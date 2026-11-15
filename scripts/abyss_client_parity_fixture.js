// Native AS methods execute unchanged apart from type/iteration syntax.
// Presentation and unrelated hero effects have neutral fixture primitives.
const assert = require('node:assert/strict');
const input=JSON.parse(require('node:fs').readFileSync(0,'utf8')),docs=input.docs;
const methods={},noop=()=>{},int=x=>Math.trunc(Number(x)||0),Tools={toInt:x=>int(Number(Number(x).toFixed(5))),clone:x=>x};
const trace=noop,GameMapTools={gameTrace:noop};
const GameMapConfig={LINE_POS:3000,lineToPixel:()=>0,posToPixel:()=>0};
const GlobalLanguageStr={getLanguageStr:()=>''},DisplayTools={getAttrs:()=>({}),addBullet:noop};
const GlobalData={$mConfig_simple:{},skillBoo:false};
const layer={delayCall:noop,effectLayer:{},infoLayer:new Proxy({},{get:()=>noop})};
const GameMapLayer={gl:layer};
const AvatarData={damageRate:()=>1};
const SIGN_DAMAGE_RATE=1.5,REAL_DAMAGE_RATE=.5;
let MIN_DAMAGE_RATE=.1;
const ratioDamage104=()=>false;
const GameMap={roundNum:0,actionDelay:0,damageNum:0,currentAvatar:null,currentMap:null};
let roster=[],context=null,attack=[],rngCalls=0,attackContexts=0;
const Random={getRandom:()=>{rngCalls++;return 99;}};
const currentAbilityAttack=()=>context;
const beginAbilityAttack=(owner,kind)=>{attackContexts++;return context={owner,kind};};
const endAbilityAttack=()=>{context=null;};
class Buff {constructor(type,round,value){Object.assign(this,{type,round,value});}}
Buff.LIST_DEBUFF=['stun','silence','weak','sunder','poison','burn','curse','taunt','root'];
/*METHODS*/
/*SUMMON_POLICY*/
const Avatar=methods;
function unit(data){
 const u={...methods,id:data.aid,abyssToken104:data.instance_id,hp:data.hp,hpMax:data.hp_max,
 ap:data.ap,dePh:data.de_ph,deMa:data.de_ma,line:data.line,pos:data.pos,team:data.team||1,otherTeam:data.team===2?1:2,
 isLeader:!!data.leader,skill0:null,skill1:data.leader_skill?{m_cooldownNum:data.leader_skill.pl[0]}:null,skillB:null,
 buffs:{},abilityState:{},abilitySerial:0,manualSkillDots:{},kaisaRoot104:null,kaisaCast104:0,skin2:{},__avatar:true,avatarData:{signType:0,skill_diff:0},fightRes:{parent:null},offset:0,
 fxPulse104:noop,beginParallelVisualBatch:noop,endParallelVisualBatch:noop,abilityControl:noop,
 abilityFeedback:noop,removeIndependentShields104:noop,
 currentSkillKillContext:null,manualSkillDamageCapture:null,manualLethalFloor:null,tryndUndyingActive:false,
 dotPopup104:false,abyssReduction104:0,abyssRevived104:false,abyssRecovered104:false,
 abyssDodgeRound104:-1,abyssDodgeCount104:0,abyssDots104:null,abyssRelicA104:null,
 equipPassives104:data.equip_passives||null,
 abilityDirectMultiplier:()=>1,damageAttack104:()=>attack,checkTalent:()=>0,getTough:()=>0,
 getDamage(){return this.ap;},getHpMax(){return this.hpMax;},getType:()=>1,getDePh:()=>0,getDeMa:()=>0,
 getDefenseAgainst:()=>0,getRecoveryTalentMultiplier:()=>1,
 getBookCombatBonus:()=>0,skin2Incoming:v=>v,yasuoDamage104:v=>v,yasuoImmune104:()=>false,
 hasManualDotKind(k){return !!this.buffs[k]||this.hasAbyssDot104(k);},skin2Lethal:noop,s2Family:()=>0,
 recordStatistics104:noop,emitModEvent:noop,yasuoCritical104:noop,abilityRecordDamage:noop,
 refreshHp:noop,dead:noop,showBuff:noop,queueNurseHealing:noop,queueVitalBar104:noop,
 showCurseImpact:noop,blessFade:noop,blessCure:noop,kaisaNotifyStun104:noop,
 removeAllDebuff(){for(const k of Buff.LIST_DEBUFF)delete this.buffs[k];this.abyssDots104=null;},
 getSummonPanelSnapshot(){return {hpMax:this.hpMax,ap:this.ap,dePh:this.dePh,deMa:this.deMa,hit:0,flee:0,crit:0,tough:0};}
 };
 for(const key of ['abyssEvents104','abyssOrigin104'])Object.defineProperty(u,key,{get:()=>methods[key],set:v=>methods[key]=v});
 return u;
}
// Backend clamps dead HP; AIR retains negative HP for death animation only.
function state(){return Object.fromEntries(roster.map(u=>[u.abyssToken104,{hp:Math.max(0,u.hp),hp_max:u.hpMax,ap:u.ap,
 shield:u.shieldValue104(),buffs:Object.values(u.buffs).map(b=>b.type).sort(),
 leader_preparation:u.leaderPrepared?u.skill1.m_cooldownNum:null}]));}
