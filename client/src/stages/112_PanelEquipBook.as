package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.equip.Equip;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.element.ItemEquip;
   import com.meng52.game.ui.element.ItemEquipBook;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelCenterMainAvatar;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import feathers.display.Scale9Image;
   import feathers.textures.Scale9Textures;
   import flash.geom.Rectangle;
   import starling.animation.Juggler;
   import starling.display.Image;
   import starling.display.MovieClip;
   import starling.display.Sprite;
   import starling.events.EnterFrameEvent;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.extensions.ColorArgb;
   import starling.extensions.PDParticleSystem;
   import starling.text.TextField;
   
   public class PanelEquipBook extends PanelCenterMainAvatar
   {
      
      public static var $selectType:int = 0;
      
      private var mTxt_title:TextField;
      
      private var mTxt_p:TextField;
      
      private var mTxt_gold:LOL_MutilTextFieldIcon;
      
      private var mBtn_clear:LOL_Scale9Button;
      
      private var mCost_gold:Number = 0;
      
      private var mJuggler_food:Juggler;
      
      private var mMC_book:MovieClip;
      
      private var mTimer_book:Number = 0;
      
      private var mClip_status:int = 0;
      
      protected var mCurrEquip:ItemEquip;
      
      protected var mImg_label:Image;
      
      protected var mBtn_price:LOL_Scale9Button;
      
      protected var mBtn_to:LOL_Scale9Button;
      
      protected var mBox_dataUp:Sprite;
      
      protected var mPrice_num:int = 0;
      
      protected var mCurr_lv:int = 0;
      
      protected var mT_9x9:Scale9Textures;
      
      protected var mImg9_base:Scale9Image;
      
      protected var mImg9_new:Scale9Image;
      
      protected var mStatus_up:Boolean = false;
      
      protected var mSpr_:Sprite;
      
      protected var mClip_pause:Number;
      
      protected var mJuggler_upLv:Juggler;
      
      protected var mParticleSystem:PDParticleSystem;
      
      public var mBox_data:Sprite;
      
      public var mBox_team:Sprite;
      
      public var mBg_team:Image;
      
      public var mBg_data:Image;
      
      public var mArr_team:Array;
      
      public var mRuler_item:Number = 0;
      
      public var mBox_equip:Sprite;
      
      private var mBtn_help:LOL_Button;
      
      private var _spRule:Sprite;
      
      public function PanelEquipBook()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(20267) + GlobalLanguageStr.getLanguageStr(20406));
         this.initOtherUIs();
      }
      
      override public function onTRIGGERED_closePanel(param1:Event) : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.reSetLastPanel_ID();
         GlobalData.$mEventDispatcher.dispatchEventWith("update_equip_list_data");
         super.onTRIGGERED_closePanel(null);
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         delmMC_book();
         if(mJuggler_food)
         {
            mJuggler_food.purge();
         }
         if(mBtn_clear)
         {
            mBtn_clear.removeFromParent(true);
         }
         if(mTxt_gold)
         {
            mTxt_gold.removeFromParent(true);
         }
         if(mTxt_p)
         {
            mTxt_p.removeFromParent(true);
         }
         if(mTxt_title)
         {
            mTxt_title.removeFromParent(true);
         }
         if(_spRule)
         {
            _spRule.removeEventListener("touch",onTRIGGERED_help);
         }
         super.onREMOVED_FROM_STAGE(param1);
         mTxt_title = null;
         mTxt_p = null;
         mTxt_gold = null;
         mBtn_clear = null;
         mJuggler_food = null;
         if(mBtn_help)
         {
            mBtn_help.removeFromParent(true);
         }
         mBtn_help = null;
         GlobalData.$tempEquipCurrSelected = "";
      }
      
      public function initOtherUIs() : void
      {
         mPrice_num = 0;
         mCurr_lv = 0;
         mJuggler_upLv = new Juggler();
         addEventListener("enterFrame",onENTER_FRAME_clip);
         mBox_equip = new Sprite();
         mBox_equip.x = 70;
         mBox_equip.y = 112;
         addChild(mBox_equip);
         var _loc10_:Object = GlobalData.$userData.my_equips[GlobalData.$tempEquipCurrSelected];
         var _loc9_:Boolean = _loc10_ != null;
         _loc10_ = _loc10_ == null ? {} : _loc10_;
         _loc10_["status"] = -1;
         _loc10_["score"] = _loc9_;
         _loc10_["id"] = _loc10_ == null ? null : GlobalData.$tempEquipCurrSelected;
         mCurrEquip = new ItemEquip();
         mCurrEquip.data = _loc10_;
         mBox_equip.addChild(mCurrEquip);
         if(!_loc9_)
         {
            setChangeStatusUI();
            return;
         }
         mImg9_base = GlobalFunction.createScale9Image("UI_bg_9slice_7_0000",575,270,new Rectangle(25,25,10,10));
         mImg9_base.x = -38;
         mImg9_base.y = 190;
         mBox_equip.addChild(mImg9_base);
         var _loc8_:Number = 280;
         mTxt_title = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20407),20,16777215,"left",_loc8_,35);
         var _loc7_:Number = GlobalFunction.getEquipBookUpP(GlobalData.$tempFoodForBook,GlobalData.$tempEquipCurrSelected);
         var _loc4_:String = _loc7_ > 0 ? int(_loc7_ * 100) + "%" : "0";
         mTxt_p = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20408,_loc4_),20,16777215,"left",_loc8_,35);
         var _loc3_:String = GlobalData.$tempEquipCurrSelected;
         var _loc1_:Object = GlobalData.$userData.my_equips[_loc3_];
         var _loc6_:Equip = null;
         if(_loc1_ != null)
         {
            _loc6_ = new Equip(_loc3_,_loc1_);
         }
         mCost_gold = _loc1_ != null && GlobalData.$tempFoodForBook.length > 0 ? _loc6_.getBookUpGold() : 0;
         mTxt_gold = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getStr(90444),mCost_gold > 0 ? String(mCost_gold) : "0","UI_money_gold_0_0000");
         mBox_equip.addChild(mTxt_title);
         mBox_equip.addChild(mTxt_p);
         mBox_equip.addChild(mTxt_gold);
         _loc6_.clear();
         mTxt_title.x = mImg9_base.x + 20;
         mTxt_title.y = mImg9_base.y + 20;
         mTxt_p.x = mTxt_title.x + 10;
         mTxt_p.y = mImg9_base.y + mImg9_base.height - 35 - 25;
         mTxt_gold.x = MainConfig.$isEA ? int(mImg9_base.x + mImg9_base.width * 0.5) + 28 : int(mImg9_base.x + mImg9_base.width * 0.5 + 118) - 70;
         mTxt_gold.y = MainConfig.$isEA ? mTxt_p.y - 5 : mTxt_p.y + 3;
         mBox_data = new Sprite();
         mBox_data.touchable = false;
         mBox_data.x = 125;
         mBox_equip.addChild(mBox_data);
         setTxt(mBox_data);
         setFood();
         mBtn_to = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20406),150,70,"UI_btn_normalFun_0000");
         mBtn_to.shadowFilter();
         mBtn_to.addEventListener("triggered",onTRIGGERED_book);
         addChild(mBtn_to);
         var _loc2_:Number = int(GlobalData.$mStageWidth * 0.5);
         mBtn_to.x = _loc2_ + 20;
         mBtn_to.y = _height - mBtn_to.height - 75;
         mBtn_clear = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20228),150,70,"UI_btn_normalFun_0000",true,false);
         mBtn_clear.shadowFilter();
         mBtn_clear.addEventListener("triggered",onTRIGGERED_select);
         addChild(mBtn_clear);
         mBtn_clear.x = _loc2_ - mBtn_clear.width - 20;
         mBtn_clear.y = mBtn_to.y;
         checkBtn_selectStatus();
         mJuggler_food = new Juggler();
         var _loc5_:Object = GlobalFunction.get_HelpLink(GlobalLanguageStr.getLanguageStr(90519));
         _spRule = _loc5_.ui;
         _spRule.x = _width - _loc5_.w - 40;
         _spRule.y = 88;
         addChild(_spRule);
         _spRule.addEventListener("touch",onTRIGGERED_help);
         GlobalData.$mEventDispatcher.addEventListener("update_book_selected_data",UPDATE_BOOK_SELECTED_DATA);
      }
      
      private function onTRIGGERED_help(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(_spRule);
         if(_loc2_)
         {
            if(_loc2_.phase == "ended")
            {
               GlobalFunction.popPanelHelp(MainConfig.SERVER_ADDRESS_HELP_ADD_BOOK);
            }
         }
      }
      
      private function UPDATE_BOOK_SELECTED_DATA(param1:Event) : void
      {
         checkBtn_selectStatus();
         setFood();
      }
      
      protected function onENTER_FRAME_clip(param1:EnterFrameEvent) : void
      {
         if(mJuggler_food)
         {
            mJuggler_food.advanceTime(param1.passedTime);
            if(mMC_book && mClip_status == 0)
            {
               mTimer_book += 1;
               if(mTimer_book > 40)
               {
                  delmMC_book();
                  mClip_status = 1;
               }
            }
            else if(mClip_status == 1)
            {
               mClip_status = 2;
               setFood(true);
            }
         }
      }
      
      protected function setChangeStatusUI() : void
      {
         var _loc2_:ColorArgb = null;
         var _loc1_:ColorArgb = null;
         if(mBox_equip)
         {
            mBox_equip.x = int((GlobalData.$mStageWidth - 100) * 0.5);
            mBox_equip.y = int((GlobalData.$center_height_curr - 121 - 100) * 0.5);
            mParticleSystem = new PDParticleSystem(GlobalData.$assetManager.getXml("drugs"),GlobalFunction.getTexture("drugs_particle"));
            mParticleSystem.x = 50;
            mParticleSystem.y = 50;
            _loc2_ = ColorArgb.fromArgb(26112);
            _loc1_ = ColorArgb.fromArgb(16776960);
            mParticleSystem.startColor = new ColorArgb(_loc2_.red,_loc2_.green,_loc2_.blue,0.76);
            mParticleSystem.startColorVariance = new ColorArgb(_loc2_.red,_loc2_.green,_loc2_.blue,0.08);
            mParticleSystem.endColor = new ColorArgb(_loc1_.red,_loc1_.green,_loc1_.blue,0.2);
            mBox_equip.addChildAt(mParticleSystem,0);
            mJuggler_upLv.add(mParticleSystem);
            mParticleSystem.start();
         }
      }
      
      private function onTRIGGERED_book(param1:Event) : void
      {
         var _loc3_:LOL_Scale9Button = null;
         var _loc2_:Object = null;
         if(GlobalData.$tempFoodForBook.length > 0 && GlobalData.$tempEquipCurrSelected != "" && GlobalData.$tempEquipCurrSelected.indexOf("e") > -1)
         {
            _loc3_ = param1.currentTarget as LOL_Scale9Button;
            if(_loc3_.enabled)
            {
               if(this.mCost_gold > GlobalData.$userData.gold)
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10023),false,"A_6999_3");
               }
               else
               {
                  _loc2_ = {
                     "eqid":GlobalData.$tempEquipCurrSelected,
                     "eqids":GlobalData.$tempFoodForBook
                  };
                  var _bookEqid:String = String(GlobalData.$tempEquipCurrSelected);
                  var _bookFoodIds:Array = (_loc2_["eqids"] as Array).concat();
                  var _bookOldData:Object = GlobalData.$userData.my_equips[_bookEqid];
                  var _bookOldSlv:int = _bookOldData == null ? 0 : new Equip(_bookEqid,_bookOldData).slv;
                  var _bookOwner:PanelEquipBook = this;
                  SendServiceAMFFun.send_user_swallow_skillbook(function(_receipt:Object):void
                  {
                     _bookOwner.re_bookUP(_receipt,_bookOldSlv,_bookEqid,_bookFoodIds);
                  },_loc2_);
               }
            }
         }
         else
         {
            GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(90010),GlobalLanguageStr.getLanguageStr(97004));
         }
      }
      
      private function re_bookUP(param1:Object, param2:int, param3:String, param4:Array) : void
      {
         var _loc7_:int = 0;
         var _loc8_:Array = GlobalData.$tempFoodForBook as Array;
         var _loc9_:int = 0;
         var _loc6_:Object = param1.data;
         var _loc4_:Object = param1["params"];
         var _loc2_:Array = param4;
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            _loc7_ = 0;
            while(_loc7_ < _loc2_.length)
            {
               delete GlobalData.$userData.my_equips[_loc2_[_loc7_]];
               _loc7_++;
            }
            GlobalData.$userData.my_equips[param3] = _loc6_.equip;
         }
         // The authoritative cache may already contain a newer equip receipt.
         // Animate only if this view still shows that exact target, using its
         // current row rather than the potentially stale response payload.
         var _currentEquipData:Object = GlobalData.$userData == null || GlobalData.$userData.my_equips == null ? null : GlobalData.$userData.my_equips[param3];
         var _currentEquip:Equip = _currentEquipData == null ? null : new Equip(param3,_currentEquipData);
         if(this.stage && GlobalData.$tempEquipCurrSelected == param3 && _currentEquip && _currentEquip.slv > param2)
         {
            SoundManager.getOnlyExample().playSound("avatarLvUp");
            LayoutUIAnimation.getOnlyExample().popSuperWord("50014",2,0.46);
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.gold = _loc6_.gold;
         }
         // Filter only consumed IDs; do not clear a newer target's selection.
         if(_loc8_)
         {
            for each(var _foodId:String in _loc2_)
            {
               _loc9_ = _loc8_.indexOf(_foodId);
               if(_loc9_ >= 0)
               {
                  _loc8_.splice(_loc9_,1);
                  if(GlobalData.$tempObjectFoodForBook && GlobalData.$tempObjectFoodForBook[_foodId])
                  {
                     GlobalData.$tempObjectFoodForBook[_foodId].reData = false;
                     delete GlobalData.$tempObjectFoodForBook[_foodId];
                  }
               }
            }
         }
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
         GlobalData.$tempTeamPowerTemp = GlobalFunction.getTeamPower(GlobalData.$userData.team[0]);
         if(this.stage && GlobalData.$tempEquipCurrSelected == param3)
         {
            clip_food();
            if(mBox_data)
            {
               setTxt(mBox_data,true);
            }
            checkBtn_selectStatus();
         }
      }
      
      private function onTRIGGERED_select(param1:Event) : void
      {
         if(GlobalData.$tempFoodForBook.length > 0)
         {
            GlobalFunction.clearBookFood();
            checkBtn_selectStatus();
            setFood(true);
         }
         else
         {
            checkBookFood();
            checkBtn_selectStatus();
            setFood(false);
         }
      }
      
      private function checkBtn_selectStatus() : void
      {
         var _loc1_:String = "";
         if(GlobalData.$tempFoodForBook.length > 0)
         {
            _loc1_ = GlobalLanguageStr.getLanguageStr(20071);
            mBtn_to.enabled = true;
         }
         else
         {
            _loc1_ = GlobalLanguageStr.getLanguageStr(20228);
            mBtn_to.enabled = false;
         }
         if(mBtn_clear)
         {
            mBtn_clear.text = _loc1_;
            mBtn_clear.shadowFilter();
         }
      }
      
      private function checkBookFood() : void
      {
         var _loc10_:Object = null;
         var _loc7_:Equip = null;
         var _loc9_:int = 0;
         var _loc5_:Equip = new Equip(GlobalData.$tempEquipCurrSelected);
         if(_loc5_.slv >= GlobalData.$mConfig_simple.slv_config[0])
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90238),false,"A_1008_3");
            return;
         }
         var _loc1_:Boolean = false;
         var _loc2_:Array = [];
         var _loc8_:Object = GlobalData.$userData.my_equips;
         var _loc3_:String = "";
         var _loc11_:int = 0;
         for(var _loc12_:Object in _loc8_)
         {
            _loc1_ = false;
            _loc3_ = String(_loc12_);
            _loc11_ = 0;
            if(_loc8_[GlobalData.$tempEquipCurrSelected].eid != _loc8_[_loc12_].eid)
            {
               if(GlobalData.$tempFoodForBook[_loc3_] != null)
               {
                  _loc11_ = -1;
               }
               _loc7_ = new Equip(_loc3_);
               if(_loc7_.getType() == 6 && GlobalFunction.checkEquipHasUsed(_loc3_) == -1)
               {
                  _loc10_ = _loc8_[_loc12_];
                  _loc10_["id"] = _loc3_;
                  _loc10_["status"] = _loc11_;
                  _loc10_["canBetter"] = 0;
                  _loc10_["sort_1"] = _loc7_.getBookValue();
                  _loc2_.push(_loc10_);
               }
            }
         }
         _loc2_.sortOn(["sort_1"],[0x10 | 2]);
         var _loc4_:int = 0;
         var _loc6_:Number = 5;
         _loc9_ = 0;
         while(_loc9_ < _loc2_.length)
         {
            if(_loc4_ >= _loc6_)
            {
               break;
            }
            _loc10_ = _loc2_[_loc9_];
            if(_loc10_["sort_1"] < 0)
            {
               break;
            }
            GlobalFunction.changeBookFoodArray(_loc10_["id"],false,null,_loc10_);
            _loc4_++;
            _loc9_++;
         }
         if(_loc2_.length == 0)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90457),false,"A_3001_1");
         }
         else if(_loc6_ > 0 && _loc4_ == 0)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90115),false,"A_3001_1");
         }
         _loc6_ = 0;
      }
      
      private function setTxt(param1:Sprite, param2:Boolean = false) : void
      {
         if(param2)
         {
            StarlingTools.removeChildrenClear(param1);
         }
         var _loc4_:String = GlobalData.$tempEquipCurrSelected;
         var _loc3_:Object = GlobalData.$userData.my_equips[_loc4_];
         var _loc8_:int = 0;
         var _loc7_:String = GlobalLanguageStr.getLanguageStr(90081);
         var _loc6_:Equip = null;
         if(_loc3_ != null)
         {
            _loc6_ = new Equip(_loc4_,_loc3_);
            _loc8_ = _loc6_.slv;
            _loc7_ = _loc6_.equipData.name;
         }
         var _loc11_:int = 34;
         var _loc9_:int = GlobalData.$mStageWidth * 0.8;
         var _loc10_:TextField = GlobalTextStyle.getTextField(_loc7_,20,16777215,"left",_loc9_,46);
         param1.addChild(_loc10_);
         if(_loc3_ == null)
         {
            return;
         }
         var _loc5_:TextField = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20079,_loc8_),20,16777215,"left",_loc9_,46);
         _loc5_.y = _loc10_.y + _loc11_;
         param1.addChild(_loc5_);
         var _loc12_:TextField = GlobalTextStyle.getTextField(_loc6_.getBookSkill().getInfo(),20,16777215,"left",400,29 * 2);
         _loc12_.y = _loc5_.y + _loc11_;
         param1.addChild(_loc12_);
      }
      
      private function setFood(param1:Boolean = false) : void
      {
         var _loc6_:Number = NaN;
         _loc6_ = 110;
         if(mBox_dataUp)
         {
            StarlingTools.removeChildrenClear(mBox_dataUp);
         }
         else
         {
            mBox_dataUp = new Sprite();
            mBox_equip.addChild(mBox_dataUp);
         }
         var _loc8_:Number = GlobalFunction.getEquipBookUpP(GlobalData.$tempFoodForBook,GlobalData.$tempEquipCurrSelected);
         var _loc5_:String = _loc8_ > 0 ? int(_loc8_ * 100) + "%" : "0%";
         if(mTxt_p)
         {
            mTxt_p.text = GlobalLanguageStr.getLanguageStr(20408,_loc5_);
         }
         var _loc4_:String = GlobalData.$tempEquipCurrSelected;
         var _loc3_:Object = GlobalData.$userData.my_equips[_loc4_];
         var _loc7_:Equip = null;
         if(_loc3_ != null)
         {
            _loc7_ = new Equip(_loc4_,_loc3_);
         }
         if(mTxt_gold)
         {
            mCost_gold = _loc3_ != null && GlobalData.$tempFoodForBook.length > 0 ? _loc7_.getBookUpGold() : 0;
            mTxt_gold.txt2 = mCost_gold > 0 ? String(mCost_gold) : "0";
         }
         _loc7_.clear();
         var _loc2_:Array = GlobalData.$tempFoodForBook;
         var _loc12_:int = 0;
         var _loc9_:int = 5;
         var _loc11_:Object = null;
         var _loc10_:ItemEquipBook = null;
         _loc12_ = 0;
         while(_loc12_ < _loc9_)
         {
            _loc11_ = {};
            _loc11_["id"] = _loc2_[_loc12_] != null ? _loc2_[_loc12_] : null;
            _loc11_["indexID_s"] = _loc12_;
            _loc10_ = new ItemEquipBook();
            _loc10_.data = _loc11_;
            _loc10_.x = _loc12_ * 110;
            mBox_dataUp.addChild(_loc10_);
            _loc12_++;
         }
         if(mImg9_base)
         {
            mBox_dataUp.x = mImg9_base.x + int((mImg9_base.width - _loc12_ * 110) * 0.5);
            mBox_dataUp.y = mImg9_base.y + int((mImg9_base.height - 110) * 0.5);
         }
      }
      
      private function clip_food() : void
      {
         var _loc3_:int = 0;
         var _loc1_:int = 0;
         var _loc2_:ItemEquipBook = null;
         if(mBox_dataUp)
         {
            setmMC_book();
            _loc3_ = 0;
            _loc1_ = mBox_dataUp.numChildren;
            _loc2_ = null;
            _loc3_ = 0;
            while(_loc3_ < _loc1_)
            {
               _loc2_ = mBox_dataUp.getChildAt(_loc3_) as ItemEquipBook;
               _loc2_.setClip_to();
               _loc3_++;
            }
         }
      }
      
      private function delmMC_book() : void
      {
         if(mMC_book)
         {
            mMC_book.removeFromParent(true);
         }
         mMC_book = null;
      }
      
      private function setmMC_book() : void
      {
         delmMC_book();
         if(mCurrEquip && mBox_equip)
         {
            mClip_status = 0;
            mTimer_book = 0;
            mMC_book = DisplayTools.newMc("UI_boss_clip_2_",0,0,15);
            mMC_book.scaleX = mMC_book.scaleY = 2;
            mMC_book.x = mCurrEquip.x + 50;
            mMC_book.y = mCurrEquip.y + 45;
            mBox_equip.addChild(mMC_book);
            mJuggler_food.add(mMC_book);
         }
      }
   }
}

