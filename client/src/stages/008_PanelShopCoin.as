package com.meng52.game.ui.panel
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalLocalStore;
   import com.meng52.game.global.GlobalPay;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.ui.element.ItemShopCoin;
   import com.meng52.game.ui.element.ItemVIP;
   import com.meng52.game.ui.element.ItemVIPShopping;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.screen.PanelCenterSocial;
   import com.meng52.global.GlobalStaticConst;
   import com.meng52.net.SendAndSelect;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.ScrollText;
   import feathers.display.Scale9Image;
   import feathers.textures.Scale9Textures;
   import flash.events.TimerEvent;
   import flash.geom.Rectangle;
   import flash.utils.Timer;
   import starling.display.DisplayObject;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class PanelShopCoin extends PanelCenterSocial
   {
      
      private var mItemArrTemp:Array;
      
      private var mImg_title:Image;
      
      private var mBtn_goPay:LOL_Button;
      
      private var mBox_info:Sprite;
      
      private var mBox_firstAward:Sprite;
      
      private var mVIP_timer:Timer;
      
      private var mTxt_VIPtime:TextFieldHtmlRenderer;
      
      private var mTxt_VIPExp:TextFieldHtmlRenderer;
      
      private var mVIP_box:Sprite;
      
      private var mVIP_l:Sprite;
      
      private var mVIP_r:Sprite;
      
      private var isVIPInfo:Boolean = false;

      private var mSpendingBanner:Sprite;

      private var mSpendingBackground:Scale9Image;

      private var mSpendingText:TextField;

      private var mFirstDoubleText:TextField;

      private var mBalanceText:TextField;

      private var mRateText:TextField;

      private var mSpendingTimer:Timer;

      private var mSpendingDay:String = "";

      private var mCoinRowsRefreshQueued:Boolean = false;
      
      public function PanelShopCoin()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         var _loc2_:String = "";
         if(!MainConfig.$canPay)
         {
            _loc2_ = GlobalLanguageStr.getLanguageStr(20094);
         }
         else
         {
            _loc2_ = GlobalLanguageStr.getLanguageStr(20094);
         }
         if(!GlobalFunction.checkIOSvip())
         {
            _loc2_ = GlobalLanguageStr.getLanguageStr(20224);
         }
         mImg_head = getImg_headBg(-40);
         addChild(mImg_head);
         setTabBar([{
            "label":GlobalLanguageStr.getLanguageStr(20185),
            "indexID":0
         },{
            "label":GlobalLanguageStr.getLanguageStr(20186),
            "indexID":1
         },{
            "label":GlobalLanguageStr.getLanguageStr(20315),
            "indexID":2
         }],tabBar_changeHandler,tabBar_CREATION_COMPLETE);
         mTabBar.y = 5;
         if(GlobalFunction.checkIOSvip())
         {
            this.mTabBar.selectedIndex = GlobalData.$shopType;
         }
         else
         {
            this.mTabBar.selectedIndex = 0;
         }
         mImg3_info = getImg3_info();
         mImg3_info.y = mTabBar.y + 55;
         mImg3_info.height = 40;
         addChild(mImg3_info);
         GlobalData.$mEventDispatcher.addEventListener("profile_state_sync",onSpendingProfileSync);
         GlobalData.$mEventDispatcher.addEventListener("update_shop_coin",onShopCoinUpdated);
         mSpendingDay = shanghaiDayKey();
         mSpendingTimer = new Timer(60000);
         mSpendingTimer.addEventListener("timer",onSpendingTimer);
         mSpendingTimer.start();
         tabBar_changeHandler(null);
         requestSpendingInfo();
      }
      
      override public function tabBar_changeHandler(param1:Event) : void
      {
         if(mTabBar)
         {
            GlobalData.$shopType = this.mTabBar.selectedIndex;
            check_typeFun();
         }
      }
      
      public function gotoShopCoin() : void
      {
         this.mTabBar.selectedIndex = 0;
      }
      
      override public function check_typeFun(param1:String = "") : void
      {
         if(this.mTabBar.selectedIndex == 0)
         {
            this.mStatus_back = "status_normal";
         }
         else if(this.mTabBar.selectedIndex == 1)
         {
            this.mStatus_back = "status_vip";
         }
         else
         {
            this.mStatus_back = "status_vip_shopping";
         }
         if(mList)
         {
            mList.stopScrolling();
         }
         this.update();
      }
      
      override public function update() : void
      {
         if(mList && mSpendingBanner && mSpendingBanner.visible)
         {
            mList.y = mListY;
            mList.height = mListH;
         }
         this.setList();
         this.addList();
         refreshSpendingBanner();
      }

      private function shanghaiDayKey() : String
      {
         var seconds:Number = SendAndSelect.$systemTimer_nowSecond;
         if(!isFinite(seconds) || seconds <= 0) seconds = new Date().time * 0.001;
         var day:Date = new Date(seconds * 1000 + 8 * 3600000);
         var month:String = day.monthUTC + 1 < 10 ? "0" + (day.monthUTC + 1) : String(day.monthUTC + 1);
         var date:String = day.dateUTC < 10 ? "0" + day.dateUTC : String(day.dateUTC);
         return day.fullYearUTC + "-" + month + "-" + date;
      }

      private function onSpendingTimer(param1:TimerEvent) : void
      {
         var day:String = shanghaiDayKey();
         if(day != mSpendingDay)
         {
            mSpendingDay = day;
            requestSpendingInfo();
         }
      }

      private function requestSpendingInfo() : void
      {
         SendAndSelect.sendAndSelectService("user.spending_info",{},onSpendingInfo);
      }

      private function onSpendingInfo(param1:Object) : void
      {
         if(param1 && param1.state_sync && !GlobalData.isCurrentProfileSyncEnvelope(param1.state_sync)) return;
         if(stage != null && param1 && int(param1.return_code) == 0 && param1.data && param1.data.tier != null && GlobalData.$userData)
         {
            GlobalData.$userData.spending = param1.data;
            mSpendingDay = shanghaiDayKey();
            refreshSpendingBanner();
            queueCoinRowsRefresh();
         }
      }

      private function onSpendingProfileSync(param1:Event) : void
      {
         refreshSpendingBanner();
      }

      private function onShopCoinUpdated(param1:Event) : void
      {
         requestSpendingInfo();
         queueCoinRowsRefresh();
      }

      private function queueCoinRowsRefresh() : void
      {
         if(mCoinRowsRefreshQueued || !mList || mStatus_back != "status_normal" || !mItemArrTemp) return;
         mCoinRowsRefreshQueued = true;
         GlobalData.$mStarling.juggler.delayCall(refreshCoinRows,0.05);
      }

      private function refreshCoinRows() : void
      {
         mCoinRowsRefreshQueued = false;
         if(stage == null || !mList || mStatus_back != "status_normal" || !mItemArrTemp) return;
         setListTimer(mList,mItemArrTemp,ItemShopCoin,false);
         refreshSpendingBanner();
      }

      public static function spendingBannerLayout(param1:Number, param2:Number, param3:Number, param4:Boolean) : Object
      {
         var width:Number = Math.min(600,Math.max(0,param1 - 40));
         var height:Number = param4 ? 158 : 126;
         return {x:Math.max(0,(param1 - width) * 0.5),y:param2,width:width,height:height,
            listY:param2 + height + 8,listHeight:Math.max(40,param3 - height - 8)};
      }

      public static function spendingBannerTitle(param1:Object) : String
      {
         if(param1 && param1.is_gm === true) return "GM · 今日可充值：无限制";
         if(param1 && param1.remaining_yuan != null)
         {
            return String(param1.label || "消费档位") + " · 今日剩余：" + int(param1.remaining_yuan) + "元";
         }
         return "正在查询今日剩余额度…";
      }

      public static function walletBalanceTitle(profile:Object) : String
      {
         var balance:Number = profile ? Number(profile.coin) : 0;
         if(!isFinite(balance) || balance < 0) balance = 0;
         return "当前余额：" + Math.floor(balance) + " 金砖";
      }

      private function isLocalMode() : Boolean
      {
         var address:String = MainConfig.$SERVER_ADDRESS;
         return GlobalLocalStore.$pf_type_curr == "local" || address.indexOf("http://127.0.0.1") == 0 || address.indexOf("http://localhost") == 0;
      }

      private function refreshSpendingBanner() : void
      {
         if(!mList || mStatus_back != "status_normal")
         {
            if(mSpendingBanner) mSpendingBanner.visible = false;
            return;
         }
         var first:Boolean = GlobalData.$userData && GlobalData.$userData.attrs && int(GlobalData.$userData.attrs.pay_first_gift) == 0;
         var layout:Object = PanelShopCoin.spendingBannerLayout(GlobalData.$mStageWidth,mListY,mListH,first);
         if(!mSpendingBanner)
         {
            mSpendingBanner = new Sprite();
            mSpendingBanner.touchable = false;
            mSpendingBackground = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",layout.width,layout.height,new Rectangle(20,20,20,20));
            mSpendingBanner.addChild(mSpendingBackground);
            mBalanceText = GlobalTextStyle.getTextField("",28,4926491,"left",layout.width - 40,38);
            mBalanceText.x = 20;
            mBalanceText.y = 12;
            mSpendingBanner.addChild(mBalanceText);
            mSpendingText = GlobalTextStyle.getTextField("",22,4926491,"left",layout.width - 40,32);
            mSpendingText.x = 20;
            mSpendingText.y = 53;
            mSpendingBanner.addChild(mSpendingText);
            mRateText = GlobalTextStyle.getTextField("1元 = 10金砖",18,6505778,"left",layout.width - 40,28);
            mRateText.x = 20;
            mRateText.y = 87;
            mSpendingBanner.addChild(mRateText);
            mFirstDoubleText = GlobalTextStyle.getTextField("首充双倍：首次充值获2倍金砖，额度按原价计算",18,10169366,"left",layout.width - 40,28);
            mFirstDoubleText.x = 20;
            mFirstDoubleText.y = 119;
            mSpendingBanner.addChild(mFirstDoubleText);
            addChild(mSpendingBanner);
         }
         mSpendingBanner.visible = true;
         mSpendingBanner.x = layout.x;
         mSpendingBanner.y = layout.y;
         mSpendingBackground.width = layout.width;
         mSpendingBackground.height = layout.height;
         mBalanceText.width = mSpendingText.width = mRateText.width = mFirstDoubleText.width = layout.width - 40;
         mBalanceText.text = PanelShopCoin.walletBalanceTitle(GlobalData.$userData);
         mSpendingText.text = PanelShopCoin.spendingBannerTitle(GlobalData.$userData ? GlobalData.$userData.spending : null);
         mFirstDoubleText.visible = first;
         setChildIndex(mSpendingBanner,numChildren - 1);
         mList.y = layout.listY;
         mList.height = layout.listHeight;
      }

      override public function onBTN_NAME_BACK() : void
      {
         if(isVIPInfo)
         {
            isVIPInfo = false;
            delVIPInfoBox();
         }
         else
         {
            if(PanelActivityFund.$isPay)
            {
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_activity");
               return;
            }
            if(GlobalData.$shopInByMain)
            {
               GlobalData.$shopInByMain = false;
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_main");
               return;
            }
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_shop");
         }
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalData.$mEventDispatcher.removeEventListener("profile_state_sync",onSpendingProfileSync);
         GlobalData.$mEventDispatcher.removeEventListener("update_shop_coin",onShopCoinUpdated);
         if(mSpendingTimer)
         {
            mSpendingTimer.stop();
            mSpendingTimer.removeEventListener("timer",onSpendingTimer);
            mSpendingTimer = null;
         }
         if(mSpendingBanner)
         {
            mSpendingBanner.removeFromParent(true);
            mSpendingBanner = null;
            mSpendingBackground = null;
            mSpendingText = null;
            mFirstDoubleText = null;
            mBalanceText = null;
            mRateText = null;
         }
         mCoinRowsRefreshQueued = false;
         PanelActivityFund.$isPay = false;
         GlobalData.$shopType = 0;
         isVIPInfo = false;
         delVIPInfoBox();
         setVIPUI(true);
         super.onREMOVED_FROM_STAGE(param1);
      }
      
      override public function addList() : void
      {
         var _loc17_:Object = null;
         var _loc15_:Object = null;
         var _loc13_:Boolean = false;
         var _loc12_:Array = null;
         var _loc5_:String = null;
         var _loc6_:String = null;
         var _loc11_:Array = null;
         var _loc10_:Array = null;
         var _loc16_:int = 0;
         var _loc3_:int = 0;
         var _loc2_:int = 0;
         var _loc8_:int = 0;
         var _loc7_:Vector.<String> = new Vector.<String>();
         var _loc1_:Object = GlobalData.$mConfig_pay;
         var _loc4_:Array = [];
         var _loc14_:int = 0;
         var _loc9_:int = 0;
         if(GlobalFunction.checkIOSvip())
         {
            mList.y = mListY + 100;
            mList.height = mListH - 100;
         }
         if(mStatus_back == "status_normal")
         {
            _loc13_ = false;
            if(_loc13_)
            {
               delVIPInfoBox();
               setVIPUI(false,GlobalFunction.checkIsPayOnly(),true);
            }
            else
            {
               _loc5_ = GlobalData.$mConfig_simple.mon_card_primary_sku;
               _loc6_ = null;
               for(_loc15_ in _loc1_)
               {
                  _loc6_ = _loc15_.toString();
                  if(!(!GlobalFunction.checkIsPayMon30(_loc6_) && _loc6_ == _loc5_))
                  {
                     _loc17_ = {};
                     _loc17_["id"] = _loc6_;
                     _loc17_["status"] = _loc1_[_loc15_];
                     _loc17_["indexID_s"] = _loc1_[_loc15_][2];
                     _loc4_.push(_loc17_);
                     _loc7_.push(_loc17_["id"]);
                  }
               }
               if(_loc4_.length > 0)
               {
                  _loc4_.sortOn("indexID_s");
                  mItemArrTemp = _loc4_;
                  mList.removeEventListener("scroll",onSCROLL);
                  delVIPInfoBox();
                  setVIPUI(false,GlobalFunction.checkIsPayOnly());
                  if(GlobalStaticConst.$isIOS)
                  {
                     if(GlobalFunction.check_isApplePay())
                     {
                        GlobalPay.storeList_os(_loc7_,reStoreList);
                     }
                     else
                     {
                        reStoreList();
                     }
                  }
                  else
                  {
                     reStoreList();
                  }
               }
            }
         }
         else if(mStatus_back == "status_vip")
         {
            _loc11_ = GlobalData.$mConfig_simple.vip_config as Array;
            _loc9_ = GlobalFunction.getVipLv();
            if(_loc9_ < _loc11_[3])
            {
               _loc1_ = GlobalData.$mConfig_vip;
               for(_loc15_ in _loc1_)
               {
                  _loc14_ = int(_loc15_);
                  _loc17_ = _loc1_[_loc15_];
                  _loc17_["id"] = _loc15_.toString();
                  _loc17_["indexID_s"] = _loc14_;
                  if(_loc14_ >= _loc9_)
                  {
                     _loc4_.push(_loc17_);
                  }
               }
               if(_loc4_.length > 0)
               {
                  _loc4_.sortOn("indexID_s",16);
                  mList.addEventListener("scroll",onSCROLL);
                  this.setListTimer(mList,_loc4_,ItemVIP,false);
               }
               _loc1_ = null;
               _loc4_ = null;
               _loc17_ = null;
            }
            else
            {
               onSetVIPInfo();
            }
            setVIPUI();
         }
         else if(mStatus_back == "status_vip_shopping")
         {
            _loc10_ = GlobalData.$userData.attrs.vip_gift_buy as Array;
            _loc16_ = GlobalFunction.getVipLv();
            _loc3_ = GlobalFunction.geVipMaxLv();
            _loc2_ = _loc16_ + 2;
            _loc2_ = _loc2_ > _loc3_ ? _loc3_ : _loc2_;
            _loc8_ = 0;
            _loc8_ = _loc2_;
            while(_loc8_ > 0)
            {
               if(_loc10_.indexOf(_loc8_) < 0)
               {
                  _loc1_ = GlobalFunction.getVipObj(_loc8_);
                  _loc17_ = {};
                  _loc17_["data_base"] = _loc1_.gift_buy;
                  _loc17_["id"] = _loc8_.toString();
                  _loc4_.push(_loc17_);
               }
               _loc8_--;
            }
            this.setListTimer(mList,_loc4_,ItemVIPShopping,false);
            delVIPInfoBox();
            setVIPUI();
         }
      }
      
      public function reStoreList() : void
      {
         GlobalData.$shopAppleGetList = true;
         this.setListTimer(mList,mItemArrTemp,ItemShopCoin,false);
         refreshSpendingBanner();
      }
      
      public function onSCROLL(param1:Event) : void
      {
         (mList.viewPort as Sprite).sortChildren(sortVIPListFun);
      }
      
      public function sortVIPListFun(param1:DisplayObject, param2:DisplayObject) : int
      {
         return param1.y < param2.y ? 0 : 1;
      }
      
      private function setVIP_firstUIs(param1:Sprite) : void
      {
         var _loc5_:Object = null;
         var _loc7_:Array = null;
         var _loc8_:int = 0;
         var _loc16_:Sprite = null;
         var _loc11_:DisplayObject = null;
         var _loc12_:String = null;
         var _loc13_:Object = null;
         var _loc15_:int = 0;
         var _loc17_:Number = NaN;
         var _loc3_:Number = NaN;
         var _loc4_:Number = NaN;
         var _loc14_:TextField = null;
         var _loc6_:String = null;
         var _loc10_:Number = NaN;
         var _loc2_:TextField = null;
         var _loc9_:int = 0;
         if(GlobalData.$userData.attrs.pay_first_gift < 2)
         {
            _loc5_ = GlobalData.$mConfig_simple.pay_first_gift[GlobalData.$userData.attrs.pay_first_gift];
            _loc7_ = [null,null,null,null,null,null,null,null];
            _loc8_ = int(_loc7_.length);
            if(_loc5_["gold"])
            {
               _loc7_[2] = ["gold",_loc5_["gold"]];
            }
            if(_loc5_["equip"])
            {
               _loc7_[3] = ["equip",_loc5_["equip"]];
            }
            if(_loc5_["avatar"])
            {
               _loc7_[4] = ["avatar",_loc5_["avatar"]];
            }
            if(_loc5_["medal"])
            {
               _loc7_[5] = ["medal",_loc5_["medal"]];
            }
            if(_loc5_["mark"])
            {
               _loc7_[6] = ["mark",_loc5_["mark"]];
            }
            if(_loc5_["score"])
            {
               _loc7_[7] = ["score",_loc5_["score"]];
            }
            if(GlobalData.$userData.attrs.pay_first_gift == 0)
            {
               _loc7_[0] = ["vip_title",1];
               _loc7_[1] = ["coin",-1];
            }
            else if(GlobalData.$userData.attrs.pay_first_gift == 1)
            {
               _loc7_[1] = ["coin",-1];
            }
            _loc16_ = new Sprite();
            _loc11_ = null;
            _loc12_ = "";
            _loc13_ = null;
            _loc15_ = 0;
            _loc17_ = 110;
            _loc3_ = 80;
            _loc4_ = 150;
            _loc6_ = "";
            _loc10_ = 0;
            _loc9_ = 0;
            while(_loc9_ < _loc8_)
            {
               _loc2_ = null;
               _loc10_ = 0;
               if(_loc7_[_loc9_] != null)
               {
                  _loc12_ = _loc7_[_loc9_][0].toString();
                  _loc13_ = GlobalFunction.getAwardByType(_loc12_,_loc7_[_loc9_][1]);
                  _loc11_ = _loc13_.ui;
                  if(_loc12_ == "avatar" || _loc12_ == "equip")
                  {
                     _loc6_ = _loc13_.baseName;
                     if(_loc12_ == "equip")
                     {
                        _loc11_.width = _loc11_.height = 80;
                     }
                     else
                     {
                        _loc11_.scaleX = _loc11_.scaleY = 0.9;
                        _loc10_ = 2;
                     }
                  }
                  else if(_loc12_ == "gold")
                  {
                     _loc6_ = Tools.formateNum(Number(_loc13_.baseName)) + GlobalLanguageStr.getLanguageStr(20162);
                  }
                  else
                  {
                     _loc6_ = _loc13_.msg;
                  }
                  _loc11_.x = _loc15_ * (_loc17_ + _loc10_);
                  _loc16_.addChild(_loc11_);
                  _loc14_ = GlobalTextStyle.getTextField(_loc6_,20,16764006,"center",_loc4_,35);
                  _loc14_.x = _loc11_.x + _loc13_.width * 0.5 - _loc4_ * 0.5;
                  _loc14_.y = _loc3_;
                  if(_loc2_ != null)
                  {
                     _loc2_.x = _loc14_.x;
                     _loc2_.y = _loc14_.y - 24;
                     _loc16_.addChild(_loc2_);
                  }
                  _loc16_.addChild(_loc14_);
                  _loc15_ += 1;
               }
               _loc9_++;
            }
            _loc16_.x = GlobalData.$mStageWidth * 0.5 - _loc15_ * _loc17_ * 0.5 + 10;
            _loc16_.y = 70;
            param1.addChild(_loc16_);
         }
      }
      
      private function onTRIGGERED_goPay(param1:Event) : void
      {
         GlobalPay.payByOther();
      }
      
      private function setVIPUI(param1:Boolean = false, param2:Boolean = false, param3:Boolean = false) : void
      {
         var _tw:Number;
         var _bg:Scale9Image;
         var _t9x9:Scale9Textures;
         var _info:TextField;
         var _img_L:Image;
         var _img_R:Image;
         var _vipEx:Array;
         var _rec:Rectangle;
         var _rec2:Rectangle;
         var _expB:Boolean;
         var _isVIPTimeOut:Boolean;
         var _strVIPExp:String;
         var _clear:Boolean = param1;
         var _isMoney:Boolean = param2;
         var _isNoPayList:Boolean = param3;
         if(mBtn_goPay)
         {
            mBtn_goPay.removeFromParent(true);
            mBtn_goPay = null;
         }
         if(mImg_title)
         {
            mImg_title.removeFromParent(true);
            mImg_title = null;
         }
         if(mBox_info)
         {
            StarlingTools.removeChildrenClear(mBox_info);
            mBox_info.removeFromParent(true);
            mBox_info = null;
         }
         if(mTxt_VIPtime)
         {
            mTxt_VIPtime.dispose();
            mTxt_VIPtime = null;
         }
         if(mTxt_VIPExp)
         {
            mTxt_VIPExp.dispose();
            mTxt_VIPExp = null;
         }
         GlobalData.$mEventDispatcher.removeEventListener("show_vip_info",onSetVIPInfo);
         if(isLocalMode() && mStatus_back == "status_normal") return;
         _tw = 600;
         if(!_clear)
         {
            mBox_info = new Sprite();
            if(_isNoPayList)
            {
               mBtn_goPay = GlobalFunction.createButtonStarling("UI_bg_0_8_2_0000",{
                  "t":"开始充值金砖",
                  "fc":16777215,
                  "fs":40
               });
               mBtn_goPay.x = int((GlobalData.$mStageWidth - mBtn_goPay.width) * 0.5);
               mBtn_goPay.y = mListY;
               mBtn_goPay.shadowFilter(1118481);
               mBtn_goPay.addEventListener("triggered",onTRIGGERED_goPay);
               mBox_info.addChild(mBtn_goPay);
            }
            if(_isMoney)
            {
               _t9x9 = new Scale9Textures(GlobalFunction.getTexture("UI_bg_vip_buy_0_0000"),new Rectangle(40,25,30,30));
               _bg = new Scale9Image(_t9x9);
               _bg.width = 600;
               _bg.height = 200;
               _bg.x = int((GlobalData.$mStageWidth - _bg.width) * 0.5);
               mBox_info.addChild(_bg);
               _info = GlobalFunction.createTextField(180,40,GlobalLanguageStr.getStr(90380),"",25,16777215);
               _info.x = (_bg.width - _info.width) * 0.5 + 20;
               _info.y = 20;
               mBox_info.addChild(_info);
               _img_L = GlobalFunction.createImage("UI_bg_9slice_2_0000");
               _img_L.scaleX = _img_L.scaleY = 0.7;
               _img_L.x = _info.x - _img_L.width - 2;
               _img_L.y = _info.y;
               mBox_info.addChild(_img_L);
               _img_R = GlobalFunction.createImage("UI_bg_9slice_2_0000");
               _img_R.scaleX = -0.7;
               _img_R.scaleY = 0.7;
               _img_R.x = _info.x + _info.width + _img_R.width + 2;
               _img_R.y = _info.y;
               mBox_info.addChild(_img_R);
               mList.y = mListY + _bg.height;
               mList.height = mListH - _bg.height + 10;
               mBox_info.y = mListY;
               this.addChild(mBox_info);
               setVIP_firstUIs(mBox_info);
               if(_isNoPayList && mBtn_goPay != null)
               {
                  mBtn_goPay.y = _bg.height;
               }
               return;
            }
            _vipEx = GlobalData.$mConfig_simple.vip_config as Array;
            _t9x9 = new Scale9Textures(GlobalFunction.getTexture("UI_bg_9slice_7_0000"),new Rectangle(30,30,50,50));
            _bg = new Scale9Image(_t9x9);
            _bg.width = 616;
            _bg.height = 105;
            _bg.x = int((GlobalData.$mStageWidth - _bg.width) * 0.5);
            mBox_info.addChild(_bg);
            mBox_info.y = mListY;
            this.addChild(mBox_info);
            mBox_info.visible = GlobalFunction.checkIOSvip();
            _rec = null;
            _rec2 = null;
            mTxt_VIPtime = GlobalTextStyle.getHtmlTextRenderer();
            _expB = true;
            _isVIPTimeOut = false;
            if(this.mTabBar.selectedIndex == 2)
            {
               mTxt_VIPtime.text = Tools.formatHtmlTextBr([Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20318),GlobalTextStyle.COLOR_R_R_R_R,20,30)],"center");
               mTxt_VIPtime.y = 15 - 3;
            }
            else if(GlobalFunction.getVipLv() > 0)
            {
               if(GlobalFunction.isInVipTime())
               {
                  mTxt_VIPtime.text = Tools.formatHtmlTextBr([Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20318,GlobalFunction.getVIPTimeTxt()),GlobalTextStyle.COLOR_R_R_R_R,20,30)],"center");
                  mTxt_VIPtime.y = 15 - 3;
               }
               else
               {
                  mTxt_VIPtime.text = Tools.formatHtmlTextBr([Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90116),GlobalTextStyle.COLOR_R_R_R_R,20,30)],"center");
                  mTxt_VIPtime.y = 15 - 3;
                  _isVIPTimeOut = true;
               }
            }
            else
            {
               mTxt_VIPtime.text = Tools.formatHtmlTextBr([Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20200),GlobalTextStyle.COLOR_R_R_R_R,20,30)],"center");
               mTxt_VIPtime.y = 30;
               _expB = false;
            }
            mTxt_VIPtime.mLayoutFun = function():void
            {
               _rec2 = mTxt_VIPtime.getTextSnapshotFrame();
               mTxt_VIPtime.x = int((GlobalData.$mStageWidth - _rec2.width) * 0.5);
            };
            mBox_info.addChild(mTxt_VIPtime);
            if(_expB)
            {
               mTxt_VIPExp = GlobalTextStyle.getHtmlTextRenderer();
               _strVIPExp = "";
               if(this.mTabBar.selectedIndex == 2)
               {
                  _strVIPExp = GlobalLanguageStr.getLanguageStr(20319);
               }
               else
               {
                  _strVIPExp = _isVIPTimeOut ? GlobalLanguageStr.getLanguageStr(90117) : GlobalLanguageStr.getLanguageStr(20319,GlobalFunction.getVipRate());
               }
               mTxt_VIPExp.text = Tools.formatHtmlTextBr([Tools.formatLineX(_strVIPExp,GlobalTextStyle.COLOR_R_R_R_R,30,30)],"center");
               mTxt_VIPExp.mLayoutFun = function():void
               {
                  _rec = mTxt_VIPExp.getTextSnapshotFrame();
                  mTxt_VIPExp.x = int((GlobalData.$mStageWidth - _rec.width) * 0.5);
               };
               mTxt_VIPExp.y = mTxt_VIPtime.y + 35;
               mBox_info.addChild(mTxt_VIPExp);
            }
            GlobalData.$mEventDispatcher.addEventListener("show_vip_info",onSetVIPInfo);
         }
      }
      
      private function checkVIPUI(param1:Boolean) : void
      {
         if(mBox_info)
         {
            mBox_info.visible = true;
         }
         if(mList)
         {
            mList.visible = param1;
         }
      }
      
      private function setVIPtimer() : void
      {
         mVIP_timer = new Timer(10000);
         mVIP_timer.addEventListener("timer",onVIPtimer);
         mVIP_timer.start();
      }
      
      private function onVIPtimer(param1:TimerEvent) : void
      {
         if(mTxt_VIPtime)
         {
            mTxt_VIPtime.text = GlobalFunction.getVIPTimeTxt();
         }
      }
      
      private function delVIPtimer() : void
      {
         if(mVIP_timer)
         {
            mVIP_timer.stop();
            if(mVIP_timer.hasEventListener("timer"))
            {
               mVIP_timer.removeEventListener("timer",onVIPtimer);
            }
         }
         mVIP_timer = null;
      }
      
      private function onSetVIPInfo(param1:Event = null) : void
      {
         var _loc4_:Object = null;
         var _loc3_:int = 0;
         var _loc2_:Array = GlobalData.$mConfig_simple.vip_config as Array;
         if(param1 != null)
         {
            isVIPInfo = true;
            _loc4_ = param1.data;
            _loc3_ = int(_loc4_["id"]);
         }
         else
         {
            _loc3_ = int(_loc2_[3]);
         }
         delVIPInfoBox();
         if(mVIP_box == null)
         {
            checkVIPUI(false);
            mVIP_box = new Sprite();
            mVIP_l = new Sprite();
            mVIP_r = new Sprite();
            mVIP_box.addChild(mVIP_l);
            mVIP_box.addChild(mVIP_r);
            setVIPInfoBox(mVIP_l,0,_loc3_);
            setVIPInfoBox(mVIP_r,1,_loc3_);
            mVIP_box.y = mListY + 120 + 10;
            this.addChild(mVIP_box);
         }
      }
      
      private function delVIPInfoBox() : void
      {
         checkVIPUI(true);
         if(mBtn_goPay)
         {
            mBtn_goPay.removeFromParent(true);
         }
         if(mVIP_box)
         {
            StarlingTools.removeChildrenClear(mVIP_l);
            StarlingTools.removeChildrenClear(mVIP_r);
            StarlingTools.removeChildrenClear(mVIP_box);
            mVIP_box.removeFromParent(true);
            mVIP_box = null;
            mVIP_l = null;
            mVIP_r = null;
         }
         mBtn_goPay = null;
      }
      
      private function setVIPInfoBox(param1:Sprite, param2:int, param3:int) : void
      {
         var _loc8_:Array = GlobalData.$mConfig_simple.vip_config as Array;
         var _loc6_:int = GlobalFunction.getVipLv();
         if(param2 == 0 && (_loc6_ == param3 || _loc6_ <= 0 || _loc6_ == _loc8_[3]))
         {
            return;
         }
         var _loc12_:Image = GlobalFunction.createImage("UI_bg_vip_2_0000");
         var _loc4_:Number = int(_loc12_.width * 0.5);
         var _loc9_:int = 1;
         var _loc5_:Image = GlobalFunction.getVipImg(param2 == 0 ? _loc6_ : param3);
         _loc5_.touchable = false;
         _loc5_.scaleX = _loc5_.scaleY = 1;
         var _loc11_:Image = GlobalFunction.createImage("UI_bg_vip_txt_1_0000");
         var _loc10_:String = "";
         var _loc7_:ScrollText = new ScrollText();
         if(param2 == 0)
         {
            _loc9_ = 1;
            param1.x = -_loc4_ + 20;
            _loc12_.x = 0;
            _loc5_.x = _loc12_.width - GlobalFunction.getVipLvWidth(_loc6_,1) - 25;
            _loc11_.x = _loc5_.x - _loc11_.width;
            _loc11_.y = 40;
            _loc10_ = GlobalFunction.getVIPgiftInfo(_loc6_);
            _loc7_.x = _loc4_ - 10;
            _loc7_.width = _loc4_ - 10;
         }
         else
         {
            _loc9_ = -1;
            _loc10_ = GlobalFunction.getVIPgiftInfo(param3,65331);
            _loc12_.x = _loc12_.width;
            _loc5_.x = 25;
            _loc7_.x = 30;
            _loc7_.width = _loc4_ - 10;
            if(_loc6_ != param3 && _loc6_ > 0 && _loc6_ < _loc8_[3])
            {
               param1.x = GlobalData.$mStageWidth - _loc4_ - 20;
            }
            else
            {
               param1.x = int((GlobalData.$mStageWidth - _loc12_.width) * 0.5);
               _loc7_.width = _loc4_ * 2 - 20;
            }
         }
         _loc12_.scaleX = _loc9_;
         param1.addChildAt(_loc12_,0);
         _loc5_.y = 30;
         param1.addChild(_loc5_);
         if(param2 == 0)
         {
            param1.addChild(_loc11_);
         }
         _loc7_.isHTML = true;
         _loc7_.text = _loc10_;
         _loc7_.maxHeight = 190;
         _loc7_.y = _loc5_.y + _loc5_.height + 20;
         param1.addChild(_loc7_);
      }
   }
}

