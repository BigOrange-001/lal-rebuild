"""Insert the maintained skin runtime into the existing Avatar replacement."""
from pathlib import Path
root=Path(__file__).resolve().parents[1]
p=root/'client/src/stages/137_Avatar.as'
s=p.read_text('utf8')
start='      // BEGIN SKIN REVISION V2\n';end='      // END SKIN REVISION V2\n'
code=(root/'client/src/skin_revision_v2.aspart').read_text('utf8').replace('damage+=','ap+=')
if start in s:s=s[:s.index(start)].rstrip('\n')+'\n\n'+s[s.index(end)+len(end):].lstrip('\n')
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
once('         initializingFightAttributes = false;','         initializingFightAttributes = false;\n         skin2Initialize();')
once('''      protected function showBuff(param1:Buff) : void
      {
         if(!m_buff)''', '''      protected function showBuff(param1:Buff) : void
      {
         // Cleansing can run before this delayed visual callback. Only render
         // a Buff still owned by the unit, including independent DOT visuals.
         var active:Boolean = false;
         for each(var current:Buff in buffs) if(current === param1) active = true;
         if(!active && manualSkillDots)
            for each(var dot:Object in manualSkillDots) if(dot && dot.visual === param1) active = true;
         if(!active) return;
         if(!m_buff)''')
once('         if(yasuoImmune104(param1)) return;',
     '         if(yasuoImmune104(param1)) return;\n         if(s2AnnieImmune() && Buff.LIST_DEBUFF.indexOf(param1)>=0) return;')
once('         if(param1=="stun" && hp>0 && buffs.stun) kaisaNotifyStun104(this);',
     '         if(param1=="stun" && hp>0 && buffs.stun) kaisaNotifyStun104(this);\n         if(_loc9_) s2AnnieStatus(param1);')
once('         if(yasuoImmune104(param2)) return;',
     '         if(yasuoImmune104(param2)) return;\n         if(s2AnnieImmune()) return;')
once('         showBuff(_loc2_);\n      }\n\n      public function hasManualDamageOverTime()',
     '         showBuff(_loc2_);\n         s2AnnieStatus(param2);\n      }\n\n      public function hasManualDamageOverTime()')
once('         if(target.abilityState.channel && ["stun","silence","root","pull","push"].indexOf(kind)>=0) return;',
     '         if(target.s2AnnieImmune()) return;\n         if(target.abilityState.channel && ["stun","silence","root","pull","push"].indexOf(kind)>=0) return;')
once('         if(target && target.hp > 0) target.abilityState["mark_"+kind+"_"+abilityIndex] = {until:target.abilitySerial+duration,owner:this,debuff:true,scale:scale};',
     '         if(target && target.hp > 0 && !target.s2AnnieImmune())\n         {\n            target.abilityState["mark_"+kind+"_"+abilityIndex] = {until:target.abilitySerial+duration,owner:this,debuff:true,scale:scale};\n            target.s2AnnieStatus("mark");\n         }')
once('               if(target.buffs.purify) {target.removeBuff("purify",true); break;}',
     '               if(target.s2AnnieImmune()) break;\n               if(target.buffs.purify) {target.removeBuff("purify",true); break;}')
malz='               target.abilityState["malz_"+abilityIndex]={owner:this,until:target.abilitySerial+nativeAbilityNumber(sourceSkill,kind,"cast_4",1),ticks:nativeAbilityNumber(sourceSkill,kind,"cast_5",3),tickDamage:getDamage()*nativeAbilityNumber(sourceSkill,kind,"cast_6",1)*scale*manualDamageMultiplier*heroSkillOutputRate104(),hops:0,debuff:true};'
once(malz,malz+'\n               target.s2AnnieStatus("poison");')
once('                  if(next.length) { state.hops = 1; state.until = next[0].abilitySerial+1; next[0].abilityState[key] = state; }',
     '''                  if(next.length)
                  {
                     var infected:Avatar = next[0];
                     if(infected.s2AnnieImmune()) continue;
                     if(infected.buffs.purify) {infected.removeBuff("purify",true); continue;}
                     state.hops = 1; state.until = infected.abilitySerial+1; infected.abilityState[key] = state;
                     infected.s2AnnieStatus("poison");
                  }''')
