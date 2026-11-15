"""Seeded Abyss rules and account migration, independent of owned progression."""
from __future__ import annotations

import copy
import hashlib
import random
from combat_math import level_stats, to_int

from battle_engine import base_unit, validate_team_lane_coverage
from bonds_104 import active_bonds, apply_stats, skill_ids
from native_skill_snapshot import _native_skill_snapshot
from player_store import GameplayFault


DECKS = {
    'blade': ('锋刃', 0, [1001, 1007, 1004, 1009, 1012]),
    'flame': ('炎咒', 0, [1013, 1020, 1006, 1003, 1016]),
    'venom': ('蚀骨', 1, [1018, 1077, 1045, 1063, 1082]),
    'summon': ('群策', 3, [1049, 1085, 1094, 1014, 1040]),
    'star': ('星裔', 5, []),
}
DIFFICULTIES = [(.80,20),(.86,20),(.92,18),(.99,18),(1.06,16),
                (1.13,16),(1.22,14),(1.30,14),(1.40,12),(1.50,10)]
MAIN_STATS = ('hp', 'ap', 'de_ph', 'de_ma')
TANK_FAMILIES = {f'A_{i}' for i in (1001,1007,1013,1020,1018,1077,1049,1085,1073,1090,
                                    1137,1138,1201,1204)}
SUPPORT_FAMILIES = {f'A_{i}' for i in (1004,1006,1045,1094,1093,1139,1208,1228)}
SUMMON_FAMILIES = {f'A_{i}' for i in (1014,1040,1103,1212,1218,1221,1311)}


def rng_for(seed, *domain):
    value = '|'.join(map(str, (seed, *domain))).encode()
    return random.Random(int.from_bytes(hashlib.sha256(value).digest(), 'big'))


def rules(cfg):
    return cfg.get('system_simple', {}).get('roguelite_abyss', {})


def apply_abyss_config(document):
    cfg = document.get('cfg', document)
    avatars = cfg.get('avatar', {})
    skins = set(cfg.get('system_simple', {}).get('skin_hero_ids', []))
    skin_families = {aid.rsplit('_', 1)[0] for aid in skins}
    purple = sorted(a for a in avatars if a.endswith('_5') and a.startswith('A_1'))
    normal = [a for a in purple if a.rsplit('_', 1)[0] not in skin_families]
    eligible = [a for a in normal if 1001<=int(a.split('_')[1])<=1099 and a[:-1]+'6' in avatars]
    chosen = [f'A_{i}_5' for _,_,ids in DECKS.values() for i in ids]+[
        'A_1002_5','A_1005_5','A_1008_5','A_1010_5','A_1011_5']
    if len(set(chosen))!=25 or not set(chosen)<=set(eligible):
        raise ValueError('Abyss initial pool must contain 25 distinct eligible ordinary heroes')
    initial = sorted(chosen)
    paired = [a for a in purple if a.rsplit('_',1)[0] in skin_families and a[:-1]+'6' in avatars]
    orange_only = sorted(a for a in avatars if a.endswith('_6') and
                         a.rsplit('_',1)[0] in skin_families and a[:-1]+'5' not in avatars)
    cfg.setdefault('system_simple', {})['roguelite_abyss'] = {
        'schema': 3, 'level': 99, 'orange_panel_ratio':1.4,
        'standalone_orange_panel_ratio':.7, 'skill_level': 5, 'pool_cap': 20,
        'eligible_ordinary_purple':eligible,
        'initial_purple': initial, 'skin_purple': paired, 'skin_orange_only': orange_only,
        'skin_families': sorted(skin_families),
        'enemy_skin_orange': sorted(a for a in skins if a.endswith('_6') and a in avatars),
        'enemy_skin_counts': {'elite':[0,1,2], 'boss':[0,2,4]},
        'enemy_orange_counts': {'act1':1, 'act2':2, 'act3_early':3,
                                'act3_late':4, 'boss':[2,3,5]},
        'candidate_policy': {
            'weak': {'options':6, 'pick':3, 'orange':[0,0,0], 'skin':[0,0,0]},
            'normal': {'options':3, 'pick':1, 'orange':[.01,.015,.04], 'skin':[0,.15,.35]},
            'elite': {'options':5, 'pick':1, 'orange':[.04,.15,.40], 'skin':[0,.15,.35]},
            'boss': {'options':3, 'pick':1, 'orange':[1,1,1], 'skin':[0,.15,0]},
        },
        'decks': {key: {'name':name, 'clear_required':clear,
                        'members':[f'A_{i}_5' for i in ids]}
                  for key,(name,clear,ids) in DECKS.items()},
        'difficulties': [{'multiplier':m, 'retries':r} for m,r in DIFFICULTIES],
        'enemy_rates': {'weak':.55, 'normal':[.8,1,1.2], 'elite':1.3, 'boss':1.6},
        'boss_decks': {
            str(act): [[f'A_{i}_5' for i in ids] for ids in sets]
            for act,sets in enumerate((
                ([1001,1007,1004,1009,1012],[1013,1020,1006,1003,1016]),
                ([1018,1077,1045,1063,1082],[1049,1085,1094,1014,1040]),
                ([1077,1085,1094,1099,1063],[1073,1090,1093,1098,1081])),1)},
        'ancient_chance': .07, 'ancient_multiplier':1.25,
    }
    return document


