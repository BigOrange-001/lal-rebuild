package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelBase;
   import com.meng52.utils.StageWebViewBase;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import starling.display.DisplayObject;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class PanelHelpNotice extends PanelBase
   {
      
      public var address:String = "";
      
      public var title:String = "";
      
      public var mBg_login:Scale9Image;
      
      public var mBg_title:LOL_Button;
      
      protected var mBtn_close:LOL_Scale9Button;
      
      private var mBtn_touch_close:Quad;
      
      public var mBg_img:Scale9Image;
      
      private var mBg_png:Image;
      
      public var mBg_help_style_0:Image;
      
      public var mBg_help_style_1:Image;
      
      public var mBg_help_style_2:Image;
      
      public var mBg_help_txt:TextField;
      
      public var mBg_loading_txt:TextField;
      
      public var mBtn_notification_close:LOL_Button;
      
      public var mTouch_self:Boolean = false;
      
      public var mBgHeight:Number = 850;
      
      public var mIE_height:Number = 150;
      
      public var mQuad_bg:Quad;
      
      private var mWebAnchor:DisplayObject;
      private var mWebLocalRect:Rectangle;
      private var mOwnedWebView:StageWebViewBase;

      public function PanelHelpNotice(param1:String, param2:String)
      {
         address = param1;
         title = param2;
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         removeEventListener("addedToStage",initializeHandler);
         this.htmlFun();
      }
      
      public function setUIAndInfo(param1:String, param2:String) : void
      {
         address = param1;
         title = param2;
         htmlFun();
      }
      
      public function htmlFun() : void
      {
         var _loc3_:DisplayObject = null;
         var _loc11_:Point = null;
         var _loc2_:Number = NaN;
         var _loc1_:Number = NaN;
         var _loc4_:Number = NaN;
         var _loc7_:Number = NaN;
         var _loc10_:String = null;
         var _loc9_:Rectangle = null;
         var _loc6_:Number = NaN;
         var _loc5_:Number = NaN;
         if(mTouch_self)
         {
            mQuad_bg = Tools.newQuad(GlobalData.$mStageWidth,GlobalData.$mStageHeight,0,0,16711680);
            mQuad_bg.alpha = 0;
            this.addChild(mQuad_bg);
         }
         if(MainConfig.$ispentaKill && address == MainConfig.SERVER_ADDRESS_NOTICE)
         {
            mBg_png = GlobalFunction.createImage("pic_notification_bg",true);
            mBg_png.y = (GlobalData.$mStageHeight - mBg_png.height) * 0.5;
            addChild(mBg_png);
            _loc3_ = mBg_png;
            openNoticeWebView(_loc3_,new Rectangle(83,250,_loc3_.width - 165,_loc3_.height - mIE_height - 205),MainConfig.$SERVER_ADDRESS + address);
            mBtn_notification_close = GlobalFunction.createButtonStarling("UI_regist_btn_0_0001",{
               "t":GlobalLanguageStr.getStr(20121),
               "fs":25,
               "fc":1118481
            });
            mBtn_notification_close.shadowFilter();
            mBtn_notification_close.x = int((GlobalData.$mStageWidth - mBtn_notification_close.width) * 0.5);
            mBtn_notification_close.y = _loc3_.y + _loc3_.height - mBtn_notification_close.height - 15;
            mBtn_notification_close.addEventListener("triggered",closeFun);
            this.addChild(mBtn_notification_close);
         }
         else
         {
            mBg_img = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",640,mBgHeight,new Rectangle(110,55,70,20));
            _loc6_ = GlobalData.$mStage$Starling_w;
            _loc5_ = GlobalData.$mStage$Starling_h;
            mBg_img.x = int((GlobalData.$mStageWidth - mBg_img.width) * 0.5);
            mBg_img.y = int((GlobalData.$mStageHeight - mBg_img.height) * 0.5);
            addChild(mBg_img);
            _loc3_ = mBg_img;
            if(!mTouch_self)
            {
               mBg_help_style_0 = GlobalFunction.createImage("UI_help_style_0_0000",true);
               mBg_help_style_0.scaleX = 1.35;
               mBg_help_style_0.touchable = false;
               mBg_help_style_0.x = (mBg_img.width - mBg_help_style_0.width) / 2;
               mBg_help_style_0.y = mBg_img.height - mBg_help_style_0.height - 25;
               mBg_img.addChild(mBg_help_style_0);
               mBg_help_style_1 = GlobalFunction.createImage("UI_help_style_1_0000",true);
               mBg_help_style_1.touchable = false;
               mBg_help_style_1.x = (mBg_img.width / 2 - mBg_help_style_1.width) / 2 - 15;
               mBg_help_style_1.y = 25;
               mBg_img.addChild(mBg_help_style_1);
               mBg_help_style_2 = GlobalFunction.createImage("UI_help_style_1_0000",true);
               mBg_help_style_2.touchable = false;
               mBg_help_style_2.x = mBg_img.width - (mBg_img.width / 2 - mBg_help_style_2.width) / 2 + 15;
               mBg_help_style_2.y = mBg_help_style_1.y;
               mBg_help_style_2.scaleX = -1;
               mBg_img.addChild(mBg_help_style_2);
            }
            mBg_help_txt = GlobalTextStyle.getTextField(title,30,1513239,"center",200,46);
            mBg_help_txt.touchable = false;
            mBg_help_txt.x = mBg_img.width / 2 - mBg_help_txt.width / 2;
            mBg_help_txt.y = mBg_help_txt.height / 1.5 - 10;
            mBg_img.addChild(mBg_help_txt);
            mBg_loading_txt = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90438),40,1513239,"center",200,35);
            mBg_loading_txt.touchable = false;
            mBg_loading_txt.x = mBg_img.width / 2 - mBg_loading_txt.width / 2;
            mBg_loading_txt.y = _loc3_.height / 2;
            mBg_img.addChild(mBg_loading_txt);
            openNoticeWebView(_loc3_,new Rectangle(30,70,_loc3_.width - 60,_loc3_.height - mIE_height),MainConfig.$SERVER_ADDRESS + address);
            mBtn_close = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20121),126,50,"UI_btn_enterGame_0_0000");
            mBtn_close.shadowFilter();
            mBtn_close.x = int((GlobalData.$mStageWidth - mBtn_close.width) * 0.5);
            mBtn_close.y = _loc3_.y + _loc3_.height - mBtn_close.height - 20;
            this.addChild(mBtn_close);
            mBtn_close.addEventListener("triggered",this.onTRIGGERED_btns);
         }
         var _loc8_:Quad = new Quad(2,2,0);
         _loc8_.visible = false;
         _loc8_.x = int((GlobalData.$mStageWidth - _loc8_.width) * 0.5);
         _loc8_.y = GlobalData.$mStageHeight - _loc8_.height;
         addChild(_loc8_);
      }
      
      private function closeFun(param1:Event) : void
      {
         GlobalData.$mGameClassObject.closePopUp();
      }
      
      private function imageComFun() : void
      {
         var _loc3_:DisplayObject = null;
         var _loc7_:Number = NaN;
         var _loc6_:Number = NaN;
         mBg_img = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",550,700,new Rectangle(110,55,70,20));
         _loc7_ = GlobalData.$mStage$Starling_w;
         _loc6_ = GlobalData.$mStage$Starling_h;
         mBg_img.x = int((GlobalData.$mStageWidth - mBg_img.width) * 0.5);
         mBg_img.y = int((GlobalData.$mStageHeight - mBg_img.height) * 0.5);
         addChild(mBg_img);
         _loc3_ = mBg_img;
         mBg_help_style_0 = GlobalFunction.createImage("UI_help_style_0_0000",true);
         mBg_help_style_0.touchable = false;
         mBg_help_style_0.x = (mBg_img.width - mBg_help_style_0.width) / 2;
         mBg_help_style_0.y = mBg_img.height - mBg_help_style_0.height - 25;
         mBg_img.addChild(mBg_help_style_0);
         mBg_help_style_1 = GlobalFunction.createImage("UI_help_style_1_0000",true);
         mBg_help_style_1.touchable = false;
         mBg_help_style_1.x = (mBg_img.width / 2 - mBg_help_style_1.width) / 2 + 10;
         mBg_help_style_1.y = mBg_help_style_1.height / 1.5;
         mBg_img.addChild(mBg_help_style_1);
         mBg_help_style_2 = GlobalFunction.createImage("UI_help_style_1_0000",true);
         mBg_help_style_2.touchable = false;
         mBg_help_style_2.x = mBg_img.width - (mBg_img.width / 2 - mBg_help_style_2.width) / 2 - 10;
         mBg_help_style_2.y = mBg_help_style_2.height / 1.5;
         mBg_help_style_2.scaleX = -1;
         mBg_img.addChild(mBg_help_style_2);
         mBtn_close.x = mBg_img.width - mBtn_close.width - 20;
         mBtn_close.y = mBtn_close.height / 1.5;
         mBg_img.addChild(mBtn_close);
         mBtn_close.addEventListener("triggered",this.onTRIGGERED_btns);
         mBg_help_txt = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20103),40,1513239,"center",200,35);
         mBg_help_txt.touchable = false;
         mBg_help_txt.x = mBg_img.width / 2 - mBg_help_txt.width / 2;
         mBg_help_txt.y = mBg_help_txt.height / 1.5;
         mBg_img.addChild(mBg_help_txt);
         openNoticeWebView(_loc3_,new Rectangle(6,6,_loc3_.width - 12,_loc3_.height - 16),MainConfig.$SERVER_ADDRESS + address);
         var _loc8_:Quad = new Quad(2,2,0);
         _loc8_.visible = false;
         _loc8_.x = int((GlobalData.$mStageWidth - _loc8_.width) * 0.5);
         _loc8_.y = GlobalData.$mStageHeight - _loc8_.height;
         addChild(_loc8_);
      }
      
      private function nativeNoticeRect(anchor:DisplayObject, area:Rectangle) : Rectangle
      {
         var start:Point = anchor.localToGlobal(new Point(area.x,area.y));
         var end:Point = anchor.localToGlobal(new Point(area.right,area.bottom));
         var viewport:Rectangle = GlobalData.$mStarling.viewPort;
         var sx:Number = viewport.width / GlobalData.$mStarling.stage.stageWidth;
         var sy:Number = viewport.height / GlobalData.$mStarling.stage.stageHeight;
         var left:Number = Math.floor(viewport.x + Math.min(start.x,end.x) * sx);
         var top:Number = Math.floor(viewport.y + Math.min(start.y,end.y) * sy);
         var right:Number = Math.ceil(viewport.x + Math.max(start.x,end.x) * sx);
         var bottom:Number = Math.ceil(viewport.y + Math.max(start.y,end.y) * sy);
         var rect:Rectangle = new Rectangle(left,top,Math.max(1,right-left),Math.max(1,bottom-top));
         return rect.intersection(viewport);
      }

      private function openNoticeWebView(anchor:DisplayObject, area:Rectangle, url:String) : void
      {
         if(mOwnedWebView) mOwnedWebView.clear();
         mWebAnchor = anchor;
         mWebLocalRect = area;
         mOwnedWebView = new StageWebViewBase(GlobalData.$mStarling.nativeStage,url,nativeNoticeRect(anchor,area));
         GlobalData.$stageWebViewBase = mOwnedWebView;
         addEventListener("enterFrame",syncNoticeWebView);
      }

      private function syncNoticeWebView(event:Event) : void
      {
         if(!stage || !mWebAnchor || !mOwnedWebView || !mOwnedWebView.mStageWebView) return;
         var rect:Rectangle = nativeNoticeRect(mWebAnchor,mWebLocalRect);
         if(rect.width <= 0 || rect.height <= 0 || mOwnedWebView.mRec.equals(rect)) return;
         mOwnedWebView.mRec = rect;
         mOwnedWebView.mStageWebView.viewPort = rect;
      }

      public function onTRIGGERED_btns(param1:Event) : void
      {
         GlobalData.$mGameClassObject.closePopUp();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(mBtn_close)
         {
            mBtn_close.removeFromParent(true);
         }
         if(mBg_login)
         {
            mBg_login.removeFromParent(true);
            mBg_login.dispose();
         }
         if(mBg_title)
         {
            mBg_title.removeFromParent(true);
         }
         if(mBg_img)
         {
            mBg_img.removeFromParent(true);
         }
         removeEventListener("enterFrame",syncNoticeWebView);
         if(mOwnedWebView)
         {
            mOwnedWebView.clear();
            if(GlobalData.$stageWebViewBase === mOwnedWebView) GlobalData.$stageWebViewBase = null;
         }
         mOwnedWebView = null;
         mWebAnchor = null;
         mWebLocalRect = null;
         if(mBg_png)
         {
            GlobalFunction.delTextureByBD("pic_notification_bg");
            mBg_png.removeFromParent(true);
         }
         if(mBtn_notification_close)
         {
            mBtn_notification_close.dispose();
            mBtn_notification_close.removeFromParent(true);
         }
         mBtn_notification_close = null;
         StarlingTools.removeChildrenClear(this);
         clear();
         dispose();
         mBtn_close = null;
         mBg_login = null;
         mBg_title = null;
         mBg_img = null;
         mBg_png = null;
      }
   }
}

