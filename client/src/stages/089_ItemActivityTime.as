package com.meng52.game.ui.element
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.controls.renderers.IListItemRenderer;
   import flash.geom.Rectangle;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   
   public class ItemActivityTime extends ItemBase implements IListItemRenderer
   {
      
      private var mBtn_to:LOL_Scale9Button;
      
      private var mBox_UIs:Sprite;
      
      private var mName:String;
      
      private var da:Object;
      
      private var txt_Integral:TextField;
      
      public function ItemActivityTime()
      {
         super();
      }
      
      override public function layoutWH() : void
      {
         if(!this.mScale9Image)
         {
         }
         tweenX();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         this.removeEventListener("touch",onTOUCH_ui);
         if(mBox_UIs)
         {
            mBox_UIs.unflatten();
            StarlingTools.removeChildrenClear(mBox_UIs);
         }
         if(mBtn_to)
         {
            mBtn_to.removeEventListener("triggered",onTRIGGERED_to);
            mBtn_to.removeFromParent(true);
         }
         this.clear();
         mBox_UIs = null;
         mBtn_to = null;
      }
      
      override public function init(param1:Object) : void
      {
         da = {};
         for(var _loc9_:String in param1)
         {
            da.aid = _loc9_;
            da.score = param1[_loc9_];
         }
         var _loc6_:Boolean = this.data["indexID_s"] == "equip";
         mBox_UIs = new Sprite();
         addChild(mBox_UIs);
         var _loc8_:Boolean = true;
         this.mScale9Image = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",480,100,new Rectangle(110,55,70,20));
         mScale9Image.y = 5;
         mBox_UIs.x = 100;
         mBox_UIs.addChild(this.mScale9Image);
         this.width = this.mScale9Image.width + 100;
         this.height = this.mScale9Image.height + 10;
         var _loc2_:Number = this.mScale9Image.width * 0.5;
         var _loc4_:TextField = null;
         var _loc5_:TextField = null;
         var _loc7_:String = "";
         mBtn_to = new LOL_Scale9Button(GlobalLanguageStr.getStr(20459),110,47,"UI_btn_enterGame_0_0000");
         addChild(mBtn_to);
         mBtn_to.x = this.mScale9Image.x + this.mScale9Image.width - 30;
         mBtn_to.y = _loc6_ ? mScale9Image.y + mScale9Image.height - mBtn_to.height - 15 + 2 : mScale9Image.y + (mScale9Image.height - mBtn_to.height + 25) * 0.5;
         mBtn_to.addEventListener("triggered",onTRIGGERED_to);
         txt_Integral = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97693,da.score + ""),20,1513239,"left",300,46);
         this.addChild(txt_Integral);
         txt_Integral.x = mBtn_to.x - txt_Integral.width + 150;
         txt_Integral.y = mBtn_to.y;
         var _loc3_:Boolean = false;
         if(_loc8_)
         {
            this.setAvatar(da["aid"]);
            mBox_UIs.addChild(this.mAvatar);
            _loc7_ = this.mAvatarData.avatarData.name;
            this.mAvatar.x = -100;
         }
         mName = _loc7_;
         _loc5_ = GlobalTextStyle.getTextField(_loc7_,20,1118481,"left",_loc2_,35);
         _loc5_.x = this.mScale9Image.x + 30;
         _loc5_.y = 18;
         mBox_UIs.addChild(_loc5_);
         this.addEventListener("touch",onTOUCH_ui);
      }
      
      private function onTOUCH_ui(param1:TouchEvent) : void
      {
         var _loc3_:List = this.parent.parent as List;
         if(_loc3_.isScrolling)
         {
            return;
         }
         var _loc2_:Touch = null;
         if(mAvatar)
         {
            _loc2_ = param1.getTouch(mAvatar,"ended");
            if(_loc2_)
            {
               GlobalFunction.setDetaiAvatar({"id":da.aid},true);
               return;
            }
         }
      }
      
      private function onTRIGGERED_to(param1:Event) : void
      {
         GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
         if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
         {
            GlobalFunction.popAvatarLen();
            return;
         }
         var _loc2_:uint = 0;
         if(GlobalData.$userData.attrs.activity_score)
         {
            _loc2_ = uint(GlobalData.$userData.attrs.activity_score);
         }
         if(_loc2_ >= da.score)
         {
            SendServiceAMFFun.send_user_exchange_activity_avatar(onRe,{
               "aid":da.aid,
               "score":da.score
            });
         }
         else
         {
            GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(97694));
         }
      }
      
      private function onRe(param1:Object) : void
      {
         if(stage == null)
         {
            return;
         }
         trace(param1);
         var _loc2_:Object = {};
         if(param1.data)
         {
            for(var _loc4_:Object in param1.data)
            {
               if(_loc4_ == "avatar")
               {
                  for(var _loc3_:Object in param1.data.avatar)
                  {
                     if(!GlobalFunction.isVersionedProfileReceipt(param1))
                     {
                        GlobalData.$userData.avatars[_loc3_.toString()] = param1.data["avatar"][_loc3_.toString()];
                     }
                     _loc2_ = GlobalFunction.getAwardByType("avatar",param1.data["avatar"]);
                     GlobalFunction.popAward("avatar",_loc2_.msg,param1.data["avatar"]);
                  }
               }
            }
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.activity_score = param1.data.score;
         }
         GlobalData.$mEventDispatcher.dispatchEventWith("update_activity_score");
      }
   }
}

