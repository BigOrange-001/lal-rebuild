"""Increase captain skill magnitudes in a loaded full-config document.

The transform is deliberately limited to skill rows referenced by avatar
``pl[11]``.  It runs after the other skill overlays and never writes a config
file.  Unknown action operators fail before any document mutation.
"""

from __future__ import annotations

import copy
import hashlib
import re
from collections import Counter, defaultdict

from skill_balance_overlay import (
    _MANUAL_DAMAGE_PERCENT_INDICES,
    _action_paths,
    _get,
    _number,
    _pct,
    _set,
)


SCHEMA = "captain-strength-v1"
FACTOR = 1.5
_PERCENT = re.compile(r"(?<![\d.])([0-9]+(?:\.[0-9]+)?)%")
_TOKEN = re.compile(r"\{(?:rank|scale|flat):[^}]+\}")
_SCALE_TOKEN = re.compile(r"\{scale:([0-9.]+):([0-9.]+)\}")

# Only magnitudes belong here.  Action counts, geometry, durations, target
# limits, status flags and summon level ratios deliberately do not.
_EXTRA_PATHS = {
    "armor": ((1,),), "attrup": ((1,),), "back": ((1,),),
    "caster_hp_shield": ((1,),), "caster_hp_heal": ((1,),), "cure": ((1,),), "heal_ap": ((1,),),
    "dash_group_strike": ((3,),), "heal_missing_hp": ((1,),),
    "hp_shield": ((1,),), "kill_buff": ((2,),),
    "lethal_floor": ((3,),), "manual_dot": ((3,),),
    "push": ((1,),), "shield": ((1,),),
    "shield_composite": ((1,), (2,)), "stat_flat": ((2,),),
    "strong": ((1,),), "stun_by_condition": ((1,),),
    "sunder": ((3,),), "sunder_percent": ((3,),),
    "target_hp_shield": ((1,),), "timed_stack": ((2,),),
    "weak": ((3,),), "weak_percent": ((3,),),
    "summon_turret": ((1,),),
    "caster_ap_shield": ((1,),), "hitup": ((1,),), "fleeup": ((1,),),
    "shield_followup": ((1,),), "heal_missing_hp_per_hero": ((1,), (2,)),
    "battle_stack": ((2,),), "battle_stack_unconditional": ((2,),),
}
_STRUCTURAL = {
    "bless", "clone_normal", "dash", "dispel_good", "evil", "heal_damage_sum", "manual_ability",
    "move_self", "move_to_ally", "move_to_target_lane",
    "normal_on_hero_kill", "purify", "push_aoe", "recast_on_kill",
    "select_target", "shield_dispel", "summon", "taunt", "curse", "timed_bless",
    "pull", "pull_group", "move_to_target", "move_enemy_side_target", "focus_fire",
}
# Base paths cover the existing damage and DOT operator families.  The
# supplemental list above covers their independent healing/buff magnitudes.
_BASE_OPERATORS = {
    "burn", "combo", "conditional_damage", "damage", "damage_chain",
    "locked_combo_group", "locked_sequence", "locked_sequence_area",
    "pending_area_strike", "poison", "ricochet_bursts", "silence",
    "steel", "stun", "suck", "true_damage",
}
_REVIEWED = set(_EXTRA_PATHS) | _STRUCTURAL | _BASE_OPERATORS

