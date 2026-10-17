"""Authored hero basic-attack channels and narrowly verified skill corrections.

`avatar.tl[2]` is the native basic-attack channel: 1 physical, 2 magic,
3 true.  A skill action carries its *own* channel; a champion's basic channel
must never be copied across all of that champion's skills.  Classifications
below describe the character's primary damage fantasy in this game.  Riot's
champion pages are the reference for ambiguous mixed-damage champions:
https://www.leagueoflegends.com/en-us/champions/teemo/
https://www.leagueoflegends.com/en-us/champions/kayle/
https://www.leagueoflegends.com/en-us/champions/shen/
https://www.leagueoflegends.com/en-us/champions/maokai/
"""
from __future__ import annotations

import hashlib
import json


PHYSICAL_BASE = frozenset("""
1001 1002 1005 1007 1008 1009 1011 1012 1017 1019 1021 1023 1024 1025
1026 1028 1030 1041 1053 1054 1056 1078 1083 1097 1099 1101 1108
1113 1115 1119 1123 1128 1130 1132 1135 1136 1142 1143
""".split())

MAGIC_BASE = frozenset("""
1003 1004 1006 1010 1013 1014 1015 1016 1018 1020 1022 1027 1029
1032 1033 1036 1040 1045 1049 1052 1060 1063 1068 1071 1073 1074
1077 1079 1081 1082 1085 1086 1090 1093 1094 1095 1096 1098 1103
1105 1106 1109 1112 1114 1117 1120 1124 1125 1126 1127 1131 1133
1134 1137 1138
""".split())

# The skin changes artwork and named abilities, not the champion's primary
# basic-attack channel.  A_1226 is the authored Erlang Xin Zhao from PR #11.
SKIN_BASE = {
    "1129": "1010", "1201": "1001", "1202": "1002", "1203": "1003",
    "1204": "1013", "1207": "1022", "1208": "1015",
    "1209": "1082", "1210": "1056", "1211": "1025", "1213": "1021",
    "1214": "1096", "1215": "1026", "1216": "1081", "1217": "1027",
    "1218": "1079", "1219": "1119", "1221": "1029", "1222": "1021",
    "1223": "1206", "1226": "1009", "1228": "1006", "1309": "1082",
    "1310": "1082",
}

# Vayne and Maokai have no ordinary hero family in this reconstruction.
# Vayne's basic attack remains physical; Silver Bolts is a separate true hit.
SPECIAL_FAMILIES = {"1205": 2, "1206": 1, "1212": 2}

# Streamer and event avatars have no Riot champion identity; retain their
# specifically authored channel instead of inventing a League counterpart.
CUSTOM_FAMILIES = frozenset("1900 1901 1902 1903 1904 1905 1909 1998".split())

# The Chinese ability text names magic damage and the positive-damage action
# is currently coded physical.  These seven entries are the only mismatches
# found in the referenced authored hero skills after upstream PR #11/#12.
EXPLICIT_MAGIC_SKILL_FIXES = {
    "S_201129_5": "combo", "S_201129_6": "combo",
    "S_301204_4": "silence", "S_301204_5": "silence",
    "S_301204_6": "silence",
    "S_201207_5": "suck", "S_201207_6": "suck",
}

_MARKER = "hero_damage_type_overlay"
_SCHEMA = "hero-damage-types-v1"

_SIMPLE_TYPED_DAMAGE = frozenset({
    "damage", "combo", "poison", "burn", "silence", "stun", "weak",
    "weak_percent", "sunder", "sunder_percent", "suck", "pull", "push",
})


def _positive_damage_action_type(action):
    """Read only native action positions whose coefficient carries damage."""
    opcode = action[0]
    if opcode == "true_damage":
        return 3
    if opcode in _SIMPLE_TYPED_DAMAGE:
        return int(action[2]) if float(action[1]) > 0 else None
    if opcode in ("conditional_damage", "dash_group_strike", "locked_combo_weak"):
        return int(action[2])
    if opcode in ("damage_chain", "pending_area_strike"):
        return int(action[3])
    if opcode in ("ricochet_bursts", "locked_combo_group"):
        return int(action[4])
    if opcode in ("locked_sequence", "locked_sequence_area"):
        return int(action[2 + int(action[1])])
    return None


