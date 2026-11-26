"""Layered purify and curse: each purify layer cancels one debuff, each curse
layer strips or blocks two good buffs, and neither counts down by rounds."""
import re
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from battle_engine import ReferenceBattle, curse_layers
from manual_ability_sim import SkillCompleteBattle
from purify_curse_text_106 import (CURSE_TERM, PURIFY_INFO, PURIFY_TERM,
                                   apply_purify_curse_text, rewrite)

ROOT = Path(__file__).resolve().parents[1]


def unit(aid, team, pos):
    return {'aid': aid, 'isme': team == 1, 'line': 0, 'pos': pos, 'hp': 1000,
            'hp_max': 1000, 'ap': 100, 'de_ph': 0, 'de_ma': 0,
            'tpl': [1, 0, 0, 200, 337], 'new_4attrs': {}, 'range': 337}


class PurifyLayerTests(unittest.TestCase):
    def setUp(self):
        self.battle = ReferenceBattle([unit('A_1001_6', 1, 500)],
                                      [unit('A_1002_6', 2, 600)], config={})
        self.target = self.battle.b[0]

    def layers(self):
        entry = self.target.get('_buffs', {}).get('purify')
        return int(entry.value) if entry else 0

    def test_layers_stack_without_limit_and_never_expire(self):
        for _ in range(7):
            self.battle._add_buff(self.target, 'purify', 1)
        self.assertEqual(self.layers(), 7)
        for _ in range(5):
            self.battle._settle_turn_buffs(self.target)
        self.assertEqual(self.layers(), 7)

    def test_each_layer_refuses_one_incoming_debuff(self):
        self.battle._add_buff(self.target, 'purify', 2)
        self.battle._add_buff(self.target, 'purify', 2)
        self.battle._add_buff(self.target, 'stun', 1)
        self.battle._add_buff(self.target, 'weak', 2, .3)
        self.assertEqual(set(self.target['_buffs']), set())
        self.battle._add_buff(self.target, 'silence', 1)
        self.assertIn('silence', self.target['_buffs'])

    def test_gaining_purify_cancels_only_the_earliest_debuff(self):
        self.battle._add_buff(self.target, 'weak', 2, .3)
        self.battle._add_buff(self.target, 'stun', 1)
        self.battle._add_buff(self.target, 'sunder', 2, .2)
        # A refreshed weak keeps its first acquisition stamp.
        self.battle._add_buff(self.target, 'weak', 3, .5)
        self.battle._add_buff(self.target, 'purify', 1)
        self.assertEqual(set(self.target['_buffs']), {'stun', 'sunder'})
        self.battle._add_buff(self.target, 'purify', 1)
        self.assertEqual(set(self.target['_buffs']), {'sunder'})

    def test_multi_layer_gain_spends_one_layer_per_debuff_and_keeps_the_rest(self):
        self.battle._add_buff(self.target, 'stun', 1)
        self.battle._add_buff(self.target, 'purify', 0, 3)
        self.assertNotIn('stun', self.target['_buffs'])
        self.assertEqual(self.layers(), 2)

    def test_hero_specific_debuffs_are_outside_purify(self):
        # Hero ability DOTs are neither cancelled on gain nor blocked.
        self.target['_manual_dots'] = {'bleed': {'kind': 'bleed'}}
        self.battle._add_buff(self.target, 'purify', 1)
        self.assertTrue(self.target['_manual_dots'])
        self.assertEqual(self.layers(), 1)
        self.assertTrue(self.battle._add_manual_skill_dot(
            self.target, 'poison', 'poison', 10, 0, 2, self.battle.a[0], 6, False))
        self.assertEqual(self.layers(), 1)

    def test_single_dispel_takes_one_layer_and_dispel_all_takes_every_layer(self):
        self.battle._add_buff(self.target, 'purify', 0, 3)
        self.battle._remove_buff(self.target, 'purify', consume=True)
        self.assertEqual(self.layers(), 2)
        self.battle._remove_all_good(self.target)
        self.assertEqual(self.layers(), 0)


