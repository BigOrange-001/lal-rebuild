import copy
from pathlib import Path
import unittest
from battle_engine import base_unit
from gateway import load_game_config
from manual_ability_sim import SkillCompleteBattle
from native_skill_snapshot import _native_skill_snapshot
from nightbringer_yasuo_104 import AID, NORMAL, CAPTAIN, PASSIVE, apply_nightbringer_yasuo

ROOT = Path(__file__).resolve().parents[1]


class NightbringerYasuoTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.cfg = load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']

    def battle(self, count=1, team=1, critical=False):
        c = copy.deepcopy(self.cfg)
        c['combat_rules'] = {}
        a = c['system_simple']['attack']
        a[2] = 1
        a[4] = a[15] = a[16] = 0
        a[5] = 100 if critical else 0
        a[7] = 100
        a[3] = 2
        a[21] = 1
        def unit(aid, side, pos):
            u = base_unit(c, aid, 1, 1, 0, .2, aid==AID, side)
            u.update(pos=pos, hp=100000, hp_max=100000, ap=100, de_ph=0, de_ma=0)
            u['new_4attrs'] = dict(hit=1000000, flee=0, crit=0, tough=0)
            return u
        owner = unit(AID, team, 2400 if team==1 else 600)
        enemies = [unit('A_1001_6', 3-team, 1400-i*300 if team==1 else 1600+i*300) for i in range(count)]
        b = SkillCompleteBattle([owner] if team==1 else enemies, enemies if team==1 else [owner], config=c, trace_abilities=True)
        return b, (b.a if team==1 else b.b)[0], b.b if team==1 else b.a

    def cast(self, b, o, captain=False):
        slot = 'leader_skill' if captain else 'skill'
        skill = o[slot]
        with b.context(o, 'active', skill=skill):
            return b.execute(o, 'night_yasuo_c' if captain else 'night_yasuo_n', 1, skill)

    def test_configuration_panel_ranks_and_acquisition(self):
        c = self.cfg
        h = c['avatar'][AID]
        self.assertEqual(h['pl'][:8], c['avatar']['A_1206_6']['pl'][:8])
        self.assertEqual((h['tl'][0], h['stat_profile'], h['hero_category_104']), (1,1,'skin'))
        self.assertTrue(h['voiceDisabled104'])
        self.assertEqual(h['pl'][9],550)
        self.assertEqual(c['avatar']['A_1801_6']['pl'][9],850)
        self.assertEqual(c['skill'][NORMAL]['pl'][:2], [0,2])
        self.assertEqual(c['skill'][CAPTAIN]['pl'][:2], [1,4])
        for rank, value in ((1,2.25),(10,4.5)):
            self.assertEqual(_native_skill_snapshot(c,NORMAL,rank)['skills'][0][4], value)
        for rank, value in ((1,.33),(10,.66)):
            self.assertAlmostEqual(_native_skill_snapshot(c,NORMAL,rank)['skills'][0][5], value)
        self.assertEqual(c['skill'][CAPTAIN]['skill'][0][4:7],[1.75,1.75,4.44])
        self.assertNotIn('净化',c['skill'][CAPTAIN]['info'])
        self.assertIn('免疫上述效果1回合',c['skill'][CAPTAIN]['info'])
        for pool in ('advanced','vip'):
            self.assertEqual(sum(x['id']==AID for x in c['summon_calibration']['pools'][pool]['qualities']['orange']['cards']),1)
        fresh = copy.deepcopy(c)
        apply_nightbringer_yasuo(fresh)
        self.assertEqual(fresh,c)
        from orange_ascension_104 import builtin_asset
        media=c['nightbringer_yasuo_104']['media']
        for entry in media['assets']:
            self.assertEqual(len(builtin_asset(c,media['digest'],entry['path'])[0]),entry['bytes'])

    def test_q_lane_damage_stun_and_all_push(self):
        b,o,en = self.battle(4)
        en[-1]['line']=1
        self.assertTrue(self.cast(b,o))
        self.assertEqual([100000-u['hp'] for u in en], [225,135,135,0])
        self.assertEqual(b._buff(en[0],'stun').round,1)
        self.assertIsNone(b._buff(en[1],'stun'))
        self.assertIsNone(b._buff(en[0],'weak'))
        self.assertEqual(b._buff(en[1],'weak').round,1)
        self.assertAlmostEqual(b._get_damage(en[1]),67,delta=1)
        self.assertEqual([u['pos'] for u in en], [1100,800,500,500])
        self.assertEqual(o['pos'],2000)
        launch=[e for e in b.ability_events if e['kind']=='yasuo_vortex_launch']
        contacts=[e for e in b.ability_events if e['kind']=='yasuo_vortex_contact']
        self.assertEqual(len(launch),1)
        self.assertEqual((launch[0]['position'],launch[0]['end']),(2000,0))
        self.assertEqual([e['position'] for e in contacts],[1400,1100,800])
        self.assertEqual([e['time'] for e in contacts],[.25,.375,.5])

    def test_q_dash_is_limited_by_front_on_both_sides(self):
        for team in (1,2):
            b,o,en = self.battle(team=team)
            o['pos']=en[0]['pos']+(300 if team==1 else -300)
            original=en[0]['pos']
            self.cast(b,o)
            self.assertEqual(o['pos'],original+(b._MIN_SPACE_POS if team==1 else -b._MIN_SPACE_POS))
            self.assertEqual(en[0]['pos'],original+(-300 if team==1 else 300))

    def test_q_keeps_original_front_after_death_and_empty_lane_is_noop(self):
        b,o,en=self.battle(2)
        en[0]['hp']=1
        self.cast(b,o)
        self.assertEqual(100000-en[1]['hp'],135)
        en[1]['hp']=0
        pos=o['pos']
        self.assertFalse(self.cast(b,o))
        self.assertEqual(o['pos'],pos)

    def test_q_purifies_now_and_blocks_exactly_one_future_debuff(self):
        b,o,en=self.battle()
        for kind in ('root','weak','curse'):
            b._add_buff(o,kind,3,1)
        self.cast(b,o)
        for kind in ('root','weak','curse'):
            self.assertIsNone(b._buff(o,kind))
        self.assertEqual(b._buff(o,'purify').value,1)
        b._add_buff(o,'silence',2)
        self.assertIsNone(b._buff(o,'silence'))
        self.assertIsNone(b._buff(o,'purify'))
        b._add_buff(o,'silence',2)
        self.assertIsNotNone(b._buff(o,'silence'))
        self.cast(b,o)
        self.assertIsNone(b._buff(o,'silence'))
        self.assertEqual(b._buff(o,'purify').value,1)

    def test_q_rank_ten_weakness_is_actual_attack_reduction_and_expires(self):
        b,o,en=self.battle(3)
        o['skill']=_native_skill_snapshot(b._config,NORMAL,10)
        self.cast(b,o)
        self.assertIsNone(b._buff(en[0],'weak'))
        self.assertAlmostEqual(b._get_damage(en[1]),34,delta=1)
        self.assertEqual(b._buff(en[1],'weak').round,1)
        b._tick_buffs(en[1]);b._tick_buffs(en[1])
        self.assertIsNone(b._buff(en[1],'weak'))

    def test_lifesteal_is_actual_hp_damage_without_precision_scaling(self):
        for precision in (0,1000,100000000):
            b,o,en=self.battle()
            o['_yasuo_vamp_rounds']=2
            o['new_4attrs']['hit']=precision
            o['hp']=90000
            b.yasuo_event(o,'hit',o,en[0],100)
            self.assertEqual(o['hp'],90100)
            o['hp']=99990
            b.yasuo_event(o,'hit',o,en[0],100)
            self.assertEqual(o['hp'],100000)
        b,o,en=self.battle()
        o['_yasuo_vamp_rounds']=2;o['hp']=90000
        b._add_buff(en[0],'shield',3,1000)
        with b.context(o,'basic'):b._native_damage(o,en[0],1,1)
        self.assertEqual(o['hp'],90000)
        b._remove_buff(en[0],'shield');en[0]['hp']=30
        with b.context(o,'basic'):b._native_damage(o,en[0],1,1)
        self.assertEqual(o['hp'],90030)

    def test_critical_attribute_is_doubled_only_once_and_resets(self):
        b,o,en=self.battle()
        o['new_4attrs']['crit']=123
        fresh=SkillCompleteBattle([o],en,config=b._config)
        self.assertEqual(fresh._get_crit(fresh.a[0]),246)
        again=SkillCompleteBattle(fresh.a,fresh.b,config=b._config)
        self.assertEqual(again._get_crit(again.a[0]),246)
        again.a[0]['skillB']=None
        final=SkillCompleteBattle(again.a,again.b,config=b._config)
        self.assertEqual(final._get_crit(final.a[0]),123)

    def test_each_crit_shields_and_bonus_includes_absorbed_damage(self):
        b,o,en=self.battle(critical=True)
        b._add_buff(en[0],'shield',3,1000)
        with b.context(o,'basic'):b._native_damage(o,en[0],1,1)
        self.assertEqual(en[0]['hp'],100000)
        self.assertEqual(b._buff_value(en[0],'shield'),730)
        self.assertEqual(b._buff_value(o,'shield'),5025)
        self.assertEqual(sum(v.type=='shield' for v in o['_buffs'].values()),1)
        self.assertEqual([e['amount'] for e in b.ability_events if e['kind']=='yasuo_crit_true'],[70])

    def test_shields_add_without_refresh_and_expire_separately(self):
        b,o,en=self.battle()
        b.yasuo_event(o,'crit',o,en[0],10)
        b._tick_buffs(o)
        b.yasuo_event(o,'crit',o,en[0],10)
        self.assertEqual(sorted(v.round for v in o['_buffs'].values()),[1,2])
        b._tick_buffs(o)
        b._tick_buffs(o)
        self.assertEqual(b._buff_value(o,'shield'),5025)
        b._tick_buffs(o)
        self.assertEqual(b._buff_value(o,'shield'),0)

    def test_shields_absorb_oldest_first_and_native_shield_expiry_does_not_clear_them(self):
        b,o,en=self.battle()
        b._add_buff(o,'shield',0,100)
        b.yasuo_event(o,'crit',o,en[0],10)
        b._tick_buffs(o)
        self.assertEqual(b._buff_value(o,'shield'),5025)
        b._injured(o,100,1,source=en[0])
        self.assertEqual(b._buff_value(o,'shield'),4925)
        self.assertEqual(o['hp'],100000)
        b._remove_buff(o,'shield')
        self.assertEqual(b._buff_value(o,'shield'),0)

    def test_captain_damage_position_and_two_distinct_durations(self):
        b,o,en=self.battle()
        self.cast(b,o,True)
        self.assertEqual((o['pos'],100000-en[0]['hp']),(1600,1190))
        self.assertEqual((o['_yasuo_night_rounds'],o['_yasuo_vamp_rounds']),(1,2))
        self.assertIsNotNone(b._buff(o,'bless'))
        b._tick_buffs(o)
        b._tick_buffs(o)
        self.assertFalse(b.yasuo_night(o))
        self.assertEqual(o['_yasuo_vamp_rounds'],0)
        before=o['hp']=90000
        with b.context(o,'basic'):b._native_damage(o,en[0],1,1)
        self.assertEqual(o['hp']-before,100)
        b._tick_buffs(o)
        self.assertEqual(o['_yasuo_vamp_rounds'],-1)

    def test_cleanses_and_repeated_immunity_only_for_five_named_effects(self):
        b,o,en=self.battle()
        for name in ('stun','curse','poison','burn','silence','weak'):
            b._add_buff(o,name,3,1)
        b._add_manual_skill_dot(o,'bleed','bleed',5,0,2,en[0],6,False)
        b._add_manual_skill_dot(o,'poison','poison',5,0,2,en[0],6,False)
        self.cast(b,o,True)
        for name in ('stun','silence','curse','poison','burn'):
            self.assertIsNone(b._buff(o,name))
            b._add_buff(o,name,3,100)
            b._add_buff(o,name,3,100)
            self.assertIsNone(b._buff(o,name))
        self.assertIsNotNone(b._buff(o,'weak'))
        self.assertIn('bleed',o['_manual_dots'])
        self.assertNotIn('poison',o['_manual_dots'])
        self.assertFalse(b._add_manual_skill_dot(o,'p2','poison',5,0,2,en[0],6,False))

    def test_night_survives_dispel_and_reduces_all_damage_channels(self):
        b,o,en=self.battle()
        o['_yasuo_night_rounds']=1
        b._remove_all_good(o)
        self.assertTrue(b.yasuo_night(o))
        for kind in (1,2,3,6,7,8):
            before=o['hp']
            b._injured(o,100,kind,source=en[0])
            self.assertEqual(before-o['hp'],20)

    def test_bonus_not_recrit_or_double_scaled_by_outgoing_amp_or_global_rate(self):
        b,o,en=self.battle(critical=True)
        b._config['system_simple']['attack'][21]=.5
        o['_yasuo_night_rounds']=1
        with b.context(o,'basic'):b._native_damage(o,en[0],1,1)
        # 100 * 2 crit * .5 global * 1.5 night =150, plus floor(150*.35)=52.
        self.assertEqual(100000-en[0]['hp'],202)
        self.assertEqual(sum(e['kind']=='yasuo_crit_true' for e in b.ability_events),1)
        self.assertEqual(sum(v.type=='shield' for v in o['_buffs'].values()),1)

    def test_bonus_still_respects_target_night_and_shields(self):
        b,o,en=self.battle(critical=True)
        en[0]['_yasuo_night_rounds']=1
        with b.context(o,'basic'):b._native_damage(o,en[0],1,1)
        # First hit 200*.2=40. Derived true 14 receives its own .2 mitigation.
        self.assertEqual(100000-en[0]['hp'],42)

    def test_captain_locks_target_and_stops_when_it_dies(self):
        b,o,en=self.battle(2)
        en[0]['hp']=1
        self.cast(b,o,True)
        self.assertEqual(en[1]['hp'],100000)
        self.assertEqual(sum(e['kind']=='hit' for e in b.ability_events),1)

    def test_bless_is_one_use_and_recast_can_rearm(self):
        b,o,en=self.battle()
        self.cast(b,o,True)
        b._injured(o,10000000,3,source=en[0])
        self.assertGreater(o['hp'],0)
        self.assertIsNone(b._buff(o,'bless'))
        self.cast(b,o,True)
        self.assertIsNotNone(b._buff(o,'bless'))


if __name__=='__main__':unittest.main()
