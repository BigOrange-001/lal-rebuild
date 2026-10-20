"""Structured templates for the complete installed battle-mechanism catalogue.

Templates contain data, never AS3/SWF or an eval surface. Operations and value
shapes come from the immutable game catalogue. Runtime identities remain private;
the compiler separately stamps the original mechanism identity for native hooks.
"""
from __future__ import annotations

import copy
import math
import re
import json
from functools import lru_cache
from pathlib import Path
from mod_schema import ModError, POLICIES, canonical, digest, fail, local_id, text_

MODEL = 'native-template-v1'
CAPABILITY = 'skill.native-template.v1'
# The 1.0.3 catalogue adds fixed skin mechanisms and changes one default.
# Existing explicit parameter values and bounds are unchanged, so both reviewed
# predecessor contracts remain valid. All current shapes and bounds still apply.
_ABILITY_CONTRACT_PREDECESSORS = {'12e6da728f5fb976dfe5dc3f2b5895ed2169882472ee0590478e6dd2b4876041': ('e92915d3f2f74b97cafebc627b8d7b7c61bcd0508bcd4985c6f71d9f40470685', 'e51a0c4280e7a861b0c8397e8c8877061c5396bda525a7c144823ee244d09f46')}
PARALLEL = ('actionTargetPolicies', 'actionTargetLocks', 'actionTargetGroups',
            'actionTargetMaxTargets', 'actionTargetPolicyArgs')
INDEX_KEYS = frozenset(('centerActionIndex', 'primaryActionIndex', 'requiresPrecastDotActionIndex'))
LIST_INDEX_KEYS = frozenset(('distinctFromActionIndices',))
_CONTRACT_CACHE = {}
ACTION_REFS = {'heal_damage_sum': (2, True), 'normal_on_hero_kill': (1, True),
               'pending_area_strike': (1, False), 'recast_on_kill': (1, False),
               'kill_buff': (4,False), 'shield_followup': (4,False),
               'battle_stack': (4,False), 'heal_missing_hp_per_hero': (3,False)}
NODE_SETTINGS=frozenset(('manualSummonPolicy','manualClonePolicy','summonCombatPolicy',
    'captainSummonMultiplier','manualDamageMultiplier','manualDefenseBuffMultiplier','manualEffectMultiplier'))

OP_LABELS = dict(zip(
    ('damage cure shield hp_shield caster_hp_shield target_hp_shield stun silence weak sunder poison burn strong purify armor '
     'dash move_to_target move_to_target_lane move_self move_to_ally move_enemy_side_target '
     'shield_followup locked_sequence locked_sequence_area locked_combo_group locked_combo_weak '
     'heal_ap suck combo pull push push_aoe curse stat_flat weak_percent sunder_percent attrup '
     'summon_turret steel summon true_damage trynd_undying shield_dispel hitup fleeup bless taunt '
     'pull_group manual_dot heal_missing_hp_per_hero battle_stack heal_damage_sum recast_on_kill '
     'conditional_damage heal_missing_hp battle_stack_unconditional damage_chain focus_fire select_target '
     'kill_buff stun_by_condition dash_group_strike lethal_floor shield_composite pending_area_strike '
     'evil ricochet_bursts back dispel_good clone_normal timed_stack normal_on_hero_kill manual_ability').split(),
    ('伤害 治疗 攻击护盾 生命护盾 施法者生命护盾 目标生命护盾 眩晕 沉默 虚弱 破甲 中毒 灼烧 强化 净化 护甲 '
     '冲刺 移动至敌人 换路并突进 自身位移 移动至友军 移至敌人侧面 '
     '护盾后续结算 锁定连段 锁定连段范围攻击 分组连击 连击附加虚弱 '
     '按攻击治疗 吸血 连击 拉近 击退 范围击退 诅咒 固定属性 百分比虚弱 百分比破甲 属性提升 '
     '召唤炮台 双抗提升 召唤 真实伤害 不死状态 驱散护盾 命中提升 闪避提升 祝福 嘲讽 '
     '群体拉近 持续伤害 按命中英雄数回复已损生命 战斗叠层 按实际伤害总和治疗 击杀重施 '
     '条件伤害 回复已损生命 无条件战斗叠层 链式伤害 集火 选定目标 '
     '击杀增益 条件眩晕 突进群攻 最低生命保护 复合护盾 延后范围打击 '
     '邪恶 弹射连发 反击 驱散增益 普通技能分身 定时叠层 击杀英雄追加普攻 原生复合机制').split()))

