package com.meng52.game.ui.element
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import feathers.controls.List;
   import feathers.controls.renderers.IListItemRenderer;
   import flash.geom.Rectangle;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   
   public class ItemEquipRender extends ItemEquipSelect implements IListItemRenderer
   {
      public function ItemEquipRender()
      {
         super();
      }
      
      override public function layoutWH() : void
      {
         if(_bg)
         {
            this.width = _bg.width + 105;
            this.height = 105;
         }
         tweenX();
      }
      
      override public function init(param1:Object) : void
      {
         _bg = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",GlobalData.$mStageWidth - 148,95,new Rectangle(110,55,70,20));
         _bg.x = 110;
         _bg.y = 5;
         addChild(_bg);
         if(param1["bookselect"] != null && param1["bookselect"] == 1)
         {
            _bg.width = GlobalData.$mStageWidth - 165;
         }
         setEquip(param1["id"],param1,8,5);
         if(param1.type == 0)
         {
            var actionLabel:int = GlobalData.$tempEquipFunId == 2 ? 20260 : 20268;
            setFunBtnUI(GlobalLanguageStr.getLanguageStr(actionLabel));
         }
         else
         {
            setFunSelect();
         }
         setOtherUIs(GlobalData.$tempEquipFunId == 3);
         setUsedStatusUI();
         if(mEquipUI)
         {
            mEquipUI.addEventListener("touch",equip_Touch);
         }
      }
      
      override public function setOtherUIs(param1:Boolean = false) : void
      {
         super.setOtherUIs(param1);
         if(!mEquip)
         {
            return;
         }
         var nameText:String = mEquip.equipData.name;
         var levelText:String = GlobalLanguageStr.getLanguageStr(20079,param1 ? mEquip.slv : mEquip.lv);
         var stepText:String = mEquip.getStep() > -1 ? GlobalLanguageStr.getLanguageStr(90703,mEquip.getStep()) : "";
         for(var i:int = 0; i < numChildren; i++)
         {
            var field:TextField = getChildAt(i) as TextField;
            if(field == null)
            {
               continue;
            }
            if(field.text == nameText)
            {
               field.x = 130;
               field.y = 10;
               field.width = 278;
               field.height = 27;
               field.fontSize = 17;
               field.autoScale = true;
               field.hAlign = "left";
            }
            else if(field.text == stepText && stepText != "")
            {
               field.x = 410;
               field.y = 10;
               field.width = 72;
               field.height = 27;
               field.fontSize = 17;
               field.autoScale = true;
               field.hAlign = "left";
            }
            else if(field.text == levelText)
            {
               field.x = 486;
               field.y = 10;
               field.width = 88;
               field.height = 27;
               field.fontSize = 17;
               field.autoScale = true;
               field.hAlign = "left";
            }
         }
      }
      
      private function equip_Touch(param1:TouchEvent) : void
      {
         var list:List = this.parent.parent as List;
         if(list.isScrolling)
         {
            return;
         }
         var touch:Touch = param1.getTouch(mEquipUI,"ended");
         if(touch)
         {
            GlobalFunction.setDetaiEquip(_data);
         }
      }
      
      override public function onTRIGGERED_btns(param1:Event) : void
      {
         if(GlobalData.$tempEquipFunId == 1)
         {
            GlobalData.$tempEquipCurrSelected = _data["id"];
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_rise",false,true);
         }
         else if(GlobalData.$tempEquipFunId == 2)
         {
            if(GlobalData.$userData.attrs.equip_forge != null)
            {
               GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(10061));
            }
            GlobalData.$tempEquipCurrSelected = _data["id"];
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_wash",false,true);
         }
         else if(GlobalData.$tempEquipFunId == 3)
         {
            if(mEquip && mEquip.slv >= GlobalData.$mConfig_simple.skill_book_exp[3])
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90162));
               return;
            }
            GlobalFunction.clearBookFood();
            GlobalData.$tempEquipCurrSelected = _data["id"];
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_book",false,true);
         }
         else if(GlobalData.$tempEquipFunId == 4)
         {
            GlobalData.$tempEquipCurrSelected = _data["id"];
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_magic",false,true);
         }
      }
      
      override public function bg_Touch(param1:TouchEvent) : void
      {
         var touch:Touch = param1.getTouch(_bg,"ended");
         if(touch)
         {
            if(this.data.selected == 0)
            {
               if(GlobalData.$tempFoodForBook.length >= 5)
               {
                  return;
               }
               this.data.selected = 1;
               GlobalFunction.changeBookFoodArray(this.data.id,false,this);
            }
            else
            {
               this.data.selected = 0;
               GlobalFunction.changeBookFoodArray(this.data.id,true,this);
            }
            visibleSelect(data.selected);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_book_selected_data");
         }
      }
   }
}
