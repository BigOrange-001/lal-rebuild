"""Persistent adventure claw draws; all rewards and receipts commit together."""
import copy, random
from gameplay_common import game_day, grant_reward, equipment_exclusive_ids
from player_store import GameplayFault
from summon_pools import SummonPools

PRICE=100
TEN_PRICE=PRICE*10*9//10
GROUP_WEIGHTS = [10, 30, 20, 38, 2]
SUMMARY = '英雄10% · 英雄魂魄30%（60片） · 装备20%（蓝14%/紫5%/橙1%） · 养成38% · 金砖2%'


def material_pool(cfg):
 """One offer per material dungeon: 30% of its final-tier reward bundle."""
 latest={}
 for cid,stage in cfg.get('combat_ploy',{}).items():
  kind=stage.get('material_kind')
  if stage.get('activity_kind')!='material' or kind in (None,'ancient_trial'):continue
  tier=int(stage.get('material_tier',0))
  if kind not in latest or tier>latest[kind][0]:latest[kind]=(tier,cid,stage)
 def scale(value):
  if isinstance(value,dict):return {k:(v if k in ('aid','eid') else scale(v)) for k,v in value.items()}
  if isinstance(value,list):return [scale(v) for v in value]
  if type(value) is int:return (value*3+9)//10 if value>0 else 0
  return value
 rows=[]
 for kind,(_,cid,stage) in sorted(latest.items()):
  reward=scale(stage.get('reward',{}))
  if not reward:raise GameplayFault('InvalidConfig','养成副本缺少掉落配置')
  rows.append(dict(name=stage.get('name',kind)+'养成奖励',gift=reward,source_stage=cid))
 if not rows:raise GameplayFault('InvalidConfig','抓宝养成奖池为空')
 return rows

def draw_cost(num,free):
 return (TEN_PRICE if num==10 else PRICE)-(PRICE if free else 0)

MILESTONES={10:{"coin":500,"culture_book":1000},50:{"attrs":{"dust":[500]*4},"dn_stone":500},100:{"avatar":{"A_1001_6":1},"attrs":{"sp":[300]*6}},300:{"avatar":{"A_1140_6":1},"coin":5000}}

class Zhuabao:
 def __init__(self,economy):
  self.economy=economy;self.store=economy.store;self.cfg=economy.config
  self.groups={"英雄卡":[],"魂魄":[],"装备":[],"材料":[],"金砖":[]}
  self.summon_pools=SummonPools.from_config(self.cfg)
  if self.summon_pools is None:raise GameplayFault('InvalidConfig','抓宝需要VIP校准奖池')
  self.equipment_pools={q:[] for q in (4,5,6)}
  def add(group,name,gift):self.groups[group].append(dict(name=name,gift=gift))
  self.groups['材料']=material_pool(self.cfg)
  add('金砖','100金砖',{'coin':100});add('金砖','1000金砖',{'coin':1000})
  vip_ids={aid for (pool,quality),(rows,_) in self.summon_pools._cards.items() if pool=='vip'
           and any(q==quality for q,_ in self.summon_pools._qualities['vip'][0]) for aid,_ in rows}
  for aid in sorted(vip_ids):
   row=self.cfg['avatar'][aid];name=row.get('name',aid)+'（'+aid.rsplit('_',1)[-1]+'星）'
   add('英雄卡',name+'×1',{'avatar':{aid:1}})
   add('魂魄',name+'魂魄×60',{'avatar_soul':{aid:60}})
  excluded=equipment_exclusive_ids(self.cfg)
  for eid,row in sorted(self.cfg.get("equip",{}).items()):
   if eid not in excluded and int(row.get('type',0)) in (1,3,4,5,6) and row.get('quality') in self.equipment_pools:
    name=row.get('name',eid)+'（'+eid.rsplit('_',1)[-1]+'星）'
    entry=dict(name=name+'×1',gift={'equip':{eid:1}})
    self.groups['装备'].append(entry);self.equipment_pools[row['quality']].append(entry)
  if any(not rows for rows in self.equipment_pools.values()):raise GameplayFault('InvalidConfig','抓宝装备奖池为空')
 def draw_entry(self):
  group=random.choices(list(self.groups),weights=GROUP_WEIGHTS,k=1)[0]
  if group in ('英雄卡','魂魄'):
   aid=self.summon_pools.draw('vip',random);name=self.cfg['avatar'][aid].get('name',aid)
   return dict(name=name+('魂魄×60' if group=='魂魄' else '×1'),gift={'avatar_soul':{aid:60}} if group=='魂魄' else {'avatar':{aid:1}})
  if group=='装备':
   quality=random.choices([4,5,6],weights=[14,5,1],k=1)[0]
   return random.choice(self.equipment_pools[quality])
  if group=='金砖':return random.choices(self.groups[group],weights=[19,1],k=1)[0]
  return random.choice(self.groups[group])
 def state(self,p):
  s=p.setdefault("attrs",{}).setdefault("zhuabao",{"count":0,"claimed":[],"free_day":""})
  if s.get("version")!=2:
   s["total"]=max(0,int(s.get("count",0)));old=s.get("claimed",[])
   s["claimed"]={str(t):int(t in old) for t in MILESTONES};s["version"]=2
  s["count"]=s["total"]%300
  return s
 def info(self,p):
  s=self.state(p);free=s["free_day"]!=game_day(self.store.clock.now())
  return dict(count=s["count"],cycles=s["total"]//300,coin=p.get("coin",0),price=PRICE,ten_cost=draw_cost(10,free),free=free,milestones=[dict(tier=t,gift=g,claimed=s["count"]>=t and s["claimed"].get(str(t),0)>=s["total"]//300+int(s["count"]>=t),claimable=s["total"]//300+int(s["count"]>=t)>s["claimed"].get(str(t),0),pending=max(0,s["total"]//300+int(s["count"]>=t)-s["claimed"].get(str(t),0))) for t,g in MILESTONES.items()],pool=[dict(group=k,name=v["name"]) for k,rows in self.groups.items() for v in rows],summary=SUMMARY)
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
     entry=self.draw_entry();awards.append(copy.deepcopy(entry))
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
