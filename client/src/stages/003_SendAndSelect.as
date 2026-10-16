package com.meng52.net
{
   import com.meng52.events.NetEvent;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.manager.DebugManager;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.guide.GuideData;
   import com.meng52.utils.Tools;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.events.TimerEvent;
   import flash.utils.Dictionary;
   import flash.utils.Timer;
   
   public class SendAndSelect extends EventDispatcher
   {
      
      public static const EVENT_SEND:String = "event_send";
      
      public static const EVENT_RE:String = "event_re";
      
      public static const NET_TIMEOUT:String = "net_timeout";
      
      public static const ACTIONID:String = "actionID";
      
      public static const ACTIONID_a:String = "a";
      
      public static const SEND_TIME:String = "sendTime";
      
      public static const RE_FUNCTION:String = "reFunction";
      
      public static const RECONNECTION:String = "reconnection";
      
      public static const SEND_METHOD:String = "sendMethod";
      
      public static const SESSIONID:String = "sessionid";
      
      public static const AVATARLOCK:String = "avatarLock";
      
      public static const UID:String = "uid";
      
      public static const PF:String = "pf";
      
      public static const SERVER_NOW:String = "server_now";
      
      public static const SERVER_NOW_TIMER:String = "$datetime";
      
      public static const DATA:String = "data";
      
      public static const RETURN_CODE:String = "return_code";
      
      public static const METHOD:String = "method";
      
      public static const PARAMS:String = "params";
      
      public static const RANDOM_NUM:Number = 1000000000;
      
      public static const GUIDE_SIGN:String = "guideSign";
      
      public static const ID_MAC:String = "mac_id";
      
      public static const ANA_INDEX:String = "ana_index/";
      
      public static const ANA_OPERATION:String = "operation/";
      
      public static var $systemTimer:Timer;
      
      public static var $MACID:String = "";
      
      public static var $IDFA:String = "";
      
      public static var $userCurrPF_uid:String = "";
      
      public static var $userCurrPF:String = "";
      
      public static var $userCurrPF_sessionid:String = "";
      
      public static var $uid:String = "";
      
      public static var $sessionid:String = "";
      
      public static var $serviceId:String = "";
      
      public static var $data_ana_url:String = "";
      
      public static var $data_ana_key:String = "";
      
      public static var $systemTimer_nowSecond:Number = 0;
      
      public static var $systemTimeDate:Date;
      
      public static var $sendNetEventObj:NetEvent;
      
      public static var $reNetEventObj:NetEvent;
      
      public static var $countServiceTime:Number = 0;
      
      public static var $countServiceTimeB:Boolean = false;
      
      public static var $appVersion:String = "";
      
      public static var $cfgVersion:String = "";
      
      public static var $serviceTimeOutNum:Number = 0;
      
      public static var $serviceTimeOut:Timer;
      
      public static var $serviceTimeCallFunBySec:Function;

      public static var $profileBootstrapActionID:String = "";
      
      public static var $serviceData:Dictionary = new Dictionary();
      
      public static var $SendServiceAMFDispatcher:EventDispatcher = new EventDispatcher();
      
      public function SendAndSelect()
      {
         super();
         throw new Error("无法实例化");
      }
      
      public static function getConnectNetRemoting() : RemotingConnect
      {
         return RpcStaticCall.$remoting;
      }
      
      public static function setConnectNet(param1:String, param2:String) : void
      {
         RpcStaticCall.connectNet(param1,param2);
      }
      
      public static function dispatchNET_ERROR() : void
      {
         RpcStaticCall.$remoting.dispatchEvent(new Event("NET_ERROR"));
      }
      
      public static function reSetServiceData() : void
      {
         for(var _loc1_:Object in $serviceData)
         {
            delete $serviceData[_loc1_];
         }
         $serviceData = null;
         $serviceData = new Dictionary();
      }
      
      public static function checkRepeat(param1:String, param2:String) : Boolean
      {
         var _loc3_:Dictionary = $serviceData;
         for(var _loc4_:Object in _loc3_)
         {
            if(_loc3_[_loc4_]["sendMethod"] == param1)
            {
               if(_loc4_ != param2)
               {
                  return true;
               }
            }
         }
         return false;
      }
      
      public static function sendAndSelectService(param1:String, param2:Object = null, param3:Function = null, param4:Function = null, param5:String = "") : void
      {
         var _loc7_:* = undefined;
         if(checkRepeat(param1,param5))
         {
            return;
         }
         var _loc8_:Object = param2 == null ? {} : param2;
         _loc8_["actionID"] = param5 == "" ? "a" + new Date().getTime().toString() + Math.floor(Math.random() * 1000000000).toString() : param5;
         if(param1 == "user.login")
         {
            $profileBootstrapActionID = String(_loc8_["actionID"]);
         }
         var _loc6_:Object = {};
         _loc6_["reFunction"] = param3;
         _loc6_["sendTime"] = new Date();
         _loc6_["sendMethod"] = param1;
         _loc6_["params"] = _loc8_;
         $serviceData[_loc8_["actionID"]] = _loc6_;
         if(param1 != "sys.get_config")
         {
            if(GlobalData.$isForceGuide && param1 != "user.do_guide")
            {
               _loc7_ = {};
               _loc7_["server_now"] = new Date();
               _loc7_["method"] = param1;
               _loc7_["data"] = GuideData.getReData(param1);
               _loc7_["return_code"] = 0;
               _loc7_["params"] = param2;
               if(Boolean(param3))
               {
                  param3(_loc7_);
               }
               delete $serviceData[_loc8_["actionID"]];
               return;
            }
         }
         if(param4 != null)
         {
         }
         RpcStaticCall.callService({
            "method":param1,
            "params":_loc8_,
            "uid":$uid,
            "sessionid":$sessionid,
            "app_version":$appVersion,
            "cfg_version":$cfgVersion
         },reCheckFun,reErrorCheckFun);
         Tools.toTrace("发送消息：" + param1);
         DebugManager.instance().debug("<font color=\"#00ff00\">Send >>> " + param1 + "  " + _loc8_["actionID"] + "</font>");
         if($sendNetEventObj)
         {
            $sendNetEventObj.data = null;
         }
         $sendNetEventObj = null;
         $sendNetEventObj = new NetEvent("event_send");
         $sendNetEventObj.data = {
            "method":param1,
            "nowLoading":(param2 ? (param2.nowLoading ? param2.nowLoading : null) : null)
         };
         $SendServiceAMFDispatcher.dispatchEvent($sendNetEventObj);
         if(SendServiceAMFFun.ignoreList.indexOf(param1) >= 0)
         {
            return;
         }
         clearTimeOut();
         $serviceTimeOutNum = 1;
         $serviceTimeOut = new Timer(1000);
         $serviceTimeOut.addEventListener("timer",onServiceTimeOut);
         $serviceTimeOut.start();
         GlobalData.$mEventDispatcher.dispatchEventWith("shuaxin");
      }
      
      public static function onServiceTimeOut(param1:TimerEvent) : void
      {
         $serviceTimeOutNum += 1;
         if($serviceTimeOutNum > 60)
         {
            clearTimeOut();
            $SendServiceAMFDispatcher.dispatchEvent(new NetEvent("net_timeout"));
         }
      }
      
      private static function clearTimeOut() : void
      {
         if($serviceTimeOut)
         {
            $serviceTimeOut.stop();
            if($serviceTimeOut.hasEventListener("timer"))
            {
               $serviceTimeOut.removeEventListener("timer",onServiceTimeOut);
            }
         }
         $serviceTimeOutNum = 0;
         $serviceTimeOut = null;
      }
      
      public static function reSend() : void
      {
         var _loc5_:* = undefined;
         var _loc4_:String = null;
         var _loc2_:String = "";
         var _loc3_:String = "";
         var _loc6_:Object = null;
         var _loc1_:Object = $serviceData;
         for(_loc5_ in _loc1_)
         {
            _loc3_ = _loc5_.toString();
            if(_loc3_ != _loc2_)
            {
               _loc2_ = _loc3_;
               _loc6_ = _loc1_[_loc3_];
               _loc4_ = _loc6_["sendMethod"];
               if(SendServiceAMFFun.ignoreList.indexOf(_loc4_) >= 0)
               {
                  Tools.toTrace(_loc4_ + "忽略重发2");
                  DebugManager.instance().debug("<font color=\"#ff0000\">Ignore >>> " + _loc4_ + "  " + _loc3_ + "</font>");
                  delete _loc1_[_loc3_];
               }
               else
               {
                  sendAndSelectService(_loc4_,_loc6_["params"],_loc6_["reFunction"],null,_loc3_);
               }
            }
         }
      }
      
      public static function sendDataStatistics(param1:Boolean = false) : void
      {
      }
      
      public static function formatDataAnalysis(param1:* = null, param2:Array = null, param3:String = null, param4:Vector.<Avatar> = null, param5:String = null) : Object
      {
         var _loc15_:String = null;
         var _loc14_:int = 0;
         var _loc13_:String = null;
         var _loc8_:int = 0;
         var _loc11_:Array = null;
         var _loc9_:Array = null;
         var _loc12_:String = null;
         var _loc6_:* = null;
         var _loc7_:Object = {};
         var _loc10_:String = "|";
         if(param1)
         {
            if(param1 is String)
            {
               _loc15_ = param1.split("|")[0] + "-1";
            }
            else
            {
               _loc15_ = "";
               _loc11_ = [];
               _loc9_ = [];
               for(_loc13_ in param1)
               {
                  _loc13_ = _loc13_.split("|")[0];
                  _loc8_ = _loc9_.indexOf(_loc13_);
                  if(_loc8_ == -1)
                  {
                     _loc11_.push([_loc13_,1]);
                     _loc9_.push(_loc13_);
                  }
                  else
                  {
                     _loc11_[_loc8_][1]++;
                  }
               }
               _loc14_ = 0;
               while(_loc14_ < _loc11_.length)
               {
                  _loc15_ += _loc11_[_loc14_][0] + "-" + _loc11_[_loc14_][1] + _loc10_;
                  _loc14_++;
               }
               _loc15_ = _loc15_.slice(0,-1);
            }
            if(_loc15_.length > 0)
            {
               _loc7_.aids = _loc15_;
            }
         }
         if(param2)
         {
            _loc15_ = param2[0] + _loc10_ + param2[1];
            _loc7_.lv = _loc15_;
         }
         if(param3)
         {
            _loc12_ = param3.charAt(0);
            if(param4)
            {
               if(_loc12_ == GlobalFunction.MAIN)
               {
                  _loc7_.cid = param3;
               }
               else
               {
                  _loc7_.pid = param3;
               }
            }
            else if(_loc12_ == GlobalFunction.MAIN)
            {
               _loc7_.lose_cid = param3;
            }
            else
            {
               _loc7_.lose_pid = param3;
            }
         }
         if(param4)
         {
            _loc15_ = "";
            _loc11_ = [];
            _loc9_ = [];
            for each(_loc6_ in param4)
            {
               if(!_loc6_.isNPC)
               {
                  _loc13_ = _loc6_.avatarData.id;
                  _loc8_ = _loc9_.indexOf(_loc13_);
                  if(_loc8_ == -1)
                  {
                     _loc11_.push([_loc13_,1]);
                     _loc9_.push(_loc13_);
                  }
                  else
                  {
                     _loc11_[_loc8_][1]++;
                  }
               }
            }
            _loc14_ = 0;
            while(_loc14_ < _loc11_.length)
            {
               _loc15_ += _loc11_[_loc14_][0] + "-" + _loc11_[_loc14_][1] + _loc10_;
               _loc14_++;
            }
            _loc15_ = _loc15_.slice(0,-1);
            if(_loc15_.length > 0)
            {
               _loc7_.team = _loc15_;
            }
         }
         if(param5)
         {
            if(param5 is String)
            {
               _loc15_ = param5.split("|")[0] + "-1";
            }
            if(_loc15_.length > 0)
            {
               _loc7_.star_up = _loc15_;
            }
         }
         return _loc7_;
      }
      
      public static function sendDataAnalysis(param1:* = null, param2:Array = null, param3:String = null, param4:Vector.<Avatar> = null, param5:String = null) : void
      {
      }
      
      private static function reCheckFun(param1:Object) : void
      {
         var _loc5_:NetEvent = null;
         var _receiptKind:int = -1;
         var _syncError:Object = null;
         if($serviceData == null)
         {
            return;
         }
         if(param1 == null)
         {
            return;
         }
         var _loc7_:String = String(param1["method"]);
         var _loc3_:String = param1["params"]["actionID"];
         if(MainConfig.$testReSend)
         {
            if(Math.random() > 0.5)
            {
               Tools.toTrace("模擬返回丟失：" + _loc7_ + " - " + $systemTimer_nowSecond);
               DebugManager.instance().debug("<font color=\"#ff0000\">Lost >>> " + _loc7_ + "  " + _loc3_ + "</font>");
               if(SendServiceAMFFun.ignoreList.indexOf(_loc7_) >= 0)
               {
                  Tools.toTrace(_loc7_ + "忽略重发1");
                  DebugManager.instance().debug("<font color=\"#ff0000\">Ignore >>> " + _loc7_ + "  " + _loc3_ + "</font>");
                  delete $serviceData[_loc3_];
               }
               else
               {
                  reSend();
               }
               return;
            }
         }
         Tools.toTrace("收到消息：" + _loc7_ + " - " + $systemTimer_nowSecond);
         DebugManager.instance().debug("<font color=\"#ffff00\">Return >>> " + _loc7_ + "  " + _loc3_ + "</font>");
         $systemTimeDate = param1["server_now"] as Date;
         var _loc8_:Date = new Date();
         _loc8_.setTime($systemTimeDate.time);
         var _loc4_:Date = new Date(_loc8_.fullYearUTC,_loc8_.monthUTC,_loc8_.dateUTC,_loc8_.hoursUTC,_loc8_.minutesUTC,_loc8_.secondsUTC,_loc8_.millisecondsUTC);
         var _loc2_:int = int(param1["return_code"]);
         _receiptKind = GlobalFunction.profileReceiptKind(param1);
         var _loc6_:Number = $systemTimeDate.time * 0.001;
         setSystem(_loc6_);
         try
         {
         if($serviceData[_loc3_] != null && $serviceData[_loc3_] != undefined && _loc2_ == 0 && (_loc7_ != "user.login" || _loc3_ == $profileBootstrapActionID))
         {
            if(_receiptKind < 0 || (_receiptKind == 0 && _loc7_.indexOf("user.") == 0 && !GlobalFunction.isProfileBootstrapMethod(_loc7_)))
            {
               // Malformed versioned envelopes and successful authenticated
               // user.* replies without the required snapshot are protocol
               // errors. Do not run callbacks that may write a partial profile.
               _loc5_ = new NetEvent("error_broadcast");
               _syncError = {
                  "method":"profile_state_sync",
                  "receipt_method":_loc7_,
                  "return_code":0,
                  "data":{"msg":"账号数据同步失败，请重新登录。"},
                  "profile_sync_error":true,
                  "profile_sync_error_message":"账号数据同步失败，请重新登录。",
                  "profile_sync_error_reason":(_receiptKind < 0 ? "malformed_state_sync" : "missing_state_sync"),
                  "profile_receipt":param1
               };
               _loc5_.data = _syncError;
               $SendServiceAMFDispatcher.dispatchEvent(_loc5_);
            }
            else
            {
               // Apply a newer authoritative snapshot before listeners or
               // the exactly-once operation receipt callback. A valid stale
               // snapshot is ignored by GlobalData, but remains a versioned
               // receipt and therefore must not use legacy profile writers.
               if(_receiptKind == 1 && !GlobalFunction.isProfileBootstrapMethod(_loc7_))
               {
                  GlobalFunction.applyProfileStateSync(param1["state_sync"]);
               }
               if($reNetEventObj)
               {
                  $reNetEventObj.data = null;
               }
               $reNetEventObj = null;
               $reNetEventObj = new NetEvent("event_re");
               $reNetEventObj.data = {
                  "holdLoading":(param1["params"] ? (param1["params"].holdLoading ? param1["params"].holdLoading : false) : false),
                  "method":_loc7_
               };
               $SendServiceAMFDispatcher.dispatchEvent($reNetEventObj);
               if($serviceData[_loc3_]["reFunction"] is Function)
               {
                  if($serviceData[_loc3_]["reFunction"] != null)
                  {
                     ($serviceData[_loc3_]["reFunction"] as Function).apply(null,[param1]);
                  }
               }
            }
         }
         else if(_loc2_ != 0)
         {
            _loc5_ = new NetEvent("error_broadcast");
            _loc5_.data = param1;
            $SendServiceAMFDispatcher.dispatchEvent(_loc5_);
         }
         }
         finally
         {
            delete $serviceData[_loc3_];
            clearTimeOut();
         }
      }
      
      public static function reErrorCheckFun(param1:Object) : void
      {
         var _loc3_:Array = [];
         for(var _loc4_:Object in $serviceData)
         {
            _loc3_[_loc3_.length] = $serviceData[_loc4_]["sendMethod"];
         }
         var _loc2_:NetEvent = new NetEvent("error_service");
         _loc2_.data = param1;
         _loc2_.data["actions"] = _loc3_;
         $SendServiceAMFDispatcher.dispatchEvent(_loc2_);
      }
      
      public static function setSystem(param1:Number) : void
      {
         $systemTimer_nowSecond = param1;
         if($systemTimer == null)
         {
            $systemTimer = new Timer(1000,0);
            $systemTimer.addEventListener("timer",onSystemTimer);
            $systemTimer.start();
         }
      }
      
      public static function onSystemTimer(param1:TimerEvent) : void
      {
         if(GlobalData.$gameIsOut)
         {
            return;
         }
         $systemTimer_nowSecond += 1;
         if($serviceTimeCallFunBySec != null)
         {
            $serviceTimeCallFunBySec();
         }
      }
   }
}