# Labels are positions in the actual engine arrays, including index zero.
ARG_LABELS = {
    'damage': ['动作','伤害倍率','伤害类型','特效'],
    'caster_hp_heal': ['动作','施法者最大生命治疗比例','特效'],
    'manual_ability': ['动作','复合机制','等级倍率','特效'],
    'move_to_target': ['动作','目标策略','最大移动距离','特效'],
    'move_to_target_lane': ['动作','目标策略','最大移动距离','落点间距','特效'],
    'move_enemy_side_target': ['动作','目标策略','落点间距','特效'],
    'summon': ['动作','面板倍率','召唤单位','存续回合','特效'],
    'summon_turret': ['动作','面板倍率','召唤单位','存续回合','原生参数4','原生参数5','原生参数6','数量参数','原生参数8','原生参数9','特效'],
    'stun': ['动作','伤害倍率','伤害类型','持续回合','特效'],
    'silence': ['动作','伤害倍率','伤害类型','持续回合','特效'],
    'heal_damage_sum': ['动作','治疗倍率','来源动作列表','特效'],
    'normal_on_hero_kill': ['动作','击杀来源动作列表','特效'],
    'pending_area_strike': ['动作','中心来源动作','伤害倍率','伤害类型','半径','最大目标数','延后回合','特效'],
    'recast_on_kill': ['动作','击杀来源动作','最多重施次数','仅英雄击杀','排除召唤物','特效'],
    'manual_dot': ['动作','持续伤害类型','每次攻击倍率','最大生命比例','持续回合','伤害类型','刷新标记','特效'],
    'conditional_damage': ['动作','基础倍率','伤害类型','触发条件','条件附加倍率','特效'],
    'damage_chain': ['动作','连锁段数','分段倍率','伤害类型','传播距离','最大目标数','传播策略','附加倍率','状态标记','附加参数','开关','特效'],
    'ricochet_bursts': ['动作','发射次数','弹射倍率列表','弹射半径','伤害类型','特效'],
    'battle_stack': ['动作','属性','每层数值','最大层数','增量层数','触发条件','特效'],
    'battle_stack_unconditional': ['动作','属性','每层数值','最大层数','特效'],
    'timed_stack': ['动作','属性','每层数值','最大层数','持续回合','特效'],
    'stat_flat': ['动作','属性','固定数值','持续回合','特效'],
    'shield_followup':['动作','生命护盾比例','持续回合','后续伤害倍率','目标来源动作','伤害类型','附加虚弱比例','虚弱回合','特效'],
    'locked_combo_group':['动作','最多目标数','连击次数','每段倍率','伤害类型','恢复比例','特效'],
    'locked_combo_weak':['动作','每段倍率','伤害类型','连击次数','附加虚弱比例','持续回合','特效'],
    'heal_ap':['动作','治疗倍率','特效'],'suck':['动作','伤害倍率','伤害类型','吸血比例','特效'],
    'combo':['动作','每段倍率','伤害类型','连击次数','特效'],
    'pull':['动作','伤害倍率','伤害类型','拉近距离','特效'],
    'push':['动作','伤害倍率','伤害类型','击退距离','特效'],
    'push_aoe':['动作','影响距离','击退距离','特效'],
    'attrup':['动作','倍率','属性','固定属性值','持续回合','特效'],
    'true_damage':['动作','真实伤害倍率','特效'],'trynd_undying':['动作','持续回合'],
    'shield_dispel':['动作','影响距离','特效'],'bless':['动作','持续回合','特效'],
    'curse':['动作','持续回合','特效'],'taunt':['动作','持续回合','特效'],
    'pull_group':['动作','伤害倍率','伤害类型','拉近距离','落点间距','特效'],
    'heal_missing_hp_per_hero':['动作','每名英雄回复比例','回复比例上限','最大英雄数','特效'],
    'heal_missing_hp':['动作','已损生命回复比例','特效'],
    'kill_buff':['动作','增益状态','增益倍率','持续回合','击杀来源动作','特效'],
    'stun_by_condition':['动作','伤害倍率','伤害类型','基础眩晕回合','触发条件','附加眩晕回合','特效'],
    'dash_group_strike':['动作','伤害倍率','伤害类型','恢复比例','特效'],
    'lethal_floor':['动作','最低生命','持续回合','结束治疗倍率','特效'],
    'shield_composite':['动作','攻击与生命混合倍率','双抗倍率','持续回合','特效'],
    'evil':['动作','伤害倍率','伤害类型','持续回合','特效'],
    'focus_fire':['动作','特效'],'select_target':['动作','特效'],'dispel_good':['动作','特效'],
    'clone_normal':['动作','特效'],'move_to_ally':['动作','特效'],
    'dash':['动作','位移距离','特效'],'move_self':['动作','位移距离','特效'],
}
for kind in ('weak','sunder','poison','weak_percent','sunder_percent'):
    ARG_LABELS[kind]=['动作','伤害倍率','伤害类型','附加比例','持续回合','特效']
