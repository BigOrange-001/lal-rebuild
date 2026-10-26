package com.meng52.game.ui.element
{
   import com.meng52.display.ScrollScreenForTxt;
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.equip.Equip;
   import com.meng52.game.ui.panel.PanelEquipAttrs;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import starling.display.DisplayObject;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   
   public class LOL_DetailEquip extends Sprite
   {
      private var mLockButton:LOL_Scale9Button;

      private function refreshInventoryLock() : void
      {
         if(!stage || !mLockButton || !_data || !(_data is Object)) return;
         var row:Object = GlobalData.$userData.my_equips[_data.id];
         mLockButton.text = row && (row.lock || row.locked) ? "已上锁 · 解锁" : "上锁保护";
         mLockButton.touchable = true;
      }

      private function toggleInventoryLock(event:Event) : void
      {
         var row:Object = GlobalData.$userData.my_equips[_data.id];
         if(!row || !mLockButton) return;
         mLockButton.touchable = false;
         GlobalFunction.setInventoryLock("equipment",String(_data.id),!(row.lock || row.locked),refreshInventoryLock);
      }
      
      private var _equip:Equip;
      
      private var _equipSp:ItemEquip;
      
      private var _starLevel:LOL_StarLevel;
      
      private var _icon:Image;
      
      private var _iconBg:Scale9Image;
      
      private var _bg:Scale9Image;
      
      public var _destinyTxt:ScrollScreenForTxt;
      
      public var mAttBaseNum:int = 0;
      
      private var _data:*;
      
      private var _width:Number = 576;
      
      public var mAttNewNum:int = 0;
      
      private var _height:Number = 600;
      
      public function LOL_DetailEquip(param1:*, param2:Number = 576, param3:Number = 600)
      {
         super();
         _data = param1;
         _width = param2;
         _height = 560;
         addEventListener("addedToStage",ADDED_TO_STAGE);
      }
      
      private function ADDED_TO_STAGE(param1:Event) : void
      {
         removeEventListener("addedToStage",ADDED_TO_STAGE);
         addEventListener("removedFromStage",REMOVED_FROM_STAGE);
         init();
      }
      
      private function init() : void
      {
         var _loc2_:Image = null;
         var _loc1_:PanelEquipAttrs = null;
         _equip = new Equip(_data.id,_data);
         if(_data.isSoul)
         {
            _loc2_ = GlobalFunction.createImage("UI_icon_fragment_0000");
            addChild(_loc2_);
            _loc1_ = _loc2_.parent.parent as PanelEquipAttrs;
            _loc2_.x = _loc1_.mTxt_titile.textBounds.x + _loc1_.mTxt_titile.textBounds.width - 50;
            _loc2_.y = _loc1_.mTxt_titile.y - 110;
            _loc2_.addEventListener("touch",icon_Touch);
         }
         _equipSp = new ItemEquip();
         if(_data is String)
         {
            _equipSp.setEquip(_equip.equipData.id,_equip.baseData.dataObj);
         }
         else
         {
            _equipSp.setEquip(_data.id,_data,8,7,_equip.lv);
         }
         _equipSp.x = -5;
         _equipSp.y = 20;
         addChild(_equipSp);
         _starLevel = new LOL_StarLevel(_equip.getStar(),_equip.getStar(),0.35);
         _starLevel.x = _width - _starLevel.width - 30;
         _starLevel.y = -5;
         addChild(_starLevel);
         _bg = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",460,160,new Rectangle(110,55,70,20));
         _bg.y = _equipSp.y;
         _bg.x = _equipSp.x + 105;
         addChild(_bg);
         _icon = GlobalFunction.createImage("UI_icon_1_0000");
         _icon.x = 0;
         _icon.y = _bg.y + _bg.height + 5;
         addChild(_icon);
         _iconBg = GlobalFunction.createScale9Image("UI_bg_9slice_5_0000",462,175,new Rectangle(25,25,10,10));
         _iconBg.x = _icon.x + _icon.width + 9;
         _iconBg.y = _icon.y;
         addChild(_iconBg);
         _equip.setDestinyAndDN();
         _destinyTxt = new ScrollScreenForTxt(Tools.formatHtmlTextBr(_equip.mDestiny.htmlArr),_iconBg.width - 40,_iconBg.height - 25);
         _destinyTxt.x = _iconBg.x + 20;
         _destinyTxt.y = _iconBg.y + 10;
         addChild(_destinyTxt);
         if(GlobalFunction.checkEquipIsBook(_equip.equipData.id))
         {
            skill();
         }
         else
         {
            equip();
         }
         if(!(_data is String) && _data && GlobalData.$userData.my_equips[_data.id])
         {
            mLockButton = new LOL_Scale9Button("",145,30,"UI_btn_enterGame_0_0000");
            mLockButton.x = _width-165;
            mLockButton.y = _iconBg.y+_iconBg.height+8;
            mLockButton.fontSize = 17;
            mLockButton.addEventListener("triggered",toggleInventoryLock);
            addChild(mLockButton);
            refreshInventoryLock();
         }
      }
      
      private function equip() : void
      {
         var _loc16_:Number = NaN;
         var _loc2_:String = null;
         var _loc10_:int = 0;
         var _loc7_:HtmlTextField = null;
         if(_equip.equipData.id.indexOf("E_1") > -1)
         {
            _loc16_ = 20263;
            _loc2_ = "UI_bg_equip_3_0000";
         }
         else if(_equip.equipData.id.indexOf("E_3") > -1)
         {
            _loc16_ = 20264;
            _loc2_ = "UI_bg_equip_2_0000";
         }
         else if(_equip.equipData.id.indexOf("E_5") > -1)
         {
            _loc16_ = 20266;
            _loc2_ = "UI_bg_equip_0_0000";
         }
         else if(_equip.equipData.id.indexOf("E_4") > -1)
         {
            _loc16_ = 20265;
            _loc2_ = "UI_bg_equip_4_0000";
         }
         var _loc9_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(_loc16_),100,50);
         _loc9_.fontColor = 16777215;
         _loc9_.fontSize = 22;
         _loc9_.y = -20;
         addChild(_loc9_);
         var _loc5_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(20017,_equip.lv) + "\n\n",100,40);
         _loc5_.fontColor = 16777215;
         _loc5_.x = _equipSp.x + 30;
         _loc5_.y = _equipSp.y + 80;
         var _loc11_:Number = 20024;
         var _loc8_:Number = 20025;
         var _loc13_:Number = 20034;
         var _loc4_:Number = 20232;
         createAttTxt(98140,_equip.getHpMax(),this._bg);
         createAttTxt(98141,_equip.getDamage(),this._bg);
         createAttTxt(98142,_equip.getDePh(),this._bg);
         createAttTxt(98143,_equip.getDeMa(),this._bg);
         createAttTxt(98144,_equip.getRange(),this._bg);
         createAttTxt(98145,_equip.getSpeed(),this._bg);
         if(_equip.hasHit())
         {
            createAttNewTxt(30021,_equip.getHit(),this._bg);
         }
         if(_equip.hasFlee())
         {
            createAttNewTxt(30022,_equip.getFlee(),this._bg);
         }
         if(_equip.hasCrit())
         {
            createAttNewTxt(30023,_equip.getCrit(),this._bg);
         }
         if(_equip.hasTough())
         {
            createAttNewTxt(30024,_equip.getTough(),this._bg);
         }
         var _loc3_:Array = [Tools.formatLineX(GlobalLanguageStr.getLanguageStr(_loc11_,_equip.getHpMax()),GlobalTextStyle.COLOR_0x4B2C1B,20,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(_loc8_,_equip.getDamage()),GlobalTextStyle.COLOR_0x4B2C1B,20,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(_loc13_,_equip.getHit(-1,false)),GlobalTextStyle.COLOR_0x4B2C1B,20,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(_loc4_,_equip.getFlee()),GlobalTextStyle.COLOR_0x4B2C1B,20,20)];
         _loc10_ = 0;
         while(_loc10_ < _loc3_.length)
         {
            _loc7_ = new HtmlTextField(240,30,_loc3_[_loc10_],true,GlobalConfig.FONT_0);
            _loc7_.touchable = false;
            _loc7_.hAlign = "left";
            _loc7_.vAlign = "top";
            _loc7_.x = 230 + int(_loc10_ / 2) * 180;
            _loc7_.y = _loc5_.y + _loc10_ % 2 * 28;
            _loc10_++;
         }
         var _loc1_:Image = GlobalFunction.createImage(_loc2_);
         _loc1_.x = _loc5_.x;
         _loc1_.y = _loc5_.y + 55;
         var _loc12_:Sprite = ItemEquipSelect.getMagicUIs(_equip.symp,_equip.magic,false,0.8);
         _loc12_.x = MainConfig.$isEA ? 47 : (MainConfig.$isEnglish ? 88 : 32);
         _loc12_.y = 78;
         _bg.addChild(_loc12_);
         var _loc6_:int = 0;
         if(!_equip.hasHit())
         {
            _loc6_ += _equip.getHit(_equip.lv);
         }
         if(!_equip.hasCrit())
         {
            _loc6_ += _equip.getCrit(_equip.lv);
         }
         if(!_equip.hasFlee())
         {
            _loc6_ += _equip.getFlee(_equip.lv);
         }
         if(!_equip.hasTough())
         {
            _loc6_ += _equip.getTough(_equip.lv);
         }
         var _loc15_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(20273) + " " + _equip.getPoteNow(_equip.lv),150,33);
         _loc15_.fontColor = 4926491;
         _loc15_.fontSize = 20;
         _loc15_.x = 273;
         _loc15_.y = _loc12_.y;
         _bg.addChild(_loc15_);
         var _loc14_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(20321) + " " + _loc6_,150,33);
         _loc14_.fontColor = 4926491;
         _loc14_.fontSize = 20;
         _loc14_.x = 273;
         _loc14_.y = _loc15_.y + _loc15_.height - 7;
         _bg.addChild(_loc14_);
      }
      
      private function createAttTxt(param1:int, param2:int, param3:DisplayObject) : void
      {
         var _loc6_:* = 0;
         var _loc7_:TextField = null;
         var _loc5_:int = GlobalData.$mStageWidth * 0.4;
         var _loc4_:int = _equip.haloLv;
         if(param2 > 0 && mAttBaseNum < 2)
         {
            _loc6_ = 4926491;
            if(_loc4_ > 0)
            {
               _loc6_ = uint(Equip.haloColor[_loc4_ - 1]);
            }
            _loc7_ = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(param1) + " " + param2,20,_loc6_,"left",_loc5_,35,GlobalConfig.FONT_1);
            _loc7_.touchable = false;
            _loc7_.x = 100;
            _loc7_.y = mAttBaseNum * 29 + 19;
            mAttBaseNum += 1;
            _bg.addChild(_loc7_);
         }
      }
      
      private function createAttNewTxt(param1:int, param2:int, param3:DisplayObject) : void
      {
         var _loc6_:TextField = null;
         var _loc5_:int = GlobalData.$mStageWidth * 0.3;
         var _loc4_:Number = 0;
         if(param2 > 0 && mAttNewNum < 2)
         {
            _loc6_ = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(param1) + " " + param2,20,1513239,"left",_loc5_,35,GlobalConfig.FONT_1);
            _loc6_.touchable = false;
            _loc6_.x = _loc6_.x + _loc6_.width + 81;
            _loc6_.y = mAttNewNum * 29 + 19;
            mAttNewNum += 1;
            _bg.addChild(_loc6_);
         }
      }
      
      private function skill() : void
      {
         var _loc6_:String = null;
         var _loc1_:Object = null;
         if(_equip)
         {
            _loc6_ = _equip.id;
            if(!_loc6_)
            {
               _loc6_ = GlobalData.$tempEquipCurrSelected;
            }
            _loc1_ = GlobalData.$userData.my_equips[_loc6_];
            if(_loc1_ != null)
            {
               _equip = new Equip(_loc6_,_loc1_);
            }
         }
         var _loc8_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(90410),100,60);
         _loc8_.fontColor = 16777215;
         _loc8_.fontSize = 22;
         _loc8_.y = -25;
         addChild(_loc8_);
         var _loc5_:LOL_Scale9Button = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90409),100,40,"UI_btn_3_0000",false);
         _loc5_.fontColor = 16777215;
         _loc5_.fontSize = 20;
         _loc5_.x = 35;
         _loc5_.y = 25;
         _bg.addChild(_loc5_);
         var _loc7_:String = GlobalLanguageStr.getLanguageStr(20489,_equip.getBookSkill().skillSetData.name,_equip.getBookSkill().lv);
         var _loc2_:LOL_TextField = new LOL_TextField(_loc7_,150,50);
         _loc2_.fontSize = 20;
         _loc2_.x = _loc5_.x + _loc5_.width;
         _loc2_.y = _loc5_.y - 5;
         _bg.addChild(_loc2_);
         var _loc4_:LOL_TextField = new LOL_TextField(_equip.getBookSkill().getInfo(),400,50);
         _loc4_.fontColor = 4926491;
         _loc4_.fontSize = 15;
         _loc4_.x = _loc5_.x;
         _loc4_.y = _loc5_.y + _loc5_.height + 5;
         _bg.addChild(_loc4_);
         var _loc3_:LOL_TextField = new LOL_TextField(_equip.getBookSkill().getInfoDesc(),_bg.width,50);
         _loc3_.fontSize = 15;
         _loc3_.x = MainConfig.$isEA ? _bg.width - 190 : _bg.width - 155;
         _loc3_.y = _loc5_.y + _loc5_.height + 47;
         _bg.addChild(_loc3_);
      }
      
      private function icon_Touch(param1:TouchEvent) : void
      {
         var _loc7_:Object = null;
         var _loc3_:Object = null;
         var _loc6_:int = 0;
         var _loc2_:int = 0;
         var _loc4_:String = null;
         var _loc5_:Touch = param1.getTouch(this,"ended");
         if(_loc5_)
         {
            if(_data)
            {
               _loc7_ = GlobalData.$mConfig_simple.soul_exchange;
               _loc3_ = GlobalData.$userData.equip_soul;
               _loc6_ = int(_loc3_[_data.id] != null ? _loc3_[_data.id] : 0);
               _loc2_ = int(_loc7_.equip[_equip.getStar()]);
               _loc4_ = "";
               if(_loc6_ < _loc2_)
               {
                  _loc4_ = GlobalLanguageStr.getLanguageStr(90600,_loc2_ - _loc6_,_equip.baseData.name);
               }
               else
               {
                  _loc4_ = GlobalLanguageStr.getLanguageStr(90604,_equip.baseData.name);
               }
               GlobalFunction.popError(_loc4_);
            }
         }
      }
      
      private function REMOVED_FROM_STAGE(param1:Event) : void
      {
         removeEventListener("removedFromStage",REMOVED_FROM_STAGE);
         if(_equipSp)
         {
            _equipSp.removeFromParent(true);
            _equipSp = null;
         }
         if(_starLevel)
         {
            _starLevel.removeFromParent(true);
            _starLevel = null;
         }
         if(_icon)
         {
            _icon.removeFromParent(true);
            _icon = null;
         }
         if(_iconBg)
         {
            _iconBg.removeFromParent(true);
            _iconBg = null;
         }
         if(_bg)
         {
            _bg.removeFromParent(true);
            _bg = null;
         }
         if(_destinyTxt)
         {
            _destinyTxt.removeFromParent(true);
            _destinyTxt = null;
         }
         StarlingTools.removeChildrenClear(this);
      }
   }
}

