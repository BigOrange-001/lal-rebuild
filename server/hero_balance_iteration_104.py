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


def _r(index,position=1):
    return '{rank:%d:%s}'%(index,position)


def _single(groups):
    if len(groups)!=1:raise ValueError('Mechanism added twice to one skill')
    return groups[0]


def _purify_cure_text(groups):
    cures=[cure for _purify,cure in groups]
    if len(cures)==1:
        return f'为全队生命比例最低的友方英雄净化，并回复（施法者攻击力＋10%最大生命值）×{_r(cures[0])}的生命。'
    amounts='、'.join(_r(c) for c in cures)
    return f'为全队生命比例最低的友方英雄净化并回复生命，共结算{len(cures)}次，每次以（施法者攻击力＋10%最大生命值）为基数，依次回复{amounts}的生命。'


# Effect-only lines, written on the skill that carries the added actions.
# Tokens follow the live action values (client per rank, info at rank 1).
LIVE_TEXT={
 'purify_cure':_purify_cure_text,
 'attack_stack_hit':lambda g:f'每次施放命中敌人后，本场攻击提高{_r(_single(g)[0],2)}，最多叠加6层。',
 'attack_stack_cast':lambda g:f'每次施放另外获得1层{_r(_single(g)[0],2)}攻击增益，该增益本场最多5层。',
 'ally_hp_shield':lambda g:f'为全队生命比例最低的友方英雄提供其最大生命值{_r(_single(g)[0])}的护盾，持续2回合。',
 'self_hp_shield_1':lambda g:f'每次施放获得自身最大生命值{_r(_single(g)[0])}的护盾，持续1回合。',
 'self_hp_shield_2':lambda g:f'为自己提供自身最大生命值{_r(_single(g)[0])}的护盾，持续2回合。',
 'self_purify':lambda g:_single(g) and '施放时净化自身。',
 'front_magic_silence':lambda g:f'同时对本路最前方的敌人造成{_r(_single(g)[0])}魔法伤害并沉默1回合。',
 'front_physical':lambda g:f'同时对本路最前方的敌人造成{_r(_single(g)[0])}物理伤害。',
 'dash_lowest_magic':lambda g:f'随后突进至本路生命比例最低的敌人面前，对其造成{_r(_single(g)[0])}魔法伤害。',
 'lowest_purify_shield':lambda g:f'全队生命比例最低的友方英雄另外获得净化和其最大生命值{_r(_single(g)[1])}的护盾，持续2回合。',
}
LIVE_TEXT_FAMILIES={'A_1001','A_1028','A_1049','A_1074','A_1103','A_1132','A_1134','A_1210','A_1212','A_1217'}
# Retargeted captain skills: the original body named the old target set.
TARGET_TEXT={
 'A_1074':('自身周围400范围内距离自己最近的最多4名敌人','本路所有敌人'),
 'A_1212':('为范围内全场友方恢复生命，并分别附加','为范围内生命比例最低的友军恢复生命，并为范围内全体友军分别附加'),
}


def _append_line(row,text):
    base=row.get('info','');template=row.get('rankInfoTemplate',base)
    if text in base.split('\n'):return
    row['info']=base+'\n'+text;row['rankInfoTemplate']=template+'\n'+text


def _retarget_text(row,family):
    old,new=TARGET_TEXT[family];found=False
    for field in ('info','rankInfoTemplate'):
        text=row.get(field)
        if isinstance(text,str):
            found=found or old in text or new in text
            row[field]=text.replace(old,new)
    if not found:raise ValueError('Unexpected retargeted skill text: '+family)


def mechanism_text(family,hero):
    return MECHANISMS.get(family,{
        1:'突破续战：小技能追加前排破甲，并获得短暂攻击护盾。',
        2:'净化援助：小技能后净化并治疗全队生命比例最低的友军。',
        3:'护援先锋：小技能后为最低生命友军提供生命护盾，并弱化前排敌人。',
    }.get(hero.get('stat_profile',1),'突破续战：小技能追加前排破甲，并获得短暂攻击护盾。'))


