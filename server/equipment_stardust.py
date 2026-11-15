"""Stardust (星辉): equipment decomposition, stardust alchemy and affix inheritance.

Integer rules shared by the server handlers and the ActionScript client:

* Decomposing an item yields ``4 ** (star - 1) * (1 + phase)`` stardust, where
  ``star`` already includes alchemy stars and ``phase`` is the in-star step.
  One alchemy star consumes three same-star copies (x4 value), so an item's
  yield equals the base copies that alchemy consumed to build it.
* One stardust alchemy step costs five times the yield of the same-name,
  same-star copy that ordinary alchemy would consume (phase 0).
* Inheritance adds the material's two displayed template affixes into the
  target's separate ``inherit_4attrs`` record, at most three times per target.
"""
from __future__ import annotations

ATTRS = ("hit", "flee", "crit", "tough")
STARDUST_ALCHEMY_MULTIPLIER = 5
MAX_INHERIT_COUNT = 3
SKILL_BOOK_TYPE = 6


def _int(value) -> int:
    try:
        return max(0, int(value or 0))
    except (TypeError, ValueError, OverflowError):
        return 0


def equipment_type(eid) -> int:
    """Native Equip.getType: the digit after ``E_`` in the template id."""
    text = str(eid or "")
    return int(text[2]) if len(text) > 2 and text[2].isdigit() else 0


def is_skill_book(eid) -> bool:
    return equipment_type(eid) == SKILL_BOOK_TYPE


def stardust_for_star(star: int, phase: int = 0) -> int:
    star = max(1, int(star))
    phase = max(0, min(2, int(phase)))
    return 4 ** (star - 1) * (1 + phase)


def item_star_phase(item: dict) -> tuple[int, int]:
    base = int(str(item.get("eid", "")).rsplit("_", 1)[-1])
    alchemy = item.get("alchemy", [0, 0])
    phase = extra = 0
    if isinstance(alchemy, list) and len(alchemy) > 1:
        phase, extra = _int(alchemy[0]), _int(alchemy[1])
    return base + extra, phase


def decompose_yield(item: dict) -> int:
    if is_skill_book(item.get("eid")):
        return 0
    star, phase = item_star_phase(item)
    return stardust_for_star(star, phase)


def alchemy_cost(target: dict) -> int:
    """Stardust replacing the same-name, same-star (phase 0) copy."""
    star, _phase = item_star_phase(target)
    return STARDUST_ALCHEMY_MULTIPLIER * stardust_for_star(star, 0)


def balance(profile: dict) -> int:
    attrs = profile.get("attrs", {}) if isinstance(profile, dict) else {}
    return _int(attrs.get("stardust", 0)) if isinstance(attrs, dict) else 0


def set_balance(profile: dict, amount: int) -> int:
    if amount < 0:
        raise ValueError("stardust balance cannot be negative")
    profile.setdefault("attrs", {})["stardust"] = int(amount)
    return int(amount)


def inherited(item: dict) -> dict[str, int]:
    raw = item.get("inherit_4attrs") if isinstance(item, dict) else None
    raw = raw if isinstance(raw, dict) else {}
    return {key: _int(raw.get(key, 0)) for key in ATTRS}


def inherit_count(item: dict) -> int:
    return _int(item.get("inherit_count", 0)) if isinstance(item, dict) else 0


def merge_inheritance(target: dict, material_affixes: dict) -> dict[str, int]:
    """Add the material's displayed affixes; caller validates the count."""
    merged = inherited(target)
    for key in ATTRS:
        merged[key] += _int((material_affixes or {}).get(key, 0))
    target["inherit_4attrs"] = merged
    target["inherit_count"] = inherit_count(target) + 1
    return merged
