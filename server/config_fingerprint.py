"""Compact semantic projection used only for configuration fingerprints.

Package and patch-target digests keep their existing canonical JSON contract.
Derived relic rows are expressed as source + differences here; the full source
row is still included, so changes to inherited fields also change the digest.
"""


def fingerprint_config(value):
    if not isinstance(value, dict):
        return value
    if isinstance(value.get('cfg'), dict):
        return {**value, 'cfg': fingerprint_config(value['cfg'])}
    key = 'skill' if isinstance(value.get('skill'), dict) else 'skills'
    skills = value.get(key)
    if not isinstance(skills, dict):
        return value
    compact = {}
    changed = False
    for sid, row in skills.items():
        source_id = row.get('relic_source_skill') if isinstance(row, dict) else None
        source = skills.get(source_id)
        if not isinstance(source, dict) or not row.get('abyss_relic_A'):
            compact[sid] = row
            continue
        overrides = {}
        for field, data in row.items():
            if field in source and data == source[field]:
                continue
            if (field == 'info' and isinstance(data, str)
                    and isinstance(source.get(field), str)
                    and data.startswith(source[field] + '\n')):
                data = {'append': data[len(source[field]):]}
            overrides[field] = data
        compact[sid] = {'$abyss_relic_source': source_id, 'overrides': overrides,
                        'removed': sorted(set(source) - set(row))}
        changed = True
    return {**value, key: compact} if changed else value
