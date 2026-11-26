import copy
from pathlib import Path
import unittest
from battle_engine import base_unit
from gateway import load_game_config
from manual_ability_sim import SkillCompleteBattle
from native_skill_snapshot import _native_skill_snapshot
from demonblade_tryndamere_105 import AID, FIVE_STAR_AID, NORMAL, CAPTAIN, PASSIVE, apply_demonblade_tryndamere

ROOT = Path(__file__).resolve().parents[1]


class DemonbladeTryndamereTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cfg = load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']

    def battle(self, count=1, allies=0, critical=False, rank=1, aid=AID):
        c = copy.deepcopy(self.cfg)
        c['combat_rules'] = {}
        a = c['system_simple']['attack']
        a[2] = 1
        a[4] = a[15] = a[16] = 0
        a[5] = 100 if critical else 0
        a[7] = 100
        a[3] = 2
        a[21] = 1
        def unit(aid, side, pos, leader=False):
            u = base_unit(c, aid, 1, rank, 0, .2, leader, side)
            u.update(pos=pos, hp=100000, hp_max=100000, ap=100, de_ph=0, de_ma=0)
            u['new_4attrs'] = dict(hit=1000000, flee=0, crit=0, tough=0)
            return u
        owner = unit(aid, 1, 2400, True)
        friends = [unit('A_1001_6', 1, 2600+i*100) for i in range(allies)]
        enemies = [unit('A_1001_6', 2, 1400-i*150) for i in range(count)]
        b = SkillCompleteBattle([owner]+friends, enemies, config=c, trace_abilities=True)
        return b, b.a[0], b.a[1:], b.b

    def cast(self, b, o, captain=False):
        slot = 'leader_skill' if captain else 'skill'
        skill = o[slot]
        with b.context(o, 'active', skill=skill):
            return b.execute(o, 'demon_trynd_c' if captain else 'demon_trynd_n', 1, skill)

    def test_configuration_panel_ranks_and_acquisition(self):
        c = self.cfg
        h = c['avatar'][AID]
        self.assertEqual(h['pl'][:8], c['avatar']['A_1206_6']['pl'][:8])
        self.assertEqual((h['res'], h['role'], h['hero_category_104'], h['tl'][2]), ('MOD_DEMONBLADE_6', '战士', 'skin', 1))
        self.assertEqual(h['pl'][9], 350)
        self.assertEqual(h['pl'][10:14], [NORMAL, CAPTAIN, h['pl'][12], PASSIVE])
        self.assertEqual(c['skill'][NORMAL]['pl'][:2], [0, 1])
        self.assertEqual(c['skill'][CAPTAIN]['pl'][:2], [1, 3])
        for rank, value in ((1, 1.6), (10, 3.2)):
            self.assertAlmostEqual(_native_skill_snapshot(c, NORMAL, rank)['skills'][0][4], value)
        for sid in (CAPTAIN, PASSIVE):
            self.assertEqual(_native_skill_snapshot(c, sid, 10)['skills'], _native_skill_snapshot(c, sid, 1)['skills'])
        for pool in ('advanced', 'vip'):
            self.assertEqual(sum(x['id'] == AID for x in c['summon_calibration']['pools'][pool]['qualities']['orange']['cards']), 1)
        self.assertIn(AID, c['system_simple']['skin_hero_ids'])
        fresh = copy.deepcopy(c)
        apply_demonblade_tryndamere(fresh)
        self.assertEqual(fresh, c)

    def test_five_star_keeps_rage_without_endless_rage_or_other_passive_bonuses(self):
        hero = self.cfg['avatar'][FIVE_STAR_AID]
        self.assertEqual(hero['res'], 'MOD_DEMONBLADE_5')
        self.assertEqual(hero['pl'][:8], self.cfg['avatar']['A_1206_5']['pl'][:8])
        passive = self.cfg['skill'][hero['pl'][13]]
        self.assertEqual([note[0] for note in passive['tipNotes105']], ['怒气'])
        b, owner, _, enemies = self.battle(aid=FIVE_STAR_AID)
        self.assertEqual(b.demon_rage(owner), 20)
        self.assertEqual(b.demon_basic_ratio(owner), 1)
        self.assertEqual(b._crit_damage_rate(owner), 1)
        owner['hp'] //= 2
        self.assertEqual(b._get_damage(owner), 100)
        self.assertTrue(self.cast(b, owner))
        self.assertEqual(b.demon_rage(owner), 25)
        self.assertAlmostEqual(b.demon_crit_bonus(owner), 10)
        b._injured(owner, 200000, 1, source=enemies[0])
        self.assertLessEqual(owner['hp'], 0)
        self.assertFalse(b.demon_fury(owner))

    def test_bonds_equipment_and_rage_cap(self):
        from bonds_104 import active_bonds, apply_stats
        from equipment_bonds_104 import equipped_bonds, apply_equipment_stats
        allies = [AID, 'A_1009_6', 'A_1012_6', 'A_1202_6', 'A_1203_6']
        active = active_bonds(self.cfg, AID, allies)
        self.assertTrue({'demonblade_brothers_105', 'demonblade_ashe_105', 'demonblade_ryze_105'}
                        <= {row['id'] for row in active})
        for aid in allies[1:3]:
            rows = [row for row in active_bonds(self.cfg, aid, allies) if row['id'] == 'demonblade_brothers_105']
            stats = {'ap': 100, 'hp': 100}
            apply_stats(stats, aid, rows)
            self.assertEqual(stats, {'ap': 120, 'hp': 120})
        b, o, _, en = self.battle(3)
        o['bonds_104'] = [r['id'] for r in active]
        o['equipment_bonds_104'] = ['E_1004_5', 'E_5001_5']
        self.assertEqual(b.demon_basic_ratio(o), 2.35)
        stats = {'ap': 100, 'hp': 100}
        apply_equipment_stats(stats, equipped_bonds(self.cfg, AID, o['equipment_bonds_104']))
        self.assertEqual(stats, {'ap': 114, 'hp': 114})
        b._add_buff(en[1], 'summon', 4, source=en[0])
        self.assertTrue(self.cast(b, o))
        self.assertEqual([100000-u['hp'] for u in en], [208, 416, 208])
        self.assertTrue(all(b._buff(u, 'curse') is not None for u in en))
        self.assertEqual(b.demon_rage(o), 42.5)
        for _ in range(6):
            b.demon_hurt(o)
        self.assertEqual(b.demon_rage(o), 54.5)
        b.demon_gain(o, 100)
        self.assertEqual(b.demon_rage(o), 100)

    def test_normal_dashes_to_front_hits_three_sunders_and_primes_crit(self):
        b, o, _, en = self.battle(5)
        en[4]['line'] = 1
        self.assertTrue(self.cast(b, o))
        self.assertEqual(o['pos'], en[0]['pos']+b._MIN_SPACE_POS)
        damaged = [100000-u['hp'] for u in en]
        # Front plus the next two within 300 of the landing point; never a fourth.
        self.assertEqual(damaged, [160, 160, 160, 0, 0])
        self.assertEqual([bool(b._buff(u, 'sunder')) for u in en], [True, True, True, False, False])
        self.assertAlmostEqual(b._buff(en[0], 'sunder').value, .25/.75)
        self.assertEqual(b.demon_rage(o), 35)
        self.assertTrue(b.demon_state(o)['force'])

    def test_normal_rage_gain_is_capped_and_rank_ten_doubles_damage(self):
        b, o, _, en = self.battle(1, rank=10)
        self.cast(b, o)
        self.assertEqual(100000-en[0]['hp'], 320)
        self.assertEqual(b.demon_rage(o), 25)

    def test_bloodlust_needs_forty_rage_below_forty_percent_and_spends_none(self):
        b, o, _, en = self.battle(1)
        b.demon_state(o)['rage'] = 50
        o['hp'] = 50000
        self.cast(b, o)
        self.assertEqual(b.demon_rage(o), 55)
        b, o, _, en = self.battle(1)
        b.demon_state(o)['rage'] = 50
        o['hp'] = 30000
        attack = b._get_damage(o)
        self.cast(b, o)
        self.assertEqual(o['hp'], 30000+20000+attack)
        self.assertEqual(b.demon_rage(o), 55)
        b, o, _, en = self.battle(1)
        b.demon_state(o)['rage'] = 39
        o['hp'] = 30000
        self.cast(b, o)
        self.assertEqual(o['hp'], 30000)

    def test_basic_attack_ratio_rage_and_forced_crit(self):
        b, o, _, en = self.battle(1)
        b._basic_attack(o, en[0])
        self.assertEqual(100000-en[0]['hp'], 200)
        self.assertEqual(b.demon_rage(o), 25)
        b.demon_state(o)['force'] = True
        b._basic_attack(o, en[0])
        self.assertEqual(100000-en[0]['hp'], 200+400)
        self.assertEqual(b.demon_rage(o), 35)
        self.assertFalse(b.demon_state(o)['force'])

    def test_rage_raises_crit_chance_and_missing_health_raises_attack(self):
        b, o, _, _ = self.battle(1)
        b.demon_state(o)['rage'] = 50
        self.assertAlmostEqual(b.demon_crit_bonus(o), 20)
        o['hp'] = 50000
        self.assertEqual(b._get_damage(o), 140)
        o['hp'] = 10000
        self.assertEqual(b._get_damage(o), 160)

    def test_crit_stat_share_of_crit_damage_is_raised_by_thirty_percent(self):
        c = copy.deepcopy(self.cfg)
        b = SkillCompleteBattle([base_unit(c, AID, 1, 1, 0, .2, True, 1), base_unit(c, 'A_1001_6', 1, 1, 0, .2, False, 1)],
                                [base_unit(c, 'A_1001_6', 1, 1, 0, .2, True, 2)], config=c)
        demon, other, enemy = b.a[0], b.a[1], b.b[0]
        for unit in (demon, other, enemy):
            unit['new_4attrs'] = dict(hit=1000000, flee=0, crit=30000, tough=0)
            unit['tpl'] = [0]*5
        plain = b._roll_attack(other, enemy, force_crit=True)
        self.assertGreater(plain, 2)
        self.assertAlmostEqual(b._roll_attack(demon, enemy, force_crit=True), 2+(plain-2)*1.3)

    def test_endless_rage_lasts_two_turns_outside_the_captain_slot(self):
        b, o, _, en = self.battle(1)
        o['leader'] = 0
        b._injured(o, 200000, 1, source=en[0])
        for _ in range(2):
            b.demon_turn(o)
            b._injured(o, 200000, 1, source=en[0])
            self.assertEqual(o['hp'], 1)
        b.demon_turn(o)
        self.assertFalse(b.demon_fury(o))
        self.assertEqual(o['hp'], 1+35000)

    def test_endless_rage_precedes_bless_holds_three_turns_as_captain_and_ends_with_cleanse_heal(self):
        b, o, _, en = self.battle(1)
        b._add_buff(o, 'bless', 2, source=o)
        b._injured(o, 200000, 1, source=en[0])
        self.assertEqual(o['hp'], 1)
        self.assertIsNotNone(b._buff(o, 'bless'))
        # 20 opening + 60 from Endless Rage + 2 for the lethal hit itself.
        self.assertEqual(b.demon_rage(o), 82)
        self.assertEqual(b._get_damage(o), int(int(100*1.6)*1.6))
        b._add_buff(o, 'curse', 2)
        self.assertIsNone(b._buff(o, 'curse'))
        b._add_buff(o, 'weak', 2, 1)
        self.assertIsNotNone(b._buff(o, 'weak'))
        for _ in range(3):
            b.demon_turn(o)
            b._injured(o, 200000, 1, source=en[0])
            self.assertEqual(o['hp'], 1)
        b._add_buff(o, 'stun', 2)
        b.demon_turn(o)
        self.assertFalse(b.demon_fury(o))
        self.assertEqual(b.demon_rage(o), 0)
        self.assertIsNone(b._buff(o, 'weak'))
        self.assertIsNone(b._buff(o, 'stun'))
        self.assertEqual(o['hp'], 1+35000)
        b._injured(o, 200000, 1, source=en[0])
        # Bless was kept through Endless Rage and now catches the next lethal hit.
        self.assertEqual(o['hp'], 50000)
        self.assertIsNone(b._buff(o, 'bless'))

    def test_endless_rage_cooldown_and_two_trigger_limit(self):
        b, o, _, en = self.battle(1)
        state = b.demon_state(o)
        b.round_index = 0
        o['hp'] = 0
        self.assertTrue(b.demon_lethal(o))
        state['fury'] = -1
        b.round_index = 11
        o['hp'] = 0
        self.assertFalse(b.demon_lethal(o))
        b.round_index = 12
        self.assertTrue(b.demon_lethal(o))
        state['fury'] = -1
        b.round_index = 40
        o['hp'] = 0
        self.assertFalse(b.demon_lethal(o))
        self.assertEqual(state['used'], 2)

    def test_rage_decays_after_idle_action_and_hurt_gain_is_capped(self):
        b, o, _, en = self.battle(1)
        b.demon_turn(o)
        b.demon_turn(o)
        self.assertEqual(b.demon_rage(o), 10)
        for _ in range(6):
            b.hit(en[0], o, 1, 1)
        self.assertEqual(b.demon_rage(o), 18)
        b.demon_turn(o)
        b.hit(en[0], o, 1, 1)
        # Idle again (-10), and the hurt cap starts over (+2).
        self.assertEqual(b.demon_rage(o), 10)

    def test_relic_poison_settles_before_endless_rage(self):
        battle, owner, _, enemies = self.battle()
        owner['hp'] = 10
        owner['_relic_dots'] = [dict(kind='poison', source=enemies[0], amount=1000, left=2)]
        battle._tick_buffs(owner)
        self.assertEqual(owner['hp'], 1)
        self.assertEqual(battle.demon_state(owner)['fury'], 2)

        owner['hp'] = 2000
        battle.demon_state(owner)['fury'] = 0
        battle._tick_buffs(owner)
        self.assertEqual(owner['hp'], 35800)  # 2,000 - 1,200 poison + 35,000 recovery.
        self.assertFalse(owner.get('_relic_dots'))

    def test_zero_damage_hit_decays_rage_but_shield_damage_preserves_it(self):
        battle, owner, _, enemies = self.battle()
        target = enemies[0]
        battle.demon_turn(owner)
        battle.state(target)['guard'] = dict(kind='kayle', charges=1, owner=None)
        battle._basic_attack(owner, target)
        self.assertEqual(target['hp'], target['hp_max'])
        hit_rage = battle.demon_rage(owner)
        self.assertGreater(hit_rage, 20)
        battle.demon_turn(owner)
        self.assertEqual(battle.demon_rage(owner), hit_rage - 10)

        battle._add_buff(target, 'shield', 2, 1000)
        battle._basic_attack(owner, target)
        self.assertEqual(target['hp'], target['hp_max'])
        self.assertLess(battle._buff_value(target, 'shield'), 1000)
        hit_rage = battle.demon_rage(owner)
        battle.demon_turn(owner)
        self.assertEqual(battle.demon_rage(owner), hit_rage)

    def test_captain_buffs_lane_weakens_two_and_heals_from_spent_rage(self):
        b, o, friends, en = self.battle(3, allies=2)
        b.demon_state(o)['rage'] = 60
        friends[0]['hp'] = 50000
        self.assertTrue(self.cast(b, o, captain=True))
        for unit in [o]+friends:
            self.assertAlmostEqual(b._buff(unit, 'strong').value, .3)
            self.assertEqual(b._buff(unit, 'critup').value, 4000)
        self.assertEqual([bool(b._buff(u, 'weak')) for u in en], [True, True, False])
        self.assertEqual(b.demon_rage(o), 30)
        # Spent rage x (10% attack, already under the war cry's power, + 1.5% max HP).
        heal = int(30*(int(100*1.3)*.1+100000*.015))
        self.assertEqual(friends[0]['hp'], 50000+heal)
        self.assertEqual(b._buff_value(friends[1], 'shield'), heal)
        self.assertEqual(b._buff_value(o, 'shield'), heal)

    def test_captain_spends_at_least_twenty_and_aura_rewards_ally_crits(self):
        b, o, friends, en = self.battle(1, allies=1)
        b.demon_state(o)['rage'] = 30
        self.cast(b, o, captain=True)
        self.assertEqual(b.demon_rage(o), 10)
        b, o, friends, en = self.battle(1, allies=1, critical=True)
        for _ in range(8):
            with b.context(friends[0], 'basic'):
                b._native_damage(friends[0], en[0], 1, 1)
        self.assertEqual(b.demon_rage(o), 30)


if __name__ == '__main__':
    unittest.main()
