"""Seeded Abyss rules and account migration, independent of owned progression."""
from __future__ import annotations

import copy
import hashlib
import random
import re
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
# Placeholder skill templates copied into unfinished heroes by the native data.
PLACEHOLDER_SKILLS = re.compile(r'S_900[0-5]_\d+$')
COMMENTATOR_FAMILIES = ('A_1903','A_1904','A_1905','A_1909')
CHECK_IN_PLACEHOLDERS = ('A_190001',)
MAP_VERSION = 2
MAP_COLUMNS = 4
ROUTE_LAYERS = 6
REST_LAYER = ROUTE_LAYERS+1
BOSS_LAYER = ROUTE_LAYERS+2


def rng_for(seed, *domain):
    value = '|'.join(map(str, (seed, *domain))).encode()
    return random.Random(int.from_bytes(hashlib.sha256(value).digest(), 'big'))


def rules(cfg):
    return cfg.get('system_simple', {}).get('roguelite_abyss', {})


def placeholder_families(cfg):
    """Hero families whose native main/captain skill is a template placeholder.

    Call on the unpatched native config: later overlays may rewrite skill ids,
    but an unfinished hero stays unfinished for this mode until it is curated.
    """
    found = set()
    for aid, avatar in cfg.get('avatar', {}).items():
        if not re.match(r'A_1\d+_\d+$', aid) or not isinstance(avatar, dict):
            continue
        pl = avatar.get('pl') or []
        if any(PLACEHOLDER_SKILLS.match(str(sid)) for sid in pl[10:12]):
            found.add(aid.rsplit('_', 1)[0])
    return found


def excluded_families(cfg, native_placeholders=None):
    if native_placeholders is None:
        previous = cfg.get('system_simple', {}).get('roguelite_abyss', {})
        native_placeholders = set(previous.get('excluded_families', [])) or placeholder_families(cfg)
    abandoned=cfg.get('system_simple',{}).get('abandoned_hero_families_105',[])
    return sorted(set(native_placeholders) | set(COMMENTATOR_FAMILIES) | set(CHECK_IN_PLACEHOLDERS) | set(abandoned))


def family(aid):
    return aid.rsplit('_', 1)[0]


def is_excluded(aid, cfg):
    return family(aid) in set(rules(cfg).get('excluded_families', ()))


