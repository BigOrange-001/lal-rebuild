"""User-directed, audited hero mechanisms and numeric calibration for 1.0.4.

Runs before bonds/equipment/output so every runtime variant inherits the change.
Card identities and native skill IDs are preserved, including hard-coded gates.
"""
import copy
import hashlib
import json
import math
from pathlib import Path
from bonds_104 import _scale_skill
from hero_calibration_104 import append_self
from equipment_bonds_104 import append_effect

PLAN=Path(__file__).resolve().parents[1]/'config/reconstruction/hero-balance-iteration-1.0.4.json'
SCHEMA='hero-balance-iteration-104-v1'
FX='FX60_MAGIC'
MECHANISMS={
 'A_1033':'暗影收割：小技能击杀后最多再释放一次，队长技扩大近身追猎范围。',
 'A_1028':'怒气积累：小技能命中后永久叠加攻击，最多六层，降低对队长技的依赖。',
 'A_1124':'沙兵整备：小技能召唤后整备自己的沙兵，延续存活时间、恢复生命并强化攻击。',
 'A_1024':'利刃续战：突刺获得护盾，队长技击杀后追放一次小技能。',
 'A_1074':'万魂领域：队长技改为覆盖本路全体敌人，小技能缩短空窗。',
 'A_1049':'寒冰护援：冲锋后为全队生命比例最低的英雄提供生命护盾。',
 'A_1130':'决斗突破：突刺施加破甲，队长技击杀后可再释放一次。',
 'A_1132':'手里剑直击：小技能在原持续伤害外追加即时物理伤害。',
 'A_1210':'舞步防护：每次小技能获得短暂生命护盾，觉醒同时净化自身。',
 'A_1217':'圣诞预热：每次小技能积累攻击，最多五层，不再只靠击杀获得成长。',
 'A_1212':'粽香援护：队长技强化本路全体友军，同时优先治疗、净化并保护最低生命友军。',
 'A_1103':'虚空压制：小技能追加即时魔法伤害和沉默，召唤时获得生命护盾。',
 'A_1134':'虚空追击：小技能后突进至本路低生命目标，追加一次魔法攻击。',
}


def append_target(row,action,policy='enemy_lane_frontmost'):
    append_effect(row,dict(action=action,policy=policy))


def mechanism_text(family,hero):
    return MECHANISMS.get(family,{
        1:'突破续战：小技能追加前排破甲，并获得短暂攻击护盾。',
        2:'净化援助：小技能后净化并治疗全队生命比例最低的友军。',
        3:'护援先锋：小技能后为最低生命友军提供生命护盾，并弱化前排敌人。',
    }.get(hero.get('stat_profile',1),'突破续战：小技能追加前排破甲，并获得短暂攻击护盾。'))


def rework(cfg,hero,family):
    normal=cfg['skill'].get(hero['pl'][10]);captain=cfg['skill'].get(hero['pl'][11])
    if not normal:return
    if family=='A_1033':
        append_self(normal,['recast_on_kill',3,1,0,0,FX]);captain['pl'][2]=max(650,captain['pl'][2])
    elif family=='A_1028':append_self(normal,['battle_stack','attack',.06,6,1,'any_hit','FX60_STRONG'])
    elif family=='A_1124':append_self(normal,['rally_soldiers',1,'A_3002_2',3,'SUMMON_EFF'])
    elif family=='A_1024':
        append_self(normal,['caster_ap_shield',.75,2,'FX60_SHIELD'])
        append_self(captain,['normal_on_hero_kill',[1,3],FX])
    elif family=='A_1074':
        captain['pl'][2]=3000;captain['pl'][4]=-1
        captain['actionTargetPolicies']=['enemy_lane_all']*len(captain['skill'])
        captain['actionTargetMaxTargets']=[-1]*len(captain['skill'])
        normal['pl'][1]=max(0,normal['pl'][1]-1)
    elif family=='A_1049':append_target(normal,['target_hp_shield',.08,2,'FX60_SHIELD'],'ally_all_lowest_hp_ratio')
    elif family=='A_1130':
        append_target(normal,['sunder_percent',0,2,.25,2,'FX60_SUNDER'])
        append_self(captain,['recast_on_kill',4,1,0,0,FX])
    elif family=='A_1132':append_target(normal,['damage',.65,1,FX])
    elif family=='A_1210':
        append_self(normal,['caster_hp_shield',.05,1,'FX60_SHIELD']);append_self(captain,['purify',1,'FX60_PURIFY'])
    elif family=='A_1217':append_self(normal,['battle_stack_unconditional','attack',.04,5,'FX60_STRONG'])
    elif family=='A_1212':
        captain['actionTargetPolicies']=['ally_all_lowest_hp_ratio']+['ally_lane_all']*(len(captain['skill'])-1)
        captain['actionTargetMaxTargets']=[1]+[-1]*(len(captain['skill'])-1)
        append_target(captain,['purify',1,'FX60_PURIFY'],'ally_all_lowest_hp_ratio')
        append_target(captain,['target_hp_shield',.08,2,'FX60_SHIELD'],'ally_all_lowest_hp_ratio')
    elif family=='A_1103':
        append_target(normal,['damage',.6,2,FX]);append_target(normal,['silence',0,1,1,'FX60_WEAK'])
        append_self(captain,['caster_hp_shield',.06,2,'FX60_SHIELD'])
    elif family=='A_1134':
        append_target(normal,['move_to_target_lane','enemy_lane_lowest_hp_ratio_n',0,125,'FX60_GAREN_DASH'])
        append_target(normal,['damage',.8,2,FX],'enemy_lane_lowest_hp_ratio_n')
    else:
        role=hero.get('stat_profile',1)
        if role==3:
            append_target(normal,['target_hp_shield',.08,2,'FX60_SHIELD'],'ally_all_lowest_hp_ratio')
            append_target(normal,['weak_percent',0,2,.15,2,'FX60_WEAK'])
        elif role==2:
            append_target(normal,['purify',1,'FX60_PURIFY'],'ally_all_lowest_hp_ratio')
            append_target(normal,['cure',.7,'FX60_HEAL'],'ally_all_lowest_hp_ratio')
        else:
            append_target(normal,['sunder_percent',0,2,.2,2,'FX60_SUNDER'])
            append_self(normal,['caster_ap_shield',.7,1,'FX60_SHIELD'])
    text=mechanism_text(family,hero)
    for row in (normal,captain):
        if row:
            row['balance_mechanism_104']=text
            for field in ('info','rankInfoTemplate'):row[field]=row.get(field,row.get('info',''))+'\n'+text


