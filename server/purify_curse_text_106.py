"""Skill texts for layered purify and curse.

Purify and curse no longer count down by rounds: each purify layer cancels
one generic debuff (the earliest held when gained, otherwise the next incoming
one) and layers stack without limit; each curse layer strips two generic good
buffs or blocks the next two, up to three layers. Hero-specific statuses are
outside both. Skill texts written for the old
timed rules ("净化2回合", "诅咒1回合") come from many overlays, so this pass
runs once over the finished config and rewrites only those phrases.
"""
import re

# Glossary lines shown in skill popups (skill_tips_105.aspart).
PURIFY_TERM = '净化：每层抵消1次通用负面状态，可无限叠加；获得时先抵消身上最早的，单次驱散只移除1层；不影响英雄专属效果'
CURSE_TERM = '诅咒：每层删除2个通用增益（护盾除外）或阻止之后2次通用增益，最多叠加3层；不影响英雄专属效果'
# return_msg_config 25018: the native skill-info line for purify actions.
PURIFY_INFO = '净化：每层抵消1次通用负面状态，获得时先抵消最早获得的，不影响英雄专属效果。'

_N = r'(?:\d+|\{flat:\d+:\d+\})'
_R = _N + '回合'

# Ordered: specific rewrites first, then the generic duration removals.
_RULES = [
    # Whole-sentence claims that a purify alone clears every debuff.
    (r'解除友军减益并给予一次净化抵挡', '为友军施加一层净化'),
    (r'施加净化' + _R + r'，解除可净化的负面效果', '施加一层净化'),
    (r'先获得一层净化：立即清除自身负面，并抵挡下一次负面效果',
     '先获得一层净化：抵消自身最早获得的通用负面效果，没有时抵挡下一次'),
    (r'净化结束时', '净化层数耗尽时'),
    (r'移除本路所有敌人的护盾和净化', '移除本路所有敌人的护盾和1层净化'),
    # A duration shared by purify and another buff keeps the other buff's.
    (r'护盾并净化，持续(' + _R + ')', r'护盾，持续\1，并净化'),
    (r'护盾和一次净化，持续(' + _R + ')', r'护盾，持续\1，并获得一次净化'),
    (r'护盾和净化，均持续(' + _R + ')', r'护盾（持续\1）和净化'),
    (r'和净化，持续(' + _R + ')', r'（持续\1）和净化'),
    (r'净化与精准(' + _R + ')', r'精准\1和净化'),
    (r'一次净化，持续' + _R, '一次净化'),
    (r'净化，每次持续' + _R, '净化'),
    (r'净化，每次' + _R, '净化'),
    (r'持续(' + _R + ')的神佑与净化', r'净化与持续\1的神佑'),
    # A duration shared by curse and another debuff keeps the other one's.
    (r'虚弱和诅咒持续', '虚弱持续'),
    (r'衰弱和诅咒，持续(' + _R + ')', r'衰弱（持续\1）和诅咒'),
    (r'诅咒和眩晕，各持续(' + _R + ')', r'诅咒和\1眩晕'),
    (r'诅咒、眩晕(' + _R + ')', r'眩晕\1、诅咒'),
    (r'一次诅咒，持续' + _R, '一层诅咒'),
    (r'诅咒当前目标，持续' + _R, '诅咒当前目标'),
    # Plain durations: "净化自身1回合", "2回合净化", "诅咒本路前排2回合".
    (r'净化(自身)?' + _R, r'净化\1'),
    (_R + '净化', '净化'),
    (r'诅咒([^，。；、和\d{]{0,6}?)' + _R, r'诅咒\1'),
    (_R + '诅咒', '诅咒'),
]
_COMPILED = [(re.compile(pattern), replacement) for pattern, replacement in _RULES]


def rewrite(text):
    """Rewrite timed purify/curse phrases in one skill text."""
    if not isinstance(text, str) or ('净化' not in text and '诅咒' not in text):
        return text
    for pattern, replacement in _COMPILED:
        text = pattern.sub(replacement, text)
    return text


def _walk(node):
    if isinstance(node, dict):
        for key, value in node.items():
            if isinstance(value, str):
                node[key] = rewrite(value)
            else:
                _walk(value)
    elif isinstance(node, list):
        for index, value in enumerate(node):
            if isinstance(value, str):
                node[index] = rewrite(value)
            else:
                _walk(value)


def apply_purify_curse_text(document):
    cfg = document.get('cfg', document)
    for table in ('skill', 'equip', 'system_simple'):
        if table in cfg:
            _walk(cfg[table])
    messages = cfg.get('return_msg_config')
    if isinstance(messages, dict) and '25018' in messages:
        messages['25018'] = PURIFY_INFO
    return document
