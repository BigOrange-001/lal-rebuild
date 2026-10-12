package com.meng52.game.ui.element
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.controls.renderers.IListItemRenderer;
   import feathers.display.Scale9Image;
   import feathers.textures.Scale9Textures;
   import flash.geom.Rectangle;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   
   public class ItemGuildPanel extends ItemBase implements IListItemRenderer
   {
      
      private var mBox_UIs:Sprite;
      
      private var playerName:TextField;
      
      private var playerLV:TextField;
      
      private var playerPost:TextField;
      
      private var btn_esc:LOL_Scale9Button;
      
      private var worshipBtn:LOL_Scale9Button;
      
      private var flag:uint = 0;
      
      private var mVip:Image;
      
      private var quad:Quad;
      
      private var memberWorshipObj:Object;
      
      private var memberWorshipNum:int;
      
      private var memberWorshipArr:Array;
      
      public function ItemGuildPanel()
      {
         super();
      }
      
      override public function layoutWH() : void
      {
         this.width = this.height = 104;
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(mBox_UIs)
         {
            mBox_UIs.removeFromParent(true);
            mBox_UIs.dispose();
         }
         if(playerName)
         {
            playerName.removeFromParent(true);
            playerName.dispose();
         }
         if(playerLV)
         {
            playerLV.removeFromParent(true);
            playerLV.dispose();
         }
         if(playerPost)
         {
            playerPost.removeFromParent(true);
            playerPost.dispose();
         }
         if(btn_esc)
         {
            btn_esc.removeFromParent(true);
            btn_esc.dispose();
         }
         if(worshipBtn)
         {
            worshipBtn.removeFromParent(true);
            worshipBtn.dispose();
         }
         if(mVip)
         {
            mVip.removeFromParent(true);
            mVip.dispose();
         }
         if(quad)
         {
            quad.removeFromParent(true);
            quad.dispose();
         }
         mBox_UIs = null;
         playerName = null;
         playerLV = null;
         playerPost = null;
         btn_esc = null;
         worshipBtn = null;
         mVip = null;
         quad = null;
         StarlingTools.removeChildrenClear(this);
         this.clear();
      }
      
      override public function init(param1:Object) : void
      {
         var _loc2_:String = null;
         var _loc4_:int = 0;
         memberWorshipNum = GlobalData.$mGuild_simple.member_worship_times;
         memberWorshipObj = param1.worship_info;
         memberWorshipArr = memberWorshipObj.member_worship_user_list;
         if(GlobalData.$userData.uid == param1.uid && GlobalData.$userData.zone == param1.zone)
         {
            flag = 1;

         }
         mBox_UIs = new Sprite();
         addChild(mBox_UIs);
         var _loc3_:Scale9Textures = new Scale9Textures(GlobalFunction.getTexture("UI_guildShop_bg_3_0000"),new Rectangle(30,30,50,50));
         this.mScale9Image = new Scale9Image(_loc3_);
         this.mScale9Image.width = 585;
         this.mScale9Image.height = 95;
         mBox_UIs.addChild(this.mScale9Image);
         this.width = mScale9Image.width;
         this.height = mScale9Image.height - 5;
         playerName = GlobalTextStyle.getTextField(param1.name,20,1513239,"left",300,46);
         playerName.x = playerName.y + 20;
         playerName.y = mScale9Image.height / 2 - playerName.height / 2 + 5;
         this.addChild(playerName);
         playerLV = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20514,param1.lv),20,1513239,"left",300,46);
         playerLV.x = playerName.x + 175;
         playerLV.y = playerName.y;
         this.addChild(playerLV);
         mVip = GlobalFunction.getVipImg(data.vip_lv,data.uid);
         mVip.visible = GlobalFunction.checkIOSvip();
         mVip.x = playerLV.x + 135;
         mVip.y = playerLV.y + 20;
         this.addChild(this.mVip);
         switch(param1.association_lv)
         {
            case 0:
               _loc2_ = GlobalLanguageStr.getLanguageStr(97082);
               break;
            case 1:
               _loc2_ = GlobalLanguageStr.getLanguageStr(97083);
               break;
            case 2:
               _loc2_ = "长老";
               break;
            case 3:
               _loc2_ = "";
         }
         playerPost = GlobalTextStyle.getTextField(_loc2_,20,1513239,"left",300,46);
         this.addChild(playerPost);
         playerPost.x = mVip.x + 50;
         playerPost.y = playerLV.y;
         if(flag && param1.association_lv != 0 && GlobalData.$userData.uid == param1.uid && GlobalData.$userData.zone == param1.zone)
         {
            setFunBtnUI(GlobalLanguageStr.getLanguageStr(97732),true,"UI_btn_guild_2_red_0000");
         }
         else
         {
            setFunBtnUI(GlobalLanguageStr.getLanguageStr(97733),true,"UI_btn_guild_2_0000");
         }
         _loc4_ = 0;
         while(_loc4_ < memberWorshipArr.length)
         {
            if(memberWorshipArr[_loc4_] == param1.uid)
            {
               setFunBtnUI(GlobalLanguageStr.getLanguageStr(97937),true,"UI_btn_guild_2_0000");
               worshipBtn.enabled = false;
            }
            _loc4_++;
         }
         quad = Tools.newQuad(445,85,this.mScale9Image.x + 8,this.mScale9Image.y + 5,0);
         quad.alpha = 0;
         addChild(quad);
         quad.addEventListener("touch",onTouch);
      }
      
      public function setFunBtnUI(param1:String, param2:Boolean = true, param3:String = "UI_btn_guild_2_0000") : void
      {
         if(worshipBtn)
         {
            worshipBtn.removeEventListener("triggered",onWorshipBtn);
            worshipBtn.removeFromParent(true);
            worshipBtn.dispose();
            worshipBtn = null;
         }
         worshipBtn = new LOL_Scale9Button(param1,115,60,param3,true,false);
         worshipBtn.fontSize = 22;
         worshipBtn.fontColor = 16777215;
         worshipBtn.x = mScale9Image.width - worshipBtn.width - 16;
         worshipBtn.y = mScale9Image.height / 2 - 29;
         addChild(worshipBtn);
         worshipBtn.addEventListener("triggered",onWorshipBtn);
         if(_data.association_lv == 0 && GlobalData.$userData.uid == _data.uid && GlobalData.$userData.zone == _data.zone)
         {
            worshipBtn.visible = false;
         }
         if(memberWorshipObj.member_worship_count >= memberWorshipNum && worshipBtn.text == GlobalLanguageStr.getLanguageStr(97733) || _data.lv <= GlobalData.$userData.lv && worshipBtn.text == GlobalLanguageStr.getLanguageStr(97733))
         {
            worshipBtn.enabled = false;
         }
      }
      
      private function onWorshipBtn(param1:Event) : void
      {
         var fun:Object;
         var _eve:Event = param1;
         var sendService:* = function():void
         {
            GlobalData.$mGameClassObject.closePopUp();
            SendServiceAMFFun.send_user_exit_association(onRe,{});
         };
         var _cfg:Object = GlobalData.$mGuild_simple.the_guild_info;
         var penaltyTime:String = _cfg.exit_guild_punish;
         var punishMoney:Number = Number(_cfg.punish_money);
         var i:int = 0;
         while(i < memberWorshipArr.length)
         {
            if(memberWorshipArr[i] == _data.uid)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97938),true);
               return;
            }
            i = i + 1;
         }
         if(worshipBtn.text == GlobalLanguageStr.getLanguageStr(97732))
         {
            fun = {
               "ok":sendService,
               "okA":["Pop"],
               "no":GlobalFunction.functionNull,
               "aid":"A_1001_3"
            };
            GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(97732),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97825,penaltyTime,Math.round(GlobalData.$userData.attrs.association_gold * punishMoney)),GlobalTextStyle.COLOR_W_Y_Y_G,24),fun,true,null,false,true);
         }
         if(worshipBtn.text == GlobalLanguageStr.getLanguageStr(97733) && memberWorshipObj.member_worship_count < memberWorshipNum)
         {
            if(_data.lv <= GlobalData.$userData.lv)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97822),true);
               return;
            }
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_member_worship",false,true,data);
         }
         if(memberWorshipObj.member_worship_count >= memberWorshipNum && worshipBtn.text == GlobalLanguageStr.getLanguageStr(97733))
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97801),true);
            return;
         }
      }
      
      private function onRe(param1:Object) : void
      {
         if(param1.data)
         {
            if(param1.data.res_code == 1)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97821),true);
               GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{
                  "flag":4,
                  "uid":data.uid,
                  "zone":data.zone
               });
               return;
            }
            if(param1.data.res_code == -1)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97835),true);
               GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{
                  "flag":4,
                  "uid":data.uid,
                  "zone":data.zone
               });
               return;
            }
            if(param1.data.res_code == -2)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97923),true);
               GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
            }
         }
      }
      
      private function onTouch(param1:TouchEvent) : void
      {
         var _loc3_:List = this.parent.parent as List;
         if(_loc3_ && _loc3_.isScrolling)
         {
            return;
         }
         var _loc2_:Touch = param1.getTouch(this);
         if(_loc2_ && _loc2_.phase == "ended")
         {
            if(GlobalData.$userData.uid == _data.uid && GlobalData.$userData.zone == _data.zone)
            {
               return;
            }
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_guild_user_setting",false,true,_data);
         }
      }
   }
}

