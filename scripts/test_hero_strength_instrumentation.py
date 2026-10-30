import unittest
from unittest.mock import patch

from hero_strength_instrumentation import MeasuredBattle, unsupported_manual_skills
from test_manual_ability_sim import unit


class StrengthStatisticsTests(unittest.TestCase):
    def setUp(self):
        self.battle = MeasuredBattle([unit('A_1001_6', 1, 1800), unit('A_1002_6', 1, 1900)],
                                     [unit('A_1003_6', 2, 1600)], config={})

    def test_damage_shield_and_effective_healing(self):
        battle = self.battle
        actor, ally, enemy = battle.a[0], battle.a[1], battle.b[0]
        battle._add_buff(enemy, 'shield', 2, 200)
        battle._injured(enemy, 500, 1, source=actor)
        battle._injured(ally, 300, 1, source=enemy)
        battle._injured(ally, 500, 4, source=actor)
        self.assertEqual(battle.statistics[(1, actor['_owner_token'])]['damage'], 500)
        self.assertEqual(battle.statistics[(1, actor['_owner_token'])]['healing'], 300)
        self.assertEqual(battle.statistics[(2, enemy['_owner_token'])]['taken'], 500)
        self.assertEqual(battle.shares(1, actor['_owner_token']), dict(damage=1, healing=1, taken=0))

    def test_summon_credit_uses_owner_identity(self):
        battle = self.battle
        owner, enemy = battle.a[0], battle.b[0]
        summon = dict(unit('A_3001_6', 1, 1800), summon_owner_token=owner['_owner_token'])
        battle._injured(enemy, 200, 1, source=summon)
        self.assertEqual(battle.statistics[(1, owner['_owner_token'])]['damage'], 200)

    def test_lethal_damage_counts_before_revival_and_overkill_is_capped(self):
        battle = self.battle
        actor, enemy = battle.a[0], battle.b[0]
        enemy['hp'] = 100
        battle._add_buff(enemy, 'bless', 1, 0)
        battle._injured(enemy, 900, 1, source=actor)
        self.assertGreater(enemy['hp'], 0)
        self.assertEqual(battle.statistics[(1, actor['_owner_token'])]['damage'], 100)
        self.assertEqual(battle.statistics[(2, enemy['_owner_token'])]['taken'], 100)

    def test_self_healing_without_explicit_source_and_zero_share(self):
        battle = self.battle
        hero = battle.a[0]
        hero['hp'] -= 150
        battle._injured(hero, 300, 4)
        self.assertEqual(battle.statistics[(1, hero['_owner_token'])]['healing'], 150)
        self.assertEqual(battle.shares(2, battle.b[0]['_owner_token'])['healing'], 0)

    def test_shield_break_bonus_counts_absorbed_damage_not_shield_points(self):
        battle = self.battle
        actor, enemy = battle.a[0], battle.b[0]
        battle._add_buff(enemy, 'shield', 2, 600)
        with patch.object(battle, '_book_bonus', side_effect=lambda source, name: 1 if name == 'shield_damage' else 0):
            battle._injured(enemy, 500, 1, source=actor)
        self.assertEqual(enemy['hp'], 9800)
        self.assertEqual(battle.statistics[(1, actor['_owner_token'])]['damage'], 500)

    def test_preflight_detects_unimplemented_manual_skill(self):
        cfg = {'avatar': {'A_1201_6': {'pl': [None] * 10 + ['skin']}},
               'skill': {'skin': {'skill': [['manual_ability', 'skin2_1201_0', 1]]}}}
        self.assertEqual(unsupported_manual_skills(cfg, ['A_1201_6']),
                         {'A_1201_6': ['skin2_1201_0']})


if __name__ == '__main__':
    unittest.main()
