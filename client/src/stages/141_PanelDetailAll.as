package com.meng52.game.ui.panel
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
   import com.meng52.game.ui.element.HtmlTextField;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_HtmlText;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.element.LOL_StarLevel;
   import com.meng52.game.ui.element.LOL_TextField;
   import com.meng52.game.ui.screen.PanelCenterMainAvatar;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import starling.animation.Juggler;
   import starling.display.Image;
   import starling.display.MovieClip;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;

   public class PanelDetailAll extends PanelCenterMainAvatar
   {

      protected var _data:*;

      protected var _avatar:Avatar;

      private static const AVATAR_VOICE_FAMILY_IDS:String = "|A_1001|A_1002|A_1003|A_1004|A_1005|A_1006|A_1007|A_1008|A_1009|A_1010|A_1011|A_1012|A_1013|A_1014|A_1015|A_1016|A_1017|A_1018|A_1019|A_1020|A_1021|A_1022|A_1023|A_1024|A_1025|A_1026|A_1027|A_1028|A_1029|A_1030|A_1032|A_1033|A_1036|A_1040|A_1041|A_1045|A_1049|A_1052|A_1053|A_1054|A_1056|A_1060|A_1063|A_1066|A_1068|A_1071|A_1073|A_1074|A_1077|A_1078|A_1079|A_1081|A_1082|A_1083|A_1085|A_1086|A_1090|A_1093|A_1094|A_1095|A_1096|A_1097|A_1098|A_1099|A_1101|A_1103|A_1105|A_1106|A_1108|A_1109|A_1112|A_1113|A_1114|A_1115|A_1117|A_1119|A_1120|A_1123|A_1124|A_1125|A_1126|A_1127|A_1128|A_1129|A_1130|A_1131|A_1132|A_1133|A_1134|A_1135|A_1136|A_1137|A_1138|A_1139|A_1140|A_1142|A_1143|A_1201|A_1202|A_1203|A_1204|A_1205|A_1206|A_1207|A_1208|A_1209|A_1210|A_1211|A_1212|A_1215|A_1216|A_1217|A_1218|A_1219|A_1220|A_1221|A_1222|A_1223|A_1224|A_1225|A_1226|A_1227|A_1228|A_1309|A_1310|A_1311|A_1900|A_1901|A_1902|A_1903|A_1904|A_1905|A_1906|A_1907|A_1908|A_1909|A_1910|A_1998|A_1999|A_2012|";
      private var _detailVoicePlayed:Boolean = false;
      private var _detailVoiceAvatarId:String = "";

      protected var _topBg:Image;

      protected var _bg1:Image;

      protected var _bg2:Scale9Image;

      protected var _uiMain:Sprite;

      protected var _euqipMain:Sprite;

      protected var _icon:Image;

      protected var _iconBg:Scale9Image;

      protected var _rise:LOL_Scale9Button;

      protected var _up:LOL_Scale9Button;

      protected var _reset:LOL_Scale9Button;

      protected var _foster:LOL_Scale9Button;

      public var mTxt_destiny:ScrollScreenForTxt;

      private var _roleMain:Sprite;

      private var mBox_P:Sprite;

      protected var _width:int;

      protected var _height:int;

      private var _bg1Spr:Sprite;

      private var _lockImg:LOL_Button;

      private var _lock:Boolean = false;

      private var _quadPith:Quad;

      private var _quadSkill1:Quad;

      private var _quadSkill2:Quad;

      private var _quadType:Quad;

      private var _quadFoster1:Quad;

      private var mFoster:LOL_TextField;

      private var _isGuide:Boolean = true;

      private var skillPassiveBtn:LOL_Scale9Button;

      private var skillPassiveTxt:LOL_TextField;

      private var _quadSkillPassive:Quad;

      private var txtSkillDescPassive:LOL_TextField;

      private var talentSp:Sprite;

      private var talentQuad:Quad;

      private var _glowMc:MovieClip;

      public function PanelDetailAll()
      {
         super();
         data(GlobalData.$tempTeamSelect);
         addEventListener("addedToStage",onDetailsAdded);
      }

      private function onDetailsAdded(param1:Event) : void
      {
         if(_detailVoicePlayed || !_avatar || !_avatar.avatarData)
         {
            return;
         }
         _detailVoicePlayed = true;
         var _loc2_:String = getAvatarVoiceId();
         if(_loc2_ != "")
         {
            // Keep the native sound toggle/cooldown; 0.5 stays non-negative
            // before SoundManager applies its 1.5x transform.
            SoundManager.getOnlyExample().playAvatar(_loc2_,0.5);
         }
      }

      private function getAvatarVoiceId() : String
      {
         var _loc2_:String = _avatar.avatarData.soundId;
         if(_loc2_.indexOf("MOD_") == 0 && GlobalData.$assetManager.getSound(_loc2_) != null) return _loc2_;
         var voiceDefinition:Object = GlobalData.$mConfig_avatar[_avatar.avatarData.id];
         if(voiceDefinition != null && voiceDefinition.hasOwnProperty("modVoice")) return _loc2_;
         // The exact asset audit found no dedicated family audio for these two
         // reviewed skins; use their confirmed prototype families instead.
         if(_loc2_ == "A_1213")
         {
            _loc2_ = "A_1021";
         }
         else if(_loc2_ == "A_1214")
         {
            _loc2_ = "A_1096";
         }
         if(AVATAR_VOICE_FAMILY_IDS.indexOf("|" + _loc2_ + "|") < 0)
         {
            return "";
         }
         return _loc2_;
      }

      override public function onTRIGGERED_closePanel(param1:Event) : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.reSetLastPanel_ID();
         super.onTRIGGERED_closePanel(null);
      }

      override protected function initializeHandler(param1:Event) : void
      {
         _width = 575;
         _height = GlobalData.$center_height_curr + 50;
         setPopPanelBg(getDisplayAvatarName(),_height);
         _bg1 = GlobalFunction.createImage("UI_bg_0_10_",true);
         var _loc4_:Number = (_bg1.height - (_height - 510) - 140) / 2;
         _bg1Spr = new Sprite();
         _bg1Spr.addChild(_bg1);
         _bg1Spr.clipRect = new Rectangle((_bg1.width - _width) / 2,_loc4_,_width,640);
         _bg1Spr.y = 80 - _loc4_;
         _bg1Spr.x = 0;
         addChild(_bg1Spr);
         _bg2 = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",_width,250,new Rectangle(110,55,70,20));
         _bg2.x = (GlobalData.$mStageWidth - _bg2.width) / 2 + 1;
         _bg2.y = _height - 345;
         addChild(_bg2);
         _roleMain = new Sprite();
         addChild(_roleMain);
         _icon = GlobalFunction.createImage("UI_icon_1_0000");
         _icon.x = _bg2.x + 5;
         _icon.y = _height - 510;
         addChild(_icon);
         _iconBg = GlobalFunction.createScale9Image("UI_bg_9slice_5_0000",_width - _icon.width - 30,130,new Rectangle(30,20,50,30));
         _iconBg.x = _icon.x + _icon.width + 10;
         _iconBg.y = _icon.y;
         addChild(_iconBg);
         mTxt_destiny = new ScrollScreenForTxt("",_iconBg.width - 25,_iconBg.height - 30);
         mTxt_destiny.x = _iconBg.x + 15;
         mTxt_destiny.y = _iconBg.y + 10;
         addChild(mTxt_destiny);
         if(_avatar)
         {
            if(_avatar.talent != null)
            {
               talentSp = new Sprite();
               talentSp.x = _iconBg.x + 10;
               talentSp.y = _iconBg.y - 60;
               this.addChild(talentSp);
               talentSp.addChild(Talent.getImage(_avatar.talent.id));
               talentQuad = Tools.newQuad(talentSp.width,talentSp.height,talentSp.x,talentSp.y,0);
               talentQuad.alpha = 0;
               this.addChild(talentQuad);
               talentQuad.addEventListener("touch",talentTouch);
               showGlow();
            }
         }
         _uiMain = new Sprite();
         addChild(_uiMain);
         _euqipMain = new Sprite();
         addChild(_euqipMain);
         update();
         _rise = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20085),135,65);
         _rise.x = 30;
         _rise.y = _height - 95;
         addChild(_rise);
         _up = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20092),135,65);
         _up.x = 175;
         _up.y = _rise.y;
         addChild(_up);
         _foster = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90553),135,65);
         _foster.x = 320;
         _foster.y = _rise.y;
         addChild(_foster);
         _reset = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(25025),135,65);
         _reset.x = 465;
         _reset.y = _rise.y;
         addChild(_reset);
         var _loc3_:Object = GlobalData.$mConfig_simple.culture;
         var _loc2_:Number = _avatar.getStar();
         if(GlobalFunction.checkSearchTypeByType(_avatar.id,2) || GlobalFunction.checkSearchTypeByType(_avatar.id,3) || GlobalFunction.checkSearchTypeByType(_avatar.id,4))
         {
            _foster.enabled = false;
         }
         else if(GlobalData.$userData.lv < _loc3_.culture_lv || _loc2_ < _loc3_.avatar_culture[0])
         {
            _foster.enabled = false;
         }
         else
         {
            _foster.enabled = true;
         }
         if(_avatar && _avatar.getPhaseType() == 0)
         {
            _up.enabled = false;
         }
         else
         {
            _up.enabled = true;
         }
         if(_avatar && _avatar.getLvMax() != 1)
         {
            _rise.enabled = true;
         }
         else
         {
            _rise.enabled = false;
         }
         _rise.addEventListener("triggered",rise_Triggered);
         _up.addEventListener("triggered",up_Triggered);
         _foster.addEventListener("triggered",foster_Triggered);
         _reset.addEventListener("triggered",reset_Triggered);
         GlobalData.$mEventDispatcher.addEventListener("change_team_member",CHANGE_TEAM_MEMBER);
         GlobalData.$mEventDispatcher.addEventListener("update_avatar_foster",UPDATE_AVATAR_FOSTER);
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

      private function UPDATE_AVATAR_FOSTER(param1:Event) : void
      {
         data(param1.data.data);
         update();
      }

      protected function data(param1:*) : void
      {
         var _loc2_:String = param1 != null && param1.id != null ? String(param1.id) : "";
         if(_loc2_ != _detailVoiceAvatarId)
         {
            _detailVoiceAvatarId = _loc2_;
            _detailVoicePlayed = false;
         }
         _data = param1;
         if(_data.id != null)
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

      private function getDisplayAvatarName() : String
      {
         var _name:String = _avatar && _avatar.avatarData ? _avatar.avatarData.name : "";
         if(_name == null || _name.length == 0)
         {
            return "未命名英雄";
         }
         if(_name.indexOf("待识别单位") == 0 && _name.indexOf("A_") >= 0)
         {
            return "待识别英雄";
         }
         return _name;
      }

      private function formatSkillTiming(param1:String) : String
      {
         if(param1 == null || param1.length == 0)
         {
            return "";
         }
         // Match the compact native detail row visible in retained screenshots
         // and keep long skill descriptions from colliding with the timing row.
         return param1.replace("准备回合：","准备").replace("冷却回合：","冷却").replace("　","回合  ·  ").replace("\r","").replace("\n"," ") + "回合";
      }

      private function getActionTypeLanguageId(param1:int) : int
      {
         if(param1 >= 1 && param1 <= 4)
         {
            return 98299 + param1;
         }
         return 98300;
      }

      private function getSkillDetailsOrFallback(param1:SkillSet) : String
      {
         var _details:String = param1 ? param1.getInfoDetails() : "";
         if(_details == null || _details.replace(/\s/g,"").length == 0)
         {
            return GlobalLanguageStr.getLanguageStr(98305);
         }
         return _details;
      }

      protected function update() : void
      {
         var _loc23_:LOL_TextField = null;
         var _loc50_:Image = null;
         var _loc47_:int = 0;
         var _loc28_:HtmlTextField = null;
         var _loc33_:Object = null;
         var _loc7_:Object = null;
         var _loc40_:Object = null;
         var _loc48_:Object = null;
         var _loc19_:String = null;
         var _loc44_:String = null;
         var _loc45_:LOL_HtmlText = null;
         var _loc12_:LOL_Button = null;
         var _loc15_:String = null;
         if(_uiMain)
         {
            // Detach handlers before clearing the previous rendered detail tree.
            if(_quadSkill1) _quadSkill1.removeEventListener("touch",quadSkill_Touch);
            if(_quadSkill2) _quadSkill2.removeEventListener("touch",quadSkill_Touch);
            if(_quadSkillPassive) _quadSkillPassive.removeEventListener("touch",quadSkill_Touch);
            if(skillPassiveBtn) skillPassiveBtn.removeEventListener("triggered",onTRIGGERED_btn);
            if(_quadFoster1) _quadFoster1.removeEventListener("touch",quadPith_Touch);
            if(_quadType) _quadType.removeEventListener("touch",onType);
            StarlingTools.removeChildrenClear(_uiMain);
            _uiMain.removeFromParent();
            _uiMain.dispose();
            _uiMain = null;
         }
         mBox_P = null;
         _quadPith = null;
         _quadSkill1 = null;
         _quadSkill2 = null;
         _quadSkillPassive = null;
         _quadType = null;
         _quadFoster1 = null;
         _lockImg = null;
         mFoster = null;
         skillPassiveBtn = null;
         skillPassiveTxt = null;
         txtSkillDescPassive = null;
         _uiMain = new Sprite();
         addChild(_uiMain);
         _avatar.setEquips();
         _avatar.setDestinyAndDN();
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
         if(_quadPith)
         {
            _quadPith.removeFromParent(true);
         }
         _quadPith = new Quad(_bg2.width - 200,110);
         _quadPith.x = _bg2.x + 200;
         _quadPith.y = _bg2.y;
         _quadPith.alpha = 0.01;
         _uiMain.addChild(_quadPith);
         mTxt_destiny.reInit("");
         mTxt_destiny.reInit(_avatar.getDestinyDescription());
         var _loc14_:Sprite = new Sprite();
         _loc14_.touchable = false;
         _loc14_.x = -5;
         _loc14_.y = -5;
         _uiMain.addChild(_loc14_);
         var _loc29_:Image = GlobalFunction.createImage("UI_tag_0_000" + (String(_avatar.avatarData.damageType - 1)));
         _loc29_.x = 40;
         _loc29_.y = 90;
         _loc14_.addChild(_loc29_);
         var _loc18_:Image = GlobalFunction.createImage("UI_tag_1_000" + (String(_avatar.avatarData.signType - 1)));
         _loc18_.x = _loc29_.x + int((_loc29_.width - _loc18_.width) * 0.5);
         _loc18_.y = _loc29_.y + int((_loc29_.height - _loc18_.height) * 0.5) - 1;
         _loc14_.addChild(_loc18_);
         var _loc35_:int = getActionTypeLanguageId(_avatar.avatarData.actionType);
         var _loc30_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(_loc35_),150,30);
         _loc30_.x = _loc29_.x + _loc29_.width + 10;
         _loc30_.y = _loc29_.y + 1;
         _loc30_.touchable = true;
         _loc30_.fontSize = 20;
         _loc30_.fontColor = 16777215;
         _loc30_.shadowFilter();
         _loc14_.addChild(_loc29_);
         _loc14_.addChild(_loc18_);
         _loc14_.addChild(_loc30_);
         var _loc31_:uint = uint(_avatar.getStar());
         var _loc49_:uint = uint(_avatar.avatarData.getMaxStar());
         var _loc43_:LOL_StarLevel = new LOL_StarLevel(_loc31_,_loc49_,0.35);
         _loc43_.pivotX = _loc43_.width;
         _loc43_.x = GlobalData.$mStageWidth - 50;
         _loc43_.y = _bg1.y + 105;
         _uiMain.addChild(_loc43_);
         if(_avatar.phase > 0)
         {
            _loc23_ = new LOL_TextField(GlobalLanguageStr.getLanguageStr(20292,_avatar.phase),100,30);
            _loc23_.shadowFilter();
            _loc23_.x = _width - _loc23_.width + 30;
            _loc23_.y = _loc43_.y + 15;
            _loc23_.fontColor = 13696768;
            _loc23_.fontSize = 25;
            _uiMain.addChild(_loc23_);
         }
         var _loc24_:String = _avatar.resId.indexOf(".") > -1 ? _avatar.resId.slice(0,_avatar.resId.length - 1) : _avatar.resId;
         var _loc10_:LOL_Button = new LOL_Button("",_loc24_.split("|")[0]);
         _loc10_.pivotX = _loc10_.width / 2;
         _loc10_.pivotY = _loc10_.height * 0.85;
         _loc10_.x = GlobalData.$mStageWidth / 2;
         _loc10_.y = _bg1.height / 2 + 20;
         _bg1Spr.addChild(_loc10_);
         if(_avatar.morph)
         {
            _loc50_ = DisplayTools.newImg("z_morph");
            _loc50_.scaleX = _loc50_.scaleY = 0.75;
            _loc50_.x = GlobalData.$mStageWidth / 2;
            _loc50_.y = _loc10_.y - 10;
            _loc50_.alpha = 1;
            _bg1Spr.addChild(_loc50_);
         }
         var _loc17_:int = int(_avatar.lv <= 0 ? 1 : _avatar.lv);
         var _loc52_:String = _avatar.getLeadership().toString();
         var _loc25_:int = _avatar.getLeadership(true) - _avatar.getLeadership();
         _loc52_ = GlobalLanguageStr.getLanguageStr(20090,_loc52_);
         var _loc13_:Array = [Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20079,_loc17_ + GlobalLanguageStr.getLanguageStr(20081,_avatar.getLvMax())),GlobalTextStyle.COLOR_4B2C1B_990000,18,MainConfig.$isEA ? 15 : 18),Tools.formatLineX(_loc52_,GlobalTextStyle.COLOR_0x4B2C1B,18,MainConfig.$isEA ? 15 : 18),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20088,_avatar.getSpeed(true)),GlobalTextStyle.COLOR_0x4B2C1B,18,MainConfig.$isEA ? 15 : 18),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20089,_avatar.getRange(true)),GlobalTextStyle.COLOR_0x4B2C1B,18,MainConfig.$isEA ? 15 : 18),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20024,_avatar.getHpMax(-1,-1,true)),GlobalTextStyle.COLOR_0x4B2C1B,18,MainConfig.$isEA ? 15 : 18),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20025,_avatar.getDamage(-1,-1,true)),GlobalTextStyle.COLOR_0x4B2C1B,18,MainConfig.$isEA ? 15 : 18),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20026,_avatar.getDePh(-1,-1,true)),GlobalTextStyle.COLOR_0x4B2C1B,18,MainConfig.$isEA ? 15 : 18),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20027,_avatar.getDeMa(-1,-1,true)),GlobalTextStyle.COLOR_0x4B2C1B,18,MainConfig.$isEA ? 15 : 18),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20034,_avatar.getHit()),GlobalTextStyle.COLOR_0x4B2C1B,18,MainConfig.$isEA ? 15 : 18),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20232,_avatar.getFlee()),GlobalTextStyle.COLOR_0x4B2C1B,18,MainConfig.$isEA ? 15 : 18),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20233,_avatar.getCrit()),GlobalTextStyle.COLOR_0x4B2C1B,18,MainConfig.$isEA ? 15 : 18),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20234,_avatar.getTough()),GlobalTextStyle.COLOR_0x4B2C1B,18,MainConfig.$isEA ? 15 : 18)];
         if(mBox_P)
         {
            StarlingTools.removeChildrenClear(mBox_P);
            mBox_P.removeFromParent(true);
         }
         mBox_P = null;
         mBox_P = new Sprite();
         _uiMain.addChild(mBox_P);
         var _loc16_:Array = [];
         var _loc2_:Image = null;
         mBox_P.x = _bg2.x + 30;
         mBox_P.y = _bg2.y + 15;
         _quadType = new Quad(_bg1.width,45);
         _quadType.x = _loc29_.x;
         _quadType.y = _loc29_.y;
         _quadType.alpha = 0.01;
         _uiMain.addChild(_quadType);
         _quadType.addEventListener("touch",onType);
         var _loc1_:Array = [];
         var _loc41_:Array = _avatar.getLoveList();
         _loc47_ = 0;
         while(_loc47_ < _loc13_.length)
         {
            if(_loc41_[0] > 0 && _loc47_ == 1)
            {
               _loc13_[_loc47_] = Tools.formatLineX(_loc52_,GlobalTextStyle.COLOR_0xFF7777,17,MainConfig.$isEA ? 15 : 17);
            }
            _loc28_ = new HtmlTextField(165,27,_loc13_[_loc47_],true,GlobalConfig.FONT_0);
            _loc28_.touchable = false;
            _loc28_.hAlign = "left";
            _loc28_.vAlign = "top";
            _loc28_.x = int(_loc47_ / 4) * 170;
            _loc28_.y = _loc47_ % 4 * 23;
            mBox_P.addChild(_loc28_);
            _loc1_.push(_loc28_);
            _loc47_++;
         }
         var skillColumnWidth:int = int((_bg2.width - 55) / 2);
         var skillThreeGap:int = 8;
         var skillThreeWidth:int = int((_bg2.width - 50 - skillThreeGap * 2) / 3);
         var hasPassiveSkill:Boolean = _avatar != null && _avatar.skillB != null;
         var skillNameHeight:int = hasPassiveSkill ? 24 : 35;
         var skillNameWidth:int = hasPassiveSkill ? skillThreeWidth - 48 : skillColumnWidth - 146;
         var skillLevelWidth:int = hasPassiveSkill ? 46 : 60;
         var skillLeaderNameWidth:int = hasPassiveSkill ? skillThreeWidth : skillColumnWidth - 120;
         var skillTimingWidth:int = hasPassiveSkill ? skillThreeWidth : skillColumnWidth;
         var _loc22_:Quad = Tools.newQuad(_bg2.width - 50,2);
         _loc22_.color = 10120765;
         _loc22_.x = _bg2.x + 20;
         _loc22_.y = _bg2.y + 120;
         _uiMain.addChild(_loc22_);
         var _loc34_:LOL_Scale9Button = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20212),110,32,"UI_btn_3_0000",false);
         _loc34_.name = _avatar && _avatar.skill0 ? _avatar.skill0.skillSetData.id : "";
         _loc34_.x = _loc22_.x;
         _loc34_.y = _loc22_.y + _loc22_.height;
         _loc34_.style(GlobalConfig.FONT_0,20,_avatar.skill0 ? 16777215 : 6710886);
         _uiMain.addChild(_loc34_);
         var _loc39_:Boolean = false;
         if(_avatar)
         {
            if(_avatar.mDestiny)
            {
               if(_avatar.mDestiny.skill1.length > 0)
               {
                  _loc39_ = true;
               }
            }
         }
         var _loc32_:LOL_Scale9Button = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20212),110,32,"UI_btn_3_0000",false);
         _loc32_.name = _avatar && _avatar.skill1 ? _avatar.skill1.skillSetData.id : "";
         _loc32_.x = _loc34_.x + skillColumnWidth + 10;
         _loc32_.y = _loc34_.y;
         _loc32_.style(GlobalConfig.FONT_0,20,_avatar.skill1 ? (_loc39_ ? 52479 : 16777215) : 6710886);
         _uiMain.addChild(_loc32_);
         _loc34_.addEventListener("triggered",onTRIGGERED_btn);
         _loc32_.addEventListener("triggered",onTRIGGERED_btn);
         _quadSkill1 = new Quad(255,100);
         _quadSkill1.x = _loc34_.x;
         _quadSkill1.y = _loc22_.y + 5;
         _quadSkill1.alpha = 0.01;
         _quadSkill1.name = _avatar && _avatar.skill0 ? _avatar.skill0.skillSetData.id : "";
         _uiMain.addChild(_quadSkill1);
         _quadSkill1.addEventListener("touch",quadSkill_Touch);
         _quadSkill2 = new Quad(255,100);
         _quadSkill2.x = _loc32_.x;
         _quadSkill2.y = _loc22_.y + 5;
         _quadSkill2.alpha = 0.01;
         _quadSkill2.name = _avatar && _avatar.skill1 ? _avatar.skill1.skillSetData.id : "";
         _uiMain.addChild(_quadSkill2);
         _quadSkill2.addEventListener("touch",quadSkill_Touch);
         var _loc11_:Image = GlobalFunction.createImage("UI_tag_leader_0_0000");
         _loc11_.scaleX = _loc11_.scaleY = 0.9;
         _loc11_.x = _loc32_.x + _loc32_.width;
         _loc11_.y = _loc32_.y - 1;
         _loc11_.touchable = false;
         _uiMain.addChild(_loc11_);
         var _loc21_:LOL_TextField = new LOL_TextField("-",skillNameWidth,skillNameHeight);
         _loc21_.fontSize = 18;
         _loc21_.vAlign = "center";
         _loc21_.x = _loc34_.x + _loc34_.width;
         _loc21_.y = _loc34_.y + 2;
         _uiMain.addChild(_loc21_);
         var _loc4_:LOL_TextField = new LOL_TextField("-",skillLevelWidth,30);
         _loc4_.fontSize = 20;
         _uiMain.addChild(_loc4_);
         var _loc20_:LOL_TextField = new LOL_TextField("-",skillLeaderNameWidth,skillNameHeight);
         _loc20_.vAlign = "center";
         _loc20_.fontSize = 18;
         _loc20_.x = _loc32_.x + _loc32_.width + 30;
         _loc20_.y = _loc32_.y + 2;
         _uiMain.addChild(_loc20_);
         var _loc9_:LOL_TextField = new LOL_TextField("-",skillColumnWidth,52);
         _loc9_.style(GlobalConfig.FONT_0,17,4926491,"left","top");
         _loc9_.x = _loc34_.x;
         _loc9_.y = _loc34_.y + _loc34_.height + 2;
         _uiMain.addChild(_loc9_);
         var _loc8_:LOL_TextField = new LOL_TextField("-",skillColumnWidth,52);
         _loc8_.style(GlobalConfig.FONT_0,17,4926491,"left","top");
         _loc8_.x = _loc32_.x;
         _loc8_.y = _loc32_.y + _loc32_.height + 2;
         _uiMain.addChild(_loc8_);
         var _loc51_:LOL_TextField = new LOL_TextField("-",skillTimingWidth,30);
         _loc51_.style(GlobalConfig.FONT_0,17,1118481,"left","center");
         _loc51_.x = _loc34_.x;
         _loc51_.y = _loc9_.y + _loc9_.height + 2;
         _uiMain.addChild(_loc51_);
         var _loc6_:LOL_TextField = new LOL_TextField("-",skillTimingWidth,30);
         _loc6_.style(GlobalConfig.FONT_0,17,1118481,"left","center");
         _loc6_.x = _loc32_.x;
         _loc6_.y = _loc8_.y + _loc8_.height + 2;
         _uiMain.addChild(_loc6_);
         if(_avatar && GlobalData.$userData.avatars[_avatar.id] != null)
         {
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
            _lockImg.x = _iconBg.x + _iconBg.width - _lockImg.width;
            _lockImg.y = _iconBg.y - _lockImg.height;
            _lockImg.addEventListener("triggered",onTRIGGERED_lock);
            _uiMain.addChild(_lockImg);
         }
         var _loc46_:int = _avatar.getCultivationDisplayScale();
         mFoster = new LOL_TextField(GlobalLanguageStr.getLanguageStr(90652,_avatar.getPithNum() * _loc46_),180,30);
         mFoster.fontColor = 16764006;
         mFoster.fontSize = 20;
         mFoster.hAlign = "right";
         mFoster.shadowFilter();
         mFoster.x = _lockImg.x - mFoster.width - 10;
         mFoster.y = _lockImg.y + 30;
         mFoster.touchable = true;
         mFoster.addEventListener("touch",quadPith_Touch);
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
         var _loc3_:String = _avatar.skill0 ? _avatar.skill0.skillSetData.name : GlobalLanguageStr.getLanguageStr(90021);
         var _loc26_:String = _avatar.skill0 ? GlobalLanguageStr.getLanguageStr(20492,_avatar.skill0.lv) : "";
         var _loc5_:String = _avatar.skill1 ? _avatar.skill1.skillSetData.name : GlobalLanguageStr.getLanguageStr(90021);
         var _loc42_:String = "";
         var _loc38_:String = "";
         var _loc36_:String = _avatar.skill0 ? GlobalLanguageStr.getLanguageStr(25021,_avatar.skill0.skillSetData.warmup,_avatar.skill0.skillSetData.cooldown) : "";
         var _loc37_:String = _avatar.skill1 ? GlobalLanguageStr.getLanguageStr(25021,_avatar.skill1.skillSetData.warmup,_avatar.skill1.skillSetData.cooldown) : "";
         if(_avatar.skill0 == null && _avatar.skill1 == null && _avatar.avatarData.info != null)
         {
            _loc11_.visible = false;
            _loc34_.visible = false;
            _loc32_.visible = false;
            _loc4_.visible = false;
            _loc21_.visible = false;
            _loc20_.visible = false;
            _loc9_.visible = false;
            _loc8_.visible = false;
            _loc51_.visible = false;
            _loc6_.visible = false;
            _loc33_ = GlobalData.$config_battle_main;
            _loc7_ = GlobalData.$mConfig_battle_ploy;
            _loc40_ = GlobalData.$config_combat_main;
            _loc48_ = GlobalData.$mConfig_combat_ploy;
            _loc19_ = "";
            _loc44_ = _avatar.avatarData.origin;
            if(_loc44_ != null)
            {
               GlobalData.$maze_BattleId = _loc44_.substring(0,_loc44_.lastIndexOf("_"));
               GlobalData.$maze_CombatId = _loc44_;
               if(GlobalData.$maze_BattleId.indexOf("M") > -1)
               {
                  _loc19_ += _loc33_[GlobalData.$maze_BattleId].name;
                  _loc19_ = _loc19_ + (" - " + _loc40_[_loc44_].name);
               }
               else
               {
                  _loc19_ += _loc7_[GlobalData.$maze_BattleId].name;
                  _loc19_ = _loc19_ + (" - " + _loc48_[_loc44_].name);
               }
               _loc19_ = GlobalLanguageStr.replaceStrArr(_avatar.avatarData.info,["  <U>" + _loc19_ + "<U/>"]);
            }
            else
            {
               _loc19_ = _avatar.avatarData.info;
               GlobalData.$maze_BattleId = "";
               GlobalData.$maze_CombatId = "";
            }
            _loc45_ = new LOL_HtmlText(_loc22_.width,80,20,10027008,false,"center");
            _loc45_.name = "_infoTxt";
            _loc45_.format(_loc19_,[10027008,10027008,16764006]);
            _loc45_.x = _loc22_.x;
            _loc45_.y = _loc22_.y + _loc22_.height + 35;
            _loc45_.touchable = true;
            _loc45_.addEventListener("touch",maze_Touch);
            _uiMain.addChild(_loc45_);
         }
         else
         {
            _loc21_.text = _loc3_;
            _loc4_.text = _loc26_;
            _loc9_.text = _loc42_;
            _loc8_.text = _loc38_;
            _loc20_.text = _loc5_;
            _loc51_.text = formatSkillTiming(_loc36_);
            _loc6_.text = formatSkillTiming(_loc37_);
         }
         _loc4_.x = _loc21_.x + _loc21_.textBounds.width + 5;
         _loc4_.y = _loc21_.y + 3;
         var skillDetailTopY:int = _loc22_.y + _loc22_.height + 6;
         _loc21_.x = _loc22_.x;
         _loc21_.y = skillDetailTopY;
         _loc20_.x = _loc32_.x;
         _loc20_.y = skillDetailTopY;
         _loc4_.x = _loc21_.x + _loc21_.textBounds.width + 5;
         _loc4_.y = skillDetailTopY + 1;
         _loc51_.x = _loc21_.x;
         _loc51_.y = skillDetailTopY + 26;
         _loc6_.x = _loc20_.x;
         _loc6_.y = skillDetailTopY + 26;
         _loc11_.x = _loc32_.x + skillColumnWidth - 18;
         _loc11_.y = skillDetailTopY - 1;
         _loc9_.visible = false;
         _loc8_.visible = false;
         _loc34_.x = _loc22_.x;
         _loc34_.y = skillDetailTopY + 55;
         _loc32_.x = _loc22_.x + skillColumnWidth + 10;
         _loc32_.y = skillDetailTopY + 55;
         if(_loc41_[0] > 0)
         {
            _loc12_ = new LOL_Button(_loc41_[0] + "","UI_love_bg_0000");
            _loc12_.pivotX = _loc12_.width / 2;
            _loc12_.pivotY = _loc12_.height / 2;
            _loc12_.fontSize = 14;
            _loc12_.fontColor = 16777215;
            _loc12_.x = MainConfig.$isEA ? _loc21_.x + 75 : _loc21_.x + 35;
            _loc12_.y = MainConfig.$isEA ? _loc21_.y - 68 : _loc21_.y - 63;
            _loc12_.textPoint = new Point(-3,-5);
            _uiMain.addChild(_loc12_);
            _loc12_.addEventListener("triggered",onTRIGGERED_love);
         }
         if(_avatar && _avatar.skillB)
         {
            // Three equal columns reproduce the retained reference layout when a passive exists.
            // Keep the existing two-column measurements untouched for heroes without skillB.
            var skillThreeX0:int = _loc22_.x;
            var skillThreeX1:int = skillThreeX0 + skillThreeWidth + skillThreeGap;
            var skillThreeX2:int = skillThreeX1 + skillThreeWidth + skillThreeGap;
            var skillThreeNameY:int = skillDetailTopY;
            var skillThreeTimingY:int = skillDetailTopY + 26;
            var skillThreeButtonY:int = skillDetailTopY + 55;
            var skillThreeHitHeight:int = 112;

            _loc34_.text = GlobalLanguageStr.getLanguageStr(20212);
            _loc34_.style(GlobalConfig.FONT_0,14,_avatar.skill0 ? 16777215 : 6710886);
            _loc34_.x = skillThreeX0;
            _loc34_.y = skillThreeButtonY;
            _loc32_.x = skillThreeX1;
            _loc32_.y = skillThreeButtonY;
            _loc32_.style(GlobalConfig.FONT_0,14,_avatar.skill1 ? (_loc39_ ? 52479 : 16777215) : 6710886);
            _loc11_.x = skillThreeX1 + skillThreeWidth - 14;
            _loc11_.y = skillThreeNameY - 1;

            _quadSkill1.x = skillThreeX0;
            _quadSkill1.y = _loc22_.y;
            _quadSkill1.width = skillThreeWidth;
            _quadSkill1.height = skillThreeHitHeight;
            _quadSkill2.x = skillThreeX1;
            _quadSkill2.y = _loc22_.y;
            _quadSkill2.width = skillThreeWidth;
            _quadSkill2.height = skillThreeHitHeight;

            _loc21_.text = _avatar.skill0 ? _avatar.skill0.skillSetData.name : GlobalLanguageStr.getLanguageStr(90021);
            _loc21_.x = skillThreeX0;
            _loc21_.y = skillThreeNameY;
            _loc21_.fontSize = 16;
            _loc4_.x = skillThreeX0 + skillThreeWidth - 46;
            _loc4_.y = skillThreeNameY + 1;
            _loc4_.fontSize = 15;
            _loc4_.hAlign = "right";

            _loc20_.text = _loc5_;
            _loc20_.x = skillThreeX1;
            _loc20_.y = skillThreeNameY;
            _loc20_.fontSize = 16;
            _loc9_.visible = false;
            _loc8_.visible = false;
            _loc21_.visible = _loc20_.visible = true;
            _loc51_.text = formatSkillTiming(_loc36_);
            _loc51_.x = skillThreeX0;
            _loc51_.y = skillThreeTimingY;
            _loc51_.fontSize = 14;
            _loc6_.text = formatSkillTiming(_loc37_);
            _loc6_.x = skillThreeX1;
            _loc6_.y = skillThreeTimingY;
            _loc6_.fontSize = 14;

            // Create the passive hit target first so its visible controls remain on top.
            _quadSkillPassive = new Quad(skillThreeWidth,skillThreeHitHeight);
            _quadSkillPassive.x = skillThreeX2;
            _quadSkillPassive.y = _loc22_.y;
            _quadSkillPassive.alpha = 0.01;
            _quadSkillPassive.name = _avatar.skillB.skillSetData.id;
            _uiMain.addChild(_quadSkillPassive);
            _quadSkillPassive.addEventListener("touch",quadSkill_Touch);
            skillPassiveBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20212),110,32,"UI_btn_3_0000",false);
            skillPassiveBtn.x = skillThreeX2;
            skillPassiveBtn.y = skillThreeButtonY;
            skillPassiveBtn.style(GlobalConfig.FONT_0,14,16777215);
            skillPassiveBtn.name = _avatar.skillB.skillSetData.id;
            _uiMain.addChild(skillPassiveBtn);
            skillPassiveBtn.addEventListener("triggered",onTRIGGERED_btn);
            skillPassiveTxt = new LOL_TextField(_avatar.skillB.skillSetData.name,skillThreeWidth,24);
            skillPassiveTxt.fontSize = 16;
            skillPassiveTxt.vAlign = "center";
            skillPassiveTxt.x = skillThreeX2;
            skillPassiveTxt.y = skillThreeNameY;
            skillPassiveTxt.touchable = false;
            _uiMain.addChild(skillPassiveTxt);
            _loc15_ = formatSkillTiming(GlobalLanguageStr.getLanguageStr(25021,_avatar.skillB.skillSetData.warmup,_avatar.skillB.skillSetData.cooldown));
            txtSkillDescPassive = new LOL_TextField(_loc15_,skillThreeWidth,30);
            txtSkillDescPassive.style(GlobalConfig.FONT_0,14,1118481,"left");
            txtSkillDescPassive.x = skillThreeX2;
            txtSkillDescPassive.y = skillThreeTimingY;
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
         }
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
            _loc5_ = new SkillSet(_loc3_,_avatar,_avatar.skill0 && _loc3_ == _avatar.skill0.skillSetData.id ? _avatar.slv : 1,_avatar.skill1 && _loc3_ == _avatar.skill1.skillSetData.id);
            _loc4_ = _loc5_.skillSetData.name;
            _loc2_ = getSkillDetailsOrFallback(_loc5_) + "\n";
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
               _loc6_ = new SkillSet(_loc4_,null);
               _loc5_ = _loc6_.skillSetData.name;
               _loc2_ = getSkillDetailsOrFallback(_loc6_) + "\n";
               _loc2_ = Tools.formatLineX(_loc2_,GlobalTextStyle.COLOR_W_W_Y_G);
               GlobalFunction.popAlert(_loc5_,_loc2_,{"res":_avatar.resId},false);
            }
         }
      }

      private function quadPith_Touch(param1:TouchEvent) : void
      {
         var _loc2_:String = null;
         var _loc3_:String = null;
         var _loc8_:int = _avatar.getCultivationDisplayScale();
         var _loc4_:Touch = param1.getTouch(this,"ended");
         var _loc7_:String = _avatar.id.split("|")[0];
         var _loc5_:Object = GlobalData.$userData.avatars[_avatar.id];
         var _loc6_:int = 0;
         if(_loc5_.pith_max)
         {
            _loc6_ = GlobalData.$mConfig_simple.culture.max_pith_base + _loc5_.pith_max;
         }
         else
         {
            _loc6_ = int(GlobalData.$mConfig_simple.culture.max_pith_base);
         }
         if(_loc6_ >= GlobalData.$mConfig_simple.culture.max_pith)
         {
            _loc6_ = int(GlobalData.$mConfig_simple.culture.max_pith);
         }
         _loc6_ = _avatar.getCultivationCap();
         if(_loc4_)
         {
            if(_avatar)
            {
               _loc2_ = GlobalLanguageStr.getLanguageStr(20226);
               _loc3_ = GlobalLanguageStr.getLanguageStr(90521,_avatar.getHpMax(-1,-1,true),_avatar.getCultivationStatGain("hp",_avatar.hpP),_avatar.getDamage(-1,-1,true),_avatar.getCultivationStatGain("ap",_avatar.apP),_avatar.getDePh(-1,-1,true),_avatar.getCultivationStatGain("de_ph",_avatar.dePhP),_avatar.getDeMa(-1,-1,true),_avatar.getCultivationStatGain("de_ma",_avatar.deMaP),_avatar.getPithNum() * _loc8_,_loc6_ * _loc8_);
               _loc2_ += "\n" + _loc3_;
               _loc2_ = Tools.formatLineX(_loc2_,GlobalTextStyle.COLOR_W_Y_Y_G);
               GlobalFunction.popAlert("",_loc2_,{"aid":_loc7_},false);
               param1.stopPropagation();
            }
         }
      }

      private function onTRIGGERED_lock(param1:Event) : void
      {
         _lock = !_lock;
         _lockImg.removeEventListener("triggered",onTRIGGERED_lock);
         _lockImg.removeFromParent(true);
         _lockImg = null;
         if(_lock)
         {
            _lockImg = GlobalFunction.createButton_5("","UI_icon_lock_1_0000");
         }
         else
         {
            _lockImg = GlobalFunction.createButton_5("","UI_icon_lock_0_0000");
         }
         _lockImg.scaleX = _lockImg.scaleY = 0.8;
         _lockImg.x = _iconBg.x + _iconBg.width - _lockImg.width;
         _lockImg.y = _iconBg.y - _lockImg.height;
         _lockImg.addEventListener("triggered",onTRIGGERED_lock);
         _uiMain.addChild(_lockImg);
         mFoster.x = _lockImg.x - mFoster.width - 10;
         mFoster.y = _lockImg.y + 30;
         GlobalFunction.changeLock(_avatar.id,_lock);
         if(GlobalData.$tempLockItem)
         {
            GlobalData.$tempLockItem["fun"]();
            GlobalData.$tempLockItem["fun"] = null;
            delete GlobalData.$tempLockItem["fun"];
         }
         GlobalData.$tempLockItem = null;
         GlobalData.$mEventDispatcher.dispatchEventWith("change_team_member_lock",false,this._avatar);
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
      }

      protected function rise_Triggered(param1:Event) : void
      {
         var _loc2_:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         if(_loc2_ == null)
         {
            return;
         }
         if(_avatar == null)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90675));
            return;
         }
         if(!_loc2_.enabled)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90644));
            return;
         }
         if(GlobalFunction.checkSearchTypeByType(_avatar.id,2))
         {
            GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(90644));
            return;
         }
         _isGuide = false;
         super.onCLOSE_PANEL_SELF();
         GlobalData.$tempAvatarBetter = GlobalData.$tempTeamSelect;
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_better_start",false,true);
      }

      protected function up_Triggered(param1:Event) : void
      {
         if(_avatar && _avatar.getPhaseType() == 0)
         {
            GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(10071));
            return;
         }
         if(GlobalFunction.checkSearchTypeByType(_avatar.id,2))
         {
            GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(10071));
            return;
         }
         _isGuide = false;
         super.onCLOSE_PANEL_SELF();
         GlobalData.$tempAvatarStarUp = GlobalData.$tempTeamSelect;
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_starup_start",false,true);
      }

      protected function foster_Triggered(param1:Event) : void
      {
         var _loc3_:Object = GlobalData.$mConfig_simple.culture;
         var _loc2_:Number = _avatar.getStar();
         if(GlobalFunction.checkSearchTypeByType(_avatar.id,2) || GlobalFunction.checkSearchTypeByType(_avatar.id,3) || GlobalFunction.checkSearchTypeByType(_avatar.id,4))
         {
            GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(90645));
            return;
         }
         if(GlobalData.$userData.lv < _loc3_.culture_lv)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90129,_loc3_.culture_lv),false);
            return;
         }
         if(_loc2_ < _loc3_.avatar_culture[0])
         {
            GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(90645));
            return;
         }
         _isGuide = false;
         this.onCLOSE_PANEL_SELF(null);
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_avatar_foster",false,true,GlobalData.$tempTeamSelect);
      }

      protected function reset_Triggered(param1:Event) : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_team_avatar",false,true);
      }

      protected function CHANGE_TEAM_MEMBER(param1:Event) : void
      {
         super.onCLOSE_PANEL_SELF();
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
               _loc2_ += GlobalLanguageStr.getLanguageStr(getActionTypeLanguageId(_loc8_.actionType));
               _loc2_ += "\n" + GlobalLanguageStr.getLanguageStr(98304);
               _loc5_ = uint(_avatar.getStar());
               _loc6_ = uint(_avatar.avatarData.getMaxStar());
               _loc7_ = _avatar.avatarData.name;
               if(_loc6_ > _loc5_)
               {
                  _loc7_ += " " + GlobalLanguageStr.getLanguageStr(20227,_loc6_);
               }
               _loc2_ = Tools.formatLineX(_loc2_,GlobalTextStyle.COLOR_W_Y_Y_G);
               GlobalFunction.popAlert(_loc7_,_loc2_,{"res":_avatar.resId},false);
               SoundManager.getOnlyExample().playAvatar(getAvatarVoiceId(),0.5);
               param1.stopPropagation();
            }
         }
      }

      protected function onTRIGGERED_love(param1:Event) : void
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
            _loc2_ = GlobalData.$mConfig_simple.show_id[16];
            GlobalFunction.popAlert("",_loc4_,{"aid":_loc2_});
         }
      }

      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         var _loc3_:LOL_HtmlText = null;
         var _loc4_:LOL_Scale9Button = null;
         var _loc2_:Quad = null;
         GlobalData.$mEventDispatcher.dispatchEventWith("panel_detailall_close",false,{"isGuide":_isGuide});
         GlobalData.$mEventDispatcher.removeEventListener("change_team_member",CHANGE_TEAM_MEMBER);
         GlobalData.$mEventDispatcher.removeEventListener("update_avatar_foster",UPDATE_AVATAR_FOSTER);
         if(mBox_P)
         {
            StarlingTools.removeChildrenClear(mBox_P);
            mBox_P.removeFromParent(true);
         }
         if(_reset)
         {
            _reset.removeFromParent(true);
         }
         if(_rise)
         {
            _rise.removeFromParent(true);
         }
         if(_up)
         {
            _up.removeFromParent(true);
         }
         if(_uiMain)
         {
            _loc3_ = _uiMain.getChildByName("_infoTxt") as LOL_HtmlText;
            if(_loc3_)
            {
               _loc3_.removeEventListener("touch",maze_Touch);
               _loc3_.removeFromParent();
               _loc3_ = null;
            }
            if(_quadSkill1) _quadSkill1.removeEventListener("touch",quadSkill_Touch);
            if(_quadSkill2) _quadSkill2.removeEventListener("touch",quadSkill_Touch);
            if(_quadSkillPassive) _quadSkillPassive.removeEventListener("touch",quadSkill_Touch);
            if(skillPassiveBtn) skillPassiveBtn.removeEventListener("triggered",onTRIGGERED_btn);
            if(_quadFoster1) _quadFoster1.removeEventListener("touch",quadPith_Touch);
            if(_quadType) _quadType.removeEventListener("touch",onType);
            StarlingTools.removeChildrenClear(_uiMain);
            _uiMain.removeFromParent();
            _uiMain.dispose();
            _quadSkill1 = null;
            _quadSkill2 = null;
            _quadSkillPassive = null;
            _quadFoster1 = null;
            _quadType = null;
            _quadPith = null;
            _lockImg = null;
            mFoster = null;
            skillPassiveBtn = null;
            skillPassiveTxt = null;
            txtSkillDescPassive = null;
         }

         if(_euqipMain)
         {
            StarlingTools.removeChildrenClear(_euqipMain);
         }
         txtSkillDescPassive = null;
         skillPassiveTxt = null;
         skillPassiveBtn = null;
         _quadSkill1 = null;
         _quadSkill2 = null;
         _quadSkillPassive = null;
         if(talentSp)
         {
            talentSp.removeFromParent(true);
            talentSp.dispose();
         }
         if(talentQuad)
         {
            talentQuad.removeFromParent(true);
            talentQuad.dispose();
         }
         StarlingTools.removeChildrenClear(this);
         mBox_P = null;
         _uiMain = null;
         _euqipMain = null;
         _reset = null;
         _up = null;
         _rise = null;
         txtSkillDescPassive = null;
         talentSp = null;
         talentQuad = null;
      }
   }
}
