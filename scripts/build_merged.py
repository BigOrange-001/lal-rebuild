"""Assemble a prebuilt AIR game client and a second APK into a single package.

The two halves cannot be built together by either toolchain: the client is a
prebuilt ADT artifact whose dex bakes the resource IDs of its own table into
bytecode, and the manager is a Gradle project that ships a second, colliding
table. So they are built separately and joined here, at the zip level, around
one rule — **the client's payload passes through byte-identical**.

Everything that could re-serialize it is therefore avoided:

  * resources.arsc, res/, classes.dex, libCore.so and the AIR assets are copied
    as raw bytes, never decoded and re-encoded.
  * The manager's dex becomes classes2.dex rather than being merged into
    classes.dex, because merging would mean re-running d8 over the client's
    bytecode and changing it.
  * The manifest is linked with the client APK as an aapt2 include, so its
    @-references resolve into the client's own IDs; the stub table aapt2
    produces is thrown away.

Nothing about a particular game is compiled in. The client APK is the source
of truth: its package name, versions, minSdk, resource table and launchable
activities are read from it, and every check below asserts that the merged
result agrees. Point it at a different client and manager and it adapts.

Run via build-merged.ps1, which supplies the toolchain paths, or directly:

    python -I scripts/build_merged.py \\
        --client-apk build/lal-rebuild-1.0.0.apk \\
        --manager-apk android-manager/app/build/outputs/apk/release/app-release.apk \\
        --manifest build/merged/AndroidManifest.xml \\
        --android-sdk tools/android/sdk \\
        --keystore build/debug.p12
"""

from __future__ import annotations

import argparse
import hashlib
import re
import shutil
import subprocess
import sys
import tempfile
import xml.etree.ElementTree as ElementTree
import zipfile
from pathlib import Path

FAILURE = re.compile(r"(?:\bSEVERE\b|compilation\s+error|syntax\s+error|compile\s+failed)", re.I)

ANDROID_NS = "http://schemas.android.com/apk/res/android"

#: Entries the manager contributes under a new name, because the client already
#: owns the original.
MANAGER_DEX_SOURCE = "classes.dex"

META_INF_PREFIX = "META-INF/"

#: Where native libraries and bundled assets land.
NATIVE_PREFIX = "lib/"
ASSET_PREFIX = "assets/"

#: The one thing the manager must never contribute. An APK has exactly one
#: resources.arsc, and the client's cannot be regenerated, so a manager that
#: ships resources has to be fixed rather than accommodated.
FORBIDDEN_MANAGER_PREFIX = "res/"

#: The client's package names the whole identity; every resource ID the game's
#: bytecode uses is `0x7f`, the first package slot.
RESOURCE_PACKAGE_ID = "7f"

#: A resource reference inside the manifest: @type/name, @+id/name, or
#: @package:type/name. Framework refs (@android:...) are skipped.
RESOURCE_REF = re.compile(r"^@(?:\+)?(?:(?P<package>[A-Za-z][\w.]*):)?(?P<type>\w+)/(?P<name>[^/]+)$")

#: `aapt2 dump resources` line for a single entry.
RESOURCE_ENTRY = re.compile(r"^\s*resource (0x[0-9a-f]{8}) (\w+)/(\S+)$", re.M)

#: Component elements whose android:name must survive into the merged manifest.
COMPONENT_TAGS = ("activity", "activity-alias", "service", "receiver", "provider")


# ----------------------------------------------------------------------------
# Small helpers, matching scripts/build_client.py so the two read alike.
# ----------------------------------------------------------------------------


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def require_file(path: Path, label: str) -> Path:
    path = Path(path).expanduser()
    if not path.is_file():
        raise FileNotFoundError(f"{label} does not exist: {path}")
    return path


