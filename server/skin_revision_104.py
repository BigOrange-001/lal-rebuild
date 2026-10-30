"""Approved second skin draft. Coefficients are authored as final output values."""
import copy
import json
import re
from pathlib import Path

PLAN=Path(__file__).resolve().parents[1]/'config/reconstruction/skin-revision-v2-1.0.4.json'
# Values here are output coefficients, never durations, target counts or buffs.
PARAMS={
1201:({'hit':2.6,'shield':1.4},{'hit':3.2},{'shield':1.8}),
1203:({'hit':2.2,'heal':1},{'hit':3.6,'hpShield':.15},{}),
1204:({'hit':3.6},{'hit':3.6,'shield':2.8},{'shield':2.2,'heal':1.8}),
1206:({'hit':1},{'hit':1.3},{'hit':1.6,'heal':.8}),
1207:({'hit':2.5,'heal':2.2},{'hit':5.2},{'hit':2,'heal':1.8,'overflow':.5}),
1209:({'hit':2,'poison':.5},{},{'hit':1.8,'shield':1}),
1210:({'hit':1,'third':1.2},{'entry':2.4,'exit':3.6},{'shield':2,'leech':.35}),
1211:({'hit':2.8},{'hit':6.5},{'hit':2.2}),
1213:({'hit':2.2,'shield':1.2},{'hit':4.2,'shot':2.4},{'hit':1.4,'heal':1}),
1214:({'hit':2.6},{'hit':3.6,'bonus':1.8},{'shield':1.6,'stealCap':3}),
1215:({'first':1.8,'second':2.6},{'hit':4.5,'collision':2.2},{'shield':1.8}),
1216:({'hit':1.8,'cold':2.4},{'hit':2},{'hit':2}),
1218:({'hit':3,'leech':.35},{'hit':2.4},{'entry':3.6,'shield':2.4}),
1219:({'hit':2.4,'wind':2},{'hit':1.8},{'shield':2.2}),
1221:({'hit':2.2,'splash':1},{'hit':2},{'command':.8,'shield':1.2}),
1228:({'heal':2.8,'shield':2},{'hit':3.6},{}),
1227:({}, {'hit':4.2,'heal':1.8,'snake':2,'shield':1.6},{}),
1140:({'hit':1.4},{'hit':3.8,'phase':1.2,'rewind':.6},{'hit':1.8,'shield':1}),
}

