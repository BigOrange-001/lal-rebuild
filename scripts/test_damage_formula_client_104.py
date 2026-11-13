"""Actual AS formula/control bodies compared with the shared Python model."""
from pathlib import Path
import json
import subprocess
import unittest

from test_vital_bar_104 import method
from combat_math import damage_before_final
from combat_rules import attack_parameters, candidate_config, legacy_config
from test_combat_redesign import config

ROOT = Path(__file__).resolve().parents[1]
PART = 'client/src/combat_rules_104.aspart'


def runtime():
    data = json.loads((ROOT/'config/reconstruction/combat-rules-1.0.4.json').read_text('utf8'))
    script = '''const assert=require('assert'),int=Math.trunc;const trace=()=>{};
const stored=new Map(),LocalStore={getItemObj:k=>stored.get(k),setItemObj:(k,v)=>stored.set(k,v)};
let roll=99;const Random={getRandom:()=>roll},Tools={toInt:x=>Math.trunc(+Number(x).toFixed(5))};
const GameMapTools={gameTrace(){}},GameMap={actionDelay:0,currentAvatar:{id:1,team:1}};
const GameMapLayer={gl:{infoLayer:{popTextForAvatar(){}},delayCall(){}}};
const SoundManager={getOnlyExample:()=>({playSound(){}})},GlobalLanguageStr={getLanguageStr(){return ''}},missTween=()=>{};
const AvatarData={damageRate:(a,b)=>a%3===b-1?1.5:1};
const methods={damageChoiceLoaded104:false,legacyDamageChoice104:false,damageBattleStarted104:false,legacyBattleDamage104:false,
configuredTrueDamageRate104:NaN,
DAMAGE_CHOICE_KEY104:'damage-pref',MIN_DAMAGE_RATE:.1,SIGN_DAMAGE_RATE:1.5};
'''
    script += 'const GlobalData={$mConfig_simple:{attack:'+json.dumps(config()['system_simple']['attack'])+'},$mConfig:{combat_rules:'+json.dumps(data)+'}};'
    script += 'methods.DEFAULT_DAMAGE_RULES104='+json.dumps(data)+';'
    names = ['useLegacyDamage104','setLegacyDamage104','beginDamageRules104','ratioDamage104',
             'damageRuleNumber104','damageAttack104','defenseDamage104','trueSkillCoefficient104']
    for name in names:
        script += 'methods.'+name+'=('+method(PART,name)+').bind(methods);'
    avatar = (ROOT/'client/src/stages/137_Avatar.as').read_text('utf8')
    setter = avatar.split('public static function set REAL_DAMAGE_RATE(value:Number) : void {',1)[1].split('}',1)[0]
    script += "Object.defineProperty(methods,'REAL_DAMAGE_RATE',{get:()=>methods.damageAttack104()[1],set:function(value){with(methods){"+setter+"}}});"
    for name in ('countDamage','checkCrit','checkMiss'):
        script += 'methods.'+name+'=('+method('client/src/stages/137_Avatar.as',name)+').bind(methods);'
    script += 'const Avatar={useLegacyDamage104:methods.useLegacyDamage104,setLegacyDamage104:methods.setLegacyDamage104};'
    return script


