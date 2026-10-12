package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.map.GameMapConfig;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.element.ItemActivityRoulette;
   import com.meng52.game.ui.element.ItemActivityRouletteAward;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.element.LOL_ScrollText;
   import com.meng52.game.ui.element.LOL_TextPop;
   import com.meng52.game.ui.element.LOL_TimeStatus;
   import com.meng52.game.ui.screen.PanelBase;
   import com.meng52.global.ConfigManager;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
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
   import starling.text.TextField;
   import starling.textures.Texture;
   
   public class PanelActivityRoulette extends PanelBase
   {
      
      protected static const BTN_NAME_ONE:String = "btn_name_one";
      
      protected static const BTN_NAME_TEN:String = "btn_name_ten";
      
      protected static const UI_WIDTH_BY_TIMES:Array = [{
         "min":0,
         "max":105,
         "xx":95
      },{
         "min":105,
         "max":270,
         "xx":260
      },{
         "min":270,
         "max":438,
         "xx":428
      },{
         "min":438,
         "max":610,
         "xx":590
      }];
      
      protected var mWarningOne:Boolean;
      
      protected var mWarningTen:Boolean;
      
      protected var mReward:Array;
      
      protected var mY_bg:Number = 0;
      
      protected var mImg_bg:Image;
      
      protected var mImg_avatar:Image;
      
      protected var mImg_tBg:Image;
      
      protected var mImg_pay:Image;
      
      protected var mBtn_one:LOL_Scale9Button;
      
      protected var mBtn_ten:LOL_Scale9Button;
      
      protected var mImg_barBg:Image;
      
      protected var mImg_bar:Image;
      
      protected var mBox_bar:Sprite;
      
      protected var mBox_ui:Sprite;
      
      protected var mRec_bar:Rectangle;
      
      protected var mArr_fixed_gift:Array;
      
      protected var mData_curr:int;
      
      protected var mData_times:int;
      
      protected var mSelect:int = 0;
      
      protected var mBox_itemAward:Sprite;
      
      protected var mArr_itemAward:Array;
      
      protected var mTxt_price:TextField;
      
      protected var mImg_title:LOL_TextPop;
      
      protected var mMC_btn:MovieClip;
      
      protected var mJuggler_clip:Juggler;
      
      protected var mFloatSpr:Sprite;
      
      protected var mBox_award:Sprite;
      
      protected var mBtn_award:LOL_Scale9Button;
      
      protected var mCurr_data:Object;
      
      protected var mFixed_gift:Object;
      
      private var _timer:LOL_TimeStatus;
      
      private var _txt_coin:LOL_MutilTextFieldIcon;
      
      private var _txt_free:TextField;
      
      protected var awardNum:Array;
      
      private var _scrollText:LOL_ScrollText;
      
      public function PanelActivityRoulette()
      {
         super();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         removeEventListener("enterFrame",onENTER_FRAME_clip);
         GlobalData.$mEventDispatcher.removeEventListener("update_activity_fun_roulette",onMainEvent);
         delUI_award();
         delBaseUI();
         GlobalFunction.delTextureByBD("UI_roulette_bg");
         GlobalFunction.delTextureByBD("UI_roulette_bar");
         GlobalFunction.delTextureByBD("UI_roulette_bar_bg");
         var _loc3_:int = 0;
         var _loc2_:int = 12;
         _loc3_ = 0;
         while(_loc3_ < _loc2_)
         {
            GlobalFunction.delTextureByBD("UI_box_RouletteRobot" + (_loc3_ + 1));
            _loc3_++;
         }
      }
      
      protected function delBaseUI() : void
      {
         if(mBox_itemAward)
         {
            StarlingTools.removeChildrenClear(mBox_itemAward);
            mBox_itemAward.removeFromParent(true);
         }
         if(mBox_bar)
         {
            StarlingTools.removeChildrenClear(mBox_bar);
            mBox_bar.removeFromParent(true);
         }
         if(mBox_ui)
         {
            StarlingTools.removeChildrenClear(mBox_ui);
            mBox_ui.removeFromParent(true);
         }
         if(mBtn_one)
         {
            mBtn_one.removeFromParent(true);
         }
         if(mBtn_ten)
         {
            mBtn_ten.removeFromParent(true);
         }
         if(mImg_bg)
         {
            mImg_bg.removeFromParent(true);
         }
         if(mImg_avatar)
         {
            mImg_avatar.removeFromParent(true);
         }
         if(mImg_bar)
         {
            mImg_bar.removeFromParent(true);
         }
         if(mImg_barBg)
         {
            mImg_barBg.removeFromParent(true);
         }
         if(mTxt_price)
         {
            mTxt_price.removeFromParent(true);
         }
         if(mJuggler_clip)
         {
            mJuggler_clip.purge();
            mJuggler_clip.remove(mMC_btn);
         }
         if(mMC_btn)
         {
            mMC_btn.removeFromParent(true);
         }
         if(mFloatSpr)
         {
            mFloatSpr.removeFromParent(true);
         }
         if(_timer)
         {
            _timer.removeFromParent(true);
         }
         mFloatSpr = null;
         mBox_itemAward = null;
         mBox_bar = null;
         mBox_ui = null;
         mBtn_one = null;
         mBtn_ten = null;
         mImg_bg = null;
         mImg_avatar = null;
         mImg_bar = null;
         mImg_barBg = null;
         mCurr_data = null;
         mArr_fixed_gift = null;
         mRec_bar = null;
         mTxt_price = null;
         mMC_btn = null;
         mJuggler_clip = null;
         awardNum = null;
         _timer = null;
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         removeEventListener("addedToStage",initializeHandler);
         setUIs();
      }
      
      protected function setUIs() : void
      {
         var _loc17_:int = 0;
         var _loc18_:int = 0;
         var _loc27_:Array = null;
         var _loc3_:Object = null;
         var _loc23_:Object = null;
         var _loc4_:Object = null;
         var _loc10_:* = null;
         var _loc9_:Sprite = null;
         var _loc22_:Image = null;
         var _loc7_:int = 0;
         var _loc8_:int = 0;
         var _loc13_:int = 0;
         var _loc15_:int = 0;
         var _loc1_:Number = NaN;
         var _loc24_:Number = NaN;
         var _loc21_:DisplayObject = null;
         var _loc19_:Array = null;
         GlobalData.$mEventDispatcher.addEventListener("update_activity_fun_roulette",onMainEvent);
         mImg_bg = GlobalFunction.createImage("UI_roulette_bg",true);
         mImg_bg.y = mY_bg = -130;
         addChild(mImg_bg);
         mBox_ui = new Sprite();
         addChild(mBox_ui);
         mBox_bar = new Sprite();
         mBox_bar.touchable = false;
         mImg_bar = GlobalFunction.createImage("UI_roulette_bar",true);
         mRec_bar = new Rectangle(0,0,mImg_bar.width,mImg_bar.height);
         mBox_bar.addChild(mImg_bar);
         mBox_bar.clipRect = mRec_bar;
         mBox_ui.addChild(mBox_bar);
         mImg_barBg = GlobalFunction.createImage("UI_roulette_bar_bg",true);
         mBox_ui.addChild(mImg_barBg);
         mImg_barBg.x = int((GlobalData.$mStageWidth - mImg_barBg.width) * 0.5);
         mImg_barBg.y = GlobalData.$center_height_curr - 121 - mImg_barBg.height - 30 - 100;
         mBox_bar.x = mImg_barBg.x + 2;
         mBox_bar.y = mImg_barBg.y + 2;
         var _loc11_:Object = ConfigManager.getInstance().getUIPos("Roulette");
         mImg_avatar = GlobalFunction.createImage("UI_box_RouletteRobot1",true);
         mImg_avatar.scaleX = _loc11_[ConfigManager.SCALEX];
         mImg_avatar.scaleY = _loc11_[ConfigManager.SCALEY];
         mImg_avatar.x = mImg_bg.x + int(_loc11_[ConfigManager.POSX]);
         mImg_avatar.y = mImg_bg.y + int(_loc11_[ConfigManager.POSY]);
         mImg_avatar.touchable = false;
         addChild(mImg_avatar);
         mImg_title = new LOL_TextPop(250,100);
         mImg_title.scaleX = mImg_title.scaleY = 0.75;
         mImg_title._icon.rotation = -1.5707963267948966;
         mImg_title._icon.x = -mImg_title._icon.width + 10;
         mImg_title._icon.y = mImg_title._bg.x + mImg_title._icon.height + 45;
         mImg_title.x = mImg_avatar.x + mImg_title.width + int(_loc11_[ConfigManager.POSX1]) - 90;
         mImg_title.y = mImg_avatar.y + int(_loc11_[ConfigManager.POSY1]);
         addChild(mImg_title);
         var _loc26_:Scale9Image = GlobalFunction.createScale9Image("UI_bg_9slice_5_0000",616,100,new Rectangle(30,20,50,30));
         _loc26_.x = (GlobalData.$mStageWidth - _loc26_.width) / 2;
         _loc26_.y = mImg_barBg.y + mImg_barBg.height + 30;
         addChild(_loc26_);
         var _loc16_:TextField = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90492),20,16764006,"center",600,70);
         _loc16_.x = _loc26_.x + (_loc26_.width - _loc16_.width) / 2;
         _loc16_.y = _loc26_.y + (_loc26_.height - _loc16_.height) / 2;
         addChild(_loc16_);
         mBtn_one = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20422),170,75,"UI_btn_normalFun_0000");
         mBtn_one.name = "btn_name_one";
         if(MainConfig.$isEA)
         {
            mBtn_one.fontSize = 21;
         }
         mBtn_one.shadowFilter();
         mBtn_one.addEventListener("triggered",onTRIGGERED_btn);
         mBtn_ten = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20423),170,75,"UI_btn_normalFun_0000");
         mBtn_ten.name = "btn_name_ten";
         mBtn_ten.shadowFilter();
         mBtn_ten.addEventListener("triggered",onTRIGGERED_btn);
         var _loc6_:Number = int(GlobalData.$mStageWidth * 0.5);
         mBox_ui.addChild(mBtn_one);
         mBox_ui.addChild(mBtn_ten);
         mBtn_one.x = _loc6_ - mBtn_one.width - 15;
         mBtn_ten.x = _loc6_ + 15;
         mBtn_one.y = mBtn_ten.y = mImg_barBg.y - mBtn_ten.height + 10;
         mImg_tBg = GlobalFunction.createImage("UI_wordbg_yellow_0_0000");
         mImg_tBg.width = 335;
         mImg_tBg.x = (GlobalData.$mStageWidth - mImg_tBg.width) * 0.5;
         mImg_tBg.y = mBtn_one.y - mImg_tBg.height - 5;
         mBox_ui.addChild(mImg_tBg);
         var _loc14_:Object = GlobalData.$mConfig_ploy_system_simple.roulette;
         _txt_coin = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getLanguageStr(20503),_loc14_.coin + "","UI_money_coin_0_0000",1513239,1513239);
         _txt_coin.x = mImg_tBg.x + (mImg_tBg.width - _txt_coin.textFieldWidth) * 0.5;
         _txt_coin.y = mImg_tBg.y;
         mBox_ui.addChild(_txt_coin);
         mImg_pay = GlobalFunction.createImage("UI_roulette_t_free_0000");
         mImg_pay.name = "UI_roulette_t_free_0000";
         mImg_pay.x = mImg_tBg.x + 20;
         mImg_pay.y = mImg_tBg.y - mImg_tBg.height - 5;
         _txt_free = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90510),20,1118481,"center",300,29);
         _txt_free.x = (GlobalData.$mStageWidth - _txt_free.width) * 0.5;
         _txt_free.y = mImg_tBg.y;
         mBox_ui.addChild(_txt_free);
         mTxt_price = GlobalTextStyle.getTextField(_loc14_.coin + "",20,1118481,"left",80,29);
         mTxt_price.x = mImg_pay.x + mImg_pay.width - 10;
         mTxt_price.y = mImg_tBg.y + 3;
         var _loc5_:Object = mFixed_gift = _loc14_.fixed_gift;
         var _loc20_:Object = null;
         var _loc12_:Object = null;
         var _loc2_:Array = [];
         var _loc25_:int = 0;
         for(_loc20_ in _loc5_)
         {
            _loc12_ = {};
            _loc12_["gift"] = _loc5_[_loc20_];
            _loc12_["id"] = _loc20_.toString();
            _loc2_.push(_loc12_);
         }
         _loc2_.sortOn("id",16);
         if(mArr_fixed_gift == null)
         {
            mArr_fixed_gift = [];
            _loc18_ = 0;
            _loc17_ = int(_loc2_.length);
            _loc12_ = null;
            _loc18_ = 0;
            while(_loc18_ < _loc17_)
            {
               _loc12_ = {};
               _loc12_["id"] = _loc18_;
               _loc12_["min"] = _loc18_ - 1 >= 0 ? int(_loc2_[_loc18_ - 1]["id"]) + 1 : 0;
               _loc12_["max"] = int(_loc2_[_loc18_]["id"]);
               mArr_fixed_gift.push(_loc12_);
               _loc18_++;
            }
         }
         if(!mFloatSpr)
         {
            mFloatSpr = new Sprite();
            mJuggler_clip = new Juggler();
            addEventListener("enterFrame",onENTER_FRAME_clip);
            _loc27_ = (_loc14_.random_gift["6"] as Array).concat();
            _loc1_ = 1;
            _loc24_ = 0.4;
            _loc17_ = Math.min(6,_loc27_.length);
            _loc19_ = [[40,50],[100,20],[160,40],[490,25],[550,60],[600,20]];
            _loc27_ = Tools.randomArray(_loc27_);
            _loc18_ = 0;
            while(_loc18_ < _loc17_)
            {
               _loc3_ = _loc27_[_loc18_][0];
               for(_loc4_ in _loc3_)
               {
                  if(_loc4_ == "avatar" || _loc4_ == "avatar_soul" || _loc4_ == "equip" || _loc4_ == "equip_soul")
                  {
                     _loc23_ = GlobalFunction.getAwardByType(_loc4_.toString(),_loc3_[_loc4_],false,null,"",true,0.8);
                  }
                  else
                  {
                     _loc23_ = GlobalFunction.getAwardByType(_loc4_.toString(),_loc3_[_loc4_]);
                  }
                  _loc9_ = new Sprite();
                  _loc21_ = _loc23_.ui;
                  if(_loc21_)
                  {
                     _loc9_.x = _loc19_[_loc18_][0] + (Math.random() * 10 - 5);
                     _loc9_.y = _loc19_[_loc18_][1] + (Math.random() * 10 - 5) + GameMapConfig.SCREEN_HEIGHT * 0.3 + 40;
                     _loc22_ = DisplayTools.newImg("ball_box0");
                     _loc22_.scaleX = _loc22_.scaleY = 1.4;
                     _loc9_.addChild(_loc22_);
                     _loc21_.pivotX = _loc21_.width / 2;
                     _loc21_.pivotY = _loc21_.height / 2;
                     _loc9_.addChild(_loc21_);
                     mJuggler_clip.delayCall(shake,_loc18_ * 0.15,_loc9_,_loc9_.y,_loc9_.y + 10,0.7);
                  }
                  mFloatSpr.addChild(_loc9_);
                  _loc9_.scaleX = _loc9_.scaleY = 0.45 + Math.random() * 0.1;
               }
               _loc18_++;
            }
            this.addChildAt(mFloatSpr,1);
         }
         upDateProgress();
      }
      
      public function shake(param1:DisplayObject, param2:int, param3:int, param4:Number) : void
      {
         var _loc5_:Tween = null;
         if(!param1)
         {
            return;
         }
         mJuggler_clip.removeTweens(param1);
         _loc5_ = new Tween(param1,param4,"easeInOut");
         if(param1.y <= param2)
         {
            _loc5_.animate("y",param3);
         }
         else
         {
            _loc5_.animate("y",param2);
         }
         _loc5_.onComplete = shake;
         _loc5_.onCompleteArgs = [param1,param2,param3,param4];
         mJuggler_clip.add(_loc5_);
      }
      
      protected function upDateProgress() : void
      {
         var _prevMS:Number;
         var _nowMS:Number;
         var _xCenter:Number;
         var _endMS:Number;
         var i:int;
         var l:int;
         var _data:Object;
         var _index:int;
         var _oneMax:int;
         var _p:Number;
         var _recObj:Object;
         var _min:Number;
         var _max:Number;
         var _num:Number;
         var _every:Number;
         var _wV:Number;
         var _itemAward:ItemActivityRoulette;
         var bgW:* = function(param1:int):void
         {
            _timer.x = 20;
         };
         mData_curr = GlobalData.$userData.attrs.roulette.fixed_count;
         var _isFree:Boolean = false;
         if(GlobalData.$userData.attrs.roulette.last_time == null)
         {
            _isFree = true;
         }
         else
         {
            _prevMS = (GlobalData.$userData.attrs.roulette.last_time as Date).time;
            _nowMS = SendAndSelect.$systemTimer_nowSecond * 1000;
            _isFree = !Tools.checkIsSameDay(_nowMS,_prevMS);
         }
         _xCenter = int(GlobalData.$mStageWidth * 0.5);
         _endMS = (GlobalData.$mConfig_ploy_system_simple.roulette.end_time as Date).time - SendAndSelect.$systemTimer_nowSecond * 1000;
         if(_endMS > 0)
         {
            if(!_timer)
            {
               _timer = new LOL_TimeStatus("panelroulette",bgW);
               _timer.refresh(_endMS * 0.001,GlobalLanguageStr.getLanguageStr(20485));
               _timer.y = 140;
               addChild(_timer);
            }
         }
         if(mImg_title)
         {
            mImg_title.show(GlobalLanguageStr.getLanguageStr(20426,mData_curr),0);
         }
         if(_isFree)
         {
            mBtn_one.showGlow();
            _txt_free.visible = true;
            _txt_coin.visible = false;
            mImg_pay.visible = true;
            mTxt_price.visible = false;
            mBtn_one.visible = true;
            mBtn_ten.visible = false;
            mBtn_one.x = _xCenter - mBtn_one.width * 0.5;
         }
         else
         {
            mBtn_one.clearGlow();
            _txt_free.visible = false;
            _txt_coin.visible = true;
            mImg_pay.visible = false;
            mTxt_price.visible = true;
            mBtn_one.visible = true;
            mBtn_ten.visible = true;
            mBtn_one.x = _xCenter - mBtn_one.width - 15;
            mBtn_ten.x = _xCenter + 15;
         }
         i = 0;
         l = int(mArr_fixed_gift.length);
         _data = null;
         _index = -1;
         _data = mArr_fixed_gift[l - 1];
         _oneMax = int(_data.max);
         mData_times = Math.ceil(mData_curr / _oneMax);
         _p = mData_curr % _data.max;
         i = 0;
         while(i < l)
         {
            _data = mArr_fixed_gift[i];
            if(_p >= _data.min && _p <= _data.max)
            {
               _index = i;
               break;
            }
            i = i + 1;
         }
         _recObj = UI_WIDTH_BY_TIMES[_index];
         _min = Number(_recObj["min"]);
         _max = Number(_recObj["max"]);
         _data = mArr_fixed_gift[_index];
         _num = _data.max - (_data.min > 0 ? _data.min + 1 : 0);
         _every = (_max - _min) / _num;
         _wV = _min + _every * (_p - (_data.min > 0 ? _data.min + 1 : 0));
         mRec_bar.width = _wV;
         mBox_bar.clipRect = mRec_bar;
         if(mBox_itemAward == null)
         {
            mArr_itemAward = [];
            mBox_itemAward = new Sprite();
            mBox_ui.addChild(mBox_itemAward);
            i = 0;
            while(i < l)
            {
               _itemAward = new ItemActivityRoulette(mArr_fixed_gift[i]);
               _itemAward.x = UI_WIDTH_BY_TIMES[i].xx - 2;
               _itemAward.y = mImg_barBg.y + 63;
               mBox_itemAward.addChild(_itemAward);
               mArr_itemAward.push(_itemAward);
               i = i + 1;
            }
         }
         i = 0;
         while(i < l)
         {
            _itemAward = mArr_itemAward[i];
            _itemAward.check_num(mData_times,mData_curr,_oneMax);
            i = i + 1;
         }
      }
      
      protected function onTRIGGERED_btn(param1:Event) : void
      {
         var _loc3_:Object = null;
         var _loc5_:int = 0;
         var _loc2_:String = null;
         var _loc4_:Object = null;
         if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
         {
            GlobalFunction.popAvatarLen();
            return;
         }
         if(Tools.getElementNum(GlobalData.$userData.my_equips) >= int(GlobalData.$mConfig_simple.equip_config[0]))
         {
            GlobalFunction.popEquipFull();
            return;
         }
         var _loc7_:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         var _loc6_:String = _loc7_.name;
         if(_loc6_ == "btn_name_one")
         {
            mSelect = 1;
         }
         else if(_loc6_ == "btn_name_ten")
         {
            mSelect = 10;
         }
         GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
         if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
         {
            GlobalFunction.popAvatarLen();
            return;
         }
         if(!mTxt_price.visible)
         {
            sendService();
         }
         else
         {
            _loc3_ = GlobalData.$mConfig_ploy_system_simple.roulette;
            _loc5_ = _loc3_.coin * mSelect;
            if(GlobalData.$userData.coin >= _loc5_)
            {
               if(mSelect == 1 && mWarningOne)
               {
                  sendService();
               }
               else if(mSelect == 10 && mWarningTen)
               {
                  sendService();
               }
               else
               {
                  _loc2_ = GlobalData.$mConfig_simple.show_id[5];
                  _loc4_ = {
                     "ok":sendService,
                     "no":GlobalFunction.functionNull,
                     "aid":_loc2_
                  };
                  GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20427,mSelect,_loc5_),GlobalTextStyle.COLOR_W_Y_Y_G),_loc4_);
               }
            }
            else
            {
               GlobalFunction.popErrorCoin(_loc5_);
            }
         }
      }
      
      protected function sendService() : void
      {
         SendServiceAMFFun.send_user_roulette(reService,{"num":mSelect});
      }
      
      protected function reService(param1:Object) : void
      {
         if(stage == null)
         {
            return;
         }
         var _loc6_:Object = null;
         var _loc3_:Object = null;
         var _loc5_:Object = null;
         var _loc10_:int = 0;
         var _loc9_:Object = param1.data;
         var _loc2_:Object = GlobalData.$mConfig_ploy_system_simple.roulette;
         if(mSelect == 1)
         {
            mWarningOne = true;
         }
         else if(mSelect == 10)
         {
            mWarningTen = true;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1) && _loc9_.coin != GlobalData.$userData.coin)
         {
            GlobalFunction.payCoinVip(mSelect * _loc2_.coin);
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.roulette = _loc9_.attr_roulette;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.coin = _loc9_.coin;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.gold = _loc9_.gold;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.sp = _loc9_.sp;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.medal = _loc9_.medal;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.avatar_soul = _loc9_.avatar_soul;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.equip_soul = _loc9_.equip_soul;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.culture_book = _loc9_.culture_book;
         }
         if(_loc9_["dn_stone"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.dn_stone = _loc9_.dn_stone;
            }
         }
         if(_loc9_["score"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.score = _loc9_.score;
            }
         }
         if(_loc9_["mark"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.mark = _loc9_.mark;
            }
         }
         if(_loc9_["dust"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.dust = _loc9_.dust;
            }
         }
         if(_loc9_["box_key"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.box_key = _loc9_.box_key;
            }
         }
         if(_loc9_["fragment_energy"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.fragment_energy = _loc9_.fragment_energy;
            }
         }
         if(_loc9_["fragment_energy_extra"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.fragment_energy_extra = _loc9_.fragment_energy_extra;
            }
         }
         if(_loc9_["energy_extra"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.energy_extra = _loc9_.energy_extra;
            }
         }
         if(_loc9_["energy"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.energy = _loc9_.energy;
            }
         }
         if(_loc9_["exp"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.exp = _loc9_.exp;
            }
         }
         if(_loc9_["lv"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.lv = _loc9_.lv;
            }
         }
         var _loc7_:Object = null;
         for(_loc7_ in _loc9_.get_avatars)
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.avatars[_loc7_] = _loc9_.get_avatars[_loc7_];
            }
         }
         for(_loc7_ in _loc9_.get_equips)
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.my_equips[_loc7_] = _loc9_.get_equips[_loc7_];
            }
         }
         mReward = _loc9_.gift_list as Array;
         startRoulette();
         GlobalData.$mGameClassObject.touchable = false;
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateVip();
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateEn();
         GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
         upDateProgress();
         var _loc8_:Array = _loc9_.radio_gift as Array;
         var _loc4_:Array = [];
         if(_loc8_)
         {
            _loc10_ = 0;
            while(_loc10_ < _loc8_.length)
            {
               _loc6_ = _loc8_[_loc10_];
               for(_loc5_ in _loc6_)
               {
                  if(_loc5_ == "avatar" || _loc5_ == "avatar_soul" || _loc5_ == "equip" || _loc5_ == "equip_soul")
                  {
                     _loc3_ = GlobalFunction.getAwardByType(_loc5_.toString(),_loc6_[_loc5_],false,null,"",true,0.8);
                  }
                  else
                  {
                     _loc3_ = GlobalFunction.getAwardByType(_loc5_.toString(),_loc6_[_loc5_]);
                  }
                  _loc4_.push(GlobalLanguageStr.getLanguageStr(97629,GlobalData.$userData.name,_loc3_.msg));
               }
               _loc10_++;
            }
            if(!_scrollText)
            {
               _scrollText = new LOL_ScrollText(_loc4_,500,25,5,16777215,15);
               _scrollText.x = 20;
               _scrollText.y = 180;
               addChild(_scrollText);
            }
            else
            {
               _scrollText.data = _loc4_;
            }
         }
      }
      
      protected function startRoulette() : void
      {
         var _loc3_:* = undefined;
         var _loc4_:int = 0;
         var _loc2_:int = 0;
         var _loc1_:Object = ConfigManager.getInstance().getUIPos("Roulette");
         if(!mMC_btn)
         {
            _loc3_ = new Vector.<Texture>();
            _loc4_ = 0;
            _loc2_ = int(_loc1_[ConfigManager.FRAMENUM]);
            _loc4_ = 0;
            while(_loc4_ < _loc2_)
            {
               _loc3_[_loc4_] = GlobalFunction.getTextureByBD("UI_box_RouletteRobot" + (_loc4_ + 1));
               _loc4_++;
            }
            mMC_btn = new MovieClip(_loc3_,15);
            mMC_btn.touchable = false;
            mMC_btn.loop = false;
            mMC_btn.scaleX = _loc1_[ConfigManager.SCALEX];
            mMC_btn.scaleY = _loc1_[ConfigManager.SCALEY];
            mMC_btn.x = mImg_avatar.x;
            mMC_btn.y = mImg_avatar.y;
            mJuggler_clip.add(mMC_btn);
            addChildAt(mMC_btn,1);
         }
         mImg_avatar.visible = false;
         mMC_btn.alpha = 1;
         mMC_btn.addEventListener("complete",popRoulette);
         mMC_btn.stop();
         mMC_btn.play();
      }
      
      protected function popRoulette(param1:Event) : void
      {
         var _ball:Sprite;
         var _ballImg:Image;
         var _img:Image;
         var i:int;
         var l:int;
         var _award:Object;
         var _awardUI:Object;
         var _awardTypeNum:Object;
         var _x:int;
         var _y:int;
         var _endX:int;
         var _endY:int;
         var _popTime:Number;
         var _stepTime:Number;
         var _tf:TextField;
         var _num:int;
         var _ui:DisplayObject;
         var _time:Number;
         var _maxTime:Number;
         var _e:Event = param1;
         var _tween:Tween = new Tween(mMC_btn,0.2,"easeIn");
         _tween.fadeTo(0);
         mJuggler_clip.add(_tween);
         mImg_avatar.visible = true;
         mMC_btn.removeEventListener("complete",popRoulette);
         l = int(mReward.length);
         _popTime = 1;
         _stepTime = 0.4;
         _maxTime = -2147483648;
         i = 0;
         while(i < l)
         {
            _award = mReward[i];
            for(_awardTypeNum in _award)
            {
               if(_awardTypeNum == "avatar" || _awardTypeNum == "avatar_soul" || _awardTypeNum == "equip" || _awardTypeNum == "equip_soul")
               {
                  _awardUI = GlobalFunction.getAwardByType(_awardTypeNum.toString(),_award[_awardTypeNum],false,null,"",true,0.8);
               }
               else
               {
                  _awardUI = GlobalFunction.getAwardByType(_awardTypeNum.toString(),_award[_awardTypeNum]);
               }
               _ball = new Sprite();
               _ui = _awardUI.ui;
               _ballImg = DisplayTools.newImg("ball_box" + _awardUI.vType);
               _ballImg.scaleX = _ballImg.scaleY = 1.4;
               _ball.addChild(_ballImg);
               if(_ui)
               {
                  _ui.x = -_awardUI.width / 2 + _awardUI.width / 8;
                  _ui.y = -_awardUI.height / 2 + _awardUI.height / 8;
                  if(_awardTypeNum == "culture_book")
                  {
                     _ui.x = -_awardUI.width / 2;
                     _ui.y = -_awardUI.height / 2;
                  }
                  if(_awardTypeNum == "gold")
                  {
                     _ui.x = -_awardUI.width / 2;
                     _ui.y = -_awardUI.height / 2;
                  }
                  if(_awardTypeNum == "coin")
                  {
                     _ui.x = -_awardUI.width / 2;
                     _ui.y = -_awardUI.height / 2;
                  }
                  if(_awardTypeNum == "medal")
                  {
                     _ui.x = -_awardUI.width / 2;
                     _ui.y = -_awardUI.height / 2;
                  }
                  if(_awardTypeNum == "sp")
                  {
                     _ui.x = -_awardUI.width / 2;
                     _ui.y = -_awardUI.height / 2;
                  }
                  _ball.addChild(_ui);
                  _num = int(_awardUI.num);
                  if(_num > 1)
                  {
                  }
               }
               if(l == 10)
               {
                  _x = (i % 5 - 2) * GameMapConfig.SCREEN_WIDTH * 0.1 + GameMapConfig.SCREEN_WIDTH * 0.5;
                  _y = GameMapConfig.SCREEN_HEIGHT * 0.8;
                  _endX = (i % 5 - 2) * GameMapConfig.SCREEN_WIDTH * (0.18 - int(i / 5) * 0.02) + GameMapConfig.SCREEN_WIDTH * 0.5;
                  _endY = (i % 2 - 0.5) * GameMapConfig.SCREEN_HEIGHT * 0.11 + GameMapConfig.SCREEN_HEIGHT * 0.4 + Math.pow(i % 5 - 2,2) * 14;
               }
               else
               {
                  _x = GameMapConfig.SCREEN_WIDTH * 0.5;
                  _y = GameMapConfig.SCREEN_HEIGHT * 0.8;
                  _endX = GameMapConfig.SCREEN_WIDTH * 0.5;
                  _endY = GameMapConfig.SCREEN_HEIGHT * 0.4;
               }
               _ball.x = _x;
               _ball.y = _y;
               _ball.alpha = 0;
               _ball.scaleX = _ball.scaleY = 0.4;
               addChild(_ball);
               _tween = new Tween(_ball,_popTime,"easeOutBack");
               _tween.delay = i * _stepTime;
               _tween.fadeTo(1);
               _tween.scaleTo(1);
               _tween.animate("y",_endY);
               mJuggler_clip.add(_tween);
               _tween = new Tween(_ball,_popTime);
               _tween.delay = i * _stepTime;
               _tween.animate("x",_endX);
               mJuggler_clip.add(_tween);
               mJuggler_clip.delayCall(SoundManager.getOnlyExample().playSound,i * _stepTime,"E_8003",Math.random() * 0.3);
               mJuggler_clip.delayCall(SoundManager.getOnlyExample().playSound,i * _stepTime + 0.1,_awardUI.vType == 2 ? "drop" : "E_9006",_awardUI.vType * 0.3);
               _time = (l - 1) * _stepTime + _popTime * 1.5 + Math.random() * 0.3;
               _maxTime = Math.max(_time,_maxTime);
               _tween = new Tween(_ball,0.2,"easeOut");
               _tween.delay = _time;
               _tween.animate("y",GameMapConfig.SCREEN_HEIGHT * 0.1 + 170);
               mJuggler_clip.add(_tween);
               _tween = new Tween(_ball,0.2,"easeIn");
               _tween.delay = _time + 0.2;
               _tween.animate("y",GameMapConfig.SCREEN_HEIGHT * 0.15 + 230);
               mJuggler_clip.add(_tween);
               _tween = new Tween(_ball,0.4);
               _tween.delay = _time;
               _tween.animate("x",GameMapConfig.SCREEN_WIDTH * 0.63);
               _tween.fadeTo(0.4);
               _tween.scaleTo(0.4);
               _tween.onComplete = DisplayTools.clearObject;
               _tween.onCompleteArgs = [_ball];
               mJuggler_clip.add(_tween);
            }
            i = i + 1;
         }
         _tween = new Tween(this,_maxTime + 0.2);
         _tween.onComplete = function():void
         {
            GlobalData.$mGameClassObject.touchable = true;
         };
         mJuggler_clip.add(_tween);
      }
      
      protected function onENTER_FRAME_clip(param1:EnterFrameEvent) : void
      {
         if(mJuggler_clip)
         {
            mJuggler_clip.advanceTime(param1.passedTime);
         }
      }
      
      protected function onMainEvent(param1:Event) : void
      {
         mCurr_data = param1.data;
         setUI_award();
      }
      
      protected function setUI_award() : void
      {
         var _loc5_:Object = null;
         var _loc1_:Object = null;
         var _loc6_:ItemActivityRouletteAward = null;
         var _loc9_:int = 0;
         delUI_award();
         mBox_award = new Sprite();
         addChild(mBox_award);
         var _loc4_:Quad = Tools.newQuad(GlobalData.$mStageWidth,GlobalData.$center_height_curr,0,0,1118481);
         _loc4_.alpha = 0.75;
         mBox_award.addChild(_loc4_);
         var _loc12_:Number = int(GlobalData.$mStageWidth * 0.5);
         var _loc13_:Number = int((GlobalData.$center_height_curr - 121) * 0.5);
         var _loc11_:Image = GlobalFunction.createImage("UI_bg_vip_buy_1_0000");
         _loc11_.touchable = false;
         _loc11_.x = int(_loc12_ - _loc11_.width * 0.5);
         _loc11_.y = int(_loc13_ - _loc11_.height * 0.5) + 50;
         mBox_award.addChild(_loc11_);
         var _loc17_:int = int(mCurr_data.num);
         _loc4_.addEventListener("touch",onTOUCH_closeAward);
         var _loc15_:String = _loc17_ > 0 ? GlobalLanguageStr.getLanguageStr(20173) : GlobalLanguageStr.getLanguageStr(20121);
         mBtn_award = new LOL_Scale9Button(_loc15_,170,75,"UI_btn_normalFun_0000");
         mBtn_award.shadowFilter();
         mBtn_award.x = int(_loc12_ - mBtn_award.width * 0.5) - 4;
         mBtn_award.y = _loc11_.y + _loc11_.height - mBtn_award.height - 30;
         mBox_award.addChild(mBtn_award);
         mBtn_award.addEventListener("triggered",onTRIGGERED_award);
         var _loc10_:Object = mFixed_gift;
         var _loc7_:Object = _loc10_[mCurr_data.data.max];
         var _loc14_:Object = null;
         var _loc8_:Object = null;
         var _loc18_:String = "";
         var _loc2_:Object = null;
         var _loc3_:Array = [];
         awardNum = [0,0];
         for(_loc8_ in _loc7_)
         {
            _loc18_ = _loc8_.toString();
            if(_loc18_ == "equip")
            {
               awardNum[1] = 1;
            }
            if(_loc18_ == "avatar")
            {
               awardNum[0] = 1;
            }
            if(_loc18_ == "equip" || _loc18_ == "avatar")
            {
               _loc2_ = _loc7_[_loc8_];
               for(_loc5_ in _loc2_)
               {
                  _loc1_ = {};
                  _loc1_[_loc5_] = _loc2_[_loc5_];
                  if(_loc5_ == "avatar" || _loc5_ == "avatar_soul" || _loc5_ == "equip" || _loc5_ == "equip_soul")
                  {
                     _loc14_ = GlobalFunction.getAwardByType(_loc18_,_loc1_,false,null,"",true,0.8);
                  }
                  else
                  {
                     _loc14_ = GlobalFunction.getAwardByType(_loc18_,_loc1_);
                  }
                  _loc6_ = new ItemActivityRouletteAward(_loc14_);
                  _loc6_.scaleX = _loc6_.scaleY = 0.9;
                  _loc3_.push({
                     "index":0,
                     "ui":_loc6_
                  });
                  mBox_award.addChild(_loc6_);
               }
            }
            else
            {
               if(_loc5_ == "avatar" || _loc5_ == "avatar_soul" || _loc5_ == "equip" || _loc5_ == "equip_soul")
               {
                  _loc14_ = GlobalFunction.getAwardByType(_loc18_,_loc7_[_loc8_],false,null,"",true,0.8);
               }
               else
               {
                  _loc14_ = GlobalFunction.getAwardByType(_loc18_,_loc7_[_loc8_]);
               }
               _loc6_ = new ItemActivityRouletteAward(_loc14_);
               _loc6_.scaleX = _loc6_.scaleY = 0.9;
               _loc3_.push({
                  "index":1,
                  "ui":_loc6_
               });
               mBox_award.addChild(_loc6_);
            }
         }
         var _loc16_:Number = _loc3_.length * 170;
         var _loc19_:Number = int(_loc11_.x + (_loc11_.width - _loc16_) * 0.5);
         _loc3_.sortOn(["index"],16);
         _loc9_ = 0;
         while(_loc9_ < _loc3_.length)
         {
            _loc6_ = _loc3_[_loc9_].ui as ItemActivityRouletteAward;
            _loc6_.x = _loc11_.x + 60;
            _loc6_.y = _loc11_.y + 110 + _loc9_ * 90;
            _loc9_++;
         }
      }
      
      protected function onTOUCH_closeAward(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(param1.currentTarget as DisplayObject);
         if(_loc2_)
         {
            if(_loc2_.phase == "began")
            {
               delUI_award();
            }
         }
      }
      
      protected function onTRIGGERED_award(param1:Event) : void
      {
         if(mCurr_data.num > 0)
         {
            if(awardNum != null && awardNum[0] == 1 && Tools.getElementNum(GlobalData.$userData.avatars) >= GlobalData.$userData.attrs.avatar_len)
            {
               GlobalFunction.popAvatarLen();
            }
            else if(awardNum != null && awardNum[1] == 1 && Tools.getElementNum(GlobalData.$userData.my_equips) >= int(GlobalData.$mConfig_simple.equip_config[0]))
            {
               GlobalFunction.popEquipFull();
            }
            else
            {
               SendServiceAMFFun.send_user_roulette_lottery(reService_award,{"level":mCurr_data.data.max});
            }
         }
         else
         {
            delUI_award();
         }
      }
      
      protected function reService_award(param1:Object) : void
      {
         if(stage == null)
         {
            return;
         }
         var _loc5_:Object = null;
         var _loc3_:Object = null;
         var _loc12_:String = "sound03";
         SoundManager.getOnlyExample().playSound(_loc12_);
         var _loc13_:Object = param1.data;
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.roulette = _loc13_.attr_roulette;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.medal = _loc13_.medal;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.avatar_soul = _loc13_.avatar_soul;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.sp = _loc13_.sp;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.equip_soul = _loc13_.equip_soul;
         }
         if(_loc13_["coin"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.coin = _loc13_.coin;
            }
         }
         if(_loc13_["gold"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.gold = _loc13_.gold;
            }
         }
         if(_loc13_["dn_stone"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.dn_stone = _loc13_.dn_stone;
            }
         }
         if(_loc13_["score"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.score = _loc13_.score;
            }
         }
         if(_loc13_["mark"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.mark = _loc13_.mark;
            }
         }
         if(_loc13_["dust"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.dust = _loc13_.dust;
            }
         }
         if(_loc13_["box_key"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.box_key = _loc13_.box_key;
            }
         }
         if(_loc13_["culture_book"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.culture_book = _loc13_.culture_book;
            }
         }
         if(_loc13_["fragment_energy"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.fragment_energy = _loc13_.fragment_energy;
            }
         }
         if(_loc13_["fragment_energy_extra"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.fragment_energy_extra = _loc13_.fragment_energy_extra;
            }
         }
         if(_loc13_["energy_extra"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.energy_extra = _loc13_.energy_extra;
            }
         }
         if(_loc13_["energy"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.energy = _loc13_.energy;
            }
         }
         if(_loc13_["exp"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.exp = _loc13_.exp;
            }
         }
         if(_loc13_["lv"])
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.lv = _loc13_.lv;
            }
         }
         var _loc11_:Object = null;
         for(_loc11_ in _loc13_.get_avatars)
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.avatars[_loc11_] = _loc13_.get_avatars[_loc11_];
            }
         }
         for(_loc11_ in _loc13_.get_equips)
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.my_equips[_loc11_] = _loc13_.get_equips[_loc11_];
            }
         }
         var _loc2_:Object = GlobalData.$mConfig_ploy_system_simple.roulette;
         var _loc8_:Object = _loc2_.fixed_gift;
         var _loc6_:Object = _loc8_[mCurr_data.data.max];
         var _loc9_:Object = null;
         var _loc7_:Object = null;
         var _loc10_:String = "";
         var _loc4_:Object = null;
         for(_loc7_ in _loc6_)
         {
            _loc10_ = _loc7_.toString();
            if(_loc10_ == "equip" || _loc10_ == "avatar")
            {
               _loc4_ = _loc6_[_loc7_];
               for(_loc5_ in _loc4_)
               {
                  _loc3_ = {};
                  _loc3_[_loc5_] = _loc4_[_loc5_];
                  if(_loc5_ == "avatar" || _loc5_ == "avatar_soul" || _loc5_ == "equip" || _loc5_ == "equip_soul")
                  {
                     _loc9_ = GlobalFunction.getAwardByType(_loc10_,_loc3_,false,null,"",true,0.8);
                  }
                  else
                  {
                     _loc9_ = GlobalFunction.getAwardByType(_loc10_,_loc3_);
                  }
                  GlobalFunction.popAward(_loc10_,GlobalLanguageStr.getLanguageStr(90062,_loc9_.msg),_loc3_,false);
               }
            }
            else
            {
               if(_loc5_ == "avatar" || _loc5_ == "avatar_soul" || _loc5_ == "equip" || _loc5_ == "equip_soul")
               {
                  _loc9_ = GlobalFunction.getAwardByType(_loc10_,_loc6_[_loc7_],false,null,"",true,0.8);
               }
               else
               {
                  _loc9_ = GlobalFunction.getAwardByType(_loc10_,_loc6_[_loc7_]);
               }
               GlobalFunction.popAward(_loc10_,GlobalLanguageStr.getLanguageStr(90062,_loc9_.msg),_loc6_[_loc7_],false);
            }
         }
         delUI_award();
         upDateProgress();
      }
      
      protected function delUI_award() : void
      {
         if(mBtn_award)
         {
            mBtn_award.removeFromParent(true);
         }
         if(mBox_award)
         {
            StarlingTools.removeChildrenClear(mBox_award);
            mBox_award.removeFromParent(true);
         }
         mBox_award = null;
         mBtn_award = null;
      }
   }
}

