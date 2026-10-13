"""Small clock persistence and CLI boundary tests; never use the live DB."""

import tempfile
import unittest
import sys
import contextlib
import io
import datetime
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
from game_clock import GameClock
from gameplay_common import game_day
from gameplay_energy import normalize_energy_purchase_day


class GameClockTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.database = Path(self.directory.name) / "clock.sqlite3"

    def test_advance_is_persistent_and_visible_without_restart(self):
        with patch("game_clock.boot_id", return_value="boot-1"), \
             patch("game_clock.time.time", return_value=1_797_000_000), \
             patch("game_clock.time.monotonic", return_value=1000):
            server = GameClock(self.database)
            admin = GameClock(self.database)
        self.addCleanup(server.close)
        self.addCleanup(admin.close)
        with patch("game_clock.time.monotonic", return_value=1010):
            self.assertEqual(server.now(), 1_797_000_010)
        with patch("game_clock.boot_id", return_value="boot-1"), \
             patch("game_clock.time.time", return_value=1_797_000_099), \
             patch("game_clock.time.monotonic", return_value=1010):
            before, after = admin.advance(86400)
            self.assertEqual(after - before, 86400)
            self.assertEqual(server.now(), after)
        with patch("game_clock.boot_id", return_value="boot-1"), \
             patch("game_clock.time.time", return_value=1_797_000_099), \
             patch("game_clock.time.monotonic", return_value=1011):
            reopened = GameClock(self.database)
            self.addCleanup(reopened.close)
            self.assertEqual(reopened.now(), after + 1)
        for invalid in (0, -3600, 1.5, True):
            with self.assertRaises(ValueError):
                admin.advance(invalid)

    def test_changed_os_clock_never_advances_logical_time(self):
        with patch("game_clock.boot_id", return_value="boot-1"), \
             patch("game_clock.time.time", return_value=1_797_000_000), \
             patch("game_clock.time.monotonic", return_value=1000):
            clock = GameClock(self.database)
        with patch("game_clock.time.monotonic", return_value=1031):
            self.assertEqual(clock.now(), 1_797_000_031)
        clock.close()
        # Simulate another boot or a large OS-clock edit. Resume at the last
        # committed game second rather than applying the wall-clock delta.
        with patch("game_clock.boot_id", return_value="boot-2"), \
             patch("game_clock.time.time", return_value=1_900_000_000), \
             patch("game_clock.time.monotonic", return_value=100):
            reopened = GameClock(self.database)
            self.addCleanup(reopened.close)
            self.assertEqual(reopened.now(), 1_797_000_031)

    def test_cli_advance_crosses_shanghai_day_and_resets_daily_energy(self):
        from scripts.game_time import main
        start = int(datetime.datetime(2026, 10, 13, 15, 59, 59,
                                      tzinfo=datetime.timezone.utc).timestamp())
        with patch("game_clock.boot_id", return_value="boot-day"), \
             patch("game_clock.time.time", return_value=start), \
             patch("game_clock.time.monotonic", return_value=1000):
            clock = GameClock(self.database)
            self.addCleanup(clock.close)
            profile = {"records": {"energy_purchase_day": "2026-10-13", "energy_times": 2}}
            self.assertEqual(game_day(clock.now()), "2026-10-13")
            with contextlib.redirect_stdout(io.StringIO()):
                self.assertEqual(main(["--database", str(self.database), "advance", "--hours", "1"]), 0)
            self.assertEqual(game_day(clock.now()), "2026-10-14")
            self.assertEqual(normalize_energy_purchase_day(profile, clock.now()), 0)
            with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit):
                main(["--database", str(self.database), "advance", "--days", "0"])

    def test_gateway_reply_resynchronizes_after_cli_advance(self):
        from gateway import Backend
        from scripts.game_time import main
        config = Path(__file__).resolve().parents[1] / "config/reconstruction/full-config.json"
        backend = Backend(self.database, config)
        self.addCleanup(backend.db.close)
        self.addCleanup(backend.clock.close)
        before = backend.call({"method": "sys.get_config", "params": {"actionID": "clock-before"}})
        with contextlib.redirect_stdout(io.StringIO()):
            main(["--database", str(self.database), "advance", "--days", "1"])
        after = backend.call({"method": "sys.get_config", "params": {"actionID": "clock-after"}})
        self.assertEqual(int((after["server_now"] - before["server_now"]).total_seconds()), 86400)

    def test_live_console_advances_and_rejects_nonpositive_duration(self):
        from gateway import Backend, _console_loop
        from types import SimpleNamespace
        config = Path(__file__).resolve().parents[1] / 'config/reconstruction/full-config.json'
        backend = Backend(self.database, config)
        self.addCleanup(backend.db.close)
        self.addCleanup(backend.clock.close)
        before = backend.clock.now()
        service = SimpleNamespace(backend=backend, shutdown=lambda: None)
        output = io.StringIO()
        with patch('builtins.input', side_effect=['time days 1', 'time hours 0', 'time', 'exit']), \
             contextlib.redirect_stdout(output):
            _console_loop(service)
        self.assertLessEqual(abs(backend.clock.now() - before - 86400), 1)
        self.assertIn('Game time failed:', output.getvalue())
        reply = backend.call({'method': 'sys.get_config', 'params': {'actionID': 'console-clock'}})
        self.assertEqual(int(reply['server_now'].replace(tzinfo=datetime.timezone.utc).timestamp()),
                         backend.clock.now())


if __name__ == "__main__":
    unittest.main()
