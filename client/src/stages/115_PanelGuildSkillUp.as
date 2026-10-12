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
   import starling.events.Event;
   
   public class PanelGuildSkillUp extends PanelCenterPVE
   {
      
      private var m_info:TextFieldHtmlRenderer;
      
      private var upBtn:LOL_Scale9Button;
      
      private var data:Object;
      
      private var obj:Object;
      
      private var level:Object;
      
      private var nowLv:int;
      
      private var nextLv:int;
      
      public function PanelGuildSkillUp(param1:Object)
      {
         data = param1;
         super();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(m_info)
         {
            m_info.removeFromParent(true);
            m_info.dispose();
         }
         if(upBtn)
         {
            upBtn.removeFromParent(true);
            upBtn.dispose();
         }
         m_info = null;
         upBtn = null;
         StarlingTools.removeChildrenClear(this);
         this.clear();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(90772),330,600,true);
         obj = GlobalData.$userData.attrs.guild_graduate_skill;
         setUI();
      }
      
      private function setUI() : void
      {
         for(var _loc2_ in obj)
         {
            if(_loc2_ == data.id)
            {
               nowLv = obj[_loc2_];
               nextLv = obj[_loc2_] + 1;
               level = data.level[nextLv];
            }
         }
         m_info = GlobalTextStyle.getHtmlTextRenderer();
         m_info.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90774,level.up_demand,data.name,nowLv,nextLv),GlobalTextStyle.COLOR_W_B_Y_O,25,20,false,"center");
         m_info.pivotX = m_info.width * 0.5;
         m_info.pivotY = m_info.height * 0.5;
         m_info.x = int((this.mImg9_baseBg.width - m_info.width) * 0.5 - 215);
         m_info.y = this.mImg9_baseBg.y + 102;
         addChild(m_info);
         upBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90773),160,70,"UI_btn_guild_4_0000");
         upBtn.fontColor = 16777215;
         upBtn.x = int((this.mImg9_baseBg.width - upBtn.width) * 0.5 + 20);
         upBtn.y += 215;
         addChild(upBtn);
         upBtn.addEventListener("triggered",onUpBtn);
         if(GlobalData.$userData.attrs.guild_contribute < level.up_demand)
         {
            upBtn.enabled = false;
         }
         for(var _loc1_ in obj)
         {
            if(_loc1_ == data.id)
            {
               if(GlobalData.$userGuild.GuildList.data.association_info.level <= obj[_loc1_])
               {
                  upBtn.enabled = false;
               }
            }
         }
      }
      
      private function onUpBtn(param1:Event) : void
      {
         if(upBtn.enabled == false)
         {
            for(var _loc2_ in obj)
            {
               if(_loc2_ == data.id)
               {
                  if(GlobalData.$userGuild.GuildList.data.association_info.level <= obj[_loc2_])
                  {
                     if(this.stage)
            {
               this.onCLOSE_PANEL_SELF();
            }
                     GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90781),true);
                     return;
                  }
               }
            }
            if(GlobalData.$userData.attrs.guild_contribute < level.up_demand)
            {
               this.onCLOSE_PANEL_SELF();
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90768),true);
               return;
            }
         }
         else
         {
            SendServiceAMFFun.send_user_guild_graduate_skill_up(reGraduateSkill,{"skill_id":data.id});
         }
      }
      
      private function reGraduateSkill(param1:Object) : void
      {
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            return;
         }
         var _loc2_:Object = null;
         var _loc3_:Object = null;
         var _loc4_:String = "combatWin";
         SoundManager.getOnlyExample().playSound(_loc4_);
         if(param1.data)
         {
            _loc2_ = param1.data.user_data;

            _loc3_ = GlobalFunction.getAwardByType("guild_skill",data.icon);
            GlobalFunction.popAward("guild_skill",GlobalLanguageStr.getLanguageStr(90794),data.icon,false);
            obj = GlobalData.$userData.attrs.guild_graduate_skill;
            for(var _loc5_ in obj)
            {
               if(_loc5_ == data.id)
               {
                  nowLv = obj[_loc5_];
                  nextLv = obj[_loc5_] + 1;
                  level = data.level[nextLv];
               }
            }
            if(this.stage)
            {
               if(nowLv < 10)
               {
                  m_info.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90774,level.up_demand,data.name,nowLv,nextLv),GlobalTextStyle.COLOR_W_B_Y_O,21,20,false,"center");
               }
               if(nowLv < 10 && GlobalData.$userData.attrs.guild_contribute < level.up_demand)
               {
                  upBtn.enabled = false;
               }
               this.onCLOSE_PANEL_SELF();
            }
            GlobalData.$mEventDispatcher.dispatchEventWith("updata_guild_contribute",false,{"guild_contribute":GlobalData.$userData.attrs.guild_contribute});
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_update",false,_loc2_);
         }
      }
   }
}

