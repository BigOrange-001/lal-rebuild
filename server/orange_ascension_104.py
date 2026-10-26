"""Same-family purple -> orange ascensions, applied before bonds/output scaling."""
from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path

from hero_packs_104 import scale_outputs
from mod_effects import compile_skill

ROOT = Path(__file__).resolve().parents[1]
PLAN = ROOT / 'config/reconstruction/orange-ascension-1.0.4.json'
MEDIA = ROOT / 'config/reconstruction/orange-ascension-media'


def apply_orange_ascension_104(document):
    cfg = document.get('cfg', document)
    if cfg.get('orange_ascension_104'):
        return document
    plan = json.loads(PLAN.read_text('utf-8'))
    assets = json.loads((MEDIA/'manifest.json').read_text('utf-8'))
    avatars, skills = cfg['avatar'], cfg['skill']
    # The native turret is an explicit non-collectible summon. Effect-sequence
    # clients require this same classification before constructing a unit.
    avatars['A_2001_4']['modUnitType'] = 'summon'
    added = []
    next_order = max(int(h.get('tl', [0]*10)[9]) for h in avatars.values() if len(h.get('tl', [])) > 9) + 1
    for index, design in enumerate(plan['heroes']):
        aid, source = design['id'], design['source']
        if aid in avatars:
            raise ValueError('Orange ascension ID already exists: '+aid)
        row = copy.deepcopy(avatars[source])
        row.update(id=aid, res='MOD_ASC104_'+aid, hero_category_104='ordinary', orange_ascension_104=source)
        row['pl'][:8] = [round(v*2, 10) for v in row['pl'][:8]]
        row['tl'][3] = {1:45, 2:50, 3:48}[row['tl'][0]]
        row['tl'][6:8] = [150, 120]
        row['tl'][8] = []
        row['tl'][9] = next_order+index
        row['skillup'] = row['love'] = 600
        row['pl'] += [None]*max(0, 14-len(row['pl']))
        # Reuse the normal skill exactly, including its ID-bound summon/manual rules.
        old = row['pl'][11]
        sid = 'S_981'+aid.split('_')[1]+'_6'
        ultimate = copy.deepcopy(skills[old])
        ultimate.update(id=sid, name='真-'+ultimate['name'], equipment_source_skill_104=old)
        ultimate.setdefault('res', old)
        scale_outputs(ultimate, 1.1)
        kinds = [a[1] for a in ultimate['skill'] if a[0] == 'manual_ability']
        if kinds:
            field = 'manualEffectMultiplier' if kinds[0] == 'yi_c' else 'manualDamageMultiplier'
            ultimate[field] = ultimate.get(field, 1)*1.1
            note = '橙卡进阶：'+('力量与精准数值提高10%，持续时间与追击规则不变。' if kinds[0] == 'yi_c' else '伤害提高10%，原控制、位移与增益机制不变。')
            for key in ('info','rankInfoTemplate'):
                if key in ultimate: ultimate[key] += '\n'+note
        for key in ('manualClonePolicy','manualSummonPolicy'):
            if isinstance(ultimate.get(key), dict): ultimate[key]['skillId'] = sid
        skills[sid] = ultimate
        row['pl'][11] = sid
        pid = 'S_982'+aid.split('_')[1]+'_6'
        passive = compile_skill(design['passive'], pid, lambda ref,*_: ref.rsplit('/',1)[-1] if ref else None)
        passive['orange_ascension_104'] = aid
        skills[pid] = passive
        row['pl'][13], row['skill_diff'] = pid, 20
        avatars[aid] = row
        added.append(aid)
    # Ordinary-orange acquisition uses the existing quality probabilities and
    # the same within-quality weight as the established ordinary-orange cards.
    calibration = cfg['summon_calibration']
    for pool in ('advanced','vip'):
        cards = calibration['pools'][pool]['qualities']['orange']['cards']
        weight = next(c['weight'] for c in cards if c['id']=='A_1022_6')
        cards.extend(dict(id=aid,name=avatars[aid]['name'],weight=weight,custom=False,confirmed=False) for aid in added)
    cfg['ploy_system_simple']['extract_avatar']['activity_pool'] = [
        dict(kind='avatar',aid=c['id'],weight=c['weight'])
        for quality in calibration['pools']['vip']['qualities'].values() if quality['probability_percent']>0
        for c in quality['cards']]
    # Built-in media use the existing authenticated-client resource loader and
    # content-addressed transport; they are not an optional save-local Mod.
    cfg['builtin_assets_104'] = assets
    runtime = cfg.setdefault('mod_runtime', {})
    runtime['assets'] = copy.deepcopy(assets['assets'])
    cfg['orange_ascension_104'] = {'heroes':added, 'captainRate':1.1, 'panelRate':2,
                                  'schema':plan['schema'], 'mediaDigest':assets['digest']}
    return document


def builtin_asset(cfg, content_digest, path):
    manifest = cfg.get('builtin_assets_104', {})
    if content_digest != manifest.get('digest'):
        return None
    entry = next((r for r in manifest['assets'] if r['path'] == path), None)
    if entry is None:
        raise ValueError('Unknown built-in asset')
    file = (MEDIA/path).resolve()
    if not file.is_relative_to(MEDIA.resolve()):
        raise ValueError('Invalid built-in asset path')
    data = file.read_bytes()
    if hashlib.sha256(data).hexdigest() != entry['sha256']:
        raise ValueError('Built-in asset hash mismatch')
    return data, 'image/png'
