"""Daily nominal-yuan payment limits for local accounts."""
from __future__ import annotations

from game_calendar import game_day


TIERS = {
    "small": ("小氪", 648),
    "wealthy": ("富哥", 2000),
    "tycoon": ("大佬", 5000),
    "protagonist": ("系统文主角", 20000),
    "gm": ("GM", None),
}
ORDINARY_TIERS = frozenset(TIERS) - {"gm"}
LIMIT_MESSAGE = "今天没钱了 明天再来吧"


def valid_registration_tier(value):
    return type(value) is str and value in TIERS


def local_day(now):
    return game_day(now)


def initial_spending(tier, now):
    if not valid_registration_tier(tier):
        raise ValueError("Invalid spending tier")
    return {"tier": tier, "gm_eligible": tier == "gm", "day": local_day(now), "spent_yuan": 0}


def normalize_spending(profile, now):
    """Refresh the stored daily bucket while preserving the lifetime GM grant."""
    raw = profile.get("spending")
    raw = raw if isinstance(raw, dict) else {}
    gm = raw.get("gm_eligible") is True
    tier = raw.get("tier")
    if gm:
        tier = "gm"
    elif type(tier) is not str or tier not in ORDINARY_TIERS:
        tier = "small"
    day = local_day(now)
    spent = raw.get("spent_yuan", 0) if raw.get("day") == day else 0
    if type(spent) is not int or spent < 0:
        spent = 0
    label, limit = TIERS[tier]
    state = {
        "tier": tier,
        "label": label,
        "daily_limit_yuan": limit,
        "spent_yuan": spent,
        "remaining_yuan": None if limit is None else max(0, limit - spent),
        "is_gm": gm,
        "can_change": not gm,
        "gm_eligible": gm,
        "day": day,
    }
    profile["spending"] = state
    return state


def public_spending(profile, now):
    state = normalize_spending(profile, now)
    return {key: state[key] for key in (
        "tier", "label", "daily_limit_yuan", "spent_yuan", "remaining_yuan", "is_gm", "can_change"
    )}


def charge_spending(profile, yuan, now):
    if type(yuan) is not int or yuan <= 0:
        raise ValueError("Nominal payment must be positive whole yuan")
    state = normalize_spending(profile, now)
    limit = state["daily_limit_yuan"]
    if limit is not None and state["spent_yuan"] + yuan > limit:
        return False
    state["spent_yuan"] += yuan
    state["remaining_yuan"] = None if limit is None else limit - state["spent_yuan"]
    return True
