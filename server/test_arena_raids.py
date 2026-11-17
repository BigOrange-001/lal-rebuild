"""Top-ten arena raids: queueing, client-fought defense, rank swap and retries."""
import json
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from arena_raids import (MAX_QUEUED_RAIDS, PREPARED_POWER, RAID_TTL_SECONDS, RAID_WINDOW_SECONDS,
                         RETRY_DELAY_SECONDS)
from gameplay_competition import GameplayCompetition
from player_store import GameplayFault, PlayerStore


class FakeClock:
    def __init__(self, now):
        self.value = now

    def now(self):
        return self.value


class ArenaRaidsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = json.loads((Path(__file__).resolve().parents[1] /
                                 "config/reconstruction/full-config.json").read_text(encoding="utf-8"))

    def setUp(self):
        self.db = sqlite3.connect(":memory:", check_same_thread=False)
        self.addCleanup(self.db.close)
        self.clock = FakeClock(1_800_000_000)
        self.store = PlayerStore(self.db, self.config, clock=self.clock)
        self.uid = self.store.login("arena-raids")["uid"]
        self.comp = GameplayCompetition(self.store, self.config)
        self._set_rank(3)

    def _set_rank(self, rank):
        def change(profile):
            profile.setdefault("records", {})["current_rank"] = rank
            profile.setdefault("attrs", {})["pvp_rank"] = rank
            profile["attrs"]["pvp_count"] = 5
            return profile, {}
        self.store.atomic_update(self.uid, change)

    def _team(self):
        saved = self.store.profile_raw(self.uid)["team"][0]
        return [[iid, slot % 3, .2 if slot < 3 else .1]
                for slot, iid in enumerate(iid for iid in saved if iid)]

    def _wait_for_raid(self, windows=40):
        self.comp.dispatch(self.uid, "user.get_rank_list", {})
        for _ in range(windows):
            self.clock.value += RAID_WINDOW_SECONDS
            listed = self.comp.dispatch(self.uid, "user.get_arena_raids", {})
            if listed["raids"]:
                return listed
        self.fail("no raid was queued")

    def _fight(self, raid, sign, action):
        started = self.comp.dispatch(self.uid, "user.pk_combat_raid", {
            "raid_id": raid["raid_id"], "uid": raid["uid"], "rank": raid["rank"],
            "team": self._team(), "actionID": action + "-start"})
        self.assertEqual(started["fight_kind"], "pvp")
        self.assertTrue(started["arena_raid"])
        return started, self.comp.dispatch(self.uid, "user.battle_finish", {
            "fight_kind": "pvp", "fight_id": started["fight_id"], "sign": sign,
            "metadata": started["metadata"],
            "teams": {"team_a": started["orgin_team_a"], "team_b": started["orgin_team_b"]},
            "actionID": action + "-finish"})

    def test_raids_come_from_lower_ranked_npcs_at_prepared_strength(self):
        listed = self._wait_for_raid()
        self.assertLessEqual(len(listed["raids"]), MAX_QUEUED_RAIDS)
        own = self.comp._team_power(self.comp._current_arena_team(self.store.profile_raw(self.uid)))
        batch = self.store.profile_raw(self.uid)["records"]["pvp_opponents"]
        for raid in listed["raids"]:
            self.assertGreater(raid["rank"], 3)
            self.assertIn(raid["uid"], {bot["uid"] for bot in batch["bots"]})
            self.assertEqual(len(raid["data_base"]), 5)
            low, high = PREPARED_POWER
            self.assertGreaterEqual(raid["power"], own * low * .8)
            self.assertLessEqual(raid["power"], own * high * 1.2)

    def test_lost_defense_swaps_rank_without_using_daily_fights(self):
        raid = self._wait_for_raid()["raids"][0]
        before = self.store.profile_raw(self.uid)["attrs"].get("pvp_count")
        started, result = self._fight(raid, 2, "raid-lost")
        self.assertEqual(result["arena_raid"], "lost")
        self.assertEqual(result["current_rank"], raid["rank"])
        profile = self.store.profile_raw(self.uid)
        self.assertEqual(profile["attrs"]["pvp_rank"], raid["rank"])
        self.assertEqual(profile["attrs"].get("pvp_count"), before)
        self.assertEqual(result["mark"], profile["mark"])
        log = profile["records"]["arena_raids"]["log"][0]
        self.assertEqual((log["result"], log["old_rank"], log["new_rank"]), ("lost", 3, raid["rank"]))
        report = profile["records"]["local_pvp_battle_reports"][0]
        self.assertEqual(report["cpb_id"], started["fight_id"])
        self.assertTrue(report["users"]["user_b"][2].startswith("防守 · "))
        self.assertNotIn(raid["uid"], [row[1] for row in profile["records"].get("pvp_history_loss", [])])

    def test_defended_raid_keeps_rank_and_may_return_with_new_lanes(self):
        raid = self._wait_for_raid()["raids"][0]
        _, result = self._fight(raid, 1, "raid-held")
        self.assertEqual(result["arena_raid"], "defended")
        self.assertEqual(result["current_rank"], 3)
        state = self.store.profile_raw(self.uid)["records"]["arena_raids"]
        self.assertNotIn(raid["raid_id"], [row["id"] for row in state["queue"]])
        if state["retries"]:
            retry = state["retries"][0]
            self.assertEqual(retry["attacker_uid"], raid["uid"])
            self.clock.value += RETRY_DELAY_SECONDS
            again = self.comp.dispatch(self.uid, "user.get_arena_raids", {})["raids"]
            back = [row for row in again if row["uid"] == raid["uid"]]
            self.assertTrue(back)
            self.assertEqual(back[0]["attempt"], 1)
        # A finished raid cannot be fought twice.
        with self.assertRaises(GameplayFault):
            self.comp.dispatch(self.uid, "user.pk_combat_raid", {
                "raid_id": raid["raid_id"], "team": self._team(), "actionID": "raid-twice"})

    def test_no_raids_outside_top_ten_and_stale_raids_expire(self):
        raid = self._wait_for_raid()["raids"][0]
        self.clock.value += RAID_TTL_SECONDS + 1
        remaining = self.comp.dispatch(self.uid, "user.get_arena_raids", {})["raids"]
        self.assertNotIn(raid["raid_id"], [row["raid_id"] for row in remaining])
        self._set_rank(40)
        for _ in range(10):
            self.clock.value += RAID_WINDOW_SECONDS
            self.assertEqual(self.comp.dispatch(self.uid, "user.get_arena_raids", {})["raids"], [])


if __name__ == "__main__":
    unittest.main()
