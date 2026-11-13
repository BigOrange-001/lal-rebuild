"""Persistent, isolated Kai'Sa playtest save with native campaign target stages."""
from __future__ import annotations

import argparse
import copy
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "server"))
from gateway import Backend, Handler, make_server
from gameplay_common import grant_reward

ACCOUNT = "kaisa"
PASSWORD = "123456"
PLAYTEST_REVISION = 3


class PlaytestHandler(Handler):
    def do_GET(self):
        if self.path == "/kaisa-playtest":
            body = json.dumps({"ready": True, "fixture": "kaisa-20261112", "revision": PLAYTEST_REVISION, "hero": "A_1801_6"}).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
            return
        super().do_GET()


def targets(config):
    """Alter only this disposable server's first chapter, never production files."""
    cfg = config["cfg"]
    dummy_id = "A_1880_3"
    dummy = copy.deepcopy(cfg["avatar"]["A_1001_3"])
    dummy.update(id=dummy_id, name="训练靶")
    # Keep native hero identity for Hunt targeting, but remove the original
    # Garen's silence/shields so only Kai'Sa and the two stun allies cast.
    dummy["pl"][10:14] = [None, None, dummy["pl"][12], None]
    cfg["avatar"][dummy_id] = dummy
    cfg["battle_main"]["M_001"]["name"] = "卡莎技能测试场"
    cases = [
        ("弹体分配：2名目标", [2], 3000000),
        ("弹体分配：3名目标", [3], 3000000),
        ("跨路狩猎：三路靶场", [4, 3, 3], 6000000),
        ("逐发索敌：低血前排", [4], 3000000),
        ("电浆与分身：耐久靶场", [3, 3, 3], 12000000),
        ("长时间叠弹：三路靶场", [4, 4, 4], 30000000),
    ]
    for number, (name, lanes, health) in enumerate(cases, 1):
        stage = cfg["combat_main"][f"M_001_{number}"]
        team, stats = [], []
        for lane, count in enumerate(lanes):
            for slot in range(count):
                aid = dummy_id
                team.append([aid, 1, 1, lane, .56 - slot * .11, 0, 0, 0, "", None, None, (slot % 2 * 2 - 1) * .22, 300])
                stats.append(dict(index=len(stats), aid=aid, hp=(1200 if number == 4 and slot == 0 else health),
                                  ap=80, de_ph=0, de_ma=0, hit=0, flee=0, crit=0, tough=0))
        stage.update(name=name, line=[len(lanes), ["m014"] * len(lanes)], team1=[], team2=team,
                     team2_by_diff={"1": copy.deepcopy(team)},
                     enemy_unit_stats_by_diff={"0": copy.deepcopy(stats), "1": copy.deepcopy(stats)},
                     energy=0, limit=[9999, 9999, 9999], win=[-1], pre=[], recommended_power=0,
                     recommended_power_by_diff={"0": 0, "1": 0})
    config["kaisa_playtest"] = {"isolated": True, "firstChapter": "M_001"}
    for container in (config, config.get("pve", {})):
        for table in ("battle_main", "combat_main"):
            if table in container:
                container[table] = copy.deepcopy(cfg[table])


def prepare(work):
    work.mkdir(parents=True, exist_ok=True)
    backend = Backend(work / "卡莎测试存档.sqlite3", ROOT / "config/reconstruction/full-config.json", work / "mods")
    targets(backend.config)
    # Mod/config replies own a frozen base copy. Rebind that service to the
    # disposable tables too, so the UI and battle authority see the same maps.
    from mod_service import ModService
    backend.mods = ModService(backend.players, backend.config, work / "mods")
    # No account from any existing game database is opened or copied.
    exists = backend.db.execute("SELECT 1 FROM accounts WHERE name=?", (ACCOUNT,)).fetchone()
    credentials = {"pf": "local", "session_key": ACCOUNT, "sessionid": PASSWORD}
    if not exists:
        result = backend.call({"method": "user.register", "params": dict(credentials, actionID="kaisa-register")})
        if result["return_code"] != 0:
            raise RuntimeError(result)
    result = backend.call({"method": "user.login", "params": dict(credentials, actionID="kaisa-login")})
    if result["return_code"] != 0:
        raise RuntimeError(result)
    uid = result["data"]["uid"]
    if not backend.players.profile(uid).get("kaisa_playtest_seeded"):
        def seed(profile):
            grant_reward(profile, {"heroes": [{"aid": "A_1801_6", "num": 2},
                                               {"aid": "A_1133_6", "num": 1},
                                               {"aid": "A_1020_6", "num": 1}]}, backend.config, allow_skin=True)
            selected, kaisas = {}, []
            for iid, hero in profile["avatars"].items():
                aid = str(hero.get("aid", iid)).split("|")[0]
                if aid in ("A_1801_6", "A_1133_6", "A_1020_6"):
                    rank = (1 if not kaisas else 10) if aid == "A_1801_6" else 1
                    hero.update(lv=99 if aid == "A_1801_6" else 50, slv=rank, phase=0,
                                hp=0, ap=0, de_ph=0, de_ma=0)
                    if aid == "A_1801_6":
                        kaisas.append(iid)
                    selected.setdefault(aid, iid)
            profile["team"][0] = [selected[k] for k in ("A_1801_6", "A_1133_6", "A_1020_6")] + [None] * 3
            profile["as_equips"] = [[None] * 6 for _ in range(6)]
            profile.update(name="卡莎技能测试", lv=99, coin=10000000, gold=10000000, score=1000000,
                           cid="M_001_6", hid="M_001_6", kaisa_playtest_seeded=True)
            profile.setdefault("attrs", {}).update(team_num=0, avatar_len=1000)
            return profile, {"kaisas": kaisas}
        backend.players.atomic_update(uid, seed)
    return backend, uid


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--work", type=Path, required=True)
    parser.add_argument("--port", type=int, default=18084)
    parser.add_argument("--setup-only", action="store_true")
    args = parser.parse_args()
    backend, uid = prepare(args.work.resolve())
    if args.setup_only:
        p = backend.players.profile(uid)
        print(json.dumps({"uid": uid, "team": p["team"][0], "isolated": True,
                          "stageNames": [backend.config["cfg"]["combat_main"][f"M_001_{n}"]["name"] for n in range(1, 7)]}, ensure_ascii=False))
        return 0
    service = make_server("127.0.0.1", args.port, backend)
    service.RequestHandlerClass = PlaytestHandler
    print(f"Kai'Sa playtest ready: http://127.0.0.1:{args.port}/health", flush=True)
    try:
        service.serve_forever()
    finally:
        service.server_close()
        backend.db.close()
        backend.clock.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
