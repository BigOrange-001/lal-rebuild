"""Demonblade Tryndamere's five- and six-star forms and shared rage kit."""
from __future__ import annotations
import copy
import hashlib
import json
from pathlib import Path

AID = 'A_1803_6'
FIVE_STAR_AID = 'A_1803_5'
NORMAL = 'S_98618030_6'
CAPTAIN = 'S_98618031_6'
PASSIVE = 'S_98618033_6'
EFFECT = 'FX_DEMON_TRYND105'
MEDIA = Path(__file__).resolve().parents[1] / 'config/reconstruction/demonblade-media'

# Index constants shared with the simulator and client (action[0][index]).
# N_RAGE_NEED is a threshold only: Demon Slash never spends rage.
N_DAMAGE, N_SUNDER, N_RADIUS, N_TARGETS, N_LOW_HP, N_RAGE_NEED, N_HEAL_HP, N_HEAL_ATK = range(4, 12)
C_POWER, C_CRIT, C_WEAK, C_SPEND, C_SPEND_MIN, C_HEAL_ATK, C_HEAL_HP, C_AURA_RAGE, C_AURA_CAP = range(4, 13)
(P_BASIC, P_CRIT_PER_RAGE, P_ATK_PER_MISSING, P_ATK_CAP, P_FURY_COOLDOWN, P_FURY_LIMIT, P_FURY_RAGE,
 P_FURY_ROUNDS, P_FURY_ATK, P_FURY_END_HEAL, P_RAGE_START, P_RAGE_BASIC, P_RAGE_CRIT, P_RAGE_SKILL,
 P_RAGE_SKILL_CAP, P_RAGE_HURT, P_RAGE_HURT_CAP, P_RAGE_DECAY, P_FURY_ROUNDS_MEMBER, P_CRIT_DAMAGE_RATE) = range(4, 24)

NORMAL_TEXT = ('突进至本路敌方最前排面前，对其及300范围内最多3名敌人造成{rank:0:4}攻击力物理伤害并施加25%破甲2回合，'
               '下一次普攻必定暴击。生命低于40%且怒气不少于40时，先回复20%最大生命＋100%攻击力的生命，不消耗怒气。'
               '本分路内不受施法距离限制。')
CAPTAIN_TEXT = ('本路友军获得30%力量和4000暴击2回合；本路敌方前排及其后方最近一名敌人虚弱30%，持续2回合。'
                '消耗一半怒气（至少20），本路友军各回复“消耗怒气×（10%蛮王攻击力＋1.5%蛮王最大生命）”的生命，'
                '满血者改为获得等量护盾2回合。任队长时，本路友军每次暴击使蛮王获得2怒气，每次自身行动间隔最多10点。')
PASSIVE_TEXT = ('普攻造成200%攻击力物理伤害。每点怒气使暴击率提高0.4%；暴击属性带来的暴击伤害提高30%。'
                '每损失1%生命，攻击力提高0.8%，最多60%。受到致死伤害时进入无尽怒火。')
# Hero mechanic names: own popup color by what they do (rage orange, the undying fury blood red).
TIP_TERMS = {'怒气': 0xFF8A1E, '无尽怒火': 0xFF3D6E}
PASSIVE_NOTES = [
    ['怒气', '上限100，开战20。普攻命中+5，暴击再+5；技能每命中1名敌人+5，每次最多15；'
             '受到敌方直接伤害+2，每次行动间隔最多8；自身行动未造成伤害-10。'],
    ['无尽怒火', '生命保留1点，获得60怒气，攻击力独立提高60%，免疫诅咒，期间生命不低于1；任队长持续3回合，否则2回合。'
                 '结束时清空怒气、解除自身减益并回复35%最大生命。冷却12回合，每场最多2次；先于神佑结算且不消耗神佑；'
                 '沉默不影响触发，虚弱、击退和控制仍生效。'],
]


