"""Execute actual Avatar merge/expiry code for the requested bless priority."""
import shutil
import re
import unittest
from pathlib import Path

from test_avatar_passive import method_body
import test_playtest_client as harness


@unittest.skipUnless(shutil.which('node'), 'Node is required for AS behavior checks')
class HeroSkills103ClientTests(unittest.TestCase):
    run_js = harness.PlaytestClientTests.run_js

    def test_hp_heal_action_reads_caster_maximum_without_attack_or_precision(self):
        source=(Path(__file__).resolve().parents[1]/'client/src/stages/139_SkillSet.as').read_text('utf-8')
        body=source.split('case "caster_hp_heal":',1)[1].split('case "timed_bless":',1)[0]
        body=body.rsplit('break;',1)[0]
        body=re.sub(r'(\bvar\s+\w+)\s*:\s*(?:Vector\.<\w+>|\w+)',r'\1',body)
        body=re.sub(r'for each\((var \w+) in ([^)]+)\)',r'for (\1 of \2)',body)
        script='''const Tools={toInt:Math.trunc},DisplayTools={getAttrs:id=>({id})},GameMap={actionDelay:0};
const out=[],avatar={hpMax:10000,getDamage(){throw Error('HP heal read attack');},getHit(){throw Error('HP heal read precision');}};
const target={injured(amount,crit,effect,type,healer,flag,source){out.push([amount,type,healer===avatar,source===avatar]);}};
const _loc14_=5,actionTargets={},targetGroups={};
function getCustomActionTargets(){return [target];}
for(const coefficient of [.12,.18]){const _loc20_=['caster_hp_heal',coefficient,'FX'];'''+body+'''}
console.log(JSON.stringify(out));'''
        self.assertEqual(self.run_js(script),[[1200,4,True,True],[1800,4,True,True]])

    def test_permanent_priority_timed_merge_and_expiry_in_real_avatar_methods(self):
        source = (Path(__file__).resolve().parents[1] / 'client/src/stages/137_Avatar.as').read_text('utf-8')
        script = '''const noop=()=>{},int=Math.trunc;
function Avatar(){}
function Buff(type,round,value){Object.assign(this,{type,round,value});}
Buff.LIST_BUFF=['bless'];Buff.LIST_DEBUFF=['curse','evil','stun'];
const GameMap={actionDelay:0,currentMap:{gameMapData:{win:[0]}}};
const GameMapLayer={gl:{delayCall:noop,infoLayer:{popTextForAvatar:noop}}};
const GlobalLanguageStr={getLanguageStr:()=>''};
const GlobalData={$mConfig_simple:{}};
const unit={buffs:{},hp:1000,abilityState:{},tryndUndyingActive:false,manualSkillDots:{},
currentAbilityAttack:()=>null,checkTalent:()=>0,tickManualLethalFloors:noop,showBuff:noop,
removeBuff(kind){delete this.buffs[kind];},removeAllDebuff:noop,removeAllGoodBuff:noop};
'''
        for name, params in [('addBuff', 'param1,param2,param3=0,param4=0,param5=-1,param6=null'), ('checkBuff', '')]:
            body = method_body(source, name).replace(' is Avatar', ' instanceof Avatar')
            script += f'unit.{name}=function({params}){{with(this){{{body}\n}}}};\n'
        script += '''const snapshot=()=>{let b=unit.buffs.bless;return b?[b.round,b.value]:null;};
let out=[];
unit.addBuff('bless',1,0);unit.addBuff('bless',3,1);out.push(snapshot());
for(let i=0;i<5;i++)unit.checkBuff();out.push(snapshot());
unit.buffs={};unit.addBuff('bless',3,1);unit.addBuff('bless',1,0);out.push(snapshot());
for(let i=0;i<5;i++)unit.checkBuff();out.push(snapshot());
unit.buffs={};unit.addBuff('bless',1,1);unit.addBuff('bless',2,1);
unit.addBuff('bless',1,1);out.push(snapshot());
unit.checkBuff();unit.checkBuff();out.push(snapshot());unit.checkBuff();out.push(snapshot());
unit.addBuff('bless',1,1);unit.removeAllGoodBuff=()=>{unit.buffs={};};
unit.removeAllGoodBuff();out.push(snapshot());
console.log(JSON.stringify(out));'''
        self.assertEqual(self.run_js(script), [[1, 0], [1, 0], [3, 0], [3, 0], [2, 1], [0, 1], None, None])


if __name__ == '__main__':
    unittest.main()
