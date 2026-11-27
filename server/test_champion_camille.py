import unittest
from pathlib import Path
from unittest.mock import patch

from battle_engine import base_unit
from champion_camille import CHAMPION, TROPHY, builtin_asset
from gateway import load_game_config
from manual_ability_sim import SkillCompleteBattle


class ChampionCamilleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        root = Path(__file__).resolve().parents[1]
        cls.cfg = load_game_config(root / 'config/reconstruction/full-config.json')['cfg']

    def test_builtin_media_and_acquisition(self):
        self.assertEqual(self.cfg['avatar'][CHAMPION]['role'], '功能型')
        self.assertEqual(self.cfg['avatar'][TROPHY]['modUnitType'], 'summon')
        for mode, pool in self.cfg['summon_calibration']['pools'].items():
            ids = {card['id'] for quality in pool['qualities'].values() for card in quality['cards']}
            self.assertNotIn(TROPHY, ids)
            if mode in ('advanced', 'vip'):
                self.assertIn(CHAMPION, ids)
        media = self.cfg['champion_camille']['media']
        aliases = {row['alias'] for row in self.cfg['mod_runtime']['assets']}
        for row in media['assets']:
            self.assertIn(row['alias'], aliases)
            content, mime = builtin_asset(self.cfg, media['digest'], row['path'])
            self.assertEqual(mime, 'image/png')
            self.assertEqual(len(content), row['bytes'])

    def unit(self, aid, side, lane, pos, *, level=10, rank=10, leader=False):
        return base_unit(self.cfg, aid, level, rank, lane, pos, leader, side)

    def battle(self, enemies=None, extra_allies=()):
        owner = self.unit(CHAMPION, 1, 0, .80, leader=True)
        enemies = enemies or [self.unit('A_1028_6', 2, 1, .20), self.unit('A_1001_5', 2, 1, .26)]
        return SkillCompleteBattle([owner, *extra_allies], enemies, config=self.cfg)

    def test_engage_spawns_at_cast_origin_and_trophies_coexist(self):
        battle = self.battle(extra_allies=(self.unit(CHAMPION, 1, 2, .80),))
        owner, friend = battle.a
        target, front = battle.b
        for unit, ap in ((target, 100), (front, 10)):
            unit.update(ap=ap, hp=100000, hp_max=100000)
        self.assertEqual(owner['skill']['skills'][0][5:9], [2, .15, 4, .20])
        self.assertEqual(owner['skill']['pl'][:2], [0, 3])
        origin = owner['pos']
        with patch.object(battle, 'hit', wraps=battle.hit) as hit:
            self.assertTrue(battle._apply_native_skill(owner, battle.b))
            self.assertEqual([call.args[3] for call in hit.call_args_list], [1, 1, 3, 3])
        cup = battle.a[-1]
        self.assertEqual((owner['line'], cup['line'], cup['pos']), (1, 0, origin))
        self.assertGreater(target['pos'], front['pos'])
        self.assertEqual(battle._buff(target, 'stun').round, 2)
        self.assertEqual((cup['hp'], cup['de_ph'], cup['de_ma'], cup['ap']),
                         (owner['hp_max'], battle._get_de_ph(owner), battle._get_de_ma(owner), 0))
        self.assertTrue(battle._apply_native_skill(friend, battle.b))
        friend_cup = battle.a[-1]
        original_lifetime = battle._buff(cup, 'summon')
        battle._settle_turn_buffs(cup)
        battle._add_buff(cup, 'bless', 0)
        self.assertTrue(battle._apply_native_skill(owner, battle.b))
        self.assertGreater(cup['hp'], 0)
        self.assertIs(battle._buff(cup, 'summon'), original_lifetime)
        self.assertEqual(original_lifetime.round, 4)
        self.assertGreater(friend_cup['hp'], 0)
        new_cup = battle.a[-1]
        self.assertEqual(new_cup['line'], 1)
        self.assertEqual(battle._buff(new_cup, 'summon').round, 5)
        for _ in range(5):
            battle._settle_turn_buffs(cup)
        self.assertEqual(cup['hp'], 0)
        self.assertGreater(new_cup['hp'], 0)

    def test_rain_heals_each_champion_and_bless_does_not_extend_trophy_life(self):
        friend = self.unit(CHAMPION, 1, 2, .80)
        other = self.unit('A_1001_5', 1, 2, .90)
        battle = self.battle(extra_allies=(friend, other))
        owner, friend, other = battle.a
        battle._apply_native_skill(owner, battle.b)
        cup = battle.a[-1]
        for unit in (owner, friend, other, cup):
            unit.update(hp=500, hp_max=1000)
        battle._add_buff(owner, 'stun', 2)
        self.assertTrue(battle._apply_native_skill(cup, battle.b))
        self.assertEqual([unit['hp'] for unit in (owner, friend, other, cup)], [700, 700, 500, 700])
        self.assertEqual([battle._buff(u, 'purify').value for u in (owner, friend, cup)], [1, 2, 2])
        self.assertFalse(battle._buff(owner, 'stun'))
        self.assertFalse(battle._buff(owner, 'bless'))
        life = battle._buff(cup, 'summon')
        self.assertEqual(life.round, 5)
        for _ in range(4):
            battle._settle_turn_buffs(cup)
        self.assertEqual(cup['hp'], 700)
        self.assertEqual(life.round, 1)
        cup['hp'] = 0
        battle._resolve_lethal(cup)
        self.assertGreater(cup['hp'], 0)
        self.assertEqual(life.round, 1)
        self.assertFalse(battle._buff(cup, 'bless'))
        battle._add_buff(cup, 'bless', 0)
        self.assertFalse(battle._settle_turn_buffs(cup))
        self.assertTrue(battle._settle_turn_buffs(cup))
        self.assertEqual(cup['hp'], 0)

    def test_wild_form_keeps_stats_and_two_actions_and_can_be_purified(self):
        battle = self.battle()
        owner = battle.a[0]
        target = max(battle.b, key=lambda unit: unit['hp_max'])
        stats = {key: target[key] for key in ('hp_max', 'ap', 'de_ph', 'de_ma', 'line')}
        with patch.object(battle, '_fixed_true_damage', wraps=battle._fixed_true_damage) as smite:
            self.assertTrue(battle._apply_native_skill(owner, battle.b, 'leader_skill'))
            self.assertEqual(smite.call_args.args[2], target['hp_max'] * .40)
        self.assertEqual(stats, {key: target[key] for key in stats})
        self.assertTrue(target['_camille_wild_card'].endswith(target['aid'][-2:]))
        self.assertFalse(battle._apply_native_skill(target, battle.a))
        with patch.object(battle, '_run_unit_turn_base', return_value=True):
            for expected in (1, 0, None):
                battle._run_unit_turn(target, {1: battle.a, 2: battle.b}, 2)
                status = battle._buff(target, 'camille_wild')
                self.assertEqual(status.round if status is not None else None, expected)
        battle.add_purify_charges(target, 1)
        self.assertTrue(battle._apply_native_skill(owner, battle.b, 'leader_skill'))
        self.assertFalse(battle._buff(target, 'camille_wild'))

    def test_fmvp_requires_alive_crossing_and_has_opening_readiness(self):
        battle = self.battle()
        owner, source = battle.a[0], battle.b[0]
        owner.update(hp=310, hp_max=1000, _skill_cd_b=0)
        battle._injured(owner, 21, 3, source=source, derived=True)
        self.assertEqual(owner['hp'], 289)
        self.assertEqual(battle._buff(owner, 'purify').value, 1)
        self.assertEqual(battle._buff(owner, 'bless').round, 2)
        self.assertGreaterEqual(battle._buff_value(owner, 'shield'), 500)
        self.assertEqual(owner['_skill_cd_b'], 2)

        battle = self.battle()
        owner, source = battle.a[0], battle.b[0]
        owner.update(hp=310, hp_max=1000)
        battle._injured(owner, 310, 3, source=source, derived=True)
        self.assertEqual(owner['hp'], 0)
        self.assertFalse(battle._buff(owner, 'bless'))
        self.assertFalse(owner.get('_camille_fmvp_fired'))

    def test_wild_form_keeps_demonblade_endless_rage_on_lethal_hit(self):
        battle = self.battle(enemies=[self.unit('A_1803_6', 2, 1, .2)])
        owner, target = battle.a[0], battle.b[0]
        self.assertTrue(battle._apply_native_skill(owner, battle.b, 'leader_skill'))
        self.assertTrue(battle._buff(target, 'camille_wild'))
        target['hp'] = 1
        battle._injured(target, 1000, 3, source=owner, derived=True)
        self.assertEqual(target['hp'], 1)
        self.assertTrue(battle.demon_fury(target))

    def test_wild_form_blocks_direct_on_hit_passives_without_blocking_basic_damage(self):
        for aid in ('A_1086_6', 'A_1103_6'):
            with self.subTest(aid=aid):
                battle = self.battle(enemies=[self.unit(aid, 2, 1, .2)])
                owner, transformed = battle.a[0], battle.b[0]
                self.assertTrue(battle._apply_native_skill(owner, battle.b, 'leader_skill'))
                self.assertTrue(battle._buff(transformed, 'camille_wild'))
                owner.update(hp=100000, hp_max=100000)
                with (patch.object(battle, '_roll_attack', return_value=1),
                      patch.object(battle, 'six_next_raw', wraps=battle.six_next_raw) as lunar,
                      patch.object(battle, 'six_next_command_void', wraps=battle.six_next_command_void) as command):
                    battle._basic_attack(transformed, owner)
                self.assertLess(owner['hp'], 100000)
                lunar.assert_not_called()
                command.assert_not_called()
                self.assertIsNone(battle._buff(owner, 'silence'))
