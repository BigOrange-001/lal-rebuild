"""Combat tempo boundary and authored-skill checks."""

import copy
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from captain_timing import REPEAT_4
from skill_tempo import apply_skill_tempo
from upstream_skill_priority import SKILL_IDS, apply_upstream_skill_priority


class SkillTempoTests(unittest.TestCase):
    def document(self):
        return {"cfg": {"skill": {
            str(cd): {"id": str(cd), "pl": [cd, cd, 600, 0, 2, 1],
                      "skill": [["damage", .5, 1, "fx"], ["shield", .2, 2, "fx"]],
                      "skillUp": [[0, 1, .05], [1, 1, .02]],
                      "info": f"造成50%伤害，护盾20%，准备{cd}，冷却{cd}。"}
            for cd in range(9)}}}

    def test_original_timing_matrix_and_idempotency(self):
        doc = self.document()
        apply_skill_tempo(doc)
        for cd, expected in enumerate([0, 0, 1, 2, 3, 3, 3, 3, 3]):
            row = doc["cfg"]["skill"][str(cd)]
            self.assertEqual(row["pl"][:2], [cd - 1 if cd >= 2 else cd, expected])
            self.assertEqual(row["pl"][2:], [600, 0, 2, 1])
            self.assertEqual(row["skill"][1][2], 2)
        saved = copy.deepcopy(doc)
        apply_skill_tempo(doc)
        self.assertEqual(saved, doc)

    def test_damage_only_and_all_magnitudes(self):
        doc = self.document()
        apply_skill_tempo(doc)
        zero, three = [doc["cfg"]["skill"][str(cd)] for cd in (0, 3)]
        self.assertEqual(zero["skill"][0][1], 1)
        self.assertEqual(zero["skill"][1][1], .2)
        self.assertEqual(zero["skillUp"][0][2], .1)
        self.assertEqual(zero["skillUp"][1][2], .02)
        self.assertEqual(three["skill"][0][1], .6)
        self.assertEqual(three["skill"][1][1], .24)
        self.assertIn("护盾24%", three["info"])

    def test_dot_multi_hit_and_upgrade_paths(self):
        row = {"id": "dot", "pl": [2, 0, 600, 0, 0, 1],
               "skill": [["manual_dot", "burn", .08, 0, 5], ["battle_stack_unconditional", "flee", 100, 99]],
               "skillUpPaths": [[0, [2], .01]]}
        doc = {"cfg": {"skill": {"dot": row}}}
        apply_skill_tempo(doc)
        self.assertEqual(row["skill"][0][2:], [.16, 0, 5])
        self.assertEqual(row["skill"][1][2:], [100, 99])
        self.assertEqual(row["skillUpPaths"][0][2], .02)

    def test_manual_scale_and_summon_rank_ten(self):
        row = {"id": "manual", "pl": [2, 3, 600, 0, 0, 1],
               "skill": [["manual_ability", "yi_n", 1, "fx"]], "manualDamageMultiplier": 1.2,
               "skillUp": [[0, 2, 1/9]], "info": "132%伤害600点闪避，准备2，冷却3。",
               "rankInfoTemplate": "{scale:0:132}伤害600点闪避"}
        doc = {"cfg": {"skill": {"manual": row}}}
        apply_skill_tempo(doc)
        self.assertEqual(row["manualDamageMultiplier"], 1.2)
        self.assertEqual(row["skill"][0][2], 1.2)
        self.assertIn("{scale:0:132}", row["rankInfoTemplate"])
        self.assertIn("720点闪避", row["info"])
        self.assertAlmostEqual(row["skill"][0][2] + 9 * row["skillUp"][0][2], 2.4)

    def test_published_configuration(self):
        path = Path(__file__).resolve().parents[1] / "config/reconstruction/full-config.json"
        doc = json.loads(path.read_text(encoding="utf-8-sig"))
        apply_skill_tempo(doc)
        apply_upstream_skill_priority(doc)
        rows = doc["cfg"]["skill"]
        captain_refs = {avatar["pl"][11] for avatar in doc["cfg"]["avatar"].values()
                        if len(avatar.get("pl", [])) > 11 and avatar["pl"][11] in rows}
        captain_four = {sid for sid in captain_refs if sid.rsplit("_", 1)[0] in REPEAT_4}
        priority_rows = json.loads((Path(__file__).resolve().parent / "upstream_hero_config_delta.json")
                                   .read_text(encoding="utf-8"))["skill"]
        upstream_long = {sid for sid in SKILL_IDS if priority_rows[sid]["pl"][1] > 3}
        self.assertEqual({sid for sid, row in rows.items() if row["pl"][1] > 3},
                         captain_four | upstream_long)
        self.assertTrue(all(rows[sid]["pl"][1] == 4 for sid in captain_four))
        self.assertTrue(all(rows[sid]["pl"][:2] == priority_rows[sid]["pl"][:2]
                            for sid in upstream_long))
        self.assertTrue(all(0 <= row["pl"][1] <= 3 for sid, row in rows.items()
                            if sid not in captain_four | upstream_long))
        self.assertEqual(rows["S_621029_5"]["skill"][0][2], .16)
        self.assertEqual(rows["S_621029_5"]["skill"][1][2], 100)
        turret = rows["S_203014_3"]
        self.assertAlmostEqual(turret["skill"][0][1] + 9 * turret["skillUp"][0][2], 1.2)
        self.assertIn("192%", rows["S_621030_5"]["info"])


if __name__ == "__main__":
    unittest.main()
