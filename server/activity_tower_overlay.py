"""Publish native activity chapters and a 100-floor soul tower.

This operates on an isolated full-config document. Caller is responsible for
writing a reviewed candidate; no live config, database or player is touched.
"""
from __future__ import annotations

import argparse
import copy
import json
import math
from pathlib import Path

from battle_engine import serialize_stage_team
from campaign_workbook_overlay import _fit_power, _native_snapshot_power

TOWER_CHAPTER = "P_200"
MATERIALS = (
    ("hero_exp", "英雄经验", [1, 2, 4, 8]),
    ("gold", "L币", [20000, 60000, 180000, 500000]),
    ("dust", "洗练粉尘", [30, 60, 100, 160]),
    ("mark", "洗练印记", [15, 45, 135, 405]),
    ("enchant_book", "附魔书", [1, 2, 3, 5]),
    ("culture_book", "培养书", [3, 9, 27, 81]),
    ("talent", "天赋点", [3, 8, 18, 36]),
    ("dn_stone", "德诺石", [5, 15, 45, 135]),
)
LEVELS = ((4, 60), (5, 99), (6, 99), (6, 125))
# Six native un-geared representatives serialize at roughly 63k blue/204k
# purple/719k orange for the selected rosters. The final anchor follows the
# reviewed 3.35m full-gear orange-125 reference, rounded to 3.5m.
MATERIAL_POWER = (80000, 230000, 720000, 3500000)
TOWER_FIRST_POWER = 100000
TOWER_LAST_POWER = 2000000000
STAT_KEYS = ("hp", "ap", "de_ph", "de_ma")


def _chapter(cid, name, count, index):
    return {"id": cid, "name": name, "combat": count, "index": index,
            "ulv": 1, "start_time": {"$date": 1577836800},
            "end_time": {"$date": 2082758400}, "cycle": 1440,
            "duration": 1440, "state": 0, "status_activity": 2,
            "info": "常驻挑战，消耗10体力。"}


def _pool(cfg, star, skin=None):
    blocked = set(cfg.get("system_simple", {}).get("skin_acquisition_blocked_heroes", []))
    return sorted(aid for aid in cfg["avatar"]
                  if aid.startswith("A_1") and aid.rsplit("_", 1)[-1] == str(star)
                  and (skin is None or (aid in blocked) == skin))


def _team(cfg, star, level, seed, *, skin=False, advanced=False):
    pool = _pool(cfg, star, skin=skin)
    if len(pool) < 6:
        raise ValueError(f"need six configured star-{star} heroes for activity tier")
    start = seed % len(pool)
    aids = [pool[(start + i) % len(pool)] for i in range(6)]
    phase_rows = cfg.get("system_simple", {}).get("phase_config", [])
    max_phase = int(phase_rows[0][str(star)][1]) if advanced else 0
    rows = []
    for i, aid in enumerate(aids):
        row = [aid, level, 1, i // 2, .17 if i % 2 == 0 else .34,
               1 if i == 0 else 0, 0, 0, ""]
        if advanced:
            row += [None, None, None, None, 1, max_phase]
        rows.append(row)
    return rows


def _base_stats(cfg, team):
    units = serialize_stage_team(cfg, team, team=2)
    return [{"index": i, "aid": unit["aid"],
             **{key: max(1, int(unit[key])) for key in STAT_KEYS},
             **{key: int(unit["new_4attrs"].get(key, 0))
                for key in ("hit", "flee", "crit", "tough")}}
            for i, unit in enumerate(units)]


def _reward(kind, amount, tier):
    if kind == "hero_exp":
        return {"heroes": [{"aid": "A_6996_5", "num": amount}]}, None, "物理经验书"
    if kind == "gold":
        return {"gold": amount}, None, "L币"
    if kind == "dust":
        values = [0, 0, 0, 0]; values[tier] = amount
        return {"attrs": {"dust": values}}, None, "洗练粉尘"
    if kind == "mark":
        return {"mark": amount}, None, "洗练印记"
    if kind == "enchant_book":
        return {"items": [{"eid": f"E_650{tier + 1}_{tier + 2}", "num": amount}]}, None, "附魔书"
    if kind == "culture_book":
        return {"attrs": {"culture_book": amount}}, None, "培养书"
    if kind == "talent":
        colors = [0] * 6
        for i in range(1 if tier == 0 else 2 if tier == 1 else 4 if tier == 2 else 6):
            colors[i] = amount // (1 if tier == 0 else 2 if tier == 1 else 4 if tier == 2 else 6)
        return {"attrs": {"sp": colors}}, None, "天赋点"
    return {"attrs": {"dn_stone": amount}}, None, "德诺石"


def _stage(cid, name, team, stats, actual, *, reward=None, info="", extra=None):
    return {"id": cid, "name": name, "line": [3, ["m002", "m003", "m004"]],
            "team1": [], "team2": team, "ulv": 1, "win": [-1],
            "energy": 10, "exp": 0, "gold": int((reward or {}).get("gold", 0)),
            "limit": [2147483647], "pre": [], "new_4attrs": [0, 0, 0, 0],
            "equip_drop": [], "index": int(cid.rsplit("_", 1)[-1]),
            "indexID_s": int(cid.rsplit("_", 1)[-1]), "status_activity": 2,
            "reward": reward or {}, "info": info,
            "recommended_power": actual,
            "recommended_power_by_diff": {"0": actual},
            "enemy_unit_stats_by_diff": {"0": stats}, **(extra or {})}


