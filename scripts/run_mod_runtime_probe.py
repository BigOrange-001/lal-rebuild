"""Exercise a packaged desktop SWF in real AIR against an isolated production gateway.

The package must contain compiled ModRuntimeProbe.swf. This command creates only
QA data beneath --work; never supply a real player's package data directory.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import shutil
import struct
import subprocess
import sys
import threading
import time
import uuid
import zlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "server"))
from gateway import Backend, make_server
from mod_tools import pack_directory


def png():
    def chunk(kind, raw):
        return struct.pack(">I", len(raw)) + kind + raw + struct.pack(">I", zlib.crc32(kind + raw) & 0xffffffff)
    width = height = 160
    row = b"\x22\x88\xcc\xff" * width
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress((b"\0" + row) * height)) + chunk(b"IEND", b""))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package", type=Path, required=True)
    parser.add_argument("--work", type=Path, required=True)
    parser.add_argument("--serve-only", action="store_true", help="Keep an isolated Android QA backend alive; create work/stop to finish")
    parser.add_argument("--mode", choices=("base", "media", "minimal", "scopes", "manage", "missing", "restored", "import", "directory-import"), default="media")
    args = parser.parse_args()
    package = args.package.resolve()
    app = package / "app"
    work = args.work.resolve()
    if work.exists():
        raise FileExistsError("Use a fresh isolated QA directory")
    work.mkdir(parents=True)
    if not (app / "ModRuntimeProbe.swf").is_file():
        raise FileNotFoundError("Compile scripts/probes/ModRuntimeProbe.as into the package app first")
    # The normal host and the test host use distinct AIR application identities.
    descriptor = app / ("probe-" + uuid.uuid4().hex + ".xml")
    descriptor.write_text('''<?xml version="1.0" encoding="utf-8"?>
<application xmlns="http://ns.adobe.com/air/application/51.4"><id>org.bigorange.lal.mods.qa.UNIQUE</id>
<filename>LALModProbe</filename><name>LAL Mod Runtime QA</name><versionNumber>1.0.2</versionNumber>
<supportedProfiles>extendedDesktop</supportedProfiles><initialWindow><content>ModRuntimeProbe.swf</content>
<visible>true</visible><width>640</width><height>960</height><renderMode>direct</renderMode><depthAndStencil>true</depthAndStencil>
</initialWindow></application>'''.replace("UNIQUE", uuid.uuid4().hex), "utf-8")
    source = work / "media-hero"
    shutil.copytree(ROOT / "examples/mods/new-minimal", source)
    manifest = json.loads((source / "manifest.json").read_text("utf-8"))
    manifest["packageId"] = str(uuid.uuid4())
    manifest["name"] = "Runtime QA Media Hero"
    if args.mode not in ("minimal", "scopes"):
        manifest["requiredCapabilities"] += ["asset.image", "asset.sound"]
    heroes = json.loads((source / "heroes.json").read_text("utf-8"))
    hero = heroes["heroes"][0]
    hero["name"] = "运行验收英雄"
    hero["baseStats"]["health"] = 5000
    hero["baseStats"]["attack"] = 1500
    hero["leadership"] = 1
    if args.mode not in ("minimal", "scopes"):
        hero["presentation"]["portrait"] = "self:asset/portrait.png"
        hero["presentation"]["icon"] = "self:asset/portrait.png"
        hero["presentation"]["voice"] = "self:asset/voice.mp3"
        (source / "assets").mkdir()
        (source / "assets/portrait.png").write_bytes(png())
        shutil.copy2(ROOT / "client/resources/app/assets/audio/A_1001.mp3", source / "assets/voice.mp3")
    (source / "heroes.json").write_text(json.dumps(heroes, ensure_ascii=False), "utf-8")
    (source / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False), "utf-8")
    archive = work / "media-hero.heropack"
    pack_directory(source, archive)
    backend = Backend(work / "local.sqlite3", ROOT / "config/reconstruction/full-config.json", work / "mods")
    account = "mod-probe-" + uuid.uuid4().hex
    password = uuid.uuid4().hex
    credentials = {"pf": "local", "session_key": account, "sessionid": password}
    backend.call({"method": "user.register", "params": {**credentials, "actionID": "qa-register"}})
    owner = backend.call({"method": "user.login", "params": {**credentials, "actionID": "qa-login"}})["data"]
    if args.mode == "base":
        iid = next(card for card in backend.players.profile(owner["uid"])["team"][0] if card)
        aid = iid.split("|")[0]
    else:
        meta = backend.mods.install_bytes(archive.read_bytes())
        selection = {key: meta[key] for key in ("packageId", "version", "digest")}
        selection["enabled"] = True
        plan = backend.mods.plan(owner["uid"], {"expectedRevision": 0, "selections": [selection]})
        if not plan["valid"]:
            raise RuntimeError(plan)
        backend.mods.apply(owner["uid"], {"expectedRevision": 0, "selections": [selection], "planDigest": plan["planDigest"], "actionID": "qa-apply"})
        aid = next(a for a, h in backend.mods.config(owner["uid"])["mod_runtime"]["heroes"].items() if h["kind"] == "new")
        grant = backend.mods.test_grant(owner["uid"], {"aid": aid, "actionID": "qa-grant"})
        iid = next(iter(grant["new_avatars"]))

    def formation(profile):
        profile["team"][0][0] = iid
        return profile, {}

    backend.players.atomic_update(owner["uid"], formation)
    if args.mode in ("missing", "restored"):
        before = backend.players.profile(owner["uid"])
        backend.mods.catalog.uninstall(meta["packageId"], meta["version"], meta["digest"])
        missing = backend.mods.config(owner["uid"])["mod_runtime"]["heroes"][aid]
        if missing["available"] is not False:
            raise AssertionError("Deleted package did not freeze its saved hero")
        if args.mode == "restored":
            backend.mods.install_bytes(archive.read_bytes())
            if backend.players.profile(owner["uid"])["avatars"][iid] != before["avatars"][iid]:
                raise AssertionError("Restoring a package changed saved hero progress")
    probe_settings = {"account": account, "password": password, "expectedHero": aid,
                      "expectedInstance": iid, "mode": args.mode, "outputDirectory": str(work)}
    if args.mode == "scopes":
        sys.path.insert(0, str(ROOT / "scripts/probes"))
        from mod_scope_fixture import setup_a11_scope
        probe_settings.update(setup_a11_scope(backend, owner, work))
    if args.mode in ("import", "directory-import"):
        import_source = work / "import-target"
        shutil.copytree(ROOT / "examples/mods/new-minimal", import_source)
        import_manifest = json.loads((import_source / "manifest.json").read_text("utf-8"))
        import_manifest["packageId"] = str(uuid.uuid4())
        import_manifest["name"] = "Native Import QA"
        (import_source / "manifest.json").write_text(json.dumps(import_manifest), "utf-8")
        pack_directory(import_source, work / "native-import.heropack")
        probe_settings["expectedImportedPackage"] = import_manifest["packageId"]
        if args.mode == "directory-import":
            inbox = work / "mods/inbox"
            inbox.mkdir(exist_ok=True)
            shutil.copy2(work / "native-import.heropack", inbox / "native-import.heropack")
    service = make_server("127.0.0.1", 0, backend)
    thread = threading.Thread(target=service.serve_forever, daemon=True)
    thread.start()
    port = service.server_address[1]
    if args.serve_only:
        (work / "probe.json").write_text(json.dumps(probe_settings), "utf-8")
        session = {"port": port, "hero": aid, "database": str(work / "local.sqlite3"),
                   "probe_settings": str(work / "probe.json"), "stop_file": str(work / "stop")}
        (work / "session.json").write_text(json.dumps(session, indent=2), "utf-8")
        print(json.dumps(session, ensure_ascii=False), flush=True)
        try:
            deadline = time.monotonic() + 1800
            while time.monotonic() < deadline and not (work / "stop").exists():
                time.sleep(1)
        finally:
            service.shutdown()
            service.server_close()
            backend.db.close()
            backend.clock.close()
        return 0
    (app / "bootstrap.json").write_text(json.dumps({"port": port, "version": "1.0.2"}), "utf-8")
    (app / "probe.json").write_text(json.dumps(probe_settings), "utf-8")
    command = [str(package / "air/bin/adl64.exe"), "-runtime", str(package / "air/runtimes/air/win64"),
               "-profile", "extendedDesktop", str(descriptor), str(app)]
    try:
        with (work / "adl.log").open("wb") as log:
            result = subprocess.run(command, cwd=app, stdout=log, stderr=log, timeout=620,
                                    creationflags=getattr(subprocess, "CREATE_NO_WINDOW", 0))
        probe_log = (work / "mod-probe.log").read_text("utf-8") if (work / "mod-probe.log").exists() else ""
        report = {"passed": result.returncode == 0 and "PROBE_FINISHED" in probe_log and "UNCAUGHT" not in probe_log,
                  "returncode": result.returncode, "swf_sha256": hashlib.sha256((app / "MainLLOL.swf").read_bytes()).hexdigest(),
                  "hero": aid, "instance": iid, "mode": args.mode, "log": probe_log, "database": str(work / "local.sqlite3"),
                  "client_errors": str(ROOT / "data/logs/client-errors.log")}
        (work / "report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), "utf-8")
        print(json.dumps(report, ensure_ascii=False, indent=2))
        return 0 if report["passed"] else 1
    finally:
        service.shutdown()
        service.server_close()
        backend.db.close()
        backend.clock.close()
        (app / "probe.json").unlink(missing_ok=True)


if __name__ == "__main__":
    raise SystemExit(main())
