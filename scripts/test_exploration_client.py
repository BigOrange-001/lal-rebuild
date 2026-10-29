"""Execute exploration AS request and preview logic with native UI stubs."""
import unittest
from test_adventure_client import function
import test_playtest_client as client_helpers
from test_playtest_client import NODE

BASE=r"""
const int=Math.trunc,noop=()=>{};
let calls=[],callbacks=[],alerts=[],words=[],painted=[];
const GlobalData={$userData:{coin:100,records:{exploration_times:{refresh_count:0,refresh_buy:1}},exploration:{stage:1,current_stage_finish:0}},$mConfig_simple:{explore:{refresh_num:3,refresh_price:10}},isCurrentProfileSyncEnvelope:r=>!r||!r.stale};
const GlobalFunction={isVersionedProfileReceipt:r=>!!r.state_sync,popAlert:(...v)=>alerts.push(v),functionNull:noop,popErrorCoin:v=>words.push('coin'+v),createImage:()=>({width:90,height:100}),};
const LayoutUIAnimation={getOnlyExample:()=>({popWords:v=>words.push(v)})};
const SendAndSelect={sendAndSelectService:(method,params,cb)=>calls.push({method,params,cb})};
const Tools={clone:v=>JSON.parse(JSON.stringify(v))};
function AvatarImg(aid,data,type,isArray,isNpc){Object.assign(this,{aid,data,type,isArray,isNpc,width:100,height:100});}
const DisplayTools={newTextField:()=>({width:20,height:30})};
const unit={stage:{},explorationRequest:'',explorationGeneration:0,freshNum:0,mFresh_txt:{},mFresh_btn:{},_refun:r=>painted.push('refresh'),reback:r=>painted.push('reply'),mirror_data:{},mOppAvt_arr:[],mOppAvt_spr:{addChild:noop}};
"""

