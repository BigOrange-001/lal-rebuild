"""Exercise the actual name/count/colour and native frame methods for all affix masks."""
import subprocess
import unittest
from pathlib import Path

from test_abyss_ui_104 import method
from test_equipment_frames import frame_script

ROOT=Path(__file__).resolve().parents[1]


class RelicRarityTests(unittest.TestCase):
    def test_all_ancient_masks_and_native_quality_frames(self):
        source=(ROOT/'client/src/abyss_ui_104.aspart').read_text('utf8')
        script=frame_script()+"const assert=require('node:assert/strict');const core={};\n"
        for name in ('relicAncientCount','relicFrameQuality','relicName'):
            script+='core.'+name+'='+method(source,name,'item')+';\n'
        script+='''
for(let mask=0;mask<16;mask++){
 let count=Array.from({length:4},(_,i)=>(mask>>i)&1).reduce((a,b)=>a+b,0);
 let item={name:'测试遗物',main:{ancient:!!(mask&1)},substats:[1,2,3].map(i=>({ancient:!!(mask&(1<<i))}))};
 assert.equal(core.relicAncientCount(item),count);
 assert.equal(core.relicName(item),'*'.repeat(count)+'测试遗物');
 assert.equal(core.relicFrameQuality(item),4+count);
 let frame=unit.createQualityFrame104(core.relicFrameQuality(item));
 if(count<3){assert.equal(frame.children.length,8);assert(frame.children.every(c=>c.texture.texture.name==='EQ_1001_'+(4+count)+'0000'));}
 else if(count===3)assert.equal(frame.children[0].resource,'UI_equip_box_0005');
 else assert(frame.children[0].movieClip,'only four ancient affixes use animated rainbow');
}
assert.equal(core.relicAncientCount(null),0);
assert.equal(core.relicFrameQuality({}),4);
assert.equal(core.relicName({name:'旧遗物',substats:[null,{ancient:true}]}),'*旧遗物');
'''
        result=subprocess.run(['node'],input=script,capture_output=True,text=True,encoding='utf8')
        self.assertEqual(result.returncode,0,result.stdout+'\n'+result.stderr)

    def test_every_name_colour_uses_main_affix(self):
        source=(ROOT/'client/src/abyss_ui_104.aspart').read_text('utf8')
        self.assertNotIn('name.charAt(0) == "*"',source)
        self.assertNotIn('relicName(item).charAt(0)',source)
        self.assertIn('var ancient:Boolean = item.main && item.main.ancient;',source)
        self.assertIn('COLOR_ANCIENT:uint = 0x4CA6FF',source)
        self.assertIn('INK_ANCIENT:uint = 0x1663B8',source)


if __name__=='__main__':unittest.main()
