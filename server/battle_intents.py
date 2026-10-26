"""Atomic battle-intent helpers for single-player game modes.

Call these functions only from PlayerStore.atomic_update mutators. They do
not simulate a winner or grant rewards; each gameplay mode owns that policy.
"""
from __future__ import annotations
import copy, secrets, time
from player_store import GameplayFault


def create_intent(profile, kind, metadata, team_a, team_b, ttl=3600, now=None, *, config=None):
    """Persist a one-shot intent in the caller's existing profile transaction."""
    from mod_policy import effective_digest, retain_frozen_intent
    if not isinstance(kind, str) or not kind or len(kind) > 48:
        raise GameplayFault("InvalidBattle", "Battle kind is invalid")
    if not isinstance(metadata, dict) or not isinstance(team_a, list) or not isinstance(team_b, list):
        raise GameplayFault("InvalidBattle", "Battle metadata and teams are required")
    now = int(time.time() if now is None else now)
    fight_id = secrets.token_urlsafe(18)
    seed = secrets.randbelow(2**31 - 1) + 1
    all_pending = profile.setdefault("pending_battles", {})
    pending = all_pending.setdefault(kind, {})
    all_pending[kind] = {key: value for key, value in pending.items()
                         if isinstance(value, dict) and (int(value.get("expires", 0)) > now
                         or (config is not None and retain_frozen_intent(config, value)))}
    intent = {"fight_id": fight_id, "kind": kind, "seed": seed,
              "metadata": copy.deepcopy(metadata), "team_a": copy.deepcopy(team_a),
              "team_b": copy.deepcopy(team_b), "created": now,
              "expires": now + max(60, min(int(ttl), 86400))}
    if config is not None:
        if effective_digest(config):
            intent["mod_digest"] = effective_digest(config)
    all_pending[kind][fight_id] = intent
    return {"fight_id": fight_id, "seed": seed}


def consume_intent(profile, kind, params, metadata_keys=(), allowed_signs=(1, 2), now=None, *, config=None):
    """Validate and consume one intent in the same transaction as settlement."""
    if not isinstance(params, dict):
        raise GameplayFault("InvalidBattle", "Battle finish params must be an object")
    fight_id, sign = params.get("fight_id"), params.get("sign")
    if not isinstance(fight_id, str) or not fight_id or len(fight_id) > 128:
        raise GameplayFault("MissingFight", "A valid fight_id is required")
    if type(sign) is not int or sign not in allowed_signs:
        raise GameplayFault("InvalidResult", "Client result is invalid")
    intents = profile.setdefault("pending_battles", {}).setdefault(kind, {})
    intent = intents.get(fight_id)
    now = int(time.time() if now is None else now)
    if isinstance(intent, dict) and config is not None:
        from mod_policy import validate_battle_config
        validate_battle_config(config, intent)
    if not isinstance(intent, dict) or int(intent.get("expires", 0)) < now:
        intents.pop(fight_id, None)
        raise GameplayFault("UnknownFight", "Battle is expired or does not belong to this player")
    if params.get("fight_kind", kind) != kind:
        raise GameplayFault("InvalidBattle", "Battle kind does not match the intent")
    metadata = intent.get("metadata", {})
    submitted_metadata = params.get("metadata", params)
    if not isinstance(submitted_metadata, dict):
        raise GameplayFault("InvalidBattle", "Battle metadata must be an object")
    for key in metadata_keys:
        if key in metadata and submitted_metadata.get(key) != metadata[key]:
            raise GameplayFault("InvalidBattle", "Battle metadata does not match the intent")
    snapshots = params.get("teams", {})
    if not isinstance(snapshots, dict):
        raise GameplayFault("InvalidResult", "Team snapshots must be an object")
    validate_snapshots(snapshots, intent)
    intents.pop(fight_id)
    return {**copy.deepcopy(intent), "sign": sign, "snapshots": copy.deepcopy(snapshots)}


def validate_snapshots(snapshots, intent):
    """Bound client diagnostics; snapshots are never treated as proof of victory."""
    for name, expected in (("team_a", intent.get("team_a", [])), ("team_b", intent.get("team_b", []))):
        values = snapshots.get(name, [])
        if not isinstance(values, list) or len(values) > 30:
            raise GameplayFault("InvalidResult", "Invalid result team snapshot")
        for unit in values:
            if not isinstance(unit, dict) or not isinstance(unit.get("aid"), str):
                raise GameplayFault("InvalidResult", "Invalid combatant snapshot")
            hp, maximum = unit.get("hp"), unit.get("hp_max")
            # Avatar.injured subtracts lethal damage without clamping hp to 0,
            # so native client snapshots may contain a negative final value.
            if (type(hp) not in (int, float) or type(maximum) not in (int, float)
                    or abs(hp) > 1_000_000_000 or maximum <= 0 or maximum > 1_000_000_000
                    or hp > maximum):
                raise GameplayFault("InvalidResult", "Invalid combatant health")

