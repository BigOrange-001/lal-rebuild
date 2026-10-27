"""Rebuild the pinned AIR client source chain and package it with HARMAN ADT."""

from __future__ import annotations

import argparse
import contextlib
import getpass
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

from android_manifest import read_binary_manifest_cleartext, read_binary_manifest_version, release_metadata


ROOT = Path(__file__).resolve().parents[1]
CLIENT = ROOT / "client"
BUILD = ROOT / "build"
CONFIG = CLIENT / "build.json"
VERSION_FILE = ROOT / "VERSION"
FAILURE = re.compile(r"(?:\bSEVERE\b|compilation\s+error|syntax\s+error|compile\s+failed)", re.I)
EXPECTED_APP_ID = "air.com.meng52.lol.android"


def sha256_bytes(value: bytes) -> str:
    return hashlib.sha256(value).hexdigest()


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def require_file(path: Path, label: str) -> Path:
    path = path.expanduser().resolve()
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
    output = (completed.stdout or b"").decode("utf-8", errors="replace")
    if completed.returncode != 0 or FAILURE.search(output):
        raise RuntimeError(f"{label} failed (exit {completed.returncode}):\n{output[-12000:]}")
    return output


def resolved_repo_path(value: str, label: str) -> Path:
    path = (ROOT / value).resolve()
    if ROOT.resolve() not in path.parents:
        raise ValueError(f"{label} must stay inside the repository: {value}")
    return require_file(path, label)


def validate_runtime_version(source_text: str, version: str) -> None:
    # Preserve strings while removing comments, so a commented assignment
    # cannot stand in for a missing Android startup version.
    code = re.sub(
        r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|//[^\r\n]*|/\*[\s\S]*?\*/',
        lambda match: "" if match.group().startswith(("//", "/*")) else match.group(),
        source_text,
    )
    versions = re.findall(
        r'^[ \t]*MainConfig\.VERSION_CURR\s*=\s*'
        r'(?:GlobalStaticConst\.\$isAndroid\s*\?\s*)?["\']([^"\']+)["\']',
        code,
        flags=re.MULTILINE,
    )
    if len(versions) != 3 or any(value != version for value in versions):
        raise ValueError(f"MainLLOL runtime versions must all match VERSION {version}; found {versions}")


def read_build_config() -> tuple[dict, str, Path, Path, Path]:
    config = json.loads(CONFIG.read_text(encoding="utf-8"))
    version = VERSION_FILE.read_text(encoding="utf-8").strip()
    if config.get("schema") != "lal-client-build-v2":
        raise ValueError("Unsupported client/build.json schema")
    if config.get("version") != version:
        raise ValueError("client/build.json version must match VERSION")
    stages = config.get("stages", [])
    if not isinstance(stages, list) or not stages or config.get("stage_count") != len(stages):
        raise ValueError("stage_count must match the non-empty ordered stages list")
    if config.get("unique_class_count") != len({stage.get("class") for stage in stages}):
        raise ValueError("unique_class_count must match the qualified classes in stages")
    runtime_source_text = None
    for index, stage in enumerate(stages, start=1):
        if stage.get("index") != index:
            raise ValueError(f"Build stage order is not contiguous at stage {index}")
        source = resolved_repo_path(stage["source"], f"stage {index} source")
        stage["source_sha256"] = sha256_file(source)
        source_text = source.read_text(encoding="utf-8-sig")
        expected_class = stage["class"].rsplit(".", 1)[-1]
        class_match = re.search(r"\b(?:public\s+)?class\s+([A-Za-z_$][\w$]*)", source_text)
        package_match = re.search(r"\bpackage\s+([A-Za-z0-9_.]*)\s*\{", source_text)
        expected_package = stage["class"].rsplit(".", 1)[0] if "." in stage["class"] else ""
        if not class_match or class_match.group(1) != expected_class:
            raise ValueError(f"Stage {index} does not declare {stage['class']}")
        if (package_match.group(1) if package_match else "") != expected_package:
            raise ValueError(f"Stage {index} package mismatch for {stage['class']}")
        if stage["class"] == "MainLLOL":
            runtime_source_text = source_text
    if runtime_source_text is None:
        raise ValueError("client/build.json must declare the MainLLOL runtime source")
    validate_runtime_version(runtime_source_text, version)

    template = resolved_repo_path(config["template_swf"]["path"], "SWF resource template")
    if sha256_file(template) != config["template_swf"]["sha256"]:
        raise ValueError("Pinned SWF resource template hash mismatch")
    descriptor = resolved_repo_path(config["descriptor"]["path"], "AIR descriptor")
    if sha256_file(descriptor) != config["descriptor"]["sha256"]:
        raise ValueError("Pinned AIR descriptor hash mismatch")
    manifest = resolved_repo_path(config["assets_manifest"]["path"], "asset manifest")
    if sha256_file(manifest) != config["assets_manifest"]["sha256"]:
        raise ValueError("Pinned asset manifest hash mismatch")
    entries = json.loads(manifest.read_text(encoding="utf-8"))
    seen_paths: set[str] = set()
    for entry in entries:
        rel = entry["path"]
        if rel in seen_paths:
            raise ValueError(f"Duplicate resource path in asset manifest: {rel}")
        seen_paths.add(rel)
        resource = (CLIENT / rel).resolve()
        if CLIENT.resolve() not in resource.parents:
            raise ValueError(f"Packaged resource escapes client directory: {rel}")
        require_file(resource, "packaged resource")
        if resource.stat().st_size != entry["size"] or sha256_file(resource) != entry["sha256"]:
            raise ValueError(f"Packaged resource pin mismatch: {rel}")
    return config, version, template, descriptor, manifest