@unittest.skipUnless(NODE,'Node required')
class ExplorationClientTests(unittest.TestCase):
    run_js=client_helpers.PlaytestClientTests.run_js
    def script(self):
        code=BASE
        for name,params in [('freshBtnStatus',''),('onTRIGGERED','event'),('freeFresh',''),('requestExploration','method,params=null'),('onExplorationError','event')]:
            code+=function('074_PanelActivityExplorationMap.as',name,params).replace('):void',')')
        return code

    def test_paid_refresh_remains_available_after_free_attempts(self):
        code=self.script()+r"""
unit.freshBtnStatus();unit.onTRIGGERED({});alerts[0][2].ok();
console.log(JSON.stringify({enabled:unit.mFresh_btn.enabled,quote:alerts[0][1],label:unit.mFresh_txt.text,calls:calls.map(v=>v.method)}));
"""
        result=self.run_js(code)
        self.assertIn('付费刷新：2次',result['label']);self.assertIn('10金砖',result['quote'])
        self.assertEqual(result['calls'],['user.exploration_refresh']);self.assertFalse(result['enabled'])

    def test_exhausted_or_unclaimed_reward_cannot_refresh(self):
        for reward in [False,True]:
            code=self.script()+f"GlobalData.$userData.records.exploration_times.refresh_buy=3;GlobalData.$userData.exploration.current_stage_finish={int(reward)};"+r"""
unit.freshBtnStatus();unit.onTRIGGERED({});console.log(JSON.stringify({enabled:unit.mFresh_btn.enabled,alerts:alerts.length,calls:calls.length,words:words.length}));
"""
            self.assertEqual(self.run_js(code),dict(enabled=False,alerts=0,calls=0,words=1))

    def test_double_request_error_recovery_and_closed_panel_receipt(self):
        code=self.script()+r"""
unit.requestExploration('user.exploration_refresh');unit.requestExploration('user.exploration_refresh');
unit.onExplorationError({data:{method:'user.exploration_refresh'}});
const recovered=unit.mFresh_btn.enabled;
unit.requestExploration('user.exploration_refresh');const count=calls.length;
calls[0].cb({return_code:0,data:{stage:1}});
unit.stage=null;calls[1].cb({return_code:0,data:{stage:1}});
console.log(JSON.stringify({recovered,count,painted:painted.length}));
"""
        self.assertEqual(self.run_js(code),dict(recovered=True,count=2,painted=0))

    def test_stale_profile_or_old_stage_cannot_reopen_opponent_panel(self):
        code=self.script()+r"""
unit.requestExploration('user.exploration_opponent',{stage:1});
GlobalData.$userData.exploration.stage=2;calls[0].cb({return_code:0,data:{stage:1}});
unit.requestExploration('user.exploration_get_reward');calls[1].cb({return_code:0,data:{stage:2},state_sync:{stale:true}});
console.log(JSON.stringify({painted:painted.length,waiting:unit.explorationRequest}));
"""
        self.assertEqual(self.run_js(code),dict(painted=0,waiting=''))

    def test_four_enemy_preview_uses_actual_snapshot_health(self):
        code=BASE+function('173_PanelActivityExplorationMyTeam.as','setOpponentAvatars').replace('mirror_data.army as Array','mirror_data.army').replace('mirror_data.units as Array','mirror_data.units')+r"""
unit.mirror_data={is_npc:true,army:Array.from({length:4},(_,i)=>['A_'+i,99,1,0,.2,1,500,1000]),units:Array.from({length:4},(_,i)=>({aid:'A_'+i,hp:500+i,hp_max:1000+i,ap:10+i}))};
unit.setOpponentAvatars();console.log(JSON.stringify(unit.mOppAvt_arr));
"""
        result=self.run_js(code);self.assertEqual(len(result),4)
        for i,row in enumerate(result):
            self.assertFalse(row['isArray']);self.assertEqual(row['data']['current_hp'],500+i)
            self.assertEqual(row['data']['max_hp'],1000+i);self.assertEqual(row['scaleX'],.78)
            self.assertLessEqual(row['x']+row['width']*row['scaleX'],330)

    def test_entry_with_full_roster_still_opens_manual_selection(self):
        for resume,expected in [(False,'exploration_select'),(True,'exploration_select_game')]:
            code=BASE+r"""
GlobalData.$userData.exploration.army=Object.fromEntries(Array.from({length:15},(_,i)=>['hero'+i,{current_hp:50,max_hp:100}]));
GlobalData.$mConfig_simple.explore.map_max=12;
GlobalData.$mGameClassObject={mLayoutUICenter:{showPanel:panel=>painted.push(panel)}};
const GlobalLanguageStr={getLanguageStr:()=>''};Tools.getElementNum=o=>Object.keys(o).length;
unit.mSchedule_spr={};
"""+f'unit.resumeExploration={str(resume).lower()};'+function('102_PanelActivityExploration.as','backFun','param1')+r"""
unit.backFun({data:{army:GlobalData.$userData.exploration.army},state_sync:{}});
console.log(JSON.stringify({painted,health:GlobalData.$exploration_select_avatar.hero0.current_hp}));
"""
            self.assertEqual(self.run_js(code),dict(painted=[expected],health=50))

    def test_confirmed_new_roster_replaces_temporary_battle_selection(self):
        code=BASE+r"""
GlobalData.$exploration_select_avatar={old:{}};
GlobalData.$mGameClassObject={mLayoutUICenter:{screenID:'a',mCurrPanel:'b',lastPanel_ID:'c',mPanelExplorationMap:{}}};
GlobalFunction.closePopAllPanel=noop;
"""+function('103_PanelActivityExplorationSure.as','backFun','param1').replace('):void',')')+r"""
unit.backFun({data:{army:{newHero:{current_hp:20,max_hp:100}}},state_sync:{}});
console.log(JSON.stringify(GlobalData.$exploration_select_avatar));
"""
        self.assertEqual(self.run_js(code),dict(newHero=dict(current_hp=20,max_hp=100,id='newHero')))

if __name__=='__main__':unittest.main()
