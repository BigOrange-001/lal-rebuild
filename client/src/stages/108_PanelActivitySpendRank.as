package com.meng52.game.ui.panel
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.map.GameMapTools;
   import com.meng52.game.ui.element.ItemActivitySpendRankAward;
   import com.meng52.game.ui.element.LOL_HtmlText;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.element.LOL_TimeStatus;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.filters.BlurFilter;
   import starling.filters.ColorMatrixFilter;
   import starling.filters.FragmentFilter;
   import starling.text.TextField;
   
   public class PanelActivitySpendRank extends PanelActivityRoulette
   {
      
      private static const BTN_NAME_INFO:String = "btn_name_info";
      
      private static const BTN_NAME_RANK:String = "btn_name_rank";
      
      public static var $mCoinNum:int = 0;
      
      public static var $rank_list:Array;
      
      private static const UI_WIDTH_BY_TIMES:Array = [{
         "min":0,
         "max":105,
         "xx":95
      },{
         "min":105,
         "max":270,
         "xx":260
      },{
         "min":270,
         "max":438,
         "xx":428
      },{
         "min":438,
         "max":610,
         "xx":590
      }];
      
      private var mTxt_time:TextField;
      
      private var mBtn_info:LOL_Scale9Button;
      
      private var mBtn_rank:LOL_Scale9Button;
      
      private var mBox:Sprite;
      
      private var mTxt_info:TextFieldHtmlRenderer;
      
      private var mTxt_myPay:TextField;
      
      private var mTxt_tips:LOL_HtmlText;
      
      private var mTxt_myRank:TextField;
      
      private var m9x9_bg:Scale9Image;
      
      private var mImg_myPay:Image;
      
      private var mAImg:Image;
      
      private var _timer:LOL_TimeStatus;
      
      private var _awardOver:Boolean = check_awardIsOver();
      
      public function PanelActivitySpendRank()
      {
         super();
      }
      
      public static function check_listHadMe() : int
      {
         var _loc4_:int = 0;
         var _loc2_:int = 0;
         var _loc3_:Object = null;
         var _loc1_:int = -1;
         if($rank_list)
         {
            _loc4_ = 0;
            _loc2_ = int($rank_list.length);
            if(_loc2_ > 0)
            {
               _loc3_ = null;
               _loc4_ = 0;
               while(_loc4_ < _loc2_)
               {
                  _loc3_ = $rank_list[_loc4_];
                  if(_loc3_.uid == GlobalData.$userData.uid && GlobalData.$mServiceID == _loc3_.zone)
                  {
                     _loc1_ = _loc4_ + 1;
                     break;
                  }
                  _loc4_++;
               }
            }
         }
         return _loc1_;
      }
      
      public static function check_awardIsOver() : Boolean
      {
         var _loc2_:Boolean = true;
         var _loc1_:Object = GlobalData.$mConfig_ploy_system_simple.spend_rank;
         var _loc3_:Array = GlobalData.$userData.attrs.spend_rank.fixed_gift;
         var _loc4_:Object = _loc1_.fixed_gift;
         var _loc5_:Object = null;
         if(_loc3_.length <= 0)
         {
            _loc2_ = false;
         }
         else
         {
            for(_loc5_ in _loc4_)
            {
               if(_loc3_.indexOf(int(_loc5_)) < 0)
               {
                  _loc2_ = false;
                  break;
               }
            }
         }
         return _loc2_;
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalData.$mEventDispatcher.removeEventListener("update_activity_fun_SpendRank",onMainEvent);
         if(mTxt_tips)
         {
            mTxt_tips.removeFromParent(true);
         }
         if(mBtn_info)
         {
            mBtn_info.removeFromParent(true);
         }
         if(mTxt_info)
         {
            mTxt_info.removeFromParent(true);
         }
         if(mBtn_rank)
         {
            mBtn_rank.removeFromParent(true);
         }
         if(mTxt_myPay)
         {
            mTxt_myPay.removeFromParent(true);
         }
         if(mTxt_myRank)
         {
            mTxt_myRank.removeFromParent(true);
         }
         if(m9x9_bg)
         {
            m9x9_bg.removeFromParent(true);
         }
         if(mImg_myPay)
         {
            mImg_myPay.removeFromParent(true);
         }
         if(mAImg)
         {
            mAImg.removeFromParent(true);
         }
         if(_timer)
         {
            _timer.removeFromParent(true);
         }
         delUI_award();
         delBaseUI();
         _timer = null;
         mAImg = null;
         mTxt_tips = null;
         mImg_myPay = null;
         m9x9_bg = null;
         m9x9_bg = null;
         mTxt_myRank = null;
         mTxt_myPay = null;
         mBtn_rank = null;
         mBtn_info = null;
         mTxt_info = null;
         GlobalFunction.delTextureByBD("png_activity_bg");
         GlobalFunction.delTextureByBD("UI_spend_rank_bar");
         GlobalFunction.delTextureByBD("UI_roulette_bar_bg");
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         removeEventListener("addedToStage",initializeHandler);
         SendServiceAMFFun.send_user_get_consume_ranks(re_user_get_consume_ranks);
      }
      
      private function re_user_get_consume_ranks(param1:Object) : void
      {
         if(stage == null)
         {
            return;
         }
         var _loc2_:Object = param1.data;
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.spend_rank.fixed_gift = _loc2_.fixed_gift;
         }
         $mCoinNum = _loc2_.my_coin_num;
         $rank_list = _loc2_.rank_list;
         setUIs();
      }
      
      private function setUIs() : void
      {
         var _isOver:Boolean;
         var _cfg:Object;
         var _startMS:Number;
         var _currMS:Number;
         var _endMS:Number;
         var _win:Boolean;
         var _awardOver:Boolean;
         var cmf:ColorMatrixFilter;
         var _myIndex:int;
         var _bg:Image;
         var _str:String;
         var _rec:Rectangle;
         var _centerX:Number;
         var _txt_coin:LOL_MutilTextFieldIcon;
         var _gift:Object;
         var i:Object;
         var _data:Object;
         var _arr:Array;
         var _num:int;
         var l:int;
         var j:int;
         var _coinMAX:Number;
         var _strRank:String;
         var _lastS:Number;
         var bgW:* = function(param1:int):void
         {
            _timer.x = 20;
         };
         GlobalData.$mEventDispatcher.addEventListener("update_activity_fun_SpendRank",onMainEvent);
         _isOver = false;
         _cfg = GlobalData.$mConfig_ploy_system_simple.spend_rank;
         _startMS = (_cfg.start_time as Date).time;
         _currMS = SendAndSelect.$systemTimer_nowSecond * 1000;
         _endMS = _startMS + _cfg.duration * 60 * 1000;
         _win = false;
         _awardOver = check_awardIsOver();
         if(_currMS >= _endMS)
         {
            _isOver = true;
         }
         cmf = new ColorMatrixFilter();
         cmf.adjustBrightness(-0.2);
         cmf.adjustContrast(0.6);
         cmf.adjustSaturation(0.5);
         cmf.adjustHue(int(_cfg.hue) / 180);
         _myIndex = check_listHadMe();
         _bg = GlobalFunction.createImage("png_activity_bg",true);
         _bg.filter = cmf;
         _bg.y = int((GlobalData.$center_height_curr - 121 - _bg.height) * 0.5);
         addChild(_bg);
         m9x9_bg = GlobalFunction.createScale9Image("UI_bg_9slice_5_0000",616,120,new Rectangle(30,20,50,30));
         m9x9_bg.x = int((GlobalData.$mStageWidth - m9x9_bg.width) * 0.5);
         m9x9_bg.y = GlobalData.$center_height_curr - 121 - m9x9_bg.height;
         addChild(m9x9_bg);
         mAImg = GameMapTools.newAvatarImgById(_cfg.show_avatar);
         mAImg.pivotX = mAImg.width / 2;
         mAImg.pivotY = mAImg.height / 2;
         mAImg.scaleX = mAImg.scaleY = 1.3;
         mAImg.x = GlobalData.$mStageWidth * 0.5;
         mAImg.y = (GlobalData.$center_height_curr - 121) * 0.5 - 20;
         addChild(mAImg);
         _str = GlobalLanguageStr.getLanguageStr(90273);
         mTxt_info = GlobalTextStyle.getHtmlTextRenderer();
         mTxt_info.text = Tools.formatLineX(_str,GlobalTextStyle.COLOR_F_FFCC66,MainConfig.$isEA ? 36 : 26,MainConfig.$isEA ? 16 : 20);
         mTxt_info.mLayoutFun = function():void
         {
            _rec = mTxt_info.getTextSnapshotFrame();
            mTxt_info.x = m9x9_bg.x + int((m9x9_bg.width - _rec.width) * 0.5);
            mTxt_info.y = m9x9_bg.y + int((m9x9_bg.height - _rec.height) * 0.5);
         };
         addChild(mTxt_info);
         mImg_myPay = GlobalFunction.createImage("UI_roulette_t_bg_0000");
         mImg_myPay.x = int((GlobalData.$mStageWidth - mImg_myPay.width) * 0.5);
         mImg_myPay.y = m9x9_bg.y - mImg_myPay.height;
         addChild(mImg_myPay);
         _centerX = int(GlobalData.$mStageWidth * 0.5);
         mBtn_info = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90259),150,70,"UI_btn_normalFun_0000");
         mBtn_info.name = "btn_name_info";
         if(MainConfig.$isEA)
         {
            mBtn_info.fontSize = 17;
         }
         mBtn_rank = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20469),150,70,"UI_btn_normalFun_0000");
         mBtn_rank.name = "btn_name_rank";
         if(MainConfig.$isEA)
         {
            mBtn_rank.fontSize = 23;
         }
         mBtn_info.x = mImg_myPay.x - mBtn_info.width + 10;
         mBtn_rank.x = mImg_myPay.x + mImg_myPay.width - 10;
         mBtn_info.y = m9x9_bg.y - mBtn_info.height;
         mBtn_rank.y = mBtn_info.y;
         addChild(mBtn_info);
         addChild(mBtn_rank);
         mBtn_info.addEventListener("triggered",onTRIGGERED_list);
         mBtn_rank.addEventListener("triggered",onTRIGGERED_list);
         mTxt_myPay = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20470,$mCoinNum),20,1513239,"center",mImg_myPay.width,35);
         mTxt_myPay.x = mImg_myPay.x;
         mTxt_myPay.y = mImg_myPay.y;
         _txt_coin = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getLanguageStr(20501),$mCoinNum + "","UI_money_coin_0_0000",1513239,1513239);
         _txt_coin.pivotX = _txt_coin.width / 2;
         _txt_coin.pivotY = _txt_coin.height / 2;
         _txt_coin.x = mImg_myPay.x + 168;
         _txt_coin.y = mImg_myPay.y + 20;
         addChild(_txt_coin);
         _gift = mFixed_gift = _cfg.fixed_gift;
         i = null;
         _data = null;
         _arr = [];
         _num = 0;
         for(i in _gift)
         {
            _data = {};
            _data["gift"] = _gift[i];
            _data["id"] = i.toString();
            _arr.push(_data);
         }
         _arr.sortOn("id",16);
         if(mArr_fixed_gift == null)
         {
            mArr_fixed_gift = [];
            j = 0;
            l = int(_arr.length);
            _data = null;
            j = 0;
            while(j < l)
            {
               _data = {};
               _data["id"] = j;
               _data["min"] = j - 1 >= 0 ? int(_arr[j - 1]["id"]) + 1 : 0;
               _data["max"] = int(_arr[j]["id"]);
               mArr_fixed_gift.push(_data);
               j = j + 1;
            }
         }
         _coinMAX = Number(mArr_fixed_gift[mArr_fixed_gift.length - 1]["max"]);
         if($mCoinNum < _coinMAX)
         {
            mBtn_rank.enabled = false;
         }
         else
         {
            _win = true;
         }
         _strRank = "";
         mTxt_myRank = GlobalTextStyle.getTextField("",20,16777215,"center",mImg_myPay.width,35);
         mTxt_myRank.name = "trueShow";
         mTxt_myRank.x = mTxt_myPay.x;
         mTxt_myRank.y = mTxt_myPay.y - 30;
         addChild(mTxt_myRank);
         _lastS = _endMS - _currMS;
         _lastS = _lastS < 0 ? 0 : _lastS;
         if(_isOver)
         {
            _timer = new LOL_TimeStatus("panelspendrank",bgW);
            _timer.refresh(0,GlobalLanguageStr.getLanguageStr(20476));
            if(_win)
            {
               if(_myIndex > -1)
               {
                  _strRank = GlobalLanguageStr.getLanguageStr(20471,_myIndex);
               }
               else
               {
                  _strRank = GlobalLanguageStr.getLanguageStr(20486);
               }
            }
            else
            {
               mTxt_myRank.name = "falseShow";
            }
            setTimeOverNoHasAwardAll();
         }
         else
         {
            if(_myIndex > -1)
            {
               _strRank = GlobalLanguageStr.getLanguageStr(20471,_myIndex);
            }
            else
            {
               _strRank = GlobalLanguageStr.getLanguageStr(20471,GlobalLanguageStr.getLanguageStr(20486));
            }
            _timer = new LOL_TimeStatus("panelspendrank",bgW);
            _timer.refresh(_lastS * 0.001,GlobalLanguageStr.getLanguageStr(20476),"",timer_Tick);
         }
         mTxt_myRank.text = _strRank;
         _timer.filter = GlobalFunction.getShadowFilters();
         _timer.y = 140;
         addChild(_timer);
         if(!(_isOver || _awardOver))
         {
            mBox_ui = new Sprite();
            addChild(mBox_ui);
            mBox_bar = new Sprite();
            mBox_bar.touchable = false;
            mImg_bar = GlobalFunction.createImage("UI_roulette_bar",true);
            mRec_bar = new Rectangle(0,0,mImg_bar.width,mImg_bar.height);
            mBox_bar.addChild(mImg_bar);
            mBox_bar.clipRect = mRec_bar;
            mBox_ui.addChild(mBox_bar);
            mImg_barBg = GlobalFunction.createImage("UI_roulette_bar_bg",true);
            mBox_ui.addChild(mImg_barBg);
            mImg_barBg.x = int((GlobalData.$mStageWidth - mImg_barBg.width) * 0.5);
            mImg_barBg.y = mBtn_info.y - mImg_barBg.height - 15;
            mBox_bar.x = mImg_barBg.x + 2;
            mBox_bar.y = mImg_barBg.y + 2;
            upDateProgress();
         }
      }
      
      private function timer_Tick() : void
      {
         if(mBox_ui)
         {
            mBox_ui.visible = false;
         }
         if(mBox_bar)
         {
            mBox_bar.visible = false;
         }
         if(mImg_barBg)
         {
            mImg_barBg.visible = false;
         }
         setTimeOverNoHasAwardAll();
      }
      
      private function setTimeOverNoHasAwardAll() : void
      {
         var _loc1_:FragmentFilter = null;
         if(!_awardOver)
         {
            _loc1_ = BlurFilter.createDropShadow(3,0.785,0,1,0);
            mTxt_tips = new LOL_HtmlText(GlobalData.$mStageWidth,100,20,16777215,false,"center");
            mTxt_tips.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90336),null,25);
            mTxt_tips.filter = _loc1_;
            mTxt_tips.y = mBtn_info.y - 100;
            addChild(mTxt_tips);
            if(mBox_ui)
            {
               mBox_ui.visible = false;
            }
            if(mBox_bar)
            {
               mBox_bar.visible = false;
            }
            if(mImg_barBg)
            {
               mImg_barBg.visible = false;
            }
         }
      }
      
      override protected function upDateProgress() : void
      {
         var _loc6_:ItemActivitySpendRankAward = null;
         mData_curr = $mCoinNum;
         var _loc7_:int = 0;
         var _loc4_:int = int(mArr_fixed_gift.length);
         var _loc13_:Object = null;
         var _loc3_:* = -1;
         _loc13_ = mArr_fixed_gift[_loc4_ - 1];
         var _loc9_:int = int(_loc13_.max);
         mData_curr = mData_curr >= _loc9_ ? _loc9_ : mData_curr;
         mData_times = Math.ceil(mData_curr / _loc9_);
         var _loc11_:Number = mData_curr % _loc13_.max;
         _loc7_ = 0;
         while(_loc7_ < _loc4_)
         {
            _loc13_ = mArr_fixed_gift[_loc7_];
            if(_loc11_ >= _loc13_.min && _loc11_ <= _loc13_.max)
            {
               _loc3_ = _loc7_;
               break;
            }
            _loc7_++;
         }
         var _loc5_:Object = UI_WIDTH_BY_TIMES[_loc3_];
         var _loc2_:Number = Number(_loc5_["min"]);
         var _loc1_:Number = Number(_loc5_["max"]);
         _loc13_ = mArr_fixed_gift[_loc3_];
         var _loc10_:Number = _loc13_.max - (_loc13_.min > 0 ? _loc13_.min + 1 : 0);
         var _loc8_:Number = (_loc1_ - _loc2_) / _loc10_;
         var _loc12_:Number = Number(mData_curr >= _loc9_ ? UI_WIDTH_BY_TIMES[_loc4_ - 1]["max"] : _loc2_ + _loc8_ * (_loc11_ - (_loc13_.min > 0 ? _loc13_.min + 1 : 0)));
         mRec_bar.width = _loc12_;
         mBox_bar.clipRect = mRec_bar;
         if(mBox_itemAward == null)
         {
            mArr_itemAward = [];
            mBox_itemAward = new Sprite();
            mBox_ui.addChild(mBox_itemAward);
            _loc7_ = 0;
            while(_loc7_ < _loc4_)
            {
               _loc6_ = new ItemActivitySpendRankAward(mArr_fixed_gift[_loc7_],20484);
               _loc6_.x = UI_WIDTH_BY_TIMES[_loc7_].xx - 2;
               _loc6_.y = mImg_barBg.y + 63;
               mBox_itemAward.addChild(_loc6_);
               mArr_itemAward.push(_loc6_);
               _loc7_++;
            }
         }
         _loc7_ = 0;
         while(_loc7_ < _loc4_)
         {
            _loc6_ = mArr_itemAward[_loc7_];
            _loc6_.check_num(mData_times,mData_curr,_loc9_);
            _loc7_++;
         }
      }
      
      private function onTRIGGERED_list(param1:Event) : void
      {
         var _loc2_:Number = NaN;
         var _loc3_:LOL_Scale9Button = param1.target as LOL_Scale9Button;
         if(_loc3_.name == "btn_name_info")
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_spend_rank_info",false,true);
         }
         else if(_loc3_.name == "btn_name_rank")
         {
            if(_loc3_.enabled)
            {
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_spend_rank_list",false,true);
            }
            else
            {
               _loc2_ = Number(mArr_fixed_gift[mArr_fixed_gift.length - 1]["max"]);
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90274,_loc2_));
            }
         }
      }
      
      override protected function onMainEvent(param1:Event) : void
      {
         mCurr_data = param1.data;
         if(mCurr_data.num > 0)
         {
            if($mCoinNum >= mCurr_data.data.max)
            {
               setUI_award();
            }
            else
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90278));
            }
         }
         else if($mCoinNum >= mCurr_data.data.max)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90278));
         }
         else
         {
            setUI_award();
         }
      }
      
      override protected function onTRIGGERED_award(param1:Event) : void
      {
         if(mCurr_data.num > 0)
         {
            if(awardNum != null && awardNum[0] == 1 && Tools.getElementNum(GlobalData.$userData.avatars) >= GlobalData.$userData.attrs.avatar_len)
            {
               GlobalFunction.popAvatarLen();
            }
            else if(awardNum != null && awardNum[1] == 1 && Tools.getElementNum(GlobalData.$userData.my_equips) >= int(GlobalData.$mConfig_simple.equip_config[0]))
            {
               GlobalFunction.popEquipFull();
            }
            else
            {
               SendServiceAMFFun.send_user_get_spend_fixed_gift(reService_award,{"key":mCurr_data.data.max});
            }
         }
         else
         {
            delUI_award();
         }
      }
      
      override protected function reService_award(param1:Object) : void
      {
         if(stage == null)
         {
            return;
         }
         var _loc6_:Object = null;
         var _loc4_:Object = null;
         var _loc11_:String = "sound03";
         SoundManager.getOnlyExample().playSound(_loc11_);
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.gold = param1.data.gold;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.medal = param1.data.medal;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.sp = param1.data.sp;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.dust = param1.data.dust;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.energy = param1.data.energy;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.energy_extra = param1.data.attr_energy_extra;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.avatars = param1.data.avatars;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.my_equips = param1.data.my_equips;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.avatar_soul = param1.data.avatar_soul;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.equip_soul = param1.data.equip_soul;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.culture_book = param1.data.culture_book;
         }
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateEn();
         var _loc2_:Object = GlobalData.$mConfig_ploy_system_simple.spend_rank;
         var _loc10_:Object = _loc2_.fixed_gift;
         var _loc9_:Object = _loc10_[mCurr_data.data.max];
         var _loc3_:Object = null;
         var _loc8_:Object = null;
         var _loc7_:String = "";
         var _loc5_:Object = null;
         for(_loc8_ in _loc9_)
         {
            _loc7_ = _loc8_.toString();
            if(_loc7_ == "equip" || _loc7_ == "avatar")
            {
               _loc5_ = _loc9_[_loc8_];
               for(_loc6_ in _loc5_)
               {
                  _loc4_ = {};
                  _loc4_[_loc6_] = _loc5_[_loc6_];
                  _loc3_ = GlobalFunction.getAwardByType(_loc7_,_loc4_);
                  GlobalFunction.popAward(_loc7_,GlobalLanguageStr.getLanguageStr(90062,_loc3_.msg),_loc4_,false);
               }
            }
            else
            {
               _loc3_ = GlobalFunction.getAwardByType(_loc7_,_loc9_[_loc8_]);
               GlobalFunction.popAward(_loc7_,GlobalLanguageStr.getLanguageStr(90062,_loc3_.msg),_loc9_[_loc8_],false);
            }
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.spend_rank.fixed_gift.push(mCurr_data.data.max);
         }
         delUI_award();
         upDateProgress();
      }
   }
}