class CurseLayerTests(unittest.TestCase):
    GOOD = ('shield', 'strong', 'taunt', 'bless', 'steel', 'armor',
            'hitup', 'fleeup', 'critup', 'toughup')

    def setUp(self):
        self.battle = ReferenceBattle([unit('A_1001_6', 1, 500)],
                                      [unit('A_1002_6', 2, 600)], config={})
        self.target = self.battle.b[0]

    def charges(self):
        entry = self.target.get('_buffs', {}).get('curse')
        return int(entry.value) if entry else 0

    def test_hero_specific_shields_are_outside_curse(self):
        from battle_engine import _Buff
        # An independent hero shield: type shield, but not a generic buff key.
        self.target.setdefault('_buffs', {})['yasuoShield104_1'] = _Buff('shield', 2, 100)
        self.battle._add_buff(self.target, 'strong', 2, .3)
        self.battle._add_buff(self.target, 'curse', 1)
        self.assertEqual(set(self.target['_buffs']), {'yasuoShield104_1', 'curse'})
        self.assertEqual(self.charges(), 1)

    def test_held_shields_are_never_stripped(self):
        self.battle._add_buff(self.target, 'shield', 2, 100)
        self.battle._add_buff(self.target, 'strong', 2, .3)
        self.battle._add_buff(self.target, 'curse', 1)
        self.assertEqual(set(self.target['_buffs']), {'shield', 'curse'})
        self.assertEqual(self.charges(), 1)
        # A new shield is still blocked by the remaining charge.
        self.battle._add_buff(self.target, 'shield', 2, 500)
        self.assertEqual(self.target['_buffs']['shield'].value, 100)
        self.assertEqual(self.charges(), 0)

    def test_a_layer_strips_the_two_earliest_good_buffs(self):
        self.battle._add_buff(self.target, 'strong', 2, .3)
        self.battle._add_buff(self.target, 'steel', 2, .3)
        self.battle._add_buff(self.target, 'hitup', 2, 100)
        self.battle._add_buff(self.target, 'curse', 1)
        self.assertEqual(set(self.target['_buffs']), {'hitup'})

    def test_unused_charges_block_the_next_good_buffs(self):
        self.battle._add_buff(self.target, 'strong', 2, .3)
        self.battle._add_buff(self.target, 'curse', 1)
        self.assertNotIn('strong', self.target['_buffs'])
        self.assertEqual(self.charges(), 1)
        self.battle._add_buff(self.target, 'shield', 2, 100)
        self.assertEqual(set(self.target['_buffs']), set())
        self.battle._add_buff(self.target, 'shield', 2, 100)
        self.assertIn('shield', self.target['_buffs'])

    def test_three_layers_block_six_good_buffs_at_most(self):
        for _ in range(5):
            self.battle._add_buff(self.target, 'curse', 1)
        self.assertEqual(self.charges(), 6)
        self.assertEqual(curse_layers(self.charges()), 3)
        for kind in self.GOOD[:6]:
            self.battle._add_buff(self.target, kind, 2, 100)
        self.assertEqual(set(self.target['_buffs']), set())
        self.battle._add_buff(self.target, self.GOOD[6], 2, 100)
        self.assertEqual(set(self.target['_buffs']), {self.GOOD[6]})

    def test_curse_never_expires_by_rounds(self):
        self.battle._add_buff(self.target, 'curse', 1)
        for _ in range(5):
            self.battle._settle_turn_buffs(self.target)
        self.assertEqual(self.charges(), 2)

    def test_purify_blocks_a_curse_and_a_purify_layer_removes_one_curse_layer(self):
        self.battle._add_buff(self.target, 'purify', 1)
        self.battle._add_buff(self.target, 'curse', 1)
        self.assertEqual(set(self.target['_buffs']), set())
        self.battle._add_buff(self.target, 'curse', 1)
        self.battle._add_buff(self.target, 'curse', 1)
        self.assertEqual(curse_layers(self.charges()), 2)
        self.battle._add_buff(self.target, 'purify', 1)
        self.assertEqual(curse_layers(self.charges()), 1)
        self.assertNotIn('purify', self.target['_buffs'])

    def test_purify_is_not_blocked_by_curse(self):
        self.battle._add_buff(self.target, 'curse', 1)
        self.battle._add_buff(self.target, 'purify', 0, 2)
        self.assertEqual(set(self.target['_buffs']), {'purify'})
        self.assertEqual(int(self.target['_buffs']['purify'].value), 1)


