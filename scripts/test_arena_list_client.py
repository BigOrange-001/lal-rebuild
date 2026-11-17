"""Actual arena query callbacks with delayed transport and page lifecycle stubs."""
import subprocess
import unittest
from pathlib import Path

from test_abyss_ui_104 import method

ROOT = Path(__file__).resolve().parents[1]


class ArenaListClientTests(unittest.TestCase):
    def script(self):
        source = (ROOT/'client/src/stages/046_PanelCenterPVP.as').read_text('utf-8')
        transport = (ROOT/'client/src/stages/003_SendAndSelect.as').read_text('utf-8')
        script = r'''
const assert=require('node:assert/strict'),int=Math.trunc;
let arenaRankTarget105=null;
const GlobalData={$userData:{uid:'owner',mark:0}},MainConfig={$isEnglish:false};
const GlobalFunction={isVersionedProfileReceipt:r=>!!r.state_sync,popAlert:()=>{}};
const GlobalLanguageStr={getLanguageStr:()=>''};
const SendAndSelect={$systemTimer_nowSecond:100,$serviceData:{}};
const pending=[],sent=[];
function send(name,fn){
 if(SendAndSelect.checkRepeat(name,'')) return;
 let action='request-'+sent.length;
 SendAndSelect.$serviceData[action]={sendMethod:name};
 pending.push({name,fn,action});sent.push(name);
}
const SendServiceAMFFun={send_user_get_rank_list:fn=>send('user.get_rank_list',fn),
send_user_refresh_pvp_opponents:fn=>send('user.refresh_pvp_opponents',fn)};
function reply(request,label,revision){
 delete SendAndSelect.$serviceData[request.action];
 request.fn({return_code:0,data:[1,[],[label],[],[],0,0],state_sync:{uid:'owner',revision}});
}
'''
        # checkRepeat's Dictionary iteration is over keys in native AS.
        body = method(transport,'checkRepeat','param1,param2')
        script += 'SendAndSelect.checkRepeat=' + body + '.bind(SendAndSelect);\n'
        script += 'const receiveArenaRankList105=' + method(source,'receiveArenaRankList105','reply') + ';\n'
        script += 'const select=' + method(source,'selectList','param1') + ';\n'
        script += 'const change=' + method(source,'changeOpponents','param1') + ';\n'
        script += 'const receive=' + method(source,'re_get_rank_list','param1') + ';\n'
        script += r'''
function panel(){const p={stage:{},mTabBar:{selectedIndex:1},mFun_status:false,
mChange_s:-100,mRefresh_s:0,arenaRankRevision105:-1,mPVP_list:null,mTxt_pkTimes:null,
shareModal104:null,raidModal105:null,renders:0,setList:()=>{},loadRaids105:()=>{},
addList:()=>p.renders++};
p.re_get_rank_list=receive.bind(p);p.selectList=select.bind(p);p.change=change.bind(p);return p;}
'''
        return script

    def run_case(self, script):
        result = subprocess.run(['node'],input=self.script()+script,capture_output=True,
                                text=True,encoding='utf-8',cwd=ROOT)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)

    def test_slow_query_reaches_reopened_panel_without_refreshing_opponents(self):
        self.run_case(r'''
const old=panel();old.selectList(true);const request=pending.shift();old.stage=null;
const current=panel();current.selectList(true);
assert.equal(sent.length,1);reply(request,'same-batch',10);
assert.equal(old.renders,0);assert.equal(current.renders,1);
assert.deepEqual(current.mPVP_list[2],['same-batch']);
assert.deepEqual(sent,['user.get_rank_list']);
''')

    def test_late_initial_reply_cannot_replace_manual_refresh(self):
        self.run_case(r'''
const current=panel();current.selectList(true);const initial=pending.shift();
current.change(null);const refreshed=pending.shift();reply(refreshed,'new-batch',20);
reply(initial,'old-batch',10);
assert.deepEqual(current.mPVP_list[2],['new-batch']);assert.equal(current.renders,1);
''')

    def test_late_reply_does_not_replace_reports_or_other_tabs(self):
        self.run_case(r'''
for(const tab of [1,4]){
 const current=panel();current.selectList(true);const request=pending.shift();
 current.mTabBar.selectedIndex=tab;current.mFun_status=tab===1;
 reply(request,'batch',30);assert.equal(current.renders,0);
}
const current=panel();current.selectList(true);const request=pending.shift();
current.stage=null;reply(request,'batch',31);assert.equal(current.renders,0);
''')
