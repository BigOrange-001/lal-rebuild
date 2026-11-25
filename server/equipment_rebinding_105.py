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
    apply_six_star_redesigns(cfg, plan)


# (hero, equipment, slot, component, action index, expected action, path, output share)
# Shares below one keep a focused hit or secondary effect within the original budget.
SIX_STAR_REDESIGNS = (
    ('A_1053_6', 'E_5001_5', 'normal', '快速拔枪的普攻增伤幅度', 0, 'six_next_graves_n', (5,), 1),
    ('A_1119_6', 'E_1001_6', 'normal', '疾风斩第二段伤害', 2, 'damage', (1,), .56),
    ('A_1119_6', 'E_3007_6', 'passive', '浪客之道的生命值护盾', 0, 'six_batch_yasuo_p', (5,), 1),
    ('A_1130_6', 'E_1016_6', 'captain', '利刃华尔兹每次斩击的伤害系数', 0, 'six_fiora_c', (4,), 1),
    ('A_1054_6', 'E_3999_5', 'passive', '巨龙真身的灼烧转护盾比例', 0, 'six_next_shyvana_p', (4,), 1),
    ('A_1205_6', 'E_1501_5', 'captain', '自然之握的最大生命伤害系数', 0, 'six_next_maokai_c', (4,), 1),
    ('A_1205_6', 'E_3001_6', 'passive', '吸元秘术的普攻回血比例', 0, 'six_next_maokai_p', (4,), 1),
    ('A_1033_6', 'E_5008_6', 'normal', '暗影突袭的破甲幅度', 1, 'sunder_percent', (3,), 1),
    ('A_1060_6', 'E_1002_6', 'passive', '光束护盾的攻击力护盾系数', 0, 'six_next_lux_p', (4,), 1),
    ('A_1086_6', 'E_1022_6', 'normal', '苍白之瀑护盾的双抗系数', 0, 'six_next_diana_n', (5,), 1),
    ('A_1086_6', 'E_4027_6', 'captain', '月神降临每段的双抗伤害系数', 0, 'six_next_diana_c', (4,), 1),
    ('A_1098_6', 'E_4002_6', 'captain', '安魂曲引导完成后的全场伤害', 0, 'six_next_karthus_c', (4,), 1),
    ('A_1114_6', 'E_1502_5', 'normal', '连锁闪电每次释放的首击伤害', 0, 'six_next_aoxing_n', (4,), .55),
    ('A_1124_6', 'E_4015_6', 'captain', '沙兵支援的正面冲击伤害', 0, 'damage', (1,), 1),
    ('A_1127_6', 'E_1505_5', 'normal', '幻影魔弹引爆恶意魔印的真伤', 0, 'six_next_leblanc_n', (5,), .6),
    ('A_1133_6', 'E_1999_5', 'passive', '灵魂庇护的生命值护盾', 0, 'six_morgana_p', (4,), 1),
    ('A_1214_6', 'E_3006_6', 'captain', '逆命对当前目标的魔法伤害', 0, 'six_batch_tf_c', (4,), 1),
    ('A_1131_6', 'E_5004_5', 'normal', '潮汐涌泉赋予友军的追加真伤', 0, 'six_nami_n', (5,), .6),
    ('A_1005_6', 'E_1017_6', 'normal', '真假猴王的直接物理伤害', 0, 'wukong_n', 'wukong_hit', .65),
    ('A_1005_6', 'E_3010_6', 'normal', '真假猴王分身的面板继承比例', 0, 'wukong_n', 'wukong_clone_panel', 1),
    ('A_1007_6', 'E_3001_5', 'captain', '真-天崩地裂的生命值护盾', 0, 'hp_shield', (1,), 1),
    ('A_1011_6', 'E_3004_5', 'normal', '枪火谈判中橘子的攻击力回复系数', 0, 'gangplank_n', 'orange_heal_ap', 1),
    ('A_1019_6', 'E_3002_5', 'normal', '旋斧回旋的命中回复及回复上限', 3, 'heal_missing_hp_per_hero', (1, 2), 1),
    ('A_1018_6', 'E_4004_5', 'normal', '守护屏障强化普攻的生命伤害系数', 0, 'six_shen_n', (4,), 1),
)


def apply_six_star_redesigns(cfg, plan):
    slots = {'normal': 10, 'captain': 11, 'passive': 13}
    for aid, eid, slot, part, index, expected, targets, share in SIX_STAR_REDESIGNS:
        effect = next(row for row in plan['heroes'][aid]['affinities'] if row['equipment'] == eid)
        source = cfg['skill'][cfg['avatar'][aid]['pl'][slots[slot]]]
        actions = source['skill']
        action = actions[index]
        prefix = ['manual_ability', expected] if action[0] == 'manual_ability' else [expected]
        if action[:len(prefix)] != prefix:
            raise ValueError(f'Six-star affinity target changed: {aid} {eid} {part}')
        budget = effect['skill_budget']
        strength = budget / share
        for key in ('six_star_component_removed', 'six_star_native_component', 'review_source_104', 'manual_kind'):
            effect.pop(key, None)
        effect.update(slot=slot, part=part, skill_name=source['name'], strength=strength,
                      power_budget=budget, benefit_share=share, benefit_curve=1,
                      info=f'仅提高{part}{strength:.2%}。')
        if isinstance(targets, str):
            effect.update(index=targets, path=[], manual_kind=expected)
        else:
            effect.update(index=index, path=[targets[0]], extra_paths=[[i] for i in targets[1:]],
                          expected_action=prefix, signature=[a[0] for a in actions[:index+1]])
        if (aid, eid) == ('A_1007_6', 'E_3001_5'):
            effect['reworks']['光盾壁垒'] = {
                'index': 1, 'path': [1], 'signature': ['damage', 'caster_hp_shield'],
                'part': '光盾壁垒的生命值护盾', 'info': f'仅提高光盾壁垒的生命值护盾{strength:.2%}。',
            }


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
