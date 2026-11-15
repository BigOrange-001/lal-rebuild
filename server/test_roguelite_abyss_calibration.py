"""Accepted evidence must match published tables and decisive-win criteria."""
import json
import unittest
from pathlib import Path

from roguelite_abyss import DIFFICULTIES

ROOT=Path(__file__).resolve().parents[1]


class CalibrationEvidenceTests(unittest.TestCase):
    def test_actual_config_report_matches_difficulty_and_explicit_win_criteria(self):
        report=json.loads((ROOT/'docs/roguelite-abyss-calibration-data/accepted.json').read_text('utf-8'))
        self.assertEqual([(d['multiplier'],d['retries']) for d in report['difficulties']],DIFFICULTIES)
        self.assertEqual(report['enemy_rates']['normal'],[.36,.45,.54])
        self.assertEqual(len(report['runs']),40)
        self.assertFalse(report['native_verified'])
        for run in report['runs']:
            self.assertEqual(run['status'],'cleared')
            for row in run['rows']:
                if row['win']:
                    self.assertEqual(row['enemy_alive'],0)
                    self.assertGreater(row['own_alive'],0)
                    self.assertFalse(row['censored'])
        one,ten=report['summary']
        self.assertLessEqual(one['node_attempts']['normal']['max_attempts'],2)
        self.assertLessEqual(one['node_attempts']['boss']['max_attempts'],4)
        self.assertLessEqual(ten['mean_retries'],5)

    def test_starters_and_budget_are_bounded_and_not_native_claims(self):
        starters=json.loads((ROOT/'docs/roguelite-abyss-calibration-data/starter-trials.json').read_text('utf-8'))
        self.assertEqual(starters['trials'],60)
        self.assertEqual(starters['passes'],60)
        self.assertFalse(starters['pool_growth'])
        budget=json.loads((ROOT/'docs/roguelite-abyss-relic-budget.json').read_text('utf-8'))
        self.assertFalse(budget['native_verified'])
        for row in budget['budget']:
            self.assertEqual(row['combinations'],56)
            self.assertTrue(.8<=row['max_ratio']<=1.2)
        self.assertEqual(len(budget['tower']),144)


if __name__=='__main__':unittest.main()