def normalize_account(profile, config):
    """Union is monotonic; run at load and both sides of every profile mutation.

    Recording before mutation retains heroes consumed/sold in the first request
    after upgrade. Recording after mutation covers all acquisition channels.
    """
    cfg = config.get('cfg', config) if isinstance(config, dict) else {}
    state = profile.setdefault('abyss_account', {})
    obtained = set(state.get('obtained', []))
    for iid, hero in profile.get('avatars', {}).items():
        if not isinstance(hero, dict):
            continue
        aid = str(hero.get('aid', iid)).split('|')[0]
        if aid in cfg.get('avatar', {}):
            obtained.add(aid)
    state.update(schema=1, obtained=sorted(obtained))
    state.setdefault('appeared', [])
    state.setdefault('cleared', [])
    state['max_difficulty'] = min(10, max(state.get('cleared', [0]) or [0])+1)
    cleared = max(state['cleared'] or [0])
    state['decks'] = [key for key,(_,unlock,_) in DECKS.items() if cleared >= unlock]
    return state


def unlocked_pool(profile, cfg):
    account = normalize_account(profile, cfg)
    plan = rules(cfg)
    purple = set(plan['initial_purple'])
    for aid in account['obtained']:
        counterpart = aid.rsplit('_',1)[0]+'_5'
        if counterpart.startswith('A_1') and counterpart in cfg['avatar']:
            purple.add(counterpart)
    orange = {a[:-1]+'6' for a in plan['initial_purple']}
    orange.update(a.rsplit('_',1)[0]+'_6' for a in account['appeared']
              if a.startswith('A_1') and a.rsplit('_',1)[0]+'_6' in cfg['avatar'])
    standalone = set(plan['skin_orange_only']).intersection(account['obtained'])
    return sorted(purple), sorted(orange), sorted(standalone)


def hero_record(aid, temporary=False):
    return {'id':aid.rsplit('_',1)[0], 'aid':aid, 'quality':int(aid[-1]),
            'lv':99, 'slv':5, 'temporary':temporary}


def standard_team(cfg, heroes, formation, team=1, scale=1):
    if not isinstance(formation, list) or not 1 <= len(formation) <= 7:
        raise GameplayFault('InvalidFormation', '请选择有效的上阵阵容。')
    result, ids = [], set()
    for index, entry in enumerate(formation):
        if not isinstance(entry, list) or len(entry) != 3:
            raise GameplayFault('InvalidFormation', '布阵需要英雄、路线和位置。')
        hid, line, pos = entry
        if (not isinstance(hid,str) or hid not in heroes or hid in ids or
                type(line) is not int or line not in (0,1,2) or
                type(pos) not in (int,float) or not 0 <= pos <= 1):
            raise GameplayFault('InvalidFormation', '布阵成员、路线或位置无效。')
        ids.add(hid)
        hero = heroes[hid]
        unit = base_unit(cfg, hero['aid'],99,hero['slv'],line,pos,index==0,team,
                         enforce_avatar_level_cap=False)
        if hero['aid'].endswith('_6'):
            purple = hero['aid'][:-1]+'5'
            source = cfg['avatar'].get(purple,cfg['avatar'][hero['aid']])
            ratio = rules(cfg)['orange_panel_ratio'] if purple in cfg['avatar'] else rules(cfg)['standalone_orange_panel_ratio']
            raw = level_stats(source,99,enforce_cap=False)
            for key,stat in zip(MAIN_STATS,('health','attack','physical_defense','magic_defense')):
                unit[key] = to_int(raw[stat]*ratio)
            unit['hp_max'] = unit['hp']
        result.append(unit)
    aids = [u['aid'] for u in result]
    for unit in result:
        bonds = active_bonds(cfg, unit['aid'], aids)
        stats = {key:unit[key] for key in MAIN_STATS}
        stats.update(hit=0,flee=0,crit=0,tough=0)
        apply_stats(stats, unit['aid'], bonds)
        for key in MAIN_STATS:
            unit[key] = max(1, int(stats[key]*scale))
        unit['hp_max'] = unit['hp']
        unit['new_4attrs'] = {key:stats[key] for key in ('hit','flee','crit','tough')}
        for field,sid in skill_ids(cfg, unit['aid'], bonds).items():
            if field != 'leader_skill' or unit['leader']:
                unit[field] = _native_skill_snapshot(cfg, sid, unit['slv'] if field=='skill' else 1)
        unit['bonds_104'] = [b['id'] for b in bonds]
        unit['abyss_standardized'] = True
    try:
        validate_team_lane_coverage(result, 3)
    except ValueError as error:
        raise GameplayFault('InvalidFormation', '三路都至少需要一名上阵英雄。') from error
    return result


