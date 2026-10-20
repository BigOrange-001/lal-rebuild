"""Run notice's actual coordinate conversion through viewport/parent transforms."""
import json
import shutil
import unittest
from pathlib import Path

from test_avatar_passive import method_body
import test_playtest_client as harness

SOURCE = Path(__file__).resolve().parents[1] / 'client/src/stages/161_PanelHelpNotice.as'


@unittest.skipUnless(shutil.which('node'), 'Node is required for AS behavior checks')
class NoticeViewportTests(unittest.TestCase):
    run_js = harness.PlaytestClientTests.run_js

    def test_content_rect_tracks_letterbox_safe_area_and_parent_scale(self):
        body = method_body(SOURCE.read_text('utf8'), 'nativeNoticeRect')
        script = '''class Point{constructor(x,y){Object.assign(this,{x,y});}}
class Rectangle{constructor(x,y,width,height){Object.assign(this,{x,y,width,height});}
get right(){return this.x+this.width;}get bottom(){return this.y+this.height;}
intersection(b){let x=Math.max(this.x,b.x),y=Math.max(this.y,b.y),right=Math.min(this.right,b.right),bottom=Math.min(this.bottom,b.bottom);
return new Rectangle(x,y,Math.max(0,right-x),Math.max(0,bottom-y));}}
const GlobalData={$mStarling:{stage:{stageWidth:640,stageHeight:1138}}};
let unit={};unit.convert=function(anchor,area){BODY};let rows=[];
for(let viewport of [new Rectangle(0,0,640,1138),new Rectangle(0,240,1080,1920),new Rectangle(80,40,900,1600)]){
GlobalData.$mStarling.viewPort=viewport;let anchor={localToGlobal:p=>new Point(20+p.x*.8,110+p.y*.8)};
rows.push(unit.convert(anchor,new Rectangle(30,70,580,700)));}console.log(JSON.stringify(rows));'''.replace('BODY', body)
        rows = self.run_js(script)
        for actual, (vx, vy, vw, vh) in zip(rows, [(0, 0, 640, 1138), (0, 240, 1080, 1920), (80, 40, 900, 1600)]):
            import math
            left, top = math.floor(vx + 44 * vw / 640), math.floor(vy + 166 * vh / 1138)
            right, bottom = math.ceil(vx + 508 * vw / 640), math.ceil(vy + 726 * vh / 1138)
            self.assertEqual(actual, {'x': left, 'y': top, 'width': right-left, 'height': bottom-top})

    def test_all_notice_variants_use_the_same_conversion_and_resync_after_layout(self):
        source = SOURCE.read_text('utf8')
        self.assertEqual(source.count('openNoticeWebView(_loc3_,'), 3)
        self.assertNotIn('$isNotFullScreenX', source)
        self.assertIn('addEventListener("enterFrame",syncNoticeWebView)', source)
        self.assertIn('removeEventListener("enterFrame",syncNoticeWebView)', source)
        self.assertIn('mOwnedWebView.mStageWebView.viewPort = rect', source)


if __name__ == '__main__':
    unittest.main()
