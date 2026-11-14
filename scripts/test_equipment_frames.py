"""Native rarity icons and invisible missing-resource placeholders."""
import json
import shutil
import unittest
from pathlib import Path

from test_avatar_passive import method_body
import test_playtest_client as harness

ROOT=Path(__file__).resolve().parents[1]
STAGES=ROOT/'client/src/stages'


def frame_script():
    """Execute the real equipment frame builder; also supplies preview draw data."""
    source=(STAGES/'084_Equip.as').read_text('utf8')
    script='''const int=Math.trunc,uint=x=>x>>>0;
function Sprite(){this.children=[];this.addChild=x=>{this.children.push(x);x.removeFromParent=()=>this.children.splice(this.children.indexOf(x),1)};this.getChildByName=name=>this.children.find(x=>x.name===name);}
const GlobalFunction={getEquipUI:res=>({res}),createImage:resource=>({resource}),getSympUI:()=>({width:20,height:30})};
const Rectangle=function(x,y,width,height){Object.assign(this,{x,y,width,height})};
const Image=function(texture){this.texture=texture;this.colors=[0xffffff,0xffffff,0xffffff,0xffffff];this.setVertexColor=(i,c)=>this.colors[i]=c};
const Quad=function(width,height,color=0xffffff){Object.assign(this,{quad:true,width,height,colors:[color,color,color,color]});this.setVertexColor=(i,c)=>this.colors[i]=c};
const BitmapData=function(width,height){Object.assign(this,{width,height,pixels:Array(width*height).fill(0)});this.setPixel32=(x,y,c)=>this.pixels[y*width+x]=c};
const Texture={fromTexture:(texture,area)=>({texture,area})};GlobalFunction.getTexture=name=>({name,width:92,height:name.startsWith('EQ_')?93:92});
let cornerTexturesCreated=0,cornerRestores=0;
Texture.fromBitmapData=bitmap=>{cornerTexturesCreated++;return {name:'__equipRainbowCorners104',width:bitmap.width,height:bitmap.height,pixels:bitmap.pixels,root:{uploadBitmapData:()=>cornerRestores++}}};
const cachedTextures={};
const GlobalData={$mConfig_simple:{equip_alchemy:{equip_al:1,star_lv:7}},$assetManager:{getTexture:key=>cachedTextures[key],addTexture:(key,value)=>cachedTextures[key]=value}};
const unit={symp:-1};
'''
    methods={'getStar':'','getAddStar':'','getProStar':'','getAlchemyColor104':'',
             'getAdvancedFrame104':'','getStep':'','addRainbowFrame104':'frame',
             'addAlchemyCorners104':'frame,phase,height','getRes':'param1=null,param2=1'}
    for name,args in methods.items():
        body=method_body(source,name).replace('for each(var area in areas)','for(var area of areas)')
        body=body.replace('for each(var piece in pieces)','for(var piece of pieces)')
        body=body.replace('function(event:Event)','function(event)')
        script+='unit.'+name+'=function('+args+'){with(this){'+body+'}};\n'
    script += """
let atlasBuilds=0;
unit.getRainbowFrameTextures105=function(){
 if(!this.cachedFrames){atlasBuilds++;this.cachedFrames=Array.from({length:48},(_,i)=>({width:92,height:93,index:i}));}
 return this.cachedFrames;
};
const Starling={juggler:{active:new Set(),add(x){this.active.add(x)},remove(x){this.active.delete(x)}}};
function MovieClip(frames,fps){Object.assign(this,{movieClip:true,frames,fps,listeners:{}});this.addEventListener=(name,fn)=>this.listeners[name]=fn;}
"""
    return script


