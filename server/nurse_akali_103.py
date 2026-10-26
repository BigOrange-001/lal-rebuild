"""Nurse Akali: dual-defense tank and healing-triggered true damage."""
from hero_skills_103 import _skill


def apply_nurse_akali_103(document):
    cfg = document.get('cfg', document)
    if cfg.get('nurse_akali_103'):
        return document
    panels = []
    for q in (5, 6):
        hero = cfg['avatar'][f'A_1208_{q}']
        skills = cfg['skill']
        n, c, p = (f'S_{family}_{q}' for family in (271208, 371208, 471208))
        normal_res = skills[hero['pl'][10]].get('res', hero['pl'][10])
        captain_res = skills[hero['pl'][11]].get('res', hero['pl'][11])
        before = list(hero['pl'][:8])
        # Keep prior tier bonuses, and convert both base stats and growth.
        defense = [(before[4+i] + before[6+i]) * .75 for i in (0, 1)]
        hero['pl'][:8] = [round(v, 10) for v in
                         [before[0]*1.2, before[1]*1.2, before[2]*.5, before[3]*.5,
                          defense[0], defense[1], defense[0], defense[1]]]
        hero['role'] = '双抗坦克'
        hero['stat_profile'] = 3
        skills[n] = _skill(n, '全队急救', normal_res, [1, 2, 3000, 0, -1, 1],
            [['manual_ability', 'nurse_n', 1, 'FX60_HEAL', .7]], ['ally_all'],
            '准备1，冷却2。净化全图所有存活友军（含自身与召唤物），并分别恢复护士阿卡丽实时总攻击力的{rank:0:4}生命。'
            '1～10级治疗从70%线性成长到140%，不附加额外生命系数。', upgrades=[[0, 4, .7/9]])
        skills[c] = _skill(c, '重症守护', captain_res, [3, 3, 3000, 0, -1, 1],
            [['manual_ability', 'nurse_c', 1, 'FX60_HEAL']], ['ally_all'],
            '准备3，冷却3。选择全图剩余生命比例最低的存活友军，并对其和自身分别施加净化、永久神佑，'
            '各恢复护士阿卡丽最大生命值50%的生命。若选中自身，则对自身独立释放两次，分别触发治疗被动。治疗比例不随等级成长。')
        skills[p] = _skill(p, '医者反击', normal_res, [0, 0, 3000, 0, -1, 1],
            [['nurse_healing', .4]], ['enemy_all'],
            '每当自身受到治疗，对全图所有存活敌人分别造成该次治疗量40%的真实伤害。'
            '治疗增益与减疗结算后、生命上限截断前计算，包含全部过量治疗；不受攻击倍率、命中、暴击或护甲影响。40%固定。')
        hero['pl'][10:12] = [n, c]
        hero['pl'][13] = p
        hero['tl'][2] = 3
        hero['skill_diff'] = 0
        panels.append(dict(aid=hero['id'], before=before, after=list(hero['pl'][:8])))
    cfg['nurse_akali_103'] = dict(schema='nurse-akali-1.0.3-v1', panels=panels)
    return document
