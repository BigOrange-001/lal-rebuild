"""Follow-up six-star balance, applied at the same pre-bond stage."""
from native_skill_snapshot import _native_skill_snapshot
from skill_output_104 import RATE
from six_star_balance_105 import (
    DASH, HEAL, MAGIC, SHIELD, SLASH, STRONG, add, compound, endpoint, text, timing,
)


PASSIVE_NAMES = {
    1024: '艾欧尼亚之志', 1026: '疾风骤雨', 1130: '夺命连刺', 1131: '踏浪之行',
    1133: '灵魂庇护', 1135: '残忍无情', 1138: '厚实表皮',
}


def apply_followup(cfg, normal, captain, passive):
    timing(normal(1008), 1, 1)
    timing(captain(1008), 2, 0)

    row = normal(1024)
    timing(row, 0, 1)
    endpoint(row, 1, 1, 4.25)
    row['sixStarIreliaDash105'] = True
    row['skill'][0][1] = 'enemy_lane_frontmost'
    row['actionTargetPolicies'][0] = 'enemy_lane_frontmost'
    text(row, '突进至本路最前排敌人面前，对其造成{rank:1:1}物理伤害。'
              '回复自身生命，并获得{rank:4:1}攻击力护盾2回合。'
              '击杀目标时对本路另一名前排敌人追加一次；每次施放最多追加一次。')
    compound(captain(1024), 'irelia_c', 2, 2, 3000, 'FX_A_1024_PHYSICAL', [2, .5, 3.75, .35],
             '对本路最前排敌人及其700范围内所有其他敌人造成{rank:0:4}魔法伤害并施加{rank:0:5}破甲2回合，'
             '再对这些目标各造成{rank:0:6}物理伤害。自身解除并免疫虚弱、沉默、破甲、诅咒和眩晕2回合，'
             '回复本次实际物理伤害的{rank:0:7}生命。')
    compound(passive(1024), 'irelia_p', 0, 0, 0, SLASH, [.25],
             '对本路敌人造成伤害时，本路存活敌人每比己方多一名，伤害提高{rank:0:4}。')

    row = normal(1026)
    timing(row, 1, 2)
    base = _native_skill_snapshot(cfg, row['id'], 10)['skills'][2][1] * RATE
    endpoint(row, 2, 4, 3.6 - base)
    endpoint(row, 3, 1, .5)
    endpoint(row, 4, 1, .6)
    row['sixStarLeeCombo105'] = True
    text(row, '对当前目标造成{rank:0:1}物理伤害，随后突进并造成{rank:2:1}物理伤害。'
              '若第二段结算前目标低于半血，该段总倍率提高至{rankSum:2:1:4}。'
              '回复两段实际伤害的{rank:3:1}生命，自身获得{rank:4:1}最大生命值的护盾2回合。')
    compound(captain(1026), 'lee_c', 2, 2, 600, 'FX_A_1026_PHYSICAL', [6.75, 3.5],
             '对当前目标造成{rank:0:4}物理伤害，眩晕1回合并击退800。'
             '沿途本路其他敌人各受到{rank:0:5}物理伤害。自身获得一次净化。')
    compound(passive(1026), 'lee_p', 0, 0, 0, MAGIC, [2, .4],
             '施放任意主动技能后，下一次普通攻击对目标及其400范围内的本路敌人追加'
             '{rank:0:4}魔法伤害，命中时施加{rank:0:5}衰弱1回合。')

    row = normal(1027)
    row['pl'][2] = 3000
    row['actionTargetMaxTargets'][0] = 2
    row['sixStarVeigar105'] = True
    original = row.get('rankInfoTemplate', row['info'])
    damage_token = original.split('造成', 1)[1].split('魔法伤害', 1)[0]
    text(row, f'对本路最前排的最多2名敌人造成{damage_token}魔法伤害。'
              '命中敌方英雄时获得一层邪恶之力，每层增加开战基础攻击力的{sixVeigarStack}，本场最多10层。'
              '每次施放最多获得一层，命中召唤物不成长。')

    row = normal(1130)
    compound(row, 'fiora_n', 0, 1, 1500, 'FX_A_1130_PHYSICAL', [2.5, .12, 1],
             '突进至本路前排敌人面前，造成{rank:0:4}攻击力物理伤害和目标最大生命值'
             '{rank:0:5}的真实伤害。回复实际造成的生命伤害，溢出治疗以{rank:0:6}的比例转为2回合护盾，自身获得净化1回合。')
    row['rankFixedPaths105'] = [[0, 6]]
    row = captain(1130)
    row['name'] = '利刃华尔兹'
    compound(row, 'fiora_c', 2, 3, 3000, 'FX_A_1130_PHYSICAL', [1.75, .5, .5],
             '连续攻击5次，每次随机选取本路一名存活敌人，对其造成{rank:0:4}物理伤害。'
             '其300范围内其他敌人受到该倍率的{rank:0:5}。结束后将实际造成的生命伤害的{rank:0:6}转化为自身护盾2回合。')
    compound(passive(1130), 'fiora_p', 0, 0, 0, SLASH, [1],
             '每第二次施放小技能时，命中后必定暴击并无视目标韧性。暴击倍率仍由自身暴击属性决定。')

    compound(normal(1131), 'nami_n', 1, 2, 3000, HEAL, [4, 1.25, .66],
             '治疗本路攻击力最高的其他友军，恢复{rank:0:4}攻击力的生命。'
             '该友军接下来3次造成伤害的普攻或主动技能，每次对各受击目标追加一次'
             '{rank:0:5}娜美攻击力的真实伤害，并施加{rank:0:6}衰弱3回合。每次普攻或施法只消耗一层。')
    row = captain(1131)
    timing(row, 2, 2)
    row['sixStarNamiWave105'] = True
    text(row, '对本路前方800范围内最靠近的最多4名敌人造成{rank:0:1}魔法伤害，首个目标眩晕1回合并击退250。'
              '被命中的敌方英雄移动速度减半2回合。我方友军获得{rank:3:1}力量2回合。')
    compound(passive(1131), 'nami_p', 0, 0, 0, STRONG, [2],
             '娜美在场时，本路其他友军移动速度翻倍。')

    row = normal(1132)
    row['pl'][2] = 3000
    row['skill'][0][4] = 2
    row['actionTargetLocks'][1] = 0
    row['sixStarZedRandom105'] = True
    text(row, '随机选取本路一名存活敌人，造成{rank:0:1}物理伤害和{rank:1:1}追加物理伤害，'
              '并施加{rank:0:3}攻击力的中毒，持续{flat:0:4}回合。')
    row = captain(1132)
    timing(row, 2, 2)
    # The live panel ratio already includes earlier tuning. Show it directly.
    text(row, '召唤继承自身{sixClonePanel}面板的影分身，复制自身小技能，持续5次自身行动。')

    compound(normal(1133), 'morgana_n', 0, 3, 3000, 'FX_A_1133_MAGIC', [2.75],
             '对本路前排敌人造成{rank:0:4}魔法伤害并眩晕2回合，回复等量实际生命伤害。'
             '为本路攻击最高的友军提供一次净化，持续2回合。')
    compound(captain(1133), 'morgana_c', 0, 4, 3000, 'FX_A_1133_MAGIC', [.6, 6.66],
             '链接本路所有存活敌人3回合。莫甘娜存活时，目标受到的非持续伤害增加{rank:0:4}。'
             '到期时若莫甘娜仍存活，解除链接，眩晕这些目标1回合并造成{rank:0:5}魔法伤害。')
    compound(passive(1133), 'morgana_p', 0, 0, 0, SHIELD, [.2],
             '施放任意主动技能后，自身获得{rank:0:4}最大生命值护盾和一次净化，持续2回合。')

    timing(normal(1135), 2, 1)
    timing(captain(1135), 3, 2)
    compound(passive(1135), 'rengar_p', 0, 0, 0, SLASH, [1.5],
             '自身技能的暴击概率在原公式结果上乘以1.5，上限100%。')

    row = normal(1138)
    endpoint(row, 0, 1, 2.5)
    add(row, ['pull', 0, 1, 500, DASH], 'enemy_lane_frontmost')
    row['actionTargetLocks'][-1] = 0
    row['sixStarTahmPull105'] = True
    text(row, '对当前目标造成{rank:0:1}魔法伤害，沉默{flat:0:3}回合，并触发同路集火，再将目标拉近500。')
    row = captain(1138)
    row['sixStarTahmRange105'] = True
    endpoint(row, 1, 1, 1.2)
    endpoint(row, 2, 1, 3.5)
    endpoint(row, 4, 1, 15)
    text(row, '普通攻击距离内有本路敌人时才施放。自身获得{flat:0:1}回合净化及{flat:3:1}回合嘲讽，'
              '攻击提升{rank:1:1}、双抗提升{rank:2:1}，持续2回合，随后对该敌人造成{rank:4:1}物理伤害。')
    compound(passive(1138), 'tahm_p', 0, 0, 0, SHIELD, [.5],
             '受到伤害损失的生命记为灰血。下次自身回合开始时，将灰血的{rank:0:4}恢复为生命值。')

    row = normal(1142)
    timing(row, 0, 0)
    endpoint(row, 2, 1, 2.25)
    row['sixStarKindredVolley105'] = True
    text(row, '自身获得{flat:0:2}精准1回合，随后后退200。对后退位置前方最近的最多3名本路敌人'
              '各造成{rank:2:1}物理伤害。')

    row = normal(1202)
    endpoint(row, 0, 4, 0)
    text(row, '对本路所有敌人造成{rank:0:6}攻击力物理伤害，命中后施加{rank:0:5}破甲1回合。')
    row = captain(1202)
    row['sixStarPolarStun105'] = 2
    text(row, row.get('rankInfoTemplate', row['info']).replace('诅咒和眩晕，各持续1回合', '诅咒1回合和眩晕2回合'))
    row = passive(1202)
    row['sixStarPolarGrowth105'] = .1
    text(row, row.get('rankInfoTemplate', row['info']) + ' 每次自身回合开始时，暴击属性增加开战暴击属性的十分之一，无限叠加。')
