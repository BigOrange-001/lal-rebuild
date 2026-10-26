"""Compare all 44 study branches with the actual Avatar.executeAbility code."""
import json
import re
import subprocess
import sys
import unittest

from test_avatar_passive import NODE, ROOT, method_body

sys.path.insert(0,str(ROOT/'server'))
from manual_ability_sim import SkillCompleteBattle, KINDS


HARNESS=r'''
const input=JSON.parse(require('fs').readFileSync(0,'utf8')),events=[],int=v=>Math.trunc(Number(v)||0),uint=int;
const row={manualDamageMultiplier:input.damage,manualEffectMultiplier:input.effect,range:700,equipment_parts_104:input.parts||{}};
const GlobalData={$mConfig_skill:{TEST:row},$mConfig_simple:{skill_effect_radius_scale:1.4}};
let context;
const currentAbilityAttack=()=>context,activeManualEffectMultiplier=()=>input.effect;
const Avatar={};
function attach(u){for(const [name,[params,body]] of Object.entries(input.methods))u[name]=eval('(function('+params+'){with(this){'+body+'\n}})');}
const units=input.units.map((data,i)=>Object.assign(data,{id:data.aid,hpMax:data.hp_max,abilityState:{},abilitySerial:0,
 abilityIndex:i+1,buffs:{},otherTeam:3-data.team,isManualSummonUnit:false,
 heroSkillOutputRate104:()=>1,getType:()=>1,getStar:()=>6,getDamage:()=>1000,getHpMax:()=>10000,abilityFeedback:()=>{},
 beginParallelVisualBatch:()=>null,endParallelVisualBatch:()=>{},prepareParallelVisualTarget:()=>{},
 checkMove(forward,distance,center=null){this.pos+=(this.team===1?-1:1)*(forward?1:-1)*distance;},
 reline(line,pos){this.line=line;this.pos=pos;},removeBuff(k){delete this.buffs[k];},removeAllDebuff(){},
 skill0:{useSkill(){events.push(['recast']);}}}));
const owner=units[0],GameMap={currentMap:{getAliveList(team){return units.filter(u=>u.team===team&&u.hp>0);}}},GameMapConfig={LINE_POS:3000};
for(const u of units){attach(u);
 u.addBuff=(name,turns,value=0)=>{events.push(['buff',u.id,name,turns,value*input.effect]);u.buffs[name]={value:value*input.effect};};
 u.abilityHit=(target,coefficient,kind)=>{if(!target||target.hp<=0)return false;events.push(['hit',target.id,coefficient*input.damage,kind]);return true;};
 u.abilityHeal=(target,coef)=>{if(target&&target.hp>0)events.push(['heal',target.id,coef*input.effect]);};
 u.abilityShield=(target,coef,duration=2,health=false)=>{if(target&&target.hp>0)events.push(['shield',target.id,coef*input.effect,duration,health]);};
 u.abilitySummon=(aid,count,ratio,turns,key,focus=null,clone=false)=>events.push(['summon',aid,count,ratio*input.effect,turns,key,clone]);
}
const skill={getNativeAction(){return this.skills[0];},getNativeSetting:(key,fallback=null)=>Object.hasOwn(row,key)?row[key]:fallback,skillSetData:{id:'TEST',range:700},skills:[['manual_ability',input.kind,input.scale]],getCastRange:()=>700};
context={owner,kind:'active',skill,manualDamageMultiplier:input.damage,manualEffectMultiplier:input.effect,kills:[]};
const ok=owner.executeAbility(input.kind,input.scale,'FX',skill);
process.stdout.write(JSON.stringify({ok,events}));
'''


class OracleBattle(SkillCompleteBattle):
    def __init__(self,*args,**kwargs):
        super().__init__(*args,**kwargs);self.events=[]
    def _get_damage(self,unit):return 1000
    def hit(self,owner,target,coef,kind,shared_total=0):
        if not target or target['hp']<=0:return False
        self.events.append(['hit',target['aid'],coef*self._context(owner)['damage_factor'],kind]);return True
    def heal(self,owner,target,coef):
        if target and target['hp']>0:self.events.append(['heal',target['aid'],coef*self._context(owner)['effect_factor']])
    def shield(self,owner,target,coef,duration=2,health=False):
        if target and target['hp']>0:self.events.append(['shield',target['aid'],coef*self._context(owner)['effect_factor'],duration,health])
    def summon(self,owner,aid,count,ratio,turns,key,focus=None,clone=False):
        self.events.append(['summon',aid,count,ratio*self._context(owner)['effect_factor'],turns,key,clone])
    def _add_buff(self,unit,name,turns,value=0):
        ctx=self._context();self.events.append(['buff',unit['aid'],name,turns,value*(ctx['effect_factor'] if ctx else 1)])
        super()._add_buff(unit,name,turns,value)
    def _apply_native_skill(self,owner,enemies,slot='skill'):
        self.events.append(['recast']);return True


