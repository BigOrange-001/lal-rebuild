package com.meng52.game.ui.element
{
   import com.meng52.game.ui.screen.PanelAvatarSell;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.ui.screen.PanelCenterDNTeam;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.renderers.IListItemRenderer;
   import starling.events.Event;
   
   public class ItemBetterSelect extends ItemAvatarSell implements IListItemRenderer
   {

      private var mStackPicked:LOL_TextField;
      
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
         mStackPicked = null;
         if(this.data.stack_ids is Array)
         {
            initStack();
            return;
         }
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
      
      // MATERIAL STACKS 106: a stack card stands for stack_ids. Each picked copy
      // is registered under its own instance id, exactly like a single card,
      // so the feed request and its server checks are unchanged.
      private function initStack() : void
      {
         var _picked:int = stackPicked();
         this.data.status = _picked > 0 ? -1 : 0;
         this.checkLock();
         for each(var _copy:String in this.data.stack_ids)
         {
            if(GlobalData.$tempAvatarBetterArr.indexOf(_copy) > -1)
            {
               GlobalFunction.changeAvatarBetterArray(_copy,false,this,stackCopyData(_copy));
            }
         }
         this.checkSelect();
         showStackPicked(_picked);
      }

      private function stackPicked() : int
      {
         var _picked:int = 0;
         for each(var _copy:String in this.data.stack_ids)
         {
            if(GlobalData.$tempAvatarBetterArr.indexOf(_copy) > -1)
            {
               _picked++;
            }
         }
         return _picked;
      }

      private function stackCopyData(param1:String) : Object
      {
         var _copy:Object = Tools.clone(this.data);
         delete _copy.stack_ids;
         delete _copy.stack_count;
         _copy.id = param1;
         _copy.aid = param1;
         _copy.status = -1;
         return _copy;
      }

      private function showStackPicked(param1:int) : void
      {
         if(mStackPicked == null)
         {
            mStackPicked = new LOL_TextField("",86,30,false);
            mStackPicked.fontSize = 20;
            mStackPicked.fontColor = 11003770;
            mStackPicked.hAlign = "left";
            mStackPicked.shadowFilter();
            mStackPicked.touchable = false;
            mStackPicked.x = 6;
            mStackPicked.y = 4;
            addChild(mStackPicked);
         }
         mStackPicked.text = param1 > 0 ? "已选" + param1 : "";
         setChildIndex(mStackPicked,numChildren - 1);
      }

      // Tap adds the next unpicked copy while the five-material limit allows;
      // when nothing more can be added, the tap puts this stack's copies back.
      private function checkStackSelect() : void
      {
         var _next:String = null;
         for each(var _copy:String in this.data.stack_ids)
         {
            if(GlobalData.$tempAvatarBetterArr.indexOf(_copy) == -1)
            {
               _next = _copy;
               break;
            }
         }
         if(_next != null && GlobalData.$tempAvatarBetterArr.length < 5)
         {
            GlobalFunction.changeAvatarBetterArray(_next,false,this,stackCopyData(_next));
            GlobalData.$tempAvatarChoose.push(_next);
         }
         else
         {
            for each(_copy in this.data.stack_ids)
            {
               GlobalFunction.changeAvatarBetterArray(_copy,true,this,null);
            }
         }
         var _picked:int = stackPicked();
         this.data.status = _picked > 0 ? -1 : 0;
         this.checkSelect();
         showStackPicked(_picked);
         GlobalData.$mEventDispatcher.dispatchEventWith("update_avatar_better_data");
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
         if(this.data.stack_ids is Array)
         {
            checkStackSelect();
            return;
         }
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
               if(this.data.stack_ids is Array)
               {
                  showStackPicked(0);
               }
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

