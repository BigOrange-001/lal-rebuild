"""Relic versus fully developed orange gear, plus fixed soul-tower probes."""
import copy
import itertools
import json
import random
import statistics
from pathlib import Path

from abyss_relics import SUBSTATS, new_relic, main_effect
from battle_engine import serialize_player_team, serialize_stage_team
from gameplay_roster import GameplayRosterEquipment
from gateway import load_game_config
from manual_ability_sim import SkillCompleteBattle
from solo_progression import _native_team_power

ROOT=Path(__file__).resolve().parents[1]


def full_item(cfg,eid):
    pair=cfg['equip'][eid]['pl'][6:8]
    return {'eid':eid,'lv':200,'alchemy':[0,2],'halo':{'lv':20},
            'magic':[100]*4,'magic_stage5':1,'rune_lv':10,'symp':0,
            'stat_roll_ppm':1150000,'new_4attrs':{key:9600 for key in pair}}


def profile(cfg,aids):
    ids=[a+'|budget' for a in aids]
    p={'avatars':{iid:{'aid':aid,'lv':125,'slv':10,'phase':3,'limit_break':1} for iid,aid in zip(ids,aids)},
       'team':[ids],'attrs':{'team_num':0,'dn':{}},'my_equips':{},
       'as_equips':[[None]*7 for _ in range(6)],'abyss_relics':{}}
    for slot in range(len(ids)):
        for equipment_slot,eid in {0:'E_1001_6',2:'E_3001_6',3:'E_4002_6',4:'E_5002_6'}.items():
            iid=f'gear-{slot}-{equipment_slot}'
            p['my_equips'][iid]=full_item(cfg,eid)
            p['as_equips'][slot][equipment_slot]=iid
    return p


def relic(cfg,kind,keys=('hp','ap','de_ph')):
    item=new_relic(cfg,random.Random(5),kind)
    item['main']=main_effect(kind,kind!=19)
    item['substats']=[{'stat':key,'value':SUBSTATS[key][2]*1.25,'ancient':True} for key in keys]
    return item


def units(document,p):
    roster=GameplayRosterEquipment(None,document)
    ids=p['team'][0]
    return serialize_player_team(document['cfg'],p,0,
        [[iid,i%3,.25] for i,iid in enumerate(ids)],roster.battle_attributes)


def budget(document):
    cfg=document['cfg'];rows=[]
    for aid in ('A_1002_6','A_1001_6','A_1004_6'):
        p=profile(cfg,[aid]);base=_native_team_power(cfg,units(document,p))
        with_gear=copy.deepcopy(p)
        with_gear['my_equips']['extra']=full_item(cfg,'E_1001_6')
        with_gear['as_equips'][0][1]='extra'
        gear_delta=_native_team_power(cfg,units(document,with_gear))-base
        ratios=[]
        for keys in itertools.combinations(SUBSTATS,3):
            probe=copy.deepcopy(p);item=relic(cfg,1,keys)
            probe['abyss_relics'][item['id']]=item
            probe['as_equips'][0][6]=item['id']
            delta=_native_team_power(cfg,units(document,probe))-base
            ratios.append(delta/gear_delta)
        rows.append({'aid':aid,'gear_delta':gear_delta,'combinations':len(ratios),
                     'min_ratio':min(ratios),'median_ratio':statistics.median(ratios),
                     'max_ratio':max(ratios)})
    return rows


def tower(document):
    cfg=document['cfg'];rows=[]
    base=profile(cfg,['A_1001_6','A_1004_6','A_1009_6','A_1003_6','A_1014_6'])
    for floor in (100,125,150,180):
        stage=cfg['combat_ploy'][f'P_200_{floor}']
        enemy=serialize_stage_team(cfg,stage['team2'])
        stats=stage.get('enemy_unit_stats_by_diff',{}).get('0',[])
        for unit,authored in zip(enemy,stats):
            for key in ('hp','ap','de_ph','de_ma'):unit[key]=authored[key]
            unit['hp_max']=unit['hp']
            unit['new_4attrs']={key:authored.get(key,0) for key in ('hit','flee','crit','tough')}
        for kind in (0,1,3,4,7,12,14,15,16,17,18,19):
            probe=copy.deepcopy(base)
            if kind:
                item=relic(cfg,kind)
                probe['abyss_relics'][item['id']]=item
                probe['as_equips'][0][6]=item['id']
            own=units(document,probe)
            for seed in (173,174,175):
                report=SkillCompleteBattle(own,enemy,seed=seed,max_rounds=120,config=cfg).run()
                alive_a=sum(u['hp']>0 for u in report['team_a']);alive_b=sum(u['hp']>0 for u in report['team_b'])
                rows.append({'floor':floor,'relic':kind,'seed':seed,'win':bool(alive_a and not alive_b),
                             'censored':bool(alive_a and alive_b),'rounds':report['rounds']})
    return rows


if __name__=='__main__':
    document=load_game_config(ROOT/'config/reconstruction/full-config.json')
    result={'schema':1,'native_verified':False,'reference':'125级3阶橙英雄；四件200级8星满附魔/符文/洗练橙装；新增一件同样养成的普通橙武器',
            'main_power_rate':document['cfg']['system_simple']['abyss_relic_main_power_rate'],
            'budget':budget(document),'tower':tower(document)}
    target=ROOT/'docs/roguelite-abyss-relic-budget.json'
    target.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n','utf-8')
    print(json.dumps({'budget':result['budget'],'tower_battles':len(result['tower'])},ensure_ascii=False),flush=True)