for kind in ('shield','hp_shield','caster_hp_shield','target_hp_shield','strong','steel','armor','burn','back','hitup','fleeup'):
    ARG_LABELS[kind]=['动作','倍率','持续回合','特效']

def argument_label(kind, index, arguments):
    raw=[kind]+arguments
    if index == len(raw)-1 and isinstance(raw[index],str) and kind not in ('trynd_undying',):return '视觉特效'
    if kind in ('locked_sequence','locked_sequence_area') and len(raw)>1 and type(raw[1]) is int:
        hits=raw[1]
        if index==1:return '连段次数'
        if 2<=index<2+hits:return '第 '+str(index-1)+' 段伤害倍率'
        return {hits+2:'伤害类型',hits+3:'恢复比例',hits+4:'范围半径',hits+5:'最多目标数'}.get(index,'连段附加参数 '+str(index))
    labels=ARG_LABELS.get(kind,())
    return labels[index] if index<len(labels) else '参数 '+str(index)

def is_native(skill):
    return isinstance(skill,dict) and skill.get('model') == MODEL

def _cfg(base):return base.get('cfg',base)

@lru_cache(maxsize=1)
def ability_contract():
    return json.loads((Path(__file__).with_name('native_ability_parameters.json')).read_text('utf-8'))

def ability_defaults(kind):
    return {k:v['default'] for k,v in ability_contract()['mechanisms'].get(kind,{}).items()}

def contracts(base):
    cfg=_cfg(base);entry=_CONTRACT_CACHE.get(id(cfg))
    if entry and entry[0] is cfg:return entry[1]
    operations={};fields={};effects=set(cfg.get('effect',{}));policies=set(POLICIES)
    for row in cfg.get('skill',{}).values():
        for key,value in row.items():
            bucket=fields.setdefault(key,[])
            if not any(_same_shape(value,e) for e in bucket):bucket.append(value)
        for raw in row.get('skill',[]):
            bucket=operations.setdefault(raw[0],[])
            if not any(_same_shape(raw,e) for e in bucket):bucket.append(raw)
            if isinstance(raw[-1],str):effects.add(raw[-1])
            policies.update(v for v in _strings(raw) if v.startswith(('enemy_','ally_')))
        policies.update(v for v in row.get('actionTargetPolicies',[]) or [] if isinstance(v,str))
    result={'operations':operations,'fields':fields,'effects':effects,'policies':policies}
    if len(_CONTRACT_CACHE)>=4:_CONTRACT_CACHE.pop(next(iter(_CONTRACT_CACHE)))
    _CONTRACT_CACHE[id(cfg)]=(cfg,result)
    return result

def _same_shape(a,b):
    if type(a) is not type(b):return type(a) in (int,float) and type(b) in (int,float)
    if isinstance(a,list):return len(a)==len(b) and all(_same_shape(x,y) for x,y in zip(a,b))
    if isinstance(a,dict):return set(a)==set(b) and all(_same_shape(a[k],b[k]) for k in a)
    return True

