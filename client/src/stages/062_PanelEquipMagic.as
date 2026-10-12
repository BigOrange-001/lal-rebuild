package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.equip.Equip;
   import com.meng52.game.ui.element.ItemEquip;
   import com.meng52.game.ui.element.ItemMagicIcon;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_IconText;
   import com.meng52.game.ui.element.LOL_MagicButton;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import flash.geom.Rectangle;
   import starling.animation.Juggler;
   import starling.animation.Tween;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.EnterFrameEvent;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.extensions.ColorArgb;
   import starling.extensions.PDParticleSystem;
   import starling.text.TextField;
   
   public class PanelEquipMagic extends PanelEquipRise
   {
      
      private var mTxt_self:TextField;
      
      private var mBox_icon:Sprite;
      
      private var mBtn_help:LOL_Button;
      
      private var mQuad_bg:Quad;
      
      private var mArr_icon:Array;
      
      private var mStatus_toMagic:Boolean;
      
      private var _txt:LOL_IconText;
      
      private var _spRule:Sprite;
      
      public function PanelEquipMagic()
      {
         super();
      }
      
      public static function getMagicUIs(param1:int, param2:Array, param3:Boolean = true) : Sprite
      {
         var _loc18_:Image = null;
         var _loc13_:TextField = null;
         var _loc5_:Sprite = new Sprite();
         var _loc16_:String = "UI_magic_icon_lv_000";
         var _loc15_:int = 0;
         var _loc10_:int = int(param2.length);
         var _loc17_:int = 0;
         var _loc12_:Boolean = false;
         var _loc11_:Boolean = false;
         var _loc7_:int = 0;
         var _loc6_:Number = 0;
         var _loc9_:Number = 0;
         var _loc14_:Number = 17;
         var _loc8_:Number = param3 ? 14 : 20;
         var _loc4_:Number = param3 ? 67 : 109;
         _loc15_ = 0;
         while(_loc15_ < _loc10_)
         {
            _loc17_ = int(param2[_loc15_]);
            if(_loc17_ > 0)
            {
               _loc18_ = GlobalFunction.createImage(_loc16_ + _loc15_);
               _loc14_ = _loc18_.width;
               if(param3)
               {
                  _loc18_.scaleX = _loc18_.scaleY = 0.57;
                  _loc14_ = _loc18_.width;
               }
               _loc7_ = _loc15_ % 2;
               _loc18_.x = _loc7_ * (_loc18_.width + _loc4_);
               if(_loc7_ == 0)
               {
                  _loc6_ += _loc17_;
                  _loc12_ = true;
               }
               if(_loc7_ != 0)
               {
                  _loc9_ += _loc17_;
                  _loc11_ = true;
               }
               _loc5_.addChild(_loc18_);
            }
            _loc15_++;
         }
         if(_loc12_)
         {
            _loc13_ = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(98149) + "+" + _loc6_,_loc8_,16777215,"left",_loc4_ + 20,35);
            _loc13_.x = _loc14_;
            _loc13_.y = -2;
            _loc5_.addChild(_loc13_);
         }
         if(_loc11_)
         {
            _loc13_ = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(98150) + "+" + _loc9_,_loc8_,16777215,"left",_loc4_ + 20,35);
            _loc13_.x = _loc14_ * 2 + _loc4_;
            _loc13_.y = -2;
            _loc5_.addChild(_loc13_);
         }
         return _loc5_;
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         setPopPanelBg(GlobalLanguageStr.getLanguageStr(98146));
         initOtherUIs();
      }
      
      override public function onTRIGGERED_closePanel(param1:Event) : void
      {
         GlobalData.$mEventDispatcher.dispatchEventWith("update_equip_list_data");
         super.onTRIGGERED_closePanel(null);
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(mQuad_bg)
         {
            mQuad_bg.removeEventListener("touch",onTOUCH_icon);
            mQuad_bg.removeFromParent(true);
         }
         if(mBtn_help)
         {
            mBtn_help.removeFromParent(true);
         }
         if(mTxt_self)
         {
            mTxt_self.removeFromParent(true);
         }
         if(mBox_icon)
         {
            StarlingTools.removeChildrenClear(mBox_icon);
            mBox_icon.removeFromParent(true);
         }
         if(_spRule)
         {
            _spRule.removeEventListener("touch",onTRIGGERED_help);
         }
         super.onREMOVED_FROM_STAGE(param1);
         mTxt_self = null;
         mBox_icon = null;
         mBtn_help = null;
         mQuad_bg = null;
         GlobalData.$tempEquipCurrSelected = "";
      }
      
      override public function initOtherUIs() : void
      {
         mStatus_toMagic = false;
         mPrice_num = 0;
         mCurr_lv = 0;
         var _loc3_:Number = 150;
         var _loc1_:Number = 130;
         var _loc6_:Number = 130;
         mJuggler_upLv = new Juggler();
         addEventListener("enterFrame",onENTER_FRAME_clip);
         mBox_equip = new Sprite();
         mBox_equip.x = 70;
         mBox_equip.y = 112;
         addChild(mBox_equip);
         var _loc5_:Object = GlobalData.$userData.my_equips[GlobalData.$tempEquipCurrSelected];
         var _loc4_:Boolean = _loc5_ != null;
         _loc5_ = _loc5_ == null ? {} : _loc5_;
         _loc5_["status"] = -1;
         _loc5_["score"] = _loc4_;
         _loc5_["id"] = _loc5_ == null ? null : GlobalData.$tempEquipCurrSelected;
         mCurrEquip = new ItemEquip();
         mCurrEquip.data = _loc5_;
         mBox_equip.addChild(mCurrEquip);
         if(!_loc4_)
         {
            setChangeStatusUI();
            return;
         }
         setMyDustUIs();
         mBox_data = new Sprite();
         mBox_data.touchable = false;
         mBox_data.x = 125;
         mBox_equip.addChild(mBox_data);
         setTxt(mBox_data);
         mBox_team = new Sprite();
         addChild(mBox_team);
         setDustBtn(mBox_team);
         setIcon();
         var _loc2_:Object = GlobalFunction.get_HelpLink(GlobalLanguageStr.getLanguageStr(90203));
         _spRule = _loc2_.ui;
         _spRule.x = _width - _loc2_.w - 40;
         _spRule.y = 88;
         addChild(_spRule);
         _spRule.addEventListener("touch",onTRIGGERED_help);
      }
      
      private function onTRIGGERED_help(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(_spRule);
         if(_loc2_)
         {
            if(_loc2_.phase == "ended")
            {
               GlobalFunction.popPanelHelp(MainConfig.SERVER_ADDRESS_HELP_ADD_MAGIC);
            }
         }
      }
      
      private function setTxt(param1:Sprite, param2:Boolean = false) : void
      {
         var _loc5_:Sprite = null;
         if(param2)
         {
            StarlingTools.removeChildrenClear(param1);
         }
         var _loc4_:String = GlobalData.$tempEquipCurrSelected;
         var _loc3_:Object = GlobalData.$userData.my_equips[_loc4_];
         var _loc9_:int = 0;
         var _loc8_:String = "";
         var _loc7_:Equip = null;
         if(_loc3_ != null)
         {
            _loc7_ = new Equip(_loc4_,_loc3_);
            _loc9_ = _loc7_.lv;
            _loc8_ = _loc7_.equipData.name;
         }
         var _loc12_:int = 34;
         var _loc10_:int = GlobalData.$mStageWidth * 0.8;
         var _loc11_:TextField = GlobalTextStyle.getTextField(_loc8_,20,16777215,"left",_loc10_,46);
         param1.addChild(_loc11_);
         if(_loc3_ == null)
         {
            return;
         }
         var _loc6_:TextField = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20079,_loc9_),20,16777215,"left",_loc10_,46);
         _loc6_.y = _loc11_.y + _loc12_;
         param1.addChild(_loc6_);
         if(_loc7_.symp >= 0)
         {
            _loc5_ = getMagicUIs(_loc7_.symp,_loc7_.magic,false);
            _loc5_.y = _loc6_.y + _loc12_;
            param1.addChild(_loc5_);
         }
      }
      
      private function setMyDustUIs(param1:Boolean = false) : void
      {
         var _loc2_:String = null;
         if(mBox_dataUp == null)
         {
            mBox_dataUp = PanelEquipSellSelect.getDustUIs();
            _loc2_ = GlobalLanguageStr.getLanguageStr(20458);
            _txt = new LOL_IconText(_loc2_);
            _txt.x = 25;
            _txt.y = mImg9_baseBg.height - _txt.height - 25 - 3;
            _txt.bgWidth = 585;
            addChild(_txt);
            addChild(mBox_dataUp);
            mBox_dataUp.x = 140;
            mBox_dataUp.y = 665;
         }
         if(param1)
         {
            PanelEquipSellSelect.updateDustNum(mBox_dataUp);
         }
      }
      
      private function setDustBtn(param1:Sprite, param2:Boolean = false, param3:int = 0) : void
      {
         var _loc14_:LOL_MagicButton = null;
         if(param2)
         {
            StarlingTools.removeChildrenClear(param1);
         }
         var _loc11_:String = GlobalData.$tempEquipCurrSelected;
         var _loc9_:Object = GlobalData.$userData.my_equips[_loc11_];
         var _loc6_:Equip = null;
         if(_loc9_ != null)
         {
            _loc6_ = new Equip(_loc11_,_loc9_);
         }
         var _loc4_:Array = [0,0,0,0];
         if(_loc6_ != null)
         {
            _loc4_ = _loc6_.magic;
         }
         var _loc8_:int = 0;
         var _loc7_:int = int(_loc4_.length);
         var _loc12_:Number = 150;
         var _loc5_:int = 0;
         var _loc13_:int = 0;
         _loc8_ = 0;
         while(_loc8_ < _loc7_)
         {
            _loc5_ = _loc8_ - 1;
            if(_loc5_ < 0 || _loc5_ >= 0 && _loc4_[_loc5_] > 0)
            {
               _loc14_ = new LOL_MagicButton(_loc8_,_loc4_,toMagic,param2,param3);
               _loc14_.x = _loc8_ * _loc12_;
               _loc14_.y = 0;
               param1.addChild(_loc14_);
               _loc13_ += 1;
            }
            _loc8_++;
         }
         param1.x = int((GlobalData.$mStageWidth - _loc12_ * _loc13_ + _loc12_) * 0.5);
         var _loc10_:Number = GlobalData.formatVScaleY_center(150) + 20;
         param1.y = 665 - _loc10_;
      }
      
      public function toMagic(param1:int) : void
      {
         var _fun:Object;
         var _index:int = param1;
         var gotoEquipSell:* = function():void
         {
            onCLOSE_PANEL_SELF(null);
            GlobalData.$tempEquipFunId = 4;
            GlobalData.$mEventDispatcher.dispatchEventWith("update_panel_equipbase_index");
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_change_base");
         };
         var gotoEquipMagic:* = function():void
         {
            SendServiceAMFFun.send_user_add_magic(re_add_magic,{
               "eqid":_eid,
               "color":_index,
               "dust":_pay
            });
         };
         var _eid:String = GlobalData.$tempEquipCurrSelected;
         var _equipData:Object = GlobalData.$userData.my_equips[_eid];
         var _pay:int = int(GlobalData.$mConfig_simple.dust.add_magic[0][_index]);
         var _myDust:int = int(GlobalData.$userData.attrs.dust[_index]);
         var _dustStr:Array = GlobalLanguageStr.getLanguageStr(90197).split("$");
         var _color:uint = uint(LOL_MagicButton.TXT_COLOR[_index]);
         var _str:String = "";
         if(_myDust >= _pay)
         {
            if(!mStatus_toMagic)
            {
               mStatus_toMagic = true;
               _str = GlobalLanguageStr.getLanguageStr(90202,_pay,_dustStr[_index],GlobalLanguageStr.getLanguageStr(LOL_MagicButton.TXT_STR[_index]));
               _fun = {
                  "ok":gotoEquipMagic,
                  "no":GlobalFunction.functionNull,
                  "aid":"A_1098_6"
               };
               GlobalFunction.popAlert("",Tools.formatLineX(_str,[16777215,_color,_color,_color]),_fun);
            }
            else
            {
               gotoEquipMagic();
            }
         }
         else
         {
            _str = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90199,_pay,_dustStr[_index]),[16777215,_color,_color,_color]);
            _fun = {
               "ok":gotoEquipSell,
               "no":GlobalFunction.functionNull,
               "aid":"A_1098_6"
            };
            GlobalFunction.popAlert("",_str,_fun);
         }
      }
      
      private function re_add_magic(param1:Object) : void
      {
         if(GlobalFunction.isMalformedProfileReceipt(param1))
         {
            return;
         }
         if(GlobalFunction.isLegacyProfileReceipt(param1))
         {
            RpcStaticCall.$remoting.reportDiagnostic("PROFILE_RECEIPT_LEGACY|method=user.add_magic");
         }
         var _requestParams:Object = param1["params"];
         var _requestEquipId:String = _requestParams == null ? "" : String(_requestParams["eqid"]);
         if(mCurrEquip == null || _requestEquipId == "" || mCurrEquip.data.id != _requestEquipId)
         {
            return;
         }
         var _loc18_:Object = null;
         var _loc16_:Boolean = false;
         var _loc6_:Equip = new Equip(mCurrEquip.data.id);
         var _loc14_:int = _loc6_.symp;
         SoundManager.getOnlyExample().playSound("E_9020",1.5);
         var _loc15_:Object = param1["params"];
         var _loc5_:int = int(_loc15_["color"]);
         var _loc12_:String = _loc15_["eqid"];
         if(GlobalData.$userData.my_equips[_loc12_] == null)
         {
            return;
         }
         var _loc10_:int = int(GlobalData.$userData.my_equips[_loc12_]["symp"] == null ? -1 : GlobalData.$userData.my_equips[_loc12_]["symp"]);
         var _loc2_:int = int(GlobalData.$userData.my_equips[_loc12_]["symp"] == null ? -1 : GlobalData.$userData.my_equips[_loc12_]["symp"]);
         setMyDustUIs(true);
         setTxt(mBox_data,true);
         setDustBtn(mBox_team,true,_loc5_);
         var _loc4_:Array = GlobalData.$userData.my_equips[_loc12_]["magic"];
         var _loc17_:Array = GlobalLanguageStr.getLanguageStr(90197).split("$");
         var _loc7_:uint = uint(LOL_MagicButton.TXT_COLOR[_loc5_]);
         var _loc19_:String = GlobalLanguageStr.getLanguageStr(98140 + _loc5_);
         var _loc13_:String = "";
         if(mCurrEquip)
         {
            _loc13_ = GlobalLanguageStr.getLanguageStr(90201,GlobalLanguageStr.getLanguageStr(LOL_MagicButton.TXT_SYMP[_loc2_]));
            mCurrEquip.removeFromParent(true);
            mCurrEquip = null;
            _loc18_ = GlobalData.$userData.my_equips[_loc12_];
            _loc16_ = _loc18_ != null;
            _loc18_ = _loc18_ == null ? {} : _loc18_;
            _loc18_["indexID_s"] = 6;
            _loc18_["status"] = -1;
            _loc18_["score"] = _loc16_;
            _loc18_["id"] = _loc18_ == null ? null : _loc12_;
            mCurrEquip = new ItemEquip(true);
            mCurrEquip.data = _loc18_;
            mBox_equip.addChildAt(mCurrEquip,0);
         }
         GlobalData.$tempTeamPowerTemp = GlobalFunction.getTeamPower(GlobalData.$userData.team[0]);
         _loc6_ = new Equip(mCurrEquip.data.id);
         if(_loc6_.symp != _loc14_)
         {
            showSymp();
         }
         if(!stage || !mCurrEquip)
         {
            return;
         }
         var _loc3_:Rectangle = mCurrEquip.getBounds(stage);
         var _loc8_:int = _loc3_.x + 51;
         var _loc9_:int = _loc3_.y + 51;
      }
      
      private function setIcon() : void
      {
         var _loc4_:ItemMagicIcon = null;
         if(mBox_icon == null)
         {
            mArr_icon = [];
            mBox_icon = new Sprite();
            addChild(mBox_icon);
            mQuad_bg = Tools.newQuad(GlobalData.$mStageWidth,150,0,0,16777215);
            mQuad_bg.alpha = 0;
            mQuad_bg.x = -GlobalData.$mStageWidth * 0.5;
            mQuad_bg.y = -25;
            mBox_icon.addChild(mQuad_bg);
            mQuad_bg.addEventListener("touch",onTOUCH_icon);
         }
         var _loc5_:int = 0;
         var _loc3_:int = 5;
         var _loc2_:Equip = new Equip(mCurrEquip.data.id);
         var _loc1_:int = (_loc2_.symp + _loc3_) % _loc3_;
         _loc5_ = 0;
         while(_loc5_ < _loc3_)
         {
            _loc4_ = new ItemMagicIcon(_loc5_,(_loc1_ + 4) * 3.141592653589793 * 2 / _loc3_);
            mArr_icon.push(_loc4_);
            mBox_icon.addChild(_loc4_);
            _loc5_++;
         }
         mBox_icon.x = GlobalData.$mStageWidth * 0.5;
         mBox_icon.y = _height - mBox_icon.height - 300;
         showSymp();
      }
      
      private function showSymp() : void
      {
         var _loc3_:Tween = null;
         var _loc9_:Number = NaN;
         var _loc4_:Number = NaN;
         var _loc8_:ItemMagicIcon = null;
         SoundManager.getOnlyExample().playSound("E_8008",0.5);
         var _loc1_:Juggler = GlobalData.$mStarling.juggler;
         var _loc10_:int = 0;
         var _loc7_:int = 5;
         var _loc6_:Equip = new Equip(mCurrEquip.data.id);
         var _loc5_:int = (_loc6_.symp + _loc7_) % _loc7_;
         var _loc2_:Array = [];
         _loc10_ = 0;
         while(_loc10_ < _loc7_)
         {
            _loc2_.push(mArr_icon[(_loc10_ + _loc5_) % _loc7_]);
            _loc10_++;
         }
         _loc10_ = 0;
         while(_loc10_ < _loc7_)
         {
            _loc8_ = _loc2_[_loc10_];
            _loc1_.removeTweens(_loc8_);
            _loc3_ = new Tween(_loc8_,1,"easeOut");
            _loc9_ = _loc8_.radian;
            _loc4_ = Math.ceil(_loc9_ / (3.141592653589793 * 2)) * 3.141592653589793 * 2 + _loc10_ * 3.141592653589793 * 2 / _loc7_;
            if(_loc4_ <= _loc9_)
            {
               _loc4_ += 3.141592653589793 * 2;
            }
            if(_loc4_ - 3.141592653589793 * 2 > _loc9_)
            {
               _loc4_ -= 3.141592653589793 * 2;
            }
            _loc3_.animate("radian",_loc4_);
            _loc1_.add(_loc3_);
            if(_loc10_ == 2 || _loc10_ == 3)
            {
               mBox_icon.setChildIndex(_loc8_,1);
            }
            else if(_loc10_ == 0)
            {
               mBox_icon.setChildIndex(_loc8_,mBox_icon.numChildren - 1);
            }
            _loc10_++;
         }
      }
      
      private function onTOUCH_icon(param1:TouchEvent) : void
      {
         var _loc3_:Touch = null;
         var _loc10_:String = null;
         var _loc4_:Equip = null;
         var _loc7_:String = null;
         var _loc5_:String = null;
         var _loc16_:String = null;
         var _loc15_:String = null;
         var _loc8_:int = 0;
         var _loc14_:Array = null;
         var _loc6_:int = 0;
         var _loc12_:Array = null;
         var _loc11_:Array = null;
         var _loc13_:int = 0;
         var _loc9_:int = 0;
         var _loc2_:String = null;
         if(mQuad_bg)
         {
            _loc3_ = param1.getTouch(mQuad_bg);
            if(_loc3_)
            {
               if(_loc3_.phase != "began")
               {
                  if(_loc3_.phase == "ended")
                  {
                     _loc10_ = GlobalData.$tempEquipCurrSelected;
                     _loc4_ = new Equip(_loc10_);
                     _loc7_ = _loc4_.getSympStr();
                     _loc5_ = _loc4_.getSympTypeStr();
                     _loc16_ = GlobalLanguageStr.getLanguageStr(90205,_loc7_);
                     _loc15_ = "";
                     _loc14_ = GlobalData.$mConfig_simple.dust.symp[1];
                     _loc6_ = int(_loc14_.length);
                     _loc12_ = [16777215,6710886,16776960,_loc4_.getSympColor()];
                     _loc11_ = [6710886,6710886,6710886,6710886];
                     _loc2_ = GlobalFunction.checkEquipHasUsed(_loc4_.id) + "";
                     if(_loc2_.length == 1)
                     {
                        _loc2_ = "0";
                     }
                     else
                     {
                        _loc2_ = _loc2_.split("")[0];
                     }
                     if(_loc4_.symp >= 0)
                     {
                        _loc8_ = 0;
                        while(_loc8_ < _loc6_)
                        {
                           _loc13_ = 2 + _loc8_;
                           _loc9_ = _loc13_ * GlobalData.$mConfig_simple.dust.symp[1][_loc13_ - 2] * GlobalData.$mConfig_simple.dust.symp[0][_loc4_.symp];
                           if(GlobalFunction.checkIsSympSameCount(_loc4_.id,_loc4_.symp,int(_loc2_)) >= _loc13_)
                           {
                              _loc15_ += Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90206,_loc8_ + 2,_loc7_,_loc5_,_loc9_) + "\n",_loc12_);
                           }
                           else
                           {
                              _loc15_ += Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90206,_loc8_ + 2,_loc7_,_loc5_,_loc9_) + "\n",_loc11_);
                           }
                           _loc8_++;
                        }
                     }
                     _loc15_ += Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90207),_loc11_);
                     GlobalFunction.popAlert(_loc16_,_loc15_);
                  }
               }
            }
         }
      }
      
      override protected function onENTER_FRAME_clip(param1:EnterFrameEvent) : void
      {
         super.onENTER_FRAME_clip(param1);
         if(mBox_icon && mArr_icon.length > 0)
         {
         }
      }
      
      override protected function setChangeStatusUI() : void
      {
         var _loc2_:ColorArgb = null;
         var _loc1_:ColorArgb = null;
         if(mBox_equip)
         {
            mBox_equip.x = int((GlobalData.$mStageWidth - 100) * 0.5);
            mBox_equip.y = int((GlobalData.$center_height_curr - 121 - 100) * 0.5);
            mParticleSystem = new PDParticleSystem(GlobalData.$assetManager.getXml("drugs"),GlobalFunction.getTexture("drugs_particle"));
            mParticleSystem.x = 50;
            mParticleSystem.y = 50;
            _loc2_ = ColorArgb.fromArgb(16737535);
            _loc1_ = ColorArgb.fromArgb(10040319);
            mParticleSystem.startColor = new ColorArgb(_loc2_.red,_loc2_.green,_loc2_.blue,0.76);
            mParticleSystem.startColorVariance = new ColorArgb(_loc2_.red,_loc2_.green,_loc2_.blue,0.08);
            mParticleSystem.endColor = new ColorArgb(_loc1_.red,_loc1_.green,_loc1_.blue,0.2);
            mBox_equip.addChildAt(mParticleSystem,0);
            mJuggler_upLv.add(mParticleSystem);
            mParticleSystem.start();
            checkGuide();
         }
      }
   }
}

