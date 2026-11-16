"""Abyss pool bonds change real combat stats and skill snapshots."""
import unittest

import test_roguelite_abyss as helpers
from battle_engine import _native_skill_snapshot
from roguelite_abyss import hero_record, standard_team


class PoolBondTests(unittest.TestCase):
    setUpClass = classmethod(helpers.AbyssTests.setUpClass.__func__)
    setUp = helpers.AbyssTests.setUp
    call = helpers.AbyssTests.call
    start = helpers.AbyssTests.start
    enter = helpers.AbyssTests.enter

    def pool(self, aids):
        return {aid.rsplit('_', 1)[0]: hero_record(aid) for aid in aids}

    def formation(self, aids):
        return [[aid.rsplit('_', 1)[0], index % 3, .2] for index, aid in enumerate(aids)]

    def test_benched_members_activate_stats_only_for_related_deployed_heroes(self):
        selected = ['A_1001_5', 'A_1002_5', 'A_1003_5']
        pool = self.pool(selected + ['A_1007_5', 'A_1009_5'])
        formation = self.formation(selected)
        plain = standard_team(self.cfg, self.pool(selected), formation)
        units = standard_team(self.cfg, pool, formation)
        self.assertEqual([u['aid'] for u in units], selected)
        self.assertIn('b001', units[0]['bonds_104'])
        for stat in ('hp', 'de_ph', 'de_ma'):
            self.assertEqual(units[0][stat], int(round(plain[0][stat] * (1 + 2 / 15), 5)))
        self.assertEqual(units[0]['hp_max'], units[0]['hp'])
        self.assertEqual(units[0]['ap'], plain[0]['ap'])
        self.assertEqual(units[1:], plain[1:])

    def test_benched_member_activates_mechanic_and_skill_variants(self):
        selected = ['A_1009_5', 'A_1007_5', 'A_1002_5']
        pool = self.pool(selected + ['A_1001_5'])
        units = standard_team(self.cfg, pool, self.formation(selected))
        for unit in units[:2]:
            self.assertEqual(unit['bonds_104'], ['b001'])
            variant = self.cfg['system_simple']['bond_skill_variants_104'][unit['aid']]['b001']
            self.assertEqual(unit['skill'], _native_skill_snapshot(self.cfg, variant['skill'], 5))
            self.assertNotEqual(unit['skill'], _native_skill_snapshot(
                self.cfg, self.cfg['avatar'][unit['aid']]['pl'][10], 5))
        self.assertIsNone(units[1]['leader_skill'])
        self.assertIsNone(units[2]['leader_skill'])

    def test_matching_purple_or_orange_required_and_upgrade_recomputes_bonds(self):
        for quality in (5, 6):
            with self.subTest(quality=quality):
                selected = [f'A_1001_{quality}', 'A_1002_5', 'A_1003_5']
                pool = self.pool(selected + [f'A_1007_{quality}', f'A_1009_{quality}'])
                formation = self.formation(selected)
                self.assertIn('b001', standard_team(self.cfg, pool, formation)[0]['bonds_104'])
                pool['A_1007'] = hero_record(f'A_1007_{11 - quality}')
                self.assertNotIn('b001', standard_team(self.cfg, pool, formation)[0]['bonds_104'])
                del pool['A_1009']
                self.assertNotIn('b001', standard_team(self.cfg, pool, formation)[0]['bonds_104'])

    def test_collected_bond_also_applies_secondary_stats(self):
        bond, family = next((b, f) for b in self.cfg['system_simple']['bonds_104']
                            for f, benefit in b['benefits'].items()
                            if benefit.get('flat_by_quality', {}).get('5'))
        fillers = [f for f in ('A_1002', 'A_1003', 'A_1004', 'A_1095', 'A_1018')
                   if f not in bond['families']][:2]
        selected = [family + '_5'] + [f + '_5' for f in fillers]
        pool = self.pool([f + '_5' for f in bond['families']] + selected)
        unit = standard_team(self.cfg, pool, self.formation(selected))[0]
        self.assertIn(bond['id'], unit['bonds_104'])
        for stat, amount in bond['benefits'][family]['flat_by_quality']['5'].items():
            self.assertGreaterEqual(unit['new_4attrs'][stat], amount)

    def test_enemy_reserves_do_not_activate_player_pool_rule(self):
        selected = ['A_1001_5', 'A_1002_5', 'A_1003_5']
        pool = self.pool(selected + ['A_1007_5', 'A_1009_5'])
        formation = self.formation(selected)
        self.assertEqual(standard_team(self.cfg, pool, formation, team=2),
                         standard_team(self.cfg, self.pool(selected), formation, team=2))

    def test_combat_api_freezes_pool_bonds_into_battle_and_pending_intent(self):
        self.enter(self.start())
        selected = ['A_1001_5', 'A_1002_5', 'A_1003_5']
        pool = self.pool(selected + ['A_1007_5', 'A_1009_5'])
        def collect(profile):
            profile['abyss_run']['pool'] = pool
            return profile, {}
        self.store.atomic_update(self.uid, collect)
        battle = self.call('combat', team=self.formation(selected))
        own = battle['orgin_team_a']
        self.assertEqual([u['aid'] for u in own], selected)
        self.assertIn('b001', own[0]['bonds_104'])
        profile = self.store.profile_raw(self.uid)
        self.assertEqual(profile['pending_battles']['abyss'][battle['fight_id']]['team_a'], own)
        self.assertEqual(profile['abyss_run']['battle']['orgin_team_a'], own)


if __name__ == '__main__':
    unittest.main()
