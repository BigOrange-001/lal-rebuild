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
