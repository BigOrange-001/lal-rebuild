from pathlib import Path
from unittest import TestCase
from unittest.mock import patch

from battle_engine import base_unit
from gateway import load_game_config


CONFIG = Path(__file__).resolve().parents[1] / 'config/reconstruction/full-config.json'


class HeroPassiveQualityTests(TestCase):
    @classmethod
    def setUpClass(cls):
        with patch('hero_passive_quality_105.restrict_low_star_passives'):
            cls.before = load_game_config(CONFIG)['cfg']
        cls.cfg = load_game_config(CONFIG)['cfg']

    def test_only_the_requested_low_star_slots_change(self):
        removed = {
            'A_1033_5', 'A_1123_5', 'A_1129_5', 'A_1132_5', 'A_1134_5', 'A_1137_5',
            'A_1139_5', 'A_1202_5', 'A_1208_5', 'A_1217_5', 'A_1221_5', 'A_1222_5',
            'A_1223_5', 'A_1227_5', 'A_1309_5', 'A_1310_5', 'A_1311_5',
        }
        self.assertEqual(self.before['avatar'].keys(), self.cfg['avatar'].keys())
        self.assertEqual(self.before['skill'], self.cfg['skill'])
        for aid, original in self.before['avatar'].items():
            with self.subTest(aid=aid):
                current = self.cfg['avatar'][aid]
                if aid in removed:
                    self.assertTrue(original['pl'][13])
                    panel = original['pl'].copy()
                    panel[13] = None
                    self.assertEqual(current, {**original, 'pl': panel})
                else:
                    self.assertEqual(current, original)

    def test_combat_snapshots_use_the_final_passive_slot(self):
        for aid in ('A_1221_5', 'A_1221_6', 'A_1209_4', 'A_1209_5'):
            with self.subTest(aid=aid):
                unit = base_unit(self.cfg, aid, 1, leader=True)
                self.assertIsNotNone(unit['skill'])
                self.assertIsNotNone(unit['leader_skill'])
                if aid == 'A_1221_5':
                    self.assertIsNone(unit['skillB'])
                else:
                    self.assertEqual(unit['skillB']['skid'], self.cfg['avatar'][aid]['pl'][13])
