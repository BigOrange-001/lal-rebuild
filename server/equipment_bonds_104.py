"""Personal equipment affinities layered after hero bonds, before output balance."""
from __future__ import annotations
import copy
import hashlib
import itertools
import json
from pathlib import Path
from captain_strength import _update_growth, _update_text
from skill_balance_overlay import _get, _set, _pct

PLAN=Path(__file__).resolve().parents[1]/'config/reconstruction/equipment-bonds-1.0.4.json'


def equipped_bonds(cfg,aid,eids):
    owned=set(eids)
    return [r for r in cfg.get('system_simple',{}).get('equipment_bonds_104',{}).get(aid,[]) if r['equipment'] in owned]


def profile_equipment_bonds(cfg,profile,iid,hero_only=False):
    if hero_only:return []
    aid=str(profile.get('avatars',{}).get(iid,{}).get('aid',iid)).split('|')[0]
    selected=int(profile.get('attrs',{}).get('team_num',0))
    teams=profile.get('team',[])
    ordered=([teams[selected]] if 0<=selected<len(teams) else [])+[t for i,t in enumerate(teams) if i!=selected]
    slot=next((t.index(iid) for t in ordered if iid in t),None)
    groups=profile.get('as_equips',[])
    if slot is None or slot>=len(groups):return []
    eids=[profile.get('my_equips',{}).get(eq,{}).get('eid') for eq in groups[slot] or []]
    return equipped_bonds(cfg,aid,eids)


def skill_id(cfg,aid,source,bonds):
    key='|'.join(sorted(r['equipment'] for r in bonds))
    return cfg.get('system_simple',{}).get('equipment_skill_variants_104',{}).get(aid,{}).get(source,{}).get(key,source)


def output_rate(cfg,aid,keys):
    # Kept for native/manual compatibility; benefits live in the selected skill.
    return 1.0



def part_for_skill(row,effect):
    return dict(effect,**effect.get('reworks',{}).get(row.get('name'),{}))


def apply_part(row,effect):
    """Do not reinterpret an absent component as a different damage/heal effect.
    Hero-bond additions/scaling retain the original prefix; full rewrites do not.
    """
    effect=part_for_skill(row,effect)
    index=effect['index'];factor=1+effect['strength']
    if isinstance(index,str):
        if not any(a[:2]==['manual_ability',effect['manual_kind']] for a in row['skill']):return False
        row.setdefault('equipment_parts_104',{})[index]=factor
        return True
    signature=effect['signature']
    if [a[0] for a in row['skill'][:len(signature)]]!=signature:return False
    action=row['skill'][index];path=tuple(effect['path'])
    value=_get(action,path)
    if type(value) not in (float,int) or value<=0:raise ValueError('Equipment component changed: '+effect['part'])
    # Update a printed coefficient only when no untouched value shares it.
    unchanged=set()
    def visit(node,position=()):
        if type(node) in (int,float) and position!=(index,*path):unchanged.add(_pct(node))
        elif isinstance(node,list):
            for i,child in enumerate(node):visit(child,(*position,i))
    visit(row['skill'])
    _set(action,path,value*factor)
    _update_text(row,{_pct(value):{_pct(value*factor)}},unchanged)
    _update_growth(row,{(index,*path)},factor)
    return True


def append_effect(row,effect):
    offset=len(row['skill']);row['skill'].append(copy.deepcopy(effect['action']))
    for attr,default,value in (
        ('actionTargetPolicies',None,effect['policy']),('actionTargetMaxTargets',1,1),
        ('actionTargetLocks',None,None),('actionTargetGroups',None,None),
        ('actionTargetPolicyArgs',None,{'effectRange':9999,'heroOnly':True} if effect['policy']=='ally_all_lowest_hp_ratio' else {'effectRange':9999})):
        values=list(row.get(attr) or []);values.extend([default]*(offset-len(values)));values.append(value);row[attr]=values

