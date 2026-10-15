"""Behavior regressions for the skill simulator issues found in PR #11."""
import copy
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from battle_engine import ReferenceBattle, _native_skill_snapshot, base_unit


ROOT = Path(__file__).resolve().parents[1]


class ReferenceBattleActionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = json.loads((ROOT / 'config/reconstruction/full-config.json')
                                .read_text(encoding='utf-8'))['cfg']

    def unit(self, aid, team, pos, *, hp=1000, attack=100, line=0):
        return {'aid': aid, 'isme': team == 1, 'line': line, 'pos': pos,
                'hp': hp, 'hp_max': hp, 'ap': attack, 'de_ph': 0, 'de_ma': 0,
                'tpl': [1, 0, 0, 200, 337], 'new_4attrs': {}}

    def cast(self, allies, enemies, skill):
        battle = ReferenceBattle(allies, enemies, config=self.config)
        caster = battle.a[0]
        caster['_team'] = battle.a  # Set by run() before dispatching a skill.
        caster['skill'] = copy.deepcopy(skill)
        self.assertTrue(battle._apply_native_skill(caster, battle.b))
        return battle

    def focus_skill(self):
        return {'pl': [0, 0, 1000, 0, 0, 1],
                'skills': [['focus_fire', 'FX']]}

    def test_focus_fire_hits_enemy_and_includes_caster(self):
        allies = [self.unit('A_1001_6', 1, 500),
                  self.unit('A_1002_6', 1, 550)]
        for ally in allies:
            ally['range'] = 337  # Isolate routing from snapshot range lookup.
        battle = self.cast(allies, [self.unit('A_1003_6', 2, 600)],
                           self.focus_skill())
        self.assertEqual([unit['hp'] for unit in battle.a], [1000, 1000])
        self.assertEqual(battle.b[0]['hp'], 800)

    def test_focus_fire_caster_can_attack_without_other_allies(self):
        caster = self.unit('A_1001_6', 1, 500)
        caster['range'] = 337
        battle = self.cast([caster], [self.unit('A_1003_6', 2, 600)],
                           self.focus_skill())
        self.assertEqual(battle.a[0]['hp'], 1000)
        self.assertEqual(battle.b[0]['hp'], 900)

    def test_focus_fire_uses_snapshot_range_and_filters_helpers(self):
        allies = [self.unit('A_1001_6', 1, 500, attack=50),
                  self.unit('A_1002_6', 1, 600),
                  self.unit('A_1004_6', 1, 1200, attack=999),
                  self.unit('A_1005_6', 1, 600, attack=999, line=1),
                  self.unit('A_1006_6', 1, 600, attack=999, hp=0)]
        battle = self.cast(allies, [self.unit('A_1003_6', 2, 700)],
                           self.focus_skill())
        self.assertEqual(battle.b[0]['hp'], 850)
        self.assertEqual([unit['hp'] for unit in battle.a],
                         [1000, 1000, 1000, 1000, 0])

    def test_locked_sequence_attacks_lowest_hp_hero_on_another_lane(self):
        caster = self.unit('A_1226_6', 1, 500)
        enemies = [self.unit('A_1001_6', 2, 600, hp=10000),
                   self.unit('A_1002_6', 2, 1000, hp=1000, line=1),
                   self.unit('A_2001_6', 2, 550, hp=100)]
        skill = _native_skill_snapshot(self.config, 'S_401226_6')
        battle = self.cast([caster], enemies, skill)
        self.assertEqual([unit['hp'] for unit in battle.b], [10000, 535, 100])

    def test_locked_sequence_uses_its_action_index_for_the_policy(self):
        caster = self.unit('A_1226_6', 1, 500)
        skill = _native_skill_snapshot(self.config, 'S_401226_6')
        skill['skills'].insert(0, ['manual_ability', 'unused'])
        skill['actionTargetPolicies'].insert(0, None)
        skill['actionTargetMaxTargets'].insert(0, None)
        battle = self.cast([caster], [self.unit('A_1001_6', 2, 600, hp=10000),
                                     self.unit('A_1002_6', 2, 1000)], skill)
        self.assertEqual([unit['hp'] for unit in battle.b], [10000, 535])

    def test_locked_sequence_without_policy_preserves_nearest_target(self):
        skill = _native_skill_snapshot(self.config, 'S_401226_6')
        skill['actionTargetPolicies'] = []
        battle = self.cast([self.unit('A_1226_6', 1, 500)],
                           [self.unit('A_1001_6', 2, 600, hp=10000),
                            self.unit('A_1002_6', 2, 1000)], skill)
        self.assertEqual([unit['hp'] for unit in battle.b], [9535, 1000])

    def test_range_reads_the_serialized_tpl_field(self):
        unit = base_unit(self.config, 'A_1001_2')
        self.assertNotIn('range', unit)
        self.assertEqual(unit['tpl'][4], 337)
        battle = ReferenceBattle([unit], [], config=self.config)
        self.assertEqual(battle._get_range(unit), 337)

    def test_explicit_and_manual_attack_range_take_priority(self):
        unit = self.unit('A_1001_6', 1, 500)
        battle = ReferenceBattle([unit], [], config=self.config)
        unit['range'] = 0
        self.assertEqual(battle._get_range(unit), 0)
        unit['range'] = 500
        self.assertEqual(battle._get_range(unit), 500)
        unit['manual_attack_range'] = 800
        self.assertEqual(battle._get_range(unit), 800)


if __name__ == '__main__':
    unittest.main()
