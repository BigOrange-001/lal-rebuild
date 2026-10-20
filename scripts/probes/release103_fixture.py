"""Serve a disposable 1.0.3 Android QA save; never open a player's database."""
from __future__ import annotations

import argparse
import json
import sys
import threading
import time
import uuid
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
sys.path[:0]=[str(ROOT/'server')]
from gateway import Backend,make_server
from gameplay_common import grant_reward


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--work',type=Path,required=True)
    args=parser.parse_args()
    work=args.work.resolve()
    work.mkdir(parents=True,exist_ok=False)
    backend=Backend(work/'qa.sqlite3',ROOT/'config/reconstruction/full-config.json',work/'mods')
    account='qa103-'+uuid.uuid4().hex
    password=uuid.uuid4().hex
    credentials={'pf':'local','session_key':account,'sessionid':password}
    assert backend.call({'method':'user.register','params':dict(credentials,actionID='register')})['return_code']==0
    owner=backend.call({'method':'user.login','params':dict(credentials,actionID='login')})['data']
    aids=['A_1208_6','A_1217_6','A_1311_6','A_1137_6','A_1202_6']

    def seed(profile):
        grant_reward(profile,{'heroes':[{'aid':aid,'num':1} for aid in aids]},backend.config)
        selected=[]
        for aid in aids:
            iid=next(i for i,h in profile['avatars'].items() if str(h.get('aid',i)).split('|')[0]==aid)
            profile['avatars'][iid].update(lv=99,slv=10,phase=2,hp=0,ap=0,de_ph=0,de_ma=0)
            selected.append(iid)
        profile['team'][0]=selected+[None]
        profile.update(name='1.0.3验收',lv=99,coin=100000000,gold=100000000,score=1000000)
        attrs=profile.setdefault('attrs',{})
        attrs.update(team_num=0,dust=[500000]*4,avatar_len=1000)
        profile['my_equips']['e-qa-weapon']={'eid':'E_1001_3','lv':30,'stat_roll_ppm':1000000,'magic':[0,0,0,0]}
        profile['my_equips']['e-qa-book']={'eid':'E_6001_2','lv':1,'slv':1,'stat_roll_ppm':1000000}
        for i in range(25):
            profile['my_equips']['e-qa-material-'+str(i)]={'eid':'E_6001_2','lv':1,'slv':1,'stat_roll_ppm':1000000}
        for i in range(5):
            profile['my_equips']['e-qa-green-'+str(i)]={'eid':'E_6001_3','lv':1,'slv':1,'stat_roll_ppm':1000000}
        profile['as_equips']=[[] for _ in range(6)]
        return profile,{}

    backend.players.atomic_update(owner['uid'],seed)
    settings={'account':account,'password':password,'mode':'release103','expectedHero':aids[0],
              'magicEquipment':'e-qa-weapon','bookEquipment':'e-qa-book','outputDirectory':str(work)}
    (work/'probe.json').write_text(json.dumps(settings,ensure_ascii=False),'utf-8')
    service=make_server('127.0.0.1',0,backend)
    threading.Thread(target=service.serve_forever,daemon=True).start()
    session={'port':service.server_address[1],'database':str(work/'qa.sqlite3'),
             'probe_settings':str(work/'probe.json'),'stop_file':str(work/'stop')}
    (work/'session.json').write_text(json.dumps(session,indent=2),'utf-8')
    print(json.dumps(session),flush=True)
    try:
        deadline=time.monotonic()+7200
        while time.monotonic()<deadline and not (work/'stop').exists():time.sleep(1)
    finally:
        service.shutdown();service.server_close();backend.db.close();backend.clock.close()


if __name__=='__main__':main()
