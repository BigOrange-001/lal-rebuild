"""Single-target, skill-only kill trials through the complete skill model.

The opponent keeps its real HP and defense but idles (DOTs still tick). Basic
attacks by the tested hero are suppressed; summons retain their own turns.
Cooldowns, delayed strikes, skill passives and on-hit hooks remain active.
"""
import argparse
import concurrent.futures
import copy
import hashlib
import json
from pathlib import Path
import sqlite3
import statistics

from gateway import load_game_config
from gameplay_roster import GameplayRosterEquipment
from battle_engine import base_unit, serialize_player_team
from combat_rules import candidate_config, legacy_config
from hero_strength_native_bridge import NativeSkinBattle

ROOT=Path(__file__).resolve().parents[1]
CFG=None


class SkillDuel(NativeSkinBattle):
    def __init__(self,*args,**kwargs):
        super().__init__(*args,**kwargs);self.casts=0;self.leader_mode=False;self.first_cast_damage=None

    def _apply_native_skill(self,attacker,enemies,slot='skill'):
        result=super()._apply_native_skill(attacker,enemies,slot)
        if attacker is self.a[0] and slot==('leader_skill' if self.leader_mode else 'skill') and result:
            self.casts+=1
        return result

    def _basic_attack(self,attacker,target):
        if attacker is not self.a[0]:return super()._basic_attack(attacker,target)

    def _run_unit_turn_base(self,attacker,sides,side):
        if side==2:
            self._tick_buffs(attacker);self.turn_start(attacker)
            return True
        if self.leader_mode and self.casts:
            self._resolve_pending_strike(attacker);self._tick_buffs(attacker);self.turn_start(attacker)
            return True
        return super()._run_unit_turn_base(attacker,sides,side)


def initialize(path):
    global CFG
    CFG=json.loads(Path(path).read_text('utf8'))


def run_job(job):
    stage,label,source,target,seed,trials=job;values=[];censored=0;leader=[];rounds=[]
    for i in range(trials):
        normal=copy.deepcopy(source);normal['leader']=0;normal['leader_skill']=None
        b=SkillDuel([normal],[target],seed=seed+i,max_rounds=180,config=CFG);b.run()
        if b.b[0]['hp']<=0:values.append(b.casts);rounds.append(b.round_index)
        else:censored+=1
        if source.get('leader_skill'):
            u=copy.deepcopy(source);u['skill']=None;u['book_skill']=None
            b=SkillDuel([u],[target],seed=seed+i,max_rounds=10,config=CFG);b.leader_mode=True;b.run()
            if b.casts:leader.append(1-b.b[0]['hp']/target['hp_max'])
    return dict(stage=stage,target=label,aid=source['aid'],name=CFG['avatar'][source['aid']]['name'],
                trials=trials,kills=len(values),censored=censored,
                mean_casts=statistics.mean(values) if values else None,
                sem_casts=statistics.stdev(values)/len(values)**.5 if len(values)>1 else None,
                mean_rounds=statistics.mean(rounds) if rounds else None,
                leader_mean_fraction=statistics.mean(leader) if leader else None,
                leader_max_fraction=max(leader) if leader else None)


def naked_sources(cfg,star,level,slv):
    return [base_unit(cfg,aid,level,slv,0,.5,True,1)
            for aid,row in sorted(cfg['avatar'].items())
            if aid.startswith('A_1') and len(aid.split('_')[1])==4 and aid.endswith('_'+str(star))
            and row.get('stat_profile')==1 and row.get('name') and '序号' not in row['name']]


def naked_target(cfg,star,level,profile):
    units=[base_unit(cfg,aid,level,1,0,.5,False,2) for aid,row in cfg['avatar'].items()
           if aid.startswith('A_1') and len(aid.split('_')[1])==4 and aid.endswith('_'+str(star)) and row.get('stat_profile')==profile]
    result=copy.deepcopy(units[0])
    for key in ('hp','hp_max','ap','de_ph','de_ma'):result[key]=int(statistics.median(u[key] for u in units))
    return dummy(result)


def dummy(u):
    u=copy.deepcopy(u);u.update(isme=False,leader=0,pos=1500,line=0,skill=None,leader_skill=None,skillB=None,
                             book_skill=None,skill_diff=0,talent=None)
    return u