let passed=0;
for(const doc of docs){
 attack=Array(24).fill(0);attack[13]=1;Object.entries(doc.attack_overrides).forEach(([k,v])=>attack[k]=v);
 roster=[...doc.input.team_a.map(d=>unit({...d,team:1})),...doc.input.team_b.map(d=>unit({...d,team:2}))];
 GameMap.currentMap={roundNum:0,getAliveList:t=>roster.filter(u=>u.team===t&&u.hp>0)};
 methods.abyssEvents104=[];methods.abyssOrigin104=null;rngCalls=0;
 for(const [index,c] of doc.commands.entries()){
  const lookup=id=>roster.find(u=>u.abyssToken104===id),owner=lookup('owner');
  const source=lookup(c.source||'owner'),target=lookup(c.target||'owner');
  switch(c.op){
   case 'initialize':methods.abyssInitialize104(roster.filter(u=>u.team===1),roster.filter(u=>u.team===2));
    owner.leaderPrepared=!!owner.abyssEffect104(19);break;
   case 'round':GameMap.currentMap.roundNum=c.value;break;
   case 'hp':target.hp=c.value;break;
   case 'damage':target.injured(c.amount,1,null,1,null,false,source,null,c.dot_kind||'');break;
   case 'heal':target.injured(c.amount,1,null,4,null,false,source);break;
   case 'buff':target.addBuff(c.kind,3,c.amount,0,-1,source);break;
   case 'dodge':owner.abyssOnDodge104();break;
   case 'summon':{const s=unit({aid:'A_2001_4',instance_id:'summon',hp:1,hp_max:1,ap:1,team:1});
    s.inheritSummonPanel(owner,1);s.addBuff('summon',3,1);roster.push(s);break;}
   default:throw Error(c.op);
  }
  const actual={command:c,units:state(),equipment_events:methods.abyssEvents104,rng_calls:rngCalls};
  assert.deepEqual(actual,doc.expected[index],`kind ${doc.kind} ancient ${doc.ancient} command ${index}`);
 }
 passed++;
}
console.log(`AS settlement methods vs backend fixtures: ${passed}/27 passed (rendering/scheduler stubs).`);
for(const c of input.conversion){
 const own=unit(docs[0].input.team_a[0]),enemy=unit(docs[0].input.team_b[0]);
 own.skill0={};own.abyssRelicA104={id:20,value:c.fraction};context={owner:own,kind:'active',skill:own.skill0};
 enemy.getDefenseAgainst=()=>7;MIN_DAMAGE_RATE=c.minimum;AvatarData.damageRate=()=>c.sign;
 assert.equal(methods.countDamage(own,enemy,c.raw,1,c.share)[0],c.expected,JSON.stringify(c));
}
context=null;
{
 const own=unit(docs.find(d=>d.kind===14&&!d.ancient).input.team_a[0]);
 context={manualEffectMultiplier:.37};own.addBuff('shield',3,3,0,-1,own);
 assert.equal(own.shieldValue104(),1,'shield: effect scaling before relic rounding');context=null;
}
{
 const own=unit(docs.find(d=>d.kind===5&&!d.ancient).input.team_a[0]);
 const enemy=unit({...docs[0].input.team_b[0],team:2});
 enemy.skin2Incoming=v=>int(v*.2);enemy.yasuoDamage104=v=>int(v*.2);enemy.abilityDirectMultiplier=()=>3;
 attack[21]=2;own.injured(100,1,null,1,null,false,enemy);
 assert.equal(enemy.hp,960,'reflect: one 20% share, bypass outgoing/context/skin multipliers');
}
console.log(`Additional parity: ${input.conversion.length} raw/element/split rounding boundaries, shield ordering and reflect scaling passed.`);
for(const ancient of [false,true]) {
 const own=unit(docs.find(d=>d.kind===4&&d.ancient===ancient).input.team_a[0]);
 const enemy=unit(docs[0].input.team_b[0]);own.hp=10;own.hpMax=100;
 own.abyssDots104=[enemy,{}].map(source=>({kind:'burn',source,amount:20,left:2}));
 own.abyssTickDots104();assert.equal(own.hp,ancient?62:50,'revive must cancel remaining copied DOT ticks');
}
for(const kind of ['bomb','zone','channel'])for(const ultimate of [false,true]) {
 const own=unit(docs[0].input.team_a[0]),enemy=unit(docs[0].input.team_b[0]);
 own.skill0={};own.abyssRelicA104={id:20,value:.4};
 context={owner:own,kind:'active',skill:ultimate?{}:own.skill0};
 const saved=methods.abyssCaptureContext104(own),hits=context.abyssHits104;
 assert.equal(saved===null,ultimate);
 // Transformation after the cast must not change a delayed hit's origin.
 own.skill0={};context=null;let count=0;
 own.abilityCandidates=own.abilityEnemies=()=>[enemy];
 own.abilityHit=()=>{
  assert.equal(own.abyssConversion104(),ultimate?0:.4,kind+' origin');
  if(!ultimate){assert.equal(context.abyssHits104,hits);context.abyssHits104.push(enemy);}
  count++;return true;
 };
 const state={owner:own,abyssRelicContext104:saved,coefficient:1,line:own.line,pos:own.pos,left:2};
 if(kind==='bomb') {enemy.abilityBombExplode(state);enemy.abilityBombExplode(state);}
 else {own.abilityState[kind]=state;own.abilityTurnStart();
  if(kind==='zone')own.abilityTurnStart();}
 assert.equal(count,kind==='channel'?1:2);
 if(!ultimate)assert.equal(saved.hits.length,count,'shared per-cast target history');
}
context=null;
console.log('Revive cleansing and delayed bomb/zone/channel cast provenance passed.');
{
 const own=unit(docs[0].input.team_a[0]),enemy=unit(docs[0].input.team_b[0]);
 own.abyssRelicA104={id:13,value:.2};own.skill0={skills:[['dragon_kaisa_q',0,0,0,1]],getNativeSetting:()=>1};
 own.kaisaLane104=()=>[enemy];own.kaisaProjectile104=noop;own.skinBondNumber104=()=>0;
 own.abilityHit=target=>{target.abyssAfterDamage104(own,1,0,2,'');return true;};
 rngCalls=attackContexts=0;
 assert(own.kaisaVolley104(own.skill0));assert.equal(attackContexts,3);assert.equal(rngCalls,1);
 assert(own.kaisaVolley104(own.skill0));assert.equal(attackContexts,8);assert.equal(rngCalls,2);
 // Targeted removal also works when there is no native poison/burn Buff.
 enemy.abyssDots104=[{kind:'burn'},{kind:'poison'},{kind:'phantasm'}];
 enemy.removeBuff('burn');assert.deepEqual(enemy.abyssDots104.map(d=>d.kind),['poison','phantasm']);
 enemy.yasuoCleanse104();assert.deepEqual(enemy.abyssDots104.map(d=>d.kind),['phantasm']);
 assert(!enemy.hasAbyssDot104('poison'));assert(!enemy.hasAbyssDot104('burn'));
}
console.log('KaiSa per-volley rolls and Yasuo targeted relic cleansing passed.');
for(const row of input.summons){
 const skill={getMechanismId:()=>row.source,getNativeSetting:()=>row.policy,skillSetData:{id:row.id}};
 assert(summonAllowed.call(skill),row.id+' must retain native summoning');
 if(row.id!==row.source){
  skill.getNativeSetting=()=>({...row.policy,skillId:row.source});
  assert(!summonAllowed.call(skill),'regression control: old mismatched policy must fail');
 }
}
console.log(`Native Zyra/Azir summon policy checks: ${input.summons.length} passed.`);
