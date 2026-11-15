"""Integrate the Abyss relic equipment passives into the native client battle.

Inserts client/src/abyss_equip_passives_104.aspart into Avatar (between
BEGIN/END markers) and applies the narrow hooks below. Every hook is guarded by
data that only relic snapshots carry, so battles without relics are unchanged.
Idempotent; run scripts/sync_abyss_client_104.py afterwards to refresh pins.
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AVATAR = ROOT / 'client/src/stages/137_Avatar.as'
GAMEMAP = ROOT / 'client/src/stages/175_GameMap.as'
PART = ROOT / 'client/src/abyss_equip_passives_104.aspart'
BEGIN = '      // BEGIN ABYSS_PASSIVES_104\n'
END = '      // END ABYSS_PASSIVES_104\n'


def once(text, before, after):
    if after in text:
        return text
    if text.count(before) != 1:
        raise ValueError('Integration anchor must occur once: ' + before[:120])
    return text.replace(before, after, 1)


def methods(text):
    block = BEGIN + PART.read_text('utf-8-sig').replace('\r\n', '\n').rstrip() + '\n' + END
    if BEGIN in text:
        a = text.index(BEGIN)
        b = text.index(END, a) + len(END)
        text = text[:a] + text[b:]
    at = text.index('\n   }\n}', text.index('public class Avatar'))
    return text[:at].rstrip() + '\n\n' + block + text[at:]


def avatar(s):
    # One Kai'Sa volley still has separate missile settlements, but is one cast
    # for relic status application (including misses and repeat targets).
    s = once(s, 'var seen:Array=[];\n         for(var shot:Number=0;',
             'var seen:Array=[];\n         var abyssVolleyHits104:Array=[];\n         for(var shot:Number=0;')
    before = '''            context.manualDamageMultiplier=sourceSkill.getNativeSetting("manualDamageMultiplier",1);
            try
            {
               var hit:Boolean=abilityHit(target,coefficient/globalRate,2,"FX_KAISA_MISSILE104");'''
    s = once(s, before, before.replace('            try\n',
             '            context.abyssHits104=abyssVolleyHits104;\n            try\n',1))
    # Targeted purges must clear relic layers even if no ordinary Buff exists.
    s = once(s, '''      protected function removeBuff(param1:String, consume:Boolean = false, clearShields:Boolean = true) : void
      {
''', '''      protected function removeBuff(param1:String, consume:Boolean = false, clearShields:Boolean = true) : void
      {
         abyssRemoveDots104(param1);
''')
    # Preserve the source small-skill and shared hit set for delayed effects.
    for prefix in ('abilityState.zone={line:', 'abilityState.channel={pos:',
                   'target.abilityState["bomb_"+abilityIndex]={owner:'):
        s = once(s, prefix, prefix.replace('={', '={abyssRelicContext104:abyssCaptureContext104(this),'))
    for name, owner, state in (('context', 'owner', 'bomb'),
                               ('zoneContext', 'this', 'state'),
                               ('channelContext', 'this', 'state')):
        anchor = f'var {name}:Object = beginAbilityAttack({owner},"active");\n'
        # "context" occurs elsewhere; its multiplier line identifies the bomb.
        tail = f'         {name}.manualDamageMultiplier = {state}.manualDamageMultiplier;'
        before = anchor + tail if name == 'context' else anchor
        after = anchor + f'         abyssRestoreContext104({name},{state}.abyssRelicContext104);\n'
        if name == 'context': after += tail
        s = once(s, before, after)
    # Migrate earlier integration hooks before reapplying the current anchors.
    s = s.replace('         if(abyssOrigin104 != "relic_reflect") param1 = int(param1 * abilityDirectMultiplier(param7,param4));',
        '         param1 = int(param1 * abilityDirectMultiplier(param7,param4));')
    s = s.replace('''            if(abyssOrigin104 != "relic_reflect")
            {
               param1 = int(skin2Incoming(param1,param7 || param5,param4));
               param1 = int(yasuoDamage104(param1,param7 || param5,derivedDamage104));
            }''', '''            param1 = int(skin2Incoming(param1,param7 || param5,param4));
            param1 = int(yasuoDamage104(param1,param7 || param5,derivedDamage104));''')
    s = s.replace('         if(param1 == "shield" && source) param3 = source.abyssAmplifyHeal104(param3);\n','')
    # Snapshot fields (battle units only; owned/display avatars carry none).
    s = once(s, '''         limitBreak = 0;
         cultureSchema = "";
''', '''         limitBreak = 0;
         cultureSchema = "";
         loadAbyssPassives104(param1 != null && !(param1 is Array) && param1.hp_max ? param1 : null);
''')
    # Heals: 圣佑 before book healing / burn reduction.
    s = once(s, '''            var bookHealer:Avatar = param7 || param5 || this;
            param1 = Tools.toInt(param1 * (1 + bookHealer.getBookCombatBonus("healing")));''', '''            var bookHealer:Avatar = param7 || param5 || this;
            param1 = int(bookHealer.abyssAmplifyHeal104(param1));
            param1 = Tools.toInt(param1 * (1 + bookHealer.getBookCombatBonus("healing")));''')
    # Relic reflect is absolute true damage: no native talent multiplier either.
    s = once(s, '''            trace("最终伤害算减伤之前" + param1);
            switch(param4 - 1)''', '''            trace("最终伤害算减伤之前" + param1);
            if(abyssOrigin104 != "relic_reflect") switch(param4 - 1)''')
    # Equipment modifiers after the existing ones, before shields.
    s = once(s, '''            param1 = int(yasuoDamage104(param1,param7 || param5,derivedDamage104));
            settledCriticalDamage104=Math.max(0,param1);''', '''            param1 = int(yasuoDamage104(param1,param7 || param5,derivedDamage104));
            param1 = abyssModifyDamage104(param1,param7,param4,dotKind);
            settledCriticalDamage104=Math.max(0,param1);''')
    s = once(s, '''               var bookShieldFactor:Number = 1 + (param7 ? param7.getBookCombatBonus("shield_damage") : 0);''',
             '''               var bookShieldFactor:Number = (1 + (param7 ? param7.getBookCombatBonus("shield_damage") : 0)) * (param7 ? param7.abyssShieldMultiplier104() : 1);''')
    s = once(s, '''               param1 = absorbShieldDamage(param1,bookShieldFactor);
               statisticsShield104 = Math.max(0,statisticsBeforeShield104-param1);''', '''               param1 = absorbShieldDamage(param1,bookShieldFactor);
               statisticsShield104 = Math.max(0,statisticsBeforeShield104-param1);
               abyssShieldSpent104 = Math.max(0,modShieldBefore - shieldValue104());''')
    s = once(s, '''         var statisticsShield104:Number = 0;
         param1 = int(param1 * abilityDirectMultiplier(param7,param4));''', '''         var statisticsShield104:Number = 0;
         var abyssShieldSpent104:Number = 0;
         var abyssRevivedNow104:Boolean = false;
         param1 = int(param1 * abilityDirectMultiplier(param7,param4));''')
    # Lethal protection order: bless, Tryndamere, then 复苏之羽.
    s = once(s, '''            GameMapTools.gameTrace(id + "触发限时一次免死，保留1生命");
            _loc19_.delayCall(refreshHp,GameMap.actionDelay,hp,false,shieldValue104(),hpMax);
         }
''', '''            GameMapTools.gameTrace(id + "触发限时一次免死，保留1生命");
            _loc19_.delayCall(refreshHp,GameMap.actionDelay,hp,false,shieldValue104(),hpMax);
         }
         if(hp <= 0 && abilityHpBefore > 0 && param4 != 4 && abyssTryRevive104())
         {
            abyssRevivedNow104 = true;
            _loc19_.delayCall(refreshHp,GameMap.actionDelay,hp,false,shieldValue104(),hpMax);
         }
''')
    # Loss is fixed before 坚守 restores HP; a relic revive counts the whole HP lost.
    s = once(s, '''         var modActualDamage:Number = param4 == 4 ? 0 : Math.max(0,abilityHpBefore-Math.max(0,hp));''',
             '''         var modActualDamage:Number = param4 == 4 ? 0 : (abyssRevivedNow104 ? Math.max(0,abilityHpBefore) : Math.max(0,abilityHpBefore-Math.max(0,hp)));
         if(abilityHpBefore > 0 && param4 != 0 && param4 != 4 && param4 != 5) abyssAfterDamage104(param7,modActualDamage,abyssShieldSpent104,param4,dotKind);''')
    # Lifesteal healing never triggers Nurse Akali's healing-received passive.
    s = once(s, '''         if(param4 == 4 && nurseHealAmount > 0) queueNurseHealing(''',
             '''         if(param4 == 4 && nurseHealAmount > 0 && abyssOrigin104 != "relic_lifesteal") queueNurseHealing(''')
    # Shields cast by a 圣佑 wearer.
    s = once(s, '''         if(param3 != 0 && param1 != "summon") param3 *= manualEffect;
         if(param1 == "shield" && source) param3 *= source.getRecoveryTalentMultiplier();''', '''         if(param3 != 0 && param1 != "summon") param3 *= manualEffect;
         if(param1 == "shield" && source) param3 *= source.getRecoveryTalentMultiplier();
         if(param1 == "shield" && source) param3 = source.abyssAmplifyHeal104(param3);''')
    # 疾风步 listens to the native dodge event.
    s = once(s, '''            param2.emitModEvent("dodge",param1,param2);''', '''            param2.emitModEvent("dodge",param1,param2);
            param2.abyssOnDodge104();''')
    # Purify / revive clear relic DOT layers with the other debuffs.
    s = once(s, '''         clearManualSkillDots();
      }

      protected function removeBuff(''', '''         clearManualSkillDots();
         abyssDots104 = null;
      }

      protected function removeBuff(''')
    # Relic DOTs keep poison vulnerability / burn heal-reduction semantics.
    s = once(s, '''         if(param1 == "burn" && buffs && buffs["burn"]) return true;
''', '''         if(param1 == "burn" && buffs && buffs["burn"]) return true;
         if(hasAbyssDot104(param1)) return true;
''')
    s = once(s, '''         if(yasuoNightRounds104>=0 && --yasuoNightRounds104<0) yasuoQueueNight104(false);''', '''         if(abyssDots104 && abyssDots104.length)
         {
            abyssTickDots104();
            if(hp <= 0)
            {
               hp = 0;
               return true;
            }
         }
         if(yasuoNightRounds104>=0 && --yasuoNightRounds104<0) yasuoQueueNight104(false);''')
    # 真理之刃: split before defense, sharing the hit and crit rolls.
    s = s if 'var abyssTrue104:Number' in s else once(s, '''         if(param4 == 1)
         {
            _loc7_ = defenseDamage104(_loc7_,param2.getDefenseAgainst(param1,1),param1.ap);
         }''', '''         var abyssTrue104:Number = (param4 == 1 || param4 == 2) ? param1.abyssConversion104() : 0;
         if(abyssTrue104 > 0)
         {
            var abyssTrueRaw104:Number = _loc7_ * abyssTrue104;
            _loc7_ = defenseDamage104(_loc7_ - abyssTrueRaw104,param2.getDefenseAgainst(param1,param4),param1.ap) + Tools.toInt(abyssTrueRaw104 * REAL_DAMAGE_RATE);
         }
         else if(param4 == 1)
         {
            _loc7_ = defenseDamage104(_loc7_,param2.getDefenseAgainst(param1,1),param1.ap);
         }''')
    # 召唤契约 and the inherited 坚城 reduction.
    s = once(s, '''         var panel:Object = owner.getSummonPanelSnapshot();
         statisticsOwner104 = owner;''', '''         var panel:Object = owner.abyssSummonPanel104(owner.getSummonPanelSnapshot());
         abyssReduction104 = owner.abyssReduction104;
         statisticsOwner104 = owner;''')
    s = s.replace('            var abyssTrueRaw104:Number = _loc7_ * abyssTrue104;\n            _loc7_ = defenseDamage104(_loc7_ - abyssTrueRaw104,param2.getDefenseAgainst(param1,param4),param1.ap) + Tools.toInt(abyssTrueRaw104 * REAL_DAMAGE_RATE);',
        '''            // Split raw damage before each branch's element and rounding stages.
            var abyssPhysicalRaw104:Number = Tools.toInt(param3 * (1 - abyssTrue104) * _loc6_[1]);
            var abyssTrueRaw104:Number = Tools.toInt(param3 * abyssTrue104 * _loc6_[1]);
            _loc7_ = Tools.toInt(Tools.toInt(defenseDamage104(abyssPhysicalRaw104,param2.getDefenseAgainst(param1,param4),param1.ap)) * param5) + Tools.toInt(Tools.toInt(abyssTrueRaw104 * REAL_DAMAGE_RATE) * param5);
            param5 = 1;''')
    s = s.replace('         param1 = int(param1 * abilityDirectMultiplier(param7,param4));',
        '         if(abyssOrigin104 != "relic_reflect") param1 = int(param1 * abilityDirectMultiplier(param7,param4));')
    s = s.replace('            param1 = int(skin2Incoming(param1,param7 || param5,param4));\n            param1 = int(yasuoDamage104(param1,param7 || param5,derivedDamage104));',
        '''            if(abyssOrigin104 != "relic_reflect")
            {
               param1 = int(skin2Incoming(param1,param7 || param5,param4));
               param1 = int(yasuoDamage104(param1,param7 || param5,derivedDamage104));
            }''')
    return methods(s)


def gamemap(s):
    s = once(s, '''      public function beginFight() : void
      {
''', '''      public function beginFight() : void
      {
         if(!abyssPassivesReady104)
         {
            abyssPassivesReady104 = true;
            Avatar.abyssInitialize104(team1List,team2List);
         }
''')
    s = once(s, '''         roundTeam = firstTeam;
         roundNum = 0;''', '''         roundTeam = firstTeam;
         abyssPassivesReady104 = false;
         roundNum = 0;''')
    s = once(s, '''      public var roundNum:int;''', '''      public var roundNum:int;

      // Abyss relic passives initialize once per fight (reset by startFight).
      public var abyssPassivesReady104:Boolean = false;''')
    return s


def rewrite(path, fn):
    raw = path.read_bytes()
    crlf = b'\r\n' in raw
    text = fn(raw.decode('utf-8').replace('\r\n', '\n'))
    path.write_bytes((text.replace('\n', '\r\n') if crlf else text).encode('utf-8'))


if __name__ == '__main__':
    rewrite(AVATAR, avatar)
    rewrite(GAMEMAP, gamemap)
