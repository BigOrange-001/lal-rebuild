"""Portable B-affix commands and actual event traces for client parity work."""
import argparse
import copy
import json
from pathlib import Path

from abyss_equip_passives import initialize
from abyss_relics import A_TYPES, main_effect
from battle_engine import base_unit
from gateway import load_game_config
from manual_ability_sim import SkillCompleteBattle

ROOT = Path(__file__).resolve().parents[1]


def case_config(cfg):
    simple = {**cfg['system_simple'],'attack':list(cfg['system_simple']['attack'])}
    attack = simple['attack']
    attack[1]=.5
    attack[2]=attack[3]=attack[21]=1
    attack[4]=attack[5]=attack[15]=attack[16]=0
    return {**cfg,'system_simple':simple,'combat_rules':{}}


def input_units(cfg, kind, ancient):
    own = base_unit(cfg,'A_1001_5',1,1,leader=True)
    ally = base_unit(cfg,'A_1007_5',1,1)
    enemy = base_unit(cfg,'A_1009_5',1,1,team=2)
    for index,u in enumerate((own,ally,enemy)):
        u.update(instance_id=('owner','ally','enemy')[index],hp=1000,hp_max=1000,ap=100,
                 de_ph=0,de_ma=0,line=0,pos=1500,skill=None,skillB=None,book_skill=None,
                 talent=None,new_4attrs={'hit':0,'flee':0,'crit':0,'tough':0})
    own['leader_skill'] = {'skid':'S_fixture_5','pl':[4,6,1000,0,1],'skills':[['damage',1,1]]}
    own['equip_passives']=[main_effect(kind,ancient)]
    return [own,ally],[enemy]


def commands(kind):
    table = {
        1:[{'op':'initialize'}],
        2:[{'op':'damage','source':'owner','target':'enemy','amount':100}, {'op':'round','value':1},
           {'op':'damage','source':'owner','target':'enemy','amount':100}],
        3:[{'op':'damage','source':'enemy','target':'owner','amount':600},
           {'op':'damage','source':'enemy','target':'owner','amount':600}],
        4:[{'op':'buff','target':'owner','kind':'poison','amount':10},
           {'op':'buff','target':'owner','kind':'stun','amount':0},
           {'op':'damage','source':'enemy','target':'owner','amount':2000},
           {'op':'damage','source':'enemy','target':'owner','amount':2000}],
        5:[{'op':'damage','source':'enemy','target':'owner','amount':100}],
        6:[{'op':'dodge'},{'op':'dodge'},{'op':'dodge'},{'op':'round','value':1},{'op':'dodge'}],
        7:[{'op':'hp','target':'owner','value':500},{'op':'damage','source':'owner','target':'enemy','amount':100},
           {'op':'damage','source':'owner','target':'enemy','amount':100,'dot_kind':'burn'}],
        12:[{'op':'buff','target':'enemy','kind':'shield','amount':150},
            {'op':'damage','source':'owner','target':'enemy','amount':100}],
        14:[{'op':'hp','target':'ally','value':500},{'op':'heal','source':'owner','target':'ally','amount':100},
            {'op':'buff','source':'owner','target':'ally','kind':'shield','amount':100}],
        15:[{'op':'damage','source':'enemy','target':'ally','amount':100}],
        16:[{'op':'initialize'}],
        17:[{'op':'damage','source':'owner','target':'enemy','amount':100},
            {'op':'hp','target':'ally','value':0},{'op':'damage','source':'owner','target':'enemy','amount':100}],
        18:[{'op':'summon'}],
        19:[{'op':'initialize'}],
    }
    return [{'op':'initialize'}]+table[kind] if kind not in (1,16,19) else table[kind]


def state(battle):
    return {u.get('instance_id',u['_owner_token']):{
        'hp':u['hp'],'hp_max':u['hp_max'],'ap':u['ap'],
        'shield':battle._buff_value(u,'shield'),
        'buffs':sorted(v.type for v in u.get('_buffs',{}).values()),
        'leader_preparation':u.get('_skill_cd_leader')}
        for u in battle.a+battle.b}


def execute_case(cfg, kind, ancient=False, document=None):
    cfg = case_config(cfg)
    a,b = input_units(cfg,kind,ancient) if document is None else (document['input']['team_a'],document['input']['team_b'])
    battle = SkillCompleteBattle(a,b,seed=173,config=cfg)
    inputs = {'team_a':copy.deepcopy(a),'team_b':copy.deepcopy(b)}
    steps = commands(kind) if document is None else document['commands']
    results = []
    for command in steps:
        units = {u.get('instance_id'):u for u in battle.a+battle.b}
        source = units.get(command.get('source','owner'))
        target = units.get(command.get('target','owner'))
        op = command['op']
        if op=='initialize':initialize(battle)
        elif op=='round':battle.round_index=command['value']
        elif op=='hp':target['hp']=command['value']
        elif op=='damage':battle._injured(target,command['amount'],1,source=source,dot_kind=command.get('dot_kind'))
        elif op=='heal':battle._injured(target,command['amount'],4,source=source)
        elif op=='buff':battle._add_buff(target,command['kind'],3,command['amount'],source=source)
        elif op=='dodge':battle._emit_mod_event(units['owner'],'dodge',units['enemy'],units['owner'])
        elif op=='summon':
            summon = battle._spawn_summon(units['owner'],'A_2001_4',1,3)
            if not summon:raise AssertionError('summon failed')
            summon['instance_id']='summon'
            summon['_owner_token']='summon'
        results.append({'command':command,'units':state(battle),
                        'equipment_events':copy.deepcopy(getattr(battle,'equip_events',[])),
                        'rng_calls':battle.rng.calls})
    return {'schema':1,'kind':kind,'ancient':ancient,'seed':173,
            'combat_model':'legacy','attack_overrides':{str(i):cfg['system_simple']['attack'][i] for i in (1,2,3,4,5,15,16,21)},
            'input':inputs,'commands':steps,'expected':results}


def export_cases(destination):
    cfg = load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']
    destination = Path(destination);destination.mkdir(parents=True,exist_ok=True)
    count = 0
    for kind in range(1,21):
        if kind in A_TYPES:continue
        for ancient in ((False,) if kind==19 else (False,True)):
            result = execute_case(cfg,kind,ancient)
            (destination/f'{kind:02d}-{"ancient" if ancient else "normal"}.json').write_text(
                json.dumps(result,ensure_ascii=False,indent=2)+'\n','utf-8')
            count+=1
    print(json.dumps({'cases':count,'directory':str(destination)},ensure_ascii=False))


if __name__=='__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,default=ROOT/'docs/roguelite-abyss-equip-passive-cases')
    args = parser.parse_args()
    export_cases(args.output)
