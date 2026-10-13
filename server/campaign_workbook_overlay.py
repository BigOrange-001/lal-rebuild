"""Apply the reviewed narrative campaign workbook to the local PVE config.

The workbook is data, never executable instructions. Its old recommended-power
column is deliberately ignored. No skill definitions or player data are edited.
"""
from __future__ import annotations

import argparse
import copy
import hashlib
import json
import math
import posixpath
import re
import statistics
import zipfile
from collections import defaultdict
from pathlib import Path
from xml.etree import ElementTree as ET

from battle_engine import serialize_stage_team


WORKBOOK_SHA256 = "c75d410042286006ae5e418f76a3a95d610ff98daad92cb1d0f3fda715ab58b6"
NAMESPACE = {"m": "http://schemas.openxmlformats.org/spreadsheetml/2006/main"}
RELATIONSHIP = "{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id"
STAT_KEYS = ("hp", "ap", "de_ph", "de_ma")
# One target per five-chapter band, in units of the existing reviewed bare
# orange level-99 reference. The first two bands are anchored to actual early
# player teams (five green level-1 ~= 1,444; five blue level-60 ~= 64,156),
# rather than blindly using the old orange-relative targets. An 8% rise
# across each band keeps its chapters close.
BAND_RATIOS = (0.0032, 0.14, 1.00, 1.72, 2.78, 4.00)
FINALE_MULTIPLIER = 1.25


def _sheet_rows(archive: zipfile.ZipFile, member: str, strings: list[str]) -> list[dict]:
    root = ET.fromstring(archive.read(member))
    result = []
    for row in root.findall("m:sheetData/m:row", NAMESPACE):
        values = {}
        for cell in row.findall("m:c", NAMESPACE):
            column = re.match(r"[A-Z]+", cell.attrib["r"]).group()
            raw = cell.find("m:v", NAMESPACE)
            kind = cell.attrib.get("t")
            if kind == "inlineStr":
                inline = cell.find("m:is", NAMESPACE)
                value = "".join(inline.itertext()) if inline is not None else ""
            elif raw is None:
                value = None
            elif kind == "s":
                value = strings[int(raw.text)]
            elif kind == "b":
                value = raw.text == "1"
            elif kind in ("str", "e"):
                value = raw.text
            else:
                number = float(raw.text)
                value = int(number) if number.is_integer() else number
            values[column] = value
        if any(value is not None for value in values.values()):
            result.append(values)
    return result


def read_workbook(path: Path) -> dict[str, list[dict]]:
    if hashlib.sha256(path.read_bytes()).hexdigest() != WORKBOOK_SHA256:
        raise ValueError("campaign workbook SHA-256 changed; review the new sheet before applying")
    with zipfile.ZipFile(path) as archive:
        strings = []
        if "xl/sharedStrings.xml" in archive.namelist():
            shared = ET.fromstring(archive.read("xl/sharedStrings.xml"))
            strings = ["".join(item.itertext()) for item in shared.findall("m:si", NAMESPACE)]
        relationships = {
            row.attrib["Id"]: row.attrib["Target"]
            for row in ET.fromstring(archive.read("xl/_rels/workbook.xml.rels"))
        }
        book = ET.fromstring(archive.read("xl/workbook.xml"))
        requested = {"关卡总览", "逐关设计", "敌方配置", "掉落与奖励"}
        sheets = {}
        for sheet in book.findall("m:sheets/m:sheet", NAMESPACE):
            name = sheet.attrib["name"]
            if name not in requested:
                continue
            target = relationships[sheet.attrib[RELATIONSHIP]]
            member = target.lstrip("/") if target.startswith("/") else posixpath.normpath("xl/" + target)
            sheets[name] = _sheet_rows(archive, member, strings)
    if set(sheets) != requested:
        raise ValueError(f"campaign workbook missing required sheets: {requested - set(sheets)}")
    return sheets


def _data_rows(rows: list[dict]) -> list[dict]:
    return [row for row in rows if row.get("A") in ("普通", "精英", "活动", "探险当前地图")]


def _group(rows: list[dict]) -> dict[tuple[str, str], list[dict]]:
    grouped = defaultdict(list)
    for row in _data_rows(rows):
        grouped[(row["A"], str(row["D"]))].append(row)
    return dict(grouped)


