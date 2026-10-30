"""Validate and roll hard-mainline equipment drops.

The feature is inert until the configuration explicitly supplies
``system_simple.elite_equipment_drop``.  This module intentionally contains no
fallback pool: a missing or malformed policy must never invent item IDs.
"""
from __future__ import annotations

import random
import re

from player_store import GameplayFault
from gameplay_common import equipment_exclusive_ids


ALLOWED_EQUIPMENT_TYPES = {1, 3, 4, 5}
_MAIN_STAGE = re.compile(r"M_(\d{3})_(\d+)")


def policy_from_config(config: dict) -> dict | None:
    cfg = config.get("cfg", config) if isinstance(config, dict) else {}
    simple = cfg.get("system_simple", {}) if isinstance(cfg, dict) else {}
    policy = simple.get("elite_equipment_drop") if isinstance(simple, dict) else None
    if policy is None:
        return None
    if not isinstance(policy, dict) or policy.get("schema") != "elite-equipment-drop-policy-v1" or policy.get("enabled") is not True:
        raise GameplayFault("InvalidEquipmentDropPolicy", "Elite equipment drop policy is malformed")
    tiers = policy.get("tiers")
    pools = policy.get("pools_by_quality")
    if not isinstance(tiers, list) or not isinstance(pools, dict):
        raise GameplayFault("InvalidEquipmentDropPolicy", "Elite equipment drop tiers and pools are required")
    return policy


def roll_elite_drop(config: dict, stage_id: str, difficulty: int, victory: bool, rng=None) -> str | None:
    """Return one validated equipment EID or None; does not mutate profile/reward."""
    if difficulty != 1 or not victory:
        return None
    match = _MAIN_STAGE.fullmatch(str(stage_id))
    if not match:
        return None
    chapter = int(match.group(1))
    if chapter < 1 or chapter > 30:
        return None
    policy = policy_from_config(config)
    if policy is None:
        return None
    selected = [row for row in policy["tiers"]
                if isinstance(row, dict)
                and type(row.get("chapter_min")) is int
                and type(row.get("chapter_max")) is int
                and row["chapter_min"] <= chapter <= row["chapter_max"]]
    if len(selected) != 1:
        raise GameplayFault("InvalidEquipmentDropPolicy", "Each campaign chapter must map to exactly one equipment tier")
    tier = selected[0]
    quality = tier.get("quality")
    from loot_rates_104 import elite_chance
    chance = elite_chance(tier)
    if type(quality) is not int or not 2 <= quality <= 6:
        raise GameplayFault("InvalidEquipmentDropPolicy", "Elite equipment drop tier values are invalid")
    pool = policy["pools_by_quality"].get(str(quality))
    if not isinstance(pool, list) or not pool:
        raise GameplayFault("InvalidEquipmentDropPolicy", "Elite equipment tier pool is empty")
    cfg = config.get("cfg", config) if isinstance(config, dict) else {}
    definitions = cfg.get("equip", {}) if isinstance(cfg, dict) else {}
    pool_rules = policy.get("pool_rules", {})
    blocked_values = policy.get("excluded_item_ids", pool_rules.get("excluded_item_ids", []) if isinstance(pool_rules, dict) else [])
    if not isinstance(blocked_values, list) or any(not isinstance(eid, str) for eid in blocked_values):
        raise GameplayFault("InvalidEquipmentDropPolicy", "Elite equipment exclusions are malformed")
    blocked = set(blocked_values) | set(equipment_exclusive_ids(cfg))
    for eid in pool:
        definition = definitions.get(eid) if isinstance(definitions, dict) else None
        match_id = re.fullmatch(r"E_\d+_(\d+)", str(eid))
        if (not isinstance(definition, dict) or not match_id
                or int(match_id.group(1)) != quality
                or definition.get("quality") != quality
                or type(definition.get("type")) is not int
                or definition["type"] not in ALLOWED_EQUIPMENT_TYPES
                or eid in blocked):
            raise GameplayFault("InvalidEquipmentDropPolicy", "Elite equipment pool contains an invalid or blocked item")
    source = rng if rng is not None else random.SystemRandom()
    scale = tier.get("chance_bp_fraction", [0, 1])[1]
    if source.randrange(10000 * scale) >= int(chance * 10000 * scale):
        return None
    return source.choice(pool)
