"""1.0.5 shop balance: recharge tiers, mystery tiers, lottery, VIP packs and pity."""
import sqlite3
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))

from gateway import load_game_config
from gameplay_economy import GameplayEconomy, PACKS
from gameplay_roster import GameplayRosterEquipment
from player_store import GameplayFault, PlayerStore
from shop_balance_105 import (ADVANCED_ORANGE_PITY, GAMBLE_LADDER, RECHARGE_TIERS, VIP_DAILY_PACKS,
                              daily_limit)
from vip_campaign import VIP_THRESHOLDS

CONFIG_PATH = Path(__file__).resolve().parents[1] / "config/reconstruction/full-config.json"


class FakeClock:
    def __init__(self, now):
        self.value = now

    def now(self):
        return self.value


class ShopBalanceTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.doc = load_game_config(CONFIG_PATH)
        cls.cfg = cls.doc["cfg"]

    def setUp(self):
        self.db = sqlite3.connect(":memory:", check_same_thread=False)
        self.addCleanup(self.db.close)
        self.clock = FakeClock(1_800_000_000)
        self.store = PlayerStore(self.db, self.doc, clock=self.clock)
        self.uid = self.store.login("shop-balance")["uid"]
        self.eco = GameplayEconomy(self.store, self.doc)

    def _set(self, **fields):
        def change(profile):
            if "vip" in fields:
                profile.setdefault("attrs", {})["vip_gift_total_coin"] = VIP_THRESHOLDS[fields["vip"]]
                profile["vip_lv"] = fields["vip"]
            if "coin" in fields:
                profile["coin"] = fields["coin"]
            return profile, {}
        self.store.atomic_update(self.uid, change)

    def test_recharge_tiers_2000_5000_10000_yuan(self):
        for coin in RECHARGE_TIERS:
            self.assertEqual(PACKS[f"local_{coin}"], coin)
            self.assertEqual(self.cfg["pay_config"][f"local_{coin}"][0], coin // 10)
        order = [row[2] for row in self.cfg["pay_config"].values()]
        self.assertEqual(sorted(order), list(range(len(order))))
        self.eco.set_spending_tier(self.uid, {"spending_tier": "protagonist", "actionID": "tier"})
        before = self.store.profile_raw(self.uid)["coin"]
        result = self.eco.local_pay_test(self.uid, {"pid": "local_100000", "order_id": "big-1"})
        self.assertEqual(result["base_coin"], 100000)
        self.assertGreaterEqual(self.store.profile_raw(self.uid)["coin"] - before, 100000)

    def test_mystery_tiers_have_distinct_mixes(self):
        def kinds(tier):
            return {(next(iter(row[0])), next(iter(next(iter(row[0].values())))).rsplit("_", 1)[1])
                    for row in self.cfg["mystery_shop_offers"][tier]}
        self.assertNotIn(("avatar", "6"), kinds("normal"))
        self.assertIn(("avatar", "6"), kinds("super"))
        self.assertIn(("avatar_soul", "5"), kinds("normal"))
        for tier, rows in self.cfg["mystery_shop_offers"].items():
            self.assertEqual(len(rows), len(self.cfg["mystery_shop_weights"][tier]))
        sheet = self.eco.mystery_shop_info(self.uid, {"s_type": "super"})
        self.assertEqual(len(sheet["items"]), 6)
        self.assertEqual(len({str(row) for row in sheet["items"]}), 6)

    def test_lottery_now_pays_back(self):
        ploy = self.cfg["ploy_system_simple"]
        self.assertEqual(ploy["gamble"]["return_coin"], GAMBLE_LADDER)
        self.assertTrue(all(payout > cost for cost, payout in GAMBLE_LADDER[1:]))
        coins = [row.get("coin", 0) for row in ploy["roulette"]["pool"]]
        self.assertGreater(sum(coins) / len(coins), ploy["roulette"]["coin"] * .6)

    def test_vip_daily_packs_limits_lock_and_reset(self):
        self._set(vip=7, coin=50_000)
        listed = self.eco.vip_daily_packs(self.uid, {})
        rows = {row["id"]: row for row in listed["packs"]}
        self.assertTrue(rows["supreme"]["locked"])
        self.assertEqual(rows["culture"]["limit"], daily_limit(VIP_DAILY_PACKS[0], 7))
        with self.assertRaises(GameplayFault):
            self.eco.vip_daily_pack_buy(self.uid, {"pack_id": "supreme", "actionID": "s1"})
        bought = self.eco.vip_daily_pack_buy(self.uid, {"pack_id": "equipment", "actionID": "e1"})
        self.assertEqual(len(bought["granted"]["equip"]), 1)
        self.assertNotIn("random_orange_equip", bought["granted"])
        with self.assertRaises(GameplayFault) as limit:
            self.eco.vip_daily_pack_buy(self.uid, {"pack_id": "equipment", "actionID": "e2"})
        self.assertEqual(limit.exception.code, "DailyLimit")
        self.clock.value += 86_400
        again = {row["id"]: row for row in self.eco.vip_daily_packs(self.uid, {})["packs"]}
        self.assertEqual(again["equipment"]["left"], again["equipment"]["limit"])
        culture = self.store.profile_raw(self.uid)["attrs"].get("culture_book", 0)
        self.eco.vip_daily_pack_buy(self.uid, {"pack_id": "culture", "actionID": "c1"})
        self.assertEqual(self.store.profile_raw(self.uid)["attrs"]["culture_book"], culture + 1500)

    def test_vip_one_time_packs_for_every_level(self):
        for level in range(1, 16):
            row = self.cfg["vip"][str(level)]
            self.assertTrue(row["gift_buy"]["data"])
            self.assertEqual(row["gift_coin_buy"]["pay"][1], 600 * level)
        self._set(vip=5, coin=10_000)
        heroes = len(self.store.profile_raw(self.uid)["avatars"])
        self.eco.vip_gift_buy(self.uid, {"vip_lv": 5, "type": 1, "actionID": "v5"})
        profile = self.store.profile_raw(self.uid)
        self.assertEqual(profile["coin"], 10_000 - 3000)
        self.assertEqual(len(profile["avatars"]), heroes + 1)
        with self.assertRaises(GameplayFault):
            self.eco.vip_gift_buy(self.uid, {"vip_lv": 5, "type": 1, "actionID": "v5-again"})

    def test_advanced_summon_orange_pity(self):
        roster = GameplayRosterEquipment(self.store, self.doc)
        self._set(coin=1_000_000)
        purple = next(aid for aid in roster.heroes if aid.startswith("A_1") and aid.endswith("_5"))
        with patch.object(type(roster.summon_pools), "draw", return_value=purple):
            got = []
            for index in range(ADVANCED_ORANGE_PITY):
                result = roster.dispatch(self.uid, "user.wager_avatar",
                                         {"wager_type": "coin", "times": 1, "actionID": f"w{index}"})
                got.append(result)
        profile = self.store.profile_raw(self.uid)
        oranges = [hero for hero in profile["avatars"].values() if hero["aid"].split("|")[0].endswith("_6")]
        self.assertTrue(oranges)
        self.assertEqual(profile["records"]["advanced_orange_pity"], 0)


if __name__ == "__main__":
    unittest.main()
