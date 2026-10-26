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


def apply_power_balance_104(document):
    cfg = document.get('cfg', document)
    cfg['system_simple']['power_exponent'] = 1.5
    for row in cfg.get('talent', {}).values():
        row['power_factor_104'] = talent_power_factor(row)
    _scale_recommendations(document, cfg)
    return document


def recommendation_blend(index, first, stop):
    return max(0.0, min(1.0, (stop - index) / (stop - first + 1)))


def _scale_recommendations(document, cfg):
    from battle_engine import serialize_stage_team
    from campaign_workbook_overlay import _native_snapshot_power
    from gameplay_competition import GameplayCompetition
    from types import SimpleNamespace
    estimator = SimpleNamespace(cfg=cfg, simple=cfg['system_simple'])
    for table in ('combat_main', 'combat_ploy'):
        for cid, stage in cfg.get(table, {}).items():
            if stage.get('recommendation_schema') == 'power-1.0.4':
                continue
            if table == 'combat_main':
                index = int(cid.split('_')[1])
                blend = recommendation_blend(index, 11, 26)
            elif cid.startswith('P_200_'):
                blend = recommendation_blend(int(cid.rsplit('_', 1)[1]), 80, 151)
            else:
                continue
            originals = dict(stage.get('recommended_power_by_diff', {}))
            if not originals and 'recommended_power' in stage:
                originals = {'0': stage['recommended_power']}
            stage['recommended_power_original_104'] = originals
            values = {}
            for diff, original in originals.items():
                team = stage.get('team2_by_diff', {}).get(diff, stage.get('team2', []))
                units = serialize_stage_team(cfg, team, team=2)
                stats = stage.get('enemy_unit_stats_by_diff', {}).get(diff)
                if stats is not None:
                    if len(stats) != len(units):
                        raise ValueError(f'{cid}: recommendation snapshot length mismatch')
                    for unit, row in zip(units, stats):
                        if unit['aid'] != row['aid']:
                            raise ValueError(f'{cid}: recommendation snapshot order mismatch')
                        for key in ('hp', 'ap', 'de_ph', 'de_ma'):
                            unit[key] = row[key]
                        unit['hp_max'] = unit['hp']
                        unit['new_4attrs'] = {k: row.get(k, 0) for k in ('hit', 'flee', 'crit', 'tough')}
                old = _native_snapshot_power(cfg, units)
                new = GameplayCompetition._team_power(estimator, units)
                ratio = new / old if old > 0 else 1.0
                values[diff] = max(1, round(original * (1 - blend + blend * ratio)))
            stage['recommended_power_by_diff'] = values
            if '0' in values:
                stage['recommended_power'] = values['0']
            stage['recommendation_schema'] = 'power-1.0.4'
        if 'cfg' in document:
            document[table] = cfg[table]
            if isinstance(document.get('pve'), dict):
                document['pve'][table] = cfg[table]
