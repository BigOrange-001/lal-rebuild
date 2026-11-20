"""Six-star balance endpoints, applied before hero and equipment bond variants."""
from copy import deepcopy

from equipment_bonds_104 import append_effect
from native_skill_snapshot import _native_skill_snapshot
from skill_balance_overlay import _set
from skill_output_104 import RATE, output_paths

MAGIC = 'FX60_MAGIC'
SLASH = 'FX60_SLASH'
SHIELD = 'FX60_SHIELD'
STRONG = 'FX60_STRONG'
STEEL = 'FX60_STEEL'
STUN = 'FX60_STUN'
WEAK = 'FX60_WEAK'
PURIFY = 'FX60_PURIFY'
HEAL = 'FX60_HEAL'
DASH = 'FX60_GAREN_DASH'


def text(row, description):
    row['info'] = row['rankInfoTemplate'] = description


def endpoint(row, index, position, value):
    """Set the authored value that will survive the final 80% output pass."""
    path = (position,)
    action = row['skill'][index]
    _set(action, path, value / RATE if path in output_paths(action) else value)
    growth = row.get('skillUp')
    if growth and isinstance(growth[0], list):
        row['skillUp'] = [entry for entry in growth if entry[:2] != [index, position]]
    elif growth and growth[0] == index and position == 1:
        row.pop('skillUp', None)


def timing(row, warmup=None, cooldown=None):
    if warmup is not None:
        row['pl'][0] = warmup
    if cooldown is not None:
        row['pl'][1] = cooldown


def rewrite(row, timing_and_target, actions, description, policies=None, caps=None):
    for key in list(row):
        if key.startswith(('actionTarget', 'manual', 'mod', 'rankDisplay')) or key in (
            'skillUp', 'skillUpPaths', 'chainDot', 'targetPolicy', 'captainSummonMultiplier',
            'rankPolicy', 'nativeAbilityParameters',
        ):
            row.pop(key)
    row['pl'] = timing_and_target
    row['skill'] = actions
    if policies is not None:
        row['actionTargetPolicies'] = policies
    if caps is not None:
        row['actionTargetMaxTargets'] = caps
    text(row, description)


def compound(row, kind, warmup, cooldown, reach, effect, values, description):
    rewrite(row, [warmup, cooldown, reach, 0, 0, 1],
            [['manual_ability', 'six_' + kind, 1, effect, *values]], description)


def add(row, action, policy):
    append_effect(row, {'action': action, 'policy': policy})


def passive_step(kind, buff, amount=0, duration=1, effect=STRONG):
    return ['mod_step', kind, 'self', -1, 0, 0, 0, amount, buff, duration, 0,
            None, 1, 3, 1, False, 3, effect, 0, 0]


