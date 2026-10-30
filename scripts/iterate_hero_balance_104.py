"""Audited half-draw hero balance iterations, retaining every measured round."""
import argparse
import copy
import json
import math
from pathlib import Path
import shutil
import subprocess
import sys
from run_hero_strength_104 import aggregate
from hero_balance_iteration_104 import SCHEMA,PLAN,MECHANISMS,mechanism_text

ROOT=Path(__file__).resolve().parents[1]
OUTPUT=ROOT/'outputs/hero-balance-iteration-20261030'
BASE=ROOT/'outputs/hero-strength-20261030-1000'


def evaluate(report):
    summary={}
    for mode,lo,hi in [('ordinary',.45,.55),('skin',.4,.6)]:
        rows=[r for r in report['rows'] if r['mode']==mode]
        outside=[dict(aid=r['aid'],name=r['name'],rate=r['win_rate']) for r in rows if not lo<=r['win_rate']<=hi]
        summary[mode]=dict(total=len(rows),in_target=len(rows)-len(outside),minimum=min(r['win_rate'] for r in rows),maximum=max(r['win_rate'] for r in rows),outside=outside)
    avg={cat:sum(r['win_rate'] for r in report['rows'] if r['mode']=='mixed' and r['category']==cat)/sum(r['mode']=='mixed' and r['category']==cat for r in report['rows']) for cat in ('ordinary','skin')}
    gap=avg['skin']-avg['ordinary'];summary.update(mixed_means=avg,mixed_gap=gap,mixed_target=.1<=gap<=.15)
    summary['achieved']=not summary['ordinary']['outside'] and not summary['skin']['outside'] and summary['mixed_target']
    summary['distance']=sum(max(0,.45-r['win_rate'],r['win_rate']-.55) for r in report['rows'] if r['mode']=='ordinary')+sum(max(0,.4-r['win_rate'],r['win_rate']-.6) for r in report['rows'] if r['mode']=='skin')+2*max(0,.1-gap,gap-.15)
    return summary


def baseline():
    dest=OUTPUT/'baseline-half-draw'
    if not dest.exists():
        dest.mkdir(parents=True)
        for name in ('battles','sources'):shutil.copytree(BASE/name,dest/name)
        for name in ('frozen-config.json','manifest.json'):shutil.copy2(BASE/name,dest/name)
    original=json.loads((BASE/'results.json').read_text('utf8'))
    result=aggregate(dest,original['heroes'],100)
    subprocess.run([sys.executable,str(ROOT/'scripts/verify_hero_strength_104.py'),str(dest)],check=True)
    (dest/'evaluation.json').write_text(json.dumps(evaluate(result),ensure_ascii=False,indent=2),encoding='utf8')
    return result


def initial_plan(report):
    plan=dict(schema=SCHEMA,enabled=True,round=1,skin_panel_factor=1.,target=dict(ordinary=[.45,.55],skin=[.4,.6],mixed_skin_advantage=[.1,.15]),heroes={})
    for r in report['rows']:
        if r['mode']=='mixed':continue
        family=r['aid'].rsplit('_',1)[0];score=r['win_rate']
        if score<.43:panel,skill,kind=1.04,1.08,'mechanism'
        elif score>.65:panel,skill,kind=.85,(.45 if family=='A_1222' else .6),'major-nerf'
        elif abs(score-.5)<.015:panel,skill,kind=1.,1.,'hold-near-center'
        else:panel,skill,kind=math.exp((.5-score)*.65),max(.82,min(1.22,math.exp((.5-score)*2))),'medium-numeric'
        plan['heroes'][family]=dict(panel_factor=round(panel,8),skill_factor=round(skill,8),mechanism=score<.43,
                                   category=r['category'],name=r['name'],initial_score=score,action=kind,
                                   mechanism_description=MECHANISMS.get(family,'') if score<.43 else '')
    return plan


