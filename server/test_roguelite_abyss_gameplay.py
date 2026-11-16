"""Route maps v2, up-to-three weak picks, randomized enemy formations, pool exclusions."""
import collections
import json
import unittest
from pathlib import Path

import test_roguelite_abyss as helpers
from roguelite_abyss import (_crosses, _fallback_act, _route_graph, _valid_act, candidates,
                             enemy_role, generate_enemies, generate_enemy_preview,
                             generate_map, placeholder_families, preview_from_units, rules,
                             unlocked_pool)

ROOT = Path(__file__).resolve().parents[1]


class MapV2Tests(unittest.TestCase):
    setUpClass = classmethod(helpers.AbyssTests.setUpClass.__func__)

    def act(self, nodes, act):
        return {n['id']: n for n in nodes if n['act'] == act}

    def test_structure_and_constraints_over_many_seeds(self):
        for difficulty in (1, 5, 10):
            elites = 0
            for seed in range(60):
                nodes = generate_map(seed, difficulty, self.cfg)
                ids = {n['id'] for n in nodes}
                self.assertEqual(len(ids), len(nodes))
                for act in (1, 2, 3):
                    graph = self.act(nodes, act)
                    route = [n for n in graph.values() if n['layer'] <= 6]
                    rest = [n for n in graph.values() if n['layer'] == 7]
                    boss = [n for n in graph.values() if n['layer'] == 8]
                    self.assertEqual([n['type'] for n in rest], ['rest'])
                    self.assertEqual([n['type'] for n in boss], ['boss'])
                    self.assertEqual(rest[0]['next'], [boss[0]['id']])
                    self.assertIsNone(rest[0]['col'])
                    for layer in range(1, 7):
                        row = [n for n in route if n['layer'] == layer]
                        self.assertTrue(2 <= len(row) <= 4, (seed, act, layer))
                        self.assertEqual(len({n['col'] for n in row}), len(row))
                    for node in route:
                        self.assertIn(node['col'], range(4))
                        self.assertEqual(node['id'], f"{act}-{node['layer']}-{node['col']}")
                        self.assertTrue(1 <= len(node['next']) <= 3, node)
                        if node['layer'] == 6:
                            self.assertEqual(node['next'], [rest[0]['id']])
                            self.assertNotEqual(node['type'], 'rest')
                            continue
                        for target in map(graph.get, node['next']):
                            self.assertEqual(target['layer'], node['layer'] + 1)
                            self.assertLessEqual(abs(target['col'] - node['col']), 1)
                            if node['type'] in ('elite', 'rest'):
                                self.assertNotEqual(node['type'], target['type'], (seed, node, target))
                    # Non-crossing edges between consecutive route layers.
                    edges = [(n['layer'], n['col'], graph[t]['col']) for n in route
                             for t in n['next'] if graph[t]['layer'] <= 6]
                    for layer, a, b in edges:
                        for other, c, d in edges:
                            if other == layer:
                                self.assertFalse((c < a and d > b) or (c > a and d < b))
                    kinds = [n['type'] for n in route]
                    self.assertGreaterEqual(kinds.count('elite'), 2 if difficulty == 10 else 1)
                    if difficulty >= 5:  # design table: at most one route rest per path
                        most = {}
                        for n in sorted(route, key=lambda n: -n['layer']):
                            most[n['id']] = (n['type'] == 'rest') + max(
                                [most[t] for t in n['next'] if t in most] or [0])
                        self.assertLessEqual(max(most.values()), 1)
                    self.assertIn('rest', kinds)
                    elites += kinds.count('elite')
                    for node in route:
                        if act == 1 and node['layer'] <= 3:
                            self.assertEqual(node['type'], 'weak')
                        elif act > 1 and node['layer'] == 1:
                            self.assertEqual(node['type'], 'normal')
                        else:
                            self.assertIn(node['type'], ('normal', 'elite', 'rest'))
                    # A route avoiding every elite exists.
                    safe = {n['id'] for n in route if n['layer'] == 6 and n['type'] != 'elite'}
                    for layer in range(5, 0, -1):
                        safe |= {n['id'] for n in route if n['layer'] == layer and n['type'] != 'elite'
                                 and set(n['next']) & safe}
                    self.assertTrue(any(graph[i]['layer'] == 1 for i in safe), (seed, act))
                    boss_next = boss[0]['next']
                    if act < 3:
                        nxt = self.act(nodes, act + 1)
                        self.assertEqual(sorted(boss_next),
                                         sorted(i for i, n in nxt.items() if n['layer'] == 1))
                    else:
                        self.assertEqual(boss_next, [])
            if difficulty == 1:
                easy = elites
            elif difficulty == 10:
                self.assertGreater(elites, easy)  # difficulty 10 uses the 35% elite weight

    def test_sibling_targets_usually_differ(self):
        mixed = total = 0
        for seed in range(80):
            nodes = generate_map(seed, 1, self.cfg)
            graph = {n['id']: n for n in nodes}
            for node in nodes:
                targets = [graph[t] for t in node['next'] if graph[t]['layer'] <= 6]
                if len(targets) > 1 and not all(t['type'] == 'weak' for t in targets):
                    total += 1
                    mixed += len({t['type'] for t in targets}) > 1
        self.assertGreater(mixed / total, .7)

    def test_fallback_layout_is_valid_and_crossing_rule(self):
        for act in (1, 2, 3):
            cells, nexts, kinds = _fallback_act(act)
            for difficulty in (1, 5, 10):
                self.assertTrue(_valid_act(act, cells, nexts, kinds, difficulty))
        self.assertTrue(_crosses([[1, 2]], 1, 2, 1))
        self.assertFalse(_crosses([[1, 2]], 1, 2, 2))
        self.assertFalse(_crosses([[1, 1]], 1, 2, 2))


