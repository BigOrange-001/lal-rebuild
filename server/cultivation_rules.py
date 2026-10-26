"""Weighted purple/orange cultivation and one-time legacy value migration."""

from __future__ import annotations

import copy
import math

FIELDS = ("hp", "ap", "de_ph", "de_ma")
SCHEMA = "weighted-v2"
WEIGHTS = {"hp": 1, "ap": 12, "de_ph": 10, "de_ma": 10}
STAR_RULES = {
    "5": {"cap_base": 30000, "cap_per_phase": 5000, "roll_budget": 500},
    "6": {"cap_base": 60000, "cap_per_phase": 10000, "roll_budget": 500},
}


def apply_cultivation_config(document: dict) -> dict:
    """Return a detached config with the new rules; safe to apply repeatedly."""
    result = copy.deepcopy(document)
    cfg = result.get("cfg", result)
    culture = cfg.setdefault("system_simple", {}).setdefault("culture", {})
    culture["weighted"] = {
        "enabled": True,
        "schema": SCHEMA,
        "weights": copy.deepcopy(WEIGHTS),
        "stars": copy.deepcopy(STAR_RULES),
    }
    price = culture.setdefault("price", {})
    price.setdefault("coin", {})["1"] = 100
    price["coin"]["10"] = 1000
    price.setdefault("culture_book", {})["1"] = 1
    price["culture_book"]["10"] = 10
    return result


def star_of(hero: dict) -> str:
    aid = str(hero.get("aid", hero.get("id", ""))).split("|", 1)[0]
    return aid.rsplit("_", 1)[-1]


def active(simple: dict, hero: dict) -> bool:
    culture = simple.get("culture", {}) if isinstance(simple, dict) else {}
    weighted = culture.get("weighted", {}) if isinstance(culture, dict) else {}
    aid = str(hero.get("aid", hero.get("id", ""))).split("|", 1)[0]
    return (isinstance(weighted, dict) and weighted.get("enabled") is True
            and weighted.get("schema") == SCHEMA and aid.startswith("A_1")
            and star_of(hero) in STAR_RULES)


def rules(simple: dict, hero: dict) -> tuple[dict, dict]:
    weighted = simple["culture"]["weighted"]
    weights, row = weighted["weights"], weighted["stars"][star_of(hero)]
    if (not isinstance(weights, dict) or not isinstance(row, dict)
            or any(type(weights.get(key)) is not int or weights[key] <= 0 for key in FIELDS)
            or weights["hp"] != 1
            or any(type(row.get(key)) is not int or row[key] <= 0
                   for key in ("cap_base", "cap_per_phase", "roll_budget"))):
        raise ValueError("invalid weighted cultivation config")
    return weights, row


def values(hero: dict) -> dict:
    return {key: max(0, int(hero.get(key, 0) or 0)) for key in FIELDS}


def used(hero: dict, simple: dict) -> int:
    weights, _ = rules(simple, hero)
    return sum(weights[key] * value for key, value in values(hero).items())


def cap(hero: dict, simple: dict) -> int:
    _, row = rules(simple, hero)
    phase = min(3, max(0, int(hero.get("phase", 0) or 0)))
    return row["cap_base"] + phase * row["cap_per_phase"]


def legacy_rate(simple: dict) -> float:
    try:
        rate = float(simple.get("culture", {}).get("pith_growth_rate", 0.008))
    except (TypeError, ValueError):
        rate = 0.008
    return rate if math.isfinite(rate) and rate > 0 else 0.008


def legacy_to_actual(raw: dict, avatar_row: dict, simple: dict) -> dict:
    pl = avatar_row.get("pl", []) if isinstance(avatar_row, dict) else []
    if not isinstance(pl, list) or len(pl) < 8:
        raise ValueError("missing avatar growth slopes for cultivation migration")
    rate = legacy_rate(simple)
    result = {}
    for key, index in zip(FIELDS, (1, 3, 5, 7)):
        amount = max(0, int(raw.get(key, 0) or 0))
        slope = float(pl[index])
        if not math.isfinite(slope) or slope < 0:
            raise ValueError("invalid avatar growth slope")
        result[key] = int(amount * slope * rate)
    return result


