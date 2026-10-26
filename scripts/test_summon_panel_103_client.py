"""Run every summon entry against the actual live Avatar stat getters."""
import json
import re
import subprocess
import unittest
from pathlib import Path

from test_avatar_passive import NODE, ROOT, method_body


HARNESS = r'''
const input=JSON.parse(require('fs').readFileSync(0,'utf8'));
const noop=()=>{},int=v=>Math.trunc(Number(v)||0),uint=int;
const Tools={toInt:v=>int(Number(Number(v).toFixed(5)))};
const added=[],aura={hp:1,ownGrowthValue:key=>key.startsWith('team_')?700:0};
const map={addAvatar(u){added.push(u);},getAliveList(){return [aura];},getFinalPos:(team,line,pos)=>pos};
const GameMap={currentMap:map,actionDelay:0},GameMapConfig={SUMMON_POS:200,LINE_POS:3000};
const GameMapLayer={gl:{effectLayer:{},delayCall:noop}};
const GameMapTools={gameTrace:noop},DisplayTools={getAttrs:()=>null};
const GlobalData={$mConfig_skill:{},$mConfig_avatar:{A_TEST:{modUnitType:'summon'}},modDefinitionId:id=>id};
function attach(target,source,names){for(const [name,params] of Object.entries(names))
 target[name]=eval('(function('+params+'){with(this){'+source[name]+'\n}})');}
function SkillSet(id){this.skillSetData={id};}
const getters={getHpMax:'param1=-1,param2=-1,param3=false',getDamage:'param1=-1,param2=-1,param3=false',
 getDePh:'param1=-1,param2=-1,param3=false',getDeMa:'param1=-1,param2=-1,param3=false',
 getPhysicalDefense:'param1,param2,param3,ignoreSunder',getMagicDefense:'param1,param2,param3,ignoreSunder',getHit:'',getFlee:'',getCrit:'',getTough:'',
 teamTalentFlat:'effect',getSummonPanelSnapshot:'',scaledSummonStat:'value,ratio,minimum',
 inheritSummonPanel:'owner,apRatio,hpRatio=-1,dePhRatio=-1,deMaRatio=-1,secondaryRatio=-1'};
function Avatar(id){
 Object.assign(this,{id,lv:99,hpMax:999999,hp:7,ap:888888,dePh:777777,deMa:666666,
 hit:0,flee:0,crit:0,tough:0,team:1,otherTeam:2,buffs:{},abilityState:{},abilityEntryAttack:0,
 initializingFightAttributes:false,summonStatSnapshot:false,manualAttackRangeOverride:NaN,
 getManualBattleStack:()=>0,getManualTimedStack:()=>0,goFight:noop,addBuff:noop,dead:noop,deadFast:noop});
 attach(this,input.avatar,getters);
 attach(this,input.avatar,{checkTalent:'param1,param2=false'});
 this.isValidSummonMultiplier=Avatar.isValidSummonMultiplier;
}
Avatar.isValidSummonMultiplier=eval('(function(ratio){'+input.avatar.isValidSummonMultiplier+'})');
const owner=new Avatar('A_1132_5');
Object.assign(owner,{lv:99,hpMax:10001,hp:53,ap:1001,dePh:501,deMa:401,hit:101,flee:103,crit:107,tough:109,
 team:1,line:0,pos:1500,manualSummonFamilies:{},
 buffs:{strong:{value:.5},weak:{value:.2},steel:{value:.4},sunder:{value:.25},armor:{value:.2},
 hitup:{value:11},fleeup:{value:13},critup:{value:17},toughup:{value:19}},
 getManualBattleStack:key=>({attack:.2,defense:.3,flee:7}[key]||0),getManualTimedStack:()=>.1,
 checkTalent:key=>({1:.1,2:.2,3:.3}[key]||0),getManualSummonSlots:()=>1,registerManualSummon:()=>true,
 avatarData:{id:'A_1132_5'},activeManualEffectMultiplier:()=>1,
 skill0:{skillSetData:{id:'S_621132_5'},getMechanismId:()=> 'S_621132_5',lv:4,isActive:()=>true}});
const enemy={hp:1000,line:0,pos:1700};
const panel=owner.getSummonPanelSnapshot();
const skill={avatar:owner,skillSetData:{id:'S_301209_5'},boundedSummons:[],
 hasBoundedSummonPolicy:()=>true,isHeimerTurretSkill:()=>true,isManualSummonPolicyAllowed:()=>true,
 getActionPolicy:()=>null,getCustomActionTargets:()=>[enemy],getActionPolicyArgs:()=>null,
 isNativeCloneSummonSkill:()=>false,isModEffectSequence:()=>true,modSelectTargets:()=>[enemy],modStepAnchors:{},
 getNativeSetting(key){return this.skillSetData[key];},getMechanismId(){return this.skillSetData.id;}};
attach(skill,input.skill,{getSummonCombatSnapshotApFactor:''});
let ratios=[.5,.5,.5,.5,.5];
if(input.route==='generic'){
 attach(skill,input.skill,{summonAction:'_loc20_,_loc14_=0,actionTargets=null,targetGroups=null'});
 skill.summonAction(['summon',.5,'A_TEST',2,'FX']);
}else if(input.route==='turret'){
 attach(skill,input.skill,{executeHeimerTurretSummon:'param1'});
 ratios=Array(5).fill(1.5);
 skill.executeHeimerTurretSummon(['summon_turret',1.5,'A_2001_4',2,0,0,0,2,0,0,'FX']);
}else if(input.route==='manual'){
 skill.skillSetData.manualSummonPolicy={skillId:skill.skillSetData.id,unitId:'A_TEST',familyKey:'test',maxAlive:1,
 apRatio:.4,hpRatio:.2,dePhRatio:.3,deMaRatio:.5,ttlOwnerTurns:2,attackRange:125,clearSkills:true};
 attach(skill,input.skill,{executeManualSummon:'param1,param2,param3,param4'});
 ratios=[.2,.4,.3,.5,.4];
 skill.executeManualSummon(['summon',.4,'A_TEST',2,'FX'],0,[],{});
}else if(input.route==='clone'){
 skill.skillSetData.id='S_631132_5';
 skill.skillSetData.manualClonePolicy={skillId:skill.skillSetData.id,familyKey:'manual-1132-shadow-clone',maxAlive:1,
 panelStatRatio:1.2,ttlOwnTurns:2,replaceOldest:true};
 attach(skill,input.skill,{executeManualNormalClone:'param1'});
 ratios=Array(5).fill(1.2);
 skill.executeManualNormalClone(['clone_normal','FX']);
}else if(input.route==='ability'){
 attach(owner,input.avatar,{abilitySummon:'aid,count,ratio,turns,key,focus=null,clone=false'});
 ratios=Array(5).fill(.35);owner.abilitySummon('A_TEST',1,.35,2,'test');
}else if(input.route==='mod'){
 attach(skill,input.skill,{executeModStep:'step,index'});
 ratios=Array(5).fill(.7);
 skill.executeModStep(['mod_step','summon','self',-1,0,0,0,0,'',0,0,'A_TEST',.7,2,1,false,1,'FX'],0);
}
function stats(u){return [u.getHpMax(),u.getDamage(),u.getDePh(),u.getDeMa(),u.getHit(),u.getFlee(),u.getCrit(),u.getTough()];}
const summon=added[0];if(!summon)throw Error('Summon not added: '+input.route);
const actual=stats(summon),talents=[1,2,3].map(k=>summon.checkTalent(k));
owner.ap*=2;owner.buffs={};const unchanged=stats(summon);
const fresh=new Avatar('A_TEST');fresh.inheritSummonPanel(owner,.5);
const invalid=new Avatar('A_TEST');const rejected=[0,NaN,Infinity,-1,101].map(r=>invalid.inheritSummonPanel(owner,r));
process.stdout.write(JSON.stringify({panel,ratios,actual,unchanged,talents,fresh:stats(fresh),rejected,hp:summon.hp}));
'''


