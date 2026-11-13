"""Chaquopy-facing adapter for the bundled server.

Nothing upstream is modified: this module drives ``gateway`` and its helpers
from Java. The server resolves its project root from ``__file__`` and reads
``ROOT/VERSION`` at import time, so ``prepare`` puts the unpacked tree on
``sys.path`` and moves the cwd there before anything from the package is
imported.

The console thread blocks on ``input()``. Shutdown feeds it ``exit`` and then
closes stdin to release the blocked read. The upstream ``exit`` branch stops
the serve loop and closes the database in ``main()``'s ``finally``.
"""
from __future__ import annotations

import json
from collections import deque
import os
import pathlib
import sqlite3
import sys
import threading
import gzip
import shutil
import tempfile
from contextlib import contextmanager

class _Events:
    """Line-buffered bridge from Python output to the Android callback."""

    def __init__(self, callback, prefix=""):
        self._callback = callback
        self._prefix = prefix
        self._pending = ""

    def write(self, text):
        text = str(text)
        if not text:
            return 0
        self._pending += text
        while "\n" in self._pending:
            line, self._pending = self._pending.split("\n", 1)
            self.line(line)
        return len(text)

    def line(self, text):
        text = text.rstrip("\r")
        if not text:
            return
        self._dispatch(text)
        self._callback.onLog(self._prefix + text)

    def _dispatch(self, text):
        """Report the server's own machine-readable replies as events."""
        if text.startswith("AMF gateway "):
            self._callback.onReady(text)
            return True
        stripped = text.strip()
        if stripped.startswith("{") and stripped.endswith("}"):
            try:
                payload = json.loads(stripped)
            except ValueError:
                return False
            if not isinstance(payload, dict):
                return False
            if "address" in payload:
                # Java parses this with org.json, so it must arrive as a JSON
                # string; handing over the Python dict would reach the callback
                # as a PyObject and fail the String parameter binding.
                self._callback.onStats(json.dumps(payload, ensure_ascii=False))
                return True
            return False
        return False

    def flush(self):
        if self._pending:
            line, self._pending = self._pending, ""
            self.line(line)

    def isatty(self):
        return False


class _Bridge:
    """stdin replacement that hands the upstream console our commands."""

    def __init__(self, lock):
        self._lock = lock
        self._lines = deque()
        self._closed = False

    def feed(self, text):
        with self._lock:
            if self._closed or not text.strip() or "\n" in text or "\r" in text:
                return False
            self._lines.append(text.strip() + "\n")
        return True

    def release(self):
        """Unblock the server's ``input()`` so its thread can finish."""
        with self._lock:
            self._closed = True

    def read(self, size=0):
        return self.readline(size)

    def readline(self, size=0):
        while True:
            with self._lock:
                if self._lines:
                    return self._lines.popleft()
                if self._closed:
                    return ""
            # input() is waiting in another thread; a short idle keeps this
            # thread from spinning while that one is scheduled.
            threading.Event().wait(0.05)

    def readlines(self, hint=0):
        return []

    def close(self):
        self.release()


_EVENTS = None
_STDIN = None
_LOCK = threading.RLock()


def prepare(runtime_dir: str) -> str:
    root = pathlib.Path(runtime_dir).resolve()
    server = root / "server"
    if not server.is_dir():
        raise RuntimeError(f"runtime server directory is missing: {server}")
    os.chdir(root)
    entry = str(server)
    if entry not in sys.path:
        sys.path.insert(0, entry)
    return str(root)


def install(callback) -> None:
    """Route server output to ``callback`` and give its console a command feed."""
    global _EVENTS, _STDIN
    _EVENTS = _Events(callback)
    _STDIN = _Bridge(_LOCK)
    sys.stdout = _EVENTS
    sys.stderr = _Events(callback, prefix="[stderr] ")
    sys.stdin = _STDIN


def log(message: str) -> None:
    if _EVENTS is None:
        print(message, file=sys.__stdout__, flush=True)
        return
    _EVENTS.line(str(message))


def command(line: str) -> bool:
    if _STDIN is None:
        return False
    return _STDIN.feed(line)


