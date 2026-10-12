package com.meng52.game.ui.panel
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.map.GameMapTools;
   import com.meng52.game.ui.element.ItemWelfare;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_EffectLight;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.element.LOL_TextField;
   import com.meng52.game.ui.element.LOL_TimeStatus;
   import com.meng52.game.ui.screen.PanelCenterPVE;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale3Image;
   import feathers.display.Scale9Image;
   import feathers.textures.Scale3Textures;
   import feathers.textures.Scale9Textures;
   import flash.events.TimerEvent;
   import flash.geom.Rectangle;
   import flash.utils.Timer;
   import starling.animation.Tween;
   import starling.core.Starling;
   import starling.display.DisplayObject;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.filters.ColorMatrixFilter;
   import starling.text.TextField;
   
   public class PanelActivityWelfare extends PanelCenterPVE
   {
      
      private var _time:LOL_TimeStatus;
      
      private var _rewards:Array = [];
      
      private var _getInfos:Array = [];
      
      private var _getBtns:Array = [];
      
      private var _goods:Array = [[],[],[],[],[]];
      
      private var _selectBig:Sprite;
      
      private var _config:Object;
      
      private var _once:Array = [];
      
      private var _timer:Timer;
      
      private var _autoIndex:int = 0;
      
      private var _delay:int = 100;
      
      private var _delayCur:int = 0;
      
      private var _delayAll:int = 20;
      
      private var _freeData:Array = [];
      
      private var _freeConfig:Array = [];
      
      public var _infoData:Object;
      
      private var _data:Object;
      
      private var _lines:Sprite;
      
      private var _tags:Array = [[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0],[0,0,0,0,0]];
      
      private var _had_reward:Array = [];
      
      private var _welfare_photo:Array = [];
      
      private var _isActive:Boolean = false;
      
      private var _isDelayCall:Boolean = false;
      
      private var _timeChcek:Boolean = false;
      
      private var _isFirstBuy:int = 0;
      
      private var _isPopFirstIndex:int = -1;
      
      private var _spRule:Sprite;
      private var mReceiptDustBefore:Number;
      
      private var _tween:Tween;
      
      private var mBox_Grren:Sprite;
      
      private var mImg3_title:Scale3Image;
      
      private var mBtn_close:LOL_Button;
      
      private var btn_BuyOne:LOL_Scale9Button;
      
      private var btn_BuyTen:LOL_Scale9Button;
      
      private var mAvatarIcon:Image;
      
      private var _type:String;
      
      private var moneyGo:LOL_MutilTextFieldIcon;
      
      private var moneyL:LOL_MutilTextFieldIcon;
      
      private var index:int;
      
      private var arr:Array = [];
      
      private var txt:TextField;
      
      private var _fun:Object;
      
      private var str:Array;
      
      private var str_1:Array;
      
      private var _id:String;
      
      public function PanelActivityWelfare()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         _config = GlobalData.$mConfig.ploy_system_simple.welfare;
         _welfare_photo = _config.welfare_photo;
         mImgBg = GlobalFunction.createImage("png_activity_bg",true);
         var _loc2_:ColorMatrixFilter = new ColorMatrixFilter();
         _loc2_.adjustBrightness(-0.2);
         _loc2_.adjustContrast(0.6);
         _loc2_.adjustSaturation(0.5);
         _loc2_.adjustHue(int(_config.hue) / 180);
         mImgBg.filter = _loc2_;
         mImgBg.y = -180;
         addChild(mImgBg);
         var _loc3_:Object = GlobalFunction.get_HelpLink(GlobalLanguageStr.getLanguageStr(90467));
         _spRule = _loc3_.ui;
         _spRule.x = GlobalData.$mStageWidth - _loc3_.w - 20;
         addChild(_spRule);
         _spRule.addEventListener("touch",onTRIGGERED_help);
         SendServiceAMFFun.send_user_welfare_reward_info(re_info,null);
         GlobalData.$mEventDispatcher.addEventListener("update_panel_welfareinfo",UPDATE_PANEL_WELFAREINFO);
      }
      
      private function UPDATE_PANEL_WELFAREINFO(param1:Event) : void
      {
         var _loc12_:int = 0;
         var _loc4_:LOL_Scale9Button = null;
         var _loc8_:Object = null;
         var _loc7_:Image = null;
         var _loc10_:* = 0;
         var _loc2_:* = 0;
         var _loc6_:* = 0;
         var _loc9_:int = (_config.start_time as Date).time * 0.001;
         var _loc11_:int = (_config.end_time as Date).time * 0.001;
         var _loc5_:Number = SendAndSelect.$systemTimer_nowSecond;
         var _loc3_:int = _config.duration * 60;
         if(_infoData.number == -1)
         {
            if(_loc9_ + _loc3_ - _loc5_ <= int(_config.buy_offset) * 60)
            {
               btnEnable(false,GlobalLanguageStr.getLanguageStr(20146));
            }
            else
            {
               _loc12_ = 0;
               while(_loc12_ < _getBtns.length)
               {
                  _loc4_ = _getBtns[_loc12_] as LOL_Scale9Button;
                  _loc8_ = _getInfos[_loc12_];
                  _loc7_ = _loc4_.parent.getChildByName("mh") as Image;
                  if(_freeData[_loc12_] < _freeConfig[_loc12_])
                  {
                     if(_loc7_)
                     {
                        _loc7_.visible = false;
                     }
                  }
                  else if(_loc7_)
                  {
                     _loc7_.visible = true;
                  }
                  _loc12_++;
               }
            }
         }
         if(_data.flag == 1)
         {
            _loc10_ = 0;
            while(_loc10_ < _goods.length)
            {
               _loc2_ = 0;
               _loc6_ = 0;
               while(_loc6_ < _data.welfare_info.length)
               {
                  if(_data.welfare_info[_loc6_].pos_x == _loc10_)
                  {
                     _loc2_ = uint(_data.welfare_info[_loc6_].num);
                  }
                  _loc6_++;
               }
               if(_loc2_ != 0)
               {
                  updateItem(index,_loc10_,_loc2_);
               }
               _loc10_++;
            }
         }
         else
         {
            updateItem(_data.welfare_info.pos_y,_data.welfare_info.pos_x,_data.welfare_info.num);
         }
         checkFirst();
      }
      
      private function checkFirst() : void
      {
         var _loc2_:int = 0;
         var _loc1_:Array = _tags;
         _loc2_ = 0;
         while(_loc2_ < _getInfos.length)
         {
            if(_getInfos[_loc2_].type == "coin")
            {
               if(_isPopFirstIndex == -1)
               {
                  _isPopFirstIndex = _loc2_;
                  break;
               }
            }
            _loc2_++;
         }
      }
      
      private function onTRIGGERED_help(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(_spRule);
         if(_loc2_)
         {
            if(_loc2_.phase == "ended")
            {
               GlobalFunction.popPanelHelp(MainConfig.SERVER_ADDRESS_HELP_ADD_WELFARE);
            }
         }
      }
      
      private function re_info(param1:Object) : void
      {
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc3_:Number = NaN;
         var _loc2_:int = 0;
         _infoData = param1.data;
         if(_infoData.info != null)
         {
            _tags[0] = _infoData.info[0];
            _tags[1] = _infoData.info[1];
            _tags[2] = _infoData.info[2];
            _tags[3] = _infoData.info[3];
         }
         _freeData = _infoData.welfare_times;
         _had_reward = _infoData.had_reward;
         _isFirstBuy = _infoData.coin_times;
         getData();
         if(_infoData.number != -1 && _infoData.had_play == 0)
         {
            _isActive = true;
            showItem();
            btnEnable(false,GlobalLanguageStr.getLanguageStr(20173));
            GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(90483),GlobalLanguageStr.getLanguageStr(90484),{"ok":autoFlash});
         }
         else if(_infoData.number != -1 && _infoData.had_play == 1)
         {
            _isActive = true;
            showItem();
            btnEnable(false,GlobalLanguageStr.getLanguageStr(20173));
            endFlashBig(_infoData.number);
         }
         else
         {
            showItem();
            _loc4_ = (_config.start_time as Date).time * 0.001;
            _loc5_ = (_config.end_time as Date).time * 0.001;
            _loc3_ = SendAndSelect.$systemTimer_nowSecond;
            _loc2_ = _config.duration * 60;
            if(_loc4_ + _loc2_ - _loc3_ <= int(_config.buy_offset) * 60)
            {
               btnEnable(false,GlobalLanguageStr.getLanguageStr(20146));
            }
         }
         checkFirst();
      }
      
      private function autoFlash() : void
      {
         autoFlashBig(_infoData.number);
      }
      
      private function getData() : void
      {
         var _loc11_:int = 0;
         var _loc10_:int = 0;
         var _loc6_:Object = null;
         var _loc2_:* = 0;
         var _loc7_:int = (_config.start_time as Date).time * 0.001;
         var _loc8_:int = (_config.end_time as Date).time * 0.001;
         var _loc5_:Number = SendAndSelect.$systemTimer_nowSecond;
         _freeConfig = _config.free_times as Array;
         if(_time)
         {
            _time.removeFromParent(true);
            _time = null;
         }
         time_OnUpdate(_loc8_ - _loc5_);
         var _loc3_:int = _config.duration * 60;
         _time = new LOL_TimeStatus(null,time_OnUpdate);
         if(_infoData.number != -1)
         {
            _time.refresh(_loc8_ - _loc5_,"",GlobalLanguageStr.getLanguageStr(90482),time_Complete);
         }
         else
         {
            _time.refresh(_loc7_ + _loc3_ - _loc5_,"",GlobalLanguageStr.getLanguageStr(90464),time_Complete);
         }
         _time.x = 20;
         addChild(_time);
         _rewards = [];
         _loc11_ = 0;
         while(_loc11_ < _config.reward.length)
         {
            for(var _loc4_:String in _config.reward[_loc11_])
            {
               _rewards.push({
                  "type":_loc4_,
                  "data":_config.reward[_loc11_][_loc4_]
               });
            }
            _loc11_++;
         }
         _getInfos = [];
         _loc10_ = 0;
         while(_loc10_ < _config.dust_price.length)
         {
            _loc6_ = {};
            _loc2_ = 0;
            while(_loc2_ < _config.dust_price[_loc10_].length)
            {
               if(!_loc2_)
               {
                  for(var _loc1_:String in _config.dust_price[_loc10_][_loc2_])
                  {
                     for(var _loc9_:String in _config.dust_price[_loc10_][_loc2_][_loc1_])
                     {
                        _loc6_.type = _loc9_;
                        _loc6_.dust = _loc1_;
                        _loc6_.count = _config.dust_price[_loc10_][_loc2_][_loc1_][_loc9_];
                        _loc6_.data = _config.dust_price[_loc10_][_loc2_];
                     }
                  }
               }
               else
               {
                  for(_loc1_ in _config.dust_price[_loc10_][_loc2_])
                  {
                     for(_loc9_ in _config.dust_price[_loc10_][_loc2_][_loc1_])
                     {
                        _loc6_.dust10 = _loc1_;
                        _loc6_.type10 = _loc9_;
                        _loc6_.count10 = _config.dust_price[_loc10_][_loc2_][_loc1_][_loc9_];
                        _loc6_.data10 = _config.dust_price[_loc10_][_loc2_];
                     }
                  }
               }
               _loc2_++;
            }
            _getInfos.push(_loc6_);
            _loc10_++;
         }
      }
      
      private function time_OnUpdate(param1:int) : void
      {
         var _loc4_:int = (_config.start_time as Date).time * 0.001;
         var _loc5_:int = (_config.end_time as Date).time * 0.001;
         var _loc3_:Number = SendAndSelect.$systemTimer_nowSecond;
         var _loc2_:int = _config.duration * 60;
         if(_loc4_ + _loc2_ - _loc3_ <= int(_config.buy_offset) * 60 && !_timeChcek)
         {
            _timeChcek = true;
            btnEnable(false,GlobalLanguageStr.getLanguageStr(20146));
         }
      }
      
      private function time_Complete() : void
      {
         SendServiceAMFFun.send_user_welfare_reward_info(re_info,null);
      }
      
      private function showItem() : void
      {
         var _loc2_:Scale9Textures = null;
         var _loc3_:Scale9Image = null;
         var _loc1_:Image = null;
         var _loc5_:int = 0;
         var _loc4_:Sprite = null;
         if(!_selectBig)
         {
            _loc2_ = new Scale9Textures(GlobalFunction.getTexture("UI_activity_btn_bg_0_0000"),new Rectangle(35,35,51,47));
            _loc3_ = new Scale9Image(_loc2_);
            _loc3_.width = 105;
            _loc3_.height = GlobalData.$mStageHeight / 2;
            _loc3_.x = -1;
            _loc3_.y = 15;
            _loc1_ = GlobalFunction.createImage("UI_getaward_bg_0000");
            _loc1_.x = 10;
            _selectBig = new Sprite();
            _selectBig.addChild(_loc3_);
            _selectBig.addChild(_loc1_);
            _selectBig.visible = false;
            _selectBig.touchable = false;
            addChild(_selectBig);
         }
         if(_lines)
         {
            StarlingTools.removeChildrenClear(_lines);
            _lines = null;
         }
         _getBtns = [];
         _lines = new Sprite();
         addChild(_lines);
         _loc5_ = 0;
         while(_loc5_ < _rewards.length)
         {
            _loc4_ = getItem(_loc5_);
            _loc4_.x = 25;
            _loc4_.y = 120 + _loc5_ * (GlobalData.$mStageHeight <= 960 ? 110 : 110 + (GlobalData.$mStageHeight - 960) / 5);
            _lines.addChild(_loc4_);
            _loc5_++;
         }
         setChildIndex(_selectBig,this.numChildren - 1);
      }
      
      private function getItem(param1:int) : Sprite
      {
         var _loc11_:DisplayObject = null;
         var _loc5_:Object = null;
         var _loc8_:int = 0;
         var _loc4_:ItemWelfare = null;
         var _loc3_:Sprite = new Sprite();
         var _loc10_:LOL_EffectLight = new LOL_EffectLight(1);
         _loc10_.x = 25;
         _loc10_.y = 35;
         _loc10_.name = "effect";
         _loc3_.addChild(_loc10_);
         var _loc2_:Scale3Textures = new Scale3Textures(GlobalFunction.getTexture("UI_welfare_bg_000" + param1 + ""),20,60);
         var _loc13_:Scale3Image = new Scale3Image(_loc2_,1);
         _loc13_.x = 50;
         _loc13_.y = -1;
         _loc13_.width = 455;
         _loc13_.height = 75;
         _loc3_.addChild(_loc13_);
         if(_rewards[param1].type == "avatar" || _rewards[param1].type == "avatar_soul" || _rewards[param1].type == "equip" || _rewards[param1].type == "equip_soul")
         {
            _loc11_ = GlobalFunction.getAwardByType(_rewards[param1].type,_rewards[param1].data,false,null,"",true,0.8).ui;
         }
         else
         {
            _loc11_ = GlobalFunction.getAwardByType(_rewards[param1].type,_rewards[param1].data,false,null,"",true,1).ui;
         }
         _loc11_.x = -10;
         _loc3_.addChild(_loc11_);
         arr.push(_rewards[param1].data);
         var _loc6_:Image = GlobalFunction.createImage("UI_welfare_bg_000" + param1 + "");
         _loc6_.x = -23;
         _loc6_.y = -18;
         _loc3_.addChild(_loc6_);
         var _loc7_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(90463),100,30);
         _loc7_.fontColor = 16777215;
         _loc7_.fontSize = 15;
         _loc7_.x = _loc6_.x + 16;
         _loc7_.y = _loc6_.y - 5;
         _loc7_.shadowFilter();
         _loc3_.addChild(_loc7_);
         var _loc9_:LOL_Scale9Button = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20146),110,65);
         _loc9_.name = param1 + "";
         _loc9_.fontSize = 20;
         _loc9_.x = _loc13_.x + _loc13_.width - 10;
         _loc9_.y = _loc13_.y + 3;
         _loc3_.addChild(_loc9_);
         _loc9_.addEventListener("triggered",btn_TriggeredAfter);
         _getBtns.push(_loc9_);
         if(!_isActive)
         {
            _loc5_ = _getInfos[param1];
            _loc9_.text = GlobalLanguageStr.getLanguageStr(97053);
         }
         str_1 = GlobalLanguageStr.getLanguageStr(97815).split("$");
         str = GlobalLanguageStr.getLanguageStr(90197).split("$");
         var _loc12_:LOL_MutilTextFieldIcon = new LOL_MutilTextFieldIcon("",str[param1],"UI_magic_money_000" + param1 + "");
         _loc12_.fontSize = 15;
         _loc12_.iconScale = 0.5;
         _loc12_.x = _loc9_.x + _loc9_.width / 2 - _loc12_.width / 2;
         _loc12_.y = _loc9_.y + _loc9_.height;
         _loc12_.shadowFilter();
         _loc12_.name = "dust";
         _loc3_.addChild(_loc12_);
         _loc8_ = 0;
         while(_loc8_ < int(_config.number_pool))
         {
            _loc4_ = new ItemWelfare();
            _loc4_.data = {
               "mainIndex":param1,
               "index":_welfare_photo[_loc8_],
               "count":_tags[param1][_loc8_],
               "data":_rewards[param1]
            };
            _loc4_.x = 70 + _loc8_ * 75 + _loc4_.width / 2;
            _loc4_.y = _loc4_.height / 2 - 20;
            _loc3_.addChild(_loc4_);
            _goods[param1][_loc8_] = _loc4_;
            _loc8_++;
         }
         return _loc3_;
      }
      
      private function btn_TriggeredAfter(param1:Event) : void
      {
         var _loc2_:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         var _loc3_:int = int(_loc2_.name);
         index = _loc3_;
         if(_loc2_.enabled)
         {
            if(_isActive)
            {
               SendServiceAMFFun.send_user_welfare_get_reward(re_get,{"color":index});
            }
            else
            {
               setExChangeUIs(_loc3_);
            }
         }
         else
         {
            if(_loc2_.text == GlobalLanguageStr.getLanguageStr(20146))
            {
               LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getLanguageStr(97014));
            }
            if(_loc2_.text == GlobalLanguageStr.getLanguageStr(97017))
            {
               LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getLanguageStr(97016));
            }
            if(_loc2_.text == GlobalLanguageStr.getLanguageStr(20377))
            {
               LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getLanguageStr(97015));
            }
         }
      }
      
      private function setExChangeUIs(param1:int) : void
      {
         var _loc14_:* = null;
         var _loc10_:* = 0;
         var _loc4_:String = null;
         var _loc21_:Object = null;
         var _loc12_:Object = null;
         var _loc15_:String = null;
         var _loc13_:* = 0;
         mBox_Grren = new Sprite();
         if(this.parent)
         {
            this.parent.addChild(mBox_Grren);
         }
         var _loc23_:Quad = Tools.newQuad(GlobalData.$mStageWidth,GlobalData.$center_height_curr - 121,0,0,0);
         _loc23_.alpha = 0.75;
         mBox_Grren.addChild(_loc23_);
         var _loc16_:Scale9Image = new Scale9Image(new Scale9Textures(GlobalFunction.getTexture("UI_bg_9slice_1_0000"),new Rectangle(83,94,88,100)));
         _loc16_.width = 595;
         _loc16_.height = 380;
         _loc16_.x = int((GlobalData.$mStageWidth - _loc16_.width) * 0.5);
         _loc16_.y = int((_loc23_.height - _loc16_.height) * 0.5) + 25;
         mBox_Grren.addChild(_loc16_);
         var _loc6_:Image = GlobalFunction.createImage("UI_bg_9slice_2_0000");
         var _loc7_:Image = GlobalFunction.createImage("UI_bg_9slice_2_0000");
         _loc7_.scaleX = -1;
         _loc6_.x = _loc16_.x + 15;
         _loc6_.y = int(_loc16_.y + 10);
         _loc7_.x = _loc16_.x + _loc16_.width - 15;
         _loc7_.y = _loc6_.y;
         mBox_Grren.addChild(_loc6_);
         mBox_Grren.addChild(_loc7_);
         mImg3_title = new Scale3Image(new Scale3Textures(GlobalFunction.getTexture("UI_bg_9slice_3_0000"),90,100));
         mImg3_title.touchable = false;
         mBox_Grren.addChild(mImg3_title);
         var _loc20_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(97702),GlobalData.$mStageWidth,46);
         _loc20_.fontSize = 30;
         _loc20_.fontColor = 16764006;
         _loc20_.hAlign = "center";
         _loc20_.shadowFilter();
         _loc20_.touchable = false;
         mBox_Grren.addChild(_loc20_);
         mBtn_close = GlobalFunction.createButtonStarling("UI_btn_9slice_0000");
         mBtn_close.x = _loc16_.x + _loc16_.width - mBtn_close.width - 15;
         mBtn_close.y = _loc16_.y + 10;
         mBox_Grren.addChild(mBtn_close);
         mBtn_close.addEventListener("triggered",onTRIGGERED_exchangeClose);
         var _loc8_:Rectangle = _loc20_.textBounds;
         var _loc5_:Number = _loc8_.width + 90;
         mImg3_title.width = Math.max(_loc5_,100);
         mImg3_title.x = int(_loc16_.x + (_loc16_.width - mImg3_title.width) * 0.5);
         mImg3_title.y = int(_loc16_.y + 12);
         _loc20_.y = mImg3_title.y;
         _loc10_ = 0;
         while(_loc10_ < arr.length)
         {
            for(var _loc9_:String in arr[_loc10_])
            {
               if(param1 == _loc10_)
               {
                  _loc4_ = _loc9_;
                  _loc21_ = {};
                  _loc21_[_loc4_] = 1;
                  _loc12_ = GlobalFunction.getAwardByType("avatar_soul",_loc21_);
                  trace(_loc12_);
               }
            }
            _loc10_++;
         }
         var _loc19_:String = GlobalLanguageStr.getLanguageStr(97814,_getInfos[param1].dust,str[param1],str_1[param1],_getInfos[param1].dust10,str[param1],str_1[param1]);
         var _loc17_:TextFieldHtmlRenderer = GlobalTextStyle.getHtmlTextRenderer();
         _loc17_.text = Tools.formatLineX(_loc19_,GlobalTextStyle.COLOR_W_B_Y_O,24,20);
         _loc17_.x = _loc16_.x + 53;
         _loc17_.y = _loc16_.y + 100;
         mBox_Grren.addChild(_loc17_);
         btn_BuyOne = new LOL_Scale9Button("",150,70,"UI_btn_normalFun_0000");
         btn_BuyOne.name = "buyone";
         btn_BuyOne.fontSize = 22;
         mBox_Grren.addChild(btn_BuyOne);
         btn_BuyOne.x = _loc16_.x + 70;
         btn_BuyOne.y = _loc16_.y + 220;
         btn_BuyOne.addEventListener("triggered",btn_Triggered);
         var _loc18_:LOL_MutilTextFieldIcon = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getLanguageStr(20146),_getInfos[param1].dust,"UI_magic_money_000" + param1 + "");
         _loc18_.fontSize = 20;
         _loc18_.iconScale = 0.5;
         _loc18_.x = btn_BuyOne.x + 20;
         _loc18_.y = btn_BuyOne.y + btn_BuyOne.height + 10;
         mBox_Grren.addChild(_loc18_);
         moneyGo = new LOL_MutilTextFieldIcon("",Tools.formateNum(_getInfos[param1].count) + "",_getInfos[param1].type == "gold" ? "UI_money_gold_0_0000" : "UI_money_coin_0_0000",1118481,1118481);
         btn_BuyOne.addChild(moneyGo);
         moneyGo.x = btn_BuyOne.width / 2 - moneyGo.width / 2;
         moneyGo.y = btn_BuyOne.height / 2 - moneyGo.height / 2 + 5;
         btn_BuyTen = new LOL_Scale9Button("",150,70,"UI_btn_normalFun_0000");
         btn_BuyTen.name = "buyten";
         btn_BuyTen.fontSize = 22;
         mBox_Grren.addChild(btn_BuyTen);
         btn_BuyTen.x = btn_BuyOne.x + btn_BuyOne.width * 2;
         btn_BuyTen.y = btn_BuyOne.y;
         btn_BuyTen.addEventListener("triggered",btn_Triggered);
         var _loc3_:LOL_MutilTextFieldIcon = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getLanguageStr(20146),String(_getInfos[param1].dust10),"UI_magic_money_000" + param1 + "");
         _loc3_.fontSize = 20;
         _loc3_.iconScale = 0.5;
         _loc3_.x = btn_BuyTen.x + 20;
         _loc3_.y = btn_BuyTen.y + btn_BuyTen.height + 10;
         mBox_Grren.addChild(_loc3_);
         moneyL = new LOL_MutilTextFieldIcon("",Tools.formateNum(_getInfos[param1].count10) + "",_getInfos[param1].type10 == "gold" ? "UI_money_gold_0_0000" : "UI_money_coin_0_0000",1118481,1118481);
         btn_BuyTen.addChild(moneyL);
         moneyL.x = btn_BuyTen.width / 2 - moneyL.width / 2;
         moneyL.y = btn_BuyTen.height / 2 - moneyL.height / 2 + 5;
         var _loc2_:Array = GlobalData.$mConfig.ploy_system_simple.welfare.free_times;
         var _loc22_:Array = GlobalData.$userData.records.welfare_times;
         if(_loc22_)
         {
            if(_loc2_[param1] == 1 && _loc22_[param1] == 0)
            {
               txt = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97087),22,1513239,"left",300,46);
               btn_BuyOne.addChild(txt);
               txt.x = btn_BuyOne.width / 2 - txt.width / 2 + 30;
               txt.y = btn_BuyOne.height / 2 - txt.height / 2 + 5;
               moneyGo.visible = false;
               btn_BuyOne.name = "free";
            }
         }
         else if(_loc2_[param1] == 1)
         {
            txt = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97087),22,1513239,"left",300,46);
            btn_BuyOne.addChild(txt);
            txt.x = btn_BuyOne.width / 2 - txt.width / 2 + 30;
            txt.y = btn_BuyOne.height / 2 - txt.height / 2 + 5;
            moneyGo.visible = false;
            btn_BuyOne.name = "free";
         }
         _loc13_ = 0;
         while(_loc13_ < arr.length)
         {
            for(var _loc11_:String in arr[_loc13_])
            {
               if(param1 == _loc13_)
               {
                  _loc15_ = _loc11_;
               }
            }
            _loc13_++;
         }
         mAvatarIcon = GameMapTools.newAvatarImgById(_loc15_);
         mAvatarIcon.x = _loc16_.width / 2 + 40;
         mAvatarIcon.y = _loc16_.y - 70;
         mBox_Grren.addChildAt(mAvatarIcon,1);
      }
      
      private function onTRIGGERED_exchangeClose(param1:Event) : void
      {
         if(mBox_Grren)
         {
            StarlingTools.removeChildrenClear(mBox_Grren);
            mBox_Grren.removeFromParent(true);
         }
         mBox_Grren = null;
      }
      
      private function gotoCoin() : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_pay",false,true);
      }
      
      private function btn_Triggered(param1:Event) : void
      {
         var _fun:Object;
         var str2:String;
         var _fun1:Object;
         var str1:String;
         var iii:int;
         var str:String;
         var send:*;
         var e:Event = param1;
         var t:LOL_Scale9Button = e.currentTarget as LOL_Scale9Button;
         var flag:int = 0;
         if(t.name == "buyone")
         {
            flag = 0;
         }
         else if(t.name == "free")
         {
            flag = -1;
            moneyGo.visible = true;
            txt.visible = false;
         }
         else
         {
            flag = 1;
         }
         if(flag == 1)
         {
            if(_getInfos[index].type10 == "gold")
            {
               if(GlobalData.$userData.gold < _getInfos[index].count10)
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10023),false,"A_6999_3");
                  return;
               }
            }
            else if(GlobalData.$userData.coin < _getInfos[index].count10)
            {
               _fun = {
                  "ok":gotoCoin,
                  "no":GlobalFunction.functionNull,
                  "aid":"A_2009_5"
               };
               str2 = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90051,_getInfos[index].count10),GlobalTextStyle.COLOR_W_Y_Y_G);
               GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(90010),str2,_fun);
               return;
            }
         }
         else if(flag == 0)
         {
            if(_getInfos[index].type == "gold")
            {
               if(GlobalData.$userData.gold < _getInfos[index].count)
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10023),false,"A_6999_3");
                  return;
               }
            }
            else if(GlobalData.$userData.coin < _getInfos[index].count)
            {
               _fun1 = {
                  "ok":gotoCoin,
                  "no":GlobalFunction.functionNull,
                  "aid":"A_2009_5"
               };
               str1 = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90051,_getInfos[index].count),GlobalTextStyle.COLOR_W_Y_Y_G);
               GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(90010),str1,_fun1);
               return;
            }
         }
         if(t.enabled)
         {
            send = function():void
            {
               if(_isActive)
               {
                  SendServiceAMFFun.send_user_welfare_get_reward(re_get,{"color":index});
               }
               else
               {
                  mReceiptDustBefore = Number(GlobalData.$userData.attrs.dust[index]);
                  SendServiceAMFFun.send_user_welfare_buy_dust(re_buy,{
                     "color":index,
                     "flag":flag
                  });
               }
            };
            if(_isFirstBuy < 1 && _freeData[index] >= _freeConfig[index] && index >= _isPopFirstIndex)
            {
               iii = 90478;
               str = GlobalLanguageStr.getLanguageStr(90547,flag ? _getInfos[index].count10 : _getInfos[index].count,flag ? _getInfos[index].dust10 : _getInfos[index].dust,GlobalLanguageStr.getLanguageStr(90478 + index),flag == 1 ? "十" : "一");
               GlobalFunction.popAlert("",str,{
                  "ok":send,
                  "no":GlobalFunction.functionNull
               });
               return;
            }
            if(_isActive)
            {
               SendServiceAMFFun.send_user_welfare_get_reward(re_get,{"color":index});
            }
            else
            {
               mReceiptDustBefore = Number(GlobalData.$userData.attrs.dust[index]);
               SendServiceAMFFun.send_user_welfare_buy_dust(re_buy,{
                  "color":index,
                  "flag":flag
               });
            }
         }
         else
         {
            if(t.text == GlobalLanguageStr.getLanguageStr(20146))
            {
               LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getLanguageStr(97014));
            }
            if(t.text == GlobalLanguageStr.getLanguageStr(97017))
            {
               LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getLanguageStr(97016));
            }
            if(t.text == GlobalLanguageStr.getLanguageStr(20377))
            {
               LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getLanguageStr(97015));
            }
         }
      }
      
      private function re_get(param1:Object) : void
      {
         if(stage == null)
         {
            return;
         }
         var _loc2_:Object = null;
         var _loc6_:int = 0;
         var _loc3_:LOL_Scale9Button = null;
         var _loc5_:Object = param1.data;
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.coin = _loc5_.coin;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.gold = _loc5_.gold;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.medal = _loc5_.medal;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.score = _loc5_.score;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.mark = _loc5_.mark;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.avatars = _loc5_.avatars;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.my_equips = _loc5_.my_equips;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.avatar_soul = _loc5_.avatar_soul;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.equip_soul = _loc5_.equip_soul;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.culture_book = _loc5_.culture_book;
         }
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin(0);
         for(var _loc4_:String in _loc5_.reward)
         {
            _loc2_ = GlobalFunction.getAwardByType(_loc4_,_loc5_.reward[_loc4_]);
            GlobalFunction.popAward(_loc4_,GlobalLanguageStr.getLanguageStr(90062,_loc2_.msg),_loc5_.reward[_loc4_],false);
         }
         _had_reward = _loc5_.had_reward;
         _loc6_ = 0;
         while(_loc6_ < _getBtns.length)
         {
            _loc3_ = _getBtns[_loc6_];
            if(_had_reward[_loc6_] == 0 && int(_tags[_loc6_][_infoData.number]) > 0)
            {
               _loc3_.enabled = true;
               _loc3_.text = GlobalLanguageStr.getLanguageStr(20173);
               (_loc3_.parent.getChildByName("effect") as LOL_EffectLight).start();
            }
            else if(_had_reward[_loc6_] == 1 && int(_tags[_loc6_][_infoData.number]) > 0)
            {
               _loc3_.enabled = false;
               _loc3_.text = GlobalLanguageStr.getLanguageStr(20377);
               (_loc3_.parent.getChildByName("effect") as LOL_EffectLight).stop();
            }
            else
            {
               _loc3_.enabled = false;
               _loc3_.text = GlobalLanguageStr.getLanguageStr(97017);
               (_loc3_.parent.getChildByName("effect") as LOL_EffectLight).stop();
            }
            _loc6_++;
         }
      }
      
      private function re_buy(param1:Object) : void
      {
         if(stage == null)
         {
            return;
         }
         _data = param1.data;
         _freeData = _data.welfare_times;
         _isFirstBuy = _data.coin_times;
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.coin = _data.coin;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.gold = _data.gold;
         }
         var _loc4_:Array = GlobalData.$userData.attrs.dust;
         var _loc2_:int = int(_data.welfare_info.pos_y);
         var _loc3_:int = _data.dust[_loc2_] - int(mReceiptDustBefore);
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.dust = _data.dust;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.records.welfare_times = _data.welfare_times;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.vip_exp = _data.vip_exp;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.vip_lv = _data.vip_lv;
         }
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateVip();
         _data["getInfos"] = _getInfos;
         _data["oldDust"] = _loc4_;
         GlobalFunction.showPanel_Center("panel_welfareinfo",false,true,_data);
      }
      
      private function btnEnable(param1:Boolean, param2:String = "", param3:Number = 25) : void
      {
         var _loc6_:int = 0;
         var _loc4_:LOL_Scale9Button = null;
         var _loc5_:Image = null;
         _loc6_ = 0;
         while(_loc6_ < _getBtns.length)
         {
            _loc4_ = _getBtns[_loc6_];
            _loc4_.enabled = param1;
            _loc5_ = _loc4_.parent.getChildByName("mh") as Image;
            if(param2 != "")
            {
               _loc4_.text = param2;
               if(_loc5_)
               {
                  if(param1)
                  {
                     _loc5_.visible = true;
                  }
                  else
                  {
                     _loc5_.visible = false;
                  }
               }
            }
            _loc6_++;
         }
      }
      
      private function updateItem(param1:int, param2:int, param3:int) : void
      {
         var item:ItemWelfare;
         var img:ItemWelfare;
         var y:int = param1;
         var x:int = param2;
         var num:int = param3;
         var update:* = function():void
         {
            if(img == null)
            {
               Starling.juggler.remove(_tween);
               flash();
            }
         };
         var flash:* = function():void
         {
            if(img)
            {
               img.removeFromParent();
            }
            if(item)
            {
               item.updateTag(num);
            }
         };
         _tags[y][x] = num;
         item = _goods[y][x];
         img = new ItemWelfare();
         img.data = {
            "index":_welfare_photo[x],
            "count":0,
            "data":_rewards[y]
         };
         img.pivotX = img.width / 2;
         img.pivotY = img.height / 2;
         img.x = item.x - 50;
         img.y = item.y - 100;
         img.scaleX = img.scaleY = 2;
         if(item)
         {
            item.parent.addChild(img);
         }
         _tween = new Tween(img,0.8);
         _tween.animate("scaleX",1);
         _tween.animate("scaleY",1);
         _tween.animate("alpha",0);
         _tween.moveTo(item.x,item.y);
         _tween.onUpdate = update;
         _tween.onComplete = flash;
         Starling.juggler.add(_tween);
      }
      
      private function endFlashBig(param1:int) : void
      {
         var _loc4_:ItemWelfare = null;
         var _loc6_:int = 0;
         var _loc2_:LOL_Scale9Button = null;
         var _loc3_:Image = null;
         var _loc5_:String = "stop";
         SoundManager.getOnlyExample().playSound(_loc5_);
         _loc6_ = 0;
         while(_loc6_ < 4)
         {
            _loc2_ = _getBtns[_loc6_];
            _loc3_ = _loc2_.parent.getChildByName("mh") as Image;
            if(_had_reward[_loc6_] == 0 && int(_tags[_loc6_][param1]) > 0)
            {
               _loc2_.enabled = true;
               (_loc2_.parent.getChildByName("effect") as LOL_EffectLight).start();
               if(_loc3_)
               {
                  _loc3_.visible = true;
               }
               _loc2_.showGlow();
               _loc2_.text = GlobalLanguageStr.getLanguageStr(20173);
            }
            else
            {
               _loc2_.enabled = false;
               _loc2_.clearGlow();
               if(_loc3_)
               {
                  _loc3_.visible = false;
               }
               if(int(_tags[_loc6_][param1]) > 0)
               {
                  _loc2_.text = GlobalLanguageStr.getLanguageStr(20377);
               }
               else
               {
                  _loc2_.text = GlobalLanguageStr.getLanguageStr(97017);
               }
            }
            _loc2_.parent.getChildByName("dust").visible = false;
            _loc6_++;
         }
         _loc4_ = _goods[0][param1];
         _selectBig.visible = true;
         _selectBig.x = _loc4_.x + _loc4_.parent.x + 10;
         _selectBig.y = 70;
         _autoIndex = 0;
         _delayCur = 0;
      }
      
      private function autoFlashBig(param1:int) : void
      {
         _isDelayCall = true;
         _timer = new Timer(_delay);
         _timer.addEventListener("timer",time_TickBig);
         _timer.start();
      }
      
      private function time_TickBig(param1:TimerEvent) : void
      {
         var _loc2_:ItemWelfare = null;
         var _loc5_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:String = "roll";
         SoundManager.getOnlyExample().playSound(_loc4_);
         if(_autoIndex >= int(_config.number_pool))
         {
            _autoIndex = 0;
         }
         _loc5_ = 0;
         loop0:
         while(_loc5_ < 5)
         {
            _loc3_ = 0;
            while(_loc3_ < 4)
            {
               _loc2_ = _goods[_loc3_][_loc5_] as ItemWelfare;
               if(_loc5_ == _autoIndex)
               {
                  _selectBig.visible = true;
                  _selectBig.x = _loc2_.x + _loc2_.parent.x + 10;
                  _selectBig.y = 70;
                  if(_delayCur >= _delayAll)
                  {
                     if(_isDelayCall)
                     {
                        _timer.delay = _delay + 300;
                        _delayCur = 0;
                        _delayAll = 4;
                        _isDelayCall = false;
                     }
                     else if(int(_infoData.number) == _loc5_)
                     {
                        clearTimer();
                        endFlashBig(_infoData.number);
                        break loop0;
                     }
                  }
               }
               _loc3_++;
            }
            _loc5_++;
         }
         _autoIndex = _autoIndex + 1;
         _delayCur = _delayCur + 1;
      }
      
      private function clearTimer() : void
      {
         if(_timer)
         {
            _timer.stop();
            _timer.removeEventListener("timer",time_TickBig);
            _timer = null;
         }
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         Starling.juggler.remove(_tween);
         clearTimer();
         GlobalData.$mEventDispatcher.removeEventListener("update_panel_welfareinfo",UPDATE_PANEL_WELFAREINFO);
         if(_spRule)
         {
            _spRule.removeEventListener("touch",onTRIGGERED_help);
         }
         StarlingTools.removeChildrenClear(this);
      }
   }
}

