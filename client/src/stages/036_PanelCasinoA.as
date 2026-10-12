package com.meng52.game.ui.panel
{
   import com.meng52.display.ScrollScreenForTxt;
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.module.map.GameMapConfig;
   import com.meng52.game.module.map.GameMapTools;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.element.HtmlTextField;
   import com.meng52.game.ui.element.ItemAvatarAward;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_IconText;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.game.ui.element.LOL_TextField;
   import com.meng52.game.ui.element.LOL_TimeStatus;
   import com.meng52.game.ui.screen.PanelCenterCasino;
   import com.meng52.game.ui.screen.PanelCenterShopVIP;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.HtmlTextFormat;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import starling.animation.Tween;
   import starling.display.Image;
   import starling.display.MovieClip;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.EnterFrameEvent;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   
   public class PanelCasinoA extends PanelCenterCasino
   {
      
      public static var FLASH_TIME:Number = 0.2;
      
      public static var M_AVATAR_Y:int = 590;
      
      public static var BTN_NAME_CASINO_ONE:String = "btn_name_casino_one";
      
      public static var BTN_NAME_CASINO_TEN:String = "btn_name_casino_ten";
      
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
      
      private var pay_ont_txt:TextField;
      
      private var pay_ten_txt:TextField;
      
      private var mOwn_txt:TextField;
      
      private var mTime_a:LOL_TimeStatus;
      
      private var mFree_a:LOL_IconText;
      
      private var _score:Boolean;
      
      private const ONE_RATE:int = 1;
      
      private const TEN_RATE:int = 10;
      
      private var _Txt_isFree:TextField;
      
      private var _wordA_bg:Image;
      
      private var _wordB_bg:Image;
      
      private var _mColor:int = 16777215;
      
      private var _isNormalFree:Boolean = false;
      
      private var _userData:Object;
      
      public function PanelCasinoA()
      {
         super();
      }
      
      public static function free_wager(param1:Boolean) : void
      {
         var _loc2_:String = param1 ? "coin" : "score";
         SendServiceAMFFun.send_user_wager_avatar(re_wager,{
            "wager_type":_loc2_,
            "times":1,
            "avatar_len":GlobalData.$userData_avatarNum,
            "free":1
         });
      }
      
      public static function re_wager(param1:Object) : void
      {
         var _loc6_:int = 0;
         var _loc5_:Array = GlobalData.$mConfig_simple.wager_avatar as Array;
         var _loc4_:int = int(param1["params"]["times"]);
         var _loc7_:Boolean = param1["params"]["free"] != 0;
         var _loc2_:Boolean = param1["params"]["wager_type"] == "coin";
         if(_loc2_)
         {
            if(_loc4_ == 1)
            {
               if(!_loc7_)
               {
                  if(!GlobalFunction.isVersionedProfileReceipt(param1))
                  {
                  GlobalData.$userData.medal += _loc5_[12];
                  }
               }
               else
               {
                  if(!GlobalFunction.isVersionedProfileReceipt(param1))
                  {
                  GlobalData.$userData.medal += _loc5_[11];
                  }
               }
            }
            else if(!_loc7_)
            {
               if(!GlobalFunction.isVersionedProfileReceipt(param1))
               {
               GlobalData.$userData.medal += _loc5_[13];
               }
            }
         }
         if(!_loc7_)
         {
            if(!_loc2_)
            {
               if(_loc4_ == 1)
               {
                  if(!GlobalFunction.isVersionedProfileReceipt(param1))
                  {
                  GlobalData.$userData.score -= _loc5_[2];
                  }
               }
               else
               {
                  if(!GlobalFunction.isVersionedProfileReceipt(param1))
                  {
                  GlobalData.$userData.score -= _loc5_[3];
                  }
               }
            }
            else
            {
               if(_loc4_ == 1)
               {
                  _loc6_ = int(_loc5_[0]);
               }
               else
               {
                  _loc6_ = int(_loc5_[1]);
               }
               if(!GlobalFunction.isVersionedProfileReceipt(param1))
               {
               GlobalFunction.payCoinVip(_loc6_);
               }
            }
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
         GlobalData.$userData.attrs = param1.data.attrs;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
         GlobalData.$userData.records = param1.data.records;
         }
         for(var _loc8_:Object in param1.data.new_avatars)
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalFunction.changeUserDataAvatars(_loc8_.toString(),param1.data.new_avatars[_loc8_],true);
            }
         }
         GlobalData.$tempCasinoResult = param1.data.new_avatars;
         GlobalData.$typeCasinoResult = param1["params"]["wager_type"];
         GuideMaster.getOnlyExample().guideWait();
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("");
         LayoutUIAnimation.getOnlyExample().clearAnimationLayer();
         var _loc3_:int = (_loc2_ ? 2 : 0) + (_loc7_ ? 1 : 0);
         LayoutUIAnimation.getOnlyExample().popCasino(param1.data.new_avatars,_loc3_,0,MainConfig.$casionBgUiName);
         if(!GlobalData.$isForceGuide)
         {
            LayoutUIAnimation.getOnlyExample().clearIfNoGuide();
         }
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(20059));
         this.addEventListener("close_panel_self",onCLOSE_PANEL_SELF);
         setPopUI();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalData.$mEventDispatcher.removeEventListener("update_casion_coin",formatTxtInfo);
         GlobalData.$mGameClassObject.mLayoutUIBottom.visible = true;
         GlobalData.$panelCasinoClipB = false;
         if(mTxt_info)
         {
            mTxt_info.removeFromParent(true);
            mTxt_info.dispose();
         }
         if(_txt_coin)
         {
            _txt_coin.removeFromParent(true);
            _txt_coin.dispose();
         }
         if(mBtn_one)
         {
            mBtn_one.removeFromParent(true);
            mBtn_one.dispose();
         }
         if(mBtn_ten)
         {
            mBtn_ten.removeFromParent(true);
            mBtn_ten.dispose();
         }
         if(mTxt_one)
         {
            mTxt_one.removeFromParent(true);
            mTxt_one.dispose();
         }
         if(mTxt_ten)
         {
            mTxt_ten.removeFromParent(true);
            mTxt_ten.dispose();
         }
         if(mBox)
         {
            StarlingTools.removeChildrenClear(mBox);
         }
         if(mClip_a)
         {
            mClip_a.removeFromParent(true);
            mClip_a.dispose();
         }
         if(mClip_b)
         {
            mClip_b.removeFromParent(true);
            mClip_b.dispose();
         }
         if(mList_box)
         {
            StarlingTools.removeChildrenClear(mList_box);
            mList_box.removeFromParent(true);
         }
         if(mBg_touch)
         {
            mBg_touch.removeFromParent(true);
            mBg_touch.dispose();
         }
         if(mImgBgClip)
         {
            mImgBgClip.removeFromParent(true);
            mImgBgClip.dispose();
         }
         if(mTime_a)
         {
            StarlingTools.removeChildrenClear(mTime_a);
            mTime_a.removeFromParent(true);
         }
         mTime_a = null;
         this.delBoxUI();
         this.delList();
         super.onREMOVED_FROM_STAGE(param1);
         _txt_coin = null;
         mTxt_info = null;
         mTxt_ten = null;
         mTxt_one = null;
         mBtn_one = null;
         mBtn_ten = null;
         mBox = null;
         mClip_a = null;
         mClip_b = null;
         mList_box = null;
         mBg_touch = null;
         mImgBgClip = null;
         GlobalFunction.delTextureByBD("png_bg_avatar");
      }
      
      override public function update() : void
      {
         this.setBoxUI();
         this.setJuggler_clipA(mImgBgClip);
      }
      
      public function setUI_box(param1:Boolean = false) : void
      {
         mImgBgClip = GlobalFunction.get_png_bg_avatar();
         mImgBgClip.touchable = false;
         this.addChildAt(mImgBgClip,0);
         if(param1)
         {
            mImgBgClip.y -= int(mImgBgClip.height * 0.4);
         }
         mRulerPoint = new Point();
         mRulerPoint.x = int((640 - mImgBgClip.width) * 0.5);
         mRulerPoint.y = int((960 - mImgBgClip.height) * 0.5);
      }
      
      public function delBoxUI() : void
      {
         StarlingTools.removeChildrenClear(this.mBox);
         if(mTxt_info)
         {
            mTxt_info.dispose();
         }
         this.mTxt_info = null;
         this.mBox = null;
      }
      
      public function setPopUI(param1:Boolean = false) : void
      {
         var _cfg:Array;
         var _avatar_name:Array;
         var _bottombg:String;
         var _bottombg1:String;
         var _btnA_bg:Image;
         var _btnB_bg:Image;
         var _imgArr:Array;
         var _length:int;
         var _mask:Rectangle;
         var _btnA_hero_bg:Image;
         var _btn_A_hero_sp:Sprite;
         var _btnB_hero_bg:Image;
         var _btn_B_hero_sp:Sprite;
         var _btnA_txt:LOL_TextField;
         var _btnB_txt:LOL_TextField;
         var _bgInfo:Scale9Image;
         var _config:Array;
         var _mColor:Array;
         var _num:int;
         var _str:String;
         var _mInfo:String;
         var _oneInfo_txt:HtmlTextField;
         var _tenInfo_txt:TextField;
         var _madel_a:madel_component;
         var _madel_b:madel_component;
         var _strOne:String;
         var _strTen:String;
         var _tw:Number;
         var _strID:int;
         var txt_battleinfo:TextFieldHtmlRenderer;
         var _recRank:Rectangle;
         var _str1:String;
         var _mInfoStr:String;
         var mInfo:ScrollScreenForTxt;
         var _sale:Image;
         var _bottom:Boolean = param1;
         this.mBox = new Sprite();
         _score = this.name == "center_casino_A";
         _cfg = GlobalData.$mConfig_simple.show_avatar;
         _userData = GlobalData.$userData;
         _avatar_name = _score ? _cfg[0] : _cfg[1];
         this.btn_one = GlobalFunction.createScale9Image("UI_bg_box_0_0000",260,330,new Rectangle(30,30,30,20));
         btn_one.x = this.mImg9_baseBg.width * 0.5 - btn_one.width - 10;
         mBox.addChild(this.btn_one);
         this.btn_ten = GlobalFunction.createScale9Image("UI_bg_box_0_0000",260,330,new Rectangle(30,30,30,20));
         btn_ten.x = this.mImg9_baseBg.width * 0.5 + 10;
         mBox.addChild(this.btn_ten);
         this.btn_one.y = this.btn_ten.y = this.mImg9_baseBg.y + 120;
         this.btn_one.name = BTN_NAME_CASINO_ONE;
         this.btn_ten.name = BTN_NAME_CASINO_TEN;
         if(_score)
         {
            _bottombg = "UI_bg_colorbottom_1_0000";
            _btnA_bg = GlobalFunction.createImage(_bottombg);
            _btnA_bg.x = btn_one.x + 13;
            _btnA_bg.y = btn_one.y + 12;
            _btnA_bg.touchable = false;
            mBox.addChildAt(_btnA_bg,0);
            _btnB_bg = GlobalFunction.createImage(_bottombg);
            _btnB_bg.x = btn_ten.x + 13;
            _btnB_bg.y = btn_ten.y + 12;
            _btnB_bg.touchable = false;
            mBox.addChildAt(_btnB_bg,0);
            _btnA_bg.width = _btnB_bg.width = 234;
            _btnA_bg.height = _btnB_bg.height = 304;
         }
         else
         {
            _imgArr = String(_cfg[1][0]).split("_");
            _length = int(_imgArr.length);
            _bottombg = int(String(_cfg[1][0]).split("_")[_length - 1]) < 6 ? "UI_bg_colorbottom_2_0000" : "UI_bg_colorbottom_3_0000";
            _bottombg1 = int(String(_cfg[1][1]).split("_")[_length - 1]) < 6 ? "UI_bg_colorbottom_2_0000" : "UI_bg_colorbottom_3_0000";
            _btnA_bg = GlobalFunction.createImage(_bottombg);
            _btnA_bg.x = btn_one.x + 13;
            _btnA_bg.y = btn_one.y + 12;
            _btnA_bg.touchable = false;
            mBox.addChildAt(_btnA_bg,0);
            _btnB_bg = GlobalFunction.createImage(_bottombg1);
            _btnB_bg.x = btn_ten.x + 13;
            _btnB_bg.y = btn_ten.y + 12;
            _btnB_bg.touchable = false;
            mBox.addChildAt(_btnB_bg,0);
            _btnA_bg.width = _btnB_bg.width = 234;
            _btnA_bg.height = _btnB_bg.height = 304;
         }
         _mask = new Rectangle(0,0,_btnA_bg.width,_btnA_bg.height);
         _btnA_hero_bg = GameMapTools.newAvatarImgById(_avatar_name[0],80,160);
         _btn_A_hero_sp = new Sprite();
         _btn_A_hero_sp.addChild(_btnA_hero_bg);
         _btn_A_hero_sp.clipRect = _mask;
         _btn_A_hero_sp.x = _btnA_bg.x;
         _btn_A_hero_sp.y = _btnA_bg.y;
         _btn_A_hero_sp.touchable = false;
         _btnA_hero_bg.scaleX = _btnA_hero_bg.scaleY = 0.85;
         mBox.addChild(_btn_A_hero_sp);
         _btnB_hero_bg = GameMapTools.newAvatarImgById(_avatar_name[1],80,160);
         _btn_B_hero_sp = new Sprite();
         _btn_B_hero_sp.addChild(_btnB_hero_bg);
         _btn_B_hero_sp.clipRect = _mask;
         _btn_B_hero_sp.x = _btnB_bg.x;
         _btn_B_hero_sp.y = _btnB_bg.y;
         _btn_B_hero_sp.touchable = false;
         _btnB_hero_bg.scaleX = _btnB_hero_bg.scaleY = 0.85;
         mBox.addChild(_btn_B_hero_sp);
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
         _bgInfo = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",560,169,new Rectangle(110,55,70,20));
         _bgInfo.x = int((GlobalData.$mStageWidth - _bgInfo.width) * 0.5);
         _bgInfo.y = this.mImg9_baseBg.y + this.mImg9_baseBg.height - _bgInfo.height - 30 - 5;
         mBox.addChild(_bgInfo);
         _config = GlobalData.$mConfig_simple.wager_avatar as Array;
         _mColor = [16777215,16764006,16777215,16764006];
         if(!_score)
         {
            _num = 1 + _config[14] - _userData.attrs.wager_coin_1_count % (_config[14] + 1);
            if(_userData.attrs.wager_coin_1_count == 0)
            {
               _str = GlobalLanguageStr.getLanguageStr(90426,_num);
            }
            else if(_num == 1 + _config[14])
            {
               _str = GlobalLanguageStr.getStr(90445);
            }
            else
            {
               _str = GlobalLanguageStr.getLanguageStr(90426,_num);
            }
            _mInfo = Tools.formatLineX(_str,_mColor,MainConfig.$isEA ? 15 : 20,MainConfig.$isEnglish ? 16 : 20);
            _oneInfo_txt = new HtmlTextField(MainConfig.$isEnglish ? 350 : 250,MainConfig.$isEA ? 60 : (MainConfig.$isEnglish ? 80 : 30),_mInfo,true,GlobalConfig.FONT_0);
            _oneInfo_txt.x = btn_one.x + 10;
            _oneInfo_txt.y = MainConfig.$isEA ? btn_ten.y - 49 : (MainConfig.$isEnglish ? btn_ten.y - 59 : btn_one.y - 30);
            _oneInfo_txt.hAlign = "left";
            mBox.addChild(_oneInfo_txt);
            _tenInfo_txt = GlobalFunction.createTextField(MainConfig.$isEA ? 250 : (MainConfig.$isEnglish ? 350 : 250),MainConfig.$isEA ? 60 : (MainConfig.$isEnglish ? 80 : 30),GlobalLanguageStr.getStr(90427),"",MainConfig.$isEnglish ? 16 : 20,16777215);
            _tenInfo_txt.x = btn_ten.x + 10;
            _tenInfo_txt.y = MainConfig.$isEA ? btn_ten.y - 49 : (MainConfig.$isEnglish ? btn_ten.y - 59 : btn_ten.y - 30);
            _tenInfo_txt.hAlign = "left";
            mBox.addChild(_tenInfo_txt);
            if(_config[12] / 1 > 1)
            {
               _madel_a = new madel_component();
               _madel_a.Num = _config[12] / 1;
               _madel_a.x = btn_one.x + btn_one.width - _madel_a.width;
               _madel_a.y = btn_one.y + 10;
               mBox.addChild(_madel_a);
            }
            if(_config[13] / 10 > 1)
            {
               _madel_b = new madel_component();
               _madel_b.Num = _config[13] / 10;
               _madel_b.x = btn_ten.x + btn_ten.width - _madel_b.width;
               _madel_b.y = btn_ten.y + 10;
               mBox.addChild(_madel_b);
            }
         }
         _isNormalFree = _userData.records.free_wager_count < _config[15];
         _strOne = "";
         _strTen = "";
         _tw = 158;
         _strID = 0;
         if(_score)
         {
            _strOne = _config[2].toString();
            _strTen = _config[3].toString();
            _strID = 20393;
         }
         else
         {
            _strOne = _config[0].toString();
            _strTen = _config[1].toString();
            _strID = 20394;
         }
         pay_ont_txt = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(_strID,_strOne),20,1118481,"center",MainConfig.$isEA ? _tw + 30 : _tw,35);
         pay_ten_txt = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(_strID,_strTen),20,1118481,"center",MainConfig.$isEA ? _tw + 40 : _tw,35);
         pay_ont_txt.x = btn_one.x + (btn_one.width - pay_ont_txt.width) * 0.5;
         pay_ten_txt.x = btn_ten.x + (btn_ten.width - pay_ten_txt.width) * 0.5;
         pay_ont_txt.y = pay_ten_txt.y = MainConfig.$isEA ? _wordA_bg.y + 5 : _wordA_bg.y;
         this.mBox.addChild(pay_ont_txt);
         this.mBox.addChild(pay_ten_txt);
         txt_battleinfo = GlobalTextStyle.getHtmlTextRenderer();
         txt_battleinfo.text = Tools.formatLineX(_score ? GlobalLanguageStr.getLanguageStr(90384) : GlobalLanguageStr.getLanguageStr(90385),[4926491,16711680,16711680,16776960],25,20);
         txt_battleinfo.mLayoutFun = function():void
         {
            _recRank = txt_battleinfo.getTextSnapshotFrame();
            txt_battleinfo.x = _bgInfo.x + (_bgInfo.width - _recRank.width) * 0.5;
            txt_battleinfo.y = _bgInfo.y + 30;
         };
         if(_score)
         {
            _str1 = PanelCenterShopVIP.infoUIsA()["score"];
            if(_str1 == "")
            {
               _str1 = GlobalLanguageStr.getStr(20490);
            }
         }
         else
         {
            _str1 = PanelCenterShopVIP.infoUIsA()["coin"];
         }
         _mInfoStr = HtmlTextFormat.font(_str1,4926491);
         mInfo = new ScrollScreenForTxt(_mInfoStr,_bgInfo.width - 60,_bgInfo.height - 45);
         mInfo.x = _bgInfo.x + 33;
         mInfo.y = _bgInfo.y + 25;
         mBox.addChild(mInfo);
         if(GlobalFunction.checkIsSale("center_casino") && !_score)
         {
            _sale = GlobalFunction.createImage("UI_sale_bg_2_0000");
            _sale.x = (GlobalData.$mStageWidth - _sale.width) * 0.5;
            _sale.y = 50;
            this.mBox.addChild(_sale);
         }
         this.formatTxtInfo();
         this.addChild(mBox);
         setFree();
         this.btn_one.addEventListener("touch",onTOUCH);
         this.btn_ten.addEventListener("touch",onTOUCH);
      }
      
      private function createTime() : void
      {
         var removeTimeA:* = function():void
         {
            if(mTime_a != null)
            {
               mTime_a.visible = false;
            }
            if(mFree_a != null)
            {
               mFree_a.removeFromParent(true);
               mFree_a = null;
            }
            createFree();
         };
         var _gap:Number = 78;
         if(mTime_a)
         {
            mTime_a.removeFromParent(true);
            mTime_a = null;
         }
         mTime_a = GlobalFunction.setWagerTime("mTime_a",mTime_a,_score ? 0 : 1,removeTimeA);
         mTime_a.x = btn_one.x + int((btn_one.width - 109) * 0.5) - 45 - 15;
         mTime_a.y = btn_one.y + btn_one.height - 45;
         mTime_a.scaleX = mTime_a.scaleY = 0.7;
         mBox.addChild(this.mTime_a);
      }
      
      private function createFree() : void
      {
         var _loc2_:String = null;
         var _loc1_:Array = null;
         if(mFree_a)
         {
            mFree_a.removeFromParent(true);
            mFree_a = null;
         }
         if(_score)
         {
            _loc1_ = GlobalData.$mConfig_simple.wager_avatar as Array;
            _isNormalFree = _userData.records.free_wager_count < _loc1_[15];
            if(_isNormalFree)
            {
               _loc2_ = GlobalLanguageStr.getLanguageStr(90441);
               _mColor = 65331;
               _wordA_bg.visible = false;
               pay_ont_txt.visible = false;
            }
            else
            {
               _loc2_ = GlobalLanguageStr.getStr(90437);
               _mColor = 6710886;
            }
         }
         else
         {
            _loc2_ = GlobalLanguageStr.getStr(90441);
            _wordA_bg.visible = false;
            pay_ont_txt.visible = false;
            _mColor = 65331;
         }
         mFree_a = new LOL_IconText(_loc2_,_mColor);
         mFree_a.bgWidth = 200;
         mFree_a.touchable = false;
         mFree_a.x = btn_one.x + 15;
         mFree_a.y = btn_one.y + btn_one.height - mFree_a.height - 5 - 5;
         mFree_a.scaleX = mFree_a.scaleY = 0.7;
         if(MainConfig.$isEA)
         {
            if(!_isNormalFree)
            {
               mFree_a.fontSize = 16;
            }
         }
         mBox.addChild(mFree_a);
      }
      
      private function setFree() : void
      {
         var _loc1_:Array = GlobalData.$mConfig_simple.wager_avatar as Array;
         _isNormalFree = _userData.records.free_wager_count < _loc1_[15];
         if(_score)
         {
            if(_isNormalFree)
            {
               createTime();
            }
            else
            {
               createFree();
            }
         }
         else if(GlobalFunction.checkWagerTime(1) > 0)
         {
            createTime();
         }
         else
         {
            createFree();
            _mColor = 6475106;
         }
      }
      
      private function checkFree() : void
      {
         if(mFree_a)
         {
            if(_score)
            {
               if(_isNormalFree)
               {
                  mFree_a.visible = !mTime_a.visible;
               }
               else
               {
                  mFree_a.visible = false;
                  mTime_a.visible = false;
               }
            }
            else
            {
               mFree_a.visible = !mTime_a.visible;
            }
         }
      }
      
      protected function onTOUCH(param1:TouchEvent) : void
      {
         var _loc5_:Scale9Image = param1.currentTarget as Scale9Image;
         var _loc4_:Touch = param1.getTouch(_loc5_,"ended");
         var _loc3_:Boolean = true;
         var _loc2_:int = 1;
         if(_loc4_)
         {
            if(_loc5_.name == BTN_NAME_CASINO_ONE)
            {
               _loc2_ = 1;
               if(_score)
               {
                  if(_isNormalFree)
                  {
                     if(GlobalFunction.checkWagerTime(0) > 0)
                     {
                        checkWager(_loc2_,0);
                     }
                     else
                     {
                        onFree();
                     }
                  }
                  else
                  {
                     checkWager(_loc2_,0);
                  }
               }
               else if(GlobalFunction.checkWagerTime(1) > 0)
               {
                  checkWager(_loc2_,0);
               }
               else
               {
                  onFree();
               }
            }
            else if(_loc5_.name == BTN_NAME_CASINO_TEN)
            {
               _loc2_ = 10;
               checkWager(_loc2_,0);
            }
         }
      }
      
      public function setBoxUI(param1:Boolean = false) : void
      {
         var _loc4_:Number = NaN;
         var _loc7_:Number = NaN;
         var _loc8_:Number = NaN;
         var _loc3_:Number = NaN;
         var _loc6_:Image = null;
         this.delBoxUI();
         this.mBox = new Sprite();
         var _loc5_:Boolean = this.name == "center_casino_A";
         this.mImgBg = GlobalFunction.createImage("UI_tariff_title_000" + (_loc5_ ? 0 : 1));
         this.mImgBg.touchable = false;
         this.mBox.addChild(this.mImgBg);
         this.addChild(this.mBox);
         this.mBox.x = 0;
         this.mBox.y = param1 ? GlobalData.$center_height_curr - 121 - this.mImgBg.height : GlobalData.formatVScaleY_center(850 * 0.1);
         this.mBtn_one = GlobalFunction.createButtonStarling("UI_tariff_btn_0000");
         var _loc11_:Number = this.mBtn_one.width + 40 * 2;
         var _loc9_:Number = this.mImgBg.height - this.mBtn_one.height - 40 + (_loc5_ ? 1 : 2);
         var _loc13_:Number = this.mImgBg.width * 0.5;
         this.mBtn_one.x = _loc5_ ? -6 : -7;
         this.mBtn_one.y = _loc9_;
         this.mBox.addChild(this.mBtn_one);
         this.mBtn_ten = GlobalFunction.createButtonStarling("UI_tariff_btn_0000");
         this.mBtn_ten.x = GlobalData.$mStageWidth - this.mBtn_one.width + (_loc5_ ? 2 : 3);
         this.mBtn_ten.y = _loc9_;
         this.mBox.addChild(this.mBtn_ten);
         this.mBtn_one.name = BTN_NAME_CASINO_ONE;
         this.mBtn_ten.name = BTN_NAME_CASINO_TEN;
         this.mBtn_one.addEventListener("triggered",this.onTRIGGERED_btns);
         this.mBtn_ten.addEventListener("triggered",this.onTRIGGERED_btns);
         var _loc10_:Array = GlobalData.$mConfig_simple.wager_avatar as Array;
         var _loc14_:String = "";
         var _loc15_:String = "";
         var _loc2_:Number = 158;
         var _loc12_:int = 0;
         if(_loc5_)
         {
            _loc14_ = _loc10_[2].toString();
            _loc15_ = _loc10_[3].toString();
            _loc4_ = this.mImgBg.x + 90;
            _loc7_ = this.mImgBg.y + 74;
            _loc8_ = this.mImgBg.x + 410;
            _loc3_ = _loc7_;
            _loc12_ = 20393;
         }
         else
         {
            _loc14_ = _loc10_[0].toString();
            _loc15_ = _loc10_[1].toString();
            _loc4_ = this.mImgBg.x + 100;
            _loc7_ = this.mImgBg.y + 74;
            _loc8_ = this.mImgBg.x + 405;
            _loc3_ = _loc7_;
            _loc12_ = 20394;
         }
         mTxt_one = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(_loc12_,_loc14_),25,_loc5_ ? 16777215 : 16763904,"center",_loc2_,35);
         mTxt_ten = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(_loc12_,_loc15_),25,_loc5_ ? 16777215 : 16763904,"center",_loc2_,35);
         mTxt_one.x = _loc4_;
         mTxt_one.y = _loc7_;
         mTxt_ten.x = _loc8_;
         mTxt_ten.y = _loc3_;
         this.mBox.addChild(mTxt_one);
         this.mBox.addChild(mTxt_ten);
         if(GlobalFunction.checkIsSale("center_casino") && !_loc5_)
         {
            _loc6_ = GlobalFunction.createImage("UI_sale_bg_2_0000");
            _loc6_.x = (GlobalData.$mStageWidth - _loc6_.width) * 0.5;
            _loc6_.y = 50;
            this.mBox.addChild(_loc6_);
         }
         this.formatTxtInfo();
      }
      
      public function formatTxtInfo() : void
      {
         var _loc1_:Array = GlobalData.$mConfig_simple.wager_avatar as Array;
         this.mNum_one = _loc1_[2];
         this.mNum_ten = _loc1_[3];
         var _loc2_:Number = Number(GlobalData.$userData.score);
         this.setTxtInfo(null,_loc2_,null,null,20163);
      }
      
      public function setTxtInfo(param1:*, param2:*, param3:*, param4:*, param5:*) : void
      {
         var _loc8_:Boolean = false;
         var _loc7_:String = null;
         var _loc9_:String = null;
         var _loc6_:String = null;
         if(this.mTxt_info == null)
         {
            _loc8_ = this.name == "center_casino_A";
            this.mTxt_info = GlobalTextStyle.getTextField("",20,16777215,"center",240,46);
            mTxt_info.hAlign = "left";
            mTxt_info.x = btn_one.x;
            mTxt_info.y = btn_one.y + btn_one.height + 20;
         }
         if(param5 != null)
         {
            _loc6_ = GlobalLanguageStr.getLanguageStr(90386,param2,GlobalLanguageStr.getStr(param5));
            this.mTxt_info.text = _loc6_;
            _loc7_ = _loc8_ ? GlobalLanguageStr.getLanguageStr(90495) : GlobalLanguageStr.getLanguageStr(90494);
            _loc9_ = _loc8_ ? "UI_bg_jidian_0_0000" : "UI_money_coin_0_0000";
         }
         else
         {
            this.mTxt_info.text = param2;
         }
         if(_txt_coin)
         {
            _txt_coin.removeFromParent(true);
            _txt_coin = null;
         }
         _txt_coin = new LOL_MutilTextFieldIcon(_loc7_,param2,_loc9_);
         _txt_coin.x = btn_one.x;
         if(_loc8_)
         {
            _txt_coin.iconScale = 0.7;
         }
         _txt_coin.y = btn_one.y + btn_one.height + 20;
         addChild(_txt_coin);
      }
      
      override public function onBTN_NAME_BACK() : void
      {
         if(this.mStatus_back == "status_normal")
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_casino");
         }
      }
      
      public function onTRIGGERED_btns(param1:Event) : void
      {
         var _loc3_:LOL_Button = param1.currentTarget as LOL_Button;
         var _loc2_:int = 1;
         if(_loc3_.name == BTN_NAME_CASINO_ONE)
         {
            _loc2_ = 1;
         }
         else if(_loc3_.name == BTN_NAME_CASINO_TEN)
         {
            _loc2_ = 10;
         }
         checkWager(_loc2_,0);
      }
      
      public function checkWager(param1:int = 1, param2:int = 0) : void
      {
         var _loc3_:Boolean = true;
         GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
         if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
         {
            GlobalFunction.popAvatarLen();
            return;
         }
         if(param2 == 0)
         {
            _loc3_ = true;
         }
         else
         {
            if(param1 == 1 && GlobalData.$userData.score < this.mNum_one && param2 == 0)
            {
               _loc3_ = false;
            }
            else if(param1 == 10 && GlobalData.$userData.score < this.mNum_ten && param2 == 0)
            {
               _loc3_ = false;
            }
            if(!_loc3_ && param2 == 0)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90013));
            }
         }
         if(_loc3_)
         {
            SendServiceAMFFun.send_user_wager_avatar(this.re_wager_avatar,{
               "wager_type":"score",
               "times":param1,
               "avatar_len":GlobalData.$userData_avatarNum,
               "free":param2
            });
         }
      }
      
      public function onFree() : void
      {
         checkWager(1,1);
      }
      
      public function re_wager_avatar(param1:Object) : void
      {
         var _loc3_:Array = GlobalData.$mConfig_simple.wager_avatar as Array;
         var _loc2_:int = int(param1["params"]["times"]);
         var _loc4_:int = int(param1["params"]["free"]);
         isTen = _loc2_ != 1;
         isFree = _loc4_ != 0;
         isCoin = param1["params"]["wager_type"] == "coin";
         onCLOSE_PANEL_SELF();
         re_wager(param1);
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
         GlobalData.$userData.score = param1.data.score;
         }
      }
      
      public function setClip_light_A() : void
      {
         GlobalData.$panelCasinoClipB = false;
         GlobalData.$mGameClassObject.touchable = false;
         delList();
         this.mClip_statusA = 0;
         this.mClip_statusB = 0;
         mClip_imgA = GlobalFunction.createImage("UI_color_0x00000000");
         mClip_imgA.width = GlobalData.$mStageWidth;
         mClip_imgA.height = GlobalData.$mStageHeight;
         mClip_imgA.alpha = 0;
         this.addChild(mClip_imgA);
         var _loc2_:Rectangle = mClip_imgA.getBounds(GlobalData.$mGameClassObject);
         mClip_imgA.x -= _loc2_.x;
         mClip_imgA.y -= _loc2_.y;
         var _loc1_:Tween = new Tween(mClip_imgA,FLASH_TIME);
         _loc1_.fadeTo(1);
         _loc1_.onComplete = setClip_light_A_onComplete;
         this.mJuggler.add(_loc1_);
      }
      
      private function setClip_light_A_onComplete() : void
      {
         this.mJuggler.removeTweens(mClip_imgA);
         var _loc1_:Tween = new Tween(mClip_imgA,1);
         _loc1_.fadeTo(0);
         _loc1_.onComplete = setClip_light_B_onComplete;
         this.mJuggler.add(_loc1_);
         this.delBoxUI();
         GlobalData.$mGameClassObject.mLayoutUIBottom.visible = false;
         this.mClip_statusA = 1;
      }
      
      private function setClip_light_B_onComplete() : void
      {
         mClip_imgA.removeFromParent(true);
         this.mJuggler.removeTweens(mClip_imgA);
      }
      
      public function setClip_light() : void
      {
         var _loc2_:String = null;
         mJugglerBox.y = 0;
         if(!mQuad)
         {
            mQuad = Tools.newQuad(GameMapConfig.SCREEN_WIDTH,GameMapConfig.SCREEN_HEIGHT);
         }
         mQuad.visible = true;
         mQuad.alpha = 1;
         mJugglerBox.addChild(mQuad);
         var _loc1_:Tween = new Tween(mQuad,FLASH_TIME * 3,"easeInOut");
         _loc1_.delay = FLASH_TIME * 2;
         _loc1_.fadeTo(0.2);
         mJuggler.add(_loc1_);
         if(!isCoin)
         {
            _loc2_ = "UI_movieClip_light_a_1";
            mClip_a = DisplayTools.newMc(_loc2_,325,M_AVATAR_Y + 9,15,true);
            mClip_a.scaleX = mClip_a.scaleY = 1.66;
            _loc1_ = new Tween(mClip_a,FLASH_TIME * 4,"easeIn");
            _loc1_.delay = FLASH_TIME * 2;
            _loc1_.fadeTo(0);
            mJuggler.add(_loc1_);
         }
         else
         {
            _loc2_ = "UI_movieClip_light_c_";
            mClip_a = DisplayTools.newMc(_loc2_,325,380,10 / 5,true);
            mClip_a.scaleX = mClip_a.scaleY = 1.5;
            _loc1_ = new Tween(mClip_a,FLASH_TIME * 2,"easeInOut");
            _loc1_.scaleTo(1);
            mJuggler.add(_loc1_);
            _loc1_ = new Tween(mClip_a,FLASH_TIME,"easeInOut");
            _loc1_.delay = FLASH_TIME * 4;
            _loc1_.fadeTo(0);
            mJuggler.add(_loc1_);
         }
         mJugglerBox.addChild(this.mClip_a);
         mJuggler.add(this.mClip_a);
      }
      
      public function setClip_lightA() : void
      {
         var _res:String;
         var _delayFun:Function;
         var _fun:Function = function():void
         {
            if(mQuad)
            {
               mQuad.alpha = 0.7;
            }
         };
         var _tween:Tween = new Tween(mQuad,FLASH_TIME * 2,"easeOut");
         _tween.delay = FLASH_TIME * 0.5 * 0.66;
         _tween.onStart = _fun;
         _tween.fadeTo(0.2);
         mJuggler.add(_tween);
         _tween = new Tween(mQuad,FLASH_TIME * 2,"easeOut");
         _tween.delay = FLASH_TIME * 3 * 0.66;
         _tween.onStart = _fun;
         _tween.fadeTo(0.2);
         mJuggler.add(_tween);
         _tween = new Tween(mQuad,FLASH_TIME * 3,"easeOut");
         _tween.delay = FLASH_TIME * 5.5 * 0.66;
         _tween.onStart = _fun;
         _tween.fadeTo(0);
         mJuggler.add(_tween);
         _tween = new Tween(mJugglerBox,FLASH_TIME * 2,"easeOutElastic");
         _tween.delay = FLASH_TIME * 5.5 * 0.66;
         _tween.onStart = function():void
         {
            if(mJugglerBox)
            {
               mJugglerBox.y = 30;
            }
         };
         _tween.animate("y",0);
         mJuggler.add(_tween);
         mJuggler.remove(mClip_a);
         if(isCoin)
         {
            _res = "UI_movieClip_light_a_2";
            mClip_a = DisplayTools.newMc(_res,325,M_AVATAR_Y + 9,15,true);
            mClip_a.scaleX = mClip_a.scaleY = 1.66;
            mClip_a.stop();
            mJugglerBox.addChild(this.mClip_a);
            mJuggler.add(this.mClip_a);
            _delayFun = function():void
            {
               if(mClip_a)
               {
                  mClip_a.play();
                  _tween = new Tween(mClip_a,FLASH_TIME * 4,"easeIn");
                  _tween.delay = FLASH_TIME * 2;
                  _tween.fadeTo(0);
                  mJuggler.add(_tween);
               }
            };
            mJuggler.delayCall(_delayFun,1);
         }
         _res = isCoin ? "UI_movieClip_light_e_2" : "UI_movieClip_light_e_1";
         mClip_b = DisplayTools.newMc(_res,320,M_AVATAR_Y,15,true);
         mClip_b.scaleX = mClip_b.scaleY = 1.66;
         mJugglerBox.addChild(this.mClip_b);
         mJuggler.add(this.mClip_b);
         SoundManager.getOnlyExample().playSound("getAvatar");
      }
      
      override public function onENTER_FRAME_juggler(param1:EnterFrameEvent) : void
      {
         var _loc3_:int = 0;
         var _loc5_:int = 0;
         var _loc4_:Number = NaN;
         var _loc2_:Tween = null;
         if(this.mJuggler)
         {
            this.mJuggler.advanceTime(param1.passedTime);
         }
         if(this.mClip_statusA == 1)
         {
            this.mClip_statusA = 2;
            setClip_light();
         }
         if(this.mClip_statusA == 2)
         {
            if(this.mClip_a && this.mClip_a.isComplete)
            {
               this.mClip_statusA = 3;
               this.mClip_a.stop();
               this.setClip_lightA();
            }
         }
         if(this.mClip_statusA == 3)
         {
            if(this.mClip_b && this.mClip_b.isComplete)
            {
               this.mClip_statusA = 4;
               this.mClip_b.stop();
               mClip_b.removeFromParent(true);
               this.mJuggler.remove(mClip_b);
            }
         }
         if(this.mClip_statusA == 4)
         {
            if(mClip_statusB == 1)
            {
               this.mClip_statusA = 5;
               this.setList();
               this.addList();
            }
         }
         if(this.mClip_statusA == 5)
         {
            this.mList_box.y -= 5;
            if(this.mList_box.y < this.mClip_awards_YY)
            {
               mClip_b.removeFromParent(true);
               this.mJuggler.remove(mClip_b);
               this.mClip_statusA = 6;
               _loc3_ = 0;
               _loc5_ = 0;
               while(_loc5_ < mList_box.numChildren)
               {
                  if(mList_box.getChildAt(_loc5_) is ItemAvatarAward)
                  {
                     _loc3_++;
                  }
                  _loc5_++;
               }
               if(_loc3_ == 1)
               {
                  _loc4_ = isCoin ? FLASH_TIME + 1 : FLASH_TIME;
                  _loc2_ = new Tween(this,_loc4_);
                  _loc2_.onComplete = openItem;
                  mJuggler.add(_loc2_);
                  _loc2_ = new Tween(this,FLASH_TIME * 3 * 1.5);
                  _loc2_.delay = _loc4_;
                  _loc2_.onComplete = overTween;
                  mJuggler.add(_loc2_);
               }
               else
               {
                  mJuggler.delayCall(overTween,2);
               }
            }
         }
      }
      
      public function openItem() : void
      {
         var _loc1_:ItemAvatarAward = null;
         _loc1_ = mList_box.getChildAt(0) as ItemAvatarAward;
         GlobalFunction.setDetaiAvatar(_loc1_.data,false);
      }
      
      public function overTween() : void
      {
         GlobalData.$mGameClassObject.touchable = true;
         GlobalData.$panelCasinoClipB = true;
         if(mBg_touch)
         {
            mBg_touch.touchable = true;
         }
         if(GlobalData.$currentGuide)
         {
            return;
         }
         var _loc1_:TextField = GlobalFunction.getNextTextField();
         _loc1_.x = GameMapConfig.SCREEN_WIDTH / 2 - mList_box.x;
         _loc1_.y = 200 - mList_box.y;
         mList_box.addChild(_loc1_);
      }
      
      override public function delList() : void
      {
         if(this.mList_box)
         {
            StarlingTools.removeChildrenClear(this.mList_box);
            this.mList_box.removeFromParent(true);
         }
         if(this.mBg_touch)
         {
            this.mBg_touch.removeFromParent(true);
         }
         this.mBg_touch = null;
         this.mList_box = null;
      }
      
      override public function setList() : void
      {
         delList();
         this.mBg_touch = GlobalFunction.createButtonStarling("UI_color_0x00000000");
         this.mBg_touch.width = GlobalData.$mStageWidth;
         this.mBg_touch.height = GlobalData.$mStageHeight;
         this.mBg_touch.alpha = 0;
         this.mBg_touch.touchable = false;
         this.mBg_touch.addEventListener("triggered",this.onTRIGGERED_continu);
         this.addChildAt(this.mBg_touch,1);
         this.mList_box = new Sprite();
         this.addChild(this.mList_box);
      }
      
      private function onTRIGGERED_continu(param1:Event) : void
      {
         GlobalData.$mGameClassObject.mLayoutUIBottom.visible = true;
         GlobalData.$panelCasinoClipB = false;
         this.setBoxUI();
         delList();
      }
      
      override public function addList() : void
      {
         var _data:Object;
         var _item:ItemAvatarAward;
         var _tween:Tween;
         var _glow:MovieClip;
         var _fun:Function;
         var i:Object;
         var _madelSpr:Sprite;
         var _config:Array;
         var _madel:Image;
         var _madelNum:int;
         var _numTf:LOL_TextField;
         var _obj:Object = GlobalData.$tempCasinoResult;
         var _num:int = 0;
         var _w:int = 100;
         if(_obj == null)
         {
            return;
         }
         _fun = function(param1:MovieClip):void
         {
            param1.play();
         };
         for(i in _obj)
         {
            _data = _obj[i];
            _data["id"] = i.toString();
            _item = new ItemAvatarAward();
            _item.data = _data;
            _item.x = _num % 5 * _w;
            _item.y = Math.floor(_num / 5) * (_item.height + 20);
            _item.pivotY = _item.height / 2;
            this.mList_box.addChild(_item);
            _item.scaleX = _item.scaleY = 0;
            _tween = new Tween(_item,0.5,"easeOutBack");
            _tween.delay = _num * 0.2;
            _tween.scaleTo(1);
            mJuggler.add(_tween);
            _glow = DisplayTools.newMc("UI_movieClip_light_d_",_item.x + 50,_item.y,15,true);
            _glow.stop();
            _glow.scaleX = _glow.scaleY = 0;
            this.mList_box.addChild(_glow);
            mJuggler.add(_glow);
            _tween = new Tween(_glow,0.5,"easeOutBack");
            _tween.onStart = _fun;
            _tween.onStartArgs = [_glow];
            _tween.delay = _num * 0.2;
            _tween.scaleTo(8);
            mJuggler.add(_tween);
            _num += 1;
         }
         this.mList_box.x = int((GlobalData.$mStageWidth - (_num > 5 ? 5 : _num) * _w) * 0.5);
         this.mList_box.y = M_AVATAR_Y;
         if(isCoin)
         {
            _madelSpr = new Sprite();
            _config = GlobalData.$mConfig_simple.wager_avatar as Array;
            _madel = GlobalFunction.createImage("UI_award_ui_type_0005");
            _madel.pivotX = _madel.width / 2;
            _madel.pivotY = _madel.height / 2;
            _madelSpr.addChild(_madel);
            _madelNum = int(isTen ? _config[13] : (isFree ? _config[11] : _config[12]));
            _numTf = GlobalTextStyle.getBitmapText(90 * 2,24,"+" + _madelNum,20,16777215,"center");
            _numTf.pivotX = _numTf.width / 2;
            _numTf.pivotY = _numTf.height / 2;
            _numTf.y = 30;
            _madelSpr.addChild(_numTf);
            _madelSpr.visible = false;
            _madelSpr.touchable = false;
            _madelSpr.y = -110;
            _madelSpr.x = (_num > 5 ? 5 : _num) * _w * 0.5 - 4;
            _madelSpr.scaleX = _madelSpr.scaleY = 2;
            mList_box.addChild(_madelSpr);
            _tween = new Tween(_madelSpr,0.6,"easeOutBack");
            _tween.scaleTo(1);
            _tween.delay = _num * 0.2 + 0.5;
            _tween.onStart = function(param1:Sprite):void
            {
               param1.visible = true;
            };
            _tween.onStartArgs = [_madelSpr];
            mJuggler.add(_tween);
         }
         if(isTen)
         {
            this.mList_box.y -= 100;
         }
         this.mClip_awards_YY = mList_box.y - 100;
      }
   }
}

