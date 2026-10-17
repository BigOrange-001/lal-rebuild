"""Scale four-stat ally buffs authored on six-star orange hero skills.

This is an in-memory full-config overlay.  The numbers live on skill actions,
not on Buff/getHit/getFlee, so equipment, talents, enemy debuffs, duration and
proc chances retain their original behavior.
"""

from __future__ import annotations

import copy
import re
from collections import defaultdict


SCHEMA = "orange-six-star-four-stat-buffs-v1"
MULTIPLIER = 5
STATS = frozenset(("hit", "flee", "tough", "crit"))
SKILL_SLOTS = (10, 11, 13)  # ordinary, captain and passive
_POINTS = re.compile(r"(?<![\d.])\d+(?:\.\d+)?点(精准|命中|闪避|韧性|暴击)")
_STAT_LABEL = {"精准": "hit", "命中": "hit", "闪避": "flee", "韧性": "tough", "暴击": "crit"}


def _is_orange(aid: str) -> bool:
    return aid.startswith("A_") and aid.endswith("_6")


def _position(action: list) -> int | None:
    if not action:
        return None
    if action[0] == "stat_flat" and len(action) >= 5 and action[1] in STATS:
        return 2
    if action[0] == "attrup" and len(action) >= 6 and action[2] in STATS:
        return 1
    if action[0] == "battle_stack_unconditional" and len(action) >= 5 and action[1] in STATS:
        return 2
    return None


def _clone_id(sid: str, skills: dict) -> str:
    private_id = sid + "__orange6_four_stat5"
    if private_id in skills:
        raise ValueError(f"private orange skill ID already exists: {private_id}")
    return private_id


def _refresh_point_descriptions(row: dict, original_actions: list) -> None:
    """Make explicit point values show actual rank-one values and track rank."""
    stat_actions: dict[str, list[int]] = defaultdict(list)
    for index, action in enumerate(original_actions):
        if not isinstance(action, list) or _position(action) is None:
            continue
        stat = action[1] if action[0] != "attrup" else action[2]
        # Percentage-based attrup has no fixed point value to describe.
        if action[0] != "attrup":
            stat_actions[stat].append(index)

    def replace(text: str, tokens: bool) -> str:
        def render(match: re.Match) -> str:
            stat = _STAT_LABEL[match.group(1)]
            candidates = stat_actions.get(stat, [])
            if len(candidates) != 1:
                return match.group(0)
            index = candidates[0]
            value = row["skill"][index][2]
            points = f"{{flat:{index}:2}}" if tokens else str(round(value))
            return points + "点" + match.group(1)
        return _POINTS.sub(render, text)

    info = row.get("info")
    if not isinstance(info, str):
        return
    template = row.get("rankInfoTemplate", info)
    row["info"] = replace(info, tokens=False)
    if isinstance(template, str):
        rendered = replace(template, tokens=True)
        if rendered != template or "rankInfoTemplate" in row:
            row["rankInfoTemplate"] = rendered


def apply_orange_four_stat_buffs(document: dict) -> dict:
    """Mutate a full-config document once and return a deterministic report."""
    cfg = document["cfg"]
    marker = cfg.get("orange_four_stat_buff_overlay")
    if marker is not None:
        if marker.get("schema") == SCHEMA:
            return marker
        raise ValueError(f"incompatible orange four-stat overlay: {marker!r}")

    avatars, skills = cfg["avatar"], cfg["skill"]
    owners: dict[str, list[tuple[str, int]]] = defaultdict(list)
    for aid, avatar in avatars.items():
        pl = avatar.get("pl", [])
        for slot in SKILL_SLOTS:
            if len(pl) > slot and isinstance(pl[slot], str) and pl[slot] in skills:
                owners[pl[slot]].append((aid, slot))

    skill_count = action_count = clone_count = 0
    kind_counts: dict[str, int] = defaultdict(int)
    for sid in sorted(owners):
        users = owners[sid]
        if not any(_is_orange(aid) for aid, _ in users):
            continue
        source = skills[sid]
        actions = source.get("skill", [])
        positions = {index: _position(action) for index, action in enumerate(actions)
                     if isinstance(action, list)}
        positions = {index: pos for index, pos in positions.items() if pos is not None}
        if not positions:
            continue
        policies = source.get("actionTargetPolicies") or []
        for index in positions:
            action = actions[index]
            if action[0] == "stat_flat":
                policy = policies[index] if index < len(policies) else None
                if not isinstance(policy, str) or not policy.startswith("ally_"):
                    raise ValueError(f"cannot prove {sid} action {index} buffs an ally: {policy!r}")
            if not isinstance(action[positions[index]], (int, float)) or isinstance(action[positions[index]], bool):
                raise ValueError(f"nonnumeric orange buff {sid} action {index}")
            if action[0] == "stat_flat" and action[positions[index]] * MULTIPLIER > 100000:
                # SkillSet.useSkill rejects larger flat buffs.  Fail here
                # rather than publish a visually stronger but inert skill.
                raise ValueError(f"orange flat buff exceeds native cap: {sid} action {index}")

        target_id = sid
        if any(not _is_orange(aid) for aid, _ in users):
            target_id = _clone_id(sid, skills)
            skills[target_id] = copy.deepcopy(source)
            skills[target_id]["id"] = target_id
            for aid, slot in users:
                if _is_orange(aid):
                    avatars[aid]["pl"][slot] = target_id
            clone_count += 1
        row = skills[target_id]
        original_actions = copy.deepcopy(row["skill"])
        for index, position in positions.items():
            action = row["skill"][index]
            action[position] *= MULTIPLIER
            action_count += 1
            kind_counts[action[0]] += 1

        # Native SkillSet.init adds skillUp deltas after copying base actions.
        # The delta must change alongside the base to keep every rank 5x.
        upgrades = row.get("skillUp") or []
        if (isinstance(upgrades, list) and len(upgrades) >= 2
                and isinstance(upgrades[0], int) and isinstance(upgrades[1], (int, float))
                and positions.get(upgrades[0]) == 1):
            # Legacy two-item form upgrades action[index][1].
            upgrades[1] *= MULTIPLIER
        for upgrade in upgrades:
            if (isinstance(upgrade, list) and len(upgrade) >= 3
                    and isinstance(upgrade[0], int) and isinstance(upgrade[1], int)
                    and positions.get(upgrade[0]) == upgrade[1]):
                upgrade[2] *= MULTIPLIER
        for upgrade in row.get("skillUpPaths") or []:
            if (isinstance(upgrade, list) and len(upgrade) >= 3
                    and isinstance(upgrade[0], int) and isinstance(upgrade[1], list)
                    and len(upgrade[1]) == 1
                    and positions.get(upgrade[0]) == upgrade[1][0]):
                upgrade[2] *= MULTIPLIER
        _refresh_point_descriptions(row, original_actions)
        skill_count += 1

    report = {"schema": SCHEMA, "multiplier": MULTIPLIER,
              "skills": skill_count, "actions": action_count,
              "cloned_shared_skills": clone_count,
              "action_kinds": dict(sorted(kind_counts.items()))}
    cfg["orange_four_stat_buff_overlay"] = report
    return report
