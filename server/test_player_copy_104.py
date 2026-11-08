import copy
import unittest
from player_copy_104 import apply_player_copy_104, clean_player_text

class PlayerCopyTests(unittest.TestCase):
    def test_keeps_effects_tokens_and_combat_growth(self):
        text='中毒每次结算{rank:2:3}攻击并沿用原版附加规则。每次击杀获得5%攻击。眩晕按原生命中与闪避结算。'
        self.assertEqual(clean_player_text(text),'中毒每次结算{rank:2:3}攻击。每次击杀获得5%攻击。')
        self.assertEqual(clean_player_text('自身总面板攻击提高3%，作为独立乘区结算。'),'自身总面板攻击提高3%。')

    def test_cleanup_is_idempotent_and_leaves_rules_unchanged(self):
        document={'cfg':{'skill':{'x':{'info':'中毒沿用原版附加规则。造成40%伤害。',
                       'skill':[['damage',.4,2]],'pl':[0,2,600,0,1,0],
                       'rankInfoTemplate':'造成{rank:0:1}伤害。强化每级伤害+10%。'}},
                       'equip':{'e':{'description':'装备效果。该部分按技能等效收益的50%估值。'}},
                       'audit':{'info':'保留设计记录'}}}
        before=copy.deepcopy(document)
        apply_player_copy_104(document)
        self.assertEqual(document['cfg']['skill']['x']['skill'],before['cfg']['skill']['x']['skill'])
        self.assertEqual(document['cfg']['skill']['x']['pl'],before['cfg']['skill']['x']['pl'])
        self.assertEqual(document['cfg']['audit'],before['cfg']['audit'])
        once=copy.deepcopy(document);apply_player_copy_104(document)
        self.assertEqual(document,once)

    def test_display_names_for_stages_resources_and_unknown_units(self):
        stages={'M_010_5':{'name':'第10章·还没排好的火力'},'M_001_1':{'name':'第1章·散落的工事'}}
        ploy={'P_1':{'name':'英雄经验·难度3'},'P_2':{'name':'远古试炼·第4档'},'P_3':{'name':'灵魂塔·第12层'}}
        document={'cfg':{'combat_main':stages,'combat_ploy':ploy,
                         'avatar':{'A_1907_4':{'name':'蓝阶英雄·序号907'},'A_1001_2':{'name':'盖伦'}}},
                  'pve':{'combat_main':copy.deepcopy(stages)}}
        apply_player_copy_104(document)
        cfg=document['cfg']
        self.assertEqual(cfg['combat_main']['M_010_5']['name'],'第10章·仓促火线')
        self.assertEqual(cfg['combat_main']['M_001_1']['name'],'第1章·散落的工事')
        self.assertEqual(document['pve']['combat_main']['M_010_5']['name'],'第10章·仓促火线')
        self.assertEqual([cfg['combat_ploy'][k]['name'] for k in ('P_1','P_2','P_3')],
                         ['英雄经验副本·高级','远古试炼·第4关','灵魂塔·第12层'])
        self.assertEqual(cfg['avatar']['A_1907_4']['name'],'正义执剑者')
        self.assertEqual(cfg['avatar']['A_1001_2']['name'],'盖伦')

    def test_talent_and_bond_text_use_planner_copy(self):
        from copy_polish_104 import polish_text
        self.assertEqual(polish_text('自身总面板攻击提高3%'),'自身攻击力提高3%。')
        self.assertEqual(polish_text('对本分路3名敌人造成480.0%攻击物伤；为友军赋予施法者40%最大生命护盾2回合；'),
                         '对本路3名敌人造成480%物理伤害；为友军赋予施法者相当于40%最大生命的护盾2回合。')
        once=polish_text('装备·回旋护步：小技能回收刀刃时获得35%攻击护盾，持续1回合。')
        self.assertEqual(once,'【装备·回旋护步】小技能回收刀刃时获得相当于35%攻击力的护盾，持续1回合。')
        self.assertEqual(polish_text(once),once)

if __name__=='__main__':unittest.main()
