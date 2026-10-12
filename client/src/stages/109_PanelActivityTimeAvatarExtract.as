package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.map.GameMapTools;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.game.ui.screen.PanelBase;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.game.ui.stage.LayoutUIPop;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.Tools;
   import starling.animation.Tween;
   import starling.core.Starling;
   import starling.display.DisplayObject;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.filters.ColorMatrixFilter;
   import starling.text.TextField;
   
   public class PanelActivityTimeAvatarExtract extends PanelBase
   {
      
      private var data:Object;
      
      private var ava:String;
      
      private var btn:LOL_Button;
      
      private var _bg:Image;
      
      private var imgAvatar:Image;
      
      private var btnAgain:LOL_Button;
      
      private var txt:TextField;
      
      private var txt1:TextField;
      
      private var _txt_coin:LOL_MutilTextFieldIcon;
      
      private var txtNum:int;
      
      private var _halo:Image;
      
      private var _tween:Tween;
      
      private var b:Boolean = false;
      
      private var que:Quad;
      
      private var avatar:Avatar;
      
      private var avatars:Array;
      
      private var isAvatar:Boolean = false;
      
      private var avatar_soul:Object;
      
      private var soul_sp:Sprite;
      
      private var avatarObj:Object = {};
      
      public function PanelActivityTimeAvatarExtract(param1:Object)
      {
         data = param1;
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         onAvatar(data);
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         LayoutUIPop._effect = true;
         if(btn)
         {
            btn.removeFromParent(true);
            btn.dispose();
         }
         if(que)
         {
            que.removeEventListener("touch",avatar.touchDetaiAvatar);
            que.removeFromParent(true);
            que.dispose();
         }
         if(_bg)
         {
            _bg.removeFromParent(true);
            _bg.dispose();
         }
         if(imgAvatar)
         {
            imgAvatar.removeFromParent(true);
            imgAvatar.dispose();
         }
         if(_halo)
         {
            _halo.removeFromParent(true);
            _halo.dispose();
         }
         if(_tween)
         {
            Starling.juggler.remove(_tween);
            _tween = null;
         }
         que = null;
         _halo = null;
         imgAvatar = null;
         _bg = null;
         btn = null;
      }
      
      private function onAvatar(param1:Object) : void
      {
         if(stage == null)
         {
            return;
         }
         var _loc7_:Object = null;
         var _loc8_:* = 0;
         var _loc6_:Object = null;
         var _loc3_:Object = null;
         var _loc4_:String = null;
         var _loc5_:Object = null;
         delUI();
         if(!data.payType)
         {
            _loc7_ = param1.data.avatars;
            for(var _loc9_:String in _loc7_)
            {
               _loc8_ = 0;
               while(_loc8_ < _loc7_[_loc9_].length)
               {
                  for(var _loc2_:String in _loc7_[_loc9_][_loc8_])
                  {
                     ava = _loc2_;
                  }
                  if(_loc9_ == "avatar")
                  {
                     isAvatar = true;
                     avatarObj[_loc2_] = _loc7_[_loc9_][_loc8_][_loc2_];
                     if(!GlobalFunction.isVersionedProfileReceipt(param1))
                     {
                        GlobalData.$userData.avatars[_loc2_] = _loc7_[_loc9_][_loc8_][_loc2_];
                     }
                  }
                  _loc6_ = GlobalData.$userData.avatar_soul;
                  if(_loc9_ == "avatar_soul")
                  {
                     isAvatar = false;
                     if(GlobalData.$userData.avatar_soul[_loc2_])
                     {
                        if(!GlobalFunction.isVersionedProfileReceipt(param1))
                        {
                           GlobalData.$userData.avatar_soul[_loc2_] += _loc7_[_loc9_][_loc8_][_loc2_];
                        }
                     }
                     else
                     {
                        if(!GlobalFunction.isVersionedProfileReceipt(param1))
                        {
                           GlobalData.$userData.avatar_soul[_loc2_] = _loc7_[_loc9_][_loc8_][_loc2_];
                        }
                     }
                     avatar_soul = _loc7_[_loc9_][_loc8_];
                  }
                  _loc8_++;
               }
            }
         }
         else
         {
            _loc3_ = param1.data.avatars;
            avatars = [];
            for(_loc9_ in _loc3_)
            {
               _loc8_ = 0;
               while(_loc8_ < _loc3_[_loc9_].length)
               {
                  for(_loc2_ in _loc3_[_loc9_][_loc8_])
                  {
                     _loc4_ = _loc2_;
                  }
                  if(_loc9_ == "avatar")
                  {
                     _loc5_ = {};
                     _loc5_["avatar"] = {};
                     _loc5_["avatar"][_loc4_] = _loc3_[_loc9_][_loc8_][_loc4_];
                     if(!GlobalFunction.isVersionedProfileReceipt(param1))
                     {
                        GlobalData.$userData.avatars[_loc4_] = _loc3_[_loc9_][_loc8_][_loc4_];
                     }
                     avatars.push(_loc5_);
                  }
                  if(_loc9_ == "avatar_soul")
                  {
                     _loc5_ = {};
                     _loc5_["avatar_soul"] = {};
                     _loc5_["avatar_soul"][_loc4_] = _loc3_[_loc9_][_loc8_][_loc4_];
                     if(GlobalData.$userData.avatar_soul[_loc4_])
                     {
                        if(!GlobalFunction.isVersionedProfileReceipt(param1))
                        {
                           GlobalData.$userData.avatar_soul[_loc4_] += _loc3_[_loc9_][_loc8_][_loc4_];
                        }
                     }
                     else
                     {
                        if(!GlobalFunction.isVersionedProfileReceipt(param1))
                        {
                           GlobalData.$userData.avatar_soul[_loc4_] = _loc3_[_loc9_][_loc8_][_loc4_];
                        }
                     }
                     avatars.push(_loc5_);
                  }
                  _loc8_++;
               }
            }
         }
         setUI();
      }
      
      private function setUI() : void
      {
         var _loc5_:ColorMatrixFilter = null;
         var _loc2_:String = null;
         var _loc6_:Number = NaN;
         var _loc3_:Object = null;
         var _loc7_:* = 0;
         var _loc1_:DisplayObject = null;
         _bg = GlobalFunction.createImage("png_activity_avatar_bg",true);
         _bg.x = GlobalData.$mStageWidth / 2 - _bg.width / 2;
         this.addChild(_bg);
         _halo = GlobalFunction.createImage("halo001",true);
         _loc5_ = new ColorMatrixFilter();
         _loc5_.adjustBrightness(0.3);
         _loc5_.adjustHue(-0.85);
         _halo.filter = _loc5_;
         _halo.pivotX = _halo.width / 2;
         _halo.pivotY = _halo.height / 2;
         _halo.x = GlobalData.$mStageWidth / 2;
         _halo.y = GlobalData.$mStageHeight / 2 - 50;
         this.addChild(_halo);
         _tween = new Tween(_halo,5000);
         _tween.animate("rotation",-628.3185307179587);
         _tween.repeatCount = 0;
         Starling.juggler.add(_tween);
         if(!avatars)
         {
            if(isAvatar)
            {
               _loc2_ = ((ava.split("_")[2] as String).split("|") as Array)[0];
               LayoutUIAnimation.getOnlyExample().popStars(int(_loc2_),0,0.5,0.2,0,2,false);
               LayoutUIAnimation.getOnlyExample().showAnimationLayer();
               avatar = new Avatar(ava);
               imgAvatar = GameMapTools.newAvatarImgById(ava);
               imgAvatar.x = GlobalData.$mStageWidth / 2;
               imgAvatar.y = GlobalData.$mStageHeight / 2 - imgAvatar.height / 5;
               this.addChild(imgAvatar);
               imgAvatar.visible = false;
               LayoutUIAnimation.getOnlyExample().popCasino(avatarObj,6,0,MainConfig.$casionBgUiName);
               que = new Quad(imgAvatar.width,imgAvatar.height);
               que.x = imgAvatar.x / 2 - 100;
               que.y = imgAvatar.y / 2 + 100;
               que.alpha = 0;
               this.addChild(que);
               que.addEventListener("touch",avatar.touchDetaiAvatar);
            }
            else
            {
               soul_sp = (GlobalFunction.getAwardByType("avatar_soul",avatar_soul,false,null,"",true) as Object).ui;
               soul_sp.scaleX = soul_sp.scaleY = 1.5;
               soul_sp.x = GlobalData.$mStageWidth / 2 - soul_sp.width / 2;
               soul_sp.y = GlobalData.$mStageHeight / 2 - soul_sp.height / 5 - soul_sp.height / 2;
               this.addChild(soul_sp);
            }
         }
         else
         {
            _loc6_ = 0;
            _loc7_ = 0;
            while(_loc7_ < avatars.length)
            {
               for(var _loc4_:String in avatars[_loc7_])
               {
                  _loc3_ = GlobalFunction.getAwardByType(_loc4_,avatars[_loc7_][_loc4_],false,null,"",true);
                  _loc1_ = _loc3_.ui;
                  _loc1_.x = GlobalData.$mStageWidth / 2 - _loc1_.width / 2 + 10;
                  _loc1_.y = GlobalData.$mStageHeight / 2 - 50 - _loc1_.height / 2 + 10;
                  _loc1_.x += Math.cos(_loc6_ * 3.141592653589793 / 180) * 200;
                  _loc1_.y += Math.sin(_loc6_ * 3.141592653589793 / 180) * 200;
                  _loc6_ += 360 / avatars.length;
                  this.addChild(_loc1_);
               }
               _loc7_++;
            }
         }
         txt1 = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90671) + ":" + GlobalData.$userData.coin,20,16777215,"center",800,46);
         txt1.autoSize = "center";
         txt1.x = GlobalData.$mStageWidth / 2 - txt1.width / 2;
         txt1.y = GlobalData.$mStageHeight / 2 + 250;
         this.addChild(txt1);
         txt = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97072,data.score),20,16777215,"center",800,46);
         txt.autoSize = "center";
         txt.x = GlobalData.$mStageWidth / 2 - txt.width / 2;
         txt.y = txt1.y + 30;
         this.addChild(txt);
         if(!data.score)
         {
            txt.visible = false;
         }
         btn = GlobalFunction.createButton_normal(GlobalLanguageStr.getLanguageStr(90407));
         this.addChild(btn);
         btn.x = GlobalData.$mStageWidth / 2 - btn.width - 50;
         btn.y = GlobalData.$mStageHeight / 2 + 400;
         btn.addEventListener("touch",onTouch);
         btnAgain = GlobalFunction.createButton_normal(GlobalLanguageStr.getLanguageStr(97662));
         this.addChild(btnAgain);
         btnAgain.x = GlobalData.$mStageWidth / 2 + 50;
         btnAgain.y = btn.y;
         btnAgain.addEventListener("touch",onTouchAgain);
         _txt_coin = new LOL_MutilTextFieldIcon("",GlobalData.$mConfig_simple.vip_avatar[data.payType],"UI_money_coin_0_0000");
         this.addChild(_txt_coin);
         _txt_coin.x = btnAgain.x + btnAgain.width / 2 - _txt_coin.width / 2;
         _txt_coin.y = btnAgain.y + btnAgain.height;
      }
      
      private function delUI() : void
      {
         if(soul_sp)
         {
            soul_sp.removeFromParent(true);
            soul_sp.dispose();
         }
         soul_sp = null;
         if(_txt_coin)
         {
            _txt_coin.removeFromParent(true);
            _txt_coin.dispose();
         }
         if(txt1)
         {
            txt1.removeFromParent(true);
            txt1.dispose();
         }
         if(_bg)
         {
            _bg.removeFromParent(true);
            _bg.dispose();
         }
         if(imgAvatar)
         {
            GlobalFunction.delTextureByBD(ava.split("|")[0]);
            imgAvatar.removeFromParent(true);
            imgAvatar.dispose();
         }
         if(txt)
         {
            txt.removeFromParent(true);
            txt.dispose();
         }
         if(btn)
         {
            btn.removeEventListener("touch",onTouch);
            btn.removeFromParent(true);
            btn.dispose();
         }
         if(btnAgain)
         {
            btnAgain.removeEventListener("touch",onTouchAgain);
            btnAgain.removeFromParent(true);
            btnAgain.dispose();
            LayoutUIAnimation.getOnlyExample().rePanel();
         }
         if(_halo)
         {
            GlobalFunction.delTextureByBD("halo001");
            _halo.removeFromParent(true);
            _halo.dispose();
         }
         if(_tween)
         {
            Starling.juggler.remove(_tween);
            _tween = null;
         }
         if(que)
         {
            que.removeFromParent(true);
            que.removeEventListener("touch",avatar.touchDetaiAvatar);
         }
         que = null;
         _halo = null;
         _txt_coin = null;
         txt1 = null;
         _bg = null;
         imgAvatar = null;
         txt = null;
         btn = null;
         btnAgain = null;
      }
      
      private function onTouchAgain(param1:TouchEvent) : void
      {
         var _loc3_:Object = null;
         var _loc2_:String = null;
         var _loc4_:Object = null;
         var _loc5_:Touch = param1.getTouch(this,"ended");
         if(_loc5_)
         {
            GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
            if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
            {
               GlobalFunction.popAvatarLen();
               return;
            }
            _loc3_ = GlobalData.$mConfig_ploy_system_simple.extract_avatar;
            if(GlobalData.$userData.coin >= GlobalData.$mConfig_simple.vip_avatar[data.payType])
            {
               if(b == false)
               {
                  _loc2_ = GlobalData.$mConfig_simple.show_id[5];
                  _loc4_ = {
                     "ok":sendFree,
                     "no":GlobalFunction.functionNull,
                     "aid":_loc2_
                  };
                  GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20427,1,GlobalData.$mConfig_simple.vip_avatar[data.payType]),GlobalTextStyle.COLOR_W_Y_Y_G),_loc4_);
               }
               else
               {
                  sendFree();
               }
            }
            else
            {
               GlobalFunction.popErrorCoin(GlobalData.$mConfig_simple.vip_avatar[data.payType]);
            }
         }
      }
      
      private function sendFree() : void
      {
         b = true;
         SendServiceAMFFun.send_user_get_lottery_activity(onAvatar,{
            "flag":data.payType,
            "hit":0
         });
      }
      
      private function onTouch(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(this,"ended");
         if(_loc2_)
         {
            LayoutUIAnimation.getOnlyExample().rePanel();
            this.onCLOSE_PANEL_SELF();
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_shopAndVIP");
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_casino_VIP");
         }
      }
   }
}

