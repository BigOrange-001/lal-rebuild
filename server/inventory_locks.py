"""Durable inventory locks, including assets referenced by saved formations."""
from __future__ import annotations


def lock_preset_assets(profile, preset):
    teams = preset.get('team')
    teams = teams if isinstance(teams, list) else []
    equips = preset.get('as_equips')
    equips = equips if isinstance(equips, list) else []
    bindings = preset.get('dn_bindings')
    bindings = bindings if isinstance(bindings, dict) else {}
    hero_ids = {hid for row in teams if isinstance(row, list)
                for hid in row if isinstance(hid, str)}
    hero_ids.update(hid for hid in bindings.values() if isinstance(hid, str))
    equipment_ids = {eid for row in equips if isinstance(row, list)
                     for eid in row if isinstance(eid, str)}
    changed = False
    for field, keys in (('avatars', hero_ids), ('my_equips', equipment_ids)):
        for key in keys:
            row = profile.get(field, {}).get(key)
            if isinstance(row, dict) and row.get('lock') != 1:
                row['lock'] = 1
                changed = True
    return changed


def migrate_preset_locks(profile):
    attrs = profile.setdefault('attrs', {})
    if attrs.get('preset_auto_lock_version') == 1:
        return False
    presets = attrs.get('team_presets', [])
    if isinstance(presets, list):
        for preset in presets:
            if isinstance(preset, dict):
                lock_preset_assets(profile, preset)
    attrs['preset_auto_lock_version'] = 1
    return True


ACTIONS = {
    'sell': '出售', 'swallow': '当作吞噬材料', 'upgrade': '当作升阶材料',
    'book': '当作技能书材料', 'alchemy': '当作炼金材料',
}


def lock_users(profile, field, asset_id):
    """Names of saved team presets that reference this hero or equipment."""
    presets = profile.get('attrs', {}).get('team_presets')
    names = []
    for slot, preset in enumerate(presets if isinstance(presets, list) else [], 1):
        if not isinstance(preset, dict):
            continue
        if field == 'avatars':
            rows = list(preset.get('team') or []) + [list((preset.get('dn_bindings') or {}).values())]
        else:
            rows = list(preset.get('as_equips') or [])
        if any(isinstance(row, list) and asset_id in row for row in rows):
            names.append(str(preset.get('name') or f'阵容{slot}'))
    return names


def locked_fault(profile, field, asset_id, name, action):
    """A lock rejection that tells the player which item and why it is locked."""
    from player_store import GameplayFault
    kind = '英雄' if field == 'avatars' else '装备'
    users = lock_users(profile, field, asset_id)
    if users:
        reason = '被阵容预设「' + '」「'.join(users) + '」使用，已自动锁定'
    else:
        reason = '已手动锁定'
    verb = ACTIONS.get(action, '使用')
    message = f'{kind}「{name}」{reason}，不能{verb}。如确定要{verb}，请先在{kind}详情里点「解锁」。'
    fault = GameplayFault('HeroLocked' if field == 'avatars' else 'EquipmentLocked', message)
    fault.detail = True
    return fault
