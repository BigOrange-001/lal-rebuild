package com.meng52.game.ui.screen
{
   import com.meng52.display.ScrollScreenForTxt;
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalPay;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.map.GameMapTools;
   import com.meng52.game.ui.element.ItemShopHelp;
   import com.meng52.game.ui.element.ItemVIP;
   import com.meng52.game.ui.element.ItemVIPShopping;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_IconText;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.element.LOL_TextField;
   import com.meng52.game.ui.element.LOL_TimeStatus;
   import com.meng52.net.SendAndSelect;
   import com.meng52.utils.HtmlTextFormat;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import feathers.layout.VerticalLayout;
   import feathers.textures.Scale9Textures;
   import flash.geom.Rectangle;
   import flash.utils.Timer;
   import starling.display.DisplayObject;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   
   public class PanelCenterShopVIP extends PanelCenterPVE
   {
      
      public static var $selectType:int = 1;
      
      public static var BTN_NAME_CASINO_A:String = "btn_name_casino_A";
      
      public static var BTN_NAME_CASINO_B:String = "btn_name_casino_B";
      
      public static var BTN_NAME_CASINO_C:String = "btn_name_casino_C";
      
      public static var BTN_NAME_CASINO_D:String = "btn_name_casino_D";
      
      public static var BTN_NAME_CASINO_E:String = "btn_name_casino_E";
      
      public var pay_btn:LOL_Button;
      
      private var mItemArrTemp:Array;
      
      private var mImg_title:Image;
      
      private var mBtn_goPay:LOL_Button;
      
      private var mBox_info:Sprite;
      
      private var mBox_firstAward:Sprite;
      
      private var mVIP_timer:Timer;
      
      private var mTxt_VIPtime:TextFieldHtmlRenderer;
      
      private var mTxt_VIPExp:TextFieldHtmlRenderer;

      private var mTxt_VipGiftEmpty:TextField;
      
      private var mVIP_box:Sprite;
      
      private var mVIP_l:Sprite;
      
      private var mVIP_r:Sprite;
      
      private var isVIPInfo:Boolean = false;
      
      private var image_VIP:Image;
      
      private const PAYBTN:String = "pay_btn";
      
      public var casinoSprite:Sprite;
      
      private var mBtn_a:Scale9Image;
      
      private var mBtn_b:Scale9Image;
      
      private var mBtn_c:Scale9Image;
      
      private var mBtn_d:Scale9Image;
      
      private var mBtn_e:Scale9Image;
      
      private var mBg_Medal:LOL_MutilTextFieldIcon;
      
      private var mBg_Score:LOL_MutilTextFieldIcon;
      
      private var btn_Medal:LOL_Scale9Button;
      
      private var btn_Score:LOL_Scale9Button;
      
      private var _info_txt:TextField;
      
      private var _info_txt1:TextField;
      
      private var _btnA_txt:LOL_TextField;
      
      private var _btnB_txt:LOL_TextField;
      
      private var _btnD_txt:LOL_TextField;
      
      private var _btnD1_txt:LOL_TextField;
      
      private var mInfo:ScrollScreenForTxt;
      
      private var mTimer:Timer;
      
      private var mTime_a:LOL_TimeStatus;
      
      private var mTime_b:LOL_TimeStatus;
      
      private var mTime_Vip_a:LOL_TimeStatus;
      
      private var mTime_Vip_b:LOL_TimeStatus;
      
      private var mFree_a:LOL_IconText;
      
      private var mFree_b:LOL_IconText;
      
      private var mFree_Vip_a:LOL_IconText;
      
      private var mFree_Vip_b:LOL_IconText;
      
      private var _itemArr:Array = [];
      
      private var _score:Boolean;
      
      private var _isNormalFree:Boolean = false;
      
      private var _userData:Object;
      
      private var _mColor:int = 16777215;
      
      private const TIME_A:String = "time_a";
      
      private const TIME_B:String = "time_b";
      
      private const TIME_VIP_B:String = "time_vip_b";
      
      private const FREE_A:String = "free_a";
      
      private const FREE_B:String = "free_b";
      
      private const FREE_VIp_B:String = "free_vip_b";
      
      public function PanelCenterShopVIP()
      {
         super();
      }
      
      public static function infoUIsA() : Object
      {
         var _loc8_:Object = null;
         var _loc13_:String = null;
         var _loc7_:int = 0;
         var _loc3_:int = 0;
         var _loc10_:Array = null;
         var _loc2_:Number = SendAndSelect.$systemTimer_nowSecond;
         var _loc4_:Number = 0;
         var _loc5_:Number = 0;
         var _loc6_:Number = 0;
         var _loc15_:Number = 0;
         var _loc12_:Date = null;
         var _loc16_:Date = null;
         var _loc9_:Number = 0;
         var _loc11_:Object = {};
         var _loc1_:Object = GlobalData.$mConfig_wager_festival;
         for(var _loc14_:Object in GlobalData.$mConfig_wager_festival)
         {
            _loc13_ = "";
            _loc10_ = GlobalData.$mConfig_wager_festival[_loc14_];
            _loc3_ = int(_loc10_.length);
            _loc7_ = 0;
            while(_loc7_ < _loc3_)
            {
               _loc8_ = _loc10_[_loc7_];
               _loc5_ = (_loc8_.start_time as Date).time * 0.001;
               _loc4_ = (_loc8_.end_time as Date).time * 0.001;
               if(_loc2_ >= _loc5_ && _loc2_ < _loc4_)
               {
                  _loc13_ = GlobalLanguageStr.replaceStrArr(_loc8_.info,[Tools.dateFormat(_loc8_.start_time as Date,-8,"YYYY-MM-DD HH:NN"),Tools.dateFormat(_loc8_.end_time as Date,-8,"YYYY-MM-DD HH:NN")]);
               }
               _loc7_++;
            }
            if(_loc14_ == "coin")
            {
               _loc11_["coin"] = _loc13_;
            }
            else if(_loc14_ == "score")
            {
               _loc11_["score"] = _loc13_;
            }
         }
         _loc10_ = GlobalData.$mConfig_ploy_cycle.info as Array;
         _loc3_ = int(_loc10_.length);
         _loc5_ = (GlobalData.$mConfig_ploy_cycle.start_time as Date).time * 0.001;
         _loc9_ = GlobalData.$mConfig_ploy_cycle.cycle_days * 24 * 60 * 60;
         _loc4_ = Math.floor(_loc2_ - _loc5_);
         if(_loc4_ >= 0)
         {
            _loc15_ = Math.floor(_loc4_ / _loc9_);
            _loc6_ = _loc15_ % _loc3_;
            _loc12_ = new Date();
            _loc16_ = new Date();
            _loc12_.setTime((GlobalData.$mConfig_ploy_cycle.start_time as Date).time + _loc15_ * _loc9_ * 1000);
            _loc16_.setTime((GlobalData.$mConfig_ploy_cycle.start_time as Date).time + (_loc15_ + 1) * _loc9_ * 1000);
            _loc11_["coin"] += GlobalLanguageStr.replaceStrArr(_loc10_[_loc6_],[Tools.dateFormat(_loc12_,-8,"YYYY-MM-DD HH:NN"),Tools.dateFormat(_loc16_,-8,"YYYY-MM-DD HH:NN")]);
         }
         return _loc11_;
      }
      
      public static function infoUIsB() : String
      {
         var _loc11_:* = null;
         var _loc15_:String = "";
         var _loc10_:int = 0;
         var _loc5_:int = 0;
         var _loc13_:Array = null;
         var _loc4_:Number = SendAndSelect.$systemTimer_nowSecond;
         var _loc6_:Number = 0;
         var _loc7_:Number = 0;
         var _loc8_:Number = 0;
         var _loc16_:Number = 0;
         var _loc14_:Date = null;
         var _loc17_:Date = null;
         var _loc12_:Number = 0;
         var _loc3_:Array = GlobalData.$mConfig_festival["avatar"] as Array;
         var _loc2_:Object = null;
         var _loc1_:Boolean = false;
         var _loc9_:int = 0;
         _loc9_ = 0;
         while(_loc9_ < _loc3_.length)
         {
            _loc2_ = _loc3_[_loc9_];
            _loc7_ = (_loc2_.start_time as Date).time * 0.001;
            _loc6_ = (_loc2_.end_time as Date).time * 0.001;
            if(_loc4_ >= _loc7_ && _loc4_ < _loc6_)
            {
               _loc1_ = true;
               break;
            }
            _loc9_++;
         }
         if(_loc1_ && _loc2_)
         {
            _loc14_ = _loc2_.start_time as Date;
            _loc17_ = _loc2_.end_time as Date;
            _loc15_ += GlobalLanguageStr.replaceStrArr(_loc2_.info,[Tools.dateFormat(_loc14_,-8,"YYYY-MM-DD HH:NN"),Tools.dateFormat(_loc17_,-8,"YYYY-MM-DD HH:NN")]);
         }
         _loc2_ = null;
         _loc1_ = false;
         _loc3_ = null;
         _loc3_ = GlobalData.$mConfig_festival["equip"] as Array;
         _loc9_ = 0;
         while(_loc9_ < _loc3_.length)
         {
            _loc2_ = _loc3_[_loc9_];
            _loc7_ = (_loc2_.start_time as Date).time * 0.001;
            _loc6_ = (_loc2_.end_time as Date).time * 0.001;
            if(_loc4_ >= _loc7_ && _loc4_ < _loc6_)
            {
               _loc1_ = true;
               break;
            }
            _loc9_++;
         }
         if(_loc1_ && _loc2_)
         {
            _loc14_ = _loc2_.start_time as Date;
            _loc17_ = _loc2_.end_time as Date;
            _loc15_ += GlobalLanguageStr.replaceStrArr(_loc2_.info,[Tools.dateFormat(_loc14_,-8,"YYYY-MM-DD HH:NN"),Tools.dateFormat(_loc17_,-8,"YYYY-MM-DD HH:NN")]);
         }
         _loc2_ = null;
         _loc3_ = null;
         return _loc15_;
      }
      
      public static function infoUIsC() : String
      {
         var _loc8_:* = null;
         var _loc12_:String = "";
         var _loc7_:int = 0;
         var _loc3_:int = 0;
         var _loc10_:Array = null;
         var _loc2_:Number = SendAndSelect.$systemTimer_nowSecond;
         var _loc4_:Number = 0;
         var _loc5_:Number = 0;
         var _loc6_:Number = 0;
         var _loc13_:Number = 0;
         var _loc11_:Date = null;
         var _loc14_:Date = null;
         var _loc9_:Number = 0;
         var _loc1_:Object = GlobalData.$mConfig_exchange["avatar"];
         _loc5_ = (_loc1_.start_time as Date).time * 0.001;
         _loc9_ = _loc1_.cycle_days * 24 * 60 * 60;
         _loc13_ = 0;
         _loc6_ = 0;
         _loc3_ = int((_loc1_.cycle_exchange as Array).length);
         _loc4_ = Math.floor(_loc2_ - _loc5_);
         _loc10_ = _loc1_.cycle_exchange as Array;
         if(_loc4_ >= 0)
         {
            _loc11_ = new Date();
            _loc14_ = new Date();
            _loc13_ = Math.floor(_loc4_ / _loc9_);
            _loc6_ = _loc13_ % _loc3_;
            _loc11_.setTime((_loc1_.start_time as Date).time + _loc13_ * _loc9_ * 1000);
            _loc14_.setTime((_loc1_.start_time as Date).time + (_loc13_ + 1) * _loc9_ * 1000);
            _loc12_ += GlobalLanguageStr.replaceStrArr(_loc10_[_loc6_].info,[Tools.dateFormat(_loc11_,-8,"YYYY-MM-DD HH:NN"),Tools.dateFormat(_loc14_,-8,"YYYY-MM-DD HH:NN")]);
         }
         _loc1_ = GlobalData.$mConfig_exchange["equip"];
         return _loc12_ + _loc1_.info;
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalData.$mEventDispatcher.removeEventListener("update_vip_gift",onMainEvent_VIP);
         super.onREMOVED_FROM_STAGE(param1);
         if(mTxt_VipGiftEmpty)
         {
            mTxt_VipGiftEmpty.removeFromParent(true);
            mTxt_VipGiftEmpty.dispose();
            mTxt_VipGiftEmpty = null;
         }
         if(_info_txt)
         {
            _info_txt.removeFromParent(true);
            _info_txt.dispose();
         }
         if(_info_txt1)
         {
            _info_txt1.removeFromParent(true);
            _info_txt1.dispose();
         }
         if(btn_Medal)
         {
            btn_Medal.removeEventListener("triggered",onClick_Trigged);
            btn_Medal.removeFromParent(true);
            btn_Medal.dispose();
         }
         if(mBg_Medal)
         {
            mBg_Medal.removeFromParent(true);
            mBg_Medal.dispose();
         }
         if(btn_Score)
         {
            btn_Score.removeEventListener("triggered",onClick_Trigged);
            btn_Score.removeFromParent(true);
            btn_Score.dispose();
         }
         if(mBg_Score)
         {
            mBg_Score.removeFromParent(true);
            mBg_Score.dispose();
         }
         if(_btnA_txt)
         {
            _btnA_txt.removeFromParent(true);
            _btnA_txt.dispose();
         }
         if(_btnB_txt)
         {
            _btnB_txt.removeFromParent(true);
            _btnB_txt.dispose();
         }
         if(_btnD_txt)
         {
            _btnD_txt.removeFromParent(true);
            _btnD_txt.dispose();
         }
         if(_btnD1_txt)
         {
            _btnD1_txt.removeFromParent(true);
            _btnD1_txt.dispose();
         }
         if(mBtn_a)
         {
            mBtn_a.removeFromParent(true);
            mBtn_a.dispose();
         }
         if(mBtn_b)
         {
            mBtn_b.removeFromParent(true);
            mBtn_b.dispose();
         }
         if(mBtn_d)
         {
            mBtn_d.removeFromParent(true);
            mBtn_d.dispose();
         }
         _info_txt = null;
         _info_txt1 = null;
         btn_Medal = null;
         mBg_Medal = null;
         btn_Score = null;
         mBg_Score = null;
         _btnA_txt = null;
         _btnB_txt = null;
         _btnD_txt = null;
         _btnD1_txt = null;
         mBtn_a = null;
         mBtn_b = null;
         mBtn_d = null;
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         GlobalData.$mEventDispatcher.addEventListener("update_vip_gift",onMainEvent_VIP);
         GlobalData.$mEventDispatcher.addEventListener("update_shop_list",UPDATE_SHOP_LIST);
         mImg_head = getImg_headBg(-50);
         addChild(mImg_head);
         var _loc2_:Boolean = GlobalFunction.checkIOSvip();
         var _loc3_:Array = null;
         if(_loc2_)
         {
            _loc3_ = [{
               "label":"招募",
               "indexID":0
            },{
               "label":"VIP商店",
               "indexID":1
            },{
               "label":"特权",
               "indexID":2
            },{
               "label":"VIP礼包",
               "indexID":3
            }];
         }
         else
         {
            _loc3_ = [{
               "label":"招募",
               "indexID":0
            },{
               "label":"VIP商店",
               "indexID":1
            }];
         }
         this.setTabBar(_loc3_,tabBar_changeHandler,tabBar_CREATION_COMPLETE);
         mTabBar.y = 20;
         mTabBar.selectedIndex = $selectType;
         mImg3_info = getImg3_info();
         mImg3_info.y = mTabBar.y + 55;
         addChild(mImg3_info);
         pay_btn = GlobalFunction.createButton_5("","UI_btn_pay_0_0000");
         pay_btn.name = "pay_btn";
         pay_btn.x = mImg_head.width - pay_btn.width - 5;
         pay_btn.y = mImg3_info.y - pay_btn.height;
         pay_btn.addEventListener("triggered",onTRIGGERED);
         addChild(pay_btn);
      }
      
      private function onMainEvent_VIP(param1:Event) : void
      {
         if(param1.type == "update_vip_gift")
         {
            update();
         }
      }
      
      private function UPDATE_SHOP_LIST(param1:Event) : void
      {
         if(mTabBar)
         {
            update();
         }
      }
      
      override public function tabBar_CREATION_COMPLETE(param1:*) : void
      {
         if(GlobalFunction.checkIOSvip())
         {
         }
         tabBar_changeHandler(null);
      }
      
      override public function tabBar_changeHandler_false(param1:int) : void
      {
         var _loc3_:int = 0;
         var _loc2_:String = null;
         if(mTabBar)
         {
            _loc3_ = 0;
            if(param1 == 2)
            {
               _loc3_ = 99;
            }
            if(_loc3_ > 0)
            {
               _loc2_ = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20184,_loc3_),GlobalTextStyle.COLOR_W_B_Y_O);
               GlobalFunction.popAlert("",_loc2_,{"aid":"A_1090_5"});
            }
         }
      }
      
      override public function tabBar_changeHandler(param1:Event) : void
      {
         if(mTabBar)
         {
            GlobalData.$shopType = this.mTabBar.selectedIndex;
            update();
         }
      }
      
      public function gotoShopCoin() : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_pay",false,true);
      }
      
      override public function onTRIGGERED(param1:Event) : void
      {
         var _loc2_:LOL_Button = param1.currentTarget as LOL_Button;
         if(_loc2_.name == BTN_NAME_BACK)
         {
            this.onBTN_NAME_BACK();
         }
         else if(_loc2_.name == BTN_NAME_APPEND)
         {
            this.onBTN_NAME_APPEND();
         }
         else if(_loc2_.name == "pay_btn")
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_pay",false,true);
         }
      }
      
      override public function update() : void
      {
         this.setList();
         this.addList();
      }
      
      override public function addList() : void
      {
         var _loc14_:Object = null;
         var _loc13_:Object = null;
         var _loc10_:Array = null;
         var _loc7_:VerticalLayout = null;
         var _loc9_:Array = null;
         var _loc11_:Array = null;
         var _loc2_:int = 0;
         var _loc15_:int = 0;
         var _loc4_:int = 0;
         var _loc3_:int = 0;
         var _loc6_:int = 0;
         var _loc5_:Vector.<String> = new Vector.<String>();
         var _loc1_:Object = GlobalData.$mConfig_pay;
         var _loc12_:int = 0;
         var _loc8_:int = 0;
         // Rebuild renderer data on every tab change. The original array
         // survives update(), so appending here otherwise duplicates stale
         // rows when users switch between the VIP and shop tabs.
         _itemArr = [];
         if(mTxt_VipGiftEmpty)
         {
            mTxt_VipGiftEmpty.removeFromParent(true);
            mTxt_VipGiftEmpty.dispose();
            mTxt_VipGiftEmpty = null;
         }
         if(GlobalFunction.checkIOSvip())
         {
            mList.y = mListY + 120;
            mList.height = mListH = GlobalData.$center_height - 230;
         }
         if(this.mTabBar.selectedIndex == 0)
         {
            delVIPInfoBox();
            setCasinoUI();
         }
         else if(this.mTabBar.selectedIndex == 1)
         {
            delCasinoUI();
            setShopUI();
         }
         else if(this.mTabBar.selectedIndex == 2)
         {
            _loc10_ = GlobalData.$mConfig_simple.vip_config as Array;
            _loc8_ = GlobalFunction.getVipLv();
            if(_loc10_ != null && GlobalData.$mConfig_vip != null)
            {
               _loc1_ = GlobalData.$mConfig_vip;
               // Keep all configured VIP levels browseable, even when the
               // account is already at the current cap. Each row uses the
               // native ItemVIP renderer and its existing details action.
               _loc3_ = 0;
               while(_loc3_ <= int(_loc10_[3]))
               {
                  _loc12_ = _loc3_;
                  _loc14_ = _loc1_[_loc12_.toString()];
                  if(_loc14_ != null)
                  {
                     _loc14_["id"] = _loc12_.toString();
                     _loc14_["indexID_s"] = _loc12_;
                     _itemArr.push(_loc14_);
                  }
                  _loc3_++;
               }
               if(_itemArr.length > 0)
               {
                  _itemArr.sortOn("indexID_s",16);
                  mList.addEventListener("scroll",onSCROLL);
                  this.setListTimer(mList,_itemArr,ItemVIP,false);
               }
               mList.x = (GlobalData.$mStageWidth - mList.width) / 2 + 15;
               _loc1_ = null;
               _loc14_ = null;
            }
            setVIPUI();
            _loc7_ = new VerticalLayout();
            _loc7_.paddingBottom = 100;
            _loc7_.paddingTop = -15;
            this.mList.layout = _loc7_;
         }
         else if(this.mTabBar.selectedIndex == 3)
         {
            _loc9_ = GlobalData.$userData.attrs.vip_gift_buy as Array;
            _loc11_ = GlobalData.$userData.attrs.vip_gift_buy2 as Array;
            _loc2_ = getVipCoinBuyLv();
            _loc15_ = GlobalFunction.getVipLv();
            _loc4_ = GlobalFunction.geVipMaxLv();
            _loc3_ = _loc15_ + GlobalData.$mConfig_simple.vip_gift_diff;
            _loc3_ = _loc3_ > _loc4_ ? _loc4_ : _loc3_;
            _loc6_ = 0;
            _loc6_ = _loc3_;
            while(_loc6_ > 0)
            {
               if(_loc11_.indexOf(_loc6_) < 0 && _loc6_ >= _loc2_)
               {
                  _loc1_ = GlobalFunction.getVipObj(_loc6_);
                  _loc14_ = {};
                  _loc14_["data_base"] = _loc1_.gift_coin_buy;
                  _loc14_["id"] = _loc6_.toString();
                  _loc14_["status"] = 1;
                  _itemArr.unshift(_loc14_);
               }
               if(_loc9_.indexOf(_loc6_) < 0)
               {
                  _loc1_ = GlobalFunction.getVipObj(_loc6_);
                  _loc14_ = {};
                  _loc14_["data_base"] = _loc1_.gift_buy;
                  _loc14_["id"] = _loc6_.toString();
                  _loc14_["status"] = 0;
                  _itemArr.unshift(_loc14_);
               }
               _loc6_--;
            }
            this.setListTimer(mList,_itemArr,ItemVIPShopping,false);
            delVIPInfoBox();
            setVIPUI();
            mList.height = mListH = GlobalData.$center_height - 195;
            if(_itemArr.length == 0)
            {
               mTxt_VipGiftEmpty = GlobalFunction.createTextField(600,60,GlobalLanguageStr.getLanguageStr(98136),"",28,16777215,true);
               mTxt_VipGiftEmpty.x = int((GlobalData.$mStageWidth - mTxt_VipGiftEmpty.width) * 0.5);
               mTxt_VipGiftEmpty.y = mList.y + int((mList.height - mTxt_VipGiftEmpty.height) * 0.5);
               addChild(mTxt_VipGiftEmpty);
            }
         }
      }
      
      private function getVipCoinBuyLv() : int
      {
         var _loc4_:Object = null;
         var _loc2_:* = 0;
         var _loc1_:Object = GlobalData.$mConfig_pay;
         var _loc5_:int = GlobalFunction.getVipLv();
         var _loc3_:int = GlobalFunction.geVipMaxLv();
         var _loc6_:int = 0;
         _loc6_ = 1;
         while(_loc6_ <= _loc3_)
         {
            _loc4_ = GlobalFunction.getVipObj(_loc6_);
            if(_loc4_.hasOwnProperty("gift_coin_buy"))
            {
               _loc2_ = _loc6_;
               break;
            }
            _loc6_++;
         }
         return _loc2_;
      }
      
      private function setCasinoUI() : void
      {
         var _loc7_:Image = null;
         delCasinoUI();
         casinoSprite = new Sprite();
         var _loc19_:Array = GlobalData.$mConfig_simple.show_avatar;
         _userData = GlobalData.$userData;
         var _loc34_:Number = GlobalData.formatVScaleY_center(850 * 0.1);
         var _loc16_:Image = GlobalFunction.createImage("UI_bg_colorbottom_1_0000");
         casinoSprite.addChild(_loc16_);
         var _loc8_:Array = String(_loc19_[1][0]).split("_");
         var _loc22_:int = int(_loc8_.length);
         var _loc26_:String = int(String(_loc19_[1][0]).split("_")[_loc22_ - 1]) < 6 ? "UI_bg_colorbottom_2_0000" : "UI_bg_colorbottom_3_0000";
         var _loc4_:Image = GlobalFunction.createImage(_loc26_);
         casinoSprite.addChild(_loc4_);
         var _loc18_:Array = String(_loc19_[1][0]).split("_");
         var _loc14_:int = int(_loc18_.length);
         var _loc25_:String = "UI_bg_colorbottom_3_0000";
         var _loc29_:Image = GlobalFunction.createImage(_loc25_);
         casinoSprite.addChild(_loc29_);
         var _loc3_:Image = GlobalFunction.createImage("UI_bg_colorbottom_0_0000");
         _loc3_.width = 275;
         _loc3_.height = 190 + GlobalData.$mStageHeight - 960;
         var _loc35_:Image = GlobalFunction.createImage("UI_bg_colorbottom_0_0000");
         _loc35_.width = _loc3_.width;
         _loc35_.height = _loc3_.height;
         this.addChild(casinoSprite);
         _loc4_.x = int((GlobalData.$mStageWidth - _loc4_.width) * 0.5);
         var _loc11_:Number = _loc4_.width + 15;
         _loc16_.x = _loc4_.x - _loc11_;
         _loc29_.x = _loc4_.x + _loc11_;
         _loc16_.y = _loc4_.y = _loc29_.y = _loc34_ + 100;
         var _loc2_:Rectangle = new Rectangle(0,0,_loc16_.width,_loc16_.height);
         var _loc31_:Rectangle = new Rectangle(0,0,_loc3_.width,_loc3_.height);
         var _loc38_:Rectangle = new Rectangle(0,0,_loc35_.width,_loc35_.height);
         var _loc36_:Image = GameMapTools.newAvatarImgById(_loc19_[0][0],_loc16_.width * 0.5,160);
         var _loc23_:Sprite = new Sprite();
         _loc23_.addChild(_loc36_);
         _loc23_.clipRect = _loc2_;
         _loc23_.x = _loc16_.x;
         _loc23_.y = _loc16_.y;
         _loc23_.touchable = false;
         casinoSprite.addChild(_loc23_);
         var _loc27_:Image = GameMapTools.newAvatarImgById(_loc19_[1][0],_loc4_.width * 0.5,160);
         var _loc12_:Sprite = new Sprite();
         _loc12_.addChild(_loc27_);
         _loc12_.clipRect = _loc2_;
         _loc12_.x = _loc4_.x;
         _loc12_.y = _loc4_.y;
         _loc12_.touchable = false;
         casinoSprite.addChild(_loc12_);
         var _loc9_:Image = GameMapTools.newAvatarImgById(_loc19_[2],_loc29_.width * 0.5,160);
         var _loc20_:Sprite = new Sprite();
         _loc20_.addChild(_loc9_);
         _loc20_.clipRect = _loc2_;
         _loc20_.x = _loc29_.x;
         _loc20_.y = _loc29_.y;
         _loc20_.touchable = false;
         casinoSprite.addChild(_loc20_);
         var _loc5_:Image = GameMapTools.newAvatarImgById("A_1209_4",_loc3_.width * 0.5,100);
         var _loc10_:Sprite = new Sprite();
         _loc10_.addChild(_loc5_);
         _loc10_.clipRect = _loc31_;
         _loc10_.x = _loc3_.x - 10;
         _loc10_.y = _loc3_.y;
         _loc10_.touchable = false;
         var _loc37_:Image = GameMapTools.newAvatarImgById("A_1082_6",_loc35_.width * 0.5,80);
         var _loc17_:Sprite = new Sprite();
         _loc17_.addChild(_loc37_);
         _loc17_.clipRect = _loc38_;
         _loc17_.x = _loc35_.x;
         _loc17_.y = _loc35_.y;
         _loc17_.touchable = false;
         _loc36_.scaleX = _loc36_.scaleY = _loc27_.scaleX = _loc27_.scaleY = _loc9_.scaleX = _loc9_.scaleY = 0.85;
         _loc5_.scaleX = _loc5_.scaleY = _loc37_.scaleX = _loc37_.scaleY = 0.75;
         this.mBtn_a = GlobalFunction.createScale9Image("UI_bg_box_0_0000",190,330,new Rectangle(30,30,30,20));
         mBtn_a.x = _loc16_.x - 5;
         mBtn_a.y = _loc16_.y - 5;
         mBtn_a.touchable = false;
         casinoSprite.addChild(this.mBtn_a);
         this.mBtn_b = GlobalFunction.createScale9Image("UI_bg_box_0_0000",190,330,new Rectangle(30,30,30,20));
         mBtn_b.x = _loc4_.x - 5;
         mBtn_b.y = _loc4_.y - 5;
         mBtn_b.touchable = false;
         casinoSprite.addChild(this.mBtn_b);
         this.mBtn_d = GlobalFunction.createScale9Image("UI_bg_box_0_0000",190,330,new Rectangle(30,30,30,20));
         mBtn_d.x = _loc29_.x - 5;
         mBtn_d.y = _loc29_.y - 5;
         mBtn_d.touchable = false;
         casinoSprite.addChild(this.mBtn_d);
         this.mBtn_c = GlobalFunction.createScale9Image("UI_bg_box_0_0000",285,200 + GlobalData.$mStageHeight - 960,new Rectangle(30,30,30,20));
         mBtn_c.x = _loc3_.x - 5;
         mBtn_c.y = _loc3_.y - 5;
         mBtn_c.touchable = false;
         mBtn_e = GlobalFunction.createScale9Image("UI_bg_box_0_0000",285,200 + GlobalData.$mStageHeight - 960,new Rectangle(30,30,30,20));
         mBtn_e.x = _loc35_.x - 5;
         mBtn_e.y = _loc35_.y - 5;
         mBtn_e.touchable = false;
         _info_txt = GlobalFunction.createTextField(600,MainConfig.$isEnglish ? 60 : 40,GlobalLanguageStr.getStr(90382),"",20,16777215);
         _info_txt.x = (GlobalData.$mStageWidth - _info_txt.width) * 0.5;
         _info_txt.y = mBtn_a.y - (mBtn_a.y - (mImg3_info.y + mImg3_info.height)) / 2 - _info_txt.height;
         casinoSprite.addChild(_info_txt);
         _info_txt1 = GlobalFunction.createTextField(600,MainConfig.$isEnglish ? 60 : 40,GlobalLanguageStr.getStr(97941),"",20,16777215);
         _info_txt1.x = (GlobalData.$mStageWidth - _info_txt1.width) * 0.5;
         _info_txt1.y = _info_txt.y + _info_txt.height - 7;
         casinoSprite.addChild(_info_txt1);
         btn_Medal = new LOL_Scale9Button("    勋章兑换",280,70,"UI_btn_normalFun_0000");
         btn_Medal.x = mBtn_a.x;
         btn_Medal.y = mBtn_a.y + mBtn_a.height;
         casinoSprite.addChild(btn_Medal);
         mBg_Medal = new LOL_MutilTextFieldIcon("","","UI_exchange_icon_0_0000");
         mBg_Medal.iconScale = 0.65;
         mBg_Medal.x = btn_Medal.x + (btn_Medal.width - mBg_Medal.width) * 0.5 - 55;
         mBg_Medal.y = btn_Medal.y + (btn_Medal.height - mBg_Medal.height) * 0.5 + 28;
         casinoSprite.addChild(mBg_Medal);
         btn_Score = new LOL_Scale9Button("    积分兑换",280,70,"UI_btn_normalFun_0000");
         btn_Score.x = btn_Medal.x + btn_Medal.width + 15;
         btn_Score.y = btn_Medal.y;
         casinoSprite.addChild(btn_Score);
         if(getVipTime().can)
         {
            btn_Score.showGlow();
         }
         mBg_Score = new LOL_MutilTextFieldIcon("","","UI_guildCredit_icon_0_0000");
         mBg_Score.iconScale = 0.65;
         mBg_Score.x = btn_Score.x + (btn_Score.width - mBg_Score.width) * 0.5 - 55;
         mBg_Score.y = btn_Score.y + (btn_Score.height - mBg_Score.height) * 0.5 + 25;
         casinoSprite.addChild(mBg_Score);
         _loc16_.name = BTN_NAME_CASINO_A;
         _loc4_.name = BTN_NAME_CASINO_B;
         btn_Medal.name = BTN_NAME_CASINO_C;
         _loc29_.name = BTN_NAME_CASINO_D;
         btn_Score.name = BTN_NAME_CASINO_E;
         _btnA_txt = new LOL_TextField("普通召唤",100,40);
         _btnA_txt.fontSize = 20;
         _btnA_txt.fontColor = 16777215;
         _btnA_txt.shadowFilter();
         _btnA_txt.x = _loc16_.x + 10;
         _btnA_txt.y = _loc16_.y + 10;
         casinoSprite.addChild(_btnA_txt);
         _btnB_txt = new LOL_TextField("高级召唤",100,40);
         _btnB_txt.fontSize = 20;
         _btnB_txt.fontColor = 16777215;
         _btnB_txt.shadowFilter();
         _btnB_txt.x = _loc4_.x + 10;
         _btnB_txt.y = _loc4_.y + 10;
         casinoSprite.addChild(_btnB_txt);
         _btnD_txt = new LOL_TextField(GlobalLanguageStr.getLanguageStr(97926),100,40);
         _btnD_txt.fontSize = 20;
         _btnD_txt.fontColor = 16777215;
         _btnD_txt.shadowFilter();
         _btnD_txt.x = _loc29_.x + 10;
         _btnD_txt.y = _loc29_.y + 10;
         casinoSprite.addChild(_btnD_txt);
         _btnD1_txt = new LOL_TextField(GlobalLanguageStr.getLanguageStr(97982,GlobalData.$mConfig_ploy_system_simple.extract_avatar.start_vip_level),120,40);
         _btnD1_txt.fontSize = 15;
         _btnD1_txt.fontColor = 16777215;
         _btnD1_txt.shadowFilter();
         _btnD1_txt.x = _loc29_.x + 10;
         _btnD1_txt.y = _loc29_.y + 30;
         casinoSprite.addChild(_btnD1_txt);
         var _loc6_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(97680),120,40);
         _loc6_.fontSize = 20;
         _loc6_.fontColor = 16777215;
         _loc6_.shadowFilter();
         _loc6_.x = _loc35_.x + 10;
         _loc6_.y = _loc35_.y + 10;
         var _loc33_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getStr(90383),100,40);
         _loc33_.fontSize = 20;
         _loc33_.fontColor = 16777215;
         _loc33_.shadowFilter();
         _loc33_.x = _loc3_.x + 10;
         _loc33_.y = _loc3_.y + 10;
         _loc16_.addEventListener("touch",onTOUCH);
         _loc4_.addEventListener("touch",onTOUCH);
         _loc29_.addEventListener("touch",onTOUCH);
         btn_Medal.addEventListener("triggered",onClick_Trigged);
         btn_Score.addEventListener("triggered",onClick_Trigged);
         var _loc13_:String = "普通召唤使用友情积分，高级召唤使用金砖。<br/><br/>召唤勋章：80枚兑换一张橙卡，每日更新20名非皮肤英雄。<br/><br/>召唤积分：100分兑换40个指定皮肤的橙色碎片。<br/>当前开放：二郎真君赵信、钢铁侠提莫。";
         var _loc32_:Number = int(GlobalData.centerRealHeight() - _loc16_.y - _loc16_.height - 10 - 15);
         var _loc21_:Scale9Image = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",618,_loc32_ - 40,new Rectangle(110,55,70,20));
         _loc21_.x = int((GlobalData.$mStageWidth - _loc21_.width) * 0.5);
         _loc21_.y = GlobalData.$center_height_curr - 121 - _loc32_ + 43;
         casinoSprite.addChild(_loc21_);
         var _loc15_:String = HtmlTextFormat.font(_loc13_,4926491,20);
         mInfo = new ScrollScreenForTxt(_loc15_,_loc21_.width - 100,_loc21_.height - 55);
         mInfo.x = _loc21_.x + 50;
         mInfo.y = _loc21_.y + 25;
         casinoSprite.addChild(this.mInfo);
         if(GlobalFunction.checkIsSale("center_casino"))
         {
            _loc7_ = GlobalFunction.createImage("UI_sale_bg_2_0000");
            _loc7_.x = this.mBtn_b.x + 80;
            _loc7_.y = this.mBtn_b.y;
            casinoSprite.addChild(_loc7_);
         }
         this.addChild(casinoSprite);
         setFree();
      }
      
      private function onClick_Trigged(param1:Event) : void
      {
         var _loc2_:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         if(_loc2_.name == BTN_NAME_CASINO_C)
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_exchange",false,true);
         }
         else if(_loc2_.name == BTN_NAME_CASINO_E)
         {
            onCLOSE_PANEL_SELF();
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_main");
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_intergral_exchange",false,true);
         }
      }
      
      protected function onTOUCH(param1:TouchEvent) : void
      {
         var _loc2_:Array = null;
         var _loc4_:Boolean = false;
         var _loc6_:Image = param1.currentTarget as Image;
         var _loc5_:Touch = param1.getTouch(_loc6_,"ended");
         var _loc3_:Boolean = true;
         if(_loc5_)
         {
            GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
            if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len && (_loc6_.name == BTN_NAME_CASINO_A || _loc6_.name == BTN_NAME_CASINO_B))
            {
               _loc3_ = false;
               GlobalFunction.popAvatarLen();
               return;
            }
            if(_loc6_.name == BTN_NAME_CASINO_A && _loc3_)
            {
               _loc2_ = GlobalData.$mConfig_simple.wager_avatar as Array;
               _loc4_ = _loc2_[15] > _userData.records.free_wager_count;
               if(GlobalFunction.checkWagerTime(0) > 0)
               {
                  GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_casino_A",false,true);
               }
               else if(_loc4_)
               {
                  GlobalData.$mEventDispatcher.dispatchEventWith("update_casino_free_A");
               }
               else
               {
                  GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_casino_A",false,true);
               }
            }
            else if(_loc6_.name == BTN_NAME_CASINO_B && _loc3_)
            {
               if(GlobalFunction.checkWagerTime(1) > 0)
               {
                  GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_casino_B",false,true);
               }
               else
               {
                  GlobalData.$mEventDispatcher.dispatchEventWith("update_casino_free_B");
               }
            }
            else if(_loc6_.name == BTN_NAME_CASINO_D)
            {
               if(GlobalData.$userData.vip_lv >= GlobalData.$mConfig.ploy_system_simple.extract_avatar.start_vip_level)
               {
                  GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_casino_VIP",false,true);
               }
               else
               {
                  GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(97971));
               }
            }
            return;
         }
      }
      
      private function getVipTime() : Object
      {
         var _loc6_:Object = GlobalData.$mConfig_ploy_system_simple.extract_avatar;
         var _loc3_:Number = (_loc6_.start_time as Date).time;
         var _loc5_:Number = (_loc6_.end_time as Date).time;
         var _loc1_:Number = SendAndSelect.$systemTimer_nowSecond * 1000;
         var _loc2_:Date = new Date();
         _loc2_.setTime(_loc1_);
         var _loc4_:Object = {};
         if(_loc1_ > _loc3_ && _loc1_ < _loc5_)
         {
            _loc4_.can = true;
         }
         else
         {
            _loc4_.can = false;
         }
         return _loc4_;
      }
      
      private function delCasinoUI() : void
      {
         if(mTime_a)
         {
            StarlingTools.removeChildrenClear(mTime_a);
            mTime_a.removeFromParent(true);
            mTime_a.dispose();
         }
         if(mTime_b)
         {
            StarlingTools.removeChildrenClear(mTime_b);
            mTime_b.removeFromParent(true);
            mTime_b.dispose();
         }
         if(mTime_Vip_b)
         {
            StarlingTools.removeChildrenClear(mTime_Vip_b);
            mTime_Vip_b.removeFromParent(true);
            mTime_Vip_b.dispose();
         }
         if(mFree_a)
         {
            mFree_a.dispose();
         }
         if(mFree_b)
         {
            mFree_b.dispose();
         }
         if(mFree_Vip_b)
         {
            mFree_Vip_b.dispose();
         }
         if(mInfo)
         {
            mInfo.removeFromParent(true);
            mInfo.dispose();
         }
         if(casinoSprite)
         {
            StarlingTools.removeChildrenClear(casinoSprite);
            casinoSprite.removeFromParent(true);
         }
         mTime_Vip_b = null;
         mFree_Vip_b = null;
         casinoSprite = null;
         mFree_b = null;
         mFree_a = null;
         mTime_b = null;
         mTime_a = null;
         mInfo = null;
      }
      
      private function createTime(param1:String) : void
      {
         var _config:Array;
         var removeTimeA:*;
         var removeTimeB:*;
         var _str:String = param1;
         var _gap:Number = 50;
         if("time_a" == _str)
         {
            removeTimeA = function():void
            {
               if(mTime_a != null)
               {
                  mTime_a.visible = false;
               }
               if(mFree_a != null)
               {
                  mFree_a.removeFromParent(true);
                  mFree_a = null;
               }
               createFree("free_a");
            };
            if(mTime_a != null)
            {
               mTime_a.removeFromParent(true);
               mTime_a = null;
            }
            _config = GlobalData.$mConfig_simple.wager_avatar as Array;
            mTime_a = GlobalFunction.setWagerTime("mTime_a",mTime_a,0,removeTimeA);
            mTime_a.x = mBtn_a.x + int((mBtn_a.width - 109) * 0.5) - 30;
            mTime_a.y = mBtn_a.y + mBtn_a.height - _gap + 5;
            mTime_a.scaleX = mTime_a.scaleY = 0.7;
            casinoSprite.addChild(this.mTime_a);
         }
         else if("time_b" == _str)
         {
            removeTimeB = function():void
            {
               if(mTime_b != null)
               {
                  mTime_b.visible = false;
               }
               if(mFree_b != null)
               {
                  mFree_b.removeFromParent(true);
                  mFree_b = null;
               }
               createFree("free_b");
            };
            if(mTime_b != null)
            {
               mTime_b.removeFromParent(true);
               mTime_b = null;
            }
            mTime_b = GlobalFunction.setWagerTime("mTime_b",mTime_b,1,removeTimeB);
            mTime_b.x = mBtn_b.x + int((mBtn_b.width - 109) * 0.5) - 30;
            mTime_b.y = mBtn_b.y + mBtn_b.height - _gap + 5;
            mTime_b.scaleX = mTime_b.scaleY = 0.7;
            casinoSprite.addChild(this.mTime_b);
         }
      }
      
      private function createFree(param1:String) : void
      {
         var _loc3_:Number = NaN;
         var _loc2_:Array = null;
         var _loc4_:String = null;
         if("free_a" == param1)
         {
            if(mFree_a != null)
            {
               mFree_a.removeFromParent(true);
               mFree_a = null;
            }
            _mColor = 65331;
            _loc3_ = 80;
            _loc2_ = GlobalData.$mConfig_simple.wager_avatar as Array;
            _loc4_ = GlobalLanguageStr.getLanguageStr(90436,_loc2_[15] - _userData.records.free_wager_count,_loc2_[15]);
            mFree_a = new LOL_IconText(_loc4_,_mColor);
            if(MainConfig.$isEnglish)
            {
               mFree_a.fontSize = 18;
            }
            mFree_a.width = 170;
            mFree_a.bgWidth = 170;
            mFree_a.x = MainConfig.$isEA ? mBtn_a.x + int((mBtn_a.width - mFree_a.width) * 0.5) + 5 : (MainConfig.$isEnglish ? mBtn_a.x + int((mBtn_a.width - mFree_a.width) * 0.5) : mBtn_a.x + int((mBtn_a.width - mFree_a.width) * 0.5) + 5);
            mFree_a.y = mBtn_a.y + mBtn_a.height - mFree_a.height - 10;
            mFree_a.scaleX = mFree_a.scaleY = 0.7;
            casinoSprite.addChild(mFree_a);
         }
         else if("free_b" == param1)
         {
            if(mFree_b != null)
            {
               mFree_b.removeFromParent(true);
               mFree_b = null;
            }
            _mColor = 65331;
            mFree_b = new LOL_IconText(GlobalLanguageStr.getStr(90441),_mColor);
            if(MainConfig.$isEnglish)
            {
               mFree_b.fontSize = 18;
            }
            mFree_b.width = 170;
            mFree_b.bgWidth = 170;
            mFree_b.x = MainConfig.$isEA ? mBtn_b.x + int((mBtn_b.width - mFree_b.width) * 0.5) + 5 : (MainConfig.$isEnglish ? mBtn_b.x + int((mBtn_b.width - mFree_b.width) * 0.5) - 5 : mBtn_b.x + int((mBtn_b.width - mFree_b.width) * 0.5) + 5);
            mFree_b.y = mBtn_b.y + mBtn_b.height - mFree_b.height - 10;
            mFree_b.scaleX = mFree_b.scaleY = 0.7;
            casinoSprite.addChild(mFree_b);
         }
      }
      
      private function setFree() : void
      {
         var _loc1_:Array = GlobalData.$mConfig_simple.wager_avatar as Array;
         _isNormalFree = _userData.records.free_wager_count < _loc1_[15];
         if(_isNormalFree && GlobalFunction.checkWagerTime(0) > 0)
         {
            createTime("time_a");
         }
         else if(_isNormalFree)
         {
            createFree("free_a");
            _mColor = 6475106;
         }
         if(GlobalFunction.checkWagerTime(1) > 0)
         {
            createTime("time_b");
         }
         else
         {
            createFree("free_b");
         }
         if(GlobalFunction.checkWagerTime(1) > 0)
         {
            createTime("time_vip_b");
         }
         else
         {
            createFree("free_vip_b");
         }
      }
      
      private function checkFree() : void
      {
         var _loc1_:Array = GlobalData.$mConfig_simple.wager_avatar as Array;
         _isNormalFree = _userData.records.free_wager_count < _loc1_[15];
         if(mFree_a)
         {
            if(_isNormalFree)
            {
               mFree_a.visible = !mTime_a.visible;
            }
            else
            {
               mFree_a.visible = true;
               mTime_a.visible = false;
            }
         }
         if(mFree_b)
         {
            mFree_b.visible = !mTime_b.visible;
         }
         if(mFree_Vip_b)
         {
            mFree_Vip_b.visible = !mFree_Vip_b.visible;
         }
      }
      
      private function onTRIGGERED_btns(param1:Event) : void
      {
         var _loc3_:LOL_Button = param1.currentTarget as LOL_Button;
         var _loc2_:Boolean = true;
         GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
         if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len && (_loc3_.name == BTN_NAME_CASINO_A || _loc3_.name == BTN_NAME_CASINO_B))
         {
            _loc2_ = false;
            GlobalFunction.popAvatarLen();
            return;
         }
         if(_loc3_.name == BTN_NAME_CASINO_A && _loc2_)
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_casino_A");
            if(GlobalFunction.checkWagerTime(0) > 0)
            {
               GlobalData.$mEventDispatcher.dispatchEventWith("update_casino_A");
            }
            else
            {
               GlobalData.$mEventDispatcher.dispatchEventWith("update_casino_free_A");
            }
         }
         else if(_loc3_.name == BTN_NAME_CASINO_B && _loc2_)
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_casino_B");
            if(GlobalFunction.checkWagerTime(1) > 0)
            {
               GlobalData.$mEventDispatcher.dispatchEventWith("update_casino_B");
            }
            else
            {
               GlobalData.$mEventDispatcher.dispatchEventWith("update_casino_free_B");
            }
         }
         else if(_loc3_.name == BTN_NAME_CASINO_C)
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_exchange");
         }
         else if(_loc3_.name == BTN_NAME_CASINO_D)
         {
            trace("VIP召唤");
         }
      }
      
      private function setShopUI() : void
      {
         delVIPInfoBox();
         var _loc1_:Array = [{
            "name":"center_shop_avatar",
            "title":98120
         },{
            "name":"center_shop_energy",
            "title":98121
         },{
            "name":"center_shop_pvp",
            "title":20098
         },{
            "name":"center_shop_friend",
            "title":98122
         }];
         mList.height = GlobalData.$center_height_curr - 121;
         mList.x = -15;
         mList.y = 130;
         this.setListTimer(mList,_loc1_,ItemShopHelp,false);
         _loc1_ = null;
      }
      
      private function delVIPInfoBox() : void
      {
         checkVIPUI(true);
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
         var _s:Number;
         var _str:String;
         var _expB:Boolean;
         var _isVIPTimeOut:Boolean;
         var _strVIPExp:String;
         var _clear:Boolean = param1;
         var _isMoney:Boolean = param2;
         var _isNoPayList:Boolean = param3;
         delCasinoUI();
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
            _t9x9 = new Scale9Textures(GlobalFunction.getTexture("UI_bg_9slice_5_0000"),new Rectangle(30,30,50,50));
            _bg = new Scale9Image(_t9x9);
            _bg.width = 616;
            _bg.height = 105;
            _bg.x = int((GlobalData.$mStageWidth - _bg.width) * 0.5);
            _bg.y = 10;
            mBox_info.addChild(_bg);
            mBox_info.y = mListY;
            this.addChild(mBox_info);
            mBox_info.visible = GlobalFunction.checkIOSvip();
            _rec = null;
            _rec2 = null;
            _s = GlobalFunction.getVIPTimeS();
            _str = Tools.timeFormatAll(_s,false);
            mTxt_VIPtime = GlobalTextStyle.getHtmlTextRenderer();
            _expB = true;
            _isVIPTimeOut = false;
            if(this.mTabBar.selectedIndex == 2)
            {
               mTxt_VIPtime.text = Tools.formatHtmlTextBr([Tools.formatLineX((GlobalFunction.getVipLv() > 0 && _s <= 0 ? GlobalLanguageStr.getLanguageStr(98131) : GlobalLanguageStr.getLanguageStr(20190,GlobalFunction.getVIPTimeTxt())),GlobalTextStyle.COLOR_W_R_R_Y,1000,20)],"center");
               if(_s <= 0)
               {
                  mTxt_VIPtime.y = 40;
               }
               else
               {
                  mTxt_VIPtime.y = _bg.x + 15;
               }
               if(GlobalFunction.getVipLv() <= 0)
               {
                  mTxt_VIPtime.text = Tools.formatHtmlTextBr([Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20200),GlobalTextStyle.COLOR_W_R_R_Y,20,20)],"center");
                  mTxt_VIPtime.y = 40;
                  _expB = false;
               }
            }
            else if(GlobalFunction.getVipLv() > 0)
            {
               if(GlobalFunction.isInVipTime())
               {
                  mTxt_VIPtime.text = Tools.formatHtmlTextBr([Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20318),GlobalTextStyle.COLOR_W_R_R_Y,21,20)],"center");
                  mTxt_VIPtime.y = _bg.y + 15;
                  if(_itemArr.length == 0)
                  {
                     mTxt_VIPtime.text = Tools.formatHtmlTextBr([Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20491),GlobalTextStyle.COLOR_W_R_R_Y,MainConfig.$isEA ? 40 : 21,20)],"center");
                     mTxt_VIPtime.y = 40;
                  }
               }
               else
               {
                  mTxt_VIPtime.text = Tools.formatHtmlTextBr([Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20318),GlobalTextStyle.COLOR_W_R_R_Y,21,20)],"center");
                  mTxt_VIPtime.y = 15 + 10;
                  _isVIPTimeOut = true;
               }
            }
            else
            {
               mTxt_VIPtime.text = Tools.formatHtmlTextBr([Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20200),GlobalTextStyle.COLOR_W_R_R_Y,21,20)],"center");
               mTxt_VIPtime.y = 40;
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
                  _strVIPExp = _isVIPTimeOut ? GlobalLanguageStr.getLanguageStr(90117) : GlobalLanguageStr.getLanguageStr(20201,GlobalFunction.getVipRate());
                  mTxt_VIPExp.text = Tools.formatHtmlTextBr([Tools.formatLineX(_strVIPExp,GlobalTextStyle.COLOR_W_W_R_Y,80,20)],"center");
                  mTxt_VIPExp.y = mTxt_VIPtime.y + 35;
               }
               else
               {
                  _strVIPExp = GlobalLanguageStr.getLanguageStr(20319);
                  mTxt_VIPExp.text = Tools.formatHtmlTextBr([Tools.formatLineX(_strVIPExp,GlobalTextStyle.COLOR_W_W_R_Y,80,MainConfig.$isEnglish ? 19 : 20)],"center");
                  if(_itemArr.length == 0)
                  {
                     mTxt_VIPExp.text = "";
                  }
                  if(MainConfig.$isEA)
                  {
                     mTxt_VIPExp.y = mTxt_VIPtime.y + 29;
                  }
                  else
                  {
                     mTxt_VIPExp.y = mTxt_VIPtime.y + 35;
                  }
               }
               mTxt_VIPExp.mLayoutFun = function():void
               {
                  _rec = mTxt_VIPExp.getTextSnapshotFrame();
                  mTxt_VIPExp.x = int((GlobalData.$mStageWidth - _rec.width) * 0.5);
               };
               mBox_info.addChild(mTxt_VIPExp);
               if(_s <= 0)
               {
                  mTxt_VIPExp.visible = false;
                  mTxt_VIPtime.text = Tools.formatHtmlTextBr([Tools.formatLineX((GlobalFunction.getVipLv() > 0 && _s <= 0 ? GlobalLanguageStr.getLanguageStr(98131) : GlobalLanguageStr.getLanguageStr(20190,GlobalFunction.getVIPTimeTxt())),GlobalTextStyle.COLOR_W_R_R_Y,20,20)],"center");
                  mTxt_VIPtime.y = 40;
               }
            }
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
      
      public function onSCROLL(param1:Event) : void
      {
         (mList.viewPort as Sprite).sortChildren(sortVIPListFun);
      }
      
      public function sortVIPListFun(param1:DisplayObject, param2:DisplayObject) : int
      {
         return param1.y < param2.y ? 0 : 1;
      }
   }
}


