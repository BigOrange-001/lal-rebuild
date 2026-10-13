"""Apply the VIP gift-coin thresholds to a full game config.

Usage: py -3.12 scripts/vip_campaign_overlay.py INPUT OUTPUT
Writes a separate output file; the caller chooses when to use it as the
runtime config.  No version field is changed.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "server"))
from vip_campaign import VIP_THRESHOLDS


def apply_vip_campaign(document: dict) -> dict:
    cfg = document["cfg"]
    vip = cfg["vip"]
    if any(str(level) not in vip for level in range(16)):
        raise ValueError("VIP rows 0..15 are required")
    for level, threshold in enumerate(VIP_THRESHOLDS):
        row = vip[str(level)]
        row["exp"] = threshold
        row["need_exp"] = (VIP_THRESHOLDS[level + 1] - threshold
                           if level < 15 else 0)
        row["equip_upgrade_multi_percent"] = 6 * level
        row["equip_alchemy_bonus_percent"] = 2 * level
    simple = cfg.get("system_simple", {})
    tips = simple.get("vip_tips") if isinstance(simple, dict) else None
    if isinstance(tips, list) and not any(isinstance(item, list) and len(item) > 1
                                           and item[1] == "equip_upgrade_multi_percent"
                                           for item in tips):
        tips.append([99009, "equip_upgrade_multi_percent", -1])
    if isinstance(tips, list) and not any(isinstance(item, list) and len(item) > 1
                                           and item[1] == "equip_alchemy_bonus_percent"
                                           for item in tips):
        tips.append([99010, "equip_alchemy_bonus_percent", -1])
    text = cfg.get("return_msg_config")
    if isinstance(text, dict):
        text["90458"] = "累计赠送金砖：@0"
        text["20506"] = "达到该VIP等级需累计赠送@0金砖。"
        text["99009"] = "装备强化多级提升概率@0%"
        text["99010"] = "装备炼金额外进度概率@0%"
    return document


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print("usage: vip_campaign_overlay.py INPUT OUTPUT", file=sys.stderr)
        return 2
    source, target = (Path(arg).resolve() for arg in argv[1:])
    if source == target:
        raise ValueError("INPUT and OUTPUT must differ")
    document = json.loads(source.read_text(encoding="utf-8-sig"))
    apply_vip_campaign(document)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(document, ensure_ascii=False, separators=(",", ":")),
                      encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
