import json
from pathlib import Path
import unittest
from unittest.mock import patch

from gateway import load_game_config
from hero_balance_iteration_104 import PLAN, apply_hero_balance_iteration_104
from native_skill_snapshot import _native_skill_snapshot
from skill_balance_overlay import _get
from skill_rank_growth_104 import hero_skill_references

ROOT=Path(__file__).resolve().parents[1]


class NewYearAnnieTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        plan=json.loads(PLAN.read_text('utf8'))
        plan.get('final_skill_multipliers',{}).pop('A_1221',None)
        with patch('hero_balance_iteration_104.apply_hero_balance_iteration_104',lambda d:apply_hero_balance_iteration_104(d,plan)):
            cls.before=load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']
        cls.cfg=load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']

    def test_all_quality_and_bond_equipment_curves_increase_ten_percent(self):
        selected=hero_skill_references(self.cfg,{'A_1221'})
        self.assertGreater(len(selected),10)
        for sid in selected:
            for lv in range(1,11):
                old=_native_skill_snapshot(self.before,sid,lv)['skills']
                new=_native_skill_snapshot(self.cfg,sid,lv)['skills']
                for index,path,*_ in self.cfg['skill'][sid]['rankGrowth104']['magnitudes']:
                    self.assertAlmostEqual(_get(new[index],path),_get(old[index],path)*1.1,places=8,msg=(sid,lv,path))
            self.assertEqual(self.cfg['skill'][sid]['pl'],self.before['skill'][sid]['pl'])
        for sid in hero_skill_references(self.cfg):
            if sid not in selected:
                self.assertEqual(self.cfg['skill'][sid],self.before['skill'][sid],sid)
        for aid in ('A_1221_5','A_1221_6','A_1029_5','A_1029_6'):
            self.assertEqual(self.cfg['avatar'][aid]['pl'][:10],self.before['avatar'][aid]['pl'][:10])

    def test_orange_bear_binding_in_all_captain_variants(self):
        self.assertEqual(self.cfg['avatar']['A_2020_6']['res'],'A_2020_6')
        self.assertEqual(self.cfg['avatar']['A_2020_6']['modUnitType'],'summon')
        for sid,slot in hero_skill_references(self.cfg,{'A_1221'}).items():
            if slot==11:
                self.assertEqual(self.cfg['skill'][sid]['skin_v2_summon_id'],'A_2020_6',sid)
        for aid in ('A_1029_5','A_1029_6'):
            skill=self.cfg['skill'][self.cfg['avatar'][aid]['pl'][11]]
            self.assertEqual(skill['manualSummonPolicy']['unitId'],'A_2002_5')

    def test_native_cast_orange_bear_reuse_and_resummon(self):
        from test_hero_strength_native_bridge import NativeBridgeTests
        fixture=NativeBridgeTests()
        fixture.cfg=self.cfg
        battle=fixture.battle(1221)
        owner=battle.a[0]
        def cast():
            self.assertTrue(battle._apply_native_skill(owner,battle.b,'leader_skill'))
            return battle.state(owner)['summons_skin2bear'][0]
        pet=cast()
        self.assertEqual(pet['aid'],'A_2020_6')
        self.assertIsNone(pet['skill'])
        self.assertIsNone(pet['leader_skill'])
        self.assertIsNone(pet['skillB'])
        self.assertAlmostEqual(pet['hp_max'],int(owner['hp_max']*.77))
        self.assertIs(cast(),pet)
        pet['hp']=0
        new=cast()
        self.assertIsNot(new,pet)
        self.assertEqual(new['aid'],'A_2020_6')


if __name__=='__main__':unittest.main()
