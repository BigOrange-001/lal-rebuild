import copy
import unittest

import test_roguelite_abyss as helpers
from battle_engine import base_unit
from native_skill_snapshot import _native_skill_snapshot
from roguelite_abyss import (hero_record, standard_team, rules, is_skin, normalize_account,
                            generate_enemy_preview, generate_enemies, preview_from_units)


class SkinBalanceTests(unittest.TestCase):
    setUpClass=classmethod(helpers.AbyssTests.setUpClass.__func__)
    setUp=helpers.AbyssTests.setUp
    call=helpers.AbyssTests.call
    start=helpers.AbyssTests.start
    enter=helpers.AbyssTests.enter
    combat=helpers.AbyssTests.combat

    def test_all_skin_forms_both_sides_scaled_once_and_normal_unchanged(self):
        original=copy.deepcopy(self.cfg)
        rules(original)['skin_stat_multiplier']=1
        aids=[a for a in self.cfg['avatar'] if a.rsplit('_',1)[0] in rules(self.cfg)['skin_families']]
        self.assertIn('A_1140_6',aids)
        for team in (1,2):
            for aid in aids+['A_1001_5','A_1002_6']:
                heroes={'a':hero_record(aid,cfg=self.cfg),'b':hero_record('A_1003_5'),'c':hero_record('A_1004_5')}
                formation=[['a',0,.2],['b',1,.2],['c',2,.2]]
                before=standard_team(original,heroes,formation,team)[0]
                after=standard_team(self.cfg,heroes,formation,team)[0]
                for key in ('hp','ap','de_ph','de_ma'):
                    expected=max(1,int(before[key]*.66)) if is_skin(aid,self.cfg) else before[key]
                    self.assertEqual(after[key],expected,(aid,team,key))
                self.assertEqual(after['hp'],after['hp_max'])
                self.assertEqual(after['slv'],3 if is_skin(aid,self.cfg) else 5)
        self.assertEqual(base_unit(original,'A_1140_6',99)['ap'],base_unit(self.cfg,'A_1140_6',99)['ap'],
                         'normal game modes retain their original card panel')

    def test_existing_run_migrates_levels_and_choices_but_keeps_pending_battle(self):
        self.start()
        p=self.store.profile_raw(self.uid);run=p['abyss_run']
        run['pool']={a:hero_record(a) for a in ('A_1140_6','A_1221_5','A_1001_5')}
        run['pool']['A_1140_6']['slv']=10
        run['pool']['A_1001_5']['slv']=10
        run['pending_choice']={'options':[hero_record('A_1801_6')]}
        run['battle']={'orgin_team_a':[{'aid':'A_1140_6','slv':10,'ap':999}],'fight_id':'frozen'}
        frozen=copy.deepcopy(run['battle'])
        normalize_account(p,self.cfg)
        self.assertEqual([h['slv'] for h in run['pool'].values()],[6,3,10])
        self.assertEqual(run['pending_choice']['options'][0]['slv'],3)
        self.assertEqual(run['battle'],frozen)
        again=copy.deepcopy(p);normalize_account(p,self.cfg)
        self.assertEqual(p,again,'normalization is idempotent')

    def test_skin_rest_three_to_six_and_enemy_fixed_three(self):
        self.start()
        def prepare(p):
            run=p['abyss_run'];rest=next(n for n in run['map'] if n['type']=='rest')
            run['current_node']=rest['id'];run['available_nodes']=[]
            run['pool']['A_1140']=hero_record('A_1140_6',cfg=self.cfg)
            return p,{}
        self.store.atomic_update(self.uid,prepare)
        run=self.call('rest',hero_id='A_1140',option='skill')['abyss_run']
        self.assertEqual(run['pool']['A_1140']['slv'],6)
        heroes={a:hero_record(a,cfg=self.cfg) for a in ('A_1140_6','A_1001_5','A_1002_5')}
        heroes['A_1140_6']['slv']=6
        formation=[[a,i%3,.2] for i,a in enumerate(heroes)]
        own=standard_team(self.cfg,heroes,formation)[0]
        enemy=standard_team(self.cfg,heroes,formation,team=2)[0]
        self.assertEqual(own['slv'],6);self.assertEqual(enemy['slv'],3)
        sid=self.cfg['avatar']['A_1140_6']['pl'][10]
        self.assertEqual(own['skill'],_native_skill_snapshot(self.cfg,sid,6))
        self.assertEqual(enemy['skill'],_native_skill_snapshot(self.cfg,sid,3))

    def test_enemy_preview_and_fight_match_skin_three_ordinary_five(self):
        for difficulty in (1,10):
            node={'id':'3-8-0','act':3,'type':'boss','layer':8}
            node['enemy_preview']=generate_enemy_preview(20261117,difficulty,node,self.cfg)
            units=generate_enemies(20261117,difficulty,node,self.cfg)
            self.assertEqual(node['enemy_preview'],preview_from_units(units,self.cfg))
            self.assertTrue(any(is_skin(u['aid'],self.cfg) for u in units))
            self.assertTrue(all(u['slv']==(3 if is_skin(u['aid'],self.cfg) else 5) for u in units))


if __name__=='__main__':unittest.main()
