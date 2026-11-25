"""Wire original effectDB animations that sat in the assets but on no skill.

The base SWF's DragonBones library ("effectDB", armatures ``effect/eNNN``)
still holds art whose owner is unmistakable, while the rebuilt effect table
pointed those skills at shared placeholders.  This overlay adds one effect
descriptor per such skill and points only that skill's matching action at it.
Round one wired the certain owners (Lux, Ahri, Twisted Fate); round two
attributes the rest of the idle hero art by look and skill (DERIVED_FX).

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

# The rest of the idle hero art (round two, attributed by look and skill fit).
# Each new name starts as a copy of the effect it replaces, so bullet speed,
# timings and sound cues stay identical; only the listed parts swap their art.
# A part given as None is dropped (that action then plays no bullet: the travel
# wait falls back to the default 800, the same speed every replaced entry uses).
DERIVED_FX = {
    # Ashe, Enchanted Crystal Arrow: the long ice arrow ringed by a frost halo.
    "FX_A_1002_CRYSTAL": ("FX60_ARROW", {"b": {"id": "e520"}}),
    # Ezreal, Mystic Shot: a blue energy bolt with a starry spark on impact.
    "FX_A_1021_MYSTIC": ("FX_A_1021_PHYSICAL", {"b": {"id": "e505"}, "h": {"id": "e029"}}),
    # Kennen, Mark of the Storm: a crackling spark flies in and the yellow bolt
    # strikes the mark (e206 is drawn striking in from above, so it is a hit,
    # not a bullet).  Slicing Maelstrom keeps its falling lightning and now
    # bursts into cyan arcs on each target.
    "FX_A_1016_MARK": ("FX_A_1016_MAGIC", {"b": {"id": "e542"}, "h": {"id": "e206"}}),
    "FX_A_1016_STORM": ("FX_A_1016_MAGIC", {"h": {"id": "e009"}}),
    # Twitch, Spray and Pray: the poison lands as his green skull cloud.
    "FX_A_1099_VENOM": ("FX_S9140_POISON", {"h": {"id": "e510"}}),
    # Brand, Pyroclasm: a fire crescent bounces between the targets.
    "FX_A_1068_PYRO": ("FX_A_1068_MAGIC", {"b": {"id": "e516"}}),
    # Annie, Disintegrate: a small fireball instead of the generic pink orb,
    # bursting in her own scorched-ground blast.
    "FX_A_1029_FIREBALL": ("FX60_MAGIC", {"b": {"id": "e507"}, "h": {"id": "e023"}}),
    # Malphite, Seismic Shard: he hurls a burning boulder.
    "FX_A_1077_SHARD": ("FX_A_1077_MAGIC", {"b": {"id": "e514"}}),
    # Cassiopeia, Twin Fang: each of the two fangs strikes as the serpent head.
    "FX_A_1063_FANG": ("FX_A_1063_MAGIC", {"h": {"id": "e545", "sc": 0.7}}),
    # Nami, Tidal Wave: the water swirl flies, the tide vortex rises on the hit.
    "FX_A_1131_TIDE": ("FX_A_1131_MAGIC", {"h": {"id": "e070", "sc": 0.8}}),
    # Zilean, Chronoshift: golden clock hands wind back into a ring.
    "FX_A_1095_REWIND": ("FX_S9120_CURE", {"h": {"id": "e002", "sc": 0.5}}),
    # Riven, Blade of the Exile: the blue wind slash crescent.
    "FX_A_1056_WIND": ("FX_A_1056_PHYSICAL", {"b": {"id": "e503"}, "h": {"id": "e006"}}),
    # Talon, Rake: thrown blue blades.
    "FX_A_1023_BLADE": ("FX_A_1023_PHYSICAL", {"b": {"id": "e513"}}),
    # Kha'Zix, Taste Their Fear: purple void spikes tear out of the target.
    "FX_A_1097_FEAR": ("FX_A_1097_PHYSICAL", {"h": {"id": "e546"}}),
    # Caitlyn, Ace in the Hole: a long rifle tracer, then the lock-on reticle.
    "FX_A_1025_ACE": ("FX_A_1025_PHYSICAL", {"b": {"id": "e014"}, "h": {"id": "e543"}}),
    # Gangplank, Cannon Barrage: a shell drops onto a red target marker; the
    # flying slash it borrowed is dropped.  Lower stars use their own old name.
    "FX_A_1011_BARRAGE": ("FX60_SLASH", {"b": None, "h": {"id": "e005", "sc": 1.2}}),
    "FX_A_1011_BARRAGE_N": ("FX_A_1011_PHYSICAL", {"b": None, "h": {"id": "e005", "sc": 1.2}}),
}

# Played by client code rather than a skill action: Kayle's Divine Judgment
# guard had no visual at all.  Avatar.sixBatchExecute105 shows it on Kayle
# when the guard starts (the golden flash settling into a glass dome).
SELF_FX = {
    "FX_A_1120_GUARD": {"h": {"id": "e019", "sc": 0.75, "t": 0.55}},
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
    # Round two.  "manual_ability" rules match the action's effect slot [3].
    ("魔法水晶箭", "damage", "FX60_ARROW", "FX_A_1002_CRYSTAL", False),
    ("真-魔法水晶箭", "damage", "FX60_ARROW", "FX_A_1002_CRYSTAL", False),
    ("秘术射击", "damage", "FX_A_1021_PHYSICAL", "FX_A_1021_MYSTIC", False),
    ("雷电标记", "damage", "FX_A_1016_MAGIC", "FX_A_1016_MARK", False),
    ("雷霆领域", "damage", "FX_A_1016_MAGIC", "FX_A_1016_STORM", False),
    ("真-雷霆领域", "damage", "FX_A_1016_MAGIC", "FX_A_1016_STORM", False),
    ("毒雾扫射", "poison", "FX_S9140_POISON", "FX_A_1099_VENOM", False),
    ("烈焰风暴", "damage_chain", "FX_A_1068_MAGIC", "FX_A_1068_PYRO", False),
    ("灼热火球", "manual_dot", "FX60_MAGIC", "FX_A_1029_FIREBALL", False),
    ("地震碎片", "damage", "FX_A_1077_MAGIC", "FX_A_1077_SHARD", False),
    ("毒牙", "conditional_damage", "FX_A_1063_MAGIC", "FX_A_1063_FANG", False),
    ("怒涛之潮", "damage", "FX_A_1131_MAGIC", "FX_A_1131_TIDE", False),
    ("时光倒流", "cure", "FX_S9120_CURE", "FX_A_1095_REWIND", False),
    ("放逐之锋", "manual_ability", "FX_A_1056_PHYSICAL", "FX_A_1056_WIND", False),
    ("飞叶联动", "manual_ability", "FX_A_1023_PHYSICAL", "FX_A_1023_BLADE", False),
    ("飞叶联动", "damage", "FX_A_1023_PHYSICAL", "FX_A_1023_BLADE", False),
    ("品尝恐惧", "manual_ability", "FX_A_1097_PHYSICAL", "FX_A_1097_FEAR", False),
    ("让子弹飞", "manual_ability", "FX_A_1025_PHYSICAL", "FX_A_1025_ACE", False),
    ("真-加农炮幕", "manual_ability", "FX60_SLASH", "FX_A_1011_BARRAGE", False),
    ("加农炮幕", "manual_ability", "FX_A_1011_PHYSICAL", "FX_A_1011_BARRAGE_N", False),
)

# Client-coded six-star abilities pass action[3] as their effect name.
MANUAL_ABILITY_RULES = (
    ("six_ahri_c", "FX60_MAGIC", "FX_A_1022_CHARM"),
)


def _slot(action):
    """Index of the action's effect name: [3] for manual abilities, else last."""
    if action[0] == "manual_ability":
        return 3 if len(action) > 3 else None
    return len(action) - 1


def _rewire_actions(actions, kind, old, new, first_only):
    changed = 0
    for action in actions:
        if not (isinstance(action, list) and len(action) > 1 and action[0] == kind):
            continue
        slot = _slot(action)
        if slot is not None and action[slot] == old:
            action[slot] = new
            changed += 1
            if first_only:
                break
    return changed


def _derive(effects, base, parts):
    row = {part: dict(value) if isinstance(value, dict) else value
           for part, value in effects[base].items()}
    for part, change in parts.items():
        if change is None:
            row.pop(part, None)
        else:
            row[part] = {**row.get(part, {}), **change}
    return row


def apply_native_fx_wiring(document: dict) -> dict:
    """Add the descriptors and repoint the matching actions in place.

    Idempotent: a rerun finds no action still using the old effect name.
    """
    cfg = document["cfg"]
    effects = cfg["effect"]
    for key, descriptor in (*NATIVE_FX.items(), *MISSING_FX.items(), *SELF_FX.items()):
        effects[key] = {part: dict(value) if isinstance(value, dict) else value
                        for part, value in descriptor.items()}
    for key, (base, parts) in DERIVED_FX.items():
        effects[key] = _derive(effects, base, parts)
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
