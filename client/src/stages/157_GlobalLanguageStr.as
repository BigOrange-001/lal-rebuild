package com.meng52.game.global
{
   import com.meng52.utils.Tools;

   public class GlobalLanguageStr
   {

      private static const ID:String = "id";

      private static const re:String = "@";

      public static var $_global_language_str:XML = null;

      public function GlobalLanguageStr()
      {
         super();
      }

      public static function getStr(param1:*, param2:String = "", ... rest) : String
      {
         var _loc5_:Array = [param1].concat(rest);
         var _loc4_:String = getLanguageStr.apply(null,_loc5_);
         if(_loc4_ == "")
         {
            _loc4_ = param2;
         }
         return _loc4_;
      }

      public static function getLanguageStr(param1:*, ... rest) : String
      {
         var _loc3_:Object = null;
         var _loc4_:String = getConfigLanguageStr(param1);
         if(_loc4_ == null && $_global_language_str && param1 != null)
         {
            if($_global_language_str["id" + param1].@str == "CHILD2010")
            {
               _loc4_ = $_global_language_str["id" + param1].children().toString();
            }
            else
            {
               _loc4_ = $_global_language_str["id" + param1].@str;
            }
         }
         if(_loc4_ == null || _loc4_.length <= 0)
         {
            return "";
         }
         return replaceStrArr(_loc4_,rest);
      }

      private static function getConfigLanguageStr(id:*) : String
      {
         var messages:Object = GlobalData.$mConfig ? GlobalData.$mConfig.msg : null;
         if(id != null && messages && messages[id] is String) return messages[id];
         if(id != null && GlobalData.$mConfig_msg && GlobalData.$mConfig_msg[id] is String) return GlobalData.$mConfig_msg[id];
         return null;
      }

      public static function replaceStrArr(param1:String, param2:Array) : String
      {
         var _loc3_:String = null;
         var _loc5_:int = 0;
         var _loc4_:* = undefined;
         _loc5_ = 0;
         while(_loc5_ < param2.length)
         {
            _loc3_ = "@" + _loc5_;
            _loc4_ = param2[_loc5_];
            if(_loc4_ is String || _loc4_ is int || _loc4_ is Number)
            {
               param1 = Tools.replaceString(param1,_loc3_,_loc4_);
            }
            else
            {
               param1 = replaceStrObj(param1,_loc4_);
            }
            _loc5_++;
         }
         return param1;
      }

      public static function replaceStrObj(param1:String, param2:*) : String
      {
         var _loc4_:* = undefined;
         var _loc3_:String = null;
         for(_loc4_ in param2)
         {
            _loc3_ = "@" + _loc4_;
            param1 = Tools.replaceString(param1,_loc3_,param2[_loc4_] is Date ? Tools.dateFormat(param2[_loc4_],-8,"YYYY-MM-DD") : param2[_loc4_]);
         }
         return param1;
      }
   }
}