def maxhero(cfg,path):
    uri=path.resolve().as_uri()+'?mode=ro'
    with sqlite3.connect(uri,uri=True) as connection:
        row=connection.execute('SELECT profile FROM players WHERE account=?',('maxhero',)).fetchone()
    if not row:raise ValueError('maxhero profile not found')
    profile=json.loads(row[0]);roster=GameplayRosterEquipment(None,{'cfg':cfg})
    formation=[[iid,0,.5] for iid in profile['team'][0] if iid]
    units=serialize_player_team(cfg,profile,0,formation,roster.battle_attributes)
    # Each hero is tested independently with its own configured leader skill.
    for u in units:
        base=base_unit(cfg,u['aid'],99,u['slv'],0,.5,True,1)
        u['leader_skill']=base['leader_skill'];u['leader']=1
    return units


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--trials',type=int,default=50);p.add_argument('--workers',type=int,default=6)
    p.add_argument('--graduation-only',action='store_true')
    p.add_argument('--global-rate',type=float,default=.66)
    p.add_argument('--model',choices=('legacy','ratio','both'),default='both')
    p.add_argument('--output',type=Path,default=ROOT/'build/combat-duels-20261110')
    p.add_argument('--database',type=Path,default=ROOT.parent/'runtime/local.sqlite3')
    a=p.parse_args();out=a.output.resolve();out.mkdir(parents=True,exist_ok=True)
    cfg=load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']
    # Remove sign advantage from both sides to measure the formula itself.
    for row in cfg['avatar'].values():
        if row.get('tl'):row['tl'][0]=0
    jobs=[]
    if not a.graduation_only:
        for n,(star,level,slv) in enumerate(((5,1,1),(5,60,5),(6,99,10))):
            for k,source in enumerate(naked_sources(cfg,star,level,slv)):
                for profile,label in ((1,'output'),(2,'tank')):
                    jobs.append((f'{star}star-lv{level}-slv{slv}',label,source,naked_target(cfg,star,level,profile),1700000+n*100000+k*1000+profile*100,a.trials))
    team=maxhero(cfg,a.database)
    # Equipment/cultivation can invert a hero's original panel role. Use the
    # actual saved panels for graduation matchups, and record the thresholds.
    sources=[u for u in team if u['ap']>=.75*max(v['ap'] for v in team)]
    for k,source in enumerate(sources):
        for j,target in enumerate(team):
            profile=1 if target in sources else 2 if min(target['de_ph'],target['de_ma'])>=.9*max(min(v['de_ph'],v['de_ma']) for v in team) else 0
            if profile in (1,2):jobs.append(('maxhero',f"{'output' if profile==1 else 'tank'}:{target['aid']}",source,dummy(target),2400000+k*10000+j*100,a.trials))
    (out/'snapshots.json').write_text(json.dumps(dict(maxhero=team,jobs=jobs),ensure_ascii=False),encoding='utf8')
    for model in (('legacy','ratio') if a.model=='both' else (a.model,)):
        c=legacy_config(cfg) if model=='legacy' else candidate_config(cfg,attack_overrides={'21':a.global_rate})
        path=out/(model+'-config.json');path.write_text(json.dumps(c,ensure_ascii=False,default=str),encoding='utf8')
        rows=[]
        with concurrent.futures.ProcessPoolExecutor(max_workers=a.workers,initializer=initialize,initargs=(str(path),)) as executor:
            for count,future in enumerate(concurrent.futures.as_completed([executor.submit(run_job,j) for j in jobs]),1):
                rows.append(future.result())
                if count%20==0 or count==len(jobs):print(model,count,len(jobs),flush=True)
        rows.sort(key=lambda r:(r['stage'],r['aid'],r['target']))
        (out/(model+'-results.json')).write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf8')
        print(model,'done',len(rows),flush=True)
    hashes={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [ROOT/'server/combat_math.py',ROOT/'server/battle_engine.py',ROOT/'server/manual_ability_sim.py',Path(__file__)]}
    (out/'source-hashes.json').write_text(json.dumps(hashes,indent=2),encoding='utf8')


if __name__=='__main__':main()
