"""One-time skill balance overlay for the 1c1b0db configuration baseline.

This module only transforms an in-memory full-config document.  It does not
read or write the published configuration, player state, or running service.
"""

from __future__ import annotations

import copy
import hashlib
import re
from collections import defaultdict


SCHEMA = "combat-skill-balance-1c1b0db-v1"
BASELINE_SKILL_SHA256 = "ddd68c5436d90efc687e610378f632cdd36e96dc2abb061cead77567d4708d8a"
_PERCENT = re.compile(r"(?<![\d.])([0-9]+(?:\.[0-9]+)?)%")
_RANK_TOKEN = re.compile(r"\{(?:rank|scale|flat):[^}]+\}")
_SCALE_TOKEN = re.compile(r"\{scale:([0-9.]+):([0-9.]+)\}")

# Percentage positions in the existing authored descriptions.  These were
# audited against Avatar.executeAbility: shield/heal, attack buff, summoning,
# sunder and damage reduction percentages are intentionally absent.
_MANUAL_DAMAGE_PERCENT_INDICES = {
    "illaoi_n": (0,), "illaoi_c": (0, 1),
    "jayce_n": (0, 1, 2), "jayce_c": (0, 1),
    "nidalee_n": (0, 1), "nidalee_c": (2, 3),
    "kayle_n": (0,), "kayle_c": (0,),
    "maokai_n": (0,), "maokai_c": (0,),
    "wukong_n": (0,), "wukong_c": (0,),
    "gangplank_n": (0,), "gangplank_c": (0,),
    "yi_n": (0, 1), "yi_c": (),
    "veigar_n": (0,), "veigar_c": (0, 1),
    "elise_n": (0, 1, 2), "elise_c": (0, 1, 2),
    "riven_n": (0, 1, 2), "riven_c": (1, 2),
    "orianna_n": (2,), "orianna_c": (0,),
    "nunu_n": (0, 1), "nunu_c": (2,),
    "alistar_n": (0, 1), "alistar_c": (),
    "diana_n": (0,), "diana_c": (0, 1),
    "khazix_n": (0, 1), "khazix_c": (0, 1),
    "malzahar_n": (0,), "malzahar_c": (0,),
    "jinx_n": (0, 1), "jinx_c": (0, 1, 2, 3),
    "tahm_n": (0,), "tahm_c": (),
    "caitlyn_n": (0, 1), "caitlyn_c": (0, 1),
    "kaelthas_n": (0, 1), "kaelthas_c": (0, 1, 2),
    "aoxing_n": (0, 1), "aoxing_c": (0, 1),
}
_MANUAL_DEFENSE_PERCENT_INDICES = {"wukong_c": (1,), "tahm_c": (2,)}


def _number(value: float) -> float:
    return round(value, 10)


def _pct(value: float) -> str:
    return f"{value * 100:.4f}".rstrip("0").rstrip(".") + "%"


def _action_paths(action: list) -> tuple[list[tuple[int, ...]], list[tuple[int, ...]], list[tuple[int, ...]]]:
    """Return damage, damage-to-heal, and both-defense coefficient paths."""
    kind = action[0]
    damage: list[tuple[int, ...]] = []
    steal: list[tuple[int, ...]] = []
    defense: list[tuple[int, ...]] = []
    direct = {
        "damage", "combo", "suck", "stun", "silence", "weak",
        "weak_percent", "sunder", "sunder_percent", "pull",
        "pull_group", "true_damage", "dash_group_strike", "manual_ability",
        "locked_combo_weak", "poison", "burn",
    }
    if kind in direct:
        # push_aoe is deliberately absent: its numbers are distances.
        # manual_ability has its own native multiplier channel; action[2]
        # also controls healing/shield and must remain at the authored value.
        if kind != "manual_ability":
            damage.append((1,))
    if kind == "suck":
        steal.append((3,))
    elif kind == "poison":
        # Index 1 is the direct hit; index 3 is damage per poison round.
        damage.append((3,))
    elif kind == "heal_damage_sum":
        steal.append((1,))
    elif kind == "locked_combo_group":
        damage.append((3,))
        steal.append((5,))
    elif kind in {"locked_sequence", "locked_sequence_area"}:
        count = int(action[1])
        damage.extend((i,) for i in range(2, 2 + count))
        steal.append((3 + count,))
    elif kind == "conditional_damage":
        damage.extend(((1,), (4,)))
    elif kind == "manual_dot":
        damage.append((2,))
    elif kind == "damage_chain":
        damage.extend((2, i) for i in range(len(action[2])))
        damage.extend(((7,), (9,)))
    elif kind == "ricochet_bursts":
        damage.extend((2, i) for i in range(len(action[2])))
    elif kind == "pending_area_strike":
        damage.append((2,))
    elif kind == "shield_followup":
        damage.append((3,))
    elif kind == "steel":
        defense.append((1,))
    elif kind in {"battle_stack", "battle_stack_unconditional"} and action[1] == "defense":
        defense.append((2,))
    return damage, steal, defense


