package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.ui.screen.PanelCenterMainAvatar;
   import feathers.display.Scale3Image;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   
   public class PanelAlchemy extends PanelCenterMainAvatar
   {
      
      private var _bg1:Image;
      
      private var _bg2:Scale3Image;
      
      private var _panelEquipAlchemy:PanelEquipAlchemy;
      
      private var _panelAvatarTalent:PanelAvatarTalent;
      
      private var _abyssReroll104:Sprite;
      
      public function PanelAlchemy()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         this.setTabBar([{
            "label":GlobalLanguageStr.getLanguageStr(98006),
            "indexID":0
         },{
            "label":GlobalLanguageStr.getLanguageStr(90691),
            "indexID":1
         },{
            "label":"深渊遗物",
            "indexID":2
         }],tabBar_Change,tabBar_CREATION_COMPLETE,130);
         this.mTabBar.y = 17;
         this.mTabBar.selectedIndex = GlobalData.$tempAlchemyIndex;
         tabBar_Change(null);
         _bg1 = getImg_headBg(-50);
         addChildAt(_bg1,1);
         _bg2 = getImg3_info();
         _bg2.y = mTabBar.y + 55;
         _bg2.height = 55;
         addChildAt(_bg2,2);
      }
      
      override public function tabBar_CREATION_COMPLETE(param1:*) : void
      {
         var _loc2_:int = GlobalFunction.checkGameFunIsOpenByType("equip_fun_panel_alchemy");
         if(GlobalData.$userData.lv < GlobalData.$mConfig_simple.start_lv[18])
         {
            mTabBar.setChildStatus(1,false,tabBar_changeHandler_false);
         }
      }
      
      override public function tabBar_changeHandler_false(param1:int) : void
      {
         var _loc3_:int = 0;
         var _loc2_:String = null;
         if(mTabBar)
         {
            if(param1 == 1)
            {
               _loc3_ = GlobalFunction.checkGameFunIsOpenByType("alchemy_");
               if(_loc3_ > -1)
               {
                  _loc2_ = GlobalData.$mConfig_simple.show_id[8];
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90129,_loc3_),false,_loc2_);
               }
            }
         }
      }
      
      private function UPDATE_PANEL_EQUIPBASE_INDEX(param1:Event) : void
      {
         if(mTabBar)
         {
            mTabBar.selectedIndex = GlobalData.$tempAlchemyIndex;
         }
      }
      
      private function tabBar_Change(param1:Event) : void
      {
         var _loc2_:String = null;
         var _loc3_:int = 0;
         GlobalData.$tempAlchemyIndex = this.mTabBar.selectedIndex;
         clearPanel();
         switch(mTabBar.selectedIndex)
         {
            case 0:
               _panelAvatarTalent = new PanelAvatarTalent();
               addChildAt(_panelAvatarTalent,0);
               break;
            case 1:
               if(GlobalData.$userData.lv < GlobalData.$mConfig_simple.start_lv[18])
               {
                  _loc2_ = GlobalData.$mConfig_simple.show_id[8];
                  _loc3_ = int(GlobalData.$mConfig_simple.start_lv[18]);
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90129,_loc3_),false,_loc2_);
                  break;
               }
               _panelEquipAlchemy = new PanelEquipAlchemy();
               addChildAt(_panelEquipAlchemy,0);
               break;
            case 2:
               // Abyss relic reroll (screens live with the Abyss Corridor UI).
               _abyssReroll104 = PanelActivityExploration.createRerollView104(GlobalData.$center_height_curr - 121 - 140);
               _abyssReroll104.y = mTabBar.y + 125;
               addChildAt(_abyssReroll104,0);
         }
      }
      
      public function clearPanel() : void
      {
         if(_panelEquipAlchemy)
         {
            _panelEquipAlchemy.removeFromParent(true);
         }
         if(_panelAvatarTalent)
         {
            _panelAvatarTalent.removeFromParent(true);
         }
         if(_abyssReroll104)
         {
            _abyssReroll104.removeFromParent(true);
         }
         _abyssReroll104 = null;
         _panelAvatarTalent = null;
         _panelEquipAlchemy = null;
      }
   }
}

