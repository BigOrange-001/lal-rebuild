"""Apply the combat tempo rules once to a configuration document."""

import copy
import re
from collections import Counter

from skill_balance_overlay import _action_paths, _get, _set, _pct

SCHEMA = "skill-tempo-v1"
_TOKEN = re.compile(r"\{(?:rank|scale|flat):[^}]+\}")
_PERCENT = re.compile(r"(?<![\d.])([0-9]+(?:\.[0-9]+)?)%")
_MAGNITUDES = {
    "shield": (1,), "cure": (1,), "heal_ap": (1,),
    "strong": (1,), "steel": (1,), "hitup": (1,), "fleeup": (1,),
    "attrup": (1,), "summon_turret": (1,), "manual_ability": (2,),
    "stat_flat": (2,), "weak": (3,), "weak_percent": (3,),
}
_STRUCTURAL = {"dash", "move_self", "purify", "summon"}


def _upgrade(row, factors):
    entries = row.get("skillUp")
    if entries:
        if isinstance(entries[0], list):
            for entry in entries:
                factor = factors.get((int(entry[0]), int(entry[1])), 1)
                if factor != 1:
                    entry[2] = round(entry[2] * factor, 10)
        else:
            factor = factors.get((int(entries[0]), 1), 1)
            if factor != 1:
                entries[1] = round(entries[1] * factor, 10)
    for entry in row.get("skillUpPaths", []) or []:
        factor = factors.get((int(entry[0]), *map(int, entry[1])), 1)
        if factor != 1:
            entry[2] = round(entry[2] * factor, 10)


def _timing_text(text, prepare, cooldown):
    text = re.sub(r"准备(?:时间|回合)?\s*[:：]?\s*\d+", lambda m: re.sub(r"\d+$", str(prepare), m[0]), text)
    return re.sub(r"冷却(?:时间|回合)?\s*[:：]?\s*\d+", lambda m: re.sub(r"\d+$", str(cooldown), m[0]), text)


def apply_skill_tempo(document):
    cfg = document["cfg"]
    if cfg.get("skill_tempo", {}).get("schema") == SCHEMA:
        return cfg["skill_tempo"]
    if cfg.get("skill_tempo"):
        raise ValueError("Unknown skill tempo schema")
    changes = Counter()
    for row in cfg["skill"].values():
        original = copy.deepcopy(row)
        prepare, cooldown = original["pl"][:2]
        if type(prepare) is not int or type(cooldown) is not int or min(prepare, cooldown) < 0:
            raise ValueError(f"Invalid skill timing: {row['id']}")
        row["pl"][0] = prepare - 1 if prepare >= 2 else prepare
        row["pl"][1] = max(0, cooldown - 1) if cooldown <= 3 else 3
        changes[f"original_cooldown_{cooldown}"] += 1
        changes["prepare_shortened"] += prepare >= 2
        factor = 2 if cooldown == 0 else 1.2 if cooldown == 3 else 1
        paths = {}
        percentages = {}
        for i, action in enumerate(row.get("skill", [])):
            if factor == 1:
                continue
            damage, steal, defense = _action_paths(action)
            selected = list(damage)
            if cooldown == 3:
                selected += steal + defense
                selected += [(index,) for index in _MAGNITUDES.get(action[0], ())]
                if not selected and action[0] not in _STRUCTURAL:
                    raise ValueError(f"Unreviewed effect: {row['id']} {action[0]}")
            for path in set(selected):
                value = _get(action, path)
                _set(action, path, value * factor)
                paths[(i, *path)] = factor
                if value:
                    percentages[_pct(value)] = _pct(value * factor)
        if factor != 1 and row.get("chainDot"):
            old = row["chainDot"][1]
            row["chainDot"][1] = round(old * factor, 10)
            percentages[_pct(old)] = _pct(old * factor)
        _upgrade(row, paths)
        manual = any(a[0] == "manual_ability" for a in row.get("skill", []))
        if manual and cooldown == 3:
            # Existing manual scale tokens read action[2] at display time.
            percentages = {m[0]: _pct(float(m[1]) / 100 * factor)
                           for m in _PERCENT.finditer(original.get("info", ""))}
        for key in ("info", "rankInfoTemplate"):
            if not isinstance(row.get(key), str):
                continue
            pieces = _TOKEN.split(row[key])
            tokens = _TOKEN.findall(row[key])
            pieces = [_PERCENT.sub(lambda m: percentages.get(m[0], m[0]), piece) for piece in pieces]
            text = pieces[0] + "".join(token + part for token, part in zip(tokens, pieces[1:]))
            if manual and cooldown == 3 and row["skill"][0][1] == "yi_n":
                text = text.replace("600点闪避", "720点闪避")
            if cooldown == 3:
                for old_action, new_action in zip(original.get("skill", []), row.get("skill", [])):
                    if old_action[0] == "stat_flat":
                        label = {"hit": "精准", "crit": "暴击", "flee": "闪避", "tough": "韧性"}[old_action[1]]
                        text = text.replace(f"{old_action[2]:g}点{label}", f"{new_action[2]:g}点{label}")
                    if old_action[0] == "heal_ap":
                        text = text.replace(_pct(old_action[1] * .1) + "的生命", _pct(new_action[1] * .1) + "的生命")
                    if old_action[0] == "damage_chain" and "弹射倍率提高至" in text:
                        text = re.sub(r"弹射倍率提高至[0-9.]+%", "弹射倍率提高至" + _pct(new_action[2][1] + new_action[7]), text)
            if cooldown == 0 and any(a[0] == "conditional_damage" for a in row.get("skill", [])):
                action = next(a for a in row["skill"] if a[0] == "conditional_damage")
                text = re.sub(r"两段倍率均提高至[0-9.]+%", "两段倍率均提高至" + _pct(action[1] + action[4]), text)
            row[key] = _timing_text(text, row["pl"][0], row["pl"][1])
        if cooldown == 3 and row.get("summonCombatPolicy"):
            policy = row["summonCombatPolicy"]
            if "owner_ap_ratio" in policy:
                policy["owner_ap_ratio"] = round(policy["owner_ap_ratio"] * factor, 10)
    result = {"schema": SCHEMA, "skill_rows": len(cfg["skill"]), **dict(changes)}
    cfg["skill_tempo"] = result
    return result
