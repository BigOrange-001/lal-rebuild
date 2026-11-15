"""Synthetic-account balance study with decisive victories and censored draws.

No player database is opened. This is an offline model, never native acceptance.
"""
import argparse
import json
import sqlite3
import statistics
from pathlib import Path

from gateway import load_game_config
from manual_ability_sim import SkillCompleteBattle
from player_store import PlayerStore

ROOT=Path(__file__).resolve().parents[1]
TANKS = ['A_1001','A_1020','A_1018','A_1077','A_1085','A_1049','A_1007','A_1013']
SUPPORTS = ['A_1004','A_1006','A_1094','A_1045']
DAMAGE = ['A_1014','A_1040','A_1016','A_1003','A_1063','A_1082','A_1012','A_1009',
          'A_1010','A_1008','A_1002','A_1005','A_1011']


def rank(hero, category):
    ids={'tank':TANKS,'support':SUPPORTS,'damage':DAMAGE}[category]
    return (hero['quality'], len(ids)-ids.index(hero['id']) if hero['id'] in ids else -1,hero['slv'])


def lineup(run, attempt):
    heroes=list(run['pool'].values())
    chosen=[]
    for category,count,ids in (('tank',2,TANKS),('support',1,SUPPORTS),('damage',2,DAMAGE)):
        available=sorted([h for h in heroes if h['id'] in ids],key=lambda h:rank(h,category),reverse=True)
        chosen.extend(available[:count])
    for hero in sorted(heroes,key=lambda h:(h['quality'],h['slv']),reverse=True):
        if len(chosen)>=5:break
        if hero not in chosen:chosen.append(hero)
    lanes=[0,1,0,2,1]
    entries=[[h['id'],(lanes[i]+attempt)%3,.4 if i in (0,1,3) else .1] for i,h in enumerate(chosen)]
    captain=max(chosen,key=lambda h:(h['quality'],len(DAMAGE)-DAMAGE.index(h['id']) if h['id'] in DAMAGE else 0))
    entries.sort(key=lambda e:e[0]!=captain['id'])
    return entries


def choose(run):
    choice=run['pending_choice']
    def score(h):
        category='support' if h['id'] in SUPPORTS else 'tank' if h['id'] in TANKS else 'damage'
        return rank(h,category)
    return [h['id'] for h in sorted(choice['options'],key=score,reverse=True)[:choice['count']]]


def run_one(document, difficulty, deck, seed, max_rounds=120):
    db=sqlite3.connect(':memory:')
    store=PlayerStore(db,document)
    login=store.login('abyss-calibration')
    uid=login['uid']
    required=document['cfg']['system_simple']['roguelite_abyss']['decks'][deck]['clear_required']
    if difficulty>1 or required:
        def unlock(p):p['abyss_account']['cleared']=list(range(1,max(difficulty-1,required)+1));return p,{}
        store.atomic_update(uid,unlock)
    sequence=0
    def call(name,**fields):
        nonlocal sequence
        sequence+=1
        return store.dispatch({**login,'method':'user.abyss_'+name,'params':{'actionID':str(sequence),**fields}})
    rows=[]
    try:
        run=call('start',difficulty=difficulty,deck=deck,seed=seed)['abyss_run']
        while run['status']=='active':
            if run['pending_choice']:
                run=call('choose',heroes=choose(run))['abyss_run'];continue
            if run['available_nodes']:
                run=call('route',node_id=run['available_nodes'][0])['abyss_run']
            node=next(n for n in run['map'] if n['id']==run['current_node'])
            if node['type']=='rest':
                active=lineup(run,0)
                current=[run['pool'][row[0]] for row in active]
                purple=[h for h in current if h['can_orange']]
                if purple:
                    selected=max(purple,key=lambda h:(h['id'] in DAMAGE,h['slv']))
                    option='orange'
                else:
                    selected=next(h for h in current if h['slv']==5)
                    option='skill'
                run=call('rest',hero_id=selected['id'],option=option)['abyss_run'];continue
            attempt=sum(r['node_id']==node['id'] for r in rows)
            battle=call('combat',team=lineup(run,attempt))
            report=SkillCompleteBattle(battle['orgin_team_a'],battle['orgin_team_b'],
                seed=battle['seed'],max_rounds=max_rounds,config=document['cfg']).run()
            enemy_alive=sum(u['hp']>0 for u in report['team_b'])
            own_alive=sum(u['hp']>0 for u in report['team_a'])
            # Never accept ReferenceBattle's HP-score tie breaker as a kill.
            win=enemy_alive==0 and own_alive>0
            rows.append({'node_id':node['id'],'type':node['type'],'act':node['act'],
                         'attempt':attempt+1,'win':win,'rounds':report['rounds'],
                         'censored':bool(own_alive and enemy_alive),
                         'own_alive':own_alive,'enemy_alive':enemy_alive,
                         'formation':lineup(run,attempt),'combat_seed':battle['seed']})
            run=call('finish',fight_id=battle['fight_id'],metadata=battle['metadata'],
                fight_kind='abyss',sign=1 if win else 2)['abyss_run']
        return {'difficulty':difficulty,'deck':deck,'seed':seed,'status':run['status'],
                'retries_used':document['cfg']['system_simple']['roguelite_abyss']['difficulties'][difficulty-1]['retries']-run['retries'],
                'rows':rows}
    finally:db.close()