# Indexes of non-damage effect percentages in the hand-authored manual skill
# descriptions.  Damage indexes come from the existing audited balance map.
# These include healing, shields, buffs, debuffs, summon inheritance and caps.
# Derived damage-to-heal/storage ratios and conditional thresholds are listed
# separately because the source damage is already scaled.
_MANUAL_EFFECT_PERCENT_INDICES = {
    "alistar_c": (0, 1, 2), "diana_c": (2, 3),
    "elise_c": (3,), "gangplank_c": (1,), "gangplank_n": (2, 3),
    "illaoi_c": (2, 3), "illaoi_n": (1, 2), "jayce_n": (3, 4),
    "jinx_c": (4,), "kayle_n": (1, 2, 3), "malzahar_c": (1,),
    "maokai_c": (1,), "maokai_n": (1, 2), "nidalee_c": (0, 1),
    "nunu_c": (0, 1, 3), "nunu_n": (2, 3),
    "orianna_c": (1, 2), "orianna_n": (0, 1),
    "riven_c": (0,), "riven_n": (3, 4), "tahm_c": (0, 1, 2),
    "tahm_n": (1, 2), "veigar_n": (1,), "wukong_c": (1,),
    "wukong_n": (1, 2), "yi_c": (0,),
}
_MANUAL_PRESERVED_PERCENT_INDICES = {
    "gangplank_n": (1,),  # HP condition for drinking the orange
    "kaelthas_c": (2,),  # explicitly suppressed original explosion
}
_MANUAL_DAMAGE_EXCLUDED = {"kaelthas_c": (2,)}
_MANUAL_FLAT_STAT_LABELS = {
    "caitlyn_c": "精准", "jinx_c": "暴击", "khazix_c": "闪避",
    "yi_c": "精准", "yi_n": "闪避",
}
_FLAT_STAT = re.compile(r"(?<![\d.])([0-9]+(?:\.[0-9]+)?)点(精准|暴击|闪避|韧性)")


def _captain_id(original: str, skills: dict) -> str:
    """Make a stable private ID when an ordinary and captain slot share one."""
    star = original.rsplit("_", 1)[-1]
    seed = hashlib.sha256(("captain-strength:" + original).encode()).hexdigest()
    candidate = f"S_8{int(seed[:12], 16)}_{star}"
    if candidate in skills:
        raise ValueError(f"captain private skill ID collision: {candidate}")
    return candidate


def _numeric(value, sid: str, action_index: int, path: tuple[int, ...]) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)):
        raise ValueError(f"non-numeric captain coefficient: {sid} {action_index} {path}")
    return value


def _update_growth(row: dict, scaled: set[tuple[int, ...]], factor: float = FACTOR) -> None:
    upgrades = row.get("skillUp")
    if isinstance(upgrades, list) and upgrades:
        if isinstance(upgrades[0], list):
            for entry in upgrades:
                if isinstance(entry, list) and len(entry) >= 3 and (int(entry[0]), int(entry[1])) in scaled:
                    entry[2] = _number(entry[2] * factor)
        elif len(upgrades) >= 2 and (int(upgrades[0]), 1) in scaled:
            upgrades[1] = _number(upgrades[1] * factor)
    for entry in row.get("skillUpPaths", []) or []:
        if isinstance(entry, list) and len(entry) >= 3 and isinstance(entry[1], list):
            if (int(entry[0]), *map(int, entry[1])) in scaled:
                entry[2] = _number(entry[2] * factor)


def _update_text(row: dict, changes: dict[str, set[str]], unchanged: set[str]) -> None:
    """Rewrite only unambiguous authored percentages outside dynamic tokens."""
    for key in ("info", "rankInfoTemplate"):
        value = row.get(key)
        if not isinstance(value, str):
            continue
        pieces = _TOKEN.split(value)
        tokens = _TOKEN.findall(value)

        def replace(match: re.Match) -> str:
            original = match.group(0)
            targets = changes.get(original, set())
            if original in unchanged or len(targets) != 1:
                return original
            return next(iter(targets))

        pieces = [_PERCENT.sub(replace, piece) for piece in pieces]
        row[key] = pieces[0] + "".join(token + piece for token, piece in zip(tokens, pieces[1:]))


