import copy
import json
import unittest
from pathlib import Path

from abyss_equip_passives import initialize, casting
from abyss_passive_cases import execute_case, input_units, case_config
from abyss_relics import main_effect
from battle_engine import ReferenceBattle
from gateway import load_game_config
from manual_ability_sim import SkillCompleteBattle

ROOT = Path(__file__).resolve().parents[1]


class PassiveTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):cls.cfg=load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']

    def battle(self, kind=7, ancient=False, engine=SkillCompleteBattle):
        cfg = case_config(self.cfg)
        a,b = input_units(cfg,kind,ancient)
        battle = engine(a,b,config=cfg,seed=173)
        initialize(battle)
        return battle,battle.a[0],battle.b[0]

    def test_all_b_main_normal_ancient_have_independent_expected_outcomes(self):
        for ancient in (False,True):
            with self.subTest(ancient=ancient):
                cases = {k:execute_case(self.cfg,k,ancient) for k in (1,2,3,4,5,6,7,12,14,15,16,17,18,19)}
                final = lambda k:cases[k]['expected'][-1]['units']
                self.assertEqual(final(1)['owner']['shield'],1250 if ancient else 1000)
                self.assertEqual(final(2)['enemy']['hp'],675 if ancient else 700)
                self.assertEqual(final(3)['owner']['hp'],650 if ancient else 400)
                self.assertEqual(sum(e['event']=='full_recovery' for e in cases[3]['expected'][-1]['equipment_events']),1)
                first_revive = cases[4]['expected'][-2]['units']['owner']
                self.assertEqual(first_revive['hp'],625 if ancient else 500)
                self.assertEqual(first_revive['buffs'],[])
                self.assertEqual(final(4)['owner']['hp'],0)
                self.assertEqual(final(5)['enemy']['hp'],975 if ancient else 980)
                self.assertEqual(len(cases[6]['expected'][-1]['equipment_events']),3)
                self.assertEqual(final(6)['owner']['shield'],125 if ancient else 100)
                self.assertEqual(final(7)['owner']['hp'],562 if ancient else 550)
                self.assertEqual(final(12)['enemy']['hp'],960 if ancient else 975)
                self.assertEqual(final(12)['enemy']['shield'],0)
                self.assertEqual(final(14)['ally']['hp'],662 if ancient else 650)
                self.assertEqual(final(14)['ally']['shield'],162 if ancient else 150)
                self.assertEqual(final(15)['ally']['hp'],908 if ancient else 906)
                self.assertEqual(final(16)['ally']['ap'],107 if ancient else 106)
                self.assertEqual(final(17)['enemy']['hp'],782 if ancient else 785)
                self.assertEqual(final(18)['summon']['hp_max'],1437 if ancient else 1350)
                self.assertEqual(final(18)['summon']['ap'],143 if ancient else 135)
                self.assertEqual(final(19)['owner']['leader_preparation'],2)

    def test_initialization_idempotent_and_existing_skillb_kept(self):
        b,o,e=self.battle(16)
        before = o['ap'];o['skillB']={'skid':'existing','skills':[['nurse_healing',1]]}
        initialize(b)
        self.assertEqual(o['ap'],before)
        self.assertEqual(o['skillB']['skid'],'existing')
        o['leader']=False
        b,o,e=self.battle(15)
        e['equip_passives']=[main_effect(15)]
        self.assertNotIn('_equip_reduction',e)

    def test_strict_half_health_thresholds_and_one_time_recovery(self):
        b,o,e=self.battle(3)
        b._injured(o,500,1,source=e)
        self.assertEqual(o['hp'],500)
        b._injured(o,1,1,source=e)
        self.assertEqual(o['hp'],1000)
        b._injured(o,501,1,source=e)
        self.assertEqual(o['hp'],499)
        b,o,e=self.battle(3)
        b._injured(o,2000,1,source=e)
        self.assertEqual(o['hp'],0)

    def test_lifesteal_nurse_source_suppression_only_for_relic_healing(self):
        b,o,e=self.battle(7)
        o['skillB']={'skid':'nurse-test','skills':[['nurse_healing',.5,.5]]}
        o['hp']=500
        b._injured(e,100,1,source=o)
        self.assertEqual(o['hp'],525)
        self.assertFalse(any(v['kind']=='nurse_retribution' for v in (b.ability_events or [])))
        self.assertEqual(e['hp'],900)
        # A normal heal must still execute the actual nurse receive hook.
        b.ability_events=[]
        b._injured(o,100,4,source=o)
        self.assertTrue(any(v['kind']=='nurse_retribution' for v in b.ability_events))

    def test_shield_damage_overflow_and_reflect_recursion_cap(self):
        b,o,e=self.battle(12)
        b._add_buff(e,'shield',3,50)
        b._injured(e,100,1,source=o)
        self.assertEqual(e['hp'],925)
        b,o,e=self.battle(5)
        e['equip_passives']=[main_effect(5)]
        b._injured(o,100,1,source=e)
        self.assertEqual((o['hp'],e['hp']),(900,980))
        self.assertEqual(len(b.equip_events),1)

    def test_relic_inactive_in_abyss_even_if_channel_injected(self):
        cfg=case_config(self.cfg);a,b=input_units(cfg,1,True)
        a[0]['abyss_standardized']=True
        battle=SkillCompleteBattle(a,b,config=cfg);initialize(battle)
        self.assertEqual(battle._buff_value(battle.a[0],'shield'),0)

    def test_a_effects_use_small_skill_context_and_not_captain_or_basic(self):
        for kind,ratio,expected in ((8,1,140),(8,.5,100),(9,.49,160),(9,.5,100)):
            b,o,e=self.battle();o['equip_passives']=[]
            o['skill']={'abyss_relic_A':main_effect(kind)}
            e['hp']=int(e['hp_max']*ratio);before=e['hp']
            with casting(b,o,'skill'):b._injured(e,100,1,source=o)
            self.assertEqual(before-e['hp'],expected)
            before=e['hp']
            with casting(b,o,'leader_skill'):b._injured(e,100,1,source=o)
            self.assertEqual(before-e['hp'],100)

    def test_a_dot_is_two_ticks_without_native_poison_hp_term_and_cleanses(self):
        for kind in (10,11):
            b,o,e=self.battle();o['equip_passives']=[]
            o['skill']={'abyss_relic_A':main_effect(kind)}
            with casting(b,o,'skill'):
                b._injured(e,10,1,source=o)
                b._injured(e,10,1,source=o)
            self.assertEqual(len(e['_relic_dots']),1)
            before=e['hp']
            b._tick_buffs(e);b._tick_buffs(e);b._tick_buffs(e)
            # Poison has its existing +20% incoming damage interaction.
            self.assertEqual(before-e['hp'],96 if kind==11 else 80)
            self.assertFalse(e['_relic_dots'])
            with casting(b,o,'skill'):b._injured(e,1,1,source=o)
            b._remove_all_debuff(e)
            self.assertNotIn('_relic_dots',e)

    def test_a_true_conversion_before_defense_and_single_hit_rng(self):
        b,o,e=self.battle();o['equip_passives']=[]
        o['skill']={'abyss_relic_A':main_effect(20)}
        e['de_ph']=10
        with casting(b,o,'skill'):
            with b.context(o,'active'):
                b._native_damage(o,e,1,1)
        self.assertEqual(1000-e['hp'],70)  # (100*.6-10)+100*.4*.5
        self.assertEqual(b.rng.calls,2)

    def test_frost_probability_boundary_and_once_per_target_per_cast(self):
        for ancient,roll,expected in ((False,199999,True),(False,200000,False),
                                     (True,249999,True),(True,250000,False)):
            b,o,e=self.battle();o['equip_passives']=[]
            o['skill']={'abyss_relic_A':main_effect(13,ancient)}
            calls=[]
            def draw(bound):calls.append(bound);return roll
            b.rng.get_random=draw
            with casting(b,o,'skill'):
                b._injured(e,10,1,source=o);b._injured(e,10,1,source=o)
            self.assertEqual(bool(b._buff(e,'stun')),expected)
            self.assertEqual(calls,[1000000])

    def test_delayed_small_skill_preserves_relic_context(self):
        b,o,e=self.battle();o['equip_passives']=[]
        o['skill']={'abyss_relic_A':main_effect(8)}
        with casting(b,o,'skill'):
            b._injured(e,10,1,source=o)
            b._act_pending_area_strike(o,[e],[o],o['skill'],
                ['pending_area_strike',0,1,1,300,1,1,'fixture'],0,{'targets':{0:e}})
        b._resolve_pending_strike(o)
        self.assertEqual(1000-e['hp'],154)

    def test_lifesteal_counts_hp_lost_before_relic_revive(self):
        b,o,e=self.battle(7);o['hp']=500;e['equip_passives']=[main_effect(4)]
        b._injured(e,2000,1,source=o)
        self.assertEqual(e['hp'],500)
        self.assertEqual(o['hp'],750)

    def test_reference_engine_has_same_independent_passive_channel(self):
        b,o,e=self.battle(12,engine=ReferenceBattle)
        b._add_buff(e,'shield',3,150)
        b._injured(e,100,1,source=o)
        self.assertEqual(e['hp'],975)

    def test_exported_b_cases_replay_identical_step_states(self):
        directory=ROOT/'docs/roguelite-abyss-equip-passive-cases'
        files=list(directory.glob('*.json'))
        self.assertEqual(len(files),27)
        for path in files:
            case=json.loads(path.read_text('utf-8'))
            actual=execute_case(self.cfg,case['kind'],case['ancient'],case)
            self.assertEqual(actual['expected'],case['expected'],path.name)


if __name__=='__main__':unittest.main()