def cli_command(path: Path, java: str) -> list[str]:
    suffix = path.suffix.lower()
    if suffix == ".jar":
        return [java, "-Dfile.encoding=UTF-8", "-jar", str(path)]
    if suffix in {".bat", ".cmd"} and os.name == "nt":
        return [os.environ.get("COMSPEC", "cmd.exe"), "/d", "/c", str(path)]
    return [str(path)]


def java_major(java: str) -> int:
    output = subprocess.run([java, "-version"], text=True, stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, check=False).stdout or ""
    match = re.search(r'version "(\d+)', output)
    if not match:
        raise RuntimeError(f"Could not read Java version from {java}:\n{output}")
    return int(match.group(1))


def find_adt(sdk: Path) -> Path:
    candidates = [sdk / "lib" / "adt.jar", sdk / "bin" / "adt.bat", sdk / "bin" / "adt"]
    for candidate in candidates:
        if candidate.is_file():
            # Keep a caller-supplied ASCII alias (for example a subst drive).
            # ADT's Android packaging subprocess can misread runtime metadata
            # when its SDK path contains non-ASCII characters.
            return candidate.absolute()
    raise FileNotFoundError("Could not find bin/adt.bat, bin/adt, or lib/adt.jar under --air-sdk")


@contextlib.contextmanager
def ascii_sdk_path(sdk: Path):
    """Use an unused temporary Windows drive for ADT's non-ASCII SDK bug."""
    sdk = Path(sdk).absolute()
    if os.name != "nt" or str(sdk).isascii():
        yield sdk
        return
    drive = next((letter + ":" for letter in "ZYXWVUTSRQPONMLKJIEB"
                  if not os.path.exists(letter + ":\\")), None)
    if drive is None:
        raise RuntimeError("No unused drive is available for an ASCII AIR SDK alias")
    checked_run(["subst", drive, str(sdk)], label="temporary AIR SDK alias")
    try:
        yield Path(drive + "\\")
    finally:
        checked_run(["subst", drive, "/D"], label="release temporary AIR SDK alias")


