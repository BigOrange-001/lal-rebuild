"""Replace numeric status placeholders with existing battle animations.

Only visual descriptors are touched.  Damage numbers, buff mechanics and
skill actions remain controlled by their existing combat paths.
"""

from __future__ import annotations


STATUS_EFFECTS = {
    # A short red ember loop stays visible for the entire burn duration.
    # Its distinct art also avoids confusing burn with strong's e703 flames.
    "burn": {"id": "e068", "sc": 1, "t": 0, "loop": True},
    # Tick effects play once; neither is a numeric combatRate sprite.
    "BURN_EFF": {"id": "e067", "sc": 1, "t": 0.45},
    "POISON_EFF": {"id": "e707", "sc": 1, "t": 0.45},
    # A sparkle loop signals increased critical chance without showing "1".
    "critup": {"id": "e705", "sc": 1, "t": 0, "loop": True},
    # Skill and battle event cues: each name maps to art matching the action.
    "SUCK_EFF": {"id": "e305", "sc": 1, "t": 0.4},  # red life droplet
    "SUMMON_EFF": {"id": "e013", "sc": 1, "t": 0.5},  # portal circle
    "GANK": {"id": "e509", "sc": 1, "t": 0.35},  # target lock ring
    "DEAD_MODE_EFF": {"id": "e718", "sc": 1, "t": 0.55},  # dark sudden-death aura
    "TAUNT_HIT_EFF": {"id": "e716", "sc": 1, "t": 0.3},  # taunt ring
    "BACK_BUL": {"id": "e508", "sc": 1, "t": 0.35, "loop": True},  # red retaliation shot
    "BLESS_EFF": {"id": "e701", "sc": 1, "t": 0.45},  # revival wings
    "DEAD_MODE_START_EFF": {"id": "e718", "sc": 1, "t": 0.55},
    "ADD_AVATAR_EFF": {"id": "e013", "sc": 1, "t": 0.45},
    "RANDOM_AVATAR_EFF": {"id": "e024", "sc": 1, "t": 0.45},  # arrival beam
    "SIGN": {"id": "e011", "sc": 1, "t": 1},  # gold sign-in glint
    "OPENING_ANIMATION": {"id": "e202", "sc": 1, "t": 0.45, "loop": True},  # moving gold ray
    # Buff.displayObject asks for these names; pull/push are instant moves,
    # whereas passive and summon badges remain until the native buff expires.
    "summon": {"id": "e304", "sc": 1, "t": 0, "loop": True},
    "pull": {"id": "e518", "sc": 1, "t": 0},  # inward vortex
    "push": {"id": "e511", "sc": 1, "t": 0},  # outward wind streak
    "asuck": {"id": "e305", "sc": 1, "t": 0, "loop": True},
    "back": {"id": "e306", "sc": 1, "t": 0, "loop": True},
    "avenge": {"id": "e703", "sc": 1, "t": 0, "loop": True},
}


def apply_battle_status_effects(document: dict) -> dict:
    """Apply the four visual fixes in place and return *document*.

    Assigning fresh descriptor dictionaries makes reruns idempotent and avoids
    retaining references to shared template objects in the loaded config.
    """
    effects = document["cfg"]["effect"]
    for key, descriptor in STATUS_EFFECTS.items():
        effects[key] = dict(descriptor)
    return document
