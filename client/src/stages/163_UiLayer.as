package com.meng52.game.ui.map
{
   import com.meng52.game.command.map.GameMapData;
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalLocalStore;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.module.map.GameMap;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.ui.panel.PanelInforPop;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.display.ScrollScreenForTxt;
   import com.meng52.game.module.map.GameMapConfig;
   import com.meng52.game.module.map.GameMapTools;
   import com.meng52.game.ui.effect.BaseLayer;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.element.HtmlTextField;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.utils.HtmlTextFormat;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import starling.animation.Tween;
   import starling.display.DisplayObject;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   
   public class UiLayer extends BaseLayer
   {
      
      public static const SHADOW_COLOR:uint = 0;
      
      public static const SHADOW_ALPHA:Number = 0.6;
      
      public static const SHADOW_Y:int = 3;
      
      public static const HELP_TIPS_MIN:int = 46100;
      
      public static const HELP_TIPS_MAX:int = 46199;
      
      public static var tipsLength:uint;
      
      public static var tipsIndex:uint;
      
      public static var btnRateReduce:LOL_Button;
      
      public static var btnRateIncrease:LOL_Button;
      
      public static var btnToAuto:LOL_Button;
      
      public var m_mapName:HtmlTextField;
      
      public var m_mapName2:HtmlTextField;
      
      public var m_roundTF:TextField;
      
      public var m_roundTF2:TextField;
      
      public var m_rateSpr:Sprite;
      
      public var m_winBg:Sprite;
      
      public var m_black:Sprite;
      
      public var m_bag:Image;
      
      public var m_tips:Sprite;
      
      private var m9x9_bg:Scale9Image;
      
      protected var m_tipsTf:HtmlTextField;
      
      public var lineSignList:Array;
      
      public var canReturn:Boolean;

      public var m_sprFg:Sprite;
      
      public function UiLayer()
      {
         super();
      }
      
      public function init(param1:* = null) : void
      {
         m_sprFg = new Sprite();
         addChild(m_sprFg);
         var _loc2_:GameMapData = GameMap.currentMap.gameMapData;
         touchable = true;
         addBg();
         addRound();
         addWinSign(GameMapTools.getWinStr(_loc2_));
         addButton();
         addBag();
         addSignBar(_loc2_.line);
      }
      
      public function addSignBar(param1:int) : void
      {
         var _loc4_:Image = null;
         var _loc5_:int = 0;
         if(lineSignList)
         {
            return;
         }
         lineSignList = [];
         var _loc2_:int = GameMapConfig.FIGHT_WIDTH / 2;
         var _loc3_:int = 65;
         _loc5_ = 0;
         while(_loc5_ < param1)
         {
            _loc4_ = DisplayTools.newImg("lineSign0");
            _loc4_.x = _loc2_ + (_loc5_ - (param1 - 1) / 2) * 40;
            _loc4_.y = _loc3_;
            m_sprFg.addChild(_loc4_);
            lineSignList.push(_loc4_);
            _loc5_++;
         }
      }
      
      public function changeSignBar(param1:int, param2:int) : void
      {
         var _loc8_:Image = null;
         var _loc3_:Image = null;
         var _loc6_:* = null;
         if(!lineSignList)
         {
            return;
         }
         if(param2 == 0)
         {
            return;
         }
         _loc8_ = lineSignList[param1];
         var _loc4_:int = _loc8_.x - 1;
         var _loc5_:int = _loc8_.y - 3;
         var _loc7_:GameMapLayer = GameMapLayer.gl;
         var _loc9_:* = DisplayTools.getAttrs("lineSign" + param2 + "0");
         _loc3_ = DisplayTools.newMc("lineSign" + param2 + "0",_loc4_,_loc5_);
         m_sprFg.addChild(_loc3_);
         _loc9_ = DisplayTools.getAttrs("LINESIGN" + param2);
         _loc9_.x = _loc4_ - 1;
         _loc9_.y = _loc5_ - 1;
         _loc9_.par = m_sprFg;
         DisplayTools.addEffectOne(_loc9_);
      }
      
      public function refreshRate(param1:int = 0, param2:int = 0) : void
      {
         var _loc3_:int = 0;
         if(!m_rateSpr)
         {
            m_rateSpr = new Sprite();
            m_rateSpr.x = param1;
            m_rateSpr.y = param2;
            m_rateSpr.touchable = false;
         }
         m_rateSpr.removeChildren();
         _loc3_ = int(GameMapLayer.FPS_LIST[GameMapLayer.fpsLv]);
         var _loc4_:Image = DisplayTools.newImg("combatRatex");
         var _loc5_:Image = DisplayTools.newImg("combatRate" + _loc3_);
         _loc4_.y = 5;
         _loc5_.x = (_loc4_.width + _loc5_.width) * 0.4;
         m_rateSpr.addChild(_loc4_);
         m_rateSpr.addChild(_loc5_);
         m_rateSpr.pivotX = m_rateSpr.width / 2;
         m_rateSpr.flatten();
         m_sprFg.addChild(m_rateSpr);
         if(!btnRateReduce || !btnRateIncrease)
         {
            return;
         }
         if(GameMapLayer.fpsLv == GameMapLayer.FPS_LIST.length - 1)
         {
            btnRateIncrease.alpha = 0.3;
         }
         else
         {
            btnRateIncrease.alpha = 1;
            if(GameMapLayer.canFpsLv == GameMapLayer.fpsLv)
            {
               btnRateIncrease.enabled = false;
            }
            else
            {
               btnRateIncrease.enabled = true;
            }
         }
         if(GameMapLayer.fpsLv == 0)
         {
            btnRateReduce.alpha = 0.3;
         }
         else
         {
            btnRateReduce.alpha = 1;
         }
      }
      
      public function addButton() : void
      {
         var _loc6_:LOL_Button = null;
         var _loc5_:* = undefined;
         var _loc4_:Array = null;
         var _loc2_:int = GameMapConfig.FIGHT_WIDTH - 140;
         var _loc3_:int = GameMapConfig.FIGHT_HEIGHT - 70;
         btnRateReduce = new LOL_Button("","combatRateAdd0000",true,false);
         btnRateReduce.style(GlobalConfig.FONT_0,25,1118481);
         btnRateReduce.x = _loc2_;
         btnRateReduce.y = _loc3_;
         btnRateReduce.scaleX = -btnRateReduce.scaleX;
         btnRateReduce.addEventListener("triggered",onRateReduce);
         m_sprFg.addChild(btnRateReduce);
         btnRateIncrease = new LOL_Button("","combatRateAdd0000",true,false);
         btnRateIncrease.style(GlobalConfig.FONT_0,25,1118481);
         btnRateIncrease.x = _loc2_ + 50;
         btnRateIncrease.y = _loc3_;
         btnRateIncrease.addEventListener("triggered",onRateIncrease);
         m_sprFg.addChild(btnRateIncrease);
         refreshRate(_loc2_ + 40,_loc3_ + 33);
         var _loc1_:int = 50;
         if(!GlobalData.$isForceGuide)
         {
            trace(GameMap.isLoad,GameMap.isLoadFile);
            if(GameMap.isLoad || GameMap.isLoadFile)
            {
               _loc6_ = new LOL_Button(GlobalLanguageStr.getLanguageStr(31005),"UI_btn_enterGame_0_0000",true,false);
               _loc6_.style(GlobalConfig.FONT_0,25,1118481);
               GlobalFunction.setPivot(_loc6_);
               _loc6_.scale = 1.2;
               _loc6_.x = GameMapConfig.FIGHT_WIDTH / 2;
               _loc6_.y = _loc3_ + 25;
               _loc6_.alpha = 0.7;
               _loc6_.addEventListener("triggered",rePanel);
               m_sprFg.addChild(_loc6_);
            }
            else if(GlobalFunction.checkIOSvip())
            {
               if(GlobalData.$isPVE && GlobalData.$isNoFriendToPVE)
               {
                  _loc5_ = GlobalData.$userData;
                  _loc4_ = GlobalData.$mConfig_simple.start_lv;
                  if(_loc5_.lv >= _loc4_[13])
                  {
                     if(GameMap.currentMap)
                     {
                        if(int(GlobalFunction.getCombatStarById(GameMap.currentMap.gameMapData.id)) == 3)
                        {
                           btnToAuto = new LOL_Button(GlobalLanguageStr.getLanguageStr(32002),"UI_btn_enterGame_0_0000",true,false);
                           btnToAuto.style(GlobalConfig.FONT_0,25,1118481);
                           GlobalFunction.setPivot(btnToAuto);
                           btnToAuto.scale = 1.2;
                           btnToAuto.x = GameMapConfig.FIGHT_WIDTH / 2;
                           btnToAuto.y = _loc3_ + 25;
                           refreshAuto();
                           btnToAuto.addEventListener("triggered",toAuto);
                           btnToAuto.visible = false;
                           m_sprFg.addChild(btnToAuto);
                        }
                     }
                  }
               }
            }
         }
         if(!MainConfig.$isTest)
         {
            return;
         }
         if(MainConfig.$isFightTest)
         {
            _loc6_ = new LOL_Button("更换","UI_btn_enterGame_0_0000",true,false);
            _loc6_.style(GlobalConfig.FONT_0,25,1118481);
            _loc6_.width = 80;
            _loc6_.height = _loc1_;
            _loc6_.y = -0;
            _loc6_.addEventListener("triggered",rePanel);
            m_sprFg.addChild(_loc6_);
            _loc6_ = new LOL_Button("重播","UI_btn_enterGame_0_0000",true,false);
            _loc6_.style(GlobalConfig.FONT_0,25,1118481);
            _loc6_.width = 80;
            _loc6_.height = _loc1_;
            _loc6_.x = 80;
            _loc6_.y = -0;
            _loc6_.addEventListener("triggered",rePlay);
            m_sprFg.addChild(_loc6_);
            return;
         }
         _loc6_ = new LOL_Button("读档","UI_btn_enterGame_0_0000",true,false);
         _loc6_.style(GlobalConfig.FONT_0,25,1118481);
         _loc6_.width = 80;
         _loc6_.height = _loc1_;
         _loc6_.y = -0;
         _loc6_.addEventListener("triggered",getErrlog);
         m_sprFg.addChild(_loc6_);
         _loc6_ = new LOL_Button("重播","UI_btn_enterGame_0_0000",true,false);
         _loc6_.style(GlobalConfig.FONT_0,25,1118481);
         _loc6_.width = 80;
         _loc6_.height = _loc1_;
         _loc6_.x = 80;
         _loc6_.y = -0;
         _loc6_.addEventListener("triggered",rePlay);
         m_sprFg.addChild(_loc6_);
         _loc6_ = new LOL_Button("返回","UI_btn_enterGame_0_0000",true,false);
         _loc6_.style(GlobalConfig.FONT_0,25,1118481);
         _loc6_.width = 80;
         _loc6_.height = _loc1_;
         _loc6_.x = 160;
         _loc6_.y = -0;
         _loc6_.addEventListener("triggered",rePanel);
         m_sprFg.addChild(_loc6_);
         _loc6_ = new LOL_Button("暂停/报错","UI_btn_enterGame_0_0000",true,false);
         _loc6_.style(GlobalConfig.FONT_0,25,1118481);
         _loc6_.width = 100;
         _loc6_.height = _loc1_;
         _loc6_.x = 420;
         _loc6_.y = -0;
         _loc6_.addEventListener("triggered",sendErrorLog);
         m_sprFg.addChild(_loc6_);
      }
      
      protected function sendErrorLog(param1:Event) : void
      {
         if(!GameMap.currentMap.isFight)
         {
            GameMap.currentMap.sendErrorLog(true);
         }
         else
         {
            GameMapLayer.isPlay = !GameMapLayer.isPlay;
         }
      }
      
      protected function getErrlog(param1:Event) : void
      {
         GameMapTools.sendGetCombatErrlog();
      }
      
      protected function rePanel(param1:Event) : void
      {
         var _loc3_:Touch = null;
         if(param1 is TouchEvent)
         {
            if(!canReturn)
            {
               return;
            }
            _loc3_ = (param1 as TouchEvent).getTouch(m_black,"began");
            if(!_loc3_)
            {
               return;
            }
         }
         var _loc2_:GameMap = GameMap.currentMap;
         if(GameMap.currentMap && !GameMap.currentMap.isClear)
         {
            if(MainConfig.$isFightTest)
            {
               GameMap.currentMap.isClear = true;
               GameMap.currentMap.clear(false);
               new GameMap("random");
               return;
            }
            if(GameMap.currentMap.re == null)
            {
               GameMap.currentMap.isClear = true;
               GameMapLayer.gl.delayCall(clearMap,0.5);
               GuideMaster.getOnlyExample().addBlack(GuideMaster.getOnlyExample().nextGuide);
               return;
            }
            if(GlobalData.$currentGuide)
            {
               GuideMaster.getOnlyExample().resumeUI();
            }
         }
         returnPanel();
      }
      
      protected function returnPanel() : void
      {
         if(GameMap.currentMap && GameMap.currentMap.settlementPending)
         {
            GameMap.currentMap.retryBattleFinish();
            return;
         }
         if(GameMap.isLoadFile && (GameMap.lastCid == "pvp" || GameMap.lastCid == "extreme"))
         {
            GlobalData.$mEventDispatcher.dispatchEventWith("stage_ui");
         }
         else
         {
            if(GlobalData.$mGameClassObject && GlobalData.$mGameClassObject.mLayoutUICenter)
            {
               GlobalData.$mGameClassObject.mLayoutUICenter.mCurrPanel = "";
            }
            GlobalData.$mEventDispatcher.dispatchEventWith("stage_ui",false,GameMap.currentMap.re);
         }
      }
      
      protected function clearMap() : void
      {
         if(GameMap.currentMap && GameMap.currentMap.isClear)
         {
            GameMap.currentMap.clear();
            GameMapLayer.gl.mapStage.removeFromParent();
         }
      }
      
      protected function refreshAuto() : void
      {
         if(!btnToAuto)
         {
            return;
         }
         if(GameMapLayer.isAuto)
         {
            btnToAuto.text = GlobalLanguageStr.getLanguageStr(32005);
         }
         else
         {
            btnToAuto.text = GlobalLanguageStr.getLanguageStr(32002);
         }
         btnToAuto.shadowFilter();
         if(GameMapLayer.isAuto)
         {
            btnToAuto.showGlow();
         }
         else
         {
            btnToAuto.clearGlow();
         }
      }
      
      protected function toAuto(param1:Event) : void
      {
         if(!btnToAuto)
         {
            return;
         }
         var _loc2_:Object = GlobalFunction.getVipObj();
         if(_loc2_ && _loc2_.battle_speed == 1)
         {
            GameMapLayer.setAuto(!GameMapLayer.isAuto);
            refreshAuto();
         }
         else
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90247),false,"A_1006_5");
         }
      }
      
      protected function rePlay(param1:Event) : void
      {
         if(GameMapLayer.isAuto)
         {
            GameMapLayer.setAuto(false);
            return;
         }
         var _loc2_:GameMap = GameMap.currentMap;
         var _loc3_:LOL_Button = param1.currentTarget as LOL_Button;
         if(_loc2_)
         {
            _loc2_.replay();
         }
         _loc3_.alpha = 1;
         GlobalData.$mStarling.juggler.tween(_loc3_,1,{"alpha":0});
      }
      
      protected function onRateReduce(param1:Event) : void
      {
         if(GameMapLayer.fpsLv > 0)
         {
            GameMapLayer.fpsLv--;
            refreshRate();
         }
      }
      
      protected function onRateIncrease(param1:Event) : void
      {
         var _loc3_:String = null;
         var _loc2_:String = null;
         if(GameMapLayer.canFpsLv > GameMapLayer.fpsLv)
         {
            GameMapLayer.fpsLv++;
            refreshRate();
         }
         else
         {
            if(GameMapLayer.fpsLv >= GameMapLayer.FPS_LIST.length - 1)
            {
               return;
            }
            if(!GlobalFunction.checkIOSvip())
            {
               return;
            }
            _loc3_ = GlobalLanguageStr.getLanguageStr(31002,GlobalData.$mConfig_simple.start_lv[4]);
            _loc3_ += "\n" + GlobalLanguageStr.getLanguageStr(31003);
            _loc3_ = Tools.formatLineX(_loc3_,GlobalTextStyle.COLOR_W_W_Y_G);
            _loc2_ = GlobalData.$mConfig_simple.show_id[15];
            GlobalFunction.popAlert("",_loc3_,{"aid":_loc2_});
         }
      }
      
      public function addBg() : void
      {
         var _loc1_:Image = null;
         _loc1_ = new Image(GlobalData.$assetManager.getTexture("combatTop0000"));
         _loc1_.touchable = false;
         _loc1_.width = GameMapConfig.FIGHT_WIDTH;
         _loc1_.scaleY = 2;
         _loc1_.y = -0;
         m_sprFg.addChild(_loc1_);
         _loc1_ = new Image(GlobalData.$assetManager.getTexture("combatBottom0000"));
         _loc1_.touchable = false;
         _loc1_.width = GameMapConfig.FIGHT_WIDTH;
         _loc1_.pivotY = _loc1_.height;
         _loc1_.y = 45;
         m_sprFg.addChild(_loc1_);
         _loc1_ = new Image(GlobalData.$assetManager.getTexture("combatBottom0000"));
         _loc1_.touchable = false;
         _loc1_.width = GameMapConfig.FIGHT_WIDTH;
         _loc1_.pivotY = _loc1_.height;
         _loc1_.y = GameMapConfig.FIGHT_HEIGHT + 0;
         m_sprFg.addChild(_loc1_);
      }
      
      public function addBag() : void
      {
         if(m_bag == null)
         {
            m_bag = new Image(GlobalData.$assetManager.getTexture("combatBag0000"));
            m_bag.touchable = false;
            m_bag.pivotX = m_bag.width / 2;
            m_bag.pivotY = m_bag.height / 2;
            m_bag.x = m_bag.width / 2;
            m_bag.y = GameMapConfig.FIGHT_HEIGHT + 0 - m_bag.height / 2;
            m_sprFg.addChild(m_bag);
         }
      }
      
      public function addName() : void
      {
         var _loc3_:String = GameMap.currentMap.getName();
         var _loc2_:Array = GameMap.isLoadFile ? GlobalTextStyle.COLOR_B_P_B_R : GlobalTextStyle.COLOR_W_Y_Y_G;
         var _loc4_:String = HtmlTextFormat.multiColorText(_loc3_,_loc2_,25);
         var _loc1_:String = HtmlTextFormat.multiColorText(_loc3_,GlobalTextStyle.COLOR_B_B_B_B,25);
         if(!m_mapName)
         {
            m_mapName = new HtmlTextField(GameMapConfig.SCREEN_WIDTH,30,_loc4_,true,GlobalConfig.FONT_0);
            m_mapName.touchable = false;
            m_mapName.pivotX = m_mapName.width / 2;
            m_mapName.pivotY = m_mapName.height / 2;
            m_mapName.y = 20;
            m_mapName.x = GameMapConfig.FIGHT_WIDTH / 2;
            m_mapName2 = new HtmlTextField(GameMapConfig.SCREEN_WIDTH,30,_loc1_,true,GlobalConfig.FONT_0);
            m_mapName2.touchable = false;
            m_mapName2.pivotX = m_mapName2.width / 2;
            m_mapName2.pivotY = m_mapName2.height / 2;
            m_mapName2.y = m_mapName.y + 3;
            m_mapName2.alpha = 0.6;
            m_mapName2.x = GameMapConfig.FIGHT_WIDTH / 2;
         }
         else
         {
            m_mapName.text = _loc4_;
            m_mapName2.text = _loc1_;
         }
         m_sprFg.addChild(m_mapName2);
         m_sprFg.addChild(m_mapName);
      }
      
      public function addWinSign(param1:String = "", param2:int = 0) : void
      {
         var _loc3_:TextField = null;
         var _loc6_:int = 0;
         var _loc5_:DisplayObject = null;
         var _loc11_:* = null;
         var _loc9_:Tween = null;
         var _loc10_:Quad = null;
         var _loc12_:TextField = null;
         var _loc13_:Number = NaN;
         var _loc4_:GameMapLayer = GameMapLayer.gl;
         var _loc8_:int = 60;
         var _loc7_:int = GameMapConfig.FIGHT_WIDTH - 230;
         if(!m_winBg)
         {
            m_winBg = new Sprite();
            m_winBg.touchable = false;
            param1 = GlobalLanguageStr.getLanguageStr(30041) + param1;
            _loc3_ = new TextField(MainConfig.$isEA ? 300 : 240,MainConfig.$isEA ? 45 : 30,param1,GlobalConfig.FONT_0,20,0,true);
            _loc3_.hAlign = "left";
            _loc3_.alpha = 0.6;
            _loc3_.pivotY = _loc3_.height / 2;
            _loc3_.x = MainConfig.$isEA ? _loc7_ - 30 : _loc7_;
            _loc3_.y = MainConfig.$isEA ? _loc8_ + 3 + 1 : _loc8_ + 3;
            m_winBg.addChild(_loc3_);
            _loc3_ = new TextField(MainConfig.$isEA ? 300 : 240,MainConfig.$isEA ? 45 : 30,param1,GlobalConfig.FONT_0,20,16777215,true);
            _loc3_.hAlign = "left";
            _loc3_.pivotY = _loc3_.height / 2;
            _loc3_.x = MainConfig.$isEA ? _loc7_ - 30 : _loc7_;
            _loc3_.y = MainConfig.$isEA ? _loc8_ + 1 : _loc8_;
            m_winBg.addChild(_loc3_);
         }
         while(_loc6_ < m_winBg.numChildren)
         {
            _loc5_ = m_winBg.getChildAt(_loc6_);
            if(!(_loc5_ is TextField))
            {
               m_winBg.removeChildAt(_loc6_);
            }
            _loc6_++;
         }
         m_sprFg.addChild(m_winBg);
         if(!m_black)
         {
            m_black = new Sprite();
         }
         if(param2 != 0)
         {
            m_black.addEventListener("touch",rePanel);
            m_black.removeChildren(0,-1,true);
            m_sprFg.addChildAt(m_black,0);
            _loc10_ = new Quad(GameMapConfig.FIGHT_WIDTH,GameMapConfig.FIGHT_HEIGHT,1118481);
            _loc10_.pivotY = _loc10_.height / 2 / 2;
            _loc10_.y = _loc10_.pivotY;
            _loc10_.alpha = 0.8;
            _loc10_.scaleY = 0;
            m_black.addChild(_loc10_);
            canReturn = false;
            _loc4_.delayCall(setCanReturn,2.5);
            _loc9_ = new Tween(_loc10_,0.5,"easeInOut");
            _loc9_.animate("scaleY",1);
            _loc4_.juggler.add(_loc9_);
            _loc4_.delayCall(addInfo,2);
            _loc13_ = 3;
            if(btnToAuto)
            {
               btnToAuto.removeFromParent(true);
            }
            if(param2 != 1)
            {
               GameMapLayer.setAuto(false);
            }
            if(GameMapLayer.isAuto)
            {
               _loc4_.delayCall(returnPanel,2);
            }
            if(GlobalData.$isBattleOfThePeak)
            {
               _loc7_ = GameMapConfig.SCREEN_WIDTH / 2;
               _loc8_ = GameMapConfig.SCREEN_HEIGHT / 2;
               _loc4_.delayCall(returnPanel,10);
               _loc12_ = GlobalFunction.getNextTextField(GlobalLanguageStr.getLanguageStr(98014));
               _loc12_.x = _loc7_;
               _loc12_.y = _loc8_ + 50;
               _loc4_.delayCall(m_sprFg.addChild,_loc13_,_loc12_);
            }
            else
            {
               _loc7_ = GameMapConfig.SCREEN_WIDTH / 2;
               _loc8_ = GameMapConfig.SCREEN_HEIGHT / 2;
               _loc12_ = GlobalFunction.getNextTextField();
               _loc12_.x = _loc7_;
               _loc12_.y = _loc8_ + 50;
               _loc4_.delayCall(m_sprFg.addChild,_loc13_,_loc12_);
            }
         }
      }
      
      public function setCanReturn() : void
      {
         canReturn = true;
      }
      
      public function addInfo() : void
      {
         var _loc1_:Tween = null;
         if(m_tips)
         {
            m_tips.removeChildren(0,-1,true);
         }
         else
         {
            m_tips = new Sprite();
            m_sprFg.addChild(m_tips);
         }
         var _loc4_:GameMapLayer = GameMapLayer.gl;
         _loc4_.delayCall(addInfo,10);
         var _loc5_:String = "";
         var tipScans:int = 0;
         while(_loc5_ == "" && tipScans < HELP_TIPS_MAX - HELP_TIPS_MIN + 1)
         {
            tipsIndex = Math.max(Math.min(tipsIndex,HELP_TIPS_MAX),HELP_TIPS_MIN);
            _loc5_ = GlobalLanguageStr.getLanguageStr(tipsIndex);
            tipsIndex = tipsIndex + 1;
            if(tipsIndex > HELP_TIPS_MAX)
            {
               tipsIndex = HELP_TIPS_MIN;
            }
            tipScans++;
         }
         if(_loc5_ == "")
         {
            _loc5_ = "战斗结束后，点击屏幕返回关卡。";
            tipsIndex = HELP_TIPS_MIN;
         }
         _loc5_ = HtmlTextFormat.multiColorText(_loc5_,GlobalTextStyle.COLOR_B_P_B_R,15,-1,GlobalConfig.FONT_1);
         GlobalLocalStore.setHelpTips(tipsIndex);
         m9x9_bg = GlobalFunction.createScale9Image("UI_bg_9slice_5_0000",500,130,new Rectangle(30,20,50,30));
         GlobalFunction.setPivot(m9x9_bg);
         m9x9_bg.touchable = false;
         m9x9_bg.x = GameMapConfig.SCREEN_WIDTH / 2;
         m9x9_bg.y = GameMapConfig.SCREEN_HEIGHT * 0.6 + 200;
         m_tips.addChild(m9x9_bg);
         var _loc2_:Number = m9x9_bg.scaleX;
         var _loc3_:Number = m9x9_bg.scaleY;
         m_tipsTf = new HtmlTextField(m9x9_bg.width * 0.85,m9x9_bg.height * 0.8,_loc5_,true,GlobalConfig.FONT_0,25);
         m_tipsTf.touchable = false;
         m_tipsTf.pivotX = m_tipsTf.width / 2;
         m_tipsTf.pivotY = m_tipsTf.height / 2;
         m_tipsTf.hAlign = "left";
         m_tipsTf.vAlign = "center";
         m_tipsTf.x = GameMapConfig.SCREEN_WIDTH / 2;
         m_tipsTf.y = m9x9_bg.y - 4;
         m_tips.addChild(m_tipsTf);
         m9x9_bg.scaleX = _loc2_ / 2;
         m9x9_bg.scaleY = _loc3_ / 2;
         _loc1_ = new Tween(m9x9_bg,0.3,"easeOutBack");
         _loc1_.animate("scaleX",_loc2_);
         _loc1_.animate("scaleY",_loc3_);
         _loc4_.addTween(_loc1_);
      }
      
      public function addRound() : void
      {
         if(m_roundTF) return;
         var text:String = (MainConfig.$isEnglish ? "Round " : "回合 ") + "0 / " + GameMap.ROUND_MAX;
         m_roundTF2 = new TextField(194,34,text,GlobalConfig.FONT_0,22,0,true);
         m_roundTF2.x = 15;
         m_roundTF2.y = 46;
         m_roundTF2.hAlign = "left";
         m_roundTF2.autoScale = true;
         m_roundTF2.touchable = false;
         m_roundTF2.alpha = SHADOW_ALPHA;
         m_sprFg.addChild(m_roundTF2);
         m_roundTF = new TextField(194,34,text,GlobalConfig.FONT_0,22,16777215,true);
         m_roundTF.x = 14;
         m_roundTF.y = 44;
         m_roundTF.hAlign = "left";
         m_roundTF.autoScale = true;
         m_roundTF.touchable = false;
         m_sprFg.addChild(m_roundTF);
      }
      
      public function refreashRound(param1:int) : void
      {
         if(!m_roundTF) addRound();
         var text:String = (MainConfig.$isEnglish ? "Round " : "回合 ") + param1 + " / " + GameMap.ROUND_MAX;
         m_roundTF.text = text;
         m_roundTF2.text = text;
         m_roundTF.color = param1 >= GameMap.ROUND_MAX ? 16711680 : GameMap.ROUND_MAX - param1 < 5 ? 16776960 : 16777215;
         var layer:GameMapLayer = GameMapLayer.gl;
         if(layer)
         {
            layer.juggler.removeTweens(m_roundTF);
            m_roundTF.alpha = 0.65;
            var tween:Tween = new Tween(m_roundTF,0.18,"easeOut");
            tween.fadeTo(1);
            layer.addTween(tween);
         }
      }
      
      override public function clear() : void
      {
         if(m_roundTF && GameMapLayer.gl) GameMapLayer.gl.juggler.removeTweens(m_roundTF);
         super.clear();
         m_sprFg = null;
         m_roundTF = null;
         m_roundTF2 = null;
         m_winBg = null;
         m_bag = null;
         if(m_tips)
         {
            m_tips.removeChildren(0,-1,true);
         }
         if(m9x9_bg)
         {
            m9x9_bg.removeFromParent(true);
         }
         m_tips = null;
         m9x9_bg = null;
         m_tipsTf = null;
         m_mapName = null;
         m_mapName2 = null;
         btnRateReduce = null;
         btnRateIncrease = null;
         lineSignList = null;
      }
   }
}

