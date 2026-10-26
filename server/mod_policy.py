"""Pure policy adapters for one save's compiled Mod configuration.

The compiler owns identity and channel precedence. Gameplay consumes only its
resolved metadata; no helper mutates shared configuration or stored assets.
"""
from __future__ import annotations

import copy
import hashlib
import json

from player_store import GameplayFault


CHANNELS = {
    "appearance.arena_enemy": "竞技场敌人",
    "acquisition.summon.normal": "普通召唤",
    "acquisition.summon.advanced": "高级召唤",
    "acquisition.shop.hero_soul": "英雄碎片商店",
    "appearance.fragment_enemy": "掠夺敌人",
    "appearance.exploration_enemy": "探索随机敌人",
    "appearance.expedition_enemy": "远征随机敌人",
    "appearance.campaign_random_enemy": "主线随机敌人",
    "appearance.assist_bot": "机器人助战",
    "acquisition.summon.activity": "活动抽取",
    "acquisition.exchange.hero": "英雄整卡兑换",
    "acquisition.exchange.activity": "活动兑换",
    "acquisition.drop.campaign": "主线英雄掉落",
    "acquisition.drop.activity": "活动关卡英雄产出",
    "acquisition.drop.tower_hero": "爬塔整卡",
    "acquisition.drop.tower_soul": "爬塔英雄碎片",
    "usage.friend_assist": "好友助战",
    "usage.destiny": "羁绊联动",
    "usage.auxiliary_formation": "辅助阵容",
}
UNSUPPORTED_CHANNELS = {
    "appearance.expedition_enemy": "当前远征是英雄遣散转换玩法，没有随机敌人生成器。",
    "appearance.campaign_random_enemy": "当前主线为固定编排关卡，没有随机敌人槽。",
}


def channel_catalog():
    return [{"key": key, "name": name, "label": name, "supported": key not in UNSUPPORTED_CHANNELS,
             "reason": UNSUPPORTED_CHANNELS.get(key, "")}
            for key, name in CHANNELS.items()]


def channel_descriptors():
    return channel_catalog()


def patch_scope_descriptors():
    return [{"key": key, "label": label, "supported": True} for key, label in (
        ("owned", "玩家持有英雄"), ("arenaEnemy", "竞技场敌方"),
        ("pveEnemy", "PvE 敌方"), ("assist", "助战英雄"), ("summoned", "召唤与形态"))]


def config_tables(config):
    return config.get("cfg", config) if isinstance(config, dict) else {}


def runtime(config):
    cfg = config_tables(config)
    value = cfg.get("mod_runtime", {})
    return value if isinstance(value, dict) else {}


def effective_digest(config):
    return str(runtime(config).get("digest", ""))


def base_aid(config, aid):
    aid = str(aid).split("|", 1)[0]
    info = runtime(config)
    mapped = info.get("aliasBaseIds", {}).get(aid)
    if isinstance(mapped, str):
        return mapped
    native = config_tables(config).get("avatar", {}).get(aid, {})
    if isinstance(native, dict) and isinstance(native.get("modBaseAid"), str):
        return native["modBaseAid"]
    row = info.get("heroes", {}).get(aid, {})
    return str(row.get("baseAid", aid)) if isinstance(row, dict) else aid


def hero_metadata(config, aid):
    return runtime(config).get("heroes", {}).get(base_aid(config, aid), {})


def hero_available(config, aid):
    aid = base_aid(config, aid)
    info = runtime(config)
    row = info.get("heroes", {}).get(aid, {})
    if aid in info.get("missingHeroIds", ()) or (isinstance(row, dict) and row.get("available") is False):
        return False
    return aid in config_tables(config).get("avatar", {})


def ensure_available(config, aid):
    if not hero_available(config, aid):
        raise GameplayFault("ModContentMissing", "英雄内容缺失或已停用，请在 Mod 管理中恢复所需包：" + base_aid(config, aid))


def channel_enabled(config, aid, channel):
    if not hero_available(config, aid):
        return False
    row = hero_metadata(config, aid)
    channels = row.get("channels", {}) if isinstance(row, dict) else {}
    if channel in row.get("unavailableChannels", {}):
        return False
    if channel in UNSUPPORTED_CHANNELS:
        return False
    if channels.get(channel) is False:
        return False
    # A shop's individual tier can inherit or narrow its parent switch.
    parent = "acquisition.shop.hero_soul"
    if channel.startswith(parent + ".") and channels.get(parent) is False:
        return False
    return True


def ensure_channel(config, aid, channel):
    ensure_available(config, aid)
    if not channel_enabled(config, aid, channel):
        raise GameplayFault("ModChannelDisabled", "该英雄已从当前存档的此玩法中禁用：" + channel)


def new_heroes(config, channel=None, quality=None):
    result = []
    for aid, metadata in runtime(config).get("heroes", {}).items():
        if not isinstance(metadata, dict) or metadata.get("kind") != "new" or metadata.get("baseAid", aid) != aid:
            continue
        if not hero_available(config, aid) or metadata.get("unitType", "hero") != "hero":
            continue
        try:
            star = int(aid.rsplit("_", 1)[-1])
        except (TypeError, ValueError):
            continue
        if quality is not None and star != quality:
            continue
        if channel is None or channel_enabled(config, aid, channel):
            result.append(aid)
    return sorted(set(result))