def checked_run(command: list[str], *, label: str, cwd: Path | None = None) -> str:
    completed = subprocess.run(
        command,
        cwd=cwd,
        text=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    # aapt2 emits CRLF on Windows. Every parser below anchors to "$" under
    # re.MULTILINE, which sits *after* a \r, so a stray \r would make the
    # anchored patterns match nothing. Normalising here keeps them simple.
    output = (completed.stdout or b"").decode("utf-8", errors="replace").replace("\r\n", "\n")
    if completed.returncode != 0 or FAILURE.search(output):
        raise RuntimeError(f"{label} failed (exit {completed.returncode}):\n{output[-12000:]}")
    return output


def relay(step: str, message: str) -> None:
    print(f"[{step}] {message}", flush=True)


def resolve_tool(directory: Path, override: str | None, stem: str, label: str) -> Path:
    """Finds a build-tools binary, with or without the platform's suffix.

    The Android build-tools ship `aapt2.exe`/`zipalign.exe`/`apksigner.bat` on
    Windows and unsuffixed on Linux and macOS. Probing for both is what lets
    this script run unchanged on either.
    """
    if override:
        return require_file(Path(override), label)
    candidates = [f"{stem}{suffix}" for suffix in ("", ".exe", ".bat", ".cmd")]
    for candidate in candidates:
        path = directory / candidate
        if path.is_file():
            return path
    raise FileNotFoundError(
        f"{label} not found in {directory} (looked for {', '.join(candidates)})"
    )


# ----------------------------------------------------------------------------
# Reading the two inputs
# ----------------------------------------------------------------------------


class Badging:
    """The parts of `aapt2 dump badging` this script depends on."""

    def __init__(self, text: str, label: str) -> None:
        self.text = text
        self.label = label
        package = re.search(
            r"^package: name='([^']+)' versionCode='([^']*)' versionName='([^']*)'",
            text,
            re.M,
        )
        if not package:
            raise RuntimeError(f"could not read the package line from {label} badging")
        self.package, self.version_code, self.version_name = package.groups()

        self.min_sdk = self._int(r"^minSdkVersion:'(\d+)'")
        self.target_sdk = self._int(r"^targetSdkVersion:'(\d+)'")
        self.launchers = re.findall(r"^launchable-activity: name='([^']+)'", text, re.M)

    def _int(self, pattern: str) -> int | None:
        found = re.search(pattern, self.text, re.M)
        return int(found.group(1)) if found else None


def dump_badging(aapt2: Path, apk: Path) -> str:
    return checked_run([str(aapt2), "dump", "badging", str(apk)], label=f"aapt2 dump badging {apk.name}")


def dump_xmltree(aapt2: Path, apk: Path, entry: str = "AndroidManifest.xml") -> str:
    return checked_run(
        [str(aapt2), "dump", "xmltree", str(apk), "--file", entry],
        label=f"aapt2 dump xmltree {apk.name}",
    )


def dump_resources(aapt2: Path, apk: Path) -> str:
    return checked_run([str(aapt2), "dump", "resources", str(apk)], label=f"aapt2 dump resources {apk.name}")


def resource_ids(dump: str) -> dict[str, str]:
    """Maps "type/name" to its numeric ID, from a `dump resources` output."""
    return {f"{kind}/{name}": value for value, kind, name in RESOURCE_ENTRY.findall(dump)}


def declared_components(manifest: Path) -> list[str]:
    """The android:name of every component the shipping manifest declares."""
    root = ElementTree.parse(manifest).getroot()
    names: list[str] = []
    for element in root.iter():
        if element.tag not in COMPONENT_TAGS:
            continue
        name = element.get(f"{{{ANDROID_NS}}}name")
        if name:
            names.append(name)
    return names


def referenced_resources(manifest: Path) -> dict[str, str]:
    """Every non-framework @type/name the shipping manifest references."""
    root = ElementTree.parse(manifest).getroot()
    wanted: dict[str, str] = {}
    for element in root.iter():
        for value in element.attrib.values():
            match = RESOURCE_REF.match(value.strip())
            if not match:
                continue
            package = match.group("package")
            if package == "android":
                # A framework resource: lives in the platform's table, not ours.
                continue
            if package:
                raise RuntimeError(
                    f"{manifest.name} references @{package}:{match.group('type')}/"
                    f"{match.group('name')}, which is not a resource in the client's own "
                    "table; the merged package has no library to resolve it against"
                )
            wanted[f"{match.group('type')}/{match.group('name')}"] = value.strip()
    return wanted


# ----------------------------------------------------------------------------
# Zip-level assembly
# ----------------------------------------------------------------------------


class Payload:
    """Records what was copied from the client so it can be verified afterwards."""

    def __init__(self) -> None:
        self.entries: dict[str, str] = {}

    def record(self, name: str, digest: str) -> None:
        self.entries[name] = digest

    def verify_all(self, apk: Path) -> None:
        with zipfile.ZipFile(apk) as archive:
            present = set(archive.namelist())
            missing = sorted(set(self.entries) - present)
            if missing:
                raise RuntimeError(
                    "client entries did not survive: " + ", ".join(missing[:10])
                )
            for name, expected in self.entries.items():
                actual = sha256_bytes(archive.read(name))
                if actual != expected:
                    raise RuntimeError(f"client payload was altered: {name}")


def assemble(
    client_apk: Path,
    manager_apk: Path,
    manifest_blob: bytes,
    dex_target: str,
    drops: frozenset[str],
    output: Path,
) -> Payload:
    """Writes the merged APK, copying the client's entries through untouched."""
    payload = Payload()

    with zipfile.ZipFile(client_apk) as client, zipfile.ZipFile(manager_apk) as manager:
        client_names = set(client.namelist())

        # Whatever the manager ships that the client already has must not be
        # copied; those are exactly the collisions this design exists to avoid.
        # Anywhere under META-INF is expected: both sides carry Gradle metadata
        # there and both are dropped rather than merged.
        allowed_overlap = {"AndroidManifest.xml", "classes.dex", "resources.arsc"}
        unexpected = sorted(
            name
            for name in client_names & set(manager.namelist())
            if name not in allowed_overlap and not name.startswith(META_INF_PREFIX)
        )
        if unexpected:
            raise RuntimeError(
                "manager entries collide with the client outside the known set: "
                + ", ".join(unexpected)
            )

        with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED) as merged:
            merged.writestr("AndroidManifest.xml", manifest_blob)

            for info in client.infolist():
                name = info.filename
                if name == "AndroidManifest.xml" or name.startswith(META_INF_PREFIX):
                    continue
                data = client.read(name)
                # The client's payload is the point: hash it on the way through
                # so a later step cannot quietly rewrite it.
                payload.record(name, sha256_bytes(data))
                merged.writestr(info, data)

            # The manager's dex, under a name the client does not use. Both are
            # loaded, because the client's declared application class installs
            # the secondary dex loader.
            merged.writestr(dex_target, manager.read(MANAGER_DEX_SOURCE))

            for info in manager.infolist():
                name = info.filename
                if name in ("AndroidManifest.xml", "resources.arsc", MANAGER_DEX_SOURCE):
                    continue
                if name.startswith(META_INF_PREFIX) or name in drops:
                    continue
                if name.startswith(FORBIDDEN_MANAGER_PREFIX):
                    raise RuntimeError(
                        f"manager re-shipped a resource: {name}. The merged package keeps the "
                        "client's single resource table, so the manager must contribute none."
                    )
                if name in client_names:
                    raise RuntimeError(f"manager re-shipped a client entry: {name}")
                merged.writestr(info, manager.read(name))

    return payload


