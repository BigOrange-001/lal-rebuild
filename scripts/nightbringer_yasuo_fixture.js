const assert=require('assert');
const data=/*DATA*/;
const int=x=>Math.trunc(Number(x)||0),Tools={toInt:int};
let units=[],contexts=[],afterHit=null,critical=1,missTargets=new Set();
const GameMapConfig={LINE_POS:3000};
const GameMapLayer={gl:null};
const debuffs=['stun','silence','curse','poison','burn','weak','sunder','root','evil'];
const GlobalData={$mConfig_avatar:{[data.aid]:{nightbringerYasuo104:true}},$mConfig_simple:{hero_skill_output_rate_104:.8}};
const GameMap={actionDelay:0,currentMap:{isEnd:()=>false}};
function Buff(type,round,value=0){Object.assign(this,{type,round,value,displayObject:null})}
function beginAbilityAttack(owner,kind){const ctx={owner,kind};contexts.push(ctx);return ctx}
function endAbilityAttack(ctx){assert.equal(contexts.pop(),ctx);if(afterHit&&ctx.kind==='active')afterHit(ctx)}
const methods={};
/*METHODS*/
function skill(sid,rank=1){const row=data.skills[sid],actions=structuredClone(row.skill);for(const [a,p,g]of row.skillUp||[])actions[a][p]+=g*(rank-1);return {skills:actions,getNativeSetting:()=>1}}
function make(team=1,pos=2400,yasuo=true){
 const u={team,otherTeam:3-team,line:0,pos,hp:100000,hpMax:100000,ap:100,baseCrit:123,
  avatarData:{id:yasuo?data.aid:'enemy'},buffs:{},manualSkillDots:{},abilityState:{},receipts:[],offset:0,flights:[],hitTimes:[],
  yasuoNightRounds104:-1,yasuoVampRounds104:-1,yasuoCritBonus104:0,yasuoShieldSerial104:0,yasuoCritBurst104:false};
 u.bondEffects={};u.skinBondNumber104=(key,fallback=0)=>u.bondEffects[key]??fallback;u.isLeader=yasuo;
 Object.assign(u,methods);
 u.skill0=skill(data.normal);u.skill1=skill(data.captain);u.skillB=yasuo?skill(data.passive):null;
 u.getCrit=()=>u.baseCrit+u.yasuoCritBonus104;
 u.getHpMax=()=>u.hpMax;u.getRecoveryTalentMultiplier=()=>1;
 u.abilityEntryAttack=0;u.manualAttackStack=0;u.timedAttackStack=0;
 u.getManualBattleStack=()=>u.manualAttackStack;u.getManualTimedStack=()=>u.timedAttackStack;
 u.yasuoEffect104=()=>{};u.fxPulse104=()=>{};u.abilityFeedback=()=>{};u.queueVitalBar104=()=>{};
 u.yasuoResetVisuals104=()=>{};u.yasuoQueueNight104=()=>{};
 u.yasuoWhirlwind104=(lane,offset,points)=>u.flights.push({lane,offset,points:structuredClone(points)});
 u.beginParallelVisualBatch=()=>({});u.endParallelVisualBatch=()=>{};u.prepareParallelVisualTarget=()=>{};
 u.abilityCandidates=(team,lane)=>units.filter(t=>t.hp>0&&t.team===team&&t.line===lane).sort((a,b)=>team===1?a.pos-b.pos:b.pos-a.pos);
 u.removeBuff=(key,consume=false,clear=true)=>{if(key==='shield'&&clear)u.removeIndependentShields104();if(key==='purify'&&consume&&u.buffs[key]?.value>1){u.buffs[key].value--;return}delete u.buffs[key]};
 u.addBuff=(key,round,value=0)=>{if(u.yasuoImmune104(key))return;if(u.buffs.purify&&debuffs.includes(key)){u.removeBuff('purify',true);return}if(key==='shield'&&u.buffs.curse)return;u.buffs[key]=new Buff(key,round,value)};
 u.abilityControl=(target,key,round,value=0)=>target.addBuff(key,round,value);
 u.removeAllDebuff=()=>{
  for(const key of debuffs)delete u.buffs[key];
  delete u.abilityState.root;u.manualSkillDots={};
 };
 u.reline=(lane,pos)=>{u.line=lane;u.pos=pos};
 u.checkMove=(forward,amount)=>{
  const front=u.abilityCandidates(u.otherTeam,u.line)[0];
  let requested=u.pos+(forward?-1:1)*(u.team===1?1:-1)*amount;
  if(u.team===1)requested=Math.max(front?front.pos+200:0,Math.min(3000,requested));
  else requested=Math.min(front?front.pos-200:3000,Math.max(0,requested));
  const delta=Math.abs(u.pos-requested);u.pos=requested;return .4*Math.min(1,delta/400);
 };
 u.injured=(amount,crit,fx,kind,source,p6,p7,p8,dot,derived=false)=>{
  if(u.hp<=0)return 0;
  if(kind===4){const heal=Math.min(amount,u.hpMax-u.hp);u.hp+=heal;return heal}
  const settled=u.yasuoDamage104(int(amount*crit),source,derived);
  const before=u.hp;const remaining=u.absorbShieldDamage(settled,1);u.hp-=remaining;
  if(u.hp<=0&&u.buffs.bless){u.removeBuff('bless');u.hp=u.hpMax*.5}
  const actual=Math.max(0,before-Math.max(0,u.hp));
  u.receipts.push({kind,crit,settled,derived,actual});
  source.yasuoEvent104('hit',source,u,actual);
  if(crit>1){source.yasuoEvent104('crit',source,u,actual);source.yasuoCritical104(u,settled)}
  return actual;
 };
 u.abilityHit=(target,coefficient,kind,effect)=>{u.hitTimes.push({target,at:GameMap.actionDelay,effect});if(missTargets.has(target))return false;target.injured(int(coefficient*.8*u.getDamage()),critical,null,kind,u,false,u);return true};
 u.tick=()=>{
  if(u.yasuoNightRounds104>=0)--u.yasuoNightRounds104;
  if(u.yasuoVampRounds104>=0)--u.yasuoVampRounds104;
  for(const [key,buff]of Object.entries(u.buffs)){
   if((key==='bless'&&buff.value<=0)||(key==='purify'&&buff.value>0))continue;
   if(--buff.round<0)u.removeBuff(key,false,false);
  }
 };
 units.push(u);return u;
}
function fresh(count=1,team=1){
 units=[];contexts=[];afterHit=null;critical=1;missTargets=new Set();GameMap.actionDelay=0;
 const a=make(team,team===1?2400:600);
 const en=Array.from({length:count},(_,i)=>make(3-team,team===1?1400-300*i:1600+300*i,false));
 return {a,en};
}
let cases=0;
{
 const {a,en}=fresh(3);a.yasuoExecute104('night_yasuo_n',a.skill0);
 assert.deepEqual(en.map(t=>100000-t.hp),[225,135,135]);
 assert.equal(en[0].buffs.stun.round,1);assert(!en[1].buffs.stun);
 assert(!en[0].buffs.weak);assert.equal(en[1].buffs.weak.round,1);
 assert(Math.abs(en[1].buffs.weak.value-.33/(1-.33))<1e-10);
 assert.equal(a.pos,2000);assert.deepEqual(en.map(t=>t.pos),[1100,800,500]);cases++;
 assert.equal(a.flights.length,1,'one full-lane projectile rather than one projectile per target');
 assert.equal(a.flights[0].points[0].pos,2000);assert.equal(a.flights[0].points.at(-1).pos,0);
 assert(a.hitTimes.every(x=>x.effect==='FX_NIGHT_YASUO_CONTACT104'));
 const launch=a.flights[0].points[0].at;
 assert.deepEqual(a.hitTimes.map(x=>Math.round((x.at-launch)*2400)),[600,900,1200]);
}
for(const team of [1,2]){
 const {a,en}=fresh(1,team);const old=en[0].pos;a.pos=old+(team===1?300:-300);
 a.yasuoExecute104('night_yasuo_n',a.skill0);
 assert.equal(a.pos,old+(team===1?200:-200));cases++;
}
{
 const {a,en}=fresh(2);en[0].hp=1;a.yasuoExecute104('night_yasuo_n',a.skill0);
 assert.equal(100000-en[1].hp,135);cases++;
}
{
 const {a}=fresh();a.yasuoStart104();assert.equal(a.getCrit(),246);
 a.yasuoStart104();assert.equal(a.getCrit(),246);a.skillB=null;a.yasuoStart104();assert.equal(a.getCrit(),123);cases++;
}
{
 const {a,en}=fresh();const t=en[0];t.addBuff('shield',3,1000);critical=2;
 a.abilityHit(t,1/.8,1);
 assert.equal(t.hp,100000);assert.equal(t.shieldValue104(),730);
 assert.equal(a.shieldValue104(),5025);assert.equal(Object.keys(a.buffs).length,1);
 assert.deepEqual(t.receipts.map(r=>r.crit),[2,1]);assert.equal(t.receipts[1].kind,3);cases++;
}
{
 const {a,en}=fresh();a.yasuoEvent104('crit',a,en[0],10);a.tick();a.yasuoEvent104('crit',a,en[0],10);
 assert.deepEqual(Object.values(a.buffs).map(b=>b.round),[1,2]);
 assert.equal(a.absorbShieldDamage(100,1),0);assert.equal(a.buffs.yasuoShield104_1.value,4925);
 a.tick();a.tick();assert.equal(a.shieldValue104(),5025);a.tick();assert.equal(a.shieldValue104(),0);cases++;
}
{
 const {a,en}=fresh();for(const key of ['stun','curse','poison','burn','silence','weak'])a.addBuff(key,3,1);
 a.manualSkillDots={p:{kind:'poison'},b:{kind:'burn'},bleed:{kind:'bleed'}};
 a.yasuoExecute104('night_yasuo_c',a.skill1);
 for(const key of ['stun','silence','curse','poison','burn']){assert(!a.buffs[key]);a.addBuff(key,3,9);a.addBuff(key,3,9);assert(!a.buffs[key])}
 assert(a.buffs.weak);assert.deepEqual(Object.keys(a.manualSkillDots),['bleed']);
 assert.equal(a.pos,1600);assert.equal(a.getDamage(),87,'preserved weakness applies before the independent night multiplier');assert.equal(100000-en[0].hp,690);assert(a.buffs.bless);
 assert.equal(a.yasuoNightRounds104,2);a.tick();a.tick();assert(a.yasuoNight104());assert(a.yasuoImmune104('stun'));assert.equal(a.yasuoVampRounds104,0);
 a.hp=90000;a.abilityHit(en[0],1/.8,1);assert.equal(a.hp,90087);a.tick();assert(!a.yasuoNight104());assert(!a.yasuoImmune104('stun'));assert.equal(a.yasuoVampRounds104,-1);cases++;
}
{
 const {a,en}=fresh(2);en[0].hp=1;a.yasuoExecute104('night_yasuo_c',a.skill1);
 assert.equal(en[1].hp,100000);assert.equal(en[0].receipts.length,1);cases++;
}
{
 const {a,en}=fresh(2);afterHit=()=>a.hp=0;a.yasuoExecute104('night_yasuo_n',a.skill0);
 assert.equal(en[1].hp,99865,'a wave settles all targets before queued counters');cases++;
}
{
 const {a,en}=fresh();a.yasuoNightRounds104=1;critical=2;a.abilityHit(en[0],1/.8,1);
 assert.equal(100000-en[0].hp,472);assert.deepEqual(en[0].receipts.map(r=>r.settled),[350,122]);cases++;
}
{
 const {a,en}=fresh(2);for(const key of ['weak','root','curse'])a.addBuff(key,3,1);
 a.abilityState.root=true;a.manualSkillDots={bleed:{kind:'bleed'}};
 a.yasuoExecute104('night_yasuo_n',a.skill0);
 assert(!a.buffs.weak&&!a.buffs.root&&!a.buffs.curse&&!a.abilityState.root);assert.deepEqual(a.manualSkillDots,{});
 assert.equal(a.pos,2000,'purification removes root before the dash');assert.equal(a.buffs.purify.value,1);
 a.addBuff('silence',2);assert(!a.buffs.silence&&!a.buffs.purify,'one future debuff is blocked');
 a.addBuff('silence',2);assert(a.buffs.silence,'the next debuff applies normally');
 a.yasuoExecute104('night_yasuo_n',a.skill0);assert.equal(a.buffs.purify.value,1,'recast restores one charge');
 a.buffs.purify.value=2;a.yasuoExecute104('night_yasuo_n',a.skill0);assert.equal(a.buffs.purify.value,2,'existing stronger purification stays intact');cases++;
}
{
 const {a,en}=fresh(3);a.skill0=skill(data.normal,10);missTargets.add(en[2]);
 a.yasuoExecute104('night_yasuo_n',a.skill0);
 assert(!en[0].buffs.weak);assert(Math.abs(1/(1+en[1].buffs.weak.value)-.34)<1e-8);
 assert(!en[2].buffs.weak,'a missed later target receives no weakness');
 en[1].tick();en[1].tick();assert(!en[1].buffs.weak);cases++;
}
{
 const {a,en}=fresh();a.hp=90000;a.yasuoVampRounds104=2;
 const getDamage=a.getDamage;
 a.getHit=()=>{throw Error('lifesteal must not use precision')};
 a.getDamage=()=>{throw Error('lifesteal must not use AP healing')};
 a.yasuoEvent104('hit',a,en[0],100);assert.equal(a.hp,90100);
 a.hp=99990;a.yasuoEvent104('hit',a,en[0],100);assert.equal(a.hp,100000);
 a.getDamage=getDamage;
 a.hp=90000;en[0].addBuff('shield',3,1000);a.abilityHit(en[0],1/.8,1);assert.equal(a.hp,90000,'fully absorbed damage heals nothing');
 en[0].removeBuff('shield');en[0].hp=30;a.abilityHit(en[0],1/.8,1);assert.equal(a.hp,90030,'overkill heals only actual HP lost');cases++;
}
{
 const {a,en}=fresh();a.bondEffects.yasuo_crit_true=.5;critical=2;a.abilityHit(en[0],1/.8,1);
 assert.equal(100000-en[0].hp,300,'bond changes only the derived ratio from 35% to 50%');cases++;
}
{
 const {a}=fresh();a.addBuff('silence',3);let captainCalls=0;
 a.skill2={checkUse(){throw Error('silenced book must not cast')}};
 a.skill0.checkUse=()=>{throw Error('silenced Q must not cast')};
 a.skill1.checkUse=()=>{captainCalls++;return a.skill1.ready};a.skill1.ready=true;
 assert(!a.checkSkill());assert.equal(captainCalls,0);
 a.bondEffects.yasuo_c_silenced=1;assert(a.checkSkill());assert.equal(captainCalls,1);
 a.skill1.ready=false;assert(!a.checkSkill(),'cooldown gate remains authoritative');
 a.isLeader=false;a.skill1.ready=true;assert(!a.checkSkill());
 a.isLeader=true;a.addBuff('stun',1);assert(!a.checkSkill(),'stun still blocks the exception');
 a.removeBuff('stun');delete a.bondEffects.yasuo_c_silenced;assert(!a.checkSkill());cases++;
}
{
 const {a}=fresh(2);let seen=[];
 a.bondEffects.yasuo_c_damage=1.12;
 a.yasuoHit104=(target,coefficient,source,effect)=>{seen.push({coefficient,effect});return true};
 a.yasuoExecute104('night_yasuo_c',a.skill1);
 [1.75,1.75,4.44].forEach((c,i)=>assert(Math.abs(seen[i].coefficient-c*1.12)<1e-10));
 seen=[];a.yasuoExecute104('night_yasuo_n',a.skill0);
 [2.25,1.35].forEach((c,i)=>assert(Math.abs(seen[i].coefficient-c)<1e-10,'Q must not receive captain damage bonus'));
 cases++;
}
{
 const {a,en}=fresh();a.addBuff('strong',3,.5);a.manualAttackStack=.2;a.timedAttackStack=.3;
 a.abilityEntryAttack=100;a.abilityState.evilStackBonus=.1;a.abilityState.santaStacks=2;
 assert.equal(a.getDamage(),258);a.yasuoNightRounds104=2;
 assert.equal(a.getDamage(),451,'night multiplies after all ordinary attack modifiers');
 assert.equal(en[0].yasuoDamage104(100,a),100,'fixed damage has no second outgoing amplification');
 a.tick();a.tick();assert.equal(a.getDamage(),451);a.tick();assert.equal(a.getDamage(),258);cases++;
}
assert.equal(contexts.length,0);
console.log(JSON.stringify({nativeMethodScenarios:cases,passed:true}));
