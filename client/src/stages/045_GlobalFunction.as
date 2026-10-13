package com.meng52.game.global
{
   import com.meng52.game.command.avatar.AvatarManager;
   import com.meng52.game.command.effect.EffectManager;
   import com.meng52.game.command.equip.EquipManager;
   import com.meng52.game.command.map.GameMapManager;
   import com.meng52.game.command.skill.SkillSetManager;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.equip.Equip;
   import com.meng52.game.module.equip.Fragment;
   import com.meng52.game.module.guide.GuideData;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.module.map.GameMap;
   import com.meng52.game.module.map.GameMapTools;
   import com.meng52.game.module.skill.SkillSet;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_TextField;
   import com.meng52.game.ui.element.LOL_TimeStatus;
   import com.meng52.game.ui.map.GameMapLayer;
   import com.meng52.game.ui.panel.PanelAwardTips;
   import com.meng52.game.ui.panel.PanelBetterSelect;
   import com.meng52.game.ui.panel.PanelFunctionOpenInfo;
   import com.meng52.game.ui.panel.PanelHelpNotice;
   import com.meng52.game.ui.panel.PanelInforPop;
   import com.meng52.game.ui.panel.PanelMail;
   import com.meng52.game.ui.panel.PanelPop;
   import com.meng52.game.ui.panel.PanelRollInfo;
   import com.meng52.game.ui.panel.PanelTeamAvatar;
   import com.meng52.game.ui.screen.PanelAvatarBetter;
   import com.meng52.game.ui.screen.PanelAvatarSell;
   import com.meng52.game.ui.screen.PanelAvatarStarUp;
   import com.meng52.game.ui.screen.PanelCenterActivity;
   import com.meng52.game.ui.screen.PanelCenterDNTeam;
   import com.meng52.game.ui.screen.PanelCenterMain;
   import com.meng52.game.ui.screen.PanelCenterPVP;
   import com.meng52.game.ui.screen.PanelCenterShopVIP;
   import com.meng52.game.ui.screen.PanelSocialMainAvatar;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.game.ui.stage.LayoutUIBottom;
   import com.meng52.game.ui.stage.LayoutUILoading;
   import com.meng52.global.GlobalStaticConst;
   import com.meng52.global.SocketManager;
   import com.meng52.net.RpcStaticCall;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StageWebViewBase;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale3Image;
   import feathers.display.Scale9Image;
   import feathers.textures.Scale3Textures;
   import feathers.textures.Scale9Textures;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.net.URLRequest;
   import flash.net.navigateToURL;
   import flash.utils.ByteArray;
   import flash.utils.Timer;
   import flash.utils.getDefinitionByName;
   import starling.animation.Juggler;
   import starling.animation.Tween;
   import starling.display.DisplayObject;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.filters.BlurFilter;
   import starling.filters.FragmentFilter;
   import starling.text.TextField;
   import starling.textures.Texture;
   
   public class GlobalFunction
   {
      
      public static var arrFilter:Array;
      
      public static var ROLL_LIST:Array;
      
      public static var $teamDataObj:Object;
      
      private static var $nextTextField:TextField;
      
      private static var $rndMC1:*;
      
      private static var $rndMC2:*;
      
      public static var $rndMCShow:Boolean;
      
      public static const RADIO_MIN:int = 46000;
      
      public static const RADIO_MAX:int = 46099;
      
      public static var GLOW_MAX_ALPHA:Number = 0.5;
      
      public static var GLOW_MIN_ALPHA:Number = 0;
      
      public static var MAIN:String = "M";
      
      public static var PLOY:String = "P";
      
      public static var TEXTURE_DEFAULT:String = "guideClick0000";
      
      public static const TEXTURE_MAX:int = 10;
      
      public static var $getTextureList:Array = [];
      
      public function GlobalFunction()
      {
         super();
      }
      
      public static function get classStoreIOS() : Class
      {
         return MainConfig.classStoreIOS;
      }
      
      public static function checkIsFirstPVP() : Boolean
      {
         var _loc1_:Boolean = false;
         if(GlobalData.$userData.attrs)
         {
            if(GlobalData.$userData.attrs.pvp_count == 0)
            {
               _loc1_ = true;
            }
         }
         return _loc1_;
      }
      
      public static function getRandomNumber(param1:uint, param2:uint) : Array
      {
         var _loc6_:int = 0;
         var _loc4_:* = 0;
         var _loc3_:Array = [];
         _loc6_ = param1 - 1;
         while(_loc6_ >= 0)
         {
            _loc3_.unshift(_loc6_);
            _loc6_--;
         }
         var _loc5_:Array = [];
         _loc6_ = 0;
         while(_loc6_ < param2)
         {
            _loc4_ = uint(Math.random() * (param1 - 1));
            _loc5_.push(_loc3_[_loc4_]);
            param1 -= 1;
            _loc3_.splice(_loc4_,1);
            _loc6_++;
         }
         return _loc5_;
      }
      
      public static function getBuleNumber(param1:uint) : starling.display.Sprite
      {
         var _loc6_:* = 0;
         var _loc5_:Image = null;
         var _loc3_:String = param1.toString();
         var _loc4_:Array = _loc3_.split("");
         var _loc2_:starling.display.Sprite = new starling.display.Sprite();
         _loc6_ = 0;
         while(_loc6_ < _loc4_.length)
         {
            _loc5_ = createImage("UI_ranking_number_000" + _loc4_[_loc6_]);
            _loc5_.x = _loc6_ * _loc5_.width;
            _loc2_.addChild(_loc5_);
            _loc6_++;
         }
         return _loc2_;
      }
      
      public static function getNumber(param1:int) : String
      {
         var _loc3_:String = null;
         var _loc4_:Array = param1.toString().split("");
         var _loc2_:int = int(_loc4_.length);
         switch(_loc2_ - 1)
         {
            case 0:
               _loc3_ = getNumberChange(_loc4_[0]);
               break;
            case 1:
               if(_loc4_[1] == 0)
               {
                  _loc3_ = getNumberChange(_loc4_[0]) + "十";
                  _loc3_ = "十";
                  _loc4_[0] == 1 ? _loc3_ : _loc3_;
               }
               else
               {
                  _loc3_ = getNumberChange(_loc4_[0]) + "十" + getNumberChange(_loc4_[1]);
               }
               break;
            case 2:
               if(_loc4_[1] == 0 && _loc4_[2] == 0)
               {
                  return getNumberChange(_loc4_[0]) + "百";
               }
               if(_loc4_[1] == 0)
               {
                  _loc3_ = getNumberChange(_loc4_[0]) + "百零" + getNumberChange(_loc4_[2]);
               }
               else if(_loc4_[2] == 0)
               {
                  _loc3_ = getNumberChange(_loc4_[0]) + "百" + getNumberChange(_loc4_[1]) + "十";
               }
               else
               {
                  _loc3_ = getNumberChange(_loc4_[0]) + "百" + getNumberChange(_loc4_[1]) + "十" + getNumberChange(_loc4_[2]);
               }
               break;
            case 3:
               if(_loc4_[1] == 0 && _loc4_[2] == 0 && _loc4_[3] == 0)
               {
                  _loc3_ = getNumberChange(_loc4_[0]) + "千";
                  break;
               }
               if(_loc4_[2] == 0 && _loc4_[3] == 0)
               {
                  _loc3_ = getNumberChange(_loc4_[0]) + "千" + getNumberChange(_loc4_[1]) + "百";
                  break;
               }
               if(_loc4_[1] == 0 && _loc4_[3] == 0)
               {
                  _loc3_ = getNumberChange(_loc4_[0]) + "千零" + getNumberChange(_loc4_[2]) + "十";
                  break;
               }
               if(_loc4_[1] == 0 && _loc4_[2] == 0)
               {
                  _loc3_ = getNumberChange(_loc4_[0]) + "千零" + getNumberChange(_loc4_[3]);
                  break;
               }
               if(_loc4_[3] == 0)
               {
                  _loc3_ = getNumberChange(_loc4_[0]) + "千" + getNumberChange(_loc4_[1]) + "百" + getNumberChange(_loc4_[2]) + "十";
                  break;
               }
               if(_loc4_[2] == 0)
               {
                  _loc3_ = getNumberChange(_loc4_[0]) + "千" + getNumberChange(_loc4_[1]) + "百零" + getNumberChange(_loc4_[3]);
                  break;
               }
               if(_loc4_[1] == 0)
               {
                  _loc3_ = getNumberChange(_loc4_[0]) + "千零" + getNumberChange(_loc4_[2]) + "十" + getNumberChange(_loc4_[3]);
                  break;
               }
               _loc3_ = getNumberChange(_loc4_[0]) + "千" + getNumberChange(_loc4_[1]) + "百" + getNumberChange(_loc4_[2]) + "十" + getNumberChange(_loc4_[3]);
         }
         return _loc3_;
      }
      
      public static function getNumberChange(param1:int) : String
      {
         var _loc2_:String = null;
         switch(param1 - 1)
         {
            case 0:
               _loc2_ = "一";
               break;
            case 1:
               _loc2_ = "二";
               break;
            case 2:
               _loc2_ = "三";
               break;
            case 3:
               _loc2_ = "四";
               break;
            case 4:
               _loc2_ = "五";
               break;
            case 5:
               _loc2_ = "六";
               break;
            case 6:
               _loc2_ = "七";
               break;
            case 7:
               _loc2_ = "八";
               break;
            case 8:
               _loc2_ = "九";
         }
         return _loc2_;
      }
      
      public static function cloneArray(param1:Array) : Array
      {
         var _loc3_:ByteArray = new ByteArray();
         _loc3_.writeObject(param1);
         _loc3_.position = 0;
         return _loc3_.readObject() as Array;
      }
      
      public static function filterStringInit() : void
      {
         arrFilter = GlobalData.sensitiveWords.split("/");
      }
      
      public static function filterString(param1:String, param2:String = "*") : String
      {
         var _loc6_:* = null;
         var _loc4_:String = null;
         var _loc3_:RegExp = null;
         var _loc5_:int = 0;
         for each(_loc6_ in arrFilter)
         {
            _loc4_ = "";
            _loc3_ = new RegExp(_loc6_,"g");
            _loc5_ = 0;
            while(_loc5_ < _loc6_.length)
            {
               _loc4_ += "*";
               _loc5_++;
            }
            param1 = param1.replace(_loc3_,_loc4_);
         }
         return param1;
      }
      
      public static function getShadowFilters() : FragmentFilter
      {
         return BlurFilter.createDropShadow(2,0.785,0,1,0,1);
      }
      
      public static function formatePVProbotCfg(param1:Object) : void
      {
         var _loc4_:Object = null;
         var _loc8_:Object = null;
         var _loc6_:Object = null;
         if(GlobalData.$config_pvp_robot == null)
         {
            GlobalData.$config_pvp_robot = [];
            for(_loc4_ in param1)
            {
               _loc8_ = param1[_loc4_];
               _loc8_["index"] = int(_loc4_);
               GlobalData.$config_pvp_robot.push(_loc8_);
            }
            GlobalData.$config_pvp_robot.sortOn("index",16);
         }
         var _loc7_:int = 0;
         var _loc5_:int = 0;
         var _loc2_:Object = null;
         var _loc3_:int = 0;
         if(GlobalData.$config_pvp_robot && GlobalData.$config_pvp_title == null)
         {
            _loc7_ = 0;
            _loc5_ = int(GlobalData.$config_pvp_robot.length);
            GlobalData.$config_pvp_title = [];
            _loc7_ = 0;
            while(_loc7_ < _loc5_)
            {
               _loc6_ = {
                  "min":0,
                  "max":0,
                  "title":_loc7_ + 1
               };
               _loc2_ = GlobalData.$config_pvp_robot[_loc7_];
               _loc6_.min = _loc3_ + 1;
               _loc6_.max = _loc2_.num + _loc3_;
               _loc3_ += _loc2_.num;
               GlobalData.$config_pvp_title.push(_loc6_);
               _loc7_++;
            }
         }
      }
      
      public static function check_pvp_list_title(param1:int) : int
      {
         var _loc4_:Object = null;
         var _loc5_:int = 0;
         var _loc3_:int = 0;
         var _loc2_:int = int(GlobalData.$config_pvp_title.length);
         if(GlobalData.$config_pvp_title)
         {
            _loc3_ = int(GlobalData.$config_pvp_title.length);
            _loc5_ = 0;
            while(_loc5_ < _loc3_)
            {
               _loc4_ = GlobalData.$config_pvp_title[_loc5_];
               if(param1 >= _loc4_.min && param1 <= _loc4_.max)
               {
                  _loc2_ = int(_loc4_.title);
                  break;
               }
               _loc5_++;
            }
         }
         return _loc2_;
      }
      
      public static function getPVPoutputMark(param1:int, param2:int = 1) : Number
      {
         var _diagnosticSimple:Object = GlobalData.$mConfig_simple;
         var _diagnosticPvpConfig:* = _diagnosticSimple != null ? _diagnosticSimple["pvp_config"] : null;
         var _diagnosticPvpMark:* = _diagnosticSimple != null ? _diagnosticSimple["pvp_get_mark"] : null;
         if(!(_diagnosticPvpConfig is Array) || (_diagnosticPvpConfig as Array).length < 10 || !(_diagnosticPvpMark is Array) || (_diagnosticPvpMark as Array).length == 0 || param1 < 1)
         {
            var _diagnosticCross:Object = _diagnosticSimple != null ? _diagnosticSimple["cross_pvp"] : null;
            var _diagnosticSchedule:Array = _diagnosticCross != null ? _diagnosticCross["cross_server_pvp"] as Array : null;
            if(RpcStaticCall.$remoting != null)
            {
               RpcStaticCall.$remoting.reportDiagnostic("PVP_MARK_CONFIG_INVALID cfg_version=" + SendAndSelect.$cfgVersion + " page=PanelCenterPVP:" + PanelCenterPVP.$tabBarSelectedIndex + " rank=" + param1 + " pvp_config=" + String(_diagnosticPvpConfig) + " pvp_get_mark=" + String(_diagnosticPvpMark) + " cross_open_status=" + (_diagnosticCross != null ? String(_diagnosticCross["open_status"]) : "missing") + " cross_schedule=" + (_diagnosticSchedule != null ? String(_diagnosticSchedule) : "missing") + " cross_start=" + (_diagnosticSchedule != null && _diagnosticSchedule.length > 2 ? String(_diagnosticSchedule[2]) : "missing"));
            }
         }
         var _loc3_:Array = GlobalData.$mConfig_simple.pvp_config as Array;
         var _loc9_:Array = GlobalData.$mConfig_simple.pvp_get_mark as Array;
         var _loc7_:Number = Number(_loc3_[6]);
         var _loc5_:Number = Number(_loc3_[7]);
         var _loc6_:Number = Number(_loc3_[8]);
         var _loc8_:Number = Number(_loc3_[9]);
         var _loc4_:Number = Number(param1 > 11 ? _loc9_[_loc9_.length - 1] : _loc9_[param1 - 1]);
         return Math.floor((Math.pow(_loc7_ / (param1 + _loc5_),_loc8_) + _loc6_) * param2 * _loc4_);
      }
      
      public static function getAvatarAndEquipAttInit() : Object
      {
         var _loc1_:Object = {};
         _loc1_["hp"] = 0;
         _loc1_["ap"] = 0;
         _loc1_["deph"] = 0;
         _loc1_["dema"] = 0;
         _loc1_["range"] = 0;
         _loc1_["speed"] = 0;
         _loc1_["hit"] = 0;
         _loc1_["crit"] = 0;
         _loc1_["tough"] = 0;
         _loc1_["flee"] = 0;
         return _loc1_;
      }
      
      public static function getOneGroupEquipAttValues(param1:int, param2:Boolean = false) : Object
      {
         var _loc7_:Array = null;
         var _loc8_:Equip = null;
         var _loc4_:Boolean = param2;
         var _loc6_:Object = null;
         if(param2 && GlobalData.$pvp_rival)
         {
            _loc4_ = Boolean(GlobalData.$pvp_rival["isRobot"]);
            _loc7_ = GlobalData.$pvp_rival["data_base"];
            _loc6_ = GlobalFunction.getPVPenemyEquip(_loc4_ ? [] : (_loc7_[param1][10] != null ? _loc7_[param1][10] : null),_loc4_);
         }
         var _loc9_:Array = param2 ? (_loc4_ ? [null,null,null,null,null,null] : (_loc6_ ? _loc6_.as_equips : [])) : GlobalData.$userData.as_equips[param1];
         var _loc11_:Object = param2 ? (_loc4_ ? {} : (_loc6_ ? _loc6_.my_equips : {})) : GlobalData.$userData.my_equips;
         var _loc5_:Object = getAvatarAndEquipAttInit();
         var _loc10_:int = int(_loc9_.length);
         var _loc12_:int = 0;
         var _loc3_:Object = null;
         _loc12_ = 0;
         while(_loc12_ < _loc10_)
         {
            _loc3_ = null;
            _loc3_ = _loc11_[_loc9_[_loc12_]];
            if(_loc9_[_loc12_] != null)
            {
               _loc8_ = new Equip(_loc9_[_loc12_],_loc3_);
               _loc5_["hp"] += _loc8_.getHpMax();
               _loc5_["ap"] += _loc8_.getDamage();
               _loc5_["deph"] += _loc8_.getDePh();
               _loc5_["dema"] += _loc8_.getDeMa();
               _loc5_["range"] += _loc8_.getRange();
               _loc5_["speed"] += _loc8_.getSpeed();
               _loc5_["hit"] += _loc8_.getHit(-1,true);
               _loc5_["crit"] += _loc8_.getCrit(-1,true);
               _loc5_["tough"] += _loc8_.getTough(-1,true);
               _loc5_["flee"] += _loc8_.getFlee(-1,true);
            }
            _loc12_++;
         }
         return _loc5_;
      }
      
      public static function setOtherCfgAvatarsObj(param1:Array) : Object
      {
         var _loc9_:Array = null;
         var _loc4_:Object = null;
         var _loc8_:Object = null;
         var _loc3_:Array = null;
         var _loc5_:Object = null;
         var _loc11_:int = 0;
         var _loc7_:int = 5;
         var _loc2_:Object = {};
         var _loc6_:Array = [null,null,null,null,null];
         _loc11_ = 0;
         while(_loc11_ < _loc7_)
         {
            if(param1[_loc11_] != null && param1[_loc11_] is Array)
            {
               _loc9_ = param1[_loc11_];
               _loc6_[_loc11_] = _loc9_[0];
               _loc2_[_loc9_[0]] = setOtherCfgAvatar(_loc9_);
            }
            else
            {
               _loc6_[_loc11_] = null;
            }
            _loc11_++;
         }
         var _loc10_:Object = {};
         if(param1[param1.length - 1] != null && !(param1[param1.length - 1] is Array))
         {
            _loc4_ = param1[param1.length - 1];
            for(_loc8_ in _loc4_)
            {
               if(_loc4_[_loc8_] is Array)
               {
                  _loc3_ = _loc4_[_loc8_];
                  _loc10_[_loc8_] = _loc3_;
                  if(_loc3_.length > 2 && _loc3_[1] != null)
                  {
                     var _temp_5:* = _loc2_;
                     var _temp_4:* = _loc3_[1];
                     _loc3_[2];
                     true;
                     _temp_5[_temp_4] = _loc3_[1];
                  }
               }
            }
         }
         return {
            "team":_loc6_,
            "avatars":_loc2_,
            "dn":_loc10_
         };
      }
      
      public static function setOtherCfgAvatar(param1:Array, param2:Boolean = false, param3:String = "") : Object
      {
         var _loc4_:Object = {};
         if(param2)
         {
            _loc4_["id"] = param3;
            _loc4_["aid"] = param3;
            _loc4_.lv = param1[0];
            _loc4_.slv = 0;
            _loc4_.hp = param1[1];
            _loc4_.ap = param1[2];
            _loc4_.de_ph = param1[3];
            _loc4_.de_ma = param1[4];
            _loc4_.phase = param1[5];
         }
         else
         {
            _loc4_["id"] = param1[0];
            _loc4_["aid"] = param1[0];
            _loc4_.lv = param1[1];
            _loc4_.slv = param1[2];
            if(param1.length > 6)
            {
               _loc4_.hp = param1[3];
               _loc4_.ap = param1[4];
               _loc4_.de_ph = param1[5];
               _loc4_.de_ma = param1[6];
               _loc4_.phase = param1[7];
               _loc4_.morph = param1[11];
            }
         }
         return _loc4_;
      }
      
      public static function getOneGroupAvatarAttValues(param1:String, param2:Object = null) : Object
      {
         var _loc3_:Avatar = null;
         var _loc4_:Object = getAvatarAndEquipAttInit();
         if(param1 != null && param1 != "")
         {
            _loc3_ = new Avatar(param1,param2);
            _loc4_["hp"] = _loc3_.getHpMax();
            _loc4_["ap"] = _loc3_.getDamage();
            _loc4_["deph"] = _loc3_.getDePh();
            _loc4_["dema"] = _loc3_.getDeMa();
            _loc4_["range"] = _loc3_.getRange();
            _loc4_["speed"] = _loc3_.getSpeed();
            _loc3_.clear();
            _loc3_ = null;
         }
         return _loc4_;
      }
      
      public static function checkEquipType(param1:int) : String
      {
         var _loc2_:String = "";
         if(param1 == 0 || param1 == 1)
         {
            _loc2_ = "E_1";
         }
         else if(param1 == 2)
         {
            _loc2_ = "E_3";
         }
         else if(param1 == 3)
         {
            _loc2_ = "E_4";
         }
         else if(param1 == 4)
         {
            _loc2_ = "E_5";
         }
         else if(param1 == 5)
         {
            _loc2_ = "E_6";
         }
         return _loc2_;
      }
      
      public static function checkEquipTypeToId(param1:String, param2:Array) : int
      {
         var _loc3_:int = 0;
         if(param2 != null && param2.length == 6)
         {
            if(param1.indexOf("E_1") > -1)
            {
               if(param2[0] == null)
               {
                  _loc3_ = 0;
               }
               else if(param2[0] != null && param2[1] == null)
               {
                  _loc3_ = 1;
               }
            }
            else if(param1.indexOf("E_3") > -1)
            {
               _loc3_ = 2;
            }
            else if(param1.indexOf("E_4") > -1)
            {
               _loc3_ = 3;
            }
            else if(param1.indexOf("E_5") > -1)
            {
               _loc3_ = 4;
            }
            else if(param1.indexOf("E_6") > -1)
            {
               _loc3_ = 5;
            }
         }
         return _loc3_;
      }
      
      public static function checkBossIn(param1:Boolean = true) : Boolean
      {
         var _loc2_:int = int(GlobalFunction.checkBossInCD());
         if(_loc2_ > 0 && _loc2_ < GlobalData.$mConfig_simple.zone_boss.delay_times[1])
         {
            if(param1)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(32007,_loc2_),false,"A_4015_6");
            }
            return false;
         }
         if(-(_loc2_ - checkBossInDelay()) > GlobalData.$mConfig_simple.zone_boss.max_alive_time * 60)
         {
            if(param1)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10087,_loc2_),false,"A_4015_6");
            }
            return false;
         }
         return true;
      }
      
      public static function checkBossInDelay() : int
      {
         var _loc2_:int = 0;
         var _loc1_:Date = new Date();
         return int((int(GlobalData.$userData.uid) + int(_loc1_.getDay())) % 7 * GlobalData.$mConfig_simple.zone_boss.delay_times[0]);
      }
      
      public static function checkBossIsOpen() : Boolean
      {
         var _loc10_:int = 0;
         var _loc9_:Array = null;
         var _loc6_:Number = Number(NaN);
         var _loc4_:Number = Number(NaN);
         var _loc3_:Number = Number(NaN);
         var _loc8_:Boolean = false;
         var _loc7_:Date = new Date();
         var _loc1_:Array = GlobalData.$mConfig_simple.zone_boss.open_times;
         var _loc5_:Number = Math.ceil(SendAndSelect.$systemTimer_nowSecond * 1000 + GlobalConfig.HOURS_8_MS);
         var _loc2_:Number = GlobalData.$mConfig_simple.zone_boss.max_alive_time * 60 * 1000;
         if(_loc1_)
         {
            _loc10_ = 0;
            while(_loc10_ < _loc1_.length)
            {
               _loc9_ = _loc1_[_loc10_];
               _loc7_.hours = _loc9_[0];
               _loc7_.minutes = _loc9_[1];
               _loc7_.seconds = 0;
               _loc4_ = _loc7_.time;
               _loc3_ = _loc7_.time + _loc2_;
               if(_loc5_ < _loc3_ && _loc5_ >= _loc4_)
               {
                  _loc8_ = true;
               }
               _loc10_++;
            }
         }
         return _loc8_;
      }
      
      public static function checkBossInGuideTime() : Boolean
      {
         var _loc10_:int = 0;
         var _loc9_:Array = null;
         var _loc6_:Number = Number(NaN);
         var _loc4_:Number = Number(NaN);
         var _loc3_:Number = Number(NaN);
         var _loc8_:Boolean = false;
         var _loc7_:Date = new Date();
         var _loc1_:Array = GlobalData.$mConfig_simple.zone_boss.open_times;
         var _loc5_:Number = Math.ceil(SendAndSelect.$systemTimer_nowSecond * 1000 + GlobalConfig.HOURS_8_MS);
         var _loc2_:Number = GlobalData.$mConfig_simple.zone_boss.predict_alive_time * 60 * 1000;
         if(_loc1_)
         {
            _loc10_ = 0;
            while(_loc10_ < _loc1_.length)
            {
               _loc9_ = _loc1_[_loc10_];
               _loc7_.hours = _loc9_[0];
               _loc7_.minutes = _loc9_[1];
               _loc7_.seconds = 0;
               _loc4_ = _loc7_.time;
               _loc3_ = _loc7_.time + _loc2_;
               if(_loc5_ < _loc3_ && _loc5_ >= _loc4_)
               {
                  _loc8_ = true;
               }
               _loc10_++;
            }
         }
         return _loc8_;
      }
      
      public static function checkBossInCD() : int
      {
         var _loc11_:int = 0;
         var _loc2_:int = 0;
         var _loc10_:int = 0;
         var _loc5_:Number = Number(NaN);
         var _loc4_:Number = Number(NaN);
         var _loc9_:Array = null;
         var _loc7_:Date = new Date();
         _loc11_ = checkBossInDelay();
         var _loc1_:Array = GlobalData.$mConfig_simple.zone_boss.open_times;
         var _loc6_:Number = Math.ceil(SendAndSelect.$systemTimer_nowSecond + GlobalConfig.HOURS_8_MS / 1000);
         var _loc8_:int = 0;
         var _loc3_:int = 2147483647;
         if(_loc1_)
         {
            _loc10_ = 0;
            while(_loc10_ < _loc1_.length)
            {
               _loc9_ = _loc1_[_loc10_];
               _loc7_.hours = _loc9_[0];
               _loc7_.minutes = _loc9_[1];
               _loc7_.seconds = 0;
               _loc5_ = Math.ceil(_loc7_.getTime() / 1000);
               _loc2_ = Math.abs(_loc5_ - _loc6_);
               if(_loc3_ > _loc2_)
               {
                  _loc3_ = _loc2_;
                  _loc8_ = _loc10_;
               }
               _loc10_++;
            }
            _loc9_ = _loc1_[_loc8_];
            _loc7_.hours = _loc9_[0];
            _loc7_.minutes = _loc9_[1];
            _loc7_.seconds = 0;
            _loc5_ = Math.ceil(_loc7_.getTime() / 1000);
            _loc2_ = _loc5_ - _loc6_ + _loc11_;
         }
         return _loc2_;
      }
      
      public static function checkEquipIsBook(param1:String) : Boolean
      {
         var _loc2_:Boolean = false;
         if(param1.indexOf("E_6") > -1)
         {
            _loc2_ = true;
         }
         return _loc2_;
      }
      
      public static function getEquipBookUpP(param1:Array, param2:String) : Number
      {
         var _loc11_:String = null;
         var _loc9_:Object = null;
         var _loc5_:Equip = null;
         var _loc3_:Array = null;
         var _loc8_:int = 0;
         var _loc6_:int = 0;
         var _loc14_:Object = null;
         var _loc7_:Number = Number(NaN);
         var _loc13_:int = 0;
         var _loc10_:Array = null;
         var _loc4_:int = 0;
         var _loc12_:Number = 0;
         if(param1 != null && param1.length > 0)
         {
            _loc11_ = param2;
            _loc9_ = GlobalData.$userData.my_equips[_loc11_];
            _loc5_ = null;
            if(_loc9_ != null)
            {
               _loc5_ = new Equip(_loc11_,_loc9_);
            }
            _loc3_ = GlobalData.$mConfig_simple.skill_book_rand as Array;
            _loc8_ = 0;
            _loc6_ = int(param1.length);
            _loc7_ = 0;
            _loc13_ = 0;
            _loc10_ = null;
            _loc4_ = 0;
            _loc8_ = 0;
            while(_loc8_ < _loc6_)
            {
               _loc14_ = GlobalData.$userData.my_equips[param1[_loc8_]];
               if(_loc14_)
               {
                  _loc10_ = String(_loc14_.eid).split("_");
                  _loc4_ = _loc13_ = int(_loc10_[2]);
                  _loc7_ = Number(_loc3_[_loc4_ - 1] != null ? _loc3_[_loc4_ - 1] : 0);
                  _loc12_ += _loc7_;
               }
               _loc8_++;
            }
            _loc12_ = Math.floor(_loc12_ / _loc5_.slv * 100) * 0.01;
         }
         return _loc12_ >= 1 ? 1 : _loc12_;
      }
      
      public static function checkEquipTypeWash(param1:String) : Boolean
      {
         var _loc2_:Boolean = false;
         if(param1.indexOf("E_1") > -1 || param1.indexOf("E_4") > -1)
         {
            _loc2_ = true;
         }
         return _loc2_;
      }
      
      public static function checkEquipHasUsed(param1:String) : int
      {
         var _loc4_:int = 0;
         var _loc3_:int = -1;
         var _loc5_:Array = GlobalData.$userData.as_equips;
         var _loc2_:int = 0;
         _loc4_ = 0;
         while(_loc4_ < _loc5_.length)
         {
            _loc2_ = (_loc5_[_loc4_] as Array).indexOf(param1);
            if(_loc2_ > -1)
            {
               _loc3_ = _loc4_ * 10 + _loc2_;
               break;
            }
            _loc4_++;
         }
         return _loc3_;
      }
      
      public static function changeEquipGroup(param1:String, param2:int, param3:int, param4:Boolean = false) : Array
      {
         var _loc9_:int = 0;
         var _loc8_:int = 0;
         var _loc7_:int = 0;
         var _loc6_:int = 0;
         var _loc5_:String = null;
         var _loc10_:Array = (GlobalData.$userData.as_equips as Array).concat();
         if(param4)
         {
            _loc10_[param2][param3] = null;
         }
         else
         {
            _loc9_ = 0;
            _loc8_ = 0;
            _loc7_ = int(_loc10_.length);
            _loc6_ = 6;
            _loc5_ = _loc10_[param2][param3];
            _loc5_ = _loc5_ == null || _loc5_ == "" ? null : _loc5_;
            _loc9_ = 0;
            while(_loc9_ < _loc7_)
            {
               _loc8_ = 0;
               while(_loc8_ < _loc6_)
               {
                  if(_loc10_[_loc9_][_loc8_] == param1)
                  {
                     _loc10_[_loc9_][_loc8_] = _loc5_;
                     break;
                  }
                  _loc8_++;
               }
               _loc9_++;
            }
            _loc10_[param2][param3] = param1;
         }
         return _loc10_;
      }
      
      public static function changeEquipGroupAll(param1:int, param2:int) : Array
      {
         var _loc4_:Array = GlobalData.$userData.as_equips as Array;
         var _loc3_:Array = _loc4_[param1];
         _loc4_[param1] = _loc4_[param2];
         _loc4_[param2] = _loc3_;
         return _loc4_;
      }
      
      public static function getPVPenemyEquip(param1:Array, param2:Boolean) : Object
      {
         var _loc8_:int = 0;
         var _loc5_:int = 0;
         var _loc4_:Object = null;
         var _loc3_:int = 0;
         var _loc7_:Array = [null,null,null,null,null,null];
         var _loc6_:Object = {};
         if(!param2 && param1 != null)
         {
            _loc8_ = 0;
            _loc5_ = int(param1.length);
            _loc3_ = 0;
            _loc8_ = 0;
            while(_loc8_ < _loc5_)
            {
               if(param1[_loc8_] != null)
               {
                  _loc4_ = param1[_loc8_];
                  _loc3_ = checkEquipTypeToId(_loc4_.eid,_loc7_);
                  _loc6_["eq" + _loc8_] = _loc4_;
                  _loc7_[_loc3_] = "eq" + _loc8_;
               }
               _loc8_++;
            }
         }
         return {
            "as_equips":_loc7_,
            "my_equips":_loc6_
         };
      }
      
      public static function getNextTextField(param1:String = null) : TextField
      {
         if($nextTextField)
         {
            $nextTextField.removeFromParent(true);
         }
         if(!param1)
         {
            param1 = GlobalLanguageStr.getLanguageStr(20212);
         }
         $nextTextField = DisplayTools.newTextField(param1,"",25,16777215,0,0,420,55);
         $nextTextField.addEventListener("addedToStage",addGlow);
         return $nextTextField;
      }
      
      public static function glow(param1:DisplayObject, param2:Number) : void
      {
         var _loc4_:Tween = null;
         if(!param1)
         {
            return;
         }
         var _loc3_:Juggler = GlobalData.$mStarling.juggler;
         _loc3_.removeTweens(param1);
         _loc4_ = new Tween(param1,param2,"easeInOut");
         if(param1.alpha <= GLOW_MIN_ALPHA)
         {
            _loc4_.fadeTo(GLOW_MAX_ALPHA);
         }
         else
         {
            _loc4_.fadeTo(GLOW_MIN_ALPHA);
         }
         _loc4_.onComplete = glow;
         _loc4_.onCompleteArgs = [param1,param2];
         _loc3_.add(_loc4_);
      }
      
      public static function addGlow(param1:starling.events.Event) : void
      {
         var _loc2_:DisplayObject = param1.currentTarget as DisplayObject;
         _loc2_.alpha = GLOW_MIN_ALPHA;
         glow(_loc2_,1.5);
         $nextTextField.addEventListener("removedFromStage",removeTween);
      }
      
      public static function removeTween(param1:starling.events.Event) : void
      {
         var _loc2_:Juggler = GlobalData.$mStarling.juggler;
         _loc2_.removeTweens(param1.currentTarget as DisplayObject);
         (param1.currentTarget as DisplayObject).removeEventListeners();
      }
      
      public static function checkMorph() : Number
      {
         var _loc6_:Number = Number(NaN);
         var _loc4_:* = GlobalData.$userData.attrs.morph.chance;
         var _loc3_:* = GlobalData.$mConfig_ploy_system_simple.morph.params;
         if(!_loc4_)
         {
            return -1;
         }
         var _loc1_:Date = _loc4_ as Date;
         var _loc2_:Number = _loc1_.getTime() * 0.001;
         var _loc5_:Number = SendAndSelect.$systemTimer_nowSecond;
         return _loc3_[4] * 60 + _loc2_ - _loc5_;
      }
      
      public static function getRndAvatarObj(param1:int) : Object
      {
         if(!GlobalData.$userData)
         {
            return null;
         }
         var _loc2_:Object = GlobalData.$userData.random_avatars;
         if(!_loc2_)
         {
            return null;
         }
         return _loc2_[param1.toString()];
      }
      
      public static function isRndCombat(param1:int, param2:String) : Boolean
      {
         if(!GlobalFunction.hasRndAvatar(param1))
         {
            return null;
         }
         var _loc3_:Object = GlobalFunction.getRndAvatarObj(param1);
         if(_loc3_.cid == param2)
         {
            return true;
         }
         return false;
      }
      
      public static function hasRndAvatar(param1:int) : Boolean
      {
         var _loc5_:Object = getRndAvatarObj(param1);
         if(!_loc5_)
         {
            return false;
         }
         if(!_loc5_.start_time)
         {
            return false;
         }
         var _loc6_:Array = GlobalData.$mConfig_simple.random_battle;
         if(!_loc6_)
         {
            return false;
         }
         _loc6_ = _loc6_[param1];
         if(!_loc6_)
         {
            return false;
         }
         if(_loc5_.times > _loc6_[2])
         {
            return false;
         }
         var _loc2_:Date = _loc5_.start_time as Date;
         var _loc3_:Number = _loc2_.getTime() * 0.001;
         var _loc7_:Number = SendAndSelect.$systemTimer_nowSecond;
         var _loc4_:Number = (_loc7_ - _loc3_) / 60;
         if(_loc4_ > 0 && _loc4_ < _loc6_[0])
         {
            return true;
         }
         return false;
      }
      
      public static function getRndSpr() : starling.display.Sprite
      {
         var _fun:Function;
         var _spr:starling.display.Sprite = new starling.display.Sprite();
         _spr.touchable = false;
         if(!$rndMC1)
         {
            $rndMC1 = DisplayTools.newMc("rndAvatar1",0,0,10);
            $rndMC1.scaleX = $rndMC1.scaleY = 2;
            $rndMC1.loop = false;
         }
         $rndMC1.visible = false;
         _spr.addChild($rndMC1);
         if($rndMCShow)
         {
            completeRndMc(null);
            return _spr;
         }
         _fun = function():void
         {
            $rndMC1.stop();
            $rndMC1.play();
            $rndMC1.addEventListener("complete",completeRndMc);
            GlobalData.$mStarling.juggler.add($rndMC1);
            $rndMC1.visible = true;
         };
         GlobalData.$mStarling.juggler.delayCall(_fun,0.5);
         SoundManager.getOnlyExample().playSound("rndAvatar");
         return _spr;
      }
      
      public static function stopRndSpr() : void
      {
         if($rndMC1)
         {
            $rndMC1.stop();
         }
         if($rndMC2)
         {
            $rndMC2.stop();
         }
      }
      
      public static function completeRndMc(param1:starling.events.Event) : void
      {
         if(!$rndMC1)
         {
            return;
         }
         $rndMC1.removeEventListener("complete",completeRndMc);
         if($rndMC1.parent)
         {
            if(!$rndMC2)
            {
               $rndMC2 = DisplayTools.newMc("rndAvatar2",0,0,10);
            }
            $rndMC2.stop();
            $rndMC2.play();
            GlobalData.$mStarling.juggler.add($rndMC2);
            $rndMC1.parent.addChild($rndMC2);
            $rndMC1.removeFromParent();
            $rndMC1.stop();
            $rndMCShow = true;
         }
      }
      
      public static function getEquipRiseMaxLv() : int
      {
         var _loc1_:Object = getVipObj();
         var _loc2_:int = 0;
         if(_loc1_)
         {
            _loc2_ = int(_loc1_.equip_lvmax);
         }
         return GlobalData.$userData.lv + _loc2_;
      }
      
      public static function getVipLv() : int
      {
         if(!GlobalData.$userData)
         {
            return 0;
         }
         return GlobalData.$userData.vip_lv;
      }
      
      public static function getVipLvWidth(param1:int = -1, param2:Number = 0) : int
      {
         var _loc3_:Number = Number(NaN);
         if(param1 < 0)
         {
            param1 = getVipLv();
         }
         if(param1 == 0)
         {
            _loc3_ = 0;
         }
         else if(param1 == 1)
         {
            _loc3_ = 0.5;
         }
         else if(param1 <= 10)
         {
            _loc3_ = 1;
         }
         else
         {
            _loc3_ = 2;
         }
         return param2 != 1 ? 40 + 10 + _loc3_ * 15 : 80 + _loc3_ * 30;
      }
      
      public static function getVipObj(param1:int = -1) : Object
      {
         if(param1 < 0)
         {
            param1 = getVipLv();
         }
         return GlobalData.$mConfig_vip[param1];
      }
      
      public static function isInVipTime() : Boolean
      {
         return getVIPTimeS() > 0;
      }
      
      public static function payCoinVip(param1:int, param2:Boolean = false, param3:int = 0) : String
      {
         var _loc11_:int = 0;
         var _loc7_:Object = null;
         if(param1 == 0)
         {
            return "";
         }
         GlobalData.$userData.coin -= param1;
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
         var _loc5_:Number = param2 ? 1 : getVipRate();
         var _loc10_:int = getVipLv();
         if(_loc10_ == 0)
         {
            return GlobalFunction.checkIOSvip() ? GlobalLanguageStr.getLanguageStr(20195) : "";
         }
         if(!isInVipTime() && !param2)
         {
            return GlobalFunction.checkIOSvip() ? GlobalLanguageStr.getLanguageStr(20196) : "";
         }
         var _loc4_:int = geVipMaxLv();
         var _loc6_:int = int(GlobalData.$userData.vip_exp);
         _loc6_ += param2 ? param3 : param1 * _loc5_;
         _loc11_ = _loc10_;
         while(_loc11_ < _loc4_)
         {
            _loc7_ = getVipObj(_loc11_);
            if(_loc6_ < _loc7_.need_exp)
            {
               break;
            }
            _loc6_ -= _loc7_.need_exp;
            _loc11_++;
         }
         GlobalData.$userData.vip_lv = _loc11_;
         GlobalData.$userData.vip_exp = _loc6_;
         var _loc8_:Boolean = Boolean(GlobalFunction.checkIOSvip());
         if(_loc10_ != _loc11_)
         {
            if(_loc8_)
            {
               popAward("_$vip$_",GlobalLanguageStr.getLanguageStr(20203,_loc11_),_loc11_);
            }
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateVip();
            return "";
         }
         var _loc9_:String = _loc5_ == 1 ? (param2 ? param3.toString() : param1.toString()) : param1 + GlobalLanguageStr.getLanguageStr(20193) + _loc5_;
         return _loc8_ ? GlobalLanguageStr.getLanguageStr(20194,_loc9_) : GlobalLanguageStr.getLanguageStr(90027);
      }
      
      public static function getVipRate() : Number
      {
         var _loc4_:Object = null;
         var _loc1_:Number = Number(NaN);
         var _loc7_:Number = Number(NaN);
         var _loc5_:Number = Number(NaN);
         var _loc8_:Number = Number(NaN);
         var _loc2_:Array = GlobalData.$mConfig_simple.vip_config;
         var _loc6_:Number;
         var _loc3_:Number = _loc6_ = Number(_loc2_[1]);
         if(_loc2_[4] != null)
         {
            _loc4_ = GlobalData.$mConfig_zones[GlobalData.$mServiceID];
            _loc1_ = (_loc4_[1] as Date).time * 0.001;
            _loc7_ = _loc1_ + _loc2_[5] * 60;
            _loc5_ = SendAndSelect.$systemTimer_nowSecond;
            _loc8_ = Number(_loc2_[4]);
            if(_loc5_ >= _loc1_ && _loc5_ < _loc7_)
            {
               if(_loc8_ >= _loc6_)
               {
                  _loc3_ = _loc8_;
               }
            }
         }
         return _loc3_;
      }
      
      public static function getAllVipExp() : int
      {
         var _loc1_:int = getVipLv();
         var _loc2_:Object = GlobalData.$mConfig_vip[_loc1_.toString()];
         // The server sends progress within the current tier.  The row's exp
         // is its cumulative gift-coin threshold, including VIP1's first 60.
         return int(_loc2_ ? _loc2_.exp : 0) + int(GlobalData.$userData.vip_exp);
      }
      
      public static function geVipMaxLv() : int
      {
         return GlobalData.$mConfig_simple.vip_config[2];
      }
      
      public static function geVipAllLv() : int
      {
         return GlobalData.$mConfig_simple.vip_config[3];
      }
      
      public static function getVipImg(param1:int = -1, param2:String = "") : Image
      {
         if(param1 < 0)
         {
            param1 = getVipLv();
         }
         var _loc6_:String = param2 == "" ? GlobalData.$userData.uid : param2;
         var _loc5_:Boolean = false;
         var _loc4_:Array = GlobalData.$mConfig_client.star_id;
         if(_loc4_ != null && _loc4_.length > 0)
         {
            _loc5_ = _loc4_.indexOf(_loc6_) > -1;
         }
         var _loc3_:String = _loc5_ ? "UI_star_icon_vip_0000" : "UI_tag_vip_" + Tools.fillStr(param1.toString(),4,"0");
         var _loc7_:Image = createImage(_loc3_);
         _loc7_.touchable = false;
         if(!_loc5_)
         {
            _loc7_.pivotX = int(_loc7_.width * 0.5);
            _loc7_.pivotY = int(_loc7_.height * 0.5);
         }
         else
         {
            _loc7_.pivotY = 15;
         }
         return _loc7_;
      }
      
      public static function getVipImgTxt(param1:int = -1) : Image
      {
         if(param1 < 0)
         {
            param1 = getVipLv();
         }
         var _loc2_:String = "UI_tag_vip_1_" + Tools.fillStr(param1.toString(),4,"0");
         var _loc3_:Image = createImage(_loc2_);
         _loc3_.touchable = false;
         return _loc3_;
      }
      
      public static function getVipEXP(param1:int) : Number
      {
         var _loc1_:Object = GlobalData.$mConfig_vip[param1.toString()];
         return _loc1_ ? Number(_loc1_.exp) : 0;
      }
      
      public static function getVIPTimeS() : Number
      {
         var _loc2_:Number = Number(NaN);
         var _loc1_:Number = 0;
         if(GlobalData.$userData != null && GlobalData.$userData.vip_lv != null && GlobalData.$userData.vip_lv > 0)
         {
            _loc2_ = (GlobalData.$userData.vip_time as Date).time * 0.001;
            _loc1_ = _loc2_ - SendAndSelect.$systemTimer_nowSecond;
            _loc1_ = _loc1_ < 0 ? 0 : _loc1_;
         }
         return _loc1_;
      }
      
      public static function getVIPTimeTxt() : String
      {
         var _loc2_:Number = getVIPTimeS();
         var _loc1_:String = Tools.timeFormatAll(_loc2_,false);
         if(_loc2_ <= 0)
         {
            _loc1_ = GlobalLanguageStr.getLanguageStr(20197);
         }
         return _loc1_;
      }
      
      public static function getVIPgiftInfo(param1:int, param2:uint = 16777215, param3:uint = 16764006, param4:int = 20) : String
      {
         var _loc11_:Array = null;
         var _loc9_:int = 0;
         var _loc14_:Array = null;
         var _loc20_:String = null;
         var _loc16_:* = undefined;
         var _loc12_:Object = null;
         var _loc17_:String = null;
         if(param1 <= 0)
         {
            return "";
         }
         var _loc5_:Object = GlobalData.$mConfig_vip[param1];
         var _loc13_:int = 0;
         var _loc10_:Array = [];
         var _loc18_:Array = [param2,param3,param2,param3];
         var _loc6_:Array = GlobalData.$mConfig_simple.vip_tips as Array;
         _loc9_ = int(_loc6_.length);
         var _loc15_:String = "";
         var _loc8_:int = -1;
         var _loc7_:int = 0;
         _loc13_ = 0;
         for(; _loc13_ < _loc9_; _loc13_++)
         {
            _loc14_ = _loc6_[_loc13_];
            _loc16_ = _loc5_[_loc14_[1]];
            _loc8_ = int(_loc14_[2]);
            if(_loc14_[1] == "rise_onekey" || _loc14_[1] == "battle_speed" || _loc14_[1] == "equip_lvmax" || _loc14_[1] == "explore_count" || _loc14_[1] == "explore_relive" || _loc14_[1] == "close_sever_talk" || _loc14_[1] == "hit_guild_boss" || _loc14_[1] == "energy_limit_add" || _loc14_[1] == "friend_len_add" || _loc14_[1] == "avatar_len_add")
            {
               if(_loc8_ < 0)
               {
                  if(int(_loc16_) <= 0)
                  {
                     continue;
                  }
               }
            }
            if(_loc14_[1] != "rise_onekey" && _loc14_[1] != "battle_speed" && (_loc8_ < 0 && _loc16_ != "" || _loc8_ > -1 && _loc16_ != null))
            {
               if("swallow_rp" == _loc14_[1] && _loc8_ == 0)
               {
                  if(_loc16_[0] <= 0)
                  {
                     continue;
                  }
                  _loc15_ = _loc16_[0];
               }
               else if("swallow_rp" == _loc14_[1] && _loc8_ == 1)
               {
                  if(_loc16_[1] <= 0)
                  {
                     continue;
                  }
                  _loc15_ = _loc16_[1];
               }
               else if("forge_rp" == _loc14_[1] && _loc8_ == 0)
               {
                  if(_loc16_[0] <= 0)
                  {
                     continue;
                  }
                  _loc15_ = _loc16_[0];
               }
               else if("forge_rp" == _loc14_[1] && _loc8_ == 1)
               {
                  if(_loc16_[1] <= 0)
                  {
                     continue;
                  }
                  _loc15_ = _loc16_[1];
               }
               else
               {
                  if(_loc16_ <= 0)
                  {
                     continue;
                  }
                  _loc15_ = _loc16_;
               }
            }
            else
            {
               _loc15_ = "";
            }
            _loc7_ += 1;
            _loc20_ = _loc7_ + "." + GlobalLanguageStr.getLanguageStr(_loc14_[0],_loc15_);
            _loc10_.push(Tools.formatLineX(_loc20_,_loc18_,100,param4));
         }
         var _loc19_:int = int(_loc10_.length);
         _loc11_ = _loc5_.gift as Array;
         _loc20_ = GlobalLanguageStr.getLanguageStr(70002);
         _loc9_ = int(_loc11_.length);
         _loc13_ = 0;
         while(_loc13_ < _loc9_)
         {
            _loc12_ = _loc11_[_loc13_];
            if(_loc12_)
            {
               _loc17_ = String(_loc13_ + _loc19_ + 1) + "." + _loc20_ + "{" + " " + check_awardNmae(_loc12_) + "}";
               _loc10_.push(Tools.formatLineX(_loc17_,_loc18_,100,param4));
            }
            _loc13_++;
         }
         _loc13_ = 0;
         while(_loc13_ < 4)
         {
            _loc10_.push("");
            _loc13_++;
         }
         return Tools.formatHtmlTextBr(_loc10_,"left");
      }
      
      public static function getVIP_avatarBetterPer(param1:Number) : String
      {
         var _loc3_:Object = GlobalData.$mConfig_simple.exp_multiple;
         var _loc6_:Array = [];
         for(var _loc9_:Object in _loc3_)
         {
            _loc6_[_loc9_.toString()];
         }
         _loc6_.sort();
         var _loc7_:Number = Number(_loc3_[_loc6_[0]]);
         var _loc5_:Number = Number(_loc3_[_loc6_[1]]);
         var _loc8_:Number = Number(_loc3_[_loc6_[2]]);
         var _loc2_:Number = (param1 + _loc8_) / (param1 + _loc7_ + _loc5_ + _loc8_);
         var _loc4_:Number = _loc8_ / (_loc7_ + _loc5_ + _loc8_);
         return GameMapTools.toPercentage(_loc2_ - _loc4_);
      }
      
      public static function check_awardNmae(param1:Object) : String
      {
         var _loc9_:Array = null;
         var _loc7_:int = 0;
         var _loc5_:String = "";
         var _loc4_:Array = Tools.getObjectKeyValue(param1);
         var _loc6_:String = "";
         var _loc8_:int = 0;
         var _loc2_:String = "";
         var _loc3_:String = _loc4_[0];
         if(_loc3_ == "coin")
         {
            _loc8_ = 20149;
            _loc5_ = String(_loc4_[1]);
         }
         else if(_loc3_ == "gold")
         {
            _loc8_ = 20162;
            _loc5_ = String(_loc4_[1]);
         }
         else if(_loc3_ == "score")
         {
            _loc8_ = 20163;
            _loc5_ = String(_loc4_[1]);
         }
         else if(_loc3_ == "energy")
         {
            _loc8_ = 20164;
            _loc5_ = String(_loc4_[1]);
         }
         else if(_loc3_ == "avatar")
         {
            _loc9_ = Tools.getObjectKeyValue(_loc4_[1]);
            _loc2_ = _loc9_[0];
            if(_loc2_ != "")
            {
               if(GlobalData.$mConfig_avatar[_loc2_])
               {
                  if(GlobalData.$mConfig_avatar[_loc2_].name)
                  {
                     _loc7_ = int(_loc2_.split("_")[2]);
                     _loc6_ = GlobalData.$mConfig_avatar[_loc2_].name;
                     _loc6_ = " " + GlobalLanguageStr.getLanguageStr(20205,_loc7_,_loc6_);
                  }
               }
            }
            _loc5_ = "";
         }
         if(_loc8_ != 0)
         {
            _loc6_ = GlobalLanguageStr.getLanguageStr(_loc8_) + " " + _loc2_;
         }
         return _loc6_ + _loc5_;
      }
      
      public static function changeTeam(param1:int, param2:int, param3:String, param4:Boolean = true) : Boolean
      {
         var _loc6_:Boolean = false;
         var _loc5_:int = 0;
         var _loc8_:int = 0;
         var _loc7_:String = null;
         if(Tools.strIsNull(param3))
         {
            if(param2 != 0)
            {
               GlobalData.$userData.team[param1][param2] = null;
            }
         }
         else
         {
            _loc6_ = !Tools.strIsNull(GlobalData.$userData.team[param1][param2]);
            _loc5_ = (GlobalData.$userData.team[param1] as Array).indexOf(param3);
            _loc8_ = check_dn_had_avatarID(param3);
            if(_loc6_)
            {
               _loc7_ = GlobalData.$userData.team[param1][param2];
               if(_loc5_ > -1)
               {
                  GlobalData.$userData.team[param1][_loc5_] = _loc7_;
               }
               else if(_loc8_ > -1)
               {
                  if(_loc7_.indexOf("A_1") < 0)
                  {
                     popError(GlobalLanguageStr.getLanguageStr(90507));
                     return false;
                  }
                  GlobalData.$userData.attrs.dn[String(_loc8_)][1] = _loc7_;
               }
            }
            else if(_loc5_ > -1)
            {
               GlobalData.$userData.team[param1][_loc5_] = null;
            }
            else if(_loc8_ > -1)
            {
               GlobalData.$userData.attrs.dn[String(_loc8_)][1] = null;
            }
            GlobalData.$userData.team[param1][param2] = param3;
         }
         formateTeamToObj();
         if(param4)
         {
            SendServiceAMFFun.send_user_fix_team(re_fix_team,{
               "team":GlobalData.$userData.team,
               "team_num":GlobalData.$tempTeamID,
               "dn":GlobalData.$userData.attrs.dn
            });
         }
         return true;
      }
      
      public static function re_fix_team(param1:*) : void
      {
         GuideMaster.getOnlyExample().nextGuideStep();
      }
      
      public static function changeDNteam(param1:String, param2:String, param3:Boolean = true) : Boolean
      {
         var _loc7_:Boolean = false;
         var _loc6_:int = 0;
         var _loc4_:Avatar = null;
         var _loc8_:int = 0;
         var _loc9_:String = null;
         var _loc10_:Array = GlobalData.$userData.attrs.dn[param1] as Array;
         var _loc5_:Boolean = true;
         if(Tools.strIsNull(param2))
         {
            _loc10_[1] = null;
         }
         else
         {
            _loc7_ = _loc10_[1] != null;
            _loc6_ = (GlobalData.$userData.team[0] as Array).indexOf(param2);
            if(_loc6_ > -1)
            {
               if(_loc7_)
               {
                  GlobalData.$tempTeamSelectLS = GlobalFunction.getTeamLeaderShip(GlobalData.$userData.team[0]);
                  GlobalData.$tempUserLS = GlobalFunction.getLeaderShip();
                  _loc4_ = new Avatar(param2);
                  GlobalData.$tempTeamSelectLS -= _loc4_.getLeadership();
                  _loc4_.clear();
                  _loc4_ = null;
                  _loc4_ = new Avatar(_loc10_[1]);
                  GlobalData.$tempTeamSelectLS += _loc4_.getLeadership();
                  _loc4_.clear();
                  _loc4_ = null;
                  if(GlobalData.$tempTeamSelectLS > GlobalData.$tempUserLS)
                  {
                     popError(GlobalLanguageStr.getLanguageStr(90439));
                     _loc5_ = false;
                  }
                  else
                  {
                     GlobalData.$userData.team[0][_loc6_] = _loc10_[1];
                     _loc10_[1] = param2;
                  }
               }
               else if(_loc6_ > 0)
               {
                  GlobalData.$userData.team[0][_loc6_] = null;
                  _loc10_[1] = param2;
                  GlobalData.$tempTeamSelectLS = GlobalFunction.getTeamLeaderShip(GlobalData.$userData.team[0]);
               }
               else
               {
                  popError(GlobalLanguageStr.getLanguageStr(90440));
                  _loc5_ = false;
               }
            }
            else
            {
               _loc8_ = check_dn_had_avatarID(param2);
               if(_loc7_)
               {
                  if(_loc10_[1] == param2)
                  {
                     _loc5_ = false;
                  }
                  else if(_loc8_ > -1)
                  {
                     _loc9_ = _loc10_[1];
                     _loc10_[1] = param2;
                     GlobalData.$userData.attrs.dn[String(_loc8_)][1] = _loc9_;
                  }
                  else
                  {
                     _loc10_[1] = param2;
                  }
               }
               else if(_loc8_ > -1)
               {
                  GlobalData.$userData.attrs.dn[String(_loc8_)][1] = null;
                  _loc10_[1] = param2;
               }
               else
               {
                  _loc10_[1] = param2;
               }
            }
         }
         if(_loc5_)
         {
            GlobalData.$userData.attrs.dn[param1] = _loc10_;
            formateTeamToObj();
            if(param3)
            {
               SendServiceAMFFun.send_user_fix_team(null,{
                  "team":GlobalData.$userData.team,
                  "team_num":GlobalData.$tempTeamID,
                  "dn":GlobalData.$userData.attrs.dn
               });
            }
         }
         return _loc5_;
      }
      
      public static function check_dn_had_avatarID(param1:String) : int
      {
         var _loc3_:Array = null;
         var _loc2_:int = -1;
         for(var _loc4_:Object in GlobalData.$userData.attrs.dn)
         {
            _loc3_ = GlobalData.$userData.attrs.dn[_loc4_];
            if(_loc3_[1] == param1)
            {
               _loc2_ = int(_loc4_.toString());
               break;
            }
         }
         return _loc2_;
      }
      
      public static function changeDNteam_del(param1:String) : void
      {
         var _loc2_:Array = null;
         for(var _loc3_:Object in GlobalData.$userData.attrs.dn)
         {
            _loc2_ = GlobalData.$userData.attrs.dn[_loc3_];
            if(_loc2_[1] == param1)
            {
               _loc2_[1] = null;
               break;
            }
         }
      }
      
      public static function formateTeamToObj() : void
      {
         var _loc1_:Object = null;
         $teamDataObj = {};
         var _loc3_:Array = GlobalData.$userData.team;
         var _loc5_:uint = 0;
         var _loc4_:uint = 0;
         var _loc2_:uint = 5;
         _loc4_ = 0;
         while(_loc4_ < _loc2_)
         {
            if(_loc3_[_loc5_][_loc4_] != null)
            {
               _loc1_ = $teamDataObj[_loc3_[_loc5_][_loc4_]];
               if(_loc1_ != null)
               {
                  _loc1_.num += 1;
               }
               else
               {
                  $teamDataObj[_loc3_[_loc5_][_loc4_]] = {
                     "id":_loc3_[_loc5_][_loc4_],
                     "a":_loc5_,
                     "b":_loc4_,
                     "num":1
                  };
               }
            }
            _loc4_++;
         }
      }
      
      public static function changeTeamOneToOne(param1:String, param2:String) : void
      {
         var _loc4_:Array = GlobalData.$userData.team;
         var _loc7_:uint = 0;
         var _loc5_:uint = 0;
         var _loc3_:uint = 5;
         var _loc6_:Boolean = false;
         _loc5_ = 0;
         while(_loc5_ < _loc3_)
         {
            if(_loc4_[_loc7_][_loc5_] != null)
            {
               if(_loc4_[_loc7_][_loc5_] == param1)
               {
                  _loc6_ = true;
                  _loc4_[_loc7_][_loc5_] = param2;
               }
            }
            _loc5_++;
         }
         if(_loc6_)
         {
            formateTeamToObj();
         }
      }
      
      public static function checkIsTeamMember(param1:String) : Boolean
      {
         return GlobalData.$userData.team[0].indexOf(param1) > -1;
      }
      
      public static function checkIsActiveExplorationMember(param1:String) : Boolean
      {
         var _loc2_:Object = GlobalData.$userData.exploration;
         var _loc3_:Object = _loc2_ == null ? null : _loc2_.army;
         var _loc4_:int = int(GlobalData.$mConfig_simple.explore.map_max);
         if(_loc3_ == null || _loc2_.stage == null)
         {
            return false;
         }
         if(int(_loc2_.stage) > _loc4_ && int(_loc2_.current_stage_finish) != 1)
         {
            return false;
         }
         return _loc3_.hasOwnProperty(param1);
      }
      
      public static function getTeamMemberNum(param1:String) : int
      {
         var _loc2_:int = 0;
         var _loc3_:Object = $teamDataObj[param1];
         if(_loc3_ != null)
         {
            _loc2_ = _loc3_.num * 10000 + (5 - _loc3_.a) * 1000 + (5 - _loc3_.b) * 100;
         }
         return _loc2_;
      }
      
      public static function getCurrTeamLeaderID(param1:int) : String
      {
         return GlobalData.$userData.team[param1][0];
      }
      
      public static function getLeaderShip(param1:Object = null) : int
      {
         var _loc6_:Object = param1 == null ? GlobalData.$userData : param1;
         var _loc2_:Array = GlobalData.$mConfig_simple.leadership as Array;
         var _loc5_:int = int(_loc2_[0]);
         var _loc4_:int = int(_loc2_[1]);
         var _loc3_:int = Math.floor(_loc5_ * _loc6_.lv + _loc4_);
         _loc3_ += getVipLv() > 0 ? int(getVipObj().leadership_up) : 0;
         _loc6_ = null;
         _loc2_ = null;
         return _loc3_;
      }
      
      public static function getTeamLeaderShip(param1:Array) : int
      {
         var _loc2_:Avatar = null;
         var _loc6_:int = 0;
         var _loc4_:int = int(param1.length);
         var _loc3_:String = "";
         var _loc5_:int = 0;
         _loc6_ = 0;
         while(_loc6_ < _loc4_)
         {
            _loc3_ = param1[_loc6_];
            if(!Tools.strIsNull(_loc3_))
            {
               _loc2_ = new Avatar(_loc3_);
               _loc5_ += _loc2_.getLeadership();
               _loc2_.clear();
            }
            _loc2_ = null;
            _loc6_++;
         }
         return _loc5_;
      }
      
      public static function checkTeamLeaderShipIsOK(param1:Array) : Boolean
      {
         var _loc3_:Number = getTeamLeaderShip(param1);
         var _loc2_:Number = getLeaderShip();
         return _loc3_ <= _loc2_;
      }
      
      public static function getTeamPower(param1:Array, param2:* = null) : Number
      {
         var _loc3_:Avatar = null;
         var _loc7_:Object = null;
         var _loc9_:int = 0;
         var _loc6_:int = int(param1.length);
         var _loc4_:String = "";
         var _loc8_:Number = 0;
         var _loc5_:Array = GlobalData.$userData.as_equips;
         _loc9_ = 0;
         while(_loc9_ < _loc6_)
         {
            _loc4_ = param1[_loc9_];
            if(!Tools.strIsNull(_loc4_))
            {
               _loc3_ = new Avatar(_loc4_);
               _loc3_.setEquips(_loc5_[_loc9_]);
               _loc3_.setDestinyAndDN(_loc4_,param1);
               _loc3_.initFightAttr();
               _loc8_ += _loc3_.getPower(_loc9_ == 0,-1,true);
               _loc3_.clear();
            }
            _loc9_++;
         }
         if(param2)
         {
            _loc7_ = param2.avatar;
            _loc3_ = new Avatar(_loc7_.id,_loc7_);
            _loc3_.initFightAttr();
            _loc8_ += _loc3_.getPower(param2.isF == 1);
            _loc3_.clear();
         }
         return _loc8_;
      }
      
      public static function isTeamItemUnlock(param1:int) : Boolean
      {
         var _loc3_:Boolean = false;
         var _loc2_:Array = GlobalData.$mConfig_simple.unlock_avatar as Array;
         var _loc4_:int = int(_loc2_[param1]);
         if(GlobalData.$userData.lv >= _loc4_)
         {
            _loc3_ = true;
         }
         _loc2_ = null;
         if(GlobalData.$InfoLookFromChat)
         {
            _loc3_ = true;
         }
         return _loc3_;
      }
      
      public static function isExisitTeam(param1:String) : int
      {
         var _loc2_:int = -1;
         var _loc3_:Array = GlobalData.$tempTeam;
         return _loc3_.indexOf(param1);
      }
      
      public static function isTeamUnlock(param1:int) : Boolean
      {
         var _loc3_:Boolean = false;
         var _loc2_:Array = GlobalData.$mConfig_simple.unlock_team as Array;
         var _loc4_:int = int(_loc2_[param1]);
         if(GlobalData.$userData.lv >= _loc4_)
         {
            _loc3_ = true;
         }
         _loc2_ = null;
         return _loc3_;
      }
      
      public static function updateLvUnlockTeam() : void
      {
      }
      
      public static function check_battle_ploy(param1:String) : Object
      {
         var _loc9_:Number = GlobalData.$mConfig_simple.activity_show * 60;
         var _loc2_:Object = GlobalData.$mConfig_battle_ploy[param1];
         var _loc5_:Date = _loc2_.start_time as Date;
         var _loc7_:Date = _loc2_.end_time as Date;
         var _loc3_:Number = _loc5_.getTime() * 0.001;
         var _loc8_:Number = _loc7_.getTime() * 0.001;
         var _loc4_:Number = _loc2_.cycle * 60;
         var _loc11_:Number = _loc2_.duration * 60;
         var _loc6_:Number = SendAndSelect.$systemTimer_nowSecond;
         var _loc13_:Number = _loc6_ - _loc3_;
         var _loc10_:Number = _loc13_ % _loc4_;
         return {
            "moreS":_loc10_,
            "endS":_loc11_ - _loc10_,
            "startS":(_loc13_ > 0 ? _loc4_ - _loc10_ : Math.abs(_loc13_)),
            "rulerS":_loc9_,
            "s":_loc3_,
            "e":_loc8_,
            "now":_loc6_
         };
      }
      
      public static function check_pass_activeity_battle(param1:String) : Boolean
      {
         var _loc5_:int = 0;
         var _loc3_:Object = GlobalData.$mConfig_battle_ploy;
         var _loc4_:int = int(_loc3_[param1].combat);
         var _loc2_:Boolean = true;
         _loc5_ = 1;
         while(_loc5_ <= _loc4_)
         {
            if(check_pass_combat(param1 + "_" + _loc5_.toString(),GlobalData.$tempPVE_type_id) != 1)
            {
               _loc2_ = false;
            }
            _loc5_++;
         }
         return _loc2_;
      }
      
      public static function current_battle_main(param1:int = 0) : String
      {
         if(param1 == 1)
         {
            return GlobalData.$userData.hid;
         }
         return GlobalData.$userData.cid;
      }
      
      public static function check_pass_battle_main(param1:String, param2:int = 0) : int
      {
         var _loc6_:Array = null;
         var _loc3_:int = 0;
         var _loc5_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:Array = param1.split("_");
         var _loc4_:Object = GlobalData.$config_battle_main[param1];
         var _loc9_:String = current_battle_main(param2);
         if(!Tools.strIsNull(_loc9_))
         {
            _loc6_ = _loc9_.split("_");
            _loc3_ = int(_loc6_[1]);
            _loc5_ = int(_loc6_[2]);
            if(_loc8_[1] < _loc3_)
            {
               _loc7_ = 1;
            }
            else if(_loc8_[1] == _loc3_)
            {
               if(_loc5_ > _loc4_.combat)
               {
                  _loc7_ = 1;
               }
               else
               {
                  _loc7_ = 2;
               }
            }
         }
         return _loc7_;
      }
      
      public static function compareCid(param1:String, param2:String) : int
      {
         var _loc7_:int = 0;
         var _loc3_:Array = param1.split("_");
         var _loc6_:Array = param2.split("_");
         var _loc5_:int = int(_loc3_[1]);
         var _loc4_:int = int(_loc6_[1]);
         if(_loc5_ > _loc4_)
         {
            return 1;
         }
         if(_loc5_ < _loc4_)
         {
            return -1;
         }
         return 0;
      }
      
      public static function check_pass_combat(param1:String, param2:int = 0) : int
      {
         var _loc6_:int = 0;
         var _loc4_:String = null;
         var _loc3_:Array = null;
         var _loc5_:String = param1.charAt(0);
         if(GlobalData.$currentGuide)
         {
            return 2;
         }
         if(_loc5_ == MAIN)
         {
            return check_pass_combat_main(param1,param2);
         }
         if(_loc5_ == PLOY)
         {
            _loc4_ = param1.slice(0,param1.length - 2);
            _loc6_ = 2;
            _loc3_ = GlobalData.$userData.ploy_cids[_loc4_];
            if(_loc3_ != null)
            {
               if(_loc3_.length > 0 && _loc3_.indexOf(param1) > -1)
               {
                  _loc6_ = 1;
               }
            }
            return _loc6_;
         }
         return -1;
      }
      
      public static function check_pass_combat_main(param1:String, param2:int = 0) : int
      {
         var _loc9_:String = null;
         var _loc6_:Array = null;
         var _loc3_:int = 0;
         var _loc5_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:Array = param1.split("_");
         var _loc4_:Object = GlobalData.$config_combat_main[param1];
         if(!GlobalData.$userData)
         {
            if(param2 == 1)
            {
               return 2;
            }
            return 1;
         }
         if(param2 == 1)
         {
            _loc9_ = GlobalData.$userData.hid;
         }
         else
         {
            _loc9_ = GlobalData.$userData.cid;
         }
         if(!Tools.strIsNull(_loc9_))
         {
            _loc6_ = _loc9_.split("_");
            _loc3_ = int(_loc6_[1]);
            _loc5_ = int(_loc6_[2]);
            if(_loc8_[1] < _loc3_)
            {
               _loc7_ = 1;
            }
            else if(_loc8_[1] == _loc3_)
            {
               if(_loc8_[2] < _loc5_)
               {
                  _loc7_ = 1;
               }
               else if(_loc8_[2] == _loc5_)
               {
                  _loc7_ = 2;
               }
            }
         }
         return _loc7_;
      }
      
      public static function getActivityFun(param1:String) : Object
      {
         return {"data":{"id":param1}};
      }
      
      public static function createImage(param1:String, param2:Boolean = false) : Image
      {
         var _loc4_:Texture = null;
         if(param2)
         {
            _loc4_ = getTextureByBD(param1);
         }
         else
         {
            _loc4_ = getTexture(param1);
         }
         var _loc3_:Image = new Image(_loc4_);
         var _loc5_:Rectangle = _loc4_.frame;
         if(_loc5_ == null)
         {
            _loc5_ = new Rectangle(0,0,_loc4_.width,_loc4_.height);
         }
         _loc3_.width = _loc5_.width;
         _loc3_.height = _loc5_.height;
         return _loc3_;
      }
      
      public static function createGiftSprite(param1:*, param2:String = "UI_gift_bg_0000") : starling.display.Sprite
      {
         var _loc6_:String = null;
         _loc6_ = "UI_award_ui_type_00";
         var _loc9_:int = 0;
         _loc9_ = 2;
         var _loc5_:String = "";
         var _loc4_:int = int(String(param1).split().length);
         if(_loc4_ < 2)
         {
            _loc5_ = "UI_award_ui_type_000" + String(param1);
         }
         else if(_loc4_ < 3)
         {
            _loc5_ = "UI_award_ui_type_00" + String(param1);
         }
         else
         {
            _loc5_ = String(param1);
         }
         var _loc7_:starling.display.Sprite = new starling.display.Sprite();
         var _loc8_:Image = GlobalFunction.createImage(param2);
         _loc7_.addChild(_loc8_);
         var _loc3_:Image = GlobalFunction.createImage(_loc5_);
         _loc3_.x = _loc8_.x + (_loc8_.width - _loc3_.width) * 0.5;
         _loc3_.y = _loc8_.y + (_loc8_.height - _loc3_.height) * 0.5;
         _loc7_.addChild(_loc3_);
         return _loc7_;
      }
      
      public static function createScale9Image(param1:String, param2:int, param3:int, param4:Rectangle) : Scale9Image
      {
         if(param1 == "")
         {
            param1 = "UI_btn_normalFun_0000";
         }
         var _loc5_:Scale9Textures = new Scale9Textures(GlobalFunction.getTexture(param1),param4);
         var _loc6_:Scale9Image = new Scale9Image(_loc5_);
         if(param2 > 0 && param3 > 0)
         {
            _loc6_.width = param2;
            _loc6_.height = param3;
         }
         return _loc6_;
      }
      
      public static function setPivot(param1:DisplayObject, param2:Number = 0.5, param3:Number = 0.5) : void
      {
         param1.pivotX = param1.width * param2 / param1.scaleX;
         param1.pivotY = param1.height * param3 / param1.scaleY;
      }
      
      public static function createScale3Image(param1:String, param2:Number, param3:Number, param4:int) : Scale3Image
      {
         if(param1 == "")
         {
            param1 = "UI_btn_normalFun_0000";
         }
         var _loc5_:Scale3Textures = new Scale3Textures(GlobalFunction.getTexture(param1),param2,param3);
         var _loc6_:Scale3Image = new Scale3Image(_loc5_);
         if(param4 > 0)
         {
            _loc6_.width = param4;
         }
         return _loc6_;
      }
      
      public static function createTextField(param1:int, param2:int, param3:String, param4:String = "", param5:Number = 12, param6:uint = 0, param7:Boolean = false) : TextField
      {
         if(param4 == "")
         {
            param4 = GlobalConfig.FONT_0;
         }
         return new TextField(param1,param2,param3,param4,param5,param6,param7);
      }
      
      public static function createButton_5(param1:String, param2:String = "", param3:Boolean = true, param4:Boolean = false, param5:int = 25) : LOL_Button
      {
         var _loc6_:LOL_Button = new LOL_Button(param1,param2 == "" ? "UI_btn_enterGame_0_0000" : param2);
         _loc6_.style(GlobalConfig.FONT_0,param5,1118481);
         return _loc6_;
      }
      
      public static function createButton_normal(param1:String, param2:uint = 1513239, param3:int = 25) : LOL_Button
      {
         return createButtonStarling("UI_btn_normalFun_0000",{
            "t":param1,
            "fs":param3,
            "fc":param2
         });
      }
      
      public static function createButton_smallRed(param1:String, param2:uint = 16777215, param3:int = 25) : LOL_Button
      {
         return createButtonStarling("UI_btn_smallFun_1_0000",{
            "t":param1,
            "fs":param3,
            "fc":param2
         });
      }
      
      public static function getUI_BG_9SLICE_0() : Scale9Image
      {
         return new Scale9Image(new Scale9Textures(getTexture("UI_bg_9slice_0_0000"),new Rectangle(110,55,70,20)));
      }
      
      public static function createButtonStarling(param1:String = "", param2:Object = null, param3:Boolean = false) : LOL_Button
      {
         var _loc4_:LOL_Button = null;
         if(param2 != null)
         {
            _loc4_ = new LOL_Button(param2.t,param1,true);
            _loc4_.fontColor = param2.fc;
            _loc4_.fontSize = param2.fs;
         }
         else
         {
            _loc4_ = new LOL_Button("",param1,false);
         }
         return _loc4_;
      }
      
      public static function changeExpeditionArray(param1:String, param2:Boolean = false, param3:* = null, param4:Object = null) : void
      {
         var _loc5_:int = GlobalData.$tempExpeditionArr.indexOf(param1);
         if(param2)
         {
            if(_loc5_ > -1)
            {
               GlobalData.$tempExpeditionArr.splice(_loc5_,1);
               GlobalData.$tempExpeditionItem[param1] = null;
               GlobalData.$tempExpeditionElements[param1] = null;
               delete GlobalData.$tempExpeditionItem[param1];
               delete GlobalData.$tempExpeditionElements[param1];
            }
         }
         else
         {
            if(_loc5_ == -1)
            {
               GlobalData.$tempExpeditionArr.push(param1);
            }
            GlobalData.$tempExpeditionItem[param1] = param3;
            GlobalData.$tempExpeditionElements[param1] = param4;
         }
      }
      
      public static function clearExpeditionItems() : void
      {
         for each(var _loc1_ in GlobalData.$tempExpeditionItem)
         {
            if(_loc1_ != null)
            {
               if((_loc1_ as Object).hasOwnProperty("reData"))
               {
                  _loc1_.reData = false;
               }
            }
         }
         GlobalData.$tempExpeditionItem = null;
         GlobalData.$tempExpeditionItem = {};
         GlobalData.$tempExpeditionArr = [];
         GlobalData.$tempExpeditionElements = null;
         GlobalData.$tempExpeditionElements = {};
      }
      
      public static function clearMorphItems() : void
      {
         GlobalData.$tempMorphItem = null;
      }
      
      public static function changeSellArray(param1:String, param2:Boolean = false, param3:* = null, param4:Object = null) : void
      {
         var _loc5_:int = GlobalData.$tempSell.indexOf(param1);
         if(param2)
         {
            if(_loc5_ > -1)
            {
               GlobalData.$tempSell.splice(_loc5_,1);
               GlobalData.$tempSellItem[param1] = null;
               delete GlobalData.$tempSellItem[param1];
            }
         }
         else
         {
            if(_loc5_ == -1)
            {
               GlobalData.$tempSell.push(param1);
            }
            GlobalData.$tempSellItem[param1] = param3;
         }
      }
      
      public static function clearSellItems() : void
      {
         for each(var _loc1_ in GlobalData.$tempSellItem)
         {
            if(_loc1_ != null)
            {
               if((_loc1_ as Object).hasOwnProperty("reData"))
               {
                  _loc1_.reData = false;
               }
            }
         }
         GlobalData.$tempSellItem = null;
         GlobalData.$tempSellItem = {};
         GlobalData.$tempSell = [];
      }
      
      public static function changeAvatarBetterArray(param1:String, param2:Boolean = false, param3:* = null, param4:Object = null) : void
      {
         var _loc5_:int = GlobalData.$tempAvatarBetterArr.indexOf(param1);
         if(param2)
         {
            if(_loc5_ > -1)
            {
               GlobalData.$tempAvatarBetterArr.splice(_loc5_,1);
               GlobalData.$tempAvatarBetterItem[param1] = null;
               GlobalData.$tempBetterElements[param1] = null;
               delete GlobalData.$tempAvatarBetterItem[param1];
               delete GlobalData.$tempBetterElements[param1];
            }
         }
         else
         {
            if(_loc5_ == -1)
            {
               GlobalData.$tempAvatarBetterArr.push(param1);
            }
            GlobalData.$tempAvatarBetterItem[param1] = param3;
            GlobalData.$tempBetterElements[param1] = param4;
         }
      }
      
      public static function clearAvatarBetterItems() : void
      {
         for each(var _loc1_ in GlobalData.$tempAvatarBetterItem)
         {
            if(_loc1_ != null)
            {
               if((_loc1_ as Object).hasOwnProperty("reData"))
               {
                  _loc1_.reData = false;
               }
            }
         }
         GlobalData.$tempAvatarBetterItem = null;
         GlobalData.$tempAvatarBetterItem = {};
         GlobalData.$tempAvatarBetterArr = [];
         GlobalData.$tempBetterElements = null;
         GlobalData.$tempBetterElements = {};
      }
      
      public static function changeBookFoodArray(param1:String, param2:Boolean = false, param3:* = null, param4:Object = null) : void
      {
         var _loc5_:int = GlobalData.$tempFoodForBook.indexOf(param1);
         if(param2)
         {
            if(_loc5_ > -1)
            {
               GlobalData.$tempFoodForBook.splice(_loc5_,1);
               GlobalData.$tempObjectFoodForBook[param1] = null;
               delete GlobalData.$tempObjectFoodForBook[param1];
            }
         }
         else
         {
            if(_loc5_ == -1)
            {
               GlobalData.$tempFoodForBook.push(param1);
            }
            GlobalData.$tempObjectFoodForBook[param1] = param3;
         }
      }
      
      public static function clearBookFood() : void
      {
         for each(var _loc1_ in GlobalData.$tempObjectFoodForBook)
         {
            if(_loc1_ != null)
            {
               if((_loc1_ as Object).hasOwnProperty("reData"))
               {
                  _loc1_.reData = false;
               }
            }
         }
         GlobalData.$tempFoodForBook = null;
         GlobalData.$tempFoodForBook = [];
         GlobalData.$tempObjectFoodForBook = null;
         GlobalData.$tempObjectFoodForBook = {};
      }
      
      public static function changeEquipSellArray(param1:String, param2:Boolean = false, param3:* = null, param4:Object = null) : void
      {
         var _loc5_:int = GlobalData.$tempEquipSellArr.indexOf(param1);
         if(param2)
         {
            if(_loc5_ > -1)
            {
               GlobalData.$tempEquipSellArr.splice(_loc5_,1);
               GlobalData.$tempEquipSellItem[param1] = null;
               delete GlobalData.$tempEquipSellItem[param1];
            }
         }
         else
         {
            if(_loc5_ == -1)
            {
               GlobalData.$tempEquipSellArr.push(param1);
            }
            GlobalData.$tempEquipSellItem[param1] = param3;
         }
      }
      
      public static function clearEquipSell() : void
      {
         for each(var _loc1_ in GlobalData.$tempEquipSellItem)
         {
            if(_loc1_ != null)
            {
               if((_loc1_ as Object).hasOwnProperty("reData"))
               {
                  _loc1_.reData = false;
               }
            }
         }
         GlobalData.$tempEquipSellArr = null;
         GlobalData.$tempEquipSellArr = [];
         GlobalData.$tempEquipSellItem = null;
         GlobalData.$tempEquipSellItem = {};
      }
      
      public static function checkIsSympSame(param1:String, param2:int, param3:int, param4:Array = null, param5:Object = null) : Boolean
      {
         var _loc10_:Object = null;
         var _loc8_:Array = param4 == null ? GlobalData.$userData.as_equips[param3] : param4;
         var _loc9_:Object = param5 == null ? GlobalData.$userData.my_equips : param5;
         var _loc11_:int = 0;
         var _loc7_:int = int(_loc8_.length);
         var _loc6_:Boolean = false;
         _loc11_ = 0;
         while(_loc11_ < _loc7_)
         {
            if(_loc8_[_loc11_] != null && _loc8_[_loc11_] != param1)
            {
               _loc10_ = _loc9_[_loc8_[_loc11_]];
               if(_loc10_.symp != null)
               {
                  if(_loc10_.symp == param2)
                  {
                     _loc6_ = true;
                     break;
                  }
               }
            }
            _loc11_++;
         }
         return _loc6_;
      }
      
      public static function checkIsSympSameCount(param1:String, param2:int, param3:int, param4:Array = null, param5:Object = null) : int
      {
         var _loc10_:Object = null;
         var _loc8_:Array = param4 == null ? GlobalData.$userData.as_equips[param3] : param4;
         var _loc9_:Object = param5 == null ? GlobalData.$userData.my_equips : param5;
         var _loc11_:int = 0;
         var _loc7_:int = int(_loc8_.length);
         var _loc6_:int = 0;
         _loc11_ = 0;
         while(_loc11_ < _loc7_)
         {
            if(_loc8_[_loc11_] != null)
            {
               _loc10_ = _loc9_[_loc8_[_loc11_]];
               if(_loc10_.symp != null)
               {
                  if(_loc10_.symp == param2)
                  {
                     _loc6_++;
                  }
               }
            }
            _loc11_++;
         }
         return _loc6_;
      }
      
      public static function changeLock(param1:String, param2:Boolean) : void
      {
         var _loc3_:Array = param1.split("|");
         if(_loc3_ == null)
         {
            return;
         }
         if(param2)
         {
            GlobalData.$tempAvatarLock[_loc3_[1]] = _loc3_[1];
         }
         else
         {
            GlobalData.$tempAvatarLock[_loc3_[1]] = null;
            delete GlobalData.$tempAvatarLock[_loc3_[1]];
         }
         GlobalData.$localUser["avatarLock"] = GlobalData.$tempAvatarLock;
         GlobalLocalStore.setCurrUserData(SendAndSelect.$uid + "_" + GlobalData.$mServiceID,GlobalData.$localUser);
      }
      
      public static function checkLock(param1:String) : Boolean
      {
         var _loc2_:Array = param1.split("|");
         return GlobalData.$tempAvatarLock[_loc2_[1]] == null ? false : true;
      }
      
      public static function checkCombatWinAndLose(param1:Object) : Object
      {
         var _loc8_:int = 0;
         var _loc6_:String = "";
         var _loc4_:String = "";
         var _loc3_:Array = param1.win as Array;
         var _loc5_:int = -1;
         var _loc2_:int = -1;
         var _loc7_:Array = null;
         _loc8_ = 0;
         while(_loc8_ < _loc3_.length)
         {
            _loc5_ = int(_loc3_[_loc8_]);
            _loc7_ = GlobalData.$mConfig_simple.win[_loc5_];
            if(!_loc7_)
            {
               return {
                  "win":"",
                  "lose":""
               };
            }
            _loc6_ += _loc8_ + 1 + "." + _loc7_[0];
            if(_loc2_ != int(_loc7_[1]))
            {
               _loc2_ = int(_loc7_[1]);
               _loc4_ += _loc8_ + 1 + "." + GlobalData.$mConfig_simple.lose[_loc2_][0];
            }
            _loc8_++;
         }
         return {
            "win":_loc6_,
            "lose":_loc4_
         };
      }
      
      public static function getAvatarEXP(param1:Object) : Object
      {
         var _loc8_:Array = GlobalData.$mConfig_simple.avatar_exp as Array;
         var _loc6_:String = param1.id;
         var _loc3_:Object = getAvatarCfg(_loc6_);
         var _loc11_:Number = Number(param1.lv);
         var _loc10_:Number = Number(_loc8_[0]);
         var _loc5_:Number = Number(_loc8_[1]);
         var _loc7_:Number = Number(_loc8_[2]);
         var _loc4_:Number = Number(_loc3_["tl"][5]);
         var _loc2_:Number = Math.floor(_loc4_ * (_loc10_ * _loc11_ * _loc11_ + _loc5_ * _loc11_ + _loc7_));
         var _loc9_:Number = Math.floor(_loc4_ * (_loc10_ / 3 * _loc11_ * _loc11_ * _loc11_ + (_loc5_ - _loc10_) / 2 * _loc11_ * _loc11_ + (_loc10_ / 6 - _loc5_ / 2 + _loc7_) * _loc11_ - _loc7_));
         return {
            "exp":_loc9_,
            "next":_loc2_
         };
      }
      
      public static function getAvatarCfg(param1:String) : Object
      {
         var _loc3_:String = param1.split("|")[0];
         return GlobalData.$mConfig_avatar[_loc3_];
      }
      
      public static function getBetterGive(param1:Object = null, param2:Object = null) : Object
      {
         var _loc10_:Object = null;
         var _loc7_:Number = 0;
         var _loc8_:Number = 0;
         var _loc6_:Number = Number(param1 ? param1.hp : 0);
         var _loc4_:Number = Number(param1 ? param1.ap : 0);
         var _loc3_:Number = Number(param1 ? param1.de_ma : 0);
         var _loc9_:Number = Number(param1 ? param1.de_ph : 0);
         var _loc5_:Number = 0;
         var _loc12_:Object = param2 ? param2 : GlobalData.$tempBetterElements;
         for(var _loc11_:Object in _loc12_)
         {
            _loc10_ = _loc12_[_loc11_];
            _loc7_ += _loc10_["give"]["exp"];
            _loc8_ += _loc10_["give"]["gold"];
            _loc6_ += _loc10_.hp;
            _loc4_ += _loc10_.ap;
            _loc3_ += _loc10_.de_ma;
            _loc9_ += _loc10_.de_ph;
         }
         return {
            "exp":_loc7_,
            "gold":_loc8_,
            "hp":_loc6_,
            "ap":_loc4_,
            "ma":_loc3_,
            "ph":_loc9_
         };
      }
      
      public static function getSkillProbability(param1:Object) : Number
      {
         var _loc8_:Object = null;
         var _loc2_:Avatar = new Avatar(param1.id,param1);
         var _loc4_:Number = 0;
         var _loc5_:String = _loc2_.skill0 ? _loc2_.skill0.skillSetData.id : "";
         if(_loc5_ == "")
         {
            _loc2_.clear();
            _loc2_ = null;
            return _loc4_;
         }
         var _loc6_:Number = _loc2_.getSkillProMother();
         var _loc3_:Array = GlobalData.$mConfig_simple.slv_config as Array;
         _loc2_.clear();
         _loc2_ = null;
         var _loc10_:Object = GlobalData.$tempBetterElements;
         var _loc7_:Number = 0;
         for(var _loc9_:Object in _loc10_)
         {
            _loc8_ = _loc10_[_loc9_];
            _loc2_ = new Avatar(_loc8_.id,_loc8_);
            if(_loc2_.avatarData.skillExp > 0)
            {
               _loc7_ += _loc2_.avatarData.skillExp;
            }
            else if(_loc2_.skill0)
            {
               if(_loc2_.skill0.skillSetData.id == _loc5_)
               {
                  _loc7_ += _loc2_.getSkillPro();
               }
            }
            _loc2_.clear();
            _loc2_ = null;
         }
         _loc4_ = _loc6_ <= 0 ? 0 : Math.floor(_loc7_ * _loc3_[1] / _loc6_ * 100);
         if(_loc4_ > 100)
         {
            _loc4_ = 100;
         }
         return isNaN(_loc4_) ? 0 : _loc4_;
      }
      
      public static function formateBetterItemsError(param1:Array = null, param2:Boolean = true) : Object
      {
         var _loc11_:String = null;
         var _loc9_:String = null;
         var _loc12_:int = 0;
         var _loc3_:Avatar = null;
         var _loc8_:int = 0;
         var _loc10_:int = 0;
         var _loc6_:int = 0;
         var _loc5_:Boolean = false;
         var _loc7_:Array = param1 == null ? GlobalData.$tempSell : param1;
         var _loc4_:int = int(GlobalData.$mConfig_simple.star_swallow_tips);
         _loc12_ = 0;
         while(_loc12_ < _loc7_.length)
         {
            _loc3_ = new Avatar(_loc7_[_loc12_]);
            if(_loc3_.getStar() >= _loc4_ && param2)
            {
               if(_loc3_.getType() == 1)
               {
                  if(_loc3_.morph >= _loc6_)
                  {
                     if(_loc3_.getStar() >= _loc10_)
                     {
                        _loc11_ = _loc3_.avatarData.name;
                        _loc9_ = _loc3_.resId;
                        _loc10_ = Math.max(_loc10_,_loc3_.getStar());
                        _loc6_ = Math.max(_loc6_,_loc3_.morph);
                     }
                  }
               }
               else
               {
                  _loc8_ = Math.max(_loc8_,_loc3_.getStar());
               }
            }
            if(!param2 && _loc3_.getPithNum() > 0)
            {
               _loc5_ = true;
               break;
            }
            _loc3_.clear();
            _loc3_ = null;
            _loc12_++;
         }
         if(_loc11_)
         {
            return {
               "s":_loc10_,
               "p":_loc5_,
               "name":_loc11_,
               "aid":_loc9_
            };
         }
         return {
            "s":_loc8_,
            "p":_loc5_
         };
      }
      
      public static function changeUserDataAvatars(param1:String, param2:Object = null, param3:Boolean = false) : void
      {
         if(param2 == null)
         {
            delete GlobalData.$userData.avatars[param1];
            GlobalData.$userData_avatarNum -= 1;
            return;
         }
         GlobalData.$userData.avatars[param1] = param2;
         if(param3)
         {
            GlobalData.$userData_avatarNum += 1;
         }
      }
      
      public static function ChangeUserTeamOne(param1:String, param2:String) : void
      {
         var _loc4_:int = 0;
         var _loc3_:Array = GlobalData.$userData.team[0];
         _loc4_ = 0;
         while(_loc4_ < _loc3_.length)
         {
            if(_loc3_[_loc4_] == param1)
            {
               _loc3_[_loc4_] = param2;
               GlobalData.$userData.team[0] = _loc3_;
               GlobalData.$tempTeam = _loc3_;
               break;
            }
            _loc4_++;
         }
      }
      
      public static function changeStarUpDnTeam(param1:String, param2:String) : void
      {
         var _loc3_:Object = GlobalData.$userData.attrs.dn;
         for(var _loc4_:String in _loc3_)
         {
            if(_loc3_[_loc4_][1] == param1)
            {
               _loc3_[_loc4_][1] = param2;
               break;
            }
         }
      }
      
      public static function getPhaseUpItems(param1:Object) : Array
      {
         var _loc8_:Object = null;
         var _loc2_:Avatar = null;
         var _loc5_:Array = [];
         var _loc4_:String = "";
         var _loc6_:Boolean = false;
         var _loc3_:Boolean = false;
         for(var _loc7_:Object in GlobalData.$userData.avatars)
         {
            _loc8_ = GlobalData.$userData.avatars[_loc7_];
            if(!_loc8_.phase)
            {
               _loc8_.phase = 0;
            }
            if(!param1.phase)
            {
               param1.phase = 0;
            }
            _loc4_ = _loc7_.toString();
            _loc8_["id"] = _loc4_;
            _loc6_ = checkIsTeamMember(_loc4_) || checkIsActiveExplorationMember(_loc4_);
            _loc3_ = PanelCenterDNTeam.checkIsInDn(_loc4_) != null;
            if(_loc4_ != param1.id && !_loc6_ && !_loc3_ && !checkLock(_loc4_) )
            {
               _loc2_ = new Avatar(_loc4_);
               if(_loc2_.morph == 0)
               {
                  _loc8_["pithNum"] = getPithNum(_loc8_);
                  _loc5_.push(_loc8_);
               }
            }
         }
         _loc5_.sortOn(["lv","slv","pithNum"],[16,16,16]);
         return _loc5_;
      }
      
      public static function getStarUpItems(param1:Object) : Array
      {
         var _loc7_:Object = null;
         var _loc4_:Array = [];
         var _loc3_:String = "";
         var _loc5_:Boolean = false;
         var _loc2_:Boolean = false;
         for(var _loc6_:Object in GlobalData.$userData.avatars)
         {
            _loc7_ = GlobalData.$userData.avatars[_loc6_];
            _loc3_ = _loc6_.toString();
            _loc7_["id"] = _loc3_;
            _loc5_ = checkIsTeamMember(_loc3_) || checkIsActiveExplorationMember(_loc3_);
            _loc2_ = PanelCenterDNTeam.checkIsInDn(_loc3_) != null;
            if(_loc3_ != param1.id && !_loc5_ && !_loc2_ && !checkLock(_loc3_))
            {
               _loc7_["pithNum"] = getPithNum(_loc7_);
               _loc4_.push(_loc7_);
            }
         }
         _loc4_.sortOn(["pithNum","lv"],[16,16]);
         return _loc4_;
      }
      
      public static function getStarUpId(param1:String, param2:int = 1) : String
      {
         var _loc5_:Array = param1.split("|");
         var _loc3_:String = _loc5_[1];
         var _loc4_:Array = String(_loc5_[0]).split("_");
         var _loc6_:int = int(_loc4_[2]) + param2;
         return _loc4_[0] + "_" + _loc4_[1] + "_" + _loc6_ + "|" + _loc3_;
      }
      
      public static function isNullNextStarCfgId(param1:String) : Boolean
      {
         var _loc4_:Array = param1.split("|");
         var _loc2_:String = _loc4_[1];
         var _loc3_:Array = String(_loc4_[0]).split("_");
         var _loc5_:int = int(_loc3_[2]) + 1;
         var _loc6_:String = _loc3_[0] + "_" + _loc3_[1] + "_" + _loc5_;
         return GlobalData.$mConfig_avatar[_loc6_] == null;
      }
      
      public static function getPithNum(param1:Object) : int
      {
         var _loc2_:int = 0;
         _loc2_ += param1.hp;
         _loc2_ += param1.ap;
         _loc2_ += param1.de_ph;
         return int(_loc2_ + param1.de_ma);
      }
      
      public static function formateUserDataToFriend(param1:Object) : Object
      {
         var _loc3_:Object = {
            "uid":param1.uid,
            "name":param1.name,
            "lv":param1.lv,
            "vip_lv":param1.vip_lv
         };
         var _loc2_:String = param1.team[param1.attrs.team_num][0];
         _loc3_["avatar"] = param1.avatars[_loc2_];
         _loc3_["avatar"]["aid"] = _loc2_;
         return _loc3_;
      }
      
      public static function changeFriendRequestList(param1:String, param2:Boolean = false) : void
      {
         var _loc5_:* = 0;
         var _loc3_:Object = null;
         var _loc4_:Array = GlobalData.$tempFriendRequest;
         _loc5_ = 0;
         while(_loc5_ < _loc4_.length)
         {
            _loc3_ = _loc4_[_loc5_];
            if(_loc3_.uid == param1)
            {
               _loc4_.splice(_loc5_,1);
               GlobalData.$tempFriendRequest = _loc4_;
               break;
            }
            _loc5_++;
         }
      }
      
      public static function changeFriendList(param1:String, param2:Boolean = true, param3:Object = null) : void
      {
         var _loc4_:Object = null;
         var _loc5_:* = 0;
         if(param2 && param3)
         {
            GlobalData.$tempFriend.push(param3);
         }
         else
         {
            _loc4_ = null;
            _loc5_ = 0;
            while(_loc5_ < GlobalData.$tempFriend.length)
            {
               _loc4_ = GlobalData.$tempFriend[_loc5_];
               if(_loc4_.uid == param1)
               {
                  GlobalData.$tempFriend.splice(_loc5_,1);
                  break;
               }
               _loc5_++;
            }
         }
      }
      
      public static function searchFriendList(param1:String) : Object
      {
         var _loc4_:* = 0;
         var _loc2_:Object = null;
         var _loc3_:Object = null;
         _loc4_ = 0;
         while(_loc4_ < GlobalData.$tempFriend.length)
         {
            _loc3_ = GlobalData.$tempFriend[_loc4_];
            if(_loc3_.uid == param1)
            {
               _loc2_ = _loc3_["avatar"];
               break;
            }
            _loc4_++;
         }
         return _loc2_;
      }
      
      public static function get radioPanel() : PanelRollInfo
      {
         if(GlobalData.$mGameClassObject)
         {
            if(GlobalData.$mGameClassObject.mLayoutUICenter)
            {
               return GlobalData.$mGameClassObject.mLayoutUICenter.mPanelCenterMain.getRoll;
            }
         }
         return null;
      }
      
      public static function resetRollInfo() : void
      {
         var _loc1_:int = 0;
         ROLL_LIST = [];
         _loc1_ = 46000;
         while(_loc1_ < 46099)
         {
            if(GlobalLanguageStr.getLanguageStr(_loc1_) == "")
            {
               break;
            }
            ROLL_LIST.push(GlobalLanguageStr.getLanguageStr(_loc1_));
            _loc1_++;
         }
         Tools.randomArray(ROLL_LIST);
      }
      
      public static function checkIsSale(param1:String) : Boolean
      {
         var _loc2_:int = 0;
         if(param1 == "center_shop_energy")
         {
            _loc2_ = int(GlobalData.$mConfig_simple.energy_config[8]);
         }
         else if(param1 == "center_shop_avatar")
         {
            _loc2_ = int(GlobalData.$mConfig_simple.avatar_len[4]);
         }
         else if(param1 == "center_shop_friend")
         {
            _loc2_ = int(GlobalData.$mConfig_simple.friend_len[4]);
         }
         else if(param1 == "center_shop_pvp")
         {
            _loc2_ = int(GlobalData.$mConfig_simple.capacity_config[7]);
         }
         else if(param1 == "center_casino")
         {
            _loc2_ = int(GlobalData.$mConfig_simple.wager_avatar[10]);
         }
         else if(param1 == "equip_fun_wash")
         {
            _loc2_ = int(GlobalData.$mConfig_simple.equip_config[12]);
         }
         else if(param1 == "center_shop_coin")
         {
            _loc2_ = -1;
         }
         else if(param1 == "center_boss")
         {
            _loc2_ = int(GlobalData.$mConfig_simple.zone_boss.relive_coin[2]);
         }
         return _loc2_ > -1;
      }
      
      public static function getSellAvatarGold() : Number
      {
         var _loc2_:String = null;
         var _loc1_:Object = null;
         var _loc4_:* = 0;
         var _loc3_:Number = 0;
         _loc4_ = 0;
         while(_loc4_ < GlobalData.$tempSell.length)
         {
            _loc2_ = GlobalData.$tempSell[_loc4_];
            _loc2_ = _loc2_.split("|")[0];
            _loc1_ = GlobalData.$mConfig_avatar[_loc2_];
            _loc3_ += _loc1_["tl"][7];
            _loc4_++;
         }
         return _loc3_;
      }
      
      public static function getEquipUI(param1:String) : Image
      {
         var _loc3_:Texture = getTexture(param1 + "0000");
         var _loc2_:Image = new Image(_loc3_);
         var _loc4_:Rectangle = _loc3_.frame;
         if(_loc4_ == null)
         {
            _loc4_ = new Rectangle(0,0,_loc3_.width,_loc3_.height);
         }
         _loc2_.width = _loc4_.width;
         _loc2_.height = _loc4_.height;
         return _loc2_;
      }
      
      public static function getSympUI(param1:int = 0, param2:Boolean = true) : Image
      {
         var _loc3_:Image = createImage("UI_magic_icon_000" + param1);
         _loc3_.pivotX = int(_loc3_.width * 0.5 - 18);
         _loc3_.pivotY = int(_loc3_.height * 0.5 + 12);
         _loc3_.touchable = false;
         if(!param2)
         {
            _loc3_.scaleX = _loc3_.scaleY = 0.35;
         }
         return _loc3_;
      }
      
      public static function delTextureByLoading(param1:*, param2:Boolean = false) : void
      {
         var _loc3_:int = 0;
         if(param2)
         {
            GlobalData.$assetManager.purgeQueue();
         }
         if(param1 is Array)
         {
            if(param1 != null)
            {
               _loc3_ = 0;
               while(_loc3_ < param1.length)
               {
                  GlobalData.$assetManager.removeTexture(param1[_loc3_]);
                  _loc3_++;
               }
            }
         }
         else if(param1 is String)
         {
            GlobalData.$assetManager.removeTexture(param1);
         }
      }
      
      public static function getTextureByBD(param1:String) : Texture
      {
         var _loc3_:Object = null;
         var _loc2_:BitmapData = null;
         var _loc4_:Texture = GlobalData.$assetManager.getTexture(param1);
         if(_loc4_ == null)
         {
            try
            {
               _loc3_ = getDefinitionByName(param1);
               if(_loc3_ != null)
               {
                  _loc2_ = new (_loc3_ as Class)() as BitmapData;
                  if(_loc2_ != null)
                  {
                     _loc4_ = Texture.fromBitmapData(_loc2_,false,true);
                     if(_loc2_ != null)
                     {
                        _loc2_.dispose();
                        _loc2_ = null;
                     }
                     GlobalData.$assetManager.addTexture(param1,_loc4_);
                  }
               }
            }
            catch(_error:Error)
            {
               _loc4_ = null;
            }
         }
         if(_loc4_ == null)
         {
            _loc4_ = GlobalData.$assetManager.getTexture(TEXTURE_DEFAULT);
         }
         return _loc4_;
      }
      
      public static function getBitmapByBD(param1:String) : Bitmap
      {
         var _loc2_:Bitmap = null;
         var _loc3_:Class = getDefinitionByName(param1) as Class;
         if(_loc3_ != null)
         {
            _loc2_ = new Bitmap(new _loc3_() as BitmapData);
            if(_loc2_ != null)
            {
               return _loc2_;
            }
         }
         if(_loc2_ == null)
         {
            _loc2_ = new Bitmap(new BitmapData(50,20,false,16711680));
         }
         return _loc2_;
      }
      
      public static function delTextureByBD(param1:String) : void
      {
         GlobalData.$assetManager.removeTexture(param1);
      }
      
      public static function getTexture(param1:String, param2:Object = null) : Texture
      {
         var _loc7_:String = null;
         var _loc6_:Object = null;
         var _loc5_:Class = null;
         var _loc11_:flash.display.Sprite = null;
         var _loc9_:BitmapData = null;
         var _loc3_:String = null;
         var _loc10_:MovieClip = null;
         var _loc8_:int = 0;
         var _loc12_:Texture = GlobalData.$assetManager.getTexture(param1);
         var _loc4_:int = 0;
         if(param1.indexOf("_$icon") > -1)
         {
            _loc7_ = param1.split("_$icon")[0];
            _loc4_ = 1;
         }
         else if(param1.indexOf("_$circle") > -1)
         {
            _loc7_ = param1.split("_$circle")[0];
            _loc4_ = 2;
         }
         else
         {
            _loc7_ = param1;
            _loc4_ = 3;
         }
         if(_loc12_ == null)
         {
            try
            {
               _loc6_ = getDefinitionByName(_loc7_);
               if(_loc6_ != null)
               {
                  _loc5_ = _loc6_ as Class;
                  _loc11_ = new _loc5_() as flash.display.Sprite;
                  if(param2)
                  {
                     _loc9_ = Tools.formatBitmapDataScale(_loc11_,param2);
                     if(_loc4_ == 2)
                     {
                        _loc9_ = Tools.formatBitmapCircle(_loc9_);
                     }
                     _loc12_ = Texture.fromBitmapData(_loc9_,false,true);
                     if(_loc4_ == 2)
                     {
                        GlobalData.$assetManager.addTexture(_loc7_ + "_$circle",_loc12_);
                     }
                     else
                     {
                        GlobalData.$assetManager.addTexture(_loc7_ + "_$icon",_loc12_);
                     }
                  }
                  else
                  {
                     $getTextureList.push(_loc7_);
                     if($getTextureList.length > 10)
                     {
                        _loc3_ = $getTextureList.shift();
                        GlobalData.$assetManager.removeTexture(_loc3_);
                     }
                     if(_loc11_.getChildByName("special_avatar"))
                     {
                        _loc10_ = _loc11_.getChildByName("special_avatar") as MovieClip;
                        _loc9_ = Tools.getBitmapData(_loc11_,1,new Rectangle(0,0,_loc10_.width,_loc10_.height));
                     }
                     else
                     {
                        _loc9_ = Tools.getBitmapData(_loc11_);
                     }
                     _loc12_ = Texture.fromBitmapData(_loc9_,false,true);
                     GlobalData.$assetManager.addTexture(_loc7_,_loc12_);
                  }
                  _loc9_.dispose();
                  _loc9_ = null;
               }
               else
               {
                  _loc12_ = GlobalData.$assetManager.getTexture(TEXTURE_DEFAULT);
               }
            }
            catch(_error:Error)
            {
               _loc12_ = GlobalData.$assetManager.getTexture(TEXTURE_DEFAULT);
            }
         }
         else if(_loc4_ == 3)
         {
            _loc8_ = $getTextureList.indexOf(_loc7_);
            if(_loc8_ >= 0)
            {
               $getTextureList.splice(_loc8_,1);
               $getTextureList.push(_loc7_);
            }
         }
         return _loc12_;
      }
      
      public static function popTips(param1:String, param2:String, param3:Object = null, param4:Boolean = false) : void
      {
         GlobalData.$mGameClassObject.openPopUp(new PanelPop(param1,param2,param3));
      }
      
      public static function popAlert(param1:String, param2:String, param3:Object = null, param4:Boolean = true, param5:Function = null, param6:Boolean = false, param7:Boolean = false) : void
      {
         if(!param6)
         {
            GlobalData.$mGameClassObject.closePopUp();
         }
         if(param2.indexOf("<") == -1)
         {
            param2 = Tools.formatLineX(param2);
         }
         param2 = Tools.formatHtmlTextBr([param2],param4 ? "center" : "left");
         GlobalData.$mGameClassObject.openPopUp(new PanelPop(param1,param2,param3,370,param7));
      }
      
      public static function popFunctionOpenAlert(param1:String, param2:Array, param3:Object = null, param4:Boolean = true, param5:Function = null) : void
      {
         GlobalData.$mGameClassObject.closePopUp();
         GlobalData.$mGameClassObject.openPopUp(new PanelFunctionOpenInfo(param1,param2,param3));
      }
      
      public static function popInforAlert(param1:String, param2:String, param3:Object = null, param4:Boolean = false, param5:String = null) : void
      {
         GlobalData.$mGameClassObject.closePopUp();
         var _loc6_:PanelInforPop = new PanelInforPop(param1,param4 ? Tools.formatHtmlTextBr([param2],"center") : param2,600,630);
         if(param5 == "status_boss")
         {
            _loc6_.set_Status = true;
         }
         GlobalData.$mGameClassObject.openPopUp(_loc6_);
      }
      
      public static function popPanelHelp(param1:String = null) : void
      {
         var _loc2_:int = 0;
         if(!param1)
         {
            param1 = MainConfig.SERVER_ADDRESS_NOTICE;
         }
         if(param1 == MainConfig.SERVER_ADDRESS_NOTICE)
         {
            _loc2_ = 20100;
         }
         else if(param1 == MainConfig.SERVER_ADDRESS_HELP_HELP)
         {
            _loc2_ = 20103;
         }
         else if(param1 == MainConfig.SERVER_ADDRESS_HELP_EXTREME)
         {
            _loc2_ = 90252;
         }
         else if(param1 == MainConfig.SERVER_ADDRESS_HELP_ADD_MAGIC)
         {
            _loc2_ = 90203;
         }
         else if(param1 == MainConfig.SERVER_ADDRESS_HELP_ADD_RISE)
         {
            _loc2_ = 90517;
         }
         else if(param1 == MainConfig.SERVER_ADDRESS_HELP_ADD_WASH)
         {
            _loc2_ = 90518;
         }
         else if(param1 == MainConfig.SERVER_ADDRESS_HELP_ADD_BOOK)
         {
            _loc2_ = 90519;
         }
         else if(param1 == MainConfig.SERVER_ADDRESS_HELP_ZONE_BOSS)
         {
            _loc2_ = 20356;
         }
         else if(param1 == MainConfig.SERVER_ADDRESS_HELP_DN)
         {
            _loc2_ = 25032;
         }
         else if(param1 == MainConfig.SERVER_ADDRESS_HELR_AVATAR_CULTURE)
         {
            _loc2_ = 90643;
         }
         else if(param1 == MainConfig.SERVER_ADDRESS_HELP_MYSTERY_SHOP)
         {
            _loc2_ = 97517;
         }
         else if(param1 == MainConfig.SERVER_ADDRESS_HELP_EXPLORATION)
         {
            _loc2_ = 90649;
         }
         else if(param1 == MainConfig.SERVER_ADDRESS_HELP_ADD_WELFARE)
         {
            _loc2_ = 90467;
         }
         else if(param1 == MainConfig.SERVER_ADDRESS_EVERYDAYSIGN)
         {
            _loc2_ = 90684;
         }
         else if(param1 == MainConfig.SERVER_ADDRESS_ALCHEMT)
         {
            _loc2_ = 90702;
         }
         else if(param1 == MainConfig.SERVER_ADDRESS_PVP)
         {
            _loc2_ = 90712;
         }
         else if(param1 == MainConfig.SERVER_ADDRESS_HELP_GUILD_EXPLAIN)
         {
            _loc2_ = 97850;
         }
         else if(param1 == MainConfig.SERVER_ADDRESS_HELP_GUILD_BATTLE)
         {
            _loc2_ = 97851;
         }
         else if(param1 == MainConfig.SERVER_ADDRESS_HELP_GUILD_SHOP)
         {
            _loc2_ = 97852;
         }
         else if(param1 == MainConfig.SERVER_ADDRESS_HELP_GUILD_BOSS)
         {
            _loc2_ = 97853;
         }
         else if(param1 == MainConfig.SERVER_ADDRESS_HELP_GUILD_RESEARCH)
         {
            _loc2_ = 90752;
         }
         else if(param1 == MainConfig.SERVER_ADDRESS_HELP_GUILD_STUDY)
         {
            _loc2_ = 90759;
         }
         else if(param1 == MainConfig.SERVER_ADDRESS_HELP_PVP15)
         {
            _loc2_ = 98035;
         }
         else if(param1 == MainConfig.SERVER_ADDRESS_HELP_TALENT)
         {
            _loc2_ = 98007;
         }
         GlobalData.$mGameClassObject.openPopUp(new PanelHelpNotice(param1,GlobalLanguageStr.getLanguageStr(_loc2_)));
      }
      
      public static function popPanelBet() : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_popbet",false,true);
      }
      
      public static function popPanelFlower() : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_flower",false,true);
      }
      
      public static function functionNull() : void
      {
         var _loc1_:int = 0;
      }
      
      public static function popAward(param1:String, param2:String, param3:* = null, param4:Boolean = true, param5:String = null, param6:Boolean = false, param7:Object = null, param8:Object = null) : void
      {
         GlobalData.$mGameClassObject.openPopUp(new PanelAwardTips(param1,param2,param3,param4,param5,param6,param7,param8));
      }
      
      public static function checkName(param1:String) : String
      {
         var _loc2_:RegExp = null;
         var _loc3_:String = null;
         if(!param1 || param1.length == 0)
         {
            return GlobalLanguageStr.getLanguageStr(90011);
         }
         if(Tools.hasText(param1,Tools.BAN_LIST.concat(Tools.BAN_LIST2)))
         {
            return GlobalLanguageStr.getLanguageStr(90122);
         }
         if(param1.length < 2 || Tools.getCharLength(param1) > 16)
         {
            return GlobalLanguageStr.getLanguageStr(10012);
         }
         _loc2_ = /^\S+$/;
         if(_loc2_.test(param1) == false)
         {
            if(!MainConfig.$isEnglish)
            {
               return GlobalLanguageStr.getLanguageStr(90123);
            }
            if(MainConfig.$isEA)
            {
               return GlobalLanguageStr.getLanguageStr(90123);
            }
         }
         return _loc3_;
      }
      
      public static function checkNullString(param1:String) : Boolean
      {
         var _loc2_:String = null;
         _loc2_ = " 　\n\t\r";
         var _loc5_:int = 0;
         var _loc3_:String = null;
         var _loc4_:Boolean = true;
         if(!param1 || param1.length == 0)
         {
            return _loc4_;
         }
         _loc5_ = 0;
         while(_loc5_ < param1.length)
         {
            _loc3_ = param1.charAt(_loc5_);
            if(" 　\n\t\r".indexOf(_loc3_) == -1)
            {
               return false;
            }
            _loc5_++;
         }
         return _loc4_;
      }
      
      public static function getEnergy() : Object
      {
         var _loc2_:int = 0;
         var _loc9_:Array = GlobalData.$mConfig_simple.energy_config as Array;
         var _loc10_:Number = Number(_loc9_[0]);
         var _loc5_:Number = Number(_loc9_[1]);
         var _loc8_:Number = Number(_loc9_[2]);
         var _loc3_:Number = Number(_loc9_[3]);
         var _loc4_:Number = Number(_loc9_[4]);
         if(GlobalData.$userData.vip_lv > 0)
         {
            _loc2_ = int(GlobalFunction.getVipObj().energy_limit_add);
         }
         else
         {
            _loc2_ = 0;
         }
         var _loc1_:int = _loc10_ + Math.floor(GlobalData.$userData.lv * _loc5_) + _loc2_;
         _loc1_ = int(_loc1_ > _loc3_ ? _loc3_ : _loc1_);
         var _loc7_:Number = SendAndSelect.$systemTimer_nowSecond - _loc1_ * _loc8_ * 60;
         var _loc6_:Number = (GlobalData.$userData.energy as Date).time * 0.001;
         var _loc12_:Number = SendAndSelect.$systemTimer_nowSecond - _loc6_;
         var _loc11_:Number = Math.floor(Math.max(_loc12_,0) / (_loc8_ * 60));
         _loc11_ = _loc11_ >= _loc1_ ? _loc1_ + int(GlobalData.$userData.attrs.energy_extra) : _loc11_;
         return {
            "energy":_loc11_,
            "max":_loc1_,
            "sec":_loc6_ - _loc7_,
            "maxExtra":_loc1_ * 2
         };
      }
      
      public static function getFragmentPower() : Object
      {
         var _loc2_:Array = GlobalData.$mConfig_simple.capacity_config as Array;
         var _loc1_:int = int(_loc2_[0]);
         var _loc6_:Number = Number(_loc2_[1]);
         var _loc5_:Object = GlobalData.$userData.attrs;
         var _loc4_:Number = SendAndSelect.$systemTimer_nowSecond - _loc1_ * _loc6_ * 60;
         var _loc3_:Number = (GlobalData.$userData.attrs.fragment_energy as Date).time * 0.001;
         var _loc8_:Number = SendAndSelect.$systemTimer_nowSecond - _loc3_;
         var _loc7_:Number = Math.floor(Math.max(_loc8_,0) / (_loc6_ * 60));
         _loc7_ = _loc7_ >= _loc1_ ? _loc1_ + int(GlobalData.$userData.attrs.fragment_energy_extra) : _loc7_;
         return {
            "energy":_loc7_,
            "max":_loc1_,
            "sec":_loc3_ - _loc4_,
            "maxExtra":_loc1_ * 2
         };
      }
      
      public static function setDetaiEquip(param1:*) : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panelequipattrs",false,true,param1);
      }
      
      public static function setDetaiAvatar(param1:*, param2:Boolean = false) : void
      {
         var _loc3_:Object = {
            "data":param1,
            "isLock":param2
         };
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_detail_avatar",false,true,_loc3_);
      }
      
      public static function delDetaiAvatar() : void
      {
      }
      
      public static function setMail(param1:String, param2:Object) : void
      {
         delMail();
         GlobalData.$mGameClassObject.mLayoutUICenter.mPanelMail = new starling.display.Sprite();
         PanelMail.mType = param1;
         PanelMail.mCfg = param2;
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_send_mail",false,true);
      }
      
      public static function delMail() : void
      {
         if(GlobalData.$mGameClassObject.mLayoutUICenter.mPanelMail)
         {
            StarlingTools.removeChildrenClear(GlobalData.$mGameClassObject.mLayoutUICenter.mPanelMail);
            GlobalData.$mGameClassObject.mLayoutUICenter.mPanelMail.removeFromParent(true);
         }
         GlobalData.$mGameClassObject.mLayoutUICenter.mPanelMail = null;
      }
      
      public static function checkFirendsLen() : Boolean
      {
         var _loc3_:Object = null;
         var _loc2_:String = null;
         var _loc6_:Boolean = false;
         var _loc1_:Array = GlobalData.$mConfig_simple.friend_len as Array;
         var _loc4_:Object = GlobalData.$userData;
         var _loc5_:int = int(_loc1_[2]);
         if(GlobalData.$tempFriend.length >= GlobalData.$userData.attrs.friend_len)
         {
            if(GlobalData.$userData.attrs.friend_len >= _loc1_[3])
            {
               popError(GlobalLanguageStr.getLanguageStr(90007));
            }
            else
            {
               if(GlobalData.$userData.coin >= _loc5_)
               {
                  _loc3_ = {
                     "ok":service_friend,
                     "no":functionNull
                  };
               }
               else
               {
                  _loc3_ = {
                     "ok":popErrorCoin,
                     "okA":[_loc5_,"Pop"],
                     "no":functionNull
                  };
               }
               _loc2_ = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90006,_loc1_[1],_loc5_,GlobalData.$userData.attrs.friend_len,_loc1_[3]),GlobalTextStyle.COLOR_W_Y_Y_G);
               popAlert("",_loc2_,_loc3_);
            }
         }
         else
         {
            _loc6_ = true;
         }
         return _loc6_;
      }
      
      public static function getAvatarIcon(param1:String = "A_1001_2") : Image
      {
         var _loc2_:String = param1 + "_icon0000";
         var _loc3_:Image = new Image(getTexture(_loc2_));
         _loc3_.touchable = false;
         _loc3_.name = "icon";
         return _loc3_;
      }
      
      public static function popMsg(param1:String, param2:Boolean = false) : void
      {
         popAlert("",param1,null,true);
      }
      
      public static function popError(param1:String, param2:Boolean = false, param3:String = null) : void
      {
         var _loc5_:String = param2 ? param1 : Tools.formatLineX(param1,GlobalTextStyle.COLOR_W_Y_Y_G);
         var _loc4_:Object = null;
         if(param3)
         {
            _loc4_ = {"aid":param3};
         }
         popAlert("",_loc5_,_loc4_,true);
      }
      
      public static function popErrorCoin(param1:int, param2:Function = null, param3:String = "") : void
      {
         var goStore:*;
         var _fun:Object;
         var str:String;
         var _coin:int = param1;
         var _funOther:Function = param2;
         var _status:String = param3;
         if(MainConfig.$canPay)
         {
            goStore = function():void
            {
               PanelCenterShopVIP.$selectType = 1;
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_pay",false,true);
               GlobalFunction.delMail();
            };
            if(_status == "sys")
            {
               popAlert(GlobalLanguageStr.getLanguageStr(90010),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90051,_coin),GlobalTextStyle.COLOR_W_Y_Y_G),_fun);
               GlobalData.$mGameClassObject.closePopForPanel();
            }
            else
            {
               _fun = {
                  "ok":(_funOther == null ? goStore : _funOther),
                  "no":GlobalFunction.functionNull,
                  "aid":"A_2009_5"
               };
               str = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90051,_coin),GlobalTextStyle.COLOR_W_Y_Y_G);
               popAlert("",str,_fun);
            }
         }
         else
         {
            popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90059,_coin),GlobalTextStyle.COLOR_W_Y_Y_G));
         }
      }
      
      public static function popBuyVIP(param1:Function = null) : void
      {
         var _fun:Object;
         var _funOther:Function = param1;
         var goStore:* = function():void
         {
            PanelCenterShopVIP.$selectType = 1;
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_pay",false,true);
         };
         if(MainConfig.$canPay)
         {
            _fun = {
               "ok":(_funOther == null ? goStore : _funOther),
               "no":GlobalFunction.functionNull
            };
            popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90121),GlobalTextStyle.COLOR_W_Y_Y_G),_fun);
         }
         else
         {
            goStore();
         }
      }
      
      public static function getAvatarUI(param1:String = "A_1001_2") : Image
      {
         param1 = param1.split("|")[0];
         return createImage(param1);
      }
      
      public static function popAvatarInfo(param1:String) : void
      {
         var _loc2_:Avatar = null;
         var _loc3_:String = "";
         var _loc4_:String = "";
         if(param1 == "type_team_formation")
         {
            _loc3_ = GlobalLanguageStr.getLanguageStr(20077);
            _loc4_ = GlobalData.$tempTeamSelect_member.id;
            _loc2_ = new Avatar(_loc4_,GlobalData.$tempTeamSelect_member);
         }
         else if(param1 == "type_avatars_manage")
         {
            _loc3_ = checkLock(GlobalData.$tempLockItem.id) ? GlobalLanguageStr.getLanguageStr(20078) : GlobalLanguageStr.getLanguageStr(20023);
            _loc4_ = GlobalData.$tempLockItem.id;
            _loc2_ = new Avatar(_loc4_,GlobalData.$tempLockItem);
         }
         else if(param1 == "type_pve_friend")
         {
            _loc4_ = GlobalData.$tempHelpAvatar.avatar.aid;
            _loc2_ = new Avatar(_loc4_,GlobalData.$tempHelpAvatar.avatar);
         }
         else if(param1 == "type_avatars_friend")
         {
            _loc3_ = GlobalLanguageStr.getLanguageStr(20056);
            _loc4_ = GlobalData.$tempSocial_friend.avatar.aid;
            _loc2_ = new Avatar(_loc4_,GlobalData.$tempSocial_friend.avatar);
         }
         else if(param1 == "type_avatars_better")
         {
            _loc3_ = GlobalLanguageStr.getLanguageStr(20077);
            _loc4_ = GlobalData.$tempAvatarBetter.id;
            _loc2_ = new Avatar(_loc4_,GlobalData.$tempAvatarBetter);
         }
         else if(param1 == "type_avatars_starup")
         {
            _loc3_ = GlobalLanguageStr.getLanguageStr(20077);
            _loc4_ = GlobalData.$tempAvatarStarUp.id;
            _loc2_ = new Avatar(_loc4_,GlobalData.$tempAvatarStarUp);
         }
         else if(param1 == "type_avatars_morph")
         {
            _loc3_ = GlobalLanguageStr.getLanguageStr(20077);
            _loc4_ = GlobalData.$tempMorphItem.id;
            _loc2_ = new Avatar(_loc4_,GlobalData.$tempMorphItem);
         }
         setDetaiAvatar(_loc2_,false);
      }
      
      public static function checkSkillName(param1:SkillSet) : String
      {
         var _loc2_:String = "";
         if(param1)
         {
            _loc2_ = param1.skillSetData.name;
         }
         else
         {
            _loc2_ = GlobalLanguageStr.getLanguageStr(90022);
         }
         return _loc2_;
      }
      
      public static function openGameEndAward() : void
      {
         if(GlobalData.$mGameClassObject)
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_GameEndAward");
            GlobalData.$mEventDispatcher.dispatchEventWith("update_game_end_award");
            GlobalData.$mGameClassObject.mLayoutUIBottom.visible = false;
         }
      }
      
      public static function checkSearchType(param1:Avatar, param2:int) : Boolean
      {
         return checkSearchTypeByType(param1.avatarData.id,param2);
      }
      
      public static function checkSearchTypeByType(param1:String, param2:int) : Boolean
      {
         var _loc3_:Boolean = false;
         if(param2 == 0)
         {
            _loc3_ = true;
         }
         else if(param2 == 1)
         {
            if(param1.indexOf("A_1") > -1)
            {
               _loc3_ = true;
            }
         }
         else if(param2 == 2)
         {
            if(param1.indexOf("A_2") > -1 || param1.indexOf("A_3") > -1 || param1.indexOf("A_4") > -1)
            {
               _loc3_ = true;
            }
         }
         else if(param2 == 3)
         {
            if(param1.indexOf("A_5") > -1)
            {
               _loc3_ = true;
            }
         }
         else if(param2 == 4)
         {
            if(param1.indexOf("A_6") > -1)
            {
               _loc3_ = true;
            }
         }
         return _loc3_;
      }
      
      public static function clearSearchType() : void
      {
         GlobalData.$searchType = [0,0,0];
      }
      
      public static function closePopAllPanel(param1:Function = null) : void
      {
         GlobalData.$mGameClassObject.closePopForPanel(-1,param1);
      }
      
      public static function setLoading(param1:Boolean = true, param2:Boolean = false) : void
      {
         if(param1)
         {
            if(GlobalData.$mGameClassObject.mLayoutLoading)
            {
               return;
            }
            GlobalData.$mGameClassObject.mLayoutLoading = new starling.display.Sprite();
            GlobalData.$mGameClassObject.mLayoutLoading.addChild(new LayoutUILoading());
            GlobalData.$mGameClassObject.addChild(GlobalData.$mGameClassObject.mLayoutLoading);
         }
         else
         {
            delLoading();
         }
      }
      
      public static function delLoading() : void
      {
         if(GlobalData.$mGameClassObject.mLayoutLoading)
         {
            if(GlobalData.$mGameClassObject.mLayoutLoading.numChildren > 0)
            {
               GlobalData.$mGameClassObject.mLayoutLoading.removeChildren();
            }
         }
         GlobalData.$mGameClassObject.mLayoutLoading = null;
      }
      
      public static function getCurrLvMaxEXP(param1:int) : Number
      {
         var _loc5_:Array = GlobalData.$mConfig_simple.exp_config as Array;
         var _loc6_:Number = Number(_loc5_[0]);
         var _loc3_:Number = Number(_loc5_[1]);
         var _loc4_:Number = Number(_loc5_[2]);
         var _loc2_:Number = _loc6_ * param1 * param1 + _loc3_ * param1 + _loc4_;
         if(GlobalData.$mConfig_simple.up_exp[param1 + 1])
         {
            _loc2_ = Number(GlobalData.$mConfig_simple.up_exp[param1 + 1]);
         }
         if(param1 >= _loc5_[3])
         {
            _loc2_ = 0;
         }
         return _loc2_;
      }
      
      public static function changePVEHelpAvatar(param1:String, param2:Object) : void
      {
         var _loc3_:Object = null;
         var _loc5_:Array = GlobalData.$tempOnline;
         var _loc6_:uint = 0;
         var _loc4_:uint = _loc5_.length;
         _loc6_ = 0;
         while(_loc6_ < _loc4_)
         {
            _loc3_ = _loc5_[_loc6_];
            if(_loc3_.uid == param1)
            {
               _loc3_.avatar = param2;
               return;
            }
            _loc6_++;
         }
         _loc5_ = GlobalData.$tempFriend;
         _loc4_ = _loc5_.length;
         _loc6_ = 0;
         while(_loc6_ < _loc4_)
         {
            _loc3_ = _loc5_[_loc6_];
            if(_loc3_.uid == param1)
            {
               _loc3_.avatar = param2;
               return;
            }
            _loc6_++;
         }
      }
      
      public static function check_bot_user(param1:String) : Boolean
      {
         var _uid:String = param1;
         if(_uid.indexOf("bot") >= 0)
         {
            return true;
         }
         var _localBotId:Number = Number(_uid);
         return _localBotId >= 92000001 && _localBotId <= 92000012;
      }
      
      public static function checkLoginTime(param1:Number) : String
      {
         var _loc3_:Number = SendAndSelect.$systemTimer_nowSecond;
         var _loc6_:Number = _loc3_ - param1;
         var _loc4_:Number = _loc6_ / 60;
         var _loc2_:Number = _loc4_ / 60;
         var _loc5_:Number = Math.floor(_loc2_ / 24);
         _loc5_ -= 1;
         return _loc5_ < 1 ? GlobalLanguageStr.getLanguageStr(20293) : GlobalLanguageStr.getLanguageStr(20294,_loc5_);
      }
      
      public static function popEnergy() : void
      {
         var _loc5_:Object = null;
         var _loc3_:Array = GlobalData.$mConfig_simple.energy_config as Array;
         _loc5_ = {
            "ok":GlobalFunction.service_energy,
            "no":GlobalFunction.functionNull
         };
         var _loc1_:int = int(_loc3_[5]);
         _loc1_ += int(GlobalFunction.getVipLv() > 0 ? GlobalFunction.getVipObj().buy_energy : 0);
         var _used:int = getEnergyPurchaseCountToday();
         var _loc2_:int = Math.max(0,_loc1_ - _used);
         var _loc6_:int = _loc3_[4] + _loc3_[7] * _used;
         var _loc4_:String = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90002,_loc6_,_loc1_,_loc2_),GlobalTextStyle.COLOR_W_Y_Y_G);
         GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(20095),_loc4_,_loc5_);
      }
      
      private static function getEnergyPurchaseCountToday() : int
      {
         var records:Object = GlobalData.$userData.records;
         var now:Date = new Date(SendAndSelect.$systemTimer_nowSecond * 1000 + 28800000);
         var month:String = String(now.getUTCMonth() + 1);
         var day:String = String(now.getUTCDate());
         if(month.length < 2) month = "0" + month;
         if(day.length < 2) day = "0" + day;
         var today:String = now.getUTCFullYear() + "-" + month + "-" + day;
         if(records.energy_purchase_day && String(records.energy_purchase_day) != today) return 0;
         return Math.max(0,int(records.energy_times));
      }

      public static function popAskMorph(param1:Boolean = false) : void
      {
         var _show_id:String;
         var _fCfg:Object;
         var _mStatus_up:Boolean = param1;
         var ok:* = function():void
         {
            PanelCenterMain.gotoOpenActivityPanel("morph");
         };
         var no:* = function():void
         {
         };
         if(GlobalData.$currentGuide)
         {
            return;
         }
         _show_id = GlobalData.$mConfig_simple.show_id[18];
         _fCfg = {
            "ok":ok,
            "okUI":GlobalLanguageStr.getLanguageStr(90225),
            "no":no,
            "noUI":GlobalLanguageStr.getLanguageStr(44002),
            "aid":_show_id
         };
         popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90224),GlobalTextStyle.COLOR_W_Y_Y_G),_fCfg,true,null,_mStatus_up);
      }
      
      public static function popAskGuide() : void
      {
         var _info:String;
         var _fCfg:Object;
         var ok:* = function():void
         {
            GlobalData.isShow_ShareBtn = false;
            GuideMaster.getOnlyExample().startGuide("A",2);
            GlobalFunction.delLoading();
         };
         var no:* = function():void
         {
            GuideMaster.getOnlyExample().finishGuide("A");
            GuideMaster.getOnlyExample().startGuide("C");
            GlobalFunction.delLoading();
         };
         GuideMaster.getOnlyExample().guideWait();
         _info = GlobalLanguageStr.getLanguageStr(44000,GlobalData.$userData.name);
         _fCfg = {
            "ok":ok,
            "okUI":GlobalLanguageStr.getLanguageStr(44001),
            "no":no,
            "noUI":GlobalLanguageStr.getLanguageStr(44002),
            "aid":"A_1060_6",
            "noClose":1
         };
         popAlert("",Tools.formatLineX(_info,GlobalTextStyle.COLOR_W_Y_Y_G),_fCfg);
      }
      
      public static function popHardGuide(param1:Function) : void
      {
         var _noFun:Function = param1;
         var rise:* = function():void
         {
            GlobalData.$tempEquipFunId = 1;
            GlobalData.$mGameClassObject.closePopForPanel();
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_change_base");
         };
         var better:* = function():void
         {
            GlobalData.$mGameClassObject.closePopForPanel();
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_social_main_avatar");
         };
         var _fCfg:Object = {
            "ok":better,
            "okUI":GlobalLanguageStr.getLanguageStr(20308),
            "append":rise,
            "appendUI":GlobalLanguageStr.getLanguageStr(20307),
            "no":_noFun,
            "noUI":GlobalLanguageStr.getLanguageStr(20296)
         };
         popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20215),GlobalTextStyle.COLOR_W_Y_Y_G),_fCfg);
      }
      
      public static function popLoseGuide(param1:Boolean = false) : void
      {
         var _isFragment:Boolean = param1;
         var rise:* = function():void
         {
            GlobalData.$tempEquipFunId = 0;
            GlobalData.$mGameClassObject.closePopForPanel();
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_change_base");
            GlobalData.$mEventDispatcher.dispatchEventWith("update_avatar_sell");
         };
         var better:* = function():void
         {
            PanelSocialMainAvatar.$tabBarSelectedIndex = 1;
            GlobalData.$mGameClassObject.closePopForPanel();
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_social_main_avatar");
         };
         var again:* = function():void
         {
            if(_isFragment)
            {
               GlobalData.$setFragment();
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_fragment_embattle");
            }
         };
         var _title:String = GlobalLanguageStr.getLanguageStr(90010);
         var _fCfg:Object = null;
         if(_isFragment)
         {
            _fCfg = {
               "ok":better,
               "okUI":GlobalLanguageStr.getLanguageStr(20308),
               "append":rise,
               "appendUI":GlobalLanguageStr.getLanguageStr(20307),
               "no":again,
               "noUI":GlobalLanguageStr.getLanguageStr(20295)
            };
         }
         else
         {
            _fCfg = {
               "ok":better,
               "okUI":GlobalLanguageStr.getLanguageStr(20308),
               "closeA":true,
               "no":rise,
               "noUI":GlobalLanguageStr.getLanguageStr(20307)
            };
         }
         popAlert(_title,Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90089),GlobalTextStyle.COLOR_W_Y_Y_G),_fCfg);
      }
      
      public static function popAvatarLen() : void
      {
         var sell:* = function():void
         {
            PanelSocialMainAvatar.$tabBarSelectedIndex = 4;
            GlobalData.$mGameClassObject.closePopForPanel();
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_social_main_avatar");
         };
         var better:* = function():void
         {
            PanelSocialMainAvatar.$tabBarSelectedIndex = 1;
            GlobalData.$mGameClassObject.closePopForPanel();
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_social_main_avatar");
         };
         var addLen:* = function():void
         {
            var _loc5_:int = 0;
            var _loc2_:String = null;
            var _loc1_:Array = GlobalData.$mConfig_simple.avatar_len as Array;
            var _loc3_:Object = null;
            var _loc4_:int = int(_loc1_[2]);
            if(GlobalData.$userData.vip_lv == 0)
            {
               _loc5_ = 0;
            }
            else
            {
               _loc5_ = int(getVipObj().avatar_len_add);
            }
            if(GlobalData.$userData.attrs.avatar_len < _loc5_ + _loc1_[3])
            {
               if(GlobalData.$userData.coin >= _loc4_)
               {
                  _loc3_ = {
                     "ok":GlobalFunction.service_avatarNum,
                     "no":GlobalFunction.functionNull
                  };
               }
               else
               {
                  _loc3_ = {
                     "ok":popErrorCoin,
                     "okA":[_loc4_,"Pop"],
                     "no":functionNull
                  };
               }
               _loc2_ = GlobalLanguageStr.getLanguageStr(90004,_loc1_[1],_loc1_[2],GlobalData.$userData.attrs.avatar_len,_loc5_ + _loc1_[3]);
               popAlert(GlobalLanguageStr.getLanguageStr(20096),Tools.formatLineX(_loc2_,GlobalTextStyle.COLOR_W_Y_Y_G),_loc3_);
            }
            else
            {
               popError(GlobalLanguageStr.getLanguageStr(90005));
            }
         };
         var _title:String = GlobalLanguageStr.getLanguageStr(90015);
         var _info:String = GlobalLanguageStr.getLanguageStr(90030);
         var _fCfg:Object = {
            "no":addLen,
            "noUI":GlobalLanguageStr.getLanguageStr(20129),
            "noA":["Pop"],
            "append":sell,
            "appendUI":GlobalLanguageStr.getLanguageStr(20309),
            "ok":better,
            "okUI":GlobalLanguageStr.getLanguageStr(20308)
         };
         popAlert(_title,_info,_fCfg);
      }
      
      public static function popEquipFull() : void
      {
         var disassemble:* = function():void
         {
            GlobalData.$tempEquipFunId = 4;
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_change_base");
            GlobalData.$mGameClassObject.closePopForPanel();
         };
         var _title:String = GlobalLanguageStr.getLanguageStr(90226);
         var _equipfun:Object = {
            "ok":disassemble,
            "okUI":GlobalLanguageStr.getLanguageStr(90227),
            "no":GlobalFunction.functionNull
         };
         popAlert(_title,Tools.formatLineX(GlobalLanguageStr.getLanguageStr(10084),GlobalTextStyle.COLOR_W_Y_Y_G),_equipfun);
      }
      
      public static function check_EquipAvatar_Len() : Boolean
      {
         var _loc1_:Boolean = true;
         if(GlobalData.$userData_avatarNum >= int(GlobalData.$userData.attrs.avatar_len))
         {
            GlobalFunction.popAvatarLen();
            _loc1_ = false;
         }
         else if(Tools.getElementNum(GlobalData.$userData.my_equips) >= int(GlobalData.$mConfig_simple.equip_config[0]))
         {
            GlobalFunction.popEquipFull();
            _loc1_ = false;
         }
         return _loc1_;
      }
      
      public static function popCasion_A() : void
      {
         var _goWagerscore:* = function():void
         {
            PanelCenterShopVIP.$selectType = 0;
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_shopAndVIP");
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_casino_A",false,true);
            if(GlobalFunction.checkWagerTime(0) <= 0)
            {
            }
         };
         var _gowagerscoreFun:Object = {
            "ok":_goWagerscore,
            "no":GlobalFunction.functionNull,
            "aid":"A_2009_5"
         };
         GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(10040),_gowagerscoreFun);
      }
      
      public static function popCasion_B(param1:String = "") : void
      {
         var _info:String = param1;
         var goWagercoin:* = function():void
         {
            PanelCenterShopVIP.$selectType = 0;
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_shopAndVIP");
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_casino_B",false,true);
            if(GlobalFunction.checkWagerTime(1) <= 0)
            {
            }
         };
         var _wagercoinFun:Object = {
            "ok":goWagercoin,
            "no":GlobalFunction.functionNull,
            "aid":"A_2009_5"
         };
         GlobalFunction.popAlert("",_info,_wagercoinFun);
      }
      
      public static function service_energy() : void
      {
         var _beforeVip:int = int(GlobalData.$userData.vip_lv);
         var _received:Boolean = false;
         SendServiceAMFFun.send_user_full_energy(function(_receipt:Object):void
         {
            if(_received)
            {
               return;
            }
            _received = true;
            _receipt._profileBeforeVip = _beforeVip;
            re_fun(_receipt);
         },null);
      }
      
      public static function service_avatarNum() : void
      {
         var _beforeVip:int = int(GlobalData.$userData.vip_lv);
         var _received:Boolean = false;
         SendServiceAMFFun.send_user_expand_avatar_num(function(_receipt:Object):void
         {
            if(_received)
            {
               return;
            }
            _received = true;
            _receipt._profileBeforeVip = _beforeVip;
            re_fun(_receipt);
         },{"avatar_len":GlobalData.$userData.attrs.avatar_len});
      }
      
      public static function service_friend() : void
      {
         var _beforeVip:int = int(GlobalData.$userData.vip_lv);
         var _received:Boolean = false;
         SendServiceAMFFun.send_user_expand_friend_len(function(_receipt:Object):void
         {
            if(_received)
            {
               return;
            }
            _received = true;
            _receipt._profileBeforeVip = _beforeVip;
            re_fun(_receipt);
         },{"friend_len":GlobalData.$userData.attrs.friend_len});
      }
      
      public static function sevice_pvp_buy(param1:String, param2:Function = null) : void
      {
         var _fun:Object;
         var _title:String = param1;
         var _reFun:Function = param2;
         var _received:Boolean = false;
         var sendService:* = function():void
         {
            var _beforeVip:int = int(GlobalData.$userData.vip_lv);
            SendServiceAMFFun.send_user_full_fragment_energy(function(_receipt:Object):void
            {
               _receipt._profileBeforeVip = _beforeVip;
               re_buy_pvp_fun(_receipt);
            },null);
         };
         var re_buy_pvp_fun:* = function(param1:Object):void
         {
            var _loc2_:String = null;
            if(_received)
            {
               return;
            }
            _received = true;
            if(isVersionedProfileReceipt(param1))
            {
               refreshProfileTopBar();
               showVersionedVipReceipt(param1);
               if(_reFun != null)
               {
                  _reFun();
               }
               return;
            }
            GlobalData.$userData.attrs.fragment_energy_extra = param1.data.attr_fragment_energy_extra;
            GlobalData.$userData.records.fragment_energy_times = param1.data.fragment_energy_times;
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateFragmentEn(param1.data.fragment_energy as Date);
            if(_reFun != null)
            {
               _reFun();
            }
            _loc2_ = payCoinVip(_coin);
            if(_loc2_ != "")
            {
               check_vip_gotoShop(_loc2_);
            }
         };
         var _cfg:Array = GlobalData.$mConfig_simple.capacity_config as Array;
         var _max:int = int(_cfg[4]);
         var _times:int = _max - GlobalData.$userData.records.fragment_energy_times;
         var _coin:int = _cfg[6] + GlobalData.$userData.records.fragment_energy_times * _cfg[5];
         var _data:Object = GlobalData.$userData.records;
         var _obj:Object = GlobalFunction.getFragmentPower();
         if(GlobalData.$userData.records.fragment_energy_times >= _cfg[4])
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10075));
            return;
         }
         if(_obj.energy < _obj.max)
         {
            if(GlobalData.$userData.coin >= _coin)
            {
               if(GlobalData.$userData.records.fragment_energy_times < _cfg[4])
               {
                  _fun = {
                     "ok":sendService,
                     "no":GlobalFunction.functionNull
                  };
                  GlobalFunction.popAlert(_title,Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90088,GlobalLanguageStr.getStr(90670),_coin,_max,_times),GlobalTextStyle.COLOR_W_Y_Y_G),_fun);
               }
               else
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90087,_cfg[1]));
               }
            }
            else
            {
               GlobalFunction.popErrorCoin(_coin);
            }
         }
         else
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10135));
         }
      }
      
      public static function re_fun(param1:Object) : void
      {
         var _loc2_:Array = null;
         var _loc3_:String = null;
         if(isVersionedProfileReceipt(param1))
         {
            refreshProfileTopBar();
            showVersionedVipReceipt(param1);
            return;
         }
         if(param1.method == "user.full_energy")
         {
            GlobalData.$userData.attrs.energy_extra = param1.data.attr_energy_extra;
            GlobalData.$userData.records.energy_times = param1.data.energy_times;
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateEn(param1.data.energy as Date);
            _loc3_ = payCoinVip(GlobalData.$userData.coin - param1.data.coin);
         }
         else if(param1.method == "user.expand_avatar_len")
         {
            _loc2_ = GlobalData.$mConfig_simple.avatar_len as Array;
            GlobalData.$userData.attrs.avatar_len += int(_loc2_[1]);
            _loc3_ = payCoinVip(_loc2_[2]);
         }
         else if(param1.method == "user.expand_friend_len")
         {
            _loc2_ = GlobalData.$mConfig_simple.friend_len as Array;
            GlobalData.$userData.attrs.friend_len += _loc2_[1];
            _loc3_ = payCoinVip(_loc2_[2]);
         }
         if(_loc3_ != "")
         {
            check_vip_gotoShop(_loc3_);
         }
      }
      
      public static function check_vip_gotoShop(param1:String) : void
      {
         var _str:String = param1;
         var goStore:* = function():void
         {
            PanelCenterShopVIP.$selectType = 1;
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_pay",false,true);
            GlobalFunction.delMail();
         };
         var _fun:Object = {
            "ok":GlobalFunction.functionNull,
            "okUI":GlobalLanguageStr.getLanguageStr(20121),
            "no":goStore,
            "noUI":GlobalLanguageStr.getLanguageStr(20224)
         };
         _str = Tools.formatLineX(_str,[16777215,16777215,16776960,65280]);
         GlobalFunction.popAlert("",_str,_fun);
      }
      
      public static function get_png_bg_avatar(param1:Number = 1) : Image
      {
         var _loc2_:Image = createImage("png_bg_avatar",true);
         _loc2_.touchable = false;
         _loc2_.x = int((640 - _loc2_.width) * 0.5);
         _loc2_.y = int((960 - _loc2_.height) * 0.5);
         return _loc2_;
      }
      
      public static function showReward(param1:Array) : void
      {
         var _loc4_:int = 0;
         var _loc3_:Object = null;
         var _loc2_:Object = null;
         _loc4_ = 0;
         while(_loc4_ < param1.length)
         {
            _loc3_ = param1[_loc4_];
            _loc2_ = _loc3_.rewards_dict;
            showReward2(_loc3_,_loc2_);
            _loc4_++;
         }
         SoundManager.getOnlyExample().playSound("skill2");
      }
      
      public static function showReward2(param1:Object, param2:Object) : void
      {
         var _loc8_:String = null;
         var _loc14_:String = null;
         var _loc15_:Array = null;
         var _loc3_:* = null;
         var _loc13_:* = undefined;
         var _loc11_:Object = null;
         var _loc7_:String = null;
         var _loc12_:Object = null;
         var _loc9_:String = null;
         var _loc5_:Object = null;
         _loc14_ = param1.info + "\n";
         var _loc10_:int = 0;
         var _loc6_:int = 0;
         for(_loc8_ in param2)
         {
            _loc13_ = param2[_loc8_];
            _loc9_ = param1.icon;
            if(_loc8_ == "avatar" || _loc8_ == "equip")
            {
               for(_loc7_ in _loc13_)
               {
                  if(_loc8_ == "avatar")
                  {
                     _loc9_ = _loc7_;
                  }
                  else
                  {
                     _loc9_ = param1.icon;
                  }
                  _loc12_ = {};
                  _loc12_[_loc7_] = _loc13_[_loc7_];
                  _loc11_ = getAwardByType(_loc8_,_loc12_);
                  popAward(_loc8_,_loc14_ + GlobalLanguageStr.getLanguageStr(90062,_loc11_.msg),_loc12_,false,_loc9_);
               }
            }
            else if(_loc8_ == "dust")
            {
               _loc15_ = _loc13_ as Array;
               _loc6_ = int(_loc15_.length);
               _loc10_ = 0;
               while(_loc10_ < _loc6_)
               {
                  if(_loc15_[_loc10_] != 0)
                  {
                     _loc12_ = {};
                     _loc12_["indexID_s"] = _loc10_;
                     _loc12_["numberIndex"] = _loc15_[_loc10_];
                     _loc11_ = getAwardByType(_loc8_,_loc12_);
                     popAward(_loc8_,_loc14_ + GlobalLanguageStr.getLanguageStr(90062,_loc11_.msg),_loc12_,false,_loc9_);
                  }
                  _loc10_++;
               }
            }
            else if(_loc8_ == "culture_book")
            {
               _loc11_ = getAwardByType(_loc8_,_loc13_);
               popAward(_loc8_,_loc14_ + GlobalLanguageStr.getLanguageStr(90062,_loc11_.msg),_loc12_,false,_loc9_);
            }
            else if(_loc8_ == "avatar_soul" || _loc8_ == "equip_soul")
            {
               for(var _loc4_:String in param2[_loc8_])
               {
                  _loc5_ = {};
                  _loc5_[_loc4_] = param2[_loc8_][_loc4_];
                  _loc11_ = getAwardByType(_loc8_,_loc5_);
                  popAward(_loc8_,_loc14_ + GlobalLanguageStr.getLanguageStr(90062,_loc11_.msg),_loc5_,false,_loc9_);
               }
            }
            else
            {
               _loc11_ = getAwardByType(_loc8_,_loc13_);
               popAward(_loc8_,_loc14_ + GlobalLanguageStr.getLanguageStr(90062,_loc11_.msg),_loc13_,false,_loc9_);
            }
         }
      }
      
      public static function updateGlod() : void
      {
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
      }
      
      public static function updateCoin() : void
      {
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin(0);
      }
      
      public static function updateEn() : void
      {
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateEn(GlobalData.$userData.attrs.energy_extra as Date);
      }
      
      public static function updateExp() : void
      {
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateExp(GlobalData.$userData.lv,GlobalData.$userData.exp);
      }
      
      public static function updateFragmentEn() : void
      {
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateFragmentEn(GlobalData.$userData.attrs.fragment_energy);
      }
      
      public static function updateVip() : void
      {
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateVip();
      }
      
      // Receipt kind: -1 malformed state_sync, 0 legacy response without the
      // member, 1 valid versioned response. Validity is independent of whether
      // its revision is newer than the local snapshot high-water mark.
      public static function profileReceiptKind(param1:Object) : int
      {
         if(param1 == null)
         {
            return -1;
         }
         if(!param1.hasOwnProperty("state_sync"))
         {
            return 0;
         }
         if(String(param1.method) == "user.login")
         {
            if(param1.data == null || param1.data.uid == null || !GlobalData.isValidProfileSyncEnvelope(param1.state_sync,String(param1.data.uid)))
            {
               return -1;
            }
            return 1;
         }
         if(!GlobalData.isValidProfileSyncEnvelope(param1.state_sync))
         {
            return -1;
         }
         return 1;
      }
      
      public static function isVersionedProfileReceipt(param1:Object) : Boolean
      {
         return profileReceiptKind(param1) == 1;
      }
      
      public static function isLegacyProfileReceipt(param1:Object) : Boolean
      {
         if(profileReceiptKind(param1) != 0)
         {
            return false;
         }
         var _method:String = String(param1.method);
         return _method.indexOf("user.") != 0 || isProfileBootstrapMethod(_method);
      }
      
      public static function isMalformedProfileReceipt(param1:Object) : Boolean
      {
         return profileReceiptKind(param1) < 0;
      }

      public static function isProfileBootstrapMethod(param1:String) : Boolean
      {
         // These methods establish credentials or install the initial user
         // session; they are the only user.* replies allowed to use the
         // pre-revision bootstrap callback path without a state_sync envelope.
         return param1 == "user.login" || param1 == "user.llogin" || param1 == "user.register" || param1 == "user.default_register";
      }

      public static function didApplyProfileStateSync(param1:Object) : Boolean
      {
         return isVersionedProfileReceipt(param1) && GlobalData.wasProfileSyncApplied(param1.state_sync);
      }

      private static function showVersionedVipReceipt(param1:Object) : void
      {
         var _beforeVip:int = int(param1._profileBeforeVip);
         var _data:Object = param1.data;
         if(!didApplyProfileStateSync(param1) || param1._profileBeforeVip == null || _data == null || _data.vip_lv == null || GlobalData.$userData == null)
         {
            return;
         }
         if(int(_data.vip_lv) > _beforeVip && int(_data.vip_lv) == int(GlobalData.$userData.vip_lv))
         {
            GlobalFunction.popAward("_$vip$_",GlobalLanguageStr.getLanguageStr(20203,_data.vip_lv),_data.vip_lv);
         }
      }

      private static function refreshProfileTopBar() : void
      {
         var _game:Object = GlobalData.$mGameClassObject;
         var _layout:Object = null;
         var _top:Object = null;
         if(_game == null)
         {
            return;
         }
         _layout = _game.mLayoutUITop;
         if(_layout == null)
         {
            return;
         }
         _top = _layout.mPanelTopMain;
         if(_top == null || GlobalData.$userData == null || GlobalData.$userData.attrs == null)
         {
            return;
         }
         _top.updateGold();
         _top.updateCoin(0);
         _top.updateEn(GlobalData.$userData.attrs.energy_extra as Date);
         _top.updateExp(GlobalData.$userData.lv,GlobalData.$userData.exp);
         _top.updateFragmentEn(GlobalData.$userData.attrs.fragment_energy);
         _top.updateVip();
      }
      
      public static function applyProfileStateSync(param1:Object) : Boolean
      {
         if(!GlobalData.applyProfileSnapshot(param1))
         {
            return false;
         }
         GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
         refreshProfileTopBar();
         if(GlobalData.$mEventDispatcher != null)
         {
            GlobalData.$mEventDispatcher.dispatchEventWith("profile_state_sync");
         }
         return true;
      }

      public static function update_UserData(param1:Object) : void
      {
         var _loc2_:String = null;
         var _loc3_:Object = param1.new_avatars;
         for(_loc2_ in _loc3_)
         {
            GlobalData.$userData.avatars[_loc2_] = _loc3_[_loc2_];
            GlobalData.$userData_avatarNum += 1;
         }
         _loc3_ = param1.new_avatar_soul;
         for(_loc2_ in _loc3_)
         {
            GlobalData.$userData.avatar_soul[_loc2_] = _loc3_[_loc2_];
         }
         _loc3_ = param1.new_equips;
         for(_loc2_ in _loc3_)
         {
            GlobalData.$userData.my_equips[_loc2_] = _loc3_[_loc2_];
         }
         _loc3_ = param1.new_equip_soul;
         for(_loc2_ in _loc3_)
         {
            GlobalData.$userData.equip_soul[_loc2_] = _loc3_[_loc2_];
         }
         _loc3_ = param1.new_fragments;
         for(_loc2_ in _loc3_)
         {
            GlobalData.$userData.fragment["equips"][_loc2_] = _loc3_[_loc2_];
         }
         if(param1.coin != null)
         {
            GlobalData.$userData.coin = param1.coin;
            GlobalFunction.updateCoin();
         }
         if(param1.gold != null)
         {
            GlobalData.$userData.gold = param1.gold;
            GlobalFunction.updateGlod();
         }
         if(param1.mark != null)
         {
            GlobalData.$userData.mark = param1.mark;
         }
         if(param1.lv != null)
         {
            GlobalData.$userData.lv = param1.lv;
         }
         if(param1.exp != null)
         {
            GlobalData.$userData.exp = param1.exp;
            GlobalFunction.updateExp();
         }
         if(param1.score != null)
         {
            GlobalData.$userData.score = param1.score;
         }
         if(param1.medal != null)
         {
            GlobalData.$userData.medal = param1.medal;
         }
         if(param1.avatars != null)
         {
            GlobalData.$userData.avatars = param1.avatars;
         }
         if(param1.equips != null)
         {
            GlobalData.$userData.equips = param1.equips;
         }
         if(param1.avatar_soul != null)
         {
            GlobalData.$userData.avatar_soul = param1.avatar_soul;
         }
         if(param1.equip_soul != null)
         {
            GlobalData.$userData.equip_soul = param1.equip_soul;
         }
         if(param1.vip_lv != null)
         {
            GlobalData.$userData.vip_lv = param1.vip_lv;
            GlobalFunction.updateVip();
         }
         if(param1.vip_exp != null)
         {
            GlobalData.$userData.vip_exp = param1.vip_exp;
            GlobalFunction.updateVip();
         }
         if(param1.box_key != null)
         {
            GlobalData.$userData.attrs.box_key = param1.box_key;
         }
         if(param1.dn_stone != null)
         {
            GlobalData.$userData.attrs.dn_stone = param1.dn_stone;
         }
         if(param1.dust != null)
         {
            GlobalData.$userData.attrs.dust = param1.dust;
         }
         if(param1.culture_book != null)
         {
            GlobalData.$userData.attrs.culture_book = param1.culture_book;
         }
         if(param1.energy != null)
         {
            GlobalData.$userData.energy = param1.energy;
            GlobalFunction.updateEn();
         }
         if(param1.energy_extra != null)
         {
            GlobalData.$userData.attrs.energy_extra = param1.energy_extra;
            GlobalFunction.updateEn();
         }
         if(param1.fragment_energy != null)
         {
            GlobalData.$userData.attrs.fragment_energy = param1.fragment_energy;
            GlobalFunction.updateFragmentEn();
         }
         if(param1.fragment_energy_extra != null)
         {
            GlobalData.$userData.attrs.fragment_energy_extra = param1.fragment_energy_extra;
            GlobalFunction.updateFragmentEn();
         }
         if(param1.mode_buy != null)
         {
            GlobalData.$userData.records.exploration_times.mode_buy = param1.mode_buy;
         }
         if(param1.stage_mode != null)
         {
            GlobalData.$userData.exploration.stage_mode = param1.stage_mode;
         }
         if(param1.sp != null)
         {
            GlobalData.$userData.attrs.sp = param1.sp;
         }
      }
      
      public static function showPanel_Center(param1:String, param2:Boolean = false, param3:Boolean = false, param4:Object = null, param5:Boolean = false) : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel(param1,param2,param3,param4,param5);
      }
      
      public static function getPF_Size(param1:int) : int
      {
         if(MainConfig.$isEnglish)
         {
            return param1 - 5;
         }
         return param1;
      }
      
      public static function get_HelpLink(param1:String) : Object
      {
         var _loc3_:starling.display.Sprite = new starling.display.Sprite();
         var _loc4_:LOL_TextField = new LOL_TextField(param1,140,30);
         _loc4_.fontColor = 16777215;
         _loc4_.fontSize = 18;
         _loc4_.touchable = true;
         var _loc2_:int = _loc4_.textBounds.width == 0 ? 1 : _loc4_.textBounds.width;
         var _loc5_:Quad = new Quad(_loc2_,2,16777215);
         _loc5_.y = _loc4_.height - 2;
         _loc5_.x = 3;
         _loc3_.addChild(_loc5_);
         _loc3_.addChild(_loc4_);
         return {
            "ui":_loc3_,
            "w":_loc4_.textBounds.width
         };
      }
      
      public static function getAwardByType(param1:String, param2:* = null, param3:Boolean = false, param4:* = null, param5:String = "", param6:Boolean = true, param7:Number = -1, param8:* = null, param9:Object = null) : Object
      {
         var rate:int;
         var _ui:DisplayObject;
         var _icon:Image;
         var k:*;
         var _avatar:Avatar;
         var onTOUCH_Avatar:*;
         var onTOUCH_Avatar1:*;
         var avatarId:String;
         var nn:String;
         var _add_info:String;
         var onTOUCH_Avatar5:*;
         var onTOUCH_Avatar6:*;
         var _equip:Equip;
         var onTOUCH_equip:*;
         var equipId:String;
         var ee:String;
         var onTOUCH_equip1:*;
         var onTOUCH_Avatar7:*;
         var _dustStr:String;
         var _dustArr:Array;
         var _index:int;
         var ind:int;
         var eid:String;
         var fraIndex:int;
         var ei:String;
         var len:int;
         var framents:Array;
         var j:int;
         var data:*;
         var fr:Fragment;
         var _spStr:String;
         var _spArr:Array;
         var index:int;
         var w:int;
         var h:int;
         var uu:starling.display.Sprite;
         var _numStr:String;
         var _t:LOL_TextField;
         var ss:starling.display.Sprite;
         var _ss:starling.display.Sprite;
         var _type:String = param1;
         var _avatarId:* = param2;
         var _gift:Boolean = param3;
         var _giftItem:* = param4;
         var _info:String = param5;
         var isNumVisible:Boolean = param6;
         var scaleXY:Number = param7;
         var mlist:* = param8;
         var _awardData:Object = param9;
         var hit:* = function(param1:TouchEvent, param2:*):Boolean
         {
            var _loc3_:Touch = param1.getTouch(param2);
            var _loc4_:Point = _loc3_.getLocation(param2);
            return param2.bounds.containsPoint(_loc4_);
         };
         var _num:int = 0;
         var _msg:String = "";
         var _check_in_msg:String = "";
         var _kyArr:Array = null;
         var _isString:Boolean = false;
         var _name:String = "";
         var _valueType:int = 0;
         var _count:int = 0;
         if(_avatarId is String)
         {
            if(String(_avatarId).indexOf("_") > -1)
            {
               _isString = true;
            }
         }
         if(_type == "discount")
         {
            _num = _avatarId;
            _name = GlobalLanguageStr.getLanguageStr(25055);
            _name = GlobalLanguageStr.getLanguageStr(25055);
            _msg = GlobalLanguageStr.getLanguageStr(25055) + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num));
            if(!_gift)
            {
               _ui = GlobalFunction.createImage("UI_award_ui_type_0017") as DisplayObject;
               _ui.addEventListener("touch",function(param1:TouchEvent):void
               {
                  if(mlist && mlist.isScrolling)
                  {
                     return;
                  }
                  if(param1.getTouch(_ui,"ended") && hit(param1,_ui))
                  {
                     GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr("show_return_coin"),GlobalTextStyle.COLOR_W_Y_Y_G));
                  }
               });
            }
         }
         if(_type == "coin")
         {
            _num = _avatarId;
            _valueType = 1;
            _name = GlobalLanguageStr.getLanguageStr(20149);
            _msg = GlobalLanguageStr.getLanguageStr(20149) + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num));
            _check_in_msg = GlobalLanguageStr.getLanguageStr(20149) + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num * 2));
            if(_num < 0)
            {
               _msg = GlobalLanguageStr.getLanguageStr(20324);
               _check_in_msg = GlobalLanguageStr.getLanguageStr(20324);
            }
            if(_gift)
            {
               GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
            }
            else
            {
               _ui = createImage("UI_award_ui_type_0001") as DisplayObject;
               _ui.addEventListener("touch",function(param1:TouchEvent):void
               {
                  if(mlist && mlist.isScrolling)
                  {
                     return;
                  }
                  if(param1.getTouch(_ui,"ended") && hit(param1,_ui))
                  {
                     GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr("show_coin"),GlobalTextStyle.COLOR_W_Y_Y_G));
                  }
               });
            }
         }
         else if(_type == "dn_stone")
         {
            _num = _avatarId;
            _name = GlobalLanguageStr.getLanguageStr(25033);
            _msg = GlobalLanguageStr.getLanguageStr(25033) + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num));
            _check_in_msg = GlobalLanguageStr.getLanguageStr(25033) + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num * 2));
            if(!_gift)
            {
               _ui = createImage("UI_award_ui_type_0008") as DisplayObject;
               _ui.addEventListener("touch",function(param1:TouchEvent):void
               {
                  if(mlist && mlist.isScrolling)
                  {
                     return;
                  }
                  if(param1.getTouch(_ui,"ended") && hit(param1,_ui))
                  {
                     GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr("show_dn_stone"),GlobalTextStyle.COLOR_W_Y_Y_G));
                  }
               });
            }
         }
         else if(_type == "vip_title")
         {
            _num = _avatarId;
            _msg = GlobalLanguageStr.getLanguageStr(20323);
            if(!_gift)
            {
               _ui = createImage("UI_award_ui_type_0006") as DisplayObject;
            }
         }
         else if(_type == "mark")
         {
            _num = _avatarId;
            _name = GlobalLanguageStr.getLanguageStr(20272);
            _msg = _info + GlobalLanguageStr.getLanguageStr(20272) + GlobalLanguageStr.getLanguageStr(20317,_num);
            _check_in_msg = _info + GlobalLanguageStr.getLanguageStr(20272) + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num * 2));
            if(!_gift)
            {
               _ui = createImage("UI_award_ui_type_0004") as DisplayObject;
               _ui.addEventListener("touch",function(param1:TouchEvent):void
               {
                  if(mlist && mlist.isScrolling)
                  {
                     return;
                  }
                  if(param1.getTouch(_ui,"ended") && hit(param1,_ui))
                  {
                     GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr("show_mark"),GlobalTextStyle.COLOR_W_Y_Y_G));
                  }
               });
            }
         }
         else if(_type == "medal")
         {
            _num = _avatarId;
            _valueType = 1;
            _name = GlobalLanguageStr.getLanguageStr(20311);
            _msg = _info + GlobalLanguageStr.getLanguageStr(20311) + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num));
            _check_in_msg = _info + GlobalLanguageStr.getLanguageStr(20311) + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num * 2));
            if(!_gift)
            {
               _ui = createImage("UI_award_ui_type_0005") as DisplayObject;
               _ui.addEventListener("touch",function(param1:TouchEvent):void
               {
                  if(mlist && mlist.isScrolling)
                  {
                     return;
                  }
                  if(param1.getTouch(_ui,"ended") && hit(param1,_ui))
                  {
                     GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr("show_medal"),GlobalTextStyle.COLOR_W_Y_Y_G));
                  }
               });
            }
         }
         else if(_type == "gold")
         {
            _num = _avatarId;
            _name = GlobalLanguageStr.getLanguageStr(20162);
            _msg = GlobalLanguageStr.getLanguageStr(20162) + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num));
            _check_in_msg = GlobalLanguageStr.getLanguageStr(20162) + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num * 2));
            if(_gift)
            {
               GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
            }
            else
            {
               _ui = createImage("UI_award_ui_type_0000") as DisplayObject;
               _ui.addEventListener("touch",function(param1:TouchEvent):void
               {
                  if(mlist && mlist.isScrolling)
                  {
                     return;
                  }
                  if(param1.getTouch(_ui,"ended") && hit(param1,_ui))
                  {
                     GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr("show_gold"),GlobalTextStyle.COLOR_W_Y_Y_G));
                  }
               });
            }
         }
         else if(_type == "score")
         {
            _num = _avatarId;
            _msg = _info + GlobalLanguageStr.getLanguageStr(20163) + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num));
            _check_in_msg = _info + GlobalLanguageStr.getLanguageStr(20163) + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num * 2));
            _name = GlobalLanguageStr.getLanguageStr(20163);
            if(_gift)
            {
               GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateScore();
            }
            else
            {
               _ui = createImage("UI_award_ui_type_0002") as DisplayObject;
               _ui.addEventListener("touch",function(param1:TouchEvent):void
               {
                  if(mlist && mlist.isScrolling)
                  {
                     return;
                  }
                  if(param1.getTouch(_ui,"ended") && hit(param1,_ui))
                  {
                     GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr("show_score"),GlobalTextStyle.COLOR_W_Y_Y_G));
                  }
               });
            }
         }
         else if(_type == "energy")
         {
            _num = _avatarId;
            _valueType = 1;
            _name = GlobalLanguageStr.getLanguageStr(20164);
            _msg = GlobalLanguageStr.getLanguageStr(20164) + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num));
            _check_in_msg = GlobalLanguageStr.getLanguageStr(20164) + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num * 2));
            if(_gift)
            {
               GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateEn();
            }
            else
            {
               _ui = createImage("UI_award_ui_type_0003") as DisplayObject;
               _ui.addEventListener("touch",function(param1:TouchEvent):void
               {
                  if(mlist && mlist.isScrolling)
                  {
                     return;
                  }
                  if(param1.getTouch(_ui,"ended") && hit(param1,_ui))
                  {
                     GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr("show_energy"),GlobalTextStyle.COLOR_W_Y_Y_G));
                  }
               });
            }
         }
         else if(_type == "fragment_energy")
         {
            _num = _avatarId;
            _name = GlobalLanguageStr.getLanguageStr(90466);
            _msg = GlobalLanguageStr.getLanguageStr(90466) + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num));
            _check_in_msg = GlobalLanguageStr.getLanguageStr(90466) + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num * 2));
            if(!_gift)
            {
               _ui = createImage("UI_award_ui_type_0011") as DisplayObject;
               _ui.addEventListener("touch",function(param1:TouchEvent):void
               {
                  if(mlist && mlist.isScrolling)
                  {
                     return;
                  }
                  if(param1.getTouch(_ui,"ended") && hit(param1,_ui))
                  {
                     GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr("show_fragmentenergy"),GlobalTextStyle.COLOR_W_Y_Y_G));
                  }
               });
            }
         }
         else if(_type == "avatar")
         {
            if(!_isString)
            {
               _msg = "";
               _check_in_msg = "";
               _num = 0;
               for(k in _avatarId)
               {
                  _count += 1;
                  if(_count > 3)
                  {
                     _msg += GlobalLanguageStr.getLanguageStr(31006) + " ";
                     _check_in_msg += GlobalLanguageStr.getLanguageStr(31006) + " ";
                     break;
                  }
                  _avatar = new Avatar(k);
                  if(_avatar.getStar() > 4)
                  {
                     _valueType = 2;
                  }
                  else
                  {
                     _valueType = 1;
                  }
                  _num += _avatarId[k];
                  if(_count == 1)
                  {
                     onTOUCH_Avatar = function(param1:TouchEvent):void
                     {
                        if(mlist && mlist.isScrolling)
                        {
                           return;
                        }
                        var _loc2_:Touch = param1.getTouch(_ui);
                        if(_loc2_)
                        {
                           if(_loc2_.phase == "ended" && Boolean(hit(param1,_ui)))
                           {
                              GlobalFunction.setDetaiAvatar({
                                 "id":k,
                                 "isSoul":false
                              });
                           }
                        }
                     };
                     _ui = _avatar.getAvatarRes() as DisplayObject;
                     _name = _avatar.avatarData.name;
                     _ui.addEventListener("touch",onTOUCH_Avatar);
                  }
                  _msg += GlobalLanguageStr.getLanguageStr(20205,_avatar.getStar(),_avatar.avatarData.name);
                  _check_in_msg += GlobalLanguageStr.getLanguageStr(20205,_avatar.getStar(),_avatar.avatarData.name);
                  if(_avatarId[k] > 1)
                  {
                     _msg += GlobalLanguageStr.getLanguageStr(20317,_avatarId[k]);
                  }
                  _check_in_msg += GlobalLanguageStr.getLanguageStr(20317,_avatarId[k] * 2);
                  _msg += " ";
                  _check_in_msg += " ";
                  _avatar.clearData();
               }
               _msg = _msg.slice(0,_msg.length - 1);
               _check_in_msg = _check_in_msg.slice(0,_check_in_msg.length - 1);
            }
            else
            {
               onTOUCH_Avatar1 = function(param1:TouchEvent):void
               {
                  if(mlist && mlist.isScrolling)
                  {
                     return;
                  }
                  var _loc2_:Touch = param1.getTouch(_ui);
                  if(_loc2_ && _loc2_.phase == "ended" && hit(param1,_ui))
                  {
                     GlobalFunction.setDetaiAvatar({"id":_avatarId});
                  }
               };
               _num = 1;
               _avatar = new Avatar(_avatarId);
               _name = _avatar.avatarData.name;
               _msg = GlobalLanguageStr.getLanguageStr(20205,_avatar.getStar(),_avatar.avatarData.name);
               _check_in_msg = GlobalLanguageStr.getLanguageStr(20205,_avatar.getStar(),_avatar.avatarData.name);
               _ui = _avatar.getAvatarRes() as DisplayObject;
               _ui.addEventListener("touch",onTOUCH_Avatar1);
            }
            if(_gift)
            {
               GlobalData.$userData_avatarNum += _num;
            }
         }
         else if(_type == "avatar_soul")
         {
            onTOUCH_Avatar5 = function(param1:TouchEvent):void
            {
               if(mlist && mlist.isScrolling)
               {
                  return;
               }
               var _loc2_:Touch = param1.getTouch(_ui);
               if(_loc2_ && _loc2_.phase == "ended" && hit(param1,_ui))
               {
                  GlobalFunction.setDetaiAvatar({
                     "id":avatarId,
                     "isSoul":true
                  });
               }
            };
            for(nn in _avatarId)
            {
               avatarId = nn;
               _num = int(_avatarId[nn]);
            }
            _avatar = new Avatar(avatarId);
            _name = _avatar.avatarData.name + GlobalLanguageStr.getLanguageStr(90586);
            _check_in_msg = _msg = GlobalLanguageStr.getLanguageStr(20205,_avatar.getStar(),_avatar.avatarData.name) + GlobalLanguageStr.getLanguageStr(90586);
            if(_num > 1)
            {
               _msg += GlobalLanguageStr.getLanguageStr(20317,_num);
            }
            _check_in_msg += GlobalLanguageStr.getLanguageStr(20317,_num * 2);
            _add_info = "\n（" + GlobalLanguageStr.getStr(90672) + "）";
            _msg += _add_info;
            _check_in_msg += _add_info;
            _ui = _avatar.getAvatarRes() as DisplayObject;
            _ui.addEventListener("touch",onTOUCH_Avatar5);
            _ui.name = _type;
            _icon = GlobalFunction.createImage("UI_icon_fragment_0000");
         }
         else if(_type == "avatar_soul_random")
         {
            onTOUCH_Avatar6 = function(param1:TouchEvent):void
            {
               if(mlist && mlist.isScrolling)
               {
                  return;
               }
               var _loc2_:Touch = param1.getTouch(_ui);
               if(_loc2_ && _loc2_.phase == "ended" && hit(param1,_ui))
               {
                  GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr("show_avatarsoul_random"),GlobalTextStyle.COLOR_W_Y_Y_G));
               }
            };
            _ui = GlobalFunction.createImage("UI_bg_card_2_0003") as DisplayObject;
            _icon = GlobalFunction.createImage("UI_icon_fragment_0000");
            _ui.addEventListener("touch",onTOUCH_Avatar6);
         }
         else if(_type == "equip")
         {
            if(!_isString)
            {
               _check_in_msg = _msg = "";
               for(k in _avatarId)
               {
                  _count += 1;
                  if(_count > 3)
                  {
                     _msg += GlobalLanguageStr.getLanguageStr(31006) + " ";
                     _check_in_msg += GlobalLanguageStr.getLanguageStr(31006) + " ";
                     break;
                  }
                  _equip = new Equip(k,_awardData);
                  if(_equip.getStar() > 4)
                  {
                     _valueType = 2;
                  }
                  else
                  {
                     _valueType = 1;
                  }
                  _num = int(_avatarId[k]);
                  if(_count == 1)
                  {
                     onTOUCH_equip = function(param1:TouchEvent):void
                     {
                        if(mlist && mlist.isScrolling)
                        {
                           return;
                        }
                        var _loc2_:Touch = param1.getTouch(_ui,"ended");
                        if(_loc2_ && hit(param1,_ui))
                        {
                           GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panelequipattrs",false,true,{
                              "id":k,
                              "isSoul":false
                           });
                        }
                     };
                     _ui = _equip.getRes();
                     _ui.addEventListener("touch",onTOUCH_equip);
                     _name = _equip.equipData.name;
                  }
                  _msg += _equip.equipData.name;
                  _check_in_msg += _equip.equipData.name;
                  if(_num > 1)
                  {
                     _msg += GlobalLanguageStr.getLanguageStr(20317,_num);
                  }
                  _check_in_msg += GlobalLanguageStr.getLanguageStr(20317,_num * 2);
                  _msg += ",";
                  _check_in_msg += ",";
               }
               _msg = _msg.slice(0,_msg.length - 1);
               _check_in_msg = _check_in_msg.slice(0,_check_in_msg.length - 1);
            }
            else
            {
               _num = 1;
               _equip = new Equip(_avatarId);
               _name = _equip.equipData.name;
               _msg = _equip.equipData.name;
               _ui = GlobalFunction.getEquipUI(_equip.equipData.res);
            }
         }
         else if(_type == "equip_soul")
         {
            onTOUCH_equip1 = function(param1:TouchEvent):void
            {
               if(mlist && mlist.isScrolling)
               {
                  return;
               }
               var _loc2_:Touch = param1.getTouch(_ui,"ended");
               if(_loc2_ && hit(param1,_ui))
               {
                  GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panelequipattrs",false,true,{
                     "id":equipId,
                     "isSoul":true
                  });
               }
            };
            for(ee in _avatarId)
            {
               equipId = ee;
               _num = int(_avatarId[ee]);
            }
            _equip = new Equip(equipId);
            _ui = GlobalFunction.getEquipUI(_equip.equipData.res);
            _ui.addEventListener("touch",onTOUCH_equip1);
            _name = _equip.equipData.name + GlobalLanguageStr.getLanguageStr(90586);
            _check_in_msg = _msg = GlobalLanguageStr.getLanguageStr(20205,_equip.getStar(),_equip.equipData.name) + GlobalLanguageStr.getLanguageStr(90586);
            if(_num > 1)
            {
               _msg = GlobalLanguageStr.getLanguageStr(20205,_equip.getStar(),_equip.equipData.name) + GlobalLanguageStr.getLanguageStr(90586) + GlobalLanguageStr.getLanguageStr(20317,_num);
            }
            else
            {
               _msg = GlobalLanguageStr.getLanguageStr(20205,_equip.getStar(),_equip.equipData.name) + GlobalLanguageStr.getLanguageStr(90586);
            }
            _check_in_msg = GlobalLanguageStr.getLanguageStr(20205,_equip.getStar(),_equip.equipData.name) + GlobalLanguageStr.getLanguageStr(90586) + GlobalLanguageStr.getLanguageStr(20317,_num * 2);
            _add_info = "\n（" + GlobalLanguageStr.getStr(90673) + "）";
            _msg += _add_info;
            _check_in_msg += _add_info;
            _icon = GlobalFunction.createImage("UI_icon_fragment_0000");
         }
         else if(_type == "equip_soul_random")
         {
            onTOUCH_Avatar7 = function(param1:TouchEvent):void
            {
               if(mlist && mlist.isScrolling)
               {
                  return;
               }
               var _loc2_:Touch = param1.getTouch(_ui);
               if(_loc2_ && _loc2_.phase == "ended" && hit(param1,_ui))
               {
                  GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr("show_equipsoul_random"),GlobalTextStyle.COLOR_W_Y_Y_G));
               }
            };
            _ui = GlobalFunction.createImage("UI_equip_random_0000") as DisplayObject;
            _icon = GlobalFunction.createImage("UI_icon_fragment_0000");
            _ui.addEventListener("touch",onTOUCH_Avatar7);
         }
         else if(_type == "_$vip$_")
         {
            if(GlobalFunction.checkIOSvip())
            {
               _check_in_msg = _msg = GlobalLanguageStr.getLanguageStr(20203,_avatarId);
            }
            else
            {
               _msg = "";
               _check_in_msg = "";
            }
            _ui = GlobalFunction.getVipImg(_avatarId,"1");
            _ui.addEventListener("touch",function(param1:TouchEvent):void
            {
               if(mlist && mlist.isScrolling)
               {
                  return;
               }
               if(param1.getTouch(_ui,"ended") && hit(param1,_ui))
               {
                  GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr("show_vip"),GlobalTextStyle.COLOR_W_Y_Y_G));
               }
            });
         }
         else if(_type == "exp")
         {
            _num = _avatarId;
            _name = GlobalLanguageStr.getLanguageStr(20379);
            _msg = _info + GlobalLanguageStr.getLanguageStr(20379) + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num));
            _check_in_msg = _info + GlobalLanguageStr.getLanguageStr(20379) + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num * 2));
            if(!_gift)
            {
               _ui = createImage("UI_award_ui_type_0007") as DisplayObject;
               _ui.addEventListener("touch",function(param1:TouchEvent):void
               {
                  if(param1.getTouch(_ui,"ended") && hit(param1,_ui))
                  {
                     GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr("show_exp"),GlobalTextStyle.COLOR_W_Y_Y_G));
                  }
               });
            }
         }
         else if(_type == "dust")
         {
            _valueType = 1;
            _dustStr = GlobalLanguageStr.getLanguageStr(90197);
            _dustArr = _dustStr.split("$");
            _index = 0;
            _info = " ";
            _num = int(_avatarId["numberIndex"]);
            if(_avatarId["indexID_s"] == undefined)
            {
               _check_in_msg = _msg = "";
               k = 0;
               while(k < _dustArr.length)
               {
                  if(_avatarId[k] != 0)
                  {
                     _num = int(_avatarId[k]);
                     _name = _dustArr[k];
                     _index = k;
                     _msg += _name + GlobalLanguageStr.getLanguageStr(20317,_num);
                     _check_in_msg += _name + GlobalLanguageStr.getLanguageStr(20317,_num * 2);
                  }
                  k += 1;
               }
               if(_index > 1)
               {
                  _valueType = 2;
               }
            }
            else
            {
               _num = int(_avatarId["numberIndex"]);
               _name = _dustArr[_avatarId["indexID_s"]];
               _msg = _info + _name + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num));
               _check_in_msg = _info + _name + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num * 2));
            }
            if(!_gift)
            {
               if(_avatarId["indexID_s"] == undefined)
               {
                  k = _index;
               }
               else
               {
                  k = _avatarId["indexID_s"];
               }
               ind = 12;
               _ui = createImage("UI_award_ui_type_00" + (k + ind)) as DisplayObject;
               _ui.addEventListener("touch",function(param1:TouchEvent):void
               {
                  if(mlist && mlist.isScrolling)
                  {
                     return;
                  }
                  if(param1.getTouch(_ui,"ended") && hit(param1,_ui))
                  {
                     GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr("show_dust"),GlobalTextStyle.COLOR_W_Y_Y_G));
                  }
               });
            }
         }
         else if(_type == "box")
         {
            _num = _avatarId;
            _name = GlobalLanguageStr.getLanguageStr(90186);
            _msg = GlobalLanguageStr.getLanguageStr(90186) + GlobalLanguageStr.getLanguageStr(20317,_num.toString());
            _check_in_msg = GlobalLanguageStr.getLanguageStr(90186) + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num * 2));
            if(!_gift)
            {
               _ui = createImage("UI_award_ui_type_0009") as DisplayObject;
               _ui.addEventListener("touch",function(param1:TouchEvent):void
               {
                  if(mlist && mlist.isScrolling)
                  {
                     return;
                  }
                  if(param1.getTouch(_ui,"ended") && hit(param1,_ui))
                  {
                     GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr("show_box"),GlobalTextStyle.COLOR_W_Y_Y_G));
                  }
               });
            }
         }
         else if(_type == "fragment")
         {
            _num = 1;
            _name = GlobalLanguageStr.getLanguageStr(20429);
            _check_in_msg = _msg = GlobalLanguageStr.getLanguageStr(20429);
            if(!_gift)
            {
               eid = "";
               fraIndex = 0;
               for(ei in _avatarId)
               {
                  eid = ei;
                  len = int(_avatarId[ei].length);
                  framents = _avatarId[ei];
                  j = 0;
                  while(j < len)
                  {
                     if(framents[j] == 1)
                     {
                        fraIndex = j;
                        break;
                     }
                     j += 1;
                  }
               }
               data = {};
               data["id"] = new Equip(eid).equipData.id;
               data["fragmentType"] = "fragment";
               data["data_base"] = _avatarId[eid];
               fr = new Fragment(eid);
               fr.fragIndex = fraIndex;
               _ui = fr.getFragRes();
               _ui.addEventListener("touch",function(param1:TouchEvent):void
               {
                  if(mlist && mlist.isScrolling)
                  {
                     return;
                  }
                  if(param1.getTouch(_ui,"ended") && hit(param1,_ui))
                  {
                     GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_chip_info",false,true,data);
                  }
               });
            }
         }
         else if(_type == "key")
         {
            _num = _avatarId;
            _name = GlobalLanguageStr.getLanguageStr(90187);
            _msg = GlobalLanguageStr.getLanguageStr(90187) + GlobalLanguageStr.getLanguageStr(20317,_num);
            _check_in_msg = GlobalLanguageStr.getLanguageStr(90187) + GlobalLanguageStr.getLanguageStr(20317,_num * 2);
            if(!_gift)
            {
               _ui = createImage("UI_award_ui_type_0010") as DisplayObject;
               _ui.addEventListener("touch",function(param1:TouchEvent):void
               {
                  if(mlist && mlist.isScrolling)
                  {
                     return;
                  }
                  if(param1.getTouch(_ui,"ended") && hit(param1,_ui))
                  {
                     GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr("show_key"),GlobalTextStyle.COLOR_W_Y_Y_G));
                  }
               });
            }
         }
         else if(_type == "culture_book")
         {
            _num = _avatarId;
            _name = GlobalLanguageStr.getLanguageStr(90562);
            _msg = _info + GlobalLanguageStr.getLanguageStr(90562) + GlobalLanguageStr.getLanguageStr(20317,_num);
            _check_in_msg = _info + GlobalLanguageStr.getLanguageStr(90562) + GlobalLanguageStr.getLanguageStr(20317,_num * 2);
            _ui = createImage("UI_award_ui_type_0016") as DisplayObject;
            _ui.addEventListener("touch",function(param1:TouchEvent):void
            {
               if(mlist && mlist.isScrolling)
               {
                  return;
               }
               if(param1.getTouch(_ui,"ended") && hit(param1,_ui))
               {
                  GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90593),GlobalTextStyle.COLOR_W_Y_Y_G));
               }
            });
         }
         else if(_type == "guild_money" || _type == "guild_currency")
         {
            _num = _avatarId;
            _valueType = 1;
            _name = GlobalLanguageStr.getLanguageStr(97813);
            _msg = GlobalLanguageStr.getLanguageStr(97813) + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num));
            _check_in_msg = GlobalLanguageStr.getLanguageStr(97813) + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num * 2));
            if(!_gift)
            {
               _ui = createImage("UI_award_ui_type_0018") as DisplayObject;
               _ui.addEventListener("touch",function(param1:TouchEvent):void
               {
                  if(mlist && mlist.isScrolling)
                  {
                     return;
                  }
                  if(param1.getTouch(_ui,"ended") && hit(param1,_ui))
                  {
                     GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr("show_guild_money"),GlobalTextStyle.COLOR_W_Y_Y_G));
                  }
               });
            }
         }
         else if(_type == "guild_contribute")
         {
            _num = _avatarId;
            _valueType = 1;
            _name = GlobalLanguageStr.getLanguageStr(90792);
            _msg = GlobalLanguageStr.getLanguageStr(90792) + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num));
            _check_in_msg = GlobalLanguageStr.getLanguageStr(90792) + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num * 2));
            if(!_gift)
            {
               _ui = createImage("UI_award_ui_type_0020") as DisplayObject;
               _ui.addEventListener("touch",function(param1:TouchEvent):void
               {
                  if(mlist && mlist.isScrolling)
                  {
                     return;
                  }
                  if(param1.getTouch(_ui,"ended") && hit(param1,_ui))
                  {
                     GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr("show_guild_contribute"),GlobalTextStyle.COLOR_W_Y_Y_G));
                  }
               });
            }
         }
         else if(_type == "guild_skill")
         {
            _num = _avatarId;
            _valueType = 1;
            _name = GlobalLanguageStr.getLanguageStr(90793);
            _msg = GlobalLanguageStr.getLanguageStr(90793);
            _check_in_msg = GlobalLanguageStr.getLanguageStr(90793);
            if(!_gift)
            {
               _ui = GlobalFunction.createImage("UI_research_money_0_000" + _avatarId) as DisplayObject;
               _ui.addEventListener("touch",function(param1:TouchEvent):void
               {
                  if(mlist && mlist.isScrolling)
                  {
                     return;
                  }
                  if(param1.getTouch(_ui,"ended") && hit(param1,_ui))
                  {
                     GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr("show_guild_skillStudy"),GlobalTextStyle.COLOR_W_Y_Y_G));
                  }
               });
            }
         }
         else if(_type == "sp")
         {
            _valueType = 1;
            _spStr = GlobalLanguageStr.getLanguageStr(98028);
            _spArr = _spStr.split("$");
            index = 0;
            _info = " ";
            _num = int(_avatarId["numberIndex"]);
            if(_avatarId["indexID_s"] == undefined)
            {
               _check_in_msg = _msg = "";
               k = 0;
               while(k < _spArr.length)
               {
                  if(_avatarId[k] != 0)
                  {
                     _num = int(_avatarId[k]);
                     _name = _spArr[k];
                     index = k;
                     _msg += _name + GlobalLanguageStr.getLanguageStr(20317,_num);
                     _check_in_msg += _name + GlobalLanguageStr.getLanguageStr(20317,_num * 2);
                  }
                  k += 1;
               }
               if(index > 1)
               {
                  _valueType = 2;
               }
            }
            else
            {
               _num = int(_avatarId["numberIndex"]);
               _name = _spArr[_avatarId["indexID_s"]];
               _msg = _info + _name + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num));
               _check_in_msg = _info + _name + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num * 2));
            }
            if(!_gift)
            {
               if(_avatarId["indexID_s"] == undefined)
               {
                  k = index;
               }
               else
               {
                  k = _avatarId["indexID_s"];
               }
               _ui = createImage("UI_soulStone_ui_type_000" + k) as DisplayObject;
               _ui.addEventListener("touch",function(param1:TouchEvent):void
               {
                  if(mlist && mlist.isScrolling)
                  {
                     return;
                  }
                  if(param1.getTouch(_ui,"ended") && hit(param1,_ui))
                  {
                     GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr("show_sp"),GlobalTextStyle.COLOR_W_Y_Y_G));
                  }
               });
            }
         }
         else if(_type == "score_vip")
         {
            _num = _avatarId;
            _valueType = 1;
            _name = GlobalLanguageStr.getLanguageStr(96567);
            _msg = GlobalLanguageStr.getLanguageStr(96567) + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num));
            _check_in_msg = GlobalLanguageStr.getLanguageStr(96567) + GlobalLanguageStr.getLanguageStr(20317,Tools.formateNum(_num * 2));
            if(!_gift)
            {
               _ui = createImage("UI_award_ui_type_0019") as DisplayObject;
               _ui.addEventListener("touch",function(param1:TouchEvent):void
               {
                  if(mlist && mlist.isScrolling)
                  {
                     return;
                  }
                  if(param1.getTouch(_ui,"ended") && hit(param1,_ui))
                  {
                     GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr("show_score_vip"),GlobalTextStyle.COLOR_W_Y_Y_G));
                  }
               });
            }
         }
         if(_ui)
         {
            w = _ui.width;
            h = _ui.height;
            if(scaleXY != -1)
            {
               _ui.scaleX = _ui.scaleY = scaleXY;
            }
         }
         if(_num > 1 && _ui)
         {
            uu = new starling.display.Sprite();
            uu.addChild(_ui);
            _numStr = "";
            if(_type == "gold" || _type == "coin")
            {
               _numStr = GlobalLanguageStr.getLanguageStr(20193) + Tools.formateNum(_num);
            }
            else
            {
               _numStr = GlobalLanguageStr.getLanguageStr(20193) + _num;
            }
            _t = new LOL_TextField(_numStr,_ui.width,25);
            _t.fontColor = 16777215;
            _t.hAlign = "center";
            _t.x = (_ui.width - _t.getWidth()) / 2 - 5;
            _t.shadowFilter();
            if(_type == "avatar" || _type == "avatar_soul")
            {
               _t.y = _ui.y + _ui.height - _t.getHeight() / 2 - 10;
            }
            else
            {
               _t.y = _ui.y + _ui.height - _t.getHeight() / 2;
            }
            _t.visible = isNumVisible;
            if(_type == "guild_skill")
            {
               _t.visible = false;
            }
            uu.addChild(_t);
            if(_icon)
            {
               uu.addChild(_icon);
               _icon.x = _ui.width / 2 - _icon.width + 46;
               _icon.y = uu.y - 10;
               _icon.touchable = false;
               if(_type == "equip_soul" || _type == "equip_soul_random")
               {
                  _icon.x += 5;
               }
               if(scaleXY != -1)
               {
                  _icon.scaleX = _icon.scaleY = scaleXY;
               }
            }
            return {
               "ui":uu,
               "num":_num,
               "msg":_msg,
               "baseName":_name,
               "vType":_valueType,
               "width":w,
               "height":h,
               "type":_type,
               "text":_t,
               "check_in_msg":_check_in_msg
            };
         }
         if(_icon)
         {
            ss = new starling.display.Sprite();
            ss.addChild(_ui);
            ss.addChild(_icon);
            if(_type == "avatar_soul" || _type == "avatar_soul_random")
            {
               _icon.x = _ui.width / 2 - _icon.width + 46;
            }
            if(_type == "equip_soul" || _type == "equip_soul_random")
            {
               _icon.x = _ui.width - _icon.width + 5;
            }
            _icon.y = _ui.y - 10;
            _icon.touchable = false;
            if(scaleXY != -1)
            {
               _icon.scaleX = _icon.scaleY = scaleXY;
            }
            return {
               "ui":ss,
               "num":_num,
               "msg":_msg,
               "baseName":_name,
               "vType":_valueType,
               "width":w,
               "height":h,
               "type":_type,
               "text":_t,
               "check_in_msg":_check_in_msg
            };
         }
         _ss = new starling.display.Sprite();
         _ss.addChild(_ui);
         return {
            "ui":_ss,
            "num":_num,
            "msg":_msg,
            "baseName":_name,
            "vType":_valueType,
            "width":w,
            "height":h,
            "type":_type,
            "text":_t,
            "check_in_msg":_check_in_msg
         };
      }
      
      public static function tipsOS_ios(param1:String, param2:String, param3:String = "OK", param4:Function = null, param5:String = null, param6:Function = null, param7:Function = null) : void
      {
         if(param4 && !param6)
         {
            popAlert(param1,param2,{
               "ok":param4,
               "okUI":param3,
               "close":param7
            },true);
         }
         else
         {
            if(!param6)
            {
               param6 = GlobalFunction.functionNull;
            }
            if(!param5)
            {
               param5 = GlobalLanguageStr.getLanguageStr(20121);
            }
            popAlert(param1,param2,{
               "ok":param4,
               "okUI":param3,
               "no":param6,
               "noUI":param5,
               "close":param7
            },true);
         }
      }
      
      public static function check_isApplePay() : Boolean
      {
         var _loc1_:Boolean = false;
         if(GlobalLocalStore.$pf_type_curr == "idpios" || GlobalLocalStore.$pf_type_curr == "rkios" || GlobalLocalStore.$pf_type_curr == "rkjs" || GlobalLocalStore.$pf_type_curr == "ios1006")
         {
            _loc1_ = true;
         }
         return _loc1_;
      }
      
      public static function check_isHadTOKEN() : Boolean
      {
         var _loc1_:Boolean = false;
         if(GlobalLocalStore.$pf_type_curr == "idpios" || GlobalLocalStore.$pf_type_curr == "rkios" || GlobalLocalStore.$pf_type_curr == "rkjs" || GlobalLocalStore.$pf_type_curr == "gatios" || GlobalLocalStore.$pf_type_curr == "ios1006")
         {
            _loc1_ = true;
         }
         return _loc1_;
      }
      
      public static function levelup() : void
      {
         var _loc2_:int = 0;
         var _loc1_:String = null;
         if(GlobalData.$userData.attrs.comment_gift != true)
         {
            if(GlobalData.$mConfig_simple.pf_comment_lv)
            {
               _loc2_ = int(GlobalData.$mConfig_simple.pf_comment_lv[0]);
               if(GlobalData.$userData.lv % _loc2_ == 0 && GlobalData.$userData.lv != 0)
               {
                  _loc1_ = GlobalLocalStore.getIOSComment();
                  if(_loc1_ == "")
                  {
                     popAppleComment();
                  }
               }
            }
         }
      }
      
      public static function popAppleComment(param1:Boolean = true) : void
      {
         var _title:String;
         var _fCfg:Object;
         var _url:Boolean = param1;
         var comment:* = function():void
         {
            send_comment_gift();
            try
            {
               navigateToURL(new URLRequest(GlobalData.$mConfig_client.pf_comment_url[GlobalLocalStore.$pf_type_curr]),"_blank");
            }
            catch(_error:Error)
            {
            }
         };
         var closeComment:* = function():void
         {
            GlobalLocalStore.setIOSComment("closeComment");
         };
         var send_comment_gift:* = function():void
         {
            SendServiceAMFFun.send_user_comment_gift(reFun_commont_gift);
         };
         var reFun_commont_gift:* = function(param1:Object):void
         {
            var _loc6_:int = int(param1.data);
            var _loc5_:Object = GlobalData.$mConfig_simple.pf_comment_lv[1];
            var _loc2_:Object = null;
            var _loc3_:Object = null;
            var _loc4_:String = "";
            GlobalData.$userData.attrs.comment_gift = true;
            for(_loc3_ in _loc5_)
            {
               _loc4_ = _loc3_.toString();
               _loc2_ = GlobalFunction.getAwardByType(_loc4_,_loc5_[_loc3_]);
               GlobalFunction.popAward(_loc4_,_loc2_.msg,_loc5_[_loc3_]);
            }
            if(_loc4_ == "coin")
            {
               GlobalData.$userData.coin = _loc6_;
               GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
            }
            else if(_loc4_ == "gold")
            {
               GlobalData.$userData.gold = _loc6_;
               GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
            }
            else if(_loc4_ == "medal")
            {
               GlobalData.$userData.medal = _loc6_;
            }
            if(GlobalData.$mGameClassObject && GlobalData.$mGameClassObject.mLayoutUICenter && GlobalData.$mGameClassObject.mLayoutUICenter.mPanelCenterHelp)
            {
            }
            GlobalData.$mEventDispatcher.dispatchEventWith("update_avatar_award");
            GlobalData.$mEventDispatcher.dispatchEventWith("update_hele_comment_gift_fun");
         };
         if(GlobalData.$mConfig_client["pf_comment_url"] == null)
         {
            return;
         }
         if(GlobalData.$mConfig_client.pf_comment_url[GlobalLocalStore.$pf_type_curr] == null)
         {
            return;
         }
         if(_url)
         {
            _title = GlobalLanguageStr.getLanguageStr(90010);
            _fCfg = {
               "ok":closeComment,
               "okUI":GlobalLanguageStr.getLanguageStr(90173),
               "append":functionNull,
               "appendUI":GlobalLanguageStr.getLanguageStr(90176),
               "no":comment,
               "noUI":GlobalLanguageStr.getLanguageStr(90175)
            };
            popAlert(_title,Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90159),GlobalTextStyle.COLOR_W_Y_Y_G),_fCfg);
         }
         else
         {
            comment();
         }
      }
      
      public static function setWebView(param1:String, param2:Function, param3:Function = null) : void
      {
         var _webBg:flash.display.Sprite;
         var _class:Class;
         var _btn:MovieClip;
         var _gap:Number;
         var _h:Number;
         var _rec:Rectangle;
         var onMOUSE_DOWN:*;
         var onREMOVED_FROM_STAGE:*;
         var _url:String = param1;
         var _callBack:Function = param2;
         var _closeCallBack:Function = param3;
         delWebView();
         if(GlobalData.$mStarling)
         {
            onMOUSE_DOWN = function(param1:MouseEvent):void
            {
               delWebView();
               if(_closeCallBack != null)
               {
                  _closeCallBack();
               }
            };
            onREMOVED_FROM_STAGE = function(param1:flash.events.Event):void
            {
               param1.currentTarget.removeEventListener("removedFromStage",onREMOVED_FROM_STAGE);
               param1.currentTarget.removeEventListener("mouseDown",onMOUSE_DOWN);
            };
            _webBg = new flash.display.Sprite();
            _webBg.name = "_web_name_bg_";
            _webBg.graphics.beginFill(0,0.75);
            _webBg.graphics.drawRect(0,0,GlobalData.$fullScreenWidth,GlobalData.$fullScreenHeight);
            _webBg.graphics.endFill();
            _class = getDefinitionByName("A_web_btn_close") as Class;
            _btn = new _class() as MovieClip;
            GlobalData.$mStarling.nativeStage.addChild(_webBg);
            _gap = 50;
            _h = GlobalData.$mStageHeight - _gap;
            _rec = new Rectangle(GlobalData.$isNotFullScreenX,_gap * GlobalData.$mStage$Starling_h,GlobalData.$mStageWidth * GlobalData.$mStage$Starling_w,_h * GlobalData.$mStage$Starling_h);
            _btn.x = _gap;
            _btn.y = int((_gap - _btn.height) * 0.5);
            _btn.addEventListener("mouseDown",onMOUSE_DOWN);
            _btn.addEventListener("removedFromStage",onREMOVED_FROM_STAGE);
            _webBg.addChild(_btn);
            GlobalData.$stageWebViewBase = new StageWebViewBase(GlobalData.$mStarling.nativeStage,_url,_rec,_callBack);
         }
      }
      
      public static function delWebView() : void
      {
         var _loc1_:flash.display.Sprite = null;
         if(GlobalData.$mStarling)
         {
            if(GlobalData.$mStarling.nativeStage.getChildByName("_web_name_bg_"))
            {
               _loc1_ = GlobalData.$mStarling.nativeStage.getChildByName("_web_name_bg_") as flash.display.Sprite;
               _loc1_.removeChildren();
               GlobalData.$mStarling.nativeStage.removeChild(_loc1_);
            }
         }
         if(GlobalData.$stageWebViewBase)
         {
            GlobalData.$stageWebViewBase.clear();
         }
         GlobalData.$stageWebViewBase = null;
      }
      
      public static function webCallBack(param1:String) : void
      {
         var _loc12_:int = 0;
         var _loc3_:String = "=";
         var _loc9_:String = param1;
         var _loc6_:Array = String(_loc9_.split("#")[1]).split("&");
         var _loc11_:String = "";
         var _loc8_:String = "";
         var _loc5_:String = "";
         var _loc2_:String = "";
         var _loc7_:String = "";
         var _loc10_:String = "";
         var _loc4_:String = "";
         _loc12_ = 0;
         while(_loc12_ < _loc6_.length)
         {
            _loc4_ = _loc6_[_loc12_];
            if(_loc4_.indexOf("access_token=") >= 0)
            {
               _loc11_ = _loc4_.split(_loc3_)[1];
            }
            if(_loc4_.indexOf("expires_in=") >= 0)
            {
               _loc8_ = _loc4_.split(_loc3_)[1];
            }
            if(_loc4_.indexOf("remind_in=") >= 0)
            {
               _loc5_ = _loc4_.split(_loc3_)[1];
            }
            if(_loc4_.indexOf("uid=") >= 0)
            {
               _loc2_ = _loc4_.split(_loc3_)[1];
            }
            if(_loc4_.indexOf("openid=") >= 0)
            {
               _loc7_ = _loc4_.split(_loc3_)[1];
            }
            if(_loc4_.indexOf("refresh_token=") >= 0)
            {
               _loc10_ = _loc4_.split(_loc3_)[1];
            }
            _loc12_++;
         }
         if(_loc11_ != "")
         {
            if(GlobalData.$weiboBinding)
            {
            }
         }
      }
      
      public static function checkIsPayOnly() : Boolean
      {
         var _loc1_:Boolean = false;
         return getPayOnlyStatus() != GlobalData.$userData.attrs.pay_first;
      }
      
      public static function getPayOnlyStatus() : String
      {
         var _loc1_:Array = GlobalData.$mConfig_zones[GlobalData.$mServiceID];
         var _loc2_:String = _loc1_[3];
         return _loc2_ == null ? "" : _loc2_;
      }
      
      public static function checkIsPayMon30(param1:String) : Boolean
      {
         var _loc2_:String = null;
         var _loc4_:Boolean = false;
         var _loc5_:int = int(GlobalData.$mConfig_client.pay_fun_30 ? GlobalData.$mConfig_client.pay_fun_30 : 0);
         var _loc3_:Object = GlobalData.$mConfig_simple.mon_card as Object;
         for(var _loc6_:String in _loc3_)
         {
            _loc2_ = _loc6_;
            if(param1 == _loc2_ && !checkIsPayOnly() && _loc5_ > 0)
            {
               _loc4_ = true;
            }
         }
         return _loc4_;
      }
      
      public static function getSYS_music() : Boolean
      {
         var _loc1_:Boolean = false;
         var _loc3_:int = 0;
         var _loc2_:Object = GlobalData.$localMusic;
         if(GlobalData.$localMusic)
         {
            if(GlobalData.$localMusic.music)
            {
               _loc3_ = int(GlobalData.$localMusic.music);
            }
         }
         return _loc3_ == 1;
      }
      
      public static function getSYS_sound() : Boolean
      {
         var _loc1_:Boolean = false;
         var _loc2_:int = 0;
         if(GlobalData.$localMusic)
         {
            if(GlobalData.$localMusic.sound)
            {
               _loc2_ = int(GlobalData.$localMusic.sound);
            }
         }
         return _loc2_ == 1;
      }
      
      public static function getWagerScoreTimes() : Number
      {
         var _loc2_:Array = GlobalData.$mConfig_simple.wager_avatar as Array;
         var _loc3_:Number = Number(GlobalData.$userData.score);
         var _loc1_:Number = Math.floor(_loc3_ / _loc2_[2]);
         return isNaN(_loc1_) ? 0 : _loc1_;
      }
      
      public static function getWagerCoinTimes() : Number
      {
         var _loc2_:Array = GlobalData.$mConfig_simple.wager_avatar as Array;
         var _loc3_:Number = Number(GlobalData.$userData.coin);
         var _loc1_:Number = Math.floor(_loc3_ / _loc2_[0]);
         return isNaN(_loc1_) ? 0 : _loc1_;
      }
      
      public static function getTagPopTip(param1:int, param2:Boolean = true) : starling.display.Sprite
      {
         var _loc3_:starling.display.Sprite = new starling.display.Sprite();
         _loc3_.touchable = false;
         var _loc4_:Image = createImage("UI_tag_6_0000");
         _loc3_.addChild(_loc4_);
         var _loc5_:LOL_TextField = new LOL_TextField("",_loc4_.width,_loc4_.height);
         _loc5_.fontColor = 16777215;
         _loc5_.fontSize = 15;
         _loc5_.hAlign = "center";
         _loc3_.addChild(_loc5_);
         if(param1 > 9)
         {
            _loc5_.text = "N";
         }
         else
         {
            _loc5_.text = param1 + "";
         }
         if(param1 > 0)
         {
            _loc4_.visible = true;
            _loc5_.visible = true;
            _loc5_.visible = param2;
         }
         else
         {
            _loc4_.visible = false;
            _loc5_.visible = false;
         }
         return _loc3_;
      }
      
      public static function setWagerTime(param1:String, param2:LOL_TimeStatus, param3:int = 0, param4:Function = null, param5:Object = null) : LOL_TimeStatus
      {
         var _loc9_:* = null;
         var _loc14_:Boolean = false;
         var _loc11_:Number = GlobalData.$mConfig_simple.wager_free[param3] * 60;
         var _loc12_:Date = param3 == 0 ? GlobalData.$userData.attrs.wager_free_score as Date : GlobalData.$userData.attrs.wager_free_coin as Date;
         var _loc13_:Number = _loc12_.time * 0.001 + _loc11_;
         var _loc6_:Number = SendAndSelect.$systemTimer_nowSecond;
         var _loc7_:Number = _loc13_ - SendAndSelect.$systemTimer_nowSecond;
         var _loc8_:String = "_date_";
         _loc14_ = _loc7_ > 0 ? true : false;
         StarlingTools.removeChildrenClear(param2);
         if(param2)
         {
            param2.dispose();
         }
         var _loc10_:LOL_TimeStatus = new LOL_TimeStatus(param1);
         _loc10_.touchable = false;
         _loc10_.refresh(_loc7_,""," ",param4,GlobalLanguageStr.getStr(90442),true);
         _loc10_.visible = _loc14_;
         return _loc10_;
      }
      
      public static function checkWagerTime(param1:int = 0) : Number
      {
         var _loc3_:Number = GlobalData.$mConfig_simple.wager_free[param1] * 60;
         var _loc4_:Date = param1 == 0 ? GlobalData.$userData.attrs.wager_free_score as Date : GlobalData.$userData.attrs.wager_free_coin as Date;
         var _loc5_:Number = _loc4_.time * 0.001 + _loc3_;
         var _loc2_:Number = SendAndSelect.$systemTimer_nowSecond;
         return _loc5_ - SendAndSelect.$systemTimer_nowSecond;
      }
      
      public static function checkIOSvip() : Boolean
      {
         var _loc1_:Boolean = false;
         if(GlobalData.$mConfig_client.is_vip != null)
         {
            if(int(GlobalData.$mConfig_client.is_vip) != 0)
            {
               _loc1_ = true;
            }
         }
         return _loc1_;
      }
      
      public static function formateConfig(param1:Object) : void
      {
         if(GlobalData.$mConfig == null)
         {
            GlobalData.$mConfig = {};
         }
         if(param1 != null)
         {
            for(var _loc2_:Object in param1)
            {
               GlobalData.$mConfig[_loc2_.toString()] = param1[_loc2_];
            }
         }
      }
      
      public static function check_noPayList() : Boolean
      {
         var _loc1_:Boolean = false;
         if(GlobalLocalStore.$pf_type_curr == "gatios" || GlobalLocalStore.$pf_type_curr == "gatad")
         {
            _loc1_ = true;
         }
         return _loc1_;
      }
      
      public static function get_pf_selfServierID(param1:String) : String
      {
         var _loc3_:String = "";
         if(GlobalLocalStore.$pf_type_curr == "gatios" || GlobalLocalStore.$pf_type_curr == "gatad")
         {
            _loc3_ = "lol";
         }
         return param1 == "" ? "" : param1.split(_loc3_)[1];
      }
      
      public static function check_pf_useMeng52Service() : Boolean
      {
         var _loc1_:Boolean = true;
         if(GlobalLocalStore.$pf_type_curr == "gatios" || GlobalLocalStore.$pf_type_curr == "gatad")
         {
            _loc1_ = false;
         }
         return _loc1_;
      }
      
      public static function check_useMeng52ID() : Boolean
      {
         var _loc1_:Boolean = false;
         if(GlobalData.$mConfig_client.self_login != null && GlobalData.$mConfig_client.self_login != 0 || GlobalLocalStore.$pf_type_curr == "local" || GlobalStaticConst.$isIOS && GlobalLocalStore.$pf_type_curr == "idpun" || GlobalLocalStore.$pf_type_curr == "rkjsad" || GlobalLocalStore.$pf_type_curr == "rkad" || GlobalLocalStore.$pf_type_curr == "jinsad" || GlobalLocalStore.getPF_dtaib(GlobalLocalStore.$pf_type_curr) || GlobalLocalStore.$pf_type_curr == "sgno1" || GlobalLocalStore.$pf_type_curr == "rkafw" || GlobalLocalStore.$pf_type_curr == "sytx" || GlobalLocalStore.$pf_type_curr == "rkdx" || GlobalLocalStore.$pf_type_curr == "dtczk" || GlobalLocalStore.$pf_type_curr == "1006ad" || GlobalStaticConst.$isIOS && GlobalLocalStore.$pf_type_curr == "rkjsun" || GlobalStaticConst.$isIOS && GlobalLocalStore.$pf_type_curr == "rkios" || GlobalStaticConst.$isIOS && GlobalLocalStore.$pf_type_curr == "rkjs" || GlobalStaticConst.$isIOS && GlobalLocalStore.$pf_type_curr == "rkun" || GlobalStaticConst.$isIOS && GlobalLocalStore
         .$pf_type_curr == "idpios" || GlobalStaticConst.$isIOS && GlobalLocalStore.$pf_type_curr == "ios1006" || GlobalStaticConst.$isIOS && GlobalLocalStore.$pf_type_curr == "rkndw" || GlobalLocalStore.$pf_type_curr == "banshu")
         {
            _loc1_ = true;
         }
         if(GlobalLocalStore.$pf_type_curr == "qihoo" || GlobalLocalStore.$pf_type_curr == "dtqh" || GlobalLocalStore.$pf_type_curr == "rkky" || GlobalLocalStore.$pf_type_curr == "rk91" || GlobalLocalStore.$pf_type_curr == "rk91ios" || GlobalLocalStore.$pf_type_curr == "rkuc" || GlobalLocalStore.$pf_type_curr == "dtuc" || GlobalLocalStore.$pf_type_curr == "dtdl" || GlobalLocalStore.$pf_type_curr == "dtxm" || GlobalLocalStore.$pf_type_curr == "dtbd" || GlobalLocalStore.$pf_type_curr == "dtoppo" || GlobalLocalStore.$pf_type_curr == "dthw" || GlobalLocalStore.$pf_type_curr == "dtfl" || GlobalLocalStore.$pf_type_curr == "rkwdj" || GlobalLocalStore.$pf_type_curr == "dtwdj" || GlobalLocalStore.$pf_type_curr == "rkxm" || GlobalLocalStore.$pf_type_curr == "rkaz" || GlobalLocalStore.$pf_type_curr == "dtaz" || GlobalLocalStore.$pf_type_curr == "dtlenovo" || GlobalLocalStore.$pf_type_curr == "rk37w" || GlobalLocalStore.$pf_type_curr == "rk37wmz" || GlobalLocalStore.$pf_type_curr == "rkbd" || GlobalLocalStore
         .$pf_type_curr == "tlios" || GlobalLocalStore.$pf_type_curr == "gatios" || GlobalLocalStore.$pf_type_curr == "gatad" || GlobalLocalStore.$pf_type_curr == "rkjf" || GlobalLocalStore.$pf_type_curr == "hgkt" || GlobalLocalStore.$pf_type_curr == "hgtstore" || GlobalLocalStore.$pf_type_curr == "hgnaver" || GlobalLocalStore.$pf_type_curr == "ChinaMove" || GlobalLocalStore.$pf_type_curr == "rkhw" || GlobalLocalStore.$pf_type_curr == "hggoogle" || GlobalStaticConst.$isIOS && GlobalLocalStore.$pf_type_curr == "rkpp" || GlobalStaticConst.$isIOS && GlobalLocalStore.$pf_type_curr == "rkit" || GlobalStaticConst.$isIOS && GlobalLocalStore.$pf_type_curr == "rki4" || GlobalLocalStore.$pf_type_curr == "rkppw" || GlobalLocalStore.$pf_type_curr == "dnyios" || GlobalLocalStore.$pf_type_curr == "dnyad" || GlobalLocalStore.$pf_type_curr == "7k7k" || GlobalLocalStore.$pf_type_curr == "bfyy" || GlobalLocalStore.$pf_type_curr == "anfeng" || GlobalLocalStore.$pf_type_curr == "gameBaby" || GlobalLocalStore.$pf_type_curr == "kugou" || GlobalLocalStore
         .$pf_type_curr == "sougou1" || GlobalLocalStore.$pf_type_curr == "sougou2" || GlobalLocalStore.$pf_type_curr == "sougou3" || GlobalLocalStore.$pf_type_curr == "dnyad" || GlobalLocalStore.$pf_type_curr == "rkdk")
         {
            _loc1_ = false;
         }
         return _loc1_;
      }
      
      public static function check_awardCode() : Boolean
      {
         var _loc1_:Boolean = false;
         if(GlobalData.$mConfig_client.award_code != null && GlobalData.$mConfig_client.award_code != 0)
         {
            _loc1_ = true;
         }
         return _loc1_;
      }
      
      public static function check_loginUidIsStatic() : Boolean
      {
         var _loc1_:Boolean = false;
         var _loc2_:String = GlobalLocalStore.getMeng52UID();
         var _loc3_:String = GlobalLocalStore.getMeng52PW();
         if(_loc2_ && _loc3_)
         {
            _loc1_ = true;
         }
         return _loc1_;
      }
      
      public static function check_ownQuickInfo() : Boolean
      {
         var _loc2_:Boolean = false;
         var _loc1_:String = GlobalLocalStore.getQuickUID();
         var _loc3_:String = GlobalLocalStore.getQuickPW();
         if(_loc1_ && _loc3_)
         {
            _loc2_ = true;
         }
         return _loc2_;
      }
      
      public static function checkIs_quickUser() : Boolean
      {
         var _loc3_:Boolean = false;
         var _loc1_:String = GlobalLocalStore.getQuickUID();
         var _loc5_:String = GlobalLocalStore.getQuickPW();
         var _loc4_:String = GlobalLocalStore.$pf_token_curr;
         var _loc2_:String = GlobalLocalStore.$pf_uid_curr;
         if(_loc4_ == _loc1_ && _loc2_ == _loc5_)
         {
            _loc3_ = true;
         }
         return _loc3_;
      }
      
      public static function check_isSysErrorTips(param1:String) : Boolean
      {
         var _loc2_:Boolean = false;
         if(param1 == "user.bind" || param1 == "user.default_register" || param1 == "user.llogin" || param1 == "user.register" || param1 == "user.get_reward_by_code")
         {
            _loc2_ = true;
         }
         return _loc2_;
      }
      
      public static function getBgImgXY(param1:Number, param2:Number) : Object
      {
         var _loc6_:Number = 2046;
         var _loc5_:Number = 2046;
         var _loc4_:Number = 640;
         var _loc3_:Number = 1136;
         return {
            "x":param1 + (_loc6_ - _loc4_) * 0.5,
            "y":param2 + (_loc5_ - _loc3_) * 0.5
         };
      }
      
      public static function setGameSoundInit(param1:Boolean = false) : void
      {
         var _loc2_:Object = GlobalLocalStore.getCurrMusic();
         if(_loc2_)
         {
            GlobalData.$localMusic = _loc2_;
         }
         else
         {
            GlobalLocalStore.setCurrMusic(GlobalData.$localMusic);
         }
         SoundManager.getOnlyExample().setMusic(getSYS_music());
         SoundManager.getOnlyExample().setSound(getSYS_sound());
         if(param1)
         {
            if(MainConfig.$isPlayMusicTheme)
            {
               SoundManager.getOnlyExample().stopMusic(false);
               SoundManager.getOnlyExample().playMusic(SoundManager.SOUND_LOADING);
            }
         }
         else
         {
            SoundManager.getOnlyExample().stopMusic(false);
            SoundManager.getOnlyExample().playMusic(SoundManager.SOUND_MAIN);
         }
      }
      
      public static function getPveTypeById(param1:int) : String
      {
         var _loc2_:String = "";
         if(param1 == 0)
         {
            _loc2_ = "status_pve_normal";
         }
         else if(param1 == 1)
         {
            _loc2_ = "status_pve_hard";
         }
         else if(param1 == 2)
         {
            _loc2_ = "status_pve_activities";
         }
         else
         {
            _loc2_ = "status_pve_guild";
         }
         return _loc2_;
      }
      
      public static function getPveBattleCfg(param1:String) : Object
      {
         if(param1 == "status_pve_normal")
         {
            return GlobalData.$config_battle_main;
         }
         if(param1 == "status_pve_hard")
         {
            return GlobalData.$config_battle_main;
         }
         if(param1 == "status_pve_activities")
         {
            return GlobalData.$mConfig_battle_ploy;
         }
         if(param1 == "status_pve_guild")
         {
            return GlobalData.$config_battle_association;
         }
         return null;
      }
      
      public static function getBattleNameById(param1:String, param2:Boolean = false) : String
      {
         var _loc4_:String = "";
         var _loc3_:Object = null;
         if(!param2)
         {
            _loc3_ = GlobalData.$config_battle_main;
         }
         else
         {
            _loc3_ = GlobalData.$mConfig_battle_ploy;
         }
         for(var _loc5_:Object in _loc3_)
         {
            if(_loc5_.toString() == param1)
            {
               _loc4_ = _loc3_[_loc5_].name;
            }
         }
         return _loc4_;
      }
      
      public static function getBattleStarById(param1:String, param2:String) : String
      {
         var _loc9_:int = 0;
         var _loc7_:String = "";
         var _loc4_:int = 0;
         var _loc6_:int = 0;
         var _loc5_:Object = null;
         var _loc3_:Object = null;
         _loc5_ = getPveBattleCfg(param2);
         var _loc8_:Object = GlobalData.$userData;
         var _loc10_:Array = [16777215,16764006,16764006,16764006];
         if(GlobalData.$tempPVE_type == "status_pve_normal")
         {
            _loc3_ = GlobalData.$userData.combat_score.normal;
         }
         else if(GlobalData.$tempPVE_type == "status_pve_hard")
         {
            _loc3_ = GlobalData.$userData.combat_score.hard;
         }
         else if(GlobalData.$tempPVE_type == "status_pve_activities")
         {
            _loc3_ = GlobalData.$userData.combat_score.ploy;
         }
         else if(GlobalData.$tempPVE_type == "status_pve_guild")
         {
            _loc3_ = GlobalData.$userData.combat_score.normal;
         }
         for(var _loc11_:Object in _loc5_)
         {
            if(_loc11_.toString() == param1)
            {
               _loc6_ = int(_loc5_[_loc11_].combat) * 3;
            }
         }
         if(_loc3_.hasOwnProperty(param1))
         {
            _loc9_ = 0;
            while(_loc9_ < _loc3_[param1][1].length)
            {
               if(_loc3_[param1][1][_loc9_] == null)
               {
                  _loc4_ += 0;
               }
               else
               {
                  _loc4_ += int(_loc3_[param1][1][_loc9_]);
               }
               _loc9_++;
            }
         }
         else
         {
            _loc4_ = 0;
         }
         if(_loc4_ == _loc6_)
         {
            _loc10_ = [16764006,16764006,16764006,16764006];
         }
         return Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90641,_loc4_,_loc6_),_loc10_,35,20);
      }
      
      public static function getCombatStarById(param1:String) : String
      {
         var _loc6_:String = null;
         var _loc8_:Object = null;
         var _loc2_:Array = null;
         var _loc7_:Array = param1.split("_");
         var _loc5_:String = _loc7_[0] + "_" + _loc7_[1];
         var _loc4_:String = _loc7_[2];
         var _loc3_:Object = GlobalData.$userData.combat_score;
         if(GlobalData.$tempPVE_type == "status_pve_normal")
         {
            _loc8_ = GlobalData.$userData.combat_score.normal;
         }
         else if(GlobalData.$tempPVE_type == "status_pve_hard")
         {
            _loc8_ = GlobalData.$userData.combat_score.hard;
         }
         else if(GlobalData.$tempPVE_type == "status_pve_activities")
         {
            _loc8_ = GlobalData.$userData.combat_score.ploy;
         }
         else if(GlobalData.$tempPVE_type == "status_pve_guild")
         {
            _loc8_ = GlobalData.$userData.combat_score.normal;
         }
         if(_loc8_.hasOwnProperty(_loc5_))
         {
            _loc2_ = _loc8_[_loc5_][1];
            _loc6_ = _loc2_[int(_loc4_) - 1] == null ? "0" : _loc2_[int(_loc4_) - 1];
         }
         else
         {
            _loc6_ = "0";
         }
         return _loc6_;
      }
      
      public static function passBattleInfo(param1:String) : Object
      {
         var _loc8_:int = 0;
         var _loc7_:int = 0;
         var _loc4_:int = 0;
         var _loc6_:Object = null;
         var _loc3_:Object = null;
         var _loc2_:Object = {};
         _loc2_.isPass = false;
         if(GlobalData.$tempPVE_type == "status_pve_normal")
         {
            _loc3_ = GlobalData.$userData.combat_score.normal;
            _loc6_ = getPveBattleCfg(GlobalData.$tempPVE_type);
            if(check_pass_battle_main(param1,GlobalData.$tempPVE_type_id) == 1)
            {
               _loc2_.isPass = true;
            }
            if(check_pass_battle_main(param1,GlobalData.$tempPVE_type_id) == 2)
            {
               _loc2_.isPass = false;
            }
         }
         else if(GlobalData.$tempPVE_type == "status_pve_hard")
         {
            _loc3_ = GlobalData.$userData.combat_score.hard;
            _loc6_ = getPveBattleCfg(GlobalData.$tempPVE_type);
            if(check_pass_battle_main(param1,GlobalData.$tempPVE_type_id) == 1)
            {
               _loc2_.isPass = true;
            }
            if(check_pass_battle_main(param1,GlobalData.$tempPVE_type_id) == 2)
            {
               _loc2_.isPass = false;
            }
         }
         else if(GlobalData.$tempPVE_type == "status_pve_activities")
         {
            _loc3_ = GlobalData.$userData.combat_score.ploy;
            _loc6_ = getPveBattleCfg(GlobalData.$tempPVE_type);
            if(check_pass_activeity_battle(param1))
            {
               _loc2_.isPass = true;
            }
            else
            {
               _loc2_.isPass = false;
            }
         }
         else if(GlobalData.$tempPVE_type == "status_pve_guild")
         {
            _loc3_ = GlobalData.$userData.combat_score.normal;
            _loc6_ = getPveBattleCfg(GlobalData.$tempPVE_type);
            if(check_pass_battle_main(param1,GlobalData.$tempPVE_type_id) == 1)
            {
               _loc2_.isPass = true;
            }
            if(check_pass_battle_main(param1,GlobalData.$tempPVE_type_id) == 2)
            {
               _loc2_.isPass = false;
            }
         }
         for(var _loc9_:Object in _loc6_)
         {
            if(_loc9_.toString() == param1)
            {
               _loc7_ = int(_loc6_[_loc9_].combat) * 3;
            }
         }
         var _loc5_:int = 0;
         if(_loc3_.hasOwnProperty(param1))
         {
            _loc5_ = int(_loc3_[param1][1].length);
            _loc8_ = 0;
            while(_loc8_ < _loc5_)
            {
               if(_loc3_[param1][1][_loc8_] == null)
               {
                  _loc4_ += 0;
               }
               else
               {
                  _loc4_ += int(_loc3_[param1][1][_loc8_]);
               }
               _loc8_++;
            }
         }
         else
         {
            _loc4_ = 0;
         }
         if(_loc7_ == _loc4_)
         {
            _loc2_.isAll = true;
         }
         else
         {
            _loc2_.isAll = false;
         }
         if(_loc3_.hasOwnProperty(param1))
         {
            if(_loc3_[param1][0] == "0")
            {
               _loc2_.getGift = false;
            }
            if(_loc3_[param1][0] == "1")
            {
               _loc2_.getGift = true;
            }
         }
         else
         {
            _loc2_.getGift = false;
         }
         return _loc2_;
      }
      
      public static function getExtremeStartEndTime(param1:String, param2:int = -1) : Object
      {
         var _loc16_:Object = GlobalData.$mConfig_simple.extreme;
         var _loc15_:Object = _loc16_.time;
         var _loc28_:Date = _loc15_.start_time as Date;
         var _loc23_:Number = SendAndSelect.$systemTimer_nowSecond * 1000;
         var _loc12_:Number = _loc28_.time;
         var _loc24_:Number = _loc15_.cycle * 60 * 1000;
         var _loc8_:Number = _loc15_.signup * 60 * 1000;
         var _loc4_:Number = _loc12_;
         var _loc9_:Number = _loc4_ + _loc24_;
         while(_loc23_ > _loc9_)
         {
            _loc4_ = _loc9_;
            _loc9_ = _loc4_ + _loc24_;
         }
         var _loc10_:Number = _loc4_;
         var _loc18_:Number;
         var _loc22_:Number = _loc18_ = _loc4_ + _loc15_.signup * 60 * 1000;
         var _loc6_:Number;
         var _loc13_:Number = _loc6_ = _loc22_ + _loc15_.auditions[0] * 60 * 1000;
         var _loc14_:Number = _loc13_ + _loc15_.select_aud * 60 * 1000;
         var _loc11_:Number = _loc15_.battle_time[0] * 60 * 1000;
         var _loc26_:Number = _loc15_.battle_time[1] * 60 * 1000;
         var _loc29_:Number = _loc15_.battle_time[2] * 60 * 1000;
         var _loc25_:int = 0;
         var _loc21_:int = 5;
         var _loc20_:Array = [];
         var _loc7_:Number = 0;
         var _loc5_:Number = 0;
         var _loc17_:Number = 0;
         var _loc3_:Number = 0;
         var _loc19_:Object = null;
         _loc25_ = 0;
         while(_loc25_ < _loc21_)
         {
            _loc19_ = {};
            _loc7_ = _loc14_ + _loc11_ * _loc25_;
            _loc5_ = _loc7_ + _loc11_;
            _loc17_ = _loc7_ + _loc26_;
            _loc3_ = _loc7_ + _loc29_;
            _loc19_["start"] = _loc7_;
            _loc19_["end"] = _loc5_;
            _loc19_["team"] = _loc17_;
            _loc19_["fans"] = _loc3_;
            _loc20_.push(_loc19_);
            _loc25_++;
         }
         var _loc27_:Number = _loc5_;
         if(_loc23_ >= _loc12_)
         {
            if(_loc23_ >= _loc4_ && _loc23_ < _loc9_)
            {
            }
         }
         switch(param1)
         {
            case "signup":
               return {
                  "start":_loc10_,
                  "end":_loc18_
               };
            case "audition":
               return {
                  "start":_loc22_,
                  "end":_loc6_
               };
            case "select_aud":
               return {
                  "start":_loc13_,
                  "end":_loc14_
               };
            case "battle":
               if(param2 == -1)
               {
                  return {};
               }
               return _loc20_[param2];
               break;
            case "grant":
               return {
                  "start":_loc27_,
                  "end":_loc9_
               };
            default:
               return {};
         }
      }
      
      public static function getExtremeTime() : Object
      {
         var _loc31_:Object = null;
         var _loc22_:int = 0;
         var _loc30_:int = 0;
         var _loc7_:Object = null;
         var _loc15_:Object = GlobalData.$mConfig_simple.extreme;
         var _loc14_:Object = _loc15_.time;
         var _loc29_:Date = _loc14_.start_time as Date;
         var _loc24_:Number = SendAndSelect.$systemTimer_nowSecond * 1000;
         var _loc11_:Number = _loc29_.time;
         var _loc25_:Number = _loc14_.cycle * 60 * 1000;
         var _loc6_:Number = _loc14_.signup * 60 * 1000;
         var _loc2_:Number = _loc11_;
         var _loc8_:Number = _loc2_ + _loc25_;
         while(_loc24_ > _loc8_)
         {
            _loc2_ = _loc8_;
            _loc8_ = _loc2_ + _loc25_;
         }
         var _loc9_:Number = _loc2_;
         var _loc18_:Number;
         var _loc23_:Number = _loc18_ = _loc2_ + _loc14_.signup * 60 * 1000;
         var _loc4_:Number;
         var _loc12_:Number = _loc4_ = _loc23_ + _loc14_.auditions[0] * 60 * 1000;
         var _loc13_:Number = _loc12_ + _loc14_.select_aud * 60 * 1000;
         var _loc10_:Number = _loc14_.battle_time[0] * 60 * 1000;
         var _loc27_:Number = _loc14_.battle_time[1] * 60 * 1000;
         var _loc32_:Number = _loc14_.battle_time[2] * 60 * 1000;
         var _loc26_:int = 0;
         var _loc21_:int = 5;
         var _loc20_:Array = [];
         var _loc5_:Number = 0;
         var _loc3_:Number = 0;
         var _loc17_:Number = 0;
         var _loc1_:Number = 0;
         var _loc19_:Object = null;
         _loc26_ = 0;
         while(_loc26_ < _loc21_)
         {
            _loc19_ = {};
            _loc5_ = _loc13_ + _loc10_ * _loc26_;
            _loc3_ = _loc5_ + _loc10_;
            _loc17_ = _loc5_ + _loc27_;
            _loc1_ = _loc5_ + _loc32_;
            _loc19_["start"] = _loc5_;
            _loc19_["end"] = _loc3_;
            _loc19_["team"] = _loc17_;
            _loc19_["fans"] = _loc1_;
            _loc20_.push(_loc19_);
            _loc26_++;
         }
         var _loc28_:Number = _loc3_;
         var _loc16_:Object = {};
         if(_loc9_ <= _loc24_ && _loc24_ < _loc18_)
         {
            _loc16_.time = "signup";
            _loc16_.start = _loc9_;
            _loc16_.end = _loc18_;
            _loc16_.next = _loc18_ - _loc24_;
         }
         else if(_loc23_ <= _loc24_ && _loc24_ < _loc4_)
         {
            _loc16_.time = "audition";
            _loc16_.start = _loc23_;
            _loc16_.end = _loc4_;
            _loc16_.next = _loc4_ - _loc24_;
         }
         else if(_loc12_ <= _loc24_ && _loc24_ < _loc13_)
         {
            _loc16_.time = "select_aud";
            _loc16_.start = _loc12_;
            _loc16_.end = _loc13_;
            _loc16_.next = _loc13_ - _loc24_;
         }
         else if(_loc13_ <= _loc24_ && _loc24_ < _loc28_)
         {
            _loc31_ = GlobalData.$useExtreme;
            _loc16_.time = "battle";
            _loc22_ = 0;
            while(_loc22_ < _loc20_.length)
            {
               if(_loc20_[_loc22_]["start"] <= _loc24_ && _loc24_ < _loc20_[_loc22_]["end"])
               {
                  _loc30_ = _loc22_;
               }
               _loc22_++;
            }
            _loc16_.timeNum = _loc30_;
            _loc7_ = _loc20_[_loc30_];
            _loc16_.start = _loc7_.start;
            _loc16_.end = _loc7_.end;
            _loc16_.next = _loc16_.end - _loc24_;
         }
         else if(_loc28_ <= _loc24_ && _loc24_ < _loc8_)
         {
            _loc16_.time = "grant";
            _loc16_.start = _loc28_;
            _loc16_.end = _loc8_;
            _loc16_.next = _loc8_ - _loc24_;
         }
         return _loc16_;
      }
      
      public static function checkIsExtremeTime(param1:String, param2:int = -1) : Boolean
      {
         if(param1 == "battle")
         {
            param2 = int(GlobalData.$useExtreme.phase_data[0]);
         }
         var _loc3_:Object = getExtremeStartEndTime(param1,param2);
         var _loc4_:Number = SendAndSelect.$systemTimer_nowSecond * 1000;
         if(_loc3_ == null)
         {
            return false;
         }
         if(_loc3_.start <= _loc4_ && _loc4_ < _loc3_.end)
         {
            return true;
         }
         return false;
      }
      
      public static function setTeamData(param1:String) : Object
      {
         var _loc3_:Object = GlobalData.$userData.exploration.army;
         var _loc2_:Object = [];
         for(var _loc4_:String in _loc3_)
         {
            if(_loc4_ == param1)
            {
               _loc2_ = _loc3_[_loc4_];
            }
         }
         return _loc2_;
      }
      
      public static function getPveCombatCfg(param1:String) : Object
      {
         if(param1 == "status_pve_normal")
         {
            return GlobalData.$config_combat_main;
         }
         if(param1 == "status_pve_hard")
         {
            return GlobalData.$config_combat_main;
         }
         if(param1 == "status_pve_activities")
         {
            return GlobalData.$mConfig_combat_ploy;
         }
         if(param1 == "status_pve_guild")
         {
            return GlobalData.$config_combat_association;
         }
         return null;
      }
      
      public static function getUserCombat(param1:String, param2:String) : int
      {
         var _records:Object = GlobalData.$userData == null ? null : GlobalData.$userData.records;
         var _bucket:Object = null;
         var _value:* = null;
         if(_records == null)
         {
            return 0;
         }
         if(param1 == "status_pve_normal")
         {
            _bucket = _records.combat_main;
         }
         else if(param1 == "status_pve_hard")
         {
            _bucket = _records.combat_main_hard;
         }
         else if(param1 == "status_pve_activities")
         {
            _bucket = _records.combat_ploy;
         }
         else if(param1 == "status_pve_guild")
         {
            _bucket = _records.combat_main;
         }
         if(_bucket == null)
         {
            return 0;
         }
         _value = _bucket[param2];
         return _value == null ? 0 : int(_value);
      }
      
      public static function checkGameFunIsOpenByType(param1:String) : int
      {
         var _loc3_:int = 0;
         var _loc2_:Array = GlobalData.$mConfig_simple.start_lv;
         if(GlobalData.$mConfig_simple.start_lv)
         {
            if(param1 == "status_pve_activities")
            {
               _loc3_ = int(GlobalData.$mConfig_simple.start_lv[0]);
            }
            else if(param1 == "status_pve_hard")
            {
               _loc3_ = int(GlobalData.$mConfig_simple.start_lv[6]);
            }
            else if(param1 == "center_pvp")
            {
               _loc3_ = int(GlobalData.$mConfig_simple.start_lv[1]);
            }
            else if(param1 == "equip_fun_change")
            {
               _loc3_ = int(GlobalData.$mConfig_simple.start_lv[7]);
            }
            else if(param1 == "equip_fun_wash")
            {
               _loc3_ = int(GlobalData.$mConfig_simple.start_lv[8]);
            }
            else if(param1 == "center_boss")
            {
               _loc3_ = int(GlobalData.$mConfig_simple.start_lv[9]);
            }
            else if(param1 == "center_radio")
            {
               _loc3_ = int(GlobalData.$mConfig_simple.start_lv[10]);
            }
            else if(param1 == "center_pvp_fragment")
            {
               _loc3_ = int(GlobalData.$mConfig_simple.start_lv[11]);
            }
            else if(param1 == "equip_fun_magic")
            {
               _loc3_ = int(GlobalData.$mConfig_simple.start_lv[12]);
            }
            else if(param1 == "center_pvp_embattle")
            {
               _loc3_ = int(GlobalData.$mConfig_simple.start_lv[16]);
            }
            else if(param1 == "center_avatar_foster")
            {
               _loc3_ = int(GlobalData.$mConfig_simple.culture.culture_lv);
            }
            else if(param1 == "center_scence")
            {
               _loc3_ = int(GlobalData.$mConfig_simple.start_lv[17]);
            }
            else if(param1 == "alchemy_")
            {
               _loc3_ = int(GlobalData.$mConfig_simple.start_lv[18]);
            }
            else if(param1 == "status_pvp_fifteen")
            {
               _loc3_ = int(GlobalData.$mConfig_simple.start_lv[19]);
            }
            else if(param1 == "center_alchemy")
            {
               _loc3_ = int(GlobalData.$mConfig_simple.start_lv[20]);
            }
         }
         if(GlobalData.$userData.lv >= _loc3_)
         {
            _loc3_ = -1;
         }
         return _loc3_;
      }
      
      public static function getServiceIconUIname(param1:int) : String
      {
         var _loc2_:String = "UI_service_icon_000";
         if(param1 == 999)
         {
            _loc2_ = "UI_service_icon_0003";
         }
         else
         {
            _loc2_ += String(param1 - 1);
         }
         return _loc2_;
      }
      
      public static function checkFragmentIsFull(param1:Array) : Boolean
      {
         return param1.indexOf(0) < 0;
      }
      
      public static function getFragmentNum(param1:Array) : int
      {
         var _loc4_:int = 0;
         var _loc3_:int = int(param1.length);
         var _loc2_:int = 0;
         _loc4_ = 0;
         while(_loc4_ < _loc3_)
         {
            _loc2_ += param1[_loc4_];
            _loc4_++;
         }
         return _loc2_;
      }
      
      public static function getFragmentNumType(param1:Array) : int
      {
         var _loc4_:int = 0;
         var _loc3_:int = int(param1.length);
         var _loc2_:int = 0;
         _loc4_ = 0;
         while(_loc4_ < _loc3_)
         {
            if(param1[_loc4_] > 0)
            {
               _loc2_ += 1;
            }
            _loc4_++;
         }
         return _loc2_;
      }
      
      public static function getObjArrNumType(param1:Array) : int
      {
         var _loc3_:int = 0;
         var _loc2_:int = 0;
         _loc3_ = 0;
         while(_loc3_ < param1.length)
         {
            if(param1[_loc3_] != null)
            {
               _loc2_++;
            }
            _loc3_++;
         }
         return _loc2_;
      }
      
      public static function check_panelIDsort(param1:Array) : Boolean
      {
         var _loc4_:int = 0;
         var _loc3_:int = int(param1.length);
         var _loc2_:int = 0;
         _loc4_ = 0;
         while(_loc4_ < _loc3_)
         {
            if(GlobalData.$panelSortArr[_loc4_] != null)
            {
               if(GlobalData.$panelSortArr[_loc4_] == param1[_loc4_])
               {
                  _loc2_ += 1;
               }
            }
            _loc4_++;
         }
         return _loc2_ == _loc3_;
      }
      
      public static function set_panelIDsort(param1:String) : void
      {
         if(GlobalData.$panelSortArr.length > 1)
         {
            GlobalData.$panelSortArr.shift();
         }
         GlobalData.$panelSortArr.push(param1);
      }
      
      public static function setlv_up(param1:int, param2:String, param3:String, param4:Function) : void
      {
      }
      
      public static function getStage_Mode(param1:Array) : Object
      {
         var _loc4_:Array = param1;
         var _loc2_:Object = {};
         var _loc3_:Array = [];
         if(_loc4_[1] == "all")
         {
            _loc3_[0] = GlobalLanguageStr.getStr(90626);
         }
         else if(_loc4_[1] == "1")
         {
            _loc3_[0] = GlobalLanguageStr.getStr(90627);
         }
         else if(_loc4_[1] == "2")
         {
            _loc3_[0] = GlobalLanguageStr.getStr(90628);
         }
         else if(_loc4_[1] == "3")
         {
            _loc3_[0] = GlobalLanguageStr.getStr(90629);
         }
         else if(_loc4_[1] == "4")
         {
            _loc3_[0] = GlobalLanguageStr.getStr(90630);
         }
         else if(_loc4_[1] == "5")
         {
            _loc3_[0] = GlobalLanguageStr.getStr(90631);
         }
         else if(_loc4_[1] == "6")
         {
            _loc3_[0] = GlobalLanguageStr.getStr(90632);
         }
         else if(_loc4_[1] == "7")
         {
            _loc3_[0] = GlobalLanguageStr.getStr(90633);
         }
         else if(_loc4_[1] == "8")
         {
            _loc3_[0] = GlobalLanguageStr.getStr(90634);
         }
         else if(_loc4_[1] == "9")
         {
            _loc3_[0] = GlobalLanguageStr.getStr(90635);
         }
         else if(_loc4_[1] == "10")
         {
            _loc3_[0] = GlobalLanguageStr.getStr(90636);
         }
         if(_loc4_[0] == "ap")
         {
            _loc3_[1] = GlobalLanguageStr.getStr(90640);
         }
         else if(_loc4_[0] == "hp")
         {
            _loc3_[1] = GlobalLanguageStr.getStr(90637);
         }
         else if(_loc4_[0] == "de_ph")
         {
            _loc3_[1] = GlobalLanguageStr.getStr(90638);
         }
         else if(_loc4_[0] == "de_ma")
         {
            _loc3_[1] = GlobalLanguageStr.getStr(90639);
         }
         else if(_loc4_[0] == "hit")
         {
            _loc3_[1] = GlobalLanguageStr.getStr(30021);
         }
         else if(_loc4_[0] == "flee")
         {
            _loc3_[1] = GlobalLanguageStr.getStr(30022);
         }
         else if(_loc4_[0] == "crit")
         {
            _loc3_[1] = GlobalLanguageStr.getStr(30023);
         }
         else if(_loc4_[0] == "tough")
         {
            _loc3_[1] = GlobalLanguageStr.getStr(30024);
         }
         if(_loc4_[3] == 0)
         {
            if(_loc4_[2] > 0)
            {
               _loc3_[2] = "+" + _loc4_[2];
               _loc2_["add"] = 1;
            }
            else
            {
               _loc3_[2] = "-" + _loc4_[2];
               _loc2_["add"] = 0;
            }
         }
         else if(_loc4_[2] >= 1)
         {
            _loc3_[2] = "+" + GameMapTools.toPercentage(_loc4_[2] - 1);
            _loc2_["add"] = 1;
         }
         else
         {
            _loc3_[2] = "-" + GameMapTools.toPercentage(1 - _loc4_[2]);
            _loc2_["add"] = 0;
         }
         _loc2_["info"] = _loc3_[0] + _loc3_[1] + _loc3_[2];
         _loc2_["data"] = _loc4_;
         return _loc2_;
      }
      
      public static function openPrompt(param1:String, param2:int = 370, param3:int = 900, param4:int = 100) : void
      {
         var _loc7_:LayoutUIBottom = null;
         var _loc5_:int = 0;
         var _loc8_:int = 0;
         var _loc6_:Boolean = false;
         var _loc9_:Boolean = false;
         if(param1 == "status_boss")
         {
            _loc7_ = GlobalData.$mGameClassObject.mLayoutUIBottom;
            if(null == GlobalData.$mGameClassObject.mLayoutUIBottom || null == GlobalData.$mGameClassObject.mLayoutUIBottom.parent)
            {
               return;
            }
            _loc5_ = int(GlobalData.$mConfig_simple.zone_boss.open_status);
            _loc8_ = int(GlobalFunction.checkGameFunIsOpenByType("center_boss"));
            _loc6_ = Boolean(GlobalFunction.checkBossIsOpen());
            _loc9_ = Boolean(GlobalFunction.checkBossInGuideTime());
            if(_loc5_ && _loc8_ < 0)
            {
               LayoutUIAnimation.getOnlyExample().addArrowhead(param2,param3,param4);
            }
         }
      }
      
      public static function clearPromptAnimation() : void
      {
         if(null == GlobalData.$mGameClassObject.mLayoutUIBottom || null == GlobalData.$mGameClassObject.mLayoutUIBottom.parent)
         {
            return;
         }
         var _loc1_:int = int(GlobalData.$mConfig_simple.zone_boss.open_status);
         var _loc2_:int = int(GlobalFunction.checkGameFunIsOpenByType("center_boss"));
         if(_loc1_ && _loc2_ < 0)
         {
            LayoutUIAnimation.getOnlyExample().clear();
         }
      }
      
      public static function newDate(param1:* = null) : Date
      {
         return param1 == null ? new Date() : new Date(int(param1));
      }
      
      public static function checkBannerAd() : Boolean
      {
         var _loc1_:Object = null;
         var _loc2_:Boolean = false;
         if(GlobalData.$mConfig_client["banner_ad"])
         {
            _loc1_ = GlobalData.$mConfig_client.banner_ad;
            if(_loc1_[GlobalLocalStore.$pf_type_curr])
            {
               _loc2_ = true;
            }
         }
         return _loc2_;
      }
      
      public static function checkQuikLogin() : Boolean
      {
         var _loc2_:Boolean = false;
         var _loc3_:int = 0;
         var _loc1_:Array = GlobalData.$mConfig_client["quik_login"];
         if(_loc1_)
         {
            _loc3_ = 0;
            while(_loc3_ < _loc1_.length)
            {
               if(_loc1_[_loc3_] == GlobalLocalStore.$pf_type_curr)
               {
                  _loc2_ = true;
                  break;
               }
               _loc3_++;
            }
         }
         return _loc2_;
      }
      
      public static function quitGame() : void
      {
         var _timer:Timer;
         var onTIMER_COMPLETE:* = function(param1:TimerEvent):void
         {
            param1.currentTarget.removeEventListener("timerComplete",onTIMER_COMPLETE);
            GlobalData.$mGameClassObject.closePopForPanel();
            GlobalData.$mGameClassObject.initUILayout();
            GlobalFunction.setGameSoundInit(true);
         };
         SendAndSelect.$uid = "";
         PanelRollInfo.lastTime = 0;
         GlobalData.$tempTeamID = 0;
         GlobalData.$tempTeam = null;
         GlobalData.$tempTeamSelect = null;
         GlobalData.$tempTeamSelectLS = 0;
         GlobalData.$tempUserLS = 0;
         GlobalData.$tempTeamSelect_member = null;
         GlobalData.$tempPVE_battleID = "";
         GlobalData.$tempPVE_combatID = "";
         GlobalData.$tempPVE_type = "";
         GlobalData.$tempPVE_battleID_normal = "";
         GlobalData.$tempPVE_battleID_hard = "";
         GlobalData.$tempPVE_battleID_ACTIVITIES = "";
         GlobalData.$tempPVE_battleID_isFirstWin = false;
         GlobalData.$tempPVE_battleStyle = 0;
         StarlingTools.removeChildrenClear(GlobalData.$tempPVE_drag);
         GlobalData.$tempPVE_drag = null;
         GlobalData.$tempSocial_friend = null;
         GlobalData.$tempSell = [];
         GlobalData.$tempSellItem = {};
         GlobalData.$tempAvatarBetterArr = [];
         GlobalData.$tempAvatarBetterItem = {};
         GlobalData.$tempFoodForBook = [];
         GlobalData.$tempObjectFoodForBook = {};
         GlobalData.$tempAvatarBetter = null;
         GlobalData.$tempBetterElements = {};
         GlobalData.$tempAvatarStarUp = null;
         GlobalData.$tempAvatarLock = {};
         GlobalData.$tempLockItem = null;
         GlobalData.$tempItemTeamEmbattle = null;
         GlobalData.$chatBtnTouchable = true;
         GlobalData.$BattleOfThePeakDefenseTeam = null;
         GlobalData.$BattleOfThePeakTeam = null;
         GlobalData.$tempFriend = null;
         GlobalData.$tempFriendRequest = null;
         GlobalData.$tempOnline = null;
         GlobalData.$tempHelpAvatar = null;
         GlobalData.$tempCasinoResult;
         GlobalData.$typeCasinoResult = "";
         GlobalData.$traceRollInfoB = true;
         GlobalData.$isGameEndAward = false;
         GlobalData.$searchTypeFun = null;
         GlobalData.$gameEndAwardObj = null;
         GlobalData.$panelCasinoClipB = false;
         GlobalData.$shopAppleGetList = false;
         GlobalData.$reLoginGame = true;
         GlobalData.$tempPVE_type_id = 0;
         GlobalData.$tempEquipFunId = 0;
         GlobalData.$tempEquipIndex = 0;
         GlobalData.$tempEquipChangeIndex = 0;
         GlobalData.$tempEquipCurrSelected = "";
         PanelSocialMainAvatar.$tabBarSelectedIndex = 0;
         GlobalData.$setPVE();
         GlobalData.$PVPupClip = false;
         GlobalData.$tempMazeSelect = null;
         GlobalData.$pvp_rival = null;
         GlobalData.$shopType = 0;
         GlobalData.$vipGiftData = null;
         GlobalData.$shopInByMain = false;
         GlobalData.$gambleReportStr = "";
         GlobalData.$gambleReportTimer = 0;
         PanelCenterPVP.$tabBarSelectedIndex = 0;
         PanelBetterSelect.$tabBarSelectedIndex = 0;
         PanelAvatarSell.$tabBarSelectedIndex = 0;
         PanelTeamAvatar.$tabBarSelectedIndex = 0;
         PanelAvatarBetter.$tabBarSelectedIndex = 0;
         PanelAvatarStarUp.$tabBarSelectedIndex = 0;
         GlobalData.$tempPVP_Elite_fans_tab_id = 0;
         GlobalData.$tempPVP_Elite_award_tab_id = 0;
         GlobalData.$tempExtremeBetTeam = [];
         GlobalData.$tempExtremeBetTeamDate = {};
         GlobalData.$tempExtremeBetUser = [];
         GlobalData.$tempIsApplyorChangeTeam = false;
         GlobalData.$tempExtreme32Users = [];
         GlobalData.$exploration_select_avatar = null;
         GlobalData.$exploration_team_avatar = null;
         GlobalData.backFromExploration = false;
         GlobalData.$fragment_data = null;
         GlobalData.$panelSortArr = [];
         _timer = new Timer(100,1);
         _timer.addEventListener("timerComplete",onTIMER_COMPLETE);
         _timer.start();
         if(GameMap.currentMap)
         {
            GameMap.currentMap.clear();
         }
         GameMapLayer.gl.mapStage.removeFromParent();
         SkillSetManager.clear();
         GameMapManager.clear();
         EffectManager.clear();
         EquipManager.clear();
         AvatarManager.clear();
         SocketManager.getInstance().clear();
         GlobalData.$pro_send_time_server = 0;
         GlobalData.$pro_send_time_private = 0;
         GlobalData.$pro_send_time_world = 0;
         GlobalData.$pro_send_time_guild = 0;
         GlobalData.$mPrivateChatUserData = null;
         GlobalData.$InfoLookFromChat = false;
         GuideMaster.getOnlyExample().skipGuide(true);
         LayoutUIAnimation.getOnlyExample().clear();
         LayoutUIAnimation.getOnlyExample().clearAnimationLayer();
         PanelRollInfo.lastTime = 0;
         PanelCenterActivity.$activityFunObj = null;
         GuideData.clear();
      }
   }
}

