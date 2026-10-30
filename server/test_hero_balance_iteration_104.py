import copy
import json
from pathlib import Path
import unittest
from unittest.mock import patch
from gateway import load_game_config
from hero_balance_iteration_104 import apply_hero_balance_iteration_104,SCHEMA
from hero_strength_instrumentation import MeasuredBattle
from test_manual_ability_sim import unit

ROOT=Path(__file__).resolve().parents[1]


class IterationBalanceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with patch('hero_balance_iteration_104.apply_hero_balance_iteration_104',lambda d:d), patch('skill_rank_growth_104.apply_skill_rank_growth_104',lambda d:d):
            cls.base=load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']

    def plan(self,entries,skin_factor=1):
        return dict(schema=SCHEMA,enabled=True,round=1,skin_panel_factor=skin_factor,
                    heroes={family:dict(panel_factor=values[0],skill_factor=values[1],mechanism=values[2]) for family,values in entries.items()})

    def test_numeric_scope_identity_quality_and_idempotence(self):
        cfg=copy.deepcopy(self.base);before=copy.deepcopy(cfg)
        p=self.plan({'A_1021':(.85,.6,False)})
        apply_hero_balance_iteration_104(cfg,p)
        for aid,h in cfg['avatar'].items():
            if aid.startswith('A_1021_'):
                self.assertEqual(h['pl'][8:],before['avatar'][aid]['pl'][8:])
                for x,y in zip(h['pl'][:8],before['avatar'][aid]['pl'][:8]):self.assertAlmostEqual(x,y*.85)
            else:self.assertEqual(h,before['avatar'][aid])
        frozen=copy.deepcopy(cfg);apply_hero_balance_iteration_104(cfg,p);self.assertEqual(cfg,frozen)

    def test_mechanism_rework_adds_actual_actions_and_preserves_originals(self):
        cfg=copy.deepcopy(self.base);aid='A_1033_6';sid=cfg['avatar'][aid]['pl'][10]
        original=copy.deepcopy(cfg['skill'][sid]['skill'])
        apply_hero_balance_iteration_104(cfg,self.plan({'A_1033':(1,1,True)}))
        self.assertEqual(cfg['skill'][sid]['skill'][:-1],original)
        self.assertEqual(cfg['skill'][sid]['skill'][-1][:3],['recast_on_kill',3,1])
        self.assertIn('balance_mechanism_104',cfg['skill'][sid])

    def test_skin_group_multiplier_leaves_ordinary_and_skills_unchanged(self):
        cfg=copy.deepcopy(self.base);before=copy.deepcopy(cfg)
        apply_hero_balance_iteration_104(cfg,self.plan({'A_1001':(1,1,False),'A_1210':(1,1,False)},1.12))
        self.assertEqual(cfg['avatar']['A_1001_6'],before['avatar']['A_1001_6'])
        for x,y in zip(cfg['avatar']['A_1210_6']['pl'][:8],before['avatar']['A_1210_6']['pl'][:8]):self.assertAlmostEqual(x,1.12*y)
        self.assertEqual(cfg['skill'][cfg['avatar']['A_1210_6']['pl'][10]]['skill'],before['skill'][before['avatar']['A_1210_6']['pl'][10]]['skill'])

    def test_support_shield_uses_action_policy_and_only_lowest_hp_ally(self):
        b=MeasuredBattle([unit('A_1049_6',1,1800),unit('A_1001_6',1,1900),unit('A_1002_6',1,2000)],
                          [unit('A_1003_6',2,1600)],config={})
        owner,weak,other=b.a;weak['hp']=1000
        skill=dict(skid='test',pl=[0,0,1500,0,0,1],
                   actionTargetPolicies=['enemy_lane_frontmost','ally_all_lowest_hp_ratio'],
                   actionTargetPolicyArgs=[None,{'effectRange':9999,'heroOnly':True}],actionTargetMaxTargets=[1,1])
        b._act_target_hp_shield(owner,b.b,b.a,skill,['target_hp_shield',.08,2,'FX'],1,{})
        self.assertIsNone(b._buff(owner,'shield'));self.assertIsNone(b._buff(other,'shield'))
        self.assertEqual(b._buff(weak,'shield').value,800)

    def test_half_draw_aggregation_differs_from_outright_wins(self):
        import tempfile
        from run_hero_strength_104 import blank,aggregate
        with tempfile.TemporaryDirectory() as temp:
            p=Path(temp);(p/'battles').mkdir();r=blank();r.update(games=10,wins=4,draws=2,losses=4,seats=[1]*10)
            (p/'battles/test.summary.json').write_text(json.dumps(dict(mode='ordinary',start=0,stop=1,battles=1,seconds=0,rows={'A_1001_6':r},casts={},rounds={})),encoding='utf8')
            result=aggregate(p,[dict(aid='A_1001_6',name='test',category='ordinary')],1)['rows'][0]
            self.assertEqual(result['win_rate'],.5);self.assertEqual(result['outright_win_rate'],.4)


if __name__=='__main__':unittest.main()
