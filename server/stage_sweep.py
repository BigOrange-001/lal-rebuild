"""Daily stage sweeps: settle a three-star stage without fighting.

Every player has FREE_SWEEPS free sweeps per game day plus VIP_BONUS per VIP
level. Past the free quota each sweep costs EXTRA_COST gold bricks, without a
daily cap. A sweep still spends the stage's energy and challenge attempts and
grants the same rewards as a three-star win (never first-clear bonuses).
"""
from __future__ import annotations

from gameplay_common import game_day
from player_store import GameplayFault

FREE_SWEEPS = 20
VIP_BONUS = 5
EXTRA_COST = 20
REQUIRED_STARS = 3
MAX_TIMES = 100


def fault(code, message):
    """A fault whose Chinese message reaches the player as written."""
    error = GameplayFault(code, message)
    error.detail = True
    return error


def daily_state(profile, now):
    records = profile.setdefault("records", {})
    state = records.get("stage_sweep")
    today = game_day(now)
    if not isinstance(state, dict) or state.get("day") != today:
        state = {"day": today, "used": 0, "paid": 0}
        records["stage_sweep"] = state
    for key in ("used", "paid"):
        if type(state.get(key)) is not int or state[key] < 0:
            raise GameplayFault("InvalidProfile", "Malformed stage sweep counts")
    return state


def free_limit(profile):
    vip = profile.get("vip_lv", 0)
    vip = vip if type(vip) is int and vip > 0 else 0
    return FREE_SWEEPS + VIP_BONUS * vip


def quote(profile, now, times):
    """Free and paid parts of `times` sweeps today, and their gold-brick cost."""
    state = daily_state(profile, now)
    free_left = max(0, free_limit(profile) - state["used"])
    free = min(times, free_left)
    paid = times - free
    return {"free_limit": free_limit(profile), "used": state["used"], "free_left": free_left,
            "free": free, "paid": paid, "coin_cost": paid * EXTRA_COST, "price": EXTRA_COST}


def record(profile, now, times, paid):
    state = daily_state(profile, now)
    state["used"] += times
    state["paid"] += paid
    return state


def apply_stage_sweep(document):
    cfg = document.get("cfg", document)
    cfg.setdefault("system_simple", {})["stage_sweep"] = {
        "free": FREE_SWEEPS, "vip_bonus": VIP_BONUS, "extra_cost": EXTRA_COST,
        "stars": REQUIRED_STARS, "max_times": MAX_TIMES,
    }
    return document
