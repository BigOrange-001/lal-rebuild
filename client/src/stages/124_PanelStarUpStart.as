package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.module.talent.Talent;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.element.HtmlTextField;
   import com.meng52.game.ui.element.ItemAvatarAward;
   import com.meng52.game.ui.element.ItemStarUpElement;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.element.LOL_StarLevel;
   import com.meng52.game.ui.screen.PanelAvatarStarUp;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import starling.display.Image;
   import starling.display.MovieClip;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.EnterFrameEvent;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   
   public class PanelStarUpStart extends PanelAvatarStarUp
   {
      
      private var mBox_a:Sprite;
      
      private var mBox_a_info:Sprite;
      
      private var mBox_b:Sprite;
      
      private var mBox_b_info:Sprite;
      
      private var mList_avatars:Sprite;
      
      private var mAvatar_a:Avatar;
      
      private var mAvatar_b:Avatar;
      
      private var mBtn_up:LOL_Scale9Button;
      
      private var mOK_a:Boolean = false;
      
      private var mOK_b:Boolean = false;
      
      private var mOK_c:Boolean = false;
      
      private var mOK_c_teamID:int = 0;
      
      private var mStarUpArr:Array;
      
      private var mBox_a_clip:Sprite;
      
      private var mBox_b_clip:Sprite;
      
      private var mBottom_clip:Sprite;
      
      private var mClip_bgY:Number = 0;
      
      private var mClip_status:Number = 0;
      
      private var mClip_statusB:Number = 0;
      
      private var mClip_statusC:Boolean = false;

      private var mStarUpRequestId:uint = 0;

      private var mStarUpViewEpoch:uint = 0;

      private var mStarUpReceiptRequestId:uint = 0;
      
      private var isPhaseUp:Boolean = false;

      private var mGrowthType:int = 0;
      
      private var isStartUp:Boolean = false;
      
      private var _arrowsImg:Image;
      
      private var mClip_spr:Sprite;
      
      private const BOX_A_CLIP:String = "mBox_a_clip";
      
      private const BOX_B_CLIP:String = "mBox_b_clip";
      
      public function PanelStarUpStart()
      {
         super();
      }
      
      override public function onTRIGGERED_closePanel(param1:Event) : void
      {
         if(GlobalData.$mGameClassObject.mLayoutUICenter.mPanelSocialMainAvatar)
         {
            if(GlobalData.$mGameClassObject.mLayoutUICenter.mPanelSocialMainAvatar.mList != null)
            {
               GlobalData.$mGameClassObject.mLayoutUICenter.mPanelSocialMainAvatar.mList.visible = true;
            }
         }
         super.onTRIGGERED_closePanel(param1);
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         mStarUpViewEpoch++;
         this.removeEventListener("addedToStage",initializeHandler);
         GlobalData.$mEventDispatcher.addEventListener("update_avatar_better_start",onMainEvent);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(20087),807);
         this.mBox_a_clip = new Sprite();
         mBox_a_clip.name = "mBox_a_clip";
         this.mBox_b_clip = new Sprite();
         mBox_b_clip.name = "mBox_b_clip";
         this.mBottom_clip = new Sprite();
         this.mBox_a = new Sprite();
         this.mBox_b = new Sprite();
         this.mList_avatars = new Sprite();
         var _loc5_:Scale9Image = GlobalFunction.createScale9Image("UI_bg_9slice_7_0000",275,425,new Rectangle(30,20,20,20));
         var _loc3_:Scale9Image = GlobalFunction.createScale9Image("UI_bg_9slice_7_0000",275,425,new Rectangle(30,20,20,20));
         var _loc2_:Scale9Image = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",560,170,new Rectangle(110,55,70,20));
         _loc5_.touchable = false;
         _loc3_.touchable = false;
         _loc2_.touchable = false;
         var _loc4_:Quad = new Quad(_loc5_.width - 5,_loc5_.height - 5);
         this.mBox_a_clip.addChild(_loc4_);
         var _loc7_:Quad = new Quad(_loc3_.width - 5,_loc3_.height - 5);
         this.mBox_b_clip.addChild(_loc7_);
         _loc4_.alpha = _loc7_.alpha = 0.01;
         this.mBox_a_clip.addChild(_loc5_);
         this.mBox_b_clip.addChild(_loc3_);
         this.mBottom_clip.addChild(_loc2_);
         var _loc6_:TextField = GlobalFunction.createTextField(200,40,GlobalLanguageStr.getStr(90397),"",20,1513239);
         _loc6_.hAlign = "left";
         _loc6_.x = 30;
         _loc6_.y = 10;
         this.mBottom_clip.addChild(_loc6_);
         mBox_a_clip.x = this.mImg9_baseBg.x + 30 + 2;
         mBox_b_clip.x = mBox_a_clip.x + this.mBox_a_clip.width + 25;
         mBox_a_clip.y = mBox_b_clip.y = 90;
         mBottom_clip.x = this.mImg9_baseBg.x + (this.mImg9_baseBg.width - _loc2_.width) * 0.5;
         mBottom_clip.y = mBox_a_clip.y + mBox_a_clip.height + 5;
         _arrowsImg = GlobalFunction.createImage("UI_tag_right_0_0000");
         _arrowsImg.x = mBox_a_clip.x + mBox_a_clip.width + 2;
         _arrowsImg.y = mBox_a_clip.y + mBox_a_clip.height * 0.5;
         this.addChild(_arrowsImg);
         this.mBox_a_clip.addChild(this.mBox_a);
         this.mBox_b_clip.addChild(this.mBox_b);
         this.mBottom_clip.addChild(this.mList_avatars);
         this.mBtn_up = new LOL_Scale9Button(GlobalLanguageStr.getStr(20092),150,70,"UI_btn_normalFun_0000");
         this.mBtn_up.x = int((GlobalData.$mStageWidth - this.mBtn_up.width) * 0.5);
         this.mBtn_up.y = mBottom_clip.y + mBottom_clip.height + 10;
         this.mBtn_up.addEventListener("triggered",this.onTRIGGERED_btns);
         this.addChild(this.mBtn_up);
         this.addChild(this.mBox_a_clip);
         this.addChild(this.mBox_b_clip);
         this.addChild(this.mBottom_clip);
         this.addChild(_arrowsImg);
         onMainEvent();
      }
      
      private function onMainEvent() : void
      {
         update();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         mStarUpViewEpoch++;
         mStarUpRequestId++;
         GlobalData.$mEventDispatcher.dispatchEventWith("change_team_member",false,GlobalData.$tempTeamSelect);
         GlobalData.$mEventDispatcher.removeEventListener("update_avatar_better_start",onMainEvent);
         if(this.mAvatar_a)
         {
            this.mAvatar_a.clear();
            this.mAvatar_a = null;
         }
         if(this.mAvatar_b)
         {
            this.mAvatar_b.clear();
            this.mAvatar_b = null;
         }
         StarlingTools.removeChildrenClear(mList_avatars);
         StarlingTools.removeChildrenClear(mBox_a_info);
         StarlingTools.removeChildrenClear(mBox_b_info);
         StarlingTools.removeChildrenClear(mBox_a);
         StarlingTools.removeChildrenClear(mBox_b);
         StarlingTools.removeChildrenClear(this);
         this.mClip_status = 0;
         this.mClip_statusB = 0;
         this.mClip_statusC = false;
         this.delJuggler();
         this.delUIList();
         if(mList_avatars)
         {
            mList_avatars.dispose();
         }
         if(mClip_spr)
         {
            mClip_spr.dispose();
         }
         mClip_spr = null;
         mList_avatars = null;
         this.dispose();
         this.clear();
         if(_arrowsImg)
         {
            _arrowsImg.dispose();
            _arrowsImg.removeFromParent(true);
         }
         _arrowsImg = null;
      }
      
      override public function onBTN_NAME_BACK() : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_social_main_avatar");
      }
      
      private function onTRIGGERED_btns(param1:Event) : void
      {
         var _id:String;
         var _serviceFun:Function;
         var arr:Array;
         var i:int;
         var ava:Avatar;
         var _fun1:Object;
         var talent:Talent;
         var str:String;
         var _error:Object;
         var func:Object;
         var serverFun:*;
         var str2:String;
         var aid:String;
         var b:Boolean;
         var serverFun1:*;
         var _str:String;
         var _teamName:Array;
         var _event:Event = param1;
         if(mGrowthType == 0)
         {
            return;
         }
         var a:Object = GlobalData.$userData;
         var o:* = GlobalData.$tempAvatarStarUp;
         if(GlobalData.$userData.attrs.avatar_culture != null)
         {
            if(GlobalData.$userData.attrs.avatar_culture.aid)
            {
               _id = GlobalData.$userData.attrs.avatar_culture.aid;
            }
            else
            {
               _id = GlobalData.$userData.attrs.avatar_culture.eqid;
            }
            if(_id == GlobalData.$tempAvatarStarUp.id)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10165));
               return;
            }
         }
         if(isPhaseUp)
         {
            _serviceFun = service_phaseUp;
         }
         else
         {
            _serviceFun = service_starUp;
         }
         arr = [];
         i = 0;
         while(i < mStarUpArr.length)
         {
            arr.push(mStarUpArr[i].id);
            i = i + 1;
         }
         if(this.mOK_a && this.mOK_b && this.mOK_c)
         {
            if(isPhaseUp)
            {
               ava = new Avatar(arr[0],GlobalData.$userData.avatars[arr[0]]);
               if(ava.talent)
               {
                  _fun1 = {
                     "ok":_serviceFun,
                     "no":GlobalFunction.functionNull
                  };
                  talent = new Talent(ava.talent.id);
                  str = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(98037,talent.my_HaloData.name),GlobalTextStyle.COLOR_W_Y_Y_G);
                  GlobalFunction.popAlert("",str,_fun1);
                  return;
               }
               if(mStarUpArr[0].lv > GlobalData.$tempAvatarStarUp.lv)
               {
                  serverFun = function():void
                  {
                     var _loc2_:Object = {
                        "ok":_serviceFun,
                        "no":GlobalFunction.functionNull
                     };
                     var _loc1_:String = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90020),GlobalTextStyle.COLOR_W_Y_Y_G);
                     GlobalFunction.popAlert("",_loc1_,_loc2_);
                  };
                  _error = GlobalFunction.formateBetterItemsError(arr,false);
                  func = null;
                  if(_error.p)
                  {
                     func = {
                        "ok":serverFun,
                        "okA":["Pop"],
                        "no":GlobalFunction.functionNull
                     };
                  }
                  else
                  {
                     func = {
                        "ok":_serviceFun,
                        "no":GlobalFunction.functionNull
                     };
                  }
                  str2 = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90368),GlobalTextStyle.COLOR_W_Y_Y_G);
                  GlobalFunction.popAlert("",str2,func);
                  return;
               }
            }
            _error = GlobalFunction.formateBetterItemsError(arr,false);
            if(_error.p)
            {
               serverFun1 = function():void
               {
                  var _loc2_:Object = {
                     "ok":_serviceFun,
                     "no":GlobalFunction.functionNull
                  };
                  var _loc1_:String = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(10165),GlobalTextStyle.COLOR_W_Y_Y_G);
                  GlobalFunction.popAlert("",_loc1_);
               };
               aid = mStarUpArr[0].id;
               b = false;
               if(GlobalData.$userData.attrs.avatar_culture != null)
               {
                  if(GlobalData.$userData.attrs.avatar_culture.aid == aid || GlobalData.$userData.attrs.avatar_culture.eqid == aid)
                  {
                     b = true;
                  }
               }
               if(b)
               {
                  func = {
                     "ok":serverFun1,
                     "no":GlobalFunction.functionNull,
                     "okA":["Pop"]
                  };
               }
               else
               {
                  func = {
                     "ok":_serviceFun,
                     "no":GlobalFunction.functionNull
                  };
               }
               _str = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90020),GlobalTextStyle.COLOR_W_Y_Y_G);
               GlobalFunction.popAlert("",_str,func);
            }
            else
            {
               _serviceFun();
            }
         }
         else
         {
            if(!this.mOK_b)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90018),false,"A_1001_5");
               return;
            }
            if(!this.mOK_a)
            {
               if(isPhaseUp)
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90128),false);
               }
               else
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90019),false);
               }
               return;
            }
            if(!this.mOK_c)
            {
               _teamName = ["A","B","C","D","E"];
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90024,_teamName[mOK_c_teamID]),false);
               return;
            }
         }
      }
      
      private function service_phaseUp() : void
      {
         var _loc2_:int = 0;
         var _loc1_:Array = [];
         _loc2_ = 0;
         while(_loc2_ < mStarUpArr.length)
         {
            _loc1_.push(mStarUpArr[_loc2_].id);
            _loc2_++;
         }
         if(SendAndSelect.checkRepeat("user.phase_up",""))
         {
            return;
         }
         var _targetId:String = String(GlobalData.$tempAvatarStarUp.id);
         var _materialIds:Array = _loc1_.concat();
         var _op:uint = ++mStarUpRequestId;
         var _epoch:uint = mStarUpViewEpoch;
         var _owner:PanelStarUpStart = this;
         SendServiceAMFFun.send_user_phase_up(function(_receipt:Object):void
         {
            _owner.re_phase_up(_receipt,_op,_epoch,_targetId,_materialIds);
         },{
            "aid":_targetId,
            "aids":_materialIds.concat()
         });
      }
      
      private function service_starUp() : void
      {
         var _loc2_:int = 0;
         var _loc1_:Array = [];
         _loc2_ = 0;
         while(_loc2_ < mStarUpArr.length)
         {
            _loc1_.push(mStarUpArr[_loc2_].id);
            _loc2_++;
         }
         if(SendAndSelect.checkRepeat("user.star_up",""))
         {
            return;
         }
         var _targetId:String = String(GlobalData.$tempAvatarStarUp.id);
         var _materialIds:Array = _loc1_.concat();
         var _op:uint = ++mStarUpRequestId;
         var _epoch:uint = mStarUpViewEpoch;
         var _owner:PanelStarUpStart = this;
         SendServiceAMFFun.send_user_star_up(function(_receipt:Object):void
         {
            _owner.re_star_up(_receipt,_op,_epoch,_targetId,_materialIds);
         },{
            "aid":_targetId,
            "aids":_materialIds.concat()
         });
      }
      
      private function mBox_b_clip_onComplete(param1:Avatar) : void
      {
         onCLOSE_PANEL_SELF();
         LayoutUIAnimation.getOnlyExample().clearAnimationLayer();
         LayoutUIAnimation.getOnlyExample().popCasino([param1],4,0,MainConfig.$betterBgUiName);
      }
      
      private function clip_fireworks(param1:Boolean = false) : void
      {
         var _loc2_:MovieClip = null;
         var _loc4_:int = 0;
         var _loc3_:Number = GlobalData.formatVScaleY_center(850 * 0.1);
         if(!param1)
         {
            this.mJugglerBox.removeChildren(2,-1,true);
            this.mJuggler.purge();
            this.mClip_statusB += 1;
         }
         _loc2_ = DisplayTools.newMc("UI_movieClip_starUp_b_",0,0,15,true);
         _loc2_.scaleX = _loc2_.scaleY = Math.random() + 1;
         _loc2_.x = Tools.getRandom(_loc2_.width / 2,GlobalData.$mStageWidth - _loc2_.width / 2);
         _loc2_.y = Tools.getRandom(_loc3_,_loc3_ + 450);
         this.mJugglerBox.addChild(_loc2_);
         this.mJuggler.add(_loc2_);
      }
      
      override public function onENTER_FRAME_juggler(param1:EnterFrameEvent) : void
      {
         if(this.mJuggler)
         {
            this.mJuggler.advanceTime(param1.passedTime);
            if(this.mClip_spr)
            {
               if(this.mClip_spr.stage == null && this.mClip_statusC)
               {
                  if(this.mClip_status == 0)
                  {
                     this.mClip_status = 1;
                     this.clip_fireworks();
                  }
                  if(mClip_status >= 1)
                  {
                     mClip_status += 1;
                     if(mClip_status % 6 == 0)
                     {
                        this.clip_fireworks(true);
                     }
                  }
               }
            }
            if(this.mClip_statusB >= 2)
            {
               if(!GlobalData.$mGameClassObject.touchable)
               {
                  GlobalData.$mGameClassObject.touchable = true;
                  GuideMaster.getOnlyExample().nextGuideStep();
               }
            }
         }
      }
      
      private function isCurrentStarUpReceipt(param1:Object, param2:uint, param3:uint, param4:String, param5:Array) : Boolean
      {
         if(param1 == null || param1["params"] == null || param2 != mStarUpRequestId || param3 != mStarUpViewEpoch || stage == null || GlobalData.$tempAvatarStarUp == null || String(GlobalData.$tempAvatarStarUp.id) != param4)
         {
            return false;
         }
         if(String(param1["params"].aid) != param4 || !(param1["params"].aids is Array))
         {
            return false;
         }
         var _responseIds:Array = param1["params"].aids as Array;
         if(_responseIds.length != param5.length)
         {
            return false;
         }
         var _i:int = 0;
         while(_i < param5.length)
         {
            if(String(_responseIds[_i]) != String(param5[_i]))
            {
               return false;
            }
            _i++;
         }
         return true;
      }

      private function re_phase_up(param1:Object, param2:uint, param3:uint, param4:String, param5:Array) : void
      {
         if(GlobalFunction.isMalformedProfileReceipt(param1) || !isCurrentStarUpReceipt(param1,param2,param3,param4,param5))
         {
            return;
         }
         if(param2 == mStarUpReceiptRequestId)
         {
            return;
         }
         mStarUpReceiptRequestId = param2;
         var _loc5_:* = 0;
         var _loc4_:String = param4;
         var _loc3_:Array = param5;
         if(GlobalFunction.isLegacyProfileReceipt(param1))
         {
            while(_loc5_ < _loc3_.length)
            {
               GlobalFunction.changeUserDataAvatars(_loc3_[_loc5_]);
               _loc5_++;
            }
            GlobalFunction.changeUserDataAvatars(_loc4_,param1.data);
         }
         var _currentProfile:Object = GlobalData.$userData;
         var _currentAvatars:Object = _currentProfile == null ? null : _currentProfile.avatars;
         var _currentHero:Object = _currentAvatars == null ? null : _currentAvatars[_loc4_];
         if(_currentHero == null)
         {
            return;
         }
         this.mClip_statusB += 1;
         GuideMaster.getOnlyExample().guideWait();
         SoundManager.getOnlyExample().playSound("avatarStarUp");
         var _loc2_:Avatar = new Avatar(_loc4_,_currentHero);
         this.mBox_b_clip_onComplete(_loc2_);
         mBtn_up.visible = false;
      }
      
      private function re_star_up(param1:Object, param2:uint, param3:uint, param4:String, param5:Array) : void
      {
         if(GlobalFunction.isMalformedProfileReceipt(param1) || !isCurrentStarUpReceipt(param1,param2,param3,param4,param5))
         {
            return;
         }
         if(param2 == mStarUpReceiptRequestId)
         {
            return;
         }
         mStarUpReceiptRequestId = param2;
         var _loc7_:* = 0;
         var _loc4_:Object = null;
         var _loc6_:String = param4;
         var _loc3_:Array = param5;
         var _loc5_:String = GlobalFunction.getStarUpId(_loc6_);
         if(GlobalFunction.isLegacyProfileReceipt(param1))
         {
            GlobalFunction.changeTeamOneToOne(_loc6_,_loc5_);
            _loc7_ = 0;
            while(_loc7_ < _loc3_.length)
            {
               GlobalFunction.changeUserDataAvatars(_loc3_[_loc7_]);
               _loc7_++;
            }
            GlobalFunction.changeUserDataAvatars(_loc6_);
            GlobalFunction.changeUserDataAvatars(_loc5_,param1.data,true);
            GlobalFunction.changeStarUpDnTeam(_loc6_,_loc5_);
         }
         var _currentProfile:Object = GlobalData.$userData;
         var _currentAvatars:Object = _currentProfile == null ? null : _currentProfile.avatars;
         var _currentHero:Object = _currentAvatars == null ? null : _currentAvatars[_loc5_];
         if(_currentHero == null)
         {
            return;
         }
         this.mClip_statusB += 1;
         GuideMaster.getOnlyExample().guideWait();
         SoundManager.getOnlyExample().playSound("avatarStarUp");
         var _loc2_:Avatar = new Avatar(_loc5_,_currentHero);
         this.mBox_b_clip_onComplete(_loc2_);
         if(GlobalData.$tempTeamSelect != null && String(GlobalData.$tempTeamSelect.id) == _loc6_)
         {
            _loc4_ = GlobalData.$tempTeamSelect;
            _loc4_.id = _loc5_;
            GlobalData.$tempTeamSelect = _loc4_;
         }
         mBtn_up.visible = false;
      }
      
      override public function update() : void
      {
         this.mClip_status = 0;
         this.mClip_statusB = 0;
         this.mOK_a = false;
         this.mOK_b = false;
         this.mOK_c = false;
         var _loc1_:Avatar = new Avatar(GlobalData.$tempAvatarStarUp.id,GlobalData.$tempAvatarStarUp);
         var _loc2_:int = _loc1_.getPhaseType();
         mGrowthType = _loc2_;
         if(_loc2_ == 1)
         {
            isPhaseUp = true;
         }
         else
         {
            isPhaseUp = false;
         }
         this.setUIGroup(this.mBox_a,"a","UI_bg_bar_2_0000",0);
         if(mGrowthType == 0)
         {
            this.delUIList();
            StarlingTools.removeChildrenClear(this.mBox_b);
            mAvatar_b = null;
            mBtn_up.enabled = false;
            mBtn_up.text = "已达上限";
            return;
         }
         this.checkOK_c();
         this.setUIList();
         this.setUIGroup(this.mBox_b,"b","UI_bg_bar_2_0000",1);
         GuideMaster.getOnlyExample().nextGuideStep();
      }
      
      private function checkOK_c() : void
      {
         var _loc4_:Array = null;
         var _loc6_:int = 0;
         var _loc1_:Avatar = null;
         var _loc3_:Number = NaN;
         var _loc5_:String = GlobalData.$tempAvatarStarUp.id;
         var _loc2_:Avatar = new Avatar(GlobalData.$tempAvatarStarUp.id,GlobalData.$tempAvatarStarUp);
         if(!isPhaseUp)
         {
            _loc5_ = GlobalFunction.getStarUpId(_loc5_);
         }
         _loc1_ = new Avatar(_loc5_,GlobalData.$tempAvatarStarUp);
         if(isPhaseUp)
         {
            _loc1_.phase++;
         }
         else
         {
            _loc1_.phase = 0;
         }
         this.mOK_c = true;
         if(GlobalFunction.checkIsTeamMember(GlobalData.$tempAvatarStarUp.id))
         {
            _loc4_ = GlobalData.$userData.team as Array;
            _loc6_ = 0;
            _loc3_ = 0;
            GlobalData.$tempUserLS = GlobalFunction.getLeaderShip();
            _loc3_ = GlobalFunction.getTeamLeaderShip(_loc4_[_loc6_]);
            if(_loc3_ - _loc2_.getLeadership() + _loc1_.getLeadership() > GlobalData.$tempUserLS && (_loc4_[_loc6_] as Array).indexOf(GlobalData.$tempAvatarStarUp.id) > -1)
            {
               this.mOK_c = false;
               mOK_c_teamID = _loc6_;
            }
         }
      }
      
      private function delUIList() : void
      {
         if(this.mList_avatars)
         {
            StarlingTools.removeChildrenClear(this.mList_avatars);
         }
      }
      
      public function setUIList() : void
      {
         var _loc3_:Array = null;
         var _loc14_:Array = null;
         var _loc11_:Array = null;
         var _loc7_:* = 0;
         var _loc12_:ItemStarUpElement = null;
         var _loc1_:Avatar = new Avatar(GlobalData.$tempAvatarStarUp.id,GlobalData.$tempAvatarStarUp);
         if(isPhaseUp)
         {
            _loc11_ = _loc1_.avatarData.phaseUpList;
            _loc3_ = [];
            _loc7_ = 0;
            while(_loc7_ < _loc1_.phase + 1)
            {
               _loc3_.push(_loc1_.avatarData.id);
               _loc7_++;
            }
            _loc14_ = GlobalFunction.getPhaseUpItems(GlobalData.$tempAvatarStarUp);
            for(var materialIndex:int = _loc14_.length - 1; materialIndex >= 0; materialIndex--)
            {
               if(int(_loc14_[materialIndex].phase) != 0) _loc14_.splice(materialIndex,1);
            }
         }
         else
         {
            _loc3_ = _loc1_.avatarData.starUp as Array;
            _loc14_ = GlobalFunction.getStarUpItems(GlobalData.$tempAvatarStarUp);
         }
         _loc7_ = 0;
         var _loc2_:uint = 5;
         var _loc8_:String = "";
         var _loc13_:Object = {};
         var _loc5_:uint = 0;
         var _loc6_:uint = _loc14_.length;
         var _loc4_:String = "";
         this.mStarUpArr = [];
         var _loc9_:int = int(_loc3_.length);
         this.mOK_a = false;
         _loc7_ = 0;
         while(_loc7_ < _loc2_)
         {
            _loc13_ = {"had":0};
            if(_loc3_[_loc7_] != null)
            {
               _loc8_ = _loc3_[_loc7_];
               _loc13_["id"] = _loc8_;
               _loc6_ = _loc14_.length;
               _loc5_ = 0;
               while(_loc5_ < _loc6_)
               {
                  _loc4_ = _loc14_[_loc5_].id;
                  if(_loc4_.indexOf(_loc8_) > -1)
                  {
                     _loc13_ = Tools.clone(_loc14_[_loc5_]);
                     _loc13_["had"] = 1;
                     _loc13_["id"] = _loc4_;
                     _loc14_.splice(_loc5_,1);
                     _loc5_ -= 1;
                     _loc6_ = _loc14_.length;
                     this.mStarUpArr.push({
                        "id":_loc4_,
                        "lv":_loc13_.lv
                     });
                     _loc9_ -= 1;
                     break;
                  }
                  _loc5_++;
               }
            }
            _loc12_ = new ItemStarUpElement();
            _loc12_.x = _loc7_ * (90 + 10);
            if(isPhaseUp)
            {
               _loc13_["isPhase"] = 1;
               _loc13_["phase"] = 0;
            }
            _loc12_.data = _loc13_;
            this.mList_avatars.addChild(_loc12_);
            mList_avatars.x = (this.mBottom_clip.width - mList_avatars.width) * 0.5 - 5;
            mList_avatars.y = this.mBottom_clip.height - mList_avatars.height - 10;
            _loc7_++;
         }
         if(_loc9_ <= 0 && mGrowthType > 0)
         {
            this.mOK_a = true;
         }
         var _loc10_:Number = 0.5;
         if(this.mOK_a && this.mOK_b && this.mOK_c)
         {
            _loc10_ = 1;
         }
         this.mBtn_up.enabled = _loc10_ >= 1;
         if(mGrowthType > 0)
         {
            mBtn_up.text = _loc9_ > 0 ? "缺材料 " + _loc9_ : (!mOK_b ? "等级未满" : (!mOK_c ? "统率不足" : (isPhaseUp ? "进阶 " + (_loc1_.phase + 1) + "/3" : "升星")));
         }
      }
      
      public function setUIGroup(param1:Sprite, param2:String, param3:String = "", param4:int = 0) : void
      {
         var _loc25_:Avatar = null;
         var _loc7_:HtmlTextField = null;
         var _loc32_:* = 0;
         var _loc12_:int = 0;
         var _loc13_:int = 0;
         var _loc27_:int = 0;
         var _loc40_:Avatar = null;
         var _loc8_:Array = null;
         var _loc36_:String = null;
         var _loc23_:LOL_Button = null;
         var _loc29_:Rectangle = null;
         var _loc26_:TextField = null;
         StarlingTools.removeChildrenClear(param1);
         var _loc16_:Number = Number(GlobalData.$mConfig_simple.culture.culture_pith);
         var _loc9_:String = GlobalData.$tempAvatarStarUp.id;
         var _loc33_:Avatar = new Avatar(GlobalData.$tempAvatarStarUp.id,GlobalData.$tempAvatarStarUp);
         if(param4 == 1)
         {
            if(!isPhaseUp)
            {
               _loc9_ = GlobalFunction.getStarUpId(_loc9_);
            }
         }
         else
         {
            this.mOK_b = false;
         }
         if(param2 == "a")
         {
            _loc25_ = this.mAvatar_a;
         }
         else if(param2 == "b")
         {
            _loc25_ = this.mAvatar_b;
         }
         if(_loc25_)
         {
            _loc25_.clear();
            _loc25_ = null;
         }
         _loc25_ = new Avatar(_loc9_,Tools.clone(GlobalData.$tempAvatarStarUp),true);
         if(param2 == "a")
         {
            mAvatar_a = _loc25_;
         }
         else if(param2 == "b")
         {
            mAvatar_b = _loc25_;
         }
         var _loc5_:Avatar = _loc25_;
         var _loc6_:int = int(_loc5_.skill0 ? _loc5_.skill0.lv : 0);
         if(_loc5_.lv >= _loc5_.getLvMax() && param4 == 0)
         {
            this.mOK_b = true;
         }
         else if(param4 == 0 && isPhaseUp)
         {
            this.mOK_b = true;
         }
         if(!isPhaseUp)
         {
            if(param4 == 1)
            {
               _loc5_.lv = 1;
               _loc5_.exp = 0;
               _loc5_.phase = 0;
            }
         }
         else if(param4 == 1)
         {
            _loc5_.lv = _loc5_.lv;
            _loc5_.phase++;
            _loc27_ = _loc5_.getPhasePith();
            _loc5_.hpP += _loc27_;
            _loc5_.apP += _loc27_;
            _loc5_.dePhP += _loc27_;
            _loc5_.deMaP += _loc27_;
         }
         if(param4 == 1)
         {
            if(mStarUpArr)
            {
               _loc32_ = 0;
               while(_loc32_ < mStarUpArr.length)
               {
                  _loc40_ = new Avatar(mStarUpArr[_loc32_].id);
                  _loc5_.hpP += _loc40_.hpP;
                  _loc5_.apP += _loc40_.apP;
                  _loc5_.dePhP += _loc40_.dePhP;
                  _loc5_.deMaP += _loc40_.deMaP;
                  _loc32_++;
               }
            }
            _loc5_.hpP = Math.min(_loc5_.hpP,Avatar.PITH_MAX);
            _loc5_.apP = Math.min(_loc5_.apP,Avatar.PITH_MAX);
            _loc5_.dePhP = Math.min(_loc5_.dePhP,Avatar.PITH_MAX);
            _loc5_.deMaP = Math.min(_loc5_.deMaP,Avatar.PITH_MAX);
         }
         if(param4 != 0)
         {
            if(_loc33_.avatarData.skill0 == _loc5_.avatarData.skill0)
            {
               _loc6_ = int(_loc33_.skill0 ? _loc33_.skill0.lv : 0);
            }
         }
         var _loc14_:Number = 96;
         var _loc18_:String = "";
         var _loc22_:Number = 200;
         var _loc20_:TextField = GlobalFunction.createTextField(180,MainConfig.$isEA ? 40 : 30,_loc5_.avatarData.name,"",20,16764006);
         _loc20_.hAlign = "left";
         _loc20_.x = 105;
         _loc20_.y = 20;
         param1.addChild(_loc20_);
         var _loc28_:Number = 16763955;
         var _loc38_:Array = GlobalTextStyle.COLOR_W_Y_Y_Y;
         var _loc24_:Array = GlobalTextStyle.COLOR_Y_Y_Y_Y;
         var _loc34_:Array = GlobalTextStyle.COLOR_Y_R_R_R;
         if(isPhaseUp)
         {
            _loc28_ = 65280;
            _loc24_ = GlobalTextStyle.COLOR_382E16;
            _loc34_ = GlobalTextStyle.COLOR_382E16;
         }
         _loc18_ = _loc5_.skill0 ? GlobalLanguageStr.getLanguageStr(20091,_loc5_.skill0.skillSetData.name,_loc6_,_loc5_.skill0.skillSetData.warmup,_loc5_.skill0.skillSetData.cooldown) : GlobalLanguageStr.getLanguageStr(90022);
         var _loc30_:TextField = GlobalTextStyle.getTextField(_loc18_,20,param4 == 0 ? 16777215 : uint(_loc28_),"left",200,29);
         var _loc41_:Sprite = new Sprite();
         var _loc11_:uint = uint(_loc5_.getStar());
         var _loc35_:uint = uint(_loc5_.avatarData.getMaxStar());
         var _loc42_:Image = null;
         _loc41_ = new LOL_StarLevel(_loc11_,_loc35_,0.4);
         _loc41_.pivotX = 0;
         _loc41_.x = 93;
         _loc41_.y = _loc20_.y + _loc20_.height + 30;
         _loc41_.scaleX = _loc41_.scaleY = 0.7;
         param1.addChild(_loc41_);
         var _loc37_:int = _loc5_.getLeadership(true) - _loc5_.getLeadership();
         _loc36_ = _loc5_.getLeadership().toString();
         if(_loc37_ > 0)
         {
            _loc36_ = GlobalLanguageStr.getLanguageStr(20207,_loc36_);
         }
         _loc36_ = GlobalLanguageStr.getLanguageStr(20090,_loc36_);
         var _loc39_:Array = param4 == 0 ? GlobalTextStyle.COLOR_W_P_P_P : _loc24_;
         _loc39_ = _loc39_.concat();
         if(_loc37_ > 0)
         {
            _loc39_[1] = _loc39_[2] = _loc39_[3] = 16748704;
         }
         _loc8_ = [Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20079,_loc5_.lv >= _loc5_.getLvMax() ? _loc5_.lv + GlobalLanguageStr.getLanguageStr(20081,_loc5_.getLvMax()) : _loc5_.lv + GlobalLanguageStr.getLanguageStr(20081,_loc5_.getLvMax())),_loc5_.lv >= _loc5_.getLvMax() ? [16764006,16764006,16764006,16764006] : [13777209,16764006,16764006,16764006],100,20),Tools.formatLineX(_loc36_,_loc39_,100,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20088,_loc5_.getSpeed()),param4 == 0 ? _loc38_ : _loc34_,100,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20089,_loc5_.getRange()),param4 == 0 ? _loc38_ : _loc34_,100,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20024,_loc5_.getHpMax(-1,0)),param4 == 0 ? _loc38_ : _loc34_,100,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20025,_loc5_.getDamage(-1,0)),param4 == 0 ? _loc38_ : _loc34_,100,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20026,_loc5_.getDePh(-1,0)),param4 == 0 ? _loc38_ : _loc34_,100,20),Tools
         .formatLineX(GlobalLanguageStr.getLanguageStr(20027,_loc5_.getDeMa(-1,0)),param4 == 0 ? _loc38_ : _loc34_,100,20)];
         var _loc21_:Array = _loc5_.getLoveList();
         if(_loc21_[0] > 0)
         {
            _loc23_ = GlobalFunction.createButtonStarling("UI_love_bg_0000",{
               "t":_loc21_[0] + "",
               "fs":14
            });
            _loc29_ = _loc23_.textBounds;
            _loc23_.textPoint = new Point(-3,-5);
            _loc23_.fontColor = 16777215;
            _loc23_.touchable = false;
            _loc23_.x = MainConfig.$isEA ? 175 : 125;
            _loc23_.y = 155;
            param1.addChild(_loc23_);
         }
         var _loc31_:Array = [];
         _loc12_ = 20;
         _loc13_ = 130;
         _loc32_ = 0;
         while(_loc32_ < _loc8_.length)
         {
            _loc7_ = new HtmlTextField(_loc22_,30,_loc8_[_loc32_],true,GlobalConfig.FONT_0);
            _loc7_.touchable = false;
            _loc7_.hAlign = "left";
            _loc7_.vAlign = "top";
            _loc7_.x = _loc12_;
            _loc7_.y = _loc13_ + _loc32_ * 25;
            param1.addChild(_loc7_);
            _loc32_++;
         }
         _loc8_ = [_loc5_.hpP == 0 ? "" : Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20080,_loc5_.hpP,_loc16_),GlobalTextStyle.COLOR_R_Y_Y_Y,1000,20),_loc5_.apP == 0 ? "" : Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20080,_loc5_.apP,_loc16_),GlobalTextStyle.COLOR_R_Y_Y_Y,1000,20),_loc5_.dePhP == 0 ? "" : Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20080,_loc5_.dePhP,_loc16_),GlobalTextStyle.COLOR_R_Y_Y_Y,1000,20),_loc5_.deMaP == 0 ? "" : Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20080,_loc5_.deMaP,_loc16_),GlobalTextStyle.COLOR_R_Y_Y_Y,1000,20)];
         var _loc17_:LOL_Scale9Button = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20091),88,36,"UI_btn_3_0000",false);
         _loc17_._text.width = 80;
         _loc17_._text.height = 35;
         _loc17_._text.shadowFilter();
         _loc17_.x = param1.x + 10;
         _loc17_.y = param1.y + param1.height + 25;
         _loc17_.style(GlobalConfig.FONT_0,20,16777215);
         param1.addChild(_loc17_);
         _loc18_ = _loc5_.skill0 ? _loc5_.skill0.skillSetData.name + "" : GlobalLanguageStr.getLanguageStr(90021);
         var _loc43_:TextField = GlobalTextStyle.getTextField(_loc18_,20,16777215,"left",100,29);
         if(_loc5_.skill0)
         {
            _loc43_.x = _loc17_.x + _loc17_.width + 5;
         }
         else
         {
            _loc43_.x = _loc17_.x + _loc17_.width + 29;
         }
         _loc43_.y = _loc17_.y + 2;
         param1.addChild(_loc43_);
         if(_loc5_.skill0)
         {
            _loc26_ = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20492,_loc5_.skill0.lv),20,16777215,"left",200,29);
            _loc26_.x = _loc43_.x + _loc43_.textBounds.width + 5;
            _loc26_.y = _loc43_.y;
            param1.addChild(_loc26_);
         }
         var _loc15_:LOL_Scale9Button = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20105),88,36,"UI_btn_3_0000",false);
         _loc15_._text.width = 80;
         _loc15_._text.height = 35;
         _loc15_._text.shadowFilter();
         _loc15_.x = _loc17_.x;
         _loc15_.y = _loc17_.y + 35;
         _loc15_.style(GlobalConfig.FONT_0,20,16777215);
         param1.addChild(_loc15_);
         var _loc19_:Image = GlobalFunction.createImage("UI_tag_leader_0_0000");
         _loc19_.x = _loc15_.x + _loc15_.bounds.width - 10;
         _loc19_.y = _loc15_.y;
         param1.addChild(_loc19_);
         _loc18_ = _loc5_.skill1 ? _loc5_.skill1.skillSetData.name : GlobalLanguageStr.getLanguageStr(90021);
         var _loc44_:TextField = GlobalTextStyle.getTextField(_loc18_,20,16777215,"left",100,29);
         _loc44_.x = _loc19_.x + _loc19_.width + 13;
         _loc44_.y = _loc19_.y + 2;
         param1.addChild(_loc44_);
         var _loc10_:ItemAvatarAward = new ItemAvatarAward();
         if(param4 == 1)
         {
            _loc5_.mData.aid = _loc9_;
            _loc5_.mData.id = _loc9_;
            _loc5_.mData.lv = _loc5_.lv;
            _loc5_.mData.love_exp = _loc5_.loveExp;
            _loc5_.mData.phase = _loc5_.phase;
            _loc5_.mData.hp = _loc5_.hpP;
            _loc5_.mData.ap = _loc5_.apP;
            _loc5_.mData.de_ph = _loc5_.dePhP;
            _loc5_.mData.de_ma = _loc5_.deMaP;
         }
         _loc10_.mFunIndex = 2;
         _loc10_.data = _loc5_.mData;
         _loc10_.x = 10;
         _loc10_.y = 10;
         param1.addChild(_loc10_);
         if(param2 != "a")
         {
            if(param2 == "b")
            {
            }
         }
      }
      
      private function onTouch(param1:TouchEvent) : void
      {
         var _loc3_:String = (param1.currentTarget as Sprite).name;
         var _loc2_:Touch = param1.getTouch(this,"ended");
         if(_loc2_)
         {
            if(_loc3_ == "mBox_a_clip")
            {
               GlobalFunction.setDetaiAvatar(mAvatar_a,false);
            }
            else
            {
               _loc3_ = "mBox_b_clip";
               if(_loc3_)
               {
                  GlobalFunction.setDetaiAvatar(mAvatar_b,false);
               }
            }
         }
      }
   }
}

