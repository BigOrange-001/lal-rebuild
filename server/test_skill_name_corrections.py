"""Focused checks for mechanically justified skill-title corrections."""

import json
import unittest
from pathlib import Path

from skill_name_corrections import SKILL_NAME_CORRECTIONS, apply_skill_name_corrections


class SkillNameCorrectionsTest(unittest.TestCase):
    def test_only_verified_titles_change_and_overlay_is_repeatable(self):
        original = json.loads((Path(__file__).resolve().parents[1] /
                               "config/reconstruction/full-config.json").read_text(encoding="utf-8"))
        corrected = apply_skill_name_corrections(original)
        self.assertEqual(apply_skill_name_corrections(corrected), corrected)
        for skill_id, (old_name, new_name, _) in SKILL_NAME_CORRECTIONS.items():
            self.assertIn(original["cfg"]["skill"][skill_id]["name"], (old_name, new_name))
            self.assertEqual(corrected["cfg"]["skill"][skill_id]["name"], new_name)
            corrected["cfg"]["skill"][skill_id]["name"] = original["cfg"]["skill"][skill_id]["name"]
        self.assertEqual(corrected, original)

    def test_rejects_mechanic_drift(self):
        original = json.loads((Path(__file__).resolve().parents[1] /
                               "config/reconstruction/full-config.json").read_text(encoding="utf-8"))
        original["cfg"]["skill"]["S_621077_6"]["skill"].append(["shield", 1])
        with self.assertRaisesRegex(ValueError, "S_621077_6"):
            apply_skill_name_corrections(original)


if __name__ == "__main__":
    unittest.main()
