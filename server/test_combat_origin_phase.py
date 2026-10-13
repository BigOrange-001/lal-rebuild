"""Advancement metadata must match Avatar.toDataObj in every player path."""
import copy
import json
import sqlite3
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
from battle_engine import base_unit, serialize_player_team, _native_skill_snapshot
from gameplay_combat import GameplayCombat
from gameplay_roster import GameplayRosterEquipment
from gameplay_social import GameplaySocial
from player_store import PlayerStore


class CombatOriginPhaseTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = json.loads((Path(__file__).resolve().parents[1] /
                                 'config/reconstruction/full-config.json').read_text(encoding='utf-8'))

    def setUp(self):
        self.db = sqlite3.connect(':memory:', check_same_thread=False)
        self.addCleanup(self.db.close)
        self.store = PlayerStore(self.db, self.config)
        self.uid = self.store.login('phase-origin')['uid']
        self.combat = GameplayCombat(self.store, self.config)
        self.roster = GameplayRosterEquipment(self.store, self.config)
        def progress(profile):
            for phase, iid in enumerate(list(profile['avatars'])[:3]):
                profile['avatars'][iid]['phase'] = phase
            return profile, {}
        self.store.atomic_update(self.uid, progress)
        self.profile = self.store.profile_raw(self.uid)
        self.ids = list(self.profile['avatars'])[:3]
        self.team = [[iid, lane, .2] for lane, iid in enumerate(self.ids)]

    def test_main_origin_preserves_stored_phase_and_derived_stats(self):
        reply = self.combat._start_main(self.uid, {'cid': 'M_001_1', 'diff': 0, 'team': self.team})
        self.assertEqual([unit['phase'] for unit in reply['orgin_team_a']], [0, 1, 2])
        for iid, unit in zip(self.ids, reply['orgin_team_a']):
            raw = self.roster.battle_attributes(self.profile, iid)
            for key in ('hp', 'hp_max', 'ap', 'de_ph', 'de_ma'):
                self.assertEqual(unit[key], raw[key])
        self.assertTrue(all(unit['phase'] == 0 for unit in reply['orgin_team_b']))

    def test_submitted_compact_phase_cannot_override_owned_progress(self):
        compact = [[iid, 99, 10, 999999, 999999, 999999, 999999, 99, lane, .2, None, 1]
                   for lane, iid in enumerate(self.ids)]
        units = serialize_player_team(self.config['cfg'], self.profile, 0, compact)
        self.assertEqual([unit['phase'] for unit in units], [0, 1, 2])

    def test_helper_snapshot_carries_validated_phase(self):
        aid = self.ids[1].split('|')[0]
        avatar = self.roster.battle_attributes(self.profile, self.ids[1])
        avatar.update(aid=aid, new_4attrs={k: 0 for k in ('hit', 'flee', 'crit', 'tough')})
        helper = {'avatar': avatar, 'avatar_id': self.ids[1]}
        with patch.object(GameplaySocial, 'lookup_assist', return_value=copy.deepcopy(helper)):
            result = self.combat._resolve_assist(self.profile, {'team': [None] * 5 +
                [[aid, 0, .2, '92000001', 0]]})
        self.assertEqual(result['battle_snapshot']['phase'], 1)

    def test_default_npc_phase_is_explicit_zero(self):
        aid = self.ids[0].split('|')[0]
        self.assertEqual(base_unit(self.config['cfg'], aid, team=2)['phase'], 0)

    def test_exploration_origin_preserves_selected_roster_phase(self):
        self.combat._dispatch_exploration(self.uid, 'user.exploration_start', {})
        self.combat._dispatch_exploration(self.uid, 'user.exploration_make_army', {'aids': self.ids})
        reply = self.combat._dispatch_exploration(self.uid, 'user.exploration_combat', {'team': self.team})
        self.assertEqual([unit['phase'] for unit in reply['orgin_team_a']], [0, 1, 2])

    def test_player_nested_skill_growth_matches_npc_and_preserves_config(self):
        skill_id = self.config['cfg']['avatar']['A_1030_5']['pl'][10]
        row = self.config['cfg']['skill'][skill_id]
        before = copy.deepcopy(row)
        self.assertTrue(row['skillUpPaths'])
        for level in (1, 2, 4, 6, 8, 10, 11):
            actual = self.roster._skill(skill_id, level)
            expected = _native_skill_snapshot(self.config['cfg'], skill_id, level)
            self.assertEqual(actual, expected)
            for action_index, path, step in row['skillUpPaths']:
                value = actual['skills'][action_index]
                base = before['skill'][action_index]
                for index in path:
                    value, base = value[index], base[index]
                self.assertAlmostEqual(value, base + step * (min(10, level) - 1))
        self.assertEqual(row, before)


if __name__ == '__main__':
    unittest.main()
