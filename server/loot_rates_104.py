"""Reviewed equipment probability reductions; exact rational elite rolls."""
from fractions import Fraction
from player_store import GameplayFault

SCHEMA = 'loot-rates-104-v1'


def elite_chance(tier):
    ratio = tier.get('chance_bp_fraction')
    if ratio is None:
        value = tier.get('chance_bp')
        if type(value) is not int or not 0 <= value <= 10000:
            raise GameplayFault('InvalidEquipmentDropPolicy', 'Invalid equipment chance')
        return Fraction(value, 10000)
    if (not isinstance(ratio, list) or len(ratio) != 2
            or any(type(v) is not int for v in ratio) or ratio[1] <= 0):
        raise GameplayFault('InvalidEquipmentDropPolicy', 'Invalid equipment chance ratio')
    chance = Fraction(*ratio)
    if not 0 <= chance <= 10000 or float(chance) != tier.get('chance_bp'):
        raise GameplayFault('InvalidEquipmentDropPolicy', 'Equipment chance does not match ratio')
    return chance / 10000


def apply_loot_rates_104(document):
    cfg = document.get('cfg', document)
    if cfg.get('loot_rates_104') == SCHEMA:
        return document
    policy = cfg['system_simple']['elite_equipment_drop']
    for tier in policy['tiers']:
        original = tier['chance_bp']
        divisor = 2 if tier['quality'] in (2, 3, 4) else 3
        value = Fraction(original, divisor)
        tier.update(chance_bp=float(value) if value.denominator != 1 else int(value),
                    chance_bp_fraction=[original, divisor])
    for stage in cfg['combat_ploy'].values():
        if not stage.get('ancient_equip_drop'):
            continue
        stage['ancient_equip_drop']['chance_bp'] //= 2
        if stage.get('ancient_exclusive_drop'):
            stage['ancient_exclusive_drop']['chance_bp'] //= 2
        stage['loot_rate_revision_104'] = SCHEMA
        chance = stage['ancient_equip_drop']['chance_bp'] / 100
        quality = {4: '蓝', 5: '紫', 6: '橙'}[stage['ancient_equip_drop']['quality']]
        note = f'胜利有{chance:g}%概率获得一件随机普通{quality}色装备。'
        if stage.get('ancient_exclusive_drop'):
            note += '另有2.5%概率额外获得一件专属橙装。'
        stage['reward_note'] = note
        stage['info'] = stage.get('info', '').split('胜利有')[0] + note
    cfg['loot_rates_104'] = SCHEMA
    return document