def make_template(sid, native, base):
    cfg=_cfg(base)
    triggers=sorted({row.get('skill_diff',0) for row in cfg.get('avatar',{}).values()
                     if len(row.get('pl',[]))>13 and row['pl'][13]==sid and row.get('skill_diff')})
    result={'id':'Template_'+sid, 'name':native.get('name',sid), 'description':native.get('info',''),
            'model':MODEL, 'nativeTemplate':{'source':'builtin:skill/'+sid,'sourceDigest':digest(native),
                'settings':copy.deepcopy({k:v for k,v in native.items() if k not in ('id','name','info','skill')}),
                'passiveTrigger':triggers[0] if len(triggers)==1 else 0},
            'actions':[{'type':a[0],'arguments':copy.deepcopy(a[1:])} for a in native.get('skill',[])],
            'upgrades':[]}
    kinds={a[1] for a in native.get('skill',[]) if a[0]=='manual_ability'}
    if kinds:
        result['nativeTemplate']['abilityParameters']={kind:ability_defaults(kind) for kind in sorted(kinds)}
        result['nativeTemplate']['abilityContract']=digest(ability_contract())
    if '{scale:' in native.get('rankInfoTemplate',''):result['nativeTemplate']['scaleActionIndex']=0
    return result

def validate_shape(skill,path='skill'):
    if not isinstance(skill,dict):fail('Expected native template object',path)
    required={'id','name','description','model','nativeTemplate','actions','upgrades'}
    if set(skill)!=required:fail('Native template fields differ from the contract',path)
    local_id(skill['id'],path+'.id');text_(skill['name'],path+'.name')
    text_(skill['description'],path+'.description',4000,True)
    model=skill['nativeTemplate']
    if (skill['model']!=MODEL or not isinstance(model,dict) or
        not {'source','sourceDigest','settings','passiveTrigger'}<=set(model) or
        set(model)-{'source','sourceDigest','settings','passiveTrigger','abilityParameters','abilityContract','scaleActionIndex'}):
        fail('Invalid native template identity',path+'.nativeTemplate')
    if not isinstance(model['source'],str) or not re.fullmatch(r'builtin:skill/[A-Za-z0-9_]+',model['source']):
        fail('Expected original builtin skill source',path+'.nativeTemplate.source')
    if not isinstance(model['sourceDigest'],str) or not re.fullmatch('[0-9a-f]{64}',model['sourceDigest']):
        fail('Expected original source SHA-256',path+'.nativeTemplate.sourceDigest')
    if type(model['passiveTrigger']) is not int or not 0<=model['passiveTrigger']<=19:fail('Invalid passive trigger',path)
    if not isinstance(model['settings'],dict):fail('Expected structured settings',path)
    if not isinstance(skill['actions'],list) or not 1<=len(skill['actions'])<=32:fail('Expected 1..32 native actions',path)
    for i,action in enumerate(skill['actions']):
        if (not isinstance(action,dict) or not {'type','arguments'}<=set(action) or set(action)-{'type','arguments','origin','settings'} or
            not isinstance(action['type'],str) or not isinstance(action['arguments'],list)):
            fail('Expected typed operation and argument list',path+'.actions[%d]'%i)
        if 'settings' in action and (not isinstance(action['settings'],dict) or set(action['settings'])-NODE_SETTINGS):
            fail('Unknown per-operation native settings',path+'.actions[%d]'%i)
    if skill['upgrades']!=[]:fail('Native growth is edited in nativeTemplate.settings.skillUp/skillUpPaths',path+'.upgrades')
    _bounded(skill,path)
    if 'scaleActionIndex' in model:_link(model['scaleActionIndex'],len(skill['actions']),path+'.scaleActionIndex')
    if 'abilityParameters' in model:
        current_contract=digest(ability_contract())
        accepted={current_contract}
        if current_contract in _ABILITY_CONTRACT_PREDECESSORS:accepted.update(_ABILITY_CONTRACT_PREDECESSORS[current_contract])
        if model.get('abilityContract') not in accepted:fail('Compound ability contract changed; re-import and review',path,'ModTargetMismatch')
        if not isinstance(model['abilityParameters'],dict):fail('Expected compound ability parameter groups',path)
        for kind,values in model['abilityParameters'].items():
            descriptors=ability_contract()['mechanisms'].get(kind)
            if descriptors is None or not isinstance(values,dict) or set(values)!=set(descriptors):fail('Unknown compound mechanism parameter',path)
            for key,value in values.items():
                d=descriptors[key]
                if type(value) not in (int,float) or (d['integer'] and int(value)!=value) or not d['minimum']<=value<=d['maximum'] or ('enum' in d and value not in d['enum']):
                    fail('Compound mechanism parameter outside its bounds',path+'.'+kind+'.'+key)

