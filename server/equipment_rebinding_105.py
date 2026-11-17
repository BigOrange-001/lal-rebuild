"""Reviewed equipment ownership; retain authored skill effects when moving a bond."""
import copy
import json
from collections import Counter
from pathlib import Path

PLAN = Path(__file__).resolve().parents[1] / 'config/reconstruction/equipment-binding-20261117.json'


def load_plan():
    return json.loads(PLAN.read_text('utf8'))


def rebind_ordinary(cfg, plan):
    design = load_plan()
    for aid, hero in plan['heroes'].items():
        replacements = design['ordinary'][aid]
        if len(replacements) != len(hero['affinities']):
            raise ValueError('Equipment affinity count changed: ' + aid)
        for effect, eid in zip(hero['affinities'], replacements):
            effect['previous_equipment_105'] = effect['equipment']
            effect['equipment'] = eid
            # A change of item quality must not silently rebalance the skill.
            effect['power_budget'] = effect['skill_budget']
        hero['equipment'] = replacements
        if aid == 'A_1221_6':
            effect = next(e for e in hero['affinities'] if e['equipment'] == 'E_4999_6')
            effect.update(passive_extra_105=True, slot='passive', index='annie_core', path=[],
                          reworks={}, skill_name='不讲道理', part='异常反击与全队净化',
                          info=design['annie_core']['info'], strength=0, power_budget=.20)


def rebind_new_skins(cfg, equipment):
    design = load_plan()
    for aid, replacements in design['stats'].items():
        if len(replacements) != len(equipment[aid]):
            raise ValueError('Stat affinity count changed: ' + aid)
        for row, eid in zip(equipment[aid], replacements):
            old = cfg['equip'][row['equipment']]['name']
            row['previous_equipment_105'] = row['equipment']
            row['equipment'] = eid
            row['info'] = row['info'].replace(old, cfg['equip'][eid]['name'])
            if aid == 'A_1801_6' and eid == 'E_3004_6':
                row['name'] = '虚空龙甲'


def annie_passive(row):
    spec = load_plan()['annie_core']
    row['name'] += '·不讲道理'
    row['pl'][:2] = [spec['warmup'], spec['cooldown']]
    row['annie_core_105'] = copy.deepcopy(spec)
    for field in ('info', 'rankInfoTemplate'):
        row[field] = row.get(field, '') + '\n烈焰核心追加被动（准备0、冷却1）：' + spec['info']


def validate_bindings(cfg):
    definitions = cfg['system_simple']['equipment_bonds_104']
    gear = {eid for eid, e in cfg['equip'].items() if e.get('quality') in (5, 6) and e.get('type') != 6}
    owners = Counter()
    for aid, rows in definitions.items():
        ids = [r['equipment'] for r in rows]
        if len(ids) != len(set(ids)):
            raise ValueError('Duplicate personal equipment affinity: ' + aid)
        owners.update(ids)
    if set(owners) != gear or any(n > 3 for n in owners.values()):
        raise ValueError('Every purple/orange equipment must have one to three bond owners')
    cfg['system_simple']['equipment_binding_schema_105'] = load_plan()['schema']