def _get(action: list, path: tuple[int, ...]):
    value = action
    for index in path:
        value = value[index]
    return value


def _set(action: list, path: tuple[int, ...], value: float) -> None:
    target = action
    for index in path[:-1]:
        target = target[index]
    target[path[-1]] = _number(value)


def _scale_row(row: dict, damage_factor: float, steal_factor: float) -> dict:
    row = copy.deepcopy(row)
    scaled: dict[tuple[int, ...], float] = {}
    percent_changes: dict[str, set[str]] = defaultdict(set)
    unchanged_percent: set[str] = set()
    for action_index, action in enumerate(row.get("skill", [])):
        if not isinstance(action, list) or not action:
            continue
        damage, steal, defense = _action_paths(action)
        chosen: dict[tuple[int, ...], float] = {}
        for path in damage:
            chosen[path] = damage_factor
        for path in steal:
            chosen[path] = steal_factor
        for path in defense:
            chosen[path] = 2.0
        for path, factor in chosen.items():
            old = _get(action, path)
            if not isinstance(old, (int, float)) or isinstance(old, bool):
                raise ValueError(f"non-numeric skill coefficient: {row['id']} {action_index} {path}")
            if factor == 1 or old == 0:
                continue
            new = _number(old * factor)
            _set(action, path, new)
            scaled[(action_index, *path)] = factor
            percent_changes[_pct(old)].add(_pct(new))
        # An unchanged attack buff cannot be rewritten just because it happens
        # to share the percentage of a modified damage coefficient.
        unchanged_paths = {
            "strong": (1,), "armor": (1,), "shield": (1,),
            "hp_shield": (1,), "caster_hp_shield": (1,), "target_hp_shield": (1,),
            "weak": (3,), "weak_percent": (3,), "sunder": (3,),
            "sunder_percent": (3,), "attrup": (1,), "cure": (1,),
            "shield_followup": (1, 6), "kill_buff": (2,),
        }.get(action[0], ())
        if action[0] in {"battle_stack", "battle_stack_unconditional", "timed_stack"} and action[1] != "defense":
            unchanged_paths = (2,)
        for index in unchanged_paths:
            if index < len(action) and isinstance(action[index], (int, float)) and not isinstance(action[index], bool):
                unchanged_percent.add(_pct(action[index]))
    chain_dot = row.get("chainDot")
    if isinstance(chain_dot, list) and len(chain_dot) == 5 and isinstance(chain_dot[1], (int, float)):
        old = chain_dot[1]
        chain_dot[1] = _number(old * damage_factor)
        percent_changes[_pct(old)].add(_pct(chain_dot[1]))

    upgrades = row.get("skillUp")
    if isinstance(upgrades, list) and upgrades:
        if isinstance(upgrades[0], list):
            for entry in upgrades:
                if isinstance(entry, list) and len(entry) >= 3:
                    factor = scaled.get((int(entry[0]), int(entry[1])))
                    if factor is not None:
                        entry[2] = _number(entry[2] * factor)
        elif len(upgrades) >= 2:
            factor = scaled.get((int(upgrades[0]), 1))
            if factor is not None:
                upgrades[1] = _number(upgrades[1] * factor)
    for entry in row.get("skillUpPaths", []) or []:
        if isinstance(entry, list) and len(entry) >= 3 and isinstance(entry[1], list):
            factor = scaled.get((int(entry[0]), *map(int, entry[1])))
            if factor is not None:
                entry[2] = _number(entry[2] * factor)

    # rankInfoTemplate resolves numbers from action arrays at display time;
    # only its literal percentages (and the static info fallback) need edits.
    def update_text(original: str) -> str:
        pieces = _RANK_TOKEN.split(original)
        tokens = _RANK_TOKEN.findall(original)
        def replace(match: re.Match) -> str:
            old = match.group(0)
            replacements = percent_changes.get(old, set())
            if old in unchanged_percent or len(replacements) != 1:
                return old
            return next(iter(replacements))
        pieces = [_PERCENT.sub(replace, piece) for piece in pieces]
        result = pieces[0]
        for token, piece in zip(tokens, pieces[1:]):
            result += token + piece
        return result

    for key in ("info", "rankInfoTemplate"):
        if isinstance(row.get(key), str):
            row[key] = update_text(row[key])
    if row["id"].startswith("S_621019_"):
        # This original text reused the sunder placeholder for bleed damage.
        # Keep the first 20% debuff intact, then show the scaled bleed value.
        if isinstance(row.get("rankInfoTemplate"), str):
            first = row["rankInfoTemplate"].find("{rank:1:3}")
            second = row["rankInfoTemplate"].find("{rank:1:3}", first + 1)
            if second >= 0:
                row["rankInfoTemplate"] = (row["rankInfoTemplate"][:second] + "{rank:3:2}" +
                                           row["rankInfoTemplate"][second + len("{rank:1:3}"):])
        if isinstance(row.get("info"), str):
            old_token = "20%"
            first = row["info"].find(old_token)
            second = row["info"].find(old_token, first + 1)
            if second >= 0:
                row["info"] = (row["info"][:second] + _pct(row["skill"][3][2]) +
                               row["info"][second + len(old_token):])
    return row