def _bounded(value,path,depth=0):
    if depth>16:fail('Native mechanism data is too deep',path)
    if value is None or type(value) is bool:return
    if type(value) in (int,float):
        if not math.isfinite(value) or abs(value)>10_000_000:fail('Nonfinite or oversized native parameter',path)
    elif isinstance(value,str):
        if len(value)>8000:fail('Native text exceeds limit',path)
    elif isinstance(value,(list,dict)):
        if len(value)>256:fail('Native collection exceeds limit',path)
        for key,child in (value.items() if isinstance(value,dict) else enumerate(value)):
            if isinstance(value,dict) and (not isinstance(key,str) or len(key)>200):fail('Invalid native field name',path)
            _bounded(child,path+'.'+str(key),depth+1)
    else:fail('Native data must be JSON values',path)

def _matches(value, example):
    if example is None:return value is None
    if type(example) is bool:return type(value) is bool
    if type(example) in (int,float):return type(value) in (int,float)
    if isinstance(example,str):return isinstance(value,str)
    if isinstance(example,list):
        if not isinstance(value,list):return False
        if not example:return len(value)<=128
        if len(value)==len(example):return all(_matches(v,e) for v,e in zip(value,example))
        return all(any(_matches(v,e) for e in example) for v in value)
    if isinstance(example,dict):return isinstance(value,dict) and set(value)==set(example) and all(_matches(value[k],example[k]) for k in example)
    return False

