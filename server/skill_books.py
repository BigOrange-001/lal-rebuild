"""Shared skill-book calibration, rank curves and authoritative upgrade odds."""
from __future__ import annotations

import copy
import hashlib
import json
import math
import re
from decimal import Decimal
from pathlib import Path

from player_store import GameplayFault

QUALITY_NAMES = {1: '灰', 2: '白', 3: '绿', 4: '蓝', 5: '紫', 6: '橙', 7: '红'}
CALIBRATION_PATH = Path(__file__).resolve().parents[1] / 'config/reconstruction/equipment-calibration.json'
# Each material loses three percentage points per current level above one.
# Publish both values so preview and settlement use the same rule.
UPGRADE_WEIGHTS = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7]


def percentage(quality, level, multiplier=1):
    """White: .18..45, green: .24..60, continuing linearly through red."""
    if quality not in QUALITY_NAMES or type(level) is not int or not 1 <= level <= 10:
        raise ValueError('Invalid book quality or level')
    return float(Decimal(quality + 1) * Decimal(level + 5) / 100 * multiplier)


def apply_equipment_calibration(document):
    cfg = document.get('cfg', document)
    payload = CALIBRATION_PATH.read_bytes()
    calibration = json.loads(payload)
    if calibration.get('schema') != 'lal-equipment-calibration-v1':
        raise ValueError('Unknown equipment calibration schema')
    definitions = calibration.get('equipment')
    if not isinstance(definitions, dict) or set(definitions) != set(cfg.get('equip', {})):
        raise ValueError('Equipment calibration catalog differs from game definitions')
    for eid, raw in definitions.items():
        if (not isinstance(raw, dict) or raw.get('id') != eid
                or raw.get('quality') != cfg['equip'][eid].get('quality')
                or raw.get('type') not in (1, 3, 4, 5, 6)
                or not isinstance(raw.get('name'), str) or not raw['name'].strip()
                or not isinstance(raw.get('pl'), list) or len(raw['pl']) != 10):
            raise ValueError('Invalid equipment calibration: ' + eid)
        row = copy.deepcopy(raw)
        if row['type'] == 6:
            row['name'] = re.sub(r'[-－][灰白绿蓝紫橙红]$', '', row['name']) + '-' + QUALITY_NAMES[row['quality']]
        cfg['equip'][eid] = row
    simple = cfg.setdefault('system_simple', {})
    simple['skill_book_rand'] = list(UPGRADE_WEIGHTS)
    simple['skill_book_level_penalty'] = .03
    simple['skill_book_exp'][3] = 10
    cfg['equipment_calibration_overlay'] = {
        'schema': 'equipment-calibration-v1', 'sha256': hashlib.sha256(payload).hexdigest(),
        'rows': len(definitions), 'changed_ids': list(calibration.get('changed_ids', [])),
        'upgrade': 'one-level Bernoulli trial; min(1,sum(max(0,quality_weight-.03*(current_level-1))))',
    }
    apply_book_skill_rules(cfg)
    return document


