"""Hero challenges: an activity chapter of named-hero boss fights.

Chapter P_300 ("英雄挑战") lists every challenge. A challenge is a group of
difficulty stages that share one daily victory quota: BASE_ATTEMPTS per game
day plus one per VIP_STEP VIP levels. Wins consume the quota, losses do not.
A win rolls the group's hero card at the stage's chance. Helpers are allowed
(as on every activity stage); sweeps are refused.

Stage numbering inside P_300 is fixed per challenge, so a later challenge is
appended as stages 4..6 without renumbering saved stars.
"""
from __future__ import annotations

import copy

from gameplay_common import game_day
from player_store import GameplayFault

SCHEMA = "hero-challenge-106-v1"
CHAPTER_ID = "P_300"
CHAPTER_NAME = "英雄挑战"
KIND = "hero_challenge"
BASE_ATTEMPTS = 2
VIP_STEP = 3
BOSS_SHARE = 3  # Base-stat weight of the challenged hero before the team is fitted.

# Displayed recommended power, enemy stars/level/skill, and drop chance per tier.
CHALLENGES = (
    {"group": "demonblade_tryndamere", "boss": "A_1803_6", "reward": "A_1803_5",
     "title": "恶魔之刃泰达米尔", "first_stage": 1,
     "tiers": (
         {"label": "普通", "energy": 30, "power": 2_000_000, "chance_bp": 3000,
          "star": 5, "lv": 99, "slv": 7, "advanced": False},
         {"label": "困难", "energy": 50, "power": 50_000_000, "chance_bp": 6600,
          "star": 6, "lv": 99, "slv": 10, "advanced": False},
         {"label": "噩梦", "energy": 70, "power": 1_000_000_000, "chance_bp": 10000,
          "star": 6, "lv": 125, "slv": 10, "advanced": True},
     )},
)

# Lane and position of the six enemies; index 0 is the challenged captain.
FORMATION = ((1, .17), (1, .34), (0, .17), (0, .34), (2, .17), (2, .34))


def raw_power_for_display(display):
    """Inverse of power_balance_104.normalize_team_power."""
    from power_balance_104 import POWER_ANCHOR
    return round(POWER_ANCHOR * (display / POWER_ANCHOR) ** (4 / 3))


def _companions(cfg, boss, star, count, seed):
    from activity_tower_overlay import _pool
    pool = [aid for aid in _pool(cfg, star, skin=False) if aid.split("_")[1] != boss.split("_")[1]]
    warriors = [aid for aid in pool if cfg["avatar"][aid].get("role") == cfg["avatar"][boss].get("role")]
    pool = warriors if len(warriors) >= count else pool
    if len(pool) < count:
        raise ValueError(f"hero challenge needs {count} ordinary star-{star} companions")
    start = seed % len(pool)
    return [pool[(start + i) % len(pool)] for i in range(count)]


def _team(cfg, challenge, tier_index, tier):
    from pve_formation import stagger_lane_offsets
    aids = [challenge["boss"]] + _companions(cfg, challenge["boss"], tier["star"],
                                              len(FORMATION) - 1, 7 * tier_index + 3)
    phase = 0
    if tier["advanced"]:
        phase = int(cfg["system_simple"]["phase_config"][0][str(tier["star"])][1])
    team = []
    for index, (aid, (lane, pos)) in enumerate(zip(aids, FORMATION)):
        row = [aid, tier["lv"], tier["slv"], lane, pos, int(index == 0), 0, 0, ""]
        if tier["advanced"]:
            # Index 13/14 are the native NPC limit-break and full-phase markers.
            row += [None, None, None, None, 1, phase]
        team.append(row)
    stagger_lane_offsets(team)
    return team


def _info(challenge, tier):
    chance = tier["chance_bp"] / 100
    drop = ("必定获得" if tier["chance_bp"] >= 10000 else f"有{chance:g}%概率获得") + "一张紫色" + challenge["title"]
    return (f"挑战{challenge['title']}，敌方全灭后获胜。胜利{drop}。"
            f"{len(challenge['tiers'])}个难度共享每日{BASE_ATTEMPTS}次（VIP每{VIP_STEP}级+1次），"
            "胜利扣次数、失败不扣；可以助战，不能扫荡。")