def validate_template(skill,base,path='skill'):
    validate_shape(skill,path)
    cfg=_cfg(base);model=skill['nativeTemplate'];sid=model['source'].split('/')[-1]
    source=cfg.get('skill',{}).get(sid)
    if source is None or digest(source)!=model['sourceDigest']:
        fail('Original skill changed or is missing; re-import and review template',path+'.nativeTemplate.sourceDigest','ModTargetMismatch')
    profile=contracts(base)
    settings=model['settings']; forbidden={'id','name','info','skill','modNativeSource','modPassiveTrigger','abilityParameters'}
    if set(settings)&forbidden:fail('Runtime identity fields are compiler-owned',path)
    for key,value in settings.items():
        examples=profile['fields'].get(key,[])
        if not examples or not any(_matches(value,e) for e in examples):fail('Unknown native field or incompatible value shape',path+'.settings.'+key)
    if 'pl' not in settings or 'skillUp' not in settings:fail('Native timing and growth fields are required',path)
    if settings['pl'] is not None and (not isinstance(settings['pl'],list) or len(settings['pl'])!=6):fail('Native timing requires six fields or null',path)
    if settings['pl'] is not None:
        timing=settings['pl']
        for index in (0,1,2,4,5):
            if type(timing[index]) is not int:fail('Timing/count fields must be integers',path+'.settings.pl')
        if not (0<=timing[0]<=100 and 0<=timing[1]<=100 and abs(timing[2])<=100000 and
                -1<=timing[3]<=1 and -32<=timing[4]<=100000 and timing[5] in (0,1)):
            fail('Native timing/health/area fields exceed bounds',path+'.settings.pl')
    for policy in settings.get('actionTargetPolicies',[]) or []:
        if policy is not None and policy not in profile['policies']:fail('Unknown native target policy',path)
    for i,action in enumerate(skill['actions']):
        raw=[action['type']]+action['arguments']
        examples=profile['operations'].get(action['type'],[])
        origin=action.get('origin',model['source'])
        if not isinstance(origin,str) or not origin.startswith('builtin:skill/'):fail('Expected builtin node origin',path)
        donor=cfg.get('skill',{}).get(origin.split('/')[-1])
        if not donor or not any(a[0]==action['type'] for a in donor.get('skill',[])):fail('Action does not belong to its mechanism origin',path)
        for key,value in action.get('settings',{}).items():
            if key not in donor or not _matches(value,donor[key]):fail('Per-operation setting is outside its origin contract',path)
        if not examples or not any(len(raw)==len(e) and all(_matches(v,p) for v,p in zip(raw,e)) for e in examples):
            fail('Operation/parameter shape is outside installed battle contracts',path+'.actions[%d]'%i)
        summon_policy=action.get('settings',{}).get('manualSummonPolicy',settings.get('manualSummonPolicy'))
        if action['type']=='summon' and summon_policy:
            if raw[2]!=summon_policy.get('unitId') or raw[3]!=summon_policy.get('ttlOwnerTurns'):
                fail('Summon unit and lifetime must match the summon policy; update both linked fields',path+'.actions[%d]'%i)
        if isinstance(raw[-1],str) and raw[-1] not in profile['effects']:
            fail('Unknown native visual effect; select an installed resource',path+'.actions[%d]'%i)
        if action['type']=='manual_ability' and raw[1] not in ability_contract()['mechanisms']:
            fail('Unknown compound ability',path+'.actions[%d]'%i)
        if action['type']=='locked_sequence' and (type(raw[1]) is not int or not 1<=raw[1]<=32 or len(raw)!=raw[1]+5):
            fail('Sequence count must match its editable hit coefficients',path+'.actions[%d]'%i)
        if action['type']=='damage_chain' and (type(raw[1]) is not int or not 1<=raw[1]<=32 or len(raw[2])!=raw[1]):
            fail('Chain count must match coefficient list',path+'.actions[%d]'%i)
        if action['type']=='ricochet_bursts' and (type(raw[1]) is not int or not 1<=raw[1]<=16 or not 1<=len(raw[2])<=16):
            fail('Ricochet bursts/hops exceed bounded limits',path+'.actions[%d]'%i)
        for j,value in enumerate(raw[1:],1):
            label=argument_label(action['type'],j,action['arguments'])
            if label=='目标策略' and value not in profile['policies']:fail('Unknown movement target policy',path)
            if label in ('持续回合','存续回合','延后回合') and (type(value) is not int or not 1<=value<=100):
                fail('Duration must be an integer in 1..100',path+'.actions[%d]'%i)
            if label=='伤害类型' and (type(value) is not int or value not in (0,1,2,3)):
                fail('Expected native damage type 0..3',path+'.actions[%d]'%i)
            if label in ('最大目标数','数量参数') and (type(value) is not int or value not in range(-1,33) or value==0):
                fail('Expected a bounded native target count',path+'.actions[%d]'%i)
            if label in ('最大层数','增量层数','连锁段数','发射次数','最多重施次数') and (type(value) is not int or not 0<=value<=100):
                fail('Expected a bounded integer count',path+'.actions[%d]'%i)
        # Strings that name concrete resources cannot become file paths/code.
        for val in _strings(action['arguments']):
            if val.startswith(('A_','S_')) and val not in cfg.get('avatar',{}) and val not in cfg.get('skill',{}):
                # Refresh/mark namespaces such as A_1019:normal are plain tokens.
                if ':' not in val:fail('Native unit/skill reference is missing',path+'.actions[%d]'%i)
    policies=[(key,settings.get(key),sid) for key in ('manualSummonPolicy','manualClonePolicy')]
    policies += [(key,a.get('settings',{}).get(key),a.get('origin',model['source']).split('/')[-1])
                 for a in skill['actions'] for key in ('manualSummonPolicy','manualClonePolicy')]
    for key,policy,policy_source in policies:
        if not policy:continue
        if policy.get('skillId')!=policy_source:fail('Original policy identity is compiler-managed',path+'.'+key+'.skillId')
        for name in ('maxAlive','ttlOwnerTurns','ttlOwnTurns'):
            if name in policy and (type(policy[name]) is not int or not 1<=policy[name]<=(16 if name=='maxAlive' else 100)):
                fail('Summon capacity/lifetime outside bounds',path+'.'+key+'.'+name)
        for name in ('apRatio','hpRatio','dePhRatio','deMaRatio','panelStatRatio'):
            if name in policy and (type(policy[name]) not in (int,float) or not .01<=policy[name]<=100):fail('Summon ratio outside bounds',path+'.'+key+'.'+name)
        if 'unitId' in policy and policy['unitId'] not in cfg.get('avatar',{}):fail('Missing summon unit',path+'.'+key+'.unitId')
        if 'actionType' in policy and policy['actionType'] not in (1,2,4):fail('Unsupported summon action type',path+'.'+key+'.actionType')
    for val in _strings(settings):
        if re.fullmatch(r'[AS]_\d+_\d+',val) and val not in cfg.get('avatar',{}) and val not in cfg.get('skill',{}):
            fail('Native resource reference does not exist',path+'.settings')
    for values in [settings]+[a.get('settings',{}) for a in skill['actions']]:
        for key in ('manualDamageMultiplier','manualDefenseBuffMultiplier','manualEffectMultiplier','captainSummonMultiplier'):
            if key in values and (type(values[key]) not in (int,float) or not .01<=values[key]<=100):fail('Mechanism multiplier outside .01..100',path+'.'+key)
        policy=values.get('summonCombatPolicy')
        if policy and (type(policy.get('owner_ap_ratio')) not in (int,float) or not .01<=policy['owner_ap_ratio']<=100):fail('Summon snapshot ratio outside bounds',path)
    _validate_links(skill,path)
    return source

