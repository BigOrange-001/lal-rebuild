package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelCenterMainAvatar;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import starling.events.Event;
   
   public class PanelMem_Manage extends PanelCenterMainAvatar
   {
      
      private var appointCDRBtn:LOL_Scale9Button;
      
      private var appointVice_ChairmanBtn:LOL_Scale9Button;
      
      private var removePositionBtn:LOL_Scale9Button;
      
      private var outGuildBtn:LOL_Scale9Button;
      
      private var data:Object;
      
      private var btnName:int;
      
      private var mGuildLv:int;
      
      private var btn:LOL_Scale9Button;
      
      public function PanelMem_Manage(param1:Object)
      {
         data = param1;
         mGuildLv = data.association_lv;
         super();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(appointCDRBtn)
         {
            appointCDRBtn.removeFromParent(true);
            appointCDRBtn.dispose();
         }
         if(appointVice_ChairmanBtn)
         {
            appointVice_ChairmanBtn.removeFromParent(true);
            appointVice_ChairmanBtn.dispose();
         }
         if(removePositionBtn)
         {
            removePositionBtn.removeFromParent(true);
            removePositionBtn.dispose();
         }
         if(outGuildBtn)
         {
            outGuildBtn.removeFromParent(true);
            outGuildBtn.dispose();
         }
         if(btn)
         {
            btn.removeFromParent(true);
            btn.dispose();
         }
         appointCDRBtn = null;
         appointVice_ChairmanBtn = null;
         removePositionBtn = null;
         outGuildBtn = null;
         btn = null;
         StarlingTools.removeChildrenClear(this);
         this.clear();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(97688),480,420,true);
         appointCDRBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(97698),180,70,"UI_btn_guild_4_0000");
         appointCDRBtn.name = "0";
         appointCDRBtn.fontSize = 22;
         appointCDRBtn.fontColor = 16777215;
         this.addChild(appointCDRBtn);
         appointCDRBtn.x = mImg9_baseBg.x + mImg9_baseBg.width / 2 - appointCDRBtn.width / 2;
         appointCDRBtn.y = appointCDRBtn.height + 30;
         appointCDRBtn.addEventListener("triggered",onClick_GuildBtn);
         appointVice_ChairmanBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(97699),180,70,"UI_btn_guild_4_0000");
         appointVice_ChairmanBtn.name = "1";
         appointVice_ChairmanBtn.fontSize = 22;
         appointVice_ChairmanBtn.fontColor = 16777215;
         this.addChild(appointVice_ChairmanBtn);
         appointVice_ChairmanBtn.x = appointCDRBtn.x;
         appointVice_ChairmanBtn.y = appointCDRBtn.y + appointVice_ChairmanBtn.height + 5;
         appointVice_ChairmanBtn.addEventListener("triggered",onClick_GuildBtn);
         removePositionBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(97700),180,70,"UI_btn_guild_4_0000");
         removePositionBtn.name = "3";
         removePositionBtn.fontSize = 22;
         removePositionBtn.fontColor = 16777215;
         this.addChild(removePositionBtn);
         removePositionBtn.x = appointVice_ChairmanBtn.x;
         removePositionBtn.y = appointVice_ChairmanBtn.y + removePositionBtn.height + 5;
         removePositionBtn.addEventListener("triggered",onClick_GuildBtn);
         outGuildBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(97701),180,70,"UI_btn_guild_4_0000");
         outGuildBtn.name = "-1";
         outGuildBtn.fontSize = 22;
         outGuildBtn.fontColor = 16777215;
         this.addChild(outGuildBtn);
         outGuildBtn.x = removePositionBtn.x;
         outGuildBtn.y = removePositionBtn.y + outGuildBtn.height + 5;
         outGuildBtn.addEventListener("triggered",onClick_GuildBtn);
         if(GlobalData.$userData.attrs.association_lv > 1)
         {
            appointCDRBtn.enabled = false;
            appointVice_ChairmanBtn.enabled = false;
            removePositionBtn.enabled = false;
            outGuildBtn.enabled = false;
         }
         if(mGuildLv == 0)
         {
            appointCDRBtn.enabled = false;
            appointVice_ChairmanBtn.enabled = false;
            removePositionBtn.enabled = false;
            outGuildBtn.enabled = false;
         }
         if(GlobalData.$userData.attrs.association_lv == 1)
         {
            if(GlobalData.$userData.uid == data.uid || mGuildLv == 0)
            {
               appointCDRBtn.enabled = false;
               appointVice_ChairmanBtn.enabled = false;
               removePositionBtn.enabled = false;
               outGuildBtn.enabled = false;
            }
            else
            {
               appointCDRBtn.enabled = false;
               appointVice_ChairmanBtn.enabled = false;
               removePositionBtn.enabled = false;
            }
         }
      }
      
      private function onClick_GuildBtn(param1:Event) : void
      {
         var _loc4_:Object = null;
         var _loc7_:* = 0;
         btn = param1.currentTarget as LOL_Scale9Button;
         btnName = int(btn.name);
         var _loc6_:String = GlobalData.$userData.uid;
         var _loc5_:String = GlobalData.$userData.zone;
         var _loc3_:Array = GlobalData.$userGuild.GuildList.data.member_list;
         var _loc2_:Boolean = false;
         _loc7_ = 0;
         while(_loc7_ < _loc3_.length)
         {
            if(_loc3_[_loc7_].association_lv == 1)
            {
               _loc2_ = true;
            }
            _loc7_++;
         }
         if(mGuildLv == 0)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97819),true);
            return;
         }
         if(GlobalData.$userData.attrs.association_lv == 1)
         {
            if(GlobalData.$userData.uid == data.uid || mGuildLv == 0)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97819),true);
               return;
            }
            if(btnName == 0 || btnName == 1 || btnName == 3)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97819),true);
               return;
            }
         }
         if(GlobalData.$userData.attrs.association_lv > 1)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97819),true);
            return;
         }
         if(_loc6_ != data.uid || _loc5_ != data.zone)
         {
            switch(btnName - -1)
            {
               case 0:
                  _loc4_ = {
                     "ok":sendService,
                     "no":GlobalFunction.functionNull
                  };
                  GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(97701),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97747,data.name),GlobalTextStyle.COLOR_W_Y_Y_G),_loc4_,true,null,false,true);
                  break;
               case 1:
                  _loc4_ = {
                     "ok":sendService,
                     "no":GlobalFunction.functionNull
                  };
                  GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(97698),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97746,data.name),GlobalTextStyle.COLOR_W_Y_Y_G),_loc4_,true,null,false,true);
                  break;
               case 2:
                  if(_loc2_)
                  {
                     GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97823),true);
                     return;
                  }
                  _loc4_ = {
                     "ok":sendService,
                     "no":GlobalFunction.functionNull
                  };
                  GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(97699),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97752,data.name),GlobalTextStyle.COLOR_W_Y_Y_G),_loc4_,true,null,false,true);
                  break;
               case 4:
                  _loc4_ = {
                     "ok":sendService,
                     "no":GlobalFunction.functionNull
                  };
                  GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(97700),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97748,data.name),GlobalTextStyle.COLOR_W_Y_Y_G),_loc4_,true,null,false,true);
            }
         }
      }
      
      private function sendService() : void
      {
         SendServiceAMFFun.send_user_modify_association(onRe,{
            "zone":data.zone,
            "uid":data.uid,
            "num":btnName
         });
      }
      
      private function onRe(param1:Object) : void
      {
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            return;
         }
         if(param1.data)
         {
            if(param1.data.res_code == 1)
            {
               switch(btnName - -1)
               {
                  case 0:
                     GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97751,data.name),true);
                     break;
                  case 1:

                     GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97749,data.name),true);
                     GlobalData.$mEventDispatcher.dispatchEventWith("updata_manager",false,data);
                     break;
                  case 2:
                     GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97753,data.name),true);
                     break;
                  case 4:
                     GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97750,data.name),true);
               }
               GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{
                  "flag":2,
                  "zone":data.zone,
                  "uid":data.uid,
                  "num":btnName
               });
               GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_friend_list",false,{
                  "zone":data.zone,
                  "uid":data.uid,
                  "num":btnName,
                  "boo":1
               });
            }
            else if(param1.data.res_code == -1)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97835),true);
               GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
            }
            else if(param1.data.res_code == -2)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97819),true);
            }
            else
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97999),true);
               GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_friend_list",false,{
                  "zone":data.zone,
                  "uid":data.uid,
                  "num":-1,
                  "boo":1
               });
            }
            if(this.stage)
            {
               this.onCLOSE_PANEL_SELF();
            }
         }
      }
   }
}

