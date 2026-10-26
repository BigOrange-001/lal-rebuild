"""Daily medal recruitment and the two explicitly approved skin-soul offers."""
import copy
import datetime
import json
import sqlite3
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from gameplay_common import game_day, grant_reward
from gameplay_economy import GameplayEconomy
from gameplay_roster import GameplayRosterEquipment
from player_store import GameplayFault, PlayerStore
from recruit_exchange import (MEDAL_PRICE, SKIN_SOUL_IDS,
                              apply_recruit_exchange_config, daily_orange_list)
from upstream_hero_config import apply_upstream_hero_config


class RecruitExchangeTest(unittest.TestCase):
    def setUp(self):
        root = Path(__file__).resolve().parents[1]
        self.config = json.loads((root / 'config/reconstruction/full-config.json').read_text(encoding='utf8'))
        apply_recruit_exchange_config(self.config)
        self.db = sqlite3.connect(':memory:', check_same_thread=False)
        self.addCleanup(self.db.close)
        self.store = PlayerStore(self.db, self.config)
        self.uid = self.store.login('daily-recruit-test')['uid']
        self.economy = GameplayEconomy(self.store, self.config)
        self.roster = GameplayRosterEquipment(self.store, self.config)

    def seed(self, **changes):
        def mutate(profile):
            profile.update(changes)
            return profile, {}
        self.store.atomic_update(self.uid, mutate)

    def test_twenty_distinct_playable_cards_and_shanghai_rollover(self):
        before = datetime.datetime(2026, 10, 16, 15, 59, 59, tzinfo=datetime.timezone.utc)
        after = before + datetime.timedelta(seconds=1)
        day, aids = daily_orange_list(self.config, before)
        next_day, next_aids = daily_orange_list(self.config, after)
        self.assertEqual((day, next_day), ('2026-10-16', '2026-10-17'))
        self.assertEqual(len(aids), len(set(aids)))
        self.assertEqual(len(aids), 20)
        self.assertNotEqual(aids, next_aids)
        self.assertFalse(set(aids + next_aids) & set(self.config['cfg']['system_simple']['skin_acquisition_blocked_heroes']))
        self.assertTrue(all(self.config['cfg']['avatar'][aid]['tl'][4] == 99 for aid in aids))

    def test_config_is_idempotent_and_skin_souls_can_be_synthesized(self):
        first = copy.deepcopy(self.config)
        apply_recruit_exchange_config(self.config)
        self.assertEqual(self.config, first)
        cfg = self.config['cfg']
        self.assertNotIn('A_1009_6', cfg['avatar'])
        self.assertNotIn('A_1009_6', cfg['system_simple']['skin_acquisition_blocked_heroes'])
        self.assertEqual(cfg['avatar']['A_1226_6']['name'], '二郎真君赵信')
        self.assertEqual(cfg['avatar']['A_1226_6']['pl'][10:14],
                         ['S_201226_6', 'S_301226_6', 'E_008', 'S_401226_6'])
        self.assertEqual(cfg['avatar']['A_1226_6']['pl'][:8],
                         [12731, 519.6326530612245, 1805, 73.6734693877551,
                          587, 23.959183673469386, 1024, 41.795918367346935])
        self.assertEqual(cfg['avatar']['A_1310_6']['name'], '钢铁侠提莫')
        self.assertEqual(cfg['avatar']['A_1310_6']['pl'][:8],
                         [13848, 565.2244897959183, 2718, 110.93877551020408,
                          909, 37.10204081632653, 794, 32.40816326530612])
        self.assertEqual(cfg['ploy_system_simple']['extract_avatar']['exchange'],
                         [[{'avatar_soul': {aid: 40}}, 100] for aid in SKIN_SOUL_IDS])
        self.seed(attrs={**self.store.profile(self.uid)['attrs'],
                         'lottery_activity': {'score': 1600}, 'avatar_len': 100})
        for index, aid in enumerate(SKIN_SOUL_IDS):
            for i in range(8):
                self.economy.dispatch(self.uid, 'user.exchange_activity_avatar',
                                      {'index': index, 'actionID': f'skin-points-{index}-{i}'})
        profile = self.store.profile(self.uid)
        for aid in SKIN_SOUL_IDS:
            self.assertEqual(profile['avatar_soul'][aid], 320)
            self.assertEqual(profile['attrs']['tower_skin_soul_credit'][aid], 320)
        self.assertEqual(profile['attrs']['lottery_activity']['score'], 0)
        for aid in SKIN_SOUL_IDS:
            composed = self.roster.dispatch(self.uid, 'user.soul_exchange_avatar',
                                            {'aid': aid, 'num': 1, 'actionID': 'skin-compose-' + aid})
            self.assertEqual(len(composed['new_avatars']), 1)
        profile = self.store.profile(self.uid)
        for aid in SKIN_SOUL_IDS:
            self.assertEqual(profile['avatar_soul'][aid], 0)
            self.assertEqual(profile['attrs']['tower_skin_soul_credit'][aid], 320)
            grant_reward(profile, {'heroes': [{'aid': aid, 'num': 1}]}, self.config)

    def test_rejected_fake_form_is_removed_from_an_older_overlay(self):
        document = copy.deepcopy(self.config)
        cfg = document['cfg']
        fake = copy.deepcopy(cfg['avatar']['A_1009_5'])
        fake.update(id='A_1009_6', name='二郎神赵信', res='A_1009_5',
                    skin_exchange_only=True)
        cfg['avatar']['A_1009_6'] = fake
        cfg['system_simple']['skin_acquisition_blocked_heroes'].append('A_1009_6')
        apply_recruit_exchange_config(document)
        self.assertNotIn('A_1009_6', cfg['avatar'])
        self.assertNotIn('A_1009_6', cfg['system_simple']['skin_acquisition_blocked_heroes'])
        self.assertNotIn('A_1009_6', str(cfg['ploy_system_simple']['extract_avatar']['exchange']))

    def test_medal_purchase_cost_capacity_day_and_replay(self):
        self.seed(medal=160)
        info = self.economy.dispatch(self.uid, 'user.recruit_exchange_info', {})
        self.assertEqual(info['cost'], MEDAL_PRICE)
        self.assertEqual(len(info['heroes']), 20)
        aid = info['heroes'][0]['aid']
        with self.assertRaises(GameplayFault) as legacy:
            self.economy.dispatch(self.uid, 'user.medal_exchange',
                                  {'exch_type': 'avatar', 'exch_id': aid,
                                   'need_medal': 20, 'actionID': 'legacy-discount'})
        self.assertEqual(legacy.exception.code, 'DailyRecruitRequired')
        self.assertEqual(self.store.profile(self.uid)['medal'], 160)
        params = {'aid': aid, 'day': info['day'], 'actionID': 'recruit-once'}
        first = self.economy.dispatch(self.uid, 'user.recruit_medal_exchange', params)
        self.assertEqual((first['medal'], first['aid'], len(first['avatar'])), (80, aid, 1))
        self.assertFalse(first['replayed'])
        replay = self.economy.dispatch(self.uid, 'user.recruit_medal_exchange', params)
        self.assertTrue(replay['replayed'])
        self.assertEqual(replay['avatar'], first['avatar'])
        self.assertEqual(self.store.profile(self.uid)['medal'], 80)
        with self.assertRaises(GameplayFault) as reused:
            self.economy.dispatch(self.uid, 'user.recruit_medal_exchange',
                                  {**params, 'aid': info['heroes'][1]['aid']})
        self.assertEqual(reused.exception.code, 'RequestKeyConflict')
        for invalid in ({'aid': 'A_1009_6', 'day': info['day'], 'actionID': 'skin'},
                        {'aid': aid, 'day': '2000-01-01', 'actionID': 'stale'}):
            with self.assertRaises(GameplayFault):
                self.economy.dispatch(self.uid, 'user.recruit_medal_exchange', invalid)
        profile = self.store.profile(self.uid)
        self.assertEqual(profile['medal'], 80)
        profile['attrs']['avatar_len'] = len(profile['avatars'])
        self.seed(attrs=profile['attrs'])
        with self.assertRaises(GameplayFault) as full:
            self.economy.dispatch(self.uid, 'user.recruit_medal_exchange',
                                  {'aid': aid, 'day': info['day'], 'actionID': 'full'})
        self.assertEqual(full.exception.code, 'AvatarCapacity')
        profile = self.store.profile(self.uid)
        profile['attrs']['avatar_len'] += 1
        self.seed(attrs=profile['attrs'], medal=79)
        with self.assertRaises(GameplayFault) as low:
            self.economy.dispatch(self.uid, 'user.recruit_medal_exchange',
                                  {'aid': aid, 'day': info['day'], 'actionID': 'low'})
        self.assertEqual(low.exception.code, 'InsufficientMedal')
        self.assertEqual(self.store.profile(self.uid)['medal'], 79)

    def test_only_two_point_offers_and_insufficient_points_are_atomic(self):
        self.seed(attrs={**self.store.profile(self.uid)['attrs'],
                         'lottery_activity': {'score': 100}})
        before = self.store.profile_raw(self.uid)
        with self.assertRaises(GameplayFault) as unavailable:
            self.economy.dispatch(self.uid, 'user.exchange_activity_avatar',
                                  {'index': 2, 'actionID': 'unverified-offer'})
        self.assertEqual(unavailable.exception.code, 'UnknownExchange')
        self.assertEqual(self.store.profile_raw(self.uid), before)
        result = self.economy.dispatch(self.uid, 'user.exchange_activity_avatar',
                                       {'index': 0, 'actionID': 'erlang-points'})
        self.assertEqual((result['score'], result['avatar_soul']),
                         (0, {'A_1226_6': 40}))
        self.assertEqual(self.store.profile(self.uid)['attrs']['tower_skin_soul_credit']['A_1226_6'], 40)
        replay = self.economy.dispatch(self.uid, 'user.exchange_activity_avatar',
                                       {'index': 0, 'actionID': 'erlang-points'})
        self.assertTrue(replay['replayed'])
        with self.assertRaises(GameplayFault) as low:
            self.economy.dispatch(self.uid, 'user.exchange_activity_avatar',
                                  {'index': 0, 'actionID': 'no-points'})
        self.assertEqual(low.exception.code, 'ActivityScoreLow')
        self.assertEqual(self.store.profile(self.uid)['avatar_soul'].get('A_1226_6', 0), 40)

    def test_upstream_snapshot_has_all_config_changes_and_preserves_unrelated_fields(self):
        root = Path(__file__).resolve().parents[1]
        delta = json.loads((root / 'server/upstream_hero_config_delta.json').read_text(encoding='utf8'))
        self.assertEqual(set(delta['avatar']),
                         {'A_1226_5', 'A_1226_6', 'A_1310_5', 'A_1310_6',
                          'A_2003_2', 'A_2018_2', 'A_2024_6', 'A_2003_3'})
        self.assertEqual((len(delta['skill']), len(delta['effect'])), (20, 4))
        document = copy.deepcopy(self.config)
        document['cfg'].pop('upstream_hero_config_overlay')
        document['cfg']['avatar']['A_1226_6']['name'] = '橙阶英雄·序号226'
        document['cfg']['avatar']['A_1226_6']['local_only'] = 'keep'
        document['cfg']['skill']['S_301310_6']['captainSummonMultiplier'] = 1.5
        apply_upstream_hero_config(document)
        self.assertEqual(document['cfg']['avatar']['A_1226_6']['name'], '二郎真君赵信')
        self.assertEqual(document['cfg']['avatar']['A_1226_6']['local_only'], 'keep')
        self.assertEqual(document['cfg']['skill']['S_301310_6']['captainSummonMultiplier'], 1.5)
        marker = document['cfg']['upstream_hero_config_overlay']
        self.assertEqual(marker['schema'], 'upstream-hero-config-v1')
        self.assertEqual(marker['source_commit'], delta['source_commit'])
        self.assertEqual(len(marker['delta_sha256']), 64)
        document['cfg']['skill']['S_201310_6']['info'] = 'downstream tempo balance'
        document['cfg']['avatar']['A_1310_6']['pl'][0] = 99999
        first = copy.deepcopy(document)
        apply_upstream_hero_config(document)
        apply_recruit_exchange_config(document)
        self.assertEqual(document, first)


if __name__ == '__main__':
    unittest.main()