def translated(source, name):
    body = method_body(source, name)
    body = re.sub(r'for each\s*\(([^)]+) in ([^)]+)\)', r'for (\1 of \2)', body)
    body = re.sub(r'new Vector\.<\w+>\(\)', '[]', body)
    return body


@unittest.skipUnless(NODE, 'Node is required for actual ActionScript methods')
class SummonPanelClientTests(unittest.TestCase):
    def run_route(self, root, route):
        av = (root / 'client/src/stages/137_Avatar.as').read_text('utf-8')
        sk = (root / 'client/src/stages/139_SkillSet.as').read_text('utf-8')
        av_names = ('getHpMax','getDamage','getDePh','getDeMa','getHit','getFlee','getCrit','getTough',
                    'teamTalentFlat','getSummonPanelSnapshot','scaledSummonStat','inheritSummonPanel',
                    'isValidSummonMultiplier','checkTalent','abilitySummon')
        if 'function getPhysicalDefense(' in av:
            av_names += ('getPhysicalDefense','getMagicDefense')
        sk_names = ['getSummonCombatSnapshotApFactor','executeHeimerTurretSummon','executeManualSummon','executeManualNormalClone']
        if route == 'mod':
            sk_names.append('executeModStep')
        methods = {name: translated(sk, name) for name in sk_names}
        branch = sk.rsplit('case "summon":', 1)[1].split('case "clone_normal":', 1)[0]
        branch = branch.replace('break;', 'return;').replace('new Vector.<Avatar>()', '[]')
        methods['summonAction'] = ('var limitedSummon,summonLevel,summonApFactor,_loc1_,_loc23_,_loc12_;'
                                  'var captainSummonMultiplier=1,_loc16_=GameMapLayer.gl,_loc26_=map;' + branch)
        proc = subprocess.run([NODE, '-e', HARNESS], input=json.dumps(dict(route=route,skill=methods,
                              avatar={name: translated(av, name) for name in av_names})),
                              capture_output=True,text=True,encoding='utf-8',timeout=15)
        self.assertEqual(proc.returncode, 0, proc.stderr)
        result = json.loads(proc.stdout)
        panel=result['panel']; hp,ap,dp,dm,secondary=result['ratios']
        keys=('hpMax','ap','dePh','deMa','hit','flee','crit','tough')
        expected=[max(1 if k in ('hpMax','ap') else 0,int(panel[k]*r))
                  for k,r in zip(keys,[hp,ap,dp,dm,*([secondary]*4)])]
        self.assertEqual(result['actual'], expected)
        self.assertEqual(result['unchanged'], expected)
        self.assertEqual(result['hp'], expected[0])
        self.assertEqual(result['talents'], [0,0,0])
        self.assertEqual(result['rejected'], [False]*5)
        self.assertNotEqual(result['fresh'][1], result['actual'][1])

    def test_all_native_summon_entries(self):
        for route in ('generic','turret','manual','clone','ability'):
            with self.subTest(route=route):
                self.run_route(ROOT,route)

    def test_custom_hero_effect_sequence_and_native_entries(self):
        root=ROOT.parents[1]/'development/lal-game-native-api-pr'
        if not root.is_dir():
            self.skipTest('Separate custom hero interface checkout is unavailable')
        for route in ('generic','turret','manual','clone','ability','mod'):
            with self.subTest(route=route):
                self.run_route(root,route)


if __name__ == '__main__':
    unittest.main()
