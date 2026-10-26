"""Keep summon descriptions consistent with the live-panel inheritance rule."""

NOTICE = '召唤属性按施法者召唤当刻的完整面板和技能倍率折算，天赋与光环仅计入一次。'
OLD_RULE = '生命、攻击、双抗按自身基础值和每级成长计算，命中、闪避、暴击、韧性继承主人。'


def apply_summon_panel_config(document):
    for row in document.get('cfg', {}).get('skill', {}).values():
        if not any(isinstance(action, list) and action and action[0] in ('summon', 'summon_turret', 'clone_normal')
                   for action in row.get('skill', [])):
            continue
        for key in ('info', 'info_tw'):
            if key not in row:
                continue
            text = str(row[key]).replace(OLD_RULE, '')
            if NOTICE not in text:
                text += ' ' + NOTICE
            row[key] = text
