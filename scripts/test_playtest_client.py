"""Run the actual patched AS control flow with presentation/transport stubs.

This verifies selection, receipt and lifecycle behavior; GPU rendering and
Android power management still require a device acceptance run.
"""
import json
import re
import shutil
import subprocess
import unittest
from pathlib import Path

from test_avatar_passive import method_body

ROOT = Path(__file__).resolve().parents[1]
STAGES = ROOT / 'client/src/stages'
NODE = shutil.which('node')


def function(filename, name, params=''):
    body = method_body((STAGES / filename).read_text(encoding='utf-8'), name)
    body = body.replace('reply.data is Array', 'Array.isArray(reply.data)')
    body = re.sub(r'for each\((\w+) in (\w+)\)', r'for(\1 of \2)', body)
    return f"unit.{name} = (function({params}) {{ with(this) {{ {body}\n }} }}).bind(unit);\n"


@unittest.skipUnless(NODE, 'Node is needed for the ActionScript behavior harness')
class PlaytestClientTests(unittest.TestCase):
    def run_js(self, script, options=None):
        run = subprocess.run([NODE, '-e', script], input=json.dumps(options or {}),
                             encoding='utf-8', capture_output=True, timeout=20)
        self.assertEqual(run.returncode, 0, run.stderr)
        return json.loads(run.stdout)

    def rise(self, **options):
        script = r'''
const options = JSON.parse(require('fs').readFileSync(0,'utf8'));
const noop=()=>{};
let tasks=new Map(), serial=0, pending=[], sent=0, errors=0;
const setTimeout=(fn)=>{tasks.set(++serial,fn); return serial;};
const clearTimeout=(id)=>tasks.delete(id);
const int=Number;
const data={lv:options.level || 1};
const GlobalData={$tempEquipCurrSelected:'eq0',$userData:{my_equips:{eq0:data},gold:options.gold ?? 1000,team:[[]]},
  $mGameClassObject:{touchable:true,mLayoutUITop:{mPanelTopMain:{updateGold:noop}}},$mStageHeight:1000};
const GlobalFunction={getEquipRiseMaxLv:()=>options.cap || 100,popError:()=>errors++,getTeamPower:()=>1,
  isMalformedProfileReceipt:r=>!!r.bad,didApplyProfileStateSync:r=>!r.bad};
const GlobalLanguageStr={getLanguageStr:()=>''}, Tools={clone:v=>({...v})};
function Equip(){this.getRiseGold=()=>10;}
const SendServiceAMFFun={send_user_equip_rise:(fn,params)=>{sent++;pending.push(()=>{
  data.lv += options.crit || 1; GlobalData.$userData.gold-=10;
  fn({params,data:[data.lv,GlobalData.$userData.gold]});
});}};
const LayoutUIAnimation={getOnlyExample:()=>({popWords:noop,popEffect:()=>{if(options.effectError)throw Error('GPU');}})};
const SoundManager={getOnlyExample:()=>({playSound:noop})}, GuideTools={doModuleGuide:noop};
const unit={stage:{},riseInFlight:false,riseBefore:null,riseDelay:0,_btn_status:false,_riseBatchRemaining:0,
  mStatus_up:false,mPrice_num:0,mCurr_lv:1,mBox_equip:{},_spRule:{},mBtn_to:{enabled:true},
  mBtn_riseByonce:{name:'mbtn_risebyonce'},updateAttUIs:noop,mCurrEquip:{getBounds:()=>({x:0,y:0})}};
'''
        for name, params in [('stopRiseBatch', ''), ('chengeStutes', 'param1=false'),
                             ('onRiseError', 'event'), ('send_rise_fun', ''),
                             ('onTRIGGERED_up', 'param1'), ('continueRiseBatch', ''),
                             ('re_equip_rise', 'reply')]:
            script += function('060_PanelEquipRise.as', name, params)
        script += r'''
const click=()=>unit.onTRIGGERED_up({currentTarget:unit.mBtn_riseByonce});
click();
if(options.doubleClick)click();
if(options.businessError){pending=[];unit.onRiseError({data:{method:'user.equip_rise'}});click();}
if(options.malformed){pending=[];unit.re_equip_rise({params:{eqid:'eq0'},bad:true});click();}
if(options.stop)click();
let turns=0;
while((pending.length || tasks.size) && turns++<100){
  if(pending.length){try{pending.shift()();}catch(e){if(!options.effectError)throw e;}}
  else {const [id,fn]=tasks.entries().next().value; tasks.delete(id);fn();}
  if(options.leave){unit.stage=null;}
}
console.log(JSON.stringify({sent,level:data.lv,remaining:unit._riseBatchRemaining,inFlight:unit.riseInFlight,
  running:unit._btn_status,button:unit.mBtn_riseByonce.text,errors,turns}));
'''
        return self.run_js(script, options)

    def test_ten_upgrades_finish_and_restore_controls(self):
        result = self.rise()
        self.assertEqual((result['sent'],result['level'],result['remaining']), (10,11,0))
        self.assertFalse(result['running'] or result['inFlight'])
        self.assertEqual(result['button'], '强化十次')

    def test_cap_gold_critical_and_stop_are_bounded(self):
        for options, expected in [({'cap':4},3), ({'gold':25},2), ({'crit':3,'cap':7},2),
                                  ({'stop':True},1), ({'doubleClick':True},1), ({'leave':True},1)]:
            with self.subTest(options=options):
                self.assertEqual(self.rise(**options)['sent'], expected)

    def test_business_or_protocol_failure_allows_restart(self):
        for options in [{'businessError':True}, {'malformed':True}]:
            with self.subTest(options=options):
                result = self.rise(**options)
                self.assertEqual(result['sent'],11)
                self.assertFalse(result['inFlight'] or result['running'])

    def test_optional_effect_failure_does_not_stall_batch(self):
        self.assertEqual(self.rise(effectError=True)['sent'],10)

    def test_draw_restores_hidden_layer_and_clears_previous_timeline(self):
        script = r'''
let purges=0,reopens=0;
const StarlingTools={removeChildrenClear:()=>{}};
const unit={animationLayer:{visible:false,touchable:true},visible:false,touchable:false,
  tempUIName:'center_casino_VIP',txt:null,txt1:null,isPlay:false,jugglerA:{purge:()=>purges++}};
const GlobalData={$mGameClassObject:{mLayoutUICenter:{showPanel:()=>reopens++}}};
const PanelCenterShopVIP={};
'''
        script += function('147_LayoutUIAnimation.as','clearAnimationLayer','param1=null')
        script += function('147_LayoutUIAnimation.as','clearAnimationLayerForDraw')
        script += '''unit.clearAnimationLayerForDraw(); console.log(JSON.stringify({visible:unit.animationLayer.visible,
          playing:unit.isPlay,purges,reopens}));'''
        self.assertEqual(self.run_js(script),{'visible':True,'playing':True,'purges':1,'reopens':0})

    def test_system_labels_survive_missing_translation_catalog(self):
        script = "const GlobalLanguageStr={getLanguageStr:()=>''}; const unit={};\n"
        script += function('153_ItemHelp.as','getMenuTitle','item')
        script += '''console.log(JSON.stringify(['center_help_notice','center_help_setting','center_help_quit',
          'center_help_award_code','center_help_name'].map(name=>unit.getMenuTitle({name}))));'''
        self.assertEqual(self.run_js(script),['游戏公告','游戏设置','返回登录','兑换码','修改昵称'])

    def test_non_skill_fragment_has_safe_description(self):
        script = 'const unit={_skillset:null};\n'
        script += function('156_PanelInfoChip.as','getFragmentSkillInfo')
        script += 'console.log(JSON.stringify(unit.getFragmentSkillInfo()));'
        self.assertEqual(self.run_js(script),'该装备不附带技能。')

    def test_fragment_timer_stops_on_close(self):
        body = method_body((STAGES/'130_PanelChip.as').read_text(encoding='utf-8'),'onREMOVED_FROM_STAGE')
        body = body.replace('super.onREMOVED_FROM_STAGE(param1);','baseCalls++;')
        script = '''let stopped=0,unsubscribed=0,baseCalls=0;
const GlobalData={$mEventDispatcher:{removeEventListener:()=>unsubscribed++}};
const unit={onTIMER_fragment:()=>{},onUPDATE_FRAGMENT_LIST:()=>{},setFragment_child:()=>{},
  mTimer_fragment:{stop:()=>stopped++,removeEventListener:()=>unsubscribed++}};
'''
        script += f'(function(param1){{with(unit){{{body}}}}})({{}});'
        script += 'console.log(JSON.stringify({stopped,unsubscribed,baseCalls,timer:unit.mTimer_fragment}));'
        self.assertEqual(self.run_js(script),{'stopped':1,'unsubscribed':3,'baseCalls':1,'timer':None})

    def test_equipment_all_tab_includes_all_owned_non_books(self):
        script = r'''
Array.prototype.sortOn=function(){return this;};
const int=Number, ItemEquipRender=function(){};
const input={a:{eid:'E_1001_3',lv:1},b:{eid:'E_3001_3',lv:2},c:{eid:'E_4001_3',lv:4},
  d:{eid:'E_6001_3',lv:1},broken:{eid:'E_missing_3',lv:1}};
const GlobalData={$tempEquipFunId:1,$userData:{my_equips:input},$mConfig_equip:{
  E_1001_3:{},E_3001_3:{},E_4001_3:{},E_6001_3:{}}};
const GlobalFunction={checkEquipType:()=>'E_1',checkEquipIsBook:id=>id.startsWith('E_6'),checkEquipHasUsed:()=>-1};
const GlobalLanguageStr={getLanguageStr:()=>''}, Tools={clone:o=>({...o})};
let rows=[];
const unit={mRadioBar:{selectedIndex:0},mList:{},mListY:0,mTips:null,
  setListTimer:(list,data)=>rows=data, setTips:()=>{}};
'''
        script += function('158_PanelEquipSelect.as','addList')
        script += 'unit.addList();console.log(JSON.stringify({ids:rows.map(v=>v.id),mutated:input.a.id!==undefined}));'
        self.assertEqual(self.run_js(script),{'ids':['a','b','c'],'mutated':False})

    def test_barracks_quality_then_phase_order(self):
        script = 'const unit={};\n'
        script += function('031_PanelSocialMainAvatar.as','compareSmartAvatars','param1,param2')
        script += '''console.log(JSON.stringify([{id:'a',star:5,phase:0},{id:'b',star:5,phase:1},
          {id:'c',star:6,phase:0}].sort(unit.compareSmartAvatars).map(v=>v.id)));'''
        self.assertEqual(self.run_js(script),['c','b','a'])

    def test_reconnect_always_constructs_a_connection(self):
        script = 'let closed=0; const unit={$remoting:{closeNet:()=>closed++}}; function RemotingConnect(a,b){this.url=a;}\n'
        script += function('013_RpcStaticCall.as','connectNet','param1,param2')
        script += "unit.connectNet('local','main');console.log(JSON.stringify({closed,url:unit.$remoting.url}));"
        self.assertEqual(self.run_js(script),{'closed':1,'url':'local'})

    def test_failed_receipt_callback_is_removed_and_can_be_retried(self):
        body = method_body((STAGES/'003_SendAndSelect.as').read_text(encoding='utf-8'),'reCheckFun')
        body = body.replace('$serviceData[_loc3_]["reFunction"] is Function',
                            'typeof $serviceData[_loc3_]["reFunction"] === "function"')
        script = r'''
const int=Number, MainConfig={$testReSend:false}, Tools={toTrace:()=>{}};
const DebugManager={instance:()=>({debug:()=>{}})};
const GlobalFunction={profileReceiptKind:()=>1,isProfileBootstrapMethod:()=>false,applyProfileStateSync:()=>{}};
function NetEvent(type){this.type=type;}
let cleared=0;
const unit={$serviceData:{a1:{reFunction:()=>{throw Error('UI failed');}}},
  $systemTimer_nowSecond:0,$systemTimeDate:null,$profileBootstrapActionID:'',
  $reNetEventObj:null,$SendServiceAMFDispatcher:{dispatchEvent:()=>{}},
  setSystem:()=>{},clearTimeOut:()=>cleared++};
'''
        script += f'unit.reply=(function(param1){{with(this){{{body}}}}}).bind(unit);'
        script += '''let failed=false;try{unit.reply({method:'user.equip_rise',params:{actionID:'a1'},
          server_now:{time:1000},return_code:0,state_sync:{}});}catch(e){failed=true;}
          console.log(JSON.stringify({failed,cleared,pending:Object.keys(unit.$serviceData).length}));'''
        self.assertEqual(self.run_js(script),{'failed':True,'cleared':1,'pending':0})


if __name__ == '__main__':
    unittest.main()
