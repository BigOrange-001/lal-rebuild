"""Actual medal tab routing and late list receipts, with native widget stubs."""
import subprocess
import unittest
from pathlib import Path
from test_abyss_ui_104 import method

ROOT=Path(__file__).resolve().parents[1]


class MedalExchangeClientTests(unittest.TestCase):
    def test_tabs_filter_items_and_slow_reply_reaches_current_panel(self):
        source=(ROOT/'client/src/stages/155_PanelExchange.as').read_text('utf-8')
        script=r'''
const assert=require('node:assert/strict'),int=Math.trunc;
let recruitTarget105=null,pending=null,sent=0;
const GlobalData={$mConfig_equip:{E_one:{}},$mConfig_avatar:{A_one:{}},isCurrentProfileSyncEnvelope:()=>true};
const GuideMaster={getOnlyExample:()=>({checkGuide:()=>{}})};
function ListCollection(){};function ItemExchange(){};
const SendAndSelect={sendAndSelectService:(m,p,fn)=>{if(!pending){pending=fn;sent++;}}};
'''
        for name,args in [('receiveDailyRecruit105','result'),('showDailyRecruit105','result'),('loadDailyRecruit',''),('addList','')]:
            script+='const '+name+'='+method(source,name,args)+';\n'
        script+=r'''
function panel(){const p={stage:{},mTabBar:{selectedIndex:0},mList:{},rows:null,updateInfo:()=>{},
setListTimer:(list,rows)=>p.rows=rows};
p.showDailyRecruit105=showDailyRecruit105.bind(p);p.loadDailyRecruit=loadDailyRecruit.bind(p);p.addList=addList.bind(p);return p;}
const old=panel();old.addList();old.stage=null;
const current=panel();current.addList();current.mTabBar.selectedIndex=1;current.addList();
assert.equal(sent,1);
const receipt={return_code:0,data:{day:'2026-11-17',items:[{kind:'equip',id:'E_one',medal:80},{kind:'avatar',id:'A_one',medal:80}]}};
const done=pending;pending=null;done(receipt);
assert.equal(old.rows,null);assert.deepEqual(current.rows.map(r=>r.indexID_s),['equip']);
current.mTabBar.selectedIndex=0;current.showDailyRecruit105(receipt);
assert.deepEqual(current.rows.map(r=>r.indexID_s),['avatar']);assert.equal(current.rows[0].status,true);
'''
        run=subprocess.run(['node'],input=script,capture_output=True,text=True,encoding='utf-8',cwd=ROOT)
        self.assertEqual(run.returncode,0,run.stdout+run.stderr)
