"""Cat Katarina: targets, damage recovery, charges, crit reward and kill cap."""
import copy,json,unittest
from pathlib import Path
from cat_katarina_103 import apply_cat_katarina_103
from battle_engine import _native_skill_snapshot
from manual_ability_sim import SkillCompleteBattle

class CatKatarina103Tests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.document=json.loads((Path(__file__).resolve().parents[1]/'config/reconstruction/full-config.json').read_text('utf-8'))
        apply_cat_katarina_103(cls.document);cls.cfg=cls.document['cfg']
    def battle(self,count=4,passive=False):
        def unit(aid,side,pos,hp=10000,line=0):
            return dict(aid=aid,isme=side==1,line=line,pos=pos,hp=hp,hp_max=10000,ap=300,de_ph=99999,de_ma=99999,
                        tpl=[1,2,3,250,300],new_4attrs={},slv=1,lv=99)
        owner=unit('A_1129_6',1,1800,5000)
        if passive:owner['skillB']=_native_skill_snapshot(self.cfg,'S_471129_6')
        enemies=[unit('A_1001_6',2,1600-100*i) for i in range(count)]
        cfg=dict(self.cfg,system_simple=dict(self.cfg['system_simple'],attack=[]))
        return SkillCompleteBattle([owner],enemies,config=cfg,trace_abilities=True)
    def cast(self,b,slot='n',level=1):
        b.a[0]['skill']=_native_skill_snapshot(self.cfg,f'S_{271129 if slot=="n" else 371129}_6',level)
        return b._apply_native_skill(b.a[0],b.b)
    def test_configuration_growth_fixed_passive_timing_and_idempotence(self):
        self.assertEqual(self.cfg['effect']['FX_S9130_COMBO']['sp'],850)
        self.assertNotIn('instantWave',self.cfg['effect']['FX_S9130_COMBO'])
        for q in (5,6):
            h=self.cfg['avatar'][f'A_1129_{q}'];self.assertEqual(h['tl'][2],3);self.assertEqual(h['skill_diff'],0)
            lo=_native_skill_snapshot(self.cfg,h['pl'][10],1);hi=_native_skill_snapshot(self.cfg,h['pl'][10],10)
            self.assertEqual(lo['pl'][:2],[0,2]);self.assertEqual(self.cfg['skill'][h['pl'][11]]['pl'][:2],[2,4])
            self.assertEqual(hi['skills'][0][4:],[2*x for x in lo['skills'][0][4:]])
            self.assertEqual(_native_skill_snapshot(self.cfg,h['pl'][13],1)['skills'],_native_skill_snapshot(self.cfg,h['pl'][13],10)['skills'])
        doc=copy.deepcopy(self.document);apply_cat_katarina_103(doc);self.assertEqual(doc,self.document)
    def test_normal_three_front_targets_locked_primary_heal_and_level_growth(self):
        for level,damage,heal,precision in ((1,[330,180,180,0],207,5000),(10,[660,360,360,0],828,10000)):
            b=self.battle();b.a[0]['pos']=2200;self.assertTrue(self.cast(b,level=level))
            self.assertEqual([10000-u['hp'] for u in b.b],damage)
            self.assertEqual(b.a[0]['hp'],5000+heal);self.assertEqual(b._buff_value(b.a[0],'hitup'),precision)
            self.assertEqual(b._buff(b.a[0],'hitup').round,2)
            self.assertEqual(b.a[0]['pos'],1800)
    def test_no_healing_from_shields_or_passive_chain_and_root_blocks_dash(self):
        b=self.battle()
        for u in b.b:b._add_buff(u,'shield',3,10000)
        self.cast(b);self.assertEqual(b.a[0]['hp'],5000)
        b=self.battle();b.state(b.a[0])['root']={'until':3};self.assertFalse(self.cast(b))
        self.assertTrue(all(u['hp']==10000 for u in b.b))
    def test_captain_all_lanes_six_hits_and_two_persistent_purify_charges(self):
        b=self.battle(3);b.b[1]['line']=1;b.b[2]['line']=2;b._add_buff(b.a[0],'curse',3)
        self.cast(b,'c');self.assertEqual([u['hp'] for u in b.b],[9460]*3)
        self.assertIsNone(b._buff(b.a[0],'curse'));self.assertEqual(b._buff_value(b.a[0],'purify'),2)
        for _ in range(4):b._tick_buffs(b.a[0])
        self.assertEqual(b._buff_value(b.a[0],'purify'),2)
        b._add_buff(b.a[0],'stun',1);self.assertIsNone(b._buff(b.a[0],'stun'))
        self.assertEqual(b._buff_value(b.a[0],'purify'),1)
        b._add_manual_skill_dot(b.a[0],'dot','poison',10,0,3,b.b[0],2,False)
        self.assertIsNone(b._buff(b.a[0],'purify'));self.assertFalse(b.a[0].get('_manual_dots'))
        b._add_buff(b.a[0],'silence',1);self.assertIsNotNone(b._buff(b.a[0],'silence'))
    def test_captain_rewards_each_crit_only_after_all_damage(self):
        b=self.battle(2)
        b._config=dict(b._config,system_simple=dict(b._config['system_simple'],attack=self.cfg['system_simple']['attack']))
        b._get_hit=lambda u:100000;b._get_flee=lambda u:0;b._get_crit=lambda u:1000;b._get_tough=lambda u:0
        b.rng.get_random=lambda n=100:0
        self.cast(b,'c')
        self.assertAlmostEqual(b._buff_value(b.a[0],'strong'),.36)
        self.assertEqual(b._buff(b.a[0],'strong').round,2)
        self.assertEqual(b.b[0]['hp'],b.b[1]['hp'])
    def test_kill_chain_retargets_and_is_capped_at_five_activations_per_global_round(self):
        b=self.battle(40,True);owner=b.a[0]
        for u in b.b:u['hp']=1
        b.rng.get_random=lambda n=100:0
        b._injured(b.b[0],10,3,source=owner)
        self.assertEqual(sum(u['hp']<=0 for u in b.b),16)
        self.assertEqual(b.state(owner)['cat_count'],5)
        b._injured(next(u for u in b.b if u['hp']>0),10,3,source=owner)
        self.assertEqual(sum(u['hp']<=0 for u in b.b),17)
        b.round_index+=1;b._injured(next(u for u in b.b if u['hp']>0),10,3,source=owner)
        self.assertEqual(sum(u['hp']<=0 for u in b.b),33)
    def test_each_passive_strike_draws_again_across_the_whole_map(self):
        b=self.battle(4,True);b.b[0]['hp']=1;b.b[2]['line']=1;b.b[3]['line']=2
        picks=iter([0,1,2]);b.rng.get_random=lambda n=100:next(picks)
        b._injured(b.b[0],10,3,source=b.a[0])
        self.assertEqual([u['hp'] for u in b.b[1:]],[9880]*3)
        self.assertEqual(b.state(b.a[0])['cat_count'],1)
    def test_revival_does_not_count_as_a_kill_and_dispel_removes_all_charges(self):
        b=self.battle(2,True);b.b[0]['hp']=1;b._add_buff(b.b[0],'bless',2)
        b._injured(b.b[0],100,3,source=b.a[0]);self.assertEqual(b.b[1]['hp'],10000)
        b.add_purify_charges(b.a[0],2);b._add_buff(b.a[0],'purify',3)
        self.assertEqual(b._buff_value(b.a[0],'purify'),2)
        b._remove_all_good(b.a[0]);self.assertIsNone(b._buff(b.a[0],'purify'))

if __name__=='__main__':unittest.main()
