import copy,unittest
from pathlib import Path
from gateway import load_game_config
from dragonmancer_kaisa_104 import AID,NORMAL,CAPTAIN,PASSIVE,apply_dragonmancer_kaisa,builtin_asset
from native_skill_snapshot import _native_skill_snapshot
from battle_engine import base_unit
from manual_ability_sim import SkillCompleteBattle
ROOT=Path(__file__).resolve().parents[1]

class DragonmancerKaisaTests(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.cfg=load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']
 def config(self):
  c=copy.deepcopy(self.cfg);c['combat_rules']={}
  a=c['system_simple']['attack'];a[2]=1;a[4]=0;a[5]=0;a[15]=0;a[21]=1
  return c
 def unit(self,c,aid=AID,team=1,line=0,pos=2400,leader=False):
  u=base_unit(c,aid,1,1,line,0.2,leader,team)
  u.update(pos=pos,hp=100000,hp_max=100000,ap=100,de_ph=0,de_ma=0)
  u['new_4attrs']={'hit':1000000,'flee':0,'crit':0,'tough':0}
  return u
 def battle(self,count=1):
  c=self.config();owner=self.unit(c,leader=True)
  enemies=[self.unit(c,'A_1001_6',2,pos=1400-300*i) for i in range(count)]
  b=SkillCompleteBattle([owner],enemies,seed=5,config=c,trace_abilities=True)
  return b,b.a[0],b.b
 def cast(self,b,o):
  with b.context(o,'active',skill=o['skill']):
   return b.execute(o,'dragon_kaisa_n',1,o['skill'])
 def test_panel_timing_rank_and_no_voice(self):
  h=self.cfg['avatar'][AID]
  self.assertEqual(h['pl'][:8],self.cfg['avatar']['A_1206_6']['pl'][:8])
  self.assertEqual((h['stat_profile'],h['tl'][0]),(1,1))
  self.assertTrue(h['voiceDisabled104'])
  for lv,coefficient in [(1,1),(10,2)]:
   self.assertAlmostEqual(_native_skill_snapshot(self.cfg,NORMAL,lv)['skills'][0][4],coefficient)
  self.assertEqual(self.cfg['skill'][NORMAL]['pl'][:2],[0,1])
  self.assertEqual(self.cfg['skill'][CAPTAIN]['pl'][:2],[0,3])
  self.assertIn('持续7回合',self.cfg['skill'][CAPTAIN]['info'])
  for field in ('info','rankInfoTemplate'):
   self.assertIn('叠加1层电浆',self.cfg['skill'][PASSIVE][field])
   for ui_word in ('格','点亮','标记'):
    self.assertNotIn(ui_word,self.cfg['skill'][PASSIVE][field])
 def test_config_idempotence_and_asset_dispatch(self):
  c=copy.deepcopy(self.cfg);before=copy.deepcopy(c)
  apply_dragonmancer_kaisa(c);self.assertEqual(c,before)
  media=c['dragonmancer_kaisa_104']['media']
  for e in media['assets']:self.assertEqual(len(builtin_asset(c,media['digest'],e['path'])[0]),e['bytes'])
  from orange_ascension_104 import builtin_asset as dispatch
  e=media['assets'][0];self.assertEqual(dispatch(c,media['digest'],e['path']),builtin_asset(c,media['digest'],e['path']))
 def test_three_projectiles_round_robin_for_one_to_four_enemies(self):
  for n,expected in [(1,[3]),(2,[2,1]),(3,[1,1,1]),(4,[1,1,1,0])]:
   b,o,enemies=self.battle(n);self.assertTrue(self.cast(b,o))
   self.assertEqual([100000-u['hp'] for u in enemies],[100*x for x in expected])
 def test_growth_is_unbounded_and_per_caster(self):
  b,o,_=self.battle()
  self.cast(b,o);self.cast(b,o);self.cast(b,o)
  self.assertEqual([e['missiles'] for e in b.ability_events if e['kind']=='kaisa_volley'],[3,5,7])
  o['_kaisa_casts']=60
  self.cast(b,o)
  self.assertEqual([e['missiles'] for e in b.ability_events if e['kind']=='kaisa_volley'][-1],123)
 def test_each_shot_reacquires_after_front_death(self):
  b,o,enemies=self.battle(2);enemies[0]['hp']=100
  self.cast(b,o)
  self.assertLessEqual(enemies[0]['hp'],0)
  self.assertEqual(enemies[1]['hp'],99800)
 def test_empty_lane_does_not_spend_stack(self):
  b,o,_=self.battle();o['line']=1
  self.assertFalse(self.cast(b,o));self.assertNotIn('_kaisa_casts',o)
 def test_hunt_lands_500_from_actual_front_and_free_cast_keeps_normal_cd(self):
  b,o,enemies=self.battle(2)
  for u in enemies:u['line']=1
  o['_skill_cd']=7;o['_skill_cd_leader']=-1;o['_kaisa_casts']=2
  b._add_buff(enemies[1],'stun',1)
  self.assertEqual((o['line'],o['pos']),(1,enemies[0]['pos']+500))
  self.assertEqual(o['_skill_cd'],7);self.assertEqual(o['_skill_cd_leader'],3)
  self.assertEqual(o['_kaisa_casts'],3)
  clones=[u for u in b.a if u.get('_kaisa_clone')]
  self.assertEqual(len(clones),1);clone=clones[0]
  self.assertEqual((clone['line'],clone['pos']),(0,2400))
  for key in ('hp_max','ap','de_ph','de_ma'):self.assertEqual(clone[key],o[key])
  self.assertIs(clone['_kaisa_root'],o);self.assertEqual(clone['_kaisa_casts'],0)
  self.assertFalse(clone['leader']);self.assertIsNone(clone['leader_skill'])
  self.assertEqual(clone['skill']['skills'],o['skill']['skills'])
  self.assertEqual(clone['skillB']['skid'],PASSIVE)
  self.assertEqual(b._buff(clone,'summon').round,7)
  enemies[0]['line']=0
  self.cast(b,clone);self.assertEqual(clone['_kaisa_casts'],1);self.assertEqual(o['_kaisa_casts'],3)
 def test_hunt_ignores_same_lane_summon_and_cooldown(self):
  b,o,enemies=self.battle();o['_skill_cd_leader']=-1
  b.b.append(self.unit(b._config,'A_1001_6',2,line=1,pos=1400))
  b._add_buff(enemies[0],'stun',1);self.assertEqual(o['line'],0)
  enemies[0]['line']=1;enemies[0]['summon_owner']='fake'
  b.kaisa_stun(enemies[0]);self.assertEqual(o['line'],0)
  enemies[0].pop('summon_owner');o['_skill_cd_leader']=2
  b.kaisa_stun(enemies[0]);self.assertEqual(o['line'],0)
 def test_plasma_shared_with_clone_and_burst_does_not_restack(self):
  b,o,enemies=self.battle();target=enemies[0]
  clone=b._spawn_summon(o,AID,1,5);clone.update(_kaisa_clone=True,_kaisa_root=o)
  target['hp']=target['hp_max']=10000
  for actor in [o,clone,o,clone,o]:
   with b.context(actor,'basic'):b.hit(actor,target,1/b.hero_output_rate_104(actor),1)
  self.assertEqual(target['hp'],7500)
  self.assertEqual(target['_kaisa_plasma'][b.state(o)['index']],0)
  self.assertIsNotNone(b._buff(target,'curse'))
  self.assertEqual(sum(e['kind']=='kaisa_plasma_burst' for e in b.ability_events),1)
 def test_two_bodies_do_not_share_unrelated_roots(self):
  b,o,enemies=self.battle();target=enemies[0]
  other=b._spawn_summon(o,AID,1,5);other.pop('summon_owner',None)
  for actor in [o]*4+[other]*4:
   with b.context(actor,'basic'):b.hit(actor,target,1/b.hero_output_rate_104(actor),1)
  self.assertEqual(target['_kaisa_plasma'][b.state(o)['index']],4)
  self.assertEqual(target['_kaisa_plasma'][b.state(other)['index']],4)
  self.assertFalse(any(e['kind']=='kaisa_plasma_burst' for e in b.ability_events))
 def test_clone_expires_and_keeps_rank_ten(self):
  b,o,enemies=self.battle();o['skill']=_native_skill_snapshot(b._config,NORMAL,10)
  enemies[0]['line']=1;o['_skill_cd_leader']=-1
  b._add_buff(enemies[0],'stun',1)
  clone=next(u for u in b.a if u.get('_kaisa_clone'))
  self.assertEqual(clone['skill']['skills'][0][4],2)
  for _ in range(7):
   self.assertFalse(b._tick_buffs(clone))
   self.assertGreater(clone['hp'],0)
  # The native summon survives its seven actions and expires at turn eight's
  # start, before it can take an eighth action.
  b._tick_buffs(clone)
  self.assertLessEqual(clone['hp'],0)
 def test_mirrored_team_lands_on_its_own_side_of_front(self):
  c=self.config();kaisa=self.unit(c,team=2,line=0,pos=600,leader=True)
  enemy=self.unit(c,'A_1001_6',1,line=1,pos=1400)
  b=SkillCompleteBattle([enemy],[kaisa],config=c)
  o,target=b.b[0],b.a[0];o['_skill_cd_leader']=-1
  b._add_buff(target,'stun',1)
  self.assertEqual((o['line'],o['pos']),(1,900))
 def test_new_battle_resets_volley_and_plasma_counters(self):
  b,o,enemies=self.battle();self.cast(b,o)
  fresh=SkillCompleteBattle([o],enemies,config=b._config)
  self.assertNotIn('_kaisa_casts',fresh.a[0]);self.assertNotIn('_kaisa_plasma',fresh.b[0])
 def test_replaced_passive_does_not_keep_old_plasma(self):
  b,o,enemies=self.battle();o['skillB']=None
  with b.context(o,'basic'):b.hit(o,enemies[0],1,1)
  self.assertNotIn('_kaisa_plasma',enemies[0])
 def test_plasma_true_damage_ignores_armor_rps_and_legacy_true_ratio(self):
  b,o,enemies=self.battle();target=enemies[0]
  target['hp']=target['hp_max']=10000;target['de_ma']=target['de_ph']=1000000
  b._config['system_simple']['attack'][1]=.3
  b._config['system_simple']['attack'][2]=1.5
  b._config['avatar'][target['aid']]['tl'][0]=2
  for _ in range(5):
   with b.context(o,'basic'):b.kaisa_event(o,'hit',o,target)
  self.assertEqual(target['hp'],8000)
 def test_single_lane_stun_can_trigger_hunt(self):
  b,o,enemies=self.battle();o['_skill_cd_leader']=-1
  b._add_buff(enemies[0],'stun',1)
  self.assertEqual(o['_kaisa_casts'],1)
  self.assertEqual(o['pos'],enemies[0]['pos']+500)
 def test_last_contested_lane_can_hunt_on_same_lane(self):
  c=self.config();allies=[self.unit(c,line=i,leader=(i==2)) for i in range(3)]
  enemies=[self.unit(c,'A_1001_6',2,line=i,pos=1400) for i in range(3)]
  b=SkillCompleteBattle(allies,enemies,config=c)
  b.a[0]['hp']=0;b.b[1]['hp']=0;o=b.a[2];o['_skill_cd_leader']=-1
  b._add_buff(b.b[2],'stun',1)
  self.assertEqual(b.kaisa_open_lanes(),{2});self.assertEqual(o['_kaisa_casts'],1)
 def test_hunt_purifies_then_shields_all_own_clones_before_free_volley(self):
  b,o,enemies=self.battle();enemies[0]['line']=1;o['_skill_cd_leader']=-1
  clone=b._spawn_summon(o,AID,1,5);clone.update(_kaisa_clone=True,_kaisa_root=o,hp_max=4000,hp=3000)
  other=b._spawn_summon(o,AID,1,5);other.pop('_kaisa_root',None)
  b._add_buff(o,'curse',2);b._add_buff(clone,'burn',2,10)
  original=b._apply_native_skill
  def guarded(actor,opponents,slot):
   if slot=='skill':
    self.assertIsNone(b._buff(o,'curse'));self.assertIsNone(b._buff(clone,'burn'))
    self.assertEqual((b._buff(o,'shield').value,b._buff(o,'shield').round),(60000,3))
    self.assertEqual((b._buff(clone,'shield').value,b._buff(clone,'purify').round),(2400,3))
   return original(actor,opponents,slot)
  b._apply_native_skill=guarded
  b._add_buff(enemies[0],'stun',1)
  self.assertIsNone(b._buff(other,'shield'))
  newest=[u for u in b.a if u.get('_kaisa_root') is o and u is not clone][-1]
  self.assertEqual(b._buff(newest,'shield').value,newest['hp_max']*.6)
 def test_burst_heals_only_triggering_caster_and_caps_at_maximum(self):
  b,o,enemies=self.battle();target=enemies[0];target['hp']=target['hp_max']=10000
  o['hp']=70000
  for _ in range(5):
   with b.context(o,'basic'):b.kaisa_event(o,'hit',o,target)
  self.assertEqual(o['hp'],75000)
  clone=b._spawn_summon(o,AID,1,5);clone.update(_kaisa_clone=True,_kaisa_root=o,hp_max=60000,hp=59000)
  for _ in range(5):
   with b.context(clone,'basic'):b.kaisa_event(clone,'hit',clone,target)
  self.assertEqual(clone['hp'],60000);self.assertEqual(o['hp'],75000)
 def test_four_plasma_assets_and_no_legacy_projectile(self):
  aliases={e['alias'] for e in self.cfg['dragonmancer_kaisa_104']['media']['assets']}
  self.assertTrue({f'MOD_KAISA_PLASMA104_{n}' for n in range(1,5)}<=aliases)
  self.assertEqual(self.cfg['effect']['FX_KAISA_MISSILE104'],{})
  self.assertEqual(self.cfg['skill'][NORMAL]['skill'][0][3],'FX_KAISA_MISSILE104')
if __name__=='__main__':unittest.main()
