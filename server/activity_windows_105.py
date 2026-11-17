"""Keep authored activity windows open relative to the system clock.

The original activities shipped with fixed end dates (several in October 2027,
the rest in 2035/2036). A local single-player build must not silently close
them, so every open window's end is moved to at least one year after the time
the config is loaded. Start dates are kept: recharge campaigns reset their
progress whenever a window's start changes. Windows that never opened
(end at or before the Unix epoch) stay closed.
"""
from __future__ import annotations

import datetime

HORIZON_SECONDS = 365 * 86400


def _seconds(value):
    if isinstance(value, datetime.datetime):
        if value.tzinfo is None:
            value = value.replace(tzinfo=datetime.timezone.utc)
        return int(value.timestamp())
    if isinstance(value, dict) and set(value) == {"$date"}:
        return int(value["$date"])
    if type(value) in (int, float):
        return int(value)
    return None


def _like(original, seconds):
    """Return ``seconds`` in the same representation as ``original``."""
    if isinstance(original, datetime.datetime):
        return datetime.datetime.fromtimestamp(seconds, datetime.timezone.utc).replace(tzinfo=None)
    if isinstance(original, dict):
        return {"$date": seconds}
    return seconds


def _extend(row, now):
    if not isinstance(row, dict) or "end_time" not in row:
        return False
    end = _seconds(row["end_time"])
    if end is None or end <= 0:
        return False
    target = int(now) + HORIZON_SECONDS
    if end < target:
        row["end_time"] = _like(row["end_time"], target)
        return True
    return False


def _rows(document):
    cfg = document.get("cfg", document)
    roots = [cfg, document.get("pve", {}), document]
    for root in roots:
        for row in (root.get("battle_ploy") or {}).values() if isinstance(root, dict) else ():
            yield row
    for key in ("welfare", "roulette", "extract_avatar", "groupon"):
        yield cfg.get("ploy_system_simple", {}).get(key)
    for key in ("time_pay", "time_pay_loop"):
        yield cfg.get("task", {}).get(key)
    for rows in (cfg.get("wager_festival") or {}).values():
        for row in rows if isinstance(rows, list) else ():
            yield row


def apply_activity_windows_105(document, now):
    """Extend every open activity window to now + one year; returns the count."""
    return sum(1 for row in _rows(document) if _extend(row, now))
