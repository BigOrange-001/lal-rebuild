"""Isolated difficulty-1 normal fights with unmodified starting decks."""
import json
from pathlib import Path

from abyss_calibrate import lineup
from gateway import load_game_config
from manual_ability_sim import SkillCompleteBattle
from roguelite_abyss import rules,hero_record,standard_team,generate_enemies,rng_for

ROOT=Path(__file__).resolve().parents[1]


def trials(document):
    cfg=document['cfg'];plan=rules(cfg);results=[]
    for deck,definition in plan['decks'].items():
        for seed in range(20261126,20261138):
            aids=definition['members'][:]
            if deck=='star':
                rng=rng_for(seed,'star')
                aids=[rng.choice(plan['skin_purple'])]+rng.sample(plan['initial_purple'],4)
            run={'pool':{a.rsplit('_',1)[0]:hero_record(a) for a in aids}}
            node={'id':'1-6-0','act':1,'type':'normal'}
            enemy=generate_enemies(seed,1,node,cfg)
            rows=[]
            for attempt in range(2):
                own=standard_team(cfg,run['pool'],lineup(run,attempt))
                combat_seed=rng_for(seed,'starter_normal',attempt).randrange(1,2**31)
                report=SkillCompleteBattle(own,enemy,seed=combat_seed,max_rounds=120,config=cfg).run()
                a_alive=any(u['hp']>0 for u in report['team_a']);b_alive=any(u['hp']>0 for u in report['team_b'])
                win=bool(a_alive and not b_alive)
                rows.append({'attempt':attempt+1,'combat_seed':combat_seed,'win':win,
                             'censored':bool(a_alive and b_alive),'rounds':report['rounds']})
                if win:break
            results.append({'deck':deck,'seed':seed,'passed':rows[-1]['win'],'attempts':rows})
    return {'schema':1,'native_verified':False,'difficulty':1,'pool_growth':False,
            'trials':len(results),'passes':sum(r['passed'] for r in results),'results':results}


if __name__=='__main__':
    result=trials(load_game_config(ROOT/'config/reconstruction/full-config.json'))
    target=ROOT/'docs/roguelite-abyss-calibration-data/starter-trials.json'
    target.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n','utf-8')
    print(json.dumps({k:result[k] for k in ('trials','passes')},ensure_ascii=False))
