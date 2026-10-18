"""Set private QA-only runtime settings; never prints test login credentials."""
from __future__ import annotations

import argparse
import json
import subprocess
from pathlib import Path

APP = "org.bigorange.lal.mods.qa"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", type=Path, required=True)
    parser.add_argument("--serial", default="emulator-5554")
    parser.add_argument("--session", type=Path, required=True)
    args = parser.parse_args()
    session = json.loads(args.session.read_text("utf-8"))
    settings = Path(session["probe_settings"]).read_bytes()
    json.loads(settings)
    adb = [str(args.adb), "-s", args.serial]
    subprocess.run(adb + ["shell", "am", "force-stop", APP], check=True)
    command = f"run-as {APP} sh -c \"cat > '{APP}/Local Store/probe-override.json'\""
    result = subprocess.run(adb + ["shell", command], input=settings, capture_output=True)
    if result.returncode or result.stderr:
        raise RuntimeError("Could not save private QA settings")
    subprocess.run(adb + ["reverse", "tcp:8080", "tcp:" + str(int(session["port"]))], check=True)
    subprocess.run(adb + ["shell", "am", "start", "-n", APP + "/.AIRAppEntry"], check=True)
    print("Started isolated QA mode " + json.loads(settings).get("mode", "media"))


if __name__ == "__main__":
    raise SystemExit(main())
