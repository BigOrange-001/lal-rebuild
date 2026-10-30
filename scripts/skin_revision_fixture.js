const assert=require('assert'),fs=require('fs');
const data=/*RUNTIME_DATA*/;
let skin2Depth=0,serial=0,contexts=[],roster=[];
const int=x=>Math.trunc(Number(x)||0),Tools={toInt:int},GameMapConfig={LINE_POS:3001};
const Buff={LIST_BUFF:['shield','strong','armor','steel','purify','bless','fleeup'],LIST_DEBUFF:['stun','silence','poison','curse','root']};
const GlobalData={$mConfig_skill:data.skill,$mConfig_avatar:{}};
const GameMap={currentMap:{getAliveList:team=>roster.filter(u=>u.team===team&&u.hp>0),roundNum:1}};
const currentAbilityAttack=()=>contexts.at(-1),beginAbilityAttack=(owner,kind)=>{let c={owner,kind,damage:0,hitSerial:0};contexts.push(c);return c},endAbilityAttack=()=>contexts.pop();
const methods={};
/*METHODS*/
function unit(family=0,team=1,pos=1500){
 const aid=`A_${family}_6`,def=data.avatar[aid];GlobalData.$mConfig_avatar[aid]={skin_revision_v2_104:family};
 let u=Object.assign({skin2:{},abilityState:{},avatarData:{id:aid},abilityIndex:++serial,hp:100000,hpMax:100000,ap:1000,team,otherTeam:3-team,pos,line:0,range:300,buffs:{},manualOwnerActionSerial:1,isManualSummonUnit:false},methods);
 u.getDamage=()=>u.ap;u.getType=()=>u.isManualSummonUnit?2:1;
 u.getHpMax=()=>u.hpMax;u.heroSkillOutputRate104=()=>.8;
 u.beginAbilityAttack=beginAbilityAttack;u.endAbilityAttack=endAbilityAttack;u.currentAbilityAttack=currentAbilityAttack;
 u.abilityFeedback=()=>{};u.abilityControl=(v,k,d,value=0)=>{if(v&&v.hp>0)v.addBuff(k,d,value)};
 u.removeBuff=k=>delete u.buffs[k];u.removeAllDebuff=()=>{u.skin2ClearDebuffs();for(let k of Buff.LIST_DEBUFF)delete u.buffs[k]};
 u.addBuff=(k,d,value=0)=>{if(k==='purify')u.removeAllDebuff();if(Buff.LIST_DEBUFF.includes(k)&&u.buffs.purify){delete u.buffs.purify;return;}let old=u.buffs[k];u.buffs[k]={round:d,value:k==='shield'&&old?Math.max(old.value,value):value};};
 u.abilityCandidates=(which,lane,position,range,max,heroOnly=false,order='nearest',excluded=[])=>{
  let a=roster.filter(v=>v.hp>0&&v.team===which&&v.line===lane&&Math.abs(v.pos-position)<=range&&!(excluded||[]).includes(v)&&(!heroOnly||!v.isManualSummonUnit));
  a.sort((a,b)=>order==='ratio'?a.hp/a.hpMax-b.hp/b.hpMax:order==='attack'?b.ap-a.ap:order==='farthest'?Math.abs(b.pos-position)-Math.abs(a.pos-position):Math.abs(a.pos-position)-Math.abs(b.pos-position));return max<0?a:a.slice(0,max)
 };
 u.abilityAllEnemies=()=>roster.filter(v=>v.team!==team&&v.hp>0);
 u.abilityHit=(target,coefficient,kind)=>{if(!target||target.hp<=0)return false;let c=currentAbilityAttack();if(c)c.hitSerial++;target.injured(int(u.ap*coefficient*.8),1,null,kind,u,false,u);return true;};
 u.injured=(amount,crit,effect,kind,source,flag,owner)=>{
  let before=u.hp,over=0;amount=u.skin2Incoming(amount,owner||source,kind);
  if(kind===4){u.hp=Math.min(u.hpMax,u.hp+amount);over=Math.max(0,amount-(u.hp-before));if(source)source.skin2Event('heal_done',source,u,u.hp-before,over);return u.hp-before;}
  if(u.buffs.shield){let n=Math.min(amount,u.buffs.shield.value);amount-=n;u.buffs.shield.value-=n;if(!u.buffs.shield.value)delete u.buffs.shield;}
  u.hp=Math.max(0,u.hp-amount);let loss=before-u.hp;u.skin2Lethal();let c=currentAbilityAttack();if(c)c.damage+=loss;
  if(loss){u.skin2Event('damage_taken',source,u,loss,0);if(source)source.skin2Event('damage_dealt',source,u,loss,0);}
  if(source&&kind<=3)source.skin2Event('hit',source,u,loss,0);
  if(u.hp<=0){if(source)source.skin2Event('kill',source,u,loss,0);u.skin2Event('death',source,u,loss,0);}return loss;
 };
 u.reline=(lane,pos)=>{u.line=lane;u.pos=pos};u.checkMove=(towards,distance,other)=>{u.pos+=towards?Math.sign(other.pos-u.pos)*distance:Math.sign(u.pos-other.pos)*distance};
 u.abilityDash=target=>{u.pos=target.pos+100};u.abilityPull=(target,center)=>{target.pos=center.pos-100};
 u.abilitySummon=(aid,count,ratio,turns,key)=>{let pets=[];for(let i=0;i<count;i++){let p=unit(0,team,u.pos-125);p.ap=u.ap*ratio;p.hpMax=p.hp=u.hpMax*ratio;p.isManualSummonUnit=true;p.statisticsOwner104=u;pets.push(p)}u.abilityState['summons_'+key]=pets;};
 if(def){[u.skill0,u.skill1,u.skillB]=def.skills.map(s=>({skills:structuredClone(s.skills),skillSetData:{id:s.skid,cooldown:s.pl[1]}}));}
 u.skin2Initialize();roster.push(u);return u;
}
function fresh(f){roster=[];contexts=[];skin2Depth=0;let a=unit(f),b=unit(0,2,1400),c=unit(0,2,1300),ally=unit(0,1,1600);return {a,b,c,ally}}
function cast(a,slot){let s=slot===0?a.skill0:a.skill1;beginAbilityAttack(a,'active');try{assert(a.executeSkin2(`skin2_${a.s2Family()}_${slot}`,s));}finally{endAbilityAttack();}}
function turn(a){a.manualOwnerActionSerial++;a.skin2Event('turn_start',a,a,0,0)}
let cases=0;
for(let aid of Object.keys(data.avatar)){let f=+aid.split('_')[1];let {a,b}=fresh(f);if(f!==1227)cast(a,0);if(f===1219){a.s2Mark(b,'airborne',2);b.addBuff('stun',1)}cast(a,1);assert(Number.isFinite(a.hp));cases++;}
{
 let {a,b}=fresh(1140);a.hp=70000;a.skin2.record={line:0,pos:1500,lost:0};cast(a,0);assert.equal(b.skin2['rings_'+a.abilityIndex].count,2);turn(a);cast(a,0);assert(a.buffs.shield);assert(b.hp<94400,'three-ring bonus executes');
 a.removeBuff('shield');a.skin2.lost=20000;a.hp=50000;cast(a,1);assert.equal(a.hp,62000,'rewind heals actual recorded loss');assert(a.skin2.phase);cases++;
}
{
 let {a,b}=fresh(1206);cast(a,0);assert.equal(b.skin2['rings_'+a.abilityIndex].count,2);turn(a);cast(a,0);assert.equal(b.skin2['rings_'+a.abilityIndex].count,1);cases++;
}
{
 let {a}=fresh(1210);cast(a,0);assert(a.buffs.shield);cast(a,0);cast(a,0);assert.equal(a.skin2.dance,0);cases++;
}
{
 let {a}=fresh(1221);cast(a,1);let pet=a.s2Pet();for(let i=0;i<10;i++)pet.skin2Event('turn_end',pet,pet,0,0);assert.equal(pet.skin2.bearGrowth,6);assert.equal(pet.ap,910);cast(a,1);assert.strictEqual(a.s2Pet(),pet,'captain preserves raised summon');cases++;
}
{
 let {a,b}=fresh(1216);a.hp=10;b.s2Hit(a,1);assert(a.skin2.eggUntil);assert.equal(a.hp,30000);assert(!a.skin2CanCast('skin2_1216_0'));turn(a);assert(a.skin2.eggUntil);turn(a);assert(!a.skin2.eggUntil);assert.equal(a.hp,40000);a.hp=1;b.s2Hit(a,1);assert.equal(a.hp,0,'rebirth only once');cases++;
}
{
 let {a,b,ally}=fresh(1213);cast(a,0);assert.strictEqual(a.skin2.ball,ally);beginAbilityAttack(ally,'active');ally.s2Hit(b,1);endAbilityAttack();assert.equal(a.skin2.shotUntil,3);assert.equal(a.skin2.ball,null);cases++;
}
{
 let {a,b}=fresh(1209);cast(a,0);assert.equal(a.skin2.eggs.length,1);a.skin2PoisonTick(b);assert.equal(a.skin2.eggs.length,1);turn(a);a.skin2PoisonTick(b);assert.equal(a.skin2.eggs.length,0);cases++;
}
{
 let {a,b,ally}=fresh(1201);ally.hp=20000;a.skin2Event('turn_end',a,a,0,0);beginAbilityAttack(b,'active');b.s2Hit(ally,10);endAbilityAttack();assert(a.hp<100000);assert(ally.hp>10000,'guard reduces incoming loss');assert(a.skin2.guardUsed);cases++;
}
{
 let {a,b,c}=fresh(1216);c.line=2;cast(a,0);cast(a,1);assert.equal(c.hp,100000,'lane effects cannot hit another lane');a.s2Mark(b,'cold',2);b.removeAllDebuff();assert(!a.s2LiveMark(b,'cold'));cases++;
}
{
 let {a,b}=fresh(1203);cast(a,0);for(let i=0;i<15;i++){turn(a);cast(a,0)}assert.equal(a.skin2.growth,10);assert.equal(a.hpMax,150000);assert.equal(a.ap,1400);cases++;
}
{
 let {a,b}=fresh(1211);cast(a,0);b.pos=a.pos-100;b.skin2Moved();assert(b.buffs.root);assert(!a.skin2.trap);let hp=b.hp;b.skin2Moved();assert.equal(b.hp,hp,'trap cannot trigger twice');cases++;
}
{
 let {a,b}=fresh(1203);a.getDamage=()=>2000;cast(a,0);turn(a);
 assert.equal(a.ap,1040,'growth uses entry attack even with a temporary attack buff');
 a.getDamage=()=>a.ap;for(let i=0;i<12;i++){cast(a,0);turn(a)}
 assert.equal(a.ap,1400);assert.equal(a.skin2.growth,10);cases++;
}
{
 let {a,b,ally}=fresh(1140);a.skin2.record={line:0,pos:1500,lost:0};
 b.isManualSummonUnit=true;b.s2Hit(a,10);assert.equal(a.skin2.lost,10000);
 assert.equal(a.skin2.lastHurt,undefined,'summons do not satisfy hero-hit conditions');
 a.skin2Event('damage_taken',ally,a,1000,0);assert.equal(a.skin2.lost,10000);
 const before=a.hp;cast(a,1);assert.equal(a.hp-before,6000);cases++;
}
{
 let {a,b,c}=fresh(1206);b.skin2['rings_'+a.abilityIndex]={count:2};c.hp=20000;
 cast(a,1);assert(b.hp<100000);assert.equal(c.hp,20000,'most own rings outrank low health');cases++;
}
{
 let {a,b,c}=fresh(1206);b.skin2.rings_other={count:3};c.hp=20000;
 cast(a,1);assert.equal(b.hp,100000);assert(c.hp<20000,'foreign rings ignored; ties use low HP');cases++;
}
{
 let {a,b,ally}=fresh(1215);a.abilityHit=()=>false;cast(a,0);
 assert(!a.skin2.sonic);assert(!a.skin2.ward);assert(!ally.buffs.shield);assert(!a.buffs.shield);assert.equal(b.hp,100000);cases++;
}
{
 let {a,b,ally}=fresh(1215);ally.hp=20000;cast(a,0);
 assert.strictEqual(a.skin2.sonic,b);assert.strictEqual(a.skin2.ward,ally);assert(ally.buffs.shield);cases++;
}
{
 let {a,b}=fresh(1206);a.addBuff('curse',2);a.s2Mark(a,'cold',2);cast(a,1);
 assert(!a.buffs.curse,'captain cleanses debuffs before applying buffs');
 assert(!a.skin2.cold,'captain also cleanses authored debuff marks');
 assert.equal(a.buffs.strong.value,.4);assert.equal(a.buffs.fleeup.value,8000);cases++;
}
{
 let {a,b,c}=fresh(1219);b.line=1;b.isManualSummonUnit=true;c.line=2;
 unit(0,2,1450);
 a.s2Mark(b,'airborne',1);a.s2Mark(c,'airborne',1);
 assert(a.skin2CanCast('skin2_1219_1',a.skill1));cast(a,1);
 assert.equal(a.line,2,'captain anchors on an airborne hero, ignoring airborne summons');
 assert(c.hp<100000);assert.equal(b.hp,100000);cases++;
}
{
 let {a,b,c}=fresh(1219);b.line=1;c.line=2;
 a.s2Mark(b,'airborne',1);
 let row=data.skill[a.skill1.skillSetData.id],old=row.skin_v2_bond_size;
 row.skin_v2_bond_size=4;
 assert(!a.skin2CanCast('skin2_1219_1',a.skill1),'lane-bound bond cannot consume a cast on another lane');
 b.line=0;assert(a.skin2CanCast('skin2_1219_1',a.skill1));
 a.s2Mark(b,'windmark',2);assert(a.skin2CanCast('skin2_1219_1',a.skill1));
 if(old===undefined)delete row.skin_v2_bond_size;else row.skin_v2_bond_size=old;cases++;
}
{
 let {a,b}=fresh(1206);unit(1228,1,a.pos);a.hp=50000;
 a.s2Hit(b,1,1,true);a.s2Hit(b,1,1,true);let before=a.hp;a.s2Hit(b,1,1,true);
 assert.equal(a.hp-before,Math.trunc(a.ap*a.s2Value(a.skillB,'heal')*1.25),'healing aura also amplifies ring-triggered healing');cases++;
}
console.log(`${cases} native skill/state scenarios passed`);