def build_stages(cfg):
    from ancient_trial_overlay import _base_stats
    from campaign_workbook_overlay import _fit_power
    from power_balance_104 import POWER_SCHEMA
    stages = {}
    for challenge in CHALLENGES:
        for avatar in (challenge["boss"], challenge["reward"]):
            if avatar not in cfg["avatar"]:
                raise ValueError(f"hero challenge hero is not configured: {avatar}")
        for offset, tier in enumerate(challenge["tiers"]):
            number = challenge["first_stage"] + offset
            cid = f"{CHAPTER_ID}_{number}"
            team = _team(cfg, challenge, offset, tier)
            base = _base_stats(cfg, team)
            for key in ("hp", "ap", "de_ph", "de_ma"):
                base[0][key] *= BOSS_SHARE
            stats, actual = _fit_power(cfg, team, base, raw_power_for_display(tier["power"]))
            info = _info(challenge, tier)
            stages[cid] = {
                "id": cid, "name": f"{challenge['title']}·{tier['label']}",
                "line": [3, ["m002", "m003", "m004"]], "team1": [], "team2": team,
                "ulv": 1, "win": [-2], "energy": tier["energy"], "exp": 0, "gold": 0,
                "limit": [BASE_ATTEMPTS], "pre": [], "new_4attrs": [0, 0, 0, 0], "equip_drop": [],
                "index": number, "indexID_s": number, "status_activity": 0,
                "reward": {}, "info": info, "reward_note": info.split("。")[1] + "。",
                "recommended_power": tier["power"],
                "recommended_power_by_diff": {"0": tier["power"]},
                "recommended_power_original_104": {"0": actual},
                "recommendation_schema": POWER_SCHEMA,
                "enemy_snapshot_power": actual,
                "enemy_unit_stats_by_diff": {"0": stats},
                "activity_kind": KIND, "sweep_disabled": True,
                "hero_challenge": {"schema": SCHEMA, "group": challenge["group"], "tier": offset + 1,
                                   "aid": challenge["reward"], "chance_bp": tier["chance_bp"]},
            }
    return stages


def apply_hero_challenge(document):
    cfg = document.get("cfg", document)
    if cfg.get("hero_challenge", {}).get("schema") == SCHEMA:
        return document
    chapters, stages = copy.deepcopy(cfg["battle_ploy"]), copy.deepcopy(cfg["combat_ploy"])
    if CHAPTER_ID in chapters or any(cid.startswith(CHAPTER_ID + "_") for cid in stages):
        raise ValueError(f"{CHAPTER_ID} collides with existing activity content")
    template = chapters["P_200"]
    built = build_stages(cfg)
    chapters[CHAPTER_ID] = {
        "id": CHAPTER_ID, "name": CHAPTER_NAME, "combat": len(built), "index": 50, "ulv": 1,
        "start_time": copy.deepcopy(template["start_time"]), "end_time": copy.deepcopy(template["end_time"]),
        "cycle": 1440, "duration": 1440, "state": 0, "status_activity": 2,
        "info": f"挑战强大的英雄，胜利可能获得该英雄。每个挑战的各难度共享每日{BASE_ATTEMPTS}次（VIP每{VIP_STEP}级+1次）；可以助战，不能扫荡。",
    }
    stages.update(built)
    cfg.update(battle_ploy=chapters, combat_ploy=stages)
    cfg.setdefault("system_simple", {})["hero_challenge"] = {
        "base_attempts": BASE_ATTEMPTS, "vip_step": VIP_STEP, "consume": "victory"}
    cfg["hero_challenge"] = {"schema": SCHEMA, "chapter": CHAPTER_ID,
                             "groups": [challenge["group"] for challenge in CHALLENGES]}
    if "cfg" in document:
        for key in ("combat_ploy", "battle_ploy"):
            document[key] = cfg[key]
            if isinstance(document.get("pve"), dict):
                document["pve"][key] = cfg[key]
    return document


def _policy(stage):
    policy = stage.get("hero_challenge") if isinstance(stage, dict) else None
    if (stage.get("activity_kind") != KIND or not isinstance(policy, dict)
            or policy.get("schema") != SCHEMA or not isinstance(policy.get("group"), str)
            or not isinstance(policy.get("aid"), str)
            or type(policy.get("chance_bp")) is not int or not 0 <= policy["chance_bp"] <= 10000):
        raise GameplayFault("InvalidStage", "Hero challenge policy is missing")
    return policy


def daily_limit(profile):
    vip = profile.get("vip_lv", 0)
    vip = vip if type(vip) is int and vip > 0 else 0
    return BASE_ATTEMPTS + vip // VIP_STEP


def daily_state(profile, now):
    records = profile.setdefault("records", {})
    state = records.get("hero_challenge")
    today = game_day(now)
    if not isinstance(state, dict) or state.get("day") != today:
        state = {"day": today, "uses": {}}
        records["hero_challenge"] = state
    uses = state.get("uses")
    if not isinstance(uses, dict) or any(type(n) is not int or n < 0 for n in uses.values()):
        raise GameplayFault("InvalidProfile", "Malformed hero challenge counts")
    return state


def remaining(profile, stage, now):
    group = _policy(stage)["group"]
    return max(0, daily_limit(profile) - daily_state(profile, now)["uses"].get(group, 0))


def consume_win(profile, stage, now):
    if remaining(profile, stage, now) <= 0:
        raise GameplayFault("ActivityAttemptsExhausted", "今日该英雄挑战次数已用完。")
    uses = daily_state(profile, now)["uses"]
    group = _policy(stage)["group"]
    uses[group] = uses.get(group, 0) + 1


def roll_drop(config, stage, rng):
    """The hero card a win grants, or None. `stage` is the pending intent's copy."""
    policy = _policy(stage)
    cfg = config.get("cfg", config)
    if policy["aid"] not in cfg.get("avatar", {}):
        raise GameplayFault("InvalidStage", "Hero challenge reward hero is not configured")
    if policy["chance_bp"] >= 10000 or rng.randrange(10000) < policy["chance_bp"]:
        return policy["aid"]
    return None
