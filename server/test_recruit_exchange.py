"""Daily medal equipment exchange and the recruit config overlay."""
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

    def test_daily_medal_equipment_purchase_cost_day_and_replay(self):
        from daily_exchange_105 import MEDAL_EQUIPMENT
        from gateway import load_game_config
        self.config=load_game_config(Path(__file__).resolve().parents[1]/'config/reconstruction/full-config.json')
        self.economy=GameplayEconomy(self.store,self.config)
        self.seed(medal=200)
        info = self.economy.dispatch(self.uid, 'user.recruit_exchange_info', {})
        items=[item for item in info['items'] if item['kind']=='equip']
        qualities = [item['quality'] for item in items]
        self.assertEqual((qualities.count(6), qualities.count(5)), (10, 10))
        self.assertEqual(len({item['id'] for item in items}), 20)
        prices = {int(q): price for q, _, price in MEDAL_EQUIPMENT}
        item = items[0]
        self.assertEqual(item['medal'], prices[item['quality']])
        params = {'id': item['id'], 'day': info['day'], 'actionID': 'medal-once'}
        first = self.economy.dispatch(self.uid, 'user.recruit_medal_exchange', params)
        self.assertEqual((first['medal'], first['id'], len(first['equip'])), (200 - item['medal'], item['id'], 1))
        self.assertEqual(next(iter(first['equip'].values()))['eid'], item['id'])
        replay = self.economy.dispatch(self.uid, 'user.recruit_medal_exchange', params)
        self.assertTrue(replay['replayed'])
        self.assertEqual(self.store.profile(self.uid)['medal'], 200 - item['medal'])
        for invalid in ({'id': 'E_9999_6', 'day': info['day'], 'actionID': 'unknown'},
                        {'id': item['id'], 'day': '2000-01-01', 'actionID': 'stale'}):
            with self.assertRaises(GameplayFault):
                self.economy.dispatch(self.uid, 'user.recruit_medal_exchange', invalid)
        self.seed(medal=item['medal'] - 1)
        with self.assertRaises(GameplayFault) as low:
            self.economy.dispatch(self.uid, 'user.recruit_medal_exchange',
                                  {'id': item['id'], 'day': info['day'], 'actionID': 'low'})
        self.assertEqual(low.exception.code, 'InsufficientMedal')

    def test_medal_equipment_rotates_at_shanghai_midnight(self):
        from daily_exchange_105 import daily_medal_offers
        before = datetime.datetime(2026, 10, 16, 15, 59, 59, tzinfo=datetime.timezone.utc).timestamp()
        day, items = daily_medal_offers(self.config, before)
        next_day, next_items = daily_medal_offers(self.config, before + 1)
        self.assertEqual((day, next_day), ('2026-10-16', '2026-10-17'))
        self.assertNotEqual([i['id'] for i in items], [i['id'] for i in next_items])
        exclusive = set(self.config['cfg']['system_simple'].get('equipment_roll_policy', {}).get('exclusive_ids', []))
        self.assertFalse({i['id'] for i in items} & exclusive)
        self.assertTrue(all(i['id'].split('_')[1][0] in '1345' for i in items))

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
