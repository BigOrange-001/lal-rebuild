"""Exercise task-panel flow and renderer geometry using actual AS methods."""
import unittest
import re

import test_playtest_client as client_helpers
from test_playtest_client import NODE


def function(filename, name, params=''):
    source = client_helpers.function(filename, name, params)
    source = re.sub(r'function\([^)]*\)',
                    lambda match: re.sub(r':\s*\w+', '', match.group()), source)
    return re.sub(r'for each\((\w+) in ([\w.]+)\)', r'for(\1 of \2)', source)


BASE = r'''
const noop=()=>{};
const int=Math.trunc;
let requests=[],popups=[],drawn=[];
const GlobalData={$mStageWidth:640,$center_height_curr:1000,
 $mConfig_avatar:{A_1226_6:{name:'二郎真君赵信'}},$mConfig_equip:{},
 $mEventDispatcher:{dispatchEventWith:noop}};
const GlobalFunction={isCurrentProfileSyncEnvelope:()=>true,popAlert:(...args)=>popups.push(args)};
GlobalData.isCurrentProfileSyncEnvelope=()=>true;
const SendAndSelect={sendAndSelectService:(method,params,cb)=>requests.push({method,params,cb})};
const Tools={clone:v=>({...v})};
function ListCollection(rows=[]){this.rows=rows;}
function ItemTaskAward(){}
const GuideMaster={getOnlyExample:()=>({nextGuideStep:noop})};
const unit={stage:{},adventureData:null,adventureRequest:0,adventureClaiming:false,adventureTab:0,
 adventureButtons:[{},{},{}],adventureStatus:{},mList:{validate:noop,verticalScrollPosition:0},adventureReady:0,
 buildAdventureUI:noop,setListTimer:(list,rows)=>drawn=rows};
'''


@unittest.skipUnless(NODE, 'Node is required for ActionScript control-flow checks')
class AdventureClientTests(unittest.TestCase):
    run_js = client_helpers.PlaytestClientTests.run_js
    def test_task_rows_progress_and_repeat_quantity(self):
        script = BASE + function('009_PanelCenterTaskAward.as', 'addList')
        script += r'''
unit.adventureData={paid_yuan:4000,daily:[{key:'login',title:'每日登录',count:2,goal:1,claimable:true}],
 milestones:[{key:'6',required_yuan:6,claimable:true}],
 repeat:{key:'2000',available_count:2,claimed_count:0,claimable:true}};
unit.mList.verticalScrollPosition=380;
unit.addList();const daily=drawn[0];
unit.adventureTab=1;unit.addList();const milestone=drawn[0];
unit.adventureTab=2;unit.addList();
console.log(JSON.stringify({daily,milestone,repeat:drawn[0],ready:unit.adventureReady,scroll:unit.mList.verticalScrollPosition}));
'''
        result = self.run_js(script)
        self.assertEqual(result['daily']['progress_text'], '进度：1/1')
        self.assertEqual(result['milestone']['title'], '累计充值6元')
        self.assertIn('当前可领取2张', result['repeat']['progress_text'])
        self.assertEqual(result['ready'], 3)
        self.assertEqual(result['scroll'], 380)

    def test_claim_double_click_and_removed_page_callback(self):
        script = BASE + function('009_PanelCenterTaskAward.as', 'onAdventureClaim', 'param1')
        script += r'''
unit.addList=noop;unit.update=noop;
const row={key:'2000',kind:'repeat',claimable:true,reward_text:'橙卡'};
unit.onAdventureClaim({data:row});unit.onAdventureClaim({data:row});
const first=requests[0];unit.stage=null;
first.cb({return_code:0,data:{tasks:{},award:{avatar:{A_1226_6:2}}}});
console.log(JSON.stringify({count:requests.length,params:first.params,popups}));
'''
        result = self.run_js(script)
        self.assertEqual(result['count'], 1)
        self.assertEqual(result['params'], {'kind': 'repeat', 'key': '2000'})
        self.assertEqual(result['popups'], [])

    def test_claim_updates_tasks_and_names_actual_hero(self):
        script = BASE + function('009_PanelCenterTaskAward.as', 'onAdventureClaim', 'param1')
        script += r'''
unit.addList=noop;unit.update=noop;
unit.onAdventureClaim({data:{key:'10000',kind:'milestone',claimable:true,reward_text:'橙卡'}});
requests[0].cb({return_code:0,data:{tasks:{paid_yuan:10000},award:{avatar:{A_1226_6:1}}}});
console.log(JSON.stringify({claiming:unit.adventureClaiming,tasks:unit.adventureData,popups}));
'''
        result = self.run_js(script)
        self.assertFalse(result['claiming'])
        self.assertEqual(result['tasks']['paid_yuan'], 10000)
        self.assertEqual(result['popups'], [['奖励已领取', '二郎真君赵信×1']])

    def test_renderer_children_stay_inside_card(self):
        script = BASE + r'''
const Rectangle=function(){};
GlobalFunction.createScale9Image=(id,width,height)=>({id,width,height,x:0,y:0});
GlobalFunction.createTextField=(width,height,text,font,size)=>({width,height,text,size,x:0,y:0});
function LOL_Scale9Button(text,width,height){Object.assign(this,{text,width,height,x:0,y:0,addEventListener:noop});}
unit.addChild=v=>drawn.push(v);unit.layoutWH=noop;unit.onAdventureButton=noop;
'''
        script += function('133_ItemTaskAward.as', 'renderAdventureTask', 'row')
        script += r'''
const output=[];
for(const width of [480,640,720]){
 GlobalData.$mStageWidth=width;drawn=[];
 unit.renderAdventureTask({title:'每累计充值2000元，再领橙卡',progress_text:'已领取10张，当前可领取20张',
  reward_text:'金砖×20000、培养书×10000、装备粉尘各1500',kind:'repeat',claimable:true,available_count:20});
 output.push({width:width-24,height:158,children:drawn});
}
console.log(JSON.stringify(output));
'''
        for card in self.run_js(script):
            for child in card['children']:
                self.assertLessEqual(child['x'] + child['width'], card['width'])
                self.assertLessEqual(child['y'] + child['height'], card['height'])


if __name__ == '__main__':
    unittest.main()
