"""Captain-only opening and repeat cadence for the authored skill families.

The family table is deliberately about *what a skill does*, not its rarity or
numeric ID order.  Every currently authored family is assigned an opening;
new families use a conservative effect-based rule until they are reviewed.
Only the two timing fields and their visible text are changed.
"""

from __future__ import annotations

import copy
import hashlib
import re
from collections import Counter, defaultdict


SCHEMA = "captain-timing-v1"


def _families(numbers: str) -> set[str]:
    return {"S_" + number for number in numbers.split()}


# Straight attacks, movement strikes, and short self-buffs can enter early.
OPEN_1 = _families("""
301129 301201 301206 301207 301208 301210 301211 301213
301214 301215 301216 301219 301222 301223 301309 302013
305015 631033 9003
""")

# Single-target control, two-turn defenses, small summons and mixed attacks.
OPEN_2 = _families("""
301007 301008 301202 301203 301204 301209 301218 301221
301226 301228 301310 301217 303002 303003 303004 303006
631016 631017 631018 631021 631022 631023 631024 631026
631028 631030 631045 631049 631052 631053 631060 631068
631074 631077 631078 631082 631083 631093 631094 631095
631106 631108 631109 631112 631117 631119 631123 631128
631131 631136 651025 651041 651071 651073 651085 651086
651097 651098 651105 651115 651120 651138 651143 651205 9001 9005
""")

# Large area bursts, long control, resurrection, persistent pets, and
# multi-stage/manual executions should enter only after the battle develops.
OPEN_3 = _families("""
301001 301009 303014 305010 611001 631019 631020 631029
631032 631040 631054 631063 631079 631081 631090 631096
631099 631101 631113 631124 631125 631126 631127 631130
631132 631133 631135 631137 631142 651005 651011 651012
651027 651036 651056 651103 651114
""")

# Kassadin's four independently expiring stacks require an immediate repeat
# after his long wind-up; a normal cooldown would make four stacks impossible.
STACKING_OPEN_4_REPEAT_0 = _families("631134")

# Direct hits, dashes and shield removal have no persistent protection/control.
REPEAT_2 = _families("""
301129 301201 301207 301208 301210 301211 301213 301214
301215 301219 301222 302013 305015 9003
""")
# Short-cycle families: 301008's armor lasts one turn; 301206/631023/
# 631083/631123/651086 offer at most two-turn self stats; 301216/301309
# have two-turn DOTs, 301223's weak is short, and 301221's Tibbers is capped
# at one live summon. 631094/651105 are mobile healers without long control.
REPEAT_2 |= _families("""
301008 301206 301216 301221 301223 301309 631023 631083
631094 631123 651086 651105
""")

# Actual 900% single-target true-damage executions are the only 4-turn
# family.  Ziggs' 384% primary / 216% splash stays at 3 despite broad reach;
# pets, revivals and shields refresh or obey existing live-count limits.
REPEAT_4 = _families("301001 611001")

KNOWN = OPEN_1 | OPEN_2 | OPEN_3 | STACKING_OPEN_4_REPEAT_0
if len(KNOWN) != sum(map(len, (OPEN_1, OPEN_2, OPEN_3, STACKING_OPEN_4_REPEAT_0))):
    raise AssertionError("captain opening families overlap")
if REPEAT_2 & REPEAT_4 or not (REPEAT_2 | REPEAT_4) <= KNOWN:
    raise AssertionError("captain repeat families overlap or are unknown")

_PREPARE = re.compile(r"准备(?:时间|回合)?\s*[:：]?\s*\d+")
_COOLDOWN = re.compile(r"冷却(?:时间|回合)?\s*[:：]?\s*\d+")


def _timing_text(text: str, prepare: int, cooldown: int) -> str:
    """Keep existing wording where present and add one concise timing note."""
    had_prepare = bool(_PREPARE.search(text))
    had_cooldown = bool(_COOLDOWN.search(text))
    text = _PREPARE.sub(lambda m: re.sub(r"\d+$", str(prepare), m.group()), text)
    text = _COOLDOWN.sub(lambda m: re.sub(r"\d+$", str(cooldown), m.group()), text)
    if not had_prepare or not had_cooldown:
        suffix = "、".join(part for present, part in (
            (had_prepare, f"准备{prepare}"), (had_cooldown, f"冷却{cooldown}"))
            if not present)
        text = text.rstrip() + (" " if text.strip() else "") + suffix + "。"
    return text


