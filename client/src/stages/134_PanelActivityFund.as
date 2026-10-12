package com.meng52.game.ui.panel
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.element.LOL_TimeStatus;
   import com.meng52.game.ui.screen.PanelBase;
   import com.meng52.game.ui.screen.PanelCenterShopVIP;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale3Image;
   import feathers.display.Scale9Image;
   import feathers.textures.Scale9Textures;
   import flash.geom.Rectangle;
   import starling.animation.Juggler;
   import starling.display.Image;
   import starling.events.EnterFrameEvent;
   import starling.events.Event;
   import starling.filters.BlurFilter;
   import starling.filters.FragmentFilter;
   import starling.text.TextField;
   import starling.textures.Texture;
   
   public class PanelActivityFund extends PanelBase
   {
      private var mReceiptCoinBefore:Number;

      
      public static var $isPay:Boolean = false;
      
      private var m9x9_bg:Scale9Image;
      
      private var m9x9_info:Scale9Image;
      
      private var mTxt_info:TextFieldHtmlRenderer;
      
      private var mBtn:LOL_Scale9Button;
      
      private var mJuggler_clip:Juggler;
      
      private var mStatus:Object;
      
      private var mTxt_gift:TextFieldHtmlRenderer;
      
      private var mTxt_timer:TextField;
      
      private var _bgClockt3_bg:Scale3Image;
      
      private var _clock:Image;
      
      private var mTimerT:LOL_TimeStatus;
      
      private var _txt_coin2:LOL_MutilTextFieldIcon;
      
      private var _txt_coin:LOL_MutilTextFieldIcon;
      
      private var _txt_coin3:LOL_MutilTextFieldIcon;
      
      public function PanelActivityFund()
      {
         super();
      }
      
      public static function checkStatus() : Object
      {
         var _loc10_:Number = NaN;
         _loc10_ = 86400000;
         var _loc2_:Object = GlobalData.$mConfig_ploy_system_simple.fund;
         var _loc8_:Object = GlobalData.$userData.attrs.fund;
         var _loc5_:String = _loc8_.key == null ? "1" : String(_loc8_.key);
         var _loc12_:Array = _loc2_.time[_loc5_] as Array;
         var _loc6_:Date = GlobalData.$userData.attrs.fund_add_time as Date;
         var _loc9_:Number = _loc6_.time + _loc12_[0] * 86400000;
         var _loc3_:Number = _loc9_ + _loc12_[1] * 86400000;
         var _loc1_:Number = _loc3_ + _loc12_[2] * 86400000 - 60000;
         var _loc11_:Number = SendAndSelect.$systemTimer_nowSecond * 1000;
         var _loc4_:Number = _loc8_.last_time != null ? (_loc8_.last_time as Date).time : 0;
         var _loc13_:int = -1;
         if(_loc11_ >= _loc9_ && _loc11_ < _loc3_)
         {
            if(_loc8_.money >= _loc2_["return"][0])
            {
               _loc13_ = 1;
            }
            else
            {
               _loc13_ = 0;
            }
         }
         else if(_loc11_ >= _loc3_ && _loc11_ < _loc1_)
         {
            _loc13_ = 2;
         }
         var _loc7_:Boolean = !Tools.checkIsSameDay(_loc4_,_loc11_);
         return {
            "status":_loc13_,
            "start":_loc9_,
            "end":_loc3_,
            "over":_loc1_,
            "isCan":_loc7_
         };
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         removeEventListener("enterFrame",onENTER_FRAME_clip);
         if(mTimerT)
         {
            mTimerT.removeFromParent(true);
         }
         StarlingTools.removeChildrenClear(this);
         if(m9x9_bg)
         {
            m9x9_bg.removeFromParent(true);
         }
         if(_txt_coin2)
         {
            _txt_coin2.removeFromParent(true);
            _txt_coin2.dispose();
         }
         if(m9x9_info)
         {
            m9x9_info.removeFromParent(true);
         }
         if(mTxt_info)
         {
            mTxt_info.removeFromParent(true);
         }
         if(mBtn)
         {
            mBtn.removeFromParent(true);
         }
         if(mJuggler_clip)
         {
            mJuggler_clip.purge();
         }
         if(mTxt_gift)
         {
            mTxt_gift.removeFromParent(true);
         }
         if(mTxt_timer)
         {
            mTxt_timer.removeFromParent(true);
         }
         if(_clock)
         {
            _clock.removeFromParent(true);
         }
         if(_bgClockt3_bg)
         {
            _bgClockt3_bg.removeFromParent(true);
         }
         clear();
         dispose();
         m9x9_bg = null;
         mTimerT = null;
         m9x9_info = null;
         mTxt_info = null;
         mBtn = null;
         mJuggler_clip = null;
         mStatus = null;
         mTxt_gift = null;
         mTxt_timer = null;
         _clock = null;
         _bgClockt3_bg = null;
         _txt_coin2 = null;
         GlobalData.$mEventDispatcher.removeEventListener("update_shop_coin",onUpdate);
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         removeEventListener("addedToStage",initializeHandler);
         GlobalData.$mEventDispatcher.addEventListener("update_shop_coin",onUpdate);
         setUIs();
      }
      
      private function onUpdate(param1:Event) : void
      {
         var _loc2_:Object = GlobalData.$mConfig_ploy_system_simple.fund;
         var _loc4_:int = Math.floor(GlobalData.$userData.attrs.fund.money * 10 * _loc2_["return"][1]);
         var _loc3_:int = int(_loc2_["return"][2]);
         _loc4_ = _loc4_ >= _loc3_ ? _loc3_ : _loc4_;
         if(_txt_coin2)
         {
            _txt_coin2.text(GlobalLanguageStr.getLanguageStr(90498),Tools.toInt(GlobalData.$userData.attrs.fund.money * 10) + " ","UI_money_coin_0_0000");
         }
         if(_txt_coin3)
         {
            _txt_coin3.text(GlobalLanguageStr.getLanguageStr(20499),_loc4_ + GlobalLanguageStr.getLanguageStr(20500),"UI_money_coin_0_0000");
         }
         if(_txt_coin)
         {
            _txt_coin.text(GlobalLanguageStr.getLanguageStr(20499),_loc4_ + GlobalLanguageStr.getLanguageStr(20500),"UI_money_coin_0_0000");
         }
         else
         {
            setUIs();
         }
      }
      
      private function setUIs() : void
      {
         var avatarBg:Image;
         var mTex:Texture;
         var mFont:Image;
         var _t9x9:Scale9Textures;
         var _mColor:Array;
         var _arr:Array;
         var _textures:Vector.<Texture>;
         var i:int;
         var l:int;
         var _mTimerEnd:TextField;
         var _filter:FragmentFilter;
         var _giftNum:int;
         var _giftMax:int;
         var _info:String;
         var _lastS:Number;
         var bgW:* = function(param1:int):void
         {
            mTimerT.x = 20;
         };
         var _cfg:Object = GlobalData.$mConfig_ploy_system_simple.fund;
         var _status:Object = mStatus = checkStatus();
         var _uiStr:String = "UI_fund_bg_0_";
         var _btnStr:String = GlobalLanguageStr.getLanguageStr(20185);
         var _click:Boolean = false;
         var avatars:Object = GlobalData.$mConfig.client_config.fund_avatar;
         var mAvatar:String = avatars.avatar[0];
         if(_status.status == 1)
         {
            _click = true;
         }
         else if(_status.status == 2)
         {
            _btnStr = GlobalLanguageStr.getLanguageStr(20444);
            _click = Boolean(_status.isCan);
            mAvatar = avatars.avatar[1];
         }
         else
         {
            _click = true;
         }
         mImgBg = GlobalFunction.createImage("png_activity_bg",true);
         mImgBg.touchable = false;
         mImgBg.pivotY = mImgBg.height * 0.67;
         mImgBg.y = GlobalData.$mStageHeight / 2;
         addChild(mImgBg);
         avatarBg = GlobalFunction.createImage(mAvatar);
         avatarBg.touchable = false;
         avatarBg.pivotY = avatarBg.height * 0.78;
         avatarBg.pivotX = avatarBg.width * 0.5;
         avatarBg.x = GlobalData.$mStageWidth / 2;
         avatarBg.y = GlobalData.$mStageHeight / 2;
         avatarBg.scaleX = avatarBg.scaleY = 1.5;
         addChild(avatarBg);
         mTex = GlobalFunction.getTextureByBD("UI_fund_font");
         mFont = new Image(mTex);
         mFont.pivotX = mFont.width / 2;
         mFont.pivotY = mFont.height * 0.7;
         mFont.x = avatarBg.x;
         mFont.y = avatarBg.y;
         addChild(mFont);
         _t9x9 = new Scale9Textures(GlobalFunction.getTexture("UI_bg_9slice_5_0000"),new Rectangle(30,20,50,30));
         m9x9_bg = new Scale9Image(_t9x9);
         m9x9_bg.width = 616;
         m9x9_bg.height = 118;
         m9x9_bg.x = int((GlobalData.$mStageWidth - m9x9_bg.width) * 0.5);
         m9x9_bg.y = GlobalData.$center_height_curr - 121 - m9x9_bg.height;
         addChild(m9x9_bg);
         _mColor = [16777215,16764006,6710886,13777209];
         _arr = [Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90167,_cfg["return"][0],_cfg["return"][1] * 100,_cfg["return"][2]),_mColor,1000,MainConfig.$isEnglish ? 18 : 20)];
         mTxt_info = GlobalTextStyle.getHtmlTextRenderer();
         mTxt_info.text = Tools.formatHtmlTextBr(_arr,"center");
         mTxt_info.mLayoutFun = function():void
         {
            var _loc1_:Rectangle = mTxt_info.getTextSnapshotFrame();
            mTxt_info.x = m9x9_bg.x + int((m9x9_bg.width - _loc1_.width) * 0.5);
            mTxt_info.y = m9x9_bg.y + int((m9x9_bg.height - _loc1_.height) * 0.5);
         };
         addChild(mTxt_info);
         _textures = new Vector.<Texture>();
         i = 0;
         l = 30;
         mBtn = new LOL_Scale9Button(_btnStr,150,70,"UI_btn_normalFun_0000");
         mBtn.enabled = _click;
         if(_click)
         {
            mBtn.showGlow();
         }
         else
         {
            mBtn.clearGlow();
         }
         mBtn.shadowFilter();
         mBtn.x = GlobalData.$mStageWidth - mBtn.width - 15;
         mBtn.y = m9x9_bg.y - mBtn.height;
         mBtn.addEventListener("triggered",onTRIGGERED_fun);
         addChild(mBtn);
         mTimerT = new LOL_TimeStatus("panelfund",bgW);
         mTimerT.refresh(0,GlobalLanguageStr.getLanguageStr(20446,Tools.dateFormatByMS(_status.over,"YYYY-MM-DD")),GlobalLanguageStr.getLanguageStr(90490));
         mTimerT.y = 140;
         addChild(mTimerT);
         _mTimerEnd = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20449,Tools.dateFormatByMS(_status.over,"YYYY-MM-DD")),20,16777215,"center",345,35);
         _mTimerEnd.visible = false;
         _mTimerEnd.x = mBtn.x - mBtn.width + 10;
         _mTimerEnd.y = mBtn.y + mBtn.height - _mTimerEnd.height + 5;
         addChild(_mTimerEnd);
         addEventListener("enterFrame",onENTER_FRAME_clip);
         _filter = BlurFilter.createDropShadow(3,0.785,0,1,0);
         _giftNum = Math.floor(GlobalData.$userData.attrs.fund.money * 10 * _cfg["return"][1]);
         _giftMax = int(_cfg["return"][2]);
         _giftNum = _giftNum >= _giftMax ? _giftMax : _giftNum;
         _info = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20447,_giftNum),[16777215,16764006,undefined],15,20);
         _lastS = 0;
         if(_status.status == 2)
         {
            mBtn.x = int((GlobalData.$mStageWidth - mBtn.width) * 0.5);
            _txt_coin3 = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getLanguageStr(20499),_giftNum + GlobalLanguageStr.getLanguageStr(20500),"UI_money_coin_0_0000");
            _txt_coin3.x = 8;
            _txt_coin3.y = mBtn.y + 40;
            addChild(_txt_coin3);
            _mTimerEnd.visible = true;
            _lastS = _status.over * 0.001 - SendAndSelect.$systemTimer_nowSecond;
            _lastS = _lastS > 0 ? _lastS : 0;
            mTimerT.time = _lastS;
         }
         else
         {
            _lastS = _status.end * 0.001 - SendAndSelect.$systemTimer_nowSecond;
            _lastS = _lastS > 0 ? _lastS : 0;
            mTimerT.time = _lastS;
            if(_status.status == 1)
            {
               m9x9_info = new Scale9Image(_t9x9);
               m9x9_info.width = 285;
               m9x9_info.height = 55;
               m9x9_info.x = m9x9_bg.x;
               m9x9_info.y = m9x9_bg.y - 60;
               _txt_coin = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getLanguageStr(20499),_giftNum + GlobalLanguageStr.getLanguageStr(20500),"UI_money_coin_0_0000");
               _txt_coin.x = 12;
               _txt_coin.y = m9x9_info.y + int((m9x9_info.height - 29) * 0.5) - 13;
               addChild(_txt_coin);
               _txt_coin2 = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getLanguageStr(90498),Tools.toInt(GlobalData.$userData.attrs.fund.money * 10) + " ","UI_money_coin_0_0000");
               _txt_coin2.x = 12;
               _txt_coin2.y = mBtn.y + 38;
               addChild(_txt_coin2);
            }
         }
      }
      
      private function onENTER_FRAME_clip(param1:EnterFrameEvent) : void
      {
         if(mJuggler_clip)
         {
            mJuggler_clip.advanceTime(param1.passedTime);
         }
      }
      
      private function onTRIGGERED_fun(param1:Event) : void
      {
         if(mBtn)
         {
            if(mBtn.enabled)
            {
               if(mStatus.status == 2)
               {
                  mReceiptCoinBefore = Number(GlobalData.$userData.coin);
                  SendServiceAMFFun.send_user_fund(reService);
               }
               else
               {
                  $isPay = true;
                  PanelCenterShopVIP.$selectType = 1;
                  GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_pay",false,true);
               }
            }
            else if(mStatus.status == 2)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90170),false,"A_1207_5");
            }
         }
      }
      
      private function reService(param1:Object) : void
      {
         if(stage == null)
         {
            return;
         }
         if(mBtn)
         {
            mBtn.enabled = false;
            mBtn.clearGlow();
         }
         var _loc2_:Number = param1.data - mReceiptCoinBefore;
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.fund.last_time = param1.server_now;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.coin = param1.data;
         }
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin(0);
         GlobalFunction.popAward("coin",GlobalLanguageStr.getLanguageStr(90168,_loc2_),_loc2_,false);
      }
   }
}

