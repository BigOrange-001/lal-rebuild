"""Server-authoritative optional equipment roll for native P_001 victories."""
from __future__ import annotations

import random
import re

from gameplay_common import equipment_exclusive_ids
from player_store import GameplayFault

from ancient_trial_overlay import CHANCES_BP, EQUIPMENT_TYPES, QUALITIES, SCHEMA
from ancient_trial_103 import EXTENDED_CHANCES_BP,SCHEMA as EXTENDED_SCHEMA


_STAGE_ID = re.compile(r"P_001_(1[0-5]|[1-9])\Z")


def roll_ancient_trial_drop(config: dict, stage: dict, stage_id: str,
                            victory: bool, rng=None) -> str | None:
    """Roll one validated EID; caller appends it before atomic grant_reward.

    The caller must pass the stage copied into its pending battle intent, so a
    configuration refresh cannot change the odds after a fight has started.
    """
    match = _STAGE_ID.fullmatch(str(stage_id))
    if not victory or not match:
        return None
    tier = int(match.group(1))
    policy = stage.get("ancient_equip_drop") if isinstance(stage, dict) else None
    expected_schema=SCHEMA if tier<=10 else EXTENDED_SCHEMA
    if not isinstance(policy, dict) or stage.get("id") != stage_id or policy.get("schema") != expected_schema:
        raise GameplayFault("InvalidStage", "Ancient trial equipment policy is missing")
    quality=QUALITIES[tier-1] if tier<=10 else 6
    chance_bp=CHANCES_BP[tier-1] if tier<=10 else EXTENDED_CHANCES_BP[tier]
    from loot_rates_104 import SCHEMA as RATE_SCHEMA
    if stage.get('loot_rate_revision_104') == RATE_SCHEMA:
        chance_bp //= 2
    pool = policy.get("pool")
    if (type(policy.get("quality")) is not int or policy["quality"] != quality
            or type(policy.get("chance_bp")) is not int or policy["chance_bp"] != chance_bp
            or not isinstance(pool, list) or not pool
            or any(not isinstance(eid, str) for eid in pool)
            or len(pool) != len(set(pool))):
        raise GameplayFault("InvalidStage", "Ancient trial equipment tier is malformed")
    cfg = config.get("cfg", config) if isinstance(config, dict) else {}
    definitions = cfg.get("equip", {}) if isinstance(cfg, dict) else {}
    excluded = set(equipment_exclusive_ids(cfg))
    for eid in pool:
        row = definitions.get(eid) if isinstance(definitions, dict) else None
        if (not isinstance(eid, str) or not re.fullmatch(rf"E_\d+_{quality}", eid)
                or eid in excluded
                or not isinstance(row, dict) or row.get("quality") != quality
                or row.get("type") not in EQUIPMENT_TYPES):
            raise GameplayFault("InvalidStage", "Ancient trial equipment pool has a blocked item")
    source = rng if rng is not None else random.SystemRandom()
    if source.randrange(10000) >= chance_bp:
        return None
    return source.choice(pool)


def roll_ancient_exclusive_drop(config,stage,stage_id,victory,rng):
    """Tier 15 adds an independent exclusive roll, including current rate tuning."""
    if not victory or stage_id!='P_001_15':return None
    policy=stage.get('ancient_exclusive_drop')
    from loot_rates_104 import SCHEMA as RATE_SCHEMA
    chance_bp = 250 if stage.get('loot_rate_revision_104') == RATE_SCHEMA else 500
    if (stage.get('id')!=stage_id or not isinstance(policy,dict) or policy.get('schema')!=EXTENDED_SCHEMA
            or type(policy.get('chance_bp')) is not int or policy['chance_bp']!=chance_bp
            or type(policy.get('quality')) is not int or policy['quality']!=6):
        raise GameplayFault('InvalidStage','Ancient exclusive equipment policy is missing')
    cfg=config.get('cfg',config);pool=policy.get('pool');exclusive=set(equipment_exclusive_ids(cfg))
    if (not isinstance(pool,list) or not pool or any(not isinstance(eid,str) for eid in pool)
            or len(pool)!=len(set(pool))):
        raise GameplayFault('InvalidStage','Ancient exclusive equipment pool is malformed')
    for eid in pool:
        row=cfg['equip'].get(eid)
        if (eid not in exclusive or not isinstance(row,dict) or row.get('quality')!=6
                or row.get('type') not in EQUIPMENT_TYPES):
            raise GameplayFault('InvalidStage','Ancient exclusive equipment pool contains a non-exclusive item')
    return rng.choice(pool) if rng.randrange(10000)<chance_bp else None
