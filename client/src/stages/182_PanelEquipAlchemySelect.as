package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.module.equip.Equip;
   import com.meng52.game.ui.element.ItemEquipAlchemySelect;
   import com.meng52.game.ui.screen.PanelCenterMainAvatar;
   import feathers.controls.List;
   import feathers.data.ListCollection;
   import feathers.layout.VerticalLayout;
   import starling.events.Event;

   public class PanelEquipAlchemySelect extends PanelCenterMainAvatar
   {

      private const PANEL_TOP:int = 85;

      private var alchemyList:Object;

      public function PanelEquipAlchemySelect()
      {
         super();
      }

      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         GlobalData.$mEventDispatcher.addEventListener("update_alchemy_select",onUpdate);
         this.setPopPanelBg(PanelEquipAlchemyStart.$inheritMode ? "选择传承装备" : GlobalLanguageStr.getStr(90694),GlobalData.$center_height);
         initUI();
      }

      private function onUpdate(param1:Event) : void
      {
         update();
      }

      private function initUI() : void
      {
         alchemyList = GlobalData.$mConfig_simple.equip_alchemy;
         update();
      }

      override public function update() : void
      {
         setList();
         addList();
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
         this.delList();
         isReady = false;
         isOut = true;
         GlobalData.$mStarling.juggler.tween(this,0.4,{"onComplete":tweenComplete});
         if(this.mList == null)
         {
            _rulerH = 85;
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
            this.mList.height = mListH = GlobalData.$center_height_curr - 121 - _rulerH - 20;
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
         var _loc13_:Object = null;
         var _loc6_:Object = null;
         var _loc8_:String = null;
         var _loc14_:Array = null;
         var _loc11_:int = 0;
         var _loc5_:int = 0;
         var _loc3_:Array = null;
         var _loc4_:int = 0;
         var _loc1_:Object = GlobalData.$userData.my_equips;
         var _loc2_:Array = [];
         var _loc9_:int = 0;
         var _loc10_:String = GlobalFunction.checkEquipType(_loc9_);
         var _loc12_:Boolean = false;
         for(_loc6_ in _loc1_)
         {
            _loc12_ = false;
            _loc7_ = _loc6_.toString();
            _loc13_ = _loc1_[_loc7_];
            _loc8_ = _loc13_["eid"];
            _loc12_ = GlobalFunction.checkEquipIsBook(_loc8_);
            if(_loc9_ == 0 && !_loc12_ && checkEquipStar(_loc13_))
            {
               _loc14_ = _loc8_.split("_");
               _loc11_ = int(_loc14_[_loc14_.length - 1]);
               _loc5_ = 0;
               if(_loc13_.hasOwnProperty("alchemy"))
               {
                  _loc3_ = _loc13_["alchemy"];
                  _loc11_ += int(_loc3_[1]);
                  _loc5_ = int(_loc3_[0]);
                  _loc13_["isAlchemy"] = _loc5_ + int(_loc3_[1]) * 3;
               }
               else
               {
                  _loc13_["isAlchemy"] = 0;
               }
               _loc13_["id"] = _loc7_;
               _loc13_["type"] = 0;
               _loc13_["bookselect"] = 0;
               _loc13_["star"] = _loc11_;
               _loc13_["step"] = _loc5_;
               _loc13_["sort_1"] = _loc13_.lv;
               _loc13_["sort_3"] = _loc14_[2];
               _loc13_["sort_5"] = _loc14_[1];
               _loc4_ = GlobalFunction.checkEquipHasUsed(_loc7_);
               _loc13_["sort_2"] = _loc4_ > -1 ? _loc4_ : 2147483647;
               _loc13_["sort_4"] = _loc4_ > -1 ? 0 : 2147483647;
               _loc13_["tag"] = 0;
               _loc2_.push(_loc13_);
            }
         }
         mList.y = mListY;
         if(_loc2_.length > 0)
         {
            _loc2_.sortOn(["isAlchemy","sort_4","star","step","sort_1","sort_5"],[0x10 | 2,16,0x10 | 2,0x10 | 2,0x10 | 2,0x10 | 2]);
            this.setListTimer(mList,_loc2_,ItemEquipAlchemySelect,false);
         }
         if(_loc2_.length <= 0)
         {
            this.setTips(GlobalLanguageStr.getLanguageStr(20505));
            mTips.y = (GlobalData.$center_height - mTips.height) / 2 + 28;
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
         super.onREMOVED_FROM_STAGE(param1);
         GlobalData.$mEventDispatcher.removeEventListener("update_alchemy_select",onUpdate);
      }

      private function checkEquipStar(param1:Object) : Boolean
      {
         var _loc3_:Array = null;
         var _loc5_:int = 0;
         var _loc2_:String = param1["eid"];
         var _loc4_:Boolean = false;
         var _loc6_:int = 0;
         if(PanelEquipAlchemyStart.$inheritMode)
         {
            // Any star may receive affixes, up to the inheritance limit.
            return _loc2_ != null && (param1.inherit_count == undefined || int(param1.inherit_count) < Equip.MAX_INHERIT_COUNT);
         }
         if(param1.hasOwnProperty("alchemy"))
         {
            _loc6_ = int(param1["alchemy"][1]);
         }
         if(_loc2_ != null)
         {
            _loc3_ = _loc2_.split("_");
            _loc5_ = int(_loc3_[_loc3_.length - 1]) + _loc6_;
            if(_loc5_ >= alchemyList.equip_al && _loc5_ < alchemyList.star_lv)
            {
               _loc4_ = true;
            }
         }
         return _loc4_;
      }
   }
}
