"""Daily quota, price and retry boundaries for native energy purchases."""
import datetime
import sqlite3
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0,str(Path(__file__).resolve().parent))
from player_store import PlayerStore,GameplayFault
from gameplay_economy import GameplayEconomy
from gameplay_energy import normalize_energy_purchase_day


class EnergyPurchaseTest(unittest.TestCase):
    def setUp(self):
        self.database=sqlite3.connect(':memory:',check_same_thread=False)
        self.config={'cfg':{'system_simple':{'energy_config':[100,0,5,130,50,10,0,10,0]},'vip':{str(level):{'buy_energy':level*2,'energy_limit_add':0} for level in range(16)}}}
        self.store=PlayerStore(self.database,self.config)
        self.uid=self.store.login('energy-check')['uid']
        self.economy=GameplayEconomy(self.store,self.config)

    def tearDown(self):
        self.database.close()

    def empty_meter(self, vip=0):
        def mutate(profile):
            profile['coin']=100_000
            profile['vip_lv']=vip
            profile['energy']={'$date':self.economy._now()}
            profile['attrs']['energy_extra']=0
            return profile,{}
        self.store.atomic_update(self.uid,mutate)

    def test_prices_quota_and_replay(self):
        self.empty_meter()
        first=self.economy.full_energy(self.uid,{'actionID':'first'})
        self.assertEqual((first['coin'],first['energy_times']),(99_950,1))
        self.assertTrue(self.economy.full_energy(self.uid,{'actionID':'first'})['replayed'])
        for index in range(1,10):
            self.empty_meter()
            receipt=self.economy.full_energy(self.uid,{'actionID':f'purchase-{index}'})
            self.assertEqual((receipt['coin'],receipt['energy_times']),(100_000-(50+10*index),index+1))
        self.empty_meter()
        before=self.store.profile_raw(self.uid)
        with self.assertRaises(GameplayFault) as error:
            self.economy.full_energy(self.uid,{'actionID':'over-limit'})
        self.assertEqual(error.exception.code,'EnergyPurchaseLimit')
        self.assertEqual(before,self.store.profile_raw(self.uid))

    def test_vip15_has_forty_purchases(self):
        self.empty_meter(15)
        def near_limit(profile):
            profile['records']['energy_times']=39
            return profile,{}
        self.store.atomic_update(self.uid,near_limit)
        receipt=self.economy.full_energy(self.uid,{'actionID':'vip-last'})
        self.assertEqual((receipt['coin'],receipt['energy_times']),(99_560,40))
        self.empty_meter(15)
        with self.assertRaises(GameplayFault) as error:
            self.economy.full_energy(self.uid,{'actionID':'vip-over'})
        self.assertEqual(error.exception.code,'EnergyPurchaseLimit')

    def test_shanghai_midnight_and_legacy_count(self):
        before=datetime.datetime(2026,10,13,15,59,59,tzinfo=datetime.timezone.utc).timestamp()
        profile={'records':{'energy_times':7}}
        self.assertEqual(normalize_energy_purchase_day(profile,before),7)
        self.assertEqual(profile['records']['energy_purchase_day'],'2026-10-13')
        self.assertEqual(normalize_energy_purchase_day(profile,before+1),0)
        self.assertEqual(profile['records']['energy_purchase_day'],'2026-10-14')


if __name__=='__main__':
    unittest.main()