def migrate_hero(hero: dict, avatar_row: dict, simple: dict) -> bool:
    """Keep exact old stat gain and the raw source values for audit/retry."""
    if not isinstance(avatar_row, dict) or avatar_row.get("modMissing"):
        return False
    if not active(simple, hero) or hero.get("culture_schema") == SCHEMA:
        return False
    raw = values(hero)
    converted = legacy_to_actual(raw, avatar_row, simple)
    hero["culture_legacy_raw"] = {"schema": "raw-v1",
                                  "aid": str(hero.get("aid", hero.get("id", ""))).split("|", 1)[0],
                                  "values": raw, "rate": legacy_rate(simple)}
    hero.update(converted)
    hero["culture_schema"] = SCHEMA
    return True


def normalize_profile(profile: dict, cfg: dict) -> bool:
    """Migrate 5/6-star heroes and any old pending roll exactly once."""
    simple = cfg.get("system_simple", {}) if isinstance(cfg, dict) else {}
    avatar_rows = cfg.get("avatar", {}) if isinstance(cfg, dict) else {}
    roster = profile.get("avatars", {}) if isinstance(profile, dict) else {}
    if not isinstance(roster, dict):
        return False
    changed = False
    for iid, hero in roster.items():
        if not isinstance(hero, dict):
            continue
        aid = str(hero.get("aid", iid)).split("|", 1)[0]
        metadata = cfg.get("mod_runtime", {}).get("heroes", {}).get(aid, {}) if isinstance(cfg, dict) else {}
        row = avatar_rows.get(aid)
        if (isinstance(row, dict) and row.get("modMissing")) or metadata.get("available") is False:
            continue
        if not active(simple, {"aid": aid}):
            continue
        hero.setdefault("aid", iid)
        row = avatar_rows.get(aid)
        if isinstance(row, dict):
            changed = migrate_hero(hero, row, simple) or changed
    attrs = profile.get("attrs", {}) if isinstance(profile, dict) else {}
    pending = attrs.get("avatar_culture") if isinstance(attrs, dict) else None
    if isinstance(pending, dict):
        iid = pending.get("aid", pending.get("eqid"))
        hero = roster.get(iid)
        if isinstance(hero, dict) and active(simple, hero):
            aid = str(hero.get("aid", iid)).split("|", 1)[0]
            row = avatar_rows.get(aid)
            metadata = cfg.get("mod_runtime", {}).get("heroes", {}).get(aid, {})
            if isinstance(row, dict) and not row.get("modMissing") and metadata.get("available") is not False:
                changed = migrate_pending(pending, hero, row, simple) or changed
    return changed


def migrate_pending(pending: dict, hero: dict, avatar_row: dict, simple: dict) -> bool:
    """Preserve the old pending roll's incremental gain across conversion."""
    if not active(simple, hero) or pending.get("schema") == SCHEMA:
        return False
    raw_roll = pending.get("rolled", pending.get("save_status", {}))
    if not isinstance(raw_roll, dict):
        return False
    raw_roll = values(raw_roll)
    backup = hero.get("culture_legacy_raw", {})
    old_raw = backup.get("values", {}) if isinstance(backup, dict) else {}
    if not isinstance(old_raw, dict):
        old_raw = {}
    before = legacy_to_actual(old_raw, avatar_row, simple)
    after = legacy_to_actual({key: int(old_raw.get(key, 0) or 0) + raw_roll[key]
                              for key in FIELDS}, avatar_row, simple)
    gain = {key: max(0, after[key] - before[key]) for key in FIELDS}
    pending["legacy_rolled_raw"] = raw_roll
    pending["rolled"] = gain
    pending["save_status"] = dict(gain)
    pending["schema"] = SCHEMA
    return True


