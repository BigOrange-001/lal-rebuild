"""Apply reviewed PVE placement and NPC skill levels to an isolated config.

The published full config already contains balanced enemy rosters. This overlay
keeps those rosters and their power targets, changing only skill level, lateral
placement, and the four enemy stats needed to offset the skill-power change.
"""
from __future__ import annotations

import argparse
import copy
import json
from pathlib import Path

from campaign_workbook_overlay import _fit_power, _power
from pve_formation import stagger_lane_offsets


TOWER_CHAPTER = "P_200"


def _retune_variant(cfg: dict, stage: dict, team: list[list], diff: str,
                    skill_level: int, *, lateral: bool) -> tuple[int, float]:
    stats_by_diff = stage.get("enemy_unit_stats_by_diff")
    if not isinstance(stats_by_diff, dict) or diff not in stats_by_diff:
        raise ValueError(f"{stage.get('id')}: missing enemy stats for difficulty {diff}")
    base = stats_by_diff[diff]
    if len(base) != len(team) or any(row[0] != stat.get("aid") for row, stat in zip(team, base)):
        raise ValueError(f"{stage.get('id')}: enemy stats are not aligned with roster")
    target = _power(cfg, team, base)
    changed_skills = 0
    for row in team:
        if len(row) < 3:
            raise ValueError(f"{stage.get('id')}: enemy row is missing skill level")
        if row[2] != skill_level:
            row[2] = skill_level
            changed_skills += 1
    changed_positions = stagger_lane_offsets(team) if lateral else 0
    if changed_skills:
        calibrated, actual = _fit_power(cfg, team, base, target)
        stats_by_diff[diff] = calibrated
    else:
        actual = target
    # Existing recommendation may have been rounded independently. Publish
    # the real snapshot so the UI and the server agree after the re-fit.
    by_diff = stage.get("recommended_power_by_diff")
    if isinstance(by_diff, dict) and diff in by_diff:
        by_diff[diff] = actual
    if diff == "0" and "recommended_power" in stage:
        stage["recommended_power"] = actual
    error = abs(actual - target) / max(1, target)
    return changed_skills + changed_positions, error


def retune_campaign_tables(pve: dict, cfg: dict) -> dict:
    """Update main normal/elite plus authored non-tower activity/exploration."""
    result = {"stages": 0, "changed_rows": 0, "max_power_error_pct": 0.0}

    def visit(stage: dict, team: list[list], diff: str, slv: int, lateral: bool) -> None:
        changed, error = _retune_variant(cfg, stage, team, diff, slv, lateral=lateral)
        result["stages"] += 1
        result["changed_rows"] += changed
        result["max_power_error_pct"] = max(result["max_power_error_pct"], error * 100)

    for stage in pve["combat_main"].values():
        visit(stage, stage["team2"], "0", 4, True)
        hard = stage.get("team2_by_diff", {}).get("1")
        if hard is None:
            raise ValueError(f"{stage.get('id')}: missing elite roster")
        visit(stage, hard, "1", 8, True)
    for cid, stage in pve["combat_ploy"].items():
        if cid.startswith(TOWER_CHAPTER + "_"):
            continue
        visit(stage, stage["team2"], "0", 4, True)
    for stage in pve.get("modes", {}).get("exploration", {}).get("stages", []):
        visit(stage, stage["team2"], "0", 4, True)
    result["max_power_error_pct"] = round(result["max_power_error_pct"], 5)
    return result


def tower_skill_level(floor: int) -> int:
    if not 1 <= floor <= 100:
        raise ValueError("tower floor must be from 1 to 100")
    if floor <= 10:
        return 2
    if floor <= 20:
        return 4
    if floor <= 30:
        return 6
    if floor <= 40:
        return 8
    return 10


def retune_tower_tables(pve: dict, cfg: dict) -> dict:
    result = {"floors": 0, "changed_rows": 0, "max_power_error_pct": 0.0}
    for floor in range(1, 101):
        stage = pve["combat_ploy"].get(f"{TOWER_CHAPTER}_{floor}")
        if stage is None:
            raise ValueError(f"missing tower floor {floor}")
        changed, error = _retune_variant(cfg, stage, stage["team2"], "0",
                                         tower_skill_level(floor), lateral=True)
        result["floors"] += 1
        result["changed_rows"] += changed
        result["max_power_error_pct"] = max(result["max_power_error_pct"], error * 100)
    result["max_power_error_pct"] = round(result["max_power_error_pct"], 5)
    return result


def apply_pve_feedback(full_config: dict) -> tuple[dict, dict]:
    """Return a candidate with synchronized gameplay and native PVE tables."""
    output = copy.deepcopy(full_config)
    pve, cfg = output["pve"], output["cfg"]
    campaign = retune_campaign_tables(pve, cfg)
    tower = retune_tower_tables(pve, cfg)
    pve.setdefault("feedback_overlay", {})["schema"] = "lateral-stagger-and-npc-skills-v1"
    for table in ("battle_main", "combat_main", "battle_ploy", "combat_ploy"):
        output[table] = copy.deepcopy(pve[table])
        cfg[table] = copy.deepcopy(pve[table])
    return output, {"campaign": campaign, "tower": tower}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    output, report = apply_pve_feedback(json.loads(args.config.read_text(encoding="utf-8-sig")))
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
