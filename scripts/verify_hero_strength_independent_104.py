"""Recompute only designated focal outcomes; ignore all incidental appearances."""
import argparse
import collections
import gzip
import hashlib
import json
import math
from pathlib import Path
from run_hero_strength_104 import blank


def verify(out):
    result=json.loads((out/'results.json').read_text('utf8'));payload=json.loads((out/'frozen-config.json').read_text('utf8'))
    assert result['sampling_design']==payload['sampling_design']=='independent-focal-hero'
    games=payload['games_per_hero'];expected={(r['mode'],r['aid']):r for r in result['rows']}
    totals={key:blank() for key in expected};seeds=set();actual=0;incidental=0
    files_seen=set()
    for file in sorted((out/'battles').glob('*.jsonl.gz')):
        mode,aid=file.name.removesuffix('.jsonl.gz').split('-',1);key=(mode,aid);assert key in expected and key not in files_seen;files_seen.add(key)
        pool=payload['pools'][mode];hero_index=pool.index(aid);indices=set();team_sets=set();opponent_sets=set();r=totals[key]
        with gzip.open(file,'rt',encoding='utf8') as f:
            for line in f:
                seed,index,focal,seat,roster,winner,rounds,alive,stats,shares=json.loads(line)
                assert focal==aid and roster[seat]==aid and len(roster)==len(set(roster))==len(stats)==10
                assert set(roster)<=set(pool) and 0<=seat<10 and 1<=rounds<=40 and 0<=index<games
                assert index not in indices and seed not in seeds;indices.add(index);seeds.add(seed)
                assert seed==1900000000+{'mixed':0,'ordinary':100000000,'skin':200000000}[mode]+hero_index*10000+index
                assert winner==(0 if all(alive) or not any(alive) else 1 if alive[0] else 2)
                side=1+seat//5;own=roster[(side-1)*5:side*5];enemy=roster[(2-side)*5:(3-side)*5]
                friends=frozenset(own);enemies=frozenset(enemy)
                assert friends not in team_sets and enemies not in opponent_sets;team_sets.add(friends);opponent_sets.add(enemies)
                r['games']+=1;r['seats'][seat]+=1;r['wins' if winner==side else 'draws' if not winner else 'losses']+=1
                for j,k in enumerate(('damage','healing','taken')):
                    assert all(math.isfinite(s[j]) and s[j]>=0 for s in stats)
                    denominator=sum(s[j] for s in stats[(side-1)*5:side*5]);share=stats[seat][j]/denominator if denominator else 0
                    assert math.isclose(shares[j],share,abs_tol=1e-12)
                    r[k]+=stats[seat][j];r[k+'_share']+=share
                r['healing_zero_games']+=int(not sum(s[1] for s in stats[(side-1)*5:side*5]))
                actual+=1;incidental+=9
        assert len(indices)==games
    assert files_seen==set(expected)
    for key,r in totals.items():
        e=expected[key]
        for field,v in r.items():
            if isinstance(v,float):assert math.isclose(v,e[field],rel_tol=1e-9,abs_tol=1e-7),(key,field)
            else:assert v==e[field],(key,field)
        assert r['games']==games and r['seats']==[games//10]*10
        assert math.isclose((r['wins']+.5*r['draws'])/games,e['win_rate'],abs_tol=1e-12)
        for k in ('damage','healing','taken'):assert math.isclose(r[k+'_share']/games,e['avg_'+k+'_share'],abs_tol=1e-10)
    assert sum(x['games'] for x in totals.values())==actual==result['total_battles']==sum(len(v) for v in payload['pools'].values())*games
    for mode in payload['pools']:
        rows=sorted((r for r in result['rows'] if r['mode']==mode),key=lambda r:(-r['win_rate'],-r['avg_damage_share'],r['aid']))
        assert [r['rank'] for r in rows]==list(range(1,len(rows)+1))
    for name,digest in json.loads((out/'manifest.json').read_text('utf8')).items():
        p=out/name if name=='frozen-config.json' else out/'sources'/name
        assert hashlib.sha256(p.read_bytes()).hexdigest()==digest,name
    audit=dict(passed=True,sampling_design='independent-focal-hero',actual_battles=actual,unique_seeds=len(seeds),hero_environment_rows=len(totals),
               counted_focal_appearances=actual,incidental_appearances_excluded=incidental,games_per_hero_per_environment=games,
               exact_focal_games=True,one_counted_hero_per_battle=True,sides_and_slots_exact=True,category_pools_isolated=True,
               unique_teammate_and_opponent_sets_per_focal=True,raw_statistics_and_shares_recomputed=True,rankings_recomputed=True,source_hashes_verified=True)
    (out/'verification.json').write_text(json.dumps(audit,ensure_ascii=False,indent=2),encoding='utf8');print(json.dumps(audit,ensure_ascii=False))


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('output',type=Path);verify(p.parse_args().output)
