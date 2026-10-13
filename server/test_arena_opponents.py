"""Arena refresh, native preview, stale UID and retained-intent boundaries."""
import json
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from arena_opponents import highest_rarity_heroes
from bot_names import BOT_NAMES
from gameplay_competition import GameplayCompetition
from player_store import GameplayFault, PlayerStore


class ArenaOpponentsTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = json.loads((Path(__file__).resolve().parents[1] /
                                 "config/reconstruction/full-config.json").read_text(encoding="utf-8"))

    def setUp(self):
        self.db = sqlite3.connect(":memory:", check_same_thread=False)
        self.addCleanup(self.db.close)
        self.store = PlayerStore(self.db, self.config)
        self.uid = self.store.login("arena-generated")["uid"]
        self.comp = GameplayCompetition(self.store, self.config)
        def king(profile):
            profile.setdefault("records", {})["current_rank"] = 1
            profile.setdefault("attrs", {})["pvp_rank"] = 1
            profile["attrs"]["pvp_count"] = 1
            return profile, {}
        self.store.atomic_update(self.uid, king)

    def _team(self):
        saved = self.store.profile_raw(self.uid)["team"][0]
        return [[iid, slot % 3, .2 if slot < 3 else .1]
                for slot, iid in enumerate(iid for iid in saved if iid)]

    def test_king_batch_uses_highest_hero_forms_and_real_power(self):
        pool = highest_rarity_heroes(self.config["cfg"])
        self.assertGreaterEqual(len(pool), 100)
        blocked = set(self.config["cfg"]["system_simple"]["skin_acquisition_blocked_heroes"])
        self.assertTrue(set(pool) & blocked)
        forms = {aid.rsplit("_", 1)[0]: aid for aid in pool}
        self.assertEqual(len(forms), len(pool))
        listed = self.comp.dispatch(self.uid, "user.get_rank_list", {})
        rows = listed[2]
        self.assertEqual([row[0] for row in rows], list(range(2, 11)))
        self.assertEqual(len(rows), 9)
        batch = self.store.profile_raw(self.uid)["records"]["pvp_opponents"]
        self.assertEqual(len({bot["name"] for bot in batch["bots"]}), 9)
        self.assertTrue(all(bot["name"] in BOT_NAMES for bot in batch["bots"]))
        self.assertEqual(batch["source_power"], self.comp._team_power(
            self.comp._current_arena_team(self.store.profile_raw(self.uid))))
        powers = []
        for index, (row, bot) in enumerate(zip(rows, batch["bots"])):
            self.assertEqual(row[1], bot["uid"])
            self.assertNotIn("r", bot["uid"])
            self.assertEqual(len(row[3]), 5)
            self.assertEqual({unit["line"] for unit in bot["units"]}, {0, 1, 2})
            aids = [unit["aid"] for unit in bot["units"]]
            self.assertEqual(len(set(aids)), 5)
            self.assertTrue(all(forms[aid.rsplit("_", 1)[0]] == aid for aid in aids))
            actual = self.comp._team_power(bot["units"])
            powers.append(actual)
            self.assertEqual(actual, bot["power"])
            target = batch["source_power"] * (.5 + .75 * index / 8)
            self.assertLess(abs(actual - target) / target, .015)
            preview = self.comp.dispatch(self.uid, "user.get_battle_users",
                                         {"users": [[bot["uid"]]]})
            self.assertEqual(preview[bot["uid"]]["data"], row[3])
        self.assertEqual(powers, sorted(powers))
        self.assertEqual(self.comp.dispatch(self.uid, "user.get_rank_list", {})[2], rows)

    def test_refresh_rebuilds_roster_and_old_fight_remains_stable(self):
        old = self.comp.dispatch(self.uid, "user.get_rank_list", {})[2]
        rival = old[0]
        started = self.comp.dispatch(self.uid, "user.pk_combat_pvp",
                                     {"uid": rival[1], "rank": rival[0],
                                      "team": self._team(), "actionID": "arena-start-old"})
        self.assertEqual(started["pr_power"], self.comp._team_power(started["orgin_team_b"]))
        changed = self.comp.dispatch(self.uid, "user.refresh_pvp_opponents",
                                     {"actionID": "arena-refresh-one"})
        self.assertEqual(len(changed[2]), 9)
        self.assertNotEqual([row[1] for row in old], [row[1] for row in changed[2]])
        self.assertNotEqual([row[3] for row in old], [row[3] for row in changed[2]])
        replay = self.comp.dispatch(self.uid, "user.refresh_pvp_opponents",
                                    {"actionID": "arena-refresh-one"})
        self.assertEqual(replay, changed)
        self.assertEqual(self.store.profile_raw(self.uid)["records"]["pvp_opponent_generation"], 2)
        with self.assertRaises(GameplayFault) as stale:
            self.comp.dispatch(self.uid, "user.pk_combat_pvp",
                               {"uid": rival[1], "rank": rival[0],
                                "team": self._team(), "actionID": "stale-new-start"})
        self.assertEqual(stale.exception.code, "UnknownOpponent")
        self.assertEqual(self.comp.dispatch(self.uid, "user.pk_combat_pvp",
                                   {"uid": rival[1], "rank": rival[0],
                                    "team": self._team(), "actionID": "arena-start-old"}), started)
        finish = {"fight_kind": "pvp", "fight_id": started["fight_id"], "sign": 1,
                  "metadata": started["metadata"],
                  "teams": {"team_a": started["orgin_team_a"],
                            "team_b": started["orgin_team_b"]},
                  "actionID": "arena-finish-old"}
        won = self.comp.dispatch(self.uid, "user.battle_finish", finish)
        self.assertEqual(won["current_rank"], 1)
        history = self.comp.dispatch(self.uid, "user.get_rank_list", {})[3]
        self.assertTrue(any(row[1] == rival[1] and row[3] == rival[3] for row in history))
        previous = self.comp.dispatch(self.uid, "user.get_battle_users",
                                      {"users": [[rival[1]]]})
        self.assertEqual(previous[rival[1]]["data"], rival[3])
        playback = self.comp.dispatch(self.uid, "user.get_combat_playback",
                                      {"cpb_id": started["fight_id"]})
        self.assertEqual(playback["orgin_team_b"], started["orgin_team_b"])

    def test_existing_first_robot_and_fragment_start_still_work(self):
        def first(profile):
            profile["records"]["current_rank"] = 100
            profile["attrs"]["pvp_rank"] = 100
            profile["attrs"]["pvp_count"] = 0
            return profile, {}
        self.store.atomic_update(self.uid, first)
        robot = self.comp.dispatch(self.uid, "user.pk_combat_pvp",
                                   {"uid": "r999999999_6_0", "rank": 99,
                                    "team": self._team(), "actionID": "first-robot"})
        self.assertTrue(robot["orgin_team_b"])
        one_lane = [[row[0], 0, row[2]] for row in self._team()]
        fragment = self.comp.dispatch(self.uid, "user.pk_combat_fragment",
                                      {"uid": "b_001",
                                       "eid": self.comp.side["fragment_eids"][0],
                                       "fragment_index": 0, "team": one_lane,
                                       "actionID": "fragment-legacy"})
        self.assertTrue(fragment["orgin_team_b"])

    def test_rank_change_rebuilds_nine_without_self_rank_collision(self):
        old = self.comp.dispatch(self.uid, "user.get_rank_list", {})
        def change(profile):
            profile["records"]["current_rank"] = 2
            profile["attrs"]["pvp_rank"] = 2
            return profile, {}
        self.store.atomic_update(self.uid, change)
        current = self.comp.dispatch(self.uid, "user.get_rank_list", {})
        self.assertEqual(current[0], 2)
        self.assertEqual(len(current[2]), 9)
        self.assertNotIn(2, [row[0] for row in current[2]])
        self.assertNotEqual([row[1] for row in old[2]], [row[1] for row in current[2]])

    def test_empty_captain_slot_does_not_promote_another_hero(self):
        profile = self.store.profile_raw(self.uid)
        profile['team'][0][0] = None
        units = self.comp._current_arena_team(profile)
        self.assertTrue(units)
        self.assertTrue(all(not unit['leader'] and unit['leader_skill'] is None for unit in units))


if __name__ == "__main__":
    unittest.main()
