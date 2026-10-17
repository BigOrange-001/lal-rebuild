"""Native sign-in preview and atomic reward boundaries."""
import datetime
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
from check_in_rewards import apply_check_in_rewards, check_in_coin
from gateway import Backend


CONFIG = Path(__file__).resolve().parents[1] / "config" / "reconstruction" / "full-config.json"


def epoch(year, month, day):
    return int(datetime.datetime(year, month, day, 4,
                                 tzinfo=datetime.timezone.utc).timestamp())


class CheckInRewardsTests(unittest.TestCase):
    def setUp(self):
        self.backend = Backend(":memory:", CONFIG)
        self.addCleanup(self.backend.db.close)
        self.now = epoch(2028, 2, 1)
        self.clock_patch = patch.object(self.backend.clock, "now", side_effect=lambda: self.now)
        self.clock_patch.start()
        self.addCleanup(self.clock_patch.stop)
        self.backend.call({"method": "user.register", "params": {
            "actionID": "register", "pf": "local", "session_key": "signer", "sessionid": "password"}})
        login = self.backend.call({"method": "user.login", "params": {
            "actionID": "login", "pf": "local", "session_key": "signer", "sessionid": "password"}})
        self.uid, self.token = login["data"]["uid"], login["data"]["sessionid"]

    def rpc(self, method, action, **params):
        return self.backend.call({"method": method, "uid": self.uid, "sessionid": self.token,
                                  "params": {"actionID": action, **params}})

    def test_first_fifth_and_vip_grant_only_one_orange_set(self):
        start = self.backend.players.profile_raw(self.uid)
        first = self.rpc("user.check_in", "day-1")
        self.assertEqual(first["data"]["check_in_reward"], {"coin": 2000})
        self.assertEqual(first["data"]["coin"] - start["coin"], 2000)
        duplicate = self.rpc("user.check_in", "new-action-same-day")
        self.assertEqual((duplicate["return_code"], duplicate["data"]["error_code"]),
                         (1, "AlreadyCheckedIn"))
        for day in range(2, 5):
            self.now = epoch(2028, 2, day)
            result = self.rpc("user.check_in", "day-" + str(day))
            self.assertEqual(result["data"]["check_in_reward"], {"coin": check_in_coin(day)})
        self.now = epoch(2028, 2, 5)
        def qualify_vip(p):
            p["vip_lv"] = 1
            p["attrs"]["vip_gift_total_coin"] = 60
            return p, {}
        self.backend.players.atomic_update(self.uid, qualify_vip)
        before = self.backend.players.profile_raw(self.uid)
        regular = self.rpc("user.check_in", "day-5")
        reward = regular["data"]["check_in_reward"]
        self.assertEqual(reward["coin"], 2800)
        self.assertEqual(len(reward["avatar"]), 1)
        aid, count = next(iter(reward["avatar"].items()))
        self.assertEqual(count, 6)
        blocked = set(self.backend.config["cfg"]["system_simple"]["skin_acquisition_blocked_heroes"])
        self.assertNotIn(aid, blocked)
        self.assertTrue(aid.endswith("_6"))
        gained = set(regular["data"]["avatars"]) - set(before["avatars"])
        self.assertEqual(len(gained), 6)
        self.assertTrue(all(iid.startswith(aid + "|") for iid in gained))
        vip = self.rpc("user.check_in", "day-5-vip", is_vip=True)
        self.assertEqual(vip["return_code"], 0, vip["data"])
        self.assertEqual(vip["data"]["check_in_reward"], {"coin": 2800})
        self.assertEqual(vip["data"]["coin"] - before["coin"], 5600)
        self.assertEqual(set(vip["data"]["avatars"]) - set(before["avatars"]), gained)
        self.assertEqual(self.rpc("user.check_in", "day-5-vip-again", is_vip=True)["data"]["error_code"],
                         "AlreadyCheckedIn")

    def test_year_projection_and_nonleap_february_last_day(self):
        config = self.backend.config
        apply_check_in_rewards(config, 2028)
        self.assertEqual(len(config["cfg"]["check_in"]["2"]), 29)
        self.assertEqual(config["cfg"]["check_in"]["2"][4]["bonus_orange_cards"], 6)
        self.assertEqual(config["cfg"]["check_in"]["2"][4]["reward"], {"coin": 2800})
        apply_check_in_rewards(config, 2028)
        self.assertEqual(config["cfg"]["check_in"]["2"][4]["reward"], {"coin": 2800})
        self.now = epoch(2027, 2, 28)
        projected = self.backend.call({"method": "sys.get_config", "params": {"actionID": "cfg-2027"}})
        self.assertEqual(len(projected["data"]["cfg"]["check_in"]["2"]), 28)
        def near_month_end(p):
            p["attrs"]["check_in"].update(m=2, month_key="2027-02", day=27, n=27,
                                           had_check=[1, 1], last_day="2027-02-27")
            return p, {}
        self.backend.players.atomic_update(self.uid, near_month_end)
        last = self.rpc("user.check_in", "feb-28")
        self.assertEqual((last["data"]["check_in"]["day"], last["data"]["check_in_reward"]["coin"]),
                         (28, 7400))
        self.now = epoch(2027, 3, 1)
        march = self.rpc("user.check_in", "mar-1")
        self.assertEqual((march["data"]["check_in"]["day"], march["data"]["check_in_reward"]),
                         (1, {"coin": 2000}))
        self.assertEqual(len(self.backend.config["cfg"]["check_in"]["2"]), 28)
        self.now = epoch(2028, 2, 29)
        def leap_eve(p):
            p["attrs"]["check_in"].update(m=2, month_key="2028-02", day=28, n=28,
                                           had_check=[1, 1], last_day="2028-02-28")
            return p, {}
        self.backend.players.atomic_update(self.uid, leap_eve)
        leap = self.rpc("user.check_in", "leap-feb-29")
        self.assertEqual((leap["data"]["check_in"]["day"], leap["data"]["check_in_reward"]["coin"]),
                         (29, 7600))
        self.assertEqual(len(self.backend.config["cfg"]["check_in"]["2"]), 29)


if __name__ == "__main__":
    unittest.main()
