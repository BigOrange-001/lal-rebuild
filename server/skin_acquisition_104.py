"""Acquisition policy frozen from the reviewed total strength ranking."""
import copy
import json
from pathlib import Path

PLAN = Path(__file__).resolve().parents[1] / 'config/reconstruction/skin-orange-acquisition-1.0.4.json'


def apply_skin_acquisition_104(document):
    cfg = document.get('cfg', document)
    policy = json.loads(PLAN.read_text(encoding='utf8'))
    heroes = cfg['avatar']
    tiers = {row['id']: row['tier'] for row in policy['heroes']}
    if len(tiers) != 35 or any(aid not in heroes or tier not in ('T1', 'T2')
                               for aid, tier in tiers.items()):
        raise ValueError('Skin orange ranking does not match hero definitions')
    family_tiers = {aid.rsplit('_', 1)[0]: tier for aid, tier in tiers.items()}
    calibrated = copy.deepcopy(cfg['summon_calibration'])
    # Three authored skins were present on the ranking but absent from the
    # legacy calibration. Give every ranked orange the approved acquisition.
    for pool in ('advanced', 'vip'):
        cards = calibrated['pools'][pool]['qualities']['orange']['cards']
        existing = {row['id'] for row in cards}
        cards.extend({'id': aid, 'name': heroes[aid]['name'], 'weight': 1}
                     for aid in tiers if aid not in existing)
    for pool in calibrated['pools'].values():
        for quality in pool['qualities'].values():
            for card in quality['cards']:
                card['weight'] = policy['weights'][family_tiers.get(card['id'].rsplit('_', 1)[0], 'other')]
    for quality in policy['normal_excluded_skin_qualities']:
        row = calibrated['pools']['normal']['qualities'][quality]
        row['cards'] = [card for card in row['cards'] if card['id'].rsplit('_', 1)[0] not in family_tiers]
    for quality in policy['advanced_excluded_skin_qualities']:
        row = calibrated['pools']['advanced']['qualities'][quality]
        row['cards'] = [card for card in row['cards'] if card['id'].rsplit('_', 1)[0] not in family_tiers]
    for card in calibrated['pools']['advanced']['qualities']['purple']['cards']:
        if card['id'].rsplit('_', 1)[0] in family_tiers:
            card['weight'] = policy['advanced_purple_skin_weight']
    calibrated['normalization']['vip_orange_skin_weight_multiplier'] = 1
    from summon_pools import SummonPools
    SummonPools(calibrated, heroes)
    for pool in ('advanced', 'vip'):
        ids = {row['id'] for row in calibrated['pools'][pool]['qualities']['orange']['cards']}
        if not set(tiers) <= ids:
            raise ValueError('Ranked skin orange is missing from summon pool')
    cfg['summon_calibration'] = calibrated
    t1 = sorted(aid for aid, tier in tiers.items() if tier == 'T1')
    t2 = [row['id'] for row in policy['heroes'] if row['tier'] == 'T2']
    cfg['system_simple']['skin_acquisition_blocked_heroes'] = []
    for aid, tier in tiers.items():
        heroes[aid]['acquisition_tier_104'] = tier
    extract = cfg['ploy_system_simple']['extract_avatar']
    extract['exchange'] = [[{'avatar': {aid: 1}}, policy['t2_point_price']] for aid in t2]
    extract['permanent_exchange_hero_ids'] = t2
    extract['min_vip_level'] = policy['vip_min_level']
    cfg['recruit_exchange_overlay'].update(
        skin_souls=[], t2_heroes=t2, card_price=policy['t2_point_price'], card_count=1)
    extract['activity_pool'] = [
        {'kind': 'avatar', 'aid': card['id'], 'weight': card['weight']}
        for quality in calibrated['pools']['vip']['qualities'].values()
        if quality['probability_percent'] > 0 for card in quality['cards']]
    timed = cfg['ploy_system_simple'].get('timed_exchange', [])
    cfg['ploy_system_simple']['timed_exchange'] = [row for row in timed
                                                 if not set(row) & set(t1)]
    cfg['skin_acquisition_104'] = policy
    return document