class ClientFormulaTests(unittest.TestCase):
    def run_js(self, script):
        r = subprocess.run(['node'],input=script,text=True,capture_output=True,encoding='utf8')
        self.assertEqual(r.returncode,0,r.stdout+r.stderr)
        print(r.stdout.strip())

    def test_default_persistence_next_battle_switch_and_no_array_mutation(self):
        script = runtime()
        script += 'const toggle='+method('client/src/stages/151_PanelHelpSetting.as','toggleDamageFormula104')+';'
        self.run_js(script+'''
const original=GlobalData.$mConfig_simple.attack.slice();
assert(methods.ratioDamage104(),'no saved choice defaults to new');
assert.equal(methods.damageAttack104()[21],.66);assert.equal(methods.REAL_DAMAGE_RATE,.5);
methods.beginDamageRules104();let panel={mDisposed:false,mLegacyDamageCheckmark104:{visible:false}};
toggle.call(panel);assert(panel.mLegacyDamageCheckmark104.visible);assert(methods.ratioDamage104(),'current battle retains its model');
methods.damageChoiceLoaded104=false;methods.legacyDamageChoice104=false;assert(methods.useLegacyDamage104(),'legacy survives preference reload');
methods.beginDamageRules104();assert(!methods.ratioDamage104());assert.deepEqual(methods.damageAttack104(),original);assert.equal(methods.REAL_DAMAGE_RATE,.3);
toggle.call(panel);assert(!panel.mLegacyDamageCheckmark104.visible);assert(!methods.ratioDamage104());methods.beginDamageRules104();assert(methods.ratioDamage104());
assert.deepEqual(GlobalData.$mConfig_simple.attack,original,'both toggles leave base attack values intact');
panel.mDisposed=true;toggle.call(panel);assert(!methods.useLegacyDamage104());
console.log('New default, saved legacy switch, next-battle activation and exact base-array restoration passed');
''')

    def test_native_config_initialization_can_assign_true_damage_rate(self):
        self.run_js(runtime()+'''
const original=GlobalData.$mConfig_simple.attack.slice();
methods.REAL_DAMAGE_RATE=.3;assert.equal(methods.REAL_DAMAGE_RATE,.5);
methods.setLegacyDamage104(true);methods.beginDamageRules104();assert.equal(methods.REAL_DAMAGE_RATE,.3);
methods.REAL_DAMAGE_RATE=.4;assert.equal(methods.REAL_DAMAGE_RATE,.4);
assert.equal(methods.trueSkillCoefficient104(),2.5);
methods.setLegacyDamage104(false);methods.beginDamageRules104();assert.equal(methods.REAL_DAMAGE_RATE,.5);
assert.deepEqual(GlobalData.$mConfig_simple.attack,original);
console.log('Native config writes remain supported without changing the selected formula');
''')

    def test_native_damage_matches_both_server_models(self):
        rows = []
        cases = [(0,0,0),(1,0,0),(9,1000,100),(1000,1000,0),(1000,1000,350),
                 (1000,1000,700),(1001,1000,700),(1000,0,700),(1000,1000,10**9)]
        for legacy in (False,True):
            cfg = legacy_config(config()) if legacy else candidate_config(config())
            attack = attack_parameters(cfg)
            for raw,ap,defense in cases:
                for kind in (0,1,2,3,4,5):
                    for sign_b,share in ((1,1),(2,.9)):
                        expected = damage_before_final(raw,1,sign_b,kind,defense,defense,attack,share,
                                                       base_attack=ap,rules=cfg['combat_rules'])
                        rows.append([legacy,raw,ap,defense,kind,sign_b,share,expected])
        self.run_js(runtime()+'const rows='+json.dumps(rows)+';'+'''
for(const [legacy,raw,ap,defense,kind,sign,share,expected] of rows){
 methods.setLegacyDamage104(legacy);methods.beginDamageRules104();
 let a={ap,id:1,avatarData:{signType:1}},b={id:2,avatarData:{signType:sign},checkTalent:()=>0,getDePh:()=>defense,getDeMa:()=>defense,getDefenseAgainst:()=>defense};
 assert.equal(methods.countDamage(a,b,raw,kind,share)[0],expected,JSON.stringify({legacy,raw,ap,defense,kind,sign,share}));
}
methods.setLegacyDamage104(false);methods.beginDamageRules104();assert.equal(methods.trueSkillCoefficient104(),1.6);
methods.setLegacyDamage104(true);methods.beginDamageRules104();assert.equal(methods.trueSkillCoefficient104(),1/.3);
console.log(rows.length+' native damage cases match the Python ratio/legacy models');
''')

    def test_native_probabilities_and_fixed_critical(self):
        self.run_js(runtime()+'''
let a={id:1,checkTalent:()=>0,getCrit:()=>6000,getHit:()=>3000,emitModEvent(){}},b={id:2,buffs:{},checkTalent:()=>0,getTough:()=>3000,getFlee:()=>6000,getEffectiveActionType:()=>1,emitModEvent(){}};
methods.beginDamageRules104();roll=29;assert.equal(methods.checkCrit(a,b),2);roll=30;assert.equal(methods.checkCrit(a,b),1);
roll=17;assert(methods.checkMiss(a,b));roll=18;assert(!methods.checkMiss(a,b));
methods.setLegacyDamage104(true);methods.beginDamageRules104();roll=30;assert(Math.abs(methods.checkCrit(a,b)-(2+6000*.5/9000))<1e-8);
roll=44;assert(methods.checkMiss(a,b));roll=45;assert(!methods.checkMiss(a,b));
console.log('Actual client crit/miss boundaries and legacy critical multiplier passed');
''')


if __name__=='__main__':
    unittest.main()
