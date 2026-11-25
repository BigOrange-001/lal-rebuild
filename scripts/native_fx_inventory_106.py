"""Per-hero native effect inventory for docs/native-fx-wiring-106.md.

Builds the runtime tables (gateway.build_static_config), resolves every skill
action's effect name to its effectDB armatures and rewrites the table between
the BEGIN/END markers of the doc.  Usage:

    python scripts/native_fx_inventory_106.py          # print the table
    python scripts/native_fx_inventory_106.py --write  # update the doc
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "server"))
DOC = ROOT / "docs/native-fx-wiring-106.md"
BEGIN, END = "<!-- BEGIN HERO TABLE -->", "<!-- END HERO TABLE -->"

# Heroes whose skills are drawn by the hero-fx-106 code effects (heroFxClaim106
# and the earlier exclusive effect files).  Their native names stay untouched.
CODE_COVERED = {
    "A_1132": "劫（A 组）", "A_1139": "卡尔玛（A 组）", "A_1228": "DJ娑娜（A 组）",
    "A_1214": "逆转裁判崔斯特（A 组）", "A_1209": "兔宝宝提莫（A 组）", "A_1204": "苹果机器人布里茨（A 组）",
    "A_1213": "足球先生伊泽瑞尔（A 组）", "A_1138": "塔姆（B 组）", "A_1103": "马尔扎哈与虚灵（B 组）",
    "A_1215": "龙的传人李青（B 组）", "A_1203": "恶魔男爵瑞兹（B 组）", "A_1211": "沙漠治安官凯瑟琳（B 组）",
    "A_1206": "觅心猎手薇恩（B 组）", "A_1223": "暗影薇恩（C 组）", "A_1227": "白娘子与青蛇/白蛇（C 组）",
    "A_1309": "超人提莫（C 组）", "A_1134": "卡萨丁（C 组）", "A_1219": "源计划亚索（C 组）",
    "A_1212": "粽子少女（C 组）", "A_1222": "动感伊泽（C 组）", "A_1801": "神龙卡莎（专属文件）",
    "A_1802": "黑夜亚索（专属文件）", "A_1803": "恶魔之刃泰达米尔（专属文件）",
}


# Round one wired the certain owners (NATIVE_FX); round two attributed the rest
# of the idle hero art by look and skill fit (DERIVED_FX).  Nothing is left
# waiting for confirmation.
CANDIDATES = {}


def effect_name(action):
    if not isinstance(action, list) or not action:
        return None
    name = action[3] if action[0] == "manual_ability" and len(action) > 3 else action[-1]
    return name if isinstance(name, str) and re.match(r"^(FX|E_\d|[A-Z_]+_EFF$)", name) else None


def resolve(row):
    if not isinstance(row, dict) or not row:
        return "无素材"
    parts = [f"{part}:{row[part]['id']}" for part in ("b", "p", "h")
             if isinstance(row.get(part), dict) and row[part].get("id")]
    if row.get("id"):
        parts.insert(0, str(row["id"]))
    return "/".join(parts) or "无素材"


def table(document):
    from native_fx_wiring_106 import DERIVED_FX, MISSING_FX, NATIVE_FX
    cfg = document["cfg"]
    wired_fx = {**NATIVE_FX, **{key: cfg["effect"][key] for key in DERIVED_FX}}
    avatars, skills, effects = cfg["avatar"], cfg["skill"], cfg["effect"]
    heroes = {}
    for aid, row in avatars.items():
        match = re.fullmatch(r"(A_1\d{3})_(\d+)", aid)
        if match and int(match.group(2)) >= heroes.get(match.group(1), (None, None, 0))[2]:
            heroes[match.group(1)] = (row, aid, int(match.group(2)))
    lines = ["| 英雄 | 技能 | 当前特效（名称 → 素材） | 应接的原版素材 | 处理结果 |",
             "|---|---|---|---|---|"]
    for base in sorted(heroes):
        row = heroes[base][0]
        if not str(row.get("name", "")).strip() or "野怪" in row["name"] or "单位" in row["name"]:
            continue
        for sid in [x for x in row.get("pl", []) if isinstance(x, str) and x in skills]:
            skill = skills[sid]
            names = []
            for action in skill.get("skill") or []:
                name = effect_name(action)
                if name and name not in names:
                    names.append(name)
            if not names:
                continue
            current = "；".join(f"{n} → {resolve(effects.get(n))}" for n in names)
            wired = [n for n in names if n in wired_fx or n in MISSING_FX]
            if base in CODE_COVERED:
                should, result = "—", f"已由代码特效覆盖：{CODE_COVERED[base]}"
            elif wired:
                should = "；".join(f"{n} → {resolve({**wired_fx, **MISSING_FX}[n])}" for n in wired)
                result = ("已接线" if any(n in NATIVE_FX for n in wired) else
                          "已接线（第二轮）" if any(n in DERIVED_FX for n in wired) else "已补特效表条目")
            elif (base, skill.get("name")) in CANDIDATES:
                should, result = f"候选：{CANDIDATES[(base, skill['name'])]}", "待用户确认（未接线）"
            else:
                should, result = "无确定归属的专属素材", "保持现状"
            lines.append(f"| {row['name']} ({base}) | {skill.get('name', sid)} ({sid}) | {current} | {should} | {result} |")
    return "\n".join(lines)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--write", action="store_true", help="replace the table inside the doc")
    args = parser.parse_args(argv)
    import gateway
    text = table(gateway.build_static_config(ROOT / "config/reconstruction/full-config.json"))
    if not args.write:
        print(text)
        return 0
    doc = DOC.read_text(encoding="utf-8")
    head, rest = doc.split(BEGIN, 1)
    _, tail = rest.split(END, 1)
    DOC.write_text(f"{head}{BEGIN}\n{text}\n{END}{tail}", encoding="utf-8")
    print(f"{text.count(chr(10)) - 1} rows written to {DOC.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
