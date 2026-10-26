"""Quality-aware roster bonds; definitions are shared with the AIR client."""
from __future__ import annotations

import copy
import hashlib
import itertools
from pathlib import Path
import json

PLAN = Path(__file__).resolve().parents[1] / 'config/reconstruction/bonds-1.0.4.json'
MAIN = ('hp', 'ap', 'de_ph', 'de_ma')
SECONDARY = ('hit', 'flee', 'crit', 'tough')


def candidates(cfg, profile, lineup=None):
    teams = profile.get('team', [])
    index = int(profile.get('attrs', {}).get('team_num', 0))
    ids = list(lineup if lineup is not None else (teams[index] if 0 <= index < len(teams) else []))
    for node, value in profile.get('attrs', {}).get('dn', {}).items():
        definition = cfg.get('system_simple', {}).get('dn', {}).get(str(node), [])
        if len(definition) > 5 and definition[5] == 'all' and isinstance(value, list) and len(value) > 1 and int(value[0]) > 0:
            ids.append(value[1])
    return [str(profile['avatars'][iid].get('aid', iid)).split('|')[0]
            for iid in dict.fromkeys(i for i in ids if isinstance(i, str)) if iid in profile.get('avatars', {})]


def active_bonds(cfg, aid, aids):
    family, quality = aid.rsplit('_', 1)
    quality = int(quality)
    result = []
    for bond in cfg.get('system_simple', {}).get('bonds_104', []):
        if family not in bond['families']:
            continue
        # Exactly matching quality, with only the explicitly permitted blue /
        # minimum-purple substitution. No orange/purple or skin/base bridging.
        levels = [quality] + ([4] if quality == 5 and bond['minimum_quality'][family] == 5 else [])
        for level in levels:
            required = [f'{member}_{5 if level == 4 and bond["minimum_quality"][member] == 5 else level}'
                        for member in bond['families']]
            if aid in required and all(member in aids for member in required):
                result.append(bond)
                break
    return result


def profile_bonds(cfg, profile, iid, *, hero_only=False):
    if hero_only:
        return []
    teams = profile.get('team', [])
    selected = int(profile.get('attrs', {}).get('team_num', 0))
    lineup = teams[selected] if 0 <= selected < len(teams) else []
    if iid not in lineup:
        return []
    aid = str(profile['avatars'][iid].get('aid', iid)).split('|')[0]
    return active_bonds(cfg, aid, candidates(cfg, profile, lineup))


def apply_stats(stats, aid, bonds):
    family = aid.rsplit('_', 1)[0]
    for bond in bonds:
        benefit = bond['benefits'][family]
        for key, rate in benefit.get('stats', {}).items():
            stats[key] = int(round(float(stats[key]) * (1 + rate), 5))
        for key, amount in benefit.get('flat_by_quality', {}).get(aid.rsplit('_', 1)[1], {}).items():
            stats[key] = int(stats.get(key, 0)) + amount


def skill_ids(cfg, aid, bonds):
    key = '|'.join(sorted(bond['id'] for bond in bonds))
    return cfg.get('system_simple', {}).get('bond_skill_variants_104', {}).get(aid, {}).get(key, {})


def _scale_skill(source, factor):
    from skill_balance_overlay import _action_paths, _get, _set
    from captain_strength import _EXTRA_PATHS, _update_growth
    row = copy.deepcopy(source)
    paths = set()
    for index, action in enumerate(row.get('skill', [])):
        damage, _, defense = _action_paths(action)
        extras = [] if action[0] == 'push' else list(_EXTRA_PATHS.get(action[0], ()))
        if action[0] == 'mod_step':
            from skill_output_104 import output_paths
            extras.extend(output_paths(action))
        if action[0] in ('heal_ap', 'heal_max_hp'):
            extras.append((1,))
        if action[0] == 'manual_ability':
            extras.append((2,))
        for path in set(damage + defense + extras):
            _set(action, path, _get(action, path) * factor)
            paths.add((index, *path))
    _update_growth(row, paths, factor)
    row.pop('rankInfoTemplate', None)
    row['info'] = row.get('info', '') + f'\n羁绊：技能伤害、治疗、护盾及数值增益系数×{factor:g}（持续时间、目标数量、位移距离不变）。'
    return row


