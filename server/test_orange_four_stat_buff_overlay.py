"""Focused checks for orange-only four-stat skill buffs."""

import copy
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from orange_four_stat_buff_overlay import (MULTIPLIER, SCHEMA,
                                           apply_orange_four_stat_buffs, _position)
from upstream_skill_priority import SKILL_IDS, apply_upstream_skill_priority


CONFIG = Path(__file__).resolve().parents[1] / "config/reconstruction/full-config.json"


class OrangeFourStatBuffOverlayTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with CONFIG.open(encoding="utf-8-sig") as stream:
            cls.before = json.load(stream)
        # Final publication gives these PR skills their authored rows again.
        # Keep that priority in the fixture, while reconstructing the
        # pre-orange state for every other reachable orange skill.
        apply_upstream_skill_priority(cls.before)
        # full-config is already published with this overlay. Reconstruct its
        # immediately preceding action magnitudes and rank deltas so the test
        # still proves one application changes every eligible orange action.
        cfg = cls.before["cfg"]
        marker = cfg.pop("orange_four_stat_buff_overlay", None)
        if (marker is None or marker.get("schema") != SCHEMA
                or marker.get("multiplier") != MULTIPLIER
                or marker.get("cloned_shared_skills") != 0):
            raise AssertionError(f"unexpected published orange overlay: {marker!r}")
        orange_skills = {
            avatar["pl"][slot]
            for aid, avatar in cfg["avatar"].items() if aid.startswith("A_") and aid.endswith("_6")
            for slot in (10, 11, 13)
            if len(avatar.get("pl", [])) > slot and isinstance(avatar["pl"][slot], str)
        }
        for sid in orange_skills & cfg["skill"].keys():
            if sid in SKILL_IDS:
                continue
            row = cfg["skill"][sid]
            positions = {index: _position(action) for index, action in enumerate(row.get("skill", []))
                         if isinstance(action, list)}
            positions = {index: pos for index, pos in positions.items() if pos is not None}
            for index, position in positions.items():
                row["skill"][index][position] /= MULTIPLIER
            upgrades = row.get("skillUp") or []
            if (isinstance(upgrades, list) and len(upgrades) >= 2
                    and isinstance(upgrades[0], int) and isinstance(upgrades[1], (int, float))
                    and positions.get(upgrades[0]) == 1):
                upgrades[1] /= MULTIPLIER
            for upgrade in upgrades:
                if (isinstance(upgrade, list) and len(upgrade) >= 3
                        and positions.get(upgrade[0]) == upgrade[1]):
                    upgrade[2] /= MULTIPLIER
            for upgrade in row.get("skillUpPaths") or []:
                if (isinstance(upgrade, list) and len(upgrade) >= 3
                        and isinstance(upgrade[1], list) and len(upgrade[1]) == 1
                        and positions.get(upgrade[0]) == upgrade[1][0]):
                    upgrade[2] /= MULTIPLIER
        cls.after = copy.deepcopy(cls.before)
        cls.report = apply_orange_four_stat_buffs(cls.after)

    def test_all_reachable_orange_actions_and_rank_deltas_are_scaled_only_at_magnitude(self):
        old = self.before["cfg"]
        new = self.after["cfg"]
        owners = {}
        for aid, avatar in old["avatar"].items():
            for slot in (10, 11, 13):
                pl = avatar.get("pl", [])
                if len(pl) > slot and isinstance(pl[slot], str):
                    owners.setdefault(pl[slot], set()).add(aid)
        target_actions = 0
        for sid, row in old["skill"].items():
            if not any(aid.startswith("A_") and aid.endswith("_6") for aid in owners.get(sid, ())):
                self.assertEqual(new["skill"][sid], row, sid)
                continue
            changed = new["skill"][sid]
            expected = copy.deepcopy(row)
            positions = {}
            for index, action in enumerate(row.get("skill", [])):
                if isinstance(action, list) and (position := _position(action)) is not None:
                    positions[index] = position
                    expected["skill"][index][position] *= 5
                    target_actions += 1
            for upgrade in expected.get("skillUp") or []:
                if isinstance(upgrade, list) and len(upgrade) >= 3 and positions.get(upgrade[0]) == upgrade[1]:
                    upgrade[2] *= 5
            for upgrade in expected.get("skillUpPaths") or []:
                if (isinstance(upgrade, list) and len(upgrade) >= 3
                        and isinstance(upgrade[1], list) and len(upgrade[1]) == 1
                        and positions.get(upgrade[0]) == upgrade[1][0]):
                    upgrade[2] *= 5
            for text_field in ("info", "rankInfoTemplate"):
                expected.pop(text_field, None)
                changed = dict(changed)
                changed.pop(text_field, None)
            self.assertEqual(changed, expected, sid)
        self.assertEqual(self.report["actions"], target_actions)
        self.assertGreaterEqual(target_actions, 29)
        self.assertEqual(self.report["cloned_shared_skills"], 0)

    def test_ordinary_purple_and_other_numbers_are_untouched(self):
        old, new = self.before["cfg"]["skill"], self.after["cfg"]["skill"]
        self.assertEqual(new["S_621099_5"], old["S_621099_5"])
        self.assertEqual(new["S_631096_5"], old["S_631096_5"])
        self.assertEqual(new["S_631126_6"]["skill"][2:], old["S_631126_6"]["skill"][2:])
        self.assertEqual(new["S_621029_6"]["skill"][0], old["S_621029_6"]["skill"][0])
        self.assertEqual(new["S_621029_6"]["skill"][1][3:], old["S_621029_6"]["skill"][1][3:])
        self.assertEqual(new["S_301206_6"]["skill"][0][4:], old["S_301206_6"]["skill"][0][4:])

    def test_rank_ten_and_display_track_scaled_flat_buff(self):
        old, new = self.before["cfg"]["skill"], self.after["cfg"]["skill"]
        sid = "S_621099_6"
        old_ten = old[sid]["skill"][0][2] + 9 * next(x[2] for x in old[sid]["skillUp"] if x[:2] == [0, 2])
        new_ten = new[sid]["skill"][0][2] + 9 * next(x[2] for x in new[sid]["skillUp"] if x[:2] == [0, 2])
        self.assertAlmostEqual(new_ten, 5 * old_ten)
        self.assertIn("2400点暴击", new[sid]["info"])
        self.assertIn("{flat:0:2}点暴击", new[sid]["rankInfoTemplate"])
        self.assertIn("500点闪避", new["S_621029_6"]["info"])

    def test_repeat_is_idempotent_and_shared_purple_row_is_cloned(self):
        before = copy.deepcopy(self.after)
        self.assertEqual(apply_orange_four_stat_buffs(self.after), self.report)
        self.assertEqual(self.after, before)
        shared = {
            "cfg": {
                "avatar": {
                    "A_1000_5": {"pl": [None] * 10 + ["S_shared", None, None, None]},
                    "A_1000_6": {"pl": [None] * 10 + ["S_shared", None, None, None]},
                },
                "skill": {"S_shared": {"id": "S_shared", "info": "增加10点暴击，持续2回合。",
                                       "skill": [["stat_flat", "crit", 10, 2, "FX"]],
                                       "actionTargetPolicies": ["ally_self"],
                                       "skillUp": [[0, 2, 1]]}},
            }
        }
        result = apply_orange_four_stat_buffs(shared)
        self.assertEqual(result["cloned_shared_skills"], 1)
        self.assertEqual(shared["cfg"]["skill"]["S_shared"]["skill"][0][2], 10)
        orange_sid = shared["cfg"]["avatar"]["A_1000_6"]["pl"][10]
        self.assertNotEqual(orange_sid, "S_shared")
        self.assertEqual(shared["cfg"]["avatar"]["A_1000_5"]["pl"][10], "S_shared")
        self.assertEqual(shared["cfg"]["skill"][orange_sid]["skill"][0][2], 50)
        self.assertEqual(shared["cfg"]["skill"][orange_sid]["skillUp"][0][2], 5)

    def test_native_flat_buff_limit_is_checked_before_publishing(self):
        data = {"cfg": {"avatar": {"A_1000_6": {"pl": [None] * 10 + ["S_large"]}},
                        "skill": {"S_large": {"id": "S_large",
                                              "skill": [["stat_flat", "hit", 20_001, 2, "FX"]],
                                              "actionTargetPolicies": ["ally_self"]}}}}
        with self.assertRaisesRegex(ValueError, "native cap"):
            apply_orange_four_stat_buffs(data)

    def test_legacy_rank_upgrade_scales_attrup_coefficient(self):
        data = {"cfg": {"avatar": {"A_1000_6": {"pl": [None] * 10 + ["S_legacy"]}},
                        "skill": {"S_legacy": {"id": "S_legacy",
                                               "skill": [["attrup", .1, "flee", 0, 2, "FX"]],
                                               "skillUp": [0, .01]}}}}
        apply_orange_four_stat_buffs(data)
        row = data["cfg"]["skill"]["S_legacy"]
        self.assertAlmostEqual(row["skill"][0][1], .5)
        self.assertAlmostEqual(row["skillUp"][1], .05)


if __name__ == "__main__":
    unittest.main()
