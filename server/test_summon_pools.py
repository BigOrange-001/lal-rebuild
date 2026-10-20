"""Deterministic calibration boundaries and real transaction integration."""
import copy
import json
import random
import sqlite3
import sys
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parent))
from player_store import PlayerStore, GameplayFault
from gameplay_common import grant_reward, skin_acquisition_blocked_ids
from gameplay_roster import GameplayRosterEquipment
from recruit_exchange import apply_recruit_exchange_config, daily_orange_pool
from summon_pools import SummonPools, confirm_custom_hero, _pick, _weighted
from decimal import Decimal


class SummonPoolsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        root = Path(__file__).resolve().parents[1]
        cls.document = json.loads((root / 'config/reconstruction/full-config.json').read_text('utf-8'))
        apply_recruit_exchange_config(cls.document)

    def test_shared_lists_probabilities_and_vip_skin_multiplier(self):
        c = self.document['cfg']['summon_calibration']
        for quality in ('blue', 'green', 'purple'):
            normal = c['pools']['normal']['qualities'][quality]['cards']
            for pool in ('advanced', 'vip'):
                self.assertEqual(c['pools'][pool]['qualities'][quality]['cards'], normal)
        self.assertEqual([c['pools'][p]['qualities']['orange']['probability_percent']
                          for p in ('normal', 'advanced', 'vip')], [0, 2, 5])
        advanced = {r['id']: r['weight'] for r in c['pools']['advanced']['qualities']['orange']['cards']}
        vip = {r['id']: r['weight'] for r in c['pools']['vip']['qualities']['orange']['cards']}
        self.assertEqual(set(advanced), set(vip))
        skins = set(self.document['cfg']['system_simple']['skin_hero_ids'])
        for aid, weight in advanced.items():
            self.assertEqual(vip[aid], weight * (2 if aid in skins else 1), aid)
        self.assertEqual((vip['A_1205_6'], vip['A_1226_6'], vip['A_1212_6']), (2, .04, .4))

    def test_decimal_weight_boundaries_are_exact(self):
        compiled = _weighted([('small', Decimal('.02')), ('large', Decimal('2'))])
        self.assertEqual(compiled[1], 202)
        for ticket, expected in ((0, 'small'), (1, 'small'), (2, 'large'), (201, 'large')):
            rng = unittest.mock.Mock()
            rng.randrange.return_value = ticket
            self.assertEqual(_pick(compiled, rng), expected)
        pools = SummonPools.from_config(self.document)
        rng = unittest.mock.Mock()
        rng.randrange.side_effect = [99, 0]
        self.assertTrue(pools.draw('vip', rng).endswith('_6'))
        self.assertEqual(rng.randrange.call_args_list[0].args, (100,))

    def test_invalid_active_pool_quality_and_rates_are_rejected(self):
        for mutation in ('empty', 'unknown', 'nan', 'sum', 'quality'):
            c = copy.deepcopy(self.document['cfg']['summon_calibration'])
            row = c['pools']['normal']['qualities']['white']
            if mutation == 'empty': row['cards'] = []
            elif mutation == 'unknown': row['cards'][0]['id'] = 'A_missing_2'
            elif mutation == 'nan': row['cards'][0]['weight'] = float('nan')
            elif mutation == 'sum': row['probability_percent'] = 71
            else: row['cards'][0]['id'] = 'A_1001_3'
            with self.subTest(mutation=mutation), self.assertRaises(GameplayFault):
                SummonPools(c, self.document['cfg']['avatar'])

    def test_custom_confirmation_weight_one_and_existing_weights_preserved(self):
        document = copy.deepcopy(self.document)
        cfg = document['cfg']
        aid = 'A_custom_6'
        cfg['avatar'][aid] = {'name': '自定义英雄'}
        before = copy.deepcopy(cfg['summon_calibration'])
        self.assertFalse(confirm_custom_hero(document, aid, confirmed=False))
        self.assertEqual(cfg['summon_calibration'], before)
        self.assertTrue(confirm_custom_hero(document, aid, confirmed=True))
        cfg['summon_calibration']['pools']['vip']['qualities']['orange']['cards'][-1]['weight'] = .125
        confirm_custom_hero(document, aid, confirmed=True)
        for pool in ('normal', 'advanced', 'vip'):
            row = cfg['summon_calibration']['pools'][pool]['qualities']['orange']
            self.assertEqual(row['cards'][-1]['weight'], .125 if pool == 'vip' else 1)
            self.assertEqual(row['probability_percent'], before['pools'][pool]['qualities']['orange']['probability_percent'])

    def test_applied_mod_channels_join_own_quality_without_mutating_base(self):
        doc = copy.deepcopy(self.document)
        cfg = doc['cfg']
        aid = 'A_custom_6'
        cfg['avatar'][aid] = {'name': '已确认英雄'}
        cfg['mod_runtime'] = {'heroes': {aid: {'kind': 'new', 'quality': 6, 'available': True,
            'channels': {'acquisition.summon.advanced': True, 'acquisition.summon.activity': False}}}}
        before = copy.deepcopy(cfg['summon_calibration'])
        pools = SummonPools.from_config(doc)
        self.assertIn(aid, dict(pools._cards['advanced', 'orange'][0]))
        self.assertNotIn(aid, dict(pools._cards['normal', 'orange'][0]))
        self.assertNotIn(aid, dict(pools._cards['vip', 'orange'][0]))
        self.assertEqual(cfg['summon_calibration'], before)

    def test_skin_acquisition_and_synthesis_no_longer_require_tower_credit(self):
        cfg = self.document['cfg']
        self.assertFalse(skin_acquisition_blocked_ids(cfg))
        self.assertTrue(all(not r.get('skin_exchange_only') for r in cfg['avatar'].values()))
        self.assertFalse(set(daily_orange_pool(cfg)) & set(cfg['system_simple']['skin_hero_ids']))
        db, store, uid, roster = self.store()
        skin = 'A_1226_6'
        def seed(p):
            grant_reward(p, {'heroes': [{'aid': skin, 'num': 1}]}, self.document)
            p['avatar_soul'][skin] = cfg['system_simple']['soul_exchange']['avatar']['6']
            return p, {}
        store.atomic_update(uid, seed)
        reply = roster.dispatch(uid, 'user.soul_exchange_avatar', {'aid': skin, 'num': 1, 'actionID': 'skin'})
        self.assertEqual(len(reply['new_avatars']), 1)

    def store(self):
        db = sqlite3.connect(':memory:', check_same_thread=False)
        self.addCleanup(db.close)
        store = PlayerStore(db, copy.deepcopy(self.document))
        uid = store.login('calibration-test')['uid']
        def seed(p):
            p.update(coin=100000, score=100000)
            return p, {}
        store.atomic_update(uid, seed)
        roster = next(h for h in store.gameplay_handlers if isinstance(h, GameplayRosterEquipment))
        return db, store, uid, roster

    def test_single_ten_draws_replay_and_old_pity_are_calibrated(self):
        _, store, uid, roster = self.store()
        roster.rng = random.Random(10)
        def seed(p):
            p['attrs']['wager_coin_1_count'] = 100000
            return p, {}
        store.atomic_update(uid, seed)
        for kind, times in (('score', 1), ('coin', 10)):
            params = {'wager_type': kind, 'times': times, 'actionID': kind}
            with patch.object(roster.summon_pools, 'draw', wraps=roster.summon_pools.draw) as draw:
                first = roster.dispatch(uid, 'user.wager_avatar', params)
                self.assertEqual(draw.call_count, times)
                before = store.profile_raw(uid)
                replay = roster.dispatch(uid, 'user.wager_avatar', params)
                self.assertEqual(draw.call_count, times)
            self.assertEqual(first['new_avatars'], replay['new_avatars'])
            self.assertEqual(store.profile_raw(uid), before)
            self.assertEqual(len(first['new_avatars']), times)
        self.assertEqual(store.profile(uid)['attrs']['wager_coin_1_count'], 0)

    def test_vip_only_full_cards_and_capacity_failure_is_atomic(self):
        _, store, uid, _ = self.store()
        params = {'flag': 1, 'actionID': 'vip-ten'}
        before = store.profile(uid)
        result = store.economy.get_lottery_activity(uid, params)
        self.assertEqual(len(result['avatars']['avatar']), 10)
        self.assertNotIn('avatar_soul', result['avatars'])
        after = store.profile(uid)
        self.assertEqual(after['avatar_soul'], before['avatar_soul'])
        self.assertEqual(after['attrs']['lottery_activity']['score'], before['attrs']['lottery_activity']['score'] + 10)
        replay = store.economy.get_lottery_activity(uid, params)
        self.assertTrue(replay['replayed'])
        self.assertEqual(store.profile(uid), after)
        def full(p):
            p['attrs']['avatar_len'] = len(p['avatars'])
            return p, {}
        store.atomic_update(uid, full)
        before = store.profile_raw(uid)
        with self.assertRaises(GameplayFault):
            store.economy.get_lottery_activity(uid, {'flag': 0, 'actionID': 'full'})
        self.assertEqual(store.profile_raw(uid), before)


if __name__ == '__main__':
    unittest.main()
