"""Execute the client curse action, targeting, buff rules and VFX scheduling.

Only AS type declarations are removed. Display stubs inspect geometry and
cleanup; these checks do not replace a visual playtest on an Android device.
"""
import json
import re
import subprocess
import sys
import unittest

from test_avatar_passive import NODE, ROOT, method_body

sys.path.insert(0, str(ROOT / 'server'))
from upstream_skill_priority import apply_upstream_skill_priority


HARNESS = r'''
const vm = require('node:vm');
const input = JSON.parse(require('node:fs').readFileSync(0, 'utf8'));
const noop = () => {};
const pending = [], tweens = [], labels = [];
function Sprite() {
  Object.assign(this, {children:[], x:0, y:0, scaleX:1, scaleY:1, alpha:1});
  this.removeChild = child => {
    this.children = this.children.filter(value => value !== child);
    if (child.parent === this) child.parent = null;
  };
  this.removeFromParent = () => { if (this.parent) this.parent.removeChild(this); };
}
Sprite.prototype.addChild = function(child) {
  if (child.parent) child.parent.removeChild(child);
  this.children.push(child); child.parent=this; return child;
};
function Quad(width,height,color) { Sprite.call(this); Object.assign(this,{width,height,color}); }
function Tween(target,duration,transition='linear') {
  if (!['linear','easeIn','easeOut','easeInOut','easeOutIn','easeInBack','easeOutBack',
        'easeInOutBack','easeOutInBack','easeInElastic','easeOutElastic',
        'easeInOutElastic','easeOutInElastic','easeInBounce','easeOutBounce',
        'easeInOutBounce','easeOutInBounce'].includes(transition))
    throw Error('Unsupported Starling transition: '+transition);
  Object.assign(this,{target,duration});
}
Tween.prototype.scaleTo=function(value){this.scale=value;};
Tween.prototype.fadeTo=function(value){this.alpha=value;};
const layer={effectLayer:new Sprite(),infoLayer:{popTextForAvatar:noop,popInjuredForAvatar:noop},
  getLineSpr(line){return {x:line*200,y:0};},
  delayCall(fn,delay,...args){pending.push({fn,delay,args});},
  addTween(tween){tweens.push(tween);}};
layer.effectLayer.globalToLocal=p=>p;
function flush(){
  while(pending.length){pending.sort((a,b)=>a.delay-b.delay);const p=pending.shift();p.fn(...p.args);}
}
const GameMap={actionDelay:1};
const clone=value=>value ? JSON.parse(JSON.stringify(value)) : value;
const context=vm.createContext({
  GameMap,GameMapLayer:{gl:layer},GameMapConfig:{LINE_POS:3000,MIN_SPACE_POS:300,
    lineToPixel(line,offset){return 100+line*200+offset/6;},posToPixel(pos){return 650-pos/6;}},
  Buff,Sprite,Quad,Tween,BUFF_CURSE:'curse',
  Tools:{toInt:Math.trunc,clone,sortVector(list,sort){return list.slice().sort(sort || (()=>0));}},
  DisplayTools:{getAttrs(key){return clone(input.effects[key]);},
    newDisplayObject(attrs){const native=new Sprite();native.nativeAsset=attrs.id;return native;},
    newTextField(text){const field=new Sprite();field.text=text;labels.push(text);return field;},
    addBullet(){return .25;},addEffects:noop,addSound:noop},
  AvatarData:{isAttack(type){return type>=1 && type<=3;},canMiss(type){return type>=1 && type<=3;}},
  GlobalLanguageStr:{getLanguageStr(id){return String(id);}},
  GameMapTools:{gameTrace:noop,toPercentage(value){return String(value);}},
  GlobalData:{$mConfig_simple:input.simple},Point:function(x=0,y=0){this.x=x;this.y=y;},trace:noop,int:Math.trunc,uint:value=>value>>>0,Math,Number,isFinite,String
});
function compile(name,params){return vm.runInContext('(function('+params+'){with(this){'+input.methods[name]+'\n}})',context);}
function install(host,name,params){host[name]=compile(name,params).bind(host);}
function Buff(type,round,value=0){
  Object.assign(this,{type,round,value,m_do:null});
  Object.defineProperty(this,'displayObject',{get:compile('displayObject','').bind(this)});
}
Buff.LIST_BUFF=['shield','strong','taunt','bless','steel','armor','hitup','fleeup','critup','toughup','purify'];
Buff.LIST_DEBUFF=['root','stun','silence','weak','sunder','poison','burn','evil','curse'];
function unit(team,line,pos){
  const host={id:'A_1001_6',team,otherTeam:3-team,line,pos,offset:0,hp:100000,hpMax:100000,
    buffs:{},abilityState:{},manualSkillDots:{},tryndUndyingActive:false,m_buff:new Sprite(),
    avatarData:{id:'A_1001_6',type:1},fightRes:{parent:{setFirst:noop},x:0,y:100,pivotX:0,pivotY:0,localToGlobal(p){return {x:line*200+p.x,y:100+p.y};}},manualFocusTarget:null,skillB:null,
    currentAbilityAttack(){return {kind:'active'};},purpleBondMultiplier(){return 1;},
    prepareParallelVisualTarget:noop,playParallelAttackTween:()=>true,
    emitModEvent:noop,
    abilityDirectMultiplier(){return 1;},getTeamHp:noop,getDamage(){return 100;},getTough(){return 0;},
    refreshHp:noop,abilityRecordDamage:noop,resSwing:noop,queueRangePreview:noop,
    checkTalent(){return 0;},getEffectiveActionType(){return 1;},getSortOnFun(){return null;},
    isResolvingSkill(){return true;},isRangedSkillCaster(){return true;},
    attackTween:noop,tickManualLethalFloors:noop,abilityClearStates:noop,clearManualSkillDots:noop,
    hasManualDamageOverTime(){return false;},hasManualDotKind(){return false;},
    checkMove(forward,distance,anchor){this.pos=forward?1500:(this.team===1?0:3000);},
    countDamage(a,b,base){return [base,false];},checkMiss(){return false;},checkCrit(){return 1;}};
  for(const name of ['showBuff','showCurseImpact','removeAllDebuff','removeAllGoodBuff','checkBuff','getType'])
    install(host,name,name==='showBuff'?'param1':'');
  install(host,'removeBuff','param1,consume=false');
  install(host,'addBuff','param1,param2,param3=0,param4=0,param5=-1,param6=null');
  install(host,'injured','param1,param2=1,param3=null,param4=-1,param5=null,param6=false,param7=null,param8=null,dotKind=""');
  install(host,'findAimList','param1,param2=null,param3=-1,param4=false');
  install(host,'checkAttack','param1,param2,param3=-1,param4=false,param5=-1,param6=1,param7=0,param8=null,param9=null,param10=1');
  install(host,'checkAllAttack','param1,param2,param3=-1,param4=false,param5=-1,param6=1,param7=0,param8=null,param9=null,param10=1');
  install(host,'attackAimList','param1,param2=-1,param3=1,param4=0,param5=null,param6=false,param7=null,param8=-1,param9=1,effectSource=null');
  return host;
}
const team=input.team || 1;
const caster=unit(team,1,1500);
const enemies=[0,1,2].flatMap(line=>[0,1500,3000].map(pos=>unit(3-team,line,pos)));
const map={gameMapData:{win:[-1]},getAliveList(side){return (side===team?[caster]:enemies).filter(unit=>unit.hp>0);},
  isEnd(){return false;},getShowLine(line){return line;}};
GameMap.currentMap=map;
if(input.dead) enemies[0].hp=0;
if(input.immune) enemies.forEach(enemy=>enemy.buffs.purify=new Buff('purify',1));
const row=input.skill;context.GlobalData.$mConfig_skill={[row.id]:row};
const groups=input.fullCast ? {} : {cluster:enemies.slice()};
const skill={baseActionCount104:()=>row.skill.length,avatar:caster,skills:row.skill,skillSetData:{...row,range:row.pl[2],aoe:row.pl[4],banStand:false},
  currentActionTargets:[],currentTargetGroups:groups,preparingCast:false,sortAnchor:null,
  isSuper:false,abilityHasCast:false,abilityCooldownOverride:-1,inKillRecast:false,lv:1,
  m_cooldownNum:-1,activeNativeSource:null,activeNativeAction:null,activeNativeSettings:null,getNativeAction(){return this.activeNativeAction||null;},isModEffectSequence:()=>false,getNativeSetting:(key,fallback=null)=>Object.hasOwn(row,key)?row[key]:fallback,getMechanismId:()=>row.id};
context.Avatar={beginAbilityAttack(){return {};},endAbilityAttack:noop,skillAreaRadius(v){return v;}};
layer.infoLayer.showSkill=noop;
context.GlobalLanguageStr.getStr=id=>String(id);
for(const name of ['getCastRange','hasCastTargets','useSkill']) install(skill,name,'');
for(const name of ['isEnemyTargetAction','isDirectDamageAction']) install(skill,name,'param1');
install(skill,'getCustomActionTargets','param1,param2,param3,param4');
install(skill,'damageShareTotal','param1,param2,param3,param4,param5,param6=-1');
install(skill,'damageShareWeight','param1,param2');
install(skill,'actionShareGroupFor','param1');
install(skill,'plannedDirectDamageTotal','param1,param2,param3,param4,param5=-1');
for(const name of ['getActionCenter','hasActionCenter','getActionPolicyArgs']) install(skill,name,'param1');
for(const name of ['getActionPolicy','getActionRange']) install(skill,name,'param1,param2=null');
for(const name of ['getActionSortFunction']) install(skill,name,'param1,param2,param3=null');
for(const name of ['getActionAoeIndex','hasDistinctActionTarget','applyActionTargetLock']) install(skill,name,'param1,param2,param3');
install(skill,'selectAndCapActionTargets','param1,param2');
install(skill,'applyActionTargetPolicy','param1,param2,param3=null');
install(skill,'applyActionTargetLinks','param1,param2,param3,param4');
install(skill,'curseAction','_loc20_,_loc14_,_loc26_,_loc24_,_loc2_,_loc7_,actionTargets,targetGroups');
const index=row.skill.findIndex(action=>action[0]==='curse');
if(input.fullCast) skill.useSkill();
else skill.curseAction(row.skill[index],index,map,row.pl[2],false,row.pl[4],skill.currentActionTargets,groups);
flush();
const accepted=enemies.filter(enemy=>enemy.buffs.curse);
const display=accepted[0] && accepted[0].buffs.curse.displayObject;
const result={accepted:accepted.length,deadHasCurse:!!enemies[0].buffs.curse,
  casterHasCurse:!!caster.buffs.curse,impacts:layer.effectLayer.children.length,
  labels,sealAsset:display ? display.nativeAsset:null,
  attached:accepted.every(enemy=>enemy.buffs.curse.displayObject.parent===enemy.m_buff),
  hp:enemies.map(enemy=>enemy.hp)};
for(const enemy of accepted){enemy.addBuff('shield',2,999);enemy.addBuff('strong',2,1);}
result.blocked=accepted.every(enemy=>!enemy.buffs.shield && !enemy.buffs.strong);
if(input.cleanse){
  for(const enemy of accepted) enemy.addBuff('purify',1);
  flush();
  result.remaining=accepted.filter(enemy=>enemy.buffs.curse).length;
  result.visibleAfterCleanse=accepted.some(enemy=>enemy.m_buff.children.some(child=>child.name==='curseSeal'));
}else if(accepted.length){
  const enemy=accepted[0];
  result.turns=[];
  for(let turn=0;turn<3;turn++){enemy.checkBuff();flush();result.turns.push(!!enemy.buffs.curse);}
  enemy.addBuff('shield',2,999);flush();result.shieldAfterExpiry=!!enemy.buffs.shield;
  result.visibleAfterExpiry=enemy.m_buff.children.some(child=>child.name==='curseSeal');
}
for(const tween of tweens) if(tween.onComplete) tween.onComplete(...tween.onCompleteArgs);
result.burstsAfterCleanup=layer.effectLayer.children.length;
process.stdout.write(JSON.stringify(result));
'''


