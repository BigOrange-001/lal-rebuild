"""Monthly sign-in preview rows and the matching orange-card selection."""
from __future__ import annotations

import calendar
import hashlib


BASE_COIN = 2000
DAILY_COIN_STEP = 200
FIFTH_DAY_CARDS = 6


def check_in_coin(day):
    if type(day) is not int or day < 1 or day > 31:
        raise ValueError("Sign-in day must be from 1 to 31")
    return BASE_COIN + DAILY_COIN_STEP * (day - 1)


def orange_bonus_count(day):
    return FIFTH_DAY_CARDS if day % 5 == 0 else 0


def orange_pool(cfg):
    from recruit_exchange import daily_orange_pool
    return daily_orange_pool(cfg)


def random_orange_aid(cfg, uid, date):
    """A stable pseudorandom choice makes retries return the same hero."""
    pool = orange_pool(cfg)
    if not pool:
        raise ValueError("No eligible non-skin orange heroes are configured")
    digest = hashlib.sha256(f"check-in:{uid}:{date}".encode("utf-8")).digest()
    return pool[int.from_bytes(digest[:8], "big") % len(pool)]


def apply_check_in_rewards(document, year):
    """Idempotently update native preview rows for the game's current year."""
    if type(year) is not int or not 1 <= year <= 9999:
        raise ValueError("A valid calendar year is required")
    cfg = document.get("cfg", document)
    if not isinstance(cfg, dict):
        raise ValueError("Game config must be an object")
    source = cfg.get("check_in", {})
    if not isinstance(source, dict):
        raise ValueError("Sign-in config must be an object")
    updated = {}
    for month in range(1, 13):
        previous = source.get(str(month), source.get(month, []))
        if not isinstance(previous, list):
            raise ValueError("Sign-in month must be an array")
        rows = []
        for day in range(1, calendar.monthrange(year, month)[1] + 1):
            old = previous[day - 1] if day <= len(previous) and isinstance(previous[day - 1], dict) else {}
            row = dict(old)
            row["reward"] = {"coin": check_in_coin(day)}
            row["vip_double"] = old.get("vip_double", 1)
            row["bonus_orange_cards"] = orange_bonus_count(day)
            rows.append(row)
        updated[str(month)] = rows
    cfg["check_in"] = updated
    return document
