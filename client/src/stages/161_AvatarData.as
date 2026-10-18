package com.meng52.game.command.avatar
{
   import com.meng52.game.command.BaseDisplayData;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.module.avatar.Avatar;

   public class AvatarData extends BaseDisplayData
   {

      public static const TYPE_LIST:String = "tl";

      public static const PROPERTY_LIST:String = "pl";

      public static const SKILL:String = "skillup";

      public static const LOVE:String = "love";

      public static const SIGN_ATTACK:int = 1;

      public static const SIGN_TANK:int = 2;

      public static const SIGN_ASSIST:int = 3;

      public static const ACTION_FORWARD:int = 1;

      public static const ACTION_SLY:int = 2;

      public static const ACTION_STAND:int = 3;

      public static const ACTION_CUNNING:int = 4;

      public static const DAMAGE_DEBUFF:int = 0;

      public static const DAMAGE_PHYSICAL:int = 1;

      public static const DAMAGE_MAGIC:int = 2;

      public static const DAMAGE_REAL:int = 3;

      public static const DAMAGE_CURE:int = 4;

      public static const DAMAGE_BUFF:int = 5;

      public static const DAMAGE_POISON:int = 6;

      public static const DAMAGE_BURN:int = 7;

      public static const DAMAGE_DEAD:int = 8;

      public var signType:int;

      public var actionType:int;

      public var damageType:int;

      public var leadership:int;

      public var lvMax:int;

      public var expRate:Number;

      public var offerExp:int;

      public var offerGold:int;

      public var starUp:Array;

      public var sortIndex:int;

      public var hp0:Number;

      public var hp1:Number;

      public var ap0:Number;

      public var ap1:Number;

      public var d10:Number;

      public var d11:Number;

      public var d20:Number;

      public var d21:Number;

      public var speed:int;

      public var range:int;

      public var skill0:String;

      public var skill1:String;

      public var skillB:String;

      public var effectSet:String;

      public var skillUpP:Number;

      public var skillExp:Number;

      public var loveExp:Number;

      public var skill_diff:uint;

      public function AvatarData(param1:*)
      {
         super(param1);
         var _loc3_:Array = param1["tl"];
         var _loc2_:Array = param1["pl"];
         signType = _loc3_[0];
         actionType = _loc3_[1];
         damageType = _loc3_[2];
         leadership = _loc3_[3];
         lvMax = _loc3_[4];
         expRate = _loc3_[5];
         offerExp = _loc3_[6];
         offerGold = _loc3_[7];
         starUp = _loc3_[8];
         sortIndex = _loc3_[9];
         skillUpP = _loc3_[10] ? _loc3_[10] : 1;
         skillExp = param1["skillup"] ? param1["skillup"] : 0;
         loveExp = param1["love"] ? param1["love"] : 0;
         if(param1.skill_diff)
         {
            skill_diff = param1.skill_diff;
         }
         hp0 = _loc2_[0];
         hp1 = _loc2_[1];
         ap0 = _loc2_[2];
         ap1 = _loc2_[3];
         d10 = _loc2_[4];
         d11 = _loc2_[5];
         d20 = _loc2_[6];
         d21 = _loc2_[7];
         speed = _loc2_[8];
         range = _loc2_[9];
         skill0 = _loc2_[10];
         skill1 = _loc2_[11];
         if(_loc2_[13])
         {
            skillB = _loc2_[13];
         }
         effectSet = _loc2_[12];
      }

      public static function isAttack(param1:int) : Boolean
      {
         return param1 != 4 && param1 != 5;
      }

      public static function canMiss(param1:int) : Boolean
      {
         return param1 != 4 && param1 != 5 && param1 != 0;
      }

      public static function damageRate(param1:int, param2:int) : Number
      {
         if(param1 % 3 == param2 - 1)
         {
            return Avatar.SIGN_DAMAGE_RATE;
         }
         return 1;
      }

      public function get soundId() : String
      {
         var row:Object = GlobalData.$mConfig_avatar == null ? null : GlobalData.$mConfig_avatar[id];
         if(row != null && row.hasOwnProperty("modVoice")) return row.modVoice == null ? "" : String(row.modVoice);
         var base:String = GlobalData.baseModHeroId(id);
         return base.slice(0,base.length - 2);
      }

      public function get phaseUpList() : Array
      {
         var _loc4_:* = null;
         var _loc2_:Object = null;
         if(lvMax == 1)
         {
            return null;
         }
         var _loc1_:int = getType();
         var _loc5_:Array = GlobalData.$mConfig_simple.phase_config;
         var _loc3_:int = getStar();
         if(_loc1_ == 1)
         {
            _loc2_ = _loc5_[0];
         }
         else
         {
            _loc2_ = _loc5_[1];
         }
         return _loc2_[String(_loc3_)];
      }

      public function getStar() : int
      {
         return id.split("_")[2];
      }

      public function getType() : int
      {
         return int(id.slice(2,3));
      }

      public function getMaxStar() : int
      {
         var _loc2_:String = null;
         var _loc4_:AvatarData = null;
         var _loc3_:Array = id.split("_");
         var _loc1_:int = int(_loc3_[2]);
         while(_loc1_ < 10)
         {
            _loc2_ = _loc3_[0] + "_" + _loc3_[1] + "_" + _loc1_;
            _loc4_ = AvatarManager.getOnlyExample().getData(_loc2_);
            if(!(_loc4_ && _loc4_.canStarUp()))
            {
               break;
            }
            _loc1_++;
         }
         return _loc1_;
      }

      public function canStarUp() : Boolean
      {
         if(starUp.length > 0 && !GlobalFunction.isNullNextStarCfgId(id))
         {
            return true;
         }
         return false;
      }
   }
}
