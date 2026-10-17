package com.meng52.game.ui.element
{
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalLocalStore;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.renderers.IListItemRenderer;
   import flash.geom.Rectangle;
   import starling.display.Image;
   import starling.events.Event;

   public class ItemHelpSetting extends ItemBase implements IListItemRenderer
   {

      private var mLanguage_index:int;

      public function ItemHelpSetting()
      {
         super();
      }

      override public function layoutWH() : void
      {
         this.width = this.mScale9Image.width;
         this.height = this.mScale9Image.height;
         tweenX(false);
      }

      override public function init(param1:Object) : void
      {
         var _loc2_:Number = NaN;
         this.mScale9Image = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",520,100,new Rectangle(110,55,70,20));
         this.mScale9Image.x = 0;
         this.mScale9Image.y = -10;
         this.addChild(this.mScale9Image);
         if(param1.id != 2)
         {
            this.mImg_bg_lv = new LOL_Scale9Button(this.data.id == 0 ? (SoundManager.isMusicPlay ? "开启" : "关闭") : (SoundManager.isSoundPlay ? "开启" : "关闭"),126,47,"UI_btn_enterGame_0_0000");
            this.mImg_bg_lv.name = String(this.data.id);
            this.mImg_bg_lv.x = int(this.mScale9Image.width - this.mImg_bg_lv.width - 15) - 18;
            this.mImg_bg_lv.y = int((this.mScale9Image.height - this.mImg_bg_lv.height) * 0.5) + 5 - 14;
            this.addChild(this.mImg_bg_lv);
            this.mImg_bg_lv.addEventListener("triggered",this.onTRIGGERED_btns);
            _loc2_ = int(this.mScale9Image.width * 0.5);
            this.mTxt_title = GlobalTextStyle.getTextField(this.data.title,30,4926491,"left",_loc2_,35);
            this.addChild(this.mTxt_title);
            this.mTxt_title.x = 24 + 20;
            this.mTxt_title.y = int((this.mScale9Image.height - 35) * 0.5 - 13);
         }
         else
         {
            setLanguageUI();
         }
      }

      private function setLanguageUI() : void
      {
         var _hNum:Number;
         var _wNum:Number;
         var onTRIGGERED_language:* = function(param1:Event):void
         {
            _name = (param1.currentTarget as LOL_Button).name;
            var _loc2_:int = int(_name.charAt(_name.length - 1));
            if(_loc2_ != mLanguage_index)
            {
               GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90127),GlobalTextStyle.COLOR_W_Y_Y_G),{
                  "ok":selectLanguage,
                  "okA":[_loc2_],
                  "no":GlobalFunction.functionNull
               });
            }
         };
         var selectLanguage:* = function(param1:int, param2:Boolean = true):void
         {
            mLanguage_index = param1;
            i = 0;
            while(i < GlobalConfig.cfg_static_language_1.length)
            {
               (getChildByName("UI_language_tag_" + i) as Image).texture = GlobalFunction.getTexture("UI_language_tag_0001");
               i = i + 1;
            }
            (getChildByName("UI_language_tag_" + param1) as Image).texture = GlobalFunction.getTexture("UI_language_tag_0000");
            if(param2)
            {
               GlobalData.$gameLanguage = GlobalConfig.LANGUAGE_TYPE_INDEX[param1];
               GlobalLocalStore.setGameLanguage(GlobalData.$gameLanguage);
               GlobalData.$mGameClassObject.changeCfgToLanguage();
            }
         };
         var _btn:LOL_Button = null;
         var _tag:Image = null;
         var _w:Number = 0;
         var _name:String = "";
         var i:int = 0;
         var _lID:int = 0;
         i = 0;
         while(i < GlobalConfig.cfg_static_language_1.length)
         {
            _tag = GlobalFunction.createImage("UI_language_tag_0001");
            _tag.name = "UI_language_tag_" + i;
            _btn = GlobalFunction.createButton_5("","UI_language_btn_000" + i);
            _btn.name = "UI_language_btn_" + i;
            _btn.addEventListener("triggered",onTRIGGERED_language);
            _w = _tag.width + _btn.width + 10;
            _tag.x = 70 + i % 2 * _w;
            _tag.y = 30 + Math.floor(i / 2) * _btn.height;
            _btn.x = _tag.x;
            _btn.y = _tag.y - 10;
            addChild(_tag);
            addChild(_btn);
            i = i + 1;
         }
         selectLanguage(GlobalConfig.LANGUAGE_TYPE_INDEX.indexOf(GlobalData.$gameLanguage),false);
      }

      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         StarlingTools.removeChildrenClear(this);
         this.clear();
      }

      override public function onTRIGGERED(param1:Event) : void
      {
      }

      private function onTRIGGERED_btns(param1:Event) : void
      {
         var _loc2_:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         if(_loc2_.name == "0")
         {
            SoundManager.getOnlyExample().setMusic(!SoundManager.isMusicPlay);
            _loc2_.text = SoundManager.isMusicPlay ? "开启" : "关闭";
         }
         else
         {
            SoundManager.getOnlyExample().setSound(!SoundManager.isSoundPlay);
            _loc2_.text = SoundManager.isSoundPlay ? "开启" : "关闭";
         }
         GlobalData.$localMusic["music"] = SoundManager.isMusicPlay ? 1 : 0;
         GlobalData.$localMusic["sound"] = SoundManager.isSoundPlay ? 1 : 0;
         GlobalLocalStore.setCurrMusic(GlobalData.$localMusic);
      }
   }
}
