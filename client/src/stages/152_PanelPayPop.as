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
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.element.LOL_TextField;
   import com.meng52.game.ui.screen.PanelCenterPVE;
   import com.meng52.global.GlobalStaticConst;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.controls.ScrollText;
   import feathers.data.ListCollection;
   import feathers.display.Scale9Image;
   import feathers.layout.VerticalLayout;
   import feathers.textures.Scale9Textures;
   import flash.geom.Rectangle;
   import flash.utils.Timer;
   import flash.events.TimerEvent;
   import com.meng52.net.SendAndSelect;
   import starling.display.DisplayObject;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;

   public class PanelPayPop extends PanelCenterPVE
   {

      private var mItemArrTemp:Array;

      private var mImg_title:Image;

      private var mBtn_goPay:LOL_Scale9Button;

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
      private var mBalanceText:TextField;
      private var mSpendingText:TextField;
      private var mRateText:TextField;
      private var mFirstDoubleText:TextField;
      private var mSpendingTimer:Timer;
      private var mRefreshQueued:Boolean = false;

      public function PanelPayPop()
      {
         super();
      }

      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalData.$mEventDispatcher.removeEventListener("update_pay",onUpdatePanel);
         GlobalData.$mEventDispatcher.removeEventListener("profile_state_sync",onProfileSync);
         GlobalData.$mEventDispatcher.removeEventListener("close_popblack_self",CLOSE_POPBLACK_SELF);
         if(mSpendingTimer)
         {
            mSpendingTimer.stop();
            mSpendingTimer.removeEventListener("timer",requestSpendingInfo);
            mSpendingTimer = null;
         }
         mRefreshQueued = false;
         super.onREMOVED_FROM_STAGE(param1);
      }

      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(20224),GlobalData.$center_height);
         this.addEventListener("close_panel_self",onCLOSE_PANEL_SELF);
         GlobalData.$mEventDispatcher.addEventListener("update_pay",onUpdatePanel);
         GlobalData.$mEventDispatcher.addEventListener("close_popblack_self",CLOSE_POPBLACK_SELF);
         GlobalData.$mEventDispatcher.addEventListener("profile_state_sync",onProfileSync);
         mSpendingTimer = new Timer(60000);
         mSpendingTimer.addEventListener("timer",requestSpendingInfo);
         mSpendingTimer.start();
         update();
         requestSpendingInfo();
      }

      private function CLOSE_POPBLACK_SELF(param1:Event) : void
      {
         GlobalData.$mEventDispatcher.dispatchEventWith("update_shop_list");
         GlobalData.$mEventDispatcher.dispatchEventWith("update_coin");
      }

      private function onUpdatePanel(param1:Event) : void
      {
         if(!mRefreshQueued)
         {
            mRefreshQueued = true;
            GlobalData.$mStarling.juggler.delayCall(refreshAfterPayment,0.05);
         }
      }

      private function refreshAfterPayment() : void
      {
         mRefreshQueued = false;
         if(stage != null) update();
      }

      private function onProfileSync(event:Event) : void
      {
         refreshSpendingBanner();
      }

      private function requestSpendingInfo(event:TimerEvent = null) : void
      {
         SendAndSelect.sendAndSelectService("user.spending_info",{},onSpendingInfo);
      }

      private function onSpendingInfo(result:Object) : void
      {
         if(stage == null || !result || int(result.return_code) != 0 || !result.data || result.data.tier == null) return;
         if(result.state_sync && !GlobalData.isCurrentProfileSyncEnvelope(result.state_sync)) return;
         GlobalData.$userData.spending = result.data;
         refreshSpendingBanner();
      }

      private function isLocalMode() : Boolean
      {
         var address:String = MainConfig.$SERVER_ADDRESS;
         return GlobalLocalStore.$pf_type_curr == "local" || address.indexOf("http://127.0.0.1") == 0 || address.indexOf("http://localhost") == 0;
      }

      private function refreshSpendingBanner() : void
      {
         if(!mList || !isLocalMode())
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
         mList.height = Math.max(40,mImg9_baseBg.y + mImg9_baseBg.height - 18 - layout.listY);
      }

      override public function update() : void
      {
         setList();
         addList();
         refreshSpendingBanner();
      }

      override public function setList() : void
      {
         var _rulerH:Number;
         var settings:Object;
         var _layout:VerticalLayout;
         var tweenComplete:* = function():void
         {
            isReady = true;
         };
         isReady = false;
         isOut = true;
         GlobalData.$mStarling.juggler.tween(this,0.4,{"onComplete":tweenComplete});
         this.delList();
         if(this.mList == null)
         {
            _rulerH = 110;
            settings = {
               "paging":0,
               "gap":5,
               "horizontalGap":20,
               "verticalGap":20,
               "paddingTop":0,
               "paddingRight":0,
               "paddingBottom":0,
               "paddingLeft":0,
               "horizontalAlign":"center",
               "verticalAlign":"top"
            };
            _layout = new VerticalLayout();
            _layout.paddingTop = settings.paddingTop;
            _layout.paddingRight = settings.paddingRight;
            _layout.paddingBottom = settings.paddingBottom;
            _layout.paddingLeft = settings.paddingLeft;
            _layout.horizontalAlign = settings.horizontalAlign;
            _layout.verticalAlign = settings.verticalAlign;
            _layout.gap = settings.gap;
            _layout.hasVariableItemDimensions = true;
            this.mList = new List();
            this.mList.isSelectable = false;
            this.mList.width = GlobalData.$mStageWidth - 20;
            this.mList.height = mListH = GlobalData.$center_height - 230;
            this.mList.layout = _layout;
            this.mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
            this.mList.x = int((GlobalData.$mStageWidth - this.mList.width) * 0.5);
            this.mList.y = mListY = _rulerH;
            this.mList.snapScrollPositionsToPixels = true;
            this.addChild(this.mList);
            settings = null;
            _layout = null;
            this.mList.dataProvider = new ListCollection();
         }
      }

      override public function addList() : void
      {
         var _loc13_:Object = null;
         var _loc12_:Object = null;
         var _loc9_:Object = null;
         var _loc4_:String = null;
         var _loc5_:Object = null;
         var _loc2_:Boolean = false;
         var _loc6_:Vector.<String> = new Vector.<String>();
         var _loc1_:Object = GlobalData.$mConfig_pay;
         var _loc3_:Array = [];
         var _loc11_:int = 0;
         var _loc8_:int = 0;
         if(GlobalFunction.checkIOSvip())
         {
            mList.y = 70;
            mList.height = 600;
         }
         var _loc10_:Boolean = GlobalFunction.check_noPayList();
         if(_loc10_)
         {
            delVIPInfoBox();
            setVIPUI(false,GlobalFunction.checkIsPayOnly(),true);
         }
         else
         {
            _loc9_ = GlobalData.$mConfig_simple.mon_card as Object;
            _loc4_ = null;
            _loc5_ = _loc9_;
            for(_loc12_ in _loc1_)
            {
               _loc4_ = _loc12_.toString();
               _loc2_ = false;
               for(var _loc7_:String in _loc5_)
               {
                  if(!GlobalFunction.checkIsPayMon30(_loc4_) && _loc4_ == _loc7_)
                  {
                     _loc2_ = true;
                  }
                  else if(!_loc5_[_loc7_][3] && _loc4_ == _loc7_)
                  {
                     _loc2_ = true;
                  }
               }
               if(!_loc2_)
               {
                  _loc13_ = {};
                  _loc13_["id"] = _loc4_;
                  _loc13_["status"] = _loc1_[_loc12_];
                  _loc13_["indexID_s"] = _loc1_[_loc12_][2];
                  if(GlobalLocalStore.$pf_type_curr == "ChinaMove")
                  {
                     if(_loc1_[_loc12_][0] <= 100)
                     {
                        _loc3_.push(_loc13_);
                     }
                  }
                  else
                  {
                     _loc3_.push(_loc13_);
                  }
                  _loc6_.push(_loc13_["id"]);
               }
            }
            if(_loc3_.length > 0)
            {
               _loc3_.sortOn("indexID_s",16);
               mItemArrTemp = _loc3_;
               mList.removeEventListener("scroll",onSCROLL);
               delVIPInfoBox();
               setVIPUI(false,GlobalFunction.checkIsPayOnly());
               if(GlobalStaticConst.$isIOS)
               {
                  if(GlobalFunction.check_isApplePay())
                  {
                     GlobalPay.storeList_os(_loc6_,reStoreList);
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

      public function onSCROLL(param1:Event) : void
      {
         (mList.viewPort as Sprite).sortChildren(sortVIPListFun);
      }

      public function sortVIPListFun(param1:DisplayObject, param2:DisplayObject) : int
      {
         return param1.y < param2.y ? 0 : 1;
      }

      public function reStoreList() : void
      {
         GlobalData.$shopAppleGetList = true;
         this.setListTimer(mList,mItemArrTemp,ItemShopCoin,false);
         refreshSpendingBanner();
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

      private function setVIPUI(param1:Boolean = false, param2:Boolean = false, param3:Boolean = false) : void
      {
         var _tw:Number;
         var _bg:Scale9Image;
         var _t9x9:Scale9Textures;
         var _info:LOL_TextField;
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
         if(isLocalMode()) return;
         _tw = 600;
         if(!_clear)
         {
            mBox_info = new Sprite();
            if(_isNoPayList)
            {
               mBtn_goPay = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(95010),200,80,"UI_btn_normalFun_0000");
               mBtn_goPay.fontColor = 1513239;
               mBtn_goPay.shadowFilter();
               mBtn_goPay.x = int((GlobalData.$mStageWidth - mBtn_goPay.width) * 0.5);
               mBtn_goPay.y = mListY;
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
               _info = new LOL_TextField(GlobalLanguageStr.getStr(90380),180,40);
               _info.fontSize = 25;
               _info.fontColor = 16777215;
               _info.shadowFilter();
               _info.x = MainConfig.$isEnglish ? (_bg.width - _info.width) * 0.5 + 21 : (_bg.width - _info.width) * 0.5 + 30;
               _info.y = 25;
               mBox_info.addChild(_info);
               _img_L = GlobalFunction.createImage("UI_bg_title_0_0000");
               _img_L.x = _bg.x + 20;
               _img_L.y = _info.y - 5;
               mBox_info.addChild(_img_L);
               _img_R = GlobalFunction.createImage("UI_bg_title_0_0000");
               _img_R.scaleX = -1;
               _img_R.x = _bg.x + _bg.width - 25;
               _img_R.y = _img_L.y;
               mBox_info.addChild(_img_R);
               mListY = 90;
               mList.y = mListY + _bg.height;
               mList.height = GlobalData.$center_height - 320;
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
            mListY = 90;
            mList.y = mListY;
            mList.height = GlobalData.$center_height - 118;
            mBox_info.y = mListY;
            this.addChild(mBox_info);
            if(!_isNoPayList)
            {
               mBox_info.visible = GlobalFunction.checkIOSvip();
            }
            _rec = null;
            _rec2 = null;
            mTxt_VIPtime = GlobalTextStyle.getHtmlTextRenderer();
            _expB = true;
            _isVIPTimeOut = false;
            if(GlobalFunction.getVipLv() > 0)
            {
               if(GlobalFunction.isInVipTime())
               {
                  mTxt_VIPtime.text = Tools.formatHtmlTextBr([Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20201,GlobalFunction.getVIPTimeTxt()),GlobalTextStyle.COLOR_W_R_R_Y,20,20)],"center");
                  mTxt_VIPtime.y = 15 - 3;
               }
               else
               {
                  mTxt_VIPtime.text = Tools.formatHtmlTextBr([Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90116),GlobalTextStyle.COLOR_W_R_R_Y,20,20)],"center");
                  mTxt_VIPtime.y = 15 - 3;
                  _isVIPTimeOut = true;
               }
            }
            else
            {
               mTxt_VIPtime.text = Tools.formatHtmlTextBr([Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20200),GlobalTextStyle.COLOR_W_R_R_Y,20,20)],"center");
               mTxt_VIPtime.y = 30;
               _expB = false;
            }
            mTxt_VIPtime.mLayoutFun = function():void
            {
               _rec2 = mTxt_VIPtime.getTextSnapshotFrame();
               mTxt_VIPtime.x = int((GlobalData.$mStageWidth - _rec2.width) * 0.5);
            };
            if(_expB)
            {
               mTxt_VIPExp = GlobalTextStyle.getHtmlTextRenderer();
               _strVIPExp = "";
               _strVIPExp = _isVIPTimeOut ? GlobalLanguageStr.getLanguageStr(90117) : GlobalLanguageStr.getLanguageStr(20319,GlobalFunction.getVipRate());
               mTxt_VIPExp.text = Tools.formatHtmlTextBr([Tools.formatLineX(_strVIPExp,GlobalTextStyle.COLOR_W_R_R_Y,30,20)],"center");
               mTxt_VIPExp.mLayoutFun = function():void
               {
                  _rec = mTxt_VIPExp.getTextSnapshotFrame();
                  mTxt_VIPExp.x = int((GlobalData.$mStageWidth - _rec.width) * 0.5);
               };
               mTxt_VIPExp.y = mTxt_VIPtime.y + 35;
            }
            GlobalData.$mEventDispatcher.addEventListener("show_vip_info",onSetVIPInfo);
         }
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
               if(GlobalFunction.checkIOSvip())
               {
                  _loc7_[0] = ["vip_title",1];
               }
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
            _loc17_ = 100;
            _loc3_ = 70;
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
                  _loc13_ = GlobalFunction.getAwardByType(_loc12_,_loc7_[_loc9_][1],false,null,"",false);
                  _loc11_ = _loc13_.ui;
                  _loc11_.pivotX = _loc11_.width / 2;
                  if(_loc12_ == "avatar" || _loc12_ == "equip")
                  {
                     _loc6_ = _loc13_.baseName;
                     if(_loc12_ == "equip")
                     {
                        _loc11_.width = _loc11_.height = 72;
                     }
                     else
                     {
                        _loc11_.scaleX = _loc11_.scaleY = 0.72;
                        _loc10_ = 2;
                        _loc11_.y = -2;
                     }
                  }
                  else if(_loc12_ == "gold")
                  {
                     _loc6_ = _loc13_.msg;
                  }
                  else
                  {
                     _loc6_ = _loc13_.msg;
                  }
                  _loc11_.x = _loc11_.width / 2 + _loc15_ * (_loc17_ + _loc10_);
                  _loc16_.addChild(_loc11_);
                  _loc14_ = GlobalTextStyle.getTextField(_loc6_,MainConfig.$isEnglish ? 13 : 15,16764006,"center",_loc4_,35);
                  _loc14_.pivotX = _loc14_.width / 2;
                  _loc14_.x = _loc11_.x;
                  _loc14_.y = _loc3_;
                  if(_loc12_ == "equip")
                  {
                     _loc14_.x = MainConfig.$isEnglish ? _loc11_.x + 2 : _loc11_.x + 7;
                  }
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

      override public function onTRIGGERED_closePanel(param1:Event) : void
      {
         super.onTRIGGERED_closePanel(param1);
      }

      private function onTRIGGERED_goPay(param1:Event) : void
      {
         GlobalPay.payByOther();
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
