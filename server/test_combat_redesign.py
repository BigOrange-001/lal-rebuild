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
        self.assertEqual(b._native_damage(a,t,1,1),330)
        b._add_buff(a,'strong',3,1)
        self.assertEqual(b._native_damage(a,t,1,1),660)

    def test_sunder_and_penetration_still_feed_effective_defense(self):
        b,a,t=self.battle(SkillCompleteBattle)
        b._add_buff(t,'sunder',3,1)
        self.assertEqual(b._defense_against(a,t,1),350)
        b._book_bonus=lambda owner,kind:0.75 if owner is a and kind=='penetration' else 0
        self.assertEqual(b._defense_against(a,t,1),175)
        expected=math.trunc(defense_damage(1000,175,1000,rules=b._combat_rules)*0.66)
        self.assertEqual(b._native_damage(a,t,1,1),expected)

    def test_native_true_and_explicit_true_have_distinct_rates(self):
        for cls in (ReferenceBattle,SkillCompleteBattle):
            b,a,t=self.battle(cls)
            self.assertEqual(b._native_damage(a,t,1,3),330)
            self.assertAlmostEqual(b._native_damage(a,t,b._true_skill_coefficient(1),3),528,delta=1)
        b,a,t=self.battle(SkillCompleteBattle)
        self.assertTrue(b.hit(a,t,1,3))
        self.assertEqual(t['hp'],100000-528)

    def test_true_skill_does_not_double_apply_native_rate(self):
        for rate in (0.3,0.5,0.8):
            cfg=candidate_config(config(),attack_overrides={'1':rate})
            b,a,t=self.battle(SkillCompleteBattle,cfg)
            self.assertAlmostEqual(b._native_damage(a,t,b._true_skill_coefficient(1),3),528,delta=1)

    def test_absolute_and_reference_share_ratio_curve(self):
        b,a,t=self.battle()
        self.assertEqual(b._injured_absolute(t,1000,1,a),330)
        self.assertEqual(b._native_damage(a,t,1,1),330)
        self.assertEqual(b._native_damage(a,t,1,2),487)

    def test_probability_parameters_and_fixed_critical(self):
        cfg=candidate_config(config());attack=attack_parameters(cfg);rules=cfg['combat_rules']
        self.assertEqual(miss_chance(3000,6000,attack,rules),18)
        self.assertEqual(crit_chance(6000,3000,attack,rules),30)
        self.assertEqual(miss_chance(0,10**9,attack,rules),35)
        self.assertEqual(crit_chance(10**9,0,attack,rules),60)
        self.assertEqual(miss_chance(10**9,0,attack,rules),0)
        self.assertEqual(critical_multiplier(10**9,attack),2)
        self.assertEqual(chance(6000,3000,20,60,3000),45)

    def test_toughness_removed_global_and_shield_preserved(self):
        attack=attack_parameters(candidate_config(config()))
        self.assertEqual(settle_damage(1000,2,100000,100,attack),dict(health_damage=1220,shield_left=0,absorbed=100))
        b,a,t=self.battle(SkillCompleteBattle)
        t['new_4attrs']['tough']=100000
        self.assertEqual(b._native_damage(a,t,1,1),330)
        self.assertEqual(b._injured(t,1000,6,a,dot_kind='burn'),660)
        self.assertEqual(b._injured(t,1000,6,a,dot_kind='poison'),660)

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
        self.assertEqual(b._native_damage(a,t,1,1),330)

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