def _update_manual_text(row: dict, kind: str, factor: float = FACTOR) -> None:
    """Scale audited manual magnitudes, leaving mechanics and conditions."""
    if kind not in _MANUAL_DAMAGE_PERCENT_INDICES:
        raise ValueError(f"unreviewed captain manual ability: {kind}")
    positions = (set(_MANUAL_DAMAGE_PERCENT_INDICES[kind])
                 - set(_MANUAL_DAMAGE_EXCLUDED.get(kind, ()))) | set(_MANUAL_EFFECT_PERCENT_INDICES.get(kind, ()))
    preserved = set(_MANUAL_PRESERVED_PERCENT_INDICES.get(kind, ()))
    if isinstance(row.get("info"), str):
        index = 0

        def replace_info(match: re.Match) -> str:
            nonlocal index
            selected = index in positions
            index += 1
            return _pct(_number(float(match.group(1)) * factor / 100)) if selected else match.group(0)

        row["info"] = _PERCENT.sub(replace_info, row["info"])
        if positions | preserved != set(range(index)):
            raise ValueError(f"unreviewed manual captain info percentage: {row['id']} {kind}")

        if kind in _MANUAL_FLAT_STAT_LABELS:
            label = _MANUAL_FLAT_STAT_LABELS[kind]
            seen = 0

            def replace_flat(match: re.Match) -> str:
                nonlocal seen
                if match.group(2) != label:
                    return match.group(0)
                seen += 1
                value = _number(float(match.group(1)) * factor)
                return f"{value:g}点{label}"

            row["info"] = _FLAT_STAT.sub(replace_flat, row["info"])
            if seen != 1:
                raise ValueError(f"manual captain flat-stat text changed: {row['id']} {kind}")
    template = row.get("rankInfoTemplate")
    if isinstance(template, str):
        index = 0

        def replace_scale(match: re.Match) -> str:
            nonlocal index
            selected = index in positions
            index += 1
            if not selected:
                return match.group(0)
            return f"{{scale:{_number(float(match.group(1)) * factor)}:{_number(float(match.group(2)) * factor)}}}"

        row["rankInfoTemplate"] = _SCALE_TOKEN.sub(replace_scale, template)


def _scale_captain_row(source: dict, factor: float = FACTOR, *, scale_displacement: bool = True) -> tuple[dict, Counter, dict]:
    row = copy.deepcopy(source)
    sid = row["id"]
    counts = Counter()
    scaled: set[tuple[int, ...]] = set()
    changes: dict[str, set[str]] = defaultdict(set)
    unchanged: set[str] = set()
    manual_kinds: list[str] = []
    generic_summon = False
    actions = row.get("skill", [])
    # Keep source damage-to-heal ratios: the damage source gets 1.5x, so
    # scaling the ratio as well would incorrectly make healing 2.25x.
    derived_heals = 0
    for index, action in enumerate(actions):
        if not isinstance(action, list) or not action or action[0] not in _REVIEWED:
            raise ValueError(f"unreviewed captain action: {sid} {index} {action!r}")
        kind = action[0]
        counts[kind] += 1
        damage, steal, defense = _action_paths(action)
        paths = set(damage + defense + list(_EXTRA_PATHS.get(kind, ())))
        if kind == "push" and not scale_displacement:
            paths.discard((1,))
        if kind == "manual_ability":
            if len(action) < 3 or not isinstance(action[1], str):
                raise ValueError(f"malformed captain manual ability: {sid} {index}")
            manual_kinds.append(action[1])
        if kind == "summon":
            generic_summon = True
        # heal_damage_sum consumes recorded damage from earlier actions;
        # the other listed operators heal from their own scaled damage.
        if steal:
            derived_heals += 1
        for path in paths:
            old = _numeric(_get(action, path), sid, index, path)
            if old == 0:
                continue
            new = _number(old * factor)
            _set(action, path, new)
            scaled.add((index, *path))
            changes[_pct(old)].add(_pct(new))
        # Ambiguous literals matching an unchanged coefficient must not be
        # rewritten just because another action used the same percentage.
        for path in steal:
            old = _numeric(_get(action, path), sid, index, path)
            unchanged.add(_pct(old))
    if len(manual_kinds) > 1:
        raise ValueError(f"multiple captain manual abilities: {sid}")
    _update_growth(row, scaled, factor)
    chain_dot = row.get("chainDot")
    if isinstance(chain_dot, list) and len(chain_dot) >= 2:
        old = _numeric(chain_dot[1], sid, -1, (1,))
        chain_dot[1] = _number(old * factor)
        changes[_pct(old)].add(_pct(chain_dot[1]))
        counts["chainDot"] += 1
    if manual_kinds:
        old_factor = row.get("manualDamageMultiplier", 1)
        _numeric(old_factor, sid, -1, ())
        row["manualDamageMultiplier"] = _number(old_factor * factor)
        old_effect = row.get("manualEffectMultiplier", 1)
        _numeric(old_effect, sid, -1, ())
        row["manualEffectMultiplier"] = _number(old_effect * factor)
        _update_manual_text(row, manual_kinds[0], factor)
    else:
        _update_text(row, changes, unchanged)
    if generic_summon:
        # Native code scales spawned unit combat stats through this field;
        # changing action[1] would change summon level instead.
        row["captainSummonMultiplier"] = _number(row.get("captainSummonMultiplier", 1) * factor)
    clone_action = any(a[0] == "clone_normal" for a in actions)
    clone_policy = row.get("manualClonePolicy")
    if clone_action and not isinstance(clone_policy, dict):
        raise ValueError(f"captain clone has no stat policy: {sid}")
    if clone_action:
        old = _numeric(clone_policy["panelStatRatio"], sid, -1, ())
        clone_policy["panelStatRatio"] = _number(old * factor)
        changes[_pct(old)].add(_pct(clone_policy["panelStatRatio"]))
        _update_text(row, changes, unchanged)
    notes = {"derived_heals": derived_heals,
             "summon_native_context": generic_summon,
             "normal_clone_policy_scaled": clone_action}
    return row, counts, notes