def _fallback_timing(row: dict) -> tuple[int, int]:
    """Safe semantic default for newly added, not-yet-curated families."""
    actions = row.get("skill") or []
    kinds = [action[0] for action in actions if action]
    info = row.get("info", "")
    control = bool(set(kinds) & {"stun", "stun_by_condition", "silence", "root"})
    persistent = bool(set(kinds) & {"summon", "summon_turret", "clone_normal", "bless", "timed_stack"})
    heavy = bool(set(kinds) & {"locked_combo_group", "locked_sequence_area", "combo", "manual_ability"})
    long_effect = bool(re.search(r"持续[34](?:次自身行动|回合)", info))
    mixed = len(kinds) >= 3
    if persistent or heavy or (control and mixed) or long_effect:
        return 3, 3
    if control or mixed or len(kinds) == 2:
        return 2, 3
    if kinds == ["damage"] or kinds == ["true_damage"]:
        return 1, 2
    return 2, 3


def _timing_for(sid: str, row: dict) -> tuple[int, int]:
    family = sid.rsplit("_", 1)[0]
    if family in STACKING_OPEN_4_REPEAT_0:
        return 4, 0
    if family not in KNOWN:
        return _fallback_timing(row)
    prepare = 1 if family in OPEN_1 else 2 if family in OPEN_2 else 3
    cooldown = 2 if family in REPEAT_2 else 4 if family in REPEAT_4 else 3
    return prepare, cooldown


def _private_id(sid: str, skills: dict) -> str:
    rarity = sid.rsplit("_", 1)[-1]
    digest = hashlib.sha256(("captain-timing:" + sid).encode()).hexdigest()
    candidate = f"S_8{int(digest[:12], 16)}_{rarity}"
    if candidate in skills:
        raise ValueError(f"captain timing private skill collision: {candidate}")
    return candidate


def apply_captain_timing(document: dict) -> dict:
    """Apply once to a loaded config, returning a small audit marker."""
    cfg = document["cfg"]
    marker = cfg.get("captain_timing")
    if marker:
        if marker.get("schema") == SCHEMA:
            return marker
        raise ValueError(f"another captain timing overlay exists: {marker!r}")
    skills = cfg["skill"]
    avatars = cfg["avatar"]
    refs: dict[str, list[str]] = defaultdict(list)
    ordinary: set[str] = set()
    for aid, avatar in avatars.items():
        pl = avatar.get("pl") or []
        if len(pl) > 11 and isinstance(pl[11], str) and pl[11]:
            if pl[11] not in skills:
                raise ValueError(f"missing captain skill: {aid} {pl[11]}")
            refs[pl[11]].append(aid)
        for slot in (10, 13):
            if len(pl) > slot and isinstance(pl[slot], str):
                ordinary.add(pl[slot])
    if not refs:
        raise ValueError("no captain skills found")

    replacements = {}
    rewires = {}
    distribution = Counter()
    changed = 0
    unreviewed = []
    for sid in sorted(refs):
        row = copy.deepcopy(skills[sid])
        pl = row.get("pl")
        if not isinstance(pl, list) or len(pl) < 2 or any(
            type(value) is not int or value < 0 for value in pl[:2]
        ):
            raise ValueError(f"invalid captain timing: {sid}")
        timing = _timing_for(sid, row)
        if sid.rsplit("_", 1)[0] not in KNOWN:
            unreviewed.append(sid)
        changed += tuple(pl[:2]) != timing
        pl[:2] = timing
        for key in ("info", "rankInfoTemplate"):
            if isinstance(row.get(key), str):
                row[key] = _timing_text(row[key], *timing)
        target = _private_id(sid, skills) if sid in ordinary else sid
        row["id"] = target
        replacements[target] = row
        if target != sid:
            rewires[sid] = target
        distribution[f"prepare_{timing[0]}"] += 1
        distribution[f"cooldown_{timing[1]}"] += 1
    skills.update(replacements)
    for sid, target in rewires.items():
        for aid in refs[sid]:
            avatars[aid]["pl"][11] = target
    marker = {
        "schema": SCHEMA,
        "skill_rows": len(refs),
        "changed_rows": changed,
        "private_clones": len(rewires),
        "unreviewed_families": unreviewed,
        "distribution": dict(sorted(distribution.items())),
    }
    cfg["captain_timing"] = marker
    return marker
