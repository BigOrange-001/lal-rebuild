"""Validate all 20 icon IDs, atlas pixels, shared upload and context restore."""
import hashlib
import json
import re
import subprocess
import unittest
import zlib
from pathlib import Path
from PIL import Image
from test_avatar_passive import method_body

ROOT=Path(__file__).resolve().parents[1]


class RelicArtTests(unittest.TestCase):
    def test_sources_match_atlas_and_all_20_ids(self):
        folder=ROOT/'client/resources/abyss-relics'
        metadata=json.loads((folder/'manifest.json').read_text('utf-8'))
        self.assertEqual([r['relic_id'] for r in metadata['icons']],list(range(1,21)))
        for row in metadata['icons']:
            self.assertEqual(hashlib.sha256((folder/row['file']).read_bytes()).hexdigest(),row['sha256'])
        source=(ROOT/'client/src/abyss_relic_art_104.aspart').read_text('utf-8')
        encoded=source.split('var encoded:String = [',1)[1].split('].join',1)[0]
        raw=zlib.decompress(bytes.fromhex(''.join(re.findall(r'"([0-9a-f]+)"',encoded))))
        self.assertEqual(hashlib.sha256(raw).hexdigest(),metadata['argb_sha256'])
        rgba=bytearray(len(raw))
        for destination,offset in enumerate((1,2,3,0)):rgba[destination::4]=raw[offset::4]
        atlas=Image.open(folder/'atlas.png').convert('RGBA')
        self.assertEqual(bytes(rgba),atlas.tobytes())
        for row in metadata['icons']:
            x,y,w,h=row['region'];region=atlas.crop((x,y,x+w,y+h))
            bounds=region.getbbox();self.assertIsNotNone(bounds)
            self.assertGreaterEqual(bounds[0],8);self.assertGreaterEqual(bounds[1],8)
            self.assertLessEqual(bounds[2],w-8);self.assertLessEqual(bounds[3],h-8)

    def test_native_factory_and_one_context_restorable_texture(self):
        source=(ROOT/'client/src/abyss_relic_art_104.aspart').read_text('utf-8')
        def translate(name,params):
            body=method_body(source,name).replace('function():void','function()')
            return 'function('+params+'){'+body+'}'
        script='''const assert=require('node:assert/strict'),zlib=require('node:zlib');
const int=Math.trunc;let uploads=0,restores=0,frames=0;const cache={};
function Sprite(){this.children=[];this.addChild=c=>this.children.push(c);}
function Quad(w,h,c){Object.assign(this,{w,h,c});}
function Image(t){this.texture=t;}
function Rectangle(x,y,width,height){Object.assign(this,{x,y,width,height});}
function ByteArray(){this.values=[];this.writeByte=v=>this.values.push(v&255);this.uncompress=()=>this.raw=zlib.inflateSync(Buffer.from(this.values));this.clear=()=>{};}
function BitmapData(width,height){this.setPixels=(r,bytes)=>assert.equal(bytes.raw.length,width*height*4);}
const Texture={fromBitmapData:bitmap=>{uploads++;return {root:{uploadBitmapData:b=>{assert.equal(b,bitmap);restores++;}}};},fromTexture:(atlas,region)=>({atlas,region})};
const Equip={createRainbowFrame104:()=>{frames++;return {nativeRainbow:true};}};
const GlobalData={$assetManager:{getTexture:key=>cache[key],addTexture:(key,t)=>cache[key]=t}};
'''
        script+='const atlas='+translate('atlas','')+';\nconst create='+translate('create','item,size=92')+';\n'
        script+='''for(let id=1;id<=20;id++){
const icon=create({relic_id:id},100);assert.equal(icon.children.length,3);
assert(icon.children[2].nativeRainbow);assert.equal(icon.children[1].texture.region.x,((id-1)%5)*100);
assert.equal(icon.children[1].texture.region.y,Math.trunc((id-1)/5)*100);
assert.equal(icon.scaleX,100/92);}
assert.equal(uploads,1);assert.equal(frames,20);cache.__abyssRelicAtlas104.root.onRestore();assert.equal(restores,1);
console.log('20 IDs share one icon texture, preserve native rainbow factory and restore GPU context.');'''
        result=subprocess.run(['node'],input=script,capture_output=True,text=True,encoding='utf-8',cwd=ROOT)
        self.assertEqual(result.returncode,0,result.stdout+'\n'+result.stderr)


if __name__=='__main__':unittest.main()
