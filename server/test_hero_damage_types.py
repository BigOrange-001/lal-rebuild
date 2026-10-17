"""Focused validation of basic and explicitly authored skill damage channels."""
import copy
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from hero_damage_types import (CUSTOM_FAMILIES, EXPLICIT_MAGIC_SKILL_FIXES,
                               apply_hero_damage_types, described_skill_type_mismatches,
                               expected_basic_damage_type)
from upstream_hero_config import apply_upstream_hero_config


class HeroDamageTypesTest(unittest.TestCase):
    def setUp(self):
        root = Path(__file__).resolve().parents[1]
        self.config = json.loads((root / "config/reconstruction/full-config.json").read_text(encoding="utf8"))
        apply_upstream_hero_config(self.config)
        # The published config already includes this overlay. Restore the
        # seven explicitly authored mismatches so this test exercises the fix.
        cfg = self.config["cfg"]
        cfg.pop("hero_damage_type_overlay", None)
        for sid, opcode in EXPLICIT_MAGIC_SKILL_FIXES.items():
            actions = [action for action in cfg["skill"][sid]["skill"]
                       if action[0] == opcode and float(action[1]) > 0]
            self.assertEqual(len(actions), 1, sid)
            self.assertEqual(actions[0][2], 2, sid)
            actions[0][2] = 1

    def test_all_authored_league_families_and_skins_share_primary_channel(self):
        before = copy.deepcopy(self.config)
        apply_hero_damage_types(self.config)
        rows = self.config["cfg"]["avatar"]
        touched = 0
        for aid, row in rows.items():
            parts = aid.split("_")
            if len(parts) != 3 or len(parts[1]) != 4 or not parts[1].startswith("1"):
                continue
            if "阶英雄" in row["name"] or "序号" in row["name"]:
                continue
            expected = expected_basic_damage_type(parts[1])
            if expected is None:
                self.assertIn(parts[1], CUSTOM_FAMILIES)
                self.assertEqual(row["tl"], before["cfg"]["avatar"][aid]["tl"])
            else:
                touched += 1
                self.assertEqual(row["tl"][2], expected, aid)
                self.assertEqual(row["tl"][:2] + row["tl"][3:],
                                 before["cfg"]["avatar"][aid]["tl"][:2]
                                 + before["cfg"]["avatar"][aid]["tl"][3:])
        self.assertGreater(touched, 250)
        for skin, base in (("A_1201_6", "A_1001_5"),
                           ("A_1223_6", "A_1206_6"),
                           ("A_1226_6", "A_1009_5"),
                           ("A_1310_6", "A_1082_6")):
            self.assertEqual(rows[skin]["tl"][2], rows[base]["tl"][2])
        self.assertEqual(rows["A_1206_6"]["tl"][2], 1)  # Silver Bolts is separate.
        self.assertEqual(rows["A_1029_6"]["tl"][2], 2)

    def test_only_seven_explicit_skill_channels_change_and_true_damage_survives(self):
        before = copy.deepcopy(self.config["cfg"]["skill"])
        apply_hero_damage_types(self.config)
        after = self.config["cfg"]["skill"]
        self.assertEqual({sid for sid in after if after[sid] != before[sid]},
                         set(EXPLICIT_MAGIC_SKILL_FIXES))
        for sid, opcode in EXPLICIT_MAGIC_SKILL_FIXES.items():
            self.assertIn("魔法伤害", after[sid]["info"])
            action = next(action for action in after[sid]["skill"] if action[0] == opcode)
            self.assertEqual(action[2], 2)
        self.assertEqual(after["S_301001_5"]["skill"][1][0], "true_damage")
        self.assertEqual(after["S_621029_6"]["skill"][0][0], "manual_dot")
        self.assertEqual(after["S_621029_6"]["skill"][0][5], 0)
        self.assertEqual(described_skill_type_mismatches(self.config), [])
        first = copy.deepcopy(self.config)
        apply_hero_damage_types(self.config)
        self.assertEqual(self.config, first)

    def test_unclassified_new_league_hero_fails_before_silent_misclassification(self):
        with self.assertRaisesRegex(ValueError, "Unclassified authored hero"):
            expected_basic_damage_type("A_1995")


if __name__ == "__main__":
    unittest.main()
