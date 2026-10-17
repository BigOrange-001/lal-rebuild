"""Apply the authored PR #11/#12 hero and skill configuration changes.

The reconstruction baseline predates those merged PRs.  This small snapshot
contains the changed configuration rows from origin/main at 00f777e, plus the
authored A_1310_6 panel to undo an earlier local recalculation.  Apply it
before local balance and recruitment overlays.  Existing avatar and skill
rows are merged by changed field so unrelated local metadata survives.
"""
from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path


_DELTA_PATH = Path(__file__).with_name("upstream_hero_config_delta.json")
_MARKER = "upstream_hero_config_overlay"
_SCHEMA = "upstream-hero-config-v1"


def apply_upstream_hero_config(document):
    """Bring the stale reconstruction config up to the merged authored rows."""
    payload = _DELTA_PATH.read_bytes()
    delta = json.loads(payload)
    cfg = document.get("cfg", document)
    marker = {
        "schema": _SCHEMA,
        "source_commit": delta["source_commit"],
        "delta_sha256": hashlib.sha256(payload).hexdigest(),
    }
    if cfg.get(_MARKER) == marker:
        return document
    for section in ("avatar", "skill"):
        for key, changed_fields in delta[section].items():
            row = cfg[section].setdefault(key, {})
            row.update(copy.deepcopy(changed_fields))
    for key, row in delta["effect"].items():
        cfg["effect"][key] = copy.deepcopy(row)
    cfg["system_simple"]["attack"] = copy.deepcopy(delta["system_simple"]["attack"])
    cfg[_MARKER] = marker
    return document
