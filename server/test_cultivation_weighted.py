"""Targeted weighted-cultivation boundaries; all storage is in memory."""

import copy
import json
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from cultivation_rules import (  # noqa: E402
    SCHEMA, active, apply_cultivation_config, cap, normalize_profile,
    roll, used, weighted_feed,
)
from gameplay_roster import GameplayRosterEquipment  # noqa: E402
from player_store import GameplayFault, PlayerStore  # noqa: E402


class WeightedCultivationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source = json.loads((Path(__file__).resolve().parents[1] /
                             "config/reconstruction/full-config.json").read_text(encoding="utf-8"))
        cls.config = apply_cultivation_config(source)
        cls.cfg = cls.config["cfg"]

    @staticmethod
    def hero(aid="A_1078_6", **changes):
        result = {"id": aid + "|culture", "aid": aid + "|culture", "lv": 99,
                  "slv": 1, "exp": 0, "phase": 0, "limit_break": 0,
                  "morph": 0, "love_exp": 0,
                  "hp": 0, "ap": 0, "de_ph": 0, "de_ma": 0}
        result.update(changes)
        return result

    def test_overlay_and_phase_only_caps(self):
        self.assertEqual(self.cfg["system_simple"]["culture"]["price"],
                         {"coin": {"1": 100, "10": 1000},
                          "culture_book": {"1": 1, "10": 10}})
        simple = self.cfg["system_simple"]
        orange = self.hero(culture_schema=SCHEMA, pith_max=999999)
        purple = self.hero("A_1001_5", culture_schema=SCHEMA, pith_max=999999)
        self.assertEqual([cap({**orange, "phase": phase}, simple) for phase in range(5)],
                         [60000, 70000, 80000, 90000, 90000])
        self.assertEqual([cap({**purple, "phase": phase}, simple) for phase in range(5)],
                         [30000, 35000, 40000, 45000, 45000])
        self.assertFalse(active(simple, self.hero("A_1001_4")))
        self.assertFalse(active(simple, self.hero("A_2001_6")))

    def test_legacy_migration_preserves_actual_stats_and_pending_delta_once(self):
        simple = self.cfg["system_simple"]
        old = self.hero(hp=51, ap=19, de_ph=23, de_ma=17)
        profile = {"avatars": {old["id"]: old}, "attrs": {"avatar_culture": {
            "aid": old["id"], "eqid": old["id"],
            "rolled": {"hp": 3, "ap": 2, "de_ph": 1, "de_ma": 2}}}}
        roster = GameplayRosterEquipment(None, self.config)
        before = roster.battle_attributes(copy.deepcopy(profile), old["id"])
        self.assertTrue(normalize_profile(profile, self.cfg))
        self.assertEqual(old["culture_schema"], SCHEMA)
        self.assertEqual(old["culture_legacy_raw"]["values"],
                         {"hp": 51, "ap": 19, "de_ph": 23, "de_ma": 17})
        after = roster.battle_attributes(profile, old["id"])
        for key in ("hp", "ap", "de_ph", "de_ma"):
            self.assertEqual(before[key], after[key], key)
        row = self.cfg["avatar"]["A_1078_6"]["pl"]
        pending = profile["attrs"]["avatar_culture"]
        for key, slope in (("hp", 1), ("ap", 3), ("de_ph", 5), ("de_ma", 7)):
            source = old["culture_legacy_raw"]["values"][key]
            extra = pending["legacy_rolled_raw"][key]
            self.assertEqual(pending["rolled"][key],
                             int((source + extra) * row[slope] * .008)
                             - int(source * row[slope] * .008))
        stable = copy.deepcopy(profile)
        self.assertFalse(normalize_profile(profile, self.cfg))
        self.assertEqual(profile, stable)
        self.assertEqual(pending["schema"], SCHEMA)
        self.assertGreaterEqual(used(old, simple), 0)

    def test_roll_exact_budget_near_cap_and_existing_overcap(self):
        class Deterministic:
            def __init__(self): self.n = 0
            def randrange(self, maximum):
                self.n += 1
                return maximum * self.n // 4
        simple = self.cfg["system_simple"]
        for aid, budget in (("A_1078_6", 500), ("A_1001_5", 250)):
            hero = self.hero(aid, culture_schema=SCHEMA)
            weights = simple["culture"]["weighted"]["weights"]
            for count in (1, 10):
                result = roll(hero, count, simple, Deterministic())
                self.assertEqual(sum(result[key] * weights[key] for key in weights), budget * count)
            hero["hp"] = cap(hero, simple) - 13
            result = roll(hero, 10, simple, Deterministic())
            self.assertEqual(sum(result[key] * weights[key] for key in weights), 13)
            hero["hp"] = cap(hero, simple) + 500
            self.assertEqual(sum(roll(hero, 1, simple, Deterministic()).values()), 0)
            self.assertEqual(hero["hp"], cap(hero, simple) + 500)

    def test_feed_uses_actual_gains_without_pith_max(self):
        simple = self.cfg["system_simple"]
        target = self.hero(culture_schema=SCHEMA, hp=59990, pith_max=100000)
        source = self.hero("A_1001_5", culture_schema=SCHEMA,
                           hp=8, ap=1, de_ph=1, de_ma=1)
        weighted_feed(target, [(source, self.cfg["avatar"]["A_1001_5"])], simple)
        self.assertGreater(used(target, simple), 59990)
        self.assertLessEqual(used(target, simple), 60000)
        self.assertEqual(target["pith_max"], 100000)

    def test_store_roll_save_retry_and_cancel(self):
        db = sqlite3.connect(":memory:", check_same_thread=False)
        self.addCleanup(db.close)
        store = PlayerStore(db, self.config)
        uid = store.login("weighted-cultivation-test")["uid"]
        hero = self.hero()

        def seed(profile):
            profile["avatars"][hero["id"]] = copy.deepcopy(hero)
            profile["coin"] = 2500
            profile["attrs"]["culture_book"] = 20
            return profile, {}

        store.atomic_update(uid, seed)
        roster = GameplayRosterEquipment(store, self.config)
        migrated = store.profile(uid)["avatars"][hero["id"]]
        self.assertEqual(migrated["culture_schema"], SCHEMA)
        request = {"aid": hero["id"], "num": "10", "type": "culture_book", "actionID": "roll-1"}
        rolled_response = roster.dispatch(uid, "user.avatar_culture", request)
        self.assertEqual(rolled_response["avatar_culture"]["schema"], SCHEMA)
        pending = store.profile_raw(uid)["attrs"]["avatar_culture"]
        self.assertEqual(pending["schema"], SCHEMA)
        self.assertEqual(pending["spent"], {"culture_book": 10})
        self.assertEqual(store.profile_raw(uid)["attrs"]["culture_book"], 10)
        save = {"actionID": "save-1"}
        roster.dispatch(uid, "user.avatar_culture_save", save)
        first = copy.deepcopy(store.profile_raw(uid)["avatars"][hero["id"]])
        self.assertEqual(used(first, self.cfg["system_simple"]), 5000)
        roster.dispatch(uid, "user.avatar_culture_save", save)
        self.assertEqual(store.profile_raw(uid)["avatars"][hero["id"]], first)
        with self.assertRaises(GameplayFault):
            roster.dispatch(uid, "user.avatar_culture_save", {"actionID": "save-new"})
        roster.dispatch(uid, "user.avatar_culture", {
            "aid": hero["id"], "num": 1, "type": "coin", "actionID": "roll-2"})
        roster.dispatch(uid, "user.avatar_culture_cancel", {"actionID": "cancel-1"})
        self.assertEqual(store.profile_raw(uid)["avatars"][hero["id"]], first)

    def test_paid_legacy_pending_survives_migration_and_saves_once(self):
        db = sqlite3.connect(":memory:", check_same_thread=False)
        self.addCleanup(db.close)
        store = PlayerStore(db, self.config)
        uid = store.login("weighted-legacy-pending-test")["uid"]
        hero = self.hero(hp=250000, ap=9)
        pending_raw = {"hp": 3, "ap": 4, "de_ph": 2, "de_ma": 1}

        def seed(profile):
            profile["avatars"][hero["id"]] = copy.deepcopy(hero)
            profile["attrs"]["avatar_culture"] = {"aid": hero["id"], "eqid": hero["id"],
                "rolled": pending_raw, "save_status": dict(pending_raw), "spent": {"coin": 100}}
            return profile, {}

        store.atomic_update(uid, seed)
        normalized = store.profile(uid)
        first = normalized["avatars"][hero["id"]]
        pending = normalized["attrs"]["avatar_culture"]
        self.assertGreater(used(first, self.cfg["system_simple"]), cap(first, self.cfg["system_simple"]))
        self.assertEqual(pending["schema"], SCHEMA)
        self.assertEqual(pending["legacy_rolled_raw"], pending_raw)
        roster = GameplayRosterEquipment(store, self.config)
        roster.dispatch(uid, "user.avatar_culture_save", {"actionID": "save-old"})
        saved = store.profile_raw(uid)["avatars"][hero["id"]]
        for key in ("hp", "ap", "de_ph", "de_ma"):
            self.assertEqual(saved[key], first[key] + pending["rolled"][key])
        roster.dispatch(uid, "user.avatar_culture_save", {"actionID": "save-old"})
        self.assertEqual(store.profile_raw(uid)["avatars"][hero["id"]], saved)
        with self.assertRaises(GameplayFault) as rejected:
            roster.dispatch(uid, "user.avatar_culture", {"aid": hero["id"], "type": "coin"})
        self.assertEqual(rejected.exception.code, "MaxCulture")


if __name__ == "__main__":
    unittest.main()
