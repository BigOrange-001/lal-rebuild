package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalConfig;
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
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import starling.display.Image;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   
   public class PanelGuildSkillReplace extends PanelCenterPVE
   {
      
      private var data:Object;
      
      private var m_txt_bg:Scale9Image;
      
      private var m_infoTxt:TextField;
      
      private var m_skill_add_img:PanelIconBaseSprite;
      
      private var m_selectTxt:TextField;
      
      private var m_arrow:Image;
      
      private var m_replaceImg:Image;
      
      private var m_replaceTxt:TextField;
      
      private var cfg:Object;
      
      private var selectBtn:LOL_Button;
      
      private var m_unscathedTxt:TextField;
      
      private var replaceBtn:LOL_Scale9Button;
      
      private var m_beforeImg:Image;
      
      private var hasLearnCfg:Object;
      
      private var m_id:String;
      
      private var m_icon:String;
      
      private var _type:int = 0;
      
      private var cfgObj:Object;
      
      private var m_nextImg:Image;
      
      private var costObj:Object;
      
      private var _length:int;
      
      public function PanelGuildSkillReplace(param1:Object)
      {
         data = param1;
         super();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalData.$mEventDispatcher.removeEventListener("update_guild_select_skill",onUpdateSelectSkill);
         if(m_txt_bg)
         {
            m_txt_bg.removeFromParent(true);
            m_txt_bg.dispose();
         }
         if(m_infoTxt)
         {
            m_infoTxt.removeFromParent(true);
            m_infoTxt.dispose();
         }
         if(m_arrow)
         {
            m_arrow.removeFromParent(true);
            m_arrow.dispose();
         }
         if(m_skill_add_img)
         {
            m_skill_add_img.removeFromParent(true);
         }
         if(m_selectTxt)
         {
            m_selectTxt.removeFromParent(true);
            m_selectTxt.dispose();
         }
         if(m_replaceImg)
         {
            m_replaceImg.removeFromParent(true);
            m_replaceImg.dispose();
         }
         if(m_replaceTxt)
         {
            m_replaceTxt.removeFromParent(true);
            m_replaceTxt.dispose();
         }
         if(selectBtn)
         {
            selectBtn.removeFromParent(true);
            selectBtn.dispose();
         }
         if(m_unscathedTxt)
         {
            m_unscathedTxt.removeFromParent(true);
            m_unscathedTxt.dispose();
         }
         if(replaceBtn)
         {
            replaceBtn.removeFromParent(true);
            replaceBtn.dispose();
         }
         if(m_beforeImg)
         {
            m_beforeImg.removeFromParent(true);
            m_beforeImg.dispose();
         }
         if(m_nextImg)
         {
            m_nextImg.removeFromParent(true);
            m_nextImg.dispose();
         }
         m_infoTxt = null;
         m_txt_bg = null;
         m_arrow = null;
         m_skill_add_img = null;
         m_selectTxt = null;
         m_replaceImg = null;
         m_replaceTxt = null;
         selectBtn = null;
         m_unscathedTxt = null;
         replaceBtn = null;
         m_beforeImg = null;
         m_nextImg = null;
         StarlingTools.removeChildrenClear(this);
         this.clear();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         removeEventListener("addedToStage",initializeHandler);
         GlobalData.$mEventDispatcher.addEventListener("update_guild_select_skill",onUpdateSelectSkill);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(90770),500,640,true);
         cfg = GlobalData.$mGuild_simple.guild_graduate.vip_use_skill_count;
         costObj = GlobalData.$mGuild_simple.guild_graduate.change_skill_cost;
         cfgObj = GlobalData.$mGuild_simple.guild_graduate.guild_graduate_skill;
         hasLearnCfg = GlobalData.$userData.attrs.guild_graduate_skill;
         setUI();
      }
      
      private function onUpdateSelectSkill(param1:Event) : void
      {
         m_id = param1.data.id;
         _type = 0;
         selectBtn.texture = GlobalFunction.getTexture("UI_tag_sell_to_book_0000",true);
         m_beforeImg = GlobalFunction.createImage("UI_research_money_0_000" + cfgObj[param1.data.id].icon);
         m_beforeImg.pivotX = m_beforeImg.width * 0.5;
         m_beforeImg.pivotY = m_beforeImg.height * 0.5;
         m_beforeImg.x = m_txt_bg.x + 98;
         m_beforeImg.y = m_txt_bg.y + 130;
         this.addChild(m_beforeImg);
         m_beforeImg.addEventListener("touch",beforeTouch);
         m_skill_add_img.visible = false;
         replaceBtn.enabled = true;
         if(m_unscathedTxt)
         {
            m_unscathedTxt.removeFromParent(true);
            m_unscathedTxt.dispose();
            m_unscathedTxt = null;
         }
         m_unscathedTxt = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90779,costObj[hasLearnCfg[m_id]]),20,16777215,"left",500,30,GlobalConfig.FONT_1);
         m_unscathedTxt.x = selectBtn.x + selectBtn.width + 15;
         m_unscathedTxt.y = selectBtn.y + 12;
         this.addChild(m_unscathedTxt);
         refreshReplacementText();
         if(hasLearnCfg[m_id] <= 1)
         {
            selectBtn.touchable = false;
         }
         else
         {
            selectBtn.touchable = true;
         }
      }
      
      private function setUI() : void
      {
         for(var _loc1_:String in hasLearnCfg)
         {
            _length = _length + 1;
            m_icon = cfgObj[_loc1_].icon;
         }
         m_txt_bg = GlobalFunction.createScale9Image("UI_guild_bg_4_0000",540,40,new Rectangle(7,7,7,7));
         m_txt_bg.x = this.mImg9_baseBg.x + (this.mImg9_baseBg.width - m_txt_bg.width) * 0.5;
         m_txt_bg.y = 90;
         this.addChild(m_txt_bg);
         m_infoTxt = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90775,cfg[GlobalFunction.getVipLv()]),20,6475106,"center",550,35);
         m_infoTxt.pivotX = m_infoTxt.width / 2;
         m_infoTxt.pivotY = m_infoTxt.height / 2;
         m_infoTxt.x = m_txt_bg.x + 270;
         m_infoTxt.y = m_txt_bg.y + 21;
         this.addChild(m_infoTxt);
         if(_length > 1)
         {
            m_skill_add_img = new PanelIconBaseSprite("UI_equip_bg_3_0007","UI_icon_0_0000");
            m_skill_add_img.pivotX = m_skill_add_img.width * 0.5;
            m_skill_add_img.pivotY = m_skill_add_img.height * 0.5;
            m_skill_add_img.x = m_txt_bg.x + 98;
            m_skill_add_img.y = m_txt_bg.y + 125;
            m_skill_add_img.addEventListener("touch",onTouch);
            this.addChild(m_skill_add_img);
         }
         else
         {
            m_beforeImg = GlobalFunction.createImage("UI_research_money_0_000" + m_icon);
            m_beforeImg.pivotX = m_beforeImg.width * 0.5;
            m_beforeImg.pivotY = m_beforeImg.height * 0.5;
            m_beforeImg.x = m_txt_bg.x + 98;
            m_beforeImg.y = m_txt_bg.y + 130;
            this.addChild(m_beforeImg);
            m_beforeImg.addEventListener("touch",beforeTouch);
            m_id = _loc1_;
         }
         m_selectTxt = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90777),18,16777215,"left",200,30,GlobalConfig.FONT_1);
         m_selectTxt.x = _length > 1 ? m_skill_add_img.x - 76 : m_beforeImg.x - 76;
         m_selectTxt.y = _length > 1 ? m_skill_add_img.y + m_skill_add_img.height - 45 : m_beforeImg.y + m_beforeImg.height - 45;
         this.addChild(m_selectTxt);
         m_arrow = GlobalFunction.createImage("UI_equip_tag_0_0000");
         m_arrow.pivotY = m_arrow.height * 0.5;
         m_arrow.x = _length > 1 ? m_skill_add_img.x + m_skill_add_img.width + 40 : m_beforeImg.x + m_beforeImg.width + 40;
         m_arrow.y = _length > 1 ? m_skill_add_img.y + m_skill_add_img.height * 0.5 - 48 : m_beforeImg.y + m_beforeImg.height * 0.5 - 48;
         this.addChild(m_arrow);
         m_replaceImg = GlobalFunction.createImage("UI_research_money_0_000" + data.icon);
         m_replaceImg.pivotX = m_replaceImg.width * 0.5;
         m_replaceImg.pivotY = m_replaceImg.height * 0.5;
         m_replaceImg.x = m_arrow.x + m_arrow.width + 135;
         m_replaceImg.y = _length > 1 ? m_skill_add_img.y + 5 : m_beforeImg.y;
         this.addChild(m_replaceImg);
         m_replaceTxt = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90778),18,16777215,"left",100,30,GlobalConfig.FONT_1);
         m_replaceTxt.x = m_replaceImg.x - 52;
         m_replaceTxt.y = m_selectTxt.y;
         this.addChild(m_replaceTxt);
         selectBtn = new LOL_Button("","UI_tag_sell_to_book_0000",true);
         selectBtn.x = _length > 1 ? m_skill_add_img.x + 19 : m_beforeImg.x + 19;
         selectBtn.y = m_selectTxt.y + 56;
         this.addChild(selectBtn);
         selectBtn.addEventListener("triggered",selectTriggered);
         m_unscathedTxt = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90779,costObj[hasLearnCfg[_loc1_]]),20,16777215,"left",500,30,GlobalConfig.FONT_1);
         m_unscathedTxt.x = selectBtn.x + selectBtn.width + 15;
         m_unscathedTxt.y = selectBtn.y + 12;
         this.addChild(m_unscathedTxt);
         refreshReplacementText();
         replaceBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90780),160,70,"UI_btn_guild_4_0000");
         replaceBtn.fontColor = 16777215;
         replaceBtn.x = int((this.mImg9_baseBg.width - replaceBtn.width) * 0.5);
         replaceBtn.y = m_unscathedTxt.y + m_unscathedTxt.height + 30;
         this.addChild(replaceBtn);
         replaceBtn.addEventListener("triggered",replaceTriggered);
         if(m_skill_add_img)
         {
            replaceBtn.enabled = false;
            selectBtn.touchable = false;
         }
         if(_length <= 1)
         {
            if(hasLearnCfg[_loc1_] <= 1)
            {
               selectBtn.touchable = false;
            }
            else
            {
               selectBtn.touchable = true;
            }
         }
      }
      
      private function replaceTriggered(param1:Event) : void
      {
         var _fun:Object;
         var eve:Event = param1;
         var sendService:* = function():void
         {
            GlobalData.$mGameClassObject.closePopUp();
            SendServiceAMFFun.send_user_guild_graduate_skill_change(reReplace,{
               "skill_id_1":m_id,
               "skill_id_2":data.id,
               "type":_type
            });
         };
         if(replaceBtn.enabled == false)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90796),true);
            return;
         }
         if(selectBtn.texture == GlobalFunction.getTexture("UI_tag_sell_to_book_0000"))
         {
            _fun = {
               "ok":sendService,
               "okA":["Pop"],
               "no":GlobalFunction.functionNull,
               "aid":"A_1001_3"
            };
            GlobalFunction.popAlert("",int(hasLearnCfg[m_id]) <= 1 ? "免费替换为1级？" : "降至" + (int(hasLearnCfg[m_id]) - 1) + "级并消耗" + int(costObj[hasLearnCfg[m_id]]) + "贡献替换？",_fun,true,null,false,true);
         }
         else if(GlobalData.$userData.coin >= costObj[hasLearnCfg[m_id]])
         {
            SendServiceAMFFun.send_user_guild_graduate_skill_change(reReplace,{
               "skill_id_1":m_id,
               "skill_id_2":data.id,
               "type":_type
            });
         }
         else
         {
            GlobalFunction.popErrorCoin(costObj[hasLearnCfg[m_id]]);
         }
      }
      
      private function selectTriggered(param1:Event) : void
      {
         if(selectBtn.texture == GlobalFunction.getTexture("UI_tag_sell_to_book_0000"))
         {
            selectBtn.texture = GlobalFunction.getTexture("UI_tag_sell_to_book_0001",true);
            _type = 1;
         }
         else
         {
            selectBtn.texture = GlobalFunction.getTexture("UI_tag_sell_to_book_0000",true);
            _type = 0;
         }
         refreshReplacementText();
      }

      private function refreshReplacementText() : void
      {
         if(!m_unscathedTxt || !m_id || !hasLearnCfg || !costObj)
         {
            return;
         }
         var skillLevel:int = int(hasLearnCfg[m_id]);
         var price:int = int(costObj[skillLevel]);
         if(_type == 1)
         {
            m_unscathedTxt.text = "保留" + skillLevel + "级，消耗" + price + " 金砖";
         }
         else if(skillLevel <= 1)
         {
            m_unscathedTxt.text = "免费替换为1级";
         }
         else
         {
            m_unscathedTxt.text = "降至" + (skillLevel - 1) + "级，消耗" + price + "贡献";
         }
      }
      
      private function onTouch(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(this);
         if(_loc2_ && _loc2_.phase == "ended")
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_guild_replace_select",false,true);
         }
      }
      
      private function beforeTouch(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(this);
         if(_loc2_ && _loc2_.phase == "ended")
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_guild_replace_select",false,true);
         }
      }
      
      private function reReplace(param1:Object) : void
      {
         if(this.stage == null) return;
         var _loc2_:Object = null;
         var _loc3_:Object = null;
         var _loc4_:String = "combatWin";
         SoundManager.getOnlyExample().playSound(_loc4_);
         if(param1.data)
         {
            _loc2_ = param1.data.user_data;
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
            GlobalData.$userData.attrs.guild_graduate_skill = _loc2_.guild_graduate_skill;
            }
            if(_loc2_.guild_contribute != null)
            {
               if(!GlobalFunction.isVersionedProfileReceipt(param1))
               {
               GlobalData.$userData.attrs.guild_contribute = _loc2_.guild_contribute;
               }
            }
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
            _loc3_ = GlobalFunction.getAwardByType("guild_skill",data.icon);
            GlobalFunction.popAward("guild_skill",GlobalLanguageStr.getLanguageStr(90795),data.icon,false);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_replace",false,_loc2_);
            this.onCLOSE_PANEL_SELF();
         }
      }
   }
}

