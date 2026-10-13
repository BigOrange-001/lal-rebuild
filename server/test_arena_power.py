"""Native AIR golden values for talent power and its two rounding stages."""
import copy
import json
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from gameplay_competition import GameplayCompetition


class ArenaPowerTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source = Path(__file__).resolve().parents[1] / 'config/reconstruction/full-config.json'
        cls.game = GameplayCompetition(None, json.loads(source.read_text(encoding='utf-8')))

    def setUp(self):
        # Only combat numbers and skill IDs; no account or private save data.
        self.unit = {
            'hp_max': 290957, 'ap': 26829, 'de_ph': 14431, 'de_ma': 13219,
            'tpl': [2, 4, 1, 350, 577], 'slv': 9, 'talent': 'T_03_02',
            'new_4attrs': {'hit': 3079, 'flee': 2039, 'crit': 1073, 'tough': 1344},
            'skill': {'skid': 'S_621078_6'},
            'leader_skill': {'skid': 'S_631078_6'},
            'book_skill': {'skid': 'S_9001_6', 'slv': 2},
        }

    def test_talent_and_captain_skill_match_native(self):
        self.assertEqual(self.game._team_power([self.unit]), 21243450)
        no_talent = {**self.unit, 'talent': None}
        self.assertEqual(self.game._team_power([no_talent]), 10621725)
        no_captain = {**self.unit, 'leader_skill': None}
        self.assertEqual(self.game._team_power([no_captain]), 11127520)
        self.assertEqual(self.game._team_power([no_talent, no_captain]), 21749245)

    def test_native_five_decimal_floor_boundary(self):
        self.assertEqual(self.game._team_power([{**self.unit, 'talent': None, 'ap': 51766}]),
                         16081432)
        self.assertEqual(self.game._team_power([{**self.unit, 'talent': None, 'ap': 482327}]),
                         288254415)

    def test_invalid_or_legacy_talent_is_finite_without_bonus(self):
        for talent in (None, 'unknown', 'T_03_01', {}, {'id': 'unknown'}):
            with self.subTest(talent=talent):
                unit = copy.deepcopy(self.unit)
                unit['talent'] = talent
                self.assertEqual(self.game._team_power([unit]), 10621725)
        self.assertEqual(self.game._team_power([{**self.unit, 'talent': {'id': 'T_03_02'}}]),
                         21243450)


if __name__ == '__main__':
    unittest.main()
