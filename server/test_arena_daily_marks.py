"""Native arena reward, record and replay contract without a production account."""
import copy
import datetime
import json
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from arena_rewards import (DAILY_BATTLE_MARK, DAILY_PAID_BATTLES,
                           DAILY_RANK_MARK, apply_arena_rewards)
from gameplay_common import game_day
from player_store import GameplayFault, PlayerStore


class FixedClock:
    def __init__(self, epoch):
        self.epoch = epoch

    def now(self):
        return self.epoch


class ArenaDailyMarksTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        path = Path(__file__).resolve().parents[1] / "config/reconstruction/full-config.json"
        cls.authored = json.loads(path.read_text(encoding="utf-8"))

    def setUp(self):
        self.config = copy.deepcopy(self.authored)
        self.assertIs(apply_arena_rewards(self.config), self.config)
        self.assertIs(apply_arena_rewards(self.config), self.config)
        bands = self.config["cfg"]["ploy_system_simple"]["pvp_rank"]["lv_range_gift"]
        self.assertTrue(all(gifts["mark"] == DAILY_RANK_MARK for gifts in bands.values()))
        self.db = sqlite3.connect(":memory:", check_same_thread=False)
        self.addCleanup(self.db.close)
        # Shanghai 2026-10-17 23:59:00.
        self.clock = FixedClock(int(datetime.datetime(2026, 10, 17, 15, 59,
                tzinfo=datetime.timezone.utc).timestamp()))
        self.store = PlayerStore(self.db, self.config, self.clock)
        session = self.store.login("arena-daily-in-memory")
        self.uid, self.sessionid = session["uid"], session["sessionid"]

        def established(profile):
            profile["records"]["current_rank"] = 1
            profile["attrs"]["pvp_rank"] = 1
            profile["attrs"]["pvp_count"] = 1
            return profile, None

        self.store.atomic_update(self.uid, established)

    def rpc(self, method, params=None):
        return self.store.dispatch({"uid": self.uid, "sessionid": self.sessionid,
                                    "method": method, "params": params or {}})

    def team(self):
        saved = self.store.profile_raw(self.uid)["team"][0]
        return [[iid, slot % 3, .2 if slot < 3 else .1]
                for slot, iid in enumerate(saved) if iid]

    def battle(self, number, sign):
        rival = self.rpc("user.get_rank_list")[2][0]
        started = self.rpc("user.pk_combat_pvp", {
            "uid": rival[1], "rank": rival[0], "team": self.team(),
            "actionID": f"daily-start-{number}"})
        params = {"fight_kind": "pvp", "fight_id": started["fight_id"],
                  "sign": sign, "metadata": started["metadata"],
                  "teams": {"team_a": started["orgin_team_a"],
                            "team_b": started["orgin_team_b"]},
                  "actionID": f"daily-finish-{number}"}
        return started, params, self.rpc("user.battle_finish", params)

    def test_daily_battle_and_rank_mail_are_separate_and_once_only(self):
        initial = self.store.profile_raw(self.uid)["mark"]
        ranked = self.rpc("user.get_rank_list")
        self.assertEqual(ranked[1][0][5], DAILY_RANK_MARK)
        self.assertTrue(all(row[5] == DAILY_RANK_MARK for row in ranked[2]))
        self.assertEqual(ranked[5], initial)  # Header remains wallet balance.
        self.assertEqual(ranked[6], 0)
        first_start, first_finish, first = self.battle(0, 2)
        self.assertEqual(first["mark"], initial + DAILY_BATTLE_MARK)
        self.assertEqual(self.rpc("user.battle_finish", first_finish)["mark"], first["mark"])
        with self.assertRaises(GameplayFault) as duplicate:
            self.rpc("user.battle_finish", {**first_finish, "actionID": "new-finish-key"})
        self.assertEqual(duplicate.exception.code, "UnknownFight")
        for number in range(1, DAILY_PAID_BATTLES + 1):
            self.battle(number, 1 if number % 2 else 2)
        profile = self.store.profile_raw(self.uid)
        today = game_day(self.clock.now())
        self.assertEqual(profile["records"]["local_pvp_rank_days"][today]["count"], 11)
        self.assertEqual(profile["mark"], initial + DAILY_RANK_MARK)
        self.assertEqual(self.rpc("user.get_rank_list")[6], 11)

        messages = self.rpc("user.get_msg")["pvp_msg"]["pvp"]
        self.assertEqual(len(messages), 11)
        first_row = next(row for row in messages
                         if row["data"]["cpb_id"] == first_start["fight_id"])
        self.assertEqual(first_row["mtype"], 98155)
        self.assertIsInstance(first_row["time"], datetime.datetime)
        replay = self.rpc("user.get_combat_playback", {
            "cpb_id": first_row["data"]["cpb_id"]})
        self.assertEqual(replay["fight_id"], first_start["fight_id"])
        self.assertEqual(replay["orgin_team_a"], first_start["orgin_team_a"])
        self.assertEqual(replay["my_pr_power"], first_start["my_pr_power"])

        # Advance across the Shanghai midnight boundary. The next login
        # creates one prior-day rank mail; claiming it is idempotent.
        self.clock.epoch += 61
        self.assertEqual(game_day(self.clock.now()), "2026-10-18")
        self.store.login("arena-daily-in-memory")
        gift_messages = self.rpc("user.get_msg")["gift_msg"]
        rank_mails = [mail for mail in gift_messages.values()
                      if mail["debug_title"] == "本地竞技昨日排名奖励"]
        self.assertEqual(len(rank_mails), 1)
        self.assertEqual(rank_mails[0]["gift_dict"]["mark"], DAILY_RANK_MARK)
        self.assertEqual(rank_mails[0]["gift_dict"]["coin"], 80)
        mail_id = rank_mails[0]["id"]
        claimed = self.rpc("user.get_gift_msg", {"gk": mail_id})
        self.assertEqual(claimed["mark"], initial + 2 * DAILY_RANK_MARK)
        self.assertEqual(self.rpc("user.get_gift_msg", {"gk": mail_id})["mark"], claimed["mark"])
        self.store.login("arena-daily-in-memory")
        self.assertEqual(sum(mail["debug_title"] == "本地竞技昨日排名奖励"
                             for mail in self.rpc("user.get_msg")["gift_msg"].values()), 1)
        self.assertEqual(self.battle("next-day", 2)[2]["mark"],
                         claimed["mark"] + DAILY_BATTLE_MARK)
        self.assertEqual(self.rpc("user.get_rank_list")[6], 1)

    def test_preexisting_daily_count_at_quota_cannot_reopen_rewards(self):
        today = game_day(self.clock.now())

        def existing(profile):
            profile["records"].setdefault("local_pvp_rank_days", {})[today] = {
                "played": True, "rank": 1, "count": DAILY_PAID_BATTLES}
            return profile, None

        self.store.atomic_update(self.uid, existing)
        before = self.store.profile_raw(self.uid)["mark"]
        self.assertEqual(self.battle("existing", 1)[2]["mark"], before)


if __name__ == "__main__":
    unittest.main()
