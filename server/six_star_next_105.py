"""Six-star balance endpoints for the fourth batch."""

from six_star_balance_105 import HEAL, MAGIC, SHIELD, compound, endpoint, text, timing
from skill_output_104 import RATE

PASSIVE_NAMES = {
    1053: '霰弹交火', 1054: '巨龙真身', 1056: '断刃震荡', 1060: '光束护盾',
    1078: '弹射狩猎', 1086: '月银之刃', 1098: '死亡契约', 1103: '虚灵号令',
    1114: '风暴龙光环', 1127: '镜花水月', 1205: '吸元秘术',
}


def action(row, name, warmup, cooldown, reach, effect, values, description, fixed=()):
    compound(row, 'next_' + name, warmup, cooldown, reach, effect, values, description)
    if fixed:
        row['rankFixedPaths105'] = [[0, index] for index in fixed]


def apply_next(avatars, normal, captain, passive):
    graves = 'FX_A_1053_PHYSICAL'
    avatars['A_1053_6']['pl'][9] = 500
    row = normal(1053)
    row['name'] = '快速拔枪'
    action(row, 'graves_n', 0, 4, 600, graves, [.2, .15],
           '突进到600范围内的当前敌人面前，永久提高{rank:0:4}双抗和{rank:0:5}普攻伤害，并额外普攻一次。每受到3次直接攻击，缩短本技能1回合冷却。', (4, 5))
    action(passive(1053), 'graves_p', 0, 0, 0, graves, [4, 2.8, 1.8],
           '普攻距离恒为500。距离不超过200、201至350、351至500时，各造成{rank:0:4}、{rank:0:5}、{rank:0:6}攻击物理伤害。')

    dragon = 'FX_A_1054_MAGIC'
    action(captain(1054), 'shyvana_c', 2, 2, 3000, dragon, [.5, 2.75],
           '对本路所有敌人造成{rank:0:4}攻击魔法伤害与3回合灼烧，每回合{rank:0:5}攻击伤害。巨龙真身期间改为全图。')
    action(passive(1054), 'shyvana_p', 0, 0, 0, dragon, [.5],
           '每次造成伤害或受到直接攻击获得5怒气。达到100时永久化龙，净化并回满生命，最大生命提高100%、攻击提高60%、双抗提高50%。化龙后每次小技能额外释放一次，敌人所受灼烧伤害的{rank:0:4}转为自身护盾。')

    riven = 'FX_A_1056_PHYSICAL'
    row = normal(1056)
    warmup, cooldown = row['pl'][:2]
    action(row, 'riven_n', warmup, cooldown, 450, riven, [2, 3, 4, .5, .96],
           '依次施展折翼之舞三式，突进并打击主目标及附近敌人，分别造成{rank:0:4}、{rank:0:5}、{rank:0:6}攻击物理伤害，吸血{rank:0:7}。第二式获得{rank:0:8}攻击护盾，第三式眩晕1回合。', (7,))
    row = captain(1056)
    action(row, 'riven_c', row['pl'][0], 3, 3000, riven, [4.5, 7.5, .7, .5],
           '获得{rank:0:6}力量和{rank:0:7}最大生命的护盾，持续2回合。对本路所有敌人造成{rank:0:4}至{rank:0:5}攻击物理伤害，目标生命比例越低伤害越高。')
    action(passive(1056), 'riven_p', 0, 0, 0, riven, [2],
           '普攻选中目标后，若该目标600范围内的敌人（含主目标）超过3名，眩晕这些敌人1回合并各造成{rank:0:4}攻击物理伤害。')

    row = normal(1060)
    timing(row, cooldown=2)
    for key in ('skill', 'actionTargetPolicies', 'actionTargetMaxTargets', 'actionTargetPolicyArgs',
                'actionTargetLocks', 'actionTargetGroups'):
        if key in row and len(row[key]) == 5:
            row[key].pop()
    if row.get('skillUp') and isinstance(row['skillUp'][0], list):
        row['skillUp'] = [entry for entry in row['skillUp'] if entry[0] < 4]
    text(row, '对本路敌人连续造成两段{rank:0:1}攻击魔法伤害，命中附带眩晕。')
    row = captain(1060)
    timing(row, cooldown=4)
    row['pl'][2] = 9999
    row['actionTargetPolicies'][1] = 'enemy_global_lowest_current_hp'
    endpoint(row, 1, 1, 6)
    text(row, '瞄准全场当前生命最低的敌方英雄，造成{rank:1:1}攻击魔法伤害，维持原精准、韧性增益。')
    action(passive(1060), 'lux_p', 0, 0, 0, SHIELD, [3.25],
           '本路每有敌人受到眩晕，为本路所有友军提供{rank:0:4}攻击护盾2回合。每个战斗回合最多触发3次。')

    row = normal(1078)
    timing(row, 0, 1)
    row['pl'][2] = 3000
    text(row, '对本路前排目标造成{rank:0:1}及{rank:1:1}攻击物理伤害，本路内不受距离限制。')
    action(passive(1078), 'sivir_p', 2, 6, 0, HEAL, [.25, .15],
           '普攻沿用大招的弹射规则，额外弹射2次；普攻和弹射获得{rank:0:4}吸血。自身没有净化时获得1层净化，准备2回合、冷却6回合；自身净化结束时恢复{rank:0:5}最大生命。')

    lunar = 'FX_A_1086_MAGIC'
    row = normal(1086)
    row['name'] = '苍白之瀑'
    action(row, 'diana_n', 1, 4, 600, lunar, [.4, 2, .4],
           '获得护盾，数值为{rank:0:4}最大生命加{rank:0:5}双抗之和。对自身600范围内的敌人造成相当于盾量{rank:0:6}的魔法伤害。命中至少3人时，额外获得等额护盾。', (6,))
    row = captain(1086)
    row['name'] = '月神降临'
    action(row, 'diana_c', 1, 5, 3000, lunar, [3.5],
           '突进到本路最前方，把本路敌人强制拉到身前200。每段造成{rank:0:4}双抗之和的魔法伤害，基础1段，每使一个敌人位移至少100便增加1段。')
    action(passive(1086), 'diana_p', 0, 0, 0, lunar, [1.75],
           '普攻打击面前350范围内所有敌人，并额外造成{rank:0:4}双抗之和的魔法伤害。')

    timing(normal(1098), 0, 1)
    action(captain(1098), 'karthus_c', 2, 5, 9999, 'FX_A_1098_MAGIC', [5],
           '引导至下次自身行动开始，对全场敌人造成{rank:0:4}攻击魔法伤害。眩晕、沉默或死亡会打断引导。')
    action(passive(1098), 'karthus_p', 0, 0, 3001, MAGIC, [],
           '每场首次被击杀时，若本路还有其他友军存活，保留1点生命，立即连续释放两次小技能，随后死亡。')

    timing(normal(1103), 0, 0)
    row = captain(1103)
    endpoint(row, 0, 12, .85)
    row['skill'][0][13] = 4
    text(row, '召唤一个继承{rank:0:12}即时面板的虚灵，存活4次自身行动，并为自己提供{rank:1:1}最大生命护盾2回合。')
    action(passive(1103), 'malzahar_p', 0, 0, 0, MAGIC, [],
           '普攻命中附加1回合沉默；战斗中攻击命中时，号令本路己方虚灵无视距离，对命中目标释放一次小技能。')

    lightning = 'FX_A_1114_MAGIC'
    row = normal(1114)
    action(row, 'aoxing_n', *row['pl'][:2], 650, lightning, [2.75, 1.25],
           '向当前敌人发射闪电，首个目标{rank:0:4}攻击魔伤，弹射最多2次，每次{rank:0:5}。施放增加1层电荷；已有5层时改为开启持续引导。引导中不移动、普攻或施放小技能，每次自身行动开始释放3次同样的闪电，受到眩晕、沉默或死亡时中止并清空电荷。')
    action(captain(1114), 'aoxing_c', 1, 1, 3001, lightning, [],
           '电荷少于5层时获得1层电荷；已达5层时立即释放3次连锁闪电。')
    action(passive(1114), 'aoxing_p', 8, 8, 9999, lightning, [.15],
           '对全场敌人造成各自当前生命{rank:0:4}的真实伤害，并眩晕1回合。')

    mirror = 'FX_A_1127_MAGIC'
    action(normal(1127), 'leblanc_n', 0, 0, 1500, mirror, [2, 3],
           '对当前目标造成{rank:0:4}攻击魔法伤害并施加恶意魔印。若目标已有该魔印，消耗魔印，改为{rank:0:5}攻击真实伤害并沉默1回合。')
    row = captain(1127)
    timing(row, 2, 4)
    row['sixStarNextLeBlancClone105'] = True
    text(row, row.get('rankInfoTemplate', row['info']) + '\n队长技能召唤的分身也可施放恶意魔印。')
    action(passive(1127), 'leblanc_p', 0, 0, 0, mirror, [.4],
           '闪避时在本路召唤一个能释放小技能的分身，继承{rank:0:4}即时面板，存活3次自身行动。该被动最多同时保留3个分身，以新替旧。')

    row = normal(1203)
    row['sixStarNextBaronLane105'] = True
    text(row, '对本路所有敌人施加2回合诅咒并造成{rank:0:4}攻击魔法伤害；每命中一名施放前已被自己诅咒的敌人，恢复{rank:0:5}攻击生命。')
    row = captain(1203)
    row['sixStarNextBaronDrain105'] = True
    text(row, row.get('rankInfoTemplate', row['info']) + '\n进入2回合吸血状态，技能获得70%吸血，对被诅咒敌人的伤害翻倍。')
    row = passive(1203)
    action(row, 'baron_p', 0, 0, 0, MAGIC, [.05],
           '每次自身行动开始，本路每有一名受诅咒的敌人，永久提高自身入场生命、攻击和双抗各{rank:0:4}。层数无上限。')
    row.pop('skin_v2_keys', None)

    tree = 'FX_A_1205_MAGIC'
    action(normal(1205), 'maokai_n', 0, 3, 1500, tree, [3, .15, .4],
           '突进至本路前排敌人旁，造成{rank:0:4}攻击魔法伤害并眩晕1回合。对其及附近300的敌人额外造成{rank:0:5}自身最大生命魔法伤害，击退400并衰弱{rank:0:6}2回合。', (6,))
    row = captain(1205)
    action(row, 'maokai_c', *row['pl'][:2], 9999, tree, [.25],
           '眩晕每条分路最靠前的敌人2回合，并造成{rank:0:4}自身最大生命的魔法伤害。')
    action(passive(1205), 'maokai_p', 0, 0, 0, HEAL, [.12],
           '每次普通攻击时恢复{rank:0:4}自身最大生命。')

    row = normal(1211)
    endpoint(row, 0, 4, 3)
    keys = row['skin_v2_keys']
    if 'penetration' not in keys:
        keys.append('penetration')
        row['skill'][0].append(1 / RATE)
    position = 4 + keys.index('penetration')
    endpoint(row, 0, position, 1)
    row['rankFixedPaths105'] = [[0, position]]
    text(row, '攻击本路攻击最高敌人，造成{rank:0:4}攻击物伤并施加1回合通缉。通缉期间，本人的技能对该目标无视{rank:0:'+str(position)+'}物防。')
    endpoint(passive(1211), 0, 4, 4)