def _native_snapshot_power(cfg: dict, units: list[dict]) -> int:
    """The same Avatar.getPower terms used by GameplayCompetition._team_power."""
    power = cfg["system_simple"].get("power", [])
    if not isinstance(power, list) or len(power) < 13:
        power = [1e-8, .5, 2, .625, .625, 1000, .1, .1, .5, .01, 2, .1, .1]

    def skill_factor(skill: dict | None, *, super_skill=False, book=False, level=1) -> float:
        if not isinstance(skill, dict) or not isinstance(skill.get("skid"), str):
            return 0.0
        sid = skill["skid"]
        try:
            star = max(1, int(sid.split("_")[-1]))
        except ValueError:
            star = 1
        level = max(1, int(skill.get("slv", level) or level))
        if book:
            actions = cfg.get("skill", {}).get(sid, {}).get("skill", [])
            if actions and isinstance(actions[0], (list, tuple)) and actions[0] and actions[0][0] == "equipup":
                return 0.0
            return star * float(power[11]) + level * float(power[12])
        if super_skill:
            return star * .5
        return star * .1 + level * .1

    total = 0
    for unit in units:
        tpl = unit.get("tpl", [])
        attrs = unit.get("new_4attrs", {})
        weighted = (unit["hp_max"] * float(power[1]) + unit["ap"] * float(power[2])
                    + unit["de_ph"] * float(power[3]) + unit["de_ma"] * float(power[4]))
        substats = sum(float(attrs.get(key, 0)) for key in ("hit", "flee", "crit", "tough"))
        skill = (1 + skill_factor(unit.get("skill"), level=unit.get("slv", 1))
                 + skill_factor(unit.get("leader_skill"), super_skill=True)
                 + skill_factor(unit.get("book_skill"), book=True)
                 + skill_factor(unit.get("skillB")))
        factor = 1 + math.pow(max(0, substats), 1 / float(power[10])) * float(power[9])
        value = (weighted ** 2) * skill * (float(power[5]) + tpl[3] + tpl[4]) * factor * float(power[0])
        if math.isfinite(value) and value > 0:
            total += math.floor(value)
    return int(total)


def _power(cfg: dict, team: list[list], rows: list[dict]) -> int:
    units = serialize_stage_team(cfg, team, team=2)
    if len(units) != len(rows):
        raise ValueError("power snapshot does not match enemy roster length")
    for unit, row in zip(units, rows):
        if unit["aid"] != row["aid"]:
            raise ValueError("power snapshot does not match enemy roster order")
        for key in STAT_KEYS:
            unit[key] = int(row[key])
        unit["hp_max"] = unit["hp"]
        unit["new_4attrs"] = {key: int(row.get(key, 0)) for key in ("hit", "flee", "crit", "tough")}
    return _native_snapshot_power(cfg, units)


def _scaled_rows(base: list[dict], factor: float, locked: set[int]) -> list[dict]:
    output = copy.deepcopy(base)
    for index, row in enumerate(output):
        if index in locked:
            continue
        for key in STAT_KEYS:
            row[key] = max(1, round(base[index][key] * factor))
    return output


def _fit_power(cfg: dict, team: list[list], base: list[dict], target: int,
               locked: set[int] | None = None) -> tuple[list[dict], int]:
    locked = locked or set()
    low, high = 0.001, 1.0
    while _power(cfg, team, _scaled_rows(base, high, locked)) < target and high < 1024:
        high *= 2
    if _power(cfg, team, _scaled_rows(base, high, locked)) < target:
        raise ValueError("cannot reach campaign power target within stat scale bound")
    for _ in range(28):
        mid = (low + high) / 2
        if _power(cfg, team, _scaled_rows(base, mid, locked)) < target:
            low = mid
        else:
            high = mid
    candidates = [_scaled_rows(base, value, locked) for value in (low, high)]
    return min(((rows, _power(cfg, team, rows)) for rows in candidates),
               key=lambda item: abs(item[1] - target))


def _target(chapter: int, stage_no: int, final_no: int, orange_reference: int) -> int:
    band = (chapter - 1) // 5
    chapter_fraction = ((chapter - 1) % 5) / 4
    chapter_base = orange_reference * BAND_RATIOS[band] * (0.96 + 0.08 * chapter_fraction)
    if stage_no == final_no:
        return round(chapter_base * FINALE_MULTIPLIER)
    return round(chapter_base * (0.985 + 0.03 * (stage_no - 1) / max(1, final_no - 2)))


