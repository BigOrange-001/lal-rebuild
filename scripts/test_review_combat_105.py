"""Exercise reviewed shield dispels and infection spread using real AS bodies."""
import re
import subprocess
import unittest
from pathlib import Path

from test_avatar_passive import method_body
from test_skin_revision_native_104 import balanced

ROOT = Path(__file__).resolve().parents[1]


def methods():
    source = (ROOT/'client/src/stages/137_Avatar.as').read_text('utf8')
    names = ('s2Dispel', 'shieldValue104', 'removeIndependentShields104',
             'removeBuff', 'abilityDeath', 's2AnnieCore', 's2AnnieImmune',
             's2AnnieStatus', 's2Family', 'removeAllDebuff', 'abilityClearStates',
             'skin2ClearDebuffs', 'addManualSkillDot')
    result = []
    for name in names:
        match = re.search(r'function '+name+r'\((.*?)\)\s*:\s*\w+\s*\{', source, re.S)
        args = re.sub(r':(?:\w+|\*)', '', match[1])
        body = method_body(source, name)
        for kind, js in (('Number', 'number'), ('Boolean', 'boolean'), ('String', 'string')):
            body = re.sub(r'([\w.]+) is '+kind, lambda m: '(typeof '+m[1]+' === "'+js+'")', body)
        body = re.sub(r'([\w.]+) is Array', r'Array.isArray(\1)', body)
        body = re.sub(r'([\w.]+) is Avatar', r'(\1 && \1.__avatar)', body)
        while 'for each(' in body:
            a = body.index('for each('); b = balanced(body, a+8)
            left, right = body[a+9:b].split(' in ', 1)
            body = body[:a]+'for ('+left+' of Object.values('+right+'))'+body[b+1:]
        result.append('methods.'+name+'=function('+args+'){with(this){'+body+'}};')
    return '\n'.join(result)


HARNESS = r'''
const assert=require('node:assert/strict');
const int=x=>Math.trunc(Number(x)||0),Tools={toInt:int};
function Buff(type,round,value){Object.assign(this,{type,round,value})}
Buff.LIST_BUFF=['shield','strong','armor','purify'];Buff.LIST_DEBUFF=['poison','stun','silence','sunder','weak'];
const GlobalData={$mConfig_avatar:{annie:{skin_revision_v2_104:1221},thief:{skin_revision_v2_104:1214}},
 $mConfig_skill:{passive:{annie_core_105:{cooldown:1,purify_rounds:1,debuff_rounds:2,sunder:.33,weak:.33,poison_ap:.5,control_rounds:1,stun_enabled:true}}}};
let roster=[],skin2AnnieChainDepth=0,skin2AnnieChain=[];
const GameMapLayer={gl:null},GameMap={currentMap:{getAliveList:team=>roster.filter(u=>u.hp>0&&u.team===team)}};
const methods={};
/*METHODS*/
function actor(id,team=1){
 const u=Object.assign({__avatar:true,avatarData:{id},team,otherTeam:3-team,line:0,pos:100,
 hp:10000,skin2:{},buffs:{},abilityState:{},abilityIndex:roster.length+1,abilitySerial:4,manualOwnerActionSerial:2,
 skillB:{skillSetData:{id:'passive'}},manualSkillDots:{},manualDotSerial:0,ap:1000},methods);
 u.abyssRemoveDots104=u.queueVitalBar104=u.abilityFeedback=u.fxPulse104=()=>{};
 u.yasuoImmune104=()=>false;u.showBuff=()=>{};
 u.clearManualSkillDots=()=>{u.manualSkillDots={}};
 u.beginAbilityAttack=()=>({});u.endAbilityAttack=()=>{};u.getDamage=()=>u.ap;
 u.addBuff=(key,round,value=0)=>{u.buffs[key]={round,value,type:key}};
 u.s2Pick=()=>roster.find(v=>v.team===u.team&&v!==u&&v.hp>0);
 u.s2Value=(skill,key)=>key==='stealCap'?.5:.25;
 roster.push(u);return u;
}
function fresh(){roster=[];skin2AnnieChainDepth=0;skin2AnnieChain=[]}
'''


