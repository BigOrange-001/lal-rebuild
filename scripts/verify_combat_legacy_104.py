"""Compare disabled-model battles against the original git revision in isolation."""
import argparse
import gzip
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import types

ROOT=Path(__file__).resolve().parents[1]


def replay_cache(args):
    import run_hero_strength_104 as shared
    from hero_strength_instrumentation import MeasuredBattle
    from hero_strength_native_bridge import NativeSkinBattle
    folder=args.config.parent;shared.initialize(str(args.config));mismatches=[];count=0
    for path in sorted((folder/'battles').glob('*.jsonl.gz')):
        with gzip.open(path,'rt',encoding='utf8') as stream:
            row=json.loads(next(stream))
        seed,index,aid,seat,roster,winner,rounds,alive,raw,shares=row
        teams=[[shared.TEMPLATES[(h,s)] for s,h in enumerate(roster) if s//5==side] for side in (0,1)]
        cls=NativeSkinBattle if any(shared.CFG['avatar'][h].get('skin_revision_v2_104') for h in roster) else MeasuredBattle
        b=cls(*teams,seed=seed,max_rounds=40,config=shared.CFG);result=b.run()
        actual_alive=[sum(u['hp']>0 for u in team) for team in (b.a,b.b)]
        actual_winner=0 if all(actual_alive) or not any(actual_alive) else 1 if actual_alive[0] else 2
        stats=[]
        for s in range(10):
            u=(b.a if s<5 else b.b)[s%5];v=b.statistics[(1+s//5,u['_owner_token'])]
            stats.append([v[k] for k in ('damage','healing','taken')])
        if (actual_winner,result['rounds'],actual_alive,stats)!=(winner,rounds,alive,raw):mismatches.append(path.name)
        count+=1
    data=dict(battles=count,mismatches=mismatches,config=str(args.config))
    args.output.write_text(json.dumps(data,indent=2),encoding='utf8');print(json.dumps(data),flush=True)
    if mismatches:raise SystemExit(1)


def sample(args):
    if args.original:
        for name in ('combat_math','battle_engine','manual_ability_sim'):
            source=subprocess.check_output(['git','show',args.revision+':server/'+name+'.py'],cwd=ROOT)
            module=types.ModuleType(name);module.__file__=str(ROOT/'server'/(name+'.py'))
            sys.modules[name]=module
            exec(compile(source,module.__file__,'exec'),module.__dict__)
    import run_hero_strength_104 as shared
    from run_hero_strength_independent_104 import focal_schedule
    from hero_strength_instrumentation import MeasuredBattle
    from hero_strength_native_bridge import NativeSkinBattle
    shared.initialize(str(args.config));rows=[]
    for mode in ('ordinary','mixed','skin'):
        pool=shared.POOLS[mode]
        for aid in pool[::max(1,len(pool)//10)]:
            for index,seat,seed,roster in list(focal_schedule(pool,aid,mode,10))[:4]:
                teams=[[shared.TEMPLATES[(h,s)] for s,h in enumerate(roster) if s//5==side] for side in (0,1)]
                cls=NativeSkinBattle if any(shared.CFG['avatar'][h].get('skin_revision_v2_104') for h in roster) else MeasuredBattle
                b=cls(*teams,seed=seed,max_rounds=40,config=shared.CFG);result=b.run()
                rows.append(dict(mode=mode,aid=aid,index=index,rounds=result['rounds'],rng=b.rng.calls,
                    panels=[[u['aid'],u['hp'],u['ap'],u['de_ph'],u['de_ma']] for u in b.a+b.b],
                    statistics=sorted((str(k),v) for k,v in b.statistics.items()),casts=b.manual_casts))
    args.output.write_text(json.dumps(rows,ensure_ascii=False,sort_keys=True),encoding='utf8')


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--original',action='store_true');p.add_argument('--sample',action='store_true')
    p.add_argument('--replay-cache',action='store_true')
    p.add_argument('--revision',default='6cab382');p.add_argument('--config',type=Path,default=ROOT/'build/combat-calibration-20261110/legacy/frozen-config.json')
    p.add_argument('--output',type=Path,default=ROOT/'build/combat-calibration-20261110/legacy-differential.json')
    a=p.parse_args()
    if a.replay_cache:replay_cache(a);return
    if a.sample:sample(a);return
    paths=[]
    for original in (True,False):
        path=a.output.with_name('original-battles.json' if original else 'disabled-battles.json');paths.append(path)
        cmd=[sys.executable,'-B',__file__,'--sample','--revision',a.revision,'--config',str(a.config),'--output',str(path)]
        if original:cmd+=['--original']
        subprocess.run(cmd,check=True)
    old,new=[json.loads(path.read_text('utf8')) for path in paths]
    mismatches=[i for i,(x,y) in enumerate(zip(old,new,strict=True)) if x!=y]
    result=dict(revision=a.revision,battles=len(old),mismatches=mismatches,
                hashes={path.name:hashlib.sha256(path.read_bytes()).hexdigest() for path in paths})
    a.output.write_text(json.dumps(result,indent=2),encoding='utf8');print(json.dumps(result),flush=True)
    if mismatches:raise SystemExit(1)


if __name__=='__main__':main()
