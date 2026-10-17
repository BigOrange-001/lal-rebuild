"""Rebuild the native P_001 ancient trial without changing other activities.

The generated enemy stat rows are the snapshots consumed by both the native
client and GameplayCombat at fight start. Optional equipment is described by
stage metadata and rolled only by the settlement helper, never by reward.items.
"""
from __future__ import annotations

import copy
import math
import re

from battle_engine import serialize_stage_team
from campaign_workbook_overlay import _fit_power
from gameplay_common import equipment_exclusive_ids
from pve_formation import stagger_lane_offsets


CHAPTER_ID = "P_001"
SCHEMA = "ancient-trial-v1"
CHANCES_BP = (4000, 5500, 7000, 8500, 3000, 4000, 5000, 6000, 7000, 2500)
QUALITIES = (4, 4, 4, 4, 5, 5, 5, 5, 5, 6)
HERO_STARS = (4, 4, 5, 5, 6, 6, 6, 6, 6, 6)
RARITIES = {4: "蓝色", 5: "紫色", 6: "橙色"}
EQUIPMENT_TYPES = {1, 3, 4, 5}


def target_power(tier: int) -> int:
    if not 1 <= tier <= 10:
        raise ValueError("ancient trial tier must be 1..10")
    if tier == 10:
        return 80_000_000
    return round(100_000 * math.exp(math.log(200) * (tier - 1) / 8))


def _equipment_pools(cfg: dict) -> dict[int, list[str]]:
    excluded = set(equipment_exclusive_ids(cfg))
    definitions = cfg.get("equip", {})
    pools = {
        quality: sorted(eid for eid, row in definitions.items()
                        if isinstance(row, dict) and row.get("quality") == quality
                        and row.get("type") in EQUIPMENT_TYPES
                        and re.fullmatch(rf"E_\d+_{quality}", eid)
                        and eid not in excluded)
        for quality in (4, 5, 6)
    }
    if any(not pool for pool in pools.values()):
        raise ValueError("ancient trial needs ordinary blue, purple and orange equipment")
    return pools


def _enemy_team(cfg: dict, tier: int) -> list[list]:
    star = HERO_STARS[tier - 1]
    blocked = set(cfg.get("system_simple", {}).get("skin_acquisition_blocked_heroes", []))
    candidates = sorted(aid for aid in cfg.get("avatar", {})
                        if aid.startswith("A_1") and aid.endswith(f"_{star}")
                        and aid not in blocked)
    if len(candidates) < 10:
        raise ValueError(f"ancient trial tier {tier} needs ten ordinary star-{star} heroes")
    start = (tier * 13) % len(candidates)
    selected = [candidates[(start + index) % len(candidates)] for index in range(10)]
    level = 60 if tier <= 2 else 99 if tier <= 8 else 125
    skill = 4 if tier <= 2 else 7 if tier <= 4 else 10
    max_phase = int(cfg["system_simple"]["phase_config"][0]["6"][1]) if tier >= 9 else 0
    positions = ((0, .46), (0, .34), (0, .22), (0, .10),
                 (1, .44), (1, .29), (1, .14),
                 (2, .44), (2, .29), (2, .14))
    team = []
    for index, (aid, (lane, pos)) in enumerate(zip(selected, positions)):
        row = [aid, level, skill, lane, pos, int(index == 0), 0, 0, ""]
        if tier >= 9:
            # Index 13/14 are the native NPC limit-break and full-phase markers.
            row += [None, None, None, None, 1, max_phase]
        team.append(row)
    stagger_lane_offsets(team)
    return team


def _base_stats(cfg: dict, team: list[list]) -> list[dict]:
    units = serialize_stage_team(cfg, team, team=2)
    return [{"index": index, "aid": unit["aid"],
             **{key: max(1, int(unit[key])) for key in ("hp", "ap", "de_ph", "de_ma")},
             **{key: int(unit["new_4attrs"].get(key, 0))
                for key in ("hit", "flee", "crit", "tough")}}
            for index, unit in enumerate(units)]


def apply_ancient_trial(full_config: dict) -> tuple[dict, dict]:
    """Return a reproducible ten-stage P_001 candidate and validation report."""
    output = copy.deepcopy(full_config)
    cfg = output["cfg"]
    pve = output["pve"]
    chapters, stages = pve["battle_ploy"], pve["combat_ploy"]
    chapter = chapters.get(CHAPTER_ID)
    if not isinstance(chapter, dict):
        raise ValueError("native ancient trial P_001 is missing")
    old_stages = {tier: copy.deepcopy(stages[f"{CHAPTER_ID}_{tier}"])
                  for tier in (1, 2, 3)}
    pools = _equipment_pools(cfg)
    chapter["combat"] = 10
    chapter["info"] = "常驻远古试炼，击败全部10名敌方英雄；胜利概率获得对应品质装备。"
    report = {"chapter": CHAPTER_ID, "tiers": [],
              "pools": {str(quality): len(pool) for quality, pool in pools.items()}}
    for tier in range(1, 11):
        cid = f"{CHAPTER_ID}_{tier}"
        quality = QUALITIES[tier - 1]
        chance_bp = CHANCES_BP[tier - 1]
        team = _enemy_team(cfg, tier)
        target = target_power(tier)
        stats, actual = _fit_power(cfg, team, _base_stats(cfg, team), target)
        old = old_stages.get(tier)
        if old:
            reward = copy.deepcopy(old.get("reward", {}))
            reward.pop("items", None)  # Old guaranteed gear would defeat the stated probability.
            gold, exp = int(old.get("gold", 0)), int(old.get("exp", 0))
        else:
            # No authored fourth-through-tenth base payout exists. Carry the
            # last native tier's currency/experience, not an invented jackpot.
            gold, exp = int(old_stages[3].get("gold", 0)), int(old_stages[3].get("exp", 0))
            reward = {"gold": gold}
        drop = {"schema": SCHEMA, "quality": quality,
                "chance_bp": chance_bp, "pool": list(pools[quality])}
        stage = {
            "id": cid, "name": f"远古试炼·第{tier}档", "line": [3, ["m002", "m003", "m004"]],
            "team1": [], "team2": team, "ulv": 1, "win": [-2],
            "energy": int(old.get("energy", 6)) if old else 6,
            "exp": exp, "gold": gold, "limit": [99, 99, 99], "pre": [],
            "new_4attrs": [0, 0, 0, 0], "equip_drop": [],
            "index": tier, "indexID_s": tier, "status_activity": 2,
            "reward": reward, "reward_note": f"胜利有{chance_bp / 100:g}%概率获得一件随机{RARITIES[quality]}装备。",
            "info": ("10名突破极限、满进阶橙色英雄；敌方全灭后获胜。"
                     if tier >= 9 else
                     f"10名{RARITIES[HERO_STARS[tier - 1]]}英雄；敌方全灭后获胜。"),
            "ancient_equip_drop": drop,
            "recommended_power": target, "recommended_power_by_diff": {"0": target},
            "enemy_snapshot_power": actual,
            "enemy_unit_stats_by_diff": {"0": stats},
        }
        stages[cid] = stage
        report["tiers"].append({"tier": tier, "target": target,
                                "actual": actual, "quality": quality,
                                "chance_bp": chance_bp})
    pve.setdefault("activities_overlay", {})["ancient_trial"] = SCHEMA
    # Native config and GameplayCombat resolve different aliases. Keep only
    # these two activity tables synchronized; all other PVE remains untouched.
    for table in ("battle_ploy", "combat_ploy"):
        cfg[table] = copy.deepcopy(pve[table])
        output[table] = copy.deepcopy(pve[table])
    return output, report
