"""Exercise avatar lock creation/toggle with the real AS method bodies.

Widget stubs cover display-list anchoring; device checks cover rendering.
"""
import subprocess
import unittest
from pathlib import Path

from test_abyss_ui_104 import method

ROOT = Path(__file__).resolve().parents[1]


class AvatarDetailRelicLockTests(unittest.TestCase):
    def test_relic_slot_touch_opens_its_position_without_external_panel_lookup(self):
        source = (ROOT / 'client/src/abyss_ui_104.aspart').read_text('utf-8')
        source = source.split('class AbyssRelicSlotView104', 1)[1].split('class AbyssRerollView104', 1)[0]
        script = r'''
const assert=require('node:assert/strict');
class Sprite {constructor(){this.children=[];}addChild(child){this.children.push(child);}}
class ItemEquip {}
class Quad {addEventListener(type,callback){assert.equal(type,'touch');this.touch=callback;}}
const GlobalData={$userData:{abyss_relics:{relic:{}}}};
const GlobalFunction={createTextField:()=>({})};
const opened=[];
const AbyssCore104={relicSlots:()=>[null,'relic',null,null,null,null],relicName:()=>'*test',
openRelicSlot:slot=>opened.push(slot),COLOR_ANCIENT:1,COLOR_TITLE:2,COLOR_DIM:3};
const AbyssRelicArt104={create:()=>({})};
'''
        script += 'const create=' + method(source, 'create', 'slot') + ';\n'
        script += r'''
for(let slot=0;slot<6;slot++) {
 const view=create(slot),hit=view.children.find(child=>child instanceof Quad);
 assert(hit,'relic slot has a touch target');
 hit.touch({getTouch:(target,phase)=>{assert.equal(target,hit);assert.equal(phase,'ended');return null;}});
 assert.equal(opened.length,slot,'other touch phases do not open a selector');
 hit.touch({getTouch:()=>({})});
 assert.equal(opened.at(-1),slot);
}
assert.deepEqual(opened,[0,1,2,3,4,5]);
console.log('relic slot touch ok');
'''
        result = subprocess.run(['node'], input=script, capture_output=True, text=True, encoding='utf-8', cwd=ROOT)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_initial_lock_and_toggle_ignore_relic_and_other_non_equipment_children(self):
        source = (ROOT / 'client/src/stages/143_LOL_DetailAvatar.as').read_text('utf-8')
        script = r'''
const assert=require('node:assert/strict');
const noop=()=>{};
class ItemEquip {constructor(x){this.x=x;}}
class Sprite {constructor(x){this.x=x;}}
let locked=false, notifications=0, refreshed=0;
const GlobalData={$userData:{avatars:{hero:{}}},$tempLockItem:{fun:()=>refreshed++}};
const GlobalFunction={checkLock:()=>locked,changeLock:(id,value)=>{assert.equal(id,'hero');locked=value;},
createButton_5:()=>({width:40,height:40,addEventListener:noop,removeEventListener:noop,removeFromParent:noop})};
const GlobalLanguageStr={getLanguageStr:id=>String(id)};
const LayoutUIAnimation={getOnlyExample:()=>({popWords:()=>notifications++})};
const panel={_avatar:{id:'hero'},_isShowLock:true,_lockImg:null,_lock:false,_width:640,
_iconBg:{y:600},_uiMain:{addChild:noop},mFoster:null,mFoster2:null,
_euqipMain:{children:[],get numChildren(){return this.children.length;},getChildAt(i){return this.children[i];}}};
'''
        for name in ('positionAvatarLock104', 'update_Lock', 'onTRIGGERED_lock'):
            body = method(source, name, 'event' if name == 'onTRIGGERED_lock' else '')
            body = body.replace('child is ItemEquip', 'child instanceof ItemEquip')
            script += f'panel.{name}={body};\n'
        script += r'''
for(const children of [
 [new ItemEquip(20),new ItemEquip(420)],
 [new ItemEquip(20),new ItemEquip(420),new Sprite(280)],
 [new ItemEquip(20),new ItemEquip(420),new Sprite(280),new Sprite(10)],
 [new Sprite(280)],[]]) {
 panel._euqipMain.children=children;
 const expected=children.some(c=>c instanceof ItemEquip)?380:540;
 panel.update_Lock();
 assert.equal(panel._lockImg.x,expected);
 assert.equal(panel._lockImg.y,560);
 for(let n=0;n<2;n++) {
  const before=locked;panel.onTRIGGERED_lock(null);
  assert.equal(locked,!before);
  assert.equal(panel._lockImg.x,expected);
  assert.equal(panel._lockImg.y,560);
 }
}
assert.equal(notifications,10);assert.equal(refreshed,10);
panel._isShowLock=false;panel._lockImg=null;panel.update_Lock();assert.equal(panel._lockImg,null);
console.log('avatar detail relic lock ok');
'''
        result = subprocess.run(['node'], input=script, capture_output=True, text=True, encoding='utf-8', cwd=ROOT)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == '__main__':
    unittest.main()
