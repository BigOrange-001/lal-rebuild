"""Native rarity icons and invisible missing-resource placeholders."""
import json
import shutil
import unittest
from pathlib import Path

from test_avatar_passive import method_body
import test_playtest_client as harness

ROOT=Path(__file__).resolve().parents[1]
STAGES=ROOT/'client/src/stages'


@unittest.skipUnless(shutil.which('node'), 'Node is required for the AS behavior harness')
class EquipmentFrameTests(unittest.TestCase):
    def test_alchemy_does_not_cover_native_rarity_border(self):
        cfg=json.loads((ROOT/'config/reconstruction/full-config.json').read_text('utf8'))['cfg']['equip']
        body=method_body((STAGES/'084_Equip.as').read_text('utf8'),'getRes')
        script='''const int=Math.trunc;
function Sprite(){this.children=[];this.addChild=x=>this.children.push(x);}
const GlobalFunction={getEquipUI:res=>({res}),getSympUI:()=>({width:20,height:30})};
const unit={symp:-1};
'''
        script+='unit.getRes=function(param1=null,param2=1){with(this){'+body+'}};\n'
        script+="const rows=JSON.parse(require('fs').readFileSync(0,'utf8')).rows;let checked=0;\n"
        script+='''for(const [id,row] of Object.entries(rows))for(const alchemy of [null,[0,0],[1,0],[2,1]]){
unit.equipData=row;unit.my_data={eid:id,alchemy};
const icon=unit.getRes();
if(icon.children.length!==1||icon.children[0].res!==row.res)throw Error(id);
checked++;}
unit.symp=0;const scaled=unit.getRes(null,0.5);
console.log(JSON.stringify({checked,badge:scaled.children[1].name,scale:scaled.children[0].scaleX}));'''
        result=harness.PlaytestClientTests.run_js(self,script,{'rows':cfg})
        self.assertEqual(result,{'checked':len(cfg)*4,'badge':'sympClip','scale':0.5})

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
