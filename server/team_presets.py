"""Four account-owned roster snapshots; restore assignments without reverting growth."""
from __future__ import annotations

import copy
from inventory_locks import lock_preset_assets

LIMIT = 4
METHODS = {'user.team_preset_save', 'user.team_preset_load', 'user.team_preset_delete'}


def _slots(roster, profile):
    saved = profile.setdefault('attrs', {}).get('team_presets')
    if saved is None:
        return [None] * LIMIT
    if not isinstance(saved, list) or len(saved) != LIMIT:
        roster._fail('InvalidPreset', '已保存阵容数据异常，请恢复存档后重试。')
    return copy.deepcopy(saved)


def _validate_assignments(roster, profile, team, team_num, equips, dn):
    roster._mutate(profile, 'user.fix_team', {'team': team, 'team_num': team_num, 'dn': dn})
    roster._mutate(profile, 'user.equip_dress', {'data': equips})


def mutate(roster, profile, method, params):
    slot = params.get('slot')
    if type(slot) is not int or not 1 <= slot <= LIMIT:
        roster._fail('InvalidPresetSlot', '阵容槽位必须为1至4的整数。')
    saved = _slots(roster, profile)
    index = slot - 1
    if method == 'user.team_preset_delete':
        saved[index] = None
    elif method == 'user.team_preset_save':
        # Capture only the authenticated account's committed state. Submitted
        # team/equipment data is never accepted as a substitute for ownership.
        candidate = copy.deepcopy(profile)
        roster._team_response(candidate)
        dn = copy.deepcopy(roster._normalize_dn(candidate))
        team_num = int(candidate['attrs'].get('team_num', 0))
        _validate_assignments(roster, candidate, candidate['team'], team_num, candidate['as_equips'], dn)
        main = candidate['team'][0]
        if not any(main[:5]):
            roster._fail('EmptyPresetTeam', '请先在主队上阵英雄，再保存阵容。')
        preview = []
        for position, hero_id in enumerate(main[:5]):
            if hero_id is None:
                preview.append(None)
                continue
            _, hero = roster._hero(candidate, hero_id)
            aid = hero.get('aid', hero_id).split('|')[0]
            preview.append({'id': hero_id, 'aid': aid, 'leader': position == 0,
                            'name': roster.heroes.get(aid, {}).get('name', aid)})
        saved[index] = {
            'schema': 1, 'name': f'阵容{slot}',
            'team': copy.deepcopy(candidate['team']), 'team_num': team_num,
            'as_equips': copy.deepcopy(candidate['as_equips']),
            'dn_bindings': {key: node[1] for key, node in dn.items()},
            'preview': preview, 'saved_at': roster.store.clock.now(),
        }
        lock_preset_assets(profile, saved[index])
    elif method == 'user.team_preset_load':
        preset = saved[index]
        if not isinstance(preset, dict) or preset.get('schema') != 1:
            roster._fail('EmptyPreset', '该槽位还没有保存阵容。')
        team, equips, bindings = preset.get('team'), preset.get('as_equips'), preset.get('dn_bindings')
        if (not isinstance(team, list) or len(team) != 3
                or any(not isinstance(row, list) or len(row) != 6 for row in team)
                or not isinstance(equips, list) or len(equips) != 6
                or any(not isinstance(row, list) or len(row) != 6 for row in equips)
                or not isinstance(bindings, dict)):
            roster._fail('InvalidPreset', '该阵容数据异常，请重新保存。')
        heroes = [hid for row in team for hid in row if hid is not None]
        heroes += [hid for hid in bindings.values() if hid is not None]
        equipment = [eqid for row in equips for eqid in row if eqid is not None]
        if any(not isinstance(hid, str) or hid not in profile.get('avatars', {}) for hid in heroes):
            roster._fail('PresetMissingAssets', '该阵容有英雄已不在背包中，当前配队未改动，请重新保存阵容。')
        if any(not isinstance(eqid, str) or eqid not in profile.get('my_equips', {}) for eqid in equipment):
            roster._fail('PresetMissingAssets', '该阵容有装备已不在背包中，当前配队未改动，请重新保存阵容。')
        current_dn = roster._normalize_dn(profile)
        if any(key not in current_dn and hero_id is not None for key, hero_id in bindings.items()):
            roster._fail('InvalidPreset', '该阵容使用了当前未解锁的德诺阵节点，当前配队未改动。')
        # A preset stores hero bindings, never node levels, hero growth or
        # equipment attributes. Newly unlocked nodes become unassigned.
        dn = {key: [node[0], bindings.get(key)] for key, node in current_dn.items()}
        _validate_assignments(roster, profile, copy.deepcopy(team), preset.get('team_num', 0), copy.deepcopy(equips), dn)
        lock_preset_assets(profile, preset)
    else:
        roster._fail('NotImplemented', 'Unknown team preset operation')
    profile.setdefault('attrs', {})['team_presets'] = saved
    return {'team': profile['team'], 'as_equips': profile['as_equips'],
            'attrs': profile['attrs'], 'slot': slot}
