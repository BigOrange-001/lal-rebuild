package com.meng52.game.ui.panel
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.map.GameMapConfig;
   import com.meng52.game.module.map.GameMapTools;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.element.HtmlTextField;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelBase;
   import com.meng52.game.ui.screen.PanelCenterActivity;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import starling.animation.Juggler;
   import starling.animation.Tween;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   
   public class PanelActivityMorphUp extends PanelBase
   {
      
      private var mImg_bg:Image;
      
      private var m9x9_bg:Scale9Image;
      
      private var mTxt_info:TextFieldHtmlRenderer;
      
      private var mQuad:Quad;
      
      private var mBox:Sprite;
      
      private var mCard1:Sprite;
      
      private var mCard2:Sprite;
      
      private var mBtn_morph:LOL_Scale9Button;
      
      private var _bg:Scale9Image;
      
      private var _bg2:Scale9Image;
      
      public function PanelActivityMorphUp()
      {
         super();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(mBox)
         {
            StarlingTools.removeChildrenClear(mBox);
            mBox.removeFromParent(true);
         }
         if(mBtn_morph)
         {
            StarlingTools.removeChildrenClear(mBtn_morph);
            mBtn_morph.removeFromParent(true);
         }
         mBox = null;
         mBtn_morph = null;
         if(mImg_bg)
         {
            mImg_bg.removeFromParent(true);
         }
         if(m9x9_bg)
         {
            m9x9_bg.removeFromParent(true);
         }
         if(mImg9x9_bg)
         {
            mImg9x9_bg.removeFromParent(true);
            mImg9x9_bg.dispose();
         }
         if(mTxt_info)
         {
            mTxt_info.removeFromParent(true);
         }
         if(_bg)
         {
            _bg.removeFromParent(true);
            _bg.dispose();
         }
         if(_bg2)
         {
            _bg2.removeFromParent(true);
            _bg2.dispose();
         }
         mImg_bg = null;
         m9x9_bg = null;
         mImg9x9_bg = null;
         mTxt_info = null;
         mQuad = null;
         mCard1 = null;
         mCard2 = null;
         _bg = null;
         _bg2 = null;
         if(!checkOpen_morph())
         {
            PanelCenterActivity.$activityFunObj = GlobalFunction.getActivityFun("task");
            GlobalData.$mGameClassObject.mLayoutUICenter.mPanelCenterActivity.updateList();
         }
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(20467),750);
         setUIs();
      }
      
      private function setUIs() : void
      {
         var _arr:Array;
         var _arrowsImg:Image;
         mImg9x9_bg = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",590,130,new Rectangle(110,60,30,15));
         mImg9x9_bg.x = int((GlobalData.$mStageWidth - mImg9x9_bg.width) * 0.5) + 2;
         mImg9x9_bg.y = 90;
         addChild(mImg9x9_bg);
         _arr = [Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90228),[4926491,4926491,4926491,10027008],MainConfig.$isEnglish ? 30 : 28,MainConfig.$isEnglish ? 17 : 20)];
         mTxt_info = GlobalTextStyle.getHtmlTextRenderer();
         mTxt_info.touchable = false;
         mTxt_info.text = Tools.formatHtmlTextBr(_arr);
         mTxt_info.width = 540;
         mTxt_info.mLayoutFun = function():void
         {
            var _loc1_:Rectangle = mTxt_info.getTextSnapshotFrame();
            mTxt_info.x = mImg9x9_bg.x + 32;
            mTxt_info.y = mImg9x9_bg.y + int((mImg9x9_bg.height - _loc1_.height) * 0.5) - 5;
         };
         addChild(mTxt_info);
         _bg = GlobalFunction.createScale9Image("UI_bg_9slice_7_0000",280,410,new Rectangle(30,25,15,15));
         _bg.x = 30;
         _bg.y = mImg9x9_bg.y + mImg9x9_bg.height + 10;
         addChild(_bg);
         _bg2 = GlobalFunction.createScale9Image("UI_bg_9slice_7_0000",280,410,new Rectangle(30,25,15,15));
         _bg2.x = _bg.x + _bg.width + 20;
         _bg2.y = _bg.y;
         addChild(_bg2);
         _arrowsImg = GlobalFunction.createImage("UI_tag_right_0_0000");
         _arrowsImg.x = _bg.x + _bg.width;
         _arrowsImg.y = _bg.y + _bg.height * 0.5 + 20;
         this.addChild(_arrowsImg);
         mBox = new Sprite();
         mBox.x = GameMapConfig.SCREEN_WIDTH * 0.5;
         mBox.y = mImg9_baseBg.y + 300;
         addChild(mBox);
         mCard1 = new Sprite();
         mCard1.x = -GameMapConfig.SCREEN_WIDTH * 0.24;
         mBox.addChild(mCard1);
         mCard2 = new Sprite();
         mCard2.x = GameMapConfig.SCREEN_WIDTH * 0.24;
         mBox.addChild(mCard2);
         setCard(1);
         setCard(2);
         mBtn_morph = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20467),150,70,"UI_btn_normalFun_0000");
         if(MainConfig.$isEnglish)
         {
            mBtn_morph.fontSize = 21;
         }
         mBtn_morph.shadowFilter();
         mBtn_morph.pivotX = mBtn_morph.width / 2;
         mBtn_morph.y = _bg.y + 118;
         mBtn_morph.addEventListener("triggered",onTRIGGERED_send);
         mBox.addChild(mBtn_morph);
      }
      
      private function setCard(param1:int) : void
      {
         var _loc10_:Sprite = null;
         var _loc3_:Avatar = null;
         var _loc19_:Image = null;
         var _loc6_:Sprite = null;
         var _loc9_:int = 0;
         var _loc5_:HtmlTextField = null;
         var _loc11_:int = 0;
         var _loc14_:int = 0;
         var _loc7_:Array = null;
         var _loc15_:String = null;
         var _loc16_:int = 0;
         var _loc12_:Array = null;
         var _loc2_:Array = null;
         var _loc4_:LOL_Button = null;
         var _loc8_:Rectangle = null;
         var _loc18_:String = null;
         var _loc17_:int = 90220;
         var _loc13_:Function = onTRIGGERED_avatar1;
         _loc10_ = param1 == 1 ? mCard1 : mCard2;
         if(GlobalData.$tempMorphItem)
         {
            _loc3_ = new Avatar(GlobalData.$tempMorphItem.id,GlobalData.$tempMorphItem);
            if(param1 == 2)
            {
               _loc3_.lv = _loc3_.getLvMax();
               _loc3_.morph = 1;
               _loc17_ = 90221;
               _loc13_ = onTRIGGERED_avatar2;
               _loc19_ = DisplayTools.newImg("z_morph");
               _loc19_.scaleX = _loc19_.scaleY = 0.5;
               _loc19_.x = -20;
               _loc10_.addChild(_loc19_);
            }
            _loc19_ = GameMapTools.newAvatarImg(_loc3_.resId);
            _loc19_.scaleX = _loc19_.scaleY = 0.58;
            _loc19_.y = 67;
            _loc10_.addChildAt(_loc19_,0);
            _loc11_ = 200;
            _loc6_ = _loc3_.getAvatarRes();
            _loc6_.x = MainConfig.$isEA ? -120 : -110;
            _loc6_.y = _loc11_;
            _loc10_.addChild(_loc6_);
            _loc6_.addEventListener("touch",_loc13_);
            _loc11_ += 10;
            _loc14_ = int(_loc3_.lv <= 0 ? 1 : _loc3_.lv);
            _loc16_ = _loc3_.getLeadership(true) - _loc3_.getLeadership();
            _loc15_ = _loc3_.getLeadership().toString();
            if(_loc16_ > 0)
            {
               _loc15_ = GlobalLanguageStr.getLanguageStr(20207,_loc15_);
            }
            _loc15_ = GlobalLanguageStr.getLanguageStr(20090,_loc15_);
            _loc12_ = GlobalTextStyle.COLOR_F_F_F_F;
            if(_loc17_ == 90221)
            {
               _loc12_ = GlobalTextStyle.COLOR_382E16;
            }
            _loc7_ = [Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20079,_loc14_),_loc12_,1000,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20081,_loc3_.getLvMax()),_loc12_,1000,20),Tools.formatLineX(_loc15_,_loc12_,1000,20)];
            _loc2_ = _loc3_.getLoveList();
            if(_loc2_[0] > 0)
            {
               _loc4_ = GlobalFunction.createButtonStarling("UI_love_bg_0000",{
                  "t":_loc2_[0] + "",
                  "fs":14
               });
               _loc8_ = _loc4_.textBounds;
               _loc4_.textPoint = new Point(-3,-5);
               _loc4_.x = 75;
               _loc4_.y = _loc11_ + 54;
               _loc4_.addEventListener("touch",onTRIGGERED_love);
            }
            _loc18_ = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(_loc17_),GlobalTextStyle.COLOR_W_Y_Y_Y,20,20);
            _loc5_ = new HtmlTextField(400,40,_loc18_,true,GlobalConfig.FONT_0);
            _loc5_.x = MainConfig.$isEA ? _loc5_.width / 2 - 400 : (MainConfig.$isEnglish ? -_loc5_.width / 2 - 18 : -_loc5_.width / 2 - 45);
            _loc5_.y = _bg.y - 290;
            _loc10_.addChild(_loc5_);
            _loc9_ = 0;
            while(_loc9_ < _loc7_.length)
            {
               _loc5_ = new HtmlTextField(400,40,_loc7_[_loc9_],true,GlobalConfig.FONT_0);
               _loc5_.touchable = false;
               _loc5_.hAlign = "left";
               _loc5_.vAlign = "top";
               _loc5_.x = MainConfig.$isEA ? -20 : -10;
               _loc5_.y = _loc11_ + _loc9_ * 25;
               _loc10_.addChild(_loc5_);
               _loc9_++;
            }
         }
      }
      
      protected function onTRIGGERED_love(param1:TouchEvent) : void
      {
         var _loc2_:Avatar = null;
         var _loc4_:Array = null;
         var _loc6_:int = 0;
         var _loc5_:String = null;
         var _loc3_:String = null;
         var _loc7_:Touch = param1.getTouch(this);
         if(!_loc7_)
         {
            return;
         }
         if(_loc7_.phase == "ended")
         {
            if(GlobalData.$tempMorphItem)
            {
               _loc2_ = new Avatar(GlobalData.$tempMorphItem.id,GlobalData.$tempMorphItem);
            }
            if(_loc2_)
            {
               _loc4_ = _loc2_.getLoveList();
               _loc6_ = _loc2_.getLeadership(true) - _loc2_.getLeadership();
               _loc5_ = GlobalLanguageStr.getLanguageStr(20225,_loc4_[0],_loc6_,GlobalData.$mConfig_simple.love_up[0]);
               _loc5_ = Tools.formatLineX(_loc5_,GlobalTextStyle.COLOR_W_Y_Y_G);
               _loc3_ = GlobalData.$mConfig_simple.show_id[16];
               GlobalFunction.popAlert("",_loc5_,{"aid":_loc3_});
               param1.stopPropagation();
            }
         }
      }
      
      private function onTRIGGERED_avatar1(param1:TouchEvent) : void
      {
         var _loc2_:Avatar = null;
         var _loc3_:Touch = param1.getTouch(this);
         if(!GlobalData.$tempMorphItem)
         {
            return;
         }
         if(!_loc3_)
         {
            return;
         }
         if(_loc3_.phase == "ended")
         {
            _loc2_ = new Avatar(GlobalData.$tempMorphItem.id,GlobalData.$tempMorphItem);
            GlobalFunction.setDetaiAvatar(_loc2_);
         }
      }
      
      private function onTRIGGERED_avatar2(param1:TouchEvent) : void
      {
         var _loc2_:Avatar = null;
         var _loc3_:Touch = param1.getTouch(this);
         if(!GlobalData.$tempMorphItem)
         {
            return;
         }
         if(!_loc3_)
         {
            return;
         }
         if(_loc3_.phase == "ended")
         {
            _loc2_ = new Avatar(GlobalData.$tempMorphItem.id,GlobalData.$tempMorphItem);
            _loc2_.lv = _loc2_.getLvMax();
            _loc2_.morph = 1;
            _loc2_.mData = _loc2_.toDataNormalObj();
            GlobalFunction.setDetaiAvatar(_loc2_);
         }
      }
      
      private function onTRIGGERED_send(param1:Event) : void
      {
         var _fun:Object;
         var _morph:Object;
         var _avatar:Avatar;
         var _info:String;
         var _event:Event = param1;
         var gotoMorph:* = function():void
         {
            var _loc1_:Object = {"aid":GlobalData.$tempMorphItem.id};
            SendServiceAMFFun.send_user_morph(re_morph,_loc1_);
         };
         if(GlobalData.$tempMorphItem)
         {
            _fun = {
               "ok":gotoMorph,
               "no":GlobalFunction.functionNull
            };
            _morph = GlobalData.$mConfig_ploy_system_simple.morph;
            _avatar = new Avatar(GlobalData.$tempMorphItem.id,GlobalData.$tempMorphItem);
            _avatar.morph = 1;
            _info = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90213,_avatar.avatarData.name,_avatar.getLvMax(),_avatar.getLeadership()),GlobalTextStyle.COLOR_W_Y_Y_G,20);
            GlobalFunction.popAlert("",_info,_fun);
         }
         else
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90209));
         }
      }
      
      override public function onTRIGGERED_closePanel(param1:Event) : void
      {
         GlobalData.$mGameClassObject.closePopForPanel(mPop_currID);
      }
      
      private function checkOpen_morph() : Boolean
      {
         return GlobalFunction.checkMorph() >= 0;
      }
      
      private function re_morph(param1:Object) : void
      {
         if(this.stage == null) return;
         SoundManager.getOnlyExample().playSound("E_8003",0.3);
         var _loc4_:String = param1["params"].aid;
         var _loc5_:Object = param1.data;
         var _loc3_:Object = _loc5_.avatar;
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
         GlobalFunction.changeUserDataAvatars(_loc4_,_loc3_);
         }
         var _loc2_:Avatar = new Avatar(_loc4_,_loc3_);
         GlobalFunction.clearMorphItems();
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
         GlobalData.$userData.attrs.morph = _loc5_.attr_morph;
         }
           if(!GlobalFunction.isVersionedProfileReceipt(param1))
           {
           GlobalData.$userData.coin = _loc5_.coin;
           }
           if(!GlobalFunction.isVersionedProfileReceipt(param1))
           {
           GlobalData.$userData.attrs.dust = _loc5_.dust;
           }
           GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin(0);
         mBtn_morph.visible = false;
         onCLOSE_PANEL_SELF();
         LayoutUIAnimation.getOnlyExample().clearAnimationLayer();
         LayoutUIAnimation.getOnlyExample().popCasino([_loc2_],5,0,MainConfig.$betterBgUiName);
      }
      
      private function setItemUIs() : void
      {
         mBox.touchable = false;
         var _loc1_:String = "50016";
         LayoutUIAnimation.getOnlyExample().popSuperWord(_loc1_,2,0.65);
         GlobalData.$mGameClassObject.touchable = true;
      }
      
      private function showMorph(param1:Object) : void
      {
         var _tween:Tween;
         var _juggler:Juggler;
         var i:int;
         var _x:int;
         var _time:Number;
         var _data:Object = param1;
         if(!mBox)
         {
            return;
         }
         _juggler = GlobalData.$mStarling.juggler;
         i = 0;
         _x = (mCard1.x + mCard2.x) / 2;
         _time = 0.6;
         _tween = new Tween(mBtn_morph,_time / 2);
         _tween.fadeTo(0);
         _juggler.add(_tween);
         _tween = new Tween(mCard1,_time,"easeOutBack");
         _tween.animate("x",_x);
         _tween.fadeTo(0);
         _juggler.add(_tween);
         _tween = new Tween(mCard2,_time,"easeOutBack");
         _tween.animate("x",_x);
         _tween.onComplete = function():void
         {
            setItemUIs();
            mBtn_morph.visible = false;
         };
         _juggler.add(_tween);
      }
   }
}

