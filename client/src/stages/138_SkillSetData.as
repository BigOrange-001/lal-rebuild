package com.meng52.game.command.skill
{
   import com.meng52.game.command.BaseData;

   public class SkillSetData extends BaseData
   {

      public static const PROPERTY_LIST:String = "pl";

      public static const TYPE_DAMAGE:String = "damage";

      public static const TYPE_COMBO:String = "combo";

      public static const TYPE_SUCK:String = "suck";

      public static const TYPE_STUN:String = "stun";

      public static const TYPE_SILENCE:String = "silence";

      public static const TYPE_WEAK:String = "weak";

      public static const TYPE_SUNDER:String = "sunder";

      public static const TYPE_POISON:String = "poison";

      public static const TYPE_BURN:String = "burn";

      public static const TYPE_PULL:String = "pull";

      public static const TYPE_PUSH:String = "push";

      public static const TYPE_SUMMON:String = "summon";

      public static const TYPE_SHIELD:String = "shield";

      public static const TYPE_CURE:String = "cure";

      public static const TYPE_STRONG:String = "strong";

      public static const TYPE_PURIFY:String = "purify";

      public static const TYPE_ATTRUP:String = "attrup";

      public static const TYPE_DASH:String = "dash";

      public static const TYPE_RELINE:String = "reline";

      public static const TYPE_GANK:String = "gank";

      public static const TYPE_TAUNT:String = "taunt";

      public static const TYPE_BLESS:String = "bless";

      public static const TYPE_STEEL:String = "steel";

      public static const TYPE_EVIL:String = "evil";

      public static const TYPE_AE:String = "ae";

      public static const TYPE_EQUIPUP:String = "equipup";

      public static const TYPE_BACK:String = "back";

      public static const TYPE_AVENGE:String = "avenge";

      public static const KIND_HP:String = "hp";

      public static const KIND_AP:String = "ap";

      public static const KIND_DE_PH:String = "de_ph";

      public static const KIND_DE_MA:String = "de_ma";

      public static const KIND_HIT:String = "hit";

      public static const KIND_FLEE:String = "flee";

      public static const KIND_CRIT:String = "crit";

      public static const KIND_TOUGH:String = "tough";

      public static const SKILLS:String = "skill";

      public static const SKILL_UP:String = "skillUp";

      public var pl:Array;

      public var warmup:int;

      public var cooldown:int;

      public var range:int;

      public var hpType:Number;

      public var aoe:int;

      public var banStand:Boolean;

      public var skills:Array;

      public var skillUp:Array;
      public var skillUpPaths:Array;

      public var targetPolicy:String;
      public var modNativeSource:String;
      public var actionTargetPolicies:Array;
      public var actionTargetLocks:Array;
      public var actionTargetGroups:Array;
      public var actionTargetMaxTargets:Array;
      public var actionTargetPolicyArgs:Array;
      public var damageShareGroups:Array;
      public var recastNormalOnceOnKill:Boolean;
      public var manualSummonPolicy:Object;
      public var manualClonePolicy:Object;
      public var chainDot:Array;

      public function SkillSetData(param1:*)
      {
         super(param1);
         pl = param1["pl"];
         if(pl)
         {
            warmup = pl[0];
            cooldown = pl[1];
            range = pl[2];
            hpType = pl[3];
            aoe = pl[4];
            banStand = pl[5] == 0;
         }
         skills = param1["skill"];
         skillUp = param1["skillUp"];
         skillUpPaths = param1["skillUpPaths"] as Array;
         targetPolicy = param1["targetPolicy"];
         modNativeSource = param1["modNativeSource"];
         actionTargetPolicies = param1["actionTargetPolicies"] as Array;
         actionTargetLocks = param1["actionTargetLocks"] as Array;
         actionTargetGroups = param1["actionTargetGroups"] as Array;
         actionTargetMaxTargets = param1["actionTargetMaxTargets"] as Array;
         actionTargetPolicyArgs = param1["actionTargetPolicyArgs"] as Array;
         damageShareGroups = param1["damageShareGroups"] as Array;
         recastNormalOnceOnKill = param1["recastNormalOnceOnKill"] === true;
         manualSummonPolicy = param1["manualSummonPolicy"] as Object;
         manualClonePolicy = param1["manualClonePolicy"] as Object;
         chainDot = param1["chainDot"] as Array;
      }
   }
}
