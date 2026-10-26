"""Pure configured skill serialization, shared by runtime and authoring overlays."""
import copy
import math

def _native_skill_snapshot(config, skill_id, level=1):
    """Serialize a configured SkillSet the way Avatar.toDataObj() exposes it."""
    if not skill_id:
        return None
    row = config.get("skill", {}).get(str(skill_id))
    if not isinstance(row, dict):
        return None
    pl = row.get("pl", [])
    actions = copy.deepcopy(row.get("skill", []))
    skill_up = row.get("skillUp")
    if isinstance(skill_up, list) and skill_up and isinstance(skill_up[0], list) and int(level) > 1:
        upgrades = []
        valid = True
        for entry in skill_up:
            if (not isinstance(entry, list) or len(entry) != 3
                    or not isinstance(entry[0], (int, float))
                    or not isinstance(entry[1], (int, float))
                    or not isinstance(entry[2], (int, float))):
                valid = False
                break
            action_index, value_index, step = int(entry[0]), int(entry[1]), float(entry[2])
            if (action_index != entry[0] or value_index != entry[1] or not math.isfinite(step)
                    or action_index < 0 or action_index >= len(actions)
                    or not isinstance(actions[action_index], list)
                    or value_index < 0 or value_index >= len(actions[action_index])
                    or not isinstance(actions[action_index][value_index], (int, float))):
                valid = False
                break
            upgrades.append((action_index, value_index, step))
        if valid:
            for action_index, value_index, step in upgrades:
                actions[action_index][value_index] += step * (int(level) - 1)
    elif (isinstance(skill_up, list) and len(skill_up) >= 2 and int(level) > 1
            and isinstance(skill_up[0], (int, float))
            and isinstance(skill_up[1], (int, float))):
        action_index = int(skill_up[0])
        if (0 <= action_index < len(actions) and isinstance(actions[action_index], list)
                and len(actions[action_index]) > 1):
            actions[action_index][1] += float(skill_up[1]) * (int(level) - 1)
    for entry in row.get("skillUpPaths", []) or []:
        if not isinstance(entry, list) or len(entry) != 3 or not isinstance(entry[1], list) or not entry[1]:
            continue
        action_index, path, step = entry
        if type(action_index) is not int or not 0 <= action_index < len(actions) or not isinstance(step, (int, float)) or not math.isfinite(step):
            continue
        target = actions[action_index]
        valid = True
        for index in path[:-1]:
            if type(index) is not int or not isinstance(target, list) or not 0 <= index < len(target):
                valid = False
                break
            target = target[index]
        leaf = path[-1]
        if valid and isinstance(target, list) and type(leaf) is int and 0 <= leaf < len(target) and isinstance(target[leaf], (int, float)):
            target[leaf] += step * (max(1, min(10, int(level))) - 1)
    return {
        "modCondition": copy.deepcopy(row.get("modCondition")),
        "modEffectSequence": row.get("modEffectSequence",0),
        "cd": int(pl[0]) if isinstance(pl, list) and pl and pl[0] is not None else 0,
        "pl": copy.deepcopy(pl),
        "skid": str(skill_id),
        "skills": actions,
        "actionTargetPolicies": copy.deepcopy(row.get("actionTargetPolicies") or []),
        "actionTargetPolicyArgs": copy.deepcopy(row.get("actionTargetPolicyArgs") or []),
        "actionTargetMaxTargets": copy.deepcopy(row.get("actionTargetMaxTargets") or []),
        "actionTargetGroups": copy.deepcopy(row.get("actionTargetGroups") or []),
        "manualSummonPolicy": copy.deepcopy(row.get("manualSummonPolicy")),
        "manualClonePolicy": copy.deepcopy(row.get("manualClonePolicy")),
        "captainSummonMultiplier": row.get("captainSummonMultiplier", 1),
        "equipment_source_skill_104": row.get("equipment_source_skill_104"),
        "chainDot": copy.deepcopy(row.get("chainDot")),
    }
