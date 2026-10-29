"""Shared, effect-based talent valuation for the 1.0.4 power projection."""
from __future__ import annotations


def talent_power_factor(row):
    # Main stats and team secondary stats are already valued by the panel.
    # Recovery assumes 25% effective healing/shield uptime; sunder assumes
    # 25% of damage meets meaningful armor. No unconditional rarity premium.
    effect = row.get('growth_effect')
    rate = max(0.0, float(row.get('growth_value', 0))) / 100
    if effect == 'recovery':
        return rate * .25
    if effect == 'enemy_sunder':
        return .25 * min(rate, .9) / (1 - min(rate, .9))
    return 0.0


POWER_ANCHOR = 1_000_000
POWER_SCHEMA = 'team-anchor-1m-104-v1'
POWER_STAT_SCHEMA = 'role-balanced-panel-104-v2'
POWER_STAT_WEIGHTS = (0.29, 1.5, 1.8, 1.8)
LEGACY_POWER_STAT_WEIGHTS = (0.5, 2.0, 0.625, 0.625)


def normalize_team_power(value):
    """Compress the complete squared-panel team budget once, never per member."""
    import math
    value = float(value)
    if not math.isfinite(value) or value <= 0:
        return 0
    return math.floor(POWER_ANCHOR * (value / POWER_ANCHOR) ** .75 + .000005)


def apply_power_balance_104(document):
    cfg = document.get('cfg', document)
    simple = cfg.setdefault('system_simple', {})
    power = simple.get('power', [])
    if not isinstance(power, list) or len(power) < 13:
        power = [1e-8, .5, 2, .625, .625, 1000, .1, .1, .5, .01, 2, .1, .1]
    power = list(power)
    power[1:5] = POWER_STAT_WEIGHTS
    simple.update(power=power, power_exponent=2, power_anchor=POWER_ANCHOR,
                  power_team_exponent=.75, power_schema=POWER_SCHEMA,
                  power_stat_schema=POWER_STAT_SCHEMA,
                  power_stat_weights=dict(zip(('hp', 'ap', 'de_ph', 'de_ma'), POWER_STAT_WEIGHTS)))
    for row in cfg.get('talent', {}).values():
        row['power_factor_104'] = talent_power_factor(row)
    _scale_recommendations(document, cfg)
    return document


def recommendation_blend(index, first, stop):
    # Kept for older calibration callers; display units now change at every tier.
    return max(0.0, min(1.0, (stop - index) / (stop - first + 1)))


def _scale_recommendations(document, cfg):
    # Recommendations are authored difficulty budgets, not enemy stat changes.
    # Always convert the saved original budget; never compound on reapplication.
    for table in ('combat_main', 'combat_ploy'):
        for stage in cfg.get(table, {}).values():
            if stage.get('recommendation_schema') == POWER_SCHEMA:
                continue
            originals = dict(stage.get('recommended_power_original_104',
                                        stage.get('recommended_power_by_diff', {})))
            if not originals:
                originals = {'0': stage.get('recommended_power', stage.get('ulv', 0))}
            stage['recommended_power_original_104'] = originals
            values = {str(diff): normalize_team_power(value) for diff, value in originals.items()}
            stage['recommended_power_by_diff'] = values
            if '0' in values:
                stage['recommended_power'] = values['0']
            stage['recommendation_schema'] = POWER_SCHEMA
        if 'cfg' in document:
            document[table] = cfg[table]
            if isinstance(document.get('pve'), dict):
                document['pve'][table] = cfg[table]
    return document
