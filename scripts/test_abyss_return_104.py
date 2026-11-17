"""Real return/tab/resume method bodies with native navigation stubs."""
import subprocess
import unittest
from pathlib import Path

from test_abyss_ui_104 import method

ROOT = Path(__file__).resolve().parents[1]


class AbyssReturnTests(unittest.TestCase):
    def run_js(self, script):
        result = subprocess.run(['node'], input=script, capture_output=True, text=True, encoding='utf-8', cwd=ROOT)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_settlement_snapshots_exclude_accumulated_summons_only_in_abyss(self):
        source = (ROOT / 'client/src/stages/175_GameMap.as').read_text('utf-8')
        script = r'''
const assert=require('node:assert/strict');
let sent=[],ready=0;
const GlobalData={$abyss104:{finish:null}};
const GameMapLayer={gl:{uiLayer:{setCanReturn:()=>ready++}}};
const SendServiceAMFFun={send_user_battle_finish:(done,request,key,method)=>sent.push({done,request,key,method})};
function avatar(aid,hp){return {hp,toDataObj:()=>({aid,hp,hp_max:1000})};}
const originalA=[avatar('hero-a',-300),avatar('hero-b',0),avatar('hero-c',0)];
const originalB=[avatar('enemy-a',900),avatar('enemy-b',50),avatar('enemy-c',0)];
// Same-id clones must also stay out of the original heroes' health snapshots.
const summons=Array.from({length:80},()=>avatar('hero-a',-20));
const panel={team1List:originalA.concat(summons),team2List:originalB.concat(summons),
re:{data:{fight_id:'saved-fight',fight_kind:'abyss',metadata:{run_id:'run',node_id:'node'},
orgin_team_a:originalA,orgin_team_b:originalB},params:{}},gameMapData:{id:'abyss'},diff:0,
winner:2,settlementPending:true};
'''
        script += 'panel.submit=' + method(source, 'submitBattleFinish', '') + ';\n'
        script += r'''
panel.submit();
assert.deepEqual(sent[0].request.teams.team_a,originalA.map(u=>u.toDataObj()));
assert.deepEqual(sent[0].request.teams.team_b,originalB.map(u=>u.toDataObj()));
assert.equal(panel.team1List.length,83);assert.equal(panel.team2List.length,83);
assert.equal(panel.settlementPending,true);assert.equal(ready,0);
panel.submit();assert.deepEqual(sent[1].request,sent[0].request);assert.equal(sent[1].key,sent[0].key);
sent[1].done({return_code:0,data:{sign:2,abyss_run:{battle:null,retries:19}}});
assert.equal(panel.settlementPending,false);assert.equal(ready,1);
assert.equal(GlobalData.$abyss104.finish.sign,2);
assert.equal(GlobalData.$abyss104.finish.abyss_run.battle,null);
panel.re.data.fight_kind='exploration';panel.submit();
assert.equal(sent[2].request.teams.team_a.length,83);
assert.equal(sent[2].request.teams.team_b.length,83);
'''
        self.run_js(script)

    def test_battle_return_waits_for_receipt_then_leaves_exploration_mode(self):
        source = (ROOT / 'client/src/stages/163_UiLayer.as').read_text('utf-8')
        script = r'''
const assert=require('node:assert/strict');
let retries=0,mode=4;const shown=[];
const layout={mCurrPanel:''};
const GlobalData={$abyss104:{finish:{sign:1}},backFromExploration:true,
$mGameClassObject:{mLayoutUICenter:layout},get $isExploration(){return mode===4;},$setPVE:()=>mode=0,
$mEventDispatcher:{dispatchEventWith:(type,bubbles,data)=>{
 assert.equal(type,'stage_ui');
 // Native Game.onSTAGE routes exploration directly to panel_maze, before
 // considering mCurrPanel or the ordinary award receipt.
 shown.push(mode===4?'panel_maze':data?'ordinary_award':layout.mCurrPanel);
}}};
const PanelCenterPVE={$abyssTab104:false},PanelCenterPVP={$tabBarSelectedIndex:0};
const GameMap={currentMap:{settlementPending:true,re:{data:{fight_kind:'abyss'}},retryBattleFinish:()=>retries++},isLoadFile:false};
'''
        script += 'const back=' + method(source, 'returnPanel', '') + ';\n'
        script += r'''
back();assert.equal(retries,1);assert.deepEqual(shown,[]);assert.equal(mode,4);
for(const sign of [1,2]){
 mode=4;GlobalData.backFromExploration=true;GlobalData.$abyss104={finish:{sign}};
 GameMap.currentMap.settlementPending=false;back();
 assert.equal(shown.at(-1),'center_pve');assert.equal(mode,0);
 assert.equal(GlobalData.$abyss104.resume,true);assert.equal(GlobalData.$abyss104.finish.sign,sign);
 assert.equal(PanelCenterPVE.$abyssTab104,true);assert.equal(GlobalData.backFromExploration,false);
}
GameMap.currentMap.re.data.fight_kind='exploration';mode=4;back();assert.equal(shown.at(-1),'panel_maze');
GameMap.currentMap.re.data.fight_kind='formation';mode=0;back();assert.equal(shown.at(-1),'center_pvp');
'''
        self.run_js(script)

    def test_abyss_tab_takes_priority_over_previous_campaign_selection(self):
        source = (ROOT / 'client/src/stages/054_PanelCenterPVE.as').read_text('utf-8')
        script = r'''
const assert=require('node:assert/strict'),noop=()=>{};
const ABYSS_TAB_104=3;
const GlobalData={$tempPVE_type_id:2,$maze_BattleId:'M_old',$abyss104:null};
const GlobalFunction={checkGameFunIsOpenByType:()=>50};
const changes=[];const panel={$abyssTab104:true,mTabBar:{selectedIndex:0,setChildStatus:noop},
tabBar_changeHandler:()=>changes.push(panel.mTabBar.selectedIndex),tabBar_changeHandler_false:noop};
'''
        script += 'panel.created=' + method(source, 'tabBar_CREATION_COMPLETE', 'event') + ';\n'
        script += r'''
panel.created(null);assert.deepEqual(changes,[3]);assert.equal(GlobalData.$tempPVE_type_id,2);
changes.length=0;panel.$abyssTab104=false;GlobalData.$abyss104={resume:true};
panel.created(null);assert.deepEqual(changes,[3]);
changes.length=0;GlobalData.$abyss104=null;panel.created(null);assert.equal(panel.mTabBar.selectedIndex,0);
'''
        self.run_js(script)

    def test_resume_keeps_win_choice_and_loss_retry_flow(self):
        source = (ROOT / 'client/src/abyss_ui_104.aspart').read_text('utf-8')
        script = r'''
const assert=require('node:assert/strict');
const int=Math.trunc;const GlobalData={$abyss104:null};
const Starling={juggler:{delayCall:fn=>fn()}};
const AbyssCore104={REOPEN_DELAY:.3};function AbyssMapPanel104(){}
const shown=[];
const panel={run:{status:'active'},query:fn=>fn({}),closeAll:()=>{},open:p=>shown.push('map'),
rewardsOf:()=>[],openNodeStep:()=>shown.push('next'),showRetry:()=>shown.push('retry'),showFinalFailure:()=>shown.push('failed')};
'''
        script += 'panel.resume=' + method(source, 'resumeAfterBattle', 'afterQuery=false') + ';\n'
        script += r'''
for(const [sign,status,expected] of [[1,'active','next'],[2,'active','retry'],[2,'failed','failed']]){
 shown.length=0;GlobalData.$abyss104={finish:{sign},node_id:'1-1-0',resume:true};panel.run.status=status;
 panel.resume();assert.deepEqual(shown,['map',expected]);assert.equal(GlobalData.$abyss104,null);
}
'''
        self.run_js(script)

    def test_slow_entry_reply_restores_map_without_another_query(self):
        source = (ROOT / 'client/src/abyss_ui_104.aspart').read_text('utf-8')
        script = r'''
const assert=require('node:assert/strict'),int=Math.trunc;
const GlobalData={$abyss104:{resume:true,finish:{sign:1},node_id:'1-1-0'}};
const Starling={juggler:{delayCall:fn=>fn()}};
function AbyssEntryPanel104(){this.resetChoice=()=>{};this.refresh=()=>{};}
function AbyssMapPanel104(){}
let reply=null,queries=0,steps=0,maps=0;
const core={REOPEN_DELAY:.3,run:{status:'active'},query:fn=>{queries++;assert.equal(queries,1);reply=fn;},
closeAll:()=>{},open:p=>{assert(p instanceof AbyssMapPanel104);maps++;},rewardsOf:()=>[],openNodeStep:()=>steps++};
const AbyssCore104=core;
'''
        script += 'core.resumeAfterBattle=' + method(source, 'resumeAfterBattle', 'afterQuery=false') + ';\n'
        script += 'core.createEntryTab=' + method(source, 'createEntryTab', 'area') + ';\n'
        script += r'''
const context=GlobalData.$abyss104;
const entry=core.createEntryTab({x:0,y:80,width:640,height:900});
assert.equal(queries,1);assert.equal(maps,0);assert.equal(GlobalData.$abyss104,context);
// The entry query can take longer than any former 0.15-second timer.
reply({});assert.equal(queries,1);assert.equal(maps,1);assert.equal(steps,1);
assert.equal(GlobalData.$abyss104,null);
'''
        self.run_js(script)

    def test_suppressed_or_failed_query_keeps_battle_return_context(self):
        source = (ROOT / 'client/src/abyss_ui_104.aspart').read_text('utf-8')
        script = r'''
const assert=require('node:assert/strict');
const GlobalData={$abyss104:{resume:true,finish:{sign:2},node_id:'1-1-0'}};
const context=GlobalData.$abyss104;
const panel={query:fn=>{},closeAll:()=>{throw Error('must wait for reply');}};
'''
        script += 'panel.resume=' + method(source, 'resumeAfterBattle', 'afterQuery=false') + ';\n'
        script += 'panel.resume();assert.equal(GlobalData.$abyss104,context);\n'
        self.run_js(script)


if __name__ == '__main__':
    unittest.main()