def _scale(source,factor):
    row=_scale_skill(source,factor)
    for action in row.get('skill',[]):
        if action[0]=='mod_step' and action[1]=='summon':action[12]*=factor
    if any(a[0]=='summon' for a in row.get('skill',[])):
        row['captainSummonMultiplier']=row.get('captainSummonMultiplier',1)*factor
    if row.get('manualClonePolicy'):
        row['manualClonePolicy']['panelStatRatio']*=factor
    if row.get('chainDot'):row['chainDot'][1]*=factor
    return row


def apply_hero_balance_iteration_104(document,plan=None):
    cfg=document.get('cfg',document)
    if cfg.get('hero_balance_iteration_104'):return document
    if plan is None:
        if not PLAN.exists():return document
        plan=json.loads(PLAN.read_text('utf8'))
    if not plan.get('enabled'):return document
    if plan.get('schema')!=SCHEMA:raise ValueError('Unknown hero balance plan')
    skin_factor=plan.get('skin_panel_factor',1)
    if type(skin_factor) not in (int,float) or not math.isfinite(skin_factor) or not .3<=skin_factor<=3:raise ValueError('Invalid skin panel factor')
    demands=plan['heroes'];skins=set(cfg['system_simple'].get('skin_hero_ids',[]))
    for family,entry in demands.items():
        for k in ('panel_factor','skill_factor'):
            v=entry[k]
            if type(v) not in (int,float) or not math.isfinite(v) or not .03<=v<=10:raise ValueError(f'Invalid {family} {k}')
    # This baseline has no shared skill across the named hero families. Refuse
    # future ambiguity rather than let one hero silently change another.
    owners={};applied={};changes=[]
    for aid,hero in cfg['avatar'].items():
        family=aid.rsplit('_',1)[0]
        if family not in demands:continue
        entry=demands[family];panel=entry['panel_factor']*(skin_factor if aid in skins or hero.get('hero_category_104')=='skin' else 1)
        hero['pl'][:8]=[round(v*panel,10) for v in hero['pl'][:8]]
        # Rework once per unique skill pair; quality variants have private rows.
        pair=tuple(hero['pl'][i] if len(hero['pl'])>i else None for i in (10,11))
        if entry.get('mechanism') and pair not in applied:
            rework(cfg,hero,family);applied[pair]=True
        for slot in (10,11,13):
            if len(hero['pl'])<=slot:continue
            sid=hero['pl'][slot]
            if sid not in cfg['skill']:continue
            if sid in owners:
                if owners[sid]!=family:raise ValueError('Shared skill during balance: '+str(sid))
                continue
            owners[sid]=family
            cfg['skill'][sid]=_scale(cfg['skill'][sid],entry['skill_factor'])
        changes.append(aid)
    digest=hashlib.sha256(json.dumps(plan,sort_keys=True,ensure_ascii=False).encode()).hexdigest()
    cfg['hero_balance_iteration_104']=dict(schema=SCHEMA,round=plan.get('round',0),plan_sha256=digest,changed_ids=changes,
                                         final_skill_multipliers=copy.deepcopy(plan.get('final_skill_multipliers',{})))
    return document
