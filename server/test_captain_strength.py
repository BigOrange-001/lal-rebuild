"""Focused checks for the captain-only 50% effect overlay."""

import copy
import json
import subprocess
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from captain_strength import apply_captain_strength
from skill_balance_overlay import apply_skill_balance
from skill_tempo import apply_skill_tempo


ROOT = Path(__file__).resolve().parents[1]


class CaptainStrengthTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        baseline = subprocess.run(
            ["git", "show", "1c1b0db:config/reconstruction/full-config.json"],
            cwd=ROOT, check=True, capture_output=True,
        ).stdout
        cls.source = json.loads(baseline.decode("utf-8"))
        apply_skill_balance(cls.source)
        apply_skill_tempo(cls.source)
        cls.document = copy.deepcopy(cls.source)
        cls.marker = apply_captain_strength(cls.document)
        cls.old = cls.source["cfg"]["skill"]
        cls.new = cls.document["cfg"]["skill"]

    def test_all_captain_rows_and_ordinary_unchanged(self):
        cfg = self.source["cfg"]
        captain = {a["pl"][11] for a in cfg["avatar"].values()
                   if len(a.get("pl", [])) > 11 and a["pl"][11] in cfg["skill"]}
        ordinary = {a["pl"][10] for a in cfg["avatar"].values()
                    if len(a.get("pl", [])) > 10 and a["pl"][10] in cfg["skill"]}
        self.assertEqual(self.marker["captain_skill_rows"], len(captain))
        self.assertEqual(set(self.marker["action_kinds"]),
                         {x[0] for sid in captain for x in self.old[sid]["skill"]} | {"chainDot"})
        for sid in ordinary - captain:
            self.assertEqual(self.new[sid], self.old[sid])
        self.assertEqual(self.source["cfg"]["avatar"], cfg["avatar"])

    def test_magnitudes_scale_without_counts_duration_or_range(self):
        self.assertEqual(self.new["S_301001_2"]["skill"][0][1], 9.0)
        self.assertEqual(self.new["S_301001_2"]["skill"][0][2:],
                         self.old["S_301001_2"]["skill"][0][2:])
        old_poison = next(a for a in self.old["S_301209_4"]["skill"] if a[0] == "poison")
        new_poison = next(a for a in self.new["S_301209_4"]["skill"] if a[0] == "poison")
        self.assertAlmostEqual(new_poison[1], old_poison[1] * 1.5)
        self.assertAlmostEqual(new_poison[3], old_poison[3] * 1.5)
        self.assertEqual(new_poison[2], old_poison[2])
        self.assertEqual(new_poison[4:], old_poison[4:])
        old_multi = self.old["S_301008_2"]["skill"][0]
        new_multi = self.new["S_301008_2"]["skill"][0]
        self.assertEqual(new_multi[1], old_multi[1])
        self.assertEqual(new_multi[2:5], [round(v * 1.5, 10) for v in old_multi[2:5]])
        self.assertEqual(new_multi[6], old_multi[6])  # derived lifesteal ratio
        self.assertEqual(new_multi[5], old_multi[5])  # target count
        self.assertAlmostEqual(self.new["S_631068_5"]["chainDot"][1],
                               self.old["S_631068_5"]["chainDot"][1] * 1.5)

    def test_manual_and_summon_channels_preserve_authored_level(self):
        sid = "S_651005_2"
        self.assertEqual(self.new[sid]["skill"][0][2], self.old[sid]["skill"][0][2])
        self.assertEqual(self.new[sid]["manualDamageMultiplier"],
                         round(self.old[sid].get("manualDamageMultiplier", 1) * 1.5, 10))
        self.assertEqual(self.new[sid]["manualEffectMultiplier"], 1.5)
        sid = "S_301221_5"
        self.assertEqual(self.new[sid]["skill"][0], self.old[sid]["skill"][0])
        self.assertEqual(self.new[sid]["captainSummonMultiplier"], 1.5)
        sid = "S_303014_3"
        self.assertEqual(self.new[sid]["skill"][0][1], 1.5)
        self.assertEqual(self.new[sid]["skill"][0][2:], self.old[sid]["skill"][0][2:])

    def test_manual_descriptions_show_scaled_effects_without_mechanics(self):
        nunu = self.new["S_651073_6"]["info"]
        self.assertIn("180%攻击力＋18%自身生命上限的护盾", nunu)
        self.assertIn("432%魔法伤害", nunu)
        self.assertIn("45%衰弱2回合", nunu)
        self.assertIn("400范围内最多3名", nunu)
        self.assertIn("30%衰弱", self.new["S_651011_5"]["info"])
        self.assertIn("原本96%的范围爆炸", self.new["S_651098_6"]["info"])
        self.assertIn("1200点暴击", self.new["S_651115_6"]["info"])
        self.assertIn("240%攻击力＋24%自身生命上限的护盾",
                      self.new["S_651138_6"]["info"])
        clone = self.new["S_631132_5"]
        self.assertEqual(clone["manualClonePolicy"]["panelStatRatio"], 1.2)
        self.assertIn("120%面板", clone["info"])
        self.assertEqual(clone["manualClonePolicy"]["ttlOwnTurns"],
                         self.old["S_631132_5"]["manualClonePolicy"]["ttlOwnTurns"])

    def test_shared_skill_clones_and_rewires_only_captain(self):
        document = {"cfg": {"avatar": {
            "A_normal": {"pl": [None] * 10 + ["S_shared", "S_other"]},
            "A_captain": {"pl": [None] * 10 + ["S_other", "S_shared"]},
        }, "skill": {
            "S_shared": {"id": "S_shared", "skill": [["damage", 2, 1, "FX"]],
                         "skillUp": [0, 0.2], "info": "造成200%伤害"},
            "S_other": {"id": "S_other", "skill": [["damage", 1, 1, "FX"]]},
        }}}
        original = copy.deepcopy(document)
        marker = apply_captain_strength(document)
        self.assertEqual(marker["private_clones"], 2)
        normal_id = document["cfg"]["avatar"]["A_normal"]["pl"][10]
        captain_id = document["cfg"]["avatar"]["A_captain"]["pl"][11]
        self.assertEqual(normal_id, "S_shared")
        self.assertNotEqual(captain_id, normal_id)
        self.assertEqual(document["cfg"]["skill"][normal_id], original["cfg"]["skill"][normal_id])
        self.assertEqual(document["cfg"]["skill"][captain_id]["skill"][0][1], 3)
        self.assertEqual(document["cfg"]["skill"][captain_id]["skillUp"][1], 0.3)
        self.assertEqual(document["cfg"]["skill"][captain_id]["info"], "造成300%伤害")
        self.assertEqual(marker, apply_captain_strength(document))

    def test_unreviewed_action_is_atomic(self):
        document = {"cfg": {"avatar": {"A_one": {"pl": [None] * 11 + ["S_one"]}},
                            "skill": {"S_one": {"id": "S_one", "skill": [["damage", 2, 1, "FX"],
                                                                   ["unknown_new_opcode", 1]]}}}}
        before = copy.deepcopy(document)
        with self.assertRaisesRegex(ValueError, "unreviewed captain action"):
            apply_captain_strength(document)
        self.assertEqual(document, before)


if __name__ == "__main__":
    unittest.main()