@unittest.skipUnless(NODE,'Node is needed for the actual client ability methods')
class ManualOracleTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source=(ROOT/'client/src/stages/137_Avatar.as').read_text('utf-8')
        definitions=dict(equipmentPart104='sourceSkill,part,value',executeAbility='kind,scale,effect,sourceSkill',
          executeAbilityBody='kind,scale,effect,sourceSkill',
          nativeAbilityNumber='sourceSkill,kind,key,fallback',
          abilityEnemies='distance,center=null,maximum=1,heroOnly=false,order="nearest",excluded=null,forward=false',
          abilityCandidates='whichTeam,lane,position,distance,maximum,heroOnly=false,order="nearest",excluded=null,forward=false',
          abilityAlly='distance=3001,order="ratio",excludeSelf=false',abilityMarkedTarget='mark,distance,order="nearest"',
          abilityHasMark='owner,kind',abilityMark='target,kind,duration,scale=1',abilityDash='target,enemySide=false',
          abilityPull='target,center,amount',abilityControl='target,kind,duration,value=0',
          abilityIsolated='target',skillAreaRadius='value')
        cls.methods={}
        for name,params in definitions.items():
            body=method_body(source,name)
            body=re.sub(r'for each\s*\(([^)]+) in ([^)]+)\)',r'for (\1 of \2)',body)
            body=re.sub(r'function\(([^)]*)\)',lambda m:'function('+re.sub(r':\w+','',m[1])+')',body)
            cls.methods[name]=[params,body]
        cls.units=[dict(aid='A_1001_6',team=1,isme=True,line=0,pos=1800,hp=3000,hp_max=10000),
                   dict(aid='A_1002_6',team=1,isme=True,line=0,pos=1850,hp=2000,hp_max=10000),
                   dict(aid='A_1003_6',team=2,isme=False,line=0,pos=1600,hp=5000,hp_max=10000),
                   dict(aid='A_1004_6',team=2,isme=False,line=0,pos=1550,hp=4000,hp_max=10000),
                   dict(aid='A_1005_6',team=2,isme=False,line=0,pos=1300,hp=6000,hp_max=10000)]
        cls.config={'avatar':{u['aid']:{'range':337,'pl':[0]*14} for u in cls.units},
                    'skill':{'TEST':{}},'system_simple':{'skill_effect_radius_scale':1.4}}

    def test_equipment_component_hooks_match_client(self):
        import copy
        plan=json.loads((ROOT/'config/reconstruction/equipment-bonds-1.0.4.json').read_text('utf-8'))
        parts={r['index']:1+r['strength'] for h in plan['heroes'].values() for r in h['affinities'] if isinstance(r['index'],str)}
        original=self.config
        self.config=copy.deepcopy(original);self.config['skill']['TEST']['equipment_parts_104']=parts
        try:self.compare_branches(parts)
        finally:self.config=original

    def test_every_named_branch_matches_client_coefficients_and_targets(self):
        self.compare_branches({})

    def compare_branches(self,parts):
        # Unequal factors expose damage/effect double-counting and missing paths.
        for kind in sorted(KINDS):
            with self.subTest(kind=kind):
                options=dict(kind=kind,scale=1.3,damage=1.5625,effect=1.25,parts=parts)
                proc=subprocess.run([NODE,'-e',HARNESS],input=json.dumps(dict(methods=self.methods,units=self.units,**options)),
                                    capture_output=True,text=True,encoding='utf-8',timeout=15)
                self.assertEqual(proc.returncode,0,proc.stderr)
                actual=json.loads(proc.stdout)
                engine=OracleBattle(self.units[:2],self.units[2:],config=self.config)
                owner=engine.a[0];owner['skill']={'skills':[['damage',1,1,'FX']]}
                skill=dict(skid='TEST',pl=[0,0,700],skills=[['manual_ability',kind,options['scale']]])
                with engine.context(owner,'active',skill,options['damage'],options['effect']):
                    ok=engine.execute(owner,kind,options['scale'],skill)
                self.assertEqual(ok,actual['ok'])
                self.assertEqual(len(engine.events),len(actual['events']), (engine.events,actual['events']))
                for expected,observed in zip(engine.events,actual['events']):
                    self.assertEqual(len(expected),len(observed))
                    for x,y in zip(expected,observed):
                        if type(x) in (int,float) and type(y) in (int,float):self.assertAlmostEqual(x,y,places=8)
                        else:self.assertEqual(x,y)


if __name__=='__main__':unittest.main()
