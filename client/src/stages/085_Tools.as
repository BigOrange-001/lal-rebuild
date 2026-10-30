package com.meng52.utils
{
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import feathers.display.Scale9Image;
   import feathers.textures.Scale9Textures;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.display.Sprite;
   import flash.display.Stage;
   import flash.geom.ColorTransform;
   import flash.geom.Matrix;
   import flash.geom.Rectangle;
   import flash.system.ApplicationDomain;
   import flash.system.Capabilities;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.utils.ByteArray;
   import flash.utils.getDefinitionByName;
   import flash.utils.getQualifiedClassName;
   import flash.utils.getQualifiedSuperclassName;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.textures.Texture;
   
   public class Tools
   {
      
      public static var rateY:Number = 0;
      
      public static var $isAndroidB:Boolean = false;
      
      public static const BAN_LIST:Array = [";","&",">","<","$","\x16","\x03","\\"];
      
      public static const BAN_LIST2:Array = ["(",")","[","]","{","}"];
      
      public static const BAN_LIST3:Array = ["《","》","，","(",")","[","]","{","}","；","？",".","。"," ","+"];
      
      public function Tools()
      {
         super();
      }
      
      public static function getTimegoBySec(param1:int) : String
      {
         var _loc2_:String = "";
         if(param1 < 60)
         {
            _loc2_ = param1 + GlobalLanguageStr.getLanguageStr(98022);
         }
         else if(param1 < 3600)
         {
            _loc2_ = Tools.toInt(param1 / 60) + GlobalLanguageStr.getLanguageStr(98023);
         }
         else if(param1 < 86400)
         {
            _loc2_ = Tools.toInt(param1 / 60 / 60) + GlobalLanguageStr.getLanguageStr(98024);
         }
         else if(param1 < 2592000)
         {
            _loc2_ = Tools.toInt(param1 / 60 / 60 / 24) + GlobalLanguageStr.getLanguageStr(98025);
         }
         else if(param1 < 31104000)
         {
            _loc2_ = Tools.toInt(param1 / 60 / 60 / 24 / 30) + GlobalLanguageStr.getLanguageStr(98026);
         }
         else
         {
            _loc2_ = Tools.toInt(param1 / 60 / 60 / 24 / 30 / 12) + GlobalLanguageStr.getLanguageStr(98027);
         }
         return _loc2_;
      }
      
      public static function getListRandom(param1:Array) : *
      {
         var _loc3_:int = 0;
         var _loc2_:Number = Math.random();
         _loc3_ = 0;
         while(_loc3_ < param1.length)
         {
            if(_loc2_ <= param1[_loc3_][0])
            {
               return param1[_loc3_][1];
            }
            _loc3_++;
         }
         return null;
      }
      
      public static function getArrayRandom(param1:Array) : *
      {
         var _loc2_:int = param1.length * Math.random();
         return param1[_loc2_];
      }
      
      public static function getRandomElement(param1:*, param2:Boolean = false) : *
      {
         var _loc3_:int = 0;
         var _loc4_:int = getElementNum(param1);
         var _loc5_:int = Math.random() * _loc4_;
         for(var _loc6_ in param1)
         {
            if(_loc3_ == _loc5_)
            {
               if(param2)
               {
                  return param1[_loc6_];
               }
               return _loc6_;
            }
            _loc3_++;
         }
         return null;
      }
      
      public static function toInt(param1:Number) : int
      {
         return int(param1.toFixed(5));
      }
      
      public static function toEffectiveInt(param1:int, param2:int) : int
      {
         var _loc7_:int = 0;
         var _loc4_:int = 0;
         var _loc3_:String = param1.toString();
         var _loc5_:String = "";
         var _loc6_:int = param1;
         _loc4_ = _loc3_.length;
         if(_loc4_ > param2)
         {
            _loc5_ = int(_loc3_.charAt(param2)) >= 5 ? (int(_loc3_.slice(0,param2)) + 1).toString() : _loc3_.slice(0,param2);
            _loc7_ = 0;
            while(_loc7_ < _loc4_ - param2)
            {
               _loc5_ += "0";
               _loc7_++;
            }
            _loc6_ = int(_loc5_);
         }
         return _loc6_;
      }
      
      public static function getImage(param1:DisplayObject, param2:uint = 1) : Image
      {
         return new Image(Texture.fromBitmapData(getBitmapData(param1)));
      }
      
      public static function newQuad(param1:int, param2:int, param3:int = 0, param4:int = 0, param5:uint = 0) : Quad
      {
         var _loc6_:Quad = null;
         _loc6_ = new Quad(1,1,param5);
         _loc6_.width = param1;
         _loc6_.height = param2;
         _loc6_.x = param3;
         _loc6_.y = param4;
         return _loc6_;
      }
      
      public static function getBitmapData(param1:DisplayObject, param2:uint = 1, param3:Rectangle = null) : BitmapData
      {
         var _loc4_:Rectangle = param3 ? param3 : param1.getBounds(param1);
         return formatBitmapData(param1,_loc4_,param2);
      }
      
      public static function getBitmapDataAndRec(param1:DisplayObject, param2:uint = 1) : Object
      {
         var _loc3_:Rectangle = param1.getBounds(param1);
         return {
            "bitmapData":formatBitmapData(param1,_loc3_,param2),
            "rec":_loc3_
         };
      }
      
      public static function formatBitmapData(param1:DisplayObject, param2:Rectangle, param3:uint = 1) : BitmapData
      {
         var _loc5_:uint = uint(param2.width + param3 | 1);
         var _loc4_:uint = uint(param2.height + param3 | 1);
         _loc5_ = uint(_loc5_ % 2 == 0 ? _loc5_ : _loc5_ + 1);
         _loc4_ = uint(_loc4_ % 2 == 0 ? _loc4_ : _loc4_ + 1);
         var _loc6_:BitmapData = new BitmapData(_loc5_,_loc4_,true,16777215);
         _loc6_.drawWithQuality(param1,new Matrix(1,0,0,1,-param2.x,-param2.y),null,null,null,null,"medium");
         return _loc6_;
      }
      
      public static function getXML(param1:String) : XML
      {
         return GlobalData.$assetManager.getXml(param1);
      }
      
      public static function getTexture(param1:String) : Texture
      {
         var _loc5_:Object = null;
         var _loc4_:BitmapData = null;
         var _loc2_:BitmapData = null;
         var _loc3_:Texture = GlobalData.$assetManager.getTexture(param1);
         if(_loc3_)
         {
            return _loc3_;
         }
         if(/\d\d\d\d$/.test(param1) == false)
         {
            _loc3_ = GlobalData.$assetManager.getTexture(param1 + "0000");
         }
         if(_loc3_)
         {
            return _loc3_;
         }
         _loc5_ = getDefinitionByName(param1);
         if(_loc5_)
         {
            _loc4_ = new _loc5_() as BitmapData;
            return Texture.fromBitmapData(_loc4_);
         }
         _loc2_ = new BitmapData(50,50,true,16711680);
         return Texture.fromBitmapData(_loc2_);
      }
      
      public static function formatBitmapDataScale(param1:DisplayObject, param2:Object, param3:uint = 1) : BitmapData
      {
         var _loc4_:BitmapData = new BitmapData(param2.width,param2.height,true,16777215);
         var _loc5_:Matrix = new Matrix();
         _loc5_.scale(param2.scale,param2.scale);
         _loc5_.translate(param2.x,param2.y);
         _loc4_.drawWithQuality(param1,_loc5_,null,null,null,false,"medium");
         return _loc4_;
      }
      
      public static function getBitmapDataNoRec(param1:DisplayObject, param2:Object) : BitmapData
      {
         var _loc3_:BitmapData = new BitmapData(param2.w,param2.h,true,16777215);
         _loc3_.draw(param1);
         return _loc3_;
      }
      
      public static function formatBitmapCircle(param1:BitmapData, param2:int = -1) : BitmapData
      {
         if(param2 < 0)
         {
            param2 = param1.width;
         }
         var _loc5_:Sprite = new Sprite();
         var _loc3_:Sprite = new Sprite();
         _loc3_.graphics.beginFill(0);
         _loc3_.graphics.lineStyle();
         _loc3_.graphics.drawCircle(param1.width / 2,param1.width / 2,param2 / 2);
         _loc3_.graphics.endFill();
         var _loc4_:Bitmap = new Bitmap(param1);
         _loc5_.addChild(_loc4_);
         _loc5_.mask = _loc3_;
         var _loc6_:Matrix = new Matrix(1,0,0,1,(param2 - param1.width) / 2,(param2 - param1.width) / 2);
         param1 = new BitmapData(param2,param2,true,0);
         param1.draw(_loc5_,_loc6_);
         return param1;
      }
      
      public static function setBitmapDataToGray(param1:BitmapData) : void
      {
         var _loc3_:Number = param1.width;
         var _loc2_:Number = param1.height;
         var _loc5_:uint = 0;
         var _loc4_:uint = 0;
         _loc5_ = 0;
         while(_loc5_ < _loc3_)
         {
            _loc4_ = 0;
            while(_loc4_ < _loc2_)
            {
               param1.setPixel(_loc5_,_loc4_,setRGBtoGray(param1.getPixel(_loc5_,_loc4_)));
               _loc4_++;
            }
            _loc5_++;
         }
      }
      
      public static function setRGBtoGray(param1:uint) : uint
      {
         var _loc4_:uint = uint(param1 >> 16 & 0xFF);
         var _loc2_:uint = uint(param1 >> 8 & 0xFF);
         var _loc3_:uint = uint(param1 & 0xFF);
         _loc4_ = _loc2_;
         _loc3_ = _loc2_;
         return _loc4_ << 16 | _loc2_ << 8 | _loc3_ | 0xFF000000;
      }
      
      public static function setRGBtoGray2(param1:uint) : uint
      {
         var _loc5_:uint = param1;
         var _loc4_:uint = uint(_loc5_ >> 16 & 0xFF);
         var _loc2_:uint = uint(_loc5_ >> 8 & 0xFF);
         var _loc3_:uint = uint(_loc5_ & 0xFF);
         _loc5_ = uint(_loc4_ * 38 + _loc2_ * 75 + _loc3_ * 15 >> 7);
         return uint(parseInt(_loc5_.toString(16),16) + parseInt(_loc5_.toString(16) + "00",16) + parseInt(_loc5_.toString(16) + "0000",16));
      }
      
      public static function drawRect(param1:Number, param2:Number, param3:Number, param4:Number, param5:uint, param6:Number) : Sprite
      {
         var _loc7_:Sprite = new Sprite();
         _loc7_.graphics.beginFill(param5,param6);
         _loc7_.graphics.drawRect(param1,param2,param3,param4);
         _loc7_.graphics.endFill();
         return _loc7_;
      }
      
      public static function getElementNum(param1:Object) : int
      {
         var _loc3_:* = undefined;
         var _loc2_:int = 0;
         for(_loc3_ in param1)
         {
            _loc2_++;
         }
         return _loc2_;
      }
      
      public static function getArrayNum(param1:Array) : int
      {
         var _loc3_:int = 0;
         var _loc2_:int = 0;
         if(!param1)
         {
            return 0;
         }
         _loc3_ = 0;
         while(_loc3_ < param1.length)
         {
            if(param1[_loc3_])
            {
               _loc2_++;
            }
            _loc3_++;
         }
         return _loc2_;
      }
      
      public static function randomElement(param1:Object) : Object
      {
         var _loc4_:* = undefined;
         var _loc3_:int = 0;
         var _loc2_:int = getElementNum(param1);
         var _loc5_:int = Math.random() * _loc2_;
         for(_loc4_ in param1)
         {
            if(_loc3_ == _loc5_)
            {
               return _loc4_;
            }
            _loc3_++;
         }
         return null;
      }
      
      public static function fillSpace(param1:String, param2:int = 10, param3:Boolean = true) : String
      {
         var _loc6_:int = 0;
         var _loc4_:int = getCharLength(param1);
         var _loc5_:String = "";
         _loc6_ = _loc4_;
         while(_loc6_ < param2)
         {
            _loc5_ += " ";
            _loc6_++;
         }
         if(param3)
         {
            _loc5_ += param1;
         }
         else
         {
            _loc5_ = param1 + _loc5_;
         }
         return _loc5_;
      }
      
      public static function getCharLength(param1:String, param2:Array = null) : int
      {
         var _loc4_:int = 0;
         var _loc7_:int = 0;
         var _loc3_:RegExp = null;
         var _loc6_:* = 0;
         var _loc5_:int = 0;
         if(param2)
         {
            _loc7_ = 0;
            while(_loc7_ < param2.length)
            {
               _loc3_ = new RegExp("\\" + param2[_loc7_],"g");
               param1 = param1.replace(_loc3_,"");
               _loc7_++;
            }
         }
         _loc7_ = 0;
         while(_loc7_ < param1.length)
         {
            _loc6_ = uint(param1.charCodeAt(_loc7_));
            if(_loc6_ >= 32 && _loc6_ <= 126)
            {
               _loc4_ = 1;
            }
            else
            {
               _loc4_ = 2;
            }
            _loc5_ += _loc4_;
            _loc7_++;
         }
         return _loc5_;
      }
      
      public static function formatHtmlText(param1:String, param2:uint = 3355443, param3:Boolean = false, param4:int = 14, param5:String = "", param6:int = 12, param7:Array = null) : String
      {
         if(param1 == null)
         {
            return "";
         }
         var _loc9_:String = "";
         var _loc12_:String = "";
         var _loc8_:String = "";
         var _loc11_:String = "#" + param2.toString(16);
         if(param5 == "")
         {
            param5 = GlobalConfig.FONT_0;
         }
         var _loc10_:int = param4;
         if($isAndroidB && param5 != GlobalConfig.FONT_0)
         {
         }
         if(param6 > 0 && param6 < 1000)
         {
            _loc9_ = param1;
            _loc8_ = formatLineX(_loc9_,null,param6);
         }
         else
         {
            _loc8_ = param1;
         }
         if(param3)
         {
            return "<font color=\"" + _loc11_ + "\" size=\"" + _loc10_ + "\" face=\"" + param5 + "\"><b>" + _loc8_ + "</b></font>";
         }
         return "<font color=\"" + _loc11_ + "\" size=\"" + _loc10_ + "\" face=\"" + param5 + "\">" + _loc8_ + "</font>";
      }
      
      public static function getLine(param1:int = 40, param2:String = "=", param3:String = "", param4:int = 5) : String
      {
         var _loc6_:int = 0;
         var _loc5_:String = "";
         if(param2 == "")
         {
            param2 = "=";
         }
         if(param3 == "")
         {
            param3 = "center";
         }
         _loc6_ = 0;
         while(_loc6_ < param1)
         {
            _loc5_ += param2;
            _loc6_++;
         }
         return HtmlTextFormat.format(_loc5_,param3,14540253,param4);
      }
      
      public static function formatHtmlTextBr(param1:Array, param2:String = "left") : String
      {
         var _loc4_:int = 0;
         var _loc3_:String = "";
         _loc4_ = 0;
         while(_loc4_ < param1.length)
         {
            _loc3_ += "<P ALIGN=\"" + param2 + "\">" + param1[_loc4_] + "</P>";
            _loc4_++;
         }
         return _loc3_;
      }
      
      public static function formatHtmlTextBr2(param1:Array) : String
      {
         var _loc3_:int = 0;
         var _loc2_:String = "";
         _loc3_ = 0;
         while(_loc3_ < param1.length)
         {
            _loc2_ += param1[_loc3_] + " ";
            _loc3_++;
         }
         return _loc2_;
      }
      
      public static function formatLine(param1:String, param2:String = "\n", param3:int = 18, param4:Array = null) : String
      {
         var _loc11_:int = 0;
         var _loc7_:int = 0;
         var _loc9_:* = 0;
         var _loc10_:String = null;
         var _loc8_:String = "";
         var _loc5_:String = "";
         var _loc6_:int = 0;
         if(param4 == null)
         {
            param4 = [];
         }
         if(param3 <= 1)
         {
            param3 = 2;
         }
         _loc11_ = 0;
         while(_loc11_ < param1.length)
         {
            _loc9_ = uint(param1.charCodeAt(_loc11_));
            _loc10_ = param1.charAt(_loc11_);
            if(_loc10_ == "\n")
            {
               _loc6_ = 0;
               _loc8_ += _loc10_;
            }
            else
            {
               if(param4.indexOf(_loc10_) != -1)
               {
                  _loc7_ = 0;
               }
               else if(_loc9_ >= 32 && _loc9_ <= 126)
               {
                  _loc7_ = 1;
               }
               else
               {
                  _loc7_ = 2;
               }
               _loc6_ += _loc7_;
               if(_loc6_ > param3)
               {
                  _loc8_ += param2;
                  _loc6_ = _loc7_;
               }
               _loc8_ += _loc10_;
            }
            _loc11_++;
         }
         return _loc8_;
      }
      
      public static function formatLineX(param1:String, param2:Array = null, param3:int = 21, param4:int = 20, param5:Boolean = false, param6:String = "left") : String
      {
         var _loc8_:Boolean = false;
         var _loc25_:* = 0;
         var _loc24_:* = 0;
         var _loc23_:* = 0;
         var _loc12_:* = 0;
         var _loc21_:String = null;
         var _loc19_:int = 0;
         var _loc9_:String = null;
         var _loc17_:* = 0;
         var _loc13_:int = 0;
         var _loc11_:String = null;
         var _loc22_:RegExp = null;
         if(param3 <= 0)
         {
            param3 = 21;
         }
         if(param1 == "" || param1 == null)
         {
            return "";
         }
         var _loc15_:String = GlobalConfig.FONT_0;
         if(param2 == null)
         {
            param2 = GlobalTextStyle.COLOR_W_B_Y_O;
         }
         if(param2 == HtmlTextFormat.COLOR_GUIDE2)
         {
            _loc8_ = true;
         }
         var _loc7_:Array = [];
         _loc25_ = uint(param2[0]);
         if(param2[1] && param2[1] is uint)
         {
            _loc24_ = uint(param2[1]);
            _loc7_.push("(",")");
         }
         else
         {
            _loc24_ = _loc25_;
         }
         if(param2[2] && param2[2] is uint)
         {
            _loc23_ = uint(param2[2]);
            _loc7_.push("[","]");
         }
         else
         {
            _loc23_ = _loc25_;
         }
         if(param2[3] && param2[3] is uint)
         {
            _loc12_ = uint(param2[3]);
            _loc7_.push("{","}");
         }
         else
         {
            _loc12_ = _loc25_;
         }
         var _loc20_:Number = 0;
         var _loc18_:String = "";
         var _loc10_:int = 0;
         if(MainConfig.$isEnglish)
         {
            _loc21_ = " ";
            _loc10_ = param3 * 2;
         }
         else
         {
            _loc21_ = "";
            _loc10_ = param3;
         }
         var _loc14_:Array = param1.split(_loc21_);
         _loc19_ = 0;
         while(_loc19_ < _loc14_.length)
         {
            _loc9_ = _loc14_[_loc19_];
            if(_loc7_.indexOf(_loc9_) > -1)
            {
               _loc9_ = "";
            }
            if(_loc9_ == "")
            {
               _loc18_ += _loc14_[_loc19_];
            }
            else
            {
               if(!MainConfig.$isEnglish)
               {
                  _loc17_ = uint(_loc9_.charCodeAt(0));
                  if(_loc17_ >= 32 && _loc17_ <= 126)
                  {
                     _loc20_ += 0.5;
                  }
                  else
                  {
                     _loc20_ += 1;
                  }
               }
               else if(_loc14_[_loc19_].length > _loc10_)
               {
                  _loc20_ = 0;
               }
               else
               {
                  _loc13_ = int(_loc14_[_loc19_].indexOf("\n"));
                  if(_loc13_ > -1 && _loc20_ + _loc13_ < _loc10_)
                  {
                     _loc20_ = _loc14_[_loc19_].length - _loc13_;
                  }
                  else
                  {
                     _loc20_ += _loc9_.length + 1;
                  }
               }
               if(_loc20_ > _loc10_)
               {
                  _loc18_ += "\n";
                  _loc20_ = 0;
                  _loc19_--;
               }
               else if(!MainConfig.$isEnglish)
               {
                  if(_loc14_[_loc19_] == "\n")
                  {
                     _loc18_ += "\n";
                     _loc20_ = 0;
                  }
                  else
                  {
                     _loc18_ += _loc14_[_loc19_];
                  }
               }
               else
               {
                  _loc18_ += _loc14_[_loc19_] + " ";
               }
            }
            _loc19_++;
         }
         var _loc16_:String = "#" + _loc25_.toString(16);
         if(param5)
         {
            _loc18_ = "<font color=\"" + _loc16_ + "\" size=\"" + param4 + "\" face=\"" + _loc15_ + "\"><b>" + _loc18_ + "</b></font>";
         }
         else
         {
            _loc18_ = "<font color=\"" + _loc16_ + "\" size=\"" + param4 + "\" face=\"" + _loc15_ + "\">" + _loc18_ + "</font>";
         }
         if(param2[1] && param2[1] is uint)
         {
            _loc11_ = "#" + _loc24_.toString(16);
            _loc22_ = /\(/g;
            if(_loc8_)
            {
               _loc18_ = _loc18_.replace(_loc22_,"<FONT COLOR=\"" + _loc11_ + "\" size=\"" + param4 * 0.7 + "\" face=\"" + _loc15_ + "\">");
            }
            else
            {
               _loc18_ = _loc18_.replace(_loc22_,"<FONT COLOR=\"" + _loc11_ + "\" face=\"" + _loc15_ + "\">");
            }
            _loc22_ = /\)/g;
            _loc18_ = _loc18_.replace(_loc22_,"</FONT>");
         }
         if(param2[2] && param2[2] is uint)
         {
            _loc11_ = "#" + _loc23_.toString(16);
            _loc22_ = /\[/g;
            _loc18_ = _loc18_.replace(_loc22_,"<FONT COLOR=\"" + _loc11_ + "\" face=\"" + _loc15_ + "\"><b>");
            _loc22_ = /\]/g;
            _loc18_ = _loc18_.replace(_loc22_,"</b></FONT>");
         }
         if(param2[3] && param2[3] is uint)
         {
            _loc11_ = "#" + _loc12_.toString(16);
            _loc22_ = /\{/g;
            _loc18_ = _loc18_.replace(_loc22_,"<FONT COLOR=\"" + _loc11_ + "\" face=\"" + _loc15_ + "\"><b>");
            _loc22_ = /\}/g;
            _loc18_ = _loc18_.replace(_loc22_,"</b></FONT>");
         }
         return _loc18_;
      }
      
      public static function clearLine(param1:String) : String
      {
         param1 = param1.replace("\n","");
         param1 = param1.replace("<br>","");
         return param1.replace("</br>","");
      }
      
      public static function isHtml(param1:String) : Boolean
      {
         var _loc3_:int = param1.indexOf("<");
         var _loc2_:int = param1.indexOf(">");
         if(_loc3_ != -1 && _loc2_ != -1 && _loc3_ < _loc2_)
         {
            return true;
         }
         return false;
      }
      
      public static function hasText(param1:String, param2:Array = null) : Boolean
      {
         var _loc3_:int = 0;
         if(param2 == null)
         {
            param2 = BAN_LIST;
         }
         _loc3_ = 0;
         while(_loc3_ < param2.length)
         {
            if(param1.indexOf(param2[_loc3_]) != -1)
            {
               return true;
            }
            _loc3_++;
         }
         return false;
      }
      
      public static function fillStr(param1:String, param2:int, param3:String = " ", param4:Boolean = true) : String
      {
         var _loc7_:int = 0;
         var _loc6_:String = "";
         var _loc5_:int = param2 - param1.length;
         _loc7_ = 0;
         while(_loc7_ < _loc5_)
         {
            _loc6_ += param3;
            _loc7_++;
         }
         if(param4)
         {
            _loc6_ += param1;
         }
         else
         {
            _loc6_ = param1 + _loc6_;
         }
         return _loc6_;
      }
      
      public static function insertStr(param1:String, param2:String = "\n", param3:int = 4, param4:int = 1) : String
      {
         var _loc6_:String = "";
         var _loc5_:String = "";
         var _loc8_:int = 0;
         var _loc7_:int = 0;
         if(param4 <= 0)
         {
            param4 = 2147483647;
         }
         if(param3 <= 0)
         {
            param3 = 1;
         }
         while(_loc7_ < param4)
         {
            _loc5_ = param1.substr(_loc7_ * param3,param3);
            _loc7_++;
            if(_loc5_.length != param3)
            {
               _loc6_ += _loc5_;
               break;
            }
            _loc5_ += param2;
            _loc6_ += _loc5_;
         }
         return _loc6_ + param1.substr(_loc7_ * param3);
      }
      
      public static function replaceString(param1:String, param2:String, param3:String) : String
      {
         var _loc4_:RegExp = new RegExp(param2,"g");
         return param1.replace(_loc4_,param3);
      }
      
      public static function clearString(param1:String) : String
      {
         var _loc2_:RegExp = /[\[\](){}]/g;
         return param1.replace(_loc2_,"");
      }
      
      public static function clearHtmlTag(param1:String) : String
      {
         var _loc2_:RegExp = /<[^>]*>/g;
         return param1.replace(_loc2_,"");
      }
      
      public static function getVector(param1:Class, param2:ApplicationDomain = null) : *
      {
         var _loc4_:String = getQualifiedClassName(param1);
         var _loc3_:String = "__AS3__.vec.Vector.<" + _loc4_ + ">";
         if(!param2)
         {
            param2 = ApplicationDomain.currentDomain;
         }
         if(param2.hasDefinition(_loc3_))
         {
            return param2.getDefinition(_loc3_);
         }
         return null;
      }
      
      public static function sortVector(param1:*, param2:Function) : *
      {
         var _loc3_:Class = null;
         var _loc6_:int = 0;
         var _loc4_:int = 0;
         if(param1.length == 0)
         {
            return param1;
         }
         var _loc5_:* = param1[0];
         _loc3_ = getVector(_loc5_.constructor);
         var _loc7_:* = new _loc3_();
         _loc7_.push(param1[0]);
         _loc6_ = 1;
         while(_loc6_ < param1.length)
         {
            _loc4_ = 0;
            while(_loc4_ < _loc7_.length)
            {
               if(param2(param1[_loc6_],_loc7_[_loc4_]) < 0)
               {
                  _loc7_.splice(_loc4_,0,param1[_loc6_]);
                  break;
               }
               _loc4_++;
            }
            if(_loc4_ == _loc7_.length)
            {
               _loc7_.push(param1[_loc6_]);
            }
            _loc6_++;
         }
         return _loc7_;
      }
      
      public static function coverObj(param1:Object, param2:Object, param3:Boolean = false, param4:Number = -2147483648) : Object
      {
         var _loc8_:* = undefined;
         var _loc6_:Object = null;
         if(param4 == -2147483648)
         {
            param4 = rateY;
         }
         else
         {
            rateY = param4;
         }
         if(!param2 || param4 == 0)
         {
            return param1;
         }
         var _loc5_:Object = {};
         var _loc7_:Array = ["number","int","uint","boolean","array"];
         for(_loc8_ in param1)
         {
            if(param2[_loc8_])
            {
               _loc6_ = typeof param1[_loc8_];
               if(_loc7_.indexOf(_loc6_) >= 0)
               {
                  if(param3)
                  {
                     _loc5_[_loc8_] = param2[_loc8_];
                  }
                  else
                  {
                     _loc5_[_loc8_] = param1[_loc8_] + param2[_loc8_] * param4;
                  }
               }
               else
               {
                  _loc5_[_loc8_] = coverObj(param1[_loc8_],param2[_loc8_],param3,param4);
               }
            }
            else
            {
               _loc5_[_loc8_] = param1[_loc8_];
            }
         }
         return _loc5_;
      }
      
      public static function toTrace(param1:*) : void
      {
         if(MainConfig.$isDebug)
         {
            trace(param1);
         }
      }
      
      public static function toString(param1:Object, param2:int = 0, param3:Boolean = false) : String
      {
         var _loc10_:int = 0;
         var _loc7_:int = 0;
         var _loc9_:String = null;
         var _loc5_:RegExp = null;
         var _loc6_:String = "";
         param2++;
         if(param1 == null)
         {
            return "null";
         }
         var _loc8_:Object = typeof param1;
         var _loc4_:int = 0;
         switch(_loc8_)
         {
            case "number":
               return param1.toString() + "";
            case "string":
               return "\"" + param1 + "\"";
            case "object":
               if(param1 is Array)
               {
                  _loc4_ = int(Tools.getElementNum(param1));
                  if(_loc4_ > 1)
                  {
                     if(param2 > 1)
                     {
                        _loc6_ += "\n";
                     }
                     _loc7_ = 0;
                     while(_loc7_ < param2 - 1)
                     {
                        _loc6_ += "\t";
                        _loc7_++;
                     }
                  }
                  _loc6_ += "[";
                  _loc10_ = 0;
                  while(_loc10_ < param1.length)
                  {
                     if(_loc4_ > 1)
                     {
                        _loc6_ += "\n";
                        _loc7_ = 0;
                        while(_loc7_ < param2)
                        {
                           _loc6_ += "\t";
                           _loc7_++;
                        }
                     }
                     _loc6_ += toString(param1[_loc10_],param2);
                     _loc6_ = _loc6_ + ",";
                     _loc10_++;
                  }
                  if(_loc4_ > 0)
                  {
                     _loc6_ = _loc6_.slice(0,_loc6_.length - 1);
                  }
                  if(_loc4_ > 1)
                  {
                     _loc6_ += "\n";
                     _loc7_ = 0;
                     while(_loc7_ < param2 - 1)
                     {
                        _loc6_ += "\t";
                        _loc7_++;
                     }
                  }
                  _loc6_ += "]";
               }
               else if(param1 is Date)
               {
                  _loc6_ = "new Date(" + (param1 as Date).getTime() + ")";
               }
               else
               {
                  _loc4_ = int(Tools.getElementNum(param1));
                  if(_loc4_ > 1)
                  {
                     if(param2 > 1)
                     {
                        _loc6_ += "\n";
                     }
                     _loc7_ = 0;
                     while(_loc7_ < param2 - 1)
                     {
                        _loc6_ += "\t";
                        _loc7_++;
                     }
                  }
                  _loc6_ += "{";
                  for(_loc9_ in param1)
                  {
                     if(_loc4_ > 1)
                     {
                        _loc6_ += "\n";
                        _loc7_ = 0;
                        while(_loc7_ < param2)
                        {
                           _loc6_ += "\t";
                           _loc7_++;
                        }
                     }
                     _loc5_ = /\D/xgi;
                     if(!isNaN(Number(_loc9_.slice(0,1))) || _loc9_.search(/[^a-zA-Z0-9_]/) != -1)
                     {
                        _loc6_ += "\"" + _loc9_ + "\":" + toString(param1[_loc9_],param2);
                     }
                     else
                     {
                        _loc6_ += _loc9_ + ":" + toString(param1[_loc9_],param2);
                     }
                     _loc6_ += ",";
                  }
                  if(_loc4_ > 0)
                  {
                     _loc6_ = _loc6_.slice(0,_loc6_.length - 1);
                  }
                  if(_loc4_ > 1)
                  {
                     _loc6_ += "\n";
                     _loc7_ = 0;
                     while(_loc7_ < param2 - 1)
                     {
                        _loc6_ += "\t";
                        _loc7_++;
                     }
                  }
                  _loc6_ += "}";
               }
               break;
            case "boolean":
               return param1.toString() + "";
         }
         return _loc6_;
      }
      
      public static function getRandom(param1:int, param2:int) : int
      {
         var _loc3_:int = 0;
         if(param1 == param2)
         {
            return param1;
         }
         if(param1 > param2)
         {
            _loc3_ = param1;
            param1 = param2;
            param2 = _loc3_;
         }
         _loc3_ = param2 - param1 + 1;
         return param1 + Math.random() * _loc3_ | 0;
      }
      
      public static function clone(param1:*) : *
      {
         var _loc2_:ByteArray = new ByteArray();
         _loc2_.writeObject(param1);
         _loc2_.position = 0;
         return _loc2_.readObject();
      }
      
      public static function isNoChildrenInObj(param1:Object) : Boolean
      {
         var _loc2_:int = 0;
         var _loc4_:Object = null;
         var _loc3_:Boolean = true;
         if(param1 != null)
         {
            _loc2_ = 0;
            var _loc6_:int = 0;
            var _loc5_:Object = param1;
            for(_loc4_ in _loc5_)
            {
               _loc2_++;
            }
            if(_loc2_ > 0)
            {
               _loc3_ = false;
            }
         }
         return _loc3_;
      }
      
      public static function randomArray(param1:Array) : Array
      {
         var _sArr:Array = param1;
         _sArr.sort(function():Number
         {
            return Math.random() > 0.5 ? -1 : 1;
         });
         return _sArr;
      }
      
      public static function replaceAllBySplit(param1:String, param2:String, param3:String) : String
      {
         return param1 == null ? null : param1.split(param2).join(param3);
      }
      
      public static function dateFormat(param1:Date, param2:int = 8, param3:String = "YYYY-MM-DD HH:NN:SS", param4:Number = -1) : String
      {
         var _loc11_:Date = new Date();
         var _loc10_:int = param2 == 0 ? 0 : _loc11_.timezoneOffset;
         _loc11_.setTime(param1.time + _loc10_ * 60 * 1000);
         var _loc23_:String = "";
         var _loc16_:Array = ["January","February","March","April","May","June","July","August","September","October","November","December"];
         var _loc14_:Array = ["Sunday","Monday","TuesDay","Wednesday","Thursday","Friday","Saturday"];
         var _loc12_:String = _loc11_.getFullYear().toString();
         var _loc9_:Number = _loc11_.getMonth();
         var _loc7_:String = _loc9_ < 9 ? "0" + (_loc9_ + 1) : (_loc9_ + 1).toString();
         var _loc13_:Number = _loc11_.getDate();
         var _loc20_:String = _loc13_ < 10 ? "0" + _loc13_ : _loc13_.toString();
         var _loc5_:Number = param4 > -1 ? param4 : _loc11_.getHours();
         var _loc19_:String = _loc5_ < 10 ? "0" + _loc5_ : _loc5_.toString();
         var _loc8_:Number = _loc11_.getMinutes();
         var _loc6_:String = _loc8_ < 10 ? "0" + _loc8_ : _loc8_.toString();
         var _loc22_:Number = _loc11_.getSeconds();
         var _loc18_:String = _loc22_ < 10 ? "0" + _loc22_ : _loc22_.toString();
         var _loc15_:Number = _loc11_.getDay();
         var _loc21_:String = "0" + (_loc15_ + 1);
         var _loc17_:String = "";
         if(param3.charAt(param3.length - 1) == "H")
         {
            _loc17_ = GlobalLanguageStr.getLanguageStr(20488);
         }
         _loc23_ = param3;
         _loc23_ = _loc23_.replace(/YYYY/g,_loc12_);
         _loc23_ = _loc23_.replace(/YY/g,_loc12_.slice(-2));
         _loc23_ = _loc23_.replace(/MMMM/g,_loc16_[_loc9_]);
         _loc23_ = _loc23_.replace(/MMM/g,_loc16_[_loc9_].substr(0,3));
         _loc23_ = _loc23_.replace(/MM/g,_loc7_);
         _loc23_ = _loc23_.replace(/M/g,_loc9_ + 1);
         _loc23_ = _loc23_.replace(/DD/g,_loc20_);
         _loc23_ = _loc23_.replace(/D/g,_loc13_);
         _loc23_ = _loc23_.replace(/A/g,_loc5_ < 12 ? "AM" : "PM");
         _loc23_ = _loc23_.replace(/HH/g,_loc5_);
         _loc23_ = _loc23_.replace(/L/g,_loc5_ % 12);
         _loc23_ = _loc23_.replace(/NN/g,_loc6_);
         _loc23_ = _loc23_.replace(/SS/g,_loc18_);
         _loc23_ = _loc23_.replace(/EEEE/g,_loc14_[_loc15_]);
         _loc23_ = _loc23_.replace(/EEE/g,_loc14_[_loc15_].substr(0,3));
         _loc23_ = _loc23_.replace(/EE/g,_loc21_);
         _loc23_ = _loc23_.replace(/E/g,_loc15_ + 1);
         return _loc23_ + _loc17_;
      }
      
      public static function dateFormatByMS(param1:Number, param2:String = "YYYY-MM-DD HH:NN:SS") : String
      {
         var _loc3_:Date = new Date();
         _loc3_.setTime(param1);
         return dateFormat(_loc3_,0,param2,_loc3_.getHours());
      }
      
      public static function timeFormat(param1:int, param2:Boolean = true, param3:Boolean = true) : String
      {
         param1 = int(param1 < 0 ? 0 : param1);
         var _loc4_:Number = param1 / 3600 | 0;
         var _loc6_:Number = param1 % 3600 / 60 | 0;
         var _loc9_:Number = param1 - 60 * _loc6_ - _loc4_ * 3600 | 0;
         var _loc8_:String = _loc4_ < 10 ? "0" + _loc4_ : _loc4_.toString();
         var _loc5_:String = _loc6_ < 10 ? "0" + _loc6_ : _loc6_.toString();
         var _loc7_:String = _loc9_ < 10 ? "0" + _loc9_ : _loc9_.toString();
         if(!param3)
         {
            return _loc8_ + ":" + _loc5_ + ":" + "00";
         }
         if(_loc8_ == "00" && param2 == false)
         {
            return _loc6_.toString() + ":" + _loc7_;
         }
         return _loc8_ + ":" + _loc5_ + ":" + _loc7_;
      }
      
      public static function timeFormatAll(param1:int, param2:Boolean = true) : String
      {
         var _loc8_:String = null;
         var _loc11_:String = timeFormat(param1);
         var _loc7_:String = GlobalLanguageStr.getLanguageStr(20478);
         var _loc3_:String = GlobalLanguageStr.getLanguageStr(20479);
         var _loc5_:String = GlobalLanguageStr.getLanguageStr(20480);
         var _loc13_:String = GlobalLanguageStr.getLanguageStr(20481);
         var _loc6_:Array = _loc11_.split(":");
         var _loc12_:int = _loc6_[0] / 24;
         var _loc10_:int = _loc6_[0] % 24;
         var _loc9_:int = int(_loc6_[1]);
         var _loc4_:int = int(_loc6_[2]);
         if(param2)
         {
            if(_loc12_ > 0)
            {
               _loc8_ = _loc12_ + _loc7_ + _loc10_ + _loc3_ + _loc9_ + _loc5_ + "[" + _loc4_ + "]" + _loc13_;
            }
            else if(_loc10_ > 0)
            {
               _loc8_ = _loc10_ + _loc3_ + _loc9_ + _loc5_ + "[" + _loc4_ + "]" + _loc13_;
            }
            else if(_loc9_ > 0)
            {
               _loc8_ = _loc9_ + _loc5_ + "[" + _loc4_ + "]" + _loc13_;
            }
            else if(_loc4_ > 0)
            {
               _loc8_ = "[" + _loc4_ + "]" + _loc13_;
            }
            else
            {
               _loc8_ = GlobalLanguageStr.getLanguageStr(20482);
            }
         }
         else if(_loc12_ > 0)
         {
            _loc8_ = _loc12_ + _loc7_ + _loc10_ + _loc3_ + _loc9_ + _loc5_;
         }
         else if(_loc10_ > 0)
         {
            _loc8_ = _loc10_ + _loc3_ + _loc9_ + _loc5_;
         }
         else if(_loc9_ > 0)
         {
            _loc8_ = _loc9_ + _loc5_;
         }
         else if(_loc4_ >= 0)
         {
            _loc8_ = _loc4_ + _loc13_;
         }
         return _loc8_;
      }
      
      public static function timeDay(param1:int) : String
      {
         var _loc5_:String = null;
         var _loc4_:String = timeFormat(param1);
         var _loc6_:String = GlobalLanguageStr.getLanguageStr(20478);
         var _loc3_:Array = _loc4_.split(":");
         var _loc2_:int = _loc3_[0] / 24;
         if(_loc2_ > 0)
         {
            _loc5_ = _loc2_ + _loc6_;
         }
         return _loc5_;
      }
      
      public static function timeFormatToDate(param1:int, param2:Boolean = false) : String
      {
         var _loc7_:String = timeFormat(param1);
         var _loc9_:String = GlobalLanguageStr.getLanguageStr(20478);
         var _loc3_:String = GlobalLanguageStr.getLanguageStr(20479);
         var _loc5_:String = GlobalLanguageStr.getLanguageStr(20487);
         var _loc6_:Array = _loc7_.split(":");
         var _loc4_:int = int(_loc6_[0]);
         var _loc10_:int = int(_loc6_[1]);
         var _loc8_:String = "";
         if(_loc4_ > 0)
         {
            if(_loc4_ < 24)
            {
               _loc8_ += _loc4_ + _loc3_;
            }
            else if(param2)
            {
               _loc8_ += _loc4_ + _loc3_;
            }
            else
            {
               _loc8_ += int(_loc4_ / 24) + _loc9_ + int(_loc4_ % 24) + _loc3_;
            }
         }
         return _loc8_ + (_loc10_ + _loc5_);
      }
      
      public static function align(param1:DisplayObject, param2:DisplayObject, param3:Array = null) : void
      {
         var _loc5_:Rectangle = null;
         if(!param3)
         {
            param3 = [0.5,0.5,0,0];
         }
         _loc5_ = param1.getBounds(param2);
         var _loc4_:int = int(param2 is Stage ? (param2 as Stage).stageWidth : param2.width);
         var _loc6_:int = int(param2 is Stage ? (param2 as Stage).stageHeight : param2.height);
         param1.x += -_loc5_.x + param3[0] * (_loc4_ - param1.width) + param3[2];
         param1.y += -_loc5_.y + param3[1] * (_loc6_ - param1.height) + param3[3];
      }
      
      public static function setText(param1:TextField, param2:*, param3:uint = 4294967295) : void
      {
         var _loc4_:TextFormat = null;
         if(param1.mouseEnabled == true)
         {
            _loc4_ = param1.defaultTextFormat;
            if($isIOS)
            {
               if(_loc4_.size)
               {
                  param1.y += int(_loc4_.size) / 4;
               }
               else
               {
                  param1.y += 4;
               }
            }
            param1.mouseEnabled = false;
         }
         param2 = String(param2);
         if(isHtml(param2 as String))
         {
            param1.htmlText = param2;
         }
         else
         {
            param1.text = param2;
            if(param3 < 4294967295)
            {
               _loc4_ = param1.getTextFormat();
               _loc4_.color = param3;
               param1.setTextFormat(_loc4_);
            }
         }
      }
      
      public static function timeToFormatShort(param1:int) : String
      {
         var _loc4_:int = param1 / 60 / 60;
         var _loc3_:int = param1 / 60;
         var _loc2_:int = param1;
         if(_loc4_ > 0)
         {
            return Math.floor(_loc4_) + GlobalLanguageStr.getLanguageStr(20479);
         }
         if(_loc3_ > 0)
         {
            return Math.floor(_loc3_) + GlobalLanguageStr.getLanguageStr(20480);
         }
         return Math.floor(_loc2_) + GlobalLanguageStr.getLanguageStr(20481);
      }
      
      public static function get $isIOS() : Boolean
      {
         var _loc1_:String = Capabilities.os;
         _loc1_ = _loc1_.toLocaleUpperCase();
         if(_loc1_ == "IOS")
         {
            return true;
         }
         return false;
      }
      
      public static function get $isAndroid() : Boolean
      {
         var _loc1_:String = Capabilities.os;
         _loc1_ = _loc1_.toLocaleUpperCase();
         if(_loc1_ == "android")
         {
            return true;
         }
         return false;
      }
      
      public static function getVerson() : String
      {
         return "?v=" + new Date().getTime().toString() + "_" + (Math.random() * 1000000).toString();
      }
      
      public static function compareVersion(param1:String, param2:String) : int
      {
         var _loc8_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc7_:Array = param1.split(".");
         var _loc6_:Array = param2.split(".");
         if(_loc7_.length != _loc6_.length)
         {
            return -2;
         }
         var _loc5_:int = int(_loc7_.length);
         _loc8_ = 0;
         while(_loc8_ < _loc5_)
         {
            _loc3_ = int(_loc7_[_loc8_]);
            _loc4_ = int(_loc6_[_loc8_]);
            if(_loc3_ > _loc4_)
            {
               return 1;
            }
            if(_loc3_ < _loc4_)
            {
               return -1;
            }
            _loc8_++;
         }
         return 0;
      }
      
      public static function checkObjTypeIsTrue(param1:*, param2:String) : Boolean
      {
         var _loc3_:String = getQualifiedClassName(param1);
         _loc3_ = _loc3_.split("::")[1];
         return _loc3_ == param2;
      }
      
      public static function checkObjSuperTypeIsTrue(param1:*, param2:String) : Boolean
      {
         var _loc3_:String = getQualifiedSuperclassName(param1);
         _loc3_ = _loc3_.split("::")[1];
         return _loc3_ == param2;
      }
      
      public static function textBitmap(param1:String, param2:int = 0) : Bitmap
      {
         var _loc5_:Sprite = new Sprite();
         var _loc4_:Bitmap = null;
         var _loc6_:TextField = new TextField();
         var _loc3_:TextFormat = new TextFormat();
         _loc3_.leading = 3;
         _loc6_.autoSize = "left";
         _loc6_.multiline = true;
         _loc6_.htmlText = param1;
         if(_loc6_.bottomScrollV > 1)
         {
            _loc6_.setTextFormat(_loc3_);
         }
         _loc5_.addChild(_loc6_);
         _loc4_ = getBitmap(_loc5_);
         if(param2 > 0 && _loc4_.width > param2)
         {
            _loc4_.width = param2;
         }
         return _loc4_;
      }
      
      public static function getBitmap(param1:DisplayObject, param2:int = 1) : Bitmap
      {
         var _loc6_:Rectangle = param1.getBounds(param1);
         var _loc4_:int = _loc6_.width + param2 * 2;
         var _loc3_:int = _loc6_.height + param2 * 2;
         var _loc5_:BitmapData = new BitmapData(_loc4_,_loc3_,true,16777215);
         _loc5_.draw(param1,new Matrix(1,0,0,1,-_loc6_.x + param2,-_loc6_.y + param2));
         return new Bitmap(_loc5_);
      }
      
      public static function colorChangeToLight(param1:DisplayObject) : void
      {
         if(param1 != null)
         {
            param1.transform.colorTransform = new ColorTransform(1,1,1,1,-128,-128,-128,-128);
         }
      }
      
      public static function stopAllMc(param1:DisplayObject, param2:Boolean = false) : void
      {
         var _loc4_:DisplayObject = null;
         var _loc3_:DisplayObjectContainer = null;
         var _loc9_:int = 0;
         var _loc6_:MovieClip = null;
         var _loc8_:DisplayObjectContainer = null;
         var _loc7_:int = 0;
         var _loc5_:MovieClip = null;
         if(!param2)
         {
            if(param1 is DisplayObjectContainer)
            {
               _loc3_ = param1 as DisplayObjectContainer;
               _loc9_ = _loc3_.numChildren;
               if(_loc3_ is MovieClip)
               {
                  _loc6_ = _loc3_ as MovieClip;
                  _loc6_.stop();
               }
               while(_loc9_-- > 0)
               {
                  _loc4_ = _loc3_.getChildAt(_loc9_);
                  stopAllMc(_loc4_,param2);
               }
            }
         }
         else if(param1 is DisplayObjectContainer)
         {
            _loc8_ = param1 as DisplayObjectContainer;
            _loc7_ = _loc8_.numChildren;
            if(_loc8_ is MovieClip)
            {
               _loc5_ = _loc8_ as MovieClip;
               _loc5_.play();
            }
            while(_loc7_-- > 0)
            {
               _loc4_ = _loc8_.getChildAt(_loc7_);
               stopAllMc(_loc4_,param2);
            }
         }
      }
      
      public static function getGameDayNumber(milliseconds:Number) : Number
      {
         var settings:Object = GlobalData.$mConfig_simple;
         var resetHour:Number = settings && settings.daily_reset_hour !== undefined ? Number(settings.daily_reset_hour) : 0;
         var timezoneHours:Number = settings && settings.daily_timezone_offset_hours !== undefined ? Number(settings.daily_timezone_offset_hours) : 8;
         return Math.floor((milliseconds+(timezoneHours-resetHour)*3600000)/86400000);
      }

      public static function getGameDayKey(milliseconds:Number) : String
      {
         var day:Date = new Date(getGameDayNumber(milliseconds)*86400000);
         var month:String = day.monthUTC+1<10 ? "0"+(day.monthUTC+1) : String(day.monthUTC+1);
         var date:String = day.dateUTC<10 ? "0"+day.dateUTC : String(day.dateUTC);
         return day.fullYearUTC+"-"+month+"-"+date;
      }

      public static function checkIsSameDay(param1:Number, param2:Number) : Boolean
      {
         return param1>0 && param2>0 && getGameDayNumber(param1)==getGameDayNumber(param2);
      }

      public static function checkIsPrevDay(param1:Number, param2:Number) : Boolean
      {
         return param1>0 && param2>0 && Math.abs(getGameDayNumber(param1)-getGameDayNumber(param2))==1;
      }

      public static function getBlendMode(param1:String = null, param2:Number = 1, param3:Number = 1, param4:Number = 1) : String
      {
         if(!param1)
         {
            param1 = "normal";
         }
         if(param2 == 1 && param3 == 1 && param4 == 1)
         {
            return param1;
         }
         return param1 + "|" + param2 + "," + param3 + "," + param4;
      }
      
      public static function getObjectKeyValue(param1:Object) : Array
      {
         var _loc2_:Array = null;
         if(param1 != null)
         {
            _loc2_ = [];
            for(var _loc3_:Object in param1)
            {
               _loc2_[0] = _loc3_.toString();
               _loc2_[1] = param1[_loc3_];
            }
         }
         return _loc2_;
      }
      
      public static function strIsNull(param1:String) : Boolean
      {
         return param1 == "" || param1 == null;
      }
      
      public static function strIsNumber(param1:String) : Boolean
      {
         return /^\d+$/.test(param1);
      }
      
      public static function strIsHalf(param1:String) : Boolean
      {
         var _loc2_:uint = param1.charCodeAt(0);
         return _loc2_ <= 255;
      }
      
      public static function formateNum(param1:Number) : String
      {
         var _loc2_:String = "";
         if(MainConfig.$isEnglish)
         {
            if(param1 >= 10000000000)
            {
               param1 = Math.floor(param1 / 1000000000);
               _loc2_ = param1 + "B";
            }
            else if(param1 >= 10000000)
            {
               param1 = Math.floor(param1 / 1000000);
               _loc2_ = param1 + "M";
            }
            else if(param1 >= 10000)
            {
               param1 = Math.floor(param1 / 1000);
               _loc2_ = param1 + "k";
            }
            else
            {
               _loc2_ = param1 + "";
            }
         }
         else if(param1 >= 1000000000)
         {
            param1 = Math.floor(param1 / 100000000);
            _loc2_ = param1 + "亿";
         }
         else if(param1 > 100000)
         {
            param1 = Math.floor(param1 / 10000);
            _loc2_ = param1 + "万";
         }
         else
         {
            _loc2_ = param1 + "";
         }
         return _loc2_;
      }
      
      public static function formateIntToStrBy0(param1:int, param2:int) : String
      {
         var _loc5_:Number = Math.pow(10,param2);
         var _loc4_:String = String(_loc5_ + param1);
         var _loc7_:int = 1;
         var _loc3_:int = _loc4_.length;
         var _loc6_:String = "";
         _loc7_ = 1;
         while(_loc7_ < _loc3_)
         {
            _loc6_ += _loc4_.charAt(_loc7_);
            _loc7_++;
         }
         return _loc6_;
      }
      
      public static function getServerNowTimeDate(param1:Number) : Date
      {
         var _loc3_:Date = new Date();
         _loc3_.setTime(param1);
         return new Date(_loc3_.fullYearUTC,_loc3_.monthUTC,_loc3_.dateUTC,_loc3_.hoursUTC,_loc3_.minutesUTC,_loc3_.secondsUTC,_loc3_.millisecondsUTC);
      }
      
      public static function getScale9Image(param1:String, param2:Rectangle) : Scale9Image
      {
         var _loc3_:Scale9Textures = new Scale9Textures(GlobalFunction.getTexture(param1),param2);
         return new Scale9Image(_loc3_);
      }
      
      public static function changeArrayToObject(param1:Array) : Object
      {
         var _loc6_:int = 0;
         var _loc3_:Object = null;
         var _loc4_:int = int(param1.length);
         var _loc2_:Object = {};
         _loc6_ = 0;
         while(_loc6_ < _loc4_)
         {
            _loc3_ = param1[_loc6_];
            for(var _loc5_:Object in _loc3_)
            {
               _loc2_[_loc5_] = _loc3_[_loc5_];
            }
            _loc6_++;
         }
         return _loc2_;
      }
      
      public static function getObjectAllProperty(param1:Object) : Array
      {
         var _loc2_:Array = [];
         for(var _loc3_:String in param1)
         {
            _loc2_.push(_loc3_);
         }
         return _loc2_;
      }
      
      public static function getArrayLength(param1:Array) : int
      {
         var _loc3_:int = 0;
         var _loc2_:int = 0;
         if(param1 != null)
         {
            _loc3_ = 0;
            while(_loc3_ < param1.length)
            {
               if(!(param1[_loc3_] == null || param1[_loc3_] == ""))
               {
                  _loc2_++;
               }
               _loc3_++;
            }
         }
         else
         {
            _loc2_ = 0;
         }
         return _loc2_;
      }
      
      public static function formateGuideObj(param1:*) : *
      {
         var _loc10_:int = 0;
         var _loc8_:int = 0;
         var _loc9_:String = null;
         var _loc13_:String = null;
         var _loc5_:Array = null;
         var _loc6_:Array = null;
         var _loc12_:Class = null;
         var _loc3_:* = Tools.clone(param1);
         var _loc2_:Array = ["GlobalLanguageStr.getLanguageStr","GlobalFunction.newDate"];
         var _loc4_:int = 0;
         _loc4_++;
         if(_loc3_ == null)
         {
            return null;
         }
         var _loc7_:Object = typeof _loc3_;
         var _loc11_:int = 0;
         switch(_loc7_)
         {
            case "string":
               _loc13_ = _loc3_ as String;
               if(_loc13_.indexOf(_loc2_[0]) == 0)
               {
                  _loc5_ = _loc13_.split("|");
                  _loc13_ = _loc5_[0];
                  _loc6_ = _loc13_.split(".");
                  _loc12_ = getDefinitionByName("com.meng52.game.global::" + _loc6_[0]) as Class;
                  _loc3_ = _loc12_[_loc6_[1]](_loc5_[1]);
               }
               if(_loc13_.indexOf(_loc2_[1]) == 0)
               {
                  _loc5_ = _loc13_.split("|");
                  _loc13_ = _loc5_[0];
                  _loc6_ = _loc13_.split(".");
                  _loc12_ = getDefinitionByName("com.meng52.game.global::" + _loc6_[0]) as Class;
                  var _temp_9:* = _loc12_;
                  _loc3_ = _loc12_[_loc6_[1]](_loc5_.length == 1 ? null : _loc5_[1]);
               }
               break;
            case "object":
               if(_loc3_ is Array)
               {
                  _loc10_ = 0;
                  while(_loc10_ < _loc3_.length)
                  {
                     _loc3_[_loc10_] = formateGuideObj(_loc3_[_loc10_]);
                     _loc10_++;
                  }
               }
               else if(!(_loc3_ is Date))
               {
                  for(_loc9_ in _loc3_)
                  {
                     _loc3_[_loc9_] = formateGuideObj(_loc3_[_loc9_]);
                  }
               }
         }
         return _loc3_;
      }
   }
}


