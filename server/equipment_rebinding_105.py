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


def rebind_six_star_components(cfg, plan):
    if not cfg.get('six_star_balance_105'):
        return
    # Keep the original item's relative strength when its skill component
    # survives the rewrite. A removed component has no coefficient to boost.
    changes = {
        'A_1005_6': [None, None],
        'A_1007_6': [(), None],
        'A_1011_6': [('火刀每回合的点燃伤害', 0, 4, ['manual_ability']), None],
        'A_1013_6': [(), ('无护盾时的应急屏障', 0, 6, ['mod_step'])],
        'A_1017_6': [('跃至前排后的长矛重击', 2, 1, ['damage', 'move_to_target_lane', 'damage', 'stun', 'caster_hp_shield']),
                     ('贯日长矛的生命护盾', 4, 1, ['damage', 'move_to_target_lane', 'damage', 'stun', 'caster_hp_shield'])],
        'A_1018_6': [None, ('舍身佑护的生命护盾', 0, 4, ['manual_ability'])],
        'A_1019_6': [('回旋斧直接命中伤害', 2, 1, ['pull_group', 'sunder_percent', 'damage', 'heal_missing_hp_per_hero']), None],
        'A_1023_6': [('飞叶回收段伤害', 0, 5, ['manual_ability']), ()],
        'A_1025_6': [('让子弹飞的狙击伤害', 0, 4, ['manual_ability']),
                     ('绳网命中的魔法伤害', 0, 4, ['manual_ability'])],
        'A_1033_6': [('魅影猎袭对低血量目标的魔法伤害', 0, 4, ['manual_ability']), ()],
        'A_1036_6': [('毒蛛猎杀的低血量增伤', 0, 6, ['manual_ability']), ()],
        'A_1115_6': [('鱼骨头对周围次要目标的溅射伤害', 0, 5, ['manual_ability']),
                     ('飞弹已损生命附加伤害系数', 0, 5, ['manual_ability'])],
        'A_1119_6': [(), None],
        'A_1123_6': [('回力标真实伤害', 0, 1, ['true_damage', 'weak_percent', 'curse']), ()],
        'A_1125_6': [('爆破弹对周围次要目标的溅射伤害', 0, 5, ['manual_ability']),
                     ('地狱火炮中心真伤', 0, 4, ['manual_ability'])],
        'A_1214_6': [None, ('万能选牌的魔法伤害', 0, 4, ['manual_ability'])],
        'A_1130_6': [None, ('决斗突刺的溢出护盾', 0, 6, ['manual_ability'])],
        'A_1131_6': [('潮汐涌泉的治疗', 0, 4, ['manual_ability']), None],
        'A_1133_6': [None, ('灵魂镣铐到期伤害', 0, 5, ['manual_ability'])],
        'A_1053_6': [(), None],
        'A_1054_6': [(), None],
        'A_1056_6': [('折翼之舞第三式伤害', 0, 6, ['manual_ability']),
                     ('折翼之舞第二式护盾', 0, 8, ['manual_ability'])],
        'A_1060_6': [None, ()],
        'A_1086_6': [None, None],
        'A_1098_6': [(), None],
        'A_1114_6': [None, ('连锁闪电后续弹射伤害', 0, 5, ['manual_ability'])],
        'A_1127_6': [None, ()],
        'A_1205_6': [None, None],
    }
    for aid, replacements in changes.items():
        for effect, change in zip(plan['heroes'][aid]['affinities'], replacements):
            if change is None:
                effect['six_star_component_removed'] = True
                effect['power_budget'] = 0
                effect['info'] = '六星技能改版后已移除此组件，这项羁绊不再提供技能加成。'
            elif change:
                part, index, position, signature = change
                effect.update(part=part, index=index, path=[position], signature=signature,
                              info=f'仅提高{part}{effect["strength"]:.2%}。')
                # Existing explicit full-rework mappings still select their
                # own components. They never inherit the replacement index.
                if signature == ['manual_ability']:
                    effect['six_star_native_component'] = True
                    effect.pop('manual_kind',None)


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
