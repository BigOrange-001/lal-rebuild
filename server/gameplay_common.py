"""Shared, transaction-local gameplay helpers."""
from __future__ import annotations
import datetime
import random
from zoneinfo import ZoneInfo
from player_store import GameplayFault

LOCAL_TZ = ZoneInfo("Asia/Shanghai")
CURRENCIES = {"gold", "coin", "score", "medal", "mark"}

def game_day(now=None):
    """Return the authoritative local calendar day as YYYY-MM-DD."""
    if now is None:
        now = datetime.datetime.now(datetime.timezone.utc)
    if isinstance(now, (int, float)):
        now = datetime.datetime.fromtimestamp(now, datetime.timezone.utc)
    if now.tzinfo is None:
        now = now.replace(tzinfo=datetime.timezone.utc)
    return now.astimezone(LOCAL_TZ).date().isoformat()

def skin_acquisition_blocked_ids(config=None):
    """Return the exact configured hero IDs blocked from new player grants."""
    cfg = config.get("cfg", config) if isinstance(config, dict) else {}
    simple = cfg.get("system_simple", {}) if isinstance(cfg, dict) else {}
    ids = simple.get("skin_acquisition_blocked_heroes", []) if isinstance(simple, dict) else []
    if not isinstance(ids, list) or any(not isinstance(aid, str) for aid in ids):
        raise GameplayFault("InvalidConfig", "Skin acquisition policy has an invalid ID list")
    return frozenset(ids)

def ensure_hero_acquirable(aid, config=None, *, allow_skin=False):
    """Reject a newly minted skin hero unless a trusted internal caller opts in."""
    if allow_skin:
        return
    if aid in skin_acquisition_blocked_ids(config):
        raise GameplayFault("SkinAcquisitionRestricted", "This hero form is not available through player acquisition")

def _reward_hero_ids(reward):
    if not isinstance(reward, dict):
        return []
    found = []
    avatars = reward.get("avatar")
    if isinstance(avatars, dict):
        found.extend(str(aid) for aid in avatars)
    heroes = reward.get("heroes")
    if isinstance(heroes, list):
        found.extend(item.get("aid") for item in heroes if isinstance(item, dict) and isinstance(item.get("aid"), str))
    return found

def _reward_equip_ids(reward):
    if not isinstance(reward, dict):
        return []
    found = []
    items = reward.get("items")
    if isinstance(items, list):
        found.extend(item.get("eid") for item in items if isinstance(item, dict) and isinstance(item.get("eid"), str))
    equips = reward.get("equip")
    if isinstance(equips, dict):
        found.extend(str(eid) for eid in equips)
    return found

def equipment_exclusive_ids(config=None):
    """Return the configured exact gear IDs reserved for authorized mail."""
    cfg = config.get("cfg", config) if isinstance(config, dict) else {}
    simple = cfg.get("system_simple", {}) if isinstance(cfg, dict) else {}
    policy = simple.get("equipment_roll_policy", {}) if isinstance(simple, dict) else {}
    ids = policy.get("exclusive_ids", []) if isinstance(policy, dict) else []
    if not isinstance(ids, list) or any(not isinstance(eid, str) for eid in ids):
        raise GameplayFault("InvalidConfig", "Equipment exclusive policy has an invalid ID list")
    return frozenset(ids)

