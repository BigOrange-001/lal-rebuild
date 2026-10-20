"""System game time with a durable shared offset for admin advances."""

from __future__ import annotations

import datetime
import sqlite3
import threading
import time
from decimal import Decimal, InvalidOperation
from pathlib import Path


def duration_seconds(value: str, unit: int) -> int:
    """Positive durations shared by the live console and standalone CLI."""
    try:
        seconds = Decimal(value) * unit
    except InvalidOperation as error:
        raise ValueError('duration must be a positive number') from error
    if not seconds.is_finite() or seconds <= 0 or seconds != seconds.to_integral_value():
        raise ValueError('duration must be positive whole seconds')
    return int(seconds)


class GameClock:
    def __init__(self, database: str | Path | sqlite3.Connection):
        self._owns_connection = not isinstance(database, sqlite3.Connection)
        self._db = (sqlite3.connect(str(database), timeout=0, check_same_thread=False)
                    if self._owns_connection else database)
        self._lock = threading.RLock()
        with self._lock:
            # Ignore legacy monotonic anchors: upgraded saves start at system time.
            self._db.execute("""CREATE TABLE IF NOT EXISTS game_clock_offset (
                id INTEGER PRIMARY KEY CHECK(id=1), seconds INTEGER NOT NULL)""")
            self._db.execute("INSERT OR IGNORE INTO game_clock_offset VALUES(1,0)")
            self._db.commit()

    def close(self) -> None:
        if self._owns_connection:
            with self._lock:
                self._db.close()

    def _offset(self) -> int:
        row = self._db.execute("SELECT seconds FROM game_clock_offset WHERE id=1").fetchone()
        if row is None:
            raise RuntimeError("game clock offset row is missing")
        return int(row[0])

    def now(self) -> int:
        """Follow system calendar changes and shared CLI advances immediately."""
        with self._lock:
            return int(time.time() + self._offset())

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
                offset = self._offset()
                before = time.time() + offset
                after = before + seconds
                self._db.execute("UPDATE game_clock_offset SET seconds=? WHERE id=1",
                                 (offset + seconds,))
                self._db.commit()
                return int(before), int(after)
            except Exception:
                self._db.rollback()
                raise


def utc_datetime(epoch: int) -> datetime.datetime:
    """Naive UTC datetime required by the original client's AMF Date."""
    return datetime.datetime.fromtimestamp(epoch, datetime.timezone.utc).replace(tzinfo=None)