def assert_native_libs_stored(apk: Path) -> None:
    """extractNativeLibs="false" means the loader maps the stored entry directly.

    A compressed .so would fail to load at runtime, and the failure surfaces as
    a missing-library crash rather than a build error, so it is checked here.
    """
    with zipfile.ZipFile(apk) as archive:
        compressed = [
            info.filename
            for info in archive.infolist()
            if info.filename.startswith(NATIVE_PREFIX)
            and info.compress_type != zipfile.ZIP_STORED
        ]
    if compressed:
        raise RuntimeError("native library is compressed: " + ", ".join(compressed))


# ----------------------------------------------------------------------------
# Steps
# ----------------------------------------------------------------------------


def link_manifest(aapt2: Path, client_apk: Path, android_jar: Path, manifest: Path, work: Path) -> bytes:
    """Resolves the hand-written manifest against the client's resource table."""
    stub = work / "manifest-stub.apk"
    checked_run(
        [
            str(aapt2),
            "link",
            "-o",
            str(stub),
            "-I",
            str(client_apk),
            "-I",
            str(android_jar),
            "--manifest",
            str(manifest),
        ],
        label="aapt2 link",
    )
    # aapt2 emits a resources.arsc of its own here. It is discarded on purpose:
    # the client's table is the one that ships, and it is already correct.
    with zipfile.ZipFile(stub) as archive:
        return archive.read("AndroidManifest.xml")


