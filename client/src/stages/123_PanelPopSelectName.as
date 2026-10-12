package com.meng52.game.ui.panel
{
   import com.adobe.text.NativeText;
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelBase;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.StarlingTools;
   import feathers.display.Scale3Image;
   import feathers.display.Scale9Image;
   import flash.events.FocusEvent;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import starling.core.Starling;
   import starling.display.Sprite;
   import starling.events.Event;
   
   public class PanelPopSelectName extends PanelBase
   {
      
      public static const BTN_NAME_BACK:String = "btn_name_back";
      
      public static const BTN_NAME_ENTERGAME:String = "btn_name_enterGame";
      
      public static const BTN_NAME_NEXT:String = "btn_name_next";
      
      public static const BTN_NAME_RANDOM:String = "btn_name_random";
      
      public var _box:Sprite;
      
      private var nt:NativeText;
      
      private var _mBg_input:Scale3Image;
      
      private var _mBg_box:Scale9Image;
      
      private var mBtn_random:LOL_Scale9Button;
      
      private var mBtn_enterGame:LOL_Scale9Button;
      
      private const _gap:int = 20;
      
      public function PanelPopSelectName()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getStr(90421),320);
         this.addEventListener("pop_layout_y_is_ok",onPop_layout);
      }
      
      private function onPop_layout() : void
      {
         this.y = 50;
         this.init();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(this.nt)
         {
            if(this.nt.parent)
            {
               this.nt.parent.removeChild(this.nt);
            }
         }
         if(this._box)
         {
            StarlingTools.removeChildrenClear(this._box);
            this._box.removeFromParent(true);
            this._box = null;
         }
      }
      
      private function init() : void
      {
         _box = new Sprite();
         this.addChild(_box);
         _mBg_box = GlobalFunction.createScale9Image("UI_bg_9slice_7_0000",370,85,new Rectangle(30,20,40,40));
         _mBg_box.x = (mImg9_baseBg.width - _mBg_box.width) * 0.5;
         _mBg_box.y = 110;
         _mBg_input = GlobalFunction.createScale3Image("UI_bg_9slice_6_0000",20,30,350);
         _mBg_input.x = _mBg_box.x + (_mBg_box.width - _mBg_input.width) * 0.5;
         _mBg_input.y = _mBg_box.y + (_mBg_box.height - _mBg_input.height) * 0.5;
         _box.addChild(_mBg_input);
         _box.addChild(_mBg_box);
         mBtn_random = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20306),150,70,"UI_btn_normalFun_0000");
         mBtn_random.name = "btn_name_random";
         mBtn_random.x = _mBg_input.x + 10;
         mBtn_random.y = _mBg_input.y + _mBg_input.height + 20;
         _box.addChild(mBtn_random);
         mBtn_random.addEventListener("triggered",onTRIGGERED);
         mBtn_enterGame = new LOL_Scale9Button(GlobalLanguageStr.getStr(90422),150,70,"UI_btn_normalFun_0000");
         mBtn_enterGame.name = "btn_name_enterGame";
         mBtn_enterGame.x = _mBg_input.x + _mBg_input.width - mBtn_enterGame.width - 10;
         mBtn_enterGame.y = mBtn_random.y;
         mBtn_enterGame.addEventListener("triggered",onTRIGGERED);
         _box.addChild(mBtn_enterGame);
         this.setInputText();
      }
      
      public function setInputText() : void
      {
         nt = null;
         nt = new NativeText(1);
         nt.autoCorrect = true;
         nt.textAlign = "center";
         nt.fontSize = 30 * GlobalData.$mStage$Starling_h;
         nt.maxChars = 16;
         nt.color = 0;
         nt.assignFocus();
         nt.fontFamily = GlobalConfig.FONT_1;
         nt.text = "";
         nt.width = Starling.current.nativeStage.stageWidth;
         nt.height = 46 * 2 * GlobalData.$mStage$Starling_h;
         var _loc1_:Point = new Point(this._mBg_input.x,this._mBg_input.y);
         nt.y = int((50 + _loc1_.y + 10) * GlobalData.$mStage$Starling_h);
         nt.addEventListener("focusIn",onFOCUS);
         GlobalData.$mStarling.nativeStage.addChild(nt);
         selectRandomName();
      }
      
      private function selectRandomName() : void
      {
         var re_send_user_get_uname:* = function(param1:Object):void
         {
            if(nt)
            {
               nt.text = String(param1.data);
            }
         };
         SendServiceAMFFun.send_user_get_uname(re_send_user_get_uname,{"lan_type":GlobalData.$gameLanguage});
      }
      
      private function onFOCUS(param1:FocusEvent) : void
      {
         param1.currentTarget.removeEventListener("focusIn",onFOCUS);
         if(param1.type == "focusIn")
         {
            if(this.nt)
            {
               this.nt.text = "";
            }
         }
      }
      
      private function onTRIGGERED(param1:Event) : void
      {
         var _loc3_:String = null;
         var _loc4_:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         var _loc2_:String = _loc4_.name;
         if(_loc2_ == "btn_name_enterGame")
         {
            if(this.nt && this.nt.text != "")
            {
               _loc3_ = GlobalFunction.checkName(this.nt.text);
               if(_loc3_)
               {
                  GlobalFunction.popError(_loc3_);
               }
               else
               {
                  GlobalData.$mUserName = this.nt.text;
                  SendServiceAMFFun.send_user_init_user(this.re_init_user,{
                     "name":GlobalData.$mUserName,
                     "aid":GlobalData.$mInitAvatarID
                  });
               }
            }
            else
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90011));
            }
         }
         else if(_loc2_ == "btn_name_random")
         {
            this.selectRandomName();
         }
      }
      
      private function re_init_user(param1:Object) : void
      {
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            return;
         }

         var _loc2_:Object = GlobalData.$userData;


         if(this.stage)
         {
            GlobalData.$mGameClassObject.initUIGroup();
         }
      }
   }
}

