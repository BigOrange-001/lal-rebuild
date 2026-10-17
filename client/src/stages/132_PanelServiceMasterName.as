package com.meng52.game.ui.screen
{
   import starling.display.DisplayObject;
   import com.adobe.text.NativeText;
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalLocalStore;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.map.GameMapTools;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.element.ItemInitAvatar;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.panel.PanelPopSelectName;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.data.ListCollection;
   import feathers.display.Scale9Image;
   import feathers.layout.TiledRowsLayout;
   import flash.events.FocusEvent;
   import flash.geom.Rectangle;
   import starling.animation.Juggler;
   import starling.animation.Tween;
   import starling.display.Image;
   import starling.display.MovieClip;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class PanelServiceMasterName extends PanelBase
   {
      
      public static const BTN_NAME_BACK:String = "btn_name_back";
      
      public static const BTN_NAME_ENTERGAME:String = "btn_name_enterGame";
      
      public static const BTN_NAME_NEXT:String = "btn_name_next";
      
      public static const BTN_NAME_RANDOM:String = "btn_name_random";
      
      private var nt:NativeText;
      
      private var mInputBg:Image;
      
      private var mBtn_enterGame:LOL_Button;
      
      private var mBtn_next:LOL_Scale9Button;
      
      private var mBtn_random:LOL_Button;
      
      private var mBox:Sprite;
      
      private var mTxt_name:TextField;
      
      private var mTime_random:Number = 0;
      
      private var mMc_avatar:MovieClip;
      
      private var mImg_avatar:Image;
      
      private var mMc:MovieClip;
      
      private var mTxt_info:TextFieldHtmlRenderer;
      
      private var mTxt_selectHero:TextField;
      
      private var mTopBg_L:Image;
      
      private var mTopBg_R:Image;
      
      private var mTips_box:Sprite;
      
      public function PanelServiceMasterName()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         var _loc7_:Object = null;
         var _loc8_:int = 0;
         this.removeEventListener("addedToStage",initializeHandler);
         GlobalData.$mGameClassObject.closePopUp();
         mImgBg = GlobalFunction.get_png_bg_avatar();
         mImgBg.blendMode = "none";
         this.addChild(mImgBg);
         GlobalData.$mGameClassObject.mBgImg.visible = false;
         mTxt_selectHero = GlobalFunction.createTextField(230,60,GlobalLanguageStr.getLanguageStr(20001),"",25,16777215);
         mTxt_selectHero.x = 10;
         mTxt_selectHero.y = 10;
         this.addChild(mTxt_selectHero);
         if(MainConfig.$isEnglish)
         {
            mTxt_selectHero.x = 30;
            mTxt_selectHero.y = 20;
         }
         var _loc4_:Array = GlobalData.$mConfig_simple.initialize_avatar as Array;
         var _loc9_:int = Tools.getRandom(0,_loc4_.length - 1);
         GlobalData.$mInitAvatarID = _loc4_[_loc9_];
         var _loc5_:Array = [];
         _loc8_ = 0;
         while(_loc8_ < _loc4_.length)
         {
            _loc7_ = {
               "id":_loc4_[_loc8_],
               "index":_loc8_
            };
            _loc5_.push(_loc7_);
            _loc8_++;
         }
         var _loc2_:TiledRowsLayout = new TiledRowsLayout();
         _loc2_.horizontalAlign = "center";
         _loc2_.verticalAlign = "top";
         _loc2_.tileHorizontalAlign = "left";
         _loc2_.tileVerticalAlign = "top";
         this.mList = new List();
         this.mList.width = GlobalData.$mStageWidth;
         this.mList.height = 90 * 2 + 40;
         this.mList.layout = _loc2_;
         this.mList.isSelectable = false;
         this.mList.itemRendererType = ItemInitAvatar;
         this.mList.dataProvider = new ListCollection(_loc5_);
         this.mList.x = int((GlobalData.$mStageWidth - 160 * _loc5_.length) * 0.5);
         this.addChild(this.mList);
         this.mBox = new Sprite();
         this.addChild(this.mBox);
         var _loc3_:Scale9Image = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",640,205,new Rectangle(110,55,70,20));
         _loc3_.x = int((GlobalData.$mStageWidth - _loc3_.width) * 0.5);
         _loc3_.y = GlobalData.$mStageHeight - _loc3_.height;
         this.mBox.addChild(_loc3_);
         var _loc6_:Image = GlobalFunction.createImage("UI_help_style_0_0000");
         _loc6_.width = GlobalData.$mStageWidth - 60;
         _loc6_.x = int((GlobalData.$mStageWidth - _loc6_.width) * 0.5);
         _loc6_.y = _loc3_.y + _loc3_.height - 60;
         this.mBox.addChild(_loc6_);
         mTxt_name = GlobalTextStyle.getTextField("",30,1513239,"center",GlobalData.$mStageWidth,35);
         mTxt_name.x = 0;
         mTxt_name.y = _loc3_.y + 20;
         this.mBox.addChild(mTxt_name);
         mTopBg_L = GlobalFunction.createImage("UI_help_style_1_0000");
         mTopBg_L.x = mTxt_name.x + 70;
         mTopBg_L.y = _loc3_.y + 20;
         this.mBox.addChild(mTopBg_L);
         mTopBg_R = GlobalFunction.createImage("UI_help_style_1_0000");
         mTopBg_R.scaleX = -1;
         mTopBg_R.x = mTxt_name.x + mTxt_name.width - 70;
         mTopBg_R.y = mTopBg_L.y;
         this.mBox.addChild(mTopBg_R);
         this.mBtn_next = new LOL_Scale9Button(GlobalLanguageStr.getStr(90418),150,70,"UI_btn_normalFun_0000");
         this.mBtn_next.name = "btn_name_next";
         this.mBtn_next.x = int((GlobalData.$mStageWidth - this.mBtn_next.width) * 0.5);
         this.mBtn_next.y = _loc3_.y - this.mBtn_next.height;
         this.addChild(this.mBtn_next);
         this.mBtn_next.addEventListener("triggered",onTRIGGERED);
         setUIAvatar();
      }
      
      public function setInputText() : void
      {
         nt = null;
         nt = new NativeText(1);
         nt.autoCorrect = true;
         nt.textAlign = "center";
         nt.fontSize = 30 * GlobalData.$mStage$Starling_h;
         nt.maxChars = 16;
         nt.color = 16777215;
         nt.assignFocus();
         nt.fontFamily = GlobalConfig.FONT_1;
         nt.text = "";
         nt.width = GlobalData.$mStarling.viewPort.width;
         nt.height = 46 * 2 * GlobalData.$mStage$Starling_h;
         nt.x = GlobalData.$isNotFullScreenX;
         nt.y = int((mInputBg.y + 40 + 5) * GlobalData.$mStage$Starling_h + GlobalData.$mStarling.viewPort.y);
         nt.addEventListener("focusIn",onFOCUS);
         GlobalData.$mStarling.nativeStage.addChild(nt);
         selectRandomName();
      }
      
      private function setTipsBox() : void
      {
         this.delTipsBox();
         this.mTips_box = new Sprite();
         this.addChild(this.mTips_box);
         var _loc1_:Quad = Tools.newQuad(GlobalData.$mStageWidth,GlobalData.$mStageHeight,0,0,1118481);
         _loc1_.alpha = 0.3;
         this.mTips_box.addChildAt(_loc1_,0);
         mInputBg = GlobalFunction.createImage("UI_selectService_txt_name_0000");
         mInputBg.x = int((GlobalData.$mStageWidth - mInputBg.width) * 0.5);
         mInputBg.y = int(GlobalData.$mStageHeight * 0.1);
         this.mTips_box.addChild(mInputBg);
         this.mBtn_enterGame = GlobalFunction.createButtonStarling("UI_selectService_btn_ksyx_0000");
         this.mBtn_enterGame.name = "btn_name_enterGame";
         this.mTips_box.addChild(this.mBtn_enterGame);
         this.mBtn_enterGame.x = int((GlobalData.$mStageWidth - this.mBtn_enterGame.width) * 0.5);
         this.mBtn_enterGame.y = mInputBg.y + mInputBg.height - this.mBtn_enterGame.height - 10;
         this.mBtn_enterGame.addEventListener("triggered",this.onTRIGGERED);
         this.mBtn_back = GlobalFunction.createButtonStarling("UI_selectService_bg_back_0000");
         this.mBtn_back.name = "btn_name_back";
         this.mBtn_back.x = mInputBg.x + 20;
         this.mBtn_back.y = mInputBg.y + mInputBg.height - this.mBtn_back.height - 20;
         this.mBtn_back.addEventListener("triggered",onTRIGGERED);
         mBtn_random = GlobalFunction.createButton_5(GlobalLanguageStr.getLanguageStr(20306));
         this.mBtn_random.name = "btn_name_random";
         this.mBtn_random.x = mInputBg.x + mInputBg.width - mBtn_random.width - 20;
         this.mBtn_random.y = mInputBg.y + mInputBg.height - mBtn_random.height - 10;
         this.mTips_box.addChild(this.mBtn_random);
         this.mBtn_random.addEventListener("triggered",onTRIGGERED);
         this.setInputText();
      }
      
      private function selectRandomName() : void
      {
         var re_send_user_get_uname:* = function(param1:Object):void
         {
            if(nt)
            {
               nt.text = String(param1.data);
            }
         };
         SendServiceAMFFun.send_user_get_uname(re_send_user_get_uname,{"lan_type":GlobalData.$gameLanguage});
      }
      
      private function delTipsBox() : void
      {
         if(this.nt)
         {
            if(this.nt.parent)
            {
               this.nt.parent.removeChild(this.nt);
            }
         }
         if(this.mTips_box)
         {
            StarlingTools.removeChildrenClear(this.mTips_box);
            this.mTips_box.removeFromParent(true);
            this.mTips_box = null;
         }
      }
      
      private function onFOCUS(param1:FocusEvent) : void
      {
         param1.currentTarget.removeEventListener("focusIn",onFOCUS);
         if(param1.type == "focusIn")
         {
            if(this.nt)
            {
               this.nt.text = "";
            }
         }
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         this.delTipsBox();
         if(mTxt_name)
         {
            mTxt_name.dispose();
         }
         if(mTxt_info)
         {
            mTxt_info.dispose();
         }
         if(mTxt_selectHero)
         {
            mTxt_selectHero.dispose();
            mTxt_selectHero.removeFromParent(true);
         }
         if(mTopBg_L)
         {
            mTopBg_L.dispose();
            mTopBg_L.removeFromParent(true);
         }
         if(mTopBg_R)
         {
            mTopBg_R.dispose();
            mTopBg_R.removeFromParent(true);
         }
         mTopBg_L = null;
         mTopBg_R = null;
         StarlingTools.removeChildrenClear(this);
         this.clear();
         mTxt_selectHero = null;
         mTxt_name = null;
         mTxt_info = null;
         GlobalFunction.delTextureByBD("png_bg_avatar");
      }
      
      public function updateEx() : void
      {
         setUIAvatar();
      }
      
      private function setUIAvatar() : void
      {
         var _avatar:Avatar;
         var _rec:Rectangle;
         var _configInfoNum:int;
         var _configInfo:String;
         var _juggler:Juggler;
         var _tween:Tween;
         var _y:int;
         var _attrs:*;
         if(mMc_avatar)
         {
            mMc_avatar.removeFromParent(true);
         }
         if(mTxt_info)
         {
            mTxt_info.removeFromParent(true);
         }
         if(mImg_avatar)
         {
            mImg_avatar.removeFromParent(true);
         }
         mTxt_info = null;
         mMc_avatar = null;
         mImg_avatar = null;
         _avatar = new Avatar(GlobalData.$mInitAvatarID,null);
         mTxt_name.text = _avatar.avatarData.name;
         this.mTxt_info = GlobalTextStyle.getHtmlTextRenderer();
         this.mTxt_info.mLayoutFun = function():void
         {
            _rec = mTxt_info.getTextSnapshotFrame();
            mTxt_info.x = int((GlobalData.$mStageWidth - _rec.width) * 0.5);
            mTxt_info.y = mTxt_name.y + 50;
         };
         _configInfoNum = int(GlobalData.$mConfig_simple.initialize_info[GlobalData.$mInitAvatarID]);
         _configInfo = GlobalLanguageStr.getLanguageStr(_configInfoNum);
         this.mTxt_info.text = Tools.formatLineX(_configInfo,GlobalTextStyle.COLOR_G_R_R_R,20,20);
         this.mBox.addChild(this.mTxt_info);
         if(MainConfig.$isEnglish)
         {
            mTxt_info.text = Tools.formatLineX(_configInfo,GlobalTextStyle.COLOR_G_R_R_R,25,20);
         }
         _juggler = GlobalData.$mStarling.juggler;
         SoundManager.getOnlyExample().playAvatar(_avatar.avatarData.soundId);
         if(GlobalData.$mConfig_client["new_user_avatar_clip"] > 0)
         {
            mMc_avatar = DisplayTools.newMc(GlobalData.$mInitAvatarID + "_MC",0,0,15);
            mMc_avatar.x = int(GlobalData.$mStageWidth * 0.5) + mBox.x;
            mMc_avatar.y = mImgBg.y + 665;
            GlobalData.$mStarling.juggler.add(mMc_avatar);
            _y = mMc_avatar.y;
            if(mMc)
            {
               mMc.removeFromParent(true);
            }
            _attrs = {
               "id":"e024",
               "x":mMc_avatar.x,
               "y":_y,
               "sc":2
            };
            _attrs.par = this;
            DisplayTools.addEffectOne(_attrs);
            this.addChild(mMc_avatar);
            mMc_avatar.alpha = 0;
            _tween = new Tween(mMc_avatar,0.4,"easeInOut");
            _tween.fadeTo(1);
            _juggler.add(_tween);
            _y = 0;
            _juggler.removeTweens(mBox);
            mBox.y = _y + 100;
            _tween = new Tween(mBox,0.4,"easeOut");
            _tween.animate("y",_y);
            _juggler.add(_tween);
         }
         else
         {
            mImg_avatar = GameMapTools.newAvatarImg(_avatar.resId);
            mImg_avatar.pivotX = mImg_avatar.width * 0.5;
            mImg_avatar.pivotY = mImg_avatar.height * 0.8;
            mImg_avatar.x = int(GlobalData.$mStageWidth * 0.5) + mBox.x;
            mImg_avatar.y = mImgBg.y + 705;
            _y = mImg_avatar.y;
            if(mMc)
            {
               mMc.removeFromParent(true);
            }
            _attrs = {
               "id":"e024",
               "x":mImg_avatar.x,
               "y":_y,
               "sc":2
            };
            _attrs.par = this;
            DisplayTools.addEffectOne(_attrs);
            this.addChild(mImg_avatar);
            mImg_avatar.alpha = 0;
            _tween = new Tween(mImg_avatar,0.4,"easeInOut");
            _tween.fadeTo(1);
            _juggler.add(_tween);
            _y = 0;
            _juggler.removeTweens(mBox);
            mBox.y = _y + 100;
            _tween = new Tween(mBox,0.4,"easeOut");
            _tween.animate("y",_y);
            _juggler.add(_tween);
         }
         _avatar.clear();
         _avatar = null;
      }
      
      private function onTRIGGERED(param1:Event) : void
      {
         var _loc3_:String = null;
         var _loc4_:DisplayObject = param1.currentTarget as DisplayObject;
         var _loc2_:String = _loc4_.name;
         if(_loc2_ == "btn_name_back")
         {
            this.delTipsBox();
         }
         else if(_loc2_ == "btn_name_enterGame")
         {
            if(this.nt && this.nt.text != "")
            {
               _loc3_ = GlobalFunction.checkName(this.nt.text);
               if(_loc3_)
               {
                  GlobalFunction.popError(_loc3_);
               }
               else
               {
                  GlobalData.$mUserName = this.nt.text;
                  SendServiceAMFFun.send_user_init_user(this.re_init_user,{
                     "name":GlobalData.$mUserName,
                     "aid":GlobalData.$mInitAvatarID
                  });
               }
            }
            else
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90011));
            }
         }
         else if(_loc2_ == "btn_name_next")
         {
            GlobalData.$mGameClassObject.openPopForPanel(new PanelPopSelectName());
         }
         else if(_loc2_ == "btn_name_random")
         {
            this.selectRandomName();
         }
      }
      
      private function re_init_user(param1:Object) : void
      {
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            return;
         }



         if(this.stage)
         {
            GlobalData.$mGameClassObject.initUIGroup();
         }
         if(GlobalLocalStore.$pf_type_curr == "hggoogle")
         {
            if(MainConfig.classAppsflyer)
            {
               MainConfig.classAppsflyer.sendTrackingWithEvent("role creation",GlobalData.$userData.uid + "");
            }
         }
      }
   }
}

