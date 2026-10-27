import copy,json,unittest
from pathlib import Path
from gateway import Backend
from native_skill_snapshot import _native_skill_snapshot
from equipment_bonds_104 import apply_part
from skin_revision_104 import PARAMS

ROOT=Path(__file__).resolve().parents[1]
class SkinRevisionTests(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.backend=Backend(':memory:',ROOT/'config/reconstruction/full-config.json');cls.cfg=cls.backend.config['cfg']
 @classmethod
 def tearDownClass(cls):cls.backend.clock.close();cls.backend.db.close()
 def test_final_coefficients_and_growth(self):
  c=self.cfg
  for aid in c['skin_revision_v2_104']['heroes']:
   family=c['avatar'][aid]['skin_revision_v2_104']
   for n,slot in enumerate((10,11,13)):
    if family==1227 and slot!=11:continue
    sid=c['avatar'][aid]['pl'][slot];row=c['skill'][sid];snap=_native_skill_snapshot(c,sid,10 if n==0 else 1)
    for i,(key,value) in enumerate(PARAMS[family][n].items()):self.assertAlmostEqual(snap['skills'][0][4+i],value,7,(aid,slot,key))
    self.assertNotIn('准备',row['info']);self.assertNotIn('设计',row['info']);self.assertNotIn('原版',row['info'])
 def test_equipment_targets_all_bond_combinations(self):
  c=self.cfg
  for aid in c['skin_revision_v2_104']['heroes']:
   if not aid.endswith('_6'):continue
   ordinary=[x for x in c['system_simple']['equipment_bonds_104'][aid] if x['kind']=='ordinary'];self.assertEqual(len(ordinary),2)
   for item in ordinary:
    slot='skill' if item['slot']=='normal' else 'leader_skill';index=10 if slot=='skill' else 11
    ids={c['avatar'][aid]['pl'][index]}
    ids.update(x[slot] for x in c['system_simple']['bond_skill_variants_104'][aid].values() if slot in x)
    for sid in ids:
     row=copy.deepcopy(c['skill'][sid]);before=copy.deepcopy(row['skill'])
     self.assertTrue(apply_part(row,item),(aid,sid));self.assertNotEqual(before,row['skill'])
     path=item['path'][0];self.assertGreater(row['skill'][0][path],before[0][path])
 def test_ekko_identity_pool_bonds(self):
  c=self.cfg;h=c['avatar']['A_1140_6'];self.assertEqual(h['name'],'艾克');self.assertIn('A_1140_6',c['system_simple']['skin_hero_ids'])
  for pool in ['advanced','vip']:
   cards=c['summon_calibration']['pools'][pool]['qualities']['orange']['cards'];self.assertEqual(sum(x['id']=='A_1140_6' for x in cards),1)
  bonds=[x for x in c['system_simple']['bonds_104'] if 'A_1140' in x['families']];self.assertEqual(len(bonds),2)
 def test_focused_bonds_describe_new_skills(self):
  c=self.cfg
  for bond in c['system_simple']['bonds_104']:
   aid=str(bond.get('focus'))+'_6'
   if c['avatar'].get(aid,{}).get('skin_revision_v2_104'):
    self.assertNotIn('{rank',bond['mechanism']['normal']['info'])
    self.assertNotIn('强化每级',bond['mechanism']['normal']['info'])

if __name__=='__main__':unittest.main()
