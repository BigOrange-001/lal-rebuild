package com.meng52.game.ui.screen
{
   import com.adobe.text.NativeText;
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalLocalStore;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.stage.LayoutUIPop;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.TextInput;
   import feathers.display.Scale9Image;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import starling.core.Starling;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.EventDispatcher;
   import starling.text.TextField;

   public class PanelLogin extends PanelBase
   {

      private static const mRegExp_mail:RegExp = /^([a-zA-Z0-9_\.\-])+\@(([a-zA-Z0-9\-])+\.)+([a-zA-Z0-9]{2,4})+$/;

      private var mType:int = 0;

      private var mBg_00:Quad;

      private var mBox:Sprite;

      private var mBg_login:Scale9Image;

      private var mBg_txt1:Scale9Image;

      private var mBg_txt2:Scale9Image;

      private var mBtn_regist:LOL_Button;

      private var mBtn_login:LOL_Button;

      private var mBtn_back:LOL_Button;

      private var mBtn_registTo:LOL_Button;

      private var mBtn_password:LOL_Scale9Button;

      private var mNT_id:NativeText;

      private var mNT_pass:NativeText;

      private var mTxt_title:TextField;

      private var mTxt_info:TextFieldHtmlRenderer;

      private var mTxt_id:TextField;

      private var mTxt_pass:TextField;

      private var _txtInput:TextInput;

      private const BTN_NAME_REGIST:String = "btn_name_regist";

      private const BTN_NAME_LOGIN:String = "btn_name_login";

      private const BTN_NAME_BACK:String = "btn_name_back";

      private const BTN_NAME_TO:String = "btn_name_to";

      private const BTN_NAME_CLOSE:String = "btn_name_close";

      private const BTN_NAME_STATIC:String = "btn_name_static";

      private const BTN_NAME_PASSWORD:String = "btn_name_password";

      private const BTN_NAME_QUIKLOGIN:String = "btn_name_quiklogin";

      private const BTN_NAME_BINDINGUSER:String = "btn_name_bindinguser";

      private var m0_id:String = "";

      private var m0_pw:String = "";

      private var mStatus:int = 0;

      private var _width:Number = 600;

      private var _height:Number = 420;

      private var _factor:Number;

      private var _isNotFullScreenX:Number;

      private var mBtn_QuikLogin:LOL_Button;

      private var mBtn_BindingUser:LOL_Scale9Button;

      private var mBtn_tier:LOL_Scale9Button;

      private var mTierMenu:Sprite;

      private var mTierIndex:int = 0;

      private static const TIER_KEYS:Array = ["small","wealthy","tycoon","protagonist","gm"];

      private static const TIER_NAMES:Array = ["小氪（每日648元）","富哥（每日2000元）","大佬（每日5000元）","系统文主角（每日20000元）","GM（不限额）"];

      public static function tierForOption(param1:int) : String
      {
         return param1 >= 0 && param1 < TIER_KEYS.length ? String(TIER_KEYS[param1]) : null;
      }

      public static function tierOptionIndex(param1:String) : int
      {
         for(var i:int = 0; i < TIER_KEYS.length; i++)
         {
            if(param1 == "spending_tier_" + i) return i;
         }
         return -1;
      }

      public static function registrationParams(param1:String, param2:String, param3:String, param4:int) : Object
      {
         return {"session_key":param1,"sessionid":param2,"pf":param3,"spending_tier":tierForOption(param4)};
      }

      public static function loginParams(param1:String, param2:String, param3:String) : Object
      {
         return {"session_key":param1,"sessionid":param2,"pf":param3};
      }

      public function PanelLogin(param1:int = 0)
      {
         mStatus = param1;
         super();
      }

      override protected function initializeHandler(param1:Event) : void
      {
         var _loc2_:String = "";
         if(mStatus == 0)
         {
            _loc2_ = GlobalLanguageStr.getLanguageStr(20221);
         }
         else if(mStatus == 1)
         {
            _loc2_ = GlobalLanguageStr.getLanguageStr(20246);
         }
         else if(mStatus == 2)
         {
            _loc2_ = GlobalLanguageStr.getLanguageStr(20222);
         }
         else if(mStatus == 3 || mStatus == 4)
         {
            _loc2_ = GlobalLanguageStr.getLanguageStr(20221);
         }
         else if(mStatus == 98)
         {
            _loc2_ = GlobalLanguageStr.getLanguageStr(90709);
         }
         else if(mStatus == 99)
         {
            _loc2_ = GlobalLanguageStr.getLanguageStr(20455);
         }
         if(mStatus == 2 || mStatus == 3 || mStatus == 4)
         {
            _height = 500;
         }
         this.setPopPanelBg(_loc2_,_height,_width);
         this._factor = Starling.contentScaleFactor;
         this._isNotFullScreenX = Starling.current.viewPort.x;
         initUI();
      }

      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         LayoutUIPop.$touch = true;
         delNT();
         if(mBg_login)
         {
            mBg_login.removeFromParent(true);
            mBg_login.dispose();
         }
         if(mBg_txt1)
         {
            mBg_txt1.removeFromParent(true);
         }
         if(mBg_txt2)
         {
            mBg_txt2.removeFromParent(true);
         }
         if(mBtn_password)
         {
            mBtn_password.removeFromParent(true);
         }
         StarlingTools.removeChildrenClear(mBox);
         StarlingTools.removeChildrenClear(this);
         if(this.mBg_00)
         {
            this.mBg_00.dispose();
         }
         if(this.mBtn_regist)
         {
            this.mBtn_regist.dispose();
         }
         if(this.mBtn_login)
         {
            this.mBtn_login.dispose();
         }
         if(this.mBtn_back)
         {
            this.mBtn_back.dispose();
         }
         if(this.mBtn_registTo)
         {
            this.mBtn_registTo.dispose();
         }
         if(mTxt_title)
         {
            mTxt_title.dispose();
         }
         if(mTxt_info)
         {
            mTxt_info.dispose();
         }
         if(mTxt_id)
         {
            mTxt_id.dispose();
         }
         if(mTxt_pass)
         {
            mTxt_pass.dispose();
         }
         if(mBtn_QuikLogin)
         {
            mBtn_QuikLogin.dispose();
         }
         if(mBtn_BindingUser)
         {
            mBtn_BindingUser.dispose();
         }
         this.clear();
         mBg_txt1 = null;
         mBg_txt2 = null;
         mBg_login = null;
         mBtn_regist = null;
         mBtn_login = null;
         mBtn_back = null;
         mBtn_registTo = null;
         mTxt_title = null;
         mNT_id = null;
         mNT_pass = null;
         mTxt_info = null;
         mTxt_id = null;
         mTxt_pass = null;
         mBtn_QuikLogin = null;
         mBtn_BindingUser = null;
         mBtn_tier = null;
         mTierMenu = null;
      }

      private function initUI() : void
      {
         this.mType = 0;
         this.mBox = new Sprite();
         mBox.x = mImg9_baseBg.x;
         mBox.y = mImg9_baseBg.y;
         mBox.width = mImg9_baseBg.width;
         this.addChild(this.mBox);
         mBg_txt1 = GlobalFunction.createScale9Image("UI_bg_9slice_6_0000",355,48,new Rectangle(20,20,10,10));
         mBg_txt1.width = 400;
         mBg_txt1.x = int((GlobalData.$mStageWidth - mBg_txt1.width) * 0.5) - 25;
         if(MainConfig.$isEnglish == true)
         {
            mBg_txt1.y = 210;
         }
         else
         {
            mBg_txt1.y = 165;
         }
         this.mBox.addChild(mBg_txt1);
         mBg_txt2 = GlobalFunction.createScale9Image("UI_bg_9slice_6_0000",355,48,new Rectangle(20,20,10,10));
         mBg_txt2.width = 400;
         mBg_txt2.x = mBg_txt1.x;
         mBg_txt2.y = mBg_txt1.y + 55;
         this.mBox.addChild(mBg_txt2);
         this.mBtn_regist = GlobalFunction.createButtonStarling("UI_btn_normalFun_0000",{
            "t":GlobalLanguageStr.getLanguageStr(90659),
            "fs":(MainConfig.$isEnglish ? 21 : 25),
            "fc":1118481
         });
         this.mBtn_regist.shadowFilter();
         this.mBtn_regist.name = "btn_name_regist";
         this.mBtn_regist.addEventListener("triggered",this.onTRIGGERED_btns);
         this.mBox.addChild(this.mBtn_regist);
         this.mBtn_login = GlobalFunction.createButtonStarling("UI_btn_normalFun_0000",{
            "t":GlobalLanguageStr.getLanguageStr(20454),
            "fs":25,
            "fc":1118481
         });
         this.mBtn_login.shadowFilter();
         this.mBtn_login.name = "btn_name_login";
         this.mBtn_login.addEventListener("triggered",this.onTRIGGERED_btns);
         this.mBox.addChild(this.mBtn_login);
         this.mBtn_back = GlobalFunction.createButtonStarling("UI_btn_normalFun_0000",{
            "t":GlobalLanguageStr.getLanguageStr(20453),
            "fs":25,
            "fc":1118481
         });
         this.mBtn_back.shadowFilter();
         this.mBtn_back.name = "btn_name_back";
         this.mBtn_back.addEventListener("triggered",this.onTRIGGERED_btns);
         this.addChild(this.mBtn_back);
         this.mBtn_registTo = GlobalFunction.createButtonStarling("UI_btn_normalFun_0000",{
            "t":GlobalLanguageStr.getLanguageStr(20452),
            "fs":25,
            "fc":1118481
         });
         this.mBtn_registTo.shadowFilter();
         this.mBtn_registTo.name = "btn_name_to";
         this.mBtn_registTo.addEventListener("triggered",this.onTRIGGERED_btns);
         this.addChild(this.mBtn_registTo);
         mBtn_password = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20455),150,70,"UI_btn_normalFun_0000");
         if(MainConfig.$isEnglish)
         {
            mBtn_password.fontSize = 19;
         }
         mBtn_password.shadowFilter();
         mBtn_password.name = "btn_name_password";
         mBtn_password.addEventListener("triggered",this.onTRIGGERED_btns);
         this.mBox.addChild(mBtn_password);
         this.mBtn_QuikLogin = GlobalFunction.createButtonStarling("UI_btn_normalFun_0000",{
            "t":GlobalLanguageStr.getLanguageStr(90710),
            "fs":(MainConfig.$isEnglish ? 20 : 25),
            "fc":1118481
         });
         this.mBtn_QuikLogin.shadowFilter();
         this.mBtn_QuikLogin.name = "btn_name_quiklogin";
         this.mBtn_QuikLogin.addEventListener("triggered",this.onTRIGGERED_btns);
         this.addChild(this.mBtn_QuikLogin);
         mBtn_BindingUser = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90709),150,70,"UI_btn_normalFun_0000");
         mBtn_BindingUser.shadowFilter();
         if(MainConfig.$isEnglish)
         {
            mBtn_BindingUser.fontSize = 17;
         }
         mBtn_BindingUser.name = "btn_name_bindinguser";
         mBtn_BindingUser.addEventListener("triggered",this.onTRIGGERED_btns);
         this.mBox.addChild(mBtn_BindingUser);
         this.createTierSelector();
         var _loc4_:Number = GlobalData.$mStageWidth * 0.5;
         if(GlobalFunction.checkQuikLogin())
         {
            this.mBtn_back.x = _loc4_ - this.mBtn_regist.width - 20 - 86;
            this.mBtn_regist.x = _loc4_ - this.mBtn_regist.width - 20 - 20 - 86;
            this.mBtn_registTo.x = _loc4_ + 20 - 10 - 86;
            this.mBtn_login.x = _loc4_ + 20 - 30 - 86;
            this.mBtn_QuikLogin.x = mBtn_login.x + mBtn_login.width + 50;
         }
         else
         {
            this.mBtn_back.x = _loc4_ - this.mBtn_regist.width - 20;
            this.mBtn_regist.x = _loc4_ - this.mBtn_regist.width - 20 - 20;
            this.mBtn_registTo.x = _loc4_ + 20 - 10;
            this.mBtn_login.x = _loc4_ + 20 - 30;
         }
         if(MainConfig.$isEnglish == true)
         {
            this.mBtn_BindingUser.y = this.mBtn_QuikLogin.y = mBtn_password.y = this.mBtn_back.y = this.mBtn_regist.y = this.mBtn_registTo.y = this.mBtn_login.y = mBg_txt2.y + 57;
         }
         else
         {
            this.mBtn_BindingUser.y = this.mBtn_QuikLogin.y = mBtn_password.y = this.mBtn_back.y = this.mBtn_regist.y = this.mBtn_registTo.y = this.mBtn_login.y = mBg_txt2.y + 65;
         }
         var _loc3_:String = "";
         this.mBtn_regist.visible = false;
         this.mBtn_back.visible = false;
         this.mBtn_registTo.visible = false;
         this.mBtn_login.visible = false;
         this.mBtn_password.visible = false;
         this.mBtn_QuikLogin.visible = false;
         this.mBtn_BindingUser.visible = false;
         var _loc1_:Number = int(_loc4_ - _width * 0.5);
         var _loc2_:String = "";
         if(mStatus == 0)
         {
            _loc3_ = GlobalLanguageStr.getLanguageStr(20221);
            _loc2_ = GlobalLanguageStr.getLanguageStr(90153);
            this.mBtn_login.visible = true;
            this.mBtn_login.x = _loc1_;
         }
         else if(mStatus == 2)
         {
            _loc3_ = GlobalLanguageStr.getLanguageStr(20222);
            _loc2_ = GlobalLanguageStr.getLanguageStr(90152);
            this.mBtn_registTo.visible = true;
            this.mBtn_registTo.x = _loc1_;
         }
         else if(mStatus == 3 || mStatus == 4)
         {
            _loc3_ = GlobalLanguageStr.getLanguageStr(20221);
            _loc2_ = GlobalLanguageStr.getLanguageStr(90153);
            mBtn_regist.visible = mBtn_login.visible = true;
            if(GlobalFunction.checkQuikLogin())
            {
               mBtn_QuikLogin.visible = true;
            }
            mBtn_close.visible = mStatus == 4;
            LayoutUIPop.$touch = mBtn_close.visible;
         }
         else if(mStatus == 99)
         {
            _loc3_ = GlobalLanguageStr.getLanguageStr(20455);
            _loc2_ = GlobalLanguageStr.getLanguageStr(90177,GlobalLocalStore.getMeng52UID());
            mBtn_close.visible = true;
            mBtn_password.visible = true;
            mBtn_password.x = _loc1_ + 200;
            LayoutUIPop.$touch = mBtn_close.visible;
         }
         else if(mStatus == 98)
         {
            _loc3_ = GlobalLanguageStr.getLanguageStr(20246);
            _loc2_ = GlobalLanguageStr.getLanguageStr(90154);
            mBtn_close.visible = true;
            mBtn_BindingUser.visible = true;
            mBtn_BindingUser.x = _loc1_ + 200;
            LayoutUIPop.$touch = mBtn_close.visible;
         }
         mTxt_info = GlobalTextStyle.getHtmlTextRenderer();
         if(mStatus == 99)
         {
            mTxt_info.text = Tools.formatLineX(_loc2_,[16777215,16764006,16777215,16777215],23,20,false,"left");
            mTxt_info.x = 100;
            mTxt_info.y = this.mImg9_baseBg.y + 95;
         }
         else
         {
            mTxt_info.text = Tools.formatLineX(_loc2_,[16777215,16764006,16777215,16777215],21,20,false,"left");
            mTxt_info.x = 95;
            mTxt_info.y = this.mImg9_baseBg.y + 95;
         }
         this.mBox.addChild(this.mTxt_info);
         this.delNT();
         this.setNT_id();
         this.setNT_pass();
         if(mStatus == 98)
         {
            setTxtID("");
            setTxtPS("");
         }
         updateTierVisibility();
      }

      private function createTierSelector() : void
      {
         mBtn_tier = new LOL_Scale9Button("有钱程度：" + TIER_NAMES[mTierIndex] + " ▼",400,50,"UI_btn_normalFun_0000");
         mBtn_tier.x = mBg_txt1.x;
         mBtn_tier.y = mBg_txt2.y + 145;
         mBtn_tier.addEventListener("triggered",openTierMenu);
         mBox.addChild(mBtn_tier);
         mTierMenu = new Sprite();
         var background:Scale9Image = GlobalFunction.createScale9Image("UI_bg_9slice_6_0000",420,310,new Rectangle(20,20,10,10));
         background.x = mBg_txt1.x - 10;
         background.y = 93;
         mTierMenu.addChild(background);
         for(var i:int = 0; i < TIER_NAMES.length; i++)
         {
            var option:LOL_Scale9Button = new LOL_Scale9Button(String(TIER_NAMES[i]),390,49,"UI_btn_normalFun_0000");
            option.name = "spending_tier_" + i;
            option.x = mBg_txt1.x + 5;
            option.y = 101 + i * 56;
            option.addEventListener("triggered",chooseTier);
            mTierMenu.addChild(option);
         }
         mTierMenu.visible = false;
         mBox.addChild(mTierMenu);
      }

      private function updateTierVisibility() : void
      {
         if(mBtn_tier)
         {
            mBtn_tier.visible = mStatus == 2 || mType == 2;
         }
         if(mTierMenu && mBtn_tier && !mBtn_tier.visible)
         {
            mTierMenu.visible = false;
         }
      }

      private function openTierMenu(param1:Event) : void
      {
         if(mNT_id) mNT_id.visible = false;
         if(mNT_pass) mNT_pass.visible = false;
         mBox.setChildIndex(mTierMenu,mBox.numChildren - 1);
         mTierMenu.visible = true;
      }

      private function chooseTier(param1:Event) : void
      {
         var index:int = tierOptionIndex(String(param1.currentTarget.name));
         if(index >= 0 && index < TIER_KEYS.length)
         {
            mTierIndex = index;
            mBtn_tier.text = "有钱程度：" + TIER_NAMES[index] + " ▼";
         }
         mTierMenu.visible = false;
         btn_CloseEvent();
      }

      override public function onTRIGGERED_closePanel(param1:Event) : void
      {
         super.onTRIGGERED_closePanel(param1);
         GlobalData.$mEventDispatcher.dispatchEventWith("login_status_out");
      }

      private function checkBtnStatus() : void
      {
         var _loc1_:String = null;
         if(mType == 2)
         {
            if(mTxt_info)
            {
               mTxt_info.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90152),[16777215,16764006,16777215,16777215],MainConfig.$isEnglish ? 26 : 21,MainConfig.$isEnglish ? 19 : 20,false,"left");
            }
            m0_id = getNT_id();
            m0_pw = getNT_pass();
            setTxtID("");
            setTxtPS("");
            mTxt_titile.text = GlobalLanguageStr.getLanguageStr(20222);
            mBtn_regist.visible = mBtn_login.visible = false;
            mBtn_back.visible = mBtn_registTo.visible = true;
            setAsPassword(false);
         }
         else
         {
            if(mTxt_info)
            {
               _loc1_ = "";
               _loc1_ = GlobalLanguageStr.getLanguageStr(90153);
               mTxt_info.text = Tools.formatLineX(_loc1_,[16777215,16764006,16777215,16777215],21,20,false,"left");
            }
            setTxtID(m0_id);
            setTxtPS(m0_pw);
            m0_id = "";
            m0_pw = "";
            mTxt_titile.text = GlobalLanguageStr.getLanguageStr(20221);
            mBtn_regist.visible = mBtn_login.visible = true;
            mBtn_back.visible = mBtn_registTo.visible = false;
            setAsPassword(true);
         }
         mBtn_close.visible = mType == 4;
         LayoutUIPop.$touch = mBtn_close.visible;
         updateTierVisibility();
      }

      private function onTRIGGERED_btns(param1:Event) : void
      {
         var _loc7_:Boolean = false;
         var _loc8_:Boolean = false;
         var _loc9_:String = null;
         var _loc5_:String = null;
         var _loc10_:Number = NaN;
         var _loc11_:String = null;
         var _loc3_:String = null;
         var _loc2_:String = null;
         var _loc12_:String = null;
         var _loc14_:String = null;
         var _loc6_:String = null;
         var _loc4_:Object = null;
         mNT_id.visible = false;
         mNT_pass.visible = false;
         var _loc13_:EventDispatcher = param1.currentTarget;
         if(_loc13_.name == "btn_name_regist")
         {
            this.mType = 2;
            this.checkBtnStatus();
            btn_CloseEvent();
         }
         else if(_loc13_.name == "btn_name_login")
         {
            if(getNT_id().length <= 0 || getNT_pass().length <= 0)
            {
               GlobalFunction.tipsOS_ios(GlobalLanguageStr.getLanguageStr(90010),GlobalLanguageStr.getLanguageStr(90067),GlobalLanguageStr.getLanguageStr(20021),btn_CloseEvent);
            }
            else
            {
               SendServiceAMFFun.send_user_llogin(re_llogin,loginParams(getNT_id(),getNT_pass(),GlobalLocalStore.$pf_type_curr));
            }
         }
         else if(_loc13_.name == "btn_name_back")
         {
            this.mType = mStatus;
            this.checkBtnStatus();
            btn_CloseEvent();
         }
         else if(_loc13_.name == "btn_name_to")
         {
            if(getNT_id().length <= 0 || getNT_pass().length <= 0)
            {
               GlobalFunction.tipsOS_ios(GlobalLanguageStr.getLanguageStr(90010),GlobalLanguageStr.getLanguageStr(90067),GlobalLanguageStr.getLanguageStr(20021),btn_CloseEvent);
            }
            else
            {
               _loc7_ = false;
               _loc8_ = true;
               _loc9_ = getNT_id();
               _loc5_ = getNT_pass();
               _loc10_ = Number(_loc9_);
               if(isNaN(_loc10_))
               {
                  _loc7_ = mRegExp_mail.test(_loc9_);
                  if(!_loc7_)
                  {
                     GlobalFunction.tipsOS_ios(GlobalLanguageStr.getLanguageStr(90010),GlobalLanguageStr.getLanguageStr(90155),GlobalLanguageStr.getLanguageStr(20021),btn_CloseEvent);
                  }
               }
               else if(_loc9_.length >= 11 && int(_loc9_.charAt(0)) != 0)
               {
                  _loc7_ = true;
               }
               else
               {
                  GlobalFunction.tipsOS_ios(GlobalLanguageStr.getLanguageStr(90010),GlobalLanguageStr.getLanguageStr(90156),GlobalLanguageStr.getLanguageStr(20021),btn_CloseEvent);
               }
               if(_loc7_ && _loc8_)
               {
                  SendServiceAMFFun.send_user_register(re_register,registrationParams(_loc9_,_loc5_,GlobalLocalStore.$pf_type_curr,mTierIndex));
               }
            }
         }
         else if(_loc13_.name == "btn_name_close")
         {
            GlobalData.$mEventDispatcher.dispatchEventWith("login_status_out",false,{
               "status":mStatus,
               "type":1
            });
         }
         else if(_loc13_.name != "btn_name_static")
         {
            if(_loc13_.name == "btn_name_password")
            {
               if(getNT_id().length <= 0 || getNT_pass().length <= 0 || getNT_id() != GlobalLocalStore.$pf_uid_curr)
               {
                  GlobalFunction.tipsOS_ios(GlobalLanguageStr.getLanguageStr(90010),GlobalLanguageStr.getLanguageStr(90180),GlobalLanguageStr.getLanguageStr(20021),btn_CloseEvent);
               }
               else if(MainConfig.$isEnglish)
               {
                  _loc11_ = GlobalLanguageStr.getLanguageStr(90181);
                  _loc3_ = _loc11_.slice(0,35) + "[" + GlobalLocalStore.getMeng52UID() + "]";
                  _loc2_ = _loc11_.slice(37,_loc11_.length - 5) + "[" + getNT_pass() + "]" + "？";
                  GlobalFunction.tipsOS_ios(GlobalLanguageStr.getLanguageStr(90010),_loc3_ + _loc2_,GlobalLanguageStr.getLanguageStr(20021),sendService_password,GlobalLanguageStr.getLanguageStr(20104),btn_CloseEvent,btn_CloseEvent);
               }
               else
               {
                  _loc11_ = GlobalLanguageStr.getLanguageStr(90181);
                  _loc3_ = _loc11_.slice(0,5) + "[" + GlobalLocalStore.getMeng52UID() + "]";
                  _loc2_ = _loc11_.slice(9,_loc11_.length - 5) + "[" + getNT_pass() + "]" + "？";
                  GlobalFunction.tipsOS_ios(GlobalLanguageStr.getLanguageStr(90010),_loc3_ + _loc2_,GlobalLanguageStr.getLanguageStr(20021),sendService_password,GlobalLanguageStr.getLanguageStr(20104),btn_CloseEvent,btn_CloseEvent);
               }
            }
            else if(_loc13_.name == "btn_name_quiklogin")
            {
               _loc12_ = GlobalLocalStore.getQuickUID();
               _loc14_ = GlobalLocalStore.getQuickPW();
               if(_loc12_ && _loc14_)
               {
                  GlobalLocalStore.$pf_token_curr = _loc12_;
                  GlobalLocalStore.$pf_uid_curr = _loc14_;
                  GlobalData.$mEventDispatcher.dispatchEventWith("login_status_out",false,{
                     "status":mStatus,
                     "type":98
                  });
                  _loc6_ = GlobalLanguageStr.getLanguageStr(90710) + GlobalLanguageStr.getLanguageStr(90074);
                  _loc6_ = _loc6_ + ("\n" + GlobalLanguageStr.getLanguageStr(90711));
                  GlobalFunction.tipsOS_ios(GlobalLanguageStr.getLanguageStr(90010),_loc6_,"OK",btn_CloseEvent);
                  LayoutUIPop.$touch = mBtn_close.visible = true;
               }
               else
               {
                  SendServiceAMFFun.send_user_default_register(re_default_register,{"pf":GlobalLocalStore.$pf_type_curr});
               }
            }
            else if(_loc13_.name == "btn_name_bindinguser")
            {
               if(getNT_id().length <= 0 || getNT_pass().length <= 0)
               {
                  GlobalFunction.tipsOS_ios(GlobalLanguageStr.getLanguageStr(90010),GlobalLanguageStr.getLanguageStr(90067),GlobalLanguageStr.getLanguageStr(20021),btn_CloseEvent);
               }
               else
               {
                  _loc7_ = false;
                  _loc8_ = true;
                  _loc9_ = getNT_id();
                  _loc5_ = getNT_pass();
                  _loc10_ = Number(_loc9_);
                  if(isNaN(_loc10_))
                  {
                     _loc7_ = mRegExp_mail.test(_loc9_);
                     if(!_loc7_)
                     {
                        GlobalFunction.tipsOS_ios(GlobalLanguageStr.getLanguageStr(90010),GlobalLanguageStr.getLanguageStr(90155),GlobalLanguageStr.getLanguageStr(20021),btn_CloseEvent);
                     }
                  }
                  else if(_loc9_.length >= 11 && int(_loc9_.charAt(0)) != 0)
                  {
                     _loc7_ = true;
                  }
                  else
                  {
                     GlobalFunction.tipsOS_ios(GlobalLanguageStr.getLanguageStr(90010),GlobalLanguageStr.getLanguageStr(90156),GlobalLanguageStr.getLanguageStr(20021),btn_CloseEvent);
                  }
                  btn_CloseEvent();
                  if(_loc7_ && _loc8_)
                  {
                     _loc4_ = {};
                     _loc4_.def_session_key = GlobalLocalStore.$pf_token_curr;
                     _loc4_.def_sessionid = GlobalLocalStore.$pf_uid_curr;
                     _loc4_.session_key = getNT_id();
                     _loc4_.sessionid = getNT_pass();
                     _loc4_.pf = GlobalLocalStore.$pf_type_curr;
                     SendServiceAMFFun.send_user_bind(re_bind,_loc4_);
                  }
               }
            }
         }
      }

      private function re_default_register(param1:Object) : void
      {
         GlobalLocalStore.$pf_token_curr = param1.data.session_key;
         GlobalLocalStore.$pf_uid_curr = param1.data.sessionid;
         GlobalLocalStore.setQuickUID(GlobalLocalStore.$pf_token_curr);
         GlobalLocalStore.setQuickPW(GlobalLocalStore.$pf_uid_curr);
         GlobalData.$mEventDispatcher.dispatchEventWith("login_status_out",false,{
            "status":mStatus,
            "type":98
         });
         var _loc2_:String = GlobalLanguageStr.getLanguageStr(90710) + GlobalLanguageStr.getLanguageStr(90074);
         _loc2_ += "\n" + GlobalLanguageStr.getLanguageStr(90711);
         GlobalFunction.tipsOS_ios(GlobalLanguageStr.getLanguageStr(90010),_loc2_,"OK",btn_CloseEvent);
         LayoutUIPop.$touch = mBtn_close.visible = true;
      }

      public function btn_CloseEvent() : void
      {
         if(mNT_id)
         {
            mNT_id.visible = true;
         }
         if(mNT_pass)
         {
            mNT_pass.visible = true;
         }
      }

      private function sendService_password() : void
      {
         var _loc1_:Object = {};
         _loc1_.session_key = GlobalLocalStore.getMeng52UID();
         _loc1_.sessionid = getNT_id();
         _loc1_.new_sessionid = getNT_pass();
         _loc1_.pf = GlobalLocalStore.$pf_type_curr;
         SendServiceAMFFun.send_user_change_password(re_change_password,_loc1_);
      }

      private function re_change_password(param1:Object) : void
      {
         this.saveUserData(param1["params"]);
         GlobalData.$mEventDispatcher.dispatchEventWith("login_status_out",false,{
            "status":mStatus,
            "type":99
         });
         var _loc2_:String = GlobalLanguageStr.getLanguageStr(90074) + GlobalLanguageStr.getLanguageStr(20455);
         GlobalFunction.tipsOS_ios(GlobalLanguageStr.getLanguageStr(90010),_loc2_,"OK",btn_CloseEvent);
      }

      private function re_bind(param1:Object) : void
      {
         GlobalData.$mGameClassObject.closePopForPanel();
         this.saveUserData(param1["params"]);
         GlobalData.$mEventDispatcher.dispatchEventWith("login_status_out",false,{
            "status":mStatus,
            "type":98
         });
         var _loc2_:String = GlobalLanguageStr.getLanguageStr(90074) + GlobalLanguageStr.getLanguageStr(20246);
         _loc2_ += "\n" + GlobalLanguageStr.getLanguageStr(90075,GlobalLocalStore.$pf_token_curr);
         GlobalFunction.tipsOS_ios(GlobalLanguageStr.getLanguageStr(90010),_loc2_,"OK",btn_CloseEvent);
         LayoutUIPop.$touch = mBtn_close.visible = true;
         GlobalLocalStore.setQuickUID("");
         GlobalLocalStore.setQuickPW("");
         GlobalData.$mEventDispatcher.dispatchEventWith("update_hele_comment_gift_fun");
      }

      private function re_llogin(param1:Object) : void
      {
         this.saveUserData(param1["params"]);
         GlobalData.$mEventDispatcher.dispatchEventWith("login_status_out",false,{
            "status":mStatus,
            "type":3
         });
         var _loc2_:String = GlobalLanguageStr.getLanguageStr(90074) + GlobalLanguageStr.getLanguageStr(20221);
         _loc2_ += "\n" + GlobalLanguageStr.getLanguageStr(90075,GlobalLocalStore.$pf_token_curr);
         GlobalFunction.tipsOS_ios(GlobalLanguageStr.getLanguageStr(90010),_loc2_,"OK",btn_CloseEvent);
         if(mBtn_close)
         {
            LayoutUIPop.$touch = mBtn_close.visible = true;
         }
         GlobalLocalStore.setQuickUID("");
         GlobalLocalStore.setQuickPW("");
      }

      private function re_register(param1:Object) : void
      {
         this.saveUserData(param1["params"]);
         GlobalData.$mEventDispatcher.dispatchEventWith("login_status_out",false,{
            "status":mStatus,
            "type":4
         });
         var _loc2_:String = GlobalLanguageStr.getLanguageStr(90074) + GlobalLanguageStr.getLanguageStr(20222);
         _loc2_ += "\n" + GlobalLanguageStr.getLanguageStr(90075,GlobalLocalStore.$pf_token_curr);
         GlobalFunction.tipsOS_ios(GlobalLanguageStr.getLanguageStr(90010),_loc2_,"OK",btn_CloseEvent);
      }

      private function saveUserData(param1:Object) : void
      {
         GlobalLocalStore.$pf_token_curr = param1.session_key;
         GlobalLocalStore.$pf_uid_curr = mStatus == 99 ? param1.new_sessionid : param1.sessionid;
         GlobalLocalStore.setMeng52UID(GlobalLocalStore.$pf_token_curr);
         GlobalLocalStore.setMeng52PW(GlobalLocalStore.$pf_uid_curr);
      }

      private function delNT() : void
      {
         if(this.mNT_id)
         {
            if(this.mNT_id.parent)
            {
               this.mNT_id.parent.removeChild(this.mNT_id);
            }
         }
         this.mNT_id = null;
         if(this.mNT_pass)
         {
            if(this.mNT_pass.parent)
            {
               this.mNT_pass.parent.removeChild(this.mNT_pass);
            }
         }
         this.mNT_pass = null;
      }

      private function getNT_id() : String
      {
         var _loc1_:String = "";
         if(mNT_id)
         {
            _loc1_ = mNT_id.text;
         }
         return _loc1_;
      }

      private function setTxtID(param1:String) : void
      {
         if(mNT_id)
         {
            mNT_id.text = param1;
         }
      }

      private function setTxtPS(param1:String) : void
      {
         if(mNT_pass)
         {
            mNT_pass.text = param1;
         }
      }

      private function setNT_id() : void
      {
         var _loc2_:Boolean = mStatus == 99;
         mTxt_id = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(_loc2_ ? 90178 : 20416),25,1118481,"left",85,35);
         this.mBox.addChild(mTxt_id);
         this.mNT_id = null;
         this.mNT_id = new NativeText(1);
         this.mNT_id.autoCorrect = true;
         this.mNT_id.textAlign = "left";
         this.mNT_id.fontSize = 24 * GlobalData.$mStage$Starling_h;
         if(_loc2_)
         {
            this.mNT_id.restrict = "[a-zA-Z0-9]";
            this.mNT_id.maxChars = 16;
         }
         this.mNT_id.color = 0;
         this.mNT_id.fontFamily = GlobalConfig.FONT_1;
         this.mNT_id.text = _loc2_ ? "" : (!GlobalFunction.check_loginUidIsStatic() || mStatus == 2 ? "" : GlobalLocalStore.getMeng52UID());
         this.mNT_id.width = int(this.mBox.width * this._factor);
         this.mNT_id.height = 46 * 4;
         mTxt_id.x = mBg_txt1.x + 10;
         mTxt_id.y = mBg_txt1.y + 6 + 3;
         var _loc1_:Point = new Point(mTxt_id.x,mTxt_id.y);
         _loc1_ = this.mBox.localToGlobal(_loc1_);
         this.mNT_id.x = (_loc1_.x + mTxt_id.textBounds.width) * this._factor + this._isNotFullScreenX;
         if(MainConfig.$isEnglish == true)
         {
            this.mNT_id.y = int(((GlobalData.$mStageHeight - mImg9_baseBg.height) * 0.5 + 175) * GlobalData.$mStage$Starling_h + Starling.current.viewPort.y) + 42;
         }
         else
         {
            this.mNT_id.y = int(((GlobalData.$mStageHeight - mImg9_baseBg.height) * 0.5 + 175) * GlobalData.$mStage$Starling_h + Starling.current.viewPort.y);
         }
         GlobalData.$mStarling.nativeStage.addChild(this.mNT_id);
      }

      private function getNT_pass() : String
      {
         var _loc1_:String = "";
         if(mNT_pass)
         {
            _loc1_ = mNT_pass.text;
         }
         return _loc1_;
      }

      private function setNT_pass() : void
      {
         var _loc2_:Boolean = mStatus == 99;
         mTxt_pass = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(_loc2_ ? 90179 : 20417),25,1118481,"left",85,35);
         this.mBox.addChild(mTxt_pass);
         this.mNT_pass = null;
         this.mNT_pass = new NativeText(1);
         if(!_loc2_)
         {
            this.mNT_pass.displayAsPassword = mStatus != 1;
         }
         this.mNT_pass.autoCorrect = true;
         this.mNT_pass.textAlign = "left";
         this.mNT_pass.fontSize = 24 * GlobalData.$mStage$Starling_h;
         this.mNT_pass.restrict = "[a-zA-Z0-9]";
         this.mNT_pass.maxChars = 16;
         this.mNT_pass.color = 0;
         this.mNT_pass.fontFamily = GlobalConfig.FONT_1;
         this.mNT_pass.text = _loc2_ ? "" : (!GlobalFunction.check_loginUidIsStatic() || mStatus == 2 ? "" : GlobalLocalStore.getMeng52PW());
         this.mNT_pass.width = int(this.mBox.width * this._factor);
         this.mNT_pass.height = 46 * 4;
         mTxt_pass.x = mBg_txt1.x + 10;
         mTxt_pass.y = mBg_txt1.y + 60 + 5;
         var _loc1_:Point = new Point(this.mTxt_pass.x,this.mTxt_pass.y);
         _loc1_ = this.mBox.localToGlobal(_loc1_);
         if(mStatus == 99)
         {
            if(MainConfig.$isEnglish == true)
            {
               this.mNT_pass.y = int(((GlobalData.$mStageHeight - mImg9_baseBg.height) * 0.5 + 228) * GlobalData.$mStage$Starling_h + Starling.current.viewPort.y) + 42;
            }
            else
            {
               this.mNT_pass.y = int(((GlobalData.$mStageHeight - mImg9_baseBg.height) * 0.5 + 228) * GlobalData.$mStage$Starling_h + Starling.current.viewPort.y);
            }
         }
         else if(MainConfig.$isEnglish == true)
         {
            this.mNT_pass.y = int(((GlobalData.$mStageHeight - mImg9_baseBg.height) * 0.5 + 233) * GlobalData.$mStage$Starling_h + Starling.current.viewPort.y) + 42;
         }
         else
         {
            this.mNT_pass.y = int(((GlobalData.$mStageHeight - mImg9_baseBg.height) * 0.5 + 233) * GlobalData.$mStage$Starling_h + Starling.current.viewPort.y);
         }
         this.mNT_pass.x = (_loc1_.x + mTxt_pass.textBounds.width) * this._factor + this._isNotFullScreenX;
         GlobalData.$mStarling.nativeStage.addChild(this.mNT_pass);
      }

      private function setAsPassword(param1:Boolean) : void
      {
         if(mNT_pass)
         {
            mNT_pass.displayAsPassword = param1;
         }
      }
   }
}
