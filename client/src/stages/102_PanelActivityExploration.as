package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_IconText;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelBase;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import starling.core.Starling;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   
   public class PanelActivityExploration extends PanelBase
   {
      
      private const _BTN_IN:String = "mbtn_in";
      
      private const GAMERULE:String = "gamerule";
      
      private var mBg:Image;
      
      private var mBtn_In:LOL_Scale9Button;
      
      private var mInfo_bg:Scale9Image;
      
      private var mSchedule_spr:LOL_IconText;
      
      private var mFresh_num:TextField;
      
      private var gamerule:LOL_Button;
      
      private var serverBack:Object;
      
      private var _spRule:Sprite;
      
      public function PanelActivityExploration()
      {
         super();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalFunction.delTextureByBD("UI_exploration");
         mBg = null;
         if(mInfo_bg)
         {
            mInfo_bg.dispose();
            mInfo_bg.removeFromParent(true);
         }
         mInfo_bg = null;
         if(mSchedule_spr)
         {
            mSchedule_spr.dispose();
            mSchedule_spr.removeFromParent(true);
         }
         mSchedule_spr = null;
         if(mFresh_num)
         {
            mFresh_num.dispose();
            mFresh_num.removeFromParent(true);
         }
         if(_spRule)
         {
            _spRule.removeEventListener("touch",onPith);
            _spRule.removeFromParent(true);
            _spRule = null;
         }
         mFresh_num = null;
         GlobalData.$mEventDispatcher.removeEventListener("update_exploration_fresh_count",freshCountFun);
         GlobalData.$mEventDispatcher.removeEventListener("update_exploration_fresh_stage",freshCountFun);
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         removeEventListener("addedToStage",initializeHandler);
         GlobalData.$mEventDispatcher.addEventListener("update_exploration_fresh_count",freshCountFun);
         GlobalData.$mEventDispatcher.addEventListener("update_exploration_fresh_stage",freshCountFun);
         setUIs();
      }
      
      private function freshCountFun(param1:Event) : void
      {
         var _loc3_:String = null;
         var _loc4_:String = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc2_:int = 0;
         if(param1.data.refresh_count != null)
         {
            _loc3_ = param1.data.refresh_count;
            _loc4_ = GlobalLanguageStr.getLanguageStr(90560,_loc3_);
            mFresh_num.text = _loc4_;
         }
         if(param1.data.stage != null)
         {
            _loc5_ = int(param1.data.stage);
            _loc6_ = int(GlobalData.$mConfig_simple.explore.map_max);
            _loc2_ = _loc5_ <= _loc6_ ? _loc5_ : _loc6_;
            _loc4_ = GlobalLanguageStr.getLanguageStr(90566,_loc2_);
            mSchedule_spr.text = _loc4_;
         }
      }
      
      private function setUIs() : void
      {
         var o:Object;
         var _stage:int;
         var _map_max:int;
         var _battle_id:int;
         var _num:String;
         var num_info:String;
         var fun:*;
         mBg = GlobalFunction.createImage("UI_exploration",true);
         mBg.y = GlobalData.$center_height_curr - 121 - mBg.height + 10;
         addChild(mBg);
         o = GlobalFunction.get_HelpLink(GlobalLanguageStr.getLanguageStr(90649));
         _spRule = o.ui;
         _spRule.x = GlobalData.$mStageWidth - o.w - 20;
         _spRule.y = 140;
         addChild(_spRule);
         _spRule.addEventListener("touch",onPith);
         mBtn_In = new LOL_Scale9Button(GlobalLanguageStr.getStr(90549),150,70,"UI_btn_normalFun_0000");
         mBtn_In.name = "mbtn_in";
         mBtn_In.x = (GlobalData.$mStageWidth - mBtn_In.width) * 0.5;
         mBtn_In.y = mBg.y + mBg.height - 200;
         mBtn_In.addEventListener("triggered",onTRIGGERED_btn);
         addChild(mBtn_In);
         mInfo_bg = GlobalFunction.createScale9Image("UI_bg_9slice_5_0000",618,100,new Rectangle(40,30,30,30));
         mInfo_bg.x = mBg.x + (mBg.width - mInfo_bg.width) * 0.5;
         mInfo_bg.y = mBg.y + mBg.height - mInfo_bg.height - 10;
         this.addChild(mInfo_bg);
         _stage = int(GlobalData.$userData.exploration.stage);
         _map_max = int(GlobalData.$mConfig_simple.explore.map_max);
         _battle_id = _stage <= _map_max ? _stage : _map_max;
         mSchedule_spr = new LOL_IconText(GlobalLanguageStr.getLanguageStr(90566,_battle_id));
         mSchedule_spr.fontSize = MainConfig.$isEnglish ? 18 : 20;
         mSchedule_spr.x = MainConfig.$isEnglish ? mInfo_bg.x + 10 : mInfo_bg.x + 40;
         mSchedule_spr.y = mInfo_bg.y + (mInfo_bg.height - mSchedule_spr.height) * 0.5;
         mSchedule_spr.bgVisible = false;
         this.addChild(mSchedule_spr);
         _num = GlobalData.$userData.records.exploration_times.refresh_count;
         num_info = GlobalLanguageStr.getLanguageStr(90560,_num);
         mFresh_num = GlobalFunction.createTextField(400,30,num_info,"",MainConfig.$isEnglish ? 18 : 20,16777215);
         mFresh_num.x = mInfo_bg.x + MainConfig.$isEnglish ? mInfo_bg.width * 0.5 - 50 : mInfo_bg.width * 0.5;
         mFresh_num.y = mSchedule_spr.y;
         this.addChild(mFresh_num);
         if(GlobalData.backFromExploration)
         {
            fun = function():void
            {
               onTRIGGERED_btn(null);
               GlobalData.backFromExploration = false;
            };
            Starling.juggler.delayCall(fun,0.1);
         }
      }
      
      private function onTRIGGERED_btn(param1:Event) : void
      {
         SendServiceAMFFun.send_user_exploration_start(backFun);
      }
      
      protected function onPith(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(_spRule,"ended");
         if(_loc2_)
         {
            GlobalFunction.popPanelHelp(MainConfig.SERVER_ADDRESS_HELP_EXPLORATION);
         }
      }
      
      private function backFun(param1:Object) : void
      {
         var _loc6_:Object = null;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc2_:int = 0;
         var _armyMax:int = 15;
         var _armyCount:int = 0;
         if(param1.data && GlobalFunction.isVersionedProfileReceipt(param1) && this.stage)
         {
            if(!GlobalData.isCurrentProfileSyncEnvelope(param1.state_sync))
            {
               LayoutUIAnimation.getOnlyExample().popWords("探索状态已更新，请重新确认队伍。");
               return;
            }
            GlobalData.$exploration_data = null;
            GlobalData.$exploration_data = param1.data;
            GlobalData.$exploration_select_avatar = null;
            _loc6_ = Tools.clone(param1.data.army);
            for(var _loc5_:String in _loc6_)
            {
               _loc6_[_loc5_]["id"] = _loc5_;
            }
            GlobalData.$exploration_select_avatar = _loc6_;
            _loc3_ = int(GlobalData.$userData.exploration.stage);
            _loc4_ = int(GlobalData.$mConfig_simple.explore.map_max);
            _loc2_ = _loc3_ <= _loc4_ ? _loc3_ : _loc4_;
            mSchedule_spr.text = GlobalLanguageStr.getLanguageStr(90566,_loc2_);
            _armyMax = int(GlobalData.$mConfig_simple.explore.army_max);
            if(_armyMax < 1)
            {
               _armyMax = 15;
            }
            _armyCount = Tools.getElementNum(GlobalData.$userData.exploration.army);
            if(_armyCount < _armyMax)
            {
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("exploration_select",false,true);
            }
            else
            {
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("exploration_select_game",false,true);
            }
         }
      }
   }
}

