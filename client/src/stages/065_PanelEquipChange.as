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
         var _loc4_:Array = [12075775,16764006,13777209];
         var _loc3_:int = int(GlobalData.$mConfig_simple.equip_alchemy.equip_al);
         var _loc2_:String = _equip.getStep() > -1 ? GlobalLanguageStr.getLanguageStr(90703,_equip.getStep().toString()) : "";
         setPopPanelBg(_equip.equipData.name,570,640,false,true,_loc2_,_loc4_[_equip.getStar() - _loc3_]);
         _detailEquip = new LOL_DetailEquip(_data,width,height);
         _detailEquip.x = 40;
         _detailEquip.y = 100;
         addChild(_detailEquip);
         init();
      }
      
      private function init() : void
      {
         var _loc1_:Boolean = GlobalFunction.checkEquipIsBook(_equip.equipData.id);
         if(_loc1_)
         {
            _book = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20406),140,70);
            _book.x = 150;
            _book.y = _height - _book.height - 40;
            addChild(_book);
            _reset = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(25025),140,70);
            _reset.x = width - _reset.width - 80;
            _reset.y = _book.y;
            addChild(_reset);
            _book.addEventListener("triggered",book_Triggered);
         }
         else
         {
            _rise = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20259),135,70);
            _rise.x = 35;
            _rise.y = _height - _rise.height - 40;
            addChild(_rise);
            _wash = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20260),135,70);
            _wash.enabled = GlobalFunction.checkGameFunIsOpenByType("equip_fun_wash") < 0;
            _wash.x = _rise.x + _rise.width + 10;
            _wash.y = _rise.y;
            addChild(_wash);
            _magic = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(98146),135,70);
            _magic.enabled = GlobalFunction.checkGameFunIsOpenByType("equip_fun_magic") < 0;
            _magic.x = _wash.x + _wash.width + 10;
            _magic.y = _rise.y;
            addChild(_magic);
            _reset = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(25025),135,70);
            _reset.x = _magic.x + _magic.width + 10;
            _reset.y = _rise.y;
            addChild(_reset);
            _rise.addEventListener("triggered",rise_Triggered);
            _wash.addEventListener("triggered",wash_Triggered);
            _magic.addEventListener("triggered",magic_Triggered);
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

