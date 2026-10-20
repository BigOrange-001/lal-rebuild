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
const Starling={juggler:{add:noop,removeTweens:noop}};
function Tween(){this.fadeTo=noop;this.animate=noop;}
function Quad(width,height,color){Object.assign(this,{width,height,color,x:0,y:0});}
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
unit.addChild=v=>drawn.push(v);unit.layoutWH=noop;unit.onAdventureButton=noop;unit.addAdventureRewardIcon=noop;
'''
        script += function('133_ItemTaskAward.as', 'renderAdventureTask', 'row')
        script += r'''
const output=[];
for(const width of [480,640,720]){
 GlobalData.$mStageWidth=width;drawn=[];
 unit.renderAdventureTask({title:'每累计充值2000元，再领橙卡',progress_text:'已领取10张，当前可领取20张',
  reward_text:'金砖×20000、培养书×10000、装备粉尘各1500',kind:'repeat',claimable:true,available_count:20});
 output.push({width:width-24,height:208,children:drawn});
}
console.log(JSON.stringify(output));
'''
        for card in self.run_js(script):
            for child in card['children']:
                self.assertLessEqual(child['x'] + child['width'], card['width'])
                self.assertLessEqual(child['y'] + child['height'], card['height'])

    def test_task_header_and_list_reserve_bottom_bar_at_short_and_tall_heights(self):
        script=BASE+r'''
function Rectangle(){}
function Timer(){this.addEventListener=noop;this.start=noop;}
function VerticalLayout(){}
function List(){}
GlobalFunction.createScale9Image=(id,width,height)=>({width,height,x:0,y:0});
GlobalFunction.createTextField=(width,height,text)=>({width,height,text,x:0,y:0});
function LOL_Scale9Button(text,width,height){Object.assign(this,{text,width,height,x:0,y:0,addEventListener:noop});}
unit.addChild=v=>drawn.push(v);unit.adventureUnderline=null;
unit.onAdventureTab=noop;unit.onAdventureTimer=noop;
'''+function('009_PanelCenterTaskAward.as','buildAdventureUI')+function('009_PanelCenterTaskAward.as','setList')+r'''
const result=[];
for(const width of [480,640,720])for(const height of [850,1028]){
 GlobalData.$mStageWidth=width;GlobalData.$center_height_curr=height;
 unit.adventureStatus=null;unit.mList=null;unit.adventureButtons=[];drawn=[];unit.buildAdventureUI();
 result.push({width,height,children:drawn});
}
console.log(JSON.stringify(result));
'''
        for page in self.run_js(script):
            for child in page['children']:
                self.assertGreaterEqual(child.get('x',0),0)
                self.assertLessEqual(child.get('x',0)+child['width'],page['width'])
                self.assertLessEqual(child.get('y',0)+child['height'],page['height']-121)
            listing=page['children'][-1]
            self.assertEqual(listing['y'],184)
            self.assertEqual(listing['y']+listing['height'],page['height']-133)

    def test_failed_claim_restores_buttons_before_identical_data_refresh(self):
        script=BASE+function('009_PanelCenterTaskAward.as','onAdventureClaim','param1')
        script+=r'''
let renders=[];unit.addList=()=>renders.push(unit.adventureClaiming);unit.update=noop;
unit.onAdventureClaim({data:{key:'login',kind:'daily',claimable:true}});
requests[0].cb({return_code:1});
console.log(JSON.stringify({renders,claiming:unit.adventureClaiming}));
'''
        self.assertEqual(self.run_js(script),{'renders':[True,False],'claiming':False})

    def test_tab_motion_keeps_list_geometry_and_same_tab_is_noop(self):
        script=BASE+r'''
function LOL_Scale9Button(){}
unit.adventureUnderline={x:26};let rendered=0,animations=[];
unit.addList=()=>rendered++;unit.mList.y=184;
Starling.juggler.add=t=>animations.push(t);
'''+function('009_PanelCenterTaskAward.as','onAdventureTab','param1').replace('param1.currentTarget as LOL_Scale9Button','param1.currentTarget')+r'''
unit.onAdventureTab({currentTarget:{name:'0',x:20}});
const same=rendered;unit.onAdventureTab({currentTarget:{name:'1',x:220}});
console.log(JSON.stringify({same,rendered,tab:unit.adventureTab,y:unit.mList.y,scroll:unit.mList.verticalScrollPosition,animations:animations.length}));
'''
        self.assertEqual(self.run_js(script),{'same':0,'rendered':1,'tab':1,'y':184,'scroll':0,'animations':2})

    def test_reward_icon_uses_native_assets_and_fits_in_reserved_column(self):
        script=BASE+r'''
GlobalFunction.createImage=id=>({id,width:140,height:190,scaleX:1,scaleY:1});
GlobalFunction.createTextField=(width,height,text)=>({width,height,text,x:0,y:0});
GlobalFunction.getAwardByType=(type)=>({ui:{id:type,width:100,height:100,scaleX:1,scaleY:1}});
unit.addChild=v=>drawn.push(v);unit.parent=null;
'''
        src=function('133_ItemTaskAward.as','addAdventureRewardIcon','row')
        src=src.replace('reward.attrs.dust as Array','reward.attrs.dust').replace('this.parent.parent as List','this.parent.parent')
        script+=src+r'''
const result=[];
for(const reward of [{random_non_skin_orange_hero:1},{coin:200},{attrs:{dust:[0,0,20,0]}}]){
 drawn=[];unit.addAdventureRewardIcon({reward});
 const icon=drawn[0];result.push({id:icon.id,w:icon.width*icon.scaleX,h:icon.height*icon.scaleY,caption:drawn[1].text});
}
console.log(JSON.stringify(result));
'''
        rows=self.run_js(script)
        self.assertEqual([x['id'] for x in rows],['UI_bg_card_2_0003','coin','dust'])
        self.assertEqual(rows[0]['caption'],'随机橙卡')
        for icon in rows:
            self.assertLessEqual(icon['w'],72)
            self.assertLessEqual(icon['h'],76)


if __name__ == '__main__':
    unittest.main()
