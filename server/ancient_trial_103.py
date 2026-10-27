"""Extend the authored ancient trial through tier 15, preserving tiers 1..10."""
import copy,math,random,re
from ancient_trial_overlay import _base_stats,EQUIPMENT_TYPES
from campaign_workbook_overlay import _fit_power
from gameplay_common import equipment_exclusive_ids

SCHEMA='ancient-trial-1.0.3-v1'
EXTENDED_CHANCES_BP={11:3000,12:3500,13:4000,14:4500,15:4500}

def _extended_team(cfg,template,tier):
    blocked=set(cfg['system_simple'].get('skin_hero_ids',[]))
    blocked.update(cfg['system_simple'].get('skin_acquisition_blocked_heroes',[]))
    candidates=sorted(aid for aid in cfg['avatar']
                      if re.fullmatch(r'A_1\d{3}_6',aid) and aid not in blocked)
    if len(candidates)<10:raise ValueError('Ancient trial requires ten ordinary orange heroes')
    previous=next(row[0] for row in template if row[5]==1)
    start=candidates.index(previous) if previous in candidates else 0
    captain=candidates[(start+tier-10)%len(candidates)]
    others=random.Random(f'ancient-trial-103-{tier}').sample([a for a in candidates if a!=captain],9)
    team=copy.deepcopy(template)
    for index,(row,aid) in enumerate(zip(team,[captain]+others)):
        row[0]=aid;row[5]=int(index==0)
    return team

def target_power(tier):
    if not 11<=tier<=15:raise ValueError('Extended ancient trial tier must be 11..15')
    return round(80_000_000*math.pow(25,(tier-10)/5))

def apply_ancient_trial_103(document):
    cfg=document.get('cfg',document)
    if cfg.get('ancient_trial_103',{}).get('schema')==SCHEMA:return document
    stages=copy.deepcopy(cfg['combat_ploy']);template=stages['P_001_10']
    exclusive=sorted(eid for eid in equipment_exclusive_ids(cfg)
                     if eid in cfg['equip'] and cfg['equip'][eid].get('quality')==6
                     and cfg['equip'][eid].get('type') in EQUIPMENT_TYPES)
    if not exclusive:raise ValueError('Ancient trial requires an exclusive orange equipment pool')
    for tier,chance in EXTENDED_CHANCES_BP.items():
        stage=copy.deepcopy(template);cid=f'P_001_{tier}'
        target=target_power(tier);team=_extended_team(cfg,template['team2'],tier)
        stats,actual=_fit_power(cfg,team,_base_stats(cfg,team),target)
        policy=copy.deepcopy(template['ancient_equip_drop'])
        policy.update(schema=SCHEMA,chance_bp=chance,quality=6)
        note=f'胜利有{chance/100:g}%概率获得一件随机普通橙色装备。'
        stage.update(id=cid,name=f'远古试炼·第{tier}档',index=tier,indexID_s=tier,
                     win=[-2],team2=team,ancient_equip_drop=policy,reward_note=note,
                     recommended_power=actual,recommended_power_by_diff={'0':actual},
                     enemy_snapshot_power=actual,enemy_unit_stats_by_diff={'0':stats})
        if tier==15:
            stage['ancient_exclusive_drop']={'schema':SCHEMA,'quality':6,'chance_bp':500,'pool':exclusive}
            stage['reward_note']+='另有5%概率额外获得一件专属橙装。'
        stage['info']='挑战10名强大的橙色英雄。'+stage['reward_note']
        stages[cid]=stage
    chapters=copy.deepcopy(cfg['battle_ploy']);chapters['P_001'].update(combat=15,info='常驻远古试炼，共15档；敌方全灭获胜，全部档位共享每日挑战次数。')
    cfg.update(combat_ploy=stages,battle_ploy=chapters,
               ancient_trial_103={'schema':SCHEMA,'tiers':15,'last_target_power':2_000_000_000})
    if 'cfg' in document:
        for key in ('combat_ploy','battle_ploy'):
            document[key]=cfg[key]
            if isinstance(document.get('pve'),dict):document['pve'][key]=cfg[key]
    return document
