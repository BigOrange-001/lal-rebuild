"""Balanced, reproducible 10-seat hero strength study with per-battle shares."""
from __future__ import annotations
import argparse
import collections
import concurrent.futures
import copy
import csv
import gzip
import hashlib
import json
import math
import os
from pathlib import Path
import random
import time

from gateway import load_game_config
from battle_engine import base_unit
from hero_strength_instrumentation import MeasuredBattle, unsupported_manual_skills
from hero_strength_native_bridge import NativeSkinBattle

ROOT=Path(__file__).resolve().parents[1]
CFG=None
TEMPLATES=None
POOLS=None
EPOCH=0


def load_study_policy():
    path=ROOT/'config/reconstruction/hero-strength-study-policy.json'
    return json.loads(path.read_text('utf8')) if path.exists() else dict(excluded_families=[])


def study_config():
    cfg=load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']
    old=json.loads((ROOT/'config/reconstruction/hero-balance-1.0.3.json').read_text('utf8'))['heroes']
    current={aid.split('_')[1] for aid,h in cfg['avatar'].items()
             if aid.startswith('A_1') and len(aid.split('_')[1])==4 and aid.endswith(('_5','_6'))
             and h.get('name') and '序号' not in h['name']}
    excluded=set(load_study_policy()['excluded_families'])
    families=sorted(f for f in ({r['aid'].split('_')[1] for r in old}|current) if 'A_'+f not in excluded)
    skins=set(cfg['system_simple']['skin_hero_ids'])
    heroes=[]
    for family in families:
        aid=next(a for a in (f'A_{family}_6',f'A_{family}_5') if a in cfg['avatar'])
        h=cfg['avatar'][aid]
        # Retain the historical equal-orange-panel convention for purple-only cards.
        normalized=aid.endswith('_5')
        if normalized:
            h['pl'][:8]=[v*2 for v in h['pl'][:8]]
        heroes.append(dict(aid=aid,name=h['name'],category='skin' if aid in skins or h.get('hero_category_104')=='skin' else 'ordinary',
                           purple_orange_model=normalized,old_aid=next((x['aid'] for x in old if x['aid'].split('_')[1]==family),None)))
    pools={'mixed':[x['aid'] for x in heroes],
           'ordinary':[x['aid'] for x in heroes if x['category']=='ordinary'],
           'skin':[x['aid'] for x in heroes if x['category']=='skin']}
    missing=unsupported_manual_skills(cfg,pools['mixed'])
    from skin_revision_104 import PARAMS
    missing={aid:[k for k in kinds if not (k.startswith('skin2_') and int(k.split('_')[1]) in PARAMS)] for aid,kinds in missing.items()}
    missing={aid:k for aid,k in missing.items() if k}
    if missing:raise ValueError(f'Unsupported skills: {missing}')
    return cfg,heroes,pools


def initialize(config_path):
    global CFG,TEMPLATES,POOLS,EPOCH
    payload=json.loads(Path(config_path).read_text('utf8'))
    CFG=payload['cfg'];POOLS=payload['pools'];EPOCH=payload.get('seed_epoch',0);TEMPLATES={}
    for aid in POOLS['mixed']:
        for seat in range(10):
            side=1+seat//5;slot=seat%5
            # Native equal-progression snapshots, with explicit study-level 125.
            u=base_unit(CFG,aid,99,10,0,.2+.13*slot,slot==0,side)
            h=CFG['avatar'][aid]['pl']
            u.update(lv=125,**{key:int(h[i]+124*h[i+1]) for key,i in [('hp_max',0),('ap',2),('de_ph',4),('de_ma',6)]})
            u['hp']=u['hp_max']
            TEMPLATES[(aid,seat)]=u


def schedule(pool,cycle,mode):
    """Each hero appears once in every seat per cycle; no hero repeats in a match."""
    rng=random.Random(103000000+EPOCH*10000000+{'mixed':0,'ordinary':1000000,'skin':2000000}[mode]+cycle)
    n=len(pool);cols=[]
    for seat in range(10):
        col=rng.sample(pool,n)
        # Repair forbidden pairs by swaps; never alter an already accepted column.
        for _ in range(n*100):
            bad=[i for i in range(n) if any(col[i]==prior[i] for prior in cols)]
            if not bad:break
            i=bad[0]
            options=[j for j in range(n) if j!=i and all(col[j]!=p[i] and col[i]!=p[j] for p in cols)]
            if not options:raise RuntimeError('Unable to construct distinct-hero schedule')
            j=rng.choice(options);col[i],col[j]=col[j],col[i]
        else:raise RuntimeError('Schedule repair exceeded bound')
        cols.append(col)
    return list(zip(*cols))