def configure_android_gradle(tree: ET.ElementTree, android_sdk: Path) -> dict:
    """Change only staged build settings; preserve published app identity/SDK policy."""
    root = tree.getroot()
    namespace = root.tag.split("}")[0].lstrip("{")
    android = root.find("{" + namespace + "}android")
    if android is None:
        raise ValueError("AIR descriptor has no Android configuration")
    compile_sdk = 36 if (android_sdk / "platforms/android-36/android.jar").is_file() else 35
    settings = {"buildLegacyAPK":"false", "androidGradlePluginVersion":"8.9.1",
                "gradleVersion":"8.13", "androidBuildToolsVersion":"35.0.0",
                "androidCompileSdkVersion":str(compile_sdk)}
    for key, value in settings.items():
        node = android.find("{" + namespace + "}" + key)
        if node is None:
            node = ET.SubElement(android, "{" + namespace + "}" + key)
        node.text = value
    additions = android.find("{" + namespace + "}manifestAdditions")
    if additions is None or not additions.text:
        raise ValueError("AIR descriptor has no Android manifest additions")
    manifest_text = additions.text
    if "xmlns:android=" not in manifest_text:
        manifest_text = manifest_text.replace("<manifest", '<manifest xmlns:android="http://schemas.android.com/apk/res/android"', 1)
    manifest = ET.fromstring(manifest_text)
    sdk_node = manifest.find("uses-sdk")
    if sdk_node is None:
        sdk_node = ET.Element("uses-sdk")
        manifest.insert(0, sdk_node)
    android_ns = "{http://schemas.android.com/apk/res/android}"
    # These are the deployed main APK's existing AIR51 defaults, made explicit
    # because the Gradle path otherwise changes them. Authored values win.
    sdk_node.attrib.setdefault(android_ns + "minSdkVersion", "21")
    sdk_node.attrib.setdefault(android_ns + "targetSdkVersion", "36")
    ET.register_namespace("android", android_ns[1:-1])
    # AIR binds its reserved android prefix itself and rejects an explicit
    # xmlns:android attribute in manifestAdditions (descriptor error404).
    additions.text = ET.tostring(manifest, encoding="unicode").replace(
        ' xmlns:android="http://schemas.android.com/apk/res/android"', '')
    ET.register_namespace("", namespace)
    return settings


def verify_apk_signature(apk: Path, java: str, *, android_sdk: Path | None = None,
                         apksigner: Path | None = None, jarsigner: str = "jarsigner") -> tuple[str, str]:
    """Android's verifier understands v1/v2/v3; JAR verification is legacy fallback."""
    if apksigner is None and android_sdk:
        candidate = android_sdk / "build-tools/35.0.0/lib/apksigner.jar"
        if candidate.is_file():
            apksigner = candidate
    if apksigner:
        apksigner = require_file(apksigner, "Android apksigner.jar")
        verification = checked_run([java, "-Duser.language=en", "-Duser.country=US", "-jar", str(apksigner),
                                    "verify", "--verbose", "--print-certs", str(apk)], label="Android APK signature verification")
        if not re.search(r"^Verifies\s*$", verification, re.M):
            raise RuntimeError("apksigner did not report a verified APK signature")
        return verification, "apksigner"
    executable = shutil.which(jarsigner)
    if not executable:
        raise FileNotFoundError("No Android apksigner or JDK jarsigner is available")
    verification = checked_run([executable, "-J-Duser.language=en", "-J-Duser.country=US", "-J-Dfile.encoding=UTF-8",
                                "-verify", "-verbose", "-certs", str(apk)], label="legacy JAR APK signature verification")
    if not re.search(r"jar\s+verified\.?", verification, re.I):
        raise RuntimeError("JAR/v1 signature verification failed; modern APKs require Android --apksigner or --android-sdk")
    return verification, "jarsigner"


def signature_evidence(verification: str, verifier: str) -> dict:
    """Public verification evidence; certificate fingerprints contain no key material."""
    return {"verified":True, "verifier":verifier,
            "schemes":{name:value == "true" for name,value in re.findall(
                r"Verified using (v[0-9.]+) scheme[^\r\n]*:\s*(true|false)", verification)},
            "certificate_sha256":re.findall(r"Signer #\d+ certificate SHA-256 digest:\s*([0-9a-fA-F]+)", verification),
            "verification_log_sha256":sha256_bytes(verification.encode("utf-8"))}


