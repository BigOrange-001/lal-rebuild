"""Run the real registration layering and battle HUD methods at UI boundaries."""
import unittest
import shutil
import json
import re
from pathlib import Path
import test_playtest_client as harness
from test_playtest_client import function
from test_avatar_passive import method_body

@unittest.skipUnless(shutil.which('node'),'Node required for actual AS control flow')
class UILayers103Tests(unittest.TestCase):
    run_js=harness.PlaytestClientTests.run_js

    def test_final_hud_keeps_all_other_existing_methods(self):
        stages=Path(__file__).resolve().parents[1]/'client/src/stages'
        previous=(stages/'016_UiLayer.as').read_text('utf-8')
        current=(stages/'163_UiLayer.as').read_text('utf-8')
        names=re.findall(r'function\s+(\w+)\(',previous)
        for name in set(names)-{'UiLayer','addRound','refreashRound','clear'}:
            with self.subTest(method=name):
                self.assertEqual(method_body(previous,name),method_body(current,name))

    def test_dropdown_stays_above_siblings_and_native_inputs_until_closed(self):
        script=r'''
let removed=[],tweens=[];
const Starling={juggler:{removeTweens:v=>removed.push(v),add:v=>tweens.push(v)}};
function Tween(target){this.target=target;this.fadeTo=()=>{};}
function Point(x,y){this.x=x;this.y=y;}
const backdrop={};
const unit={stage:{},mTierMenu:{visible:false,getChildAt:()=>backdrop,globalToLocal:()=>({x:-20,y:-350})},mBox:{x:20,y:170},numChildren:12,
 mNT_id:{visible:true},mNT_pass:{visible:true},setChildIndex:(obj,index)=>unit.top=index};
'''
        for method,params in [('openTierMenu','event'),('closeTierMenu',''),('btn_CloseEvent','')]:
            script+=function('150_PanelLogin.as',method,params).replace('mTierMenu.getChildAt(0) as Quad','mTierMenu.getChildAt(0)')
        script+=r'''
unit.openTierMenu({});unit.btn_CloseEvent();
const opened={top:unit.top,native:unit.mNT_id.visible||unit.mNT_pass.visible,menu:unit.mTierMenu.visible,backdrop};
unit.closeTierMenu();
console.log(JSON.stringify({opened,closed:{native:unit.mNT_id.visible&&unit.mNT_pass.visible,menu:unit.mTierMenu.visible},tweens:tweens.length}));
'''
        self.assertEqual(self.run_js(script),{'opened':{'top':11,'native':False,'menu':True,'backdrop':{'x':-20,'y':-350}},'closed':{'native':True,'menu':False},'tweens':1})

    def test_round_label_has_one_line_and_never_scales_or_moves_on_update(self):
        script=r'''
const MainConfig={$isEnglish:false},GameMap={ROUND_MAX:40},GlobalConfig={FONT_0:'font'},SHADOW_ALPHA=.6;
const GameMapLayer={gl:{juggler:{removeTweens:()=>{}},addTween:()=>{}}};
function TextField(width,height,text,font,size,color){Object.assign(this,{width,height,text,color,x:0,y:0});}
function Tween(target){this.fadeTo=v=>target.alpha=v;}
const children=[],unit={m_roundTF:null,m_roundTF2:null,m_sprFg:{addChild:v=>children.push(v)}};
'''+function('163_UiLayer.as','addRound')+function('163_UiLayer.as','refreashRound','param1')+r'''
const rows=[];for(const n of [1,9,10,39,40]){unit.refreashRound(n);rows.push({...unit.m_roundTF});}
console.log(JSON.stringify({rows,children:children.length,shadow:unit.m_roundTF2.text}));
'''
        result=self.run_js(script)
        self.assertEqual(result['children'],2)
        self.assertEqual(result['shadow'],'回合 40 / 40')
        for row,n in zip(result['rows'],[1,9,10,39,40]):
            self.assertEqual(row['text'],f'回合 {n} / 40')
            self.assertEqual((row['x'],row['y'],row['width'],row['height']),(14,44,194,34))
            self.assertNotIn('scaleX',row)
        self.assertEqual(result['rows'][-1]['color'],16711680)

    def test_native_inputs_follow_viewport_and_social_refresh_disposes_old_input(self):
        social=function('164_PanelSocialSearch.as','setInputText')
        source=(Path(__file__).resolve().parents[1]/'client/src/stages/165_PanelGuildReleaseInfo.as').read_text('utf-8')
        body=method_body(source,'setUI')
        body=body[body.index('var inputBounds'):body.index('GlobalData.$mStarling.nativeStage.addChild(this.nt);')]
        body=body.replace('var inputBounds:Rectangle','var inputBounds').replace('var scaleX:Number','var scaleX').replace('var scaleY:Number','var scaleY')
        script=r'''
const int=Math.trunc,GlobalConfig={FONT_1:'font'};
let removed=0;
const GlobalData={$mStageWidth:640,$mStageHeight:1138,$mStage$Starling_h:1,$mStarling:{nativeStage:{addChild:()=>{}}}};
const Starling={current:{viewPort:{}}};
function NativeText(){};function Point(x,y){this.x=x;this.y=y;}
const unit={nt:{parent:{removeChild:()=>removed++}},mBox:{localToGlobal:p=>({x:p.x+66,y:p.y+200})},m9x9_txt:{x:78,y:92,width:352,height:46}};
'''+social+r'''
unit.placeGuild=function(){with(this){const bottom_bg={getBounds:()=>({x:90,y:450,width:460,height:140})},stage={},view=Starling.current.viewPort;
'''+body+r'''
}};
const result=[];
for(const view of [{x:0,y:15,width:720,height:1280},{x:530,y:0,width:607,height:1080},{x:20,y:80,width:1040,height:1849.25}]){
 Starling.current.viewPort=view;GlobalData.$mStage$Starling_h=view.height/1138;
 unit.setInputText();const social={...unit.nt};unit.placeGuild();
 result.push({view,social,guild:{...unit.nt}});
}
console.log(JSON.stringify({removed,result}));
'''
        result=self.run_js(script)
        self.assertEqual(result['removed'],1)
        for row in result['result']:
            view=row['view'];sx=view['width']/640;sy=view['height']/1138
            for kind,logical in [('social',(152,298,336)),('guild',(100,454,440))]:
                placed=row[kind]
                self.assertEqual(placed['x'],int(view['x']+logical[0]*sx))
                self.assertEqual(placed['y'],int(view['y']+logical[1]*sy))
                self.assertEqual(placed['width'],int(logical[2]*sx))

if __name__=='__main__':unittest.main()