def rework(cfg,hero,family,notes=None):
    """Add the family's actions; record where they land for the skill text."""
    normal=cfg['skill'].get(hero['pl'][10]);captain=cfg['skill'].get(hero['pl'][11])
    if not normal:return
    notes={} if notes is None else notes
    def note(row,kind,*indices):
        # Keyed by skill ID: numeric scaling later replaces the row object.
        entry=notes.setdefault(hero['pl'][10 if row is normal else 11],[kind,[]])
        if entry[0]!=kind:raise ValueError('Two mechanism texts for one skill')
        entry[1].append(indices)
    n=len(normal['skill']);c=len(captain['skill']) if captain else 0
    if family in LIVE_TEXT_FAMILIES:
        # Reworked rows always carried a rank template; keep it without a line.
        for row in (normal,captain):
            if row:row.setdefault('rankInfoTemplate',row.get('info',''))
    if family=='A_1033':
        append_self(normal,['recast_on_kill',3,1,0,0,FX]);captain['pl'][2]=max(650,captain['pl'][2])
    elif family=='A_1028':
        append_self(normal,['battle_stack','attack',.06,6,1,'any_hit','FX60_STRONG']);note(normal,'attack_stack_hit',n)
    elif family=='A_1124':append_self(normal,['rally_soldiers',1,'A_3002_2',3,'SUMMON_EFF'])
    elif family=='A_1024':
        append_self(normal,['caster_ap_shield',.75,2,'FX60_SHIELD'])
        append_self(captain,['normal_on_hero_kill',[1,3],FX])
    elif family=='A_1074':
        captain['pl'][2]=3000;captain['pl'][4]=-1
        captain['actionTargetPolicies']=['enemy_lane_all']*len(captain['skill'])
        captain['actionTargetMaxTargets']=[-1]*len(captain['skill'])
        normal['pl'][1]=max(0,normal['pl'][1]-1)
        _retarget_text(captain,family)
    elif family=='A_1049':
        append_target(normal,['target_hp_shield',.08,2,'FX60_SHIELD'],'ally_all_lowest_hp_ratio');note(normal,'ally_hp_shield',n)
    elif family=='A_1130':
        append_target(normal,['sunder_percent',0,2,.25,2,'FX60_SUNDER'])
        append_self(captain,['recast_on_kill',4,1,0,0,FX])
    elif family=='A_1132':append_target(normal,['damage',.65,1,FX]);note(normal,'front_physical',n)
    elif family=='A_1210':
        append_self(normal,['caster_hp_shield',.05,1,'FX60_SHIELD']);append_self(captain,['purify',1,'FX60_PURIFY'])
        note(normal,'self_hp_shield_1',n);note(captain,'self_purify',c)
    elif family=='A_1217':
        append_self(normal,['battle_stack_unconditional','attack',.04,5,'FX60_STRONG']);note(normal,'attack_stack_cast',n)
    elif family=='A_1212':
        captain['actionTargetPolicies']=['ally_all_lowest_hp_ratio']+['ally_lane_all']*(len(captain['skill'])-1)
        captain['actionTargetMaxTargets']=[1]+[-1]*(len(captain['skill'])-1)
        append_target(captain,['purify',1,'FX60_PURIFY'],'ally_all_lowest_hp_ratio')
        append_target(captain,['target_hp_shield',.08,2,'FX60_SHIELD'],'ally_all_lowest_hp_ratio')
        _retarget_text(captain,family);note(captain,'lowest_purify_shield',c,c+1)
    elif family=='A_1103':
        append_target(normal,['damage',.6,2,FX]);append_target(normal,['silence',0,1,1,'FX60_WEAK'])
        append_self(captain,['caster_hp_shield',.06,2,'FX60_SHIELD'])
        note(normal,'front_magic_silence',n,n+1);note(captain,'self_hp_shield_2',c)
    elif family=='A_1134':
        append_target(normal,['move_to_target_lane','enemy_lane_lowest_hp_ratio_n',0,125,'FX60_GAREN_DASH'])
        append_target(normal,['damage',.8,2,FX],'enemy_lane_lowest_hp_ratio_n')
        note(normal,'dash_lowest_magic',n+1)
    else:
        role=hero.get('stat_profile',1)
        if role==3:
            append_target(normal,['target_hp_shield',.08,2,'FX60_SHIELD'],'ally_all_lowest_hp_ratio')
            append_target(normal,['weak_percent',0,2,.15,2,'FX60_WEAK'])
        elif role==2:
            append_target(normal,['purify',1,'FX60_PURIFY'],'ally_all_lowest_hp_ratio')
            append_target(normal,['cure',.7,'FX60_HEAL'],'ally_all_lowest_hp_ratio')
            if family in LIVE_TEXT_FAMILIES:note(normal,'purify_cure',n,n+1)
        else:
            append_target(normal,['sunder_percent',0,2,.2,2,'FX60_SUNDER'])
            append_self(normal,['caster_ap_shield',.7,1,'FX60_SHIELD'])
    text=mechanism_text(family,hero)
    for row in (normal,captain):
        if row:
            row['balance_mechanism_104']=text
            if family not in LIVE_TEXT_FAMILIES:_append_line(row,text)
    return notes


def write_mechanism_text(cfg,notes):
    for sid,(kind,groups) in notes.items():_append_line(cfg['skill'][sid],LIVE_TEXT[kind](groups))


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
    owners={};applied={};changes=[];notes={}
    for aid,hero in cfg['avatar'].items():
        family=aid.rsplit('_',1)[0]
        if family not in demands:continue
        entry=demands[family];panel=entry['panel_factor']*(skin_factor if aid in skins or hero.get('hero_category_104')=='skin' else 1)
        hero['pl'][:8]=[round(v*panel,10) for v in hero['pl'][:8]]
        # Rework once per unique skill pair; quality variants have private rows.
        pair=tuple(hero['pl'][i] if len(hero['pl'])>i else None for i in (10,11))
        if entry.get('mechanism') and pair not in applied:
            rework(cfg,hero,family,notes);applied[pair]=True
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
    write_mechanism_text(cfg,notes)
    digest=hashlib.sha256(json.dumps(plan,sort_keys=True,ensure_ascii=False).encode()).hexdigest()
    cfg['hero_balance_iteration_104']=dict(schema=SCHEMA,round=plan.get('round',0),plan_sha256=digest,changed_ids=changes,
                                         final_skill_multipliers=copy.deepcopy(plan.get('final_skill_multipliers',{})))
    return document
