"""Exercise the actual embedded atlas decoder, cache and texture restoration."""
import hashlib
import json
import re
import unittest
import zlib
from pathlib import Path
import test_playtest_client as client_harness

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT/'client/src/stages/084_Equip.as'


class RainbowAtlasTests(unittest.TestCase):
    def test_actual_atlas_pixels_keep_center_clear_and_have_48_animation_frames(self):
        source = SOURCE.read_text('utf8')
        block = source.split('var encoded:String = [',1)[1].split('].join',1)[0]
        raw = zlib.decompress(bytes.fromhex(''.join(re.findall(r'"([0-9a-f]+)"',block))))
        meta = json.loads((ROOT/'client/resources/equipment/rainbow-frame-105.json').read_text('utf8'))
        self.assertEqual(hashlib.sha256(raw).hexdigest(),meta['raw_sha256'])
        self.assertEqual(len(raw),1024*512*4)
        hashes = set()
        for frame in range(48):
            x,y = (frame%10)*96+2,(frame//10)*97+2
            rows = [raw[((y+dy)*1024+x)*4:((y+dy)*1024+x+92)*4] for dy in range(93)]
            hashes.add(hashlib.sha256(b''.join(rows)).digest())
            for row in rows[14:-14]:
                self.assertFalse(any(row[14*4:(92-14)*4:4]),'opaque center hides the equipment')
            self.assertGreater(sum(rows[1][::4]),92*200)
            # All sides have a two-pixel transparent gutter to avoid atlas bleed.
            self.assertEqual(raw[((y-1)*1024+x)*4:((y-1)*1024+x+92)*4],bytes(92*4))
        self.assertEqual(len(hashes),48)

    def test_actual_decoder_shares_upload_and_restores_texture(self):
        source = SOURCE.read_text('utf8')
        start = source.index('private function getRainbowFrameTextures105(')
        start = source.index('{',start)+1
        end = source.index('      // END GENERATED RAINBOW ATLAS 105',start)
        body = source[start:end].rsplit('}',1)[0]
        body = re.sub(r'\bvar (\w+)\s*:(?:Vector\.<Texture>|\w+)',r'var \1',body)
        body = body.replace('new Vector.<Texture>()','[]').replace('function():void','function()')
        script = '''const assert=require('assert'),zlib=require('zlib'),crypto=require('crypto');
const int=Math.trunc;let uploads=0,restores=0,digest;
function ByteArray(){this.values=[];this.writeByte=x=>this.values.push(x&255);this.uncompress=()=>{this.raw=zlib.inflateSync(Buffer.from(this.values))};this.clear=()=>{this.values=[];this.raw=null};}
function Rectangle(x,y,width,height){Object.assign(this,{x,y,width,height});}
function BitmapData(width,height){Object.assign(this,{width,height});this.setPixels=(area,bytes)=>{assert.equal(bytes.raw.length,width*height*4);digest=crypto.createHash('sha256').update(bytes.raw).digest('hex');};}
const cache={},GlobalData={$assetManager:{getTexture:key=>cache[key],addTexture:(key,value)=>cache[key]=value}};
const Texture={fromBitmapData:bitmap=>{uploads++;return {bitmap,root:{uploadBitmapData:b=>{assert.equal(b,bitmap);restores++;}}}},fromTexture:(atlas,area)=>({atlas,area})};
const decode=function(){'''+body+'''};
const first=decode(),second=decode();assert.equal(uploads,1);assert.equal(first.length,48);
for(let i=0;i<48;i++){
 assert.equal(first[i].atlas,second[i].atlas);
 assert.deepEqual(first[i].area,new Rectangle((i%10)*96+2,Math.trunc(i/10)*97+2,92,93));
}
cache.__equipRainbowAtlas105.root.onRestore();assert.equal(restores,1);
console.log(JSON.stringify({uploads,restores,digest}));'''
        meta = json.loads((ROOT/'client/resources/equipment/rainbow-frame-105.json').read_text('utf8'))
        result = client_harness.PlaytestClientTests.run_js(self,script)
        self.assertEqual(result,dict(uploads=1,restores=1,digest=meta['raw_sha256']))


if __name__=='__main__':
    unittest.main()