def apply_captain_strength(document: dict) -> dict:
    """Mutate a loaded config once, returning a JSON-serializable audit marker."""
    cfg = document["cfg"]
    marker = cfg.get("captain_strength")
    if marker:
        if marker.get("schema") == SCHEMA:
            return marker
        raise ValueError(f"another captain strength overlay exists: {marker!r}")
    avatars = cfg["avatar"]
    skills = cfg["skill"]
    captain_refs: dict[str, list[str]] = defaultdict(list)
    ordinary_refs: set[str] = set()
    for aid, avatar in avatars.items():
        pl = avatar.get("pl", [])
        if len(pl) > 10 and isinstance(pl[10], str):
            ordinary_refs.add(pl[10])
        if len(pl) > 11 and isinstance(pl[11], str) and pl[11] in skills:
            captain_refs[pl[11]].append(aid)
    if not captain_refs:
        raise ValueError("no captain skill references found")
    replacements = {}
    rewires = {}
    kinds = Counter()
    notes = Counter()
    native_followups: dict[str, list[str]] = defaultdict(list)
    for sid in sorted(captain_refs):
        row, counts, findings = _scale_captain_row(skills[sid])
        kinds.update(counts)
        notes.update(findings)
        if findings["summon_native_context"]:
            native_followups["summon_native_context"].append(sid)
        target = _captain_id(sid, skills) if sid in ordinary_refs else sid
        row["id"] = target
        replacements[target] = row
        if target != sid:
            rewires[sid] = target
    # Commit only after every row was validated, so an unknown operator
    # cannot leave a partially transformed config behind.
    skills.update(replacements)
    for sid, target in rewires.items():
        for aid in captain_refs[sid]:
            avatars[aid]["pl"][11] = target
    marker = {
        "schema": SCHEMA,
        "factor": FACTOR,
        "captain_skill_rows": len(captain_refs),
        "private_clones": len(rewires),
        "action_kinds": dict(sorted(kinds.items())),
        "derived_heal_ratios_preserved": notes["derived_heals"],
        "summon_native_context_rows": notes["summon_native_context"],
        "normal_clone_policy_scaled_rows": notes["normal_clone_policy_scaled"],
        "native_followups": dict(sorted(native_followups.items())),
    }
    cfg["captain_strength"] = marker
    return marker
