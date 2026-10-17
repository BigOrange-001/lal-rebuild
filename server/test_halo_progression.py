"""Halo experience curve and native table-consumption checks."""

import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from halo_progression import HALO_CURVE, apply_halo_progression, halo_rank_threshold


ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "config/reconstruction/full-config.json"


class HaloProgressionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.original = json.loads(CONFIG.read_text(encoding="utf-8"))
        cls.config = apply_halo_progression(cls.original)
        cls.simple = cls.config["cfg"]["system_simple"]

    def test_config_is_idempotent_and_both_wash_types_gain_twenty(self):
        self.assertEqual(apply_halo_progression(self.config), self.config)
        self.assertEqual(self.simple["equipwash"][2:4], [20, 20])
        self.assertEqual(self.simple["wash_halo_curve"], HALO_CURVE)
        self.assertIsNot(self.original, self.config)
        self.assertIsNot(self.original["cfg"]["system_simple"]["equipwash"], self.simple["equipwash"])

    def test_five_ranks_total_625_washes_at_item_level_125(self):
        thresholds = [halo_rank_threshold(self.simple, 125, rank) for rank in range(5)]
        self.assertEqual(thresholds, [1000, 1500, 2250, 3250, 4500])
        self.assertEqual(sum(thresholds), 625 * 20)
        self.assertEqual([(-(-sum(thresholds[:rank]) // 20)) for rank in range(1, 6)],
                         [50, 125, 238, 400, 625])
        self.assertEqual(sorted(thresholds), thresholds)

    def test_lower_level_curve_remains_positive_and_full_budget_exact(self):
        for item_level in (1, 10, 99, 125):
            with self.subTest(level=item_level):
                thresholds = [halo_rank_threshold(self.simple, item_level, rank) for rank in range(5)]
                wash_points = max(5, item_level // 10)
                baseline = (int(self.simple["equip_config"][3]) * item_level + wash_points - 1) // wash_points
                self.assertTrue(all(value > 0 for value in thresholds))
                self.assertEqual(sum(thresholds), baseline * 5 * 20)

    def test_native_equipment_and_wash_panel_read_same_table(self):
        equip = (ROOT / "client/src/stages/084_Equip.as").read_text(encoding="utf-8")
        panel = (ROOT / "client/src/stages/068_PanelEquipWash.as").read_text(encoding="utf-8")
        self.assertIn("GlobalData.$mConfig_simple.wash_halo_curve", equip)
        self.assertIn("curve.rank_weights as Array", equip)
        self.assertIn("_loc3_[2] * param1", equip)
        self.assertIn("_loc3_[3] * param1", equip)
        self.assertIn("_loc4_.getHaloExpMax()", panel)


if __name__ == "__main__":
    unittest.main()
