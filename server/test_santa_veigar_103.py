"""Santa Veigar's fixed 5% stacks and repeats locked at each cast's start."""
import copy,json,unittest
from pathlib import Path
from santa_veigar_103 import apply_santa_veigar_103
from battle_engine import _native_skill_snapshot
from manual_ability_sim import SkillCompleteBattle

class SantaVeigar103Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.document=json.loads((Path(__file__).resolve().parents[1]/'config/reconstruction/full-config.json').read_text('utf-8'))
        apply_santa_veigar_103(cls.document);cls.cfg=cls.document['cfg']
    def battle(self,count=3,level=1):
        def unit(aid,side,pos):return dict(aid=aid,isme=side==1,line=0,pos=pos,hp=10000,hp_max=10000,ap=300,de_ph=99999,de_ma=0,tpl=[1,2,2,250,300],new_4attrs={})
        owner=unit('A_1217_6',1,1800)
        owner.update(skill=_native_skill_snapshot(self.cfg,'S_271217_6',level),skillB=_native_skill_snapshot(self.cfg,'S_471217_6'))
        cfg=dict(self.cfg,system_simple=dict(self.cfg['system_simple'],attack=[]))
        b=SkillCompleteBattle([owner],[unit('A_1001_6',2,1600-100*i) for i in range(count)],config=cfg,trace_abilities=True)
        b.rng.get_random=lambda n=100:0
        return b
    def cast(self,b,slot='skill'):
        if slot=='leader_skill':b.a[0][slot]=_native_skill_snapshot(self.cfg,'S_371217_6')
        return b._apply_native_skill(b.a[0],b.b,slot)
    def test_damage_grows_but_five_percent_and_passive_timing_stay_fixed(self):
        for q in (5,6):
            h=self.cfg['avatar'][f'A_1217_{q}'];lo=_native_skill_snapshot(self.cfg,h['pl'][10],1);hi=_native_skill_snapshot(self.cfg,h['pl'][10],10)
            self.assertAlmostEqual(hi['skills'][0][4],2.6);self.assertEqual(lo['pl'][:2],[0,0])
            self.assertEqual(_native_skill_snapshot(self.cfg,h['pl'][13],1)['skills'],_native_skill_snapshot(self.cfg,h['pl'][13],10)['skills'])
            self.assertEqual(self.cfg['skill'][h['pl'][11]]['pl'][:2],[0,6])
        doc=copy.deepcopy(self.document);apply_santa_veigar_103(doc);self.assertEqual(doc,self.document)
    def test_normal_random_lane_damage_then_one_stack_at_both_levels(self):
        for level,damage in ((1,390),(10,780)):
            b=self.battle(level=level);b.b[1]['line']=1;self.cast(b)
            self.assertEqual([u['hp'] for u in b.b],[10000-damage,10000,10000])
            self.assertEqual(b.state(b.a[0])['santa_stacks'],1)
            self.assertEqual(b._get_damage(b.a[0]),315)
    def test_additive_layers_multiply_independently_and_survive_dispel(self):
        b=self.battle();owner=b.a[0];b.state(owner)['santa_stacks']=4;b._add_buff(owner,'strong',3,.5)
        self.assertEqual(b._get_damage(owner),540)
        b._remove_all_good(owner);self.assertEqual(b._get_damage(owner),360)
    def test_kill_increases_future_casts_without_immediate_recast(self):
        b=self.battle(2);owner=b.a[0];b.b[0]['hp']=1;self.cast(b)
        self.assertEqual(b.manual_casts['santa_n'],1)
        self.assertEqual(b.state(owner)['santa_stacks'],3) # 2 on kill + 1 resolution
        self.assertEqual(b.b[1]['hp'],10000)
        self.assertEqual(b.state(owner)['santa_kills'],1)
        self.cast(b)
        self.assertEqual(b.b[1]['hp'],10000-448-468)
        self.assertEqual(b.state(owner)['santa_stacks'],5)
        self.assertEqual(b.manual_casts['santa_n'],2)
    def test_repeats_lock_at_cast_start_and_retarget_after_each_kill(self):
        b=self.battle(20);owner=b.a[0]
        for enemy in b.b:enemy['hp']=1
        for expected_kills in (1,3,7,15,20):
            self.cast(b)
            self.assertEqual(sum(u['hp']==0 for u in b.b),expected_kills)
            self.assertEqual(b.state(owner)['santa_kills'],expected_kills)
        self.assertEqual(b.manual_casts['santa_n'],5)
        self.assertEqual(b.state(owner)['santa_stacks'],60)
        self.assertEqual(b.ability_contexts,[])
    def test_summon_kills_count_and_revived_enemies_do_not(self):
        b=self.battle(2);owner=b.a[0];b.b[0].update(aid='A_2003_2',hp=1,summon_owner='enemy')
        b._injured(b.b[0],10,3,source=owner)
        self.assertEqual(b.state(owner)['santa_stacks'],2)
        self.assertEqual(b.state(owner)['santa_kills'],1)
        self.assertNotIn('santa_n',b.manual_casts)
        b=self.battle(2);b.b[0]['hp']=1;b._add_buff(b.b[0],'bless',1)
        b._injured(b.b[0],10,3,source=b.a[0]);self.assertNotIn('santa_stacks',b.state(b.a[0]))
    def test_captain_true_damage_and_stun_cover_all_lanes_without_extra_layers(self):
        b=self.battle(3);b.b[1]['line']=1;b.b[2]['line']=2;self.cast(b,'leader_skill')
        self.assertEqual([u['hp'] for u in b.b],[9910]*3)
        self.assertTrue(all(b._buff(u,'stun').round==1 for u in b.b))
        self.assertNotIn('santa_stacks',b.state(b.a[0]))
    def test_captain_kills_and_missing_lane_targets_do_not_start_extra_casts(self):
        b=self.battle(3);owner=b.a[0]
        b.b[0]['hp']=1;b.b[1]['hp']=1;b.b[1]['line']=1;b.b[2]['line']=2
        self.cast(b,'leader_skill')
        self.assertEqual(b.state(owner)['santa_kills'],2)
        self.assertEqual(b.state(owner)['santa_stacks'],4)
        self.assertFalse(self.cast(b))
        self.assertNotIn('santa_n',b.manual_casts)

if __name__=='__main__':unittest.main()
