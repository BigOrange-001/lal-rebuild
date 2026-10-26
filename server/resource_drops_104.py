"""Higher resource tiers retain their reward and include earlier materials."""
from __future__ import annotations
import copy
import math


def apply_resource_drops_104(document):
    cfg = document.get('cfg', document)
    chapters = {}
    for cid, stage in cfg.get('combat_ploy', {}).items():
        if stage.get('activity_kind') == 'material' and stage.get('material_kind') in ('dust', 'enchant_book', 'talent'):
            chapters.setdefault(cid.rsplit('_', 1)[0], []).append(stage)
    for stages in chapters.values():
        stages.sort(key=lambda s: int(s.get('material_tier', s['id'].rsplit('_', 1)[1])))
        originals = [copy.deepcopy(s.get('resource_reward_original_104', s.get('reward', {}))) for s in stages]
        for tier, stage in enumerate(stages):
            reward = copy.deepcopy(originals[tier])
            kind = stage['material_kind']
            for earlier in range(tier):
                factor = 1 + .25 * (tier - earlier)
                if kind in ('dust', 'talent'):
                    key = 'dust' if kind == 'dust' else 'sp'
                    target = reward.setdefault('attrs', {}).setdefault(key, [0] * (4 if key == 'dust' else 6))
                    for color, amount in enumerate(originals[earlier].get('attrs', {}).get(key, [])):
                        target[color] = max(target[color], math.ceil(amount * factor))
                else:
                    items = reward.setdefault('items', [])
                    for item in originals[earlier].get('items', []):
                        match = next((r for r in items if r['eid'] == item['eid']), None)
                        amount = math.ceil(item['num'] * factor)
                        if match:
                            match['num'] = max(match['num'], amount)
                        else:
                            items.append({**item, 'num': amount})
            stage['resource_reward_original_104'] = originals[tier]
            stage['reward'] = reward
            info = stage.get('info', '').split('；')
            info[0] = '胜利获得本阶及低阶素材（具体数量见掉落预览）'
            stage['info'] = '；'.join(info)
    if 'cfg' in document:
        document['combat_ploy'] = cfg['combat_ploy']
        if isinstance(document.get('pve'), dict):
            document['pve']['combat_ploy'] = cfg['combat_ploy']
    return document
