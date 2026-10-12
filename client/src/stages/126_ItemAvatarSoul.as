package com.meng52.game.ui.element
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.ui.screen.PanelCenterSoul;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import starling.display.DisplayObject;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   
   public class ItemAvatarSoul extends ItemBase
   {
      
      private var _bg:Scale9Image;
      
      private var mStatus_full:Boolean;
      
      private var mBtn:LOL_Scale9Button;
      
      private var mPlan_txt:TextField;
      
      private var mTxt_num:TextField;
      
      private var mCollect_txt:TextFieldHtmlRenderer;
      
      private var mTxt:TextField;
      
      private var mSoulBg:Image;
      
      private var avatarQuad:Quad;
      
      private var _avatar:Avatar;
      
      private var checkBtn:LOL_Scale9Button;
      
      public function ItemAvatarSoul()
      {
         super();
      }
      
      override public function layoutWH() : void
      {
         if(this._bg)
         {
            this.width = this._bg.width;
            this.height = this._bg.height;
         }
         tweenX(false);
      }
      
      override public function init(param1:Object) : void
      {
         mStatus_full = data["need"] <= data["current"];
         _bg = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",488,105,new Rectangle(110,55,70,20));
         _bg.x = 58;
         addChild(_bg);
         avatarQuad = Tools.newQuad(488,105,_bg.x,_bg.y,0);
         avatarQuad.alpha = 0;
         addChild(avatarQuad);
         avatarQuad.addEventListener("touch",avatarTouch);
         _avatar = new Avatar(data["id"]);
         var _loc3_:Object = {};
         _loc3_[data["id"]] = 1;
         var _loc2_:DisplayObject = GlobalFunction.getAwardByType("avatar_soul",_loc3_,false,null,"",true,1,this.parent.parent as List).ui;
         _loc2_.x = -42;
         _loc2_.y = _bg.y;
         addChild(_loc2_);
         mTxt_title = GlobalTextStyle.getTextField(data["name"],20,4926491,"left",165,35,GlobalConfig.FONT_1);
         mTxt_title.x = _bg.x + 26;
         mTxt_title.y = 18;
         addChild(this.mTxt_title);
         mCollect_txt = GlobalTextStyle.getHtmlTextRenderer();
         if(MainConfig.$isEnglish == true)
         {
            mCollect_txt.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97511,data["need"]),GlobalTextStyle.COLOR_task,30,15);
         }
         else
         {
            mCollect_txt.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97511,data["need"],data["name"]),GlobalTextStyle.COLOR_task,30,15);
         }
         mCollect_txt.x = mTxt_title.x;
         mCollect_txt.y = mTxt_title.y + 28;
         addChild(mCollect_txt);
         mPlan_txt = GlobalTextStyle.getTextField("",15,mStatus_full ? 13056 : 10027008,"left",200,29);
         mPlan_txt.text = GlobalLanguageStr.getLanguageStr(97508,data["current"],data["need"]);
         mPlan_txt.x = mTxt_title.x;
         mPlan_txt.y = mCollect_txt.y + 22;
         addChild(this.mPlan_txt);
         if(mStatus_full)
         {
            mBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20432),126,47,"UI_btn_enterGame_0_0000");
            mBtn.x = MainConfig.$isEnglish ? _bg.width - mBtn.width + 28 : _bg.width - mBtn.width + 15;
            mBtn.y = int((_bg.height - mBtn.height + 1) * 0.5);
            mBtn.fontSize = 25;
            addChild(mBtn);
            mBtn.showGlow();
            mBtn.addEventListener("triggered",mBtn_Triggerd);
         }
         else
         {
            mTxt = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97509),20,4926491,"left",80,35);
            mTxt.x = MainConfig.$isEnglish ? _bg.width - mTxt.width + 5 : _bg.width - mTxt.width - 2;
            mTxt.y = int((_bg.height - mTxt.height + 1) * 0.5);
            addChild(mTxt);
         }
      }
      
      private function avatarTouch(param1:TouchEvent) : void
      {
         var _loc5_:int = 0;
         var _loc2_:int = 0;
         var _loc4_:List = this.parent.parent as List;
         if(_loc4_.isScrolling)
         {
            return;
         }
         var _loc3_:Touch = param1.getTouch(stage);
         if(_loc3_ && _loc3_.phase == "ended")
         {
            _loc5_ = int(data["current"]);
            _loc2_ = int(data["need"]);
            if(_loc5_ < _loc2_)
            {
               if(MainConfig.$isEnglish == true)
               {
                  LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getLanguageStr(90600,_loc2_ - _loc5_));
               }
               else
               {
                  LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getLanguageStr(90600,_loc2_ - _loc5_,_avatar.avatarData.name));
               }
            }
            else
            {
               LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getLanguageStr(90604,_avatar.avatarData.name));
            }
         }
      }
      
      private function mBtn_Triggerd(param1:Event) : void
      {
         var _loc3_:int = 0;
         var _loc2_:int = 0;
         if(mStatus_full)
         {
            _loc3_ = this.index;
            _loc2_ = Tools.getElementNum(GlobalData.$userData.avatars);
            if(_loc2_ >= int(GlobalData.$userData.attrs.avatar_len))
            {
               GlobalFunction.popAvatarLen();
               return;
            }
            PanelCenterSoul.currSoulIndex = _loc3_;
            SendServiceAMFFun.send_user_avatar_soul(reService,{"aid":data["id"]});
         }
      }
      
      private function reService(param1:Object) : void
      {
         var _loc2_:* = null;
         var _loc7_:String = "compound";
         SoundManager.getOnlyExample().playSound(_loc7_);
         var _loc5_:Object = param1["params"];
         var _loc3_:Object = param1.data;
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.avatars = _loc3_.avatars;
            GlobalData.$userData.avatar_soul = _loc3_.avatar_soul;
         }
         var _loc6_:Object = {};
         _loc6_[_loc5_.aid] = 1;
         var _loc4_:Object = GlobalFunction.getAwardByType("avatar",_loc6_);
         GlobalFunction.popAward("avatar",GlobalLanguageStr.getLanguageStr(97514,_loc4_.msg),_loc6_,false);
         GlobalData.$mEventDispatcher.dispatchEventWith("update_avatarsoul_list");
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(_bg)
         {
            _bg.removeFromParent();
            _bg = null;
         }
         if(mPlan_txt)
         {
            mPlan_txt.removeFromParent();
            mPlan_txt = null;
         }
         if(mBtn)
         {
            mBtn.removeFromParent();
            mBtn = null;
         }
         if(mTxt_num)
         {
            mTxt_num.removeFromParent();
            mTxt_num = null;
         }
         if(mCollect_txt)
         {
            mCollect_txt.removeFromParent();
            mCollect_txt = null;
         }
         if(mTxt)
         {
            mTxt.removeFromParent();
            mTxt = null;
         }
         if(mSoulBg)
         {
            mSoulBg.removeFromParent();
            mSoulBg = null;
         }
         if(avatarQuad)
         {
            avatarQuad.removeFromParent();
            avatarQuad = null;
         }
         if(checkBtn)
         {
            checkBtn.removeFromParent();
            checkBtn = null;
         }
         StarlingTools.removeChildrenClear(this);
      }
   }
}

