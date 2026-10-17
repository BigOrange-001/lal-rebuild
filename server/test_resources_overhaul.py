"""Focused resource-stage and shop acquisition checks."""
import copy
import json
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from activity_tower_overlay import (RESOURCE_AMOUNTS, RESOURCE_POWER,
                                    SKILL_BISCUIT_AMOUNTS, apply_resource_overhaul)
from gameplay_common import equipment_exclusive_ids, grant_reward
from gameplay_economy import GameplayEconomy
from player_store import GameplayFault, PlayerStore


class ResourceOverhaulTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source = json.loads((Path(__file__).resolve().parents[1] /
                             "config/reconstruction/full-config.json").read_text(encoding="utf-8"))
        cls.original = source
        source = copy.deepcopy(source)
        source["cfg"]["system_simple"].setdefault("skill_biscuit_avatar_id", "A_6992_4")
        cls.biscuit_id = source["cfg"]["system_simple"]["skill_biscuit_avatar_id"]
        cls.config, cls.report = apply_resource_overhaul(source)

    def test_five_tiers_and_unlimited_biscuit_stage(self):
        pve = self.config["pve"]
        self.assertEqual(pve["battle_ploy"]["P_101"]["combat"], 5)
        self.assertEqual(pve["battle_ploy"]["P_109"]["combat"], 4)
        self.assertEqual(pve["battle_ploy"]["P_200"]["combat"], 150)
        self.assertEqual(pve["battle_ploy"]["P_200"]["name"], "灵魂之塔")
        self.assertEqual(self.config["cfg"]["pass_battle_gift"]["-1"]["P_200"]["need_star"], 450)
        self.assertEqual(self.config["pass_battle_gift"], self.config["cfg"]["pass_battle_gift"])
        self.assertEqual((self.report["chapters"], self.report["stages"]), (11, 204))
        self.assertEqual(pve["combat_ploy"]["P_200_100"]["team2"],
                         self.original["pve"]["combat_ploy"]["P_200_100"]["team2"])
        orange = {aid for aid in self.config["cfg"]["avatar"]
                  if aid.startswith("A_1") and aid.endswith("_6")}
        self.assertEqual(set(pve["combat_ploy"]["P_200_101"]["tower_hero_candidates"]), orange)
        self.assertEqual(pve["combat_ploy"]["P_200_150"]["tower_hero_amount"], 1)
        self.assertTrue(pve["combat_ploy"]["P_200_150"]["tower_allow_skin"])
        for floor in range(1, 151):
            cid = f"P_200_{floor}"
            self.assertEqual(pve["combat_ploy"][cid]["win"], [-2])
            self.assertEqual(self.config["cfg"]["combat_ploy"][cid]["win"], [-2])
            target = round(10000 * (10000000000 / 10000) ** ((floor - 1) / 149))
            actual = pve["combat_ploy"][f"P_200_{floor}"]["recommended_power"]
            self.assertLessEqual(abs(actual - target), max(10, target * .001))
        for index, kind in enumerate(RESOURCE_AMOUNTS, 101):
            for tier, amount in enumerate(RESOURCE_AMOUNTS[kind], 1):
                stage = pve["combat_ploy"][f"P_{index}_{tier}"]
                self.assertEqual(stage["material_kind"], kind)
                self.assertEqual(stage["material_tier"], tier)
                self.assertLess(abs(stage["recommended_power"] - RESOURCE_POWER[tier - 1]),
                                RESOURCE_POWER[tier - 1] * .01)
                if tier == 5:
                    self.assertEqual(stage["team2"][0][1], 125)
                    self.assertEqual(stage["team2"][0][14], 3)
                    self.assertTrue(all(row[0].endswith("_6") for row in stage["team2"]))
                reward = stage["reward"]
                actual = (reward["heroes"][0]["num"] if kind == "hero_exp" else
                          reward["gold"] if kind == "gold" else
                          reward["attrs"]["dust"][min(tier - 1, 3)] if kind == "dust" else
                          reward["mark"] if kind == "mark" else
                          reward["items"][0]["num"] if kind == "enchant_book" else
                          reward["attrs"]["culture_book"] if kind == "culture_book" else
                          sum(reward["attrs"]["sp"]) if kind == "talent" else
                          reward["attrs"]["dn_stone"])
                # The published third talent tier splits 18 by integer
                # division across four colors, for an actual total of 16.
                self.assertEqual(actual, 16 if kind == "talent" and tier == 3 else amount)
        for tier, amount in enumerate(SKILL_BISCUIT_AMOUNTS, 1):
            stage = pve["combat_ploy"][f"P_109_{tier}"]
            self.assertEqual(stage["reward"]["heroes"], [{"aid": self.biscuit_id, "num": amount}])
            self.assertTrue(stage["unlimited_attempts"])
            self.assertEqual(stage["material_kind"], "skill_biscuit")

    def test_orange_offers_and_exclusive_purchase_gate(self):
        cfg = self.config["cfg"]
        exclusive_ids = equipment_exclusive_ids(cfg)
        offers = cfg["mystery_shop_offers"]["normal"]
        ordinary = next(row for row in offers if "equip" in row[0]
                        and next(iter(row[0]["equip"])) .endswith("_6")
                        and next(iter(row[0]["equip"])) not in exclusive_ids)
        exclusive = next(row for row in offers if "equip" in row[0]
                         and next(iter(row[0]["equip"])) in exclusive_ids)
        self.assertEqual(ordinary[1], {"coin": 5000})
        self.assertEqual(exclusive[1], {"coin": 8000})
        eid = next(iter(exclusive[0]["equip"]))
        db = sqlite3.connect(":memory:", check_same_thread=False)
        self.addCleanup(db.close)
        store = PlayerStore(db, self.config)
        uid = store.login("exclusive-shop-test")["uid"]
        shop = GameplayEconomy(store, self.config)
        with self.assertRaises(GameplayFault) as denied:
            grant_reward(store.profile_raw(uid), {"equip": {eid: 1}}, self.config)
        self.assertEqual(denied.exception.code, "ExclusiveEquipmentRestricted")

        def stock(profile, row):
            profile["coin"] = 20000
            profile.setdefault("attrs", {}).setdefault("mystery_shop", {})["normal"] = {
                "t": 123456789, "items": [copy.deepcopy(row)], "b": [], "refresh_seq": 0}
            return profile, {}
        store.atomic_update(uid, lambda p: stock(p, exclusive))
        bought = shop.mystery_shop_buy(uid, {"s_type": "normal", "index": 0,
                                             "time": 123456789, "actionID": "exclusive-buy"})
        self.assertEqual(bought["coin"], 12000)
        self.assertTrue(any(item["eid"] == eid for item in store.profile_raw(uid)["my_equips"].values()))
        self.assertTrue(shop.mystery_shop_buy(uid, {"s_type": "normal", "index": 0,
                                                    "time": 123456789,
                                                    "actionID": "exclusive-buy"})["replayed"])

        forged = [{"equip": {eid: 1}}, {"coin": 1}]
        store.atomic_update(uid, lambda p: stock(p, forged))
        with self.assertRaises(GameplayFault) as denied:
            shop.mystery_shop_buy(uid, {"s_type": "normal", "index": 0,
                                        "time": 123456789, "actionID": "forged-buy"})
        self.assertEqual(denied.exception.code, "ExclusiveEquipmentRestricted")
        self.assertEqual(store.profile_raw(uid)["coin"], 20000)
        shop._now = lambda: 2_000_000_000
        first = shop.mystery_shop_refresh_by_coin(uid, {"s_type": "normal", "actionID": "refresh-1"})
        second = shop.mystery_shop_refresh_by_coin(uid, {"s_type": "normal", "actionID": "refresh-2"})
        self.assertEqual(second["t"], first["t"] + 1)
        self.assertEqual(second["coin"], 19800)


if __name__ == "__main__":
    unittest.main()
