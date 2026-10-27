"""Own-stat talents use a distinct multiplier on the complete equipped panel."""
from __future__ import annotations

from decimal import Decimal, ROUND_HALF_UP

STAT_TARGETS = {'attack': ('ap',), 'defense': ('de_ph', 'de_ma'), 'hp': ('hp',)}


def apply_talent_stats_103(document):
    cfg = document.get('cfg', document)
    names = {'attack': '攻击', 'defense': '物理与法术防御', 'hp': '生命上限'}
    for row in cfg.get('talent', {}).values():
        effect = row.get('growth_effect')
        if effect not in STAT_TARGETS:
            continue
        original = row.get('growth_base_value_103', row['growth_value'])
        value = float(Decimal(str(original)) * Decimal('0.6'))
        row['growth_base_value_103'] = original
        row['growth_value'] = value
        row['pl'][1] = value
        row['info'] = row['info_tw'] = f'自身总面板{names[effect]}提高{value:g}%。'
    cfg.setdefault('system_simple', {})['talent_total_panel_103'] = True
    return document


def apply_stat_talent(stats, talent_row):
    """Apply once after gear, DN, guild research and passive skill books."""
    targets = STAT_TARGETS.get(talent_row.get('growth_effect'), ())
    rate = max(0.0, float(talent_row.get('growth_value', 0))) / 100
    for key in targets:
        value = float(stats[key]) * (1 + rate)
        stats[key] = int(Decimal(str(value)).quantize(Decimal('.00001'), rounding=ROUND_HALF_UP))
