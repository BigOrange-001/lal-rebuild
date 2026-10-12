package com.meng52.game.ui.element
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.utils.StarlingTools;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.EnterFrameEvent;
   import starling.events.Event;
   import starling.text.TextField;
   import starling.utils.deg2rad;
   
   public class LOL_MagicButton extends Sprite
   {
      
      public static const TXT_COLOR:Array = [52326,39423,12075775,16763955];
      
      public static const TXT_STR:Array = [90193,90194,90195,90196];
      
      public static const TXT_SYMP:Array = [31021,31022,31023,31024];
      
      private var mMagic:Array;
      
      private var mIndex:int = 0;
      
      private var mTxt_attr:TextField;
      
      private var mTxt_max:TextField;
      
      private var mTxt_info:TextField;
      
      private var mTxt_num:TextField;
      
      private var mImg_icon:Image;
      
      private var mBtn:LOL_Scale9Button;
      
      private var mFun:Function;
      
      private var mClip_times:Number = 0;
      
      private var mClip_y:Number = 0;
      
      private var mUpdate:Boolean = false;
      
      private var mUpdateID:int = 0;
      
      public function LOL_MagicButton(param1:int, param2:Array, param3:Function = null, param4:Boolean = false, param5:int = 0)
      {
         super();
         mIndex = param1;
         mMagic = param2;
         mFun = param3;
         mUpdate = param4;
         mUpdateID = param5;
         init();
      }
      
      private function init() : void
      {
         var _loc3_:String = GlobalLanguageStr.getLanguageStr(98140 + mIndex);
         var _loc2_:Number = 140;
         mTxt_attr = GlobalTextStyle.getTextField(_loc3_ + "+" + mMagic[mIndex],20,TXT_COLOR[mIndex],"center",140,35);
         addChild(mTxt_attr);
         var _loc1_:int = int(GlobalData.$mConfig_simple.dust.max[mIndex]);
         mTxt_max = GlobalTextStyle.getTextField("(MAX" + _loc1_ + ")",20,16763955,"center",140,35);
         addChild(mTxt_max);
         mBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(TXT_STR[mIndex]),135,65,"UI_btn_normalFun_0000");
         if(MainConfig.$isEnglish)
         {
            mBtn.fontSize = 18;
         }
         mBtn.shadowFilter();
         mBtn.addEventListener("triggered",onTRIGGERED);
         addChild(mBtn);
         mImg_icon = GlobalFunction.createImage("UI_magic_money_000" + mIndex);
         mImg_icon.scaleX = mImg_icon.scaleY = 0.6;
         mTxt_num = GlobalTextStyle.getTextField(GlobalData.$mConfig_simple.dust.add_magic[0][mIndex] + "",20,TXT_COLOR[mIndex],"left",42,35);
         var _loc4_:LOL_MutilTextFieldIcon = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getLanguageStr(90493)," " + GlobalData.$mConfig_simple.dust.add_magic[0][mIndex],"UI_magic_money_000" + mIndex,TXT_COLOR[mIndex],TXT_COLOR[mIndex]);
         _loc4_.iconScale = 0.6;
         if(MainConfig.$isEA)
         {
            _loc4_.fontSize = 16;
         }
         addChild(_loc4_);
         mTxt_attr.x = mTxt_max.x = -_loc2_ * 0.5;
         mBtn.x = -mBtn.width * 0.5;
         mImg_icon.x = -mImg_icon.width;
         _loc4_.x = MainConfig.$isEA ? -mImg_icon.width - 48 : -mImg_icon.width - 30;
         _loc4_.y = mBtn.y + mBtn.height - 10 + 67;
         mTxt_max.y = 30;
         mBtn.y = mTxt_max.y + 35 - 10;
         mImg_icon.y = mBtn.y + mBtn.height - 10 + 12;
         mTxt_num.y = mImg_icon.y;
         addEventListener("removedFromStage",onREMOVED_FROM_STAGE);
         if(mUpdate && mUpdateID == mIndex)
         {
            startClip();
         }
      }
      
      public function startClip() : void
      {
         mClip_y = 0;
         mClip_times = 0;
         if(mTxt_attr)
         {
            addEventListener("enterFrame",onENTER_FRAME_clip);
         }
      }
      
      private function onENTER_FRAME_clip(param1:EnterFrameEvent) : void
      {
         if(mClip_y >= 360)
         {
            mClip_y = 0;
            mClip_times += 1;
         }
         mClip_y += 10;
         if(mTxt_attr)
         {
            mTxt_attr.y = -Math.abs(Math.sin(deg2rad(mClip_y))) * 10;
         }
         if(mClip_times > 2)
         {
            mTxt_attr.y = 0;
            removeEventListener("enterFrame",onENTER_FRAME_clip);
         }
      }
      
      private function onTRIGGERED(param1:Event) : void
      {
         if(mFun != null)
         {
            mFun(mIndex);
         }
      }
      
      private function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         removeEventListener("removedFromStage",onREMOVED_FROM_STAGE);
         StarlingTools.removeChildrenClear(this);
         mTxt_attr = null;
         mTxt_max = null;
         mTxt_info = null;
         mTxt_num = null;
         mImg_icon = null;
         mBtn = null;
         mMagic = null;
         mFun = null;
      }
   }
}

