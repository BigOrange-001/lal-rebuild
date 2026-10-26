"""Tier boundaries, shared skills and idempotent production calibration."""
import copy
import json
import unittest
from pathlib import Path

from hero_balance_103 import adjustment,apply_hero_balance_103,PLAN


class TierBalanceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        root=Path(__file__).resolve().parents[1]
        cls.before=json.loads((root/'config/reconstruction/full-config.json').read_text('utf-8'))
        cls.plan=json.loads(PLAN.read_text('utf-8'))

    def test_exact_boundaries(self):
        self.assertEqual(adjustment('T4',.4499),(1.12,1.25,'T4'))
        self.assertEqual(adjustment('T3',.4499),(1.08,1.15,'T3-low'))
        self.assertEqual(adjustment('T3',.45),(1.05,1.05,'unchanged'))
        self.assertEqual(adjustment('T3',.50),(1.05,1.05,'unchanged'))
        self.assertEqual(adjustment('T2',.5001),(1,1,'unchanged'))

    def test_all_panel_pairs_and_unchanged_heroes(self):
        d=copy.deepcopy(self.before);marker=apply_hero_balance_103(d,self.plan)
        self.assertEqual(len(marker['avatar_changes']),205)
        for row in marker['avatar_changes']:
            self.assertEqual(row['after'],[round(x*row['panel_factor'],10) for x in row['before']])
            self.assertEqual(d['cfg']['avatar'][row['aid']]['pl'][8:10],self.before['cfg']['avatar'][row['aid']]['pl'][8:10])
        self.assertEqual(d['cfg']['avatar']['A_1226_6'],self.before['cfg']['avatar']['A_1226_6'])

    def test_timing_policy_preserves_special_values_and_light_group(self):
        d=copy.deepcopy(self.before);marker=apply_hero_balance_103(d,self.plan)
        for row in marker['skill_changes']:
            for index,(old,new) in enumerate(zip(row['before_timing'],row['after_timing'])):
                expected=old
                if type(old) in (int,float) and old>=0:
                    if row['mode']=='T4' or row['mode']=='T3-low' and old>=(2 if index==0 else 3):expected=max(0,old-1)
                self.assertEqual(new,expected)

    def test_shared_skills_do_not_change_other_heroes_or_summon_templates(self):
        d=copy.deepcopy(self.before);apply_hero_balance_103(d,self.plan)
        for sid in ('S_9000_5','S_9001_5','S_9004_6','S_9005_6'):
            self.assertEqual(d['cfg']['skill'][sid],self.before['cfg']['skill'][sid])
        first=d['cfg']['avatar']['A_1998_6']['pl'][10]
        second=d['cfg']['avatar']['A_1212_6']['pl'][10]
        self.assertNotEqual(first,second)
        self.assertEqual(d['cfg']['avatar']['A_2003_2'],self.before['cfg']['avatar']['A_2003_2'])

    def test_native_manual_damage_effect_and_summon_factors_compose(self):
        d=copy.deepcopy(self.before);marker=apply_hero_balance_103(d,self.plan)
        for entry in marker['skill_changes']:
            old=self.before['cfg']['skill'][entry['source']];new=d['cfg']['skill'][entry['target']]
            if old.get('manualDamageMultiplier'):
                self.assertAlmostEqual(new['manualDamageMultiplier'],old['manualDamageMultiplier']*entry['factor'])
            if old.get('captainSummonMultiplier'):
                self.assertAlmostEqual(new['captainSummonMultiplier'],old['captainSummonMultiplier']*entry['factor'])

    def test_idempotent_and_rejects_different_plan(self):
        d=copy.deepcopy(self.before);apply_hero_balance_103(d,self.plan);once=copy.deepcopy(d)
        apply_hero_balance_103(d,self.plan);self.assertEqual(once,d)
        plan=copy.deepcopy(self.plan);plan['source_sha256']='changed'
        with self.assertRaisesRegex(ValueError,'different'):apply_hero_balance_103(d,plan)


if __name__=='__main__':unittest.main()
