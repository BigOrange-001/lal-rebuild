"""Attach Yasuo and the narrowly scoped independent-shield integration hooks."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parents[1]
p = ROOT / 'client/src/stages/137_Avatar.as'
s = p.read_text('utf-8')
start = '      // BEGIN NIGHTBRINGER YASUO 104\n'
end = '      // END NIGHTBRINGER YASUO 104\n'
if start in s:
    s = s[:s.index(start)] + s[s.index(end) + len(end):]
anchor = '      public function abilityCanCast('
code = (ROOT / 'client/src/nightbringer_yasuo.aspart').read_text('utf-8')
code += '\n' + (ROOT/'client/src/nightbringer_yasuo_effects.aspart').read_text('utf-8')
s = s.replace(anchor, start + code + '\n' + end + '\n' + anchor, 1)


def once(old, new):
    global s
    if new in s:
        return
    if old not in s:
        raise ValueError('Missing Yasuo hook: ' + old[:110])
    s = s.replace(old, new, 1)


once('         if(kind.indexOf("dragon_kaisa_")==0) return kaisaCanCast104(kind);',
     '         if(kind.indexOf("night_yasuo_")==0) return yasuoCanCast104(kind);\n'
     '         if(kind.indexOf("dragon_kaisa_")==0) return kaisaCanCast104(kind);')
once('         if(kind.indexOf("dragon_kaisa_")==0) return kaisaExecute104(kind,sourceSkill);',
     '         if(kind.indexOf("night_yasuo_")==0) return yasuoExecute104(kind,sourceSkill);\n'
     '         if(kind.indexOf("dragon_kaisa_")==0) return kaisaExecute104(kind,sourceSkill);')
once('         kaisaEvent104(event,source,target);',
     '         yasuoEvent104(event,source,target,amount);\n         kaisaEvent104(event,source,target);')
reset = '         yasuoNightRounds104=-1;yasuoVampRounds104=-1;yasuoCritBonus104=0;yasuoShieldSerial104=0;yasuoCritBurst104=false;\n'
s = re.sub(r'^         yasuoNightRounds104=-1;[^\n]*\n', '', s, flags=re.M)
once('         summonStatSnapshot = false;\n         kaisaClearPlasma104();',
     '         summonStatSnapshot = false;\n' + reset + '         kaisaClearPlasma104();')
once('         abilityEntryAttack = ap;\n         ready();',
     '         abilityEntryAttack = ap;\n         yasuoStart104();\n         ready();')
once('         return _loc2_ + (initializingFightAttributes ? 0 : teamTalentFlat("team_crit"));',
     '         return _loc2_ + yasuoCritBonus104 + (initializingFightAttributes ? 0 : teamTalentFlat("team_crit"));')
once('         if(abilityState.channel && ["stun","silence","root","pull","push"].indexOf(param1)>=0) return;',
     '         if(yasuoImmune104(param1)) return;\n'
     '         if(abilityState.channel && ["stun","silence","root","pull","push"].indexOf(param1)>=0) return;')
once('         if(!param1 || (param2 != "poison"',
     '         if(yasuoImmune104(param2)) return;\n         if(!param1 || (param2 != "poison"')
s = re.sub(r'^         if\(yasuo(?:Night|Vamp)Rounds104[^\n]*\n', '', s, flags=re.M)
once('         tickManualLethalFloors();',
     '         if(yasuoNightRounds104>=0 && --yasuoNightRounds104<0) yasuoQueueNight104(false);\n'
     '         if(yasuoVampRounds104>=0) --yasuoVampRounds104;\n         tickManualLethalFloors();')
once('      protected function removeBuff(param1:String, consume:Boolean = false) : void\n      {',
     '      protected function removeBuff(param1:String, consume:Boolean = false, clearShields:Boolean = true) : void\n      {\n'
     '         if(param1=="shield" && clearShields) removeIndependentShields104();')
# Replacement by a stronger allied shield and ordinary expiry must not dispel
# independent shields. Explicit shield dispels continue to clear all pools.
a = s.index('      public function addBuff(')
b = s.index('      public function resetBuff()', a)
s = s[:a] + s[a:b].replace('removeBuff(param1);', 'removeBuff(param1,false,false);') + s[b:]
once('               removeBuff(_loc3_);', '               removeBuff(_loc3_,false,false);')
once('      protected function removeAllGoodBuff() : void\n      {',
     '      protected function removeAllGoodBuff() : void\n      {\n         removeIndependentShields104();')
once('         keys.sort();\n         for each(key in keys)',
     '         if(target.shieldValue104()>0 && keys.indexOf("shield")<0) keys.push("shield");\n'
     '         keys.sort();\n         for each(key in keys)')
once('            if(key == "shield") stolen = Number(target.buffs[key].value);',
     '            if(key == "shield") stolen = target.shieldValue104();')
once('         var modShieldBefore:Number = buffs && buffs["shield"] ? Number(buffs["shield"].value) : 0;',
     '         var modShieldBefore:Number = shieldValue104();')
if '            param1 = int(yasuoDamage104(' not in s:
    once('            param1 = int(skin2Incoming(param1,param7 || param5,param4));\n            _loc9_ = buffs["shield"] as Buff;\n            if(_loc9_)',
         '            param1 = int(skin2Incoming(param1,param7 || param5,param4));\n'
         '            param1 = int(yasuoDamage104(param1,param7 || param5));\n'
         '            _loc9_ = buffs["shield"] as Buff;\n            if(shieldValue104()>0)')
once('         var modShieldBroke:Boolean = modShieldBefore > 0 && (!buffs["shield"] || Number(buffs["shield"].value) <= 0);',
     '         var modShieldBroke:Boolean = modShieldBefore > 0 && shieldValue104()<=0;')
once('dotKind:String = "") : int\n      {\n         var abilityHpBefore:int = hp;',
     'dotKind:String = "", derivedDamage104:Boolean = false) : int\n      {\n'
     '         var settledCriticalDamage104:Number=0;\n         var abilityHpBefore:int = hp;')
once('            param1 = Tools.toInt(Tools.toInt(param1 * param2) * _loc24_[21]);',
     '            if(!derivedDamage104) param1 = Tools.toInt(Tools.toInt(param1 * param2) * _loc24_[21]);')
once('            param1 = Tools.toInt(param1 / _loc18_);',
     '            if(!derivedDamage104) param1 = Tools.toInt(param1 / _loc18_);')
once('            param1 = int(yasuoDamage104(param1,param7 || param5));',
     '            param1 = int(yasuoDamage104(param1,param7 || param5,derivedDamage104));\n'
     '            settledCriticalDamage104=Math.max(0,param1);')
once('               if(param2 > 1) param7.emitModEvent("crit",param7,this,modActualDamage);',
     '               if(param2 > 1)\n               {\n'
     '                  param7.emitModEvent("crit",param7,this,modActualDamage);\n'
     '                  param7.yasuoCritical104(this,settledCriticalDamage104);\n               }')
# The travelling projectile supplies the exact contact time. Reuse the native
# hit/crit/injury primitives without the generic per-target windup or bullets.
contact='''         if(_loc41_.nativeContact104===true)
         {
            for each(var contactTarget104:Avatar in param1)
            {
               if(!contactTarget104 || contactTarget104.hp<=0) continue;
               if(_loc42_ && checkMiss(this,contactTarget104,_loc25_)) continue;
               _loc46_=_loc42_ ? countDamage(this,contactTarget104,_loc14_,param2,param9) : [_loc14_,false];
               _loc20_=_loc42_ ? checkCrit(this,contactTarget104) : 1;
               _loc21_+=contactTarget104.injured(_loc46_[0],_loc20_,_loc25_,param2,this,_loc46_[1],this,param7);
            }
            return _loc21_;
         }
'''
once('         _loc25_.par = _loc30_.effectLayer;\n         GameMap.actionDelay += 0.3;',
     '         _loc25_.par = _loc30_.effectLayer;\n'+contact+'         GameMap.actionDelay += 0.3;')
a = s.index('      private function absorbShieldDamage(')
b = s.index('      public function injured(', a)
s = s[:a] + '''      private function absorbShieldDamage(amount:int, factor:Number) : int
      {
         if(amount<=0) return amount;
         if(!isFinite(factor) || factor<1) factor=1;
         var keys:Array=[];
         for(var key:String in buffs) if(buffs[key] && buffs[key].type=="shield") keys.push(key);
         // Consume the soonest-expiring pool first. Round only once after all
         // pools so splitting shields cannot lose damage to repeated rounding.
         var pools:Object=buffs;
         keys.sort(function(a:String,b:String):Number {return pools[a].round-pools[b].round || (a<b ? -1 : a>b ? 1 : 0);});
         var budget:Number=Tools.toInt(amount*factor);
         var spent:Number=0;
         for each(key in keys)
         {
            var shield:Buff=buffs[key] as Buff;
            var take:Number=Math.min(Math.max(0,shield.value),budget-spent);
            shield.value-=take;spent+=take;
            if(shield.value<=0) removeBuff(key,false,false);
            if(spent>=budget) break;
         }
         return Tools.toInt(Math.max(0,Number(amount)-spent/factor));
      }

''' + s[b:]
# The night multiplier belongs after every ordinary attack modifier, including
# flat evil stacks and Santa stacks. Keep it out of outgoing damage settlement.
a = s.index('      public function getDamage(')
b = s.index('      public function getDefenseAgainst(', a)
attack = s[a:b]
night_attack = 'if(this.yasuoNightRounds104>=0) _loc6_ = Tools.toInt(_loc6_*1.75);'
if night_attack not in attack:
    old = 'return Math.max(_loc6_,0);'
    if old not in attack:
        raise ValueError('Missing final attack return for Yasuo multiplier')
    attack = attack.replace(old, night_attack + '\n         ' + old, 1)
s = s[:a] + attack + s[b:]
p.write_bytes(s.encode('utf-8'))
manifest = ROOT / 'client/build.json'
cfg = json.loads(manifest.read_text('utf-8'))
for stage in cfg['stages']:
    if stage['source'] == 'client/src/stages/137_Avatar.as':
        stage['source_sha256'] = hashlib.sha256(p.read_bytes()).hexdigest()
manifest.write_text(json.dumps(cfg, ensure_ascii=False, indent=2) + '\n', 'utf-8')
print('Synchronized Nightbringer Yasuo and independent shield settlement')