@unittest.skipUnless(NODE, 'Node is needed for the client control-flow harness')
class CurseClientCombatTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        avatar = (ROOT/'client/src/stages/137_Avatar.as').read_text(encoding='utf-8')
        skill = (ROOT/'client/src/stages/139_SkillSet.as').read_text(encoding='utf-8')
        buff = (ROOT/'client/src/stages/140_Buff.as').read_text(encoding='utf-8')
        cls.methods = {}
        for source, names in (
            (avatar, ('addBuff','showBuff','removeBuff','removeAllDebuff','removeAllGoodBuff',
                      'checkBuff','injured','checkAttack','checkAllAttack','attackAimList',
                      'findAimList','showCurseImpact','getType')),
            (skill, ('getCastRange','getActionPolicy','getActionRange','getActionPolicyArgs',
                     'getActionCenter','hasActionCenter','getActionSortFunction',
                     'getActionAoeIndex','hasDistinctActionTarget','applyActionTargetLock',
                     'selectAndCapActionTargets','applyActionTargetPolicy','applyActionTargetLinks',
                     'hasCastTargets','getCustomActionTargets','isEnemyTargetAction',
                     'useSkill','isDirectDamageAction','damageShareTotal','damageShareWeight',
                     'actionShareGroupFor','plannedDirectDamageTotal')),
            (buff.replace('function get displayObject','function displayObject'),
             ('displayObject',)),
        ):
            # ActionScript int locals default to zero rather than undefined.
            source = re.sub(r'(var\s+\w+:int)\s*;',r'\1 = 0;',source)
            source = re.sub(r'\)\s*:\s*Vector\.<\w+>',') : Object',source)
            for name in names:
                cls.methods[name] = cls.translate(method_body(source,name))
        branch=skill.rsplit('case "curse":',1)[1].split('case "pull":',1)[0]
        # Wrap a branch in a function so the shared parser removes AS types.
        wrapped='function curseAction():void {var _loc3_:Vector.<Avatar>; var _loc1_:Avatar;'+branch.replace('break;','return;')+'}'
        cls.methods['curseAction']=cls.translate(method_body(wrapped,'curseAction'))
        document=json.loads((ROOT/'config/reconstruction/full-config.json').read_text(encoding='utf-8'))
        apply_upstream_skill_priority(document)
        cls.config=document['cfg']

    @staticmethod
    def translate(body):
        body=re.sub(r'(function\s*(?:\w+)?\s*\()([^)]*)(\))',
                    lambda m:m[1]+re.sub(r':\s*(?:Vector\.<\w+>|\w+|\*)','',m[2])+m[3],body)
        body=re.sub(r'for each\s*\(([^)]+) in ([^)]+)\)',r'for (\1 of \2)',body)
        body=re.sub(r'new Vector\.<\w+>\(\)','[]',body)
        body=re.sub(r'([\w.]+(?:\[[^\]]+\])?) is (?:Vector\.<\w+>|Array)',r'Array.isArray(\1)',body)
        body=re.sub(r'([\w.]+(?:\[[^\]]+\])?) is (String|Object|Number|Boolean|int|uint)',
                    lambda m:'(typeof '+m[1]+' === "'+({'int':'number','uint':'number'}.get(m[2],m[2].lower()))+'")',body)
        body=re.sub(r'([\w.]+(?:\[[^\]]+\])?) is Avatar',r'!!\1',body)
        return body

    def run_client(self, **options):
        data={'methods':self.methods,'skill':self.config['skill']['S_201226_6'],
              'effects':self.config['effect'],'simple':self.config['system_simple'],**options}
        result=subprocess.run([NODE,'-e',HARNESS],input=json.dumps(data),
                              capture_output=True,text=True,encoding='utf-8',timeout=15)
        self.assertEqual(result.returncode,0,result.stderr)
        return json.loads(result.stdout)

    def test_curse_reaches_all_three_lanes_without_damage_and_blocks_buffs(self):
        for team in (1,2):
            with self.subTest(team=team):
                result=self.run_client(team=team)
                self.assertEqual(result['accepted'],9)
                self.assertFalse(result['casterHasCurse'])
                self.assertEqual(result['hp'],[100000]*9)
                self.assertTrue(result['blocked'])
                self.assertTrue(result['attached'])
                self.assertEqual(result['impacts'],9)
                self.assertEqual(result['sealAsset'],'e704')
                self.assertEqual(result['labels'],[])
                self.assertEqual(result['burstsAfterCleanup'],0)

    def test_full_thunder_cast_push_damage_weak_then_curse(self):
        for team in (1,2):
            with self.subTest(team=team):
                result=self.run_client(team=team,fullCast=True)
                self.assertEqual(result['accepted'],9)
                self.assertTrue(result['blocked'])
                self.assertTrue(result['attached'])
                self.assertEqual(result['impacts'],9)
                self.assertTrue(all(hp < 100000 for hp in result['hp']))

    def test_two_target_turns_then_expiry_restore_buff_acceptance(self):
        result=self.run_client()
        self.assertEqual(result['turns'],[True,True,False])
        self.assertTrue(result['shieldAfterExpiry'])
        self.assertFalse(result['visibleAfterExpiry'])

    def test_purify_prevents_curse_and_its_visuals(self):
        result=self.run_client(immune=True)
        self.assertEqual(result['accepted'],0)
        self.assertEqual(result['impacts'],0)
        self.assertNotIn('诅咒',result['labels'])

    def test_purify_cleanses_state_and_attached_marker(self):
        result=self.run_client(cleanse=True)
        self.assertEqual(result['remaining'],0)
        self.assertFalse(result['visibleAfterCleanse'])

    def test_dead_targets_are_skipped(self):
        result=self.run_client(dead=True)
        self.assertEqual(result['accepted'],8)
        self.assertEqual(result['impacts'],8)
        self.assertFalse(result['deadHasCurse'])


if __name__ == '__main__':
    unittest.main()
