"""Solo encounter generation and material conversion."""
from __future__ import annotations

import hashlib
import math
import random
import copy
from types import SimpleNamespace
from pve_formation import stagger_lane_offsets
from mod_policy import runtime as mod_runtime, candidate_ids, policy_signature, hero_available
from player_store import GameplayFault


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
    # The narrative workbook authors the first/current twelve-stage map. A
    # refresh increments map_revision and still generates a new seeded map.
    baseline = state.get("difficulty") if isinstance(state, dict) else None
    army = state.get("army") if isinstance(state, dict) else None
    roster = profile.get("avatars") if isinstance(profile, dict) else None
    if ((not isinstance(baseline, dict) or baseline.get("stat_schema") != "hero-only-all-captains-v2"
            or "team_power" not in baseline)
            and isinstance(army, dict) and army and isinstance(roster, dict)):
        selected = [iid for iid in army if iid in roster and hero_available(config, roster[iid].get("aid", iid))]
        if selected:
            state["difficulty"] = exploration_difficulty(profile, selected, config)
    if template.get("campaign_workbook_fixed") and int(state.get("map_revision", 0)) == 0:
        authored = copy.deepcopy(template)
        return _calibrate_exploration(config, state, stage, authored)
    cfg = config.get("cfg", config)
    families = cfg.get("system_simple", {}).get("solo_hero_families", [])
    if mod_runtime(config):
        families = list(dict.fromkeys(list(families) + [aid.rsplit("_", 1)[0]
                            for aid in candidate_ids(config, [], "appearance.exploration_enemy", include_new=True)]))
    avatars = cfg.get("avatar", {})
    seed = f'{profile.get("uid", "")}:explore:{state.get("map_revision", 0)}:{stage}'
    rng = random.Random(int.from_bytes(hashlib.sha256(seed.encode()).digest()[:8], "big"))
    baseline = state.get("difficulty") or {"level": max(1, min(99, int(profile.get("lv", 1)))), "star": 3}
    level = max(1, min(99, int(baseline["level"]) + (stage - 6) * 2))
    star = max(2, min(6, int(baseline["star"]) - (1 if stage <= 4 else 0)))
    candidates = []
    for family in families:
        members = [aid for aid in avatars if aid.rsplit("_", 1)[0] == family]
        if mod_runtime(config):
            members = candidate_ids(config, members, "appearance.exploration_enemy")
        if members:
            aid = min(members, key=lambda value: (abs(int(value.rsplit("_", 1)[-1]) - star), value))
            candidates.append(aid)
    rng.shuffle(candidates)
    selected = candidates[:3]
    if len(selected) < 3:
        if mod_runtime(config):
            raise GameplayFault("ModPoolEmpty", "探索随机敌人至少需要三个合法英雄家族")
        selected = [row[0] for row in template["team2"]][:3]
    team = [[aid, level, 4, 0, 0.08 + i * 0.12, int(i == 0)] for i, aid in enumerate(selected)]
    # Refreshed exploration maps are generated at runtime rather than read
    # from the published stage table. Apply the same per-lane placement policy
    # as authored PVE so all three enemies do not land on one side.
    stagger_lane_offsets(team)
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
    generated = {"id": stage, "line": [1, [rng.choice(backgrounds)]], "team2": team, "reward": reward}
    return _calibrate_exploration(config, state, stage, generated)


def _native_team_power(config: dict, units: list[dict]) -> int:
    from gameplay_competition import GameplayCompetition

    cfg = config.get("cfg", config)
    estimator = SimpleNamespace(cfg=cfg, simple=cfg.get("system_simple", {}))
    return GameplayCompetition._team_power(estimator, units)


