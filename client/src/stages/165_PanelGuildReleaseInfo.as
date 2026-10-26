package com.meng52.game.ui.panel
{
   import com.adobe.text.NativeText;
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelCenterPVE;
   import com.meng52.global.SocketManager;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import starling.core.Starling;
   import starling.display.Sprite;
   import starling.events.Event;
   
   public class PanelGuildReleaseInfo extends PanelCenterPVE
   {
      
      private var promptText:TextFieldHtmlRenderer;
      
      private var bottom_bg:Scale9Image;
      
      private var releaseInfoBtn:LOL_Scale9Button;
      
      private var nt:NativeText;
      
      private var _cfg:Object;
      
      private var numText:int;
      
      private var _data:Object;
      
      public function PanelGuildReleaseInfo(param1:Object)
      {
         _data = param1;
         super();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(promptText)
         {
            promptText.removeFromParent(true);
            promptText.dispose();
         }
         if(bottom_bg)
         {
            bottom_bg.removeFromParent(true);
            bottom_bg.dispose();
         }
         if(releaseInfoBtn)
         {
            releaseInfoBtn.removeFromParent(true);
            releaseInfoBtn.dispose();
         }
         if(nt)
         {
            GlobalData.$mStarling.nativeStage.removeChild(this.nt);
         }
         promptText = null;
         bottom_bg = null;
         releaseInfoBtn = null;
         nt = null;
         StarlingTools.removeChildrenClear(this);
         this.clear();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(97691),388,600,true);
         SendServiceAMFFun.send_user_associatione_is(onReGuild);
         _cfg = GlobalData.$mGuild_simple.a_key_message;
         numText = _cfg.max_word;
         setUI();
      }
      
      private function onReGuild(param1:Object) : void
      {
         var _loc3_:Function = null;
         var _loc2_:Object = param1.data;
         if(_loc2_.flag == 0)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97835),true);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":4});
            onCLOSE_PANEL_SELF();
            _loc3_ = _data.reFun;
            _loc3_();
         }
      }
      
      private function setUI() : void
      {
         var _loc4_:String = null;
         var _loc1_:int = 0;
         var _loc12_:int = 0;
         var _loc7_:Sprite = new Sprite();
         this.addChild(_loc7_);
         bottom_bg = GlobalFunction.createScale9Image("UI_bg_9slice_6_0000",460,140,new Rectangle(20,20,20,20));
         bottom_bg.x = mImg9_baseBg.x + (mImg9_baseBg.width - bottom_bg.width) * 0.5;
         bottom_bg.y = 130;
         _loc7_.addChild(bottom_bg);
         promptText = GlobalTextStyle.getHtmlTextRenderer();
         promptText.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97831,numText),GlobalTextStyle.COLOR_W_B_Y_O,120,20);
         promptText.x = bottom_bg.x + 60;
         promptText.y = bottom_bg.y - 40;
         _loc7_.addChild(promptText);
         var _loc6_:Number = bottom_bg.width - 10;
         var _loc8_:Number = mImg9_baseBg.height - 30 - 150;
         var _loc2_:Array = _cfg.message_list;
         _loc12_ = 0;
         while(_loc12_ < _loc2_.length)
         {
            _loc1_ = Math.floor(0 + (_loc2_.length - 1 + 1) * Math.random());
            _loc4_ = _loc2_[_loc1_];
            _loc12_++;
         }
         var _loc10_:int = int(GlobalData.$userData.attrs.association_id);
         var _loc5_:String = "" + (10000 + _loc10_);
         var _loc3_:Number = Starling.contentScaleFactor;
         var view:Rectangle = Starling.current.viewPort;
         this.nt = null;
         this.nt = new NativeText(5);
         this.nt.autoCorrect = true;
         this.nt.textAlign = "left";
         this.nt.fontSize = 20 * GlobalData.$mStage$Starling_h;
         this.nt.maxChars = 52;
         this.nt.color = 0;
         this.nt.fontFamily = GlobalConfig.FONT_0;
         this.nt.text = GlobalLanguageStr.getLanguageStr(_loc4_,_loc5_);
         var inputBounds:Rectangle = bottom_bg.getBounds(stage);
         var scaleX:Number = view.width / GlobalData.$mStageWidth;
         var scaleY:Number = view.height / GlobalData.$mStageHeight;
         this.nt.width = int((inputBounds.width - 20) * scaleX);
         this.nt.height = int((inputBounds.height - 8) * scaleY);
         this.nt.x = int(view.x + (inputBounds.x + 10) * scaleX);
         this.nt.y = int(view.y + (inputBounds.y + 4) * scaleY);
         GlobalData.$mStarling.nativeStage.addChild(this.nt);
         releaseInfoBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(97755),125,65,"UI_btn_guild_4_0000");
         releaseInfoBtn.fontSize = 21;
         releaseInfoBtn.fontColor = 16777215;
         releaseInfoBtn.x = mImg9_baseBg.x + (mImg9_baseBg.width - releaseInfoBtn.width) * 0.5;
         releaseInfoBtn.y = bottom_bg.y + bottom_bg.height + 15;
         _loc7_.addChild(releaseInfoBtn);
         releaseInfoBtn.addEventListener("triggered",onReleaseInfo);
      }
      
      private function onReleaseInfo(param1:Event) : void
      {
         if(this.nt.text.length <= 0)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97756),true);
            return;
         }
         if(this.nt.text.length > numText)
         {
            GlobalFunction.tipsOS_ios(GlobalLanguageStr.getLanguageStr(90010),GlobalLanguageStr.getLanguageStr(97817,numText));
            return;
         }
         GlobalData.$userGuild.chatText = this.nt.text;
         this.onCLOSE_PANEL_SELF();
         var chatSocketManager:SocketManager = SocketManager.getInstance();
         chatSocketManager.init();
      }
   }
}

