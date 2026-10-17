"""Current cultivation, destiny and talent configuration."""

import copy


def apply_progression_overhaul(document):
    result = copy.deepcopy(document)
    cfg = result["cfg"]
    simple = cfg["system_simple"]
    simple["skill_biscuit_avatar_id"] = "A_6992_4"
    simple["skill_biscuit_ids"] = ["A_6992_4", "A_6992_5", "A_6992_6"]
    for aid in simple["skill_biscuit_ids"]:
        cfg["avatar"][aid]["name"] = "技能饼干"
        cfg["avatar"][aid]["skillup"] = 20
    for key, row in simple["dn"].items():
        maximum = .35 if key == "1" else .07
        row[6] = maximum / 50
        row[7] = maximum / 50
    simple["wash_halo_sync"] = True
    simple["morph_open"] = False
    definitions = [
        ("01", "强攻", "attack", 5, 5, 1, 0, "自身攻击力提高{value}%"),
        ("02", "坚韧", "defense", 5, 5, 2, 0, "自身物理与法术防御提高{value}%"),
        ("03", "破甲", "enemy_sunder", 10, 5, 2, 2, "存活时敌方全体物理防御降低{value}%"),
        ("04", "活力", "hp", 10, 10, 0, 0, "自身生命上限提高{value}%"),
        ("05", "庇护", "recovery", 10, 10, 0, 0, "自身技能提供的护盾与恢复量提高{value}%"),
        ("06", "致命光环", "team_crit", 500, 250, 0, 1, "存活时全队获得{value}点暴击"),
        ("07", "坚毅光环", "team_tough", 500, 250, 0, 1, "存活时全队获得{value}点韧性"),
        ("08", "精准光环", "team_hit", 500, 250, 0, 1, "存活时全队获得{value}点精准"),
        ("09", "灵动光环", "team_flee", 500, 250, 0, 1, "存活时全队获得{value}点闪避"),
    ]
    talents = {}
    for branch, name, effect, first, step, kind, use, text in definitions:
        for rank in range(1, 8):
            value = first + (rank - 1) * step
            sid = f"T_{branch}_{rank:02d}"
            info = text.format(value=value) + "。同类天赋取最高效果，不重复叠加。"
            talents[sid] = {"id": sid, "name": f"{name}·{rank}阶", "name_tw": f"{name}·{rank}阶",
                            "pl": [kind, value, use], "growth_effect": effect, "growth_value": value,
                            "branch": int(branch), "rank": rank, "info": info, "info_tw": info,
                            "icon": "H_0010000"}
    cfg["talent"] = talents
    simple["progression_overhaul"] = "progression-v2"
    return result
