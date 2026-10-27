package com.meng52.game.ui.map
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalLocalStore;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.map.GameMap;
   import com.meng52.game.module.map.GameMapConfig;
   import com.meng52.game.ui.effect.BaseLayer;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.sound.SoundManager;
   import dragonBones.animation.WorldClock;
   import flash.geom.Rectangle;
   import starling.animation.Juggler;
   import starling.animation.Tween;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.EnterFrameEvent;

   public class GameMapLayer
   {

      public static var fpsLv:int = 1;

      public static var canFpsLv:int = 1;

      public static var isAuto:Boolean = false;

      public static var isPlay:Boolean = true;

      public static var isReady:Boolean = false;

      private static var onlyExample:GameMapLayer = null;

      public static var FPS_LIST:Array = [1,2,4,10];

      public var mapStage:BaseLayer;

      public var lineLayerList:Array;

      public var mgLayer:BaseLayer;

      public var lineLayer:LineLayer;

      public var effectLayer:EffectLayer;

      public var doorLayer:DoorLayer;

      public var uiLayer:UiLayer;

      public var infoLayer:InfoLayer;

      public var juggler:Juggler;

      public var clock:WorldClock;

      public function GameMapLayer()
      {
         super();
         init();
      }

      public static function setAuto(param1:Boolean) : void
      {
         var _loc2_:String = null;
         if(isAuto == param1)
         {
            return;
         }
         isAuto = param1;
         if(isAuto)
         {
            _loc2_ = GlobalLanguageStr.getLanguageStr(32003);
         }
         else
         {
            _loc2_ = GlobalLanguageStr.getLanguageStr(32004);
            GlobalData.$mEventDispatcher.dispatchEventWith("autoOff");
         }
         LayoutUIAnimation.getOnlyExample().popWords(_loc2_,1,0.3);
      }

      public static function get gl() : GameMapLayer
      {
         if(onlyExample == null)
         {
            onlyExample = new GameMapLayer();
         }
         return onlyExample;
      }

      public static function get isFastest() : Boolean
      {
         return fpsLv == FPS_LIST.length - 1;
      }

      public static function get isFast() : Boolean
      {
         return fpsLv >= FPS_LIST.length - 2;
      }

      public function delayCall(param1:Function, param2:Number, ... rest) : void
      {
         var _loc4_:Array = [param1,param2].concat(rest);
         if(param2 <= 0)
         {
            param1.apply(null,rest);
            return;
         }
         onlyExample.juggler.delayCall.apply(null,_loc4_);
      }

      public function addTween(param1:Tween) : void
      {
         onlyExample.juggler.add(param1);
      }

      private function init() : void
      {
         var _loc1_:Object = null;
         mapStage = new BaseLayer();
         mapStage.touchable = true;
         mapStage.y = 0;
         mgLayer = new BaseLayer();
         mgLayer.touchable = true;
         effectLayer = new EffectLayer();
         lineLayer = new LineLayer();
         uiLayer = new UiLayer();
         doorLayer = new DoorLayer();
         infoLayer = new InfoLayer();
         mapStage.addChild(mgLayer);
         mapStage.addChild(lineLayer);
         mapStage.addChild(effectLayer);
         mapStage.addChild(uiLayer);
         mapStage.addChild(infoLayer);
         juggler = new Juggler();
         clock = new WorldClock();
         mapStage.visible = false;
         _loc1_ = GlobalLocalStore.getIconStyle();
         if(_loc1_)
         {
            Avatar.iconStyle = int(_loc1_);
         }
         _loc1_ = GlobalLocalStore.getHelpTips();
         if(_loc1_)
         {
            UiLayer.tipsIndex = uint(_loc1_);
         }
         mapStage.addEventListener("enterFrame",onEnterFrame);
      }

      private function onEnterFrame(param1:EnterFrameEvent) : void
      {
         if(!isPlay || !mapStage.visible)
         {
            return;
         }
         var _loc2_:Number = param1.passedTime;
         if(isReady)
         {
            _loc2_ *= FPS_LIST[fpsLv];
         }
         juggler.advanceTime(_loc2_);
         clock.advanceTime(_loc2_);
         Avatar.advanceEffects104(_loc2_);
      }

      public function show(param1:int) : void
      {
         var _loc9_:int = 0;
         var _loc8_:BgLayer = null;
         var _loc5_:ShadowLayer = null;
         var _loc7_:AvatarLayer = null;
         var _loc3_:Rectangle = null;
         var _loc6_:Sprite = null;
         var _loc4_:int = 0;
         lineLayerList = [];
         var _loc2_:Number = GameMapConfig.FIGHT_WIDTH / param1;
         _loc9_ = 0;
         while(_loc9_ < param1)
         {
            _loc4_ = Math.round(_loc2_ * (_loc9_ + 0.5));
            _loc6_ = new Sprite();
            _loc8_ = new BgLayer();
            _loc5_ = new ShadowLayer();
            _loc7_ = new AvatarLayer();
            _loc7_.line = _loc9_;
            _loc7_.touchable = true;
            _loc3_ = new Rectangle(-Math.round(_loc2_ / 2),0,Math.round(_loc2_),GameMapConfig.FIGHT_HEIGHT * (1 + GameMapConfig.FIGHT_EXTRA_Y));
            lineLayerList[_loc9_] = [_loc8_,_loc5_,_loc7_,_loc3_,_loc6_];
            _loc6_.addChild(_loc8_);
            _loc6_.addChild(_loc5_);
            _loc6_.addChild(_loc7_);
            _loc6_.x = _loc4_;
            _loc6_.clipRect = _loc3_;
            mgLayer.addChild(_loc6_);
            _loc9_++;
         }
         mapStage.visible = true;
      }

      public function getLineSpr(param1:int) : Sprite
      {
         return lineLayerList[param1][4];
      }

      public function getLineBg(param1:int) : BgLayer
      {
         return lineLayerList[param1][0];
      }

      public function closeLine() : void
      {
         var _tween:Tween;
         var _rect:Rectangle;
         var _spr:Sprite;
         var _win:int;
         var _avatarLayer:AvatarLayer;
         var _team:int;
         var _x:int;
         var _b:Boolean;
         var _w:int;
         var _lingFg:Image;
         var _gameMap:GameMap = GameMap.currentMap;
         var _num:int = int(lineLayerList.length);
         var i:int = 0;
         while(i < lineLayerList.length)
         {
            _win = int(_gameMap.winnerList[i]);
            if(_win != 0)
            {
               _rect = lineLayerList[i][3];
               _spr = lineLayerList[i][4];
               _avatarLayer = lineLayerList[i][2];
               if(_avatarLayer.addClose(_win))
               {
                  _spr.parent.setChildIndex(_spr,0);
                  _team = int(_gameMap.winnerList[i]);
                  SoundManager.getOnlyExample().playSound("doorOpen");
                  if(_team == 1)
                  {
                     delayCall(SoundManager.getOnlyExample().playSound,2 / 2,"E_9020");
                  }
                  else
                  {
                     delayCall(SoundManager.getOnlyExample().playSound,2 / 2,"E_9021");
                  }
                  delayCall(uiLayer.changeSignBar,2 / 2,i,_gameMap.winnerList[i]);
                  delayCall(_spr.removeFromParent,2);
               }
               _num = _num - 1;
            }
            i = i + 1;
         }
         _x = 0;
         _b = false;
         GameMapConfig.lineOffset = Math.round(1200 * 3 / _num);
         GameMapConfig.sideOffset = Math.round(GameMapConfig.lineOffset * 0.25);
         _w = Math.round(GameMapConfig.FIGHT_WIDTH / _num);
         i = 0;
         while(i < lineLayerList.length)
         {
            if(_gameMap.winnerList[i] == 0)
            {
               _rect = lineLayerList[i][3];
               _spr = lineLayerList[i][4];
               _tween = new Tween(_rect,2 / 5,"easeInOut");
               _tween.delay = 1.6;
               _tween.animate("x",-Math.round(_w / 2));
               _tween.animate("width",_w);
               _tween.onUpdate = function(param1:Sprite, param2:Rectangle):void
               {
                  param1.clipRect = param2;
               };
               _tween.onUpdateArgs = [_spr,_rect];
               addTween(_tween);
               _tween = new Tween(_spr,2 / 5,"easeInOut");
               _tween.delay = 1.6;
               _tween.animate("x",Math.round(_x + _w / 2));
               addTween(_tween);
               _x += _w;
               _b = true;
            }
            if(lineLayer.lineFgList)
            {
               _lingFg = lineLayer.lineFgList[i];
               if(_lingFg)
               {
                  _tween = new Tween(_lingFg,2 / 5,"easeInOut");
                  _tween.delay = 1.6;
                  _tween.animate("x",Math.round(_x));
                  _tween.onCompleteArgs = [_lingFg];
                  _tween.onComplete = function(param1:Image):void
                  {
                     if(param1.x <= 0 || param1.x >= GameMapConfig.FIGHT_WIDTH)
                     {
                        param1.visible = false;
                     }
                  };
                  addTween(_tween);
                  _b = false;
               }
            }
            i = i + 1;
         }
      }

      public function startMg() : void
      {
         var _loc3_:int = 0;
         var _loc1_:Sprite = null;
         var _loc2_:Image = null;
         _loc3_ = 0;
         while(_loc3_ < lineLayerList.length)
         {
            _loc1_ = lineLayerList[_loc3_][4];
            _loc1_.y = -GameMapConfig.FIGHT_HEIGHT * GameMapConfig.FIGHT_EXTRA_Y;
            _loc3_++;
         }
         _loc3_ = 0;
         while(_loc3_ < lineLayer.lineFgList.length)
         {
            _loc2_ = lineLayer.lineFgList[_loc3_];
            _loc2_.y = -GameMapConfig.FIGHT_HEIGHT * GameMapConfig.FIGHT_EXTRA_Y;
            _loc3_++;
         }
      }

      public function moveMg() : void
      {
         var _loc1_:Tween = null;
         var _loc4_:int = 0;
         var _loc2_:Sprite = null;
         var _loc3_:Image = null;
         _loc4_ = 0;
         while(_loc4_ < lineLayerList.length)
         {
            _loc2_ = lineLayerList[_loc4_][4];
            _loc1_ = new Tween(_loc2_,1.2);
            _loc1_.animate("y",0);
            addTween(_loc1_);
            _loc4_++;
         }
         _loc4_ = 0;
         while(_loc4_ < lineLayer.lineFgList.length)
         {
            _loc3_ = lineLayer.lineFgList[_loc4_];
            _loc1_ = new Tween(_loc3_,1.2);
            _loc1_.animate("y",0);
            addTween(_loc1_);
            _loc4_++;
         }
      }

      public function addAvatar(param1:Avatar, param2:int = 0) : void
      {
         if(!lineLayerList || !lineLayerList[param1.line])
         {
            return;
         }
         var _loc3_:AvatarLayer = lineLayerList[param1.line][2] as AvatarLayer;
         if(param2 < 0)
         {
            param2 = Math.max(0,_loc3_.numChildren + param2 + 1);
         }
         _loc3_.addChildAt(param1.fightRes,param2);
      }

      public function getLineX(param1:int) : int
      {
         var _loc2_:Sprite = null;
         _loc2_ = lineLayerList[param1][4];
         return _loc2_.x;
      }

      public function sortAvatar() : void
      {
         var _loc2_:int = 0;
         var _loc1_:AvatarLayer = null;
         _loc2_ = 0;
         while(_loc2_ < lineLayerList.length)
         {
            _loc1_ = lineLayerList[_loc2_][2] as AvatarLayer;
            _loc1_.sort();
            _loc2_++;
         }
      }

      public function clearAvatar() : void
      {
         var _loc2_:int = 0;
         var _loc1_:AvatarLayer = null;
         _loc2_ = 0;
         while(_loc2_ < lineLayerList.length)
         {
            _loc1_ = lineLayerList[_loc2_][2] as AvatarLayer;
            _loc1_.clear();
            _loc2_++;
         }
      }

      public function initBg() : void
      {
         var _loc2_:int = 0;
         var _loc1_:BgLayer = null;
         _loc2_ = 0;
         while(_loc2_ < lineLayerList.length)
         {
            _loc1_ = lineLayerList[_loc2_][0] as BgLayer;
            _loc1_.init(_loc2_);
            _loc2_++;
         }
      }

      public function clear() : void
      {
         isPlay = true;
         Avatar.clearEffects104();
         juggler.purge();
         clock.clear();
         mapStage.visible = false;
         mapStage.clipRect = null;
         mapStage.scaleX = mapStage.scaleY = 1;
         mapStage.y = 0;
         mapStage.pivotY = 0;
         isReady = false;
         mgLayer.clear();
         mgLayer.touchable = true;
         lineLayerList = null;
         effectLayer.clear();
         doorLayer.clear();
         lineLayer.clear();
         uiLayer.clear();
         infoLayer.clear();
         if(GlobalData.$mGameClassObject)
         {
            GlobalData.$mGameClassObject.touchable = true;
         }
      }
   }
}
