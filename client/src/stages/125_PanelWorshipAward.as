package com.meng52.game.ui.panel
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelCenterPVE;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import starling.events.Event;
   
   public class PanelWorshipAward extends PanelCenterPVE
   {
      
      private var data:Object;
      
      private var mText:TextFieldHtmlRenderer;
      
      private var remainingNum:TextFieldHtmlRenderer;
      
      private var totalNum:LOL_MutilTextFieldIcon;
      
      private var receiveBtn:LOL_Scale9Button;
      
      private var num:int;
      
      private var obj:Object;
      
      private var memberWorshipNum:int;
      
      public function PanelWorshipAward(param1:Object)
      {
         obj = param1;
         super();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(mText)
         {
            mText.removeFromParent(true);
            mText.dispose();
         }
         if(remainingNum)
         {
            remainingNum.removeFromParent(true);
            remainingNum.dispose();
         }
         if(totalNum)
         {
            totalNum.removeFromParent(true);
            totalNum.dispose();
         }
         if(receiveBtn)
         {
            receiveBtn.removeFromParent(true);
            receiveBtn.dispose();
         }
         mText = null;
         remainingNum = null;
         totalNum = null;
         receiveBtn = null;
         StarlingTools.removeChildrenClear(this);
         this.clear();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(97741),425,640,true);
         memberWorshipNum = GlobalData.$mGuild_simple.member_worship_times;
         num = GlobalData.$userData.gold;
         setUI();
      }
      
      private function setUI() : void
      {
         SendServiceAMFFun.send_user_get_association_worship_gold_info(reWorshipAward);
      }
      
      private function reWorshipAward(param1:Object) : void
      {
         var _loc2_:Function = null;
         data = param1.data;
         if(data.res_code == 1)
         {
            mText = GlobalTextStyle.getHtmlTextRenderer();
            mText.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97809),GlobalTextStyle.COLOR_W_B_Y_O,27,20,false,"center");
            mText.pivotX = mText.width / 2;
            mText.pivotY = mText.height / 2;
            mText.x = int((this.mImg9_baseBg.width - mText.width) * 0.5 - 273);
            mText.y = this.mImg9_baseBg.y + 100;
            addChild(mText);
            remainingNum = GlobalTextStyle.getHtmlTextRenderer();
            remainingNum.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97810,memberWorshipNum - data.member_worship_count,memberWorshipNum),GlobalTextStyle.COLOR_W_B_Y_O,23,20,false,"center");
            remainingNum.pivotX = remainingNum.width / 2;
            remainingNum.pivotY = remainingNum.height / 2;
            remainingNum.x = int((this.mImg9_baseBg.width - remainingNum.width) * 0.5 - 120);
            remainingNum.y = mText.y + 85;
            addChild(remainingNum);
            totalNum = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getLanguageStr(97811),data.association_worship_gold,"UI_money_gold_0_0000",16777215,16764006,20);
            totalNum._mIcon.y = totalNum.y + 4;
            totalNum.pivotX = totalNum.width / 2;
            totalNum.pivotY = totalNum.height / 2;
            totalNum.x = int((this.mImg9_baseBg.width - totalNum.width) * 0.5 + 134);
            totalNum.y = remainingNum.y + 70;
            addChild(totalNum);
            receiveBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(97812),160,70,"UI_btn_guild_4_0000");
            receiveBtn.fontColor = 16777215;
            receiveBtn.x = int((this.mImg9_baseBg.width - receiveBtn.width) * 0.5);
            receiveBtn.y = totalNum.y + 45;
            addChild(receiveBtn);
            receiveBtn.addEventListener("triggered",onReceive);
            if(data.association_worship_gold == 0)
            {
               receiveBtn.enabled = false;
            }
         }
         else
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97835),true);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
            this.onCLOSE_PANEL_SELF();
            _loc2_ = obj.reFun;
            _loc2_();
         }
      }
      
      private function onReceive(param1:Event) : void
      {
         if(data.association_worship_gold == 0)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97824),true);
            return;
         }
         SendServiceAMFFun.send_user_get_association_worship_gold(reWorshipGold);
      }
      
      private function reWorshipGold(param1:Object) : void
      {
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            return;
         }
         var _loc4_:Object = null;
         var _loc2_:Object = null;
         var _loc3_:Function = null;
         if(param1.data.res_code == 1)
         {
            _loc4_ = param1.data;
            if(this.stage)
            {
               data.association_worship_gold = 0;
               totalNum.text(GlobalLanguageStr.getLanguageStr(97811),data.association_worship_gold,"UI_money_gold_0_0000");
               receiveBtn.enabled = false;
            }

            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
            _loc2_ = GlobalFunction.getAwardByType("gold",_loc4_.user.gold - num);
            GlobalFunction.popAward("gold",GlobalLanguageStr.getLanguageStr(97636,_loc2_.msg),_loc4_.user.gold - num,false);
         }
         else
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97835),true);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
            if(this.stage)
            {
               this.onCLOSE_PANEL_SELF();
            }
            _loc3_ = obj.reFun;
            _loc3_();
         }
      }
   }
}

