package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.ui.element.ItemActivityTime;
   import com.meng52.game.ui.element.LOL_IconText;
   import com.meng52.game.ui.screen.PanelCenterMainAvatar;
   import com.meng52.net.SendAndSelect;
   import feathers.controls.List;
   import feathers.data.ListCollection;
   import feathers.layout.VerticalLayout;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class PanelActivityTimedCharts extends PanelCenterMainAvatar
   {
      
      private var mTxt_medalNum:TextField;
      
      private var _txt_coin:LOL_IconText;
      
      private var _icon_bg:LOL_IconText;
      
      public function PanelActivityTimedCharts()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(97680),GlobalData.$center_height_curr - 121);
         this.addEventListener("close_panel_self",onCLOSE_PANEL_SELF);
         _txt_coin = new LOL_IconText(GlobalLanguageStr.getLanguageStr(97072,GlobalData.$userData.attrs.activity_score ? GlobalData.$userData.attrs.activity_score : "0"),6475106);
         _txt_coin.bgWidth = MainConfig.$isEA ? 470 : (MainConfig.$isEnglish ? 370 : 230);
         addChild(_txt_coin);
         _txt_coin.x = 30;
         _txt_coin.y = GlobalData.$center_height - _txt_coin.height - 20;
         var _loc2_:int = int(GlobalData.$mConfig_simple.medal_fun);
         GlobalData.$mEventDispatcher.addEventListener("update_activity_score",upDataGold);
         update();
      }
      
      private function upDataGold(param1:Event) : void
      {
         if(_txt_coin)
         {
            _txt_coin.text = GlobalLanguageStr.getLanguageStr(97072,GlobalData.$userData.attrs.activity_score ? GlobalData.$userData.attrs.activity_score : "0");
         }
      }
      
      public function tabBar_CREATION_COMPLETE1(param1:*) : void
      {
         mTabBar.y = 90;
         mTabBar.x = this.mImg9_baseBg.y + 40;
         update();
      }
      
      override public function onBTN_NAME_BACK() : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_casino");
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         this.removeEventListener("close_panel_self",onCLOSE_PANEL_SELF);
         GlobalData.$mEventDispatcher.removeEventListener("update_activity_score",upDataGold);
         GlobalData.$mStarling.juggler.removeTweens(this);
         if(mTxt_medalNum)
         {
            mTxt_medalNum.removeFromParent(true);
         }
         super.onREMOVED_FROM_STAGE(param1);
         mTxt_medalNum = null;
      }
      
      public function tabBar_changeHandler1(param1:Event) : void
      {
         if(mTabBar)
         {
            update();
         }
      }
      
      override public function setList() : void
      {
         var _rulerH:Number;
         var settings:Object;
         var _layout:VerticalLayout;
         var tweenComplete:* = function():void
         {
            isReady = true;
         };
         isReady = false;
         isOut = true;
         GlobalData.$mStarling.juggler.tween(this,0.4,{"onComplete":tweenComplete});
         this.delList();
         if(this.mList == null)
         {
            _rulerH = 200;
            settings = {
               "paging":0,
               "gap":0,
               "horizontalGap":20,
               "verticalGap":20,
               "paddingTop":0,
               "paddingRight":0,
               "paddingBottom":0,
               "paddingLeft":0,
               "horizontalAlign":"center",
               "verticalAlign":"top"
            };
            _layout = new VerticalLayout();
            _layout.paddingTop = settings.paddingTop;
            _layout.paddingRight = settings.paddingRight;
            _layout.paddingBottom = settings.paddingBottom;
            _layout.paddingLeft = settings.paddingLeft;
            _layout.horizontalAlign = settings.horizontalAlign;
            _layout.verticalAlign = settings.verticalAlign;
            _layout.hasVariableItemDimensions = true;
            this.mList = new List();
            this.mList.isSelectable = false;
            this.mList.width = GlobalData.$mStageWidth - 20;
            this.mList.height = mListH = GlobalData.$center_height_curr - _rulerH - 65;
            this.mList.layout = _layout;
            this.mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
            this.mList.x = int((GlobalData.$mStageWidth - this.mList.width) * 0.5);
            this.mList.y = mListY = _rulerH - 121;
            this.mList.snapScrollPositionsToPixels = true;
            this.addChild(this.mList);
            settings = null;
            _layout = null;
            this.mList.dataProvider = new ListCollection();
         }
      }
      
      override public function addList() : void
      {
         var _loc1_:Array = GlobalData.$mConfig.ploy_system_simple.timed_exchange;
         this.setListTimer(mList,_loc1_,ItemActivityTime,false);
      }
      
      private function checkAvatarExchange() : Object
      {
         var _loc1_:Object = GlobalData.$mConfig_exchange["avatar"];
         var _loc8_:Number = (_loc1_.start_time as Date).time * 0.001;
         var _loc7_:Number = 0;
         var _loc9_:Number = _loc1_.cycle_days * 24 * 60 * 60;
         var _loc3_:Number = SendAndSelect.$systemTimer_nowSecond;
         var _loc6_:Number = 0;
         var _loc5_:Number = 0;
         var _loc4_:int = int((_loc1_.cycle_exchange as Array).length);
         var _loc2_:Boolean = false;
         _loc7_ = Math.floor(_loc3_ - _loc8_);
         if(_loc7_ >= 0)
         {
            _loc2_ = true;
            _loc6_ = Math.floor(_loc7_ / _loc9_);
            _loc5_ = _loc6_ % _loc4_;
         }
         return {
            "id":_loc5_,
            "end":_loc7_,
            "start":_loc2_,
            "endDate":_loc8_ + (_loc6_ + 1) * _loc9_ - _loc3_
         };
      }
      
      private function checkEquipExchange() : Object
      {
         var _loc1_:Object = GlobalData.$mConfig_exchange["equip"];
         var _loc8_:Number = (_loc1_.start_time as Date).time * 0.001;
         var _loc7_:Number = (_loc1_.end_time as Date).time * 0.001;
         var _loc9_:Number = _loc1_.cycle_days * 24 * 60 * 60;
         var _loc3_:Number = SendAndSelect.$systemTimer_nowSecond;
         var _loc6_:Number = 0;
         var _loc5_:Number = 0;
         var _loc4_:int = int((_loc1_.exchange as Array).length);
         var _loc2_:Boolean = false;
         _loc7_ = Math.floor(_loc3_ - _loc8_);
         if(_loc7_ >= 0)
         {
            _loc2_ = true;
            _loc6_ = Math.floor(_loc7_ / _loc9_);
            _loc5_ = _loc6_ % _loc4_;
         }
         return {
            "id":_loc5_,
            "end":_loc7_,
            "start":_loc2_,
            "endDate":_loc8_ + (_loc6_ + 1) * _loc9_ - _loc3_
         };
      }
   }
}


