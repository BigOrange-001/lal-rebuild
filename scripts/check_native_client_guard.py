"""Focused RPC compatibility guard check, using an isolated temporary save."""
import copy
from pathlib import Path
import sys
import tempfile

ROOT=Path(__file__).resolve().parents[1]
sys.path[:0]=[str(ROOT),str(ROOT/'server')]
from gateway import Backend
from scripts.check_native_api import package
from scripts.mod_tools import load_base
from mod_native import make_template

def main():
    with tempfile.TemporaryDirectory() as folder:
        root=Path(folder);backend=Backend(root/'save.sqlite3',ROOT/'config/reconstruction/full-config.json',root/'mods')
        try:
            credentials={'pf':'local','session_key':'native-guard','sessionid':'local-test','actionID':'register'}
            assert backend.call({'method':'user.register','params':credentials})['return_code']==0
            owner=backend.call({'method':'user.login','params':{**credentials,'actionID':'login'}})['data']
            serial=0
            def rpc(method,params=None,native=False,expected=0):
                nonlocal serial
                serial+=1
                request={'method':method,'uid':owner['uid'],'sessionid':owner['sessionid'],
                         'params':{'actionID':str(serial),**(params or {})},
                         'mod_digest':backend.mods.config(owner['uid'])['digest']}
                if native:request['client_capabilities']=['skill.native-template.v1']
                response=backend.call(request)
                assert response['return_code']==expected,response
                return response['data']
            base=load_base(ROOT/'config/reconstruction/full-config.json')
            native_skill=make_template('S_631132_5',base['cfg']['skill']['S_631132_5'],base)
            path=package(root/'native.heropack',[native_skill])
            installed=backend.mods.install_bytes(path.read_bytes())
            selection={'packageId':installed['packageId'],'version':installed['version'],'contentDigest':installed['digest'],'enabled':True}
            params={'expectedRevision':0,'selections':[selection]}
            old=rpc('user.mods_plan',params)
            assert not old['valid'] and old['errors'][0]['code']=='ModClientIncompatible',old
            new=rpc('user.mods_plan',params,native=True);assert new['valid'],new
            rpc('user.mods_apply',{**params,'planDigest':new['planDigest'],'requestId':'apply-native'},native=True)
            assert rpc('user.init_user',expected=1)['error_code']=='ModClientIncompatible'
            rpc('user.init_user',native=True)
            assert rpc('user.mods_config',expected=1)['error_code']=='ModClientIncompatible'
            rpc('user.mods_info')  # management remains available to a live old session
            disable=rpc('user.mods_plan',{'expectedRevision':1,'selections':[]});assert disable['valid']
            def login_state():
                return (backend.db.execute('SELECT profile FROM players WHERE uid=?',(owner['uid'],)).fetchone(),
                        backend.db.execute('SELECT * FROM sessions ORDER BY token').fetchall(),
                        backend.db.execute('SELECT * FROM operation_ledger ORDER BY uid,operation_key').fetchall(),
                        backend.db.execute('SELECT * FROM gift_mail ORDER BY id').fetchall(),
                        backend.players.state_revision(owner['uid']))
            before=login_state()
            for attempt in range(3):
                old_login=backend.call({'method':'user.login','params':{**credentials,'actionID':'old-login-'+str(attempt)}})
                assert old_login['return_code']==1 and old_login['data']['error_code']=='ModClientIncompatible',old_login
                assert login_state()==before,'Rejected login changed profile, session, rewards or revision'
            new_login=backend.call({'method':'user.login','params':{**credentials,'actionID':'new-login'},'client_capabilities':['skill.native-template.v1']})
            assert new_login['return_code']==0,new_login
            backup=rpc('user.mods_backup')
            disabled={'expectedRevision':1,'selections':[]}
            disable=rpc('user.mods_plan',disabled)
            rpc('user.mods_apply',{**disabled,'planDigest':disable['planDigest'],'requestId':'disable-for-restore'})
            restored={'backup':backup}
            before=login_state()
            assert rpc('user.mods_restore_plan',restored,expected=1)['error_code']=='ModClientIncompatible'
            allowed=rpc('user.mods_restore_plan',restored,native=True)
            assert allowed['valid']
            restore={**restored,'planDigest':allowed['planDigest'],'requestId':'restore-native'}
            assert rpc('user.mods_restore',restore,expected=1)['error_code']=='ModClientIncompatible'
            assert login_state()==before,'Rejected restore changed persisted player state'
            rpc('user.mods_restore',restore,native=True)
            assert rpc('user.init_user',expected=1)['error_code']=='ModClientIncompatible'
            print('PASS: capability checks guard activation, restore and login before state changes; native paths succeed')
        finally:
            backend.clock.close();backend.db.close()

if __name__=='__main__':main()
