package com.meng52.game.ui.panel
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelCenterCasino;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import starling.display.Image;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class PanelMemberWorship extends PanelCenterCasino
   {
      
      private static const BTN_NAME_FREE:String = "btn_name_free";
      
      private static const BTN_NAME_COIN:String = "btn_name_coin";
      
      private static const BTN_NAME_GOLD:String = "btn_name_gold";
      
      private var caseFree:Scale9Image;
      
      private var caseCoin:Scale9Image;
      
      private var caseGold:Scale9Image;
      
      private var bgFree:Image;
      
      private var bgCoin:Image;
      
      private var bgGold:Image;
      
      private var txtFree:TextFieldHtmlRenderer;
      
      private var txtCoin:TextFieldHtmlRenderer;
      
      private var txtGold:TextFieldHtmlRenderer;
      
      private var freeWorshipBtn:LOL_Scale9Button;
      
      private var coinWorshipBtn:LOL_Scale9Button;
      
      private var goldWorshipBtn:LOL_Scale9Button;
      
      private var freeImg:Image;
      
      private var coinImg:Image;
      
      private var goldImg:Image;
      
      private var freeSpend:TextField;
      
      private var coinSpend:LOL_MutilTextFieldIcon;
      
      private var goldSpend:LOL_MutilTextFieldIcon;
      
      private var data:Object;
      
      private var arr:Array;
      
      private var strFree:String;
      
      private var strCoin:String;
      
      private var StrGold:String;
      
      private var coin:String;
      
      private var gold:String;
      
      private var sign:int;
      
      private var memberWorshipNum:int;
      
      public function PanelMemberWorship(param1:Object)
      {
         data = param1;
         super();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalData.$mEventDispatcher.removeEventListener("update_guild_member_list",updateMemberWorship);
         if(caseFree)
         {
            caseFree.removeFromParent(true);
            caseFree.dispose();
         }
         if(caseCoin)
         {
            caseCoin.removeFromParent(true);
            caseCoin.dispose();
         }
         if(caseGold)
         {
            caseGold.removeFromParent(true);
            caseGold.dispose();
         }
         if(bgFree)
         {
            bgFree.removeFromParent(true);
            bgFree.dispose();
         }
         if(bgCoin)
         {
            bgCoin.removeFromParent(true);
            bgCoin.dispose();
         }
         if(bgGold)
         {
            bgGold.removeFromParent(true);
            bgGold.dispose();
         }
         if(txtFree)
         {
            txtFree.removeFromParent(true);
            txtFree.dispose();
         }
         if(txtCoin)
         {
            txtCoin.removeFromParent(true);
            txtCoin.dispose();
         }
         if(txtGold)
         {
            txtGold.removeFromParent(true);
            txtGold.dispose();
         }
         if(freeWorshipBtn)
         {
            freeWorshipBtn.removeFromParent(true);
            freeWorshipBtn.dispose();
         }
         if(coinWorshipBtn)
         {
            coinWorshipBtn.removeFromParent(true);
            coinWorshipBtn.dispose();
         }
         if(goldWorshipBtn)
         {
            goldWorshipBtn.removeFromParent(true);
            goldWorshipBtn.dispose();
         }
         if(freeImg)
         {
            freeImg.removeFromParent(true);
            freeImg.dispose();
         }
         if(coinImg)
         {
            coinImg.removeFromParent(true);
            coinImg.dispose();
         }
         if(goldImg)
         {
            goldImg.removeFromParent(true);
            goldImg.dispose();
         }
         if(freeSpend)
         {
            freeSpend.removeFromParent(true);
            freeSpend.dispose();
         }
         if(coinSpend)
         {
            coinSpend.removeFromParent(true);
            coinSpend.dispose();
         }
         if(goldSpend)
         {
            goldSpend.removeFromParent(true);
            goldSpend.dispose();
         }
         caseFree = null;
         caseCoin = null;
         caseGold = null;
         bgFree = null;
         bgCoin = null;
         bgGold = null;
         txtFree = null;
         txtCoin = null;
         txtGold = null;
         freeWorshipBtn = null;
         coinWorshipBtn = null;
         goldWorshipBtn = null;
         freeImg = null;
         coinImg = null;
         goldImg = null;
         freeSpend = null;
         coinSpend = null;
         goldSpend = null;
         StarlingTools.removeChildrenClear(this);
         this.clear();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(97741),480,640,true);
         GlobalData.$mEventDispatcher.addEventListener("update_guild_member_list",updateMemberWorship);
         arr = GlobalData.$mGuild_simple.member_worship;
         memberWorshipNum = GlobalData.$mGuild_simple.member_worship_times;
         setUI();
      }
      
      private function updateMemberWorship(param1:Event) : void
      {
         if(sign == 0)
         {
            freeWorshipBtn.enabled = false;
            coinWorshipBtn.enabled = false;
            goldWorshipBtn.enabled = false;
         }
      }
      
      private function setUI() : void
      {
         strFree = arr[0][1];
         strCoin = arr[1][1];
         StrGold = arr[2][1];
         coin = arr[1][0];
         gold = arr[2][0];
         caseFree = GlobalFunction.createScale9Image("UI_guild_bg_6_0000",132,122,new Rectangle(82,103,10,10));
         caseFree.x = this.mImg9_baseBg.x + 71;
         caseFree.y = this.mImg9_baseBg.y + 110;
         addChild(caseFree);
         bgFree = GlobalFunction.createImage("UI_guildMoney_energy_0_0000");
         bgFree.x = caseFree.x + 21;
         bgFree.y = caseFree.y + 15;
         bgFree.touchable = false;
         addChild(bgFree);
         txtFree = GlobalTextStyle.getHtmlTextRenderer();
         txtFree.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97790,strFree),GlobalTextStyle.COLOR_W_B_Y_O,100,20);
         txtFree.x = caseFree.x;
         txtFree.y = caseFree.y + caseFree.height + 20;
         addChild(txtFree);
         freeWorshipBtn = new LOL_Scale9Button("免费膜拜",140,70,"UI_btn_guild_4_0000");
         freeWorshipBtn.fontSize = 23;
         freeWorshipBtn.fontColor = 16777215;
         freeWorshipBtn.name = "btn_name_free";
         freeWorshipBtn.x = txtFree.x - 4;
         freeWorshipBtn.y = txtFree.y + txtFree.height + 50;
         addChild(freeWorshipBtn);
         freeWorshipBtn.addEventListener("triggered",onWorshipBtn);
         freeImg = GlobalFunction.createImage("UI_welfare_bg_0003");
         freeImg.width = 160;
         freeImg.height = 35;
         freeImg.x = freeWorshipBtn.x - 12;
         freeImg.y = freeWorshipBtn.y + freeWorshipBtn.height + 10;
         addChild(freeImg);
         freeSpend = GlobalTextStyle.getTextField("免费",20,1513239,"left",300,46);
         freeSpend.x = freeImg.width * 0.5 + 25;
         freeSpend.y = freeImg.y + 2;
         addChild(freeSpend);
         caseCoin = GlobalFunction.createScale9Image("UI_guild_bg_6_0000",132,122,new Rectangle(82,103,10,10));
         caseCoin.x = caseFree.x + caseFree.width + 50;
         caseCoin.y = caseFree.y;
         addChild(caseCoin);
         bgCoin = GlobalFunction.createImage("UI_guildMoney_energy_0_0000");
         bgCoin.x = caseCoin.x + 21;
         bgCoin.y = caseCoin.y + 15;
         bgCoin.touchable = false;
         addChild(bgCoin);
         txtCoin = GlobalTextStyle.getHtmlTextRenderer();
         txtCoin.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97790,strCoin),GlobalTextStyle.COLOR_W_B_Y_O,100,20);
         txtCoin.x = caseCoin.x;
         txtCoin.y = txtFree.y;
         addChild(txtCoin);
         coinWorshipBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20162) + GlobalLanguageStr.getLanguageStr(97733),140,70,"UI_btn_guild_4_0000");
         coinWorshipBtn.fontSize = 23;
         coinWorshipBtn.fontColor = 16777215;
         coinWorshipBtn.name = "btn_name_coin";
         coinWorshipBtn.x = txtCoin.x - 4;
         coinWorshipBtn.y = freeWorshipBtn.y;
         addChild(coinWorshipBtn);
         coinWorshipBtn.addEventListener("triggered",onWorshipBtn);
         coinImg = GlobalFunction.createImage("UI_welfare_bg_0003");
         coinImg.width = 160;
         coinImg.height = 35;
         coinImg.x = coinWorshipBtn.x - 12;
         coinImg.y = freeImg.y;
         addChild(coinImg);
         coinSpend = new LOL_MutilTextFieldIcon("",coin,"UI_money_gold_0_0000",0,0,18);
         coinSpend.pivotX = coinSpend.width / 2;
         coinSpend.pivotY = coinSpend.height / 2;
         coinSpend.x = coinImg.x + coinImg.width / 2 - coinSpend.width / 2 + 63;
         coinSpend.y = coinImg.y + 20;
         addChild(coinSpend);
         caseGold = GlobalFunction.createScale9Image("UI_guild_bg_6_0000",132,122,new Rectangle(82,103,10,10));
         caseGold.x = caseCoin.x + caseCoin.width + 50;
         caseGold.y = caseCoin.y;
         addChild(caseGold);
         bgGold = GlobalFunction.createImage("UI_guildMoney_energy_0_0000");
         bgGold.x = caseGold.x + 21;
         bgGold.y = caseGold.y + 15;
         bgGold.touchable = false;
         addChild(bgGold);
         txtGold = GlobalTextStyle.getHtmlTextRenderer();
         txtGold.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97790,StrGold),GlobalTextStyle.COLOR_W_B_Y_O,100,20);
         txtGold.x = caseGold.x;
         txtGold.y = txtFree.y;
         addChild(txtGold);
         goldWorshipBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20149) + GlobalLanguageStr.getLanguageStr(97733),140,70,"UI_btn_guild_4_0000");
         goldWorshipBtn.fontSize = 23;
         goldWorshipBtn.fontColor = 16777215;
         goldWorshipBtn.name = "btn_name_gold";
         goldWorshipBtn.x = txtGold.x - 4;
         goldWorshipBtn.y = freeWorshipBtn.y;
         addChild(goldWorshipBtn);
         goldWorshipBtn.addEventListener("triggered",onWorshipBtn);
         goldImg = GlobalFunction.createImage("UI_welfare_bg_0003");
         goldImg.width = 160;
         goldImg.height = 35;
         goldImg.x = goldWorshipBtn.x - 12;
         goldImg.y = freeImg.y;
         addChild(goldImg);
         goldSpend = new LOL_MutilTextFieldIcon("",gold,"UI_money_coin_0_0000",0,0,18);
         goldSpend.pivotX = goldSpend.width / 2;
         goldSpend.pivotY = goldSpend.height / 2;
         goldSpend.x = goldImg.x + goldImg.width / 2 - goldSpend.width / 2 + 56;
         goldSpend.y = goldImg.y + 20;
         addChild(goldSpend);
      }
      
      private function onWorshipBtn(param1:Event) : void
      {
         var _fun:Object;
         var vip_lv:int;
         var num:Object;
         var num1:Number;
         var fun:Object;
         var _eve:Event = param1;
         var sendService:* = function():void
         {
            GlobalData.$mGameClassObject.closePopUp();
            if(btn.name == "btn_name_coin")
            {
               SendServiceAMFFun.send_user_member_worship(reFunWorship,{
                  "target_uid":data.uid,
                  "type":1
               });
            }
            if(btn.name == "btn_name_gold")
            {
               SendServiceAMFFun.send_user_member_worship(reFunWorship,{
                  "target_uid":data.uid,
                  "type":2
               });
            }
         };
         var btn:LOL_Scale9Button = _eve.target as LOL_Scale9Button;
         var Gold:int = int(arr[2][0]);
         if(btn.enabled == false)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97938),true);
            return;
         }
         if(GlobalData.$userData.vip_lv > 0)
         {
            vip_lv = int(GlobalFunction.getVipObj().energy_limit_add);
         }
         else
         {
            vip_lv = 0;
         }
         num = GlobalFunction.getEnergy();
         num1 = GlobalData.$mConfig_simple.energy_config[0] + vip_lv;
         if(num.energy >= num1)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10009),true);
            return;
         }
         if(btn.name == "btn_name_free")
         {
            SendServiceAMFFun.send_user_member_worship(reFunWorship,{
               "target_uid":data.uid,
               "type":0
            });
         }
         if(btn.name == "btn_name_coin")
         {
            if(GlobalData.$userData.gold < coin)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10023),false,"A_6999_3");
               return;
            }
            _fun = {
               "ok":sendService,
               "okA":["Pop"],
               "no":GlobalFunction.functionNull,
               "aid":"A_1001_3"
            };
            GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(97741),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97807,coin,GlobalLanguageStr.getLanguageStr(20162)),GlobalTextStyle.COLOR_W_Y_Y_G),_fun,true,null,false,true);
         }
         if(btn.name == "btn_name_gold")
         {
            if(GlobalData.$userData.coin < gold)
            {
               GlobalFunction.popErrorCoin(Gold);
               return;
            }
            fun = {
               "ok":sendService,
               "okA":["Pop"],
               "no":GlobalFunction.functionNull,
               "aid":"A_1001_3"
            };
            GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(97741),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97807,gold,GlobalLanguageStr.getLanguageStr(20149)),GlobalTextStyle.COLOR_W_Y_Y_G),fun,true,null,false,true);
         }
      }
      
      private function reFunWorship(param1:Object) : void
      {
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            return;
         }
         var _loc3_:Object = null;
         var _loc2_:int = 0;
         var _loc5_:String = "combatWin";
         SoundManager.getOnlyExample().playSound(_loc5_);
         var _loc6_:Object = param1.data;
         var _loc4_:Object = param1["params"];
         if(_loc6_.res_code == 1)
         {
            sign = 0;






            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateEn();
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{
               "flag":10,
               "zone":data.zone,
               "uid":data.uid,
               "sign":0
            });
            if(_loc4_.type == 0)
            {
               _loc2_ = int(arr[0][1]);
            }
            if(_loc4_.type == 1)
            {
               _loc2_ = int(arr[1][1]);
            }
            if(_loc4_.type == 2)
            {
               _loc2_ = int(arr[2][1]);
            }
            _loc3_ = GlobalFunction.getAwardByType("energy",_loc2_);
            GlobalFunction.popAward("energy",GlobalLanguageStr.getLanguageStr(98005,_loc3_.msg),_loc2_,false);
         }
         else if(_loc6_.res_code == -1)
         {
            sign = 1;
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97835),true);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{
               "flag":10,
               "sign":1
            });
            if(this.stage)
            {
               this.onCLOSE_PANEL_SELF();
            }
         }
         else if(_loc6_.res_code == -2)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97939),true);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{
               "flag":10,
               "sign":1
            });
            if(this.stage)
            {
               this.onCLOSE_PANEL_SELF();
            }
         }
         else
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97822),true);
         }
      }
   }
}

