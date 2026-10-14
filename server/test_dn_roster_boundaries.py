"""Destiny-node replay, level, formation and reload boundaries."""
import copy
import json
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from gameplay_roster import GameplayRosterEquipment
from player_store import GameplayFault, PlayerStore


class DestinyBoundaryTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = json.loads((Path(__file__).resolve().parents[1] /
                                 'config/reconstruction/full-config.json').read_text(encoding='utf-8'))

    def setUp(self):
        self.db = sqlite3.connect(':memory:', check_same_thread=False)
        self.addCleanup(self.db.close)
        self.store = PlayerStore(self.db, self.config)
        self.uid = self.store.login('dn-boundary-test')['uid']
        self.roster = GameplayRosterEquipment(self.store, self.config)

    def call(self, method, action, **params):
        return self.roster.dispatch(self.uid, method, {'actionID': action, **params})

    def fault(self, code, method, action, **params):
        with self.assertRaises(GameplayFault) as caught:
            self.call(method, action, **params)
        self.assertEqual(caught.exception.code, code)

    def test_last_unlock_replay_levels_and_binding_reload(self):
        spare = 'A_1101_5|dn-spare'
        def seed(profile):
            profile['lv'] = 16
            profile['attrs']['dn_stone'] = 2000
            profile['attrs']['dn'] = {}
            profile['avatars'][spare] = {'id': spare, 'aid': spare, 'lv': 1, 'phase': 0}
            return profile, {}
        self.store.atomic_update(self.uid, seed)
        for number in range(1, 14):
            result = self.call('user.dn_unlock', f'unlock-{number}', key=str(number))
            self.assertEqual(result['dn'][str(number)], [1, None])
        before = self.store.profile_raw(self.uid)['attrs']
        self.fault('AlreadyUnlocked', 'user.dn_unlock', 'unlock-13-again', key='13')
        self.assertEqual(self.store.profile_raw(self.uid)['attrs']['dn_stone'], before['dn_stone'])
        self.assertEqual(self.call('user.dn_unlock', 'unlock-13', key='13')['dn']['13'], [1, None])
        level = self.call('user.dn_lvup', 'level-13', key='13', lv=1)
        self.assertEqual(level['dn']['13'], [2, None])
        self.assertEqual(self.call('user.dn_lvup', 'level-13', key='13', lv=1)['dn']['13'], [2, None])
        self.fault('InvalidLevel', 'user.dn_lvup', 'stale-level', key='13', lv=1)

        profile = self.store.profile_raw(self.uid)
        team = copy.deepcopy(profile['team'])
        dn = copy.deepcopy(profile['attrs']['dn'])
        dn['13'][1] = spare
        bound = self.call('user.fix_team', 'bind-spare', team=team, team_num=0, dn=dn)
        self.assertEqual(bound['dn']['13'][1], spare)
        illegal_team = copy.deepcopy(team)
        illegal_team[0][0] = spare
        self.fault('InvalidDN', 'user.fix_team', 'double-occupy',
                   team=illegal_team, team_num=0, dn=dn)
        self.assertEqual(self.store.profile_raw(self.uid)['attrs']['dn']['13'][1], spare)
        dn['13'][1] = None
        self.call('user.fix_team', 'unbind-spare', team=team, team_num=0, dn=dn)
        self.call('user.fix_team', 'add-main', team=illegal_team, team_num=0, dn=dn)
        self.assertEqual(self.store.login('dn-boundary-test')['uid'], self.uid)
        persisted = self.store.profile_raw(self.uid)
        self.assertIsNone(persisted['attrs']['dn']['13'][1])
        self.assertEqual(persisted['team'][0][0], spare)

    def test_max_level_and_missing_node_do_not_consume_stone(self):
        def seed(profile):
            profile['attrs']['dn_stone'] = 500
            profile['attrs']['dn'] = {'1': [50, None]}
            return profile, {}
        self.store.atomic_update(self.uid, seed)
        before = self.store.profile_raw(self.uid)['attrs']['dn_stone']
        self.fault('MaxLevel', 'user.dn_lvup', 'max', key='1', lv=50)
        self.fault('LockedNode', 'user.dn_lvup', 'locked', key='2', lv=1)
        self.assertEqual(self.store.profile_raw(self.uid)['attrs']['dn_stone'], before)


if __name__ == '__main__':
    unittest.main()