def generate_map(seed, difficulty, cfg):
    rng = rng_for(seed, 'map')
    nodes, previous = [], []
    for act in range(1,4):
        for layer in range(1,8):
            if layer == 7: kinds = ['boss']
            elif act == 1 and layer <= 3: kinds = ['weak'] * rng.randint(2,3)
            else:
                rest_layer = 4 if act==1 else 2
                elite_layers = (5,6) if difficulty==10 else (5,)
                kind = 'rest' if layer==rest_layer else 'elite' if layer in elite_layers else 'normal'
                kinds = [kind] * rng.randint(2,3)
            current = []
            for branch,kind in enumerate(kinds):
                node = {'id':f'{act}-{layer}-{branch}', 'act':act, 'layer':layer,
                        'type':kind, 'next':[], 'completed':False}
                node['enemy_preview'] = (generate_enemy_preview(seed,difficulty,node,cfg)
                                         if kind!='rest' else [])
                nodes.append(node)
                current.append(node)
            for node in previous:
                node['next'] = [n['id'] for n in current]
            previous = current
    return nodes


def is_skin(aid, cfg):
    return aid.rsplit('_',1)[0] in rules(cfg)['skin_families']


def enemy_role(aid, cfg):
    """Authored roles: stat_profile is a panel template, not combat position."""
    family=aid.rsplit('_',1)[0]
    if family in TANK_FAMILIES:return 'tank'
    if family in SUPPORT_FAMILIES:return 'support'
    if family in SUMMON_FAMILIES:return 'summon'
    return 'physical' if cfg['avatar'][aid]['tl'][2]==1 else 'magic'


def enemy_orange_count(node, cfg):
    kind,act=node['type'],node['act']
    counts=rules(cfg)['enemy_orange_counts']
    if kind=='weak':return 0
    if kind=='boss':return counts['boss'][act-1]
    if act<3:return counts[f'act{act}']
    layer=node.get('layer')
    if layer is None:
        parts=str(node['id']).split('-')
        layer=int(parts[1]) if len(parts)>1 and parts[1].isdigit() else 6
    return counts['act3_early' if layer<=3 else 'act3_late']


def preview_from_units(units, cfg):
    return [{'aid':u['aid'],'quality':int(u['aid'].rsplit('_',1)[1]),
             'lv':u.get('lv',99),'slv':u.get('slv',5),'star':int(u['aid'].rsplit('_',1)[1]),
             'line':u['line'],'pos':u['pos'],'leader':bool(u['leader']),'is_skin':is_skin(u['aid'],cfg)}
            for u in units]


