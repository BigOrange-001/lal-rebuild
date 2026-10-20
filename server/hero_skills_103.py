"""Targeted 1.0.3 hero revisions, applied after the older balance overlays."""
from __future__ import annotations

import copy
import re


def _skill(sid, name, res, pl, actions, policies, info, *, upgrades=None, caps=None):
    def initial_value(match):
        value = actions[int(match[2])][int(match[3])]
        return f'{value * 100:g}%' if match[1] == 'rank' else f'{value:g}'
    initial_info = re.sub(r'\{(rank|flat):(\d+):(\d+)\}', initial_value, info)
    return {'id': sid, 'name': name, 'res': res, 'pl': pl, 'skill': actions,
            'skillUp': upgrades, 'info': initial_info, 'rankInfoTemplate': info,
            'actionTargetPolicies': policies,
            'actionTargetMaxTargets': caps or [1 if p == 'ally_self' else -1 for p in policies]}


def apply_hero_skills_103(document):
    """Assign independent Goku skills and replace only Mordekaiser's own rows.

    Fixed passive magnitudes are authored from the previous configuration,
    rather than multiplied on every startup, so reapplication is idempotent.
    Portrait verification: A_1311's golden-haired Super Saiyan portrait and
    the user-provided panel's three skill names. A_1005 is a different hero.
    """
    cfg = document.get('cfg', document)
    heroes, skills = cfg['avatar'], cfg['skill']
    simple = cfg.setdefault('system_simple', {})
    simple['skin_hero_ids'] = sorted(set(simple.get('skin_hero_ids', [])) |
                                    {'A_1311_5', 'A_1311_6'})
    changed = []
    for quality in (5, 6):
        suffix = str(quality)
        aid = 'A_1311_' + suffix
        hero = heroes[aid]
        normal, captain, passive = (f'S_{family}_{suffix}' for family in (201311, 301311, 401311))
        # Keep the existing assets: no invented resource IDs or shared-skill edits.
        normal_res = skills[hero['pl'][10]].get('res', hero['pl'][10])
        captain_res = skills[hero['pl'][11]].get('res', hero['pl'][11])
        skills[normal] = _skill(normal, '超赛变身', normal_res, [0, 0, 0, 0, 0, 1], [
            ['purify', 2, 'FX_S9150_PURIFY'],
            ['timed_bless', 2, 'BLESS_EFF'],
            ['stat_flat', 'hit', 4500, 2, 'FX60_HIT'],
            ['stat_flat', 'flee', 4500, 2, 'FX60_HIT'],
            ['stat_flat', 'tough', 4500, 2, 'FX60_HIT'],
            ['caster_hp_heal', .12, 'FX_S9150_CURE'],
        ], ['ally_self'] * 6,
            '净化自身并获得神佑，持续2回合；精准、闪避、韧性各提高{flat:2:2}点，'
            '持续2回合，再恢复自身最大生命值的{rank:5:1}。治疗1级12%、10级18%，线性成长，不附加攻击力或精准系数。准备0，冷却0。',
            upgrades=[[2, 2, 500], [3, 2, 500], [4, 2, 500], [5, 1, .06 / 9]])
        skills[captain] = _skill(captain, '真·龟派气功', captain_res, [0, 0, 3000, 0, -1, 1], [
            ['damage', .5, 2, 'FX_S9004_ARC'],
            ['push_aoe', 3000, 1500, 'push'],
        ], ['enemy_lane_all'] * 2,
            '对当前分路全部敌人造成50%攻击的魔法伤害，并击退1500码。准备0，冷却0。')
        skills[passive] = _skill(passive, '绝境逢生', normal_res, [0, 0, 10000, 0, -1, 1], [
            ['purify', 1, 'FX_S9150_PURIFY'],
            ['caster_ap_shield', 3.0, 1, 'FX60_SHIELD'],
            ['strong', .5, 1, 'FX60_STRONG'],
            ['steel', 1.5, 1, 'FX60_STEEL'],
            ['timed_bless', 1, 'BLESS_EFF'],
        ], ['ally_all'] * 5,
            '自身行动前持有负面状态时触发：为全队净化，并按施放时自身300%攻击生成护盾，'
            '再提高全队50%力量和150%双防，赋予神佑；均持续1回合。')
        hero['name'] = '超级赛亚人孙悟空'
        hero['pl'][10:12] = [normal, captain]
        if len(hero['pl']) == 13:
            hero['pl'].append(passive)
        else:
            hero['pl'][13] = passive
        hero['skill_diff'] = 19
        changed.append(aid)

        aid = 'A_1137_' + suffix
        hero = heroes[aid]
        normal, captain = hero['pl'][10:12]
        normal_row, captain_row = skills[normal], skills[captain]
        normal_pl = copy.deepcopy(normal_row['pl'])
        normal_pl[4] = 0
        skills[normal] = _skill(normal, '毁灭一击', normal_row.get('res', normal), normal_pl, [
            ['select_target'],
            ['dispel_good', 'FX60_WEAK'],
            ['curse', 1, 'FX60_WEAK'],
            ['purify', 1, 'FX_S9150_PURIFY'],
            ['stat_flat', 'hit', 6000, 1, 'FX60_HIT'],
            ['stat_flat', 'crit', 6000, 1, 'FX60_HIT'],
            ['damage', 3.12, 2, 'FX_A_1137_MAGIC'],
        ], ['enemy_lane_frontmost'] * 3 + ['ally_self'] * 3 + ['enemy_lane_frontmost'],
            '先驱散当前分路最近敌人的增益并诅咒1回合，再净化自身1回合，'
            '提高自身精准和暴击各{flat:4:2}点，持续1回合，'
            '最后对原目标造成{rank:6:1}攻击的魔法伤害。准备1，冷却3。',
            upgrades=[[4, 2, 2000 / 3], [5, 2, 2000 / 3], [6, 1, 3.12 / 9]], caps=[1] * 7)
        # The enemy's buffs are removed before damage; self actions cannot
        # redirect the final strike to an ally or a different enemy.
        skills[normal]['actionTargetLocks'] = [None, 0, 0, None, None, None, 0]
        captain_pl = copy.deepcopy(captain_row['pl'])
        captain_pl[2], captain_pl[4], captain_pl[5] = 10000, -1, 1
        skills[captain] = _skill(captain, '不动如山', captain_row.get('res', captain), captain_pl, [
            ['purify', 2, 'FX_S9150_PURIFY'],
            ['caster_ap_shield', 5.0, 2, 'FX60_SHIELD'],
            ['steel', 1.0, 2, 'FX60_STEEL'],
            ['timed_bless', 2, 'BLESS_EFF'],
            ['strong', .2, 2, 'FX60_STRONG'],
        ], ['ally_all'] * 5,
            '为全队净化2回合，按施放时自身{rank:1:1}攻击生成护盾，'
            '双防提高{rank:2:1}，获得神佑和{rank:4:1}力量，均持续2回合。准备3，冷却3。')
        passive = hero['pl'][13]
        row = skills[passive]
        # Fivefold magnitudes only. Preparation, cooldown, damage types,
        # durations, target scope and the native on-kill trigger stay intact.
        row['skill'] = [
            ['cure', .75, 'FX_S9150_CURE'],
            ['purify', 1, 'FX_S9150_PURIFY'],
            ['taunt', 1, 'FX_S9150_TAUNT'],
            ['weak', 1.2, 3, .25, 1, 'FX_S9150_WEAK'],
            ['silence', 1.2, 3, 1, 'FX_S9150_SILENCE'],
            ['damage', 1.2, 3, 'FX_S9150_TRUE'],
        ]
        row['info'] = ('击杀敌人时触发：治疗并净化友军，自身获得嘲讽；'
                       '对全体敌人连续造成3段真实伤害，并施加虚弱和沉默。'
                       '治疗系数、各段伤害系数和虚弱数值均为调整前的5倍；'
                       '净化、嘲讽、虚弱和沉默仍持续1回合。')
        row['rankInfoTemplate'] = row['info']
        changed.append(aid)
    cfg['hero_skills_103'] = {'schema': 'hero-skills-1.0.3-v2', 'heroes': changed}
    return document


def finalize_hero_skills_103(document):
    """Apply exact authored values after the older general tier multiplier.

    Other Mordekaiser magnitudes retain their existing 5% tier adjustment.
    Text is projected from the final actions so fallback and rank UI agree.
    """
    cfg=document.get('cfg',document)
    for q in (5,6):
        hero=cfg['avatar'][f'A_1137_{q}']
        cfg['skill'][hero['pl'][11]]['skill'][2][1]=1.0
        for slot in (10,11):
            row=cfg['skill'][hero['pl'][slot]]
            actions=row['skill']
            def replace(match):
                value=actions[int(match[2])][int(match[3])]
                return f'{value*100:g}%' if match[1]=='rank' else f'{value:g}'
            row['info']=re.sub(r'\{(rank|flat):(\d+):(\d+)\}',replace,row['rankInfoTemplate'])
    cfg['hero_skills_103']['exact_captain_defense']=1.0
    return document
