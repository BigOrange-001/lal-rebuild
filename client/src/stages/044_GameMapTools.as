package com.meng52.game.module.map
{
   import com.meng52.game.Game;
   import com.meng52.game.command.avatar.AvatarData;
   import com.meng52.game.command.avatar.AvatarManager;
   import com.meng52.game.command.map.GameMapData;
   import com.meng52.game.command.map.GameMapManager;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.guide.GuideData;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.ui.map.GameMapLayer;
   import com.meng52.net.RpcStaticCall;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.Tools;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import starling.display.Image;
   
   public class GameMapTools
   {
      
      public static const MORPH_SIGN:String = ".";
      
      public static const DIR_AMOUNT:int = 4;
      
      public static const DIR_RIGHT:int = 0;
      
      public static const DIR_DOWN:int = 1;
      
      public static const DIR_LEFT:int = 2;
      
      public static const DIR_UP:int = 3;
      
      public static const DIR:String = "dir";
      
      public static const POINT:String = "point";

      private static var originMismatchReported:Boolean = false;
      private static var originMismatchDetails:Array = [];
      private static const MAX_ORIGIN_MISMATCH_DETAILS:int = 10;
      
      public function GameMapTools()
      {
         super();
      }
      
      public static function getAvatarIDByRes(param1:String) : String
      {
         var _loc3_:AvatarData = null;
         var _loc2_:Object = null;
         var _loc4_:String = null;
         if(param1.indexOf("-") == 0)
         {
            param1 = param1.slice(1);
         }
         if(param1 == "user")
         {
            param1 = GlobalData.$userData.team[GlobalData.$tempTeamID][0];
            param1 = param1.split("|")[0];
         }
         else if(param1 == "a")
         {
            param1 = GuideData.monsterId;
         }
         else if(param1 == "sys")
         {
            _loc3_ = AvatarManager.getOnlyExample().getData(GlobalData.$mConfig_client["sys_aid"]);
            param1 = _loc3_.res;
         }
         else if(Tools.strIsNumber(param1))
         {
            _loc2_ = GlobalData.$userData.avatars;
            for(_loc4_ in _loc2_)
            {
               if(_loc4_.split("|")[1] == param1)
               {
                  return _loc4_.split("|")[0];
               }
            }
         }
         return param1;
      }
      
      public static function newAvatarImgById(param1:String, param2:int = 0, param3:int = 0) : Image
      {
         var _loc4_:AvatarData = AvatarManager.getOnlyExample().getData(param1);
         if(_loc4_)
         {
            return newAvatarImg(_loc4_.res,param2,param3);
         }
         return newAvatarImg(param1,param2,param3);
      }
      
      public static function newAvatarImg(param1:String, param2:int = 0, param3:int = 0) : Image
      {
         var _loc5_:Boolean = false;
         var _loc4_:Boolean = false;
         if(param1.indexOf("-") == 0)
         {
            param1 = param1.slice(1);
            _loc5_ = true;
         }
         if(param1.indexOf(".") > -1)
         {
            param1 = param1.slice(0,param1.length - 1);
            _loc4_ = true;
         }
         if(param1.indexOf("|") != -1)
         {
            param1 = param1.split("|")[0];
         }
         if(param1 == "user")
         {
            param1 = GlobalData.$userData.team[GlobalData.$tempTeamID][0];
         }
         var _loc6_:Image = GlobalFunction.getAvatarUI(param1);
         _loc6_.pivotX = _loc6_.width / 2;
         _loc6_.pivotY = _loc6_.height / 2;
         _loc6_.x = param2;
         _loc6_.y = param3;
         _loc6_.touchable = false;
         if(_loc5_)
         {
            _loc6_.scaleX = -1;
         }
         return _loc6_;
      }
      
      public static function gridToVector(param1:int = 0, param2:int = 0) : Point
      {
         return new Point(Math.atan2(param2,param1),new Point(param1,param2).length);
      }
      
      public static function vectorToGrid(param1:Number, param2:Number) : Point
      {
         return new Point(Math.cos(param1) * param2,Math.sin(param1) * param2);
      }
      
      public static function getZScale(param1:int = 0) : Number
      {
         return Math.max(1,Math.min(2,1 + param1 / 5000));
      }
      
      public static function checkStep(param1:Point, param2:Point, param3:Number) : *
      {
         var _loc5_:int = 0;
         var _loc4_:Point = null;
         var _loc6_:Object = {};
         if(Math.abs(param2.x) < Math.abs(param2.y))
         {
            if(Math.abs(param2.x) >= param3)
            {
               if(param2.x > 0)
               {
                  _loc4_ = new Point(param1.x + param3,param1.y);
                  _loc5_ = 0;
               }
               else
               {
                  _loc4_ = new Point(param1.x - param3,param1.y);
                  _loc5_ = 2;
               }
            }
            else if(param2.y > 0)
            {
               _loc4_ = new Point(param1.x + param2.x,param1.y + (param3 - Math.abs(param2.x)));
               _loc5_ = 1;
            }
            else
            {
               _loc4_ = new Point(param1.x + param2.x,param1.y - (param3 - Math.abs(param2.x)));
               _loc5_ = 3;
            }
         }
         else if(Math.abs(param2.y) >= param3)
         {
            if(param2.y > 0)
            {
               _loc4_ = new Point(param1.x,param1.y + param3);
               _loc5_ = 1;
            }
            else
            {
               _loc4_ = new Point(param1.x,param1.y - param3);
               _loc5_ = 3;
            }
         }
         else if(param2.x > 0)
         {
            _loc4_ = new Point(param1.x + (param3 - Math.abs(param2.y)),param1.y + param2.y);
            _loc5_ = 0;
         }
         else
         {
            _loc4_ = new Point(param1.x - (param3 - Math.abs(param2.y)),param1.y + param2.y);
            _loc5_ = 2;
         }
         _loc6_["dir"] = _loc5_;
         _loc6_["point"] = _loc4_;
         return _loc6_;
      }
      
      public static function toPercentage(param1:Number) : String
      {
         return Math.round(param1 * 100) + "%";
      }
      
      public static function toGridStr(param1:int) : String
      {
         return String(Math.round(param1 / 100) / 10);
      }
      
      public static function getPosID(param1:int, param2:int) : String
      {
         return param1 + "_" + param2;
      }
      
      public static function getIDPos(param1:String) : Point
      {
         var _loc2_:int = param1.indexOf("_");
         var _loc3_:Point = new Point();
         _loc3_.x = int(param1.slice(0,_loc2_));
         _loc3_.y = int(param1.slice(_loc2_ + 1,param1.length));
         return _loc3_;
      }
      
      public static function getRandomPos(param1:Point, param2:int) : Point
      {
         var _loc3_:Point = new Point(param1.x,param1.y);
         _loc3_.x = _loc3_.x + Math.random() * param2 * 2 - param2;
         _loc3_.y = _loc3_.y + Math.random() * param2 * 2 - param2;
         return _loc3_;
      }
      
      public static function getBetweenPosList(param1:Point, param2:Point) : Array
      {
         var _loc6_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:Point = null;
         var _loc5_:Array = [];
         if(param1.x == param2.x)
         {
            _loc3_ = param1.y - param2.y;
            if(Math.abs(_loc3_) <= 1)
            {
               return _loc5_;
            }
            _loc6_ = _loc3_ > 0 ? 1 : -1;
            while(param1.y != param2.y + _loc6_)
            {
               _loc4_ = new Point(param2.x,param2.y + _loc6_);
               _loc6_ += _loc3_ > 0 ? 1 : -1;
               if(_loc4_.y != param2.y)
               {
                  _loc5_.unshift(_loc4_);
               }
            }
         }
         else
         {
            if(param1.y != param2.y)
            {
               return null;
            }
            _loc3_ = param1.x - param2.x;
            if(Math.abs(_loc3_) <= 1)
            {
               return _loc5_;
            }
            _loc6_ = _loc3_ > 0 ? 1 : -1;
            while(param1.x != param2.x + _loc6_)
            {
               _loc4_ = new Point(param2.x + _loc6_,param2.y);
               _loc6_ += _loc3_ > 0 ? 1 : -1;
               if(_loc4_.x != param2.x)
               {
                  _loc5_.unshift(_loc4_);
               }
            }
         }
         return _loc5_;
      }
      
      public static function getCrossPosList(param1:Point, param2:int) : Array
      {
         var _loc4_:int = 0;
         var _loc3_:Array = [param1];
         _loc4_ = param1.x - param2;
         while(_loc4_ <= param1.x + param2)
         {
            if(_loc4_ != param1.x)
            {
               _loc3_.push(new Point(_loc4_,param1.y));
            }
            _loc4_++;
         }
         _loc4_ = param1.y - param2;
         while(_loc4_ <= param1.y + param2)
         {
            if(_loc4_ != param1.y)
            {
               _loc3_.push(new Point(param1.x,_loc4_));
            }
            _loc4_++;
         }
         return _loc3_;
      }
      
      public static function getSquarePosList(param1:Point, param2:int) : Array
      {
         var _loc5_:int = 0;
         var _loc4_:int = 0;
         var _loc3_:Array = [];
         _loc5_ = param1.x - param2;
         while(_loc5_ <= param1.x + param2)
         {
            _loc4_ = param1.y - param2;
            while(_loc4_ <= param1.y + param2)
            {
               _loc3_.push(new Point(_loc5_,_loc4_));
               _loc4_++;
            }
            _loc5_++;
         }
         return _loc3_;
      }
      
      public static function getDiamondPosList(param1:Point, param2:int) : Array
      {
         var _loc5_:int = 0;
         var _loc4_:int = 0;
         var _loc3_:Array = [];
         _loc5_ = param1.x - param2;
         while(_loc5_ <= param1.x + param2)
         {
            _loc4_ = param1.y - param2;
            while(_loc4_ <= param1.y + param2)
            {
               if(Math.abs(_loc5_ - param1.x) + Math.abs(_loc4_ - param1.y) <= param2)
               {
                  _loc3_.push(new Point(_loc5_,_loc4_));
               }
               _loc4_++;
            }
            _loc5_++;
         }
         return _loc3_;
      }
      
      public static function getCirclePosList(param1:Point, param2:int) : Array
      {
         var _loc6_:int = 0;
         var _loc5_:int = 0;
         var _loc4_:Point = null;
         var _loc3_:Array = [];
         _loc6_ = param1.x - param2;
         while(_loc6_ <= param1.x + param2)
         {
            _loc5_ = param1.y - param2;
            while(_loc5_ <= param1.y + param2)
            {
               _loc4_ = new Point(_loc6_ - param1.x,_loc5_ - param1.y);
               if(_loc4_.length <= param2)
               {
                  _loc3_.push(new Point(_loc6_,_loc5_));
               }
               _loc5_++;
            }
            _loc6_++;
         }
         return _loc3_;
      }
      
      public static function getRingPosList(param1:Point, param2:int, param3:int) : Array
      {
         var _loc7_:int = 0;
         var _loc6_:int = 0;
         var _loc5_:Point = null;
         var _loc4_:Array = [];
         _loc7_ = param1.x - param3;
         while(_loc7_ <= param1.x + param3)
         {
            _loc6_ = param1.y - param3;
            while(_loc6_ <= param1.y + param3)
            {
               _loc5_ = new Point(_loc7_ - param1.x,_loc6_ - param1.y);
               if(_loc5_.length >= param2 && _loc5_.length <= param3)
               {
                  _loc4_.push(new Point(_loc7_,_loc6_));
               }
               _loc6_++;
            }
            _loc7_++;
         }
         return _loc4_;
      }
      
      public static function getIntersectionPosList(param1:Array, param2:Array) : Array
      {
         var _loc6_:int = 0;
         var _loc5_:int = 0;
         var _loc4_:* = null;
         var _loc3_:Array = [];
         _loc6_ = 0;
         while(_loc6_ <= param1.length)
         {
            _loc5_ = 0;
            while(_loc5_ <= param2.length)
            {
               if(param1[_loc6_].x == param2[_loc5_].x && param1[_loc6_].y == param2[_loc5_].y)
               {
                  _loc3_.push(new Point(param1[_loc6_].x,param1[_loc6_].y));
               }
               _loc5_++;
            }
            _loc6_++;
         }
         return _loc3_;
      }
      
      public static function getDistance(param1:Point, param2:Point) : int
      {
         return new Point(param1.x - param2.x,param1.y - param2.y).length;
      }
      
      public static function getRadians(param1:Point, param2:Point) : Number
      {
         var _loc3_:Point = null;
         _loc3_ = new Point(param2.x - param1.x,param2.y - param1.y);
         return (Math.atan2(_loc3_.y,_loc3_.x) + 3.141592653589793 * 2) % (3.141592653589793 * 2);
      }
      
      public static function getHitTime(param1:Number, param2:Number, param3:Number, param4:Number, param5:Rectangle) : Object
      {
         var _loc8_:Number = NaN;
         var _loc6_:Number = NaN;
         var _loc7_:int = 0;
         var _loc9_:Object = {};
         if(param3 < 0)
         {
            _loc8_ = Math.max((param5.x - param1) / param3,0);
         }
         else
         {
            _loc8_ = Math.max((param5.x + param5.width - param1) / param3,0);
         }
         if(param4 < 0)
         {
            _loc6_ = Math.max((param5.y - param2) / param4,0);
         }
         else
         {
            _loc6_ = Math.max((param5.y + param5.height - param2) / param4,0);
         }
         if(_loc8_ < _loc6_)
         {
            _loc9_.side = 1;
            _loc9_.time = _loc8_;
            _loc9_.pos = new Point(param1 + param3 * _loc9_.time,param2 + param4 * _loc9_.time);
            return _loc9_;
         }
         _loc9_.side = 2;
         _loc9_.time = _loc6_;
         _loc9_.pos = new Point(param1 + param3 * _loc9_.time,param2 + param4 * _loc9_.time);
         return _loc9_;
      }
      
      public static function gameTrace(... rest) : void
      {
         if(MainConfig.$isWindows)
         {
            trace.apply(null,rest);
         }
      }
      
      public static function sendGetCombatErrlog() : void
      {
         SendServiceAMFFun.send_user_get_combat_errlog(reSendGetCombatErrlog,{});
      }
      
      public static function reSendGetCombatErrlog(param1:*) : void
      {
         var _loc2_:Game = null;
         var _loc4_:* = undefined;
         var _loc5_:String = null;
         var _loc3_:GameMap = null;
         if(param1)
         {
            Avatar.index = 1;
            if(GameMap.currentMap)
            {
               GameMap.currentMap.clear();
            }
            _loc2_ = GlobalData.$mGameClassObject;
            GuideMaster.getOnlyExample().skipGuide();
            _loc2_.removeChildren(1,-1);
            _loc2_.addChild(GameMapLayer.gl.mapStage);
            _loc4_ = param1.data;
            _loc5_ = _loc4_.cid;
            if(_loc5_.indexOf("U") != -1 || _loc5_.indexOf("V") != -1)
            {
               _loc5_ = "pvp";
            }
            else if(_loc5_.indexOf("F_") != -1)
            {
               _loc5_ = "fragment";
            }
            else if(_loc5_.indexOf("E") == 0)
            {
               _loc5_ = "extreme";
            }
            else if(_loc5_.indexOf("B") == 0)
            {
               _loc5_ = "exploration";
            }
            else if(_loc5_.indexOf("C") == 0)
            {
               _loc5_ = "battle_of_the_peak";
            }
            _loc3_ = new GameMap(_loc5_,_loc4_.diff);
            GameMapLayer.canFpsLv = GameMapLayer.FPS_LIST.length - 1;
            _loc3_.re = param1;
            _loc3_.randomSeed = _loc4_.seed;
            _loc3_.initByOrgin(param1);
            _loc3_.isGetErrlog = true;
            _loc3_.checkOrginTeam();
            _loc3_.readyFight();
         }
      }
      
      public static function compareData(param1:Object, param2:Object, param3:String = "") : Boolean
      {
         var _loc5_:* = undefined;
         var _loc4_:Boolean = true;
         var mismatchPath:String;
         // Avatar.toDataObj legitimately includes null-valued skill/talent fields.
         // AS3 for..in on that value throws Error #1009, so compare nulls before recursion.
         if(param1 == null || param2 == null)
         {
            if(param1 == null && param2 == null)
            {
               return true;
            }
            mismatchPath = param3 == "" ? "value" : param3;
            rememberOriginMismatch(mismatchPath,param1,param2);
            gameTrace(mismatchPath + " null mismatch");
            return false;
         }
         if(param1 is Array || param2 is Array)
         {
            if(!(param1 is Array) || !(param2 is Array))
            {
               mismatchPath = param3 == "" ? "type" : param3 + ".type";
               rememberOriginMismatch(mismatchPath,param1,param2);
               return false;
            }
            if((param1 as Array).length != (param2 as Array).length)
            {
               mismatchPath = (param3 == "" ? "value" : param3) + ".length";
               rememberOriginMismatch(mismatchPath,(param1 as Array).length,(param2 as Array).length);
               return false;
            }
         }
         for(_loc5_ in param1)
         {
            if(param1[_loc5_] is int || param1[_loc5_] is Number || param1[_loc5_] is String || param1[_loc5_] is Boolean)
            {
               if(!(param1[_loc5_] == 0 && param2[_loc5_] == null))
               {
                  if(param1[_loc5_] != param2[_loc5_])
                  {
                     mismatchPath = param3 == "" ? _loc5_ : param3 + "." + _loc5_;
                     rememberOriginMismatch(mismatchPath,param1[_loc5_],param2[_loc5_]);
                     gameTrace(mismatchPath + " " + param1[_loc5_] + " != " + param2[_loc5_]);
                     _loc4_ = false;
                  }
               }
            }
            else
            {
               // Keep walking sibling fields after a mismatch so one report
               // can identify several related serialization differences.
               if(!compareData(param1[_loc5_],param2[_loc5_],param3 == "" ? _loc5_ : param3 + "." + _loc5_))
               {
                  _loc4_ = false;
               }
            }
         }
         return _loc4_;
      }

      private static function rememberOriginMismatch(path:String, clientValue:Object, serverValue:Object) : void
      {
         var i:int = 0;
         if(!originMismatchDetails)
         {
            originMismatchDetails = [];
         }
         while(i < originMismatchDetails.length)
         {
            if(originMismatchDetails[i].field == path)
            {
               return;
            }
            i++;
         }
         if(originMismatchDetails.length >= MAX_ORIGIN_MISMATCH_DETAILS)
         {
            return;
         }
         originMismatchDetails.push({"field":path,"client":safeOriginValue(path,clientValue),"server":safeOriginValue(path,serverValue)});
      }

      private static function safeOriginValue(path:String, value:Object) : String
      {
         var text:String;
         if(value == null)
         {
            return "null";
         }
         if(value is Array)
         {
            return "Array(" + (value as Array).length + ")";
         }
         if(value is String)
         {
            text = String(value);
            if(path.indexOf("aid") >= 0 || path.indexOf("uid") >= 0 || path.indexOf("name") >= 0)
            {
               return "<text len=" + text.length + ">";
            }
            if(text.length > 32)
            {
               text = text.substr(0,16) + "..." + text.substr(text.length - 8);
            }
            return "\"" + text + "\"";
         }
         if(value is int || value is Number || value is Boolean)
         {
            return String(value);
         }
         return "Object";
      }

      public static function beginOriginCheck() : void
      {
         originMismatchReported = false;
         originMismatchDetails = [];
      }

      public static function reportOriginMismatch(mapId:String) : void
      {
         if(originMismatchReported || !originMismatchDetails || originMismatchDetails.length == 0 || RpcStaticCall.$remoting == null)
         {
            return;
         }
         originMismatchReported = true;
         var details:String = "";
         var i:int = 0;
         while(i < originMismatchDetails.length)
         {
            if(details != "")
            {
               details += " | ";
            }
            details += originMismatchDetails[i].field + " client=" + originMismatchDetails[i].client + " server=" + originMismatchDetails[i].server;
            i++;
         }
         RpcStaticCall.$remoting.reportDiagnostic("COMBAT_ORIGIN_MISMATCH map=" + mapId + " count=" + originMismatchDetails.length + " details=" + details);
      }
      
      public static function initAvatarDiff(param1:Avatar, param2:int = 0) : void
      {
         var _loc3_:Array = GameMapData.getDiffConfig(param2);
         param1.hp = param1.hpMax = param1.hpMax * _loc3_[0];
         param1.ap *= _loc3_[0];
         param1.dePh *= _loc3_[0];
         param1.deMa *= _loc3_[0];
         param1.hit *= _loc3_[1];
         param1.flee *= _loc3_[1];
         param1.crit *= _loc3_[1];
         param1.tough *= _loc3_[1];
      }
      
      public static function getWinStr(param1:*, param2:Boolean = false) : String
      {
         var _loc3_:GameMapData = null;
         var _loc5_:int = 0;
         var _loc4_:String = "";
         if(param1 is GameMapData)
         {
            _loc3_ = param1 as GameMapData;
         }
         else
         {
            _loc3_ = GameMapManager.getOnlyExample().getData(param1);
         }
         if(_loc3_)
         {
            if(_loc3_.win[0] == -2)
            {
               _loc4_ = GlobalLanguageStr.getLanguageStr(30043);
            }
            else if(_loc3_.win[0] == -3)
            {
               _loc4_ = GlobalLanguageStr.getLanguageStr(30045);
            }
            else
            {
               if(_loc3_.line == 1)
               {
                  _loc4_ = GlobalLanguageStr.getLanguageStr(30030);
               }
               else if(_loc3_.line == 2)
               {
                  if(_loc3_.win.length >= 2)
                  {
                     _loc4_ = GlobalLanguageStr.getLanguageStr(30030);
                  }
                  else if(_loc3_.win[0] == -1)
                  {
                     _loc4_ = GlobalLanguageStr.getLanguageStr(30030);
                  }
                  else if(_loc3_.win[0] == 0)
                  {
                     _loc4_ = GlobalLanguageStr.getLanguageStr(30031) + GlobalLanguageStr.getLanguageStr(30034);
                  }
                  else if(_loc3_.win[0] == 1)
                  {
                     _loc4_ = GlobalLanguageStr.getLanguageStr(30033) + GlobalLanguageStr.getLanguageStr(30034);
                  }
               }
               else if(_loc3_.line == 3)
               {
                  if(_loc3_.win.length >= 3)
                  {
                     _loc4_ = GlobalLanguageStr.getLanguageStr(30030);
                  }
                  else if(_loc3_.win[0] == -1)
                  {
                     _loc4_ = GlobalLanguageStr.getLanguageStr(30035);
                  }
                  else
                  {
                     _loc5_ = 0;
                     while(_loc5_ < 3)
                     {
                        if(_loc3_.win[_loc5_] == 0)
                        {
                           _loc4_ += GlobalLanguageStr.getLanguageStr(30031);
                        }
                        else if(_loc3_.win[_loc5_] == 1)
                        {
                           _loc4_ += GlobalLanguageStr.getLanguageStr(30032);
                        }
                        else if(_loc3_.win[_loc5_] == 2)
                        {
                           _loc4_ += GlobalLanguageStr.getLanguageStr(30033);
                        }
                        if(_loc3_.win.length > _loc5_ + 1)
                        {
                           _loc4_ += GlobalLanguageStr.getLanguageStr(30036);
                        }
                        _loc5_++;
                     }
                     _loc4_ += GlobalLanguageStr.getLanguageStr(30034);
                  }
               }
               _loc4_ += GlobalLanguageStr.getLanguageStr(30040);
            }
         }
         if(param2)
         {
            _loc4_ = GlobalLanguageStr.getLanguageStr(30042,_loc3_.line) + _loc4_;
         }
         return _loc4_;
      }
   }
}

