"""Exercise task-panel flow and renderer geometry using actual AS methods."""
import unittest
import re

import test_playtest_client as client_helpers
from test_playtest_client import NODE


def function(filename, name, params=''):
    source = client_helpers.function(filename, name, params)
    source = re.sub(r'function\([^)]*\)',
                    lambda match: re.sub(r':\s*\w+', '', match.group()), source)
    return re.sub(r'for each\((var \w+|\w+) in ([\w.]+)\)', r'for(\1 of \2)', source)


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
const unit={zhuabaoBox:null,zhuabaoRobot:null,stage:{},adventureData:null,adventureRequest:0,adventureClaiming:false,adventureTab:0,
 adventureButtons:[{},{},{}],adventureStatus:{},mList:{validate:noop,verticalScrollPosition:0},adventureReady:0,
 buildAdventureUI:noop,setListTimer:(list,rows)=>drawn=rows};
'''


@unittest.skipUnless(NODE, 'Node is required for ActionScript control-flow checks')
class AdventureClientTests(unittest.TestCase):
    run_js = client_helpers.PlaytestClientTests.run_js

    def test_profile_sync_error_unlocks_treasure_controls(self):
        script = BASE + function('009_PanelCenterTaskAward.as', 'onAdventureError', 'param1') + r'''
