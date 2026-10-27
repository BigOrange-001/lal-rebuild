import unittest
from pathlib import Path
from gateway import Backend
from native_skill_snapshot import _native_skill_snapshot
from test_manual_ability_sim import ManualAbilityStateTests

class HeroRevisionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.backend=Backend(':memory:',Path(__file__).resolve().parents[1]/'config/reconstruction/full-config.json')
        cls.cfg=cls.backend.config['cfg']
    @classmethod
    def tearDownClass(cls):cls.backend.clock.close();cls.backend.db.close()

    def test_gabriel_and_zed_final_values(self):
        cfg=self.cfg;hero=cfg['avatar']['A_1998_6']
        self.assertEqual(hero['name'],'加百列')
        for level,ratio in ((1,.55),(10,1.1)):
            skill=_native_skill_snapshot(cfg,hero['pl'][10],level)
            self.assertEqual(len(skill['skills']),5)
            for action in skill['skills']:self.assertAlmostEqual(action[1],ratio)
        cap=cfg['skill'][hero['pl'][11]]
        self.assertEqual(cap['pl'][:2],[1,5]);self.assertEqual(cap['skill'][2][1],3)
        self.assertEqual(cap['skill'][3][1:3],[.3,3])
        self.assertEqual(cap['actionTargetMaxTargets'][0],999)
        zed=cfg['avatar']['A_1132_6']
        self.assertEqual(cfg['skill'][zed['pl'][11]]['manualClonePolicy']['panelStatRatio'],1)

    def test_karthus_isolation_and_global_finisher(self):
        helper=ManualAbilityStateTests();battle=helper.battle();hits=[]
        battle.hit=lambda owner,target,ratio,kind,shared=0: hits.append((target,ratio,kind)) or True
        helper.cast(battle,'karthus_n')
        self.assertEqual(len(hits),3);self.assertTrue(all(h[1]==.875 for h in hits))
        battle.b[1]['hp']=battle.b[2]['hp']=0;hits.clear()
        helper.cast(battle,'karthus_n');self.assertEqual(hits[0][1],1.75)
        battle.b[1]['hp']=3000;battle.b[1]['line']=2;hits.clear()
        helper.cast(battle,'karthus_c')
        self.assertEqual(len(hits),2);self.assertAlmostEqual(hits[1][1],3.85)

if __name__=='__main__':unittest.main()
