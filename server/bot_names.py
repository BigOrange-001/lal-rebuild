"""Short, safe 2010s/2020s Chinese game nicknames for local NPCs."""
from __future__ import annotations

import hashlib
import random


_PREFIXES = (
    "冷少灬", "葬爱丨", "逆天丶", "孤城メ", "傲世丿", "寂夜丶",
    "夜影メ", "烈焰灬", "残月丨", "星陨丶", "孤狼メ", "暗夜灬",
    "霜刃丨", "苍穹丶", "天煞メ", "逐风灬", "无心丨", "流云丶",
    "绝尘メ", "修罗灬",
)
_SUFFIXES = (
    "独尊", "残梦", "狂少", "冷月", "无双", "孤影", "封神", "傲天",
    "夜行", "逐星", "战魂", "凌霄",
)
BOT_NAMES = tuple(prefix + suffix for prefix in _PREFIXES for suffix in _SUFFIXES)


def bot_name_for_uid(uid: str) -> str:
    """Choose once per local bot UID; previews and selection stay consistent."""
    digest = hashlib.sha256(str(uid).encode("utf-8")).digest()
    return BOT_NAMES[int.from_bytes(digest[:8], "big") % len(BOT_NAMES)]


def sample_bot_names(rng: random.Random, count: int) -> list[str]:
    """Choose distinct nicknames for one persisted arena batch."""
    if not 0 <= count <= len(BOT_NAMES):
        raise ValueError("invalid local bot name count")
    return rng.sample(BOT_NAMES, count)
