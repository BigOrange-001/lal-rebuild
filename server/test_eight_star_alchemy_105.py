"""Production eight-star alchemy: real transactions, multipliers and terminal cap."""
import copy
import json
import sqlite3
import unittest
from pathlib import Path
from gameplay_roster import GameplayRosterEquipment
from player_store import PlayerStore,GameplayFault

ROOT = Path(__file__).resolve().parents[1]


class FixedRandom:
    def random(self):
        return 0


class EightStarAlchemyTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = json.loads((ROOT/'config/reconstruction/full-config.json').read_text('utf8'))

    def setUp(self):
        self.db = sqlite3.connect(':memory:',check_same_thread=False)
        self.addCleanup(self.db.close)
        self.store = PlayerStore(self.db,self.config)
        self.uid = self.store.login('eight-star-alchemy')['uid']
        self.roster = GameplayRosterEquipment(self.store,self.config)

    def seed(self,items,vip=0):
        def mutate(p):
            p['my_equips'] = copy.deepcopy(items)
            p['as_equips'] = [[] for _ in range(6)]
            p['vip_lv'] = vip
            return p,{}
        self.store.atomic_update(self.uid,mutate)

    def alchemy(self,target,material,action):
        return self.roster.dispatch(self.uid,'user.equip_alchemy',{'eqids':[target,material],'actionID':action})

    def test_shipping_and_generation_configs_open_eight_with_exact_terminal_entry(self):
        for simple in [self.config['cfg']['system_simple'],json.loads((ROOT/'config/reconstruction/roster-config.json').read_text('utf8'))['system_simple']]:
            table = simple['equip_alchemy']
            self.assertEqual(table['star_lv'],8)
            self.assertIn('8_0',table['phase'])
            self.assertNotIn('8_1',table['phase'])
            self.assertNotIn('8_2',table['phase'])
        self.assertEqual(self.config['cfg']['system_simple']['equip_alchemy']['phase']['8_0'],[1.12,1,1.0])

    def test_six_star_reaches_eight_through_only_normal_material_transactions(self):
        # Four six-star copies make each seven-star item. Four seven-star
        # items make an eight-star item, with no VIP bonus or seeded upgrades.
        self.seed({f'eq{i}':{'eid':'E_1011_6','lv':1,'alchemy':[0,0]} for i in range(16)})
        for group in range(4):
            target = f'eq{group*4}'
            for index in range(1,4):
                self.alchemy(target,f'eq{group*4+index}',f'six-{group}-{index}')
            self.assertEqual(self.store.profile_raw(self.uid)['my_equips'][target]['alchemy'],[0,1])
        for index,material in enumerate(['eq4','eq8','eq12'],1):
            before = self.store.profile_raw(self.uid)['my_equips']['eq0']
            rate = self.roster._equip_alchemy_rate(before,0)
            result = self.alchemy('eq0',material,f'seven-{index}')
            after = self.store.profile_raw(self.uid)['my_equips']['eq0']
            self.assertAlmostEqual(self.roster._equip_alchemy_rate(after,0)/rate,1.12)
            self.assertEqual(after['alchemy'],[index,1] if index<3 else [0,2])
            # Replaying a confirmed request cannot consume another material.
            snapshot = self.store.profile_raw(self.uid)
            self.assertEqual(self.alchemy('eq0',material,f'seven-{index}'),result)
            self.assertEqual(self.store.profile_raw(self.uid),snapshot)
        self.assertEqual(list(self.store.profile_raw(self.uid)['my_equips']),['eq0'])
        self.assertAlmostEqual(self.roster._equip_alchemy_rate(after,0),1.12**6)
        self.store.login('eight-star-alchemy')
        self.assertEqual(self.store.profile_raw(self.uid)['my_equips']['eq0']['alchemy'],[0,2])

    def test_every_equipment_family_reaches_eight_and_terminal_rejects_without_consumption(self):
        # All original qualities, exclusive items and skill books share this
        # transaction. Materials need the same EID and star, not the same +step.
        for eid,row in self.config['cfg']['equip'].items():
            if int(row['type']) not in [1,3,4,5,6]:
                continue
            with self.subTest(eid=eid):
                extra = 7-int(eid.rsplit('_',1)[1])
                self.seed({'target':{'eid':eid,'lv':1,'alchemy':[2,extra]},
                           'material':{'eid':eid,'lv':1,'alchemy':[0,extra]},
                           'terminal_material':{'eid':eid,'lv':1,'alchemy':[0,extra+1]}})
                self.alchemy('target','material',f'last-{eid}')
                p = self.store.profile_raw(self.uid)
                self.assertEqual(p['my_equips']['target']['alchemy'],[0,extra+1])
                self.assertEqual(self.roster._equip_star(p['my_equips']['target']),8)
                with self.assertRaises(GameplayFault) as caught:
                    self.alchemy('target','terminal_material',f'blocked-{eid}')
                self.assertEqual(caught.exception.code,'MaxGrowth')
                self.assertEqual(self.store.profile_raw(self.uid),p)

    def test_vip_bonus_stops_at_eight_without_creating_plus_steps(self):
        self.roster.rng = FixedRandom()
        for phase in [1,2]:
            with self.subTest(phase=phase):
                self.seed({'target':{'eid':'E_1011_6','lv':1,'alchemy':[phase,1]},
                           'material':{'eid':'E_1011_6','lv':1,'alchemy':[0,1]}},vip=15)
                receipt = self.alchemy('target','material',f'vip-{phase}')
                p = self.store.profile_raw(self.uid)
                self.assertEqual(p['my_equips']['target']['alchemy'],[0,2])
                self.assertEqual(receipt['alchemy_bonus_step'],1 if phase==1 else 0)


if __name__=='__main__':
    unittest.main()
