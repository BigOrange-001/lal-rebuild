"""Check generated icon pixels, shared uploads and context restoration."""
import hashlib
import json
from pathlib import Path
import unittest
from PIL import Image
from test_avatar_passive import method_body
import test_playtest_client as client_harness

ROOT = Path(__file__).resolve().parents[1]


class StardustIconTests(unittest.TestCase):
    def test_embedded_pixels_match_png_and_shared_texture_survives_context_loss(self):
        art = ROOT / 'client/resources/currency'
        image = Image.open(art / 'stardust-52x50.png').convert('RGBA')
        self.assertEqual(image.size, (52, 50))
        self.assertEqual(image.getpixel((0, 0))[3], 0)
        self.assertGreater(image.getchannel('A').getextrema()[1], 250)
        rgba = image.tobytes()
        argb = bytearray(len(rgba))
        for channel, original in enumerate((3, 0, 1, 2)):
            argb[channel::4] = rgba[original::4]
        expected = hashlib.sha256(argb).hexdigest()
        source = (ROOT / 'client/src/stages/084_Equip.as').read_text('utf8')
        body = method_body(source, 'createStardustIcon')
        script = '''const assert=require('assert'),zlib=require('zlib'),crypto=require('crypto');
let uploads=0,restores=0,digest;
function ByteArray(){this.values=[];this.writeByte=x=>this.values.push(x&255);this.uncompress=()=>{this.raw=zlib.inflateSync(Buffer.from(this.values));};this.clear=()=>{this.values=[];this.raw=null;};}
function Rectangle(x,y,width,height){Object.assign(this,{x,y,width,height});}
function BitmapData(width,height){Object.assign(this,{width,height});this.setPixels=(area,bytes)=>{assert.equal(bytes.raw.length,width*height*4);digest=crypto.createHash('sha256').update(bytes.raw).digest('hex');};}
const cache={},GlobalData={$assetManager:{getTexture:key=>cache[key],addTexture:(key,value)=>cache[key]=value}};
const Texture={fromBitmapData:bitmap=>{uploads++;return {bitmap,root:{uploadBitmapData:b=>{assert.equal(b,bitmap);restores++;}}};}};
function Image(texture){this.texture=texture;this.dispose=()=>{this.texture=null;};}
const create=function(){'''+body+'''};
const sell=create(),alchemy=create();
assert.notEqual(sell,alchemy);assert.equal(sell.texture,alchemy.texture);
assert.equal(sell.scaleX,.6);assert.equal(sell.scaleY,.6);assert.equal(sell.touchable,false);
sell.dispose();cache.__stardustIcon105.root.onRestore();
assert.equal(create().texture,alchemy.texture);assert.equal(uploads,1);assert.equal(restores,1);
console.log(JSON.stringify({digest,uploads,restores}));'''
        result = client_harness.PlaytestClientTests.run_js(self, script)
        self.assertEqual(result, dict(digest=expected, uploads=1, restores=1))


if __name__ == '__main__':
    unittest.main()