def run(runtime_dir: str, host: str, port: int, database: str, config: str) -> None:
    """Run the upstream gateway until it stops. Called on a worker thread."""
    prepare(runtime_dir)
    from gateway import main as gateway_main

    sys.argv = [
        "gateway.py",
        "--host", host,
        "--port", str(port),
        "--database", database,
        "--config", config,
    ]
    try:
        gateway_main()
    finally:
        _release_console()


def _release_console() -> None:
    """main() returned, so its console thread no longer needs a command feed."""
    if _STDIN is not None:
        _STDIN.release()
    if _EVENTS is not None:
        _EVENTS.flush()


def stop() -> None:
    """Ask the running server to shut down on its own terms."""
    command("exit")
    _release_console()


def snapshot(source: str, target: str) -> None:
    """Copy a live database to ``target`` without disturbing the server.

    SQLite's backup API walks the pages under its own lock, so a snapshot taken
    while the server is serving is consistent without pausing it.
    """
    source_path = pathlib.Path(source)
    if not source_path.is_file():
        raise RuntimeError(f"database is missing: {source_path}")
    target_path = pathlib.Path(target)
    if source_path.resolve() == target_path.resolve():
        raise RuntimeError('snapshot must not replace the live database')
    target_path.parent.mkdir(parents=True, exist_ok=True)
    target_path.unlink(missing_ok=True)
    origin = sqlite3.connect(str(source_path))
    destination = sqlite3.connect(str(target_path))
    try:
        origin.backup(destination)
        destination.commit()
        from ledger_codec import compact_ledger
        compact_ledger(destination)
    finally:
        destination.close()
        origin.close()


@contextmanager
def _expanded_database(path):
    path = pathlib.Path(path)
    with path.open('rb') as stream:
        compressed = stream.read(2) == b'\x1f\x8b'
    if not compressed:
        yield path
        return
    with tempfile.TemporaryDirectory(prefix='lal-save-') as directory:
        expanded = pathlib.Path(directory) / 'save.sqlite3'
        with gzip.open(path, 'rb') as source, expanded.open('wb') as target:
            shutil.copyfileobj(source, target, 65536)
        yield expanded


def verify(path: str) -> str:
    with _expanded_database(path) as expanded:
        result = json.loads(_verify_sqlite(expanded))
    result['bytes'] = pathlib.Path(path).stat().st_size
    return json.dumps(result)


def _verify_sqlite(path) -> str:
    """Check that a file is a usable save before it is allowed to replace one.

    Returns JSON rather than a dict: Java has no direct mapping for Python
    containers, and ``str()`` on a dict produces single-quoted pseudo-JSON that
    a real parser rejects.
    """
    candidate = pathlib.Path(path)
    if not candidate.is_file() or candidate.stat().st_size == 0:
        raise RuntimeError("存档文件为空或不存在。")
    connection = sqlite3.connect(f"file:{candidate.as_posix()}?mode=ro", uri=True)
    try:
        report = connection.execute("PRAGMA integrity_check").fetchone()[0]
        if report != "ok":
            raise RuntimeError(f"存档已损坏：{report}")
        tables = sorted(
            row[0]
            for row in connection.execute(
                "SELECT name FROM sqlite_master WHERE type='table'"
            )
        )
    finally:
        connection.close()
    if "accounts" not in tables or "players" not in tables:
        raise RuntimeError("该文件不是本游戏的存档。")
    return json.dumps({"tables": len(tables), "bytes": candidate.stat().st_size})


def import_database(source: str, target: str) -> None:
    """Replace the live database with a verified copy of ``source``."""
    target_path = pathlib.Path(target)
    target_path.parent.mkdir(parents=True, exist_ok=True)
    staged = target_path.with_suffix(target_path.suffix + ".importing")
    staged.unlink(missing_ok=True)
    try:
        with _expanded_database(source) as expanded:
            _verify_sqlite(expanded)
            origin = sqlite3.connect(str(expanded))
            destination = sqlite3.connect(str(staged))
            try:
                origin.backup(destination)
                destination.commit()
                from ledger_codec import compact_ledger
                compact_ledger(destination)
            finally:
                destination.close()
                origin.close()
        os.replace(staged, target_path)
    finally:
        staged.unlink(missing_ok=True)
