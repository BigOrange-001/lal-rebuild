"""Restore the exact removed package in a disposable runtime-probe fixture."""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "server"))
from gateway import Backend


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--session", type=Path, required=True)
    args = parser.parse_args()
    work = args.session.resolve().parent
    session = json.loads(args.session.read_text("utf-8"))
    settings_path = Path(session["probe_settings"]).resolve()
    database = Path(session["database"]).resolve()
    if not database.is_relative_to(work) or not settings_path.is_relative_to(work):
        raise ValueError("Only an isolated probe fixture is accepted")
    settings = json.loads(settings_path.read_text("utf-8"))
    if settings.get("mode") != "missing":
        raise ValueError("Expected a completed missing-package QA fixture")
    backend = Backend(database, ROOT / "config/reconstruction/full-config.json", work / "mods")
    try:
        reply = backend.call({"method": "user.login", "params": {"pf": "local", "session_key": settings["account"],
                     "sessionid": settings["password"], "actionID": "qa-restore-login"}})
        uid = reply["data"]["uid"]
        before = backend.players.profile(uid)
        archive = work / "media-hero.heropack"
        installed = backend.mods.install_bytes(archive.read_bytes())
        config = backend.mods.config(uid)
        after = backend.players.profile(uid)
        iid = settings["expectedInstance"]
        if before["avatars"][iid] != after["avatars"][iid] or before["team"] != after["team"]:
            raise AssertionError("Restoring package content changed saved progress or formation")
        if config["mod_runtime"]["heroes"][settings["expectedHero"]]["available"] is not True:
            raise AssertionError("The original hero did not recover")
        settings["mode"] = "restored"
        settings_path.write_text(json.dumps(settings), "utf-8")
        report = {"passed": True, "instance": iid, "package": installed["packageId"],
                  "archive_sha256": hashlib.sha256(archive.read_bytes()).hexdigest(),
                  "progress_preserved": True, "formation_preserved": True}
        (work / "restore-report.json").write_text(json.dumps(report, indent=2), "utf-8")
        print(json.dumps(report))
    finally:
        backend.db.close()
        backend.clock.close()


if __name__ == "__main__":
    raise SystemExit(main())
