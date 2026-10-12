package com.meng52.game.ui.element
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.equip.Equip;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.controls.renderers.IListItemRenderer;
   import flash.geom.Rectangle;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   import starling.utils.deg2rad;
   
   public class ItemExchange extends ItemBase implements IListItemRenderer
   {
      
      private var mEquipUI:Image;
      
      private var mVip:Image;
      
      private var mBtn_to:LOL_Scale9Button;
      
      private var mBox_UIs:Sprite;
      
      private var mName:String;
      
      public function ItemExchange()
      {
         super();
      }
      
      override public function layoutWH() : void
      {
         if(!this.mScale9Image)
         {
         }
         tweenX();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         this.removeEventListener("touch",onTOUCH_ui);
         if(mBox_UIs)
         {
            mBox_UIs.unflatten();
            StarlingTools.removeChildrenClear(mBox_UIs);
         }
         if(mBtn_to)
         {
            mBtn_to.removeEventListener("triggered",onTRIGGERED_to);
            mBtn_to.removeFromParent(true);
         }
         if(mEquipUI)
         {
            mEquipUI.removeFromParent(true);
         }
         if(mVip)
         {
            mVip.removeFromParent(true);
         }
         this.clear();
         mBox_UIs = null;
         mBtn_to = null;
         mEquipUI = null;
      }
      
      override public function init(param1:Object) : void
      {
         var _loc10_:Equip = null;
         var _loc3_:TextField = null;
         var _loc7_:Rectangle = null;
         var _loc16_:Image = null;
         var _loc6_:Image = null;
         var _loc18_:TextField = null;
         var _loc11_:Image = null;
         var _loc9_:Number = NaN;
         var _loc8_:Number = NaN;
         var _loc4_:TextField = null;
         var _loc21_:Boolean = this.data["indexID_s"] == "equip";
         mBox_UIs = new Sprite();
         addChild(mBox_UIs);
         var _loc17_:Boolean = Boolean(param1["status"]);
         var _loc5_:int = int(param1["medal"]);
         var _loc19_:int = int(param1["medal_old"]);
         var _loc2_:Boolean = GlobalData.$userData.medal >= _loc5_;
         this.mScale9Image = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",480,100,new Rectangle(110,55,70,20));
         mScale9Image.y = 5;
         mBox_UIs.x = 100;
         mBox_UIs.addChild(this.mScale9Image);
         this.width = this.mScale9Image.width + 100;
         this.height = this.mScale9Image.height + 10;
         var _loc20_:Number = this.mScale9Image.width * 0.5;
         var _loc13_:TextField = null;
         var _loc15_:TextField = null;
         var _loc22_:String = "";
         mBtn_to = new LOL_Scale9Button(GlobalLanguageStr.getStr(20459),110,47,"UI_btn_enterGame_0_0000");
         addChild(mBtn_to);
         mBtn_to.x = this.mScale9Image.x + this.mScale9Image.width - 30;
         mBtn_to.y = _loc21_ ? mScale9Image.y + mScale9Image.height - mBtn_to.height - 15 + 2 : mScale9Image.y + (mScale9Image.height - mBtn_to.height + 25) * 0.5;
         mBtn_to.addEventListener("triggered",onTRIGGERED_to);
         var _loc12_:Boolean = false;
         if(_loc19_ > 0)
         {
            _loc12_ = true;
         }
         if(_loc17_)
         {
            this.setAvatar(param1["id"]);
            mBox_UIs.addChild(this.mAvatar);
            _loc22_ = this.mAvatarData.avatarData.name;
            this.mAvatar.x = -100;
         }
         else
         {
            _loc10_ = new Equip(param1["id"]);
            this.mEquipUI = GlobalFunction.getEquipUI(_loc10_.equipData.res);
            mBox_UIs.addChild(this.mEquipUI);
            _loc22_ = _loc10_.equipData.name;
            this.mEquipUI.x = -100;
            this.mEquipUI.y = 5;
            if(param1["status_vip"] > 0)
            {
               _loc3_ = GlobalFunction.createTextField(200,40,GlobalLanguageStr.getStr(90388),"",16,1118481);
               _loc3_.visible = GlobalFunction.checkIOSvip();
               _loc3_.x = MainConfig.$isEnglish ? this.mScale9Image.x + mScale9Image.width - _loc3_.width - 16 : this.mScale9Image.x + mScale9Image.width - _loc3_.width - 13;
               _loc3_.y = 10;
               mBox_UIs.addChild(_loc3_);
               mVip = GlobalFunction.getVipImg(param1["status_vip"]);
               mBox_UIs.addChild(this.mVip);
               mVip.visible = GlobalFunction.checkIOSvip();
               mVip.x = this.mScale9Image.x + mScale9Image.width - mVip.width + 18;
               mVip.y = 30;
            }
            else
            {
               mBtn_to.y = mScale9Image.y + (mScale9Image.height - mBtn_to.height) * 0.5;
            }
         }
         mName = _loc22_;
         var _loc14_:Image = GlobalFunction.createImage("UI_exchange_icon_0_0000");
         _loc14_.scaleX = _loc14_.scaleY = 0.9;
         _loc14_.x = this.mScale9Image.x + 50 + this.mScale9Image.width * 0.5;
         _loc14_.y = (this.mScale9Image.height - _loc14_.height) * 0.5 + 20;
         mBox_UIs.addChild(_loc14_);
         _loc15_ = GlobalTextStyle.getTextField(_loc22_,20,1118481,"left",_loc20_,35);
         _loc15_.x = this.mScale9Image.x + 30;
         _loc15_.y = 18;
         mBox_UIs.addChild(_loc15_);
         if(_loc12_)
         {
            _loc13_ = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20322,_loc19_),20,4926491,"left",_loc20_,35);
            _loc13_.x = _loc15_.x;
            _loc13_.y = _loc15_.y + 25;
            _loc16_ = GlobalFunction.createImage("UI_exchange_icon_0_0000");
            _loc16_.scaleX = _loc16_.scaleY = 0.5;
            _loc7_ = _loc13_.textBounds;
            _loc16_.x = _loc13_.x + _loc7_.width + 5;
            _loc16_.y = _loc13_.y + 2;
            mBox_UIs.addChild(_loc16_);
            _loc6_ = GlobalFunction.createImage("UI_sale_bg_2_0002");
            _loc6_.x = this.mScale9Image.x + 15 + (this.mScale9Image.width - _loc6_.width) * 0.5;
            _loc6_.scaleX = _loc6_.scaleY = 0.8;
            _loc6_.y = (this.mScale9Image.height - _loc6_.height) * 0.5;
            mBox_UIs.addChild(_loc6_);
            _loc18_ = GlobalTextStyle.getTextField(_loc5_.toString(),30,8257792,"center",_loc20_,35);
            _loc18_.pivotX = _loc20_ * 0.5;
            _loc18_.pivotY = 35 * 0.5;
            _loc18_.rotation = deg2rad(-15);
            _loc18_.x = int(_loc6_.x + _loc6_.width * 0.5 - 2);
            _loc18_.y = int(_loc6_.y + _loc6_.height * 0.5 + 10);
            mBox_UIs.addChild(_loc18_);
            _loc11_ = GlobalFunction.createImage("UI_bg_vip_buy_3_0000");
            _loc11_.width = _loc7_.width;
            _loc11_.x = _loc13_.x + 3;
            _loc11_.y = _loc13_.y + 13;
            mBox_UIs.addChild(_loc13_);
            mBox_UIs.addChild(_loc11_);
            _loc9_ = SendAndSelect.$systemTimer_nowSecond;
            _loc8_ = Number(param1["sort_3"] == -1 ? param1["end_time"] : param1["end_time"] - _loc9_);
            _loc4_ = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20301,Tools.timeFormatToDate(_loc8_,false)),20,10027008,"left",_loc20_,24);
            _loc4_.x = _loc13_.x;
            _loc4_.y = _loc13_.y + 25;
            mBox_UIs.addChild(_loc4_);
         }
         else
         {
            _loc13_ = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20302,_loc5_),20,4926491,"right",_loc20_,46);
            _loc13_.x = _loc14_.x - _loc20_ - 15;
            _loc13_.y = _loc15_.y + 24;
            mBox_UIs.addChild(_loc13_);
         }
         if(mBox_UIs)
         {
            mBox_UIs.flatten();
         }
         this.addEventListener("touch",onTOUCH_ui);
      }
      
      private function onTOUCH_ui(param1:TouchEvent) : void
      {
         var _loc3_:List = this.parent.parent as List;
         if(_loc3_.isScrolling)
         {
            return;
         }
         var _loc2_:Touch = null;
         if(mAvatar)
         {
            _loc2_ = param1.getTouch(mAvatar,"ended");
            if(_loc2_)
            {
               GlobalFunction.setDetaiAvatar({"id":data["id"]},true);
               return;
            }
         }
         else if(mEquipUI)
         {
            _loc2_ = param1.getTouch(mEquipUI,"ended");
            if(_loc2_)
            {
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panelequipattrs",false,true,data);
            }
         }
      }
      
      private function onTRIGGERED_to(param1:Event) : void
      {
         var _loc2_:int = 0;
         if(GlobalData.$userData.medal >= data["medal"])
         {
            if(data["indexID_s"] != "avatar")
            {
               _loc2_ = Tools.getElementNum(GlobalData.$userData.my_equips);
               if(GlobalData.$userData.vip_lv < data["status_vip"])
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90281,data["status_vip"]));
                  return;
               }
               if(_loc2_ >= GlobalData.$mConfig_simple.equip_config[0])
               {
                  GlobalFunction.popEquipFull();
                  return;
               }
            }
            else
            {
               GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
               if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
               {
                  GlobalFunction.popAvatarLen();
                  return;
               }
            }
            GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90125,data["medal"],mName),GlobalTextStyle.COLOR_W_Y_Y_G),{
               "ok":sendService,
               "no":GlobalFunction.functionNull
            });
         }
         else
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90106));
         }
      }
      
      private function sendService() : void
      {
         SendServiceAMFFun.send_user_medal_exchange(re_medal_exchange,{
            "exch_type":data["indexID_s"],
            "exch_id":data["id"],
            "medal":GlobalData.$userData.medal,
            "need_medal":data["medal"]
         });
      }
      
      private function re_medal_exchange(param1:Object) : void
      {
         SoundManager.getOnlyExample().playSound("sound05");
         var _loc3_:Object = param1["params"];
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.medal = param1.data.medal;
            if(_loc3_["exch_type"] == "avatar")
            {
               GlobalData.$userData.avatars = param1.data.avatars;
            }
            else
            {
               GlobalData.$userData.my_equips = param1.data.my_equips;
            }
         }
         GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
         var _loc2_:Object = GlobalFunction.getAwardByType(_loc3_["exch_type"],_loc3_["exch_id"]);
         GlobalFunction.popAward(_loc3_["exch_type"],GlobalLanguageStr.getLanguageStr(90062,_loc2_.msg),_loc3_["exch_id"],false);
         _loc2_ = null;
          if(GlobalData.$mGameClassObject && GlobalData.$mGameClassObject.mLayoutUICenter && GlobalData.$mGameClassObject.mLayoutUICenter.mPanelExchange && GlobalData.$mGameClassObject.mLayoutUICenter.mPanelExchange.stage)
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.mPanelExchange.update();
         }
      }
   }
}

