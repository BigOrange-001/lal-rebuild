"""Generate a persistent nine-opponent local arena batch from real cultivation."""
from __future__ import annotations

import copy
import datetime
import hashlib
import json
import math
import random
import re
import secrets

from npc_cultivation import template_stars
from bot_names import sample_bot_names
from mod_policy import runtime as mod_runtime, candidate_ids, policy_signature


STAT_KEYS = ("hp", "ap", "de_ph", "de_ma")
POWER_ORDER_SCHEMA = "real-cultivation-v2"
COMBAT_CONFIG_TABLES = ("avatar", "skill", "equip", "talent", "system_simple")


def _signature_date(value):
    if not isinstance(value, datetime.datetime):
        raise TypeError(f"Unsupported arena config value: {type(value).__name__}")
    if value.tzinfo is None:
        value = value.replace(tzinfo=datetime.timezone.utc)
    stamp = value.timestamp()
    return {"$date": int(stamp) if stamp.is_integer() else stamp}


def combat_config_signature(cfg: dict) -> str:
    """Fingerprint tables consumed by arena snapshots and native power.

    A persisted batch contains complete skill and stat rows. A new process
    must not reuse them after a balance/config update just because its rank
    and opponent-order schema are unchanged.
    """
    combat = {name: cfg.get(name, {}) for name in COMBAT_CONFIG_TABLES}
    if mod_runtime(cfg):
        combat["mod_policy"] = policy_signature(cfg)
    payload = json.dumps({"schema": "arena-combat-config-v1", "tables": combat},
                         sort_keys=True, ensure_ascii=False, separators=(",", ":"),
                         default=_signature_date)
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def highest_rarity_heroes(cfg: dict) -> list[str]:
    """One highest configured A_1xxx color per hero family, including skins."""
    selected: dict[str, tuple[int, str]] = {}
    candidates = [aid for aid in cfg.get("avatar", {}) if re.fullmatch(r"A_1\d{3}_[2-6]", aid)]
    if mod_runtime(cfg):
        candidates = candidate_ids(cfg, candidates, "appearance.arena_enemy", include_new=True)
    for aid in candidates:
        if not aid.rsplit("_", 1)[-1].isdigit():
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
    if player_rank > 100:
        return list(range(91, 101))
    # Native PvP title bands cover ranks 1..100. Rank 1 (King) therefore
    # receives ranks 2..10, which are still selectable challenges.
    choices = sorted((rank for rank in range(1, 101) if rank != player_rank),
                     key=lambda rank: (abs(rank - player_rank), rank))[:9]
    return sorted(choices)


def bot_lines(rng: random.Random, size: int = 5) -> list[int]:
    """A lane per slot that always covers all three lanes."""
    lines = [0, 1, 2] + [rng.randrange(3) for _ in range(max(0, size - 3))]
    rng.shuffle(lines)
    return lines[:size]


def team_rows(units: list[dict]) -> list[list]:
    """Compact ``[aid, lv, slv, line, pos, leader]`` rows kept for history."""
    return [[unit["aid"], int(unit.get("lv", 1)), int(unit.get("slv", 1)), int(unit.get("line", 0)),
             float(unit.get("pos", 0)), int(bool(unit.get("leader")))] for unit in units]


def fit_bot(cultivator, template: dict, forms: dict, rng: random.Random, target: int, power_fn,
            *, uid: str, name: str, seed: int, aids=None, lines=None) -> dict:
    """Build one opponent whose stats come from real cultivation.

    Heroes match the player's lineup quality slot by slot. When even level-1
    heroes at that quality are stronger than the target, one lower quality is
    tried, so a new account is not met by a lineup it cannot answer.
    """
    stars = template_stars(template)
    bonds: list[str] = []
    best = None
    for drop in range(0, 3):
        wanted = [max(2, star - drop) for star in stars]
        picked, picked_bonds = (aids, []) if aids else cultivator.pick_team(rng, forms, wanted)
        slot_lines = lines or bot_lines(rng, len(picked))
        result = cultivator.fit(picked, template, target, power_fn, seed, uid=uid, name=name,
                                scope="arenaEnemy", lines=slot_lines + [0] * (6 - len(slot_lines)))
        result.update(aids=picked, bonds=picked_bonds, lines=slot_lines)
        if best is None or abs(result["power"] - target) < abs(best["power"] - target):
            best = result
        if aids or result["power"] <= target * 1.05:
            break
    if not math.isfinite(best["power"]) or best["power"] < 1:
        raise ValueError("arena generated invalid enemy power")
    return best


def generate_opponents(cultivator, profile: dict, owner_uid: str, generation: int, player_rank: int,
                       own_power: int, power_fn, *, combat_signature: str) -> dict:
    if own_power < 1:
        raise ValueError("current arena team has no battle power")
    if type(generation) is not int or generation < 1:
        raise ValueError("arena generation must be positive")
    nonce = secrets.token_hex(16)
    rng = random.Random(int.from_bytes(hashlib.sha256(
        f"{owner_uid}:{generation}:{nonce}".encode()).digest(), "big"))
    owner_hex = hashlib.sha256(str(owner_uid).encode()).hexdigest()[:14]
    template = cultivator.template(profile)
    forms = cultivator.family_forms("appearance.arena_enemy")
    ranks = opponent_ranks(player_rank)
    names = sample_bot_names(rng, len(ranks))
    bots = []
    for index, rank in enumerate(ranks):
        # Lower rank numbers are stronger. Keep the generated UID and rank in
        # their original order; only the target strength descends down the list.
        ratio = .5 + .75 * (len(ranks) - 1 - index) / (len(ranks) - 1)
        target = max(1, round(own_power * ratio))
        # ItemPVP treats *any* UID containing 'r' as a configured robot and
        # replaces its compact roster with pvp_robot. Hex IDs use the supplied
        # compact snapshots instead, including skin heroes.
        bot_uid = f"n{owner_hex}_{generation}_{index}"
        seed = rng.getrandbits(48)
        built = fit_bot(cultivator, template, forms, rng, target, power_fn,
                        uid=bot_uid, name=names[index], seed=seed)
        units = built["units"]
        bots.append({"uid": bot_uid, "rank": rank, "name": names[index],
                     "lv": max(int(unit.get("lv", 1)) for unit in units),
                     "team": team_rows(units), "units": units, "power": built["power"],
                     "target_power": target, "bonds": built["bonds"],
                     "recipe": {"aids": built["aids"], "lines": built["lines"],
                                "progress": built["progress"], "seed": seed}})
    # Real cultivation moves in whole steps, so neighbouring targets can land
    # out of order. Stronger teams always take the better ranks.
    order = sorted(range(len(bots)), key=lambda i: -bots[i]["power"])
    ordered = [dict(bots[i]) for i in order]
    for slot, bot in enumerate(ordered):
        bot["rank"] = ranks[slot]
        bot["uid"] = f"n{owner_hex}_{generation}_{slot}"
    return {"generation": generation, "player_rank": player_rank, "nonce": nonce,
            "power_order_schema": POWER_ORDER_SCHEMA,
            "combat_config_sha256": combat_signature,
            "source_power": own_power, "template": template, "bots": ordered}
