const assert=require('assert');
const data=/*DATA*/;
const int=x=>Math.trunc(Number(x)||0),Tools={toInt:int};
const Avatar=x=>x;
let units=[],contexts=[];
const GameMapConfig={LINE_POS:3000};
const GameMapLayer={gl:null};
const GlobalData={$mConfig_avatar:{[data.aid]:{demonbladeTryndamere105:true}},$mConfig_simple:{hero_skill_output_rate_104:.8}};
const GameMap={actionDelay:0,currentMap:{roundNum:0,getAliveList:team=>units.filter(u=>u.team===team&&u.hp>0)}};
function beginAbilityAttack(owner,kind){const ctx={owner,kind};contexts.push(ctx);return ctx}
function endAbilityAttack(ctx){assert.equal(contexts.pop(),ctx)}
function currentAbilityAttack(){return contexts[contexts.length-1]||null}
const methods={};
/*METHODS*/
function skill(sid,rank=1){const row=data.skills[sid],actions=structuredClone(row.skill);for(const [a,p,g]of row.skillUp||[])actions[a][p]+=g*(rank-1);return {skills:actions,getNativeSetting:()=>1}}
function make(team,pos,{demon=false,leader=false,line=0}={}){
 const u={team,otherTeam:3-team,line,pos,hp:100000,hpMax:100000,ap:100,isLeader:leader,
  avatarData:{id:demon?data.aid:'other'},buffs:{},abilityState:{},bars:[],feedback:[],
  demonRage105:0,demonFury105:-1,demonFuryReady105:0,demonFuryUsed105:0,demonHurtGain105:0,demonAuraGain105:0,
  demonDealt105:false,demonActed105:false,demonForceCrit105:false};
 Object.assign(u,methods);
 // Effects are visual only: record which ones each skill plays.
 u.fx=[];u.demonFx105=(kind,target)=>u.fx.push(kind+':'+(target&&target!==u?units.indexOf(target):'self'));
 u.demonFxStop105=kind=>u.fx.push('stop:'+kind);
 u.skill0=demon?skill(data.normal):null;u.skill1=demon?skill(data.captain):null;u.skillB=demon?skill(data.passive):null;
 u.mBloodSpr={setRage105:rate=>u.bars.push(rate)};
 u.sixNextPassive105=key=>u.shyvana&&key==='shyvana';
 u.getRange=()=>350;
 u.getDamage=()=>u.demonAttack105(int(u.ap*(1+(u.buffs.strong?u.buffs.strong.value:0))));
 u.shieldValue104=()=>u.buffs.shield?u.buffs.shield.value:0;
 u.refreshHp=()=>{};u.abilityFeedback=text=>u.feedback.push(text);
 u.abilityCandidates=(team,lane,center,distance,maximum=1,hero=false,order='nearest',excluded=[])=>{
  let found=units.filter(t=>t.hp>0&&t.team===team&&t.line===lane&&Math.abs(t.pos-center)<=distance&&!excluded.includes(t));
  found.sort(order==='front'?(a,b)=>team===1?a.pos-b.pos:b.pos-a.pos:(a,b)=>Math.abs(a.pos-center)-Math.abs(b.pos-center));
  return maximum<0?found:found.slice(0,maximum);
 };
 u.abilityDash=target=>{u.line=target.line;u.pos=target.pos+(u.team===1?125:-125);return true};
 u.addBuff=(key,round,value=0)=>{if(u.demonImmune105(key))return;u.buffs[key]={type:key,round,value}};
 u.removeBuff=key=>{delete u.buffs[key]};
 u.removeAllDebuff=()=>{for(const key of ['stun','silence','weak','sunder','curse','root'])delete u.buffs[key]};
 u.abilityControl=(target,key,round,value=0)=>target.addBuff(key,round,value);
 u.injured=(amount,crit,fx,kind,source)=>{
  if(u.hp<=0)return 0;
  if(kind===4){const heal=Math.min(amount,u.hpMax-u.hp);u.hp+=heal;return heal}
  u.hp-=amount;if(u.hp<=0)u.demonLethal105();
  if(source&&source!==u){source.demonEvent105('hit',source,u);source.demonRecordDamage105(u,amount);u.demonHurtTaken105()}
  return amount;
 };
 u.abilityHit=(target,coefficient,kind)=>{target.injured(int(coefficient*.8*u.getDamage()),1,null,kind,u);return true};
 units.push(u);return u;
}
function fresh(count=1,allies=0){
 units=[];contexts=[];GameMap.actionDelay=0;GameMap.currentMap.roundNum=0;
 const a=make(1,2400,{demon:true,leader:true});
 const friends=Array.from({length:allies},(_,i)=>make(1,2600+100*i));
 const en=Array.from({length:count},(_,i)=>make(2,1400-150*i));
 a.demonStart105();
 return {a,friends,en};
}
let cases=0;
{
 const {a,en}=fresh(5);en[4].line=1;
 assert.ok(a.demonExecute105('demon_trynd_n',a.skill0));
 assert.equal(a.pos,1525);
 assert.deepEqual(en.map(t=>100000-t.hp),[160,160,160,0,0]);
 assert.deepEqual(en.map(t=>!!t.buffs.sunder),[true,true,true,false,false]);
 assert.ok(Math.abs(en[0].buffs.sunder.value-.25/.75)<1e-9);
 assert.equal(a.demonRage105,35);assert.equal(a.demonForceCrit105,true);
 assert.equal(a.bars.at(-1),.35);
 assert.equal(a.demonTakeForceCrit105(),true);assert.equal(a.demonTakeForceCrit105(),false);
 cases++;
}
{
 const {a,en}=fresh(1);a.skill0=skill(data.normal,10);
 a.demonExecute105('demon_trynd_n',a.skill0);
 assert.equal(100000-en[0].hp,320);assert.equal(a.demonRage105,25);
 cases++;
}
{
 let {a}=fresh(1);a.demonRage105=50;a.hp=50000;a.demonExecute105('demon_trynd_n',a.skill0);
 assert.equal(a.demonRage105,55);
 ({a}=fresh(1));a.demonRage105=50;a.hp=30000;const attack=a.getDamage();
 a.demonExecute105('demon_trynd_n',a.skill0);
 assert.equal(a.hp,30000+20000+attack);assert.equal(a.demonRage105,55);
 ({a}=fresh(1));a.demonRage105=39;a.hp=30000;a.demonExecute105('demon_trynd_n',a.skill0);assert.equal(a.hp,30000);
 cases++;
}
{
 const {a}=fresh(1);a.demonRage105=50;
 assert.ok(Math.abs(a.demonCritBonus105()-20)<1e-9);
 assert.equal(a.demonCritDamageRate105(),1.3);assert.equal(make(1,2000).demonCritDamageRate105(),1);
 a.hp=50000;assert.equal(a.getDamage(),140);
 a.hp=10000;assert.equal(a.getDamage(),160);
 cases++;
}
{
 const {a,en}=fresh(1);a.addBuff('curse',2);
 a.injured(200000,1,null,1,en[0]);
 assert.equal(a.hp,1);assert.equal(a.buffs.curse,undefined);
 assert.equal(a.demonRage105,82);assert.deepEqual(a.feedback,['无尽怒火']);
 assert.equal(a.getDamage(),int(int(100*1.6)*1.6));
 a.addBuff('curse',2);assert.equal(a.buffs.curse,undefined);
 a.addBuff('weak',2,1);assert.ok(a.buffs.weak);
 for(let i=0;i<3;i++){a.demonTurn105();a.injured(200000,1,null,1,en[0]);assert.equal(a.hp,1)}
 a.addBuff('stun',2);a.demonTurn105();
 assert.equal(a.demonFuryActive105(),false);assert.equal(a.demonRage105,0);
 assert.equal(a.buffs.weak,undefined);assert.equal(a.buffs.stun,undefined);
 assert.equal(a.hp,1+35000);
 cases++;
}
{
 const {a,en}=fresh(1);a.isLeader=false;
 a.injured(200000,1,null,1,en[0]);
 for(let i=0;i<2;i++){a.demonTurn105();a.injured(200000,1,null,1,en[0]);assert.equal(a.hp,1)}
 a.demonTurn105();assert.equal(a.demonFuryActive105(),false);assert.equal(a.hp,1+35000);
 cases++;
}
{
 const {a}=fresh(1);
 a.hp=0;a.demonLethal105();assert.equal(a.hp,1);
 a.demonFury105=-1;GameMap.currentMap.roundNum=11;a.hp=0;a.demonLethal105();assert.equal(a.hp,0);
 GameMap.currentMap.roundNum=12;a.demonLethal105();assert.equal(a.hp,1);
 a.demonFury105=-1;GameMap.currentMap.roundNum=40;a.hp=0;a.demonLethal105();assert.equal(a.hp,0);
 assert.equal(a.demonFuryUsed105,2);
 cases++;
}
{
 const {a,en}=fresh(1);a.demonTurn105();a.demonTurn105();assert.equal(a.demonRage105,10);
 for(let i=0;i<6;i++)a.demonHurtTaken105();
 assert.equal(a.demonRage105,18);
 a.demonTurn105();a.demonHurtTaken105();assert.equal(a.demonRage105,10);
 const ctx=beginAbilityAttack(a,'basic');a.demonEvent105('hit',a,en[0]);a.demonEvent105('crit',a,en[0]);endAbilityAttack(ctx);
 assert.equal(a.demonRage105,20);assert.equal(a.demonDealt105,false);
 a.demonRecordDamage105(en[0],0);assert.equal(a.demonDealt105,false);
 a.demonRecordDamage105(en[0],1);assert.equal(a.demonDealt105,true);
 const skillCtx=beginAbilityAttack(a,'active');a.demonEvent105('crit',a,en[0]);endAbilityAttack(skillCtx);
 assert.equal(a.demonRage105,20);
 cases++;
}
{
 const {a,friends,en}=fresh(3,2);a.demonRage105=60;friends[0].hp=50000;
 assert.ok(a.demonExecute105('demon_trynd_c',a.skill1));
 for(const u of [a,...friends]){assert.equal(u.buffs.strong.value,.3);assert.equal(u.buffs.critup.value,4000)}
 assert.deepEqual(en.map(t=>!!t.buffs.weak),[true,true,false]);
 assert.equal(a.demonRage105,30);
 const heal=int(30*(int(100*1.3)*.1+100000*.015));
 assert.equal(friends[0].hp,50000+heal);
 assert.equal(friends[1].buffs.shield.value,heal);assert.equal(a.buffs.shield.value,heal);
 cases++;
}
{
 let {a}=fresh(1,1);a.demonRage105=30;a.demonExecute105('demon_trynd_c',a.skill1);assert.equal(a.demonRage105,10);
 const {a:leader,friends,en}=fresh(1,1);
 for(let i=0;i<8;i++)friends[0].demonEvent105('crit',friends[0],en[0]);
 assert.equal(leader.demonRage105,30);
 leader.isLeader=false;leader.demonAuraGain105=0;friends[0].demonEvent105('crit',friends[0],en[0]);
 assert.equal(leader.demonRage105,30);
 cases++;
}
{
 const {a,en}=fresh(1);
 const dragon=make(1,2500);dragon.shyvana=true;dragon.skillB={skills:[]};dragon.abilityState.nextRage=35;
 dragon.queueRageBar105();assert.equal(dragon.bars.at(-1),.35);
 dragon.abilityState.nextDragon=true;dragon.queueRageBar105();assert.equal(dragon.bars.at(-1),1);
 en[0].queueRageBar105();assert.deepEqual(en[0].bars,[]);
 a.demonRage105=100;a.queueRageBar105();assert.equal(a.bars.at(-1),1);
 cases++;
}
{
 // Demon Slash: dash slash on the front enemy, cleaves on the rest, then the crit glint.
 let {a,en}=fresh(3);
 a.demonExecute105('demon_trynd_n',a.skill0);
 assert.deepEqual(a.fx,['slash:1','cleave:2','cleave:3','edge:self']);
 a.demonExecute105('demon_trynd_n',a.skill0);
 assert.equal(a.fx.filter(k=>k==='edge:self').length,1);
 const ctx=beginAbilityAttack(a,'basic');a.demonEvent105('crit',a,en[0]);
 a.demonRecordDamage105(en[0],0,true);
 assert.equal(a.fx.includes('crit:1'),false);
 a.demonRecordDamage105(en[0],100,true);endAbilityAttack(ctx);
 a.demonTakeForceCrit105();
 assert.deepEqual(a.fx.slice(-2),['crit:1','stop:edge']);
 // The low-health heal flares before the slash.
 ({a}=fresh(1));a.demonRage105=50;a.hp=30000;a.demonExecute105('demon_trynd_n',a.skill0);
 assert.deepEqual(a.fx.slice(0,2),['mend:self','slash:1']);
 // War cry: the roar, every ally in the lane lifted, the weakened enemies marked.
 let friends;({a,friends,en}=fresh(3,2));a.demonRage105=60;
 a.demonExecute105('demon_trynd_c',a.skill1);
 assert.deepEqual(a.fx,['warcry:self','rally:self','rally:1','rally:2','weak:3','weak:4']);
 // Endless Rage: the trigger and the aura, then the calm when it ends.
 ({a,en}=fresh(1));a.injured(200000,1,null,1,en[0]);
 assert.deepEqual(a.fx,['fury:self','aura:self']);
 a.hp=0;a.demonLethal105();assert.equal(a.fx.length,2);
 for(let i=0;i<3;i++)a.demonTurn105();
 assert.deepEqual(a.fx.slice(2),[]);
 a.demonTurn105();
 assert.deepEqual(a.fx.slice(2),['stop:aura','calm:self']);
 cases++;
}
{
 const {a,en}=fresh(3);
 const attack=a.abilityHit;
 a.abilityHit=(target,coefficient,kind)=>{
   if(target===en[0]) return false; // Evaded.
   if(target===en[1]) {a.demonRecordDamage105(target,0);return true;} // Immune.
   return attack(target,coefficient,kind);
 };
 a.demonExecute105('demon_trynd_n',a.skill0);
 assert.deepEqual(a.fx,['cleave:3','edge:self']);
 a.fx=[];
 const addBuff=en[0].addBuff;
 en[0].buffs.weak={value:5};
 en[0].addBuff=(key,...args)=>{if(key!=='weak')addBuff(key,...args);};
 a.demonExecute105('demon_trynd_c',a.skill1);
 assert.deepEqual(a.fx,['warcry:self','rally:self','weak:2']);
 cases++;
}
console.log(`Demonblade Tryndamere native cases passed: ${cases}`);
