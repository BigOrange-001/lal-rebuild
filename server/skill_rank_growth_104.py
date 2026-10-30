"""Final hero/variant rank contract; geometry, timing and counts are not ranks.

Normal skills retain their calibrated rank-10 endpoint. Fixed-rank captain and
passive skills retain rank 1. Run after all variant/output generation.
"""
import copy
import math

from captain_strength import _EXTRA_PATHS
from native_skill_snapshot import _native_skill_snapshot
from skill_balance_overlay import _action_paths, _get

SCHEMA = 'hero-linear-rank-104-v1'
SLOTS = {'skill': 10, 'leader_skill': 11, 'skillB': 13}
SKIN_FIXED = {
    'skin2_1201_0': {'bondShield': 1.2},
    'skin2_1201_1': {'executeBonus': .8},
    'skin2_1201_2': {'transfer': .35, 'transferReduction': .5, 'soloReduction': .25},
    'skin2_1203_2': {'attackGrowth': .04, 'hpGrowth': .05},
    'skin2_1204_0': {'exposedAmp': .15},
    'skin2_1206_1': {'attackBuff': .4, 'dodgeBuff': 8000},
    'skin2_1210_0': {'bondShield': 1.2},
    'skin2_1210_1': {'attackBuff': .3, 'executeBonus': .5},
    'skin2_1211_0': {'penetration': .25},
    'skin2_1213_0': {'bondShield': 1.2},
    'skin2_1213_1': {'attackBuff': .3},
    'skin2_1215_0': {'executeBonus': .4},
    'skin2_1216_0': {'slow': .5},
    'skin2_1216_1': {'frostReduction': .25, 'slow': .5},
    'skin2_1216_2': {'eggHp': .3, 'rebornHp': .4, 'slow': .5},
    'skin2_1219_1': {'bondHeal': .8, 'penetration': .3},
    'skin2_1221_1': {'petHeal': .4, 'petPanel': .7},
    'skin2_1221_2': {'petGrowth': .05},
    'skin2_1227_1': {'petHeal': .4},
    'skin2_1228_1': {'attackBuff': .4},
    'skin2_1228_2': {'healAmp': .25, 'damageReduction': .15},
    'skin2_1140_1': {'rewindCap': .3},
}
EXTRA = {
    'attrup': ((3,),),
    'nurse_healing': ((1,), (2,)), 'polar_basic': ((1,),),
    'cat_passive': ((1,),), 'santa_kill': ((3,),), 'evil': ((1,),),
    'summon': ((1,),), 'rally_soldiers': ((1,), (5,), (6,)),
}
STRUCTURAL = {
    'purify', 'push_aoe', 'dash', 'move_to_target_lane', 'shield_dispel',
    'taunt', 'move_to_ally', 'move_self', 'recast_on_kill', 'select_target',
    'normal_on_hero_kill', 'focus_fire', 'bless', 'rally_soldiers',
    'dispel_good', 'move_enemy_side_target', 'clone_normal', 'curse',
    'timed_bless', 'arm_dash_response_104', 'move_to_target',
}


def hero_skill_references(cfg, families=None):
    refs = {}
    def add(sid, slot):
        if sid and sid in cfg['skill']:
            refs.setdefault(sid, set()).add(slot)
    heroes = {a: h for a, h in cfg['avatar'].items() if a.startswith('A_1')
              and (families is None or a.rsplit('_',1)[0] in families)}
    for hero in heroes.values():
        for slot in (10, 11, 13):
            if len(hero.get('pl', [])) > slot:
                add(hero['pl'][slot], slot)
    simple = cfg.get('system_simple', {})
    for aid, variants in simple.get('bond_skill_variants_104', {}).items():
        if aid in heroes:
            for variant in variants.values():
                for field, sid in variant.items():
                    add(sid, SLOTS[field])
    for aid, sources in simple.get('equipment_skill_variants_104', {}).items():
        if aid in heroes:
            for source, variants in sources.items():
                for sid in variants.values():
                    for slot in refs.get(source, {10}):
                        add(sid, slot)
    if any(len(slots) != 1 for slots in refs.values()):
        raise ValueError('Hero skill shared between differently anchored slots')
    return {sid: next(iter(slots)) for sid, slots in refs.items()}


def magnitude_paths(action):
    """Reviewed operator schema. Never infer magnitudes from numeric type alone."""
    kind = action[0]
    if kind == 'manual_ability':
        # Four-field native compound abilities use a single output channel;
        # skins with explicit coefficients keep those coefficients in actions.
        return {(i,) for i in range(4, len(action))}
    if kind == 'mod_step':
        return {(i,) for i in (5, 6, 7, 18, 19) if i < len(action)} | ({(12,)} if action[1] == 'summon' else set())
    groups = _action_paths(action)
    paths = set(sum(groups, [])) | set(_EXTRA_PATHS.get(kind, ())) | set(EXTRA.get(kind, ()))
    if kind == 'shield_followup' and len(action) == 9:
        paths.add((6,))
    if not paths and kind not in STRUCTURAL:
        raise ValueError('Unreviewed hero action: ' + kind)
    return {p for p in paths if p[0] < len(action)}


