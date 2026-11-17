"""Daily rotating medal and points exchanges (refresh at the game-day boundary).

* Medal exchange: 10 orange and 10 purple equipment, drawn from every
  ordinary equipment piece of that quality (no skill books, no exclusive gear).
  A separate hero tab offers 2 eligible orange skins and 8 ordinary oranges.
* Points exchange: 8 orange heroes, 6 from the permanent T2 skin list and 2
  ordinary orange heroes.

The same list is shown to every player on one game day (UTC+8 midnight).
"""
from __future__ import annotations

import hashlib
import random

from gameplay_common import game_day, equipment_exclusive_ids
from mod_policy import candidate_ids

MEDAL_EQUIPMENT = (("6", 10, 80), ("5", 10, 30))   # quality, count, medal price
EQUIPMENT_SLOTS = ("1", "3", "4", "5")              # weapon/armour slots; 6 = skill books
INTEGRAL_SKINS = (6, 300)                           # count, points
INTEGRAL_ORDINARY = (2, 200)
MEDAL_HERO_SKINS = 2
MEDAL_HERO_ORDINARY = 8


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
    channel = "acquisition.exchange.activity"
    skins = candidate_ids(config, extract.get("permanent_exchange_hero_ids", []), channel)
    skin_count, skin_price = INTEGRAL_SKINS
    ordinary_count, ordinary_price = INTEGRAL_ORDINARY
    if len(skins) < skin_count:
        raise ValueError("Fewer than six permanent skin heroes are configured for the points exchange")
    rows = [[{"avatar": {aid: 1}}, skin_price] for aid in rng.sample(sorted(skins), skin_count)]
    ordinary = [aid for aid in daily_orange_pool(config, channel=channel, minimum=ordinary_count)
                if aid not in skins]
    rows += [[{"avatar": {aid: 1}}, ordinary_price] for aid in rng.sample(ordinary, ordinary_count)]
    return day, rows


def daily_medal_hero_offers(config, now):
    """Two eligible skin oranges and eight ordinary oranges per Shanghai day."""
    from recruit_exchange import daily_orange_pool, MEDAL_PRICE
    cfg = config.get('cfg', config)
    day = game_day(now)
    rng = _rng('medal-heroes', day)
    channel = 'acquisition.exchange.hero'
    skins = candidate_ids(config, cfg.get('ploy_system_simple', {}).get('extract_avatar', {})
                          .get('permanent_exchange_hero_ids', []), channel)
    skins = sorted({aid for aid in skins if aid in cfg.get('avatar', {}) and aid.endswith('_6')})
    # Save-local policies can leave a smaller pool. Offer every eligible hero
    # up to each daily limit, without duplicates or borrowing disabled heroes.
    ordinary = daily_orange_pool(config, channel=channel, minimum=0)
    selected = rng.sample(skins, min(len(skins), MEDAL_HERO_SKINS)) + rng.sample(ordinary, min(len(ordinary), MEDAL_HERO_ORDINARY))
    return day, [{'kind':'avatar', 'id':aid, 'name':cfg['avatar'][aid]['name'],
                  'quality':6, 'medal':MEDAL_PRICE} for aid in selected]
