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
   import flash.utils.setTimeout;
   import starling.display.Image;
   import starling.events.Event;
   
   public class PanelGuildWorship extends PanelCenterCasino
   {
      
      private static const BTN_NAME_COIN:String = "btn_name_coin";
      
      private static const BTN_NAME_GOLD1:String = "btn_name_gold1";
      
      private static const BTN_NAME_GOLD2:String = "btn_name_gold2";
      
      private var caseCoin:Scale9Image;
      
      private var caseGold1:Scale9Image;
      
      private var caseGold2:Scale9Image;
      
      private var bgCoin:Image;
      
      private var bgGold1:Image;
      
      private var bgGold2:Image;
      
      private var txtCoin:TextFieldHtmlRenderer;
      
      private var txtGold1:TextFieldHtmlRenderer;
      
      private var txtGold2:TextFieldHtmlRenderer;
      
      private var coinWorshipBtn:LOL_Scale9Button;
      
      private var goldWorshipBtn1:LOL_Scale9Button;
      
      private var goldWorshipBtn2:LOL_Scale9Button;
      
      private var coinImg:Image;
      
      private var goldImg1:Image;
      
      private var goldImg2:Image;
      
      private var coinSpend:LOL_MutilTextFieldIcon;
      
      private var goldSpend1:LOL_MutilTextFieldIcon;
      
      private var goldSpend2:LOL_MutilTextFieldIcon;
      
      private var aliveCoin:TextFieldHtmlRenderer;
      
      private var aliveGold1:TextFieldHtmlRenderer;
      
      private var aliveGold2:TextFieldHtmlRenderer;
      
      private var data:Object;
      
      private var arr:Array;
      
      private var strCoin:String;
      
      private var StrGold1:String;
      
      private var StrGold2:String;
      
      private var coin:String;
      
      private var gold1:String;
      
      private var gold2:String;
      
      private var StrAliveCoin:String;
      
      private var StrAliveGold1:String;
      
      private var StrAliveGold2:String;
      
      private var guildWorshipNum:int;
      
      private var lvText:TextFieldHtmlRenderer;
      
      private var totalAlive:TextFieldHtmlRenderer;
      
      private var needNum:TextFieldHtmlRenderer;
      
      private var surplusWorshipNum:TextFieldHtmlRenderer;
      
      private var btn:LOL_Scale9Button;
      
      private var aliveNum:int;
      
      private var _data:Object;
      
      private var award:Object;
      
      private var num:int;
      
      public function PanelGuildWorship(param1:Object)
      {
         _data = param1;
         super();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalData.$mEventDispatcher.removeEventListener("updata_guild_worship",updataGuildWorship);
         if(caseCoin)
         {
            caseCoin.removeFromParent(true);
            caseCoin.dispose();
         }
         if(caseGold1)
         {
            caseGold1.removeFromParent(true);
            caseGold1.dispose();
         }
         if(caseGold2)
         {
            caseGold2.removeFromParent(true);
            caseGold2.dispose();
         }
         if(bgCoin)
         {
            bgCoin.removeFromParent(true);
            bgCoin.dispose();
         }
         if(bgGold1)
         {
            bgGold1.removeFromParent(true);
            bgGold1.dispose();
         }
         if(bgGold2)
         {
            bgGold2.removeFromParent(true);
            bgGold2.dispose();
         }
         if(txtCoin)
         {
            txtCoin.removeFromParent(true);
            txtCoin.dispose();
         }
         if(txtGold1)
         {
            txtGold1.removeFromParent(true);
            txtGold1.dispose();
         }
         if(txtGold2)
         {
            txtGold2.removeFromParent(true);
            txtGold2.dispose();
         }
         if(coinWorshipBtn)
         {
            coinWorshipBtn.removeFromParent(true);
            coinWorshipBtn.dispose();
         }
         if(goldWorshipBtn1)
         {
            goldWorshipBtn1.removeFromParent(true);
            goldWorshipBtn1.dispose();
         }
         if(goldWorshipBtn2)
         {
            goldWorshipBtn2.removeFromParent(true);
            goldWorshipBtn2.dispose();
         }
         if(coinImg)
         {
            coinImg.removeFromParent(true);
            coinImg.dispose();
         }
         if(goldImg1)
         {
            goldImg1.removeFromParent(true);
            goldImg1.dispose();
         }
         if(goldImg2)
         {
            goldImg2.removeFromParent(true);
            goldImg2.dispose();
         }
         if(coinSpend)
         {
            coinSpend.removeFromParent(true);
            coinSpend.dispose();
         }
         if(goldSpend1)
         {
            goldSpend1.removeFromParent(true);
            goldSpend1.dispose();
         }
         if(goldSpend2)
         {
            goldSpend2.removeFromParent(true);
            goldSpend2.dispose();
         }
         if(lvText)
         {
            lvText.removeFromParent(true);
            lvText.dispose();
         }
         if(totalAlive)
         {
            totalAlive.removeFromParent(true);
            totalAlive.dispose();
         }
         if(needNum)
         {
            needNum.removeFromParent(true);
            needNum.dispose();
         }
         if(btn)
         {
            btn.removeFromParent(true);
            btn.dispose();
         }
         if(aliveCoin)
         {
            aliveCoin.removeFromParent(true);
            aliveCoin.dispose();
         }
         if(aliveGold2)
         {
            aliveCoin.removeFromParent(true);
            aliveCoin.dispose();
         }
         if(aliveGold1)
         {
            aliveGold1.removeFromParent(true);
            aliveGold1.dispose();
         }
         if(surplusWorshipNum)
         {
            surplusWorshipNum.removeFromParent(true);
            surplusWorshipNum.dispose();
         }
         caseCoin = null;
         caseGold1 = null;
         caseGold2 = null;
         bgCoin = null;
         bgGold1 = null;
         bgGold2 = null;
         txtCoin = null;
         txtGold1 = null;
         txtGold2 = null;
         coinWorshipBtn = null;
         goldWorshipBtn1 = null;
         goldWorshipBtn2 = null;
         coinImg = null;
         goldImg1 = null;
         goldImg2 = null;
         coinSpend = null;
         goldSpend1 = null;
         goldSpend2 = null;
         lvText = null;
         totalAlive = null;
         needNum = null;
         btn = null;
         aliveCoin = null;
         aliveGold1 = null;
         aliveGold2 = null;
         surplusWorshipNum = null;
         StarlingTools.removeChildrenClear(this);
         this.clear();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         removeEventListener("addedToStage",initializeHandler);
         GlobalData.$mEventDispatcher.addEventListener("updata_guild_worship",updataGuildWorship);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(97740),510,640,true);
         arr = GlobalData.$mGuild_simple.guild_worship;
         guildWorshipNum = GlobalData.$mGuild_simple.guild_worship_times;
         setUI();
         onReGuild(GlobalData.$userGuild.GuildList);
      }
      
      private function updataGuildWorship(param1:Event) : void
      {
         updateWorshipButtons(param1.data.user);
      }

      private function updateWorshipButtons(user:Object) : void
      {
         var dailyCount:int = 0;
         var freeCount:int = 0;
         var freeLimit:int = int(GlobalData.$mGuild_simple.guild_worship_free_daily_limit);
         if(user != null && user.worship_info != null)
         {
            dailyCount = int(user.worship_info.guild_worship_count);
            if(user.worship_info.guild_worship_free_count != null)
            {
               freeCount = int(user.worship_info.guild_worship_free_count);
            }
         }
         if(coinWorshipBtn != null)
         {
            coinWorshipBtn.enabled = dailyCount < guildWorshipNum && freeCount < freeLimit;
         }
         if(goldWorshipBtn1 != null)
         {
            goldWorshipBtn1.enabled = dailyCount < guildWorshipNum;
         }
         if(goldWorshipBtn2 != null)
         {
            goldWorshipBtn2.enabled = dailyCount < guildWorshipNum;
         }
      }
      
      private function onReGuild(param1:Object) : void
      {
         var _loc4_:String = null;
         var _loc3_:Object = null;
         var _loc2_:Function = null;
         data = param1.data;
         if(data.flag == 1)
         {
            _loc4_ = GlobalData.$userGuild.GuildList.data ? GlobalData.$userGuild.GuildList.data.association_info.level : GlobalData.$userGuild.GuildList.association_info.level;
            _loc3_ = GlobalData.$mGuild_simple.guild_level["level_" + _loc4_];
            aliveNum = _loc3_.flourishing;
            lvText = GlobalTextStyle.getHtmlTextRenderer();
            lvText.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97804,data.association_info.level),GlobalTextStyle.COLOR_W_B_Y_O,300,20);
            lvText.width = 210;
            lvText.x = this.mImg9_baseBg.x + 65;
            lvText.y = caseCoin.y - 65;
            addChild(lvText);
            totalAlive = GlobalTextStyle.getHtmlTextRenderer();
            totalAlive.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97805,data.association_info.total_alive),GlobalTextStyle.COLOR_W_B_Y_O,300,20);
            totalAlive.x = lvText.x + lvText.width + 107;
            totalAlive.y = lvText.y;
            addChild(totalAlive);
            surplusWorshipNum = GlobalTextStyle.getHtmlTextRenderer();
            surplusWorshipNum.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97810,guildWorshipNum - data.user.worship_info.guild_worship_count,guildWorshipNum),GlobalTextStyle.COLOR_W_B_Y_O,300,20);
            surplusWorshipNum.x = lvText.x;
            surplusWorshipNum.y = caseCoin.y - 40;
            addChild(surplusWorshipNum);
            needNum = GlobalTextStyle.getHtmlTextRenderer();
            needNum.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97806,GlobalData.$userGuild.GuildList.data.association_info.level == 10 ? aliveNum : Math.abs(aliveNum - data.association_info.total_alive)),GlobalTextStyle.COLOR_W_B_Y_O,300,20);
            needNum.pivotX = needNum.width / 2;
            needNum.pivotY = needNum.height / 2;
            needNum.x = totalAlive.x;
            needNum.y = surplusWorshipNum.y;
            addChild(needNum);
            updateWorshipButtons(data.user);
         }
         else
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97835),true);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":4});
            this.onCLOSE_PANEL_SELF();
            _loc2_ = _data.reFun;
            _loc2_();
         }
      }
      
      private function setUI() : void
      {
         strCoin = arr[0][2];
         StrGold1 = arr[1][2];
         StrGold2 = arr[2][2];
         coin = arr[0][0];
         gold1 = arr[1][0];
         gold2 = arr[2][0];
         StrAliveCoin = arr[0][1];
         StrAliveGold1 = arr[1][1];
         StrAliveGold2 = arr[2][1];
         caseCoin = GlobalFunction.createScale9Image("UI_guild_bg_6_0000",132,122,new Rectangle(82,103,10,10));
         caseCoin.x = this.mImg9_baseBg.x + 61;
         caseCoin.y = this.mImg9_baseBg.y + 150;
         addChild(caseCoin);
         bgCoin = GlobalFunction.createImage("UI_guildMoney_power_0_0000");
         bgCoin.x = caseCoin.x + 21;
         bgCoin.y = caseCoin.y + 15;
         bgCoin.touchable = false;
         addChild(bgCoin);
         txtCoin = GlobalTextStyle.getHtmlTextRenderer();
         txtCoin.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(98223,int(GlobalData.$mGuild_simple.guild_worship_free_daily_limit)),GlobalTextStyle.COLOR_W_B_Y_O,150,16,false,"center");
         txtCoin.x = caseCoin.x - 9;
         txtCoin.y = caseCoin.y + caseCoin.height + 10;
         addChild(txtCoin);
         aliveCoin = GlobalTextStyle.getHtmlTextRenderer();
         aliveCoin.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(98224,StrAliveCoin,int(GlobalData.$mGuild_simple.guild_worship_currency_reward)),GlobalTextStyle.COLOR_W_B_Y_O,170,14,false,"center");
         aliveCoin.x = caseCoin.x - 19;
         aliveCoin.y = txtCoin.y + txtCoin.height + 30;
         addChild(aliveCoin);
         coinWorshipBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(98226),140,70,"UI_btn_guild_4_0000");
         coinWorshipBtn.fontSize = 23;
         coinWorshipBtn.fontColor = 16777215;
         coinWorshipBtn.name = "btn_name_coin";
         coinWorshipBtn.x = caseCoin.x - 5;
         coinWorshipBtn.y = aliveCoin.y + aliveCoin.height + 40;
         addChild(coinWorshipBtn);
         coinWorshipBtn.addEventListener("triggered",onWorshipBtn);
         coinImg = GlobalFunction.createImage("UI_welfare_bg_0003");
         coinImg.width = 160;
         coinImg.height = 35;
         coinImg.x = coinWorshipBtn.x - 12;
         coinImg.y = coinWorshipBtn.y + coinWorshipBtn.height + 10;
         coinImg.visible = false;
         addChild(coinImg);
         coinSpend = new LOL_MutilTextFieldIcon("",coin,"UI_money_gold_0_0000",0,0,18);
         coinSpend.pivotX = coinSpend.width / 2;
         coinSpend.pivotY = coinSpend.height / 2;
         coinSpend.x = coinImg.x + coinImg.width / 2 - coinSpend.width / 2 + 63;
         coinSpend.y = coinImg.y + 20;
         coinSpend.visible = false;
         addChild(coinSpend);
         caseGold1 = GlobalFunction.createScale9Image("UI_guild_bg_6_0000",132,122,new Rectangle(82,103,10,10));
         caseGold1.x = caseCoin.x + caseCoin.width + 60;
         caseGold1.y = caseCoin.y;
         addChild(caseGold1);
         bgGold1 = GlobalFunction.createImage("UI_guildMoney_power_0_0000");
         bgGold1.x = caseGold1.x + 21;
         bgGold1.y = caseGold1.y + 15;
         bgGold1.touchable = false;
         addChild(bgGold1);
         txtGold1 = GlobalTextStyle.getHtmlTextRenderer();
         txtGold1.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(98225,gold1),GlobalTextStyle.COLOR_W_B_Y_O,150,16,false,"center");
         txtGold1.x = caseGold1.x - 9;
         txtGold1.y = txtCoin.y;
         addChild(txtGold1);
         aliveGold1 = GlobalTextStyle.getHtmlTextRenderer();
         aliveGold1.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(98227,StrAliveGold1),GlobalTextStyle.COLOR_W_B_Y_O,170,14,false,"center");
         aliveGold1.x = caseGold1.x - 19;
         aliveGold1.y = txtGold1.y + txtGold1.height + 30;
         addChild(aliveGold1);
         goldWorshipBtn1 = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20149) + GlobalLanguageStr.getLanguageStr(97733),140,70,"UI_btn_guild_4_0000");
         goldWorshipBtn1.fontSize = 23;
         goldWorshipBtn1.fontColor = 16777215;
         goldWorshipBtn1.name = "btn_name_gold1";
         goldWorshipBtn1.x = caseGold1.x - 5;
         goldWorshipBtn1.y = coinWorshipBtn.y;
         addChild(goldWorshipBtn1);
         goldWorshipBtn1.addEventListener("triggered",onWorshipBtn);
         goldImg1 = GlobalFunction.createImage("UI_welfare_bg_0003");
         goldImg1.width = 160;
         goldImg1.height = 35;
         goldImg1.x = goldWorshipBtn1.x - 12;
         goldImg1.y = coinImg.y;
         addChild(goldImg1);
         goldSpend1 = new LOL_MutilTextFieldIcon("",gold1,"UI_money_coin_0_0000",0,0,18);
         goldSpend1.pivotX = goldSpend1.width / 2;
         goldSpend1.pivotY = goldSpend1.height / 2;
         goldSpend1.x = goldImg1.x + goldImg1.width / 2 - goldSpend1.width / 2 + 38;
         goldSpend1.y = goldImg1.y + 20;
         addChild(goldSpend1);
         caseGold2 = GlobalFunction.createScale9Image("UI_guild_bg_6_0000",132,122,new Rectangle(82,103,10,10));
         caseGold2.x = caseGold1.x + caseGold1.width + 60;
         caseGold2.y = caseGold1.y;
         addChild(caseGold2);
         bgGold2 = GlobalFunction.createImage("UI_guildMoney_power_0_0000");
         bgGold2.x = caseGold2.x + 21;
         bgGold2.y = caseGold2.y + 15;
         bgGold2.touchable = false;
         addChild(bgGold2);
         txtGold2 = GlobalTextStyle.getHtmlTextRenderer();
         txtGold2.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(98225,gold2),GlobalTextStyle.COLOR_W_B_Y_O,150,16,false,"center");
         txtGold2.x = caseGold2.x - 9;
         txtGold2.y = txtCoin.y;
         addChild(txtGold2);
         aliveGold2 = GlobalTextStyle.getHtmlTextRenderer();
         aliveGold2.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(98227,StrAliveGold2),GlobalTextStyle.COLOR_W_B_Y_O,170,14,false,"center");
         aliveGold2.x = caseGold2.x - 19;
         aliveGold2.y = txtGold2.y + txtGold2.height + 30;
         addChild(aliveGold2);
         goldWorshipBtn2 = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20149) + GlobalLanguageStr.getLanguageStr(97733),140,70,"UI_btn_guild_4_0000");
         goldWorshipBtn2.fontSize = 23;
         goldWorshipBtn2.fontColor = 16777215;
         goldWorshipBtn2.name = "btn_name_gold2";
         goldWorshipBtn2.x = caseGold2.x - 5;
         goldWorshipBtn2.y = coinWorshipBtn.y;
         addChild(goldWorshipBtn2);
         goldWorshipBtn2.addEventListener("triggered",onWorshipBtn);
         goldImg2 = GlobalFunction.createImage("UI_welfare_bg_0003");
         goldImg2.width = 160;
         goldImg2.height = 35;
         goldImg2.x = goldWorshipBtn2.x - 12;
         goldImg2.y = coinImg.y;
         addChild(goldImg2);
         goldSpend2 = new LOL_MutilTextFieldIcon("",gold2,"UI_money_coin_0_0000",0,0,18);
         goldSpend2.pivotX = goldSpend2.width / 2;
         goldSpend2.pivotY = goldSpend2.height / 2;
         goldSpend2.x = goldImg2.x + goldImg2.width / 2 - goldSpend2.width / 2 + 56;
         goldSpend2.y = goldImg2.y + 20;
         addChild(goldSpend2);
      }
      
      private function onWorshipBtn(param1:Event) : void
      {
         var fun:Object;
         var _eve:Event = param1;
         var sendService:* = function():void
         {
            GlobalData.$mGameClassObject.closePopUp();
            if(btn.name == "btn_name_coin")
            {
               SendServiceAMFFun.send_user_guild_worship(reFunWorship,{"type":0});
            }
            if(btn.name == "btn_name_gold1")
            {
               SendServiceAMFFun.send_user_guild_worship(reFunWorship,{"type":1});
            }
            if(btn.name == "btn_name_gold2")
            {
               SendServiceAMFFun.send_user_guild_worship(reFunWorship,{"type":2});
            }
         };
         btn = _eve.target as LOL_Scale9Button;
         var Gold1:int = int(arr[1][0]);
         var Gold2:int = int(arr[2][0]);
         if(btn.enabled == false)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97801),true);
            return;
         }
         if(btn.name == "btn_name_coin")
         {
            if(GlobalData.$userData.gold < coin)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10023),false,"A_6999_3");
               return;
            }
            fun = {
               "ok":sendService,
               "okA":["Pop"],
               "no":GlobalFunction.functionNull,
               "aid":"A_1001_3"
            };
            GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(97740),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(98223,int(GlobalData.$mGuild_simple.guild_worship_free_daily_limit)),GlobalTextStyle.COLOR_W_Y_Y_G) + "\n" + Tools.formatLineX(GlobalLanguageStr.getLanguageStr(98220,int(GlobalData.$mGuild_simple.guild_worship_currency_reward)),GlobalTextStyle.COLOR_W_B_Y_O),fun,true,null,false,true);
         }
         if(btn.name == "btn_name_gold1")
         {
            if(GlobalData.$userData.coin < gold1)
            {
               GlobalFunction.popErrorCoin(Gold1);
               return;
            }
            fun = {
               "ok":sendService,
               "okA":["Pop"],
               "no":GlobalFunction.functionNull,
               "aid":"A_1001_3"
            };
            GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(97740),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97808,gold1,GlobalLanguageStr.getLanguageStr(20149)),GlobalTextStyle.COLOR_W_Y_Y_G),fun,true,null,false,true);
         }
         if(btn.name == "btn_name_gold2")
         {
            if(GlobalData.$userData.coin < gold2)
            {
               GlobalFunction.popErrorCoin(Gold2);
               return;
            }
            fun = {
               "ok":sendService,
               "okA":["Pop"],
               "no":GlobalFunction.functionNull,
               "aid":"A_1001_3"
            };
            GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(97740),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97808,gold2,GlobalLanguageStr.getLanguageStr(20149)),GlobalTextStyle.COLOR_W_Y_Y_G),fun,true,null,false,true);
         }
      }
      
      private function reFunWorship(param1:Object) : void
      {
         if(this.stage == null) return;
         var _loc2_:Object = null;
         var _loc3_:Function = null;
         var _loc4_:String = "combatWin";
         var _currencyReward:int = 0;
         SoundManager.getOnlyExample().playSound(_loc4_);
         data = param1.data;
         if(data.res_code == 1)
         {
            _loc2_ = param1["params"];
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.coin = data.user.coin;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.gold = data.user.gold;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.attrs.association_gold = data.user.association_gold;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.vip_exp = data.user.vip_exp;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.vip_lv = data.user.vip_lv;
            }
            GlobalData.$userGuild.total_alive = data.association.total_alive;
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
            GlobalData.$mEventDispatcher.dispatchEventWith("updata_guild_worship",false,data);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
            _currencyReward = int(data.user.guild_currency_reward != null ? data.user.guild_currency_reward : data.guild_currency_reward);
            num = _currencyReward;
            if(GlobalData.$userGuild.GuildList.data.association_info.level < data.association.level)
            {
               GlobalFunction.popError(Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97919,data.association.level),GlobalTextStyle.COLOR_W_B_Y_O,50),true);
               if(_currencyReward > 0)
               {
                  award = GlobalFunction.getAwardByType("guild_money",_currencyReward);
                  setTimeout(delayTime,1000);
               }
            }
            else if(_currencyReward > 0)
            {
               award = GlobalFunction.getAwardByType("guild_money",_currencyReward);
               delayTime();
            }
            lvText.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97804,data.association.level),GlobalTextStyle.COLOR_W_B_Y_O,200,20);
            totalAlive.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97805,data.association.total_alive),GlobalTextStyle.COLOR_W_B_Y_O,200,20);
            aliveNum = GlobalData.$mGuild_simple.guild_level["level_" + data.association.level].flourishing;
            needNum.text = needNum.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97806,data.association.level == 10 ? aliveNum : Math.abs(aliveNum - data.association.total_alive)),GlobalTextStyle.COLOR_W_B_Y_O,200,20);
            surplusWorshipNum.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97810,guildWorshipNum - data.user.guild_worship_count,guildWorshipNum),GlobalTextStyle.COLOR_W_B_Y_O,200,20);
         }
         if(data.res_code == -1)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97835),true);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
            this.onCLOSE_PANEL_SELF();
            _loc3_ = _data.reFun;
            _loc3_();
         }
      }
      
      private function delayTime() : void
      {
         GlobalFunction.popAward("guild_money",GlobalLanguageStr.getLanguageStr(98005,award.msg),num,false);
      }
   }
}

