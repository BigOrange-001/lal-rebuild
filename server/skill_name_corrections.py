"""Correct skill titles that contradict their authored combat actions."""

from __future__ import annotations

import copy


# Include only rarity variants of the same five hero skills with identical
# action sequences. Preserve descriptions and mechanics.
SKILL_NAME_CORRECTIONS = {
    "S_621077_4": ("花岗岩护盾", "地震碎片", ("damage", "weak_percent", "strong")),
    "S_621077_5": ("花岗岩护盾", "地震碎片", ("damage", "weak_percent", "strong")),
    "S_621077_6": ("花岗岩护盾", "地震碎片", ("damage", "weak_percent", "strong")),
    "S_621128_5": ("欺诈魔盒", "欺诈突袭", ("move_enemy_side_target", "stat_flat", "damage")),
    "S_621128_6": ("欺诈魔盒", "欺诈突袭", ("move_enemy_side_target", "stat_flat", "damage")),
    "S_631128_5": ("惊吓魔盒", "幻象分身", ("summon", "move_self", "strong", "stat_flat")),
    "S_631128_6": ("惊吓魔盒", "幻象分身", ("summon", "move_self", "strong", "stat_flat")),
    "S_631113_4": ("暗裔横扫", "暗裔重生", ("strong", "steel", "cure", "bless")),
    "S_631113_5": ("暗裔横扫", "暗裔重生", ("strong", "steel", "cure", "bless")),
    "S_631113_6": ("暗裔横扫", "暗裔重生", ("strong", "steel", "cure", "bless")),
    "S_621124_5": ("沙漠之矛", "沙兵召唤", ("summon",)),
    "S_621124_6": ("沙漠之矛", "沙兵召唤", ("summon",)),
}


def apply_skill_name_corrections(document: dict) -> dict:
    """Return a copy with the five verified skill families renamed."""
    output = copy.deepcopy(document)
    skills = output.get("cfg", {}).get("skill")
    if not isinstance(skills, dict):
        raise ValueError("skill configuration is missing")
    for skill_id, (old_name, new_name, operators) in SKILL_NAME_CORRECTIONS.items():
        row = skills.get(skill_id)
        if not isinstance(row, dict) or row.get("name") not in (old_name, new_name):
            raise ValueError(f"unexpected skill title for {skill_id}")
        actions = row.get("skill")
        if (not isinstance(actions, list)
                or any(not isinstance(action, list) or not action for action in actions)
                or tuple(action[0] for action in actions) != operators):
            raise ValueError(f"unexpected skill actions for {skill_id}")
        row["name"] = new_name
    return output
