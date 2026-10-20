"""Apply the user-approved tier adjustments to the loaded 1.0.3 config."""
from __future__ import annotations

import copy
import hashlib
import json
import re
from collections import defaultdict
from pathlib import Path

from captain_strength import _scale_captain_row


PLAN = Path(__file__).resolve().parents[1] / 'config/reconstruction/hero-balance-1.0.3.json'
SCHEMA = 'hero-tier-balance-1.0.3-v1'


def adjustment(tier, win_rate):
    if tier == 'T4':
        return 1.12, 1.25, 'T4'
    if tier == 'T3' and win_rate < .45:
        return 1.08, 1.15, 'T3-low'
    if .45 <= win_rate <= .50:
        return 1.05, 1.05, 'unchanged'
    return 1.0, 1.0, 'unchanged'


def _timing(row, mode):
    pl = row.get('pl')
    if not isinstance(pl, list) or len(pl) < 2:
        return
    original = list(pl[:2])
    for index in (0, 1):
        value = pl[index]
        if type(value) not in (int, float) or value < 0:
            continue
        threshold = 0 if mode == 'T4' else 2 if index == 0 else 3
        if mode != 'unchanged' and value >= threshold:
            pl[index] = max(0, value - 1)
    for key in ('info', 'info_tw', 'rankInfoTemplate'):
        text = row.get(key)
        if not isinstance(text, str):
            continue
        for index, label in ((0, '准备'), (1, '冷却')):
            if original[index] != pl[index]:
                text = re.sub(label + r'\s*' + re.escape(f'{original[index]:g}') + r'(?![\d.])',
                              label + f'{pl[index]:g}', text)
        row[key] = text


def _private_skill_id(sid, factor, mode):
    digest = hashlib.sha256(f'{SCHEMA}:{sid}:{factor}:{mode}'.encode()).hexdigest()
    return f'S_8{int(digest[:12],16)}_{sid.rsplit("_",1)[-1]}'


def apply_hero_balance_103(document, plan=None):
    if plan is None:
        plan = json.loads(PLAN.read_text('utf-8'))
    digest = hashlib.sha256(json.dumps(plan, sort_keys=True, ensure_ascii=False).encode()).hexdigest()
    cfg = document['cfg']
    previous = cfg.get('hero_balance_103')
    if previous:
        if previous.get('schema') == SCHEMA and previous.get('plan_sha256') == digest:
            return previous
        raise ValueError('A different hero balance plan is already applied')
    by_family = {}
    for item in plan['heroes']:
        aid = item['aid']
        if aid not in cfg['avatar']:
            raise ValueError(f'Balance hero is missing: {aid}')
        family = aid.rsplit('_',1)[0]
        entry = adjustment(item['tier'], item['old_win_rate'])
        if family in by_family and by_family[family] != entry:
            raise ValueError(f'Conflicting family adjustment: {family}')
        by_family[family] = entry
    avatars = copy.deepcopy(cfg['avatar'])
    skills = cfg['skill']
    consumers = defaultdict(list)
    changed = []
    for aid, row in avatars.items():
        panel_factor, skill_factor, mode = by_family.get(aid.rsplit('_',1)[0], (1,1,'unchanged'))
        if panel_factor != 1:
            if len(row.get('pl',[])) < 8:
                raise ValueError(f'Incomplete hero stats: {aid}')
            before = list(row['pl'][:8])
            row['pl'][:8] = [round(value*panel_factor,10) for value in before]
            changed.append({'aid':aid,'panel_factor':panel_factor,'skill_factor':skill_factor,
                            'timing_mode':mode,'before':before,'after':row['pl'][:8]})
        for slot in (10,11,13):
            if len(row.get('pl',[])) > slot and row['pl'][slot] in skills:
                consumers[row['pl'][slot]].append((aid,slot,skill_factor,mode))
    replacements = {}
    audit = []
    for sid, refs in consumers.items():
        demands = {(factor,mode) for aid,slot,factor,mode in refs}
        for factor,mode in sorted(demands):
            if factor == 1 and mode == 'unchanged':
                continue
            original = skills[sid]
            row, _, _ = _scale_captain_row(original, factor, scale_displacement=False)
            _timing(row,mode)
            target = sid if len(demands) == 1 else _private_skill_id(sid,factor,mode)
            if target != sid:
                # Shared generic skills may be private copies. Native ID-bound
                # mechanisms must remain on their verified IDs.
                if any(a[0] in ('manual_ability','summon','summon_turret','clone_normal') for a in original.get('skill',[])):
                    raise ValueError(f'Cannot split an ID-bound shared skill: {sid}')
                if target in skills or target in replacements:
                    raise ValueError(f'Private balance skill collision: {target}')
                row['id'] = target
                for aid,slot,consumer_factor,consumer_mode in refs:
                    if (consumer_factor,consumer_mode) == (factor,mode):
                        avatars[aid]['pl'][slot] = target
            replacements[target] = row
            audit.append({'source':sid,'target':target,'factor':factor,'mode':mode,
                          'before_timing':copy.deepcopy(original.get('pl',[])[:2]),
                          'after_timing':copy.deepcopy(row.get('pl',[])[:2])})
    cfg['avatar'] = avatars
    skills.update(replacements)
    marker = {'schema':SCHEMA,'plan_sha256':digest,'source_workbook_sha256':plan['source_sha256'],
              'avatar_changes':changed,'skill_changes':audit}
    cfg['hero_balance_103'] = marker
    return marker
