"""Durable game time, independent of the operating-system calendar after seeding.

The stored monotonic anchor makes a second process (including the admin CLI)
observe the same live time. A reboot changes the monotonic epoch; in that case
we resume from the last persisted checkpoint instead of trusting wall time.
"""

from __future__ import annotations

import datetime
import os
import sqlite3
import threading
import time
from decimal import Decimal, InvalidOperation
from pathlib import Path


CHECKPOINT_SECONDS = 30


def duration_seconds(value: str, unit: int) -> int:
    """Positive durations shared by the live console and standalone CLI."""
    try:
        seconds = Decimal(value) * unit
    except InvalidOperation as error:
        raise ValueError('duration must be a positive number') from error
    if not seconds.is_finite() or seconds <= 0 or seconds != seconds.to_integral_value():
        raise ValueError('duration must be positive whole seconds')
    return int(seconds)


def boot_id() -> str | None:
    """Read a boot-session identity without consulting the system calendar."""
    if os.name == "nt":
        try:
            import winreg
            key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE,
                                 r"SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters")
            with key:
                value, _ = winreg.QueryValueEx(key, "BootId")
            return f"windows:{value}"
        except OSError:
            return None
    try:
        return "linux:" + Path("/proc/sys/kernel/random/boot_id").read_text(encoding="ascii").strip()
    except OSError:
        return None


class GameClock:
    def __init__(self, database: str | Path | sqlite3.Connection):
        self._owns_connection = not isinstance(database, sqlite3.Connection)
        self._db = (sqlite3.connect(str(database), timeout=0, check_same_thread=False)
                    if self._owns_connection else database)
        self._lock = threading.RLock()
        with self._lock:
            self._db.execute("""CREATE TABLE IF NOT EXISTS game_clock (
                id INTEGER PRIMARY KEY CHECK(id=1),
                logical_epoch REAL NOT NULL,
                monotonic_anchor REAL NOT NULL,
                boot_id TEXT
            )""")
            mono = time.monotonic()
            current_boot = boot_id()
            raw = self._db.execute("SELECT logical_epoch,monotonic_anchor,boot_id "
                                   "FROM game_clock WHERE id=1").fetchone()
            if raw is None:
                self._db.execute("INSERT OR IGNORE INTO game_clock VALUES(1,?,?,?)",
                                 (time.time(), mono, current_boot))
                self._db.commit()
            row = self._read()
            if (row[2] is not None and current_boot is not None and row[2] != current_boot
                    or mono < row[1]):
                # Never advance game time using a changed OS calendar or a
                # monotonic counter from an earlier boot.
                self._db.execute("UPDATE game_clock SET monotonic_anchor=?,boot_id=? WHERE id=1",
                                 (mono, current_boot or row[2]))
                self._db.commit()

    def close(self) -> None:
        if self._owns_connection:
            with self._lock:
                self._db.close()

    def _read(self) -> tuple[float, float, str | None]:
        row = self._db.execute("SELECT logical_epoch,monotonic_anchor,boot_id "
                               "FROM game_clock WHERE id=1").fetchone()
        if row is None:
            raise RuntimeError("game clock row is missing")
        return float(row[0]), float(row[1]), row[2]

    @staticmethod
    def _value(row: tuple[float, float, str | None], mono: float) -> float:
        return row[0] + max(0.0, mono - row[1])

    def now(self) -> int:
        """Current Unix-like game seconds; picks up CLI advances on next call."""
        with self._lock:
            mono = time.monotonic()
            row = self._read()
            current = self._value(row, mono)
            if self._owns_connection and mono - row[1] >= CHECKPOINT_SECONDS:
                self._checkpoint(mono)
            return int(current)

    def _checkpoint(self, mono: float) -> None:
        # Never delay a gameplay transaction just to persist elapsed seconds.
        try:
            self._db.execute("BEGIN IMMEDIATE")
        except sqlite3.OperationalError as error:
            if error.sqlite_errorcode in (sqlite3.SQLITE_BUSY, sqlite3.SQLITE_LOCKED):
                return
            raise
        try:
            row = self._read()
            if mono - row[1] >= CHECKPOINT_SECONDS:
                self._db.execute("UPDATE game_clock SET logical_epoch=?,monotonic_anchor=? WHERE id=1",
                                 (self._value(row, mono), mono))
            self._db.commit()
        except Exception:
            self._db.rollback()
            raise

    def advance(self, seconds: int) -> tuple[int, int]:
        """Atomically move only forward and return the previous/new seconds."""
        if type(seconds) is not int or seconds <= 0:
            raise ValueError("advance seconds must be a positive integer")
        with self._lock:
            deadline = time.monotonic() + 5
            while True:
                try:
                    self._db.execute("BEGIN IMMEDIATE")
                    break
                except sqlite3.OperationalError as error:
                    if (error.sqlite_errorcode not in (sqlite3.SQLITE_BUSY, sqlite3.SQLITE_LOCKED)
                            or time.monotonic() >= deadline):
                        raise
                    time.sleep(0.05)
            try:
                mono = time.monotonic()
                row = self._read()
                before = self._value(row, mono)
                after = before + seconds
                self._db.execute("UPDATE game_clock SET logical_epoch=?,monotonic_anchor=?,boot_id=? WHERE id=1",
                                 (after, mono, boot_id() or row[2]))
                self._db.commit()
                return int(before), int(after)
            except Exception:
                self._db.rollback()
                raise


def utc_datetime(epoch: int) -> datetime.datetime:
    """Naive UTC datetime required by the original client's AMF Date."""
    return datetime.datetime.fromtimestamp(epoch, datetime.timezone.utc).replace(tzinfo=None)
