"""Annie's companion mechanics belong to her normal skill; retaliation is passive."""
import copy
import re

from equipment_rebinding_105 import load_plan
from native_skill_snapshot import _native_skill_snapshot
from skill_rank_growth_104 import hero_skill_references


def reaction_spec(bonded=False):
    spec = copy.deepcopy(load_plan()['annie_core'])
    spec['stun_enabled'] = bool(bonded)
    effects = '33%破甲和33%虚弱2回合、中毒2回合（每回合50%攻击真实伤害，可叠加）、'
    effects += '眩晕和沉默各1回合。' if bonded else '沉默1回合。'
    spec['info'] = ('自身受到异常状态时，净化全体友方并使其免疫有害状态1回合；'
                    '对全体存活敌人施加' + effects +
                    '跨路生效，准备0、冷却1；同一次异常连锁中每位安妮只反击一次。' +
                    ('烈焰核心羁绊已激活：额外附加眩晕。' if bonded else '烈焰核心羁绊激活后，额外附加眩晕1回合。'))
    return spec


def apply_annie_reaction(document):
    cfg = document.get('cfg', document)
    if cfg.get('annie_reaction_105'):
        return document
    heroes = [aid for aid in cfg['avatar'] if aid.rsplit('_', 1)[0] == 'A_1221']
    refs = hero_skill_references(cfg, {'A_1221'})
    for aid in heroes:
        hero = cfg['avatar'][aid]
        original = cfg['skill'][hero['pl'][13]]
        old = _native_skill_snapshot(cfg, original['id'], 1)
        keys = list(original['skin_v2_keys'])
        companion = {'keys': keys, 'values': old['skills'][0][4:]}
        # The old passive always ran at rank 1. Moving its metadata to the
        # normal skill must not make its coefficients grow with normal rank.
        text = original.get('rankInfoTemplate', original['info'])
        def rank(match):
            value = old['skills'][int(match[1])]
            for index in match[2].split('.'):
                value = value[int(index)]
            return f'{value*100:.1f}%'
        text = re.sub(r'\{rank:(\d+):([\d.]+)\}', rank, text)
        quality = aid.rsplit('_', 1)[1]
        for sid, slot in refs.items():
            if slot != 10 or not sid.endswith('_' + quality):
                continue
            row = cfg['skill'][sid]
            row['annie_companion_105'] = copy.deepcopy(companion)
            command = companion['values'][keys.index('command')]
            for field in ('info', 'rankInfoTemplate'):
                value = row.get(field, row['info'])
                value = re.sub(r'其普攻额外造成[\d.]+%安妮攻击', f'其普攻额外造成{command*100:.1f}%安妮攻击', value)
                row[field] = value + '\n提伯斯伙伴：' + text
    for sid, slot in refs.items():
        if slot != 13:
            continue
        row = cfg['skill'][sid]
        spec = reaction_spec(bool(row.get('annie_core_105')))
        row.update(name='不讲道理', skin_v2_keys=[], annie_core_105=spec,
                   info=spec['info'], rankInfoTemplate=spec['info'],
                   skill=[['manual_ability', 'skin2_1221_2', 1, 'FX60_MAGIC']],
                   skillUp=[], skillUpPaths=[], rankSettingGrowth104={})
        row['pl'][:2] = [spec['warmup'], spec['cooldown']]
        row['rankGrowth104']['magnitudes'] = []
    for row in cfg.get('skill_rank_growth_104', {}).get('audit', []):
        if refs.get(row['sid']) == 13:
            row['magnitudes'] = 0
    cfg['annie_reaction_105'] = {'schema': 'annie-reaction-20261117-v2', 'heroes': heroes}
    return document