bomb='               if(abilityHit(target,nativeAbilityNumber(sourceSkill,kind,"cast_2",0.8)*scale,nativeAbilityNumber(sourceSkill,kind,"cast_3",2),effect) && target.hp>0 && !target.buffs.purify) target.abilityState["bomb_"+abilityIndex]={abyssRelicContext104:abyssCaptureContext104(this),owner:this,until:target.abilitySerial+nativeAbilityNumber(sourceSkill,kind,"cast_6",1),coefficient:equipmentPart104(sourceSkill,"bomb_burst",nativeAbilityNumber(sourceSkill,kind,"cast_7",1.2))*scale,manualDamageMultiplier:manualDamageMultiplier,debuff:true};'
once(bomb,bomb.replace('&& !target.buffs.purify)', '&& !target.buffs.purify && !target.s2AnnieImmune())').replace(') target.abilityState', ')\n               {\n                  target.abilityState')+'\n                  target.s2AnnieStatus("bomb");\n               }')
once('         if(abilityTurnStart())\n         {','         if(abilityTurnStart())\n         {\n            if(skin2.eggUntil && hp > 0 && checkBuff()) dead();')
once('         manualOwnerActionSerial = 0;','         manualOwnerActionSerial = 0;\n         skin2 = {};')
once('         return hp <= 0;\n      }\n      public static function skillAreaRadius','         return hp <= 0 || Boolean(skin2.eggUntil);\n      }\n      public static function skillAreaRadius')
if 'param1 = int(skin2Incoming(param1,param7 || param5,param4));' not in s:
 once('            _loc9_ = buffs["shield"] as Buff;\n            if(_loc9_)','            param1 = int(skin2Incoming(param1,param7 || param5,param4));\n            _loc9_ = buffs["shield"] as Buff;\n            if(_loc9_)')
once('            var bookHealer:Avatar = param7 || param5 || this;','            param1 = int(skin2Incoming(param1,param7 || param5,param4));\n            var bookHealer:Avatar = param7 || param5 || this;')
once('         if(hp <= 0 && buffs["bless"])','         skin2Lethal();\n         if(hp <= 0 && buffs["bless"])')
once('         var modKilled:Boolean = abilityHpBefore > 0 && hp <= 0;','         if(param4==6 && param7 && param7.s2Family()==1209 && modActualDamage>0) param7.skin2PoisonTick(this);\n         var modKilled:Boolean = abilityHpBefore > 0 && hp <= 0;')
once('         if(param5 && abilityState.channel) return 0;','         if(param5 && abilityState.channel) return 0;\n         if(!param5 && s2LiveMark(this,"cold") && param2>0) param2=Math.round(param2*s2ColdMoveFactor());')
once('         if(forced && abilityState.channel) return;','         if(forced && abilityState.channel) return;\n         if(!forced && s2LiveMark(this,"cold") && param2!=-2147483648) param2=pos+Math.round((param2-pos)*s2ColdMoveFactor());')
once('         var talent:Number = checkTalent(damageType == 1 ? 2 : 3);','         if(source && damageType==1) {\n            if(s2LiveMark(this,"wanted") && skin2.wanted.owner===source) penetration=Math.max(penetration,source.s2Value(source.skill0,"penetration"));\n            if(source.skin2.penetrationEnd && source.manualOwnerActionSerial<=source.skin2.penetrationEnd) penetration=Math.max(penetration,source.s2Value(source.skill1,"penetration"));\n         }\n         var talent:Number = checkTalent(damageType == 1 ? 2 : 3);')
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
skill_newline='\r\n' if b'\r\n' in skill.read_bytes() else '\n'
t=skill.read_text('utf8')
original_skill=t
anchor='         if(_loc2_ && param2 >= 0 && param2 < _loc2_.length && _loc2_[param2] !== null'
if '         _loc1_ = avatar.skin2Focus(_loc1_);' not in t:
 t=t.replace(anchor,'         _loc1_ = avatar.skin2Focus(_loc1_);\n'+anchor,1)
if t!=original_skill:skill.write_text(t,encoding='utf8',newline=skill_newline)

# Reapplying the maintained combat part must preserve its presentation hooks.
effects=root/'scripts/sync_battle_effects_104.py'
if effects.exists() and (root/'client/src/native_effect_profiles_104.aspart').exists():
 import runpy
 runpy.run_path(str(effects),run_name='__main__')
