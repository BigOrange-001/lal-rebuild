package com.meng52.game.ui.element
{
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
   
   public class ItemSoulShop extends ItemBase
   {
      
      private var _ui:DisplayObject;
      
      private var _txt:LOL_TextField;
      
      private var _btn:LOL_Scale9Button;
      
      private var _award:Object;
      
      private var _id:String;
      
      private var _type:String;
      
      public function ItemSoulShop()
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
         var _loc2_:Image = null;
         var _loc6_:Image = null;
         this.mScale9Image = GlobalFunction.createScale9Image("UI_bg_vip_buy_0_0000",285,135,new Rectangle(30,30,58,30));
         this.addChild(this.mScale9Image);
         for(var _loc4_:String in param1.data)
         {
            for(var _loc8_:String in param1.data[_loc4_])
            {
               _id = _loc8_;
            }
            if(_loc4_ == "avatar" || _loc4_ == "avatar_soul" || _loc4_ == "equip" || _loc4_ == "equip_soul")
            {
               _award = GlobalFunction.getAwardByType(_loc4_,param1.data[_loc4_],false,null,"",true,0.8,this.parent.parent as List);
            }
            else
            {
               _award = GlobalFunction.getAwardByType(_loc4_,param1.data[_loc4_],false,null,"",true,1,this.parent.parent as List);
            }
            _ui = _award.ui;
            _ui.x = 25;
            _ui.y = 25;
            addChild(_ui);
         }
         for(var _loc3_:String in param1.pay)
         {
            _type = _loc3_;
            _loc5_ = int(param1.pay[_loc3_]);
         }
         _txt = new LOL_TextField(_award.baseName,140,30);
         _txt.fontColor = 16777215;
         _txt.x = 120;
         _txt.y = _ui.y;
         addChild(_txt);
         var _loc7_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(90583),45,25);
         _loc7_.fontColor = 16777215;
         _loc7_.fontSize = MainConfig.$isEA ? 18 : 20;
         _loc7_.x = 100;
         _loc7_.y = _txt.y + _txt.height + 20;
         addChild(_loc7_);
         _btn = new LOL_Scale9Button("",120,45,"UI_btn_enterGame_0_0000");
         _btn.fontSize = 20;
         _btn.x = 150;
         _btn.y = _txt.y + _txt.height + 10;
         addChild(_btn);
         if(_type == "gold")
         {
            _loc2_ = GlobalFunction.createImage("UI_money_gold_0_0000");
            _btn.text = "　　" + Tools.formateNum(_loc5_);
         }
         else
         {
            _loc2_ = GlobalFunction.createImage("UI_money_coin_0_0000");
            _btn.text = "　　" + Tools.formateNum(_loc5_);
         }
         _btn.name = _loc5_ + "";
         _loc2_.x = _btn.x + 5;
         _loc2_.y = _btn.y + 5;
         _loc2_.touchable = false;
         addChild(_loc2_);
         if(param1["isBuy"] != -1)
         {
            _btn.visible = false;
            _loc2_.visible = false;
            _loc7_.visible = false;
            _loc7_ = new LOL_TextField(GlobalLanguageStr.getLanguageStr(90583),100,40);
            _loc7_.x = _txt.x + 25;
            _loc7_.y = _txt.y + _txt.height + 22;
            _loc7_.text = GlobalLanguageStr.getLanguageStr(90646);
            _loc7_.fontColor = 6475106;
            addChild(_loc7_);
            _loc6_ = GlobalFunction.createImage("UI_select_0_0000");
            _loc6_.x = _loc7_.x + _loc7_.textBounds.width + 10;
            _loc6_.y = _loc7_.y + 7;
            addChild(_loc6_);
         }
         _btn.addEventListener("triggered",btn_Triggered);
      }
      
      private function btn_Triggered(param1:Event) : void
      {
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
         var requestData:Object;
         var awardInfo:Object;
         var awardPayload:Object;
         var e:Event = param1;
         if(!_btn.enabled)
         {
            LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getLanguageStr(90587));
         }
         else
         {
            send = function():void
            {
               requestData = {
                  "s_type":_data["s_type"],
                  "index":_data["index"],
                  "time":_data["time"]
               };
               awardInfo = Tools.clone(_award);
               awardPayload = Tools.clone(_data.data[_award.type]);
               SendServiceAMFFun.send_user_mystery_shop_buy(function(response:Object):void
               {
                  buy(response,awardInfo,awardPayload);
               },requestData);
            };
            p = this.parent.parent as List;
            if(p.isScrolling)
            {
               return;
            }
            price = int(_btn.name);
            type = _type == "gold" ? GlobalLanguageStr.getLanguageStr(20162) : GlobalLanguageStr.getLanguageStr(20149);
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
               str = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90592,Tools.formateNum(price),type,_award.num,_award.baseName,cur,need),[16777215,10066329,16764006,16777215],MainConfig.$isEA ? 25 : 21);
               GlobalFunction.popAlert("",str,{
                  "ok":send,
                  "no":GlobalFunction.functionNull
               });
            }
            else if(_award.type == "avatar" || _award.type == "equip")
            {
               str = GlobalLanguageStr.getLanguageStr(90654,Tools.formateNum(price),type,_award.num,_award.baseName);
               str = Tools.formatLineX(str,GlobalTextStyle.COLOR_W_W_Y_W);
               GlobalFunction.popAlert("",str,{
                  "ok":send,
                  "no":GlobalFunction.functionNull
               });
            }
            else
            {
               str = GlobalLanguageStr.getLanguageStr(90653,Tools.formateNum(price),type,Tools.formateNum(_award.num),_award.baseName);
               str = Tools.formatLineX(str,GlobalTextStyle.COLOR_W_W_Y_W);
               GlobalFunction.popAlert("",str,{
                  "ok":send,
                  "no":GlobalFunction.functionNull
               });
            }
         }
      }
      
      private function buy(param1:Object, param2:Object, param3:Object) : void
      {
         if(!param1.data || !GlobalFunction.isVersionedProfileReceipt(param1))
         {
            return;
         }
         var _loc2_:String = "combatWin";
         SoundManager.getOnlyExample().playSound(_loc2_);
         GlobalFunction.popAward(param2.type,GlobalLanguageStr.getLanguageStr(97515,param2.msg),param3,false);
         GlobalData.$mEventDispatcher.dispatchEventWith("update_soulshop_list",false,{"b":param1.data.b});
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
         StarlingTools.removeChildrenClear(this);
      }
   }
}

