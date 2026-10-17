package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.ui.element.ItemInteGralExchange;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.game.ui.element.LOL_TimeStatus;
   import com.meng52.game.ui.screen.PanelCenterMainAvatar;
   import com.meng52.net.SendAndSelect;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.data.ListCollection;
   import feathers.layout.TiledRowsLayout;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class PanelInteGralExchange extends PanelCenterMainAvatar
   {
      
      private var _sp:Sprite;
      
      private var _itemArr:Array;
      
      private var mTimerT:LOL_TimeStatus;
      
      private var _cfg:Object;
      
      private var endTime:Number;
      
      private var now:Number;
      
      private var txt_Integral:TextField;
      
      private var _txt_coin:LOL_MutilTextFieldIcon;
      
      private var txt_Hint:TextField;
      
      public function PanelInteGralExchange()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg("积分兑换",GlobalData.$center_height_curr - 121);
         var _loc2_:Object = getVipTime();
         mTimerT = new LOL_TimeStatus("paneltimeextraction");
         if(_loc2_.can)
         {
            mTimerT.refresh(_loc2_.endTime / 1000,GlobalLanguageStr.getLanguageStr(97059,_loc2_.endTime / 1000),GlobalLanguageStr.getLanguageStr(97060),isOver);
         }
         else
         {
            mTimerT.refresh(0,GlobalLanguageStr.getLanguageStr(97074,Tools.timeFormatAll(0)),GlobalLanguageStr.getLanguageStr(97074));
         }
         mTimerT.x = 40;
         mTimerT.y = 95;
         addChild(mTimerT);
         mTimerT.visible = false;
         GlobalData.$mEventDispatcher.addEventListener("updata_vip_choujiang_fush",onFush);
         update();
      }
      
      private function getVipTime() : Object
      {
         var _loc6_:Object = GlobalData.$mConfig_ploy_system_simple.extract_avatar;
         var _loc3_:Number = (_loc6_.start_time as Date).time;
         var _loc5_:Number = (_loc6_.end_time as Date).time;
         var _loc1_:Number = SendAndSelect.$systemTimer_nowSecond * 1000;
         var _loc2_:Date = new Date();
         _loc2_.setTime(_loc1_);
         var _loc4_:Object = {};
         if(_loc1_ > _loc3_ && _loc1_ < _loc5_)
         {
            _loc4_.can = true;
         }
         else
         {
            _loc4_.can = false;
         }
         _loc4_.endTime = _loc5_ - _loc1_;
         return _loc4_;
      }
      
      private function getDisplayLotteryScore() : Number
      {
         var state:Object = GlobalData.$userData.attrs.lottery_activity;
         return state && !isNaN(Number(state.score)) ? Number(state.score) : 0;
      }
      
      private function onFush(param1:Event) : void
      {
         if(!getVipTime().can)
         {
            
         }
         this.mPageNum.text = "积分余额：" + getDisplayLotteryScore();
         update();
      }
      
      private function isOver() : void
      {
         
         if(mPageNum)
         {
            this.mPageNum.text = "积分余额：" + getDisplayLotteryScore();
         }
         mTimerT.refresh(0,GlobalLanguageStr.getLanguageStr(97074,Tools.timeFormatAll(0)),GlobalLanguageStr.getLanguageStr(97074));
         update();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalData.$mEventDispatcher.removeEventListener("updata_vip_choujiang_fush",onFush);
         if(_txt_coin)
         {
            _txt_coin.removeFromParent(true);
            _txt_coin.dispose();
         }
         if(txt_Hint)
         {
            txt_Hint.removeFromParent(true);
            txt_Hint.dispose();
         }
         this.delList();
         _txt_coin = null;
         txt_Hint = null;
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_shopAndVIP");
      }
      
      override public function update() : void
      {
         this.setList_Shop();
         this.addList();
      }
      
      public function setList_Shop() : void
      {
         var _rulerH:Number;
         var _layout:TiledRowsLayout;
         var tweenComplete:* = function():void
         {
            isReady = true;
         };
         isReady = false;
         GlobalData.$mStarling.juggler.tween(this,0.4,{"onComplete":tweenComplete});
         this.delList();
         if(this.mList == null)
         {
            _rulerH = 335;
            _layout = new TiledRowsLayout();
            _layout.paddingTop = 0;
            _layout.paddingRight = 10;
            _layout.paddingBottom = 0;
            _layout.paddingLeft = 0;
            _layout.horizontalAlign = "center";
            _layout.verticalAlign = "top";
            _layout.gap = 5;
            _layout.useSquareTiles = false;
            this.mList = new List();
            this.mList.isSelectable = false;
            this.mList.width = GlobalData.$mStageWidth - 20;
            this.mList.height = mListH = GlobalData.$center_height - 190;
            this.mList.layout = _layout;
            this.mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
            this.mList.x = 15;
            this.mList.y = mListY = _rulerH - 205;
            this.mList.snapScrollPositionsToPixels = true;
            this.addChild(this.mList);
            _layout = null;
            this.mList.dataProvider = new ListCollection();
         }
      }
      
      override public function addList() : void
      {
         var _loc5_:* = 0;
         var _loc3_:Object = null;
         var _loc2_:Array = GlobalData.$mConfig.ploy_system_simple.extract_avatar.exchange;
         _itemArr = [];
         _loc5_ = 0;
         while(_loc5_ < _loc2_.length)
         {
            _loc3_ = {};
            _loc3_.data = _loc2_[_loc5_][0];
            for(var _loc1_:String in _loc2_[_loc5_][0])
            {
               _loc3_.gift_type = _loc1_;
               for(var _loc4_:String in _loc2_[_loc5_][0][_loc1_])
               {
                  _loc3_.aid = _loc4_;
               }
            }
            _loc3_.needNum = _loc2_[_loc5_][1];
            _loc3_.index = _loc5_;
            _itemArr.push(_loc3_);
            _loc5_++;
         }
         this.setListTimer(mList,_itemArr,ItemInteGralExchange,true);
         this.mPageNum.x += 20;
         this.mPageNum.y -= 25;
         this.mPageNum.bgWidth = 580;
         this.mPageNum.text = "积分余额：" + getDisplayLotteryScore();
         _txt_coin = new LOL_MutilTextFieldIcon("","","UI_guildCredit_icon_0_0000");
         _txt_coin.iconScale = 0.65;
         _txt_coin.visible = false;
         this.addChild(_txt_coin);
         _txt_coin.y = this.mPageNum.y + _txt_coin.height / 4;
         _txt_coin.x = this.mPageNum.x + 100;
         txt_Hint = GlobalTextStyle.getTextField("100积分兑换40个橙色碎片",18,16764006,"right",380,35);
         txt_Hint.x = _txt_coin.x + 90;
         txt_Hint.y = _txt_coin.y - 15;
         addChild(txt_Hint);
      }
   }
}