def candidate_ids(config, candidates, channel, *, include_new=False, quality=None):
    candidates = [base_aid(config, aid) for aid in candidates]
    result = [aid for aid in candidates if channel_enabled(config, aid, channel)
              and (quality is None or str(aid).endswith("_" + str(quality)))]
    if include_new:
        result.extend(new_heroes(config, channel, quality))
    return list(dict.fromkeys(result))


def band_candidates(config, candidates, channel):
    """Extend only the rarity bands already authored for this concrete source."""
    qualities = {int(str(aid).rsplit("_", 1)[-1]) for aid in candidates
                 if str(aid).rsplit("_", 1)[-1].isdigit()}
    result = candidate_ids(config, candidates, channel)
    for quality in sorted(qualities):
        result.extend(new_heroes(config, channel, quality))
    return list(dict.fromkeys(result))


def definition_id(config, aid, scope="owned"):
    aid = base_aid(config, aid)
    ensure_available(config, aid)
    return runtime(config).get("scopedAvatarIds", {}).get(scope, {}).get(aid, aid)


def reward_hero_ids(reward):
    if not isinstance(reward, dict):
        return []
    result = []
    for key in ("avatar", "avatar_soul"):
        rows = reward.get(key)
        if isinstance(rows, dict):
            result.extend(str(aid) for aid in rows)
    for row in reward.get("heroes", []) if isinstance(reward.get("heroes"), list) else []:
        if isinstance(row, dict) and isinstance(row.get("aid"), str):
            result.append(row["aid"])
    return list(dict.fromkeys(result))


def ensure_reward(config, reward, channel=None):
    for aid in reward_hero_ids(reward):
        if channel is not None:
            ensure_channel(config, aid, channel)
        else:
            ensure_available(config, aid)


def reward_allowed(config, reward, channel):
    return all(channel_enabled(config, aid, channel) for aid in reward_hero_ids(reward))


def draw_categories(config, categories, kind):
    """Keep category probabilities intact; new heroes join their quality band."""
    channel = "acquisition.summon.advanced" if kind == "coin" else "acquisition.summon.normal"
    result = []
    bands = {"green_hero": 3, "blue_hero": 4, "purple_hero": 5, "orange_hero": 6}
    for original in categories:
        if not isinstance(original, dict) or int(original.get("weight", 0)) <= 0:
            continue
        row = copy.deepcopy(original)
        quality = bands.get(row.get("category"))
        row["ids"] = candidate_ids(config, row.get("ids", []), channel,
                                    include_new=quality is not None, quality=quality)
        if not row["ids"]:
            raise GameplayFault("ModPoolEmpty", "过滤后召唤品阶池为空，不能保持原概率：" + str(row.get("category")))
        result.append(row)
    if not result or (kind == "coin" and not any(row.get("category") == "purple_hero" for row in result)):
        raise GameplayFault("ModPoolEmpty", "召唤候选或高级召唤保底品阶不可用")
    return result


def activity_categories(config, pool):
    """Preserve activity quality, whole-card/shard and shard-amount chances."""
    channel = "acquisition.summon.activity"
    groups = {}
    for row in pool:
        if not isinstance(row, dict) or row.get("kind") not in ("avatar", "avatar_soul"):
            continue
        aid, weight = row.get("aid"), row.get("weight")
        if not isinstance(aid, str) or type(weight) is not int or weight <= 0:
            continue
        quality = aid.rsplit("_", 1)[-1]
        key = (row["kind"], quality, row.get("amount", 5) if row["kind"] == "avatar_soul" else 1)
        group = groups.setdefault(key, {"weight": 0, "rows": [], "template": row})
        group["weight"] += weight
        if channel_enabled(config, aid, channel):
            group["rows"].append((copy.deepcopy(row), weight))
    for (kind, quality, amount), group in groups.items():
        template = group.pop("template")
        existing = {row["aid"] for row, _ in group["rows"]}
        for aid in new_heroes(config, channel, int(quality)):
            if aid not in existing:
                group["rows"].append(({**copy.deepcopy(template), "aid": aid}, template["weight"]))
        if not group["rows"]:
            raise GameplayFault("ModPoolEmpty", "活动抽取的某个品阶或奖励类别池为空")
        group["candidateWeight"] = sum(weight for _, weight in group["rows"])
    if not groups:
        raise GameplayFault("ModPoolEmpty", "活动抽取没有可用候选")
    return list(groups.values())


def validate_battle_config(config, intent):
    """Freeze an intent on external deletion; keep the pending record intact."""
    expected = str(intent.get("mod_digest", intent.get("metadata", {}).get("mod_digest", "")))
    if expected and expected != effective_digest(config):
        raise GameplayFault("ModBattleConfigChanged", "战斗使用的 Mod 配置已变化，请恢复原配置后结算")
    if runtime(config):
        for unit in intent.get("team_a", []) + intent.get("team_b", []):
            if isinstance(unit, dict):
                ensure_available(config, unit.get("base_aid", unit.get("aid", "")))


def retain_frozen_intent(config, intent):
    """Expired paid results with missing config remain an auditable record."""
    if not isinstance(intent, dict):
        return False
    expected = intent.get("mod_digest", intent.get("metadata", {}).get("mod_digest", ""))
    return bool(expected and str(expected) != effective_digest(config))


def policy_signature(config):
    info = runtime(config)
    if not info:
        return ""
    payload = json.dumps(info, sort_keys=True, ensure_ascii=False, separators=(",", ":"))
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()
