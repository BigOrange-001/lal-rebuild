package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.module.equip.Equip;
   import com.meng52.game.ui.element.LOL_DetailEquip;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelCenterMainAvatar;
   import starling.events.Event;
   
   public class PanelEquipChange extends PanelCenterMainAvatar
   {
      
      private var _detailEquip:LOL_DetailEquip;
      
      private var _rise:LOL_Scale9Button;
      
      private var _wash:LOL_Scale9Button;
      
      private var _book:LOL_Scale9Button;
      
      private var _magic:LOL_Scale9Button;
      
      private var _reset:LOL_Scale9Button;
      
      private var _equip:Equip;
      
      private var _data:Object;
      
      private var width:Number = 585;
      
      private var height:Number = 530;
      
      public function PanelEquipChange(param1:*)
      {
         super();
         _data = param1;
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         _equip = new Equip(_data.id,_data);
         var _loc2_:String = _equip.getStep() > -1 ? GlobalLanguageStr.getLanguageStr(90703,_equip.getStep().toString()) : "";
         setPopPanelBg(_equip.equipData.name,570,640,false,true,_loc2_,_equip.getAlchemyColor104());
         _detailEquip = new LOL_DetailEquip(_data,width,height);
         // The lock joins the native button row below instead of floating over it.
         _detailEquip.externalLock104 = true;
         _detailEquip.x = (mImg9_baseBg ? mImg9_baseBg.x : 0) + 40;
         _detailEquip.y = 100;
         addChild(_detailEquip);
         init();
      }
      
      private function init() : void
      {
         var _loc1_:Boolean = GlobalFunction.checkEquipIsBook(_equip.equipData.id);
         // One native row: book/reset or rise/wash/magic/reset, plus the inventory
         // lock for owned equipment. Width shrinks so five buttons still fit
         // inside the 640px frame with 30px margins and 10px gaps.
         var gap:int = 10;
         var count:int = (_loc1_ ? 2 : 4) + (_detailEquip.canLock104() ? 1 : 0);
         var w:int = Math.min(_loc1_ ? 140 : 135,int((_width - 60 - gap * (count - 1)) / count));
         var row:Array = [];
         if(_loc1_)
         {
            _book = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20406),w,70);
            row.push(_book);
            _reset = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(25025),w,70);
            row.push(_reset);
            _book.addEventListener("triggered",book_Triggered);
         }
         else
         {
            _rise = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20259),w,70);
            row.push(_rise);
            _wash = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20260),w,70);
            _wash.enabled = GlobalFunction.checkGameFunIsOpenByType("equip_fun_wash") < 0;
            row.push(_wash);
            _magic = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(98146),w,70);
            _magic.enabled = GlobalFunction.checkGameFunIsOpenByType("equip_fun_magic") < 0;
            row.push(_magic);
            _reset = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(25025),w,70);
            row.push(_reset);
            _rise.addEventListener("triggered",rise_Triggered);
            _wash.addEventListener("triggered",wash_Triggered);
            _magic.addEventListener("triggered",magic_Triggered);
         }
         var lock:LOL_Scale9Button = _detailEquip.createLockButton104(w,70);
         if(lock)
         {
            lock.fontSize = 25; // match the native row's default label size
            row.push(lock);
         }
         // Widths above already fit, so uiRow only places (never shrinks) the row.
         var left:Number = (mImg9_baseBg ? mImg9_baseBg.x : 0) + 30;
         GlobalFunction.uiRow(row,left,left + _width - 60,_height - 70 - 40,gap,"center");
         for each(var button:LOL_Scale9Button in row)
         {
            addChild(button);
         }
         _reset.addEventListener("triggered",reset_Triggered);
      }
      
      private function rise_Triggered(param1:Event) : void
      {
         super.onCLOSE_PANEL_SELF();
         GlobalData.$tempEquipCurrSelected = _data["id"];
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_rise",false,true);
      }
      
      private function wash_Triggered(param1:Event) : void
      {
         var _loc2_:int = GlobalFunction.checkGameFunIsOpenByType("equip_fun_wash");
         if(_loc2_ > 0)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90129,_loc2_),false,"A_1073_4");
            return;
         }
         super.onCLOSE_PANEL_SELF();
         if(GlobalData.$userData.attrs.equip_forge != null)
         {
            GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(10061));
         }
         GlobalData.$tempEquipCurrSelected = _data["id"];
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_wash",false,true);
      }
      
      private function magic_Triggered(param1:Event) : void
      {
         var _loc2_:int = GlobalFunction.checkGameFunIsOpenByType("equip_fun_magic");
         if(_loc2_ > 0)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90129,_loc2_),false,"A_1093_5");
            return;
         }
         super.onCLOSE_PANEL_SELF();
         GlobalData.$tempEquipCurrSelected = _data["id"];
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_magic",false,true);
      }
      
      private function book_Triggered(param1:Event) : void
      {
         super.onCLOSE_PANEL_SELF();
         if(_equip)
         {
            if(_equip.slv >= GlobalData.$mConfig_simple.skill_book_exp[3])
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90162));
               return;
            }
         }
         GlobalFunction.clearBookFood();
         GlobalData.$tempEquipFunId = 3;
         GlobalData.$tempEquipCurrSelected = _data["id"];
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_book",false,true);
      }
      
      private function reset_Triggered(param1:Event) : void
      {
         super.onCLOSE_PANEL_SELF();
         GlobalData.$tempEquipChangeIndex = _data["indexID_s"];
         GlobalData.$tempEquipChangeId = _data["id"];
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_change_select",false,true);
      }
   }
}

