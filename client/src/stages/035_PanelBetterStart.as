package com.meng52.game.ui.panel
{
   import com.meng52.game.ui.screen.PanelAvatarSell;
   import com.meng52.display.ProgressBar;
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.module.skill.SkillSet;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.element.ItemBetterElement;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.element.LOL_TextField;
   import com.meng52.game.ui.screen.PanelAvatarBetter;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale3Image;
   import feathers.display.Scale9Image;
   import feathers.textures.Scale3Textures;
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
   
   public class PanelBetterStart extends PanelAvatarBetter
   {
      
      private static const ICON_AVATAR:String = "icon_avatar";
      
      private static const TWEEN_STEP:int = 10;
      
      private var mBox_top:Sprite;
      
      private var mBox:Sprite;
      
      private var mBox_info:Sprite;
      
      private var mBox_other:Sprite;
      
      private var mBox_avatar:Sprite;
      
      private var mImg_info_bg:Scale9Image;
      
      private var mImg_info:Object;
      
      private var mImg_l:Object;
      
      private var mImg_r:Object;
      
      public var mAvatar:Avatar;
      
      public var mBtn:LOL_Scale9Button;
      
      public var mBtn_select:LOL_Scale9Button;
      
      private var mCost_gold:int;
      
      private var mBox_clip:Sprite;
      
      private var mClip_status:int = 0;
      
      private var mClip_statusB:int = 0;
      
      private var mClip_a:MovieClip;
      
      private var mClip_spr:Sprite;
      
      private var mClip_b_num:Number = 0;
      
      private var mExp_bg:Image;
      
      private var mExpCurr_bg:Scale3Image;
      
      private var mExpCurrAdd_bg:Scale3Image;
      
      private var mClip_exp:Boolean = false;
      
      private var mClip_expTime:int = 0;
      
      private var mClip_expLast:int = 0;
      
      private var mClip_expLastMax:int = 0;
      
      private var mClip_expMax:int = 0;
      
      private var mMultiple:int = 0;
      
      private var mExp_old:Number = 0;
      
      private var mExp_add:Number = 0;
      
      private var mSkillUpP:Number = 0;
      
      private var mLove:LOL_Button;
      
      private var upPith:Boolean = false;
      
      private var upSlv:Boolean = false;
      
      private var upLove:Boolean = false;
      
      private var upLv:Boolean = false;
      
      private var isUpdate:Boolean = false;
      
      private var upExp:Boolean = false;
      
      private var _attrs:*;
      
      private var mAtt_name:TextField;
      
      private var mAtt_leadership:TextField;
      
      private var mAtt_lv:TextField;
      
      private var mAtt_life:TextField;
      
      private var mAtt_ap:TextField;
      
      private var mAtt_maxlv:TextFieldHtmlRenderer;
      
      private var mAtt_d0:TextField;
      
      private var mAtt_d1:TextField;
      
      private var lineImg:Quad;
      
      private var skillImg:LOL_Button;
      
      private var _txtSkillA:TextField;
      
      private var _infoSkillA:TextField;
      
      private var _infoSkillBase:TextField;
      
      private var _title_txt:TextField;
      
      private var mAtt_expNext:TextField;
      
      private var mAtt_expAll:TextField;
      
      private var mAtt_goldAll:TextField;
      
      private var mAtt_skillP:TextField;
      
      private var mAtt_loveBtn:LOL_Button;
      
      private var mAtt_icon:Sprite;
      
      private var mLove_bar:ProgressBar;
      
      private var _pith_arr:Array = [];
      
      private var _arr:Array = [];
      
      private var mFoster:LOL_TextField;
      
      private var _quad:Quad;

      private var mSwallowViewEpoch:uint = 0;

      private function refreshGlobalGold() : void
      {
         var _game:Object = GlobalData.$mGameClassObject;
         if(_game != null && _game.mLayoutUITop != null && _game.mLayoutUITop.mPanelTopMain != null && _game.mLayoutUITop.mPanelTopMain.stage != null)
         {
            _game.mLayoutUITop.mPanelTopMain.updateGold();
         }
      }
      
      public function PanelBetterStart()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         GlobalData.$mEventDispatcher.addEventListener("update_avatar_better_start",onMainEvent);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(20076));
         this.mBox = new Sprite();
         this.mImg_info_bg = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",560,400,new Rectangle(110,55,70,20));
         this.mBox.addChild(this.mImg_info_bg);
         this.mBox.width = this.mImg_info_bg.width;
         this.mBox.height = this.mImg_info_bg.height;
         this.addChild(this.mBox);
         this.mBox.x = this.mImg9_baseBg.x + int((this.mImg9_baseBg.width - this.mBox.width) * 0.5);
         this.mBox.y = this.mImg9_baseBg.y + 210;
         mImg_info = {
            "width":316,
            "height":324,
            "x":40,
            "y":5
         };
         mImg_l = {
            "width":115,
            "height":300,
            "x":mImg_info.x + mImg_info.width + 10,
            "y":35
         };
         mImg_r = {
            "width":115,
            "height":300,
            "x":mImg_l.x + mImg_l.width + 10,
            "y":35
         };
         this.mBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20085),150,70,"UI_btn_normalFun_0000");
         this.mBtn.shadowFilter();
         this.mBtn.x = mImg_info_bg.x + mImg_info_bg.width - mBtn.width - 75 - 35;
         this.mBtn.y = int(this.mImg_info_bg.x + this.mImg_info_bg.height + 10);
         this.mBtn.addEventListener("triggered",this.onTRIGGERED_btn);
         this.mBox.addChild(this.mBtn);
         this.mBtn_select = new LOL_Scale9Button("",150,70,"UI_btn_normalFun_0000");
         mBtn_select.x = mImg_info_bg.x + 75 + 35;
         mBtn_select.y = this.mBtn.y;
         mBtn_select.addEventListener("triggered",this.onTRIGGERED_select);
         mBox.addChild(mBtn_select);
         onMainEvent(null);
      }
      
      override public function onTRIGGERED_closePanel(param1:Event) : void
      {
         super.onTRIGGERED_closePanel(param1);
         GlobalData.$mEventDispatcher.dispatchEventWith("change_team_member",false,GlobalData.$tempTeamSelect);
         GlobalData.$mEventDispatcher.dispatchEventWith("update_avatar_better");
         GlobalData.$mEventDispatcher.dispatchEventWith("update_team_avatar_list");
         GlobalData.$mEventDispatcher.dispatchEventWith("update_avatar_starup");
      }
      
      private function onMainEvent(param1:Event) : void
      {
         checkBtn_selectStatus();
         update();
      }
      
      private function onTRIGGERED_select(param1:Event) : void
      {
         if(GlobalData.$tempAvatarBetterArr.length > 0)
         {
            GlobalFunction.clearAvatarBetterItems();
         }
         else
         {
            checkBetterFood();
         }
         checkBtn_selectStatus();
         setUI(true);
      }
      
      private function checkBtn_selectStatus() : void
      {
         var _loc1_:String = "";
         if(GlobalData.$tempAvatarBetterArr.length > 0)
         {
            _loc1_ = GlobalLanguageStr.getLanguageStr(20228);
         }
         else
         {
            _loc1_ = GlobalLanguageStr.getLanguageStr(90990);
         }
         if(mBtn_select)
         {
            mBtn_select.text = _loc1_;
            mBtn_select.shadowFilter();
         }
      }
      
      private function onTRIGGERED_btn(param1:Event) : void
      {
         var _loc2_:Object = null;
         var _loc3_:Array = GlobalData.$tempAvatarBetterArr;
         if(GlobalData.$userData.attrs.avatar_culture != null)
         {
            if(GlobalData.$userData.attrs.avatar_culture.aid == mAvatar.mData.aid || GlobalData.$userData.attrs.avatar_culture.eqid == mAvatar.mData.aid)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10182));
               return;
            }
         }
         if(GlobalData.$tempAvatarBetterArr.length == 0)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90034),true);
            return;
         }
         if(this.mCost_gold > GlobalData.$userData.gold)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10023),false,"A_6999_3");
         }
         else if(this.mAvatar.slv >= GlobalData.$mConfig_simple.slv_config[0] && mSkillUpP > 0)
         {
            _loc2_ = {
               "ok":service_swallow,
               "no":GlobalFunction.functionNull
            };
            GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90208),GlobalTextStyle.COLOR_W_Y_Y_G),_loc2_);
         }
         else if(this.mAvatar.lv >= this.mAvatar.getLvMax())
         {
            _loc2_ = {
               "ok":service_swallow,
               "no":GlobalFunction.functionNull,
               "aid":mAvatar.avatarData.id
            };
            GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90053),GlobalTextStyle.COLOR_W_Y_Y_G),_loc2_);
         }
         else
         {
            this.service_swallow();
         }
      }
      
      private function service_swallow() : void
      {
         if(GlobalData.$tempAvatarBetterArr.length > 0)
         {
            var _aid:String = GlobalData.$tempAvatarBetter.id;
            var _aids:Array = GlobalData.$tempAvatarBetterArr.concat();
            var _epoch:uint = mSwallowViewEpoch;
            var _cost:int = mCost_gold;
            SendServiceAMFFun.send_user_swallow_avatar(function(param1:Object):void
            {
               re_swallow_avatar(param1,_aid,_aids,_epoch);
            },{
               "aid":_aid,
               "aids":_aids.concat(),
               "gold":_cost
            });
         }
         else
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90034),true);
         }
      }
      
      private function setClip() : void
      {
         var _loc3_:ItemBetterElement = null;
         var _loc5_:uint = 0;
         var _loc2_:int = this.mBox_avatar.numChildren;
         mBox_clip = new Sprite();
         var _loc4_:Sprite = this.mBox_top.getChildByName("icon_avatar") as Sprite;
         var _loc1_:Rectangle = null;
         _loc5_ = 0;
         while(_loc5_ < _loc2_)
         {
            _loc3_ = this.mBox_avatar.getChildAt(_loc5_) as ItemBetterElement;
            if(_loc3_.data["id"] != null)
            {
               _loc1_ = _loc4_.getBounds(_loc3_);
               _loc3_.setClipFun(_loc1_,setClip_b,_loc5_ * 3,5);
            }
            _loc5_++;
         }
      }

      private function isSameSwallowSelection(param1:String, param2:Array) : Boolean
      {
         var _loc3_:int = 0;
         if(GlobalData.$tempAvatarBetter == null || GlobalData.$tempAvatarBetter.id != param1 || !(GlobalData.$tempAvatarBetterArr is Array))
         {
            return false;
         }
         var _loc4_:Array = GlobalData.$tempAvatarBetterArr as Array;
         if(_loc4_.length != param2.length)
         {
            return false;
         }
         _loc3_ = 0;
         while(_loc3_ < param2.length)
         {
            if(_loc4_[_loc3_] != param2[_loc3_])
            {
               return false;
            }
            _loc3_++;
         }
         return true;
      }
      
      public function setClip_b() : void
      {
         var _loc2_:Sprite = null;
         var _loc1_:Rectangle = null;
         if(mClip_status == 0)
         {
            this.mClip_status = 1;
            this.setJuggler();
            _loc2_ = this.mBox_top.getChildByName("icon_avatar") as Sprite;
            _loc1_ = _loc2_.getBounds(this);
            _attrs = _attrs = {
               "id":"e003",
               "x":5,
               "y":0,
               "sc":1.4,
               "a":0.5,
               "rate":5
            };
            _attrs.par = this.mJugglerBox;
            DisplayTools.addEffectOne(_attrs);
            this.setChildIndex(mJugglerBox,this.numChildren - 1);
            this.mJugglerBox.x = int(_loc1_.x + _loc1_.width * 0.5);
            this.mJugglerBox.y = int(_loc1_.y + _loc1_.height * 0.5);
         }
      }
      
      public function setClip_super() : void
      {
         if(!stage)
         {
            return;
         }
         if(mMultiple <= 1)
         {
            return;
         }
         var _loc5_:Sprite = this.mBox_top.getChildByName("icon_avatar") as Sprite;
         var _loc3_:Rectangle = _loc5_.getBounds(stage);
         var _loc1_:int = int(_loc3_.x + _loc3_.width * 0.5) + 5;
         var _loc2_:int = int(_loc3_.y + _loc3_.height * 0.5) + 2;
         var _loc4_:Number = 1 + mMultiple * 0.4;
         LayoutUIAnimation.getOnlyExample().popEffect({
            "id":"e026",
            "x":_loc1_,
            "y":_loc2_,
            "sc":_loc4_,
            "s":{"id":"skill2"},
            "rate":5
         });
      }
      
      override public function onENTER_FRAME_juggler(param1:EnterFrameEvent) : void
      {
         var step:int = 0;
         while(step < 5 && this.mJuggler && stage != null)
         {
            advanceUpgradeFrame(param1);
            step++;
         }
      }

      private function advanceUpgradeFrame(param1:EnterFrameEvent) : void
      {
         var _loc6_:Boolean = false;
         var _loc3_:int = 0;
         var _loc7_:String = null;
         var _loc5_:Number = NaN;
         var _loc4_:Number = NaN;
         var _loc2_:Number = NaN;
         if(this.mJuggler)
         {
            this.mJuggler.advanceTime(param1.passedTime);
            if(_attrs)
            {
               if(_attrs.isComplete)
               {
                  this.mClip_status += 1;
                  if(this.mClip_status == 4)
                  {
                     this.mClip_status = 5;
                     _attrs.removeFromParent(true);
                     this.mJuggler.remove(_attrs);
                  }
                  else if(this.mClip_status < 4)
                  {
                  }
               }
            }
            if(this.mClip_statusB == 3)
            {
               if(this.mClip_spr == null || this.mClip_spr.stage == null)
               {
                  this.mClip_statusB = 4;
               }
            }
            if(this.mClip_statusB == 2)
            {
               _loc6_ = false;
               if(this.mMultiple > 1)
               {
                  if(mAvatar.lv < mAvatar.getLvMax())
                  {
                     _loc6_ = true;
                  }
               }
               if(!_loc6_)
               {
                  this.mClip_statusB += 15;
               }
               else
               {
                  _loc3_ = mMultiple == 3 ? 2 : 1;
                  _loc7_ = _loc3_ == 2 ? "50003" : "50004";
                  mClip_spr = LayoutUIAnimation.getOnlyExample().popSuperWord(_loc7_,_loc3_,0.65,0,0,5);
                  this.mClip_statusB += 1;
               }
            }
            if(this.mClip_statusB >= 4)
            {
               this.mClip_statusB += 1;
               if(this.mClip_statusB >= 15)
               {
                  this.mClip_statusB = 0;
                  setClip_super();
                  this.mJuggler.purge();
                  this.delJuggler();
                  this.update();
               }
            }
            if(this.mClip_statusB == 1)
            {
               if(!mClip_exp)
               {
                  _loc5_ = 0;
                  _loc4_ = 0;
                  if(mAvatar.lv >= mAvatar.getLvMax())
                  {
                     mClip_expTime = 0;
                  }
                  if(mClip_expTime > 0)
                  {
                     _loc5_ = mClip_expMax / 10;
                     if(this.mExpCurr_bg.width < mClip_expMax)
                     {
                        _loc4_ = this.mExpCurr_bg.width + _loc5_;
                        _loc4_ = Number(_loc4_ > mClip_expMax ? mClip_expMax : _loc4_);
                        this.mExpCurr_bg.width = _loc4_;
                        SoundManager.getOnlyExample().playAvatar("avatarExpUp");
                     }
                     else
                     {
                        mClip_expTime -= 1;
                        this.mExpCurr_bg.width = 10;
                        mAvatar.lv++;
                        mAvatar.exp = 0;
                        if(mAvatar.lv >= mAvatar.getLvMax())
                        {
                           SoundManager.getOnlyExample().playSound("skill1");
                        }
                        else
                        {
                           SoundManager.getOnlyExample().playSound("avatarLvUp");
                        }
                        setUI(false);
                     }
                  }
                  else
                  {
                     SoundManager.getOnlyExample().playAvatar("avatarExpUp");
                     _loc2_ = mClip_expMax * (mClip_expLast / mClip_expLastMax);
                     _loc5_ = _loc2_ / 10;
                     if(this.mExpCurr_bg.width < _loc2_)
                     {
                        _loc4_ = this.mExpCurr_bg.width + _loc5_;
                        _loc4_ = Number(_loc4_ > mClip_expMax ? mClip_expMax : _loc4_);
                        _loc4_ = _loc4_ > _loc2_ ? _loc2_ : _loc4_;
                        this.mExpCurr_bg.width = _loc4_;
                     }
                     else
                     {
                        mClip_exp = true;
                        this.mClip_statusB += 1;
                     }
                  }
               }
            }
         }
      }
      
      private function re_swallow_avatar(param1:Object, param2:String, param3:Array, param4:uint) : void
      {
         if(GlobalFunction.isMalformedProfileReceipt(param1))
         {
            return;
         }
         if(GlobalFunction.isLegacyProfileReceipt(param1))
         {
            RpcStaticCall.$remoting.reportDiagnostic("PROFILE_RECEIPT_LEGACY|method=user.swallow_avatar");
         }
         var _loc8_:* = 0;
         var _loc5_:Number = Number(param1.data.gold);
         var _loc6_:String = param2;
         var _loc3_:Array = param3;
         var _loc9_:Avatar = new Avatar(_loc6_);
         refreshGlobalGold();
         if(isSameSwallowSelection(_loc6_,_loc3_))
         {
            GlobalFunction.clearAvatarBetterItems();
         }
         if(param4 != mSwallowViewEpoch || this.stage == null || mAvatar == null || mAvatar.mData.aid != _loc6_)
         {
            _loc9_.clear();
            GlobalData.$mEventDispatcher.dispatchEventWith("update_dn_team_ui");
            return;
         }
         this.setClip();
         GlobalData.$tempAvatarBetter = param1.data.avatar;
         GlobalData.$tempAvatarBetter["id"] = _loc6_;
         var _loc2_:Avatar = new Avatar(_loc6_,param1.data.avatar);
         var _loc7_:Number = _loc2_.getAllExp();
         var _loc4_:Number = (_loc7_ - mExp_old) / mExp_add;
         if(_loc4_ <= 0 || isNaN(_loc4_))
         {
            this.mMultiple = 1;
         }
         else
         {
            this.mMultiple = _loc4_ >= 3 ? 3 : Math.round(_loc4_);
         }
         upPith = _loc2_.getPithNum() > _loc9_.getPithNum();
         upSlv = _loc2_.slv > _loc9_.slv;
         upLove = _loc2_.loveExp > _loc9_.loveExp;
         upLv = _loc2_.lv > _loc9_.lv;
         upExp = _loc2_.exp > _loc9_.exp;
         _loc2_.clear();
         _loc9_.clear();
         GlobalData.$mGameClassObject.touchable = false;
         this.mClip_statusB += 1;
         GuideMaster.getOnlyExample().guideWait();
         checkBtn_selectStatus();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         mSwallowViewEpoch += 1;
         GlobalFunction.clearAvatarBetterItems();
         GlobalData.$mEventDispatcher.removeEventListener("update_avatar_better_start",onMainEvent);
         if(mClip_a)
         {
            mClip_a.removeFromParent(true);
         }
         if(mClip_spr)
         {
            mClip_spr.removeFromParent(true);
         }
         this.delUI();
         if(mAvatar)
         {
            mAvatar.clear();
         }
         if(mBox)
         {
            StarlingTools.removeChildrenClear(mBox);
            mBox.removeFromParent(true);
         }
         if(mBox_top)
         {
            StarlingTools.removeChildrenClear(mBox_top);
            mBox_top.removeFromParent(true);
         }
         super.onREMOVED_FROM_STAGE(param1);
         mClip_a = null;
         mClip_spr = null;
         mAvatar = null;
         mBox = null;
         mBox_top = null;
         GuideMaster.getOnlyExample().nextGuideStep();
         GlobalData.$mEventDispatcher.dispatchEventWith("update_dn_team_ui");
         GlobalData.$mEventDispatcher.dispatchEventWith("change_team_member",false,GlobalData.$tempAvatarBetter);
      }
      
      private function delUI(param1:Boolean = true) : void
      {
         if(param1 && this.mAvatar != null)
         {
            this.mAvatar.clear();
            this.mAvatar = null;
         }
         if(this.mExp_bg)
         {
            this.mExp_bg.removeFromParent(true);
         }
         if(this.mExpCurr_bg)
         {
            this.mExpCurr_bg.removeFromParent(true);
         }
         if(this.mExpCurrAdd_bg)
         {
            this.mExpCurrAdd_bg.removeFromParent(true);
         }
         if(this.mBox_info)
         {
            StarlingTools.removeChildrenClear(this.mBox_info);
            this.mBox_info.removeFromParent(true);
         }
         if(this.mBox_other)
         {
            StarlingTools.removeChildrenClear(this.mBox_other);
            this.mBox_other.removeFromParent(true);
         }
         if(this.mBox_avatar)
         {
            StarlingTools.removeChildrenClear(this.mBox_avatar);
            this.mBox_avatar.removeFromParent(true);
         }
         this.mBox_info = null;
         this.mBox_other = null;
         this.mBox_avatar = null;
         this.mExpCurr_bg = null;
         this.mExp_bg = null;
         this.mExpCurrAdd_bg = null;
         mAtt_name = null;
         mAtt_lv = null;
         mAtt_life = null;
         mAtt_ap = null;
         mAtt_d0 = null;
         mAtt_d1 = null;
         mAtt_expNext = null;
         mAtt_expAll = null;
         mAtt_goldAll = null;
         mAtt_skillP = null;
      }
      
      override public function update() : void
      {
         this.setUI(true);
         GuideMaster.getOnlyExample().nextGuideStep();
      }
      
      private function setUI(param1:Boolean) : void
      {
         var _loc21_:Object = null;
         var _loc16_:Number = NaN;
         var _loc13_:String = null;
         var _loc23_:int = 0;
         var _loc24_:int = 0;
         var _loc5_:TextField = null;
         var _loc7_:Number = NaN;
         var _loc15_:Image = null;
         var _loc19_:Array = null;
         var _loc22_:* = null;
         var _loc20_:Array = null;
         var _loc30_:Array = null;
         var _loc11_:Scale3Textures = null;
         var _loc10_:Scale3Textures = null;
         if(param1)
         {
            GlobalData.$mGameClassObject.touchable = true;
            this.mClip_status = 0;
            this.mClip_statusB = 0;
            this.mClip_b_num = 0;
            this.mMultiple = 0;
            mClip_exp = false;
            _loc21_ = GlobalData.$tempAvatarBetter;
            mAvatar = new Avatar(_loc21_.id);
            _loc16_ = 0;
            if(upLv)
            {
               if(mAvatar.lv >= mAvatar.getLvMax())
               {
                  LayoutUIAnimation.getOnlyExample().popSuperWord("50005",1,0.64,_loc16_,0,5);
                  _loc16_ += 0.6;
               }
            }
            if(upPith)
            {
               _loc16_ += 0.8;
            }
            if(upSlv)
            {
               if(mAvatar.slv >= GlobalData.$mConfig_simple.slv_config[0])
               {
                  LayoutUIAnimation.getOnlyExample().popSuperWord("50011",2,0.52,_loc16_,0,5);
               }
               else
               {
                  LayoutUIAnimation.getOnlyExample().popSuperWord("50010",2,0.52,_loc16_,0,5);
               }
               _loc16_ += 1.2;
            }
            if(upLove)
            {
               if(mAvatar.getLoveList()[0] >= GlobalData.$mConfig_simple.love_up[0])
               {
                  LayoutUIAnimation.getOnlyExample().popSuperWord("50013",2,0.44,_loc16_,0,5);
               }
               else
               {
                  LayoutUIAnimation.getOnlyExample().popSuperWord("50012",2,0.44,_loc16_,0,5);
               }
               _loc16_ += 1.2;
            }
            upPith = upSlv = upLove = upLv = false;
         }
         var _loc2_:Avatar = this.mAvatar;
         var _loc8_:Number = Number(GlobalData.$mConfig_simple.culture.culture_pith);
         var _loc18_:Number = 110;
         if(mBox_top == null)
         {
            this.mBox_top = new Sprite();
            this.addChild(mBox_top);
            mBox_top.x = this.mBox.x + 10;
            mBox_top.y = this.mBox.y - 120;
            mAtt_name = GlobalTextStyle.getTextField(_loc2_.avatarData.name,20,16764006,"center",_loc18_ + 20,35);
            mAtt_leadership = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20090,_loc2_.getLeadership().toString()),20,16777215,"center",MainConfig.$isEA ? _loc18_ + 50 : _loc18_,35);
            mAtt_lv = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20079,_loc2_.lv),20,16777215,"left",_loc18_,35);
            mAtt_maxlv = GlobalTextStyle.getHtmlTextRenderer();
            mAtt_maxlv.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20081,_loc2_.getLvMax()),[13777209,13777209,13777209,13777209],15,15);
            this.mBox_top.addChild(mAtt_name);
            this.mBox_top.addChild(mAtt_leadership);
            this.mBox_top.addChild(mAtt_lv);
            this.mBox_top.addChild(mAtt_maxlv);
         }
         if(param1)
         {
            if(mAtt_icon)
            {
               mAtt_icon.removeFromParent(true);
            }
            mAtt_icon = null;
            mAtt_icon = this.mAvatar.getAvatarRes();
            mAtt_icon.name = "icon_avatar";
            this.mBox_top.addChild(mAtt_icon);
         }
         _loc2_.initFightAttr();
         _loc2_.initFightAttr();
         if(mBox_info == null)
         {
            mBox_info = new Sprite();
            mBox_info.x = mImg_info.x;
            mBox_info.y = mImg_info.y;
            mBox.addChild(mBox_info);
            mAtt_life = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20024,_loc2_.getHpMax(-1,0)),20,4926491,"left",_loc18_ + 20,35,GlobalConfig.FONT_1);
            mAtt_ap = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20025,_loc2_.getDamage(-1,0)),20,4926491,"left",_loc18_ + 20,35,GlobalConfig.FONT_1);
            mAtt_d0 = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20026,_loc2_.getDePh(-1,0)),20,4926491,"left",_loc18_ + 20,35,GlobalConfig.FONT_1);
            mAtt_d1 = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20027,_loc2_.getDeMa(-1,0)),20,4926491,"left",_loc18_ + 20,35,GlobalConfig.FONT_1);
            _loc23_ = _loc2_.getCultivationDisplayScale();
            mFoster = new LOL_TextField(GlobalLanguageStr.getLanguageStr(90652,_loc2_.getPithNum() * _loc23_),_loc18_ + 50,30);
            mFoster.fontSize = 20;
            mFoster.fontColor = 4926491;
            mFoster.hAlign = "left";
            _arr = [mAtt_life,mAtt_ap,mAtt_d0,mAtt_d1];
            _loc24_ = 0;
            while(_loc24_ < _arr.length)
            {
               _loc5_ = _arr[_loc24_];
               _loc5_.touchable = false;
               _loc5_.x = -5;
               _loc5_.y = 15 + _loc24_ % 4 * 25;
               mBox_info.addChild(_loc5_);
               _loc24_++;
            }
            mBox_info.addChild(mFoster);
            mFoster.x = -5;
            mFoster.y = 115;
            mExp_old = this.mAvatar.getAllExp(-1,true);
            mAtt_name.hAlign = mAtt_leadership.hAlign = mAtt_lv.hAlign = "left";
            mAtt_name.x = mAtt_lv.x = mAtt_leadership.x = mAtt_icon.x + mAtt_icon.width;
            mAtt_name.y = mAtt_icon.y + 10;
            mAtt_leadership.y = mAtt_name.y + mAtt_name.height - 3;
            mAtt_lv.y = mAtt_leadership.y + mAtt_leadership.height - 3;
            mAtt_maxlv.x = mAtt_lv.x;
            mAtt_maxlv.y = mAtt_lv.y + mAtt_lv.height - 10;
            lineImg = Tools.newQuad(mImg_info_bg.width - 80,2);
            lineImg.color = 10120765;
            lineImg.y = mAtt_d1.y + mAtt_d1.height + 25;
            mBox_info.addChild(lineImg);
            _title_txt = GlobalFunction.createTextField(200,30,GlobalLanguageStr.getStr(90397),"",20,1513239);
            _title_txt.hAlign = "left";
            _title_txt.x = lineImg.x - 5;
            _title_txt.y = lineImg.y + 5;
            mBox_info.addChild(_title_txt);
            skillImg = GlobalFunction.createButton_5(GlobalLanguageStr.getStr(20091),"UI_btn_3_0000",true,false,20);
            skillImg.x = this.mAtt_life.width + 20 + 65;
            skillImg.y = this.mAtt_life.y;
            skillImg.fontColor = 16777215;
            skillImg.name = mAvatar.skill0 == null ? "" : mAvatar.skill0.skillSetData.id;
            skillImg.addEventListener("triggered",onSkill);
            mBox_info.addChild(skillImg);
            _loc13_ = this.mAvatar.skill0 ? this.mAvatar.skill0.skillSetData.name + " " + GlobalLanguageStr.getLanguageStr(20492,this.mAvatar.skill0.lv) : GlobalLanguageStr.getLanguageStr(90021);
            _txtSkillA = GlobalTextStyle.getTextField(_loc13_,20,1513239,"left",200,35);
            _txtSkillA.x = skillImg.x + skillImg.width + 3;
            _txtSkillA.y = skillImg.y + 5;
            mBox_info.addChild(_txtSkillA);
            _loc13_ = "";
            _loc7_ = mImg_info_bg.width * 0.5;
            _infoSkillA = GlobalTextStyle.getTextField(_loc13_,15,4926491,"left",_loc7_,24 * 3,GlobalConfig.FONT_1);
            _infoSkillA.x = skillImg.x + 20 - 20;
            _infoSkillA.y = skillImg.y + skillImg.height;
            _infoSkillA.visible = this.mAvatar.skill0 != null;
            mBox_info.addChild(_infoSkillA);
            _loc13_ = this.mAvatar.skill0 == null ? GlobalLanguageStr.getStr(31020) : GlobalLanguageStr.getLanguageStr(25021,this.mAvatar.skill0.skillSetData.warmup,this.mAvatar.skill0.skillSetData.cooldown);
            _infoSkillBase = GlobalTextStyle.getTextField(_loc13_,15,1513239,"right",_loc7_,24,GlobalConfig.FONT_1);
            _infoSkillBase.x = _infoSkillA.x - 10;
            _infoSkillBase.y = _infoSkillA.y + _infoSkillA.height;
            _infoSkillBase.visible = this.mAvatar.skill0 != null;
            mBox_info.addChild(_infoSkillBase);
            _quad = new Quad(160,130);
            _quad.x = mAtt_life.x;
            _quad.y = mAtt_life.y;
            _quad.alpha = 0.01;
            mBox_info.addChild(_quad);
         }
         else
         {
            mAtt_lv.text = GlobalLanguageStr.getLanguageStr(20079,_loc2_.lv);
            mAtt_leadership.text = GlobalLanguageStr.getLanguageStr(20090,_loc2_.getLeadership());
            mAtt_life.text = GlobalLanguageStr.getLanguageStr(20024,_loc2_.getHpMax(-1,0));
            mAtt_ap.text = GlobalLanguageStr.getLanguageStr(20025,_loc2_.getDamage(-1,0));
            mAtt_d0.text = GlobalLanguageStr.getLanguageStr(20026,_loc2_.getDePh(-1,0));
            mAtt_d1.text = GlobalLanguageStr.getLanguageStr(20027,_loc2_.getDeMa(-1,0));
            _loc23_ = _loc2_.getCultivationDisplayScale();
            mFoster.text = GlobalLanguageStr.getLanguageStr(90652,_loc2_.getPithNum() * _loc23_);
            mExp_old = this.mAvatar.getAllExp(-1,true);
            _loc13_ = this.mAvatar.skill0 ? this.mAvatar.skill0.skillSetData.name + "    " + GlobalLanguageStr.getLanguageStr(20079,this.mAvatar.skill0.lv) : GlobalLanguageStr.getLanguageStr(90021);
            _txtSkillA.text = _loc13_;
            _loc13_ = "";
            _infoSkillA.text = _loc13_;
            _infoSkillA.visible = this.mAvatar.skill0 != null;
            _loc13_ = this.mAvatar.skill0 ? GlobalLanguageStr.getLanguageStr(25021,this.mAvatar.skill0.skillSetData.warmup,this.mAvatar.skill0.skillSetData.cooldown) : GlobalLanguageStr.getLanguageStr(90021);
            _infoSkillBase.text = _loc13_;
            _infoSkillBase.visible = this.mAvatar.skill0 != null;
            while(_pith_arr.length > 0)
            {
               _loc15_ = _pith_arr.pop();
               if(_loc15_)
               {
                  _loc15_.removeFromParent(true);
               }
            }
         }
         var _loc14_:Object = GlobalFunction.getBetterGive(GlobalData.$tempAvatarBetter);
         var _loc26_:Number = 0;
         if(mAtt_loveBtn == null)
         {
            _loc19_ = mAvatar.getLoveList();
            if(_loc19_[0] > 0)
            {
               mAtt_loveBtn = GlobalFunction.createButtonStarling("UI_love_bg_0000",{
                  "t":_loc19_[0] + "",
                  "fs":14
               });
               mAtt_loveBtn.fontColor = 16777215;
               mAtt_loveBtn.textPoint = new Point(-3,-5);
               mAtt_loveBtn.x = MainConfig.$isEA ? mAtt_leadership.x + 160 : mAtt_leadership.x + 90;
               mAtt_loveBtn.y = mAtt_leadership.y + 2;
               mBox_top.addChild(mAtt_loveBtn);
               mLove_bar = new ProgressBar(GlobalFunction.getTexture("UI_love_bar_0_0000"),GlobalFunction.getTexture("UI_love_bar_1_0000"),{
                  "f":3,
                  "s":4,
                  "x":3,
                  "y":3
               });
               _loc26_ = _loc19_[1] / _loc19_[2];
               _loc26_ = _loc26_ >= 1 ? 1 : _loc26_;
               mLove_bar.x = mAtt_loveBtn.x + mAtt_loveBtn.width;
               mLove_bar.y = mAtt_loveBtn.y + 8;
               mLove_bar.setRatio(_loc26_);
               mBox_top.addChild(mLove_bar);
               mLove_bar.touchable = true;
               mAtt_loveBtn.addEventListener("touch",onTRIGGERED_love);
               mLove_bar.addEventListener("touch",onTRIGGERED_love);
               mAtt_leadership.color = 16742263;
            }
            else
            {
               mAtt_leadership.color = 16777215;
            }
         }
         else if(param1)
         {
            _loc19_ = mAvatar.getLoveList();
            mAtt_loveBtn.text = _loc19_[0] + "";
            _loc26_ = _loc19_[1] / _loc19_[2];
            _loc26_ = _loc26_ >= 1 ? 1 : _loc26_;
            mLove_bar.setRatio(_loc26_);
         }
         var _loc6_:Number = this.mAvatar.getNextExp();
         var _loc27_:int = Math.max(0,_loc6_ >= 2147483647 ? 0 : _loc6_ - GlobalData.$tempAvatarBetter.exp);
         mExp_add = _loc14_.exp;
         mSkillUpP = 0;
         mSkillUpP = GlobalFunction.getSkillProbability(GlobalData.$tempAvatarBetter);
         var _loc25_:String = GlobalLanguageStr.getLanguageStr(2004,mSkillUpP);
         var _loc9_:Array = GlobalData.$mConfig_simple.slv_config as Array;
         if(_loc2_.skill0 == null || _loc2_.skill0 && _loc2_.skill0.lv >= _loc9_[0])
         {
            _loc25_ = "--";
         }
         if(this.mBox_other == null)
         {
            this.mBox_other = new Sprite();
            this.mBox.addChild(this.mBox_other);
            _loc18_ = 250;
            mAtt_expNext = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90400,_loc27_),20,4926491,"left",_loc18_,35);
            mAtt_expAll = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90398,mExp_add),20,4926491,"left",_loc18_,35);
            mAtt_goldAll = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90399,_loc14_.gold),20,4926491,"left",_loc18_,35);
            mAtt_skillP = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90401,_loc25_),20,4926491,"left",_loc18_,35);
            this.mBox_other.addChild(mAtt_expNext);
            this.mBox_other.addChild(mAtt_expAll);
            this.mBox_other.addChild(mAtt_goldAll);
            this.mBox_other.addChild(mAtt_skillP);
            _loc20_ = [0,this.mImg_info_bg.x + this.mImg_info_bg.width * 0.5];
            _loc30_ = [15,45];
            mAtt_expAll.x = _loc20_[0] - 30;
            mAtt_expAll.y = _loc30_[0];
            mAtt_goldAll.x = _loc20_[1] - 45;
            mAtt_goldAll.y = mAtt_expAll.y;
            mAtt_expNext.x = mAtt_expAll.x;
            mAtt_expNext.y = _loc30_[1];
            mAtt_skillP.x = mAtt_goldAll.x;
            mAtt_skillP.y = mAtt_expNext.y;
            mBox_other.x = 60;
            mBox_other.y = this.mImg_info_bg.height - mBox_other.height - 30;
         }
         else if(param1)
         {
            mAtt_expNext.text = GlobalLanguageStr.getLanguageStr(90400,_loc27_);
            mAtt_expAll.text = GlobalLanguageStr.getLanguageStr(90398,mExp_add);
            mAtt_goldAll.text = GlobalLanguageStr.getLanguageStr(90399,_loc14_.gold);
            mAtt_skillP.text = GlobalLanguageStr.getLanguageStr(90401,_loc25_);
         }
         this.mCost_gold = _loc14_.gold;
         if(this.mExp_bg == null)
         {
            this.mExp_bg = GlobalFunction.createImage("UI_bar_exp_6_0000");
            this.mExp_bg.x = this.mAtt_lv.x + 90;
            this.mExp_bg.y = this.mAtt_lv.y + 5;
            this.mBox_top.addChild(this.mExp_bg);
         }
         var _loc28_:Object = {
            "f":4,
            "s":6,
            "x":1,
            "y":0
         };
         var _loc29_:Number;
         mClip_expMax = _loc29_ = this.mExp_bg.width - 8;
         if(mExpCurr_bg == null && mExpCurrAdd_bg == null)
         {
            _loc11_ = new Scale3Textures(GlobalFunction.getTexture("UI_bar_exp_2_0000"),_loc28_.f,_loc28_.s);
            _loc10_ = new Scale3Textures(GlobalFunction.getTexture("UI_bar_exp_2_1_0000"),_loc28_.f,_loc28_.s);
            this.mExpCurr_bg = new Scale3Image(_loc11_);
            this.mExpCurrAdd_bg = new Scale3Image(_loc10_);
            this.mBox_top.addChild(this.mExpCurrAdd_bg);
            this.mBox_top.addChild(this.mExpCurr_bg);
         }
         this.mExpCurr_bg.x = this.mExp_bg.x + 3;
         this.mExpCurr_bg.y = this.mExp_bg.y + 2;
         this.mExpCurrAdd_bg.x = this.mExpCurr_bg.x;
         this.mExpCurrAdd_bg.y = this.mExpCurr_bg.y;
         var _loc12_:Number = GlobalData.$tempAvatarBetter.exp / _loc6_;
         _loc12_ = _loc12_ > 1 ? 1 : _loc12_;
         if(mAvatar.lv >= mAvatar.getLvMax())
         {
            _loc12_ = 1;
         }
         var _loc4_:Number = 1;
         var _loc3_:Number = _loc12_ * _loc29_;
         _loc3_ = _loc3_ < _loc4_ ? _loc4_ : _loc3_;
         this.mExpCurr_bg.width = _loc3_ + 3;
         var _loc17_:Number = (GlobalData.$tempAvatarBetter.exp + _loc14_.exp) / _loc6_;
         _loc17_ = _loc17_ > 1 ? 1 : _loc17_;
         _loc3_ = _loc17_ * _loc29_;
         this.mExpCurrAdd_bg.width = _loc3_ < _loc4_ ? _loc4_ : _loc3_ + 3;
         if(param1)
         {
            mClip_expTime = 0;
            this.checkExpToClip(GlobalData.$tempAvatarBetter.exp + _loc14_.exp,this.mAvatar,this.mAvatar.lv);
            this.setAvatarUIGroup();
         }
      }
      
      private function quadPith_Touch(param1:TouchEvent) : void
      {
         var _loc2_:Avatar = null;
         var _loc3_:String = null;
         var _loc4_:String = null;
         var _loc5_:Touch = param1.getTouch(this,"ended");
         if(_loc5_)
         {
            _loc2_ = this.mAvatar;
            _loc3_ = GlobalLanguageStr.getLanguageStr(20226);
            _loc4_ = GlobalLanguageStr.getLanguageStr(90521,_loc2_.hpP,_loc2_.getCultivationStatGain("hp",_loc2_.hpP),_loc2_.apP,_loc2_.getCultivationStatGain("ap",_loc2_.apP),_loc2_.dePhP,_loc2_.getCultivationStatGain("de_ph",_loc2_.dePhP),_loc2_.deMaP,_loc2_.getCultivationStatGain("de_ma",_loc2_.deMaP));
            _loc3_ += "\n" + _loc4_;
            _loc3_ = Tools.formatLineX(_loc3_,GlobalTextStyle.COLOR_W_Y_Y_G);
            GlobalFunction.popAlert("",_loc3_,{"aid":"A_1999_6"});
            param1.stopPropagation();
         }
      }
      
      protected function onSkill(param1:Event) : void
      {
         var _loc5_:SkillSet = null;
         var _loc2_:String = null;
         var _loc4_:String = null;
         var _loc3_:String = (param1.currentTarget as LOL_Button).name;
         if(_loc3_ && _loc3_.length > 0)
         {
            _loc5_ = new SkillSet(_loc3_,mAvatar,mAvatar.slv,false);
            _loc4_ = _loc5_.skillSetData.name;
            _loc2_ = _loc5_.getInfoDetails() + "\n";
            _loc2_ = Tools.formatLineX(_loc2_,GlobalTextStyle.COLOR_W_W_Y_G);
            GlobalFunction.popAlert(_loc4_,_loc2_,{"res":mAvatar.resId},false);
            param1.stopPropagation();
         }
      }
      
      private function onTRIGGERED_love(param1:TouchEvent) : void
      {
         var _loc3_:Array = null;
         var _loc5_:int = 0;
         var _loc4_:String = null;
         var _loc2_:String = null;
         var _loc6_:Touch = param1.getTouch(this);
         if(!_loc6_)
         {
            return;
         }
         if(_loc6_.phase == "ended")
         {
            if(mAvatar)
            {
               _loc3_ = mAvatar.getLoveList();
               _loc5_ = mAvatar.getLeadership(true) - mAvatar.getLeadership();
               _loc4_ = GlobalLanguageStr.getLanguageStr(20225,_loc3_[0],_loc5_,GlobalData.$mConfig_simple.love_up[0]);
               _loc4_ = Tools.formatLineX(_loc4_,GlobalTextStyle.COLOR_W_Y_Y_G);
               _loc2_ = GlobalData.$mConfig_simple.show_id[16];
               GlobalFunction.popAlert("",_loc4_,{"aid":_loc2_});
               param1.stopPropagation();
            }
         }
      }
      
      private function setAvatarUIGroup() : void
      {
         var _loc4_:ItemBetterElement = null;
         if(this.mBox_avatar)
         {
            StarlingTools.removeChildrenClear(this.mBox_avatar);
            this.mBox_avatar.removeFromParent(true);
         }
         this.mBox_avatar = null;
         this.mBox_avatar = new Sprite();
         this.mBox.addChild(this.mBox_avatar);
         var _loc6_:uint = 0;
         var _loc2_:uint = 5;
         var _loc5_:Number = 100;
         var _loc3_:String = "";
         var _loc1_:Object = {};
         _loc6_ = 0;
         while(_loc6_ < _loc2_)
         {
            _loc4_ = new ItemBetterElement();
            _loc1_ = {};
            _loc3_ = GlobalData.$tempAvatarBetterArr[_loc6_];
            if(_loc3_ != "" && _loc3_ != null)
            {
               if(GlobalData.$tempBetterElements[_loc3_])
               {
                  _loc1_ = GlobalData.$tempBetterElements[_loc3_];
               }
            }
            _loc4_.data = _loc1_;
            _loc4_.x = int(_loc6_ * _loc5_);
            this.mBox_avatar.addChild(_loc4_);
            _loc6_++;
         }
         this.mBox_avatar.x = (this.mImg_info_bg.width - mBox_avatar.width) * 0.5;
         this.mBox_avatar.y = _title_txt.y + _title_txt.height + 15;
         this.mBox_avatar.addEventListener("touch",this.onTOUCH);
      }
      
      private function onTOUCH(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(this.mBox_avatar,"began");
         if(_loc2_)
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_better_select",false,true);
         }
      }
      
      private function checkExpToClip(param1:Number, param2:Avatar, param3:int) : void
      {
         var _loc4_:int = param3;
         var _loc5_:Number = param2.getNextExp(_loc4_);
         if(param1 <= _loc5_)
         {
            mClip_expLast = param1;
            mClip_expLastMax = _loc5_;
            return;
         }
         if(mClip_expTime < 99)
         {
            mClip_expTime += 1;
            checkExpToClip(param1 - _loc5_,param2,_loc4_ + 1);
            return;
         }
      }
      
      override public function setList() : void
      {
      }
      
      override public function addList() : void
      {
      }
      
      private function checkBetterFood() : void
      {
         var _loc8_:String = null;
         var _loc17_:Object = null;
         var _loc1_:Avatar = null;
         var _candidateOffer:Number = 0;
         var _hasUnaffordableCandidate:Boolean = false;
         var _loc11_:int = 0;
         var _loc2_:String = null;
         var _loc7_:Avatar = new Avatar(GlobalData.$tempAvatarBetter.id);
         if(_loc7_.slv >= GlobalData.$mConfig_simple.slv_config[0])
         {
            _loc8_ = "";
         }
         else
         {
            _loc8_ = _loc7_.skill0 ? _loc7_.skill0.skillSetData.id : "";
         }
         var _loc13_:Boolean = false;
         var _loc3_:Array = [];
         var _loc4_:Object = GlobalData.$userData.avatars;
         var _loc9_:String = "";
         var _loc18_:int = 0;
         for(var _loc12_:Object in _loc4_)
         {
            _loc13_ = false;
            _loc9_ = _loc12_.toString();
            _loc18_ = 0;
            if(GlobalData.$tempBetterElements[_loc9_] != null)
            {
               _loc18_ = -1;
            }
            if(GlobalFunction.checkSearchTypeByType(_loc9_,0) || _loc18_ == -1 && GlobalFunction.checkSearchTypeByType(_loc9_,0))
            {
               _loc1_ = new Avatar(_loc9_);
               _loc17_ = _loc4_[_loc12_];
               _loc17_["id"] = _loc9_;
               _loc17_["status"] = _loc18_;
               _loc17_["canBetter"] = 0;
               _loc17_["sort_1"] = _loc1_.getSwallowValue(_loc7_);
            _loc17_["material_protected"] = PanelAvatarSell.isHeroAssigned(_loc9_) ? 1 : 0;
            _loc17_["auto_blocked"] = PanelAvatarSell.isAutoBlocked(_loc17_) ? 1 : 0;
            _loc17_["xp_material_priority"] = PanelBetterSelect.autoMaterialPriority(_loc9_);
            _loc17_["lock"] = PanelBetterSelect.isAutoSwallowProtected(_loc1_,_loc7_,_loc9_) || _loc17_["material_protected"] != 0;
               _loc3_.push(_loc17_);
               _loc1_.clear();
               _loc1_ = null;
            }
         }
      _loc3_.sortOn(["xp_material_priority","material_protected","sort_1"],[0x10,0x10,0x10 | 2]);
         var _loc15_:int = 0;
         var _loc14_:int = _loc7_.getAllExp(_loc7_.getLvMax()) - (_loc7_.getAllExp() + _loc7_.exp);
         var _loc10_:int = 0;
         var _loc16_:int = 0;
         var _loc6_:Number = 0;
         var _loc5_:Number = 5;
         _loc11_ = 0;
         while(_loc11_ < _loc3_.length)
         {
            if(_loc15_ >= _loc5_)
            {
               break;
            }
            if(_loc14_ - _loc10_ <= 0)
            {
               break;
            }
            _loc17_ = _loc3_[_loc11_];
         if(!PanelBetterSelect.matchesBetterRarity(_loc17_["id"]) || _loc17_["auto_blocked"])
         {
            _loc11_++;
            continue;
         }
            if(!_loc17_["lock"])
            {
               _loc1_ = new Avatar(_loc17_["id"]);
               _loc16_ = _loc1_.getOfferExp();
               _candidateOffer = _loc16_;
               if(_loc10_ + _candidateOffer > GlobalData.$userData.gold)
               {
                  _hasUnaffordableCandidate = true;
                  _loc11_++;
                  continue;
               }
               _loc10_ += _candidateOffer;
               _loc17_["give"] = {
                  "exp":_loc16_,
                  "gold":_loc16_
               };
               GlobalFunction.changeAvatarBetterArray(_loc17_["id"],false,null,_loc17_);
               if(_loc15_ == 0)
               {
                  _loc6_ = _loc11_;
               }
               _loc15_++;
            }
            _loc11_++;
         }
         if(_loc5_ > 0 && _loc15_ == 0)
         {
            if(_loc14_ <= 0)
            {
               _loc2_ = _loc7_.resId.indexOf(".") > -1 ? _loc7_.resId.slice(0,_loc7_.resId.length - 1) : _loc7_.resId;
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90198),false,_loc2_);
            }
            else if(_hasUnaffordableCandidate)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10023),false,"A_6999_3");
            }
            else
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90115),false,"A_3001_1");
            }
         }
         _loc5_ = 0;
      }
   }
}