class WeakPickTests(unittest.TestCase):
    setUpClass = classmethod(helpers.AbyssTests.setUpClass.__func__)
    setUp = helpers.AbyssTests.setUp
    call = helpers.AbyssTests.call
    start = helpers.AbyssTests.start
    enter = helpers.AbyssTests.enter
    combat = helpers.AbyssTests.combat
    finish = helpers.AbyssTests.finish

    def test_weak_choice_accepts_one_two_three_or_skip(self):
        for taken in (0, 1, 2, 3):
            with self.subTest(taken=taken):
                self.setUp()
                run = self.enter(self.start())
                run = self.finish(self.combat(run))['abyss_run']
                choice = run['pending_choice']
                size = len(run['pool'])
                if taken:
                    after = self.call('choose', heroes=[h['id'] for h in choice['options'][:taken]])
                else:
                    after = self.call('skip')
                self.assertEqual(len(after['abyss_run']['pool']), size + taken)
                self.assertIsNone(after['abyss_run']['pending_choice'])
                self.assertTrue(after['abyss_run']['available_nodes'])

    def test_count_never_exceeds_remaining_pool_space(self):
        p = {'avatars': {}, 'abyss_account': {'obtained': [], 'appeared': [], 'cleared': []}}
        plan = rules(self.cfg)
        pool = {a.rsplit('_', 1)[0]: {'aid': a} for a in plan['initial_purple'][:19]}
        choice = candidates(p, {'pool': pool, 'seed': 1, 'difficulty': 1},
                            {'id': '1-1-0', 'act': 1, 'type': 'weak'}, self.cfg)
        self.assertEqual((choice['count'], choice['can_skip']), (1, True))

    def test_new_runs_carry_map_version_and_legacy_runs_keep_their_map(self):
        run = self.start()
        self.assertEqual(run['map_version'], 2)
        first = [n['id'] for n in run['map'] if n['act'] == 1 and n['layer'] == 1]
        self.assertEqual(sorted(run['available_nodes']), sorted(first))
        # A saved v1 run (no col, old ids) keeps routing on its own map.
        legacy = [{'id': f'1-{l}-0', 'act': 1, 'layer': l, 'type': 'rest' if l == 4 else 'weak',
                   'next': [f'1-{l+1}-0'] if l < 7 else [], 'completed': False, 'enemy_preview': []}
                  for l in range(1, 8)]
        def downgrade(p):
            p['abyss_run'].pop('map_version')
            p['abyss_run'].update(map=legacy, current_node='1-4-0', available_nodes=[])
            return p, {}
        self.store.atomic_update(self.uid, downgrade)
        after = self.call('rest', option='leave')['abyss_run']
        self.assertEqual(after['map'][3]['completed'], True)
        self.assertEqual(after['available_nodes'], ['1-5-0'])
        self.assertNotIn('map_version', after)


