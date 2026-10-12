package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.element.ItemGambleCard;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.element.LOL_ScrollText;
   import com.meng52.game.ui.element.LOL_TextPop;
   import com.meng52.game.ui.element.LOL_TimeStatus;
   import com.meng52.game.ui.screen.PanelBase;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import starling.animation.Juggler;
   import starling.display.Image;
   import starling.display.MovieClip;
   import starling.display.Sprite;
   import starling.events.EnterFrameEvent;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class PanelActivityGamble extends PanelBase
   {
      private var mReceiptGambleIndex:int;
      private var mReceiptCoinBefore:Number;

      
      private var mImg_bg:Image;
      
      private var mImg_table:Image;
      
      private var mBox_report:Sprite;
      
      private var mBox_talk:Sprite;
      
      private var mBox_info:Sprite;
      
      private var mBtn_gamble:LOL_Scale9Button;
      
      private var mTxt_report:LOL_ScrollText;
      
      private var mTxt_coin:TextField;
      
      private var mTxt_time:TextField;
      
      private var mCfg_num:int;
      
      private var mClip_person:MovieClip;
      
      private var mImg_person:Image;
      
      private var mImg_light:Image;
      
      private var mImg_talk:LOL_TextPop;
      
      private var mLight_x:Number = 0;
      
      private var mJuggler_clip:Juggler;
      
      private var mBox_card:Sprite;
      
      private var mStatus_clip_start:Boolean = false;
      
      private var mStatus_clip:int = 0;
      
      private var mClip_timer:Number = 0;
      
      private var mReport_h:Number = 0;
      
      private var mReport_clip:Boolean = false;
      
      private var mCoinNum:int = 0;
      
      private var _txt_coin:LOL_MutilTextFieldIcon;
      
      private var mTimerT:LOL_TimeStatus;
      
      private var _clientConfig:Object;
      
      public function PanelActivityGamble()
      {
         super();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         delCard();
         if(mJuggler_clip)
         {
            mJuggler_clip.purge();
         }
         if(mBtn_gamble)
         {
            mBtn_gamble.removeFromParent(true);
         }
         if(mImg_bg)
         {
            mImg_bg.removeFromParent(true);
         }
         if(mImg_table)
         {
            mImg_table.removeFromParent(true);
         }
         if(mTxt_coin)
         {
            mTxt_coin.removeFromParent(true);
         }
         if(mTxt_report)
         {
            mTxt_report.removeFromParent(true);
         }
         if(mTxt_time)
         {
            mTxt_time.removeFromParent(true);
         }
         if(mClip_person)
         {
            mClip_person.removeFromParent(true);
         }
         if(mImg_person)
         {
            mImg_person.removeFromParent(true);
         }
         if(mImg_light)
         {
            mImg_light.removeFromParent(true);
         }
         if(mImg_talk)
         {
            mImg_talk.removeFromParent(true);
         }
         if(mBox_info)
         {
            StarlingTools.removeChildrenClear(mBox_info);
            mBox_info.removeFromParent(true);
         }
         if(mBox_talk)
         {
            StarlingTools.removeChildrenClear(mBox_talk);
            mBox_talk.removeFromParent(true);
         }
         dispose();
         clear();
         mImg_talk = null;
         mJuggler_clip = null;
         mImg_light = null;
         mClip_person = null;
         mBtn_gamble = null;
         mImg_person = null;
         mImg_bg = null;
         mImg_table = null;
         mTxt_coin = null;
         mTxt_time = null;
         mBox_info = null;
         mBox_talk = null;
         mTxt_report = null;
         GlobalFunction.delTextureByBD("pic_gamble_bg_0");
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         removeEventListener("addedToStage",initializeHandler);
         setUIs();
      }
      
      private function onENTER_FRAME_clip(param1:EnterFrameEvent) : void
      {
         var _loc2_:String = null;
         if(mJuggler_clip)
         {
            mJuggler_clip.advanceTime(param1.passedTime);
            if(mStatus_clip_start)
            {
               if(mStatus_clip == 0)
               {
                  mClip_timer += 1;
                  if(mClip_timer > 60)
                  {
                     if(mClip_person)
                     {
                        mClip_person.visible = !mStatus_clip_start;
                        mClip_person.stop();
                        mClip_person.currentFrame = 2;
                     }
                     if(mImg_person)
                     {
                        mImg_person.visible = mStatus_clip_start;
                     }
                     mStatus_clip = 1;
                     mClip_timer = 0;
                  }
               }
               else if(mStatus_clip == 1)
               {
                  if(mImg_light)
                  {
                     mImg_light.visible = true;
                     mImg_light.alpha -= 0.2;
                     mImg_light.x -= 1;
                     if(mImg_light.alpha <= 0)
                     {
                        mImg_light.x = mLight_x;
                        mStatus_clip = 2;
                     }
                  }
               }
               else if(mStatus_clip == 2)
               {
                  mStatus_clip = 3;
                  setCard();
               }
               else if(mStatus_clip == 3)
               {
                  mClip_timer += 1;
                  if(mClip_timer > 30)
                  {
                     mStatus_clip = 0;
                     mClip_timer = 0;
                     mStatus_clip_start = false;
                     if(mImg_light)
                     {
                        mImg_light.visible = mStatus_clip_start;
                        mImg_light.alpha = 1;
                     }
                     if(mClip_person)
                     {
                        mClip_person.visible = !mStatus_clip_start;
                     }
                     if(mImg_person)
                     {
                        mImg_person.visible = mStatus_clip_start;
                     }
                     if(mBox_talk)
                     {
                        mBox_talk.visible = !mStatus_clip_start;
                     }
                     GlobalData.$mGameClassObject.touchable = true;
                     SoundManager.getOnlyExample().playSound("cure");
                     if(_clientConfig != "")
                     {
                        GlobalFunction.showReward2({
                           "info":GlobalLanguageStr.getLanguageStr(90146),
                           "icon":_clientConfig + ""
                        },{"coin":mCoinNum});
                     }
                     else
                     {
                        _loc2_ = GlobalData.$mConfig_simple.show_id[4];
                     }
                     GlobalFunction.showReward2({
                        "info":GlobalLanguageStr.getLanguageStr(90146),
                        "icon":_loc2_
                     },{"coin":mCoinNum});
                     update_gamble();
                     GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
                     send_report();
                  }
               }
            }
            if(mReport_clip)
            {
               if(mTxt_report)
               {
                  mTxt_report.y -= 0.5;
                  if(mTxt_report.y + mReport_h < 0)
                  {
                     mTxt_report.y = 85;
                  }
               }
            }
         }
      }
      
      private function setUIs() : void
      {
         var role:Image;
         var _bg:Image;
         var m9x9_bg:Scale9Image;
         var _tTips:TextField;
         var _tTips2:TextField;
         var _obj:Object;
         var bgW:* = function(param1:int):void
         {
            mTimerT.x = 20;
         };
         _clientConfig = GlobalData.$mConfig.client_config.gamble_avatar;
         mReport_clip = false;
         mStatus_clip_start = false;
         mStatus_clip = 0;
         mClip_timer = 0;
         var _cfg:Object = GlobalData.$mConfig_ploy_system_simple.gamble;
         mCfg_num = Tools.getElementNum(GlobalData.$mConfig_ploy_system_simple.gamble.return_coin);
         var _result:Object = getTimeOut();
         mImg_bg = GlobalFunction.createImage("pic_gamble_bg_0",true);
         mImg_bg.touchable = true;
         mImg_bg.y = -127 + GlobalData.formatVScaleY(1);
         addChild(mImg_bg);
         addEventListener("enterFrame",onENTER_FRAME_clip);
         mJuggler_clip = new Juggler();
         mClip_person = DisplayTools.newMc("UI_gamble_clip_person_0_",mImg_bg.x + 342,mImg_bg.y + 270,15);
         mClip_person.visible = !mStatus_clip_start;
         mClip_person.loop = true;
         mClip_person.pivotX = mClip_person.pivotY = 0;
         mClip_person.scaleX = mClip_person.scaleY = 2;
         addChild(mClip_person);
         mJuggler_clip.add(mClip_person);
         mClip_person.stop();
         mClip_person.currentFrame = 2;
         if(_clientConfig != "")
         {
            mClip_person.visible = false;
            mClip_person.alpha = 0;
            role = GlobalFunction.createImage(_clientConfig + "");
            role.x = mImg_bg.x + 198;
            role.y = mImg_bg.y + 280;
            addChild(role);
         }
         mImg_person = GlobalFunction.createImage("UI_gamble_clip_person_1_0000");
         mImg_person.scaleX = mImg_person.scaleY = 2;
         mImg_person.visible = mStatus_clip_start;
         mImg_person.x = mImg_bg.x + 190;
         mImg_person.y = mImg_bg.y + 265;
         addChild(mImg_person);
         mImg_light = GlobalFunction.createImage("UI_gamble_clip_light_1_0000");
         mImg_light.visible = mStatus_clip_start;
         mLight_x = mImg_person.x + 5;
         mImg_light.x = mLight_x;
         mImg_light.y = mImg_person.y + mImg_light.height;
         addChild(mImg_light);
         mImg_table = GlobalFunction.createImage("UI_gamble_clip_bg_0_0000");
         mImg_table.touchable = true;
         mImg_table.x = -30;
         mImg_table.y = GlobalData.$center_height_curr - 121 - mImg_table.height + 30;
         addChild(mImg_table);
         mBox_report = new Sprite();
         mBox_report.clipRect = new Rectangle(0,0,415,300);
         mBox_report.x = 40;
         mBox_report.y = mImg_table.y - 145;
         addChild(mBox_report);
         mTxt_report = new LOL_ScrollText(GlobalData.$gambleReportArr,415,29,5,16777215,15);
         mBox_report.addChild(mTxt_report);
         if(GlobalData.$gambleReportStr != "")
         {
            mReport_h = mTxt_report.textHeight;
            mTxt_report.y = 0;
            mReport_clip = false;
         }
         mBox_talk = new Sprite();
         mBox_talk.visible = !mStatus_clip_start;
         mImg_talk = new LOL_TextPop(MainConfig.$isEA ? 260 : 250,100);
         mBox_talk.addChild(mImg_talk);
         mBox_talk.x = mClip_person.x - mImg_talk.width + 20;
         mBox_talk.y = mClip_person.y + 70;
         addChild(mBox_talk);
         mBox_info = new Sprite();
         addChild(mBox_info);
         _bg = GlobalFunction.createImage("UI_gamble_bg_0_0000");
         mBtn_gamble = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20402),150,70,"UI_btn_normalFun_0000");
         mBtn_gamble.fontColor = 1513239;
         mBtn_gamble.shadowFilter();
         mBox_info.addChild(mBtn_gamble);
         mBox_info.x = int((GlobalData.$mStageWidth - _bg.width) * 0.5) + 20;
         mBox_info.y = GlobalData.$center_height_curr - 121 - _bg.height - 100;
         mBtn_gamble.x = int((_bg.width - mBtn_gamble.width) * 0.5) + 5 + 200;
         mBtn_gamble.y = int((_bg.height - mBtn_gamble.height) * 0.5) + 10;
         mBtn_gamble.addEventListener("triggered",onTRIGGERED_gamble);
         mBtn_gamble.enabled = _result.can;
         if(_result.can)
         {
            mBtn_gamble.showGlow();
         }
         else
         {
            mBtn_gamble.clearGlow();
         }
         m9x9_bg = GlobalFunction.createScale9Image("UI_bg_9slice_5_0000",616,100,new Rectangle(30,20,50,30));
         m9x9_bg.x = (GlobalData.$mStageWidth - m9x9_bg.width) / 2;
         m9x9_bg.y = GlobalData.$center_height_curr - m9x9_bg.height * 2 - 20;
         addChild(m9x9_bg);
         _tTips = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90143),20,16764006,"center",400,29);
         _tTips.x = m9x9_bg.x + m9x9_bg.width / 2 - 210;
         _tTips.y = 22;
         m9x9_bg.addChild(_tTips);
         _tTips2 = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90504),20,16777215,"center",400,29);
         _tTips2.x = m9x9_bg.x + m9x9_bg.width / 2 - 200;
         _tTips2.y = _tTips.height + 25;
         m9x9_bg.addChild(_tTips2);
         _obj = getTimeOut();
         mTimerT = new LOL_TimeStatus("panelgamble",bgW);
         mTimerT.refresh(_obj.end,GlobalLanguageStr.getLanguageStr(90491,Tools.timeFormatAll(_obj.end)),GlobalLanguageStr.getLanguageStr(90505));
         mTimerT.y = 140;
         addChild(mTimerT);
         mTxt_coin = GlobalTextStyle.getTextField("",20,16763955,"center",110,29);
         mTxt_coin.x = 50;
         mTxt_coin.y = 45;
         _txt_coin = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getLanguageStr(20502),"","UI_money_coin_0_0000");
         if(MainConfig.$isEnglish == true)
         {
            _txt_coin.x = mBtn_gamble.x - _txt_coin.width - 50;
         }
         else
         {
            _txt_coin.x = mBtn_gamble.x - _txt_coin.width - 75;
         }
         _txt_coin.y = 50;
         mBox_info.addChild(_txt_coin);
         mTxt_time = GlobalTextStyle.getTextField("",20,16777215,"center",200,29);
         mTxt_time.x = 420;
         mTxt_time.y = 42;
         mBox_info.addChild(mTxt_time);
         update_gamble();
         send_report();
      }
      
      private function getTimeOut() : Object
      {
         var _loc2_:Object = GlobalData.$mConfig_ploy_system_simple.gamble;
         var _loc6_:* = GlobalData.$userData.add_time;
         var _loc4_:Number = (GlobalData.$userData.add_time as Date).time;
         var _loc3_:Number = _loc4_ + _loc2_.days * 24 * 60 * 60 * 1000;
         var _loc5_:Number = SendAndSelect.$systemTimer_nowSecond * 1000;
         var _loc1_:int = Tools.getElementNum(_loc2_.return_coin);
         var _loc9_:int = int(GlobalData.$userData.attrs.gamble_index);
         var _loc8_:Boolean = false;
         if(_loc5_ >= _loc4_ && _loc5_ < _loc3_ && _loc9_ < _loc1_)
         {
            _loc8_ = true;
         }
         var _loc7_:Number = _loc3_ - _loc5_;
         return {
            "can":_loc8_,
            "end":_loc7_ * 0.001,
            "curr":_loc9_,
            "max":_loc1_
         };
      }
      
      private function onTRIGGERED_gamble(param1:Event) : void
      {
         var _loc2_:Object = null;
         var _loc4_:int = 0;
         var _loc5_:Array = null;
         var _loc3_:int = 0;
         var _loc7_:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         if(!_loc7_)
         {
            return;
         }
         var _loc6_:Object = getTimeOut();
         if(_loc7_.enabled)
         {
            _loc2_ = GlobalData.$mConfig_ploy_system_simple.gamble;
            _loc4_ = _loc6_.curr + 1;
            _loc4_ = _loc4_ > mCfg_num ? mCfg_num : _loc4_;
            _loc5_ = _loc2_.return_coin[_loc4_];
            _loc3_ = int(_loc5_ != null ? _loc5_[0] : 0);
            if(GlobalData.$userData.coin >= _loc3_)
            {
               send_gamble();
            }
            else
            {
               GlobalFunction.popErrorCoin(_loc3_);
            }
         }
         else if(_loc6_.end > 0)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90147));
         }
         else
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90144));
         }
      }
      
      private function send_gamble() : void
      {
         GlobalData.$mGameClassObject.touchable = false;
         mReceiptGambleIndex = int(GlobalData.$userData.attrs.gamble_index);
         mReceiptCoinBefore = Number(GlobalData.$userData.coin);
         SendServiceAMFFun.send_user_gamble(re_gamble);
      }
      
      private function re_gamble(param1:Object) : void
      {
         if(stage == null)
         {
            return;
         }
         GlobalData.$mGameClassObject.touchable = false;
         var _loc2_:Object = GlobalData.$mConfig_ploy_system_simple.gamble;
         var _loc4_:int = mReceiptGambleIndex + 1;
         _loc4_ = _loc4_ > mCfg_num ? mCfg_num : _loc4_;
         var _loc5_:Array = _loc2_.return_coin[_loc4_];
         var _loc6_:int = int(_loc5_ != null ? _loc5_[0] : 0);
         var _loc3_:int = int(param1.data);
         var _loc8_:int = _loc6_ + (_loc3_ - int(mReceiptCoinBefore));
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.coin = _loc3_;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.gamble_index += 1;
         }
         setClipStart(_loc8_);
      }
      
      private function update_gamble() : void
      {
         var _loc1_:Object = GlobalData.$mConfig_ploy_system_simple.gamble;
         var _loc5_:Object = getTimeOut();
         var _loc2_:int = _loc5_.curr + 1;
         _loc2_ = _loc2_ > mCfg_num ? mCfg_num : _loc2_;
         var _loc3_:Array = _loc1_.return_coin[_loc2_];
         var _loc6_:String = String(_loc3_ != null ? _loc3_[0] : 0);
         if(!_loc5_.can)
         {
            _loc6_ = "--";
         }
         mTxt_coin.text = _loc6_;
         if(_txt_coin)
         {
            _txt_coin.txt2 = _loc6_;
            if(!_loc5_.can)
            {
               _txt_coin.removeFromParent(true);
               _txt_coin = null;
            }
         }
         var _loc4_:String = _loc5_.end > 0 ? GlobalLanguageStr.getLanguageStr(90151,Tools.timeFormatToDate(_loc5_.end,false)) : GlobalLanguageStr.getLanguageStr(90144);
         mTxt_time.text = _loc4_;
         mBtn_gamble.enabled = _loc5_.can;
         if(mImg_talk)
         {
            if(_loc5_.can)
            {
               mImg_talk.show(GlobalLanguageStr.getLanguageStr(90148),0);
            }
            else
            {
               mImg_talk.show(GlobalLanguageStr.getLanguageStr(90150),0);
            }
         }
      }
      
      private function setClipStart(param1:int) : void
      {
         mCoinNum = param1;
         mStatus_clip = 0;
         mClip_timer = 0;
         mStatus_clip_start = true;
         if(mClip_person)
         {
            mClip_person.play();
         }
         if(!mImg_person)
         {
         }
         if(mBox_talk)
         {
            mBox_talk.visible = !mStatus_clip_start;
         }
         if(_clientConfig != "")
         {
            mClip_person.stop();
            mStatus_clip = 2;
         }
      }
      
      private function setCard() : void
      {
         var _loc4_:ItemGambleCard = null;
         delCard();
         mBox_card = new Sprite();
         var _loc6_:int = 0;
         var _loc3_:int = 5;
         var _loc5_:Object = null;
         var _loc1_:int = mCoinNum;
         var _loc2_:String = Tools.formateIntToStrBy0(_loc1_,_loc3_);
         _loc6_ = 0;
         while(_loc6_ < _loc3_)
         {
            _loc5_ = {};
            _loc5_["indexID_s"] = _loc2_.charAt(_loc6_);
            _loc5_["id"] = _loc6_;
            _loc4_ = new ItemGambleCard();
            _loc4_.mXX = 120 * _loc6_;
            _loc4_.x = 120 * _loc6_;
            _loc4_.data = _loc5_;
            mBox_card.addChild(_loc4_);
            _loc6_++;
         }
         mBox_card.x = int((GlobalData.$mStageWidth - _loc3_ * 120) * 0.5) + 60;
         mBox_card.y = mImg_table.y + 110;
         addChild(mBox_card);
      }
      
      private function delCard() : void
      {
         if(mBox_card)
         {
            StarlingTools.removeChildrenClear(mBox_card);
            mBox_card.removeFromParent(true);
         }
         mBox_card = null;
      }
      
      private function send_report() : void
      {
         var _loc1_:Object = GlobalData.$mConfig_ploy_system_simple.gamble;
         var _loc2_:Number = _loc1_.radio[1] * 60;
         var _loc3_:Number = SendAndSelect.$systemTimer_nowSecond - GlobalData.$gambleReportTimer;
         if(_loc3_ > 0 && _loc3_ >= _loc2_ || GlobalData.$gambleReportStr == "")
         {
            SendServiceAMFFun.send_user_get_gamble_reports(re_report);
         }
      }
      
      private function re_report(param1:Object) : void
      {
         var _loc6_:int = 0;
         var _loc3_:int = 0;
         var _loc2_:String = null;
         var _loc5_:Array = param1.data;
         var _loc4_:Array = [];
         if(_loc5_.length > 0)
         {
            _loc6_ = 0;
            _loc3_ = int(_loc5_.length);
            _loc2_ = "";
            _loc6_ = 0;
            while(_loc6_ < _loc3_)
            {
               _loc2_ = GlobalLanguageStr.getLanguageStr("gamble",_loc5_[_loc6_]);
               _loc4_.push(_loc2_);
               _loc6_++;
            }
            GlobalData.$gambleReportArr = _loc4_;
            if(mTxt_report)
            {
               mTxt_report.data = GlobalData.$gambleReportArr;
               mReport_h = mTxt_report.textHeight;
               mTxt_report.y = 0;
               mReport_clip = false;
            }
         }
      }
   }
}

