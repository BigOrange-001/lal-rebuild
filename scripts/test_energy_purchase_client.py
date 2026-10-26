"""Native overflow display remains valid above the natural energy maximum."""
import json,shutil,unittest
from test_skill_books_client import method
import test_playtest_client as harness

@unittest.skipUnless(shutil.which('node'),'Node is required for AS behavior checks')
class EnergyPurchaseClientTests(unittest.TestCase):
    run_js=harness.PlaytestClientTests.run_js

    def test_current_energy_preserves_purchased_overflow(self):
        script='''const int=v=>Math.trunc(Number(v))||0;
const SendAndSelect={$systemTimer_nowSecond:1000000};
const GlobalData={$userData:{vip_lv:0,lv:1,attrs:{energy_extra:50},energy:{time:(1000000-130*300)*1000}},
$mConfig_simple:{energy_config:[130,0,5,130,50,10,0,10]}};
const calls={dialogs:[],errors:[]};
const Tools={formatLineX:v=>v},GlobalLanguageStr={getLanguageStr:()=>''},GlobalTextStyle={COLOR_W_Y_Y_G:0};
const unit={getVipLv:()=>0,getEnergyPurchaseCountToday:()=>0,functionNull:()=>{},service_energy:()=>{},
popAlert:(title,text)=>calls.dialogs.push(text),popError:text=>calls.errors.push(text)};
const GlobalFunction=unit;
'''
        script+=method('045_GlobalFunction.as','getEnergy').replace(' as Array','').replace(' as Date','')
        script+='''const values=[unit.getEnergy().energy];
GlobalData.$userData.attrs.energy_extra=370;values.push(unit.getEnergy().energy);
console.log(JSON.stringify(values));'''
        self.assertEqual(self.run_js(script),[180,500])

    def test_purchase_text_reads_bound_configuration_and_keeps_legacy_fallback(self):
        script="const GlobalData={$mConfig:{msg:{90002:'增加体力，最多500点'}},$mConfig_msg:{90002:'旧提示',42:'旧语言'}};const unit={};"
        body=method('157_GlobalLanguageStr.as','getConfigLanguageStr','id')
        body=body.replace('messages[id] is String',"typeof messages[id] === 'string'")
        body=body.replace('GlobalData.$mConfig_msg[id] is String',"typeof GlobalData.$mConfig_msg[id] === 'string'")
        script+=body+"const first=unit.getConfigLanguageStr(90002),fallback=unit.getConfigLanguageStr(42);GlobalData.$mConfig=null;console.log(JSON.stringify([first,fallback,unit.getConfigLanguageStr(90002),unit.getConfigLanguageStr(999)]));"
        self.assertEqual(self.run_js(script),['增加体力，最多500点','旧语言','旧提示',None])

if __name__=='__main__':unittest.main()
