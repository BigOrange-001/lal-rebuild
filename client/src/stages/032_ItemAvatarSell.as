package com.meng52.game.ui.element
{
   import com.meng52.game.ui.screen.PanelAvatarSell;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.ui.screen.PanelCenterDNTeam;
   import com.meng52.utils.StarlingTools;
   import feathers.controls.renderers.IListItemRenderer;
   import starling.events.Event;
   
   public class ItemAvatarSell extends ItemBase implements IListItemRenderer
   {
      
      public var isSelect:Boolean;
      
      public function ItemAvatarSell()
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
         this.setAvatar(this.data.id,3);
         this.addChild(this.mAvatar);
         this.setUISelect();
         if(GlobalData.$tempSell.indexOf(this.data.id) > -1)
         {
            this.data.status = -1;
         }
         else
         {
            this.data.status = 0;
         }
         this.checkLock();
         this.checkSelect();
      }
      
      override public function checkLock() : void
      {
         var _loc5_:Boolean = this.checkIsTeam() || PanelAvatarSell.isHeroAssigned(this.data.id) || this.data["material_protected"] == 1;
         var _loc4_:Boolean = GlobalFunction.checkLock(this.data.id);
         var _loc6_:Boolean = PanelCenterDNTeam.checkIsInDn(this.data.id) != null;
         var _loc3_:Boolean = false;
         var _loc1_:Avatar = new Avatar(data.id);
         if(_loc5_ || _loc4_ || _loc6_)
         {
            _loc3_ = true;
         }
         this.mTouchB = !_loc3_;
         var _loc2_:int = 0;
         if(_loc5_)
         {
            _loc2_ = 1;
         }
         else if(_loc6_)
         {
            _loc2_ = 5;
         }
         else
         {
            _loc2_ = 0;
         }
         this.visibleTeam(_loc2_);
         this.visibleMask(_loc3_);
         this.visibleLock(_loc4_);
      }
      
      override public function onTRIGGERED(param1:Event) : void
      {
         if(!this.mTouchB)
         {
            GlobalData.$tempLockItem = this.data;
            GlobalData.$tempLockItem["fun"] = checkLock;
            GlobalFunction.setDetaiAvatar(this.data);
            return;
         }
         this.checkSelectData();
      }
      
      public function checkSelectData() : void
      {
         if(this.data.status == 0)
         {
            if(GlobalData.$tempSell.length >= 10)
            {
               return;
            }
            this.data.status = -1;
            GlobalFunction.changeSellArray(this.data.id,false,this);
         }
         else
         {
            this.data.status = 0;
            GlobalFunction.changeSellArray(this.data.id,true,this);
         }
         this.checkSelect();
         GlobalData.$mEventDispatcher.dispatchEventWith("update_avatar_sell_data");
      }
      
      public function checkSelect() : void
      {
         if(data)
         {
            this.isSelect = this.data.status < 0;
            this.visibleSelect(this.isSelect);
         }
      }
      
      public function set reData(param1:Boolean) : void
      {
         if(!param1)
         {
            if(data)
            {
               data.status = 0;
               unflatten();
               checkSelect();
            }
         }
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         StarlingTools.removeChildrenClear(this);
         this.clear();
      }
   }
}

