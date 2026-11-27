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

    def test_graves_bounty_hunters_scales_existing_skills(self):
        from battle_engine import _native_skill_snapshot
        from bonds_104 import active_bonds, skill_ids

        cfg = self.fixture.cfg
        for quality in (5, 6):
            roster = [f'A_{number}_{quality}' for number in (1053, 1096, 1105, 1135)]
            aid = roster[0]
            bonds = active_bonds(cfg, aid, roster)
            self.assertEqual([bond['id'] for bond in bonds], ['b106'])
            variants = skill_ids(cfg, aid, bonds)
            for field, slot in (('skill', 10), ('leader_skill', 11)):
                with self.subTest(quality=quality, slot=slot):
                    base_id = cfg['avatar'][aid]['pl'][slot]
                    boosted_id = variants[field]
                    base = _native_skill_snapshot(cfg, base_id, 10)
                    boosted = _native_skill_snapshot(cfg, boosted_id, 10)
                    self.assertEqual(cfg['skill'][boosted_id]['name'], cfg['skill'][base_id]['name'])
                    self.assertEqual(boosted['pl'], base['pl'])
                    self.assertEqual([a[0] for a in boosted['skills']], [a[0] for a in base['skills']])
                    action, coefficient = (0, 5) if (quality, slot) == (6, 10) else (2, 1)
                    self.assertAlmostEqual(boosted['skills'][action][coefficient],
                                           base['skills'][action][coefficient] * 1.44)

    def test_graves_bounty_hunters_boosts_passive_in_battle_snapshot(self):
        from gameplay_roster import GameplayRosterEquipment

        cfg = self.fixture.cfg
        roster = [f'A_{number}_6' for number in (1053, 1096, 1105, 1135)]
        ids = [f'{aid}|{i}' for i, aid in enumerate(roster)]
        profile = {
            'avatars': {iid: {'aid': aid, 'lv': 60} for iid, aid in zip(ids, roster)},
            'team': [ids], 'as_equips': [[] for _ in ids], 'my_equips': {},
            'attrs': {'team_num': 0},
        }
        equipment = GameplayRosterEquipment(None, {'cfg': cfg})
        bonded = equipment.battle_attributes(profile, ids[0])['skillB']
        profile['team'] = [ids[:-1]]
        unbonded = equipment.battle_attributes(profile, ids[0])['skillB']
        self.assertNotEqual(bonded['skid'], unbonded['skid'])
        self.assertEqual(cfg['skill'][bonded['skid']]['name'], '新命运')
        self.assertEqual(bonded['pl'], unbonded['pl'])
        self.assertEqual(bonded['skills'][0][:4], unbonded['skills'][0][:4])

        battle, owner, foes = self.arena(1053)
        owner['skillB'] = bonded
        self.assertEqual(battle._get_range(owner), 500)
        for distance, coefficient in ((200, 4), (350, 2.8), (500, 1.8)):
            foes[0]['pos'] = owner['pos'] - distance
            with patch.object(battle, '_native_damage', wraps=battle._native_damage) as hit:
                battle._basic_attack(owner, foes[0])
                self.assertAlmostEqual(hit.call_args.args[2], coefficient * 1.44)

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

    def test_lux_captain_applies_accuracy_above_one_hundred_thousand(self):
        battle, owner, foes = self.arena(1060)
        self.assertTrue(self.fixture.cast(battle, owner, 'leader_skill'))
        self.assertGreater(battle._buff_value(owner, 'hitup'), 100000)

    def test_diana_magic_basic_adds_defense_damage_once_per_target(self):
        battle, owner, foes = self.arena(1086)
        self.assertEqual(battle._config['avatar'][owner['aid']]['tl'][2], 2)
        defenses = battle._get_de_ph(owner)+battle._get_de_ma(owner)
        with patch.object(battle, 'six_next_raw', wraps=battle.six_next_raw) as raw:
            battle._basic_attack(owner, foes[0])
        hit = [call.args[1] for call in raw.call_args_list]
        # Every same-lane enemy the 350 sweep reaches takes the lunar damage once.
        self.assertEqual(len(hit), len({id(target) for target in hit}))
        self.assertIn(foes[0], hit)
        self.assertNotIn(foes[-1], hit)
        for call in raw.call_args_list:
            self.assertAlmostEqual(call.args[2], defenses*1.75)
            self.assertEqual(call.args[3], 2)
            self.assertEqual(call.args[4], defenses)

    def test_diana_nami_blessing_does_not_repeat_lunar_damage(self):
        battle, owner, foes = self.arena(1086, [(0,1500,100000)], [(0,1750,100000)])
        aura = dict(source=battle.a[1], left=3, ratio=1.25, weak=.66)
        battle.state(owner)['six_nami_bless'] = aura
        with (patch.object(battle, '_fixed_true_damage', wraps=battle._fixed_true_damage) as nami,
              patch.object(battle, 'six_next_raw', wraps=battle.six_next_raw) as lunar):
            battle._basic_attack(owner, foes[0])
        self.assertEqual(aura['left'], 2)
        self.assertEqual(nami.call_count, 2)
        for hit in nami.call_args_list:
            self.assertIs(hit.args[1], foes[0])
            self.assertEqual(hit.args[2], 625)
        lunar.assert_called_once()
        self.assertIs(lunar.call_args.args[1], foes[0])

    def test_diana_defense_damage_measures_target_defense_against_her_defenses(self):
        battle, owner, foes = self.arena(1086)
        target = foes[0]
        target['de_ma'] = 30000
        owner['ap'], owner['de_ph'], owner['de_ma'] = 5000, 40000, 40000
        defenses = battle._get_de_ph(owner)+battle._get_de_ma(owner)
        dealt = []
        for base in (None, defenses):
            target['hp'] = target['hp_max']
            battle._native_damage(owner, target, 1, 2, raw_override=100000, defense_base=base)
            dealt.append(target['hp_max']-target['hp'])
        # Against her low attack the target's 30000 magic defense nearly caps the reduction.
        self.assertGreater(dealt[1], dealt[0]*2)

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

    def test_leblanc_consumes_mark_and_shares_one_pool_of_eight_clones(self):
        battle, owner, foes = self.arena(1127)
        self.assertTrue(self.fixture.cast(battle,owner))
        self.assertTrue(battle.marked(owner,foes[0],'next_mirror'))
        self.assertTrue(self.fixture.cast(battle,owner))
        self.assertFalse(battle.marked(owner,foes[0],'next_mirror'))
        self.assertIsNotNone(battle._buff(foes[0],'silence'))
        panel = battle._summon_panel_snapshot(owner)
        battle._emit_mod_event(owner, 'dodge', foes[0], owner)
        first = battle.state(owner)['next_mirrors'][0]
        for stat in ('hp_max', 'ap', 'de_ph', 'de_ma'):
            self.assertEqual(first[stat], panel[stat])
        for stat in ('hit', 'flee', 'crit', 'tough'):
            self.assertEqual(first['new_4attrs'][stat], panel[stat])

        # A clone uses the original owner's full panel, but summons on its own lane.
        first['ap'] *= 2
        first['line'] = 1
        battle._emit_mod_event(first, 'dodge', foes[0], first)
        second = battle.state(owner)['next_mirrors'][-1]
        self.assertEqual(second['ap'], panel['ap'])
        self.assertEqual(second['line'], first['line'])
        for _ in range(7):
            battle._emit_mod_event(second, 'dodge', foes[0], second)
        clones = battle.state(owner)['next_mirrors']
        self.assertEqual(second['next_mirror_generation'], 2)
        self.assertTrue(all(u['next_mirror_generation'] == 3 for u in clones if u is not second))
        third = clones[-1]
        with patch.object(battle, '_spawn_summon', wraps=battle._spawn_summon) as spawn:
            battle._emit_mod_event(third, 'dodge', foes[0], third)
        spawn.assert_not_called()
        self.assertIs(battle.state(owner)['next_mirrors'], clones)
        self.assertEqual(len(clones), 8)
        self.assertEqual(first['hp'], 0)
        self.assertEqual(sum(u['hp'] > 0 for u in battle.a[1:]), 8)
        self.assertTrue(all(u['skill'] and not u['skillB'] and
                            u['summon_owner_token'] == owner['_owner_token'] for u in clones))

    def test_leblanc_captain_clone_dodge_also_uses_passive_pool(self):
        battle, owner, foes = self.arena(1127)
        self.assertTrue(self.fixture.cast(battle, owner, 'leader_skill'))
        captain_clone = battle.a[1]
        self.assertEqual(captain_clone['next_mirror_generation'], 1)
        battle._emit_mod_event(captain_clone, 'dodge', foes[0], captain_clone)
        captain_entry, passive_clone = battle.state(owner)['next_mirrors']
        self.assertIs(captain_entry, captain_clone)
        self.assertEqual(captain_clone['skill'], owner['skill'])
        self.assertEqual(passive_clone['next_mirror_generation'], 2)
        self.assertEqual(passive_clone['ap'], battle._summon_panel_snapshot(owner)['ap'])
        for _ in range(7):
            battle._emit_mod_event(passive_clone, 'dodge', foes[0], passive_clone)
        self.assertEqual(captain_clone['hp'], 0)
        self.assertEqual(sum(u['hp'] > 0 for u in battle.a[1:]), 8)
        oldest = battle.state(owner)['next_mirrors'][0]
        self.assertTrue(self.fixture.cast(battle, owner, 'leader_skill'))
        self.assertEqual(oldest['hp'], 0)
        self.assertEqual(battle.state(owner)['next_mirrors'][-1]['next_mirror_generation'], 1)
        self.assertEqual(sum(u['hp'] > 0 for u in battle.a[1:]), 8)

    def test_baron_heals_only_from_hitting_an_existing_own_curse(self):
        for prior, landed in (('none', True), ('ally', True), ('own', False), ('own', True)):
            with self.subTest(prior=prior, landed=landed):
                battle, owner, foes = self.arena(1203, [(0,1500,100000)], [(0,1850,100000)])
                owner['hp'] = 50000
                if prior != 'none':
                    source = owner if prior == 'own' else battle.a[1]
                    battle._add_buff(foes[0], 'curse', 3, source=source)
                battle._roll_attack = lambda *args, **kwargs: int(landed)
                self.assertTrue(self.fixture.cast(battle,owner))
                self.assertEqual(owner['hp'] > 50000, prior == 'own' and landed)

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
