"""Balanced elemental enchantment levels shared by previews and combat stats."""
import copy

DEFAULT_GAINS = (120, 10, 360, 30)
SYMP_STATS = ('hp', 'ap', 'de_ph', 'de_ma')
STAGE5_COST = (2, 3, 6, 8)
RUNE_GAINS = (500, 40, 40, 40)


def rules(config):
    cfg = config.get('cfg', config)
    simple = cfg.get('system_simple', cfg)
    return simple.get('equipment_magic', {})


def gain(config, color, level):
    policy = rules(config)
    step = policy.get('stat_per_level', [1, 1, 1, 1])[color]
    return max(0, int(level)) * max(0, int(step))


def upgrade_cost(config, color, level):
    cfg = config.get('cfg', config)
    simple = cfg.get('system_simple', cfg)
    base = simple.get('dust', {}).get('add_magic', [[1, 1, 1, 1]])[0][color]
    every = int(rules(config).get('cost_growth_every', 0))
    return max(1, int(base)) + (max(0, int(level)) // every if every > 0 else 0)


def stat_bonus(config, magic):
    levels = (list(magic or []) + [0] * 4)[:4]
    return {'hp': gain(config, 0, levels[0]) + gain(config, 2, levels[2]),
            'ap': gain(config, 1, levels[1]) + gain(config, 3, levels[3])}


def enchantment_stage(item):
    """Four elemental first unlocks, then one separately purchased fifth stage."""
    levels = item.get('magic') if isinstance(item, dict) else None
    if not isinstance(levels, list):
        levels = []
    stage = 0
    for level in levels[:4]:
        try:
            if int(level) <= 0:
                break
        except (TypeError, ValueError, OverflowError):
            break
        stage += 1
    if stage == 4 and item.get('magic_stage5') == 1:
        stage = 5
    return stage


def main_stat_multiplier(config, item):
    policy = rules(config)
    return 1.0 + enchantment_stage(item) * float(policy.get('stage_main_stat_step', 0))


def rune_bonus(config, item):
    """Independent flat bonus from one revealed elemental rune on one item."""
    result = {stat: 0 for stat in SYMP_STATS}
    if not isinstance(item, dict):
        return result
    color = item.get('symp', -1)
    if type(color) is not int or not 0 <= color < 4:
        return result
    level = max(0, int(item.get('rune_lv', 0) or 0))
    gains = rules(config).get('rune_stat_per_level', RUNE_GAINS)
    result[SYMP_STATS[color]] = level * max(0, int(gains[color]))
    return result


def rune_upgrade_cost(config, color, level):
    if type(color) is not int or not 0 <= color < 4:
        raise ValueError('rune color must be 0..3')
    policy = rules(config)
    current = max(0, int(level))
    return max(1, int(policy.get('rune_dust_base', 2))) + current, \
           max(1, int(policy.get('rune_mark_step', 100))) * (current + 1)


def symp_bonuses(config, counts):
    """Match Avatar's int(count * tier_factor * flat_value) for 2–6 pieces."""
    cfg = config.get('cfg', config)
    simple = cfg.get('system_simple', cfg)
    pair = simple.get('dust', {}).get('symp', [[], []])
    flats = pair[0] if isinstance(pair, list) and len(pair) > 0 else []
    factors = pair[1] if isinstance(pair, list) and len(pair) > 1 else []
    result = {stat: 0 for stat in SYMP_STATS}
    for color, stat in enumerate(SYMP_STATS):
        count = max(0, int(counts[color])) if color < len(counts) else 0
        if count >= 2 and color < len(flats) and factors:
            count = min(count, len(factors) + 1)
            result[stat] = int(count * float(factors[count - 2]) * float(flats[color]))
    return result


def apply_equipment_magic_config(document):
    output = copy.deepcopy(document)
    cfg = output['cfg']
    simple = cfg['system_simple']
    simple['equipment_magic'] = {'schema': 'elemental-enchantment-v3',
        'stat_per_level': list(DEFAULT_GAINS), 'cost_growth_every': 20,
        'stage_main_stat_step': 0.10, 'stage_max': 5,
        'stage5_cost': list(STAGE5_COST),
        'rune_max': 10, 'rune_stat_per_level': list(RUNE_GAINS),
        'rune_dust_base': 2, 'rune_mark_step': 100,
        'attributes': ['hp', 'ap', 'hp', 'ap'],
        'names': ['绿阶生命', '蓝阶攻击', '紫阶生命', '金阶攻击']}
    simple['dust']['max'] = [100, 100, 100, 100]
    simple['dust']['add_magic'] = [[2, 3, 6, 8]]
    simple['dust']['symp'] = [[4000, 300, 600, 600], [1, 1.25, 1.5, 1.75, 2]]
    if simple.get('equipment_potential_schema') != 'sixfold-v1':
        simple['equip_config'][3] *= 6
        simple['equipment_potential_schema'] = 'sixfold-v1'
    # Existing elemental levels retain their investment and receive the new
    # stat-per-level values; no committed or pending wash values are rewritten.
    return output