def _hard_target(chapter: int, stage_no: int, final_no: int,
                 normal_target: int, references: dict) -> int:
    if chapter <= 15:
        return round(normal_target * 1.16)
    if chapter <= 20:
        anchor = references["two_orange_items_lv125"]
    elif chapter <= 25:
        anchor = references["two_orange_items_lv125"] * 1.17
    else:
        anchor = references["three_orange_items_lv125_full_wash"] * 1.10
    chapter_fraction = ((chapter - 1) % 5) / 4
    chapter_base = anchor * (0.96 + 0.08 * chapter_fraction)
    if stage_no == final_no:
        return round(chapter_base * FINALE_MULTIPLIER)
    return round(chapter_base * (0.985 + 0.03 * (stage_no - 1) / max(1, final_no - 2)))


def _stage_unit_rows(sheet_rows: list[dict], overview: dict, cfg: dict,
                     old_team: list[list]) -> tuple[list[list], list[dict]]:
    ordered = sorted(sheet_rows, key=lambda row: row["E"])
    if [row["E"] for row in ordered] != list(range(1, len(ordered) + 1)):
        raise ValueError(f"{overview['D']}: non-contiguous workbook unit order")
    if len(ordered) != overview["F"] or len(ordered) < overview["I"]:
        raise ValueError(f"{overview['D']}: workbook roster/count mismatch")
    if sum(row["H"] == "英雄" for row in ordered) != overview["G"]:
        raise ValueError(f"{overview['D']}: workbook hero count mismatch")
    if sum(bool(row["O"]) for row in ordered) != 1:
        raise ValueError(f"{overview['D']}: workbook requires one leader")
    old_by_aid = defaultdict(list)
    for old in old_team:
        old_by_aid[old[0]].append(old)
    team, stats = [], []
    occupied = set()
    seen_positions = set()
    for index, row in enumerate(ordered):
        aid, level, slv = row["F"], row["J"], row["K"]
        if aid not in cfg["avatar"] or type(level) is not int or not 1 <= level <= 99 or type(slv) is not int or slv < 1:
            raise ValueError(f"{overview['D']}: invalid configured enemy at unit {index + 1}")
        lane, pos, side = row["L"] - 1, float(row["M"]), float(row["Y"])
        if not 0 <= lane < overview["I"] or not 0 < pos <= 0.5 or abs(side) > 0.5:
            raise ValueError(f"{overview['D']}: unit {index + 1} outside native formation bounds")
        # Same depth is valid only when the explicit lateral coordinates differ.
        footprint = (lane, round(pos * 3000), round(side * 1000))
        if footprint in seen_positions:
            raise ValueError(f"{overview['D']}: two enemies occupy the same point")
        seen_positions.add(footprint)
        occupied.add(lane)
        previous = old_by_aid[aid].pop(0) if old_by_aid[aid] else None
        drop_rate = previous[6] if previous and len(previous) > 6 else 0
        reach = row["U"]
        team.append([aid, level, slv, lane, pos, int(bool(row["O"])), drop_rate, 0, "", None, None, side, reach])
        values = {"index": index, "aid": aid, "hp": int(row["P"]), "ap": int(row["Q"]),
                  "de_ph": int(row["R"]), "de_ma": int(row["S"]),
                  "hit": 0, "flee": 0, "crit": 0, "tough": 0}
        if any(values[key] < 1 for key in STAT_KEYS):
            raise ValueError(f"{overview['D']}: nonpositive workbook enemy stats")
        stats.append(values)
    if occupied != set(range(overview["I"])):
        raise ValueError(f"{overview['D']}: workbook leaves an empty native lane")
    return team, stats


def _hero_drop_candidates(team: list[list], cfg: dict, diff: int) -> list[dict]:
    blocked = set(cfg["system_simple"].get("skin_acquisition_blocked_heroes", []))
    avatars = cfg["avatar"]
    enemy_families = {}
    for row in team:
        aid = row[0]
        if re.fullmatch(r"A_1\d{3}_[2-6]", aid) and aid not in blocked:
            enemy_families.setdefault(aid.rsplit("_", 1)[0], aid)
    result = []
    for family, enemy_aid in sorted(enemy_families.items()):
        enemy_star = int(enemy_aid.rsplit("_", 1)[-1])
        configured = sorted((int(aid.rsplit("_", 1)[-1]), aid) for aid in avatars
                            if re.fullmatch(re.escape(family) + r"_[2-6]", aid) and aid not in blocked)
        lower = [value for value in configured if value[0] < enemy_star]
        chosen = lower[-1] if lower else configured[0] if enemy_star == 6 and len(configured) == 1 else None
        if chosen is None:
            continue
        star, aid = chosen
        chance = 100 if star == 5 else 20 if star == 6 else 2500 if diff else 1500
        result.append({"family": family, "enemy_aid": enemy_aid, "aid": aid,
                       "star": star, "chance_bp": chance})
    return result


