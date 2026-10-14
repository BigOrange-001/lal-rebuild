package
{
   import com.meng52.events.NetEvent;
   import com.meng52.extensions.NotificationsIOS;
   import com.meng52.game.Game;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalLocalStore;
   import com.meng52.game.global.GlobalPFANE;
   import com.meng52.game.manager.DebugManager;
   import com.meng52.global.ConfigManager;
   import com.meng52.global.GlobalStaticConst;
   import com.meng52.net.SendAndSelect;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.LoaderTools;
   import com.meng52.utils.LocalStore;
   import com.meng52.utils.Tools;
   import flash.desktop.NativeApplication;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.Loader;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.KeyboardEvent;
   import flash.filesystem.File;
   import flash.filesystem.FileStream;
   import flash.geom.Rectangle;
   import flash.media.SoundMixer;
   import flash.system.Capabilities;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.utils.ByteArray;
   import flash.utils.getDefinitionByName;
   import flash.utils.getTimer;
   import flash.utils.setTimeout;
   import starling.core.Starling;
   import starling.events.EventDispatcher;
   import starling.utils.AssetManager;
   import starling.utils.RectangleUtil;
   
   [SWF(width="500", height="375", backgroundColor="#000000", frameRate="30")]
   public class MainLLOL extends Sprite
   {
      
      public static var $logoBox:Sprite;
      
      public static var $logoBitmap:Bitmap;
      
      public static var $logoBitmap_czk:Bitmap;
      
      public static var $UI_init_ui_logo:Bitmap;
      
      public static var $UI_img_index:Bitmap;
      
      public static var $UI_waitStage_loadingClip:ByteArray;
      
      public static var $XML_loadingClip:XML;
      
      public static var $XML_init:XML;
      
      public static const TEXTURE_UI_WAITSTAGE_LOADINGCLIP:String = "ui_waitStage_loadingClip";
      
      public static const BASE_WIDTH:int = 640;
      
      public static const BASE_HEIGHT:int = 960;
      
      public static const AIR_WIDTH:int = 640;
      
      public static var AIR_HEIGHT:int = 960;
      
      public static var AIR_SCALE:Number = 1;
      
      public static var $padBgLeft:Bitmap;
      
      public static var $padBgRight:Bitmap;
      
      public static var $starlingRec:Rectangle;
      
      public static var $isHightOS:Boolean = false;
      
      public static var $sound_lol_theme:Class = loading_mp3$624c8cf040eb9d7222779707f650079f223602527;
      
      public var UI_init_logo:Class = logo_png$fd4912dcc0b52c65f25aba8ec8d7969a518538278;
      
      public var UI_img_index:Class = getDefinitionByName("ui_img_index_png$fb44ee62dacf39bb1e2d7dbb9526dadc-966789018") as Class;
      
      public var UI_init_ui_logo:Class = getDefinitionByName("ui_logo_png$e335bbd756c36162ba0dc88c374c8888-148600735") as Class;
      
      public var UI_waitStage_loadingClip:Class = ui_waitStage_loadingClip_atf$fb2416c0e6f6e5dd5c33a43af2938e53823746115;
      
      public var Config_ui_waitStage_loadingClip:Class = ui_waitStage_loadingClip_xml$bb6a2c1d160f949ce1c44a1dbd5ef877823719111;
      
      public var Config_initLoader:Class = getDefinitionByName("initLoader_xml$2216d217c6b921e84f36cea063682bc4-1143981681") as Class;
      
      public var Config_language_tw:Class = language_tw_xml$879146f2c71a4e1f433e963f68743fb41608885072;
      
      private var mTxt_pro:TextField;
      
      private var mTxt_status:TextField;
      
      private var mTxt_txtF:TextFormat;
      
      public function MainLLOL()
      {
         super();
         this.addEventListener("addedToStage",onADDED_TO_STAGE);
      }
      
      public static function showPadBg() : void
      {
         if(GlobalStaticConst.$IOS_iPad)
         {
            if($padBgLeft && $padBgRight)
            {
               $padBgLeft.visible = $padBgRight.visible = true;
            }
         }
      }
      
      private function onADDED_TO_STAGE(param1:Event) : void
      {
         this.alpha = 0.999;
         param1.currentTarget.removeEventListener("addedToStage",onADDED_TO_STAGE);
         if(this.stage)
         {
            var startupConfig:ConfigManager = ConfigManager.getInstance();
            startupConfig.init();
            if(Capabilities.manufacturer.indexOf("Android") != -1)
            {
               MainConfig.VERSION_CURR = "1.0.1";
            }
            this.checkClearLocalStore();
            this.stage.quality = "low";
            this.stage.scaleMode = "noScale";
            this.stage.align = "TL";
            this.mouseChildren = this.mouseEnabled = false;
            SoundMixer.audioPlaybackMode = "ambient";
            checkCapabilities();
            if(MainConfig.$isAir)
            {
               LoadXML();
            }
            else
            {
               initFun();
            }
         }
      }
      
      private function LoadXML() : void
      {
         var _loc2_:FileStream = null;
         var _loc1_:File = new File("C:/lol_ini.xml");
         if(_loc1_.exists)
         {
            _loc2_ = new FileStream();
            _loc2_.addEventListener("complete",reXML);
            _loc2_.openAsync(_loc1_,"read");
         }
         else
         {
            initFun();
         }
      }
      
      private function reXML(param1:Event) : void
      {
         $XML_init = XML(param1.target.readUTFBytes(param1.target.bytesAvailable));
         param1.target.close();
         initXML();
         initFun();
      }
      
      private function initXML() : void
      {
         if(!$XML_init)
         {
            return;
         }
         var _loc1_:XML = $XML_init;
         if($XML_init.hasOwnProperty("server"))
         {
            MainConfig.$SERVER_ADDRESS = $XML_init.server;
         }
         if($XML_init.hasOwnProperty("language"))
         {
            MainConfig.$gameLanguage = $XML_init.language;
         }
         if($XML_init.hasOwnProperty("version"))
         {
            MainConfig.VERSION_CURR = GlobalStaticConst.$isAndroid ? "1.0.1" : $XML_init.version;
         }
         if($XML_init.hasOwnProperty("height"))
         {
            AIR_HEIGHT = $XML_init.height;
         }
         if($XML_init.hasOwnProperty("scale"))
         {
            AIR_SCALE = $XML_init.scale;
         }
         if($XML_init.hasOwnProperty("isReSend"))
         {
            MainConfig.$testReSend = $XML_init.isReSend == "1" ? true : false;
         }
         if($XML_init.hasOwnProperty("isAllBook"))
         {
            MainConfig.$isAllBook = $XML_init.isAllBook == "1" ? true : false;
         }
         if($XML_init.hasOwnProperty("isHideFPS"))
         {
            MainConfig.$hideFPS = $XML_init.isHideFPS == "1" ? true : false;
         }
         if($XML_init.hasOwnProperty("isTest"))
         {
            MainConfig.$isTest = $XML_init.isTest == "1" ? true : false;
         }
         if($XML_init.hasOwnProperty("isEnglish"))
         {
            MainConfig.$isEnglish = $XML_init.isEnglish == "1" ? true : false;
         }
         if($XML_init.hasOwnProperty("isEA"))
         {
            MainConfig.$isEA = $XML_init.isEA == "1" ? true : false;
         }
         setAirStage();
      }
      
      public function checkCapabilities() : void
      {
         GlobalData.$fullScreenWidth = stage.fullScreenWidth;
         GlobalData.$fullScreenHeight = stage.fullScreenHeight;
         if(Capabilities.manufacturer.indexOf("Window") > -1)
         {
            MainConfig.$isWindows = true;
            if(MainConfig.$isAir || !Capabilities.isDebugger)
            {
               MainConfig.$isAir = true;
               MainConfig.$isDebug = true;
               setAirStage();
            }
         }
         if(Capabilities.isDebugger)
         {
            MainConfig.$isDebug = true;
         }
      }
      
      public function setAirStage() : void
      {
         var _loc2_:int = 0;
         var _loc1_:int = 0;
         if(MainConfig.$isAir)
         {
            _loc2_ = Tools.toInt(640 * AIR_SCALE);
            _loc1_ = Tools.toInt(AIR_HEIGHT * AIR_SCALE);
            stage.stageWidth = _loc2_;
            stage.stageHeight = _loc1_;
            GlobalData.$fullScreenWidth = _loc2_;
            GlobalData.$fullScreenHeight = _loc1_;
         }
      }
      
      private function checkClearLocalStore() : void
      {
         var _loc1_:String = GlobalLocalStore.getVersion();
         if((_loc1_ == "" || Tools.compareVersion(_loc1_,MainConfig.VERSION_CLEAR) <= 0) && MainConfig.$isDebug)
         {
            LocalStore.clearAll();
         }
         GlobalLocalStore.setVersion(MainConfig.VERSION_CURR);
      }
      
      private function initFun() : void
      {
         if(GlobalStaticConst.$isAndroid)
         {
            MainConfig.VERSION_CURR = "1.0.1";
            MainConfig.server_address_group();
         }
         if(MainConfig.$isTest)
         {
            DebugManager.instance().register(this.stage);
         }
         GlobalLocalStore.$pf_token_curr = "";
         $logoBox = new Sprite();
         addChild($logoBox);
         $logoBitmap = new UI_init_logo() as Bitmap;
         $logoBitmap.x = int((GlobalData.$fullScreenWidth - $logoBitmap.width) * 0.5);
         $logoBitmap.y = int((GlobalData.$fullScreenHeight - $logoBitmap.height) * 0.5);
         $logoBox.addChild($logoBitmap);
         GlobalData.$mEventDispatcher = new EventDispatcher();
         GlobalData.$mConfigInitLoader = XML(new Config_initLoader());
         GlobalLanguageStr.$_global_language_str = XML(new Config_language_tw());
         $XML_loadingClip = XML(new Config_ui_waitStage_loadingClip());
         SendAndSelect.$appVersion = MainConfig.VERSION_CURR;
         SendAndSelect.$cfgVersion = GlobalLocalStore.getVersion_cfg();
         GlobalLocalStore.$pf_type_curr = MainConfig.PF_NAME_ONLY;
         this.checkOSTypeAndSetting();
      }
      
      private function checkOSTypeAndSetting() : void
      {
         var _loc5_:String = null;
         var _loc3_:String = null;
         var _loc1_:Number = NaN;
         NativeApplication.nativeApplication.systemIdleMode = "keepAwake";
         var _loc4_:Boolean = true;
         var _loc2_:String = "";
         GlobalStaticConst.$isIOS = Capabilities.manufacturer.indexOf("iOS") != -1;
         GlobalStaticConst.$isAndroid = Capabilities.manufacturer.indexOf("Android") != -1;
         if(GlobalStaticConst.$isIOS)
         {
            _loc2_ = "iOS";
            GlobalStaticConst.$IOS_iPad = false;
            _loc4_ = true;
            if(Capabilities.screenResolutionX > 640)
            {
               GlobalStaticConst.$IOS_iPad = true;
            }
         }
         else if(GlobalStaticConst.$isAndroid)
         {
            _loc1_ = Math.min(Capabilities.screenResolutionX,Capabilities.screenResolutionY);
            if(_loc1_ >= 1080)
            {
               $isHightOS = true;
            }
            else
            {
               $isHightOS = false;
            }
            _loc2_ = "Android";
            _loc4_ = true;
         }
         else
         {
            _loc2_ = "Window";
            _loc4_ = true;
            if(GlobalData.$fullScreenWidth >= 768)
            {
               GlobalStaticConst.$isAndroid_1024 = true;
            }
            else
            {
               _loc5_ = "bg@640x960.png";
               _loc3_ = "Default.png";
            }
         }
         if(GlobalLocalStore.$pf_type_curr == "gatad" || GlobalLocalStore.$pf_type_curr == "hgkt" || GlobalLocalStore.$pf_type_curr == "hgtstore" || GlobalLocalStore.$pf_type_curr == "hgnaver" || GlobalLocalStore.$pf_type_curr == "hggoogle" || GlobalLocalStore.$pf_type_curr == "qihoo" || GlobalLocalStore.$pf_type_curr == "dtqh" || GlobalLocalStore.$pf_type_curr == "dnyad")
         {
            stage.autoOrients = true;
         }
         else
         {
            stage.autoOrients = false;
         }
         if(MainConfig.$ispentaKill)
         {
            stage.autoOrients = true;
            if(GlobalLocalStore.$pf_type_curr != "ios1006" && GlobalLocalStore.$pf_type_curr != "dtqh" && GlobalLocalStore.$pf_type_curr != "1006ad")
            {
               MainConfig.$isCZKgroup = true;
            }
         }
         GlobalStaticConst.$scaleFactor = _loc4_ ? 1 : 2;
         MainConfig.getServiceURLByPF(GlobalLocalStore.$pf_type_curr,_loc2_);
         initXML();
         SendAndSelect.setConnectNet(MainConfig.$SERVER_ADDRESS + MainConfig.SERVER_ADDRESS_GATEWAY,"http_api");
         if(GlobalFunction.check_isHadTOKEN())
         {
            NotificationsIOS.getInstance().init(MainConfig.$isDebug);
            NotificationsIOS.getInstance().addEventListener("event_token",onEVENT_TOKEN);
            NotificationsIOS.getInstance().subFun();
         }
         re_music();
         if(GlobalStaticConst.$isAndroid)
         {
            stage.addEventListener("keyDown",keyboardHandler);
         }
      }
      
      private function onEVENT_TOKEN(param1:NetEvent) : void
      {
         GlobalData.$notificationsIOS_token = param1.data.tokenId;
         GlobalPFANE.setPF_token(param1.data.tokenId);
      }
      
      private function re_music(param1:Object = null) : void
      {
         MainConfig.$isPlayMusicTheme = true;
         loadFun_step1();
      }
      
      protected function keyboardHandler(param1:KeyboardEvent) : void
      {
         var _event:KeyboardEvent = param1;
         var ok_exit:* = function():void
         {
            GlobalPFANE.extPF_quit();
         };
         if(_event.keyCode == 16777238 || _event.keyCode == 18 || _event.keyCode == 36 || _event.keyCode == 16777235)
         {
            _event.preventDefault();
            _event.stopPropagation();
            if(GlobalStaticConst.$isAndroid)
            {
               if(GlobalLocalStore.$pf_type_curr == "rkuc" || GlobalLocalStore.$pf_type_curr == "dtuc")
               {
                  ok_exit();
               }
               else
               {
                  if(GlobalLocalStore.$pf_type_curr == "rkhw")
                  {
                     MainConfig.classMainExtension.getInstance().rkOnPause();
                  }
                  GlobalFunction.tipsOS_ios(MainConfig.ERROR_ARR[3],MainConfig.ERROR_ARR[4],MainConfig.ERROR_ARR[5],ok_exit,MainConfig.ERROR_ARR[6],GlobalFunction.functionNull);
               }
            }
         }
      }
      
      private function loadFun_step1() : void
      {
         var chinaMoveCallBack:*;
         $UI_waitStage_loadingClip = new UI_waitStage_loadingClip();
         $UI_init_ui_logo = new UI_init_ui_logo() as Bitmap;
         $UI_img_index = new UI_img_index() as Bitmap;
         if(GlobalLocalStore.$pf_type_curr != "rkdk" && GlobalLocalStore.$pf_type_curr != "rk91" && GlobalLocalStore.$pf_type_curr != "rkuc" && GlobalLocalStore.$pf_type_curr != "dtdl" && GlobalLocalStore.$pf_type_curr != "dtuc" && GlobalLocalStore.$pf_type_curr != "dtbd" && GlobalLocalStore.$pf_type_curr != "rkaz" && GlobalLocalStore.$pf_type_curr != "dtaz" && GlobalLocalStore.$pf_type_curr != "rkdx" && GlobalLocalStore.$pf_type_curr != "rkppw" && GlobalLocalStore.$pf_type_curr != "banshu" && GlobalLocalStore.$pf_type_curr != "hgkt" && GlobalLocalStore.$pf_type_curr != "hgtstore" && GlobalLocalStore.$pf_type_curr != "hgnaver" && GlobalLocalStore.$pf_type_curr != "hggoogle")
         {
            $UI_init_ui_logo.x = int((GlobalData.$fullScreenWidth - $UI_init_ui_logo.width) * 0.5);
            $UI_init_ui_logo.y = int((GlobalData.$fullScreenHeight - $UI_init_ui_logo.height) * 0.5);
            $logoBox.addChild($UI_init_ui_logo);
         }
         if(GlobalLocalStore.$pf_type_curr == "qihoo" || GlobalLocalStore.$pf_type_curr == "dtqh" || GlobalLocalStore.$pf_type_curr == "rkxm" || GlobalLocalStore.$pf_type_curr == "rkhw" || GlobalLocalStore.$pf_type_curr == "tlios" || GlobalLocalStore.$pf_type_curr == "rkwdj" || GlobalLocalStore.$pf_type_curr == "ChinaMove" || GlobalLocalStore.$pf_type_curr == "rkjf" || GlobalLocalStore.$pf_type_curr == "dnyios" || GlobalLocalStore.$pf_type_curr == "dnyad" || GlobalLocalStore.$pf_type_curr == "gatad" || GlobalLocalStore.$pf_type_curr == "hgkt" || GlobalLocalStore.$pf_type_curr == "hgtstore" || GlobalLocalStore.$pf_type_curr == "hgnaver" || GlobalLocalStore.$pf_type_curr == "hggoogle" || GlobalLocalStore.$pf_type_curr == "gatios" || GlobalLocalStore.$pf_type_curr == "rkdx" || GlobalLocalStore.$pf_type_curr == "rkdk" || GlobalLocalStore.$pf_type_curr == "rk91")
         {
            if(GlobalLocalStore.$pf_type_curr == "dnyad" || GlobalLocalStore.$pf_type_curr == "hggoogle" || GlobalLocalStore.$pf_type_curr == "gatad")
            {
               GlobalPFANE.$progressSetFun = setProgressTxt;
               GlobalPFANE.$progressdelFun = delProgressTxt;
               GlobalPFANE.$statusFun = setStatusTxt;
               GlobalPFANE.$setTxtsFun = setTxts;
            }
            else if(GlobalLocalStore.$pf_type_curr == "gatios")
            {
               if(MainConfig.classIOS_tw_ios_ad != null)
               {
                  MainConfig.classIOS_tw_ios_ad.instance.init("12388","b16f58010e868e74c50000a8f51ff251");
                  MainConfig.classIOS_tw_ios_ad.instance.setPackageName("com.efunfun.lol");
               }
            }
            if(GlobalLocalStore.$pf_type_curr == "ChinaMove")
            {
               chinaMoveCallBack = function(param1:*):void
               {
                  var _loc3_:String = param1.code;
                  var _loc2_:String = param1.level;
                  if(_loc3_ == "LoginSuccess")
                  {
                     GlobalPFANE.ChinaMoveLevel = _loc2_;
                     GlobalLocalStore.setChinaMoveUid(_loc2_);
                     MainConfig.classMainExtension.getInstance().removeEventListener("status",chinaMoveCallBack);
                  }
                  if(_loc2_ == "success")
                  {
                     GlobalPFANE.ChinaMoveLevel = GlobalLocalStore.getChinaMoveUid();
                  }
                  GlobalLocalStore.$pf_token_curr = GlobalPFANE.ChinaMoveLevel;
               };
               MainConfig.classMainExtension.getInstance().addEventListener("status",chinaMoveCallBack);
               MainConfig.classMainExtension.getInstance().setUserListener();
               MainConfig.classMainExtension.getInstance().rkInit("1238964756zxcvbn");
            }
            pf_init(true);
         }
         else
         {
            if(GlobalLocalStore.$pf_type_curr == "rkios")
            {
               if(MainConfig.classTalkClass != null)
               {
                  MainConfig.classTalkClass.init("8cfaca5f03c14334a7024bcef9320be8","Store");
               }
               if(MainConfig.classInmobileClass != null)
               {
                  MainConfig.classInmobileClass.getInstance().inmobile("895dc86bd6d04ec1b2af8bf4e7cd7ef7");
               }
            }
            pf_init(false);
         }
      }
      
      private function pf_init(param1:Boolean) : void
      {
         if(param1)
         {
            setTimeout(GlobalPFANE.extPF_init,3000,checkOtherLogo);
         }
         else
         {
            setTimeout(checkOtherLogo,3000);
         }
      }
      
      private function checkOtherLogo() : void
      {
         var logo_czk:* = function(param1:Loader):void
         {
            $logoBitmap_czk = param1.content as Bitmap;
            $logoBitmap_czk.x = int((GlobalData.$fullScreenWidth - $logoBitmap_czk.width) * 0.5);
            $logoBitmap_czk.y = int((GlobalData.$fullScreenHeight - $logoBitmap_czk.height) * 0.5);
            $logoBox.addChild($logoBitmap_czk);
            setTimeout(logo_czk_end,3000);
         };
         var logo_czk_end:* = function():void
         {
            init();
         };
         if(MainConfig.$isCZKgroup)
         {
            LoaderTools.loadAssets("logo_czk.png",logo_czk);
         }
         else
         {
            init();
         }
      }
      
      private function init() : void
      {
         var _padLeft:Number;
         var _padTop:Number;
         var _viewPort:Rectangle;
         var _stageWidth:int = Capabilities.screenResolutionX;
         var _stageHeight:int = Capabilities.screenResolutionY;
         var _starlingStageWidth:int = 0;
         var _starlingStageHeight:int = 0;
         if(MainConfig.$isAir)
         {
            _stageWidth = GlobalData.$fullScreenWidth;
            _stageHeight = GlobalData.$fullScreenHeight;
         }
         else if(MainConfig.$isDebug)
         {
            if(MainConfig.$isWindows)
            {
               _stageWidth = GlobalData.$fullScreenWidth;
               _stageHeight = GlobalData.$fullScreenHeight;
            }
            else if(Capabilities.manufacturer.indexOf("Mac") > -1)
            {
               _stageWidth = GlobalData.$fullScreenWidth;
               _stageHeight = GlobalData.$fullScreenHeight;
            }
         }
         Starling.multitouchEnabled = false;
         Starling.handleLostContext = false;
         _padLeft = (GlobalData.$fullScreenWidth - 640) * 0.5;
         _padTop = (GlobalData.$fullScreenHeight - 960) * 0.5;
         _starlingStageWidth = _stageWidth;
         _starlingStageHeight = _stageHeight;
         GlobalData.$isNotFullScreenX = 0;
         GlobalData.$isNotFullScreen = false;
         if(MainConfig.$isWindows)
         {
            _starlingStageWidth = 640;
            _starlingStageHeight = _starlingStageWidth * GlobalData.$fullScreenHeight / GlobalData.$fullScreenWidth;
            if(_starlingStageHeight >= 960)
            {
               _viewPort = RectangleUtil.fit(new Rectangle(0,0,_starlingStageWidth,_starlingStageHeight),new Rectangle(0,0,GlobalData.$fullScreenWidth,GlobalData.$fullScreenHeight),"showAll");
            }
            else
            {
               _viewPort = RectangleUtil.fit(new Rectangle(0,0,640,960),new Rectangle(0,0,GlobalData.$fullScreenWidth,GlobalData.$fullScreenHeight),"showAll");
               GlobalData.$isNotFullScreen = true;
               GlobalData.$isNotFullScreenX = Math.abs((GlobalData.$fullScreenWidth - 640) * 0.5);
               _starlingStageWidth = 640;
               _starlingStageHeight = 960;
            }
         }
         else
         {
            _starlingStageWidth = 640;
            _starlingStageHeight = _starlingStageWidth * GlobalData.$fullScreenHeight / GlobalData.$fullScreenWidth;
            if(GlobalStaticConst.$IOS_iPad)
            {
               _viewPort = RectangleUtil.fit(new Rectangle(0,0,640,960),new Rectangle(0,0,GlobalData.$fullScreenWidth,GlobalData.$fullScreenHeight),"showAll");
               GlobalData.$isNotFullScreenX = int(_viewPort.x);
               _starlingStageWidth = 640;
               _starlingStageHeight = 960;
               LoaderTools.loadAssets("padBg.png",completePadBg);
            }
            else if(_starlingStageHeight >= 960)
            {
               _viewPort = RectangleUtil.fit(new Rectangle(0,0,_starlingStageWidth,_starlingStageHeight),new Rectangle(0,0,GlobalData.$fullScreenWidth,GlobalData.$fullScreenHeight),"showAll");
            }
            else
            {
               _viewPort = RectangleUtil.fit(new Rectangle(0,0,640,960),new Rectangle(0,0,GlobalData.$fullScreenWidth,GlobalData.$fullScreenHeight),"showAll");
               GlobalData.$isNotFullScreen = true;
               GlobalData.$isNotFullScreenX = Math.abs((GlobalData.$fullScreenWidth - 640) * 0.5);
               _starlingStageWidth = 640;
               _starlingStageHeight = 960;
            }
         }
         $starlingRec = _viewPort;
         GlobalData.$assetManager = new AssetManager(GlobalStaticConst.$scaleFactor);
         GlobalData.$assetManager.verbose = MainConfig.$isDebug;
         GlobalData.$mStarlingStageWidth = _starlingStageWidth;
         GlobalData.$mStarlingStageHeight = _starlingStageHeight;
         GlobalData.$mStarling = new Starling(Game,stage,_viewPort);
         GlobalData.$mStarling.stage.stageWidth = _starlingStageWidth;
         GlobalData.$mStarling.stage.stageHeight = _starlingStageHeight;
         GlobalData.$mStarling.simulateMultitouch = false;
         GlobalData.$mStarling.enableErrorChecking = MainConfig.$isDebug;
         GlobalData.$mStarling.showStats = MainConfig.$hideFPS ? false : MainConfig.$isDebug;
         GlobalData.$mStarling.start();
         GlobalData.$mStarling.addEventListener("rootCreated",starling_rootCreatedHandler);
         NativeApplication.nativeApplication.addEventListener("activate",function(param1:*):void
         {
            GlobalPFANE.activity_pf(true);
            GlobalData.$mStarling.start();
            GlobalData.$gameIsOut = false;
            if(GlobalLocalStore.$pf_type_curr == "7k7k" || GlobalLocalStore.$pf_type_curr == "bfyy" || GlobalLocalStore.$pf_type_curr == "anfeng" || GlobalLocalStore.$pf_type_curr == "gameBaby" || GlobalLocalStore.$pf_type_curr == "kugou" || GlobalLocalStore.$pf_type_curr == "sougou1" || GlobalLocalStore.$pf_type_curr == "sougou2" || GlobalLocalStore.$pf_type_curr == "sougou3")
            {
               MainConfig.classMainExtension.getInstance().rkOnDestory();
               MainConfig.classMainExtension.getInstance().rkOnResume();
            }
            if(GlobalLocalStore.$pf_type_curr == "dnyad")
            {
               GlobalPFANE.showPfWindow(1);
            }
            else if(GlobalLocalStore.$pf_type_curr == "dtoppo")
            {
               GlobalPFANE.extPF_bbs(1);
            }
            SoundManager.getOnlyExample().setAllMusic(true,false);
            var _loc2_:Number = getTimer();
            var _loc3_:Number = GlobalData.$gameGetTimer;
            var _loc4_:Number = 0;
            if(_loc3_ > 0 && _loc2_ > _loc3_)
            {
               _loc4_ = (_loc2_ - _loc3_) * 0.001;
               SendAndSelect.$systemTimer_nowSecond += Math.max(0,_loc4_ - 1);
            }
         });
         NativeApplication.nativeApplication.addEventListener("deactivate",function(param1:*):void
         {
            GlobalPFANE.activity_pf(false);
            GlobalData.$mStarling.stop();
            GlobalData.$gameIsOut = true;
            SoundManager.getOnlyExample().setAllMusic(false,false);
            var _loc2_:Number = getTimer();
            GlobalData.$gameGetTimer = _loc2_;
            if(GlobalStaticConst.$isAndroid)
            {
               if(GlobalLocalStore.$pf_type_curr == "dtoppo")
               {
                  GlobalPFANE.extPF_bbs(-1);
               }
               else if(GlobalLocalStore.$pf_type_curr == "dnyad")
               {
                  GlobalPFANE.showPfWindow(2);
               }
            }
            else if(GlobalStaticConst.$isIOS && GlobalLocalStore.$pf_type_curr == "rk91ios")
            {
               GlobalPFANE.extPF_bbs(5);
            }
         });
         this.stage.addEventListener("resize",stage_resizeHandler);
         this.stage.addEventListener("deactivate",stage_deactivateHandler);
      }
      
      private function completePadBg(param1:Loader) : void
      {
         var _loc2_:Bitmap = param1.content as Bitmap;
         var _loc3_:BitmapData = _loc2_.bitmapData.clone();
         $padBgLeft = new Bitmap(_loc3_);
         $padBgRight = new Bitmap(_loc3_);
         var _loc4_:Number = int($starlingRec.x);
         $padBgLeft.x = _loc4_;
         $padBgRight.x = stage.fullScreenWidth - _loc4_;
         $padBgLeft.height = $padBgRight.height = stage.fullScreenHeight;
         $padBgLeft.scaleX = -1;
         addChild($padBgLeft);
         addChild($padBgRight);
         if(GlobalData.$mStarling)
         {
            if(GlobalData.$mStarling.isStarted)
            {
               $padBgLeft.visible = $padBgRight.visible = true;
            }
         }
         else
         {
            $padBgLeft.visible = $padBgRight.visible = false;
         }
         if(_loc2_.bitmapData)
         {
            _loc2_.bitmapData.dispose();
         }
         param1.unload();
      }
      
      private function starling_rootCreatedHandler(param1:Object, param2:Game) : void
      {
         GlobalData.$mStarling.removeEventListener("rootCreated",starling_rootCreatedHandler);
      }
      
      private function stage_resizeHandler(param1:Event) : void
      {
      }
      
      private function stage_deactivateHandler(param1:Event) : void
      {
         GlobalData.$mStarling.stop();
         param1.currentTarget.addEventListener("activate",stage_activateHandler);
      }
      
      private function stage_activateHandler(param1:Event) : void
      {
         param1.currentTarget.removeEventListener("activate",stage_activateHandler);
         GlobalData.$mStarling.start();
      }
      
      public function setProgressTxt(param1:Number, param2:Number) : void
      {
         var _loc4_:Number = NaN;
         var _loc3_:Number = NaN;
         if(mTxt_pro != null && mTxt_txtF != null)
         {
            _loc4_ = param1 / 1024 / 1024;
            _loc4_ = Math.floor(_loc4_ * 100) / 100;
            _loc3_ = param2 / 1024 / 1024;
            _loc3_ = Math.floor(_loc3_ * 100) / 100;
            mTxt_pro.text = _loc4_ + "MB" + " / " + _loc3_ + "MB";
            mTxt_pro.setTextFormat(mTxt_txtF);
         }
      }
      
      public function setTxts() : void
      {
         if(mTxt_pro == null && mTxt_txtF == null && mTxt_status == null)
         {
            mTxt_txtF = new TextFormat("Droid Sans Fallback",25,16777215);
            mTxt_txtF.align = "center";
            mTxt_txtF.size = 34;
            mTxt_status = new TextField();
            mTxt_status.width = stage.fullScreenWidth;
            mTxt_status.height = 200;
            mTxt_status.text = "";
            mTxt_status.textColor = 16777215;
            mTxt_status.y = stage.fullScreenHeight - 300;
            mTxt_status.setTextFormat(mTxt_txtF);
            addChild(mTxt_status);
            mTxt_pro = new TextField();
            mTxt_pro.width = stage.fullScreenWidth;
            mTxt_pro.height = 50;
            mTxt_pro.text = "";
            mTxt_pro.textColor = 16777215;
            mTxt_pro.y = mTxt_status.y + mTxt_status.height + 10;
            mTxt_pro.setTextFormat(mTxt_txtF);
            addChild(mTxt_pro);
         }
      }
      
      public function setStatusTxt(param1:String) : void
      {
         if(mTxt_status != null && mTxt_txtF != null)
         {
            mTxt_status.text = param1;
            mTxt_status.setTextFormat(mTxt_txtF);
         }
      }
      
      public function delProgressTxt() : void
      {
         if(mTxt_pro != null)
         {
            if(mTxt_pro.parent)
            {
               removeChild(mTxt_pro);
            }
         }
         if(mTxt_status != null)
         {
            if(mTxt_status.parent)
            {
               removeChild(mTxt_status);
            }
         }
         mTxt_txtF = null;
         mTxt_pro = null;
         mTxt_status = null;
      }
   }
}

