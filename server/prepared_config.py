"""Prepare the shipped, data-only snapshot of date-independent game tables.

Run python server/prepared_config.py after editing base tables or overlays.
The gateway also runs directly from source when the snapshot is unavailable.
"""
import datetime
import gzip
import hashlib
import logging
import os
from pathlib import Path
import plistlib
import tempfile
import zlib


ROOT = Path(__file__).resolve().parents[1]
TABLES = ROOT / "config" / "reconstruction"
SOURCE = TABLES / "full-config.json"
SNAPSHOT = TABLES / "prepared-config.bin"
MAGIC = b"LAL-STATIC-1\n"


def input_digest():
    server = ROOT / "server"
    files = [ROOT / "VERSION"]
    files.extend(p for p in server.glob("*.py") if not p.name.startswith("test_"))
    files.extend(p for p in server.glob("*.json") if p.name != "llm.json" and not p.name.startswith("test_"))
    files.extend(p for p in TABLES.rglob("*") if p.is_file() and p != SNAPSHOT)
    result = hashlib.sha256()
    for path in sorted(files, key=lambda p: p.relative_to(ROOT).as_posix()):
        data = path.read_bytes()
        if path.suffix in (".py", ".json") or path.name == "VERSION":
            data = data.replace(b"\r\n", b"\n")
        result.update(path.relative_to(ROOT).as_posix().encode("utf-8") + b"\0")
        result.update(hashlib.sha256(data).digest())
    return result.digest()


def read_prepared(path):
    if Path(path).resolve() != SOURCE or not SNAPSHOT.is_file():
        return None
    try:
        with SNAPSHOT.open("rb") as source:
            if source.read(len(MAGIC)) != MAGIC or source.read(32) != input_digest():
                return None
            expected = source.read(32)
            payload = source.read()
        if hashlib.sha256(payload).digest() != expected:
            raise ValueError("snapshot checksum mismatch")
        prepared = plistlib.loads(gzip.decompress(payload), fmt=plistlib.FMT_BINARY)
        if (not isinstance(prepared, dict) or not isinstance(prepared.get("document"), dict)
                or not isinstance(prepared.get("arena"), str) or len(prepared["arena"]) != 64):
            raise ValueError("invalid snapshot contents")
        # A plist interns equal dates. Flash Dates are mutable reference
        # objects, so restore exactly the sharing present in the source graph.
        for stamp, locations in prepared.pop("dates"):
            date = stamp.replace()
            for parent, key in locations:
                parent[key] = date
        return prepared
    except (OSError, EOFError, ValueError, KeyError, TypeError, zlib.error, plistlib.InvalidFileException) as error:
        logging.getLogger(__name__).warning("Rebuilding game tables from source: %s", error)
        return None


def _date_locations(document):
    groups = {}
    seen = set()

    def visit(parent):
        if id(parent) in seen:
            return
        seen.add(id(parent))
        entries = parent.items() if isinstance(parent, dict) else enumerate(parent)
        for key, item in entries:
            if isinstance(item, datetime.datetime):
                groups.setdefault(id(item), (item, []))[1].append((parent, key))
            elif isinstance(item, (dict, list)):
                visit(item)

    visit(document)
    return list(groups.values())


def prepare():
    from gateway import build_static_config
    from arena_opponents import combat_config_signature
    fingerprint = input_digest()
    document = build_static_config(SOURCE)
    # Binary plists preserve shared tables, native dates and numeric types.
    raw = plistlib.dumps({"document": document, "arena": combat_config_signature(document["cfg"]),
                          "dates": _date_locations(document)},
                         fmt=plistlib.FMT_BINARY, sort_keys=False)
    payload = gzip.compress(raw, compresslevel=6, mtime=0)
    if input_digest() != fingerprint:
        raise RuntimeError("Game configuration changed during preparation")
    with tempfile.NamedTemporaryFile(dir=TABLES.parent, delete=False) as tmp:
        temporary = Path(tmp.name)
    try:
        temporary.write_bytes(MAGIC + fingerprint + hashlib.sha256(payload).digest() + payload)
        os.replace(temporary, SNAPSHOT)
    finally:
        temporary.unlink(missing_ok=True)


if __name__ == "__main__":
    prepare()
