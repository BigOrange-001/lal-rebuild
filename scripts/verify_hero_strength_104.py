"""Independently reconstruct final tables from the compressed battle records."""
import argparse
import collections
import gzip
import hashlib
import json
import math
from pathlib import Path


def verify(output):
    result=json.loads((output/'results.json').read_text('utf8'))
    cfg=json.loads((output/'frozen-config.json').read_text('utf8'))
    expected={(r['mode'],r['aid']):r for r in result['rows']}
    totals={k:dict(games=0,wins=0,draws=0,losses=0,seats=[0]*10,
                    damage=0.,healing=0.,taken=0.,damage_share=0.,healing_share=0.,taken_share=0.,healing_zero_games=0) for k in expected}
    seeds=set();matches=0
    for path in sorted((output/'battles').glob('*.jsonl.gz')):
        mode=path.name.split('-')[0];pool=set(cfg['pools'][mode])
        with gzip.open(path,'rt',encoding='utf8') as f:
            for line in f:
                seed,cycle,index,heroes,winner,rounds,stats=json.loads(line)
                assert seed not in seeds,(path,seed);seeds.add(seed)
                assert len(heroes)==len(set(heroes))==len(stats)==10
                assert set(heroes)<=pool and 1<=rounds<=40 and winner in (0,1,2)
                assert seed==1000000000+cfg.get('seed_epoch',0)*300000000+{'mixed':0,'ordinary':100000000,'skin':200000000}[mode]+cycle*1000+index
                assert 0<=cycle<result['cycles'] and 0<=index<len(pool)
                for seat,(aid,values) in enumerate(zip(heroes,stats)):
                    assert all(math.isfinite(v) and v>=0 for v in values)
                    side=1+seat//5;group=stats[seat//5*5:seat//5*5+5];r=totals[(mode,aid)]
                    r['games']+=1;r['seats'][seat]+=1
                    r['wins' if winner==side else 'draws' if not winner else 'losses']+=1
                    for i,key in enumerate(('damage','healing','taken')):
                        denominator=sum(x[i] for x in group);share=values[i]/denominator if denominator else 0
                        assert math.isclose(share,values[i+3],rel_tol=1e-12,abs_tol=1e-12)
                        r[key]+=values[i];r[key+'_share']+=share
                    r['healing_zero_games']+=int(not sum(x[1] for x in group))
                matches+=1
    for key,r in totals.items():
        e=expected[key]
        for field,value in r.items():
            if isinstance(value,float):assert math.isclose(value,e[field],rel_tol=1e-9,abs_tol=1e-7),(key,field,value,e[field])
            else:assert value==e[field],(key,field,value,e[field])
        assert r['games']==result['games_per_hero'] and r['seats']==[result['cycles']]*10
        for metric in ('damage','healing','taken'):
            assert math.isclose(r[metric+'_share']/r['games'],e['avg_'+metric+'_share'],abs_tol=1e-10)
        assert math.isclose((r['wins']+.5*r['draws'])/r['games'],e['win_rate'],abs_tol=1e-12)
    assert matches==result['total_battles']==sum(len(p) for p in cfg['pools'].values())*result['cycles']
    for name,digest in json.loads((output/'manifest.json').read_text('utf8')).items():
        file=output/name if name=='frozen-config.json' else output/'sources'/name
        assert hashlib.sha256(file.read_bytes()).hexdigest()==digest,name
    audit=dict(passed=True,actual_battles=matches,unique_seeds=len(seeds),hero_environment_rows=len(totals),
               total_hero_appearances=sum(x['games'] for x in totals.values()),games_per_hero_per_environment=result['games_per_hero'],
               same_match_distinct_heroes=True,category_pools_isolated=True,sides_and_slots_exact=True,
               raw_statistics_and_shares_recomputed=True,rankings_recomputed=True,source_hashes_verified=True)
    for mode in cfg['pools']:
        rows=[r for r in result['rows'] if r['mode']==mode]
        ranked=sorted(rows,key=lambda r:(-r['win_rate'],-r['avg_damage_share'],r['aid']))
        assert [r['rank'] for r in ranked]==list(range(1,len(rows)+1))
        assert sum(r['wins'] for r in rows)==sum(r['losses'] for r in rows)
    (output/'verification.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2),encoding='utf8')
    print(json.dumps(audit,ensure_ascii=False))


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('output',type=Path);verify(p.parse_args().output)
