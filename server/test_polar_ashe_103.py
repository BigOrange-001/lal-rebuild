"""Polar Ashe: physical volley, real attack targeting and round-scoped n."""
import copy,json,unittest
from pathlib import Path
from polar_ashe_103 import apply_polar_ashe_103
from battle_engine import _native_skill_snapshot
from manual_ability_sim import SkillCompleteBattle

class PolarAshe103Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.document=json.loads((Path(__file__).resolve().parents[1]/'config/reconstruction/full-config.json').read_text('utf-8'))
        apply_polar_ashe_103(cls.document);cls.cfg=cls.document['cfg']
    def battle(self,count=4):
        def unit(aid,side,pos):return dict(aid=aid,isme=side==1,line=0,pos=pos,hp=100000,hp_max=100000,ap=300,de_ph=100,de_ma=0,tpl=[1,2,1,250,300],new_4attrs={'hit':123})
        owner=unit('A_1202_6',1,1800);owner['skillB']=_native_skill_snapshot(self.cfg,'S_471202_6')
        cfg=dict(self.cfg,system_simple=dict(self.cfg['system_simple'],attack=[]))
        return SkillCompleteBattle([owner],[unit('A_1001_6',2,1600-100*i) for i in range(count)],config=cfg,trace_abilities=True)
    def cast(self,b,slot='n',level=1):
        b.a[0]['skill']=_native_skill_snapshot(self.cfg,f'S_{271202 if slot=="n" else 371202}_6',level)
        return b._apply_native_skill(b.a[0],b.b)
    def test_quality_growth_timing_damage_type_and_idempotence(self):
        for q in (5,6):
            hero=self.cfg['avatar'][f'A_1202_{q}'];self.assertEqual(hero['tl'][2],1)
            lo=_native_skill_snapshot(self.cfg,hero['pl'][10],1);hi=_native_skill_snapshot(self.cfg,hero['pl'][10],10)
            self.assertEqual(lo['pl'][:2],[1,0]);self.assertEqual(self.cfg['skill'][hero['pl'][11]]['pl'][:2],[3,3])
            for a,c in zip(hi['skills'][0][4:],lo['skills'][0][4:]):self.assertAlmostEqual(a,2*c)
        doc=copy.deepcopy(self.document);apply_polar_ashe_103(doc);self.assertEqual(doc,self.document)
    def test_volley_only_own_lane_uses_physical_damage_and_applies_exact_armor_reduction(self):
        for level,crit,damage,defense in ((1,100000,110,65),(10,200000,320,30)):
            b=self.battle();b.b[3]['line']=1
            for u in b.b:u['de_ma']=999999
            self.cast(b,level=level)
            self.assertEqual([100000-u['hp'] for u in b.b],[damage]*3+[0])
            self.assertEqual(b._buff_value(b.a[0],'critup'),crit)
            self.assertEqual(b._buff(b.a[0],'critup').round,1)
            self.assertEqual([b._get_de_ph(u) for u in b.b],[defense]*3+[100])
    def test_ultimate_uses_highest_total_attack_and_exact_three_hundred_radius(self):
        b=self.battle(5);owner=b.a[0]
        b.b[0].update(pos=1000,ap=500);b._add_buff(b.b[0],'strong',3,1)
        b.b[1].update(pos=1299,ap=600);b.b[2].update(pos=1301,ap=600)
        b.b[3].update(pos=1000,line=1,ap=900);b.b[4].update(pos=700,ap=600)
        readings=[];original=b.hit
        def hit(*args,**kwargs):readings.append(b._get_hit(owner));return original(*args,**kwargs)
        b.hit=hit;self.cast(b,'c')
        self.assertEqual(readings,[50123]*3)
        self.assertEqual([100000-u['hp'] for u in b.b],[900,900,0,0,900])
        self.assertEqual(b._get_hit(owner),123)
        for u in (b.b[0],b.b[1],b.b[4]):
            self.assertEqual(b._buff(u,'curse').round,1);self.assertEqual(b._buff(u,'stun').round,1)
    def test_cast_precision_is_restored_even_if_damage_raises(self):
        b=self.battle();owner=b.a[0]
        def fail(*args,**kwargs):raise RuntimeError('test')
        b.hit=fail
        with self.assertRaises(RuntimeError):self.cast(b,'c')
        self.assertEqual(b._get_hit(owner),123)
    def test_first_basic_gains_one_same_round_does_not_add_again_and_caps_at_four(self):
        b=self.battle(1);b.b[0]['de_ph']=0;b.rng.get_random=lambda n=100:0;owner=b.a[0]
        b._basic_attack(owner,b.b[0])
        self.assertEqual(b.b[0]['hp'],100000-300-180)
        self.assertEqual(b.state(owner)['polar_count'],1)
        for r,expected in ((0,1),(1,2),(2,3),(3,4),(4,4)):
            b.round_index=r;b.polar_basic_attack(owner)
            self.assertEqual(b.state(owner)['polar_count'],expected)
        hits=[e for e in b.ability_events if e['kind']=='hit']
        self.assertEqual(len(hits),6) # one followup per real basic/direct passive call
    def test_skipped_rounds_decay_before_next_basic_and_never_go_below_zero(self):
        b=self.battle(1);owner=b.a[0];b.rng.get_random=lambda n=100:0
        for r in range(4):b.round_index=r;b.polar_basic_attack(owner)
        b.round_index=6;b.polar_basic_attack(owner);self.assertEqual(b.state(owner)['polar_count'],3)
        b.round_index=20;b.polar_basic_attack(owner);self.assertEqual(b.state(owner)['polar_count'],1)
    def test_followup_randomly_targets_only_own_lane_and_never_recurses(self):
        b=self.battle(3);owner=b.a[0];b.b[2]['line']=1
        for u in b.b:u['de_ph']=0
        picks=iter([0,1]);b.rng.get_random=lambda n=100:next(picks)
        b.polar_basic_attack(owner);b.polar_basic_attack(owner)
        self.assertEqual([u['hp'] for u in b.b],[99820,99820,100000])
        self.assertEqual(b.state(owner)['polar_count'],1)

if __name__=='__main__':unittest.main()
