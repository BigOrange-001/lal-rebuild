"""Execute authored skin actions, permanent repeats and healing reactions."""
import json,re,shutil,unittest
from pathlib import Path
from test_avatar_passive import method_body
import test_playtest_client as harness

SOURCE=Path(__file__).resolve().parents[1]/'client/src/stages/137_Avatar.as'
@unittest.skipUnless(shutil.which('node'),'Node required for AS behavior checks')
class SkinSkills103ClientTests(unittest.TestCase):
    run_js=harness.PlaytestClientTests.run_js
    def run_case(self,code):
        script=r'''
const int=v=>Math.trunc(Number(v))||0,noop=()=>{};
const Tools={toInt:Math.trunc,clone:x=>x||{}};
const trace=noop,GameMapTools={gameTrace:noop},GlobalLanguageStr={getLanguageStr:()=>''};
const DisplayTools={getAttrs:id=>({id})};
const GlobalData={$mConfig_simple:{attack:[.1,.3,1.5,2,20,20,60,80,.5,3000,3000,3000,3000,3000,.5,.5,.5,.5,.05,.05,.5,1]}};
const GameMapConfig={LINE_POS:3000};
const layer={delayCall:noop};const GameMapLayer={gl:layer};
let contexts=[],events=[],picks=0;const abilityContexts=contexts;
function currentAbilityAttack(){return contexts[contexts.length-1]||null;}
function beginAbilityAttack(owner,kind){const c={owner,kind,damage:0};contexts.push(c);return c;}
function endAbilityAttack(c){if(currentAbilityAttack()!==c)throw Error('context leak');contexts.pop();}
function Buff(type,round,value=0){this.type=type;this.round=round;this.value=value;}
const Random={getRandom:n=>(picks++)%n};
let enemies=Array.from({length:4},(_,i)=>({id:'enemy'+i,team:2,hp:10000,hpMax:10000,line:0,pos:1600-100*i,ap:300,abilityIndex:10+i,buffs:{},getDamage(){return this.ap;},addBuff(kind,round,value=0){this.buffs[kind]=new Buff(kind,round,value);}}));
const unit={heroSkillOutputRate104:()=>1,equipmentPart104:(skill,part,value)=>value,id:'owner',team:1,otherTeam:2,line:0,pos:2200,hp:5000,hpMax:10000,abilityIndex:1,
abilityState:{},parallelVisualBatches:[],buffs:{},skillB:null,m_buff:{},showBuff:noop,abilityFeedback:noop,checkTalent:()=>0,flushParallelVisualBatch:noop,
abilityDirectMultiplier:()=>1,getTough:()=>0,getBookCombatBonus:()=>0,hasManualDotKind:()=>false,abilityRecordDamage:noop,
ap:300,abilityEntryAttack:0,getManualBattleStack:()=>0,getManualTimedStack:()=>0,
removeAllDebuff:noop,reline(line,pos){this.line=line;this.pos=pos;},
addBuff(kind,round,value=0){this.buffs[kind]=new Buff(kind,round,value);},
injured(amount,a,b,type){if(type===4)this.hp=Math.min(this.hpMax,this.hp+amount);},
abilityControl(target,kind,round,value=0){target.addBuff(kind,round,value);},
abilityHit(target,coef,type){if(!target||target.hp<=0)return false;
const c=currentAbilityAttack();const crit=!!this.forceCrit&&!!c.catCaptainCapture;
let damage=Math.trunc(this.getDamage()*coef*(crit?2:1));let actual=Math.min(target.hp,damage);
c.damage+=actual;if(crit)c.catCrits++;
events.push({id:target.id,coef,type,damage,hit:123+(this.abilityState.polarCastHit||0)});
target.hp-=actual;if(target.hp<=0){this.queueCatSkinKill();this.queueSantaKill();}return true;}};
let allies=[unit];
const GameMap={roundNum:0,actionDelay:0,currentMap:{roundNum:0,getAliveList(side){return (side===1?allies:enemies).filter(e=>e.hp>0);}}};
'''
        source=SOURCE.read_text('utf-8')
        params={
            'executeAbility':'kind,scale,effect,sourceSkill','executeAbilityBody':'kind,scale,effect,sourceSkill','beginParallelVisualBatch':'',
            'prepareParallelVisualTarget':'target,hit','endParallelVisualBatch':'batch','flushParallelVisualBatch':'',
            'abilityCandidates':'whichTeam,lane,position,distance,maximum,heroOnly=false,order="nearest",excluded=null,forward=false',
            'abilityDash':'target,enemySide=false','abilityAllEnemies':'','addPurifyCharges':'count',
            'executeCatSkin':'kind,scale,effect,sourceSkill','executePolarSkin':'kind,effect,sourceSkill',
            'queueCatSkinKill':'','polarBasicAttack':'','removeBuff':'param1,consume=false',
            'executeSantaSkin':'kind,effect,sourceSkill','queueSantaKill':'',
            'executeNurseSkin':'kind,sourceSkill','queueNurseHealing':'amount,overheal=0','abilityCanCast':'kind,distance',
            'absorbShieldDamage':'amount,factor',
            'getDamage':'param1=-1,param2=-1,param3=false'}
        for name,args in params.items():
            body=method_body(source,name)
            if name in ('executeCatSkin','executePolarSkin','executeSantaSkin','executeNurseSkin'):
                # Skill doubles expose the current node, matching the native API.
                body='if(sourceSkill && !sourceSkill.getNativeAction) sourceSkill.getNativeAction=function(){return this.skills[0]||[];};'+body
                body='if(sourceSkill && !sourceSkill.getNativeSetting) sourceSkill.getNativeSetting=function(k,f){return this[k] == null ? f : this[k];};'+body
            body=re.sub(r'for each\s*\(([^)]+) in ([^)]+)\)',r'for (\1 of \2)',body)
            body=re.sub(r'function\(([^)]*)\)',lambda m:'function('+re.sub(r':\w+','',m[1])+')',body)
            script+=f'unit.{name}=function({args}){{with(this){{{body}}}}};\n'
        # Execute the numeric injury path and its actual terminal hooks. The
        # omitted middle handles Flash rendering and lethal animations.
        body=method_body(source,'injured')
        body=body[:body.index('if(fightRes.parent)')]+body[body.index('if(param4 != 4) abilityRecordDamage'):]
        body=body.replace('param7.currentSkillKillContext.hitHeroes is Array','Array.isArray(param7.currentSkillKillContext.hitHeroes)')
        script+='function installInjury(target){Object.assign(target,{abilityDirectMultiplier:()=>1,getTough:()=>0,checkTalent:()=>0,getBookCombatBonus:()=>0,hasManualDotKind:()=>false,abilityRecordDamage:noop,absorbShieldDamage:unit.absorbShieldDamage,removeBuff:unit.removeBuff,queueNurseHealing:unit.queueNurseHealing});target.injured=function(param1,param2=1,param3={},param4=-1,param5=null,param6=false,param7=null,param8=null,dotKind=""){with(this){'+body+'}};}\n'
        script+=code
        return self.run_js(script)
    def test_cat_normal_locks_primary_hits_three_and_heals_only_own_skill(self):
        result=self.run_case('''const c=beginAbilityAttack(unit,'active');
unit.executeCatSkin('cat_n',1,'FX',{skills:[['manual_ability','cat_n',1,'FX',5000,.6,.5,.3]]});
endAbilityAttack(c);console.log(JSON.stringify({events,hp:unit.hp,pos:unit.pos,hitup:unit.buffs.hitup}));''')
        self.assertEqual([e['id'] for e in result['events']],['enemy0','enemy1','enemy2','enemy0'])
        self.assertEqual(result['hp'],5207);self.assertEqual(result['pos'],1725)
        self.assertEqual(result['hitup']['value'],5000);self.assertEqual(result['hitup']['round'],2)
    def test_cat_captain_counts_all_crits_then_adds_strength_and_two_charges(self):
        result=self.run_case('''enemies[1].line=1;enemies[2].line=2;unit.forceCrit=true;
const c=beginAbilityAttack(unit,'active');unit.executeCatSkin('cat_c',1,'FX',{skills:[]});endAbilityAttack(c);
console.log(JSON.stringify({events,buffs:unit.buffs,contexts:contexts.length}));''')
        self.assertEqual(len(result['events']),24)
        self.assertTrue(all(e['damage']==180 for e in result['events']))
        self.assertAlmostEqual(result['buffs']['strong']['value'],.72)
        self.assertEqual(result['buffs']['purify']['value'],2);self.assertEqual(result['contexts'],0)

    def test_cat_dispatch_runs_six_parallel_target_waves(self):
        result=self.run_case('''const starts=[],original=unit.abilityHit;
unit.abilityHit=function(target,coef,type){this.prepareParallelVisualTarget(target,true);starts.push(GameMap.actionDelay);
let ok=original.call(this,target,coef,type);GameMap.actionDelay+=.25;return ok;};
const c=beginAbilityAttack(unit,'active');unit.executeAbility('cat_c',1,'FX',{skills:[]});endAbilityAttack(c);
console.log(JSON.stringify({starts,end:GameMap.actionDelay,stack:unit.parallelVisualBatches.length}));''')
        self.assertEqual(result['starts'],[w*.25 for w in range(6) for _ in range(4)])
        self.assertEqual(result['end'],1.5);self.assertEqual(result['stack'],0)

    def test_veigar_precision_only_exists_during_captain_hit(self):
        result=self.run_case('''unit.getStar=()=>6;unit.abilityEnemies=()=>[enemies[0]];
unit.nativeAbilityNumber=(skill,kind,key,fallback)=>fallback;
unit.abilityHit=()=>events.push(unit.abilityState.veigarCastHit);
const skill={skillSetData:{id:'TEST'},getNativeSetting:(key,fallback)=>fallback};
const c=beginAbilityAttack(unit,'active');unit.executeAbility('veigar_c',1,'FX',skill);
const after=unit.abilityState.veigarCastHit;unit.abilityHit=()=>{throw Error('failed')};
try{unit.executeAbility('veigar_c',1,'FX',skill)}catch(e){}endAbilityAttack(c);
console.log(JSON.stringify([events,after,unit.abilityState.veigarCastHit]));''')
        self.assertEqual(result,[[30000],0,0])
    def test_cat_reentrant_kills_stop_at_five_and_reset_next_round(self):
        result=self.run_case('''enemies=Array.from({length:40},(_,i)=>({id:'e'+i,team:2,hp:1,line:i%3,pos:1000}));
unit.skillB={skills:[['cat_passive',.4,3,5]]};unit.queueCatSkinKill();let first=events.length;
unit.queueCatSkinKill();let second=events.length;GameMap.currentMap.roundNum++;
unit.queueCatSkinKill();console.log(JSON.stringify([first,second,events.length,unit.abilityState.catKillCount,contexts.length]));''')
        self.assertEqual(result,[15,15,30,5,0])
    def test_charged_purify_consumption_and_full_dispel(self):
        result=self.run_case('''unit.addPurifyCharges(2);unit.removeBuff('purify',true);let remaining=unit.buffs.purify.value;
unit.removeBuff('purify',true);let gone=!unit.buffs.purify;
unit.addPurifyCharges(2);unit.removeBuff('purify');console.log(JSON.stringify([remaining,gone,!unit.buffs.purify]));''')
        self.assertEqual(result,[1,True,True])
    def test_polar_normal_and_temporary_captain_precision(self):
        result=self.run_case('''enemies[0].ap=1000;enemies[0].pos=1000;enemies[1].pos=1299;enemies[2].pos=1301;enemies[3].line=1;
let c=beginAbilityAttack(unit,'active');unit.executePolarSkin('polar_n','FX',{skills:[['manual_ability','polar_n',1,'FX',100000,.35,.7]]});endAbilityAttack(c);
let normal=events.slice();events=[];c=beginAbilityAttack(unit,'active');unit.executePolarSkin('polar_c','FX',{skills:[]});endAbilityAttack(c);
console.log(JSON.stringify({normal,events,buffs:unit.buffs,hit:unit.abilityState.polarCastHit,enemyBuffs:enemies.map(e=>e.buffs)}));''')
        self.assertEqual(len(result['normal']),3);self.assertTrue(all(e['type']==1 and e['coef']==.7 for e in result['normal']))
        self.assertEqual([e['id'] for e in result['events']],['enemy0','enemy1'])
        self.assertTrue(all(e['type']==2 and e['coef']==3 and e['hit']==50123 for e in result['events']))
        self.assertEqual(result['hit'],0)
        self.assertEqual(result['buffs']['critup']['value'],100000)
        self.assertEqual(result['enemyBuffs'][0]['curse']['round'],1)
    def test_polar_first_basic_same_round_cap_and_skipped_round_decay(self):
        result=self.run_case('''unit.skillB={skills:[['polar_basic',.6,4]]};let counts=[];
for(let r of [0,0,1,2,3,4,7,20]){GameMap.currentMap.roundNum=r;unit.polarBasicAttack();counts.push(unit.abilityState.polarCount);}
console.log(JSON.stringify({counts,events}));''')
        self.assertEqual(result['counts'],[1,1,2,3,4,4,3,1])
        self.assertEqual(len(result['events']),8)
    def test_santa_kill_changes_next_cast_and_does_not_recast_immediately(self):
        result=self.run_case('''enemies=enemies.slice(0,2);enemies[0].hp=1;
unit.skillB={skills:[['santa_kill',2,1,.05]]};unit.skill0={skills:[['manual_ability','santa_n',1,'FX',1.3]]};
let c=beginAbilityAttack(unit,'active');unit.executeSantaSkin('santa_n','FX',unit.skill0);endAbilityAttack(c);
const first=events.length;const firstStacks=unit.abilityState.santaStacks;
c=beginAbilityAttack(unit,'active');unit.executeSantaSkin('santa_n','FX',unit.skill0);endAbilityAttack(c);
console.log(JSON.stringify({first,firstStacks,events,stacks:unit.abilityState.santaStacks,kills:unit.abilityState.santaKills,damage:unit.getDamage(),contexts:contexts.length}));''')
        self.assertEqual((result['first'],result['firstStacks']),(1,3))
        self.assertEqual(len(result['events']),3)
        self.assertEqual(result['events'][1]['damage'],448)
        self.assertEqual((result['stacks'],result['kills'],result['damage'],result['contexts']),(5,1,375,0))
    def test_santa_repeat_count_is_locked_and_each_repeat_retargets(self):
        result=self.run_case('''enemies=Array.from({length:20},(_,i)=>({id:'e'+i,hp:1,team:2,line:0,pos:1000}));
unit.skillB={skills:[['santa_kill',2,1,.05]]};unit.skill0={skills:[['manual_ability','santa_n',1,'FX',1.3]]};
let counts=[];for(let i=0;i<5;i++){let c=beginAbilityAttack(unit,'active');unit.executeSantaSkin('santa_n','FX',unit.skill0);endAbilityAttack(c);counts.push(events.length);}
console.log(JSON.stringify([counts,unit.abilityState.santaStacks,unit.abilityState.santaKills,contexts.length]));''')
        self.assertEqual(result,[[1,3,7,15,20],60,20,0])
    def test_santa_layers_multiply_other_buffs_in_the_real_attack_getter(self):
        result=self.run_case('''unit.abilityState.santaStacks=4;unit.buffs.strong={value:.5};
console.log(JSON.stringify(unit.getDamage()));''')
        self.assertEqual(result,540)

    def test_nurse_normal_heals_all_lanes_from_ap_and_procs_only_for_receiver(self):
        result=self.run_case('''installInjury(unit);unit.skillB={skills:[['nurse_healing',.4]]};
const friend=Object.assign({},unit,{id:'friend',hp:5000,line:2,buffs:{},abilityState:{},skillB:null});installInjury(friend);allies.push(friend);
enemies[1].line=1;enemies[2].line=2;for(const e of enemies)installInjury(e);
unit.executeNurseSkin('nurse_n',{skills:[['manual_ability','nurse_n',1,'FX',.7]]});
console.log(JSON.stringify({hp:allies.map(a=>a.hp),enemyHp:enemies.map(e=>e.hp),purified:allies.map(a=>!!a.buffs.purify),canCast:unit.abilityCanCast('nurse_n',3000),contexts:contexts.length}));''')
        self.assertEqual(result['hp'],[5210,5210])
        self.assertEqual(result['enemyHp'],[9916]*4)
        self.assertEqual(result['purified'],[True,True])
        self.assertTrue(result['canCast']);self.assertEqual(result['contexts'],0)

    def test_nurse_actual_healing_hook_counts_modified_overheal_before_hp_cap(self):
        result=self.run_case('''installInjury(unit);for(const e of enemies)installInjury(e);
unit.skillB={skills:[['nurse_healing',.4]]};unit.hp=9900;unit.hasManualDotKind=kind=>kind==='burn';
const healer={team:1,getBookCombatBonus:key=>key==='healing'?.5:0};
unit.injured(1000,1,{},4,healer,false,healer);
console.log(JSON.stringify({hp:unit.hp,enemyHp:enemies.map(e=>e.hp),pending:unit.abilityState.nursePending,contexts:contexts.length}));''')
        self.assertEqual(result,dict(hp=10000,enemyHp=[9160]*4,pending=[],contexts=0))

    def test_nurse_captain_self_target_produces_two_independent_heal_pulses(self):
        result=self.run_case('''installInjury(unit);for(const e of enemies)installInjury(e);
unit.skillB={skills:[['nurse_healing',.4]]};unit.hp=6000;
unit.executeNurseSkin('nurse_c',{skills:[]});
console.log(JSON.stringify({hp:unit.hp,enemyHp:enemies.map(e=>e.hp),bless:unit.buffs.bless,pending:unit.abilityState.nursePending,contexts:contexts.length}));''')
        self.assertEqual(result['hp'],10000)
        self.assertEqual(result['enemyHp'],[2400]*4)
        self.assertEqual(result['bless']['value'],0)
        self.assertEqual((result['pending'],result['contexts']),([],0))

    def test_nurse_captain_uses_health_ratio_and_caster_maximum_across_lanes(self):
        result=self.run_case('''installInjury(unit);for(const e of enemies)installInjury(e);
unit.skillB={skills:[['nurse_healing',.4]]};unit.hp=7000;
const friend=Object.assign({},unit,{id:'friend',hp:1000,hpMax:2000,line:2,buffs:{},abilityState:{},skillB:null});installInjury(friend);allies.push(friend);
unit.executeNurseSkin('nurse_c',{skills:[]});
console.log(JSON.stringify({hp:allies.map(a=>a.hp),enemyHp:enemies.map(e=>e.hp),blessed:allies.map(a=>!!a.buffs.bless)}));''')
        self.assertEqual(result,dict(hp=[10000,2000],enemyHp=[6800]*4,blessed=[True,True]))

if __name__=='__main__':unittest.main()
