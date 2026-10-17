"""Focused regression checks for status visuals used by live combat."""

import copy
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from battle_status_effects import STATUS_EFFECTS, apply_battle_status_effects


CONFIG = Path(__file__).resolve().parents[1] / "config/reconstruction/full-config.json"
STAGES = Path(__file__).resolve().parents[1] / "client/src/stages"


class BattleStatusEffectTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.document = json.loads(CONFIG.read_text(encoding="utf-8"))

    def test_statuses_are_real_effects_not_numeric_sprites(self):
        document = copy.deepcopy(self.document)
        before = copy.deepcopy(document["cfg"]["effect"])
        self.assertIs(apply_battle_status_effects(document), document)
        effects = document["cfg"]["effect"]
        for key, expected in STATUS_EFFECTS.items():
            with self.subTest(effect=key):
                self.assertEqual(effects[key], expected)
                self.assertFalse(effects[key].get("img", False))
                self.assertFalse(effects[key]["id"].startswith("combatRate"))
        numeric_placeholders = {key: row["id"] for key, row in effects.items()
                                if isinstance(row, dict) and str(row.get("id", "")).startswith("combatRate")}
        self.assertEqual(numeric_placeholders, {})
        for key in set(before) - set(STATUS_EFFECTS):
            self.assertEqual(effects[key], before[key], key)

    def test_rerun_is_idempotent_and_loop_scoped_to_statuses(self):
        document = copy.deepcopy(self.document)
        apply_battle_status_effects(document)
        first = copy.deepcopy(document)
        apply_battle_status_effects(document)
        self.assertEqual(document, first)
        self.assertTrue(document["cfg"]["effect"]["burn"]["loop"])
        self.assertTrue(document["cfg"]["effect"]["critup"]["loop"])
        self.assertNotIn("loop", document["cfg"]["effect"]["BURN_EFF"])
        self.assertNotIn("loop", document["cfg"]["effect"]["POISON_EFF"])

    def test_semantic_families_use_distinct_existing_effects(self):
        ids = {key: value["id"] for key, value in STATUS_EFFECTS.items()}
        self.assertNotEqual(ids["SUCK_EFF"], ids["SUMMON_EFF"])
        self.assertNotEqual(ids["BACK_BUL"], ids["BLESS_EFF"])
        self.assertNotEqual(ids["pull"], ids["push"])
        self.assertNotEqual(ids["burn"], ids["avenge"])
        self.assertTrue(STATUS_EFFECTS["OPENING_ANIMATION"]["loop"])
        self.assertTrue(STATUS_EFFECTS["BACK_BUL"]["loop"])
        self.assertEqual({value["sc"] for value in STATUS_EFFECTS.values()}, {1})

    def test_live_buff_and_dot_paths_read_the_overlaid_keys(self):
        buff = (STAGES / "140_Buff.as").read_text(encoding="utf-8")
        avatar = (STAGES / "137_Avatar.as").read_text(encoding="utf-8")
        self.assertIn("DisplayTools.getAttrs(type)", buff)
        self.assertIn('DisplayTools.getAttrs("BURN_EFF")', avatar)
        self.assertIn('DisplayTools.getAttrs("POISON_EFF")', avatar)
        self.assertIn('manualDot.kind == "burn" ? "BURN_EFF" : "POISON_EFF"', avatar)
        self.assertIn("m_buff.addChild(param1.displayObject)", avatar)
        self.assertNotIn('DisplayTools.newTextField("" + (actionNum + 1)', avatar)
        self.assertIn('param1.addEventListener("touch",this.onTouch)', avatar)


if __name__ == "__main__":
    unittest.main()
