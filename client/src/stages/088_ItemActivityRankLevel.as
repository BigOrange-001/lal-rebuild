package com.meng52.game.ui.element
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.Tools;
   import feathers.controls.renderers.IListItemRenderer;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import starling.display.DisplayObject;
   import starling.display.Sprite;
   import starling.events.Event;
   
   public class ItemActivityRankLevel extends ItemTaskAward implements IListItemRenderer
   {
      private var mReceiptCoinBefore:Number;

      
      private var _item:*;
      
      private var _msg:String;
      
      private var _sp:Sprite;
      
      private var _bg:Scale9Image;
      
      public function ItemActivityRankLevel()
      {
         super();
      }
      
      override public function init(param1:Object) : void
      {
         this.setUI();
      }
      
      override public function setUI() : void
      {
         var _giftObj:Object;
         var _awardType:String;
         var i:Object;
         var _infoStr:String;
         var _awardUI:Object;
         var _ui:DisplayObject;
         var _rulerLeft:Number;
         var _info:TextFieldHtmlRenderer;
         var _rec:Rectangle;
         var _mColor:Array;
         var btn:LOL_Scale9Button;
         var _rankCfg:Array = GlobalData.$userData.attrs.rank_lv as Array;
         var _needLv:int = int(data["need"]);
         var _hadAward:Boolean = _rankCfg.indexOf(_needLv) > -1;
         var _can:Boolean = false;
         if(!_hadAward)
         {
            if(GlobalData.$userData.lv >= _needLv)
            {
               _can = true;
            }
         }
         _bg = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",GlobalData.$mStageWidth - 30,110,new Rectangle(110,55,70,20));
         this.addChild(_bg);
         this.width = _bg.width;
         this.height = _bg.height;
         _giftObj = data["gift"];
         _awardType = "";
         mAwardItem = null;
         for(i in _giftObj)
         {
            _awardType = i.toString();
            mAwardItem = _giftObj[i];
         }
         data["giftType"] = _awardType;
         _infoStr = GlobalLanguageStr.replaceStrArr(GlobalLanguageStr.getLanguageStr(data["info"]),[_needLv]);
         _awardUI = GlobalFunction.getAwardByType(_awardType,mAwardItem);
         mMsg = _awardUI.msg;
         m_uiBox = new Sprite();
         _ui = _awardUI.ui;
         if(_ui)
         {
            _ui.x = _ui.y = 10;
            m_uiBox.addChild(_ui);
         }
         m_uiBox.x = int(_bg.x + 25);
         m_uiBox.y = int(_bg.y + (_bg.height - 90) * 0.5) - 5;
         addChild(m_uiBox);
         _rulerLeft = int(_bg.x + 90 * 2);
         _info = GlobalTextStyle.getHtmlTextRenderer();
         _rec = null;
         _info.mLayoutFun = function():void
         {
            _rec = _info.getTextSnapshotFrame();
            _info.x = 165;
            _info.y = 40;
         };
         _mColor = [4926491,13056,13056,10027008];
         _info.text = Tools.formatLineX(_infoStr,_mColor,20);
         addChild(_info);
         btn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(_hadAward ? 20377 : 20173),125,45,"UI_btn_enterGame_0_0000");
         btn.x = int(_bg.x + _bg.width - btn.width - 25);
         btn.y = int((_bg.height - btn.height) * 0.5);
         btn.enabled = _can;
         btn.addEventListener("triggered",onTRIGGERED_btn);
         addChild(btn);
      }
      
      override protected function onTRIGGERED_btn(param1:Event) : void
      {
         var _loc3_:Array = null;
         var _loc2_:int = 0;
         var _loc4_:Boolean = false;
         soundTriggered();
         var _loc5_:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         if(_loc5_.enabled)
         {
            mReceiptCoinBefore = Number(GlobalData.$userData.coin);
            SendServiceAMFFun.send_user_rank_lv(reService,{"lv":data["need"]});
         }
         else
         {
            _loc3_ = GlobalData.$userData.attrs.rank_lv as Array;
            _loc2_ = int(data["need"]);
            _loc4_ = _loc3_.indexOf(_loc2_) > -1;
            if(_loc4_)
            {
               GlobalFunction.popError(GlobalLanguageStr.getStr(90244));
            }
            else
            {
               GlobalFunction.popError(GlobalLanguageStr.getStr(90520));
            }
         }
      }
      
      private function reService(param1:Object) : void
      {
         if(stage == null)
         {
            return;
         }
         var _loc4_:Object = param1.data;
         var _loc2_:int = _loc4_.coin - int(mReceiptCoinBefore);
         var _loc3_:String = "sound03";
         SoundManager.getOnlyExample().playSound(_loc3_);
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.coin = _loc4_.coin;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs = _loc4_.attrs;
         }
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
         GlobalFunction.popAward("coin",GlobalLanguageStr.getLanguageStr(90062,mMsg),_loc2_,false);
         GlobalData.$mEventDispatcher.dispatchEventWith("update_avatar_award_rank_lv");
      }
   }
}

