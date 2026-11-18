"""1.0.5 shop balance: recharge tiers, mystery shop tiers, lottery value and VIP packs.

Value anchors (daily free income from adventure tasks: ~11,500 coin,
1,300 culture books, 300 DN stones, 100 of each dust):

* orange hero ~ 10,000 coin (320 souls; advanced summon is ~12,500 per orange)
* purple hero ~ 2,000 coin (160 souls)
* orange equipment 5,000 / 8,000 coin (unchanged published prices)

Every price below is set against those anchors. Applied last in
``gateway.load_game_config`` so it sees the final hero and equipment tables.
"""
from __future__ import annotations

import copy
import re
import random

from hero_workshop import is_test_hero

SCHEMA = "shop-balance-105-v2"

# ---------------------------------------------------------------- recharge
# Coin amounts; the first number in pay_config is nominal yuan (coin / 10).
RECHARGE_TIERS = (20000, 50000, 100000)

# ---------------------------------------------------------- mystery shop
# Each tier draws six distinct rows by weight. Category weights are shares of
# the draw; rows inside a category share its weight evenly.
MYSTERY_TIERS = {
    "normal": (
        ("purple_soul", 20, ("coin", 300), 40),
        ("purple_equip", 1, ("coin", 1200), 22),
        ("purple_equip_soul", 20, ("coin", 250), 15),
        ("orange_soul", 10, ("coin", 450), 13),
        ("purple_equip_gold", 1, ("gold", 60), 6),
        ("orange_equip", 1, None, 4),
    ),
    "advanced": (
        ("orange_soul", 20, ("coin", 700), 30),
        ("purple_hero", 1, ("coin", 1800), 18),
        ("orange_equip_soul", 20, ("coin", 600), 14),
        ("orange_equip", 1, None, 28),
        ("purple_equip", 1, ("coin", 1000), 10),
    ),
    "super": (
        ("orange_hero", 1, ("coin", 9000), 16),
        ("orange_soul", 40, ("coin", 1300), 26),
        ("orange_equip", 1, None, 42),
        ("orange_equip_soul", 40, ("coin", 1100), 10),
        ("skin_soul", 40, ("coin", 1300), 6),
    ),
}

# --------------------------------------------------------------- lottery
ROULETTE_POOL = ({"coin": 30}, {"gold": 5}, {"coin": 60}, {"medal": 3},
                 {"coin": 100}, {"gold": 15}, {"coin": 300}, {"medal": 10})
ROULETTE_FIXED = {"1": {"coin": 200}, "5": {"gold": 30}, "10": {"coin": 1000}, "30": {"gold": 200}}
# [cost, payout]; row 0 is the display baseline. Each attempt now pays back more.
GAMBLE_LADDER = [[0, 0], [20, 30], [40, 65], [60, 100], [80, 140], [100, 200]]
# Advanced summon: guaranteed orange on the Nth draw without one.
ADVANCED_ORANGE_PITY = 60

# ------------------------------------------------------------- VIP packs
# Daily packs: only books and equipment grow their caps with VIP level;
# all remaining packs have two purchases per Shanghai day.
VIP_DAILY_PACKS = (
    {"id": "culture", "name": "经验书补给", "vip": 1, "price": 1000, "limit": 2,
     "limit_step":4, "max_limit":5, "reward": {"avatar":{"A_6998_5":50}}},
    {"id": "dust", "name": "粉尘补给", "vip": 3, "price": 1000, "limit": 2,
     "reward": {"attrs": {"dust": [400, 400, 400, 400]}}},
    {"id": "equipment", "name": "装备补给", "vip": 7, "price": 6666, "limit": 4,
     "limit_step":2, "max_limit":8, "reward": {"random_orange_equip": 1}},
    {"id": "hero", "name": "英雄补给", "vip": 9, "price": 8888, "limit": 2,
     "reward": {"random_orange_hero":1}},
    {"id": "stardust", "name": "星辉补给", "vip": 12, "price": 2000, "limit": 2,
     "reward": {"attrs": {"stardust": 1000}}},
    {"id": "supreme", "name": "至尊补给", "vip": 15, "price": 30000, "limit": 2,
     "reward": {"random_skin_orange":1}},
)
VIP_PACK_PRICES = (666,1888,2888,3888,4888,6666,8888,10000,11888,12666,
                   23333,26666,28888,32888,88888)