class ReviewCombatTests(unittest.TestCase):
    def run_case(self, body):
        result = subprocess.run(['node'], input=HARNESS.replace('/*METHODS*/', methods())+body,
                                capture_output=True, text=True, encoding='utf8')
        self.assertEqual(result.returncode, 0, result.stdout+'\n'+result.stderr)

    def test_independent_and_mixed_shield_dispels_and_steal_cap(self):
        self.run_case(r'''
for(const all of [false,true])for(const ordinary of [0,100]){
 fresh();const thief=actor('thief'),ally=actor('ally'),target=actor('yasuo',2);
 target.buffs.yasuoShield104_1={type:'shield',value:200};
 target.buffs.yasuoShield104_2={type:'shield',value:450};
 if(ordinary)target.buffs.shield={type:'shield',value:ordinary};
 target.buffs.strong={type:'strong',value:1};
 assert.equal(thief.s2Dispel(target,all),all?2:1);
 assert.equal(target.shieldValue104(),0,'explicit dispel clears all independent shield pools');
 assert.equal(!!target.buffs.strong,!all,'single dispel leaves the next buff alone');
 assert.equal(ally.buffs.shield.value,500,'steal uses combined shields with the existing AP cap');
}
fresh();const thief=actor('thief'),ally=actor('ally'),target=actor('yasuo',2);
target.buffs.yasuoShield104_1={type:'shield',value:125};
assert.equal(thief.s2Dispel(target),1);assert.equal(ally.buffs.shield.value,125);
assert.equal(thief.s2Dispel(target),0,'empty shields do not count as another dispel');
''')

    def test_death_spread_respects_immunity_purify_and_annie_reaction(self):
        self.run_case(r'''
function spread(id,mode){
 fresh();const target=actor(id),ally=actor('ally'),caster=actor('malzahar',2),dead=actor('dead');
 dead.hp=0;caster.abilityCandidates=()=>[target];
 const state={owner:caster,hops:0,ticks:2,until:1,tickDamage:100,debuff:true};
 dead.abilityState.malz_7=state;
 if(mode==='immune')target.skin2.anniePurifyUntil=target.manualOwnerActionSerial+1;
 if(mode==='purify')target.buffs.purify={type:'purify',value:2};
 if(mode==='cooldown')target.skin2.annieCoreNext=target.manualOwnerActionSerial+1;
 dead.abilityDeath();assert(!dead.abilityState.malz_7);
 return {target,ally,caster,state,dead};
}
for(const id of ['ally','annie'])for(const mode of ['immune','purify']){
 const {target,caster,state}=spread(id,mode);
 assert(!target.abilityState.malz_7,'blocked infection never enters status state');
 assert.equal(Object.keys(caster.manualSkillDots).length,0,'blocked infection does not retaliate');
 assert.equal(state.hops,0);
 if(mode==='purify')assert.equal(target.buffs.purify.value,1,'consume one native purify charge');
}
{
 const {target,ally,caster,dead}=spread('annie','ready');
 assert(!target.abilityState.malz_7,'ready Annie cleanses the newly spread infection');
 assert(target.s2AnnieImmune()&&ally.s2AnnieImmune());
 assert(Object.keys(caster.manualSkillDots).length&&caster.buffs.stun&&caster.buffs.silence);
 assert(!caster.buffs.poison);assert.equal(Object.values(caster.manualSkillDots)[0].hpMaxFraction,0);
 const next=target.skin2.annieCoreNext;dead.abilityDeath();
 assert.equal(target.skin2.annieCoreNext,next,'death is handled exactly once');
}
for(const [id,mode] of [['ally','normal'],['annie','cooldown']]){
 const {target,caster,state}=spread(id,mode);
 assert.equal(target.abilityState.malz_7,state);assert.equal(state.hops,1);
 assert.equal(state.until,target.abilitySerial+1);assert.equal(Object.keys(caster.manualSkillDots).length,0);
}
''')


if __name__ == '__main__':
    unittest.main()