def generate_enemy_preview(seed, difficulty, node, cfg):
    """Freeze identity/quality/formation only; never construct combat stats."""
    plan = rules(cfg)
    rng = rng_for(seed, 'enemy', node['id'])
    kind, act = node['type'], node['act']
    if kind == 'boss':
        aids = list(rng.choice(plan['boss_decks'][str(act)]))
        if difficulty >= 7:
            used={a.rsplit('_',1)[0] for a in aids}
            aids.append(rng.choice([a for a in plan['initial_purple'] if a.rsplit('_',1)[0] not in used]))
    else:
        count = 3 if kind=='weak' else 5 if kind=='elite' else rng.randint(4,5)
        aids = rng.sample(plan['initial_purple'], count)
    aids=[a[:-1]+'5' for a in aids]
    orange_count=enemy_orange_count(node,cfg)
    if kind=='boss':
        # Authored priority: captain, two carries, support, second tank.
        orange_slots=[0,3,4,2,1][:orange_count]
    elif kind=='elite':
        orange_slots=[0]+rng.sample(list(range(1,len(aids))),orange_count-1)
    else:
        orange_slots=rng.sample(list(range(len(aids))),orange_count)
    for slot in orange_slots:aids[slot]=aids[slot][:-1]+'6'
    skin_count=plan['enemy_skin_counts'].get(kind,[0,0,0])[act-1]
    used={a.rsplit('_',1)[0] for a in aids}
    for slot in rng.sample(orange_slots,skin_count):
        possible=[a for a in plan['enemy_skin_orange'] if a.rsplit('_',1)[0] not in used
                  and (kind!='boss' or enemy_role(a,cfg)==enemy_role(aids[slot],cfg))]
        if not possible:
            raise GameplayFault('AbyssUnavailable','敌方皮肤阵容配置不完整。')
        replacement=rng.choice(possible)
        used.remove(aids[slot].rsplit('_',1)[0])
        aids[slot]=replacement
        used.add(replacement.rsplit('_',1)[0])
    line_length=cfg['system_simple']['battle'][1]
    return [{'aid':aid,'quality':int(aid[-1]),'star':int(aid[-1]),'lv':99,'slv':5,
             'line':i%3,'pos':(.15+.18*(i//3))*line_length,
             'leader':i==0,'is_skin':is_skin(aid,cfg)} for i,aid in enumerate(aids)]


def generate_enemies(seed, difficulty, node, cfg):
    plan=rules(cfg)
    kind,act=node['type'],node['act']
    preview=node.get('enemy_preview')
    if preview is None:preview=generate_enemy_preview(seed,difficulty,node,cfg)
    rate=plan['enemy_rates']
    multiplier = rate['weak'] if kind=='weak' else rate['normal'][act-1]
    if kind in ('elite','boss'): multiplier *= rate[kind]
    if kind!='weak':
        multiplier *= plan['difficulties'][difficulty-1]['multiplier']
    heroes = {str(i):hero_record(u['aid']) for i,u in enumerate(preview)}
    units = standard_team(cfg, heroes, [[str(i),u['line'],.15+.18*(i//3)] for i,u in enumerate(preview)], 2, multiplier)
    if kind=='elite':
        for key in MAIN_STATS: units[0][key] = int(units[0][key]*1.2)
        units[0]['hp_max'] = units[0]['hp']
    return units


def candidates(profile, run, node, cfg):
    if len(run['pool']) >= rules(cfg)['pool_cap']:
        return None
    if node['type']=='boss' and node['act']==3:return None
    purple, orange, standalone = unlocked_pool(profile, cfg)
    unavailable = set(run['pool'])
    skin_families=set(rules(cfg)['skin_families'])
    purples={a.rsplit('_',1)[0]:a for a in purple}
    oranges={a.rsplit('_',1)[0]:a for a in orange+standalone}
    rng = rng_for(run['seed'], 'candidates', node['id'])
    policy=rules(cfg)['candidate_policy'][node['type']]
    act=node.get('act')
    if act is None:act=int(node['id'].split('-')[0])
    guaranteed=(1 if run['difficulty']>=3 else 2) if node['type']=='elite' else 0
    selected=[]

    def pool(source, skin):
        return sorted(f for f in source if f not in unavailable and (f in skin_families)==skin)

    for index in range(policy['options']):
        skin=rng.random()<policy['skin'][act-1]
        forced=index<guaranteed or node['type']=='boss'
        # Guaranteed offers require an unlocked orange. When that skin
        # category is unavailable, use an unlocked ordinary orange instead.
        if forced:
            available=pool(oranges,skin)
            if skin and not available:available=pool(oranges,False)
            if not available:break
            aid=oranges[rng.choice(available)]
        else:
            available=pool(set(purples)|set(oranges),skin)
            if skin and not available:
                skin=False
                available=pool(set(purples)|set(oranges),False)
            if not available:break
            family=rng.choice(available)
            want_orange=rng.random()<policy['orange'][act-1]
            aid=oranges.get(family) if want_orange else None
            if aid is None:aid=purples.get(family)
            if aid is None:
                # Orange-only skins cannot appear on a purple roll. Fall
                # back to another purple of the same class, then ordinary.
                fallback=pool(purples,skin) or pool(purples,False)
                if not fallback:break
                aid=purples[rng.choice(fallback)]
        unavailable.add(aid.rsplit('_',1)[0])
        selected.append(aid)
    if not selected: return None
    rng.shuffle(selected)
    return {'node_id':node['id'], 'options':[hero_record(a) for a in selected],
            'count':min(policy['pick'],len(selected),20-len(run['pool'])),
            'can_skip':node['type']!='weak'}


def public_run(run, profile, cfg):
    if not run: return None
    result = copy.deepcopy(run)
    for node in result['map']:
        if 'enemy_preview' not in node:
            node['enemy_preview']=preview_from_units(node.get('enemies',[]),cfg)
        node.pop('enemies', None)
    orange = set(unlocked_pool(profile,cfg)[1])
    for hero in result['pool'].values():
        hero['can_orange'] = hero['quality']==5 and hero['aid'][:-1]+'6' in orange
    return result