def stamp_manifest_version(source: Path, version_code: str, version_name: str, work: Path) -> Path:
    """Rewrites the manifest's version attributes to the manager's own.

    The manager's BuildConfig.VERSION_CODE/VERSION_NAME are what the runtime
    unpack stamp is written from, so letting the shipping manifest drift from
    them means an update installs but the bundled server never refreshes.
    Stamping keeps one source of truth; the alternative is failing and asking.
    """
    text = source.read_text(encoding="utf-8")
    text, code_hits = re.subn(r'android:versionCode="[^"]*"', f'android:versionCode="{version_code}"', text)
    text, name_hits = re.subn(r'android:versionName="[^"]*"', f'android:versionName="{version_name}"', text)
    if not code_hits or not name_hits:
        raise RuntimeError(
            f"could not stamp versions into {source.name}: "
            "the manifest must declare both android:versionCode and android:versionName"
        )
    stamped = work / f"AndroidManifest-{version_code}.xml"
    stamped.write_text(text, encoding="utf-8")
    return stamped


def stamp_client_runtime_id(source: Path, client_tree: str, work: Path) -> Path:
    """Carry the newly packaged AIR content identity into the shipping manifest."""
    match = re.search(r':name\([^)]*\)="uniqueappversionid"[^\n]*\n\s+A: [^\n]*:value\([^)]*\)="([^"]+)"', client_tree)
    if not match:
        return source  # A non-AIR client has no such runtime metadata.
    tree = ElementTree.parse(source)
    nodes = [node for node in tree.getroot().iter("meta-data") if node.get(f"{{{ANDROID_NS}}}name") == "uniqueappversionid"]
    if len(nodes) != 1:
        raise RuntimeError("The shipping manifest must preserve the client's AIR runtime content identity")
    expected = match.group(1)
    if nodes[0].get(f"{{{ANDROID_NS}}}value") == expected:
        return source
    nodes[0].set(f"{{{ANDROID_NS}}}value", expected)
    ElementTree.register_namespace("android", ANDROID_NS)
    output = work / "AndroidManifest-runtime.xml"
    tree.write(output, encoding="utf-8", xml_declaration=True)
    relay("stamp", f"AIR uniqueappversionid copied from client: {expected}")
    return output


def assert_dex(client_apk: Path, manager_apk: Path, apk: Path, dex_target: str) -> None:
    with (
        zipfile.ZipFile(client_apk) as client,
        zipfile.ZipFile(manager_apk) as manager,
        zipfile.ZipFile(apk) as merged,
    ):
        names = set(merged.namelist())
        for required in ("classes.dex", dex_target):
            if required not in names:
                raise RuntimeError(f"merged APK is missing {required}")
        if sha256_bytes(merged.read("classes.dex")) != sha256_bytes(client.read("classes.dex")):
            raise RuntimeError("the client's classes.dex was modified")
        if sha256_bytes(merged.read(dex_target)) != sha256_bytes(manager.read(MANAGER_DEX_SOURCE)):
            raise RuntimeError(f"{dex_target} does not match the manager's {MANAGER_DEX_SOURCE}")
        if merged.read(dex_target)[:1] not in (b"d", b"c"):
            raise RuntimeError(f"{dex_target} does not look like a dex file")


def dex_classes(dexdump: Path | None, apk: Path, entry: str, work: Path) -> set[str] | None:
    """Class descriptors in one dex, or None when dexdump is unavailable."""
    if dexdump is None:
        return None
    with zipfile.ZipFile(apk) as archive:
        blob = archive.read(entry)
    extracted = work / f"{entry}.bin"
    extracted.write_bytes(blob)
    output = checked_run([str(dexdump), str(extracted)], label=f"dexdump {entry}")
    return set(re.findall(r"Class descriptor\s*:\s*'([^']+)'", output))


def assert_no_duplicate_classes(
    dexdump: Path | None, apk: Path, dex_target: str, allowed: frozenset[str], work: Path
) -> None:
    """A class in both dexes is loaded from classes.dex, silently shadowing the other.

    Harmless when it is the same class compiled twice; a real hazard when the
    two copies differ, which is what a manager accidentally bundling a library
    the client also ships looks like.
    """
    first = dex_classes(dexdump, apk, "classes.dex", work)
    second = dex_classes(dexdump, apk, dex_target, work)
    if first is None or second is None:
        relay("skip", "dexdump not available; class-duplication check skipped")
        return
    duplicates = sorted((first & second) - set(allowed))
    if duplicates:
        raise RuntimeError(
            "classes appear in both dexes: " + ", ".join(duplicates[:10])
        )
    relay("dex", f"{len(first)} + {len(second)} classes, 0 duplicated")


