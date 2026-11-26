"""Aurelion Sol's chain lightning, every star: the texts for the new rule.

The client (Avatar.aoxingChain106) and the offline simulation
(SixStarNextBattle.aoxing_chain) fire up to five bolts with no range limit, across
lanes, each jump taking the unhit enemy nearest the last one; a lone enemy takes
three times the first bolt. This overlay only rewrites the skill texts, keeping their
rank tokens, on every skill that carries the action (abyss tiers and skill books
included), so it runs after the overlays that copy skills.
"""
from __future__ import annotations

import re

KINDS = ('aoxing_n', 'six_next_aoxing_n')

# 4/5 stars: aoxing_n.
OLD_LOW = re.compile(r'对本分路的当前目标造成(?P<first>.+?)魔法伤害，再依次弹向上一个目标300范围内最近、且本次尚未命中的另一名敌人，'
                     r'最多弹射两次，每次(?P<bounce>.+?)魔法伤害。')
NEW_LOW = ('向最近的敌人发射连锁闪电，造成\\g<first>魔法伤害，再依次跳向离上一个目标最近、且本次尚未命中的另一名敌人，'
           '每次\\g<bounce>魔法伤害，最多命中5名敌人。不受施法距离限制，可跨分路：本分路没有敌人时从最近的分路开始。'
           '场上只有1名敌人时，改为对其造成3倍伤害。')
OLD_RANGE = re.compile(r'\s*本分路内不受施法距离限制。')

# 6 stars: six_next_aoxing_n.
OLD_SIX = re.compile(r'向当前敌人发射闪电，首个目标(?P<first>.+?)攻击魔伤，弹射最多2次，每次(?P<bounce>.+?)。'
                     r'施放增加1层电荷；已有5层时改为开启持续引导。引导中')
NEW_SIX = ('向最近的敌人发射连锁闪电，首个目标\\g<first>攻击魔伤，再依次跳向离上一个目标最近的其他敌人，每次\\g<bounce>，'
           '最多命中5名；不限距离，可跨分路，场上只有1名敌人时改为3倍伤害。施放增加1层电荷；已有5层时改为站定引导，引导中')


def _kind(row):
    for action in row.get('skill') or ():
        if isinstance(action, list) and len(action) > 1 and action[0] == 'manual_ability' and action[1] in KINDS:
            return action[1]
    return None


def rewrite(text, kind):
    if not isinstance(text, str):
        return text
    if kind == 'aoxing_n':
        changed = OLD_LOW.sub(NEW_LOW, text, count=1)
        return OLD_RANGE.sub('', changed) if changed != text else text
    return OLD_SIX.sub(NEW_SIX, text, count=1)


def apply_aoxing_chain_106(document: dict) -> dict:
    """Idempotent: the new texts no longer match the old patterns."""
    for row in document['cfg'].get('skill', {}).values():
        if not isinstance(row, dict):
            continue
        kind = _kind(row)
        if kind:
            for field in ('info', 'rankInfoTemplate'):
                if field in row:
                    row[field] = rewrite(row[field], kind)
    return document
