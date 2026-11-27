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

    def test_mechanism_and_erlang_text_bind_live_values(self):
        document={'cfg':{'skill':{
            'm':{'info':'造成20%伤害。\n本场攻击提高{rank:1:2}。','rankInfoTemplate':'造成20%伤害。\n本场攻击提高{rank:1:2}。',
                 'balance_mechanism_104':'x','skill':[['damage',.2,1],['battle_stack','attack',.035,6]]},
            'e':{'name':'五雷轰顶','info':'每回合发射五道天雷，对当前生命值最低的敌方英雄造成魔法伤害；准备与冷却均为0回合。',
                 'skill':[['locked_sequence',5,.521,.521,.521,.521,.521,2,0,'FX']]},
            'd':{'name':'唤犬令','info':'召唤灵兽协同作战。','skill':[['summon',1.0,'A_2024_6',4,'FX']]}}}}
        apply_player_copy_104(document)
        skills=document['cfg']['skill']
        self.assertEqual(skills['m']['info'],'造成20%伤害。\n本场攻击提高3.5%。')
        self.assertIn('{rank:1:2}',skills['m']['rankInfoTemplate'])
        self.assertIn('{rank:0:2}',skills['e']['rankInfoTemplate'])
        self.assertEqual(skills['e']['info'],'每回合发射五道天雷，对全场当前生命值最低的敌方英雄连续造成5次52.1%魔法伤害，目标阵亡后停止。')
        self.assertEqual(skills['d']['info'],'召唤哮天犬协同作战，存在4次自身行动。')
        once=copy.deepcopy(document);apply_player_copy_104(document)
        self.assertEqual(document,once)

    def test_skill_upgrade_chance_shows_one_percent_sign(self):
        # The client fills 90401 with 2004 ("@0%"), which already adds the sign.
        document={'cfg':{'return_msg_config':{'2004':'@0%','90401':'技能升级概率：@0%'}}}
        apply_player_copy_104(document)
        messages=document['cfg']['return_msg_config']
        rate=messages['2004'].replace('@0','35')
        self.assertEqual(messages['90401'].replace('@0',rate),'技能升级概率：35%')
        self.assertEqual(messages['90401'].replace('@0','--'),'技能升级概率：--')

    def test_display_names_for_stages_resources_and_unknown_units(self):
        stages={'M_010_5':{'name':'第10章·还没排好的火力'},'M_001_1':{'name':'第1章·散落的工事'}}
        ploy={'P_1':{'name':'英雄经验·难度3'},'P_2':{'name':'远古试炼·第4档'},'P_3':{'name':'灵魂塔·第12层'}}
        document={'cfg':{'combat_main':stages,'combat_ploy':ploy,
                         'avatar':{'A_1907_4':{'name':'蓝阶英雄·序号907'},'A_1001_2':{'name':'盖伦'}}},
                  'pve':{'combat_main':copy.deepcopy(stages)}}
        apply_player_copy_104(document)
        cfg=document['cfg']
        self.assertEqual(cfg['combat_main']['M_010_5']['name'],'第10章·荆棘花园')
        self.assertEqual(cfg['combat_main']['M_001_1']['name'],'第1章·黑默丁格炮台')
        self.assertEqual(document['pve']['combat_main']['M_010_5']['name'],'第10章·荆棘花园')
        self.assertEqual([cfg['combat_ploy'][k]['name'] for k in ('P_1','P_2','P_3')],
                         ['英雄经验副本·高级','远古试炼·第4关','灵魂塔·第12层'])
        self.assertEqual(cfg['avatar']['A_1907_4']['name'],'正义执剑者')
        self.assertEqual(cfg['avatar']['A_1001_2']['name'],'盖伦')

    def test_chapter_names_cover_every_battle_main_copy(self):
        chapters={'M_001':{'name':'前哨失联'},'M_030':{'name':'终幕中庭'}}
        document={'cfg':{'battle_main':copy.deepcopy(chapters)},'pve':{'battle_main':copy.deepcopy(chapters)},
                  'battle_main':copy.deepcopy(chapters)}
        apply_player_copy_104(document)
        for holder in (document['cfg'],document['pve'],document):
            self.assertEqual(holder['battle_main']['M_001']['name'],'泉水出发')
            self.assertEqual(holder['battle_main']['M_030']['name'],'王者之巅')

    def test_campaign_title_tables_are_complete_and_tidy(self):
        from player_copy_104 import STAGE_TITLES_104, CHAPTER_TITLES_104
        expected=[f'M_{c:03d}_{s}' for c in range(1,31) for s in range(1,(6 if c<=15 else 3)+1)]
        self.assertEqual(sorted(STAGE_TITLES_104),expected)
        self.assertEqual(sorted(CHAPTER_TITLES_104),[f'M_{c:03d}' for c in range(1,31)])
        titles=list(STAGE_TITLES_104.values())
        self.assertEqual(len(set(titles)),len(titles))
        self.assertEqual(len(set(CHAPTER_TITLES_104.values())),30)
        for title in titles:
            self.assertTrue(4<=len(title)<=7,title)
            for word in ('封锁','封口','封门','近卫','最后的'):
                self.assertNotIn(word,title)

    def test_talent_and_bond_text_use_planner_copy(self):
        from copy_polish_104 import polish_text
        self.assertEqual(polish_text('自身总面板攻击提高3%'),'自身攻击力提高3%。')
        self.assertEqual(polish_text('对本分路3名敌人造成480.0%攻击物伤；为友军赋予施法者40%最大生命护盾2回合；'),
                         '对本路3名敌人造成480%物理伤害；为友军赋予施法者相当于40%最大生命的护盾2回合。')
        once=polish_text('装备·回旋护步：小技能回收刀刃时获得35%攻击护盾，持续1回合。')
        self.assertEqual(once,'【装备·回旋护步】小技能回收刀刃时获得相当于35%攻击力的护盾，持续1回合。')
        self.assertEqual(polish_text(once),once)

if __name__=='__main__':unittest.main()
