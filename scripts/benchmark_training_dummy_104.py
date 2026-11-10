"""100-round single-hero dummy benchmark with real max-progression snapshots.

No runtime config or saved profile is changed. The dummy has a finite reference
HP maximum for percent-health skills and an unlimited, refilled damage pool.
"""
import argparse
import collections
import concurrent.futures
from contextlib import contextmanager
import copy
import csv
import gzip
import hashlib
import json
from pathlib import Path
import statistics
import time

from gateway import load_game_config
from gameplay_roster import GameplayRosterEquipment
from battle_engine import serialize_player_team
from cultivation_rules import allocate_budget, cap as culture_cap, WEIGHTS, used as culture_used
from combat_rules import candidate_config
from hero_strength_native_bridge import NativeSkinBattle
from hero_strength_freeze_104 import freeze_study

ROOT=Path(__file__).resolve().parents[1]
DUMMY='A_19999999_6'
OFFENSE=['E_1011_6','E_1019_6',None,None,'E_5009_6','E_6001_7']
DEFENSE=['E_1504_6','E_1505_6','E_3004_6','E_4016_6','E_5010_6','E_6002_7']
PAYLOAD=None


class TrainingBattle(NativeSkinBattle):
    def __init__(self,*args,**kwargs):
        self.channels=[];self.damage_channels=collections.Counter();self.round_damage=collections.Counter()
        self.cast_counts=collections.Counter();self.summon_damage=0;self.dummy_deaths=0
        super().__init__(*args,**kwargs)

    @staticmethod
    def is_dummy(unit):return unit is not None and unit.get('aid')==DUMMY

    @contextmanager
    def channel(self,name):
        self.channels.append(name)
        try:yield
        finally:self.channels.pop()

    def _injured(self,target,amount,damage_type=0,source=None,dot_kind=None,receipt=None):
        if not self.is_dummy(target) or damage_type in (0,4,5) or amount<=0:
            return super()._injured(target,amount,damage_type,source,dot_kind,receipt)
        # Reserve HP only while the native settlement runs. Its finite hp_max
        # is never changed. This prevents overkill clipping and false deaths;
        # event callbacks see full reference HP, as does the next skill action.
        previous=target['hp']
        target['hp']=max(previous,target['hp_max'])+abs(int(amount))*100+1
        try:
            if dot_kind:
                with self.channel('dot'):return super()._injured(target,amount,damage_type,source,dot_kind,receipt)
            return super()._injured(target,amount,damage_type,source,dot_kind,receipt)
        finally:target['hp']=previous

    def _emit_mod_event(self,owner,event,source=None,target=None,amount=0,overheal=0):
        dummy=next((u for u in (target,owner,source) if self.is_dummy(u)),None)
        if dummy is None:return super()._emit_mod_event(owner,event,source,target,amount,overheal)
        previous=dummy['hp'];dummy['hp']=dummy['hp_max']
        try:return super()._emit_mod_event(owner,event,source,target,amount,overheal)
        finally:dummy['hp']=previous

    def _study_statistics_event(self,source,target,damage,healing):
        super()._study_statistics_event(source,target,damage,healing)
        if self.is_dummy(target) and source is not None and self._team_number(source)==1:
            name=self.channels[-1] if self.channels else 'passive'
            ctx=self._context(source)
            if ctx and ctx.get('kind') in ('passive','response') and name!='dot':name='passive'
            self.damage_channels[name]+=damage
            self.round_damage[self.round_index+1]+=damage
            if source.get('summon_owner') or source.get('summon_owner_token'):self.summon_damage+=damage

    def _apply_native_skill(self,attacker,enemies,slot='skill'):
        name={'skill':'normal','leader_skill':'leader','book_skill':'book','skillB':'passive'}.get(slot,'passive')
        with self.channel(name):result=super()._apply_native_skill(attacker,enemies,slot)
        if result and attacker is self.a[0]:self.cast_counts[name]+=1
        return result

    def _basic_attack(self,attacker,target):
        if attacker is self.a[0]:self.cast_counts['basic']+=1
        with self.channel('basic'):return super()._basic_attack(attacker,target)

    def _check_move(self,unit,forward,distance=0,forced=False):
        if self.is_dummy(unit):return False
        return super()._check_move(unit,forward,distance,forced)

    def _reline(self,unit,line,pos=None,offset=None,forced=False):
        if self.is_dummy(unit):return False
        return super()._reline(unit,line,pos,offset,forced)

    def _run_unit_turn_base(self,attacker,sides,side):
        if self.is_dummy(attacker):
            # Even a stunned dummy must advance DOTs and mark durations.
            self._tick_buffs(attacker);self.turn_start(attacker)
            return True
        return super()._run_unit_turn_base(attacker,sides,side)


