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

# The four existing material chapters keep their chapter IDs. This separate
# pass updates their rewards and adds a fifth tier without rebuilding the
# published soul tower or any authored campaign stages.
RESOURCE_AMOUNTS = {
    "hero_exp": (5, 10, 15, 20, 40),
    "gold": (100000, 500000, 1000000, 3000000, 6000000),
    "dust": (30, 60, 100, 160, 320),
    "mark": (30, 90, 160, 270, 540),
    "enchant_book": (1, 2, 3, 5, 10),
    "culture_book": (6, 12, 20, 30, 60),
    "talent": (3, 8, 18, 36, 72),
    "dn_stone": (10, 25, 50, 80, 160),
}
RESOURCE_POWER = (100000, 1000000, 10000000, 30000000, 70000000)
RESOURCE_LEVELS = ((4, 60), (5, 99), (6, 99), (6, 125), (6, 125))
SKILL_BISCUIT_AMOUNTS = (4, 8, 12, 20)
RESOURCE_OVERHAUL_SCHEMA = "resources-and-shop-v2"
TOWER_OVERHAUL_FLOORS = 150
TOWER_OVERHAUL_FIRST_POWER = 10000
TOWER_OVERHAUL_LAST_POWER = 10000000000


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


def apply_resource_overhaul(full_config: dict) -> tuple[dict, dict]:
    """Return an isolated resource/activity and mystery-shop candidate.

    The biscuit card is named by ``system_simple.skill_biscuit_avatar_id``;
    callers must configure its actual AvatarData skill experience before this
    pass. The card ID is never inferred from its display name.
    """
    output = copy.deepcopy(full_config)
    cfg, pve = output["cfg"], output["pve"]
    simple = cfg["system_simple"]
    biscuit_id = simple.get("skill_biscuit_avatar_id")
    biscuit = cfg.get("avatar", {}).get(biscuit_id) if isinstance(biscuit_id, str) else None
    if (not isinstance(biscuit, dict) or not isinstance(biscuit.get("skillup"), (int, float))
            or biscuit["skillup"] <= 0):
        raise ValueError("configured skill biscuit avatar and positive skillup are required")
    chapters, stages = pve["battle_ploy"], pve["combat_ploy"]
    if not isinstance(chapters, dict) or not isinstance(stages, dict):
        raise ValueError("native activity tables must be maps")
    if "P_109" in chapters and pve.get("activities_overlay", {}).get("schema") != RESOURCE_OVERHAUL_SCHEMA:
        raise ValueError("P_109 collides with existing activity content")
    from pve_formation import stagger_lane_offsets

    report = {"material_categories": {}, "skill_biscuit": [], "shop_orange_offers": {},
              "tower": {"floors": TOWER_OVERHAUL_FLOORS, "min_power": None, "max_power": None}}
    for chapter_index, (kind, title, _) in enumerate(MATERIALS, 1):
        chapter_id = f"P_{100 + chapter_index:03d}"
        if chapter_id not in chapters or any(f"{chapter_id}_{tier}" not in stages for tier in range(1, 5)):
            raise ValueError(f"published material chapter is incomplete: {chapter_id}")
        chapters[chapter_id]["combat"] = 5
        amounts = RESOURCE_AMOUNTS[kind]
        report["material_categories"][kind] = []
        for tier, ((star, level), target, amount) in enumerate(zip(RESOURCE_LEVELS, RESOURCE_POWER, amounts)):
            team = _team(cfg, star, level, chapter_index * 7 + tier, advanced=tier >= 3)
            for row in team:
                row[2] = 4
            stagger_lane_offsets(team)
            stats, actual = _fit_power(cfg, team, _base_stats(cfg, team), target)
            # The fifth stage uses twice the fourth stage's highest native
            # enchantment book, dust color and talent colors.
            reward, _, reward_name = _reward(kind, amount, min(tier, 3))
            cid = f"{chapter_id}_{tier + 1}"
            stages[cid] = _stage(cid, f"{title}·难度{tier + 1}", team, stats, actual,
                                 reward=reward,
                                 info=f"胜利获得{reward_name}×{amount}；五难度共享每日次数。",
                                 extra={"activity_kind": "material", "material_kind": kind,
                                        "material_tier": tier + 1})
            report["material_categories"][kind].append(actual)

    biscuit_chapter = "P_109"
    chapters[biscuit_chapter] = _chapter(biscuit_chapter, "技能饼干", 4, 9)
    chapters[biscuit_chapter]["info"] = "常驻挑战，消耗10体力，挑战次数不限。"
    for tier, amount in enumerate(SKILL_BISCUIT_AMOUNTS):
        star, level = RESOURCE_LEVELS[tier]
        team = _team(cfg, star, level, 9 * 7 + tier, advanced=tier == 3)
        for row in team:
            row[2] = 4
        stagger_lane_offsets(team)
        stats, actual = _fit_power(cfg, team, _base_stats(cfg, team), RESOURCE_POWER[tier])
        cid = f"{biscuit_chapter}_{tier + 1}"
        stages[cid] = _stage(cid, f"技能饼干·难度{tier + 1}", team, stats, actual,
                             reward={"heroes": [{"aid": biscuit_id, "num": amount}]},
                             info=f"胜利获得技能饼干×{amount}；挑战次数不限。",
                             extra={"activity_kind": "material", "material_kind": "skill_biscuit",
                                    "material_tier": tier + 1, "unlimited_attempts": True})
        report["skill_biscuit"].append(actual)

    if TOWER_CHAPTER not in chapters or any(f"{TOWER_CHAPTER}_{floor}" not in stages
                                             for floor in range(1, 101)):
        raise ValueError("published soul tower is incomplete")
    chapters[TOWER_CHAPTER]["name"] = "灵魂之塔"
    chapters[TOWER_CHAPTER]["combat"] = TOWER_OVERHAUL_FLOORS
    tower_gift = cfg.get("pass_battle_gift", {}).get("-1", {}).get(TOWER_CHAPTER)
    if not isinstance(tower_gift, dict):
        raise ValueError("tower completion gift is not configured")
    tower_gift["need_star"] = TOWER_OVERHAUL_FLOORS * 3
    output["pass_battle_gift"] = copy.deepcopy(cfg["pass_battle_gift"])
    if "pass_battle_gift" in pve:
        pve["pass_battle_gift"] = copy.deepcopy(cfg["pass_battle_gift"])
    orange_heroes = _pool(cfg, 6)
    if not orange_heroes:
        raise ValueError("orange hero pool is empty")
    for floor in range(1, TOWER_OVERHAUL_FLOORS + 1):
        cid = f"{TOWER_CHAPTER}_{floor}"
        target = round(TOWER_OVERHAUL_FIRST_POWER * math.exp(
            math.log(TOWER_OVERHAUL_LAST_POWER / TOWER_OVERHAUL_FIRST_POWER)
            * (floor - 1) / (TOWER_OVERHAUL_FLOORS - 1)))
        if floor <= 100:
            stage = stages[cid]
            team = stage["team2"]
            # The hero catalogue and skin blocklist can change after the
            # original 100-floor table was published. Refresh its reward
            # candidates too, preserving each floor band's authored tier.
            tier = (floor - 1) // 20
            candidates = _pool(cfg, (4, 5, 6, 6, 6)[tier],
                               skin=None if tier == 4 else tier == 3)
            if not candidates:
                raise ValueError(f"soul tower floor {floor} has no eligible heroes")
            stage["soul_candidates"] = candidates
        else:
            team = _team(cfg, 6, 125, floor * 11, advanced=True)
            for row in team:
                row[2] = 10
            stagger_lane_offsets(team)
        stats, actual = _fit_power(cfg, team, _base_stats(cfg, team), target)
        if floor <= 100:
            stage["enemy_unit_stats_by_diff"] = {"0": stats}
            stage["recommended_power"] = actual
            stage["recommended_power_by_diff"] = {"0": actual}
        else:
            stage = _stage(cid, f"灵魂塔·第{floor}层", team, stats, actual,
                           info="胜利随机获得一种橙色英雄灵魂×120及一名橙色英雄；逐层解锁，可重复挑战。",
                           extra={"activity_kind": "tower", "tower_floor": floor,
                                  "tower_tier": 6, "soul_candidates": orange_heroes,
                                  "soul_amount": 120,
                                  "tower_hero_candidates": orange_heroes,
                                  "tower_hero_amount": 1,
                                  "tower_allow_skin": True})
            stages[cid] = stage
        # Native [-2] requires every living enemy across all lanes to fall;
        # [-1] would end the tower fight after winning only two lanes.
        stage["win"] = [-2]
        if floor == 1:
            report["tower"]["min_power"] = actual
        if floor == TOWER_OVERHAUL_FLOORS:
            report["tower"]["max_power"] = actual

    offers_by_type = cfg.get("mystery_shop_offers")
    if not isinstance(offers_by_type, dict):
        raise ValueError("mystery shop offers must be configured")
    exclusive_ids = set(simple.get("equipment_roll_policy", {}).get("exclusive_ids", []))
    orange_ids = sorted(eid for eid, definition in cfg.get("equip", {}).items()
                        if eid.endswith("_6") and isinstance(definition, dict)
                        and int(definition.get("type", 0)) != 6)
    if not orange_ids or not (set(orange_ids) & exclusive_ids):
        raise ValueError("ordinary and exclusive orange equipment must be configured")
    orange_set = set(orange_ids)
    for kind in ("normal", "advanced", "super"):
        if kind not in cfg.get("mystery_shop", {}) or not isinstance(offers_by_type.get(kind), list):
            raise ValueError(f"mystery shop type is missing: {kind}")
        existing = offers_by_type[kind]
        # Replace existing full orange offers at the new coin price. Existing
        # souls, lower-quality items and other stock retain their authored rows.
        kept = [row for row in existing if not (isinstance(row, list) and row
                and isinstance(row[0], dict) and isinstance(row[0].get("equip"), dict)
                and set(row[0]["equip"]) <= orange_set)]
        orange_offers = [[{"equip": {eid: 1}},
                          {"coin": 8000 if eid in exclusive_ids else 5000}]
                         for eid in orange_ids]
        offers_by_type[kind] = kept + orange_offers
        report["shop_orange_offers"][kind] = len(orange_offers)

    pve["activities_overlay"] = {
        **pve.get("activities_overlay", {}), "schema": RESOURCE_OVERHAUL_SCHEMA,
        "daily_attempts": "ceil(2+VIP/2) shared by each material chapter except skill biscuit",
        "skill_biscuit_unlimited": True,
        "tower_floors": TOWER_OVERHAUL_FLOORS,
        "tower_hero_from_floor": 101,
    }
    for table in ("battle_ploy", "combat_ploy"):
        output[table] = copy.deepcopy(pve[table])
        cfg[table] = copy.deepcopy(pve[table])
    report["chapters"] = len(chapters)
    report["stages"] = len(stages)
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
