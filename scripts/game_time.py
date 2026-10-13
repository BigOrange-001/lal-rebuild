"""Show or advance the persistent local game clock without changing OS time."""

from __future__ import annotations

import argparse
import datetime
import sqlite3
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "server"))
from game_clock import GameClock, duration_seconds  # noqa: E402


def positive_seconds(value: str, unit: int) -> int:
    try:
        return duration_seconds(value, unit)
    except ValueError as error:
        raise argparse.ArgumentTypeError(str(error)) from error


def describe(epoch: int) -> str:
    utc = datetime.datetime.fromtimestamp(epoch, datetime.timezone.utc)
    shanghai = utc.astimezone(datetime.timezone(datetime.timedelta(hours=8)))
    return f"{utc:%Y-%m-%d %H:%M:%S} UTC / {shanghai:%Y-%m-%d %H:%M:%S} Asia/Shanghai ({epoch})"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database", default=str(ROOT / "server" / "local.sqlite3"),
                        help="same SQLite database path used by gateway.py")
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("show")
    advance = commands.add_parser("advance")
    amount = advance.add_mutually_exclusive_group(required=True)
    amount.add_argument("--hours", type=lambda x: positive_seconds(x, 3600))
    amount.add_argument("--days", type=lambda x: positive_seconds(x, 86400))
    args = parser.parse_args(argv)
    deadline = time.monotonic() + 5
    while True:
        try:
            clock = GameClock(args.database)
            break
        except sqlite3.OperationalError as error:
            if (error.sqlite_errorcode not in (sqlite3.SQLITE_BUSY, sqlite3.SQLITE_LOCKED)
                    or time.monotonic() >= deadline):
                raise
            time.sleep(0.05)
    try:
        if args.command == "show":
            print(describe(clock.now()))
        else:
            before, after = clock.advance(args.hours if args.hours is not None else args.days)
            print(f"before: {describe(before)}")
            print(f"after:  {describe(after)}")
    finally:
        clock.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
