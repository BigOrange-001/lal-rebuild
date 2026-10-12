package com.meng52.game.ui.screen
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.ui.panel.PanelEquipSelect;
   import com.meng52.game.ui.panel.PanelEquipSellSelect;
   import feathers.display.Scale3Image;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   
   public class PanelEquipBase extends PanelCenterMainAvatar
   {
      
      private var _bg1:Image;
      
      private var _bg2:Scale3Image;
      
      public var mBox_data:Sprite;
      
      public var mBox_team:Sprite;
      
      public var mBg_team:Image;
      
      public var mBg_data:Image;
      
      public var mArr_team:Array;
      
      public var mRuler_item:Number = 0;
      
      public var mBox_equip:Sprite;
      
      private var _panelRise:PanelEquipSelect;
      
      private var _panelWash:PanelEquipSelect;
      
      private var _panelBook:PanelEquipSelect;
      
      private var _panelMagic:PanelEquipSelect;
      
      private var _panelSell:PanelEquipSellSelect;
      
      private var _show_id:String;
      
      public function PanelEquipBase()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         this.setTabBar([{
            "label":GlobalLanguageStr.getLanguageStr(20259),
            "indexID":0
         },{
            "label":GlobalLanguageStr.getLanguageStr(20260),
            "indexID":1
         },{
            "label":GlobalLanguageStr.getLanguageStr(20406),
            "indexID":2
         },{
            "label":GlobalLanguageStr.getLanguageStr(98146),
            "indexID":3
         },{
            "label":GlobalLanguageStr.getLanguageStr(90191),
            "indexID":4
         }],tabBar_Change,tabBar_CREATION_COMPLETE);
         this.mTabBar.y = 17;
         this.mTabBar.selectedIndex = GlobalData.$tempEquipFunId;
         tabBar_Change(null);
         _bg1 = getImg_headBg(-50);
         addChildAt(_bg1,0);
         _bg2 = getImg3_info();
         _bg2.y = mTabBar.y + 55;
         _bg2.height = 80;
         addChildAt(_bg2,1);
         GlobalData.$mEventDispatcher.addEventListener("update_panel_equipbase_index",UPDATE_PANEL_EQUIPBASE_INDEX);
      }
      
      override public function tabBar_CREATION_COMPLETE(param1:*) : void
      {
         mTabBar.setChildStatus(1,GlobalFunction.checkGameFunIsOpenByType("equip_fun_wash") < 0,tabBar_changeHandler_false);
         mTabBar.setChildStatus(3,GlobalFunction.checkGameFunIsOpenByType("equip_fun_magic") < 0,tabBar_changeHandler_false);
      }
      
      override public function tabBar_changeHandler_false(param1:int) : void
      {
         var _loc2_:int = 0;
         if(mTabBar)
         {
            _loc2_ = 0;
            if(param1 == 1)
            {
               _show_id = GlobalData.$mConfig_simple.show_id[8];
               _loc2_ = GlobalFunction.checkGameFunIsOpenByType("equip_fun_wash");
               if(_loc2_ > 0)
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90129,_loc2_),false,_show_id);
               }
            }
            else if(param1 == 3)
            {
               _show_id = GlobalData.$mConfig_simple.show_id[8];
               _loc2_ = GlobalFunction.checkGameFunIsOpenByType("equip_fun_magic");
               if(_loc2_ > 0)
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90129,_loc2_),false,_show_id);
               }
            }
         }
      }
      
      private function UPDATE_PANEL_EQUIPBASE_INDEX(param1:Event) : void
      {
         if(mTabBar)
         {
            mTabBar.selectedIndex = GlobalData.$tempEquipFunId;
         }
      }
      
      private function tabBar_Change(param1:Event) : void
      {
         GlobalData.$tempEquipFunId = this.mTabBar.selectedIndex + 1;
         clearPanel();
         switch(mTabBar.selectedIndex)
         {
            case 0:
               _panelRise = new PanelEquipSelect();
               addChild(_panelRise);
               break;
            case 1:
               _panelWash = new PanelEquipSelect();
               addChild(_panelWash);
               break;
            case 2:
               _panelBook = new PanelEquipSelect();
               addChild(_panelBook);
               break;
            case 3:
               _panelMagic = new PanelEquipSelect();
               addChild(_panelMagic);
               break;
            case 4:
               _panelSell = new PanelEquipSellSelect();
               addChild(_panelSell);
         }
      }
      
      public function clearPanel() : void
      {
         if(_panelRise)
         {
            _panelRise.removeFromParent(true);
         }
         if(_panelWash)
         {
            _panelWash.removeFromParent(true);
         }
         if(_panelBook)
         {
            _panelBook.removeFromParent(true);
         }
         if(_panelMagic)
         {
            _panelMagic.removeFromParent(true);
         }
         if(_panelSell)
         {
            _panelSell.removeFromParent(true);
         }
         _panelRise = null;
         _panelWash = null;
         _panelBook = null;
         _panelMagic = null;
         _panelSell = null;
      }
   }
}

