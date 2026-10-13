"""Boundary checks for gift-based VIP progression and equipment upgrades."""
import sqlite3
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

from equipment_growth_v2 import (alchemy_bonus_probability, alchemy_upgrade_steps,
                                 upgrade_result, vip_crit_probabilities)
from gameplay_economy import GameplayEconomy
from gameplay_roster import GameplayRosterEquipment
from player_store import GameplayFault, PlayerStore
from vip_campaign import (VIP_THRESHOLDS, credit_vip_gift,
                          legacy_first_bonus_from_receipts, normalize_vip_profile)
from vip_campaign_overlay import apply_vip_campaign


class FixedRandom:
    def __init__(self, value):
        self.value = value

    def random(self):
        return self.value


class VipCampaignTest(unittest.TestCase):
    def test_thresholds_and_legacy_migration_ignore_wallet(self):
        profile = {"coin": 1_000_000, "vip_lv": 2, "vip_exp": 6,
                   "attrs": {"pay_total": 6}, "records": {"pay": {"coin": 60}}}
        self.assertEqual(normalize_vip_profile(profile), 60)
        self.assertEqual((profile["vip_lv"], profile["vip_exp"]), (1, 0))
        self.assertEqual(credit_vip_gift(profile, 120), 180)
        self.assertEqual((profile["vip_lv"], profile["vip_exp"]), (2, 0))
        profile["coin"] = 0
        self.assertEqual(normalize_vip_profile(profile), 180)
        self.assertEqual(credit_vip_gift(profile, 199_820), 200_000)
        self.assertEqual((profile["vip_lv"], profile["vip_exp"]), (15, 0))
        self.assertEqual(credit_vip_gift(profile, 1), 200_001)
        self.assertEqual((profile["vip_lv"], profile["vip_exp"]), (15, 1))

    def test_old_receipt_recovers_first_double_without_other_rewards(self):
        receipt = '{"first_double":true,"base_coin":60,"granted_coin":120}'
        self.assertEqual(legacy_first_bonus_from_receipts(["{}", receipt]), 60)
        self.assertIsNone(legacy_first_bonus_from_receipts(
            ['{"first_double":true,"base_coin":60,"granted_coin":100}']))
        profile = {"coin": 999999, "vip_lv": 1, "vip_exp": 6,
                   "attrs": {"pay_total": 6}, "records": {"pay": {"coin": 60}}}
        self.assertEqual(normalize_vip_profile(profile, 60), 120)
        self.assertEqual((profile["vip_lv"], profile["vip_exp"]), (1, 60))

    def test_payment_double_counts_actual_gift_once(self):
        config = {"cfg": {"vip": {str(i): {"exp": n} for i, n in enumerate(VIP_THRESHOLDS)}}}
        db = sqlite3.connect(":memory:", check_same_thread=False)
        store = PlayerStore(db, config)
        uid = store.login("vip-campaign-test")["uid"]
        self.assertEqual(store.profile_raw(uid)["attrs"]["vip_gift_total_coin"], 0)
        economy = GameplayEconomy(store, config)
        first = economy.local_pay_test(uid, {"pid": "local_60", "actionID": "gift-1"})
        self.assertEqual((first["granted_coin"], first["vip_lv"], first["vip_exp"]), (120, 1, 60))
        replay = economy.local_pay_test(uid, {"pid": "local_60", "actionID": "gift-1"})
        self.assertTrue(replay["replayed"])
        self.assertEqual(store.profile(uid)["attrs"]["vip_gift_total_coin"], 120)
        second = economy.local_pay_test(uid, {"pid": "local_60", "actionID": "gift-2"})
        self.assertEqual((second["vip_gift_total_coin"], second["vip_lv"], second["vip_exp"]), (180, 2, 0))
        db.close()

    def test_legacy_login_recovers_doubled_receipt_and_persists_it(self):
        db = sqlite3.connect(":memory:", check_same_thread=False)
        store = PlayerStore(db, {"cfg": {}})
        uid = store.login("legacy-vip-test")["uid"]
        def make_legacy(profile):
            profile["coin"] = 10_000_000
            profile["vip_lv"] = 0
            profile["vip_exp"] = 6
            profile["attrs"]["pay_total"] = 6
            profile["attrs"]["pay_first_gift"] = 2
            profile["attrs"].pop("vip_gift_total_coin", None)
            profile["records"]["pay"] = {"coin": 60, "count": 1}
            return profile, {}
        store.atomic_update(uid, make_legacy)
        db.execute("INSERT INTO operation_ledger VALUES(?,?,?,?,?)", (
            uid, "user.local_pay_test:old-1", "historical-hash",
            '{"first_double":true,"base_coin":60,"granted_coin":120}', 1))
        db.commit()
        repaired = store.login("legacy-vip-test")
        self.assertEqual(repaired["attrs"]["vip_gift_total_coin"], 120)
        self.assertEqual((repaired["vip_lv"], repaired["vip_exp"]), (1, 60))
        self.assertEqual(store.profile_raw(uid)["attrs"]["vip_gift_total_coin"], 120)
        db.close()

    def test_equipment_outcomes_are_exclusive_monotone_and_capped(self):
        previous = vip_crit_probabilities(0)
        self.assertEqual(sum(previous.values()), 0)
        for level in range(1, 16):
            current = vip_crit_probabilities(level)
            self.assertTrue(all(current[step] >= previous[step] for step in current))
            previous = current
        self.assertEqual(previous, {2: .5, 3: .2, 5: .15, 10: .05})
        for draw, expected in ((0, 2), (.5, 3), (.7, 5), (.85, 10), (.9, 1)):
            self.assertEqual(upgrade_result(10, 30, 15, FixedRandom(draw)), 10 + expected)
        self.assertEqual(upgrade_result(29, 30, 15, FixedRandom(.85)), 30)
        self.assertEqual(upgrade_result(10, 30, 0, FixedRandom(0)), 11)

    def test_alchemy_bonus_advances_star_progress_without_overflow(self):
        self.assertEqual(alchemy_bonus_probability(0), 0)
        self.assertEqual(alchemy_bonus_probability(15), .3)
        self.assertEqual(alchemy_upgrade_steps(0, FixedRandom(0)), 1)
        self.assertEqual(alchemy_upgrade_steps(15, FixedRandom(0)), 2)
        roster = GameplayRosterEquipment.__new__(GameplayRosterEquipment)
        roster.simple = {"equip_alchemy": {"star_lv": 7}}
        roster.rng = FixedRandom(0)
        roster._equip = lambda p, key: (key, p["my_equips"][key])
        roster._equip_sell_rewards = lambda mat: (0, 0, [0, 0, 0, 0])
        def make_profile(vip, phase, extra, star):
            item = {"eid": f"E_1001_{star}", "alchemy": [phase, extra]}
            return {"vip_lv": vip, "my_equips": {"target": item, "mat": dict(item)},
                    "gold": 0, "mark": 0, "attrs": {"dust": [0, 0, 0, 0]}}
        ordinary = make_profile(0, 1, 0, 5)
        roster._mutate(ordinary, "user.equip_alchemy", {"eqids": ["target", "mat"]})
        self.assertEqual(ordinary["my_equips"]["target"]["alchemy"], [2, 0])
        bonus = make_profile(15, 1, 0, 5)
        receipt = roster._mutate(bonus, "user.equip_alchemy", {"eqids": ["target", "mat"]})
        self.assertEqual((bonus["my_equips"]["target"]["alchemy"], receipt["alchemy_bonus_step"]),
                         ([0, 1], 1))
        capped = make_profile(15, 2, 0, 6)
        capped_receipt = roster._mutate(capped, "user.equip_alchemy", {"eqids": ["target", "mat"]})
        self.assertEqual(capped["my_equips"]["target"]["alchemy"], [0, 1])
        self.assertEqual(capped_receipt["alchemy_bonus_step"], 0)

    def test_overlay_projects_thresholds_without_version_change(self):
        doc = {"cfg_version": "1.0.0", "cfg": {"vip": {str(i): {} for i in range(16)}}}
        apply_vip_campaign(doc)
        self.assertEqual(doc["cfg_version"], "1.0.0")
        self.assertEqual(doc["cfg"]["vip"]["0"],
                         {"exp": 0, "need_exp": 60, "equip_upgrade_multi_percent": 0,
                          "equip_alchemy_bonus_percent": 0})
        self.assertEqual(doc["cfg"]["vip"]["14"],
                         {"exp": 120_000, "need_exp": 80_000, "equip_upgrade_multi_percent": 84,
                          "equip_alchemy_bonus_percent": 28})
        self.assertEqual(doc["cfg"]["vip"]["15"],
                         {"exp": 200_000, "need_exp": 0, "equip_upgrade_multi_percent": 90,
                          "equip_alchemy_bonus_percent": 30})

    def test_limit_break_consumes_only_offered_full_level_hero(self):
        roster = GameplayRosterEquipment.__new__(GameplayRosterEquipment)
        roster.heroes = {"A_1001_5": {"tl": [0, 0, 0, 0, 99]}}
        target = "A_1001_5|0"
        hero = {"aid": target, "lv": 99, "limit_break": 0, "phase": 2, "exp": 777}
        profile = {"avatars": {target: hero}, "pending_limit_break": {
            "fight_id": "fight-1", "candidate_ids": [target], "created": 1}}
        self.assertEqual(roster._hero_level_cap("A_1001_5", hero), 99)
        with self.assertRaises(GameplayFault):
            roster._mutate(profile, "user.avatar_limit_break", {"aid": "A_1001_5|other"})
        self.assertIn("pending_limit_break", profile)
        result = roster._mutate(profile, "user.avatar_limit_break", {"aid": target})
        self.assertTrue(result["ok"])
        self.assertEqual(roster._hero_level_cap("A_1001_5", hero), 125)
        self.assertEqual((hero["phase"], hero["exp"]), (2, 777))
        self.assertNotIn("pending_limit_break", profile)
        with self.assertRaises(GameplayFault):
            roster._mutate(profile, "user.avatar_limit_break", {"aid": target})

    def test_real_config_break_feed_combat_and_phase_remain_independent(self):
        root = Path(__file__).resolve().parents[1]
        config = apply_vip_campaign(json.loads(
            (root / "config/reconstruction/full-config.json").read_text(encoding="utf-8")))
        db = sqlite3.connect(":memory:", check_same_thread=False)
        store = PlayerStore(db, config)
        uid = store.login("vip-limit-integration")["uid"]
        roster = next(handler for handler in store.gameplay_handlers
                      if isinstance(handler, GameplayRosterEquipment))
        target = "A_1001_5|limit"
        materials = [f"A_1022_6|feed{i}" for i in range(3)]
        phase_material = "A_1001_5|phase"
        def seed(profile):
            template = {"lv": 99, "slv": 1, "exp": 0, "hp": 0, "ap": 0,
                        "de_ph": 0, "de_ma": 0, "morph": 0, "equips": []}
            profile["avatars"][target] = {**template, "id": target, "aid": target,
                                          "phase": 3, "limit_break": 0}
            for iid in materials:
                profile["avatars"][iid] = {**template, "id": iid, "aid": iid,
                                            "phase": 0, "limit_break": 0}
            profile["avatars"][phase_material] = {**template, "id": phase_material,
                                                   "aid": phase_material, "phase": 0,
                                                   "limit_break": 0}
            profile["gold"] = 10_000_000
            profile["pending_limit_break"] = {"fight_id": "f-limit",
                                               "candidate_ids": [target], "created": 1}
            return profile, {}
        store.atomic_update(uid, seed)
        before = roster.battle_attributes(store.profile_raw(uid), target)
        self.assertEqual(roster.dispatch(uid, "user.avatar_limit_break",
                                         {"aid": target, "actionID": "break-real"})["ok"], True)
        broken = store.profile_raw(uid)["avatars"][target]
        self.assertEqual((broken["phase"], broken["limit_break"], broken["lv"]), (3, 1, 99))
        roster.dispatch(uid, "user.swallow_avatar",
                        {"aid": target, "aids": materials, "actionID": "feed-real"})
        grown = store.profile_raw(uid)["avatars"][target]
        self.assertEqual((grown["lv"], grown["phase"], grown["limit_break"]), (125, 3, 1))
        after = roster.battle_attributes(store.profile_raw(uid), target)
        self.assertGreater(after["hp"], before["hp"])
        self.assertGreater(after["ap"], before["ap"])

        # Phase ascension is a separate path; reaching 125 neither grants nor
        # blocks it. Reset phase only for this independent RPC boundary check.
        def unphase(profile):
            profile["avatars"][target]["phase"] = 0
            return profile, {}
        store.atomic_update(uid, unphase)
        roster.dispatch(uid, "user.phase_up",
                        {"aid": target, "aids": [phase_material], "actionID": "phase-real"})
        phased = store.profile_raw(uid)["avatars"][target]
        self.assertEqual((phased["lv"], phased["phase"], phased["limit_break"]), (125, 1, 1))
        db.close()


if __name__ == "__main__":
    unittest.main()