def signing_material(args: argparse.Namespace) -> tuple[Path, str, str, str]:
    keytool = shutil.which(args.keytool)
    if not keytool:
        raise FileNotFoundError("keytool must be on PATH or supplied with --keytool")
    if args.keystore:
        keystore = require_file(args.keystore, "signing keystore")
        storepass = os.environ.get(args.storepass_env) if args.storepass_env else None
        keypass = os.environ.get(args.keypass_env) if args.keypass_env else None
        if storepass is None:
            storepass = getpass.getpass("Keystore password: ")
        if keypass is None:
            keypass = getpass.getpass("Key password: ")
        return keystore, args.alias, storepass, keypass

    keystore = BUILD / "debug.p12"
    BUILD.mkdir(parents=True, exist_ok=True)
    if not keystore.exists():
        checked_run([
            keytool, "-genkeypair", "-alias", "lal-rebuild-debug", "-keystore", str(keystore),
            "-storetype", "PKCS12", "-storepass", "android", "-keypass", "android",
            "-keyalg", "RSA", "-keysize", "2048", "-validity", "3650",
            "-dname", "CN=LAL Rebuild Debug",
        ], label="debug signing key generation")
    return keystore, "lal-rebuild-debug", "android", "android"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--air-sdk", type=Path, required=True, help="HARMAN AIR SDK install directory")
    parser.add_argument("--ffdec", type=Path, required=True, help="External FFDec CLI executable, wrapper, or jar")
    parser.add_argument("--java", default=None, help="Java 17+ executable; defaults to JAVA_HOME or PATH")
    parser.add_argument("--android-sdk", type=Path, help="Optional Android SDK directory passed to ADT")
    parser.add_argument("--android-gradle", action="store_true", help="Use HARMAN Gradle packaging with AGP8.9.1/Gradle8.13; requires --android-sdk")
    parser.add_argument("--apksigner", type=Path, help="Android SDK apksigner.jar, including APK v2/v3 verification")
    parser.add_argument("--keystore", type=Path, help="Signing key; omitted uses an ignored local debug key")
    parser.add_argument("--alias", default="lal-rebuild-debug")
    parser.add_argument("--storepass-env", help="Environment variable holding the keystore password")
    parser.add_argument("--keypass-env", help="Environment variable holding the key password")
    parser.add_argument("--keytool", default="keytool")
    parser.add_argument("--jarsigner", default="jarsigner")
    parser.add_argument("--output", type=Path, help="Output APK; defaults to build/lal-rebuild-<VERSION>.apk")
    parser.add_argument("--metadata", type=Path, default=BUILD / "build-metadata.json", help="Build attestation output path")
    parser.add_argument("--prebuilt-swf", type=Path, help="Package an already compiled SWF without rerunning FFDec stages")
    parser.add_argument("--skip-swf-build", action="store_true", help="Package the pinned template SWF; only for toolchain smoke tests")
    args = parser.parse_args()
    if args.prebuilt_swf and args.skip_swf_build:
        parser.error("--prebuilt-swf and --skip-swf-build are mutually exclusive")
    if args.android_gradle and not args.android_sdk:
        parser.error("--android-gradle requires --android-sdk")

    config, version, template, descriptor, _ = read_build_config()
    ffdec = require_file(args.ffdec, "FFDec CLI")
    sdk = args.air_sdk.expanduser().absolute()
    if not sdk.is_dir():
        raise NotADirectoryError(f"AIR SDK directory does not exist: {sdk}")
    adt = find_adt(sdk)
    java = args.java or (str(Path(os.environ["JAVA_HOME"]) / "bin" / ("java.exe" if os.name == "nt" else "java")) if os.environ.get("JAVA_HOME") else shutil.which("java"))
    if not java or java_major(java) < 17:
        raise RuntimeError("Java 17 or newer is required")
    ffdec_base = cli_command(ffdec, java)

    BUILD.mkdir(parents=True, exist_ok=True)
    # ADT hands paths to Gradle and Android tools that do not reliably handle
    # non-ASCII paths. Keep all ADT inputs and its intermediate APK in the
    # system temp directory; copy only the finished artifact into the repo.
    work = Path(tempfile.mkdtemp(prefix="lal-client-build-")).absolute()
    stage_dir = work / "swf-stages"
    stage_dir.mkdir()
    current_swf = template
    stage_results: list[dict[str, str | int]] = []
    prebuilt_swf_hash = None
    if args.prebuilt_swf:
        current_swf = require_file(args.prebuilt_swf, "prebuilt SWF")
        prebuilt_swf_hash = sha256_file(current_swf)
    elif not args.skip_swf_build:
        total_stages = len(config["stages"])
        for position, stage in enumerate(config["stages"], start=1):
            source = (ROOT / stage["source"]).resolve()
            output_swf = stage_dir / f"stage-{stage['index']:03d}.swf"
            command = ffdec_base + ["-air", "-replace", str(current_swf), str(output_swf), stage["class"], str(source)]
            print(f"[{position}/{total_stages}] FFDec {stage['class']}", flush=True)
            output = checked_run(command, label=f"FFDec stage {stage['index']} {stage['class']}")
            if not output_swf.is_file() or output_swf.stat().st_size == 0:
                raise RuntimeError(f"FFDec stage {stage['index']} did not produce a SWF")
            if stage.get("methods"):
                # Replacing a large class recompiles all its unrelated closures.
                # A leaf-method stage keeps their original bytecode and rejects
                # signature, constant-pool, or method-index dependencies.
                if ffdec.suffix.lower() != ".jar":
                    raise ValueError("Scoped method stages require the FFDec JAR")
                compiled_swf = output_swf.with_suffix(".compiled.swf")
                output_swf.replace(compiled_swf)
                output += checked_run([
                    java, "-cp", str(ffdec), str(ROOT / "scripts/CopyAs3Methods.java"),
                    str(current_swf), str(compiled_swf), str(output_swf),
                    stage["class"], *stage["methods"],
                ], label=f"Scoped methods in stage {stage['index']}")
            stage_results.append({
                "index": stage["index"],
                "class": stage["class"],
                "source_sha256": sha256_file(source),
                "input_swf_sha256": sha256_file(current_swf),
                "output_swf_sha256": sha256_file(output_swf),
                "log_sha256": sha256_bytes(output.encode("utf-8")),
            })
            current_swf = output_swf
            print(f"[{position}/{total_stages}] complete {stage['class']} sha256={stage_results[-1]['output_swf_sha256']}", flush=True)
    else:
        current_swf = template

    swf_hash = sha256_file(current_swf)
    release = release_metadata(version, swf_hash)
    package_dir = work / "package"
    package_dir.mkdir()
    shutil.copy2(current_swf, package_dir / "MainLLOL.swf")
    shutil.copytree(CLIENT / "resources" / "app" / "assets", package_dir / "assets")
    shutil.copytree(CLIENT / "resources" / "icons", package_dir / "icons")
    package_descriptor = package_dir / "application.xml"
    shutil.copy2(descriptor, package_descriptor)
    descriptor_tree = ET.parse(package_descriptor)
    ns = {"air": "http://ns.adobe.com/air/application/51.4"}
    root = descriptor_tree.getroot()
    if root.findtext("air:id", namespaces=ns) != EXPECTED_APP_ID:
        raise ValueError("AIR application id no longer matches the deployed upgrade identity")
    if root.findtext("air:versionNumber", namespaces=ns) != version or root.findtext("air:versionLabel", namespaces=ns) != version:
        raise ValueError("AIR descriptor version does not match VERSION")
    if root.findtext("air:android/air:addAirToAppID", namespaces=ns) != "false":
        raise ValueError("AIR must preserve the existing package id without adding another 'air.' prefix")
    if root.find("air:extensions", namespaces=ns) is not None:
        raise ValueError("AIR descriptor must not reference unavailable legacy ANEs")
    gradle_settings = configure_android_gradle(descriptor_tree, args.android_sdk.expanduser().resolve()) if args.android_gradle else None
    if gradle_settings:
        descriptor_tree.write(package_descriptor, encoding="utf-8", xml_declaration=True)

    output_apk = (args.output or BUILD / f"lal-rebuild-{version}.apk").expanduser().resolve()
    output_apk.parent.mkdir(parents=True, exist_ok=True)
    adt_output_apk = work / output_apk.name
    keystore, alias, storepass, keypass = signing_material(args)
    adt_keystore = work / "signing.p12"
    shutil.copy2(keystore, adt_keystore)
    command = ["-package", "-target", config["adt_target"]]
    # SDK51 rejects 'all' for legacy APK, but Gradle needs it to avoid filtering
    # the descriptor's armv7,armv8 list down to the default single architecture.
    if args.android_gradle:
        command += ["-arch", "all"]
    command += [
        "-storetype", "pkcs12", "-keystore", str(adt_keystore),
        "-storepass", storepass, "-alias", alias, "-keypass", keypass,
    ]
    command += [str(adt_output_apk), str(package_descriptor)]
    if args.android_sdk:
        command += ["-platformsdk", str(args.android_sdk.expanduser().resolve())]
    command += ["MainLLOL.swf", "assets", "icons"]
    try:
        with ascii_sdk_path(sdk) as adt_sdk:
            adt_output = checked_run(cli_command(find_adt(adt_sdk), java) + command, label="HARMAN ADT APK package", cwd=package_dir)
    except RuntimeError as error:
        message = str(error)
        for secret in (storepass, keypass):
            if secret:
                message = message.replace(secret, "<redacted>")
        raise RuntimeError(message) from None
    finally:
        adt_keystore.unlink(missing_ok=True)
    if not adt_output_apk.is_file() or adt_output_apk.stat().st_size == 0:
        raise RuntimeError("ADT returned success without creating the APK")

    verification, signature_verifier = verify_apk_signature(adt_output_apk, java, android_sdk=args.android_sdk,
                                                            apksigner=args.apksigner, jarsigner=args.jarsigner)
    (BUILD / (signature_verifier + "-verify.txt")).write_text(verification, encoding="utf-8")
    with zipfile.ZipFile(adt_output_apk) as apk:
        names = set(apk.namelist())
        for required in ("assets/MainLLOL.swf", "assets/assets/audio/A_1001.mp3", "assets/assets/swfs/hero_A.swf"):
            if required not in names:
                raise RuntimeError(f"ADT package is missing required resource: {required}")
        if sha256_bytes(apk.read("assets/MainLLOL.swf")) != swf_hash:
            raise RuntimeError("Packaged APK SWF does not match the compiled SWF")
        version_code, version_name = read_binary_manifest_version(apk.read("AndroidManifest.xml"))
        if version_code != release["version_code"]:
            raise RuntimeError(f"Android versionCode mismatch: expected {release['version_code']}, got {version_code}")
        if version_name != release["version_name"]:
            raise RuntimeError(f"Android versionName mismatch: expected {release['version_name']}, got {version_name}")
        if not read_binary_manifest_cleartext(apk.read("AndroidManifest.xml")):
            raise RuntimeError("Packaged Android manifest must allow the game's local HTTP endpoint")
        architectures = sorted(name.split("/")[1] for name in names if re.fullmatch(r"lib/[^/]+/libCore\.so", name))
        if not {"armeabi-v7a", "arm64-v8a"}.issubset(architectures):
            raise RuntimeError("Packaged APK must include both ARMv7 and ARM64 runtimes")
        embedded_descriptor = ET.fromstring(apk.read("assets/META-INF/AIR/application.xml"))
        embedded_ns = {"air": embedded_descriptor.tag.split("}")[0].lstrip("{")}
        if embedded_descriptor.findtext("air:versionNumber", namespaces=embedded_ns) != version or embedded_descriptor.findtext("air:versionLabel", namespaces=embedded_ns) != version:
            raise RuntimeError("Packaged AIR descriptor version mismatch")
    shutil.copy2(adt_output_apk, output_apk)
    metadata = {
        "version": version,
        "version_code": release["version_code"],
        "android_uses_cleartext_traffic": True,
        "android_architectures": architectures,
        "signature_verifier": signature_verifier,
        "signature": signature_evidence(verification, signature_verifier),
        "android_gradle": gradle_settings,
        "template_swf_sha256": config["template_swf"]["sha256"],
        "compiled_swf_sha256": swf_hash,
        "apk_sha256": sha256_file(adt_output_apk),
        "apk_path": str(output_apk),
        "air_sdk_path": str(sdk),
        "adt_path": str(adt),
        "keystore_path": str(keystore),
        "build_mode": "template-smoke" if args.skip_swf_build else f"{len(stage_results)}-stage-cold-build",
        "stage_count": len(stage_results),
        "adt_log_sha256": sha256_bytes(adt_output.encode("utf-8")),
        "stages": stage_results,
    }
    if prebuilt_swf_hash is not None:
        metadata["build_mode"] = "prebuilt-swf-package"
        metadata["prebuilt_swf_sha256"] = prebuilt_swf_hash
    metadata_path = args.metadata.expanduser().resolve()
    metadata_path.parent.mkdir(parents=True, exist_ok=True)
    metadata_path.write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    shutil.rmtree(work, ignore_errors=True)
    print(f"Built {output_apk}")
    print(f"SWF SHA-256 {swf_hash}")
    print(f"APK SHA-256 {metadata['apk_sha256']}")
    print(f"Mode {metadata['build_mode']}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as error:
        print(f"build_client: {error}", file=sys.stderr)
        raise SystemExit(1)
