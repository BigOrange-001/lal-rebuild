"""Solo encounter generation and material conversion."""
from __future__ import annotations

import hashlib
import math
import random


def arena_equipment(config: dict, bot: dict, units: list[dict]) -> list[dict]:
    level = max(0, min(200, int(bot.get("equipment_level", 0))))
    cfg = config.get("cfg", config)
    from gameplay_common import equipment_exclusive_ids
    from equipment_growth_v2 import growth
    excluded = equipment_exclusive_ids(config)
    candidates = {}
    for eid, item in cfg.get("equip", {}).items():
        if eid not in excluded and int(eid.rsplit("_", 1)[-1]) == 6 and int(item.get("type", 0)) in (1, 3, 4, 5):
            candidates.setdefault(int(item["type"]), []).append((eid, item))
    for index, unit in enumerate(units) if level else []:
        seed = f'{bot.get("uid")}:equipment:{index}'
        rng = random.Random(int.from_bytes(hashlib.sha256(seed.encode()).digest()[:8], "big"))
        for choices in candidates.values():
            _, item = rng.choice(sorted(choices))
            pl = item["pl"]
            rate = growth(level) * rng.uniform(0.95, 1.05)
            for field, position in (("hp", 0), ("ap", 1), ("de_ph", 2), ("de_ma", 3)):
                unit[field] += int(pl[position] * rate)
            for field in pl[6:8]:
                unit["new_4attrs"][field] += level * 6
        unit["hp_max"] = unit["hp"]
    desired = bot.get("target_power")
    if type(desired) is int and desired > 0:
        from gameplay_competition import GameplayCompetition
        from types import SimpleNamespace
        actual = GameplayCompetition._team_power(SimpleNamespace(cfg=cfg, simple=cfg.get("system_simple", {})), units)
        rate = math.sqrt(desired / max(1, actual))
        for unit in units:
            for field in ("hp", "ap", "de_ph", "de_ma"):
                unit[field] = max(1, int(unit[field] * rate))
            unit["hp_max"] = unit["hp"]
    return units


def expedition_stones(hero: dict) -> int:
    star = max(1, min(6, int(str(hero.get("aid", "A_0_1")).split("|")[0].rsplit("_", 1)[-1])))
    base = (2, 4, 10, 24, 65, 150)[star - 1]
    return base + base * max(0, min(98, int(hero.get("lv", 1)) - 1)) // 98


def exploration_encounter(config: dict, profile: dict, state: dict, stage: int, template: dict) -> dict:
    cfg = config.get("cfg", config)
    families = cfg.get("system_simple", {}).get("solo_hero_families", [])
    avatars = cfg.get("avatar", {})
    seed = f'{profile.get("uid", "")}:explore:{state.get("map_revision", 0)}:{stage}'
    rng = random.Random(int.from_bytes(hashlib.sha256(seed.encode()).digest()[:8], "big"))
    baseline = state.get("difficulty") or {"level": max(1, min(99, int(profile.get("lv", 1)))), "star": 3}
    level = max(1, min(99, int(baseline["level"]) + (stage - 6) * 2))
    star = max(2, min(6, int(baseline["star"]) - (1 if stage <= 4 else 0)))
    candidates = []
    for family in families:
        members = [aid for aid in avatars if aid.rsplit("_", 1)[0] == family]
        if members:
            aid = min(members, key=lambda value: (abs(int(value.rsplit("_", 1)[-1]) - star), value))
            candidates.append(aid)
    rng.shuffle(candidates)
    selected = candidates[:3]
    if len(selected) < 3:
        selected = [row[0] for row in template["team2"]][:3]
    team = [[aid, level, min(10, 1 + stage // 3), 0, 0.08 + i * 0.12, int(i == 0)] for i, aid in enumerate(selected)]
    reward = {"gold": 12000 + stage * 4000, "exp": 60 + stage * 12,
              "attrs": {"dn_stone": 20 + stage * 10, "culture_book": 1 if stage % 3 == 0 else 0,
                        "dust": [int(stage % 4 == i) for i in range(4)]}}
    if stage % 3 == 0:
        reward["heroes"] = [{"aid": "A_6996_5", "num": 1 if stage < 12 else 2}]
    if stage in (6, 12):
        reward["coin"] = 25 if stage == 6 else 50
    if stage % 4 == 0:
        from gameplay_common import equipment_exclusive_ids
        excluded = equipment_exclusive_ids(config)
        equipment = [eid for eid, row in cfg.get("equip", {}).items()
                     if eid not in excluded and int(row.get("type", 0)) in (1, 3, 4, 5)
                     and int(eid.rsplit("_", 1)[-1]) == min(5, max(2, star))]
        if equipment:
            reward["items"] = [{"eid": rng.choice(sorted(equipment)), "num": 1}]
    backgrounds = cfg.get("system_simple", {}).get("explore", {}).get("line", [1, ["m002"]])[1]
    return {"id": stage, "line": [1, [rng.choice(backgrounds)]], "team2": team, "reward": reward}


def exploration_difficulty(profile: dict, selected: list[str]) -> dict:
    heroes = [profile["avatars"][iid] for iid in selected]
    strongest = sorted(heroes, key=lambda hero: (int(hero.get("lv", 1)), str(hero.get("aid", ""))), reverse=True)[:3]
    return {"level": max(1, sum(int(hero.get("lv", 1)) for hero in strongest) // len(strongest)),
            "star": max(2, sum(int(str(hero.get("aid", "A_0_2")).split("|")[0].rsplit("_", 1)[-1]) for hero in strongest) // len(strongest))}