def apply_book_skill_rules(cfg):
    if 'strong' in cfg.get('effect', {}):
        cfg['effect']['book_penetration'] = copy.deepcopy(cfg['effect']['strong'])
    known_passives = {
        'E_6001': ('ap',), 'E_6002': ('de_ph', 'de_ma'),
        'E_6003': ('shield_damage',), 'E_6004': ('tough',), 'E_6005': ('hit',),
        'E_6006': ('flee',), 'E_6007': ('crit',), 'E_6008': ('penetration',),
        'E_6009': ('attack_burn',), 'E_6010': ('healing',), 'E_6201': ('attack_curse',),
    }
    known_actives = {'E_6501': 'hit', 'E_6502': 'flee', 'E_6503': 'crit', 'E_6504': 'penetration'}
    stat_names = {'hit': '命中', 'flee': '闪避', 'crit': '暴击', 'tough': '韧性',
                  'ap': '总攻击力', 'de_ph': '总物防', 'de_ma': '总魔防',
                  'shield_damage': '对护盾伤害', 'penetration': '双抗穿透',
                  'attack_burn': '普攻附加灼烧比例', 'healing': '施放治疗效率',
                  'attack_curse': '普攻诅咒概率'}
    highest_impact = max(e['quality'] for eid, e in cfg['equip'].items() if eid.startswith('E_6505_'))
    highest_curse = max(e['quality'] for eid, e in cfg['equip'].items() if eid.startswith('E_6201_'))
    highest_penetration = max(e['quality'] for eid, e in cfg['equip'].items() if eid.startswith('E_6504_'))
    for eid, equip in cfg['equip'].items():
        if equip.get('type') != 6:
            continue
        family, q = eid.rsplit('_', 1)
        quality = int(q)
        if family not in known_passives and family not in known_actives and family not in ('E_6505', 'E_6506'):
            continue
        sid = 'S_' + str(90000 + int(family[2:])) + '_' + q
        old = cfg['skill'][equip['skill']]
        lo, step = percentage(quality, 1), (quality + 1) / 100
        if family in ('E_6001', 'E_6002'):
            lo, step = lo / 4, step / 4
        elif family == 'E_6201':
            scale = .08 / percentage(highest_curse, 10)
            lo, step = lo * scale, step * scale
        elif family == 'E_6504':
            # Active books double this curve below: top quality/rank is 90%.
            scale = .45 / percentage(highest_penetration, 10)
            lo, step = lo * scale, step * scale
        row = {'id': sid, 'name': equip['name'], 'res': old.get('res', old['id']),
               'bookRule': True, 'info': '', 'pl': None, 'skillUp': None}
        if family in known_passives:
            row['skill'] = [['book_passive', lo, stat] for stat in known_passives[family]]
            row['skillUp'] = [[i, 1, step] for i in range(len(row['skill']))]
            row['rankInfoTemplate'] = '被动：' + '、'.join(stat_names[s] for s in known_passives[family]) + '提高{rank:0:1}。'
            if family == 'E_6009':
                row['rankInfoTemplate'] = '普攻命中附加本次实际伤害{rank:0:1}的灼烧总伤害，分3回合结算。'
            elif family == 'E_6201':
                row['rankInfoTemplate'] = '普攻命中有{rank:0:1}概率诅咒当前目标，持续3回合。'
            elif family == 'E_6008':
                row['rankInfoTemplate'] += '穿透上限100%；与其他破甲、穿透效果只取最高值，不叠加。'
        elif family in known_actives:
            row['pl'] = [2, 2, 0, 0, 0, 0]
            row['skill'] = [['attrup', lo * 2, known_actives[family], 0, 1, 'FX_S9002_SHIELD']]
            if family == 'E_6504':
                row['skill'] = [['book_bonus', lo * 2, 'penetration', 1]]
            row['skillUp'] = [0, step * 2]
            row['rankInfoTemplate'] = '每3回合使自身' + stat_names[known_actives[family]] + '提高{rank:0:1}，持续1回合。'
            if family == 'E_6504':
                row['rankInfoTemplate'] += '与其他破甲、穿透效果只取最高值，不叠加。'
        else:
            # The highest available quality is the 110%..200% baseline.
            # Lower tiers scale only the impact;
            # the authored 100%-AP burn remains three ticks at every quality.
            scale = (quality + 1) / (highest_impact + 1)
            impact, impact_step = 1.1 * scale, .1 * scale
            row['pl'] = [1, 4, 3000, 0, -1, 1]
            if family == 'E_6505':
                row['skill'] = [['true_damage', impact, 'FX_S9004_ARC'],
                                ['book_burn', 3.0, 3, 'FX_S9004_ARC']]
                row['skillUp'] = [0, impact_step]
                row['actionTargetPolicies'] = ['enemy_lane_all', 'enemy_lane_all']
                row['rankInfoTemplate'] = '准备1回合，每5回合对当前分路全部敌人造成{rank:0:1}攻击的真实伤害，并施加灼烧：每回合100%攻击，持续3回合。'
            else:
                row['skill'] = [['caster_ap_shield', impact + 3, 3, 'FX_S9002_SHIELD']]
                row['skillUp'] = [0, impact_step]
                row['actionTargetPolicies'] = ['ally_lane_all']
                row['rankInfoTemplate'] = '准备1回合，每5回合为当前分路全体友军施加相当于自身{rank:0:1}攻击的护盾，持续3回合。'
        row['info'] = row['rankInfoTemplate'].replace('{rank:0:1}', f'{row["skill"][0][1]*100:g}%')
        cfg['skill'][sid] = row
        equip['skill'] = sid
        equip['pl'][8] = sid


def upgrade_probability(simple, level, material_definitions):
    weights = simple.get('skill_book_rand')
    if (not isinstance(weights, list) or len(weights) < 7
            or type(level) is not int or not 1 <= level <= 10):
        raise GameplayFault('InvalidConfig', 'Skill-book upgrade probability table is missing')
    total = Decimal(0)
    penalty=simple.get('skill_book_level_penalty',.03)
    if type(penalty) not in (int,float) or not math.isfinite(penalty) or penalty<0:
        raise GameplayFault('InvalidConfig','Invalid skill-book level penalty')
    loss=Decimal(str(penalty))*(level-1)
    for row in material_definitions:
        quality = row.get('quality')
        if type(quality) is not int or not 1 <= quality <= len(weights):
            raise GameplayFault('InvalidConfig', 'Invalid material book quality')
        weight = weights[quality - 1]
        if type(weight) not in (int, float) or not math.isfinite(weight) or weight < 0:
            raise GameplayFault('InvalidConfig', 'Invalid skill-book upgrade probability')
        total += max(Decimal(0),Decimal(str(weight))-loss)
    return float(min(Decimal(1),total)) if level<10 else 0.0
