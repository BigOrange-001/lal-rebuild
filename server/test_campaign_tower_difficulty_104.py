"""Campaign-to-tower anchors, real snapshot fitting, and unchanged early normal."""
import copy
import unittest
from pathlib import Path
from unittest.mock import patch

from gateway import Backend, load_game_config
from campaign_tower_difficulty_104 import apply_campaign_tower_difficulty_104, mapped_floor
from campaign_workbook_overlay import _power
from power_balance_104 import normalize_team_power
from gameplay_combat import GameplayCombat

CONFIG = Path(__file__).resolve().parents[1] / 'config/reconstruction/full-config.json'


class CampaignTowerDifficulty104Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.b = Backend(':memory:', CONFIG)
        cls.doc = cls.b.config
        cls.cfg = cls.doc['cfg']
        with patch('campaign_tower_difficulty_104.apply_campaign_tower_difficulty_104'):
            cls.before = load_game_config(CONFIG)['cfg']

    @classmethod
    def tearDownClass(cls):
        cls.b.clock.close()
        cls.b.db.close()

    def test_linear_floor_mapping_and_endpoints(self):
        self.assertIsNone(mapped_floor(5, 0))
        self.assertEqual(mapped_floor(6, 0), 10)
        self.assertEqual(mapped_floor(18, 0), 45)
        self.assertEqual(mapped_floor(30, 0), 80)
        self.assertEqual(mapped_floor(1, 1), 10)
        self.assertEqual(mapped_floor(30, 1), 125)

    def test_all_campaign_snapshots_and_recommendations_match_real_power(self):
        count = 0
        for cid, stage in self.cfg['combat_main'].items():
            for key, mapping in stage.get('campaign_tower_mapping_104', {}).items():
                team = stage.get('team2_by_diff', {}).get(key, stage['team2'])
                actual = _power(self.cfg, team, stage['enemy_unit_stats_by_diff'][key])
                self.assertEqual(actual, mapping['actual_power'])
                self.assertLess(abs(actual - mapping['target_power']) / mapping['target_power'], .001)
                self.assertEqual(stage['recommended_power_by_diff'][key], normalize_team_power(actual))
                count += 1
        self.assertEqual(count, 264)
        for chapter, diff, floor in ((6, 0, 10), (30, 0, 80), (1, 1, 10), (30, 1, 125)):
            stages = [(int(cid.rsplit('_', 1)[1]), s) for cid, s in self.cfg['combat_main'].items()
                      if cid.startswith(f'M_{chapter:03d}_')]
            boss = max(stages)[1]
            target = self.cfg['combat_ploy'][f'P_200_{floor}']['enemy_snapshot_power']
            actual = boss['campaign_tower_mapping_104'][str(diff)]['actual_power']
            self.assertLess(abs(actual - target) / target, .001)

    def test_early_normal_and_all_enemy_rosters_rewards_are_preserved(self):
        for cid, stage in self.cfg['combat_main'].items():
            old = self.before['combat_main'][cid]
            for key in ('team2', 'team2_by_diff', 'reward', 'hero_drop_candidates_by_diff', 'energy', 'limit'):
                self.assertEqual(stage.get(key), old.get(key), (cid, key))
            if int(cid.split('_')[1]) == 1:
                self.assertEqual(stage['enemy_unit_stats_by_diff']['0'], old['enemy_unit_stats_by_diff']['0'])
                self.assertEqual(stage['recommended_power_by_diff']['0'], old['recommended_power_by_diff']['0'])
                self.assertEqual(stage['recommended_power'], old['recommended_power'])

    def test_early_normal_recommendation_rises_to_twenty_thousand(self):
        bosses = [max((int(cid.rsplit('_', 1)[1]), s) for cid, s in self.cfg['combat_main'].items()
                      if cid.startswith(f'M_{chapter:03d}_'))[1] for chapter in range(1, 7)]
        values = [s['recommended_power_by_diff']['0'] for s in bosses]
        self.assertEqual(values[0], 6925)
        self.assertEqual(values, sorted(values))
        for chapter in range(2, 6):
            expected = values[0] + (20000 - values[0]) * (chapter - 1) / 4
            self.assertAlmostEqual(values[chapter - 1], expected, delta=10)
        self.assertAlmostEqual(values[4], 20000, delta=10)

    def test_tower_enemies_unchanged_and_display_matches_current_snapshots(self):
        for cid, stage in self.cfg['combat_ploy'].items():
            if stage.get('activity_kind') != 'tower':
                continue
            if int(stage['tower_floor']) > 125:
                self.assertEqual(stage, self.before['combat_ploy'][cid])
                continue
            self.assertEqual(stage['enemy_unit_stats_by_diff'], self.before['combat_ploy'][cid]['enemy_unit_stats_by_diff'])
            actual = _power(self.cfg, stage['team2'], stage['enemy_unit_stats_by_diff']['0'])
            self.assertEqual(stage['recommended_power'], normalize_team_power(actual))

    def test_within_chapter_progression_aliases_and_idempotence(self):
        for stage in self.cfg['combat_main'].values():
            for key, mapping in stage.get('campaign_tower_mapping_104', {}).items():
                self.assertGreater(mapping['within_chapter_ratio'], 0)
                self.assertAlmostEqual(mapping['target_power'],
                                       mapping['chapter_boss_target_power'] * mapping['within_chapter_ratio'], delta=.5)
        self.assertIs(self.doc['combat_main'], self.cfg['combat_main'])
        self.assertIs(self.doc['pve']['combat_main'], self.cfg['combat_main'])
        clone = copy.deepcopy(self.doc)
        apply_campaign_tower_difficulty_104(clone)
        self.assertEqual(clone, self.doc)

    def test_actual_battle_receives_fitted_elite_enemy_stats(self):
        uid = self.b.players.login(self.id())['uid']
        def seed(p):
            p.update(lv=125, hid='M_030_6', cid='M_030_6')
            return p, {}
        self.b.players.atomic_update(uid, seed)
        p = self.b.players.profile_raw(uid)
        team = [[aid, i, .2] for i, aid in enumerate(list(p['avatars'])[:3])]
        result = GameplayCombat(self.b.players, self.doc)._start_main(
            uid, {'cid': 'M_030_1', 'diff': 1, 'team': team, 'actionID': 'mapped-elite'})
        expected = self.cfg['combat_main']['M_030_1']['enemy_unit_stats_by_diff']['1']
        for unit, row in zip(result['orgin_team_b'], expected):
            for key in ('hp', 'ap', 'de_ph', 'de_ma'):
                self.assertEqual(unit[key], row[key])


if __name__ == '__main__':
    unittest.main()