def _put(target, path, value):
    for index in path[:-1]:
        target = target[index]
    target[path[-1]] = value


def _manual_rank_text(row, kind, slot):
    from skill_description_104 import HEAL_SHIELD, SKIN_DAMAGE, TOKEN
    from captain_strength import _MANUAL_EFFECT_PERCENT_INDICES
    from skill_balance_overlay import _MANUAL_DAMAGE_PERCENT_INDICES
    positions = (set(_MANUAL_DAMAGE_PERCENT_INDICES.get(kind, SKIN_DAMAGE.get(kind, ())))
                 | set(HEAL_SHIELD.get(kind, ())) | set(_MANUAL_EFFECT_PERCENT_INDICES.get(kind, ())))
    if kind == 'kaelthas_c':
        positions.discard(2)
    index = 0
    def replace(match):
        nonlocal index
        selected = index in positions
        index += 1
        if selected and match[3] is not None:
            base = float(match[3]) / (2 if slot == 10 else 1)
            return '{linear:' + repr(base) + '}'
        return match[0]
    row['rankInfoTemplate'] = TOKEN.sub(replace, row.get('rankInfoTemplate', row.get('info', '')))


def _skin_rank_text(row, kind):
    keys = row.get('skin_v2_keys', [])
    def token(key, flat=False):
        return '{'+('flat' if flat else 'rank')+':0:'+str(4+keys.index(key))+'}'
    changes = {
        'skin2_1201_0': [('120.0%攻击护盾', 'bondShield', '攻击护盾')],
        'skin2_1201_1': [('提高80%', 'executeBonus', '', '提高')],
        'skin2_1201_2': [('伤害的35%', 'transfer', '', '伤害的'), ('降低25%', 'soloReduction', '', '降低')],
        'skin2_1203_1': [('最大生命15%', 'hpShield', '', '最大生命')],
        'skin2_1203_2': [('入场攻击的4%', 'attackGrowth', '', '入场攻击的'), ('入场最大生命的5%', 'hpGrowth', '', '入场最大生命的')],
        'skin2_1204_0': [('提高15%', 'exposedAmp', '', '提高')],
        'skin2_1206_1': [('40%力量', 'attackBuff', '力量')],
        'skin2_1207_2': [('治疗有50%', 'overflow', '', '治疗有')],
        'skin2_1210_0': [('每次120%', 'third', '', '每次'), ('120.0%攻击护盾', 'bondShield', '攻击护盾')],
        'skin2_1210_1': [('30%力量', 'attackBuff', '力量'), ('提高50%', 'executeBonus', '', '提高')],
        'skin2_1210_2': [('伤害的35%', 'leech', '', '伤害的')],
        'skin2_1211_0': [('无视25%', 'penetration', '', '无视')],
        'skin2_1213_0': [('120.0%攻击护盾', 'bondShield', '攻击护盾')],
        'skin2_1213_1': [('30%力量', 'attackBuff', '力量')],
        'skin2_1215_0': [('提高40%', 'executeBonus', '', '提高')],
        'skin2_1216_0': [('减少50%', 'slow', '', '减少')],
        'skin2_1216_1': [('降低25%', 'frostReduction', '', '降低')],
        'skin2_1216_2': [('30%最大生命', 'eggHp', '最大生命'), ('40%最大生命', 'rebornHp', '最大生命')],
        'skin2_1218_0': [('总伤害的35%', 'leech', '', '总伤害的')],
        'skin2_1219_1': [('30%物理穿透', 'penetration', '物理穿透'), ('恢复80.0%', 'bondHeal', '', '恢复')],
        'skin2_1221_0': [('造成100%', 'splash', '', '造成')],
        'skin2_1221_1': [('自身70%面板', 'petPanel', '面板', '自身'), ('治疗它40%', 'petHeal', '', '治疗它')],
        'skin2_1221_2': [('最大生命的5%', 'petGrowth', '', '最大生命的')],
        'skin2_1227_1': [('40%最大生命', 'petHeal', '最大生命')],
        'skin2_1228_1': [('40%力量', 'attackBuff', '力量')],
        'skin2_1228_2': [('提高25%', 'healAmp', '', '提高'), ('降低15%', 'damageReduction', '', '降低')],
        'skin2_1140_1': [('生命的60%', 'rewind', '', '生命的'), ('最多30%', 'rewindCap', '', '最多')],
    }
    text = row.get('rankInfoTemplate', row.get('info', ''))
    for old, key, suffix, *prefix in changes.get(kind, []):
        if key in keys:
            text = text.replace(old, (prefix[0] if prefix else '')+token(key)+suffix)
    if kind == 'skin2_1206_1':
        text = text.replace('8000闪避', token('dodgeBuff', True)+'闪避')
    if kind == 'skin2_1201_2':
        text = text.replace('自身实际承受这部分的一半', '自身承担部分额外减伤'+token('transferReduction'))
    if kind == 'skin2_1203_2':
        text = text.replace('本场最多增加40%攻击、50%生命', '本场最多叠加10次')
    if kind == 'skin2_1221_2':
        text = text.replace('最多各30%', '最多叠加6次')
    row['rankInfoTemplate'] = text


