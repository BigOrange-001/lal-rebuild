package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.map.GameMapTools;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_IconText;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.game.ui.element.LOL_TextField;
   import com.meng52.game.ui.element.LOL_TimeStatus;
   import com.meng52.game.ui.screen.PanelCenterCasino;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.net.RpcStaticCall;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.utils.getTimer;
   import starling.display.Image;
   import starling.display.MovieClip;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   
   public class PanelCasinoVIP extends PanelCenterCasino
   {
      
      public static var FLASH_TIME:Number = 0.2;
      
      public static var M_AVATAR_Y:int = 590;
      
      public static var BTN_NAME_CASINO_ONE:String = "btn_name_casino_one";
      
      public static var BTN_NAME_CASINO_TEN:String = "btn_name_casino_ten";
      
      private static const BTN_NAME_FREE_EXTRACTION:String = "btn_name_free_extraction";
      
      private static const BTN_NAME_COIN_EXTRACTION:String = "btn_name_coin_extraction";
      
      public var mBtn_one:LOL_Button;
      
      public var mBtn_ten:LOL_Button;
      
      private var mBox:Sprite;
      
      private var mTxt_info:TextField;
      
      private var _txt_coin:LOL_MutilTextFieldIcon;
      
      private var mTxt_one:TextField;
      
      private var mTxt_ten:TextField;
      
      public var mNum_one:Number;
      
      public var mNum_ten:Number;
      
      public var mImgBgClip:Image;
      
      public var mClip_a:MovieClip;
      
      public var mClip_b:MovieClip;
      
      public var mClip_imgA:Image;
      
      public var mQuad:Quad;
      
      public var mClip_statusA:Number = 0;
      
      public var mClip_statusB:Number = 0;
      
      private var mList_box:Sprite;
      
      private var mBg_touch:LOL_Button;
      
      private var isTen:Boolean = false;
      
      private var isFree:Boolean = false;
      
      private var isCoin:Boolean = false;
      
      private var mClip_awards_YY:Number = 0;
      
      private var mRulerPoint:Point;
      
      private var btn_one:Scale9Image;
      
      private var btn_ten:Scale9Image;
      
      private var _btnA_bg:Image;
      
      private var _btnB_bg:Image;
      
      private var _btnA_txt:LOL_TextField;
      
      private var _btnB_txt:LOL_TextField;
      
      private var pay_ont_txt:TextField;
      
      private var pay_ten_txt:TextField;
      
      private var mOwn_txt:TextField;
      
      private var mTime_a:LOL_TimeStatus;
      
      private var mFree_a:LOL_IconText;
      
      private var mTime_Vip_b:LOL_TimeStatus;
      
      private var mFree_Vip_b:LOL_IconText;
      
      private var _score:Boolean;
      
      private const ONE_RATE:int = 1;
      
      private const TEN_RATE:int = 10;
      
      private var _Txt_isFree:TextField;
      
      private var _wordA_bg:Image;
      
      private var _wordB_bg:Image;
      
      private var _mColor:int = 16777215;
      
      private var txt_Integral:TextField;
      
      private var _bgInfo:Scale9Image;
      
      private var txt_Inf:TextField;
      
      private var _isNormalFree:Boolean = false;
      
      private var b:Boolean = false;
      
      private var mTimerT1:LOL_TimeStatus;
      
      private var _userData:Object;
      
      private var payType:uint;
      
      public function PanelCasinoVIP()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(97926));
         setPopUIs();
      }
      
      private function setPopUIs() : void
      {
         this.mBox = new Sprite();
         var _loc3_:Array = GlobalData.$mConfig_simple.show_avatar;
         var _loc5_:Array = _loc3_[4];
         this.btn_one = GlobalFunction.createScale9Image("UI_bg_box_0_0000",260,330,new Rectangle(30,30,30,20));
         btn_one.x = this.mImg9_baseBg.width * 0.5 - btn_one.width - 10;
         mBox.addChild(this.btn_one);
         this.btn_ten = GlobalFunction.createScale9Image("UI_bg_box_0_0000",260,330,new Rectangle(30,30,30,20));
         btn_ten.x = this.mImg9_baseBg.width * 0.5 + 10;
         mBox.addChild(this.btn_ten);
         this.btn_one.y = this.btn_ten.y = this.mImg9_baseBg.y + 120;
         this.btn_one.name = BTN_NAME_CASINO_ONE;
         this.btn_ten.name = BTN_NAME_CASINO_TEN;
         _btnA_bg = GlobalFunction.createImage("UI_bg_colorbottom_3_0000");
         _btnA_bg.x = btn_one.x + 13;
         _btnA_bg.y = btn_one.y + 12;
         _btnA_bg.touchable = false;
         mBox.addChildAt(_btnA_bg,0);
         _btnB_bg = GlobalFunction.createImage("UI_bg_colorbottom_3_0000");
         _btnB_bg.x = btn_ten.x + 13;
         _btnB_bg.y = btn_ten.y + 12;
         _btnB_bg.touchable = false;
         mBox.addChildAt(_btnB_bg,0);
         _btnA_bg.width = _btnB_bg.width = 234;
         _btnA_bg.height = _btnB_bg.height = 304;
         var _loc1_:Rectangle = new Rectangle(0,0,_btnA_bg.width,_btnA_bg.height);
         var _loc10_:Image = GameMapTools.newAvatarImgById(_loc5_[0],115,160);
         var _loc4_:Sprite = new Sprite();
         _loc4_.addChild(_loc10_);
         _loc4_.clipRect = _loc1_;
         _loc4_.x = _btnA_bg.x;
         _loc4_.y = _btnA_bg.y;
         _loc4_.touchable = false;
         _loc10_.scaleX = _loc10_.scaleY = 0.85;
         mBox.addChild(_loc4_);
         var _loc6_:Image = GameMapTools.newAvatarImgById(_loc5_[1],115,160);
         var _loc9_:Sprite = new Sprite();
         _loc9_.addChild(_loc6_);
         _loc9_.clipRect = _loc1_;
         _loc9_.x = _btnB_bg.x;
         _loc9_.y = _btnB_bg.y;
         _loc9_.touchable = false;
         _loc6_.scaleX = _loc6_.scaleY = 0.85;
         mBox.addChild(_loc9_);
         _wordA_bg = GlobalFunction.createImage("UI_wordbg_yellow_0_0000");
         _wordA_bg.x = btn_one.x + (btn_one.width - _wordA_bg.width) * 0.5;
         _wordA_bg.y = btn_one.y + btn_one.height * 0.65 + 35;
         _wordA_bg.touchable = false;
         mBox.addChild(_wordA_bg);
         _wordB_bg = GlobalFunction.createImage("UI_wordbg_yellow_0_0000");
         _wordB_bg.x = btn_ten.x + (btn_ten.width - _wordB_bg.width) * 0.5;
         _wordB_bg.y = btn_ten.y + btn_ten.height * 0.65 + 35;
         _wordB_bg.touchable = false;
         mBox.addChild(_wordB_bg);
         _btnA_txt = new LOL_TextField(GlobalLanguageStr.getStr(20061),200,40);
         _btnA_txt.fontSize = 20;
         _btnA_txt.fontColor = 16777215;
         _btnA_txt.shadowFilter();
         _btnA_txt.x = _btnA_bg.x + 10;
         _btnA_txt.touchable = false;
         mBox.addChild(_btnA_txt);
         _btnB_txt = new LOL_TextField(GlobalLanguageStr.getStr(20062),200,40);
         _btnB_txt.fontSize = 20;
         _btnB_txt.fontColor = 16777215;
         _btnB_txt.shadowFilter();
         _btnA_txt.hAlign = _btnB_txt.hAlign = "left";
         _btnB_txt.x = _btnB_bg.x + 10;
         _btnA_txt.y = _btnB_txt.y = this.mImg9_baseBg.y + 135;
         _btnB_txt.touchable = false;
         mBox.addChild(_btnB_txt);
         var _loc11_:String = GlobalLanguageStr.getLanguageStr(90494);
         var _loc8_:String = "UI_money_coin_0_0000";
         var _loc7_:String = GlobalData.$userData.coin;
         _txt_coin = new LOL_MutilTextFieldIcon(_loc11_,_loc7_,_loc8_);
         _txt_coin.x = btn_one.x;
         if(_score)
         {
            _txt_coin.iconScale = 0.7;
         }
         _txt_coin.y = btn_one.y + btn_one.height + 20;
         addChild(_txt_coin);
         txt_Integral = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97924,GlobalData.$userData.attrs.lottery_activity.score ? GlobalData.$userData.attrs.lottery_activity.score : "0"),20,16777215,"left",300,46);
         txt_Integral.x = _txt_coin.x + _txt_coin.width + 20;
         txt_Integral.y = _txt_coin.y + 2;
         addChild(txt_Integral);
         if(!getVipTime().can)
         {
            txt_Integral.visible = false;
         }
         _bgInfo = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",560,169,new Rectangle(110,55,70,20));
         _bgInfo.x = int((GlobalData.$mStageWidth - _bgInfo.width) * 0.5);
         _bgInfo.y = this.mImg9_baseBg.y + this.mImg9_baseBg.height - _bgInfo.height - 30 - 5;
         mBox.addChild(_bgInfo);
         txt_Inf = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97925),40,4926491,"left",500,60);
         txt_Inf.x = _bgInfo.x + (_bgInfo.width - txt_Inf.width) * 0.5;
         txt_Inf.y = _bgInfo.y + (_bgInfo.height - txt_Inf.height) * 0.5;
         mBox.addChild(txt_Inf);
         var _loc13_:String = "";
         var _loc14_:String = "";
         var _loc2_:Number = 158;
         var _loc12_:int = 0;
         _loc13_ = GlobalData.$mConfig.ploy_system_simple.extract_avatar.coin_one;
         _loc14_ = GlobalData.$mConfig.ploy_system_simple.extract_avatar.coin_ten;
         _loc12_ = 20394;
         mNum_one = Number(_loc13_);
         mNum_ten = Number(_loc14_);
         pay_ont_txt = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(_loc12_,_loc13_),20,1118481,"center",200,35);
         pay_ten_txt = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(_loc12_,_loc14_),20,1118481,"center",200,35);
         pay_ont_txt.x = btn_one.x + (btn_one.width - pay_ont_txt.width) * 0.5;
         pay_ten_txt.x = btn_ten.x + (btn_ten.width - pay_ten_txt.width) * 0.5;
         pay_ont_txt.y = pay_ten_txt.y = _wordA_bg.y + 5;
         this.mBox.addChild(pay_ont_txt);
         this.mBox.addChild(pay_ten_txt);
         this.addChild(mBox);
         this.btn_one.addEventListener("touch",onTOUCH);
         this.btn_ten.addEventListener("touch",onTOUCH);
      }
      
      private function getVipTime() : Object
      {
         var _loc6_:Object = GlobalData.$mConfig_ploy_system_simple.extract_avatar;
         var _loc3_:Number = (_loc6_.start_time as Date).time;
         var _loc5_:Number = (_loc6_.end_time as Date).time;
         var _loc1_:Number = SendAndSelect.$systemTimer_nowSecond * 1000;
         var _loc2_:Date = new Date();
         _loc2_.setTime(_loc1_);
         var _loc4_:Object = {};
         if(_loc1_ > _loc3_ && _loc1_ < _loc5_)
         {
            _loc4_.can = true;
         }
         else
         {
            _loc4_.can = false;
         }
         return _loc4_;
      }
      
      private function onTOUCH(param1:TouchEvent) : void
      {
         var _loc4_:Object = null;
         var _loc3_:String = null;
         var _loc6_:Object = null;
         var _loc2_:String = null;
         var _loc8_:Scale9Image = param1.currentTarget as Scale9Image;
         var _loc7_:Touch = param1.getTouch(_loc8_,"ended");
         var _loc5_:int = 0;
         if(_loc7_)
         {
            var minimumVip:int = int(GlobalData.$mConfig_ploy_system_simple.extract_avatar.min_vip_level || 8);
            if(int(GlobalData.$userData.vip_lv) < minimumVip)
            {
               GlobalFunction.popAlert("", "VIP召唤需要VIP" + minimumVip + "及以上");
               return;
            }
            if(_loc8_.name == BTN_NAME_CASINO_ONE)
            {
               payType = 0;
               if(GlobalData.$userData.coin < this.mNum_one)
               {
                  _loc4_ = {
                     "ok":gotoCoin,
                     "no":GlobalFunction.functionNull,
                     "aid":"A_2009_5"
                  };
                  _loc3_ = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90051,mNum_one),GlobalTextStyle.COLOR_W_Y_Y_G);
                  GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(90010),_loc3_,_loc4_);
                  return;
               }
               GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
               if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
               {
                  GlobalFunction.popAvatarLen();
                  return;
               }
               SendServiceAMFFun.send_user_get_lottery_activity(captureVipBefore(onAvatar),{
                  "flag":payType,
                  "hit":getVipTime().can
               });
            }
            if(_loc8_.name == BTN_NAME_CASINO_TEN)
            {
               payType = 1;
               if(GlobalData.$userData.coin < this.mNum_ten)
               {
                  _loc6_ = {
                     "ok":gotoCoin,
                     "no":GlobalFunction.functionNull,
                     "aid":"A_2009_5"
                  };
                  _loc2_ = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90051,mNum_ten),GlobalTextStyle.COLOR_W_Y_Y_G);
                  GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(90010),_loc2_,_loc6_);
                  return;
               }
               GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
               if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
               {
                  GlobalFunction.popAvatarLen();
                  return;
               }
               SendServiceAMFFun.send_user_get_lottery_activity(captureVipBefore(onAvatar),{
                  "flag":payType,
                  "hit":getVipTime().can
               });
            }
         }
      }
      
      private function gotoCoin() : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_pay",false,true);
      }
      
      private function onAvatar(param1:Object) : void
      {
         // The profile receipt has already been applied by SendAndSelect.
         // A successful draw belongs to the request, even if its panel closed.
         if(!claimRecruitmentReceipt(param1)) return;
         var _panelVisible:Boolean = this.stage != null;
         if(param1.data.score)
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1) && GlobalData.$userData.attrs.lottery_activity != null)
            {
            GlobalData.$userData.attrs.lottery_activity.score = param1.data.score;
            }
         }
         showVipTransition(param1);
         if(GlobalData.$userData.attrs.lottery_activity)
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.attrs.lottery_activity.start_time = GlobalData.$mConfig.ploy_system_simple.extract_avatar.start_time as Date;
            }
         }
         else
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.attrs["lottery_activity"] = {};
            GlobalData.$userData.attrs["lottery_activity"].score = param1.data.score ? param1.data.score : 0;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.attrs["lottery_activity"].start_time = GlobalData.$mConfig.ploy_system_simple.extract_avatar.start_time as Date;
            }
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
         GlobalData.$userData.vip_exp = param1.data.vip_exp;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
         GlobalData.$userData.vip_lv = param1.data.vip_lv;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
         GlobalData.$userData.coin = param1.data.coin;
         }
         GlobalFunction.updateVip();
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
         if(_panelVisible && _txt_coin != null)
         {
            _txt_coin.txt2 = GlobalData.$userData.coin;
         }
         if(param1.payType == null)
         {
            param1.payType = param1.params != null ? int(param1.params.flag) : payType;
         }
         if(_panelVisible)
         {
            onCLOSE_PANEL_SELF();
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_main");
         }
         isAvatar(param1);
      }
      
      private function isAvatar(param1:Object) : void
      {
         // Reward presentation lives in LayoutUIAnimation, not the old panel.
         var _loc10_:Object = null;
         var _loc11_:* = 0;
         var _loc2_:String = null;
         var _loc6_:Object = null;
         var _loc9_:Object = null;
         var _loc5_:Object = null;
         var _loc7_:String = null;
         var _loc8_:Object = null;
         var _loc4_:Array = [];
         if(!param1.payType)
         {
            _loc10_ = param1.data.avatars;
            for(var _loc12_:String in _loc10_)
            {
               _loc11_ = 0;
               while(_loc11_ < _loc10_[_loc12_].length)
               {
                  for(var _loc3_:String in _loc10_[_loc12_][_loc11_])
                  {
                     _loc2_ = _loc3_;
                  }
                  if(_loc12_ == "avatar")
                  {
                     if(!GlobalFunction.isVersionedProfileReceipt(param1))
                     {
                     GlobalData.$userData.avatars[_loc2_] = _loc10_[_loc12_][_loc11_][_loc2_];
                     }
                     _loc6_ = {};
                     _loc6_[_loc2_] = _loc10_[_loc12_][_loc11_][_loc2_];
                     LayoutUIAnimation.getOnlyExample().popCasino(_loc6_,6,0,MainConfig.$casionBgUiName,{
                        "type":"avatar",
                        "score":param1.data.score,
                        "isActivity":Boolean(param1._vip_activity_request)
                     });
                  }
                  _loc9_ = GlobalData.$userData.avatar_soul;
                  if(_loc12_ == "avatar_soul")
                  {
                     _loc6_ = {};
                     _loc6_[_loc2_] = _loc10_[_loc12_][_loc11_][_loc2_];
                     if(GlobalData.$userData.avatar_soul[_loc2_])
                     {
                        if(!GlobalFunction.isVersionedProfileReceipt(param1))
                        {
                        GlobalData.$userData.avatar_soul[_loc2_] += _loc10_[_loc12_][_loc11_][_loc2_];
                        }
                     }
                     else
                     {
                        if(!GlobalFunction.isVersionedProfileReceipt(param1))
                        {
                        GlobalData.$userData.avatar_soul[_loc2_] = _loc10_[_loc12_][_loc11_][_loc2_];
                        }
                     }
                     LayoutUIAnimation.getOnlyExample().popCasino(_loc6_,6,0,MainConfig.$casionBgUiName,{
                        "type":"avatar_soul",
                        "score":param1.data.score,
                        "isActivity":Boolean(param1._vip_activity_request)
                     });
                  }
                  _loc11_++;
               }
            }
         }
         else
         {
            _loc5_ = param1.data.avatars;
            _loc4_ = [];
            for(_loc12_ in _loc5_)
            {
               _loc11_ = 0;
               while(_loc11_ < _loc5_[_loc12_].length)
               {
                  for(_loc3_ in _loc5_[_loc12_][_loc11_])
                  {
                     _loc7_ = _loc3_;
                  }
                  if(_loc12_ == "avatar")
                  {
                     _loc8_ = {};
                     _loc8_["avatar"] = {};
                     _loc8_["avatar"][_loc7_] = _loc5_[_loc12_][_loc11_][_loc7_];
                     _loc8_.avatarInfo = new Avatar(_loc7_,{});
                     if(!GlobalFunction.isVersionedProfileReceipt(param1))
                     {
                     GlobalData.$userData.avatars[_loc7_] = _loc5_[_loc12_][_loc11_][_loc7_];
                     }
                     _loc4_.push(_loc8_);
                  }
                  if(_loc12_ == "avatar_soul")
                  {
                     _loc8_ = {};
                     _loc8_["avatar_soul"] = {};
                     _loc8_["avatar_soul"][_loc7_] = _loc5_[_loc12_][_loc11_][_loc7_];
                     _loc8_.avatarInfo = new Avatar(_loc7_,{});
                     if(GlobalData.$userData.avatar_soul[_loc7_])
                     {
                        if(!GlobalFunction.isVersionedProfileReceipt(param1))
                        {
                        GlobalData.$userData.avatar_soul[_loc7_] += _loc5_[_loc12_][_loc11_][_loc7_];
                        }
                     }
                     else
                     {
                        if(!GlobalFunction.isVersionedProfileReceipt(param1))
                        {
                        GlobalData.$userData.avatar_soul[_loc7_] = _loc5_[_loc12_][_loc11_][_loc7_];
                        }
                     }
                     _loc4_.push(_loc8_);
                  }
                  _loc11_++;
               }
            }
            LayoutUIAnimation.getOnlyExample().popCasino(_loc4_,6,0,MainConfig.$casionBgUiName,{
               "score":param1.data.score,
               "isActivity":Boolean(param1._vip_activity_request)
            });
         }
         if(!GlobalData.$isForceGuide)
         {
            LayoutUIAnimation.getOnlyExample().clearIfNoGuide();
         }
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.mCurrPanel = "";
         if(btn_one)
         {
            this.btn_one.removeEventListener("touch",onTOUCH);
            btn_one.removeFromParent(true);
            btn_one.dispose();
         }
         if(btn_ten)
         {
            this.btn_ten.removeEventListener("touch",onTOUCH);
            btn_ten.removeFromParent(true);
            btn_ten.dispose();
         }
         if(_btnA_bg)
         {
            _btnA_bg.removeFromParent(true);
            _btnA_bg.dispose();
         }
         if(_btnB_bg)
         {
            _btnB_bg.removeFromParent(true);
            _btnB_bg.dispose();
         }
         if(_wordA_bg)
         {
            _wordA_bg.removeFromParent(true);
            _wordA_bg.dispose();
         }
         if(_wordB_bg)
         {
            _wordB_bg.removeFromParent(true);
            _wordB_bg.dispose();
         }
         if(_btnA_txt)
         {
            _btnA_txt.removeFromParent(true);
            _btnA_txt.dispose();
         }
         if(_btnB_txt)
         {
            _btnB_txt.removeFromParent(true);
            _btnB_txt.dispose();
         }
         if(_txt_coin)
         {
            _txt_coin.removeFromParent(true);
            _txt_coin.dispose();
         }
         if(txt_Integral)
         {
            txt_Integral.removeFromParent(true);
            txt_Integral.dispose();
         }
         if(_bgInfo)
         {
            _bgInfo.removeFromParent(true);
            _bgInfo.dispose();
         }
         if(txt_Inf)
         {
            txt_Inf.removeFromParent(true);
            txt_Inf.dispose();
         }
         btn_one = null;
         btn_ten = null;
         _btnA_bg = null;
         _btnB_bg = null;
         _wordA_bg = null;
         _wordB_bg = null;
         _btnA_txt = null;
         _btnB_txt = null;
         _txt_coin = null;
         txt_Integral = null;
         _bgInfo = null;
         txt_Inf = null;
      }
      private var _vipTransitionReceipts:Array = [];

      private static var _recruitmentReceipts:Array = [];

      private static function claimRecruitmentReceipt(param1:Object) : Boolean
      {
         if(param1 == null || param1.data == null || param1.data.avatars == null)
         {
            return false;
         }
         if(GlobalData.$userData == null || param1.state_sync != null
            && String(param1.state_sync.uid) != String(GlobalData.$userData.uid))
         {
            return false;
         }
         var _key:String = "";
         if(param1.params != null && param1.params.actionID != null)
         {
            _key = String(param1.params.actionID);
         }
         else if(param1.state_sync != null && param1.state_sync.uid != null && param1.state_sync.revision != null)
         {
            _key = String(param1.state_sync.uid) + ":" + String(param1.state_sync.revision);
         }
         if(_key == "") return true;
         if(_recruitmentReceipts.indexOf(_key) >= 0) return false;
         _recruitmentReceipts.push(_key);
         if(_recruitmentReceipts.length > 64) _recruitmentReceipts.shift();
         return true;
      }

      private function captureVipBefore(param1:Function) : Function
      {
         var _beforeVip:int = int(GlobalData.$userData.vip_lv);
         var _requestPayType:int = payType;
         var _requestActivity:Boolean = Boolean(getVipTime().can);
         var _started:int = getTimer();
         return function(param2:Object):void
         {
            param2._vip_before_request = _beforeVip;
            param2._vip_after_request = param2.data.user_dict != null ? int(param2.data.user_dict.vip_lv) : int(param2.data.vip_lv);
            param2.payType = _requestPayType;
            param2._vip_activity_request = _requestActivity;
            if(RpcStaticCall.$remoting != null)
            {
               RpcStaticCall.$remoting.reportDiagnostic("RECRUITMENT_RESPONSE|vip=1|times=" + (_requestPayType == 1 ? 10 : 1) + "|elapsed_ms=" + (getTimer() - _started));
            }
            param1(param2);
         };
      }

      private function showVipTransition(param1:Object) : void
      {
         if(this.stage == null)
         {
            return;
         }
         var _beforeVip:int = int(param1._vip_before_request);
         var _afterVip:int = int(param1._vip_after_request);
         if(_afterVip <= _beforeVip)
         {
            return;
         }
         if(_afterVip != int(GlobalData.$userData.vip_lv))
         {
            return;
         }
         var _revisionKey:String = String(param1.method) + ":" + String(param1.state_sync.uid) + ":" + String(param1.state_sync.revision);
         if(_vipTransitionReceipts.indexOf(_revisionKey) >= 0)
         {
            return;
         }
         _vipTransitionReceipts.push(_revisionKey);
         GlobalFunction.popAward("_$vip$_",GlobalLanguageStr.getLanguageStr(20203,_afterVip),_afterVip);
      }

   }
}
