"""Independent equipment channel used by both offline battle engines.

Snapshots carry no executable code. Entries are generated from owned relics;
the Abyss mode builds clean standardized snapshots without this channel.
"""
from contextlib import contextmanager
from combat_math import to_int


def effects(unit):
    if not unit or unit.get('abyss_standardized'): return []
    return unit.get('equip_passives') or []


def effect(unit, kind):
    return next((e for e in effects(unit) if e['id']==kind),None)


def trace(battle, event, owner, target=None, **fields):
    if not hasattr(battle,'equip_events'): battle.equip_events=[]
    battle.equip_events.append({'event':event,'round':battle.round_index,
        'owner':owner.get('_owner_token',owner.get('aid')),
        'target':(target or owner).get('_owner_token',(target or owner).get('aid')),**fields})


@contextmanager
def origin(battle, name):
    previous = getattr(battle,'_equip_origin',None)
    battle._equip_origin = name
    try: yield
    finally: battle._equip_origin = previous


def initialize(battle):
    if getattr(battle,'_equip_initialized',False): return
    battle._equip_initialized = True
    battle.equip_events = []
    for roster in (battle.a,battle.b):
        for unit in roster: unit['_team'] = roster
        captains = [u for u in roster if u.get('leader') and u.get('hp',0)>0]
        for captain in captains:
            for kind in (15,16):
                affix = effect(captain,kind)
                if not affix: continue
                for target in roster:
                    if kind==15:
                        target['_equip_reduction'] = 1-(1-target.get('_equip_reduction',0))*(1-affix['value'])
                    else:
                        target['ap'] = int(target['ap']*(1+affix['value']))
                    trace(battle,'captain_aura',captain,target,kind=kind,value=affix['value'])
        for unit in roster:
            for affix in effects(unit):
                kind = affix['id']
                if kind==1:
                    shield(battle,unit,unit,int(unit['hp_max']*affix['value']),3,'entry_shield')
                elif kind==19 and unit.get('leader') and unit.get('leader_skill'):
                    preparation = int((unit['leader_skill'].get('pl') or [0])[0])
                    unit['_skill_cd_leader'] = max(0,preparation-2)
                    trace(battle,'leader_preparation',unit,value=unit['_skill_cd_leader'])


def shield(battle, source, target, amount, duration, event):
    with origin(battle,'relic_shield'):
        battle._add_buff(target,'shield',duration,amount,source=source)
    trace(battle,event,source,target,amount=amount,duration=duration)


def amplify_healing(source, amount):
    affix = effect(source,14)
    return int(amount*(1+affix['value'])) if affix else amount


def amplify_shield(source, kind, amount):
    return amplify_healing(source,amount) if kind=='shield' else amount


def active_normal(battle, source):
    stack = getattr(battle,'_equip_casts',[])
    manual = getattr(battle,'_context',lambda owner:None)(source)
    if manual and manual.get('kind')!='active':return None
    if source and stack and stack[-1]['owner'] is source and stack[-1]['slot']=='skill' and not source.get('abyss_standardized'):
        return stack[-1]
    return None


@contextmanager
def casting(battle, owner, slot):
    if not hasattr(battle,'_equip_casts'): battle._equip_casts=[]
    entry = {'owner':owner,'slot':slot,'affix':(owner.get(slot) or {}).get('abyss_relic_A'), 'hit':set()}
    existing = {id(v) for u in battle.a+battle.b for v in (u.get('_ability') or {}).values() if isinstance(v,dict)} if entry['affix'] else set()
    battle._equip_casts.append(entry)
    try: yield
    finally:
        if entry['affix'] and slot=='skill':
            for unit in battle.a+battle.b:
                for key,value in (unit.get('_ability') or {}).items():
                    if isinstance(value,dict) and id(value) not in existing and (
                        (unit is owner and key in ('zone','channel')) or
                        (isinstance(key,tuple) and key[0]=='bomb' and value.get('owner') is owner)):
                        value['_equip_affix'] = entry['affix']
                        value['_equip_hits'] = entry['hit']
        battle._equip_casts.pop()


@contextmanager
def delayed_cast(battle, owner, data):
    if not data.get('_equip_affix'):
        yield
        return
    if not hasattr(battle,'_equip_casts'):battle._equip_casts=[]
    battle._equip_casts.append({'owner':owner,'slot':'skill','affix':data['_equip_affix'],
                               'hit':data.setdefault('_equip_hits',set())})
    try: yield
    finally: battle._equip_casts.pop()


def conversion(battle, source):
    ctx = active_normal(battle,source)
    affix = ctx['affix'] if ctx else None
    return affix['value'] if affix and affix['id']==20 else 0


