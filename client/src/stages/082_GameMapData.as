package com.meng52.game.command.map
{
   import com.meng52.game.command.BaseDisplayData;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.map.GameMapTools;
   import com.meng52.utils.Tools;
   
   public class GameMapData extends BaseDisplayData
   {
      
      public static const LINE:String = "line";
      
      public static const TEAM_1_LIST:String = "team1";
      
      public static const TEAM_2_LIST:String = "team2";
      
      public static const USER_POWER:String = "ulv";
      
      public static const WIN:String = "win";
      
      public static const ENERGY:String = "energy";
      
      public static const EXP:String = "exp";
      
      public static const GOLD:String = "gold";
      
      public static const LIMIT:String = "limit";
      
      public static const PRE_STORY:String = "pre";
      
      public static const NEW_4ATTRS:String = "new_4attrs";
      
      public static const EQUIP_DROP:String = "equip_drop";
      
      public var line:int;
      
      public var team1List:Array;
      
      public var team2List:Array;
      
      public var bgList:Array;
      
      public var userPower:int;
      
      public var win:Array;
      
      public var energy:int;
      
      public var exp:int;
      
      public var gold:int;
      
      public var limit:Array;
      
      public var preStory:Array;
      
      public var new4attrs:Array;
      
      public var equipDrop:Array;
      public var enemyUnitStatsByDiff:Object;
      public var team2ByDiff:Object;
      public var recommendedPowerByDiff:Object;
      
      public function GameMapData(param1:*)
      {
         super(param1);
         line = param1["line"][0];
         bgList = param1["line"][1];
         team1List = param1["team1"];
         team2List = param1["team2"];
         // ulv remains the account-level unlock gate. Use the separate recommendation for the PVE preview when supplied.
         userPower = int(param1["recommended_power"] != null ? param1["recommended_power"] : param1["ulv"]);
         win = param1["win"];
         energy = param1["energy"];
         exp = param1["exp"];
         gold = param1["gold"];
         limit = param1["limit"] is Array ? param1["limit"] : [param1["limit"]];
         preStory = param1["pre"];
         new4attrs = param1["new_4attrs"];
         equipDrop = param1["equip_drop"];
         enemyUnitStatsByDiff = param1["enemy_unit_stats_by_diff"];
         team2ByDiff = param1["team2_by_diff"];
         recommendedPowerByDiff = param1["recommended_power_by_diff"];
      }

      public function getTeam2List(param1:int = 0) : Array
      {
         var _loc2_:Array = null;
         if(team2ByDiff)
         {
            _loc2_ = team2ByDiff[String(param1)] as Array;
         }
         return _loc2_ ? _loc2_ : team2List;
      }
      
      public static function getDiffConfig(param1:int = 0) : Array
      {
         return GlobalData.$mConfig_simple.combat_diff[param1];
      }
      
      public static function getBattleId(param1:String) : String
      {
         var _loc2_:Array = param1.split("_");
         return _loc2_[0] + "_" + _loc2_[1];
      }
      
      public function getUserPower(param1:int = 0) : int
      {
         var _loc4_:int = 0;
         var _loc9_:Array = null;
         var _loc8_:int = 0;
         var _loc2_:Avatar = null;
         var _loc3_:Number = NaN;
         var _loc10_:Array = null;
         if(recommendedPowerByDiff && recommendedPowerByDiff[String(param1)] != null)
         {
            return Tools.toEffectiveInt(int(recommendedPowerByDiff[String(param1)]),2);
         }
         if(param1 == 0)
         {
            return Tools.toEffectiveInt(userPower,2);
         }
         var _loc7_:Number = 0;
         var _loc5_:Number = 0;
         _loc4_ = int(team2List.length);
         _loc8_ = 0;
         while(_loc8_ < _loc4_)
         {
            _loc9_ = team2List[_loc8_];
            if(_loc9_ != null)
            {
               _loc2_ = new Avatar(_loc9_[0],_loc9_.slice(0,11));
               _loc7_ += getAvatarPower(_loc2_,0,getEnemyStatOverride(_loc8_,0,String(_loc9_[0])));
               _loc2_.clear();
            }
            _loc8_++;
         }
         _loc3_ = userPower / _loc7_;
         _loc10_ = getTeam2List(param1);
         _loc4_ = int(_loc10_.length);
         _loc8_ = 0;
         while(_loc8_ < _loc4_)
         {
            _loc9_ = _loc10_[_loc8_];
            if(_loc9_ != null)
            {
               _loc2_ = new Avatar(_loc9_[0],_loc9_.slice(0,11));
               _loc5_ += getAvatarPower(_loc2_,param1,getEnemyStatOverride(_loc8_,param1,String(_loc9_[0])));
               _loc2_.clear();
            }
            _loc8_++;
         }
         return Tools.toInt(_loc5_ * _loc3_);
      }
      
      public function getAvatarPower(param1:Avatar, param2:int, param3:Object = null) : Number
      {
         var _loc3_:Number = NaN;
         param1.initFightAttr();
         initAvatarNew4attrs(param1);
         GameMapTools.initAvatarDiff(param1,param2);
         GameMapTools.applyEnemyStatOverride(param1,param3);
         _loc3_ = param1.getPower(param1.isLeader);
         return Number(Math.floor(_loc3_).toString(10));
      }
      
      public function getEnemyStatOverride(param1:int, param2:int, param3:String) : Object
      {
         var _loc4_:Array = null;
         var _loc5_:Object = null;
         if(!enemyUnitStatsByDiff)
         {
            return null;
         }
         _loc4_ = enemyUnitStatsByDiff[String(param2)] as Array;
         if(!_loc4_ || param1 < 0 || param1 >= _loc4_.length)
         {
            return null;
         }
         _loc5_ = _loc4_[param1];
         if(_loc5_ == null)
         {
            return null;
         }
         if(int(_loc5_.index) != param1 || String(_loc5_.aid) != param3)
         {
            throw new Error("Mainline enemy stat override does not match team2 order");
         }
         return _loc5_;
      }
      
      public function initAvatarNew4attrs(param1:Avatar) : void
      {
         if(new4attrs)
         {
            param1.hit = new4attrs[0];
            param1.flee = new4attrs[1];
            param1.crit = new4attrs[2];
            param1.tough = new4attrs[3];
         }
      }
      
      public function getExp(param1:int = 0) : int
      {
         var _loc2_:Array = getDiffConfig(param1);
         return int(_loc2_[2] * exp);
      }
      
      public function getGold(param1:int = 0) : int
      {
         var _loc2_:Array = getDiffConfig(param1);
         return int(_loc2_[3] * gold);
      }
      
      public function getEnergy(param1:int = 0) : int
      {
         var _loc2_:Array = getDiffConfig(param1);
         return int(_loc2_[4] * energy);
      }
      
      public function getLimit(param1:int = 0) : int
      {
         return limit[param1];
      }
      
      public function get isMain() : Boolean
      {
         var _loc2_:String = id;
         var _loc1_:Array = _loc2_.split("_");
         if(_loc1_[0] == GlobalFunction.MAIN)
         {
            return true;
         }
         return false;
      }
      
      public function get isW() : Boolean
      {
         var _loc2_:String = id;
         var _loc1_:Array = _loc2_.split("_");
         if(_loc1_[0] == "W" || _loc1_[0] == "w")
         {
            return true;
         }
         return false;
      }
      
      public function get battleId() : String
      {
         var _loc1_:Array = id.split("_");
         return _loc1_[0] + "_" + _loc1_[1];
      }
      
      public function get selfId() : String
      {
         var _loc1_:Array = id.split("_");
         return _loc1_[2];
      }
      
      public function get battleName() : String
      {
         var _loc1_:String = battleId;
         var _loc2_:* = GlobalData.$config_battle_main[_loc1_];
         if(_loc2_)
         {
            return _loc2_.name;
         }
         _loc2_ = GlobalData.$mConfig_battle_ploy[_loc1_];
         if(_loc2_)
         {
            return _loc2_.name;
         }
         return null;
      }
      
      public function get bossId() : String
      {
         var _loc1_:int = 0;
         _loc1_ = 0;
         while(_loc1_ < team2List.length)
         {
            if(team2List[_loc1_][5] == 1)
            {
               return team2List[_loc1_][0];
            }
            _loc1_++;
         }
         return team2List[0][0];
      }
      
      public function get isFinnal() : Boolean
      {
         var _loc1_:String = battleId;
         var _loc2_:* = GlobalData.$config_battle_main[_loc1_];
         if(_loc2_)
         {
            return _loc2_.combat == selfId;
         }
         return false;
      }
      
      public function get dropId() : String
      {
         var _loc2_:int = 0;
         var _loc1_:String = null;
         _loc2_ = 0;
         while(_loc2_ < team2List.length)
         {
            _loc1_ = team2List[_loc2_][0];
            if(_loc1_.charAt(2) == "6")
            {
               return _loc1_;
            }
            _loc2_++;
         }
         return "";
      }
      
      public function get story() : Array
      {
         var _loc1_:String = battleId;
         if(!GlobalData.$config_battle_main[_loc1_])
         {
            return null;
         }
         return GlobalData.$config_battle_main[_loc1_].story;
      }
   }
}

