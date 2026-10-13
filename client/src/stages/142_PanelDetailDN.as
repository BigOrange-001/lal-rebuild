package com.meng52.game.ui.panel
{
   import com.meng52.display.ScrollScreenForTxt;
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.map.GameMapTools;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.element.LOL_StarLevel;
   import com.meng52.game.ui.element.LOL_TextField;
   import com.meng52.game.ui.screen.PanelCenterDNTeam;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.net.SendAndSelect;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import flash.geom.Rectangle;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;

   public class PanelDetailDN extends PanelDetailAll
   {

      private var mIcon_dn:Image;

      private var mTxt_dnLv:TextFieldHtmlRenderer;

      private var mData_noChange:Object;

      private var mDNViewEpoch:uint = 0;

      private var mDNOperation:uint = 0;


      private var _rec:Rectangle;

      public function PanelDetailDN()
      {
         super();
      }

      public static function getDNattrName(param1:String, param2:int = 0) : String
      {
         var _loc3_:String = "";
         if(param1 == "all")
         {
            _loc3_ = GlobalLanguageStr.getLanguageStr(98112);
         }
         else if(param1 == "hp")
         {
            _loc3_ = GlobalLanguageStr.getLanguageStr(98113);
         }
         else if(param1 == "ap")
         {
            _loc3_ = GlobalLanguageStr.getLanguageStr(98114);
         }
         else if(param1 == "de_ph")
         {
            _loc3_ = GlobalLanguageStr.getLanguageStr(20285);
         }
         else if(param1 == "de_ma")
         {
            _loc3_ = GlobalLanguageStr.getLanguageStr(20286);
         }
         else if(param1 == "hit")
         {
            _loc3_ = GlobalLanguageStr.getLanguageStr(30021);
         }
         else if(param1 == "flee")
         {
            _loc3_ = GlobalLanguageStr.getLanguageStr(30022);
         }
         else if(param1 == "crit")
         {
            _loc3_ = GlobalLanguageStr.getLanguageStr(30023);
         }
         else if(param1 == "tough")
         {
            _loc3_ = GlobalLanguageStr.getLanguageStr(30024);
         }
         else if(param1 == "skill")
         {
            _loc3_ = param2 == 0 ? GlobalLanguageStr.getLanguageStr(20091) : GlobalLanguageStr.getLanguageStr(20105);
         }
         return _loc3_;
      }

      public static function getDNAttrsAllValue(param1:Object = null) : Object
      {
         var _loc14_:Array = null;
         var _loc2_:Avatar = null;
         var _loc3_:Object = GlobalData.$mConfig_simple.dn;
         var _loc13_:Number = 0;
         var _loc5_:Number = 0;
         var _loc12_:Number = 0;
         var _loc8_:Number = 0;
         var _loc7_:Number = 0;
         var _loc11_:Number = 0;
         var _loc10_:String = _loc3_[5];
         var _loc6_:String = "";
         var _loc15_:Object = param1 == null ? GlobalData.$userData.attrs.dn : param1;
         var _loc4_:Object = null;
         for(var _loc9_:Object in _loc15_)
         {
            _loc14_ = _loc15_[_loc9_];
            if(_loc14_ && _loc14_[1] != null && int(_loc9_) > 0)
            {
               _loc6_ = _loc14_[1];
               if(_loc14_[2] != null)
               {
                  _loc4_ = GlobalFunction.setOtherCfgAvatar(_loc14_[2],true,_loc6_);
               }
               _loc2_ = new Avatar(_loc6_,_loc4_);
               _loc11_ = Number(getDNaddValue(_loc9_.toString(),_loc14_).currP);
               _loc10_ = _loc3_[_loc9_][5];
               if(_loc10_ == "all")
               {
                  _loc13_ += _loc11_;
                  _loc5_ += Math.floor(_loc2_.getHpMax() * _loc11_);
                  _loc12_ += Math.floor(_loc2_.getDamage() * _loc11_);
                  _loc8_ += Math.floor(_loc2_.getDePh() * _loc11_);
                  _loc7_ += Math.floor(_loc2_.getDeMa() * _loc11_);
               }
               else if(_loc10_ == "hp")
               {
                  _loc5_ += Math.floor(_loc2_.getHpMax() * _loc11_);
               }
               else if(_loc10_ == "ap")
               {
                  _loc12_ += Math.floor(_loc2_.getDamage() * _loc11_);
               }
               else if(_loc10_ == "de_ph")
               {
                  _loc8_ += Math.floor(_loc2_.getDePh() * _loc11_);
               }
               else if(_loc10_ == "de_ma")
               {
                  _loc7_ += Math.floor(_loc2_.getDeMa() * _loc11_);
               }
               _loc2_.clear();
               _loc2_ = null;
            }
         }
         return {
            "p":_loc13_,
            "hp":_loc5_,
            "ap":_loc12_,
            "de_ph":_loc8_,
            "de_ma":_loc7_
         };
      }

      public static function getDNaddValue(param1:String, param2:Array) : Object
      {
         var _loc5_:Array = GlobalData.$mConfig_simple.dn[param1] as Array;
         var _loc3_:Array = GlobalData.$mConfig_simple.dn[param1] as Array;
         var _loc8_:int = int(param2[0]);
         var _loc9_:Number = _loc8_ - 1;
         _loc9_ = _loc9_ <= 0 ? 0 : _loc9_;
         _loc9_ = _loc9_ * _loc3_[7] + _loc3_[6];
         var _loc4_:Number = _loc8_;
         _loc4_ = _loc4_ <= 0 ? 0 : _loc4_;
         _loc4_ = _loc4_ * _loc3_[7] + _loc3_[6];
         var _loc6_:String = getDNattrName(_loc3_[5]);
         var _loc7_:Number = Tools.toInt(_loc8_ * _loc8_ * _loc3_[4]);
         return {
            "currP":_loc9_,
            "nextP":_loc4_,
            "attrStr":_loc6_,
            "stone":_loc7_,
            "type":_loc5_[5]
         };
      }

      override protected function initializeHandler(param1:Event) : void
      {
         mDNViewEpoch++;
         mData_noChange = GlobalData.$tempTeamSelect;
         _width = 578;
         _height = 855;
         setPopPanelBg(GlobalLanguageStr.getLanguageStr(_data["data_base"][0]),_height);
         _bg1 = GlobalFunction.createImage("UI_bg_0_10_",true);
         _bg1.x = (640 - _width) / 2;
         _bg1.y = 80;
         _bg1.width = _width;
         _bg1.height = 600;
         addChild(_bg1);
         mIcon_dn = GlobalFunction.createImage("UI_btn_superteam0000");
         _bg2 = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",_width - 10,165,new Rectangle(110,55,70,20));
         _bg2.x = (GlobalData.$mStageWidth - _bg2.width) / 2;
         _bg2.y = _height - 270;
         addChild(_bg2);
         mIcon_dn.x = _bg2.x + 35;
         mIcon_dn.y = _bg2.y + 30;
         addChild(mIcon_dn);
         mTxt_dnLv = GlobalTextStyle.getHtmlTextRenderer();
         mTxt_dnLv.x = mIcon_dn.x + mIcon_dn.width + 10;
         mTxt_dnLv.y = _bg2.y + 35;
         _bg2.addChild(mTxt_dnLv);
         _uiMain = new Sprite();
         addChild(_uiMain);
         _icon = GlobalFunction.createImage("UI_icon_1_0000");
         _icon.x = _bg2.x + 10;
         _icon.y = _height - 430;
         addChild(_icon);
         _iconBg = GlobalFunction.createScale9Image("UI_bg_9slice_5_0000",_width - _icon.width - 40,150,new Rectangle(30,20,50,30));
         _iconBg.x = _icon.x + _icon.width;
         _iconBg.y = _icon.y;
         addChild(_iconBg);
         mTxt_destiny = new ScrollScreenForTxt("",_iconBg.width - 20,_iconBg.height - 30);
         mTxt_destiny.x = _iconBg.x + 15;
         mTxt_destiny.y = _iconBg.y + 10;
         addChild(mTxt_destiny);
         _rise = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(25051),160,65);
         _up = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(25036),160,65);
         var _loc2_:int = int(GlobalData.$mConfig_simple.dn_lv);
         var _loc4_:int = int(mData_noChange["dnlv"]);
         var _loc3_:Boolean = _loc4_ >= _loc2_;
         _up.enabled = !_loc3_;
         _reset = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(25037),160,65);
         if(MainConfig.$isEA)
         {
            _rise.fontSize = 20;
            _up.fontSize = 20;
            _reset.fontSize = 20;
         }
         _rise.y = _height - 100;
         _up.y = _rise.y;
         _reset.y = _rise.y;
         _rise.x = 60;
         _up.x = 240;
         _reset.x = 420;
         addChild(_up);
         addChild(_rise);
         addChild(_reset);
         if(!_avatar)
         {
            _rise.enabled = false;
         }
         var _loc7_:int = int(GlobalData.$mConfig_simple.dn_lv);
         var _loc5_:int = int(mData_noChange["dnlv"]);
         var _loc6_:Boolean = _loc5_ >= _loc7_;
         if(_loc6_)
         {
            _up.enabled = false;
         }
         else
         {
            _up.enabled = true;
         }
         _rise.addEventListener("triggered",rise_Triggered);
         _up.addEventListener("triggered",up_Triggered);
         _reset.addEventListener("triggered",role1_Triggered);
         GlobalData.$mEventDispatcher.addEventListener("change_team_member",CHANGE_TEAM_MEMBER);
         update();
      }

      protected function updateUI() : void
      {
         var _loc12_:Object = null;
         var _loc3_:Sprite = null;
         var _loc2_:LOL_TextField = null;
         var _loc6_:Image = null;
         var _loc10_:Image = null;
         var _loc13_:String = null;
         var _loc5_:Array = null;
         var _loc8_:TextField = null;
         var _loc9_:* = 0;
         var _loc11_:* = 0;
         var _loc4_:LOL_StarLevel = null;
         var _loc1_:String = null;
         var _loc14_:LOL_Button = null;
         var _loc16_:Image = null;
         var _loc15_:LOL_Button = null;
         var _loc7_:LOL_TextField = null;
         if(_uiMain)
         {
            StarlingTools.removeChildrenClear(_uiMain);
         }
         if(_avatar)
         {
            _avatar.setDestinyAndDN();
            _avatar.clearDNdata();
            _loc12_ = PanelCenterDNTeam.getDestinyByDN(_avatar.id);
            mTxt_destiny.reInit("");
            mTxt_destiny.reInit(Tools.formatHtmlTextBr(_loc12_.htmlArr));
            _loc3_ = new Sprite();
            _loc3_.touchable = false;
            _loc3_.x = _bg1.x - 3;
            _loc3_.y = _bg1.y + 5;
            _uiMain.addChild(_loc3_);
            _loc2_ = new LOL_TextField(_avatar.avatarData.name,150,50);
            _loc2_.fontSize = 30;
            _loc2_.fontColor = 16777215;
            _loc2_.hAlign = "center";
            _loc2_.shadowFilter();
            _loc2_.x = (GlobalData.$mStageWidth - _loc2_.width) * 0.5 - 5;
            _loc2_.y = _loc3_.y - 5;
            _uiMain.addChild(_loc2_);
            _loc6_ = GlobalFunction.createImage("UI_tag_0_000" + (String(_avatar.avatarData.damageType - 1)));
            _loc6_.x = 10;
            _loc3_.addChild(_loc6_);
            _loc10_ = GlobalFunction.createImage("UI_tag_1_000" + (String(_avatar.avatarData.signType - 1)));
            _loc10_.x = _loc6_.x + int((_loc6_.width - _loc10_.width) * 0.5);
            _loc10_.y = _loc6_.y + int((_loc6_.height - _loc10_.height) * 0.5) - 1;
            _loc3_.addChild(_loc10_);
            _loc13_ = GlobalLanguageStr.getLanguageStr(20166);
            _loc5_ = _loc13_.split("|");
            _loc8_ = GlobalTextStyle.getTextField(_loc5_[_avatar.avatarData.actionType - 1],25,16777215,"left",160,46);
            _loc8_.x = _loc6_.width + 15;
            _loc8_.y = _loc6_.y - 2;
            _loc8_.touchable = true;
            _loc3_.addChild(_loc6_);
            _loc3_.addChild(_loc10_);
            _loc3_.addChild(_loc8_);
            _loc9_ = uint(_avatar.getStar());
            _loc11_ = uint(_avatar.avatarData.getMaxStar());
            _loc4_ = new LOL_StarLevel(_loc9_,_loc11_,0.35);
            _loc4_.pivotX = _loc4_.width;
            _loc4_.x = GlobalData.$mStageWidth - 50;
            _loc4_.y = _bg1.y + 23;
            _uiMain.addChild(_loc4_);
            _loc1_ = _avatar.resId.indexOf(".") > -1 ? _avatar.resId.slice(0,_avatar.resId.length - 1) : _avatar.resId;
            _loc14_ = new LOL_Button("",_loc1_.split("|")[0]);
            _loc14_.pivotX = _loc14_.width / 2;
            _loc14_.pivotY = _loc14_.height * 0.9;
            _loc14_.x = GlobalData.$mStageWidth / 2;
            _loc14_.y = _bg1.height / 3 * 2;
            _loc14_.addEventListener("triggered",role1_Triggered);
            _uiMain.addChildAt(_loc14_,0);
            if(_avatar.morph)
            {
               _loc16_ = DisplayTools.newImg("z_morph");
               _loc16_.x = GlobalData.$mStageWidth / 2;
               _loc16_.y = _loc14_.y + 10;
               _loc16_.scaleX = _loc16_.scaleY = 0.75;
               _loc16_.alpha = 1;
               _uiMain.addChild(_loc16_);
            }
         }
         else
         {
            _loc15_ = new LOL_Button("","UI_bg_herobg0000");
            _loc15_.pivotX = _loc15_.width / 2;
            _loc15_.pivotY = _loc15_.height / 2;
            _loc15_.x = GlobalData.$mStageWidth / 2;
            _loc15_.y = mImg9_baseBg.y + 300;
            _loc15_.addEventListener("triggered",role1_Triggered);
            _uiMain.addChild(_loc15_);
            _loc7_ = new LOL_TextField(GlobalLanguageStr.getLanguageStr(10127),200,60);
            _loc7_.shadowFilter();
            _loc7_.fontSize = 25;
            _loc7_.fontColor = 16777215;
            _loc7_.pivotX = _loc7_.width / 2;
            _loc7_.pivotY = _loc7_.height / 2;
            _loc7_.x = GlobalData.$mStageWidth / 2 + 40;
            _loc7_.y = _loc15_.y + 10;
            _uiMain.addChild(_loc7_);
         }
      }

      private function role1_Triggered(param1:Event) : void
      {
         GlobalData.$tempChangeAvatarTitle = GlobalLanguageStr.getLanguageStr(90452);
         GlobalData.$tempTeamSelect = mData_noChange;
         PanelTeamAvatar.$tabBarSelectedIndex = 1;
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_team_avatar",false,true,"dn");
      }

      override protected function up_Triggered(param1:Event) : void
      {
         var _loc5_:Object = null;
         var _loc4_:String = null;
         var _loc3_:int = int(GlobalData.$mConfig_simple.dn_lv);
         var _loc8_:int = int(mData_noChange["dnlv"]);
         var _loc7_:Boolean = _loc8_ >= _loc3_;
         var _loc6_:String = mData_noChange["indexID_s"];
         var _loc2_:Array = GlobalData.$mConfig_simple.dn[_loc6_] as Array;
         var _loc9_:Object = getDNaddValue(_loc6_,[_loc8_]);
         if(_loc7_)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90513,_loc3_));
            return;
         }
         if(GlobalData.$userData.attrs.dn_stone >= _loc9_.stone)
         {
            _loc5_ = {
               "ok":sendService_lvup,
               "no":GlobalFunction.functionNull
            };
            _loc4_ = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90430,_loc9_.stone),GlobalTextStyle.COLOR_W_Y_Y_G,20);
            GlobalFunction.popAlert("",_loc4_,_loc5_);
         }
         else
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90431,_loc9_.stone));
         }
      }

      private function sendService_lvup() : void
      {
         if(stage == null || mData_noChange == null || SendAndSelect.checkRepeat("user.dn_lvup",""))
         {
            return;
         }
         mDNOperation++;
         var _op:uint = mDNOperation;
         var _epoch:uint = mDNViewEpoch;
         var _key:String = String(mData_noChange["indexID_s"]);
         var _requestedLv:int = int(mData_noChange["dnlv"]);
         SendServiceAMFFun.send_user_dn_lvup(function(param1:Object):void
         {
            re_dn_lvup(param1,_op,_epoch,_key,_requestedLv);
         },{"key":_key,"lv":_requestedLv});
      }

      private function re_dn_lvup(param1:Object, param2:uint, param3:uint, param4:String, param5:int) : void
      {
         if(GlobalFunction.isMalformedProfileReceipt(param1))
         {
            return;
         }
         if(GlobalFunction.isLegacyProfileReceipt(param1))
         {
            RpcStaticCall.$remoting.reportDiagnostic("PROFILE_RECEIPT_LEGACY|method=user.dn_lvup");
         }
         if(param2 != mDNOperation || param3 != mDNViewEpoch || mData_noChange == null || param4 != String(mData_noChange["indexID_s"]))
         {
            return;
         }
         GlobalData.$mEventDispatcher.dispatchEventWith("update_dn_team_ui");
         GlobalData.$mEventDispatcher.dispatchEventWith("update_team_power");
         if(stage == null)
         {
            return;
         }
         SoundManager.getOnlyExample().playSound("doorOpen");
         update();
         var _loc5_:Sprite = LayoutUIAnimation.getOnlyExample().popSuperWord("50006",1,0.6,0,1);
         _loc5_.y = _loc5_.y + 50;
         var _loc2_:int = int(GlobalData.$mConfig_simple.dn_lv);
         var _loc4_:int = int(mData_noChange["dnlv"]);
         var _loc3_:Boolean = _loc4_ >= _loc2_;
         if(_loc3_)
         {
            _up.enabled = false;
         }
         else
         {
            _up.enabled = true;
         }
      }

      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         mDNViewEpoch++;
         mDNOperation++;
         super.onREMOVED_FROM_STAGE(param1);
      }

      override protected function update() : void
      {
         updateDN_lv();
         updateUI();
      }

      override protected function CHANGE_TEAM_MEMBER(param1:Event) : void
      {
         GlobalData.$tempTeamSelect = mData_noChange = GlobalData.$userData.attrs.dn[mData_noChange["indexID_s"]];
         GlobalData.$mEventDispatcher.dispatchEventWith("update_dn_team_ui");
         super.onCLOSE_PANEL_SELF();
      }

      private function updateDN_lv() : void
      {
         var _maxLv:int = int(GlobalData.$mConfig_simple.dn_lv);
         var _lv:int = int(mData_noChange["dnlv"]);
         var _isMaxLv:Boolean = _lv >= _maxLv;
         var _key:String = mData_noChange["indexID_s"];
         var _cfg:Array = GlobalData.$mConfig_simple.dn[_key] as Array;
         var _data:Object = getDNaddValue(_key,[_lv]);
         var _currP:Number = Number(_data.currP);
         var _nextP:Number = Number(_data.nextP);
         var _attrStr:String = _data.attrStr;
         var _stone:Number = Number(_data.stone);
         var _arr:Array = [Tools.formatLineX(GlobalLanguageStr.getLanguageStr(25038,GameMapTools.toPercentage(_currP) + _attrStr),GlobalTextStyle.COLOR_0x4B2C1B_171717,MainConfig.$isEA ? 22 : 20,20),_isMaxLv ? "" : Tools.formatLineX(GlobalLanguageStr.getLanguageStr(25039,GameMapTools.toPercentage(_nextP) + _attrStr),GlobalTextStyle.COLOR_0x4B2C1B_171717,20,20),Tools.formatLineX(_isMaxLv ? GlobalLanguageStr.getLanguageStr(90513,_maxLv) : GlobalLanguageStr.getLanguageStr(25040,_stone),GlobalTextStyle.COLOR_4B2C1B_99_0033_FFFF,20,20)];
         if(mTxt_dnLv)
         {
            mTxt_dnLv.text = Tools.formatHtmlTextBr(_arr);
            mTxt_dnLv.mLayoutFun = function():void
            {
               _rec = mTxt_dnLv.getTextSnapshotFrame();
               mTxt_dnLv.x = mIcon_dn.x + mIcon_dn.width - 20;
               mTxt_dnLv.y = (_bg2.height - _rec.height) / 2;
            };
         }
      }
   }
}