def apply_equipment_bonds_104(document):
    cfg=document.get('cfg',document);simple=cfg['system_simple']
    if simple.get('equipment_bonds_schema_104'):return document
    plan=json.loads(PLAN.read_text('utf-8'))
    families={f for b in simple['bonds_104'] for f in b['families']}
    eligible={a for a in cfg['avatar'] if a.endswith('_6') and a.rsplit('_',1)[0] in families}
    if set(plan['heroes'])!=eligible:raise ValueError('Equipment bonds must cover exactly the named orange hero catalogue')
    exclusive_ids=set(simple['equipment_roll_policy']['exclusive_ids'])
    if {r['equipment'] for r in plan['exclusive']}!=exclusive_ids:raise ValueError('Exclusive equipment catalogue mismatch')
    definitions={};variants={};generated=[]
    for aid,design in plan['heroes'].items():
        eids=design['equipment']
        if len(eids)!=2 or len(set(eids))!=2:raise ValueError('Each orange hero needs two ordinary affinities')
        if len({cfg['equip'][e]['slot'] for e in eids})!=2:raise ValueError('Ordinary affinities must be wearable together')
        definitions[aid]=[]
        for eid in eids:
            equip=cfg['equip'][eid]
            if equip['quality'] not in (5,6) or eid in exclusive_ids or equip['type']==6:raise ValueError('Invalid ordinary affinity: '+eid)
            effect=copy.deepcopy(next(r for r in design['affinities'] if r['equipment']==eid))
            definitions[aid].append(dict(effect,kind='ordinary',rate=0,
                power_budget=.12 if equip['quality']==5 else .08,name=effect['skill_name']+'·'+effect['part']))
        if len({(r['slot'],str(r['index']),str(r['path'])) for r in definitions[aid]})!=2:
            raise ValueError('The two affinities must target different skill parts: '+aid)
    for design in plan['exclusive']:
        for aid in design['heroes']:
            if aid not in eligible:raise ValueError('Exclusive owner must be an eligible orange hero: '+aid)
            definitions[aid].append(dict(copy.deepcopy(design),kind='exclusive',rate=0))
    for aid,rows in definitions.items():
        base=cfg['avatar'][aid]['pl']
        sources={base[i] for i in (10,11,13) if len(base)>i and base[i]}
        normal_sources={base[10]}
        captain_sources={base[11]}
        for bindings in simple.get('bond_skill_variants_104',{}).get(aid,{}).values():
            sources.update(bindings.values())
            if bindings.get('skill'):normal_sources.add(bindings['skill'])
            if bindings.get('leader_skill'):captain_sources.add(bindings['leader_skill'])
        variants[aid]={sid:{} for sid in sources}
        for count in range(1,len(rows)+1):
            for selected in itertools.combinations(rows,count):
                if len({cfg['equip'][r['equipment']]['slot'] for r in selected})!=count:continue
                key='|'.join(sorted(r['equipment'] for r in selected))
                for source in sorted(sources):
                    slot='normal' if source in normal_sources else 'captain' if source in captain_sources else 'passive'
                    effects=[r for r in selected if r.get('slot','normal')==slot]
                    if not effects:continue
                    row=copy.deepcopy(cfg['skill'][source])
                    row['equipment_base_action_count_104']=len(row['skill'])
                    applied_effects=[]
                    for effect in effects:
                        if effect['kind']=='ordinary':
                            effect=part_for_skill(row,effect)
                            if not apply_part(row,effect):continue
                        else:append_effect(row,effect)
                        applied_effects.append(effect)
                        row.setdefault('equipment_notes_104',[]).append('装备·'+effect['name']+'：'+effect['info'])
                    if not applied_effects:continue
                    sid='S_96'+str(int(hashlib.sha256(f'{aid}:{source}:{key}'.encode()).hexdigest()[:12],16))+'_6'
                    if sid in cfg['skill']:raise ValueError('Equipment skill collision')
                    row['id']=sid
                    row['equipment_source_skill_104']=row.get('manualClonePolicy',{}).get('skillId') or row.get('manualSummonPolicy',{}).get('skillId') or source
                    row['equipment_output_rate_104']=1
                    row['equipment_bonds_104']=key.split('|')
                    row['bond_power_rate_104']=float(row.get('bond_power_rate_104',1))*(1+sum(e.get('power_budget',.12) for e in applied_effects))
                    for field in ('manualClonePolicy','manualSummonPolicy'):
                        if isinstance(row.get(field),dict):row[field]['skillId']=sid
                    cfg['skill'][sid]=row;generated.append(sid);variants[aid][source][key]=sid
    simple['equipment_bonds_104']=definitions
    simple['equipment_skill_variants_104']=variants
    simple['equipment_bonds_schema_104']=plan['schema']
    cfg['equipment_bonds_104']={'skills':generated,'heroes':len(eligible),'ordinary':2*len(eligible),'exclusive':len(plan['exclusive'])}
    return document
