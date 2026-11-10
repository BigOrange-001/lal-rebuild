"""The immortal benchmark must preserve finite percent-HP and uncapped damage."""
import unittest
from unittest.mock import patch

from benchmark_training_dummy_104 import TrainingBattle,DUMMY,max_snapshot,ROOT
from hero_strength_native_bridge import NativeSkinBattle
from test_combat_redesign import config,unit
from gateway import load_game_config
from cultivation_rules import cap,used


class FixedRandom:
    calls=0
    def get_random(self,n=100):self.calls+=1;return n-1


class DummyTests(unittest.TestCase):
    def battle(self):
        cfg=config();cfg['system_simple']['attack'][4:8]=[0,0,0,0]
        cfg['avatar']={a:dict(name=a,tl=[0,1,1],pl=[0]*14) for a in ('A_1001_6',DUMMY)}
        a=unit(1,skill=None,leader_skill=None,skillB=None,book_skill=None,skill_diff=0)
        d=unit(2,aid=DUMMY,hp=1000,hp_max=1000,de_ph=0,de_ma=0,ap=0,
               skill=None,leader_skill=None,skillB=None,book_skill=None,skill_diff=0)
        b=TrainingBattle([a],[d],max_rounds=100,config=cfg);b.rng=FixedRandom()
        return b,b.a[0],b.b[0]

    def test_damage_larger_than_reference_hp_is_not_clipped(self):
        b,a,d=self.battle()
        dealt=b._native_damage(a,d,100,1)
        self.assertEqual(dealt,100000)
        self.assertEqual(b.statistics[(1,a['_owner_token'])]['damage'],100000)
        self.assertEqual((d['hp'],d['hp_max']),(1000,1000))

    def test_percent_damage_uses_finite_reference_after_repeated_refills(self):
        b,a,d=self.battle()
        for _ in range(4):b._injured(d,d['hp_max']*.05,6,source=a,dot_kind='poison')
        self.assertEqual(b.damage_channels['dot'],200)
        self.assertEqual((d['hp'],d['hp_max']),(1000,1000))

    def test_events_receive_real_damage_full_hp_and_no_false_kills(self):
        b,a,d=self.battle();events=[]
        def capture(self,owner,event,source=None,target=None,amount=0,overheal=0):
            if target is d:events.append((event,amount,d['hp'],d['hp_max']))
        with patch.object(NativeSkinBattle,'_emit_mod_event',capture):b._native_damage(a,d,100,1)
        self.assertIn(('damage_dealt',100000,1000,1000),events)
        self.assertFalse(any(r[0] in ('kill','death') for r in events))

    def test_exactly_one_hundred_basic_attack_turns(self):
        b,a,d=self.battle();r=b.run()
        self.assertEqual(r['rounds'],100)
        self.assertEqual(b.cast_counts['basic'],100)
        self.assertEqual(sum(b.damage_channels.values()),100000)
        self.assertEqual(d['hp'],1000)

    def test_passive_book_does_not_suppress_basic_attacks(self):
        b,a,d=self.battle()
        a['book_skill']=dict(skid='PASSIVE',pl=None,skills=[['book_passive',.3,'ap']])
        r=b.run()
        self.assertEqual(r['rounds'],100)
        self.assertEqual(b.cast_counts['basic'],100)
        self.assertEqual(b.cast_counts['book'],0)
        self.assertEqual(sum(b.damage_channels.values()),100000)

    def test_active_book_retains_its_cast_cycle(self):
        b,a,d=self.battle()
        a['book_skill']=dict(skid='ACTIVE',pl=[0,1,1000,0,0,1],skills=[['damage',1,1]])
        b.run()
        self.assertEqual(b.cast_counts['book'],50)
        self.assertEqual(b.cast_counts['basic'],50)
        self.assertEqual(sum(b.damage_channels.values()),100000)


class SnapshotTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):cls.cfg=load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']

    def test_actual_max_progression_and_requested_equipment_counts(self):
        for eq,defensive,count in ((False,False,0),(True,False,4),(True,True,6)):
            u,p=max_snapshot(self.cfg,'A_1001_6',eq,defensive)
            h=next(iter(p['avatars'].values()))
            self.assertEqual(u['lv'],125);self.assertEqual(u['phase'],3);self.assertEqual(u['slv'],10)
            self.assertEqual(used(h,self.cfg['system_simple']),cap(h,self.cfg['system_simple']))
            self.assertEqual(len(p['my_equips']),count)
            if eq:
                for item in p['my_equips'].values():
                    if self.cfg['equip'][item['eid']]['type']!=6:
                        self.assertEqual(item['lv'],170);self.assertEqual(item['alchemy'],[0,1])
                self.assertAlmostEqual(u['book_skill']['skills'][0][1],.3)


if __name__=='__main__':unittest.main()