def apply_activity_tower(full_config: dict) -> tuple[dict, dict]:
    """Generate eight material categories and one ordered, repeatable tower."""
    output = copy.deepcopy(full_config)
    cfg = output["cfg"]
    pve = output["pve"]
    exp_book = cfg.get("avatar", {}).get("A_6996_5", {})
    exp_tl = exp_book.get("tl", []) if isinstance(exp_book, dict) else []
    multipliers = cfg.get("system_simple", {}).get("provide_exp", [])
    if (len(exp_tl) <= 6 or int(exp_tl[6]) != 50000
            or not isinstance(multipliers, list) or len(multipliers) < 5
            or float(multipliers[4]) != 1):
        raise ValueError("configured A_6996_5 must remain a 50,000-XP feed card")
    for tier in range(4):
        eid = f"E_650{tier + 1}_{tier + 2}"
        book = cfg.get("equip", {}).get(eid)
        if not isinstance(book, dict) or int(book.get("type", 0)) != 6:
            raise ValueError(f"configured enchantment book is missing: {eid}")
    existing_chapters = pve.get("battle_ploy", {})
    existing_stages = pve.get("combat_ploy", {})
    if not isinstance(existing_chapters, dict) or not isinstance(existing_stages, dict):
        raise ValueError("existing native activity tables must be maps")
    previously_applied = pve.get("activities_overlay", {}).get("schema") == "materials-and-soul-tower-v1"
    chapters, stages = {}, {}
    report = {"material_categories": {}, "tower": {"floors": 100, "min_power": None, "max_power": None}}
    for chapter_index, (kind, title, amounts) in enumerate(MATERIALS, 1):
        chapter_id = f"P_{100 + chapter_index:03d}"
        chapters[chapter_id] = _chapter(chapter_id, title, 4, chapter_index)
        report["material_categories"][kind] = []
        for tier, ((star, level), target) in enumerate(zip(LEVELS, MATERIAL_POWER)):
            cid = f"{chapter_id}_{tier + 1}"
            team = _team(cfg, star, level, chapter_index * 7 + tier, advanced=tier == 3)
            stats, actual = _fit_power(cfg, team, _base_stats(cfg, team), target)
            reward, hero_exp, reward_name = _reward(kind, amounts[tier], tier)
            extra = {"activity_kind": "material", "material_kind": kind,
                     "material_tier": tier + 1}
            if hero_exp is not None:
                extra["activity_avatar_exp"] = hero_exp
            stage = _stage(cid, f"{title}·难度{tier + 1}", team, stats, actual,
                           reward=reward, info=f"胜利获得{reward_name}×{amounts[tier]}；四难度共享每日次数。",
                           extra=extra)
            stages[cid] = stage
            report["material_categories"][kind].append(actual)
    chapters[TOWER_CHAPTER] = _chapter(TOWER_CHAPTER, "百层英雄灵魂塔", 100, 99)
    for floor in range(1, 101):
        tier = (floor - 1) // 20
        star = (4, 5, 6, 6, 6)[tier]
        level = (60, 99, 99, 99, 125)[tier]
        skin = tier == 3
        team = _team(cfg, star, level, floor * 11,
                     skin=None if tier == 4 else skin, advanced=tier == 4)
        target = round(TOWER_FIRST_POWER *
                       math.exp(math.log(TOWER_LAST_POWER / TOWER_FIRST_POWER) * (floor - 1) / 99))
        stats, actual = _fit_power(cfg, team, _base_stats(cfg, team), target)
        cid = f"{TOWER_CHAPTER}_{floor}"
        candidates = _pool(cfg, star, skin=None if tier == 4 else tier == 3)
        if tier == 4:
            candidates = _pool(cfg, 6)
        stages[cid] = _stage(cid, f"灵魂塔·第{floor}层", team, stats, actual,
                             info="胜利随机获得本阶段一种英雄灵魂×120；逐层解锁，可重复挑战。",
                             extra={"activity_kind": "tower", "tower_floor": floor,
                                    "tower_tier": tier + 1, "soul_candidates": candidates,
                                    "soul_amount": 120})
        if floor == 1: report["tower"]["min_power"] = actual
        if floor == 100: report["tower"]["max_power"] = actual
    collisions = (set(chapters) & set(existing_chapters)) | (set(stages) & set(existing_stages))
    if collisions and not previously_applied:
        raise ValueError(f"new activity IDs collide with existing content: {sorted(collisions)[:5]}")
    # Existing workbook activity stages remain playable. Reapplying our own
    # schema refreshes only the IDs it owns and preserves all other chapters.
    pve["battle_ploy"] = {**existing_chapters, **chapters}
    pve["combat_ploy"] = {**existing_stages, **stages}
    pve["activities_overlay"] = {"schema": "materials-and-soul-tower-v1",
                                  "daily_attempts": "ceil(2+VIP/2) shared by material chapter",
                                  "energy": 10, "tower_ordered": True,
                                  "tower_soul_reward": 120}
    # Generated material/tower rosters use the same NPC level policy as a
    # feedback pass over an already published config.
    from pve_feedback_overlay import retune_campaign_tables, retune_tower_tables
    report["feedback_campaign"] = retune_campaign_tables(pve, cfg)
    report["feedback_tower"] = retune_tower_tables(pve, cfg)
    pve.setdefault("feedback_overlay", {})["schema"] = "lateral-stagger-and-npc-skills-v1"
    for table in ("battle_main", "combat_main", "battle_ploy", "combat_ploy"):
        output[table] = copy.deepcopy(pve[table])
        cfg[table] = copy.deepcopy(pve[table])
    report["chapters"] = len(pve["battle_ploy"])
    report["stages"] = len(pve["combat_ploy"])
    return output, report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    output, report = apply_activity_tower(json.loads(args.config.read_text(encoding="utf-8-sig")))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