def apply_skin_revision_104(document):
 cfg=document.get('cfg',document)
 if cfg.get('skin_revision_v2_104'):return
 plans=json.loads(PLAN.read_text('utf8'))
 changed=[]
 for aid,h in cfg['avatar'].items():
  family=int(aid.split('_')[1]);quality=int(aid.rsplit('_',1)[1])
  if family not in PARAMS or family==1140 and quality!=6:continue
  if family==1140:
   h['name']='艾克';h['hero_category_104']='skin'
   # Existing skin assassin panel, preserving Ekko's art, speed and range.
   h['pl'][:8]=copy.deepcopy(cfg['avatar']['A_1223_6']['pl'][:8])
   skins=cfg['system_simple'].setdefault('skin_hero_ids',[])
   if aid not in skins:skins.append(aid)
   norm=cfg.get('summon_calibration',{}).get('normalization',{})
   norm['skin_hero_ids']=sorted(set(norm.get('skin_hero_ids',[])+[aid]))
  h['skin_revision_v2_104']=family
  h['pl'] += [None]*max(0,14-len(h['pl']))
  for n,slot in enumerate((10,11,13)):
   if family==1227 and slot!=11:continue
   spec=plans[str(family)][n];old=cfg['skill'].get(h['pl'][slot],{})
   sid=f'S_985{family}{slot}_{quality}'
   values=PARAMS[family][n];keys=list(values)
   action=['manual_ability',f'skin2_{family}_{n}',1,'FX60_MAGIC']+[v/.8*(.5 if n==0 else 1) for v in values.values()]
   text=spec['text']
   # Bind AP coefficients to the actual level and chosen bond/equipment variant.
   for key,value in values.items():
    if key in ('overflow','leech','rewind','hpShield'):continue
    number=f'{value*100:g}'
    text=re.sub(r'(?<![\d.])'+re.escape(number)+r'%((?:本人|安妮|主人)?攻击)',f'{{rank:0:{4+keys.index(key)}}}'+r'\1',text)
   row=dict(id=sid,name=spec['name'],res=old.get('res',old.get('id','S_9004_6')),
    pl=[spec['warmup'],spec['cooldown'],3001,0,0,0],skill=[action],
    skillUp=[[0,4+i,v/.8*.5/9] for i,v in enumerate(values.values())] if n==0 else None,
    info=text,rankInfoTemplate=text,calibration_104=True,skin_revision_v2_104=family,skin_v2_keys=keys,
    actionTargetPolicies=['ally_self'],actionTargetMaxTargets=[1])
   if family==1221 and slot==11:
    row['skin_v2_summon_id']='A_2020_6'
   cfg['skill'][sid]=row;h['pl'][slot]=sid
  if family!=1227:h['skill_diff']=20
  changed.append(aid)
 # Keep catalogue displays and skin draw weights consistent with the identity.
 calibration=cfg.get('summon_calibration',{})
 advanced={x['id']:x['weight'] for x in calibration.get('pools',{}).get('advanced',{}).get('qualities',{}).get('orange',{}).get('cards',[])}
 for name,pool in calibration.get('pools',{}).items():
  cards=pool.get('qualities',{}).get('orange',{}).get('cards',[])
  if name in ('advanced','vip') and not any(x['id']=='A_1140_6' for x in cards):
   reference=next(x for x in cards if x['id']=='A_1219_6')
   card=copy.deepcopy(reference);card.update(id='A_1140_6',name='艾克');cards.append(card)
  for q in pool.get('qualities',{}).values():
   for card in q.get('cards',[]):
    if card['id']=='A_1140_6':
     card['name']='艾克'
     if name=='vip' and card['id'] in advanced:card['weight']=advanced[card['id']]*calibration['normalization']['vip_orange_skin_weight_multiplier']
 if calibration:
  cfg['ploy_system_simple']['extract_avatar']['activity_pool']=[{'kind':'avatar','aid':c['id'],'weight':c['weight']} for q in calibration['pools']['vip']['qualities'].values() if q['probability_percent']>0 for c in q['cards']]
 cfg['avatar']['A_2020_6']['name']='新年提伯斯'
 cfg['avatar']['A_2020_6']['modUnitType']='summon'
 cfg['skin_revision_v2_104']={'heroes':changed}

def update_bond_mechanism(row,bond,slot):
 """Re-author focused mechanisms on the new kit, never restore the old kit."""
 row['skin_v2_bond']=bond['id']
 row['skin_v2_bond_size']=len(bond['families'])
 # Extra effects use explicit active-slot metadata; passive mechanics stay intact.
 family=row['skin_revision_v2_104']
 notes={10:{1201:'施放后为本路生命比例最低的另一名友军提供120.0%攻击护盾2回合。',1206:'小技能额外射出一箭，同样积累心印。',1210:'第三段完成后净化自身并获得120.0%攻击护盾2回合。',1211:'射击后驱散目标的一个增益。',1213:'传球时为持球友军提供120.0%攻击护盾2回合。',1221:'提伯斯的指令攻击额外溅射本路另一敌人。'}.get(family,'施放后获得120.0%攻击护盾2回合。')}
 if family==1219:
  if slot==10:
   row['info']=row['rankInfoTemplate']='对本路敌人造成{rank:0:4}攻击物伤并施加风标。已有风标的目标被击飞1回合。自身获得220.0%攻击护盾2回合。'
  else:
   row['info']=row['rankInfoTemplate']='对本路所有带风标或被击飞的敌人连续斩击3次，每次造成{rank:0:4}攻击物伤。每完成一轮斩击，恢复80.0%攻击生命。'
  row['name']=bond['mechanism']['normal' if slot==10 else 'captain']['name']
  return
 row['info']+='\n'+notes[slot];row['rankInfoTemplate']+='\n'+notes[slot]
 row['name']=bond['mechanism']['normal' if slot==10 else 'captain']['name']

