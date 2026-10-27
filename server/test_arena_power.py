"""Power 1.0.4: panel-only talents and independent arithmetic golden values."""
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

    @staticmethod
    def expected(ap=26829, captain=True, sunder=0):
        # Independent Decimal oracle for this fixed fixture, including both floors.
        from decimal import Decimal, ROUND_FLOOR, ROUND_HALF_UP
        D = Decimal
        weighted = D(290957)/2 + D(ap)*2 + D(14431+13219)*D('.625')
        skills = D('1')+D('1.5')+D('.8')+(D('3') if captain else 0)
        value = weighted * weighted * skills * 1927 * (1+D(7535).sqrt()/100) * D('1e-8')
        floor = lambda v: int(v.quantize(D('.00001'), rounding=ROUND_HALF_UP).to_integral_value(rounding=ROUND_FLOOR))
        rate = D(str(sunder))
        base = D(floor(D(floor(value))+value*D('.25')*rate/(1-rate)))
        return int((D(1000000)*(base/D(1000000))**D('.75')+D('.000005')).to_integral_value(rounding=ROUND_FLOOR))

    def test_talent_and_captain_skill_match_formula(self):
        self.assertEqual(self.game._team_power([self.unit]), self.expected(sunder=.15))
        self.assertEqual(self.game._team_power([{**self.unit,'talent':None}]), self.expected())
        self.assertEqual(self.game._team_power([{**self.unit,'leader_skill':None}]), self.expected(captain=False,sunder=.15))

    def test_rounding_at_different_panel_sizes(self):
        for ap in (51766,482327):
            self.assertEqual(self.game._team_power([{**self.unit,'talent':None,'ap':ap}]),self.expected(ap=ap))

    def test_unknown_and_panel_talents_add_no_base_power(self):
        for talent in (None,'unknown','T_01_01',{}, {'id':'unknown'}):
            self.assertEqual(self.game._team_power([{**self.unit,'talent':talent}]),self.expected())
        self.assertEqual(self.game._team_power([{**self.unit,'talent':{'id':'T_03_02'}}]),self.expected(sunder=.15))
        self.assertEqual(self.game._team_power([{**self.unit,'talent':'T_03_01'}]),self.expected(sunder=.10))


if __name__ == '__main__':
    unittest.main()
