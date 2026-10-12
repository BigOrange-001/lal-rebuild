package com.meng52.game.ui.element
{
   import com.meng52.game.ui.screen.PanelAvatarSell;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.ui.screen.PanelCenterDNTeam;
   import com.meng52.utils.StarlingTools;
   import feathers.controls.renderers.IListItemRenderer;
   import starling.events.Event;
   
   public class ItemBetterSelect extends ItemAvatarSell implements IListItemRenderer
   {
      
      public function ItemBetterSelect()
      {
         super();
      }
      
      override public function layoutWH() : void
      {
         this.width = 104 - 5;
         this.height = 104;
      }
      
      override public function init(param1:Object) : void
      {
         this.setAvatar(this.data.id,3);
         this.data["give"] = getBettrGiveOther();
         this.addChild(this.mAvatar);
         var _loc2_:int = 0;
         if(PanelCenterDNTeam.checkIsInDn(this.data.id) != null)
         {
            _loc2_ = 5;
         }
         else
         {
            _loc2_ = this.checkIsTeam() ? 1 : 0;
         }
         visibleTeam(_loc2_);
         this.setUISelect();
         if(GlobalData.$tempAvatarBetterArr.indexOf(data["id"]) > -1)
         {
            this.data.status = -1;
         }
         else
         {
            this.data.status = 0;
         }
         this.checkLock();
         if(this.data.status != 0)
         {
            GlobalFunction.changeAvatarBetterArray(this.data.id,false,this,this.data);
         }
         this.checkSelect();
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
         GuideMaster.getOnlyExample().nextGuideStep();
      }
      
      override public function checkSelectData() : void
      {
         if(this.data.status == 0)
         {
            if(GlobalData.$tempAvatarBetterArr.length >= 5)
            {
               return;
            }
            this.data.status = -1;
            GlobalFunction.changeAvatarBetterArray(this.data.id,false,this,this.data);
            GlobalData.$tempAvatarChoose.push(this.data.id);
         }
         else
         {
            this.data.status = 0;
            GlobalFunction.changeAvatarBetterArray(this.data.id,true,this,this.data);
         }
         this.checkSelect();
         GlobalData.$mEventDispatcher.dispatchEventWith("update_avatar_better_data");
      }
      
      override public function checkLock() : void
      {
         var _loc5_:Boolean = false;
         var _loc4_:Boolean = GlobalData.$tempAvatarBetter.id == this.data.id;
         var _loc2_:Boolean = this.checkIsTeam();
         var _loc3_:Boolean = GlobalFunction.checkLock(this.data.id);
         var _loc1_:Boolean = PanelCenterDNTeam.checkIsInDn(this.data.id) != null;
         var _loc6_:Boolean = this.data["material_protected"] == 1 || PanelAvatarSell.isHeroAssigned(this.data.id);
         if(_loc4_ || _loc2_ || _loc3_ || _loc1_ || _loc6_)
         {
            _loc5_ = true;
         }
         this.mTouchB = !_loc5_;
         this.visibleMask(_loc5_);
         this.visibleLock(_loc3_);
      }
      
      override public function set reData(param1:Boolean) : void
      {
         if(!param1)
         {
            if(this.data)
            {
               this.data.status = 0;
               this.checkSelect();
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