def modify_damage(battle, source, target, amount, damage_type, dot_kind):
    before = amount
    if source:
        affix = effect(source,2)
        if affix and battle.round_index==0: amount=to_int(amount*(1+affix['value']))
        affix = effect(source,17)
        if affix:
            count = sum(u is not source and u.get('hp',0)>0 and u.get('line')==source.get('line')
                        for u in (battle.a if battle._team_number(source)==1 else battle.b))
            amount = to_int(amount*(1+affix['value']*count))
        ctx = active_normal(battle,source)
        affix = ctx['affix'] if ctx else None
        if affix and damage_type in (1,2,3) and not dot_kind:
            ratio = target.get('hp',0)/max(1,target.get('hp_max',1))
            if affix['id']==8 and ratio>.5 or affix['id']==9 and ratio<.5:
                amount = to_int(amount*(1+affix['value']))
    reduction = target.get('_equip_reduction',0) if not target.get('abyss_standardized') else 0
    amount = to_int(amount*(1-reduction)) if reduction else amount
    if amount!=before:trace(battle,'damage_adjust',source or target,target,before=before,after=amount)
    return amount


def shield_multiplier(source):
    affix = effect(source,12)
    return 1+affix['value'] if affix else 1


def on_event(battle, owner, event):
    if event!='dodge' or not owner or owner.get('hp',0)<=0: return
    affix = effect(owner,6)
    if not affix: return
    state = owner.setdefault('_equip_dodge',{'round':-1,'count':0})
    if state['round']!=battle.round_index: state.update(round=battle.round_index,count=0)
    if state['count']>=2: return
    state['count'] += 1
    # No duration was authored for Windstep; use the native default 2 turns.
    shield(battle,owner,owner,int(owner['hp_max']*affix['value']),2,'dodge_shield')


def revive(battle, target):
    affix = effect(target,4)
    if not affix or target.get('_equip_revived'): return False
    target['_equip_revived'] = True
    target['hp'] = max(1,int(target['hp_max']*affix['value']))
    battle._remove_all_debuff(target)
    trace(battle,'revive',target,amount=target['hp'])
    return True


def after_damage(battle, source, target, health_damage, shield_damage, damage_type, dot_kind):
    total = max(0,health_damage)+max(0,shield_damage)
    affix = effect(target,3)
    if affix and not target.get('_equip_recovered') and 0<target.get('hp',0)<target['hp_max']*.5:
        target['_equip_recovered'] = True
        amount = target['hp_max']-target['hp']
        target['hp'] = target['hp_max']
        trace(battle,'full_recovery',target,amount=amount)
        if affix['shield_rate']:
            shield(battle,target,target,int(target['hp_max']*affix['shield_rate']),3,'recovery_shield')
    if source is None or total<=0: return
    affix = effect(source,7)
    if affix and source.get('hp',0)>0:
        amount = int(total*affix['value'])
        with origin(battle,'relic_lifesteal'):
            healed = -battle._injured(source,amount,4,source=source)
        trace(battle,'lifesteal',source,amount=amount,healed=healed,source_tag='relic_lifesteal')
    affix = effect(target,5)
    if (affix and damage_type in (1,2,3) and not dot_kind and
        getattr(battle,'_equip_origin',None)!='relic_reflect' and
        source.get('hp',0)>0 and battle._team_number(source)!=battle._team_number(target)):
        amount = int(total*affix['value'])
        trace(battle,'reflect',target,source,amount=amount,source_tag='relic_reflect')
        with origin(battle,'relic_reflect'):
            battle._injured(source,amount,3,source=target)
    ctx = active_normal(battle,source)
    affix = ctx['affix'] if ctx else None
    if (not affix or dot_kind or damage_type not in (1,2,3) or
        id(target) in ctx['hit'] or target.get('hp',0)<=0): return
    ctx['hit'].add(id(target))
    kind = affix['id']
    if kind in (10,11):
        # Dedicated DOT layers avoid poison's unrelated native hpMax term.
        dot = {'kind':'burn' if kind==10 else 'poison', 'source':source,
               'amount':int(battle._ap_with_talent(source)*affix['value']), 'left':2}
        if getattr(battle,'yasuo_immune',lambda unit,kind:False)(target,dot['kind']):return
        if battle._buff(target,'purify'):
            # Match native debuff admission via the ordinary buff guard.
            if battle._buff(target,'purify'): battle._remove_buff(target,'purify',consume=True)
            return
        rows = target.setdefault('_relic_dots',[])
        rows[:] = [d for d in rows if d['kind']!=dot['kind'] or d['source'] is not source]
        rows.append(dot)
        trace(battle,'normal_dot',source,target,kind=dot['kind'],amount=dot['amount'],duration=2)
    elif kind==13 and battle.rng.get_random(1000000)<int(affix['value']*1000000):
        battle._add_buff(target,'stun',1,0,source=source)
        trace(battle,'normal_stun',source,target,duration=1)


def tick_dots(battle, unit):
    for dot in list(unit.get('_relic_dots',[])):
        if unit.get('hp',0)<=0: break
        if not any(active is dot for active in unit.get('_relic_dots',[])):continue
        trace(battle,'dot_tick',dot['source'],unit,kind=dot['kind'],amount=dot['amount'])
        battle._injured(unit,dot['amount'],6 if dot['kind']=='poison' else 7,
                        source=dot['source'],dot_kind=dot['kind'])
        dot['left'] -= 1
        if dot['left']<=0 and dot in unit.get('_relic_dots',[]): unit['_relic_dots'].remove(dot)


def summon_panel(owner, panel):
    affix = effect(owner,18)
    return {key:int(value*(1+affix['value'])) for key,value in panel.items()} if affix else panel
