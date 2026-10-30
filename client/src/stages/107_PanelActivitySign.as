package com.meng52.game.ui.panel
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.map.GameMapTools;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.element.LOL_IconText;
   import com.meng52.game.ui.element.LOL_ProgressBar;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.element.LOL_TimeStatus;
   import com.meng52.game.ui.screen.PanelBase;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.net.SendAndSelect;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import flash.events.TimerEvent;
   import flash.utils.Timer;
   import starling.animation.Tween;
   import starling.core.Starling;
   import starling.display.DisplayObject;
   import starling.display.Image;
   import starling.display.MovieClip;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.filters.ColorMatrixFilter;
   import starling.text.TextField;
   
   public class PanelActivitySign extends PanelBase
   {
      
      private static var $mCfg_sort:Array;
      
      private static var _mcArr:Array;
      
      private var mBtn_sign:LOL_Scale9Button;
      
      private var mBtn_reward:LOL_Scale9Button;
      
      private var mTxt_times:TextField;
      
      private var mTxt_info:TextField;
      
      private var mTimer_sign:Timer;
      
      private var mPlant:Image;
      
      private var mLight:Image;
      
      private var mBar:LOL_ProgressBar;
      
      private var _info:TextFieldHtmlRenderer;
      
      private const GETAWARD_BTN:String = "getaward_btn";
      
      private const ACTIVITYSIGN_BTN:String = "activitysign_btn";
      
      private var _arr:Array;
      
      private var _tween:Tween;
      
      private var _bubbleSpr:Sprite;
      
      private var _planeSpr:Sprite;
      
      private var _bg:Image;
      
      private var _jug:JugMc;
      
      private var mTimerT:LOL_TimeStatus;
      
      private var mIconT:LOL_IconText;
      
      private var liftBox:Image;
      
      private var cmf:ColorMatrixFilter;
      
      public var _change:Sprite;
      
      private const MC_NUM:int = 8;
      
      private const CONST_TIME:Number = 0.4;
      
      public function PanelActivitySign()
      {
         super();
      }
      
      public static function checkSignResult() : Object
      {
         var _loc8_:Number = NaN;
         var _loc1_:Number = NaN;
         var _loc7_:Boolean = false;
         var _loc3_:Boolean = false;
         var _loc2_:Object = GlobalData.$mConfig_ploy_system_simple.sign_in;
         var _loc4_:Object = GlobalData.$userData.attrs.sign_in;
         var _loc6_:int = int(GlobalData.$userData.attrs.sign_in.k);
         var _loc5_:int = int(GlobalData.$userData.attrs.sign_in.n);
         if(_loc5_ < _loc2_[_loc6_].num)
         {
            _loc8_ = GlobalData.$userData.attrs.sign_in.t == null ? 0 : (GlobalData.$userData.attrs.sign_in.t as Date).time;
            _loc1_ = SendAndSelect.$systemTimer_nowSecond * 1000;
            _loc7_ = Tools.checkIsSameDay(_loc8_,_loc1_);
            _loc3_ = Tools.checkIsPrevDay(_loc1_,_loc8_);
            if(_loc7_)
            {
               _loc5_ = _loc5_;
            }
            else if(_loc3_)
            {
               _loc5_ = _loc5_;
            }
            else
            {
               _loc5_ = 0;
            }
         }
         var _loc9_:String = _loc2_[_loc6_].mcid + (_loc5_ + 1).toString();
         return {
            "max":_loc2_[_loc6_].num,
            "curr":_loc5_,
            "can":!_loc7_,
            "mcID":_loc9_
         };
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(mBtn_sign)
         {
            mBtn_sign.removeFromParent(true);
         }
         if(mTxt_times)
         {
            mTxt_times.removeFromParent(true);
         }
         if(mTxt_info)
         {
            mTxt_info.removeFromParent(true);
         }
         if(mPlant)
         {
            mPlant.dispose();
            mPlant.removeFromParent(true);
         }
         if(mBar)
         {
            StarlingTools.removeChildrenClear(mBar);
         }
         if(_planeSpr)
         {
            StarlingTools.removeChildrenClear(_planeSpr);
         }
         _planeSpr = null;
         if(_bubbleSpr)
         {
            StarlingTools.removeChildrenClear(_bubbleSpr);
         }
         if(_jug)
         {
            StarlingTools.removeChildrenClear(_jug);
         }
         if(mTimerT)
         {
            mTimerT.removeFromParent(true);
         }
         if(mIconT)
         {
            mIconT.removeFromParent(true);
         }
         if(liftBox)
         {
            liftBox.removeFromParent(true);
         }
         mIconT = null;
         _jug = null;
         _bubbleSpr = null;
         mBar = null;
         delTimer();
         dispose();
         clear();
         mBtn_sign = null;
         mTxt_times = null;
         mTxt_info = null;
         mPlant = null;
         $mCfg_sort = null;
         mTimerT = null;
         liftBox = null;
         GlobalFunction.delTextureByBD("pic_sign_bg_0");
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         removeEventListener("addedToStage",initializeHandler);
         setUIs();
      }
      
      private function setUIs() : void
      {
         _bg = GlobalFunction.createImage("pic_sign_bg_0",true);
         _bg.y = GlobalData.$center_height_curr - 121 - _bg.height + 10;
         addChild(_bg);
         var _loc2_:Object = checkSignResult();
         _planeSpr = new Sprite();
         this.addChild(_planeSpr);
         _bubbleSpr = new Sprite();
         this.addChild(_bubbleSpr);
         if(_loc2_.curr >= _loc2_.max)
         {
            mLight = GlobalFunction.createImage("UI_card_effect",true);
            mLight.touchable = false;
            mLight.pivotX = mLight.width * 0.5;
            mLight.pivotY = mLight.height * 0.5;
            mLight.scaleX = mLight.scaleY = 2;
            mLight.x = _bg.width * 0.5;
            mLight.y = _bg.y + _bg.height - 340;
            _planeSpr.addChild(mLight);
         }
         mPlant = getImgFromId(_loc2_.mcID);
         mPlant.x = _bg.width * 0.5 + 10;
         mPlant.y = _bg.y + _bg.height - 270;
         mPlant.touchable = true;
         mPlant.addEventListener("touch",onTouch);
         _planeSpr.addChild(mPlant);
         $mCfg_sort = [];
         var _loc1_:Object = GlobalData.$mConfig_ploy_system_simple.sign_in;
         for(var _loc6_:Object in _loc1_)
         {
            $mCfg_sort.push(int(_loc6_.toString()));
         }
         $mCfg_sort.sort();
         mBtn_sign = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90532),150,70,"UI_btn_normalFun_0000");
         mBtn_sign.name = "activitysign_btn";
         mBtn_sign.showGlow();
         mBtn_sign.x = (GlobalData.$mStageWidth - mBtn_sign.width) * 0.5;
         mBtn_sign.y = mPlant.y + 130;
         mBtn_sign.addEventListener("triggered",onTRIGGERED_sign);
         addChild(mBtn_sign);
         mBtn_reward = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90539),150,70,"UI_btn_normalFun_0000");
         mBtn_reward.name = "getaward_btn";
         mBtn_reward.showGlow();
         mBtn_reward.x = mBtn_sign.x;
         mBtn_reward.y = mBtn_sign.y;
         mBtn_reward.addEventListener("triggered",onTRIGGERED_sign);
         mBtn_reward.visible = _loc2_.curr >= _loc2_.max;
         addChild(mBtn_reward);
         var _loc4_:int = int(_loc2_.curr);
         mBar = new LOL_ProgressBar("UI_sign_exp_0_0000","UI_sign_exp_1_0000","UI_sign_jug_1_0000",0.3);
         mBar.x = (GlobalData.$mStageWidth - mBar.barWidth) * 0.5;
         mBar.y = mPlant.y + 50;
         mBar.iniSetBar(_loc2_.curr,_loc2_.max);
         _planeSpr.addChild(mBar);
         cmf = new ColorMatrixFilter();
         cmf.adjustSaturation(-1);
         liftBox = GlobalFunction.createImage("UI_roulette_award_1_0000");
         liftBox.scaleX = liftBox.scaleY = 0.8;
         liftBox.x = mBar.x + 223;
         liftBox.y = mBar.y - 10 + 3;
         if(_loc2_.curr < _loc2_.max)
         {
            liftBox.filter = cmf;
         }
         _planeSpr.addChild(liftBox);
         changeInfo();
         mBtn_sign.enabled = _loc2_.can;
         if(!_loc2_.can)
         {
            mTimer_sign = new Timer(10000);
            mTimer_sign.addEventListener("timer",onTIMER_sign);
            mTimer_sign.start();
         }
         _tween = new Tween(mPlant,1.3,"easeInElastic");
         _tween.animate("scaleX",0.9);
         _tween.animate("scaleY",1.1);
         _tween.repeatCount = 0;
         _tween.reverse = true;
         Starling.juggler.add(_tween);
         var _loc5_:* = DisplayTools.getAttrs("SIGN");
         _loc5_.x = mPlant.x + 10;
         _loc5_.y = mPlant.y + 30;
         _loc5_.par = _bubbleSpr;
         var _loc3_:DisplayObject = DisplayTools.addEffectOne(_loc5_);
      }
      
      private function onTouch(param1:TouchEvent) : void
      {
         var _loc2_:Object = null;
         var _loc3_:Touch = param1.getTouch(mPlant,"ended");
         if(_loc3_)
         {
            _loc2_ = checkSignResult();
            if(_loc2_.can && _loc2_.curr < _loc2_.max)
            {
               LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getStr(90542));
            }
            else if(!_loc2_.can && _loc2_.curr < _loc2_.max)
            {
               LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getStr(90543));
            }
            else if(_loc2_.can && _loc2_.curr >= _loc2_.max)
            {
               LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getStr(90544));
            }
         }
      }
      
      private function changeInfo() : void
      {
         var _loc1_:Object = checkSignResult();
         var _loc3_:Boolean = _loc1_.max - _loc1_.curr <= 0;
         var _loc2_:String = _loc3_ ? GlobalLanguageStr.getLanguageStr(90540) : GlobalLanguageStr.getLanguageStr(90536,_loc1_.max - _loc1_.curr);
         if(_loc3_)
         {
            if(mTimerT)
            {
               mTimerT.removeFromParent(true);
               mTimerT = null;
            }
            else if(mIconT)
            {
               mIconT.removeFromParent(true);
               mIconT = null;
            }
            mIconT = new LOL_IconText(_loc2_);
            mIconT.bgWidth = 250;
            mIconT.y = 140;
            addChild(mIconT);
         }
         else
         {
            if(mIconT)
            {
               mIconT.removeFromParent(true);
               mIconT = null;
            }
            else if(mTimerT)
            {
               mTimerT.removeFromParent(true);
               mTimerT = null;
            }
            mTimerT = new LOL_TimeStatus("panelsign");
            mTimerT.refresh(0,_loc2_);
            mTimerT.x = 20;
            mTimerT.y = 140;
            addChild(mTimerT);
         }
      }
      
      public function tempFun(param1:Event) : void
      {
         var e:Event = param1;
         var _c:* = function():void
         {
            _change = plantBreed();
            _change.x = _bg.width * 0.5 + 10;
            _change.y = _bg.y + _bg.height - 270;
            _planeSpr.addChild(_change);
         };
         GlobalData.$mGameClassObject.touchable = false;
         Starling.juggler.remove(_tween);
         _jug = new JugMc();
         _jug.y = _bg.y + _bg.height - 550;
         _bubbleSpr.addChild(_jug);
         _jug.start();
         if(_change != null)
         {
            StarlingTools.removeChildrenClear(_change);
            _change = null;
         }
         mPlant.scaleX = mPlant.scaleY = 1;
         Starling.juggler.delayCall(_c,1.2);
      }
      
      private function getImgFromId(param1:String) : Image
      {
         var _loc2_:Avatar = new Avatar(param1);
         var _loc3_:Image = GameMapTools.newAvatarImg(_loc2_.resId);
         _loc3_.pivotX = _loc3_.width * 0.5;
         _loc3_.pivotY = _loc3_.height * 0.8;
         return _loc3_;
      }
      
      private function plantBreed() : Sprite
      {
         var plant2:Image;
         var _tw1:Tween;
         var completeRndMc:* = function(param1:Event):void
         {
            var _e:Event = param1;
            Starling.juggler.delayCall(visible,0,false,0.9);
            Starling.juggler.delayCall(visible,0.2,true);
            Starling.juggler.delayCall(visible,0.4,false,1);
            Starling.juggler.delayCall(visible,0.5,true);
            Starling.juggler.delayCall(visible,0.6,false,1);
            Starling.juggler.delayCall(visible,0.7,true);
            Starling.juggler.delayCall(visible,0.8,false,1.1,true);
            _tw1 = new Tween(plant2,1);
            _tw1.delay = 0.2;
            _tw1.scaleTo(1.2);
            _tw1.onComplete = function():void
            {
               _tw1 = new Tween(plant2,1,"easeOutElastic");
               _tw1.scaleTo(1);
               _tw1.onComplete = function():void
               {
                  if(mPlant)
                  {
                     mPlant.removeFromParent(true);
                     mPlant = null;
                  }
                  if(plant2)
                  {
                     plant2.removeFromParent(true);
                     plant2 = null;
                  }
                  var _loc1_:Object = checkSignResult();
                  mPlant = getImgFromId(_loc1_.mcID);
                  mPlant.x = _bg.width * 0.5 + 10;
                  mPlant.y = _bg.y + _bg.height - 270;
                  resetTween();
                  mPlant.touchable = true;
                  _planeSpr.addChild(mPlant);
                  mPlant.addEventListener("touch",onTouch);
                  LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getStr(90538));
               };
               Starling.juggler.add(_tw1);
            };
            Starling.juggler.add(_tw1);
         };
         var visible:* = function(param1:Boolean = false, param2:Number = 1, param3:Boolean = false):void
         {
            mPlant.visible = param1;
            plant2.visible = !param1;
            plant2.scaleX = plant2.scaleY = param2;
            if(param3)
            {
               plant2.filter = null;
            }
         };
         var sacle:* = function(param1:Number, param2:Number):void
         {
            _tw1 = new Tween(plant2,param1);
            _tw1.scaleTo(param2);
            Starling.juggler.add(_tw1);
         };
         var reSpr:Sprite = new Sprite();
         var _cfgResult:Object = checkSignResult();
         var filter:ColorMatrixFilter = new ColorMatrixFilter();
         filter.adjustBrightness(1);
         mPlant.filter = filter;
         plant2 = getImgFromId(_cfgResult.mcID);
         plant2.filter = filter;
         plant2.visible = false;
         reSpr.addChild(plant2);
         _tw1 = new Tween(mPlant,0.5);
         _tw1.onComplete = function():void
         {
            var _loc4_:String = "combatWin";
            SoundManager.getOnlyExample().playSound(_loc4_);
            var _loc1_:int = plant2.x;
            var _loc2_:int = plant2.y - 40;
            var _loc5_:Object = {
               "id":"e026",
               "x":_loc1_,
               "y":_loc2_,
               "sc":2
            };
            _loc5_.par = reSpr;
            var _loc3_:DisplayObject = DisplayTools.addEffectOne(_loc5_);
            completeRndMc(null);
         };
         Starling.juggler.add(_tw1);
         return reSpr;
      }
      
      private function resetTween() : void
      {
         GlobalData.$mGameClassObject.touchable = true;
         _tween = new Tween(mPlant,1.3,"easeInElastic");
         _tween.animate("scaleX",0.9);
         _tween.animate("scaleY",1.1);
         _tween.repeatCount = 0;
         _tween.reverse = true;
         Starling.juggler.add(_tween);
      }
      
      private function onENTER_FRAME(param1:Event) : void
      {
         var _loc3_:int = 0;
         var _loc2_:MovieClip = null;
         _loc3_ = 0;
         while(_loc3_ < _arr.length)
         {
            _loc2_ = _arr[_loc3_].mc;
            if(_loc2_.alpha >= 1 || _loc2_.alpha <= 0)
            {
               _arr[_loc3_].saph = -_arr[_loc3_].saph;
            }
            _arr[_loc3_].mc.y -= _arr[_loc3_].sy;
            _loc2_.alpha += _arr[_loc3_].saph;
            if(_arr[_loc3_].mc.y < _arr[_loc3_].yy)
            {
               _arr[_loc3_].mc.y = _arr[_loc3_].y;
            }
            _loc3_++;
         }
         if(mLight)
         {
            mLight.rotation += 0.005555555555555556 * 3.141592653589793;
         }
      }
      
      private function delTimer() : void
      {
         if(mTimer_sign)
         {
            mTimer_sign.stop();
            mTimer_sign.removeEventListener("timer",onTIMER_sign);
         }
         mTimer_sign = null;
      }
      
      private function onTIMER_sign(param1:TimerEvent) : void
      {
         updateSign();
      }
      
      private function onTRIGGERED_sign(param1:Event) : void
      {
         var _loc3_:String = null;
         var _loc2_:int = 0;
         var _loc5_:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         var _loc4_:String = _loc5_.name;
         if(_loc4_ == "activitysign_btn")
         {
            if(_loc5_.enabled)
            {
               SendServiceAMFFun.send_user_sign_in(re_sign_in);
            }
            else
            {
               _loc3_ = GlobalData.$mConfig_simple.show_id[12];
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90140),false,_loc3_);
            }
         }
         else if(_loc4_ == "getaward_btn")
         {
            GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
            _loc2_ = Tools.getElementNum(GlobalData.$userData.my_equips);
            if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
            {
               GlobalFunction.popAvatarLen();
               return;
            }
            if(_loc2_ >= GlobalData.$mConfig_simple.equip_config[0])
            {
               GlobalFunction.popEquipFull();
               return;
            }
            SendServiceAMFFun.send_user_sign_reward(re_sign_reward);
         }
      }
      
      private function re_sign_reward(param1:Object) : void
      {
         if(stage == null)
         {
            return;
         }
         var _loc4_:int = 0;
         var _loc2_:String = "drop";
         SoundManager.getOnlyExample().playSound(_loc2_);
         if(param1.data == null)
         {
            return;
         }
         var _loc3_:Object = param1.data;
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.avatars = _loc3_.avatars;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.my_equips = _loc3_.my_equips;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.avatar_soul = _loc3_.avatar_soul;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.equip_soul = _loc3_.equip_soul;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.gold = _loc3_.gold;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.coin = _loc3_.coin;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.score = _loc3_.score;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.medal = _loc3_.medal;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.mark = _loc3_.mark;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.sp = _loc3_.sp;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.dust = _loc3_.dust;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.box_key = _loc3_.box_key;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.culture_book = _loc3_.culture_book;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.dn_stone = _loc3_.dn_stone;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.exp = _loc3_.exp;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.lv = _loc3_.lv;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.energy_extra = _loc3_.attr_energy_extra;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.fragment_energy = _loc3_.fragment_energy;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.fragment_energy_extra = _loc3_.fragment_energy_extra;
         }
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateEn();
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.sign_in = _loc3_.sign_in;
         }
         GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
         if(_loc3_.gift_dict != null)
         {
            _loc4_ = Tools.getElementNum(_loc3_.gift_dict);
            if(_loc4_ > 0)
            {
               GlobalFunction.showReward2({"info":GlobalLanguageStr.getLanguageStr(90131)},_loc3_.gift_dict);
            }
            else
            {
               SoundManager.getOnlyExample().playSound("cure");
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90141),false,"A_1078_5");
            }
         }
         delTimer();
         updateSign();
         resetPlantUI();
         changeInfo();
         LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getStr(90131));
      }
      
      private function resetPlantUI() : void
      {
         if(mPlant)
         {
            mPlant.removeFromParent(true);
            mPlant = null;
         }
         var _loc1_:Object = checkSignResult();
         mPlant = getImgFromId(_loc1_.mcID);
         mPlant.x = _bg.width * 0.5 + 10;
         mPlant.y = _bg.y + _bg.height - 270;
         mPlant.touchable = true;
         mPlant.addEventListener("touch",onTouch);
         _planeSpr.addChild(mPlant);
         resetTween();
      }
      
      private function re_sign_in(param1:Object) : void
      {
         if(stage == null)
         {
            return;
         }
         var _loc4_:int = 0;
         var _loc2_:String = "E_9022";
         SoundManager.getOnlyExample().playSound(_loc2_);
         if(param1.data == null)
         {
            return;
         }
         var _loc3_:Object = param1.data;
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.avatars = _loc3_.avatars;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.my_equips = _loc3_.my_equips;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.gold = _loc3_.gold;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.score = _loc3_.score;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.medal = _loc3_.medal;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.mark = _loc3_.mark;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.coin = _loc3_.coin;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.energy_extra = _loc3_.attr_energy_extra;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.dn_stone = _loc3_.dn_stone;
         }
         if(_loc3_["avatar_soul"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.avatar_soul = _loc3_.avatar_soul;
            }
         }
         if(_loc3_["equip_soul"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.equip_soul = _loc3_.equip_soul;
            }
         }
         if(_loc3_["dust"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.dust = _loc3_.dust;
            }
         }
         if(_loc3_["box_key"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.box_key = _loc3_.box_key;
            }
         }
         if(_loc3_["culture_book"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.culture_book = _loc3_.culture_book;
            }
         }
         if(_loc3_["exp"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.exp = _loc3_.exp;
            }
         }
         if(_loc3_["lv"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.lv = _loc3_.lv;
            }
         }
         if(_loc3_["fragment_energy"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.fragment_energy = _loc3_.fragment_energy;
            }
         }
         if(_loc3_["fragment_energy_extra"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.fragment_energy_extra = _loc3_.fragment_energy_extra;
            }
         }
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateEn();
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.sign_in = _loc3_.sign_in;
         }
         GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
         if(_loc3_.gift_dict != null)
         {
            _loc4_ = Tools.getElementNum(_loc3_.gift_dict);
            if(_loc4_ <= 0)
            {
               SoundManager.getOnlyExample().playSound("cure");
            }
         }
         delTimer();
         updateSign();
         changeInfo();
         tempFun(null);
      }
      
      private function updateSign() : void
      {
         var _loc1_:Object = checkSignResult();
         if(_loc1_.curr >= _loc1_.max)
         {
            if(mLight == null)
            {
               mLight = GlobalFunction.createImage("UI_card_effect",true);
               mLight.touchable = false;
               mLight.pivotX = mLight.width * 0.5;
               mLight.pivotY = mLight.height * 0.5;
               mLight.scaleX = mLight.scaleY = 2;
               mLight.x = _bg.width * 0.5;
               mLight.y = _bg.y + _bg.height - 340;
               _planeSpr.addChildAt(mLight,0);
            }
            liftBox.filter = null;
            mBtn_reward.visible = true;
            mBtn_sign.visible = false;
            mBar.UpdateBar(Math.min(_loc1_.curr,_loc1_.max),_loc1_.max);
         }
         else
         {
            if(mLight)
            {
               mLight.removeFromParent(true);
               mLight = null;
            }
            liftBox.filter = cmf;
            mBtn_reward.visible = false;
            mBtn_sign.visible = true;
            if(mBtn_sign)
            {
               if(mBtn_sign.enabled != _loc1_.can)
               {
                  if(mBtn_sign)
                  {
                     mBtn_sign.enabled = _loc1_.can;
                  }
               }
            }
            if(mBar)
            {
               mBar.UpdateBar(_loc1_.curr,_loc1_.max);
            }
         }
      }
   }
}

