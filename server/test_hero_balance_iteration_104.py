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


class MechanismTextTests(unittest.TestCase):
    """Live six-star descriptions state the actions each skill really has."""
    @classmethod
    def setUpClass(cls):
        cls.cfg=load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']

    def row(self,aid,slot):
        return self.cfg['skill'][self.cfg['avatar'][aid]['pl'][slot]]

    def tokens(self,row,prefix):
        import re
        line=next(l for l in row['rankInfoTemplate'].split('\n') if l.startswith(prefix))
        return [row['skill'][int(i)][0] for i in re.findall(r'\{rank:(\d+):',line)]

    def test_no_design_notes_and_tokens_name_the_added_actions(self):
        old=('怒气积累','万魂领域','圣诞预热','虚空压制','虚空追击','寒冰护援','粽香援护','舞步防护','净化援助','手里剑直击')
        for aid,hero in self.cfg['avatar'].items():
            if not aid.endswith('_6'):continue
            for slot in (10,11,13):
                sid=hero['pl'][slot] if len(hero['pl'])>slot else None
                if sid not in self.cfg['skill']:continue
                for field in ('info','rankInfoTemplate'):
                    text=self.cfg['skill'][sid].get(field,'')
                    for note in old:self.assertNotIn(note,text,(aid,sid,field))
                self.assertNotRegex(self.cfg['skill'][sid].get('info',''),r'\{(rank|flat):',(aid,sid))
        self.assertEqual(self.tokens(self.row('A_1028_6',10),'每次施放命中敌人后'),['battle_stack'])
        self.assertEqual(self.tokens(self.row('A_1217_6',10),'每次施放另外获得'),['battle_stack_unconditional'])
        self.assertEqual(self.tokens(self.row('A_1103_6',10),'同时对本路最前方'),['damage'])
        self.assertEqual(self.tokens(self.row('A_1134_6',10),'随后突进至本路'),['damage'])
        self.assertEqual(self.tokens(self.row('A_1049_6',10),'为全队生命比例最低'),['target_hp_shield'])
        self.assertEqual(self.tokens(self.row('A_1212_6',11),'全队生命比例最低'),['target_hp_shield'])
        # Garen's normal is shared by two variant pairs, so both additions apply.
        self.assertEqual(self.tokens(self.row('A_1001_6',10),'为全队生命比例最低'),['cure','cure'])
        self.assertIn('施法者攻击力＋10%最大生命值', self.row('A_1001_6',10)['info'])

    def test_captains_without_added_effects_have_no_line_and_retargets_are_named(self):
        for aid in ('A_1028_6','A_1049_6','A_1074_6','A_1134_6','A_1217_6','A_1001_6'):
            self.assertNotIn('\n',self.row(aid,11)['rankInfoTemplate'].strip(),aid)
        amumu=self.row('A_1074_6',11)['info']
        self.assertIn('本路所有敌人',amumu)
        self.assertNotIn('400范围',amumu)
        self.assertNotIn('最多4名',amumu)
        self.assertIn('范围内生命比例最低的友军恢复生命',self.row('A_1212_6',11)['info'])
        self.assertIn('施放时净化自身。',self.row('A_1210_6',11)['info'])

    def test_erlang_skills_state_numbers(self):
        for slot in (10,11,13):
            self.assertRegex(self.row('A_1226_6',slot)['info'],r'\d')
            self.assertIn('{',self.row('A_1226_6',slot)['rankInfoTemplate'])


if __name__=='__main__':unittest.main()
