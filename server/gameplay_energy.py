"""Shared server-side interpretation of the native energy timestamp model.

The client stores current energy as elapsed five-minute intervals in the
``energy`` Date field. VIP raises the natural-energy cap; ``energy_extra`` is
only added once the natural meter has reached that cap.
"""
from __future__ import annotations

import math


def energy_parameters(profile, config):
    """Return the native max and interval using ``cfg.system_simple`` data."""
    config = config if isinstance(config, dict) else {}
    cfg_root = config.get("cfg") if isinstance(config.get("cfg"), dict) else config
    system = cfg_root.get("system_simple") or {}
    row = system.get("energy_config") or [100, 0, 5, 130]
    base = int(row[0]) if len(row) > 0 else 100
    per_level = float(row[1]) if len(row) > 1 else 0
    interval = max(1, int(row[2]) if len(row) > 2 else 5) * 60
    hard_cap = int(row[3]) if len(row) > 3 else base + math.floor(int(profile.get("lv", 1)) * per_level)
    vip = cfg_root.get("vip") or {}
    vip_row = vip.get(str(int(profile.get("vip_lv", 0))), {}) if int(profile.get("vip_lv", 0)) > 0 else {}
    vip_add = int(vip_row.get("energy_limit_add", 0)) if isinstance(vip_row, dict) else 0
    maximum = min(base + math.floor(int(profile.get("lv", 1)) * per_level) + vip_add, hard_cap)
    return max(0, maximum), interval


def energy_state(profile, config, now):
    """Return native ``max``, ``current``, ``extra`` and interval values."""
    maximum, interval = energy_parameters(profile, config)
    attrs = profile.get("attrs") if isinstance(profile.get("attrs"), dict) else {}
    extra = max(0, int(attrs.get("energy_extra", 0)))
    stamp_value = profile.get("energy", {})
    stamp = stamp_value.get("$date", now) if isinstance(stamp_value, dict) else stamp_value
    try:
        elapsed = max(0, int(now) - int(stamp))
    except (TypeError, ValueError, OverflowError):
        elapsed = 0
    intervals = elapsed // interval
    current = maximum + extra if intervals >= maximum else intervals
    return {"max": maximum, "current": current, "extra": extra,
            "interval": interval, "intervals": intervals}


def write_energy_after_spend(profile, remaining, state, now):
    """Persist a balance without double-counting the native overflow bucket."""
    remaining = max(0, int(remaining))
    maximum = int(state["max"])
    interval = int(state["interval"])
    attrs = profile.setdefault("attrs", {})
    extra = int(state["extra"])
    # Extra energy is active only after the natural meter is full. If it was
    # active, spend that overflow before leaving a partially full base meter.
    if int(state["intervals"]) >= maximum and extra > 0:
        attrs["energy_extra"] = max(0, remaining - maximum)
        elapsed_intervals = min(remaining, maximum)
    else:
        attrs["energy_extra"] = extra
        elapsed_intervals = min(remaining, maximum)
    profile["energy"] = {"$date": int(now) - elapsed_intervals * interval}
    return profile["energy"]
