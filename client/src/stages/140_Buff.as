package com.meng52.game.module.skill
{
   import com.meng52.game.ui.effect.DisplayTools;
   import starling.display.DisplayObject;

   public class Buff
   {

      public static const BUFF_FPS:int = 10;

      public static const BUFF_STUN:String = "stun";

      public static const BUFF_SILENCE:String = "silence";

      public static const BUFF_WEAK:String = "weak";

      public static const BUFF_SUNDER:String = "sunder";

      public static const BUFF_POISON:String = "poison";

      public static const BUFF_BURN:String = "burn";

      public static const BUFF_EVIL:String = "evil";

      public static const BUFF_SUMMON:String = "summon";

      public static const BUFF_SHIELD:String = "shield";

      public static const BUFF_STRONG:String = "strong";

      public static const BUFF_TAUNT:String = "taunt";

      public static const BUFF_BLESS:String = "bless";

      public static const BUFF_STEEL:String = "steel";

      public static const BUFF_PURIFY:String = "purify";

      public static const BUFF_PULL:String = "pull";

      public static const BUFF_PUSH:String = "push";

      public static const BUFF_HITUP:String = "hitup";

      public static const BUFF_FLEEUP:String = "fleeup";

      public static const BUFF_CRITUP:String = "critup";

      public static const BUFF_TOUGHUP:String = "toughup";

      public static const BUFF_ASUCK:String = "asuck";

      public static const BUFF_BACK:String = "back";

      public static const BUFF_AVENGE:String = "avenge";

      public static const LIST_DEBUFF:Array = ["root","stun","silence","weak","sunder","poison","burn","evil"];

      public static const LIST_BUFF:Array = ["shield","strong","taunt","bless","steel","armor","hitup","fleeup","critup","toughup","purify"];

      public var type:String;

      public var round:int;

      public var value:Number;

      private var m_do:DisplayObject;

      public function Buff(param1:String, param2:int, param3:Number = 0)
      {
         super();
         type = param1;
         round = param2;
         value = param3;
      }

      public function get displayObject() : DisplayObject
      {
         var _loc1_:* = undefined;
         if(!m_do)
         {
            _loc1_ = DisplayTools.getAttrs(type);
            m_do = DisplayTools.newDisplayObject(_loc1_);
         }
         return m_do;
      }
   }
}
