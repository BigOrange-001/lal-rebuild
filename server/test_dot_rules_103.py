"""DOT armor bypass, status effects, budgets, and conserved shield overflow."""
import copy,json,unittest
from pathlib import Path
from gateway import Backend
from battle_engine import ReferenceBattle,_native_skill_snapshot
from manual_ability_sim import SkillCompleteBattle
from dot_rules_103 import apply_dot_rules_103
from skill_books import apply_equipment_calibration

ROOT=Path(__file__).resolve().parents[1]
class DotRules103Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.backend=Backend(':memory:',ROOT/'config/reconstruction/full-config.json')
        cls.document=cls.backend.config;cls.cfg=cls.document['cfg']
    @classmethod
    def tearDownClass(cls):cls.backend.db.close()
    def battle(self,kind=ReferenceBattle):
        u=dict(aid='A_1001_6',isme=True,line=0,pos=1000,hp=10000,hp_max=10000,ap=100,de_ph=99999,de_ma=99999,new_4attrs={'tough':0})
        v=dict(u,aid='A_1002_6',isme=False,pos=1100)
        b=kind([u],[v],config={'system_simple':{'attack':self.cfg['system_simple']['attack']}})
        return b,b.a[0],b.b[0]
    def test_native_poison_five_percent_plus_attack_once_and_one_vulnerability(self):
        b,owner,target=self.battle();b._add_buff(target,'poison',1,100)
        b._tick_buffs(target)
        self.assertEqual(target['hp'],9280) # (100 + 500) * 1.2
        self.assertIsNone(b._buff(target,'poison'))
        b._injured(target,100,1);self.assertEqual(target['hp'],9180)
    def test_every_manual_dot_ignores_armor_and_no_real_damage_rescale(self):
        for kind,damage_type,expected in [('bleed',1,100),('poison',2,120),('burn',0,100),('burn',2,100)]:
            with self.subTest(kind=kind,damage_type=damage_type):
                b,owner,target=self.battle();b._add_manual_skill_dot(target,'test',kind,100,0,1,owner,damage_type,False)
                b._tick_buffs(target);self.assertEqual(target['hp'],10000-expected)
                self.assertFalse(target['_manual_dots'])
    def test_poison_vulnerability_is_global_and_does_not_stack(self):
        b,owner,target=self.battle();b._add_buff(target,'poison',3,100)
        b._add_manual_skill_dot(target,'second','poison',100,0,3,owner,2,False)
        b._injured(target,100,1);self.assertEqual(target['hp'],9880)
        b._injured(target,100,3);self.assertEqual(target['hp'],9760)
    def test_any_burn_reduces_only_received_healing_by_forty_percent(self):
        for native in (True,False):
            b,owner,target=self.battle();target['hp']=5000
            if native:b._add_buff(target,'burn',3,100)
            else:b._add_book_burn(target,300,3,owner)
            b._injured(target,100,4,source=owner);self.assertEqual(target['hp'],5060)
            b._add_buff(target,'shield',3,100);self.assertEqual(b._buff_value(target,'shield'),100)
            b._remove_all_debuff(target);b._injured(target,100,4,source=owner);self.assertEqual(target['hp'],5160)
    def test_bleed_and_phantasm_shield_overflow_conserves_damage(self):
        for kind in ('bleed','phantasm'):
            for shield,hp_loss,remaining in [(0,100,0),(1,99,0),(150,50,0),(300,0,0),(301,0,1),(400,0,100)]:
                with self.subTest(kind=kind,shield=shield):
                    b,owner,target=self.battle()
                    if shield:b._add_buff(target,'shield',3,shield)
                    b._injured(target,100,6,source=owner,dot_kind=kind)
                    self.assertEqual(target['hp'],10000-hp_loss)
                    self.assertEqual(b._buff_value(target,'shield'),remaining)
        b,owner,target=self.battle();b._add_buff(target,'shield',3,150)
        b._injured(target,100,7,source=owner,dot_kind='burn')
        self.assertEqual((target['hp'],b._buff_value(target,'shield')),(10000,50))
    def test_purify_and_revival_clear_every_layer_without_stale_tick(self):
        b,owner,target=self.battle();target['hp']=1
        b._add_manual_skill_dot(target,'a','bleed',100,0,3,owner,1,False)
        b._add_manual_skill_dot(target,'b','burn',100,0,3,owner,2,False)
        b._add_buff(target,'bless',2,0);b._tick_buffs(target)
        self.assertEqual(target['hp'],5000);self.assertFalse(target['_manual_dots'])
        b._add_buff(target,'purify',2,0)
        self.assertFalse(b._add_manual_skill_dot(target,'blocked','bleed',100,0,3,owner,1,False))
    def test_malzahar_tick_uses_same_armor_bypass_and_shield_rule(self):
        b,owner,target=self.battle(SkillCompleteBattle)
        b.state(target)[('malz',1)]=dict(owner=owner,until=1,ticks=3,tick_damage=100,hops=0,debuff=True)
        b._add_buff(target,'shield',3,150);b.turn_start(target)
        self.assertEqual(target['hp'],9950);self.assertIsNone(b._buff(target,'shield'))
    def test_all_calibrated_curves_hit_three_times_reference_and_are_idempotent(self):
        for change in self.cfg['dot_rules_103']['changes']:
            if change['kind']=='phantasm':continue
            self.assertAlmostEqual(change['new']*change['rounds'],3*change['reference'][0],places=8)
            if 'max' in change:
                self.assertAlmostEqual(change['max']*change['rounds'],3*change['reference'][1],places=8)
        d=copy.deepcopy(self.document);apply_dot_rules_103(d);self.assertEqual(d,self.document)
        self.assertEqual(self.cfg['system_simple']['attack'][18],.05)
        self.assertTrue(all(a['name']=='卡尔玛' for aid,a in self.cfg['avatar'].items() if aid.startswith('A_1139_')))
    def test_book_damage_and_rank_curves_are_preserved(self):
        base=json.loads((ROOT/'config/reconstruction/full-config.json').read_text('utf-8'));apply_equipment_calibration(base)
        for eid,e in self.cfg['equip'].items():
            if e.get('type')!=6:continue
            sid=e['skill']
            for level in (1,10):
                self.assertEqual(_native_skill_snapshot(self.cfg,sid,level)['skills'],_native_skill_snapshot(base['cfg'],sid,level)['skills'])
    def test_ranked_dot_curves_and_runtime_text_have_no_old_poison_formula(self):
        for sid in ('S_621019_5','S_621082_6','S_621063_6'):
            s=self.cfg['skill'][sid]
            for level in (1,5,10):
                actions=_native_skill_snapshot(self.cfg,sid,level)['skills']
                from dot_rules_103 import _direct
                dot=next(a for a in actions if a[0] in ('manual_dot','poison'))
                coeff=dot[2] if dot[0]=='manual_dot' else dot[3];rounds=dot[4]
                self.assertAlmostEqual(coeff*rounds,3*_direct(actions),places=7)
            self.assertNotIn('生命上限的1%',s['info'])

if __name__=='__main__':unittest.main()
