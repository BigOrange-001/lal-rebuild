"""Chapters 31-60: power curve, rosters, even hero usage, rewards, copy and live play."""
import random
import re
import sqlite3
import unittest
from collections import Counter
from pathlib import Path
from unittest.mock import patch

from battle_engine import serialize_stage_team
from campaign_expansion_106 import (CHAPTERS, FINALE_POWER, FIRST_CHAPTER, HEROES, HP_LIMIT,
                                    LANE_NAMES, LAST_CHAPTER, LEGEND_CHAPTER, MINIONS, POOL,
                                    SKILL_LEVEL, STAGES, chapter_act, lane_count, parse_lanes,
                                    roll_hero_card, roll_relic)
from campaign_workbook_overlay import _power
from equipment_elite_drop import roll_elite_drop
from gameplay_combat import GameplayCombat
from gameplay_common import equipment_exclusive_ids
from gateway import load_game_config
from hero_catalog_105 import is_abandoned
from hero_drop import roll_campaign_hero_drop
from hero_workshop import is_test_hero
from player_copy_104 import CHAPTER_TITLES_104, STAGE_TITLES_104
from player_store import GameplayFault, PlayerStore
from power_balance_104 import normalize_team_power

CONFIG = Path(__file__).resolve().parents[1] / 'config/reconstruction/full-config.json'
NEW = [f'M_{c:03d}_{s}' for c in range(FIRST_CHAPTER, LAST_CHAPTER + 1) for s in range(1, STAGES + 1)]


def mentioned(text):
    """Hero aliases in text, longest match first (源计划亚索 is not 亚索)."""
    names, index = [], 0
    ordered = sorted(HEROES, key=len, reverse=True)
    while index < len(text):
        name = next((n for n in ordered if text.startswith(n, index)), None)
        if name:
            names.append(name)
            index += len(name)
        else:
            index += 1
    return names


def authored(chapter, number):
    return CHAPTERS[chapter - FIRST_CHAPTER][3][number - 1]