import com.meng52.game.global.GlobalFunction;
import com.meng52.game.ui.effect.DisplayTools;
import com.meng52.utils.StarlingTools;
import starling.animation.Tween;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Sprite;

class JugMc extends Sprite
{
   
   private var _mcArr:Array;
   
   private var _jug:Sprite;
   
   private var _jugImg:Image;
   
   private var _waterSpr:Sprite;
   
   private const _num:int = 30;
   
   public function JugMc()
   {
      super();
      init();
   }
   
   private function init() : void
   {
   }
   
   private function createJug() : Sprite
   {
      var CONST_TIME:Number;
      var ANGLE_RAT:Number;
      var _attrs:*;
      var _dis:DisplayObject;
      var i:int;
      var speed:Number;
      var _tw:Tween;
      var _tw1:Tween;
      _waterSpr = new Sprite();
      var reSpr:Sprite = new Sprite();
      var radiusA:Number = 70;
      var radiusB:Number = 16;
      var centerX:Number = radiusA * 2;
      var centerY:Number = radiusB * 2;
      var angle:Number = 0;
      var CONST_X:Array = [centerX + radiusA,centerX,centerX - radiusA,centerX - radiusA * 2,centerX - radiusA,centerX,centerX + radiusA,centerX + radiusA * 1.5];
      var CONST_Y:Array = [centerY - radiusB * 1.4,centerY - radiusB * 2,centerY - radiusB * 1.4,centerY,centerY + radiusB * 1.4,centerY + radiusB * 2,centerY + radiusB * 1.4,centerY - radiusB * 5];
      _jugImg = GlobalFunction.createImage("UI_sign_jug_0000");
      _jugImg.pivotX = _jugImg.width * 0.6;
      _jugImg.pivotY = _jugImg.height * 0.6;
      _jugImg.x = centerX + radiusA * 2;
      _jugImg.y = centerY;
      _jugImg.rotation = -0.3141592653589793;
      _jugImg.alpha = 0;
      reSpr.addChild(_jugImg);
      _attrs = {
         "id":"p03",
         "xml":"px13",
         "ec":16763958,
         "ep":{
            "maxp":30,
            "exv":80,
            "tav":10
         }
      };
      _attrs.par = _waterSpr;
      _dis = DisplayTools.addEffectOne(_attrs);
      _waterSpr.visible = false;
      _waterSpr.pivotX = _waterSpr.width * 0.5;
      reSpr.addChild(_waterSpr);
      _waterSpr.x = 40;
      _waterSpr.y = _jugImg.y + 70;
      i = 0;
      while(i < 7)
      {
         if(i < 5)
         {
            speed = 0.2 * 0.7;
         }
         else
         {
            speed = 0.2;
         }
         _tw = new Tween(_jugImg,0.2);
         _tw.animate("x",CONST_X[i]);
         if(i == 1)
         {
            _tw.fadeTo(1);
         }
         if(i > 1 && i < 3)
         {
            _tw.animate("rotation",-3.141592653589793 * 0.2 * i);
         }
         _tw1 = new Tween(_jugImg,0.2);
         _tw1.animate("y",CONST_Y[i]);
         _tw.delay = _tw1.delay = (i - 1) * 0.2;
         Starling.juggler.add(_tw);
         Starling.juggler.add(_tw1);
         i = i + 1;
      }
      Starling.juggler.delayCall(function():void
      {
         _waterSpr.visible = true;
      },0.2 * 2);
      _tw1 = new Tween(_jugImg,0.2 * 3);
      _tw1.animate("x",CONST_X[7]);
      _tw1.animate("y",CONST_Y[7]);
      _tw1.animate("rotation",-0.3141592653589793);
      _tw1.fadeTo(0);
      _tw1.delay = 0.2 * 6;
      _tw1.onComplete = clear;
      Starling.juggler.add(_tw1);
      _tw1 = new Tween(_waterSpr,0.2);
      _tw1.fadeTo(0);
      _tw1.delay = 0.2 * 6;
      Starling.juggler.add(_tw1);
      return reSpr;
   }
   
   private function clear() : void
   {
      if(_jug)
      {
         StarlingTools.removeChildrenClear(_jug);
         _jug = null;
      }
      if(_waterSpr)
      {
         StarlingTools.removeChildrenClear(_waterSpr);
         _waterSpr = null;
      }
      Starling.juggler.removeTweens(_jugImg);
   }
   
   public function start() : void
   {
      _jug = createJug();
      _jug.x = 280;
      this.addChild(_jug);
   }
}
