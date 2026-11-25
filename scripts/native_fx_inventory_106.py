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


# Idle effectDB art that looks like it belongs to a hero but whose owner is not
# certain.  Left unwired until the user confirms (doc: 待确认素材).
CANDIDATES = {
    ("A_1056", "放逐之锋"): "e503 蓝色新月剑气（疑似风斩）",
    ("A_1131", "怒涛之潮"): "e070 蓝色水流漩涡",
    ("A_1120", "圣裁之刻"): "e019 金色爆闪后收成金色护罩",
    ("A_1093", "守护圣域"): "e019 金色爆闪后收成金色护罩",
    ("A_1099", "毒雾扫射"): "e510 绿色骷髅毒雾（提莫也可能）",
    ("A_1082", "毒菌飞镖"): "e510 绿色骷髅毒雾（图奇也可能）",
    ("A_1002", "真-魔法水晶箭"): "e520 带光环的蓝色长箭（现用 e515 也是冰箭）",
    ("A_1021", "秘术射击"): "e505 蓝色能量弹",
    ("A_1016", "雷电标记"): "e206 黄色闪电弹 / e009 青色电球",
    ("A_1010", "瞬步斩"): "e513 蓝色飞刀（泰隆也可能）",
    ("A_1023", "飞叶联动"): "e513 蓝色飞刀（卡特琳娜也可能）",
    ("A_1068", "烈焰风暴"): "e514 燃烧巨石 / e516 火焰新月",
    ("A_1077", "势崩山裂"): "e514 燃烧巨石",
    ("A_1029", "灼热火球"): "e516 火焰新月 / e507 小火球",
    ("A_1063", "毒牙"): "e545 紫蓝色蛇首（原自制档案给过白娘子）",
}


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
    from native_fx_wiring_106 import MISSING_FX, NATIVE_FX
    cfg = document["cfg"]
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
            wired = [n for n in names if n in NATIVE_FX or n in MISSING_FX]
            if base in CODE_COVERED:
                should, result = "—", f"已由代码特效覆盖：{CODE_COVERED[base]}"
            elif wired:
                should = "；".join(f"{n} → {resolve({**NATIVE_FX, **MISSING_FX}[n])}" for n in wired)
                result = "已接线" if any(n in NATIVE_FX for n in wired) else "已补特效表条目"
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