def update_equipment(cfg,plan):
 """Specific components of the new skills; retain each hero's wearable pair."""
 # Old tiny shields were overwritten by the new kit's larger shields. Give
 # these exclusives a real additional effect, without changing other owners.
 extras=[]
 exclusive_changes={
  'A_1210_6':('E_1011_6',['heal_ap',.9, 'FX60_HEAL'],'ally_self','折翼舞步施放后恢复72%攻击生命。'),
  'A_1201_6':('E_1023_6',['heal_ap',1,'FX60_HEAL'],'ally_self','金狮突击施放后恢复80%攻击生命。'),
  'A_1213_6':('E_1026_6',['heal_ap',.8,'FX60_HEAL'],'ally_lane_lowest_hp_ratio_hero','弧线传射施放后，为本路生命比例最低的友方英雄恢复64%攻击生命。'),
  'A_1221_6':('E_1028_6',['purify',1,'FX60_PURIFY'],'ally_self','迎春爆竹施放后，净化自身1回合。'),
 }
 for aid,(eid,action,policy,info) in exclusive_changes.items():
  entry=next((e for e in plan['exclusive'] if e['equipment']==eid and aid in e['heroes']),None)
  if not entry:continue
  if len(entry['heroes'])>1:
   entry['heroes'].remove(aid);entry=copy.deepcopy(entry);entry['heroes']=[aid];extras.append(entry)
  entry.update(action=action,policy=policy,info=info)
 for e in plan['exclusive']:
  if e['equipment']=='E_1018_6':e['action'][0]='steel'
 plan['exclusive'].extend(extras)
 for aid,entry in plan['heroes'].items():
  h=cfg['avatar'][aid]
  if not h.get('skin_revision_v2_104'):continue
  family=h['skin_revision_v2_104']
  # Each value identifies a particular effect, not an all-output multiplier.
  picks={1201:[(10,'hit'),(10,'shield')],1203:[(10,'hit'),(11,'hpShield')],1204:[(10,'hit'),(11,'shield')],1206:[(10,'hit'),(11,'hit')],1207:[(11,'hit'),(10,'heal')],1209:[(10,'hit'),(10,'poison')],1210:[(10,'third'),(11,'exit')],1211:[(11,'hit'),(10,'hit')],1213:[(11,'shot'),(10,'shield')],1214:[(11,'bonus'),(10,'hit')],1215:[(10,'second'),(11,'collision')],1216:[(10,'cold'),(11,'hit')],1218:[(10,'hit'),(10,'leech')],1219:[(11,'hit'),(10,'wind')],1221:[(10,'hit'),(11,'hit')],1227:[(11,'snake'),(11,'shield')],1228:[(11,'hit'),(10,'heal')],1140:[(10,'hit'),(11,'rewind')]}[family]
  for affinity,(slot,key) in zip(entry['affinities'],picks):
   row=cfg['skill'][h['pl'][slot]];keys=row['skin_v2_keys'];i=keys.index(key)+4
   # Three-target average for lane output, HP/AP=10 for HP-based parts.
   values=PARAMS[family][(10,11,13).index(slot)]
   weights={k:v*(10 if k in ('hpShield','rewind') else 1) for k,v in values.items()}
   share=weights[key]/sum(weights.values());budget=.12 if cfg['equip'][affinity['equipment']]['quality']==5 else .08
   label={'hit':'主段伤害','third':'第三段伤害','wind':'旋风伤害','exit':'结束剑气','second':'回响追击','collision':'碰撞伤害','shot':'射门补伤','snake':'覆水伤害','cold':'寒冷目标伤害','bonus':'驱散追加真伤','shield':'护盾','hpShield':'生命护盾','heal':'治疗','leech':'吸血比例','rewind':'回溯恢复比例','poison':'中毒伤害'}[key]
   affinity.update(slot='normal' if slot==10 else 'captain',index=0,path=[i],signature=['manual_ability'],strength=budget/share,benefit_share=share,benefit_curve=1,skill_name=row['name'],part=label,review_source_104=True,
     info=f'{row["name"]}的{label}提高{budget/share*100:.1f}%。')
   affinity['reworks']={};affinity.pop('manual_kind',None)

def refresh_bond_copy(cfg):
 from native_skill_snapshot import _native_skill_snapshot
 for bond in cfg['system_simple'].get('bonds_104',[]):
  focus=bond.get('focus');aid=str(focus)+'_6';hero=cfg['avatar'].get(aid,{})
  if not hero.get('skin_revision_v2_104'):continue
  bindings=cfg['system_simple']['bond_skill_variants_104'][aid].get(bond['id'],{})
  for name,slot,level in [('normal','skill',10),('captain','leader_skill',1)]:
   if name not in bond.get('mechanism',{}) or slot not in bindings:continue
   row=cfg['skill'][bindings[slot]];snap=_native_skill_snapshot(cfg,bindings[slot],level)
   def token(m):
    value=snap['skills'][int(m[1])]
    for i in m[2].split('.'):value=value[int(i)]
    return f'{value*100:.1f}%'
   bond['mechanism'][name]['info']=re.sub(r'\{rank:(\d+):([\d.]+)\}',token,row.get('rankInfoTemplate',row['info']))
