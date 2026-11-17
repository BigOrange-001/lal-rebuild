"""Daily exchange retries and save-local acquisition policy."""
import copy
import datetime
import sqlite3
import unittest
from pathlib import Path

from daily_exchange_105 import daily_integral_offers
from gameplay_economy import GameplayEconomy
from gateway import load_game_config
from mod_policy import ensure_reward
from player_store import GameplayFault, PlayerStore
from recruit_exchange import daily_orange_pool


class Clock:
    def __init__(self):
        self.value = int(datetime.datetime.fromisoformat("2026-11-17T23:59:00+08:00").timestamp())

    def now(self):
        return self.value


class DailyExchangeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = load_game_config(Path(__file__).resolve().parents[1] /
                                      "config/reconstruction/full-config.json", now=Clock().now())

    def setUp(self):
        self.clock = Clock()
        self.db = sqlite3.connect(":memory:", check_same_thread=False)
        self.addCleanup(self.db.close)
        self.store = PlayerStore(self.db, self.config, clock=self.clock)
        self.uid = self.store.login("daily-exchange-regression")["uid"]
        self.store.atomic_update(self.uid, lambda p: (dict(p, attrs={**p["attrs"],
            "lottery_activity": {"score": 10000}, "avatar_len": 100}), {}))
        self.economy = GameplayEconomy(self.store, self.config)

    def test_successful_exchange_replays_after_midnight_without_spending_again(self):
        for supplied_day in (True, False):
            with self.subTest(supplied_day=supplied_day):
                day, _ = daily_integral_offers(self.config, self.clock.now())
                params = {"index": 0, "actionID": f"cross-midnight-{supplied_day}"}
                if supplied_day:
                    params["day"] = day
                first = self.economy.exchange_activity_avatar(self.uid, params)
                profile = self.store.profile_raw(self.uid)
                self.clock.value += 86400
                replay = self.economy.exchange_activity_avatar(self.uid, params)
                self.assertTrue(replay["replayed"])
                self.assertEqual(replay["avatar"], first["avatar"])
                self.assertEqual(replay["score"], first["score"])
                self.assertEqual(self.store.profile_raw(self.uid), profile)

    def test_new_purchase_from_yesterdays_list_is_rejected_atomically(self):
        day, _ = daily_integral_offers(self.config, self.clock.now())
        self.clock.value += 86400
        before = self.store.profile_raw(self.uid)
        with self.assertRaises(GameplayFault) as caught:
            self.economy.exchange_activity_avatar(self.uid, {"index": 0, "day": day, "actionID": "stale-new"})
        self.assertEqual(caught.exception.code, "DailyExchangeExpired")
        self.assertEqual(self.store.profile_raw(self.uid), before)

    def test_activity_policy_filters_skins_and_accepts_two_eligible_ordinary_cards(self):
        config = copy.deepcopy(self.config)
        ordinary = daily_orange_pool(config)
        keep = set(ordinary[:2])
        skins = config["cfg"]["ploy_system_simple"]["extract_avatar"]["permanent_exchange_hero_ids"]
        channel = "acquisition.exchange.activity"
        heroes = {aid: {"channels": {channel: aid in keep, "acquisition.exchange.hero": False}}
                  for aid in ordinary}
        heroes[skins[0]] = {"channels": {channel: False}}
        config["cfg"]["mod_runtime"] = {"digest": "daily-exchange-policy", "heroes": heroes,
                                         "missingHeroIds": [skins[1]]}
        _, rows = daily_integral_offers(config, self.clock.now())
        self.assertEqual(len(rows), 8)
        selected = {next(iter(row[0]["avatar"])) for row in rows}
        self.assertFalse(selected & set(skins[:2]))
        self.assertEqual({next(iter(row[0]["avatar"])) for row in rows if row[1] == 200}, keep)
        for reward, _ in rows:
            ensure_reward(config, reward, channel)
