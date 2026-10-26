"""Nurse Akali's live stat bases, overhealing and receiver-side passive."""
import copy
import json
import unittest
from pathlib import Path

from battle_engine import _native_skill_snapshot
from manual_ability_sim import SkillCompleteBattle
from nurse_akali_103 import apply_nurse_akali_103


ROOT = Path(__file__).resolve().parents[1]


class NurseAkali103Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.original = json.loads((ROOT/'config/reconstruction/full-config.json').read_text('utf-8'))
        cls.document = copy.deepcopy(cls.original)
        apply_nurse_akali_103(cls.document)
        cls.cfg = cls.document['cfg']

    def battle(self, level=1, ally=True):
        def unit(aid, side, line=0):
            return dict(aid=aid, isme=side==1, line=line, pos=1800 if side==1 else 1500,
                        hp=10000, hp_max=10000, ap=300, de_ph=999999, de_ma=999999,
                        tpl=[1, 4, 3, 245, 688], new_4attrs={})
        owner = unit('A_1208_6', 1)
        owner.update(skill=_native_skill_snapshot(self.cfg, 'S_271208_6', level),
                     leader_skill=_native_skill_snapshot(self.cfg, 'S_371208_6', level),
                     skillB=_native_skill_snapshot(self.cfg, 'S_471208_6', level))
        friends = [owner, unit('A_1001_6', 1, 2)] if ally else [owner]
        cfg = dict(self.cfg, system_simple=dict(self.cfg['system_simple'], attack=[]))
        return SkillCompleteBattle(friends, [unit('A_1002_6', 2, i) for i in range(3)],
                                   config=cfg, trace_abilities=True)

    def cast(self, b, slot='skill'):
        return b._apply_native_skill(b.a[0], b.b, slot)

    def test_tank_panel_and_growth_convert_once_without_touching_other_heroes(self):
        for q in (5, 6):
            aid = f'A_1208_{q}'
            before = self.original['cfg']['avatar'][aid]['pl']
            h = self.cfg['avatar'][aid]
            self.assertEqual((h['role'], h['stat_profile'], h['tl'][2]), ('双抗坦克', 3, 3))
            for index, factor in ((0,1.2),(1,1.2),(2,.5),(3,.5)):
                self.assertAlmostEqual(h['pl'][index], before[index]*factor)
            for i in (0,1):
                self.assertAlmostEqual(h['pl'][4+i], (before[4+i]+before[6+i])*.75)
                self.assertEqual(h['pl'][4+i], h['pl'][6+i])
            self.assertEqual(h['pl'][8:10], before[8:10])
            low = _native_skill_snapshot(self.cfg, h['pl'][10], 1)
            high = _native_skill_snapshot(self.cfg, h['pl'][10], 10)
            self.assertEqual(low['pl'][:2], [1,2])
            self.assertAlmostEqual(high['skills'][0][4], 1.4)
            self.assertEqual(self.cfg['skill'][h['pl'][11]]['pl'][:2], [3,3])
            self.assertEqual(_native_skill_snapshot(self.cfg,h['pl'][13],1)['skills'],
                             _native_skill_snapshot(self.cfg,h['pl'][13],10)['skills'])
        self.assertEqual(self.cfg['avatar']['A_1217_6'], self.original['cfg']['avatar']['A_1217_6'])
        doc = copy.deepcopy(self.document)
        apply_nurse_akali_103(doc)
        self.assertEqual(doc, self.document)

    def test_normal_cleanses_all_lanes_and_uses_total_ap_without_hp_term(self):
        for level, expected in ((1,315),(10,630)):
            b = self.battle(level)
            owner, friend = b.a
            owner['hp'] = friend['hp'] = 5000
            friend['summon_owner'] = 'ally'
            b._add_buff(owner,'strong',2,.5)
            b._add_buff(owner,'weak',2,1)
            b._add_buff(friend,'stun',1)
            self.cast(b)
            self.assertEqual([u['hp'] for u in b.a], [5000+expected]*2)
            self.assertTrue(all(b._buff(u,'purify') for u in b.a))
            self.assertIsNone(b._buff(friend,'stun'))
            # Healing another ally does not proc the healer's own passive.
            self.assertEqual([u['hp'] for u in b.b], [10000-int(expected*.4)]*3)

    def test_captain_chooses_ratio_across_lanes_and_uses_caster_maximum(self):
        b = self.battle()
        owner, friend = b.a
        owner.update(hp=7000, hp_max=10000)
        friend.update(hp=1000, hp_max=2000)  # less HP lost, but lower ratio
        self.cast(b,'leader_skill')
        self.assertEqual((owner['hp'],friend['hp']), (10000,2000))
        self.assertTrue(all(b._buff(u,'bless').value==0 for u in b.a))
        self.assertTrue(all(b._buff(u,'purify') for u in b.a))
        self.assertEqual([u['hp'] for u in b.b], [8000]*3)  # all 5000 nominal healing counts

    def test_captain_self_target_is_applied_twice_even_when_first_heal_fills_hp(self):
        b = self.battle()
        owner = b.a[0]
        owner['hp'] = 6000
        self.cast(b,'leader_skill')
        self.assertEqual(owner['hp'],10000)
        self.assertIsNone(b._buff(b.a[1],'bless'))
        self.assertEqual([u['hp'] for u in b.b], [6000]*3)
        self.assertEqual(len([e for e in b.ability_events if e['kind']=='nurse_retribution']),6)
        self.assertEqual(b.ability_contexts,[])

    def test_external_healing_counts_overheal_after_efficiency_and_burn_once(self):
        b = self.battle()
        owner, healer = b.a
        b._book_bonus = lambda unit,key: .5 if unit is healer and key=='healing' else 0
        b._add_buff(owner,'burn',3,10)
        owner['hp'] = 9900
        actual = b._injured(owner,1000,4,source=healer)  # 1000 * 1.5 * .6 = 900
        self.assertEqual(actual,-100)
        self.assertEqual(owner['hp'],10000)
        self.assertEqual([u['hp'] for u in b.b],[9640]*3)
        b._injured(healer,1000,4,source=owner)
        self.assertEqual([u['hp'] for u in b.b],[9640]*3)

    def test_passive_is_fixed_true_damage_and_common_defenses_still_apply(self):
        b = self.battle()
        owner = b.a[0]
        owner['ap'] = 9999999
        b._add_buff(b.b[0],'shield',2,150)
        b._injured(owner,1000,4,source=owner)
        self.assertEqual([u['hp'] for u in b.b], [9750,9600,9600])
        self.assertIsNone(b._buff(b.b[0],'shield'))
        self.assertEqual(b.state(owner)['nurse_pending'],[])
        self.assertFalse(b.state(owner)['nurse_busy'])
        self.assertEqual(b.ability_contexts,[])

    def test_dead_units_and_zero_healing_do_not_trigger_or_revive(self):
        b = self.battle()
        owner = b.a[0]
        b._injured(owner,0,4,source=owner)
        self.assertEqual([u['hp'] for u in b.b],[10000]*3)
        owner['hp']=0
        self.assertEqual(b._injured(owner,1000,4,source=b.a[1]),0)
        self.assertEqual(owner['hp'],0)
        self.assertEqual([u['hp'] for u in b.b],[10000]*3)

    def test_existing_cure_and_damage_based_group_heals_preserve_overhealing(self):
        b=self.battle()
        owner,healer=b.a
        skill={'pl':[0,0,10000,0,-1,1],'actionTargetPolicies':['ally_all']}
        amount=b._heal_channel_value(healer,1)
        b._act_cure(healer,b.b,b.a,skill,['cure',1],0,{})
        self.assertEqual(owner['hp'],10000)
        self.assertEqual([u['hp'] for u in b.b],[10000-int(amount*.4)]*3)
        before=[u['hp'] for u in b.b]
        b._act_heal_damage_sum(healer,b.b,b.a,skill,['heal_damage_sum',.5,[0],'FX'],1,{'damage':{0:2000}})
        self.assertEqual(owner['hp'],10000)
        self.assertEqual([u['hp'] for u in b.b],[hp-400 for hp in before])

    def test_gateway_uses_same_panel_and_skills_after_generic_balance(self):
        from gateway import Backend
        backend=Backend(':memory:',ROOT/'config/reconstruction/full-config.json')
        self.addCleanup(backend.db.close)
        cfg=backend.config['cfg']
        h=cfg['avatar']['A_1208_6']
        self.assertEqual((h['role'],h['stat_profile'],h['tl'][2]),('双抗坦克',3,3))
        self.assertEqual(h['pl'][10:12],['S_271208_6','S_371208_6'])
        self.assertEqual(h['pl'][4:6],h['pl'][6:8])


if __name__=='__main__':unittest.main()
