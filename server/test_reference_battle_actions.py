"""Behavior regressions for the skill simulator issues found in PR #11."""
import copy
import json
import sys
import unittest
from collections import Counter
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

    def test_zhaoxin_thunder_force_applies_curse_to_all_enemy_targets(self):
        caster = self.unit('A_1226_6', 1, 2200, attack=100)
        enemies = [self.unit('A_1001_6', 2, 800, hp=100000),
                   self.unit('A_1002_6', 2, 1000, hp=100000)]
        skill = _native_skill_snapshot(self.config, 'S_201226_6')

        curse_actions = [action for action in skill['skills']
                         if action and action[0] == 'curse']
        self.assertEqual(len(curse_actions), 1)
        self.assertGreaterEqual(int(curse_actions[0][1]), 1)

        battle = self.cast([caster], enemies, skill)
        self.assertTrue(all('curse' in enemy.get('_buffs', {})
                            for enemy in battle.b))
        self.assertNotIn('curse', battle.a[0].get('_buffs', {}))

    def test_steel_wave_hits_every_lane_enemy_three_times_from_either_team(self):
        for star in (5, 6):
            for team in (1, 2):
                with self.subTest(star=star, team=team):
                    caster = self.unit(f'A_1310_{star}', team, 1500, attack=100, line=1)
                    same_lane = [self.unit(f'A_100{i + 1}_5', 3-team, pos,
                                           hp=10000, line=1)
                                 for i, pos in enumerate((0, 200, 500, 900, 1700, 2200, 2700, 3000))]
                    other_lanes = [self.unit('A_1002_5', 3-team, 1600, hp=10000, line=i)
                                   for i in (0, 2)]
                    opponents = same_lane + other_lanes
                    battle = ReferenceBattle([caster] if team == 1 else opponents,
                                             opponents if team == 1 else [caster], config=self.config)
                    owner_side = battle.a if team == 1 else battle.b
                    enemy_side = battle.b if team == 1 else battle.a
                    owner = owner_side[0]
                    owner['_team'] = owner_side
                    owner['skill'] = _native_skill_snapshot(self.config, f'S_201310_{star}')
                    battle._add_buff(enemy_side[0], 'taunt', 2)
                    hits = []
                    injured = battle._injured

                    def record_hit(target, *args, **kwargs):
                        hits.append(target['aid'])
                        return injured(target, *args, **kwargs)

                    battle._injured = record_hit
                    self.assertTrue(battle._apply_native_skill(owner, enemy_side))
                    self.assertEqual([unit['hp'] for unit in enemy_side], [9700]*8 + [10000]*2)
                    self.assertEqual(Counter(hits),
                                     Counter({unit['aid']: 3 for unit in enemy_side[:8]}))

    def test_global_lowest_current_hp_does_not_fallback_to_helpers(self):
        caster = self.unit('A_1226_6', 1, 500)
        skill = _native_skill_snapshot(self.config, 'S_401226_6')
        helper = self.unit('A_2001_6', 2, 600, hp=100)
        battle = self.cast([caster], [helper], skill)
        self.assertEqual(helper['hp'], 100)

    def test_ban_stand_reads_effective_action_type_from_tpl_index_one(self):
        caster = self.unit('A_1001_5', 1, 500)
        target = self.unit('A_1001_5', 2, 600, hp=1000)
        target['tpl'] = [3, 1, 2, 200, 337]
        battle = ReferenceBattle([caster], [target], config=self.config)
        self.assertEqual(len(battle._find_aim_list(caster, [target], 500, ban_stand=True)), 1)
        target['tpl'][1] = 3
        self.assertEqual(battle._find_aim_list(caster, [target], 500, ban_stand=True), [])

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

    def test_curse_rejects_every_positive_buff(self):
        target = self.unit('A_1002_6', 2, 600)
        battle = ReferenceBattle([self.unit('A_1001_6', 1, 500)], [target], config=self.config)
        battle._add_buff(target, 'curse', 1)

        for kind in ('shield', 'strong', 'taunt', 'bless', 'steel', 'armor',
                     'hitup', 'fleeup', 'critup', 'toughup'):
            battle._add_buff(target, kind, 2, 100)

        self.assertEqual(set(target['_buffs']), {'curse'})

    def test_purify_has_priority_before_or_after_curse(self):
        for order in (('curse', 'purify'), ('purify', 'curse')):
            with self.subTest(order=order):
                target = self.unit('A_1002_6', 2, 600)
                battle = ReferenceBattle([self.unit('A_1001_6', 1, 500)], [target], config=self.config)
                for kind in order:
                    battle._add_buff(target, kind, 1)
                self.assertNotIn('curse', target['_buffs'])
                self.assertNotIn('_curse_window_started', target)

    def test_purify_cleanses_evil_and_curse_together(self):
        target = self.unit('A_1002_6', 2, 600)
        battle = ReferenceBattle([self.unit('A_1001_6', 1, 500)], [target], config=self.config)
        battle._add_buff(target, 'evil', 2)
        battle._add_buff(target, 'curse', 2)

        battle._add_buff(target, 'purify', 1)

        self.assertEqual(set(target['_buffs']), {'purify'})

    def test_curse_blocks_the_targets_next_turn_then_expires(self):
        for target_acts_first in (True, False):
            with self.subTest(target_acts_first=target_acts_first):
                target = self.unit('A_1002_6', 1, 500)
                opponent = self.unit('A_1003_6', 2, 600)
                battle = ReferenceBattle([target], [opponent], config=self.config)
                sides = {1: battle.a, 2: battle.b}
                if target_acts_first:
                    battle._run_unit_turn(target, sides, 1)

                target['skill'] = {'pl': [0, 0], 'skills': [['strong', 100, 2, 'FX']]}
                battle._add_buff(target, 'curse', 1)
                battle._run_unit_turn(target, sides, 1)

                self.assertNotIn('strong', target['_buffs'])
                self.assertIn('curse', target['_buffs'])

                battle._run_unit_turn(target, sides, 1)

                self.assertNotIn('curse', target['_buffs'])
                self.assertIn('strong', target['_buffs'])

    def test_curse_action_targets_the_enemy(self):
        attacker = self.unit('A_1001_6', 1, 500)
        target = self.unit('A_1002_6', 2, 600)
        battle = self.cast([attacker], [target], {
            'pl': [0, 0, 3000, 0, -1, 1],
            'skills': [['curse', 1, 'FX']],
        })
        self.assertIn('curse', battle.b[0]['_buffs'])
        self.assertNotIn('curse', battle.a[0].get('_buffs', {}))

    def test_zero_range_curse_targets_the_caster(self):
        battle = self.cast([self.unit('A_1001_6', 1, 500)],
                           [self.unit('A_1002_6', 2, 600)], {
                               'pl': [0, 0, 0, 0, -1, 1],
                               'skills': [['curse', 1, 'FX']],
                           })
        self.assertIn('curse', battle.a[0]['_buffs'])
        self.assertNotIn('curse', battle.b[0].get('_buffs', {}))

    def test_summon_keeps_the_owners_native_team(self):
        for owner_team in (1, 2):
            with self.subTest(owner_team=owner_team):
                owner_pos, opponent_pos = ((2200, 800) if owner_team == 1 else (800, 2200))
                owner = self.unit('A_1082_5', owner_team, owner_pos, attack=1000)
                owner['lv'] = 20
                opponent = self.unit('A_1001_6', 3 - owner_team, opponent_pos)
                battle = ReferenceBattle([owner] if owner_team == 1 else [opponent],
                                         [opponent] if owner_team == 1 else [owner],
                                         config=self.config)
                owner['_team'] = battle.a if owner_team == 1 else battle.b
                owner['skill'] = {'skid': 'S_305082_5', 'pl': [1, 1, 0, 0, 0, 1],
                                  'skills': [['summon', 0.5, 'A_2003_2', 2, 'SUMMON_EFF']]}

                self.assertTrue(battle._apply_native_skill(
                    owner, battle.b if owner_team == 1 else battle.a))

                owner_side = battle.a if owner_team == 1 else battle.b
                summoned = owner_side[-1]
                self.assertEqual(summoned['aid'], 'A_2003_2')
                self.assertEqual(summoned['isme'], owner_team == 1)
                self.assertIs(summoned['_team'], owner_side)
                self.assertEqual(summoned['summon_owner'], owner['aid'])

    def test_legacy_mushroom_array_keeps_its_original_skill(self):
        owner = self.unit('A_1082_5', 1, 2200, attack=1000)
        opponent = self.unit('A_1001_5', 2, 800)
        battle = ReferenceBattle([owner], [opponent], config=self.config)
        owner = battle.a[0]
        owner['_team'] = battle.a
        owner['skill'] = _native_skill_snapshot(self.config, 'S_305082_5')
        self.assertTrue(battle._apply_native_skill(owner, battle.b))
        summoned = battle.a[-1]
        self.assertEqual(summoned['aid'], 'A_2003_3')
        self.assertEqual(summoned['skill']['skid'], 'S_9002_2')

    def test_summons_use_authored_base_and_growth_not_owner_multipliers(self):
        authored = {
            'A_2003_2': [3729.6,447.3,1073.8,128.8,385,46.2,464.8,56],
            'A_2018_2': [6393.6,766.8,1840.8,220.8,660,79.2,796.8,96],
            'A_2024_6': [7992,958.5,2301,276,825,99,996,120],
        }
        skills = {'S_301209_4': 'A_2003_2', 'S_301209_5': 'A_2003_2',
                  'S_301209_6': 'A_2003_2', 'S_301310_5': 'A_2018_2',
                  'S_301310_6': 'A_2018_2', 'S_301226_6': 'A_2024_6'}
        for skill_id, aid in skills.items():
            for level in (1, 49, 50, 99, 125):
                for team in (1, 2):
                    with self.subTest(skill=skill_id, level=level, team=team):
                        owner = self.unit('A_1209_4', team, 2200, hp=1000, attack=300)
                        owner.update({'lv': level, 'slv': 1, 'de_ph': 70, 'de_ma': 80,
                                      'new_4attrs': {'hit': 11, 'flee': 12, 'crit': 13, 'tough': 14}})
                        enemy = self.unit('A_1001_6', 3-team, 800)
                        battle = ReferenceBattle([owner] if team == 1 else [enemy],
                                                 [enemy] if team == 1 else [owner], config=self.config)
                        roster, opponents = (battle.a, battle.b) if team == 1 else (battle.b, battle.a)
                        owner = roster[0]
                        owner['_team'] = roster
                        owner['skill'] = _native_skill_snapshot(self.config, skill_id)
                        self.assertTrue(battle._apply_native_skill(owner, opponents))
                        summoned = roster[-1]
                        self.assertEqual(summoned['aid'], aid)
                        self.assertEqual(summoned['lv'], level)
                        pl = authored[aid]
                        self.assertEqual(self.config['avatar'][aid]['pl'][:8], pl)
                        self.assertEqual([summoned[k] for k in ('hp_max', 'ap', 'de_ph', 'de_ma')],
                                         [int(pl[i]+pl[i+1]*(level-1)) for i in (0,2,4,6)])
                        self.assertEqual(summoned['hp'], summoned['hp_max'])
                        self.assertEqual(summoned['new_4attrs'], owner['new_4attrs'])
                        self.assertEqual(summoned['isme'], team == 1)

    def test_bounded_summon_does_not_stack_for_the_same_skill(self):
        owner = self.unit('A_1209_4', 1, 2200, hp=1000, attack=300)
        owner.update({'lv': 10, 'slv': 1})
        battle = ReferenceBattle([owner], [self.unit('A_1001_6', 2, 800)],
                                 config=self.config)
        owner = battle.a[0]
        owner['_team'] = battle.a
        owner['skill'] = _native_skill_snapshot(self.config, 'S_301209_4')

        self.assertTrue(battle._apply_native_skill(owner, battle.b))
        self.assertTrue(battle._apply_native_skill(owner, battle.b))

        summons = [unit for unit in battle.a if unit.get('_bounded_summon')]
        self.assertEqual(len(summons), 1)

    def test_summon_base_stats_ignore_owner_buffs_but_copy_secondary_getters(self):
        owner = self.unit('A_1209_4', 1, 2200, hp=1000, attack=301)
        owner.update({'lv': 10, 'slv': 1, 'de_ph': 100, 'de_ma': 120,
                      'new_4attrs': {'hit': 11, 'flee': 12, 'crit': 13, 'tough': 14}})
        battle = ReferenceBattle([owner], [self.unit('A_1001_6', 2, 800)], config=self.config)
        owner = battle.a[0]
        owner['_team'] = battle.a
        owner['skill'] = _native_skill_snapshot(self.config, 'S_301209_4')
        for kind, value in (('strong', .5), ('steel', .5), ('armor', .2),
                            ('hitup', 5), ('fleeup', 6), ('critup', 7), ('toughup', 8)):
            battle._add_buff(owner, kind, 2, value)
        self.assertTrue(battle._apply_native_skill(owner, battle.b))
        summoned = battle.a[-1]
        self.assertEqual([summoned[k] for k in ('hp_max', 'ap', 'de_ph', 'de_ma')],
                         [7755, 2233, 800, 968])
        self.assertEqual(summoned['new_4attrs'], {'hit': 16, 'flee': 18, 'crit': 20, 'tough': 22})

    def test_real_summons_deal_damage_and_survive_an_ordinary_hit(self):
        for skill_id, aid in (('S_301209_6', 'A_1209_6'), ('S_301310_6', 'A_1310_6')):
            with self.subTest(skill=skill_id):
                owner = base_unit(self.config, aid, level=50, team=1, leader=True)
                target = base_unit(self.config, 'A_1001_5', level=50, team=2,
                                   overrides={'hp': 1000000, 'hp_max': 1000000})
                battle = ReferenceBattle([owner], [target], config=self.config)
                owner, target = battle.a[0], battle.b[0]
                owner['_team'] = battle.a
                owner['skill'] = _native_skill_snapshot(self.config, skill_id)
                self.assertTrue(battle._apply_native_skill(owner, battle.b))
                summoned = battle.a[-1]
                initial_hp = target['hp']
                self.assertTrue(battle._apply_native_skill(summoned, battle.b))
                self.assertLess(target['hp'], initial_hp)
                summon_hp = summoned['hp']
                battle._native_damage(target, summoned, 1.0, 1)
                self.assertGreater(summoned['hp'], 0)
                self.assertLess(summoned['hp'], summon_hp)

    def test_teemo_skill_rows_match_the_update(self):
        for star in ('4', '5', '6'):
            poison = self.config['skill'][f'S_201209_{star}']
            mushroom = self.config['skill'][f'S_301209_{star}']
            self.assertEqual(poison['pl'][:2], [0, 0])
            self.assertEqual(poison['skill'][0][0], 'poison')
            self.assertEqual(poison['skill'][0][2], 2)
            self.assertEqual(mushroom['skill'][0][0], 'summon')
            self.assertEqual(mushroom['skill'][0][2:4], ['A_2003_2', 4])

        self.assertEqual(self.config['avatar']['A_2003_2']['pl'][10], 'S_821003_2')
        self.assertEqual(self.config['avatar']['A_2003_3']['res'], 'A_2003_2')
        self.assertEqual(self.config['avatar']['A_2003_3']['pl'][10], 'S_9002_2')
        for star in ('5', '6'):
            self.assertEqual(self.config['skill'][f'S_305082_{star}']['skill'][0][2], 'A_2003_3')

        for star in ('5', '6'):
            strike = self.config['skill'][f'S_201310_{star}']
            iron_mushroom = self.config['skill'][f'S_301310_{star}']
            passive = self.config['skill'][f'S_401310_{star}']
            wave = ['damage', 1.0, 1, 'FX_STEEL_LANE_WAVE']
            self.assertEqual(strike['skill'][:3], [wave, wave, wave])
            self.assertEqual(strike['actionTargetPolicies'][:3], ['enemy_lane_all'] * 3)
            self.assertEqual(strike['actionTargetMaxTargets'][:3], [-1, -1, -1])
            self.assertEqual(iron_mushroom['skill'][0][0], 'summon')
            self.assertEqual(iron_mushroom['skill'][0][2:4], ['A_2018_2', 4])
            self.assertEqual(passive['pl'][:2], [0, 2])
            self.assertEqual(passive['skill'][0][0], 'purify')

    def test_teemo_poison_uses_magic_defense_channel(self):
        caster = self.unit('A_1209_4', 1, 500, attack=1000)
        target = self.unit('A_1001_5', 2, 600, hp=1000)
        target['de_ph'] = 900
        target['de_ma'] = 0
        battle = self.cast([caster], [target],
                           _native_skill_snapshot(self.config, 'S_201209_4'))
        self.assertEqual(battle.b[0]['hp'], 808)

    def test_poison_tick_deals_twenty_percent_of_max_hp(self):
        target = self.unit('A_1001_5', 2, 600, hp=10000)
        battle = ReferenceBattle([], [target], config=self.config)
        battle._add_buff(target, 'poison', 2, 0)
        battle._tick_buffs(target)
        self.assertEqual(target['hp'], 8000)
        battle._tick_buffs(target)
        self.assertEqual(target['hp'], 6000)
        self.assertNotIn('poison', target['_buffs'])

    def test_teemo_passive_cleanses_curse_and_root(self):
        for debuff in ('curse', 'root'):
            with self.subTest(debuff=debuff):
                owner = self.unit('A_1310_5', 1, 2200)
                owner['skill_diff'] = 19
                owner['skillB'] = _native_skill_snapshot(self.config, 'S_401310_5')
                battle = ReferenceBattle([owner], [self.unit('A_1001_6', 2, 800)],
                                         config=self.config)
                owner['_team'] = battle.a
                battle._add_buff(owner, debuff, 1)

                self.assertTrue(battle._use_turn_start_passive(owner, battle.b))
                self.assertNotIn(debuff, owner.get('_buffs', {}))

    def test_steel_teemo_passive_cleanses_stun_before_turn_is_skipped(self):
        owner = base_unit(self.config, 'A_1310_5', level=99, slv=1,
                          line=0, pos=.2, leader=True, team=1)
        enemy = base_unit(self.config, 'A_1001_5', level=99, slv=1,
                          line=0, pos=.8, team=2)
        battle = ReferenceBattle([owner], [enemy], max_rounds=1, config=self.config)
        owner = battle.a[0]
        battle._add_buff(owner, 'stun', 1)
        result = battle.run()
        self.assertTrue(any(unit['aid'] == 'A_2018_2' for unit in result['team_a']))

    def test_leader_skill_runs_after_successful_ordinary_skill(self):
        owner = base_unit(self.config, 'A_1310_5', level=99, slv=1,
                          line=0, pos=.2, leader=True, team=1)
        enemy = base_unit(self.config, 'A_1001_5', level=99, slv=1,
                          line=0, pos=.8, team=2)
        result = ReferenceBattle([owner], [enemy], max_rounds=1, config=self.config).run()
        self.assertTrue(any(unit['aid'] == 'A_2018_2' for unit in result['team_a']))

    def test_duplicate_heroes_have_independent_bounded_summon_slots(self):
        owners = [self.unit('A_1209_4', 1, 2200, hp=1000, attack=300),
                  self.unit('A_1209_4', 1, 2400, hp=1000, attack=300)]
        battle = ReferenceBattle(owners, [self.unit('A_1001_5', 2, 800)], config=self.config)
        for owner in battle.a[:2]:
            owner['_team'] = battle.a
            owner['skill'] = _native_skill_snapshot(self.config, 'S_301209_4')
            self.assertTrue(battle._apply_native_skill(owner, battle.b))
        summons = [unit for unit in battle.a if unit.get('_bounded_summon')]
        self.assertEqual(len(summons), 2)
        self.assertNotEqual(summons[0].get('summon_owner_token'), summons[1].get('summon_owner_token'))

    def test_summon_uses_native_offset_from_owner(self):
        owner = self.unit('A_1209_4', 1, 2200, hp=1000, attack=300)
        battle = ReferenceBattle([owner], [self.unit('A_1001_5', 2, 800)], config=self.config)
        owner = battle.a[0]
        owner['_team'] = battle.a
        owner['skill'] = _native_skill_snapshot(self.config, 'S_301209_4')
        self.assertTrue(battle._apply_native_skill(owner, battle.b))
        self.assertEqual(battle.a[-1]['pos'], 1700)

    def test_signed_movement_respects_both_teams(self):
        for team, advanced, returned in ((1, 1950, 2200), (2, 1050, 800)):
            team_a = self.unit('A_1001_6', 1, 2200)
            team_b = self.unit('A_1002_6', 2, 800)
            battle = ReferenceBattle([team_a], [team_b], config=self.config)
            attacker = battle.a[0] if team == 1 else battle.b[0]
            enemies = battle.b if team == 1 else battle.a
            attacker['_team'] = battle.a if team == 1 else battle.b
            attacker['skill'] = {'pl': [0, 0, 1000, 0, 0, 1],
                                 'skills': [['move_self', -250, 'FX']]}

            self.assertTrue(battle._apply_native_skill(attacker, enemies))
            self.assertEqual(attacker['pos'], advanced)

            attacker['skill']['skills'] = [['move_self', 250, 'FX']]
            self.assertTrue(battle._apply_native_skill(attacker, enemies))
            self.assertEqual(attacker['pos'], returned)

    def test_push_moves_enemy_backwards_for_both_team_orientations(self):
        cases = ((1, 2400, 600, 300), (2, 0, 1800, 2100))
        for attacker_team, attacker_pos, target_pos, expected_pos in cases:
            with self.subTest(attacker_team=attacker_team):
                target_team = 3 - attacker_team
                attacker = self.unit('A_1001_6', attacker_team, attacker_pos)
                target = self.unit('A_1002_6', target_team, target_pos)
                team_a = [attacker] if attacker_team == 1 else [target]
                team_b = [target] if attacker_team == 1 else [attacker]
                battle = ReferenceBattle(team_a, team_b, config=self.config)
                attacker['_team'] = team_a if attacker_team == 1 else team_b
                attacker['skill'] = {'pl': [0, 0, 3000, 0, 0, 1],
                                     'skills': [['push', 0, 1, 300, 'FX']]}

                self.assertTrue(battle._apply_native_skill(
                    attacker, team_b if attacker_team == 1 else team_a))
                self.assertEqual(target['pos'], expected_pos)

    def test_move_to_target_lane_stays_on_the_casters_side_for_both_teams(self):
        for team, caster_pos, target_pos, expected_pos in ((1, 2200, 800, 1000),
                                                            (2, 800, 2200, 2000)):
            team_a = self.unit('A_1001_6', 1, 2200 if team == 2 else caster_pos)
            team_b = self.unit('A_1002_6', 2, 800 if team == 1 else caster_pos)
            caster = team_a if team == 1 else team_b
            target = team_b if team == 1 else team_a
            target['pos'] = target_pos
            target['line'] = 1
            battle = ReferenceBattle([team_a], [team_b], config=self.config)
            caster['_team'] = battle.a if team == 1 else battle.b
            caster['skill'] = {'pl': [0, 0, 3001, 0, 0, 1],
                               'skills': [['move_to_target_lane',
                                           'enemy_lane_frontmost', 0, 0, 'FX']]}

            self.assertTrue(battle._apply_native_skill(
                caster, battle.b if team == 1 else battle.a))
            self.assertEqual(caster['line'], 1)
            self.assertEqual(caster['pos'], expected_pos)

    def test_cross_lane_reline_clamps_to_the_casters_side(self):
        caster = self.unit('A_1001_6', 1, 2200)
        enemy = self.unit('A_1002_6', 2, 800, line=1)
        battle = ReferenceBattle([caster], [enemy], config=self.config)
        self.assertTrue(battle._reline(caster, line=1, pos=900))

        self.assertEqual(caster['line'], 1)
        self.assertEqual(caster['pos'], 1000)
        self.assertTrue(caster['isme'])


if __name__ == '__main__':
    unittest.main()
