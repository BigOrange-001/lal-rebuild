"""Each hero has its own 1000 battles; incidental appearances never count."""
import argparse
import collections
import concurrent.futures
import gzip
import hashlib
import json
from pathlib import Path
import random
import time
import run_hero_strength_104 as shared
from hero_strength_instrumentation import MeasuredBattle
from hero_strength_native_bridge import NativeSkinBattle

ROOT=Path(__file__).resolve().parents[1]
DESIGN='independent-focal-hero'
MODE_INDEX={'mixed':0,'ordinary':1,'skin':2}


def focal_schedule(pool,aid,mode,games=1000):
    if games%10:raise ValueError('games must be a multiple of ten')
    hero_index=pool.index(aid)
    rng=random.Random(481000000+MODE_INDEX[mode]*1000000+hero_index*10000)
    seats=list(range(10))*(games//10);rng.shuffle(seats)
    others=[x for x in pool if x!=aid];teams_seen=set();opponents_seen=set()
    for index,seat in enumerate(seats):
        for _ in range(10000):
            picked=rng.sample(others,9);roster=picked[:seat]+[aid]+picked[seat:]
            side=seat//5
            friendly=frozenset(roster[side*5:side*5+5])
            enemy=frozenset(roster[(1-side)*5:(1-side)*5+5])
            if friendly not in teams_seen and enemy not in opponents_seen:break
        else:raise RuntimeError('Unique teammate/opponent sampling exhausted')
        teams_seen.add(friendly);opponents_seen.add(enemy)
        seed=1900000000+MODE_INDEX[mode]*100000000+hero_index*10000+index
        yield index,seat,seed,roster


def run_focal(task):
    mode,aid,output,games=task;out=Path(output)
    path=out/'battles'/f'{mode}-{aid}.jsonl.gz';summary=path.with_suffix('.summary.json')
    if summary.exists():return json.loads(summary.read_text('utf8'))
    row=shared.blank();casts=collections.Counter();rounds=collections.Counter();started=time.monotonic()
    partial=path.with_suffix('.partial')
    with gzip.open(partial,'wt',encoding='utf8',compresslevel=1) as record:
        for index,seat,seed,roster in focal_schedule(shared.POOLS[mode],aid,mode,games):
            teams=[[shared.TEMPLATES[(h,s)] for s,h in enumerate(roster) if s//5==side] for side in (0,1)]
            cls=NativeSkinBattle if any(shared.CFG['avatar'][h].get('skin_revision_v2_104') for h in roster) else MeasuredBattle
            b=cls(*teams,seed=seed,max_rounds=40,config=shared.CFG)
            try:result=b.run()
            except Exception as exc:raise RuntimeError(f'{mode} focal={aid} index={index} seed={seed} roster={roster} bridge={getattr(b,"bridge_error",None)}') from exc
            alive=[sum(u['hp']>0 for u in team) for team in (b.a,b.b)]
            winner=0 if all(alive) or not any(alive) else 1 if alive[0] else 2
            side=1+seat//5;owner=(b.a if side==1 else b.b)[seat%5];token=owner['_owner_token']
            shares=b.shares(side,token);raw=b.statistics[(side,token)]
            row['games']+=1;row['seats'][seat]+=1
            row['wins' if winner==side else 'draws' if not winner else 'losses']+=1
            for key in ('damage','healing','taken'):row[key]+=raw[key];row[key+'_share']+=shares[key]
            raw_stats=[]
            for s in range(10):
                u=(b.a if s<5 else b.b)[s%5];values=b.statistics[(1+s//5,u['_owner_token'])]
                raw_stats.append([values[k] for k in ('damage','healing','taken')])
            row['healing_zero_games']+=int(not sum(x[1] for x in raw_stats[(side-1)*5:side*5]))
            casts.update(b.manual_casts);rounds[result['rounds']]+=1
            record.write(json.dumps([seed,index,aid,seat,roster,winner,result['rounds'],alive,raw_stats,[shares[k] for k in ('damage','healing','taken')]],ensure_ascii=False,separators=(',',':'))+'\n')
    partial.replace(path)
    report=dict(mode=mode,focal=aid,start=0,stop=games,battles=games,rows={aid:row},casts=dict(casts),rounds=dict(rounds),seconds=time.monotonic()-started)
    summary.write_text(json.dumps(report,ensure_ascii=False),encoding='utf8')
    return report


def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--games',type=int,default=1000);p.add_argument('--workers',type=int,default=16)
    p.add_argument('--output',type=Path,default=ROOT/'outputs/hero-strength-independent-20261030-1000');args=p.parse_args()
    if args.games%10:raise ValueError('games must be a multiple of 10')
    out=args.output.resolve();(out/'battles').mkdir(parents=True,exist_ok=True)
    cfg,heroes,pools=shared.study_config()
    payload=dict(cfg=cfg,heroes=heroes,pools=pools,sampling_design=DESIGN,games_per_hero=args.games,study_policy=shared.load_study_policy())
    encoded=json.dumps(payload,ensure_ascii=False,separators=(',',':'),default=str).encode('utf8');config=out/'frozen-config.json'
    if config.exists() and config.read_bytes()!=encoded:raise RuntimeError('Existing frozen config differs')
    config.write_bytes(encoded)
    manifest={};sources=out/'sources'
    for folder in ('server','scripts'):
        for f in (ROOT/folder).glob('*.py'):
            target=sources/f.relative_to(ROOT);target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(f.read_bytes());manifest[str(f.relative_to(ROOT))]=hashlib.sha256(f.read_bytes()).hexdigest()
    for name in ('client/src/skin_revision_v2.aspart','client/src/stages/137_Avatar.as'):
        f=ROOT/name;target=sources/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(f.read_bytes());manifest[name]=hashlib.sha256(f.read_bytes()).hexdigest()
    manifest['frozen-config.json']=hashlib.sha256(encoded).hexdigest();(out/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
    plan=ROOT/'config/reconstruction/hero-balance-iteration-1.0.4.json';(out/'balance-plan.json').write_bytes(plan.read_bytes())
    jobs=[(mode,aid,str(out),args.games) for mode,pool in pools.items() for aid in pool]
    print(json.dumps(dict(status='starting',design=DESIGN,heroes={m:len(v) for m,v in pools.items()},games_per_hero=args.games,total_battles=len(jobs)*args.games)),flush=True)
    started=time.monotonic();done=0;battles=0
    with concurrent.futures.ProcessPoolExecutor(max_workers=args.workers,initializer=shared.initialize,initargs=(str(config),)) as executor:
        futures=[executor.submit(run_focal,job) for job in jobs]
        for future in concurrent.futures.as_completed(futures):
            block=future.result();done+=1;battles+=block['battles']
            status=dict(status='running',heroes_done=done,hero_environment_total=len(jobs),battles_done=battles,total_battles=len(jobs)*args.games,elapsed_seconds=round(time.monotonic()-started,1),last_mode=block['mode'],last_focal=block['focal'])
            (out/'progress.json').write_text(json.dumps(status),encoding='utf8');print(json.dumps(status),flush=True)
    result=shared.aggregate(out,heroes,args.games//10,DESIGN)
    status=dict(status='complete',total_battles=result['total_battles'],games_per_hero=args.games,seconds=time.monotonic()-started)
    (out/'progress.json').write_text(json.dumps(status),encoding='utf8');print(json.dumps(status),flush=True)


if __name__=='__main__':main()
