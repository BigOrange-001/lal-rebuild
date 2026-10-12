package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.ui.element.ItemGuildDay;
   import com.meng52.game.ui.screen.PanelCenterPVE;
   import com.meng52.utils.StarlingTools;
   import feathers.controls.List;
   import feathers.data.ListCollection;
   import feathers.layout.VerticalLayout;
   import starling.events.Event;
   
   public class PanelGuildDay extends PanelCenterPVE
   {
      
      private var dayList:Array;
      
      private var _data:Object;
      
      public function PanelGuildDay(param1:Object)
      {
         _data = param1;
         super();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         dayList = null;
         StarlingTools.removeChildrenClear(this);
         this.clear();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(97728),GlobalData.$center_height,640,true);
         dayList = [];
         setUI();
      }
      
      private function setUI() : void
      {
         reFun(_data);
      }
      
      private function reFun(param1:Object) : void
      {
         dayList = param1.data.association_log;
         update();
      }
      
      override public function update() : void
      {
         this.setList();
         this.addList();
      }
      
      override public function setList() : void
      {
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
            settings = {
               "paging":0,
               "gap":5,
               "horizontalGap":20,
               "verticalGap":20,
               "paddingTop":0,
               "paddingRight":0,
               "paddingBottom":0,
               "paddingLeft":-7,
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
            _layout.gap = settings.gap;
            _layout.hasVariableItemDimensions = true;
            this.mList = new List();
            this.mList.isSelectable = false;
            this.mList.width = GlobalData.$mStageWidth - 20;
            this.mList.layout = _layout;
            this.mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
            this.mList.x = int((GlobalData.$mStageWidth - this.mList.width) * 0.5);
            this.mList.y = mImg9_baseBg.y + 100;
            this.mList.height = mListH = GlobalData.$center_height - 133;
            this.mList.snapScrollPositionsToPixels = true;
            this.addChild(this.mList);
            settings = null;
            _layout = null;
            this.mList.dataProvider = new ListCollection();
         }
      }
      
      override public function addList() : void
      {
         var _loc5_:Object = null;
         var _loc7_:int = 0;
         var _loc6_:Date = null;
         var _loc1_:VerticalLayout = null;
         var _loc4_:int = 0;
         var _loc2_:Object = null;
         var _loc3_:Array = [];
         _loc7_ = 0;
         while(_loc7_ < dayList.length)
         {
            _loc5_ = {};
            _loc6_ = new Date();
            // Convert the native UTC timestamp to Shanghai wall time for the local Date getters used by ItemGuildDay.
            _loc6_.setTime((dayList[_loc7_][0] as Date).time + GlobalConfig.HOURS_8_MS + 8 * 60 * 60 * 1000);
            _loc5_.time = _loc6_;
            _loc5_.text = dayList[_loc7_][1];
            _loc3_.push(_loc5_);
            _loc7_++;
         }
         if(dayList.length > 0)
         {
            delTips();
            _loc1_ = new VerticalLayout();
            _loc1_.paddingLeft = 30;
            _loc1_.gap = -70;
            _loc1_.paddingBottom = -70;
            mList.layout = _loc1_;
            _loc4_ = int(_loc3_.length);
            _loc3_.sortOn("time",0x10 | 2);
            _loc7_ = 0;
            while(_loc7_ < _loc4_)
            {
               if(_loc7_ == 0)
               {
                  _loc2_ = {};
                  _loc2_.time = _loc3_[0].time;
                  _loc3_.unshift(_loc2_);
                  _loc3_[0].sign = 1;
               }
               if((_loc3_[_loc7_].time as Date).date != (_loc3_[_loc7_ < _loc3_.length ? _loc7_ + 1 : _loc7_].time as Date).date)
               {
                  _loc2_ = {};
                  _loc2_.time = _loc3_[_loc7_ + 1].time;
                  _loc3_.splice(_loc7_ + 1,0,_loc2_);
                  _loc3_[_loc7_ + 1].sign = 1;
               }
               _loc7_++;
            }
            this.setListTimer(mList,_loc3_,ItemGuildDay,false);
         }
         else
         {
            this.setTips(GlobalLanguageStr.getLanguageStr(97816));
            mTips.y = (GlobalData.$center_height - mTips.height) / 2 + 10;
         }
      }
   }
}

