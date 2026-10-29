"""Persistent adventure claw draws; all rewards and receipts commit together."""
import copy, random
from gameplay_common import game_day, grant_reward, equipment_exclusive_ids
from player_store import GameplayFault
from mod_policy import hero_available

PRICE=100
TEN_PRICE=PRICE*10*9//10

def draw_cost(num,free):
 return (TEN_PRICE if num==10 else PRICE)-(PRICE if free else 0)

MILESTONES={10:{"coin":500,"culture_book":1000},50:{"attrs":{"dust":[500]*4},"dn_stone":500},100:{"avatar":{"A_1001_6":1},"attrs":{"sp":[300]*6}},300:{"avatar":{"A_1140_6":1},"coin":5000}}

class Zhuabao:
 def __init__(self,economy):
  self.economy=economy;self.store=economy.store;self.cfg=economy.config
  self.groups={"材料":[],"英雄卡":[],"魂魄":[],"装备":[]}
  def add(group,name,gift):self.groups[group].append(dict(name=name,gift=gift))
  for key,name,n in [("gold","金币",100000),("coin","金砖",100),("score","英雄积分",500),("medal","勋章",30),("mark","竞技印记",30),("culture_book","培养书",500),("dn_stone","德诺石",200)]:add("材料",name+"×"+str(n),{key:n})
  for key,name,colors,n in [("dust","附魔粉尘",4,200),("sp","天赋材料",len(self.cfg.get("system_simple",{}).get("talent_config",[])) or 6,100)]:
   for i in range(colors):add("材料",name+str(i+1)+"×"+str(n),{"attrs":{key:[n if j==i else 0 for j in range(colors)]}})
  for key,name,n in [("energy_extra","体力",50),("fragment_energy_extra","碎片能量",10)]:add("材料",name+"×"+str(n),{"attrs":{key:n}})
  for key,name in [("box","宝箱"),("key","钥匙")]:add("材料",name+"×3",{"attrs":{"box_key":{key:3}}})
  for aid,row in sorted(self.cfg.get("avatar",{}).items()):
   if aid.startswith("A_1") and aid.rsplit("_",1)[-1] in {"1","2","3","4","5","6"} and hero_available(self.cfg,aid):
    name=row.get("name",aid)+"（"+aid.rsplit("_",1)[-1]+"星）";add("英雄卡",name+"×1",{"avatar":{aid:1}})
    add("魂魄",name+"魂魄×10",{"avatar_soul":{aid:10}})
  excluded=equipment_exclusive_ids(self.cfg)
  for eid,row in sorted(self.cfg.get("equip",{}).items()):
   if eid not in excluded and int(row.get("type",0)) in (1,3,4,5,6):
    name=row.get("name",eid)+"（"+eid.rsplit("_",1)[-1]+"星）";add("装备",name+"×1",{"equip":{eid:1}});add("魂魄",name+"魂魄×10",{"equip_soul":{eid:10}})
 def state(self,p):
  s=p.setdefault("attrs",{}).setdefault("zhuabao",{"count":0,"claimed":[],"free_day":""})
  if s.get("version")!=2:
   s["total"]=max(0,int(s.get("count",0)));old=s.get("claimed",[])
   s["claimed"]={str(t):int(t in old) for t in MILESTONES};s["version"]=2
  s["count"]=s["total"]%300
  return s
 def info(self,p):
  s=self.state(p);free=s["free_day"]!=game_day(self.store.clock.now())
  return dict(count=s["count"],cycles=s["total"]//300,coin=p.get("coin",0),price=PRICE,ten_cost=draw_cost(10,free),free=free,milestones=[dict(tier=t,gift=g,claimed=s["count"]>=t and s["claimed"].get(str(t),0)>=s["total"]//300+int(s["count"]>=t),claimable=s["total"]//300+int(s["count"]>=t)>s["claimed"].get(str(t),0),pending=max(0,s["total"]//300+int(s["count"]>=t)-s["claimed"].get(str(t),0))) for t,g in MILESTONES.items()],pool=[dict(group=k,name=v["name"]) for k,rows in self.groups.items() for v in rows],summary="材料60% · 英雄卡20% · 魂魄10% · 装备10%")
 def dispatch(self,uid,method,params):
  if method=="user.zhuabao_info":return self.info(copy.deepcopy(self.store.profile_raw(uid)))
  action=params.get("actionID")
  if not isinstance(action,str) or not action:raise GameplayFault("InvalidRequest","缺少操作编号，请重新进入抓宝。")
  draw=method=="user.zhuabao_draw";n=params.get("num",1) if draw else params.get("tier")
  if type(n) is not int or (draw and n not in (1,10)) or (not draw and n not in MILESTONES):raise GameplayFault("InvalidSelection","请选择单抓、十连或有效累计奖励。")
  def mutate(p):
   s=self.state(p);awards=[]
   if draw:
    today=game_day(self.store.clock.now());free=s["free_day"]!=today;cost=draw_cost(n,free)
    if p.get("coin",0)<cost:raise GameplayFault("InsufficientCoin","金砖不足。")
    for _ in range(n):
     group=random.choices(list(self.groups),weights=[60,20,10,10],k=1)[0];entry=random.choice(self.groups[group]);awards.append(copy.deepcopy(entry))
    for entry in awards:grant_reward(p,entry["gift"],{"cfg":self.cfg},allow_skin=True)
    p["coin"]-=cost;self.economy._record_coin_spend(p,cost)
    if free:s["free_day"]=today
    s["total"]+=n;s["count"]=s["total"]%300;self.store.adventure.record_draw(p)
   else:
    available=s["total"]//300+int(s["count"]>=n)
    if s["claimed"].get(str(n),0)>=available:raise GameplayFault("AlreadyClaimed","次数未达到或该奖励已经领取。")
    grant_reward(p,MILESTONES[n],{"cfg":self.cfg},allow_skin=True);s["claimed"][str(n)]=s["claimed"].get(str(n),0)+1
   return p,dict(activity=self.info(p),awards=awards,gift=None if draw else copy.deepcopy(MILESTONES[n]))
  out,replayed=self.store.atomic_update(uid,mutate,method+":"+action,{"num" if draw else "tier":n});out["replayed"]=replayed;return out
