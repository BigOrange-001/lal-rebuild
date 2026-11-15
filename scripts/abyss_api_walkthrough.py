"""Export real RPC contract examples using only a synthetic in-memory account.

Signs are controlled workflow inputs, not evidence of combat balance/parity.
Never opens the runtime directory or an existing account database.
"""
import argparse
import json
import sqlite3
from pathlib import Path

from gateway import load_game_config
from player_store import PlayerStore

ROOT = Path(__file__).resolve().parents[1]


def walkthrough(destination):
    destination = Path(destination)
    destination.mkdir(parents=True,exist_ok=True)
    config = load_game_config(ROOT/'config/reconstruction/full-config.json')
    db = sqlite3.connect(':memory:')
    store = PlayerStore(db,config)
    login = store.login('abyss-api-fixture')
    samples, trace = {}, []
    sequence = 0
    def call(name, **fields):
        nonlocal sequence
        sequence += 1
        request = {'method':'user.abyss_'+name,'params':{'actionID':f'fixture-{sequence}',**fields}}
        response = store.dispatch({**login,**request})
        samples.setdefault(name, {'request':request, 'response':response})
        run = response.get('abyss_run') or {}
        trace.append({'method':request['method'],'status':run.get('status'),
                      'node':run.get('current_node'),'retries':run.get('retries'),
                      'pool_size':len(run.get('pool',{}))})
        return response
    try:
        call('query')
        run = call('start',difficulty=1,deck='blade',seed=20261116)['abyss_run']
        lost = skipped = False
        while run['status']=='active':
            if run['pending_choice']:
                choice = run['pending_choice']
                if choice['can_skip'] and not skipped:
                    run = call('skip')['abyss_run']; skipped = True
                else:
                    run = call('choose',heroes=[h['id'] for h in choice['options'][:choice['count']]])['abyss_run']
                continue
            run = call('route',node_id=run['available_nodes'][0])['abyss_run']
            node = next(n for n in run['map'] if n['id']==run['current_node'])
            if node['type']=='rest':
                hero = next(h for h in run['pool'].values() if h['slv']==5)
                run = call('rest',hero_id=hero['id'],option='skill')['abyss_run']
                continue
            while not node['completed']:
                battle = call('combat',team=[[h,i%3,.2] for i,h in enumerate(list(run['pool'])[:5])])
                sign = 1 if lost else 2
                lost = True
                run = call('finish',fight_id=battle['fight_id'],fight_kind='abyss',
                    metadata=battle['metadata'],sign=sign,teams={})['abyss_run']
                node = next(n for n in run['map'] if n['id']==run['current_node'])
        call('start',difficulty=2,deck='venom',seed=20261117)
        call('abandon')
        for name, data in samples.items():
            (destination/(name+'.json')).write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n','utf-8')
        summary = {'seed':20261116,'controlled_signs':True,'trace':trace,
                   'final_status':run['status'],'rewards':run['rewards']}
        (destination/'walkthrough.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n','utf-8')
        return summary
    finally:
        db.close()


if __name__=='__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output',type=Path,default=ROOT/'docs/roguelite-abyss-api-samples')
    args = parser.parse_args()
    summary = walkthrough(args.output)
    print(json.dumps({'status':summary['final_status'],'calls':len(summary['trace']),
                      'rewards':len(summary['rewards'])},ensure_ascii=False))