def blank():
    return dict(games=0,wins=0,draws=0,losses=0,damage_share=0.,healing_share=0.,taken_share=0.,
                damage=0.,healing=0.,taken=0.,seats=[0]*10,healing_zero_games=0)


def run_block(task):
    mode,start,stop,output=task
    path=Path(output)/'battles'/f'{mode}-{start:04d}-{stop:04d}.jsonl.gz'
    summary=path.with_suffix('.summary.json')
    if summary.exists():return json.loads(summary.read_text('utf8'))
    rows={aid:blank() for aid in POOLS[mode]};casts=collections.Counter();rounds=collections.Counter();total=0
    started=time.monotonic()
    partial=path.with_suffix('.partial')
    with gzip.open(partial,'wt',encoding='utf8',compresslevel=1) as record:
        for cycle in range(start,stop):
            for match,roster in enumerate(schedule(POOLS[mode],cycle,mode)):
                seed=1000000000+EPOCH*300000000+{'mixed':0,'ordinary':100000000,'skin':200000000}[mode]+cycle*1000+match
                teams=[[TEMPLATES[(aid,seat)] for seat,aid in enumerate(roster) if seat//5==side] for side in (0,1)]
                has_skin=any(CFG['avatar'][aid].get('skin_revision_v2_104') for aid in roster)
                cls=NativeSkinBattle if has_skin else MeasuredBattle
                b=cls(*teams,seed=seed,max_rounds=40,config=CFG)
                try:result=b.run()
                except Exception as exc:
                    raise RuntimeError(f'{mode} cycle={cycle} match={match} seed={seed} roster={roster} bridge={getattr(b,"bridge_error",None)}') from exc
                alive=[any(u['hp']>0 for u in team) for team in (b.a,b.b)]
                winner=0 if all(alive) or not any(alive) else 1 if alive[0] else 2
                stats=[]
                for seat,aid in enumerate(roster):
                    side=1+seat//5;slot=seat%5;u=(b.a if side==1 else b.b)[slot];token=u['_owner_token']
                    share=b.shares(side,token);raw=b.statistics[(side,token)];row=rows[aid]
                    row['games']+=1;row['seats'][seat]+=1
                    row['wins' if winner==side else 'draws' if winner==0 else 'losses']+=1
                    for key in ('damage','healing','taken'):
                        row[key]+=raw[key];row[key+'_share']+=share[key]
                    row['healing_zero_games']+=int(not any(v['healing'] for (team,_),v in b.statistics.items() if team==side))
                    stats.append([raw[k] for k in ('damage','healing','taken')]+[share[k] for k in ('damage','healing','taken')])
                casts.update(b.manual_casts);rounds[result['rounds']]+=1;total+=1
                record.write(json.dumps([seed,cycle,match,roster,winner,result['rounds'],stats],ensure_ascii=False,separators=(',',':'))+'\n')
    partial.replace(path)
    report=dict(mode=mode,start=start,stop=stop,battles=total,rows=rows,casts=dict(casts),rounds=dict(rounds),seconds=time.monotonic()-started)
    summary.write_text(json.dumps(report,ensure_ascii=False),encoding='utf8')
    return report


def aggregate(output,heroes,cycles,sampling_design='shared-balanced-rosters'):
    allrows={};blocks=[];casts=collections.Counter();rounds=collections.Counter()
    for p in sorted((output/'battles').glob('*.summary.json')):
        block=json.loads(p.read_text('utf8'));blocks.append({k:block[k] for k in ('mode','start','stop','battles','seconds')})
        casts.update(block['casts']);rounds.update(block['rounds'])
        for aid,r in block['rows'].items():
            row=allrows.setdefault((block['mode'],aid),blank())
            for k,v in r.items():
                if k=='seats':row[k]=[a+b for a,b in zip(row[k],v)]
                else:row[k]+=v
    lookup={x['aid']:x for x in heroes};result=[]
    for (mode,aid),r in allrows.items():
        n=r['games'];win=(r['wins']+.5*r['draws'])/n
        assert n==cycles*10 and r['seats']==[cycles]*10,(mode,aid,r)
        assert r['wins']+r['draws']+r['losses']==n
        variance=(r['wins']*(1-win)**2+r['draws']*(.5-win)**2+r['losses']*win**2)/(n-1) if n>1 else 0
        half=1.96*math.sqrt(variance/n)
        result.append(dict(mode=mode,**lookup[aid],**r,win_rate=win,draw_rate=r['draws']/n,
                           outright_win_rate=r['wins']/n,win_ci_low=max(0,win-half),win_ci_high=min(1,win+half),
                           **{'avg_'+k:r[k]/n for k in ('damage_share','healing_share','taken_share','damage','healing','taken')}))
    for mode in ('mixed','ordinary','skin'):
        group=sorted((r for r in result if r['mode']==mode),key=lambda r:(-r['win_rate'],-r['avg_damage_share'],r['aid']))
        for i,r in enumerate(group,1):r['rank']=i
    result.sort(key=lambda r:({'mixed':0,'ordinary':1,'skin':2}[r['mode']],r['rank']))
    report=dict(schema='hero-strength-104-half-draw-v2',sampling_design=sampling_design,win_rate_formula='(wins + 0.5 * draws) / games',cycles=cycles,games_per_hero=cycles*10,
                total_battles=sum(b['battles'] for b in blocks),blocks=blocks,heroes=heroes,rows=result,casts=dict(casts),rounds=dict(rounds),
                checks=dict(hero_counts={m:sum(r['mode']==m for r in result) for m in ('mixed','ordinary','skin')},
                            exact_games=True,balanced_sides_and_slots=True,full_roster_wins_equal_losses=all(sum(r['wins'] for r in result if r['mode']==m)==sum(r['losses'] for r in result if r['mode']==m) for m in ('mixed','ordinary','skin')) if sampling_design=='shared-balanced-rosters' else None))
    (output/'results.json').write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf8')
    fields=['rank','aid','name','category','games','wins','draws','losses','win_rate','draw_rate','avg_damage_share','avg_healing_share','avg_taken_share','win_ci_low','win_ci_high','avg_damage','avg_healing','avg_taken','healing_zero_games']
    for mode in ('mixed','ordinary','skin'):
        with (output/(mode+'.csv')).open('w',encoding='utf-8-sig',newline='') as f:
            writer=csv.DictWriter(f,fieldnames=fields,extrasaction='ignore');writer.writeheader();writer.writerows(r for r in result if r['mode']==mode)
    return report


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cycles',type=int,default=100)
    parser.add_argument('--workers',type=int,default=16)
    parser.add_argument('--block-cycles',type=int,default=10)
    parser.add_argument('--seed-epoch',type=int,default=0)
    parser.add_argument('--output',type=Path,default=ROOT/'outputs/hero-strength-20261030-1000')
    args=parser.parse_args();output=args.output.resolve();(output/'battles').mkdir(parents=True,exist_ok=True)
    cfg,heroes,pools=study_config();payload=dict(cfg=cfg,heroes=heroes,pools=pools,seed_epoch=args.seed_epoch,study_policy=load_study_policy())
    config=output/'frozen-config.json'
    encoded=json.dumps(payload,ensure_ascii=False,separators=(',',':'),default=str).encode('utf8')
    from hero_strength_freeze_104 import freeze_study
    config=freeze_study(output,encoded)
    jobs=[(m,start,min(args.cycles,start+args.block_cycles),str(output)) for m in pools for start in range(0,args.cycles,args.block_cycles)]
    print(json.dumps(dict(status='starting',heroes={k:len(v) for k,v in pools.items()},cycles=args.cycles,workers=args.workers,battles=sum(map(len,pools.values()))*args.cycles),ensure_ascii=False),flush=True)
    started=time.monotonic();completed=0;battles=0
    with concurrent.futures.ProcessPoolExecutor(max_workers=args.workers,initializer=initialize,initargs=(str(config),)) as executor:
        futures=[executor.submit(run_block,j) for j in jobs]
        for f in concurrent.futures.as_completed(futures):
            r=f.result();completed+=1;battles+=r['battles']
            status=dict(status='running',blocks_done=completed,blocks_total=len(jobs),battles_done=battles,elapsed_seconds=round(time.monotonic()-started,1),last_mode=r['mode'])
            (output/'progress.json').write_text(json.dumps(status),encoding='utf8');print(json.dumps(status),flush=True)
    report=aggregate(output,heroes,args.cycles)
    final_status=dict(status='complete',battles=report['total_battles'],checks=report['checks'],seconds=time.monotonic()-started)
    (output/'progress.json').write_text(json.dumps(final_status),encoding='utf8')
    print(json.dumps(final_status),flush=True)


if __name__=='__main__':main()
