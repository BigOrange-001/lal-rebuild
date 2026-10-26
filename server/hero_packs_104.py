"""Built-in revisions from the two authored 1.0.3 projects; no save-local mods.

Only skill slots are replaced. Existing card IDs, artwork and progression stay
stable. Summon definitions use a private A_2 namespace, outside hero pools.
"""
from __future__ import annotations
import copy
import json
from pathlib import Path
from captain_strength import _update_growth, _update_text
from skill_balance_overlay import _get, _set, _pct
from skill_output_104 import output_paths, STATUS_FIELDS
from mod_effects import compile_skill

ROOT = Path(__file__).resolve().parents[1] / 'config/reconstruction/hero-packs-104'
SKIN_FAMILIES = {1134,1103,1139,1132,1223,1138,1227,1309,1222,1137}
SLOTS = {'normal':10,'captain':11,'passive':13}


def scale_outputs(row, rate):
    scaled=set(); changes={}; unchanged=set()
    for i,action in enumerate(row['skill']):
        for path in output_paths(action):
            old=_get(action,path); _set(action,path,old*rate)
            scaled.add((i,*path)); changes.setdefault(_pct(old),set()).add(_pct(old*rate))
        for j in STATUS_FIELDS.get(action[0],()):
            if j<len(action) and type(action[j]) in (int,float):unchanged.add(_pct(action[j]))
        if action[0]=='mod_step' and action[1] in ('summon','buff'):
            for j in ((12,) if action[1]=='summon' else (7,)):
                unchanged.add(_pct(action[j]))
    _update_growth(row,scaled,rate)
    _update_text(row,changes,unchanged)


def compile_builtin(skill,sid,resolve):
    model=skill.get('model')
    if model=='effect-sequence-v1':return compile_skill(skill,sid,resolve)
    if model=='native-template-v1':
        row=copy.deepcopy(skill['nativeTemplate']['settings'])
        if any(a.get('settings') for a in skill['actions']):
            raise ValueError('Per-action native settings require an explicit runtime port')
        row.update(id=sid,name=skill['name'],info=skill['description'],
                   skill=[[a['type']]+copy.deepcopy(a['arguments']) for a in skill['actions']],
                   builtin_native_source_104=skill['nativeTemplate']['source'].rsplit('/',1)[1],
                   modPassiveTrigger=skill['nativeTemplate']['passiveTrigger'])
        return row
    actions=[]; policies=[]; maximum=[]
    for action in skill['actions']:
        kind=action['type']; effect=resolve(action.get('effect'),('effect',),'effect',True) or ''
        if kind=='damage':raw=[kind,action['coefficient'],1 if action['damageType']=='physical' else 2,effect]
        elif kind=='cure':raw=[kind,action['coefficient'],effect]
        else:raise ValueError('Unsupported built-in DSL action: '+kind)
        actions.append(raw);policies.append(action.get('targetPolicy',skill['targetPolicy']))
        maximum.append(action.get('maxTargets',1))
    return dict(id=sid,name=skill['name'],info=skill['description'],res=sid,
                pl=[skill['warmup'],skill['cooldown'],skill['range'],0,skill.get('aoe',0),0 if skill.get('banStand',True) else 1],
                skill=actions,skillUp=[[u['action'],1,u['perLevel']] for u in skill['upgrades']],
                targetPolicy=skill['targetPolicy'],actionTargetPolicies=policies,
                actionTargetMaxTargets=maximum,rankInfoTemplate=skill.get('rankInfoTemplate',skill['description']))


