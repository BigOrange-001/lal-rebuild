"""Focused P_001 roster, power, and optional equipment boundaries."""
from __future__ import annotations

import copy
import json
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ancient_trial_drop import roll_ancient_trial_drop
from ancient_trial_overlay import (CHANCES_BP, HERO_STARS, QUALITIES,
                                   apply_ancient_trial, target_power)
from battle_engine import serialize_stage_team
from campaign_workbook_overlay import _power
from gameplay_combat import GameplayCombat
from gameplay_common import equipment_exclusive_ids
from player_store import GameplayFault, PlayerStore


class FixedRng:
    def __init__(self, value):
        self.value = value

    def randrange(self, limit):
        assert limit == 10000
        return self.value

    def choice(self, pool):
        return pool[-1]


class AncientTrialTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = json.loads((Path(__file__).resolve().parents[1] /
                                 "config/reconstruction/full-config.json").read_text(encoding="utf-8"))
        cls.config, cls.report = apply_ancient_trial(cls.source)

    def test_ten_native_stages_and_unrelated_activities(self):
        pve = self.config["pve"]
        self.assertEqual(pve["battle_ploy"]["P_001"]["combat"], 10)
        for key, row in self.source["pve"]["battle_ploy"].items():
            if key != "P_001":
                self.assertEqual(pve["battle_ploy"][key], row)
        for key, row in self.source["pve"]["combat_ploy"].items():
            if not key.startswith("P_001_"):
                self.assertEqual(pve["combat_ploy"][key], row)
        for table in ("battle_ploy", "combat_ploy"):
            self.assertEqual(pve[table], self.config[table])
            self.assertEqual(pve[table], self.config["cfg"][table])
        self.assertEqual(apply_ancient_trial(self.config)[0], self.config)
        for tier in range(1, 11):
            stage = pve["combat_ploy"][f"P_001_{tier}"]
            self.assertEqual(stage["win"], [-2])
            self.assertEqual(len(stage["team2"]), 10)
            self.assertEqual({row[3] for row in stage["team2"]}, {0, 1, 2})
            self.assertEqual(len({row[0] for row in stage["team2"]}), 10)
            self.assertTrue(all(row[0].startswith("A_1") and row[0].endswith(f"_{HERO_STARS[tier - 1]}")
                                for row in stage["team2"]))
            self.assertNotIn("items", stage["reward"])
            self.assertEqual(stage["ancient_equip_drop"]["quality"], QUALITIES[tier - 1])
            self.assertEqual(stage["ancient_equip_drop"]["chance_bp"], CHANCES_BP[tier - 1])
            units = serialize_stage_team(self.config["cfg"], stage["team2"])
            self.assertEqual(len(units), 10)
            self.assertEqual(stage["recommended_power"], target_power(tier))
            self.assertEqual(stage["enemy_snapshot_power"], _power(
                self.config["cfg"], stage["team2"], stage["enemy_unit_stats_by_diff"]["0"]))
            self.assertLessEqual(abs(stage["enemy_snapshot_power"] - target_power(tier)),
                                 max(10, target_power(tier) // 100000))
            if tier >= 9:
                self.assertTrue(all((unit.get("limit_break"), unit.get("phase")) == (1, 3)
                                    for unit in units))
                self.assertTrue(all(row[1] == 125 for row in stage["team2"]))
        self.assertEqual((target_power(1), target_power(9), target_power(10)),
                         (100000, 20000000, 80000000))

    def test_real_start_uses_ten_saved_enemy_snapshots(self):
        db = sqlite3.connect(":memory:", check_same_thread=False)
        self.addCleanup(db.close)
        store = PlayerStore(db, self.config)
        uid = store.login("ancient-trial")['uid']
        team = [[aid, line, .2] for line, aid in enumerate(list(store.profile_raw(uid)["avatars"])[:3])]
        combat = GameplayCombat(store, self.config)
        for tier in (1, 9, 10):
            cid = f"P_001_{tier}"
            started = combat._start_main(uid, {"cid": cid, "diff": 0, "team": team})
            self.assertEqual(started["win"], [-2])
            self.assertEqual(len(started["team2"]), len(started["orgin_team_b"]))
            self.assertEqual(len(started["orgin_team_b"]), 10)
            for unit, authored in zip(started["orgin_team_b"],
                                      self.config["combat_ploy"][cid]["enemy_unit_stats_by_diff"]["0"]):
                self.assertEqual(unit["aid"], authored["aid"])
                self.assertEqual((unit["hp"], unit["ap"], unit["de_ph"], unit["de_ma"]),
                                 tuple(authored[key] for key in ("hp", "ap", "de_ph", "de_ma")))
            if tier >= 9:
                self.assertTrue(all(unit.get("limit_break") == 1 and unit.get("phase") == 3
                                    for unit in started["orgin_team_b"]))

    def test_settlement_grants_optional_equipment_once_and_only_on_victory(self):
        for roll, sign, expected in ((0, 1, 1), (9999, 1, 0), (0, 2, 0)):
            with self.subTest(roll=roll, sign=sign):
                db = sqlite3.connect(":memory:", check_same_thread=False)
                self.addCleanup(db.close)
                store = PlayerStore(db, self.config)
                uid = store.login(f"ancient-settlement-{roll}-{sign}")["uid"]
                combat = GameplayCombat(store, self.config)
                normal_rng = combat._reward_rng
                combat._reward_rng = lambda *args: (FixedRng(roll)
                    if args[-1] == "ancient-trial-equipment" else normal_rng(*args))
                profile = store.profile_raw(uid)
                team = [[iid, line, .2] for line, iid in enumerate(list(profile["avatars"])[:3])]
                before = set(profile["my_equips"])
                started = combat._start_main(uid, {"cid": "P_001_10", "diff": 0, "team": team})
                finish = {"cid": "P_001_10", "diff": 0, "fight_id": started["fight_id"],
                          "sign": sign, "combat_star": 3 if sign == 1 else 0,
                          "teams": {"team_a": started["orgin_team_a"],
                                    "team_b": started["orgin_team_b"]},
                          "actionID": "ancient-settlement"}
                won = combat._finish(uid, finish)
                self.assertEqual(len(won["get_equips"]), expected)
                after = store.profile_raw(uid)
                self.assertEqual(len(set(after["my_equips"]) - before), expected)
                for equipment in won["get_equips"].values():
                    eid = equipment["eid"].split("|")[0]
                    self.assertIn(eid, self.config["combat_ploy"]["P_001_10"]["ancient_equip_drop"]["pool"])
                self.assertTrue(combat._finish(uid, finish)["replayed"])
                self.assertEqual(store.profile_raw(uid)["my_equips"], after["my_equips"])

    def test_probability_boundaries_and_ordinary_equipment_only(self):
        cfg = self.config
        excluded = set(equipment_exclusive_ids(cfg))
        for tier, chance in enumerate(CHANCES_BP, 1):
            cid = f"P_001_{tier}"
            stage = cfg["combat_ploy"][cid]
            pool = stage["ancient_equip_drop"]["pool"]
            self.assertTrue(pool)
            self.assertFalse(set(pool) & excluded)
            self.assertTrue(all(cfg["cfg"]["equip"][eid]["quality"] == QUALITIES[tier - 1]
                                for eid in pool))
            self.assertEqual(roll_ancient_trial_drop(cfg, stage, cid, True, FixedRng(chance - 1)), pool[-1])
            self.assertIsNone(roll_ancient_trial_drop(cfg, stage, cid, True, FixedRng(chance)))
            self.assertIsNone(roll_ancient_trial_drop(cfg, stage, cid, False, FixedRng(0)))
        self.assertIsNone(roll_ancient_trial_drop(cfg, stage, "P_200_10", True, FixedRng(0)))
        bad = copy.deepcopy(cfg["combat_ploy"]["P_001_10"])
        bad["ancient_equip_drop"]["pool"].append(next(iter(excluded)))
        with self.assertRaises(GameplayFault):
            roll_ancient_trial_drop(cfg, bad, "P_001_10", True, FixedRng(0))


if __name__ == "__main__":
    unittest.main()
