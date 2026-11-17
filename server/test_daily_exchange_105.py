"""Daily exchange retries and save-local acquisition policy."""
import copy
import datetime
import sqlite3
import unittest
from unittest.mock import patch
from pathlib import Path

from daily_exchange_105 import daily_integral_offers, daily_medal_hero_offers
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

    def test_medal_heroes_split_purchase_and_midnight_replay(self):
        day, heroes=daily_medal_hero_offers(self.config,self.clock.now())
        skin_ids=set(self.config['cfg']['ploy_system_simple']['extract_avatar']['permanent_exchange_hero_ids'])
        self.assertEqual(len(heroes),10)
        self.assertEqual(len({h['id'] for h in heroes}),10)
        self.assertEqual(sum(h['id'] in skin_ids for h in heroes),2)
        self.assertTrue(all(h['id'].endswith('_6') for h in heroes))
        self.assertEqual((day,heroes),daily_medal_hero_offers(self.config,self.clock.now()))
        self.store.atomic_update(self.uid,lambda p:(dict(p,medal=1000),{}))
        info=self.economy.recruit_exchange_info(self.uid,{})
        self.assertEqual(sum(i['kind']=='equip' for i in info['items']),20)
        self.assertEqual(sum(i['kind']=='avatar' for i in info['items']),10)
        for index,item in enumerate((heroes[0],heroes[-1])):
            params={'id':item['id'],'day':day,'actionID':f'hero-medal-{index}'}
            result=self.economy.recruit_medal_exchange(self.uid,params)
            self.assertEqual(result['kind'],'avatar')
            self.assertEqual(len(result['avatar']),1)
            self.assertTrue(next(iter(result['avatar'].values()))['aid'].startswith(item['id']+'|'))
        profile=self.store.profile_raw(self.uid)
        self.clock.value+=86400
        self.assertTrue(self.economy.recruit_medal_exchange(self.uid,params)['replayed'])
        self.assertEqual(profile,self.store.profile_raw(self.uid))
        with self.assertRaises(GameplayFault):
            self.economy.recruit_medal_exchange(self.uid,{**params,'actionID':'new-stale-purchase'})
        self.assertNotEqual(heroes,daily_medal_hero_offers(self.config,self.clock.now())[1])

    def test_reduced_mod_hero_pool_keeps_equipment_available(self):
        config = copy.deepcopy(self.config)
        ordinary = daily_orange_pool(config)
        skins = config['cfg']['ploy_system_simple']['extract_avatar']['permanent_exchange_hero_ids']
        channel = 'acquisition.exchange.hero'
        all_heroes = set(ordinary) | set(skins)
        for keep in (set(), {ordinary[0], skins[0]}):
            with self.subTest(keep=keep):
                config['cfg']['mod_runtime'] = {'digest':'reduced-medal-pool', 'heroes':{
                    aid:{'channels':{channel:aid in keep}} for aid in all_heroes}}
                economy = GameplayEconomy(self.store, config)
                info = economy.recruit_exchange_info(self.uid, {})
                heroes = [row for row in info['items'] if row['kind']=='avatar']
                equips = [row for row in info['items'] if row['kind']=='equip']
                self.assertEqual({row['id'] for row in heroes}, keep)
                self.assertEqual(len(equips), 20)
                self.store.atomic_update(self.uid, lambda p:(dict(p,medal=1000),{}))
                with patch('daily_exchange_105.daily_medal_hero_offers', side_effect=AssertionError('equipment must not query heroes')):
                    result = economy.recruit_medal_exchange(self.uid, {'id':equips[0]['id'],
                        'day':info['day'], 'actionID':'equipment-'+str(len(keep))})
                self.assertEqual(result['kind'], 'equip')
                self.assertEqual(self.store.profile_raw(self.uid)['medal'], 1000-equips[0]['medal'])
                before = self.store.profile_raw(self.uid)
                with self.assertRaises(GameplayFault):
                    economy.recruit_medal_exchange(self.uid, {'id':ordinary[1], 'day':info['day'],
                        'actionID':'disabled-'+str(len(keep))})
                self.assertEqual(self.store.profile_raw(self.uid), before)

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
