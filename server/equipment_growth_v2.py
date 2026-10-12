"""Equipment growth and affix calculations used by roster and rewards."""
from __future__ import annotations

from decimal import Decimal, ROUND_HALF_UP
import hashlib

AFFIX_PAIRS = (
    ("hit", "crit"), ("hit", "flee"), ("hit", "tough"),
    ("crit", "flee"), ("crit", "tough"), ("flee", "tough"),
)
ATTRS = ("hit", "tough", "crit", "flee")
MIGRATION_VERSION = 1


def growth(level: int) -> float:
    if not 1 <= int(level) <= 200:
        raise ValueError("equipment level must be in [1, 200]")
    lv = int(level)
    if lv <= 125:
        return 1.0 + 9.0 * (lv - 1) / 124.0
    return 10.0 + 0.2 * (lv - 125)


def growth_ppm_table() -> list[int]:
    """Shared discrete config table, rounded half-up at 1 ppm resolution."""
    table = []
    for level in range(1, 201):
        lv = level
        if lv <= 125:
            numerator = 124_000_000 + 9_000_000 * (lv - 1)
            table.append((numerator + 62) // 124)
        else:
            table.append(10_000_000 + 200_000 * (lv - 125))
    return table


def to_int(value: float) -> int:
    """Native Tools.toInt: 5-decimal half-up, then integer truncation."""
    rounded = Decimal(str(value)).quantize(Decimal("0.00001"), rounding=ROUND_HALF_UP)
    return int(rounded)


def active_pair(equipment_id: str) -> tuple[str, str]:
    index = int(hashlib.sha256(equipment_id.encode("ascii")).hexdigest()[:8], 16) % len(AFFIX_PAIRS)
    return AFFIX_PAIRS[index]


def sample_stat_roll_ppm(rng) -> int:
    """Draw once when an item instance is created, then persist the integer."""
    return int(rng.randint(850_000, 1_150_000))


def roll_for_new_item(rng, exclusive: bool) -> int:
    return 1_200_000 if exclusive else sample_stat_roll_ppm(rng)


def effective_cap(account_level: int, vip_equip_bonus: int) -> int:
    return max(1, min(200, int(account_level) + max(0, int(vip_equip_bonus))))


def vip_crit_probabilities(vip_level: int) -> dict[int, float]:
    t = max(0, min(15, int(vip_level))) / 15.0
    return {2: 0.08 * t, 3: 0.03 * t, 5: 0.01 * t, 10: 0.002 * t}


def upgrade_result(old_level: int, cap: int, vip_level: int, rng) -> int:
    """One successful paid attempt; return final level after cap clamp."""
    if old_level >= cap:
        raise ValueError("at cap")
    draw = float(rng.random())
    cumulative = 0.0
    bonus = 1
    for final_step, probability in vip_crit_probabilities(vip_level).items():
        cumulative += probability
        if draw < cumulative:
            bonus = final_step
            break
    return min(int(cap), int(old_level) + bonus)


def legacy_pair_values(old_values: dict, pair: tuple[str, str]) -> dict[str, int]:
    """Keep all invested raw points; deterministic split onto native attrs."""
    values = {}
    for key in ATTRS:
        try:
            values[key] = max(0, int((old_values or {}).get(key, 0) or 0))
        except (TypeError, ValueError, OverflowError):
            values[key] = 0
    total = sum(values.values())
    left = total // 2
    right = total - left
    migrated = {key: 0 for key in ATTRS}
    migrated[pair[0]] = left
    migrated[pair[1]] = right
    return migrated


def _nonnegative_int(value) -> int:
    try:
        return max(0, int(value or 0))
    except (TypeError, ValueError, OverflowError):
        return 0


def migrate_item_wash(item: dict, pair: tuple[str, str]) -> bool:
    """Migrate an item's committed wash points exactly once; return if changed."""
    marker = item.get("wash_schema_version", 0)
    try:
        if int(marker) >= MIGRATION_VERSION:
            return False
    except (TypeError, ValueError):
        pass
    original = item.get("new_4attrs") if isinstance(item.get("new_4attrs"), dict) else item
    item["legacy_new_4attrs_v0"] = {key: _nonnegative_int(original.get(key, 0)) for key in ATTRS}
    item["new_4attrs"] = legacy_pair_values(original, pair)
    item["wash_schema_version"] = MIGRATION_VERSION
    for key in ATTRS:
        item.pop(key, None)
    return True


def migrate_pending_save(item: dict, pending: dict, pair: tuple[str, str]) -> dict[str, int]:
    """Save old-format pending roll then migrate the combined committed total."""
    base = item.get("new_4attrs") if isinstance(item.get("new_4attrs"), dict) else item
    combined = {key: _nonnegative_int((base or {}).get(key, 0)) for key in ATTRS}
    rolled = pending.get("rolled", {}) if isinstance(pending, dict) else {}
    for key in ATTRS:
        try:
            combined[key] += _nonnegative_int(rolled.get(key, 0))
        except (TypeError, ValueError, OverflowError):
            continue
    item["legacy_new_4attrs_v0"] = dict(combined)
    migrated = legacy_pair_values(combined, pair)
    item["new_4attrs"] = migrated
    item["wash_schema_version"] = MIGRATION_VERSION
    for key in ATTRS:
        item.pop(key, None)
    return migrated


def wash_roll(old: dict[str, int], pair: tuple[str, str], cap: int, num: int, rng, *, star: int = 1, level: int = 1) -> dict[str, int]:
    """Candidate roll only fills the two native-declared attrs, capped in aggregate."""
    remaining = max(0, int(cap) - sum(max(0, int(old.get(k, 0))) for k in ATTRS))
    budget = min(remaining, max(1, int(num)) * max(1, int(star)) * max(5, int(level) // 10))
    rolled = {key: 0 for key in ATTRS}
    if budget <= 0:
        return rolled
    first = int(rng.randint(0, budget))
    rolled[pair[0]] = first
    rolled[pair[1]] = budget - first
    return rolled


def declared_wash_contribution(item: dict, definition: dict, point_per_star_level: int = 1) -> dict[str, int]:
    """Only the two attrs declared in template pl[6]/pl[7] enter native snapshot."""
    pl = definition.get("pl", []) if isinstance(definition, dict) else []
    pair = tuple(key for key in pl[6:8] if key in ATTRS) if len(pl) >= 8 else ()
    raw = item.get("new_4attrs", {}) if isinstance(item.get("new_4attrs"), dict) else item
    try:
        migrated = int(item.get("wash_schema_version", 0)) < MIGRATION_VERSION
    except (TypeError, ValueError):
        migrated = True
    if migrated:
        raw = legacy_pair_values(raw, pair) if len(pair) == 2 else {key: 0 for key in ATTRS}
    level = max(1, int(item.get("lv", 1)))
    star = max(1, int(str(item.get("eid", "E_1_1")).rsplit("_", 1)[-1]))
    base = max(0, int(point_per_star_level)) * star * level
    return {key: (max(0, int(raw.get(key, 0) or 0)) + base if key in pair else 0) for key in ATTRS}


def stat_roll_rate(item: dict) -> float:
    value = item.get("stat_roll_ppm", 1_000_000)
    try:
        ppm = int(value)
    except (TypeError, ValueError, OverflowError):
        ppm = 1_000_000
    return max(850_000, min(1_200_000, ppm)) / 1_000_000.0


def level_growth_from_simple(simple: dict, level: int) -> float:
    """Read the same ppm curve shipped to the client; old configs keep native fallback."""
    lv = max(1, min(200, int(level)))
    table = simple.get("equip_growth_curve_ppm") if isinstance(simple, dict) else None
    if isinstance(table, list) and len(table) >= 200:
        ppm = int(table[lv - 1])
        if ppm <= 0:
            raise ValueError("invalid equipment growth ppm")
        return ppm / 1_000_000.0
    old = simple.get("equip_config", []) if isinstance(simple, dict) else []
    return 1.0 + float(old[1] if isinstance(old, list) and len(old) > 1 else 0) * (lv - 1)


def main_stat(base: float, level: int, simple: dict, item: dict,
              halo_rate: float = 1.0, alchemy_rate: float = 1.0) -> int:
    """Native Tools.toInt( base * growth * halo * alchemy * persisted roll )."""
    value = float(base) * level_growth_from_simple(simple, level) * stat_roll_rate(item)
    value *= float(halo_rate) * float(alchemy_rate)
    return to_int(value)


def wash_stats(item: dict, definition: dict, simple: dict) -> dict[str, int]:
    """Mirror native Equip.getX(-1,true): only pl[6:8] contributes, with getPoint."""
    pl = definition.get("pl", []) if isinstance(definition, dict) else []
    pair = tuple(key for key in pl[6:8] if key in ATTRS) if len(pl) >= 8 else ()
    result = {key: 0 for key in ATTRS}
    if len(pair) != 2 or pair[0] == pair[1]:
        return result
    raw = item.get("new_4attrs") if isinstance(item.get("new_4attrs"), dict) else item
    try:
        star = max(1, int(str(item.get("eid", "E_1_1")).rsplit("_", 1)[-1]))
        alchemy = item.get("alchemy", [0, 0])
        if isinstance(alchemy, list) and len(alchemy) > 1:
            star += max(0, int(alchemy[1]))
        level = max(1, int(item.get("lv", 1)))
        cfg = simple.get("equip_config", []) if isinstance(simple, dict) else []
        point = int(cfg[2]) if isinstance(cfg, list) and len(cfg) > 2 else 0
    except (TypeError, ValueError, OverflowError, IndexError):
        return result
    for attr in pair:
        try:
            invested = _nonnegative_int(raw.get(attr, 0))
        except (TypeError, ValueError, OverflowError):
            invested = 0
        result[attr] = invested + point * star * level
    return result
