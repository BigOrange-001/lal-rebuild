import collections
import unittest
from pathlib import Path
from gateway import load_game_config
from native_skill_snapshot import _native_skill_snapshot
from hero_strength_native_bridge import NativeSkinBattle
from run_hero_strength_104 import schedule, study_config
from test_manual_ability_sim import unit

ROOT=Path(__file__).resolve().parents[1]


class NativeBridgeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cfg=load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']

    def battle(self,family):
        aid=f'A_{family}_6';a=unit(aid,1,1800)
        for key,slot in [('skill',10),('leader_skill',11),('skillB',13)]:
            a[key]=_native_skill_snapshot(self.cfg,self.cfg['avatar'][aid]['pl'][slot],10 if slot==10 else 1)
        return NativeSkinBattle([a,unit('A_1001_6',1,1900)],
                                [unit('A_1002_6',2,1600),unit('A_1003_6',2,1500)],config=self.cfg)

    def test_every_revised_skin_slot_executes_through_real_method_body(self):
        from skin_revision_104 import PARAMS
        for family in PARAMS:
            for slot,key in [(0,'skill'),(1,'leader_skill')]:
                if family==1227 and slot==0:continue
                with self.subTest(family=family,slot=slot):
                    b=self.battle(family);owner=b.a[0]
                    if family==1219 and slot==1:
                        b.invoke(owner,'s2Mark',b.ref(b.b[0]),'airborne',1)
                    with b.context(owner,'active'):
                        self.assertTrue(b.execute(owner,f'skin2_{family}_{slot}',1,owner[key]))
                    self.assertFalse(b._js_contexts)

    def test_ekko_final_target_death_does_not_read_null(self):
        b=self.battle(1140);owner=b.a[0]
        b.b[1]['hp']=0;b.b[0]['hp']=1
        b.js.eval(f'unit({b.uid(owner)}).skin2.phase=true;unit({b.uid(owner)}).skin2.phaseValue=100')
        with b.context(owner,'active'):
            self.assertTrue(b.execute(owner,'skin2_1140_0',1,owner['skill']))
        self.assertEqual(b.b[0]['hp'],0)

    def test_native_rebirth_precedes_bless_and_is_not_counted_as_healing(self):
        b=self.battle(1216);bird=b.a[0];enemy=b.b[0]
        b._add_buff(bird,'bless',1)
        b._injured(bird,999999,1,source=enemy)
        self.assertEqual(bird['hp'],int(bird['hp_max']*.3))
        self.assertIsNotNone(b._buff(bird,'bless'))
        self.assertEqual(b.statistics[(1,bird['_owner_token'])]['healing'],0)
        self.assertTrue(b.turn_start(bird))
        self.assertFalse(b.turn_start(bird))
        self.assertEqual(bird['hp'],int(bird['hp_max']*.4))

    def test_effective_healing_aura_shield_and_attribution(self):
        b=self.battle(1228);owner,ally=b.a;enemy=b.b[0]
        ally['hp']=4000
        b.invoke(owner,'s2Heal',b.ref(ally),1)
        self.assertEqual(ally['hp'],5250)
        self.assertEqual(b.statistics[(1,owner['_owner_token'])]['healing'],1250)
        ally['hp']=ally['hp_max']
        b.invoke(owner,'s2Shield',b.ref(ally),2)
        with b.context(enemy,'active'):b._injured(ally,500,1,source=enemy)
        self.assertEqual(b.statistics[(1,ally['_owner_token'])]['taken'],425)
        self.assertEqual(b.statistics[(2,enemy['_owner_token'])]['damage'],425)

    def test_schedule_has_exact_sides_slots_and_no_duplicate_heroes(self):
        for size in (32,35,94,126,129):
            pool=[str(x) for x in range(size)]
            for cycle in (0,1,99,999):
                rows=schedule(pool,cycle,'mixed')
                self.assertEqual(len(rows),size)
                for row in rows:self.assertEqual(len(set(row)),10)
                for seat in range(10):self.assertEqual(collections.Counter(r[seat] for r in rows),collections.Counter(pool))

    def test_current_named_heroes_are_included_beyond_historical_roster(self):
        cfg,heroes,pools=study_config()
        for aid in ('A_1140_6','A_1139_6','A_1227_6','A_1311_6'):
            self.assertIn(aid,pools['skin'])
        self.assertFalse(set(pools['skin']) & set(pools['ordinary']))
        self.assertEqual(set(pools['mixed']),set(pools['skin'])|set(pools['ordinary']))
        self.assertNotIn('A_190001_5',pools['mixed'])
        self.assertTrue(all('序号' not in x['name'] for x in heroes))
        self.assertEqual({k:len(v) for k,v in pools.items()},{'mixed':125,'ordinary':90,'skin':35})
        self.assertFalse({'A_1903','A_1904','A_1905','A_1909'} & {aid.rsplit('_',1)[0] for aid in pools['mixed']})


if __name__=='__main__':unittest.main()
