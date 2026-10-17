package com.meng52.game.ui.element
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalLocalStore;
   import com.meng52.game.global.GlobalPay;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.net.SendAndSelect;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.controls.renderers.IListItemRenderer;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   
   public class ItemShopCoin extends ItemBase implements IListItemRenderer
   {
      
      private var _btn:LOL_Scale9Button;
      
      private var quad:Quad;
      
      public function ItemShopCoin()
      {
         super();
      }
      
      override public function layoutWH() : void
      {
         if(this.mScale9Image)
         {
            this.width = this.mScale9Image.width;
            this.height = this.mScale9Image.height;
         }
         tweenX(true,true);
      }
      
      override public function init(param1:Object) : void
      {
         if(GlobalFunction.checkIsPayMon30(param1["id"]))
         {
            this.mScale9Image = GlobalFunction.createScale9Image("UI_bg_shop_4_0000",0,0,new Rectangle(0,0,1,1));
            this.mScale9Image.width = 600;
            this.mScale9Image.x = (GlobalData.$mStageWidth - this.mScale9Image.width) * 0.5 - 30 + 10;
         }
         else
         {
            this.mScale9Image = GlobalFunction.createScale9Image("UI_bg_vip_buy_0_0000",600,135,new Rectangle(40,25,30,30));
         }
         this.addChild(this.mScale9Image);
         this.setUI();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(_btn)
         {
            _btn.removeFromParent(true);
            _btn.dispose();
         }
         if(quad)
         {
            quad.removeFromParent(true);
            quad.dispose();
         }
         _btn = null;
         quad = null;
         StarlingTools.removeChildrenClear(this);
         this.clear();
      }
      
      override public function setUI() : void
      {
         var _loc21_:String = null;
         var _loc20_:String = null;
         var _loc1_:Boolean = false;
         var _loc22_:Image = null;
         var _loc26_:int = 0;
         var _loc13_:Scale9Image = null;
         var _loc16_:Number = NaN;
         var _loc17_:Array = null;
         var _loc24_:Number = NaN;
         var _loc18_:Number = NaN;
         var _loc9_:Number = NaN;
         var _loc15_:Number = NaN;
         var _loc11_:Number = NaN;
         var _loc3_:TextField = null;
         var _loc33_:String = null;
         var _loc37_:* = 0;
         var _loc4_:TextField = null;
         var _loc25_:TextField = null;
         var _loc31_:Image = null;
         var _loc36_:TextField = null;
         var _loc27_:Number = NaN;
         var _loc5_:Number = NaN;
         var _loc23_:Number = NaN;
         var _loc10_:int = 0;
         var _loc8_:Number = NaN;
         var _loc19_:Boolean = false;
         var _loc14_:String = null;
         var _loc30_:String = null;
         var _loc28_:TextField = null;
         var _loc2_:Rectangle = null;
         var _loc34_:String = null;
         var _loc7_:TextField = null;
         var _loc6_:Boolean = false;
         var _loc35_:Object = GlobalData.$mConfig_simple.mon_card as Object;
         _loc20_ = _data["id"];
            _loc1_ = GlobalFunction.checkIsPayMon30(_loc20_);
            _loc22_ = GlobalFunction.createImage("UI_award_ui_type_0001");
            _loc22_.x = 30;
            _loc22_.y = (mScale9Image.height - _loc22_.height) * 0.5;
            this.addChild(_loc22_);
            if(GlobalFunction.checkIsPayMon30(_data["id"]))
            {
               _loc13_ = GlobalFunction.createScale9Image("UI_bg_shop_5_0000",440,42,new Rectangle(10,10,30,20));
               _loc13_.y = this.mScale9Image.height * 0.5;
               _loc13_.x = _loc22_.x + _loc22_.width + 20;
               this.addChild(_loc13_);
               _loc26_ = 16764006;
            }
            else
            {
               _loc13_ = GlobalFunction.createScale9Image("UI_bg_shop_0_0000",440,42,new Rectangle(20,10,20,20));
               _loc13_.y = this.mScale9Image.height * 0.5 + 2;
               _loc13_.x = _loc22_.x + _loc22_.width + 20;
               this.addChild(_loc13_);
               _loc26_ = 1118481;
            }
            _btn = new LOL_Scale9Button(payButtonLabel(isLocalMode(),GlobalData.$userData ? GlobalData.$userData.spending : null),126,47,"UI_btn_enterGame_0_0000");
            _btn.x = _loc13_.x + _loc13_.width - _btn.width;
            _btn.y = _loc13_.y - _btn.height;
            _btn.addEventListener("triggered",onTRIGGERED_btn);
            this.addChild(_btn);
            if(GlobalFunction.checkIsPayMon30(_data["id"]))
            {
               quad = Tools.newQuad(_btn.width + 30,_btn.height + 26,_btn.x - 10,_btn.y + 40,0);
            }
            else
            {
               quad = Tools.newQuad(_btn.width + 30,_btn.height + 5,_btn.x - 10,_btn.y + 46,0);
            }
            quad.alpha = 0;
            addChild(quad);
            _loc16_ = _loc13_.width * 0.5;
            _loc17_ = this.data["status"] as Array;
            _loc24_ = Number(GlobalData.$mConfig_simple.task_money_rate);
            if(!_loc24_)
            {
               _loc24_ = 1;
            }
            _loc18_ = Math.ceil(_loc17_[0] * 10 * _loc24_);
            if(isLocalMode()) _loc18_ = int(Number(_loc17_[0]) * 10);
            _loc9_ = Number(_loc17_[1]);
            if(isLocalMode())
            {
               _loc9_ = int(GlobalData.$userData.attrs.pay_first_gift) == 0 ? _loc18_ : 0;
            }
            _loc15_ = _loc18_ + _loc17_[1];
            _loc11_ = _loc6_ ? _loc18_ : _loc9_;
            _loc3_ = GlobalTextStyle.getTextField(_loc18_ + GlobalLanguageStr.getLanguageStr(20149),20,_loc26_,"left",_loc16_,35);
            _loc3_.x = _loc13_.x + 10;
            _loc3_.y = _loc13_.y + 5;
            this.addChild(_loc3_);
            _loc33_ = priceYuanLabel(_loc17_[0]);
            _loc37_ = 16777215;
            if(GlobalFunction.checkIsPayMon30(_data["id"]))
            {
               _loc37_ = 1513239;
            }
            else
            {
               _loc37_ = 16777215;
            }
            _loc4_ = GlobalTextStyle.getTextField(_loc33_,30,_loc37_,"left",_loc16_,46);
            _loc4_.x = _loc13_.x + 10;
            _loc4_.y = _loc13_.y - 35 - 15;
            this.addChild(_loc4_);
            if(_loc11_ > 0)
            {
               _loc25_ = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90387,_loc11_),20,10027008,"left",130,35);
               _loc25_.x = _loc13_.x + _loc13_.width - 130 - 10;
               _loc25_.y = _loc3_.y;
               this.addChild(_loc25_);
            }
         if(_loc1_)
         {
            for(var _loc32_:String in _loc35_)
            {
               if(_data.id == _loc32_)
               {
                  _loc31_ = GlobalFunction.createImage("UI_bg_shop_5_0000");
                  _loc36_ = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90149,_loc35_[_loc32_][1],_loc35_[_loc32_][0]),20,16764006,"center",300,35);
                  _loc36_.x = _loc13_.x + 100;
                  _loc36_.y = _loc3_.y;
                  addChild(_loc36_);
                  if(GlobalData.$userData.attrs.accumulate_card != null)
                  {
                     _loc19_ = false;
                     for(var _loc12_:String in GlobalData.$userData.attrs.accumulate_card)
                     {
                        _loc19_ = true;
                     }
                     if(_loc19_)
                     {
                        if(GlobalData.$userData.attrs.accumulate_card[_loc32_] != null)
                        {
                           _loc27_ = GlobalData.$userData.attrs.accumulate_card[_loc32_] == null ? -1 : (GlobalData.$userData.attrs.accumulate_card[_loc32_] as Date).time * 0.001;
                           _loc5_ = _loc35_[_loc32_][2] * 24 * 60 * 60;
                           _loc23_ = SendAndSelect.$systemTimer_nowSecond;
                           _loc10_ = GlobalData.$userData.attrs.accumulate_card[_loc32_] == null ? -1 : _loc27_ - _loc23_;
                           _loc8_ = GlobalData.$userData.attrs.accumulate_card[_loc32_] == null ? -1 : _loc27_ - _loc23_;
                        }
                     }
                     else if(GlobalData.$userData.attrs.mon_card != null)
                     {
                        if(GlobalData.$userData.attrs.mon_card[_loc32_] != null)
                        {
                           _loc27_ = GlobalData.$userData.attrs.mon_card[_loc32_] == null ? -1 : (GlobalData.$userData.attrs.mon_card[_loc32_] as Date).time * 0.001;
                           _loc5_ = _loc35_[_loc32_][2] * 24 * 60 * 60;
                           _loc23_ = SendAndSelect.$systemTimer_nowSecond;
                           _loc10_ = GlobalData.$userData.attrs.mon_card[_loc32_] == null ? -1 : _loc27_ - _loc23_;
                           _loc8_ = GlobalData.$userData.attrs.mon_card[_loc32_] == null ? -1 : _loc27_ - _loc23_;
                        }
                        else if(GlobalData.$userData.attrs.mon_card is Date)
                        {
                           if(_data.id == "coin99" && GlobalData.$userData.attrs.mon_card[_data.id] == null)
                           {
                              _loc27_ = GlobalData.$userData.attrs.mon_card == null ? -1 : (GlobalData.$userData.attrs.mon_card as Date).time * 0.001;
                              _loc5_ = _loc35_[_loc32_][2] * 24 * 60 * 60;
                              _loc23_ = SendAndSelect.$systemTimer_nowSecond;
                              _loc10_ = GlobalData.$userData.attrs.mon_card == null ? -1 : _loc27_ - _loc23_;
                              _loc8_ = GlobalData.$userData.attrs.mon_card == null ? -1 : _loc27_ - _loc23_;
                           }
                        }
                     }
                  }
                  else if(GlobalData.$userData.attrs.mon_card != null)
                  {
                     if(GlobalData.$userData.attrs.mon_card[_loc32_] != null)
                     {
                        _loc27_ = GlobalData.$userData.attrs.mon_card[_loc32_] == null ? -1 : (GlobalData.$userData.attrs.mon_card[_loc32_] as Date).time * 0.001;
                        _loc5_ = _loc35_[_loc32_][2] * 24 * 60 * 60;
                        _loc23_ = SendAndSelect.$systemTimer_nowSecond;
                        _loc10_ = GlobalData.$userData.attrs.mon_card[_loc32_] == null ? -1 : _loc27_ - _loc23_;
                        _loc8_ = GlobalData.$userData.attrs.mon_card[_loc32_] == null ? -1 : _loc27_ - _loc23_;
                     }
                     else if(GlobalData.$userData.attrs.mon_card is Date)
                     {
                        if(_data.id == "coin99" && GlobalData.$userData.attrs.mon_card[_data.id] == null)
                        {
                           _loc27_ = GlobalData.$userData.attrs.mon_card == null ? -1 : (GlobalData.$userData.attrs.mon_card as Date).time * 0.001;
                           _loc5_ = _loc35_[_loc32_][2] * 24 * 60 * 60;
                           _loc23_ = SendAndSelect.$systemTimer_nowSecond;
                           _loc10_ = GlobalData.$userData.attrs.mon_card == null ? -1 : _loc27_ - _loc23_;
                           _loc8_ = GlobalData.$userData.attrs.mon_card == null ? -1 : _loc27_ - _loc23_;
                        }
                     }
                  }
                  _loc14_ = Tools.timeDay(_loc10_);
                  if(_loc8_ > 0 && _loc14_ != null)
                  {
                     if(_loc10_ > _loc5_)
                     {
                        _btn.enabled = false;
                     }
                     _loc30_ = GlobalLanguageStr.getLanguageStr(90489,Tools.timeDay(_loc10_));
                     _loc28_ = GlobalTextStyle.getTextField(_loc30_,20,1118481,"right",200,29 * 2);
                     _loc2_ = _loc28_.textBounds;
                     _loc28_.x = _btn.x - 200 - 15;
                     _loc28_.y = _btn.y + int((_btn.height - _loc2_.height) * 0.5) - (_btn.enabled ? 0 : 10) + 10;
                     addChild(_loc28_);
                  }
                  else
                  {
                     _loc34_ = GlobalLanguageStr.getLanguageStr(_data.id == "coin99" ? 20404 : (_data.id == "coin98" ? 97839 : (_data.id == "coin100" ? 97840 : 0)));
                     _loc7_ = GlobalTextStyle.getTextField(_loc34_,20,1118481,"right",200,29);
                     _loc7_.x = _btn.x - 200 - 40;
                     _loc7_.y = _loc4_.y + 10;
                     addChild(_loc7_);
                  }
               }
            }
         }
      }
      
      private function quadTouch(param1:TouchEvent) : void
      {
         var touch:Touch;
         var _cfg:Array;
         var _tips:int;
         var _fun:Object;
         var _money_rate:Number;
         var _old:Number;
         var _more:Number;
         var _t:Number;
         var str:String;
         var gotoPay:*;
         var _eve:TouchEvent = param1;
         var p:List = this.parent.parent as List;
         if(p.isScrolling)
         {
            return;
         }
         touch = _eve.getTouch(quad);
         if(touch && touch.phase == "ended")
         {
            if(_btn.enabled)
            {
               gotoPay = function():void
               {
                  GlobalPay.pay(data["id"],data["status"]);
               };
               _tips = GlobalLocalStore.$pf_type_curr.indexOf("hg");
               if(_tips > -1)
               {
                  _fun = {
                     "ok":gotoPay,
                     "no":GlobalFunction.functionNull
                  };
                  _cfg = data["status"];
                  _money_rate = Number(GlobalData.$mConfig_simple.task_money_rate);
                  if(!_money_rate)
                  {
                     _money_rate = 1;
                  }
                  _old = Math.ceil(_cfg[0] * 10 * _money_rate);
                  _more = Number(_cfg[1]);
                  _t = _old + _cfg[1];
                  str = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(95017,_t,_cfg[0]),GlobalTextStyle.COLOR_W_Y_Y_G);
                  GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(95016),str,_fun,false);
               }
               else
               {
                  gotoPay();
               }
            }
            else
            {
               _cfg = GlobalData.$mConfig_simple.mon_card;
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90514,_cfg[3]));
            }
         }
      }
      
      private function isLocalMode() : Boolean
      {
         var address:String = MainConfig.$SERVER_ADDRESS;
         return GlobalLocalStore.$pf_type_curr == "local" || address.indexOf("http://127.0.0.1") == 0 || address.indexOf("https://127.0.0.1") == 0 || address.indexOf("http://localhost") == 0 || address.indexOf("https://localhost") == 0;
      }

      public static function payButtonLabel(param1:Boolean, param2:Object) : String
      {
         return param1 && param2 != null && param2.is_gm === true ? "点击即送" : "充值";
      }

      public static function priceYuanLabel(param1:Number) : String
      {
         return String(param1) + "元";
      }
      
      private function onTRIGGERED_btn(param1:Event) : void
      {
         var _cfg:Array;
         var _tips:int;
         var _fun:Object;
         var _money_rate:Number;
         var _old:Number;
         var _more:Number;
         var _t:Number;
         var str:String;
         var gotoPay:*;
         var i:String;
         var _event:Event = param1;
         _btn = _event.currentTarget as LOL_Scale9Button;
         if(_btn.enabled)
         {
            gotoPay = function():void
            {
               GlobalPay.pay(data["id"],data["status"]);
            };
            _tips = GlobalLocalStore.$pf_type_curr.indexOf("hg");
            if(_tips > -1)
            {
               _fun = {
                  "ok":gotoPay,
                  "no":GlobalFunction.functionNull
               };
               _cfg = data["status"];
               _money_rate = Number(GlobalData.$mConfig_simple.task_money_rate);
               if(!_money_rate)
               {
                  _money_rate = 1;
               }
               _old = Math.ceil(_cfg[0] * 10 * _money_rate);
               _more = Number(_cfg[1]);
               _t = _old + _cfg[1];
               str = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(95017,_t,_cfg[0]),GlobalTextStyle.COLOR_W_Y_Y_G);
               GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(95016),str,_fun,false);
            }
            else
            {
               gotoPay();
            }
         }
         else if(GlobalData.$mConfig_simple.mon_card is Object)
         {
            for(i in GlobalData.$mConfig_simple.mon_card)
            {
               if(data["id"] == i)
               {
                  _cfg = GlobalData.$mConfig_simple.mon_card[i];
                  if(_data.id == "coin98")
                  {
                     GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97961,_cfg[2]));
                  }
                  if(_data.id == "coin99")
                  {
                     GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90514,_cfg[2]));
                  }
                  if(_data.id == "coin100")
                  {
                     GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97960,_cfg[2]));
                  }
               }
            }
         }
         else
         {
            _cfg = GlobalData.$mConfig_simple.mon_card;
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90514,_cfg[3]));
         }
      }
   }
}

