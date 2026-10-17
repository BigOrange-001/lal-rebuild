"""Restore the twenty PR #11/#12 skill rows after local balance overlays.

The authored astronaut Teemo and Erlang Xin Zhao skills take precedence over
generic tempo, captain and orange-stat transforms.  This changes skill rows
only; avatar panels, effects and unrelated skills keep their local overlays.
"""
from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path


_DELTA_PATH = Path(__file__).with_name("upstream_hero_config_delta.json")
_MARKER = "upstream_skill_priority"
_SCHEMA = "upstream-pr11-pr12-skill-priority-v1"
SKILL_IDS = frozenset({
    "S_305082_5", "S_305082_6",
    "S_201209_4", "S_301209_4", "S_201209_5", "S_301209_5",
    "S_201209_6", "S_301209_6",
    "S_201310_5", "S_301310_5", "S_401310_5",
    "S_201310_6", "S_301310_6", "S_401310_6",
    "S_201226_6", "S_301226_6", "S_401226_6", "S_402024_6",
    "S_821003_2", "S_821018_2",
})


def apply_upstream_skill_priority(document: dict) -> dict:
    """Replace only the authored skill rows with the frozen upstream rows."""
    delta = json.loads(_DELTA_PATH.read_text(encoding="utf-8"))
    snapshot = delta["skill"]
    if set(snapshot) != SKILL_IDS:
        raise ValueError("upstream skill snapshot must contain the exact twenty PR rows")
    for sid, row in snapshot.items():
        if row.get("id") != sid or not isinstance(row.get("pl"), list) or not isinstance(row.get("skill"), list):
            raise ValueError(f"incomplete upstream skill row: {sid}")

    cfg = document.get("cfg", document)
    existing = cfg.get(_MARKER)
    if existing is not None and (not isinstance(existing, dict) or existing.get("schema") != _SCHEMA):
        raise ValueError(f"incompatible upstream skill priority marker: {existing!r}")
    digest = hashlib.sha256(json.dumps(snapshot, ensure_ascii=False, sort_keys=True,
                                       separators=(",", ":")).encode("utf-8")).hexdigest()
    marker = {"schema": _SCHEMA, "source_commit": delta["source_commit"],
              "source_path": delta["source_path"], "skill_sha256": digest,
              "sids": sorted(SKILL_IDS)}
    if existing == marker and all(cfg["skill"].get(sid) == row for sid, row in snapshot.items()):
        return document
    for sid, row in snapshot.items():
        cfg["skill"][sid] = copy.deepcopy(row)
    cfg[_MARKER] = marker
    return document
