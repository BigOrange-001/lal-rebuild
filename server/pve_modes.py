"""Validated lookup helpers for solo-mode configuration tables."""
from player_store import GameplayFault


def mode_rules(config, name):
    if not isinstance(config, dict):
        raise GameplayFault("InvalidConfig", "Mode configuration is unavailable")
    modes = config.get("modes") or config.get("cfg", {}).get("modes") or config.get("pve", {}).get("modes") or {}
    rules = modes.get(name, {}) if isinstance(modes, dict) else {}
    if not isinstance(rules, dict):
        raise GameplayFault("InvalidConfig", f"{name} mode rules are invalid")
    return rules


def exploration_stages(config):
    stages = mode_rules(config, "exploration").get("stages", [])
    if not isinstance(stages, list) or not stages:
        raise GameplayFault("InvalidConfig", "Exploration stages are not configured")
    for expected, stage in enumerate(stages, 1):
        if not isinstance(stage, dict) or int(stage.get("id", 0)) != expected or not stage.get("team2") or not stage.get("reward"):
            raise GameplayFault("InvalidConfig", f"Exploration stage {expected} is incomplete")
    return stages


def expedition_reward_per_hero(config):
    amount = mode_rules(config, "expedition").get("reward_per_hero", {}).get("dn_stone", 2)
    if type(amount) is not int or amount < 0:
        raise GameplayFault("InvalidConfig", "Expedition reward is invalid")
    return amount
