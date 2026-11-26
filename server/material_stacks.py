"""Material stacks: identical untouched material cards and spare skill books.

Storage keeps one instance per card or book, so every existing flow (feeding,
skill-book upgrades, selling, mail, drops) keeps working by instance id. Only
the warehouse view and capacity change: identical untouched copies share one
slot, up to STACK_LIMIT copies per slot. The client mirrors these rules in
GlobalData (stage 001); scripts/test_material_stacks_client.py keeps both in
step.
"""
from __future__ import annotations

STACK_LIMIT = 999

# Growth fields. A copy is untouched while each holds its fresh value; any
# other field (display flags the client adds, schema/version tags) is ignored
# so both sides agree on what one stack is.
_AVATAR_NUMBERS = {
    "lv": (0, 1), "slv": (0, 1), "exp": (0,), "hp": (0,), "ap": (0,), "de_ph": (0,), "de_ma": (0,),
    "phase": (0,), "morph": (0,), "love_exp": (0,), "limit_break": (0,), "pith_max": (0,), "inherit_count": (0,),
}
_AVATAR_BLANK = ("equips", "talent", "lock", "locked", "culture_legacy_raw", "culture_roll_raw", "worship_info")

_BOOK_NUMBERS = {"lv": (0, 1), "slv": (0, 1), "sexp": (0,), "haloLv": (0,), "haloExp": (0,),
                 "rune_lv": (0,), "magic_stage5": (0,), "inherit_count": (0,)}
_BOOK_ALL_ZERO = ("new_4attrs", "halo", "alchemy", "magic")
_BOOK_BLANK = ("lock", "locked")


def _blank(value):
    """False, zero, empty text or an empty container."""
    if value is None or value is False:
        return True
    if isinstance(value, bool):
        return False
    if isinstance(value, (int, float)):
        return value == 0
    if isinstance(value, (str, list, tuple, dict)):
        return len(value) == 0
    return False


def _number(value):
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        return None
    return value


def base_aid(instance_id, row=None):
    source = row.get("aid") if isinstance(row, dict) and isinstance(row.get("aid"), str) else instance_id
    return str(source).split("|")[0]


def is_material_aid(aid):
    """Non-hero cards: minions, monsters, towers and special units (EXP books, skill cookies)."""
    aid = str(aid)
    return aid.startswith("A_") and not aid.startswith("A_1")


def _numbers_fresh(row, fields):
    for key, allowed in fields.items():
        value = row.get(key)
        if value is None:
            continue
        number = _number(value)
        if number is None or number not in allowed:
            return False
    return True


def _all_zero(value):
    if isinstance(value, dict):
        return all(_blank(v) for v in value.values())
    if isinstance(value, (list, tuple)):
        return all(_blank(v) for v in value)
    return _blank(value)


def avatar_stack_key(instance_id, row):
    """The material id when this card is an untouched copy, otherwise ''."""
    if not isinstance(row, dict):
        return ""
    aid = base_aid(instance_id, row)
    if not is_material_aid(aid) or not _numbers_fresh(row, _AVATAR_NUMBERS):
        return ""
    if any(not _blank(row.get(key)) for key in _AVATAR_BLANK):
        return ""
    return aid


def equipped_ids(profile):
    used = set()
    for squad in profile.get("as_equips", []) if isinstance(profile, dict) else []:
        if isinstance(squad, (list, tuple)):
            used.update(str(item) for item in squad if item)
        elif isinstance(squad, dict):
            used.update(str(item) for item in squad.values() if item)
    for hero in (profile.get("avatars", {}) if isinstance(profile, dict) else {}).values():
        if isinstance(hero, dict) and isinstance(hero.get("equips"), list):
            used.update(str(item) for item in hero["equips"] if item)
    return used


def book_stack_key(instance_id, row, definitions, equipped=frozenset(), pending_wash=None):
    """eid|roll when this is a spare untouched skill book, otherwise ''."""
    if not isinstance(row, dict) or str(instance_id) in equipped or str(instance_id) == pending_wash:
        return ""
    eid = row.get("eid")
    definition = definitions.get(eid) if isinstance(definitions, dict) and isinstance(eid, str) else None
    if not isinstance(definition, dict) or int(definition.get("type", 0) or 0) != 6:
        return ""
    if not _numbers_fresh(row, _BOOK_NUMBERS):
        return ""
    if any(not _all_zero(row.get(key)) for key in _BOOK_ALL_ZERO):
        return ""
    if any(not _blank(row.get(key)) for key in _BOOK_BLANK):
        return ""
    roll = _number(row.get("stat_roll_ppm"))
    return "%s|%d" % (eid, int(roll) if roll is not None else 0)


def _slots(keys):
    counts = {}
    single = 0
    for key in keys:
        if key:
            counts[key] = counts.get(key, 0) + 1
        else:
            single += 1
    return single + sum((n + STACK_LIMIT - 1) // STACK_LIMIT for n in counts.values()), counts


def roster_slots(profile):
    avatars = profile.get("avatars", {}) if isinstance(profile, dict) else {}
    if not isinstance(avatars, dict):
        return 0
    return _slots(avatar_stack_key(iid, row) for iid, row in avatars.items())[0]


def roster_slots_after(profile, granted):
    """Slots used once `granted` [(aid, count)] new untouched cards are added."""
    avatars = profile.get("avatars", {}) if isinstance(profile, dict) else {}
    used, counts = _slots(avatar_stack_key(iid, row) for iid, row in avatars.items())
    for aid, count in granted:
        if count <= 0:
            continue
        if not is_material_aid(aid):
            used += count
            continue
        before = counts.get(aid, 0)
        after = before + count
        used += (after + STACK_LIMIT - 1) // STACK_LIMIT - (before + STACK_LIMIT - 1) // STACK_LIMIT
        counts[aid] = after
    return used


def _book_keys(profile, definitions):
    equipment = profile.get("my_equips", {}) if isinstance(profile, dict) else {}
    if not isinstance(equipment, dict):
        return []
    used = equipped_ids(profile)
    wash = profile.get("attrs", {}).get("equip_wash") if isinstance(profile.get("attrs"), dict) else None
    pending = str(wash.get("eqid")) if isinstance(wash, dict) and wash.get("eqid") else None
    return [book_stack_key(eqid, row, definitions, used, pending) for eqid, row in equipment.items()]


def equipment_slots(profile, definitions):
    return _slots(_book_keys(profile, definitions))[0]


def equipment_slots_after(profile, definitions, granted):
    """Slots used once `granted` [(eid, count)] new items are added; new books stack."""
    used, counts = _slots(_book_keys(profile, definitions))
    for eid, count in granted:
        if count <= 0:
            continue
        definition = definitions.get(eid) if isinstance(definitions, dict) else None
        if not isinstance(definition, dict) or int(definition.get("type", 0) or 0) != 6:
            used += count
            continue
        key = f"{eid}|1000000"
        before = counts.get(key, 0)
        after = before + count
        used += (after + STACK_LIMIT - 1) // STACK_LIMIT - (before + STACK_LIMIT - 1) // STACK_LIMIT
        counts[key] = after
    return used
