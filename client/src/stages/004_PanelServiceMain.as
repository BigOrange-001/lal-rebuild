package com.meng52.game.ui.screen
{
   import com.adobe.text.NativeText;
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalLocalStore;
   import com.meng52.game.global.GlobalPFANE;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.panel.PanelNoticeHg;
   import com.meng52.game.ui.stage.GuideTools;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.global.ConfigManager;
   import com.meng52.global.GlobalStaticConst;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.TextInput;
   import flash.events.TimerEvent;
   import flash.net.URLRequest;
   import flash.net.navigateToURL;
   import flash.utils.Timer;
   import starling.animation.Juggler;
   import starling.display.Image;
   import starling.display.MovieClip;
   import starling.events.Event;
   import starling.extensions.ParticleSystem;
   import starling.text.TextField;
   
   public class PanelServiceMain extends PanelBase
   {
      
      private static var $adStatus:Boolean = false;
      
      public static const BTN_NAME_SERVICE:String = "btn_name_service";
      
      public static const BTN_NAME_ENTERGAME:String = "btn_name_enterGame";
      
      public static const BTN_NAME_NEXT:String = "btn_name_next";
      
      public static const BTN_NAME_PREV:String = "btn_name_prev";
      
      public static const BTN_NAME_IDPAD_GOTORAIDERS:String = "idpad_gotoRaiders";
      
      public static const BTN_NAME_IOS1006_GOTORAIDERS:String = "ios1006_gotoraiders";
      
      public static const BTN_NAME_IOS1006_GOTOBBS:String = "ios1006_gotoBbs";
      
      private var mPanelServiceChange:PanelServiceChange;
      
      private var mBtn_enterGame:LOL_Button;
      
      private var mBtn_service:LOL_Button;
      
      private var mTxt_input:TextInput;
      
      private var nt:NativeText;
      
      private var mBtn_next:LOL_Button;
      
      private var mBtn_prev:LOL_Button;
      
      private var mImg_server:Image;
      
      private var mImg_name:Image;
      
      private var mTxt_name:TextField;
      
      private var mArr:Array;
      
      private var mRecommend:int;
      
      private var mCurrServerCfg:Object;
      
      private var mLogo:Image;
      
      private var mInputBg:Image;
      
      public var mPanelLogin:PanelLogin;
      
      private var mBtn_login:LOL_Button;
      
      private var mBtn_help:LOL_Button;
      
      private var mMC_enterGame_txt:Image;
      
      private var mMC_enterGame:Image;
      
      private var mMC_bgClip:Image;
      
      private var mMC_lightClip:Image;
      
      private var mMC_lightClip2:Image;
      
      private var mMC_logoClip:Image;
      
      private var mMC_serviceIcon:MovieClip;
      
      private var mMC_times:Number = 0;
      
      private var mMC_times_end:Number = 0;
      
      private var mParticleSystem:ParticleSystem;
      
      private var mB_light:Boolean = false;
      
      private var mImg_bgBtn:Image;
      
      private var mTxt_version:TextField;
      
      private var mBg_right:Image;
      
      private var mBg_left:Image;
      
      private var mBg_line:Image;
      
      private var mBtn_raiders:LOL_Button;
      
      private var mBtn_bbs:LOL_Button;
      
      public function PanelServiceMain()
      {
         super();
      }
      
      override public function clear() : void
      {
         GlobalData.$mStarling.juggler.purge();
         GlobalData.$mEventDispatcher.removeEventListener("update_service_change",onUPDATE_SERVICE_CHANGE);
         if(mBg_right)
         {
            mBg_right.removeFromParent(true);
         }
         if(mBg_left)
         {
            mBg_left.removeFromParent(true);
         }
         if(mBg_line)
         {
            mBg_line.removeFromParent(true);
         }
         if(mPanelServiceChange)
         {
            StarlingTools.removeChildrenClear(mPanelServiceChange);
            mPanelServiceChange.removeFromParent(true);
         }
         StarlingTools.removeChildrenClear(this);
         if(mTxt_version)
         {
            mTxt_version.removeFromParent(true);
         }
         if(mImg_bgBtn)
         {
            mImg_bgBtn.removeFromParent(true);
         }
         if(mTxt_name)
         {
            mTxt_name.dispose();
         }
         if(mLogo)
         {
            mLogo.removeFromParent(true);
         }
         if(this.mPanelLogin)
         {
            this.mPanelLogin.dispose();
         }
         if(this.mBtn_login)
         {
            mBtn_login.removeFromParent(true);
         }
         if(this.mBtn_help)
         {
            mBtn_help.removeFromParent(true);
         }
         if(mMC_enterGame)
         {
            mMC_enterGame.dispose();
         }
         if(mMC_enterGame_txt)
         {
            mMC_enterGame_txt.dispose();
         }
         if(mMC_serviceIcon)
         {
            mMC_serviceIcon.dispose();
         }
         if(mMC_bgClip)
         {
            mMC_bgClip.dispose();
         }
         if(mMC_lightClip)
         {
            mMC_lightClip.dispose();
         }
         if(mMC_lightClip2)
         {
            mMC_lightClip2.dispose();
         }
         this.mPanelServiceChange = null;
         this.mMC_lightClip2 = null;
         this.mMC_lightClip = null;
         this.mMC_bgClip = null;
         this.mMC_serviceIcon = null;
         this.mBtn_login = null;
         this.mMC_enterGame_txt = null;
         this.mMC_enterGame = null;
         this.mPanelLogin = null;
         this.mTxt_name = null;
         this.mBtn_enterGame = null;
         this.mBtn_service = null;
         this.mTxt_input = null;
         this.mImg_server = null;
         this.mBtn_next = null;
         this.mBtn_prev = null;
         this.mBtn_help = null;
         this.mArr = null;
         this.mTxt_version = null;
         this.mLogo = null;
         mBg_right = null;
         mBg_left = null;
         mBg_line = null;
         if(this.mInputBg)
         {
            this.mInputBg.dispose();
         }
         this.mInputBg = null;
         if(this.nt)
         {
            if(this.nt.parent)
            {
               this.nt.parent.removeChild(this.nt);
            }
         }
         this.nt = null;
         super.clear();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         var _j:Juggler;
         var _isHadLocalData:String;
         var _zonesObj:Object;
         var _date:Date;
         var _nowS:Number;
         var _zoneID:String;
         var _rulerS:Number;
         var _every:Array;
         var service:*;
         var event:Event = param1;
         this.removeEventListener("addedToStage",initializeHandler);
         this.mMC_times = 0;
         GlobalData.$mEventDispatcher.addEventListener("update_service_change",onUPDATE_SERVICE_CHANGE);
         mImg_bgBtn = GlobalFunction.createImage("UI_selectService_btn_jryx_bg_0000");
         mImg_bgBtn.touchable = false;
         mImg_bgBtn.alpha = 0.75;
         mImg_bgBtn.pivotX = mImg_bgBtn.width / 2;
         mImg_bgBtn.pivotY = mImg_bgBtn.height / 2;
         mImg_bgBtn.x = int(GlobalData.$mStageWidth * 0.5);
         mImg_bgBtn.y = int(GlobalData.$mStageHeight - mImg_bgBtn.height / 2 - 10);
         addChild(mImg_bgBtn);
         mBtn_enterGame = GlobalFunction.createButtonStarling("UI_selectService_btn_jryx_0000");
         mBtn_enterGame.pivotX = mBtn_enterGame.width / 2;
         mBtn_enterGame.pivotY = mBtn_enterGame.height / 2;
         this.mBtn_enterGame.name = "btn_name_enterGame";
         this.addChild(this.mBtn_enterGame);
         this.mBtn_enterGame.x = int(GlobalData.$mStageWidth * 0.5);
         this.mBtn_enterGame.addEventListener("triggered",this.onTRIGGERED);
         this.mBtn_service = GlobalFunction.createButtonStarling("UI_selectService_btn_jryx_0001",{
            "t":GlobalLanguageStr.getLanguageStr(20418),
            "fs":20,
            "fc":1118481
         });
         mBtn_service.pivotX = mBtn_service.width / 2;
         mBtn_service.pivotY = mBtn_service.height / 2;
         this.mBtn_service.name = "btn_name_service";
         this.addChild(this.mBtn_service);
         this.mBtn_service.x = this.mBtn_enterGame.x;
         this.mBtn_service.addEventListener("triggered",this.onTRIGGERED);
         this.mBtn_enterGame.y = mImg_bgBtn.y - 32;
         this.mBtn_service.y = mImg_bgBtn.y + 38;
         _j = GlobalData.$mStarling.juggler;
         LayoutUIAnimation.heartbeat(mBtn_enterGame,1,1.06,0.5,0.4,_j);
         mLogo = GlobalFunction.createImage("ui_logo");
         mLogo.x = int((GlobalData.$mStageWidth - mLogo.width) * 0.5);
         mLogo.y = ConfigManager.getInstance().getUIPos("logo")[ConfigManager.POSY];
         addChild(mLogo);
         mBg_line = GlobalFunction.createImage("UI_main_bg_modified_bar_0000");
         mBg_line.y = GlobalData.$mStageHeight - mBg_line.height;
         mBg_line.width = GlobalData.$mStageWidth;
         addChild(mBg_line);
         mBg_right = GlobalFunction.createImage("UI_main_bg_modified_0000");
         mBg_left = GlobalFunction.createImage("UI_main_bg_modified_0000");
         mBg_left.scaleX = -1;
         addChild(mBg_left);
         addChild(mBg_right);
         mBg_right.x = GlobalData.$mStageWidth - mBg_right.width;
         mBg_left.x = mBg_left.width;
         mBg_right.y = GlobalData.$mStageHeight - mBg_right.height;
         mBg_left.y = mBg_right.y;
         mTxt_version = GlobalTextStyle.getTextField("v" + MainConfig.VERSION_CURR,20,16777215,"right",GlobalData.$mStageWidth * 0.5,29);
         mTxt_version.x = GlobalData.$mStageWidth * 0.5 - 30;
         mTxt_version.y = GlobalData.$mStageHeight - 29;
         addChild(mTxt_version);
         _isHadLocalData = "";
         if(GlobalFunction.check_pf_useMeng52Service())
         {
            service = function():void
            {
               GlobalData.$mServiceID = "";
               for(var _loc2_:Object in _zonesObj)
               {
                  _every = _zonesObj[_loc2_];
                  _date = _every[1] as Date;
                  _rulerS = _date.time * 0.001;
                  if(_rulerS < _nowS)
                  {
                     _zoneID = _loc2_.toString();
                     if(int(_every[2]) <= 0)
                     {
                        GlobalData.$mServiceID = _zoneID;
                        break;
                     }
                  }
               }
               if(GlobalData.$mServiceID == "")
               {
                  for(var _loc1_:Object in _zonesObj)
                  {
                     _every = _zonesObj[_loc1_];
                     _date = _every[1] as Date;
                     _rulerS = _date.time * 0.001;
                     if(_rulerS < _nowS)
                     {
                        _zoneID = _loc1_.toString();
                        GlobalData.$mServiceID = _zoneID;
                        break;
                     }
                  }
               }
            };
            _zonesObj = GlobalData.$mConfig_zones;
            _nowS = SendAndSelect.$systemTimer_nowSecond;
            _zoneID = "";
            _rulerS = 0;
            _every = null;
            _isHadLocalData = GlobalLocalStore.getServiceId();
            GlobalData.$mServiceID = _isHadLocalData;
            GlobalData.$mServiceID_obj = GlobalLocalStore.getServiceIdObj();
            if(Tools.strIsNull(GlobalData.$mServiceID))
            {
               service();
            }
            else
            {
               _every = _zonesObj[GlobalData.$mServiceID];
               if(_every)
               {
                  _date = _every[1] as Date;
                  _rulerS = _date.time * 0.001;
                  if(_rulerS >= _nowS)
                  {
                     service();
                  }
               }
               else
               {
                  service();
               }
            }
         }
         this.changeService();
         if(GlobalLocalStore.$pf_type_curr == "hgkt" || GlobalLocalStore.$pf_type_curr == "hgtstore" || GlobalLocalStore.$pf_type_curr == "hgnaver" || GlobalLocalStore.$pf_type_curr == "hggoogle" || GlobalLocalStore.$pf_type_curr == "local" || GlobalLocalStore.$pf_type_curr == "rkios" || GlobalLocalStore.$pf_type_curr == "ios1006")
         {
            setAgreement(_isHadLocalData,true,initNotice);
         }
         else
         {
            this.initNotice();
         }
      }
      
      private function setAgreement(param1:String, param2:Boolean, param3:Function) : void
      {
         if(param1 == null || param1 == "")
         {
            GlobalData.$mGameClassObject.openPopUp(new PanelNoticeHg(MainConfig.SERVER_ADDRESS_HELP_HG,GlobalLanguageStr.getLanguageStr(95015),param2,param3));
         }
         else
         {
            this.initNotice();
         }
      }
      
      private function initNotice() : void
      {
         var _title:String;
         var _haveBBS:Boolean;
         var _haveRaiders:Boolean;
         var _url:String;
         var _pfURL:Object;
         var _helpURL:Object;
         var _helpURLstr:String;
         var _quick_uid:String;
         var _quick_pw:String;
         var _uid:String;
         var _pw:String;
         var getServiceUID:*;
         var onTRIGGERED_login:*;
         var onTRIGGERED_help:*;
         var gotoRaiders:*;
         var gotoBbs:*;
         var re_default_register:*;
         var onSetLogin:*;
         var onLOGIN_STATUS_OUT:*;
         MainConfig.isHw_Logout = false;
         if(GlobalFunction.check_useMeng52ID())
         {
            getServiceUID = function():void
            {
               SendServiceAMFFun.send_user_default_register(re_default_register,{"pf":GlobalLocalStore.$pf_type_curr});
            };
            onTRIGGERED_login = function(param1:Event):void
            {
               onSetLogin(4);
            };
            onTRIGGERED_help = function(param1:Event):void
            {
               var _loc2_:String = (param1.currentTarget as LOL_Button).name;
               switch(_loc2_)
               {
                  case "idpad_gotoRaiders":
                     gotoRaiders();
                     break;
                  case "ios1006_gotoraiders":
                     gotoRaiders();
                     break;
                  case "ios1006_gotoBbs":
                     gotoBbs();
               }
            };
            gotoRaiders = function():void
            {
               var _loc1_:String = null;
               var _loc2_:Object = GlobalData.$mConfig_client.help_url;
               if(_loc2_)
               {
                  try
                  {
                     _loc1_ = _loc2_[GlobalLocalStore.$pf_type_curr];
                     navigateToURL(new URLRequest(_loc1_),"_blank");
                  }
                  catch(_error:Error)
                  {
                  }
               }
            };
            gotoBbs = function():void
            {
               var _pfURL:Object;
               var toURL:* = function():void
               {
                  try
                  {
                     navigateToURL(new URLRequest(_url),"_blank");
                  }
                  catch(_error:Error)
                  {
                  }
               };
               var _url:String = GlobalData.$mConfig_client.bbs_url;
               if(GlobalData.$mConfig_client["pf_bbs_url"])
               {
                  _pfURL = GlobalData.$mConfig_client.pf_bbs_url;
                  if(_pfURL[GlobalLocalStore.$pf_type_curr])
                  {
                     _url = _pfURL[GlobalLocalStore.$pf_type_curr];
                  }
               }
               if(_url == "")
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90046));
               }
               else
               {
                  GlobalPFANE.extPF_bbs(0,toURL);
               }
            };
            re_default_register = function(param1:Object):void
            {
               GlobalLocalStore.$pf_token_curr = param1.data.session_key;
               GlobalLocalStore.$pf_uid_curr = param1.data.sessionid;
               GlobalLocalStore.setMeng52UID(GlobalLocalStore.$pf_token_curr);
               GlobalLocalStore.setMeng52PW(GlobalLocalStore.$pf_uid_curr);
               GlobalFunction.popPanelHelp();
            };
            onSetLogin = function(param1:int = 0):void
            {
               if(mPanelLogin)
               {
                  GlobalData.$mGameClassObject.closePopForPanel();
               }
               mPanelLogin = null;
               mPanelLogin = new PanelLogin(param1);
               mPanelLogin.mPop_currID = GlobalData.$mGameClassObject.openPopForPanel(mPanelLogin);
               GlobalData.$mEventDispatcher.addEventListener("login_status_out",onLOGIN_STATUS_OUT);
            };
            onLOGIN_STATUS_OUT = function(param1:Event):void
            {
               var _loc2_:Object = param1.data;
               GlobalData.$mEventDispatcher.removeEventListener("login_status_out",onLOGIN_STATUS_OUT);
               GlobalData.$mGameClassObject.closePopForPanel();
            };
            _title = GlobalLanguageStr.getLanguageStr(20456);
            mBtn_login = GlobalFunction.createButtonStarling("UI_regist_btn_0_0001",{
               "t":_title,
               "fs":(MainConfig.$isEnglish ? 20 : 25),
               "fc":16777215
            });
            mBtn_login.shadowFilter();
            mBtn_login.x = GlobalData.$mStageWidth - mBtn_login.width - 5;
            mBtn_login.y = 15;
            mBtn_login.addEventListener("triggered",onTRIGGERED_login);
            addChild(mBtn_login);
            if(GlobalLocalStore.$pf_type_curr == "idpad")
            {
               mBtn_help = GlobalFunction.createButtonStarling("UI_regist_btn_0_0000",{
                  "t":GlobalLanguageStr.getLanguageStr(95006),
                  "fs":25,
                  "fc":16777215
               });
               mBtn_help.shadowFilter();
               mBtn_help.name = "idpad_gotoRaiders";
               mBtn_help.x = mBtn_login.x - mBtn_help.width;
               mBtn_help.y = mBtn_login.y;
               mBtn_help.addEventListener("triggered",onTRIGGERED_help);
               addChild(mBtn_help);
            }
            if(GlobalLocalStore.$pf_type_curr == "ios1006")
            {
               _haveBBS = false;
               _haveRaiders = false;
               _url = GlobalData.$mConfig_client.bbs_url;
               if(GlobalData.$mConfig_client["pf_bbs_url"])
               {
                  _pfURL = GlobalData.$mConfig_client.pf_bbs_url;
                  if(_pfURL[GlobalLocalStore.$pf_type_curr])
                  {
                     _url = _pfURL[GlobalLocalStore.$pf_type_curr];
                     _haveBBS = true;
                  }
               }
               _helpURL = GlobalData.$mConfig_client.help_url;
               if(_helpURL)
               {
                  if(_helpURL[GlobalLocalStore.$pf_type_curr])
                  {
                     _helpURLstr = _helpURL[GlobalLocalStore.$pf_type_curr];
                     _haveRaiders = true;
                  }
               }
               if(_haveRaiders)
               {
                  mBtn_raiders = GlobalFunction.createButtonStarling("UI_regist_btn_0_0000",{
                     "t":GlobalLanguageStr.getLanguageStr(20509),
                     "fs":25,
                     "fc":16777215
                  });
                  mBtn_raiders.shadowFilter();
                  mBtn_raiders.name = "ios1006_gotoraiders";
                  mBtn_raiders.x = GlobalData.$mStageWidth * 0.5 - mBtn_raiders.width * 2 - 25;
                  mBtn_raiders.y = 15;
                  mBtn_raiders.addEventListener("triggered",onTRIGGERED_help);
                  addChild(mBtn_raiders);
               }
               if(_haveBBS)
               {
                  mBtn_bbs = GlobalFunction.createButtonStarling("UI_regist_btn_0_0000",{
                     "t":GlobalLanguageStr.getLanguageStr(20204),
                     "fs":25,
                     "fc":16777215
                  });
                  mBtn_bbs.shadowFilter();
                  mBtn_bbs.name = "ios1006_gotoBbs";
                  mBtn_bbs.x = mBtn_raiders.x + mBtn_raiders.width;
                  mBtn_bbs.y = mBtn_raiders.y;
                  mBtn_bbs.addEventListener("triggered",onTRIGGERED_help);
                  addChild(mBtn_bbs);
               }
            }
            _quick_uid = GlobalLocalStore.getQuickUID();
            _quick_pw = GlobalLocalStore.getQuickPW();
            _uid = GlobalLocalStore.getMeng52UID();
            _pw = GlobalLocalStore.getMeng52PW();
            if(_quick_uid == "" || _quick_pw == "")
            {
               if(_uid == "" || _pw == "")
               {
                  onSetLogin(3);
               }
               else
               {
                  GlobalLocalStore.$pf_token_curr = _uid;
                  GlobalLocalStore.$pf_uid_curr = _pw;
                  if(!GlobalData.$userData)
                  {
                     GlobalFunction.popPanelHelp();
                  }
               }
            }
            else
            {
               GlobalLocalStore.$pf_token_curr = _quick_uid;
               GlobalLocalStore.$pf_uid_curr = _quick_pw;
               if(!GlobalData.$userData)
               {
                  GlobalFunction.popPanelHelp();
               }
            }
            if(GlobalLocalStore.$pf_type_curr == "local" || GlobalLocalStore.$pf_type_curr == "rkios" || GlobalLocalStore.$pf_type_curr == "ios1006")
            {
               mBtn_login = GlobalFunction.createButtonStarling("UI_regist_btn_0_0001",{
                  "t":GlobalLanguageStr.getLanguageStr(95015),
                  "fs":(MainConfig.$isEnglish ? 20 : 25),
                  "fc":16777215
               });
               mBtn_login.shadowFilter();
               mBtn_login.x = GlobalData.$mStageWidth - mBtn_login.width - 5;
               if(GlobalFunction.check_useMeng52ID())
               {
                  mBtn_login.x -= mBtn_login.width - 5;
               }
               mBtn_login.y = 15;
               mBtn_login.addEventListener("triggered",onTRIGGERED_hgAgree);
               addChild(mBtn_login);
            }
         }
         else
         {
            if(GlobalLocalStore.$pf_type_curr == "hgkt" || GlobalLocalStore.$pf_type_curr == "hgtstore" || GlobalLocalStore.$pf_type_curr == "hgnaver" || GlobalLocalStore.$pf_type_curr == "hggoogle" || GlobalLocalStore.$pf_type_curr == "local" || GlobalLocalStore.$pf_type_curr == "rkios" || GlobalLocalStore.$pf_type_curr == "ios1006")
            {
               mBtn_login = GlobalFunction.createButtonStarling("UI_regist_btn_0_0001",{
                  "t":GlobalLanguageStr.getLanguageStr(95015),
                  "fs":25,
                  "fc":16777215
               });
               mBtn_login.shadowFilter();
               mBtn_login.x = GlobalData.$mStageWidth - mBtn_login.width - 5;
               if(GlobalFunction.check_useMeng52ID())
               {
                  mBtn_login.x -= mBtn_login.width - 5;
               }
               mBtn_login.y = 15;
               mBtn_login.addEventListener("triggered",onTRIGGERED_hgAgree);
               addChild(mBtn_login);
            }
            if(GlobalLocalStore.$pf_type_curr == "qihoo" || GlobalLocalStore.$pf_type_curr == "dtqh" || GlobalLocalStore.$pf_type_curr == "rkxm" || GlobalLocalStore.$pf_type_curr == "tlios")
            {
               GlobalFunction.popPanelHelp();
            }
            else if(GlobalData.$pf_init)
            {
               if(GlobalLocalStore.$pf_type_curr != "rkpp" && GlobalLocalStore.$pf_type_curr != "rkit" && GlobalLocalStore.$pf_type_curr != "rki4" && GlobalLocalStore.$pf_type_curr != "rkky" && GlobalLocalStore.$pf_type_curr != "gatios" && GlobalLocalStore.$pf_type_curr != "gatad" && GlobalLocalStore.$pf_type_curr != "hgkt" && GlobalLocalStore.$pf_type_curr != "hgtstore" && GlobalLocalStore.$pf_type_curr != "hgnaver" && GlobalLocalStore.$pf_type_curr != "hggoogle" && GlobalLocalStore.$pf_type_curr != "dnyios" && GlobalLocalStore.$pf_type_curr != "dnyad" && GlobalLocalStore.$pf_type_curr != "dtbd" && GlobalLocalStore.$pf_type_curr != "rkjf" && GlobalLocalStore.$pf_type_curr != "ChinaMove" && GlobalLocalStore.$pf_type_curr != "rkhw")
               {
                  GlobalPFANE.extPF_login();
               }
            }
            else
            {
               GlobalData.$pf_init = true;
               if(GlobalLocalStore.$pf_type_curr == "gatios" || GlobalLocalStore.$pf_type_curr == "gatad" || GlobalLocalStore.$pf_type_curr == "hgkt" || GlobalLocalStore.$pf_type_curr == "hgtstore" || GlobalLocalStore.$pf_type_curr == "hgnaver" || GlobalLocalStore.$pf_type_curr == "hggoogle" || GlobalLocalStore.$pf_type_curr == "dnyios" || GlobalLocalStore.$pf_type_curr == "dnyad" || GlobalLocalStore.$pf_type_curr == "rkjf" || GlobalLocalStore.$pf_type_curr == "ChinaMove" || GlobalLocalStore.$pf_type_curr == "rk91" || GlobalLocalStore.$pf_type_curr == "rkdk")
               {
                  GlobalPFANE.extPF_login(GlobalFunction.popPanelHelp);
               }
               else
               {
                  GlobalPFANE.extPF_init(GlobalFunction.popPanelHelp);
               }
            }
         }
      }
      
      private function onTRIGGERED_hgAgree(param1:Event) : void
      {
         setAgreement("",false,null);
      }
      
      private function onTRIGGERED(param1:Event) : void
      {
         var _loc3_:LOL_Button = param1.currentTarget as LOL_Button;
         var _loc2_:String = _loc3_.name;
         if(_loc2_ == "btn_name_enterGame")
         {
            if(!Tools.strIsNull(GlobalData.$mServiceID))
            {
               if(GlobalLocalStore.$pf_token_curr == "" && (GlobalLocalStore.$pf_type_curr == "rkpp" || GlobalLocalStore.$pf_type_curr == "rk91ios" || GlobalLocalStore.$pf_type_curr == "rk37w" || GlobalLocalStore.$pf_type_curr == "rk37wmz" || GlobalLocalStore.$pf_type_curr == "dtbd"))
               {
                  GlobalPFANE.extPF_login(GlobalFunction.popPanelHelp);
                  return;
               }
               sendLoginService();
            }
         }
         else if(_loc2_ == "btn_name_service")
         {
            if(GlobalFunction.check_pf_useMeng52Service())
            {
               if(mPanelServiceChange)
               {
                  mPanelServiceChange.removeFromParent(true);
                  mPanelServiceChange = null;
               }
               mPanelServiceChange = new PanelServiceChange();
               mPanelServiceChange.mPop_currID = GlobalData.$mGameClassObject.openPopForPanel(mPanelServiceChange);
            }
            else
            {
               GlobalPFANE.changeService();
            }
         }
         else if(_loc2_ != "btn_name_next")
         {
            if(_loc2_ == "btn_name_prev")
            {
            }
         }
      }
      
      public function sendLoginService() : void
      {
         var _loc1_:Object = null;
         var _loc3_:Boolean = false;
         var _loc2_:String = "";
         _loc3_ = true;
         if(_loc3_)
         {
            _loc1_ = GlobalLocalStore.getSendObj(_loc2_ != "" ? _loc2_ : SendAndSelect.$MACID);
            _loc1_["zone"] = GlobalData.$mServiceID;
            _loc1_["holdLoading"] = true;
            _loc1_["nowLoading"] = true;
            if(GlobalStaticConst.$isAndroid)
            {
               if(GlobalLocalStore.$pf_type_curr == "qihoo")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "qihoo";
                  _loc1_.sessionid = "";
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "dtqh")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "dtqh";
                  _loc1_.sessionid = "";
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "idpad")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "idpad";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "jinsad")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "jinsad";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "banshu")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "banshu";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "dtczk")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "dtczk";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "1006ad")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "1006ad";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "sgno1")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "sgno1";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "rkafw")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "rkafw";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "rkdx")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "rkdx";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "sytx")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "sytx";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "rk91")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "rk91";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "rkuc")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "rkuc";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "dtdl")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "dtdl";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "dtwdj")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "dtwdj";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
                  if(_loc1_.session_key == "" || _loc1_.sessionid == "")
                  {
                     MainConfig.classMainExtension.getInstance().login();
                     return;
                  }
               }
               else if(GlobalLocalStore.$pf_type_curr == "dtxm")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "dtxm";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "dtbd")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "dtbd";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "dtuc")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = "";
                  _loc1_.pf = "dtuc";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "dtoppo")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "dtoppo";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "ChinaMove")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "ChinaMove";
                  _loc1_.sessionid = "";
                  _loc1_.mac = SendAndSelect.$MACID;
                  if(_loc1_.session_key == "")
                  {
                     MainConfig.classMainExtension.getInstance().setLogin();
                     return;
                  }
               }
               else if(GlobalLocalStore.$pf_type_curr == "dthw")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "dthw";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.getPF_dtaib(GlobalLocalStore.$pf_type_curr))
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = GlobalLocalStore.$pf_type_curr;
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "dtfl")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "dtfl";
                  _loc1_.sessionid = "";
                  _loc1_.timestamp = GlobalLocalStore.$pf_timestamp;
                  _loc1_.sign = GlobalLocalStore.$pf_sign;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "dtlenovo")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = "";
                  _loc1_.pf = "dtlenovo";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "rkdk")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "rkdk";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "rkwdj")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "rkwdj";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
                  if(_loc1_.session_key == "" || _loc1_.sessionid == "")
                  {
                     MainConfig.classMainExtension.getInstance().rkLogin();
                     return;
                  }
               }
               else if(GlobalLocalStore.$pf_type_curr == "rkxm")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "rkxm";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "rkaz")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "rkaz";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "dtaz")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "dtaz";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "rk37w")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "rk37w";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "rk37wmz")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "rk37wmz";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "rkbd")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.pf = "rkbd";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "dnyad")
               {
                  _loc1_.pf = "dnyad";
                  _loc1_.sessionid = "";
                  _loc1_.timestamp = GlobalLocalStore.$pf_timestamp;
                  _loc1_.sign = GlobalLocalStore.$pf_sign;
                  _loc1_.userid = GlobalLocalStore.$pf_userid;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "rkjsad")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "rkjsad";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "rkad")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "rkad";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "gatad")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = "";
                  _loc1_.pf = "gatad";
                  _loc1_.sessionid = "";
                  _loc1_["sign"] = GlobalLocalStore.$pf_sign;
                  _loc1_["userid"] = GlobalLocalStore.$pf_userid;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "rkndw")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "rkndw";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "rkppw")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "rkppw";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
                  _loc1_.time = GlobalConfig.ppw_timer;
                  if(_loc1_.session_key == "" || _loc1_.sessionid == "")
                  {
                     MainConfig.classMainExtension.getInstance().rkLogin();
                     return;
                  }
               }
               else if(GlobalLocalStore.$pf_type_curr == "rkhw")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "rkhw";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "7k7k")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "7k7k";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
                  if(_loc1_.session_key == "" || _loc1_.sessionid == "")
                  {
                     MainConfig.classMainExtension.getInstance().rkLogin();
                     return;
                  }
               }
               else if(GlobalLocalStore.$pf_type_curr == "anfeng")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "anfeng";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
                  if(_loc1_.session_key == "" || _loc1_.sessionid == "")
                  {
                     MainConfig.classMainExtension.getInstance().rkLogin();
                     return;
                  }
               }
               else if(GlobalLocalStore.$pf_type_curr == "bfyy")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "bfyy";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
                  if(_loc1_.session_key == "" || _loc1_.sessionid == "")
                  {
                     MainConfig.classMainExtension.getInstance().rkLogin();
                     return;
                  }
               }
               else if(GlobalLocalStore.$pf_type_curr == "kugou")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "kugou";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
                  if(_loc1_.session_key == "" || _loc1_.sessionid == "")
                  {
                     MainConfig.classMainExtension.getInstance().rkLogin();
                     return;
                  }
               }
               else if(GlobalLocalStore.$pf_type_curr == "gameBaby")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "gameBaby";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
                  if(_loc1_.session_key == "" || _loc1_.sessionid == "")
                  {
                     MainConfig.classMainExtension.getInstance().rkLogin();
                     return;
                  }
               }
               else if(GlobalLocalStore.$pf_type_curr == "sougou1")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "sougou1";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
                  if(_loc1_.session_key == "" || _loc1_.sessionid == "")
                  {
                     MainConfig.classMainExtension.getInstance().rkLogin();
                     return;
                  }
               }
               else if(GlobalLocalStore.$pf_type_curr == "sougou2")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "sougou2";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
                  if(_loc1_.session_key == "" || _loc1_.sessionid == "")
                  {
                     MainConfig.classMainExtension.getInstance().rkLogin();
                     return;
                  }
               }
               else if(GlobalLocalStore.$pf_type_curr == "sougou3")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "sougou3";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
                  if(_loc1_.session_key == "" || _loc1_.sessionid == "")
                  {
                     MainConfig.classMainExtension.getInstance().rkLogin();
                     return;
                  }
               }
               else if(GlobalLocalStore.$pf_type_curr == "rkjf")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "rkjf";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "hgkt")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "hgkt";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "hgtstore")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "hgtstore";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "hgnaver")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "hgnaver";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "hggoogle")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "hggoogle";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
            }
            else if(GlobalStaticConst.$isIOS)
            {
               if(GlobalLocalStore.$pf_type_curr == "idpios")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "idpios";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "dnyios")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = "";
                  _loc1_.pf = "dnyios";
                  _loc1_.sessionid = "";
                  _loc1_.timestamp = GlobalLocalStore.$pf_timestamp;
                  _loc1_.sign = GlobalLocalStore.$pf_sign;
                  _loc1_.userid = GlobalLocalStore.$pf_userid;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "idpun")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "idpun";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "rk91ios")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "rk91ios";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "rkky")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "rkky";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "rkios")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "rkios";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "rkjs")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "rkjs";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "rkpp")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "rkpp";
                  _loc1_.sessionid = "";
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "rkit")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "rkit";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "rki4")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "rki4";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "rkjsun")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "rkjsun";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "rkun")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "rkun";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "tlios")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = "";
                  _loc1_.pf = "tlios";
                  _loc1_.sessionid = "";
                  _loc1_["sign"] = GlobalLocalStore.$pf_sign;
                  _loc1_["userid"] = GlobalLocalStore.$pf_userid;
                  _loc1_["timestamp"] = GlobalLocalStore.$pf_timestamp;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "gatios")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = "";
                  _loc1_.pf = "gatios";
                  _loc1_.sessionid = "";
                  _loc1_["sign"] = GlobalLocalStore.$pf_sign;
                  _loc1_["userid"] = GlobalLocalStore.$pf_userid;
                  _loc1_.mac = SendAndSelect.$MACID;
               }
               else if(GlobalLocalStore.$pf_type_curr == "ios1006")
               {
                  _loc1_.local_session_key = "";
                  _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
                  _loc1_.pf = "ios1006";
                  _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
                  _loc1_.mac = SendAndSelect.$MACID;
                  _loc1_.ifa = SendAndSelect.$IDFA;
               }
               GlobalPFANE.sendIOSlocalNotification(86400,GlobalLanguageStr.getLanguageStr(97001));
            }
            if(GlobalLocalStore.$pf_type_curr == "local")
            {
               _loc1_.local_session_key = "";
               _loc1_.session_key = GlobalLocalStore.$pf_token_curr;
               _loc1_.pf = GlobalLocalStore.$pf_type_curr;
               _loc1_.sessionid = GlobalLocalStore.$pf_uid_curr;
               _loc1_.mac = "";
               GlobalPFANE.sendIOSlocalNotification(86400,GlobalLanguageStr.getLanguageStr(97001));
            }
            if(_loc1_ && GlobalFunction.check_isApplePay())
            {
               _loc1_["ios_token"] = GlobalData.$notificationsIOS_token;
            }
            GlobalLocalStore.$login_SendData = _loc1_;
            SendServiceAMFFun.send_user_login(re_user_login,_loc1_);
         }
      }
      
      private function onUPDATE_SERVICE_CHANGE(param1:Event) : void
      {
         if(mPanelServiceChange)
         {
            mPanelServiceChange.removeFromParent(true);
            mPanelServiceChange = null;
         }
         changeService();
      }
      
      private function changeService() : void
      {
         var _loc3_:Boolean = GlobalFunction.check_pf_useMeng52Service();
         if(!_loc3_)
         {
            GlobalPFANE.$serviceUpdateFun = changeService;
            GlobalData.$mServiceID = GlobalFunction.get_pf_selfServierID(GlobalLocalStore.$pf_serverid);
         }
         if(GlobalData.$mServiceID == "" || GlobalData.$mServiceID == null)
         {
            GlobalData.$mServiceID = "1-01";
         }
         var _loc1_:Array = GlobalData.$mConfig_zones[GlobalData.$mServiceID] as Array;
         var _loc2_:String = GlobalLanguageStr.getLanguageStr(20160,_loc1_[0]);
         if(mBtn_service)
         {
            mBtn_service.text = _loc2_;
         }
      }
      
      private function re_user_login(param1:Object) : void
      {
         var _loc4_:Object = null;
         var _loc6_:int = 0;
         if(param1.params && param1.data != undefined && param1.data != null)
         {
            MainConfig.isHw_Logout = true;
            GlobalData.$userData = param1.data;
             GlobalData.seedProfileSync(param1.state_sync);
            GlobalData.$userData.attrs.pvp_rank = GlobalData.$userData.attrs.pvp_rank == null ? 99999 : GlobalData.$userData.attrs.pvp_rank;
            GlobalData.$userData.records.current_rank = GlobalData.$userData.records.current_rank == null ? 99999 : GlobalData.$userData.records.current_rank;
            GlobalData.$pfUserInfo = GlobalData.$userData.pf_info;
            GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
            GlobalData.$tempTeamID = 0;
            SendAndSelect.$uid = GlobalData.$userData.uid;
            SendAndSelect.$sessionid = GlobalData.$userData.sessionid;
            SendAndSelect.$userCurrPF = GlobalLocalStore.getPF();
            if(!$adStatus)
            {
               $adStatus = true;
               if(GlobalLocalStore.$pf_type_curr == "rkios")
               {
                  if(MainConfig.classTalkClass != null)
                  {
                     MainConfig.classTalkClass.onLogin(GlobalData.$userData.uid);
                  }
               }
               else if(GlobalLocalStore.$pf_type_curr == "gatios")
               {
               }
            }
            GlobalLocalStore.setSessionId(GlobalData.$userData.sessionid);
            GlobalLocalStore.setServiceId(GlobalData.$mServiceID);
            if(GlobalData.$mServiceID_obj == null)
            {
               GlobalData.$mServiceID_obj = {};
            }
            GlobalData.$mServiceID_obj[GlobalData.$mServiceID] = SendAndSelect.$systemTimer_nowSecond * 1000;
            GlobalLocalStore.setServiceIdObj(GlobalData.$mServiceID_obj);
            _loc4_ = GlobalLocalStore.getCurrUserData(SendAndSelect.$uid + "_" + GlobalData.$mServiceID);
            GlobalData.$tempAvatarLock = null;
            GlobalData.$localUser = {
               "uid":"",
               "sessionid":"",
               "avatarLock":null
            };
            if(_loc4_)
            {
               GlobalData.$localUser = _loc4_;
               GlobalData.$localUser["uid"] = GlobalData.$userData.uid;
               GlobalData.$localUser["sessionid"] = GlobalData.$userData.sessionid;
               GlobalData.$tempAvatarLock = GlobalData.$localUser["avatarLock"];
            }
            else
            {
               GlobalData.$localUser["uid"] = SendAndSelect.$uid;
               GlobalData.$localUser["sessionid"] = SendAndSelect.$sessionid;
               GlobalData.$localUser["avatarLock"] = {};
               GlobalData.$tempAvatarLock = GlobalData.$localUser["avatarLock"];
               GlobalLocalStore.setCurrUserData(SendAndSelect.$uid + "_" + GlobalData.$mServiceID,GlobalData.$localUser);
            }
            GlobalData.$msg_new_num = param1.data.msg_num;
            GlobalData.$friendReques_new_num = param1.data.apply_num;
            GuideTools.loadGuide();
            GlobalPFANE.showPfWindow();
            GlobalPFANE.setPFLog();
            GlobalPFANE.pfSubmit();
         }
         SendAndSelect.$serviceId = GlobalData.$mServiceID;
         reService_friend(null);
         var _loc2_:String = GlobalData.$mServiceID;
         _loc2_ = _loc2_.replace("-","S");
         var _loc3_:String = GlobalData.$userData.uid + "A" + _loc2_;
         var _loc5_:int = 16 - _loc3_.length;
         _loc6_ = 0;
         while(_loc6_ < _loc5_)
         {
            _loc3_ += "0";
            _loc6_++;
         }
         trace(_loc3_);
      }
      
      private function reService_friend(param1:Object) : void
      {
         var _re:Object = param1;
         var onTimer:* = function(param1:TimerEvent):void
         {
            if(GlobalData.$load2Status >= 1)
            {
               _timer.stop();
               _timer.removeEventListener("timer",onTimer);
               GlobalFunction.setLoading(false);
               GlobalFunction.setGameSoundInit();
               if(!Tools.strIsNull(GlobalData.$userData.name))
               {
                  GlobalData.$mGameClassObject.initUIGroup();
               }
               else
               {
                  GlobalData.$mGameClassObject.setBgImgToBACKGROUND();
                  removeFromParent(true);
                  GlobalData.$mGameClassObject.firstMap();
               }
            }
         };
         var _timer:Timer = new Timer(1000);
         _timer.addEventListener("timer",onTimer);
         _timer.start();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         this.clear();
      }
   }
}