def highest_talent(cfg,effect):
    return max((k for k,r in cfg['talent'].items() if r.get('growth_effect')==effect),key=lambda k:cfg['talent'][k]['growth_value'])


def max_item(cfg,eid,level=170,defensive=False):
    definition=cfg['equip'][eid]
    if definition['type']==6:
        return dict(eid=eid,lv=1,slv=10,new_4attrs={},halo={'lv':0,'exp':0},alchemy=[0,0],
                    magic=[0,0,0,0],rune_lv=0,stat_roll_ppm=1000000,wash_schema_version=1)
    star=7;raw_cap=cfg['system_simple']['equip_config'][3]*star*level
    pair=definition['pl'][6:8];wash={pair[0]:raw_cap//2,pair[1]:raw_cap-raw_cap//2}
    exclusive=eid in cfg['system_simple']['equipment_roll_policy']['exclusive_ids']
    base_star=int(eid.rsplit('_',1)[1])
    # Both defensive rune colors give the same stat value. Alternate by item
    # below for equal extra physical/magic resistance where possible.
    return dict(eid=eid,lv=level,slv=0,new_4attrs=wash,halo={'lv':5,'exp':0},haloLv=5,
                alchemy=[0,star-base_star],magic=[100]*4,magic_stage5=1,rune_lv=10,
                symp=2 if defensive else 1,stat_roll_ppm=1200000 if exclusive else 1150000,
                equipment_v2_version=1,wash_schema_version=1)


def max_snapshot(cfg,aid,equipped=False,defensive=False,level=170):
    iid=aid+'|bench';hero=dict(aid=aid,lv=125,slv=10,phase=3,limit_break=1,morph=0,
                               culture_schema='weighted-v2',talent=highest_talent(cfg,'defense' if defensive else 'attack'))
    budget=culture_cap(hero,cfg['system_simple'])
    hero.update(allocate_budget(dict.fromkeys(WEIGHTS,1),budget,WEIGHTS))
    assert culture_used(hero,cfg['system_simple'])==budget
    gear=DEFENSE if defensive else OFFENSE if equipped else [None]*6
    items={};group=[]
    for i,eid in enumerate(gear):
        if eid is None:group.append(None);continue
        key=f'eq{i}';item=max_item(cfg,eid,level,defensive)
        if defensive and cfg['equip'][eid]['type']!=6:item['symp']=2+i%2
        items[key]=item;group.append(key)
        assert (i in (0,1) if cfg['equip'][eid]['type']==1 else i==cfg['equip'][eid]['type']-1)
    profile=dict(avatars={iid:hero},team=[[iid,None,None,None,None,None]],as_equips=[group],
                 my_equips=items,attrs={'team_num':0,'dn':{},'guild_graduate_skill':{}},lv=125,vip_lv=15)
    roster=GameplayRosterEquipment(None,{'cfg':cfg})
    source=serialize_player_team(cfg,profile,0,[[iid,0,.5]],roster.battle_attributes)[0]
    return source,profile


def catalogue(cfg):
    excluded=set(json.loads((ROOT/'config/reconstruction/hero-strength-study-policy.json').read_text('utf8'))['excluded_families'])
    families=sorted({aid.split('_')[1] for aid,row in cfg['avatar'].items()
                     if aid.startswith('A_1') and len(aid.split('_')[1])==4 and aid.endswith(('_5','_6'))
                     and row.get('name') and '序号' not in row['name'] and aid.rsplit('_',1)[0] not in excluded})
    return [next(a for a in (f'A_{f}_6',f'A_{f}_5') if a in cfg['avatar']) for f in families]


def build_payload(equipment_level=170):
    cfg=load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']
    for row in cfg['avatar'].values():
        if row.get('tl'):row['tl'][0]=0
    aids=catalogue(cfg);sources={};profiles={}
    for aid in aids:
        for loadout in ('naked','offense'):
            sources[aid,loadout],profiles[aid,loadout]=max_snapshot(cfg,aid,loadout=='offense',level=equipment_level)
    armored,target_profile=max_snapshot(cfg,'A_1001_6',True,True,equipment_level)
    armored.update(aid=DUMMY,isme=False,leader=0,line=0,pos=1500,skill=None,skillB=None,
                   leader_skill=None,book_skill=None,skill_diff=0,tpl=[0,1,0,0,0],bonds_104=[],equipment_bonds_104=[])
    armored.pop('instance_id',None)
    zero=copy.deepcopy(armored)
    zero.update(ap=0,de_ph=0,de_ma=0,talent=None,new_4attrs=dict.fromkeys(('hit','flee','crit','tough'),0))
    cfg['avatar'][DUMMY]=dict(id=DUMMY,name='训练桩',tl=[0,1,0,1,125],pl=[0]*14)
    return dict(cfg=cfg,aids=aids,sources={a+'|'+l:u for (a,l),u in sources.items()},
                profiles={a+'|'+l:p for (a,l),p in profiles.items()},targets={'zero':zero,'armored':armored},
                target_profile=target_profile,equipment_level=equipment_level)


def initialize(path):
    global PAYLOAD
    PAYLOAD=json.loads(Path(path).read_text('utf8'))


def run_job(job):
    aid,loadout,target,trials,output=job
    file=Path(output)/'battles'/f'{aid}-{loadout}-{target}.jsonl.gz'
    values=[];channels=collections.Counter();casts=collections.Counter();summon=0;ended=0
    source=PAYLOAD['sources'][aid+'|'+loadout];dummy=PAYLOAD['targets'][target]
    partial=file.with_suffix('.partial')
    with gzip.open(partial,'wt',encoding='utf8',compresslevel=1) as stream:
        for i in range(trials):
            # Identical hero seed across both models, both loadouts and dummies.
            seed=110100000+PAYLOAD['aids'].index(aid)*1000+i
            battle=TrainingBattle([source],[dummy],config=PAYLOAD['cfg'],seed=seed,max_rounds=100)
            result=battle.run();total=sum(v['damage'] for (side,_),v in battle.statistics.items() if side==1)
            assert total==sum(battle.damage_channels.values())
            assert battle.b[0]['hp']==dummy['hp_max'] and battle.b[0]['hp_max']==dummy['hp_max']
            if result['rounds']<100:ended+=1
            values.append(total);channels.update(battle.damage_channels);casts.update(battle.cast_counts);summon+=battle.summon_damage
            stream.write(json.dumps(dict(seed=seed,damage=total,rounds=result['rounds'],alive=battle.a[0]['hp']>0,
                channels=dict(battle.damage_channels),casts=dict(battle.cast_counts),summon=battle.summon_damage,
                by_round=dict(battle.round_damage)),separators=(',',':'))+'\n')
    partial.replace(file)
    return dict(aid=aid,name=PAYLOAD['cfg']['avatar'][aid]['name'],loadout=loadout,target=target,trials=trials,
                mean=statistics.mean(values),stdev=statistics.stdev(values) if trials>1 else 0,
                minimum=min(values),maximum=max(values),median=statistics.median(values),ended_early=ended,
                channels={k:v/trials for k,v in channels.items()},casts={k:v/trials for k,v in casts.items()},summon_mean=summon/trials)


def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--trials',type=int,default=30);p.add_argument('--workers',type=int,default=8)
    p.add_argument('--model',choices=('legacy','ratio','both'),default='both')
    p.add_argument('--equipment-level',type=int,default=170)
    p.add_argument('--heroes',nargs='*');p.add_argument('--output',type=Path,default=ROOT/'build/dummy-benchmark-20261110')
    args=p.parse_args();out=args.output.resolve();out.mkdir(parents=True,exist_ok=True)
    payload=build_payload(args.equipment_level);legacy=payload['cfg'];started=time.monotonic()
    if args.heroes:payload['aids']=[a for a in payload['aids'] if a in args.heroes]
    print(json.dumps(dict(heroes=len(payload['aids']),targets=payload['targets'],equipment_level=args.equipment_level),ensure_ascii=False),flush=True)
    for model in (('legacy','ratio') if args.model=='both' else (args.model,)):
        folder=out/model;(folder/'battles').mkdir(parents=True,exist_ok=True)
        payload['cfg']=legacy if model=='legacy' else candidate_config(legacy)
        config=freeze_study(folder,json.dumps(payload,ensure_ascii=False,separators=(',',':'),default=str).encode('utf8'))
        jobs=[(aid,loadout,target,args.trials,str(folder)) for aid in payload['aids']
              for loadout in ('naked','offense') for target in ('zero','armored')]
        rows=[]
        with concurrent.futures.ProcessPoolExecutor(max_workers=args.workers,initializer=initialize,initargs=(str(config),)) as executor:
            for count,f in enumerate(concurrent.futures.as_completed([executor.submit(run_job,j) for j in jobs]),1):
                try:rows.append(f.result())
                except Exception:print('Failed completed-job index',count,flush=True);raise
                if count%20==0 or count==len(jobs):
                    status=dict(model=model,done=count,total=len(jobs),seconds=round(time.monotonic()-started,1))
                    (out/'progress.json').write_text(json.dumps(status),encoding='utf8');print(json.dumps(status),flush=True)
        rows.sort(key=lambda r:(r['aid'],r['loadout'],r['target']))
        (folder/'results.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf8')
    print(json.dumps(dict(status='complete',seconds=round(time.monotonic()-started,1))),flush=True)


if __name__=='__main__':main()
