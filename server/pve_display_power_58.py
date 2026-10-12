"""Exploration opponent power display using the existing battle snapshot model."""
from __future__ import annotations

from types import SimpleNamespace

from battle_engine import serialize_stage_team


def exploration_opponent_power(full_config: dict, stage: dict) -> int:
    """Return the current exploration enemy team's native-style power sum.

    The enemy is serialized by the same function used to create exploration
    combat snapshots. The final total is computed by the already-used
    ``GameplayCompetition._team_power`` contract, which mirrors
    ``Avatar.getPower`` weights and skill factors. This is display metadata;
    it does not scale enemy stats or gate combat.
    """
    if not isinstance(full_config, dict) or not isinstance(stage, dict):
        raise ValueError("exploration power requires the full config and stage row")
    cfg = full_config.get("cfg", full_config)
    entries = stage.get("team2")
    if not isinstance(cfg, dict) or not isinstance(entries, list) or not entries:
        raise ValueError("exploration stage has no configured enemy team")
    units = serialize_stage_team(cfg, entries, team=2)
    if len(units) != len(entries) or not units:
        raise ValueError("exploration enemy rows could not be serialized")
    # Exploration constructs one native lane. Match that battle snapshot before
    # passing it to the shared power estimator.
    for unit in units:
        unit["line"] = 0
    from gameplay_competition import GameplayCompetition

    estimator = SimpleNamespace(
        cfg=cfg,
        simple=cfg.get("system_simple", {}),
    )
    value = GameplayCompetition._team_power(estimator, units)
    if type(value) is not int or value < 1:
        raise ValueError("native power estimator returned an invalid result")
    return value