def _strings(value):
    if isinstance(value,str):yield value
    elif isinstance(value,list):
        for v in value:yield from _strings(v)
    elif isinstance(value,dict):
        for v in value.values():yield from _strings(v)

def _link(index,count,path,before=None):
    if type(index) is not int or not 0<=index<count or (before is not None and index>=before):
        fail('Invalid or forward native action reference',path)

def _validate_links(skill,path):
    count=len(skill['actions']);settings=skill['nativeTemplate']['settings']
    for key in PARALLEL:
        values=settings.get(key)
        if values is not None and (not isinstance(values,list) or len(values)!=count):fail('Parallel action data length differs',path+'.'+key)
    for i,index in enumerate(settings.get('actionTargetLocks',[]) or []):
        if index is not None:_link(index,count,path+'.actionTargetLocks',i)
    for i,args in enumerate(settings.get('actionTargetPolicyArgs',[]) or []):
        if not isinstance(args,dict):continue
        for key in INDEX_KEYS:
            if key in args:_link(args[key],count,path+'.'+key,i)
        for key in LIST_INDEX_KEYS:
            for index in args.get(key,[]):_link(index,count,path+'.'+key,i)
    for group in settings.get('damageShareGroups',[]) or []:
        for index in group:_link(index,count,path+'.damageShareGroups')
    for key in ('skillUp','skillUpPaths'):
        values=settings.get(key) or []
        if values and not isinstance(values[0],list):values=[values]
        for item in values:
            if item:
                _link(item[0],count,path+'.'+key)
                if key=='skillUp' and len(item)==2:indices=[1];delta=item[1]
                elif len(item)==3:indices=item[1] if key=='skillUpPaths' else [item[1]];delta=item[2]
                else:fail('Invalid native growth record',path+'.'+key)
                value=[skill['actions'][item[0]]['type']]+skill['actions'][item[0]]['arguments']
                if not isinstance(indices,list) or not indices:fail('Growth path is empty',path+'.'+key)
                try:
                    for index in indices:
                        if type(index) is not int or index<0:raise ValueError()
                        value=value[index]
                except (IndexError,TypeError,ValueError):fail('Growth path references a missing field',path+'.'+key)
                if type(value) not in (int,float) or type(delta) not in (int,float) or abs(value+9*delta)>10_000_000:
                    fail('Growth must reference a numeric field within bounds',path+'.'+key)
    for i,action in enumerate(skill['actions']):
        spec=ACTION_REFS.get(action['type'])
        if spec:
            value=action['arguments'][spec[0]-1]
            for index in value if spec[1] else [value]:_link(index,count,path+'.actions[%d]'%i,i)
    for match in re.finditer(r'\{(?:rank|flat):(\d+):([0-9.]+)\}',settings.get('rankInfoTemplate','')):
        index=int(match[1]);_link(index,count,path+'.rankInfoTemplate')
        value=[skill['actions'][index]['type']]+skill['actions'][index]['arguments']
        try:
            for component in match[2].split('.'):value=value[int(component)]
        except (ValueError,TypeError,IndexError):fail('Description references a missing nested field',path+'.rankInfoTemplate')
        if type(value) not in (int,float):fail('Description references a nonnumeric field',path+'.rankInfoTemplate')

