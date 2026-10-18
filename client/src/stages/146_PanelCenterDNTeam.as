package com.meng52.game.ui.screen
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.module.map.GameMapTools;
   import com.meng52.game.ui.element.ItemDNavatar;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.game.ui.element.LOL_TeamSet;
   import com.meng52.game.ui.panel.PanelDetailDN;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.global.ConfigManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import flash.utils.Dictionary;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;

   public class PanelCenterDNTeam extends PanelBase
   {

      public static const DN_XY:Object = {};

      private var mTeam:LOL_TeamSet;

      private var mTxt_title:TextField;

      private var mTxt_HpMax:TextField;

      private var mTxt_Damage:TextField;

      private var mTxt_DePh:TextField;

      private var mTxt_DeMa:TextField;

      private var mTxt_dnStone:TextField;

      private var mTxt_help:TextField;

      private var mStr_HpMax:String = "";

      private var mStr_Damage:String = "";

      private var mStr_DePh:String = "";

      private var mStr_DeMa:String = "";

      private var mStr_dnStone:String = "";

      private var _txt_coin:LOL_MutilTextFieldIcon;

      private var mImg_stone:Image;

      private var mBtn_list:LOL_Button;

      private var mDN_data:Object;

      private var mBox:Sprite;

      private var mH_ruler:Number;

      private var mData_other:Object;

      private var mOther_team:Array;

      private var mOther_avatars:Object;

      private var mOther_dn:Object;

      private var mDnDataPrev:Object;

      private var _speakDN:Boolean = true;

      private const _DN:String = "dn_";

      public function PanelCenterDNTeam(param1:Object = null, param2:Boolean = true)
      {
         setConstXY();
         _speakDN = param2;
         mData_other = null;
         if(param1 != null)
         {
            mData_other = param1;
            mOther_team = mData_other.team;
            mOther_avatars = mData_other.avatars;
            mOther_dn = mData_other.dn;
         }
         super();
      }

      public static function check_ndStatus() : void
      {
      }

      public static function getDestinyMyAll(param1:String, param2:Array = null, param3:Array = null, param4:Object = null, param5:Object = null, param6:Boolean = false) : Object
      {
         param1 = GlobalData.canonicalModInstanceId(param1);
         var _loc23_:Object = null;
         var _loc16_:String = param1;
         var _loc21_:Boolean = param1.indexOf("|") > -1;
         if(_loc21_)
         {
            _loc16_ = param1.split("|")[0];
         }
         var _loc15_:Array = _loc16_.split("_");
         var _loc41_:String = _loc15_[0] + "_" + _loc15_[1];
         var _loc19_:Array = param2 == null ? GlobalData.$userData.team[0] : param2;
         var _loc33_:Array = param3 == null ? GlobalData.$userData.as_equips : param3;
         var _loc22_:Object = param5 == null ? GlobalData.$userData.attrs.dn : param5;
         var _loc26_:Object = param4 == null ? GlobalData.$userData.my_equips : param4;
         _loc19_ = _loc19_.concat();
         for(var modIndex:int = 0; modIndex < _loc19_.length; modIndex++)
         {
            if(_loc19_[modIndex] != null)
               _loc19_[modIndex] = GlobalData.modChannelAllowed(String(_loc19_[modIndex]),"usage.destiny") ? GlobalData.canonicalModInstanceId(String(_loc19_[modIndex])) : null;
         }
         var modDn:Object = {};
         for(var modKey:String in _loc22_)
         {
            var modNode:Array = _loc22_[modKey] as Array;
            modDn[modKey] = modNode == null ? null : modNode.concat();
            if(modNode != null && modNode[1] != null)
               modDn[modKey][1] = GlobalData.modChannelAllowed(String(modNode[1]),"usage.destiny") && GlobalData.modChannelAllowed(String(modNode[1]),"usage.auxiliary_formation") ? GlobalData.canonicalModInstanceId(String(modNode[1])) : null;
         }
         _loc22_ = modDn;
         var _loc31_:Boolean = false;
         if(param2 != null && param3 != null && param4 != null)
         {
            _loc31_ = true;
         }
         var _loc25_:Array = GlobalData.$mConfig_destiny[_loc41_] != null ? GlobalData.$mConfig_destiny[_loc41_] : [];
         if(!GlobalData.modChannelAllowed(param1,"usage.destiny")) _loc25_ = [];
         var _loc34_:int = 0;
         var _loc30_:int = int(_loc25_.length);
         var _loc18_:Array = [];
         var _loc35_:String = "";
         var _loc37_:String = "";
         var _loc14_:Number = 0;
         var _loc20_:Number = 0;
         var _loc39_:Number = 0;
         var _loc27_:Number = 0;
         var _loc17_:Number = 0;
         var _loc8_:Number = 0;
         var _loc32_:Number = 0;
         var _loc13_:Number = 0;
         var _loc24_:Number = 0;
         var _loc7_:Number = 0;
         var _loc10_:Number = 0;
         var _loc36_:Number = 0;
         var _loc40_:Number = 0;
         var _loc12_:Number = 0;
         var _loc38_:Number = 0;
         var _loc9_:Number = 0;
         var _loc11_:Array = [];
         var _loc29_:String = "";
         var _loc28_:Array = [];
         if(_loc30_ > 0)
         {
            _loc34_ = 0;
            while(_loc34_ < _loc30_)
            {
               _loc23_ = getDestinyMyEvery(param1,_loc41_,_loc25_[_loc34_],_loc19_,_loc33_,_loc26_,_loc22_,_loc31_);
               _loc18_.push(_loc23_);
               if(_loc23_.isOK == true)
               {
                  _loc14_ += _loc23_.hp;
                  _loc20_ += _loc23_.hpP;
                  _loc39_ += _loc23_.ap;
                  _loc27_ += _loc23_.apP;
                  _loc17_ += _loc23_.de_ph;
                  _loc8_ += _loc23_.de_phP;
                  _loc32_ += _loc23_.de_ma;
                  _loc13_ += _loc23_.de_maP;
                  _loc24_ += _loc23_.hit;
                  _loc7_ += _loc23_.hitP;
                  _loc10_ += _loc23_.flee;
                  _loc36_ += _loc23_.fleeP;
                  _loc40_ += _loc23_.crit;
                  _loc12_ += _loc23_.critP;
                  _loc38_ += _loc23_.tough;
                  _loc9_ += _loc23_.toughP;
                  if(_loc23_.skill0.length > 0)
                  {
                     _loc35_ = _loc23_.skill0;
                  }
                  if(_loc23_.skill1.length > 0)
                  {
                     _loc37_ = _loc23_.skill1;
                  }
               }
               _loc11_.push(Tools.formatLineX(_loc23_.str,_loc23_.isOK && !param6 ? GlobalTextStyle.COLOR_destiny_true : GlobalTextStyle.COLOR_destiny_false,35,20));
               _loc29_ += _loc23_.isOK ? _loc23_.info : "[" + _loc23_.info + "]";
               _loc28_.push({
                  "isOK":_loc23_.isOK,
                  "txt":_loc23_.info
               });
               if(_loc34_ < _loc30_ - 1)
               {
                  _loc29_ += _loc23_.isOK ? "、" : "[、]";
               }
               _loc34_++;
            }
            _loc29_ = Tools.formatLineX(_loc29_,GlobalTextStyle.COLOR_destiny_name,20,20);
         }
         else
         {
            _loc28_ = null;
            _loc29_ = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(25045),GlobalTextStyle.COLOR_destiny_true,20,20);
            _loc11_.push(_loc29_);
         }
         return {
            "arr":_loc18_,
            "hp":_loc14_,
            "hpP":_loc20_,
            "ap":_loc39_,
            "apP":_loc27_,
            "de_ph":_loc17_,
            "de_phP":_loc8_,
            "de_ma":_loc32_,
            "de_maP":_loc13_,
            "hit":_loc24_,
            "hitP":_loc7_,
            "flee":_loc10_,
            "fleeP":_loc36_,
            "crit":_loc40_,
            "critP":_loc12_,
            "tough":_loc38_,
            "toughP":_loc9_,
            "skill0":_loc35_,
            "skill1":_loc37_,
            "htmlArr":_loc11_,
            "nameStr":_loc29_,
            "nameArr":_loc28_
         };
      }

      public static function getDestinyMyEvery(param1:String, param2:String, param3:Array, param4:Array = null, param5:Array = null, param6:Object = null, param7:Object = null, param8:Boolean = false) : Object
      {
         var _loc56_:Object = null;
         var _loc26_:String = null;
         var _loc53_:String = null;
         var _loc50_:String = null;
         var _loc48_:String = null;
         var _loc15_:Object = null;
         var _loc42_:Boolean = false;
         var _loc25_:int = int(param3[0]);
         var _loc33_:Array = param3[1];
         var _loc37_:Array = param3[2];
         var _loc23_:String = _loc33_[0];
         var _loc45_:int = 0;
         var _loc43_:int = 0;
         var _loc36_:String = "";
         var _loc16_:String = "";
         var _loc35_:Array = null;
         var _loc18_:int = 0;
         var _loc41_:Boolean = true;
         var _loc32_:int = param4.indexOf(param1);
         var _loc31_:Boolean = false;
         var _loc44_:Boolean = _loc23_.indexOf("A_") > -1;
         var _loc55_:Array = [];
         var _loc30_:Boolean = false;
         if(_loc44_)
         {
            if(_loc32_ > -1)
            {
               _loc45_ = 0;
               while(_loc45_ < _loc33_.length)
               {
                  _loc41_ = true;
                  _loc16_ = _loc33_[_loc45_];
                  _loc43_ = 0;
                  while(_loc43_ < param4.length)
                  {
                     _loc36_ = param4[_loc43_];
                     if(_loc36_ != null)
                     {
                        if(_loc36_.indexOf(_loc16_) > -1 && _loc43_ != _loc32_)
                        {
                           _loc41_ = false;
                           _loc18_ += 1;
                           break;
                        }
                     }
                     _loc43_++;
                  }
                  if(_loc41_)
                  {
                     for(_loc56_ in param7)
                     {
                        if(param7[_loc56_][1] != null)
                        {
                           _loc36_ = param7[_loc56_][1];
                           if(_loc36_.indexOf(_loc16_) > -1)
                           {
                              _loc18_ += 1;
                              break;
                           }
                        }
                     }
                  }
                  _loc45_++;
               }
               if(_loc18_ >= _loc33_.length)
               {
                  _loc31_ = true;
               }
            }
            else
            {
               _loc30_ = true;
            }
         }
         else
         {
            _loc26_ = "";
            _loc53_ = "";
            if(_loc32_ > -1)
            {
               _loc45_ = 0;
               while(_loc45_ < _loc33_.length)
               {
                  _loc41_ = true;
                  _loc16_ = _loc33_[_loc45_];
                  _loc35_ = param8 ? param5 : param5[_loc32_];
                  _loc43_ = 0;
                  while(_loc43_ < _loc35_.length)
                  {
                     if(_loc35_[_loc43_] != null)
                     {
                        _loc26_ = _loc35_[_loc43_];
                        _loc53_ = param6[_loc26_].eid;
                        if(_loc53_.indexOf(_loc16_) > -1)
                        {
                           _loc18_ += 1;
                           break;
                        }
                     }
                     _loc43_++;
                  }
                  _loc45_++;
               }
               if(_loc18_ >= _loc33_.length)
               {
                  _loc31_ = true;
               }
            }
            else
            {
               _loc30_ = true;
            }
         }
         var _loc49_:String = "";
         var _loc51_:String = "";
         var _loc34_:Number = 0;
         var _loc39_:Number = 0;
         var _loc28_:Number = 0;
         var _loc40_:Number = 0;
         var _loc38_:Number = 0;
         var _loc10_:Number = 0;
         var _loc27_:Number = 0;
         var _loc13_:Number = 0;
         var _loc22_:Number = 0;
         var _loc9_:Number = 0;
         var _loc12_:Number = 0;
         var _loc52_:Number = 0;
         var _loc54_:Number = 0;
         var _loc14_:Number = 0;
         var _loc29_:Number = 0;
         var _loc11_:Number = 0;
         var _loc17_:String = _loc37_[0];
         var _loc24_:int = int(_loc37_[2]);
         var _loc21_:String = "";
         var _loc46_:String = GlobalLanguageStr.getLanguageStr(_loc25_);
         var _loc47_:String = "";
         var _loc19_:String = "";
         var _loc20_:String = "";
         if(_loc44_)
         {
            _loc42_ = false;
            _loc45_ = 0;
            while(_loc45_ < _loc33_.length)
            {
               _loc16_ = _loc33_[_loc45_];
               _loc42_ = _loc16_.split("_").length > 2;
               _loc50_ = _loc42_ ? _loc33_[_loc45_] : _loc33_[_loc45_] + "_5";
               _loc48_ = _loc42_ ? _loc33_[_loc45_] : _loc33_[_loc45_] + "_6";
               if(GlobalData.$mConfig_avatar[_loc50_])
               {
                  _loc15_ = GlobalData.$mConfig_avatar[_loc50_];
               }
               else
               {
                  _loc15_ = GlobalData.$mConfig_avatar[_loc48_];
               }
               _loc47_ += _loc42_ ? GlobalLanguageStr.getLanguageStr(20205,_loc16_.split("_")[2],_loc15_.name) : _loc15_.name + (_loc45_ < _loc33_.length - 1 ? "、" : "");
               _loc45_++;
            }
            if(_loc17_ == "skill")
            {
               _loc19_ = PanelDetailDN.getDNattrName(_loc17_,_loc24_);
               _loc20_ = GlobalData.$mConfig_skill[_loc37_[1]].name;
               _loc21_ = GlobalLanguageStr.getLanguageStr(90434,_loc46_,_loc47_,_loc19_,_loc20_);
            }
            else
            {
               _loc19_ = PanelDetailDN.getDNattrName(_loc17_) + (_loc24_ == 0 ? GameMapTools.toPercentage(_loc37_[1]) : _loc37_[1]);
               _loc21_ = GlobalLanguageStr.getLanguageStr(90432,_loc46_,_loc47_,_loc19_);
            }
         }
         else
         {
            _loc45_ = 0;
            while(_loc45_ < _loc33_.length)
            {
               _loc47_ += GlobalData.$mConfig_equip[_loc33_[_loc45_]].name + (_loc45_ < _loc33_.length - 1 ? "、" : "");
               _loc45_++;
            }
            if(_loc17_ == "skill")
            {
               _loc19_ = PanelDetailDN.getDNattrName(_loc17_,_loc24_);
               _loc20_ = GlobalData.$mConfig_skill[_loc37_[1]].name;
               _loc21_ = GlobalLanguageStr.getLanguageStr(90435,_loc46_,_loc47_,_loc19_,_loc20_);
            }
            else
            {
               _loc19_ = PanelDetailDN.getDNattrName(_loc17_) + (_loc24_ == 0 ? GameMapTools.toPercentage(_loc37_[1]) : _loc37_[1]);
               _loc21_ = GlobalLanguageStr.getLanguageStr(90433,_loc46_,_loc47_,_loc19_);
            }
         }
         if(!_loc30_)
         {
            if(_loc17_ == "hp")
            {
               if(_loc24_ == 0)
               {
                  _loc39_ = Number(_loc37_[1]);
               }
               else
               {
                  _loc34_ = Number(_loc37_[1]);
               }
            }
            else if(_loc17_ == "ap")
            {
               if(_loc24_ == 0)
               {
                  _loc40_ = Number(_loc37_[1]);
               }
               else
               {
                  _loc28_ = Number(_loc37_[1]);
               }
            }
            else if(_loc17_ == "de_ph")
            {
               if(_loc24_ == 0)
               {
                  _loc10_ = Number(_loc37_[1]);
               }
               else
               {
                  _loc38_ = Number(_loc37_[1]);
               }
            }
            else if(_loc17_ == "de_ma")
            {
               if(_loc24_ == 0)
               {
                  _loc13_ = Number(_loc37_[1]);
               }
               else
               {
                  _loc27_ = Number(_loc37_[1]);
               }
            }
            else if(_loc17_ == "hit")
            {
               if(_loc24_ == 0)
               {
                  _loc9_ = Number(_loc37_[1]);
               }
               else
               {
                  _loc22_ = Number(_loc37_[1]);
               }
            }
            else if(_loc17_ == "flee")
            {
               if(_loc24_ == 0)
               {
                  _loc52_ = Number(_loc37_[1]);
               }
               else
               {
                  _loc12_ = Number(_loc37_[1]);
               }
            }
            else if(_loc17_ == "crit")
            {
               if(_loc24_ == 0)
               {
                  _loc14_ = Number(_loc37_[1]);
               }
               else
               {
                  _loc54_ = Number(_loc37_[1]);
               }
            }
            else if(_loc17_ == "tough")
            {
               if(_loc24_ == 0)
               {
                  _loc11_ = Number(_loc37_[1]);
               }
               else
               {
                  _loc29_ = Number(_loc37_[1]);
               }
            }
            else if(_loc17_ == "skill")
            {
               if(_loc24_ == 0)
               {
                  _loc49_ = _loc37_[1];
               }
               else
               {
                  _loc51_ = _loc37_[1];
               }
            }
         }
         return {
            "isOK":_loc31_,
            "hp":_loc34_,
            "hpP":_loc39_,
            "ap":_loc28_,
            "apP":_loc40_,
            "de_ph":_loc38_,
            "de_phP":_loc10_,
            "de_ma":_loc27_,
            "de_maP":_loc13_,
            "hit":_loc22_,
            "hitP":_loc9_,
            "flee":_loc12_,
            "fleeP":_loc52_,
            "crit":_loc54_,
            "critP":_loc14_,
            "tough":_loc29_,
            "toughP":_loc11_,
            "skill0":_loc49_,
            "skill1":_loc51_,
            "info":_loc46_,
            "str":_loc21_
         };
      }

      public static function getDestinyByDN(param1:String) : Object
      {
         var _loc13_:Array = null;
         var _loc5_:Array = null;
         var _loc14_:Array = null;
         var _loc26_:Array = null;
         var _loc23_:String = null;
         var _loc22_:String = null;
         var _loc16_:Boolean = false;
         var _loc3_:Object = null;
         var _loc24_:Boolean = false;
         var _loc4_:String = param1;
         if(param1.indexOf("|") > -1)
         {
            _loc4_ = param1.split("|")[0];
         }
         var _loc9_:Array = _loc4_.split("_");
         var _loc8_:String = _loc9_[0] + "_" + _loc9_[1];
         var _loc28_:Array = GlobalData.$userData.team[0];
         var _loc19_:int = 0;
         var _loc17_:int = int(_loc28_.length);
         var _loc12_:Object = GlobalData.$mConfig_destiny;
         var _loc11_:String = "";
         var _loc27_:int = 0;
         var _loc25_:Array = [];
         var _loc2_:Array = [];
         var _loc18_:int = 0;
         var _loc15_:Boolean = false;
         var _loc10_:String = "";
         var _loc20_:String = "";
         var _loc21_:String = "";
         var _loc6_:String = "";
         var _loc7_:String = "";
         _loc19_ = 0;
         while(_loc19_ < _loc17_)
         {
            if(_loc28_[_loc19_] != null)
            {
               _loc21_ = "";
               _loc11_ = _loc28_[_loc19_];
               _loc13_ = _loc11_.split("|");
               _loc5_ = _loc11_.split("_");
               _loc11_ = _loc5_[0] + "_" + _loc5_[1];
               _loc20_ = GlobalData.$mConfig_avatar[_loc13_[0]].name;
               if(GlobalData.$mConfig_destiny[_loc11_])
               {
                  _loc14_ = GlobalData.$mConfig_destiny[_loc11_];
                  _loc27_ = 0;
                  while(_loc27_ < _loc14_.length)
                  {
                     _loc26_ = _loc14_[_loc27_];
                     _loc15_ = false;
                     if(_loc26_[1].indexOf(_loc4_) > -1)
                     {
                        _loc15_ = true;
                     }
                     else if(_loc26_[1].indexOf(_loc8_) > -1)
                     {
                        _loc15_ = true;
                     }
                     if(_loc15_)
                     {
                        _loc24_ = false;
                        _loc18_ = 0;
                        while(_loc18_ < _loc2_.length)
                        {
                           if(_loc2_[_loc18_] == _loc11_)
                           {
                              _loc24_ = true;
                              break;
                           }
                           _loc18_++;
                        }
                        if(!_loc24_)
                        {
                           _loc18_ = 0;
                           while(_loc18_ < _loc26_[1].length)
                           {
                              _loc16_ = _loc26_[1][_loc18_].split("_").length > 2;
                              _loc23_ = _loc16_ ? _loc26_[1][_loc18_] : _loc26_[1][_loc18_] + "_5";
                              _loc22_ = _loc16_ ? _loc26_[1][_loc18_] : _loc26_[1][_loc18_] + "_6";
                              if(GlobalData.$mConfig_avatar[_loc23_])
                              {
                                 _loc3_ = GlobalData.$mConfig_avatar[_loc23_];
                              }
                              else
                              {
                                 _loc3_ = GlobalData.$mConfig_avatar[_loc22_];
                              }
                              _loc21_ += _loc16_ ? GlobalLanguageStr.getLanguageStr(20205,_loc26_[1][_loc18_].split("_")[2],_loc3_.name) : _loc3_.name + (_loc18_ < _loc26_[1].length - 1 ? "、" : "");
                              _loc18_++;
                           }
                           if(_loc26_[2][0] == "skill")
                           {
                              _loc6_ = PanelDetailDN.getDNattrName(_loc26_[2][0],_loc26_[2][2]);
                              _loc7_ = GlobalData.$mConfig_skill[_loc26_[2][1]].name;
                              _loc10_ = GlobalLanguageStr.getLanguageStr(90434,_loc20_,_loc21_,_loc6_,_loc7_);
                           }
                           else
                           {
                              _loc6_ = PanelDetailDN.getDNattrName(_loc26_[2][0]) + (_loc26_[2][2] == 0 ? GameMapTools.toPercentage(_loc26_[2][1]) : _loc26_[2][1]);
                              _loc10_ = GlobalLanguageStr.getLanguageStr(90432,_loc20_,_loc21_,_loc6_);
                           }
                           _loc2_.push(_loc11_);
                           _loc25_.push(Tools.formatLineX(_loc10_,GlobalTextStyle.COLOR_destiny_true,30,20));
                        }
                     }
                     _loc27_++;
                  }
               }
            }
            _loc19_++;
         }
         if(_loc25_.length <= 0)
         {
            _loc25_.push(Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90512,GlobalData.$mConfig_avatar[_loc4_].name),GlobalTextStyle.COLOR_destiny_false,30,20));
         }
         return {"htmlArr":_loc25_};
      }

      public static function getDestinyByEquip(param1:String) : Object
      {
         var _loc13_:Object = null;
         var _loc2_:Array = null;
         var _loc12_:Array = null;
         var _loc8_:Object = null;
         var _loc3_:int = param1.indexOf("E_");
         var _loc10_:Boolean = _loc3_ > -1;
         var _loc4_:Object = GlobalData.$mConfig_destiny;
         var _loc19_:int = 0;
         var _loc20_:String = "";
         var _loc14_:String = "";
         var _loc15_:String = "";
         var _loc17_:String = "";
         var _loc18_:String = "";
         var _loc11_:String = "";
         var _loc16_:String = "";
         var _loc7_:Array = [];
         var _loc5_:String = "";
         var _loc6_:Boolean = false;
         var _loc9_:String = "";
         if(_loc10_)
         {
            for(_loc13_ in _loc4_)
            {
               _loc2_ = _loc4_[_loc13_];
               _loc19_ = 0;
               while(_loc19_ < _loc2_.length)
               {
                  _loc12_ = _loc2_[_loc19_];
                  if(_loc12_[1][0] == param1)
                  {
                     _loc5_ = _loc13_.toString();
                     _loc6_ = _loc5_.split("_").length > 2;
                     _loc11_ = _loc6_ ? _loc5_ : _loc5_ + "_5";
                     _loc16_ = _loc6_ ? _loc5_ : _loc5_ + "_6";
                     if(GlobalData.$mConfig_avatar[_loc11_])
                     {
                        _loc8_ = GlobalData.$mConfig_avatar[_loc11_];
                     }
                     else
                     {
                        _loc8_ = GlobalData.$mConfig_avatar[_loc16_];
                     }
                     _loc9_ = _loc6_ ? GlobalLanguageStr.getLanguageStr(20205,_loc5_.split("_")[2],_loc8_.name) : _loc8_.name;
                     _loc14_ = GlobalLanguageStr.getLanguageStr(_loc12_[0]);
                     _loc15_ = GlobalData.$mConfig_equip[param1].name;
                     if(_loc12_[2][0] == "skill")
                     {
                        _loc17_ = PanelDetailDN.getDNattrName(_loc12_[2][0],_loc12_[2][2]);
                        _loc18_ = GlobalData.$mConfig_skill[_loc12_[2][1]].name;
                        _loc20_ = GlobalLanguageStr.getLanguageStr(90447,_loc14_,_loc9_,_loc15_,_loc17_,_loc18_);
                     }
                     else
                     {
                        _loc17_ = PanelDetailDN.getDNattrName(_loc12_[2][0]) + (_loc12_[2][2] == 0 ? GameMapTools.toPercentage(_loc12_[2][1]) : _loc12_[2][1]);
                        _loc20_ = GlobalLanguageStr.getLanguageStr(90446,_loc14_,_loc9_,_loc15_,_loc17_);
                     }
                     _loc7_.push(Tools.formatLineX(_loc20_,GlobalTextStyle.COLOR_destiny_true,30,20));
                     break;
                  }
                  _loc19_++;
               }
            }
         }
         else
         {
            _loc7_ = [];
         }
         if(_loc7_.length <= 0)
         {
            _loc7_.push(Tools.formatLineX(GlobalLanguageStr.getLanguageStr(25045),GlobalTextStyle.COLOR_destiny_true,16,20));
         }
         return {"htmlArr":_loc7_};
      }

      public static function checkIsInDn(param1:String) : Object
      {
         var _loc3_:Object = null;
         var _loc2_:Object = null;
         for(var _loc4_:Object in GlobalData.$userData.attrs.dn)
         {
            _loc3_ = GlobalData.$userData.attrs.dn[_loc4_];
            if(_loc3_[1] != null)
            {
               if(_loc3_[1] == param1)
               {
                  _loc2_ = _loc3_;
                  break;
               }
            }
         }
         return _loc2_;
      }

      private function setConstXY() : void
      {
         var _loc4_:String = null;
         var _loc2_:Object = null;
         var _loc5_:Boolean = true;
         var _loc1_:int = 1;
         var _loc3_:Dictionary = ConfigManager.getInstance().uiPos;
         while(_loc5_)
         {
            _loc4_ = "dn_" + _loc1_;
            if(_loc3_.hasOwnProperty(_loc4_))
            {
               _loc2_ = _loc3_[_loc4_];
               DN_XY[String(_loc1_)] = [_loc2_[ConfigManager.POSX],_loc2_[ConfigManager.POSY]];
               _loc1_++;
            }
            else
            {
               _loc5_ = false;
            }
         }
      }

      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalData.$mEventDispatcher.removeEventListener("update_dn_team_ui",onUPDATE_DN_TEAM_UI);
         if(mBox)
         {
            StarlingTools.removeChildrenClear(mBox);
            mBox.removeFromParent(true);
         }
         if(mTxt_help)
         {
            mTxt_help.removeFromParent(true);
         }
         if(mTxt_title)
         {
            mTxt_title.removeFromParent(true);
         }
         if(mTxt_HpMax)
         {
            mTxt_HpMax.removeFromParent(true);
         }
         if(mTxt_Damage)
         {
            mTxt_Damage.removeFromParent(true);
         }
         if(mTxt_DePh)
         {
            mTxt_DePh.removeFromParent(true);
         }
         if(mTxt_DeMa)
         {
            mTxt_DeMa.removeFromParent(true);
         }
         if(mTxt_dnStone)
         {
            mTxt_dnStone.removeFromParent(true);
         }
         if(mImg_stone)
         {
            mImg_stone.removeFromParent(true);
         }
         if(mBtn_list)
         {
            mBtn_list.removeFromParent(true);
         }
         if(mTeam)
         {
            StarlingTools.removeChildrenClear(mTeam);
            mTeam.removeFromParent(true);
         }
         mTeam = null;
         mTxt_title = null;
         mTxt_HpMax = null;
         mTxt_Damage = null;
         mTxt_DePh = null;
         mTxt_DeMa = null;
         mTxt_dnStone = null;
         mImg_stone = null;
         mBtn_list = null;
         mBox = null;
         mTxt_help = null;
         GlobalFunction.delTextureByBD("png_team_append_bg");
      }

      override protected function initializeHandler(param1:Event) : void
      {
         GlobalData.$mEventDispatcher.addEventListener("update_dn_team_ui",onUPDATE_DN_TEAM_UI);
         mImgBg = GlobalFunction.createImage("png_team_append_bg",true);
         var _loc2_:Number = GlobalData.$center_height_curr - 121;
         mImgBg.y = int((_loc2_ - mImgBg.height) * 0.5) + 20;
         mH_ruler = mImgBg.y;
         addChild(mImgBg);
         mBox = new Sprite();
         mBox.y = mH_ruler;
         addChild(mBox);
         this.removeEventListener("addedToStage",initializeHandler);
         mStr_HpMax = GlobalLanguageStr.getLanguageStr(25028);
         mStr_Damage = GlobalLanguageStr.getLanguageStr(25029);
         mStr_DePh = GlobalLanguageStr.getLanguageStr(25030);
         mStr_DeMa = GlobalLanguageStr.getLanguageStr(25031);
         mStr_dnStone = GlobalLanguageStr.getLanguageStr(25033);
         setTxtUI();
         if(_speakDN && GuideMaster.getOnlyExample().checkGuide("M13_1") == -1)
         {
            LayoutUIAnimation.getOnlyExample().clearIfNoGuide();
         }
      }

      private function setTxtUI() : void
      {
         var _loc1_:Number = 140;
         var _loc2_:Number = 30;
         var _loc3_:Number = 25;
         var _loc4_:Number = 10;
         mTxt_HpMax = GlobalTextStyle.getTextField(mStr_HpMax,16,1513239,"left",_loc1_,35);
         if(MainConfig.$idCenter_DN)
         {
            mTxt_HpMax.x = MainConfig.$isEA ? int((GlobalData.$mStageWidth - _loc1_) * 0.5) : int((GlobalData.$mStageWidth - _loc1_) * 0.5) + _loc4_ * 2;
            mTxt_HpMax.y = int(mImgBg.y + mImgBg.height - (mData_other == null ? 230 : 35 * 5));
         }
         else
         {
            mTxt_HpMax.x = 55;
            mTxt_HpMax.y = int(mImgBg.y + mImgBg.height - (mData_other == null ? 155 : 35 * 3));
         }
         mTxt_Damage = GlobalTextStyle.getTextField(mStr_Damage,16,1513239,"left",_loc1_,35);
         mTxt_DePh = GlobalTextStyle.getTextField(mStr_DePh,16,1513239,"left",_loc1_,35);
         mTxt_DeMa = GlobalTextStyle.getTextField(mStr_DeMa,16,1513239,"left",_loc1_,35);
         mTxt_Damage.x = mTxt_DePh.x = mTxt_DeMa.x = mTxt_HpMax.x;
         mTxt_Damage.y = mTxt_HpMax.y + _loc3_;
         mTxt_DePh.y = mTxt_Damage.y + _loc3_;
         mTxt_DeMa.y = mTxt_DePh.y + _loc3_;
         addChild(mTxt_HpMax);
         addChild(mTxt_Damage);
         addChild(mTxt_DePh);
         addChild(mTxt_DeMa);
         if(mData_other == null)
         {
            mBtn_list = GlobalFunction.createButton_5(GlobalLanguageStr.getLanguageStr(25041),"UI_btn_enterGame_0_0000");
            mBtn_list.x = int((GlobalData.$mStageWidth - mBtn_list.width) * 0.5);
            mBtn_list.y = int(mImgBg.y + mImgBg.height - 70 - mBtn_list.height);
            mBtn_list.addEventListener("triggered",onTRIGGERED_list);
            addChild(mBtn_list);
            _txt_coin = new LOL_MutilTextFieldIcon(mStr_dnStone,GlobalData.$userData.attrs.dn_stone,"UI_dn_icon_stone_0000",10027008,10027008,19);
            _loc1_ = _txt_coin.textFieldWidth;
            _txt_coin.x = _loc2_ - 3;
            _txt_coin.y = mH_ruler + 63;
            addChild(_txt_coin);
         }
         mImgBg.y += 10;
         mImgBg.height -= 20;
         mTxt_help = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(25052),25,10027008,"center",100,35);
         mTxt_help.touchable = true;
         mTxt_help.underline = true;
         mTxt_help.x = mImgBg.x + mImgBg.width - 130;
         mTxt_help.y = mImgBg.y + 50;
         mTxt_help.addEventListener("touch",onTOUCH_help);
         addChild(mTxt_help);
         check_myDN();
         updateTxt();
      }

      private function onTOUCH_help(param1:TouchEvent) : void
      {
         var _loc2_:Touch = null;
         if(mTxt_help)
         {
            _loc2_ = param1.getTouch(mTxt_help);
            if(_loc2_)
            {
               if(_loc2_.phase == "ended")
               {
                  GlobalFunction.popPanelHelp(MainConfig.SERVER_ADDRESS_HELP_DN);
               }
            }
         }
      }

      private function onTRIGGERED_list(param1:Event) : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_PanelDestinyList",false,true);
      }

      private function updateTxt() : void
      {
         mDnDataPrev = PanelDetailDN.getDNAttrsAllValue(mData_other == null ? null : mOther_dn);
         if(mTxt_HpMax)
         {
            mTxt_HpMax.text = mStr_HpMax + " +" + mDnDataPrev.hp;
         }
         if(mTxt_Damage)
         {
            mTxt_Damage.text = mStr_Damage + " +" + mDnDataPrev.ap;
         }
         if(mTxt_DePh)
         {
            mTxt_DePh.text = mStr_DePh + " +" + mDnDataPrev.de_ph;
         }
         if(mTxt_DeMa)
         {
            mTxt_DeMa.text = mStr_DeMa + " +" + mDnDataPrev.de_ma;
         }
         if(_txt_coin)
         {
            _txt_coin.txt2 = GlobalData.$userData.attrs.dn_stone;
         }
      }

      private function onUPDATE_DN_TEAM_UI(param1:Event) : void
      {
         var _loc4_:Number = NaN;
         var _loc9_:Number = NaN;
         var _loc7_:Number = NaN;
         var _loc6_:Number = NaN;
         var _loc10_:Number = NaN;
         var _loc2_:Number = NaN;
         var _loc11_:Number = NaN;
         var _loc13_:Number = NaN;
         var _loc5_:Number = NaN;
         var _loc8_:String = null;
         _loc8_ = " +";
         var _loc12_:String = null;
         _loc12_ = " -";
         var _loc3_:Object = null;
         if(mData_other == null && mDnDataPrev)
         {
            _loc3_ = {};
            _loc3_.hp = mDnDataPrev.hp;
            _loc3_.ap = mDnDataPrev.ap;
            _loc3_.de_ph = mDnDataPrev.de_ph;
            _loc3_.de_ma = mDnDataPrev.de_ma;
         }
         check_myDN();
         updateTxt();
         if(_loc3_ != null && mData_other == null && mDnDataPrev)
         {
            _loc4_ = mDnDataPrev.hp - _loc3_.hp;
            _loc9_ = mDnDataPrev.ap - _loc3_.ap;
            _loc7_ = mDnDataPrev.de_ph - _loc3_.de_ph;
            _loc6_ = mDnDataPrev.de_ma - _loc3_.de_ma;
            _loc10_ = GlobalData.$mStageHeight * 0.5;
            _loc2_ = 60;
            _loc11_ = 2;
            _loc13_ = 0;
            _loc5_ = 0.45;
            if(_loc4_ != 0)
            {
               LayoutUIAnimation.getOnlyExample().popWords(mStr_HpMax + (_loc4_ > 0 ? "[" + _loc8_ + _loc4_ + "]" : "{" + (_loc12_ + _loc4_ * -1) + "}"),_loc11_,_loc5_,_loc13_);
               _loc5_ += 0.05;
               _loc13_ += 0.2;
            }
            if(_loc9_ != 0)
            {
               LayoutUIAnimation.getOnlyExample().popWords(mStr_Damage + (_loc9_ > 0 ? "[" + _loc8_ + _loc9_ + "]" : "{" + (_loc12_ + _loc9_ * -1) + "}"),_loc11_,_loc5_,_loc13_);
               _loc5_ += 0.05;
               _loc13_ += 0.2;
            }
            if(_loc7_ != 0)
            {
               LayoutUIAnimation.getOnlyExample().popWords(mStr_DePh + (_loc7_ > 0 ? "[" + _loc8_ + _loc7_ + "]" : "{" + (_loc12_ + _loc7_ * -1) + "}"),_loc11_,_loc5_,_loc13_);
               _loc5_ += 0.05;
               _loc13_ += 0.2;
            }
            if(_loc6_ != 0)
            {
               LayoutUIAnimation.getOnlyExample().popWords(mStr_DeMa + (_loc6_ > 0 ? "[" + _loc8_ + _loc6_ + "]" : "{" + (_loc12_ + _loc6_ * -1) + "}"),_loc11_,_loc5_,_loc13_);
               _loc5_ += 0.05;
               _loc13_ += 0.2;
            }
         }
      }

      private function check_myDN() : void
      {
         var _loc8_:Object = null;
         var _loc7_:Object = null;
         var _loc6_:ItemDNavatar = null;
         var _loc1_:String = null;
         var _hero:Object = null;
         var _heroField:String = null;
         if(mBox)
         {
            StarlingTools.removeChildrenClear(mBox);
         }
         var _loc9_:Object = mData_other == null ? GlobalData.$userData.attrs.dn : mOther_dn;
         var _loc3_:Object = GlobalData.$mConfig_simple.dn;
         var _loc2_:String = "";
         mDN_data = {};
         var _loc5_:int = Tools.getElementNum(_loc9_);
         if(_loc5_ <= 0)
         {
            _loc7_ = {};
            _loc7_["indexID_s"] = "1";
            _loc7_["data_base"] = _loc3_["1"];
            _loc7_.x = DN_XY["1"][0];
            _loc7_.y = DN_XY["1"][1];
            _loc7_["lock"] = 1;
            _loc7_["dnlv"] = 0;
            _loc7_["aid"] = null;
            _loc7_["id"] = null;
            _loc7_["dn_self"] = mData_other == null;
            _loc6_ = new ItemDNavatar(this);
            _loc6_.data = _loc7_;
            mBox.addChild(_loc6_);
         }
         else
         {
            for(_loc8_ in _loc3_)
            {
               _loc2_ = _loc8_.toString();
               if(_loc9_[_loc2_])
               {
                  _loc7_ = {};
                  if(_loc9_[_loc2_][1] != null)
                  {
                     _hero = mData_other == null ? GlobalData.$userData.avatars[_loc9_[_loc2_][1]] : mOther_avatars[_loc9_[_loc2_][1]];
                     if(_hero is String)
                     {
                        _loc1_ = _hero as String;
                     }
                     else if(_hero != null)
                     {
                        // Node display fields must not be written into the owned hero.
                        for(_heroField in _hero)
                        {
                           _loc7_[_heroField] = _hero[_heroField];
                        }
                     }
                  }
                  _loc7_["indexID_s"] = _loc2_;
                  _loc7_["data_base"] = _loc3_[_loc2_];
                  _loc7_.x = DN_XY[_loc2_][0];
                  _loc7_.y = DN_XY[_loc2_][1];
                  _loc7_["lock"] = 0;
                  _loc7_["dnlv"] = _loc9_[_loc2_][0];
                  _loc7_["aid"] = _loc9_[_loc2_][1];
                  _loc7_["id"] = _loc9_[_loc2_][1];
                  _loc7_["dn_self"] = mData_other == null;
                  if(_loc9_[_loc2_][1] != null)
                  {
                     _loc7_["give"] = getBettrGiveOther(_loc9_[_loc2_][1]);
                  }
                  _loc6_ = new ItemDNavatar(this);
                  _loc6_.data = _loc7_;
                  mBox.addChild(_loc6_);
               }
               else if(_loc9_[_loc3_[_loc8_][1]] && mData_other == null)
               {
                  _loc7_ = {};
                  _loc7_["indexID_s"] = _loc2_;
                  _loc7_["data_base"] = _loc3_[_loc2_];
                  _loc7_.x = DN_XY[_loc2_][0];
                  _loc7_.y = DN_XY[_loc2_][1];
                  _loc7_["lock"] = 1;
                  _loc7_["dnlv"] = 0;
                  _loc7_["aid"] = null;
                  _loc7_["id"] = null;
                  _loc7_["dn_self"] = mData_other == null;
                  _loc6_ = new ItemDNavatar(this);
                  _loc6_.data = _loc7_;
                  mBox.addChild(_loc6_);
               }
            }
         }
      }

      public function getBettrGiveOther(param1:String) : Object
      {
         var _loc2_:Avatar = new Avatar(param1);
         var _loc3_:Number = _loc2_.getOfferExp();
         _loc2_.clear();
         _loc2_ = null;
         return {
            "exp":_loc3_,
            "gold":_loc3_
         };
      }
   }
}