VIP_DAILY_COINS = (100,250,450,800,1100,1400,1800,2400,3000,4000,
                   5000,6500,8000,10000,15000)


def daily_limit(pack, vip_lv):
    if vip_lv < pack["vip"]:
        return 0
    step=pack.get('limit_step')
    extra=(vip_lv-pack['vip'])//step if step else 0
    return min(pack.get('max_limit',pack['limit']),pack['limit']+extra)


def _quality(aid):
    return aid.rsplit("_", 1)[-1]


def _pools(cfg):
    """Hero and equipment pools used by the shop and VIP packs."""
    calibration = cfg.get("summon_calibration", {}).get("pools", {})
    def cards(pool, quality):
        rows = calibration.get(pool, {}).get("qualities", {}).get(quality, {}).get("cards", [])
        return sorted(row["id"] for row in rows if row.get("weight", 0) > 0 and row["id"] in cfg["avatar"])
    exclusive = set(cfg.get("system_simple", {}).get("equipment_roll_policy", {}).get("exclusive_ids", []))
    original = cfg.get("mystery_shop_offers", {})
    orange_rows = []
    for row in original.get("super", []):
        item = row[0].get("equip") if isinstance(row[0], dict) else None
        if isinstance(item, dict) and len(item) == 1 and _quality(next(iter(item))) == "6":
            orange_rows.append(copy.deepcopy(row))
    orange_equip = sorted({next(iter(row[0]["equip"])) for row in orange_rows})
    purple_equip = sorted({eid.rsplit("_", 1)[0] + "_5" for eid in orange_equip
                           if eid.rsplit("_", 1)[0] + "_5" in cfg.get("equip", {})
                           and eid.rsplit("_", 1)[0] + "_5" not in exclusive})
    from recruit_exchange import SKIN_SOUL_IDS
    skins = list(cfg.get("recruit_exchange_overlay", {}).get("skin_souls", [])) or list(SKIN_SOUL_IDS)
    return {
        "purple": cards("advanced", "purple"),
        "orange": cards("advanced", "orange"),
        "orange_rows": orange_rows,
        "orange_equip_open": [eid for eid in orange_equip if eid not in exclusive],
        "purple_equip": purple_equip,
        "skins": [aid for aid in skins if aid in cfg["avatar"] and not is_test_hero(cfg, aid)],
    }


def _category_rows(name, amount, price, pools):
    if name == "orange_equip":
        # Published rows keep their exact 5,000 / 8,000 prices; the exclusive
        # equipment rule only accepts the original 8,000 rows.
        return copy.deepcopy(pools["orange_rows"])
    currency, cost = price
    pay = {currency: cost}
    if name in ("purple_soul", "orange_soul", "skin_soul"):
        # Skins have their own category, so they never appear twice in one sheet.
        orange = [aid for aid in pools["orange"] if aid not in pools["skins"]]
        ids = {"purple_soul": pools["purple"], "orange_soul": orange, "skin_soul": pools["skins"]}[name]
        return [[{"avatar_soul": {aid: amount}}, dict(pay)] for aid in ids]
    if name in ("purple_hero", "orange_hero"):
        ids = pools["purple"] if name == "purple_hero" else pools["orange"]
        return [[{"avatar": {aid: 1}}, dict(pay)] for aid in ids]
    if name in ("purple_equip", "purple_equip_gold"):
        return [[{"equip": {eid: 1}}, dict(pay)] for eid in pools["purple_equip"]]
    if name == "purple_equip_soul":
        return [[{"equip_soul": {eid: amount}}, dict(pay)] for eid in pools["purple_equip"]]
    if name == "orange_equip_soul":
        return [[{"equip_soul": {eid: amount}}, dict(pay)] for eid in pools["orange_equip_open"]]
    raise ValueError("Unknown mystery shop category: " + name)


def _mystery(cfg, pools):
    offers, weights = {}, {}
    for kind, categories in MYSTERY_TIERS.items():
        rows, row_weights = [], []
        for name, amount, price, share in categories:
            category = _category_rows(name, amount, price, pools)
            if not category:
                continue
            each = share / len(category)
            rows.extend(category)
            row_weights.extend([each] * len(category))
        offers[kind] = rows
        weights[kind] = [round(w, 6) for w in row_weights]
    cfg["mystery_shop_offers"] = offers
    cfg["mystery_shop_weights"] = weights