def compile_template(skill,base,sid):
    source=validate_template(skill,base)
    result=copy.deepcopy(skill['nativeTemplate']['settings'])
    result.update(id=sid,name=skill['name'],skill=[[a['type']]+copy.deepcopy(a['arguments']) for a in skill['actions']])
    if 'info' in source or skill['description']:result['info']=skill['description']
    result['modNativeSource']=source['id']
    result['modPassiveTrigger']=skill['nativeTemplate']['passiveTrigger']
    if 'abilityParameters' in skill['nativeTemplate']:
        result['nativeAbilityParameters']=copy.deepcopy(skill['nativeTemplate']['abilityParameters'])
    if 'scaleActionIndex' in skill['nativeTemplate']:result['modScaleActionIndex']=skill['nativeTemplate']['scaleActionIndex']
    if any('origin' in action or 'settings' in action for action in skill['actions']):
        result['nativeActionSources']=[a.get('origin',skill['nativeTemplate']['source']).split('/')[-1] for a in skill['actions']]
        result['nativeActionSettings']=[copy.deepcopy(a.get('settings')) for a in skill['actions']]
        for settings in result['nativeActionSettings']:
            for key in ('manualSummonPolicy','manualClonePolicy'):
                if settings and isinstance(settings.get(key),dict) and 'skillId' in settings[key]:settings[key]['skillId']=sid
    # Policy identities are instance identities; their dispatch provenance is
    # carried separately in modNativeSource and never forged by the author.
    for key in ('manualSummonPolicy','manualClonePolicy'):
        if isinstance(result.get(key),dict) and 'skillId' in result[key]:result[key]['skillId']=sid
    return result

def reorder_actions(skill,order,_deleting=False):
    """Remap all native action references before publishing a reordered copy."""
    count=len(skill['actions'])
    if (not _deleting and sorted(order)!=list(range(count))) or len(set(order))!=len(order) or any(i not in range(count) for i in order):fail('Invalid native reorder','actions')
    mapping={old:new for new,old in enumerate(order)};changed=copy.deepcopy(skill)
    changed['actions']=[changed['actions'][old] for old in order]
    s=changed['nativeTemplate']['settings']
    if 'scaleActionIndex' in changed['nativeTemplate']:changed['nativeTemplate']['scaleActionIndex']=mapping[changed['nativeTemplate']['scaleActionIndex']]
    for key in PARALLEL:
        if key in s:s[key]=[s[key][old] for old in order]
    if 'actionTargetLocks' in s:s['actionTargetLocks']=[mapping[v] if v is not None else None for v in s['actionTargetLocks']]
    for args in s.get('actionTargetPolicyArgs',[]) or []:
        if not isinstance(args,dict):continue
        for key in INDEX_KEYS:
            if key in args:args[key]=mapping[args[key]]
        for key in LIST_INDEX_KEYS:
            if key in args:args[key]=[mapping[v] for v in args[key]]
    for key in ('skillUp','skillUpPaths'):
        vals=s.get(key) or []
        vals=[vals] if vals and not isinstance(vals[0],list) else vals
        for val in vals:
            if val:val[0]=mapping[val[0]]
    if 'damageShareGroups' in s:s['damageShareGroups']=[[mapping[v] for v in group] for group in s['damageShareGroups']]
    for a in changed['actions']:
        spec=ACTION_REFS.get(a['type'])
        if spec:
            pos=spec[0]-1;v=a['arguments'][pos]
            a['arguments'][pos]=[mapping[x] for x in v] if spec[1] else mapping[v]
    if s.get('rankInfoTemplate'):s['rankInfoTemplate']=re.sub(r'\{(rank|flat):(\d+):',lambda m:'{'+m[1]+':'+str(mapping[int(m[2])])+':',s['rankInfoTemplate'])
    _validate_links(changed,'skill')
    skill.clear();skill.update(changed)

def remove_action(skill,index):
    if type(index) is not int or not 0<=index<len(skill['actions']):fail('Invalid action index','actions')
    if len(skill['actions'])<=1:fail('Keep at least one mechanism action','actions')
    try:reorder_actions(skill,[i for i in range(len(skill['actions'])) if i!=index],True)
    except KeyError:fail('Action is still referenced by targets, growth, conditions, effects or descriptions; remove those references first','actions')
