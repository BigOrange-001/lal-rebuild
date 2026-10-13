package com.meng52.game.ui.panel
{
   import com.meng52.display.ProgressBar;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.ui.element.ItemAvatar;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_HtmlText;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.element.LOL_TextField;
   import com.meng52.game.ui.screen.PanelAvatarBetter;
   import com.meng52.game.ui.stage.GuideTools;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.RpcStaticCall;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale3Image;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.filters.ColorMatrixFilter;
   
   public class PanelAvatarFoster extends PanelAvatarBetter
   {
      
      private static const BAR_NAME_PROGRESS:String = "bar_name_progress";
      
      private static const BTN_FOSTER:String = "btn_foster";
      
      private static const BTN_SAVE:String = "btn_save";
      
      private static const BTN_CANCEL:String = "btn_cancel";
      
      private var mBox:Sprite;
      
      private var mBtn_foster:LOL_Scale9Button;
      
      private var mBtn_save:LOL_Scale9Button;
      
      private var mBtn_cancel:LOL_Scale9Button;
      
      private var mAvatar:Avatar;
      
      private var mAvatarIcon:Sprite;
      
      private var mData:Object;
      
      private var mTxt_powerNum:LOL_TextField;
      
      private var mPriceArr:Array;
      
      private var mBox_exp:Sprite;
      
      private var mCurrentAvatar:ItemAvatar;
      
      private var mArr_price:Array;
      
      private var mTxt_maxP:LOL_TextField;
      
      private var mCurrentId:String = "";
      
      private var mCurr_selectPrice:Object;
      
      private var old_power:int;
      
      private var mInfo:Sprite;
      
      private var mNumX:Number;
      
      private var mNumY:Number;
      
      private var mNewPower:Number;
      
      private var mTxt_hp:LOL_TextField;
      
      private var mTxt_damage:LOL_TextField;
      
      private var mTxt_deph:LOL_TextField;
      
      private var mTxt_dema:LOL_TextField;
      
      private var mTxt_progress:LOL_TextField;
      
      private var mTxt_myBook:LOL_MutilTextFieldIcon;
      
      private var mTxt_myCoin:LOL_MutilTextFieldIcon;
      
      private var mTxt_hp_up:LOL_TextField;
      
      private var mTxt_damage_up:LOL_TextField;
      
      private var mTxt_deph_up:LOL_TextField;
      
      private var mTxt_dema_up:LOL_TextField;
      
      private var mObj:Object;
      
      private var _upIcon:Image;
      
      private var mOld_data:Object;
      
      private var mOld_id:String;
      
      private var mQuad:Quad;
      
      private var _spRule:Sprite;
      
      private var _boo:Boolean = false;

      private var mCultureViewEpoch:uint = 0;
      private var mCultureOperationToken:uint = 0;
      private var mVipTransitionReceipts:Array = [];

      private function refreshGlobalCultureBalances() : void
      {
         var _game:Object = GlobalData.$mGameClassObject;
         var _top:Object = _game != null && _game.mLayoutUITop != null ? _game.mLayoutUITop.mPanelTopMain : null;
         if(_top != null && _top.stage != null)
         {
            _top.updateCoin();
            _top.updateVip();
         }
      }
      
      public function PanelAvatarFoster(param1:Object)
      {
         super();
         mData = param1;
         GlobalData.$mEventDispatcher.addEventListener("update_shop_list",updataCoin);
         GlobalData.$mEventDispatcher.addEventListener("profile_state_sync",onProfileStateSync);
      }
      
      private function updataCoin() : void
      {
         if(mTxt_myCoin)
         {
            mTxt_myCoin.txt2 = GlobalData.$userData.coin;
         }
      }

      private function onProfileStateSync(param1:Event) : void
      {
         if(stage == null || mCurrentId == "" || mTxt_powerNum == null)
         {
            return;
         }
         if(GlobalData.$userData.avatars[mCurrentId] == null)
         {
            return;
         }
         syncCultureViewFromCache();
      }
      
      override public function onTRIGGERED_closePanel(param1:Event) : void
      {
         GlobalData.$mEventDispatcher.dispatchEventWith("update_avatar_foster",false,{"data":new Avatar(mData.id)});
         super.onTRIGGERED_closePanel(param1);
      }
      
      public function checkGuide() : void
      {
         var _loc1_:String = GuideTools.checkGuideType();
         if(mData && mCurrentId != "")
         {
            if(!GlobalData.$userData.attrs.avatar_culture)
            {
               GuideMaster.getOnlyExample().skipGuide();
               GuideMaster.getOnlyExample().checkGuide("M15_1",checkGuide);
               if(GlobalData.$mGameClassObject.mLayoutUICenter.mPanelSocialMainAvatar)
               {
                  if(GlobalData.$mGameClassObject.mLayoutUICenter.mPanelSocialMainAvatar.mList != null)
                  {
                     GlobalData.$mGameClassObject.mLayoutUICenter.mPanelSocialMainAvatar.mList.verticalScrollPolicy = "on";
                  }
               }
            }
         }
         else
         {
            LayoutUIAnimation.getOnlyExample().clearIfNoGuide();
         }
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         var _loc11_:Image = null;
         var _loc10_:Avatar = null;
         var _loc8_:Boolean = false;
         var _loc14_:int = 0;
         this.removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(90572));
         mCurrentId = mData.id;
         mBox = new Sprite();
         var _loc18_:Scale9Image = GlobalFunction.createScale9Image("UI_bg_9slice_7_0000",490,140,new Rectangle(25,25,15,15));
         _loc18_.y = 30;
         mBox.addChild(_loc18_);
         addChild(mBox);
         var _loc13_:Scale9Image = GlobalFunction.createScale9Image("UI_bg_9slice_7_0000",490,140,new Rectangle(25,25,15,15));
         mBox.addChild(_loc13_);
         _loc13_.y = _loc18_.y + _loc18_.height + 40;
         mBox.x = mImg9_baseBg.x + (mImg9_baseBg.width - _loc18_.width) / 2;
         mBox.y = mImg9_baseBg.y + (mImg9_baseBg.height - _loc18_.height) * 0.4;
         mNumX = _loc13_.x;
         mNumY = _loc13_.y;
         if(GlobalData.$mConfig_simple.culture.sale > 0)
         {
            _loc11_ = GlobalFunction.createImage("UI_sale_bg_2_0000");
            _loc11_.x = _loc13_.x + _loc13_.width - _loc11_.width / 2;
            _loc11_.y = _loc13_.y + int((_loc13_.height - _loc11_.height) * 0.5);
            mBox.addChild(_loc11_);
         }
         var _loc15_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(90568),180,30);
         _loc15_.fontSize = 20;
         _loc15_.fontColor = 16764006;
         _loc15_.hAlign = "left";
         mBox.addChild(_loc15_);
         var _loc4_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(90569),250,30);
         _loc4_.fontSize = 20;
         _loc4_.fontColor = 16764006;
         _loc4_.hAlign = "left";
         _loc4_.y = _loc13_.y - 30;
         mBox.addChild(_loc4_);
         mBtn_foster = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90553),150,70,"UI_btn_normalFun_0000");
         mBtn_foster.name = "btn_foster";
         mBtn_foster.x = (_loc13_.width - mBtn_foster.width) / 2;
         mBtn_foster.y = _loc13_.y + _loc13_.height + 30;
         mBtn_foster.addEventListener("triggered",this.onTRIGGERED_btn);
         mBox.addChild(mBtn_foster);
         mQuad = new Quad(_loc18_.width,_loc18_.height);
         mQuad.x = _loc18_.x;
         mQuad.y = _loc18_.y;
         mQuad.alpha = 0.01;
         mQuad.addEventListener("touch",quad_touch);
         mBox.addChild(mQuad);
         mBtn_save = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20271),150,70,"UI_btn_normalFun_0000");
         mBtn_save.name = "btn_save";
         mBtn_save.x = 270;
         mBtn_save.y = mBtn_foster.y;
         mBtn_save.addEventListener("triggered",this.onTRIGGERED_btn);
         mBox.addChild(mBtn_save);
         mBtn_cancel = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20270),150,70,"UI_btn_normalFun_0000");
         mBtn_cancel.name = "btn_cancel";
         mBtn_cancel.x = 70;
         mBtn_cancel.y = mBtn_foster.y;
         mBtn_cancel.addEventListener("triggered",this.onTRIGGERED_btn);
         mBox.addChild(mBtn_cancel);
         mTxt_powerNum = new LOL_TextField("",180,30);
         mTxt_powerNum.fontSize = 20;
         mTxt_powerNum.fontColor = 16777215;
         mTxt_powerNum.hAlign = "left";
         addChild(mTxt_powerNum);
         mTxt_powerNum.x = MainConfig.$isEA ? 382 : 280;
         mTxt_powerNum.y = 155;
         mTxt_maxP = new LOL_TextField(GlobalLanguageStr.getLanguageStr(90570),180,30);
         mTxt_maxP.fontSize = MainConfig.$isEnglish ? 15 : 20;
         mTxt_maxP.fontColor = 16777215;
         mTxt_maxP.hAlign = "left";
         addChild(mTxt_maxP);
         mTxt_maxP.x = 185;
         mTxt_maxP.y = 180;
         mTxt_hp = new LOL_TextField("",180,30);
         mTxt_hp.fontSize = 20;
         mTxt_hp.fontColor = 16777215;
         mTxt_damage = new LOL_TextField("",180,30);
         mTxt_damage.fontSize = 20;
         mTxt_damage.fontColor = 16777215;
         mTxt_deph = new LOL_TextField("",180,30);
         mTxt_deph.fontSize = 20;
         mTxt_deph.fontColor = 16777215;
         mTxt_dema = new LOL_TextField("",180,30);
         mTxt_dema.fontSize = 20;
         mTxt_dema.fontColor = 16777215;
         mTxt_hp.hAlign = mTxt_damage.hAlign = mTxt_deph.hAlign = mTxt_dema.hAlign = "left";
         var _loc9_:Image = GlobalFunction.createImage("UI_tag_warn_0_0000");
         _loc9_.touchable = true;
         _loc9_.addEventListener("touch",quad_touch);
         mInfo = new Sprite();
         mInfo.addChild(mTxt_hp);
         mInfo.addChild(mTxt_damage);
         mInfo.addChild(mTxt_deph);
         mInfo.addChild(mTxt_dema);
         mInfo.addChild(_loc9_);
         mBox.addChild(mInfo);
         mTxt_hp.x = mTxt_damage.x = MainConfig.$isEA ? 30 : 60;
         mTxt_deph.x = mTxt_dema.x = MainConfig.$isEA ? 235 : 290;
         mTxt_hp.y = mTxt_deph.y = 70;
         mTxt_damage.y = mTxt_dema.y = 100;
         _loc9_.x = _loc18_.x + _loc18_.width - _loc9_.width - 10;
         _loc9_.y = _loc18_.y + 10;
         mTxt_myBook = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getLanguageStr(90577),"","UI_breed_book0000",16777215,16777215,MainConfig.$isEnglish ? 15 : 20);
         mBox.addChild(mTxt_myBook);
         mTxt_myBook.iconScale = 0.5;
         mTxt_myBook.x = _loc13_.x;
         mTxt_myBook.y = _loc13_.y + _loc13_.height;
         mTxt_myCoin = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getLanguageStr(90671),"","UI_money_coin_0_0000",16777215,16777215,MainConfig.$isEnglish ? 15 : 20);
         mBox.addChild(mTxt_myCoin);
         mTxt_myCoin.x = mBtn_save.x;
         mTxt_myCoin.y = mTxt_myBook.y;
         mTxt_hp_up = new LOL_TextField("",180,30);
         mTxt_hp_up.fontSize = 20;
         mInfo.addChild(mTxt_hp_up);
         mTxt_damage_up = new LOL_TextField("",180,30);
         mTxt_damage_up.fontSize = 20;
         mInfo.addChild(mTxt_damage_up);
         mTxt_deph_up = new LOL_TextField("",180,30);
         mTxt_deph_up.fontSize = 20;
         mInfo.addChild(mTxt_deph_up);
         mTxt_dema_up = new LOL_TextField("",180,30);
         mTxt_dema_up.fontSize = 20;
         mInfo.addChild(mTxt_dema_up);
         mAvatar = new Avatar(mCurrentId);
         old_power = mAvatar.getPower(mData["index"] == 0,-1,true);
         mObj = GlobalData.$userData.attrs.avatar_culture;
         if(mObj != null)
         {
            GuideMaster.getOnlyExample().skipGuide();
            GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(10183));
            mCurrentId = mObj.aid;
            if(mCurrentId == null)
            {
               mCurrentId = mObj.eqid;
            }
            mAvatar = new Avatar(mCurrentId);
            checkNum(mObj);
            _loc10_ = new Avatar(mCurrentId);
            if(GlobalFunction.isExisitTeam(mCurrentId) != -1)
            {
               _loc10_.setEquips();
               _loc10_.setDestinyAndDN();
               _loc10_.initFightAttr();
            }
            _loc8_ = mData["index"] == 0 ? true : false;
            old_power = _loc10_.getPower(_loc8_,-1,true);
         }
         setAttUIs();
         var _loc12_:String = mCurrentId.split("|")[0];
         mAvatarIcon = mAvatar.getAvatarRes();
         addChild(mAvatarIcon);
         mAvatarIcon.x = 80;
         mAvatarIcon.y = 100;
         var _loc6_:Object = GlobalFunction.get_HelpLink(GlobalLanguageStr.getLanguageStr(90643));
         _spRule = _loc6_.ui;
         _spRule.x = _width - _loc6_.w - 40;
         _spRule.y = 88;
         addChild(_spRule);
         _spRule.addEventListener("touch",onPith);
         var _loc5_:String = GlobalLanguageStr.getLanguageStr(90674);
         var _loc7_:String = Tools.formatLineX(_loc5_,GlobalTextStyle.COLOR_W_W_Y_G,MainConfig.$isEA ? 28 : 18,MainConfig.$isEnglish ? 15 : 20);
         var _loc3_:LOL_HtmlText = new LOL_HtmlText(420,100,20,16777215);
         _loc3_.text = _loc7_;
         addChild(_loc3_);
         _loc3_.x = mTxt_maxP.x;
         _loc3_.y = mTxt_maxP.y + mTxt_maxP.height - 3;
         var _loc16_:LOL_TextField = new LOL_TextField(mAvatar.avatarData.name,180,30);
         _loc16_.fontSize = 20;
         _loc16_.fontColor = 16764006;
         _loc16_.hAlign = "left";
         addChild(_loc16_);
         _loc16_.x = 186;
         _loc16_.y = 95;
         var _loc2_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(20079,mAvatar.lv),180,30);
         _loc2_.fontSize = MainConfig.$isEnglish ? 15 : 20;
         _loc2_.fontColor = 16777215;
         _loc2_.hAlign = "left";
         addChild(_loc2_);
         _loc2_.x = _loc16_.x;
         _loc2_.y = _loc16_.y + _loc16_.height + 5;
         var _loc17_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(10133),MainConfig.$isEA ? 300 : 180,30);
         _loc17_.fontSize = MainConfig.$isEnglish ? 15 : 20;
         _loc17_.fontColor = 16777215;
         _loc17_.hAlign = "left";
         addChild(_loc17_);
         _loc17_.x = _loc2_.x;
         _loc17_.y = _loc2_.y + _loc2_.height - 5;
         checkBtns();
         setFun_price();
         setExpBarUIs();
         setHaloExp();
         checkGuide();
         if(mObj != null)
         {
            _loc14_ = 0;
            while(_loc14_ < mPriceArr.length)
            {
               if(mPriceArr[_loc14_].type == mObj.type && mPriceArr[_loc14_].num == mObj.num)
               {
                  selectRadio(_loc14_);
               }
               _loc14_++;
            }
         }
      }
      
      private function quad_touch(param1:TouchEvent) : void
      {
         var _loc2_:String = null;
         var _loc3_:String = null;
         var _loc4_:Touch = param1.getTouch(this,"ended");
         var _loc7_:Avatar = new Avatar(mCurrentId);
         var _loc8_:String = mCurrentId.split("|")[0];
         var _loc6_:int = _loc7_.getCultivationCap();
         var _loc9_:int = _loc7_.getCultivationDisplayScale();
         if(_loc4_)
         {
            if(_loc7_)
            {
               _loc2_ = GlobalLanguageStr.getLanguageStr(20226);
               _loc3_ = GlobalLanguageStr.getLanguageStr(90521,_loc7_.getHpMax(-1,-1,true),_loc7_.getCultivationStatGain("hp",_loc7_.hpP),_loc7_.getDamage(-1,-1,true),_loc7_.getCultivationStatGain("ap",_loc7_.apP),_loc7_.getDePh(-1,-1,true),_loc7_.getCultivationStatGain("de_ph",_loc7_.dePhP),_loc7_.getDeMa(-1,-1,true),_loc7_.getCultivationStatGain("de_ma",_loc7_.deMaP),_loc7_.getPithNum() * _loc9_,_loc6_ * _loc9_);
               _loc2_ += "\n" + _loc3_;
               _loc2_ = Tools.formatLineX(_loc2_,GlobalTextStyle.COLOR_W_Y_Y_G);
               GlobalFunction.popAlert("",_loc2_,{"aid":_loc8_},false);
               param1.stopPropagation();
            }
         }
      }
      
      private function onPith(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(_spRule,"ended");
         if(_loc2_)
         {
            GlobalFunction.popPanelHelp(MainConfig.SERVER_ADDRESS_HELR_AVATAR_CULTURE);
         }
      }
      
      private function checkBtns() : void
      {
         var _hero:Object;
         var _avatar:Avatar;
         var _totalPith:int;
         var _currentCap:int;
         var _loc2_:Boolean = GlobalData.$userData.attrs.avatar_culture == null || GlobalData.$userData.attrs.avatar_culture == {};
         mBtn_foster.visible = _loc2_;
         mBtn_save.visible = !_loc2_;
         mBtn_cancel.visible = !_loc2_;
         var _loc1_:Boolean = false;
         if(mCurrentId != "" && mCurr_selectPrice != null)
         {
            _loc1_ = true;
         }
         // A pending preview remains saveable or cancellable even at the cap.
         if(_loc2_ && _loc1_ && GlobalData.$userData.avatars != null && GlobalData.$mConfig_simple.culture != null)
         {
            _hero = GlobalData.$userData.avatars[mCurrentId];
            if(_hero != null)
            {
               _avatar = new Avatar(mCurrentId,_hero);
               _totalPith = _avatar.getPithNum();
               _currentCap = _avatar.getCultivationCap();
               if(_currentCap <= 0 || _totalPith >= _currentCap)
               {
                  _loc1_ = false;
               }
            }
         }
         mBtn_foster.enabled = _loc1_;
      }
      
      private function onTRIGGERED_btn(param1:Event) : void
      {
         var mPith:int;
         var _fun:Object;
         var resId:String;
         var sendWash:*;
         var _event:Event = param1;
         var _btn:LOL_Scale9Button = _event.currentTarget as LOL_Scale9Button;
         var avatar:Avatar = new Avatar(mCurrentId);
         if(_btn.name == "btn_foster")
         {
            if(mCurrentId != null)
            {
               sendWash = function():void
               {
                  var _loc1_:int = 0;
                  var _loc2_:int = 0;
                  if(_btn.enabled)
                  {
                     if(mCurr_selectPrice.type == "coin")
                     {
                        _loc1_ = int(GlobalData.$mConfig_simple.culture.price.coin[mCurr_selectPrice.num]);
                        if(GlobalData.$userData.coin < _loc1_)
                        {
                           GlobalFunction.popErrorCoin(_loc1_);
                        }
                        else
                        {
                           sendService();
                        }
                     }
                     else if(mCurr_selectPrice.type == "culture_book")
                     {
                        _loc2_ = int(GlobalData.$mConfig_simple.culture.price.culture_book[mCurr_selectPrice.num]);
                        if(GlobalData.$userData.attrs.culture_book < _loc2_)
                        {
                           LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getLanguageStr(90575),1);
                        }
                        else
                        {
                           sendService();
                        }
                     }
                  }
               };
               mPith = avatar.getCultivationCap();
               _fun = {
                  "ok":sendWash,
                  "no":GlobalFunction.functionNull
               };
               resId = mCurrentId.split("|")[0];
               if(avatar.getPithNum() >= mPith)
               {
                  if(!_boo)
                  {
                     _boo = true;
                     _fun.aid = resId;
                     if(avatar.isWeightedCultivation() || mPith == GlobalData.$mConfig_simple.culture.max_pith)
                     {
                        GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90678)),_fun);
                     }
                     else
                     {
                        GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90678) + "\n" + "(" + GlobalLanguageStr.getLanguageStr(90677) + ")",[16777215,16764006]),_fun);
                     }
                  }
                  else if(checkIsPay())
                  {
                     sendWash();
                  }
               }
               else if(checkIsPay())
               {
                  sendWash();
               }
            }
            else
            {
               if(!checkIsPay())
               {
                  return;
               }
               if(mCurrentId == "")
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90081));
               }
            }
         }
         else if(_btn.name == "btn_save")
         {
            if(_btn.enabled)
            {
               if(SendAndSelect.checkRepeat("user.avatar_culture_save",""))
               {
                  RpcStaticCall.$remoting.reportDiagnostic("PROFILE_REQUEST_DUPLICATE_SUPPRESSED|method=user.avatar_culture_save");
                  return;
               }
               var _saveAid:String = mCurrentId;
               var _saveEpoch:uint = mCultureViewEpoch;
               var _saveToken:uint = ++mCultureOperationToken;
               SendServiceAMFFun.send_user_avatar_culture_save(function(param1:Object):void
               {
                  re_avatar_culture_save(param1,_saveAid,_saveEpoch,_saveToken);
               });
            }
         }
         else if(_btn.name == "btn_cancel")
         {
            if(_btn.enabled)
            {
               if(SendAndSelect.checkRepeat("user.avatar_culture_cancel",""))
               {
                  RpcStaticCall.$remoting.reportDiagnostic("PROFILE_REQUEST_DUPLICATE_SUPPRESSED|method=user.avatar_culture_cancel");
                  return;
               }
               var _cancelAid:String = mCurrentId;
               var _cancelEpoch:uint = mCultureViewEpoch;
               var _cancelToken:uint = ++mCultureOperationToken;
               SendServiceAMFFun.send_user_avatar_culture_cancel(function(param1:Object):void
               {
                  re_avatar_culture_cancel(param1,_cancelAid,_cancelEpoch,_cancelToken);
               });
            }
         }
      }
      
      private function sendService() : void
      {
         var _aid:String = mCurrentId;
         if(SendAndSelect.checkRepeat("user.avatar_culture",""))
         {
            RpcStaticCall.$remoting.reportDiagnostic("PROFILE_REQUEST_DUPLICATE_SUPPRESSED|method=user.avatar_culture");
            return;
         }
         var _epoch:uint = mCultureViewEpoch;
         var _token:uint = ++mCultureOperationToken;
         var _vipBefore:int = int(GlobalData.$userData.vip_lv);
         var _type:String = mCurr_selectPrice.type;
         var _num:Object = mCurr_selectPrice.num;
         SendServiceAMFFun.send_user_avatar_culture(function(param1:Object):void
         {
            re_avatar_culture(param1,_aid,_epoch,_token,_vipBefore);
         },{
            "aid":_aid,
            "type":_type,
            "num":_num
         });
      }
      
      private function re_avatar_culture(param1:Object, param2:String, param3:uint, param4:uint, param5:int) : void
      {
         if(GlobalFunction.isMalformedProfileReceipt(param1))
         {
            return;
         }
         if(GlobalFunction.isLegacyProfileReceipt(param1))
         {
            RpcStaticCall.$remoting.reportDiagnostic("PROFILE_RECEIPT_LEGACY|method=user.avatar_culture");
         }
         if(param3 != mCultureViewEpoch || param4 != mCultureOperationToken || this.stage == null || mCurrentId != param2)
         {
            return;
         }
         refreshGlobalCultureBalances();
         var _loc11_:Object = GlobalData.$userData.attrs.avatar_culture;
         if(_loc11_ == null || String(_loc11_.aid != null ? _loc11_.aid : _loc11_.eqid) != param2)
         {
            syncCultureViewFromCache();
            return;
         }
         mObj = _loc11_;
         renderCulturePending(_loc11_,true);
         var _loc3_:Object = param1.data.avatar_culture;
         var _loc8_:Object = param1["params"];
         showCultureVipTransition(param1,param5);
      }

      private function showCultureVipTransition(param1:Object, param2:int) : void
      {
         if(param1 == null || param1.data == null || GlobalData.$userData == null)
         {
            return;
         }
         var _afterVip:int = param1.data.user_dict != null ? int(param1.data.user_dict.vip_lv) : int(param1.data.vip_lv);
         if(_afterVip <= param2 || _afterVip != int(GlobalData.$userData.vip_lv))
         {
            return;
         }
         var _revisionKey:String;
         if(GlobalFunction.isVersionedProfileReceipt(param1))
         {
            _revisionKey = String(param1.method) + ":" + String(param1.state_sync.uid) + ":" + String(param1.state_sync.revision);
         }
         else
         {
            _revisionKey = "user.avatar_culture:legacy:" + String(mCurrentId) + ":" + String(param2) + ":" + String(_afterVip);
         }
         if(mVipTransitionReceipts.indexOf(_revisionKey) >= 0)
         {
            return;
         }
         mVipTransitionReceipts.push(_revisionKey);
         GlobalFunction.popAward("_$vip$_",GlobalLanguageStr.getLanguageStr(20203,_afterVip),_afterVip);
      }

      private function renderCulturePending(_loc11_:Object, _playEffect:Boolean = false) : void
      {
         mCurrentId = String(_loc11_.aid != null ? _loc11_.aid : _loc11_.eqid);
         mOld_id = _loc11_.aid;
         mOld_data = GlobalData.$userData.avatars[mCurrentId];
         if(mOld_data == null)
         {
            return;
         }
         var _previewData:Object = Tools.clone(mOld_data);
         if(_loc11_.schema == "weighted-v2") _previewData.culture_schema = "weighted-v2";
         var _loc2_:Avatar = new Avatar(mCurrentId,_previewData);
         if(_loc11_.save_status.ap)
         {
            _loc2_.apP += _loc11_.save_status.ap;
         }
         if(_loc11_.save_status.hp)
         {
            _loc2_.hpP += _loc11_.save_status.hp;
         }
         if(_loc11_.save_status.de_ph)
         {
            _loc2_.dePhP += _loc11_.save_status.de_ph;
         }
         if(_loc11_.save_status.de_ma)
         {
            _loc2_.deMaP += _loc11_.save_status.de_ma;
         }
         if(GlobalFunction.isExisitTeam(mCurrentId) != -1)
         {
            _loc2_.setEquips();
            _loc2_.setDestinyAndDN();
            _loc2_.initFightAttr();
         }
         var _loc9_:Boolean = mData["index"] == 0 ? true : false;
         var _loc7_:Number = _loc2_.getPower(_loc9_,-1,true);
         var _loc10_:Avatar = new Avatar(_loc11_.aid);
         if(GlobalFunction.isExisitTeam(_loc11_.aid) != -1)
         {
            _loc10_.setEquips();
            _loc10_.setDestinyAndDN();
            _loc10_.initFightAttr();
         }
         old_power = _loc10_.getPower(_loc9_,-1,true);
         if(_loc7_ > old_power)
         {
            checkUp(true);
         }
         else if(_loc7_ < old_power)
         {
            checkUp(false);
         }
         checkNum(_loc11_);
         checkBtns();
         setAttUIs();
         setHaloExp();
         checkGuide();
         if(_playEffect)
         {
            var _loc5_:Number = 130;
            var _loc6_:Number = (GlobalData.$mStageHeight - mImg9_baseBg.height) * 0.5 + 140;
            LayoutUIAnimation.getOnlyExample().popEffect({
               "id":"e008",
               "x":_loc5_,
               "y":_loc6_,
               "sc":1.2,
               "s":{"id":"skill1"}
            });
         }
      }

      private function syncCultureViewFromCache() : void
      {
         var _pending:Object = GlobalData.$userData.attrs.avatar_culture;
         var _pendingAid:String = _pending == null ? "" : String(_pending.aid != null ? _pending.aid : _pending.eqid);
         if(_pending != null && _pendingAid == mCurrentId && GlobalData.$userData.avatars[mCurrentId] != null)
         {
            mObj = _pending;
            checkNum(_pending);
            renderCulturePending(_pending);
         }
         else
         {
            mObj = null;
            clearCultureDeltaText();
            setAttUIs();
            checkBtns();
            setHaloExp();
            removeUpIcon();
         }
         refreshGlobalCultureBalances();
      }

      private function clearCultureDeltaText() : void
      {
         if(mTxt_damage_up) mTxt_damage_up.text = "";
         if(mTxt_hp_up) mTxt_hp_up.text = "";
         if(mTxt_deph_up) mTxt_deph_up.text = "";
         if(mTxt_dema_up) mTxt_dema_up.text = "";
      }
      
      private function checkNum(param1:Object) : void
      {
         var _displayAvatar:Avatar = new Avatar(mCurrentId);
         var _weightedPreview:Boolean = param1 && param1.schema == "weighted-v2";
         if(param1)
         {
            if(param1.save_status.ap)
            {
               if(param1.save_status.ap > 0)
               {
                  mTxt_damage_up.fontColor = 65280;
                  mTxt_damage_up.text = "+" + (_weightedPreview ? int(param1.save_status.ap) : _displayAvatar.getCultivationStatGain("ap",int(param1.save_status.ap)));
               }
               else if(param1.save_status.ap < 0)
               {
                  mTxt_damage_up.fontColor = 16711680;
                  mTxt_damage_up.text = "" + (_weightedPreview ? int(param1.save_status.ap) : _displayAvatar.getCultivationStatGain("ap",int(param1.save_status.ap)));
               }
               else
               {
                  mTxt_damage_up.text = "";
               }
            }
            else
            {
               mTxt_damage_up.text = "";
            }
            if(param1.save_status.hp)
            {
               if(param1.save_status.hp > 0)
               {
                  mTxt_hp_up.fontColor = 65280;
                  mTxt_hp_up.text = "+" + (_weightedPreview ? int(param1.save_status.hp) : _displayAvatar.getCultivationStatGain("hp",int(param1.save_status.hp)));
               }
               else if(param1.save_status.hp < 0)
               {
                  mTxt_hp_up.fontColor = 16711680;
                  mTxt_hp_up.text = "" + (_weightedPreview ? int(param1.save_status.hp) : _displayAvatar.getCultivationStatGain("hp",int(param1.save_status.hp)));
               }
               else
               {
                  mTxt_hp_up.text = "";
               }
            }
            else
            {
               mTxt_hp_up.text = "";
            }
            if(param1.save_status.de_ph)
            {
               if(param1.save_status.de_ph > 0)
               {
                  mTxt_deph_up.fontColor = 65280;
                  mTxt_deph_up.text = "+" + (_weightedPreview ? int(param1.save_status.de_ph) : _displayAvatar.getCultivationStatGain("de_ph",int(param1.save_status.de_ph)));
               }
               else if(param1.save_status.de_ph < 0)
               {
                  mTxt_deph_up.fontColor = 16711680;
                  mTxt_deph_up.text = "" + (_weightedPreview ? int(param1.save_status.de_ph) : _displayAvatar.getCultivationStatGain("de_ph",int(param1.save_status.de_ph)));
               }
               else
               {
                  mTxt_deph_up.text = "";
               }
            }
            else
            {
               mTxt_deph_up.text = "";
            }
            if(param1.save_status.de_ma)
            {
               if(param1.save_status.de_ma > 0)
               {
                  mTxt_dema_up.fontColor = 65280;
                  mTxt_dema_up.text = "+" + (_weightedPreview ? int(param1.save_status.de_ma) : _displayAvatar.getCultivationStatGain("de_ma",int(param1.save_status.de_ma)));
               }
               else if(param1.save_status.de_ma < 0)
               {
                  mTxt_dema_up.fontColor = 16711680;
                  mTxt_dema_up.text = "" + (_weightedPreview ? int(param1.save_status.de_ma) : _displayAvatar.getCultivationStatGain("de_ma",int(param1.save_status.de_ma)));
               }
               else
               {
                  mTxt_dema_up.text = "";
               }
            }
            else
            {
               mTxt_dema_up.text = "";
            }
         }
      }
      
      private function re_avatar_culture_save(param1:Object, param2:String, param3:uint, param4:uint) : void
      {
         if(GlobalFunction.isMalformedProfileReceipt(param1))
         {
            return;
         }
         if(GlobalFunction.isLegacyProfileReceipt(param1))
         {
            RpcStaticCall.$remoting.reportDiagnostic("PROFILE_RECEIPT_LEGACY|method=user.avatar_culture_save");
         }
         var _loc4_:Object = GlobalData.$userData.avatars;
         var _loc5_:Object = _loc4_[param2];
         if(_loc5_ == null)
         {
            return;
         }
         if(param3 != mCultureViewEpoch || param4 != mCultureOperationToken || this.stage == null || mCurrentId != param2)
         {
            return;
         }
         syncCultureViewFromCache();
         checkGuide();
         checkPower(old_power);
         removeUpIcon();
         SoundManager.getOnlyExample().playSound("E_9011");
         var _loc2_:Number = 130;
         var _loc3_:Number = (GlobalData.$mStageHeight - mImg9_baseBg.height) * 0.5 + 140;
         LayoutUIAnimation.getOnlyExample().popEffect({
            "id":"e703",
            "x":_loc2_,
            "y":_loc3_,
            "sc":1.2,
            "t":1
         });
      }
      
      private function re_avatar_culture_cancel(param1:Object, param2:String, param3:uint, param4:uint) : void
      {
         if(GlobalFunction.isMalformedProfileReceipt(param1))
         {
            return;
         }
         if(GlobalFunction.isLegacyProfileReceipt(param1))
         {
            RpcStaticCall.$remoting.reportDiagnostic("PROFILE_RECEIPT_LEGACY|method=user.avatar_culture_cancel");
         }
         if(param3 != mCultureViewEpoch || param4 != mCultureOperationToken || this.stage == null || mCurrentId != param2)
         {
            return;
         }
         syncCultureViewFromCache();
         removeUpIcon();
         checkGuide();
         SoundManager.getOnlyExample().playSound("E_8002");
      }
      
      private function checkIsPay() : Boolean
      {
         var _loc1_:int = 0;
         var _loc2_:int = 0;
         var _loc3_:Boolean = true;
         if(mObj != null)
         {
            GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(10183));
         }
         else if(mCurrentId != "")
         {
            if(mCurr_selectPrice != null)
            {
               if(mCurr_selectPrice.type == "coin")
               {
                  _loc1_ = int(GlobalData.$mConfig_simple.culture.price.coin[mCurr_selectPrice.num]);
                  if(GlobalData.$userData.coin < _loc1_)
                  {
                     GlobalFunction.popErrorCoin(_loc1_);
                     _loc3_ = false;
                  }
               }
               else if(mCurr_selectPrice.type == "culture_book")
               {
                  _loc2_ = int(GlobalData.$mConfig_simple.culture.price.culture_book[mCurr_selectPrice.num]);
                  if(GlobalData.$userData.attrs.culture_book < _loc2_)
                  {
                     GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90575));
                     _loc3_ = false;
                  }
               }
            }
            else
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90655));
            }
         }
         return _loc3_;
      }
      
      private function checkUp(param1:Boolean = false) : void
      {
         var _loc2_:ColorMatrixFilter = null;
         if(_upIcon)
         {
            _upIcon.removeFromParent(true);
            _upIcon = null;
         }
         _upIcon = GlobalFunction.createImage("UI_equip_tag_0_0000");
         _upIcon.x = mTxt_powerNum.x + mTxt_powerNum.textBounds.width + 20;
         _upIcon.y = mTxt_powerNum.y + 5;
         _upIcon.pivotX = _upIcon.width / 2;
         _upIcon.pivotY = _upIcon.height / 2;
         addChild(_upIcon);
         if(param1)
         {
            _upIcon.rotation = -1.5707963267948966;
         }
         else
         {
            _upIcon.rotation = 3.141592653589793 / 2;
            _loc2_ = new ColorMatrixFilter();
            _loc2_.adjustBrightness(-0.39215686274509803);
            _loc2_.adjustContrast(0.00392156862745098);
            _loc2_.adjustSaturation(0.19607843137254902);
            _loc2_.adjustHue(-0.4745098039215686);
            _upIcon.filter = _loc2_;
         }
      }
      
      private function removeUpIcon() : void
      {
         if(_upIcon)
         {
            _upIcon.removeFromParent(true);
            _upIcon = null;
         }
      }
      
      private function setAttUIs() : void
      {
         var _loc1_:Avatar = new Avatar(mCurrentId);
         if(GlobalFunction.isExisitTeam(mCurrentId) != -1)
         {
            _loc1_.setEquips();
            _loc1_.setDestinyAndDN();
            _loc1_.initFightAttr();
         }
         mTxt_hp.text = GlobalLanguageStr.getLanguageStr(20024,_loc1_.getHpMax(-1,-1,true) > 0 ? _loc1_.getHpMax(-1,-1,true) : 0);
         mTxt_damage.text = GlobalLanguageStr.getLanguageStr(20025,_loc1_.getDamage(-1,-1,true) > 0 ? _loc1_.getDamage(-1,-1,true) : 0);
         mTxt_deph.text = GlobalLanguageStr.getLanguageStr(20026,_loc1_.getDePh(-1,-1,true) > 0 ? _loc1_.getDePh(-1,-1,true) : 0);
         mTxt_dema.text = GlobalLanguageStr.getLanguageStr(20027,_loc1_.getDeMa(-1,-1,true) > 0 ? _loc1_.getDeMa(-1,-1,true) : 0);
         mTxt_myBook.txt2 = GlobalData.$userData.attrs.culture_book + "";
         mTxt_myCoin.txt2 = GlobalData.$userData.coin;
         mTxt_hp_up.hAlign = mTxt_damage_up.hAlign = mTxt_deph_up.hAlign = mTxt_dema_up.hAlign = "left";
         mTxt_hp_up.x = mTxt_hp.x + mTxt_hp.textBounds.width + 10;
         mTxt_hp_up.y = mTxt_hp.y;
         mTxt_damage_up.x = mTxt_damage.x + mTxt_damage.textBounds.width + 10;
         mTxt_damage_up.y = mTxt_damage.y;
         mTxt_deph_up.x = mTxt_deph.x + mTxt_deph.textBounds.width + 10;
         mTxt_deph_up.y = mTxt_deph.y;
         mTxt_dema_up.x = mTxt_dema.x + mTxt_dema.textBounds.width + 10;
         mTxt_dema_up.y = mTxt_dema.y;
         var _loc2_:Boolean = mData["index"] == 0 ? true : false;
         mTxt_powerNum.text = _loc1_.getPower(_loc2_,-1,true) + "";
      }
      
      private function checkPower(param1:Number) : void
      {
         var _loc2_:Avatar = new Avatar(mCurrentId);
         if(GlobalFunction.isExisitTeam(mCurrentId) != -1)
         {
            _loc2_.setEquips();
            _loc2_.setDestinyAndDN();
            _loc2_.initFightAttr();
         }
         var _loc3_:Boolean = mData["index"] == 0 ? true : false;
         mNewPower = _loc2_.getPower(_loc3_,-1,true);
         if(mNewPower > old_power)
         {
            LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getLanguageStr(10133) + "+" + (mNewPower - old_power),2,GlobalData.$mStageHeight * 0.38);
         }
         else if(mNewPower < old_power)
         {
            LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getLanguageStr(10133) + (mNewPower - old_power),2,GlobalData.$mStageHeight * 0.38);
         }
      }
      
      private function setFun_price() : void
      {
         var _loc1_:Avatar = null;
         var _loc9_:LOL_Button = null;
         var _loc2_:Rectangle = null;
         var _loc10_:int = 0;
         var _loc3_:Object = null;
         var _loc12_:String = mData.id;
         var _loc8_:Object = GlobalData.$userData.avatars[_loc12_];
         var _loc11_:Number = Number(GlobalData.$mConfig_simple.culture.price.culture_book[1]);
         var _loc13_:Number = Number(GlobalData.$mConfig_simple.culture.price.culture_book[10]);
         var _loc7_:Number = Number(GlobalData.$mConfig_simple.culture.price.coin[1]);
         var _loc5_:Number = Number(GlobalData.$mConfig_simple.culture.price.coin[10]);
         var _loc16_:Array = [_loc11_ + GlobalLanguageStr.getLanguageStr(90562) + GlobalLanguageStr.getLanguageStr(90563),_loc7_ + GlobalLanguageStr.getLanguageStr(20149) + GlobalLanguageStr.getLanguageStr(90563),_loc13_ + GlobalLanguageStr.getLanguageStr(90562) + GlobalLanguageStr.getLanguageStr(90564),_loc5_ + GlobalLanguageStr.getLanguageStr(20149) + GlobalLanguageStr.getLanguageStr(90564)];
         var _loc6_:int = int(_loc16_.length);
         var _loc14_:Number = 10;
         var _loc15_:Number = mNumY + 10;
         mPriceArr = null;
         mPriceArr = [{
            "type":"culture_book",
            "num":"1"
         },{
            "type":"coin",
            "num":"1"
         },{
            "type":"culture_book",
            "num":"10"
         },{
            "type":"coin",
            "num":"10"
         }];
         mArr_price = [];
         _loc10_ = 0;
         while(_loc10_ < _loc6_)
         {
            _loc9_ = new LOL_Button(_loc16_[_loc10_],"UI_equip_radio_0_0001",true);
            _loc9_.fontSize = MainConfig.$isEA ? 22 : (MainConfig.$isEnglish ? 18 : 22);
            _loc9_.fontColor = 16777215;
            _loc9_._text.hAlign = "left";
            _loc9_._text.x = 30;
            _loc9_._text.y = -3;
            _loc9_.name = _loc10_.toString();
            _loc9_.shadowFilter();
            _loc2_ = _loc9_.textBounds;
            _loc2_.x = 30;
            _loc9_.x = MainConfig.$isEA ? _loc14_ + _loc10_ % 2 * (_loc9_.width - 10) + 10 : _loc14_ + _loc10_ % 2 * (_loc9_.width - 20) + 20;
            _loc9_.y = _loc15_ + Math.floor(_loc10_ / 2) * (_loc9_.height + 5) + 20;
            mBox.addChild(_loc9_);
            mArr_price.push(_loc9_);
            _loc9_.addEventListener("triggered",onTRIGGERED_radio);
            _loc10_++;
         }
         var _loc4_:int = 0;
         if(mCurr_selectPrice)
         {
            _loc3_ = {
               "culture_book1":0,
               "coin1":1,
               "culture_book10":2,
               "coin10":3
            };
            _loc4_ = int(_loc3_[mCurr_selectPrice.type + mCurr_selectPrice.num]);
            selectRadio(_loc4_);
         }
         if(_loc8_ != null)
         {
            _loc1_ = new Avatar(_loc12_,_loc8_);
         }
      }
      
      public function setHaloExp() : void
      {
         var _loc3_:ProgressBar = null;
         var _loc2_:Avatar = null;
         var _loc7_:Number = NaN;
         var used:int = 0;
         var cap:int = 0;
         var displayScale:int = 1;
         if(mData)
         {
            if(mBox_exp)
            {
               _loc3_ = mBox_exp.getChildByName("bar_name_progress") as ProgressBar;
               mBox_exp.visible = false;
               if(mData.id != null && mData.id != "")
               {
                  mBox_exp.visible = true;
                  _loc2_ = new Avatar(mCurrentId,GlobalData.$userData.avatars[mCurrentId]);
                  cap = _loc2_.getCultivationCap();
                  used = Math.min(cap,_loc2_.getPithNum());
                  displayScale = _loc2_.getCultivationDisplayScale();
                  _loc7_ = cap > 0 ? Number(used) / cap : 0;
                  _loc3_.mMax = _loc3_.mBg.width;
                  _loc3_.ratio = _loc7_;
                  if(mTxt_progress)
                  {
                     mTxt_progress.removeFromParent(true);
                     mTxt_progress = null;
                  }
                  mTxt_progress = new LOL_TextField(GlobalLanguageStr.getLanguageStr(20005,used * displayScale,cap * displayScale),180,30);
                  mTxt_progress.fontSize = 15;
                  mTxt_progress.fontColor = 16777215;
                  mTxt_progress.hAlign = "center";
                  addChild(mTxt_progress);
                  mTxt_progress.x = mBox_exp.x + mBox_exp.width / 5;
                  mTxt_progress.y = mBox_exp.y - 3;
               }
            }
         }
      }
      
      private function setExpBarUIs() : void
      {
         var _loc2_:Object = {
            "f":10,
            "s":10,
            "x":3,
            "y":2,
            "gapX":3
         };
         mBox_exp = new Sprite();
         var _loc3_:Scale3Image = GlobalFunction.createScale3Image("UI_bar_exp_8_0000",10,10,290);
         _loc3_.y = 2;
         mBox_exp.addChild(_loc3_);
         var _loc1_:ProgressBar = new ProgressBar(GlobalFunction.getTexture("UI_bar_exp_8_0000"),GlobalFunction.getTexture("UI_equip_bar_1_0000"),_loc2_);
         _loc1_.mBg.visible = false;
         _loc1_.mBg.width = 290;
         _loc1_.mBg.height = 22;
         _loc1_.name = "bar_name_progress";
         _loc1_.setRatio(0);
         mBox_exp.addChild(_loc1_);
         addChild(mBox_exp);
         mBox_exp.x = MainConfig.$isEA ? 306 : 270;
         mBox_exp.y = 183;
      }
      
      private function onTRIGGERED_radio(param1:Event) : void
      {
         var _loc2_:int = int((param1.currentTarget as LOL_Button).name);
         selectRadio(_loc2_,true);
      }
      
      private function selectRadio(param1:int = 0, param2:Boolean = false) : void
      {
         var _loc7_:LOL_Button = null;
         var _loc6_:int = 0;
         var _loc3_:Object = mCurr_selectPrice;
         mCurr_selectPrice = mPriceArr[param1];
         var _loc4_:Boolean = checkIsPay();
         if(!_loc4_)
         {
            mCurr_selectPrice = _loc3_;
            return;
         }
         if(param2)
         {
            checkBtns();
         }
         var _loc5_:int = int(mArr_price.length);
         _loc6_ = 0;
         while(_loc6_ < _loc5_)
         {
            _loc7_ = mArr_price[_loc6_] as LOL_Button;
            _loc7_.texture = GlobalFunction.getTexture("UI_equip_radio_0_0001");
            _loc6_++;
         }
         _loc7_ = mArr_price[param1] as LOL_Button;
         _loc7_.texture = GlobalFunction.getTexture("UI_equip_radio_0_0000");
         checkGuide();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalData.$mEventDispatcher.removeEventListener("profile_state_sync",onProfileStateSync);
         mCultureViewEpoch += 1;
         GlobalData.$mEventDispatcher.dispatchEventWith("change_team_member",false,GlobalData.$tempTeamSelect);
         if(mBox)
         {
            mBox.removeFromParent(true);
            mBox = null;
         }
         if(mBtn_foster)
         {
            mBtn_foster.removeEventListener("triggered",this.onTRIGGERED_btn);
            mBtn_foster.removeFromParent(true);
            mBtn_foster = null;
         }
         if(mAvatarIcon)
         {
            mAvatarIcon.removeFromParent(true);
            mAvatarIcon = null;
         }
         if(mBtn_save)
         {
            mBtn_save.removeEventListener("triggered",this.onTRIGGERED_btn);
            mBtn_save.removeFromParent(true);
            mBtn_save = null;
         }
         if(mBtn_cancel)
         {
            mBtn_cancel.removeEventListener("triggered",this.onTRIGGERED_btn);
            mBtn_cancel.removeFromParent(true);
            mBtn_cancel = null;
         }
         if(mTxt_powerNum)
         {
            mTxt_powerNum.removeFromParent(true);
            mTxt_powerNum = null;
         }
         if(mTxt_maxP)
         {
            mTxt_maxP.removeFromParent(true);
            mTxt_maxP = null;
         }
         if(mTxt_hp)
         {
            mTxt_hp.removeFromParent(true);
            mTxt_hp = null;
         }
         if(mTxt_damage)
         {
            mTxt_damage.removeFromParent(true);
            mTxt_damage = null;
         }
         if(mTxt_deph)
         {
            mTxt_deph.removeFromParent(true);
            mTxt_deph = null;
         }
         if(mTxt_dema)
         {
            mTxt_dema.removeFromParent(true);
            mTxt_dema = null;
         }
         if(mTxt_progress)
         {
            mTxt_progress.removeFromParent(true);
            mTxt_progress = null;
         }
         if(mTxt_myBook)
         {
            mTxt_myBook.removeFromParent(true);
            mTxt_myBook = null;
         }
         if(mTxt_hp_up)
         {
            mTxt_hp_up.removeFromParent(true);
            mTxt_hp_up = null;
         }
         if(mTxt_damage_up)
         {
            mTxt_damage_up.removeFromParent(true);
            mTxt_damage_up = null;
         }
         if(mTxt_deph_up)
         {
            mTxt_deph_up.removeFromParent(true);
            mTxt_deph_up = null;
         }
         if(mTxt_dema_up)
         {
            mTxt_dema_up.removeFromParent(true);
            mTxt_dema_up = null;
         }
         if(_upIcon)
         {
            _upIcon.removeFromParent(true);
            _upIcon = null;
         }
         if(_spRule)
         {
            _spRule.removeEventListener("touch",onPith);
            _spRule.removeFromParent(true);
            _spRule = null;
         }
         StarlingTools.removeChildrenClear(this);
      }
   }
}