class ManualAbilityLayerTests(unittest.TestCase):
    def battle(self):
        a = [unit('A_1001_6', 1, 1800)]
        b = [unit('A_1002_6', 2, 1600)]
        cfg = {'avatar': {u['aid']: {'range': 337} for u in a + b},
               'skill': {'TEST': {}}, 'system_simple': {}}
        return SkillCompleteBattle(a, b, config=cfg)

    def test_purify_cancels_one_ordinary_or_relic_debuff_in_acquisition_order(self):
        from unittest.mock import patch
        from abyss_equip_passives import after_damage

        b = self.battle()
        owner, target = b.a[0], b.b[0]

        def apply_relic(kind):
            with patch('abyss_equip_passives.active_normal',
                       return_value={'affix': {'id': kind, 'value': .5}, 'hit': set()}):
                after_damage(b, owner, target, 100, 0, 1, None)

        b._add_buff(target, 'burn', 2, 10)
        apply_relic(10)
        b._add_buff(target, 'stun', 2)
        apply_relic(10)  # Refresh keeps the acquisition order.
        apply_relic(11)
        b.add_purify_charges(target, 1)
        self.assertIsNone(b._buff(target, 'burn'))
        self.assertEqual([dot['kind'] for dot in target['_relic_dots']], ['burn', 'poison'])
        b.add_purify_charges(target, 1)
        self.assertIsNotNone(b._buff(target, 'stun'))
        self.assertEqual([dot['kind'] for dot in target['_relic_dots']], ['poison'])
        b.add_purify_charges(target, 2)
        self.assertFalse(target['_relic_dots'])
        self.assertFalse(target['_buffs'])

    def test_curse_does_not_block_independent_shield_generation(self):
        from unittest.mock import patch
        from six_star_reaction_battle_105 import MF_SHIELD

        b = self.battle()
        owner, target = b.a[0], b.b[0]
        b._add_buff(owner, 'curse', 1)
        with patch.object(b, 'yasuo_passive', return_value=True):
            b.yasuo_event(owner, 'crit', owner, target, 10)
        b.six_next_stack_shield(owner, 'next_diana_shield', 100)
        owner['skillB'] = {'skills': [['manual_ability', 'six_reaction_mf_p', 0, 0, .5, .2, .1]]}
        b.six_reaction_mf_dealt(owner, target, 100)
        for shield in ('yasuoShield104_1', 'next_diana_shield', MF_SHIELD):
            self.assertGreater(b._buff(owner, shield).value, 0)
        self.assertEqual(b._buff(owner, 'curse').value, 2)

    def test_sivir_heals_when_purify_spends_its_last_layer(self):
        for existing_debuff in (True, False):
            with self.subTest(existing_debuff=existing_debuff):
                b = self.battle()
                owner = b.a[0]
                owner['hp'] = 500
                owner['skillB'] = {'skills': [['manual_ability', 'six_next_sivir_p', 0, 0, 0, .15]]}
                if existing_debuff:
                    b._add_buff(owner, 'weak', 2, .3)
                    b.add_purify_charges(owner, 1)
                else:
                    b.add_purify_charges(owner, 2)
                    b._add_buff(owner, 'weak', 2, .3)
                    self.assertEqual(owner['hp'], 500)
                    b._add_buff(owner, 'weak', 2, .3)
                self.assertEqual(owner['hp'], 650)
                self.assertIsNone(b._buff(owner, 'weak'))
                self.assertIsNone(b._buff(owner, 'purify'))

    def test_purify_charges_stack_with_ordinary_layers(self):
        b = self.battle()
        owner = b.a[0]
        b._add_buff(owner, 'stun', 1)
        b.add_purify_charges(owner, 2)
        self.assertNotIn('stun', owner['_buffs'])
        self.assertEqual(int(owner['_buffs']['purify'].value), 1)
        b.add_purify_charges(owner, 2)
        self.assertEqual(int(owner['_buffs']['purify'].value), 3)

    def test_skill_effect_factor_does_not_scale_layer_counts(self):
        b = self.battle()
        owner = b.a[0]
        with b.context(owner, 'active') as ctx:
            ctx['effect_factor'] = 1.7
            b._add_buff(owner, 'purify', 0, 2)
        self.assertEqual(owner['_buffs']['purify'].value, 2)

    def test_curse_hook_fires_even_when_the_layer_is_spent_at_once(self):
        b = self.battle()
        target = b.b[0]
        seen = []
        b.six_batch_curse = seen.append
        b._add_buff(target, 'strong', 2, .3)
        b._add_buff(target, 'steel', 2, .3)
        b._add_buff(target, 'curse', 1)
        self.assertEqual(seen, [target])
        self.assertNotIn('curse', target['_buffs'])


