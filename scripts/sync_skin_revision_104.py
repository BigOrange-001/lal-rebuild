"""Insert the maintained skin runtime into the existing Avatar replacement."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=root/'client/src/stages/137_Avatar.as'
s=p.read_text('utf8')
start='      // BEGIN SKIN REVISION V2\n';end='      // END SKIN REVISION V2\n'
code=(root/'client/src/skin_revision_v2.aspart').read_text('utf8').replace('damage+=','ap+=')
if start in s:s=s[:s.index(start)]+s[s.index(end)+len(end):]
anchor='      public function equipmentPart104('
s=s.replace(anchor,start+code+'\n'+end+'\n'+anchor,1)
def once(old,new):
 global s
 if new not in s:
  if old not in s:raise RuntimeError(old[:100])
  s=s.replace(old,new,1)
once('         if(kind == "cat_n" || kind == "cat_c")','         if(kind.indexOf("skin2_")==0) return executeSkin2(kind,sourceSkill);\n         if(kind == "cat_n" || kind == "cat_c")')
s=s.replace('return skin2CanCast(kind);','return skin2CanCast(kind,sourceSkill);')
once('         var center:Avatar;\n         switch(kind)','         if(kind.indexOf("skin2_")==0) return skin2CanCast(kind,sourceSkill);\n         var center:Avatar;\n         switch(kind)')
once('         if(!skillB || !skillB.isModEffectSequence() || !GameMap.currentMap) return false;','         skin2Event(event,source,target,amount,overheal);\n         if(!skillB || !skillB.isModEffectSequence() || !GameMap.currentMap) return false;')
once('         manualOwnerActionSerial = 0;','         manualOwnerActionSerial = 0;\n         skin2 = {};')
once('         return hp <= 0;\n      }\n      public static function skillAreaRadius','         return hp <= 0 || Boolean(skin2.eggUntil);\n      }\n      public static function skillAreaRadius')
once('            _loc9_ = buffs["shield"] as Buff;\n            if(_loc9_)','            param1 = int(skin2Incoming(param1,param7 || param5,param4));\n            _loc9_ = buffs["shield"] as Buff;\n            if(_loc9_)')
once('            var bookHealer:Avatar = param7 || param5 || this;','            param1 = int(skin2Incoming(param1,param7 || param5,param4));\n            var bookHealer:Avatar = param7 || param5 || this;')
once('         if(hp <= 0 && buffs["bless"])','         skin2Lethal();\n         if(hp <= 0 && buffs["bless"])')
once('         var modKilled:Boolean = abilityHpBefore > 0 && hp <= 0;','         if(param4==6 && param7 && param7.s2Family()==1209 && modActualDamage>0) param7.skin2PoisonTick(this);\n         var modKilled:Boolean = abilityHpBefore > 0 && hp <= 0;')
once('         if(param5 && abilityState.channel) return 0;','         if(param5 && abilityState.channel) return 0;\n         if(!param5 && s2LiveMark(this,"cold") && param2>0) param2=Math.round(param2*.5);')
once('         if(forced && abilityState.channel) return;','         if(forced && abilityState.channel) return;\n         if(!forced && s2LiveMark(this,"cold") && param2!=-2147483648) param2=pos+Math.round((param2-pos)*.5);')
once('         var talent:Number = checkTalent(damageType == 1 ? 2 : 3);','         if(source && damageType==1) {\n            if(s2LiveMark(this,"wanted") && skin2.wanted.owner===source) penetration=Math.max(penetration,.25);\n            if(source.skin2.penetrationEnd && source.manualOwnerActionSerial<=source.skin2.penetrationEnd) penetration=Math.max(penetration,.3);\n         }\n         var talent:Number = checkTalent(damageType == 1 ? 2 : 3);')
once('      protected function removeAllDebuff() : void\n      {','      protected function removeAllDebuff() : void\n      {\n         skin2ClearDebuffs();')
# Check traps after completed movement, not only at the next owner turn.
for method,next_method in [('checkMove','resMove'),('reline','refreshReline')]:
 marker='      public function '+method+'('
 a=s.index(marker);b=s.find('\n      }',a)
 if 'skin2Moved();' not in s[a:b]:
  if method=='checkMove':
   section=s[a:b];i=section.rfind('         return ')
   if i>=0:s=s[:a+i]+'         skin2Moved();\n'+s[a+i:]
  else:s=s[:b]+'\n         skin2Moved();'+s[b:]
p.write_bytes(s.replace('\r\n','\n').replace('\n','\r\n').encode('utf8'))
skill=root/'client/src/stages/139_SkillSet.as'
t=skill.read_text('utf8')
anchor='         if(_loc2_ && param2 >= 0 && param2 < _loc2_.length && _loc2_[param2] !== null'
if '         _loc1_ = avatar.skin2Focus(_loc1_);' not in t:
 t=t.replace(anchor,'         _loc1_ = avatar.skin2Focus(_loc1_);\n'+anchor,1)
skill.write_bytes(t.replace('\r\n','\n').replace('\n','\r\n').encode('utf8'))

# Reapplying the maintained combat part must preserve its presentation hooks.
effects=root/'scripts/sync_battle_effects_104.py'
if effects.exists() and (root/'client/src/native_effect_profiles_104.aspart').exists():
 import runpy
 runpy.run_path(str(effects),run_name='__main__')