def assert_manifest(
    apk: Path, aapt2: Path, components: list[str], forbidden: tuple[str, ...]
) -> None:
    tree = dump_xmltree(aapt2, apk)
    for name in components:
        if name not in tree:
            raise RuntimeError(f"manifest is missing the declared component {name}")
    for pattern in forbidden:
        if pattern in tree:
            raise RuntimeError(f"manifest still carries {pattern}")


def assert_launcher(apk: Path, badging: Badging, expected: str | None, declared: list[str]) -> None:
    """Exactly one tappable launcher entry, and it is one the manifest declares.

    Counting category strings in the xmltree dump would be wrong: that dump
    echoes each string twice, once as the value and once in a "(Raw: ...)"
    suffix. badging reports real launchable activities, one per line.
    """
    found = badging.launchers
    if expected:
        if found != [expected]:
            raise RuntimeError(f"expected {expected} as the only launcher, found {found}")
        return
    if len(found) != 1:
        raise RuntimeError(f"expected exactly one launcher, found {found}")
    if found[0] not in declared:
        raise RuntimeError(
            f"launcher {found[0]} is not declared in the shipping manifest; "
            "the icon would point at a component the package does not own"
        )


def assert_identity(merged: Badging, client: Badging, manager: Badging) -> None:
    """Package, versions and SDK floor, as the installer will read them."""
    if merged.package != client.package:
        raise RuntimeError(f"package is {merged.package}, expected the client's {client.package}")
    if merged.version_code != manager.version_code:
        raise RuntimeError(
            f"versionCode is {merged.version_code}, expected the manager's "
            f"{manager.version_code}; the runtime unpack stamp is built from the "
            "manager's BuildConfig, so a mismatch means updates install but the "
            "bundled server never refreshes"
        )
    if merged.version_name != manager.version_name:
        raise RuntimeError(
            f"versionName is {merged.version_name}, expected the manager's {manager.version_name}"
        )
    # An installed client must be upgradeable in place, and a device that could
    # run either half must still be able to run the union.
    if merged.version_code and client.version_code and int(merged.version_code) < int(client.version_code):
        raise RuntimeError(
            f"versionCode {merged.version_code} is below the client's {client.version_code}; "
            "installing over an existing copy would fail"
        )
    floor = max(value for value in (client.min_sdk, manager.min_sdk) if value is not None)
    if merged.min_sdk is None or merged.min_sdk < floor:
        raise RuntimeError(
            f"minSdk is {merged.min_sdk}, expected at least {floor} "
            "(the higher of the client's and the manager's)"
        )


def assert_single_resource_table(apk: Path, aapt2: Path, client_apk: Path, package: str) -> None:
    """One table, the client's, unchanged.

    Comparing the full dumps rather than just the package line is what proves
    the manager contributed nothing: an added, renamed or reordered entry would
    shift IDs the client's bytecode has already resolved.
    """
    merged_dump = dump_resources(aapt2, apk)
    packages = re.findall(r"^Package name=(\S+) id=(\S+)", merged_dump, re.M)
    if len(packages) != 1:
        raise RuntimeError(f"expected one resource package, found {packages}")
    name, package_id = packages[0]
    if name != package or package_id != RESOURCE_PACKAGE_ID:
        raise RuntimeError(f"unexpected resource package: {name} id={package_id}")
    if merged_dump != dump_resources(aapt2, client_apk):
        raise RuntimeError("the client's resource table did not pass through unmodified")


def assert_resolved_resources(apk: Path, aapt2: Path, referenced: dict[str, str], table: dict[str, str]) -> None:
    """The manifest's @ references must land on the client's existing entries.

    A wrong reference would not fail the link — it would resolve to some other
    slot in the client's table — so each one is resolved against the client's
    own dump and then required to appear as that exact ID in the merged output.
    """
    expected: dict[str, str] = {}
    for key, written in sorted(referenced.items()):
        resource_id = table.get(key)
        if resource_id is None:
            raise RuntimeError(
                f"the manifest references {written}, which the client's table does not define; "
                "the merged package has no slot to resolve it against"
            )
        expected[resource_id] = written

    tree = dump_xmltree(aapt2, apk)
    present = set(re.findall(r"@(0x7f[0-9a-f]{6})", tree))
    stray = sorted(present - set(expected))
    if stray:
        raise RuntimeError(
            "manifest references resources the client does not define: " + ", ".join(stray)
        )
    for resource_id, written in sorted(expected.items()):
        if resource_id not in present:
            raise RuntimeError(f"manifest lost its reference to {written} ({resource_id})")
    relay("resources", f"{len(expected)} manifest references resolved into the client's table")


