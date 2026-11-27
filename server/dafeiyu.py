"""Built-in Big Fish and his whale, adapted from the authored hero pack."""
import hashlib
import json
from pathlib import Path

from mod_effects import compile_skill


AID = 'A_1804_6'
WHALE = 'A_2906001_6'
MEDIA = Path(__file__).resolve().parents[1] / 'config/reconstruction/dafeiyu'
SKILLS = {
    'dafeiyu_attack': 'S_98618040_6',
    'o_jingjing': 'S_98618041_6',
    'dafeiyu_guard': 'S_98618043_6',
    'whale_charge': 'S_98618044_6',
}


def apply_dafeiyu(document):
    cfg = document['cfg']
    if 'dafeiyu' in cfg:
        return
    if {AID, WHALE} & cfg['avatar'].keys() or set(SKILLS.values()) & cfg['skill'].keys():
        raise ValueError('Big Fish avatar or skill ID already exists')

    references = {'self:hero/whale/quality5': WHALE}
    definitions = json.loads((MEDIA / 'skills.json').read_text(encoding='utf-8'))
    skills = {}
    for skill in definitions['skills']:
        sid = SKILLS[skill['id']]
        row = compile_skill(skill, sid, lambda ref, *_: references[ref] if ref else None)
        skills[sid] = row
    captain = skills[SKILLS['o_jingjing']]
    # The second blessing uses a built-in target selector, outside the public DIY DSL.
    captain['skill'][2][2] = 'ally_lane_lowest_hp_other_hero'
    cfg['skill'].update(skills)

    stats = [12238, 494.51020408, 1873, 76.44897959183675,
             853.5, 34.836734693877546, 816.5, 33.326530612244895]
    order = 1 + max(row['tl'][9] for aid, row in cfg['avatar'].items() if aid.startswith('A_1'))
    fish = dict(id=AID, name='大肥鱼！', res='MOD_DAFEIYU_6', role='攻击型',
                tl=[1, 1, 3, 45, 99, 1, 150, 120, [], order, 1],
                pl=stats + [250, 600, SKILLS['dafeiyu_attack'], SKILLS['o_jingjing'],
                            'E_008', SKILLS['dafeiyu_guard']],
                skillup=600, love=600, skill_diff=skills[SKILLS['dafeiyu_guard']]['modPassiveTrigger'],
                ranged_skill=True, voiceDisabled104=True, hero_category_104='skin')
    cfg['avatar'][AID] = fish
    cfg['avatar'][WHALE] = dict(id=WHALE, name='鲸鲸', res='MOD_DAFEIYU_WHALE_6', role='召唤物',
                                tl=[1, 1, 3, 0, 99, 1, 0, 0, [], 0, 1],
                                pl=stats + [400, 1000, SKILLS['whale_charge'], None, 'E_008', None],
                                modUnitType='summon', voiceDisabled104=True)

    cfg['system_simple'].setdefault('skin_hero_ids', []).append(AID)
    calibration = cfg['summon_calibration']
    normalization = calibration['normalization']
    normalization['skin_hero_ids'] = sorted(set(normalization['skin_hero_ids']) | {AID})
    for name in ('advanced', 'vip'):
        cards = calibration['pools'][name]['qualities']['orange']['cards']
        reference = next(card for card in cards if card['id'] == 'A_1803_6')
        cards.append(dict(reference, id=AID, name=fish['name']))

    media = json.loads((MEDIA / 'manifest.json').read_text(encoding='utf-8'))
    cfg['builtin_assets_104']['assets'].extend(media['assets'])
    cfg.setdefault('mod_runtime', {}).setdefault('assets', []).extend(media['assets'])
    cfg['dafeiyu'] = {'media': media}


def builtin_asset(cfg, content_digest, path):
    media = cfg.get('dafeiyu', {}).get('media', {})
    if content_digest != media.get('digest'):
        return None
    entry = next((row for row in media['assets'] if row['path'] == path), None)
    if entry is None:
        raise ValueError('Unknown Big Fish asset')
    data = (MEDIA / entry['path']).read_bytes()
    if hashlib.sha256(data).hexdigest() != entry['sha256']:
        raise ValueError('Big Fish media hash mismatch')
    return data, 'image/png'
