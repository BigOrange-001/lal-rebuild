"""Validate and roll per-stage campaign hero drops.

Candidate IDs and final chances are authored into the PVE stage config. This
helper only chooses one family and rolls once; reward granting stays inside
the caller's existing atomic settlement transaction.
"""
from __future__ import annotations

import random
import re

from player_store import GameplayFault
from gameplay_common import ensure_hero_acquirable

_HERO_AID = re.compile(r"A_1\d{3}_(\d+)")


def roll_campaign_hero_drop(config: dict, stage: dict, stage_id: str,
                            difficulty: int, victory: bool, rng=None) -> str | None:
    """Return one exact configured hero aid, or None, without mutating state."""
    if not victory or difficulty not in (0, 1) or not re.fullmatch(r"M_\d{3}_\d+", str(stage_id)):
        return None
    if not isinstance(stage, dict):
        raise GameplayFault("InvalidHeroDropPolicy", "Campaign hero drop stage is malformed")
    by_diff = stage.get("hero_drop_candidates_by_diff")
    if by_diff is None:
        return None
    if not isinstance(by_diff, dict):
        raise GameplayFault("InvalidHeroDropPolicy", "Campaign hero drop candidates are malformed")
    candidates = by_diff.get(str(difficulty), [])
    if not isinstance(candidates, list):
        raise GameplayFault("InvalidHeroDropPolicy", "Campaign hero drop candidates are malformed")
    if not candidates:
        return None

    cfg = config.get("cfg", config) if isinstance(config, dict) else {}
    avatars = cfg.get("avatar", {}) if isinstance(cfg, dict) else {}
    simple = cfg.get("system_simple", {}) if isinstance(cfg, dict) else {}
    if not isinstance(avatars, dict) or not isinstance(simple, dict):
        raise GameplayFault("InvalidHeroDropPolicy", "Campaign hero definitions are unavailable")
    blocked_raw = simple.get("skin_acquisition_blocked_heroes", [])
    if not isinstance(blocked_raw, list) or any(not isinstance(x, str) for x in blocked_raw):
        raise GameplayFault("InvalidHeroDropPolicy", "Campaign hero exclusion list is malformed")
    blocked = set(blocked_raw)
    stage_hero_ids = set()
    for entry in stage.get("team2", []):
        if isinstance(entry, (list, tuple)) and entry:
            stage_hero_ids.add(str(entry[0]))
    source = rng if rng is not None else random.SystemRandom()
    seen_families = set()
    for row in candidates:
        if not isinstance(row, dict):
            raise GameplayFault("InvalidHeroDropPolicy", "Campaign hero drop row is malformed")
        aid = row.get("aid")
        enemy_aid = row.get("enemy_aid")
        family = row.get("family")
        match = _HERO_AID.fullmatch(str(aid))
        chance = row.get("chance_bp")
        enemy_match = _HERO_AID.fullmatch(str(enemy_aid))
        star = int(match.group(1)) if match else 0
        base_chance = 1500 if difficulty == 0 else 2500
        expected_chance = 100 if star == 5 else 20 if star == 6 else base_chance
        if (not match or not isinstance(family, str) or not family
                or family != str(aid).rsplit("_", 1)[0]
                or aid not in avatars or aid in blocked
                or type(row.get("star")) is not int or row["star"] != star
                or not enemy_match or str(enemy_aid).rsplit("_", 1)[0] != family
                or enemy_aid not in stage_hero_ids
                or type(chance) is not int or chance != expected_chance):
            raise GameplayFault("InvalidHeroDropPolicy", "Campaign hero drop row has an invalid ID or chance")
        if star == 6:
            enemy_star = int(enemy_match.group(1))
            lower_ids = [candidate for candidate in avatars
                         if str(candidate).startswith(f"{family}_")
                         and candidate not in blocked
                         and (candidate.rsplit("_", 1)[-1].isdigit())
                         and 2 <= int(candidate.rsplit("_", 1)[-1]) < 6]
            if enemy_star != 6 or lower_ids:
                raise GameplayFault("InvalidHeroDropPolicy", "Orange fallback is only valid for an orange-only family")
        if family in seen_families:
            raise GameplayFault("InvalidHeroDropPolicy", "Campaign hero drop pool repeats a family")
        seen_families.add(family)
        try:
            ensure_hero_acquirable(aid, config)
        except GameplayFault as exc:
            raise GameplayFault("InvalidHeroDropPolicy", "Campaign hero drop pool contains a blocked skin") from exc
    selected = source.choice(candidates)
    if source.randrange(10000) < int(selected["chance_bp"]):
        return str(selected["aid"])
    return None