def _reward_matches(stage: dict, row: dict) -> bool:
    reward = stage.get("reward", {})
    try:
        attrs = json.loads(row["G"])
        first = json.loads(row["H"]) if row.get("H") else None
        heroes = json.loads(row["I"]) if row.get("I") else []
        items = json.loads(row["J"]) if row.get("J") else []
    except (TypeError, ValueError) as exc:
        raise ValueError(f"{row['D']}: malformed workbook reward JSON") from exc
    stage_gold = reward.get("gold", stage.get("gold"))
    stage_exp = reward.get("exp", stage.get("exp"))
    return (stage_gold == row["E"] and stage_exp == row["F"]
            and reward.get("attrs", {}) == attrs
            and (reward.get("first_clear") or {}) == (first or {})
            and reward.get("heroes", []) == heroes
            and reward.get("items", []) == items)


def _apply_reward(stage: dict, row: dict) -> None:
    reward = stage.setdefault("reward", {})
    reward["gold"], reward["exp"] = row["E"], row["F"]
    reward["attrs"] = json.loads(row["G"])
    for field, column in (("first_clear", "H"), ("heroes", "I"), ("items", "J")):
        value = json.loads(row[column]) if row.get(column) else None
        if value:
            reward[field] = value
        else:
            reward.pop(field, None)
    if "gold" in stage:
        stage["gold"] = row["E"]
    if "exp" in stage:
        stage["exp"] = row["F"]
    stage["reward_note"] = row.get("K") or stage.get("reward_note")


