package com.meng52.game.ui.panel
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.equip.Equip;
   import com.meng52.game.ui.element.ItemEquipAlchemyStuffSelect;
   import com.meng52.game.ui.element.LOL_IconText;
   import com.meng52.game.ui.screen.PanelCenterMainAvatar;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.data.ListCollection;
   import feathers.layout.VerticalLayout;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;

   public class PanelEquipAlchemyStuffSelect extends PanelCenterMainAvatar
   {

      private const PANEL_TOP:int = 85;

      private const DEL_PANEL_HEIGHT:Number = 310;

      private var m_data:Object;

      private var alchemyList:Object;

      private var _re_spr:Sprite;

      private var m_spRule:Sprite;

      public function PanelEquipAlchemyStuffSelect(param1:*)
      {
         super();
         this.m_data = param1;
      }

      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(PanelEquipAlchemyStart.$inheritMode ? "选择传承素材" : GlobalLanguageStr.getStr(90695),GlobalData.$center_height - 310);
         initUI();
      }

      private function initUI() : void
      {
         alchemyList = GlobalData.$mConfig_simple.equip_alchemy;
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
         isReady = false;
         isOut = true;
         GlobalData.$mStarling.juggler.tween(this,0.4,{"onComplete":tweenComplete});
         this.delList();
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
            this.mList.height = mListH = GlobalData.$center_height_curr - 121 - 310 - _rulerH - 20;
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
         var _loc2_:String = null;
         var _loc9_:Object = null;
         var _loc11_:Object = null;
         var _loc5_:String = null;
         var _loc10_:Array = null;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc3_:Array = null;
         var _loc1_:Object = GlobalData.$userData.my_equips;
         var _loc4_:Array = [];
         var _loc8_:Boolean = false;
         for(_loc11_ in _loc1_)
         {
            _loc8_ = false;
            _loc2_ = _loc11_.toString();
            _loc9_ = _loc1_[_loc2_];
            _loc5_ = _loc9_["eid"];
            _loc8_ = GlobalFunction.checkEquipIsBook(_loc5_);
            _loc6_ = GlobalFunction.checkEquipHasUsed(_loc2_);
            if(!_loc8_ && _loc6_ == -1 && _loc2_ != m_data.id && (PanelEquipAlchemyStart.$inheritMode ? checkInheritStuff(_loc9_) : m_data["eid"] == _loc9_["eid"] && checkEquipStar(_loc5_) && checkEquipIsStuff(_loc9_)))
            {
               _loc7_ = 0;
               if(_loc9_.hasOwnProperty("alchemy"))
               {
                  _loc3_ = _loc9_["alchemy"];
                  _loc7_ = _loc3_[0] + _loc3_[1] * 3;
               }
               _loc10_ = _loc5_.split("_");
               _loc9_["id"] = _loc2_;
               _loc9_["type"] = 0;
               _loc9_["bookselect"] = 0;
               _loc9_["step"] = _loc7_;
               _loc9_["sort_1"] = _loc9_.lv;
               _loc9_["sort_3"] = _loc10_[2];
               _loc9_["sort_5"] = _loc10_[1];
               _loc9_["sort_2"] = _loc6_ > -1 ? _loc6_ : 2147483647;
               _loc9_["sort_4"] = _loc6_ > -1 ? 0 : 2147483647;
               _loc9_["tag"] = 0;
               _loc4_.push(_loc9_);
            }
         }
         mList.y = mListY;
         if(_loc4_.length > 0)
         {
            _loc4_.sortOn(["step","sort_1"],[16,16]);
            this.setListTimer(mList,_loc4_,ItemEquipAlchemyStuffSelect,false);
         }
         if(_loc4_.length <= 0)
         {
            setTempPanel();
         }
         else
         {
            delTempPanel();
         }
         _loc4_ = [];
         _loc1_ = [];
      }

      public function setTempPanel() : void
      {
         var _loc12_:String = null;
         _re_spr = new Sprite();
         this.addChild(_re_spr);
         var _loc1_:Object = GlobalFunction.get_HelpLink(GlobalLanguageStr.getLanguageStr(90702));
         m_spRule = _loc1_.ui;
         m_spRule.x = MainConfig.$isEA ? this.mImg9_baseBg.x + this.mImg9_baseBg.width - 165 : this.mImg9_baseBg.x + this.mImg9_baseBg.width - 120;
         m_spRule.y = this.mImg9_baseBg.y + 90;
         m_spRule.addEventListener("touch",onTRIGGERED_help);
         var _loc10_:TextField = GlobalFunction.createTextField(600,30,PanelEquipAlchemyStart.$inheritMode ? "没有可用的同部位闲置装备" : GlobalLanguageStr.getStr(90705),"",20,16777215);
         _loc10_.x = this.mImg9_baseBg.x + (this.mImg9_baseBg.width - _loc10_.width) * 0.5;
         _loc10_.y = this.mImg9_baseBg.y + this.mImg9_baseBg.height * 0.3;
         _re_spr.addChild(_loc10_);
         if(PanelEquipAlchemyStart.$inheritMode)
         {
            return;
         }
         var _loc13_:Object = Tools.clone(m_data);
         if(_loc13_.hasOwnProperty("alchemy"))
         {
            _loc13_["alchemy"][0] = 0;
         }
         if(_loc13_.hasOwnProperty("magic"))
         {
            _loc13_["magic"] = [0,0,0,0];
         }
         if(_loc13_.hasOwnProperty("symp"))
         {
            _loc13_["symp"] = -1;
         }
         var _loc2_:Equip = new Equip(_loc13_.id,_loc13_);
         var _loc7_:Sprite = _loc2_.getRes();
         _loc7_.x = this.mImg9_baseBg.x + (this.mImg9_baseBg.width - _loc7_.width) * 0.5;
         _loc7_.y = _loc10_.y + 70;
         _re_spr.addChild(_loc7_);
         var _loc8_:LOL_IconText = new LOL_IconText(GlobalLanguageStr.getStr(90706));
         _loc8_.bgWidth = 100;
         _loc8_.bgVisible = false;
         _loc8_.x = MainConfig.$isEA ? _loc7_.x - _loc8_.bgWidth - 52 : _loc7_.x - _loc8_.bgWidth - 20;
         _loc8_.y = _loc7_.y + (_loc7_.height - _loc8_.height) * 0.5;
         _re_spr.addChild(_loc8_);
         var _loc5_:int = -1;
         var _loc4_:int = 0;
         if(_loc13_.hasOwnProperty("alchemy") && _loc13_["alchemy"][1] != 0)
         {
            _loc5_ = 0;
            _loc4_ = int(_loc13_["alchemy"][1]);
         }
         var _loc11_:int = int((_loc13_.eid as String).split("_")[2]) + _loc4_;
         var _loc6_:Array = [];
         var _loc3_:int = int(GlobalData.$mConfig_simple.equip_alchemy.equip_al);
         switch(_loc11_ - _loc3_)
         {
            case 0:
               _loc6_ = [16777215,12075775,16764006,16764006];
               break;
            case 1:
               _loc6_ = [16777215,16764006,16764006,16764006];
               break;
            default:
               _loc6_ = [16777215,16777215,16777215,16777215];
         }
         if(_loc5_ == -1)
         {
            _loc12_ = _loc2_.equipData.name;
         }
         else
         {
            _loc12_ = _loc2_.equipData.name + "(" + GlobalLanguageStr.getLanguageStr(90703,_loc5_) + ")";
         }
         var _loc9_:TextFieldHtmlRenderer = GlobalTextStyle.getHtmlTextRenderer();
         _loc9_.text = Tools.formatLineX(_loc12_,_loc6_,10,20);
         _loc9_.x = _loc7_.x + 100;
         _loc9_.y = _loc8_.y;
         _re_spr.addChild(_loc9_);
         _re_spr.addChild(m_spRule);
      }

      private function onTRIGGERED_help(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(m_spRule);
         if(_loc2_)
         {
            if(_loc2_.phase == "ended")
            {
               GlobalFunction.popPanelHelp(MainConfig.SERVER_ADDRESS_ALCHEMT);
            }
         }
      }

      private function delTempPanel() : void
      {
         if(_re_spr)
         {
            StarlingTools.removeChildrenClear(_re_spr);
         }
      }

      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         super.onREMOVED_FROM_STAGE(param1);
      }

      // Inheritance material: same slot type, any template or star, not locked.
      private function checkInheritStuff(param1:Object) : Boolean
      {
         var _eid:String = param1.eid;
         return _eid != null && String(m_data.eid).slice(2,3) == _eid.slice(2,3) && !param1.lock;
      }

      private function checkEquipStar(param1:String) : Boolean
      {
         var _loc2_:Array = null;
         var _loc4_:int = 0;
         var _loc3_:Boolean = true;
         if(param1 != null)
         {
            _loc2_ = param1.split("_");
            _loc4_ = int(_loc2_[_loc2_.length - 1]);
            if(_loc4_ < alchemyList.equip_al)
            {
               _loc3_ = false;
            }
         }
         return _loc3_;
      }

      private function checkEquipIsStuff(param1:Object) : Boolean
      {
         var _loc5_:Array = null;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc3_:String = param1.eid;
         var _loc2_:int = 0;
         var _loc9_:Array = (m_data.eid as String).split("_");
         if(m_data.hasOwnProperty("alchemy"))
         {
            _loc2_ = int(m_data.alchemy[1]);
         }
         else
         {
            _loc2_ = 0;
         }
         var _loc4_:int = int(_loc9_[_loc9_.length - 1]) + _loc2_;
         var _loc6_:Boolean = false;
         if(_loc3_ != null)
         {
            _loc5_ = _loc3_.split("_");
            _loc7_ = int(_loc5_[_loc5_.length - 1]);
            _loc8_ = 0;
            if(param1.hasOwnProperty("alchemy"))
            {
               _loc8_ = int(param1.alchemy[1]);
            }
            else
            {
               _loc8_ = 0;
            }
            if(_loc9_[2] == _loc5_[2] && _loc2_ == _loc8_)
            {
               _loc6_ = true;
            }
         }
         return _loc6_;
      }
   }
}
