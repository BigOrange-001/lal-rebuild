"""Late-added skins share the existing roster snapshots and equipment rules."""
from __future__ import annotations
import copy
import json
from pathlib import Path

PLAN = Path(__file__).resolve().parents[1] / 'config/reconstruction/new-skin-bonds-1.0.4.json'


def apply_new_skin_bonds_104(document):
    cfg = document.get('cfg', document)
    simple = cfg['system_simple']
    if simple.get('new_skin_bonds_104'):
        return document
    # Reconstruction builders deliberately disable the base bond passes when
    # generating their input catalogues. Do not re-enable dependent bonds there.
    if simple.get('bonds_schema') != '1.0.4' or not simple.get('equipment_bonds_schema_104'):
        return document
    plan = json.loads(PLAN.read_text('utf8'))
    skins = set(simple['skin_hero_ids'])
    definitions = simple['bonds_104']
    for bond in copy.deepcopy(plan['bonds']):
        if set(bond['families']) != set(bond['benefits']):
            raise ValueError('New skin bond membership mismatch')
        orange_ids = {family + '_6' for family in bond['families']}
        if not orange_ids <= cfg['avatar'].keys() or not orange_ids & skins:
            raise ValueError('New skin bonds require valid heroes and at least one six-star skin')
        if any(row['id'] == bond['id'] for row in definitions):
            raise ValueError('Duplicate new skin bond ID')
        bond['minimum_quality'] = {family: 6 for family in bond['families']}
        # The late overlay applies stats and battle mechanics directly. Its
        # bonds have no rows in the prebuilt skill-variant combination table.
        bond['runtime_only'] = True
        definitions.append(bond)
    equipment = simple['equipment_bonds_104']
    from equipment_rebinding_105 import rebind_new_skins, validate_bindings
    rebind_new_skins(cfg,plan['equipment'])
    for aid, rows in plan['equipment'].items():
        if equipment.get(aid) or len(rows) != 2:
            raise ValueError('New skins need exactly two new equipment affinities')
        if len({cfg['equip'][r['equipment']]['slot'] for r in rows}) != 2:
            raise ValueError('New skin equipment affinities must be wearable together')
        equipment[aid] = copy.deepcopy(rows)
    notes = {
        'S_98618010_6': '龙影夜刃羁绊激活时，每发命中额外施加33%破甲，持续1回合。',
        'S_98618013_6': '',
        'S_98618021_6': '异界剑盟羁绊激活时，本技能伤害提升12%，并且可以在被沉默时释放。',
        'S_98618023_6': '龙影夜刃羁绊激活时，暴击附加伤害提高至50%。',
    }
    for q in (5, 6):
        notes[f'S_98618030_{q}'] = (
            '蛮易信三兄弟激活时，伤害系数提高30%，对召唤物造成双倍伤害。'
            '狂怒恶魔激活时，命中存活目标后施加2回合诅咒。')
        notes[f'S_98618033_{q}'] = (
            '穿戴无尽之刃时，普攻伤害系数提高至235%攻击力。'
            '凛冬怒火激活时，怒气获取量和各来源的获取限额提高50%，总上限仍为100。')
    for sid, note in notes.items():
        if note:
            row = cfg['skill'][sid]
            row['info'] += '\n' + note
            row['rankInfoTemplate'] += '\n' + note
    cfg['equipment_bonds_104']['heroes'] = len(equipment)
    cfg['equipment_bonds_104']['stats'] = sum(
        row['kind'] == 'stats' for rows in plan['equipment'].values() for row in rows)
    simple['new_skin_bonds_104'] = plan['schema']
    validate_bindings(cfg)
    return document


def mechanic_value(cfg, unit, key, default=0):
    family = str(unit.get('aid', '')).split('|')[0].rsplit('_', 1)[0]
    active = set(unit.get('bonds_104') or [])
    value = default
    for bond in cfg.get('system_simple', {}).get('bonds_104', []):
        if bond['id'] in active:
            candidate = bond['benefits'].get(family, {}).get('mechanics', {}).get(key)
            if candidate is not None:
                value = max(value, candidate)
    return value
