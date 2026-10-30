"""Final-config acquisition rules and real wallet/roster transactions."""
import copy
import random
import unittest
from pathlib import Path
from unittest.mock import patch

from gateway import Backend
from gameplay_common import grant_reward
from gameplay_economy import GameplayEconomy
from gameplay_roster import GameplayRosterEquipment
from hero_drop import roll_campaign_hero_drop
from player_store import GameplayFault
from skin_acquisition_104 import apply_skin_acquisition_104
from summon_pools import SummonPools
from tower_rewards_103 import roll_tower_reward


class SkinAcquisition104Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.backend = Backend(':memory:', Path(__file__).resolve().parents[1] /
                              'config/reconstruction/full-config.json')
        cls.document = cls.backend.config
        cls.cfg = cls.document['cfg']
        cls.tiers = {r['id']: r['tier'] for r in cls.cfg['skin_acquisition_104']['heroes']}

    @classmethod
    def tearDownClass(cls):
        cls.backend.db.close()

    def setUp(self):
        self.store = self.backend.players
        self.uid = self.store.login(self.id())['uid']
        self.economy = GameplayEconomy(self.store, self.document)
        self.roster = GameplayRosterEquipment(self.store, self.document)

    def seed(self, fn):
        def mutate(p):
            fn(p)
            return p, {}
        self.store.atomic_update(self.uid, mutate)

    def test_exact_weights_membership_and_quality_rates(self):
        self.assertEqual(list(self.tiers.values()).count('T1'), 19)
        self.assertEqual(list(self.tiers.values()).count('T2'), 16)
        for pool in ('normal', 'advanced', 'vip'):
            qualities = self.cfg['summon_calibration']['pools'][pool]['qualities']
            self.assertEqual(qualities['orange']['probability_percent'],
                             {'normal': 0, 'advanced': 2, 'vip': 5}[pool])
            for quality, row in qualities.items():
                for card in row['cards']:
                    family = card['id'].rsplit('_', 1)[0]
                    tier = self.tiers.get(family + '_6')
                    expected = {'T1': .1, 'T2': .2}.get(tier, 1)
                    if pool == 'advanced' and quality == 'purple' and tier:
                        expected = .1
                    self.assertEqual(card['weight'], expected)
            if pool != 'normal':
                self.assertTrue(set(self.tiers) <= {c['id'] for c in qualities['orange']['cards']})
        clone = copy.deepcopy(self.document)
        apply_skin_acquisition_104(clone)
        self.assertEqual(clone, self.document)

    def test_native_exchange_schema_has_only_all_t2_whole_cards(self):
        extract = self.cfg['ploy_system_simple']['extract_avatar']
        self.assertEqual({next(iter(r[0]['avatar'])) for r in extract['exchange']},
                         {aid for aid, tier in self.tiers.items() if tier == 'T2'})
        self.assertTrue(all(r[1] == 300 and list(r[0]['avatar'].values()) == [1]
                            for r in extract['exchange']))

    def test_all_sixteen_exchanges_grant_one_card_at_300(self):
        self.seed(lambda p: p['attrs'].update(lottery_activity={'score': 4800}, avatar_len=100))
        for index, row in enumerate(self.cfg['ploy_system_simple']['extract_avatar']['exchange']):
            params = {'index': index, 'actionID': 'purchase-' + str(index)}
            result = self.economy.exchange_activity_avatar(self.uid, params)
            self.assertEqual([h['aid'].split('|')[0] for h in result['avatar'].values()], list(row[0]['avatar']))
            replay = self.economy.exchange_activity_avatar(self.uid, params)
            self.assertTrue(replay['replayed'])
            self.assertEqual(result['avatar'], replay['avatar'])
        self.assertEqual(self.store.profile(self.uid)['attrs']['lottery_activity']['score'], 0)

    def test_exchange_full_roster_and_low_balance_roll_back(self):
        self.seed(lambda p: p['attrs'].update(lottery_activity={'score': 300}, avatar_len=len(p['avatars'])))
        before = self.store.profile_raw(self.uid)
        with self.assertRaises(GameplayFault) as error:
            self.economy.exchange_activity_avatar(self.uid, {'index': 0, 'actionID': 'full'})
        self.assertEqual(error.exception.code, 'AvatarCapacity')
        self.assertEqual(self.store.profile_raw(self.uid), before)
        self.seed(lambda p: p['attrs'].update(lottery_activity={'score': 299}, avatar_len=100))
        with self.assertRaises(GameplayFault) as error:
            self.economy.exchange_activity_avatar(self.uid, {'index': 0, 'actionID': 'poor'})
        self.assertEqual(error.exception.code, 'ActivityScoreLow')

    def test_no_global_acquisition_gate_is_added(self):
        self.assertEqual(self.cfg['system_simple']['skin_acquisition_blocked_heroes'], [])
        p = copy.deepcopy(self.store.profile(self.uid))
        for aid, tier in self.tiers.items():
            if tier == 'T1':
                grant_reward(p, {'avatar': {aid: 1}, 'avatar_soul': {aid: 1}}, self.document)
                self.assertEqual(p['avatar_soul'][aid], 1)
        timed = self.cfg['ploy_system_simple']['timed_exchange']
        self.assertFalse(any(set(row) & {a for a, t in self.tiers.items() if t == 'T1'} for row in timed))

    def test_t1_purple_to_orange_promotion_stays_open(self):
        def seed(p):
            p['avatars'] = {'A_1226_5|promotion': dict(id='A_1226_5|promotion',
                aid='A_1226_5|promotion', lv=99, slv=7, phase=2, morph=0, exp=0)}
            p['team'] = [[None] * 6 for _ in range(3)]
            p['attrs']['dn'] = {}
            p['coin'] = 100000
            p['gold'] = 10000000
            p['attrs']['dust'] = [10000] * 4
        self.seed(seed)
        result = self.roster.dispatch(self.uid, 'user.star_up',
            {'aid': 'A_1226_5|promotion', 'aids': [], 'actionID': 't1-promote'})
        self.assertEqual(result['id'], 'A_1226_6|promotion')
        self.assertEqual(result['slv'], 7)

    def test_t1_advanced_and_vip_draws_are_authorized(self):
        self.seed(lambda p: (p.update(coin=10000, vip_lv=8), p['attrs'].update(avatar_len=100)))
        with patch.object(self.roster.summon_pools, 'draw', return_value='A_1226_6'):
            result = self.roster.dispatch(self.uid, 'user.wager_avatar',
                                         {'wager_type': 'coin', 'times': 1, 'actionID': 'rare-advanced'})
        self.assertEqual(next(iter(result['new_avatars'].values()))['aid'].split('|')[0], 'A_1226_6')
        with patch.object(self.economy.summon_pools, 'draw', return_value='A_1226_6'):
            result = self.economy.get_lottery_activity(self.uid, {'flag': 0, 'actionID': 'rare-vip'})
        self.assertIn('avatar', result['avatars'])

    def test_tower_uses_same_fractional_weights_and_grants_provenance(self):
        pools = SummonPools.from_config(self.document)
        weights = dict(pools._cards['vip', 'orange'][0])
        self.assertEqual(weights['A_1226_6'] * 10, weights['A_1022_6'])
        self.assertEqual(weights['A_1310_6'] * 5, weights['A_1022_6'])
        stage = self.cfg['combat_ploy']['P_200_180']
        with patch.object(SummonPools, 'draw_quality', return_value=['A_1226_6'] +
                          [aid for aid in weights if aid != 'A_1226_6'][:9]):
            reward = roll_tower_reward(self.document, stage, random.Random(1))
        self.assertIn('A_1226_6', reward['avatar_soul'])
        p = copy.deepcopy(self.store.profile(self.uid))
        grant_reward(p, reward, self.document, allow_skin=True)

    def test_campaign_t1_rare_drop_threshold_is_weighted(self):
        aid = 'A_1134_6'  # An orange-only T1 family.
        document = copy.deepcopy(self.document)
        for key in list(document['cfg']['avatar']):
            if key.startswith('A_1134_') and key != aid:
                del document['cfg']['avatar'][key]
        stage = {'team2': [[aid, 0, .2]], 'hero_drop_candidates_by_diff': {'0': [
            {'aid': aid, 'enemy_aid': aid, 'family': 'A_1134', 'star': 6, 'chance_bp': 20}]}}
        class Ticket:
            def __init__(self, ticket): self.ticket = ticket
            def choice(self, rows): return rows[0]
            def randrange(self, stop): return self.ticket
        self.assertEqual(roll_campaign_hero_drop(document, stage, 'M_001_1', 0, True, Ticket(1)), aid)
        self.assertIsNone(roll_campaign_hero_drop(document, stage, 'M_001_1', 0, True, Ticket(2)))


if __name__ == '__main__':
    unittest.main()
