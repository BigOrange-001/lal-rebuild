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
from gameplay_energy import normalize_energy_purchase_day,energy_state,write_energy_after_spend,apply_energy_purchase_103


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

    def test_purchase_message_uses_shared_native_localization_channel(self):
        apply_energy_purchase_103(self.config)
        message=self.config['cfg']['msg']['90002']
        self.assertIn('增加当前体力上限',message)
        self.assertIn('500',message)
        self.assertTrue(all(token in message for token in ('@0','@1','@2')))

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

    def seed_energy(self,current,maximum=130,extra=0):
        self.config['cfg']['system_simple']['energy_config'][0]=maximum
        def mutate(p):
            p['coin']=100000;p['energy']={'$date':self.economy._now()-min(current,maximum)*300}
            p['attrs']['energy_extra']=max(0,current-maximum)+extra
            return p,{}
        self.store.atomic_update(self.uid,mutate)

    def test_purchase_adds_full_cap_above_natural_max_and_replays_once(self):
        self.seed_energy(50)
        first=self.economy.full_energy(self.uid,{'actionID':'overflow'})
        p=self.store.profile_raw(self.uid)
        self.assertEqual(energy_state(p,self.config,self.economy._now())['current'],180)
        self.assertEqual(first['attr_energy_extra'],50)
        self.assertTrue(self.economy.full_energy(self.uid,{'actionID':'overflow'})['replayed'])
        self.assertEqual(p,self.store.profile_raw(self.uid))
        self.economy.full_energy(self.uid,{'actionID':'overflow2'})
        p=self.store.profile_raw(self.uid);state=energy_state(p,self.config,self.economy._now())
        self.assertEqual(state['current'],310)
        write_energy_after_spend(p,300,state,self.economy._now())
        self.assertEqual(energy_state(p,self.config,self.economy._now())['current'],300)
        self.assertEqual(energy_state(p,self.config,self.economy._now()+3600)['current'],300)

    def test_storage_exactly_five_hundred_allowed_overflow_rejected_atomically(self):
        self.seed_energy(370)
        self.economy.full_energy(self.uid,{'actionID':'exact500'})
        p=self.store.profile_raw(self.uid)
        self.assertEqual(energy_state(p,self.config,self.economy._now())['current'],500)
        for current in (371,500):
            self.seed_energy(current);before=self.store.profile_raw(self.uid)
            with self.assertRaises(GameplayFault) as error:
                self.economy.full_energy(self.uid,{'actionID':str(current)})
            self.assertEqual(error.exception.code,'EnergyStorageLimit')
            self.assertEqual(before,self.store.profile_raw(self.uid))

    def test_pending_reward_overflow_is_preserved_when_natural_meter_fills(self):
        self.seed_energy(50,extra=20)
        self.economy.full_energy(self.uid,{'actionID':'reserved'})
        self.assertEqual(energy_state(self.store.profile_raw(self.uid),self.config,self.economy._now())['current'],200)


if __name__=='__main__':
    unittest.main()