def apply_demonblade_tryndamere(document):
    cfg = document.get('cfg', document)
    if cfg.get('demonblade_tryndamere_105'):
        return document
    if AID in cfg['avatar'] or FIVE_STAR_AID in cfg['avatar']:
        raise ValueError('Demonblade Tryndamere identity already exists')
    # Same skin panel template as Kai'Sa and Nightbringer Yasuo.
    hero = copy.deepcopy(cfg['avatar']['A_1206_6'])
    base = cfg['avatar']['A_1028_6']
    hero.update(id=AID, name='恶魔之刃泰达米尔', res='MOD_DEMONBLADE_6', role='战士',
                stat_profile=1, hero_category_104='skin', demonbladeTryndamere105=True,
                skill_diff=0, voiceDisabled104=True, ranged_skill=False)
    hero.pop('skin_revision_v2_104', None)
    hero['tl'][0] = base['tl'][0]
    hero['tl'][2] = 1
    hero['tl'][8] = []
    hero['tl'][9] = 1 + max(h['tl'][9] for k, h in cfg['avatar'].items() if k.startswith('A_1'))
    hero['pl'][10:14] = [NORMAL, CAPTAIN, hero['pl'][12], PASSIVE]
    hero['pl'][9] = 350
    hero['tipTerms105'] = dict(TIP_TERMS)
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
    p['tipNotes105'] = [list(note) for note in PASSIVE_NOTES]
    for skill in (q, c, p):
        cfg['skill'][skill['id']] = skill

    purple = copy.deepcopy(cfg['avatar']['A_1206_5'])
    purple.update({key: hero[key] for key in ('name', 'role', 'stat_profile', 'hero_category_104',
                  'demonbladeTryndamere105', 'skill_diff', 'voiceDisabled104', 'ranged_skill')})
    purple.update(id=FIVE_STAR_AID, res='MOD_DEMONBLADE_5', tipTerms105={'怒气': TIP_TERMS['怒气']})
    purple['tl'][2] = hero['tl'][2]
    purple.pop('skin_revision_v2_104', None)
    purple['tl'][0] = base['tl'][0]
    purple['tl'][9] = hero['tl'][9] + 1
    purple['pl'][9] = hero['pl'][9]
    purple['pl'][10:14] = [NORMAL[:-1] + '5', CAPTAIN[:-1] + '5', purple['pl'][12], PASSIVE[:-1] + '5']
    cfg['avatar'][FIVE_STAR_AID] = purple

    for skill in (q, c):
        purple_skill = copy.deepcopy(skill)
        purple_skill.update(id=skill['id'][:-1] + '5', res='S_9004_5')
        cfg['skill'][purple_skill['id']] = purple_skill
    purple_passive = copy.deepcopy(p)
    rage_text = '每点怒气使暴击率提高0.4%。'
    purple_passive.update(id=PASSIVE[:-1] + '5', res='S_9004_5', info=rage_text,
                          rankInfoTemplate=rage_text, tipNotes105=[list(PASSIVE_NOTES[0])])
    # The existing client and simulator treat zero allowed uses as no Endless Rage.
    action = purple_passive['skill'][0]
    action[P_BASIC:P_RAGE_START] = [1.0, .004, 0, 0, 0, 0, 0, 0, 0, 0]
    action[P_FURY_ROUNDS_MEMBER] = 0
    action[P_CRIT_DAMAGE_RATE] = 1.0
    cfg['skill'][purple_passive['id']] = purple_passive

    cfg['effect'][EFFECT] = {}
    skins = cfg['system_simple'].setdefault('skin_hero_ids', [])
    skins.extend(aid for aid in (AID, FIVE_STAR_AID) if aid not in skins)
    norm = cfg['summon_calibration']['normalization']
    norm['skin_hero_ids'] = sorted(set(norm.get('skin_hero_ids', [])) | {AID, FIVE_STAR_AID})
    for name in ('advanced', 'vip'):
        cards = cfg['summon_calibration']['pools'][name]['qualities']['orange']['cards']
        reference = next(card for card in cards if card['id'] == 'A_1206_6')
        cards.append(dict(reference, id=AID, name=hero['name']))
    media = json.loads((MEDIA / 'manifest.json').read_text('utf-8'))
    cfg['builtin_assets_104']['assets'].extend(copy.deepcopy(media['assets']))
    cfg.setdefault('mod_runtime', {}).setdefault('assets', []).extend(copy.deepcopy(media['assets']))
    cfg['demonblade_tryndamere_105'] = dict(id=AID, panelSource='A_1206_6', media=media,
                                         skills=[NORMAL, CAPTAIN, PASSIVE], finalCoefficients=True)
    return document


def builtin_asset(cfg, digest, path):
    media = cfg.get('demonblade_tryndamere_105', {}).get('media', {})
    if digest != media.get('digest'):
        return None
    entry = next((row for row in media['assets'] if row['path'] == path), None)
    if entry is None:
        raise ValueError('Unknown Demonblade Tryndamere asset')
    data = (MEDIA / entry['path']).read_bytes()
    if hashlib.sha256(data).hexdigest() != entry['sha256']:
        raise ValueError('Demonblade Tryndamere media hash mismatch')
    return data, 'image/png'