def described_skill_type_mismatches(document):
    """Audit unambiguous physical/magic/true text against typed actions."""
    cfg = document.get("cfg", document)
    referenced = set()
    for aid, avatar in cfg["avatar"].items():
        if not aid.startswith("A_1") or not isinstance(avatar, dict):
            continue
        referenced.update(sid for sid in avatar.get("pl", [])[10:]
                          if isinstance(sid, str) and sid.startswith("S_"))
    mismatches = []
    for sid in sorted(referenced):
        skill = cfg["skill"].get(sid)
        if not isinstance(skill, dict):
            continue
        text = skill.get("info", "")
        categories = [(phrase, kind) for phrase, kind in
                      (("物理伤害", 1), ("魔法伤害", 2), ("真实伤害", 3))
                      if phrase in text]
        if len(categories) != 1:
            continue
        described = categories[0][1]
        for index, action in enumerate(skill.get("skill", [])):
            actual = _positive_damage_action_type(action)
            if actual in (1, 2, 3) and actual != described:
                mismatches.append((sid, index, action[0], described, actual))
    return mismatches


def expected_basic_damage_type(family):
    """Return the authored primary channel, or None for non-LoL event cards."""
    if family.startswith("A_"):
        family = family[2:]
    family = SKIN_BASE.get(family, family)
    if family in PHYSICAL_BASE:
        return 1
    if family in MAGIC_BASE:
        return 2
    if family in SPECIAL_FAMILIES:
        return SPECIAL_FAMILIES[family]
    if family in CUSTOM_FAMILIES:
        return None
    raise ValueError(f"Unclassified authored hero family A_{family}")


def apply_hero_damage_types(document):
    """Correct basic attacks, then only seven independently described skills."""
    cfg = document.get("cfg", document)
    mapping = {"physical": sorted(PHYSICAL_BASE), "magic": sorted(MAGIC_BASE),
               "skin_base": SKIN_BASE, "special": SPECIAL_FAMILIES,
               "skill_fixes": EXPLICIT_MAGIC_SKILL_FIXES}
    marker = {"schema": _SCHEMA, "basic_types": "1=physical,2=magic,3=true",
              "mapping_sha256": hashlib.sha256(json.dumps(mapping, sort_keys=True).encode()).hexdigest(),
              "corrected_skills": sorted(EXPLICIT_MAGIC_SKILL_FIXES)}
    if cfg.get(_MARKER) == marker:
        return document
    for aid, avatar in cfg["avatar"].items():
        parts = aid.split("_")
        if (len(parts) != 3 or parts[0] != "A" or len(parts[1]) != 4
                or not parts[1].startswith("1")):
            continue
        if not isinstance(avatar, dict) or not isinstance(avatar.get("tl"), list):
            continue
        if "阶英雄" in str(avatar.get("name", "")) or "序号" in str(avatar.get("name", "")):
            continue
        family = parts[1]
        damage_type = expected_basic_damage_type(family)
        if damage_type is not None:
            avatar["tl"][2] = damage_type
    for sid, opcode in EXPLICIT_MAGIC_SKILL_FIXES.items():
        skill = cfg["skill"][sid]
        if "魔法伤害" not in skill.get("info", ""):
            raise ValueError(f"Skill description changed: {sid}")
        actions = [action for action in skill["skill"]
                   if action[0] == opcode and float(action[1]) > 0]
        if len(actions) != 1 or actions[0][2] not in (1, 2):
            raise ValueError(f"Skill damage action changed: {sid}")
        actions[0][2] = 2
    cfg[_MARKER] = marker
    return document
