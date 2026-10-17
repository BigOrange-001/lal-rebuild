package com.meng52.game.ui.stage
{
   import com.meng52.game.Game;
   import com.meng52.game.command.avatar.AvatarData;
   import com.meng52.game.command.avatar.AvatarManager;
   import com.meng52.game.command.effect.EffectManager;
   import com.meng52.game.command.map.GameMapManager;
   import com.meng52.game.command.skill.SkillSetManager;
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalLocalStore;
   import com.meng52.game.global.GlobalPFANE;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.guide.Guide;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.module.map.GameMap;
   import com.meng52.game.module.map.GameMapConfig;
   import com.meng52.game.module.map.GameMapTools;
   import com.meng52.game.test.TestButton;
   import com.meng52.game.ui.effect.BaseLayer;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.element.AnimationSprite;
   import com.meng52.game.ui.element.HtmlTextField;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.element.LOL_TextField;
   import com.meng52.game.ui.element.LOL_TextPop;
   import com.meng52.game.ui.map.GameMapLayer;
   import com.meng52.game.ui.screen.PanelCenterShopVIP;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.HtmlTextFormat;
   import com.meng52.utils.LocalStore;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import flash.geom.Point;
   import starling.animation.Juggler;
   import starling.animation.Tween;
   import starling.display.DisplayObject;
   import starling.display.Image;
   import starling.display.MovieClip;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.EnterFrameEvent;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.filters.ColorMatrixFilter;
   import starling.text.BitmapFont;
   import starling.text.TextField;
   
   public class LayoutUIAnimation extends BaseLayer
   {
      
      public static const GUIDE_CLICK:String = "guideClick";
      
      public static const GUIDE_MOUSE:String = "guideMouse";
      
      public static var FONT_SIZE:int = 25;
      
      public static const TRANSMISSION_SPEED:Number = 0.5;
      
      public static const LEAF_SPEED:Number = 1;
      
      public static const ARROWHEAD_ROTATION:Number = -2;
      
      public static const OFFSET_Y:int = 45;
      
      public static const POP_Y:int = 30;
      
      public static const POP_DIS:int = 100;
      
      public static const POP_DIS_Y:int = 80;
      
      public static const POP_TIME:Number = 0.9;
      
      public static const POP_TIME_MIN:Number = 0.1;
      
      public static const DURATION_TIME:Number = 0.4;
      
      public static const ALPHA_TIME:Number = 0.4;
      
      private static var onlyExample:LayoutUIAnimation = null;
      
      public static var lastTime:Number = 0;
      
      public static var isPlay:Boolean = true;
      
      protected var m_transmission:Sprite;
      
      protected var m_arrowhead:Sprite;
      
      protected var m_arrowheadImg:Image;
      
      protected var m_click:Sprite;
      
      protected var m_clickImg:Image;
      
      protected var m_mask:Image;
      
      protected var m_quad:Quad;
      
      protected var m_leafs:Sprite;
      
      protected var m_infoTf:HtmlTextField;
      
      private var m_infoPop:LOL_TextPop;
      
      protected var m_next:LOL_Button;
      
      protected var m_replay:LOL_Button;
      
      protected var m_skip:LOL_Button;
      
      protected var m_test:LOL_Button;
      
      protected var m_storeClear:LOL_Button;
      
      public var jugglerA:Juggler;
      
      public var jugglerG:Juggler;
      
      public var animationLayer:Sprite;
      
      public var guideLayer:Sprite;
      
      public var tempUIName:String;
      
      private var txt1:TextField;
      
      private var txt:TextField;
      
      public function LayoutUIAnimation()
      {
         super();
         touchable = true;
         init();
      }
      
      public static function getOnlyExample() : LayoutUIAnimation
      {
         if(onlyExample == null)
         {
            onlyExample = new LayoutUIAnimation();
         }
         return onlyExample;
      }
      
      public static function heartbeat(param1:DisplayObject, param2:Number, param3:Number, param4:Number, param5:Number, param6:Juggler = null) : void
      {
         var _loc7_:Tween = null;
         if(!param6)
         {
            param6 = GlobalData.$mStarling.juggler;
         }
         if(!param1)
         {
            return;
         }
         param6.removeTweens(param1);
         _loc7_ = new Tween(param1,param4,"easeInOut");
         if(param1.scaleX <= param2)
         {
            _loc7_.delay = param5;
            _loc7_.scaleTo(param3);
         }
         else
         {
            _loc7_.scaleTo(param2);
         }
         _loc7_.onComplete = heartbeat;
         _loc7_.onCompleteArgs = [param1,param2,param3,param4,param5,param6];
         param6.add(_loc7_);
      }
      
      public static function removeSelfDispose(param1:Event) : void
      {
         (param1.currentTarget as DisplayObject).dispose();
      }
      
      public function init() : void
      {
         if(MainConfig.$isEnglish)
         {
            FONT_SIZE = 20;
         }
         jugglerA = new Juggler();
         jugglerG = new Juggler();
         guideLayer = new Sprite();
         guideLayer.touchable = true;
         animationLayer = new Sprite();
         animationLayer.touchable = false;
         this.addChild(animationLayer);
         this.addChild(guideLayer);
         addEventListener("enterFrame",onEnterFrame);
      }
      
      private function onEnterFrame(param1:EnterFrameEvent) : void
      {
         if(!isPlay)
         {
            return;
         }
         jugglerA.advanceTime(param1.passedTime);
         jugglerG.advanceTime(param1.passedTime);
      }
      
      public function showShake(param1:Boolean = true) : void
      {
         if(m_arrowhead && !GlobalData.$currentGuide)
         {
            m_arrowhead.visible = param1;
            if(m_click)
            {
               m_click.visible = param1;
            }
         }
      }
      
      public function addShake(param1:int, param2:int, param3:Number = 0.4, param4:Boolean = true, param5:String = "guideMouse") : void
      {
         var _tween:Tween;
         var _x:int = param1;
         var _y:int = param2;
         var _delay:Number = param3;
         var _hasClick:Boolean = param4;
         var _id:String = param5;
         if(!m_arrowhead)
         {
            m_arrowheadImg = DisplayTools.newImg(_id);
            m_arrowheadImg.pivotX = m_arrowheadImg.width;
            m_arrowheadImg.pivotY = m_arrowheadImg.height / 2;
            m_arrowhead = new Sprite();
            m_arrowhead.addEventListener("removedFromStage",removedFromStage);
            m_arrowhead.addChild(m_arrowheadImg);
         }
         if(_hasClick)
         {
            if(!m_click)
            {
               m_clickImg = DisplayTools.newImg("guideClick");
               m_clickImg.alpha = 0.6;
               m_click = new Sprite();
               m_click.addChild(m_clickImg);
            }
            m_clickImg.scaleX = m_clickImg.scaleY = 1.3;
            heartbeat(m_clickImg,1.3,1.6,0.5,0,jugglerG);
            m_click.x = _x;
            m_click.y = _y;
            m_click.alpha = 0;
            m_click.visible = true;
            guideLayer.addChild(m_click);
            jugglerG.removeTweens(m_click);
            _tween = new Tween(m_click,0.5,"easeInOut");
            _tween.delay = _delay;
            _tween.fadeTo(1);
            jugglerG.add(_tween);
         }
         else
         {
            jugglerG.removeTweens(m_click);
            m_click.visible = false;
         }
         m_arrowheadImg.x = 0;
         shake(m_arrowheadImg,-40,0,0.5);
         m_arrowhead.x = _x;
         m_arrowhead.y = _y;
         m_arrowhead.rotation = -2;
         m_arrowhead.alpha = 0;
         m_arrowhead.visible = true;
         guideLayer.addChild(m_arrowhead);
         jugglerG.removeTweens(m_arrowhead);
         _tween = new Tween(m_arrowhead,0.5,"easeInOut");
         _tween.delay = _delay;
         _tween.fadeTo(1);
         _tween.onStart = function():void
         {
            GlobalData.$mGameClassObject.addChild(LayoutUIAnimation.getOnlyExample());
         };
         jugglerG.add(_tween);
      }
      
      public function getArrowhead() : Sprite
      {
         return m_arrowhead;
      }
      
      public function hideShake() : void
      {
         if(m_arrowhead)
         {
            m_arrowhead.visible = false;
            if(m_click)
            {
               m_click.visible = false;
            }
         }
      }
      
      public function shake(param1:DisplayObject, param2:int, param3:int, param4:Number) : void
      {
         var _loc5_:Tween = null;
         if(!param1)
         {
            return;
         }
         jugglerG.removeTweens(param1);
         _loc5_ = new Tween(param1,param4,"easeInOut");
         if(param1.x <= param2)
         {
            _loc5_.animate("x",param3);
         }
         else
         {
            _loc5_.animate("x",param2);
         }
         _loc5_.onComplete = shake;
         _loc5_.onCompleteArgs = [param1,param2,param3,param4];
         jugglerG.add(_loc5_);
      }
      
      public function removedFromStage(param1:Event) : void
      {
         if(m_arrowheadImg)
         {
            jugglerA.removeTweens(m_arrowheadImg);
            jugglerG.removeTweens(m_arrowheadImg);
         }
         if(m_clickImg)
         {
            jugglerA.removeTweens(m_clickImg);
            jugglerG.removeTweens(m_clickImg);
         }
      }
      
      public function addStory(param1:Array) : void
      {
         var _loc2_:Object = {};
         _loc2_.yy = GameMapConfig.SCREEN_HEIGHT;
         _loc2_.s = param1[1];
         _loc2_.i = param1[0];
         var _loc3_:Number = 1.2000000000000002;
         if(m_leafs && m_leafs.numChildren > 0)
         {
            _loc3_ = 0;
         }
         else
         {
            _loc3_ = 1.2000000000000002 * 1;
         }
         _loc3_ = 0;
         addMaskAndStory(_loc2_,true,false,_loc3_);
      }
      
      public function addArrowhead(param1:int, param2:int, param3:int = 0) : void
      {
         var _loc4_:* = undefined;
         var _loc5_:* = undefined;
         if(GlobalData.$currentGuide)
         {
            return;
         }
         _loc4_ = {};
         _loc4_.x = param1;
         _loc4_.y = param2;
         if(param3 != 0)
         {
            _loc5_ = {};
            _loc5_.y = param3;
            _loc4_ = Tools.coverObj(_loc4_,_loc5_);
         }
         _loc4_.w = 0;
         _loc4_.h = 0;
         _loc4_.t = 5;
         addMaskAndStory(_loc4_);
      }
      
      public function addMouseDemo(param1:* = null) : void
      {
         var _spr:Sprite;
         var _img:Image;
         var _clickImg:Image;
         var _lineImg:Image;
         var _x1:int;
         var _y1:int;
         var _x2:int;
         var _y2:int;
         var _dis:int;
         var _tween:Tween;
         var _time:Number;
         var _spaceTime:Number;
         var _onceTime:Number;
         var i:int;
         var _x0:int;
         var _y0:int;
         var _num:int;
         var _rotation:Number;
         var _obj:* = param1;
         if(!_obj)
         {
            return;
         }
         _x1 = int(_obj.mx1);
         _y1 = int(_obj.my1);
         _x2 = int(_obj.mx2);
         _y2 = int(_obj.my2);
         _spaceTime = 0.3;
         if(_x1 && _y1)
         {
            _dis = new Point(_x1 - _x2,_y1 - _y2).length;
            _time = _dis / 300;
            _onceTime = _time + _spaceTime * 2;
            _rotation = GameMapTools.getRadians(new Point(_x1,_y1),new Point(_x2,_y2));
            _num = Math.ceil(_dis / 50);
            i = 0;
            while(i <= _num)
            {
               _x0 = (_x1 * (_num + 0.5 - i) + _x2 * i) / (_num + 0.5);
               _y0 = (_y1 * (_num + 0.5 - i) + _y2 * i) / (_num + 0.5);
               _lineImg = DisplayTools.newImg("guideLine1",_x0,_y0);
               _lineImg.rotation = _rotation;
               _lineImg.alpha = 0.5;
               guideLayer.addChild(_lineImg);
               i = i + 1;
            }
            _lineImg = DisplayTools.newImg("guideLine0",_x2,_y2);
            _lineImg.rotation = _rotation;
            _lineImg.alpha = 0.5;
            guideLayer.addChild(_lineImg);
            if(_obj.mt > 0)
            {
               _img = DisplayTools.newImg("guideMouse",_x1,_y1);
               _clickImg = DisplayTools.newImg("guideClick",_x1,_y1);
               guideLayer.addChild(_clickImg);
               guideLayer.addChild(_img);
               i = 0;
               while(i < _obj.mt)
               {
                  _tween = new Tween(_img,_spaceTime,"easeInOut");
                  _tween.delay = i * _onceTime;
                  _tween.onStart = function():void
                  {
                     _img.x = _x1;
                     _img.y = _y1;
                     _img.alpha = 0.5;
                     _img.scaleX = _img.scaleY = 1.5;
                  };
                  _tween.fadeTo(1);
                  _tween.scaleTo(1);
                  jugglerG.add(_tween);
                  _tween = new Tween(_img,_time,"easeInOut");
                  _tween.delay = i * _onceTime + _spaceTime;
                  _tween.moveTo(_x2,_y2);
                  jugglerG.add(_tween);
                  _tween = new Tween(_img,_spaceTime,"easeInOut");
                  _tween.delay = i * _onceTime + _spaceTime + _time;
                  _tween.fadeTo(0);
                  jugglerG.add(_tween);
                  _tween = new Tween(_clickImg,_time,"easeInOut");
                  _tween.delay = i * _onceTime;
                  _tween.onStart = function():void
                  {
                     _clickImg.alpha = 1;
                     _clickImg.scaleX = _clickImg.scaleY = 0.5;
                  };
                  _tween.scaleTo(1);
                  _tween.fadeTo(0);
                  jugglerG.add(_tween);
                  i = i + 1;
               }
            }
         }
      }
      
      public function newLeaf() : Image
      {
         var _loc1_:Image = DisplayTools.newImg("UI_leaf");
         _loc1_.pivotX = 20;
         _loc1_.pivotY = 180;
         return _loc1_;
      }
      
      public function leafsShake() : void
      {
         var _loc4_:Image = null;
         var _loc7_:int = 0;
         var _loc2_:Tween = null;
         var _loc5_:Number = NaN;
         var _loc1_:int = 0;
         var _loc6_:Number = NaN;
         if(!m_leafs)
         {
            return;
         }
         var _loc3_:int = m_leafs.numChildren;
         _loc7_ = 0;
         while(_loc7_ < _loc3_)
         {
            _loc4_ = m_leafs.getChildAt(_loc7_) as Image;
            _loc5_ = _loc4_.rotation;
            _loc6_ = Math.random() * 1 * 0.2;
            _loc2_ = new Tween(_loc4_,1 * 0.2,"easeInBack");
            _loc2_.delay = _loc6_;
            _loc2_.animate("rotation",_loc5_ + Math.random() * 0.3 - 0.15);
            jugglerG.add(_loc2_);
            _loc2_ = new Tween(_loc4_,1 * 0.2,"easeOutBack");
            _loc2_.delay = _loc6_ + 0.2;
            _loc2_.animate("rotation",_loc5_);
            jugglerG.add(_loc2_);
            _loc7_++;
         }
      }
      
      public function leafsOut() : void
      {
         var _loc4_:Image = null;
         var _loc6_:int = 0;
         var _loc2_:Tween = null;
         var _loc5_:Number = NaN;
         var _loc1_:int = 0;
         if(!m_leafs)
         {
            return;
         }
         var _loc3_:int = m_leafs.numChildren;
         _loc6_ = 0;
         while(_loc6_ < _loc3_)
         {
            _loc4_ = m_leafs.getChildAt(_loc6_) as Image;
            if(_loc6_ % 2 == 0)
            {
               _loc5_ = 3.141592653589793 / 2;
               _loc1_ = 0 - _loc4_.width;
            }
            else
            {
               _loc5_ = -1.5707963267948966;
               _loc1_ = GameMapConfig.SCREEN_WIDTH + _loc4_.width;
            }
            _loc2_ = new Tween(_loc4_,1 * 0.6,"easeInOut");
            _loc2_.delay = _loc6_ * 0.3 * 1;
            _loc2_.animate("rotation",_loc5_);
            _loc2_.animate("x",_loc1_);
            jugglerG.add(_loc2_);
            m_leafs.addChildAt(_loc4_,0);
            _loc6_++;
         }
      }
      
      public function addLeafsIn(param1:int) : void
      {
         var _loc7_:int = 0;
         var _loc6_:Image = null;
         var _loc10_:int = 0;
         var _loc4_:Tween = null;
         var _loc8_:Number = NaN;
         var _loc3_:int = 0;
         var _loc2_:int = 0;
         var _loc9_:* = 0;
         if(m_leafs && m_leafs.numChildren > 0)
         {
            if(m_quad)
            {
               _loc7_ = getChildIndex(m_quad);
               guideLayer.addChildAt(m_leafs,_loc7_ + 1);
            }
            else
            {
               guideLayer.addChild(m_leafs);
            }
            leafsShake();
            return;
         }
         if(param1 <= 0)
         {
            return;
         }
         m_leafs = new Sprite();
         var _loc5_:Array = [16777215,10066329,3355443];
         _loc10_ = 0;
         while(_loc10_ < param1)
         {
            _loc6_ = newLeaf();
            _loc8_ = 0;
            _loc2_ = _loc10_ / 2;
            _loc9_ = uint(_loc5_[Math.min(_loc5_.length - 1,_loc2_)]);
            _loc6_.scaleY = 3 - _loc2_ * 0.5;
            _loc6_.color = _loc9_;
            _loc6_.y = GameMapConfig.SCREEN_HEIGHT * ((param1 + 1 - _loc2_) / (param1 + 1) + Math.random() * 0.2);
            if(_loc10_ % 2 == 0)
            {
               _loc6_.scaleX = _loc6_.scaleY;
               _loc6_.x = -_loc6_.width;
               _loc6_.rotation = 3.141592653589793 / 2;
               _loc3_ = 0;
            }
            else
            {
               _loc6_.scaleX = -_loc6_.scaleY;
               _loc6_.x = GameMapConfig.SCREEN_WIDTH + _loc6_.width;
               _loc6_.rotation = -1.5707963267948966;
               _loc3_ = GameMapConfig.SCREEN_WIDTH;
            }
            _loc4_ = new Tween(_loc6_,1,"easeOutBack");
            _loc4_.delay = _loc10_ * 0.2 * 1;
            _loc4_.animate("rotation",_loc8_);
            _loc4_.animate("x",_loc3_);
            jugglerG.add(_loc4_);
            m_leafs.addChildAt(_loc6_,0);
            _loc10_++;
         }
         guideLayer.addChild(m_leafs);
      }
      
      public function addCartoon(param1:Object, param2:String, param3:int = 2147483647) : void
      {
         removeEventListener("touch",this.onTouch);
         removeEventListener("touch",this.onTransmission);
         var _loc4_:Game = GlobalData.$mGameClassObject;
         _loc4_.addChild(this);
         if(!m_quad)
         {
            m_quad = GuideTools.newAllMask(0);
         }
         if(!guideLayer.contains(m_quad))
         {
            guideLayer.addChildAt(m_quad,0);
         }
         var _loc5_:LayoutUICartoon = LayoutUICartoon.getOnlyExample();
         guideLayer.addChild(_loc5_);
         _loc5_.show(param1,param2,param3);
         lastTime = new Date().getTime();
         addEventListener("touch",this.onTouch);
         addNextSkip();
      }
      
      public function addMaskAndStory(param1:Object = null, param2:Boolean = false, param3:Boolean = false, param4:Number = 0) : void
      {
         var _loc9_:Sprite = null;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc8_:* = null;
         if(m_infoTf)
         {
            m_infoTf.dispose();
         }
         if(m_infoPop)
         {
            m_infoPop.dispose();
         }
         if(m_mask)
         {
            m_mask.texture.dispose();
            m_mask.dispose();
         }
         if(m_quad)
         {
            m_quad.dispose();
         }
         removeEventListener("touch",this.onTouch);
         removeEventListener("touch",this.onTransmission);
         guideLayer.removeChildren(0,-1,false);
         if(m_transmission)
         {
            guideLayer.addChild(m_transmission);
         }
         var _loc5_:Game = GlobalData.$mGameClassObject;
         _loc5_.addChild(this);
         var _loc10_:Number = param3 ? 0 : 0.3;
         if(!param1)
         {
            m_quad = GuideTools.newAllMask(_loc10_);
            guideLayer.addChildAt(m_quad,0);
            return;
         }
         if(param1.t == 0)
         {
            m_quad = GuideTools.newAllMask(_loc10_);
            guideLayer.addChildAt(m_quad,0);
         }
         else if(param1.t == 6)
         {
            m_quad = GuideTools.newAllMask(_loc10_);
            guideLayer.addChildAt(m_quad,0);
            transmission1();
         }
         else if(param1.t == 7)
         {
            m_quad = GuideTools.newAllMask(_loc10_);
            guideLayer.addChildAt(m_quad,0);
            removeTransmission();
         }
         else
         {
            if(param1.t == 5)
            {
               _loc6_ = param1.x + param1.w / 2;
               _loc7_ = param1.y + param1.h / 2;
               addShake(_loc6_,_loc7_);
               return;
            }
            if(param1.t == 1 || param1.t == 3)
            {
               m_mask = GuideTools.newCircleMask(param1.x,param1.y,param1.r,_loc10_);
               if(param1.t == 1)
               {
                  m_mask.touchable = false;
                  _loc9_ = new Sprite();
                  m_quad = Tools.newQuad(param1.x - param1.r,GameMapConfig.SCREEN_HEIGHT);
                  _loc9_.addChild(m_quad);
                  m_quad = Tools.newQuad(GameMapConfig.SCREEN_WIDTH - (param1.x + param1.r),GameMapConfig.SCREEN_HEIGHT,param1.x + param1.r);
                  _loc9_.addChild(m_quad);
                  m_quad = Tools.newQuad(param1.r * 2,param1.y - param1.r,param1.x - param1.r);
                  _loc9_.addChild(m_quad);
                  m_quad = Tools.newQuad(param1.r * 2,GameMapConfig.SCREEN_HEIGHT - (param1.y + param1.r),param1.x - param1.r,param1.y + param1.r);
                  _loc9_.addChild(m_quad);
                  _loc9_.alpha = 0;
                  guideLayer.addChild(_loc9_);
                  _loc6_ = int(param1.x);
                  _loc7_ = int(param1.y);
                  addShake(_loc6_,_loc7_);
               }
               guideLayer.addChildAt(m_mask,0);
            }
            else if(param1.t == 2 || param1.t == 4)
            {
               m_mask = GuideTools.newRectMask(param1.x,param1.y,param1.w,param1.h,param1.r,_loc10_);
               if(param1.t == 2)
               {
                  m_mask.touchable = false;
                  _loc9_ = new Sprite();
                  m_quad = Tools.newQuad(param1.x,GameMapConfig.SCREEN_HEIGHT);
                  _loc9_.addChild(m_quad);
                  m_quad = Tools.newQuad(GameMapConfig.SCREEN_WIDTH - (param1.x + param1.w),GameMapConfig.SCREEN_HEIGHT,param1.x + param1.w);
                  _loc9_.addChild(m_quad);
                  m_quad = Tools.newQuad(param1.w,param1.y,param1.x);
                  _loc9_.addChild(m_quad);
                  m_quad = Tools.newQuad(param1.w,GameMapConfig.SCREEN_HEIGHT - (param1.y + param1.h),param1.x,param1.y + param1.h);
                  _loc9_.addChild(m_quad);
                  _loc9_.alpha = 0;
                  guideLayer.addChild(_loc9_);
                  if(!param1.mx1)
                  {
                     _loc6_ = param1.x + param1.w / 2;
                     _loc7_ = param1.y + param1.h / 2;
                     addShake(_loc6_,_loc7_);
                     jugglerG.add(_loc8_);
                  }
               }
               guideLayer.addChildAt(m_mask,0);
            }
            else
            {
               m_quad = GuideTools.newAllMask(_loc10_);
               m_quad.alpha = 0;
               guideLayer.addChildAt(m_quad,0);
            }
         }
         addMouseDemo(param1);
         if(param4 <= 0)
         {
            addMaskAndStory2(param1,param2,param3);
         }
         else
         {
            jugglerG.delayCall(addMaskAndStory2,param4,param1,param2,param3);
         }
      }
      
      public function addMaskAndStory2(param1:Object = null, param2:Boolean = false, param3:Boolean = false) : void
      {
         var _loc5_:* = null;
         var _loc10_:int = 0;
         var _loc11_:int = 0;
         var _loc12_:Tween = null;
         var _loc7_:String = null;
         var _loc13_:Boolean = false;
         var _loc16_:String = null;
         var _loc4_:int = 0;
         var _loc6_:Image = null;
         var _loc14_:int = 0;
         var _loc8_:AvatarData = null;
         var _loc9_:Game = GlobalData.$mGameClassObject;
         _loc9_.addChild(this);
         var _loc15_:Number = param3 ? 0 : 0.3;
         if(param1.i)
         {
            if(param1.i.indexOf("-") == 0)
            {
               _loc13_ = true;
            }
            _loc7_ = GameMapTools.getAvatarIDByRes(param1.i);
         }
         if(param1.s)
         {
            _loc16_ = param1.s;
            _loc4_ = 40;
            if(int(_loc16_) > 0)
            {
               _loc16_ = GlobalLanguageStr.getLanguageStr(param1.s);
            }
            if(!_loc7_ && !param2)
            {
               _loc16_ = HtmlTextFormat.multiColorText(_loc16_,HtmlTextFormat.COLOR_GUIDE,FONT_SIZE,-1,GlobalConfig.FONT_1);
            }
            else
            {
               _loc16_ = HtmlTextFormat.multiColorText(_loc16_,HtmlTextFormat.COLOR_GUIDE2,FONT_SIZE,-1,GlobalConfig.FONT_1);
            }
            _loc10_ = GameMapConfig.SCREEN_WIDTH / 2;
            m_infoPop = new LOL_TextPop(GameMapConfig.SCREEN_WIDTH - 22,160,"guide");
            GlobalFunction.setPivot(m_infoPop);
            m_infoPop.touchable = false;
            m_infoPop.x = _loc10_;
            if(param1.yy)
            {
               _loc11_ = Math.max(m_infoPop.height / 2,Math.min(GameMapConfig.SCREEN_HEIGHT - m_infoPop.height / 2,param1.yy));
            }
            else
            {
               _loc11_ = GameMapConfig.SCREEN_HEIGHT - m_infoPop.height / 2;
            }
            m_infoPop.y = _loc11_ - _loc4_ + 18;
            if(_loc7_)
            {
               _loc6_ = GameMapTools.newAvatarImgById(_loc7_,_loc10_,_loc11_ - m_infoPop.height * 0.8);
               if(_loc13_)
               {
                  _loc14_ = _loc6_.x - (m_infoPop.width / 2 - _loc6_.width * 0.2 - 50);
                  _loc6_.x = _loc14_ - _loc6_.width;
               }
               else
               {
                  _loc14_ = _loc6_.x + (m_infoPop.width / 2 - _loc6_.width * 0.2 - 50);
                  _loc6_.x = _loc14_ + _loc6_.width;
               }
               _loc6_.y = Math.max(_loc6_.y,_loc11_ - m_infoPop.height / 3 - _loc6_.height / 2) + _loc4_;
               _loc12_ = new Tween(_loc6_,0.4,"easeOut");
               _loc12_.animate("y",_loc6_.y - _loc4_);
               _loc12_.animate("x",_loc14_);
               jugglerG.add(_loc12_);
               guideLayer.addChild(_loc6_);
               if(GameMap.currentMap)
               {
                  GameMap.currentMap.showSpeak(_loc7_,_loc13_);
               }
            }
            guideLayer.addChild(m_infoPop);
            m_infoPop.alpha = 0.2;
            _loc12_ = new Tween(m_infoPop,0.2,"easeOut");
            _loc12_.animate("y",m_infoPop.y + _loc4_);
            _loc12_.fadeTo(1);
            jugglerG.add(_loc12_);
            if(_loc6_)
            {
               if(_loc13_)
               {
                  _loc6_.scaleX = -_loc6_.scaleX;
                  m_infoPop.scaleX = -m_infoPop.scaleX;
               }
               _loc8_ = AvatarManager.getOnlyExample().getData(_loc7_);
            }
            m_infoTf = new HtmlTextField(m_infoPop.width * 0.9,m_infoPop.height * 0.8,_loc16_,true,GlobalConfig.FONT_0,FONT_SIZE);
            m_infoTf.touchable = false;
            m_infoTf.pivotX = m_infoTf.width / 2;
            m_infoTf.pivotY = m_infoTf.height / 2;
            m_infoTf.hAlign = "left";
            m_infoTf.vAlign = "center";
            m_infoTf.x = _loc10_;
            m_infoTf.y = _loc11_;
            guideLayer.addChild(m_infoTf);
            m_infoTf.alpha = 0;
            if(!_loc7_ && !param2)
            {
               m_infoTf.hAlign = "center";
               m_infoPop.visible = false;
               _loc12_ = new Tween(m_infoTf,1,"easeInOut");
               _loc12_.delay = 3;
               _loc12_.fadeTo(0);
               _loc12_.onComplete = nextStep;
               jugglerG.add(_loc12_);
               _loc12_ = new Tween(m_infoTf,1,"easeInOut");
               if(param1.s == 44799)
               {
                  _loc12_.delay = 1.2;
               }
            }
            else
            {
               _loc12_ = new Tween(m_infoTf,0.3,"easeOut");
            }
            _loc12_.fadeTo(1);
            jugglerG.add(_loc12_);
         }
         if(param1.t != 6)
         {
            if(param1.t != 1 && param1.t != 2)
            {
               lastTime = new Date().getTime();
               addEventListener("touch",this.onTouch);
               if(param1.s == 44799)
               {
                  popEZ(-0.2,0.5,1.2,0.5,-1,1,0);
                  popEZ(1.2,0.2,-0.2,0.7,-1,1.1,0.3);
                  popEZ(-0.2,0.2,0.5,1.2,-1,1.7,0.35);
                  popEZ(0.8,-0.2,-0.2,1.2,-1,1.3,0.5);
                  popEZ(0.2,-0.2,1.2,0.5,-1,1.5,0.7);
                  popEZ(0.6,1.2,-0.2,0.3,-1,0.9,1);
               }
               if(!_loc7_)
               {
                  if(m_quad)
                  {
                     m_quad.visible = false;
                  }
               }
            }
         }
         addNextSkip();
      }
      
      public function addNextSkip() : void
      {
         var _loc1_:String = null;
         if(!MainConfig.$isTest)
         {
            if(!GuideMaster.getOnlyExample().currentGuide)
            {
               return;
            }
            _loc1_ = GuideMaster.getOnlyExample().currentGuide.group;
            if(!(_loc1_ == "B" || _loc1_ == "D"))
            {
               return;
            }
         }
         if(!m_skip)
         {
            m_skip = new LOL_Button(GlobalLanguageStr.getLanguageStr(31005),"UI_btn_enterGame_0_0000",true,false);
            m_skip.style(GlobalConfig.FONT_0,25,1118481);
            m_skip.width = 110;
            m_skip.height = 50;
            m_skip.alpha = 0.5;
            m_skip.x = GameMapConfig.SCREEN_WIDTH - m_skip.width;
            m_skip.addEventListener("triggered",onSkip);
         }
         guideLayer.addChild(m_skip);
         if(!MainConfig.$isTest)
         {
            return;
         }
         if(GameMap.currentMap)
         {
            return;
         }
         if(!m_next)
         {
            m_next = GlobalFunction.createButton_5("NEXT");
            m_next.width = 110;
            m_next.height = 50;
            m_next.x = GameMapConfig.SCREEN_WIDTH - 220;
            m_next.addEventListener("triggered",onNext);
         }
         if(!m_replay)
         {
            m_replay = GlobalFunction.createButton_5("重来");
            m_replay.width = 110;
            m_replay.height = 50;
            m_replay.x = GameMapConfig.SCREEN_WIDTH - 330;
            m_replay.addEventListener("triggered",onReplay);
         }
         if(!m_test)
         {
            m_test = GlobalFunction.createButton_5("TEST");
            m_test.width = 110;
            m_test.height = 50;
            m_test.addEventListener("triggered",onTest);
         }
         if(!m_storeClear)
         {
            m_storeClear = GlobalFunction.createButton_5("CLEAR");
            m_storeClear.width = 110;
            m_storeClear.height = 50;
            m_storeClear.x = 110;
            m_storeClear.addEventListener("triggered",onStoreClear);
         }
         guideLayer.addChild(m_next);
         guideLayer.addChild(m_replay);
         guideLayer.addChild(m_test);
         guideLayer.addChild(m_storeClear);
      }
      
      protected function onStoreClear(param1:Event) : void
      {
         LocalStore.clearAll();
         m_storeClear.enabled = false;
      }
      
      protected function onTest(param1:Event) : void
      {
         var _loc2_:Game = GlobalData.$mGameClassObject;
         GuideMaster.getOnlyExample().skipGuide();
         _loc2_.removeChildren(1,-1);
         MainConfig.$isFightTest = true;
         (AvatarManager.getOnlyExample() as AvatarManager).init();
         (SkillSetManager.getOnlyExample() as SkillSetManager).init();
         (EffectManager.getOnlyExample() as EffectManager).init();
         (GameMapManager.getOnlyExample() as GameMapManager).init();
         _loc2_.addChild(GameMapLayer.gl.mapStage);
         new GameMap("M_000_0");
         _loc2_.addChild(new TestButton() as Sprite);
      }
      
      protected function onNext(param1:Event) : void
      {
         GuideMaster.getOnlyExample().nextGuide();
      }
      
      protected function onReplay(param1:Event) : void
      {
         clear();
         LayoutUICartoon.getOnlyExample().clear();
         GuideMaster.getOnlyExample().startGuide("B");
      }
      
      protected function onSkip(param1:Event) : void
      {
         var _loc2_:String = null;
         if(GlobalData.$currentGuide == "B" || GlobalData.$currentGuide == "D")
         {
            _loc2_ = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(31004),null);
            GlobalFunction.popAlert("",_loc2_,{
               "ok":goSkip,
               "no":GlobalFunction.functionNull
            });
         }
         else
         {
            goSkip();
         }
      }
      
      protected function goSkip() : void
      {
         GuideMaster.getOnlyExample().skipGuide();
      }
      
      protected function removeTransmission() : void
      {
         var _tween:Tween;
         if(m_transmission)
         {
            _tween = new Tween(m_transmission,0.5 * 0.5,"easeInOut");
            _tween.fadeTo(0);
            _tween.onComplete = function():void
            {
               if(m_transmission)
               {
                  m_transmission.removeFromParent(true);
               }
               nextStep();
            };
            jugglerG.add(_tween);
         }
      }
      
      protected function transmission1() : void
      {
         var _loc3_:Image = null;
         var _loc1_:Image = null;
         var _loc5_:* = null;
         var _loc4_:Tween = null;
         var _loc2_:Image = null;
         var _loc6_:Number = NaN;
         if(!m_transmission)
         {
            m_transmission = new Sprite();
         }
         guideLayer.addChild(m_transmission);
         _loc4_ = new Tween(m_transmission,0.5,"easeInOut");
         _loc4_.delay = 0.5 * 7;
         _loc4_.onComplete = nextStep;
         jugglerG.add(_loc4_);
         _loc3_ = GameMapTools.newAvatarImgById("A_1060_5",GameMapConfig.SCREEN_WIDTH / 2,GameMapConfig.SCREEN_HEIGHT / 4);
         _loc2_ = StarlingTools.cloneImage(_loc3_);
         _loc3_.x = -_loc3_.width / 2;
         m_transmission.addChild(_loc3_);
         _loc4_ = new Tween(_loc3_,0.5 * 1,"easeOut");
         _loc4_.animate("x",GameMapConfig.SCREEN_WIDTH / 2);
         jugglerG.add(_loc4_);
         _loc2_.alpha = 0;
         _loc2_.filter = new ColorMatrixFilter(Vector.<Number>([1,0,0,0,255,0,1,0,0,255,0,0,0,0,0,0,0,0,1,0]));
         m_transmission.addChild(_loc2_);
         _loc6_ = 0.5 * 2;
         _loc4_ = new Tween(_loc2_,0.5 / 2,"easeInOut");
         _loc4_.delay = _loc6_;
         _loc4_.fadeTo(1);
         jugglerG.add(_loc4_);
         _loc4_ = new Tween(_loc2_,0.5 / 2,"easeInOut");
         _loc4_.delay = _loc6_ + 0.5 / 2;
         _loc4_.fadeTo(0);
         jugglerG.add(_loc4_);
         _loc6_ += 0.5 * 2;
         _loc4_ = new Tween(_loc2_,0.5 / 2,"easeInOut");
         _loc4_.delay = _loc6_;
         _loc4_.fadeTo(1);
         jugglerG.add(_loc4_);
         _loc4_ = new Tween(_loc2_,0.5 / 2,"easeInOut");
         _loc4_.delay = _loc6_ + 0.5 / 2;
         _loc4_.fadeTo(0);
         _loc4_.onComplete = removeSelf;
         _loc4_.onCompleteArgs = [_loc2_];
         jugglerG.add(_loc4_);
         _loc6_ += 0.5;
         _loc4_ = new Tween(_loc3_,0.5,"easeInOut");
         _loc4_.delay = _loc6_;
         _loc4_.fadeTo(0);
         _loc4_.onComplete = removeSelf;
         _loc4_.onCompleteArgs = [_loc3_];
         jugglerG.add(_loc4_);
         _loc1_ = GameMapTools.newAvatarImgById("A_1060_6",GameMapConfig.SCREEN_WIDTH / 2,GameMapConfig.SCREEN_HEIGHT / 4);
         _loc2_ = StarlingTools.cloneImage(_loc1_);
         _loc1_.alpha = 0;
         m_transmission.addChild(_loc1_);
         _loc4_ = new Tween(_loc1_,0.5,"easeInOut");
         _loc4_.delay = _loc6_;
         _loc4_.fadeTo(1);
         jugglerG.add(_loc4_);
         _loc2_.alpha = 0;
         _loc2_.filter = new ColorMatrixFilter(Vector.<Number>([1,0,0,0,255,0,1,0,0,255,0,0,1,0,255,0,0,0,1,0]));
         m_transmission.addChild(_loc2_);
         _loc6_ = 0.5 * 4;
         _loc4_ = new Tween(_loc2_,0.5 / 2,"easeInOut");
         _loc4_.delay = _loc6_;
         _loc4_.fadeTo(1);
         jugglerG.add(_loc4_);
         _loc4_ = new Tween(_loc2_,0.5 / 2,"easeInOut");
         _loc4_.delay = _loc6_ + 0.5 / 2;
         _loc4_.fadeTo(0);
         jugglerG.add(_loc4_);
         _loc6_ += 0.5;
         _loc4_ = new Tween(_loc2_,0.5 / 2,"easeInOut");
         _loc4_.delay = _loc6_;
         _loc4_.fadeTo(1);
         jugglerG.add(_loc4_);
         _loc4_ = new Tween(_loc2_,0.5 / 2,"easeInOut");
         _loc4_.delay = _loc6_ + 0.5 / 2;
         _loc4_.fadeTo(0);
         _loc4_.onComplete = removeSelf;
         _loc4_.onCompleteArgs = [_loc2_];
         jugglerG.add(_loc4_);
         _loc6_ = 0.5 * 2.5;
         jugglerG.delayCall(SoundManager.getOnlyExample().playSound,_loc6_,"E_9017");
         jugglerG.delayCall(SoundManager.getOnlyExample().playSound,_loc6_ + 0.5 * 1,"E_9016");
         jugglerG.delayCall(SoundManager.getOnlyExample().playSound,_loc6_ + 0.5 * 2,"getAvatar");
         jugglerG.delayCall(SoundManager.getOnlyExample().playAvatar,_loc6_ + 0.5 * 5,"A_1060");
         jugglerG.delayCall(transmission2,0.5 * 0.5);
      }
      
      protected function transmission2() : void
      {
         var _loc5_:int = 0;
         var _loc2_:Sprite = null;
         var _loc10_:Tween = null;
         var _loc7_:Image = null;
         var _loc11_:Number = NaN;
         var _loc16_:int = 0;
         var _loc6_:int = 0;
         var _loc14_:int = 0;
         var _loc13_:Number = NaN;
         var _loc12_:* = null;
         var _loc17_:Number = NaN;
         var _loc1_:int = 3;
         var _loc3_:Array = ["A_1001_5","A_1002_5","A_1003_5"];
         var _loc4_:Array = ["A_1001_2","A_1002_2","A_1003_2"];
         var _loc15_:int = 20;
         var _loc9_:int = GameMapConfig.SCREEN_WIDTH / 2 - 7;
         var _loc8_:int = GameMapConfig.SCREEN_HEIGHT / 4 - 85;
         var _loc18_:int = GameMapConfig.SCREEN_HEIGHT * 1 / 2;
         _loc5_ = 0;
         while(_loc5_ < _loc1_)
         {
            _loc2_ = new Avatar(_loc3_[_loc5_]).getAvatarRes();
            _loc2_.pivotX = _loc2_.width / 2;
            _loc2_.pivotY = _loc2_.height / 2;
            _loc7_ = StarlingTools.cloneImage(_loc2_);
            m_transmission.addChild(_loc2_);
            _loc16_ = _loc9_ + (_loc5_ + 1) / (_loc1_ + 1) * _loc15_ - _loc15_ * 0.5;
            _loc6_ = _loc8_ + (_loc5_ + 1 == (_loc1_ + 1) / 2 ? _loc15_ / 4 : 0);
            _loc14_ = (_loc5_ + 1) / (_loc1_ + 1) * GameMapConfig.SCREEN_WIDTH;
            _loc2_.x = GameMapConfig.SCREEN_WIDTH + _loc14_;
            _loc2_.y = _loc18_;
            _loc7_.x = _loc14_;
            _loc7_.y = _loc18_;
            _loc7_.alpha = 0;
            _loc7_.filter = new ColorMatrixFilter(Vector.<Number>([1,0,0,0,255,0,1,0,0,255,0,0,1,0,255,0,0,0,1,0]));
            m_transmission.addChild(_loc7_);
            _loc10_ = new Tween(_loc2_,0.5 * 1,"easeOut");
            _loc10_.animate("x",_loc14_);
            jugglerG.add(_loc10_);
            _loc17_ = 0.5 * (2.5 + _loc5_ / 10);
            _loc10_ = new Tween(_loc2_,0.5 / 2,"easeOutBack");
            _loc10_.delay = _loc17_;
            _loc10_.scaleTo(1.3);
            jugglerG.add(_loc10_);
            _loc10_ = new Tween(_loc2_,0.5 / 2,"easeInOut");
            _loc10_.delay = _loc17_ + 0.5;
            _loc10_.scaleTo(1);
            jugglerG.add(_loc10_);
            _loc10_ = new Tween(_loc7_,0.5 / 2,"easeOutBack");
            _loc10_.delay = _loc17_;
            _loc10_.fadeTo(0.5);
            _loc10_.scaleTo(1.5);
            jugglerG.add(_loc10_);
            _loc10_ = new Tween(_loc7_,0.5 / 2,"easeInOut");
            _loc10_.delay = _loc17_ + 0.5;
            _loc10_.fadeTo(1);
            _loc10_.scaleTo(1.2);
            jugglerG.add(_loc10_);
            _loc10_ = new Tween(_loc7_,0.5,"easeInOut");
            _loc10_.delay = _loc17_ + 0.5;
            _loc10_.fadeTo(0);
            _loc10_.onComplete = removeSelf;
            _loc10_.onCompleteArgs = [_loc7_];
            jugglerG.add(_loc10_);
            _loc17_ += 0.5;
            jugglerG.delayCall(removeSelf,_loc17_,_loc2_);
            _loc2_ = new Avatar(_loc4_[_loc5_]).getAvatarRes();
            _loc2_.pivotX = _loc2_.width / 2;
            _loc2_.pivotY = _loc2_.height / 2;
            _loc2_.x = _loc14_;
            _loc2_.y = _loc18_;
            jugglerG.delayCall(m_transmission.addChildAt,_loc17_,_loc2_,0);
            _loc17_ += 0.5;
            _loc10_ = new Tween(_loc2_,0.5 / 2,"easeOutBack");
            _loc10_.delay = _loc17_;
            _loc10_.scaleTo(1.2);
            jugglerG.add(_loc10_);
            _loc10_ = new Tween(_loc2_,0.5 / 2,"easeInOut");
            _loc10_.delay = _loc17_ + 0.5 / 2;
            _loc10_.scaleTo(1);
            jugglerG.add(_loc10_);
            _loc17_ = 0.5 * (2 + _loc5_ / 10);
            jugglerG.delayCall(DisplayTools.addBullet,_loc17_,{
               "x1":_loc16_,
               "y1":_loc6_,
               "x2":_loc14_,
               "y2":_loc18_,
               "isg":1,
               "par":guideLayer,
               "p":{
                  "id":"e201",
                  "w":1,
                  "i":0,
                  "sc":2,
                  "m":"add"
               }
            });
            _loc17_ += 0.5;
            jugglerG.delayCall(DisplayTools.addBullet,_loc17_,{
               "x1":_loc14_,
               "y1":_loc18_,
               "x2":_loc16_,
               "y2":_loc6_,
               "isg":1,
               "par":guideLayer,
               "sc":2,
               "p":{
                  "id":"e204",
                  "w":1,
                  "i":0,
                  "sc":2,
                  "m":"add"
               }
            });
            _loc17_ += 0.5;
            jugglerG.delayCall(DisplayTools.addBullet,_loc17_,{
               "x1":_loc16_,
               "y1":_loc6_,
               "x2":_loc14_,
               "y2":_loc18_,
               "isg":1,
               "par":guideLayer,
               "sc":2,
               "p":{
                  "id":"e201",
                  "w":1,
                  "i":0,
                  "sc":2,
                  "m":"add"
               }
            });
            _loc5_++;
         }
      }
      
      public function removeSelf(param1:*) : void
      {
         var _loc4_:DisplayObject = null;
         var _loc3_:Event = param1 as Event;
         if(_loc3_)
         {
            _loc4_ = _loc3_.currentTarget as DisplayObject;
         }
         else
         {
            _loc4_ = param1 as DisplayObject;
         }
         if(!_loc4_)
         {
            return;
         }
         var _loc2_:MovieClip = _loc4_ as MovieClip;
         if(_loc2_)
         {
            _loc2_.pause();
            jugglerA.removeTweens(_loc2_);
            jugglerG.removeTweens(_loc2_);
         }
         _loc4_.removeFromParent(true);
      }
      
      public function onTransmission(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(this,"ended");
         if(_loc2_ && _loc2_.globalY > 0)
         {
            if(m_transmission)
            {
               jugglerG.purge();
               m_transmission.removeChildren(0,-1,true);
            }
            addMaskAndStory({"t":6});
         }
      }
      
      public function onTouch(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(this,"ended");
         if(_loc2_ && _loc2_.globalY > 0)
         {
            if(Math.abs(lastTime - new Date().getTime()) > 600)
            {
               lastTime = new Date().getTime();
               if(LayoutUICartoon.getOnlyExample().stage)
               {
                  LayoutUICartoon.getOnlyExample().nextStep();
               }
               else
               {
                  nextStep();
               }
            }
         }
      }
      
      public function nextStep() : void
      {
         if(m_transmission)
         {
            jugglerG.removeTweens(m_transmission);
         }
         if(m_infoPop)
         {
            jugglerG.removeTweens(m_infoPop);
         }
         GuideMaster.getOnlyExample().nextGuideStep();
      }
      
      public function show() : Boolean
      {
         var _loc1_:Game = GlobalData.$mGameClassObject;
         if(_loc1_)
         {
            _loc1_.addChild(this);
            return true;
         }
         return false;
      }
      
      public function popEffect(param1:*) : void
      {
         var _loc2_:DisplayObject = null;
         if(!show())
         {
            return;
         }
         param1.par = animationLayer;
         _loc2_ = DisplayTools.addEffectOne(param1);
      }
      
      public function popStars(param1:int, param2:int, param3:Number = 1, param4:Number = 0.5, param5:Number = 0, param6:Number = 1, param7:Boolean = true) : Sprite
      {
         var _loc15_:Tween = null;
         var _loc16_:Image = null;
         var _loc20_:int = 0;
         var _loc14_:int = 0;
         var _loc19_:int = 0;
         var _loc21_:int = 0;
         var _loc13_:int = 0;
         var _loc10_:int = 0;
         var _loc12_:Number = NaN;
         if(!show())
         {
            return null;
         }
         var _loc9_:Sprite = new Sprite();
         var _loc11_:int = param1 + param2;
         var _loc18_:Number = 0.2 / param6;
         var _loc8_:Number = param5;
         var _loc17_:int = 88 * param3;
         _loc9_.x = GameMapConfig.SCREEN_WIDTH / 2;
         if(param4 < 1)
         {
            _loc9_.y = param4 * GameMapConfig.SCREEN_HEIGHT;
         }
         else
         {
            _loc9_.y = param4;
         }
         _loc13_ = 0;
         while(_loc13_ < _loc11_)
         {
            _loc20_ = (-_loc17_ - GameMapConfig.SCREEN_WIDTH) / 2;
            _loc19_ = (_loc11_ - 1 - _loc13_ - (_loc11_ - 1) / 2) * _loc17_;
            _loc14_ = 0;
            if(param7)
            {
               _loc16_ = DisplayTools.newImg("UI_icon_avatarStar_0_0001",_loc19_,_loc14_);
               _loc16_.scaleX = _loc16_.scaleY = param3;
               _loc16_.alpha = 0;
               _loc9_.addChildAt(_loc16_,0);
               _loc15_ = new Tween(_loc16_,_loc18_,"easeOut");
               _loc15_.delay = param5 + (_loc11_ - _loc13_) * _loc18_ * 0.1;
               _loc15_.fadeTo(1);
               jugglerA.add(_loc15_);
            }
            if(_loc13_ >= param2)
            {
               _loc16_ = DisplayTools.newImg("UI_icon_avatarStar_0_0000",_loc20_,_loc14_);
               _loc16_.scaleX = _loc16_.scaleY = param6 > 1 ? param3 : 3 * param3;
               _loc16_.alpha = 0;
               _loc9_.addChild(_loc16_);
               if(param6 <= 1)
               {
                  if(_loc13_ >= param2)
                  {
                     _loc12_ = (_loc13_ - param2) * 0.2 + 0.3;
                     jugglerA.delayCall(SoundManager.getOnlyExample().playSound,_loc8_,"skill2",_loc12_);
                  }
                  _loc15_ = new Tween(_loc16_,_loc18_,"easeInOut");
                  _loc15_.delay = _loc8_;
                  _loc15_.animate("rotation",3.141592653589793 * 2);
                  _loc15_.scaleTo(1 * param3);
                  _loc15_.fadeTo(1);
                  jugglerA.add(_loc15_);
                  _loc10_ = (_loc19_ - _loc20_) / _loc17_;
                  _loc15_ = new Tween(_loc16_,_loc10_ * _loc18_ * 1,"easeOutBack");
                  _loc15_.delay = _loc8_ + _loc18_ * (_loc13_ / 10 + 1);
                  _loc15_.animate("x",_loc19_);
                  _loc15_.animate("rotation",(_loc10_ + 1) * 3.141592653589793 * 2);
                  jugglerA.add(_loc15_);
                  _loc8_ += _loc18_;
               }
               else
               {
                  _loc15_ = new Tween(_loc16_,_loc18_,"easeOut");
                  _loc15_.delay = param5 + (_loc11_ - _loc13_) * _loc18_ * 0.1;
                  _loc15_.fadeTo(1);
                  jugglerA.add(_loc15_);
                  _loc16_.x = _loc19_;
               }
               _loc15_ = new Tween(_loc16_,_loc18_,"easeOut");
               _loc15_.delay = param6 <= 1 ? param5 + _loc18_ * ((_loc11_ - _loc13_) * 0.2 + param1 + 1) : param5 + _loc18_ * ((_loc11_ - _loc13_) * 0.2);
               _loc15_.fadeTo(1);
               _loc15_.scaleTo(1.3 * param3);
               jugglerA.add(_loc15_);
               _loc15_ = new Tween(_loc16_,_loc18_,"easeInBack");
               _loc15_.delay = param6 <= 1 ? param5 + _loc18_ * ((_loc11_ - _loc13_) * 0.2 + param1 + 2) : param5 + _loc18_ * ((_loc11_ - _loc13_) * 0.2 + 1);
               _loc15_.scaleTo(1 * param3);
               jugglerA.add(_loc15_);
            }
            _loc13_++;
         }
         if(param6 <= 1)
         {
            jugglerA.delayCall(SoundManager.getOnlyExample().playSound,param5 + _loc18_ * (param1 * 0.2 + param1 + 1),"E_9022",_loc12_);
         }
         animationLayer.addChild(_loc9_);
         return _loc9_;
      }
      
      public function popEZ(param1:Number, param2:Number, param3:Number, param4:Number, param5:Number = -1, param6:Number = 1, param7:Number = 0) : void
      {
         var _loc9_:Tween = null;
         var _loc11_:Number = NaN;
         if(!show())
         {
            return;
         }
         var _loc12_:* = DisplayTools.getAttrs("OPENING_ANIMATION");
         _loc12_.isg = 1;
         _loc12_.sc = param6 + 0.3;
         var _loc8_:DisplayObject = DisplayTools.newDisplayObject(_loc12_);
         if(Math.abs(param1) < 2)
         {
            param1 = GameMapConfig.SCREEN_WIDTH * param1;
         }
         if(Math.abs(param2) < 2)
         {
            param2 = GameMapConfig.SCREEN_HEIGHT * param2;
         }
         if(Math.abs(param3) < 2)
         {
            param3 = GameMapConfig.SCREEN_WIDTH * param3;
         }
         if(Math.abs(param4) < 2)
         {
            param4 = GameMapConfig.SCREEN_HEIGHT * param4;
         }
         _loc8_.x = param1;
         _loc8_.y = param2;
         var _loc10_:int = GameMapTools.getDistance(new Point(param1,param2),new Point(param3,param4));
         _loc11_ = _loc10_ / 2000 / param6;
         if(param5 < 0)
         {
            param5 = GameMapTools.getRadians(new Point(param1,param2),new Point(param3,param4));
         }
         _loc8_.rotation = param5;
         jugglerA.delayCall(animationLayer.addChild,param7,_loc8_);
         jugglerA.delayCall(SoundManager.getOnlyExample().playSound,param7 + 0.3,"E_8007",param6 / 2);
         _loc9_ = new Tween(_loc8_,_loc11_,"easeIn");
         _loc9_.delay = param7;
         _loc9_.animate("x",(param3 + param1 * 3) / 4);
         _loc9_.animate("y",(param4 + param2 * 3) / 4);
         jugglerA.add(_loc9_);
         param7 += _loc11_;
         _loc9_ = new Tween(_loc8_,_loc11_);
         _loc9_.delay = param7;
         _loc9_.animate("x",(param3 * 3 + param1) / 4);
         _loc9_.animate("y",(param4 * 3 + param2) / 4);
         jugglerA.add(_loc9_);
         param7 += _loc11_;
         _loc9_ = new Tween(_loc8_,_loc11_,"easeOut");
         _loc9_.delay = param7;
         _loc9_.fadeTo(0);
         _loc9_.animate("x",param3);
         _loc9_.animate("y",param4);
         _loc9_.onComplete = removeSelf;
         _loc9_.onCompleteArgs = [_loc8_];
         jugglerA.add(_loc9_);
      }
      
      public function popWords(param1:String, param2:Number = 2, param3:Number = 0.5, param4:Number = 0) : Sprite
      {
         var _loc6_:Tween = null;
         var _loc7_:HtmlTextField = null;
         var _loc5_:* = null;
         var _loc11_:Image = null;
         if(!show())
         {
            return null;
         }
         var _loc8_:Sprite = new Sprite();
         _loc8_.x = GameMapConfig.SCREEN_WIDTH / 2;
         if(Math.abs(param3) < 2)
         {
            param3 = GameMapConfig.SCREEN_HEIGHT * param3;
         }
         _loc8_.y = param3;
         _loc8_.alpha = 0;
         _loc8_.scaleX = _loc8_.scaleY = 0.5;
         if(param1.search("\n") != -1)
         {
            param1 = param1.replace("\n","");
         }
         var _loc10_:int = MainConfig.$isEA ? 17 : 20;
         var _loc12_:int = Math.max(15,Tools.getCharLength(param1,Tools.BAN_LIST2));
         _loc11_ = DisplayTools.newImg("UI_roulette_t_bg_");
         _loc11_.height = 20;
         _loc11_.width = (_loc10_ + 2) * _loc12_ * 5;
         _loc11_.alpha = 20;
         _loc8_.addChild(_loc11_);
         var _loc9_:Array = GlobalTextStyle.COLOR_B_G_G_R;
         param1 = Tools.formatLineX(param1,_loc9_,_loc11_.width,_loc10_,false,"center");
         _loc7_ = new HtmlTextField(GameMapConfig.SCREEN_WIDTH * 0.9 + 150,_loc10_ + 10,param1,true);
         _loc7_.touchable = false;
         _loc7_.pivotX = _loc7_.width / 2;
         _loc7_.pivotY = _loc7_.height / 2;
         _loc7_.hAlign = "center";
         _loc7_.vAlign = "center";
         _loc8_.addChild(_loc7_);
         _loc6_ = new Tween(_loc11_,0.3,"easeOut");
         _loc6_.delay = param4;
         _loc6_.animate("width",(_loc10_ + 2) * _loc12_ * 2);
         _loc6_.animate("height",_loc10_ + 20);
         _loc6_.fadeTo(1);
         jugglerA.add(_loc6_);
         _loc6_ = new Tween(_loc8_,0.3,"easeOut");
         _loc6_.delay = param4;
         _loc6_.fadeTo(1);
         _loc6_.scaleTo(1);
         jugglerA.add(_loc6_);
         _loc6_ = new Tween(_loc8_,0.3,"easeIn");
         _loc6_.delay = param2 + param4;
         _loc6_.fadeTo(0);
         _loc6_.animate("y",param3 - 30);
         _loc6_.onComplete = removeSelf;
         _loc6_.onCompleteArgs = [_loc8_];
         jugglerA.add(_loc6_);
         animationLayer.addChild(_loc8_);
         return _loc8_;
      }
      
      private static function newSuperWordGlyph(char:String, size:Number, x:int, y:int) : TextField
      {
         var effectFont:BitmapFont = TextField.getBitmapFont("Font_numAndtag_3");
         // The effect bitmap font was authored for a fixed phrase list.  A
         // new localized phrase can have missing glyphs and look like a bare
         // number; render only those missing glyphs with the normal CJK font.
         var font:String = effectFont && effectFont.hasChars(char) ? "Font_numAndtag_3" : GlobalConfig.FONT_0;
         return DisplayTools.newTextField(char,font,size,16777215,x,y);
      }

      public function popSuperWord(param1:String, param2:int = 1, param3:Number = 0.5, param4:Number = 0, param5:Number = 0, param6:Number = 1) : Sprite
      {
         param6 = Math.max(1,param6);
         param4 /= param6;
         param5 /= param6;
         var _loc10_:Tween = null;
         var _loc11_:TextField = null;
         var _loc6_:* = null;
         var _loc17_:int = 0;
         var _loc24_:int = 0;
         var _loc14_:int = 0;
         var _loc27_:int = 0;
         var _loc23_:int = 0;
         var _loc7_:String = null;
         var _loc18_:MovieClip = null;
         var _loc25_:Number = NaN;
         var _loc26_:Number = NaN;
         var _loc19_:Number = NaN;
         var _loc22_:AnimationSprite = null;
         if(param1 == "50006")
         {
            clear();
            GlobalFunction.levelup();
         }
         if(!show())
         {
            return null;
         }
         var _loc15_:String = "";
         var _loc8_:Sprite = new Sprite();
         var _loc16_:Number = 0.25 / param6;
         var _loc20_:Number = param4;
         var _loc9_:Number = 96;
         _loc19_ = MainConfig.$isEnglish ? 0.5 : 0.95;
         var _loc13_:Array = (GlobalLanguageStr.getStr(param1) as String).split("");
         var _loc21_:int = int(_loc13_.length);
         _loc9_ = param2 == 3 ? (_loc21_ < 8 ? _loc9_ : _loc9_ * 0.8) : Math.min(GlobalData.$mStageWidth / _loc21_,_loc9_);
         var _loc12_:Number = _loc9_ * _loc19_;
         _loc8_.x = GameMapConfig.SCREEN_WIDTH / 2;
         if(Math.abs(param3) < 2)
         {
            param3 = GameMapConfig.SCREEN_HEIGHT * param3;
         }
         _loc8_.y = param3;
         _loc18_ = DisplayTools.newMc("skillLeaderBg",0,0,15 * param6);
         _loc18_.scaleX = 3;
         jugglerA.delayCall(jugglerA.add,_loc20_,_loc18_);
         jugglerA.delayCall(_loc8_.addChildAt,_loc20_,_loc18_,0);
         if(param2 == 1)
         {
            jugglerA.delayCall(SoundManager.getOnlyExample().playSound,_loc20_ + _loc16_,"skill0");
            _loc10_ = new Tween(_loc18_,_loc16_,"easeOut");
            _loc10_.delay = _loc20_;
            _loc10_.animate("scaleY",2);
            jugglerA.add(_loc10_);
            _loc23_ = 0;
            while(_loc23_ < _loc21_)
            {
               _loc7_ = _loc15_ + _loc13_[_loc23_];
               _loc17_ = 0;
               _loc14_ = (_loc23_ - (_loc21_ - 1) / 2) * _loc12_;
               _loc24_ = -30;
               _loc11_ = newSuperWordGlyph(_loc7_,_loc9_,_loc17_,_loc24_);
               _loc11_.alpha = 0;
               _loc11_.scaleX = _loc11_.scaleY = 0;
               _loc8_.addChild(_loc11_);
               _loc10_ = new Tween(_loc11_,_loc16_);
               _loc10_.delay = _loc20_;
               _loc10_.animate("x",_loc14_);
               jugglerA.add(_loc10_);
               _loc10_ = new Tween(_loc11_,_loc16_ / 2,"easeOut");
               _loc10_.delay = _loc20_;
               _loc10_.animate("y",(_loc24_ + _loc27_ - 100) / 2);
               _loc10_.scaleTo(1);
               _loc10_.fadeTo(1);
               jugglerA.add(_loc10_);
               _loc10_ = new Tween(_loc11_,_loc16_ / 2,"easeIn");
               _loc10_.delay = _loc20_ + _loc16_ / 2;
               _loc10_.animate("y",_loc27_);
               jugglerA.add(_loc10_);
               _loc20_ += _loc16_ * 0.2;
               _loc23_++;
            }
         }
         else if(param2 == 2)
         {
            jugglerA.delayCall(SoundManager.getOnlyExample().playSound,_loc20_ + _loc16_ * 1.5,"skill1");
            _loc10_ = new Tween(_loc18_,_loc16_ * 1.5,"easeOutBack");
            _loc10_.delay = _loc20_;
            _loc10_.animate("scaleY",3);
            jugglerA.add(_loc10_);
            _loc23_ = 0;
            while(_loc23_ < _loc21_)
            {
               _loc7_ = _loc15_ + _loc13_[_loc23_];
               _loc14_ = (_loc23_ - (_loc21_ - 1) / 2) * _loc12_;
               _loc17_ = _loc14_ * 4;
               _loc24_ = _loc23_ % 2 * 300 - 150;
               _loc11_ = newSuperWordGlyph(_loc7_,_loc9_,_loc17_,_loc24_);
               _loc11_.alpha = 0;
               _loc11_.color = 0;
               _loc11_.scaleX = _loc11_.scaleY = 2;
               if(_loc23_ < _loc21_ / 2)
               {
                  _loc8_.addChild(_loc11_);
               }
               else
               {
                  _loc8_.addChildAt(_loc11_,1);
               }
               _loc10_ = new Tween(_loc11_,_loc16_,"easeOut");
               _loc10_.delay = _loc20_;
               _loc10_.fadeTo(1);
               jugglerA.add(_loc10_);
               _loc10_ = new Tween(_loc11_,_loc16_ * 2,"easeInOut");
               _loc10_.delay = _loc20_;
               _loc10_.scaleTo(1);
               _loc10_.animate("x",_loc14_);
               _loc10_.animate("y",_loc27_);
               _loc10_.animate("color",16777215);
               jugglerA.add(_loc10_);
               _loc10_ = new Tween(_loc11_,_loc16_,"easeInBack");
               _loc10_.delay = _loc20_ + _loc16_ * 2;
               _loc10_.scaleTo(Math.pow((_loc21_ - 1) / 2 + 1 - Math.abs(_loc14_ / _loc12_),0.2) - 0.1);
               jugglerA.add(_loc10_);
               _loc20_ += _loc16_ * 0.5;
               _loc23_++;
            }
         }
         else if(param2 == 3)
         {
            jugglerA.delayCall(SoundManager.getOnlyExample().playSound,_loc20_,"skill1");
            _loc10_ = new Tween(_loc18_,_loc16_ * 1.5,"easeOutBack");
            _loc10_.delay = _loc20_;
            _loc10_.animate("scaleY",3);
            _loc10_.animate("y",_loc18_.y + 20);
            jugglerA.add(_loc10_);
            _loc23_ = 0;
            while(_loc23_ < _loc21_)
            {
               _loc7_ = _loc15_ + _loc13_[_loc23_];
               _loc11_ = newSuperWordGlyph(_loc7_,_loc9_,_loc17_,_loc24_);
               _loc22_ = new AnimationSprite(_loc11_);
               _loc22_.scale = 0.8;
               _loc22_.alpha = 0;
               _loc22_.radian = _loc23_ * 3.141592653589793 * 2 / _loc21_;
               if(_loc23_ < (_loc21_ - 1) / 2)
               {
                  _loc8_.addChild(_loc22_);
               }
               else
               {
                  _loc8_.addChildAt(_loc22_,0);
               }
               _loc10_ = new Tween(_loc22_,_loc16_ * 1.5,"easeIn");
               _loc10_.delay = _loc20_;
               _loc10_.fadeTo(1);
               jugglerA.add(_loc10_);
               _loc25_ = Math.ceil(_loc22_.radian / (3.141592653589793 * 2)) * 3.141592653589793 * 2 + (_loc23_ - _loc21_ / 2 + 0.5) / _loc21_ * 3.141592653589793 * Math.min(0.9,_loc21_ * 0.1 + 0.2);
               if(_loc25_ > _loc22_.radian)
               {
                  _loc25_ -= 3.141592653589793 * 2;
               }
               if(_loc25_ + 3.141592653589793 * 2 <= _loc22_.radian)
               {
                  _loc25_ += 3.141592653589793 * 2;
               }
               _loc25_ -= 3.141592653589793 * 2;
               _loc10_ = new Tween(_loc22_,_loc16_ * 4,"easeOut");
               _loc10_.delay = _loc20_;
               _loc10_.animate("radian",_loc25_);
               jugglerA.add(_loc10_);
               _loc20_ += _loc16_;
               _loc23_++;
            }
         }
         _loc20_ += 4.5 * _loc16_ + param5;
         _loc10_ = new Tween(_loc18_,_loc16_ * 0.5);
         _loc10_.delay = _loc20_;
         _loc10_.fadeTo(0);
         _loc10_.onComplete = removeSelf;
         _loc10_.onCompleteArgs = [_loc18_];
         jugglerA.add(_loc10_);
         _loc20_ += _loc16_ * 0.5;
         _loc10_ = new Tween(_loc8_,_loc16_ * 0.5,"easeOutInBack");
         _loc10_.delay = _loc20_;
         _loc10_.scaleTo(1.1);
         jugglerA.add(_loc10_);
         _loc20_ += _loc16_ * 1;
         _loc10_ = new Tween(_loc8_,_loc16_ * 0.5,"easeIn");
         _loc10_.delay = _loc20_;
         _loc10_.scaleTo(0.5);
         _loc10_.fadeTo(0);
         _loc10_.onComplete = removeSelf;
         _loc10_.onCompleteArgs = [_loc8_];
         jugglerA.add(_loc10_);
         animationLayer.addChild(_loc8_);
         return _loc8_;
      }
      
      public function popInjured(param1:String, param2:int, param3:int, param4:int, param5:int, param6:uint = 16728128, param7:uint = 20, param8:Number = -1, param9:String = null) : void
      {
         var _loc10_:TextField = null;
         var _loc18_:Tween = null;
         var _loc17_:int = 0;
         var _loc19_:Image = null;
         if(!show())
         {
            return;
         }
         var _loc11_:Number = 1;
         var _loc14_:Number = 1.7;
         var _loc13_:Number = 1.2;
         var _loc16_:Number = 0;
         var _loc15_:Number = 0.2;
         if(param8 < 0)
         {
            param8 = 0.4;
         }
         param8 += 0.9;
         var _loc12_:Sprite = new Sprite();
         _loc10_ = DisplayTools.newTextField(param1,"",param7,param6);
         _loc10_.fontName = "Font_numAndtag_1";
         _loc10_.addEventListener("removedFromStage",removeSelfDispose);
         _loc12_.addChild(_loc10_);
         _loc10_.pivotX = _loc10_.width / 2;
         _loc10_.pivotY = _loc10_.height / 2;
         _loc17_ = _loc10_.width * 1.2 + 20;
         if(param9)
         {
            _loc19_ = DisplayTools.newImg(param9);
            _loc19_.scaleX = _loc19_.scaleY = param7 / 50;
            _loc18_ = new Tween(_loc19_,0.9 / 2,"easeOutBack");
            _loc18_.scaleTo(_loc19_.scaleX * 2);
            jugglerA.add(_loc18_);
            _loc12_.addChildAt(_loc19_,0);
         }
         param2 = Math.max(_loc17_ / 2,Math.min(GameMapConfig.FIGHT_WIDTH - _loc17_ / 2,param2));
         param3 = Math.max(0,Math.min(GameMapConfig.FIGHT_HEIGHT,param3));
         param4 = Math.max(_loc17_ / 2,Math.min(GameMapConfig.FIGHT_WIDTH - _loc17_ / 2,param4));
         param5 = Math.max(0,Math.min(GameMapConfig.FIGHT_HEIGHT,param5));
         _loc12_.x = param2;
         _loc12_.y = param3;
         _loc12_.scaleX = _loc12_.scaleY = _loc11_;
         _loc18_ = new Tween(_loc12_,param8 / 4,"easeOutBack");
         _loc18_.scaleTo(_loc14_);
         jugglerA.add(_loc18_);
         _loc18_ = new Tween(_loc12_,param8 / 4,"easeIn");
         _loc18_.delay = param8 / 2;
         _loc18_.fadeTo(0);
         _loc18_.onComplete = removeSelf;
         _loc18_.onCompleteArgs = [_loc12_];
         jugglerA.add(_loc18_);
         animationLayer.addChild(_loc12_);
      }
      
      public function popCasino(param1:*, param2:int = 0, param3:Number = 0, param4:String = "m006", param5:Object = null) : Number
      {
         var _tween:Tween;
         var _bg:Image;
         var _aList:Array;
         var _avatar:Avatar;
         var _maxStar:int;
         var k:*;
         var obj:Object;
         var i:int;
         var l:int;
         var _time:Number;
         var _allTime:Number;
         var _aSpr:AnimationSprite;
         var _x0:int;
         var _y0:int;
         var _x1:int;
         var _y1:int;
         var _polarRadian:Number;
         var _spr:Sprite;
         var _img:Image;
         var _mc:MovieClip;
         var _z:int;
         var sp:Sprite;
         var _halo:Image;
         var _avatarSpr:Sprite;
         var _attrs:*;
         var avatarr:Object;
         var str:String;
         var a:String;
         var _madelSpr:Sprite;
         var _config:Array;
         var _madel:Image;
         var _madelNum:int;
         var _numTf:LOL_TextField;
         var _configs:Object;
         var _scale:Number;
         var _colorfilter:ColorMatrixFilter;
         var _btn:LOL_Scale9Button;
         var _fun:Function;
         var _avatars:* = param1;
         var _type:int = param2;
         var _delay:Number = param3;
         var _bgUiName:String = param4;
         var data:Object = param5;
         if(!show())
         {
            return null;
         }
         // Page navigation can hide the previous reward layer. A new draw
         // always owns a fresh, visible layer and its own animation timeline.
         clearAnimationLayerForDraw();
         _maxStar = 0;
         if(_avatars is Array)
         {
            _aList = _avatars as Array;
         }
         else if(_type == 6 && data.type == "avatar_soul")
         {
            _aList = [];
            for(k in _avatars)
            {
               obj = GlobalFunction.getAwardByType("avatar_soul",_avatars,false,null,"",true);
               obj.start = int(((k.split("_")[2] as String).split("|") as Array)[0]);
               obj.avatar = new Avatar(k,{});
               _aList.push(obj);
            }
         }
         else
         {
            _aList = [];
            for(k in _avatars)
            {
               _avatar = new Avatar(k,_avatars[k]);
               _aList.push(_avatar);
            }
         }
         l = int(_aList.length);
         _time = 1.2;
         _allTime = _delay;
         _x0 = GameMapConfig.SCREEN_WIDTH / 2;
         _y0 = GameMapConfig.SCREEN_HEIGHT / 2;
         _bg = GlobalFunction.createImage(_bgUiName,true);
         _bg.width = GameMapConfig.SCREEN_WIDTH;
         _bg.height = GameMapConfig.SCREEN_HEIGHT;
         animationLayer.addChild(_bg);
         _halo = GlobalFunction.createImage("halo001",true);
         _halo.pivotX = _halo.width / 2;
         _halo.pivotY = _halo.height / 2;
         _halo.x = _x0;
         _halo.y = _y0;
         animationLayer.addChild(_halo);
         _tween = new Tween(_halo,_time * 2000);
         _tween.delay = _delay;
         _tween.animate("rotation",-628.3185307179587);
         jugglerA.add(_tween);
         animationLayer.touchable = true;
         _avatarSpr = new Sprite();
         _avatarSpr.touchable = false;
         animationLayer.addChild(_avatarSpr);
         if(l == 1)
         {
            if(_type == 6 && data.type == "avatar_soul")
            {
               _maxStar = int(_aList[0].start);
               _avatar = _aList[0].avatar;
               jugglerA.delayCall(SoundManager.getOnlyExample().playSound,_allTime,"skill1",0.5);
               sp = (_aList[0] as Object).ui;
               sp.touchable = true;
               sp.x = GlobalData.$mStageWidth / 2 - sp.width / 2 - 10;
               sp.y = GlobalData.$mStageHeight / 2 - sp.height / 2;
               jugglerA.delayCall(_avatarSpr.addChild,_allTime,sp);
               _tween = new Tween(sp,_time / 10,"easeOut");
               _tween.delay = _allTime;
               _tween.fadeTo(1);
               jugglerA.add(_tween);
               _allTime += _time / 10;
               _tween = new Tween(sp,_time / 2,"easeOut");
               _tween.delay = _allTime;
               _tween.fadeTo(1);
               _tween.scaleTo(1.5);
               jugglerA.add(_tween);
               _allTime += _time / 5;
            }
            else
            {
               _avatar = _aList[0];
               _maxStar = _avatar.getStar();
               jugglerA.delayCall(SoundManager.getOnlyExample().playSound,_allTime,"skill1",0.5);
               _img = GameMapTools.newAvatarImg(_avatar.avatarData.res,_x0,_y0 - 20);
               _img.color = 0;
               _img.alpha = 0;
               _img.scaleX = _img.scaleY = 2;
               _img.touchable = true;
               jugglerA.delayCall(_avatarSpr.addChild,_delay,_img);
               _tween = new Tween(_img,_time / 5,"easeIn");
               _tween.delay = _allTime;
               _tween.animate("color",16777215);
               _tween.scaleTo(1);
               _tween.fadeTo(1);
               jugglerA.add(_tween);
               _img.addEventListener("touch",_avatar.touchDetaiAvatar);
               _img = GameMapTools.newAvatarImg(_avatar.avatarData.res,_x0,_y0 - 20);
               _img.alpha = 0;
               _img.filter = new ColorMatrixFilter(Vector.<Number>([1,0,0,0,255,0,1,0,0,255,0,0,1,0,0,0,0,0,1,0]));
               _allTime += _time / 5;
               jugglerA.delayCall(_avatarSpr.addChild,_allTime,_img);
               _tween = new Tween(_img,_time / 10,"easeOut");
               _tween.delay = _allTime;
               _tween.fadeTo(1);
               jugglerA.add(_tween);
               _allTime += _time / 10;
               _tween = new Tween(_img,_time / 2,"easeOut");
               _tween.delay = _allTime;
               _tween.fadeTo(0);
               _tween.scaleTo(2);
               jugglerA.add(_tween);
               _allTime += _time / 5;
            }
            if(_type == 4)
            {
               LayoutUIAnimation.getOnlyExample().popSuperWord("50007",2,0.68,1.5);
               popStars(_avatar.getStar(),0,0.5,0.3,_allTime,1,false);
            }
            else if(_type == 5)
            {
               LayoutUIAnimation.getOnlyExample().popSuperWord("50016",2,0.68,1.5);
               popStars(_avatar.getStar(),0,0.5,0.3,_allTime,2,false);
            }
            else
            {
               popStars(_avatar.getStar(),0,0.5,0.3,_allTime,2,false);
            }
         }
         else if(_type == 6)
         {
            i = 0;
            while(i < l)
            {
               _spr = new Sprite();
               _spr.scaleX = _spr.scaleY = i % 2 == 0 ? 6 : 3;
               _spr.alpha = 0;
               _attrs = _attrs = {"id":"e518"};
               _attrs.par = _spr;
               DisplayTools.addEffectOne(_attrs);
               _aSpr = new AnimationSprite(_spr);
               _aSpr.polarX = _x0 + 5;
               _aSpr.polarY = _y0 + 6;
               _aSpr.polarRadian = (l - i) / l * 3.141592653589793 * 2;
               _aSpr.polarZ = (i % 2 == 0 ? GameMapConfig.SCREEN_HEIGHT / 2 : GameMapConfig.SCREEN_HEIGHT / 4) * (0.6 + i * 0.1);
               _polarRadian = _aSpr.polarRadian + 3.141592653589793 * 4;
               _z = 200;
               jugglerA.delayCall(_avatarSpr.addChild,_delay,_aSpr);
               _tween = new Tween(_spr,_time / 2,"easeOut");
               _tween.delay = _delay;
               _tween.fadeTo(1);
               jugglerA.add(_tween);
               _tween = new Tween(_spr,_time,"easeOut");
               _tween.delay = _delay;
               _tween.scaleTo(1);
               jugglerA.add(_tween);
               _tween = new Tween(_aSpr,_time);
               _tween.delay = _delay;
               _tween.animate("polarRadian",_polarRadian);
               _tween.animate("polarZ",_z * 0);
               _tween.onComplete = function(param1:DisplayObject):void
               {
                  param1.removeFromParent();
               };
               _tween.onCompleteArgs = [_aSpr];
               jugglerA.add(_tween);
               avatarr = _aList[i];
               str = "";
               for(a in avatarr)
               {
                  if(a == "avatar" || a == "avatar_soul")
                  {
                     str = a;
                  }
               }
               _avatar = _aList[i].avatarInfo;
               _maxStar = Math.max(_maxStar,_avatar.getStar());
               _spr = GlobalFunction.getAwardByType(str,avatarr[str],false,null,"",true).ui;
               _spr.pivotX = _spr.width / 2;
               _spr.pivotY = _spr.height / 2;
               _spr.scaleX = _spr.scaleY = 0.2;
               _aSpr = new AnimationSprite(_spr);
               _aSpr.polarX = _x0 + 5;
               _aSpr.polarY = _y0 + 6;
               _aSpr.polarRadian = (l - i) / l * 3.141592653589793 * 2;
               jugglerA.delayCall(_avatarSpr.addChild,_allTime + _time,_aSpr);
               _tween = new Tween(_spr,_time,"easeOut");
               _tween.delay = _delay;
               _tween.scaleTo(1);
               jugglerA.add(_tween);
               _tween = new Tween(_aSpr,_time * 0.2,"easeOutBack");
               _tween.delay = _allTime + _time;
               _tween.animate("polarZ",_z);
               jugglerA.add(_tween);
               _x1 = _aSpr.polarX + Math.sin(_polarRadian) * _z;
               _y1 = _aSpr.polarY + Math.cos(_polarRadian) * _z;
               jugglerA.delayCall(popEffect,_allTime + _time * 1.05,{
                  "id":"e024",
                  "x":_x1,
                  "y":_y1,
                  "scx":1.5,
                  "m":"add"
               });
               jugglerA.delayCall(SoundManager.getOnlyExample().playSound,_allTime,"E_8007",0.5);
               jugglerA.delayCall(SoundManager.getOnlyExample().playSound,_allTime + _time * 1.05,"skill1",0.5);
               _allTime += _time / 50;
               i = i + 1;
            }
            _allTime += _time * 1.2;
         }
         else
         {
            i = 0;
            while(i < l)
            {
               _spr = new Sprite();
               _spr.scaleX = _spr.scaleY = i % 2 == 0 ? 6 : 3;
               _spr.alpha = 0;
               _attrs = _attrs = {"id":"e518"};
               _attrs.par = _spr;
               DisplayTools.addEffectOne(_attrs);
               _aSpr = new AnimationSprite(_spr);
               _aSpr.polarX = _x0 + 5;
               _aSpr.polarY = _y0 + 6;
               _aSpr.polarRadian = (l - i) / l * 3.141592653589793 * 2;
               _aSpr.polarZ = (i % 2 == 0 ? GameMapConfig.SCREEN_HEIGHT / 2 : GameMapConfig.SCREEN_HEIGHT / 4) * (0.6 + i * 0.1);
               _polarRadian = _aSpr.polarRadian + 3.141592653589793 * 4;
               _z = 200;
               jugglerA.delayCall(_avatarSpr.addChild,_delay,_aSpr);
               _tween = new Tween(_spr,_time / 2,"easeOut");
               _tween.delay = _delay;
               _tween.fadeTo(1);
               jugglerA.add(_tween);
               _tween = new Tween(_spr,_time,"easeOut");
               _tween.delay = _delay;
               _tween.scaleTo(1);
               jugglerA.add(_tween);
               _tween = new Tween(_aSpr,_time);
               _tween.delay = _delay;
               _tween.animate("polarRadian",_polarRadian);
               _tween.animate("polarZ",_z * 0);
               _tween.onComplete = function(param1:DisplayObject):void
               {
                  param1.removeFromParent();
               };
               _tween.onCompleteArgs = [_aSpr];
               jugglerA.add(_tween);
               _avatar = _aList[i];
               _maxStar = Math.max(_maxStar,_avatar.getStar());
               _spr = _avatar.getAvatarRes();
               _spr.pivotX = _spr.width / 2;
               _spr.pivotY = _spr.height / 2;
               _spr.scaleX = _spr.scaleY = 0.2;
               _aSpr = new AnimationSprite(_spr);
               _aSpr.polarX = _x0 + 5;
               _aSpr.polarY = _y0 + 6;
               _aSpr.polarRadian = (l - i) / l * 3.141592653589793 * 2;
               jugglerA.delayCall(_avatarSpr.addChild,_allTime + _time,_aSpr);
               _tween = new Tween(_spr,_time,"easeOut");
               _tween.delay = _delay;
               _tween.scaleTo(1);
               jugglerA.add(_tween);
               _tween = new Tween(_aSpr,_time * 0.2,"easeOutBack");
               _tween.delay = _allTime + _time;
               _tween.animate("polarZ",_z);
               jugglerA.add(_tween);
               _x1 = _aSpr.polarX + Math.sin(_polarRadian) * _z;
               _y1 = _aSpr.polarY + Math.cos(_polarRadian) * _z;
               jugglerA.delayCall(popEffect,_allTime + _time * 1.05,{
                  "id":"e024",
                  "x":_x1,
                  "y":_y1,
                  "scx":1.5,
                  "m":"add"
               });
               jugglerA.delayCall(SoundManager.getOnlyExample().playSound,_allTime,"E_8007",0.5);
               jugglerA.delayCall(SoundManager.getOnlyExample().playSound,_allTime + _time * 1.05,"skill1",0.5);
               _spr.addEventListener("touch",_avatar.touchDetaiAvatar);
               _allTime += _time / 50;
               i = i + 1;
            }
            _allTime += _time * 1.2;
         }
         if(_type == 2 || _type == 3)
         {
            tempUIName = "center_casino_B";
            _allTime += _time / 5;
            _madelSpr = new Sprite();
            _config = GlobalData.$mConfig_simple.wager_avatar as Array;
            _madel = GlobalFunction.createImage("UI_award_ui_type_0005");
            _madel.pivotX = _madel.width / 2;
            _madel.pivotY = _madel.height / 2;
            _madelSpr.addChild(_madel);
            _madelNum = int(l > 1 ? _config[13] : (_type == 3 ? _config[11] : _config[12]));
            _numTf = GlobalTextStyle.getBitmapText(90 * 2,24,"×" + _madelNum,20,16777215,"center");
            _numTf.pivotX = _numTf.width / 2;
            _numTf.pivotY = _numTf.height / 2;
            _numTf.y = 30;
            _madelSpr.addChild(_numTf);
            _madelSpr.x = _x0;
            _madelSpr.y = l > 1 ? _y0 : _y0 + 200;
            _madelSpr.touchable = false;
            _madelSpr.scaleX = _madelSpr.scaleY = 2;
            jugglerA.delayCall(animationLayer.addChild,_allTime,_madelSpr);
            _tween = new Tween(_madelSpr,_time / 3,"easeOutBack");
            _tween.scaleTo(1);
            _tween.delay = _allTime;
            jugglerA.add(_tween);
            jugglerA.delayCall(SoundManager.getOnlyExample().playSound,_allTime,"skill2",0.5);
         }
         else if(_type != 4)
         {
            if(_type != 5)
            {
               if(_type == 6)
               {
                  _allTime += _time / 5;
                  _madelSpr = new Sprite();
                  _configs = GlobalData.$mConfig.ploy_system_simple.extract_avatar;
                  _madel = GlobalFunction.createImage("UI_award_ui_type_0019");
                  _madel.pivotX = _madel.width / 2;
                  _madel.pivotY = _madel.height / 2;
                  _madelSpr.addChild(_madel);
                  _madelNum = int(l > 1 ? _configs.score_ten : _configs.score_one);
                  _numTf = GlobalTextStyle.getBitmapText(90 * 2,24,"×" + _madelNum,20,16777215,"center");
                  _numTf.pivotX = _numTf.width / 2;
                  _numTf.pivotY = _numTf.height / 2;
                  _numTf.y = 30;
                  _madelSpr.addChild(_numTf);
                  _madelSpr.x = _x0;
                  _madelSpr.y = l > 1 ? _y0 : _y0 + 200;
                  _madelSpr.touchable = false;
                  _madelSpr.scaleX = _madelSpr.scaleY = 2;
                  jugglerA.delayCall(animationLayer.addChild,_allTime,_madelSpr);
                  _tween = new Tween(_madelSpr,_time / 3,"easeOutBack");
                  _tween.scaleTo(1);
                  _tween.delay = _allTime;
                  jugglerA.add(_tween);
                  jugglerA.delayCall(SoundManager.getOnlyExample().playSound,_allTime,"skill2",0.5);
                  if(!data.isActivity)
                  {
                     _madelSpr.visible = false;
                  }
               }
               else
               {
                  tempUIName = "center_casino_A";
               }
            }
         }
         if(_type == 1 || _type == 3)
         {
            tempUIName = "center_shopAndVIP";
         }
         // Tint preserves the rarity cue without allocating an offscreen
         // filter texture at the end of every draw on mobile GPUs.
         _scale = 1;
         _halo.color = 16777215;
         if(_maxStar == 6) { _halo.color = 16760928; _scale = 1.2; }
         else if(_maxStar == 5) { _halo.color = 13408767; _scale = 1.1; }
         else if(_maxStar == 3) { _halo.color = 6736998; _scale = 0.9; }
         else if(_maxStar == 2) { _halo.color = 11184810; _scale = 0.8; }
         else if(_maxStar == 1) { _halo.color = 8947848; _scale = 0.7; }
         _halo.scaleX = _halo.scaleY = 0;
         _tween = new Tween(_halo,_time / 3,"easeOutBack");
         _tween.scaleTo(_scale);
         _tween.fadeTo(_scale);
         _tween.delay = l == 1 ? _allTime * 0.5 : _allTime - _time / 2;
         jugglerA.add(_tween);
         GuideMaster.getOnlyExample().guideWait();
         if(_type == 6)
         {
            txt1 = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90671) + ":" + GlobalData.$userData.coin,20,16777215,"center",800,46);
            txt1.autoSize = "center";
            txt1.x = GlobalData.$mStageWidth / 2 - txt1.width / 2;
            txt1.y = GlobalData.$mStageHeight / 2 + 270;
            txt = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97072,data.score),20,16777215,"center",800,46);
            txt.autoSize = "center";
            txt.x = GlobalData.$mStageWidth / 2 - txt.width / 2;
            txt.y = txt1.y + 30;
            if(!data.isActivity)
            {
               txt.visible = false;
            }
            tempUIName = "center_casino_VIP";
         }
         _btn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20465),125,45,"UI_btn_enterGame_0_0000");
         _btn.x = GameMapConfig.SCREEN_WIDTH / 2 - _btn.width / 2;
         _btn.y = GlobalData.$mStageHeight - 130;
         _btn.addEventListener("triggered",rePanel);
         _fun = function():void
         {
            _avatarSpr.touchable = true;
            animationLayer.addChild(_btn);
            if(_type == 6)
            {
               animationLayer.addChild(txt1);
               animationLayer.addChild(txt);
            }
            GuideMaster.getOnlyExample().nextGuideStep();
            jugglerA.delayCall(showTipShare,2,_avatar);
         };
         if(_type == 4 || _type == 5)
         {
            _allTime += 3;
         }
         jugglerA.delayCall(_fun,_allTime,_btn);
         return _allTime;
      }
      
      private function showTipShare(param1:Avatar) : void
      {
         var tempIndex:int;
         var tempId:String;
         var tempStr:String;
         var shareStr:String;
         var avatar:Avatar = param1;
         var ok:* = function():void
         {
            GlobalPFANE.pfShare(tempIndex,avatar.avatarData.name);
         };
         var no:* = function():void
         {
         };
         if(GlobalData.isShow_ShareBtn == false || GlobalLocalStore.$pf_type_curr != "dnyios" || GlobalLocalStore.$pf_type_curr != "dnyad")
         {
            return;
         }
         if(avatar.getStar() == 5)
         {
            tempStr = GlobalLocalStore.get5StarAvatarFirst();
            tempId = GlobalData.First_Get_5Star_Avatar + GlobalData.$userData.name;
            shareStr = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(95024) + avatar.avatarData.name,[16777215]);
            if(tempStr != tempId)
            {
               tempIndex = 2;
               GlobalFunction.popAlert("",shareStr,{
                  "ok":ok,
                  "okUI":GlobalLanguageStr.getLanguageStr(95020),
                  "no":no,
                  "noUI":GlobalLanguageStr.getLanguageStr(20104),
                  "aid":"A_1095_5"
               });
               GlobalLocalStore.set5StarAvatarFirst(tempId);
            }
         }
         if(avatar.getStar() == 6)
         {
            tempStr = GlobalLocalStore.get6StarAvatarFirst();
            tempId = GlobalData.First_Get_6Star_Avatar + GlobalData.$userData.name;
            shareStr = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(95025) + avatar.avatarData.name,[16777215]);
            if(tempStr != tempId)
            {
               tempIndex = 4;
               GlobalFunction.popAlert("",shareStr,null,{
                  "ok":ok,
                  "okUI":GlobalLanguageStr.getLanguageStr(95020),
                  "no":no,
                  "noUI":GlobalLanguageStr.getLanguageStr(20104),
                  "aid":"A_1095_5"
               });
               GlobalLocalStore.set6StarAvatarFirst(tempId);
            }
         }
      }
      
      public function rePanel(param1:Event = null) : void
      {
         clearAnimationLayer();
         GuideMaster.getOnlyExample().nextGuideStep();
         GlobalData.$mEventDispatcher.dispatchEventWith("update_avatar_starup");
      }

      private function clearAnimationLayerForDraw() : void
      {
         // Do not reopen the previous recruitment page while starting a draw.
         tempUIName = null;
         clearAnimationLayer();
         visible = true;
         touchable = true;
         isPlay = true;
      }
      
      public function clearAnimationLayer(param1:Event = null) : void
      {
         var _loc2_:LayoutUICenter = null;
         StarlingTools.removeChildrenClear(this.animationLayer);
         animationLayer.touchable = false;
         animationLayer.visible = true;
         if(txt1)
         {
            txt1.removeFromParent(true);
            txt1.dispose();
         }
         if(txt)
         {
            txt.removeFromParent(true);
            txt.dispose();
         }
         txt = null;
         txt1 = null;
         var _loc3_:String = tempUIName;
         tempUIName = null;
         if(_loc3_)
         {
            _loc2_ = GlobalData.$mGameClassObject.mLayoutUICenter;
            if(_loc2_)
            {
               PanelCenterShopVIP.$selectType = 0;
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_shopAndVIP");
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel(_loc3_,false,true);
            }
         }
         jugglerA.purge();
      }
      
      public function hideAnimationLayer(param1:* = null) : void
      {
         if(animationLayer.touchable || GlobalData.$userData.isInActivityTime)
         {
            animationLayer.visible = false;
         }
         else
         {
            clearAnimationLayer();
         }
      }
      
      public function showAnimationLayer(param1:* = null) : void
      {
         if(animationLayer.touchable || GlobalData.$userData.isInActivityTime)
         {
            animationLayer.visible = true;
         }
      }
      
      public function clearIfNoGuide() : void
      {
         if(GlobalData.$currentGuide)
         {
            return;
         }
         clear();
      }
      
      override public function clear() : void
      {
         if(m_arrowhead)
         {
            jugglerG.removeTweens(m_arrowhead);
            m_arrowhead.dispose();
            m_arrowhead = null;
         }
         if(m_click)
         {
            jugglerG.removeTweens(m_click);
            m_click.dispose();
            m_click = null;
         }
         if(m_next)
         {
            m_next = null;
         }
         if(m_replay)
         {
            m_replay = null;
         }
         if(m_skip)
         {
            m_skip = null;
         }
         if(m_test)
         {
            m_test = null;
         }
         if(m_storeClear)
         {
            m_storeClear = null;
         }
         if(m_infoTf)
         {
            jugglerG.removeTweens(m_infoTf);
            m_infoTf.dispose();
            m_infoTf = null;
         }
         if(m_infoPop)
         {
            jugglerG.removeTweens(m_infoPop);
            m_infoPop.dispose();
            m_infoPop = null;
         }
         if(m_mask)
         {
            m_mask.texture.dispose();
            m_mask.dispose();
            m_mask = null;
         }
         if(m_quad)
         {
            m_quad.dispose();
            m_quad = null;
         }
         if(m_transmission)
         {
            m_transmission.dispose();
            m_transmission = null;
         }
         removeEventListener("touch",this.onTouch);
         StarlingTools.removeChildrenClear(this.guideLayer);
         var _loc1_:Guide = GuideMaster.getOnlyExample().currentGuide;
         if(_loc1_ && _loc1_.group == "B")
         {
            addNextSkip();
         }
         jugglerG.purge();
         addEventListener("enterFrame",onEnterFrame);
         isPlay = true;
      }
   }
}

