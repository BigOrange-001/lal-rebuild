"""Daily local arena reward contract shared by service and native config."""

DAILY_RANK_MARK = 60_000
DAILY_PAID_BATTLES = 10
DAILY_BATTLE_MARK = DAILY_RANK_MARK // DAILY_PAID_BATTLES


def apply_arena_rewards(document):
    """Expose the same rank mark in every native PvP daily-award config alias.

    ``sys.get_config`` gives PanelPVPGetDayAward the authored
    ``ploy_system_simple.pvp_rank.lv_range_gift`` table directly. Keep that
    display table aligned with the server's once-per-day rank mail without
    modifying the source JSON file.
    """
    if not isinstance(document, dict):
        raise ValueError("Arena config document must be an object")
    roots = [document]
    cfg = document.get("cfg")
    if isinstance(cfg, dict):
        roots.append(cfg)
    seen = set()
    found = False
    for root in roots:
        ploy = root.get("ploy_system_simple")
        if not isinstance(ploy, dict):
            continue
        rank = ploy.get("pvp_rank")
        if not isinstance(rank, dict):
            continue
        bands = rank.get("lv_range_gift")
        if not isinstance(bands, dict) or not bands:
            raise ValueError("Arena daily rank gift bands are missing")
        for gifts in bands.values():
            if not isinstance(gifts, dict) or not gifts:
                raise ValueError("Arena daily rank gift band is invalid")
            if id(gifts) not in seen:
                gifts["mark"] = DAILY_RANK_MARK
                seen.add(id(gifts))
        found = True
    if not found:
        raise ValueError("Arena daily rank config is missing")
    return document
