"""Generate a persistent nine-opponent local arena batch from real snapshots."""
from __future__ import annotations

import copy
import hashlib
import math
import random
import re
import secrets

from battle_engine import serialize_stage_team
from bot_names import sample_bot_names


STAT_KEYS = ("hp", "ap", "de_ph", "de_ma")


def highest_rarity_heroes(cfg: dict) -> list[str]:
    """One highest configured A_1xxx color per hero family, including skins."""
    selected: dict[str, tuple[int, str]] = {}
    for aid in cfg.get("avatar", {}):
        if not re.fullmatch(r"A_1\d{3}_[2-6]", aid):
            continue
        family, star_text = aid.rsplit("_", 1)
        candidate = (int(star_text), aid)
        if candidate > selected.get(family, (0, "")):
            selected[family] = candidate
    result = sorted(aid for _, aid in selected.values())
    if len(result) < 5:
        raise ValueError("arena needs at least five configured hero families")
    return result


def opponent_ranks(player_rank: int) -> list[int]:
    # Native PvP title bands cover ranks 1..100. Rank 1 (King) therefore
    # receives ranks 2..10, which are still selectable challenges.
    choices = sorted((rank for rank in range(1, 101) if rank != player_rank),
                     key=lambda rank: (abs(rank - player_rank), rank))[:9]
    return sorted(choices)


def _scaled_units(base: list[dict], factor: float) -> list[dict]:
    result = copy.deepcopy(base)
    for unit, original in zip(result, base):
        for key in STAT_KEYS:
            unit[key] = max(1, round(int(original[key]) * factor))
        unit["hp_max"] = unit["hp"]
    return result


def _fit_units(base: list[dict], target: int, power_fn) -> tuple[list[dict], int]:
    low, high = 0.0, 1.0
    while power_fn(_scaled_units(base, high)) < target and high < 4096:
        high *= 2
    if power_fn(_scaled_units(base, high)) < target:
        raise ValueError("arena opponent power target is unreachable")
    for _ in range(28):
        mid = (low + high) / 2
        if power_fn(_scaled_units(base, mid)) < target:
            low = mid
        else:
            high = mid
    candidates = (_scaled_units(base, low), _scaled_units(base, high))
    return min(((units, power_fn(units)) for units in candidates),
               key=lambda result: abs(result[1] - target))


def generate_opponents(cfg: dict, owner_uid: str, generation: int, player_rank: int,
                       own_units: list[dict], power_fn) -> dict:
    pool = highest_rarity_heroes(cfg)
    own_power = power_fn(own_units)
    if own_power < 1:
        raise ValueError("current arena team has no battle power")
    if type(generation) is not int or generation < 1:
        raise ValueError("arena generation must be positive")
    nonce = secrets.token_hex(16)
    rng = random.Random(int.from_bytes(hashlib.sha256(
        f"{owner_uid}:{generation}:{nonce}".encode()).digest(), "big"))
    owner_hex = hashlib.sha256(str(owner_uid).encode()).hexdigest()[:14]
    levels = [int(unit.get("lv", 1)) for unit in own_units]
    skills = [int(unit.get("slv", 1)) for unit in own_units]
    level = max(1, min(99, round(sum(levels) / len(levels))))
    skill = max(1, min(10, round(sum(skills) / len(skills))))
    names = sample_bot_names(rng, 9)
    bots = []
    for index, rank in enumerate(opponent_ranks(player_rank)):
        aids = rng.sample(pool, 5)
        team = [[aid, level, skill, slot % 3, .12 if slot < 3 else .02,
                 int(slot == 0)] for slot, aid in enumerate(aids)]
        base = serialize_stage_team(cfg, team, team=2)
        ratio = .5 + .75 * index / 8
        target = max(1, round(own_power * ratio))
        units, actual = _fit_units(base, target, power_fn)
        if not math.isfinite(actual) or actual < 1:
            raise ValueError("arena generated invalid enemy power")
        # ItemPVP treats *any* UID containing 'r' as a configured robot and
        # replaces its compact roster with pvp_robot. Hex IDs use the supplied
        # compact snapshots instead, including skin heroes.
        bot_uid = f"n{owner_hex}_{generation}_{index}"
        bots.append({"uid": bot_uid, "rank": rank,
                     "name": names[index], "lv": level,
                     "team": team, "units": units, "power": actual,
                     "target_power": target})
    return {"generation": generation, "player_rank": player_rank, "nonce": nonce,
            "source_power": own_power, "bots": bots}
