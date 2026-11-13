"""Assemble the server tree into the manager's APK assets.

The Android server binary is never rebuilt from source: the bundled tree is the
same one ``start-server.ps1`` runs on a desktop, copied verbatim minus caches and
tests. Keeping the layout identical is what lets a save written on a phone be
opened by the desktop server and vice versa.

Layout produced under ``--output``:

    VERSION
    server/*.py
    server/*.json
    config/reconstruction/*.json

The manager unpacks this to ``filesDir/runtime`` and starts ``server/gateway.py``
with the same arguments the PowerShell launcher passes.

Usage:
    python scripts/prepare_android_runtime.py --output <dir>
    python scripts/prepare_android_runtime.py --output <dir> --check
"""
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]

# Tests and bytecode are dead weight in an APK and their absence is asserted
# below, so a stray __pycache__ cannot silently ship a stale module.
EXCLUDED_SUFFIXES = {".pyc", ".pyo"}
EXCLUDED_NAMES = {"__pycache__", "requirements.txt"}
EXCLUDED_PREFIXES = ("test_",)

# Directories copied wholesale, preserving their relative paths.
CONFIG_RELATIVE = Path("config") / "reconstruction"

# Recorded in the manifest so a build can be traced back to exact inputs.
MANIFEST_NAME = "runtime-manifest.json"


class PreparationError(RuntimeError):
    """Raised when the server tree cannot be assembled as required."""


def _iter_server_modules(server_dir: Path):
    if not server_dir.is_dir():
        raise PreparationError(f"server directory is missing: {server_dir}")
    modules = []
    for entry in sorted(server_dir.iterdir()):
        if entry.is_dir():
            continue
        if entry.name in EXCLUDED_NAMES or entry.suffix in EXCLUDED_SUFFIXES:
            continue
        if entry.name.startswith(EXCLUDED_PREFIXES):
            continue
        if entry.suffix != ".py":
            continue
        modules.append(entry)
    if not any(module.name == "gateway.py" for module in modules):
        raise PreparationError("server/gateway.py is missing from the bundle")
    return modules


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1 << 20), b""):
            digest.update(block)
    return digest.hexdigest()


def prepare(output: Path, check: bool = False) -> dict:
    """Copy the runtime tree into ``output`` and return its manifest.

    With ``check`` the tree is compared against an existing ``output`` instead of
    being written, which is what a CI build uses to catch a stale bundle.
    """
    version_path = REPO_ROOT / "VERSION"
    if not version_path.is_file():
        raise PreparationError("VERSION is missing from the repository root")
    version = version_path.read_text(encoding="utf-8").strip()
    if not version:
        raise PreparationError("VERSION must contain a project version")

    modules = _iter_server_modules(REPO_ROOT / "server")
    # 1.0.2's upstream overlays read this data beside their Python module.
    # Copying only *.py produces an APK which cannot start its gateway.
    data_files = sorted(p for p in (REPO_ROOT / "server").glob("*.json")
                        if p.is_file() and not p.name.startswith(EXCLUDED_PREFIXES))
    config_dir = REPO_ROOT / CONFIG_RELATIVE
    if not config_dir.is_dir():
        raise PreparationError(f"configuration directory is missing: {config_dir}")
    configs = sorted(entry for entry in config_dir.rglob('*') if entry.is_file())
    if not configs:
        raise PreparationError(f"no configuration files found in {config_dir}")

    entries: dict[str, str] = {}
    planned: list[tuple[Path, Path]] = [(version_path, Path("VERSION"))]
    for module in modules:
        planned.append((module, Path("server") / module.name))
    for data_file in data_files:
        planned.append((data_file, Path("server") / data_file.name))
    for config in configs:
        planned.append((config, CONFIG_RELATIVE / config.relative_to(config_dir)))

    for source, relative in planned:
        if not source.is_file():
            raise PreparationError(f"required file is missing: {source}")
        entries[relative.as_posix()] = _sha256(source)

    manifest = {
        "schema": "lal-android-runtime-v1",
        "version": version,
        "module_count": len(modules),
        "data_count": len(data_files),
        "config_count": len(configs),
        "files": entries,
    }

    if check:
        _verify_existing(output, manifest, planned)
        return manifest

    if output.exists():
        if REPO_ROOT.resolve() not in output.resolve().parents:
            raise PreparationError("Refusing to replace a runtime directory outside this engineering folder")
        shutil.rmtree(output)
    for source, relative in planned:
        destination = output / relative
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, destination)

    # The server reads ROOT/VERSION and ROOT/config at import time and expects
    # the same shape it has on disk, so nothing here is renamed or flattened.
    (output / MANIFEST_NAME).write_text(
        json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")

    _verify_existing(output, manifest, planned)
    return manifest


def _verify_existing(output: Path, manifest: dict, planned) -> None:
    """Assert the written (or pre-existing) tree matches the source exactly."""
    problems: list[str] = []
    for relative, digest in manifest["files"].items():
        candidate = output / relative
        if not candidate.is_file():
            problems.append(f"missing: {relative}")
            continue
        if _sha256(candidate) != digest:
            problems.append(f"content mismatch: {relative}")

    expected = {relative.as_posix() for _, relative in planned} | {MANIFEST_NAME}
    if output.is_dir():
        for entry in output.rglob("*"):
            if entry.is_dir():
                continue
            relative = entry.relative_to(output).as_posix()
            if relative not in expected:
                problems.append(f"unexpected file: {relative}")

    if problems:
        raise PreparationError(
            f"runtime bundle does not match its sources ({len(problems)} problem(s)):\n  "
            + "\n  ".join(problems[:20]))


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--output", required=True, type=Path,
                        help="directory the APK assets are assembled into")
    parser.add_argument("--check", action="store_true",
                        help="verify an existing bundle instead of writing one")
    args = parser.parse_args(argv)

    try:
        manifest = prepare(args.output, check=args.check)
    except PreparationError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    verb = "Verified" if args.check else "Prepared"
    print(f"{verb} runtime {manifest['version']}: "
          f"{manifest['module_count']} modules, {manifest['config_count']} configs "
          f"-> {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