def apply_hero_packs_104(document):
    cfg=document.get('cfg',document)
    if cfg.get('hero_packs_104'):return document
    sources=[]; imported=[]; summoned=[]; patched=[]
    def bind_quality(row,quality):
        for index in SLOTS.values():
            sid=row['pl'][index]
            if not sid or sid not in imported:continue
            target=sid.rsplit('_',1)[0]+'_'+str(quality)
            if target not in cfg['skill']:
                cfg['skill'][target]=copy.deepcopy(cfg['skill'][sid])
                cfg['skill'][target]['id']=target
                imported.append(target)
            row['pl'][index]=target
    for package_index,key in enumerate(('nine','zongzi')):
        project=json.loads((ROOT/(key+'.json')).read_text('utf-8'))
        data=project['data']; skills=data['skills']['skills']; heroes=data['heroes']['heroes']
        refs={'self:skill/'+s['id']:'S_9104%d%03d_6'%(package_index,i) for i,s in enumerate(skills)}
        for i,h in enumerate(heroes):
            refs['self:hero/'+h['id']+'/'+h['variant']]='A_2904%d%02d_%d'%(package_index,i,h['quality']) if h['unitType']=='summon' else 'A_1212_6'
        def resolve(ref,*_):
            if ref is None:return None
            if ref.startswith('builtin:'):return ref.rsplit('/',1)[1]
            return refs[ref]
        for s in skills:
            sid=refs['self:skill/'+s['id']]
            if sid in cfg['skill']:raise ValueError('Built-in skill ID collision: '+sid)
            row=compile_builtin(s,sid,resolve)
            row['builtin_pack_104']=key;row['builtin_skill_key_104']=s['id']
            if key=='nine':scale_outputs(row,2/3)
            cfg['skill'][sid]=row;imported.append(sid)
        for h in heroes:
            aid=refs['self:hero/'+h['id']+'/'+h['variant']]
            if h['unitType']!='summon':
                # The existing calibrated skin card supplies the panel template,
                # not the editor project's low-stat draft or placeholder portrait.
                targets=[a for a in cfg['avatar'] if a.startswith('A_1212_')]
                for target in targets:
                    row=cfg['avatar'][target]
                    row['pl'] += [None] * max(0,14-len(row['pl']))
                    for slot,index in SLOTS.items():row['pl'][index]=resolve(h['skills'][slot])
                    row['skill_diff']=cfg['skill'][row['pl'][13]].get('modPassiveTrigger',0)
                    bind_quality(row,int(target.rsplit('_',1)[1]))
                    row['builtin_pack_104']=key
                    patched.append(target)
                continue
            if aid in cfg['avatar']:raise ValueError('Summon ID collision: '+aid)
            pl=[v for stat in ('health','attack','physicalDefense','magicDefense') for v in (h['baseStats'][stat],h['growth'][stat])]
            pl += [h['speed'],h['attackRange'],resolve(h['skills']['normal']),resolve(h['skills']['captain']),resolve(h['presentation']['basicAttackEffect']),resolve(h['skills']['passive'])]
            row=dict(id=aid,name=h['name'],res=resolve(h['presentation']['portrait']),
                     tl=[{'attack':1,'tank':2,'assist':3}[h['signType']],{'forward':1,'sly':2,'stand':3,'cunning':4}[h['actionType']],{'physical':1,'magic':2,'true':3}[h['damageType']],0,h['levelCap'],1,0,0,[],0,1],
                     pl=pl,modUnitType='summon',builtin_pack_104=key,info=h['description'])
            row['skill_diff']=cfg['skill'].get(pl[13],{}).get('modPassiveTrigger',0)
            bind_quality(row,h['quality'])
            cfg['avatar'][aid]=row;summoned.append(aid)
        for patch in data['patches']['patches']:
            aid=resolve(patch['target']);row=cfg['avatar'][aid]
            row['pl'] += [None] * max(0,14-len(row['pl']))
            for op in patch['operations']:
                if op['op']!='replace' or op['path'] not in ('skills.normal','skills.captain','skills.passive'):raise ValueError('Unexpected built-in patch')
                row['pl'][SLOTS[op['path'].split('.')[1]]]=resolve(op['value'])
            if any(op['path']=='skills.passive' for op in patch['operations']):
                row['skill_diff']=cfg['skill'].get(row['pl'][13],{}).get('modPassiveTrigger',0)
            bind_quality(row,int(aid.rsplit('_',1)[1]))
            row['builtin_pack_104']=key
            if aid.startswith('A_1227_'):row['name']='白娘子'
            patched.append(aid)
        sources.append(project['builtinImport104'])
    skins=cfg['system_simple'].setdefault('skin_hero_ids',[])
    for aid,row in cfg['avatar'].items():
        if int(aid.split('_')[1]) in SKIN_FAMILIES:
            if aid not in skins:skins.append(aid)
            row['hero_category_104']='skin'
    skins.sort()
    # The authored 1.0.3 skin catalogue also includes Super Saiyan Wukong (A_1311).
    for aid in cfg['avatar']:
        if aid.startswith('A_1311_') and aid not in skins:skins.append(aid)
    cfg['summon_calibration']['normalization']['skin_hero_ids']=sorted(skins)
    calibration=cfg['summon_calibration']
    advanced={c['id']:c['weight'] for c in calibration['pools']['advanced']['qualities']['orange']['cards']}
    multiplier=calibration['normalization']['vip_orange_skin_weight_multiplier']
    for pool in calibration['pools'].values():
        for quality in pool['qualities'].values():
            for card in quality['cards']:
                if card['id'] in cfg['avatar']:card['name']=cfg['avatar'][card['id']]['name']
    for card in calibration['pools']['vip']['qualities']['orange']['cards']:
        if card['id'] in skins and card['id'] in advanced:card['weight']=advanced[card['id']]*multiplier
    cfg['ploy_system_simple']['extract_avatar']['activity_pool']=[
        {'kind':'avatar','aid':c['id'],'weight':c['weight']}
        for q in calibration['pools']['vip']['qualities'].values() if q['probability_percent']>0 for c in q['cards']]
    cfg['hero_packs_104']=dict(sources=sources,skills=imported,summons=summoned,heroes=sorted(patched),nine_rate=2/3)
    return document
