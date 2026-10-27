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

if __name__=='__main__':unittest.main()