def grant_reward(profile, reward, config=None, *, allow_skin=False, allow_equipment_exclusive=False):
    """Apply positive currency/attribute rewards to a profile inside atomic_update."""
    if not isinstance(reward, dict):
        raise GameplayFault("InvalidReward", "Reward must be an object")
    cfg = config.get("cfg", config) if isinstance(config, dict) else {}
    if not isinstance(allow_skin, bool):
        raise GameplayFault("InvalidReward", "Skin acquisition override must be boolean")
    if not isinstance(allow_equipment_exclusive, bool):
        raise GameplayFault("InvalidReward", "Equipment acquisition override must be boolean")
    # Validate all hero IDs before applying any other reward field. This keeps
    # direct helper calls atomic as well as callers inside PlayerStore's SQL
    # transaction, even when the reward dictionary lists currency first.
    if not allow_skin:
        blocked = skin_acquisition_blocked_ids(cfg)
        denied = sorted(set(_reward_hero_ids(reward)) & blocked)
        if denied:
            raise GameplayFault("SkinAcquisitionRestricted", "This hero form is not available through player acquisition")
    if not allow_equipment_exclusive:
        denied = sorted(set(_reward_equip_ids(reward)) & set(equipment_exclusive_ids(cfg)))
        if denied:
            raise GameplayFault("ExclusiveEquipmentRestricted", "This equipment is available only through authorized mail")
    for key, value in reward.items():
        if key in CURRENCIES:
            if type(value) is not int or value < 0:
                raise GameplayFault("InvalidReward", "Currency rewards must be nonnegative integers")
            profile[key] = int(profile.get(key, 0)) + value
        elif key == "exp":
            if type(value) is not int or value < 0:
                raise GameplayFault("InvalidReward", "Player experience must be a nonnegative integer")
            simple = cfg.get("system_simple", {}) if isinstance(cfg, dict) else {}
            exp_cfg = simple.get("exp_config", [100, 1.2, 1, 125])
            cap = int(exp_cfg[3]) if len(exp_cfg) > 3 else 125
            level = max(1, int(profile.get("lv", 1)))
            total = int(profile.get("exp", 0)) + value
            up_exp = simple.get("up_exp", {})
            while level < cap:
                required = None
                override = up_exp.get(str(level + 1), up_exp.get(level + 1)) if isinstance(up_exp, dict) else None
                if type(override) in (int, float) and override > 0:
                    required = int(override)
                if required is None:
                    required = int(exp_cfg[0] * level * level + exp_cfg[1] * level + exp_cfg[2])
                if total < required:
                    break
                total -= required
                level += 1
            profile["lv"] = level
            profile["exp"] = total
        elif key == "attrs":
            if not isinstance(value, dict):
                raise GameplayFault("InvalidReward", "attrs reward must be an object")
            attrs = profile.setdefault("attrs", {})
            for attr, amount in value.items():
                if attr == "box_key":
                    current_box_key = attrs.get(attr, 0)
                    if not isinstance(current_box_key, dict):
                        if type(current_box_key) is not int or current_box_key < 0:
                            raise GameplayFault("InvalidReward", "Stored box_key must be a nonnegative count or native box/key map")
                        current_box_key = {
                            "box": {"num": 0, "last_time": None},
                            "key": {"num": current_box_key, "last_time": None},
                        }
                        attrs[attr] = current_box_key
                if attr in {"dust", "sp"}:
                    values = amount if isinstance(amount, list) else [amount]
                    simple = cfg.get("system_simple", {}) if isinstance(cfg, dict) else {}
                    talent_config = simple.get("talent_config") if isinstance(simple, dict) else None
                    color_count = max(4, len(talent_config)) if isinstance(talent_config, (list, tuple)) else 4
                    if attr == "sp" and not isinstance(talent_config, (list, tuple)):
                        color_count = 6
                    max_values = color_count if attr == "sp" else 4
                    if not 1 <= len(values) <= max_values or any(type(n) is not int or n < 0 for n in values):
                        raise GameplayFault("InvalidReward", "dust/sp rewards must fit configured colors and contain nonnegative integers")
                    current = attrs.get(attr, [0, 0, 0, 0])
                    if not isinstance(current, list): current = [int(current), 0, 0, 0]
                    current = current + [0] * max(0, max_values - len(current))
                    for i, n in enumerate(values): current[i] += n
                    attrs[attr] = current
                elif isinstance(amount, dict):
                    current = attrs.setdefault(attr, {})
                    if attr == "box_key":
                        for box_kind, count in amount.items():
                            if box_kind not in {"box", "key"} or type(count) is not int or count < 0:
                                raise GameplayFault("InvalidReward", "box_key rewards must map box/key to nonnegative integers")
                            entry = current.get(box_kind)
                            if not isinstance(entry, dict): entry = current[box_kind] = {"num": 0, "last_time": None}
                            entry["num"] = int(entry.get("num", 0)) + count
                            entry.setdefault("last_time", None)
                    else:
                        if not isinstance(current, dict): raise GameplayFault("InvalidReward", "Mapped attribute reward requires a mapped attribute")
                        for item_id, count in amount.items():
                            if type(count) is not int or count < 0: raise GameplayFault("InvalidReward", "Mapped attribute rewards must be nonnegative integers")
                            current[str(item_id)] = int(current.get(str(item_id), 0)) + count
                else:
                    if type(amount) is not int or amount < 0:
                        raise GameplayFault("InvalidReward", "Attribute rewards must be nonnegative integers")
                    current = attrs.get(attr, 0)
                    if attr == "box_key":
                        if amount == 0: continue
                        entry = current["key"]
                        if not isinstance(entry, dict): entry = current["key"] = {"num": 0, "last_time": None}
                        entry["num"] = int(entry.get("num", 0)) + amount
                        entry.setdefault("last_time", None)
                    elif isinstance(current, list):
                        if not current: current.append(0)
                        current[0] += amount
                    elif isinstance(current, dict):
                        if amount == 0: continue
                        raise GameplayFault("InvalidReward", "Mapped attribute reward requires a mapped amount")
                    else: attrs[attr] = int(current) + amount
        elif key in {"avatar_soul", "equip_soul"}:
            if not isinstance(value, dict): raise GameplayFault("InvalidReward", "Soul rewards must be keyed by configured ids")
            target = profile.setdefault(key, {})
            for item_id, amount in value.items():
                if type(amount) is not int or amount < 0: raise GameplayFault("InvalidReward", "Soul amounts must be nonnegative integers")
                target[str(item_id)] = int(target.get(str(item_id), 0)) + amount
        elif key == "culture_book":
            if type(value) is not int or value < 0: raise GameplayFault("InvalidReward", "Culture book reward must be a nonnegative integer")
            attrs = profile.setdefault("attrs", {}); attrs["culture_book"] = int(attrs.get("culture_book", 0)) + value
        elif key == "dn_stone":
            if type(value) is not int or value < 0: raise GameplayFault("InvalidReward", "Demon stone reward must be a nonnegative integer")
            attrs = profile.setdefault("attrs", {}); attrs["dn_stone"] = int(attrs.get("dn_stone", 0)) + value
        elif key == "avatar":
            if not isinstance(value, dict): raise GameplayFault("InvalidReward", "Avatar reward must map ids to counts")
            grant_reward(profile, {"heroes":[{"aid":str(aid),"num":int(amount)} for aid,amount in value.items()]}, config, allow_skin=allow_skin, allow_equipment_exclusive=allow_equipment_exclusive)
        elif key == "equip":
            if not isinstance(value, dict): raise GameplayFault("InvalidReward", "Equipment reward must map ids to counts")
            grant_reward(profile, {"items":[{"eid":str(eid),"num":int(amount)} for eid,amount in value.items()]}, config, allow_skin=allow_skin, allow_equipment_exclusive=allow_equipment_exclusive)
        elif key == "heroes":
            definitions = cfg.get("avatar", {}) if isinstance(cfg, dict) else {}
            avatars = profile.setdefault("avatars", {})
            if not isinstance(value, list): raise GameplayFault("InvalidReward", "heroes reward must be an array of {aid,num} records")
            total = 0
            for item in value:
                if not isinstance(item, dict) or not isinstance(item.get("aid"), str): raise GameplayFault("InvalidReward", "Hero reward requires an aid")
                aid = item["aid"]; count = item.get("num", 1)
                if aid not in definitions: raise GameplayFault("UnknownAvatar", "Hero reward id is not configured: " + aid)
                if type(count) is not int or not 1 <= count <= 100: raise GameplayFault("InvalidReward", "Hero reward count must be 1 to 100")
                total += count
            attrs = profile.setdefault("attrs", {})
            current_count = len(avatars)
            stored_capacity = attrs.get("avatar_len", 0)
            if type(stored_capacity) is not int or stored_capacity < 0: stored_capacity = 0
            simple = cfg.get("system_simple", {}) if isinstance(cfg, dict) else {}
            len_cfg = simple.get("avatar_len", [0,20,100,1000,1]) if isinstance(simple, dict) else [0,20,1000,1000,1]
            configured_max = int(len_cfg[3]) if isinstance(len_cfg, (list,tuple)) and len(len_cfg) > 3 and type(len_cfg[3]) is int else 1000
            capacity = max(current_count, stored_capacity)
            if "avatar_len" not in attrs:
                capacity = max(capacity, configured_max)
            if current_count + total > capacity:
                raise GameplayFault("AvatarCapacity", "Hero inventory has no free slots")
            attrs["avatar_len"] = capacity
            for item in value:
                aid = item["aid"]; count = item.get("num", 1)
                for _ in range(count):
                    seq = max([int(v.get("id", "|0").rsplit("|",1)[-1]) for v in avatars.values() if "|" in str(v.get("id", ""))] or [-1]) + 1
                    iid = f"{aid}|{seq}"
                    avatars[iid] = {"id":iid,"aid":iid,"lv":1,"slv":1,"exp":0,"hp":0,"ap":0,"de_ph":0,"de_ma":0,"phase":0,"morph":0,"love_exp":0,"equips":[]}
        elif key == "items":
            definitions = cfg.get("equip", {}) if isinstance(cfg, dict) else {}
            equipment = profile.setdefault("my_equips", {})
            if not isinstance(equipment, dict):
                raise GameplayFault("InvalidProfile", "Equipment inventory has an invalid shape")
            if not isinstance(value, list): raise GameplayFault("InvalidReward", "items reward must be an array of {eid,num} records")
            total = 0
            for item in value:
                if not isinstance(item, dict) or not isinstance(item.get("eid"), str): raise GameplayFault("InvalidReward", "Equipment reward requires an eid")
                eid = item["eid"]; count = item.get("num", 1)
                if eid not in definitions: raise GameplayFault("UnknownEquipment", "Equipment reward id is not configured: " + eid)
                if type(count) is not int or not 1 <= count <= 100: raise GameplayFault("InvalidReward", "Equipment reward count must be 1 to 100")
                total += count
            simple = cfg.get("system_simple", {}) if isinstance(cfg, dict) else {}
            equip_cfg = simple.get("equip_config", [100]) if isinstance(simple, dict) else [100]
            capacity = int(equip_cfg[0]) if isinstance(equip_cfg, (list, tuple)) and equip_cfg and type(equip_cfg[0]) is int else 100
            if len(equipment) + total > capacity:
                raise GameplayFault("EquipCapacity", "Equipment inventory has no free slots")
            # Validate the complete reward and available storage before mutating so
            # a multi-item bundle is all-or-nothing even for direct helper callers.
            for item in value:
                eid = item["eid"]; count = item.get("num", 1)
                for _ in range(count):
                    index = 0
                    while f"eq{index}" in equipment: index += 1
                    definition = definitions[eid]
                    is_book = int(definition.get("type", 0)) == 6
                    policy = simple.get("equipment_roll_policy", {}) if isinstance(simple, dict) else {}
                    exclusive = set(policy.get("exclusive_ids", [])) if isinstance(policy, dict) else set()
                    from equipment_growth_v2 import roll_for_new_item
                    equipment[f"eq{index}"] = {"eid":eid,"lv":1,"slv":0,"sexp":0,"new_4attrs":{"hit":0,"flee":0,"crit":0,"tough":0},"halo":{"lv":0,"exp":0},"haloLv":0,"haloExp":0,"alchemy":[0,0],"stat_roll_ppm":1_000_000 if is_book else roll_for_new_item(random.SystemRandom(), eid in exclusive),"equipment_v2_version":1,"wash_schema_version":1}
        elif key == "avatar_exp":
            if not isinstance(value, dict) or not isinstance(value.get("hero_id"), str) or type(value.get("amount")) is not int or value["amount"] < 0:
                raise GameplayFault("InvalidReward", "avatar_exp requires hero_id and a nonnegative amount")
            avatar = profile.setdefault("avatars", {}).get(value["hero_id"])
            if avatar is None: raise GameplayFault("UnknownAvatar", "Cannot award experience to an unknown avatar")
            avatar["exp"] = int(avatar.get("exp", 0)) + value["amount"]
        else:
            raise GameplayFault("UnsupportedReward", "Unsupported reward field: " + str(key))
    return profile