unit.adventureTab=3;unit.zhuabaoData={};unit.zhuabaoBusy=true;unit.renderZhuabao=()=>drawn.push('render');
unit.onAdventureError({data:{method:'profile_state_sync',receipt_method:'user.zhuabao_draw',profile_sync_error:true}});
console.log(JSON.stringify({busy:unit.zhuabaoBusy,drawn,status:unit.adventureStatus.text}));
'''
        result = self.run_js(script)
        self.assertFalse(result['busy'])
        self.assertEqual(result['drawn'], ['render'])
        self.assertIn('重新登录', result['status'])
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

    def test_zhuabao_draw_blocks_double_submit_and_ignores_closed_panel(self):
        code=BASE+r"""
unit.zhuabaoBusy=false;unit.zhuabaoRequest=0;unit.zhuabaoData={count:0};
unit.renderZhuabao=noop;
"""+function('009_PanelCenterTaskAward.as','requestZhuabao','method,params').replace('):void',')')+r"""
unit.requestZhuabao('user.zhuabao_draw',{num:10});
unit.requestZhuabao('user.zhuabao_draw',{num:10});
const count=requests.length;unit.stage=null;
requests[0].cb({return_code:0,data:{activity:{count:10},awards:[]}});
console.log(JSON.stringify({count,unchanged:unit.zhuabaoData.count===0,popups:popups.length}));
"""
        self.assertEqual(self.run_js(code),dict(count=1,unchanged=True,popups=0))

    def zhuabao_script(self):
        code=BASE+r"""
let animations=[],removed=[];
Starling.juggler.add=v=>animations.push(v);Starling.juggler.remove=v=>removed.push(v);
function Rectangle(x,y,width,height){Object.assign(this,{x,y,width,height});}
function Sprite(){this.children=[];this.numChildren=0;this.addChild=v=>{this.children.push(v);this.numChildren++;};this.getChildAt=i=>this.children[i];this.removeChildAt=i=>{this.children.splice(i,1);this.numChildren--;};}
function MovieClip(){Object.assign(this,{width:256,height:306,playing:true,playCount:0,stop:function(){this.playing=false;},play:function(){this.playing=true;this.playCount++;},addEventListener:noop});}
function LOL_Scale9Button(text,w,h,texture){Object.assign(this,{text,width:w,height:h,texture,addEventListener:noop});}
GlobalFunction.createImage=id=>({id,width:640,height:805});GlobalFunction.getTextureByBD=noop;
GlobalFunction.createButtonStarling=id=>({id,width:60,height:60,addEventListener:noop});
GlobalFunction.createTextField=(w,h,text)=>({width:w,height:h,text});
unit.addChild=noop;unit.zhuabaoBox=null;unit.zhuabaoRobot=null;unit.zhuabaoBusy=false;unit.zhuabaoPage=0;unit.zhuabaoRequest=0;unit.zhuabaoGifts=[];
unit.adventureTab=3;GlobalData.$center_height_curr=680;
unit.zhuabaoData={count:50,coin:1000,free:true,ten_cost:800,summary:'test',milestones:[10,50,100,300].map(tier=>({tier,pending:tier<=50?1:0,claimable:tier<=50}))};
"""
        for name,params in [('clearZhuabaoMotion',''),('onZhuabaoComplete','event'),('zhuabaoButton','label,key,x,y,w,h=56,enabled=true'),('zhuabaoPrice','x,y,w,amount'),('renderZhuabao',''),('requestZhuabao','method,params'),('onZhuabaoAction','event')]:
            code+=function('009_PanelCenterTaskAward.as',name,params).replace('new Vector.<Texture>()','[]').replace('):void',')').replace('event.currentTarget as DisplayObject','event.currentTarget').replace('zhuabaoData.pool as Array','zhuabaoData.pool')
        return code

    def test_zhuabao_native_controls_progress_and_idle_robot(self):
        code=self.zhuabao_script()+r"""
unit.renderZhuabao();
const nodes=unit.zhuabaoBox.children.filter(v=>v.name&&v.name.startsWith('claim'));
const labels=unit.zhuabaoBox.children.filter(v=>v.name&&v.name.startsWith('status'));
const fill=unit.zhuabaoBox.children.find(v=>v.clipRect);
const buttons=unit.zhuabaoBox.children.filter(v=>v.texture);
console.log(JSON.stringify({count:nodes.length,positions:nodes.map(v=>v.x),pulse:animations.length,bottom:Math.max(...labels.map(v=>v.y+v.height)),fill:fill.clipRect.width,buttons,coinIcons:unit.zhuabaoBox.children.filter(v=>v.name==='zhuabao_coin').length,currencyWords:unit.zhuabaoBox.children.some(v=>v.text&&v.text.includes('金砖')),robot:unit.zhuabaoRobot}));
"""
        result=self.run_js(code)
        self.assertEqual(result['count'],4);self.assertEqual(result['pulse'],2)
        self.assertEqual(result['coinIcons'],2);self.assertFalse(result['currencyWords'])
        self.assertEqual(result['positions'],[46+548*v/614 for v in [80,245,413,575]])
        self.assertAlmostEqual(result['fill'],548*245/614-4)
        self.assertLessEqual(result['bottom'],363)
        self.assertFalse(result['robot']['playing']);self.assertFalse(result['robot']['loop'])
        self.assertEqual(result['robot']['scaleX'],2)
        self.assertTrue(all(b['texture']=='UI_btn_normalFun_0000' for b in result['buttons']))
        self.assertLessEqual(result['buttons'][1]['x']+result['buttons'][1]['width'],248)

    def test_zhuabao_single_and_ten_play_once_then_show_awards(self):
        for num in [1,10]:
            code=self.zhuabao_script()+f"unit.renderZhuabao();unit.requestZhuabao('user.zhuabao_draw',{{num:{num}}});"+r"""
const activity=unit.zhuabaoData;
requests[0].cb({return_code:0,data:{activity,awards:[{name:'培养书×10'}]}});
const robot=unit.zhuabaoRobot;
const before={playing:robot.playing,loop:robot.loop,playCount:robot.playCount,busy:unit.zhuabaoBusy,popups:popups.length};
unit.requestZhuabao('user.zhuabao_draw',{num:10});
unit.onZhuabaoComplete({});unit.onZhuabaoComplete({});
console.log(JSON.stringify({before,requests:requests.length,busy:unit.zhuabaoBusy,idle:!unit.zhuabaoRobot.playing,popups}));
"""
            result=self.run_js(code)
            self.assertEqual(result['before'],dict(playing=True,loop=False,playCount=1,busy=True,popups=0))
            self.assertEqual(result['requests'],1);self.assertFalse(result['busy']);self.assertTrue(result['idle'])
            self.assertEqual(result['popups'],[['抓宝收获','培养书×10']])

    def test_zhuabao_gift_claim_and_preview_are_separate(self):
        code=self.zhuabao_script()+r"""
unit.onZhuabaoAction({currentTarget:{name:'claim100'}});
unit.onZhuabaoAction({currentTarget:{name:'claim10'}});
console.log(JSON.stringify({requests:requests.map(v=>({method:v.method,params:v.params})),popups}));
"""
        result=self.run_js(code)
        self.assertEqual(result['requests'],[dict(method='user.zhuabao_claim',params=dict(tier=10))])
        self.assertIn('橙色盖伦',result['popups'][0][1])

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
