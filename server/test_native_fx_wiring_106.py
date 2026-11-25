"""Native effectDB wiring: art exists, only the effect slot changes, timing kept."""

import copy
import json
import re
import struct
import sys
import unittest
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from native_fx_wiring_106 import (ACTION_RULES, MANUAL_ABILITY_RULES, MISSING_FX, NATIVE_FX,
                                  apply_native_fx_wiring)


ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "config/reconstruction/full-config.json"
TEMPLATE = ROOT / "client/resources/template/MainLLOL.swf"
CODE_FX = [ROOT / "client/src" / name for name in
           ("hero_fx_core_106.aspart", "hero_fx_a_106.aspart", "hero_fx_b_106.aspart",
            "hero_fx_c_106.aspart", "kaisa_rain_fx_106.aspart")]


def effect_armatures():
    """Armature names of the effectDB skeleton embedded in the shipped SWF."""
    data = TEMPLATE.read_bytes()
    body = zlib.decompress(data[8:]) if data[:3] == b"CWS" else data[8:]
    offset = (5 + 4 * (body[0] >> 3) + 7) // 8 + 4
    while offset < len(body):
        header = struct.unpack("<H", body[offset:offset + 2])[0]
        offset += 2
        code, length = header >> 6, header & 0x3F
        if length == 0x3F:
            length = struct.unpack("<I", body[offset:offset + 4])[0]
            offset += 4
        payload = body[offset:offset + length]
        offset += length
        if code == 87 and b'<dragonBones name="effectDB"' in payload[:200]:
            return set(re.findall(r'<armature name="effect/(e\d+)"', payload[6:].decode("utf-8")))
        if code == 0:
            break
    raise AssertionError("effectDB skeleton not found in the template SWF")


def effect_slot(action):
    if action[0] == "manual_ability":
        return action[3] if len(action) > 3 else None
    return action[-1]


class NativeFxWiringTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.raw = json.loads(CONFIG.read_text(encoding="utf-8"))
        cls.armatures = effect_armatures()

    def test_every_new_descriptor_plays_existing_native_art(self):
        for key, descriptor in NATIVE_FX.items():
            with self.subTest(effect=key):
                self.assertIn("b", descriptor)
                self.assertIn("h", descriptor)
                for part in ("b", "h", "p"):
                    if part in descriptor:
                        self.assertIn(descriptor[part]["id"], self.armatures)
        for key, descriptor in MISSING_FX.items():
            with self.subTest(effect=key):
                self.assertNotIn(key, self.raw["cfg"]["effect"])
                self.assertEqual(set(descriptor), {"h"})
                self.assertIn(descriptor["h"]["id"], self.armatures)
        self.assertEqual(MISSING_FX["FX60_BURN"]["h"]["id"], self.raw["cfg"]["effect"]["BURN_EFF"]["id"])
        # Lux's beam uses the native stretched-path mode, nothing else does.
        self.assertEqual(NATIVE_FX["FX_A_1060_ULT"]["p"], {"id": "e602", "w": 3, "sc": 0.7})
        self.assertEqual([k for k, d in NATIVE_FX.items() if "p" in d], ["FX_A_1060_ULT"])

    def test_bullet_speed_matches_the_replaced_effect(self):
        effects = self.raw["cfg"]["effect"]
        replaced = {new: old for _, _, old, new, _ in ACTION_RULES}
        for key, descriptor in NATIVE_FX.items():
            with self.subTest(effect=key):
                self.assertEqual(descriptor["sp"], effects[replaced[key]]["sp"])

    def test_only_the_effect_slot_of_matching_actions_changes(self):
        document = copy.deepcopy(self.raw)
        before = copy.deepcopy(document["cfg"]["skill"])
        self.assertIs(apply_native_fx_wiring(document), document)
        after = document["cfg"]["skill"]
        changed = {key for key in after if after[key] != before[key]}
        self.assertTrue({"S_631060_4", "S_631060_6", "S_621096_6", "S_631022_5"} <= changed)
        for key in changed:
            old_actions, new_actions = before[key]["skill"], after[key]["skill"]
            self.assertEqual({k: v for k, v in after[key].items() if k != "skill"},
                             {k: v for k, v in before[key].items() if k != "skill"})
            self.assertEqual(len(old_actions), len(new_actions))
            for old, new in zip(old_actions, new_actions):
                if old == new:
                    continue
                with self.subTest(skill=key, action=old[0]):
                    slot = 3 if old[0] == "manual_ability" else len(old) - 1
                    self.assertEqual(old[:slot] + old[slot + 1:], new[:slot] + new[slot + 1:])
                    self.assertIn(new[slot], NATIVE_FX)
        lux = [a[-1] for a in after["S_631060_6"]["skill"]]
        self.assertEqual(lux, ["FX_S9140_HIT", "FX_A_1060_ULT", "FX_S9140_HIT", "FX_S9140_FLEE"])
        ahri = [a[-1] for a in after["S_631022_5"]["skill"] if a[0] == "damage"]
        self.assertEqual(ahri, ["FX_A_1022_CHARM", "FX_A_1022_MAGIC", "FX_A_1022_MAGIC", "FX_A_1022_MAGIC"])
        cards = [a[-1] for a in after["S_621096_6"]["skill"] if a[0] == "damage"]
        self.assertEqual(cards, ["FX_A_1096_CARD"] * 3)
        # Light Binding and Destiny keep their look.
        self.assertIn("FX_A_1060_MAGIC", [a[-1] for a in after["S_621060_6"]["skill"]])
        self.assertIn("FX_A_1096_MAGIC", [a[-1] for a in after["S_631096_6"]["skill"]])

    def test_rerun_is_idempotent(self):
        document = copy.deepcopy(self.raw)
        apply_native_fx_wiring(document)
        first = copy.deepcopy(document)
        apply_native_fx_wiring(document)
        self.assertEqual(document, first)

    def test_wired_heroes_are_not_claimed_by_code_effects(self):
        source = "\n".join(path.read_text(encoding="utf-8") for path in CODE_FX)
        for hero in ("A_1060", "A_1022", "A_1096"):
            self.assertNotIn(hero, source)
        for key in NATIVE_FX:
            self.assertNotIn(key, source)
        for ability, old, _ in MANUAL_ABILITY_RULES:
            self.assertNotIn(ability, source)

    def test_runtime_tables_resolve_every_effect_to_native_art(self):
        import gateway
        document = gateway.build_static_config(CONFIG)
        cfg = document["cfg"]
        effects = cfg["effect"]
        skills = cfg["skill"]
        for hero, expected in (("A_1060_6", "FX_A_1060_ULT"), ("A_1022_6", "FX_A_1022_CHARM"),
                               ("A_1096_6", "FX_A_1096_CARD")):
            names = {effect_slot(action) for sid in cfg["avatar"][hero]["pl"]
                     if isinstance(sid, str) and sid in skills
                     for action in skills[sid].get("skill") or [] if isinstance(action, list)}
            self.assertIn(expected, names, hero)
        missing = set()
        for sid, skill in skills.items():
            for action in skill.get("skill") or []:
                if isinstance(action, list) and action:
                    name = effect_slot(action)
                    if isinstance(name, str) and name.startswith("FX") and name not in effects:
                        missing.add((sid, name))
        self.assertEqual(missing, set())

        def ids(row):
            if isinstance(row, dict):
                for key, value in row.items():
                    if key == "id" and isinstance(value, str) and re.fullmatch(r"e\d{3}", value):
                        yield value
                    else:
                        yield from ids(value)
        dangling = {(key, art) for key, row in effects.items() for art in ids(row) if art not in self.armatures}
        self.assertEqual(dangling, set())


if __name__ == "__main__":
    unittest.main()