def exploration_difficulty_from_team(config: dict, team: list[dict], fallback: dict | None = None) -> dict:
    """Freeze the three-hero native battle strength at map/army selection."""
    if not team or len(team) > 3:
        raise ValueError("exploration difficulty requires one to three serialized heroes")
    baseline = dict(fallback or {})
    baseline.setdefault("level", max(1, sum(int(unit.get("lv", 1)) for unit in team) // len(team)))
    baseline.setdefault("star", max(2, sum(int(str(unit.get("aid", "A_0_2")).split("|")[0].rsplit("_", 1)[-1])
                                         for unit in team) // len(team)))
    baseline["team_power"] = max(1, _native_team_power(config, team))
    baseline["stat_totals"] = {key: sum(max(0, int(unit.get(key, 0))) for unit in team)
                               for key in ("hp_max", "ap", "de_ph", "de_ma")}
    baseline["member_count"] = len(team)
    return baseline


def _calibrate_exploration(config: dict, state: dict, stage: int, encounter: dict) -> dict:
    """Scale actual enemy combat stats using the frozen player strength.

    Keep workbook rewards, encounter identity and hero/skill prototypes. The
    native fight and power preview both consume enemy_unit_stats_by_diff[0].
    """
    baseline = state.get("difficulty") if isinstance(state, dict) else None
    player_power = baseline.get("team_power") if isinstance(baseline, dict) else None
    if type(player_power) is not int or player_power < 1:
        return encounter
    cfg = config.get("cfg", config)
    from battle_engine import serialize_stage_team

    original = encounter.get("team2", [])
    if not isinstance(original, list) or not original:
        return encounter
    # Exploration fields one friendly lane with at most three heroes. Retain
    # the authored captain and a small set of seeded escorts so each stage is
    # an encounter rather than a seven-unit damage spike.
    if encounter.get("campaign_workbook_fixed"):
        count = 2 if stage <= 3 else 3 if stage <= 8 else 4
        digest = hashlib.sha256(f"{state.get('map_revision', 0)}:{stage}:escorts".encode()).digest()
        rng = random.Random(int.from_bytes(digest[:8], "big"))
        escort_indices = rng.sample(range(1, len(original)), min(count - 1, len(original) - 1))
        indices = [0] + sorted(escort_indices)
        encounter["team2"] = [copy.deepcopy(original[index]) for index in indices]
        stagger_lane_offsets(encounter["team2"])
    else:
        indices = list(range(len(original)))
    units = serialize_stage_team(cfg, encounter["team2"], team=2)
    authored = encounter.get("enemy_unit_stats_by_diff", {}).get("0", [])
    for local_index, (unit, source_index) in enumerate(zip(units, indices)):
        unit["line"] = 0
        if (isinstance(authored, list) and source_index < len(authored)
                and isinstance(authored[source_index], dict)):
            row = authored[source_index]
            for key in ("hp", "ap", "de_ph", "de_ma"):
                unit[key] = max(1, int(row.get(key, unit[key])))
            unit["hp_max"] = unit["hp"]
            unit["new_4attrs"] = {key: max(0, int(row.get(key, 0)))
                                   for key in ("hit", "flee", "crit", "tough")}
    primary = ("hp", "ap", "de_ph", "de_ma")
    totals = baseline.get("stat_totals", {})
    if not isinstance(totals, dict) or any(type(totals.get(key)) is not int or totals[key] < 1
                                           for key in ("hp_max", "ap", "de_ph", "de_ma")):
        return encounter
    friendly = max(1, min(3, int(baseline.get("member_count", 3))))
    progress = (max(1, min(12, stage)) - 1) / 11
    original_means = {key: sum(max(1, int(unit[key])) for unit in units) / len(units)
                      for key in primary}
    snapshots = copy.deepcopy(units)
    for unit, source in zip(snapshots, units):
        # Enemy HP grows gradually across the map; physical/magic resistance
        # stays below a medium player's attack, avoiding 30-round stalemates.
        # Attack stays near the player's defense so carrying HP matters while
        # two or three escorts cannot erase the army in one skill cycle.
        budget = {
            "hp": totals["hp_max"] * (0.28 + 0.14 * progress) / len(units),
            "ap": (totals["de_ph"] + totals["de_ma"]) / (2 * friendly) * (0.72 + 0.08 * progress),
            "de_ph": totals["ap"] / friendly * (0.16 + 0.04 * progress),
            "de_ma": totals["ap"] / friendly * (0.16 + 0.04 * progress),
        }
        for key in primary:
            variation = max(0.8, min(1.2, max(1, int(source[key])) / original_means[key]))
            unit[key] = max(1, int(budget[key] * variation))
        unit["hp_max"] = unit["hp"]
        unit["new_4attrs"] = {key: 0 for key in ("hit", "flee", "crit", "tough")}
    # Skills and talent can change native power without changing the four
    # visible primary totals. Normalize enemy HP within a narrow bound so the
    # frozen native power is part of the difficulty contract too.
    target = max(1, int(player_power * (0.09 + 0.02 * progress)))
    original_hp = [unit["hp"] for unit in snapshots]

    def with_health(factor):
        adjusted = copy.deepcopy(snapshots)
        for unit, hp in zip(adjusted, original_hp):
            unit["hp"] = unit["hp_max"] = max(1, int(hp * factor))
        return _native_team_power(config, adjusted), adjusted

    low, high = .65, 1.55
    best = min((with_health(low), with_health(high)), key=lambda item: abs(item[0] - target))
    for _ in range(18):
        middle = (low + high) / 2
        candidate = with_health(middle)
        if abs(candidate[0] - target) < abs(best[0] - target):
            best = candidate
        if candidate[0] < target:
            low = middle
        else:
            high = middle
    _, snapshots = best
    encounter["enemy_unit_stats_by_diff"] = {"0": [
        {"index": index, "aid": unit["aid"],
         **{key: int(unit[key]) for key in primary},
         **{key: int(unit["new_4attrs"].get(key, 0)) for key in ("hit", "flee", "crit", "tough")}}
        for index, unit in enumerate(snapshots)]}
    return encounter


def exploration_difficulty(profile: dict, selected: list[str], config: dict | None = None) -> dict:
    heroes = [profile["avatars"][iid] for iid in selected]
    strongest = sorted(heroes, key=lambda hero: (int(hero.get("lv", 1)), str(hero.get("aid", ""))), reverse=True)[:3]
    fallback = {"level": max(1, sum(int(hero.get("lv", 1)) for hero in strongest) // len(strongest)),
                "star": max(2, sum(int(str(hero.get("aid", "A_0_2")).split("|")[0].rsplit("_", 1)[-1]) for hero in strongest) // len(strongest))}
    if config is None:
        return fallback
    from battle_engine import base_unit
    from gameplay_roster import GameplayRosterEquipment

    cfg = config.get("cfg", config)
    attributes = GameplayRosterEquipment(None, config).battle_attributes
    ranked = []
    for iid in selected:
        hero = profile["avatars"][iid]
        raw = attributes(profile, iid, hero_only=True)
        aid = str(hero.get("aid", iid)).split("|")[0]
        ranked.append((_native_team_power(config, [{**raw, "new_4attrs":
                       {key: raw.get(key, 0) for key in ("hit", "flee", "crit", "tough")}}]),
                       iid, aid, hero, raw))
    ranked.sort(key=lambda row: (-row[0], row[1]))
    team = []
    for index, (_, iid, aid, hero, raw) in enumerate(ranked[:3]):
        overrides = {key: raw.get(key) for key in ("hp", "hp_max", "ap", "de_ph", "de_ma",
                     "tpl", "talent", "morph", "phase", "culture_schema", "growth_stats_applied", "skill",
                     "leader_skill", "book_skill", "skillB")}
        overrides["leader_skill"] = raw.get("leader_skill")
        overrides["new_4attrs"] = {key: raw.get(key, 0) for key in ("hit", "flee", "crit", "tough")}
        team.append(base_unit(cfg, aid, int(hero.get("lv", 1)), int(hero.get("slv", 1)),
                              0, .2 + .24 * index, True, 1, iid, overrides,
                              limit_break=hero.get("limit_break") == 1))
    result = exploration_difficulty_from_team(config, team, fallback)
    result["stat_schema"] = "hero-only-all-captains-v2"
    return result