def apply_skill_rank_growth_104(document):
    cfg = document.get('cfg', document)
    if cfg.get('skill_rank_growth_104', {}).get('schema') == SCHEMA:
        return document
    refs = hero_skill_references(cfg)
    final_factors = {}
    for family, factor in cfg.get('hero_balance_iteration_104', {}).get('final_skill_multipliers', {}).items():
        if type(factor) not in (int, float) or not math.isfinite(factor) or not .03 <= factor <= 10:
            raise ValueError('Invalid final skill multiplier: '+family)
        for sid in hero_skill_references(cfg, {family}):
            if sid in final_factors:
                raise ValueError('Shared final skill multiplier: '+sid)
            final_factors[sid] = factor
    audit = []
    # Read every endpoint before modifying any row.
    endpoints = {sid: _native_skill_snapshot(cfg, sid, 10 if slot == 10 else 1)
                 for sid, slot in refs.items()}
    for sid, slot in sorted(refs.items()):
        row = cfg['skill'][sid]
        factor = final_factors.get(sid, 1)
        endpoint = endpoints[sid]['skills']
        actions = copy.deepcopy(endpoint)
        shallow, nested, fields, checked = [], [], {}, []
        for index, action in enumerate(actions):
            if action[0] == 'manual_ability' and action[1] in SKIN_FIXED:
                keys = row['skin_v2_keys'] = list(row.get('skin_v2_keys', []))
                for key, value in SKIN_FIXED[action[1]].items():
                    if key not in keys:
                        keys.append(key)
                        action.append(value)
            if action[0] == 'rally_soldiers' and len(action) == 5:
                action.extend([.3, .5])  # heal/maxHP, attack buff; counts unchanged
            for path in sorted(magnitude_paths(action)):
                value = _get(action, path)
                if type(value) not in (int, float) or not math.isfinite(value):
                    raise ValueError(f'Invalid magnitude: {sid} {index} {path}')
                value *= factor
                base = value / 2 if slot == 10 else value
                _put(action, path, base)
                entry = [index, path[0] if len(path) == 1 else list(path), base / 9]
                (shallow if len(path) == 1 else nested).append(entry)
                checked.append([index, list(path), base, base * 2])
        manual = any(a[0] == 'manual_ability' and not a[1].startswith('skin2_') and len(a) == 4 for a in actions)
        if any(a[0] == 'manual_ability' and not a[1].startswith('skin2_') for a in actions):
            base = .5 if slot == 10 else 1
            fields['manualFixedScale104'] = [base, base / 9]
            row['manualFixedScale104'] = base
        if manual:
            # Freeze the old action scale at its calibrated endpoint and rank
            # the shared output channels once, including delayed/heal effects.
            for key in ('manualDamageMultiplier', 'manualEffectMultiplier'):
                endpoint_value = row.get(key, 1) * factor
                base = endpoint_value / 2 if slot == 10 else endpoint_value
                fields[key] = [base, base / 9]
                row[key] = base
            row['rankManualDisplay104'] = True
            kind = next(a[1] for a in actions if a[0] == 'manual_ability' and len(a) == 4)
            _manual_rank_text(row, kind, slot)
        for key, path in (('chainDot', [1]), ('manualClonePolicy', ['panelStatRatio'])):
            if row.get(key):
                original = copy.deepcopy(row[key])
                value = original[path[0]] * factor
                base = value / 2 if slot == 10 else value
                row[key] = original
                _put(row[key], path, base)
                fields[key] = [[path, base, base / 9]]
        row['skill'] = actions
        row['skillUp'] = shallow
        row['skillUpPaths'] = nested
        row['rankSettingGrowth104'] = fields
        row['rankGrowth104'] = {'schema': SCHEMA, 'slot': slot, 'magnitudes': checked}
        for action in actions:
            if action[0] == 'manual_ability' and action[1].startswith('skin2_'):
                _skin_rank_text(row, action[1])
        audit.append({'sid': sid, 'slot': slot, 'magnitudes': len(checked), 'settings': sorted(fields)})
    cfg['skill_rank_growth_104'] = {'schema': SCHEMA, 'hero_rows': sum(a.startswith('A_1') for a in cfg['avatar']),
                                    'skills': len(refs), 'audit': audit}
    return document