def apply_bonds_104(document):
    cfg = document.get('cfg', document)
    simple = cfg['system_simple']
    if simple.get('bonds_schema') == '1.0.4':
        return document
    plan = json.loads(PLAN.read_text('utf-8'))
    definitions = copy.deepcopy(plan['bonds'])
    heroes = cfg['avatar']
    variants = {}
    for bond in definitions:
        skins=set(simple.get('skin_hero_ids',[]))
        categories={any(a.startswith(family+'_') for a in skins) for family in bond['families']}
        if len(categories)>1:
            raise ValueError('Mixed ordinary/skin bond: '+bond['name'])
        bond['minimum_quality'] = {family: min(int(aid.rsplit('_', 1)[1]) for aid in heroes if aid.rsplit('_', 1)[0] == family)
                                   for family in bond['families']}
        count = len(bond['families'])
        for family, benefit in bond['benefits'].items():
            if 'secondary' in benefit:
                keys = benefit.pop('secondary')
                budget = {2: 6000, 3: 10000, 4: 15000, 5: 20000}[count]
                rows = {int(aid.rsplit('_', 1)[1]): row for aid, row in heroes.items() if aid.rsplit('_', 1)[0] == family}
                reference = rows.get(6, rows[max(rows)])['pl']
                reference_total = sum(float(reference[i]) for i in (0, 2, 4, 6))
                benefit['flat_by_quality'] = {}
                for quality, row in rows.items():
                    ratio = sum(float(row['pl'][i]) for i in (0, 2, 4, 6)) / max(1, reference_total)
                    total = round(budget * ratio)
                    benefit['flat_by_quality'][str(quality)] = {key: total // len(keys) + int(i < total % len(keys)) for i, key in enumerate(keys)}
    simple['bonds_104'] = definitions
    simple['purple_bonds'] = []
    for aid, hero in heroes.items():
        family = aid.rsplit('_', 1)[0]
        related = [b for b in definitions if family in b['families']]
        if not related:
            continue
        variants[aid] = {}
        for count in range(1, len(related) + 1):
            for selected in itertools.combinations(related, count):
                key = '|'.join(sorted(b['id'] for b in selected))
                replacements = {}
                mechanics = [b for b in selected if b.get('focus') == family]
                strongest = max(mechanics, key=lambda b: (len(b['families']), b['id']), default=None)
                for slot, field in ((10, 'skill'), (11, 'leader_skill')):
                    factor = 1.0
                    for bond in selected:
                        factor *= 1 + bond['benefits'][family].get('skill_rate', 0)
                    source = cfg['skill'].get(hero['pl'][slot])
                    if not source:
                        continue
                    row = copy.deepcopy(source)
                    if strongest and (slot == 10 or len(strongest['families']) >= 4):
                        mechanism = strongest['mechanism']['normal' if slot == 10 else 'captain']
                        if mechanism.get('replace'):
                            row['skill'] = copy.deepcopy(mechanism['actions'])
                            row['pl'] = copy.deepcopy(mechanism['pl'])
                            row['skillUp'] = copy.deepcopy(mechanism.get('upgrades'))
                            row.pop('skillUpPaths', None)
                            for attr in list(row):
                                if attr.startswith('action') or attr in ('rankInfoTemplate', 'manualDamageMultiplier', 'modEffectSequence', 'modCondition', 'modPassiveTrigger', 'builtin_native_source_104'):
                                    row.pop(attr, None)
                            row['actionTargetPolicies'] = copy.deepcopy(mechanism['policies'])
                            row['actionTargetMaxTargets'] = copy.deepcopy(mechanism['caps'])
                            if mechanism.get('policy_args'):
                                row['actionTargetPolicyArgs'] = copy.deepcopy(mechanism['policy_args'])
                        else:
                            offset = len(row['skill'])
                            row['skill'].extend(copy.deepcopy(mechanism['actions']))
                            for attr, source_key, default in (('actionTargetPolicies', 'policies', None), ('actionTargetMaxTargets', 'caps', 1)):
                                values = list(row.get(attr) or [])
                                values.extend([default] * (offset - len(values)))
                                row[attr] = values + copy.deepcopy(mechanism[source_key])
                        row['name'] = mechanism['name']
                        row['info'] = ('' if mechanism.get('replace') else row.get('info', '') + '\n') + mechanism['info']
                        row.pop('rankInfoTemplate', None)
                    if factor != 1:
                        row = _scale_skill(row, factor)
                    if factor == 1 and not (strongest and (slot == 10 or len(strongest['families']) >= 4)):
                        continue
                    sid = 'S_7' + str(int(hashlib.sha256(f'{aid}:{key}:{slot}'.encode()).hexdigest()[:12], 16)) + '_' + aid.rsplit('_', 1)[1]
                    if sid in cfg['skill']:
                        raise ValueError('bond skill ID collision: ' + sid)
                    row['id'] = sid
                    row['bond_power_rate_104'] = factor * (1 + {2:.25,3:.32,4:.44,5:.56}[len(strongest['families'])] if strongest and (slot == 10 or len(strongest['families']) >= 4) else 1)
                    cfg['skill'][sid] = row
                    replacements[field] = sid
                variants[aid][key] = replacements
    simple['bond_skill_variants_104'] = variants
    simple['bonds_schema'] = '1.0.4'
    return document
