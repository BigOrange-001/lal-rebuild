"""Development status without deleting hero definitions used by old saves."""
import copy
import json
from pathlib import Path

PLAN=Path(__file__).resolve().parents[1]/'config/reconstruction/abandoned-heroes-20261117.json'


def is_abandoned(config,aid):
    cfg=config.get('cfg',config)
    family=str(aid).split('|',1)[0].rsplit('_',1)[0]
    return family in cfg.get('system_simple',{}).get('abandoned_hero_families_105',[])


def apply_hero_catalog(document):
    cfg=document.get('cfg',document)
    plan=json.loads(PLAN.read_text('utf-8'))
    families={row['family'] for row in plan['abandoned']}
    cfg.setdefault('system_simple',{})['abandoned_hero_families_105']=sorted(families)
    cfg['hero_development_105']=copy.deepcopy(plan)
    for aid,hero in cfg.get('avatar',{}).items():
        if aid.rsplit('_',1)[0] in families:
            hero['development_status_105']='abandoned'
    for pool in cfg.get('summon_calibration',{}).get('pools',{}).values():
        for quality in pool.get('qualities',{}).values():
            quality['cards']=[card for card in quality['cards'] if not is_abandoned(cfg,card['id'])]
    return document
