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
            old_login=backend.call({'method':'user.login','params':{**credentials,'actionID':'old-login'}})
            assert old_login['return_code']==1 and old_login['data']['error_code']=='ModClientIncompatible',old_login
            new_login=backend.call({'method':'user.login','params':{**credentials,'actionID':'new-login'},'client_capabilities':['skill.native-template.v1']})
            assert new_login['return_code']==0,new_login
            print('PASS: old-client activation/login/gameplay blocked; native client accepted; old-session management/disable preserved')
        finally:
            backend.clock.close();backend.db.close()

if __name__=='__main__':main()
