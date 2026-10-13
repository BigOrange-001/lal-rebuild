"""Focused boundary checks for the skill balance overlay."""

import copy
import json
import subprocess
import unittest
from pathlib import Path
import sys

sys.path.insert(0,str(Path(__file__).resolve().parent))
from skill_balance_overlay import apply_skill_balance


ROOT = Path(__file__).resolve().parents[1]


class SkillBalanceOverlayTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        baseline = subprocess.run(
            ["git", "show", "1c1b0db:config/reconstruction/full-config.json"],
            cwd=ROOT, check=True, capture_output=True,
        ).stdout
        cls.before = json.loads(baseline.decode("utf-8"))
        cls.after = copy.deepcopy(cls.before)
        cls.result = apply_skill_balance(cls.after)
        cls.old = cls.before["cfg"]["skill"]
        cls.new = cls.after["cfg"]["skill"]

    def test_damage_growth_and_multi_layer_dot(self):
        self.assertAlmostEqual(self.new["S_631096_5"]["skill"][2][2], 0.64)
        self.assertEqual(self.new["S_631096_5"]["skill"][2][1], 3)
        self.assertAlmostEqual(self.new["S_621019_5"]["skill"][3][2],
                               self.old["S_621019_5"]["skill"][3][2] * 1.2)
        self.assertEqual(self.new["S_621019_5"]["skill"][3][4:],
                         self.old["S_621019_5"]["skill"][3][4:])
        chain = self.new["S_631068_5"]
        self.assertAlmostEqual(chain["chainDot"][1], 0.16)
        self.assertEqual(chain["chainDot"][2:], self.old["S_631068_5"]["chainDot"][2:])
        self.assertAlmostEqual(self.new["S_621030_5"]["skillUpPaths"][0][2],
                               self.old["S_621030_5"]["skillUpPaths"][0][2] * 0.8)

    def test_recovery_defense_and_native_metadata(self):
        self.assertAlmostEqual(self.new["S_621022_5"]["skill"][2][1], 0.3)
        self.assertAlmostEqual(self.new["S_9001_5"]["skill"][0][3], 1.0)
        self.assertAlmostEqual(self.new["S_301008_5"]["skill"][1][1], 0.2)
        self.assertAlmostEqual(self.new["S_621032_5"]["skill"][3][2], 0.1)
        self.assertEqual(self.new["S_201007_5"]["skill"][0][1],
                         self.old["S_201007_5"]["skill"][0][1])
        self.assertEqual(self.new["S_631053_5"]["skill"][4][1], 0.5)
        manual = self.new["S_651143_5"]
        self.assertEqual(manual["skill"][0][2], 1.0)
        self.assertEqual(manual["manualDamageMultiplier"], 1.2)
        self.assertEqual(manual["manualDefenseBuffMultiplier"], 2.0)
        self.assertIn("104%", self.new["S_651005_5"]["info"])
        self.assertIn("80%", self.new["S_651005_5"]["info"])
        self.assertIn("{scale:80.0:64.0}", self.new["S_641025_5"]["rankInfoTemplate"])

    def test_target_policy_bless_and_only_once(self):
        row = self.new["S_631096_5"]
        self.assertEqual(row["skill"][0][1], row["actionTargetPolicies"][0])
        self.assertIn("其他路", row["info"])
        self.assertEqual(self.after["cfg"]["system_simple"]["attack"][20], 0.5)
        self.assertIn("50%", self.new["S_631113_5"]["info"])
        self.assertEqual(self.result, apply_skill_balance(self.after))
        self.assertEqual(self.result["private_clones"], 0)

    def test_shared_skill_gets_private_profile_row(self):
        document = copy.deepcopy(self.before)
        document["cfg"]["avatar"]["A_1001_5"]["pl"][10] = "S_203002_5"
        marker = apply_skill_balance(document)
        self.assertEqual(marker["private_clones"], 1)
        warrior_id = document["cfg"]["avatar"]["A_1001_5"]["pl"][10]
        mage_id = document["cfg"]["avatar"]["A_1002_5"]["pl"][10]
        self.assertNotEqual(warrior_id, mage_id)
        self.assertAlmostEqual(document["cfg"]["skill"][warrior_id]["skill"][0][1],
                               self.old[mage_id]["skill"][0][1] * 1.2)
        self.assertAlmostEqual(document["cfg"]["skill"][mage_id]["skill"][0][1],
                               self.old[mage_id]["skill"][0][1] * 0.8)


if __name__ == "__main__":
    unittest.main()