import com.meng52.game.global.GlobalFunction;
import com.meng52.game.global.GlobalLanguageStr;
import starling.display.Image;
import starling.display.Sprite;
import starling.text.TextField;

class madel_component extends Sprite
{
   
   private var _icon:Image;
   
   private var _bg_txt:Image;
   
   private var _txt:TextField;
   
   private var _num:Number;
   
   public function madel_component()
   {
      super();
      this.setUI();
   }
   
   private function setUI() : void
   {
      _bg_txt = GlobalFunction.createImage("UI_wordbg_yellow_0_0000");
      _bg_txt.scaleX = 0.5;
      _bg_txt.y = 5;
      this.addChild(_bg_txt);
      _txt = GlobalFunction.createTextField(_bg_txt.width,30,"","",15);
      _txt.x = 10;
      _txt.y = 2 + 5;
      this.addChild(_txt);
      _icon = GlobalFunction.createImage("UI_exchange_icon_0_0000");
      _icon.scaleX = _icon.scaleY = 0.7;
      this.addChild(_icon);
   }
   
   public function clear() : void
   {
      if(_icon)
      {
         _icon.dispose();
         _icon.removeFromParent(true);
      }
      _icon = null;
      if(_txt)
      {
         _txt.dispose;
         _txt.removeFromParent(true);
      }
      _txt = null;
      if(_bg_txt)
      {
         _bg_txt.dispose;
         _bg_txt.removeFromParent(true);
      }
      _bg_txt = null;
   }
   
   public function set Num(param1:Number) : void
   {
      this._txt.text = GlobalLanguageStr.getLanguageStr(90424,param1);
      this._num = param1;
   }
   
   public function get Num() : Number
   {
      return this._num;
   }
}
