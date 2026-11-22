"""Opt-in formulas, legacy compatibility and the damage channels they affect."""
import copy
import math
import unittest

from combat_math import (chance, crit_chance, critical_multiplier, defense_damage,
                         damage_before_final, miss_chance, ratio_reduction, settle_damage)
from combat_rules import attack_parameters, candidate_config, apply_combat_rules
from battle_engine import ReferenceBattle
from manual_ability_sim import SkillCompleteBattle


ATTACK = [0.1,0.3,1.5,2,20,20,60,80,0.5,3000,3000,3000,3000,3000,0.5,0.5,0.5,0.5,0.2,0.05,0.5,1]


def config():
    return {'system_simple': {'attack': list(ATTACK)}, 'avatar': {}}


def unit(side, **changes):
    row = dict(aid=f'A_{1000+side}_6', ap=1000, hp=100000, hp_max=100000,
               de_ph=700, de_ma=350, isme=side==1, line=0, pos=1500,
               tpl=[0,1,1,200,700], new_4attrs=dict(hit=0,flee=0,crit=0,tough=0))
    row.update(changes)
    return row


class NoRandom:
    def get_random(self, maximum=100):return 99


class CombatRedesignTests(unittest.TestCase):
    def battle(self, cls=ReferenceBattle, cfg=None):
        b=cls([unit(1)],[unit(2)],config=cfg or candidate_config(config()))
        b.rng=NoRandom()
        return b,b.a[0],b.b[0]

    def test_curve_table_and_cap(self):
        # The design's percentages are rounded; r=3 gives 89.87%, not exactly 90%.
        for r,pct in [(0.2,13),(0.32,24),(0.4,30),(0.57,42),(0.7,50),(1,63),(2,83),(3,90)]:
            self.assertAlmostEqual(ratio_reduction(r,1)*100,pct,delta=0.51)
        self.assertEqual(ratio_reduction(1000,1),0.9)
        self.assertEqual(ratio_reduction(0,0),0)
        self.assertEqual(ratio_reduction(700,0),0.9)

    def test_defense_independent_of_skill_and_attack_buffs(self):
        rules=candidate_config(config())['combat_rules']
        self.assertEqual([defense_damage(v,700,1000,rules=rules) for v in (1000,2000,3000)],[500,1000,1500])
        b,a,t=self.battle(SkillCompleteBattle)
        self.assertEqual(b._native_damage(a,t,1,1),264)
        b._add_buff(a,'strong',3,1)
        self.assertEqual(b._native_damage(a,t,1,1),528)

    def test_sunder_and_penetration_still_feed_effective_defense(self):
        b,a,t=self.battle(SkillCompleteBattle)
        b._add_buff(t,'sunder',3,1)
        self.assertEqual(b._defense_against(a,t,1),350)
        b._book_bonus=lambda owner,kind:0.75 if owner is a and kind=='penetration' else 0
        self.assertEqual(b._defense_against(a,t,1),175)
        expected=math.trunc(defense_damage(1000,175,1000,rules=b._combat_rules)*float(b._attack[21]))
        self.assertEqual(b._native_damage(a,t,1,1),expected)

    def test_native_true_and_explicit_true_have_distinct_rates(self):
        for cls in (ReferenceBattle,SkillCompleteBattle):
            b,a,t=self.battle(cls)
            self.assertEqual(b._native_damage(a,t,1,3),264)
            self.assertAlmostEqual(b._native_damage(a,t,b._true_skill_coefficient(1),3),422,delta=1)
        b,a,t=self.battle(SkillCompleteBattle)
        self.assertTrue(b.hit(a,t,1,3))
        self.assertEqual(t['hp'],100000-422)

    def test_true_skill_does_not_double_apply_native_rate(self):
        for rate in (0.3,0.5,0.8):
            cfg=candidate_config(config(),attack_overrides={'1':rate})
            b,a,t=self.battle(SkillCompleteBattle,cfg)
            self.assertAlmostEqual(b._native_damage(a,t,b._true_skill_coefficient(1),3),422,delta=1)

    def test_absolute_and_reference_share_ratio_curve(self):
        b,a,t=self.battle()
        self.assertEqual(b._injured_absolute(t,1000,1,a),264)
        self.assertEqual(b._native_damage(a,t,1,1),264)
        self.assertEqual(b._native_damage(a,t,1,2),389)

    def test_opposed_chances_and_multipliers(self):
        cfg = candidate_config(config())
        attack, rules = attack_parameters(cfg), cfg['combat_rules']
        for delta, expected in [(-200000,3.7179826),(-100000,5),(-10000,10.918734),
                                (0,15),(10000,24.671979),(20000,30.963776),(100000,39.545455)]:
            for offset in (0,16660):
                self.assertAlmostEqual(crit_chance(offset+max(0,delta),offset+max(0,-delta),attack,rules),expected,places=5)
        for junction in (0,20000):
            points = [crit_chance(30000+junction+d,30000,attack,rules) for d in (-1,0,1)]
            self.assertAlmostEqual(points[1]-points[0],points[2]-points[1],delta=0.000001)
        for delta, expected in [(0,0),(4000,28.993699),(100000,80),(200000,85.661864)]:
            self.assertAlmostEqual(miss_chance(16660,16660+delta,attack,rules),expected,places=5)
        self.assertEqual(miss_chance(90000,0,attack,rules),0)
        self.assertAlmostEqual(critical_multiplier(116660,attack,16660,rules),3.2)
        self.assertEqual(chance(6000,3000,20,60,3000),45)

    def test_opposed_toughness_applies_once(self):
        b,a,t=self.battle(SkillCompleteBattle)
        t['new_4attrs']['tough']=100000
        self.assertEqual(b._native_damage(a,t,1,1),165)
        self.assertEqual(b._injured(t,1000,6,a,dot_kind='burn'),330)
        self.assertEqual(b._injured(t,1000,3,a,derived=True),1000)
        self.assertEqual(settle_damage(1000,2,100000,100,b._attack,rules=b._combat_rules)['health_damage'],560)
        a['new_4attrs']['crit']=100000
        self.assertEqual(b._injured(t,1000,6,a,dot_kind='poison'),528)

    def test_caster_precision_scales_heal_and_shield_once(self):
        b,a,t=self.battle(SkillCompleteBattle)
        a['new_4attrs']['hit']=100000
        t['hp']=1000
        b._injured(t,1000,4,a)
        self.assertEqual(t['hp'],2500)
        b._injured(t,1000,4,a,fixed_recovery=True)
        self.assertEqual(t['hp'],3500)
        b._add_buff(t,'shield',2,1000,source=a)
        self.assertEqual(b._buff_value(t,'shield'),1500)
        b.heal(a,t,1)
        self.assertEqual(t['hp'],3500+16500)

    def test_candidate_copy_leaves_live_configuration_untouched(self):
        cfg=config();before=copy.deepcopy(cfg);candidate=candidate_config(cfg)
        self.assertEqual(cfg,before)
        self.assertEqual(candidate['system_simple']['attack'],ATTACK)
        self.assertEqual(attack_parameters(cfg),ATTACK)
        disabled=copy.deepcopy(candidate);disabled['combat_rules']['model']='legacy'
        self.assertEqual(attack_parameters(disabled),ATTACK)

    def test_controls_preserve_existing_public_combat_contracts(self):
        doc={'cfg':config()};doc['cfg']['combat_rules']={'direct_recovery':{'hit_denominator':3000}}
        apply_combat_rules(doc);first=copy.deepcopy(doc);apply_combat_rules(doc)
        self.assertEqual(doc,first)
        self.assertEqual(doc['cfg']['combat_rules']['direct_recovery'],{'hit_denominator':3000})
        self.assertEqual(doc['cfg']['combat_rules']['model'],'ratio')
        self.assertEqual(doc['cfg']['system_simple']['attack'],ATTACK)

    def test_live_config_replacement_and_switch_still_take_effect(self):
        b,a,t=self.battle(SkillCompleteBattle,config())
        b._config={'system_simple':{'attack':list(ATTACK)}}
        b._config['system_simple']['attack'][21]=.5
        self.assertEqual(b._native_damage(a,t,1,1),150)
        b._config['system_simple']['attack'][21]=1
        self.assertEqual(b._native_damage(a,t,1,1),300)
        b._config=candidate_config(config())
        self.assertEqual(b._native_damage(a,t,1,1),264)

    def test_disabled_matches_absent_rules_at_fractional_boundaries(self):
        cfg=candidate_config(config());cfg['combat_rules']['model']='legacy'
        for cls in (ReferenceBattle,SkillCompleteBattle):
            old,a,t=self.battle(cls,config());off,b,u=self.battle(cls,cfg)
            for amount in (0.1,0.999999,1,1.333333,2.52525):
                for kind in (1,2,3):
                    self.assertEqual(old._native_damage(a,t,amount,kind),off._native_damage(b,u,amount,kind))
            self.assertEqual(t['hp'],u['hp'])

    def test_legacy_known_damage_and_rounding(self):
        b,a,t=self.battle(ReferenceBattle,config())
        self.assertEqual(b._native_damage(a,t,1,1),300)
        self.assertEqual(b._native_damage(a,t,1,2),650)
        self.assertEqual(b._native_damage(a,t,1,3),300)
        self.assertEqual(b._injured_absolute(t,1001,1,a),301)
        self.assertEqual(damage_before_final(9,0,0,1,100,0,ATTACK,.9),0)


if __name__=='__main__':unittest.main()
