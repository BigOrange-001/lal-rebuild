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
         mMagic = param2 == null ? [0,0,0,0] : param2;
         mFun = param3;
         mUpdate = param4;
         mUpdateID = param5;
         init();
      }
      
      private function init() : void
      {
         var _loc1_:Object = GlobalData.$mConfig_simple.equipment_magic;
         var _loc2_:Array = _loc1_ == null ? null : _loc1_.stat_per_level as Array;
         var _loc3_:Array = _loc1_ == null ? null : _loc1_.names as Array;
         var _loc4_:int = Math.max(0,int(mMagic[mIndex]));
         var _loc5_:int = _loc2_ == null || mIndex >= _loc2_.length ? 1 : Math.max(0,int(_loc2_[mIndex]));
         var _loc6_:String = _loc3_ == null || mIndex >= _loc3_.length ? GlobalLanguageStr.getLanguageStr(98140 + mIndex) : String(_loc3_[mIndex]);
         var _loc7_:Array = GlobalData.$mConfig_simple.dust.max as Array;
         var _loc8_:int = _loc7_ == null || mIndex >= _loc7_.length ? 100 : int(_loc7_[mIndex]);
         var _loc9_:Boolean = mIndex > 0 && int(mMagic[mIndex - 1]) <= 0;
         var _loc10_:Boolean = _loc4_ >= _loc8_;
         var _loc11_:int = int(GlobalData.$mConfig_simple.dust.add_magic[0][mIndex]);
         var _loc12_:int = _loc1_ == null ? 0 : int(_loc1_.cost_growth_every);
         if(_loc12_ > 0)
         {
            _loc11_ += Math.floor(_loc4_ / _loc12_);
         }
         mTxt_attr = GlobalTextStyle.getTextField(_loc6_ + " Lv." + _loc4_ + "/" + _loc8_,14,TXT_COLOR[mIndex],"center",140,30);
         addChild(mTxt_attr);
         mTxt_info = GlobalTextStyle.getTextField("当前" + (mIndex % 2 == 0 ? "生命 +" : "攻击 +") + (_loc4_ * _loc5_),16,16777215,"center",140,30);
         mTxt_info.y = 28;
         addChild(mTxt_info);
         mTxt_max = GlobalTextStyle.getTextField("满级 +" + (_loc8_ * _loc5_),16,16763955,"center",140,30);
         mTxt_max.y = 55;
         addChild(mTxt_max);
         mBtn = new LOL_Scale9Button(_loc10_ ? "已满级" : _loc9_ ? "未解锁" : "附魔",135,65,"UI_btn_normalFun_0000");
         if(MainConfig.$isEnglish)
         {
            mBtn.fontSize = 18;
         }
         mBtn.shadowFilter();
         if(_loc9_ || _loc10_)
         {
            mBtn.touchable = false;
            mBtn.alpha = 0.5;
         }
         else
         {
            mBtn.addEventListener("triggered",onTRIGGERED);
         }
         addChild(mBtn);
         mBtn.x = -mBtn.width * 0.5;
         mBtn.y = 82;
         if(!_loc10_)
         {
            mImg_icon = GlobalFunction.createImage("UI_magic_money_000" + mIndex);
            mImg_icon.scaleX = mImg_icon.scaleY = 0.6;
            mImg_icon.x = -54;
            mImg_icon.y = 154;
            addChild(mImg_icon);
            mTxt_num = GlobalTextStyle.getTextField("粉尘 " + _loc11_,18,TXT_COLOR[mIndex],"left",105,30);
            mTxt_num.x = -20;
            mTxt_num.y = 156;
            addChild(mTxt_num);
         }
         mTxt_attr.x = mTxt_info.x = mTxt_max.x = -70;
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

