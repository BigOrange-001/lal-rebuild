"""Bounded generic passive events; synchronous settlement with explicit chain guards."""
def has_buff(battle,unit,kind):
    if kind=='root':return battle._rooted(unit)
    if kind=='timed_bless':
        buff=battle._buff(unit,'bless')
        return buff is not None and buff.value>0
    return battle._buff(unit,kind) is not None


def emit(battle,owner,event,source=None,target=None,amount=0,overheal=0):
    if owner is None:return False
    skill=owner.get('skillB') or {};gate=skill.get('modCondition') or {}
    if not skill.get('modEffectSequence') or gate.get('kind')!='event' or gate.get('event')!=event:return False
    if owner.get('hp',0)<=0 and event!='death':return False
    depth=getattr(battle,'_mod_event_depth',0)
    if owner.get('_mod_event_busy') or depth>=8 or depth and not gate.get('allowChain',False):return False
    other=target if source is owner else source
    same=other is not None and battle._team_number(other)==battle._team_number(owner)
    relation=gate.get('relation','any')
    if relation=='self' and other is not owner or relation=='ally' and (not same or other is owner) or relation=='enemy' and (other is None or same):return False
    summon=other is not None and (battle._get_type(other)==2 or other.get('summoned') or other.get('unitType')=='summon' or battle._buff(other,'summon') is not None)
    if gate.get('unitType')=='summon' and not summon or gate.get('unitType')=='hero' and (other is None or summon or battle._get_type(other)!=1):return False
    if amount<gate.get('minAmount',0) or max(0,owner.get('hp',0))/max(1,owner.get('hp_max',1))>gate.get('hpBelow',1):return False
    if gate.get('requiredBuff') and not has_buff(battle,owner,gate['requiredBuff']):return False
    if gate.get('absentBuff') and has_buff(battle,owner,gate['absentBuff']):return False
    if 'otherHpBelow' in gate and (other is None or max(0,other.get('hp',0))/max(1,other.get('hp_max',1))>gate['otherHpBelow']):return False
    if gate.get('otherRequiredBuff') and (other is None or not has_buff(battle,other,gate['otherRequiredBuff'])):return False
    radius=gate.get('nearbyRadius',600)
    near=[u for u in battle.a+battle.b if u is not owner and u.get('hp',0)>0 and u.get('line')==owner.get('line') and abs(u.get('pos',0)-owner.get('pos',0))<=radius]
    friendly=[u for u in near if battle._team_number(u)==battle._team_number(owner)]
    summoned=[u for u in friendly if battle._get_type(u)==2 or u.get('summoned') or u.get('unitType')=='summon' or battle._buff(u,'summon') is not None]
    if len(near)-len(friendly)<gate.get('nearbyEnemies',0) or len(friendly)<gate.get('nearbyAllies',0) or len(summoned)<gate.get('nearbySummons',0):return False
    turn=owner.get('_mod_owner_turn',0)
    if turn<owner.get('_mod_event_ready',(skill.get('pl') or [0])[0]):return False
    round_=getattr(battle,'round_index',0)
    if owner.get('_mod_event_round')!=round_:owner.update(_mod_event_round=round_,_mod_event_count=0)
    if owner.get('_mod_event_count',0)>=gate.get('maxPerRound',1):return False
    every=gate.get('everyEvents',1)
    if every>1:
        owner['_mod_filtered_events']=owner.get('_mod_filtered_events',0)+1
        if owner['_mod_filtered_events']<every:return False
    enemies=[u for u in (battle.b if battle._team_number(owner)==1 else battle.a) if u.get('hp',0)>0]
    if not enemies and all(a[1] in ('damage','push','move') for a in skill.get('skills',[])):return False
    previous=owner.get('_mod_event');owner['_mod_event']={'event':event,'source':source,'target':target,'amount':max(0,amount),'overheal':max(0,overheal),'sourceAlly':source is not None and battle._team_number(source)==battle._team_number(owner),'targetAlly':target is not None and battle._team_number(target)==battle._team_number(owner)}
    from battle_mod_effects import targets
    allies=[u for u in (battle.a if battle._team_number(owner)==1 else battle.b) if u.get('hp',0)>0]
    first=skill['skills'][0]
    if first[2] not in ('self','all_allies','ally_radius') and not targets(owner,enemies,allies,first,{},abs(skill['pl'][2])):
        owner['_mod_event']=previous;return False
    if depth==0:battle._mod_event_budget=64
    if battle._mod_event_budget<=0:owner['_mod_event']=previous;return False
    battle._mod_event_budget-=1;battle._mod_event_depth=depth+1;owner['_mod_event_busy']=True
    owner['_mod_event_count']=owner.get('_mod_event_count',0)+1
    owner['_mod_event_ready']=turn+skill['pl'][1]
    owner['_mod_filtered_events']=0
    try:return battle._apply_native_skill(owner,enemies,'skillB')
    finally:owner['_mod_event_busy']=False;owner['_mod_event']=previous;battle._mod_event_depth=depth
