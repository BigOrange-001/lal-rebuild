package com.meng52.game.ui.element
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.ui.panel.PanelInfoVIP;
   import feathers.controls.renderers.IListItemRenderer;
   import starling.display.Image;
   import starling.events.Event;
   import starling.filters.ColorMatrixFilter;
   import starling.filters.FragmentFilter;
   import starling.text.TextField;
   
   public class ItemVIP extends ItemBase implements IListItemRenderer
   {
      
      public var mTag_vip:Image;
      
      public var mBg_txt:TextField;
      
      private var mTxt_vip:TextField;
      
      private var mBtn_info:LOL_Scale9Button;
      
      private var mFilter:FragmentFilter;
      
      private var myshelfTxt_vip:TextField;
      
      public function ItemVIP()
      {
         super();
      }
      
      override public function layoutWH() : void
      {
         if(this.mBg)
         {
            this.width = this.mBg.width;
            this.height = 90;
         }
         tweenX(false,false);
      }
      
      override public function init(param1:Object) : void
      {
         this.mBg = GlobalFunction.createImage("UI_bg_vip_0_0000");
         this.mBg.touchable = false;
         this.mBg.filter = GlobalFunction.getVipLv() > 0 ? null : new ColorMatrixFilter(Vector.<Number>([0.3086,0.6094,0.082,0,0,0.3086,0.6094,0.082,0,0,0.3086,0.6094,0.082,0,0,0,0,0,1,0]));
         this.addChild(this.mBg);
         this.setUI();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(mTxt_vip)
         {
            mTxt_vip.dispose();
         }
         if(mFilter)
         {
            mFilter.dispose();
         }
         if(mBtn_info)
         {
            mBtn_info.removeFromParent(true);
         }
         if(this.mBg)
         {
            if(this.mBg.filter)
            {
               this.mBg.filter.clearCache();
               this.mBg.filter.dispose();
               this.mBg.filter = null;
            }
            this.mBg.removeFromParent(true);
         }
         this.clear();
         mTxt_vip = null;
         mFilter = null;
         mTag_vip = null;
         mBg_txt = null;
         mBtn_info = null;
         this.mBg = null;
      }
      
      override public function setUI() : void
      {
         var _loc4_:Array = GlobalData.$mConfig_simple.vip_config as Array;
         var _loc5_:int = int(_loc4_[2]);
         var _loc2_:int = int(_loc4_[3]);
         var _loc1_:Object = GlobalData.$mConfig_vip;
         var _loc3_:int = int(this.data["id"]);
         this.mTag_vip = GlobalFunction.getVipImg(_loc3_,"1");
         this.mTag_vip.touchable = false;
         this.mTag_vip.scaleX = this.mTag_vip.scaleY = 1;
         this.mTag_vip.x = 80;
         this.mTag_vip.y = 50 + 3;
         this.addChild(this.mTag_vip);
         if(_loc3_ <= _loc5_)
         {
            mBtn_info = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(98132),126,48,"UI_btn_enterGame_0_0000");
            this.mBtn_info.x = this.mBg.width - this.mBtn_info.width - 30 - 2;
            this.mBtn_info.y = 30 + 2;
            this.mBtn_info.addEventListener("triggered",this.onTRIGGERED_btn);
            this.addChild(this.mBtn_info);
         }
         if(_loc3_ == GlobalFunction.getVipLv())
         {
            this.mBg_txt = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90420),MainConfig.$isEnglish ? 15 : 20,13056,"left",this.mBg.width,29);
            this.mBg_txt.touchable = false;
            this.mBg_txt.x = 65 + this.mTag_vip.width;
            this.mBg_txt.y = 28;
            this.addChild(this.mBg_txt);
            myshelfTxt_vip = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90458,GlobalFunction.getAllVipExp()),MainConfig.$isEnglish ? 15 : 20,10027008,"left",this.mBg.width,29);
            myshelfTxt_vip.x = this.mBg_txt.x;
            myshelfTxt_vip.y = this.mBg_txt.y + 20;
            addChild(myshelfTxt_vip);
            mTxt_vip = GlobalTextStyle.getTextField("",20,16711680,"left",this.mBg.width,29);
            mTxt_vip.y = this.mBg_txt.y + this.mBg_txt.height - 2;
         }
         else
         {
            if(_loc3_ <= _loc5_)
            {
               mTxt_vip = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20506,GlobalFunction.getVipEXP(_loc3_)),MainConfig.$isEnglish ? 15 : 20,10027008,"left",this.mBg.width,29);
            }
            else
            {
               mTxt_vip = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90046),20,1118481,"left",this.mBg.width,29);
            }
            mTxt_vip.y = this.mTag_vip.y - 15;
         }
         mTxt_vip.x = this.mTag_vip.x + this.mTag_vip.width - 12;
         mTxt_vip.touchable = false;
         this.addChild(this.mTxt_vip);
      }
      
      private function onTRIGGERED_btn(param1:Event) : void
      {
         PanelInfoVIP._data = this.data["id"];
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_shop_vip_info",false,true);
      }
   }
}


