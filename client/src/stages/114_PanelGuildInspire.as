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
   
   public class PanelGuildInspire extends PanelCenterMainAvatar
   {
      
      private var btn_GuildAdd:LOL_Scale9Button;
      
      private var btn_HeartenRecord:LOL_Scale9Button;
      
      private var btn_OWTeam:LOL_Scale9Button;
      
      private var btn_Hearten:LOL_Scale9Button;
      
      private var data:Object;
      
      public function PanelGuildInspire(param1:Object)
      {
         data = param1;
         super();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(btn_GuildAdd)
         {
            btn_GuildAdd.removeFromParent(true);
            btn_GuildAdd.dispose();
         }
         if(btn_HeartenRecord)
         {
            btn_HeartenRecord.removeFromParent(true);
            btn_HeartenRecord.dispose();
         }
         if(btn_OWTeam)
         {
            btn_OWTeam.removeFromParent(true);
            btn_OWTeam.dispose();
         }
         if(btn_Hearten)
         {
            btn_Hearten.removeFromParent(true);
            btn_Hearten.dispose();
         }
         btn_GuildAdd = null;
         btn_HeartenRecord = null;
         btn_OWTeam = null;
         btn_Hearten = null;
         StarlingTools.removeChildrenClear(this);
         this.clear();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(97976),500,420,true);
         setUI();
      }
      
      private function setUI() : void
      {
         btn_Hearten = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(97962),190,64,"UI_btn_guild_4_0000");
         btn_Hearten.fontColor = 16777215;
         btn_Hearten.fontSize = 23;
         btn_Hearten.name = "hearten";
         this.addChild(btn_Hearten);
         btn_Hearten.x = mImg9_baseBg.x + mImg9_baseBg.width / 2 - btn_Hearten.width / 2;
         btn_Hearten.y = btn_Hearten.height + 60;
         btn_Hearten.addEventListener("triggered",onBM);
         btn_GuildAdd = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(97977),190,64,"UI_btn_guild_4_0000");
         btn_GuildAdd.fontColor = 16777215;
         btn_GuildAdd.fontSize = 23;
         btn_GuildAdd.name = "add";
         this.addChild(btn_GuildAdd);
         btn_GuildAdd.x = btn_Hearten.x;
         btn_GuildAdd.y = btn_Hearten.y + btn_Hearten.height + 10;
         btn_GuildAdd.addEventListener("triggered",onBM);
         btn_HeartenRecord = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(97978),190,64,"UI_btn_guild_4_0000");
         btn_HeartenRecord.fontColor = 16777215;
         btn_HeartenRecord.fontSize = 23;
         btn_HeartenRecord.name = "record";
         this.addChild(btn_HeartenRecord);
         btn_HeartenRecord.x = btn_GuildAdd.x;
         btn_HeartenRecord.y = btn_GuildAdd.y + btn_GuildAdd.height + 10;
         btn_HeartenRecord.addEventListener("triggered",onBM);
         btn_OWTeam = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(97979),190,64,"UI_btn_guild_4_0000");
         btn_OWTeam.fontColor = 16777215;
         btn_OWTeam.fontSize = 23;
         btn_OWTeam.name = "team";
         this.addChild(btn_OWTeam);
         btn_OWTeam.x = btn_GuildAdd.x;
         btn_OWTeam.y = btn_HeartenRecord.y + btn_HeartenRecord.height + 10;
         btn_OWTeam.addEventListener("triggered",onBM);
         if(!data.isBM)
         {
            btn_OWTeam.enabled = false;
         }
         if(data.jie == 5 || data.jie == 6)
         {
            btn_Hearten.enabled = false;
         }
      }
      
      private function onBM(param1:Event) : void
      {
         var arr:Array;
         var thisNum:int;
         var _fun:Object;
         var str:String;
         var _fun1:Object;
         var refreshService:*;
         var e:Event = param1;
         var showpanel:* = function():void
         {
         };
         var b:LOL_Scale9Button = e.currentTarget as LOL_Scale9Button;
         switch(b.name)
         {
            case "hearten":
               var _inspirePanel:PanelGuildInspire = this;
               refreshService = function():void
               {
                  var _beforeInspire:Object = {"vip_lv":GlobalData.$userData.vip_lv,"association_gold":GlobalData.$userData.attrs.association_gold};
                  SendServiceAMFFun.send_user_inspire_association_race(function(_receipt:Object):void
                  {
                     _receipt._extendedABefore = _beforeInspire;
                     _inspirePanel.onReGuWu(_receipt);
                  },{});
               };
               if(!btn_Hearten.enabled)
               {
                  GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(97981));
                  return;
               }
               arr = GlobalData.$mGuild_simple.the_guild_pvp.inspire.use_coin;
               if(data.num == 0)
               {
                  thisNum = int(arr[0]);
               }
               else
               {
                  thisNum = arr[1] * Math.pow(arr[2],data.num - 1) + arr[4] + arr[3] * (data.num - 1);
               }
               thisNum = Math.ceil(thisNum);
               if(GlobalData.$userData.coin < thisNum)
               {
                  _fun = {
                     "ok":gotoCoin,
                     "no":GlobalFunction.functionNull,
                     "aid":"A_2009_5"
                  };
                  str = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90051,thisNum),GlobalTextStyle.COLOR_W_Y_Y_G);
                  GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(90010),str,_fun);
                  return;
               }
               if(data.num == 0)
               {
                  _fun1 = {
                     "ok":refreshService,
                     "okA":["Pop"],
                     "no":GlobalFunction.functionNull
                  };
                  GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97994),GlobalTextStyle.COLOR_W_B_Y_O),_fun1,true,null,false,true);
               }
               else
               {
                  _fun1 = {
                     "ok":refreshService,
                     "okA":["Pop"],
                     "no":GlobalFunction.functionNull
                  };
                  GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97975,data.num + 1,thisNum,GlobalData.$mGuild_simple.the_guild_pvp.inspire["gift"]["guild_currency"]),GlobalTextStyle.COLOR_W_B_Y_O),_fun1,true,null,false,true);
               }
               break;
            case "add":
               SendServiceAMFFun.send_user_get_inspire_data(reData,{});
               break;
            case "record":
               SendServiceAMFFun.send_user_get_inspire_history(onRecord,{});
               break;
            case "team":
               if(btn_OWTeam.enabled)
               {
                  SendServiceAMFFun.send_user_get_inspire_team(onTeamRe,{});
               }
               else
               {
                  GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(97989));
               }
         }
      }
      
      private function gotoCoin() : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_pay",false,true);
      }
      
      private function onRecord(param1:Object) : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_guild_hearten_record",false,true,param1);
      }
      
      private function onTeamRe(param1:Object) : void
      {
         var _loc2_:Object = null;
         if(param1.data.team)
         {
            _loc2_ = {};
            _loc2_.id = param1.data.team.uid;
            _loc2_.lv = param1.data.team.lv;
            _loc2_.name = param1.data.team.name;
            _loc2_.data_base = param1.data.team.data;
            GlobalData.$pvp_rival = _loc2_;
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_change_pvp",false,true);
         }
      }
      
      private function reData(param1:Object) : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_guild_add",false,true,param1);
      }
      
      private function onReGuWu(param1:Object) : void
      {
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            return;
         }
         if(param1.data == null || param1.data.inspire_data == null || param1.data.inspire == null || param1.data.inspire.type == null)
         {
            if(this.stage)
            {
               GlobalFunction.popAlert("","该多人鼓舞功能暂未开放。");
            }
            return;
         }
         if(param1.data.jie)
         {
            if(param1.data.jie != 4)
            {
               if(this.stage)
               {
                  GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(97995));
                  btn_Hearten.enabled = false;
               }
               return;
            }
         }
         var _loc4_:Object = {"data":{}};
         _loc4_.data["inspire"] = param1.data.inspire_data;
         GlobalData.$userGuild.GuildFightInspire = _loc4_;
         if(GlobalFunction.didApplyProfileStateSync(param1) && param1._extendedABefore != null && int(param1.data.vip_lv) > int(param1._extendedABefore.vip_lv) && int(param1.data.vip_lv) == int(GlobalData.$userData.vip_lv))
         {
            GlobalFunction.popAward("_$vip$_",GlobalLanguageStr.getLanguageStr(20203,param1.data.vip_lv),param1.data.vip_lv);
         }



         GlobalFunction.updateVip();
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
         if(!this.stage)
         {
            return;
         }
         data.num += 1;
         var _loc2_:uint = 0;
         if(GlobalData.$userData.attrs.association_gold)
         {
            if(param1.data.association_gold)
            {
               _loc2_ = param1.data.association_gold - int(param1._extendedABefore.association_gold);

            }
         }
         else if(param1.data.association_gold)
         {
            _loc2_ = uint(param1.data.association_gold);

         }
         var _loc3_:String = "";
         switch(param1.data.inspire.type)
         {
            case "hp":
               _loc3_ = GlobalLanguageStr.getLanguageStr(20283);
               break;
            case "ap":
               _loc3_ = GlobalLanguageStr.getLanguageStr(20284);
               break;
            case "de_ph":
               _loc3_ = GlobalLanguageStr.getLanguageStr(20285);
               break;
            case "de_ma":
               _loc3_ = GlobalLanguageStr.getLanguageStr(20286);
               break;
            case "hit":
               _loc3_ = GlobalLanguageStr.getLanguageStr(30021);
               break;
            case "flee":
               _loc3_ = GlobalLanguageStr.getLanguageStr(30022);
               break;
            case "crit":
               _loc3_ = GlobalLanguageStr.getLanguageStr(30023);
               break;
            case "tough":
               _loc3_ = GlobalLanguageStr.getLanguageStr(30024);
         }
         var _loc5_:String = param1.data.inspire.num1 == 0 ? param1.data.inspire.num2 : (param1.data.inspire.num1 * 100 as Number).toFixed(2) + "%";
         GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97980,_loc2_,_loc3_,_loc5_),[16777215,16764006,16777215,16777215]));
      }
   }
}