class CampaignExpansion106Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.doc = load_game_config(CONFIG)
        cls.cfg = cls.doc['cfg']
        with patch('campaign_expansion_106.apply_campaign_expansion'):
            cls.before = load_game_config(CONFIG)['cfg']

    def stage(self, cid):
        return self.cfg['combat_main'][cid]

    def test_chapters_one_to_thirty_are_unchanged(self):
        for table in ('combat_main', 'battle_main'):
            for key, value in self.before[table].items():
                self.assertEqual(self.cfg[table][key], value, key)
        for diff, gifts in self.before['pass_battle_gift'].items():
            for key, value in gifts.items():
                self.assertEqual(self.cfg['pass_battle_gift'][diff][key], value)
        old = self.before['system_simple']['elite_equipment_drop']['tiers']
        self.assertEqual(self.cfg['system_simple']['elite_equipment_drop']['tiers'][:len(old)], old)

    def test_thirty_chapters_of_five_stages_in_every_table_copy(self):
        self.assertEqual(len(CHAPTERS), 30)
        for holder in (self.cfg, self.doc, self.doc['pve']):
            for chapter in range(FIRST_CHAPTER, LAST_CHAPTER + 1):
                row = holder['battle_main'][f'M_{chapter:03d}']
                self.assertEqual((row['combat'], row['indexID_s'], row['ulv']), (STAGES, chapter, 1))
            self.assertNotIn('M_061', holder['battle_main'])
            self.assertTrue(all(cid in holder['combat_main'] for cid in NEW))
        self.assertEqual(len(self.cfg['combat_main']), 135 + 150)

    def test_finales_reach_twenty_and_three_hundred_billion_on_a_rising_curve(self):
        for diff, target in FINALE_POWER.items():
            shown = self.stage('M_060_5')['recommended_power_by_diff'][diff]
            self.assertGreaterEqual(shown, target)
            self.assertLess((shown - target) / target, 1e-5)
            previous = self.stage('M_030_3')['recommended_power_by_diff'][diff]
            for cid in NEW:
                value = self.stage(cid)['recommended_power_by_diff'][diff]
                self.assertGreater(value, previous, (cid, diff))
                previous = value
        self.assertEqual(self.stage('M_060_5')['recommended_power'],
                         self.stage('M_060_5')['recommended_power_by_diff']['0'])

    def test_recommendations_are_the_real_enemy_snapshots(self):
        for cid in NEW:
            stage = self.stage(cid)
            for diff in ('0', '1'):
                team = stage['team2_by_diff'].get(diff, stage['team2'])
                rows = stage['enemy_unit_stats_by_diff'][diff]
                self.assertEqual([r[0] for r in team], [r['aid'] for r in rows])
                actual = _power(self.cfg, team, rows)
                self.assertEqual(actual, stage['recommended_power_original_104'][diff])
                self.assertEqual(stage['recommended_power_by_diff'][diff], normalize_team_power(actual))
                self.assertLessEqual(max(r['hp'] for r in rows), HP_LIMIT)
                self.assertTrue(all(type(r[k]) is int and r[k] >= 1
                                    for r in rows for k in ('hp', 'ap', 'de_ph', 'de_ma')))

    def test_rosters_are_native_valid_on_one_two_and_three_lane_maps(self):
        minions = set(MINIONS.values())
        for chapter, (_, boss, guests, stages) in enumerate(CHAPTERS, FIRST_CHAPTER):
            act = chapter_act(chapter)
            for number, (_, _, _, lineup, _) in enumerate(stages, 1):
                stage = self.stage(f'M_{chapter:03d}_{number}')
                lanes = lane_count(lineup)
                self.assertEqual((stage['line'][0], len(stage['line'][1])), (lanes, lanes))
                normal, elite = stage['team2'], stage['team2_by_diff']['1']
                named = {HEROES[name] for _, name, _ in parse_lanes(lineup) if name in HEROES}
                for diff, team in (('0', normal), ('1', elite)):
                    self.assertEqual({row[3] for row in team}, set(range(lanes)))
                    self.assertEqual(len(team), len(parse_lanes(lineup)))
                    self.assertEqual(len({row[0] for row in team}), len(team))
                    self.assertLessEqual(named, {row[0] for row in team})
                    self.assertEqual(sum(row[5] for row in team), 1)
                    self.assertTrue(all(row[2] == SKILL_LEVEL[diff][act] for row in team))
                    self.assertEqual(len({(r[3], r[4], r[11]) for r in team}), len(team))
                    for row in team:
                        expected = 99 if number != STAGES or row[5] else 98
                        self.assertEqual(row[1], expected)
                        self.assertTrue(0 < row[4] <= .5 and abs(row[11]) <= .5)
                        self.assertEqual(row[12], self.cfg['avatar'][row[0]]['pl'][9])
                        self.assertFalse(is_abandoned(self.cfg, row[0]) or is_test_hero(self.cfg, row[0]))
                        self.assertTrue(row[0] in minions or row[0] in POOL)
                        # Legends join the filler pool after leading their chapter;
                        # the elite finale guest previews the next chapter's boss.
                        guest = diff == '1' and number == STAGES and row[0] not in named
                        allowed = chapter + (2 if guest else 1 if row[0] in named else 0)
                        self.assertLess(LEGEND_CHAPTER.get(row[0], 0), allowed)
                    serialize_stage_team(self.cfg, team, team=2)
                if number == STAGES:
                    self.assertEqual(next(row[0] for row in normal if row[5]), HEROES[boss])
                    self.assertEqual(stage['win'], [-2])
                normal_minions = sum(row[0] in minions for row in normal)
                elite_minions = sum(row[0] in minions for row in elite)
                self.assertEqual(elite_minions, max(0, normal_minions - 1))
                if number == STAGES and normal_minions:
                    guest = next(HEROES[name] for name in guests if HEROES[name] not in named)
                    self.assertIn(guest, {row[0] for row in elite})

    def test_every_hero_gets_a_similar_number_of_fights_early_and_late(self):
        regular = [aid for aid in POOL if aid not in LEGEND_CHAPTER]
        for diff, spread in (('0', 2), ('1', 3)):
            usage, late = Counter(), Counter()
            for cid in NEW:
                stage = self.stage(cid)
                for row in stage['team2_by_diff'].get(diff, stage['team2']):
                    usage[row[0]] += 1
                    if int(cid[2:5]) > 45:
                        late[row[0]] += 1
            counts = [usage[aid] for aid in regular]
            self.assertLessEqual(max(counts) - min(counts), spread, diff)
            # Ordinary heroes stay in the late chapters, not only skins and legends.
            ordinary = [aid for aid in regular if aid[2:4] in ('10', '11')]
            self.assertTrue(all(late[aid] for aid in ordinary), [a for a in ordinary if not late[a]])
        maps = Counter(self.stage(cid)['line'][0] for cid in NEW)
        self.assertEqual(maps, {3: 114, 2: 30, 1: 6})

    def test_names_are_unique_short_and_clean(self):
        chapters = [name for name, *_ in CHAPTERS]
        self.assertTrue(all(len(name) == 4 for name in chapters))
        self.assertEqual(len(set(chapters) | set(CHAPTER_TITLES_104.values())), 60)
        titles = [title for *_, stages in CHAPTERS for title, *_ in stages]
        self.assertTrue(all(4 <= len(title) <= 7 for title in titles))
        self.assertEqual(len(set(titles) | set(STAGE_TITLES_104.values())), 285)
        for cid in NEW:
            stage = self.stage(cid)
            self.assertTrue(stage['name'].startswith(f'第{int(cid[2:5])}章·'))
            for word in ('封锁', '封口', '封门', '近卫', '最后的'):
                self.assertNotIn(word, stage['name'] + stage['info'])

    def test_card_text_names_only_heroes_on_the_field_and_their_lanes(self):
        for chapter in range(FIRST_CHAPTER, LAST_CHAPTER + 1):
            for number in range(1, STAGES + 1):
                _, _, _, lineup, text = authored(chapter, number)
                names = LANE_NAMES[lane_count(lineup)]
                lanes = {}
                for lane, name, _ in parse_lanes(lineup):
                    lanes.setdefault(name, set()).add(names[lane])
                for clause in re.split('[，；。]', text):
                    named = mentioned(clause)
                    for name in named:
                        self.assertIn(name, lanes, (chapter, number, name))
                    words = [word for word in ('左路', '中路', '右路') if word in clause]
                    if len(words) == 1:
                        for name in named:
                            self.assertIn(words[0], lanes[name], (chapter, number, clause))
                self.assertTrue(self.stage(f'M_{chapter:03d}_{number}')['info'].startswith(text))

    def test_written_front_and_back_order_holds_in_the_lane(self):
        # "A 挡在 B 身前" and friends: A must stand ahead of B in their lane.
        pairs = (('M_031_5', '拉莫斯', '阿木木'), ('M_035_5', '雷克顿', '阿兹尔'),
                 ('M_036_5', '维嘉', '马尔扎哈'), ('M_036_5', '马尔扎哈', '莫甘娜'),
                 ('M_037_3', '古拉加斯', '千珏'), ('M_037_5', '雷恩加尔', '卡兹克'),
                 ('M_038_5', '卡萨丁', '卡兹克'), ('M_039_5', '莫德凯撒', '锤石'),
                 ('M_040_5', '莫德凯撒', '卡尔萨斯'), ('M_041_5', '瑟庄妮', '泰达米尔'),
                 ('M_041_5', '泰达米尔', '艾希'), ('M_042_5', '瑟庄妮', '纳尔'),
                 ('M_043_5', '努努', '瑟庄妮'), ('M_044_5', '努努', '艾尼维亚'),
                 ('M_045_5', '努努', '丽桑卓'), ('M_046_5', '蕾欧娜', '潘森'),
                 ('M_047_5', '希瓦娜', '黛安娜'), ('M_048_5', '蕾欧娜', '塔里克'),
                 ('M_048_5', '塔里克', '索拉卡'), ('M_049_5', '蕾欧娜', '潘森'),
                 ('M_049_5', '潘森', '黛安娜'), ('M_050_5', '蕾欧娜', '凯尔'),
                 ('M_050_5', '凯尔', '莫甘娜'), ('M_051_5', '易大师', '白娘子'),
                 ('M_052_5', '李青', '二郎真君赵信'), ('M_053_5', '李青', '悟空'),
                 ('M_054_5', '易大师', '龙的传人李青'), ('M_055_5', '亚索', '敖兴'),
                 ('M_056_5', '莫德凯撒', '恶魔之刃泰达米尔'), ('M_056_5', '恶魔之刃泰达米尔', '泰达米尔'),
                 ('M_057_5', '菲兹', '大肥鱼！'), ('M_058_5', '苹果机器人布里茨', '冠军-卡密尔'),
                 ('M_059_5', '源计划亚索', '黑夜使者亚索'), ('M_060_4', '恶魔之刃泰达米尔', '冠军-卡密尔'),
                 ('M_060_5', '恶魔之刃泰达米尔', '神龙尊者卡莎'), ('M_060_5', '神龙尊者卡莎', '黑夜使者亚索'))
        for cid, front, back in pairs:
            for team in (self.stage(cid)['team2'], self.stage(cid)['team2_by_diff']['1']):
                rows = {row[0]: row for row in team}
                a, b = rows[HEROES[front]], rows[HEROES[back]]
                self.assertEqual(a[3], b[3], (cid, front, back))
                self.assertGreater(a[4], b[4], (cid, front, back))
        for cid, hero in (('M_031_1', '拉莫斯'), ('M_046_5', '蕾欧娜')):
            for team in (self.stage(cid)['team2'], self.stage(cid)['team2_by_diff']['1']):
                lane = next(row[3] for row in team if row[0] == HEROES[hero])
                self.assertEqual(max((row[4], row[0]) for row in team if row[3] == lane)[1], HEROES[hero])

    def test_aliases_match_hero_names(self):
        for name, aid in HEROES.items():
            self.assertEqual(self.cfg['avatar'][aid]['name'], name)
            self.assertIn(aid, POOL)
        for aid in MINIONS.values():
            self.assertIn(aid, self.cfg['avatar'])

    def test_rewards_gifts_and_first_clear_items(self):
        exclusive = set(equipment_exclusive_ids(self.cfg))
        for cid in NEW:
            chapter, number = int(cid[2:5]), int(cid[6:])
            stage = self.stage(cid)
            reward = stage['reward']
            self.assertEqual((stage['gold'], stage['exp']), (reward['gold'], reward['exp']))
            self.assertEqual(stage['energy'], 5 if number == STAGES else 3)
            if number == STAGES:
                items = reward['first_clear']['items']
                self.assertEqual(len(items), 2 if chapter % 5 == 0 else 1)
                for item in items:
                    self.assertNotIn(item['eid'], exclusive)
                    self.assertIn(self.cfg['equip'][item['eid']]['name'], stage['info'])
                self.assertIn(f'洗练印记×{reward["first_clear"]["mark"]}', stage['info'])
                self.assertEqual(reward['attrs']['dn_stone'], 2 * chapter)
        for chapter in range(FIRST_CHAPTER, LAST_CHAPTER + 1):
            for diff, multiplier in (('0', 1), ('1', 2)):
                self.assertEqual(self.cfg['pass_battle_gift'][diff][f'M_{chapter:03d}'],
                                 {'need_star': 15, 'gift': {'coin': 60 * chapter * multiplier}})

    def test_elite_gear_and_hero_drops_roll_without_policy_faults(self):
        pool = set(self.cfg['system_simple']['elite_equipment_drop']['pools_by_quality']['6'])

        class Always(random.Random):
            def randrange(self, *args):
                return 0
        for chapter in (31, 45, 46, 60):
            self.assertIn(roll_elite_drop(self.doc, f'M_{chapter:03d}_1', 1, True, Always(1)), pool)
        self.assertIsNone(roll_elite_drop(self.doc, 'M_061_1', 1, True, random.Random(1)))
        rng = random.Random(7)
        dropping = 0
        for cid in NEW:
            stage = self.stage(cid)
            for diff in (0, 1):
                # Settlement validates against the roster of the mode fought.
                fought = dict(stage, team2=stage['team2_by_diff']['1'] if diff else stage['team2'])
                roll_campaign_hero_drop(self.doc, fought, cid, diff, rng)
            dropping += bool(stage['hero_drop_candidates_by_diff']['0'])
            for row in stage['hero_drop_candidates_by_diff']['1']:
                self.assertIn(row['enemy_aid'], {r[0] for r in stage['team2']})
                self.assertIn(row['enemy_aid'], {r[0] for r in stage['team2_by_diff']['1']})
        self.assertGreater(dropping, 120)

    def test_drop_and_sweep_rules_cover_new_chapters_only(self):
        for cid, stage in self.cfg['combat_main'].items():
            new = cid in NEW
            self.assertEqual('abyss_relic_drop_106' in stage, new, cid)
            self.assertEqual(stage.get('sweep_disabled'), True if new else self.before['combat_main'][cid].get('sweep_disabled'))
            if not new:
                continue
            self.assertEqual(stage['abyss_relic_drop_106'], {'1': {
                'chance_bp': 600 if cid.endswith('_5') else 300, 'max_ancient': 1}})
            self.assertIn('不可扫荡', stage['info'])
            cards = stage['campaign_card_drop_106']
            self.assertLessEqual(set(cards), {'0'})
            for aid in cards.get('0', {}).get('candidates', []):
                self.assertIn(aid, {row[0] for row in stage['team2']})
                self.assertRegex(aid, r'^A_1[01]\d\d_6$')

    def test_relic_rolls_are_retry_stable_and_never_two_ancient(self):
        stage = dict(self.stage('M_045_5'), abyss_relic_drop_106={'1': {'chance_bp': 10000, 'max_ancient': 1}})
        self.assertIsNone(roll_relic(self.doc, stage, 'M_045_5', 0, random.Random(1)))
        for seed in range(400):
            relic = roll_relic(self.doc, stage, 'M_045_5', 1, random.Random(seed))
            ancient = relic['main']['ancient'] + sum(a['ancient'] for a in relic['substats'])
            self.assertLessEqual(ancient, 1)
            self.assertEqual(relic, roll_relic(self.doc, stage, 'M_045_5', 1, random.Random(seed)))
        stage['abyss_relic_drop_106'] = {'1': {'chance_bp': 0, 'max_ancient': 1}}
        self.assertIsNone(roll_relic(self.doc, stage, 'M_045_5', 1, random.Random(1)))

    def test_orange_cards_come_from_the_regular_heroes_on_the_field(self):
        stage = self.stage('M_031_1')
        rule = stage['campaign_card_drop_106']['0']
        self.assertEqual(rule['chance_bp'], 100)
        forced = dict(stage, campaign_card_drop_106={'0': dict(rule, chance_bp=10000)})
        seen = {roll_hero_card(self.doc, forced, 'M_031_1', 0, random.Random(seed)) for seed in range(80)}
        self.assertEqual(seen, set(rule['candidates']))
        self.assertIsNone(roll_hero_card(self.doc, forced, 'M_031_1', 1, random.Random(1)))