def clamp_gain(hero: dict, gain: dict, simple: dict) -> dict:
    """Allocate actual stat increments into remaining weighted capacity."""
    weights, _ = rules(simple, hero)
    amount = values(gain)
    room = max(0, cap(hero, simple) - used(hero, simple))
    total = sum(amount[key] * weights[key] for key in FIELDS)
    if total <= room:
        return amount
    if room <= 0:
        return {key: 0 for key in FIELDS}
    result = {key: min(amount[key], amount[key] * room // total) for key in FIELDS}
    room -= sum(result[key] * weights[key] for key in FIELDS)
    for key in FIELDS:
        extra = min(amount[key] - result[key], room // weights[key])
        result[key] += extra
        room -= extra * weights[key]
    return result


def actual_material_gain(material: dict, avatar_row: dict, simple: dict) -> dict:
    if material.get("culture_schema") == SCHEMA and active(simple, material):
        return values(material)
    return legacy_to_actual(material, avatar_row, simple)


def weighted_feed(target: dict, materials: list[tuple[dict, dict]], simple: dict) -> dict:
    requested = {key: 0 for key in FIELDS}
    for material, avatar_row in materials:
        current = actual_material_gain(material, avatar_row, simple)
        for key in FIELDS:
            requested[key] += current[key]
    gain = clamp_gain(target, requested, simple)
    for key in FIELDS:
        target[key] = max(0, int(target.get(key, 0) or 0)) + gain[key]
    return gain


def actual_to_legacy_raw(gain: dict, avatar_row: dict, simple: dict) -> dict:
    """Conservatively translate a weighted material into old target points."""
    pl = avatar_row.get("pl", []) if isinstance(avatar_row, dict) else []
    if not isinstance(pl, list) or len(pl) < 8:
        raise ValueError("missing avatar growth slopes for legacy feed")
    rate = legacy_rate(simple)
    result = {}
    for key, index in zip(FIELDS, (1, 3, 5, 7)):
        slope = float(pl[index]) * rate
        result[key] = int(max(0, int(gain.get(key, 0) or 0)) / slope) if slope > 0 else 0
    return result


def allocate_budget(scores: dict, budget: int, weights: dict) -> dict:
    """Convert random stat proportions into an exact integer point budget.

    Stat values are stored as integers. HP costs one point, so it receives the
    indivisible remainder after proportional allocation to the four stats.
    """
    result = {key: 0 for key in FIELDS}
    if budget <= 0:
        return result
    total = sum(max(0.0, float(scores.get(key, 0))) for key in FIELDS)
    if total <= 0:
        raise ValueError("cultivation roll has no positive growth score")
    ideals = {key: budget * max(0.0, float(scores.get(key, 0))) / total / weights[key]
              for key in FIELDS}
    for key in FIELDS:
        result[key] = math.floor(ideals[key])
    remaining = budget - sum(result[key] * weights[key] for key in FIELDS)
    # Award feasible rounding points to the sampled stats first. Each award
    # lowers that stat's fractional deficit, so no stat can absorb the budget
    # merely because it appears first in FIELDS.
    while True:
        candidates = [key for key in FIELDS if scores.get(key, 0) > 0
                      and weights[key] <= remaining and ideals[key] - result[key] > 0]
        if not candidates:
            break
        key = max(candidates, key=lambda field: (ideals[field] - result[field], -FIELDS.index(field)))
        result[key] += 1
        remaining -= weights[key]
    result["hp"] += remaining
    return result


def roll(hero: dict, count: int, simple: dict, rng, avatar_row: dict) -> tuple[dict, dict]:
    """Spend 500 weighted points per attempt using native random-stat ratios."""
    raw_roll = {key: 0 for key in FIELDS}
    for _ in range(count):
        raw_roll[rng.choice(FIELDS)] += rng.randint(1, 3)
    weights, row = rules(simple, hero)
    pl = avatar_row.get("pl", []) if isinstance(avatar_row, dict) else []
    if not isinstance(pl, list) or len(pl) < 8:
        raise ValueError("missing avatar growth slopes for cultivation roll")
    scores = {}
    for key, index in zip(FIELDS, (1, 3, 5, 7)):
        slope = float(pl[index])
        if not math.isfinite(slope) or slope <= 0:
            raise ValueError("invalid avatar growth slope")
        scores[key] = raw_roll[key] * slope * legacy_rate(simple) * weights[key]
    remaining = max(0, cap(hero, simple) - used(hero, simple))
    budget = min(remaining, count * row["roll_budget"])
    return allocate_budget(scores, budget, weights), raw_roll