def apply_campaign_workbook(full_config: dict, workbook: Path) -> tuple[dict, dict]:
    """Return an isolated full-config candidate and a compact evidence report."""
    sheets = read_workbook(Path(workbook))
    overviews = _group(sheets["关卡总览"])
    designs = _group(sheets["逐关设计"])
    units = _group(sheets["敌方配置"])
    rewards = _group(sheets["掉落与奖励"])
    if not all(set(table) == set(overviews) for table in (designs, units, rewards)) or len(overviews) != 285:
        raise ValueError("campaign workbook must contain exactly the same 285 mode/stage keys on all source sheets")
    output = copy.deepcopy(full_config)
    pve, cfg = output["pve"], output["cfg"]
    main, activities = pve["combat_main"], pve["combat_ploy"]
    exploration = {str(row["id"]): row for row in pve["modes"]["exploration"]["stages"]}
    references = pve["campaign_overlay"]["policy_53"]["difficulty_calibration"]["references_native_power"]
    reference = references["bare_orange_lv99"]
    if not isinstance(reference, int) or reference < 1:
        raise ValueError("missing reviewed bare-orange chapter anchor")
    if len(main) != 135 or len(activities) != 3 or len(exploration) != 12:
        raise ValueError("source config campaign stage counts changed")
    reward_mismatches = []
    power_stats = defaultdict(list)
    for key, overview_rows in overviews.items():
        mode, stage_id = key
        if len(overview_rows) != 1 or len(designs[key]) != 1 or len(rewards[key]) != 1:
            raise ValueError(f"{key}: duplicate workbook stage metadata")
        overview, design, reward_row = overview_rows[0], designs[key][0], rewards[key][0]
        if mode in ("普通", "精英"):
            stage = main.get(stage_id)
        elif mode == "活动":
            stage = activities.get(stage_id)
        else:
            stage = exploration.get(stage_id)
        if stage is None:
            raise ValueError(f"{key}: no current PVE stage")
        if not _reward_matches(stage, reward_row):
            reward_mismatches.append(f"{mode}:{stage_id}")
        _apply_reward(stage, reward_row)
        old_team = stage["team2"]
        team, stats = _stage_unit_rows(units[key], overview, cfg, old_team)
        if mode == "普通":
            chapter, stage_no = int(stage_id[2:5]), int(stage_id[6:])
            final_no = 6 if chapter <= 15 else 3
            target = _target(chapter, stage_no, final_no, reference)
            calibrated, actual = _fit_power(cfg, team, stats, target)
            stage["team2"] = team
            stage.setdefault("enemy_unit_stats_by_diff", {})["0"] = calibrated
            stage["recommended_power"] = actual
            stage.setdefault("recommended_power_by_diff", {})["0"] = actual
            stage["recommended_power_source"] = "actual normal enemy snapshot, calibrated to five-chapter band and chapter finale"
            stage.setdefault("hero_drop_candidates_by_diff", {})["0"] = _hero_drop_candidates(team, cfg, 0)
            stage["name"] = overview["E"]
            stage["campaign_scene"] = design["G"]
            stage["campaign_observation"] = design["J"]
            pve["battle_main"][f"M_{chapter:03d}"]["name"] = design["F"]
            power_stats["normal"].append((stage_id, target, actual))
        elif mode == "精英":
            chapter, stage_no = int(stage_id[2:5]), int(stage_id[6:])
            stage.setdefault("team2_by_diff", {})["1"] = team
            final_no = 6 if chapter <= 15 else 3
            target = _hard_target(chapter, stage_no, final_no,
                                  stage["recommended_power_by_diff"]["0"], references)
            # Keep the workbook's unit and four-stat proportions. The power
            # anchor is for the actual whole team, so an individual hero's old
            # gear snapshot cannot force a hidden spike in one stage.
            calibrated, actual = _fit_power(cfg, team, stats, target)
            stage["enemy_unit_stats_by_diff"]["1"] = calibrated
            stage["recommended_power_by_diff"]["1"] = actual
            stage["hero_drop_candidates_by_diff"]["1"] = _hero_drop_candidates(team, cfg, 1)
            stage["campaign_elite_observation"] = design["K"]
            power_stats["hard"].append((stage_id, target, actual))
        else:
            stage["team2"] = team
            stage["name"] = overview["E"]
            stage["campaign_scene"] = design["G"]
            stage["campaign_observation"] = design["J"]
            stage["enemy_unit_stats_by_diff"] = {"0": stats}
            if mode == "探险当前地图":
                stage["campaign_workbook_fixed"] = True
    # Main stages were populated in workbook order (normal then elite each
    # stage), so every hard calibration used its newly calibrated normal value.
    metadata = pve.setdefault("campaign_overlay", {}).setdefault("workbook_narrative", {})
    metadata.update({"schema": "campaign-workbook-narrative-v1", "workbook_sha256": WORKBOOK_SHA256,
                     "recommended_power_column": "ignored old baseline",
                     "normal_band_ratios_to_bare_orange": list(BAND_RATIOS),
                     "early_player_reference_power": {"five_green_level_1": 1444, "five_blue_level_60": 64156},
                     "chapter_band_rise": "8 percent across five chapters",
                     "finale_to_regular_target": FINALE_MULTIPLIER,
                     "hard_team_anchors": "chapters 1-15: 1.16x normal; 16-20: two-orange-item reference; 21-25: 1.17x two-item reference; 26-30: 1.10x three-item full-wash reference; fitted across actual whole-team snapshots"})
    report = {"workbook_sha256": WORKBOOK_SHA256, "stage_modes": {"normal": 135, "hard": 135, "activity": 3, "exploration": 12},
              "enemy_rows": sum(len(value) for value in units.values()), "source_reward_differences": reward_mismatches,
              "power": {mode: {"min": min(a for _, _, a in values), "max": max(a for _, _, a in values),
                               "max_target_error_pct": round(max(abs(a - t) / t for _, t, a in values) * 100, 4)}
                        for mode, values in power_stats.items()}}
    # Config is served from cfg.* while gameplay historically resolves the
    # top-level tables first. Publish the authored PVE tables to both native
    # consumers; otherwise they silently keep the pre-workbook enemy rosters.
    for table in ("battle_main", "combat_main", "battle_ploy", "combat_ploy"):
        output[table] = copy.deepcopy(pve[table])
        cfg[table] = copy.deepcopy(pve[table])
    return output, report


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path, required=True)
    parser.add_argument("--workbook", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    source = json.loads(args.config.read_text(encoding="utf-8-sig"))
    candidate, report = apply_campaign_workbook(source, args.workbook)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(candidate, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
