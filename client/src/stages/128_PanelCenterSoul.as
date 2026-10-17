package com.meng52.game.ui.screen
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.manager.TimeManager;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.equip.Equip;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.ui.element.ItemAvatarSoul;
   import com.meng52.game.ui.element.ItemEquipSoul;
   import com.meng52.game.ui.element.ItemSoulShop;
   import com.meng52.game.ui.element.LOL_HtmlText;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.element.LOL_TextField;
   import com.meng52.game.ui.element.LOL_TextPop;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.data.ListCollection;
   import feathers.display.Scale9Image;
   import feathers.layout.TiledRowsLayout;
   import feathers.layout.VerticalLayout;
   import flash.geom.Rectangle;
   import starling.display.DisplayObject;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   
   public class PanelCenterSoul extends PanelCenterPVE
   {
      
      public static var currSoulIndex:int = -1;
      
      private var mAvatarIcon:Sprite;
      
      private var mEquipIcon:Sprite;
      
      private var _bg:Scale9Image;
      
      private var _txt1:LOL_HtmlText;
      
      private var _txt2:LOL_HtmlText;
      
      private var _btn:LOL_Scale9Button;
      
      private var _sp:Sprite;
      
      private var _textPop:LOL_TextPop;
      
      private var _avatar:Image;
      
      private var _configSet:Object = {
         0:"normal",
         1:"advanced",
         2:"super"
      };
      
      private var _configSetS:Object = {
         0:90579,
         1:90580,
         2:90581
      };
      
      private var _configShop:Object;
      
      private var _radioIndex:int = 0;
      
      private var _data:Object;
      
      private var _time:int = -1;
      
      private var shopRule:LOL_TextField;
      
      private var ruleQuad:Quad;
      
      private var quad:Quad;
      
      private var _spRule:Sprite;
      
      public function PanelCenterSoul()
      {
         super();
      }
      
      public static function checkSoulIcon() : Object
      {
         var _loc4_:Object = null;
         var _loc10_:Avatar = null;
         var _loc5_:Equip = null;
         var _loc7_:Object = {};
         var _loc3_:Boolean = false;
         var _loc9_:Object = GlobalData.$mConfig_simple.soul_exchange;
         var _loc11_:Object = GlobalData.$userData.avatar_soul;
         for(var _loc1_:String in _loc11_)
         {
            if(_loc11_[_loc1_] != 0)
            {
               _loc4_ = {};
               _loc10_ = new Avatar(_loc1_);
               _loc4_["id"] = _loc1_;
               _loc4_["name"] = _loc10_.avatarData.name;
               _loc4_["current"] = _loc11_[_loc1_];
               _loc4_["need"] = _loc9_.avatar[_loc10_.getStar()];
               _loc4_["star"] = _loc10_.getStar();
               _loc4_["status"] = _loc4_["current"] >= _loc4_["need"] ? 1 : 0;
               if(_loc4_["current"] >= _loc4_["need"])
               {
                  _loc3_ = true;
                  break;
               }
            }
         }
         var _loc6_:Boolean = false;
         var _loc8_:Object = GlobalData.$userData.equip_soul;
         for(var _loc2_:String in _loc8_)
         {
            if(_loc8_[_loc2_] != 0)
            {
               _loc4_ = {};
               _loc5_ = new Equip(_loc2_);
               _loc4_["id"] = _loc2_;
               _loc4_["name"] = _loc5_.equipData.name;
               _loc4_["need"] = _loc9_.equip[_loc5_.getStar()];
               _loc4_["current"] = _loc8_[_loc2_];
               _loc4_["star"] = _loc5_.getStar();
               _loc4_["status"] = _loc4_["current"] >= _loc4_["need"] ? 1 : 0;
               if(_loc4_["current"] >= _loc4_["need"])
               {
                  _loc6_ = true;
                  break;
               }
            }
         }
         _loc7_["x"] = _loc3_ || _loc6_;
         _loc7_["x1"] = _loc3_;
         _loc7_["x2"] = _loc6_;
         return _loc7_;
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         currSoulIndex = -1;
         GlobalData.$mEventDispatcher.addEventListener("update_equipsoul_list",UPDATE_EQUIPSOUL_LIST);
         GlobalData.$mEventDispatcher.addEventListener("update_avatarsoul_list",UPDATE_AVATARSOUL_LIST);
         _configShop = GlobalData.$mConfig.mystery_shop;
         mImg_head = getImg_headBg(-60);
         addChild(mImg_head);
         setTabBar([{
            "label":GlobalLanguageStr.getLanguageStr(90578),
            "IndexID":0
         },{
            "label":GlobalLanguageStr.getLanguageStr(97506),
            "IndexID":1
         },{
            "label":GlobalLanguageStr.getLanguageStr(97507),
            "IndexID":2
         }],tab_Change,tab_Complete,MainConfig.$isEnglish ? 200 : 158);
         mTabBar.y = 20;
         mImg3_info = getImg3_info();
         mImg3_info.y = mTabBar.y + 55;
         mImg3_info.height = 39;
         addChild(mImg3_info);
         GlobalData.$mEventDispatcher.addEventListener("update_soulshop_list",UPDATE_SOULSHOP_LIST);
         var _loc2_:Object = GlobalFunction.get_HelpLink(GlobalLanguageStr.getLanguageStr(97517));
         _spRule = _loc2_.ui;
         _spRule.x = GlobalData.$mStageWidth - _loc2_.w - 30;
         _spRule.y = mImg3_info.y + 22;
         addChild(_spRule);
         _spRule.addEventListener("touch",ruleTouch);
      }
      
      private function UPDATE_SOULSHOP_LIST(param1:Event) : void
      {
         var _loc3_:Object = null;
         var _loc2_:Object = null;
         if(_data)
         {
            _data.b = param1.data.b;
            _loc3_ = {"data":_data};
            get_Info(_loc3_);
            _loc2_ = checkSoulIcon();
            checkAvatarIcon(_loc2_.x1);
            checkEquipIcon(_loc2_.x2);
         }
      }
      
      private function UPDATE_AVATARSOUL_LIST(param1:Event) : void
      {
         update();
      }
      
      private function UPDATE_EQUIPSOUL_LIST(param1:Event) : void
      {
         update();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         currSoulIndex = -1;
         TimeManager.instance().unregister("PANEL_CENTERSOUL");
         GlobalData.$mEventDispatcher.removeEventListener("update_soulshop_list",UPDATE_SOULSHOP_LIST);
         GlobalData.$mEventDispatcher.removeEventListener("update_equipsoul_list",UPDATE_EQUIPSOUL_LIST);
         GlobalData.$mEventDispatcher.removeEventListener("update_avatarsoul_list",UPDATE_AVATARSOUL_LIST);
         if(_bg)
         {
            _bg.removeFromParent();
            _bg = null;
         }
         if(_txt1)
         {
            _txt1.removeFromParent();
            _txt1 = null;
         }
         if(_txt2)
         {
            _txt2.removeFromParent();
            _txt2 = null;
         }
         if(_btn)
         {
            _btn.removeFromParent();
            _btn = null;
         }
         if(_sp)
         {
            _sp.removeFromParent();
            _sp = null;
         }
         if(shopRule)
         {
            shopRule.removeFromParent();
            shopRule = null;
         }
         if(ruleQuad)
         {
            ruleQuad.removeFromParent();
            ruleQuad = null;
         }
         if(quad)
         {
            quad.removeFromParent();
            quad = null;
         }
         if(_spRule)
         {
            _spRule.removeEventListener("touch",ruleTouch);
            _spRule.removeFromParent();
            _spRule = null;
         }
         StarlingTools.removeChildrenClear(this);
      }
      
      private function tab_Change(param1:Event) : void
      {
         update();
      }
      
      private function get_Info(param1:Object) : void
      {
         var _responseType:String = param1 && param1.params ? String(param1.params.s_type) : "";
         if(!this.stage || !mRadioBar)
         {
            return;
         }
         if(_radioIndex != mRadioBar.selectedIndex)
         {
            _radioIndex = mRadioBar.selectedIndex;
            SendServiceAMFFun.send_user_mystery_shop_info(get_Info,{"s_type":_configSet[_radioIndex]});
         }
         else if(_responseType != "" && _responseType != _configSet[_radioIndex])
         {
            // Do not render an older tab's read response over the selected tab.
            return;
         }
         else
         {
            _data = param1.data;
            this.setList_Shop();
            this.addList_Shop();
            checkTime();
         }
      }
      
      private function checkTime() : void
      {
         var _loc7_:Object = null;
         var _loc6_:int = 0;
         var _loc5_:int = 0;
         var _loc2_:int = 0;
         var _loc4_:int = 0;
         var _loc1_:Date = null;
         var _loc3_:int = 0;
         if(_txt1)
         {
            _loc7_ = _configShop[_configSet[_radioIndex]];
            _loc6_ = int(_loc7_.start_time);
            _loc5_ = SendAndSelect.$systemTimer_nowSecond;
            _loc2_ = _loc7_.refresh_interval * 60;
            _time = _loc4_ = _loc2_ - (_loc5_ - int(_data.t * 0.001));
            _loc1_ = new Date();
            _loc1_.setTime(_data.t);
            _loc1_.time += _loc2_ * 1000;
            _txt1.format(Tools.dateFormat(_loc1_,0,"HH:NN:SS",_loc1_.getUTCHours()) + GlobalLanguageStr.getLanguageStr(90582,GlobalLanguageStr.getLanguageStr(_configSetS[_radioIndex])),null,40);
            TimeManager.instance().regsiter("PANEL_CENTERSOUL",time_Tick);
         }
         if(_txt2)
         {
            _loc3_ = int(_configShop[_configSet[_radioIndex]].refresh_price);
            _txt2.text = GlobalLanguageStr.getLanguageStr(90584,_loc3_);
         }
      }
      
      override public function update() : void
      {
         this.setList();
         this.addList();
      }
      
      private function tab_Complete(param1:Event) : void
      {
         mTabBar.selectedIndex = 0;
         update();
      }
      
      override public function setList() : void
      {
         var _rulerH:Number;
         var settings:Object;
         var _layout:VerticalLayout;
         var tweenComplete:* = function():void
         {
            isReady = true;
         };
         isReady = false;
         GlobalData.$mStarling.juggler.tween(this,0.4,{"onComplete":tweenComplete});
         this.delList();
         if(this.mList == null)
         {
            _rulerH = 130;
            settings = {
               "paging":0,
               "gap":10,
               "horizontalGap":20,
               "verticalGap":20,
               "paddingTop":0,
               "paddingRight":0,
               "paddingBottom":0,
               "paddingLeft":0,
               "horizontalAlign":"center",
               "verticalAlign":"top"
            };
            _layout = new VerticalLayout();
            _layout.paddingTop = settings.paddingTop;
            _layout.paddingRight = settings.paddingRight;
            _layout.paddingBottom = settings.paddingBottom;
            _layout.paddingLeft = settings.paddingLeft;
            _layout.horizontalAlign = settings.horizontalAlign;
            _layout.verticalAlign = settings.verticalAlign;
            _layout.gap = settings.gap;
            _layout.hasVariableItemDimensions = false;
            this.mList = new List();
            this.mList.isSelectable = false;
            this.mList.width = GlobalData.$mStageWidth - 20;
            this.mList.height = mListH = GlobalData.$center_height - 260;
            this.mList.layout = _layout;
            this.mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
            this.mList.x = 0;
            this.mList.y = mListY = _rulerH;
            this.mList.snapScrollPositionsToPixels = true;
            this.addChild(this.mList);
            settings = null;
            _layout = null;
            this.mList.dataProvider = new ListCollection();
         }
         if(_sp)
         {
            _sp.visible = false;
         }
      }
      
      public function setList_Shop() : void
      {
         var _rulerH:Number;
         var _layout:TiledRowsLayout;
         var price:int;
         var tweenComplete:* = function():void
         {
            isReady = true;
         };
         isReady = false;
         GlobalData.$mStarling.juggler.tween(this,0.4,{"onComplete":tweenComplete});
         this.delList();
         if(this.mList == null)
         {
            _rulerH = 335;
            _layout = new TiledRowsLayout();
            _layout.paddingTop = 0;
            _layout.paddingRight = 10;
            _layout.paddingBottom = 0;
            _layout.paddingLeft = 0;
            _layout.horizontalAlign = "center";
            _layout.verticalAlign = "top";
            _layout.gap = 5;
            _layout.useSquareTiles = false;
            this.mList = new List();
            this.mList.isSelectable = false;
            this.mList.width = GlobalData.$mStageWidth - 20;
            this.mList.height = mListH = GlobalData.$center_height - 450;
            this.mList.layout = _layout;
            this.mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
            this.mList.x = 15;
            this.mList.y = mListY = _rulerH;
            this.mList.snapScrollPositionsToPixels = true;
            this.addChild(this.mList);
            _layout = null;
            this.mList.dataProvider = new ListCollection();
         }
         if(!_sp)
         {
            _sp = new Sprite();
            addChildAt(_sp,0);
            _bg = GlobalFunction.createScale9Image("UI_bg_9slice_5_0000",GlobalData.$mStageWidth - 20,105,new Rectangle(25,25,50,25));
            _bg.x = int((GlobalData.$mStageWidth - _bg.width) * 0.5);
            _bg.y = GlobalData.$center_height_curr - 110 - _bg.height - 15;
            _sp.addChild(_bg);
            _btn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90647),130,45,"UI_btn_enterGame_0_0000");
            _btn.x = _bg.x + _bg.width - _btn.width - 15;
            _btn.y = MainConfig.$isEnglish ? _bg.y + (_bg.height - _btn.height + 28) / 2 : _bg.y + (_bg.height - _btn.height) / 2;
            _sp.addChild(_btn);
            var _textWidth:Number = _btn.x - _bg.x - 25;
            _txt1 = new LOL_HtmlText(_textWidth,30,MainConfig.$isEnglish ? 15 : 20,16777215,false,"center");
            _txt1.x = _bg.x + 10;
            _txt1.y = _bg.y + 20;
            _sp.addChild(_txt1);
            price = int(_configShop[_configSet[_radioIndex]].refresh_price);
            _txt2 = new LOL_HtmlText(_textWidth,30,20,13777209,false,"center");
            _txt2.text = GlobalLanguageStr.getLanguageStr(90584,price);
            _txt2.x = _txt1.x;
            _txt2.y = _txt1.y + _txt1.height;
            _sp.addChild(_txt2);
            _btn.addEventListener("triggered",btn_Triggered);
            checkTime();
         }
         if(_sp)
         {
            _sp.visible = true;
            updateAvatar();
         }
      }
      
      private function updateAvatar() : void
      {
         if(!_sp)
         {
            return;
         }
         var _loc3_:DisplayObject = _sp.getChildByName("avatar");
         if(_loc3_)
         {
            _sp.removeChild(_loc3_);
         }
         var _loc4_:DisplayObject = _sp.getChildByName("textpop");
         if(_loc4_)
         {
            _sp.removeChild(_loc4_);
         }
         var _loc5_:DisplayObject = _sp.getChildByName("quad");
         if(_loc5_)
         {
            _sp.removeChild(_loc5_);
         }
         var _loc1_:Object = _configShop[_configSet[_radioIndex]];
         _avatar = GlobalFunction.createImage(_loc1_.avatar);
         _avatar.y = 150;
         _avatar.name = "avatar";
         _sp.addChild(_avatar);
         _textPop = null;
         if(_loc1_.direction == 0)
         {
            _avatar.x = (GlobalData.$mStageWidth - _avatar.width) / 2 - 100;
            _textPop = new LOL_TextPop(250,110,"textpop_left");
            _textPop.x = GlobalData.$mStageWidth / 2;
         }
         else
         {
            _avatar.x = (GlobalData.$mStageWidth - _avatar.width) / 2 + 100;
            _textPop = new LOL_TextPop(250,110,"textpop_right");
            _textPop.x = GlobalData.$mStageWidth / 2 - _textPop.width;
         }
         _textPop.name = "textpop";
         _textPop.y = 200;
         _textPop.show(GlobalLanguageStr.getLanguageStr(_loc1_.info));
         _sp.addChild(_textPop);
         var _loc2_:Quad = new Quad(mList.width,mList.height + 10,0);
         _loc2_.name = "quad";
         _loc2_.alpha = 0.5;
         _loc2_.x = mList.x - 5;
         _loc2_.y = mList.y - 5;
         _sp.addChild(_loc2_);
      }
      
      private function time_Tick(param1:int) : void
      {
         _time = _time - 1;
         if(_time < 0)
         {
            TimeManager.instance().unregister("PANEL_CENTERSOUL");
            if(mTabBar && mTabBar.selectedIndex == 0)
            {
               update_Shop();
            }
         }
      }
      
      private function btn_Triggered(param1:Event) : void
      {
         var str:String;
         var e:Event = param1;
         var _requestedType:String = _configSet[mRadioBar.selectedIndex];
         var _owner:PanelCenterSoul = this;
         var send:* = function():void
         {
            SendServiceAMFFun.send_user_mystery_shop_refresh_by_coin(function(_receipt:Object):void
            {
               _owner.refresh(_receipt,_requestedType);
            },{"s_type":_requestedType});
         };
         var price:int = int(_configShop[_requestedType].refresh_price);
         if(GlobalData.$userData.coin < price)
         {
            GlobalFunction.popErrorCoin(price);
         }
         else
         {
            str = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90588,price,GlobalLanguageStr.getLanguageStr(_configSetS[_radioIndex])),GlobalTextStyle.COLOR_W_W_Y_W);
            GlobalFunction.popAlert("",str,{
               "ok":send,
               "no":GlobalFunction.functionNull
            });
         }
      }
      
      private function refresh(param1:Object, param2:String = "") : void
      {
         var _loc2_:Object = param1.data;
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.coin = _loc2_.coin;
            GlobalData.$userData.vip_exp = _loc2_.vip_exp;
            GlobalData.$userData.vip_lv = _loc2_.vip_lv;
         }
         GlobalFunction.updateCoin();
         GlobalFunction.updateVip();
         if(!this.stage || !mRadioBar)
         {
            return;
         }
         var _responseType:String = param2 != "" ? param2 : String(param1.params ? param1.params.s_type : "");
         if(_responseType != "" && _responseType != _configSet[mRadioBar.selectedIndex])
         {
            // The authoritative snapshot is already merged. Keep the receipt,
            // but leave a newer tab's rows and selection untouched.
            return;
         }
         _data = _loc2_;
         get_Info({"data":_data,"params":{"s_type":_responseType}});
      }
      
      public function addList_Shop() : void
      {
         var _loc5_:int = 0;
         var _loc3_:Object = null;
         var _loc1_:Array = [];
         var _loc2_:Array = _data.items;
         var _loc4_:Array = _data.b;
         _loc5_ = 0;
         while(_loc5_ < _loc2_.length)
         {
            _loc3_ = {};
            _loc3_["data"] = _loc2_[_loc5_][0];
            _loc3_["pay"] = _loc2_[_loc5_][1];
            _loc3_["isBuy"] = _loc4_.length == 0 ? -1 : _loc4_.indexOf(_loc5_);
            _loc3_["s_type"] = _configSet[_radioIndex];
            _loc3_["index"] = _loc5_;
            _loc3_["time"] = _data.t;
            _loc1_.push(_loc3_);
            _loc5_++;
         }
         this.setListTimer(mList,_loc1_,ItemSoulShop,false);
         LayoutUIAnimation.getOnlyExample().clearIfNoGuide();
         if(GlobalData.$userData.lv >= GlobalData.$mConfig_simple.start_lv[17])
         {
            GuideMaster.getOnlyExample().checkGuide("M16_1");
         }
      }
      
      override public function addList() : void
      {
         var _loc4_:Object = null;
         var _loc7_:Avatar = null;
         var _loc5_:Equip = null;
         var _loc3_:Array = null;
         var _loc8_:int = 0;
         var _loc13_:Array = [];
         var _loc12_:Array = [];
         var _loc14_:Object = GlobalData.$mConfig_simple.soul_exchange;
         var _loc2_:Boolean = false;
         var _loc10_:Boolean = false;
         var _loc11_:Boolean = false;
         var _loc15_:Object = GlobalData.$userData.avatar_soul;
         for(var _loc9_:String in _loc15_)
         {
            if(_loc15_[_loc9_] != 0)
            {
               _loc4_ = {};
               _loc7_ = new Avatar(_loc9_);
               _loc4_["id"] = _loc9_;
               _loc4_["name"] = _loc7_.avatarData.name;
               _loc4_["current"] = _loc15_[_loc9_];
               _loc4_["need"] = _loc14_.avatar[_loc7_.getStar()];
               _loc4_["star"] = _loc7_.getStar();
               _loc4_["status"] = _loc4_["current"] >= _loc4_["need"] ? 1 : 0;
               _loc13_.push(_loc4_);
               if(!_loc10_ && _loc4_["current"] >= _loc4_["need"])
               {
                  _loc10_ = true;
               }
            }
         }
         var _loc6_:Object = GlobalData.$userData.equip_soul;
         for(var _loc1_:String in _loc6_)
         {
            if(_loc6_[_loc1_] != 0)
            {
               _loc4_ = {};
               _loc5_ = new Equip(_loc1_);
               _loc4_["id"] = _loc1_;
               _loc4_["name"] = _loc5_.equipData.name;
               _loc4_["need"] = _loc14_.equip[_loc5_.getStar()];
               _loc4_["current"] = _loc6_[_loc1_];
               _loc4_["star"] = _loc5_.getStar();
               _loc4_["status"] = _loc4_["current"] >= _loc4_["need"] ? 1 : 0;
               _loc12_.push(_loc4_);
               if(!_loc11_ && _loc4_["current"] >= _loc4_["need"])
               {
                  _loc11_ = true;
               }
            }
         }
         if(this.mTabBar.selectedIndex == 0)
         {
            _spRule.visible = true;
            mImg3_info.height = 80;
            _loc3_ = [];
            _loc8_ = int(GlobalData.$userData.vip_lv);
            if(_configShop.normal.vip_lv <= _loc8_)
            {
               _loc3_.push({"label":GlobalLanguageStr.getLanguageStr(90579)});
            }
            if(_configShop.advanced.vip_lv <= _loc8_)
            {
               _loc3_.push({"label":GlobalLanguageStr.getLanguageStr(90580)});
            }
            if(_configShop["super"].vip_lv <= _loc8_)
            {
               _loc3_.push({"label":GlobalLanguageStr.getLanguageStr(90581)});
            }
            this.setRadioBar(_loc3_,radioBar_Change,radioBar_Complete,MainConfig.$isEnglish ? 142 : 125);
            radioBarSelectedIndex = 0;
            this.mRadioBar.selectedIndex = 0;
            _radioIndex = 0;
            this.mRadioBar.x = 20;
            this.mRadioBar.y = mImg3_info.y + 10;
            this.delTips();
            checkAvatarIcon(_loc10_);
            checkEquipIcon(_loc11_);
         }
         else if(this.mTabBar.selectedIndex == 1)
         {
            _spRule.visible = false;
            mImg3_info.height = 39;
            mList.y = 132;
            mList.height = mListH = GlobalData.$center_height - 140;
            if(this.mRadioBar)
            {
               this.mRadioBar.visible = false;
            }
            if(_loc13_.length > 0)
            {
               delTips();
               _loc13_.sortOn(["status","star","current","id"],[0x10 | 2,0x10 | 2,0x10 | 2,0x10 | 2]);
               this.setListTimer(this.mList,_loc13_,ItemAvatarSoul,false,currSoulIndex);
            }
            else
            {
               this.setTips(GlobalLanguageStr.getLanguageStr(97512));
            }
            LayoutUIAnimation.getOnlyExample().clearIfNoGuide();
            if(GlobalData.$userData.lv >= GlobalData.$mConfig_simple.start_lv[17])
            {
               GuideMaster.getOnlyExample().checkGuide("M16_2");
            }
         }
         else if(this.mTabBar.selectedIndex == 2)
         {
            _spRule.visible = false;
            mList.y = 132;
            mImg3_info.height = 39;
            mList.height = mListH = GlobalData.$center_height - 140;
            if(this.mRadioBar)
            {
               this.mRadioBar.visible = false;
            }
            if(_loc12_.length > 0)
            {
               delTips();
               _loc12_.sortOn(["status","star","current","id"],[0x10 | 2,0x10 | 2,0x10 | 2,0x10 | 2]);
               this.setListTimer(this.mList,_loc12_,ItemEquipSoul,false,currSoulIndex);
            }
            else
            {
               this.setTips(GlobalLanguageStr.getLanguageStr(97513));
            }
            LayoutUIAnimation.getOnlyExample().clearIfNoGuide();
            if(GlobalData.$userData.lv >= GlobalData.$mConfig_simple.start_lv[17])
            {
               GuideMaster.getOnlyExample().checkGuide("M16_3");
            }
         }
         checkAvatarIcon(_loc10_);
         checkEquipIcon(_loc11_);
         GlobalData.$mGameClassObject.mLayoutUICenter.mPanelCenterMain.getSoulIcon(_loc2_);
      }
      
      private function ruleTouch(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(this);
         if(_loc2_ && _loc2_.phase == "ended")
         {
            GlobalFunction.popPanelHelp(MainConfig.SERVER_ADDRESS_HELP_MYSTERY_SHOP);
         }
      }
      
      private function radioBar_Complete(param1:Event) : void
      {
         SendServiceAMFFun.send_user_mystery_shop_info(get_Info,{"s_type":_configSet[_radioIndex]});
      }
      
      private function radioBar_Change(param1:Event) : void
      {
         update_Shop();
      }
      
      private function update_Shop() : void
      {
         var _loc1_:int = int(mRadioBar ? mRadioBar.selectedIndex : 0);
         _radioIndex = _loc1_;
         if(_loc1_ == 0)
         {
            SendServiceAMFFun.send_user_mystery_shop_info(get_Info,{"s_type":"normal"});
         }
         else if(_loc1_ == 1)
         {
            SendServiceAMFFun.send_user_mystery_shop_info(get_Info,{"s_type":"advanced"});
         }
         else if(_loc1_ == 2)
         {
            SendServiceAMFFun.send_user_mystery_shop_info(get_Info,{"s_type":"super"});
         }
      }
      
      private function checkAvatarIcon(param1:Boolean) : void
      {
         if(param1)
         {
            if(mAvatarIcon == null)
            {
               mAvatarIcon = GlobalFunction.getTagPopTip(1,false);
               mAvatarIcon.x = MainConfig.$isEnglish ? 380 : 295;
               mAvatarIcon.y = 18;
               addChild(mAvatarIcon);
            }
         }
         else if(mAvatarIcon)
         {
            mAvatarIcon.removeFromParent(true);
            mAvatarIcon = null;
         }
      }
      
      private function checkEquipIcon(param1:Boolean) : void
      {
         if(param1)
         {
            if(mEquipIcon == null)
            {
               mEquipIcon = GlobalFunction.getTagPopTip(1,false);
               mEquipIcon.x = MainConfig.$isEnglish ? 578 : 455;
               mEquipIcon.y = 18;
               addChild(mEquipIcon);
            }
         }
         else if(mEquipIcon)
         {
            mEquipIcon.removeFromParent(true);
            mEquipIcon = null;
         }
      }
   }
}

