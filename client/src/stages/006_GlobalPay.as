package com.meng52.game.global
{
   import com.meng52.extensions.EventDispatcherANE;
   import com.meng52.extensions.StoreEvent;
   import com.meng52.global.GlobalStaticConst;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.Tools;
   import flash.events.StatusEvent;
   import flash.events.TimerEvent;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   
   public class GlobalPay
   {
      
      private static var payTimes:int;
      
      private static var payPause:Boolean;

      private static var _completedCoinGiftReceipts:Array = [];
      private static var _completedPayOrderIDs:Array = [];

      private static function claimCoinGiftReceipt(param1:Object) : Boolean
      {
         if(param1 == null || param1.state_sync == null)
         {
            return false;
         }
         var _receiptKey:String = String(param1.method) + ":" + String(param1.state_sync.uid) + ":" + String(param1.state_sync.revision);
         if(_completedCoinGiftReceipts.indexOf(_receiptKey) >= 0)
         {
            return false;
         }
         _completedCoinGiftReceipts.push(_receiptKey);
         return true;
      }

      private static function claimPayOrderReceipt(param1:Object) : Boolean
      {
         if(param1 == null || param1.params == null || param1.params.order_id == null)
         {
            return false;
         }
         if(param1.hasOwnProperty("return_code") && int(param1.return_code) != 0)
         {
            return false;
         }
         var _orderID:String = String(param1.params.order_id);
         if(_orderID.length == 0 || _completedPayOrderIDs.indexOf(_orderID) >= 0)
         {
            return false;
         }
         _completedPayOrderIDs.push(_orderID);
         return true;
      }

      private static function requestCoinSnapshot(param1:int) : void
      {
         var _beforeCoin:Number = Number(GlobalData.$userData.coin);
         SendServiceAMFFun.send_user_get_coin(function(param2:Object):void
         {
            reGetCoin(param2,_beforeCoin);
         },{"error_code":param1});
      }
      
      public static var storeList_os_reFun:Function;
      
      public function GlobalPay()
      {
         super();
      }
      
      public static function payByOther() : void
      {
         var callBack_tw:*;
         var _jsonUser:String;
         var _jsonServer:String;
         var onBindCallBack:*;
         var onPayCallBack:*;
         var _class:* = null;
         if(GlobalStaticConst.$isIOS)
         {
            if(GlobalLocalStore.$pf_type_curr == "gatios")
            {
               callBack_tw = function(param1:*):void
               {
                  MainConfig.classIOS_tw_obj.removeEventListener(MainConfig.classIOS_tw_event.STORE_CALLBACK,callBack_tw);
                  requestCoinSnapshot(0);
               };
               _class = MainConfig.classMainExtension;
               MainConfig.classIOS_tw_obj.addEventListener(MainConfig.classIOS_tw_event.STORE_CALLBACK,callBack_tw);
               MainConfig.classIOS_tw_obj.showStore();
            }
         }
         else if(GlobalLocalStore.$pf_type_curr == "gatad")
         {
            onBindCallBack = function(param1:*):void
            {
               var _loc2_:Object = JSON.parse(param1.data);
               if(_loc2_.resultCode == 10000)
               {
                  GlobalLocalStore.$pf_userObj = _loc2_.efunfunUser;
                  _class.getInstance().removeEventListener(MainConfig.classIOS_tw_event.PAY_CALLBACK,onPayCallBack);
               }
            };
            onPayCallBack = function(param1:*):void
            {
               requestCoinSnapshot(0);
               _class.getInstance().removeEventListener(MainConfig.classIOS_tw_event.PAY_CALLBACK,onPayCallBack);
            };
            _class = MainConfig.classMainExtension;
            _jsonUser = JSON.stringify(GlobalLocalStore.$pf_userObj);
            _jsonServer = JSON.stringify(GlobalLocalStore.$pf_serverObj);
            _class.getInstance().efunfunAsPay(_jsonUser,_jsonServer,GlobalData.$userData.name);
            _class.getInstance().addEventListener(MainConfig.classIOS_tw_event.PAY_CALLBACK,onPayCallBack);
         }
      }
      
      public static function reGetCoin(param1:Object, param2:Number) : void
      {
         var _loc5_:Object = null;
         var _loc3_:Number = NaN;
         var _loc4_:Number = NaN;
         var _loc2_:Boolean = false;
         if(param1 && GlobalFunction.isVersionedProfileReceipt(param1))
         {
            _loc5_ = param1.data.user;
            _loc3_ = Number(_loc5_.coin);
            _loc4_ = 0;
            _loc2_ = param1.data.gifts == null || param1.data.gifts.length == 0;
            if(!_loc2_)
            {
               payPause = true;
               GlobalFunction.delLoading();
            }
            var _before:Number = isNaN(param2) ? _loc3_ : param2;
            var _hasGiftReceipt:Boolean = param1.data.gifts != null && param1.data.gifts.length > 0;
            var _coinReceived:Boolean = (_loc3_ > _before || _hasGiftReceipt) && int(param1["params"]["error_code"]) == 0;
            if(_coinReceived)
            {
               _loc4_ = _loc3_ - _before;
               if(_hasGiftReceipt && claimCoinGiftReceipt(param1))
               {
                  GlobalFunction.showReward(param1.data.gifts);
               }
               payPause = true;
               GlobalFunction.delLoading();
               if(!GlobalFunction.isVersionedProfileReceipt(param1))
               {
               GlobalData.$userData.attrs = _loc5_.attrs;
               }
               if(!GlobalFunction.isVersionedProfileReceipt(param1))
               {
               GlobalData.$userData.avatars = _loc5_.avatars;
               }
               if(!GlobalFunction.isVersionedProfileReceipt(param1))
               {
               GlobalData.$userData.my_equips = _loc5_.my_equips;
               }
               if(!GlobalFunction.isVersionedProfileReceipt(param1))
               {
               GlobalData.$userData.gold = _loc5_.gold;
               }
               if(!GlobalFunction.isVersionedProfileReceipt(param1))
               {
               GlobalData.$userData.score = _loc5_.score;
               }
               if(!GlobalFunction.isVersionedProfileReceipt(param1))
               {
               GlobalData.$userData.medal = _loc5_.medal;
               }
               if(!GlobalFunction.isVersionedProfileReceipt(param1))
               {
               GlobalData.$userData.mark = _loc5_.mark;
               }
               if(!GlobalFunction.isVersionedProfileReceipt(param1))
               {
               GlobalData.$userData.vip_lv = _loc5_.vip_lv;
               }
               if(!GlobalFunction.isVersionedProfileReceipt(param1))
               {
               GlobalData.$userData.vip_time = _loc5_.vip_time;
               }
               if(!GlobalFunction.isVersionedProfileReceipt(param1))
               {
               GlobalData.$userData.coin = _loc3_;
               }
               GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateVip();
               GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
               GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
               GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
               GlobalData.$mEventDispatcher.dispatchEventWith("update_shop_coin");
               GlobalData.$mEventDispatcher.dispatchEventWith("update_pay");
               GlobalData.$mEventDispatcher.dispatchEventWith("update_casion_coin");
               GlobalData.$mEventDispatcher.dispatchEventWith("update_groupon_buy_coin");
            }
            else
            {
               GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateVip();
               GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
               GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
               GlobalData.$mEventDispatcher.dispatchEventWith("update_shop_coin");
               GlobalData.$mEventDispatcher.dispatchEventWith("update_pay");
               GlobalData.$mEventDispatcher.dispatchEventWith("update_casion_coin");
               GlobalData.$mEventDispatcher.dispatchEventWith("update_groupon_buy_coin");
            }
         }
      }
      
      public static function pay(param1:String, param2:Array) : void
      {
         var _class:*;
         var _date:Date;
         var _dateStr:String;
         var _orderID:String;
         var _orderID__:String;
         var _timer:Timer;
         var _times:Number;
         var _reCode:int;
         var _cfgs:Object;
         var _pID:String;
         var _cfg:Array;
         var _awardCoin:Number;
         var _pName:String;
         var _priceOld:int;
         var _price:int;
         var _zone:String;
         var _pf_orderID:String;
         var timer:Timer;
         var callBack91ios:*;
         var onStatus_ky:*;
         var _ppPPClosePageViewEvent:Class;
         var _ppPPCloseWebViewEvent:Class;
         var _ppPPPayEvent:Class;
         var callBackPP:*;
         var callBackrkitools:*;
         var callBack_tl:*;
         var buyHandler:*;
         var callBack:*;
         var _usdprice:String;
         var _goldPrice:String;
         var _timesNum:int;
         var callBackListener:*;
         var statusEventListener:*;
         var callBackppw:*;
         var callBack7k7k:*;
         var callBackbfyy:*;
         var callBackAnFeng:*;
         var callBackkuGou:*;
         var callBackGameBaby:*;
         var callBackSouGou1:*;
         var callBackSouGou2:*;
         var callBackSouGou3:*;
         var callBackUC:*;
         var callBackDTDL:*;
         var callBackDTbd:*;
         var callBackOPPO:*;
         var callBackHW:*;
         var callBackFL:*;
         var callBackLenovo:*;
         var callBackAiBei:*;
         var serverId:String;
         var orderID:String;
         var len:int;
         var i:int;
         var feeCode:String;
         var callBackChinaMove:*;
         var tempArr:Array;
         var callBackDTXM:*;
         var dtCallBackWDJ:*;
         var callBackXM:*;
         var callBackAZ:*;
         var callBackDK:*;
         var callBackBFB:*;
         var callBack37:*;
         var callBackJF:*;
         var onSuccess:*;
         var re_kt_pay:*;
         var onSuccess_tstore:*;
         var re_tstore_pay:*;
         var onSuccess_naver:*;
         var re_naver_pay:*;
         var onPurchaseSuccess:*;
         var _pids:String = param1;
         var _status:Array = param2;
         var setGetCoinTimer:* = function():void
         {
            _times = 0;
            delTimer();
            _timer = new Timer(4000,0);
            _timer.addEventListener("timer",timerEvent);
            _timer.start();
            getCoin();
         };
         var delTimer:* = function():void
         {
            if(_timer != null)
            {
               _timer.stop();
               _timer.removeEventListener("timer",timerEvent);
            }
            _timer = null;
         };
         var timerEvent:* = function(param1:TimerEvent):void
         {
            if(_times >= 5)
            {
               delTimer();
               return;
            }
            getCoin();
         };
         var getCoin:* = function():void
         {
            _times += 1;
            requestCoinSnapshot(_reCode);
         };
         var checkCoinControl:* = function(param1:TimerEvent):void
         {
            payTimes += 1;
            if(payTimes >= 30 || payPause)
            {
               GlobalFunction.delLoading();
               if(timer)
               {
                  timer.stop();
                  timer.addEventListener("timer",checkCoinControl);
               }
               timer = null;
               return;
            }
            checkCoin();
         };
         var checkCoin:* = function():void
         {
            _reCode = 0;
            getCoin();
         };
         var paySuccessChangeTask:* = function(param1:Boolean = true):void
         {
            _reCode = 0;
            if(param1)
            {
               setGetCoinTimer();
            }
            else
            {
               GlobalData.$mEventDispatcher.dispatchEventWith("update_shop_coin");
            }
         };
         var reGetCoin_M:* = function():void
         {
            var _loc1_:Object = {
               "ok":getCoin,
               "okUI":GlobalLanguageStr.getLanguageStr(20223)
            };
            GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90066),GlobalTextStyle.COLOR_W_Y_Y_G),_loc1_);
         };
         var idpPayRe:* = function(param1:Object):void
         {
            GlobalFunction.setWebView(param1.data,idpPayCallBack,checkCoin);
         };
         var idpPayCallBack:* = function(param1:String):void
         {
            if(GlobalLocalStore.$pf_type_curr == "rkky")
            {
               if(param1.indexOf("suc.html") > -1)
               {
                  GlobalFunction.delWebView();
                  checkCoin();
               }
            }
            else if(param1.indexOf("return_game") > -1)
            {
               GlobalFunction.delWebView();
               checkCoin();
            }
         };
         var rePayTest:* = function(param1:*):void
         {
            // The authenticated receipt's state_sync has already been merged
            // before this callback. Use the operation receipt, not a second
            // balance-delta poll, to recognize the local purchase.
            if(param1 == null || param1.data == null || param1.data.ok !== true || !claimPayOrderReceipt(param1))
            {
               return;
            }
            _reCode = 0;
            payPause = true;
            GlobalFunction.delLoading();
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateVip();
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
            GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_shop_coin");
            GlobalData.$mEventDispatcher.dispatchEventWith("update_pay");
            GlobalData.$mEventDispatcher.dispatchEventWith("update_casion_coin");
            GlobalData.$mEventDispatcher.dispatchEventWith("update_groupon_buy_coin");
         };
         if(!MainConfig.$canPay)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90060));
            return;
         }
         _class = null;
         _date = new Date();
         _dateStr = String(_date.time);
         _orderID = GlobalData.$userData.uid + "|" + _dateStr.slice(1,_dateStr.length - 2) + "|" + GlobalData.$mServiceID;
         _orderID__ = GlobalData.$userData.uid + "_" + _dateStr.slice(1,_dateStr.length - 2) + "_" + GlobalData.$mServiceID;
         _timer = null;
         _times = 0;
         _reCode = -1001;
         _cfgs = GlobalData.$mConfig_pay;
         _pID = _pids;
         _cfg = _status as Array;
         _awardCoin = _cfg[0] * 10 + _cfg[1];
         _pName = _awardCoin + GlobalLanguageStr.getLanguageStr(20149);
         _priceOld = int(_cfg[0]);
         _price = _priceOld * 100;
         _zone = "";
         _pf_orderID = "";
         if(MainConfig.$isWindows || GlobalLocalStore.$pf_type_curr == "local")
         {
            SendServiceAMFFun.send_user_local_pay_test(rePayTest,{"pid":_pID,"order_id":_orderID});
            return;
         }
         if(GlobalStaticConst.$isIOS)
         {
            if(GlobalLocalStore.$pf_type_curr == "idpun")
            {
               SendServiceAMFFun.send_zfb_pay(idpPayRe,{"pid":_pID});
            }
            else if(GlobalLocalStore.$pf_type_curr == "rk91ios")
            {
               callBack91ios = function(param1:StatusEvent):void
               {
                  var _loc4_:XML = null;
                  var _loc2_:int = 0;
                  var _loc3_:int = 0;
                  if(param1.code == "kNdCPBuyResultNotification")
                  {
                     _loc4_ = XML(param1.level);
                     _loc2_ = int(_loc4_.error);
                     _loc3_ = int(_loc4_.result);
                     checkCoin();
                  }
               };
               _class = MainConfig.classMainExtension;
               EventDispatcherANE.$callBack = callBack91ios;
               _orderID = GlobalData.$userData.uid + "_" + _date.time.toString() + "_" + GlobalData.$mServiceID;
               _class.getInstance().NdUniPayAsyn(_orderID,_pID,_pName,_priceOld,_priceOld,1,GlobalLocalStore.$pf_type_curr);
            }
            else if(GlobalLocalStore.$pf_type_curr == "rkky")
            {
               onStatus_ky = function(param1:StatusEvent):void
               {
                  _class.getInstance().removeEventListener("status",onStatus_ky);
                  var _loc2_:String = param1.level;
                  if(_loc2_ == "close_window")
                  {
                     checkCoin();
                  }
               };
               _class = MainConfig.classMainExtension;
               _orderID += "|" + _pID;
               _class.getInstance().addEventListener("status",onStatus_ky);
               _class.getInstance().KuaiyongSelfCreate(_orderID,_priceOld + "","2184","",_pName,"JhBdbjFwqRAftM2fg24ZwjkM2aJ17TbQ","com.rekoo.lolky");
            }
            else if(GlobalLocalStore.$pf_type_curr == "rkpp")
            {
               callBackPP = function(param1:*):void
               {
                  _class.getInstance().removeEventListener(_ppPPClosePageViewEvent.PP_CLOSEPAGEVIEW_EVENT,callBackPP);
                  _class.getInstance().removeEventListener(_ppPPCloseWebViewEvent.PP_CLOSEWEBVIEW_EVENT,callBackPP);
                  _class.getInstance().removeEventListener(_ppPPPayEvent.PP_PAY_EVENT,callBackPP);
                  checkCoin();
               };
               _class = MainConfig.classMainExtension;
               _ppPPClosePageViewEvent = getDefinitionByName("ppEvents::PPClosePageViewEvent") as Class;
               _ppPPCloseWebViewEvent = getDefinitionByName("ppEvents::PPCloseWebViewEvent") as Class;
               _ppPPPayEvent = getDefinitionByName("ppEvents::PPPayEvent") as Class;
               _class.getInstance().addEventListener(_ppPPClosePageViewEvent.PP_CLOSEPAGEVIEW_EVENT,callBackPP);
               _class.getInstance().addEventListener(_ppPPCloseWebViewEvent.PP_CLOSEWEBVIEW_EVENT,callBackPP);
               _class.getInstance().addEventListener(_ppPPPayEvent.PP_PAY_EVENT,callBackPP);
               _class.getInstance().exchangeGoods(_priceOld,_orderID + "|" + _pID,_pName,"0",0);
            }
            else if(GlobalLocalStore.$pf_type_curr == "rkit" || GlobalLocalStore.$pf_type_curr == "rki4")
            {
               callBackrkitools = function(param1:*):void
               {
                  if(param1.code == "PaySuccess")
                  {
                     EventDispatcherANE.$callBack = null;
                     checkCoin();
                  }
               };
               EventDispatcherANE.$callBack = callBackrkitools;
               _class.MfPay(_orderID + "|" + _pID,_pID,"金砖",_priceOld.toString(),1,"金砖",GlobalData.$mServiceID,"extInfo",GlobalData.$userData.uid,GlobalData.$userData.name,GlobalData.$userData.lv,GlobalData.$userData.gold,GlobalData.$userData.vip_lv,"没有公会",GlobalData.$mServiceID);
            }
            else if(GlobalLocalStore.$pf_type_curr == "rkjsun")
            {
               SendServiceAMFFun.send_zfb_pay(idpPayRe,{"pid":_pID});
            }
            else if(GlobalLocalStore.$pf_type_curr == "rkun")
            {
               SendServiceAMFFun.send_zfb_pay(idpPayRe,{"pid":_pID});
            }
            else if(GlobalLocalStore.$pf_type_curr == "tlios")
            {
               callBack_tl = function(param1:*):void
               {
                  checkCoin();
               };
               _class = MainConfig.classMainExtension;
               _class.instance.addEventListener(MainConfig.classIOS_tl_event.EFUNSDK_BUY_STATE,callBack_tl);
               _class.instance.efunBuy(_pids,GlobalLocalStore.$pf_userid,GlobalData.$userData.uid,GlobalData.$mServiceID,"0","",_pids);
            }
            else if(GlobalLocalStore.$pf_type_curr == "dnyios")
            {
               buyHandler = function(param1:*):void
               {
                  _class.instance.removeEventListener(MainConfig.classIOS_dny_evt.EFUNSDK_BUY_STATE,buyHandler);
                  var _loc2_:String = "EfunSDKEvent.EFUNSDK_BUY_STATE:" + param1.efunSDKInfo;
                  _class.instance.efunDebugLog(_loc2_);
                  checkCoin();
               };
               _class = MainConfig.classMainExtension;
               _class.instance.addEventListener(MainConfig.classIOS_dny_evt.EFUNSDK_BUY_STATE,buyHandler);
               _class.instance.efunBuy(_pID,GlobalLocalStore.$pf_userid,_orderID + "|" + _pID,GlobalData.$mServiceID,GlobalData.$userData.name,GlobalData.$userData.lv,"");
            }
            else
            {
               buy_os(_pids);
            }
         }
         else if(GlobalStaticConst.$isAndroid && MainConfig.classMainExtension)
         {
            _class = MainConfig.classMainExtension;
            if(GlobalLocalStore.$pf_type_curr == "qihoo" || GlobalLocalStore.$pf_type_curr == "dtqh")
            {
               callBack = function(param1:StatusEvent):void
               {
                  checkCoin();
                  EventDispatcherANE.$callBack = null;
               };
               EventDispatcherANE.$callBack = callBack;
               _class.getInstance().callPay(false,GlobalLocalStore.$pf_token_curr,GlobalData.$pfUserInfo.id,String(_price),"10",_pName,_pID,MainConfig.$SERVER_ADDRESS + MainConfig.$pf_notifyURI_curr,MainConfig.$pf_app_name_curr,GlobalData.$userData.name,GlobalData.$userData.uid,_orderID,GlobalData.$mServiceID,GlobalData.$mServiceID);
            }
            else if(GlobalLocalStore.$pf_type_curr == "idpad")
            {
               SendServiceAMFFun.send_zfb_pay(idpPayRe,{"pid":_pID});
            }
            else if(GlobalLocalStore.$pf_type_curr == "jinsad")
            {
               SendServiceAMFFun.send_zfb_pay(idpPayRe,{"pid":_pID});
            }
            else if(GlobalLocalStore.$pf_type_curr == "banshu")
            {
               SendServiceAMFFun.send_zfb_pay(idpPayRe,{"pid":_pID});
            }
            else if(GlobalLocalStore.$pf_type_curr == "dtczk")
            {
               SendServiceAMFFun.send_zfb_pay(idpPayRe,{"pid":_pID});
            }
            else if(GlobalLocalStore.$pf_type_curr == "1006ad")
            {
               SendServiceAMFFun.send_zfb_pay(idpPayRe,{"pid":_pID});
            }
            else if(GlobalLocalStore.$pf_type_curr == "rkafw")
            {
               SendServiceAMFFun.send_zfb_pay(idpPayRe,{"pid":_pID});
            }
            else if(GlobalLocalStore.$pf_type_curr == "sgno1")
            {
               SendServiceAMFFun.send_zfb_pay(idpPayRe,{"pid":_pID});
            }
            else if(GlobalLocalStore.$pf_type_curr == "sytx")
            {
               SendServiceAMFFun.send_zfb_pay(idpPayRe,{"pid":_pID});
            }
            else if(GlobalLocalStore.$pf_type_curr == "rkndw")
            {
               SendServiceAMFFun.send_zfb_pay(idpPayRe,{"pid":_pID});
            }
            else if(GlobalLocalStore.$pf_type_curr == "dnyad")
            {
               callBackListener = function(param1:StatusEvent):void
               {
                  checkCoin();
               };
               _pf_orderID = _cfg[4];
               _usdprice = _cfg[0] + "USD";
               _goldPrice = _cfg[3] + "Gold";
               _class = MainConfig.classMainExtension;
               EventDispatcherANE.$callBack = callBackListener;
               _class.getInstance().efunGooglePlay(EventDispatcherANE.callBack,GlobalLocalStore.$pf_userid,_orderID + "|" + _pID,GlobalData.$mServiceID,_pf_orderID,_goldPrice,_usdprice,GlobalData.$userData.lv,GlobalData.$userData.name,"");
               _timesNum = 4;
            }
            else if(GlobalLocalStore.$pf_type_curr == "rkdx")
            {
               statusEventListener = function(param1:StatusEvent):void
               {
                  MainConfig.dianxinExtension.removeEventListener("status",statusEventListener);
                  trace(param1.code + ": " + param1.level);
                  checkCoin();
               };
               MainConfig.dianxinExtension.addEventListener("status",statusEventListener);
               MainConfig.dianxinExtension.rkPay(_priceOld.toString(),_orderID__ + "_" + _pID);
            }
            else if(GlobalLocalStore.$pf_type_curr == "rkppw")
            {
               callBackppw = function(param1:*):void
               {
                  var _loc2_:String = param1.code;
                  if(_loc2_ == "PaySuccess")
                  {
                     checkCoin();
                     EventDispatcherANE.$callBack = null;
                  }
               };
               EventDispatcherANE.$callBack = callBackppw;
               _class.getInstance().rkPay(_pName,_orderID + "|" + _pID,1,_pID,_pName,String(_priceOld));
            }
            else if(GlobalLocalStore.$pf_type_curr == "7k7k")
            {
               callBack7k7k = function(param1:*):void
               {
                  var _loc2_:String = param1.code;
                  if(_loc2_ == "PaySuccess")
                  {
                     checkCoin();
                     EventDispatcherANE.$callBack = null;
                  }
               };
               EventDispatcherANE.$callBack = callBack7k7k;
               _orderID = GlobalData.$userData.uid + "A" + _dateStr.slice(1,_dateStr.length - 2) + "A" + GlobalData.$mServiceID;
               _class.getInstance().rkPay(_pName,_orderID + "A" + _pID,1,_pID,_pName,String(_priceOld));
            }
            else if(GlobalLocalStore.$pf_type_curr == "bfyy")
            {
               callBackbfyy = function(param1:*):void
               {
                  var _loc2_:String = param1.code;
                  if(_loc2_ == "PaySuccess")
                  {
                     checkCoin();
                     EventDispatcherANE.$callBack = null;
                  }
               };
               EventDispatcherANE.$callBack = callBackbfyy;
               _orderID = GlobalData.$userData.uid + "A" + _dateStr.slice(1,_dateStr.length - 2) + "A" + GlobalData.$mServiceID;
               _class.getInstance().rkPay(_pName,_orderID + "A" + _pID,1,_pID,_pName,String(_priceOld));
            }
            else if(GlobalLocalStore.$pf_type_curr == "anfeng")
            {
               callBackAnFeng = function(param1:*):void
               {
                  var _loc2_:String = param1.code;
                  if(_loc2_ == "PaySuccess")
                  {
                     checkCoin();
                     EventDispatcherANE.$callBack = null;
                  }
               };
               EventDispatcherANE.$callBack = callBackAnFeng;
               _orderID = GlobalData.$userData.uid + "A" + _dateStr.slice(1,_dateStr.length - 2) + "A" + GlobalData.$mServiceID;
               _class.getInstance().rkPay(_pName,_orderID + "A" + _pID,1,_pID,_pName,String(_priceOld));
            }
            else if(GlobalLocalStore.$pf_type_curr == "kugou")
            {
               callBackkuGou = function(param1:*):void
               {
                  var _loc2_:String = param1.code;
                  if(_loc2_ == "PaySuccess")
                  {
                     checkCoin();
                     EventDispatcherANE.$callBack = null;
                  }
               };
               EventDispatcherANE.$callBack = callBackkuGou;
               _orderID = GlobalData.$userData.uid + "A" + _dateStr.slice(1,_dateStr.length - 2) + "A" + GlobalData.$mServiceID;
               _class.getInstance().rkPay(_pName,_orderID + "A" + _pID,1,_pID,_pName,String(_priceOld));
            }
            else if(GlobalLocalStore.$pf_type_curr == "gameBaby")
            {
               callBackGameBaby = function(param1:*):void
               {
                  var _loc2_:String = param1.code;
                  if(_loc2_ == "PaySuccess")
                  {
                     checkCoin();
                     EventDispatcherANE.$callBack = null;
                  }
               };
               EventDispatcherANE.$callBack = callBackGameBaby;
               _orderID = GlobalData.$userData.uid + "A" + _dateStr.slice(1,_dateStr.length - 2) + "A" + GlobalData.$mServiceID;
               _class.getInstance().rkPay(_pName,_orderID + "A" + _pID,1,_pID,_pName,String(_priceOld));
            }
            else if(GlobalLocalStore.$pf_type_curr == "sougou1")
            {
               callBackSouGou1 = function(param1:*):void
               {
                  var _loc2_:String = param1.code;
                  if(_loc2_ == "PaySuccess")
                  {
                     checkCoin();
                     EventDispatcherANE.$callBack = null;
                  }
               };
               EventDispatcherANE.$callBack = callBackSouGou1;
               _orderID = GlobalData.$userData.uid + "A" + _dateStr.slice(1,_dateStr.length - 2) + "A" + GlobalData.$mServiceID;
               _class.getInstance().rkPay(_pName,_orderID + "A" + _pID,1,_pID,_pName,String(_priceOld));
            }
            else if(GlobalLocalStore.$pf_type_curr == "sougou2")
            {
               callBackSouGou2 = function(param1:*):void
               {
                  var _loc2_:String = param1.code;
                  if(_loc2_ == "PaySuccess")
                  {
                     checkCoin();
                     EventDispatcherANE.$callBack = null;
                  }
               };
               EventDispatcherANE.$callBack = callBackSouGou2;
               _orderID = GlobalData.$userData.uid + "A" + _dateStr.slice(1,_dateStr.length - 2) + "A" + GlobalData.$mServiceID;
               _class.getInstance().rkPay(_pName,_orderID + "A" + _pID,1,_pID,_pName,String(_priceOld));
            }
            else if(GlobalLocalStore.$pf_type_curr == "sougou3")
            {
               callBackSouGou3 = function(param1:*):void
               {
                  var _loc2_:String = param1.code;
                  if(_loc2_ == "PaySuccess")
                  {
                     checkCoin();
                     EventDispatcherANE.$callBack = null;
                  }
               };
               EventDispatcherANE.$callBack = callBackSouGou3;
               _orderID = GlobalData.$userData.uid + "A" + _dateStr.slice(1,_dateStr.length - 2) + "A" + GlobalData.$mServiceID;
               _class.getInstance().rkPay(_pName,_orderID + "A" + _pID,1,_pID,_pName,String(_priceOld));
            }
            else if(GlobalLocalStore.$pf_type_curr == "rkuc")
            {
               callBackUC = function(param1:*):void
               {
                  trace(param1);
                  if(param1.code == "PaySuccess")
                  {
                     checkCoin();
                  }
                  else if(param1.code == "Logout")
                  {
                     GlobalFunction.quitGame();
                  }
                  else if(param1.code == "LoginFail")
                  {
                     GlobalFunction.quitGame();
                  }
               };
               EventDispatcherANE.$callBack = callBackUC;
               _class.getInstance().rkPay(GlobalData.$userData.uid,GlobalData.$userData.name,GlobalData.$userData.lv,GlobalData.$userData.gold,GlobalData.$userData.vip_lv,"没有公会",GlobalData.$mServiceID,"金砖",_orderID + "|" + _pID,1,_pID,"金砖",_priceOld.toString(),GlobalData.$mServiceID,"extInfo");
            }
            else if(GlobalLocalStore.$pf_type_curr == "dtdl")
            {
               callBackDTDL = function(param1:*):void
               {
                  checkCoin();
               };
               EventDispatcherANE.$callBack = callBackDTDL;
               _class.getInstance().downjoySDK.pay(_priceOld,GlobalLanguageStr.getLanguageStr(20149),_orderID + "|" + _pID);
            }
            else if(GlobalLocalStore.$pf_type_curr == "dtbd")
            {
               callBackDTbd = function(param1:*):void
               {
                  var _loc2_:Object = null;
                  if(param1.code == "fun_id_pay")
                  {
                     checkCoin();
                  }
                  else if(param1.code == "fun_id_changeAccount")
                  {
                     GlobalLocalStore.$pf_token_curr = "";
                     GlobalLocalStore.$pf_uid_curr = "";
                     GlobalFunction.quitGame();
                  }
               };
               EventDispatcherANE.$callBack = callBackDTbd;
               _class.getInstance().pay_quota(_orderID__ + "_" + _pID,GlobalLanguageStr.getLanguageStr(20149),_price,_orderID__ + "_" + _pID);
            }
            else if(GlobalLocalStore.$pf_type_curr == "dtoppo")
            {
               callBackOPPO = function(param1:*):void
               {
                  if(param1.code == _class.FUN_ID_LOGOUT)
                  {
                     GlobalFunction.quitGame();
                  }
                  else
                  {
                     checkCoin();
                  }
               };
               EventDispatcherANE.$callBack = callBackOPPO;
               _class.getInstance().pay(_orderID + "|" + _pID,_orderID + "|" + _pID,_price,GlobalLanguageStr.getLanguageStr(20149),GlobalLanguageStr.getLanguageStr(20149),"http://dtczk.meng52.net/dtoppo_notify/",_awardCoin);
            }
            else if(GlobalLocalStore.$pf_type_curr == "dthw")
            {
               callBackHW = function(param1:*):void
               {
                  if(param1.code == _class.FUN_ID_CHANGE)
                  {
                     GlobalFunction.quitGame();
                  }
                  else
                  {
                     checkCoin();
                  }
               };
               EventDispatcherANE.$callBack = callBackHW;
               _class.getInstance().pay("上海晨之科信息技术有限公司","900086000021391539","10182591",_priceOld + ".00",GlobalLanguageStr.getLanguageStr(20149),GlobalData.$userData.uid + _dateStr,GlobalLanguageStr.getLanguageStr(20149),_orderID + "|" + _pID,"MIIBVAIBADANBgkqhkiG9w0BAQEFAASCAT4wggE6AgEAAkEAi7M7mT7hAjikVBFyMjklaCGyHFzNG2bO5xYqq5hEhF0I5wifr9Ok3pRBNjTHo6LMuA1Qf1rcV7aJ9aAtYBYHvQIDAQABAkBAopKmmpMcpfxR8Sh22D3Yag6wVLeJQA3mmTjw36iD3JxqHBKTmVtnbUHp6ZNsjdExUeLP32ma0Ahy+/MwE485AiEA67Sabgugm32n7NVvouALlMEqre2hGpTlEje5d4Eb6YMCIQCXun03VaYeh4jYobc8UW9JZb70e4T15ryR3zInMFvFvwIhAOrg1v8QMSSha+QysINS1dePQlN9uAvAEiE8TGJM0x63AiBzF1LEFoPbxJNZP9HuPxdbZYJjkQ5aOJvxSoyQjW4PoQIgHhIKCRpmJwRQI06BUnfdH+FsPg7OPQWQE3bwkwh/gzo=",GlobalLocalStore.$pf_uid_curr);
            }
            else if(GlobalLocalStore.$pf_type_curr == "dtfl")
            {
               callBackFL = function(param1:*):void
               {
                  checkCoin();
               };
               EventDispatcherANE.$callBack = callBackFL;
               _class.getInstance().FlGamePlatformPayAsyn("100199","6D49FAF8-3A78-403F-B8E6-E800557E825F","100133","300000",MainConfig.$pf_app_name_curr,_price,_orderID__ + "_" + _pID,GlobalLanguageStr.getLanguageStr(20149),_orderID__ + "_" + _pID);
            }
            else if(GlobalLocalStore.$pf_type_curr == "dtlenovo")
            {
               callBackLenovo = function(param1:*):void
               {
                  checkCoin();
               };
               EventDispatcherANE.$callBack = callBackLenovo;
               _class.getInstance().pay("1409221666237.app.ln","OTFCMUYyMzc2MjgxNjVGN0NEMjlCRjU3MDhCQjY5QjNFQTVFQThDOU1UQTVNRFUxTWpBNU9UWXlPRGt4TWpRNU5Ea3JNVFUzTkRnMU5qTXlPRGN3TnpVNE5qUTNOVEU1TXpRME1USXdNemMwTmpBd05EWTBNek0z",_orderID + "|" + _pID,_orderID + "|" + _pID,_cfg[5],_price);
            }
            else if(GlobalLocalStore.getPF_dtaib(GlobalLocalStore.$pf_type_curr))
            {
               callBackAiBei = function(param1:*):void
               {
                  checkCoin();
               };
               EventDispatcherANE.$callBack = callBackAiBei;
               _class.getInstance().AiPPPayPay(_cfg[4],_price,_orderID + "|" + _pID,GlobalData.$userData.name,_orderID + "|" + _pID);
            }
            else if(GlobalLocalStore.$pf_type_curr == "ChinaMove")
            {
               callBackChinaMove = function(param1:*):void
               {
                  _class.getInstance().removeEventListener("status",callBackChinaMove);
                  if(param1.level != "cancel")
                  {
                     checkCoin();
                  }
               };
               _class.getInstance().addEventListener("status",callBackChinaMove);
               serverId = GlobalData.$mServiceID;
               serverId = serverId.replace("-","S");
               orderID = _dateStr.slice(1,_dateStr.length - 2) + "A" + serverId;
               len = 16 - orderID.length;
               i = 0;
               while(i < len)
               {
                  orderID = orderID + "M";
                  i = i + 1;
               }
               if(_cfg.length == 5)
               {
                  feeCode = _cfg[4] as String;
                  _class.getInstance().rkPay(true,true,feeCode,orderID);
               }
            }
            else if(GlobalLocalStore.$pf_type_curr == "dtxm")
            {
               callBackDTXM = function(param1:*):void
               {
                  checkCoin();
               };
               EventDispatcherANE.$callBack = callBackDTXM;
               tempArr = [];
               tempArr[0] = _orderID + "|" + _pID;
               tempArr[1] = GlobalData.$userData.name;
               tempArr[2] = _priceOld.toString();
               tempArr[3] = _pName;
               tempArr[4] = _pName;
               tempArr[5] = GlobalData.$userData.lv;
               tempArr[6] = "0";
               tempArr[7] = GlobalData.$userData.name;
               tempArr[8] = GlobalData.$userData.uid;
               tempArr[9] = "testserver";
               _class.getInstance().xiaomiSDK.pay(tempArr[0],tempArr[1],tempArr[2],tempArr[3],tempArr[4],tempArr[5],tempArr[6],tempArr[7],tempArr[8],tempArr[9]);
            }
            else if(GlobalLocalStore.$pf_type_curr == "dtwdj")
            {
               dtCallBackWDJ = function(param1:*):void
               {
                  checkCoin();
               };
               EventDispatcherANE.$callBack = dtCallBackWDJ;
               _class.getInstance().pay(_orderID + "|" + _pID,_pName,String(_price),_orderID + "|" + _pID);
            }
            else if(GlobalLocalStore.$pf_type_curr == "rkxm" || GlobalLocalStore.$pf_type_curr == "rkhw" || GlobalLocalStore.$pf_type_curr == "rk91" || GlobalLocalStore.$pf_type_curr == "rkwdj")
            {
               callBackXM = function(param1:*):void
               {
                  var _loc2_:Object = null;
                  _class.getInstance().rkOnResume();
                  if(param1.code == "PaySuccess")
                  {
                     checkCoin();
                  }
                  else if(param1.code == "Logout")
                  {
                     GlobalFunction.quitGame();
                     _class.getInstance().rkLogin();
                  }
                  else if(param1.code == "LoginSuccess")
                  {
                     _loc2_ = JSON.parse(param1.level);
                     GlobalLocalStore.$pf_token_curr = _loc2_.uid;
                     GlobalLocalStore.$pf_uid_curr = _loc2_.token;
                  }
               };
               EventDispatcherANE.$callBack = callBackXM;
               _class.getInstance().rkPay(GlobalData.$userData.uid,GlobalData.$userData.name,GlobalData.$userData.lv,GlobalData.$userData.gold,GlobalData.$userData.vip_lv,"没有公会",GlobalData.$mServiceID,"金砖",_orderID + "|" + _pID,1,_pID,"金砖",_priceOld.toString(),GlobalData.$mServiceID,"extInfo");
            }
            else if(GlobalLocalStore.$pf_type_curr == "rkaz")
            {
               callBackAZ = function(param1:*):void
               {
                  if(param1.code == "PaySuccess")
                  {
                     EventDispatcherANE.$callBack = null;
                     checkCoin();
                  }
               };
               EventDispatcherANE.$callBack = callBackAZ;
               _class.getInstance().rkPay(GlobalData.$userData.uid,GlobalData.$userData.name,GlobalData.$userData.lv,GlobalData.$userData.gold,GlobalData.$userData.vip_lv,"没有公会",GlobalData.$mServiceID,"金砖",_orderID + "|" + _pID,1,_pID,"金砖",_priceOld.toString(),GlobalData.$mServiceID,"extInfo");
            }
            else if(GlobalLocalStore.$pf_type_curr == "rkdk")
            {
               callBackDK = function(param1:*):void
               {
                  if(param1.code == "PaySuccess")
                  {
                     EventDispatcherANE.$callBack = null;
                     checkCoin();
                  }
               };
               EventDispatcherANE.$callBack = callBackDK;
               _class.getInstance().rkPay(GlobalData.$userData.uid,GlobalData.$userData.name,GlobalData.$userData.lv,GlobalData.$userData.gold,GlobalData.$userData.vip_lv,"没有公会",GlobalData.$mServiceID,"金砖",_orderID + "|" + _pID,1,_pID,"金砖",_priceOld.toString(),GlobalData.$mServiceID,"extInfo");
            }
            else if(GlobalLocalStore.$pf_type_curr == "rkbd")
            {
               callBackBFB = function(param1:StatusEvent):void
               {
                  checkCoin();
               };
               EventDispatcherANE.$callBack = callBackBFB;
               _class.getInstance().BFBPay(MainConfig.$SERVER_ADDRESS + "/rkbd_notify/",1,_orderID + "|" + _pID,_price,_orderID + "|" + _pID);
            }
            else if(GlobalLocalStore.$pf_type_curr == "rk37w" || GlobalLocalStore.$pf_type_curr == "rk37wmz")
            {
               callBack37 = function(param1:*):void
               {
                  trace(param1);
                  if(param1.code == "PaySuccess")
                  {
                     checkCoin();
                  }
               };
               EventDispatcherANE.$callBack = callBack37;
               _class.getInstance().rkPay(GlobalData.$userData.uid,GlobalData.$userData.name,GlobalData.$userData.lv,GlobalData.$userData.gold,GlobalData.$userData.vip_lv,"没有公会",GlobalData.$mServiceID,"金砖",_orderID + "|" + _pID,1,_pID,"金砖",_priceOld.toString(),GlobalData.$mServiceID,"extInfo");
            }
            else if(GlobalLocalStore.$pf_type_curr == "rkjf")
            {
               callBackJF = function(param1:StatusEvent):void
               {
                  checkCoin();
               };
               EventDispatcherANE.$callBack = callBackJF;
               _orderID = GlobalData.$userData.uid + "|" + _dateStr.slice(1,_dateStr.length - 2) + "|" + GlobalData.$mServiceID;
               _class.getInstance().rkPay(_pName,_orderID + "|" + _pID,1,_pID,_pName,String(_priceOld * 10));
            }
            else if(GlobalLocalStore.$pf_type_curr == "rkjsad")
            {
               SendServiceAMFFun.send_zfb_pay(idpPayRe,{"pid":_pID});
            }
            else if(GlobalLocalStore.$pf_type_curr == "rkad")
            {
               SendServiceAMFFun.send_zfb_pay(idpPayRe,{"pid":_pID});
            }
            else if(GlobalLocalStore.$pf_type_curr == "hgkt")
            {
               onSuccess = function(param1:StatusEvent):void
               {
                  MainConfig.classHG_kt.removeEventListener("status",onSuccess);
                  if(param1.code != "PayFailed")
                  {
                     SendServiceAMFFun.send_user_kt_pay(re_kt_pay,{
                        "receipt":param1.level,
                        "pid":_pID
                     });
                  }
               };
               re_kt_pay = function(param1:Object):void
               {
                  checkCoin();
               };
               _pf_orderID = _cfg[4];
               MainConfig.classHG_kt.addEventListener("status",onSuccess);
               MainConfig.classHG_kt.doOrder("8101A823",_pf_orderID);
            }
            else if(GlobalLocalStore.$pf_type_curr == "hgtstore")
            {
               onSuccess_tstore = function(param1:StatusEvent):void
               {
                  var _loc2_:Object = null;
                  MainConfig.classHG_tstore.removeEventListener("status",onSuccess_tstore);
                  if(param1.code != "PayFailed")
                  {
                     _loc2_ = JSON.parse(param1.level);
                     if(_loc2_.result.txid)
                     {
                        SendServiceAMFFun.send_user_tstore_pay(re_tstore_pay,{
                           "txid":_loc2_.result.txid,
                           "receipt":_loc2_.result.receipt,
                           "pid":_pID
                        });
                     }
                  }
               };
               re_tstore_pay = function(param1:Object):void
               {
                  checkCoin();
               };
               _pf_orderID = _cfg[5];
               MainConfig.classHG_tstore.addEventListener("status",onSuccess_tstore);
               MainConfig.classHG_tstore.doOrder("appid=OA00664356&product_id=" + _pf_orderID + "&product_name=CP&tid=" + _orderID + "|" + _pID + "&bpinfo=" + _orderID + "|" + _pID);
            }
            else if(GlobalLocalStore.$pf_type_curr == "hgnaver")
            {
               onSuccess_naver = function(param1:StatusEvent):void
               {
                  var _loc2_:Object = null;
                  MainConfig.classHG_naver.removeEventListener("status",onSuccess_naver);
                  if(param1.code == "PayFailed")
                  {
                     GlobalFunction.tipsOS_ios("결제하기",param1.level,"확인");
                  }
                  else
                  {
                     _loc2_ = JSON.parse(param1.level);
                     SendServiceAMFFun.send_user_naver_pay(re_naver_pay,{
                        "json":param1.level,
                        "pid":_pID
                     });
                  }
               };
               re_naver_pay = function(param1:Object):void
               {
                  checkCoin();
               };
               _pf_orderID = _cfg[6];
               MainConfig.classHG_naver.addEventListener("status",onSuccess_naver);
               MainConfig.classHG_naver.doOrder("NLHK359141401071771946","swwe4JFht8",_pf_orderID,_priceOld,_orderID + "|" + _pID);
            }
            else if(GlobalLocalStore.$pf_type_curr == "hggoogle")
            {
               onPurchaseSuccess = function(param1:Object):void
               {
                  SendServiceAMFFun.send_user_google_pay(re_google_pay,{
                     "json":param1.json,
                     "signature":param1.signature,
                     "itemId":param1.itemId
                  });
               };
               _pf_orderID = _cfg[7];
               MainConfig.classGooglePay.getInstance().serviceBuyFun = onPurchaseSuccess;
               MainConfig.classGooglePay.getInstance().purchaseSpell(_pf_orderID);
            }
         }
      }
      
      public static function reloadInventory_googlePay() : void
      {
         var onPurchaseSuccess:*;
         if(GlobalStaticConst.$isAndroid)
         {
            if(MainConfig.classGooglePay)
            {
               onPurchaseSuccess = function(param1:Object):void
               {
                  SendServiceAMFFun.send_user_google_pay(re_google_pay,{
                     "json":param1.json,
                     "signature":param1.signature,
                     "itemId":param1.itemId
                  });
               };
               if(GlobalLocalStore.$pf_type_curr == "hggoogle")
               {
                  MainConfig.classGooglePay.getInstance().serviceBuyFun = onPurchaseSuccess;
                  MainConfig.classGooglePay.getInstance().reloadInventory();
               }
            }
         }
      }
      
      public static function re_google_pay(param1:Object) : void
      {
         var _loc3_:Object = null;
         var _loc2_:String = null;
         var _loc4_:Array = null;
         if(MainConfig.classGooglePay)
         {
            MainConfig.classGooglePay.getInstance().consumeSpell(param1["params"]["itemId"]);
         }
         if(GlobalLocalStore.$pf_type_curr == "hggoogle")
         {
            if(MainConfig.classAppsflyer)
            {
               _loc3_ = JSON.parse(param1["params"]["json"]);
               _loc2_ = _loc3_.productId;
               for(var _loc5_:Object in GlobalData.$mConfig_pay)
               {
                  _loc4_ = GlobalData.$mConfig_pay[_loc5_];
                  if(_loc4_[7] == _loc2_)
                  {
                     break;
                  }
               }
               MainConfig.classAppsflyer.sendTrackingWithEvent("purchase",_loc4_[0] + "");
            }
         }
         requestCoinSnapshot(0);
      }
      
      public static function get classStoreIOS() : Class
      {
         return MainConfig.classStoreIOS;
      }
      
      public static function storeList_os(param1:Vector.<String> = null, param2:Function = null) : void
      {
         if(classStoreIOS == null)
         {
            return;
         }
         if(GlobalStaticConst.$isIOS)
         {
            GlobalFunction.setLoading();
            storeList_os_reFun = param2;
            classStoreIOS.$mEventDispatcher.addEventListener("EVENT_PRODUCT_DETAILS_SUCCESS",onEVENT_PRODUCT_DETAILS_SUCCESS);
            classStoreIOS.$mEventDispatcher.addEventListener("EVENT_PRODUCT_DETAILS_FAIL",onEVENT_PRODUCT_DETAILS_FAIL);
            classStoreIOS.showList(param1);
         }
      }
      
      public static function onEVENT_PRODUCT_DETAILS_SUCCESS(param1:StoreEvent) : void
      {
         param1.currentTarget.removeEventListener("EVENT_PRODUCT_DETAILS_SUCCESS",onEVENT_PRODUCT_DETAILS_SUCCESS);
         GlobalFunction.delLoading();
         if(storeList_os_reFun != null)
         {
            storeList_os_reFun();
         }
      }
      
      public static function onEVENT_PRODUCT_DETAILS_FAIL(param1:StoreEvent) : void
      {
         param1.currentTarget.removeEventListener("EVENT_PRODUCT_DETAILS_FAIL",onEVENT_PRODUCT_DETAILS_FAIL);
         GlobalFunction.delLoading();
      }
      
      public static function setOS_payFun() : void
      {
         if(classStoreIOS == null)
         {
            return;
         }
         if(GlobalStaticConst.$isIOS)
         {
            if(classStoreIOS)
            {
               if(classStoreIOS.$mEventDispatcher.hasEventListener("EVENT_PURCHASE_TRANSACTION_SUCCESS"))
               {
                  classStoreIOS.$mEventDispatcher.removeEventListener("EVENT_PURCHASE_TRANSACTION_SUCCESS",onEVENT_PURCHASE_TRANSACTION_SUCCESS);
               }
               if(classStoreIOS.$mEventDispatcher.hasEventListener("EVENT_PURCHASE_TRANSACTION_CANCEL"))
               {
                  classStoreIOS.$mEventDispatcher.removeEventListener("EVENT_PURCHASE_TRANSACTION_CANCEL",onEVENT_PURCHASE_TRANSACTION_CANCEL);
               }
            }
            classStoreIOS.$mEventDispatcher.addEventListener("EVENT_PURCHASE_TRANSACTION_SUCCESS",onEVENT_PURCHASE_TRANSACTION_SUCCESS);
            classStoreIOS.$mEventDispatcher.addEventListener("EVENT_PURCHASE_TRANSACTION_CANCEL",onEVENT_PURCHASE_TRANSACTION_CANCEL);
            classStoreIOS.setStore();
         }
      }
      
      public static function onEVENT_PURCHASE_TRANSACTION_CANCEL(param1:StoreEvent) : void
      {
         GlobalFunction.delLoading();
      }
      
      public static function onEVENT_PURCHASE_TRANSACTION_SUCCESS(param1:StoreEvent) : void
      {
         var _re:Object;
         var _tips:String;
         var _event:StoreEvent = param1;
         var sendServiceTo:* = function():void
         {
            SendServiceAMFFun.send_user_pay(rePay,{
               "receipt":_re.receipt,
               "mac":SendAndSelect.$MACID,
               "pay_time":_re.pDate,
               "order_id":_re.identifier,
               "coin_num":_re.pNum,
               "pid":_re.pId
            });
         };
         var rePay:* = function(param1:Object):void
         {
            var _loc2_:Object = GlobalData.$mConfig_pay;
            var _loc7_:Object = param1.data.user;
            var _loc4_:Number = Number(_loc7_.coin);
            var _loc5_:Number = _loc4_ - GlobalData.$userData.coin;
            var _loc6_:String = String(param1["params"]["order_id"]);
            var _loc3_:String = param1["params"]["pid"];
            if(!claimPayOrderReceipt(param1))
            {
               return;
            }
            // state_sync is merged before this callback; order_id is the receipt key.
            finishTransaction(_loc6_);
            if(param1.data.gifts != null && param1.data.gifts.length > 0)
            {
               GlobalFunction.showReward(param1.data.gifts);
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.attrs = _loc7_.attrs;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.avatars = _loc7_.avatars;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.my_equips = _loc7_.my_equips;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.gold = _loc7_.gold;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.score = _loc7_.score;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.medal = _loc7_.medal;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.mark = _loc7_.mark;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.vip_lv = _loc7_.vip_lv;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.vip_time = _loc7_.vip_time;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.coin = _loc4_;
            }
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateVip();
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
            GlobalFunction.delLoading();
            GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_shop_coin");
            GlobalData.$mEventDispatcher.dispatchEventWith("update_pay");
            GlobalData.$mEventDispatcher.dispatchEventWith("update_casion_coin");
         };
         if(!classStoreIOS)
         {
            return;
         }
         _re = _event.data;
         _tips = _re.isTouch ? "" : GlobalLanguageStr.getLanguageStr(90039);
         if(_re.isTouch)
         {
            sendServiceTo();
         }
         else
         {
            GlobalFunction.setLoading();
            GlobalFunction.tipsOS_ios(_tips,GlobalLanguageStr.getLanguageStr(90040),GlobalLanguageStr.getLanguageStr(20140),sendServiceTo);
         }
      }
      
      public static function buy_os(param1:String, param2:int = 1) : void
      {
         if(classStoreIOS == null)
         {
            return;
         }
         GlobalFunction.setLoading();
         if(GlobalStaticConst.$isIOS)
         {
            classStoreIOS.buy(param1,param2);
         }
      }
      
      public static function finishTransaction(param1:String) : void
      {
         if(!classStoreIOS)
         {
            return;
         }
         if(GlobalStaticConst.$isIOS)
         {
            classStoreIOS.finishTransaction(param1);
         }
      }
   }
}

