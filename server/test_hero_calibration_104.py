import copy
import json
import unittest
from pathlib import Path
from gateway import Backend
from native_skill_snapshot import _native_skill_snapshot
from manual_ability_sim import SkillCompleteBattle
from test_manual_ability_sim import unit

ROOT=Path(__file__).resolve().parents[1]

class CalibrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.backend=Backend(':memory:',ROOT/'config/reconstruction/full-config.json')
        cls.cfg=cls.backend.config['cfg']
    @classmethod
    def tearDownClass(cls):cls.backend.clock.close();cls.backend.db.close()

    def battle(self,aid):
        owner=unit(aid,1,1800);owner['hp_max']=100000;owner['hp']=40000
        owner['_mod_owner_turn']=10
        hero=self.cfg['avatar'][aid]
        for slot,index in [('skill',10),('leader_skill',11),('skillB',13)]:
            owner[slot]=_native_skill_snapshot(self.cfg,hero['pl'][index] if len(hero['pl'])>index else None,10 if index==10 else 1)
        enemies=[unit('A_1001_6',2,1600-i*100) for i in range(3)]
        for enemy in enemies:enemy['hp']=enemy['hp_max']=100000
        ally=unit('A_1001_6',1,1700);ally['hp']=2000
        cfg={'avatar':self.cfg['avatar'],'skill':self.cfg['skill'],'system_simple':{'hero_skill_output_rate_104':.8}}
        return SkillCompleteBattle([owner,ally],enemies,config=cfg,trace_abilities=True)

    def test_every_new_kit_executes_and_has_two_live_equipment_parts(self):
        for aid in self.cfg['hero_calibration_104']['skins']:
            if not aid.endswith('_6'):continue
            with self.subTest(hero=aid):
                # Revised kits execute in the AIR event runtime; their actual
                # method bodies are exercised by test_skin_revision_native_104.
                if not self.cfg['avatar'][aid].get('skin_revision_v2_104'):
                    b=self.battle(aid);owner=b.a[0]
                    self.assertTrue(b._apply_native_skill(owner,b.b,'skill'))
                    owner['_mod_owner_turn']+=4;b.round_index+=4
                    self.assertTrue(b._apply_native_skill(owner,b.b,'leader_skill'))
                rows=self.cfg['system_simple']['equipment_bonds_104'][aid]
                ordinary=[r for r in rows if r['kind']=='ordinary']
                for r in ordinary:
                    sid=self.cfg['avatar'][aid]['pl'][10 if r['slot']=='normal' else 11]
                    mapping=self.cfg['system_simple']['equipment_skill_variants_104'][aid][sid]
                    self.assertIn(r['equipment'],mapping)

    def test_exact_review_values(self):
        def skill(aid,slot,level=1):
            return _native_skill_snapshot(self.cfg,self.cfg['avatar'][aid]['pl'][slot],level)
        self.assertAlmostEqual(skill('A_1029_6',10,10)['skills'][0][2],.8)
        self.assertEqual(skill('A_1132_6',11)['manualClonePolicy']['ttlOwnTurns'],5)
        self.assertEqual(skill('A_1132_6',11)['manualClonePolicy']['panelStatRatio'],1)
        self.assertEqual(skill('A_1126_6',11)['pl'][:2],[2,4])
        self.assertEqual(skill('A_1208_6',13)['skills'][0][2],.7)
        self.assertAlmostEqual(skill('A_1217_6',10,10)['skills'][0][4]*.8,2.1)
        self.assertEqual(self.cfg['avatar']['A_2024_6']['name'],'哮天犬')
        self.assertEqual(self.cfg['skill'][self.cfg['avatar']['A_1226_6']['pl'][11]]['info'],'召唤哮天犬协同作战。')

    def test_alistar_reduction_covers_dot_expires_and_never_reduces_heals(self):
        import test_manual_ability_sim as helper
        h=helper.ManualAbilityStateTests();b=h.battle();owner=b.a[0]
        h.cast(b,'alistar_c');before=owner['hp']
        b._injured(owner,1000,6,source=b.b[0]);self.assertEqual(before-owner['hp'],200)
        before=owner['hp'];b._injured(owner,100,4,source=owner);self.assertEqual(owner['hp']-before,100)
        b.turn_start(owner);before=owner['hp'];b._injured(owner,1000,1,source=b.b[0]);self.assertEqual(before-owner['hp'],1000)

    def test_santa_accuracy_is_cast_scoped_and_nurse_is_same_lane(self):
        b=self.battle('A_1217_6');owner=b.a[0];seen=[]
        b.hit=lambda o,t,c,k,shared_total=0:seen.append(b._get_hit(o)) or True
        before=b._get_hit(owner)
        b._apply_native_skill(owner,b.b,'leader_skill')
        self.assertTrue(seen);self.assertTrue(all(v==before+10000 for v in seen));self.assertEqual(b._get_hit(owner),before)
        b=self.battle('A_1208_6');b.b[2]['line']=2
        b._on_healing_received(b.a[0],1000,1000)
        self.assertEqual(b.b[2]['hp'],100000)
        self.assertEqual(b.b[0]['hp'],99300)

    def test_akali_response_needs_own_dash_and_only_fires_once(self):
        b=self.battle('A_1015_6');owner=b.a[0]
        self.assertFalse(b._emit_mod_event(owner,'dodge',b.b[0],owner))
        b._apply_native_skill(owner,b.b,'skill')
        self.assertTrue(b._emit_mod_event(owner,'dodge',b.b[0],owner))
        owner['_mod_owner_turn']+=2;b.round_index+=2
        self.assertFalse(b._emit_mod_event(owner,'damage_taken',b.b[0],owner,100))

    def test_azir_rally_retains_existing_soldier_identity(self):
        b=self.battle('A_1124_6');owner=b.a[0]
        b._apply_native_skill(owner,b.b,'leader_skill')
        old=[u for u in b.a if u.get('summon_owner')]
        self.assertEqual(len(old),2)
        for soldier in old:soldier['hp']=int(soldier['hp_max']*.5)
        b._apply_native_skill(owner,b.b,'leader_skill')
        self.assertEqual([id(u) for u in old],[id(u) for u in b.a if u.get('summon_owner')])
        self.assertTrue(all(b._buff(u,'strong') for u in old))
        self.assertTrue(all(u['hp']>u['hp_max']*.5 for u in old))

    def test_explicit_keep_heroes_mechanics(self):
        path=ROOT/'build/calibration-before.json'
        if not path.exists():self.skipTest('Local pre-review snapshot unavailable')
        before=json.loads(path.read_text('utf8'))
        for family in ('A_1129','A_1008','A_1014','A_1077','A_1134','A_1226'):
            for aid,h in self.cfg['avatar'].items():
                if aid.rsplit('_',1)[0]!=family:continue
                for slot in (10,11,13):
                    if len(h['pl'])<=slot or not h['pl'][slot]:continue
                    old=before['skill'][before['avatar'][aid]['pl'][slot]];new=self.cfg['skill'][h['pl'][slot]]
                    self.assertEqual(old['skill'],new['skill'],(aid,slot))
                    self.assertEqual(old['pl'],new['pl'],(aid,slot))

if __name__=='__main__':unittest.main()
