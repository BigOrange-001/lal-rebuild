"""Built-in Champion Camille, her trophy, and both units' native media."""

import copy
import hashlib
import json
from pathlib import Path

CHAMPION = 'A_1804_6'
TROPHY = 'A_2905000_6'
NORMAL = 'S_98618040_6'
CAPTAIN = 'S_98618041_6'
PASSIVE = 'S_98618043_6'
RAIN = 'S_98618044_6'
MEDIA = Path(__file__).resolve().parents[1] / 'config/reconstruction/champion-camille-media'
WILD_FORMS = {'1': 'A_4001_1', '2': 'A_4001_2', '3': 'A_4001_3', '4': 'A_4004_4',
              '5': 'A_4014_5', '6': 'A_4015_6'}


def apply_champion_camille(document):
    cfg = document['cfg']
    if 'champion_camille' in cfg:
        return
    if set((CHAMPION, TROPHY)) & cfg['avatar'].keys() or set((NORMAL, CAPTAIN, PASSIVE, RAIN)) & cfg['skill'].keys():
        raise ValueError('Champion Camille identities are already in use')

    hero = copy.deepcopy(cfg['avatar']['A_1803_6'])
    hero.pop('demonbladeTryndamere105', None)
    hero.pop('tipTerms105', None)
    hero.update(id=CHAMPION, res='MOD_CHAMPION_CAMILLE_6', name='冠军-卡密尔', role='功能型',
                info='跨路开团，召唤冠军奖杯，并以惩戒压制敌方前排。', modUnitType='hero', ranged_skill=False)
    hero['tl'][0:5] = [3, 1, 1, 50, 99]
    hero['tl'][9] = max(row['tl'][9] for aid, row in cfg['avatar'].items() if aid.startswith('A_1')) + 1
    # The same six-star support panel used for the approved card draft.
    hero['pl'][:14] = [13904.175, 567.5173469388, 2256.45, 92.10, 822.675, 33.5785714286,
                       869.775, 35.5010204082, 245, 624, NORMAL, CAPTAIN, 'E_008', PASSIVE]
    cfg['avatar'][CHAMPION] = hero

    trophy = copy.deepcopy(cfg['avatar']['A_2001_4'])
    trophy.update(id=TROPHY, res='MOD_CHAMPION_TROPHY_6', name='奖杯', role='衍生召唤物',
                  modUnitType='summon', skill_diff=0, voiceDisabled104=True,
                  info='冠军-卡密尔的衍生召唤物。停在生成位置，不能普攻。')
    trophy['tl'][:5] = [3, 3, 1, 0, 99]
    trophy['tl'][8] = []
    trophy['pl'][:14] = [1, 0, 0, 0, 0, 0, 0, 0, 245, 0, RAIN, None, 'E_008', None]
    cfg['avatar'][TROPHY] = trophy

    def skill(sid, name, kind, warmup, cooldown, text, values, growth=()):
        cfg['skill'][sid] = dict(id=sid, name=name, info=text, rankInfoTemplate=text, res='S_9004_6',
                                pl=[warmup, cooldown, 3001, 0, 0, 1], skillUp=list(growth) or None,
                                skill=[['manual_ability', 'champion_camille_' + kind, 1, '', *values]],
                                actionTargetPolicies=['ally_self'], actionTargetMaxTargets=[1], calibration_104=True)

    engage = [TROPHY, 1, .075, 2, .10, 300, 3, 2, 5]
    skill(NORMAL, '强势开团', 'engage', 0, 3,
          '在原地召唤奖杯，再突进至全场攻击力最高的敌方英雄所在分路，将其拉至前排并眩晕2回合。'
          '对其和落点300范围内同路最多3名敌人，各造成{rank:0:5}攻击力＋{rank:0:6}目标最大生命的物理伤害，'
          '再造成{rank:0:7}攻击力＋{rank:0:8}目标最大生命的真实伤害。每座奖杯存续自身5个行动回合，可与其他奖杯共存。',
          engage, [[0, index, engage[index-4] / 9] for index in (5, 6, 7, 8)])
    skill(CAPTAIN, '冠军打野', 'smite', 1, 2,
          '使全场最大生命最高的敌方英雄变成同品质野怪2个自身行动回合，突进至其所在分路，'
          '再释放惩戒，造成其40%最大生命的真实伤害。惩戒必中且不可暴击。'
          '野怪可以移动和普攻。主动技能与条件发动的被动暂停，原生保命和复生仍可生效。', [.40, 2, WILD_FORMS])
    skill(PASSIVE, 'FMVP', 'fmvp', 0, 2,
          '受伤后仍存活且生命从高于30%降至不高于30%时，获得1层净化，'
          '并获得神佑及相当于自身50%最大生命的护盾，持续2回合。', [.30, .50, 2, 1])
    skill(RAIN, '金色的雨', 'rain', 0, 3,
          '使自身和全场存活的友方冠军-卡密尔各回复自身20%最大生命，并获得2层净化，'
          '然后只为奖杯自身施加一次神佑。复活不会重置奖杯寿命。', [CHAMPION, .20, 2])

    skins = cfg['system_simple'].setdefault('skin_hero_ids', [])
    skins.append(CHAMPION)
    calibration = cfg['summon_calibration']
    normalization = calibration['normalization']
    normalization['skin_hero_ids'] = sorted(set(normalization.get('skin_hero_ids', [])) | {CHAMPION})
    for pool in ('advanced', 'vip'):
        orange = calibration['pools'][pool]['qualities']['orange']['cards']
        reference = next(card for card in orange if card['id'] == 'A_1803_6')
        orange.append(dict(reference, id=CHAMPION, name=hero['name']))

    media = json.loads((MEDIA / 'manifest.json').read_text('utf-8'))
    cfg['builtin_assets_104']['assets'].extend(copy.deepcopy(media['assets']))
    cfg.setdefault('mod_runtime', {}).setdefault('assets', []).extend(copy.deepcopy(media['assets']))
    cfg['champion_camille'] = {'id': CHAMPION, 'trophy': TROPHY, 'media': media}


def builtin_asset(cfg, digest, path):
    media = cfg.get('champion_camille', {}).get('media', {})
    if digest != media.get('digest'):
        return None
    entry = next((row for row in media['assets'] if row['path'] == path), None)
    if entry is None:
        raise ValueError('Unknown Champion Camille asset')
    data = (MEDIA / entry['path']).read_bytes()
    if hashlib.sha256(data).hexdigest() != entry['sha256']:
        raise ValueError('Champion Camille media hash mismatch')
    return data, 'image/png'
