"""Export the complete live hero rank contract and all ten rank values."""
import argparse
import csv
import hashlib
import json
from pathlib import Path
from unittest.mock import patch

from gateway import load_game_config
from native_skill_snapshot import _native_skill_snapshot
from skill_rank_growth_104 import hero_skill_references
from skill_balance_overlay import _get

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--output',type=Path,default=ROOT/'outputs/skill-growth-20261030')
    args=parser.parse_args()
    cfg=load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']
    with patch('skill_rank_growth_104.apply_skill_rank_growth_104',lambda d:d):
        before=load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']
    refs=hero_skill_references(cfg)
    rows=[]
    failures=[]
    previously_invalid=set()
    for sid,slot in sorted(refs.items()):
        row=cfg['skill'][sid]
        snaps=[_native_skill_snapshot(cfg,sid,lv) for lv in range(1,11)]
        old=[_native_skill_snapshot(before,sid,lv) for lv in range(1,11)]
        records=[]
        for index,path,base,last in row['rankGrowth104']['magnitudes']:
            values=[_get(s['skills'][index],path) for s in snaps]
            try:
                old_values=[_get(s['skills'][index],path) for s in old]
            except IndexError:
                # Previously a literal in native code; now exposed in actions.
                old_values=[values[-1] if slot==10 else values[0]]*10
            records.append((str(index)+':'+'.'.join(map(str,path)),values,old_values))
        for key,growth in row['rankSettingGrowth104'].items():
            paths=[None] if isinstance(growth[0],(int,float)) else [x[0] for x in growth]
            for path in paths:
                values=[s['nativeSettings104'][key] for s in snaps]
                if path:
                    values=[_get(v,path) if isinstance(v,list) else v[path[0]] for v in values]
                # Multiplier channels replace the former compound scale;
                # this column describes the old channel, not total damage.
                previous=before['skill'][sid].get(key,1)
                if path:
                    previous=_get(previous,path) if isinstance(previous,list) else previous[path[0]]
                records.append((key+(':'+str(path) if path else ''),values,[previous]*10))
        for path,values,old_values in records:
            valid=all(abs(v-values[0]*(1+i/9))<=max(1e-8,abs(v)*1e-12) for i,v in enumerate(values))
            if not valid:failures.append([sid,path])
            if any(abs(v-old_values[0]*(1+i/9))>max(1e-8,abs(v)*1e-12) for i,v in enumerate(old_values)):
                previously_invalid.add(sid)
            rows.append([sid,row.get('name',''),{10:'普通技能',11:'队长技',13:'被动'}[slot],path,*values,valid])
    args.output.mkdir(parents=True,exist_ok=True)
    with (args.output/'逐技能等级数值.csv').open('w',encoding='utf-8-sig',newline='') as stream:
        writer=csv.writer(stream)
        writer.writerow(['技能ID','名称','技能栏','数值路径',*[f'{lv}级' for lv in range(1,11)],'线性且10级等于1级两倍'])
        writer.writerows(rows)
    summary=dict(hero_families=len({a.rsplit('_',1)[0] for a in cfg['avatar'] if a.startswith('A_1')}),
                 hero_quality_rows=cfg['skill_rank_growth_104']['hero_rows'],skills=len(refs),
                 normal_skills=sum(s==10 for s in refs.values()),captain_skills=sum(s==11 for s in refs.values()),passive_skills=sum(s==13 for s in refs.values()),
                 magnitude_curves=len(rows),rank_values_checked=len(rows)*10,client_rank_cases=len(refs)*10,
                 previously_invalid_skill_curves=len(previously_invalid),failures=failures,
                 normal_anchor=10,captain_passive_anchor=1,
                 no_strength_matches_run=True,apk_updated=False,live_service_restarted=False,
                 skill_sha256=hashlib.sha256(json.dumps({s:cfg['skill'][s] for s in sorted(refs)},sort_keys=True,ensure_ascii=False).encode()).hexdigest())
    (args.output/'audit.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n','utf8')
    print(json.dumps(summary,ensure_ascii=False))
    if failures:raise SystemExit(1)


if __name__=='__main__':main()
