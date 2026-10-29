"""Role balance, native parity, and unchanged combat-panel contracts."""
import copy
import math
import unittest
from decimal import Decimal, ROUND_FLOOR, ROUND_HALF_UP
from pathlib import Path

from audit_power_roles import build_samples, summarize
from arena_opponents import combat_config_signature
from gameplay_competition import GameplayCompetition
from gateway import load_game_config
from power_balance_104 import (
    POWER_STAT_WEIGHTS, LEGACY_POWER_STAT_WEIGHTS,
    apply_power_balance_104, normalize_team_power,
)

ROOT = Path(__file__).resolve().parents[1]


class PowerRoleBalanceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.document = load_game_config(ROOT / 'config/reconstruction/full-config.json')
        cls.samples = build_samples(cls.document)

    def test_three_roles_stay_close_across_progression_and_equipment(self):
        self.assertGreaterEqual(len(self.samples), 1600)
        for group in summarize(self.samples):
            with self.subTest(scenario=group['scenario'], quality=group['quality']):
                self.assertEqual([r['role'] for r in group['roles']], [1, 2, 3])
                # User selected defense=1.8; purple cohorts retain a gap below 13%.
                self.assertLess(group['new_mean_gap'], .13)
                self.assertLess(group['new_mean_gap'], group['old_mean_gap'])

    def test_weight_overlay_is_idempotent_and_keeps_hero_panels(self):
        document = copy.deepcopy(self.document)
        avatars = copy.deepcopy(document['cfg']['avatar'])
        apply_power_balance_104(document)
        self.assertEqual(document['cfg']['avatar'], avatars)
        self.assertEqual(tuple(document['cfg']['system_simple']['power'][1:5]), POWER_STAT_WEIGHTS)
        once = copy.deepcopy(document)
        apply_power_balance_104(document)
        self.assertEqual(document, once)

    def test_independent_squared_weight_and_anchor_rounding(self):
        unit = dict(hp_max=60000, ap=10000, de_ph=5000, de_ma=4000,
                    tpl=[1, 1, 1, 245, 337], new_4attrs={}, slv=1)
        D = Decimal
        weighted = D('0.29') * 60000 + D('1.5') * 10000 + D('1.8') * 9000
        raw = weighted * weighted * 1582 * D('0.00000001')
        base = int(raw.quantize(D('.00001'), rounding=ROUND_HALF_UP).to_integral_value(rounding=ROUND_FLOOR))
        expected = int((D(1000000) * (D(base) / D(1000000)) ** D('.75') + D('.000005')).to_integral_value(rounding=ROUND_FLOOR))
        self.assertEqual(GameplayCompetition(None, self.document)._team_power([unit]), expected)

    def test_every_main_attribute_still_increases_power(self):
        unit = dict(hp_max=60000, ap=10000, de_ph=5000, de_ma=4000,
                    tpl=[1, 1, 1, 245, 337], new_4attrs={}, slv=1)
        power = GameplayCompetition(None, self.document)
        before = power._team_power([unit])
        for stat in ('hp_max', 'ap', 'de_ph', 'de_ma'):
            with self.subTest(stat=stat):
                self.assertGreater(power._team_power([{**unit, stat: unit[stat] + 1000}]), before)
        self.assertEqual(power._team_power([unit, unit]), normalize_team_power(2 * power._team_power_base([unit])))

    def test_role_weights_invalidate_cached_arena_config(self):
        old = copy.deepcopy(self.document['cfg'])
        old['system_simple']['power'][1:5] = LEGACY_POWER_STAT_WEIGHTS
        self.assertNotEqual(combat_config_signature(old), combat_config_signature(self.document['cfg']))


if __name__ == '__main__':
    unittest.main()
