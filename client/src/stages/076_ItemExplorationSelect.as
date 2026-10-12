package com.meng52.game.ui.element
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.ui.panel.PanelActivityExplorationSelect;
   import com.meng52.game.ui.screen.PanelCenterDNTeam;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.utils.StarlingTools;
   import feathers.controls.renderers.IListItemRenderer;
   import starling.display.Image;
   import starling.events.Event;
   
   public class ItemExplorationSelect extends ItemBase implements IListItemRenderer
   {
      
      private const W_H_MAX:Number = 104;
      
      private var mUI_select:Image;
      
      private const cfg:Object = GlobalData.$mConfig_simple.explore;
      
      private const NUM:String = "num";
      
      private const POWER:String = "power";
      
      public function ItemExplorationSelect()
      {
         super();
      }
      
      override public function layoutWH() : void
      {
         this.width = 104 - 10;
         this.height = 104 + 10;
      }
      
      override public function init(param1:Object) : void
      {
         this.setAvatar(this.data.id,3,null,false,true);
         this.addChild(this.mAvatar);
         this.data["status"];
         var _loc3_:int = 0;
         this.visibleTeam(0);
         var _loc2_:Array = (GlobalData.$userData.team[0] as Array).concat();
         var _loc4_:Number = _loc2_.indexOf(this.data.id);
         if(_loc4_ > -1)
         {
            _loc3_ = 1;
         }
         else if(PanelCenterDNTeam.checkIsInDn(this.data.id) != null)
         {
            _loc3_ = 5;
         }
         else
         {
            _loc3_ = 0;
         }
         this.mUI_select = GlobalFunction.createImage("UI_tag_2_0000");
         this.mUI_select.touchable = false;
         this.mUI_select.x = GlobalData.$iconRec90.width - this.mUI_select.width + 5;
         this.mUI_select.y = GlobalData.$iconRec90.height - this.mUI_select.height + 10;
         this.mUI_select.visible = this.data["status"];
         this.addChild(this.mUI_select);
      }
      
      override public function onTRIGGERED(param1:Event) : void
      {
         var _loc2_:Object = null;
         if(this.data["choice"])
         {
            _loc2_ = checkIsLegal();
            if(this.data["status"])
            {
               changeStatus();
            }
            else if(_loc2_["num"])
            {
               changeStatus();
            }
            else
            {
               if(!_loc2_["num"])
               {
                  LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getStr(90551));
                  return;
               }
            }
         }
      }
      
      private function changeStatus() : void
      {
         this.data["status"] = !this.data["status"];
         this.mUI_select.visible = this.data["status"];
         GlobalData.$mEventDispatcher.dispatchEventWith("update_exploration_select_avatar",false,{
            "data":this.data,
            "isSelect":this.data["status"]
         });
      }
      
      private function checkIsLegal() : Object
      {
         var _loc2_:Object = {};
         var _loc3_:int = PanelActivityExplorationSelect._selectNum + 1;
         _loc2_["num"] = _loc3_ <= cfg.army_max;
         return _loc2_;
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         StarlingTools.removeChildrenClear(this);
         this.clear();
      }
   }
}

