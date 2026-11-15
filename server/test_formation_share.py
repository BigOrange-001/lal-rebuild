"""Production-store tests for private portable arena formations."""
import base64
import copy
import hashlib
import json
import math
import struct
import sqlite3
import tempfile
import unittest
import zlib
from pathlib import Path
from unittest.mock import patch
from pyamf import remoting

from gateway import Backend, load_game_config
from gameplay_common import grant_reward
from player_store import GameplayFault
from formation_share import decode_code, encode_code, same_skill_value, MAX_PAYLOAD

CONFIG=Path(__file__).resolve().parents[1]/'config/reconstruction/full-config.json'


class FormationShareTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.document=load_game_config(CONFIG)

    def setUp(self):
        self.work=tempfile.TemporaryDirectory();self.addCleanup(self.work.cleanup)
        self.path=Path(self.work.name)/'players.sqlite3'
        self.backend=self.open()
        self.uid,self.team=self.player('owner')
        self.other,self.other_team=self.player('friend')
        self.arena=next(h for h in self.backend.players.gameplay_handlers if h.__class__.__name__=='GameplayCompetition')
        self.library=self.arena.formations

    def open(self):
        with patch('gateway.load_game_config',return_value=copy.deepcopy(self.document)):
            backend=Backend(self.path,CONFIG)
        self.addCleanup(backend.clock.close);self.addCleanup(backend.db.close)
        return backend

    def player(self,name):
        credentials=dict(pf='local',session_key=name,sessionid='not-exported')
        self.backend.call(dict(method='user.register',params=dict(credentials,actionID=name+'-register')))
        login=self.backend.call(dict(method='user.login',params=dict(credentials,actionID=name+'-login')))
        self.assertEqual(login['return_code'],0)
        uid=login['data']['uid'];team=[]
        def seed(p):
            p['avatars']={};p['attrs']['avatar_len']=1000
            aids=['A_1802_6','A_1801_6','A_1001_6','A_1002_6','A_1003_6']
            grant_reward(p,dict(heroes=[dict(aid=aid,num=1) for aid in aids]),self.backend.config,allow_skin=True)
            ids=list(p['avatars'])
            for h in p['avatars'].values():h.update(lv=60,slv=10,phase=3,limit_break=0)
            p['team'][0]=ids+[None]
            team.extend([[iid,i%3,.2+(i//3)*.1] for i,iid in enumerate(ids)])
            return p,{}
        self.backend.players.atomic_update(uid,seed)
        return uid,team

    def export(self,action='export',uid=None,team=None):
        return self.library.dispatch(uid or self.uid,'user.export_formation',dict(actionID=action,team_num=0,team=team or self.team))

    def imported(self,code=None,uid=None,action='import'):
        return self.library.dispatch(uid or self.other,'user.import_formation',dict(actionID=action,code=code if code is not None else self.export()['code']))

    def start(self,fid,action='fight'):
        return self.library.dispatch(self.other,'user.pk_combat_formation',dict(actionID=action,formation_id=fid,team_num=0,team=self.other_team))

    def test_export_is_readonly_and_preserves_battle_snapshot_and_positions(self):
        before=self.backend.players.profile_raw(self.uid)
        response=self.export();payload=decode_code(response['code'])
        self.assertEqual(self.backend.players.profile_raw(self.uid),before)
        self.assertEqual(len(payload['members']),5)
        self.assertEqual(payload['members'][0]['pos'],2400)
        self.assertEqual(payload['members'][3]['pos'],2100)
        self.assertTrue(payload['members'][0]['leader'])
        self.assertEqual(payload['members'][0]['skill']['pl'][1],1)
        self.assertEqual(payload['members'][0]['leader_skill']['pl'][1],3)
        self.assertIn('dragon_night_104',payload['members'][0]['bonds_104'])
        self.assertNotIn('instance_id',payload['members'][0])
        self.assertNotIn('not-exported',json.dumps(payload))
        replay=self.export()
        self.assertEqual(response['code'],replay['code'])
        self.assertTrue(replay['replayed'])

    def test_import_persists_across_database_reopen_and_time_and_deduplicates(self):
        item=self.imported()['formation'];fid=item['id']
        again=self.imported(action='import-again')
        self.assertTrue(again['already_saved'])
        self.assertEqual(len(self.library.list(self.other)),1)
        self.backend.db.execute('UPDATE formation_library SET created=1');self.backend.db.commit()
        reopened=self.open()
        lib=next(h.formations for h in reopened.players.gameplay_handlers if h.__class__.__name__=='GameplayCompetition')
        self.assertEqual(lib.list(self.other)[0]['id'],fid)
        self.assertEqual(lib.list(self.other)[0]['created'],1)
        self.assertEqual(lib.list(self.uid),[])

    def test_challenge_mirrors_frozen_enemy_and_has_no_arena_rewards_or_costs(self):
        payload=decode_code(self.export()['code']);fid=self.imported()['formation']['id']
        def change_source(p):
            for h in p['avatars'].values():h['lv']=1
            return p,{}
        self.backend.players.atomic_update(self.uid,change_source)
        before=self.backend.players.profile_raw(self.other)
        battle=self.start(fid)
        expected=copy.deepcopy(payload['members'])
        for unit in expected:unit['isme']=False;unit['pos']=3000-unit['pos']
        self.assertEqual(battle['orgin_team_b'],expected)
        self.assertEqual(battle['fight_kind'],'formation')
        params=dict(actionID='finish',fight_kind='formation',fight_id=battle['fight_id'],metadata=battle['metadata'],sign=1,teams={})
        finished=self.arena.dispatch(self.other,'user.battle_finish',params)
        self.assertEqual(finished['poke_data']['user_gift'],{})
        replay=self.arena.dispatch(self.other,'user.battle_finish',params)
        self.assertTrue(replay['replayed'])
        after=self.backend.players.profile_raw(self.other)
        before.pop('pending_battles',None);after.pop('pending_battles',None)
        self.assertEqual(before,after)

    def test_self_challenge_and_delete_are_private_and_an_inflight_battle_survives_delete(self):
        fid=self.imported(uid=self.uid)['formation']['id']
        self.assertFalse(self.library.dispatch(self.other,'user.delete_formation',dict(actionID='foreign-delete',formation_id=fid))['deleted'])
        self.assertEqual(len(self.library.list(self.uid)),1)
        battle=self.library.start(self.uid,dict(actionID='self-fight',formation_id=fid,team_num=0,team=self.team))
        self.assertTrue(self.library.delete(self.uid,dict(actionID='delete',formation_id=fid))['deleted'])
        self.assertEqual(self.library.list(self.uid),[])
        self.library.finish(self.uid,dict(actionID='self-finish',fight_id=battle['fight_id'],fight_kind='formation',metadata=battle['metadata'],sign=2))
        with self.assertRaises(GameplayFault):
            self.library.start(self.uid,dict(actionID='deleted-start',formation_id=fid,team_num=0,team=self.team))

    def test_changed_rules_mark_saved_entry_incompatible_without_removing_it(self):
        fid=self.imported()['formation']['id']
        self.library.cfg['avatar']['A_1001_6']['pl'][0]+=1
        self.assertFalse(self.library.list(self.other)[0]['compatible'])
        with self.assertRaises(GameplayFault) as caught:self.start(fid)
        self.assertEqual(caught.exception.code,'FormationRulesMismatch')
        self.assertEqual(len(self.library.list(self.other)),1)

    def test_codes_reject_damage_corruption_unknown_heroes_and_skill_mutation(self):
        response=self.export();payload=decode_code(response['code'])
        for code in ('','invalid',response['code'][:-1]+'Z'):
            with self.assertRaises(GameplayFault):self.imported(code=code,action='bad-'+str(len(code)))
        for field,value in (('hp',-1),('pos',float('inf')),('talent',[])):
            edited=copy.deepcopy(payload);edited['members'][0][field]=value
            with self.assertRaises((GameplayFault,ValueError)):
                self.imported(code=encode_code(edited),action='bad-'+field)
        edited=copy.deepcopy(payload);edited['members'][0]['aid']='A_missing_6'
        with self.assertRaises(GameplayFault):self.imported(code=encode_code(edited),action='missing')
        edited=copy.deepcopy(payload);edited['members'][0]['skill']['skills'][0][4]+=1
        with self.assertRaises(GameplayFault):self.imported(code=encode_code(edited),action='skill-edit')

    def test_code_size_bounds_and_chat_wrapping(self):
        raw=b' '* (MAX_PAYLOAD+1);packed=base64.urlsafe_b64encode(zlib.compress(raw)).decode().rstrip('=')
        bomb='LALF1.'+packed+'.'+hashlib.sha256(raw).hexdigest()[:20]
        with self.assertRaises(GameplayFault):decode_code(bomb)
        code=self.export()['code'];wrapped='\n'.join(code[i:i+70] for i in range(0,len(code),70))
        self.assertEqual(decode_code(code),decode_code(wrapped))

    def test_binary_float_snapshot_is_exact_and_cpu_roundoff_does_not_break_compatibility(self):
        values=[2.0678763998000003,-0.0,0.1,1e-20]
        restored=decode_code(encode_code({'values':values}))['values']
        self.assertEqual([struct.pack('>d',v) for v in restored],[struct.pack('>d',v) for v in values])
        self.assertTrue(same_skill_value(values,[math.nextafter(v,math.inf) for v in values]))
        self.assertFalse(same_skill_value([2.0],[2.001]))
        self.library.cfg['avatar']['A_1001_6']['pl'][0]=math.nextafter(float(self.library.cfg['avatar']['A_1001_6']['pl'][0]),math.inf)
        # Integers and floating-point configuration rows retain their types;
        # compare the stable representation between neighboring doubles.
        first=self.library.rules
        self.library.cfg['avatar']['A_1001_6']['pl'][0]=math.nextafter(self.library.cfg['avatar']['A_1001_6']['pl'][0],math.inf)
        self.assertEqual(first,self.library.rules)

    def test_invalid_formation_duplicate_missing_lane_and_unowned_are_rejected(self):
        for team in ([self.team[0]]*5, [self.team[0]], [['unowned',0,.2]]+self.team[1:],
                     [[row[0],float('nan'),row[2]] for row in self.team]):
            with self.assertRaises(GameplayFault):self.export(action='bad-team-'+str(team),team=team)

    def test_native_amf_gateway_export_preview_self_challenge_and_delete(self):
        login=self.backend.call(dict(method='user.login',params=dict(pf='local',session_key='owner',sessionid='not-exported',actionID='native-login')))['data']
        def rpc(method,**params):
            envelope=remoting.Envelope(amfVersion=0)
            envelope['/1']=remoting.Request('http_api',[dict(method=method,uid=login['uid'],sessionid=login['sessionid'],params=dict(actionID='native-'+method,**params))])
            reply=list(remoting.decode(self.backend.process(remoting.encode(envelope,strict=True).getvalue())))[0][1].body
            self.assertEqual(reply['return_code'],0,reply)
            return reply['data']
        exported=rpc('user.export_formation',team=self.team,team_num=0.0)
        fid=rpc('user.import_formation',code=exported['code'])['formation']['id']
        self.assertEqual(rpc('user.list_formations')['formations'][0]['id'],fid)
        preview=rpc('user.get_battle_users',users=[[fid,0],['f000000000000000000000000000000000',0]])
        self.assertEqual(preview[fid]['data'][0][9],600)
        self.assertEqual(preview['f000000000000000000000000000000000']['data'],[])
        battle=rpc('user.pk_combat_formation',formation_id=fid,team=self.team,team_num=0.0)
        self.assertEqual(rpc('user.battle_finish',fight_kind='formation',fight_id=battle['fight_id'],metadata=battle['metadata'],sign=1)['fight_kind'],'formation')
        self.assertTrue(rpc('user.delete_formation',formation_id=fid)['deleted'])
        self.assertEqual(rpc('user.list_formations')['formations'],[])


if __name__=='__main__':unittest.main()