def _vip(cfg, pools):
    """Mail free milestones; publish concrete, deterministic paid rewards."""
    from recruit_exchange import daily_orange_pool
    from daily_exchange_105 import equipment_pool
    from gameplay_common import equipment_exclusive_ids
    heroes = daily_orange_pool(cfg,minimum=5)
    skins = sorted(aid for aid in cfg['system_simple'].get('skin_hero_ids',[])
                   if aid.endswith('_6') and aid in cfg['avatar'] and not is_test_hero(cfg, aid))
    ordinary_equips = equipment_pool(cfg,'6')
    exclusives = sorted(eid for eid in equipment_exclusive_ids(cfg) if eid.endswith('_6'))
    if len(skins)<5 or len(exclusives)<12 or not ordinary_equips:
        raise ValueError('VIP hero or equipment reward pools are incomplete')
    for level in range(1, 16):
        row = cfg.get("vip", {}).get(str(level))
        if not isinstance(row, dict):
            continue
        free = {"coin": 100 * level, "culture_book": 300 * level, "dn_stone": 50 * level, "gold": 10 * level}
        rng=random.Random(f'vip-paid-105-v2:{level}')
        hero_pool=heroes if level<=5 else skins
        count=1 if level<=10 else 2 if level<15 else 5
        paid={'avatar':{aid:1 for aid in rng.sample(hero_pool,count)}}
        if level>=6:
            equipment=ordinary_equips if level<=10 else exclusives
            paid['equip']={eid:1 for eid in rng.sample(equipment,12 if level==15 else 1)}
        price = VIP_PACK_PRICES[level-1]
        row['gift']=[{'coin':VIP_DAILY_COINS[level-1]}]
        row["gift_buy"] = {"pay": [price // 2], "data": free}
        row["gift_coin_buy"] = {"pay": [price * 3, price, 1], "data": paid}
        row["gift_buy_limit"] = 1
    cfg.setdefault("system_simple", {})["vip_daily_packs_105"] = [
        {**copy.deepcopy(pack)} for pack in VIP_DAILY_PACKS]
    cfg["system_simple"]["vip_daily_pack_pools_105"] = {
        "orange_equip": ordinary_equips, "orange_soul": pools["orange"],
        "ordinary_orange":heroes, "skin_orange":skins}
    cfg['system_simple']['vip_free_rewards_by_mail_105']=True


def _lottery(cfg):
    ploy = cfg.setdefault("ploy_system_simple", {})
    roulette = ploy.get("roulette")
    if isinstance(roulette, dict):
        roulette["pool"] = [dict(row) for row in ROULETTE_POOL]
        roulette["random_gift"] = {"6": [[dict(row)] for row in ROULETTE_POOL]}
        roulette["fixed_gift"] = copy.deepcopy(ROULETTE_FIXED)
    gamble = ploy.get("gamble")
    if isinstance(gamble, dict):
        gamble["return_coin"] = copy.deepcopy(GAMBLE_LADDER)
    cfg.setdefault("system_simple", {})["advanced_orange_pity_105"] = ADVANCED_ORANGE_PITY


def _recharge(cfg):
    pay = cfg.setdefault("pay_config", {})
    ordered = [pid for pid in pay if pid.startswith("local_")]
    cards = [pid for pid in pay if not pid.startswith("local_")]
    for coin in RECHARGE_TIERS:
        pid = f"local_{coin}"
        if pid not in ordered:
            pay[pid] = [coin // 10, 0, 0]
            ordered.append(pid)
    ordered.sort(key=lambda pid: int(re.sub(r"\D", "", pid)))
    for index, pid in enumerate(ordered + cards):
        pay[pid][2] = index


def apply_shop_balance_105(document):
    cfg = document.get("cfg", document)
    if cfg.get("shop_balance_schema") == SCHEMA:
        return document
    pools = _pools(cfg)
    _recharge(cfg)
    _mystery(cfg, pools)
    _lottery(cfg)
    _vip(cfg, pools)
    cfg["shop_balance_schema"] = SCHEMA
    return document
