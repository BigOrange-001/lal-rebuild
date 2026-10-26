"""Author the approved 21 ascensions and import their reviewed PNGs."""
from pathlib import Path
import argparse, hashlib, json, shutil, sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'server'))
from mod_effects import validate
from mod_packages import validate_media

def hit(ratio, target='event_target', kind='physical'):
    return dict(type='damage',target=target,attackRatio=ratio,damageType=kind,effect='builtin:effect/FX60_MAGIC' if kind=='magic' else 'builtin:effect/FX60_SLASH')

def heal(ap=0,hp=0,target='self'):
    return dict(type='heal',target=target,attackRatio=ap,maxHpRatio=hp,effect='builtin:effect/FX60_HEAL')

def shield(ap=0,hp=0,target='self'):
    return dict(type='buff',target=target,buff='shield',duration=2,attackRatio=ap,maxHpRatio=hp,effect='builtin:effect/FX60_SHIELD')

def gate(event,**kw):
    return dict(kind='event',event=event,maxPerRound=1,allowChain=False,**kw)

# Conditions are intentionally situational; output coefficients are pre-80%.
# Passives are fixed level 1, valued against the hero's level-10 normal skill.
DESIGNS = [
 (1001,'不屈之心',gate('shield_break',hpBelow=.4,relation='enemy'),[heal(hp=.20),shield(hp=.16)],'自身护盾被敌人击破后，生命不高于40%'),
 (1002,'霜封追猎',gate('hit',otherRequiredBuff='stun',hpBelow=.65,unitType='hero',relation='enemy',minAmount=1),[hit(3.8)],'自身生命不高于65%，命中已眩晕的敌方英雄'),
 (1003,'符文逆涌',gate('skill_cast',hpBelow=.4,nearbyEnemies=2,nearbyRadius=600),[hit(3.2,'lane_front','magic'),heal(ap=1.1)],'自身生命不高于40%，同路600范围内至少有2名敌人，施放主动技能后'),
 (1004,'垂星救赎',gate('heal_done',otherHpBelow=.35,relation='ally',unitType='hero',minAmount=1),[heal(ap=6.0,hp=.06,target='event_target')],'治疗另一名友方英雄后，其生命仍不高于35%'),
 (1005,'真假难辨',gate('dodge',nearbySummons=1,nearbyRadius=350,relation='enemy'),[hit(4.0,'event_source'),shield(hp=.10)],'同路350范围内有友方召唤物时，闪避敌人的攻击'),
 (1006,'救赎和弦',gate('heal_done',otherHpBelow=.4,nearbyAllies=3,nearbyRadius=600,relation='ally',unitType='hero',minAmount=1),[heal(ap=3.0,target='event_target'),shield(hp=.07,target='event_target')],'同路600范围内有至少3名其他友军，治疗另一名友方英雄后其生命仍不高于40%'),
 (1007,'孤军破阵',gate('skill_cast',requiredBuff='strong',hpBelow=.6,nearbyEnemies=3,nearbyRadius=350),[shield(hp=.20),hit(2.5,'lane_front')],'自身生命不高于60%，具有力量增益且同路350范围内至少有3名敌人，施放主动技能后'),
 (1008,'宗师反攻',gate('dodge',requiredBuff='shield',hpBelow=.6,relation='enemy'),[hit(6.0,'event_source','magic'),heal(ap=3.0)],'自身生命不高于60%，保有护盾时闪避敌人的攻击'),
 (1009,'陷阵不退',gate('hit',otherRequiredBuff='stun',hpBelow=.45,relation='enemy',unitType='hero',minAmount=1),[heal(ap=4.0,hp=.14),shield(hp=.12)],'自身生命不高于45%，命中已眩晕的敌方英雄'),
 (1010,'浴血收割',gate('kill',requiredBuff='steel',hpBelow=.5,unitType='hero',relation='enemy'),[heal(ap=3.0),hit(4.0,'lane_front','magic')],'自身生命不高于50%，具有双抗增益时击杀敌方英雄'),
 (1011,'绝境烈酒',gate('healed',hpBelow=.4,relation='self',minAmount=1),[shield(hp=.12),hit(3.4,'lane_front')],'自身治疗自己后，生命仍不高于40%'),
 (1012,'无极续战',gate('kill',requiredBuff='strong',nearbyEnemies=2,nearbyRadius=600,unitType='hero',relation='enemy'),[heal(ap=4.0),shield(ap=5.0)],'具有力量增益时击杀敌方英雄，且同路600范围内仍有至少2名存活敌人'),
 (1013,'应急屏障',gate('damage_taken',hpBelow=.25,absentBuff='shield',relation='enemy',minAmount=1),[shield(hp=.30)],'受到敌人伤害后，生命不高于25%且没有护盾'),
 (1014,'备用炮台协议',gate('skill_cast',nearbySummons=2,nearbyEnemies=2,nearbyRadius=600),[dict(type='summon',target='self',unit='builtin:hero/A_2001_4',statRatio=1.0,lifetime=2,maxAlive=1,effect='builtin:effect/SUMMON_EFF')],'施放主动技能后，同路600范围内至少有2个友方召唤物和2名敌人'),
 (1015,'烟中返刃',gate('dodge',requiredBuff='steel',nearbyEnemies=2,nearbyRadius=500,relation='enemy'),[hit(3.8,'event_source','magic'),heal(ap=.8)],'具有双抗增益、同路500范围内至少有2名敌人时，闪避敌人的攻击'),
 (1016,'雷印共鸣',gate('hit',otherRequiredBuff='stun',nearbyEnemies=3,nearbyRadius=600,relation='enemy',minAmount=1),[hit(2.5,'event_target','magic'),dict(type='damage',target='enemy_radius',centerAction=0,radius=200,excludeCenter=True,attackRatio=.65,damageType='magic',effect='builtin:effect/FX60_MAGIC')],'同路600范围内至少有3名敌人，命中已眩晕的敌人'),
 (1017,'破盾反击',gate('shield_break',nearbyEnemies=2,nearbyRadius=350,relation='enemy'),[hit(5.0,'event_source'),dict(type='buff',target='event_source',buff='stun',duration=1,effect='builtin:effect/FX60_STUN')],'同路350范围内至少有2名敌人时，自身护盾被敌人击破'),
 (1018,'舍身佑护',gate('damage_taken',requiredBuff='taunt',hpBelow=.35,nearbyAllies=1,nearbyRadius=350,relation='enemy',minAmount=1),[dict(**shield(ap=2.0,hp=.04,target='ally_radius'),radius=350)],'自身处于嘲讽状态，受到敌人伤害后生命不高于35%，同路350范围内有其他友军'),
 (1019,'血战不息',gate('kill',requiredBuff='strong',hpBelow=.5,unitType='hero',relation='enemy'),[heal(hp=.22),shield(hp=.08)],'自身生命不高于50%，具有力量增益时击杀敌方英雄'),
 (1020,'日冕坚守',gate('damage_taken',requiredBuff='steel',hpBelow=.5,nearbyEnemies=3,nearbyRadius=350,relation='enemy',minAmount=1),[shield(hp=.25),dict(type='buff',target='event_source',buff='stun',duration=1,effect='builtin:effect/FX60_STUN')],'自身具有双抗增益且生命不高于50%，在同路350范围内至少3名敌人包围下受到伤害'),
 (1021,'秘术超频',gate('hit',otherHpBelow=.35,everyEvents=3,relation='enemy',unitType='hero',minAmount=1),[hit(5.0,'event_target','magic')],'累计3次命中结算后生命不高于35%的敌方英雄'),
]

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--art',type=Path,required=True);args=parser.parse_args()
    directory=ROOT/'config/reconstruction/orange-ascension-media';directory.mkdir(exist_ok=True)
    entries=[];heroes=[]
    for ident,name,trigger,actions,condition in DESIGNS:
        aid=f'A_{ident}_6';parts=[]
        for i,action in enumerate(actions):
            who={'self':'自身','event_target':'该目标','event_source':'攻击者','lane_front':'本路前排敌人','enemy_radius':'目标周围其他敌人','ally_radius':'同路范围内友军'}.get(action['target'],'自身')
            values=[]
            if action.get('attackRatio'):values.append('{rank:%d:5}攻击力'%i)
            if action.get('maxHpRatio'):values.append('{rank:%d:6}自身生命上限'%i)
            value='+'.join(values)
            kind=action['type']
            if kind=='damage':parts.append('对'+who+'造成'+value+('魔法' if action['damageType']=='magic' else '物理')+'伤害')
            elif kind=='heal':parts.append('为'+who+'恢复'+value+'生命')
            elif kind=='buff' and action['buff']=='shield':parts.append('为'+who+'提供'+value+'护盾，持续2回合')
            elif kind=='buff':parts.append('眩晕'+who+'1回合')
            else:parts.append('额外部署1座继承自身100%面板的炮台，存在2次自身行动，同一被动最多保留1座')
        text=condition+'：'+'；'.join(parts)+'。准备0，冷却1；每回合最多触发一次，被动不连锁触发。'
        passive=dict(id=f'ascend_{ident}',name=name,description=text,rankInfoTemplate=text,model='effect-sequence-v1',warmup=0,cooldown=1,range=9999,trigger=trigger,actions=actions,maxLevel=1)
        validate(passive)
        heroes.append(dict(id=aid,source=f'A_{ident}_5',passive=passive))
        for folder,role,alias in [('portraits','portrait','MOD_ASC104_'+aid),('cards','icon','MOD_ASC104_'+aid+'_icon0000')]:
            file=directory/folder/(aid+'.png');file.parent.mkdir(exist_ok=True)
            shutil.copyfile(args.art/folder/file.name,file)
            raw=file.read_bytes();meta=validate_media(raw,file.name)
            entry=dict(alias=alias,kind='image',path=f'{folder}/{file.name}',sha256=hashlib.sha256(raw).hexdigest(),bytes=len(raw),width=meta['width'],height=meta['height'],role=role,packageId='builtin.orange-ascension-104',version='1.0.4')
            if role=='icon':entry['cardFrame']=meta['cardFrame']
            entries.append(entry)
    digest=hashlib.sha256(json.dumps(entries,sort_keys=True).encode()).hexdigest()
    for entry in entries:entry['contentDigest']=digest
    (directory/'manifest.json').write_text(json.dumps(dict(digest=digest,assets=entries),ensure_ascii=False,indent=2),'utf-8')
    (directory.parent/'orange-ascension-1.0.4.json').write_text(json.dumps(dict(schema='orange-ascension-1.0.4-v1',heroes=heroes),ensure_ascii=False,indent=2),'utf-8')
    print('Authored 21 ascensions and imported 42 verified images:',digest)

if __name__=='__main__':main()