def apply_abyss_config(document, native_placeholders=None):
    cfg = document.get('cfg', document)
    excluded = excluded_families(cfg, native_placeholders)
    blocked = set(excluded)
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
    if blocked & {family(a) for a in chosen}:
        raise ValueError('Abyss initial pool contains an excluded hero family')
    paired = [a for a in purple if family(a) in skin_families and a[:-1]+'6' in avatars
              and family(a) not in blocked]
    orange_only = sorted(a for a in avatars if a.endswith('_6') and family(a) not in blocked and
                         family(a) in skin_families and a[:-1]+'5' not in avatars)
    cfg.setdefault('system_simple', {})['roguelite_abyss'] = {
        'schema': 6, 'map_version': MAP_VERSION, 'level': 99, 'orange_panel_ratio':1.4,
        'standalone_orange_panel_ratio':.7, 'skill_level': 5, 'pool_cap': 20,
        'skin_stat_multiplier': .66, 'skin_skill_level': 3, 'skin_skill_level_max': 6,
        'eligible_ordinary_purple':eligible,
        'initial_purple': initial, 'skin_purple': paired, 'skin_orange_only': orange_only,
        'skin_families': sorted(skin_families),
        'excluded_families': excluded,
        'enemy_skin_orange': sorted(a for a in skins if a.endswith('_6') and a in avatars
                                    and family(a) not in blocked),
        'enemy_skin_counts': {'normal':[0,0,1], 'elite':[0,1,2], 'boss':[1,2,3]},
        'player_skin_limits':[1,2,3],
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
        'difficulties': [{'multiplier':m, 'retries':r, 'enemy_refreshes':8-(i*4+4)//9}
                         for i,(m,r) in enumerate(DIFFICULTIES)],
        'enemy_rates': {'weak':.55, 'normal':[.8,1,1.2], 'elite':1.3, 'boss':1.6},
        'boss_decks': {
            str(act): [[f'A_{i}_5' for i in ids] for ids in sets]
            for act,sets in enumerate((
                ([1001,1007,1004,1009,1012],[1013,1020,1006,1003,1016]),
                ([1018,1077,1045,1063,1082],[1049,1085,1094,1014,1040]),
                ([1077,1085,1094,1099,1063],[1073,1090,1093,1098,1081])),1)},
        'ancient_chance': .07, 'ancient_multiplier':1.25,
        'map_weights': {'normal':.55, 'elite':.25, 'rest':.20, 'elite_difficulty_10':.35},
        'elite_limit_break_multiplier': 1.2,
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
    run = profile.get('abyss_run')
    if isinstance(run, dict) and run.get('status') == 'active' and rules(cfg).get('skin_families'):
        records = list(run.get('pool', {}).values())
        choice = run.get('pending_choice')
        if isinstance(choice, dict):
            records.extend(choice.get('options', []))
        for hero in records:
            if isinstance(hero, dict) and is_skin(hero.get('aid', ''), cfg):
                hero['slv'] = skin_skill_level(hero.get('slv', 5), cfg)
        # Pending battle/intents keep their frozen snapshots until settlement.
    return state


def unlocked_pool(profile, cfg):
    account = normalize_account(profile, cfg)
    plan = rules(cfg)
    blocked = set(plan.get('excluded_families', ()))
    purple = set(plan['initial_purple'])
    for aid in account['obtained']:
        counterpart = aid.rsplit('_',1)[0]+'_5'
        if counterpart.startswith('A_1') and counterpart in cfg['avatar']:
            purple.add(counterpart)
    orange = {a[:-1]+'6' for a in plan['initial_purple']}
    orange.update(a.rsplit('_',1)[0]+'_6' for a in account['appeared']
              if a.startswith('A_1') and a.rsplit('_',1)[0]+'_6' in cfg['avatar'])
    standalone = set(plan['skin_orange_only']).intersection(account['obtained'])
    keep = lambda aids: sorted(a for a in aids if family(a) not in blocked)
    return keep(purple), keep(orange), keep(standalone)


def skin_skill_level(level, cfg):
    plan = rules(cfg)
    maximum = plan.get('skin_skill_level_max', 6)
    return maximum if int(level) >= maximum else plan.get('skin_skill_level', 3)


def hero_record(aid, temporary=False, cfg=None):
    level = rules(cfg).get('skin_skill_level', 3) if cfg and is_skin(aid, cfg) else 5
    return {'id':aid.rsplit('_',1)[0], 'aid':aid, 'quality':int(aid[-1]),
            'lv':99, 'slv':level, 'temporary':temporary}


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
        level = hero['slv']
        if is_skin(hero['aid'], cfg):
            level = (rules(cfg).get('skin_skill_level', 3) if team == 2 else skin_skill_level(level, cfg))
        unit = base_unit(cfg, hero['aid'],99,level,line,pos,index==0,team,
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
    # Player heroes are the whole run pool: collected allies activate bonds
    # even while benched. Enemy bonds still use only their deployed lineup.
    aids = ([hero['aid'] for hero in heroes.values()] if team == 1
            else [unit['aid'] for unit in result])
    for unit in result:
        bonds = active_bonds(cfg, unit['aid'], aids)
        stats = {key:unit[key] for key in MAIN_STATS}
        stats.update(hit=0,flee=0,crit=0,tough=0)
        apply_stats(stats, unit['aid'], bonds)
        skin_factor = rules(cfg).get('skin_stat_multiplier', 1) if is_skin(unit['aid'], cfg) else 1
        for key in MAIN_STATS:
            panel = max(1, int(stats[key]*skin_factor)) if skin_factor != 1 else stats[key]
            unit[key] = max(1, int(panel*scale))
        unit['hp_max'] = unit['hp']
        unit['new_4attrs'] = {key:int(stats[key]*skin_factor) if skin_factor != 1 else stats[key]
                             for key in ('hit','flee','crit','tough')}
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


def _crosses(paths, layer, a, b):
    """Edge a->b between layer-1 and layer crosses an existing path edge."""
    for path in paths:
        c, d = path[layer-1], path[layer]
        if (c < a and d > b) or (c > a and d < b):
            return True
    return False


def _route_paths(rng):
    """Four non-crossing column walks over ROUTE_LAYERS rows of MAP_COLUMNS."""
    paths = []
    for index in range(4):
        start = rng.randrange(MAP_COLUMNS)
        while index == 1 and start == paths[0][0]:
            start = rng.randrange(MAP_COLUMNS)
        path = [start]
        for layer in range(1, ROUTE_LAYERS):
            col = path[-1]
            for _ in range(12):
                target = min(MAP_COLUMNS-1, max(0, col+rng.choice((-1, 0, 1))))
                if not _crosses(paths, layer, col, target):
                    break
            else:
                target = col  # A straight step can never cross a one-column step.
            path.append(target)
        paths.append(path)
    return paths


def _route_graph(paths):
    cells, edges = set(), set()
    for path in paths:
        for layer, col in enumerate(path, 1):
            cells.add((layer, col))
            if layer < ROUTE_LAYERS:
                edges.add((layer, col, path[layer]))
    nexts = {cell: sorted(b for l, a, b in edges if (l, a) == cell) for cell in cells}
    return sorted(cells), nexts


def _allowed_kinds(act, layer, difficulty):
    if act == 1 and layer <= 3:
        return ('weak',)
    if act > 1 and layer == 1:
        return ('normal',)
    kinds = ['normal', 'elite']
    if layer < ROUTE_LAYERS:
        kinds.append('rest')
    return tuple(kinds)


def _assign_kinds(rng, act, difficulty, cells, nexts, weights):
    parents = {}
    for cell, targets in nexts.items():
        for col in targets:
            parents.setdefault((cell[0]+1, col), []).append(cell)
    kinds = {}
    for cell in cells:  # sorted by layer then column: parents are assigned first
        layer = cell[0]
        options = []
        for kind in _allowed_kinds(act, layer, difficulty):
            if kind in ('elite', 'rest') and any(kinds[p] == kind for p in parents.get(cell, ())):
                continue
            weight = weights[kind] if kind != 'weak' else 1
            # Siblings reached from one parent should differ: that is the choice.
            for parent in parents.get(cell, ()):
                if any(kinds.get((layer, col)) == kind for col in nexts[parent] if col != cell[1]):
                    weight *= .08
            options.append((kind, weight))
        if not options:
            options = [('normal', 1)]
        roll, total = rng.random()*sum(w for _, w in options), 0
        for kind, weight in options:
            total += weight
            if roll < total:
                break
        kinds[cell] = kind
    return kinds


def _valid_act(act, cells, nexts, kinds, difficulty=1):
    layers = {layer for layer, _ in cells}
    if any(sum(1 for l, _ in cells if l == layer) < 2 for layer in layers):
        return False
    values = list(kinds.values())
    if values.count('elite') < (2 if difficulty == 10 else 1) or 'rest' not in values:
        return False
    if difficulty >= 5:
        # Design table: from difficulty 5 a route passes at most one route-layer rest.
        most = {}
        for cell in sorted(cells, reverse=True):
            here = int(kinds[cell] == 'rest')
            most[cell] = here + max([most[(cell[0]+1, col)] for col in nexts[cell]] or [0])
        if max(most.values()) > 1:
            return False
    safe = {cell for cell in cells if cell[0] == ROUTE_LAYERS and kinds[cell] != 'elite'}
    for layer in range(ROUTE_LAYERS-1, 0, -1):
        safe |= {cell for cell in cells if cell[0] == layer and kinds[cell] != 'elite'
                 and any((layer+1, col) in safe for col in nexts[cell])}
    return any(cell[0] == 1 for cell in safe)


def _fallback_act(act):
    """Deterministic valid layout: two straight lanes plus two zig-zags."""
    paths = [[0]*ROUTE_LAYERS, [3]*ROUTE_LAYERS, [1, 1, 0, 1, 1, 1], [2, 2, 3, 2, 2, 2]]
    cells, nexts = _route_graph(paths)
    layout = {1: 'normal', 2: 'normal', 3: 'normal', 4: 'rest', 5: 'elite', 6: 'normal'}
    kinds = {}
    for layer, col in cells:
        kind = 'weak' if act == 1 and layer <= 3 else layout[layer]
        if kind == 'elite' and col in (0, 1):
            kind = 'normal'  # columns 0/1 stay elite-free
        if kind == 'rest' and col in (2, 3):
            kind = 'normal'
        kinds[(layer, col)] = kind
    return cells, nexts, kinds


def generate_map(seed, difficulty, cfg):
    """Slay-the-Spire style routes: 6 route layers, a fixed rest, then the boss."""
    weights = dict(rules(cfg).get('map_weights') or
                   {'normal':.55, 'elite':.25, 'rest':.20, 'elite_difficulty_10':.35})
    if difficulty == 10:
        weights['elite'] = weights.get('elite_difficulty_10', weights['elite'])
    nodes, previous = [], []

    def add(act, layer, col, kind):
        node = {'id': f'{act}-{layer}-{0 if col is None else col}', 'act': act, 'layer': layer,
                'col': col, 'type': kind, 'next': [], 'completed': False}
        node['enemy_preview'] = (generate_enemy_preview(seed, difficulty, node, cfg)
                                 if kind != 'rest' else [])
        node['enemy_rules_schema'] = rules(cfg)['schema']
        nodes.append(node)
        return node

    for act in range(1, 4):
        for attempt in range(40):
            rng = rng_for(seed, 'map', MAP_VERSION, act, attempt)
            cells, nexts = _route_graph(_route_paths(rng))
            kinds = _assign_kinds(rng, act, difficulty, cells, nexts, weights)
            if _valid_act(act, cells, nexts, kinds, difficulty):
                break
        else:
            cells, nexts, kinds = _fallback_act(act)
        by_cell = {cell: add(act, cell[0], cell[1], kinds[cell]) for cell in cells}
        for node in previous:
            node['next'] = [by_cell[cell]['id'] for cell in cells if cell[0] == 1]
        for cell, node in by_cell.items():
            node['next'] = [by_cell[(cell[0]+1, col)]['id'] for col in nexts[cell]]
        rest = add(act, REST_LAYER, None, 'rest')
        boss = add(act, BOSS_LAYER, None, 'boss')
        for cell, node in by_cell.items():
            if cell[0] == ROUTE_LAYERS:
                node['next'] = [rest['id']]
        rest['next'] = [boss['id']]
        previous = [boss]
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
             'line':u['line'],'pos':u['pos'],'leader':bool(u['leader']),'is_skin':is_skin(u['aid'],cfg),
             'limit_break':int(u.get('limit_break',0) or 0)}
            for u in units]


def _lane_counts(rng, count):
    """Random split over three lanes, each lane holding one to three heroes."""
    options = [(a, b, count-a-b) for a in range(1, 4) for b in range(1, 4) if 1 <= count-a-b <= 3]
    if not options:
        raise GameplayFault('AbyssUnavailable', '敌方人数无法分配到三路。')
    return rng.choice(options)


def _enemy_layout(rng, aids, cfg):
    """Shuffle heroes into lanes; tanks stand in front, then small jitter."""
    order = list(range(len(aids)))
    rng.shuffle(order)
    lanes, cursor = {}, 0
    for line, size in enumerate(_lane_counts(rng, len(aids))):
        lanes[line] = order[cursor:cursor+size]
        cursor += size
    line_length = cfg['system_simple']['battle'][1]
    placement = {}
    for line, members in lanes.items():
        ranked = sorted(members, key=lambda i: (enemy_role(aids[i], cfg) != 'tank', rng.random()))
        for rank, index in enumerate(ranked):
            share = .15 + .18*rank + rng.uniform(-.02, .02)
            placement[index] = (line, int(round(share*line_length)))
    return placement


def generate_enemy_preview(seed, difficulty, node, cfg):
    """Freeze identity/quality/formation only; never construct combat stats."""
    plan = rules(cfg)
    roll = node.get('enemy_roll', 0)
    rng = rng_for(seed, 'enemy', node['id'], roll) if roll else rng_for(seed, 'enemy', node['id'])
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
    # Boss keeps its authored theme captain; other fights draw one at random.
    leader = 0 if kind=='boss' else rng.randrange(len(aids))
    orange_count=enemy_orange_count(node,cfg)
    boosted = None
    if kind=='elite':
        boosted = rng.choice([i for i in range(len(aids)) if i != leader])
        orange_slots=[boosted]+rng.sample([i for i in range(len(aids)) if i != boosted],orange_count-1)
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
    placement = _enemy_layout(rng, aids, cfg)
    # The captain is listed first: standard_team() gives index 0 the captain skill.
    order = [leader]+[i for i in range(len(aids)) if i != leader]
    return [{'aid':aids[i],'quality':int(aids[i][-1]),'star':int(aids[i][-1]),'lv':99,
             'slv':plan.get('skin_skill_level',3) if is_skin(aids[i],cfg) else 5,
             'line':placement[i][0],'pos':placement[i][1],'leader':i==leader,
             'is_skin':is_skin(aids[i],cfg),'limit_break':int(i==boosted)} for i in order]


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
    if preview and not preview[0].get('leader', True):
        raise GameplayFault('AbyssUnavailable', '敌方阵容缺少队长。')
    line_length = cfg['system_simple']['battle'][1]
    heroes = {str(i):hero_record(u['aid'],cfg=cfg) for i,u in enumerate(preview)}
    # Legacy previews stored float positions; both round to the same native pos.
    formation = [[str(i),u['line'],min(1,max(0,u['pos']/line_length))] for i,u in enumerate(preview)]
    units = standard_team(cfg, heroes, formation, 2, multiplier)
    if kind=='elite':
        boosted = [i for i,u in enumerate(preview) if u.get('limit_break')]
        # Old saves predate limit_break: their boosted hero was always slot 0.
        for index in boosted or [0]:
            unit = units[index]
            for key in MAIN_STATS:
                unit[key] = int(unit[key]*plan.get('elite_limit_break_multiplier',1.2))
            unit['hp_max'] = unit['hp']
            if boosted:
                unit['limit_break'] = 1  # display only; stats come from the multiplier above
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
    return {'node_id':node['id'], 'options':[hero_record(a,cfg=cfg) for a in selected],
            # count is the maximum: any 1..count options may be taken, or skip.
            'count':min(policy['pick'],len(selected),20-len(run['pool'])),
            'can_skip':True}


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
