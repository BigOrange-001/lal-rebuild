"""Wire original effectDB animations that sat in the assets but on no skill.

The base SWF's DragonBones library ("effectDB", armatures ``effect/eNNN``)
still holds art whose owner is unmistakable, while the rebuilt effect table
pointed those skills at shared placeholders.  This overlay adds one effect
descriptor per such skill and points only that skill's matching action at it.

Only presentation changes: coefficients, targets, buffs and order stay as they
were, and every descriptor keeps the old bullet speed (``sp`` 800), so hit
timing is unchanged.  Inventory and open questions:
docs/native-fx-wiring-106.md.
"""

from __future__ import annotations


NATIVE_FX = {
    # Lux, Final Spark (终极闪光): e602 is a white beam slice with gold rims and
    # e504 the round cap that ends it.  DisplayTools.addBullet path mode w=3
    # stretches the slice from Lux to each target while the cap leads it.
    "FX_A_1060_ULT": {
        "b": {"id": "e504", "sc": 0.7, "t": 0.55},
        "p": {"id": "e602", "w": 3, "sc": 0.7},
        "h": {"id": "e011", "sc": 1.2, "t": 0.55},
        "sp": 800,
    },
    # Ahri, Charm (魅惑灵弹): the pulsing red heart flies to the target and
    # bursts in pink.
    "FX_A_1022_CHARM": {
        "b": {"id": "e521", "sc": 1.0, "t": 0.55},
        "h": {"id": "e020", "sc": 1.0, "t": 0.55},
        "sp": 800,
    },
    # Twisted Fate, Pick a Card (万能牌): the flaming card is the thrown
    # projectile; the old blue burst stays as the impact.
    "FX_A_1096_CARD": {
        "b": {"id": "e519", "sc": 1.0, "t": 0.55},
        "h": {"id": "e008", "sc": 1.0, "t": 0.55},
        "sp": 800,
    },
}

# Names skills already use but the effect table never defined, so the action
# played no art.  Hit-only: no bullet means the travel wait keeps its default
# 800 speed, and the burn tick is the same art as BURN_EFF.
MISSING_FX = {
    # Equipment-bond burns (斥候余毒, 余烬封疗, 爆破余焰, 龙血余焰).
    "FX60_BURN": {"h": {"id": "e067", "sc": 1.0, "t": 0.45}},
}

# Each rule: skill name, action type, effect the action uses now, new effect,
# and whether only the first matching action changes.  The old effect names
# are hero-specific (FX_A_<hero>_...), so name + old effect identifies the
# skill and every copy of it (abyss tiers, skill books) without listing ids.
ACTION_RULES = (
    ("终极闪光", "damage", "FX_A_1060_MAGIC", "FX_A_1060_ULT", False),
    # 5-star Charm: the opening damage is the charm hit; the later damage
    # actions are the dash orbs and keep their look.
    ("魅惑灵弹", "damage", "FX_A_1022_MAGIC", "FX_A_1022_CHARM", True),
    ("万能牌", "damage", "FX_A_1096_MAGIC", "FX_A_1096_CARD", False),
)

# Client-coded six-star abilities pass action[3] as their effect name.
MANUAL_ABILITY_RULES = (
    ("six_ahri_c", "FX60_MAGIC", "FX_A_1022_CHARM"),
)


def _rewire_actions(actions, kind, old, new, first_only):
    changed = 0
    for action in actions:
        if (isinstance(action, list) and len(action) > 1 and action[0] == kind
                and action[-1] == old):
            action[-1] = new
            changed += 1
            if first_only:
                break
    return changed


def apply_native_fx_wiring(document: dict) -> dict:
    """Add the descriptors and repoint the matching actions in place.

    Idempotent: a rerun finds no action still using the old effect name.
    """
    cfg = document["cfg"]
    effects = cfg["effect"]
    for key, descriptor in (*NATIVE_FX.items(), *MISSING_FX.items()):
        effects[key] = {part: dict(value) if isinstance(value, dict) else value
                        for part, value in descriptor.items()}
    for skill in cfg.get("skill", {}).values():
        if not isinstance(skill, dict) or not isinstance(skill.get("skill"), list):
            continue
        actions = skill["skill"]
        for name, kind, old, new, first_only in ACTION_RULES:
            if skill.get("name") == name:
                if first_only and any(isinstance(a, list) and a and a[-1] == new for a in actions):
                    continue
                _rewire_actions(actions, kind, old, new, first_only)
        for ability, old, new in MANUAL_ABILITY_RULES:
            for action in actions:
                if (isinstance(action, list) and len(action) > 3 and action[0] == "manual_ability"
                        and action[1] == ability and action[3] == old):
                    action[3] = new
    return document
