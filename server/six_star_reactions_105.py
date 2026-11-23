"""Six-star balance for Annie, Miss Fortune, Thresh, Evelynn, Elise and Zyra."""

from six_star_balance_105 import MAGIC, compound, endpoint, text, timing

PASSIVE_NAMES = {1029: '烈焰引爆', 1030: '大步流星', 1032: '摄魂', 1036: '盘丝', 1040: '荆棘遗种'}
PLANT_SKILL = 'S_985104001_5'


def apply_reactions(cfg, normal, captain, passive):
    row = normal(1029)
    row['pl'][2] = 9999
    row['actionTargetPolicyArgs'][0] = {'laneFilter': 'all'}
    row['sixStarReactionGlobalDot105'] = True
    endpoint(row, 0, 2, .65)
    text(row, '对全图所有敌人各施加1层独立计时的灼烧，持续5次目标行动，每次造成{rank:0:2}施加时攻击力的持续伤害。施放后永久增加{flat:1:2}点闪避，最多99层。灼烧期间受到治疗降低40%。')
    compound(passive(1029), 'reaction_annie_p', 0, 0, 0, 'FX_A_1029_MAGIC', [.4],
             '任一敌方单位累计至少4层灼烧时，立即清除其身上全部灼烧，按这些灼烧待结算总伤害的{rank:0:4}造成附加伤害，并眩晕目标1回合。所有来源的灼烧均计入。')

    row = captain(1030)
    row['pl'][1:5] = [4, 3000, 0, -1]
    row['actionTargetPolicies'] = ['enemy_lane_all'] * 2
    row['actionTargetMaxTargets'] = [-1] * 2
    row['actionTargetPolicyArgs'] = [None, None]
    row['skill'][1][1:3] = [-1, 8]
    row['sixStarReactionBarrage105'] = True
    endpoint(row, 1, 3, .7)
    text(row, '对本路所有敌人先施加{rank:0:3}破甲2回合，再连续造成8段{rank:1:3}攻击力物理伤害。')
    compound(passive(1030), 'reaction_mf_p', 0, 0, 0, 'FX_A_1030_PHYSICAL', [.8, .15, .15],
             '造成伤害时，以实际伤害的{rank:0:4}回复自身，溢出的治疗累加为无上限护盾。此护盾存在时，每次自身回合开始获得1层大步流星。每层提高{rank:0:5}造成伤害，并使伤害附加{rank:0:6}减疗1回合，减疗上限100%，不可驱散。实际损失生命时清空自身层数。')

    row = normal(1032)
    row['skill'][0][3] = 600
    text(row, row['rankInfoTemplate'].replace('拉近250码', '拉近600码'))
    row = captain(1032)
    row['skill'][1][1] = 650
    row['actionTargetPolicyArgs'][0]['radius'] = 650
    row['sixStarReactionThreshBox105'] = True
    text(row, '对自身650范围内本路敌人造成{rank:0:1}攻击力魔法伤害、击退200并眩晕1回合。为本路友军提供自身攻击力的{rank:3:1}加自身双抗之和的{rank:3:2}护盾，持续2回合，并提供净化。')
    compound(passive(1032), 'reaction_thresh_p', 0, 0, 0, 'FX_A_1032_MAGIC', [.2],
             '本路敌人每次被成功施加眩晕时，对其施加诅咒1回合，永久夺取其当前永久双抗的{rank:0:4}为己用。转移效果不可驱散。')

    row = normal(1033)
    timing(row, 1, 2)
    row['skill'][0] = ['select_target', 'FX_A_1033_MAGIC']
    row['sixStarReactionEvelynnTarget105'] = True
    text(row, '锁定本路施法范围内生命比例最低的敌人，先施加{rank:1:3}破甲2回合，再直接造成{rank:2:1}和{rank:3:1}攻击力魔法伤害，并回复两段实际造成伤害的{rank:4:1}生命。击杀后最多额外释放一次。')
    compound(captain(1033), 'reaction_evelynn_c', 1, 4, 3000, 'FX_A_1033_MAGIC', [9, 2.75],
             '本路存在生命低于40%的敌人时，对其中生命比例最低者造成{rank:0:4}攻击力魔法伤害，对本路其他敌人造成{rank:0:5}攻击力魔法伤害并沉默1回合。回满自身生命，后退3000并获得净化。')

    # Neurotoxin already applies a one-round stun on contact.
    normal(1036)
    compound(captain(1036), 'reaction_elise_c', 2, 2, 1500, 'FX_A_1036_MAGIC', [1, 4, 4],
             '获得{rank:0:4}生命上限的护盾2回合，突进到目标身边。对其造成{rank:0:5}攻击力魔法伤害，随目标已损失生命线性增加额外伤害，目标生命降至33%时额外伤害达到{rank:0:6}攻击力。回复该段实际造成的生命伤害。击杀时使盘丝冷却减少2回合。')
    compound(passive(1036), 'reaction_elise_p', 0, 6, 0, 'FX60_PURIFY', [],
             '受到伤害损失生命且结算后生命低于35%时，获得净化。随后免疫伤害1回合，并跳过下次行动。')

    plant = dict(id=PLANT_SKILL, name='疗愈', res='S_9000_5')
    compound(plant, 'reaction_plant_n', 0, 2, 0, 'FX60_HEAL', [1],
             '治疗本路所有友军，恢复{rank:0:4}植物攻击力的生命。已满生命的友军获得净化。')
    cfg['skill'][PLANT_SKILL] = plant
    for row in (normal(1040), captain(1040)):
        row['sixStarReactionPlant105'] = PLANT_SKILL
        row['manualSummonPolicy']['skillId'] = row['id']
        description = row.get('rankInfoTemplate', row['info']).replace('没有技能，会向前移动并普攻', '会普攻，也可施放疗愈')
        text(row, description + ' 疗愈准备0、冷却2，治疗本路所有友军100%植物攻击力，满血友军获得净化。')
    compound(passive(1040), 'reaction_zyra_p', 0, 0, 0, 'SUMMON_EFF', [.4],
             '阵亡后在原地召唤4株能使用疗愈的荆棘植物，继承当前小技能的植物面板比例。这些植物独立于普通召唤的数量上限。')
