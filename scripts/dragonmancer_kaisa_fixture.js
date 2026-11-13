const assert=require('assert');
const data=/*DATA*/;
let units=[],contexts=[],next=0,volleys=[],afterShot=null;
const int=x=>Math.trunc(Number(x)||0),Tools={toInt:int},GameMapConfig={LINE_POS:3000};
const GlobalData={$mConfig_avatar:{A_1801_6:{dragonmancerKaisa104:true}},$mConfig_simple:{hero_skill_output_rate_104:.8}};
const DisplayTools={getAttrs:key=>({key})};
GlobalData.modDefinitionId=id=>id;
const GameMap={actionDelay:0,currentMap:{
 winnerList:[0,0,0],winner:0,
 isEnd:lane=>GameMap.currentMap.winner!==0||(lane!==undefined&&lane>=0&&GameMap.currentMap.winnerList[lane]!==0),
 getAliveList:team=>units.filter(u=>u.team===team&&u.hp>0),
 addAvatar:(u,team,line,pos)=>{u.team=team;u.otherTeam=3-team;u.line=line;u.pos=pos;units.push(u)}
}};
function currentAbilityAttack(){return contexts.at(-1)}
function beginAbilityAttack(owner,kind){let c={owner,kind,hits:[],targets:[]};contexts.push(c);return c}
function endAbilityAttack(c){assert.strictEqual(currentAbilityAttack(),c);contexts.pop();if(afterShot&&c.kind==='active')afterShot(c)}
function countDamage(){throw new Error('Fixed plasma must bypass AP/armor/RPS calculation')}
const methods={};
/*METHODS*/
const kaisaNotifyStun104=methods.kaisaNotifyStun104;
function SkillSet(id,owner,level=1){
 let row=structuredClone(data[id]);this.skillSetData={id,cooldown:row.pl[1]};this.lv=level;
 this.skills=row.skill;this.m_cooldownNum=row.pl[0];
 this.getNativeSetting=()=>1;
 this.useSkill=()=>{this.m_cooldownNum=this.skillSetData.cooldown;return owner.kaisaExecute104(this.skills[0][1],this)};
 this.checkUse=()=>{let kind=this.skills[0][1];if(this.m_cooldownNum>=0||!owner.kaisaCanCast104(kind))return false;return this.useSkill()}
}
function make(team=1,line=0,pos=2400,kaisa=true,add=true){
 let u={team,otherTeam:3-team,line,pos,hp:100000,hpMax:100000,ap:100,lv:1,abilityIndex:++next,
  abilityState:{},avatarData:{id:kaisa?'A_1801_6':'A_1001_6'},isLeader:false,
  isManualSummonUnit:false,kaisaRoot104:null,kaisaCast104:0,kaisaMarks104:{},
  kaisaHunting104:false,kaisaBurst104:false,buffs:{},speed:250,range:600,m_icon:{},receipts:[],plasmaUpdates:[],hitEffects:[]};
 Object.assign(u,methods);
 u.bondEffects={};u.skinBondNumber104=(key,fallback=0)=>u.bondEffects[key]??fallback;
 u.abilityControl=(target,key,round,value=0)=>target.addBuff(key,round,value);
 u.kaisaProjectile104=(target,index)=>volleys.push({owner:u,target,index,delay:GameMap.actionDelay});
 u.kaisaQueuePlasma104=(key,stacks)=>u.plasmaUpdates.push({key,stacks});
 u.abilityCandidates=(which,lane,p,d,max,hero,order)=>units.filter(x=>x.hp>0&&x.team===which&&x.line===lane)
 .sort((a,b)=>(which===1?a.pos-b.pos:b.pos-a.pos)||a.abilityIndex-b.abilityIndex);
 u.getType=()=>1;u.getHpMax=()=>u.hpMax;u.getRange=()=>u.range;
 u.reline=(l,p)=>{u.line=l;u.pos=p};
 u.goFight=(t,l,p,leader)=>{u.team=t;u.otherTeam=3-t;u.line=l;u.pos=p;u.isLeader=leader};
 u.inheritSummonPanel=(owner,ratio)=>{u.hp=u.hpMax=owner.hpMax*ratio;u.ap=owner.ap*ratio;u.isManualSummonUnit=true;return true};
 u.addBuff=(kind,round,value=0)=>{if(kind==='purify')for(let k of ['curse','evil','stun','silence','burn','poison'])delete u.buffs[k];if(kind==='shield'&&u.buffs.curse)return;u.buffs[kind]={round,value}};
 u.injured=(amount,critical,effect,kind,source)=>{assert(effect===null||typeof effect==='object','native injured needs effect attributes, not a name');if(u.hp<=0)return;u.receipts.push({amount,kind});if(kind===4)u.hp=Math.min(u.hpMax,u.hp+amount);else{u.hp-=amount;source?.kaisaEvent104('hit',source,u)}};
 u.abilityHit=(target,coefficient,kind,effect)=>{u.hitEffects.push(effect);target.injured(Math.trunc(coefficient*.8*u.ap),1,{},2,u);return true};
 if(kaisa){u.skill0=new SkillSet(data.normal,u);u.skill1=new SkillSet(data.captain,u);u.skillB=new SkillSet(data.passive,u)}
 if(add)units.push(u);return u;
}
function Avatar(id,options){return make(1,0,0,true,false)}
function fresh(n=1){
 units=[];contexts=[];volleys=[];afterShot=null;GameMap.actionDelay=0;GameMap.currentMap.winnerList=[0,0,0];GameMap.currentMap.winner=0;
 let a=make();a.isLeader=true;let en=Array.from({length:n},(_,i)=>make(2,0,1400-i*300,false));
 return {a,en}
}
function cast(a){let c=beginAbilityAttack(a,'active');try{return a.kaisaVolley104(a.skill0)}finally{endAbilityAttack(c)}}
let cases=0;
for(let [n,hits] of [[1,[3]],[2,[2,1]],[3,[1,1,1]],[4,[1,1,1,0]]]){
 let {a,en}=fresh(n);cast(a);
 assert.deepEqual(en.map(x=>(100000-x.hp)/100),hits);assert(a.hitEffects.every(fx=>fx==='FX_KAISA_MISSILE104'));cases++;
}
{
 let {a,en}=fresh(2);en[0].hp=100;cast(a);
 assert(en[0].hp<=0);assert.equal(en[1].hp,99800);cases++;
}
{
 let {a,en}=fresh();afterShot=c=>{if(c.owner===a)a.hp=0};cast(a);
 assert.equal(volleys.length,1,'counter death settles before shot 2');cases++;
}
{
 let {a}=fresh();cast(a);cast(a);cast(a);
 assert.equal(volleys.length,15);assert.equal(a.kaisaCast104,3);cases++;
}
{
 let {a,en}=fresh(2);en.forEach(u=>u.line=1);en[1].addBuff('stun',1);
 a.skill0.m_cooldownNum=8;a.skill1.m_cooldownNum=-1;a.kaisaCast104=2;
 kaisaNotifyStun104(en[1]);
 assert.equal(a.line,1);assert.equal(a.pos,1900);assert.equal(a.skill0.m_cooldownNum,8);
 assert.equal(a.skill1.m_cooldownNum,3);assert.equal(a.kaisaCast104,3);
 assert(volleys[0].delay>=2,'free volley launches after native landing animation');
 let clone=units.find(u=>u.kaisaRoot104===a);assert(clone);
 assert.equal(clone.hpMax,a.hpMax);assert.equal(clone.ap,a.ap);
 assert.equal(clone.line,0);assert.equal(clone.pos,2400);assert.equal(clone.kaisaCast104,0);
 assert.equal(clone.skill1,null);assert.equal(clone.buffs.summon.round,7);
 assert.equal(a.buffs.shield.value,60000);assert.equal(clone.buffs.shield.value,60000);
 assert.equal(a.buffs.shield.round,3);assert.equal(clone.buffs.purify.round,3);
 assert.equal(clone.kaisaCanCast104('dragon_kaisa_c'),false);
 en[0].line=0;cast(clone);assert.equal(clone.kaisaCast104,1);assert.equal(a.kaisaCast104,3);cases++;
}
{
 let {a,en}=fresh();let target=en[0];target.hp=target.hpMax=10000;
 let clone=make();clone.kaisaRoot104=a;
 for(let actor of [a,clone,a,clone,a]){
  let c=beginAbilityAttack(actor,'basic');
  try{actor.abilityHit(target,1/.8)}finally{endAbilityAttack(c)}
 }
 assert.equal(target.hp,7500);assert.equal(target.kaisaMarks104[a.abilityIndex],0);
 assert.equal(target.receipts.at(-1).kind,3,'plasma is true damage');
 assert.equal(target.buffs.curse.round,1);cases++;
}
{
 let {a,en}=fresh();a.skill1.m_cooldownNum=-1;en[0].line=1;en[0].isManualSummonUnit=true;en[0].addBuff('stun',1);
 kaisaNotifyStun104(en[0]);assert.equal(a.line,0);cases++;
}
{
 let {a,en}=fresh();en[0].addBuff('stun',1);a.skill1.m_cooldownNum=-1;
 kaisaNotifyStun104(en[0]);assert.equal(a.kaisaCast104,0,'same lane cannot hunt while multiple lanes remain');
 GameMap.currentMap.winnerList=[0];kaisaNotifyStun104(en[0]);assert.equal(a.kaisaCast104,1);cases++;
}
{
 let {a,en}=fresh();a.line=en[0].line=2;en[0].addBuff('stun',1);a.skill1.m_cooldownNum=-1;
 GameMap.currentMap.winnerList=[1,2,0];kaisaNotifyStun104(en[0]);assert.equal(a.kaisaCast104,1);cases++;
}
{
 let {a,en}=fresh();en[0].line=1;en[0].addBuff('stun',1);a.skill1.m_cooldownNum=-1;
 let own=make();own.kaisaRoot104=a;own.hpMax=4000;own.hp=3000;own.addBuff('curse',2);
 let other=make();a.addBuff('curse',2);
 afterShot=()=>{assert.equal(a.buffs.shield.value,60000);assert.equal(own.buffs.shield.value,2400);assert(!a.buffs.curse);assert(!own.buffs.curse)};
 kaisaNotifyStun104(en[0]);assert.equal(own.buffs.purify.round,3);assert(!other.buffs.shield);cases++;
}
{
 let {a,en}=fresh();a.hp=70000;let target=en[0];target.hp=target.hpMax=10000;
 for(let i=0;i<5;i++){let c=beginAbilityAttack(a,'basic');try{a.kaisaEvent104('hit',a,target)}finally{endAbilityAttack(c)}}
 assert.equal(a.hp,75000);assert.equal(target.hp,8000);
 assert.deepEqual(target.plasmaUpdates.map(x=>x.stacks),[1,2,3,4,0]);
 let clone=make();clone.kaisaRoot104=a;clone.hpMax=60000;clone.hp=50000;
 for(let i=0;i<5;i++){let c=beginAbilityAttack(clone,'basic');try{clone.kaisaEvent104('hit',clone,target)}finally{endAbilityAttack(c)}}
 assert.equal(clone.hp,53000);assert.equal(a.hp,75000);assert.equal(target.hp,6000);
 assert(target.plasmaUpdates.every(x=>x.key===String(a.abilityIndex)));cases++;
}
assert.equal(contexts.length,0);
{
 let {a,en}=fresh(3);a.bondEffects.kaisa_q_sunder=.33;cast(a);
 assert(en.every(t=>t.buffs.sunder&&t.buffs.sunder.round===1));
 assert(en.every(t=>Math.abs(1/(1+t.buffs.sunder.value)-.67)<1e-8));
 let clone=make();clone.kaisaRoot104=a;cast(clone);assert(en[0].buffs.sunder,'clone inherits root bond');cases++;
}
{
 let {a,en}=fresh();a.bondEffects.kaisa_q_sunder=.33;a.abilityHit=()=>false;cast(a);
 assert(!en[0].buffs.sunder,'missed Q cannot apply armor reduction');cases++;
}
console.log(JSON.stringify({nativeMethodScenarios:cases,passed:true}));
