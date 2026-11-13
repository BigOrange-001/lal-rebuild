"""Isolated, persistent full-roster test account; never opens a production save."""
from __future__ import annotations

import argparse
import copy
import json
from pathlib import Path

from run_kaisa_playtest import ACCOUNT, PASSWORD, prepare as prepare_kaisa
from gateway import Handler, make_server
from gameplay_common import grant_reward, equipment_exclusive_ids
from cultivation_rules import cap, used, WEIGHTS, SCHEMA
from equipment_growth_v2 import effective_cap

MARKER = "full_roster_playtest_20261113"
FIXTURE = "full-roster-20261113"


def highest_families(definitions, predicate):
    selected = {}
    for key, row in definitions.items():
        if not predicate(key, row):
            continue
        family, quality = key.rsplit("_", 1)
        if family not in selected or int(quality) > int(selected[family].rsplit("_", 1)[1]):
            selected[family] = key
    return sorted(selected.values())


def prepare(work):
    backend, uid = prepare_kaisa(work)
    cfg = backend.config["cfg"]
    simple = cfg["system_simple"]
    heroes = highest_families(cfg["avatar"], lambda key, row:
        key.startswith("A_1") and len(key.split("_")[1]) == 4
        and int(key.rsplit("_", 1)[1]) >= 5 and row.get("name")
        and "序号" not in row["name"])
    equipment = highest_families(cfg["equip"], lambda key, row: int(row.get("type", 0)) in (1, 3, 4, 5, 6))

    def seed(profile):
        if profile.get(MARKER):
            return profile, profile[MARKER]
        original_heroes = set(profile["avatars"])
        original_equipment = set(profile["my_equips"])
        original_team = copy.deepcopy(profile.get("team"))
        original_loadouts = copy.deepcopy(profile.get("as_equips"))
        profile.setdefault("attrs", {})["avatar_len"] = 1000
        grant_reward(profile, {"heroes": [{"aid": aid, "num": 1} for aid in heroes],
                               "items": [{"eid": eid, "num": 6} for eid in equipment]},
                     backend.config, allow_skin=True, allow_equipment_exclusive=True)
        account_cap = int(simple["exp_config"][3])
        profile.update(lv=account_cap, exp=0, vip_lv=15, vip_exp=int(cfg["vip"]["15"]["exp"]))
        gear_level = effective_cap(account_cap, 15 * 3)
        # A max-rank personal attack talent suits both new damage dealers.
        talents = [r for r in cfg.get("talent", {}).values()
                   if r.get("rank") == 7 and r.get("growth_effect") == "attack"]
        talent = sorted(talents, key=lambda r: r["id"])[0]["id"] if talents else None
        added = {}
        for iid in sorted(set(profile["avatars"]) - original_heroes):
            hero = profile["avatars"][iid]
            aid = hero["aid"].split("|", 1)[0]
            hero.update(lv=125, slv=10, exp=0, phase=3, limit_break=1, lock=True,
                        culture_schema=SCHEMA)
            budget = cap(hero, simple)
            for key, weight in WEIGHTS.items():
                hero[key] = (budget // 4) // weight
            hero["hp"] += budget - used(hero, simple)
            if talent:
                hero["talent"] = talent
            assert used(hero, simple) == cap(hero, simple)
            added[aid] = iid
        exclusive = set(equipment_exclusive_ids(cfg))
        gear_by_id = {}
        max_star = int(simple["equip_alchemy"]["star_lv"])
        halo_cap = int(simple["equipwash"][5])
        for eqid in sorted(set(profile["my_equips"]) - original_equipment, key=lambda s: int(s[2:])):
            item = profile["my_equips"][eqid]
            eid = item["eid"]
            row = cfg["equip"][eid]
            quality = int(eid.rsplit("_", 1)[1])
            star = max(max_star, quality)
            is_book = int(row["type"]) == 6
            item.update(lv=gear_level, slv=10 if is_book else 0, sexp=0,
                        alchemy=[0, star - quality], magic=[100] * 4, magic_stage5=1,
                        symp=1, rune_lv=int(simple["equipment_magic"]["rune_max"]),
                        halo={"lv": halo_cap, "exp": 0}, haloLv=halo_cap, haloExp=0,
                        stat_roll_ppm=1_000_000 if is_book else (1_200_000 if eid in exclusive else 1_150_000),
                        equipment_v2_version=1, wash_schema_version=1, lock=True)
            pair = row.get("pl", [])[6:8]
            wash = {key: 0 for key in ("hit", "flee", "crit", "tough")}
            if len(pair) == 2 and pair[0] in wash and pair[1] in wash and pair[0] != pair[1]:
                budget = int(simple["equip_config"][3]) * star * gear_level
                wash[pair[0]] = budget // 2
                wash[pair[1]] = budget - budget // 2
            item["new_4attrs"] = wash
            gear_by_id.setdefault(eid, []).append(eqid)
        # Six position-based sets remain equipped when the player swaps heroes.
        loadout = ["E_1011_6", "E_1019_6", "E_3001_6", "E_4007_6", "E_5009_6", "E_6005_7"]
        profile["as_equips"] = [[gear_by_id[eid][slot] for eid in loadout] for slot in range(6)]
        yasuo, kaisa = added["A_1802_6"], added["A_1801_6"]
        others = [iid for aid, iid in sorted(added.items()) if aid not in ("A_1801_6", "A_1802_6")]
        squads = copy.deepcopy(profile.get("team", []))
        while len(squads) < 3:
            squads.append([None] * 6)
        squads[0] = [yasuo] + others[:5]
        squads[1] = [kaisa] + others[5:10]
        profile["team"] = squads
        profile["attrs"]["team_num"] = 0
        receipt = {"fixture": FIXTURE, "account": ACCOUNT, "uid": uid,
                   "heroCount": len(added), "equipmentCount": len(equipment) * 6,
                   "equipmentFamilies": len(equipment), "heroLevel": 125, "skillLevel": 10,
                   "heroPhase": 3, "equipmentLevel": gear_level, "equipmentStar": max_star,
                   "heroInstances": added, "originalTeam": original_team,
                   "originalEquipmentLoadouts": original_loadouts,
                   "originalHeroInstances": sorted(original_heroes),
                   "originalEquipmentInstances": sorted(original_equipment),
                   "talent": talent, "loadout": loadout}
        profile[MARKER] = receipt
        return profile, receipt

    receipt, _ = backend.players.atomic_update(uid, seed)
    return backend, uid, receipt


class FullRosterHandler(Handler):
    def do_GET(self):
        if self.path == "/full-roster-playtest":
            body = json.dumps({"ready": True, "fixture": FIXTURE, "revision": 1,
                               **self.server.playtest_summary}, ensure_ascii=False).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        super().do_GET()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--work", type=Path, required=True)
    parser.add_argument("--port", type=int, default=18084)
    parser.add_argument("--setup-only", action="store_true")
    args = parser.parse_args()
    backend, uid, receipt = prepare(args.work.resolve())
    summary = {key: value for key, value in receipt.items()
               if key not in ("heroInstances", "originalTeam", "originalEquipmentLoadouts", "originalHeroInstances", "originalEquipmentInstances")}
    (args.work / "全卡发放清单.json").write_text(json.dumps(receipt, ensure_ascii=False, indent=2), "utf-8")
    if args.setup_only:
        print(json.dumps(summary, ensure_ascii=False))
        backend.db.close()
        backend.clock.close()
        return 0
    service = make_server("127.0.0.1", args.port, backend)
    service.RequestHandlerClass = FullRosterHandler
    service.playtest_summary = summary
    print(f"Full roster test ready: http://127.0.0.1:{args.port}/full-roster-playtest", flush=True)
    try:
        service.serve_forever()
    finally:
        service.server_close()
        backend.db.close()
        backend.clock.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
