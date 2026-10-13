package com.meng52.game.ui.element
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.ui.effect.DisplayTools;
   import flash.geom.Rectangle;
   import starling.animation.Tween;
   import starling.display.DisplayObject;
   import starling.display.Image;
   import starling.events.EnterFrameEvent;
   import starling.events.Event;
   
   public class ItemBetterElement extends ItemAvatarBetter
   {
      
      public static const ACTION_TIME:Number = 0.5;
      
      public var mIcon_null:Image;
      
      public var mClip_a:DisplayObject;
      
      public var mClip_a_status:int = 0;
      
      public var mClip_b_status:int = 0;
      
      private var mClip_rec:Rectangle;
      
      private var mClip_reFun:Function;
      
      private var mDelay_num:int;

      private var mUpgradeSpeed:int = 1;
      
      public function ItemBetterElement()
      {
         super();
         this.width = this.height = 90;
      }
      
      override public function layoutWH() : void
      {
         this.width = this.height = 90;
      }
      
      override public function init(param1:Object) : void
      {
         this.removeEventListener("triggered",this.onTRIGGERED);
         this.mBg = GlobalFunction.createImage("UI_bg_card_2_0002");
         this.mIcon_null = GlobalFunction.createImage("UI_icon_0_0000");
         this.mIcon_null.x = int(this.mBg.x + (this.mBg.width - this.mIcon_null.width) * 0.5) + 2;
         this.mIcon_null.y = int(this.mBg.y + (this.mBg.height - this.mIcon_null.height) * 0.5) - 3;
         this.addChild(this.mBg);
         this.addChild(this.mIcon_null);
         if(this.data["id"] != null)
         {
            this.setAvatarUI();
            this.mIcon_null.visible = false;
         }
         this.mClip_a_status = 0;
         this.mClip_b_status = 0;
      }
      
      public function setAvatarUI() : void
      {
         this.setAvatar(this.data.id,3);
         this.addChild(this.mAvatar);
         this.data["give"] = getBettrGiveOther();
         GlobalData.$tempBetterElements[this.data.id] = this.data;
      }
      
      public function setClipFun(param1:Rectangle, param2:Function, param3:int, param4:int = 1) : void
      {
         this.mClip_rec = param1;
         this.mClip_reFun = param2;
         this.setJuggle();
         mDelay_num = param3;
         mUpgradeSpeed = Math.max(1,param4);
      }
      
      override public function onEnterFrame(param1:EnterFrameEvent) : void
      {
         var step:int = 0;
         while(step < mUpgradeSpeed && stage != null)
         {
            advanceUpgradeFrame(param1);
            step++;
         }
      }

      private function advanceUpgradeFrame(param1:EnterFrameEvent) : void
      {
         var _loc2_:Tween = null;
         var _loc3_:* = undefined;
         if(this.mJuggler)
         {
            if(mDelay_num > 0)
            {
               mDelay_num = mDelay_num - 1;
               return;
            }
            this.mJuggler.advanceTime(param1.passedTime);
            if(this.mAvatar)
            {
               if(this.mAvatar.alpha > 0)
               {
                  this.mAvatar.alpha -= 0.2;
               }
               else if(mClip_a_status == 0 && mClip_b_status == 0)
               {
                  mClip_a_status = 2;
                  mClip_b_status = 2;
                  this.mAvatar.alpha = 0;
                  _loc3_ = _loc3_ = {
                     "id":"e506",
                     "x":55,
                     "y":75,
                     "sc":0.2,
                     "rate":mUpgradeSpeed
                  };
                  _loc3_.par = this;
                  mClip_a = DisplayTools.addEffectOne(_loc3_);
                  _loc2_ = new Tween(mClip_a,0.5 * 0.1,"easeOut");
                  _loc2_.scaleTo(2);
                  mJuggler.add(_loc2_);
               }
            }
            if(this.mClip_b_status == 2 && this.mClip_a_status == 2)
            {
               this.mClip_a_status = 3;
               this.mClip_b_status = 3;
               _loc2_ = new Tween(this.mClip_a,0.5);
               _loc2_.animate("x",this.mClip_rec.x + 90 * 0.5);
               _loc2_.onComplete = onCompleteFun;
               this.mJuggler.add(_loc2_);
               _loc2_ = new Tween(this.mClip_a,0.5 / 2,"easeOut");
               _loc2_.animate("y",this.mClip_rec.y - 20);
               this.mJuggler.add(_loc2_);
               _loc2_ = new Tween(this.mClip_a,0.5 / 2,"easeIn");
               _loc2_.delay = 0.5 / 2;
               _loc2_.animate("y",this.mClip_rec.y + 90 * 0.5);
               this.mJuggler.add(_loc2_);
               _loc2_ = new Tween(this.mClip_a,0.5 * 0.1,"easeOut");
               _loc2_.delay = 0.5 * 0.9;
               _loc2_.scaleTo(0.2);
               this.mJuggler.add(_loc2_);
            }
         }
      }
      
      private function onCompleteFun() : void
      {
         this.mClip_a.removeFromParent(true);
         this.mClip_reFun();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(this.mJuggler)
         {
            this.mJuggler.purge();
         }
         if(mClip_a)
         {
            mClip_a.removeFromParent(true);
         }
         this.clear();
         mClip_a = null;
         mJuggler = null;
      }
   }
}

