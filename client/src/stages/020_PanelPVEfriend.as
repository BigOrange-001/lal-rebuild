package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.ui.element.ItemPVEfriend;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.screen.PanelCenterPVE;
   import com.meng52.game.ui.stage.GuideTools;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import feathers.layout.VerticalLayout;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class PanelPVEfriend extends PanelCenterPVE
   {
      
      private const GOTOGAME:String = "gotogame";
      private var mSkipAssistButton:LOL_Button;
      
      public function PanelPVEfriend()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(20035),GlobalData.$center_height);
         update();
      }
      
      override public function onTRIGGERED(param1:Event) : void
      {
         if(this.mStatus_back == "status_avatar_info")
         {
            this.mStatus_back = "status_normal";
            this.closePop();
         }
         else if(this.mStatus_back == "status_normal")
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pve_combat_main");
            GlobalData.$mEventDispatcher.dispatchEventWith("update_pve_combat");
         }
      }
      
      override public function update() : void
      {
         SendServiceAMFFun.send_user_online_user(this.re_online,null);
         if(GlobalData.$currentGuide)
         {
            mList.verticalScrollPolicy = "off";
         }
      }
      
      private function re_online(param1:Object) : void
      {
         GlobalData.$tempOnline = param1.data;
         if(GlobalData.$tempFriend == null)
         {
            SendServiceAMFFun.send_user_get_friends(this.re_friends,null);
         }
         else
         {
            this.showList();
         }
      }
      
      private function re_friends(param1:Object) : void
      {
         GlobalData.$tempFriend = param1.data.friends_list;
         GlobalData.$tempFriendRequest = param1.data.apply_list;
         this.showList();
      }
      
      private function showList() : void
      {
         var _loc1_:String = GuideTools.checkGuideType();
         if(_loc1_ == "1")
         {
            if(GuideMaster.getOnlyExample().checkGuide("M1_2") == -1)
            {
               LayoutUIAnimation.getOnlyExample().clearIfNoGuide();
            }
         }
         this.setList();
         this.addList();
         GuideMaster.getOnlyExample().nextGuideStep("A");
      }
      
      override public function addList() : void
      {
         var _loc16_:Object = null;
         var _loc10_:* = 0;
         var _loc5_:* = 0;
         var _loc11_:Object = null;
         var _loc1_:Avatar = null;
         var _loc6_:Date = null;
         var _loc9_:String = null;
         var _loc15_:Number = NaN;
         var _loc17_:Boolean = false;
         var _loc7_:TextField = null;
         var _loc14_:LOL_Button = null;
         var _loc8_:Sprite = null;
         var _loc3_:int = 0;
         GlobalData.$isNoFriendToPVE = false;
         var _loc2_:Array = [];
         var _loc13_:int = SendAndSelect.$systemTimer_nowSecond;
         var _loc12_:VerticalLayout = new VerticalLayout();
         _loc12_.paddingLeft = 30;
         _loc12_.gap = -13;
         mList.layout = _loc12_;
         _loc5_ = GlobalData.$tempOnline.length;
         _loc11_ = GlobalData.$userData.records.help_suids;
         _loc10_ = 0;
         while(_loc10_ < _loc5_)
         {
            _loc16_ = GlobalData.$tempOnline[_loc10_];
            _loc16_["isF"] = 0;
            _loc6_ = null;
            _loc9_ = _loc16_.uid;
            if(_loc11_[_loc9_])
            {
               _loc6_ = _loc11_[_loc9_] as Date;
            }
            _loc15_ = _loc6_ ? _loc6_.getTime() * 0.001 : 0;
            _loc17_ = _loc15_ < _loc13_;
            if(_loc17_ || GlobalFunction.check_bot_user(_loc16_.uid))
            {
               _loc1_ = new Avatar(_loc16_.avatar.aid,_loc16_.avatar);
               _loc16_["power"] = _loc1_.getPower();
               _loc2_.push(_loc16_);
               _loc1_.clear();
               _loc1_ = null;
            }
            _loc10_++;
         }
         _loc5_ = GlobalData.$tempFriend.length;
         _loc11_ = GlobalData.$userData.records.help_fuids;
         _loc10_ = 0;
         while(_loc10_ < _loc5_)
         {
            _loc16_ = GlobalData.$tempFriend[_loc10_];
            _loc16_["isF"] = 1;
            _loc6_ = _loc16_.login_time as Date;
            _loc15_ = _loc6_.getTime() * 0.001 + GlobalData.$mConfig_simple.friend_cd[2] * 60;
            _loc17_ = _loc15_ > _loc13_;
            if(_loc17_)
            {
               _loc6_ = null;
               _loc9_ = _loc16_.uid;
               if(_loc11_[_loc9_])
               {
                  _loc6_ = _loc11_[_loc9_] as Date;
               }
               _loc15_ = _loc6_ ? _loc6_.getTime() * 0.001 : 0;
               _loc17_ = _loc15_ < _loc13_;
               if(_loc17_)
               {
                  _loc1_ = new Avatar(_loc16_.avatar.aid,_loc16_.avatar);
                  _loc16_["power"] = _loc1_.getPower();
                  _loc2_.push(_loc16_);
                  _loc1_.clear();
                  _loc1_ = null;
               }
            }
            _loc10_++;
         }
         _loc2_.sortOn("power",0x10 | 2);
         if(!GlobalData.$currentGuide)
         {
            _loc10_ = 0;
            while(_loc10_ < 2)
            {
               _loc5_ = uint(int(Math.random() * _loc2_.length));
               _loc16_ = _loc2_[_loc5_];
               _loc2_.splice(_loc5_,1);
               _loc2_.unshift(_loc16_);
               _loc10_++;
            }
         }
         var _loc4_:Boolean = false;
         if(GlobalData.$userData.lv >= GlobalData.$mConfig_simple.start_lv[13] && GlobalFunction.checkIOSvip())
         {
            _loc3_ = GlobalData.$diff;
            if(GlobalFunction.isRndCombat(_loc3_,GlobalData.$tempPVE_combatID) == false)
            {
               _loc4_ = int(GlobalFunction.getCombatStarById(GlobalData.$tempPVE_combatID)) == 3;
               if(_loc4_)
               {
                  _loc8_ = new Sprite();
                  _loc7_ = GlobalFunction.createTextField(400,MainConfig.$isEnglish ? 70 : 30,GlobalLanguageStr.getLanguageStr(90242),"",20,16777215);
                  _loc7_.y = MainConfig.$isEnglish ? 0 : 18;
                  _loc8_.addChild(_loc7_);
                  _loc14_ = new LOL_Button(GlobalLanguageStr.getLanguageStr(90243),"UI_btn_normalFun_0000");
                  if(MainConfig.$isEnglish)
                  {
                     _loc14_.fontSize = 22;
                  }
                  _loc14_.x = _loc7_.x + _loc7_.width;
                  _loc14_.name = "gotogame";
                  _loc14_.addEventListener("triggered",onTRIGGEREDHandler);
                  _loc8_.addChild(_loc14_);
                  this.addChild(_loc8_);
                  _loc8_.x = this.mImg9_baseBg.x + (this.mImg9_baseBg.width - _loc8_.width) * 0.5;
                  _loc8_.y = this.mImg9_baseBg.y + this.mImg9_baseBg.height - _loc8_.height - 35;
               }
            }
         }
         if(_loc4_)
         {
            mList.y = mListY - 15;
            setListHeight(_loc8_.height + 134);
         }
         else
         {
            mList.y = mListY - 15;
            setListHeight(140);
         }
         this.setListTimer(mList,_loc2_,ItemPVEfriend,false);
         addSkipAssistButton();
         _loc2_ = null;
         _loc16_ = null;
      }
      
      private function addSkipAssistButton() : void
      {
         if(mSkipAssistButton)
         {
            mSkipAssistButton.removeFromParent(true);
            mSkipAssistButton = null;
         }
         if(mList)
         {
            mList.height = Math.max(120,mList.height - 68);
         }
         mSkipAssistButton = new LOL_Button("略过好友助战","UI_btn_normalFun_0000");
         mSkipAssistButton.name = "skip_assist";
         mSkipAssistButton.addEventListener("triggered",onTRIGGEREDHandler);
         mSkipAssistButton.x = mList.x + (mList.width - mSkipAssistButton.width) * 0.5;
         mSkipAssistButton.y = mList.y + mList.height + 8;
         this.addChild(mSkipAssistButton);
      }
      
      private function onTRIGGEREDHandler(param1:Event) : void
      {
         var _loc2_:String = (param1.currentTarget as LOL_Button).name;
         if(_loc2_ == "gotogame" || _loc2_ == "skip_assist")
         {
            GlobalData.$isNoFriendToPVE = true;
            GlobalData.$tempHelpAvatar = null;
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pve_embattle",false,true);
         }
      }
   }
}

