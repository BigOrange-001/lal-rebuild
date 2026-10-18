"""Collect evidence only from the isolated, debuggable Mod QA application."""
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
from pathlib import Path

APP = "org.bigorange.lal.mods.qa"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", type=Path, required=True)
    parser.add_argument("--serial", default="emulator-5554")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--apk", type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=False)
    files = {}
    current = ""
    for name in ("mod-probe.log", "mod-manager.png", "mod-battle.png", "mod-battle-finished.png",
                 "mod-imported.png", "mod-missing.png"):
        if name.endswith(".png") and "CAPTURE " + Path(name).stem + "\n" not in current:
            continue
        remote = f"{APP}/Local Store/{name}"
        # The remote path is a fixed, quoted path in this test app's sandbox.
        result = subprocess.run([str(args.adb), "-s", args.serial, "exec-out",
                                 f"run-as {APP} cat '{remote}'"], capture_output=True, check=False)
        if result.returncode or result.stdout.startswith(b"cat:"):
            continue
        if name.endswith(".png") and not result.stdout.startswith(b"\x89PNG\r\n\x1a\n"):
            raise RuntimeError("ADB returned invalid PNG data for " + name)
        (args.output / name).write_bytes(result.stdout)
        files[name] = hashlib.sha256(result.stdout).hexdigest()
        if name == "mod-probe.log":
            current = "PROBE_START" + result.stdout.decode("utf-8").rsplit("PROBE_START", 1)[-1]
    log = (args.output / "mod-probe.log").read_text("utf-8")
    current = "PROBE_START" + log.rsplit("PROBE_START", 1)[-1]
    report = {"applicationId": APP, "serial": args.serial, "apk": str(args.apk.resolve()),
              "apk_sha256": hashlib.sha256(args.apk.read_bytes()).hexdigest(),
              "passed": "PROBE_FINISHED" in current and "PROBE_ERROR" not in current and "UNCAUGHT" not in current,
              "last_run": current, "files": files}
    (args.output / "report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), "utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
