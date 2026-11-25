"""Native effectDB wiring: art exists, only the effect slot changes, timing kept."""

import copy
import json
import re
import struct
import subprocess
import sys
import unittest
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from native_fx_wiring_106 import (ACTION_RULES, DERIVED_FX, MANUAL_ABILITY_RULES, MISSING_FX,
                                  NATIVE_FX, SELF_FX, apply_native_fx_wiring)


ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / "config/reconstruction/full-config.json"
TEMPLATE = ROOT / "client/resources/template/MainLLOL.swf"
CODE_FX = sorted((ROOT / "client/src").glob("hero_fx_*_106.aspart")) + [ROOT / "client/src/kaisa_rain_fx_106.aspart"]
NEW_FX = {**NATIVE_FX, **DERIVED_FX, **SELF_FX}
# Round two: hero, skill id of the top-star copy, effect it must now use.
ROUND_TWO = (
    ("A_1002_6", "FX_A_1002_CRYSTAL"), ("A_1021_6", "FX_A_1021_MYSTIC"), ("A_1016_6", "FX_A_1016_MARK"), ("A_1016_6", "FX_A_1016_STORM"),
    ("A_1099_6", "FX_A_1099_VENOM"), ("A_1068_6", "FX_A_1068_PYRO"), ("A_1029_6", "FX_A_1029_FIREBALL"),
    ("A_1077_6", "FX_A_1077_SHARD"), ("A_1063_6", "FX_A_1063_FANG"), ("A_1131_6", "FX_A_1131_TIDE"),
    ("A_1095_6", "FX_A_1095_REWIND"), ("A_1056_6", "FX_A_1056_WIND"), ("A_1023_6", "FX_A_1023_BLADE"),
    ("A_1097_6", "FX_A_1097_FEAR"), ("A_1025_6", "FX_A_1025_ACE"), ("A_1011_6", "FX_A_1011_BARRAGE"),
)


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
        for key, (_, parts) in DERIVED_FX.items():
            with self.subTest(effect=key):
                self.assertTrue(parts)
                for change in parts.values():
                    if change is not None:
                        self.assertIn(change["id"], self.armatures)
                        self.assertLessEqual(set(change), {"id", "sc"})
        for key, descriptor in SELF_FX.items():
            with self.subTest(effect=key):
                self.assertEqual(set(descriptor), {"h"})
                self.assertIn(descriptor["h"]["id"], self.armatures)
        # Every idle hero art piece is placed once; e005 serves both barrage copies.
        art = [c["id"] for _, parts in DERIVED_FX.values() for c in parts.values() if c]
        art = [a for a in art if a not in ("e029", "e542", "e023", "e006", "e014")]
        self.assertEqual(sorted(set(art)), sorted(["e520", "e505", "e206", "e009", "e510", "e516", "e507", "e514",
                                                     "e545", "e070", "e002", "e503", "e513", "e546", "e543", "e005"]))

    def test_bullet_speed_matches_the_replaced_effect(self):
        effects = self.raw["cfg"]["effect"]
        replaced = {new: old for _, _, old, new, _ in ACTION_RULES}
        for key, descriptor in NATIVE_FX.items():
            with self.subTest(effect=key):
                self.assertEqual(descriptor["sp"], effects[replaced[key]]["sp"])

    def test_derived_effects_keep_speed_and_sound_of_what_they_replace(self):
        document = copy.deepcopy(self.raw)
        import gateway
        effects = gateway.build_static_config(CONFIG)["cfg"]["effect"]
        for key, (base, parts) in DERIVED_FX.items():
            with self.subTest(effect=key):
                old, new = effects[base], effects[key]
                self.assertEqual(new.get("sp"), old.get("sp"))
                for part in ("b", "h"):
                    if parts.get(part, 0) is None:
                        self.assertNotIn(part, new)
                    elif part in old:
                        self.assertEqual({k: v for k, v in new[part].items() if k not in ("id", "sc")},
                                         {k: v for k, v in old[part].items() if k not in ("id", "sc")})
        self.assertEqual({k for _, _, _, k, _ in ACTION_RULES} - set(NATIVE_FX), set(DERIVED_FX))

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
                    self.assertIn(new[slot], NEW_FX)
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
        for hero in ("A_1060", "A_1022", "A_1096", "A_1002", "A_1021", "A_1016", "A_1099", "A_1068", "A_1029",
                     "A_1077", "A_1063", "A_1131", "A_1095", "A_1056", "A_1023", "A_1097", "A_1025", "A_1011", "A_1120"):
            self.assertNotIn(hero, source)
        for key in NEW_FX:
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
                               ("A_1096_6", "FX_A_1096_CARD"), *ROUND_TWO):
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
        for key in NEW_FX:
            self.assertIn(key, effects)

    def test_kayle_guard_plays_its_dome(self):
        avatar = (ROOT / "client/src/stages/137_Avatar.as").read_text(encoding="utf-8")
        start = avatar.index('if(kind=="six_batch_kayle_c")', avatar.index("private function sixBatchExecute105("))
        branch = avatar[start:avatar.index("return true;", start)]
        body = branch[branch.index("var guardFx:"):].replace("var guardFx:Object", "let guardFx")
        entry = json.dumps(SELF_FX["FX_A_1120_GUARD"])
        script = f"const entry = {entry}; function showGuard(fightRes) {{{body}}}" + """
const assert = require("node:assert/strict");
const GameMap = {actionDelay: 0.5};
const owner = {};
let effectEntry = entry;
let played;
const Tools = {clone(value) { return {...value}; }};
const DisplayTools = {
    getAttrs(name) {
        assert.equal(name, "FX_A_1120_GUARD");
        return effectEntry;
    },
    addEffects(descriptor) { played = descriptor; }
};
const GameMapLayer = {
    isFastest: false,
    gl: {
        effectLayer: {},
        delayCall(callback, delay, descriptor) {
            assert.equal(delay, GameMap.actionDelay);
            callback(descriptor);
        }
    }
};
showGuard.call(owner, {parent: {}});
assert.deepEqual(played, {...entry.h, a1: owner, par: GameMapLayer.gl.effectLayer});
assert.notEqual(played, entry.h);
assert.equal(entry.h.par, undefined);
played = undefined;
effectEntry = {};
showGuard.call(owner, {parent: {}});
assert.equal(played, undefined);
GameMapLayer.isFastest = true;
effectEntry = entry;
showGuard.call(owner, {parent: {}});
assert.equal(played, undefined);
"""
        run = subprocess.run(["node"], input=script, text=True, encoding="utf-8", capture_output=True, cwd=ROOT)
        self.assertEqual(run.returncode, 0, run.stdout + run.stderr)


if __name__ == "__main__":
    unittest.main()
