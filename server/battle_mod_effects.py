"""Reference execution of compiler-owned effect-sequence-v1 rows."""
from __future__ import annotations


def condition_ready(battle,unit,skill):
    condition=skill.get('modCondition') or {}
    if condition.get('kind')=='event':return unit.get('_mod_event') is not None
    from battle_mod_events import has_buff
    return condition.get('kind')!='absent_buff' or not has_buff(battle,unit,condition['buff'])


def targets(owner,enemies,allies,action,anchors,reach):
    selector=action[2]
    anchor=anchors.get(action[3]) if action[3]>=0 else None
    if selector in ('event_source','event_target'):
        event=owner.get('_mod_event') or {};unit=event.get('source' if selector=='event_source' else 'target')
        good=action[1]=='heal' or action[1]=='buff' and action[8] not in ('weak','sunder','stun','curse')
        same=event.get('sourceAlly' if selector=='event_source' else 'targetAlly',False)
        return [unit] if unit is not None and unit.get('hp',0)>0 and same==good else []
    if selector=='previous':
        return [u for u in (anchor or {}).get('units',[]) if u.get('hp',0)>0]
    if selector in ('self','ally_radius','all_allies'):
        pool=[u for u in allies if u.get('hp',0)>0]
    else:pool=[u for u in enemies if u.get('hp',0)>0]
    if selector=='self':return [owner] if owner.get('hp',0)>0 else []
    if selector in ('all_allies','all_enemies'):return pool
    if selector in ('lane_lowest_hp','lane_front'):
        pool=[u for u in pool if u.get('line')==owner.get('line') and abs(u['pos']-owner['pos'])<=reach]
        if not pool:return []
        if selector=='lane_lowest_hp':
            return [min(pool,key=lambda u:(u['hp']/max(1,u['hp_max']),abs(u['pos']-owner['pos'])))]
        return [min(pool,key=lambda u:(abs(u['pos']-owner['pos']),u['pos']))]
    if selector=='enemy_radius' and anchor is None:return []
    line=(anchor or {}).get('line',owner['line'])
    pos=(anchor or {}).get('pos',owner['pos'])
    excluded=(anchor or {}).get('units',[]) if action[15] else []
    return [u for u in pool if u.get('line')==line and abs(u['pos']-pos)<=action[4]
            and not any(u is other for other in excluded)]


def execute(battle,owner,enemies,allies,skill,action,index,context):
    if len(action) not in (18,20):raise ValueError('Malformed compiled effect step')
    anchors=context.setdefault('mod_effect_anchors',{})
    # Refresh allies after a preceding summon so that the new unit receives buffs.
    allies=[u for u in owner.get('_team',allies) if u.get('hp',0)>0]
    selected=targets(owner,enemies,allies,action,anchors,abs(skill['pl'][2]))
    anchors[index]={'units':list(selected),'line':selected[0]['line'] if selected else owner['line'],
                    'pos':selected[0]['pos'] if selected else owner['pos']}
    kind=action[1]
    event=owner.get('_mod_event') or {}
    event_value=event.get('amount',0)*action[18]+event.get('overheal',0)*action[19] if len(action)==20 else 0
    if kind=='summon':
        family=str(skill.get('skid',''))+':'+str(index)
        existing=[u for u in allies if u.get('_effect_summon_owner')==owner.get('_owner_token')
                  and u.get('_effect_summon_family')==family]
        unit=battle._spawn_summon(owner,action[11],action[12],action[13],bounded=True)
        if unit:
            while len(existing)>=action[14]:
                expired=existing.pop(0);expired['hp']=0
            ratio=action[12]
            unit['de_ph']=max(0,int(battle._get_de_ph(owner)*ratio))
            unit['de_ma']=max(0,int(battle._get_de_ma(owner)*ratio))
            for key in ('hit','flee','crit','tough'):
                unit['new_4attrs'][key]=max(0,int(battle._stat_buff(owner,key)*ratio))
            unit['_effect_summon_owner']=owner.get('_owner_token')
            unit['_effect_summon_family']=family
        return
    for unit in selected:
        if owner.get('_mod_event') is not None:
            good=kind=='heal' or kind=='buff' and action[8] not in ('weak','sunder','stun','curse')
            if good!=(battle._team_number(unit)==battle._team_number(owner)):continue
        if kind=='heal':
            value=int(battle._get_damage(owner)*action[5]+owner['hp_max']*action[6]+event_value)
            battle._injured(unit,value,4,source=owner)
        elif kind=='damage':
            if len(action)==20:
                coefficient=action[5]+event_value/max(1,battle._get_damage(owner))
                if coefficient<=0:continue
                battle._native_damage(owner,unit,coefficient/.3 if action[16]==3 else coefficient,action[16])
            elif action[16]==3:battle._injured(unit,max(0,int(battle._get_damage(owner)*action[5])),3,source=owner)
            else:battle._native_damage(owner,unit,action[5],action[16])
        elif kind=='buff':
            value=action[7]
            if action[8]=='shield':value=int(battle._get_damage(owner)*action[5]+owner['hp_max']*action[6]+value+event_value)
            battle._add_buff(unit,'bless' if action[8]=='timed_bless' else action[8],action[9],1 if action[8]=='timed_bless' else value)
        elif kind=='push':battle._check_move(unit,False,int(action[10]),forced=True)
        elif kind=='move':
            distance=max(0,abs(unit['pos']-owner['pos'])-40)
            if action[10]>0:distance=min(distance,int(action[10]))
            direction=1 if unit['pos']>owner['pos'] else -1
            if battle._rooted(owner):continue
            owner['pos']=battle._get_final_pos(battle._team_number(owner),owner['line'],owner['pos']+direction*distance)
