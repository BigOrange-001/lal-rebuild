"""Attach Demonblade Tryndamere and the shared rage strip to the AIR Avatar."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
p = ROOT / 'client/src/stages/137_Avatar.as'
s = p.read_text('utf-8')
start = '      // BEGIN DEMONBLADE TRYNDAMERE 105\n'
end = '      // END DEMONBLADE TRYNDAMERE 105\n'
if start in s:
    rest = s[s.index(end) + len(end):]
    # Drop the separator written after the block so reruns do not accumulate blank lines.
    s = s[:s.index(start)] + (rest[1:] if rest.startswith(chr(10)) else rest)
anchor = '      public function abilityCanCast('
code = (ROOT / 'client/src/demonblade_tryndamere.aspart').read_text('utf-8')
s = s.replace(anchor, start + code + '\n' + end + '\n' + anchor, 1)


def once(old, new):
    global s
    if new in s:
        return
    if s.count(old) != 1:
        raise ValueError('Missing or ambiguous Demonblade hook: ' + old[:110])
    s = s.replace(old, new, 1)


# Skill dispatch.
once('         if(kind.indexOf("night_yasuo_")==0) return yasuoCanCast104(kind);',
     '         if(kind.indexOf("demon_trynd_")==0) return demonCanCast105(kind);\n'
     '         if(kind.indexOf("night_yasuo_")==0) return yasuoCanCast104(kind);')
once('         if(kind.indexOf("night_yasuo_")==0) return yasuoExecute104(kind,sourceSkill);',
     '         if(kind.indexOf("demon_trynd_")==0) return demonExecute105(kind,sourceSkill);\n'
     '         if(kind.indexOf("night_yasuo_")==0) return yasuoExecute104(kind,sourceSkill);')
# Events, battle entry and the start of each own action.
once('         yasuoEvent104(event,source,target,amount);\n         kaisaEvent104(event,source,target);',
     '         yasuoEvent104(event,source,target,amount);\n         demonEvent105(event,source,target);\n'
     '         kaisaEvent104(event,source,target);')
once('         abilityEntryAttack = ap;\n         yasuoStart104();\n',
     '         abilityEntryAttack = ap;\n         yasuoStart104();\n         demonStart105();\n')
once('         if(yasuoNightRounds104>=0 && --yasuoNightRounds104<0) yasuoQueueNight104(false);',
     '         demonTurn105();\n'
     '         if(yasuoNightRounds104>=0 && --yasuoNightRounds104<0) yasuoQueueNight104(false);')
# Crit chance from rage, added to the opposed-formula result.
once('            if(rengar) chance=Math.min(100,chance*Number(rengar[4]));\n         }\n',
     '            if(rengar) chance=Math.min(100,chance*Number(rengar[4]));\n         }\n'
     '         chance=Math.min(100,chance+param1.demonCritBonus105());\n')
# Curse immunity during Endless Rage.
once('         if(yasuoImmune104(param1)) return;\n         if(s2AnnieImmune() && Buff.LIST_DEBUFF',
     '         if(yasuoImmune104(param1)) return;\n         if(demonImmune105(param1)) return;\n'
     '         if(s2AnnieImmune() && Buff.LIST_DEBUFF')
# Attack from missing health and Endless Rage, after every other modifier.
once('         if(this.yasuoNightRounds104>=0) _loc6_ = Tools.toInt(_loc6_*1.75);\n',
     '         if(this.yasuoNightRounds104>=0) _loc6_ = Tools.toInt(_loc6_*1.75);\n'
     '         _loc6_ = demonAttack105(_loc6_);\n')
# Endless Rage settles before bless and the older lethal guards.
once('         skin2Lethal();\n         if(hp <= 0 && buffs["bless"])',
     '         demonLethal105();\n         skin2Lethal();\n         if(hp <= 0 && buffs["bless"])')
# Rage from direct enemy damage, next to Shyvana's.
once('            if(direct)\n            {\n               sixNextRage105();\n',
     '            if(direct)\n            {\n               sixNextRage105();\n               demonHurtTaken105();\n')
# Basic attack ratio and the forced crit after Demon Slash.
once('         if(basicPassive105 && basicPassive105[1]=="six_caitlyn_p") param3 *= Number(basicPassive105[4]);\n',
     '         if(basicPassive105 && basicPassive105[1]=="six_caitlyn_p") param3 *= Number(basicPassive105[4]);\n'
     '         if(param2 == -1 && demonPassive105()) param3 *= Number(demonPassive105()[4]);\n')
once('            basicContext = beginAbilityAttack(this,"basic");\n            if(param2==-1)\n            {\n',
     '            basicContext = beginAbilityAttack(this,"basic");\n            if(param2==-1)\n            {\n'
     '               if(demonTakeForceCrit105()) basicContext.sixForceCrit105=true;\n')
# Shyvana's rage strip.
once('         abilityState.nextRage=int(abilityState.nextRage)+5;\n',
     '         abilityState.nextRage=int(abilityState.nextRage)+5;\n         queueRageBar105();\n')
once('         queueVitalBar104();\n         abilityFeedback("巨龙真身"',
     '         queueVitalBar104();\n         queueRageBar105();\n         abilityFeedback("巨龙真身"')
# Show the strip as soon as the HP bar exists.
once('            refreshVitalBar104(hp,hpMax,shieldValue104());\n            mBloodSpr.y',
     '            refreshVitalBar104(hp,hpMax,shieldValue104());\n            queueRageBar105();\n            mBloodSpr.y')
p.write_text(s, encoding='utf-8', newline='')

manifest = ROOT / 'client/build.json'
cfg = json.loads(manifest.read_text('utf-8'))
for stage in cfg['stages']:
    if stage['source'] in ('client/src/stages/137_Avatar.as', 'client/src/stages/178_ProgressBar.as'):
        stage['source_sha256'] = hashlib.sha256((ROOT / stage['source']).read_bytes()).hexdigest()
manifest.write_text(json.dumps(cfg, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('Synchronized Demonblade Tryndamere and rage strip')