def _private_id(original: str, profile: int, skill_rows: dict) -> str:
    star = original.rsplit("_", 1)[-1]
    seed = hashlib.sha256(f"{original}:{profile}".encode()).hexdigest()
    candidate = f"S_8{int(seed[:12], 16)}_{star}"
    if candidate in skill_rows:
        raise ValueError(f"private skill ID collision: {candidate}")
    return candidate


def _manual_description(row: dict, kind: str, factor: float) -> None:
    if kind not in _MANUAL_DAMAGE_PERCENT_INDICES:
        raise ValueError(f"unreviewed manual ability: {kind}")
    damage_positions = set(_MANUAL_DAMAGE_PERCENT_INDICES[kind])
    defense_positions = set(_MANUAL_DEFENSE_PERCENT_INDICES.get(kind, ()))
    if not damage_positions and not defense_positions:
        return

    def scale_info(match: re.Match) -> str:
        nonlocal info_index
        current = info_index
        info_index += 1
        selected_factor = 2 if current in defense_positions else factor if current in damage_positions else 1
        if selected_factor == 1:
            return match.group(0)
        return _pct(_number(float(match.group(1)) * selected_factor / 100))

    info_index = 0
    row["info"] = _PERCENT.sub(scale_info, row.get("info") or "")
    if max(damage_positions | defense_positions) >= info_index:
        raise ValueError(f"manual info lacks damage percentage: {row['id']} {kind}")

    template = row.get("rankInfoTemplate")
    if isinstance(template, str):
        scale_index = 0

        def scale_template(match: re.Match) -> str:
            nonlocal scale_index
            current = scale_index
            scale_index += 1
            if current not in damage_positions or factor == 1:
                return match.group(0)
            base = _number(float(match.group(1)) * factor)
            step = _number(float(match.group(2)) * factor)
            return f"{{scale:{base}:{step}}}"

        row["rankInfoTemplate"] = _SCALE_TOKEN.sub(scale_template, template)
        if damage_positions and max(damage_positions) >= scale_index:
            raise ValueError(f"manual rank template lacks damage percentage: {row['id']} {kind}")