def apply_six_star_balance(document):
    cfg = document.get('cfg', document)
    if cfg.get('six_star_balance_105'):
        return document
    from six_star_followup_105 import PASSIVE_NAMES, apply_followup
    from six_star_extended_105 import PASSIVE_NAMES as EXTENDED_NAMES, apply_extended
    from six_star_reactions_105 import PASSIVE_NAMES as REACTION_NAMES, apply_reactions
    passive_names = {1022:'满盈灵息', 1023:'暗影流血', 1025:'远程狙击', **PASSIVE_NAMES, **EXTENDED_NAMES, **REACTION_NAMES}
    avatars, skills = cfg['avatar'], cfg['skill']
    changed = {}

    def skill(number, slot):
        aid = f'A_{number}_6'
        hero = avatars[aid]
        pl = hero['pl']
        pl.extend([None] * max(0, slot + 1 - len(pl)))
        sid = pl[slot]
        if sid in changed.get(aid, set()):
            return skills[sid]
        if sid is None:
            sid = f'S_985{number}{slot}_6'
            skills[sid] = dict(id=sid, name=passive_names[number],
                               res=pl[10], pl=[0, 0, 0, 0, 0, 1], skill=[])
        elif any(other is not hero and sid in other['pl'][10:14] for other in avatars.values()):
            original = skills[sid]
            private = f'S_985{number}{slot}_6'
            skills[private] = dict(deepcopy(original), id=private,
                                  equipment_source_skill_104=original.get('equipment_source_skill_104', sid))
            skills[private].setdefault('res', sid)
            summon = {1132: 'A_2904004_6', 1223: 'A_2904006_6'}.get(number)
            if summon and slot==10 and avatars[summon]['pl'][10]==sid:
                # Independently configured summons keep their calibrated skill.
                cfg.setdefault('six_star_legacy_skill_slots_105',{})[sid]=slot
            sid = private
        pl[slot] = sid
        changed.setdefault(aid, set()).add(sid)
        skills[sid]['sixStarBalance105'] = True
        return skills[sid]

    def normal(number):
        return skill(number, 10)

    def captain(number):
        return skill(number, 11)

    def passive(number):
        return skill(number, 13)

    row = normal(1001)
    timing(row, cooldown=2)
    endpoint(row, 1, 1, 4)
    row = passive(1001)
    row['modCondition'].pop('hpBelow', None)
    row['skill'] += [passive_step('buff', 'purify', effect=PURIFY),
                     passive_step('buff', 'strong', .5, 2)]
    text(row, '自身护盾被敌人击破后，恢复{rank:0:6}自身生命上限的生命，获得{rank:1:6}自身生命上限的护盾和{rank:3:7}力量，持续2回合，并获得1次净化。每回合最多触发1次。')

    row = passive(1002)
    timing(row, cooldown=0)
    row['modCondition']['maxPerRound'] = 2
    text(row, '命中已眩晕的敌方英雄时，对其造成{rank:0:5}攻击力物理伤害。每回合最多触发2次。')

    row = normal(1003)
    timing(row, cooldown=1)
    endpoint(row, 2, 1, .2)
    text(row, '对本路一名敌人造成{rank:0:1}魔法伤害并眩晕1回合。自身获得{rank:2:1}最大生命值的护盾，持续2回合。')

    row = passive(1004)
    row['modCondition'].pop('otherHpBelow', None)
    row['modCondition']['otherHpNotFull105'] = True
    text(row, '治疗另一名友方英雄后，若其生命仍未满，为其额外恢复{rank:0:5}攻击力加{rank:0:6}自身最大生命值的生命。每回合最多触发1次。')

    row = normal(1005)
    row['sixStarClone105'] = True
    row['rankInfoTemplate'] = row.get('rankInfoTemplate', row['info']).split('分身继承')[0] + (
        '分身继承召唤时自身100%面板属性，攻击距离125，会移动和普攻，存在2次自身行动，起初嘲讽1回合。')
    row = passive(1005)
    compound(row, 'wukong_p', 0, 0, 0, SLASH, [1],
             '自身普攻或释放队长技能时，存活的分身也会执行同类动作。')

    row = normal(1006)
    row['skill'][0].insert(2, .05 / RATE)
    row['sixStarExactHeal105'] = True
    row['actionTargetPolicies'] = ['ally_lane_lowest_hp_ratio_n']*3
    row['actionTargetMaxTargets'] = [2]*3
    endpoint(row, 0, 1, 1)
    endpoint(row, 2, 1, .5)
    text(row, '治疗本路生命比例最低的2名友军，各恢复{rank:0:1}自身攻击力加{rank:0:2}自身最大生命值，并赋予精准和{rank:2:1}力量，持续1回合。')

    row = normal(1007)
    timing(row, warmup=0)
    endpoint(row, 1, 1, 3)
    row['actionTargetPolicies'][2] = 'enemy_lane_all'
    row['actionTargetMaxTargets'][2] = -1
    row['sixStarLaneStun105'] = True
    text(row, '突进至前排敌人，对其造成{rank:1:1}物理伤害，使本路所有敌人眩晕1回合，并为本路全体友军提供{rank:3:1}力量，持续2回合。')
    row = captain(1007)
    timing(row, 1, 3)
    endpoint(row, 0, 1, 1)
    endpoint(row, 1, 1, 4.5)
    text(row, '自身获得{rank:0:1}最大生命值的护盾，持续2回合。对目标及其附近300范围内敌人造成{rank:1:1}物理伤害并眩晕1回合。')
    compound(passive(1007), 'jarvan_p', 0, 0, 0, WEAK, [.5],
             '具有力量时，伤害命中的敌人获得{rank:0:4}破甲和{rank:0:4}虚弱，持续1回合。')

    timing(normal(1009), 2, 1)
    endpoint(passive(1009), 1, 6, .12)

    row = normal(1010)
    timing(row, 1, 1)
    endpoint(row, 3, 1, .7)
    compound(passive(1010), 'katarina_p', 0, 0, 0, STRONG, [.4],
             '击杀敌人后获得{rank:0:4}力量，持续2回合，并立即再释放一次普通技能。追放产生的击杀不连锁追放。')
    row = captain(1010)
    row['recastNormalOnceOnKill'] = False
    text(row, row.get('rankInfoTemplate', row['info']).split('；若本次技能击杀')[0] + '。')

    timing(normal(1011), 1, 1)
    compound(captain(1011), 'gangplank_c', 1, 1, 3000, SLASH, [3],
             '对本路前排敌人及其300范围内的其他敌人造成{rank:0:4}物理伤害。暴击时，该次伤害改为真实伤害。')
    compound(passive(1011), 'gangplank_p', 0, 0, 0, SLASH, [2],
             '释放队长技能后获得火刀标记。下一次普攻或有伤害的技能消耗标记，使首次命中的敌人点燃2回合，每回合造成{rank:0:4}自身攻击力的持续伤害。')

    row = normal(1012)
    dodge = _native_skill_snapshot(cfg, row['id'], 10)['skills'][1][2]
    compound(row, 'yi_n', 2, 2, 3000, SLASH, [2.7],
             '对本路最靠前的最多4名敌人造成{rank:0:4}物理伤害，自身获得{flat:1:2}闪避，持续1回合。')
    add(row, ['stat_flat', 'flee', dodge, 1, 'FX_S9140_FLEE'], 'ally_self')
    compound(captain(1012), 'yi_c', 0, 3, 0, STRONG, [.6, .2],
             '自身获得{rank:0:4}力量，清除并免疫衰弱，持续2回合。期间普攻和技能附加减伤前伤害的{rank:0:5}等额真实伤害。每击杀1名敌人，延长状态1回合。')
    row = passive(1012)
    row['modCondition'].update(event='kill', relation='enemy')
    timing(row, 0, 0)
    row['modCondition']['maxPerRound'] = 0
    row['modCondition']['sixStarRefreshNormal105'] = True
    text(row, '击杀敌人后，为自身恢复{rank:0:5}攻击力生命，并获得{rank:1:5}攻击力护盾，持续2回合。普通技能冷却清零。')

    row = passive(1013)
    timing(row, 0, 5)
    row['modCondition'] = {'kind': 'absent_buff', 'buff': 'shield'}
    endpoint(row, 0, 6, .8)
    text(row, '自身回合开始时若没有护盾，获得{rank:0:6}自身最大生命值的护盾，持续2回合。')
    compound(captain(1013), 'blitz_c', 2, 2, 3000, MAGIC, [5],
             '移除本路所有敌人的护盾和净化，沉默1回合，并造成{rank:0:4}魔法伤害。')

    for row in (normal(1014), captain(1014)):
        row['sixStarTurret105'] = True
        row['rankFixedPaths105'] = [[0, 1]]
        endpoint(row, 0, 1, 1.2)
        turret = '召唤继承自身{rank:0:1}面板的炮台，存在2回合。炮台不移动，普攻距离1000，每回合回复自身30%最大生命值。'
        if row is skills[avatars['A_1014_6']['pl'][10]]:
            row['pl'][2] = 3000
            add(row, ['damage', 1/RATE, 2, MAGIC], 'enemy_lane_frontmost')
            add(row, ['silence', 0, 1, 1, WEAK], 'enemy_lane_frontmost')
            row['actionTargetLocks'] = [None, None, 1]
            text(row, turret + ' 对当前目标造成{rank:1:1}魔法伤害并沉默1回合。')
        else:
            text(row, turret + ' 对本路最多3名敌人各造成3次{rank:1:3}魔法伤害，并施加{rank:2:3}衰弱1回合。')
    row = passive(1014)
    row['skill'][0][12] = 1.2
    row['sixStarTurret105'] = True
    text(row, '施放主动技能后，若本路600范围内至少有2个友方召唤物和2名敌人，额外部署1座继承自身{rank:0:12}面板的炮台。炮台不移动，普攻距离1000，每回合回复自身30%最大生命值，存在2次自身行动。同一被动最多保留1座，每回合最多触发1次。')

    row = normal(1015)
    timing(row, 0, 3)
    endpoint(row, 5, 1, 1)
    row['skill'].pop()
    row = passive(1015)
    row['modCondition'] = dict(kind='event', event='dodge', relation='enemy', maxPerRound=1, allowChain=False)
    endpoint(row, 0, 5, 9)
    text(row, '闪避敌方攻击时，对攻击者造成{rank:0:5}攻击力魔法伤害，并恢复{rank:1:5}攻击力生命。每回合最多触发1次。')
    compound(captain(1015), 'akali_c', 0, 0, 3000, MAGIC, [1.2],
             '对本路攻击最高的敌人造成{rank:0:4}魔法伤害，并眩晕1回合。')

    row = normal(1016)
    timing(row, 2, 1)
    row['sixStarLeech105'] = True
    text(row, row.get('rankInfoTemplate', row['info']) + ' 技能吸血效率100%。')
    row = captain(1016)
    endpoint(row, 4, 1, 1.25)
    row['sixStarAdvance105'] = True
    row['actionTargetPolicyArgs'][3] = {'radius': 600, 'sortBy': 'nearest'}
    text(row, '先突进至本路最前方，再对600范围内的本路敌人依次造成{rank:0:1}、{rank:1:1}、{rank:2:1}魔法伤害并眩晕1回合，自身获得{rank:4:1}最大生命值的护盾，持续2回合。')
    compound(passive(1016), 'kennen_p', 1, 0, 3000, MAGIC, [3.33],
             '技能就绪且本路至少有3名敌人处于眩晕时，对这些敌人各追加{rank:0:4}魔法伤害。')

    row = normal(1017)
    timing(row, 0, 2)
    row['skill'][4][0] = 'caster_hp_shield'
    endpoint(row, 4, 1, .5)
    add(row, ['steel', 1, 2, STEEL], 'ally_self')
    text(row, '对本路所有敌人造成{rank:0:1}物理伤害，再跃至前排敌人面前，对其造成{rank:2:1}物理伤害并眩晕1回合。自身获得{rank:4:1}最大生命值的护盾和{rank:5:1}双抗，持续2回合。')

    row = normal(1018)
    compound(row, 'shen_n', row['pl'][0], row['pl'][1], 0, SLASH, [.5],
             '强化接下来3次普攻。每次命中额外造成{rank:0:4}自身最大生命值的物理伤害。')
    row = captain(1018)
    row['sixStarShenTeleport105'] = True
    text(row, '本路还有其他友军时，允许传送到其他路。传送至全场当前生命值最低的其他友军面前；本路无其他友军时留在原处。为自己和目标提供{rank:1:1}自身最大生命值的护盾、{rank:2:1}力量及1次净化。')
    row = passive(1018)
    compound(row, 'shen_p', 0, 0, 0, SHIELD, [.5, .7],
             '释放任一主动技能后，自身获得{rank:0:4}最大生命值的护盾、{rank:0:5}双抗和嘲讽，持续2回合。')

    row = normal(1019)
    row['sixStarAxe105'] = True
    row['pl'][2] = 800
    row['skill'][0][3] = 800
    for args in row.get('actionTargetPolicyArgs', []):
        if args:
            for key in ('effectRange', 'radius', 'maxRange'):
                if args.get(key) == 350:
                    args[key] = 800
    # Remove the original per-skill bleed. The passive now owns all its stacks.
    snapshot = _native_skill_snapshot(cfg, row['id'], 10)['skills']
    row['skill'] = snapshot
    row['skill'].pop(3)
    row.pop('skillUp', None)
    row.pop('skillUpPaths', None)
    for key in ('actionTargetPolicies', 'actionTargetPolicyArgs', 'actionTargetMaxTargets',
                'actionTargetLocks', 'actionTargetGroups'):
        if len(row.get(key) or []) > 3:
            row[key].pop(3)
    endpoint(row, 3, 1, .22)
    endpoint(row, 3, 2, .66)
    text(row, '将本路前方800范围内最近的最多3名敌人拉近，先施加{rank:1:3}破甲，持续2回合，再造成{rank:2:1}物理伤害。每命中1名敌方英雄回复{rank:3:1}已损生命，最多回复{rank:3:2}。')
    compound(passive(1019), 'darius_p', 0, 0, 0, SLASH, [1, 1],
             '普攻及技能伤害命中后施加流血，每层每回合造成{rank:0:4}自身攻击力的持续伤害，持续3回合，对护盾伤害为3倍。最多5层，重新施加刷新全部层数。任意敌人达到5层时，自身在本场永久增加{rank:0:5}攻击力和双抗。')

    row = normal(1020)
    timing(row, 1, 2)
    endpoint(row, 3, 1, 3)

    row = normal(1021)
    endpoint(row, 1, 1, 1.5)
    endpoint(row, 2, 2, .15)
    row['sixStarEzrealHit105'] = True
    row['skill'][2][3] = 5
    text(row, '先为自身施加精准1回合，再对当前目标造成{rank:1:1}物理伤害。命中后叠加{rank:2:2}伤害增益，最多5层。')
    row = captain(1021)
    row['sixStarEzrealBarrage105'] = True
    for index, coefficient in zip((3, 5, 7, 9), (3.25, 3.25*5/6, 3.25*4/6, 3.25*3/6)):
        endpoint(row, index, 1, coefficient)
    text(row, '后退300，获得精准1回合，再按距离由近到远对本路最多4名敌人分别造成{rank:3:1}、{rank:5:1}、{rank:7:1}、{rank:9:1}魔法伤害，每个敌人最多命中1次。')
    row = passive(1021)
    timing(row, 0, 0)
    endpoint(row, 0, 5, 1.5)

    row = normal(1022)
    timing(row, 1, 1)
    row['sixStarOrb105'] = True
    row['pl'][2:5] = [1200, 0, -1]
    row['actionTargetPolicies'][:2] = ['enemy_lane_all_in_radius']*2
    row['actionTargetMaxTargets'][:2] = [-1]*2
    row['actionTargetPolicyArgs'][:2] = [{'radius': 1200} for _ in range(2)]
    text(row, '对本路1200范围内所有敌人先造成{rank:0:1}魔法伤害，再造成{rank:1:1}真实伤害，并为自己及300范围内的友军回复两段实际伤害总量的{rank:2:1}生命。')
    compound(captain(1022), 'ahri_c', 0, 0, 3000, MAGIC, [1.5, 1.25],
             '自身后退300，将本路攻击最高的敌人拉近500，遇到阵线即停，并对其造成{rank:0:4}魔法伤害。对本路其余最靠前的最多2名敌人各造成{rank:0:5}魔法伤害。')
    compound(passive(1022), 'ahri_p', 0, 0, 0, PURIFY, [3000],
             '满生命时受到治疗，自身获得1次净化及{flat:0:4}精准和闪避，持续1回合。')

    row = normal(1023)
    compound(row, 'talon_n', row['pl'][0], row['pl'][1], 900, 'FX_A_1023_PHYSICAL', [2, 2],
             '对本路自身前方900范围内所有敌人连续造成{rank:0:4}、{rank:0:5}物理伤害。')
    row = captain(1023)
    row['sixStarTalonChain105'] = True
    text(row, '释放前获得{rank:0:1}力量，持续2回合。对首个目标造成{rank:1:1}物理伤害，随后在本路最多弹射2次，每次同样造成{rank:1:1}物理伤害。')
    compound(passive(1023), 'talon_p', 0, 0, 0, SLASH, [1.25],
             '对同一敌人每造成3次技能伤害，使其流血3回合，每回合造成{rank:0:4}自身攻击力的持续伤害，该流血对护盾造成3倍伤害。')

    compound(normal(1025), 'caitlyn_n', 0, 3, 3000, 'FX_A_1025_PHYSICAL', [.25, 7],
             '后退500，对当前目标造成{rank:0:4}魔法伤害。下次自身回合开始时，对同一目标造成{rank:0:5}物理伤害，无距离限制。')
    compound(captain(1025), 'caitlyn_c', 2, 2, 9999, 'FX_A_1025_PHYSICAL', [8],
             '瞄准全场生命比例最低的敌人，造成{rank:0:4}物理伤害。子弹不能被其他敌人拦截。')
    compound(passive(1025), 'caitlyn_p', 0, 0, 0, SLASH, [2.5],
             '普通攻击造成{rank:0:4}攻击力伤害，攻击距离1350。')
    avatars['A_1025_6']['pl'][9] = 1350
    apply_followup(cfg, normal, captain, passive)
    apply_extended(normal, captain, passive)
    apply_reactions(cfg, normal, captain, passive)
    for aid in changed:
        pl = avatars[aid]['pl']
        actions = skills.get(pl[13], {}).get('skill', []) if len(pl)>13 else []
        if actions and actions[0][0]=='manual_ability' and actions[0][1].startswith('six_'):
            avatars[aid]['skill_diff'] = 0  # handled by the six-star action's own event
    cfg['six_star_balance_105'] = sorted(changed)
    return document