def next_plan(plan,report,history):
    new=copy.deepcopy(plan);new['round']+=1
    for r in report['rows']:
        if r['mode']=='mixed':continue
        family=r['aid'].rsplit('_',1)[0];entry=new['heroes'][family];score=r['win_rate']
        # Aim at the center, leaving a margin for a fresh-seed confirmation.
        if abs(score-.5)<.012:entry['action']='hold-near-center';continue
        gain=2.4 if r['category']=='ordinary' else 1.9
        step=max(-.22,min(.22,(.5-score)*gain))
        if score>.65:step=min(step,math.log(.7));entry['action']='major-nerf'
        else:entry['action']='medium-numeric'
        if score<.43 and not entry.get('mechanism'):
            entry['mechanism']=True;entry['action']='mechanism'
            base_cfg=json.loads((BASE/'frozen-config.json').read_text('utf8'))['cfg']
            entry['mechanism_description']=mechanism_text(family,base_cfg['avatar'][r['aid']])
        entry['skill_factor']=round(max(.03,min(10,entry['skill_factor']*math.exp(step))),8)
        entry['panel_factor']=round(max(.03,min(10,entry['panel_factor']*math.exp(step*.5))),8)
    gap=evaluate(report)['mixed_gap']
    if not .11<=gap<=.14:
        new['skin_panel_factor']=round(max(.3,min(3,new['skin_panel_factor']*math.exp(max(-.12,min(.12,(.125-gap)*2.8))))),8)
    return new


def write_plan(plan):
    PLAN.write_text(json.dumps(plan,ensure_ascii=False,indent=2)+'\n',encoding='utf8')


def run_round(plan,epoch=0,tag=None):
    name=tag or f'round-{plan["round"]:02d}';dest=OUTPUT/name;dest.mkdir(parents=True,exist_ok=True)
    write_plan(plan);(dest/'balance-plan.json').write_text(PLAN.read_text('utf8'),encoding='utf8')
    cmd=[sys.executable,str(ROOT/'scripts/run_hero_strength_104.py'),'--cycles','100','--workers','16','--block-cycles','5','--seed-epoch',str(epoch),'--output',str(dest)]
    with (dest/'simulation.log').open('w',encoding='utf8') as log:
        subprocess.run(cmd,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,check=True)
    subprocess.run([sys.executable,str(ROOT/'scripts/verify_hero_strength_104.py'),str(dest)],cwd=ROOT,check=True)
    report=json.loads((dest/'results.json').read_text('utf8'));evaluation=evaluate(report)
    (dest/'evaluation.json').write_text(json.dumps(evaluation,ensure_ascii=False,indent=2),encoding='utf8')
    print(json.dumps(dict(round=name,summary=evaluation),ensure_ascii=False),flush=True)
    return report,evaluation


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--rounds',type=int,default=3);parser.add_argument('--resume',action='store_true');args=parser.parse_args()
    OUTPUT.mkdir(parents=True,exist_ok=True)
    if not args.resume:
        if PLAN.exists():raise RuntimeError('An iteration plan exists; use --resume')
        base=baseline();plan=initial_plan(base);history=[dict(round=0,path='baseline-half-draw',evaluation=evaluate(base))]
    else:
        history=json.loads((OUTPUT/'history.json').read_text('utf8'));plan=json.loads(PLAN.read_text('utf8'))
        last=OUTPUT/history[-1]['path'];report=json.loads((last/'results.json').read_text('utf8'))
        plan=next_plan(plan,report,history)
    for _ in range(args.rounds):
        report,summary=run_round(plan)
        history.append(dict(round=plan['round'],path=f'round-{plan["round"]:02d}',evaluation=summary))
        (OUTPUT/'history.json').write_text(json.dumps(history,ensure_ascii=False,indent=2),encoding='utf8')
        if summary['achieved']:break
        if _<args.rounds-1:plan=next_plan(plan,report,history)
    print(json.dumps(dict(status='batch-complete',last_round=plan['round'],achieved=summary['achieved'])),flush=True)


if __name__=='__main__':main()
