package
{
   import com.meng52.extensions.EventDispatcherANE;
   import com.meng52.extensions.KYIphone6ANE;
   import com.meng52.extensions.StoreIOS;
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalLocalStore;
   import com.meng52.net.SendAndSelect;
   import com.meng52.utils.Tools;
   import flash.filesystem.File;
   import flash.utils.getDefinitionByName;
   
   public class MainConfig
   {
      
      public static var $appAssetsDir:File;
      
      public static var $appAssetsDirString:String = "";
      
      public static var $canPay:Boolean = true;
      
      public static var $SERVER_ADDRESS:String = "";
      
      public static var macIOSid:String;
      
      public static var $gameLanguage:String = "";
      
      public static var gameSpecial:Boolean = false;
      
      public static var $font:String;
      
      public static var $isDebug:Boolean;
      
      public static var $isTest:Boolean;
      
      public static var $isWindows:Boolean;
      
      public static var $isAir:Boolean;
      
      public static var $isFightTest:Boolean;
      
      public static var $isAllBook:Boolean;
      
      public static var $hideFPS:Boolean;
      
      public static var $testReSend:Boolean;
      
      public static var $isEnglish:Boolean;
      
      public static var $idCenter_DN:Boolean;
      
      public static var $isHasBuilding:Boolean;
      
      public static var $casionBgUiName:String;
      
      public static var $betterBgUiName:String;
      
      public static var $ispentaKill:Boolean;
      
      public static var $map_id:String;
      
      public static var $magic_one:String;
      
      public static var $magic_two:String;
      
      public static var dianxinExtension:*;
      
      public static var $isCZKgroup:Boolean = false;
      
      public static var isHw_Logout:Boolean = false;
      
      public static var $isEA:Boolean;
      
      public static var VERSION_CURR:String = "";
      
      public static var $pf_notifyURI_curr:String = "/qihoo_notify/";
      
      public static var VERSION_CLEAR:String = "";
      
      public static var VERSION_CURR_TW:String = "";
      
      public static var VERSION_CURR_TW_ANDROID:String = "";
      
      public static var OBB_LENGTH:Number = 0;
      
      private static var V_STR:String = "";
      
      private static var SERVER_ADDRESS_HELP:String = "";
      
      public static var SERVER_ADDRESS_GATEWAY:String = "";
      
      public static var SERVER_ADDRESS_NOTICE:String = "";
      
      public static var SERVER_ADDRESS_HELP_HELP:String = "";
      
      public static var SERVER_ADDRESS_HELP_EXTREME:String = "";
      
      public static var SERVER_ADDRESS_HELP_ADD_MAGIC:String = "";
      
      public static var SERVER_ADDRESS_HELP_ADD_RISE:String = "";
      
      public static var SERVER_ADDRESS_HELP_ADD_WASH:String = "";
      
      public static var SERVER_ADDRESS_HELP_ADD_BOOK:String = "";
      
      public static var SERVER_ADDRESS_HELP_ZONE_BOSS:String = "";
      
      public static var SERVER_ADDRESS_HELP_DN:String = "";
      
      public static var SERVER_ADDRESS_HELP_ADD_WELFARE:String = "";
      
      public static var SERVER_ADDRESS_HELP_HG:String = "";
      
      public static var SERVER_ADDRESS_HELR_AVATAR_CULTURE:String = "";
      
      public static var SERVER_ADDRESS_HELP_EXPLORATION:String = "";
      
      public static var SERVER_ADDRESS_HELP_MYSTERY_SHOP:String = "";
      
      public static var SERVER_ADDRESS_EVERYDAYSIGN:String = "";
      
      public static var SERVER_ADDRESS_ALCHEMT:String = "";
      
      public static var SERVER_ADDRESS_PVP:String = "";
      
      public static var SERVER_ADDRESS_TIME_EXTRACTION:String = "";
      
      public static var SERVER_ADDRESS_HELP_GUILD_EXPLAIN:String = "";
      
      public static var SERVER_ADDRESS_HELP_GUILD_BATTLE:String = "";
      
      public static var SERVER_ADDRESS_HELP_GUILD_SHOP:String = "";
      
      public static var SERVER_ADDRESS_HELP_GUILD_BOSS:String = "";
      
      public static var SERVER_ADDRESS_HELP_GUILD_RESEARCH:String = "";
      
      public static var SERVER_ADDRESS_HELP_GUILD_STUDY:String = "";
      
      public static var SERVER_ADDRESS_HELP_PVP15:String = "";
      
      public static var SERVER_ADDRESS_HELP_TALENT:String = "";
      
      public static var $pf_app_name_curr:String = "";
      
      public static var GOOGLE_PUBLIC_KEY:String = "";
      
      public static var pf_tw_android_full:Boolean = false;
      
      public static var $isPlayMusicTheme:Boolean = false;
      
      public static var classANETools:*;
      
      public static var classStoreIOS:*;
      
      public static var classMainExtension:*;
      
      public static var classANESyncEvent:*;
      
      public static var classNetworkInfo:*;
      
      public static var classTalkClass:*;
      
      public static var classInmobileClass:*;
      
      public static var classIOSmacID:*;
      
      public static var classIOSLocalNotification:*;
      
      public static var class_dianxin_event:*;
      
      public static var classIOS_tl_event:*;
      
      public static var classIOS_tw_event:*;
      
      public static var classIOS_tw_android_ad:*;
      
      public static var classIOS_tw_ios_ad:*;
      
      public static var classIOS_tw_ios_ad2:*;
      
      public static var classIOS_tw_obj:*;
      
      public static var classIOS_dny_evt:*;
      
      public static var classHG_login_UserEvent:*;
      
      public static var classHG_kt:*;
      
      public static var classHG_tstore:*;
      
      public static var classHG_naver:*;
      
      public static var classGooglePay:*;
      
      public static var classADbrix:*;
      
      public static var classTapjoyAIR:*;
      
      public static var classSponsorpay:*;
      
      public static var classAppsflyer:*;
      
      public static var classChartboost:*;
      
      public static var classFacebookAD:*;
      
      public static var classIgawCommonExtension:*;
      
      public static var classGoogleObbEx:*;
      
      public static var classGoogleObbEvent:*;
      
      public static var PF_NAME_ONLY:String = "local";
      
      public static var LOADING_INFO_ARR:Array = [];
      
      public static var ERROR_ARR:Array = [];
      
      public function MainConfig()
      {
         super();
      }
      
      public static function server_address_group() : void
      {
         V_STR = "?v=" + VERSION_CURR;
         SERVER_ADDRESS_HELP = "/help/";
         SERVER_ADDRESS_GATEWAY = "/gateway/" + V_STR;
         SERVER_ADDRESS_NOTICE = "/notice/" + V_STR;
         SERVER_ADDRESS_HELP_HELP = SERVER_ADDRESS_HELP + "help.html/" + V_STR;
         SERVER_ADDRESS_HELP_EXTREME = SERVER_ADDRESS_HELP + "extreme.html/" + V_STR;
         SERVER_ADDRESS_HELP_ADD_MAGIC = SERVER_ADDRESS_HELP + "add_magic.html/" + V_STR;
         SERVER_ADDRESS_HELP_ADD_RISE = SERVER_ADDRESS_HELP + "add_rise.html/" + V_STR;
         SERVER_ADDRESS_HELP_ADD_WASH = SERVER_ADDRESS_HELP + "add_wash.html/" + V_STR;
         SERVER_ADDRESS_HELP_ADD_BOOK = SERVER_ADDRESS_HELP + "add_book.html/" + V_STR;
         SERVER_ADDRESS_HELP_ZONE_BOSS = SERVER_ADDRESS_HELP + "zone_boss.html/" + V_STR;
         SERVER_ADDRESS_HELP_DN = SERVER_ADDRESS_HELP + "dn.html/" + V_STR;
         SERVER_ADDRESS_HELP_ADD_WELFARE = SERVER_ADDRESS_HELP + "add_welfare.html/" + V_STR;
         SERVER_ADDRESS_HELP_HG = SERVER_ADDRESS_HELP + "hg_agreement.html/" + V_STR;
         SERVER_ADDRESS_HELR_AVATAR_CULTURE = SERVER_ADDRESS_HELP + "avatar_culture.html" + V_STR;
         SERVER_ADDRESS_HELP_EXPLORATION = SERVER_ADDRESS_HELP + "exploration.html" + V_STR;
         SERVER_ADDRESS_HELP_MYSTERY_SHOP = SERVER_ADDRESS_HELP + "mystery_shop.html" + V_STR;
         SERVER_ADDRESS_EVERYDAYSIGN = SERVER_ADDRESS_HELP + "check_in.html" + V_STR;
         SERVER_ADDRESS_ALCHEMT = SERVER_ADDRESS_HELP + "alchemy.html" + V_STR;
         SERVER_ADDRESS_PVP = SERVER_ADDRESS_HELP + "pvp.html" + V_STR;
         SERVER_ADDRESS_TIME_EXTRACTION = SERVER_ADDRESS_HELP + "time_extraction.html" + V_STR;
         SERVER_ADDRESS_HELP_GUILD_EXPLAIN = SERVER_ADDRESS_HELP + "guild.html" + V_STR;
         SERVER_ADDRESS_HELP_GUILD_BATTLE = SERVER_ADDRESS_HELP + "guild_pvp.html" + V_STR;
         SERVER_ADDRESS_HELP_GUILD_SHOP = SERVER_ADDRESS_HELP + "guild_shop.html" + V_STR;
         SERVER_ADDRESS_HELP_GUILD_BOSS = SERVER_ADDRESS_HELP + "guild_boss.html" + V_STR;
         SERVER_ADDRESS_HELP_GUILD_RESEARCH = SERVER_ADDRESS_HELP + "guild_research.html" + V_STR;
         SERVER_ADDRESS_HELP_GUILD_STUDY = SERVER_ADDRESS_HELP + "guild_study.html" + V_STR;
         SERVER_ADDRESS_HELP_PVP15 = SERVER_ADDRESS_HELP + "server_pvp_helo.html" + V_STR;
         SERVER_ADDRESS_HELP_TALENT = SERVER_ADDRESS_HELP + "talent.html" + V_STR;
      }
      
      public static function getServiceURLByPF(param1:String, param2:String) : void
      {
         var _loc5_:* = undefined;
         var _loc8_:* = undefined;
         var _loc7_:Class = null;
         var _loc3_:Class = null;
         var _loc4_:Class = null;
         var _loc6_:Class = null;
         pf_tw_android_full = false;
         $appAssetsDir = File.applicationDirectory;
         $appAssetsDirString = "";
         gameSpecial = false;
         classANETools = null;
         classStoreIOS = null;
         classMainExtension = null;
         classNetworkInfo = null;
         classTalkClass = null;
         classInmobileClass = null;
         classIOSmacID = null;
         classIOSLocalNotification = null;
         classIOS_tl_event = null;
         macIOSid = "";
         $gameLanguage = "cn";
         if(param2 != "Window" && param2 != "iOS")
         {
            // This public build is the local Android edition and does not use the legacy platform ANEs.
            Tools.$isAndroidB = true;
            GlobalLocalStore.$pf_type_curr = "local";
            SendAndSelect.$MACID = "";
            $SERVER_ADDRESS = "http://127.0.0.1:8080";
            $canPay = true;
            if($font.length > 0)
            {
               GlobalConfig.FONT_0 = GlobalConfig.FONT_1 = $font;
            }
            return;
         }
         if(param2 == "Window")
         {
            SendAndSelect.$MACID = "";
         }
         else if(param2 == "iOS")
         {
            try
            {
               if(getDefinitionByName("com.rekoo.mobile.ane::RkNativeUtil"))
               {
                  classIOSLocalNotification = getDefinitionByName("com.rekoo.mobile.ane::RkNativeUtil") as Class;
               }
               if(getDefinitionByName("com.rekoo.sunshine.ane.deviceidentifier::RKDeviceIdentifier"))
               {
                  classIOSmacID = getDefinitionByName("com.rekoo.sunshine.ane.deviceidentifier::RKDeviceIdentifier") as Class;
               }
            }
            catch(_error:Error)
            {
            }
            SendAndSelect.$MACID = "";
            if(classIOSmacID != null)
            {
               SendAndSelect.$MACID = classIOSmacID.getInstance().RKGetDeviceMessage();
            }
            if(param1 == "idpun")
            {
               $SERVER_ADDRESS = "http://idp.meng52.net";
            }
            else if(param1 == "idpios")
            {
               classStoreIOS = StoreIOS as Class;
               $SERVER_ADDRESS = "http://ios.meng52.net";
            }
            else if(param1 == "rkios")
            {
               classInmobileClass = getDefinitionByName("com.rekoo.inmobile.adSearch::RKInmobileAne") as Class;
               classTalkClass = getDefinitionByName("com.tendcloud.appcpa::TalkingDataAppCpa") as Class;
               classStoreIOS = StoreIOS as Class;
               $SERVER_ADDRESS = "http://rkios.meng52.net";
            }
            else if(param1 == "rkjs")
            {
               gameSpecial = true;
               classStoreIOS = StoreIOS as Class;
               $SERVER_ADDRESS = "http://rkjs.meng52.net";
            }
            else if(param1 == "rk91ios")
            {
               classMainExtension = getDefinitionByName("com.nd.complatform::NdComPlatform") as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "rkky")
            {
               classMainExtension = KYIphone6ANE as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "rkpp")
            {
               classMainExtension = getDefinitionByName("PPAne") as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "rkjsun")
            {
               gameSpecial = true;
               $SERVER_ADDRESS = "http://rkjs.meng52.net";
            }
            else if(param1 == "rkit")
            {
               classMainExtension = getDefinitionByName("org.work::AneLib") as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "rki4")
            {
               classMainExtension = getDefinitionByName("org.work::AneLib") as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "rkun")
            {
               $SERVER_ADDRESS = "http://rkios.meng52.net";
            }
            else if(param1 == "tlios")
            {
               classMainExtension = getDefinitionByName("com.efunSDK.ios::EfunSDKExtension") as Class;
               classIOS_tl_event = getDefinitionByName("com.efunSDK.ios::EfunSDKEvent") as Class;
               $SERVER_ADDRESS = "http://meng52.f3322.org";
            }
            else if(param1 == "gatios")
            {
               $gameLanguage = "tw";
               classMainExtension = getDefinitionByName("EFSDKKit::EFExContext") as Class;
               classIOS_tw_event = getDefinitionByName("EFSDKKit::EFExEvent") as Class;
               classIOS_tw_ios_ad = getDefinitionByName("com.hasoffers.nativeExtensions::MobileAppTracker") as Class;
               classIOS_tw_obj = new classMainExtension();
               $SERVER_ADDRESS = "http://lolapps.efunfun.com";
            }
            else if(param1 == "dnyios")
            {
               $gameLanguage = "tw";
               classMainExtension = getDefinitionByName("com.efunSDK.ios::EfunSDKExtension") as Class;
               classIOS_dny_evt = getDefinitionByName("com.efunSDK.ios::EfunSDKEvent") as Class;
               $SERVER_ADDRESS = "http://dny.meng52.net";
            }
            else if(param1 == "ios1006")
            {
               SendAndSelect.$MACID = "";
               classStoreIOS = StoreIOS as Class;
               $SERVER_ADDRESS = "http://ttws.meng52.net";
            }
         }
         else
         {
            Tools.$isAndroidB = true;
            classANETools = getDefinitionByName("com.meng52.ane.meng52.main::Meng52Extension") as Class;
            SendAndSelect.$MACID = classANETools.getInstance().getAndroidID();
            if(param1 == "qihoo")
            {
               classMainExtension = getDefinitionByName("com.meng52.ane.qh360.main::MainExtension") as Class;
               $SERVER_ADDRESS = "http://qihoo.meng52.net";
            }
            else if(param1 == "dtqh")
            {
               classMainExtension = getDefinitionByName("com.meng52.ane.qh360.main::MainExtension") as Class;
               $SERVER_ADDRESS = "http://dtczk.meng52.net";
            }
            else if(param1 == "rkjf")
            {
               classMainExtension = getDefinitionByName("com.rekoo.ane.tsdk::AneEventsDispatcher") as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "banshu")
            {
               classMainExtension = getDefinitionByName("com.meng52.ane.meng52.main::Meng52Extension") as Class;
               $SERVER_ADDRESS = "http://banshu.meng52.net";
               $gameLanguage = "cn";
            }
            else if(param1 == "idpad")
            {
               classMainExtension = getDefinitionByName("com.meng52.ane.meng52.main::Meng52Extension") as Class;
               $SERVER_ADDRESS = "http://idp.meng52.net";
            }
            else if(param1 == "jinsad")
            {
               classMainExtension = getDefinitionByName("com.meng52.ane.meng52.main::Meng52Extension") as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "rkafw")
            {
               classMainExtension = getDefinitionByName("com.meng52.ane.meng52.main::Meng52Extension") as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "rkdx")
            {
               classMainExtension = getDefinitionByName("com.rekoo.ane.tsdk::AneEventsDispatcher") as Class;
               dianxinExtension = classMainExtension.getInstance();
               $SERVER_ADDRESS = "http://rk2.meng52.net";
               $gameLanguage = "cn";
            }
            else if(param1 == "sgno1")
            {
               classMainExtension = getDefinitionByName("com.meng52.ane.meng52.main::Meng52Extension") as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "sytx")
            {
               classMainExtension = getDefinitionByName("com.meng52.ane.meng52.main::Meng52Extension") as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "rkhw")
            {
               classMainExtension = getDefinitionByName("com.rekoo.ane.tsdk::AneEventsDispatcher") as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "rk91")
            {
               classMainExtension = getDefinitionByName("com.rekoo.ane.tsdk::AneEventsDispatcher") as Class;
               classANESyncEvent = true;
               $SERVER_ADDRESS = "http://rk.meng52.net";
            }
            else if(param1 == "rkuc")
            {
               classMainExtension = getDefinitionByName("com.rekoo.ane.tsdk::AneEventsDispatcher") as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "dtuc")
            {
               classMainExtension = getDefinitionByName("com.rekoo.ane.tsdk::AneEventsDispatcher") as Class;
               $SERVER_ADDRESS = "http://dtczk.meng52.net";
            }
            else if(param1 == "rkwdj")
            {
               classMainExtension = getDefinitionByName("com.rekoo.ane.tsdk::AneEventsDispatcher") as Class;
               $SERVER_ADDRESS = "http://rk.meng52.net";
               $gameLanguage = "cn";
            }
            else if(param1 == "rkdk")
            {
               classMainExtension = getDefinitionByName("com.rekoo.ane.tsdk::AneEventsDispatcher") as Class;
               classANESyncEvent = true;
               $SERVER_ADDRESS = "http://rk.meng52.net";
            }
            else if(param1 == "ChinaMove")
            {
               classMainExtension = getDefinitionByName("com.rekoo.ane.tsdk::AneEventsDispatcher") as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "rkxm")
            {
               classMainExtension = getDefinitionByName("com.rekoo.ane.tsdk::AneEventsDispatcher") as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "rkaz")
            {
               classMainExtension = getDefinitionByName("com.rekoo.ane.tsdk::AneEventsDispatcher") as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "dtaz")
            {
               classMainExtension = getDefinitionByName("com.rekoo.az::AneDispatcher") as Class;
               $SERVER_ADDRESS = "http://dtczk.meng52.net";
            }
            else if(param1 == "rk37w" || GlobalLocalStore.$pf_type_curr == "rk37wmz")
            {
               classMainExtension = getDefinitionByName("com.rekoo.ane.tsdk::AneEventsDispatcher") as Class;
               classANESyncEvent = true;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "rkbd")
            {
               classMainExtension = getDefinitionByName("com.rekoo.bfb::AneDispatcher") as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "rkjsad")
            {
               gameSpecial = true;
               classMainExtension = getDefinitionByName("com.meng52.ane.meng52.main::Meng52Extension") as Class;
               $SERVER_ADDRESS = "http://rkjs.meng52.net";
            }
            else if(param1 == "rkad")
            {
               classMainExtension = getDefinitionByName("com.meng52.ane.meng52.main::Meng52Extension") as Class;
               $SERVER_ADDRESS = "http://rkios.meng52.net";
            }
            else if(param1 == "rkndw")
            {
               classMainExtension = getDefinitionByName("com.meng52.ane.meng52.main::Meng52Extension") as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "rkppw")
            {
               classMainExtension = getDefinitionByName("com.rekoo.ane.tsdk::AneEventsDispatcher") as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "7k7k")
            {
               classMainExtension = getDefinitionByName("com.rekoo.ane.tsdk::AneEventsDispatcher") as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "bfyy")
            {
               classMainExtension = getDefinitionByName("com.rekoo.ane.tsdk::AneEventsDispatcher") as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "anfeng")
            {
               classMainExtension = getDefinitionByName("com.rekoo.ane.tsdk::AneEventsDispatcher") as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "kugou")
            {
               classMainExtension = getDefinitionByName("com.rekoo.ane.tsdk::AneEventsDispatcher") as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "gameBaby")
            {
               classMainExtension = getDefinitionByName("com.rekoo.ane.tsdk::AneEventsDispatcher") as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "sougou1")
            {
               classMainExtension = getDefinitionByName("com.rekoo.ane.tsdk::AneEventsDispatcher") as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "sougou2")
            {
               classMainExtension = getDefinitionByName("com.rekoo.ane.tsdk::AneEventsDispatcher") as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "sougou3")
            {
               classMainExtension = getDefinitionByName("com.rekoo.ane.tsdk::AneEventsDispatcher") as Class;
               $SERVER_ADDRESS = "http://rk2.meng52.net";
            }
            else if(param1 == "gatad")
            {
               $gameLanguage = "tw";
               $appAssetsDir = File.documentsDirectory;
               classMainExtension = getDefinitionByName("com.efunfun.aneliblol::EfunfunAsContext") as Class;
               classIOS_tw_event = getDefinitionByName("com.efunfun.aneliblol.util::EfunfunAsConstant") as Class;
               $SERVER_ADDRESS = "http://lolapps.efunfun.com";
            }
            else if(param1 == "dnyad")
            {
               $gameLanguage = "tw";
               classMainExtension = getDefinitionByName("com.efun::EfunPlatform") as Class;
               $appAssetsDir = File.documentsDirectory;
               classGoogleObbEx = getDefinitionByName("com.efunfun.aneliblol::EfunfunAsContext") as Class;
               classGoogleObbEvent = getDefinitionByName("com.efunfun.aneliblol.util::EfunfunAsConstant") as Class;
               $SERVER_ADDRESS = "http://dny.meng52.net";
            }
            else if(param1 == "hgkt")
            {
               $gameLanguage = "tw";
               _loc5_ = getDefinitionByName("com.ssqmobile.aneas::SSQExtension") as Class;
               classMainExtension = new _loc5_();
               _loc7_ = getDefinitionByName("com.web337.anes.kt::KtExtension") as Class;
               classHG_kt = new _loc7_();
               _loc8_ = getDefinitionByName("com.web337.anes.adbrix::AdbrixExtension") as Class;
               classADbrix = new _loc8_();
               $SERVER_ADDRESS = "http://zmhg.meng52.net";
            }
            else if(param1 == "hgtstore")
            {
               $gameLanguage = "tw";
               _loc5_ = getDefinitionByName("com.ssqmobile.aneas::SSQExtension") as Class;
               classMainExtension = new _loc5_();
               _loc3_ = getDefinitionByName("com.web337.anes.tstore::TstoreExtension") as Class;
               classHG_tstore = new _loc3_();
               classHG_tstore.doInit("development");
               _loc8_ = getDefinitionByName("com.web337.anes.adbrix::AdbrixExtension") as Class;
               classADbrix = new _loc8_();
               $SERVER_ADDRESS = "http://zmhg.meng52.net";
            }
            else if(param1 == "hgnaver")
            {
               $gameLanguage = "tw";
               _loc5_ = getDefinitionByName("com.ssqmobile.aneas::SSQExtension") as Class;
               classMainExtension = new _loc5_();
               _loc4_ = getDefinitionByName("com.web337.anes.naver::NaverExtension") as Class;
               classHG_naver = new _loc4_();
               _loc8_ = getDefinitionByName("com.web337.anes.adbrix::AdbrixExtension") as Class;
               classADbrix = new _loc8_();
               $SERVER_ADDRESS = "http://zmhg.meng52.net";
            }
            else if(param1 == "hggoogle")
            {
               $gameLanguage = "tw";
               _loc6_ = getDefinitionByName("com.igaworks.air.extension::IgawCommonExtension") as Class;
               classIgawCommonExtension = new _loc6_();
               $appAssetsDir = File.documentsDirectory;
               classGoogleObbEx = getDefinitionByName("com.efunfun.aneliblol::EfunfunAsContext") as Class;
               classGoogleObbEvent = getDefinitionByName("com.efunfun.aneliblol.util::EfunfunAsConstant") as Class;
               $SERVER_ADDRESS = "http://zmhg.meng52.net";
            }
            else if(param1 == "dtczk")
            {
               classMainExtension = getDefinitionByName("com.meng52.ane.meng52.main::Meng52Extension") as Class;
               $SERVER_ADDRESS = "http://ttws.meng52.net";
            }
            else if(param1 == "1006ad")
            {
               classMainExtension = getDefinitionByName("com.meng52.ane.meng52.main::Meng52Extension") as Class;
               $SERVER_ADDRESS = "http://ttws.meng52.net";
            }
            else if(param1 == "dtdl")
            {
               classMainExtension = getDefinitionByName("com.xiawu.ane::XiawuANEHelper") as Class;
               classANESyncEvent = getDefinitionByName("com.xiawu.ane::ANESyncEvent") as Class;
               $SERVER_ADDRESS = "http://dtczk.meng52.net";
            }
            else if(param1 == "dtxm")
            {
               classMainExtension = getDefinitionByName("com.xiawu.ane::XiawuANEHelper") as Class;
               classANESyncEvent = getDefinitionByName("com.xiawu.ane::ANESyncEvent") as Class;
               $SERVER_ADDRESS = "http://dtczk.meng52.net";
            }
            else if(param1 == "dtwdj")
            {
               classMainExtension = getDefinitionByName("com.rekoo.ane.tsdk::AneEventsDispatcher") as Class;
               $SERVER_ADDRESS = "http://dtczk.meng52.net";
            }
            else if(param1 == "dtbd")
            {
               classMainExtension = getDefinitionByName("Apk_swc") as Class;
               $SERVER_ADDRESS = "http://dtczk2.meng52.net";
            }
            else if(param1 == "dtoppo")
            {
               classMainExtension = getDefinitionByName("com.meng52.ane.oppo::AsExtension") as Class;
               $SERVER_ADDRESS = "http://dtczk.meng52.net";
            }
            else if(param1 == "dthw")
            {
               classMainExtension = getDefinitionByName("com.meng52.ane.huawei::AsExtension") as Class;
               $SERVER_ADDRESS = "http://dtczk.meng52.net";
            }
            else if(param1 == "dtfl")
            {
               classMainExtension = getDefinitionByName("com.fl.ane::FlGamePlatform") as Class;
               $SERVER_ADDRESS = "http://dtczk.meng52.net";
            }
            else if(GlobalLocalStore.getPF_dtaib(param1))
            {
               classMainExtension = getDefinitionByName("com.aipppay.ane::AiPPPayExtension") as Class;
               classANESyncEvent = getDefinitionByName("com.aipppay.ane::AiPPPayEvent") as Class;
               $SERVER_ADDRESS = "http://dtczk.meng52.net";
               classMainExtension.getInstance().addEventListener(classANESyncEvent.EVT_PAY,EventDispatcherANE.callBack);
               classMainExtension.getInstance().AiPPPayInit("3001135488","Q0Q1MTVEQTk1RDg3QkY1NUNGMzc3MEZEMDg1MkMxNTJGNUI0MEI2Q01UYzJOemd3TVRJeE9EQTRPRFV5TVRjM09EY3JNVEV5TURjek5qWXdPRFU1TWpZek9UTTNOemcyTURrME5EQXhNakUyTkRVM05UUTFNREEz",true);
            }
            else if(param1 == "dtlenovo")
            {
               classMainExtension = getDefinitionByName("com.lbz.lenovo::lenovoAS") as Class;
               $SERVER_ADDRESS = "http://dtczk.meng52.net";
            }
         }
         if($isDebug)
         {
            $gameLanguage = "tw";
            $SERVER_ADDRESS = "http://qihoo.meng52.net";
         }
         $SERVER_ADDRESS = "http://127.0.0.1:8080";
         $canPay = true;
         if($font.length > 0)
         {
            GlobalConfig.FONT_0 = GlobalConfig.FONT_1 = $font;
         }
      }
   }
}

