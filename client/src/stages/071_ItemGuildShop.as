package com.meng52.game.ui.element
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.equip.Equip;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import flash.geom.Rectangle;
   import starling.display.DisplayObject;
   import starling.display.Image;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class ItemGuildShop extends ItemBase
   {
      
      private var _ui:DisplayObject;
      
      private var _txt:TextField;
      
      private var _btn:LOL_Scale9Button;
      
      private var _award:Object;
      
      private var _id:String;
      
      private var _type:String;
      
      private var shopType:uint = 10;
      
      private var icon:Image;
      
      private var txt:LOL_TextField;
      
      public function ItemGuildShop()
      {
         super();
      }
      
      override public function layoutWH() : void
      {
         this.width = 285;
         this.height = 135;
         tweenX(false);
      }
      
      override public function init(param1:Object) : void
      {
         var _loc5_:int = 0;
         var _loc7_:TextFieldHtmlRenderer = null;
         var _loc6_:Image = null;
         this.mScale9Image = GlobalFunction.createScale9Image("UI_guildShop_bg_2_0000",290,130,new Rectangle(30,30,58,30));
         this.addChild(this.mScale9Image);
         shopType = param1.s_type;
         for(var _loc4_:String in param1.data)
         {
            for(var _loc8_:String in param1.data[_loc4_])
            {
               _id = _loc8_;
            }
            if(_loc4_ == "avatar" || _loc4_ == "equip")
            {
               _award = GlobalFunction.getAwardByType(_loc4_,param1.data[_loc4_],false,null,"",true,0.8,this.parent.parent as List);
            }
            else if(_loc4_ == "avatar_soul" || _loc4_ == "equip_soul")
            {
               _award = GlobalFunction.getAwardByType(_loc4_,param1.data[_loc4_],false,null,"",true,0.85,this.parent.parent as List);
            }
            else
            {
               _award = GlobalFunction.getAwardByType(_loc4_,param1.data[_loc4_],false,null,"",true,1,this.parent.parent as List);
            }
            _ui = _award.ui;
            if(shopType)
            {
               if(_loc4_ == "avatar_soul" || _loc4_ == "equip_soul")
               {
                  _ui.scaleX = _ui.scaleY = 0.95;
                  _ui.y = int((this.mScale9Image.height - _ui.height) * 0.5 + 10);
               }
               else
               {
                  _ui.y = int((this.mScale9Image.height - _ui.height) * 0.5 + 5);
               }
            }
            else if(_loc4_ == "avatar_soul" || _loc4_ == "equip_soul")
            {
               _ui.scaleX = _ui.scaleY = 0.95;
               _ui.y = int((this.mScale9Image.height - _ui.height) * 0.5 + 10);
            }
            else
            {
               _ui.y = int((this.mScale9Image.height - _ui.height) * 0.5 + 5);
            }
            _ui.x = this.mScale9Image.x + 15;
            addChild(_ui);
         }
         for(var _loc3_:String in param1.pay)
         {
            _type = _loc3_;
            _loc5_ = int(param1.pay[_loc3_]);
         }
         _txt = GlobalTextStyle.getTextField(_award.baseName,20,16764006,"center",160,35);
         _txt.pivotX = _txt.width / 2;
         _txt.pivotY = _txt.height / 2;
         _txt.x = int((this.mScale9Image.width - _ui.width - _txt.width) * 0.5 + 163);
         _txt.y = this.mScale9Image.y + 25;
         addChild(_txt);
         if(param1.need_lv)
         {
            _loc7_ = GlobalTextStyle.getHtmlTextRenderer();
            _loc7_.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97931,param1.need_lv),[16777215,16777215,16777215,16777215],16,16,false,"left");
            _loc7_.x = this.mScale9Image.x + 98;
            _loc7_.y = _txt.y + 20;
            addChild(_loc7_);
         }
         var _loc2_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(98228,param1.buyNum),185,18);
         _loc2_.fontColor = 16777215;
         _loc2_.fontSize = 15;
         _loc2_.x = _ui.x + _ui.width + 20;
         _loc2_.y = _txt.y + 39;
         if(!param1.buyNum)
         {
            _loc2_.visible = false;
         }
         if(shopType)
         {
            _loc2_.text = GlobalLanguageStr.getLanguageStr(97930,param1.buyNum);
            _loc2_.x = _ui.x + _ui.width + 20;
         }
         addChild(_loc2_);
         txt = new LOL_TextField(GlobalLanguageStr.getLanguageStr(90583),100,24);
         txt.fontColor = 16777215;
         txt.fontSize = 17;
         txt.x = _ui.x + _ui.width + 20;
         txt.y = this.mScale9Image.y + (this.mScale9Image.height - 42);
         addChild(txt);
         _btn = new LOL_Scale9Button("",110,48,"UI_btn_guild_3_0000");
         _btn.fontSize = 20;
         _btn.x = txt.x + 60;
         _btn.y = txt.y - 7;
         addChild(_btn);
         if(_type == "gold")
         {
            icon = GlobalFunction.createImage("UI_money_gold_0_0000");
            _btn.text = "　　" + Tools.formateNum(_loc5_);
         }
         else if(_type == "guild_currency")
         {
            icon = GlobalFunction.createImage("UI_money_guild_0_0000");
            _btn.text = "　　" + Tools.formateNum(_loc5_);
         }
         else
         {
            icon = GlobalFunction.createImage("UI_money_coin_0_0000");
            _btn.text = "　　" + Tools.formateNum(_loc5_);
         }
         _btn.name = _loc5_ + "";
         _btn.fontColor = 16777215;
         icon.x = _btn.x + 5;
         icon.y = _btn.y + 5;
         if(_type == "guild_currency")
         {
            icon.x = _btn.x + 7;
            icon.y = _btn.y + 7;
         }
         icon.touchable = false;
         addChild(icon);
         if(param1["isBuy"] != true)
         {
            _btn.visible = false;
            icon.visible = false;
            txt.visible = false;
            txt = new LOL_TextField(GlobalLanguageStr.getLanguageStr(90583),100,40);
            txt.x = _btn.x + 22;
            txt.y = _btn.y;
            txt.text = GlobalLanguageStr.getLanguageStr(90646);
            txt.fontColor = 6475106;
            addChild(txt);
            _loc6_ = GlobalFunction.createImage("UI_select_0_0000");
            _loc6_.x = txt.x + txt.textBounds.width + 10;
            _loc6_.y = txt.y + 7;
            addChild(_loc6_);
         }
         _btn.addEventListener("triggered",btn_Triggered);
      }
      
      private function btn_Triggered(param1:Event) : void
      {
         var _myEquipNum:int;
         var p:List;
         var price:int;
         var type:String;
         var obj:Object;
         var equip_Soul:Object;
         var avatar_Soul:Object;
         var cur:int;
         var need:int;
         var str:String;
         var send:*;
         var e:Event = param1;
         var _b:Boolean = true;
         GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
         _myEquipNum = Tools.getElementNum(GlobalData.$userData.my_equips);
         if(_award.type == "avatar")
         {
            if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
            {
               _b = false;
               GlobalFunction.popAvatarLen();
               return;
            }
         }
         if(_award.type == "equip")
         {
            if(_myEquipNum >= GlobalData.$mConfig_simple.equip_config[0])
            {
               _b = false;
               GlobalFunction.popEquipFull();
               return;
            }
         }
         if(!_btn.enabled)
         {
            LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getLanguageStr(90587));
         }
         else
         {
            send = function():void
            {
               if(_data["s_type"])
               {
                  SendServiceAMFFun.send_user_assocication_guild_shop_buy(buy,{"index":_data["index"]});
               }
               else
               {
                  SendServiceAMFFun.send_user_assocication_sever_shop_buy(buy,{
                     "index_1":_data["index_1"],
                     "index_2":_data["index_2"]
                  });
               }
            };
            p = this.parent.parent as List;
            if(p.isScrolling)
            {
               return;
            }
            if(_data.need_lv > GlobalData.$userGuild.GuildList.data.association_info.level)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97942),false);
               return;
            }
            price = int(_btn.name);
            type = _type == "gold" ? GlobalLanguageStr.getLanguageStr(20162) : (_type == "coin" ? GlobalLanguageStr.getLanguageStr(20149) : "公会币");
            if(_type == "coin")
            {
               if(GlobalData.$userData.coin < price)
               {
                  GlobalFunction.popErrorCoin(price);
                  return;
               }
            }
            if(_type == "gold")
            {
               if(GlobalData.$userData.gold < price)
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10023),false,"A_6999_3");
                  return;
               }
            }
            if(_type == "guild_currency")
            {
               if(GlobalData.$userData.attrs.association_gold < price)
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97921),false);
                  return;
               }
            }
            obj = GlobalData.$mConfig_simple.soul_exchange;
            equip_Soul = GlobalData.$userData.equip_soul;
            avatar_Soul = GlobalData.$userData.avatar_soul;
            cur = 0;
            need = 0;
            if(_award.type == "avatar_soul")
            {
               cur = int(avatar_Soul[_id] != null ? avatar_Soul[_id] : 0);
               need = int(obj.avatar[new Avatar(_id).getStar()]);
            }
            else if(_award.type == "equip_soul")
            {
               cur = int(equip_Soul[_id] != null ? equip_Soul[_id] : 0);
               need = int(obj.avatar[new Equip(_id).getStar()]);
            }
            if(_award.type == "avatar_soul" || _award.type == "equip_soul")
            {
               str = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90592,Tools.formateNum(price),type,_award.num,_award.baseName,cur,need),[16777215,10066329,16764006,16777215],25);
               GlobalFunction.popAlert("",str,{
                  "ok":send,
                  "no":GlobalFunction.functionNull
               },true,null,false,true);
            }
            else if(_award.type == "avatar" || _award.type == "equip")
            {
               str = GlobalLanguageStr.getLanguageStr(90654,Tools.formateNum(price),type,_award.num,_award.baseName);
               str = Tools.formatLineX(str,GlobalTextStyle.COLOR_W_W_Y_W);
               GlobalFunction.popAlert("",str,{
                  "ok":send,
                  "no":GlobalFunction.functionNull
               },true,null,false,true);
            }
            else
            {
               str = GlobalLanguageStr.getLanguageStr(90653,Tools.formateNum(price),type,Tools.formateNum(_award.num),_award.baseName);
               str = Tools.formatLineX(str,GlobalTextStyle.COLOR_W_W_Y_W);
               GlobalFunction.popAlert("",str,{
                  "ok":send,
                  "no":GlobalFunction.functionNull
               },true,null,false,true);
            }
         }
      }
      
      private function buy(param1:Object) : void
      {
         if(this.stage == null) return;
         var _loc2_:String = null;
         if(param1.data.res_code == 1)
         {
            _loc2_ = "combatWin";
            SoundManager.getOnlyExample().playSound(_loc2_);
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.attrs.association_gold = param1.data.association_gold;
            }
            if(param1.data["exp"])
            {
               if(!GlobalFunction.isVersionedProfileReceipt(param1))
               {
               GlobalData.$userData.exp = param1.data.exp;
               }
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.lv = param1.data.lv;
            }
            GlobalFunction.updateExp();
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalFunction.update_UserData(param1.data);
            }
            GlobalFunction.popAward(_award.type,GlobalLanguageStr.getLanguageStr(97515,_award.msg),_data.data[_award.type],false);
            GlobalData.$mEventDispatcher.dispatchEventWith("updata_guild_shop_list");
         }
         if(_data["s_type"])
         {
            if(param1.data.res_code == -1)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97835),true);
               GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
            }
         }
         else
         {
            if(param1.data.res_code == -1)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97835),true);
               GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
            }
            if(param1.data.res_code == -2)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97084),true);
               GlobalData.$mEventDispatcher.dispatchEventWith("updata_guild_shop_list");
            }
         }
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(_ui)
         {
            _ui.removeFromParent();
            _ui = null;
         }
         if(_txt)
         {
            _txt.removeFromParent();
            _txt = null;
         }
         if(_btn)
         {
            _btn.removeFromParent();
            _btn = null;
         }
         if(icon)
         {
            icon.removeFromParent(true);
            icon.dispose();
         }
         if(txt)
         {
            txt.removeFromParent(true);
            txt.dispose();
         }
         icon = null;
         txt = null;
         StarlingTools.removeChildrenClear(this);
      }
   }
}

