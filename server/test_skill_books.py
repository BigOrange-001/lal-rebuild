"""User equipment calibration and book progression without touching saves."""
import copy
import json
import sqlite3
import sys
import unittest
from pathlib import Path
from unittest.mock import Mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
from player_store import PlayerStore, GameplayFault
from gameplay_roster import GameplayRosterEquipment
from skill_books import apply_equipment_calibration, upgrade_probability, percentage
from battle_engine import ReferenceBattle


class SkillBooksTests(unittest.TestCase):
    def setUp(self):
        root = Path(__file__).resolve().parents[1]
        self.config = json.loads((root / 'config/reconstruction/full-config.json').read_text('utf-8'))
        apply_equipment_calibration(self.config)
        self.db = sqlite3.connect(':memory:', check_same_thread=False)
        self.addCleanup(self.db.close)
        self.store = PlayerStore(self.db, self.config)
        self.uid = self.store.login('book-upgrade-test')['uid']
        self.roster = next(h for h in self.store.gameplay_handlers if isinstance(h, GameplayRosterEquipment))
        def seed(p):
            p['gold'] = 100000
            p['my_equips'] = {f'eq{i}': {'eid': 'E_6001_2', 'lv': 1, 'slv': 1}
                              for i in range(12)}
            p['as_equips'] = [[] for _ in range(6)]
            return p, {}
        self.store.atomic_update(self.uid, seed)
        self.roster.rng = Mock()
        self.roster.rng.randrange.return_value = 0

    def upgrade(self, action, materials):
        return self.roster.dispatch(self.uid, 'user.swallow_skillbook',
                                   {'actionID': action, 'eqid': 'eq0', 'eqids': materials})

    def test_calibration_exact_rows_and_quality_suffixes(self):
        root = Path(__file__).resolve().parents[1]
        source = json.loads((root / 'config/reconstruction/equipment-calibration.json').read_text('utf-8'))
        self.assertEqual(len(self.config['cfg']['equip']), 256)
        for eid, row in source['equipment'].items():
            actual = self.config['cfg']['equip'][eid]
            self.assertEqual(actual['pl'][:8], row['pl'][:8])
            self.assertEqual(actual['pl'][9:], row['pl'][9:])
            self.assertEqual(actual['type'], row['type'])
            if row['type'] == 6:
                self.assertRegex(actual['name'], r'-[白绿蓝紫橙红]$')
                self.assertNotIn('-白-白', actual['name'])
                self.assertTrue(self.config['cfg']['skill'][actual['skill']]['bookRule'])
                if '符印' in row['name']:
                    self.assertIsNone(self.config['cfg']['skill'][actual['skill']]['pl'])
            else:
                self.assertEqual(actual['name'], row['name'])
        before = copy.deepcopy(self.config)
        apply_equipment_calibration(self.config)
        self.assertEqual(before, self.config)

    def test_probability_rounding_cap_and_rank_curves(self):
        simple = self.config['cfg']['system_simple']
        self.assertEqual(upgrade_probability(simple, 1, [{'quality': 2}] * 5), 1)
        self.assertEqual(upgrade_probability(simple, 3, [{'quality': 3}, {'quality': 6}]), .78)
        self.assertEqual(upgrade_probability(simple, 9, [{'quality': 2}]), 0)
        for level in range(1,10):
            for quality in range(2,7):
                expected=max(0,quality*10-3*(level-1))/100
                self.assertEqual(upgrade_probability(simple,level,[{'quality':quality}]),expected)
        self.assertEqual(upgrade_probability(simple,9,[{'quality':2},{'quality':3}]),.06)
        self.assertEqual(upgrade_probability(simple,2,[{'quality':6}]*2),1)
        self.assertEqual(upgrade_probability(simple,10,[{'quality':6}]*5),0)
        for quality, lo, hi in ((2, .18, .45), (3, .24, .6), (7, .48, 1.2)):
            self.assertEqual(percentage(quality, 1), lo)
            self.assertEqual(percentage(quality, 10), hi)

    def test_passive_uses_full_stats_and_does_not_skip_later_equipment(self):
        p = self.store.profile_raw(self.uid)
        aid = next(iter(self.roster.heroes))
        p['avatars'] = {'hero': {'aid': aid, 'lv': 1, 'hit': 100}}
        p['team'] = [['hero']]
        p['my_equips'] = {
            'book': {'eid': 'E_6005_2', 'slv': 10, 'lv': 1},
            'gear': {'eid': 'E_1001_3', 'lv': 1},
        }
        p['as_equips'] = [['book', 'gear']]
        actual = self.roster.battle_attributes(p, 'hero')
        sid = self.roster.equipment['E_6005_2']['skill']
        passive = self.roster.skills[sid]
        actions = passive['skill']
        passive['skill'] = []
        try:
            baseline = self.roster.battle_attributes(p, 'hero')
        finally:
            passive['skill'] = actions
        self.assertEqual(actual['hit'], int(baseline['hit'] * 1.45))
        p['as_equips'] = [['gear', 'book']]
        self.assertEqual(actual, self.roster.battle_attributes(p, 'hero'))
        red = self.book_skill('E_6005_7', 10)
        self.assertAlmostEqual(red['skills'][0][1], 1.2)
        self.assertIsNone(red['pl'])

    def test_multiple_upgrades_same_login_consume_and_charge_once(self):
        first = self.upgrade('one', ['eq1', 'eq2', 'eq3', 'eq4', 'eq5'])
        self.assertEqual(first['equip']['slv'], 2)  # five materials still raise just one level
        before = self.store.profile_raw(self.uid)
        self.assertEqual(first, self.upgrade('one', ['eq1', 'eq2', 'eq3', 'eq4', 'eq5']))
        self.assertEqual(before, self.store.profile_raw(self.uid))
        second = self.upgrade('two', ['eq6'])
        self.assertEqual(second['equip']['slv'], 3)
        third = self.upgrade('three', ['eq7'])
        self.assertEqual(third['equip']['slv'], 4)
        p = self.store.profile_raw(self.uid)
        self.assertEqual(p['gold'], 100000 - 20 - 40 - 60)
        self.assertEqual(len(p['my_equips']), 5)

    def test_failed_roll_is_a_committed_replayable_attempt(self):
        self.roster.rng.randrange.return_value = 99
        reply = self.upgrade('failed', ['eq1'])
        self.assertFalse(reply['success'])
        self.assertEqual(reply['equip']['slv'], 1)
        p = self.store.profile_raw(self.uid)
        self.assertNotIn('eq1', p['my_equips'])
        self.assertEqual(p['gold'], 99980)
        self.roster.rng.randrange.return_value = 0
        self.assertEqual(reply, self.upgrade('failed', ['eq1']))
        self.assertEqual(self.upgrade('after-failure', ['eq2'])['equip']['slv'], 2)

    def test_invalid_materials_full_level_and_funds_are_atomic(self):
        for materials in (['eq0'], ['eq1', 'eq1'], ['missing'], [f'eq{i}' for i in range(1, 7)]):
            before = self.store.profile_raw(self.uid)
            with self.assertRaises(GameplayFault):
                self.upgrade(str(materials), materials)
            self.assertEqual(before, self.store.profile_raw(self.uid))

        for mode in ('max', 'locked', 'equipped', 'funds'):
            def seed(p):
                p['my_equips']['eq0']['slv'] = 10 if mode == 'max' else 1
                p['my_equips']['eq1']['lock'] = mode == 'locked'
                p['as_equips'][0] = ['eq1'] if mode == 'equipped' else []
                p['gold'] = 0 if mode == 'funds' else 1000
                return p, {}
            self.store.atomic_update(self.uid, seed)
            before = self.store.profile_raw(self.uid)
            with self.assertRaises(GameplayFault):
                self.upgrade(mode, ['eq1'])
            self.assertEqual(before, self.store.profile_raw(self.uid))

    def book_skill(self, eid, level=1):
        return self.roster._skill(self.config['cfg']['equip'][eid]['skill'], level)

    @staticmethod
    def unit(aid, side=True, line=1):
        return {'aid': aid, 'isme': side, 'line': line, 'pos': 1500, 'hp': 10000,
                'hp_max': 10000, 'ap': 100, 'de_ph': 0, 'de_ma': 0,
                'new_4attrs': {'hit': 100, 'flee': 100, 'crit': 100, 'tough': 100},
                'tpl': [1, 1, 1, 0, 300]}

    def test_active_book_self_buff_twofold_and_three_turn_cadence(self):
        skill = self.book_skill('E_6501_2', 10)
        self.assertAlmostEqual(skill['skills'][0][1], .9)
        battle = ReferenceBattle([self.unit('caster')], [self.unit('enemy', False)])
        caster = battle.a[0]
        caster['_team'] = battle.a
        caster['book_skill'] = skill
        self.assertTrue(battle._apply_native_skill(caster, battle.b, 'book_skill'))
        self.assertEqual(battle._get_hit(caster), 190)
        battle._tick_buffs(caster)
        self.assertEqual(battle._get_hit(caster), 190)
        battle._tick_buffs(caster)
        self.assertEqual(battle._get_hit(caster), 100)
        caster['_skill_cd_book'] = 2
        casts = []
        battle._apply_native_skill = lambda a, e, slot='skill': casts.append(slot) or True
        battle._basic_attack = lambda *args: None
        turns = []
        for turn in range(1, 10):
            old = len(casts)
            battle._run_unit_turn(caster, {1: battle.a, 2: battle.b}, 1)
            if len(casts) > old:
                turns.append(turn)
        self.assertEqual(turns, [3, 6, 9])

    def test_fire_hits_and_burns_all_enemies_on_own_lane(self):
        battle = ReferenceBattle([self.unit('caster')],
                                 [self.unit('a', False), self.unit('b', False), self.unit('c', False, 2)])
        caster = battle.a[0]
        caster['_team'] = battle.a
        caster['book_skill'] = self.book_skill('E_6505_5', 10)
        self.assertTrue(battle._apply_native_skill(caster, battle.b, 'book_skill'))
        for target in battle.b[:2]:
            self.assertLess(target['hp'], 10000)
            self.assertTrue(target.get('_manual_dots'))
            old = target['hp']
            for tick in range(3):
                battle._tick_buffs(target)
            self.assertEqual(old - target['hp'], 300)
            battle._tick_buffs(target)
            self.assertEqual(old - target['hp'], 300)
        self.assertEqual(battle.b[2]['hp'], 10000)
        self.assertFalse(battle.b[2].get('_manual_dots'))

    def test_guardian_shields_whole_friendly_lane_by_fire_total(self):
        battle = ReferenceBattle([self.unit('caster'), self.unit('ally'), self.unit('offlane', line=2)],
                                 [self.unit('enemy', False)])
        caster = battle.a[0]
        caster['_team'] = battle.a
        caster['book_skill'] = self.book_skill('E_6506_5', 10)
        self.assertTrue(battle._apply_native_skill(caster, battle.b, 'book_skill'))
        # Highest available quality is purple: 200% + three 100%-AP ticks.
        self.assertEqual(battle._buff_value(caster, 'shield'), 500)
        self.assertEqual(battle._buff_value(battle.a[1], 'shield'), 500)
        self.assertIsNone(battle._buff(battle.a[2], 'shield'))

    def test_strength_and_steel_use_quarter_rate_on_total_attributes(self):
        for eid, stats in [('E_6001_2', ['ap']), ('E_6002_2', ['de_ph', 'de_ma'])]:
            p = self.store.profile_raw(self.uid)
            p['avatars'] = {'hero': {'aid': next(iter(self.roster.heroes)), 'lv': 1}}
            p['team'] = [['hero']]
            p['my_equips'] = {'book': {'eid': eid, 'slv': 10, 'lv': 1}}
            p['as_equips'] = [['book']]
            actual = self.roster.battle_attributes(p, 'hero')
            skill = self.roster.skills[self.roster.equipment[eid]['skill']]
            saved = skill['skill']
            skill['skill'] = []
            try:
                baseline = self.roster.battle_attributes(p, 'hero')
            finally:
                skill['skill'] = saved
            for stat in stats:
                self.assertEqual(actual[stat], self.roster._equip_to_int(baseline[stat] * 1.1125))
            self.assertAlmostEqual(self.book_skill(eid, 1)['skills'][0][1], .045)

    def test_penetration_ignores_both_defenses_and_active_bonus_expires(self):
        battle = ReferenceBattle([self.unit('caster')], [self.unit('enemy', False)])
        caster, target = battle.a[0], battle.b[0]
        target['de_ph'] = target['de_ma'] = 80
        caster['book_skill'] = self.book_skill('E_6008_7', 10)  # top passive quality: 45%
        for damage_type in (1, 2):
            target['hp'] = 10000
            battle._native_damage(caster, target, 1, damage_type)
            self.assertEqual(target['hp'], 9944)
        caster['_team'] = battle.a
        caster['book_skill'] = self.book_skill('E_6504_7', 10)  # top quality: 90% for one turn
        self.assertTrue(battle._apply_native_skill(caster, battle.b, 'book_skill'))
        self.assertAlmostEqual(battle._book_bonus(caster, 'penetration'), .9)
        battle._tick_buffs(caster)
        battle._tick_buffs(caster)
        self.assertEqual(battle._book_bonus(caster, 'penetration'), 0)
        caster['book_skill'] = self.book_skill('E_6008_7', 10)
        self.assertAlmostEqual(battle._book_bonus(caster, 'penetration'), .45)

    def test_penetration_book_curve_scales_to_ninety_percent(self):
        for quality in range(2,8):
            for level in (1,5,10):
                skill=self.book_skill(f'E_6504_{quality}',level)
                self.assertAlmostEqual(skill['skills'][0][1],.9*(quality+1)/8*(level+5)/15)
        row=self.config['cfg']['skill'][self.config['cfg']['equip']['E_6504_7']['skill']]
        self.assertNotIn('只取最高值',row['info'])

    def test_passive_penetration_caps_at_forty_five_percent(self):
        for quality in range(2,8):
            for level in (1,5,10):
                skill=self.book_skill(f'E_6008_{quality}',level)
                self.assertAlmostEqual(skill['skills'][0][1],.45*(quality+1)/8*(level+5)/15)
            row=self.config['cfg']['skill'][self.config['cfg']['equip'][f'E_6008_{quality}']['skill']]
            for phrase in ('上限','最高值','不叠加'):
                self.assertNotIn(phrase,row['info'])

    def test_all_penetration_sources_take_maximum_for_native_and_absolute_damage(self):
        from manual_ability_sim import SkillCompleteBattle
        for cls in (ReferenceBattle,SkillCompleteBattle):
            battle=cls([self.unit('caster')],[self.unit('enemy',False)])
            caster,target=battle.a[0],battle.b[0]
            target['de_ph']=target['de_ma']=1000
            caster['ap']=1000
            caster['book_skill']={'skills':[['book_passive',.2,'penetration'],['book_passive',.45,'penetration']]}
            battle._add_buff(caster,'book_penetration',1,.6)
            self.assertAlmostEqual(battle._book_bonus(caster,'penetration'),.6)
            battle._add_buff(target,'sunder',3,1.5)  # also 60%, not 84% combined
            for kind in (1,2):
                self.assertEqual(battle._defense_against(caster,target,kind),400)
                target['hp']=10000
                battle._injured_absolute(target,1000,kind,source=caster)
                self.assertEqual(target['hp'],9400)
                target['hp']=10000
                battle._native_damage(caster,target,1,kind)
                self.assertEqual(target['hp'],9400)
            battle._add_buff(target,'sunder',3,4)  # strongest reduction is now 80%
            self.assertEqual(battle._defense_against(caster,target,1),200)
            battle._remove_buff(caster,'book_penetration')
            self.assertAlmostEqual(battle._book_bonus(caster,'penetration'),.45)
            self.assertEqual(battle._defense_against(caster,target,2),200)

    def test_shield_bonus_spends_shield_without_amplifying_unshielded_hp_damage(self):
        battle = ReferenceBattle([self.unit('caster')], [self.unit('enemy', False)])
        caster, target = battle.a[0], battle.b[0]
        caster['book_skill'] = self.book_skill('E_6003_2', 10)  # 45% extra shield damage
        battle._add_buff(target, 'shield', 3, 145)
        battle._native_damage(caster, target, 1, 1)
        self.assertEqual(target['hp'], 10000)
        self.assertIsNone(battle._buff(target, 'shield'))
        battle._native_damage(caster, target, 1, 1)
        self.assertEqual(target['hp'], 9900)
        battle._add_buff(target, 'shield', 3, 29)
        battle._native_damage(caster, target, 1, 1)
        self.assertEqual(target['hp'], 9820)  # 20 base damage absorbed, 80 reach HP

    def test_attack_burn_uses_post_shield_damage_and_preserves_total_across_ticks(self):
        battle = ReferenceBattle([self.unit('caster')], [self.unit('enemy', False)])
        caster, target = battle.a[0], battle.b[0]
        caster['book_skill'] = self.book_skill('E_6009_3', 1)  # 24%
        battle._add_buff(target, 'shield', 3, 83)
        battle._basic_attack(caster, target)  # 17 HP damage; burn total floor(17*.24) = 4
        old = target['hp']
        for _ in range(3):
            battle._tick_buffs(target)
        self.assertEqual(old - target['hp'], 4)
        battle._tick_buffs(target)
        self.assertEqual(old - target['hp'], 4)
        target.pop('_manual_dots', None)
        battle._native_damage(caster, target, 1, 1)  # skills do not trigger glyphs
        self.assertFalse(target.get('_manual_dots'))

    def test_curse_max_eight_percent_threshold_and_purification(self):
        battle = ReferenceBattle([self.unit('caster')], [self.unit('enemy', False)])
        caster, target = battle.a[0], battle.b[0]
        caster['book_skill'] = self.book_skill('E_6201_5', 10)
        self.assertAlmostEqual(battle._book_bonus(caster, 'attack_curse'), .08)
        battle.rng = Mock()
        battle.rng.get_random.return_value = 800
        battle._basic_attack(caster, target)
        self.assertIsNone(battle._buff(target, 'curse'))
        battle.rng.get_random.return_value = 799
        battle._basic_attack(caster, target)
        self.assertEqual(battle._buff(target, 'curse').round, 3)
        battle._add_buff(target, 'purify', 1, 0)
        self.assertIsNone(battle._buff(target, 'curse'))
        battle._basic_attack(caster, target)
        self.assertIsNone(battle._buff(target, 'curse'))

    def test_recovery_increases_outgoing_healing_only(self):
        battle = ReferenceBattle([self.unit('caster'), self.unit('ally')], [self.unit('enemy', False)])
        caster, target = battle.a[0], battle.a[1]
        caster['book_skill'] = self.book_skill('E_6010_3', 10)  # 60%
        target['hp'] = 100
        battle._injured(target, 100, 4, source=caster)
        self.assertEqual(target['hp'], 260)
        caster['hp'] = 100
        battle._injured(caster, 100, 4, source=target)
        self.assertEqual(caster['hp'], 200)

    def test_fire_highest_quality_curve_and_lower_quality_scaling(self):
        self.assertAlmostEqual(self.book_skill('E_6505_5', 1)['skills'][0][1], 1.1)
        self.assertAlmostEqual(self.book_skill('E_6505_5', 10)['skills'][0][1], 2)
        self.assertAlmostEqual(self.book_skill('E_6505_3', 10)['skills'][0][1], 2 * 4 / 6)



if __name__ == '__main__':
    unittest.main()
