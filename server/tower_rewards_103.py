"""Soul-tower rewards linked to the reviewed advanced/VIP summon weights."""
from __future__ import annotations
import copy
import random
import re
from player_store import GameplayFault
from summon_pools import SummonPools,QUALITY_IDS
from mod_policy import base_aid,hero_available,hero_metadata,new_heroes

SCHEMA='tower-rewards-1.0.3-v2'
MAX_FLOOR=180
EXTENSION_START=150
FINAL_POWER=50_000_000_000
QUALITY_NAMES={2:'白',3:'绿',4:'蓝',5:'紫',6:'橙'}

def _enemy_pools(cfg):
    skins=set(cfg['system_simple'].get('skin_hero_ids',[]))
    pools={key:[] for key in ('skin_orange','orange','purple')}
    # Scoped aliases are definitions of the same hero, not extra lottery tickets.
    # Mod summons share the A_1 prefix with heroes, so identity alone is unsafe.
    candidates={base_aid(cfg,aid) for aid in cfg['avatar']
                if re.fullmatch(r'A_1\d{3}_[56]',base_aid(cfg,aid))}
    candidates.update(new_heroes(cfg))
    for aid in sorted(candidates):
        if not hero_available(cfg,aid):continue
        if (hero_metadata(cfg,aid).get('unitType','hero')!='hero'
                or cfg['avatar'][aid].get('modUnitType','hero')!='hero'):continue
        if aid.endswith('_6'):pools['skin_orange' if aid in skins else 'orange'].append(aid)
        elif aid.endswith('_5'):pools['purple'].append(aid)
    if any(not pool for pool in pools.values()):
        raise GameplayFault('InvalidConfig','Tower requires skin orange, ordinary orange and purple heroes')
    return pools

def _enemy_team(cfg,rng):
    pools=_enemy_pools(cfg)
    aids=[rng.choice(pools['skin_orange'])]
    for _ in range(8):
        ticket=rng.randrange(100)
        group='skin_orange' if ticket<40 else 'orange' if ticket<70 else 'purple'
        aids.append(rng.choice(pools[group]))
    team=[]
    for i,aid in enumerate(aids):
        quality=aid.rsplit('_',1)[1]
        cap=int(cfg['system_simple']['phase_config'][0][quality][1])
        team.append([aid,125,10,i//3,(.44,.28,.12)[i%3],int(i==0),0,0,'',
                     None,None,(1,0,-1)[i%3]/3,None,1,cap])
    return team

def roll_tower_encounter(cfg,stage,rng):
    """Bind random enemies and their fitted attributes to one fight intent."""
    from activity_tower_overlay import _base_stats
    from campaign_workbook_overlay import _fit_power
    stage=copy.deepcopy(stage)
    team=_enemy_team(cfg,rng)
    target=int(stage['tower_enemy_rule']['target_power'])
    stats,actual=_fit_power(cfg,team,_base_stats(cfg,team),target)
    stage.update(team2=team,enemy_unit_stats_by_diff={'0':stats},
                 recommended_power=actual,recommended_power_by_diff={'0':actual},
                 enemy_snapshot_power=actual)
    return stage

def _extend_tower(cfg,stages):
    anchor=int(stages[f'P_200_{EXTENSION_START}']['recommended_power'])
    for floor in range(EXTENSION_START+1,MAX_FLOOR+1):
        stage=copy.deepcopy(stages[f'P_200_{EXTENSION_START}'])
        target=round(anchor*(FINAL_POWER/anchor)**((floor-EXTENSION_START)/(MAX_FLOOR-EXTENSION_START)))
        stage.update(id=f'P_200_{floor}',name=f'灵魂塔·第{floor}层',tower_floor=floor,
                     tower_tier=7,index=floor,indexID_s=floor,win=[-2],
                     tower_enemy_rule={'target_power':target,'units':9,'captain':'skin_orange',
                                       'other_slots_percent':{'skin_orange':40,'orange':30,'purple':30}})
        stages[stage['id']]=roll_tower_encounter(cfg,stage,random.Random(f'tower-103-preview-{floor}'))

def enemy_quality(stage):
    qualities=[]
    for unit in stage.get('team2',[]):
        aid=unit[0] if isinstance(unit,list) and unit else None
        if isinstance(aid,str) and aid.startswith('A_1'):
            try:qualities.append(int(aid.rsplit('_',1)[1]))
            except (ValueError,IndexError):pass
    if not qualities:raise GameplayFault('InvalidStage','Tower enemy quality is unavailable')
    return max(qualities)

