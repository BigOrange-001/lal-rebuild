"""VIP reward contents, mail migration, daily caps and retry boundaries."""
import unittest
from unittest.mock import patch

import test_shop_balance_105 as fixtures
from gameplay_common import equipment_exclusive_ids
from player_store import GameplayFault
from shop_balance_105 import VIP_PACK_PRICES, VIP_DAILY_COINS, daily_limit


class VipRewardsTests(unittest.TestCase):
    setUpClass=fixtures.ShopBalanceTest.__dict__['setUpClass']
    setUp=fixtures.ShopBalanceTest.setUp
    _set=fixtures.ShopBalanceTest._set

    def test_all_paid_contents_prices_and_exclusive_quality(self):
        skins=set(self.cfg['system_simple']['skin_hero_ids'])
        exclusive=equipment_exclusive_ids(self.cfg)
        for level in range(1,16):
            row=self.cfg['vip'][str(level)]
            reward=row['gift_coin_buy']['data']
            self.assertEqual(row['gift_coin_buy']['pay'][1],VIP_PACK_PRICES[level-1])
            self.assertEqual(row['gift'],[{'coin':VIP_DAILY_COINS[level-1]}])
            self.assertFalse(set(reward)-{'avatar','equip'})
            heroes=reward['avatar'];equipment=reward.get('equip',{})
            self.assertEqual(sum(heroes.values()),1 if level<=10 else 2 if level<15 else 5)
            self.assertEqual(sum(equipment.values()),0 if level<=5 else 1 if level<15 else 12)
            self.assertTrue(all(a.endswith('_6') for a in heroes))
            self.assertTrue(all(e.endswith('_6') for e in equipment))
            self.assertEqual(bool(set(heroes)&skins),level>=6)
            self.assertEqual(bool(set(equipment)&exclusive),level>=11)
        self._set(vip=15,coin=100000)
        before=self.store.profile_raw(self.uid)
        result=self.eco.vip_gift_buy(self.uid,{'vip_lv':15,'type':1,'actionID':'max-paid'})
        self.assertEqual(len(result['avatars'])-len(before['avatars']),5)
        self.assertEqual(len(result['my_equips'])-len(before['my_equips']),12)
        self.assertEqual(result['coin'],100000-88888)
        saved=self.store.profile_raw(self.uid)
        self.assertTrue(self.eco.vip_gift_buy(self.uid,{'vip_lv':15,'type':1,'actionID':'max-paid'})['replayed'])
        self.assertEqual(saved,self.store.profile_raw(self.uid))

    def test_free_mail_migration_claim_reconnect_and_deleted_mail_do_not_duplicate(self):
        def legacy(p):
            p['attrs']['vip_gift_buy']=[1]
            p['attrs']['vip_gift_total_coin']=300
            p['vip_lv']=3
            return p,{}
        self.store.atomic_update(self.uid,legacy)
        rows=self.db.execute('SELECT id,title FROM gift_mail WHERE uid=? ORDER BY id',(self.uid,)).fetchall()
        self.assertEqual([r[1] for r in rows],['VIP2等级奖励','VIP3等级奖励'])
        before=self.store.profile_raw(self.uid)['coin']
        self.store.claim(self.uid,str(rows[0][0]))
        self.assertEqual(self.store.profile_raw(self.uid)['coin'],before+200)
        self.store.claim(self.uid,str(rows[0][0]))
        self.assertEqual(self.store.profile_raw(self.uid)['coin'],before+200)
        self.store.login('shop-balance')
        self.assertEqual(self.db.execute('SELECT COUNT(*) FROM gift_mail WHERE uid=?',(self.uid,)).fetchone()[0],2)
        self.store.delete_mail(self.uid,{'mnum':str(rows[0][0])})
        self.store.atomic_update(self.uid,lambda p:(p,{}))
        self.assertEqual(self.db.execute('SELECT COUNT(*) FROM gift_mail WHERE uid=?',(self.uid,)).fetchone()[0],1)
        def fail(p):
            p['vip_lv']=5
            raise GameplayFault('test','rollback')
        with self.assertRaises(GameplayFault):self.store.atomic_update(self.uid,fail)
        self.assertEqual(self.db.execute('SELECT COUNT(*) FROM gift_mail WHERE uid=?',(self.uid,)).fetchone()[0],1)

    def test_daily_vip_one_claim_rollover_and_legacy_claim(self):
        self._set(vip=1)
        before=self.store.profile_raw(self.uid)
        params={'gnum':0,'actionID':'daily-one'}
        first=self.eco.vip_gift(self.uid,params)
        self.assertEqual(first['coin'],before['coin']+100)
        self.assertEqual(first['attrs']['culture_book'],before['attrs']['culture_book'])
        self._set(vip=3)
        with self.assertRaises(GameplayFault):self.eco.vip_gift(self.uid,{'gnum':0,'actionID':'same-day-new-vip'})
        self.clock.value+=86400
        self.assertTrue(self.eco.vip_gift(self.uid,params)['replayed'])
        self.assertEqual(self.eco.vip_gift(self.uid,{'gnum':0,'actionID':'tomorrow'})['coin'],first['coin']+450)

    def test_daily_contents_limits_and_exact_ten_percent_branch(self):
        packs={p['id']:p for p in self.cfg['system_simple']['vip_daily_packs_105']}
        self.assertEqual(set(packs),{'culture','dust','equipment','hero','stardust','supreme'})
        self.assertEqual((daily_limit(packs['culture'],1),daily_limit(packs['culture'],15)),(2,5))
        self.assertEqual((daily_limit(packs['equipment'],7),daily_limit(packs['equipment'],15)),(4,8))
        for name in ('dust','hero','stardust','supreme'):self.assertEqual(daily_limit(packs[name],15),2)
        self.assertEqual(packs['culture']['reward'],{'avatar':{'A_6998_5':50}})
        self.assertEqual(packs['dust']['reward'],{'attrs':{'dust':[400]*4}})
        self.assertEqual(packs['stardust']['reward'],{'attrs':{'stardust':1000}})
        skins=set(self.cfg['system_simple']['vip_daily_pack_pools_105']['skin_orange'])
        class Random:
            def __init__(self,n):self.n=n
            def randrange(self,limit):return self.n
            def choice(self,values):return values[0]
        outcomes=[]
        for value in range(10):
            with patch('gameplay_economy.random.SystemRandom',return_value=Random(value)):
                reward=self.eco._vip_pack_reward(packs['hero']['reward'])
            outcomes.append(next(iter(reward['avatar'])) in skins)
        self.assertEqual(sum(outcomes),1)
        self._set(vip=15,coin=100000)
        a=self.eco.vip_daily_pack_buy(self.uid,{'pack_id':'supreme','actionID':'supreme-1'})
        self.assertIn(next(iter(a['granted']['avatar'])),skins)
        self.assertEqual(a['coin'],70000)
        self.eco.vip_daily_pack_buy(self.uid,{'pack_id':'supreme','actionID':'supreme-2'})
        before=self.store.profile_raw(self.uid)
        with self.assertRaises(GameplayFault):self.eco.vip_daily_pack_buy(self.uid,{'pack_id':'supreme','actionID':'supreme-3'})
        self.assertEqual(before,self.store.profile_raw(self.uid))

    def test_paid_capacity_failure_keeps_wallet_and_inventory(self):
        self._set(vip=15,coin=100000)
        self.store.atomic_update(self.uid,lambda p:(dict(p,attrs={**p['attrs'],'avatar_len':len(p['avatars'])}),{}))
        before=self.store.profile_raw(self.uid)
        with self.assertRaises(GameplayFault):self.eco.vip_gift_buy(self.uid,{'vip_lv':15,'type':1,'actionID':'full'})
        self.assertEqual(before,self.store.profile_raw(self.uid))
