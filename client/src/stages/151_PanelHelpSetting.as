package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.ui.element.ItemHelpSetting;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelCenterHelp;
   import com.meng52.net.SendAndSelect;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;

   public class PanelHelpSetting extends PanelCenterHelp
   {
      private static const TIER_KEYS:Array = ["small","wealthy","tycoon","protagonist"];

      private static const TIER_NAMES:Array = ["小氪（每日648元）","富哥（每日2000元）","大佬（每日5000元）","系统文主角（每日20000元）"];

      private var mSpending:Object;

      private var mTierButton:LOL_Scale9Button;

      private var mTierStatus:TextField;

      private var mTierMenu:Sprite;

      private var mDisposed:Boolean = false;

      public static function canChangeTier(param1:Object) : Boolean
      {
         return param1 != null && param1.can_change === true && param1.is_gm !== true;
      }

      public static function tierOptionIndex(param1:String) : int
      {
         for(var i:int = 0; i < TIER_KEYS.length; i++)
         {
            if(param1 == "spending_tier_" + i) return i;
         }
         return -1;
      }

      public static function changeTierParams(param1:int, param2:Object) : Object
      {
         if(!canChangeTier(param2) || param1 < 0 || param1 >= TIER_KEYS.length || TIER_KEYS[param1] == param2.tier)
         {
            return null;
         }
         return {"spending_tier":TIER_KEYS[param1]};
      }

      public static function canApplySpendingReply(param1:Object, param2:Boolean) : Boolean
      {
         return param2 && param1 != null && int(param1.return_code) == 0 &&
            param1.data != null && param1.data.tier != null &&
            (!param1.state_sync || GlobalData.isCurrentProfileSyncEnvelope(param1.state_sync));
      }

      public function PanelHelpSetting()
      {
         super();
      }

      override protected function initializeHandler(param1:Event) : void
      {
         mDisposed = false;
         this.removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(20119),470,595);
         this.setList();
         this.addList();
         this.createSpendingRow();
         SendAndSelect.sendAndSelectService("user.spending_info",{},onSpendingInfo);
      }

      override public function onBTN_NAME_BACK() : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_help");
      }

      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         mDisposed = true;
         mTierMenu = null;
         mTierButton = null;
         mTierStatus = null;
         super.onREMOVED_FROM_STAGE(param1);
      }

      override public function addList() : void
      {
         var _loc1_:Array = [{
            "id":0,
            "status":1,
            "title":"背景音乐"
         },{
            "id":1,
            "status":1,
            "title":"游戏音效"
         }];
         mList.y = mImg9_baseBg.y + 100;
         mList.height = 205;
         this.setListTimer(mList,_loc1_,ItemHelpSetting,false);
      }

      private function createSpendingRow() : void
      {
         var rowX:Number = mImg9_baseBg.x + (mImg9_baseBg.width - 520) * 0.5;
         var rowY:Number = mImg9_baseBg.y + 310;
         var background:Scale9Image = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",520,100,new Rectangle(110,55,70,20));
         background.x = rowX;
         background.y = rowY;
         addChild(background);
         var title:TextField = GlobalTextStyle.getTextField("切换有钱程度",30,4926491,"left",270,35);
         title.x = rowX + 30;
         title.y = rowY + 13;
         addChild(title);
         mTierStatus = GlobalTextStyle.getTextField("读取中...",16,4926491,"left",310,35);
         mTierStatus.x = rowX + 30;
         mTierStatus.y = rowY + 54;
         addChild(mTierStatus);
         mTierButton = new LOL_Scale9Button("读取中...",174,50,"UI_btn_enterGame_0_0000");
         mTierButton.x = rowX + 330;
         mTierButton.y = rowY + 24;
         mTierButton.addEventListener("triggered",openTierMenu);
         addChild(mTierButton);
         mTierMenu = new Sprite();
         var menuBg:Scale9Image = GlobalFunction.createScale9Image("UI_bg_9slice_6_0000",500,285,new Rectangle(20,20,10,10));
         menuBg.x = rowX + 10;
         menuBg.y = mImg9_baseBg.y + 60;
         mTierMenu.addChild(menuBg);
         for(var i:int = 0; i < TIER_KEYS.length; i++)
         {
            var option:LOL_Scale9Button = new LOL_Scale9Button(String(TIER_NAMES[i]),450,53,"UI_btn_normalFun_0000");
            option.name = "spending_tier_" + i;
            option.x = rowX + 35;
            option.y = mImg9_baseBg.y + 68 + i * 66;
            option.addEventListener("triggered",chooseTier);
            mTierMenu.addChild(option);
         }
         mTierMenu.visible = false;
         addChild(mTierMenu);
      }

      private function onSpendingInfo(result:Object) : void
      {
         if(canApplySpendingReply(result,!mDisposed && this.stage != null))
         {
            updateSpending(result.data);
         }
      }

      private function updateSpending(data:Object) : void
      {
         mSpending = data;
         if(!mTierButton || !mTierStatus) return;
         if(data.is_gm)
         {
            mTierButton.text = "GM（固定）";
            mTierStatus.text = "GM：不限额，注册时固定";
         }
         else
         {
            mTierButton.text = String(data.label) + " ▼";
            mTierStatus.text = "今日 ¥" + data.spent_yuan + "/" + data.daily_limit_yuan + " 余 ¥" + data.remaining_yuan;
         }
      }

      private function openTierMenu(event:Event) : void
      {
         if(!mDisposed && canChangeTier(mSpending))
         {
            mTierMenu.visible = true;
         }
      }

      private function chooseTier(event:Event) : void
      {
         if(mDisposed || !mTierMenu) return;
         var index:int = tierOptionIndex(String(event.currentTarget.name));
         mTierMenu.visible = false;
         var params:Object = changeTierParams(index,mSpending);
         if(!mDisposed && params)
         {
            SendAndSelect.sendAndSelectService("user.set_spending_tier",params,onSpendingInfo);
         }
      }
   }
}
