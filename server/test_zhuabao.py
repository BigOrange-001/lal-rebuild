import copy,unittest
from pathlib import Path
from unittest.mock import patch
from gateway import Backend
from zhuabao import Zhuabao,MILESTONES
from gameplay_common import grant_reward
from player_store import GameplayFault

class ZhuabaoTests(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.b=Backend(":memory:",Path(__file__).resolve().parents[1]/"config/reconstruction/full-config.json")
 @classmethod
 def tearDownClass(cls):cls.b.clock.close();cls.b.db.close()
 def setUp(self):
  self.uid=self.b.players.login(self.id())["uid"];self.z=Zhuabao(self.b.players.economy)
  def seed(p):p["coin"]=100000;return p,{}
  self.b.players.atomic_update(self.uid,seed)
 def call(self,kind,**params):return self.z.dispatch(self.uid,"user.zhuabao_"+kind,dict(actionID=kind,**params))
 def test_ten_draw_free_discount_and_replay(self):
  with patch("zhuabao.random.choices",return_value=["材料"]),patch("zhuabao.random.choice",return_value=dict(name="金币",gift={"gold":10})):
   r=self.call("draw",num=10);again=self.call("draw",num=10)
  self.assertEqual(len(r["awards"]),10);self.assertEqual(r["activity"]["coin"],99200);self.assertEqual(again["activity"]["count"],10);self.assertTrue(again["replayed"])
  self.assertEqual(self.z.info(self.b.players.profile_raw(self.uid))["count"],10)
  with self.assertRaises(GameplayFault):self.call("draw",num=1)
 def test_ten_draw_nine_tenths_price_matches_quote_and_single_stays_100(self):
  with patch("zhuabao.random.choices",return_value=["材料"]),patch("zhuabao.random.choice",return_value=dict(name="金币",gift={"gold":10})):
   self.assertEqual(self.z.info(self.b.players.profile_raw(self.uid))["ten_cost"],800)
   self.call("draw",num=1)
   self.assertEqual(self.z.info(self.b.players.profile_raw(self.uid))["ten_cost"],900)
   r=self.z.dispatch(self.uid,"user.zhuabao_draw",dict(actionID="paid-ten",num=10))
   self.assertEqual(r["activity"]["coin"],99100)
   r=self.z.dispatch(self.uid,"user.zhuabao_draw",dict(actionID="paid-one",num=1))
   self.assertEqual(r["activity"]["coin"],99000)
  self.assertEqual(r["activity"]["count"],12)
 def test_insufficient_coin_and_full_inventory_rollback(self):
  def seed(p):p["coin"]=0;p["attrs"]["zhuabao"]={"count":0,"claimed":[],"free_day":""};return p,{}
  self.b.players.atomic_update(self.uid,seed);before=self.b.players.profile_raw(self.uid)
  with self.assertRaises(GameplayFault):self.call("draw",num=10)
  self.assertEqual(before,self.b.players.profile_raw(self.uid))
  def full(p):p["coin"]=10000;p["attrs"]["avatar_len"]=len(p["avatars"]);return p,{}
  self.b.players.atomic_update(self.uid,full);before=self.b.players.profile_raw(self.uid)
  with patch("zhuabao.random.choices",return_value=["英雄卡"]):
   with self.assertRaises(GameplayFault):self.call("draw",num=1)
  self.assertEqual(before,self.b.players.profile_raw(self.uid))
 def test_milestone_one_time_per_cycle(self):
  with self.assertRaises(GameplayFault):self.call("claim",tier=10)
  def seed(p):p["attrs"]["zhuabao"]={"count":300,"claimed":[],"free_day":""};return p,{}
  self.b.players.atomic_update(self.uid,seed)
  for tier in MILESTONES:
   self.z.dispatch(self.uid,"user.zhuabao_claim",dict(actionID=str(tier),tier=tier))
   with self.assertRaises(GameplayFault):self.z.dispatch(self.uid,"user.zhuabao_claim",dict(actionID="again"+str(tier),tier=tier))
  self.assertEqual(self.z.info(self.b.players.profile_raw(self.uid))["count"],0)
 def test_100_and_300_milestones_grant_a_random_orange(self):
  from zhuabao import SKIN_PERCENT
  self.assertEqual(SKIN_PERCENT,{100:10,300:50})
  pools=self.b.players.economy._simple("vip_daily_pack_pools_105",{})
  def seed(p):p["attrs"]["zhuabao"]={"count":300,"claimed":[],"free_day":""};return p,{}
  self.b.players.atomic_update(self.uid,seed)
  for tier,extra in ((100,"attrs"),(300,"coin")):
   gift=self.z.dispatch(self.uid,"user.zhuabao_claim",dict(actionID="orange"+str(tier),tier=tier))["gift"]
   self.assertNotIn("random_orange_hero",gift);self.assertIn(extra,gift)
   (aid,num),=gift["avatar"].items();self.assertEqual(num,1)
   self.assertIn(aid,pools["ordinary_orange"]+pools["skin_orange"])
   owned=self.b.players.profile_raw(self.uid)["avatars"].values()
   self.assertTrue(any(isinstance(h,dict) and str(h.get("aid","")).startswith(aid) for h in owned),aid)
 def test_milestone_skin_chance_follows_the_percent(self):
  pools=self.b.players.economy._simple("vip_daily_pack_pools_105",{})
  class Rng:
   def __init__(self,ticket):self.ticket=ticket
   def randrange(self,n):return self.ticket
   def choice(self,rows):return rows[0]
  pick=self.b.players.economy.random_orange_hero
  for percent in (10,50):
   self.assertIn(pick(percent,Rng(percent//10-1)),pools["skin_orange"])
   self.assertIn(pick(percent,Rng(percent//10)),pools["ordinary_orange"])
 def test_cross_cycle_ten_draw_preserves_all_pending_rewards(self):
  def seed(p):p["attrs"]["zhuabao"]={"count":295,"claimed":[10,50,100,200],"free_day":""};return p,{}
  self.b.players.atomic_update(self.uid,seed)
  with patch("zhuabao.random.choices",return_value=["材料"]),patch("zhuabao.random.choice",return_value=dict(name="金币",gift={"gold":10})):
   r=self.call("draw",num=10)
  self.assertEqual(r["activity"]["count"],5);self.assertEqual(r["activity"]["cycles"],1)
  ready={m["tier"]:m["pending"] for m in r["activity"]["milestones"]}
  self.assertEqual(ready,{10:0,50:0,100:0,300:1})
  self.call("claim",tier=300)
  def seed2(p):p["attrs"]["zhuabao"]["total"]=610;return p,{}
  self.b.players.atomic_update(self.uid,seed2)
  ready={m["tier"]:m["pending"] for m in self.z.info(self.b.players.profile_raw(self.uid))["milestones"]}
  self.assertEqual(ready,{10:2,50:1,100:1,300:1})
 def test_removed_200_milestone_is_not_shown_or_claimable(self):
  self.assertEqual([m['tier'] for m in self.z.info(self.b.players.profile_raw(self.uid))['milestones']],[10,50,100,300])
  before=self.b.players.profile_raw(self.uid)
  with self.assertRaises(GameplayFault):self.call('claim',tier=200)
  self.assertEqual(self.b.players.profile_raw(self.uid),before)
 def test_entire_pool_is_grantable_and_excludes_npcs(self):
  p=self.b.players.profile_raw(self.uid)
  self.assertGreater(len(self.z.groups["英雄卡"]),100)
  self.assertTrue(any("A_1140_6" in r["gift"]["avatar"] for r in self.z.groups["英雄卡"]))
  for group,rows in self.z.groups.items():
   self.assertTrue(rows,group)
   for row in rows:grant_reward(copy.deepcopy(p),row["gift"],{"cfg":self.z.cfg},allow_skin=True)
 def test_invalid_inputs_and_methods_route(self):
  for n in (True,1.5,"10",0,11,-1):
   with self.assertRaises(GameplayFault):self.call("draw",num=n)
  self.assertIn("pool",self.b.players.economy.dispatch(self.uid,"user.zhuabao_info",{}))

if __name__=="__main__":unittest.main()
