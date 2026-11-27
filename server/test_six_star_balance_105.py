from pathlib import Path
from unittest import TestCase
from unittest.mock import patch

from battle_engine import base_unit
from gateway import load_game_config
from equipment_bonds_104 import skill_id
from manual_ability_sim import SkillCompleteBattle
from native_skill_snapshot import _native_skill_snapshot

ROOT = Path(__file__).resolve().parents[1]
CONFIG = ROOT / 'config/reconstruction/full-config.json'
FOLLOWUP_IDS = (1008,1024,1026,1027,1130,1131,1132,1133,1135,1138,1142,1202)
EXTENDED_IDS = (1115,1117,1119,1120,1123,1124,1125,1126,1128,1136,1206,1214,1223,1227,1998)
REACTION_IDS = (1029,1030,1032,1033,1036,1040)
NEXT_IDS = (1053,1054,1056,1060,1078,1086,1098,1103,1114,1127,1203,1205,1211)
IDS = {f'A_{i}_6' for i in range(1001,1026) if i not in (1008,1024)} | {f'A_{i}_6' for i in FOLLOWUP_IDS + EXTENDED_IDS + REACTION_IDS + NEXT_IDS}


class SixStarBalanceTests(TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cfg = load_game_config(CONFIG)['cfg']

    def snapshot(self, ident, slot=10, level=10):
        aid = f'A_{ident}_6'
        sid = self.cfg['avatar'][aid]['pl'][slot]
        return _native_skill_snapshot(self.cfg, sid, level if slot==10 else 1)

    def arena(self, ident, enemies, allies=(), *, leader=True):
        owner = base_unit(self.cfg, f'A_{ident}_6', 60, 10, 0, .5, leader, 1)
        owner.update(pos=1700, ap=1000, hp=100000, hp_max=100000)
        def dummy(side, index, line, pos, hp):
            return dict(aid='A_1008_6', isme=side==1, tpl=[1,1,1,0,500], line=line, pos=pos,
                        lv=60, ap=500+index, hp=hp, hp_max=100000, de_ph=0, de_ma=0, new_4attrs={})
        battle = SkillCompleteBattle(
            [owner, *(dummy(1,i,*row) for i,row in enumerate(allies))],
            [dummy(2,i,*row) for i,row in enumerate(enemies)],
            config=self.cfg,
        )
        battle.rng.get_random = lambda *args: 99
        return battle, battle.a[0], battle.b

    def cast(self, battle, owner, slot='skill'):
        return battle._apply_native_skill(owner, battle.opponents(owner), slot)

    def test_exact_ids_timing_rank_endpoints_and_distinct_purple_rows(self):
        self.assertEqual(set(self.cfg['six_star_balance_105']), IDS)
        for aid in IDS:
            slots = self.cfg['avatar'][aid]['pl']
            lower = self.cfg['avatar'].get(aid[:-1]+'5', {}).get('pl', [])
            for index in (10,11,13):
                sid = slots[index] if len(slots)>index else None
                if sid and self.cfg['skill'][sid].get('sixStarBalance105'):
                    self.assertNotIn(sid, lower[10:14])
                    if index!=10:
                        self.assertEqual(_native_skill_snapshot(self.cfg,sid,10),_native_skill_snapshot(self.cfg,sid,1))
        endpoints = [
            (1001,10,1,1,4), (1003,10,2,1,.2), (1006,10,0,1,1), (1006,10,0,2,.05),
            (1006,10,2,1,.5), (1007,10,1,1,3), (1007,11,0,1,1), (1007,11,1,1,4.5),
            (1009,13,1,6,.12), (1010,10,3,1,.7), (1011,11,0,4,3), (1011,13,0,4,2),
            (1012,10,0,4,2.7), (1012,11,0,4,.6), (1012,11,0,5,.2),
            (1013,11,0,4,5), (1013,13,0,6,.8), (1014,10,1,1,1), (1014,11,0,1,1.2),
            (1014,13,0,12,1.2), (1015,10,5,1,1), (1015,11,0,4,1.2), (1015,13,0,5,9),
            (1016,11,4,1,1.25), (1016,13,0,4,3.33), (1017,10,4,1,.5), (1017,10,5,1,1),
            (1018,10,0,4,.5), (1018,13,0,4,.5), (1018,13,0,5,.7),
            (1019,10,3,1,.22), (1019,10,3,2,.66), (1019,13,0,4,1),
            (1020,10,3,1,3), (1021,10,1,1,1.5), (1021,10,2,2,.15), (1021,11,3,1,3.25),
            (1021,13,0,5,1.5), (1022,11,0,4,1.5), (1022,11,0,5,1.25), (1022,13,0,4,3000),
            (1023,10,0,4,2), (1023,13,0,4,1.25),
            (1025,10,0,4,.25), (1025,10,0,5,7), (1025,11,0,4,8), (1025,13,0,4,2.5),
        ]
        for ident, slot, action, field, value in endpoints:
            with self.subTest(hero=ident,slot=slot,action=action,field=field):
                self.assertAlmostEqual(self.snapshot(ident,slot)['skills'][action][field],value)
                if slot==10:
                    self.assertAlmostEqual(self.snapshot(ident,slot,1)['skills'][action][field],value/2)
        for level in range(1,11):
            self.assertAlmostEqual(self.snapshot(1014,level=level)['skills'][0][1],1.2)
        timing = {
            (1001,10):(1,2), (1002,13):(0,0), (1003,10):(1,1), (1007,10):(0,2), (1007,11):(1,3),
            (1009,10):(2,1), (1010,10):(1,1), (1011,10):(1,1), (1011,11):(1,1),
            (1012,10):(2,2), (1012,11):(0,3), (1012,13):(0,0), (1013,11):(2,2), (1013,13):(0,5),
            (1015,10):(0,3), (1015,11):(0,0), (1015,13):(0,1), (1016,10):(2,1), (1016,13):(1,0),
            (1017,10):(0,2), (1018,13):(0,0), (1020,10):(1,2), (1021,13):(0,0),
            (1022,10):(1,1), (1022,11):(0,0), (1025,10):(0,3), (1025,11):(2,2),
        }
        for key, value in timing.items():
            with self.subTest(hero=key[0],slot=key[1]):
                self.assertEqual(tuple(self.snapshot(*key)['pl'][:2]),value)

    def test_scope_does_not_change_unlisted_or_purple_skills(self):
        with patch('six_star_balance_105.apply_six_star_balance', lambda d:d):
            previous=load_game_config(CONFIG)['cfg']
        for aid, row in previous['avatar'].items():
            if aid in IDS:
                continue
            with self.subTest(aid=aid):
                for slot in (10,11,13):
                    sid = row['pl'][slot] if len(row['pl'])>slot else None
                    if sid:
                        self.assertEqual(self.cfg['avatar'][aid]['pl'][slot],sid)
                        self.assertEqual(self.cfg['skill'][sid],previous['skill'][sid])

    def test_rebound_equipment_still_strengthens_its_component(self):
        for ident, slot, gear_index, action, position in ((1014,10,0,0,1), (1017,10,1,4,1),
                       (1018,13,1,0,4), (1019,10,0,2,1), (1023,10,0,0,5), (1025,11,0,0,4),
                       (1033,11,0,0,4), (1036,11,0,0,6),
                       (1115,10,0,0,5), (1115,11,1,0,5), (1123,10,0,0,1),
                       (1125,10,0,0,5), (1125,11,1,0,4), (1214,10,1,0,4),
                       (1130,10,1,0,6), (1131,10,0,0,4), (1133,11,1,0,5)):
            with self.subTest(hero=ident,slot=slot):
                aid=f'A_{ident}_6'
                definition=self.cfg['system_simple']['equipment_bonds_104'][aid][gear_index]
                source=self.snapshot(ident,slot)
                equipped_id=skill_id(self.cfg,aid,source['skid'],[definition])
                self.assertNotEqual(equipped_id,source['skid'])
                equipped=_native_skill_snapshot(self.cfg,equipped_id,10 if slot==10 else 1)
                self.assertAlmostEqual(equipped['skills'][action][position],
                                       source['skills'][action][position]*(1+definition['strength']))

    def test_extended_rank_endpoints(self):
        endpoints = (
            (1115,10,0,4,1.8), (1115,11,0,4,3), (1117,13,0,4,3),
            (1119,10,1,1,1.2), (1119,10,2,1,1.55), (1119,13,0,5,.6),
            (1120,11,0,4,.99), (1123,10,0,1,.35), (1123,10,1,3,.2), (1123,11,2,1,2.35),
            (1124,10,0,1,8), (1124,11,0,1,14), (1125,10,0,4,1.2), (1125,11,0,4,5.5),
            (1126,11,1,3,.8), (1126,11,8,1,1.25), (1128,10,3,4,.8), (1128,11,0,1,1),
            (1136,11,1,1,1), (1214,10,0,4,3), (1214,11,0,4,2.75), (1214,13,0,4,1.7),
            (1223,10,4,1,.95), (1223,13,0,12,.85), (1227,10,0,12,1), (1227,13,0,5,3),
            (1998,10,0,1,1.65), (1998,11,1,1,6), (1998,11,3,1,.75),
        )
        for aid, slot, i, j, number in endpoints:
            with self.subTest(aid=aid, slot=slot, action=i, field=j):
                self.assertAlmostEqual(self.snapshot(aid, slot)['skills'][i][j], number)
                if slot == 10:
                    self.assertAlmostEqual(self.snapshot(aid, slot, 1)['skills'][i][j], number if aid == 1124 else number/2)

    def test_reaction_annie_global_and_mixed_burn_layers(self):
        self.assertAlmostEqual(self.snapshot(1029)['skills'][0][2], .65)
        battle, owner, enemies = self.arena(1029, [(0,1300,100000), (1,1300,100000)])
        self.assertTrue(self.cast(battle, owner))
        self.assertTrue(all(battle._has_manual_dot_kind(u, 'burn') for u in enemies))
        target = enemies[1]
        battle._add_buff(target, 'burn', 2, 100, source=owner)
        target['_relic_dots'] = [dict(kind='burn', amount=400, left=2, source=owner)]
        battle._status_received(target, 'burn')
        self.assertEqual(target['hp'], 100000)
        battle._add_book_burn(target, 500, 3, owner)
        self.assertEqual(target['hp'], 98100)
        self.assertFalse(battle._has_manual_dot_kind(target, 'burn'))
        self.assertTrue(battle._has_manual_dot_kind(enemies[0], 'burn'))
        self.assertIsNotNone(battle._buff(target, 'stun'))
        for _ in range(4):
            battle._add_buff(target, 'burn', 2, 100, source=owner)
        self.assertEqual(target['hp'], 97780)
        self.assertIsNone(battle._buff(target, 'burn'))

    def test_reaction_miss_fortune_sustain_and_barrage(self):
        from six_star_reaction_battle_105 import MF_SHIELD
        battle, owner, enemies = self.arena(1030, [(0,1100+i*100,100000) for i in range(6)] + [(1,1500,100000)])
        target = enemies[0]
        owner['hp'] -= 500
        battle._injured(target, 1000, 1, source=owner)
        self.assertEqual(owner['hp'], owner['hp_max'])
        self.assertEqual(battle._buff_value(owner, MF_SHIELD), 300)
        battle.turn_start(owner)
        battle._injured(owner, 100, 1, source=target)
        self.assertEqual(battle.state(owner)['reaction_mf_stacks'], 1)
        battle._injured(target, 1000, 1, source=owner)
        self.assertGreaterEqual(99000-target['hp'], 1149)
        before = target['hp']
        battle._remove_all_debuff(target)
        battle._injured(target, 1000, 4, source=target)
        self.assertEqual(target['hp'], before+850)
        for _ in range(6):
            battle.turn_start(owner)
        battle._injured(target, 1000, 1, source=owner)
        before = target['hp']
        battle._injured(target, 1000, 4, source=target)
        self.assertEqual(target['hp'], before)
        battle._injured(owner, battle._buff_value(owner, 'shield')+1, 1, source=target)
        self.assertEqual(battle.state(owner).get('reaction_mf_stacks', 0), 0)
        with patch.object(battle, '_native_damage', wraps=battle._native_damage) as hit:
            self.assertTrue(self.cast(battle, owner, 'leader_skill'))
        for target in enemies[:6]:
            coefficients = [call.args[2] for call in hit.call_args_list if call.args[1] is target]
            self.assertEqual(coefficients, [.7]*8)
        self.assertEqual(enemies[6]['hp'], 100000)

    def test_reaction_thresh_steals_only_after_accepted_same_lane_stuns(self):
        battle, owner, enemies = self.arena(1032, [(0,1050,100000), (0,1049,100000), (1,1050,100000)])
        for target in enemies:
            target.update(de_ph=1000, de_ma=500)
        owner_before = (battle._get_de_ph(owner), battle._get_de_ma(owner))
        battle._add_buff(enemies[0], 'purify', 1)
        battle._add_buff(enemies[0], 'stun', 1)
        battle._add_buff(enemies[2], 'stun', 1)
        self.assertEqual(battle._get_de_ph(enemies[0]), 1000)
        self.assertEqual(battle._get_de_ph(enemies[2]), 1000)
        self.assertTrue(self.cast(battle, owner, 'leader_skill'))
        self.assertTrue(battle._buff(enemies[0], 'stun'))
        self.assertTrue(battle._buff(enemies[0], 'curse'))
        self.assertIsNone(battle._buff(enemies[1], 'stun'))
        battle._remove_all_debuff(enemies[0])
        self.assertEqual((battle._get_de_ph(enemies[0]), battle._get_de_ma(enemies[0])), (800, 400))
        self.assertEqual((battle._get_de_ph(owner), battle._get_de_ma(owner)),
                         (owner_before[0]+200, owner_before[1]+100))

    def test_reaction_evelynn_target_gate_and_no_normal_dash(self):
        battle, owner, foes = self.arena(1033, [(0,1200,100000), (0,700,52000),(1,1100,100)])
        self.assertFalse(self.cast(battle, owner, 'leader_skill'))
        self.assertTrue(self.cast(battle, owner))
        self.assertEqual(owner['pos'], 1700)
        self.assertEqual(foes[0]['hp'], 100000)
        self.assertLess(foes[1]['hp'], 52000)
        foes[1]['hp'] = 40000
        self.assertFalse(self.cast(battle, owner, 'leader_skill'))
        foes[1]['hp'] = 39999
        owner['hp'] = 45000
        with patch.object(battle, '_native_damage', wraps=battle._native_damage) as hit:
            self.assertTrue(self.cast(battle, owner, 'leader_skill'))
        self.assertEqual([call.args[2] for call in hit.call_args_list], [9, 2.75])
        self.assertEqual(owner['hp'], owner['hp_max'])
        self.assertEqual(owner['pos'], 3000)
        self.assertIsNotNone(battle._buff(foes[0], 'silence'))
        self.assertEqual(foes[2]['hp'], 100)

    def test_reaction_elise_protection_and_execution(self):
        battle, owner, foes = self.arena(1036, [(0,1200,100000)])
        owner['hp'] = 35000
        battle._injured(owner,100,1,source=foes[0])
        self.assertEqual(owner['_skill_cd_b'], 6)
        battle._injured(owner,2000,7,source=foes[0],dot_kind='burn')
        self.assertEqual(owner['hp'], 34900)
        battle._run_unit_turn_base(owner, {1:battle.a, 2:battle.b}, 1)
        self.assertEqual(foes[0]['hp'], 100000)
        battle.turn_start(owner)
        battle._injured(owner,100,1,source=foes[0])
        self.assertEqual(owner['hp'], 34800)
        foes[0]['hp'] = 300
        with patch.object(battle,'_native_damage',wraps=battle._native_damage) as hit:
            self.assertTrue(self.cast(battle, owner,'leader_skill'))
        self.assertEqual(hit.call_args.args[2], 8)
        self.assertEqual(battle._buff_value(owner,'shield'), owner['hp_max'])
        self.assertEqual(owner['hp'], 35100)
        self.assertEqual(owner['_skill_cd_b'], 3)

    def test_reaction_zyra_death_plants_bypass_shared_cap_and_heal(self):
        battle, owner, enemies = self.arena(1040, [(0,1200,100000)], [(0,1950,95000),(0,2000,100000),(1,1950,95000)])
        self.assertTrue(self.cast(battle, owner, 'leader_skill'))
        self.assertTrue(self.cast(battle, owner))
        self.assertTrue(self.cast(battle, owner))
        active = [u for u in battle.a if u.get('_reaction_counted_plant') and u['hp']>0]
        self.assertEqual(len(active), 3)
        battle._injured(owner,100000,1,source=enemies[0])
        plants = [u for u in battle.a if u['aid']=='A_2326_5' and u['hp']>0]
        self.assertEqual(len(plants), 7)
        self.assertTrue(all(u['skill']['pl'][:2]==[0,2] for u in plants))
        plant = plants[-1]
        self.assertEqual(plant['pos'], owner['pos'])
        self.assertTrue(self.cast(battle, plant))
        self.assertEqual(battle.a[1]['hp'], 95000+battle._get_damage(plant))
        self.assertIsNotNone(battle._buff(battle.a[2], 'purify'))
        self.assertEqual(battle.a[3]['hp'], 95000)

    def test_extended_death_observers_and_jinx_independent_stacks(self):
        battle, owner, enemies = self.arena(1115, [(0,1300,30), (1,900,10), (1,800,1000), (0,1050,90000)])
        battle._injured(enemies[0], 30, 3, source=owner)
        self.assertEqual(battle.six_batch_jinx_stacks(owner), [3])
        battle.turn_start(owner)
        self.assertTrue(self.cast(battle, owner, 'leader_skill'))
        self.assertEqual([u['hp'] for u in enemies[:3]], [0, 0, 0])
        self.assertEqual(battle.six_batch_jinx_stacks(owner), [3, 4, 4])
        self.assertEqual(battle.six_batch_speed(owner), 2.8)
        for _ in range(3):
            battle.turn_start(owner)
        self.assertEqual(battle.six_batch_jinx_stacks(owner), [4, 4])
        self.assertTrue(self.cast(battle, owner))
        self.assertLess(enemies[3]['hp'], 86000)

        battle, owner, enemies = self.arena(1117, [(0,1000,25), (0,700,100000), (0,699,100000), (1,1000,100000)])
        battle._injured(enemies[0], 25, 3, source=owner)
        self.assertLess(enemies[1]['hp'], 100000)
        self.assertEqual([u['hp'] for u in enemies[2:]], [100000, 100000])

    def test_extended_kayle_and_yasuo(self):
        battle, owner, enemies = self.arena(1119, [(0,1200,100000)])
        owner['new_4attrs']['crit'] = 250
        self.assertEqual(battle._get_crit(owner), 500)
        battle._injured(owner, 1000, 1, source=enemies[0])
        self.assertEqual(owner['hp'], owner['hp_max'])
        self.assertEqual(battle._buff_value(owner, 'shield'), 59000)
        self.assertEqual(owner['_skill_cd_b'], 8)
        battle._emit_mod_event(owner, 'crit', owner, enemies[0])
        self.assertEqual(owner['_skill_cd_b'], 7)
        battle._remove_buff(owner, 'shield')
        battle._injured(owner, 1000, 1, source=enemies[0])
        self.assertIsNone(battle._buff(owner, 'shield'))

        battle, owner, enemies = self.arena(1120, [(0,1200,100000),(0,1100,100000),(0,1000,100000),(1,1200,100000)])
        battle.round_index = 6
        self.assertNotEqual(battle._get_range(owner), 3000)
        battle.round_index = 7
        self.assertEqual(battle._get_range(owner), 3000)
        battle.round_index = 21
        with patch.object(battle, '_native_damage', wraps=battle._native_damage) as hit:
            battle._basic_attack(owner, enemies[0])
        for foe in enemies[:3]:
            coefficients = [call.args[2] for call in hit.call_args_list if call.args[1] is foe]
            self.assertEqual(coefficients, [battle._true_skill_coefficient(x) for x in (3, 1.5, 1.5)])
        self.assertEqual(len({enemy['hp'] for enemy in enemies[:3]}), 1)
        self.assertLess(enemies[0]['hp'], 100000)
        self.assertEqual(enemies[3]['hp'], 100000)
        battle.round_index = 28
        old_hit = battle._get_hit(owner)
        self.assertTrue(self.cast(battle, owner, 'leader_skill'))
        battle._remove_all_good(owner)
        self.assertEqual(battle._get_hit(owner), old_hit+2000)
        self.assertEqual(battle.state(owner)['batch_kayle_guard'][0], battle.state(owner)['serial']+2)
        battle._injured(owner,1000,1,source=enemies[0])
        self.assertEqual(owner['hp'], owner['hp_max']-10)

    def test_extended_sand_soldier_and_shaco_summons(self):
        battle, owner, enemies = self.arena(1124, [(0,1300,100000)], [(0,1850,100000),(1,1750,100000)])
        owner['new_4attrs'].update(hit=137, flee=321, crit=444, tough=555)
        panel = battle._summon_panel_snapshot(owner)
        self.assertTrue(self.cast(battle, owner))
        soldier = battle.a[-1]
        self.assertEqual((soldier['aid'], soldier['hp_max'], soldier['ap']), ('A_3002_2',800000,0))
        self.assertEqual((soldier['de_ph'], soldier['de_ma']), (panel['de_ph'], panel['de_ma']))
        self.assertEqual(soldier['new_4attrs'], dict(hit=0, flee=0, crit=0, tough=0))
        self.assertIsNone(soldier['skill'])
        before = enemies[0]['hp']
        battle._run_unit_turn_base(soldier, {1:battle.a, 2:battle.b}, 1)
        self.assertEqual(enemies[0]['hp'], before)
        self.assertEqual(battle._native_damage(soldier, enemies[0], 1, 1), 0)
        soldier['hp'] = 1
        self.assertTrue(self.cast(battle, owner, 'leader_skill'))
        self.assertEqual(soldier['hp'], soldier['hp_max'])
        self.assertEqual(battle._buff_value(battle.a[1], 'strong'), .8)
        self.assertIsNone(battle._buff(battle.a[2], 'strong'))

        battle, owner, enemies = self.arena(1128, [(0,1300,100000), (1,1600,100000)])
        self.assertTrue(self.cast(battle, owner))
        box = battle.a[-1]
        self.assertEqual((box['aid'], box['pos'], box['hp_max']), ('A_2019_5',1700,80000))
        self.assertTrue(self.cast(battle, owner, 'leader_skill'))
        clone = battle.a[-1]
        self.assertEqual(clone['hp_max'], owner['hp_max'])
        self.assertTrue(clone['skill'])
        self.assertIsNone(clone['leader_skill'])
        self.assertIsNone(clone['skillB'])
        battle._add_buff(enemies[1], 'purify', 1)
        battle._add_buff(enemies[1], 'curse', 2, source=owner)
        self.assertIsNone(battle._buff(enemies[1], 'poison'))
        battle._add_buff(enemies[1], 'curse', 2, source=owner)
        self.assertGreater(battle._buff_value(enemies[1], 'poison'), 0)

    def test_extended_global_targeting_and_ziggs_heal_reduction(self):
        battle, owner, enemies = self.arena(1123, [(0,1300,100000), (1,900,100000)])
        battle._add_buff(enemies[0], 'taunt', 2)
        self.assertTrue(self.cast(battle, owner))
        for foe in enemies:
            self.assertLess(foe['hp'], 100000)
            self.assertIsNotNone(battle._buff(foe, 'curse'))
            self.assertAlmostEqual(battle._buff_value(foe, 'weak'), .25)

        battle, owner, enemies = self.arena(1125, [(0,1600,100000), (1,1300,100000),(1,1000,100000),(1,899,100000)])
        enemies[1]['hp_max'] = 200000
        self.assertTrue(self.cast(battle, owner, 'leader_skill'))
        self.assertEqual(enemies[0]['hp'], 100000)
        self.assertLess(enemies[1]['hp'], enemies[2]['hp'])
        self.assertLess(enemies[2]['hp'], enemies[3]['hp'])
        missing = enemies[1]['hp']
        battle._injured(enemies[1], 1000, 4, source=enemies[1])
        self.assertEqual(enemies[1]['hp'], missing+400)
        battle._remove_all_debuff(enemies[1])
        battle._injured(enemies[1], 1000, 4, source=enemies[1])
        self.assertEqual(enemies[1]['hp'], missing+1400)

        battle, owner, enemies = self.arena(1126, [(0,1300,100000)])
        for end_round, damage in ((9, 1000), (10, 1300), (20, 1600)):
            battle.round_index = end_round
            battle._remove_all_good(owner)
            before = enemies[0]['hp']
            battle._injured(enemies[0], 1000, 2, source=owner)
            self.assertEqual(before-enemies[0]['hp'], damage)

        battle, owner, enemies = self.arena(1136, [(0,300,100000), (1,1600,100000)])
        self.assertTrue(self.cast(battle, owner, 'leader_skill'))
        self.assertLess(enemies[0]['hp'], 92000)
        self.assertEqual(enemies[1]['hp'], 100000)

    def test_extended_vayne_twisted_fate_and_gabriel(self):
        battle, owner, enemies = self.arena(1206, [(0,1300,100000), (0,400,100000), (1,300,100000)])
        battle._basic_attack(owner,enemies[0])
        self.assertTrue(self.cast(battle, owner))
        self.assertEqual(enemies[1]['hp'], 100000)
        with patch.object(battle, '_native_damage', wraps=battle._native_damage) as hit:
            self.assertTrue(self.cast(battle, owner, 'leader_skill'))
        self.assertTrue(any(call.args[1] is enemies[1] and call.args[2:4] == (battle._true_skill_coefficient(6), 3)
                            for call in hit.call_args_list))
        self.assertEqual(enemies[1]['pos'], 0)
        self.assertLess(enemies[1]['hp'], 100000)
        self.assertIsNotNone(battle._buff(enemies[1], 'curse'))
        self.assertIsNotNone(battle._buff(owner, 'bless'))

        battle, owner, enemies = self.arena(1214, [(0,1400,100000),(1,1300,100000),(1,1200,100000),(2,1300,100000),(2,2500,100000)])
        self.assertFalse(self.cast(battle, owner, 'leader_skill'))
        owner['hp'] = 80000
        self.assertTrue(self.cast(battle, owner, 'leader_skill'))
        self.assertEqual(owner['hp'], 86000)
        self.assertEqual(battle._buff_value(owner, 'shield'), 25000)
        self.assertEqual(battle._buff_value(owner, 'steel'), 2)
        self.assertTrue(self.cast(battle, owner))
        self.assertEqual(sum(foe['hp']<100000 for foe in enemies), 4)
        foe = enemies[1]
        battle._add_buff(foe, 'hitup', 2, 800)
        for _ in range(3):
            battle._injured(foe,100,2,source=owner)
        self.assertIsNone(battle._buff(foe, 'hitup'))
        self.assertEqual(battle._buff_value(owner, 'hitup'), 800)
        for _ in range(4):
            battle._injured(foe,100,2,source=owner)
        self.assertIsNotNone(battle._buff(foe, 'curse'))

        battle, owner, enemies = self.arena(1998, [(0,1300,100000)], [(0,1800,100000), (0,1900,100000), (1,1800,100000)])
        owner['_skill_cd'] = -1
        self.assertTrue(battle._use_skill_slot(owner, enemies, 'skill', '_skill_cd'))
        self.assertEqual(owner['_skill_cd'], 2)

    def test_existing_event_passives(self):
        b, owner, enemies = self.arena(1001, [(0,1400,100000)])
        foe=enemies[0]
        b._add_buff(owner,'weak',2,.1)
        self.assertTrue(b._emit_mod_event(owner,'shield_break',foe,owner))
        self.assertAlmostEqual(b._buff_value(owner,'strong'),.5)
        # The purify layer was spent cancelling the weakness.
        self.assertIsNone(b._buff(owner,'purify'))
        self.assertIsNone(b._buff(owner,'weak'))

        b, owner, enemies = self.arena(1002, [(0,1400,100000)])
        foe=enemies[0]
        b._add_buff(foe,'stun',1)
        self.assertEqual([b._emit_mod_event(owner,'hit',owner,foe,1) for _ in range(3)], [True,True,False])

        b, owner, enemies = self.arena(1004, [(0,1400,100000)], [(0,1650,100000)])
        ally=b.a[1]
        self.assertFalse(b._emit_mod_event(owner,'heal_done',owner,ally,100))
        ally['hp']-=10000
        self.assertTrue(b._emit_mod_event(owner,'heal_done',owner,ally,100))

        b, owner, enemies = self.arena(1015, [(0,1400,100000)])
        foe=enemies[0]
        self.assertFalse(b._emit_mod_event(owner,'damage_taken',foe,owner,1))
        self.assertTrue(b._emit_mod_event(owner,'dodge',foe,owner))

    def test_defense_and_formation(self):
        b, owner, enemies = self.arena(1007, [(0,1400,100000),(0,100,100000),(1,1400,100000)])
        self.assertTrue(self.cast(b,owner))
        self.assertEqual([bool(b._buff(e,'stun')) for e in enemies],[True,True,False])
        b._basic_attack(owner,enemies[0])
        self.assertAlmostEqual(b._buff_value(enemies[0],'weak'),.5)
        self.assertAlmostEqual(b._buff_value(enemies[0],'sunder'),.5)

        b, owner, enemies = self.arena(1013, [(0,1500,100000),(0,500,100000),(1,1500,100000)])
        for foe in enemies:
            b._add_buff(foe,'shield',2,5000)
            b._add_buff(foe,'purify',2)
        self.assertTrue(self.cast(b,owner,'leader_skill'))
        for foe in enemies[:2]:
            self.assertFalse(b._buff(foe,'shield'))
            self.assertFalse(b._buff(foe,'purify'))
            self.assertTrue(b._buff(foe,'silence'))
        self.assertTrue(b._buff(enemies[2],'shield'))
        self.assertTrue(b._use_turn_start_passive(owner,enemies))
        self.assertEqual(b._buff_value(owner,'shield'),80000)

        b, owner, enemies = self.arena(1018, [(0,1400,100000)],
                                       [(0,1750,90000),(1,1800,1000)])
        self.assertTrue(self.cast(b,owner,'leader_skill'))
        self.assertEqual(owner['line'],1)
        self.assertTrue(b._buff(b.a[2],'shield'))
        self.assertFalse(b._buff(b.a[1],'shield'))
        self.assertTrue(b._buff(owner,'taunt'))

    def test_active_skill_and_kill_recast(self):
        b, owner, enemies = self.arena(1006, [(0,1400,100000)], [(0,1750,50000),(0,1780,60000),(0,1500,70000)])
        self.assertTrue(self.cast(b,owner))
        self.assertEqual([ally['hp'] for ally in b.a[1:]],[56000,66000,70000])

        b, owner, enemies = self.arena(1010, [(0,1450,10),(0,1400,100000),(0,1350,100000)])
        with patch.object(b,'_apply_native_skill',wraps=b._apply_native_skill) as cast:
            self.assertTrue(self.cast(b,owner,'leader_skill'))
            self.assertEqual([call.args[2] for call in cast.call_args_list],['leader_skill','skill'])
        self.assertAlmostEqual(b._buff_value(owner,'strong'),.4)
        self.assertEqual(owner['_skill_cd'],1)

        b, owner, enemies = self.arena(1016, [(0,1450,100000),(0,1370,100000),(0,1290,100000),(1,1300,100000)])
        b._add_buff(enemies[0],'stun',2)
        b._add_buff(enemies[1],'stun',2)
        self.assertEqual([u['hp'] for u in enemies],[100000]*4)
        owner['_skill_cd_b']=-1
        b._add_buff(enemies[3],'stun',2)
        self.assertEqual([u['hp'] for u in enemies],[100000]*4)
        b._add_buff(enemies[2],'stun',2)
        self.assertEqual(owner['_skill_cd_b'],0)
        self.assertEqual([u['hp']<100000 for u in enemies],[True,True,True,False])
        owner['hp']=50000
        self.assertTrue(self.cast(b,owner))
        self.assertGreater(owner['hp'],50000)

        b, owner, enemies = self.arena(1021, [(0,1490,100000),(0,1360,100000),(0,1230,100000),(0,1080,100000),(1,1400,100000)])
        with patch.object(b,'_native_damage',wraps=b._native_damage) as hit:
            self.assertTrue(self.cast(b,owner,'leader_skill'))
            # The third hit also triggers the separate 150% passive.
            self.assertEqual([id(call.args[1]) for call in hit.call_args_list],
                             [id(enemies[i]) for i in (0,1,2,2,3)])
            self.assertEqual([round(call.args[2],4) for call in hit.call_args_list],
                             [3.25,2.7083,2.1667,1.5,1.625])

    def test_wukong_clone_and_heimer_turrets(self):
        b, owner, enemies = self.arena(1005, [(0,1550,100000)])
        self.assertTrue(self.cast(b,owner))
        clone=b.a[-1]
        self.assertEqual(clone['ap'],owner['ap'])
        self.assertEqual(clone['hp_max'],owner['hp_max'])
        with patch.object(b,'_native_damage',wraps=b._native_damage) as hit:
            b._basic_attack(owner,enemies[0])
            self.assertTrue(any(entry.args[0] is clone for entry in hit.call_args_list))
            hit.reset_mock()
            self.assertTrue(self.cast(b,owner,'leader_skill'))
            self.assertTrue(any(entry.args[0] is clone for entry in hit.call_args_list))

        b, owner, enemies = self.arena(1014, [(0,1500,100000),(0,1400,100000)])
        self.assertTrue(self.cast(b,owner))
        self.assertTrue(b._buff(enemies[0],'silence'))
        self.assertTrue(self.cast(b,owner,'leader_skill'))
        self.assertEqual(len(b.a),4)
        for turret in b.a[1:]:
            with self.subTest(turret=turret.get('_six_turret_cast','passive')):
                self.assertEqual(b._get_range(turret),1000)
                self.assertEqual(turret['ap'],1200)
                self.assertEqual(turret['hp_max'],120000)
                turret['hp']=100
                b.turn_start(turret)
                self.assertEqual(turret['hp'],36100)
                location=(turret['line'],turret['pos'])
                b._check_move(turret,True,300)
                b._reline(turret,2,0)
                self.assertEqual((turret['line'],turret['pos']),location)

    def test_kill_and_dot_state(self):
        b, owner, enemies = self.arena(1012, [(0,1500,1),(0,1400,100000),(0,1300,100000)])
        self.assertTrue(self.cast(b,owner,'leader_skill'))
        b._add_buff(owner,'weak',1,.5)
        self.assertFalse(b._buff(owner,'weak'))
        owner['_skill_cd']=-1
        self.assertTrue(b._use_skill_slot(owner,enemies,'skill','_skill_cd'))
        self.assertEqual(owner['_skill_cd'],-1)
        self.assertEqual(b.state(owner)['highlander']['until'],3)
        target=enemies[2]
        true_bonus=[]
        for defense in (0,1000000):
            target['de_ph']=defense
            with patch.object(b,'_injured',wraps=b._injured) as injure:
                b._basic_attack(owner,target)
                true_bonus.append([call.args[1] for call in injure.call_args_list if call.args[2]==3])
        self.assertEqual(true_bonus[0],true_bonus[1])
        self.assertGreater(true_bonus[0][0],0)

        b, owner, enemies = self.arena(1019, [(0,1490,100000)])
        for _ in range(5):
            b._basic_attack(owner,enemies[0])
        dots=enemies[0]['_manual_dots']
        self.assertEqual(len(dots),5)
        self.assertTrue(b.state(owner)['six_bloodrage'])
        self.assertEqual(b._get_damage(owner),2000)
        b._tick_manual_skill_dots(enemies[0])
        b._basic_attack(owner,enemies[0])
        self.assertEqual([entry['round'] for entry in dots.values()],[3]*5)

        b, owner, enemies = self.arena(1023, [(0,1490,100000),(0,1800,100000)])
        self.assertTrue(self.cast(b,owner))
        self.assertEqual(enemies[1]['hp'],100000)
        self.assertFalse(enemies[0].get('_manual_dots'))
        self.assertTrue(self.cast(b,owner))
        self.assertEqual(len(enemies[0]['_manual_dots']),1)

    def test_lanes_delayed_shots_and_fire_mark(self):
        b, owner, enemies = self.arena(1011, [(0,1550,100000),(0,1250,100000),(0,1040,100000),(1,1540,100000)])
        self.assertTrue(self.cast(b,owner,'leader_skill'))
        self.assertLess(enemies[0]['hp'],100000)
        self.assertLess(enemies[1]['hp'],100000)
        self.assertEqual(enemies[2]['hp'],100000)
        self.assertEqual(enemies[3]['hp'],100000)
        b._basic_attack(owner,enemies[0])
        fire=next(iter(enemies[0]['_manual_dots'].values()))
        self.assertEqual((fire['kind'],fire['round'],fire['apTick']),('burn',2,2000))

        b, owner, enemies = self.arena(1022, [(0,1490,100000),(0,620,100000),(0,200,100000),(1,1500,100000)])
        self.assertTrue(self.cast(b,owner))
        self.assertEqual([foe['hp']<100000 for foe in enemies],[True,True,False,False])
        b._injured(owner,1000,4)
        self.assertEqual(b._buff_value(owner,'hitup'),3000)
        self.assertEqual(b._buff_value(owner,'fleeup'),3000)

        b, owner, enemies = self.arena(1025, [(0,1510,100000),(1,10,90000)])
        self.assertTrue(self.cast(b,owner))
        target=enemies[0]
        before=target['hp']
        target.update(line=2,pos=0)
        b.turn_start(owner)
        self.assertLess(target['hp'],before)
        self.assertEqual(b._get_range(owner),1350)
        before=enemies[1]['hp']
        enemies[1]['hp']=1000
        self.assertTrue(self.cast(b,owner,'leader_skill'))
        self.assertLess(enemies[1]['hp'],1000)
        self.assertGreater(before,1000)

    def test_followup_rank_endpoints_and_timing(self):
        expected = {
            (1008,10):(1,1), (1008,11):(2,0), (1024,10):(0,1), (1024,11):(2,2),
            (1026,10):(1,2), (1026,11):(2,2), (1130,10):(0,1), (1130,11):(2,3),
            (1131,10):(1,2), (1131,11):(2,2), (1132,11):(2,2), (1133,10):(0,3),
            (1133,11):(0,4), (1135,10):(2,1), (1135,11):(3,2), (1142,10):(0,0),
        }
        for key, value in expected.items():
            with self.subTest(hero=key[0],slot=key[1]):
                self.assertEqual(tuple(self.snapshot(*key)['pl'][:2]),value)
        for ident,slot,step,field,value in (
            (1024,10,1,1,4.25),(1024,11,0,4,2),(1024,11,0,5,.5),(1024,11,0,6,3.75),
            (1026,10,3,1,.5),(1026,10,4,1,.6),(1026,11,0,4,6.75),(1026,11,0,5,3.5),
            (1130,10,0,4,2.5),(1130,10,0,5,.12),(1130,11,0,4,1.75),
            (1131,10,0,4,4),(1131,10,0,5,1.25),(1131,10,0,6,.66),
            (1132,10,0,4,2),(1133,10,0,4,2.75),(1133,11,0,5,6.66),
            (1138,10,0,1,2.5),(1138,11,4,1,15),(1138,11,1,1,1.2),(1138,11,2,1,3.5),
            (1142,10,2,1,2.25),(1202,10,0,4,0),
        ):
            with self.subTest(hero=ident,slot=slot,step=step,field=field):
                self.assertAlmostEqual(self.snapshot(ident,slot)['skills'][step][field],value)
        combo=self.snapshot(1026)['skills'][2]
        self.assertAlmostEqual(combo[1]+combo[4],3.6)
        self.assertEqual(self.snapshot(1130,level=1)['skills'][0][6],1)

    def test_irelia_front_recast_numbers_and_immunity(self):
        b, owner, enemies = self.arena(1024, [(0,700,100000),(0,1600,1),(0,1400,100000),(1,1620,100000)])
        with patch.object(b,'_native_damage',wraps=b._native_damage) as damage:
            self.assertTrue(self.cast(b,owner))
            hits=[call.args[1] for call in damage.call_args_list if call.args[2]==4.25]
            self.assertEqual([id(u) for u in hits],[id(enemies[1]),id(enemies[2])])
        self.assertTrue(self.cast(b,owner,'leader_skill'))
        self.assertTrue(b.state(owner)['six_irelia_immune'])
        self.assertAlmostEqual(b._buff_value(enemies[2],'sunder'),1)
        for kind in ('weak','silence','sunder','curse','stun'):
            b._add_buff(owner,kind,2,1)
            self.assertFalse(b._buff(owner,kind))
        self.assertEqual(enemies[-1]['hp'],100000)
        target=enemies[0]
        before=target['hp']
        b._injured(target,1000,3,source=owner)
        self.assertEqual(before-target['hp'],1250)

    def test_lee_sweeps_only_the_knockback_path_and_empowers_one_auto(self):
        b, owner, enemies = self.arena(1026, [(0,1550,100000),(0,1080,100000),(0,600,100000),(1,1100,100000)])
        with patch.object(b,'_native_damage',wraps=b._native_damage) as damage:
            self.assertTrue(self.cast(b,owner,'leader_skill'))
            self.assertEqual([call.args[2] for call in damage.call_args_list],[6.75,3.5])
        self.assertEqual(enemies[0]['pos'],750)
        self.assertEqual([u['hp'] for u in enemies[2:]],[100000,100000])
        with patch.object(b,'_native_damage',wraps=b._native_damage) as damage:
            b._basic_attack(owner,enemies[0])
            self.assertEqual([call.args[2] for call in damage.call_args_list],[1,2,2,2])
            damage.reset_mock()
            b._basic_attack(owner,enemies[0])
            self.assertEqual([call.args[2] for call in damage.call_args_list],[1])

    def test_veigar_growth_and_zed_lock(self):
        b, owner, enemies = self.arena(1027, [(0,200,100000),(0,1250,100000),(0,1550,100000),(1,1700,100000)])
        self.assertTrue(self.cast(b,owner))
        self.assertEqual([u['hp']<100000 for u in enemies],[False,True,True,False])
        self.assertEqual(b.state(owner)['evil_stacks'],1)
        self.assertAlmostEqual(b.state(owner)['evil_bonus'],.07)

        b, owner, enemies = self.arena(1132, [(0,1550,100000),(0,1000,100000),(1,1550,100000),(0,1500,100000)])
        enemies[-1]['tpl'][1]=3
        b.rng.get_random=lambda bound: 1 if bound==2 else 99
        self.assertTrue(self.cast(b,owner))
        self.assertEqual([u['hp']<100000 for u in enemies],[False,True,False,False])
        self.assertEqual(b._buff(enemies[1],'poison').round,2)

    def test_fiora_crit_and_waltz(self):
        b, owner, enemies = self.arena(1130, [(0,1400,100000),(0,1300,100000),(0,680,100000)])
        for foe in enemies:
            foe['new_4attrs']['tough']=25000
        with patch.object(b,'_final_direct_damage',wraps=b._final_direct_damage) as settle:
            self.assertTrue(self.cast(b,owner))
            self.assertEqual(len(settle.call_args_list),2)
            self.assertEqual([call.args[2] for call in settle.call_args_list],[1,1])
            settle.reset_mock()
            self.assertTrue(self.cast(b,owner))
            self.assertEqual(len(settle.call_args_list),2)
            self.assertTrue(all(call.args[2]>1 and call.args[3] for call in settle.call_args_list))
        self.assertGreater(b._buff_value(owner,'shield'),0)
        owner['_buffs'].pop('shield',None)
        before=sum(u['hp'] for u in enemies)
        b.rng.get_random=lambda bound: 0 if bound<100 else 99
        self.assertTrue(self.cast(b,owner,'leader_skill'))
        loss=before-sum(u['hp'] for u in enemies)
        self.assertEqual(b._buff_value(owner,'shield'),int(loss*.5))

    def test_nami_one_charge_per_cast_and_one_bonus_per_hit(self):
        b, owner, enemies = self.arena(1131, [(0,1400,100000),(0,1320,100000),(1,1470,100000)],
                                       [(0,1750,70000),(0,1760,70000),(1,1800,70000)])
        first,target,cross=b.a[1:]
        self.assertTrue(self.cast(b,owner))
        self.assertEqual([u['hp'] for u in b.a[1:]],[70000,74000,70000])
        aura=b.state(target)['six_nami_bless']
        target['speed']=200
        cross['speed']=200
        self.assertEqual((b._get_speed(target),b._get_speed(cross)),(400,200))
        with b.context(target,'active',{'skid':'test'}):
            with patch.object(b,'_injured',wraps=b._injured) as injured:
                for victim in (enemies[0],enemies[0],enemies[1]):
                    b._native_damage(target,victim,1,1)
                # Fixed true damage: full panel (1250) under the global scale, then toughness.
                bonus = [call.args[:2] for call in injured.call_args_list if call.args[2] == 3]
                self.assertEqual(bonus, [(enemies[0], 660), (enemies[0], 660), (enemies[1], 660)])
        self.assertEqual(aura['left'],2)
        with patch.object(b, '_fixed_true_damage', wraps=b._fixed_true_damage) as bonus:
            for remaining in (1, 0):
                b._basic_attack(target, enemies[0])
                self.assertEqual(aura['left'], remaining)
            self.assertEqual(bonus.call_count, 2)
            b._basic_attack(target, enemies[0])
            self.assertEqual(bonus.call_count, 2)
        self.assertAlmostEqual(b._buff_value(enemies[0],'weak'),.66/.34)
        self.assertTrue(self.cast(b,owner,'leader_skill'))
        self.assertTrue(b.state(enemies[0])['six_nami_slow'])
        self.assertFalse(b.state(enemies[2]).get('six_nami_slow'))

    def test_morgana_links_amplify_direct_damage_only_and_expire(self):
        b, owner, enemies = self.arena(1133, [(0,1400,100000),(0,1250,100000),(1,1350,100000)])
        primary,enclosed,cross=enemies
        self.assertTrue(self.cast(b,owner,'leader_skill'))
        self.assertEqual(b._buff_value(owner,'shield'),20000)
        self.assertTrue(b._buff(owner,'purify'))
        b._injured(primary,1000,3,source=owner)
        b._injured(cross,1000,3,source=owner)
        self.assertEqual([primary['hp'],cross['hp']],[98400,99000])
        b._injured(primary,1000,6,source=owner,dot_kind='bleed')
        b._injured(cross,1000,6,source=owner,dot_kind='bleed')
        self.assertEqual(primary['hp']-cross['hp'],-600)
        enclosed['line']=1
        for _ in range(2):
            b.turn_start(owner)
        self.assertEqual(enclosed['hp'],100000)
        b.turn_start(owner)
        self.assertLess(enclosed['hp'],100000)
        self.assertTrue(b._buff(enclosed,'stun'))
        self.assertFalse(b.state(enclosed)['six_morgana_sources'])

    def test_rengar_skill_crit_tahm_grey_and_polar_growth(self):
        from combat_math import crit_chance
        b, owner, enemies = self.arena(1135, [(0,1480,100000)])
        target=enemies[0]
        roll=crit_chance(b._get_crit(owner),b._get_tough(target),b._attack,b._combat_rules)
        self.assertGreater(roll,0)
        with patch.object(b,'_final_direct_damage',wraps=b._final_direct_damage) as settle:
            with b.context(owner,'basic'):
                rng=iter([99,roll])
                b.rng.get_random=lambda limit:next(rng)
                b._native_damage(owner,target,1,1)
            with b.context(owner,'active',owner['skill']):
                rng=iter([99,roll])
                b.rng.get_random=lambda limit:next(rng)
                b._native_damage(owner,target,1,1)
            self.assertEqual(settle.call_args_list[0].args[2],1)
            self.assertGreater(settle.call_args_list[1].args[2],1)

        b, owner, enemies = self.arena(1138, [(0,600,100000)])
        self.assertFalse(self.cast(b,owner,'leader_skill'))
        self.assertIsNone(b._buff(owner,'strong'))
        enemies[0]['pos']=1550
        self.assertTrue(self.cast(b,owner,'leader_skill'))
        self.assertAlmostEqual(b._buff_value(owner,'strong'),1.2)
        b._injured(owner,10000,3,source=enemies[0])
        self.assertEqual(owner['hp'],90000)
        b.turn_start(owner)
        self.assertEqual(owner['hp'],95000)

        b, owner, enemies = self.arena(1202, [(0,1400,100000)])
        owner['new_4attrs']['crit']=1000
        self.assertTrue(self.cast(b,owner))
        self.assertFalse(b._buff(owner,'critup'))
        b.turn_start(owner)
        self.assertEqual(b._get_crit(owner),1100)
        b.turn_start(owner)
        self.assertEqual(b._get_crit(owner),1200)
        self.assertTrue(self.cast(b,owner,'leader_skill'))
        self.assertEqual(b._buff(enemies[0],'stun').round,2)
