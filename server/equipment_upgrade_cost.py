"""Integer equipment-upgrade costs shared by native previews and the server."""
from __future__ import annotations

import math

MAX_EQUIPMENT_LEVEL = 200
_EXPONENT = math.log(100_000 / 9) / math.log(100)


def cost_table():
    """Index is the level before a paid attempt; level 200 cannot upgrade."""
    values = [0]
    values.extend(max(1, round(9 * level ** _EXPONENT))
                  for level in range(1, MAX_EQUIPMENT_LEVEL))
    values.append(0)
    values[1] = 9
    values[100] = 100_000
    return values


def apply_equipment_upgrade_config(document):
    cfg = document.get("cfg", document)
    simple = cfg.get("system_simple") if isinstance(cfg, dict) else None
    vip = cfg.get("vip") if isinstance(cfg, dict) else None
    if not isinstance(simple, dict) or not isinstance(vip, dict):
        raise ValueError("Equipment upgrade configuration is incomplete")
    simple["equip_rise_cost"] = cost_table()
    simple["equip_wash_mark_cost"] = 1000
    for key, row in vip.items():
        if isinstance(row, dict) and str(key).isdecimal():
            row["equip_lvmax"] = 3 * int(key)
    return document
