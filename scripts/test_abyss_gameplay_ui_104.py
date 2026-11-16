"""Gameplay-batch UI fixtures (map v2, up-to-N picks, codex, 副本 tab, relic tab).

Runs the real AS method bodies under node with widget stubs. Proves branching and
data flow only; layout, art and touch still need the device.
"""
import json
import subprocess
import unittest
from pathlib import Path

from test_abyss_ui_104 import method

ROOT = Path(__file__).resolve().parents[1]
PART = (ROOT / 'client/src/abyss_ui_104.aspart').read_text('utf-8')


def section(start, end):
    return PART.split(start, 1)[1].split(end, 1)[0]


def run(script):
    result = subprocess.run(['node'], input=script, capture_output=True, text=True, encoding='utf-8', cwd=ROOT)
    return result.returncode, result.stdout + '\n' + result.stderr


PRELUDE = '''const assert=require('node:assert/strict'),int=Math.trunc,noop=()=>{};
function Quad(w,h,c){this.w=w;this.h=h;}
function Sprite(){this.children=[];this.addChild=c=>this.children.push(c);}
const Starling={juggler:{delayCall:(f)=>f(),add:noop,removeTweens:noop}};
'''


class GameplayUITests(unittest.TestCase):
    def test_choice_takes_one_to_count_and_always_offers_skip(self):
        choice = section('class AbyssChoicePanel104', 'class AbyssTeamPanel104')
        script = PRELUDE + '''const sent=[],buttons=[];let mapReturns=0;
const options=[1,2,3,4,5,6].map(i=>({id:'A_'+i,aid:'A_'+i+'_5',slv:5}));
const AbyssCore104={run:{pool:{},pending_choice:{options,count:3,can_skip:false}},poolCount:()=>5,poolCap:()=>20,
heroName:a=>a,isOrange:()=>false,heroInfoLines:()=>[],COLOR_TITLE:0,COLOR_ORANGE:0,COLOR_PURPLE:0,COLOR_TEXT:0,
send:(m,p,d)=>{sent.push([m,p]);d({});},continueRun:()=>mapReturns++,toast:noop};
const panel={selected:[],focus:null,lx:0,iw:640,by:900,addText:noop,addBox:noop,selectMark:noop,
heroCard:()=>({}),bindPick:noop,addButton:(label,x,y,w,h,fn,enabled)=>{buttons.push({label,fn,enabled});return {};}};
'''
        script += 'panel.title=' + method(choice, 'panelTitle', '') + ';\n'
        script += 'panel.build=' + method(choice, 'build', '') + ';\n'
        script += '''assert.equal(panel.title(),'最多选择3名英雄');
panel.build();
let skip=buttons.find(b=>b.label.startsWith('跳过'));assert(skip,'skip shown even if a legacy save says can_skip=false');
let join=buttons.find(b=>b.label.startsWith('先点选'));assert.equal(join.enabled,false);
for(const n of [1,2,3]){buttons.length=0;panel.selected=options.slice(0,n).map(o=>o.id);panel.build();
 join=buttons.find(b=>b.label.startsWith('加入'));assert.equal(join.label,'加入阵容池（'+n+' 名）');assert.equal(join.enabled,true);}
join.fn();assert.deepEqual(sent.pop(),['user.abyss_choose',{heroes:['A_1','A_2','A_3']}]);
buttons.find(b=>b.label.startsWith('跳过')).fn();assert.equal(sent.pop()[0],'user.abyss_skip');
assert.equal(mapReturns,2,'both choosing and skipping restore the map');
console.log('choice ok');'''
        code, out = run(script)
        self.assertEqual(code, 0, out)

    def test_map_positions_by_col_draws_only_next_and_shows_every_type(self):
        mp = section('class AbyssMapPanel104', '// ---------------------------------------------------------------- pick heroes')
        nodes = []
        for layer, cols in ((1, [0, 2]), (2, [1, 3])):
            for c in cols:
                nodes.append({'id': f'1-{layer}-{c}', 'act': 1, 'layer': layer, 'col': c,
                              'type': 'weak', 'next': [], 'completed': False})
        nodes[0]['next'] = ['1-2-1']
        nodes[1]['next'] = ['1-2-1', '1-2-3']
        nodes[2]['next'] = ['1-7-0']
        nodes[3]['next'] = ['1-7-0']
        nodes.append({'id': '1-7-0', 'act': 1, 'layer': 7, 'col': None, 'type': 'rest', 'next': ['1-8-0'], 'completed': False})
        nodes.append({'id': '1-8-0', 'act': 1, 'layer': 8, 'col': None, 'type': 'boss', 'next': [], 'completed': False})
        nodes[2]['type'] = 'elite'
        script = PRELUDE + '''const COLUMNS=4,TYPE_NAMES={"weak":"弱敌","normal":"普通战","elite":"精英战","rest":"休息处","boss":"Boss"};
const lines=[],buttons=[];const map=''' + json.dumps(nodes) + ''';
const run={map,retries:20,difficulty:1,current_node:null,available_nodes:['1-1-0','1-1-2'],status:'active'};
const GlobalFunction={createImage:()=>({})};
const AbyssCore104={run,retriesText:()=>'20',poolCount:()=>5,poolCap:()=>20,COLOR_TITLE:0,COLOR_DIM:0,
node:id=>map.find(n=>n.id===id),route:noop,openNodeStep:noop,toast:noop,open:noop,confirmAbandon:noop};
const body=new Sprite();
const panel={lx:0,iw:640,by:900,body,addText:noop,gray:noop,
line:(x1,y1,x2,y2)=>lines.push([x1,y1,x2,y2]),
addButton:(label,x,y,w,h)=>{const b={label,x,y,w,h};buttons.push(b);return b;}};
'''
        script += 'panel.currentAct=' + method(mp, 'currentAct', 'r') + ';\n'
        script += 'panel.addNode=' + method(mp, 'addNode', 'n,p,r,available,rowGap') + ';\n'
        script += 'panel.build=' + method(mp, 'build', '') + ';panel.build();\n'
        script += '''const nodeButtons=buttons.filter(b=>b.label!=='阵容池'&&b.label!=='放弃本局');
assert.equal(nodeButtons.length,6);
assert.deepEqual(nodeButtons.map(b=>b.label).sort(),['Boss','休息处','弱敌','弱敌','弱敌','精英战'].sort());
const cx=b=>b.x+b.w/2;const area=600;
const byLabel=nodeButtons.filter(b=>b.label!=='Boss'&&b.label!=='休息处');
const xs=byLabel.map(cx).sort((a,b)=>a-b);
assert.deepEqual(xs.map(x=>Math.round((x-20)/area*4-0.5)),[0,1,2,3]);
const rest=nodeButtons.find(b=>b.label==='休息处');assert.equal(Math.round(cx(rest)),320);
assert.equal(lines.length,6,'one line per real next edge');
console.log('map ok');'''
        code, out = run(script)
        self.assertEqual(code, 0, out)

    def test_codex_catalogue_uses_excluded_families(self):
        codex = section('class AbyssCodexPanel104', '// ---------------------------------------------------------------- confirm')
        script = PRELUDE + '''const GlobalData={$mConfig_avatar:{A_1001_5:{},A_1001_6:{},A_1139_5:{},A_190001_5:{},A_1210_6:{},A_2001_5:{},A_1002_4:{}}};
const AbyssCore104={cfg:()=>({excluded_families:['A_1139','A_190001'],skin_orange_only:['A_1210_6','A_1212_6']}),
family:aid=>aid.split('_').slice(0,2).join('_')};
'''
        script += 'const catalogue=' + method(codex, 'catalogue', '') + ';\n'
        script += '''assert.deepEqual(catalogue(),['A_1001_5','A_1210_6','A_1212_6']);console.log('codex ok');'''
        code, out = run(script)
        self.assertEqual(code, 0, out)

    def test_pve_abyss_tab_never_touches_guild_branch(self):
        source = (ROOT / 'client/src/stages/054_PanelCenterPVE.as').read_text('utf-8')
        script = PRELUDE + '''let shown=0,hidden=0,updated=0;
const GlobalData={$tempPVE_type_id:1,$tempPVE_type:'status_pve_hard'};
const GlobalFunction={getPveTypeById:i=>['status_pve_normal','status_pve_hard','status_pve_activities','status_pve_guild'][i]};
const PanelCenterPVE={$abyssTab104:false};const ABYSS_TAB_104=3;let $abyssTab104=false;
const panel={mTabBar:{selectedIndex:3},mImg_left:{},mImg_right:{},mBtn_ran:{},
showAbyss104:()=>shown++,hideAbyss104:()=>hidden++,update:()=>updated++,activeUpdate:()=>updated++};
'''
        script += 'panel.change=' + method(source, 'tabBar_changeHandler', 'param1') + ';\n'
        script += '''panel.change(null);
assert.equal(shown,1);assert.equal(updated,0);assert.equal(GlobalData.$tempPVE_type_id,1);assert.equal(GlobalData.$tempPVE_type,'status_pve_hard');
panel.mTabBar.selectedIndex=0;panel.change(null);
assert.equal(hidden,1);assert.equal(updated,1);assert.equal(GlobalData.$tempPVE_type,'status_pve_normal');
console.log('pve ok');'''
        code, out = run(script)
        self.assertEqual(code, 0, out)

    def test_equip_base_relic_tab_keeps_native_function_id(self):
        source = (ROOT / 'client/src/stages/064_PanelEquipBase.as').read_text('utf-8')
        script = PRELUDE + '''const added=[];const GlobalData={$tempEquipFunId:2,$center_height_curr:960};const RELIC_TAB_104=5;
function PanelEquipSelect(){this.kind='select';}function PanelEquipSellSelect(){this.kind='sell';}
const PanelActivityExploration={createRelicManageView104:h=>({kind:'relic',h})};
const panel={mTabBar:{selectedIndex:5,y:17},clearPanel:noop,addChild:p=>added.push(p)};
'''
        script += 'panel.change=' + method(source, 'tabBar_Change', 'param1') + ';\n'
        script += '''panel.change(null);assert.equal(added[0].kind,'relic');assert.equal(GlobalData.$tempEquipFunId,2);
panel.mTabBar.selectedIndex=1;panel.change(null);assert.equal(added[1].kind,'select');assert.equal(GlobalData.$tempEquipFunId,2);
panel.mTabBar.selectedIndex=4;panel.change(null);assert.equal(added[2].kind,'sell');assert.equal(GlobalData.$tempEquipFunId,5);
console.log('equip ok');'''
        code, out = run(script)
        self.assertEqual(code, 0, out)

    def test_relic_ui_has_no_bag_or_detail_popups_and_mode_has_no_relic_button(self):
        self.assertNotIn('AbyssRelicBagPanel104', PART)
        self.assertNotIn('AbyssRelicDetailPanel104', PART)
        entry = section('class AbyssEntryPanel104', 'class AbyssMapPanel104')
        self.assertNotIn('addButton("深渊遗物"', entry)
        result = section('class AbyssResultPanel104', 'class AbyssRelicPickPanel104')
        self.assertIn('"去装备",lx + 70,by - 90,190,66,AbyssCore104.goEquip', result)
        host = (ROOT / 'client/src/stages/102_PanelActivityExploration.as').read_text('utf-8').split('// BEGIN ABYSS_UI_104', 1)[0]
        self.assertNotIn('mBtn_Abyss104', host)


if __name__ == '__main__':
    unittest.main()
