"""Focused native-stage and settlement boundaries for material activities/tower."""
import json
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from activity_tower_overlay import apply_resource_overhaul
from battle_engine import serialize_stage_team
from campaign_workbook_overlay import _power
from gameplay_combat import GameplayCombat
from gameplay_roster import GameplayRosterEquipment
from player_store import GameplayFault, PlayerStore


class ActivityTowerTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source = json.loads((Path(__file__).resolve().parents[1] /
                             "config/reconstruction/full-config.json").read_text(encoding="utf-8"))
        source["cfg"]["system_simple"].setdefault("skill_biscuit_avatar_id", "A_6992_4")
        cls.config, cls.report = apply_resource_overhaul(source)

    def make_store(self, name):
        db = sqlite3.connect(":memory:", check_same_thread=False)
        store = PlayerStore(db, self.config)
        uid = store.login(name)["uid"]
        combat = GameplayCombat(store, self.config)
        team = [[aid, line, .2] for line, aid in enumerate(list(store.profile_raw(uid)["avatars"])[:3])]
        self.addCleanup(db.close)
        return store, uid, combat, team

    def test_color_tiers_native_power_and_three_table_publication(self):
        self.assertEqual((self.report["chapters"], self.report["stages"]), (11, 204))
        self.assertEqual(self.config["cfg_version"], json.loads((Path(__file__).resolve().parents[1] / "config/reconstruction/full-config.json").read_text(encoding="utf-8"))["cfg_version"])
        pve = self.config["pve"]
        self.assertIn("P_001", pve["battle_ploy"])
        self.assertIn("P_001_3", pve["combat_ploy"])
        for table in ("battle_ploy", "combat_ploy"):
            self.assertEqual(pve[table], self.config[table])
            self.assertEqual(pve[table], self.config["cfg"][table])
        for tier, star in enumerate((4, 5, 6, 6, 6), 1):
            stage = pve["combat_ploy"][f"P_101_{tier}"]
            self.assertTrue(all(row[0].endswith(f"_{star}") for row in stage["team2"]))
            self.assertEqual(stage["energy"], 10)
            self.assertEqual({row[3] for row in stage["team2"]}, {0, 1, 2})
            self.assertEqual(len(stage["team2"]), 6)
            self.assertEqual(stage["team2"][0][1], (60, 99, 99, 125, 125)[tier - 1])
            if tier >= 4:
                self.assertEqual(stage["team2"][0][14], 3)
                advanced = serialize_stage_team(self.config["cfg"], stage["team2"])
                self.assertEqual((advanced[0]["phase"], advanced[0]["limit_break"]), (3, 1))
        for floor, star, phase in ((1, 4, 0), (21, 5, 0), (41, 6, 0),
                                   (61, 6, 0), (81, 6, 3), (100, 6, 3),
                                   (101, 6, 3), (150, 6, 3)):
            stage = pve["combat_ploy"][f"P_200_{floor}"]
            self.assertTrue(all(row[0].endswith(f"_{star}") for row in stage["team2"]))
            snapshots = serialize_stage_team(self.config["cfg"], stage["team2"])
            self.assertEqual((snapshots[0].get("phase"), snapshots[0].get("limit_break")),
                             (phase, 1 if phase == 3 else None))
            self.assertEqual(stage["recommended_power"], _power(
                self.config["cfg"], stage["team2"], stage["enemy_unit_stats_by_diff"]["0"]))
        self.assertLess(abs(pve["combat_ploy"]["P_200_1"]["recommended_power"] - 10000), 100)
        self.assertLess(abs(pve["combat_ploy"]["P_200_150"]["recommended_power"] - 10000000000), 10000)
        skin_blocked = set(self.config["cfg"]["system_simple"]["skin_acquisition_blocked_heroes"])
        for floor in (61, 80):
            self.assertTrue(set(pve["combat_ploy"][f"P_200_{floor}"]["soul_candidates"]) <= skin_blocked)
        for floor in (1, 20, 21, 40, 41, 60):
            self.assertFalse(set(pve["combat_ploy"][f"P_200_{floor}"]["soul_candidates"]) & skin_blocked)
        self.assertNotIn("A_1226_6", pve["combat_ploy"]["P_200_41"]["soul_candidates"])
        self.assertIn("A_1226_6", pve["combat_ploy"]["P_200_61"]["soul_candidates"])
        for floor in (81, 100):
            candidates = set(pve["combat_ploy"][f"P_200_{floor}"]["soul_candidates"])
            self.assertTrue(candidates & skin_blocked)
            self.assertTrue(candidates - skin_blocked)
        invalid = list(pve["combat_ploy"]["P_200_81"]["team2"][0])
        invalid[14] = 4
        with self.assertRaises(ValueError):
            serialize_stage_team(self.config["cfg"], [invalid])
        purple = list(pve["combat_ploy"]["P_200_81"]["team2"][0])
        purple[0] = next(aid for aid in self.config["cfg"]["avatar"] if aid.startswith('A_1') and aid.endswith("_5"))
        self.assertEqual(serialize_stage_team(self.config['cfg'],[purple])[0]['limit_break'],1)
        purple[0] = next(aid for aid in self.config["cfg"]["avatar"] if aid.startswith('A_1') and aid.endswith("_4"))
        with self.assertRaises(ValueError):
            serialize_stage_team(self.config["cfg"], [purple])

    def test_shared_daily_attempts_and_ordered_replay_safe_tower_reward(self):
        store, uid, combat, team = self.make_store("activity-flow")
        with self.assertRaises(GameplayFault) as locked:
            combat._start_main(uid, {"cid": "P_200_2", "diff": 0, "team": team})
        self.assertEqual(locked.exception.code, "TowerFloorLocked")
        for index, cid in enumerate(("P_101_1", "P_101_2")):
            started=combat._start_main(uid, {"cid": cid, "diff": 0, "team": team,
                                           "actionID": f"material-{index}"})
            combat._finish(uid,{'cid':cid,'diff':0,'fight_id':started['fight_id'],'sign':1,'combat_star':3,'actionID':f'material-win-{index}'})
        self.assertEqual(store.profile_raw(uid)["records"]["material_activity"]["uses"]["P_101"], 2)
        def exhaust(p):p['records']['material_activity']['uses']['P_101']=12;return p,{}
        store.atomic_update(uid,exhaust)
        with self.assertRaises(GameplayFault) as exhausted:
            combat._start_main(uid, {"cid": "P_101_3", "diff": 0, "team": team})
        self.assertEqual(exhausted.exception.code, "ActivityAttemptsExhausted")
        started = combat._start_main(uid, {"cid": "P_200_1", "diff": 0, "team": team})
        finish = {"cid": "P_200_1", "diff": 0, "fight_id": started["fight_id"],
                  "sign": 1, "combat_star": 3,
                  "teams": {"team_a": started["orgin_team_a"], "team_b": started["orgin_team_b"]},
                  "actionID": "tower-first"}
        won = combat._finish(uid, finish)
        self.assertEqual(won["tower_floor"], 2)
        reward = won["tower_soul_reward"]
        self.assertEqual(sum(reward.values()), 120)
        self.assertTrue(combat._finish(uid, finish)["replayed"])
        self.assertEqual(store.profile_raw(uid)["avatar_soul"], reward)
        self.assertEqual(store.profile_raw(uid)["records"]["tower_floor"], 2)

    def test_completed_exploration_starts_new_map_without_open_chests(self):
        store, uid, combat, _ = self.make_store("exploration-restart")
        def completed(profile):
            profile["exploration"].update({"stage": 13, "current_stage_finish": 0, "map_revision": 0})
            return profile, {}
        store.atomic_update(uid, completed)
        reply = combat._dispatch_exploration(uid, "user.exploration_start", {})
        state = store.profile_raw(uid)["exploration"]
        self.assertEqual((reply["stage"], state["stage"], state["map_revision"]), (1, 1, 1))
        combat._dispatch_exploration(uid, "user.exploration_start", {})
        self.assertEqual(store.profile_raw(uid)["exploration"]["map_revision"], 1)

    def test_skin_tower_soul_credit_is_issued_once(self):
        store, uid, combat, team = self.make_store("skin-soul-credit")
        def unlock(profile):
            profile["records"]["tower_floor"] = 61
            return profile, {}
        store.atomic_update(uid, unlock)
        started = combat._start_main(uid, {"cid": "P_200_61", "diff": 0, "team": team})
        finish = {"cid": "P_200_61", "diff": 0, "fight_id": started["fight_id"],
                  "sign": 1, "combat_star": 3,
                  "teams": {"team_a": started["orgin_team_a"], "team_b": started["orgin_team_b"]},
                  "actionID": "skin-floor-61"}
        won = combat._finish(uid, finish)
        aid = next(iter(won["tower_soul_reward"]))
        self.assertEqual(won["tower_soul_reward"][aid], 120)
        self.assertEqual(store.profile_raw(uid)["attrs"]["tower_skin_soul_credit"][aid], 120)
        self.assertTrue(combat._finish(uid, finish)["replayed"])
        self.assertEqual(store.profile_raw(uid)["attrs"]["tower_skin_soul_credit"][aid], 120)

    def test_experience_activity_grants_storable_feed_cards_once(self):
        stage = self.config["combat_ploy"]["P_101_4"]
        self.assertEqual(stage["reward"]["heroes"], [{"aid": "A_6996_5", "num": 20}])
        self.assertNotIn("activity_avatar_exp", stage)
        store, uid, combat, team = self.make_store("experience-book-reward")
        leader = team[0][0]
        before = store.profile_raw(uid)["avatars"][leader]["exp"]
        started = combat._start_main(uid, {"cid": "P_101_1", "diff": 0, "team": team})
        finish = {"cid": "P_101_1", "diff": 0, "fight_id": started["fight_id"],
                  "sign": 1, "combat_star": 3,
                  "teams": {"team_a": started["orgin_team_a"], "team_b": started["orgin_team_b"]},
                  "actionID": "book-grant-once"}
        won = combat._finish(uid, finish)
        book_ids = [iid for iid, card in won["get_avatars"].items()
                    if card["aid"].split("|")[0] == "A_6996_5"]
        self.assertEqual(len(book_ids), 5)
        self.assertEqual(store.profile_raw(uid)["avatars"][leader]["exp"], before)
        roster = GameplayRosterEquipment(store, self.config)
        self.assertEqual(roster._hero_offer_exp(store.profile_raw(uid)["avatars"][book_ids[0]]), 50000)
        self.assertTrue(combat._finish(uid, finish)["replayed"])
        self.assertEqual(len([card for card in store.profile_raw(uid)["avatars"].values()
                              if card["aid"].split("|")[0] == "A_6996_5"]), 5)


if __name__ == "__main__":
    unittest.main()
