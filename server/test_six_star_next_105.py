"""Core mechanics and authored endpoints of the fourth balance batch."""

from unittest import TestCase
from unittest.mock import patch

import test_six_star_balance_105 as fixtures


class NextSixStarTests(TestCase):
    @classmethod
    def setUpClass(cls):
        fixtures.SixStarBalanceTests.setUpClass()
        cls.fixture = fixtures.SixStarBalanceTests()

    def arena(self, number, enemies=None, allies=(), *, leader=True):
        battle, owner, foes = self.fixture.arena(
            number, enemies or [(0,1500,100000),(0,1410,100000),(0,1330,100000),(1,1500,100000)],
            allies, leader=leader)
        owner['_team'] = battle.a
        battle._roll_attack = lambda *args, **kwargs: 1
        return battle, owner, foes

    def test_graves_bands_and_cooldown(self):
        battle, owner, foes = self.arena(1053)
        for distance, expected in ((200,4),(201,2.8),(350,2.8),(351,1.8),(500,1.8)):
            foes[0]['pos'] = owner['pos']-distance
            with patch.object(battle, '_native_damage', wraps=battle._native_damage) as hit:
                battle._basic_attack(owner, foes[0])
                self.assertAlmostEqual(hit.call_args.args[2], expected)
        self.assertEqual(battle._get_range(owner),500)
        owner['_skill_cd'] = 4
        for _ in range(3):
            battle._injured(owner,100,1,source=foes[0])
        self.assertEqual(owner['_skill_cd'],3)

    def test_shyvana_transforms_once_and_shields_from_cross_lane_burn(self):
        battle, owner, foes = self.arena(1054)
        old = owner['hp_max']
        for _ in range(19):
            battle._injured(foes[0],1,2,source=owner)
        self.assertFalse(battle.state(owner).get('next_dragon'))
        battle._injured(owner,1000,1,source=foes[0])
        self.assertTrue(battle.state(owner)['next_dragon'])
        self.assertEqual((owner['hp'],owner['hp_max']),(old*2,old*2))
        self.assertTrue(self.fixture.cast(battle,owner,'leader_skill'))
        self.assertLess(foes[-1]['hp'],100000)
        battle._injured(foes[-1],1000,7,source=foes[0],dot_kind='burn')
        self.assertGreater(battle._buff_value(owner,'shield'),0)
        self.assertEqual(owner['hp_max'],2*old)

    def test_riven_three_casts_and_lux_trigger_cap(self):
        battle, owner, foes = self.arena(1056)
        for coefficient in (2,3,4):
            with patch.object(battle,'_native_damage',wraps=battle._native_damage) as hit:
                self.assertTrue(self.fixture.cast(battle,owner))
                self.assertAlmostEqual(hit.call_args_list[0].args[2],coefficient)
        self.assertIsNotNone(battle._buff(foes[0],'stun'))

        battle, owner, foes = self.arena(1060)
        self.assertFalse(any(a[0]=='shield' for a in owner['skill']['skills']))
        for _ in range(4):
            battle._add_buff(foes[0],'stun',1,source=owner)
        self.assertEqual(battle.state(owner)['next_lux_count'],3)
        self.assertGreater(battle._buff_value(owner,'shield'),0)

    def test_sivir_purify_and_diana_additive_shield(self):
        battle, owner, foes = self.arena(1078)
        owner['hp'] = 50000
        owner['_skill_cd_b'] = -1
        self.assertTrue(battle._use_turn_start_passive(owner,foes))
        battle._add_buff(owner,'stun',1,source=foes[0])
        self.assertIsNone(battle._buff(owner,'stun'))
        self.assertGreater(owner['hp'],50000)

        battle, owner, foes = self.arena(1086)
        self.assertTrue(self.fixture.cast(battle,owner))
        self.assertAlmostEqual(battle._buff(owner,'shield').value,
                               battle._buff(owner,'next_diana_shield').value,delta=1)
        self.assertEqual(foes[-1]['hp'],100000)

    def test_riven_counts_primary_before_killing_it(self):
        for size in (3, 4):
            with self.subTest(enemies=size):
                rows = [(0,1500,1), *((0,1410-i*80,100000) for i in range(size-1)), (1,1500,100000)]
                battle, owner, foes = self.arena(1056, rows)
                battle._basic_attack(owner, foes[0])
                self.assertEqual(foes[0]['hp'], 0)
                for foe in foes[1:-1]:
                    self.assertEqual(battle._buff(foe,'stun') is not None, size == 4)
                    self.assertEqual(foe['hp'] < 100000, size == 4)
                self.assertIsNone(battle._buff(foes[-1],'stun'))
                self.assertEqual(foes[-1]['hp'], 100000)

    def test_sivir_bounces_without_captain_skill_equipped(self):
        captain = self.fixture.snapshot(1078, 11)
        ricochet = next(step for step in captain['skills'] if step[0] == 'ricochet_bursts')
        battle, owner, foes = self.arena(1078, leader=False)
        self.assertIsNone(owner['leader_skill'])
        with patch.object(battle, '_native_damage', wraps=battle._native_damage) as hit:
            battle._basic_attack(owner, foes[0])
        self.assertEqual([call.args[1] for call in hit.call_args_list], foes[:3])
        self.assertEqual([call.args[2] for call in hit.call_args_list], [1, *ricochet[2][1:3]])
        self.assertIsNone(owner['leader_skill'])

    def test_karthus_waits_or_interrupts_and_casts_twice_on_death_once(self):
        battle, owner, foes = self.arena(1098, allies=[(0,1850,100000)])
        self.assertTrue(self.fixture.cast(battle,owner,'leader_skill'))
        self.assertTrue(all(f['hp']==100000 for f in foes))
        battle._add_buff(owner,'silence',1,source=foes[0])
        self.assertFalse(battle.six_next_channel_turn(owner))
        battle._remove_buff(owner,'silence')
        self.assertTrue(self.fixture.cast(battle,owner,'leader_skill'))
        self.assertTrue(battle.six_next_channel_turn(owner))
        self.assertTrue(all(f['hp']<100000 for f in foes))
        with patch.object(battle,'_apply_native_skill',wraps=battle._apply_native_skill) as cast:
            battle._injured(owner,owner['hp']*3,3,source=foes[0])
            self.assertEqual([call.args[2] for call in cast.call_args_list],['skill','skill'])
            self.assertEqual(owner['hp'],0)

    def test_malzahar_commands_same_lane_voidling_and_aoxing_resets_channel(self):
        battle, owner, foes = self.arena(1103)
        self.assertTrue(self.fixture.cast(battle,owner,'leader_skill'))
        voidling = next(u for u in battle.a if u['aid']=='A_2904002_5')
        self.assertEqual(battle._buff(voidling,'summon').round,4)
        voidling['pos'] = 2700
        battle._basic_attack(owner,foes[0])
        self.assertIsNotNone(battle._buff(foes[0],'silence'))
        self.assertIsNotNone(battle._buff(foes[0],'burn'))

        battle, owner, foes = self.arena(1114)
        for _ in range(5):
            self.assertTrue(self.fixture.cast(battle,owner))
        self.assertEqual(battle.state(owner)['next_charge'],5)
        self.assertTrue(self.fixture.cast(battle,owner))
        self.assertIn('next_storm',battle.state(owner))
        battle._add_buff(owner,'stun',1,source=foes[0])
        self.assertNotIn('next_charge',battle.state(owner))
        self.assertNotIn('next_storm',battle.state(owner))

    def test_leblanc_consumes_mark_and_keeps_only_three_passive_clones(self):
        battle, owner, foes = self.arena(1127)
        self.assertTrue(self.fixture.cast(battle,owner))
        self.assertTrue(battle.marked(owner,foes[0],'next_mirror'))
        self.assertTrue(self.fixture.cast(battle,owner))
        self.assertFalse(battle.marked(owner,foes[0],'next_mirror'))
        self.assertIsNotNone(battle._buff(foes[0],'silence'))
        for _ in range(4):
            battle._emit_mod_event(owner,'dodge',foes[0],owner)
        clones = battle.state(owner)['next_mirrors']
        self.assertEqual(len(clones),3)
        self.assertEqual(sum(u['hp']>0 for u in battle.a[1:]),3)
        self.assertTrue(all(u['skill'] and not u['skillB'] for u in clones))

    def test_baron_only_grows_for_same_lane_and_maokai_and_caitlyn_endpoints(self):
        battle, owner, foes = self.arena(1203)
        self.assertTrue(self.fixture.cast(battle,owner))
        self.assertTrue(all(battle._buff(foe,'curse') for foe in foes[:3]))
        self.assertIsNone(battle._buff(foes[-1],'curse'))
        battle._run_unit_turn(owner,{1:battle.a,2:battle.b},1)
        self.assertEqual(owner['hp_max'],115000)
        self.assertEqual(owner['ap'],1150)

        battle, owner, foes = self.arena(1205)
        owner['hp'] = 50000
        battle._basic_attack(owner,foes[0])
        self.assertEqual(owner['hp'],62000)
        self.assertTrue(self.fixture.cast(battle,owner,'leader_skill'))
        self.assertIsNotNone(battle._buff(foes[-1],'stun'))

        row = self.fixture.snapshot(1211)['skills'][0]
        self.assertAlmostEqual(row[4],3)
        self.assertAlmostEqual(row[5],1)
        self.assertAlmostEqual(self.fixture.snapshot(1211,13)['skills'][0][4],4)