def validate_tower_reward(config,stage):
    """Use exactly the settlement pool and uniqueness rule for Mod preflight."""
    pools=SummonPools.from_config(config)
    if pools is None:raise GameplayFault('InvalidConfig','Tower requires calibrated summon pools')
    floor=int(stage.get('tower_floor',0))
    if not 1<=floor<=MAX_FLOOR:raise GameplayFault('InvalidStage','Invalid tower floor')
    quality=enemy_quality(stage)
    if quality<6:
        key=next((key for key,value in QUALITY_IDS.items() if value==quality),None)
        if key is None:raise GameplayFault('InvalidStage','Unsupported tower quality')
        pools.validate_quality('advanced',key)
        return pools,'advanced',key,1
    pools.validate_quality('vip','orange',10)
    return pools,'vip','orange',10


def roll_tower_reward(config,stage,rng):
    pools,pool,quality,count=validate_tower_reward(config,stage)
    heroes=pools.draw_quality(pool,quality,rng,count)
    if count==1:
        aid=heroes[0]
        return {'heroes':[{'aid':aid,'num':1}]}
    floor=int(stage['tower_floor'])
    souls=dict.fromkeys(heroes,1)
    for _ in range(100+floor*2-10):souls[heroes[rng.randrange(10)]]+=1
    return {'avatar_soul':souls}

def apply_tower_rewards_103(document):
    cfg=document.get('cfg',document)
    previous=cfg.get('tower_rewards_103')
    if previous:
        if previous.get('schema')==SCHEMA:return document
        raise ValueError('Incompatible tower reward schema')
    stages=copy.deepcopy(cfg['combat_ploy']);count=0
    _extend_tower(cfg,stages)
    for stage in stages.values():
        if stage.get('activity_kind')!='tower':continue
        floor=int(stage['tower_floor']);quality=enemy_quality(stage)
        rule={'schema':SCHEMA,'quality':quality,'pool':'advanced' if quality<6 else 'vip'}
        if quality<6:
            rule.update(kind='hero',amount=1)
            stage['info']=f'胜利获得一张{QUALITY_NAMES[quality]}色英雄整卡；卡池与高级召唤对应品质一致。逐层解锁，可重复挑战。'
        else:
            rule.update(kind='souls',amount=100+2*floor,distinct_heroes=10)
            stage['info']=f'胜利获得{100+2*floor}个橙色英雄碎片，随机分配给10名不同英雄，每名至少1个；英雄按VIP橙色召唤池权重抽取。逐层解锁，可重复挑战。'
        stage['tower_reward_rule']=rule
        stage['win']=[-2]
        if floor>EXTENSION_START:
            stage['info']='每次挑战随机生成9名125级、技能10级、满进阶且突破极限的英雄；队长固定为皮肤橙卡，其余位置按皮肤橙40%、普通橙30%、紫卡30%抽取。敌方全灭后获胜。'+stage['info']
        for key in ('soul_candidates','soul_amount','tower_hero_candidates','tower_hero_amount','tower_allow_skin'):stage.pop(key,None)
        count+=1
    if count!=MAX_FLOOR:raise ValueError(f'Tower requires exactly {MAX_FLOOR} floors, found {count}')
    cfg['combat_ploy']=stages
    chapters=copy.deepcopy(cfg['battle_ploy'])
    chapters['P_200'].update(combat=MAX_FLOOR,info='常驻180层灵魂之塔；敌方全灭后获胜，消耗10体力。全部180层三星通关可领取188888金砖彩蛋。')
    cfg['battle_ploy']=chapters
    gifts=copy.deepcopy(cfg['pass_battle_gift'])
    gifts['-1']['P_200']={'need_star':MAX_FLOOR*3,'gift':{'coin':188888}}
    cfg['pass_battle_gift']=gifts
    if 'cfg' in document:
        for key in ('combat_ploy','battle_ploy','pass_battle_gift'):
            document[key]=cfg[key]
            if isinstance(document.get('pve'),dict):document['pve'][key]=cfg[key]
    cfg['tower_rewards_103']={'schema':SCHEMA,'floors':count,'orange_total':'100 + floor * 2','orange_distinct':10}
    return document
