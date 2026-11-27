"""Balance changes for the third batch of orange heroes."""

from six_star_balance_105 import (MAGIC, SLASH, STRONG, WEAK, compound,
                                  endpoint, passive_step, rewrite, text, timing)

PASSIVE_NAMES = {
    1115: '罪恶快感', 1117: '冰脉爆裂', 1119: '浪客之道', 1120: '登神长阶',
    1125: '破片伤害', 1126: '卓尔不凡', 1128: '诅咒匕首', 1998: '天界共鸣',
}


def apply_extended(normal, captain, passive):
    jinx_fx = 'FX_A_1115_PHYSICAL'
    compound(normal(1115), 'batch_jinx_n', 0, 0, 3000, jinx_fx, [1.8, 1.8],
             '对本路当前目标造成{rank:0:4}攻击力物理伤害，对其附近350范围内其他敌人造成{rank:0:5}攻击力物理伤害。每层罪恶快感使本技能额外释放1次。')
    compound(captain(1115), 'batch_jinx_c', 2, 4, 9999, jinx_fx, [3, .4, .7],
             '对全图生命比例最低的敌人造成{rank:0:4}攻击力加该目标已损失生命{rank:0:5}的物理伤害，并对其附近500范围内其他敌人造成上述伤害的{rank:0:6}。每真正击杀1个敌方单位获得1层罪恶快感，同一次击杀只计1层。')
    compound(passive(1115), 'batch_jinx_p', 0, 0, 0, jinx_fx, [.6],
             '本路每死亡1个敌方单位，获得1层罪恶快感，持续3回合。每层独立计时，使自身移动距离增加{rank:0:4}，小技能额外释放1次。')

    compound(passive(1117), 'batch_lissandra_p', 0, 0, 0, 'FX_A_1117_MAGIC', [3],
             '本路每死亡1个敌方单位，对其附近300范围内所有存活敌人各造成{rank:0:4}攻击力魔法伤害。')

    row = normal(1119)
    timing(row, 1, 1)
    for index in (4, 3):
        row['skill'].pop(index)
        for key in ('actionTargetPolicies', 'actionTargetMaxTargets', 'actionTargetGroups',
                    'actionTargetLocks', 'actionTargetPolicyArgs'):
            row[key].pop(index)
    row['skillUp'] = [growth for growth in row['skillUp'] if growth[0] < 3]
    endpoint(row, 1, 1, 1.2)
    endpoint(row, 2, 1, 1.55)
    text(row, '突进至本路当前目标面前，先对其造成{rank:1:1}攻击力物理伤害，再对其及其附近200范围内最多4名敌人各造成{rank:2:1}攻击力物理伤害，并衰弱前排敌人2回合。')
    row = captain(1119)
    text(row, row['rankInfoTemplate'].split('\n护援先锋', 1)[0])
    compound(passive(1119), 'batch_yasuo_p', 0, 8, 0, 'FX60_SHIELD', [2, .6],
             '进入战斗后暴击数值翻倍。没有护盾时遭到敌方攻击，获得{rank:0:5}生命上限的护盾1回合。自身每次暴击使该护盾的剩余冷却减少1回合。')

    row = captain(1120)
    row['name'] = '圣裁之刻'
    compound(row, 'batch_kayle_c', 2, 4, 0, 'FX_A_1120_MAGIC', [.99],
             '自身获得不可被驱散的{rank:0:4}减伤1回合，登神长阶第四阶段后持续2回合。自身额外获得2000精准，持续至战斗结束。')
    compound(passive(1120), 'batch_kayle_p', 0, 0, 0, 'FX_A_1120_MAGIC', [2, 3, 1.5],
             '每过8个战斗回合进阶一次，任队长时每7回合一次，最多4次。第一阶段普攻距离变为3000。第二阶段普攻对本路所有敌人造成{rank:0:4}攻击力伤害。第三阶段改为{rank:0:5}攻击力真实伤害，每个目标还会对其200范围内的其他敌人溅射{rank:0:6}攻击力真实伤害。第四阶段将队长技能的减伤延长至2回合。')

    row = normal(1123)
    row['name'] = '恶魔回力标'
    rewrite(row, [1, 2, 9999, 0, -1, 0],
            [['true_damage', 0, 'FX_A_1123_PHYSICAL'], ['weak_percent', 0, 1, .2, 2, WEAK],
             ['curse', 2, 'FX60_MAGIC']],
            '对全图所有敌人造成{rank:0:1}攻击力真实伤害，并施加{rank:1:3}衰弱和诅咒，持续2回合。',
            ['enemy_lane_all'] * 3, [-1] * 3)
    row['actionTargetPolicyArgs'] = [{'laneFilter': 'all'}] * 3
    row['sixStarBatchTrueTargets105'] = True
    endpoint(row, 0, 1, .35)
    row = captain(1123)
    for index, coefficient in enumerate((.7, .7, 2.35)):
        endpoint(row, index, 1, coefficient)
    text(row, '对本路当前目标连续造成{rank:0:1}攻击力物理伤害2次，再造成{rank:2:1}攻击力魔法伤害。自身后退250，获得{rank:4:1}力量和{flat:5:2}闪避，持续2回合。')

    row = normal(1124)
    row['skill'] = row['skill'][:1]
    endpoint(row, 0, 1, 8)
    row.setdefault('rankFixedPaths105', []).append([0, 1])
    row['manualSummonPolicy'].update(skillId=row['id'], apRatio=1, hpRatio=1, dePhRatio=1, deMaRatio=1)
    row.pop('captainSummonMultiplier', None)
    row['sixStarBatchSand105'] = True
    text(row, '在本路召唤1名沙兵，继承召唤时自身{rank:0:1}最大生命和100%双防。攻击力为0，暴击、韧性、精准和闪避初始为0，存活4次自身行动。同时最多2名，以新替旧。')
    row = captain(1124)
    row.pop('manualSummonPolicy', None)
    row.pop('captainSummonMultiplier', None)
    row['skill'][2] = ['strong', .8, 2, STRONG]
    row['actionTargetPolicies'][2] = 'ally_lane_all'
    row['actionTargetMaxTargets'][2] = -1
    row['sixStarBatchSandHeal105'] = True
    endpoint(row, 0, 1, 14)
    row['skill'][1][2] = 600
    text(row, '对本路前方最多3名敌人造成{rank:0:1}攻击力魔法伤害并击退600。回满自身仍存活的沙兵生命，并为本路全体友军提供{rank:2:1}力量2回合。')

    ziggs_fx = 'FX_A_1125_MAGIC'
    compound(normal(1125), 'batch_ziggs_n', 0, 0, 3000, ziggs_fx, [1.2, 1.2, .25, .25],
             '对本路当前目标造成{rank:0:4}攻击力魔法伤害，对其附近400范围内其他敌人造成{rank:0:5}攻击力魔法伤害。主目标额外受到{rank:0:6}衰弱和{rank:0:7}破甲，持续2回合。')
    compound(captain(1125), 'batch_ziggs_c', 2, 4, 9999, ziggs_fx, [5.5, 2.75],
             '对全图生命上限最高的敌方英雄造成{rank:0:4}攻击力真实伤害，对其附近400范围内最多3名其他敌人造成{rank:0:5}攻击力真实伤害。')
    compound(passive(1125), 'batch_ziggs_p', 0, 0, 0, ziggs_fx, [.6],
             '造成伤害时，使目标受到的治疗降低{rank:0:4}，持续2回合，重复施加刷新持续时间。')

    row = normal(1126)
    timing(row, 1, 1)
    row['skill'][2][2] = row['skill'][3][2] = 400
    text(row, row['rankInfoTemplate'].replace('击退150码', '击退400码'))
    row = captain(1126)
    endpoint(row, 1, 3, .8)
    for index in range(3, 9):
        endpoint(row, index, 1, 1.25)
    text(row, '自身获得{flat:0:2}精准2回合。对本路当前目标先施加{rank:1:3}破甲2回合并驱散其增益，再连续投出6颗法球，每颗造成{rank:3:1}攻击力魔法伤害。')
    compound(passive(1126), 'batch_syndra_p', 0, 0, 0, 'FX_A_1126_MAGIC', [.3],
             '每经过10个战斗回合，永久提高自身造成的伤害{rank:0:4}，可叠加且不可驱散。')

    row = normal(1128)
    row['sixStarBatchShacoBox105'] = True
    row['skill'].append(['manual_ability', 'six_batch_shaco_box', 1, 'SUMMON_EFF', .8])
    row['actionTargetPolicies'].append('ally_self')
    row['actionTargetMaxTargets'].append(1)
    text(row, row['rankInfoTemplate'] + ' 在位移前的位置留下一个惊吓魔盒，继承自身{rank:3:4}面板属性，存在3次自身行动。')
    row = captain(1128)
    endpoint(row, 0, 1, 1)
    row['manualSummonPolicy'].update(skillId=row['id'], apRatio=1, hpRatio=1, dePhRatio=1, deMaRatio=1)
    row.pop('captainSummonMultiplier', None)
    row['sixStarBatchShacoClone105'] = True
    text(row, '在本路召唤1个继承自身{rank:0:1}面板属性的分身，存在3次自身行动，可使用小技能。随后本体后退250，获得{rank:2:1}力量和{flat:3:2}闪避2回合。')
    compound(passive(1128), 'batch_shaco_p', 0, 0, 0, MAGIC, [1.75, .8],
             '每当任意分路有敌人被成功施加诅咒，投掷匕首，造成{rank:0:4}攻击力魔法伤害并施加{rank:0:5}攻击力中毒2回合。')

    timing(normal(1136), 1, 1)
    row = captain(1136)
    row['pl'][2] = 9999
    args = row.get('actionTargetPolicyArgs', [])
    if len(args) > 1 and args[1]:
        for key in ('radius', 'maxRange', 'maxForwardDistance', 'effectRange'):
            args[1].pop(key, None)
    endpoint(row, 1, 1, 1)
    text(row, '自身获得{flat:0:2}精准2回合，然后连续射击12次，每次对本路自身前方最近的敌人造成{rank:1:1}攻击力物理伤害，无距离限制。')

    row = normal(1206)
    row['sixStarBatchRear105'] = True
    text(row, '优先锁定本路带有自身心印的最靠后敌人，否则选择本路最靠后敌人。连续射出2箭，每箭造成{rank:0:4}攻击力物理伤害。')
    row = captain(1206)
    row['sixStarBatchRear105'] = True
    text(row, '净化自身，获得{flat:0:6}闪避和{rank:0:5}力量2回合，并获得1次神佑。优先攻击本路带有自身心印的最靠后敌人，否则选最靠后敌人。连续射出3箭，每箭造成{rank:0:4}攻击力物理伤害。第三箭后将目标击退800。若撞到本路底线，额外造成600%攻击力真实伤害，并诅咒、眩晕1回合。')

    row = normal(1214)
    row['name'] = '万能选牌'
    compound(row, 'batch_tf_n', 0, 3, 9999, MAGIC, [3, .6],
             '向全图最多4名不同敌人各投出1张牌，造成{rank:0:4}攻击力魔法伤害并施加{rank:0:5}衰弱2回合。')
    row = captain(1214)
    row['name'] = '逆命'
    compound(row, 'batch_tf_c', 0, 0, 9999, MAGIC, [2.75, .25, 2, .5, 1, .3],
             '自身生命低于90%时释放，获得{rank:0:5}生命上限的护盾、{rank:0:6}双抗、{rank:0:7}力量、{rank:0:8}移动距离和净化，持续2回合。恢复{rank:0:9}已损失生命，对当前目标造成{rank:0:4}攻击力魔法伤害并眩晕1回合。')
    row = passive(1214)
    row['name'] = '窃法巧手'
    compound(row, 'batch_tf_p', 0, 0, 0, MAGIC, [1.7],
             '每第4次伤害命中同一个敌人时，窃取其一种属性增益或神佑，保留剩余时间。如果没有可窃取的增益，诅咒该敌人1回合并造成{rank:0:4}攻击力真实伤害。')

    row = normal(1223)
    for index in (2, 3, 4):
        endpoint(row, index, 1, .95)
    row = passive(1223)
    endpoint(row, 0, 12, .85)
    row = captain(1223)
    row['skill'].append(passive_step('buff', 'strong', .6, 2))
    text(row, row['rankInfoTemplate'] + ' 获得{rank:5:7}力量2回合。')

    endpoint(normal(1227), 0, 12, 1)
    row = passive(1227)
    timing(row, 0, 0)
    endpoint(row, 0, 5, 3)

    row = normal(1998)
    timing(row, warmup=3)
    for index in range(5):
        endpoint(row, index, 1, 1.65)
    row = captain(1998)
    endpoint(row, 1, 1, 6)
    endpoint(row, 3, 1, .75)
    text(row, '驱散本路全体敌人的增益，对全场敌人造成{rank:1:1}攻击力真实伤害。本路友军获得净化和{rank:3:1}力量3回合，自身获得1次神佑。')
    compound(passive(1998), 'batch_gabriel_p', 0, 0, 0, SLASH, [1],
             '施放小技能时，本路每有1名其他存活友军，缩短该次小技能冷却1回合，最低为0。')
