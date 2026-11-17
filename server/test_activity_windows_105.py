"""Activity windows stay open relative to the system clock at config load."""
import datetime
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from activity_windows_105 import HORIZON_SECONDS, apply_activity_windows_105
from gateway import load_game_config

CONFIG = Path(__file__).resolve().parents[1] / "config/reconstruction/full-config.json"


def seconds(value):
    if isinstance(value, datetime.datetime):
        return int(value.replace(tzinfo=datetime.timezone.utc).timestamp())
    return int(value["$date"]) if isinstance(value, dict) else int(value)


class ActivityWindowsTest(unittest.TestCase):
    def test_windows_end_a_year_after_load_and_starts_are_kept(self):
        now = 1_830_000_000  # after the authored 2027-10 end dates
        document = load_game_config(CONFIG, now=now)
        cfg = document["cfg"]
        rows = [cfg["ploy_system_simple"][key] for key in ("roulette", "extract_avatar", "welfare", "groupon")]
        rows += [cfg["task"]["time_pay"], cfg["task"]["time_pay_loop"], cfg["battle_ploy"]["P_001"],
                 cfg["battle_ploy"]["P_101"]] + cfg["wager_festival"]["coin"]
        for row in rows:
            self.assertGreaterEqual(seconds(row["end_time"]), now + HORIZON_SECONDS)
            start = row.get("start_time", row.get("begin_time"))
            if start is not None:
                self.assertLess(seconds(start), now)
        # The authored recharge-campaign start is unchanged, so progress is kept.
        raw = load_game_config(CONFIG, now=1_790_000_000)["cfg"]["task"]["time_pay"]
        self.assertEqual(seconds(raw["begin_time"]), seconds(cfg["task"]["time_pay"]["begin_time"]))

    def test_closed_windows_stay_closed_and_later_ends_are_kept(self):
        document = {"cfg": {"ploy_system_simple": {
            "roulette": {"start_time": {"$date": 0}, "end_time": {"$date": 0}},
            "groupon": {"start_time": {"$date": 1}, "end_time": {"$date": 2_000_000_000}}}}}
        changed = apply_activity_windows_105(document, 1_800_000_000)
        self.assertEqual(changed, 0)
        self.assertEqual(document["cfg"]["ploy_system_simple"]["roulette"]["end_time"], {"$date": 0})
        self.assertEqual(document["cfg"]["ploy_system_simple"]["groupon"]["end_time"], {"$date": 2_000_000_000})


if __name__ == "__main__":
    unittest.main()
