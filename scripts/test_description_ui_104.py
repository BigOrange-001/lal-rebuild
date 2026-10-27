"""Run actual description and bond-click AS methods with rendering stubs."""
import json,re,shutil,unittest
from pathlib import Path
from test_avatar_passive import method_body
from test_playtest_client import PlaytestClientTests
ROOT=Path(__file__).resolve().parents[1]

def attach(file,name,args):
    body=method_body((ROOT/'client/src/stages'/file).read_text('utf8'),name)
    return 'unit.'+name+'=function('+args+'){with(this){'+body+'}};\n'

@unittest.skipUnless(shutil.which('node'),'Node required')
class DescriptionUI104Tests(unittest.TestCase):
    run_js=PlaytestClientTests.run_js
    def test_legacy_rule_commentary_is_removed(self):
        body=method_body((ROOT/'client/src/stages/139_SkillSet.as').read_text('utf8'),'conciseInfo104')
        result=self.run_js('function clean(value){'+body+'}console.log(JSON.stringify(clean("造成144%攻击物理伤害并施加74.7%攻击中毒1回合，中毒沿用原版附加规则。")));')
        self.assertEqual(result,'造成144.0%攻击物理伤害并施加74.7%攻击中毒1回合。')
    def test_growth_notes_and_native_healing_become_plain_effects(self):
        body=method_body((ROOT/'client/src/stages/139_SkillSet.as').read_text('utf8'),'conciseInfo104')
        samples=[
            '造成236.8%攻击魔法伤害；随后以自身攻击加10%最大生命为基础，按85.3333%原生治疗倍率自疗，并受原版治疗修正。强化每级伤害+34%。',
            '为全体友军恢复112%攻击力生命。1～10级治疗从56%线性成长到112%，不附加额外生命系数。',
            '以48%原生治疗倍率为同路两名友方恢复生命。原生治疗含自身最大生命项与治疗修正。',
            '击杀攻击成长提高30%。每次击杀获得1层5%攻击增益。本技能伤害1～10级线性成长至两倍，每层5%不随等级成长。',
        ]
        result=self.run_js('function clean(value){'+body+'}console.log(JSON.stringify('+json.dumps(samples,ensure_ascii=False)+'.map(clean)));')
        self.assertIn('236.8%攻击魔法伤害',result[0])
        self.assertIn('85.3%攻击力＋8.5%最大生命',result[0])
        self.assertEqual(result[1],'为全体友军恢复112.0%攻击力生命。')
        self.assertIn('48.0%攻击力＋4.8%最大生命',result[2])
        self.assertIn('击杀攻击成长提高30.0%',result[3])
        self.assertIn('1层5.0%攻击增益',result[3])
        for text in result:
            for phrase in ('强化每级','线性成长','原生治疗','原版治疗'):
                self.assertNotIn(phrase,text)

    def test_description_keeps_effects_and_drops_commentary(self):
        body=method_body((ROOT/'client/src/stages/139_SkillSet.as').read_text('utf8'),'conciseInfo104')
        sample='自身生命不高于40%，同路600范围内至少有2名敌人，施放主动技能后：对本路前排敌人造成256%攻击力魔法伤害；为自身恢复88%攻击力生命。准备0，冷却1；每回合最多触发一次，被动不连锁触发。'
        equipment='《让子弹飞》：仅命中自身瞄准标记时的狙击伤害提高14.12%。该部分按技能等效收益的85.00%估值，整项技能目标提升12%；其他部分不变。'
        script='function clean(value){'+body+'}\n'
        script+='console.log(JSON.stringify('+json.dumps([sample,equipment,'五连击，每击160%攻击物伤；自身获得35%最大生命护盾2回合并恢复累计伤害25%，集中压制敌方主核。'],ensure_ascii=False)+'.map(clean)));'
        result=self.run_js(script)
        self.assertIn('生命不高于40.0%',result[0]);self.assertIn('256.0%',result[0]);self.assertIn('88.0%',result[0])
        for word in ('每回合最多','连锁','准备0','冷却1'):self.assertNotIn(word,result[0])
        self.assertEqual(result[1],'《让子弹飞》：仅命中自身瞄准标记时的狙击伤害提高14.1%。')
        self.assertNotIn('集中压制',result[2]);self.assertIn('35.0%最大生命护盾2回合',result[2])

    def test_detail_does_not_append_generic_target_rules(self):
        script='''const unit={skillSetData:{warmup:0,cooldown:1,hpType:0,range:9999,aoe:1,banStand:0},getInfo:()=>"对前排造成256%伤害。"};
const GlobalLanguageStr={getLanguageStr:(id,a,b)=>{if(id!==20468)throw Error('generic rule appended');return '准备'+a+'；冷却'+b;}};
'''+attach('139_SkillSet.as','getInfoDetails','')+'''console.log(JSON.stringify(unit.getInfoDetails()));'''
        self.assertEqual(self.run_js(script),'准备0；冷却1\n对前排造成256%伤害。\n')

    def test_popup_black_text_and_inset_viewport(self):
        body=method_body((ROOT/'client/src/stages/143_LOL_DetailAvatar.as').read_text('utf8'),'showBondInfo104')
        script="""let result={};
function ScrollScreenForTxt(){this.setRecWH=(w,h)=>this.maxHeight=h;}
function PanelInforPop(title,info,w,h){result={title,info,w,h};this.numChildren=2;this.scroll=new ScrollScreenForTxt();this.getChildAt=i=>i===1?this.scroll:null;result.scroll=this.scroll;}
const Tools={formatLineX:(text,colors)=>({text,colors})};
const bondInfoHtml104=e=>'colored '+e.info;
const GlobalData={$mGameClassObject:{closePopUp:()=>{},openPopUp:p=>{}}};
"""+'function show(entry){'+body+'}'+"show({txt:'武道争锋',info:'组合和本人收益'});console.log(JSON.stringify(result));"
        result=self.run_js(script)
        self.assertEqual(result['info'],'colored 组合和本人收益')
        self.assertEqual(result['scroll']['y'],84)
        self.assertLessEqual(result['scroll']['y']+result['scroll']['maxHeight'],550)
        self.assertTrue(result['scroll']['clipContent'])

    def test_bond_description_only_current_hero_benefit(self):
        body=method_body((ROOT/'client/src/stages/137_Avatar.as').read_text('utf8'),'getBondEntries104')
        body=re.sub(r'for each\(var (\w+) in ([^)]+)\)',r'for(var \1 of (\2 || []))',body)
        script="""const int=Number;
const bond={id:'b',name:'组合测试',families:['A_1','A_2'],minimum_quality:{A_1:4,A_2:3},benefits:{A_1:{stats:{ap:.28}},A_2:{stats:{hp:.4}}}};
const GlobalData={$mConfig_simple:{bonds_104:[bond],equipment_bonds_104:{}},$mConfig_avatar:{A_1_4:{id:'A_1_4',name:'甲'},A_2_4:{id:'A_2_4',name:'乙'}},$mConfig_equip:{}};
const unit={avatarData:{id:'A_1_4'},getStar:()=>4,getBondRows104:()=>[],getEquipmentBondRows104:()=>[]};
"""+'unit.get=function(){with(this){'+body+'}};console.log(JSON.stringify(unit.get()));'
        result=self.run_js(script)[0]
        self.assertEqual(result['info'],'组合：甲、乙\n\n攻击提高28%')
        self.assertFalse(result['isOK'])

    def test_names_layout_colors_and_only_clicked_popup(self):
        script='''let shown=[];const int=Number;
function Sprite(){this.children=[];this.addChild=x=>this.children.push(x);}
function LOL_TextField(txt,width,height){Object.assign(this,{txt,width,height});}
function Quad(width,height){Object.assign(this,{width,height});this.addEventListener=()=>{};}
const StarlingTools={removeChildrenClear:b=>b.children=[]};
const GlobalFunction={popInforAlert:(title,info)=>shown.push({title,info})};
const Tools={formatLineX:s=>s},GlobalTextStyle={COLOR_W_W_Y_G:1};
const unit={showBondInfo104:e=>shown.push({title:e.txt,info:e.info}),mDestinyBox:null,mBondEntries104:[],_iconBg:{width:500,height:90},addChild:()=>{}};
'''+attach('143_LOL_DetailAvatar.as','setDestinyTxts','param1,param2=0,param3=0,param4=false')+attach('143_LOL_DetailAvatar.as','bondNameTouch104','event')+'''
const rows=Array.from({length:8},(_,i)=>({txt:'羁绊'+i,isOK:i===1,info:'效果'+i}));
unit.setDestinyTxts(rows,20,10);const rendered=unit.mDestinyBox.children;
const before=shown.length;let stopped=false;
unit.bondNameTouch104({currentTarget:rendered[3],getTouch:()=>({}),stopPropagation:()=>stopped=true});
const output={before,shown,stopped,colors:[rendered[0].fontColor,rendered[2].fontColor],bottom:Math.max(...rendered.map(x=>x.y+x.height))};
unit.setDestinyTxts(null);output.cleared=unit.mBondEntries104.length;
console.log(JSON.stringify(output));'''
        result=self.run_js(script)
        self.assertEqual(result['before'],0);self.assertEqual(result['shown'],[{'title':'羁绊1','info':'效果1'}])
        self.assertTrue(result['stopped']);self.assertEqual(result['colors'],[0x888888,0x55E889]);self.assertLessEqual(result['bottom'],70.001)
        self.assertEqual(result['cleared'],0)

if __name__=='__main__':unittest.main()