class PurifyCurseTextTests(unittest.TestCase):
    def test_timed_phrases_are_rewritten(self):
        cases = {
            '净化自身1回合。': '净化自身。',
            '自身获得2回合净化及2回合嘲讽': '自身获得净化及2回合嘲讽',
            '诅咒本路前排2回合，并造成200%攻击力魔法伤害。': '诅咒本路前排，并造成200%攻击力魔法伤害。',
            '对本路所有敌人施加2回合诅咒': '对本路所有敌人施加诅咒',
            '施加{rank:1:3}衰弱和诅咒，持续2回合。': '施加{rank:1:3}衰弱（持续2回合）和诅咒。',
            '虚弱和诅咒持续2回合。': '虚弱持续2回合。',
            '获得自身14.4%最大生命护盾并净化，持续2回合。': '获得自身14.4%最大生命护盾，持续2回合，并净化。',
            '普攻命中有{rank:0:1}概率诅咒当前目标，持续3回合。': '普攻命中有{rank:0:1}概率诅咒当前目标。',
            '对本分路最靠前目标施加诅咒{flat:1:1}回合，造成': '对本分路最靠前目标施加诅咒，造成',
        }
        for before, after in cases.items():
            with self.subTest(before=before):
                self.assertEqual(rewrite(before), after)

    def test_other_durations_and_names_are_kept(self):
        for text in ('自身解除并免疫虚弱、沉默、破甲、诅咒和眩晕2回合。',
                     '万魂诅咒', '本路友军获得净化和30%力量2回合。',
                     '净化全体友方并使其免疫有害状态1回合'):
            self.assertEqual(rewrite(text), text)

    def test_document_pass_updates_skill_texts_and_purify_info(self):
        document = {'cfg': {
            'skill': {'S': {'info': '自身获得净化2回合。', 'name': '万魂诅咒'}},
            'system_simple': {'bonds_104': [{'info': '并诅咒2回合'}]},
            'return_msg_config': {'25018': '净化并移除目标的减益效果。', '30016': '净化'}}}
        apply_purify_curse_text(document)
        cfg = document['cfg']
        self.assertEqual(cfg['skill']['S'], {'info': '自身获得净化。', 'name': '万魂诅咒'})
        self.assertEqual(cfg['system_simple']['bonds_104'][0]['info'], '并诅咒')
        self.assertEqual(cfg['return_msg_config']['25018'], PURIFY_INFO)
        self.assertEqual(cfg['return_msg_config']['30016'], '净化')

    def test_client_glossary_and_rules_match(self):
        tips = (ROOT / 'client/src/skill_tips_105.aspart').read_text('utf-8')
        skill_set = (ROOT / 'client/src/stages/139_SkillSet.as').read_text('utf-8')
        avatar = (ROOT / 'client/src/stages/137_Avatar.as').read_text('utf-8')
        for source in (tips, skill_set):
            self.assertIn('"' + PURIFY_TERM + '"', source)
            self.assertIn('"' + CURSE_TERM + '"', source)
        self.assertIn('_loc1_["curse"] = "' + CURSE_TERM + '";', skill_set)
        self.assertIn('CURSE_CHARGES_PER_LAYER106:int = 2;', avatar)
        self.assertIn('CURSE_MAX_LAYERS106:int = 3;', avatar)
        # Neither status counts down in the client's turn settlement.
        self.assertIn('if(_loc3_ == "purify" || _loc3_ == "curse") continue;', avatar)
        self.assertNotRegex(avatar, re.compile(r'"诅咒" \+ _loc11_\.round'))


if __name__ == '__main__':
    unittest.main()