def zipalign(zipalign_bin: Path, source: Path, target: Path) -> None:
    # Stored native libraries must also be mmap-able on 16 KB page devices.
    # Keep ordinary ZIP entries at 4-byte alignment and .so entries at 16 KB.
    checked_run(
        [str(zipalign_bin), "-P", "16", "-f", "4", str(source), str(target)],
        label="zipalign",
    )


def sign(apksigner: Path, keystore: Path, alias: str, ks_pass: str, key_pass: str, apk: Path) -> None:
    require_file(keystore, "signing keystore")
    checked_run(
        [
            str(apksigner),
            "sign",
            "--ks",
            str(keystore),
            "--ks-key-alias",
            alias,
            "--ks-pass",
            f"pass:{ks_pass}",
            "--key-pass",
            f"pass:{key_pass}",
            "--v1-signing-enabled",
            "true",
            "--v2-signing-enabled",
            "true",
            "--v3-signing-enabled",
            "true",
            str(apk),
        ],
        label="apksigner sign",
    )


def verify_signature(apksigner: Path, apk: Path) -> str:
    return checked_run(
        [str(apksigner), "verify", "--print-certs", "-v", str(apk)],
        label="apksigner verify",
    )


# ----------------------------------------------------------------------------
# Entry point
# ----------------------------------------------------------------------------


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Join a prebuilt AIR client APK and a manager APK into one package.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("--client-apk", required=True, help="the prebuilt game client APK")
    parser.add_argument("--manager-apk", required=True, help="the manager APK to graft in")
    parser.add_argument("--manifest", default="android-manager/merged-AndroidManifest.xml", help="the shipping manifest")
    parser.add_argument("--output", help="output APK; default build/<client stem>-merged.apk")
    parser.add_argument("--android-sdk", required=True, help="Android SDK root")
    parser.add_argument("--build-tools", default="35.0.0")
    parser.add_argument("--platform", default="android-35")
    parser.add_argument("--aapt2", help="aapt2 binary; overrides --build-tools")
    parser.add_argument("--zipalign", help="zipalign binary; overrides --build-tools")
    parser.add_argument("--apksigner", help="apksigner binary; overrides --build-tools")
    parser.add_argument("--dexdump", help="dexdump binary; enables the class-duplication check")
    parser.add_argument("--keystore", default="build/debug.p12")
    parser.add_argument("--ks-alias", default="lal-rebuild-debug")
    parser.add_argument("--ks-pass", default="android")
    parser.add_argument("--key-pass", default="android")
    parser.add_argument("--dex-target", default="classes2.dex", help="name the manager's dex takes")
    parser.add_argument("--launcher", help="require this activity to be the sole launcher")
    parser.add_argument(
        "--forbid",
        action="append",
        default=[],
        metavar="SUBSTRING",
        help="fail if this string survives into the manifest (repeatable)",
    )
    parser.add_argument(
        "--allow-dup-class",
        action="append",
        default=[],
        metavar="DESCRIPTOR",
        help="allow this class to appear in both dexes (repeatable)",
    )
    parser.add_argument(
        "--drop",
        action="append",
        default=[],
        metavar="ENTRY",
        help="entry the manager ships that must not be carried over (repeatable)",
    )
    parser.add_argument(
        "--stamp-version",
        action=argparse.BooleanOptionalAction,
        default=True,
        help="rewrite the manifest's versionCode/versionName to the manager's; "
             "use --no-stamp-version to fail on a mismatch instead",
    )
    parser.add_argument("--work-dir", help="scratch directory; a temp dir by default")
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)

    sdk = Path(args.android_sdk).expanduser()
    tools = sdk / "build-tools" / args.build_tools
    aapt2 = resolve_tool(tools, args.aapt2, "aapt2", "aapt2")
    zipalign_bin = resolve_tool(tools, args.zipalign, "zipalign", "zipalign")
    apksigner = resolve_tool(tools, args.apksigner, "apksigner", "apksigner")
    dexdump = (
        require_file(Path(args.dexdump), "dexdump")
        if args.dexdump
        else next((tools / name for name in ("dexdump.exe", "dexdump") if (tools / name).is_file()), None)
    )
    android_jar = require_file(sdk / "platforms" / args.platform / "android.jar", "android.jar")

    client_apk = require_file(Path(args.client_apk), "client APK")
    manager_apk = require_file(Path(args.manager_apk), "manager APK")
    manifest = require_file(Path(args.manifest), "merged manifest")

    work = (
        Path(args.work_dir).expanduser()
        if args.work_dir
        else Path(tempfile.mkdtemp(prefix="lal-merged-"))
    )
    work.mkdir(parents=True, exist_ok=True)

    try:
        relay("read", f"client {client_apk.name}")
        client = Badging(dump_badging(aapt2, client_apk), "client")
        relay("read", f"manager {manager_apk.name}")
        manager = Badging(dump_badging(aapt2, manager_apk), "manager")

        output = (
            Path(args.output).expanduser().absolute()
            if args.output
            else (Path("build") / f"{client_apk.stem}-merged.apk").resolve()
        )
        output.parent.mkdir(parents=True, exist_ok=True)

        # The manager's BuildConfig drives the runtime unpack stamp; the shipping
        # manifest drives what the installer reads. They have to agree.
        if (manifest.read_text(encoding="utf-8").count(f'android:versionCode="{manager.version_code}"') == 0
                or f'android:versionName="{manager.version_name}"' not in manifest.read_text(encoding="utf-8")):
            if not args.stamp_version:
                raise RuntimeError(
                    f"{manifest} declares versions that disagree with the manager APK "
                    f"({manager.version_code}/{manager.version_name}). Update the manifest, "
                    "or pass --stamp-version to rewrite it from the manager automatically."
                )
            manifest = stamp_manifest_version(manifest, manager.version_code, manager.version_name, work)
            relay("stamp", f"{manifest.name} versions set to {manager.version_code}/{manager.version_name}")

        manifest = stamp_client_runtime_id(manifest, dump_xmltree(aapt2, client_apk), work)
        components = declared_components(manifest)
        referenced = referenced_resources(manifest)
        relay("read", f"{len(components)} components, {len(referenced)} resource references")

        relay("manifest", "linking against the client's resource table")
        manifest_blob = link_manifest(aapt2, client_apk, android_jar, manifest, work)

        relay("assemble", "joining the two APKs at the zip level")
        unsigned = work / "merged-unsigned.apk"
        payload = assemble(
            client_apk,
            manager_apk,
            manifest_blob,
            args.dex_target,
            frozenset(args.drop),
            unsigned,
        )

        relay("verify", "checking the client's payload survived byte-identical")
        payload.verify_all(unsigned)
        assert_native_libs_stored(unsigned)
        assert_dex(client_apk, manager_apk, unsigned, args.dex_target)
        assert_no_duplicate_classes(
            dexdump, unsigned, args.dex_target, frozenset(args.allow_dup_class), work
        )
        assert_manifest(unsigned, aapt2, components, tuple(args.forbid))
        assert_single_resource_table(unsigned, aapt2, client_apk, client.package)
        assert_resolved_resources(unsigned, aapt2, referenced, resource_ids(dump_resources(aapt2, client_apk)))
        assert_identity(Badging(dump_badging(aapt2, unsigned), "merged"), client, manager)
        assert_launcher(unsigned, Badging(dump_badging(aapt2, unsigned), "merged"), args.launcher, components)

        relay("align", "zipalign -P 16 4")
        aligned = work / "merged-aligned.apk"
        zipalign(zipalign_bin, unsigned, aligned)

        shutil.copyfile(aligned, output)

        relay("sign", f"apksigner (v1+v2+v3), alias {args.ks_alias}")
        sign(apksigner, Path(args.keystore), args.ks_alias, args.ks_pass, args.key_pass, output)

        relay("verify", "checking the signature")
        report = verify_signature(apksigner, output)
        if "Signer #1 certificate DN" not in report:
            raise RuntimeError("apksigner did not report a signer")
        checked_run([str(zipalign_bin), "-c", "-P", "16", "4", str(output)], label="signed APK 16 KB ZIP alignment")
        payload.verify_all(output)

        relay("done", f"{output} ({output.stat().st_size:,} bytes)")
        relay("done", f"sha256 {sha256_file(output)}")
    finally:
        if not args.work_dir:
            shutil.rmtree(work, ignore_errors=True)

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
