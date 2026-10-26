"""Execute the actual AS DOT tick and pre-render injury calculation together."""
import json,re,shutil,unittest
from pathlib import Path
from test_avatar_passive import method_body
import test_playtest_client as harness

SOURCE=Path(__file__).resolve().parents[1]/'client/src/stages/137_Avatar.as'
@unittest.skipUnless(shutil.which('node'),'Node required for client method execution')
class DotRulesClientTests(unittest.TestCase):
    run_js=harness.PlaytestClientTests.run_js
    def run_case(self,setup,actions):
        source=SOURCE.read_text('utf-8')
        code=r'''
const int=Math.trunc,noop=()=>{},trace=noop;
const Tools={toInt:Math.trunc,clone:x=>x||{}};
const GlobalLanguageStr={getLanguageStr:()=>''};
const DisplayTools={getAttrs:()=>({})};
const GameMapTools={gameTrace:noop};
const layer={delayCall:noop,infoLayer:{popTextForAvatar:noop,popInjuredForAvatar:noop}};
const GameMapLayer={gl:layer};
const attack=[.1,.3,1.5,2,20,20,60,80,.5,3000,3000,3000,3000,3000,.5,.5,.5,.5,.05,.05,.5,1];
const GlobalData={$mConfig_simple:{attack,battle:[40,3000,200,500,0,0]}};
const GameMap={actionDelay:0,currentMap:{gameMapData:{win:[0]}}};
const unit={id:'test',hp:10000,hpMax:10000,team:1,buffs:{},manualSkillDots:{},abilityState:{},m_buff:null,
 tryndUndyingActive:false,abilityDirectMultiplier:()=>1,getTough:()=>0,checkTalent:()=>0,
 getBookCombatBonus:()=>0,tickManualLethalFloors:noop,
 getDePh:()=>{throw Error('DOT read physical defense');},getDeMa:()=>{throw Error('DOT read magic defense');},
 removeBuff:function(kind){delete this.buffs[kind];}};
GameMap.currentAvatar=unit;
const caster={team:2,getBookCombatBonus:()=>0};
'''
        for method,params in [('hasManualDotKind','param1'),('absorbShieldDamage','amount,factor'),('checkBuff','')]:
            body=method_body(source,method)
            code+=f'unit.{method}=function({params}){{with(this){{{body}}}}};\n'
        body=method_body(source,'injured')
        body=body[:body.index('if(fightRes.parent)')]
        body=body.replace('param7.currentSkillKillContext.hitHeroes is Array','Array.isArray(param7.currentSkillKillContext.hitHeroes)')
        code+='unit.injured=function(param1,param2=1,param3={},param4=-1,param5=null,param6=false,param7=null,param8=null,dotKind=""){with(this){'+body+'return param1;}};\n'
        code+=setup+'\n'+actions+'\nconsole.log(JSON.stringify({hp:unit.hp,buffs:unit.buffs,dots:unit.manualSkillDots}));'
        return self.run_js(code)
    def test_native_poison_and_burn_are_not_rescaled_or_defended(self):
        poison=self.run_case('unit.buffs.poison={type:"poison",value:100,round:1};','unit.checkBuff();')
        self.assertEqual(poison['hp'],9280)
        self.assertEqual(poison['buffs'],{})
        burn=self.run_case('unit.buffs.burn={type:"burn",value:100,round:1};','unit.checkBuff();')
        self.assertEqual(burn['hp'],9900)
    def test_manual_poison_last_tick_still_has_vulnerability(self):
        result=self.run_case('unit.manualSkillDots.one={kind:"poison",apTick:100,hpMaxFraction:0,damageType:2,round:1,source:caster};','unit.checkBuff();')
        self.assertEqual(result['hp'],9880);self.assertEqual(result['dots'],{})
    def test_bleed_and_phantasm_conserve_damage_when_breaking_shield(self):
        for kind in ('bleed','phantasm'):
            for shield,loss,remaining in [(1,99,0),(150,50,0),(300,0,0),(400,0,100)]:
                with self.subTest(kind=kind,shield=shield):
                    result=self.run_case(f'unit.buffs.shield={{value:{shield},round:3}};',f'unit.injured(100,1,{{}},6,caster,false,caster,null,"{kind}");')
                    self.assertEqual(result['hp'],10000-loss)
                    self.assertEqual(result['buffs'].get('shield',{}).get('value',0),remaining)
    def test_book_burn_reduces_healing_but_shield_is_not_healing(self):
        result=self.run_case('unit.hp=5000;unit.manualSkillDots.one={kind:"burn",round:3,bookRemaining:300,bookTicks:3};','unit.injured(100,1,{},4,caster,false,caster);')
        self.assertEqual(result['hp'],5060)

if __name__=='__main__':unittest.main()
