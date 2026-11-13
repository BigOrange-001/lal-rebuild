"""Paired, independently sampled hero studies for the opt-in combat redesign."""
import argparse
import concurrent.futures
import gzip
import json
import math
from pathlib import Path
import time

import run_hero_strength_104 as shared
from run_hero_strength_independent_104 import run_focal, validate_games
from hero_strength_freeze_104 import freeze_study
from combat_rules import candidate_config, legacy_config

ROOT=Path(__file__).resolve().parents[1]


def compare(output):
    old=json.loads((output/'legacy/results.json').read_text('utf8'))
    new=json.loads((output/'ratio/results.json').read_text('utf8'))
    lookup={(r['mode'],r['aid']):r for r in old['rows']};rows=[]
    for r in new['rows']:
        o=lookup[r['mode'],r['aid']];diff=[]
        filename=f"{r['mode']}-{r['aid']}.jsonl.gz"
        with gzip.open(output/'legacy/battles'/filename,'rt',encoding='utf8') as a,gzip.open(output/'ratio/battles'/filename,'rt',encoding='utf8') as b:
            for x,y in zip(a,b,strict=True):
                x,y=json.loads(x),json.loads(y)
                assert x[:5]==y[:5]
                side=1+x[3]//5
                score=lambda z:0.5 if z[5]==0 else float(z[5]==side)
                diff.append(score(y)-score(x))
        mean=sum(diff)/len(diff)
        se=math.sqrt(sum((d-mean)**2 for d in diff)/(len(diff)-1)/len(diff))
        rows.append(dict(mode=r['mode'],aid=r['aid'],name=r['name'],category=r['category'],
                         old_rank=o['rank'],new_rank=r['rank'],old_win=o['win_rate'],new_win=r['win_rate'],
                         delta=mean,delta_ci_low=mean-1.96*se,delta_ci_high=mean+1.96*se,
                         games=len(diff),old_damage=o['avg_damage_share'],new_damage=r['avg_damage_share']))
    (output/'comparison.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf8')


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--games',type=int,default=100);p.add_argument('--workers',type=int,default=8)
    p.add_argument('--output',type=Path,default=ROOT/'build/combat-calibration-20261110')
    args=p.parse_args();validate_games(args.games)
    cfg,heroes,pools=shared.study_config();out=args.output.resolve();started=time.monotonic()
    for model in ('legacy','ratio'):
        folder=out/model;(folder/'battles').mkdir(parents=True,exist_ok=True)
        c=legacy_config(cfg) if model=='legacy' else candidate_config(cfg)
        payload=dict(cfg=c,heroes=heroes,pools=pools,sampling_design='independent-focal-hero',games_per_hero=args.games)
        frozen=freeze_study(folder,json.dumps(payload,ensure_ascii=False,separators=(',',':'),default=str).encode('utf8'))
        jobs=[(mode,aid,str(folder),args.games) for mode,pool in pools.items() for aid in pool]
        with concurrent.futures.ProcessPoolExecutor(max_workers=args.workers,initializer=shared.initialize,initargs=(str(frozen),)) as executor:
            for count,f in enumerate(concurrent.futures.as_completed([executor.submit(run_focal,j) for j in jobs]),1):
                block=f.result()
                status=dict(model=model,done=count,total=len(jobs),battles=count*args.games,seconds=round(time.monotonic()-started,1),last=block['focal'])
                (out/'progress.json').write_text(json.dumps(status),encoding='utf8')
                if count%10==0 or count==len(jobs):print(json.dumps(status),flush=True)
        shared.aggregate(folder,heroes,args.games//10,'independent-focal-hero')
    compare(out)
    print(json.dumps(dict(status='complete',seconds=round(time.monotonic()-started,1))),flush=True)


if __name__=='__main__':main()
