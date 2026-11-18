"""Set ``test_hero: true`` on a playable avatar definition to publish it in the workshop."""
import re

from player_store import GameplayFault


def is_test_hero(config, aid):
    from mod_policy import base_aid, config_tables
    row = config_tables(config).get("avatar", {}).get(base_aid(config, aid))
    return isinstance(row, dict) and row.get("test_hero") is True


def ensure_regular_hero(config, aid):
    if is_test_hero(config, aid):
        raise GameplayFault("TestHeroWorkshopOnly", "测试英雄仅可通过神秘商店的「测试英雄」页或管理邮件领取。")


def has_test_hero_units(config, units):
    return any(isinstance(unit, dict) and is_test_hero(config, unit.get("base_aid") or unit.get("aid"))
               for unit in (units or ()))


def contains_test_hero(config, reward):
    from mod_policy import reward_hero_ids
    return any(is_test_hero(config, aid) for aid in reward_hero_ids(reward))


def is_workshop_offer(config, aid):
    from hero_catalog_105 import is_abandoned
    from mod_policy import base_aid, config_tables, hero_available, hero_metadata
    if not isinstance(aid, str):
        return False
    row = config_tables(config).get("avatar", {}).get(aid)
    return (isinstance(row, dict) and row.get("test_hero") is True
            and re.fullmatch(r"A_1[0-9]+_[2-6]", aid) is not None
            and base_aid(config, aid) == aid and hero_available(config, aid)
            and row.get("modUnitType", "hero") == "hero"
            and hero_metadata(config, aid).get("unitType", "hero") == "hero"
            and not is_abandoned(config, aid))


def claimed_test_heroes(profile, config):
    from mod_policy import base_aid
    claimed = set(profile.get("records", {}).get("test_hero_claims", []))
    # Treat already-owned copies in older saves as claimed.
    claimed.update(base_aid(config, hero.get("aid", iid))
                   for iid, hero in profile.get("avatars", {}).items() if isinstance(hero, dict))
    return claimed


def record_test_hero_claim(profile, aid):
    claims = profile.setdefault("records", {}).setdefault("test_hero_claims", [])
    if aid not in claims:
        claims.append(aid)


def workshop_rows(profile, config):
    from mod_policy import config_tables
    claimed = claimed_test_heroes(profile, config)
    avatars = config_tables(config).get("avatar", {})
    return [{"aid": aid, "name": avatars[aid].get("name", aid), "claimed": aid in claimed}
            for aid in sorted(avatars) if is_workshop_offer(config, aid)]
