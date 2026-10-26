"""Focused checks for served PVE formations and NPC skill policy."""
import json
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from campaign_workbook_overlay import _power
from battle_engine import _native_skill_snapshot
from gameplay_combat import GameplayCombat
from player_store import PlayerStore
from pve_feedback_overlay import apply_pve_feedback, tower_skill_level
from solo_progression import exploration_encounter
from battle_engine import serialize_stage_team


class PveFeedbackOverlayTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = json.loads((Path(__file__).resolve().parents[1] /
                                 "config/reconstruction/full-config.json").read_text(encoding="utf-8"))
        cls.config, cls.report = apply_pve_feedback(cls.source)

    def test_served_tables_keep_rosters_and_power(self):
        self.assertEqual((self.report["campaign"]["stages"], self.report["tower"]["floors"]),
                         (336, 150))
        expected_campaign = (2 * len(self.source["pve"]["combat_main"])
                             + sum(not cid.startswith("P_200_")
                                   for cid in self.source["pve"]["combat_ploy"])
                             + len(self.source["pve"].get("modes", {}).get(
                                 "exploration", {}).get("stages", [])))
        self.assertEqual(self.report["campaign"]["stages"], expected_campaign)
        self.assertEqual(self.report["tower"]["floors"],
                         int(self.source["pve"]["battle_ploy"]["P_200"]["combat"]))
        self.assertLess(self.report["campaign"]["max_power_error_pct"], .25)
        self.assertLess(self.report["tower"]["max_power_error_pct"], .01)
        for name in ("battle_main", "combat_main", "battle_ploy", "combat_ploy"):
            self.assertEqual(self.config["pve"][name], self.config[name])
            self.assertEqual(self.config["pve"][name], self.config["cfg"][name])
        for cid in ("M_001_1", "M_020_1", "M_030_3"):
            before = self.source["pve"]["combat_main"][cid]
            after = self.config["pve"]["combat_main"][cid]
            for diff, old, new, slv in (("0", before["team2"], after["team2"], 4),
                                        ("1", before["team2_by_diff"]["1"],
                                         after["team2_by_diff"]["1"], 8)):
                self.assertEqual([[r[i] for i in (0, 1, 3, 4, 5, 6, 12)] for r in old],
                                 [[r[i] for i in (0, 1, 3, 4, 5, 6, 12)] for r in new])
                self.assertTrue(all(row[2] == slv for row in new))
                old_power = _power(self.source["cfg"], old, before["enemy_unit_stats_by_diff"][diff])
                new_power = _power(self.config["cfg"], new, after["enemy_unit_stats_by_diff"][diff])
                self.assertLessEqual(abs(new_power - old_power) / old_power, .0025)
                self.assertEqual(after["recommended_power_by_diff"][diff], new_power)
                for lane in {row[3] for row in new}:
                    sides = [row[11] for row in new if row[3] == lane]
                    if len(sides) > 1:
                        self.assertLess(min(sides), 0)
                        self.assertGreater(max(sides), 0)
                        self.assertEqual(len(sides), len(set(sides)))
                        self.assertLessEqual(max(map(abs, sides)), .5)
        self.assertEqual(self.config["pve"]["campaign_overlay"],
                         self.source["pve"]["campaign_overlay"])
        for cid in ("P_001_1", "P_101_1", "P_101_5", "P_109_4",
                    "P_200_1", "P_200_81", "P_200_150"):
            stage = self.config["cfg"]["combat_ploy"][cid]
            for lane in {row[3] for row in stage["team2"]}:
                sides = [row[11] for row in stage["team2"] if row[3] == lane]
                if len(sides) > 1:
                    self.assertLess(min(sides), 0, (cid, lane))
                    self.assertGreater(max(sides), 0, (cid, lane))
        exploration = self.config["pve"]["modes"]["exploration"]["stages"][0]
        self.assertEqual({row[3] for row in exploration["team2"]}, {0})
        self.assertLess(min(row[11] for row in exploration["team2"]), 0)
        self.assertGreater(max(row[11] for row in exploration["team2"]), 0)

    def test_tower_skill_boundaries_and_real_start_snapshots(self):
        for floor, expected in ((1, 2), (10, 2), (11, 4), (20, 4),
                                (21, 6), (30, 6), (31, 8), (40, 8),
                                (41, 10), (100, 10), (101, 10), (150, 10)):
            self.assertEqual(tower_skill_level(floor), expected)
            stage = self.config["cfg"]["combat_ploy"][f"P_200_{floor}"]
            self.assertTrue(all(row[2] == expected for row in stage["team2"]))
            self.assertEqual(stage["recommended_power"], _power(
                self.config["cfg"], stage["team2"], stage["enemy_unit_stats_by_diff"]["0"]))
        self.assertEqual(tower_skill_level(180),10)
        for invalid in (0, 181):
            with self.assertRaises(ValueError):
                tower_skill_level(invalid)
        db = sqlite3.connect(":memory:", check_same_thread=False)
        self.addCleanup(db.close)
        store = PlayerStore(db, self.config)
        uid = store.login("feedback-snapshot")["uid"]
        combat = GameplayCombat(store, self.config)
        team = [[aid, lane, .2] for lane, aid in enumerate(list(store.profile_raw(uid)["avatars"])[:3])]
        for cid, diff, slv in (("M_001_1", 0, 4), ("M_001_1", 1, 8),
                               ("P_200_1", 0, 2)):
            data = combat._start_main(uid, {"cid": cid, "diff": diff, "team": team})
            row = data["team2"][0]
            snapshot = data["orgin_team_b"][0]
            self.assertEqual((row[2], snapshot["slv"]), (slv, slv))
            skill_id = self.config["cfg"]["avatar"][row[0]]["pl"][10]
            self.assertEqual(snapshot["skill"], _native_skill_snapshot(
                self.config["cfg"], skill_id, slv))
            if cid.startswith("M_"):
                self.assertEqual(snapshot["side_offset"], row[11])
                pending = store.profile_raw(uid)["pending_pve"][data["fight_id"]]
                self.assertEqual(pending["stage"]["team2"], data["team2"])

    def test_refreshed_exploration_keeps_normal_skill_and_lane_stagger(self):
        template = self.config["pve"]["modes"]["exploration"]["stages"][0]
        encounter = exploration_encounter(self.config, {"uid": "exploration-feedback"},
                                          {"map_revision": 1,
                                           "difficulty": {"level": 60, "star": 4}},
                                          1, template)
        team = encounter["team2"]
        self.assertEqual((encounter["reward"]["gold"], encounter["reward"]["exp"]),
                         (16000, 72))
        self.assertEqual({row[2] for row in team}, {4})
        self.assertEqual({row[3] for row in team}, {0})
        self.assertLess(min(row[11] for row in team), 0)
        self.assertGreater(max(row[11] for row in team), 0)
        snapshots = serialize_stage_team(self.config["cfg"], team)
        self.assertEqual([unit["side_offset"] for unit in snapshots],
                         [row[11] for row in team])


if __name__ == "__main__":
    unittest.main()
