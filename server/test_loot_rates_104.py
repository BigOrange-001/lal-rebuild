"""Exact drop boundaries, final summon permissions, and redesigned claw loot."""
import copy
import unittest
from fractions import Fraction
from pathlib import Path
from unittest.mock import patch

from gateway import Backend
from ancient_trial_drop import roll_ancient_trial_drop, roll_ancient_exclusive_drop
from equipment_elite_drop import roll_elite_drop
from loot_rates_104 import apply_loot_rates_104, elite_chance
from player_store import GameplayFault
from zhuabao import Zhuabao, GROUP_WEIGHTS


class Ticket:
    def __init__(self, value): self.value = value
    def randrange(self, stop):
        assert 0 <= self.value < stop
        return self.value
    def choice(self, rows): return rows[0]


class LootRates104Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.b = Backend(':memory:', Path(__file__).resolve().parents[1] / 'config/reconstruction/full-config.json')
        cls.cfg = cls.b.config['cfg']

    @classmethod
    def tearDownClass(cls):
        cls.b.clock.close()
        cls.b.db.close()

    def setUp(self):
        self.uid = self.b.players.login(self.id())['uid']
        self.z = Zhuabao(self.b.players.economy)

    def test_elite_exact_fractions_and_roll_boundaries(self):
        tiers = self.cfg['system_simple']['elite_equipment_drop']['tiers']
        expected = [Fraction(1, 2), Fraction(35, 100), Fraction(1, 5), Fraction(1, 12), Fraction(1, 15)]
        for row, chance in zip(tiers, expected):
            self.assertEqual(elite_chance(row), chance)
            limit = row['chance_bp_fraction'][1] * 10000
            boundary = int(chance * limit)
            cid = f"M_{row['chapter_min']:03d}_1"
            self.assertIsNotNone(roll_elite_drop(self.b.config, cid, 1, True, Ticket(boundary - 1)))
            self.assertIsNone(roll_elite_drop(self.b.config, cid, 1, True, Ticket(boundary)))
            self.assertIsNone(roll_elite_drop(self.b.config, cid, 0, True, Ticket(0)))

    def test_all_ancient_equipment_rates_halved_including_exclusive(self):
        expected = [2000, 2750, 3500, 4250, 1500, 2000, 2500, 3000, 3500, 1250,
                    1500, 1750, 2000, 2250, 2250]
        for i, chance in enumerate(expected, 1):
            sid = f'P_001_{i}'
            stage = self.cfg['combat_ploy'][sid]
            self.assertEqual(stage['ancient_equip_drop']['chance_bp'], chance)
            self.assertIsNotNone(roll_ancient_trial_drop(self.b.config, stage, sid, True, Ticket(chance - 1)))
            self.assertIsNone(roll_ancient_trial_drop(self.b.config, stage, sid, True, Ticket(chance)))
        stage = self.cfg['combat_ploy']['P_001_15']
        self.assertEqual(stage['ancient_exclusive_drop']['chance_bp'], 250)
        self.assertIsNotNone(roll_ancient_exclusive_drop(self.b.config, stage, 'P_001_15', True, Ticket(249)))
        self.assertIsNone(roll_ancient_exclusive_drop(self.b.config, stage, 'P_001_15', True, Ticket(250)))
        clone = copy.deepcopy(self.b.config)
        apply_loot_rates_104(clone)
        self.assertEqual(clone, self.b.config)

    def test_normal_excludes_skins_and_other_pools_scale_all_ranks(self):
        tiers = {r['id'].rsplit('_', 1)[0]: r['tier'] for r in self.cfg['skin_acquisition_104']['heroes']}
        for pool, value in self.cfg['summon_calibration']['pools'].items():
            for quality, row in value['qualities'].items():
                for card in row['cards']:
                    tier = tiers.get(card['id'].rsplit('_', 1)[0])
                    if (pool == 'normal' and quality in ('blue', 'purple')
                            or pool == 'advanced' and quality == 'blue'):
                        self.assertIsNone(tier)
                    expected = {'T1': .1, 'T2': .2}.get(tier, 1)
                    if pool == 'advanced' and quality == 'purple' and tier:
                        expected = .1
                    self.assertEqual(card['weight'], expected)

    def test_vip7_rejected_before_spending_and_vip8_can_draw(self):
        def seed(p):
            p.update(vip_lv=7, coin=10000)
            return p, {}
        self.b.players.atomic_update(self.uid, seed)
        before = self.b.players.profile_raw(self.uid)
        for flag in (0, 1):
            with self.assertRaises(GameplayFault) as e:
                self.b.players.economy.get_lottery_activity(self.uid, {'flag': flag, 'actionID': f'vip7-{flag}'})
            self.assertEqual(e.exception.code, 'VipLevelLow')
            self.assertEqual(self.b.players.profile_raw(self.uid), before)
        def upgrade(p):
            p['vip_lv'] = 8
            return p, {}
        self.b.players.atomic_update(self.uid, upgrade)
        result = self.b.players.economy.get_lottery_activity(self.uid, {'flag': 0, 'actionID': 'vip8'})
        self.assertEqual(len(result['avatars']['avatar']), 1)

    def test_claw_hero_and_sixty_souls_use_vip_pool_even_at_vip0(self):
        self.assertEqual(GROUP_WEIGHTS, [10, 30, 20, 38, 2])
        for group, key, count in (('英雄卡', 'avatar', 1), ('魂魄', 'avatar_soul', 60)):
            with patch('zhuabao.random.choices', return_value=[group]), \
                 patch.object(self.z.summon_pools, 'draw', return_value='A_1226_6') as draw:
                entry = self.z.draw_entry()
            self.assertEqual(draw.call_args.args[0], 'vip')
            self.assertEqual(entry['gift'], {key: {'A_1226_6': count}})
            with patch.object(self.z, 'draw_entry', return_value=entry):
                result = self.z.dispatch(self.uid, 'user.zhuabao_draw', {'num': 1, 'actionID': group})
            self.assertEqual(result['awards'][0]['gift'], entry['gift'])
        self.assertEqual(self.b.players.profile_raw(self.uid)['vip_lv'], 0)
        self.assertEqual(self.b.players.profile_raw(self.uid)['avatar_soul']['A_1226_6'], 60)

    def test_claw_equipment_and_coin_nested_probabilities(self):
        for quality in (4, 5, 6):
            with patch('zhuabao.random.choices', side_effect=[['装备'], [quality]]) as picks:
                entry = self.z.draw_entry()
            self.assertEqual(picks.call_args_list[0].kwargs['weights'], [10, 30, 20, 38, 2])
            self.assertEqual(picks.call_args_list[1].kwargs['weights'], [14, 5, 1])
            eid = next(iter(entry['gift']['equip']))
            self.assertEqual(self.cfg['equip'][eid]['quality'], quality)
        for index, amount in enumerate((100, 1000)):
            expected = self.z.groups['金砖'][index]
            with patch('zhuabao.random.choices', side_effect=[['金砖'], [expected]]) as picks:
                self.assertEqual(self.z.draw_entry()['gift'], {'coin': amount})
            self.assertEqual(picks.call_args_list[1].kwargs['weights'], [19, 1])
        self.assertFalse(any('equip_soul' in r['gift'] for rows in self.z.groups.values() for r in rows))

    def test_material_quantities_use_final_dungeon_rewards_rounded_up(self):
        rows = {r['source_stage']: r['gift'] for r in self.z.groups['材料']}
        self.assertEqual(len(rows), 9)
        self.assertEqual(rows['P_102_5'], {'gold': 1800000})
        self.assertEqual(rows['P_103_5'], {'attrs': {'dust': [18, 32, 45, 96]}})
        self.assertEqual(rows['P_104_5'], {'mark': 162})
        self.assertEqual(rows['P_106_5'], {'attrs': {'culture_book': 18}})
        self.assertEqual(rows['P_107_5'], {'attrs': {'sp': [4] * 6}})
        self.assertEqual(rows['P_108_5'], {'attrs': {'dn_stone': 48}})
        self.assertEqual(rows['P_101_5']['heroes'][0]['num'], 12)
        self.assertEqual(rows['P_109_4']['heroes'][0]['num'], 6)
        self.assertEqual({r['eid']: r['num'] for r in rows['P_105_5']['items']},
                         {'E_6504_5': 3, 'E_6501_2': 1, 'E_6502_3': 2, 'E_6503_4': 2})


if __name__ == '__main__':
    unittest.main()
