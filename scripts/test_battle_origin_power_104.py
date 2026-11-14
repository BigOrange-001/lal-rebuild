"""Execute actual AS origin checks and equipment construction at terminal stars."""
import json,re,sys,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path[:0]=[str(ROOT/'scripts'),str(ROOT/'server')]
from test_avatar_passive import method_body
from test_skin_revision_native_104 import balanced
import test_playtest_client as client_harness
from gameplay_roster import GameplayRosterEquipment


def translate(body):
    body=re.sub(r'\bvar (\w+)\s*:(?:[\w.<>]+|\*)',r'var \1',body)
    body=re.sub(r'\s+as\s+\w+','',body)
    body=re.sub(r'(\w+(?:\[\w+\]|\.\w+)*) is Array',r'Array.isArray(\1)',body)
    for kind,js in [('Number','number'),('int','number'),('String','string'),('Boolean','boolean')]:
        body=re.sub(r'(\w+(?:\[\w+\])*) is '+kind,r'(typeof \1 === "'+js+'")',body)
    return body


class BattleOriginPowerTests(unittest.TestCase):
    def test_pvp_preview_uses_five_slots_without_mutating_saved_team_or_pve(self):
        source=(ROOT/'client/src/stages/179_PanelPVEembattleTeam.as').read_text('utf8')
        script='''const assert=require('assert');let calls=[];
const GlobalData={$isPVE:false,$isNoFriendToPVE:false,$isBattleOfThePeak:false,$tempTeam:['a','b','c','d','e','f']};
const GlobalFunction={getTeamPower:(team,helper)=>{calls.push([team.slice(),helper]);return team.length*100}};
const GlobalLanguageStr={getLanguageStr:()=>''},Tools={formateNum:String};
const unit={mTxt_power:{}};
'''
        script+='unit.showPower=function(){with(this){'+translate(method_body(source,'showPower'))+'}};\n'
        script+='''unit.showPower();assert.equal(unit.mTxt_power.text,'500');assert.equal(calls[0][0].length,5);
assert.equal(GlobalData.$tempTeam.length,6);calls=[];
GlobalData.$isPVE=true;GlobalData.$tempHelpAvatar={avatar:'helper'};
unit.showPower();assert.equal(calls[0][0].length,6);assert.equal(calls[0][1],GlobalData.$tempHelpAvatar);
console.log(JSON.stringify({passed:true}));'''
        self.assertEqual(client_harness.PlaytestClientTests.run_js(self,script),{'passed':True})

    def test_origin_float_roundoff_passes_but_real_stat_and_skill_changes_fail(self):
        for file in ('044_GameMapTools.as','081_GameMapTools.as'):
            source=(ROOT/'client/src/stages'/file).read_text('utf8')
            script='''let mismatches=[];const unit={rememberOriginMismatch:(...x)=>mismatches.push(x),gameTrace:()=>{}};\n'''
            for name,args in [('originValuesMatch','clientValue,serverValue'),('compareData','param1,param2,param3=""')]:
                script+='unit.'+name+'=function('+args+'){with(this){'+translate(method_body(source,name))+'}};\n'
            script+='''const assert=require('assert');
for(const [a,b] of [[2.0678763998000003,2.0678763997999994],[1.4131200000000002,1.4131199999999948],[26858.690884533302,26858.690884533273],[1.1040100499999999,1.104010049999998]]){
 assert(unit.compareData({skill:{skills:[[a]]}},{skill:{skills:[[b]]}},'teamA[2]'));
}
assert.equal(mismatches.length,0);
assert(!unit.compareData({hp:2000000000},{hp:2000000001},'teamA[0]'));
assert.equal(mismatches.at(-1)[0],'teamA[0].hp');
assert(!unit.compareData({skill:{skills:[[2.0678764]]}},{skill:{skills:[[2.0679]]}},'teamA[2]'));
assert(!unit.compareData({skills:[1,2]},{skills:[1,2,3]},'teamA[0]'));
assert(!unit.compareData({value:Infinity},{value:-Infinity},'teamA[0]'));
assert(!unit.originValuesMatch(NaN,NaN));
assert(unit.compareData({talent:null},{talent:null}));
console.log(JSON.stringify({passed:true}));'''
            self.assertEqual(client_harness.PlaytestClientTests.run_js(self,script),{'passed':True})

    def test_terminal_equipment_constructor_retains_all_existing_phase_gains(self):
        source=(ROOT/'client/src/stages/084_Equip.as').read_text('utf8')
        pos=source.index('public function Equip(');start=source.index('{',pos)
        constructor=translate(source[start+1:balanced(source,start)]).replace('super();','')
        script='''const int=Math.trunc;const data=JSON.parse(require('fs').readFileSync(0,'utf8'));
const GlobalData={$mConfig_simple:{equip_alchemy:data.table}};
const EquipManager={getOnlyExample:()=>({getData:id=>({id})})};
const unit={m_data:null,my_data:null,id:null,_Properties_rate:1,init:()=>{}};\n'''
        script+='unit.getEquipAlchemyRate=function(param1,param2){with(this){'+translate(method_body(source,'getEquipAlchemyRate'))+'}};\n'
        script+='unit.construct=function(param1,param2=null){with(this){'+constructor+'}};\n'
        script+='''const assert=require('assert');for(const row of data.rows){
 unit.construct('eq0',row.item);assert(Math.abs(unit._Properties_rate-row.expected)<1e-12);
 if(row.star===8)assert(unit._Properties_rate>1,'terminal-star rate was discarded');
}
unit.construct('eq0',{eid:'E_1011_6',alchemy:null});assert.equal(unit._Properties_rate,1);
unit.construct('eq0',{eid:'E_1011_6'});assert.equal(unit._Properties_rate,1);
console.log(JSON.stringify({checked:data.rows.length}));'''
        table={'star_lv':7,'phase':{f'{s}_{p}':[1.12,1,1] for s in range(1,8) for p in range(3)}}
        roster=GameplayRosterEquipment.__new__(GameplayRosterEquipment)
        roster.simple={'equip_alchemy':table}
        rows=[]
        for base in range(1,7):
            for star in range(base,9):
                for phase in ([0] if star==8 else [0,1,2]):
                    item={'eid':f'E_1001_{base}','alchemy':[phase,star-base]}
                    rows.append(dict(item=item,star=star,expected=roster._equip_alchemy_rate(item,0)))
        self.assertEqual(client_harness.PlaytestClientTests.run_js(self,script,dict(table=table,rows=rows)),{'checked':len(rows)})


if __name__=='__main__':unittest.main()
