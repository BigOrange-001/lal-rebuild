package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelCenterPVE;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class PanelGuildSeniorTrade extends PanelCenterPVE
   {
      
      private var m_toplimitText:TextField;
      
      private var m_txtImg:Scale9Image;
      
      private var tradeBtn:LOL_Scale9Button;
      
      private var cfg:Object;
      
      private var item:Array = [];
      
      private var obj:Object;
      
      private var m_select_txt:TextField;
      
      private var selectBtn:LOL_Button;
      
      private var cfgCount:Object;
      
      private var getContribute:String;
      
      public function PanelGuildSeniorTrade()
      {
         super();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(m_toplimitText)
         {
            m_toplimitText.removeFromParent(true);
            m_toplimitText.dispose();
         }
         if(m_txtImg)
         {
            m_txtImg.removeFromParent(true);
            m_txtImg.dispose();
         }
         if(tradeBtn)
         {
            tradeBtn.removeFromParent(true);
            tradeBtn.dispose();
         }
         if(m_select_txt)
         {
            m_select_txt.removeFromParent(true);
            m_select_txt.dispose();
         }
         if(selectBtn)
         {
            selectBtn.removeFromParent(true);
            selectBtn.dispose();
         }
         m_toplimitText = null;
         m_txtImg = null;
         tradeBtn = null;
         m_select_txt = null;
         selectBtn = null;
         StarlingTools.removeChildrenClear(this);
         this.clear();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(90756),600,640,true);
         cfg = GlobalData.$mGuild_simple.guild_contribute_info.exchange_cost_info;
         cfgCount = GlobalData.$mGuild_simple.guild_contribute_info.exchange_count_info;
         setUI();
      }
      
      private function setUI() : void
      {
         m_txtImg = GlobalFunction.createScale9Image("UI_guild_bg_4_0000",300,40,new Rectangle(7,7,7,7));
         m_txtImg.x = this.mImg9_baseBg.x + (this.mImg9_baseBg.width - m_txtImg.width) * 0.5;
         m_txtImg.y = 90;
         addChild(m_txtImg);
         m_toplimitText = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90750,cfgCount[GlobalFunction.getVipLv()]["expert"] - GlobalData.$userGuild.GuildList.data.user.guild_contribute_exchange_expert_count,cfgCount[GlobalFunction.getVipLv()]["expert"]),20,6475106,"center",300,35);
         m_toplimitText.pivotX = m_toplimitText.width / 2;
         m_toplimitText.pivotY = m_toplimitText.height / 2;
         m_toplimitText.x = m_txtImg.x + 150;
         m_toplimitText.y = m_txtImg.y + 21;
         addChild(m_toplimitText);
         exchangeList();
         tradeBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(98156),130,64,"UI_btn_guild_4_0000");
         tradeBtn.fontColor = 16777215;
         tradeBtn.x = this.mImg9_baseBg.x + (this.mImg9_baseBg.width - tradeBtn.width) * 0.5;
         tradeBtn.y = this.mImg9_baseBg.height - 100;
         addChild(tradeBtn);
         tradeBtn.addEventListener("triggered",onTradeTriggered);
      }
      
      private function exchangeList() : void
      {
         for(var _loc1_ in cfg)
         {
            obj = {};
            obj["contribute"] = cfg[_loc1_].contribute;
            obj["cost"] = cfg[_loc1_].cost;
            obj["id"] = _loc1_;
            obj["isSelect"] = _loc1_ == GlobalData.$userData.trade ? 1 : 0;
            obj["type"] = cfg[_loc1_].type;
            if(GlobalData.$userData.trade !== 0)
            {
               if(_loc1_ == 5)
               {
                  GlobalData.$userData.trade = null;
                  obj["isSelect"] = 5;
                  GlobalData.$userData.trade = obj["isSelect"];
                  obj["cost"] = cfg[GlobalData.$userData.trade].cost;
                  getContribute = cfg[GlobalData.$userData.trade].contribute;
               }
            }
            if(obj["type"] == 1)
            {
               m_select_txt = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90748,obj["cost"],GlobalLanguageStr.getLanguageStr(20149),obj["contribute"]),20,16777215,"left",300,35);
               m_select_txt.x = 140;
               m_select_txt.y = _loc1_ * 70 - 165;
               addChild(m_select_txt);
               if(obj["isSelect"])
               {
                  selectBtn = new LOL_Button("","UI_tag_sell_to_book_0001",true);
               }
               else
               {
                  selectBtn = new LOL_Button("","UI_tag_sell_to_book_0000",true);
               }
               selectBtn.name = _loc1_;
               selectBtn.x = m_select_txt.x + m_select_txt.width + 10;
               selectBtn.y = m_select_txt.y - 11;
               addChild(selectBtn);
               selectBtn.addEventListener("triggered",selectTriggered);
               item.push(selectBtn);
            }
         }
      }
      
      private function selectTriggered(param1:Event) : void
      {
         var _loc2_:int = 0;
         _loc2_ = 0;
         while(_loc2_ < item.length)
         {
            (item[_loc2_] as LOL_Button).texture = GlobalFunction.getTexture("UI_tag_sell_to_book_0000",true);
            _loc2_++;
         }
         (param1.currentTarget as LOL_Button).texture = GlobalFunction.getTexture("UI_tag_sell_to_book_0001",true);
         GlobalData.$userData.trade = (param1.currentTarget as LOL_Button).name;
         obj["cost"] = cfg[GlobalData.$userData.trade].cost;
         getContribute = cfg[GlobalData.$userData.trade].contribute;
      }
      
      private function onTradeTriggered(param1:Event) : void
      {
         obj["cost"] = cfg[GlobalData.$userData.trade].cost;
         if(GlobalData.$userGuild.GuildList.data.user.guild_contribute_exchange_expert_count >= cfgCount[GlobalFunction.getVipLv()]["expert"])
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90760),true);
            return;
         }
         if(GlobalData.$userData.coin < obj["cost"])
         {
            GlobalFunction.popErrorCoin(obj["cost"]);
            return;
         }
         SendServiceAMFFun.send_user_guild_contribute_exchange(reExchange,{"exchange_id":String(GlobalData.$userData.trade)});
      }
      
      private function reExchange(param1:Object) : void
      {
         if(this.stage == null) return;
         var _loc2_:Object = null;
         var _loc3_:Object = null;
         var _loc4_:String = "combatWin";
         SoundManager.getOnlyExample().playSound(_loc4_);
         if(param1.data)
         {
            _loc2_ = param1.data;
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.coin = _loc2_.coin;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.gold = _loc2_.gold;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.vip_exp = _loc2_.vip_exp;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.vip_lv = _loc2_.vip_lv;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.attrs.guild_contribute = _loc2_.guild_contribute;
            }
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
            _loc3_ = GlobalFunction.getAwardByType("guild_contribute",getContribute);
            GlobalFunction.popAward("guild_contribute",GlobalLanguageStr.getLanguageStr(90791,_loc3_.msg),getContribute,false);
            GlobalData.$userGuild.GuildList.data.user.guild_contribute_exchange_expert_count += 1;
            m_toplimitText.text = GlobalLanguageStr.getLanguageStr(90750,cfgCount[GlobalFunction.getVipLv()]["expert"] - GlobalData.$userGuild.GuildList.data.user.guild_contribute_exchange_expert_count,cfgCount[GlobalFunction.getVipLv()]["expert"]);
            if(GlobalData.$userGuild.GuildList.data.user.guild_contribute_exchange_expert_count >= cfgCount[GlobalFunction.getVipLv()]["expert"])
            {
               tradeBtn.enabled = false;
            }
            GlobalData.$mEventDispatcher.dispatchEventWith("updata_exchange_num",false,{
               "num":cfgCount[GlobalFunction.getVipLv()]["expert"],
               "guild_contribute":_loc2_.guild_contribute
            });
         }
      }
   }
}

