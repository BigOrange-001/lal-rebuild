package com.meng52.game.ui.effect
{
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.map.GameMapConfig;
   import com.meng52.game.ui.map.GameMapLayer;
   import starling.animation.Tween;
   import starling.display.DisplayObject;
   import starling.display.DisplayObjectContainer;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.text.TextField;

   public class BaseLayer extends Sprite
   {

      public static const POP_Y:int = 30;

      public var refreshFunction:Function = null;

      public function BaseLayer()
      {
         super();
         touchable = false;
      }

      public function addDis(param1:DisplayObject, param2:int = 0, param3:DisplayObjectContainer = null) : void
      {
         if(!param3)
         {
            param3 = this;
         }
         param2 = Math.max(0,param3.numChildren - param2);
         param3.addChildAt(param1,param2);
      }

      public function setFirst(param1:DisplayObject) : void
      {
         if(contains(param1))
         {
            setChildIndex(param1,numChildren - 1);
         }
      }

      public function sort() : void
      {
         sortChildren(compareFunction);
      }

      public function compareFunction(param1:DisplayObject, param2:DisplayObject) : int
      {
         if(param1.y > param2.y)
         {
            return 1;
         }
         if(param1.y < param2.y)
         {
            return -1;
         }
         return 0;
      }

      override public function addChildAt(param1:DisplayObject, param2:int) : DisplayObject
      {
         param2 = Math.max(0,Math.min(numChildren,param2));
         return super.addChildAt(param1,param2);
      }

      public function popTextForAvatar(param1:String, param2:Avatar, param3:uint = 16728128, param4:uint = 20, param5:Number = -1, param6:String = null, param7:int = 30) : void
      {
         var _loc10_:GameMapLayer = GameMapLayer.gl;
         var _loc8_:int = param2.fightRes.x + _loc10_.getLineSpr(param2.line).x;
         var _loc9_:int = param2.fightRes.y;
         popText(param1,_loc8_,_loc9_,param3,param4,param5,param2.team == 1,param6,param7);
      }

      public function popText(param1:String, param2:int, param3:int, param4:uint = 16728128, param5:uint = 20, param6:Number = -1, param7:Boolean = false, param8:String = null, param9:int = 30) : void
      {
         var _spr:Sprite;
         var _sprTF:Sprite;
         var _colorChar:uint;
         var _textField:TextField;
         var i:int;
         var _length:int;
         var _tween:Tween;
         var _yOffset:int;
         var _yPOP:int;
         var _firstNum:Boolean;
         var _isNum:Boolean;
         var _small:Boolean;
         var _timeChar:Number;
         var _char:String;
         var _yy:int;
         var _scale:Number;
         var _textWidth:int;
         var _hasSkillBg:Boolean;
         var _textAllWidth:int;
         var _width:int;
         var _bg:Image;
         var _str:String = param1.replace(/([+-]?\d+\.\d+)/g,function(...parts):String
         {
            var value:Number = Number(parts[0]);
            return (String(parts[0]).charAt(0) == "+" && value >= 0 ? "+" : "") + Math.round(value).toString();
         });
         var _x:int = param2;
         var _y:int = param3;
         var _color:uint = param4;
         var _size:uint = param5;
         var _time:Number = param6;
         var _isDown:Boolean = param7;
         var _bgStr:String = param8;
         var _popY:int = param9;
         var _gl:GameMapLayer = GameMapLayer.gl;
         var _scaleStart:Number = 1;
         var _scaleMiddle:Number = 1.2;
         var _scaleEnd:Number = 0.5;
         if(_time < 0)
         {
            _time = 0.4;
         }
         _spr = new Sprite();
         _sprTF = new Sprite();
         _length = _str.length;
         _yOffset = int(_isDown ? 45 : -45);
         _yPOP = int(_isDown ? _popY : -_popY);
         _time += _length / 10;
         _firstNum = false;
         _isNum = false;
         _small = false;
         _hasSkillBg = _bgStr && _bgStr != "critBg";
         _textAllWidth = 0;
         _textField = DisplayTools.newTextField(_str,"",_size,16777215);
         _scale = 1;
         _textField.pivotX = _textField.width / 2;
         _textField.scaleX = _textField.scaleY = _scale;
         if(!_hasSkillBg)
         {
            _textField.fontName = "Font_numAndtag_1";
         }
         _textField.addEventListener("removedFromStage",DisplayTools.clearObject);
         _textAllWidth = _textField.textBounds.width;
         _textField.y = -_yPOP;
         _textField.scaleX = _textField.scaleY = 0.2;
         _textField.visible = false;
         _sprTF.addChildAt(_textField,0);
         _timeChar = 0.9 / (_length + 5) + 0.1;
         _tween = new Tween(_textField,_timeChar,"easeOutBack");
         _tween.delay = i * 0.9 / 2 / (_length + 5) + 0.1 / 2;
         _tween.animate("y",_yy);
         _tween.animate("color",_color);
         _tween.onStart = function(param1:TextField):void
         {
            param1.visible = true;
         };
         _tween.onStartArgs = [_textField];
         _timeChar = _timeChar + _tween.delay;
         _gl.addTween(_tween);
         _tween = new Tween(_textField,_timeChar / 2,"easeOut");
         _tween.scaleTo(_scale * 1.6);
         _gl.addTween(_tween);
         _tween = new Tween(_textField,_timeChar / 2,"easeIn");
         _tween.delay = _timeChar / 2;
         _tween.scaleTo(_scale);
         _gl.addTween(_tween);
         _spr.addChild(_sprTF);
         if(MainConfig.$isEnglish)
         {
            _width = _textAllWidth * 1.5 + 20;
         }
         else
         {
            _width = _textAllWidth * 1.5 + 20;
         }
         if(_bgStr)
         {
            _bg = DisplayTools.newImg(_bgStr);
            _bg.width = _width;
            _bg.height = _size * 1.4 + 20;
            if(_bgStr == "critBg")
            {
               _tween = new Tween(_bg,0.9 / 2,"easeOutBack");
               _tween.animate("scaleX",_bg.scaleX * 1.6);
               _tween.animate("scaleY",_bg.scaleY * 2.4);
               _gl.addTween(_tween);
            }
            else
            {
               _bg.y += 8;
            }
            _spr.addChildAt(_bg,0);
         }
         _spr.x = Math.max(_width / 2 - 20,Math.min(GameMapConfig.FIGHT_WIDTH - _width / 2,_x));
         _spr.y = Math.max(0,Math.min(GameMapConfig.FIGHT_HEIGHT - _yPOP,_y + _yOffset));
         _spr.scaleX = _spr.scaleY = _scaleStart;
         _spr.alpha = 0.5;
         _tween = new Tween(_spr,0.9 / 4,"easeInOut");
         _tween.fadeTo(1);
         _gl.addTween(_tween);
         _tween = new Tween(_spr,0.9,"easeInOut");
         _tween.scaleTo(1);
         _tween.animate("y",_spr.y + _yPOP);
         _gl.addTween(_tween);
         if(_time != 2147483647)
         {
            _tween = new Tween(_spr,0.4,"easeInOut");
            _tween.delay = _time;
            _tween.fadeTo(0);
            _tween.onComplete = DisplayTools.clearObject;
            _tween.onCompleteArgs = [_spr];
            _gl.addTween(_tween);
         }
         this.addChild(_spr);
      }

      public function clear() : void
      {
         removeChildren(0,-1,true);
      }
   }
}
