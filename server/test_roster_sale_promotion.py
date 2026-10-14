"""Hero bulk-sale and star-promotion boundaries on temporary profiles."""
import json
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from gameplay_roster import GameplayRosterEquipment
from player_store import GameplayFault, PlayerStore


class RosterSalePromotionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.config = json.loads((Path(__file__).resolve().parents[1] /
                                 'config/reconstruction/full-config.json').read_text(encoding='utf-8'))

    def setUp(self):
        self.db = sqlite3.connect(':memory:', check_same_thread=False)
        self.addCleanup(self.db.close)
        self.store = PlayerStore(self.db, self.config)
        self.uid = self.store.login('roster-promotion-test')['uid']
        self.roster = GameplayRosterEquipment(self.store, self.config)

    def test_bulk_sell_accepts_100_and_rejects_101_without_partial_sale(self):
        def seed(profile):
            profile['team'] = [[None] * 6 for _ in range(3)]
            profile['avatars'] = {
                f'A_1101_5|s{i}': {'id': f'A_1101_5|s{i}', 'aid': f'A_1101_5|s{i}',
                                  'lv': 1, 'phase': 0, 'morph': 0}
                for i in range(101)
            }
            return profile, {}
        self.store.atomic_update(self.uid, seed)
        ids = list(self.store.profile_raw(self.uid)['avatars'])
        before = self.store.profile_raw(self.uid)['gold']
        with self.assertRaises(GameplayFault) as caught:
            self.roster.dispatch(self.uid, 'user.sell_avatars', {'aids': ids, 'actionID': 'sell101'})
        self.assertEqual(caught.exception.code, 'InvalidSelection')
        self.assertEqual(len(self.store.profile_raw(self.uid)['avatars']), 101)
        sold = self.roster.dispatch(self.uid, 'user.sell_avatars', {'aids': ids[:100], 'actionID': 'sell100'})
        self.assertGreaterEqual(sold, before)
        self.assertEqual(self.roster.dispatch(self.uid, 'user.sell_avatars', {'aids': ids[:100], 'actionID': 'sell100'}), sold)
        self.assertEqual(set(self.store.profile_raw(self.uid)['avatars']), {ids[100]})

    def test_star_promotion_resets_phase_and_keeps_cultivation(self):
        target = 'A_1101_5|r0'
        material = 'A_1101_5|r7'
        def seed(profile):
            profile['team'] = [[None] * 6 for _ in range(3)]
            profile['avatars'] = {
                target: {'id': target, 'aid': target, 'lv': 99, 'exp': 0,
                         'phase': 3, 'morph': 0, 'limit_break': 0,
                         'hp': 11, 'ap': 2, 'de_ph': 1, 'de_ma': 1},
                material: {'id': material, 'aid': material, 'lv': 1, 'exp': 0,
                           'phase': 0, 'morph': 0, 'limit_break': 0},
            }
            profile['coin'] = 1000
            profile.setdefault('attrs', {})['dust'] = [10, 10, 10, 10]
            return profile, {}
        self.store.atomic_update(self.uid, seed)
        promoted = self.roster.dispatch(self.uid, 'user.star_up',
                                        {'aid': target, 'aids': [material], 'actionID': 'star-r0'})
        self.assertEqual(promoted['phase'], 0)
        self.assertEqual(promoted['id'], 'A_1101_6|r0')
        self.assertEqual(promoted.get('limit_break', 0), 0)
        self.assertEqual(self.roster.dispatch(self.uid, 'user.star_up',
                         {'aid': target, 'aids': [material], 'actionID': 'star-r0'}), promoted)
        profile = self.store.profile_raw(self.uid)
        self.assertEqual(set(profile['avatars']), {'A_1101_6|r0'})
        self.assertEqual(profile['avatars']['A_1101_6|r0']['phase'], 0)

    def test_sell_rejects_duplicate_team_dn_and_persisted_lock(self):
        ids = [f'A_1101_5|q{i}' for i in range(4)]
        def seed(profile):
            profile['team'] = [[ids[0]] + [None] * 5, [None] * 6, [None] * 6]
            profile['avatars'] = {
                aid: {'id': aid, 'aid': aid, 'lv': 1, 'phase': 0,
                      'lock': 1 if aid == ids[2] else 0}
                for aid in ids
            }
            profile['attrs']['dn'] = {'1': [1, ids[1]]}
            return profile, {}
        self.store.atomic_update(self.uid, seed)
        cases = [([ids[3], ids[3]], 'InvalidSelection'),
                 ([ids[3], ids[0]], 'HeroInTeam'),
                 ([ids[3], ids[1]], 'HeroInDestiny'),
                 ([ids[3], ids[2]], 'HeroLocked')]
        for sequence, (selected, expected) in enumerate(cases):
            with self.assertRaises(GameplayFault) as caught:
                self.roster.dispatch(self.uid, 'user.sell_avatars',
                                     {'aids': selected, 'actionID': f'protected-{sequence}'})
            self.assertEqual(caught.exception.code, expected)
            self.assertEqual(set(self.store.profile_raw(self.uid)['avatars']), set(ids))


if __name__ == '__main__':
    unittest.main()