@unittest.skipUnless(shutil.which('node'), 'Node is required for the AS behavior harness')
class EquipmentFrameTests(unittest.TestCase):
    def test_high_star_phase_mapping_preserves_artwork_scale_and_badges(self):
        script=frame_script()
        script+='''let checked=0;
for(const threshold of [1,6])for(const base of [1,3,4,5,6])for(const star of [7,8])for(const phase of [0,1,2]){
GlobalData.$mConfig_simple.equip_alchemy.equip_al=threshold;
unit.equipData={id:`E_1001_${base}`,res:`EQ_1001_${base}`};unit.my_data={alchemy:[phase,star-base]};
const icon=unit.getRes(null,.5),frame=icon.children.find(x=>x.name==='alchemyFrame104');
if(!frame)throw Error('missing frame');
if(unit.getAlchemyColor104()!==(star===7?0xFF586B:0xE6BDFF))throw Error('wrong alchemy text color');
const parts=1;
if(frame.children.length!==parts+(star===7&&phase>0?4:0))throw Error('wrong phase ornaments');
if(star===7&&frame.children[0].resource!=='UI_equip_box_0005')throw Error('seven must be red');
if(star===8){
 const clip=frame.children[0];
 if(!clip.movieClip||clip.frames.length!==48||clip.fps!==20||!clip.loop)throw Error('shared animated frame missing');
 if(clip.frames.some(t=>t.width!==92||t.height!==93))throw Error('frame footprint changed');
 clip.listeners.addedToStage();if(!Starling.juggler.active.has(clip))throw Error('animation did not start');
 clip.listeners.removedFromStage();if(Starling.juggler.active.has(clip))throw Error('offstage animation leaked');
 clip.listeners.addedToStage();clip.listeners.removedFromStage();

}
if(star===7&&phase>0&&frame.children.slice(-4).some(x=>x.texture.texture.name!==`UI_equip_box_000${phase===1?3:4}`))throw Error('wrong corner stage');
if(star===8&&unit.getStep()!==-1)throw Error('eight-star progress shown');
if(frame.scaleX!==.5||frame.scaleY!==.5||icon.children[0].res!==unit.equipData.res)throw Error('icon or scale changed');
checked++;}
if(atlasBuilds!==1)throw Error('frame textures not shared');
unit.equipData={id:'E_1001_4',res:'EQ_1001_4'};
for(const extra of [1,2]){
 unit.my_data={alchemy:[0,extra]};const icon=unit.getRes(),frame=icon.children.find(x=>x.name==='alchemyFrame104');
 if(icon.children[0].res!=='EQ_1001_4'||frame.children[0].texture.texture.name!==`EQ_1001_${4+extra}0000`)throw Error('blue to purple/orange failed');
}
unit.equipData={id:'E_1001_6',res:'EQ_1001_6'};unit.my_data={alchemy:[0,2]};
unit.symp=0;const result=unit.getRes();if(result.children.at(-1).name!=='sympClip')throw Error('rune hidden');
unit.my_data={alchemy:[0,7-6]};unit.getRes(result);if(result.children.filter(x=>x.name==='alchemyFrame104').length!==1)throw Error('stale frame');
unit.my_data={alchemy:[0,0]};unit.getRes(result);if(result.children.some(x=>x.name==='alchemyFrame104'))throw Error('stale advanced frame');
console.log(JSON.stringify({checked}));'''
        self.assertEqual(harness.PlaytestClientTests.run_js(self,script),{'checked':60})

    def test_native_icons_are_preserved_and_only_advanced_stars_gain_overlay(self):
        cfg=json.loads((ROOT/'config/reconstruction/full-config.json').read_text('utf8'))['cfg']['equip']
        script=frame_script()
        script+="const rows=JSON.parse(require('fs').readFileSync(0,'utf8')).rows;let checked=0;\n"
        script+='''for(const [id,row] of Object.entries(rows))for(const alchemy of [null,[0,0],[1,0],[2,1]]){
unit.equipData=row;unit.my_data={eid:id,alchemy};
const icon=unit.getRes();
if(icon.children.length!==(unit.getStar()>=7||unit.getStar()>unit.getProStar()?2:1)||icon.children[0].res!==row.res)throw Error(id);
const advanced=icon.children.find(x=>x.name==='alchemyFrame104');
if(advanced&&unit.getStar()<7){
 if(advanced.children.length!==8)throw Error('border pieces');
 for(const piece of advanced.children){const a=piece.texture.area;
  if(piece.texture.texture.name!==`EQ_1001_${unit.getStar()}0000`)throw Error('wrong quality');
  if(a.x<84&&a.x+a.width>8&&a.y<85&&a.y+a.height>8)throw Error('equipment artwork covered');
 }
}
checked++;}
unit.symp=0;const scaled=unit.getRes(null,0.5);
console.log(JSON.stringify({checked,badge:scaled.children.find(x=>x.name==='sympClip').name,scale:scaled.children[0].scaleX}));'''
        result=harness.PlaytestClientTests.run_js(self,script,{'rows':cfg})
        self.assertEqual(result,{'checked':len(cfg)*4,'badge':'sympClip','scale':0.5})

    def test_alchemy_preview_crosses_star_boundaries_using_same_frame_builder(self):
        source=(STAGES/'061_PanelEquipAlchemyStart.as').read_text('utf8')
        script=frame_script()+'''const Tools={clone:x=>JSON.parse(JSON.stringify(x))};\n'''
        script+='const nextEquip=function(param1){'+method_body(source,'nextEquip')+'};\n'
        script+='''let checked=0;GlobalData.$mConfig_simple.equip_alchemy.star_lv=8;
for(const base of [1,4,6])for(const star of [6,7]){
 unit.equipData={id:`E_1001_${base}`,res:`EQ_1001_${base}`};
 const current={alchemy:[2,star-base]},next=nextEquip(current);
 if(current.alchemy[0]!==2||current.alchemy[1]!==star-base)throw Error('preview mutated actual state');
 unit.my_data=next;const frame=unit.getRes().children[1];
 if(unit.getStar()!==star+1||next.alchemy[0]!==0)throw Error('phase carry');
 if(star===6&&frame.children[0].resource!=='UI_equip_box_0005')throw Error('six to seven not red');
 if(star===7&&(frame.children.length!==1||!frame.children[0].movieClip))throw Error('seven to eight not rainbow');
 checked++;
}
console.log(JSON.stringify({checked}));'''
        self.assertEqual(harness.PlaytestClientTests.run_js(self,script),{'checked':6})
        for file in ('058_ItemEquipSelect.as','061_PanelEquipAlchemyStart.as','065_PanelEquipChange.as'):
            text=(STAGES/file).read_text('utf8')
            self.assertIn('.getAlchemyColor104()',text)
            self.assertNotIn('getStar() - _loc8_',text)
            self.assertNotIn('getStar() - _loc3_',text)

    def test_terminal_eight_star_has_no_next_preview_progress_or_request(self):
        source=(STAGES/'061_PanelEquipAlchemyStart.as').read_text('utf8')
        script=frame_script()+'''const Tools={clone:x=>JSON.parse(JSON.stringify(x))};
const gate={};let sent=0;const SendServiceAMFFun={send_user_equip_alchemy:()=>sent++};\n'''
        for name,args in [('nextEquip','param1'),('checkContinueAlchemy','param1'),('send_msg','')]:
            script+='gate.'+name+'=function('+args+'){with(this){'+method_body(source,name)+'}};\n'
        script+='''let checked=0;
for(const cap of [7,8,9])for(const phase of [0,1,2]){
 GlobalData.$mConfig_simple.equip_alchemy.star_lv=cap;
 const current={eid:'E_1001_6',alchemy:[phase,2]},next=gate.nextEquip(current);
 if(next.alchemy[0]!==0||next.alchemy[1]!==2||current.alchemy[0]!==phase)throw Error('terminal preview changed progress or source');
 if(gate.checkContinueAlchemy(current))throw Error('terminal alchemy allowed');
 unit.equipData={id:current.eid};unit.my_data=current;
 if(unit.getStep()!==-1)throw Error('terminal phase label');
 gate.m_data=current;gate.send_msg();checked++;
}
if(sent!==0)throw Error('terminal alchemy request sent');
GlobalData.$mConfig_simple.equip_alchemy.star_lv=7;
const capped={eid:'E_1001_6',alchemy:[0,1]};
if(gate.nextEquip(capped).alchemy[0]!==0||gate.checkContinueAlchemy(capped))throw Error('existing lower cap ignored');
if(!gate.checkContinueAlchemy({eid:'E_1001_6'}))throw Error('legacy equipment without alchemy blocked');
console.log(JSON.stringify({checked,sent}));'''
        self.assertEqual(harness.PlaytestClientTests.run_js(self,script),{'checked':9,'sent':0})

    def test_missing_resources_are_transparent_cached_and_keep_size(self):
        source=(STAGES/'045_GlobalFunction.as').read_text('utf8').replace('flash.display.Sprite','Sprite').replace('catch(_error:Error)','catch(_error)')
        script='''const originalGuide={width:72,height:72,frame:{width:96,height:96}};
const assets={guideClick0000:originalGuide};let created=0;
const GlobalData={resolveModTexture:key=>key,$assetManager:{getTexture:key=>assets[key]||null,addTexture:(key,value)=>assets[key]=value}};
const TEXTURE_DEFAULT='guideClick0000';
const Texture={fromColor:(width,height,color)=>{created++;return {width,height,color};}};
const getDefinitionByName=()=>{throw Error('missing');};
const unit={$getTextureList:[]};
'''
        for name,params in [('getMissingTexture',''),('getTextureByBD','param1'),('getTexture','param1,param2=null')]:
            script+='unit.'+name+'=function('+params+'){with(this){'+method_body(source,name)+'}};\n'
        script+='''const a=unit.getTexture('missing-frame');const b=unit.getTextureByBD('missing-bitmap');
const guide=unit.getTexture('guideClick0000');
console.log(JSON.stringify({same:a===b,created,width:a.width,height:a.height,color:a.color,guidePreserved:guide===originalGuide}));'''
        self.assertEqual(harness.PlaytestClientTests.run_js(self,script),
                         {'same':True,'created':1,'width':96,'height':96,'color':0,'guidePreserved':True})

    def test_missing_reference_still_returns_a_transparent_texture(self):
        source=(STAGES/'045_GlobalFunction.as').read_text('utf8')
        script='''const GlobalData={$assetManager:{getTexture:()=>null,addTexture:()=>{}}};
const TEXTURE_DEFAULT='guideClick0000';const Texture={fromColor:(width,height,color)=>({width,height,color})};
const unit={};'''
        script+='unit.getMissingTexture=function(){with(this){'+method_body(source,'getMissingTexture')+'}};'
        script+='console.log(JSON.stringify(unit.getMissingTexture()));'
        self.assertEqual(harness.PlaytestClientTests.run_js(self,script),{'width':2,'height':2,'color':0})


if __name__=='__main__':
    unittest.main()