class CampaignExpansionPlayTests(unittest.TestCase):
    """Real fights and sweeps on chapter 31 with the drops forced to happen."""

    @classmethod
    def setUpClass(cls):
        cls.config = load_game_config(CONFIG)
        stage = cls.config['cfg']['combat_main']['M_031_1']
        stage['campaign_card_drop_106']['0']['chance_bp'] = 10000
        stage['abyss_relic_drop_106']['1']['chance_bp'] = 10000

    def setUp(self):
        db = sqlite3.connect(':memory:', check_same_thread=False)
        self.addCleanup(db.close)
        self.store = PlayerStore(db, self.config)
        self.uid = self.store.login(self.id())['uid']
        self.combat = GameplayCombat(self.store, self.config)
        self.sequence = 0

        def seed(profile):
            # The pointers a player holds right after clearing chapter 30.
            profile.update(lv=125, cid='M_031_1', hid='M_031_1')
            profile['attrs'].update(energy_extra=100000, avatar_len=1000)
            return profile, {}
        self.store.atomic_update(self.uid, seed)
        avatars = list(self.store.profile_raw(self.uid)['avatars'])[:3]
        self.team = [[aid, lane, .2] for lane, aid in enumerate(avatars)]

    def action(self):
        self.sequence += 1
        return f'play{self.sequence}'

    def start(self, cid, diff):
        return self.combat._start_main(self.uid, {'cid': cid, 'diff': diff, 'team': self.team,
                                                  'actionID': self.action()})

    def clear(self, cid, diff):
        started = self.start(cid, diff)
        return self.combat._finish(self.uid, {'cid': cid, 'diff': diff, 'fight_id': started['fight_id'],
                                              'sign': 1, 'combat_star': 3, 'actionID': self.action()})

    def sweep(self, cid, diff):
        return self.combat.dispatch(self.uid, 'user.stage_sweep', {'cid': cid, 'diff': diff, 'times': 1,
                                                                   'max_coin': 0, 'actionID': self.action()})

    def test_fights_use_the_fitted_rosters_and_later_stages_stay_locked(self):
        for cid, diff in (('M_031_1', 0), ('M_031_1', 1)):
            result = self.start(cid, diff)
            expected = self.config['cfg']['combat_main'][cid]['enemy_unit_stats_by_diff'][str(diff)]
            self.assertEqual([unit['aid'] for unit in result['orgin_team_b']], [row['aid'] for row in expected])
            for unit, row in zip(result['orgin_team_b'], expected):
                for key in ('hp', 'ap', 'de_ph', 'de_ma'):
                    self.assertEqual(unit[key], row[key])
        with self.assertRaises(GameplayFault):
            self.start('M_031_2', 0)
        combat = self.combat
        self.assertEqual(combat._next_stage('M_030_3'), 'M_031_1')
        self.assertEqual(combat._next_stage('M_031_5'), 'M_032_1')
        self.assertEqual(combat._next_stage('M_060_5'), 'M_061_1')

    def test_normal_win_adds_orange_card_and_the_stage_cannot_be_swept(self):
        rule = self.config['cfg']['combat_main']['M_031_1']['campaign_card_drop_106']['0']
        before = set(self.store.profile_raw(self.uid)['avatars'])
        result = self.clear('M_031_1', 0)
        self.assertNotIn('abyss_relic_drop', result)
        gained = [str(hero['aid']).split('|')[0]
                  for iid, hero in self.store.profile_raw(self.uid)['avatars'].items() if iid not in before]
        self.assertTrue(set(gained) & set(rule['candidates']))
        self.assertEqual(self.store.profile_raw(self.uid)['cid'], 'M_031_2')
        with self.assertRaises(GameplayFault) as raised:
            self.sweep('M_031_1', 0)
        self.assertEqual(raised.exception.code, 'SweepLocked')

    def test_elite_win_adds_one_relic_and_the_stage_cannot_be_swept(self):
        result = self.clear('M_031_1', 1)
        relic = result['abyss_relic_drop']
        relics = self.store.profile_raw(self.uid)['abyss_relics']
        self.assertEqual(relics, {relic['id']: relic})
        self.assertEqual(result['abyss_relics'], relics)
        self.assertLessEqual(relic['main']['ancient'] + sum(a['ancient'] for a in relic['substats']), 1)
        with self.assertRaises(GameplayFault) as raised:
            self.sweep('M_031_1', 1)
        self.assertEqual(raised.exception.code, 'SweepLocked')
        self.assertEqual(self.store.profile_raw(self.uid)['abyss_relics'], relics)


if __name__ == '__main__':
    unittest.main()
