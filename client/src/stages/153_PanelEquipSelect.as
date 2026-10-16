package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.ui.element.ItemEquipRender;
   import com.meng52.game.ui.screen.PanelCenterMainAvatar;
   import com.meng52.game.ui.stage.GuideTools;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.data.ListCollection;
   import feathers.layout.VerticalLayout;
   import starling.events.Event;
   
   public class PanelEquipSelect extends PanelCenterMainAvatar
   {
      
      public function PanelEquipSelect()
      {
         super();
      }
      
      public function checkGuide() : void
      {
         LayoutUIAnimation.getOnlyExample().clearIfNoGuide();
         var _loc1_:String = GuideTools.checkGuideType();
         if(_loc1_ == "4")
         {
            if(GlobalData.$tempEquipFunId == 1)
            {
               if(mList.dataProvider.length > 0)
               {
                  LayoutUIAnimation.getOnlyExample().addArrowhead(563,342,0);
               }
            }
            else
            {
               LayoutUIAnimation.getOnlyExample().addArrowhead(60,154,0);
            }
         }
         else if(_loc1_ == "6")
         {
            if(GlobalData.$tempEquipFunId == 2)
            {
               if(mList.dataProvider.length > 0)
               {
                  LayoutUIAnimation.getOnlyExample().addArrowhead(565,340,0);
               }
            }
            else
            {
               LayoutUIAnimation.getOnlyExample().addArrowhead(175,154,0);
            }
         }
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         initOtherUIs();
         GlobalData.$mEventDispatcher.addEventListener("update_equip_list_data",UPDATE_EQUIP_LIST_DATA);
         GlobalData.$mEventDispatcher.addEventListener("update_book_list",UPDATE_BOOK_LIST);
      }
      
      private function radioBar_Complete(param1:Event) : void
      {
         if(GlobalData.$tempEquipFunId == 1)
         {
            this.mRadioBar.setChildStatus(1,true);
            this.mRadioBar.setChildStatus(2,true);
            this.mRadioBar.setChildStatus(3,true);
            this.mRadioBar.setChildStatus(4,true);
            this.mRadioBar.setChildStatus(5,false);
         }
         else if(GlobalData.$tempEquipFunId == 2)
         {
            this.mRadioBar.setChildStatus(1,true);
            this.mRadioBar.setChildStatus(2,true);
            this.mRadioBar.setChildStatus(3,true);
            this.mRadioBar.setChildStatus(4,true);
            this.mRadioBar.setChildStatus(5,false);
         }
         else if(GlobalData.$tempEquipFunId == 3)
         {
            this.mRadioBar.setChildStatus(1,false);
            this.mRadioBar.setChildStatus(2,false);
            this.mRadioBar.setChildStatus(3,false);
            this.mRadioBar.setChildStatus(4,false);
            this.mRadioBar.setChildStatus(5,true);
         }
         else if(GlobalData.$tempEquipFunId == 4)
         {
            this.mRadioBar.setChildStatus(1,true);
            this.mRadioBar.setChildStatus(2,true);
            this.mRadioBar.setChildStatus(3,true);
            this.mRadioBar.setChildStatus(4,true);
            this.mRadioBar.setChildStatus(5,false);
         }
         else if(GlobalData.$tempEquipFunId == 5)
         {
            this.mRadioBar.setChildStatus(1,false);
            this.mRadioBar.setChildStatus(2,false);
            this.mRadioBar.setChildStatus(3,false);
            this.mRadioBar.setChildStatus(4,false);
            this.mRadioBar.setChildStatus(5,false);
         }
      }
      
      private function UPDATE_EQUIP_LIST_DATA(param1:Event) : void
      {
         initOtherUIs();
      }
      
      private function tabBar_changeHandler(param1:Event) : void
      {
         initOtherUIs();
      }
      
      public function initOtherUIs() : void
      {
         var _loc1_:Array = null;
         if(!mRadioBar)
         {
            _loc1_ = [{"label":GlobalLanguageStr.getLanguageStr(20236)},{"label":GlobalLanguageStr.getLanguageStr(20263)},{"label":GlobalLanguageStr.getLanguageStr(20264)},{"label":GlobalLanguageStr.getLanguageStr(20265)},{"label":GlobalLanguageStr.getLanguageStr(20266)},{"label":GlobalLanguageStr.getLanguageStr(20267)}];
            this.setRadioBar(_loc1_,tabBar_changeHandler,radioBar_Complete);
            this.mRadioBar.selectedIndex = 0;
            mRadioBar.x = 15;
            mRadioBar.y = 83;
         }
         setList();
         addList();
         if(GlobalData.$mGameClassObject.mLayoutUICenter.checkPanelIsCurrentScreen())
         {
            checkGuide();
         }
      }
      
      private function UPDATE_BOOK_LIST(param1:Event) : void
      {
         initOtherUIs();
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
            _rulerH = 170;
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
            this.mList.width = GlobalData.$mStageWidth - 25;
            this.mList.height = mListH = GlobalData.$center_height_curr - 121 - _rulerH;
            this.mList.layout = _layout;
            this.mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
            this.mList.x = 6;
            this.mList.y = mListY = _rulerH;
            this.mList.snapScrollPositionsToPixels = true;
            this.addChild(this.mList);
            settings = null;
            _layout = null;
            this.mList.dataProvider = new ListCollection();
         }
      }
      
      override public function addList() : void
      {
         var _loc7_:String = null;
         var _loc12_:Object = null;
         var _loc5_:Object = null;
         var _loc8_:String = null;
         var _loc13_:Array = null;
         var _loc4_:int = 0;
         var _loc6_:int = 0;
         var _loc3_:int = 0;
         var _loc1_:Object = GlobalData.$userData.my_equips;
         var _loc2_:Array = [];
         var _loc9_:int = this.mRadioBar.selectedIndex;
         var _loc10_:String = GlobalFunction.checkEquipType(_loc9_);
         var _loc11_:Boolean = false;
         for(_loc5_ in _loc1_)
         {
            _loc11_ = false;
            _loc7_ = _loc5_.toString();
            _loc12_ = _loc1_[_loc7_];
            if(_loc12_ == null || !_loc12_.eid || GlobalData.$mConfig_equip[_loc12_.eid] == null) continue;
            // List metadata belongs to the renderer, not the saved equipment.
            _loc12_ = Tools.clone(_loc12_);
            _loc8_ = _loc12_["eid"];
            _loc11_ = GlobalFunction.checkEquipIsBook(_loc8_);
            if(_loc9_ == 0 && !_loc11_ && GlobalData.$tempEquipFunId == 1 || _loc9_ == 0 && !_loc11_ && GlobalData.$tempEquipFunId == 2 || _loc9_ == 0 && !_loc11_ && GlobalData.$tempEquipFunId == 4 || _loc8_.indexOf(_loc10_) > -1 && GlobalData.$tempEquipFunId != 3 || GlobalData.$tempEquipFunId != 3 && _loc8_.indexOf(_loc10_) > -1 || GlobalData.$tempEquipFunId == 3 && _loc11_)
            {
               _loc4_ = int(_loc12_.hasOwnProperty("alchemy") ? _loc12_["alchemy"][1] : 0);
               _loc6_ = int(_loc12_.hasOwnProperty("alchemy") ? _loc12_["alchemy"][0] : 0);
               _loc13_ = _loc8_.split("_");
               _loc12_["id"] = _loc7_;
               _loc12_["type"] = 0;
               _loc12_["bookselect"] = 0;
               _loc12_["sort_1"] = GlobalData.$tempEquipFunId == 3 ? (_loc12_.slv ? _loc12_.slv : 1) : _loc12_.lv;
               _loc12_["sort_3"] = int(_loc13_[2]) + _loc4_;
               _loc12_["step"] = _loc6_;
               _loc12_["name"] = int(_loc13_[1]);
               _loc3_ = GlobalFunction.checkEquipHasUsed(_loc7_);
               _loc12_["sort_2"] = _loc3_ > -1 ? _loc3_ : 2147483647;
               _loc12_["sort_4"] = _loc3_ > -1 ? 0 : 2147483647;
               _loc12_["tag"] = 0;
               _loc2_.push(_loc12_);
            }
         }
         mList.y = mListY;
         if(_loc2_.length > 0)
         {
            if(GlobalData.$tempEquipFunId == 1)
            {
               _loc2_.sortOn(["sort_4","sort_3","step","sort_1","name"],[16,0x10 | 2,0x10 | 2,0x10 | 2,0x10 | 2]);
            }
            else if(GlobalData.$tempEquipFunId == 2)
            {
               _loc2_.sortOn(["sort_4","sort_3","step","sort_1","name"],[16,0x10 | 2,0x10 | 2,0x10 | 2,0x10 | 2]);
            }
            else if(GlobalData.$tempEquipFunId == 3)
            {
               _loc2_.sortOn(["sort_4","sort_3","step","sort_1","name"],[16,0x10 | 2,0x10 | 2,0x10 | 2,0x10 | 2]);
            }
            else if(GlobalData.$tempEquipFunId == 4)
            {
               _loc2_.sortOn(["sort_4","sort_3","step","sort_1","name"],[16,0x10 | 2,0x10 | 2,0x10 | 2,0x10 | 2]);
            }
            else
            {
               _loc2_.sortOn(["sort_4","sort_1","sort_3"],[16,16,0x10 | 2]);
            }
            this.setListTimer(mList,_loc2_,ItemEquipRender,false);
         }
         if(_loc2_.length <= 0)
         {
            this.setTips(GlobalLanguageStr.getLanguageStr(20505));
         }
         else if(mTips)
         {
            this.delTips();
         }
         _loc2_ = [];
         _loc1_ = [];
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalData.$mEventDispatcher.removeEventListener("update_equip_list_data",UPDATE_EQUIP_LIST_DATA);
         GlobalData.$mEventDispatcher.removeEventListener("update_book_list",UPDATE_BOOK_LIST);
      }
   }
}

