"""Fit campaign enemies to the current soul-tower snapshot power curve."""
import math
import re

from campaign_workbook_overlay import _fit_power, _power
from power_balance_104 import POWER_SCHEMA, POWER_STAT_SCHEMA, normalize_team_power

SCHEMA = 'campaign-tower-difficulty-104-v2'


def mapped_floor(chapter, diff):
    if diff == 0:
        return None if chapter <= 5 else 10 + (chapter - 6) * 70 / 24
    if diff == 1:
        return 10 + (chapter - 1) * 115 / 29
    raise ValueError('Unknown campaign difficulty')


def floor_power(powers, floor):
    lower, upper = math.floor(floor), math.ceil(floor)
    if lower == upper:
        return powers[lower]
    # Interpolate multiplicative difficulty between adjacent actual floors.
    return round(powers[lower] * (powers[upper] / powers[lower]) ** (floor - lower))


def apply_campaign_tower_difficulty_104(document):
    cfg = document.get('cfg', document)
    if cfg.get('campaign_tower_difficulty_104', {}).get('schema') == SCHEMA:
        return document
    powers = {}
    for cid, stage in cfg['combat_ploy'].items():
        if stage.get('activity_kind') != 'tower' or int(stage['tower_floor']) > 125:
            continue
        actual = _power(cfg, stage['team2'], stage['enemy_unit_stats_by_diff']['0'])
        powers[int(stage['tower_floor'])] = actual
        stage['recommended_power_original_104'] = {'0': actual}
        stage['recommended_power_by_diff'] = {'0': normalize_team_power(actual)}
        stage['recommended_power'] = normalize_team_power(actual)
        stage['recommendation_schema'] = POWER_SCHEMA
        stage['enemy_snapshot_power'] = actual
    chapters = {}
    for cid, stage in cfg['combat_main'].items():
        match = re.fullmatch(r'M_(\d{3})_(\d+)', cid)
        if match:
            chapters.setdefault(int(match[1]), []).append((int(match[2]), stage))
    first_chapter_boss = max(chapters[1], key=lambda pair: pair[0])[1]
    early_start = first_chapter_boss['recommended_power_by_diff']['0']
    report = []
    for chapter, stages in sorted(chapters.items()):
        stages.sort(key=lambda pair: pair[0])
        for diff in (0, 1):
            floor = mapped_floor(chapter, diff)
            if floor is None:
                if chapter == 1:
                    continue
                recommended = early_start + (20000 - early_start) * (chapter - 1) / 4
                target = round(1_000_000 * (recommended / 1_000_000) ** (4 / 3))
            else:
                target = floor_power(powers, floor)
            key = str(diff)
            original_powers = []
            for _, stage in stages:
                team = stage.get('team2_by_diff', {}).get(key, stage['team2'])
                rows = stage['enemy_unit_stats_by_diff'][key]
                original_powers.append(_power(cfg, team, rows))
            boss_power = original_powers[-1]
            for (_, stage), original in zip(stages, original_powers):
                team = stage.get('team2_by_diff', {}).get(key, stage['team2'])
                rows = stage['enemy_unit_stats_by_diff'][key]
                budget = round(target * original / boss_power)
                fitted, actual = _fit_power(cfg, team, rows, budget)
                stage['enemy_unit_stats_by_diff'][key] = fitted
                stage['recommended_power_original_104'][key] = actual
                stage['recommended_power_by_diff'][key] = normalize_team_power(actual)
                if diff == 0:
                    stage['recommended_power'] = normalize_team_power(actual)
                stage.setdefault('campaign_tower_mapping_104', {})[key] = {
                    'tower_floor': floor, 'chapter_boss_target_power': target,
                    'within_chapter_ratio': original / boss_power,
                    'target_power': budget, 'actual_power': actual,
                }
                stage['recommended_power_source'] = 'actual enemy snapshot fitted to mapped soul-tower floor'
            report.append(dict(chapter=chapter, diff=diff, tower_floor=floor,
                               boss_target_power=target,
                               boss_recommended_power=stages[-1][1]['recommended_power_by_diff'][key]))
    cfg['campaign_tower_difficulty_104'] = dict(
        schema=SCHEMA, power_stat_schema=POWER_STAT_SCHEMA,
        normal={'unchanged_chapters': [1, 1], 'early_chapters': [1, 5],
                'early_boss_recommendation': [early_start, 20000],
                'chapters': [6, 30], 'floors': [10, 80]},
        elite={'chapters': [1, 30], 'floors': [10, 125]},
        anchor='chapter finale', interpolation='linear floor; geometric between adjacent floor powers',
        chapters=report)
    if 'cfg' in document:
        for table in ('combat_main', 'combat_ploy'):
            document[table] = cfg[table]
            if isinstance(document.get('pve'), dict):
                document['pve'][table] = cfg[table]
    return document
