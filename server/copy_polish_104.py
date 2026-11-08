"""Planner-style copy polish for player-facing text (talents, bond mechanics).

Mirrors SkillSet.polishInfo104 on the client. Skill rows are polished on the client
instead, because their templates carry {rank:..}/{scale:..} placeholders whose numbers
must not be rewritten before the client resolves them.
"""
import re


def _heal(match):
    rate = float(match.group(1))
    tenth = ('%.1f' % (rate * 0.1)).rstrip('0').rstrip('.')
    return '恢复自身生命，恢复量为自身%s%%攻击力＋%s%%最大生命' % (match.group(1), tenth)


RULES = [
    # engine / implementation wording that players don't need
    (r'[^。；\n]*一次释放内完成[^。；\n]*[。；]?', ''),
    (r'已?经?阵亡的?目标跳过[，,]?(?:不补选)?[。；，]?', ''),
    (r'没有合法(?:敌人|目标)时结束[。；]?', ''),
    (r'[^。；\n]*不触发[^。；\n]*击杀追加[。；]?', ''),
    (r'释放距离[：:]\s*\d+[。；]?', ''),
    (r'(^|\n)(?:普通技能|队长技能|队长技)[：:]', r'\1'),
    (r'随后以自身攻击加10(?:\.0)?%最大生命为基础，', '随后'),
    (r'按(\d+(?:\.\d+)?)%原生治疗倍率自疗[^。；\n]*', _heal),
    # terminology
    (r'(?:本|当前)分路', '本路'), (r'分路', '路'),
    (r'合法', ''), (r'真正阵亡', '阵亡'),
    (r'总面板攻击力?', '攻击力'), (r'攻击面板', '攻击力'),
    (r'面板((?:物理|魔法|真实)?伤害)', r'\1'), (r'面板', '属性'),
    (r'攻击魔伤', '魔法伤害'), (r'攻击物伤', '物理伤害'),
    (r'攻击力?((?:魔法|物理|真实)伤害)', r'\1'), (r'%攻击伤害', '%伤害'),
    (r'(\d+(?:\.\d+)?%)攻击力?(护盾|生命)', r'相当于\1攻击力的\2'),
    (r'(\d+(?:\.\d+)?%)最大生命护盾', r'相当于\1最大生命的护盾'),
    (r'每次结算(\S+?)施加时攻击力?', r'每次造成\1攻击力的伤害'),
    (r'实时总攻击力', '攻击力'),
    (r'独立持续伤害', '持续伤害'),
    (r'倍率的AOE', '的范围'), (r'AOE', '范围'), (r'%倍率', '%'),
    (r'(\d+)码', r'\1距离'),
    (r'本路内的', '本路'), (r'距离(?:自己|自身)最近的', '最近的'),
    # equipment lines
    (r'装备·([^·：\n]+)·([^：\n]+)：《[^》\n]+》：仅', '【装备】'),
    (r'装备·([^·：\n]+)·([^：\n]+)：\1的', '【装备】'),
    (r'装备·([^·：\n]+)·([^：\n]+)：', '【装备】'),
    (r'(^|[^【])装备·([^：\n]+)：', r'\1【装备·\2】'),
    (r'【装备】《[^》\n]+》：', '【装备】'),
    # numbers
    (r'(\d+)\.0%', r'\1%'), (r'(\d+)\.0(?![\d%])', r'\1'),
    # spacing & punctuation
    (r'[ \t]+(?=\n|$)', ''), (r'(^|\n)[ \t]+', r'\1'),
    (r'([。；，：、】」])[ \t]+', r'\1'),
    (r'([^\x00-\x7f])[ \t]+(?=[^\x00-\x7f])', r'\1，'),
    (r'([^\x00-\x7f%]|\d%?)[ \t]+(?=\d)', r'\1，'),
    (r'；\s*。', '。'), (r'，\s*。', '。'), (r'。{2,}', '。'), (r'；(?=\n|$)', '。'),
    (r'([^。！？；\n])(?=\n|$)', r'\1。'),
    (r'[，；、]+。', '。'),
]

TEXT_KEYS = {'info', 'info_tw', 'description', 'short_info', 'desc', 'tips'}


def polish_text(text):
    if not isinstance(text, str) or not text:
        return text
    for pattern, replacement in RULES:
        text = re.sub(pattern, replacement, text)
    lines = []
    for line in text.split('\n'):
        line = line.strip()
        if line and line not in lines:
            lines.append(line)
    return '\n'.join(lines)


def polish_sections(cfg, sections=('talent', 'system_simple')):
    def visit(value):
        if isinstance(value, dict):
            for key, child in value.items():
                if key in TEXT_KEYS and isinstance(child, str):
                    value[key] = polish_text(child)
                elif isinstance(child, (dict, list)):
                    visit(child)
        elif isinstance(value, list):
            for child in value:
                visit(child)
    for section in sections:
        visit(cfg.get(section, {}))
