"""Nightbringer Yasuo: six-star scissors skin with the authored, unscaled kit."""
from __future__ import annotations
import copy
import hashlib
import json
from pathlib import Path

AID = 'A_1802_6'
NORMAL = 'S_98618020_6'
CAPTAIN = 'S_98618021_6'
PASSIVE = 'S_98618023_6'
MEDIA = Path(__file__).resolve().parents[1] / 'config/reconstruction/nightbringer-yasuo-media'


def apply_nightbringer_yasuo(document):
    cfg = document.get('cfg', document)
    if cfg.get('nightbringer_yasuo_104'):
        return document
    if AID in cfg['avatar']:
        raise ValueError('Nightbringer Yasuo identity already exists')
    hero = copy.deepcopy(cfg['avatar']['A_1206_6'])
    hero.update(id=AID, name='黑夜使者亚索', res='MOD_NIGHT_YASUO104',
                stat_profile=1, hero_category_104='skin', nightbringerYasuo104=True,
                skill_diff=0, voiceDisabled104=True)
    hero.pop('skin_revision_v2_104', None)
    hero['tl'][0] = 1
    hero['tl'][8] = []
    hero['tl'][9] = 1 + max(h['tl'][9] for k, h in cfg['avatar'].items() if k.startswith('A_1'))
    hero['pl'][10:14] = [NORMAL, CAPTAIN, hero['pl'][12], PASSIVE]
    hero['pl'][9] = 550
    cfg['avatar'][AID] = hero

    def row(sid, name, kind, preparation, cooldown, info, *values):
        return dict(id=sid, name=name, res='S_9004_6', pl=[preparation, cooldown, 3001, 0, 0, 0],
                    skill=[['manual_ability', kind, 1, 'FX_NIGHT_YASUO104', *values]],
                    skillUp=None, info=info, rankInfoTemplate=info,
                    actionTargetPolicies=['ally_self'], actionTargetMaxTargets=[1],
                    nightbringerYasuo104=True, calibration_104=True)

    q = row(NORMAL, '黑夜剑气', 'night_yasuo_n', 0, 2,
            '先获得一层净化：立即清除自身负面，并抵挡下一次负面效果。'
            '向前突进最多400距离，遇到敌方前排时停在其面前，随后攻击本分路所有敌人。'
            '对最前排敌方单位造成{rank:0:4}攻击力物理伤害并眩晕1回合；'
            '其余敌人受到该伤害系数60%的物理伤害，并额外降低{rank:0:5}攻击力，持续1回合。'
            '将本路敌方单位击退300距离。', 2.25, .33)
    q['skillUp'] = [[0, 4, .25], [0, 5, .33 / 9]]
    c = row(CAPTAIN, '狂风绝息斩', 'night_yasuo_c', 1, 4,
            '先进入融入黑夜状态，持续1回合：受到的所有伤害降低80%，造成的伤害提升50%，'
            '解除自身的眩晕、沉默、诅咒、中毒和烧伤，并免疫上述效果1回合。融入黑夜不可被驱散。额外获得一次神佑，'
            '并获得100%全攻击吸血，持续2回合；吸血不受精准加成。'
            '移动至本分路最前排敌人前方200距离处，对该目标依次造成175%、175%、444%攻击力物理伤害。',
            1.75, 1.75, 4.44)
    p = row(PASSIVE, '黑夜剑心', 'night_yasuo_p', 0, 0,
            '战斗开始时，自身暴击属性数值翻倍。自身每次攻击暴击后，获得自身最大生命值5%'
            '加25%攻击力的护盾；护盾可累加，每份独立持续2回合，后续获得护盾不刷新旧护盾的持续时间。')
    p['info'] += '自身所有攻击暴击时，额外造成该次暴击结算伤害35%的真实伤害，计算包含护盾吸收部分。追加真伤不再暴击。'
    p['rankInfoTemplate'] = p['info']
    for skill in (q, c, p):
        cfg['skill'][skill['id']] = skill
    cfg['effect']['FX_NIGHT_YASUO104'] = {}
    cfg['effect']['FX_NIGHT_YASUO_CONTACT104'] = {'nativeContact104':True}
    skins = cfg['system_simple'].setdefault('skin_hero_ids', [])
    if AID not in skins:
        skins.append(AID)
    norm = cfg['summon_calibration']['normalization']
    norm['skin_hero_ids'] = sorted(set(norm.get('skin_hero_ids', []) + [AID]))
    for name in ('advanced', 'vip'):
        cards = cfg['summon_calibration']['pools'][name]['qualities']['orange']['cards']
        reference = next(c for c in cards if c['id'] == 'A_1206_6')
        cards.append(dict(reference, id=AID, name=hero['name']))
    media = json.loads((MEDIA / 'manifest.json').read_text('utf-8'))
    hero['nightBuffLayout104'] = copy.deepcopy(media['buffLayout'])
    cfg['builtin_assets_104']['assets'].extend(copy.deepcopy(media['assets']))
    cfg.setdefault('mod_runtime', {}).setdefault('assets', []).extend(copy.deepcopy(media['assets']))
    cfg['nightbringer_yasuo_104'] = dict(id=AID, panelSource='A_1206_6',
                                      skills=[NORMAL, CAPTAIN, PASSIVE], media=media, finalCoefficients=True)
    return document


def builtin_asset(cfg, digest, path):
    manifest = cfg.get('nightbringer_yasuo_104', {}).get('media', {})
    if digest != manifest.get('digest'):
        return None
    entry = next((e for e in manifest['assets'] if e['path'] == path), None)
    if not entry:
        raise ValueError('Unknown Nightbringer Yasuo asset')
    file = (MEDIA / path).resolve()
    if not file.is_relative_to(MEDIA.resolve()):
        raise ValueError('Invalid Nightbringer Yasuo media path')
    data = file.read_bytes()
    if hashlib.sha256(data).hexdigest() != entry['sha256']:
        raise ValueError('Nightbringer Yasuo media hash mismatch')
    return data, 'image/png'
