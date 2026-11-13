"""Verify native buff dimensions and the real AS contact/presentation methods."""
import json
from pathlib import Path
import re
import subprocess
import sys
import unittest
import xml.etree.ElementTree as ET
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from test_skin_revision_native_104 import balanced


def method(source,name):
    start=source.index('function '+name+'(')
    start=source.index('{',start)
    body=source[start+1:balanced(source,start)]
    body=re.sub(r'\bvar (\w+)\s*:[\w.<>]+',r'var \1',body)
    body=re.sub(r'\s+as\s+\w+','',body)
    while 'for each(' in body:
        a=body.index('for each(');b=balanced(body,a+8)
        left,right=body[a+9:b].split(' in ',1)
        body=body[:a]+'for ('+left+' of Object.values('+right+'))'+body[b+1:]
    return body


class YasuoEffectTests(unittest.TestCase):
    def test_transparent_frames_and_original_buff_size(self):
        media=ROOT/'config/reconstruction/nightbringer-yasuo-media'
        manifest=json.loads((media/'manifest.json').read_text('utf8'))
        layout=manifest['buffLayout']
        atlas=ET.fromstring((ROOT.parents[1]/'analysis/embedded/11_texture_xml.bin').read_bytes())
        native=next(t for t in atlas if t.get('name')=='Symbol 39')
        self.assertEqual((layout['width'],layout['height']),(int(native.get('height')),int(native.get('width'))))
        self.assertEqual(layout['runtimeScale'],1)
        self.assertEqual(len(layout['slots']),12)
        self.assertTrue(all(s['scaleY']==.69 and abs(s['scaleX'])==1 for s in layout['slots']))
        for kind,size in (('vortex',(256,256)),('buff',(layout['width'],layout['height']))):
            for index in range(4):
                with Image.open(media/f'effects/night_{kind}_{index}.png') as image:
                    self.assertEqual(image.size,size)
                    self.assertEqual(image.mode,'RGBA')
                    self.assertEqual(image.getchannel('A').getextrema(),(0,255))

    def test_buff_uses_original_layer_coordinates_and_scales(self):
        source=(ROOT/'client/src/nightbringer_yasuo_effects.aspart').read_text('utf8')
        layout=json.loads((ROOT/'config/reconstruction/nightbringer-yasuo-media/manifest.json').read_text('utf8'))['buffLayout']
        script='''const assert=require('assert');const int=Math.trunc;
class Sprite{constructor(){this.children=[]}addChild(x){x.parent=this;this.children.push(x)}removeFromParent(){if(this.parent)this.parent.children=this.parent.children.filter(x=>x!==this);this.parent=null}}
class Image extends Sprite{constructor(texture){super();this.texture=texture}}
const GameMapLayer={isFastest:false};
const GlobalData={$mConfig_avatar:{yasuo:{nightBuffLayout104:LAYOUT}},$assetManager:{getTexture:()=>({width:57,height:79})}};
let owner={hp:100,yasuoNightShown104:true,yasuoNightVisual104:null,yasuoNightParts104:[],yasuoNightAge104:0,m_buff:new Sprite(),avatarData:{id:'yasuo'}};
function update(elapsed){with(this){BODY}}
update.call(owner,0);
assert.equal(owner.yasuoNightVisual104.parent,owner.m_buff);
assert.equal(owner.yasuoNightParts104.length,12);
for(let i=0;i<12;i++){let p=owner.yasuoNightParts104[i],s=LAYOUT.slots[i];assert.equal(p.x,s.x);assert.equal(p.y,s.y);assert.equal(p.scaleX,s.scaleX);assert.equal(p.scaleY,s.scaleY*s.keys[0].stretch)}
update.call(owner,.035);assert(owner.yasuoNightParts104.some((p,i)=>p.y!==LAYOUT.slots[i].y));
GameMapLayer.isFastest=true;update.call(owner,.01);assert.equal(owner.yasuoNightVisual104,null);
console.log('Native buff placement, scales, layer and fast-mode cleanup passed');
'''.replace('LAYOUT',json.dumps(layout)).replace('BODY',method(source,'yasuoUpdateNight104'))
        # Keep repeated references readable instead of emitting an object literal
        # as a property-access expression in the loop's assertions.
        result=subprocess.run(['node'],input=script,text=True,encoding='utf8',capture_output=True)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)

    def test_native_contact_has_no_extra_windup_or_redundant_projectile(self):
        source=(ROOT/'client/src/stages/137_Avatar.as').read_text('utf8')
        body=method(source,'attackAimList')
        start=body.index('if(_loc41_.nativeContact104===true)')
        opening=body.index('{',start)
        contact=body[start:balanced(body,opening)+1]
        self.assertNotIn('actionDelay',contact)
        self.assertNotIn('addBullet',contact)
        self.assertLess(source.index('if(_loc41_.nativeContact104===true)'),source.index('         GameMap.actionDelay += 0.3;',source.index('function attackAimList(')))
        script='''const assert=require('assert');let calls=[];
function countDamage(a,b,raw,kind,share){calls.push('damage');return [raw*share,false]}
function checkCrit(){calls.push('crit');return 2}
function checkMiss(a,t){calls.push('miss');return t.dodged}
let hit={hp:1000,injured:(raw,crit)=>raw*crit},miss={hp:1000,dodged:true,injured:()=>{throw Error('dodge must not take damage')}};
function resolve(param1){let _loc41_={nativeContact104:true},_loc42_=true,_loc25_={},_loc14_=100,param2=1,param9=1,param7=null,_loc46_,_loc20_,_loc21_=0;CONTACT}
assert.equal(resolve([hit,miss]),200);assert.deepEqual(calls,['miss','damage','crit','miss']);
'''.replace('CONTACT',contact)
        result=subprocess.run(['node'],input=script,text=True,encoding='utf8',capture_output=True)
        self.assertEqual(result.returncode,0,result.stdout+result.stderr)


if __name__=='__main__':unittest.main()
