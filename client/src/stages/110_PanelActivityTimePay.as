package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.element.LOL_TextField;
   import com.meng52.game.ui.element.LOL_TextPop;
   import com.meng52.game.ui.element.LOL_TimeStatus;
   import com.meng52.game.ui.screen.PanelBase;
   import com.meng52.game.ui.screen.PanelCenterTaskAward;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import starling.animation.Tween;
   import starling.core.Starling;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.filters.ColorMatrixFilter;
   
   public class PanelActivityTimePay extends PanelBase
   {
      
      private var _avatarImg:Image;
      
      private var _frameBg:Scale9Image;
      
      private var _infoBtn:LOL_Scale9Button;
      
      private var _getBtn:LOL_Scale9Button;
      
      private var _payBtn:LOL_Scale9Button;
      
      private var _timeStatus:LOL_TimeStatus;
      
      private var _lineBg:Image;
      
      private var _infoText:LOL_MutilTextFieldIcon;
      
      private var mInfo:LOL_TextField;
      
      private var _sp:Sprite;
      
      private var _textPop:LOL_TextPop;
      
      private var _data:Array = [];
      
      private var _award:Array = [];
      
      private var _taskCfg:Object;
      
      private var _myTask:int;
      
      private var _current:Object;
      
      private var _wAll:Number;
      
      private var _numW:Number;
      
      private var _isGetedAll:Boolean = true;
      
      private var _firstName:String;
      
      private var mNum:Number;
      
      private var _dataInfo:Object;
      
      public function PanelActivityTimePay()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         _taskCfg = GlobalData.$mConfig.task.time_pay;
         _myTask = int(GlobalData.$userData.task.time_pay);
         mImgBg = GlobalFunction.createImage("png_activity_bg",true);
         var _loc2_:ColorMatrixFilter = new ColorMatrixFilter();
         _loc2_.adjustBrightness(-0.2);
         _loc2_.adjustContrast(0.6);
         _loc2_.adjustSaturation(0.5);
         _loc2_.adjustHue(_taskCfg.hue / 180);
         mImgBg.filter = _loc2_;
         mImgBg.y = -180;
         addChild(mImgBg);
         var _loc5_:Avatar = new Avatar(_taskCfg.show_avatar);
         _avatarImg = GlobalFunction.createImage(_loc5_.resId);
         if(_taskCfg.direction == 0)
         {
            _avatarImg.x = (GlobalData.$mStageWidth - _avatarImg.width) / 2 - 100;
         }
         else
         {
            _avatarImg.x = (GlobalData.$mStageWidth - _avatarImg.width) / 2 + 100;
         }
         _avatarImg.y = (GlobalData.$mStageHeight - _avatarImg.height) / 2 - 110 - 140;
         addChild(_avatarImg);
         _frameBg = GlobalFunction.createScale9Image("UI_bg_9slice_5_0000",GlobalData.$mStageWidth - 50,260,new Rectangle(25,25,10,10));
         _frameBg.x = (GlobalData.$mStageWidth - _frameBg.width) / 2;
         _frameBg.y = GlobalData.$center_height_curr - 110 - 490;
         addChild(_frameBg);
         _infoBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90485),150,70);
         if(MainConfig.$isEnglish)
         {
            _infoBtn.fontSize = 18;
         }
         _infoBtn.x = 55;
         _infoBtn.y = _frameBg.y + _frameBg.height + 5;
         addChild(_infoBtn);
         _infoBtn.addEventListener("triggered",info_Triggered);
         _getBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20173),150,70);
         _getBtn.x = _infoBtn.x + _infoBtn.width + 40;
         _getBtn.y = _infoBtn.y;
         addChild(_getBtn);
         _getBtn.addEventListener("triggered",get_Trigerred);
         _payBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20185),150,70);
         _payBtn.x = _getBtn.x + _getBtn.width + 40;
         _payBtn.y = _infoBtn.y;
         addChild(_payBtn);
         _payBtn.addEventListener("triggered",pay_Triggered);
         var _loc4_:int = (_taskCfg.begin_time as Date).time * 0.001;
         var _loc6_:int = (_taskCfg.end_time as Date).time * 0.001;
         var _loc3_:Number = SendAndSelect.$systemTimer_nowSecond;
         _timeStatus = new LOL_TimeStatus("paneltimepay");
         _timeStatus.refresh(_loc6_ - _loc3_,GlobalLanguageStr.getLanguageStr(25061),GlobalLanguageStr.getLanguageStr(25060));
         _timeStatus.x = 20;
         addChild(_timeStatus);
         _textPop = new LOL_TextPop(250,100,_taskCfg.direction == 0 ? "textpop_left" : "textpop_right");
         _getBtn.enabled = false;
         getGift();
         if(!_isGetedAll)
         {
            _textPop.show(GlobalLanguageStr.getLanguageStr(97018));
         }
         GlobalData.$mEventDispatcher.addEventListener("update_shop_coin",UPDATE_SHOP_COIN);
         if(_taskCfg.direction == 0)
         {
            _textPop.x = GlobalData.$mStageWidth / 2;
         }
         else
         {
            _textPop.x = GlobalData.$mStageWidth / 2 - _textPop.width;
         }
         _textPop.y = _avatarImg.y;
         addChild(_textPop);
      }
      
      private function getGift() : void
      {
         var _loc4_:String = null;
         var _loc2_:* = undefined;
         var _loc5_:int = 0;
         _isGetedAll = true;
         StarlingTools.removeChildrenClear(_sp,false);
         _myTask = int(GlobalData.$userData.task.time_pay);
         _data = [];
         _award = [];
         _sp = new Sprite();
         addChild(_sp);
         var _loc3_:Array = [];
         _loc5_ = 0;
         while(_loc5_ < _taskCfg.content.length)
         {
            for(var _loc1_:Object in _taskCfg.content[_loc5_].gift)
            {
               _loc4_ = _loc1_.toString();
               _loc2_ = _taskCfg.content[_loc5_].gift[_loc1_];
            }
            if(_loc5_ < _myTask)
            {
               _loc3_.push({
                  "type":_loc4_,
                  "item":_loc2_,
                  "need":_taskCfg.content[_loc5_].need,
                  "data":_taskCfg,
                  "geted":true
               });
            }
            else
            {
               _isGetedAll = false;
               _data.push({
                  "type":_loc4_,
                  "item":_loc2_,
                  "need":_taskCfg.content[_loc5_].need,
                  "data":_taskCfg,
                  "geted":false
               });
            }
            _loc5_++;
         }
         _dataInfo = _loc3_.concat(_data);
         if(_loc3_.length > 0)
         {
            _data = _data.concat(_loc3_);
         }
         if(_isGetedAll)
         {
            if(_data.length == 1)
            {
               getOne();
            }
            else
            {
               getAll();
            }
         }
         else if(_isGetedAll)
         {
            getAll();
         }
         else if(_data.length == 1)
         {
            getOne();
         }
         else
         {
            addGift();
         }
      }
      
      private function getAll() : void
      {
         var _loc9_:int = 0;
         var _loc11_:int = 0;
         var _loc2_:Object = null;
         var _loc1_:* = undefined;
         var _loc8_:Array = null;
         var _loc5_:ColorMatrixFilter = null;
         var _loc4_:Sprite = null;
         var _loc6_:Sprite = null;
         var _loc10_:Number = NaN;
         StarlingTools.removeChildrenClear(_sp);
         _textPop.show(GlobalLanguageStr.getLanguageStr(97019));
         _getBtn.visible = false;
         var _loc7_:Image = GlobalFunction.createImage("UI_wordbg_yellow_0_0000");
         _loc7_.width = _frameBg.width - 50;
         _loc7_.x = 50;
         _loc7_.y = _frameBg.y + 10;
         _sp.addChild(_loc7_);
         var _loc3_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(90462),_frameBg.width - 50,30);
         _loc3_.fontSize = 25;
         _loc3_.fontColor = 1513239;
         _loc3_.x = MainConfig.$isEnglish ? _frameBg.x + _frameBg.width / 2 - 136 : _frameBg.x + _frameBg.width / 2 - 75;
         _loc3_.y = _loc7_.y;
         _sp.addChild(_loc3_);
         _wAll = _frameBg.x + 80;
         if(_data.length > 0)
         {
            if(_data.length > 5)
            {
               _loc9_ = 5;
            }
            else if(_data.length > 7)
            {
               _loc9_ = 7;
            }
            else
            {
               _loc9_ = int(_data.length);
            }
            _numW = (_frameBg.width - _loc9_ * 75 - (_loc9_ - 1) * 10 - _wAll) / 2 + 20;
         }
         _loc11_ = 0;
         while(_loc11_ < _data.length)
         {
            _loc2_ = null;
            if(_data[_loc11_]["type"] == "avatar" || _data[_loc11_]["type"] == "avatar_soul" || _data[_loc11_]["type"] == "equip" || _data[_loc11_]["type"] == "equip_soul")
            {
               _loc2_ = GlobalFunction.getAwardByType(_data[_loc11_]["type"],_data[_loc11_]["item"],false,null,"",true,0.8);
            }
            else
            {
               _loc2_ = GlobalFunction.getAwardByType(_data[_loc11_]["type"],_data[_loc11_]["item"]);
            }
            _loc1_ = _loc2_.ui;
            if(_loc11_ == 0)
            {
               _firstName = _loc2_.msg;
               _loc8_ = _firstName.split("\n");
               _firstName = _loc8_[0];
               mInfo = new LOL_TextField(_firstName,200,30);
               mInfo.fontColor = 10027008;
               mInfo.touchable = false;
            }
            _loc5_ = new ColorMatrixFilter();
            _loc5_.adjustSaturation(-1);
            if(_loc2_.text)
            {
               _loc2_.text.filter = null;
            }
            if(_data[_loc11_]["geted"] == true)
            {
               _loc4_ = new Sprite();
               _loc4_.addChild(_loc1_);
               _loc6_ = geted();
               _loc6_.y = 40;
               _loc4_.addChild(_loc6_);
               _loc1_.filter = _loc5_;
               _loc1_ = _loc4_;
            }
            else
            {
               _loc1_.filter = _loc5_;
            }
            _sp.addChild(_loc1_);
            _loc10_ = 45;
            if(_data.length <= 10)
            {
               if(_data.length > 5)
               {
                  if(_loc11_ <= 4)
                  {
                     _loc1_.y = _frameBg.y + _loc10_;
                  }
                  else
                  {
                     _loc1_.y = _frameBg.y + _loc10_ + 90;
                  }
               }
               else
               {
                  _loc1_.y = _frameBg.y + _loc10_ + 40;
               }
               if(_loc11_ == 5)
               {
                  _wAll = _frameBg.x + 80;
               }
               _loc1_.x = _wAll + _numW - _loc1_.width / 2;
            }
            if(_data.length > 10)
            {
               if(_data.length > 7)
               {
                  if(_loc11_ <= 6)
                  {
                     _loc1_.y = _frameBg.y + _loc10_;
                  }
                  else
                  {
                     _loc1_.y = _frameBg.y + _loc10_ + 90;
                  }
               }
               else
               {
                  _loc1_.y = _frameBg.y + _loc10_ + 40;
               }
               if(_loc11_ == 7)
               {
                  _wAll = _frameBg.x + 80;
               }
               _loc1_.x = _wAll + _numW - _loc1_.width / 2 - 82;
            }
            if(_data[_loc11_]["type"] == "equip")
            {
               if(_data.length > 10)
               {
                  _loc1_.x = _wAll + _numW - _loc1_.width / 2 - 83;
               }
               else
               {
                  _loc1_.x = _wAll + _numW - _loc1_.width / 2 - 5;
               }
            }
            _wAll += _loc2_.width - 5;
            if(_data[_loc11_]["type"] == "avatar")
            {
               _wAll -= 15;
            }
            if(_data[_loc11_]["type"] == "equip")
            {
               _wAll -= 8;
            }
            if(_data[_loc11_]["type"] == "gold")
            {
               _wAll += 15;
            }
            if(_data[_loc11_]["type"] == "avatar_soul")
            {
               _wAll -= 16;
            }
            if(_data[_loc11_]["type"] == "culture_book")
            {
               _wAll += 17;
            }
            if(_data[_loc11_]["type"] == "equip_soul")
            {
               _wAll -= 5;
            }
            if(_data[_loc11_]["type"] == "medal")
            {
               _wAll += 13;
            }
            if(_data[_loc11_]["type"] == "dust")
            {
               _wAll += 13;
            }
            if(_data[_loc11_]["type"] == "coin")
            {
               _wAll += 13;
            }
            if(_data[_loc11_]["type"] == "mark")
            {
               _wAll += 13;
            }
            if(_data[_loc11_]["type"] == "score")
            {
               _wAll += 13;
            }
            if(_data[_loc11_]["type"] == "dn_stone")
            {
               _wAll += 13;
            }
            if(_data[_loc11_]["type"] == "energy")
            {
               _wAll += 13;
            }
            if(_data[_loc11_]["type"] == "fragment_energy")
            {
               _wAll += 13;
            }
            if(_data[_loc11_]["type"] == "exp")
            {
               _wAll += 13;
            }
            if(_data[_loc11_]["type"] == "box")
            {
               _wAll += 13;
            }
            if(_data[_loc11_]["type"] == "key")
            {
               _wAll += 13;
            }
            _loc11_++;
         }
      }
      
      private function geted() : Sprite
      {
         var _loc3_:Sprite = new Sprite();
         var _loc2_:Quad = new Quad(75,20,0);
         _loc2_.alpha = 0.8;
         _loc3_.addChild(_loc2_);
         var _loc1_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(20377),75,20);
         _loc1_.fontColor = 16711680;
         _loc1_.hAlign = "center";
         _loc1_.y = -1;
         _loc3_.addChild(_loc1_);
         _loc3_.touchable = false;
         return _loc3_;
      }
      
      private function addGift() : void
      {
         var _loc3_:* = null;
         var _loc9_:int = 0;
         var _loc10_:int = 0;
         var _loc2_:Object = null;
         var _loc1_:* = undefined;
         var _loc8_:Array = null;
         var _loc6_:ColorMatrixFilter = null;
         var _loc5_:Sprite = null;
         var _loc7_:Sprite = null;
         _wAll = _frameBg.x + 80;
         if(_data.length > 0)
         {
            _loc9_ = _data.length - 1 > 5 ? 5 : _data.length - 1;
            _numW = (_frameBg.width - _loc9_ * 75 - (_loc9_ - 1) * 10 - _wAll) / 2 + 12;
         }
         var _loc4_:Number = 0;
         _loc10_ = 0;
         while(_loc10_ < _data.length)
         {
            if(_loc10_ == 0)
            {
               _current = PanelCenterTaskAward.checkTask("time_pay",_data[_loc10_],_data[_loc10_]["data"]);
            }
            _loc2_ = null;
            if(_data[_loc10_]["type"] == "avatar" || _data[_loc10_]["type"] == "avatar_soul" || _data[_loc10_]["type"] == "equip" || _data[_loc10_]["type"] == "equip_soul")
            {
               _loc2_ = GlobalFunction.getAwardByType(_data[_loc10_]["type"],_data[_loc10_]["item"],false,null,"",true,0.8);
            }
            else
            {
               _loc2_ = GlobalFunction.getAwardByType(_data[_loc10_]["type"],_data[_loc10_]["item"]);
            }
            _loc1_ = _loc2_.ui;
            if(_loc10_ == 0)
            {
               _firstName = _loc2_.msg;
               _loc8_ = _firstName.split("\n");
               _firstName = _loc8_[0];
               mInfo = new LOL_TextField(_firstName,200,30);
               mInfo.fontColor = 10027008;
               mInfo.touchable = false;
            }
            _loc6_ = new ColorMatrixFilter();
            _loc6_.adjustSaturation(-1);
            if(_loc2_.text)
            {
               _loc2_.text.filter = null;
            }
            if(_data[_loc10_]["geted"] == true)
            {
               _loc5_ = new Sprite();
               _loc5_.addChild(_loc1_);
               _loc7_ = geted();
               _loc7_.y = 40;
               _loc5_.addChild(_loc7_);
               _loc1_.filter = _loc6_;
               _loc1_ = _loc5_;
            }
            else
            {
               _loc1_.filter = _loc6_;
            }
            _loc1_.x = _wAll + _numW - _loc1_.width / 2;
            _loc1_.y = _frameBg.y + 160;
            _sp.addChild(_loc1_);
            if(_data[_loc10_]["type"] == "equip")
            {
               _loc1_.x = _wAll + _numW - _loc1_.width / 2 - 5;
            }
            _wAll += _loc2_.width - 5;
            if(_data[_loc10_]["type"] == "avatar")
            {
               _wAll -= 15;
            }
            if(_data[_loc10_]["type"] == "gold")
            {
               _wAll += 15;
            }
            if(_data[_loc10_]["type"] == "equip")
            {
               _wAll -= 8;
            }
            if(_data[_loc10_]["type"] == "equip_soul")
            {
               _wAll -= 5;
            }
            if(_data[_loc10_]["type"] == "key")
            {
               _wAll += 13;
            }
            if(_data[_loc10_]["type"] == "avatar_soul")
            {
               _wAll -= 16;
            }
            if(_data[_loc10_]["type"] == "culture_book")
            {
               _wAll += 17;
            }
            if(_data[_loc10_]["type"] == "medal")
            {
               _wAll += 13;
            }
            if(_data[_loc10_]["type"] == "dust")
            {
               _wAll += 13;
            }
            if(_data[_loc10_]["type"] == "coin")
            {
               _wAll += 13;
            }
            if(_data[_loc10_]["type"] == "mark")
            {
               _wAll += 13;
            }
            if(_data[_loc10_]["type"] == "score")
            {
               _wAll += 13;
            }
            if(_data[_loc10_]["type"] == "dn_stone")
            {
               _wAll += 13;
            }
            if(_data[_loc10_]["type"] == "energy")
            {
               _wAll += 13;
            }
            if(_data[_loc10_]["type"] == "fragment_energy")
            {
               _wAll += 13;
            }
            if(_data[_loc10_]["type"] == "exp")
            {
               _wAll += 13;
            }
            if(_data[_loc10_]["type"] == "box")
            {
               _wAll += 13;
            }
            if(_loc10_ > 4)
            {
               _loc1_.visible = false;
            }
            _award.push(_loc1_);
            _loc10_++;
         }
         autoGift();
      }
      
      private function getOne() : void
      {
         var _loc4_:Sprite = null;
         var _loc6_:Sprite = null;
         var _loc3_:LOL_TextField = null;
         var _loc9_:Array = null;
         var _loc7_:int = 0;
         StarlingTools.removeChildrenClear(_sp);
         _current = PanelCenterTaskAward.checkTask("time_pay",_data[0],_data[0]["data"]);
         var _loc2_:Object = null;
         if(_data[0]["type"] == "avatar" || _data[0]["type"] == "avatar_soul" || _data[0]["type"] == "equip" || _data[0]["type"] == "equip_soul")
         {
            _loc2_ = GlobalFunction.getAwardByType(_data[0]["type"],_data[0]["item"],false,null,"",true,0.8);
         }
         else
         {
            _loc2_ = GlobalFunction.getAwardByType(_data[0]["type"],_data[0]["item"]);
         }
         var _loc1_:* = _loc2_.ui;
         var _loc5_:ColorMatrixFilter = new ColorMatrixFilter();
         _loc5_.adjustSaturation(-1);
         if(_loc2_.text)
         {
            _loc2_.text.filter = null;
         }
         if(_data[0]["geted"] == true)
         {
            _loc4_ = new Sprite();
            _loc4_.addChild(_loc1_);
            _loc6_ = geted();
            _loc6_.y = 55;
            if(_data[0]["type"] != "avatar" || _data[0]["type"] != "avatar_soul")
            {
               _loc6_.y = 50;
            }
            _loc4_.addChild(_loc6_);
            _loc1_.filter = _loc5_;
            _loc1_ = _loc4_;
         }
         else
         {
            _loc1_.filter = _loc5_;
         }
         _loc1_.x = _frameBg.x + (_frameBg.width - _loc1_.width) / 2;
         _loc1_.y = _frameBg.y + (_frameBg.height - _loc1_.height) / 2;
         _sp.addChild(_loc1_);
         _award.push(_loc1_);
         var _loc8_:Image = GlobalFunction.createImage("UI_wordbg_yellow_0_0000");
         _loc8_.width = _frameBg.width - 50;
         _loc8_.x = 50;
         _loc8_.y = _frameBg.y + 10;
         _sp.addChild(_loc8_);
         if(_data[0]["geted"] == true)
         {
            _loc3_ = new LOL_TextField(GlobalLanguageStr.getLanguageStr(90462),_frameBg.width - 50,30);
            _loc3_.fontSize = 25;
            _loc3_.fontColor = 1513239;
            _sp.addChild(_loc3_);
            _loc8_.x = 50;
            _loc8_.y = _frameBg.y + 10;
            _loc3_.x = MainConfig.$isEnglish ? _frameBg.x + _frameBg.width / 2 - 136 : _frameBg.x + _frameBg.width / 2 - 75;
            _loc3_.y = _loc8_.y;
            _getBtn.visible = false;
            _textPop.show(GlobalLanguageStr.getLanguageStr(97019));
         }
         else
         {
            _textPop.show(GlobalLanguageStr.getLanguageStr(97018));
            _firstName = _loc2_.msg;
            _loc9_ = _firstName.split("\n");
            _firstName = _loc9_[0];
            mInfo = new LOL_TextField(_firstName,200,30);
            mInfo.fontColor = 10027008;
            mInfo.touchable = false;
            mNum = mInfo.textBounds.width;
            _loc7_ = _current.need - _current.curr;
            _infoText = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getLanguageStr(90416),_loc7_ + " " + GlobalLanguageStr.getLanguageStr(90417),"UI_money_coin_0_0000",1513239,1513239);
            _infoText.x = MainConfig.$isEA ? _frameBg.x + (_frameBg.width - _infoText.textFieldWidth) / 2 - mInfo.textBounds.width / 2 - 9 : _frameBg.x + (_frameBg.width - _infoText.textFieldWidth) / 2 - mNum / 2;
            _sp.addChild(_infoText);
            _loc8_.x = 50;
            _loc8_.y = _loc1_.y + _loc1_.height;
            _infoText.y = _loc8_.y - 2;
            mInfo.x = _infoText.x + _infoText.width - 15;
            mInfo.y = _infoText.y + 5;
            _sp.addChild(mInfo);
            if(!(!_current.ok && _loc7_ >= 0))
            {
               _infoText.text(GlobalLanguageStr.getLanguageStr(90417),null,null);
               _getBtn.enabled = true;
               _getBtn.showGlow();
               _infoText.x = MainConfig.$isEA ? _frameBg.x + (_frameBg.width - _infoText.textFieldWidth) / 2 - mInfo.textBounds.width / 2 - 9 : _frameBg.x + (_frameBg.width - _infoText.text1_Width) / 2 - mNum - (mInfo.text.length <= 5 ? 20 : 0);
               mInfo.x = MainConfig.$isEnglish ? _infoText.x + _infoText.text1_Width + 70 : _infoText.x + _infoText.text1_Width + 55;
               changeGiftColor();
            }
         }
      }
      
      private function changeGiftColor() : void
      {
      }
      
      private function autoGift() : void
      {
         var _loc1_:Tween = null;
         var _loc5_:int = 0;
         var _loc3_:* = undefined;
         var _loc4_:* = _award[0];
         var _loc2_:int = 0;
         _loc5_ = 1;
         while(_loc5_ < _award.length)
         {
            _loc3_ = _award[_loc5_];
            _loc1_ = new Tween(_loc3_,0.2);
            _loc1_.animate("x",_award[_loc5_].x - 80);
            if(_award.length - 1 >= 4 && _loc2_ >= 4 && _loc2_ < 5)
            {
               _loc3_.visible = true;
            }
            if(_loc5_ == 1)
            {
               _loc1_.onComplete = otherComplete;
               _loc1_.onCompleteArgs = [_loc4_];
            }
            Starling.juggler.add(_loc1_);
            _loc2_++;
            _loc5_++;
         }
      }
      
      private function otherComplete(param1:*) : void
      {
         var first:* = param1;
         var onComplete1:* = function():void
         {
            Starling.juggler.tween(first,0.2,{
               "x":_frameBg.x + (_frameBg.width - first.width) / 2,
               "y":_frameBg.y + 15,
               "onComplete":onComplete3
            });
         };
         var onComplete3:* = function():void
         {
            if(_data[0]["type"] == "equip" || _data[0]["type"] == "equip")
            {
               Starling.juggler.tween(first,0.3,{
                  "scaleX":0.9,
                  "scaleY":0.9,
                  "onComplete":onComplete4,
                  "transition":"easeInOut"
               });
            }
            else
            {
               Starling.juggler.tween(first,0.3,{
                  "scaleX":1,
                  "scaleY":1,
                  "onComplete":onComplete4,
                  "transition":"easeInOut"
               });
            }
         };
         var onComplete4:* = function():void
         {
            var _loc2_:* = undefined;
            _loc2_ = _loc2_ = {
               "id":"e001",
               "x":first.x + 30 + 10,
               "y":first.y + 30,
               "sc":1.5
            };
            _loc2_.par = _sp;
            DisplayTools.addEffectOne(_loc2_);
            var _loc1_:int = _current.need - _current.curr;
            _lineBg = GlobalFunction.createImage("UI_wordbg_yellow_0_0000");
            _lineBg.width = 480;
            _lineBg.scaleX = 1;
            _lineBg.scaleY = 0.5;
            _lineBg.pivotX = _lineBg.width / 2;
            _lineBg.pivotY = _lineBg.height / 2;
            _lineBg.x = _frameBg.x + _frameBg.width / 2;
            _lineBg.y = _frameBg.y + 115;
            _sp.addChild(_lineBg);
            Starling.juggler.tween(_lineBg,0.2,{
               "scaleX":2,
               "scaleY":1
            });
            _sp.addChild(mInfo);
            mNum = mInfo.textBounds.width;
            _infoText = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getLanguageStr(90416),_loc1_ + " " + GlobalLanguageStr.getLanguageStr(90417),"UI_money_coin_0_0000",1513239,1513239);
            _infoText.scaleY = 0.5;
            _infoText.pivotY = _infoText.height / 2;
            _infoText.y = _lineBg.y;
            _sp.addChild(_infoText);
            mInfo.y = _infoText.y - 6;
            Starling.juggler.tween(_infoText,0.2,{
               "scaleX":1,
               "scaleY":1
            });
            if(!_current.ok && _loc1_ >= 0)
            {
               if(MainConfig.$isEA)
               {
                  mInfo.visible = false;
               }
               _infoText.text(GlobalLanguageStr.getLanguageStr(90416),_loc1_ + " " + GlobalLanguageStr.getLanguageStr(90417),"UI_money_coin_0_0000");
               _getBtn.enabled = false;
               _getBtn.clearGlow();
               _infoText.x = MainConfig.$isEA ? _frameBg.x + (_frameBg.width - _infoText.textFieldWidth) / 2 - mInfo.textBounds.width / 2 + 54 : _frameBg.x + (_frameBg.width - _infoText.textFieldWidth) / 2 - mInfo.textBounds.width / 2;
               mInfo.x = MainConfig.$isEA ? _infoText.x + _infoText.width - 6 : _infoText.x + _infoText.width - 15;
            }
            else
            {
               _infoText.text(GlobalLanguageStr.getLanguageStr(90417),null,null);
               _getBtn.enabled = true;
               _getBtn.showGlow();
               _infoText.x = MainConfig.$isEA ? (480 - _infoText.text1_Width - mNum) / 2 - 23 : (480 - _infoText.text1_Width - mNum) / 2 + 20;
               mInfo.x = MainConfig.$isEA ? _infoText.x + _infoText.text1_Width + 98 : (MainConfig.$isEnglish ? _infoText.x + _infoText.text1_Width + 70 : _infoText.x + _infoText.text1_Width + 55);
               changeGiftColor();
            }
            first.filter = null;
         };
         Starling.juggler.tween(first,0.2,{
            "x":_frameBg.x + 10,
            "y":_frameBg.y + _frameBg.height / 2 - first.height / 2,
            "onComplete":onComplete1
         });
      }
      
      private function UPDATE_SHOP_COIN(param1:Event) : void
      {
         var _loc2_:String = null;
         if(_data.length == 0)
         {
            return;
         }
         _current = PanelCenterTaskAward.checkTask("time_pay",_data[0],_data[0]["data"]);
         var _loc3_:int = _current.need - _current.curr;
         if(_loc3_ <= 0)
         {
            if(_infoText)
            {
               _infoText.text(GlobalLanguageStr.getLanguageStr(90417),null,null);
               _infoText.x = MainConfig.$isEA ? (480 - _infoText.text1_Width - mNum) / 2 - 23 : (480 - _infoText.text1_Width - mNum) / 2 + 20;
               mInfo.x = MainConfig.$isEA ? _infoText.x + _infoText.text1_Width + 98 : (MainConfig.$isEnglish ? _infoText.x + _infoText.text1_Width + 70 : _infoText.x + _infoText.text1_Width + 55);
            }
            if(_data[0].geted == false)
            {
               _getBtn.enabled = true;
               _getBtn.showGlow();
               changeGiftColor();
            }
            if(_isGetedAll)
            {
               if(_data.length > 1)
               {
                  getAll();
               }
               else
               {
                  getOne();
               }
               _getBtn.visible = false;
               _getBtn.clearGlow();
            }
            _loc2_ = "";
            if(_isGetedAll)
            {
               _loc2_ = GlobalLanguageStr.getLanguageStr(97019);
            }
            else
            {
               _loc2_ = GlobalLanguageStr.getLanguageStr(97018);
            }
            _textPop.show(_loc2_);
         }
         else
         {
            if(_infoText)
            {
               _infoText.text(GlobalLanguageStr.getLanguageStr(90416),_loc3_ + " " + GlobalLanguageStr.getLanguageStr(90417),"UI_money_coin_0_0000");
               _infoText.x = _frameBg.x + (_frameBg.width - _infoText.textFieldWidth) / 2 - mInfo.textBounds.width / 2;
               mInfo.x = _infoText.x + _infoText.width - 15;
            }
            _getBtn.enabled = false;
            _getBtn.clearGlow();
         }
      }
      
      private function pay_Triggered(param1:Event) : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_pay",false,true);
      }
      
      private function info_Triggered(param1:Event) : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_timepayinfo",false,true,_dataInfo);
      }
      
      private function get_Trigerred(param1:Event) : void
      {
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc2_:int = 0;
         if(GlobalData.$userData_avatarNum >= int(GlobalData.$userData.attrs.avatar_len) && _data[0]["type"] == "avatar")
         {
            GlobalFunction.popAvatarLen();
         }
         else if(Tools.getElementNum(GlobalData.$userData.my_equips) >= int(GlobalData.$mConfig_simple.equip_config[0]) && _data[0]["type"] == "equip")
         {
            GlobalFunction.popEquipFull();
         }
         else
         {
            _loc3_ = (_taskCfg.begin_time as Date).time * 0.001;
            _loc4_ = (_taskCfg.end_time as Date).time * 0.001;
            if(_data.length == 0)
            {
               GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(97010));
               return;
            }
            if(_getBtn.enabled == false)
            {
               _loc2_ = _current.need - _current.curr;
               if(_loc2_ <= 0)
               {
                  return;
               }
               GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97009,_loc2_,_firstName),GlobalTextStyle.COLOR_W_Y_Y_G));
               return;
            }
            if(SendAndSelect.$systemTimer_nowSecond < _loc3_ || SendAndSelect.$systemTimer_nowSecond >= _loc4_)
            {
               GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(90144));
               return;
            }
            SendServiceAMFFun.send_user_task_done(this.reFun,{
               "task_key":"time_pay",
               "type":"time_pay",
               "giftType":_data[0]["type"],
               "awardItem":_data[0]["item"],
               "task_code":_myTask
            });
         }
      }
      
      private function reFun(param1:Object) : void
      {
         if(stage == null)
         {
            return;
         }
         var _loc6_:String = null;
         var _loc2_:String = null;
         var _loc8_:String = null;
         var _loc7_:* = undefined;
         var _loc5_:Array = null;
         var _loc4_:int = 0;
         var _loc3_:Object = null;
         if(param1)
         {
            _loc6_ = "sound03";
            SoundManager.getOnlyExample().playSound(_loc6_);
            GuideMaster.getOnlyExample().guideWait();
            _loc2_ = param1["params"]["type"];
            _loc8_ = param1["params"]["giftType"];
            _loc7_ = param1["params"]["awardItem"];
            _loc5_ = null;
            _loc4_ = 0;
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.task = param1.data.task;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.catena = param1.data.catena;
            }
            if(param1.data.attrs)
            {
               if(!GlobalFunction.isVersionedProfileReceipt(param1))
               {
                  GlobalData.$userData.attrs = param1.data.attrs;
               }
            }
            if(param1.data.records)
            {
               if(!GlobalFunction.isVersionedProfileReceipt(param1))
               {
                  GlobalData.$userData.records = param1.data.records;
               }
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.avatars = param1.data.avatars;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.my_equips = param1.data.my_equips;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.medal = param1.data.medal;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.mark = param1.data.mark;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.coin = param1.data.coin;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.energy = param1.data.energy;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.gold = param1.data.gold;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.score = param1.data.score;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.avatar_soul = param1.data.avatar_soul;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.equip_soul = param1.data.equip_soul;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.culture_book = param1.data.culture_book;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.box_key = param1.data.attrs.box_key;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.dust = param1.data.attrs.dust;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.dn_stone = param1.data.attrs.dn_stone;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.exp = param1.data.exp;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.lv = param1.data.lv;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.fragment_energy = param1.data.attrs.fragment_energy;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.fragment_energy_extra = param1.data.attrs.fragment_energy_extra;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.energy = param1.data.energy;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.energy_extra = param1.data.attr_energy_extra;
            }
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
            _loc3_ = null;
            _loc3_ = GlobalFunction.getAwardByType(_loc8_,_loc7_);
            GlobalFunction.popAward(_loc8_,_loc3_.msg,_loc7_);
            getGift();
         }
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(_timeStatus)
         {
            _timeStatus.removeFromParent();
            _timeStatus = null;
         }
         if(_avatarImg)
         {
            _avatarImg.removeFromParent();
            _avatarImg = null;
         }
         if(_infoBtn)
         {
            _infoBtn.removeFromParent();
            _infoBtn = null;
         }
         if(_payBtn)
         {
            _payBtn.removeFromParent();
            _payBtn = null;
         }
         if(_lineBg)
         {
            _lineBg.removeFromParent();
            _lineBg = null;
         }
         if(_infoText)
         {
            _infoText.removeFromParent();
            _infoText = null;
         }
         StarlingTools.removeChildrenClear(this);
      }
   }
}

