"""Final hero-skill output pass; never scale status strength or timing."""
from __future__ import annotations

import copy
from captain_strength import _update_growth, _update_text
from skill_balance_overlay import _action_paths, _get, _set, _pct

RATE = .8
SCHEMA = 'hero-skill-output-1.0.4-v1'
EXTRA = {
    'caster_ap_shield': [(1,)], 'caster_hp_shield': [(1,)],
    'target_hp_shield': [(1,)], 'hp_shield': [(1,)], 'shield': [(1,)],
    'shield_composite': [(1,), (2,)], 'shield_followup': [(1,)],
    'cure': [(1,)], 'heal_ap': [(1,)], 'heal_max_hp': [(1,)],
    'caster_hp_heal': [(1,)], 'heal_missing_hp': [(1,)],
    'heal_missing_hp_per_hero': [(1,), (2,)], 'lethal_floor': [(3,)],
    'dash_group_strike': [(3,)], 'manual_dot': [(3,)],
    'push': [(1,)], 'stun_by_condition': [(1,)], 'nurse_healing': [(1,)],
}
STATUS_FIELDS = {
    'weak': (3,), 'weak_percent': (3,), 'sunder': (3,), 'sunder_percent': (3,),
    'armor': (1,), 'steel': (1,), 'strong': (1,), 'attrup': (1,),
    'back': (1,), 'hitup': (1,), 'fleeup': (1,), 'kill_buff': (2,),
    'stat_flat': (2,), 'battle_stack': (2,), 'battle_stack_unconditional': (2,),
    'timed_stack': (2,), 'shield_followup': (6,), 'summon': (1,), 'summon_turret': (1,),
}


def output_paths(action):
    if action[0] == 'mod_step':
        if action[1] in ('damage','heal') or (action[1]=='buff' and action[8]=='shield'):
            return {(i,) for i in (5,6,7,18,19) if i<len(action)}
        return set()
    damage, healing, _defense = _action_paths(action)
    return set(damage + healing + EXTRA.get(action[0], []))


def apply_skill_output_104(document):
    cfg = document.get('cfg', document)
    if cfg.get('skill_output_104', {}).get('schema') == SCHEMA:
        return document
    heroes = {aid: h for aid, h in cfg['avatar'].items() if aid.startswith('A_1')}
    refs = {h['pl'][i] for h in heroes.values() for i in (10, 11, 13)
            if len(h['pl']) > i and h['pl'][i]}
    refs.update(cfg.get('hero_packs_104',{}).get('skills',[]))
    refs.update(cfg.get('equipment_bonds_104',{}).get('skills',[]))
    variants = cfg['system_simple'].get('bond_skill_variants_104', {})
    refs.update(s for aid, combinations in variants.items() if aid in heroes
                for replacement in combinations.values() for s in replacement.values())
    # Shared monster/equipment skills must retain their old coefficients.
    foreign = {h['pl'][i] for aid,h in cfg['avatar'].items() if aid not in heroes and not h.get('builtin_pack_104')
               for i in (10,11,13) if len(h['pl'])>i and h['pl'][i]}
    foreign.update(e.get('skill') for e in cfg.get('equip', {}).values())
    for sid in sorted(refs & foreign):
        private = 'S_104' + sid.split('_')[1] + '_' + sid.rsplit('_',1)[1]
        if private in cfg['skill']:
            raise ValueError('skill output private ID collision: '+private)
        cfg['skill'][private] = copy.deepcopy(cfg['skill'][sid])
        cfg['skill'][private]['id'] = private
        cfg['skill'][private].setdefault('res',sid)
        for hero in heroes.values():
            for i in (10,11,13):
                if len(hero['pl'])>i and hero['pl'][i]==sid:hero['pl'][i]=private
        for aid, combinations in variants.items():
            if aid not in heroes:continue
            for replacement in combinations.values():
                for key,value in replacement.items():
                    if value==sid:replacement[key]=private
        # Equipment lookup must follow the hero-private skill reference too.
        for aid,mapping in cfg['system_simple'].get('equipment_skill_variants_104',{}).items():
            if aid in heroes and sid in mapping:mapping[private]=mapping.pop(sid)
        refs.remove(sid);refs.add(private)
    audit=[]
    for sid in sorted(refs):
        row=copy.deepcopy(cfg['skill'][sid]); scaled=set();changes={};unchanged=set()
        manual=any(a[0]=='manual_ability' for a in row.get('skill',[]))
        for i,action in enumerate(row.get('skill',[])):
            paths=output_paths(action)
            for path in paths:
                value=_get(action,path)
                _set(action,path,value*RATE);scaled.add((i,*path))
                changes.setdefault(_pct(value),set()).add(_pct(value*RATE))
            for j in STATUS_FIELDS.get(action[0], ()):
                if j<len(action) and type(action[j]) in (int,float):unchanged.add(_pct(action[j]))
        _update_growth(row,scaled,RATE)
        if row.get('chainDot'):
            row['chainDot'][1]=round(row['chainDot'][1]*RATE,10)
        # Manual/skin skills and their delayed callbacks use the dedicated
        # native helper multiplier. Never scale their mixed buff parameter.
        row['hero_output_rate_104']=RATE
        if manual or any(a[0] in ('cat_passive','polar_basic') for a in row.get('skill',[])):
            note='伤害、护盾、治疗按下述技能基准的80%结算；属性增减益及控制不变。\n'
            for key in ('info','rankInfoTemplate'):
                if isinstance(row.get(key),str):row[key]=note+row[key]
        else:
            _update_text(row,changes,unchanged)
        # Equipment notes describe relative gains, not output coefficients.
        # Append after numeric text scaling so e.g. a 12% budget stays 12%.
        for note in row.get('equipment_notes_104',[]):
            for field in ('info','rankInfoTemplate'):
                if isinstance(row.get(field),str):row[field]+='\n'+note
        cfg['skill'][sid]=row
        audit.append(sid)
    cfg['system_simple']['hero_skill_output_rate_104']=RATE
    cfg['skill_output_104']={'schema':SCHEMA,'rate':RATE,'skills':audit}
    return document
