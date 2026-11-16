"""Run actual UI method bodies with native widget stubs; no rendering claim."""
import json
import re
import subprocess
import unittest
from pathlib import Path
from test_avatar_passive import method_body
from test_skin_revision_native_104 import balanced

ROOT=Path(__file__).resolve().parents[1]


def method(source,name,params):
    body=method_body(source,name)
    body=re.sub(r'function\((.*?)\)',lambda m:'function('+re.sub(r':\w+','',m[1])+')',body)
    body=re.sub(r'([\w.]+) is Array',r'Array.isArray(\1)',body)
    body=re.sub(r'(\w+) is String',r'typeof \1 === "string"',body)
    while 'for each(' in body:
        a=body.index('for each(');b=balanced(body,a+8);left,right=body[a+9:b].split(' in ',1)
        body=body[:a]+'for ('+left+' of Object.values(('+right+') || {}))'+body[b+1:]
    return 'function('+params+'){with(this){'+body+'}}'


class AbyssUITests(unittest.TestCase):
    def test_inheritance_selectors_are_compiled_into_shipping_swf(self):
        config=json.loads((ROOT/'client/build.json').read_text('utf-8'))
        self.assertEqual(config['stage_count'],len(config['stages']))
        self.assertEqual(config['unique_class_count'],len({s['class'] for s in config['stages']}))
        by_class={s['class'].rsplit('.',1)[-1]:s for s in config['stages']}
        for name in ('PanelEquipAlchemySelect','PanelEquipAlchemyStuffSelect'):
            row=by_class[name]
            source=(ROOT/row['source']).read_text('utf-8')
            self.assertIn('$inheritMode',source)
        self.assertIn('checkInheritStuff',(ROOT/by_class['PanelEquipAlchemyStuffSelect']['source']).read_text('utf-8'))

    def test_alchemy_keeps_inheritance_and_relic_tabs_separate(self):
        source=(ROOT/'client/src/stages/181_PanelAlchemy.as').read_text('utf-8')
        script='''const assert=require('node:assert/strict'),int=Math.trunc;let errors=0,added=[];
const GlobalData={$userData:{lv:99},$center_height_curr:640,$mConfig_simple:{start_lv:Array(19).fill(50),show_id:Array(9).fill('alchemy_')}};
const GlobalFunction={checkGameFunIsOpenByType:()=>50,popError:()=>errors++};
const GlobalLanguageStr={getLanguageStr:()=>''};
const PanelEquipAlchemyStart={$inheritMode:false};
function PanelEquipAlchemy(){this.kind='equip';this.inherit=PanelEquipAlchemyStart.$inheritMode;}
function PanelAvatarTalent(){this.kind='talent';}
const PanelActivityExploration={createRerollView104:()=>({kind:'relic'})};
const panel={mTabBar:{selectedIndex:3,y:17},clearPanel:()=>{added=[];},addChildAt:p=>added.push(p),
_panelEquipAlchemy:null,_panelAvatarTalent:null,_abyssReroll104:null};
'''
        script+='panel.change='+method(source,'tabBar_Change','param1')+';\n'
        script+='''panel.change(null);assert.equal(added[0].kind,'equip');assert(added[0].inherit);
panel.mTabBar.selectedIndex=2;panel.change(null);assert.equal(added[0].kind,'relic');assert(!PanelEquipAlchemyStart.$inheritMode);
panel.mTabBar.selectedIndex=1;panel.change(null);assert.equal(added[0].kind,'equip');assert(!added[0].inherit);
GlobalData.$userData.lv=49;panel.mTabBar.selectedIndex=3;panel.change(null);assert.equal(added.length,0);assert.equal(errors,1);
panel.mTabBar.selectedIndex=2;panel.change(null);assert.equal(added[0].kind,'relic');'''
        result=subprocess.run(['node'],input=script,capture_output=True,text=True,encoding='utf-8',cwd=ROOT)
        self.assertEqual(result.returncode,0,result.stdout+'\n'+result.stderr)

    def test_enemy_preview_and_rest_leave(self):
        source=(ROOT/'client/src/abyss_ui_104.aspart').read_text('utf-8')
        rest=source.split('class AbyssRestPanel104',1)[1].split('class AbyssPoolPanel104',1)[0]
        enemy=source.split('class AbyssEnemyPanel104',1)[1].split('class AbyssRestPanel104',1)[0]
        # Both old and current backend samples supported; preview schema is tested server-side.
        preview=[{'aid':'A_1001_6','lv':99,'slv':5,'star':6,'line':2,'leader':True}]
        script='''const assert=require('node:assert/strict'),int=Math.trunc;
const calls=[],buttons=[],cards=[],noop=()=>{};
const AbyssCore104={run:{pool:{A_1001:{aid:'A_1001_6',quality:6,slv:10}}},
poolIds:()=>['A_1001'],heroName:aid=>aid,family:aid=>aid,isOrange:aid=>aid.endsWith('_6'),
send:(name,params,done)=>{calls.push({name,params});done({});},closeTop:()=>calls.push('map'),toast:noop};
function Sprite(){};function LOL_Scale9Button(){};
const panel={option:'skill',heroId:null,lx:0,iw:640,by:700,
addButton:(label,x,y,w,h,callback)=>{buttons.push({label,callback});return {x};},
addText:noop,addFrame:noop,selectMark:noop,addBox:noop,gray:noop,refresh:noop,bindHero:noop,
heroCard:(...args)=>{cards.push(args);return {};},bindInfo:noop};
'''
        script+='panel.reasonFor='+method(rest,'reasonFor','h')+';\n'
        script+='panel.build='+method(rest,'build','')+';panel.build();\n'
        script+='''assert(buttons.some(b=>b.label==='离开'));buttons.find(b=>b.label==='离开').callback();
assert.deepEqual(calls,[{name:'user.abyss_rest',params:{option:'leave'}},'map']);
'''
        script+='const enemyPreview='+method(source,'enemyPreview','r,n')+';\n'
        script+='const preview='+json.dumps(preview)+';\n'
        script+='''assert.equal(enemyPreview(null,{enemy_preview:preview}),preview);
assert.equal(enemyPreview(null,{enemies:preview}),preview);
assert.equal(enemyPreview({current_node:'x',battle:{orgin_team_b:preview,metadata:{node_id:'x'}}},{}),preview);
panel.enemies=preview;cards.length=0;
'''
        script+='panel.build='+method(enemy,'build','')+';panel.build();\n'
        script+='''assert.equal(cards.length,1);assert.equal(cards[0][0],'A_1001_6');assert.equal(cards[0][2],5);
assert.equal(cards[0][5],1);assert.equal(cards[0][6],true);
console.log('Native UI method fixtures: preview precedence/hero rendering and rest leave passed.');'''
        result=subprocess.run(['node'],input=script,capture_output=True,text=True,encoding='utf-8',cwd=ROOT)
        self.assertEqual(result.returncode,0,result.stdout+'\n'+result.stderr)

    def test_pool_bonds_follow_pool_rule(self):
        source=(ROOT/'client/src/abyss_ui_104.aspart').read_text('utf-8')
        script='''const assert=require('node:assert/strict'),int=Math.trunc;
const GlobalData={$mConfig_simple:{bonds_104:[
 {name:'Trio',families:['A_1','A_2','A_3']},
 {name:'Pair',families:['A_1','A_4']},
 {name:'Mixed',families:['A_2','A_5']},
 {name:'Far',families:['A_6','A_7','A_8','A_9']},
 {name:'None',families:['A_10','A_11']}]}};
const core={run:{pool:{A_1:{aid:'A_1_5'},A_2:{aid:'A_2_5'},A_3:{aid:'A_3_5'},A_5:{aid:'A_5_6'},A_6:{aid:'A_6_5'}}},
family:aid=>aid.split('_').slice(0,2).join('_'),heroName:aid=>aid.split('_').slice(0,2).join('_')};
'''
        script+='core.poolBonds='+method(source,'poolBonds','')+';\n'
        script+='''const list=core.poolBonds.call(core);const by=Object.fromEntries(list.map(b=>[b.name,b]));
assert.equal(list[0].name,'Trio');assert(by.Trio.active);
assert(!by.Pair.active);assert.deepEqual(by.Pair.missing,['A_4']);
assert(!by.Mixed.active);assert(by.Mixed.mixed);
assert.equal(by.Far.missing.length,3);assert(!('None' in by));
console.log('pool bond rule fixtures passed');'''
        result=subprocess.run(['node'],input=script,capture_output=True,text=True,encoding='utf-8',cwd=ROOT)
        self.assertEqual(result.returncode,0,result.stdout+'\n'+result.stderr)


if __name__=='__main__':unittest.main()
