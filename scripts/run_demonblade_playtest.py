"""Serve a disposable Demonblade workshop from a copy of a local test save."""
from __future__ import annotations

import argparse
from copy import deepcopy
import json
from pathlib import Path
import sqlite3
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "server"))

from demonblade_tryndamere_105 import AID, FIVE_STAR_AID
from gateway import Backend, make_server
from mod_service import ModService

CONFIG = ROOT / "config/reconstruction/full-config.json"
HEROES = {FIVE_STAR_AID: 1, AID: 1}
MAIL_KEY = "demonblade-tryndamere-bonds-playtest-v1"
DUMMY = "A_1891_3"
SUMMON = "A_2891_5"
CASES = (
    ("基础对照 · 普攻与装备", (DUMMY,), 30),
    ("蛮易信三兄弟 · 英雄与召唤物", (DUMMY, SUMMON, DUMMY), 30),
    ("凛冬怒火 · 怒气获取与上限", (DUMMY, DUMMY, DUMMY), 300),
    ("狂怒恶魔 · 诅咒与多目标", (DUMMY, DUMMY, DUMMY), 30),
    ("完整羁绊 · 综合实战", (DUMMY, SUMMON, DUMMY), 300),
)


def add_encounters(document):
    cfg = document["cfg"]
    for template, aid, name in [
        ("A_1001_3", DUMMY, "英雄靶"),
        ("A_2019_5", SUMMON, "召唤物靶"),
    ]:
        row = deepcopy(cfg["avatar"][template])
        row.update(id=aid, name=name)
        row["pl"][10:14] = [None, None, None, None]
        cfg["avatar"][aid] = row

    chapter = cfg["battle_main"]["M_001"]
    chapter.update(name="恶魔之刃 · 羁绊测试场", combat=len(CASES))
    stages = cfg["combat_main"]
    for number, (title, formation, attack) in enumerate(CASES, 1):
        cid = f"M_001_{number}"
        stage = stages[cid]
        enemies = [[aid, 1, 1, 0, position, 0, 0, 0, "", None, None, 0, 300]
                   for aid, position in zip(formation, (.51, .56, .61))]
        stats = [dict(index=i, aid=aid, hp=500_000, ap=attack, de_ph=0, de_ma=0,
                      hit=100_000, flee=0, crit=0, tough=0)
                 for i, aid in enumerate(formation)]
        stage.pop("hero_drop_candidates_by_diff", None)
        stage.update(name=title, line=[1, ["m014"]], team1=[], team2=enemies,
                     team2_by_diff={"1": deepcopy(enemies)}, energy=0,
                     enemy_unit_stats_by_diff={"0": stats, "1": deepcopy(stats)},
                     limit=[9999, 9999, 9999], unlimited_attempts=True,
                     win=[-1], pre=[], recommended_power=0,
                     recommended_power_by_diff={"0": 0, "1": 0})
    for container in (document, document.get("pve", {})):
        for table in ("battle_main", "combat_main"):
            if table in container:
                container[table] = deepcopy(cfg[table])


def prepare(source, work, account):
    work.mkdir(parents=True, exist_ok=True)
    database = work / "demonblade-playtest.sqlite3"
    if not database.exists():
        if not source.is_file():
            raise FileNotFoundError(source)
        with sqlite3.connect(source.resolve().as_uri() + "?mode=ro", uri=True) as original:
            with sqlite3.connect(database) as backup:
                original.backup(backup)
    backend = Backend(database, CONFIG, work / "mods")
    add_encounters(backend.config)
    backend.mods = ModService(backend.players, backend.config, work / "mods")
    row = backend.db.execute("SELECT uid FROM players WHERE account=?", (account,)).fetchone()
    if row is None:
        raise ValueError("The requested test account is missing from the source save")
    uid, = row

    def unlock(profile):
        for key in ("cid", "hid"):
            progress = profile.get(key, "M_001_1")
            if tuple(map(int, progress.split("_")[1:])) < (1, len(CASES)):
                profile[key] = f"M_001_{len(CASES)}"
        return profile, None

    backend.players.atomic_update(uid, unlock)
    mail = backend.players.send_mail(account, "恶魔之刃泰达米尔 · 五星与六星测试卡",
                                     {"avatar": HEROES}, MAIL_KEY, allow_skin=True)
    receipt = backend.db.execute("SELECT gifts FROM gift_mail WHERE id=? AND uid=?", (mail, uid)).fetchone()
    if receipt is None or json.loads(receipt[0]) != {"avatar": HEROES}:
        raise RuntimeError("The test mail does not contain exactly one card of each quality")
    return backend, uid, mail


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--save", type=Path, required=True)
    parser.add_argument("--work", type=Path, required=True)
    parser.add_argument("--account", required=True)
    parser.add_argument("--port", type=int, default=18087)
    parser.add_argument("--setup-only", action="store_true")
    args = parser.parse_args()
    backend, _, mail = prepare(args.save, args.work, args.account)
    try:
        number = len(CASES)
        receipt = {"account": args.account, "mail": mail, "heroes": HEROES,
                   "chapter": "M_001", "stages": {f"M_001_{i}": CASES[i - 1][0]
                                                 for i in range(1, number + 1)},
                   "port": args.port}
        print(json.dumps(receipt, ensure_ascii=False), flush=True)
        if not args.setup_only:
            with make_server("127.0.0.1", args.port, backend) as service:
                service.serve_forever()
    finally:
        backend.db.close()
        backend.clock.close()


if __name__ == "__main__":
    main()
