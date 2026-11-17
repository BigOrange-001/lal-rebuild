"""Run VIP pack reward callbacks against the runtime configuration."""
import json
import re
import subprocess
import sys
import unittest
import xml.etree.ElementTree as ET
from pathlib import Path

from test_avatar_passive import NODE, method_body

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "server"))
from gateway import load_game_config
from test_abyss_ui_104 import method


@unittest.skipUnless(NODE, "Node is required for the ActionScript behavior harness")
class VipPackRewardsClientTests(unittest.TestCase):
    def test_gift_icons_use_real_atlas_entries_and_long_rewards_expand_rows(self):
        source=(ROOT/'client/src/stages/129_PanelCenterShopVIP.as').read_text('utf-8')
        atlas=ROOT/'client/resources/app/assets/textures/1x/ui'
        names={row.get('name') for path in atlas.glob('*.xml') for row in ET.parse(path).getroot()}
        script='''const assert=require('node:assert/strict'),int=Math.trunc;
const names=new Set(NAMES);function Sprite(){this.children=[];this.addChild=c=>this.children.push(c);}
function Rectangle(){};const sizes=[],texts=[];
const GlobalFunction={UI_RED:0,UI_BROWN:0,UI_MUTED:0,
createImage:name=>{assert(names.has(name),name);return {name,width:80,height:80};},
createScale9Image:(name,width,height)=>{sizes.push(height);return {width,height};},
uiText:(...args)=>texts.push(args),uiButton:()=>({}),popToast:()=>{}};
const panel={rewardText105:r=>r.text};
'''.replace('NAMES',json.dumps(sorted(names)))
        script+='const giftIcon105='+method(source,'giftIcon105','pack')+';\n'
        script+='panel.render='+method(source,'dailyRow105','pack,width')+';\n'
        script+='''const packs=[{id:'culture'},{id:'equipment'},{id:'supreme'},{kind:'vip_once',vip:15},{id:'hero'}];
for(const pack of packs){assert(names.has(giftIcon105(pack)));assert.equal(giftIcon105(pack),'UI_bg_gift_0_0000');}
const a=panel.render({id:'hero',name:'英雄',reward:{text:'橙卡×1'},vip:9,price:8888,left:2,limit:2},620);
const b=panel.render({kind:'vip_once',vip:15,name:'VIP15专属',reward:{text:'皮肤英雄与专属装备'.repeat(25)},price:88888,left:1,limit:1},620);
assert(sizes[1]>sizes[0]);assert(a.children.some(c=>c.name));assert(b.children.some(c=>c.name));
assert(texts.every(args=>args[7]===108));'''
        run=subprocess.run([NODE],input=script,encoding='utf-8',capture_output=True,cwd=ROOT)
        self.assertEqual(run.returncode,0,run.stdout+run.stderr)

    def test_combined_reward_text_names_heroes_and_equipment(self):
        source=(ROOT/'client/src/stages/129_PanelCenterShopVIP.as').read_text('utf-8')
        body=method_body(source,'rewardText105').replace('value is Array','Array.isArray(value)')
        body=re.sub(r'reward\[key\] is (?:Number|int)',r'typeof reward[key] === "number"',body)
        script='''const assert=require('node:assert/strict'),int=Math.trunc;
const GlobalData={$mConfig_avatar:{hero:{name:'测试英雄'}},$mConfig_equip:{equip:{name:'测试装备'}}};
const text=function(reward){BODY};
const result=text({avatar:{hero:1},equip:{equip:1},culture_book:300,attrs:{dust:[200,200,200,200]}});
for(const part of ['测试英雄×1','测试装备×1','培养书×300','各色粉尘×200']) assert(result.includes(part),result);
'''.replace('BODY',body)
        run=subprocess.run([NODE],input=script,encoding='utf-8',capture_output=True,cwd=ROOT)
        self.assertEqual(run.returncode,0,run.stdout+run.stderr)

    def test_combined_list_handles_reentry_and_keeps_locked_and_claimed_rows(self):
        source=(ROOT/'client/src/stages/129_PanelCenterShopVIP.as').read_text('utf-8')
        script=r'''
const assert=require('node:assert/strict');let dailyTarget105=null,pending=null,sent=0;
const SendAndSelect={sendAndSelectService:(m,p,fn)=>{if(!pending){pending=fn;sent++;}}};
'''
        for name,args in [('receiveDaily105','reply'),('updateDaily105','reply'),('showDaily105','')]:
            script+='const '+name+'='+method(source,name,args)+';\n'
        script+=r'''
function panel(){const p={stage:{},mTabBar:{selectedIndex:3},mList:{visible:true},dailyPacks105:[],
dailyLoading105:false,builds:0,clearDaily105:()=>{},buildDaily105:()=>p.builds++};
p.showDaily105=showDaily105.bind(p);p.updateDaily105=updateDaily105.bind(p);return p;}
const old=panel();old.showDaily105();old.stage=null;
const current=panel();current.showDaily105();assert.equal(sent,1);assert.equal(current.builds,1);
const done=pending;pending=null;
done({return_code:0,data:{packs:[{id:'daily',left:1}],vip_packs:[{id:'claimed',left:0},{id:'locked',locked:true}]}});
assert.equal(current.builds,2);assert.equal(current.dailyLoading105,false);
assert.deepEqual(current.dailyPacks105.map(p=>p.id),['daily','claimed','locked']);
assert.deepEqual(old.dailyPacks105,[]);
current.mTabBar.selectedIndex=0;done({return_code:0,data:{packs:[]}});
assert.equal(current.dailyPacks105.length,3);
'''
        run=subprocess.run([NODE],input=script,encoding='utf-8',capture_output=True,cwd=ROOT)
        self.assertEqual(run.returncode,0,run.stdout+run.stderr)

    def test_free_and_paid_packs_render_every_reward_and_refresh_the_list(self):
        cfg = load_game_config(ROOT / "config/reconstruction/full-config.json")["cfg"]
        packs = [cfg["vip"][str(level)][kind]["data"]
                 for level in range(1, 16) for kind in ("gift_buy", "gift_coin_buy")]
        body = method_body((ROOT / "client/src/stages/100_ItemVIPShopping.as").read_text("utf-8"),
                           "sendAward")
        script = r'''
const packs=JSON.parse(require('fs').readFileSync(0,'utf8'));
const Tools={clone:value=>JSON.parse(JSON.stringify(value))};
let calls=[],events=[];
const GlobalFunction={
  getAwardByType(type,value){
    if(!['coin','gold','culture_book','dn_stone','dust','avatar','equip'].includes(type))
      throw new Error('Unsupported reward type: '+type);
    return {msg:type};
  },
  popAward(type,message,value){calls.push({type,value});}
};
const GlobalLanguageStr={getLanguageStr:(id,msg)=>msg};
const GlobalData={$mEventDispatcher:{dispatchEventWith:event=>events.push(event)}};
const sendAward=function(param1){BODY};
const rows=packs.map(pack=>{
  calls=[];events=[];
  const before=JSON.stringify(pack);
  sendAward(pack);
  return {calls,events,unchanged:before===JSON.stringify(pack)};
});
console.log(JSON.stringify(rows));
'''.replace("BODY", body)
        run = subprocess.run([NODE, "-e", script], input=json.dumps(packs),
                             encoding="utf-8", capture_output=True, timeout=20)
        self.assertEqual(run.returncode, 0, run.stderr)
        results = json.loads(run.stdout)
        self.assertEqual(len(results), 30)
        for index, (pack, result) in enumerate(zip(packs, results)):
            with self.subTest(vip=index // 2 + 1, paid=bool(index % 2)):
                expected = {key: value for key, value in pack.items() if key != "attrs"}
                expected.update(pack.get("attrs", {}))
                actual = {}
                for row in result['calls']:
                    if row['type'] in ('avatar','equip'):
                        actual.setdefault(row['type'],{}).update(row['value'])
                    else:actual[row['type']]=row['value']
                self.assertEqual(actual, expected)
                self.assertEqual(result["events"], ["update_vip_gift"])
                self.assertTrue(result["unchanged"])


if __name__ == "__main__":
    unittest.main()
