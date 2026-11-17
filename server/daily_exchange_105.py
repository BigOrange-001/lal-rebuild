"""Daily rotating medal and points exchanges (refresh at the game-day boundary).

* Medal exchange: 10 orange and 10 purple equipment, drawn from every
  ordinary equipment piece of that quality (no skill books, no exclusive gear).
* Points exchange: 8 orange heroes, 6 from the permanent T2 skin list and 2
  ordinary orange heroes.

The same list is shown to every player on one game day (UTC+8 midnight).
"""
from __future__ import annotations

import hashlib
import random

from gameplay_common import game_day, equipment_exclusive_ids

MEDAL_EQUIPMENT = (("6", 10, 80), ("5", 10, 30))   # quality, count, medal price
EQUIPMENT_SLOTS = ("1", "3", "4", "5")              # weapon/armour slots; 6 = skill books
INTEGRAL_SKINS = (6, 300)                           # count, points
INTEGRAL_ORDINARY = (2, 200)


def _rng(kind, day):
    return random.Random(int.from_bytes(hashlib.sha256(f"{kind}:{day}".encode()).digest(), "big"))


def equipment_pool(config, quality):
    cfg = config.get("cfg", config)
    exclusive = equipment_exclusive_ids(cfg)
    return sorted(eid for eid in cfg.get("equip", {})
                  if eid.rsplit("_", 1)[-1] == quality and eid.split("_")[1][:1] in EQUIPMENT_SLOTS
                  and eid not in exclusive)


def daily_medal_offers(config, now):
    day = game_day(now)
    rng = _rng("medal-equipment", day)
    cfg = config.get("cfg", config)
    items = []
    for quality, count, price in MEDAL_EQUIPMENT:
        pool = equipment_pool(config, quality)
        if len(pool) < count:
            raise ValueError(f"Fewer than {count} quality-{quality} equipment pieces are configured")
        for eid in rng.sample(pool, count):
            items.append({"kind": "equip", "id": eid, "name": cfg["equip"][eid].get("name", eid),
                          "quality": int(quality), "medal": price})
    return day, items


def daily_integral_offers(config, now):
    from recruit_exchange import daily_orange_pool
    day = game_day(now)
    rng = _rng("points-orange", day)
    cfg = config.get("cfg", config)
    extract = cfg.get("ploy_system_simple", {}).get("extract_avatar", {})
    skins = [aid for aid in extract.get("permanent_exchange_hero_ids", []) if aid in cfg.get("avatar", {})]
    skin_count, skin_price = INTEGRAL_SKINS
    ordinary_count, ordinary_price = INTEGRAL_ORDINARY
    if len(skins) < skin_count:
        raise ValueError("Fewer than six permanent skin heroes are configured for the points exchange")
    rows = [[{"avatar": {aid: 1}}, skin_price] for aid in rng.sample(sorted(skins), skin_count)]
    ordinary = [aid for aid in daily_orange_pool(config) if aid not in skins]
    rows += [[{"avatar": {aid: 1}}, ordinary_price] for aid in rng.sample(ordinary, ordinary_count)]
    return day, rows
