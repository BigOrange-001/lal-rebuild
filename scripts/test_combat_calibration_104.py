"""The calibration counter must not credit captain skills or basic attacks."""
import copy
import unittest

import calibrate_combat_duels_104 as study
from test_combat_redesign import config, unit


class SkillTrialTests(unittest.TestCase):
    def test_normal_trial_excludes_leader_and_counts_real_casts(self):
        cfg=config();cfg['system_simple']['attack'][4:8]=[0,0,0,0]
        cfg['avatar']={aid:dict(name=aid,tl=[0,1,1],pl=[0]*14) for aid in ('A_1001_6','A_1002_6')}
        study.CFG=cfg
        normal=dict(skid='NORMAL',pl=[0,0,1000,0,0,1],skills=[['damage',1,1]])
        captain=dict(skid='CAPTAIN',pl=[0,0,1000,0,0,1],skills=[['damage',100,1]])
        source=unit(1,skill=normal,leader_skill=captain,leader=1,skillB=None,skill_diff=0)
        target=unit(2,hp=5000,hp_max=5000,de_ph=0,de_ma=0,skill=None,skillB=None,skill_diff=0)
        saved=copy.deepcopy(source)
        row=study.run_job(('fixture','output',source,target,1200,3))
        self.assertEqual(row['mean_casts'],5)
        self.assertEqual(row['censored'],0)
        self.assertEqual(row['leader_mean_fraction'],1)
        self.assertEqual(source,saved)


if __name__=='__main__':unittest.main()