class EnemyFormationTests(unittest.TestCase):
    setUpClass = classmethod(helpers.AbyssTests.setUpClass.__func__)

    def node(self, kind, act=2, layer=3):
        return {'id': f'{act}-{layer}-1', 'act': act, 'layer': layer, 'type': kind}

    def test_lanes_leaders_roles_and_elite_boost_are_random_but_seeded(self):
        line_length = self.cfg['system_simple']['battle'][1]
        splits, leader_lanes, boosted_lanes = collections.Counter(), collections.Counter(), collections.Counter()
        for seed in range(150):
            for kind in ('weak', 'normal', 'elite', 'boss'):
                node = self.node(kind, act=1 if kind == 'weak' else 2)
                preview = generate_enemy_preview(seed, 7, node, self.cfg)
                self.assertEqual(preview, generate_enemy_preview(seed, 7, node, self.cfg))
                lanes = collections.Counter(u['line'] for u in preview)
                self.assertEqual(set(lanes), {0, 1, 2})
                self.assertTrue(all(1 <= c <= 3 for c in lanes.values()))
                self.assertTrue(preview[0]['leader'])
                self.assertEqual(sum(u['leader'] for u in preview), 1)
                for line in range(3):
                    members = sorted((u for u in preview if u['line'] == line), key=lambda u: u['pos'])
                    roles = [enemy_role(u['aid'], self.cfg) == 'tank' for u in members]
                    self.assertEqual(roles, sorted(roles, reverse=True), (seed, kind, members))
                    for u in members:
                        self.assertIsInstance(u['pos'], int)
                        self.assertTrue(.12 * line_length <= u['pos'] <= .54 * line_length)
                boosted = [u for u in preview if u['limit_break']]
                if kind == 'elite':
                    self.assertEqual(len(boosted), 1)
                    self.assertEqual(boosted[0]['quality'], 6)
                    self.assertFalse(boosted[0]['leader'])
                    boosted_lanes[boosted[0]['line']] += 1
                else:
                    self.assertEqual(boosted, [])
                if kind == 'normal':
                    splits[tuple(lanes[i] for i in range(3))] += 1
                    leader_lanes[preview[0]['line']] += 1
        self.assertGreaterEqual(len(splits), 4)
        self.assertEqual(set(leader_lanes), {0, 1, 2})
        self.assertEqual(set(boosted_lanes), {0, 1, 2})

    def test_boss_keeps_authored_captain(self):
        plan = rules(self.cfg)
        for act in (1, 2, 3):
            captains = {deck[0].rsplit('_', 1)[0] for deck in plan['boss_decks'][str(act)]}
            for seed in range(30):
                preview = generate_enemy_preview(seed, 1, self.node('boss', act, 8), self.cfg)
                captain = preview[0]
                # A boss skin swap keeps the slot and its role, so the captain may be a skin.
                self.assertTrue(captain['is_skin'] or captain['aid'].rsplit('_', 1)[0] in captains)

    def test_preview_equals_combat_units(self):
        for seed in range(25):
            for kind in ('weak', 'normal', 'elite', 'boss'):
                node = self.node(kind, act=1 if kind == 'weak' else 3)
                node['enemy_preview'] = generate_enemy_preview(seed, 5, node, self.cfg)
                units = generate_enemies(seed, 5, node, self.cfg)
                self.assertEqual(preview_from_units(units, self.cfg), node['enemy_preview'])
                self.assertEqual(units[0]['leader'], 1)
                self.assertTrue(units[0]['leader_skill'])
                self.assertTrue(all(u['lv'] == 99 for u in units))

    def test_elite_boost_multiplies_only_the_limit_break_hero(self):
        node = self.node('elite')
        node['enemy_preview'] = generate_enemy_preview(3, 1, node, self.cfg)
        units = generate_enemies(3, 1, node, self.cfg)
        plain = [dict(u, limit_break=0) for u in node['enemy_preview']]
        reference = generate_enemies(3, 1, {**node, 'enemy_preview': plain, 'type': 'normal'}, self.cfg)
        ratio = rules(self.cfg)['enemy_rates']['elite']
        for unit, base in zip(units, reference):
            boost = 1.2 if unit.get('limit_break') else 1
            # normal/elite differ by the elite rate; compare hp against a 1-unit tolerance.
            self.assertAlmostEqual(unit['hp'], base['hp'] * ratio * boost, delta=3 * boost * ratio)

    def test_legacy_elite_preview_keeps_slot_zero_boost(self):
        line_length = self.cfg['system_simple']['battle'][1]
        aids = rules(self.cfg)['initial_purple'][:5]
        legacy = [{'aid': a[:-1] + ('6' if i == 0 else '5'), 'quality': 6 if i == 0 else 5, 'star': 5,
                   'lv': 99, 'slv': 5, 'line': i % 3, 'pos': (.15 + .18 * (i // 3)) * line_length,
                   'leader': i == 0, 'is_skin': False} for i, a in enumerate(aids)]
        node = {**self.node('elite'), 'enemy_preview': legacy}
        units = generate_enemies(1, 1, node, self.cfg)
        reference = generate_enemies(1, 1, {**node, 'type': 'normal'}, self.cfg)
        self.assertNotIn('limit_break', units[0])
        self.assertGreater(units[0]['hp'], reference[0]['hp'] * 1.3 * 1.19)
        self.assertEqual([u['pos'] for u in units], [round(u['pos']) for u in legacy])


class PoolExclusionTests(unittest.TestCase):
    setUpClass = classmethod(helpers.AbyssTests.setUpClass.__func__)

    def test_placeholder_rule_runs_on_native_config(self):
        raw = json.loads((ROOT / 'config/reconstruction/full-config.json').read_text(encoding='utf-8-sig'))
        found = placeholder_families(raw['cfg'])
        for family in ('A_1139', 'A_1140', 'A_1212', 'A_1224', 'A_1225', 'A_1227', 'A_1311',
                       'A_1903', 'A_1904', 'A_1905', 'A_1909', 'A_1998'):
            self.assertIn(family, found)
        for family in ('A_1033', 'A_1137', 'A_1001'):  # real custom skills S_9140/S_9150
            self.assertNotIn(family, found)
        excluded = set(rules(self.cfg)['excluded_families'])
        self.assertTrue(found <= excluded)
        self.assertTrue({'A_1903', 'A_1904', 'A_1905', 'A_1909', 'A_190001'} <= excluded)

    def test_excluded_families_never_reach_pool_offers_or_enemies(self):
        plan = rules(self.cfg)
        excluded = set(plan['excluded_families'])
        family = lambda a: a.rsplit('_', 1)[0]
        for key in ('initial_purple', 'skin_purple', 'skin_orange_only', 'enemy_skin_orange',
                    'eligible_ordinary_purple'):
            self.assertFalse({family(a) for a in plan[key]} & excluded, key)
        everything = sorted(a for a in self.cfg['avatar'] if a.startswith('A_1'))
        profile = {'avatars': {}, 'abyss_account': {'obtained': everything, 'appeared': everything,
                                                     'cleared': []}}
        purple, orange, standalone = unlocked_pool(profile, self.cfg)
        self.assertFalse({family(a) for a in purple + orange + standalone} & excluded)
        self.assertTrue(purple and orange)
        for seed in range(30):
            for kind, act in (('weak', 1), ('normal', 2), ('elite', 3), ('boss', 1)):
                choice = candidates(profile, {'pool': {}, 'seed': seed, 'difficulty': 3},
                                    {'id': f'{act}-2-0', 'act': act, 'type': kind}, self.cfg)
                self.assertFalse({family(h['aid']) for h in choice['options']} & excluded)


if __name__ == '__main__':
    unittest.main()