def study(document, seeds, scale=1, max_rounds=120, top_multiplier=None, decks=('blade','flame')):
    cfg=document['cfg'];simple=cfg['system_simple'];plan=simple['roguelite_abyss']
    rates={**plan['enemy_rates'],'normal':[r*scale for r in plan['enemy_rates']['normal']]}
    # Weak battles keep the authored rate: no recruitment-stage shortcut.
    difficulties=plan['difficulties']
    if top_multiplier is not None:
        old_bottom=difficulties[0]['multiplier']
        old_top=difficulties[-1]['multiplier']
        difficulties=[{**row,'multiplier':round(old_bottom+(row['multiplier']-old_bottom)*(top_multiplier-old_bottom)/(old_top-old_bottom),4)} for row in difficulties]
    updated={**document,'cfg':{**cfg,'system_simple':{**simple,'roguelite_abyss':{**plan,'enemy_rates':rates,'difficulties':difficulties}}}}
    runs=[]
    for difficulty in (1,10):
        for deck in decks:
            for seed in seeds:
                result=run_one(updated,difficulty,deck,seed,max_rounds)
                runs.append(result)
                print(json.dumps({'scale':scale,**{k:result[k] for k in ('difficulty','deck','seed','status','retries_used')}},ensure_ascii=False),flush=True)
    summary=[]
    for difficulty in (1,10):
        subset=[r for r in runs if r['difficulty']==difficulty]
        rows=[row for r in subset for row in r['rows']]
        summary.append({'difficulty':difficulty,'runs':len(subset),
                        'clears':sum(r['status']=='cleared' for r in subset),
                        'mean_retries':statistics.mean(r['retries_used'] for r in subset),
                        'censored_battles':sum(r['censored'] for r in rows),
                        'battle_count':len(rows)})
        counts={}
        for result in subset:
            for row in result['rows']:
                key=(result['deck'],result['seed'],row['node_id'])
                counts[key]=(row['type'],row['attempt'],row['win'])
        summary[-1]['node_attempts']={kind:{
            'nodes':sum(v[0]==kind for v in counts.values()),
            'max_attempts':max([v[1] for v in counts.values() if v[0]==kind] or [0]),
            'unfinished':sum(v[0]==kind and not v[2] for v in counts.values())}
            for kind in ('weak','normal','elite','boss')}
    return {'schema':1,'model':'SkillCompleteBattle','native_verified':False,
            'weak_uses_difficulty_multiplier':False,
            'max_rounds':max_rounds,'enemy_normal_scale':scale,'enemy_rates':rates,
            'difficulties':difficulties,
            'summary':summary,'runs':runs}


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--scale',type=float,default=1)
    parser.add_argument('--seeds',type=int,nargs='+',default=[20261116,20261117,20261118])
    parser.add_argument('--rounds',type=int,default=120)
    parser.add_argument('--top-multiplier',type=float)
    parser.add_argument('--decks',nargs='+',choices=['blade','flame','venom','summon','star'],default=['blade','flame'])
    parser.add_argument('--original-initials',action='store_true',help='restore old tables only; weak enemies retain the current fixed-scaling rule')
    parser.add_argument('--output',type=Path,default=ROOT/'docs/roguelite-abyss-calibration.json')
    args=parser.parse_args()
    document=load_game_config(ROOT/'config/reconstruction/full-config.json')
    if args.original_initials:
        plan=document['cfg']['system_simple']['roguelite_abyss']
        plan['enemy_rates']['normal']=[.8,1,1.2]
        for row,multiplier in zip(plan['difficulties'],(1,1.08,1.16,1.25,1.35,1.45,1.56,1.68,1.81,1.95)):
            row['multiplier']=multiplier
    result=study(document,args.seeds,args.scale,args.rounds,args.top_multiplier,args.decks)
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n','utf-8')
    print(json.dumps(result['summary'],ensure_ascii=False),flush=True)
