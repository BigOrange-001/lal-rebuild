"""Connect the shared ratio model to AIR damage and the per-device fallback."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
avatar = ROOT/'client/src/stages/137_Avatar.as'
s = avatar.read_text('utf8')
begin = '      // BEGIN DAMAGE FORMULA 104\n'
end = '      // END DAMAGE FORMULA 104\n'
if begin in s:
    s = s[:s.index(begin)].rstrip('\n')+'\n\n'+s[s.index(end)+len(end):].lstrip('\n')
anchor = '      public static function countDamage('
s = s.replace(anchor,begin+(ROOT/'client/src/combat_rules_104.aspart').read_text('utf8')+end+'\n'+anchor,1)
if '   import com.meng52.utils.LocalStore;' not in s:
    s = s.replace('   import com.meng52.utils.Tools;', '   import com.meng52.utils.LocalStore;\n   import com.meng52.utils.Tools;',1)
s = s.replace('      public static var REAL_DAMAGE_RATE:Number = 0.3;',
              '      public static function get REAL_DAMAGE_RATE() : Number { return Number(damageAttack104()[1]); }')
rate_getter = '      public static function get REAL_DAMAGE_RATE() : Number { return Number(damageAttack104()[1]); }'
if 'public static function set REAL_DAMAGE_RATE(' not in s:
    s = s.replace(rate_getter, rate_getter + '\n      public static function set REAL_DAMAGE_RATE(value:Number) : void { configuredTrueDamageRate104 = value; }')
s = s.replace('Math.max(_loc7_ * MIN_DAMAGE_RATE,_loc7_ - param2.getDefenseAgainst(param1,1))',
              'defenseDamage104(_loc7_,param2.getDefenseAgainst(param1,1),param1.ap)')
s = s.replace('Math.max(_loc7_ * MIN_DAMAGE_RATE,_loc7_ - param2.getDefenseAgainst(param1,2))',
              'defenseDamage104(_loc7_,param2.getDefenseAgainst(param1,2),param1.ap)')
s = s.replace('GlobalData.$mConfig_simple.attack','damageAttack104()')
# The inserted helper must continue to read the unmodified base array.
s = s.replace('var attack:Array = damageAttack104().concat();','var attack:Array = GlobalData.$mConfig_simple.attack.concat();')
s = s.replace('coefficient /= REAL_DAMAGE_RATE;', 'coefficient = trueSkillCoefficient104(coefficient);')
s = s.replace('coefficient *= trueSkillCoefficient104();', 'coefficient = trueSkillCoefficient104(coefficient);')
s = s.replace('_loc6_[5] + 100 * (_loc5_ - _loc8_)',
              '_loc6_[5] + (ratioDamage104() ? damageRuleNumber104("crit_slope") : 100) * (_loc5_ - _loc8_)')
s = s.replace('_loc9_[4] + 100 * (_loc6_ - _loc7_)',
              '_loc9_[4] + (ratioDamage104() ? damageRuleNumber104("miss_slope") : 100) * (_loc6_ - _loc7_)')
avatar.write_text(s,encoding='utf8',newline='')

skill = ROOT/'client/src/stages/139_SkillSet.as'
t = skill.read_text('utf8')
t = t.replace('GlobalData.$mConfig_simple.attack','Avatar.damageAttack104()')
t = t.replace(' / Avatar.REAL_DAMAGE_RATE',' * Avatar.trueSkillCoefficient104()')
t = t.replace('/Avatar.REAL_DAMAGE_RATE','*Avatar.trueSkillCoefficient104()')
t = t.replace('coefficient /= Avatar.REAL_DAMAGE_RATE;', 'coefficient *= Avatar.trueSkillCoefficient104();')
t = t.replace('chainCoeff /= Avatar.REAL_DAMAGE_RATE;', 'chainCoeff *= Avatar.trueSkillCoefficient104();')
t = t.replace('coefficient *= Avatar.trueSkillCoefficient104();','coefficient = Avatar.trueSkillCoefficient104(coefficient);')
t = t.replace('chainCoeff *= Avatar.trueSkillCoefficient104();','chainCoeff = Avatar.trueSkillCoefficient104(chainCoeff);')
t = t.replace('(Number(step[5])+eventValue/Math.max(1,avatar.getDamage()))*Avatar.trueSkillCoefficient104()',
              'Avatar.trueSkillCoefficient104(Number(step[5])+eventValue/Math.max(1,avatar.getDamage()))')
t = t.replace('Number(_loc20_[1]) * Avatar.trueSkillCoefficient104()',
              'Avatar.trueSkillCoefficient104(Number(_loc20_[1]))')
t = t.replace('Number(_loc8_.coeff) * Avatar.trueSkillCoefficient104()',
              'Avatar.trueSkillCoefficient104(Number(_loc8_.coeff))')
skill.write_text(t,encoding='utf8',newline='')

game_map = ROOT/'client/src/stages/175_GameMap.as'
t = game_map.read_text('utf8')
if '         Avatar.beginDamageRules104();' not in t:
    t = t.replace('         currentMap = this;','         currentMap = this;\n         Avatar.beginDamageRules104();',1)
game_map.write_text(t,encoding='utf8',newline='')

manifest = ROOT/'client/build.json'
cfg = json.loads(manifest.read_text('utf8'))
for stage in cfg['stages']:
    if stage['source'] in {str(p.relative_to(ROOT)).replace('\\','/') for p in (avatar,skill,game_map,ROOT/'client/src/stages/151_PanelHelpSetting.as')}:
        stage['source_sha256'] = hashlib.sha256((ROOT/stage['source']).read_bytes()).hexdigest()
manifest.write_text(json.dumps(cfg,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print('Synchronized default ratio damage and legacy fallback')
