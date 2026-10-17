"""Focused hero growth rules for feeding, promotion, and cultivation."""

import copy
import json
import sqlite3
import unittest
from pathlib import Path

from cultivation_rules import (SCHEMA as CULTURE_SCHEMA,
                               apply_cultivation_config, used as culture_used)
from gameplay_roster import GameplayRosterEquipment
from player_store import GameplayFault, PlayerStore


class GrowthOverhaulTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        path = Path(__file__).resolve().parents[1] / "config/reconstruction/full-config.json"
        cls.config = apply_cultivation_config(json.loads(path.read_text(encoding="utf-8")))

    def setUp(self):
        self.db = sqlite3.connect(":memory:", check_same_thread=False)
        self.addCleanup(self.db.close)
        self.store = PlayerStore(self.db, self.config)
        self.uid = self.store.login(self.id())["uid"]
        self.roster = GameplayRosterEquipment(self.store, self.config)

    @staticmethod
    def hero(aid, suffix, *, level=1, exp=0, phase=0, slv=1):
        iid = f"{aid}|{suffix}"
        return iid, {"id": iid, "aid": iid, "lv": level, "exp": exp,
                     "phase": phase, "slv": slv, "morph": 0, "limit_break": 0,
                     "hp": 0, "ap": 0, "de_ph": 0, "de_ma": 0}

    def seed(self, heroes, *, gold=0, coin=0):
        def mutate(profile):
            profile["avatars"] = copy.deepcopy(dict(heroes))
            profile["gold"] = gold
            profile["coin"] = coin
            profile["team"] = [[None] * 6 for _ in range(3)]
            return profile, {}
        self.store.atomic_update(self.uid, mutate)

    def test_feed_charges_one_gold_per_ten_offered_xp(self):
        target = self.hero("A_1101_5", "target")
        food = self.hero("A_6996_5", "food")
        self.seed([target, food], gold=100_000)
        offered = self.roster._hero_offer_exp(food[1])
        expected_price = (offered + 9) // 10
        result = self.roster.dispatch(self.uid, "user.swallow_avatar", {
            "aid": target[0], "aids": [food[0]], "actionID": "feed-price"})
        self.assertEqual(result["gold"], 100_000 - expected_price)
        self.assertNotIn(food[0], self.store.profile_raw(self.uid)["avatars"])
        self.assertEqual(self.roster.dispatch(self.uid, "user.swallow_avatar", {
            "aid": target[0], "aids": [food[0]], "actionID": "feed-price"}), result)

    def test_star_up_is_free_preserves_level_and_rejects_extra_materials(self):
        target = self.hero("A_1001_4", "target", level=60, exp=17)
        spare = self.hero("A_1002_4", "spare")
        self.seed([target, spare], gold=0, coin=0)
        with self.assertRaises(GameplayFault) as caught:
            self.roster.dispatch(self.uid, "user.star_up", {
                "aid": target[0], "aids": [spare[0]], "actionID": "extra"})
        self.assertEqual(caught.exception.code, "InvalidMaterials")
        promoted = self.roster.dispatch(self.uid, "user.star_up", {
            "aid": target[0], "aids": [], "actionID": "promote"})
        self.assertEqual((promoted["lv"], promoted["exp"], promoted["phase"]), (60, 17, 0))
        self.assertEqual(promoted["id"], "A_1001_5|target")
        profile = self.store.profile_raw(self.uid)
        self.assertEqual((profile["gold"], profile["coin"]), (0, 0))
        self.assertIn(spare[0], profile["avatars"])
        self.assertEqual(self.roster.dispatch(self.uid, "user.star_up", {
            "aid": target[0], "aids": [], "actionID": "promote"}), promoted)

    def test_purple_to_orange_requires_phase_two_then_resets_phase(self):
        target = self.hero("A_1101_5", "target", level=99, exp=7, phase=1)
        self.seed([target], gold=0)
        with self.assertRaises(GameplayFault) as caught:
            self.roster.dispatch(self.uid, "user.star_up", {"aid": target[0], "aids": []})
        self.assertEqual(caught.exception.code, "PhaseRequired")
        self.assertIn(target[0], self.store.profile_raw(self.uid)["avatars"])
        def advance(profile):
            profile["avatars"][target[0]]["phase"] = 2
            return profile, {}
        self.store.atomic_update(self.uid, advance)
        promoted = self.roster.dispatch(self.uid, "user.star_up", {
            "aid": target[0], "actionID": "orange"})
        self.assertEqual((promoted["lv"], promoted["exp"], promoted["phase"]), (99, 7, 0))
        self.assertEqual(promoted["id"], "A_1101_6|target")

    def test_promotion_bounds_stored_xp_without_lowering_level(self):
        target = self.hero("A_1001_4", "overflow", level=60, exp=10_000_000)
        self.seed([target])
        promoted = self.roster.dispatch(self.uid, "user.star_up", {"aid": target[0]})
        step = (self.roster._exp_requirement("A_1001_5", 61)
                - self.roster._exp_requirement("A_1001_5", 60))
        self.assertEqual(promoted["lv"], 60)
        self.assertEqual(promoted["exp"], step - 1)

    def test_morph_is_unavailable_without_mutating_profile(self):
        target = self.hero("A_1101_5", "target", level=99)
        self.seed([target], gold=100)
        before = self.store.profile_raw(self.uid)
        with self.assertRaises(GameplayFault) as caught:
            self.roster.dispatch(self.uid, "user.morph", {"aid": target[0]})
        self.assertEqual(caught.exception.code, "MorphNotOpen")
        self.assertEqual(caught.exception.message, "转化功能尚未开放")
        self.assertEqual(self.store.profile_raw(self.uid), before)

    def test_only_biscuits_raise_skill_chance_and_one_feed_raises_one_level(self):
        target = self.hero("A_1101_5", "target", level=99)
        target[1].update({"culture_schema": CULTURE_SCHEMA, "hp": 30000})
        same_hero = self.hero("A_1101_5", "same")
        biscuits = [self.hero("A_6992_6", f"biscuit-{i}") for i in range(5)]
        self.seed([target, same_hero, *biscuits], gold=100_000)
        self.roster.simple["skill_biscuit_ids"] = ["A_6992_6"]
        self.assertEqual(self.roster._native_skill_upgrade_probability(
            "A_1101_5", target[1], [same_hero[1]]), 0)
        for biscuit_aid in ("A_6992_4", "A_6992_5", "A_6992_6"):
            self.assertEqual(self.roster._native_skill_upgrade_probability(
                "A_1101_5", target[1], [{"aid": biscuit_aid}]), 20)
        with self.assertRaises(GameplayFault) as caught:
            self.roster.dispatch(self.uid, "user.swallow_avatar", {
                "aid": target[0], "aids": [same_hero[0]], "actionID": "no-skill"})
        self.assertEqual(caught.exception.code, "MaxGrowth")
        self.assertIn(same_hero[0], self.store.profile_raw(self.uid)["avatars"])
        self.assertEqual(self.roster._native_skill_upgrade_probability(
            "A_1101_5", target[1], [hero[1] for hero in biscuits]), 100)
        class CertainRoll:
            def randrange(self, limit): return 0
        self.roster.rng = CertainRoll()
        result = self.roster.dispatch(self.uid, "user.swallow_avatar", {
            "aid": target[0], "aids": [hero[0] for hero in biscuits], "actionID": "skill"})
        self.assertEqual(result["avatar"]["slv"], 2)
        self.assertEqual(self.store.profile_raw(self.uid)["avatars"][target[0]]["slv"], 2)

    def test_cultivation_allocates_500_per_attempt_and_retains_raw_roll_audit(self):
        class FixedRoll:
            def choice(self, fields): return "ap"
            def randint(self, minimum, maximum): return 1

        target = self.hero("A_1101_5", "target", level=99)
        self.seed([target], coin=1000)
        self.roster.rng = FixedRoll()
        for i in range(10):
            self.roster.dispatch(self.uid, "user.avatar_culture", {
                "aid": target[0], "num": 1, "type": "coin", "actionID": f"roll-{i}"})
            pending = self.store.profile_raw(self.uid)["attrs"]["avatar_culture"]
            self.assertEqual(pending["rolled_raw"], {"hp": 0, "ap": 1, "de_ph": 0, "de_ma": 0})
            self.roster.dispatch(self.uid, "user.avatar_culture_save", {
                "actionID": f"save-{i}"})
        saved = self.store.profile_raw(self.uid)
        hero = saved["avatars"][target[0]]
        self.assertEqual(hero["ap"], 10 * (500 // 12))
        self.assertEqual(hero["hp"], 10 * (500 % 12))
        self.assertEqual(hero["culture_roll_raw"]["ap"], 10)
        self.assertEqual(saved["coin"], 0)
        self.assertEqual(culture_used(hero, self.roster.simple), 5000)


if __name__ == "__main__":
    unittest.main()
