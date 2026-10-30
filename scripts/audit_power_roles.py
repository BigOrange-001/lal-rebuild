"""Compare role power under equal progression using real runtime snapshots."""
from __future__ import annotations

import argparse
import copy
import csv
import json
import statistics
from pathlib import Path

from battle_engine import base_unit
from gameplay_competition import GameplayCompetition
from gameplay_roster import GameplayRosterEquipment
from gateway import load_game_config
from power_balance_104 import LEGACY_POWER_STAT_WEIGHTS, POWER_STAT_WEIGHTS

ROOT = Path(__file__).resolve().parents[1]
ROLES = {1: '攻击', 2: '功能', 3: '坦克'}
SCENARIOS = (
    ('lv1', 1, 0, 0, False, True),
    ('lv60', 60, 0, 0, False, True),
    ('lv99', 99, 0, 0, False, True),
    ('lv99_member', 99, 0, 0, False, False),
    ('lv99_culture', 99, 0, 750, False, True),
    ('lv99_equipped', 99, 0, 0, True, True),
    ('lv125_phase3', 125, 3, 750, False, True),
)


def build_samples(document):
    cfg = document['cfg']
    before = copy.deepcopy(document)
    before['cfg']['system_simple']['power'][1:5] = LEGACY_POWER_STAT_WEIGHTS
    old_power = GameplayCompetition(None, before)
    new_power = GameplayCompetition(None, document)
    roster = GameplayRosterEquipment(None, document)
    samples = []
    for scenario, level, phase, culture, equipped, leader in SCENARIOS:
        for aid, definition in sorted(cfg['avatar'].items()):
            quality = int(aid.rsplit('_', 1)[-1])
            role = definition.get('stat_profile')
            if not aid.startswith('A_1') or quality not in (5, 6) or role not in ROLES:
                continue
            if level > 99 and quality != 6:
                continue
            iid = aid + '|power-audit'
            hero = dict(id=iid, aid=aid, lv=level, slv=10, phase=phase, morph=0,
                        hp=culture, ap=culture, de_ph=culture, de_ma=culture,
                        limit_break=int(level > 99))
            equipment = ['E_1001_5', 'E_3001_5', 'E_4001_5', 'E_5001_5'] if equipped else []
            profile = dict(avatars={iid: hero}, team=[[iid]], attrs={'team_num': 0, 'dn': {}},
                           as_equips=[equipment], my_equips={
                               eid: dict(eid=eid, lv=100, stat_roll_ppm=1000000)
                               for eid in equipment})
            raw = roster.battle_attributes(profile, iid, hero_only=not equipped)
            overrides = {**raw, 'leader_skill': raw['leader_skill'] if leader else None,
                         'new_4attrs': {k: raw.get(k, 0) for k in ('hit', 'flee', 'crit', 'tough')}}
            unit = base_unit(cfg, aid, level, 10, 0, .2, leader, 1, iid, overrides,
                             limit_break=level > 99)
            samples.append(dict(aid=aid, name=definition['name'], role=role,
                                role_name=ROLES[role], quality=quality, scenario=scenario,
                                hp=unit['hp_max'], ap=unit['ap'], de_ph=unit['de_ph'],
                                de_ma=unit['de_ma'], old_power=old_power._team_power([unit]),
                                new_power=new_power._team_power([unit])))
    return samples


def summarize(samples):
    output = []
    strata = sorted({(r['scenario'], r['quality']) for r in samples})
    for scenario, quality in strata:
        roles = []
        for role in ROLES:
            rows = [r for r in samples if (r['scenario'], r['quality'], r['role']) ==
                    (scenario, quality, role)]
            if not rows:
                continue
            roles.append(dict(role=role, name=ROLES[role], count=len(rows),
                              **{field: statistics.mean(r[field] for r in rows)
                                 for field in ('hp', 'ap', 'de_ph', 'de_ma', 'old_power', 'new_power')},
                              old_median=statistics.median(r['old_power'] for r in rows),
                              new_median=statistics.median(r['new_power'] for r in rows)))
        gap = lambda field: max(r[field] for r in roles) / min(r[field] for r in roles) - 1
        output.append(dict(scenario=scenario, quality=quality, roles=roles,
                           old_mean_gap=gap('old_power'), new_mean_gap=gap('new_power'),
                           old_median_gap=gap('old_median'), new_median_gap=gap('new_median')))
    return output


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, default=ROOT / 'build/power-role-balance-20261029')
    args = parser.parse_args()
    samples = build_samples(load_game_config(ROOT / 'config/reconstruction/full-config.json'))
    report = dict(old_weights=LEGACY_POWER_STAT_WEIGHTS, weights=POWER_STAT_WEIGHTS,
                  sample_count=len(samples), summary=summarize(samples))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.with_suffix('.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    with args.output.with_suffix('.csv').open('w', encoding='utf-8-sig', newline='') as target:
        writer = csv.DictWriter(target, fieldnames=list(samples[0]))
        writer.writeheader()
        writer.writerows(samples)
    for row in report['summary']:
        values = [(r['name'], round(r['old_power']), round(r['new_power'])) for r in row['roles']]
        print(row['scenario'], row['quality'], values,
              f"mean gap {row['old_mean_gap']:.1%} -> {row['new_mean_gap']:.1%}")


if __name__ == '__main__':
    main()
