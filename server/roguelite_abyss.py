"""Seeded Abyss rules and account migration, independent of owned progression."""
from __future__ import annotations

import copy
import hashlib
import random

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
DIFFICULTIES = [(1,20),(1.08,20),(1.16,18),(1.25,18),(1.35,16),
                (1.45,16),(1.56,14),(1.68,14),(1.81,12),(1.95,10)]
MAIN_STATS = ('hp', 'ap', 'de_ph', 'de_ma')


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
    chosen = list(dict.fromkeys([f'A_{i}_5' for i in range(1001,1022)] +
                               [f'A_{i}_5' for _,_,ids in DECKS.values() for i in ids] + normal))
    initial = [a for a in chosen if a in normal][:50]
    paired = [a for a in purple if a.rsplit('_',1)[0] in skin_families and a[:-1]+'6' in avatars]
    orange_only = sorted(a for a in avatars if a.endswith('_6') and
                         a.rsplit('_',1)[0] in skin_families and a[:-1]+'5' not in avatars)
    cfg.setdefault('system_simple', {})['roguelite_abyss'] = {
        'schema': 1, 'level': 125, 'skill_level': 5, 'pool_cap': 20,
        'initial_purple': initial, 'skin_purple': paired, 'skin_orange_only': orange_only,
        'decks': {key: {'name':name, 'clear_required':clear,
                        'members':[f'A_{i}_5' for i in ids]}
                  for key,(name,clear,ids) in DECKS.items()},
        'difficulties': [{'multiplier':m, 'retries':r} for m,r in DIFFICULTIES],
        'enemy_rates': {'weak':.55, 'normal':[.8,1,1.2], 'elite':1.3, 'boss':1.6},
        'boss_decks': {
            str(act): [[f'A_{i}_6' for i in ids] for ids in sets]
            for act,sets in enumerate((
                ([1001,1007,1004,1009,1012],[1013,1020,1006,1003,1016]),
                ([1018,1077,1045,1063,1082],[1049,1085,1094,1014,1040]),
                ([1001,1020,1004,1009,1012],[1013,1018,1006,1003,1016])),1)},
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
        if counterpart in cfg['avatar']:
            purple.add(counterpart)
    orange = {a.rsplit('_',1)[0]+'_6' for a in account['appeared']
              if a.rsplit('_',1)[0]+'_6' in cfg['avatar']}
    standalone = set(plan['skin_orange_only']).intersection(account['obtained'])
    return sorted(purple), sorted(orange), sorted(standalone)


def hero_record(aid, temporary=False):
    return {'id':aid.rsplit('_',1)[0], 'aid':aid, 'quality':int(aid[-1]),
            'lv':125, 'slv':5, 'temporary':temporary}


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
        result.append(base_unit(cfg, hero['aid'], 125, hero['slv'], line, pos,
                                index==0, team, standardized=True))
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
                if kind != 'rest':
                    node['enemies'] = generate_enemies(seed, difficulty, node, cfg)
                nodes.append(node)
                current.append(node)
            for node in previous:
                node['next'] = [n['id'] for n in current]
            previous = current
    return nodes


def generate_enemies(seed, difficulty, node, cfg):
    plan = rules(cfg)
    rng = rng_for(seed, 'enemy', node['id'])
    kind, act = node['type'], node['act']
    rate = plan['enemy_rates']
    if kind == 'boss':
        aids = list(rng.choice(plan['boss_decks'][str(act)]))
        if difficulty >= 7: aids.append(rng.choice(plan['initial_purple'])[:-1]+'6')
    else:
        count = 3 if kind=='weak' else 5 if kind=='elite' else rng.randint(4,5)
        aids = rng.sample(plan['initial_purple'], count)
        if kind != 'weak':
            aids = [a[:-1]+'6' if a[:-1]+'6' in cfg['avatar'] and rng.random()<.2 else a for a in aids]
        if kind == 'elite': aids[0] = aids[0][:-1]+'6'
    multiplier = rate['weak'] if kind=='weak' else rate['normal'][act-1]
    if kind in ('elite','boss'): multiplier *= rate[kind]
    multiplier *= plan['difficulties'][difficulty-1]['multiplier']
    heroes = {str(i):hero_record(a) for i,a in enumerate(aids)}
    units = standard_team(cfg, heroes, [[str(i),i%3,.15+.18*(i//3)] for i in range(len(aids))], 2, multiplier)
    if kind=='elite':
        for key in MAIN_STATS: units[0][key] = int(units[0][key]*1.2)
        units[0]['hp_max'] = units[0]['hp']
    return units


def candidates(profile, run, node, cfg):
    if len(run['pool']) >= rules(cfg)['pool_cap']:
        return None
    purple, orange, standalone = unlocked_pool(profile, cfg)
    families = set(run['pool'])
    def available(aids): return [a for a in aids if a.rsplit('_',1)[0] not in families]
    rng = rng_for(run['seed'], 'candidates', node['id'])
    high = available(orange + standalone)
    # A family can be offered at only one quality in a single choice screen.
    rng.shuffle(high)
    selected = high[:(1 if run['difficulty']>=3 else 2)] if node['type']=='elite' else []
    excluded = {a.rsplit('_',1)[0] for a in selected}
    rest = available(purple + orange + (standalone if node['type']=='elite' else []))
    rng.shuffle(rest)
    count = 6 if node['type']=='weak' else 5
    for aid in rest:
        family = aid.rsplit('_',1)[0]
        if len(selected)>=count: break
        if family not in excluded:
            selected.append(aid); excluded.add(family)
    # Fresh accounts may have fewer unlocked oranges than the guaranteed
    # count. Never create an unearned unlock to fill that shortage.
    if not selected: return None
    rng.shuffle(selected)
    return {'node_id':node['id'], 'options':[hero_record(a) for a in selected],
            'count':min(3 if node['type']=='weak' else 1,len(selected),20-len(run['pool'])),
            'can_skip':node['type']!='weak'}


def public_run(run, profile, cfg):
    if not run: return None
    result = copy.deepcopy(run)
    for node in result['map']:
        node.pop('enemies', None)
    appeared = set(profile['abyss_account']['appeared'])
    for hero in result['pool'].values():
        hero['can_orange'] = hero['quality']==5 and hero['aid'] in appeared and hero['aid'][:-1]+'6' in cfg['avatar']
    return result
