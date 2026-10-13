package com.meng52.game.ui.element
{
   import com.meng52.display.ScrollScreenForTxt;
   import com.meng52.game.command.avatar.AvatarData;
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.map.GameMapTools;
   import com.meng52.game.module.skill.SkillSet;
   import com.meng52.game.module.talent.Talent;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.panel.PanelDetailAvatar;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import starling.animation.Juggler;
   import starling.animation.Tween;
   import starling.display.Image;
   import starling.display.MovieClip;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;

   public class LOL_DetailAvatar extends Sprite
   {

      private var _data:*;

      private var _avatar:Avatar;

      private var _topBg:Image;

      private var _bg1Spr:Sprite;

      private var _bg1:Image;

      private var _bg2:Scale9Image;

      private var _roleMain:Sprite;

      private var _uiMain:Sprite;

      private var _euqipMain:Sprite;

      private var _icon:Image;

      private var _iconBg:Scale9Image;

      public var mTxt_destiny:ScrollScreenForTxt;

      private var _juggler:Juggler = new Juggler();

      private var _tween:Tween;

      public var mAvatar:Avatar;

      private var mDestinyBox:Sprite;

      private var _width:int;

      private var _height:int;

      private var _type:String;

      private var _topXY:Rectangle;

      private var mBox_P:Sprite;

      private var _lockImg:LOL_Button;

      private var _lock:Boolean = false;

      private var _powerTxt:LOL_IconText;

      private var _bgY:int;

      private var _numY:Number;

      private var _quadRole:Quad;

      private var _quadPith:Quad;

      private var _quadSkill1:Quad;

      private var _quadSkill2:Quad;

      private var _quadType:Quad;

      private var _isShowLock:Boolean = false;

      private var _playRoleSound:Boolean = true;

      private var _quadFoster1:Quad;

      private var _quadFoster2:Quad;

      private var mFoster:LOL_TextField;

      private var mFoster2:LOL_TextField;

      private var skillPassiveBtn:LOL_Scale9Button;

      private var skillPassiveTxt:LOL_TextField;

      private var _quadSkillPassive:Quad;

      private var txtSkillDescPassive:LOL_TextField;

      private var talentSp:Sprite;

      private var talentQuad:Quad;

      private var _glowMc:MovieClip;

      public function LOL_DetailAvatar(param1:*, param2:int = 640, param3:int = 640, param4:* = "show_type_main", param5:Boolean = false, param6:Boolean = true)
      {
         super();
         addEventListener("addedToStage",ADDED_TO_STAGE);
         _data = param1;
         _width = param2;
         _height = param3;
         _type = param4;
         _isShowLock = param5;
         _playRoleSound = param6;
         if(_data.id != "" && _data.id != null)
         {
            if(_data is Avatar)
            {
               _avatar = _data as Avatar;
            }
            else
            {
               _avatar = new Avatar(_data.id,_data);
            }
         }
      }

      private function ADDED_TO_STAGE(param1:Event) : void
      {
         removeEventListener("addedToStage",ADDED_TO_STAGE);
         addEventListener("removedFromStage",REMOVED_FROM_STAGE);
         init();
         bind(_data,_playRoleSound);
      }

      private function init() : void
      {
         _topXY = null;
         _bg1 = GlobalFunction.createImage("UI_bg_0_10_",true);
         _bg1.touchable = false;
         if(_type == "show_type_dynamic")
         {
            _topBg = GlobalFunction.createImage("UI_bg_top_1_0000");
            _topBg.x = 0;
            _topBg.y = 25;
            _topBg.width = _width;
            addChild(_topBg);
            _topXY = new Rectangle(0,25,_topBg.width,_topBg.height);
            _bgY = 150;
         }
         else if(_type == "show_type_team")
         {
            _topBg = GlobalFunction.createImage("UI_bg_top_1_0000");
            _topBg.x = 0;
            _topBg.y = 25;
            _topBg.width = _width;
            addChild(_topBg);
            _topXY = new Rectangle(0,25,_topBg.width,_topBg.height);
            _bgY = Math.abs((GlobalData.$center_height_curr - 121 - _topXY.height - _bg1.height) / 2 - 20);
         }
         else
         {
            _topXY = new Rectangle(0,25,_width,0);
            _bgY = (_bg1.height - (_height - 510) - 140) / 2 - 120;
         }
         _bg1Spr = new Sprite();
         _bg1Spr.addChild(_bg1);
         _bg1Spr.clipRect = new Rectangle((_bg1.width - _width) / 2,_bgY,_width,640);
         _bg1Spr.x = -(_bg1.width - _width) / 2;
         _bg1Spr.y = _topXY.y + _topXY.height - _bgY;
         addChild(_bg1Spr);
         _bg2 = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",_topXY.width,180,new Rectangle(110,55,70,20));
         _bg2.x = (_width - _bg2.width) * 0.5 + 1;
         _bg2.y = _height - _bg2.height;
         _bg2.touchable = false;
         addChild(_bg2);
         _roleMain = new Sprite();
         _bg1Spr.addChild(_roleMain);
         _icon = GlobalFunction.createImage("UI_icon_1_0000");
         _icon.x = _bg2.x + 5;
         _icon.y = _bg2.y - _icon.height;
         _icon.touchable = false;
         addChild(_icon);
         _iconBg = GlobalFunction.createScale9Image("UI_bg_9slice_5_0000",_width - _icon.width - 30,95,new Rectangle(30,20,50,30));
         _iconBg.x = _icon.x + _icon.width + 10;
         _iconBg.y = _icon.y + 2;
         _iconBg.touchable = false;
         addChild(_iconBg);
         mTxt_destiny = new ScrollScreenForTxt("",_iconBg.width - 20,_iconBg.height - 25);
         mTxt_destiny.x = _iconBg.x + 15;
         mTxt_destiny.y = _iconBg.y + 10;
         mTxt_destiny.touchable = true;
         addChild(mTxt_destiny);
         _uiMain = new Sprite();
         addChild(_uiMain);
         _euqipMain = new Sprite();
         addChild(_euqipMain);
      }

      private function talentTouch(param1:TouchEvent) : void
      {
         var _loc4_:Talent = null;
         var _loc5_:String = null;
         var _loc2_:String = null;
         var _loc3_:Touch = param1.getTouch(this);
         if(_loc3_ && _loc3_.phase == "ended")
         {
            if(_avatar && _avatar.talent != null)
            {
               _loc4_ = new Talent(_avatar.talent.id);
            }
            _loc5_ = _loc4_.my_HaloData.name;
            _loc2_ = _loc4_.my_HaloData.info + "\n" + GlobalLanguageStr.getLanguageStr(98041) + "\n";
            _loc2_ = Tools.formatLineX(_loc2_,GlobalTextStyle.COLOR_W_R_R_R);
            GlobalFunction.popAlert(_loc5_,_loc2_,{"res":_avatar.resId});
         }
      }

      public function getRoleRect(param1:int, param2:int) : Rectangle
      {
         return new Rectangle(90 + param1,_topXY.y + 50 + param2,430,310);
      }

      private function quadRole_Touch(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(this,"ended");
         if(_loc2_)
         {
            role_Triggered(null);
         }
      }

      private function quadPith_Touch(param1:TouchEvent) : void
      {
         var _loc3_:String = null;
         var _loc4_:String = null;
         var _loc10_:String = null;
         var _loc2_:String = null;
         var _loc11_:int = _avatar.getCultivationDisplayScale();
         var _loc5_:Touch = param1.getTouch(this,"ended");
         var _loc9_:String = _avatar.id.split("|")[0];
         var _loc6_:Object = GlobalData.$userData.avatars[_avatar.id];
         var _loc7_:Object = GlobalData.$userData.avatars;
         var _loc8_:int = 0;
         if(_loc5_)
         {
            if(_loc6_)
            {
               if(_loc6_.pith_max)
               {
                  _loc8_ = GlobalData.$mConfig_simple.culture.max_pith_base + _loc6_.pith_max;
               }
               else
               {
                  _loc8_ = int(GlobalData.$mConfig_simple.culture.max_pith_base);
               }
            }
            else
            {
               _loc8_ = int(GlobalData.$mConfig_simple.culture.max_pith_base);
            }
            if(_loc8_ >= GlobalData.$mConfig_simple.culture.max_pith)
            {
               _loc8_ = int(GlobalData.$mConfig_simple.culture.max_pith);
            }
            _loc8_ = _avatar.getCultivationCap();
            if(_loc6_)
            {
               if(_avatar)
               {
                  _loc3_ = GlobalLanguageStr.getLanguageStr(20226);
                  _loc4_ = GlobalLanguageStr.getLanguageStr(90521,_avatar.getHpMax(-1,-1,true),_avatar.getCultivationStatGain("hp",_avatar.hpP),_avatar.getDamage(-1,-1,true),_avatar.getCultivationStatGain("ap",_avatar.apP),_avatar.getDePh(-1,-1,true),_avatar.getCultivationStatGain("de_ph",_avatar.dePhP),_avatar.getDeMa(-1,-1,true),_avatar.getCultivationStatGain("de_ma",_avatar.deMaP),_avatar.getPithNum() * _loc11_,_loc8_ * _loc11_);
                  _loc3_ += "\n" + _loc4_;
                  _loc3_ = Tools.formatLineX(_loc3_,GlobalTextStyle.COLOR_W_Y_Y_G);
                  GlobalFunction.popAlert("",_loc3_,{"aid":_loc9_},false);
                  param1.stopPropagation();
               }
            }
            else if(_loc5_)
            {
               if(_avatar)
               {
                  _loc10_ = GlobalLanguageStr.getLanguageStr(20226);
                  _loc2_ = GlobalLanguageStr.getLanguageStr(90679,_avatar.getHpMax(-1,-1,true),_avatar.hpP * _loc11_,_avatar.getDamage(-1,-1,true),_avatar.apP * _loc11_,_avatar.getDePh(-1,-1,true),_avatar.dePhP * _loc11_,_avatar.getDeMa(-1,-1,true),_avatar.deMaP * _loc11_,_avatar.getPithNum() * _loc11_);
                  _loc10_ += "\n" + _loc2_;
                  _loc10_ = Tools.formatLineX(_loc10_,GlobalTextStyle.COLOR_W_Y_Y_G);
                  GlobalFunction.popAlert("",_loc10_,{"aid":_loc9_},false);
               }
            }
         }
      }

      private function icon_Touch(param1:TouchEvent) : void
      {
         var _loc6_:Object = null;
         var _loc7_:Object = null;
         var _loc5_:int = 0;
         var _loc2_:int = 0;
         var _loc3_:String = null;
         var _loc4_:Touch = param1.getTouch(this,"ended");
         if(_loc4_)
         {
            if(_data)
            {
               _loc6_ = GlobalData.$mConfig_simple.soul_exchange;
               _loc7_ = GlobalData.$userData.avatar_soul;
               _loc5_ = int(_loc7_[_avatar.id] != null ? _loc7_[_avatar.id] : 0);
               _loc2_ = int(_loc6_.avatar[_avatar.getStar()]);
               _loc3_ = "";
               if(_loc5_ < _loc2_)
               {
                  _loc3_ = GlobalLanguageStr.getLanguageStr(90600,_loc2_ - _loc5_,_avatar.avatarData.name);
               }
               else
               {
                  _loc3_ = GlobalLanguageStr.getLanguageStr(90604,_avatar.avatarData.name);
               }
               GlobalFunction.popError(_loc3_);
            }
         }
      }

      private function setDestinyTxts(param1:Array, param2:Number = 0, param3:Number = 0, param4:Boolean = false) : void
      {
         if(param4 && mDestinyBox)
         {
            mDestinyBox.x = param2;
            mDestinyBox.y = param3;
            return;
         }
         if(mDestinyBox == null)
         {
            mDestinyBox = new Sprite();
            addChild(mDestinyBox);
         }
         else
         {
            StarlingTools.removeChildrenClear(mDestinyBox);
         }
         if(param1 == null)
         {
            return;
         }
         var _loc7_:int = 0;
         var _loc5_:int = int(param1.length);
         var _loc6_:LOL_TextField = null;
         _loc7_ = 0;
         while(_loc7_ < _loc5_)
         {
            _loc6_ = new LOL_TextField(param1[_loc7_].txt,155,30);
            _loc6_.fontColor = param1[_loc7_].isOK ? 52479 : 8947848;
            _loc6_.hAlign = "left";
            _loc6_.vAlign = "center";
            _loc6_.x = _loc7_ % 3 * 160;
            _loc6_.y = Math.floor(_loc7_ / 3) * 29;
            mDestinyBox.addChild(_loc6_);
            _loc7_++;
         }
         mDestinyBox.x = param2 - 15;
         mDestinyBox.y = param3;
      }

      public function bind(param1:*, param2:Boolean = false) : void
      {
         _playRoleSound = param2;
         if(_type == "show_type_team")
         {
            update(param1);
         }
         else
         {
            updateAll(param1);
         }
      }

      public function update(param1:*) : void
      {
         var _loc35_:int = 0;
         var _loc10_:HtmlTextField = null;
         var _loc2_:String = null;
         var _loc21_:LOL_Button = null;
         var _loc45_:Image = null;
         var _loc12_:Image = null;
         var _loc36_:Image = null;
         var _loc19_:String = null;
         var _loc8_:Array = null;
         var _loc14_:LOL_TextField = null;
         var _loc15_:* = 0;
         var _loc37_:* = 0;
         var _loc29_:LOL_StarLevel = null;
         var _loc46_:LOL_TextField = null;
         var _loc33_:int = 0;
         var _loc31_:Boolean = false;
         var _loc34_:int = 0;
         var _loc47_:String = null;
         var _loc4_:int = 0;
         var _loc41_:Array = null;
         var _loc32_:Array = null;
         var _loc7_:Image = null;
         var _loc26_:Array = null;
         var _loc38_:int = 0;
         var _loc6_:String = null;
         var _loc5_:String = null;
         var _loc9_:String = null;
         var _loc25_:String = null;
         var _loc22_:String = null;
         var _loc18_:String = null;
         var _loc20_:String = null;
         var _loc27_:LOL_Button = null;
         var _loc43_:LOL_Button = null;
         var _loc13_:LOL_TextField = null;
         _data = param1;
         if(_data.id != null && _data.id != "")
         {
            if(_data is Avatar)
            {
               _avatar = _data as Avatar;
            }
            else
            {
               _avatar = new Avatar(_data.id,_data);
            }
         }
         else
         {
            _avatar = null;
         }
         if(_quadRole)
         {
            _quadRole.removeEventListener("touch",quadRole_Touch);
            _quadRole.removeFromParent(true);
         }
         if(_quadPith)
         {
            _quadPith.removeFromParent(true);
         }
         StarlingTools.removeChildrenClear(_roleMain,false);
         StarlingTools.removeChildrenClear(_uiMain,false);
         _quadRole = new Quad(_icon.width + _iconBg.width,_iconBg.height);
         _quadRole.name = "_quadRole22";
         _quadRole.x = _icon.x;
         _quadRole.y = _icon.y;
         _quadRole.alpha = 0.01;
         _uiMain.addChild(_quadRole);
         _quadRole.addEventListener("touch",quadRole_Touch);
         _quadPith = new Quad(_bg2.width - 200,90);
         _quadPith.name = "_quadPith22";
         _quadPith.x = _bg2.x + 200;
         _quadPith.y = _bg2.y;
         _quadPith.alpha = 0.01;
         _uiMain.addChild(_quadPith);
         if(_type == "show_type_team" || _type == "show_type_dynamic")
         {
            updateEquip();
         }
         else
         {
            setDestinyTxts(null);
            mTxt_destiny.reInit("");
            _avatar.setDestinyAndDN();
            if(_type != "show_type_dynamic")
            {
               if(_avatar.id.indexOf("|") > -1)
               {
                  if(GlobalData.$userData.team[0].indexOf(_avatar.id) < 0)
                  {
                     _avatar.clearDNdata();
                  }
               }
               else
               {
                  _avatar.clearDNdata();
               }
            }
            if(!_avatar.mDestiny || _avatar.mDestiny.nameArr == null || _avatar.getPurpleBondDescription() != "")
            {
               mTxt_destiny.reInit(_avatar.getDestinyDescription());
            }
            else
            {
               setDestinyTxts(_avatar.mDestiny.nameArr,mTxt_destiny.x,mTxt_destiny.y);
            }
         }
         if(_type == "show_type_team")
         {
            _iconBg.width = _width - _icon.width - 20;
            _iconBg.height = 90;
            _iconBg.x = _icon.x + _icon.width - 20;
            addChildAt(_iconBg,3);
            _bg2.width = _width - 16;
            _bg2.height = 180;
            _bg2.y = _height - _bg2.height + 3;
            _bg2.x = (_width - _bg2.width) * 0.5 + 1;
         }
         var _loc30_:Sprite = new Sprite();
         _loc30_.touchable = false;
         _loc30_.x = _bg1.x - 5;
         _loc30_.y = _topBg.y + 12;
         _uiMain.addChild(_loc30_);
         var _loc28_:LOL_TextField = new LOL_TextField("",200,50);
         _loc28_.touchable = false;
         _loc28_.shadowFilter();
         _loc28_.fontColor = 16777215;
         _loc28_.fontSize = 30;
         _loc28_.hAlign = "center";
         _loc28_.x = (GlobalData.$mStageWidth - _loc28_.width) / 2;
         _loc28_.y = _topBg.y + 5;
         _uiMain.addChild(_loc28_);
         var _loc42_:Array = [Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20079,"0"),GlobalTextStyle.COLOR_0x4B2C1B,20,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20090,"0"),GlobalTextStyle.COLOR_0x4B2C1B,20,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20024,"0"),GlobalTextStyle.COLOR_0x4B2C1B,20,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20025,"0"),GlobalTextStyle.COLOR_0x4B2C1B,20,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20026,"0"),GlobalTextStyle.COLOR_0x4B2C1B,20,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20027,"0"),GlobalTextStyle.COLOR_0x4B2C1B,20,20)];
         if(mBox_P)
         {
            StarlingTools.removeChildrenClear(mBox_P);
            mBox_P.removeFromParent(true);
         }
         mBox_P = null;
         mBox_P = new Sprite();
         mBox_P.x = _bg2.x + 35;
         mBox_P.y = _bg2.y + 25;
         mBox_P.touchable = false;
         _uiMain.addChild(mBox_P);
         _quadType = new Quad(_bg1.width,45);
         _quadType.name = "_quadType";
         _quadType.x = _loc30_.x;
         _quadType.y = _loc30_.y;
         _quadType.alpha = 0.01;
         _uiMain.addChild(_quadType);
         _quadType.addEventListener("touch",onType);
         var _loc3_:Array = [];
         _loc35_ = 0;
         while(_loc35_ < _loc42_.length)
         {
            _loc10_ = new HtmlTextField(240,30,_loc42_[_loc35_],true,GlobalConfig.FONT_0);
            _loc10_.touchable = false;
            _loc10_.hAlign = "left";
            _loc10_.vAlign = "top";
            _loc10_.x = MainConfig.$isEA ? int(_loc35_ / 2) * 190 - 10 : 5 + int(_loc35_ / 2) * 192;
            _loc10_.y = _loc35_ % 2 * 30;
            if(_loc35_ < 2)
            {
               _loc10_.x = int(_loc35_ / 2) * 192 - 5;
            }
            if(_loc35_ >= 2 && _loc35_ < 4)
            {
               _loc10_.x = int(_loc35_ / 2) * 192 + 15;
            }
            mBox_P.addChild(_loc10_);
            _loc3_.push(_loc10_);
            _loc35_++;
         }
         var _loc44_:Quad = Tools.newQuad(_bg2.width - 50,2);
         _loc44_.color = 10120765;
         _loc44_.x = _bg2.x + 20;
         _loc44_.y = _bg2.y + 100;
         _loc44_.touchable = false;
         var _loc17_:LOL_Scale9Button = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20091),86,35,"UI_btn_3_0000",false);
         _loc17_.name = "btn1";
         _loc17_.x = mBox_P.x;
         _loc17_.y = mBox_P.y + 75;
         _loc17_.style(GlobalConfig.FONT_0,20,_avatar && _avatar.skill0 ? 16777215 : 6710886);
         _loc17_.name = _avatar && _avatar.skill0 ? _avatar.skill0.skillSetData.id : "";
         _uiMain.addChild(_loc17_);
         _loc17_.addEventListener("triggered",onTRIGGERED_btn);
         var _loc24_:Boolean = false;
         if(_avatar)
         {
            if(_avatar.mDestiny)
            {
               if(_avatar.mDestiny.skill1.length > 0)
               {
                  _loc24_ = true;
               }
            }
         }
         var _loc16_:LOL_Scale9Button = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20091),86,35,"UI_btn_3_0000",false);
         _loc16_.name = "btn2";
         _loc16_.x = _loc17_.x + 275;
         _loc16_.y = _loc17_.y;
         _loc16_.style(GlobalConfig.FONT_0,20,_avatar && _avatar.skill1 ? (_loc24_ ? 52479 : 16777215) : 6710886);
         _loc16_.name = _avatar && _avatar.skill1 ? _avatar.skill1.skillSetData.id : "";
         _uiMain.addChild(_loc16_);
         _loc16_.addEventListener("triggered",onTRIGGERED_btn);
         _quadSkill1 = new Quad(255,55);
         _quadSkill1.name = "_quadSkill1";
         _quadSkill1.x = _loc17_.x;
         _quadSkill1.y = _loc44_.y + 5;
         _quadSkill1.alpha = 0.01;
         _quadSkill1.name = _avatar && _avatar.skill0 ? _avatar.skill0.skillSetData.id : "";
         _uiMain.addChild(_quadSkill1);
         _quadSkill1.addEventListener("touch",quadSkill_Touch);
         _quadSkill2 = new Quad(255,55);
         _quadSkill2.name = "_quadSkill2";
         _quadSkill2.x = _loc16_.x;
         _quadSkill2.y = _loc44_.y + 5;
         _quadSkill2.alpha = 0.01;
         _quadSkill2.name = _avatar && _avatar.skill1 ? _avatar.skill1.skillSetData.id : "";
         _uiMain.addChild(_quadSkill2);
         _quadSkill2.addEventListener("touch",quadSkill_Touch);
         var _loc23_:Image = GlobalFunction.createImage("UI_tag_leader_0_0000");
         _loc23_.scaleX = _loc23_.scaleY = 0.9;
         _loc23_.x = _loc16_.x + _loc16_.width;
         _loc23_.y = _loc16_.y - 1;
         _loc23_.touchable = false;
         _uiMain.addChild(_loc23_);
         var _loc40_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(90021),130,35);
         _loc40_.fontSize = 20;
         _loc40_.vAlign = "center";
         _loc40_.x = _loc17_.x + _loc17_.width;
         _loc40_.y = _loc17_.y + 2;
         _loc40_.touchable = false;
         _uiMain.addChild(_loc40_);
         var _loc11_:LOL_TextField = new LOL_TextField("",60,30);
         _loc11_.fontSize = 20;
         _loc11_.touchable = false;
         _uiMain.addChild(_loc11_);
         var _loc39_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(90021),150,35);
         _loc39_.fontSize = 20;
         _loc39_.vAlign = "center";
         _loc39_.x = _loc16_.x + _loc16_.width + 30;
         _loc39_.y = _loc16_.y + 2;
         _loc39_.touchable = false;
         _uiMain.addChild(_loc39_);
         if(_data.id != null && _data.id != "")
         {
            _loc28_.text = _avatar.avatarData.name;
            _loc2_ = _avatar.resId.indexOf(".") > -1 ? _avatar.resId.slice(0,_avatar.resId.length - 1) : _avatar.resId;
            _loc21_ = new LOL_Button("",_loc2_.split("|")[0]);
            _loc21_.name = "_role";
            _loc21_.pivotX = _loc21_.width / 2;
            _loc21_.pivotY = _loc21_.height * 0.85;
            _loc21_.x = GlobalData.$mStageWidth / 2;
            _loc21_.y = _bg1.height / 2 + 20;
            _roleMain.addChild(_loc21_);
            if(_avatar.morph)
            {
               _loc45_ = DisplayTools.newImg("z_morph");
               _loc45_.scaleX = _loc45_.scaleY = 0.75;
               _loc45_.x = GlobalData.$mStageWidth / 2;
               _loc45_.y = _loc21_.y + 10;
               _loc45_.alpha = 1;
               _loc45_.touchable = false;
               _roleMain.addChild(_loc45_);
            }
            if(_playRoleSound)
            {
               SoundManager.getOnlyExample().playAvatar(_avatar.avatarData.soundId);
            }
            _loc12_ = GlobalFunction.createImage("UI_tag_0_000" + (String(_avatar.avatarData.damageType - 1)));
            _loc12_.touchable = false;
            _loc12_.x = 10;
            _loc30_.addChild(_loc12_);
            _loc36_ = GlobalFunction.createImage("UI_tag_1_000" + (String(_avatar.avatarData.signType - 1)));
            _loc36_.x = _loc12_.x + int((_loc12_.width - _loc36_.width) * 0.5);
            _loc36_.y = _loc12_.y + int((_loc12_.height - _loc36_.height) * 0.5) - 1;
            _loc36_.touchable = false;
            _loc30_.addChild(_loc36_);
            _loc19_ = GlobalLanguageStr.getLanguageStr(20166);
            _loc8_ = _loc19_.split("|");
            _loc14_ = new LOL_TextField(_loc8_[_avatar.avatarData.actionType - 1],150,30);
            _loc14_.x = _loc12_.width + 15;
            _loc14_.y = _loc12_.y + 1;
            _loc14_.touchable = false;
            _loc14_.fontSize = 20;
            _loc14_.fontColor = 16777215;
            _loc14_.shadowFilter();
            _loc30_.addChild(_loc12_);
            _loc30_.addChild(_loc36_);
            _loc30_.addChild(_loc14_);
            _loc30_.touchable = false;
            _loc15_ = uint(_avatar.getStar());
            _loc37_ = uint(_avatar.avatarData.getMaxStar());
            _loc29_ = new LOL_StarLevel(_loc15_,_loc37_,0.35);
            _loc29_.pivotX = _loc29_.width;
            _loc29_.x = _topBg.width - 15;
            _loc29_.y = _topBg.y + 26;
            _loc29_.touchable = false;
            _uiMain.addChild(_loc29_);
            if(_avatar.phase > 0)
            {
               _loc46_ = new LOL_TextField(GlobalLanguageStr.getLanguageStr(20292,_avatar.phase),100,30);
               _loc46_.shadowFilter();
               _loc46_.x = _width - _loc46_.width;
               _loc46_.y = _loc29_.y + 25;
               _loc46_.fontColor = 13696768;
               _loc46_.fontSize = 25;
               _loc46_.touchable = false;
               _uiMain.addChild(_loc46_);
            }
            update_Lock();
            if(_avatar)
            {
               if(talentSp)
               {
                  talentSp.removeFromParent(true);
                  talentSp.dispose();
                  talentSp = null;
               }
               if(_glowMc)
               {
                  _glowMc.removeFromParent(true);
                  _glowMc.dispose();
                  _glowMc = null;
               }
               if(talentQuad)
               {
                  talentQuad.removeFromParent(true);
                  talentQuad.dispose();
                  talentQuad = null;
               }
               if(_avatar.talent != null)
               {
                  talentSp = new Sprite();
                  talentSp.x = _iconBg.x + 30;
                  talentSp.y = _lockImg.y;
                  this.addChild(talentSp);
                  talentSp.addChild(Talent.getImage(_avatar.talent.id));
                  talentQuad = Tools.newQuad(talentSp.width,talentSp.height,talentSp.x,talentSp.y,0);
                  talentQuad.alpha = 0;
                  this.addChild(talentQuad);
                  talentQuad.addEventListener("touch",talentTouch);
                  showGlow();
               }
            }
            _loc33_ = _avatar.getCultivationDisplayScale();
            mFoster = new LOL_TextField(GlobalLanguageStr.getLanguageStr(90652,_avatar.getPithNum() * _loc33_),180,30);
            mFoster.fontColor = 16764006;
            mFoster.fontSize = 20;
            mFoster.hAlign = "right";
            mFoster.shadowFilter();
            mFoster.x = _lockImg.x - mFoster.width - 10;
            mFoster.y = _lockImg.y + 30;
            mFoster.touchable = true;
            _uiMain.addChild(mFoster);
            _quadFoster1 = new Quad(180,40);
            _quadFoster1.alpha = 0.01;
            _quadFoster1.x = mFoster.x;
            _quadFoster1.y = mFoster.y;
            _quadFoster1.addEventListener("touch",quadPith_Touch);
            _uiMain.addChild(_quadFoster1);
            if(_avatar.getPithNum() <= 0)
            {
               mFoster.visible = false;
               _quadFoster1.touchable = false;
            }
            else
            {
               mFoster.visible = true;
               _quadFoster1.touchable = true;
            }
            _loc31_ = _data["index"] == 0 ? true : false;
            update_Power(_loc31_,true);
            _loc34_ = int(_avatar.lv <= 0 ? 1 : _avatar.lv);
            _loc47_ = _avatar.getLeadership().toString();
            _loc4_ = _avatar.getLeadership(true) - _avatar.getLeadership();
            _loc47_ = GlobalLanguageStr.getLanguageStr(20090,_loc47_);
            _loc41_ = [Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20079,_loc34_ + GlobalLanguageStr.getLanguageStr(20081,_avatar.getLvMax())),GlobalTextStyle.COLOR_4B2C1B_990000,20,20),Tools.formatLineX(_loc47_,GlobalTextStyle.COLOR_0x4B2C1B,20,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20024,_avatar.getHpMax(-1,-1,true)),GlobalTextStyle.COLOR_0x4B2C1B,20,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20025,_avatar.getDamage(-1,-1,true)),GlobalTextStyle.COLOR_0x4B2C1B,20,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20026,_avatar.getDePh(-1,-1,true)),GlobalTextStyle.COLOR_0x4B2C1B,20,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20027,_avatar.getDeMa(-1,-1,true)),GlobalTextStyle.COLOR_0x4B2C1B,20,20)];
            _loc32_ = [];
            _loc32_[0] = _loc32_[1] = null;
            _loc7_ = null;
            _loc26_ = _avatar.getLoveList();
            _loc38_ = 0;
            while(_loc38_ < _loc41_.length)
            {
               if(_loc26_[0] > 0 && _loc38_ == 1)
               {
                  _loc41_[_loc38_] = Tools.formatLineX(_loc47_,GlobalTextStyle.COLOR_0xFF7777,20,20);
               }
               _loc3_[_loc38_].text = _loc41_[_loc38_];
               _loc38_++;
            }
            _loc6_ = _avatar.skill0 ? GlobalLanguageStr.getLanguageStr(20489,_avatar.skill0.skillSetData.name) : GlobalLanguageStr.getLanguageStr(90021);
            _loc5_ = _avatar.skill0 ? GlobalLanguageStr.getLanguageStr(20492,_avatar.skill0.lv) : "";
            _loc9_ = _avatar.skill1 ? _avatar.skill1.skillSetData.name : GlobalLanguageStr.getLanguageStr(90021);
            _loc25_ = "";
            _loc22_ = "";
            _loc18_ = _avatar.skill0 ? GlobalLanguageStr.getLanguageStr(25021,_avatar.skill0.skillSetData.warmup,_avatar.skill0.skillSetData.cooldown) : GlobalLanguageStr.getLanguageStr(90022);
            _loc20_ = _avatar.skill1 ? GlobalLanguageStr.getLanguageStr(25021,_avatar.skill1.skillSetData.warmup,_avatar.skill1.skillSetData.cooldown) : GlobalLanguageStr.getLanguageStr(90022);
            _loc40_.text = _loc6_;
            _loc39_.text = _loc9_;
            _loc11_.text = _loc5_;
            _loc11_.x = _loc40_.x + _loc40_.textBounds.width + 5;
            _loc11_.y = _loc40_.y + 3;
            if(_loc26_[0] > 0)
            {
               _loc27_ = new LOL_Button(_loc26_[0] + "","UI_love_bg_0000");
               _loc27_.name = "_loveBtn";
               _loc27_.fontSize = 14;
               _loc27_.fontColor = 16777215;
               _loc27_.x = MainConfig.$isEA ? _loc40_.x + 70 : _loc40_.x + 20;
               _loc27_.y = _loc40_.y - 43;
               _loc27_.textPoint = new Point(-3,-5);
               _uiMain.addChild(_loc27_);
               _loc27_.addEventListener("triggered",onTRIGGERED_love);
            }
         }
         else
         {
            _loc43_ = new LOL_Button("","UI_bg_herobg0000");
            _loc43_.name = "_role1";
            _loc43_.pivotX = _loc43_.width / 2;
            _loc43_.pivotY = _loc43_.height * 0.9;
            _loc43_.x = GlobalData.$mStageWidth / 2;
            _loc43_.y = _bg1.height / 2 + (100 - _bgY);
            _loc43_.addEventListener("triggered",role1_Triggered);
            _uiMain.addChildAt(_loc43_,1);
            _loc13_ = new LOL_TextField(GlobalLanguageStr.getLanguageStr(10127),250,50);
            _loc13_.shadowFilter();
            _loc13_.fontSize = 25;
            _loc13_.fontColor = 16777215;
            _loc13_.pivotX = _loc13_.width / 2;
            _loc13_.pivotY = _loc13_.height / 2;
            _loc13_.hAlign = "center";
            _loc13_.x = GlobalData.$mStageWidth / 2 + 20;
            _loc13_.y = _loc43_.y - 100;
            _loc13_.touchable = false;
            _uiMain.addChild(_loc13_);
         }
         if(_type == "show_type_team")
         {
            if(_loc21_)
            {
               _loc21_.addEventListener("triggered",role_Triggered);
            }
         }
         else if(_type == "show_type_dynamic")
         {
            if(_loc13_)
            {
               _loc13_.visible = false;
            }
            if(_loc43_ && _loc43_.hasEventListener("triggered"))
            {
               _loc43_.removeEventListener("triggered",role1_Triggered);
            }
         }
         if(_avatar && _avatar.skillB)
         {
            _loc17_.y = mBox_P.y + 65;
            _loc40_.x = _loc17_.x;
            _loc40_.y = _loc17_.y + 42;
            _loc11_.x = _loc40_.x + _loc40_.textBounds.width + 5;
            _loc11_.y = _loc40_.y + 3;
            _loc16_.x = _loc17_.x + 210;
            _loc16_.y = _loc17_.y;
            _loc23_.x = _loc16_.x;
            _loc23_.y = _loc16_.y + 39;
            _loc39_.x = _loc23_.x + _loc23_.width + 5;
            _loc39_.y = _loc23_.y + 2;
            _quadSkill1.width = _quadSkill2.width = 176;
            _quadSkill1.height = _quadSkill2.height = 80;
            _quadSkill1.y = _quadSkill2.y = _quadSkill2.y = _loc44_.y - 15;
            _quadSkill2.x = _loc16_.x;
            skillPassiveBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20513),86,35,"UI_btn_3_0000",false);
            skillPassiveBtn.name = "skillPassiveBtn";
            skillPassiveBtn.x = _loc16_.x + 200;
            skillPassiveBtn.y = _loc16_.y;
            skillPassiveBtn.style(GlobalConfig.FONT_0,20,_avatar && _avatar.skillB ? 16777215 : 6710886);
            skillPassiveBtn.name = _avatar && _avatar.skillB ? _avatar.skillB.skillSetData.id : "";
            _uiMain.addChild(skillPassiveBtn);
            skillPassiveBtn.addEventListener("triggered",onTRIGGERED_btn);
            skillPassiveTxt = new LOL_TextField(GlobalLanguageStr.getLanguageStr(20489,_avatar.skillB.skillSetData.name),130,35);
            skillPassiveTxt.fontSize = 20;
            skillPassiveTxt.vAlign = "center";
            skillPassiveTxt.x = skillPassiveBtn.x;
            skillPassiveTxt.y = skillPassiveBtn.y + 42;
            skillPassiveTxt.touchable = false;
            _uiMain.addChild(skillPassiveTxt);
            _quadSkillPassive = new Quad(176,80);
            _quadSkillPassive.name = "_quadSkillPassive";
            _quadSkillPassive.x = skillPassiveBtn.x;
            _quadSkillPassive.y = _loc44_.y - 15;
            _quadSkillPassive.alpha = 0.01;
            _quadSkillPassive.name = _avatar && _avatar.skillB ? _avatar.skillB.skillSetData.id : "";
            _uiMain.addChild(_quadSkillPassive);
            _quadSkillPassive.addEventListener("touch",quadSkill_Touch);
         }
      }

      private function showGlow() : void
      {
         var _loc1_:int = 0;
         var _loc2_:Juggler = GlobalData.$mStarling.juggler;
         _glowMc = DisplayTools.newMc("button_glow");
         _glowMc.width = talentSp.width + 12;
         _glowMc.height = talentSp.height + 20;
         _glowMc.x = talentSp.x + _glowMc.width / 2 - 7;
         _glowMc.y = talentSp.y + _glowMc.height / 2 - 9;
         this.addChild(_glowMc);
         _loc2_.add(_glowMc);
      }

      public function updatePower() : void
      {
         var _loc1_:String = null;
         var _loc2_:String = null;
         var _loc3_:int = GlobalData.$tempTeamPowerTemp;
         GlobalData.$tempTeamPowerTemp = GlobalFunction.getTeamPower(GlobalData.$userData.team[0]);
         _loc3_ = GlobalData.$tempTeamPowerTemp - _loc3_;
         if(_loc3_ != 0)
         {
            _loc1_ = Tools.formateNum(_loc3_);
            _loc2_ = GlobalLanguageStr.getLanguageStr(20475);
            _loc2_ += _loc3_ > 0 ? "[+" + _loc1_ + "]" : "{" + _loc1_ + "}";
            LayoutUIAnimation.getOnlyExample().popWords(_loc2_,2);
         }
      }

      public function updateAll(param1:*) : void
      {
         var _loc56_:Image = null;
         var _loc42_:PanelDetailAvatar = null;
         var _loc19_:LOL_TextField = null;
         var _loc61_:int = 0;
         var _loc37_:HtmlTextField = null;
         var _loc32_:String = null;
         var _loc13_:LOL_Button = null;
         var _loc68_:Image = null;
         var _loc36_:Image = null;
         var _loc24_:Image = null;
         var _loc48_:String = null;
         var _loc35_:Array = null;
         var _loc40_:LOL_TextField = null;
         var _loc41_:* = 0;
         var _loc63_:* = 0;
         var _loc59_:LOL_StarLevel = null;
         var _loc31_:LOL_TextField = null;
         var _loc60_:int = 0;
         var _loc23_:int = 0;
         var _loc71_:String = null;
         var _loc33_:int = 0;
         var _loc28_:Array = null;
         var _loc65_:Object = null;
         var _loc16_:Number = NaN;
         var _loc38_:Number = NaN;
         var _loc39_:Number = NaN;
         var _loc57_:Number = NaN;
         var _loc66_:Number = NaN;
         var _loc43_:Number = NaN;
         var _loc3_:Number = NaN;
         var _loc17_:Number = NaN;
         var _loc53_:Array = null;
         var _loc22_:Array = null;
         var _loc5_:Image = null;
         var _loc55_:Array = null;
         var _loc64_:int = 0;
         var _loc4_:String = null;
         var _loc34_:String = null;
         var _loc6_:String = null;
         var _loc54_:String = null;
         var _loc50_:String = null;
         var _loc47_:String = null;
         var _loc49_:String = null;
         var _loc44_:Object = null;
         var _loc8_:Object = null;
         var _loc51_:Object = null;
         var _loc62_:Object = null;
         var _loc25_:String = null;
         var _loc58_:String = null;
         var _loc70_:LOL_HtmlText = null;
         var _loc18_:LOL_Button = null;
         var _loc67_:LOL_Button = null;
         var _loc10_:LOL_TextField = null;
         var _loc21_:String = null;
         _data = param1;
         if(_data.id != null && _data.id != "")
         {
            if(_data is Avatar)
            {
               _avatar = _data as Avatar;
            }
            else
            {
               _avatar = new Avatar(_data.id,_data);
            }
         }
         else
         {
            _avatar = null;
         }
         if(_quadPith)
         {
            _quadPith.removeFromParent(true);
         }
         StarlingTools.removeChildrenClear(_roleMain,false);
         StarlingTools.removeChildrenClear(_uiMain,false);
         if(_data.hasOwnProperty("isSoul") && _data.isSoul)
         {
            _loc56_ = GlobalFunction.createImage("UI_icon_fragment_0000");
            _uiMain.addChild(_loc56_);
            _loc42_ = _loc56_.parent.parent.parent as PanelDetailAvatar;
            _loc56_.x = _loc42_.mTxt_titile.textBounds.x + _loc42_.mTxt_titile.textBounds.width - 50;
            _loc56_.y = _loc42_.mTxt_titile.y - 64;
            _loc56_.addEventListener("touch",icon_Touch);
         }
         _quadPith = new Quad(_bg2.width - 200,90);
         _quadPith.name = "quadPith";
         _quadPith.x = _bg2.x + 200;
         _quadPith.y = _bg2.y;
         _quadPith.alpha = 0.01;
         _uiMain.addChild(_quadPith);
         if(_type == "show_type_dynamic")
         {
            _bg2.height = 245;
            _bg2.y = _height - _bg2.height;
            _icon.y = _bg2.y - _icon.height - 10;
            _iconBg.y = _icon.y + 2;
            mTxt_destiny.y = _iconBg.y + 10;
            mTxt_destiny.height = _iconBg.height;
            _euqipMain.y = -20;
            _iconBg.width = _width - _icon.width;
            _iconBg.x = _icon.x + _icon.width - 20;
            addChildAt(_iconBg,3);
            setDestinyTxts(null,mTxt_destiny.x,_iconBg.y + 10,true);
         }
         else
         {
            _bg2.height = 245;
            _bg2.y = _height - 185;
            _icon.y = _bg2.y - _icon.height - 40;
            _iconBg.y = _icon.y + 7;
            _iconBg.height = 120;
            mTxt_destiny.y = _iconBg.y + 10;
            mTxt_destiny.height = _iconBg.height - 25;
         }
         if(_type == "show_type_team" || _type == "show_type_dynamic")
         {
            updateEquip();
         }
         else
         {
            setDestinyTxts(null);
            mTxt_destiny.reInit("");
            _avatar.setDestinyAndDN("",null,null,null,null,_type == "show_type_info");
            if(_type != "show_type_dynamic")
            {
               if(_avatar.id.indexOf("|") > -1)
               {
                  if(GlobalData.$userData.team[0].indexOf(_avatar.id) < 0)
                  {
                     _avatar.clearDNdata();
                  }
               }
               else
               {
                  _avatar.clearDNdata();
               }
            }
            mTxt_destiny.reInit(_avatar.getDestinyDescription());
         }
         var _loc20_:Sprite = new Sprite();
         _loc20_.touchable = false;
         _loc20_.x = _bg1.x - 5;
         if(_type == "show_type_dynamic")
         {
            _loc20_.y = _topXY.y + 12;
         }
         else
         {
            _loc20_.y = _topXY.y + 3;
         }
         _uiMain.addChild(_loc20_);
         if(_topBg != null)
         {
            _loc19_ = new LOL_TextField("",200,50);
            _loc19_.fontColor = 16777215;
            _loc19_.fontSize = 30;
            _loc19_.hAlign = "center";
            _loc19_.x = (GlobalData.$mStageWidth - _loc19_.width) / 2 - 30;
            _loc19_.y = _topXY.y + 5;
            _loc19_.shadowFilter();
            _uiMain.addChild(_loc19_);
         }
         var _loc29_:Array = [Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20079,"0"),GlobalTextStyle.COLOR_0x4B2C1B,20,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20090,"0"),GlobalTextStyle.COLOR_0x4B2C1B,20,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20088,"0"),GlobalTextStyle.COLOR_0x4B2C1B,20,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20089,"0"),GlobalTextStyle.COLOR_0x4B2C1B,20,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20024,"0"),GlobalTextStyle.COLOR_0x4B2C1B,20,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20025,"0"),GlobalTextStyle.COLOR_0x4B2C1B,20,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20026,"0"),GlobalTextStyle.COLOR_0x4B2C1B,20,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20027,"0"),GlobalTextStyle.COLOR_0x4B2C1B,20,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20034,"0"),GlobalTextStyle.COLOR_0x4B2C1B,20,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20232,"0"),GlobalTextStyle.COLOR_0x4B2C1B
         ,20,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20233,"0"),GlobalTextStyle.COLOR_0x4B2C1B,20,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20234,"0"),GlobalTextStyle.COLOR_0x4B2C1B,20,20)];
         if(mBox_P)
         {
            StarlingTools.removeChildrenClear(mBox_P);
            mBox_P.removeFromParent(true);
         }
         mBox_P = null;
         mBox_P = new Sprite();
         mBox_P.x = _bg2.x + 30;
         mBox_P.y = _bg2.y + 15;
         _uiMain.addChild(mBox_P);
         _quadType = new Quad(_bg1.width,45);
         _quadType.name = "quadType";
         _quadType.x = _loc20_.x;
         _quadType.y = _loc20_.y;
         _quadType.alpha = 0.01;
         _uiMain.addChild(_quadType);
         _quadType.addEventListener("touch",onType);
         var _loc2_:Array = [];
         _loc61_ = 0;
         while(_loc61_ < _loc29_.length)
         {
            _loc37_ = new HtmlTextField(240,30,_loc29_[_loc61_],true,GlobalConfig.FONT_0);
            _loc37_.touchable = false;
            _loc37_.hAlign = "left";
            _loc37_.vAlign = "top";
            _loc37_.x = 5 + int(_loc61_ / 4) * 192;
            _loc37_.y = _loc61_ % 4 * 25;
            if(_loc61_ < 4)
            {
               _loc37_.x = int(_loc61_ / 4) * 192 - 5;
            }
            if(_loc61_ >= 4 && _loc61_ < 8)
            {
               _loc37_.x = int(_loc61_ / 4) * 192 + 15;
            }
            mBox_P.addChild(_loc37_);
            _loc2_.push(_loc37_);
            _loc61_++;
         }
         var _loc30_:Quad = Tools.newQuad(_bg2.width - 50,2);
         _loc30_.color = 10120765;
         _loc30_.x = _bg2.x + 20;
         _loc30_.y = _bg2.y + 120;
         _uiMain.addChild(_loc30_);
         var _loc46_:LOL_Scale9Button = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20091),86,35,"UI_btn_3_0000",false);
         _loc46_.name = "_btn1";
         _loc46_.x = _loc30_.x;
         _loc46_.y = _loc30_.y + _loc30_.height;
         _loc46_.style(GlobalConfig.FONT_0,20,_avatar && _avatar.skill0 ? 16777215 : 6710886);
         _loc46_.name = _avatar && _avatar.skill0 ? _avatar.skill0.skillSetData.id : "";
         _uiMain.addChild(_loc46_);
         _loc46_.addEventListener("triggered",onTRIGGERED_btn);
         var _loc52_:Boolean = false;
         if(_avatar)
         {
            if(_avatar.mDestiny)
            {
               if(_avatar.mDestiny.skill1.length > 0)
               {
                  _loc52_ = true;
               }
            }
         }
         var _loc45_:LOL_Scale9Button = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20091),86,35,"UI_btn_3_0000",false);
         _loc45_.name = "_btn2";
         _loc45_.x = _loc46_.x + 270;
         _loc45_.y = _loc46_.y;
         _loc45_.style(GlobalConfig.FONT_0,20,_avatar && _avatar.skill1 ? (_loc52_ ? 52479 : 16777215) : 6710886);
         _loc45_.name = _avatar && _avatar.skill1 ? _avatar.skill1.skillSetData.id : "";
         _uiMain.addChild(_loc45_);
         _loc45_.addEventListener("triggered",onTRIGGERED_btn);
         _quadSkill1 = new Quad(255,100);
         _quadSkill1.name = "quadSkill11";
         _quadSkill1.x = _loc46_.x;
         _quadSkill1.y = _loc30_.y + 5;
         _quadSkill1.alpha = 0.01;
         _quadSkill1.name = _avatar && _avatar.skill0 ? _avatar.skill0.skillSetData.id : "";
         _uiMain.addChild(_quadSkill1);
         _quadSkill1.addEventListener("touch",quadSkill_Touch);
         _quadSkill2 = new Quad(255,100);
         _quadSkill2.name = "quadSkill22";
         _quadSkill2.x = _loc45_.x;
         _quadSkill2.y = _loc30_.y + 5;
         _quadSkill2.alpha = 0.01;
         _quadSkill2.name = _avatar && _avatar.skill1 ? _avatar.skill1.skillSetData.id : "";
         _uiMain.addChild(_quadSkill2);
         _quadSkill2.addEventListener("touch",quadSkill_Touch);
         var _loc15_:Image = GlobalFunction.createImage("UI_tag_leader_0_0000");
         _loc15_.scaleX = _loc15_.scaleY = 0.9;
         _loc15_.x = _loc45_.x + _loc45_.width;
         _loc15_.y = _loc45_.y - 1;
         _loc15_.touchable = false;
         _uiMain.addChild(_loc15_);
         var _loc27_:LOL_TextField = new LOL_TextField("-",130,35);
         _loc27_.fontSize = 20;
         _loc27_.vAlign = "center";
         _loc27_.x = _loc46_.x + _loc46_.width;
         _loc27_.y = _loc46_.y + 2;
         _uiMain.addChild(_loc27_);
         var _loc26_:LOL_TextField = new LOL_TextField("-",150,35);
         _loc26_.vAlign = "center";
         _loc26_.x = _loc45_.x + _loc45_.width + 30;
         _loc26_.y = _loc45_.y + 2;
         _uiMain.addChild(_loc26_);
         var _loc12_:LOL_TextField = new LOL_TextField("-",250,60);
         _loc12_.style(GlobalConfig.FONT_0,15,4926491,"left","top");
         _loc12_.x = _loc46_.x;
         _loc12_.y = _loc46_.y + _loc46_.height - 5;
         _uiMain.addChild(_loc12_);
         var _loc7_:LOL_TextField = new LOL_TextField("-",60,30);
         _loc7_.fontSize = 20;
         _uiMain.addChild(_loc7_);
         var _loc11_:LOL_TextField = new LOL_TextField("-",250,60);
         _loc11_.style(GlobalConfig.FONT_0,15,4926491,"left","top");
         _loc11_.x = _loc45_.x;
         _loc11_.y = _loc45_.y + _loc45_.height - 5;
         _uiMain.addChild(_loc11_);
         var _loc69_:LOL_TextField = new LOL_TextField("-",MainConfig.$isEA ? 300 : 150,50);
         _loc69_.style(GlobalConfig.FONT_0,15,1118481,"left");
         _loc69_.x = MainConfig.$isEA ? _loc46_.x + _loc46_.width - 5 : _loc46_.x + _loc46_.width + 40;
         _loc69_.y = _loc46_.y + _loc46_.height + 39;
         _uiMain.addChild(_loc69_);
         var _loc9_:LOL_TextField = new LOL_TextField("-",MainConfig.$isEA ? 300 : 150,50);
         _loc9_.style(GlobalConfig.FONT_0,15,1118481,"left");
         _loc9_.x = MainConfig.$isEA ? _bg2.x + _bg2.width - 190 : _bg2.x + _bg2.width - 145;
         _loc9_.y = _loc45_.y + _loc45_.height + 39;
         _uiMain.addChild(_loc9_);
         if(_data.id != null && _data.id != "")
         {
            if(_topBg != null)
            {
               _loc19_.text = _avatar.avatarData.name;
            }
            _loc32_ = _avatar.resId.indexOf(".") > -1 ? _avatar.resId.slice(0,_avatar.resId.length - 1) : _avatar.resId;
            _loc13_ = new LOL_Button("",_loc32_.split("|")[0]);
            _loc13_.pivotX = _loc13_.width / 2;
            _loc13_.pivotY = _loc13_.height * 0.9;
            _loc13_.x = GlobalData.$mStageWidth / 2;
            _loc13_.y = _bg1.height / 2 + 40;
            _roleMain.addChild(_loc13_);
            if(_avatar.morph)
            {
               _loc68_ = DisplayTools.newImg("z_morph");
               _loc68_.scaleX = _loc68_.scaleY = 0.75;
               _loc68_.x = GlobalData.$mStageWidth / 2;
               _loc68_.y = _loc13_.y + 10;
               _loc68_.alpha = 1;
               _roleMain.addChild(_loc68_);
            }
            SoundManager.getOnlyExample().playAvatar(_avatar.avatarData.soundId);
            _loc36_ = GlobalFunction.createImage("UI_tag_0_000" + (String(_avatar.avatarData.damageType - 1)));
            _loc36_.x = 10;
            _loc20_.addChild(_loc36_);
            _loc24_ = GlobalFunction.createImage("UI_tag_1_000" + (String(_avatar.avatarData.signType - 1)));
            _loc24_.x = _loc36_.x + int((_loc36_.width - _loc24_.width) * 0.5);
            _loc24_.y = _loc36_.y + int((_loc36_.height - _loc24_.height) * 0.5) - 1;
            _loc20_.addChild(_loc24_);
            _loc48_ = GlobalLanguageStr.getLanguageStr(20166);
            _loc35_ = _loc48_.split("|");
            _loc40_ = new LOL_TextField(_loc35_[_avatar.avatarData.actionType - 1],350,30);
            _loc40_.x = _loc36_.width + 15;
            _loc40_.y = _loc36_.y + 1;
            _loc40_.touchable = true;
            _loc40_.fontSize = 20;
            _loc40_.fontColor = 16777215;
            _loc40_.shadowFilter();
            _loc20_.addChild(_loc36_);
            _loc20_.addChild(_loc24_);
            _loc20_.addChild(_loc40_);
            _loc41_ = uint(_avatar.getStar());
            _loc63_ = uint(_avatar.avatarData.getMaxStar());
            _loc59_ = new LOL_StarLevel(_loc41_,_loc63_,0.35);
            _loc59_.pivotX = _loc59_.width;
            _loc59_.x = _topXY.width - 15;
            if(_type == "show_type_dynamic")
            {
               _loc59_.y = _topXY.y + 26;
            }
            else
            {
               _loc59_.y = _topXY.y + 21;
            }
            _uiMain.addChild(_loc59_);
            if(_avatar.phase > 0)
            {
               _loc31_ = new LOL_TextField(GlobalLanguageStr.getLanguageStr(20292,_avatar.phase),100,30);
               _loc31_.shadowFilter();
               _loc31_.x = MainConfig.$isEnglish ? _width - _loc31_.width - 85 : _width - _loc31_.width - 40;
               _loc31_.y = _loc59_.y + 25;
               _loc31_.fontColor = 13696768;
               _loc31_.fontSize = 25;
               _uiMain.addChild(_loc31_);
            }
            update_Lock();
            if(_avatar)
            {
               if(talentSp)
               {
                  talentSp.removeFromParent(true);
                  talentSp.dispose();
                  talentSp = null;
               }
               if(_glowMc)
               {
                  _glowMc.removeFromParent(true);
                  _glowMc.dispose();
                  _glowMc = null;
               }
               if(talentQuad)
               {
                  talentQuad.removeFromParent(true);
                  talentQuad.dispose();
                  talentQuad = null;
               }
               if(_avatar.talent != null)
               {
                  talentSp = new Sprite();
                  talentSp.x = _iconBg.x + 10;
                  talentSp.y = _iconBg.y - talentSp.y - 60;
                  this.addChild(talentSp);
                  talentSp.addChild(Talent.getImage(_avatar.talent.id));
                  talentQuad = Tools.newQuad(talentSp.width,talentSp.height,talentSp.x,talentSp.y,0);
                  talentQuad.alpha = 0;
                  this.addChild(talentQuad);
                  talentQuad.addEventListener("touch",talentTouch);
                  showGlow();
               }
            }
            _loc60_ = _avatar.getCultivationDisplayScale();
            mFoster2 = new LOL_TextField(GlobalLanguageStr.getLanguageStr(90652,_avatar.getPithNum() * _loc60_),180,30);
            mFoster2.fontColor = 16764006;
            mFoster2.fontSize = 20;
            mFoster2.hAlign = "right";
            mFoster2.shadowFilter();
            mFoster2.touchable = true;
            mFoster2.addEventListener("touch",quadPith_Touch);
            _uiMain.addChild(mFoster2);
            _quadFoster2 = new Quad(180,40);
            _quadFoster2.alpha = 0.01;
            _quadFoster2.addEventListener("touch",quadPith_Touch);
            _uiMain.addChild(_quadFoster2);
            if(_lockImg)
            {
               mFoster2.x = _lockImg.x - mFoster2.width - 10;
               mFoster2.y = _lockImg.y + 30;
               _quadFoster2.x = mFoster2.x;
               _quadFoster2.y = mFoster2.y;
            }
            else
            {
               mFoster2.x = 328;
               mFoster2.y = _iconBg.y - 30;
               _quadFoster2.x = mFoster2.x;
               _quadFoster2.y = mFoster2.y;
            }
            if(_avatar.getPithNum() <= 0)
            {
               mFoster2.visible = false;
               _quadFoster2.touchable = false;
            }
            else
            {
               mFoster2.visible = true;
               _quadFoster2.touchable = true;
            }
            _loc23_ = int(_avatar.lv <= 0 ? 1 : _avatar.lv);
            _loc71_ = _avatar.getLeadership().toString();
            _loc33_ = _avatar.getLeadership(true) - _avatar.getLeadership();
            _loc71_ = GlobalLanguageStr.getLanguageStr(20090,_loc71_);
            _loc65_ = GlobalData.$userGuild.GuildFightInspire;
            if(GlobalData.$userGuild.CheckTeam && _loc65_)
            {
               _loc16_ = _avatar.getHpMax(-1,-1,true);
               _loc38_ = _avatar.getDamage(-1,-1,true);
               _loc39_ = _avatar.getDePh(-1,-1,true);
               _loc57_ = _avatar.getDeMa(-1,-1,true);
               _loc66_ = _avatar.getHit();
               _loc43_ = _avatar.getFlee();
               _loc3_ = _avatar.getCrit();
               _loc17_ = _avatar.getTough();
               _loc53_ = [4926491,65280,65280,65280];
               for(var _loc14_:String in _loc65_.data.inspire)
               {
                  switch(_loc14_)
                  {
                     case "hp":
                        _loc16_ = _avatar.getHpMax(-1,-1,true) * (1 + _loc65_.data.inspire[_loc14_][0]) + _loc65_.data.inspire[_loc14_][1];
                        break;
                     case "ap":
                        _loc38_ = _avatar.getDamage(-1,-1,true) * (1 + _loc65_.data.inspire[_loc14_][0]) + _loc65_.data.inspire[_loc14_][1];
                        break;
                     case "de_ph":
                        _loc39_ = _avatar.getDePh(-1,-1,true) * (1 + _loc65_.data.inspire[_loc14_][0]) + _loc65_.data.inspire[_loc14_][1];
                        break;
                     case "de_ma":
                        _loc57_ = _avatar.getDeMa(-1,-1,true) * (1 + _loc65_.data.inspire[_loc14_][0]) + _loc65_.data.inspire[_loc14_][1];
                        break;
                     case "hit":
                        _loc66_ = _avatar.getHit() * (1 + _loc65_.data.inspire[_loc14_][0]) + _loc65_.data.inspire[_loc14_][1];
                        break;
                     case "flee":
                        _loc43_ = _avatar.getFlee() * (1 + _loc65_.data.inspire[_loc14_][0]) + _loc65_.data.inspire[_loc14_][1];
                        break;
                     case "crit":
                        _loc3_ = _avatar.getCrit() * (1 + _loc65_.data.inspire[_loc14_][0]) + _loc65_.data.inspire[_loc14_][1];
                        break;
                     case "tough":
                        _loc17_ = _avatar.getTough() * (1 + _loc65_.data.inspire[_loc14_][0]) + _loc65_.data.inspire[_loc14_][1];
                  }
               }
               _loc28_ = [Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20079,_loc23_ + GlobalLanguageStr.getLanguageStr(20081,_avatar.getLvMax())),GlobalTextStyle.COLOR_4B2C1B_990000,20,MainConfig.$isEA ? 17 : 20),Tools.formatLineX(_loc71_,GlobalTextStyle.COLOR_0x4B2C1B,MainConfig.$isEA ? 17 : 20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20088,_avatar.getSpeed(true)),GlobalTextStyle.COLOR_0x4B2C1B,20,MainConfig.$isEA ? 17 : 20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20089,_avatar.getRange(true)),GlobalTextStyle.COLOR_0x4B2C1B,20,MainConfig.$isEA ? 17 : 20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20024,"(" + _loc16_.toFixed(0) + ")"),_loc16_ == _avatar.getHpMax(-1,-1,true) ? GlobalTextStyle.COLOR_0x4B2C1B : _loc53_,20,MainConfig.$isEA ? 17 : 20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20025,"(" + _loc38_.toFixed(0) + ")"),_loc38_ == _avatar.getDamage(-1,-1,true) ? GlobalTextStyle.COLOR_0x4B2C1B : _loc53_,20,MainConfig.$isEA ? 17 : 20),Tools.formatLineX(GlobalLanguageStr
               .getLanguageStr(20026,"(" + _loc39_.toFixed(0) + ")"),_loc39_ == _avatar.getDePh(-1,-1,true) ? GlobalTextStyle.COLOR_0x4B2C1B : _loc53_,20,MainConfig.$isEA ? 17 : 20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20027,"(" + _loc57_.toFixed(0) + ")"),_loc57_ == _avatar.getDeMa(-1,-1,true) ? GlobalTextStyle.COLOR_0x4B2C1B : _loc53_,20,MainConfig.$isEA ? 17 : 20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20034,"(" + _loc66_.toFixed(0) + ")"),_loc66_ == _avatar.getHit() ? GlobalTextStyle.COLOR_0x4B2C1B : _loc53_,20,MainConfig.$isEA ? 17 : 20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20232,"(" + _loc43_.toFixed(0) + ")"),_loc43_ == _avatar.getFlee() ? GlobalTextStyle.COLOR_0x4B2C1B : _loc53_,20,MainConfig.$isEA ? 17 : 20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20233,"(" + _loc3_.toFixed(0) + ")"),_loc3_ == _avatar.getCrit() ? GlobalTextStyle.COLOR_0x4B2C1B : _loc53_,20,MainConfig.$isEA ? 17 : 20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20234,"(" + _loc17_
               .toFixed(0) + ")"),_loc17_ == _avatar.getTough() ? GlobalTextStyle.COLOR_0x4B2C1B : _loc53_,20,MainConfig.$isEA ? 17 : 20)];
            }
            else
            {
               _loc28_ = [Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20079,_loc23_ + GlobalLanguageStr.getLanguageStr(20081,_avatar.getLvMax())),GlobalTextStyle.COLOR_4B2C1B_990000,20,MainConfig.$isEA ? 17 : 20),Tools.formatLineX(_loc71_,GlobalTextStyle.COLOR_0x4B2C1B,MainConfig.$isEA ? 17 : 20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20088,_avatar.getSpeed(true)),GlobalTextStyle.COLOR_0x4B2C1B,20,MainConfig.$isEA ? 17 : 20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20089,_avatar.getRange(true)),GlobalTextStyle.COLOR_0x4B2C1B,20,MainConfig.$isEA ? 17 : 20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20024,_avatar.getHpMax(-1,-1,true)),GlobalTextStyle.COLOR_0x4B2C1B,20,MainConfig.$isEA ? 17 : 20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20025,_avatar.getDamage(-1,-1,true)),GlobalTextStyle.COLOR_0x4B2C1B,20,MainConfig.$isEA ? 17 : 20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20026,_avatar.getDePh(-1,-1,true)),GlobalTextStyle.COLOR_0x4B2C1B,20,MainConfig
               .$isEA ? 17 : 20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20027,_avatar.getDeMa(-1,-1,true)),GlobalTextStyle.COLOR_0x4B2C1B,20,MainConfig.$isEA ? 17 : 20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20034,_avatar.getHit()),GlobalTextStyle.COLOR_0x4B2C1B,20,MainConfig.$isEA ? 17 : 20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20232,_avatar.getFlee()),GlobalTextStyle.COLOR_0x4B2C1B,20,MainConfig.$isEA ? 17 : 20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20233,_avatar.getCrit()),GlobalTextStyle.COLOR_0x4B2C1B,20,MainConfig.$isEA ? 17 : 20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20234,_avatar.getTough()),GlobalTextStyle.COLOR_0x4B2C1B,20,MainConfig.$isEA ? 17 : 20)];
            }
            _loc22_ = [];
            _loc5_ = null;
            _loc55_ = _avatar.getLoveList();
            _loc64_ = 0;
            while(_loc64_ < _loc28_.length)
            {
               if(_loc55_[0] > 0 && _loc64_ == 1)
               {
                  _loc28_[_loc64_] = Tools.formatLineX(_loc71_,GlobalTextStyle.COLOR_0xFF7777,20,MainConfig.$isEA ? 17 : 20);
               }
               _loc2_[_loc64_].text = _loc28_[_loc64_];
               _loc64_++;
            }
            _loc4_ = _avatar.skill0 ? GlobalLanguageStr.getLanguageStr(20489,_avatar.skill0.skillSetData.name) : GlobalLanguageStr.getLanguageStr(90021);
            _loc34_ = _avatar.skill0 ? GlobalLanguageStr.getLanguageStr(20492,_avatar.skill0.lv) : "";
            _loc6_ = _avatar.skill1 ? _avatar.skill1.skillSetData.name : GlobalLanguageStr.getLanguageStr(90021);
            _loc54_ = "";
            _loc50_ = "";
            _loc47_ = _avatar.skill0 ? GlobalLanguageStr.getLanguageStr(25021,_avatar.skill0.skillSetData.warmup,_avatar.skill0.skillSetData.cooldown) : "";
            _loc49_ = _avatar.skill1 ? GlobalLanguageStr.getLanguageStr(25021,_avatar.skill1.skillSetData.warmup,_avatar.skill1.skillSetData.cooldown) : "";
            if(_avatar.skill0 == null && _avatar.skill1 == null && _avatar.avatarData.info != null)
            {
               _loc15_.visible = false;
               _loc46_.visible = false;
               _loc45_.visible = false;
               _loc7_.visible = false;
               _loc27_.visible = false;
               _loc26_.visible = false;
               _loc12_.visible = false;
               _loc11_.visible = false;
               _loc69_.visible = false;
               _loc9_.visible = false;
               _loc44_ = GlobalData.$config_battle_main;
               _loc8_ = GlobalData.$mConfig_battle_ploy;
               _loc51_ = GlobalData.$config_combat_main;
               _loc62_ = GlobalData.$mConfig_combat_ploy;
               _loc25_ = "";
               _loc58_ = _avatar.avatarData.origin;
               if(_loc58_ != null)
               {
                  GlobalData.$maze_BattleId = _loc58_.substring(0,_loc58_.lastIndexOf("_"));
                  GlobalData.$maze_CombatId = _loc58_;
                  if(GlobalData.$maze_BattleId.indexOf("M") > -1)
                  {
                     _loc25_ += _loc44_[GlobalData.$maze_BattleId].name;
                     _loc25_ = _loc25_ + (" - " + _loc51_[_loc58_].name);
                  }
                  else
                  {
                     _loc25_ += _loc8_[GlobalData.$maze_BattleId].name;
                     _loc25_ = _loc25_ + (" - " + _loc62_[_loc58_].name);
                  }
                  _loc25_ = GlobalLanguageStr.replaceStrArr(_avatar.avatarData.info,["  <U>" + _loc25_ + "<U/>"]);
               }
               else
               {
                  _loc25_ = _avatar.avatarData.info;
                  GlobalData.$maze_BattleId = "";
                  GlobalData.$maze_CombatId = "";
               }
               _loc70_ = new LOL_HtmlText(_loc30_.width,80,20,10027008,false,"center");
               _loc70_.name = "_infoTxt";
               _loc70_.format(_loc25_,[10027008,10027008,16764006]);
               _loc70_.x = _loc30_.x;
               _loc70_.y = _loc30_.y + _loc30_.height + 35;
               _loc70_.touchable = true;
               _loc70_.addEventListener("touch",maze_Touch);
               _uiMain.addChild(_loc70_);
            }
            else
            {
               _loc27_.text = _loc4_;
               _loc7_.text = _loc34_;
               _loc12_.text = _loc54_;
               _loc11_.text = _loc50_;
               _loc26_.text = _loc6_;
               _loc69_.text = _loc47_;
               _loc9_.text = _loc49_;
            }
            _loc7_.x = _loc27_.x + _loc27_.textBounds.width + 5;
            _loc7_.y = _loc27_.y + 3;
            if(_loc55_[0] > 0)
            {
               _loc18_ = new LOL_Button(_loc55_[0] + "","UI_love_bg_0000");
               _loc18_.name = "_loveBtn2";
               _loc18_.fontSize = 14;
               _loc18_.fontColor = 16777215;
               _loc18_.x = MainConfig.$isEA ? _loc27_.x + 60 : _loc27_.x + 30;
               _loc18_.y = _loc27_.y - 85;
               _loc18_.textPoint = new Point(-3,-5);
               _uiMain.addChild(_loc18_);
               _loc18_.addEventListener("triggered",onTRIGGERED_love);
            }
         }
         else
         {
            _loc67_ = new LOL_Button("","UI_bg_herobg0000");
            _loc67_.pivotX = _loc67_.width / 2;
            _loc67_.pivotY = _loc67_.height * 0.95;
            _loc67_.x = GlobalData.$mStageWidth / 2;
            _loc67_.y = _bg1.height / 2 + 20;
            _roleMain.addChild(_loc67_);
            _loc10_ = new LOL_TextField(GlobalLanguageStr.getLanguageStr(10127),200,30);
            _loc10_.fontSize = 30;
            _loc10_.fontColor = 16777215;
            _loc10_.pivotX = _loc10_.width / 2;
            _loc10_.pivotY = _loc10_.height / 2;
            _loc10_.x = GlobalData.$mStageWidth / 2 + 30;
            _loc10_.y = _loc67_.y + 20;
            _roleMain.addChild(_loc10_);
         }
         if(_avatar && _avatar.skillB)
         {
            _loc27_.x = _loc46_.x;
            _loc27_.y = _loc46_.y + 42;
            _loc7_.x = _loc27_.x + _loc27_.textBounds.width + 5;
            _loc7_.y = _loc27_.y + 3;
            _loc45_.x = _loc46_.x + 210;
            _loc15_.x = _loc45_.x;
            _loc15_.y = _loc45_.y + 39;
            _loc26_.x = _loc15_.x + _loc15_.width + 5;
            _loc26_.y = _loc15_.y + 2;
            _loc12_.visible = _loc11_.visible = false;
            _loc69_.x = _loc46_.x;
            _loc9_.x = _loc45_.x;
            _quadSkill1.width = _quadSkill2.width = 176;
            _quadSkill1.height = _quadSkill2.height = 114;
            _quadSkill1.y = _quadSkill2.y = _quadSkill2.y = _loc30_.y;
            _quadSkill2.x = _loc45_.x;
            skillPassiveBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20513),86,35,"UI_btn_3_0000",false);
            skillPassiveBtn.name = "skillPassiveBtn";
            skillPassiveBtn.x = _loc45_.x + 200;
            skillPassiveBtn.y = _loc45_.y;
            skillPassiveBtn.style(GlobalConfig.FONT_0,20,_avatar && _avatar.skillB ? 16777215 : 6710886);
            skillPassiveBtn.name = _avatar && _avatar.skillB ? _avatar.skillB.skillSetData.id : "";
            _uiMain.addChild(skillPassiveBtn);
            skillPassiveBtn.addEventListener("triggered",onTRIGGERED_btn);
            skillPassiveTxt = new LOL_TextField(GlobalLanguageStr.getLanguageStr(20489,_avatar.skillB.skillSetData.name),130,35);
            skillPassiveTxt.fontSize = 20;
            skillPassiveTxt.vAlign = "center";
            skillPassiveTxt.x = skillPassiveBtn.x;
            skillPassiveTxt.y = skillPassiveBtn.y + 42;
            skillPassiveTxt.touchable = false;
            _uiMain.addChild(skillPassiveTxt);
            _quadSkillPassive = new Quad(145,114);
            _quadSkillPassive.name = "_quadSkillPassive";
            _quadSkillPassive.x = skillPassiveBtn.x;
            _quadSkillPassive.y = _loc30_.y;
            _quadSkillPassive.alpha = 0.01;
            _quadSkillPassive.name = _avatar && _avatar.skillB ? _avatar.skillB.skillSetData.id : "";
            _uiMain.addChild(_quadSkillPassive);
            _quadSkillPassive.addEventListener("touch",quadSkill_Touch);
            _loc21_ = GlobalLanguageStr.getLanguageStr(25021,_avatar.skillB.skillSetData.warmup,_avatar.skillB.skillSetData.cooldown);
            txtSkillDescPassive = new LOL_TextField(_loc21_,150,50);
            txtSkillDescPassive.style(GlobalConfig.FONT_0,15,1118481,"left");
            txtSkillDescPassive.x = skillPassiveBtn.x;
            txtSkillDescPassive.y = skillPassiveBtn.y + skillPassiveBtn.height + 39;
            _uiMain.addChild(txtSkillDescPassive);
         }
      }

      private function maze_Touch(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(this,"ended");
         if(_loc2_)
         {
            if(GlobalData.$maze_BattleId == "" || GlobalData.$maze_CombatId == "")
            {
               return;
            }
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pve",false,false,null,true);
            GlobalData.$mGameClassObject.closePopForPanel();
         }
      }

      public function update_Lock() : void
      {
         var _loc1_:ItemEquip = null;
         if(_avatar && GlobalData.$userData.avatars[_avatar.id] != null && _isShowLock)
         {
            if(_lockImg)
            {
               _lockImg.removeEventListener("triggered",onTRIGGERED_lock);
               _lockImg.removeFromParent(true);
               _lockImg = null;
            }
            _lock = GlobalFunction.checkLock(_avatar.id);
            if(_lock)
            {
               _lockImg = GlobalFunction.createButton_5("","UI_icon_lock_1_0000");
            }
            else
            {
               _lockImg = GlobalFunction.createButton_5("","UI_icon_lock_0_0000");
            }
            _lockImg.scaleX = _lockImg.scaleY = 0.8;
            _loc1_ = null;
            if(_euqipMain.numChildren != 0)
            {
               _loc1_ = _euqipMain.getChildAt(_euqipMain.numChildren - 1) as ItemEquip;
               _lockImg.x = _loc1_.x - _lockImg.width;
               _lockImg.y = _iconBg.y - _lockImg.height;
            }
            else
            {
               _lockImg.x = _width - 100;
               _lockImg.y = _iconBg.y - _lockImg.height;
            }
            _lockImg.name = "_lockImg1";
            _lockImg.addEventListener("triggered",onTRIGGERED_lock);
            _uiMain.addChild(_lockImg);
         }
      }

      private function update_Power(param1:Boolean = false, param2:Boolean = true) : void
      {
         if(_avatar && GlobalData.$userData.avatars[_avatar.id] != null)
         {
            if(_powerTxt)
            {
               _powerTxt.removeFromParent(true);
               _powerTxt = null;
            }
            _powerTxt = new LOL_IconText(GlobalLanguageStr.getLanguageStr(10133) + _avatar.getPower(param1,-1,param2));
            _powerTxt.bgWidth = _width - 150 - 40;
            _powerTxt.x = 90;
            _powerTxt.y = _topXY.y + _topXY.height + 10;
            _uiMain.addChild(_powerTxt);
         }
      }

      private function onTRIGGERED_lock(param1:Event) : void
      {
         _lock = !_lock;
         if(_lockImg)
         {
            _lockImg.removeEventListener("triggered",onTRIGGERED_lock);
            _lockImg.removeFromParent(true);
            _lockImg = null;
         }
         if(_lock)
         {
            _lockImg = GlobalFunction.createButton_5("","UI_icon_lock_1_0000");
         }
         else
         {
            _lockImg = GlobalFunction.createButton_5("","UI_icon_lock_0_0000");
         }
         _lockImg.scaleX = _lockImg.scaleY = 0.8;
         var _loc3_:ItemEquip = null;
         if(_euqipMain.numChildren != 0)
         {
            _loc3_ = _euqipMain.getChildAt(_euqipMain.numChildren - 1) as ItemEquip;
            _lockImg.x = _loc3_.x - _lockImg.width;
            _lockImg.y = _iconBg.y - _lockImg.height;
         }
         else
         {
            _lockImg.x = _width - 100;
            _lockImg.y = _iconBg.y - _lockImg.height;
         }
         GlobalFunction.changeLock(_avatar.id,_lock);
         if(GlobalData.$tempLockItem)
         {
            GlobalData.$tempLockItem["fun"]();
         }
         if(mFoster2)
         {
            mFoster2.x = _lockImg.x - mFoster2.width - 10;
            mFoster2.y = _lockImg.y + 30;
         }
         if(mFoster)
         {
            mFoster.x = _lockImg.x - mFoster.width - 10;
            mFoster.y = _lockImg.y + 30;
         }
         var _loc2_:String = "";
         if(_lock)
         {
            _loc2_ = GlobalLanguageStr.getLanguageStr(90455);
         }
         else
         {
            _loc2_ = GlobalLanguageStr.getLanguageStr(90456);
         }
         LayoutUIAnimation.getOnlyExample().popWords(_loc2_);
         _lockImg.addEventListener("triggered",onTRIGGERED_lock);
         _uiMain.addChild(_lockImg);
      }

      private function onTRIGGERED_btn(param1:Event) : void
      {
         var _loc3_:String = null;
         var _loc5_:SkillSet = null;
         var _loc2_:String = null;
         var _loc4_:String = null;
         if(_avatar)
         {
            _loc3_ = (param1.currentTarget as LOL_Scale9Button).name;
            if(_loc3_ == "")
            {
               return;
            }
            _loc5_ = new SkillSet(_loc3_,_avatar,_avatar.skill0 && _avatar.skill0.skillSetData.id == _loc3_ ? _avatar.slv : 1,_avatar.skill1 && _avatar.skill1.skillSetData.id == _loc3_);
            _loc4_ = _loc5_.skillSetData.name;
            _loc2_ = _loc5_.getInfoDetails() + "\n";
            _loc2_ = Tools.formatLineX(_loc2_,GlobalTextStyle.COLOR_W_W_Y_G);
            GlobalFunction.popAlert(_loc4_,_loc2_,{"res":_avatar.resId});
         }
      }

      private function quadSkill_Touch(param1:TouchEvent) : void
      {
         var _loc4_:String = null;
         var _loc6_:SkillSet = null;
         var _loc2_:String = null;
         var _loc5_:String = null;
         var _loc3_:Touch = param1.getTouch(this,"ended");
         if(_loc3_)
         {
            if(_avatar)
            {
               _loc4_ = (param1.currentTarget as Quad).name;
               if(_loc4_ == "")
               {
                  return;
               }
               _loc6_ = new SkillSet(_loc4_,_avatar,_avatar.skill0 && _avatar.skill0.skillSetData.id == _loc4_ ? _avatar.slv : 1,_avatar.skill1 && _avatar.skill1.skillSetData.id == _loc4_);
               _loc5_ = _loc6_.skillSetData.name;
               _loc2_ = _loc6_.getInfoDetails() + "\n";
               _loc2_ = Tools.formatLineX(_loc2_,GlobalTextStyle.COLOR_W_W_Y_G);
               GlobalFunction.popAlert(_loc5_,_loc2_,{"res":_avatar.resId},false);
            }
         }
      }

      private function role_Triggered(param1:Event) : void
      {
         if(this.x >= 0 && this.x < 5)
         {
            if(_data.id != "" && _data.id != null)
            {
               LayoutUIAnimation.getOnlyExample().clear();
               GlobalData.$tempChangeAvatarTitle = GlobalLanguageStr.getLanguageStr(90487);
               GlobalData.$tempTeamSelect = this._data;
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_detailall",false,true);
            }
         }
      }

      private function role1_Triggered(param1:Event) : void
      {
         if(this.x >= 0 && this.x < 5)
         {
            LayoutUIAnimation.getOnlyExample().clear();
            GlobalData.$tempChangeAvatarTitle = GlobalLanguageStr.getLanguageStr(90487);
            GlobalData.$tempTeamSelect = this._data;
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_team_avatar",false,true);
         }
      }

      public function updateEquip() : void
      {
         var _loc1_:Boolean = false;
         var _loc10_:Object = null;
         var _loc4_:Array = null;
         var _loc3_:Object = null;
         var _loc14_:Object = null;
         var _loc6_:Object = null;
         var _loc15_:ItemEquip = null;
         var _loc11_:int = 0;
         var _loc13_:int = 0;
         var _loc17_:int = 0;
         var _loc18_:int = 0;
         var _loc12_:int = 0;
         var _loc8_:int = 0;
         StarlingTools.removeChildrenClear(_euqipMain);
         var _loc16_:Array = GlobalData.$mConfig.system_simple.equip_show;
         var _loc7_:int = 0;
         var _loc2_:int = 0;
         var _loc9_:Array = [];
         var _loc5_:Object = null;
         if(_type == "show_type_team")
         {
            _loc2_ = int(GlobalData.$tempTeamSelect["indexID_s"]);
            _loc7_ = int(GlobalData.$userData.lv);
            _loc9_ = GlobalData.$userData.as_equips[_loc2_];
            _loc5_ = GlobalData.$userData.my_equips;
            if(_avatar)
            {
               _avatar.setEquips();
               _avatar.setDestinyAndDN();
               _avatar.initFightAttr();
            }
         }
         else if(_type == "show_type_dynamic")
         {
            _loc2_ = int(GlobalData.$tempTeamSelect_Other["indexID_s"]);
            _loc7_ = int(GlobalData.$pvp_rival.lv);
            _loc1_ = Boolean(GlobalData.$pvp_rival["isRobot"]);
            _loc10_ = GlobalData.$pvp_rival;
            _loc4_ = _loc10_.data != null ? _loc10_.data : _loc10_["data_base"];
            _loc3_ = GlobalFunction.setOtherCfgAvatarsObj(_loc4_);
            _loc14_ = GlobalFunction.getPVPenemyEquip(_loc1_ ? [] : (_loc4_[_loc2_][10] != null ? _loc4_[_loc2_][10] : null),_loc1_);
            _loc9_ = _loc14_.as_equips;
            _loc5_ = _loc14_.my_equips;
            if(_avatar)
            {
               _avatar.setEquips(_loc9_,false,_loc5_);
               _avatar.setDestinyAndDN(_loc4_[_loc2_][0],_loc3_.team,_loc9_,_loc5_,_loc3_.dn);
               _avatar.initFightAttr();
            }
         }
         setDestinyTxts(null);
         mTxt_destiny.reInit("");
         if(_avatar)
         {
            if(!_avatar.mDestiny || _avatar.mDestiny.nameArr == null || _avatar.getPurpleBondDescription() != "")
            {
               mTxt_destiny.reInit(_avatar.getDestinyDescription());
            }
            else
            {
               setDestinyTxts(_avatar.mDestiny.nameArr,mTxt_destiny.x,mTxt_destiny.y);
            }
         }
         if(_loc9_.length == 0)
         {
            _loc9_ = [null,null,null,null,null,null];
         }
         _loc11_ = 0;
         while(_loc11_ < _loc9_.length)
         {
            if(_loc9_[_loc11_] != null)
            {
               _loc6_ = _loc5_[_loc9_[_loc11_]];
               _loc6_["id"] = _loc9_[_loc11_];
            }
            else
            {
               _loc6_ = {};
               _loc6_["id"] = null;
            }
            _loc6_["indexID_s"] = _loc11_;
            _loc6_["status"] = 0;
            _loc6_["isPVP"] = 0;
            _loc6_["lvMax"] = 1;
            _loc6_["teamNum"] = _loc2_;
            _loc6_["sympClip"] = false;
            _loc13_ = int(_loc6_["indexID_s"]);
            _loc6_["lock"] = _loc7_ >= _loc16_[_loc13_] ? 0 : 1;
            _loc6_["lockdesc"] = _loc16_[_loc13_];
            if(_type == "show_type_dynamic")
            {
               _loc6_["status"] = -1;
               _loc6_["lock"] = 0;
            }
            else if(_type == "show_type_dynamic")
            {
               _loc6_["status"] = -1;
            }
            else if(_loc6_["id"] == null)
            {
               _loc6_["status"] = 0;
            }
            else
            {
               _loc6_["status"] = 5;
            }
            if(_loc6_.symp != null)
            {
               if(_type == "show_type_dynamic")
               {
                  _loc6_["sympClip"] = GlobalFunction.checkIsSympSame(_loc9_[_loc11_],_loc6_.symp,_loc2_,_loc9_,_loc5_);
               }
               else
               {
                  _loc6_["sympClip"] = GlobalFunction.checkIsSympSame(_loc9_[_loc11_],_loc6_.symp,_loc2_);
               }
            }
            _loc15_ = new ItemEquip();
            _loc15_.width = 100;
            _loc15_.data = _loc6_;
            _loc15_.scaleX = _loc15_.scaleY = 0.8;
            _loc17_ = _icon.y - (_topXY.y + _topXY.height);
            _loc18_ = 0;
            _loc12_ = 25;
            if(_type == "show_type_dynamic")
            {
               _loc15_.x = _loc11_ % 2 * (_width - 150 - 20) + 10 + _loc11_ % 2 * 75 - 2;
               _loc18_ = 215;
               _loc12_ = 10;
            }
            else
            {
               _loc15_.x = _loc11_ % 2 * (_width - 150 - 40) + 20 + _loc11_ % 2 * 75 - 3;
               _loc18_ = 245;
               _loc12_ = 25;
            }
            _loc8_ = (_loc17_ - _loc18_) / 2 + _topXY.y + _topXY.height;
            _loc15_.y = _loc8_ + int(_loc11_ / 2) * (_loc12_ + 75);
            _euqipMain.addChild(_loc15_);
            _loc11_++;
         }
      }

      private function onType(param1:TouchEvent) : void
      {
         var _loc2_:String = null;
         var _loc8_:AvatarData = null;
         var _loc3_:Number = NaN;
         var _loc5_:* = 0;
         var _loc6_:* = 0;
         var _loc7_:String = null;
         var _loc4_:Touch = param1.getTouch(this,"ended");
         if(_loc4_)
         {
            if(_avatar)
            {
               _loc2_ = "";
               _loc8_ = _avatar.avatarData;
               _loc3_ = Number(GlobalData.$mConfig_simple.attack[2]);
               if(_avatar.morph > 0)
               {
                  _loc2_ += GlobalLanguageStr.getLanguageStr(20230);
                  _loc2_ += "\n";
               }
               if(_loc8_.signType == 1)
               {
                  _loc2_ += GlobalLanguageStr.getLanguageStr(20237,GameMapTools.toPercentage(_loc3_));
               }
               else if(_loc8_.signType == 2)
               {
                  _loc2_ += GlobalLanguageStr.getLanguageStr(20238,GameMapTools.toPercentage(_loc3_));
               }
               else if(_loc8_.signType == 3)
               {
                  _loc2_ += GlobalLanguageStr.getLanguageStr(20239,GameMapTools.toPercentage(_loc3_));
               }
               _loc2_ += "\n";
               if(_loc8_.damageType == 1)
               {
                  _loc2_ += GlobalLanguageStr.getLanguageStr(20240);
               }
               else if(_loc8_.damageType == 2)
               {
                  _loc2_ += GlobalLanguageStr.getLanguageStr(20241);
               }
               else if(_loc8_.damageType == 3)
               {
                  _loc2_ += GlobalLanguageStr.getLanguageStr(20242);
               }
               _loc2_ += "\n";
               if(_loc8_.actionType == 1)
               {
                  _loc2_ += GlobalLanguageStr.getLanguageStr(20243);
               }
               else if(_loc8_.actionType == 2)
               {
                  _loc2_ += GlobalLanguageStr.getLanguageStr(20244);
               }
               else if(_loc8_.actionType == 3)
               {
                  _loc2_ += GlobalLanguageStr.getLanguageStr(20245);
               }
               else if(_loc8_.actionType == 4)
               {
                  _loc2_ += GlobalLanguageStr.getLanguageStr(20235);
               }
               _loc5_ = uint(_avatar.getStar());
               _loc6_ = uint(_avatar.avatarData.getMaxStar());
               _loc7_ = _avatar.avatarData.name;
               if(_loc6_ > _loc5_)
               {
                  _loc7_ += " " + GlobalLanguageStr.getLanguageStr(20227,_loc6_);
               }
               _loc2_ = Tools.formatLineX(_loc2_,GlobalTextStyle.COLOR_W_Y_Y_G);
               GlobalFunction.popAlert(_loc7_,_loc2_,{"res":_avatar.resId},false);
               SoundManager.getOnlyExample().playAvatar(_avatar.avatarData.soundId);
               param1.stopPropagation();
            }
         }
      }

      private function onTRIGGERED_love(param1:Event) : void
      {
         var _loc3_:Array = null;
         var _loc5_:int = 0;
         var _loc4_:String = null;
         var _loc2_:String = null;
         if(_avatar)
         {
            _loc3_ = _avatar.getLoveList();
            _loc5_ = _avatar.getLeadership(true) - _avatar.getLeadership();
            _loc4_ = GlobalLanguageStr.getLanguageStr(20225,_loc3_[0],_loc5_,GlobalData.$mConfig_simple.love_up[0]);
            _loc4_ = Tools.formatLineX(_loc4_,GlobalTextStyle.COLOR_W_Y_Y_G);
            _loc2_ = GlobalData.$mConfig_simple.show_id[17];
            GlobalFunction.popAlert("",_loc4_,{"aid":_loc2_});
         }
      }

      private function REMOVED_FROM_STAGE(param1:Event) : void
      {
         removeEventListener("removedFromStage",REMOVED_FROM_STAGE);
         clear();
      }

      public function get data() : Object
      {
         return _data;
      }

      public function clear() : void
      {
         var _loc17_:LOL_Scale9Button = null;
         var _loc13_:Quad = null;
         var _loc2_:LOL_Scale9Button = null;
         var _loc12_:Quad = null;
         var _loc5_:Quad = null;
         var _loc4_:LOL_Button = null;
         var _loc18_:LOL_Button = null;
         var _loc20_:LOL_Button = null;
         var _loc7_:Quad = null;
         var _loc19_:Quad = null;
         var _loc14_:LOL_Scale9Button = null;
         var _loc21_:LOL_Scale9Button = null;
         var _loc10_:Quad = null;
         var _loc11_:Quad = null;
         var _loc16_:LOL_HtmlText = null;
         var _loc6_:LOL_Button = null;
         var _loc9_:LOL_Button = null;
         var _loc1_:Quad = null;
         var _loc3_:Quad = null;
         var _loc8_:LOL_Scale9Button = null;
         var _loc15_:Quad = null;
         if(_topBg)
         {
            _topBg.removeFromParent();
            _topBg = null;
         }
         if(_bg1Spr)
         {
            _bg1Spr.removeFromParent();
            _bg1Spr = null;
         }
         if(_bg1)
         {
            _bg1.removeFromParent();
            _bg1 = null;
         }
         if(_bg2)
         {
            _bg2.removeFromParent();
            _bg2 = null;
         }
         if(_roleMain)
         {
            StarlingTools.removeChildrenClear(_roleMain);
            _roleMain = null;
         }
         if(_uiMain)
         {
            _loc17_ = _uiMain.getChildByName("btn1") as LOL_Scale9Button;
            if(_loc17_)
            {
               _loc17_.removeEventListener("triggered",onTRIGGERED_btn);
               _loc17_.removeFromParent();
               _loc17_ = null;
            }
            _loc13_ = _uiMain.getChildByName("_quadType") as Quad;
            if(_loc13_)
            {
               _loc13_.removeEventListener("touch",onType);
               _loc13_.removeFromParent();
               _loc13_ = null;
            }
            _loc2_ = _uiMain.getChildByName("btn2") as LOL_Scale9Button;
            if(_loc2_)
            {
               _loc2_.removeEventListener("triggered",onTRIGGERED_btn);
               _loc2_.removeFromParent();
               _loc2_ = null;
            }
            _loc12_ = _uiMain.getChildByName("_quadSkill1") as Quad;
            if(_loc12_)
            {
               _loc12_.removeEventListener("touch",quadSkill_Touch);
               _loc12_.removeFromParent();
               _loc12_ = null;
            }
            _loc5_ = _uiMain.getChildByName("_quadSkill2") as Quad;
            if(_loc5_)
            {
               _loc5_.removeEventListener("touch",quadSkill_Touch);
               _loc5_.removeFromParent();
               _loc5_ = null;
            }
            _loc4_ = _uiMain.getChildByName("_loveBtn") as LOL_Button;
            if(_loc4_)
            {
               _loc4_.removeEventListener("triggered",onTRIGGERED_love);
               _loc4_.removeFromParent();
               _loc4_ = null;
            }
            _loc18_ = _uiMain.getChildByName("_role1") as LOL_Button;
            if(_loc18_)
            {
               _loc18_.removeEventListener("triggered",role1_Triggered);
               _loc18_.removeFromParent();
               _loc18_ = null;
            }
            _loc20_ = _uiMain.getChildByName("_role") as LOL_Button;
            if(_loc20_)
            {
               _loc20_.removeEventListener("triggered",role_Triggered);
               _loc20_.removeFromParent();
               _loc20_ = null;
            }
            _loc7_ = _uiMain.getChildByName("quadPith") as Quad;
            if(_loc7_)
            {
               _loc7_.removeFromParent();
               _loc7_ = null;
            }
            _loc19_ = _uiMain.getChildByName("quadType") as Quad;
            if(_loc19_)
            {
               _loc19_.removeEventListener("touch",onType);
               _loc19_.removeFromParent();
               _loc19_ = null;
            }
            _loc14_ = _uiMain.getChildByName("_btn1") as LOL_Scale9Button;
            if(_loc14_)
            {
               _loc14_.removeEventListener("triggered",onTRIGGERED_btn);
               _loc14_.removeFromParent();
               _loc14_ = null;
            }
            _loc21_ = _uiMain.getChildByName("_btn2") as LOL_Scale9Button;
            if(_loc21_)
            {
               _loc21_.removeEventListener("triggered",onTRIGGERED_btn);
               _loc21_.removeFromParent();
               _loc21_ = null;
            }
            _loc10_ = _uiMain.getChildByName("quadSkill11") as Quad;
            if(_loc10_)
            {
               _loc10_.removeEventListener("touch",quadSkill_Touch);
               _loc10_.removeFromParent();
               _loc10_ = null;
            }
            _loc11_ = _uiMain.getChildByName("quadSkill22") as Quad;
            if(_loc11_)
            {
               _loc11_.removeEventListener("touch",quadSkill_Touch);
               _loc11_.removeFromParent();
               _loc11_ = null;
            }
            _loc16_ = _uiMain.getChildByName("_infoTxt") as LOL_HtmlText;
            if(_loc16_)
            {
               _loc16_.removeEventListener("touch",maze_Touch);
               _loc16_.removeFromParent();
               _loc16_ = null;
            }
            _loc6_ = _uiMain.getChildByName("_loveBtn2") as LOL_Button;
            if(_loc6_)
            {
               _loc6_.removeEventListener("triggered",onTRIGGERED_love);
               _loc6_.removeFromParent();
               _loc6_ = null;
            }
            _loc9_ = _uiMain.getChildByName("_lockImg1") as LOL_Button;
            if(_loc9_)
            {
               _loc9_.removeEventListener("triggered",onTRIGGERED_lock);
               _loc9_.removeFromParent();
               _loc9_ = null;
            }
            _loc1_ = _uiMain.getChildByName("_quadRole22") as Quad;
            if(_loc1_)
            {
               _loc1_.removeEventListener("touch",quadRole_Touch);
               _loc1_.removeFromParent();
               _loc1_ = null;
            }
            _loc3_ = _uiMain.getChildByName("_quadPith22") as Quad;
            if(_loc3_)
            {
               _loc3_.removeFromParent();
               _loc3_ = null;
            }
            _loc8_ = _uiMain.getChildByName("skillPassiveBtn") as LOL_Scale9Button;
            if(_loc8_)
            {
               _loc8_.removeEventListener("triggered",onTRIGGERED_btn);
               _loc8_.removeFromParent();
               _loc8_ = null;
            }
            _loc15_ = _uiMain.getChildByName("_quadSkillPassive") as Quad;
            if(_loc15_)
            {
               _loc15_.removeEventListener("touch",quadSkill_Touch);
               _loc15_.removeFromParent();
               _loc15_ = null;
            }
            StarlingTools.removeChildrenClear(_uiMain);
            _uiMain = null;
         }
         if(_euqipMain)
         {
            StarlingTools.removeChildrenClear(_euqipMain);
            _euqipMain = null;
         }
         if(_icon)
         {
            _icon.removeFromParent();
            _icon = null;
         }
         if(_iconBg)
         {
            _iconBg.removeFromParent();
            _iconBg = null;
         }
         if(mTxt_destiny)
         {
            mTxt_destiny.removeFromParent();
            mTxt_destiny = null;
         }
         if(mDestinyBox)
         {
            mDestinyBox.removeFromParent();
            mDestinyBox = null;
         }
         if(mBox_P)
         {
            mBox_P.removeFromParent();
            mBox_P = null;
         }
         if(_lockImg)
         {
            _lockImg.removeFromParent();
            _lockImg = null;
         }
         if(_powerTxt)
         {
            _powerTxt.removeFromParent();
            _powerTxt = null;
         }
         if(_quadRole)
         {
            _quadRole.removeEventListener("touch",quadRole_Touch);
            _quadRole.removeFromParent();
            _quadRole = null;
         }
         if(_quadPith)
         {
            _quadPith.removeFromParent();
            _quadPith = null;
         }
         if(_quadSkill1)
         {
            _quadSkill1.removeFromParent();
            _quadSkill1 = null;
         }
         if(_quadSkill2)
         {
            _quadSkill2.removeFromParent();
            _quadSkill2 = null;
         }
         if(_quadType)
         {
            _quadType.removeFromParent();
            _quadType = null;
         }
         if(_quadFoster1)
         {
            _quadFoster1.removeEventListener("touch",quadPith_Touch);
            _quadFoster1.removeFromParent(true);
            _quadFoster1 = null;
         }
         if(_quadFoster2)
         {
            _quadFoster2.removeEventListener("touch",quadPith_Touch);
            _quadFoster2.removeFromParent(true);
            _quadFoster2 = null;
         }
         if(mFoster)
         {
            mFoster.removeFromParent(true);
            mFoster = null;
         }
         if(skillPassiveTxt)
         {
            skillPassiveTxt.removeFromParent(true);
            skillPassiveTxt.dispose();
            skillPassiveTxt = null;
         }
         if(txtSkillDescPassive)
         {
            txtSkillDescPassive.removeFromParent(true);
            txtSkillDescPassive.dispose();
            txtSkillDescPassive = null;
         }
         if(talentSp)
         {
            StarlingTools.removeChildrenClear(talentSp);
            talentSp = null;
         }
         if(talentQuad)
         {
            talentQuad.removeFromParent(true);
            talentQuad.dispose();
            talentQuad = null;
         }
         if(_glowMc)
         {
            _glowMc.removeFromParent(true);
            _glowMc.dispose();
            _glowMc = null;
         }
         StarlingTools.removeChildrenClear(this);
      }
   }
}
