"""Daily ordinary-orange recruitment and two explicitly offered skin souls."""
from __future__ import annotations

import hashlib
import random
import re

from gameplay_common import game_day
from upstream_hero_config import apply_upstream_hero_config


MEDAL_PRICE = 80
DAILY_CARD_COUNT = 20
SOUL_PRICE = 100
SOUL_COUNT = 40
SKIN_SOUL_IDS = ("A_1226_6", "A_1310_6")
_ORDINARY_ORANGE = re.compile(r"A_1[01]\d{2}_6\Z")


def daily_orange_pool(config):
    """Use authored playable heroes, never cosmetic, NPC, or placeholder rows."""
    cfg = config.get("cfg", config)
    avatar = cfg.get("avatar", {})
    blocked = set(cfg.get("system_simple", {}).get("skin_acquisition_blocked_heroes", []))
    if not isinstance(avatar, dict):
        raise ValueError("Avatar definitions are unavailable")
    pool = sorted(aid for aid, row in avatar.items()
                  if _ORDINARY_ORANGE.fullmatch(aid) and aid not in blocked
                  and isinstance(row, dict) and row.get("name")
                  and not str(row["name"]).startswith("橙阶"))
    if len(pool) < DAILY_CARD_COUNT:
        raise ValueError("Fewer than twenty ordinary orange heroes are configured")
    return pool


def daily_orange_list(config, now):
    """The same twenty distinct heroes appear for every player on a Shanghai day."""
    day = game_day(now)
    seed = int.from_bytes(hashlib.sha256(("recruit-medal:" + day).encode()).digest(), "big")
    return day, random.Random(seed).sample(daily_orange_pool(config), DAILY_CARD_COUNT)


def apply_recruit_exchange_config(document):
    """Offer the two authored skins; remove the rejected ordinary-Zhao-Xin fake."""
    apply_upstream_hero_config(document)
    cfg = document.get("cfg", document)
    avatar = cfg["avatar"]
    mistaken = avatar.get("A_1009_6")
    removed_fake = False
    if (isinstance(mistaken, dict) and mistaken.get("skin_exchange_only") is True
            and mistaken.get("name") == "二郎神赵信" and mistaken.get("res") == "A_1009_5"):
        del avatar["A_1009_6"]
        removed_fake = True
    erlang = avatar["A_1226_6"]
    if (erlang.get("name") != "二郎真君赵信"
            or erlang.get("pl", [])[10:12] != ["S_201226_6", "S_301226_6"]
            or erlang.get("pl", [None] * 14)[13] != "S_401226_6"):
        raise ValueError("Authored Erlang Zhao Xin definition is unavailable")
    avatar["A_1310_6"]["skin_exchange_only"] = True
    erlang["skin_exchange_only"] = True
    blocked = cfg["system_simple"].setdefault("skin_acquisition_blocked_heroes", [])
    if removed_fake or "A_1009_6" not in avatar:
        blocked[:] = [aid for aid in blocked if aid != "A_1009_6"]
    for aid in SKIN_SOUL_IDS:
        if aid not in blocked:
            blocked.append(aid)
    labels = cfg.setdefault("return_msg_config", {})
    labels.update({"20059": "普通召唤", "20068": "高级召唤"})
    for kind, info in (("score", "普通召唤使用友情积分。携带好友助战并获胜可获得友情积分。"),
                       ("coin", "高级召唤使用金砖，召唤奖励以当前奖池为准。")):
        for row in cfg.get("wager_festival", {}).get(kind, []):
            if isinstance(row, dict):
                row["info"] = info
    extract = cfg["ploy_system_simple"]["extract_avatar"]
    extract["exchange"] = [[{"avatar_soul": {aid: SOUL_COUNT}}, SOUL_PRICE]
                           for aid in SKIN_SOUL_IDS]
    cfg["recruit_exchange_overlay"] = {
        "schema": "recruit-exchange-v1", "medal_price": MEDAL_PRICE,
        "daily_count": DAILY_CARD_COUNT, "skin_souls": list(SKIN_SOUL_IDS),
        "soul_price": SOUL_PRICE, "soul_count": SOUL_COUNT,
    }
    return document