def apply_skill_balance(document: dict) -> dict:
    """Mutate a full-config document once; return deterministic counts."""
    cfg = document["cfg"]
    marker = cfg.get("skill_balance_overlay")
    if marker:
        if marker.get("schema") == SCHEMA:
            return marker
        raise ValueError(f"another skill balance overlay exists: {marker!r}")
    skills = cfg["skill"]
    avatars = cfg["avatar"]
    import json
    fingerprint = hashlib.sha256(json.dumps(skills, sort_keys=True, ensure_ascii=False,
                                           separators=(",", ":")).encode("utf-8")).hexdigest()
    if fingerprint != BASELINE_SKILL_SHA256:
        raise ValueError("skill rows differ from frozen commit 1c1b0db; refusing to stack multipliers")
    # Skill slots 10/11/13 are ordinary/leader/passive in AvatarData.pl.
    refs: dict[str, list[tuple[str, int, int | None]]] = defaultdict(list)
    for aid, avatar in avatars.items():
        profile = avatar.get("stat_profile")
        for slot in (10, 11, 13):
            pl = avatar.get("pl", [])
            if len(pl) > slot and isinstance(pl[slot], str) and pl[slot] in skills:
                refs[pl[slot]].append((aid, slot, profile))
    clones = 0
    changed = 0
    unresolved = 0
    for sid in list(skills):
        uses = refs.get(sid, [])
        profiles = sorted({profile for _, _, profile in uses if profile in (1, 2, 3)})
        if not profiles:
            # These are orphan/monster rows with no classified hero template.
            # Still apply universally requested both-defense and lifesteal
            # changes; no guessed rock/paper/scissors damage factor.
            profiles = [0]
            if not uses:
                unresolved += 1
        original = skills[sid]
        for index, profile in enumerate(profiles):
            target_id = sid if index == 0 else _private_id(sid, profile, skills)
            slot_set = {slot for _, slot, p in uses if p == profile or p is None}
            steal_factor = 2.0 if slot_set == {11} else 1.5
            damage_factor = 0.8 if profile == 1 else 1.2 if profile in (2, 3) else 1.0
            row = _scale_row(original, damage_factor, steal_factor)
            manual = [a for a in row.get("skill", []) if isinstance(a, list) and a and a[0] == "manual_ability"]
            if manual:
                row["manualDamageMultiplier"] = damage_factor
                row["manualDefenseBuffMultiplier"] = 2.0
                if len(manual) != 1:
                    raise ValueError(f"more than one manual ability in {sid}")
                _manual_description(row, manual[0][1], damage_factor)
            if target_id != sid:
                row["id"] = target_id
                skills[target_id] = row
                clones += 1
                for aid, slot, p in uses:
                    if p == profile:
                        avatars[aid]["pl"][slot] = target_id
            else:
                skills[sid] = row
            changed += 1

    # These two contract updates are linked to native client changes in 139
    # and 137 respectively.  Keep them in the same in-memory overlay.
    tw_policy = "enemy_adaptive_route_lowest_hp_ratio_hero"
    for sid in ("S_631096_5", "S_631096_6"):
        row = skills[sid]
        row["skill"][0][1] = tw_policy
        row["actionTargetPolicies"][0] = tw_policy
        hits = row["skill"][2]
        row["info"] = ("队长技：本路有其他存活友方英雄时，优先选择其他路当前生命比例最低的敌方英雄；仅本人时优先本路。"
                       "首选无目标才回退另一组，无目标则不施法。移动至目标所在路，获得800点精准持续2回合，"
                       f"连续造成{_pct(hits[2])}、{_pct(hits[3])}、{_pct(hits[4])}魔法伤害，并使原目标沉默1回合。"
                       "准备4回合，冷却6回合。")
    cfg["system_simple"]["attack"][20] = 0.5
    for row in skills.values():
        if not any(isinstance(a, list) and a and a[0] == "bless" for a in row.get("skill", [])):
            continue
        sid = row["id"]
        actions = row["skill"]
        bless_note = "神佑持续至首次致死：触发时消耗神佑，以最大生命值50%复活。"
        if sid.startswith("S_631081_"):
            row["info"] = (f"队长技：为自身施加神佑。对同路最多4名敌人造成{_pct(actions[1][1])}魔法伤害，"
                           "施加40%衰弱与30%破甲，持续3回合。" + bless_note + "准备5回合，冷却7回合。")
        elif sid.startswith("S_631095_"):
            row["info"] = ("队长技：为同路当前生命比例最低的友方英雄施加神佑，恢复相当于攻击力80%的生命值，"
                           "并提高40%攻击力持续2回合。" + bless_note + "准备2回合，冷却6回合。")
        elif sid.startswith("S_631113_"):
            row["info"] = (f"队长技：自身攻击力提高50%、双抗提高{_pct(actions[1][1])}，持续3回合，"
                           "并恢复相当于攻击力100%的生命值。" + bless_note + "准备4回合，冷却7回合。")
        elif sid.startswith("S_631142_"):
            row["info"] = ("队长技：为范围内最多2名生命比例最低的友方英雄施加神佑，"
                           "各恢复相当于攻击力50%的生命值。" + bless_note + "准备5回合，冷却8回合。")
    marker = {"schema": SCHEMA, "scaled_rows": changed, "private_clones": clones,
              "unclassified_or_orphan_rows": unresolved}
    cfg["skill_balance_overlay"] = marker
    return marker
