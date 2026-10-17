"""Focused checks for the captain-only timeline overlay."""

import copy
import json
import sys
import unittest
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from captain_timing import KNOWN, apply_captain_timing


CONFIG = Path(__file__).resolve().parents[1] / "config/reconstruction/full-config.json"


class CaptainTimingTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.original = json.loads(CONFIG.read_text(encoding="utf-8"))
        # The generated full config may already contain the overlay marker.
        # Re-run the pure transform against its rows to test either state.
        cls.original["cfg"].pop("captain_timing", None)
        cls.updated = copy.deepcopy(cls.original)
        cls.marker = apply_captain_timing(cls.updated)
        cls.old_cfg = cls.original["cfg"]
        cls.cfg = cls.updated["cfg"]
        cls.captains = {a["pl"][11] for a in cls.old_cfg["avatar"].values()
                        if len(a.get("pl", [])) > 11 and a["pl"][11] in cls.old_cfg["skill"]}

    def test_all_authored_families_and_deliberate_distribution(self):
        self.assertEqual(self.marker["skill_rows"], len(self.captains))
        self.assertEqual(self.marker["unreviewed_families"], [])
        self.assertEqual({sid.rsplit("_", 1)[0] for sid in self.captains}, KNOWN)
        pairs = Counter(tuple(self.cfg["skill"][sid]["pl"][:2]) for sid in self.captains)
        self.assertLess(pairs[(3, 3)], 90)
        self.assertGreater(sum(n for (prep, _), n in pairs.items() if prep <= 2), 190)
        self.assertLessEqual(sum(n for (_, cd), n in pairs.items() if cd == 4), 6)
        self.assertGreater(sum(n for (_, cd), n in pairs.items() if cd == 2), 55)
        self.assertEqual(pairs[(4, 0)], 2)  # Kassadin's capped 4-stack exception.

    def test_specific_hero_cadences_and_duration_guard(self):
        expected = {
            "S_301201_6": (1, 2),  # Garen: one decisive strike.
            "S_301202_6": (2, 3),  # Ashe: single-target stun.
            "S_301001_5": (3, 4),  # Garen: 900% true-damage execution.
            "S_611001_2": (3, 4),  # Same 900% execution in another family.
            "S_301008_5": (2, 2),  # One-turn armor and three-hit skirmish.
            "S_301206_6": (1, 2),  # Vayne: two-turn self stats.
            "S_301209_6": (2, 3),  # Teemo: capped/refreshable mushroom.
            "S_301221_6": (2, 2),  # Tibbers: two actions, one live summon.
            "S_631022_6": (2, 3),  # Ahri: charm and movement sequence.
            "S_631045_6": (2, 3),  # Lulu: two-turn team shield, one-turn stun.
            "S_631125_6": (3, 3),  # Ziggs: large area, lower per-target ratio.
            "S_631134_6": (4, 0),  # Kassadin: four separate timed stacks.
            "S_651103_6": (3, 3),  # Malzahar: two-turn stun and two pets.
            "S_9003_1": (1, 2),    # Shared simple strike at low rarity.
        }
        for sid, timing in expected.items():
            with self.subTest(skill=sid):
                self.assertEqual(tuple(self.cfg["skill"][sid]["pl"][:2]), timing)
        for sid in self.captains:
            row = self.cfg["skill"][sid]
            if row["pl"][1] == 2:
                kinds = {action[0] for action in row.get("skill", [])}
                self.assertFalse(kinds & {"stun", "bless", "clone_normal", "timed_stack"})
                if "summon" in kinds:
                    self.assertEqual(sid.rsplit("_", 1)[0], "S_301221")

    def test_other_skills_and_effects_unchanged(self):
        old = self.old_cfg["skill"]
        new = self.cfg["skill"]
        self.assertEqual(set(old), set(new))
        for sid, before in old.items():
            after = new[sid]
            if sid not in self.captains:
                self.assertEqual(after, before)
            else:
                self.assertEqual(after["pl"][2:], before["pl"][2:])
                for key in before.keys() - {"pl", "info", "rankInfoTemplate"}:
                    self.assertEqual(after[key], before[key], (sid, key))
                for key in ("info", "rankInfoTemplate"):
                    if isinstance(after.get(key), str):
                        self.assertRegex(after[key], rf"准备(?:时间|回合)?\s*[:：]?\s*{after['pl'][0]}(?!\d)")
                        self.assertRegex(after[key], rf"冷却(?:时间|回合)?\s*[:：]?\s*{after['pl'][1]}(?!\d)")
        self.assertEqual(self.cfg["avatar"], self.old_cfg["avatar"])

    def test_shared_normal_slot_gets_private_clone_and_reapply_is_safe(self):
        document = copy.deepcopy(self.original)
        cfg = document["cfg"]
        ordinary = next(a for a in cfg["avatar"].values()
                        if len(a.get("pl", [])) > 11 and a["pl"][11] == "S_301201_6")
        ordinary["pl"][10] = "S_301201_6"
        before = copy.deepcopy(cfg["skill"]["S_301201_6"])
        marker = apply_captain_timing(document)
        clone = ordinary["pl"][11]
        self.assertNotEqual(clone, "S_301201_6")
        self.assertEqual(ordinary["pl"][10], "S_301201_6")
        self.assertEqual(cfg["skill"]["S_301201_6"], before)
        self.assertEqual(cfg["skill"][clone]["pl"][:2], [1, 2])
        self.assertEqual(marker["private_clones"], 1)
        snapshot = copy.deepcopy(document)
        self.assertIs(apply_captain_timing(document), marker)
        self.assertEqual(document, snapshot)

    def test_new_family_semantic_fallback_does_not_short_cycle_summon(self):
        document = copy.deepcopy(self.original)
        cfg = document["cfg"]
        avatar = next(a for a in cfg["avatar"].values()
                      if len(a.get("pl", [])) > 11 and a["pl"][11] == "S_301209_6")
        clone = copy.deepcopy(cfg["skill"]["S_301209_6"])
        clone["id"] = "S_987654_6"
        cfg["skill"][clone["id"]] = clone
        avatar["pl"][11] = clone["id"]
        marker = apply_captain_timing(document)
        self.assertIn(clone["id"], marker["unreviewed_families"])
        self.assertEqual(cfg["skill"][clone["id"]]["pl"][:2], [3, 3])


if __name__ == "__main__":
    unittest.main()
