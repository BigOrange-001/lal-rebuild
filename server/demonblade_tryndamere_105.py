"""Demonblade Tryndamere: orange skin with a rage resource and authored final kit."""
from __future__ import annotations
import copy

AID = 'A_1803_6'
NORMAL = 'S_98618030_6'
CAPTAIN = 'S_98618031_6'
PASSIVE = 'S_98618033_6'
EFFECT = 'FX_DEMON_TRYND105'

# Index constants shared with the simulator and client (action[0][index]).
# N_RAGE_NEED is a threshold only: Demon Slash never spends rage.
N_DAMAGE, N_SUNDER, N_RADIUS, N_TARGETS, N_LOW_HP, N_RAGE_NEED, N_HEAL_HP, N_HEAL_ATK = range(4, 12)
C_POWER, C_CRIT, C_WEAK, C_SPEND, C_SPEND_MIN, C_HEAL_ATK, C_HEAL_HP, C_AURA_RAGE, C_AURA_CAP = range(4, 13)
(P_BASIC, P_CRIT_PER_RAGE, P_ATK_PER_MISSING, P_ATK_CAP, P_FURY_COOLDOWN, P_FURY_LIMIT, P_FURY_RAGE,
 P_FURY_ROUNDS, P_FURY_ATK, P_FURY_END_HEAL, P_RAGE_START, P_RAGE_BASIC, P_RAGE_CRIT, P_RAGE_SKILL,
 P_RAGE_SKILL_CAP, P_RAGE_HURT, P_RAGE_HURT_CAP, P_RAGE_DECAY, P_FURY_ROUNDS_MEMBER, P_CRIT_DAMAGE_RATE) = range(4, 24)

NORMAL_TEXT = ('突进至本路敌方最前排面前，本路内无距离限制。对该敌人及其300范围内的敌人，最多3名，造成{rank:0:4}攻击力物理伤害，'
               '并施加25%破甲2回合；下一次普攻必定暴击。若施放时生命低于40%且怒气不少于40，先回复20%最大生命加100%攻击力的生命，'
               '不消耗怒气。')
CAPTAIN_TEXT = ('本路友军获得30%力量和4000暴击，持续2回合。对本路敌方前排及其后方最近一名敌人施加30%衰弱2回合。'
                '消耗当前一半怒气（至少20点），本路友军每人回复“消耗怒气×（10%蛮王攻击力＋1.5%蛮王最大生命）”的生命；'
                '满血的友军改为获得等量护盾2回合。任队长期间：本路友军每次暴击，蛮王获得2怒气，每次自身行动间隔最多10点。')
PASSIVE_TEXT = ('拥有怒气，上限100，开战时20。普攻命中获得5怒气，暴击再获得5怒气；技能每命中一名敌人获得5怒气，'
                '每次施放最多15点；受到敌方直接伤害获得2怒气，每次自身行动间隔最多8点；自身行动没有造成伤害时失去10怒气。'
                '普攻造成200%攻击力物理伤害。每点怒气使暴击率提高0.4%，上限100%。暴击属性带来的暴击伤害提高30%。'
                '每损失1%生命，攻击力提高0.8%，最多60%。'
                '无尽怒火：受到致死伤害时触发，冷却12个战斗回合，每场最多2次；先于神佑结算，且不消耗神佑。'
                '生命保留1点，解除并免疫诅咒，立即获得60怒气，攻击力提高60%，独立乘算，期间生命不会低于1；'
                '任队长时持续3回合，否则持续2回合。该状态不可驱散，沉默不影响触发，虚弱、击退和控制仍然生效。'
                '状态结束时消耗全部怒气，解除自身所有减益，并回复35%最大生命。')


def apply_demonblade_tryndamere(document):
    cfg = document.get('cfg', document)
    if cfg.get('demonblade_tryndamere_105'):
        return document
    if AID in cfg['avatar']:
        raise ValueError('Demonblade Tryndamere identity already exists')
    # Same orange skin panel as Kai'Sa and Nightbringer Yasuo; base Tryndamere art.
    hero = copy.deepcopy(cfg['avatar']['A_1206_6'])
    base = cfg['avatar']['A_1028_6']
    hero.update(id=AID, name='恶魔之刃蛮王', res=base['res'], role='战士',
                stat_profile=1, hero_category_104='skin', demonbladeTryndamere105=True,
                skill_diff=0, voiceDisabled104=True, ranged_skill=False)
    hero.pop('skin_revision_v2_104', None)
    hero['tl'][0] = base['tl'][0]
    hero['tl'][2] = 1
    hero['tl'][8] = []
    hero['tl'][9] = 1 + max(h['tl'][9] for k, h in cfg['avatar'].items() if k.startswith('A_1'))
    hero['pl'][10:14] = [NORMAL, CAPTAIN, hero['pl'][12], PASSIVE]
    hero['pl'][9] = 350
    cfg['avatar'][AID] = hero

    def row(sid, name, kind, preparation, cooldown, info, *values):
        return dict(id=sid, name=name, res='S_9004_6', pl=[preparation, cooldown, 3001, 0, 0, 0],
                    skill=[['manual_ability', kind, 1, EFFECT, *values]],
                    skillUp=None, info=info, rankInfoTemplate=info,
                    actionTargetPolicies=['ally_self'], actionTargetMaxTargets=[1],
                    demonbladeTryndamere105=True, calibration_104=True)

    q = row(NORMAL, '恶魔旋斩', 'demon_trynd_n', 0, 1, NORMAL_TEXT,
            1.6, .25, 300, 3, .4, 40, .2, 1.0)
    # Rank 1 is half of rank 10, matching the other ranked normal skills.
    q['skillUp'] = [[0, N_DAMAGE, 1.6 / 9]]
    c = row(CAPTAIN, '恶魔战吼', 'demon_trynd_c', 1, 3, CAPTAIN_TEXT,
            .3, 4000, .3, .5, 20, .1, .015, 2, 10)
    p = row(PASSIVE, '战斗狂怒', 'demon_trynd_p', 0, 0, PASSIVE_TEXT,
            2.0, .004, .008, .6, 12, 2, 60, 3, .6, .35, 20, 5, 5, 5, 15, 2, 8, 10, 2, 1.3)
    for skill in (q, c, p):
        cfg['skill'][skill['id']] = skill
    cfg['effect'][EFFECT] = {}
    skins = cfg['system_simple'].setdefault('skin_hero_ids', [])
    if AID not in skins:
        skins.append(AID)
    norm = cfg['summon_calibration']['normalization']
    norm['skin_hero_ids'] = sorted(set(norm.get('skin_hero_ids', []) + [AID]))
    for name in ('advanced', 'vip'):
        cards = cfg['summon_calibration']['pools'][name]['qualities']['orange']['cards']
        reference = next(card for card in cards if card['id'] == 'A_1206_6')
        cards.append(dict(reference, id=AID, name=hero['name']))
    cfg['demonblade_tryndamere_105'] = dict(id=AID, panelSource='A_1206_6', artSource='A_1028_6',
                                         skills=[NORMAL, CAPTAIN, PASSIVE], finalCoefficients=True)
    return document
