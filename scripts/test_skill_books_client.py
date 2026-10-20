"""Run actual book-upgrade AS methods across successive receipt/selection cycles."""
import json
import re
import shutil
import unittest
from pathlib import Path

from test_avatar_passive import method_body
import test_playtest_client as harness

ROOT = Path(__file__).resolve().parents[1]
STAGES = ROOT / 'client/src/stages'


def method(filename, name, params=''):
    body = method_body((STAGES / filename).read_text('utf8'), name)
    body = re.sub(r'for each\(var (\w+) in ([^)]+)\)', r'for(var \1 of \2)', body)
    body = re.sub(r'for each\((\w+) in ([^)]+)\)', r'for(\1 of \2)', body)
    return f'unit.{name}=function({params}){{with(this){{{body}\n}}}};\n'


@unittest.skipUnless(shutil.which('node'), 'Node is required for AS behavior checks')
class SkillBooksClientTests(unittest.TestCase):
    run_js = harness.PlaytestClientTests.run_js

    def test_all_quality_level_contributions_and_zero_floor_match_user_curve(self):
        script='''const int=v=>Math.trunc(Number(v))||0;
const GlobalData={$userData:{my_equips:{target:{slv:1},food:{eid:'E_6001_2'}}},
$mConfig_simple:{skill_book_rand:[.1,.2,.3,.4,.5,.6,.7],skill_book_level_penalty:.03}};
function Equip(id,row){this.slv=row.slv;this.clear=()=>{};}const unit={};'''
        script+=method('045_GlobalFunction.as','getEquipBookUpP','param1,param2')
        script+='''let rates=[];for(let level=1;level<=10;level++){
GlobalData.$userData.my_equips.target.slv=level;
for(let q=2;q<=6;q++){GlobalData.$userData.my_equips.food.eid='E_6001_'+q;
rates.push(unit.getEquipBookUpP(['food'],'target'));}}
console.log(JSON.stringify(rates));'''
        self.assertEqual(self.run_js(script),[max(0,q*10-3*(level-1))/100 if level<10 else 0 for level in range(1,11) for q in range(2,7)])

    def test_probability_uses_current_level_and_missing_material_is_safe(self):
        for source in ('017_GlobalFunction.as', '045_GlobalFunction.as'):
            script = '''const int=v=>Math.trunc(Number(v))||0;
const GlobalData={$userData:{my_equips:{target:{slv:3},a:{eid:'E_6001_3'},b:{eid:'E_6001_6'}}},
  $mConfig_simple:{skill_book_rand:[.1,.2,.3,.4,.5,.6,.7]}};
function Equip(id,row){this.slv=row.slv;this.clear=()=>{};}const unit={};
'''
            script += method(source, 'getEquipBookUpP', 'param1,param2')
            script += '''let rates=[unit.getEquipBookUpP(['a','b'],'target')];
GlobalData.$userData.my_equips.target.slv=4;delete GlobalData.$userData.my_equips.a;
rates.push(unit.getEquipBookUpP(['a','b'],'target'));
rates.push(unit.getEquipBookUpP(['b'],'missing'));console.log(JSON.stringify(rates));'''
            self.assertEqual(self.run_js(script), [.78, .51, 0], source)

    def test_receipts_clean_consumed_ids_and_allow_next_upgrade_without_relogin(self):
        for versioned in (True, False):
            script = '''const noop=()=>{};const calls={refresh:0,failed:0};
const GlobalData={$userData:{my_equips:{target:{slv:1},one:{eid:'E_6001_2'},two:{eid:'E_6001_2'},locked:{lock:1}},team:[[]]},
$tempEquipCurrSelected:'target',$tempFoodForBook:['one','gone','one','target','locked'],
$tempObjectFoodForBook:{one:{reData:true}},$mGameClassObject:{mLayoutUITop:{mPanelTopMain:{updateGold:noop}}}};
const GlobalFunction={isVersionedProfileReceipt:()=>VERSIONED,getTeamPower:()=>0,popAlert:()=>calls.failed++};
const GlobalLanguageStr={getLanguageStr:()=>''};const SoundManager={getOnlyExample:()=>({playSound:noop})};
const LayoutUIAnimation={getOnlyExample:()=>({popSuperWord:noop})};
function Equip(id,row){this.slv=row.slv;}
const unit={stage:true,mBox_data:null,setFood:()=>calls.refresh++,setmMC_book:noop,checkBtn_selectStatus:noop};
'''.replace('VERSIONED', json.dumps(versioned))
            script += method('112_PanelEquipBook.as', 'sanitizeBookFood')
            script += method('112_PanelEquipBook.as', 're_bookUP', 'param1,param2,param3,param4')
            script += '''unit.sanitizeBookFood();let selected=GlobalData.$tempFoodForBook.slice();
if(VERSIONED){delete GlobalData.$userData.my_equips.one;}
unit.re_bookUP({data:{equip:{slv:1},gold:90,success:false}},1,'target',['one']);
let afterFailure=GlobalData.$tempFoodForBook.slice();GlobalData.$tempFoodForBook.push('two');
if(VERSIONED){delete GlobalData.$userData.my_equips.two;GlobalData.$userData.my_equips.target={slv:2};}
unit.re_bookUP({data:{equip:{slv:2},gold:70,success:true}},1,'target',['two']);
console.log(JSON.stringify({selected,afterFailure,final:GlobalData.$tempFoodForBook,
slv:GlobalData.$userData.my_equips.target.slv,calls}));'''.replace('VERSIONED', json.dumps(versioned))
            self.assertEqual(self.run_js(script), {
                'selected': ['one'], 'afterFailure': [], 'final': [], 'slv': 2,
                'calls': {'refresh': 2, 'failed': 1}}, versioned)

    def test_delayed_receipt_preserves_new_target_materials(self):
        script = '''const noop=()=>{};
const GlobalData={$userData:{my_equips:{next:{slv:1},fresh:{}},team:[[]]},
$tempEquipCurrSelected:'next',$tempFoodForBook:['fresh'],$tempObjectFoodForBook:{},
$mGameClassObject:{mLayoutUITop:{mPanelTopMain:{updateGold:noop}}}};
const GlobalFunction={isVersionedProfileReceipt:()=>true,getTeamPower:()=>0};
const unit={stage:true};function Equip(id,row){this.slv=row.slv;}
'''
        script += method('112_PanelEquipBook.as', 're_bookUP', 'param1,param2,param3,param4')
        script += '''unit.re_bookUP({data:{equip:{slv:2},gold:20,success:true}},1,'old',['consumed']);
console.log(JSON.stringify(GlobalData.$tempFoodForBook));'''
        self.assertEqual(self.run_js(script), ['fresh'])

    def test_passive_preview_and_cached_battle_stats_are_applied_once(self):
        script = '''const Tools={toInt:Math.trunc};
const unit={mData:null,hpMax:0,hit:0,equips:[{getHit:()=>100}],mDestiny:{hit:10,hitP:0},buffs:{hitup:{value:5}},
skill2:{getEquipRate:()=>1},getBookCombatBonus:()=>.45,initializingFightAttributes:false,teamTalentFlat:()=>0};
'''
        script += method('137_Avatar.as', 'getHit')
        script += '''let raw=unit.getHit();unit.hpMax=1000;unit.hit=159;
console.log(JSON.stringify([raw,unit.getHit()]));'''
        self.assertEqual(self.run_js(script), [164, 164])

    def test_final_avatar_penetration_applies_to_either_defense(self):
        script = '''const Tools={toInt:v=>Math.trunc(Number(v.toFixed(5)))};
const AvatarData={damageRate:()=>1},trace=()=>{};
const unit={MIN_DAMAGE_RATE:.1,REAL_DAMAGE_RATE:.3,SIGN_DAMAGE_RATE:1.2};
const source={avatarData:{},getBookCombatBonus:()=>.45};
const target={avatarData:{},getDePh:()=>80,getDeMa:()=>80,checkTalent:()=>0};
'''
        script += method('137_Avatar.as', 'countDamage', 'param1,param2,param3,param4,param5=1')
        script += '''console.log(JSON.stringify([unit.countDamage(source,target,100,1)[0],unit.countDamage(source,target,100,2)[0]]));'''
        self.assertEqual(self.run_js(script), [56, 56])

    def test_basic_hit_glyphs_use_actual_damage_and_curse_threshold(self):
        script = '''const Tools={toInt:v=>Math.trunc(Number(v.toFixed(5)))};
let roll=799;const Random={getRandom:()=>roll};
const calls={burn:[],curse:0};
const target={hp:1000,team:2,addBookBurn:(total,rounds)=>calls.burn.push([total,rounds]),addBuff:()=>calls.curse++};
const unit={team:1,getBookCombatBonus:stat=>stat==='attack_burn'?.24:.08};
'''
        script += method('137_Avatar.as', 'applyBookAttackEffects', 'target,dealt')
        script += '''unit.applyBookAttackEffects(target,17);roll=800;
unit.applyBookAttackEffects(target,17);unit.applyBookAttackEffects(target,0);
console.log(JSON.stringify(calls));'''
        self.assertEqual(self.run_js(script), {'burn': [[4, 3], [4, 3]], 'curse': 1})


if __name__ == '__main__':
    unittest.main()
