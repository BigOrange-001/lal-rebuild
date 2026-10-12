package com.meng52.game.ui.element
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLocalStore;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.Tools;
   import feathers.controls.renderers.IListItemRenderer;
   import feathers.display.Scale9Image;
   import feathers.textures.Scale9Textures;
   import flash.geom.Rectangle;
   import starling.display.Image;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class ItemVIPShopping extends ItemBase implements IListItemRenderer
   {
      
      private var mBtn_buy:LOL_Scale9Button;
      
      private var mBtn_show:LOL_Button;
      
      private var mBg_free:Image;
      
      private var mTxt_info:TextField;
      
      private var mTxt_bugNum:TextField;
      
      private var _currVipLv:int;
      
      private var mBtn_expense:LOL_Button;
      
      private var mBtn_get:LOL_Scale9Button;
      
      private var vipTxt_expense:LOL_TextField;
      
      private var vipImg_expense:Image;
      
      private var info_expense:TextField;
      
      private var lastPrice:TextField;
      
      private var nowPrice:LOL_MutilTextFieldIcon;
      
      private var price:Array;
      
      private var _send_data:Object;
      
      private var mTxt_num:TextField;
      
      public function ItemVIPShopping()
      {
         super();
      }
      
      override public function layoutWH() : void
      {
         if(mScale9Image)
         {
            this.width = mScale9Image.width;
            this.height = mScale9Image.height;
         }
         tweenX();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(mBtn_buy)
         {
            mBtn_buy.removeFromParent(true);
         }
         if(mBtn_show)
         {
            mBtn_show.removeFromParent(true);
         }
         if(mBtn_expense)
         {
            mBtn_expense.removeFromParent(true);
         }
         if(mBtn_get)
         {
            mBtn_get.removeFromParent(true);
         }
         if(vipTxt_expense)
         {
            vipTxt_expense.removeFromParent(true);
         }
         if(vipImg_expense)
         {
            vipImg_expense.removeFromParent(true);
         }
         if(info_expense)
         {
            info_expense.removeFromParent(true);
         }
         if(lastPrice)
         {
            lastPrice.removeFromParent(true);
         }
         if(nowPrice)
         {
            nowPrice.removeFromParent(true);
         }
         if(mTxt_num)
         {
            mTxt_num.removeFromParent(true);
         }
         this.clear();
         mBtn_buy = null;
         mBtn_show = null;
         mBtn_expense = null;
         mBtn_get = null;
         vipTxt_expense = null;
         vipImg_expense = null;
         info_expense = null;
         lastPrice = null;
         nowPrice = null;
         mTxt_num = null;
      }
      
      override public function init(param1:Object) : void
      {
         var _loc11_:Scale9Textures = null;
         var _loc6_:Image = null;
         var _loc8_:LOL_TextField = null;
         var _loc5_:int = 0;
         var _loc9_:Array = null;
         var _loc2_:Number = NaN;
         _loc2_ = 200;
         var _loc14_:TextField = null;
         var _loc4_:Rectangle = null;
         var _loc7_:Image = null;
         var _loc12_:Object = null;
         var _loc3_:Rectangle = null;
         var _loc13_:Image = null;
         var _loc10_:int = 0;
         if(this.data["status"] == 0)
         {
            _loc11_ = new Scale9Textures(GlobalFunction.getTexture("UI_bg_vip_buy_0_0000"),new Rectangle(40,25,30,30));
            this.mScale9Image = new Scale9Image(_loc11_);
            this.mScale9Image.width = 600;
            this.mScale9Image.height = 155;
            addChild(this.mScale9Image);
            mBtn_show = GlobalFunction.createButton_5("","UI_bg_gift_0_0000");
            mBtn_show.pivotY = mBtn_show.height / 2;
            mBtn_show.x = 25;
            mBtn_show.y = mScale9Image.height / 2 - 12;
            mBtn_show.addEventListener("triggered",onTRIGGERED_show);
            addChild(mBtn_show);
            _loc6_ = GlobalFunction.getVipImg(param1["id"],"1");
            _loc6_.scaleX = _loc6_.scaleY = 1;
            _loc6_.pivotX = _loc6_.pivotY = 0;
            _loc8_ = new LOL_TextField(GlobalLanguageStr.getStr(90488),200,35);
            _loc8_.fontSize = 25;
            _loc8_.fontColor = 16777215;
            _loc6_.x = 125;
            _loc6_.y = 25;
            _loc8_.x = _loc6_.x + 80;
            _loc8_.y = _loc6_.y - 5;
            _loc8_.shadowFilter();
            addChild(_loc6_);
            addChild(_loc8_);
            mTxt_info = GlobalFunction.createTextField(200,60,GlobalLanguageStr.getStr(90378),"",15,16777215);
            mTxt_info.x = _loc6_.x;
            mTxt_info.y = _loc6_.y + _loc6_.height - 10;
            mTxt_info.hAlign = "left";
            this.addChild(mTxt_info);
            mTxt_bugNum = GlobalFunction.createTextField(120,50,"(" + GlobalLanguageStr.getStr(90379) + ")","",15,16777215);
            mTxt_bugNum.x = MainConfig.$isEA ? this.mScale9Image.width - mTxt_bugNum.width - 4 : (MainConfig.$isEnglish ? this.mScale9Image.width - mTxt_bugNum.width - 1 : this.mScale9Image.width - mTxt_bugNum.width - 25);
            mTxt_bugNum.y = MainConfig.$isEnglish ? mTxt_info.y - 10 : mTxt_info.y - 8;
            this.addChild(mTxt_bugNum);
            _currVipLv = GlobalFunction.getVipLv();
            _currVipLv = _currVipLv < 0 ? 0 : _currVipLv;
            _loc5_ = MainConfig.$isEnglish ? 82 : 126;
            mBtn_buy = new LOL_Scale9Button(isLocalMode() ? "点击领取" : GlobalLanguageStr.getStr(20146),_loc5_,47,"UI_btn_enterGame_0_0000");
            mBtn_buy.enabled = int(param1["id"]) <= _currVipLv;
            mBtn_buy.x = mScale9Image.x + mScale9Image.width - mBtn_buy.width - 20;
            mBtn_buy.y = mScale9Image.y + mScale9Image.height - mBtn_buy.height - 20;
            mBtn_buy.addEventListener("triggered",onTRIGGERED_btn);
            addChild(mBtn_buy);
            mBg_free = GlobalFunction.createImage("UI_sale_bg_2_0003");
            mBg_free.x = this.mScale9Image.width - mBtn_buy.width - mBg_free.width - 50;
            mBg_free.y = this.mScale9Image.height - mBg_free.height - 20;
            this.addChild(mBg_free);
            _loc9_ = param1["data_base"].pay as Array;
            _loc14_ = GlobalTextStyle.getTextField(isLocalMode() ? "本地点击领取" : GlobalLanguageStr.getLanguageStr(20322,_loc9_[0]),20,16777215,"left",_loc2_,46);
            _loc14_.x = 128;
            _loc14_.y = this.mScale9Image.height - _loc14_.height - 10;
            addChild(_loc14_);
            _loc4_ = _loc14_.textBounds;
            _loc7_ = GlobalFunction.createImage("UI_bg_vip_buy_3_0000");
            _loc7_.width = _loc4_.width + 20;
            _loc7_.x = _loc14_.x - 10;
            _loc7_.y = _loc14_.y + 17;
            addChild(_loc7_);
         }
         else
         {
            _loc12_ = GlobalData.$mConfig_vip;
            price = param1["data_base"].pay as Array;
            _loc11_ = new Scale9Textures(GlobalFunction.getTexture("UI_bg_vip_buy_0_0001"),new Rectangle(40,25,30,30));
            this.mScale9Image = new Scale9Image(_loc11_);
            this.mScale9Image.width = 600;
            this.mScale9Image.height = 155;
            addChild(this.mScale9Image);
            mBtn_expense = GlobalFunction.createButton_5("","UI_bg_gift_0_0000");
            mBtn_expense.pivotY = mBtn_expense.height / 2;
            mBtn_expense.x = 25;
            mBtn_expense.y = mScale9Image.height / 2 - 13;
            mBtn_expense.addEventListener("triggered",onTRIGGERED_show);
            addChild(mBtn_expense);
            vipImg_expense = GlobalFunction.getVipImg(param1["id"],"1");
            vipImg_expense.scaleX = vipImg_expense.scaleY = 1;
            vipImg_expense.pivotX = vipImg_expense.pivotY = 0;
            vipTxt_expense = new LOL_TextField(GlobalLanguageStr.getStr(97600),200,35);
            vipTxt_expense.fontSize = 25;
            vipTxt_expense.fontColor = 1118481;
            vipImg_expense.x = 125;
            vipImg_expense.y = mScale9Image.x + 26;
            vipTxt_expense.x = vipImg_expense.x + 80;
            vipTxt_expense.y = vipImg_expense.y - 5;
            addChild(vipImg_expense);
            addChild(vipTxt_expense);
            info_expense = GlobalFunction.createTextField(200,60,GlobalLanguageStr.getStr(90378),"",15,1118481);
            info_expense.x = vipImg_expense.x;
            info_expense.y = vipImg_expense.y + vipImg_expense.height - 10;
            info_expense.hAlign = "left";
            this.addChild(info_expense);
            lastPrice = GlobalTextStyle.getTextField(isLocalMode() ? "VIP礼包" : GlobalLanguageStr.getLanguageStr(20322,price[0]),MainConfig.$isEnglish ? 18 : 20,16777215,"left",200,46);
            lastPrice.x = MainConfig.$isEnglish ? 120 : 118;
            lastPrice.y = this.mScale9Image.height - lastPrice.height - 10;
            addChild(lastPrice);
            _loc3_ = lastPrice.textBounds;
            _loc13_ = GlobalFunction.createImage("UI_bg_vip_buy_3_0000");
            _loc13_.width = _loc3_.width + 20;
            _loc13_.x = lastPrice.x - 10;
            _loc13_.y = lastPrice.y + 17;
            addChild(_loc13_);
            nowPrice = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getLanguageStr(97602),price[1],"UI_money_coin_0_0000",16777011,16777011,MainConfig.$isEnglish ? 18 : 20);
            nowPrice.x = MainConfig.$isEA ? lastPrice.x + 106 : (MainConfig.$isEnglish ? lastPrice.x + 196 : lastPrice.x + 150);
            nowPrice.y = lastPrice.y - 4;
            nowPrice._mIcon.y = nowPrice.height * 0.5 - 20;
            addChild(nowPrice);
            mTxt_num = GlobalFunction.createTextField(120,50,"(" + GlobalLanguageStr.getStr(90379) + ")","",15,1118481);
            mTxt_num.x = MainConfig.$isEA ? this.mScale9Image.width - mTxt_num.width - 4 : (MainConfig.$isEnglish ? this.mScale9Image.width - mTxt_num.width - 1 : this.mScale9Image.width - mTxt_num.width - 25);
            mTxt_num.y = MainConfig.$isEnglish ? info_expense.y - 10 : info_expense.y - 8;
            this.addChild(mTxt_num);
            _loc10_ = MainConfig.$isEnglish ? 82 : 126;
            mBtn_get = new LOL_Scale9Button(GlobalLanguageStr.getStr(20146),_loc10_,47,"UI_btn_enterGame_0_0000");
            mBtn_get.x = mScale9Image.x + mScale9Image.width - mBtn_get.width - 20;
            mBtn_get.y = mScale9Image.y + mScale9Image.height - mBtn_get.height - 20;
            mBtn_get.addEventListener("triggered",onTRIGGERED_get);
            if(GlobalFunction.getVipLv() < data["id"])
            {
               mBtn_get.enabled = false;
            }
            else
            {
               mBtn_get.enabled = true;
            }
            addChild(mBtn_get);
         }
      }
      
      private function onTRIGGERED_get(param1:Event) : void
      {
         var _fun:Object;
         var _event:Event = param1;
         var sendService:* = function():void
         {
            var _loc4_:int = 0;
            var _loc1_:int = 0;
            GlobalData.$mGameClassObject.closePopUp();
            var _loc3_:Object = data["data_base"].data;
            var _loc2_:Boolean = true;
            if(_loc3_["avatar"])
            {
               _loc4_ = Tools.getElementNum(GlobalData.$userData.avatars);
               if(_loc4_ >= GlobalData.$userData.attrs.avatar_len)
               {
                  _loc2_ = false;
                  GlobalFunction.popAvatarLen();
                  return;
               }
            }
            if(_loc3_["equip"])
            {
               _loc1_ = Tools.getElementNum(GlobalData.$userData.my_equips);
               if(_loc1_ >= GlobalData.$mConfig_simple.equip_config[0])
               {
                  _loc2_ = false;
                  GlobalFunction.popEquipFull();
                  return;
               }
            }
            if(_loc3_["score"])
            {
               if(GlobalData.$userData.score >= GlobalData.$mConfig_simple.score_config[2])
               {
                  _loc2_ = false;
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10040));
                  return;
               }
            }
            if(_loc2_)
            {
               sendBuy();
            }
         };
         if(GlobalFunction.getVipLv() >= data["id"])
         {
            if(GlobalData.$userData.coin >= price[1])
            {
               _fun = {
                  "ok":sendService,
                  "okA":["Pop"],
                  "no":GlobalFunction.functionNull
               };
               GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(97601),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97603,price[1],"VIP" + _data["id"],price[2]),GlobalTextStyle.COLOR_W_Y_Y_G),_fun);
            }
            else
            {
               GlobalFunction.popErrorCoin(price[1]);
            }
         }
         else
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90120,data["id"]));
            if(data["id"] == GlobalFunction.geVipMaxLv())
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97606,data["id"]));
            }
         }
      }
      
      private function onTRIGGERED_show(param1:Event) : void
      {
         GlobalData.$vipGiftData = data;
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_shop_vip_gift",false,true);
      }
      
      private function onTRIGGERED_btn(param1:Event) : void
      {
         var _loc2_:int = 0;
         var _loc5_:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         var _loc4_:Object = data["data_base"].data;
         var _loc3_:Boolean = true;
         GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
         if(!_loc5_.enabled)
         {
            if(GlobalFunction.getVipLv() > 0)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90120,data["id"]));
               if(data["id"] == GlobalFunction.geVipMaxLv())
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97606,data["id"]));
               }
            }
            else
            {
               GlobalFunction.popBuyVIP(GlobalData.$mGameClassObject.mLayoutUICenter.mPanelCenterShopVIP.gotoShopCoin);
            }
            return;
         }
         if(_loc4_["avatar"])
         {
            if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
            {
               _loc3_ = false;
               GlobalFunction.popAvatarLen();
               return;
            }
         }
         if(_loc4_["equip"])
         {
            _loc2_ = Tools.getElementNum(GlobalData.$userData.my_equips);
            if(_loc2_ >= GlobalData.$mConfig_simple.equip_config[0])
            {
               _loc3_ = false;
               GlobalFunction.popEquipFull();
               return;
            }
         }
         if(_loc4_["score"])
         {
            if(GlobalData.$userData.score >= GlobalData.$mConfig_simple.score_config[2])
            {
               _loc3_ = false;
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10040));
               return;
            }
         }
         if(_loc3_)
         {
            sendBuy();
         }
      }
      
      private function isLocalMode() : Boolean
      {
         var address:String = MainConfig.$SERVER_ADDRESS;
         return GlobalLocalStore.$pf_type_curr == "local" || address.indexOf("http://127.0.0.1") == 0 || address.indexOf("https://127.0.0.1") == 0 || address.indexOf("http://localhost") == 0 || address.indexOf("https://localhost") == 0;
      }
      
      private function sendBuy() : void
      {
         var awardData:Object = Tools.clone(data["data_base"].data);
         _send_data = {};
         _send_data.vip_lv = data["id"];
         _send_data["type"] = data["status"];
         SendServiceAMFFun.send_user_vip_gift_buy(function(param1:Object):void
         {
            re_buy(param1,awardData);
         },_send_data);
      }
      
      private function re_buy(param1:Object, param2:Object) : void
      {
         if(!param1.data || !GlobalFunction.isVersionedProfileReceipt(param1))
         {
            return;
         }
         if(GlobalData.$mGameClassObject && GlobalData.$mGameClassObject.mLayoutUICenter && GlobalData.$mGameClassObject.mLayoutUICenter.mPanelShopCoin)
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.mPanelShopCoin.update();
         }
         SoundManager.getOnlyExample().playSound("skill2");
         sendAward(param2);
      }
      
      private function sendAward(param1:Object) : void
      {
         var _loc3_:* = null;
         var _loc5_:Object = null;
         var _loc2_:Object = null;
         var _loc1_:Object = param1;
         var _loc4_:String = "";
         for(var _loc7_:Object in _loc1_)
         {
            _loc4_ = _loc7_.toString();
            if(_loc4_ == "avatar" || _loc4_ == "equip")
            {
               for(var _loc6_:Object in _loc1_[_loc7_])
               {
                  _loc5_ = {};
                  _loc5_[_loc6_.toString()] = _loc1_[_loc7_][_loc6_];
                  _loc2_ = GlobalFunction.getAwardByType(_loc4_,_loc5_,false,null,"",true,0.8);
                  GlobalFunction.popAward(_loc4_,GlobalLanguageStr.getLanguageStr(90062,_loc2_.msg),_loc5_,false);
               }
            }
            else
            {
               _loc2_ = GlobalFunction.getAwardByType(_loc4_,_loc1_[_loc7_],false,null,"",true,0.8);
               GlobalFunction.popAward(_loc4_,GlobalLanguageStr.getLanguageStr(90062,_loc2_.msg),_loc1_[_loc7_],false);
            }
         }
         GlobalData.$mEventDispatcher.dispatchEventWith("update_vip_gift");
      }
   }
}

