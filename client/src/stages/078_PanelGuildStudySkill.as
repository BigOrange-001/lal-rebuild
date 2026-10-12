package com.meng52.game.ui.panel
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelCenterPVE;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import starling.display.Image;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class PanelGuildStudySkill extends PanelCenterPVE
   {
      
      private var data:Object;
      
      private var m_studyTxt:TextFieldHtmlRenderer;
      
      private var studyBtn:LOL_Scale9Button;
      
      private var m_nameTxt:TextField;
      
      private var m_natureTxt:TextField;
      
      private var obj:Object;
      
      private var level:Object;
      
      private var m_skillIcon:Image;
      
      private var cfg:Object;
      
      public function PanelGuildStudySkill(param1:Object)
      {
         data = param1;
         super();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(m_studyTxt)
         {
            m_studyTxt.removeFromParent(true);
            m_studyTxt.dispose();
         }
         if(studyBtn)
         {
            studyBtn.removeFromParent(true);
            studyBtn.dispose();
         }
         if(m_nameTxt)
         {
            m_nameTxt.removeFromParent(true);
            m_nameTxt.dispose();
         }
         if(m_natureTxt)
         {
            m_natureTxt.removeFromParent(true);
            m_natureTxt.dispose();
         }
         if(m_skillIcon)
         {
            m_skillIcon.removeFromParent(true);
            m_skillIcon.dispose();
         }
         m_studyTxt = null;
         studyBtn = null;
         m_nameTxt = null;
         m_natureTxt = null;
         m_skillIcon = null;
         StarlingTools.removeChildrenClear(this);
         this.clear();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(90765),400,600,true);
         cfg = GlobalData.$mGuild_simple.guild_graduate.vip_use_skill_count;
         setUI();
      }
      
      private function setUI() : void
      {
         if(data.index == 0)
         {
            level = data.data.level[1];
         }
         m_skillIcon = GlobalFunction.createImage("UI_research_money_0_000" + data.data.icon);
         m_skillIcon.x = this.mImg9_baseBg.x + 55;
         m_skillIcon.y = this.mImg9_baseBg.y + 105;
         addChild(m_skillIcon);
         m_nameTxt = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90797,data.data.name),20,16764006,"left",200,35);
         m_nameTxt.x = m_skillIcon.x + m_skillIcon.width + 10;
         m_nameTxt.y = m_skillIcon.y;
         addChild(m_nameTxt);
         m_natureTxt = GlobalTextStyle.getTextField("",20,16764006,"left",400,80);
         m_natureTxt.text = GlobalLanguageStr.getLanguageStr(90761,data.data.description + GlobalLanguageStr.getLanguageStr(2004,level.value));
         m_natureTxt.x = m_nameTxt.x;
         m_natureTxt.y = m_nameTxt.y + m_nameTxt.height + 10;
         addChild(m_natureTxt);
         m_studyTxt = GlobalTextStyle.getHtmlTextRenderer();
         m_studyTxt.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90766),GlobalTextStyle.COLOR_W_B_Y_O,20,20,false,"center");
         m_studyTxt.pivotX = m_studyTxt.width / 2;
         m_studyTxt.pivotY = m_studyTxt.height / 2;
         m_studyTxt.x = int((this.mImg9_baseBg.width - m_studyTxt.width) * 0.5 - 62);
         m_studyTxt.y = m_natureTxt.y + 80;
         addChild(m_studyTxt);
         studyBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90767),160,70,"UI_btn_guild_4_0000");
         studyBtn.fontColor = 16777215;
         studyBtn.x = int((this.mImg9_baseBg.width - studyBtn.width) * 0.5 + 20);
         studyBtn.y = m_studyTxt.y + 68;
         addChild(studyBtn);
         studyBtn.addEventListener("triggered",onStudy);
      }
      
      private function onStudy(param1:Event) : void
      {
         var skill:Object = data.data;
         SendServiceAMFFun.send_user_guild_graduate_skill_up(function(response:Object):void
         {
            reGraduateSkill(response,skill);
         },{"skill_id":skill.id});
      }
      
      private function reGraduateSkill(param1:Object, param2:Object) : void
      {
         var _loc3_:Object = null;
         var _loc4_:String = "combatWin";
         if(param1.data && GlobalFunction.isVersionedProfileReceipt(param1))
         {
            SoundManager.getOnlyExample().playSound(_loc4_);
            _loc3_ = param1.data.user_data;
            if(GlobalFunction.didApplyProfileStateSync(param1) && _loc3_.hasOwnProperty("guild_contribute") && _loc3_.guild_contribute != null)
            {
               GlobalData.$mEventDispatcher.dispatchEventWith("updata_guild_contribute",false,{"guild_contribute":_loc3_.guild_contribute});
            }
            GlobalFunction.getAwardByType("guild_skill",param2.icon);
            GlobalFunction.popAward("guild_skill",GlobalLanguageStr.getLanguageStr(90793),param2.icon,false);
            if(GlobalFunction.didApplyProfileStateSync(param1))
            {
               GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_update",false,_loc3_);
            }
            if(this.stage)
            {
               this.onCLOSE_PANEL_SELF();
            }
         }
      }
   }
}



