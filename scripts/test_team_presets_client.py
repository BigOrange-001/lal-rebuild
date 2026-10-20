"""Execute the real preset UI methods with display/transport stubs."""
import json
import re
import shutil
import unittest
from pathlib import Path

from test_avatar_passive import method_body
import test_playtest_client as harness

SOURCE = Path(__file__).resolve().parents[1] / 'client/src/stages/028_PanelCenterMain.as'


def method(name, params=''):
    body = method_body(SOURCE.read_text('utf8'), name)
    body = re.sub(r'for each\(var (\w+) in ([^)]+)\)', r'for(var \1 of Object.values(\2))', body)
    body = re.sub(r'(function\([^)]*):\s*\w+', r'\1', body)
    body = re.sub(r'function\((\w+):\w+\)', r'function(\1)', body)
    return f'unit.{name}=function({params}){{with(this){{{body}\n}}}};\n'


@unittest.skipUnless(shutil.which('node'), 'Node is required for AS behavior checks')
class TeamPresetClientTests(unittest.TestCase):
    run_js = harness.PlaytestClientTests.run_js

    def test_four_rows_five_hero_previews_and_captain_badges(self):
        script = '''class Sprite{constructor(){this.children=[];}addChild(c){this.children.push(c);return c;}removeChildren(){this.children=[];}}
class Quad extends Sprite{constructor(w,h,c){super();Object.assign(this,{width:w,height:h,color:c});}}
class LOL_TextField extends Sprite{constructor(text,w,h){super();Object.assign(this,{text,width:w,height:h});}}
class LOL_Scale9Button extends Sprite{constructor(label,w,h){super();Object.assign(this,{label,width:w,height:h});}addEventListener(){}}
function Rectangle(){}
const GlobalData={$userData:{uid:'one',avatars:{},attrs:{team_presets:[]}}};
for(let slot=0;slot<4;slot++){let preview=[];for(let n=0;n<5;n++){let id=`s${slot}h${n}`;
GlobalData.$userData.avatars[id]={aid:'A_1001_3'};preview.push({id,aid:'A_1001_3',name:'英雄',leader:n===0});}
GlobalData.$userData.attrs.team_presets.push({preview,as_equips:[['eq',null]],dn_bindings:{1:'dnHero'}});}
delete GlobalData.$userData.avatars.s1h3;
const GlobalFunction={createScale9Image:(id,width,height)=>({id,width,height}),createImage:()=>({}),getAvatarCfg:()=>({res:'A_1001_3',name:'英雄'}),getAvatarIcon:aid=>({icon:aid})};
const unit={mPresetRows:new Sprite(),mPresetBusy:false,mPresetNotice:'ready',onPresetCommand(){}};
'''
        script += method('presetText', 'parent,text,x,y,w,h,size=18,color=16777215')
        script += method('presetButton', 'parent,label,command,x,y,enabled')
        script += method('renderTeamPresets')
        script += '''unit.renderTeamPresets();let all=[];function walk(n){all.push(n);for(let c of n.children||[])walk(c);}walk(unit.mPresetRows);
console.log(JSON.stringify({rows:unit.mPresetRows.children.filter(c=>c instanceof Sprite&&!(c instanceof LOL_TextField)).length,
icons:all.filter(c=>c.icon).length,captains:all.filter(c=>c.text==='队长').length,
missing:all.filter(c=>c.text==='英雄（缺失）').length,buttons:all.filter(c=>c instanceof LOL_Scale9Button).map(c=>c.name)}));'''
        actual = self.run_js(script)
        self.assertEqual(actual['rows'], 4)
        self.assertEqual(actual['icons'], 20)
        self.assertEqual(actual['captains'], 4)
        self.assertEqual(actual['missing'], 1)
        self.assertEqual(actual['buttons'], [f'{op}:{slot}' for slot in range(1, 5) for op in ('save', 'load', 'delete')])

    def request_script(self):
        script = '''const int=v=>Math.trunc(Number(v))||0;const calls={sent:0,refresh:0,render:0};let callback=null;let blocked=false;
const SendAndSelect={$SendServiceAMFDispatcher:{addEventListener(){},removeEventListener(){}},checkRepeat:()=>blocked,
sendAndSelectService(method,params,fn){calls.sent++;params.actionID='test-action';callback=fn;}};
const GlobalData={$userData:{uid:'one',attrs:{team_num:1,team_presets:[]},team:[['leader'],['second'],[]]},
$mEventDispatcher:{dispatchEventWith(){calls.refresh++;}}};
const GlobalFunction={formateTeamToObj(){calls.refresh++;},getTeamPower:()=>123};
const unit={mPresetBusy:false,mPresetConfirm:null,mPresetPopup:{stage:{}},mPresetGeneration:3,mPresetActionID:'',
renderTeamPresets(){calls.render++;}};
'''
        script += method('presetPending')
        script += method('onPresetCommand', 'event')
        script += method('submitPresetCommand','commandName')
        script += method('onPresetError', 'event')
        script += method('onPresetPopupRemoved', 'event')
        return script

    def test_occupied_save_and_clear_do_not_send_before_confirmation(self):
        script=self.request_script()+r"""
let confirmations=[];unit.openPresetConfirmation=name=>confirmations.push(name);
GlobalData.$userData.attrs.team_presets=[{preview:[]}];
unit.onPresetCommand({currentTarget:{name:'save:1'}});unit.onPresetCommand({currentTarget:{name:'delete:1'}});
const before=calls.sent;unit.onPresetCommand({currentTarget:{name:'save:2'}});
console.log(JSON.stringify({before,confirmations,sent:calls.sent}));
"""
        self.assertEqual(self.run_js(script),{'before':0,'confirmations':['save:1','delete:1'],'sent':1})

    def test_confirmation_cancel_stale_owner_and_double_click_are_safe(self):
        script=r"""class Sprite{constructor(){this.children=[];this.stage={};}addChild(c){this.children.push(c);c.parent=this;return c;}removeFromParent(){if(this.parent)this.parent.children=this.parent.children.filter(c=>c!==this);}}
class Quad extends Sprite{constructor(w,h,c){super();Object.assign(this,{width:w,height:h,color:c});}}
class LOL_TextField extends Sprite{constructor(text,w,h){super();Object.assign(this,{text,width:w,height:h});}}
class LOL_Scale9Button extends Sprite{constructor(text,w,h){super();Object.assign(this,{text,width:w,height:h});}addEventListener(type,fn){this.trigger=fn;}}
function Rectangle(){};const int=Math.trunc,GlobalFunction={createScale9Image:()=>new Sprite()};
const GlobalData={$userData:{uid:'one'}};let sent=[];
const unit={mPresetPopup:new Sprite(),mPresetBusy:false,mPresetConfirm:null,mPresetGeneration:1,submitPresetCommand:name=>sent.push(name)};
"""+method('presetText','parent,text,x,y,w,h,size=18,color=16777215')+method('clearPresetConfirmation')+method('openPresetConfirmation','commandName')+r"""
unit.openPresetConfirmation('save:1');unit.mPresetConfirm.children.find(c=>c.text==='取消').trigger({});const canceled=unit.mPresetConfirm===null;
unit.openPresetConfirmation('delete:1');let button=unit.mPresetConfirm.children.find(c=>c.text==='确认清空');GlobalData.$userData.uid='two';button.trigger({});const stale=sent.length;
GlobalData.$userData.uid='one';button.trigger({});button.trigger({});
console.log(JSON.stringify({canceled,stale,sent,closed:unit.mPresetConfirm===null}));
"""
        self.assertEqual(self.run_js(script),{'canceled':True,'stale':0,'sent':['delete:1'],'closed':True})

    def test_load_refreshes_authoritative_cache_and_can_repeat_without_relogin(self):
        script = self.request_script() + '''unit.onPresetCommand({currentTarget:{name:'load:2'}});
callback({data:{team:[['stale']]}});let first={busy:unit.mPresetBusy,team:GlobalData.$tempTeam,power:GlobalData.$tempTeamPowerTemp};
unit.onPresetCommand({currentTarget:{name:'save:4'}});callback({});console.log(JSON.stringify({first,calls,busy:unit.mPresetBusy}));'''
        actual = self.run_js(script)
        self.assertEqual(actual['first'], {'busy': False, 'team': ['second'], 'power': 123})
        self.assertEqual(actual['calls']['sent'], 2)
        self.assertFalse(actual['busy'])

    def test_pending_requests_and_account_switch_are_guarded(self):
        script = self.request_script() + '''blocked=true;unit.onPresetCommand({currentTarget:{name:'save:1'}});
blocked=false;unit.onPresetCommand({currentTarget:{name:'load:1'}});GlobalData.$userData.uid='two';callback({});
console.log(JSON.stringify(calls));'''
        actual = self.run_js(script)
        self.assertEqual(actual['sent'], 1)
        self.assertEqual(actual['refresh'], 0)

    def test_error_unlocks_retry_and_popup_removal_ignores_child_events(self):
        script = self.request_script() + '''unit.onPresetCommand({currentTarget:{name:'save:1'}});
unit.onPresetError({data:{params:{actionID:'another'}}});let staleBusy=unit.mPresetBusy;
unit.onPresetError({data:{params:{actionID:'test-action'}}});let failedBusy=unit.mPresetBusy;
unit.onPresetPopupRemoved({target:{}});let childKept=unit.mPresetPopup!==null;
unit.onPresetPopupRemoved({target:unit.mPresetPopup});console.log(JSON.stringify({staleBusy,failedBusy,childKept,popup:unit.mPresetPopup}));'''
        self.assertEqual(self.run_js(script), {'staleBusy': True, 'failedBusy': False, 'childKept': True, 'popup': None})

    def test_load_receipt_after_close_updates_state_without_reopening_popup(self):
        script = self.request_script() + '''unit.onPresetCommand({currentTarget:{name:'load:1'}});
unit.onPresetPopupRemoved({target:unit.mPresetPopup});callback({});
console.log(JSON.stringify({popup:unit.mPresetPopup,busy:unit.mPresetBusy,render:calls.render,refresh:calls.refresh}));'''
        self.assertEqual(self.run_js(script), {'popup': None, 'busy': False, 'render': 1, 'refresh': 4})


if __name__ == '__main__':
    unittest.main()
