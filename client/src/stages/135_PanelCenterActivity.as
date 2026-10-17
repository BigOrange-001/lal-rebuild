package com.meng52.game.ui.screen
{
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.ui.element.ItemActivity;
   import com.meng52.game.ui.panel.PanelActivityFund;
   import com.meng52.game.ui.panel.PanelActivityGamble;
   import com.meng52.game.ui.panel.PanelActivityGroupBuy;
   import com.meng52.game.ui.panel.PanelActivityMorph;
   import com.meng52.game.ui.panel.PanelActivityMorphSelect;
   import com.meng52.game.ui.panel.PanelActivityMorphUp;
   import com.meng52.game.ui.panel.PanelActivityRank;
   import com.meng52.game.ui.panel.PanelActivityRankLevel;
   import com.meng52.game.ui.panel.PanelActivityRankList;
   import com.meng52.game.ui.panel.PanelActivityRoulette;
   import com.meng52.game.ui.panel.PanelActivitySpendRank;
   import com.meng52.game.ui.panel.PanelActivityTimeExtraction;
   import com.meng52.game.ui.panel.PanelActivityTimePay;
   import com.meng52.game.ui.panel.PanelActivityWelfare;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.StarlingTools;
   import feathers.controls.List;
   import feathers.data.ListCollection;
   import feathers.layout.HorizontalLayout;
   import starling.display.Image;
   import starling.events.Event;
   
   public class PanelCenterActivity extends PanelCenterMainAvatar
   {
      
      public static const ACTIVITY_FUN_ID_TASK:String = "task";
      
      public static const ACTIVITY_FUN_ID_RANK:String = "rank";
      
      public static const ACTIVITY_FUN_ID_GAMBLE:String = "gamble";
      
      public static const ACTIVITY_FUN_ID_ROULETTE:String = "roulette";
      
      public static const ACTIVITY_FUN_ID_RANK_LV:String = "rank_lv";
      
      public static const ACTIVITY_FUN_ID_FUND:String = "fund";
      
      public static const ACTIVITY_FUN_ID_MORPH:String = "morph";
      
      public static const ACTIVITY_FUN_ID_MORPH_SELECT:String = "morph_select";
      
      public static const ACTIVITY_FUN_ID_MORPH_UP:String = "morph_up";
      
      public static const ACTIVITY_FUN_ID_SPEND_RANK:String = "spend_rank";
      
      public static const ACTIVITY_FUN_ID_TIME_PAY:String = "time_pay";
      
      public static const ACTIVITY_FUN_ID_WELFARE:String = "welfare";
      
      public static const ACTIVITY_FUN_ID_GROUPON:String = "groupon";
      
      public static var $activityFunObj:Object;
      
      public static const $fun_type:Object = {
         "task":"UI_activity_btn_task_0_0000",
         "rank":"UI_activity_btn_rank_0_0000",
         "pay":"UI_activity_btn_pay_0_0000",
         "gamble":"UI_activity_btn_gamble_0_0000",
         "roulette":"UI_activity_btn_roulette_0_0000",
         "rank_lv":"UI_activity_btn_rank_lv_0_0000",
         "fund":"UI_activity_btn_fund_0_0000",
         "morph":"UI_activity_btn_morph_0_0000",
         "spend_rank":"UI_activity_btn_spend_rank_0_0000",
         "time_pay":"UI_activity_btn_sale_0000",
         "welfare":"UI_activity_btn_welfare_0000",
         "groupon":"UI_activity_btn_groupbuy_0_0000"
      };
      
      private var mPanelCenterTaskAward:PanelCenterTaskAward;
      
      private var mPanelCenterShopVIP:PanelCenterShopVIP;
      
      private var mPanelActivityRank:PanelActivityRank;
      
      private var mPanelActivityGamble:PanelActivityGamble;
      
      private var mPanelActivityRankLevel:PanelActivityRankLevel;
      
      private var mPanelActivityRoulette:PanelActivityRoulette;
      
      private var mPanelActivityFund:PanelActivityFund;
      
      private var mPanelActivityMorph:PanelActivityMorph;
      
      private var mPanelActivityMorphSelect:PanelActivityMorphSelect;
      
      private var mPanelActivityMorphUp:PanelActivityMorphUp;
      
      private var mPanelActivitySpendRank:PanelActivitySpendRank;
      
      private var mPanelActivityTimePay:PanelActivityTimePay;
      
      private var mPanelActivityWelfare:PanelActivityWelfare;
      
      private var mPanelActivityGroupBuy:PanelActivityGroupBuy;
      
      private var mPanelActivityTimeExtraction:PanelActivityTimeExtraction;
      
      private var mFunCfg:Object;
      
      private var mBg_right:Image;
      
      private var mBg_left:Image;
      
      public var mCurr_funID:String = "";
      
      public function PanelCenterActivity()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         removeEventListener("addedToStage",initializeHandler);
         mCurr_funID = "task";
         mPanelCenterTaskAward = new PanelCenterTaskAward();
         mPanelCenterTaskAward.y = 0;
         addChild(mPanelCenterTaskAward);
         mPanelCenterTaskAward.update();
      }
      
      private function nextFun(param1:int) : void
      {
         var _loc2_:int = mList.selectedIndex;
         if(param1 == 1)
         {
            if(_loc2_ >= mList.dataProvider.length - 1)
            {
               _loc2_ = 0;
            }
            else
            {
               _loc2_ += 1;
            }
         }
         else if(_loc2_ <= 0)
         {
            _loc2_ = mList.dataProvider.length - 1;
         }
         else
         {
            _loc2_ -= 1;
         }
         changeFun({"data":{"id":getNameByIndex(_loc2_)}});
      }
      
      public function getNameByIndex(param1:int) : String
      {
         for(var _loc2_:String in mFunCfg)
         {
            if(param1 == int(mFunCfg[_loc2_]))
            {
               return _loc2_;
            }
         }
         return "";
      }
      
      public function updateList() : void
      {
         if(mPanelCenterTaskAward) mPanelCenterTaskAward.update();
      }
      
      override public function setList() : void
      {
         var _loc3_:Number = NaN;
         var _loc2_:Object = null;
         var _loc1_:HorizontalLayout = null;
         this.delList();
         if(this.mList == null)
         {
            _loc3_ = 50;
            _loc2_ = {
               "paging":0,
               "gap":-10,
               "horizontalGap":0,
               "verticalGap":0,
               "paddingTop":0,
               "paddingRight":0,
               "paddingBottom":0,
               "paddingLeft":0,
               "horizontalAlign":"center",
               "verticalAlign":"bottom"
            };
            _loc1_ = new HorizontalLayout();
            _loc1_.gap = _loc2_.gap;
            _loc1_.paddingTop = _loc2_.paddingTop;
            _loc1_.paddingRight = _loc2_.paddingRight;
            _loc1_.paddingBottom = _loc2_.paddingBottom;
            _loc1_.paddingLeft = _loc2_.paddingLeft;
            _loc1_.horizontalAlign = _loc2_.horizontalAlign;
            _loc1_.verticalAlign = _loc2_.verticalAlign;
            _loc1_.hasVariableItemDimensions = false;
            this.mList = new List();
            this.mList.width = GlobalData.$mStageWidth - 95;
            this.mList.height = mListH = 140;
            this.mList.layout = _loc1_;
            this.mList.x = 40;
            this.mList.snapScrollPositionsToPixels = true;
            this.addChild(this.mList);
            _loc2_ = null;
            _loc1_ = null;
            mList.dataProvider = new ListCollection();
         }
      }
      
      override public function addList() : void
      {
         var _loc6_:int = 0;
         var _loc4_:int = 0;
         var _loc3_:Array = GlobalData.$mConfig_ploy_system_simple.fun_control as Array;
         _loc4_ = int(_loc3_.length);
         var _loc5_:Object = null;
         var _loc2_:Array = [];
         mFunCfg = {};
         var _loc1_:int = 0;
         _loc6_ = 0;
         for(; _loc6_ < _loc4_; _loc6_++)
         {
            if(_loc3_[_loc6_] == "rank")
            {
               if(checkClose_rank())
               {
                  continue;
               }
            }
            else if(_loc3_[_loc6_] == "gamble")
            {
               if(checkClose_gamble())
               {
                  continue;
               }
            }
            else if(_loc3_[_loc6_] == "rank_lv")
            {
               if(checkClose_rank_lv())
               {
                  continue;
               }
            }
            else if(_loc3_[_loc6_] == "roulette")
            {
               if(checkClose_roulette())
               {
                  continue;
               }
            }
            else if(_loc3_[_loc6_] == "fund")
            {
               if(checkClose_fund())
               {
                  continue;
               }
            }
            else if(_loc3_[_loc6_] == "time_pay")
            {
               if(checkClose_TimePay())
               {
                  continue;
               }
            }
            else if(_loc3_[_loc6_] == "welfare")
            {
               if(!checkClose_Welfare())
               {
                  continue;
               }
            }
            else if(_loc3_[_loc6_] == "morph")
            {
               if(!checkOpen_morph())
               {
                  continue;
               }
            }
            else if(_loc3_[_loc6_] == "spend_rank")
            {
               if(!checkOpen_spend_rank())
               {
                  continue;
               }
            }
            else if(_loc3_[_loc6_] == "groupon")
            {
               if(!checkClose_Group())
               {
                  continue;
               }
            }
            _loc5_ = {};
            _loc5_["id"] = _loc3_[_loc6_];
            mFunCfg[_loc3_[_loc6_]] = _loc1_;
            _loc5_["ui_texture"] = $fun_type[_loc3_[_loc6_]];
            _loc2_.push(_loc5_);
            _loc1_ += 1;
         }
         if(_loc2_.length > 0)
         {
            this.setListTimer(mList,_loc2_,ItemActivity,false);
         }
         changeFun($activityFunObj);
      }
      
      public function changeFun(param1:* = null) : void
      {
         var _loc2_:Object = param1 == null ? {"id":"task"} : param1.data;
         if(mList)
         {
            mList.selectedIndex = int(mFunCfg[_loc2_.id]);
            mList.scrollToDisplayIndex(mList.selectedIndex);
            setFunUIs(_loc2_.id);
         }
      }
      
      public function clearPanel() : void
      {
         GlobalData.$mEventDispatcher.removeEventListener("update_avatar_award",onMainEvent);
         GlobalData.$mEventDispatcher.removeEventListener("update_activity_rank_id",onMainEvent);
         GlobalData.$mEventDispatcher.removeEventListener("update_avatar_award_rank_lv",onMainEvent);
         if(mPanelCenterTaskAward)
         {
            StarlingTools.removeChildrenClear(mPanelCenterTaskAward);
            mPanelCenterTaskAward.removeFromParent(true);
         }
         if(mPanelActivityRank)
         {
            StarlingTools.removeChildrenClear(mPanelActivityRank);
            mPanelActivityRank.removeFromParent(true);
         }
         if(mPanelActivityGamble)
         {
            StarlingTools.removeChildrenClear(mPanelActivityGamble);
            mPanelActivityGamble.removeFromParent(true);
         }
         if(mPanelActivityRankLevel)
         {
            StarlingTools.removeChildrenClear(mPanelActivityRankLevel);
            mPanelActivityRankLevel.removeFromParent(true);
         }
         if(mPanelActivityRoulette)
         {
            StarlingTools.removeChildrenClear(mPanelActivityRoulette);
            mPanelActivityRoulette.removeFromParent(true);
         }
         if(mPanelActivityFund)
         {
            StarlingTools.removeChildrenClear(mPanelActivityFund);
            mPanelActivityFund.removeFromParent(true);
         }
         if(mPanelActivityMorph)
         {
            StarlingTools.removeChildrenClear(mPanelActivityMorph);
            mPanelActivityMorph.removeFromParent(true);
         }
         if(mPanelActivityMorphSelect)
         {
            StarlingTools.removeChildrenClear(mPanelActivityMorphSelect);
            mPanelActivityMorphSelect.removeFromParent(true);
         }
         if(mPanelActivityMorphUp)
         {
            StarlingTools.removeChildrenClear(mPanelActivityMorphUp);
            mPanelActivityMorphUp.removeFromParent(true);
         }
         if(mPanelActivitySpendRank)
         {
            StarlingTools.removeChildrenClear(mPanelActivitySpendRank);
            mPanelActivitySpendRank.removeFromParent(true);
         }
         if(mPanelActivityTimePay)
         {
            StarlingTools.removeChildrenClear(mPanelActivityTimePay);
            mPanelActivityTimePay.removeFromParent(true);
         }
         if(mPanelActivityWelfare)
         {
            StarlingTools.removeChildrenClear(mPanelActivityWelfare);
            mPanelActivityWelfare.removeFromParent(true);
         }
         if(mPanelActivityGroupBuy)
         {
            StarlingTools.removeChildrenClear(mPanelActivityGroupBuy);
            mPanelActivityGroupBuy.removeFromParent(true);
         }
         if(mPanelActivityTimeExtraction)
         {
            StarlingTools.removeChildrenClear(mPanelActivityTimeExtraction);
            mPanelActivityTimeExtraction.removeFromParent(true);
         }
         mPanelCenterTaskAward = null;
         mPanelActivityRank = null;
         mPanelActivityGamble = null;
         mPanelActivityRankLevel = null;
         mPanelActivityRoulette = null;
         mPanelActivityFund = null;
         mPanelActivityMorph = null;
         mPanelActivityMorphSelect = null;
         mPanelActivityMorphUp = null;
         mPanelActivitySpendRank = null;
         mPanelActivityTimePay = null;
         mPanelActivityWelfare = null;
         mPanelActivityGroupBuy = null;
         mPanelActivityTimeExtraction = null;
      }
      
      public function setFunUIs(param1:String) : void
      {
         var _loc2_:Number = NaN;
         _loc2_ = 140;
         clearPanel();
         mCurr_funID = param1;
         if(param1 == "time_pay")
         {
            mPanelActivityTimePay = new PanelActivityTimePay();
            mPanelActivityTimePay.y = 140;
            addChildAt(mPanelActivityTimePay,0);
         }
         if(param1.indexOf("morph") < 0)
         {
            GlobalFunction.clearMorphItems();
         }
         if(param1 == "task")
         {
            mPanelCenterTaskAward = new PanelCenterTaskAward();
            mPanelCenterTaskAward.y = 140;
            GlobalData.$mEventDispatcher.addEventListener("update_avatar_award",onMainEvent);
            addChildAt(mPanelCenterTaskAward,0);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_avatar_award");
         }
         else if(param1 == "rank")
         {
            mPanelActivityRank = new PanelActivityRank();
            mPanelActivityRank.y = 140;
            GlobalData.$mEventDispatcher.addEventListener("update_activity_rank_id",onMainEvent);
            addChildAt(mPanelActivityRank,0);
         }
         else if(param1 == "gamble")
         {
            mPanelActivityGamble = new PanelActivityGamble();
            addChildAt(mPanelActivityGamble,0);
         }
         else if(param1 == "rank_lv")
         {
            mPanelActivityRankLevel = new PanelActivityRankLevel();
            mPanelActivityRankLevel.y = 140;
            GlobalData.$mEventDispatcher.addEventListener("update_avatar_award_rank_lv",onMainEvent);
            addChildAt(mPanelActivityRankLevel,0);
         }
         else if(param1 == "roulette")
         {
            mPanelActivityRoulette = new PanelActivityRoulette();
            addChildAt(mPanelActivityRoulette,0);
         }
         else if(param1 == "fund")
         {
            mPanelActivityFund = new PanelActivityFund();
            addChildAt(mPanelActivityFund,0);
         }
         else if(param1 == "morph")
         {
            if(this.mList)
            {
               this.mList.visible = true;
            }
            if(mBg_right)
            {
               mBg_right.visible = true;
            }
            if(mBg_left)
            {
               mBg_left.visible = true;
            }
            mPanelActivityMorph = new PanelActivityMorph();
            addChildAt(mPanelActivityMorph,0);
         }
         else if(param1 == "morph_select")
         {
            if(this.mList)
            {
               this.mList.visible = false;
            }
            if(mBg_right)
            {
               mBg_right.visible = false;
            }
            if(mBg_left)
            {
               mBg_left.visible = false;
            }
            mPanelActivityMorphSelect = new PanelActivityMorphSelect();
            addChildAt(mPanelActivityMorphSelect,0);
         }
         else if(param1 == "morph_up")
         {
            if(this.mList)
            {
               this.mList.visible = false;
            }
            if(mBg_right)
            {
               mBg_right.visible = false;
            }
            if(mBg_left)
            {
               mBg_left.visible = false;
            }
            mPanelActivityMorphUp = new PanelActivityMorphUp();
            addChildAt(mPanelActivityMorphUp,0);
         }
         else if(param1 == "spend_rank")
         {
            mPanelActivitySpendRank = new PanelActivitySpendRank();
            addChildAt(mPanelActivitySpendRank,0);
         }
         else if(param1 == "welfare")
         {
            mPanelActivityWelfare = new PanelActivityWelfare();
            mPanelActivityWelfare.y = 140;
            addChildAt(mPanelActivityWelfare,0);
         }
         else if(param1 == "groupon")
         {
            mPanelActivityGroupBuy = new PanelActivityGroupBuy();
            mPanelActivityGroupBuy.y = 140;
            addChildAt(mPanelActivityGroupBuy,0);
         }
      }
      
      override public function onBTN_NAME_BACK() : void
      {
         if(mCurr_funID == "morph_select")
         {
            GlobalFunction.clearMorphItems();
            setFunUIs("morph");
         }
         else if(mCurr_funID == "morph_up")
         {
            if(GlobalData.$tempMorphItem)
            {
               GlobalFunction.clearMorphItems();
               setFunUIs("morph_select");
            }
            else
            {
               $activityFunObj = GlobalFunction.getActivityFun("task");
               updateList();
               if(this.mList)
               {
                  this.mList.visible = true;
               }
               if(mBg_right)
               {
                  mBg_right.visible = true;
               }
               if(mBg_left)
               {
                  mBg_left.visible = true;
               }
            }
         }
         else
         {
            super.onBTN_NAME_BACK();
         }
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalFunction.clearExpeditionItems();
         GlobalFunction.clearMorphItems();
         GlobalData.$mEventDispatcher.removeEventListener("update_game_activity_fun",changeFun);
         mCurr_funID = "";
         if(mBg_left)
         {
            mBg_left.removeFromParent(true);
         }
         if(mBg_right)
         {
            mBg_right.removeFromParent(true);
         }
         clearPanel();
         super.onREMOVED_FROM_STAGE(param1);
         mFunCfg = null;
         mBg_left = null;
         mBg_right = null;
      }
      
      private function onMainEvent(param1:Event) : void
      {
         if(param1.type == "update_avatar_award")
         {
            if(mPanelCenterTaskAward)
            {
               mPanelCenterTaskAward.update();
            }
         }
         else if(param1.type == "update_activity_rank_id")
         {
            PanelActivityRankList.$rankDataInfo = param1.data.info;
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_activity_rank_list",false,true);
         }
         else if(param1.type == "update_avatar_award_rank_lv")
         {
            if(mPanelActivityRankLevel)
            {
               mPanelActivityRankLevel.update();
            }
         }
      }
      
      private function checkClose_rank_lv() : Boolean
      {
         var _loc4_:Boolean = false;
         var _loc1_:Object = GlobalData.$mConfig_ploy_system_simple.rank_lv;
         var _loc3_:Number = SendAndSelect.$systemTimer_nowSecond * 1000;
         var _loc2_:Number = (GlobalData.$userData.add_time as Date).time + _loc1_.end_time * 24 * 60 * 60 * 1000 + 3600000;
         if(_loc3_ >= _loc2_)
         {
            _loc4_ = true;
         }
         return _loc4_;
      }
      
      private function checkClose_TimePay() : Boolean
      {
         var _loc3_:Boolean = false;
         var _loc1_:Object = GlobalData.$mConfig.task.time_pay;
         var _loc2_:Number = SendAndSelect.$systemTimer_nowSecond;
         var _loc4_:int = (_loc1_.begin_time as Date).time * 0.001;
         var _loc5_:int = (_loc1_.end_time as Date).time * 0.001;
         if(_loc2_ < _loc4_ || _loc2_ >= _loc5_)
         {
            _loc3_ = true;
         }
         return _loc3_;
      }
      
      private function checkClose_Group() : Boolean
      {
         var _loc4_:Boolean = false;
         var _loc2_:Object = GlobalData.$mConfig_ploy_system_simple.groupon;
         var _loc1_:Number = (_loc2_.start_time as Date).time;
         var _loc5_:Number = (_loc2_.end_time as Date).time;
         var _loc7_:Number = _loc1_ + _loc2_.duration * 1000 * 60;
         var _loc3_:Number = SendAndSelect.$systemTimer_nowSecond * 1000;
         var _loc6_:int = int(_loc2_.start_lv);
         if(_loc3_ < _loc1_)
         {
            return false;
         }
         if(_loc3_ < _loc7_ && _loc3_ > _loc1_ && GlobalData.$userData.lv >= _loc6_)
         {
            _loc4_ = true;
         }
         else if(GlobalData.$userData.attrs.groupon != null)
         {
            if(GlobalData.$userData.attrs.groupon[1] == 1)
            {
               _loc4_ = true;
            }
            else
            {
               _loc4_ = false;
            }
         }
         else
         {
            _loc4_ = false;
         }
         if(_loc3_ >= _loc5_)
         {
            _loc4_ = false;
            SendServiceAMFFun.send_user_groupon_close(reService);
         }
         return _loc4_;
      }
      
      private function reService(param1:Object) : void
      {
         if(stage == null)
         {
            return;
         }
         var _loc2_:Object = null;
         if(param1.data)
         {
            _loc2_ = param1.data;
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.groupon[1] = _loc2_;
            }
         }
      }
      
      private function checkClose_extract_avatar() : Boolean
      {
         var _loc4_:Boolean = false;
         var _loc2_:Object = GlobalData.$mConfig_ploy_system_simple.extract_avatar;
         var _loc1_:Number = (_loc2_.start_time as Date).time;
         var _loc5_:Number = (_loc2_.end_time as Date).time;
         var _loc7_:Number = _loc1_ + _loc2_.duration * 1000 * 60;
         var _loc3_:Number = SendAndSelect.$systemTimer_nowSecond * 1000;
         var _loc6_:int = int(_loc2_.start_lv);
         if(_loc3_ < _loc7_ && _loc3_ > _loc1_ && GlobalData.$userData.lv >= _loc6_)
         {
            _loc4_ = true;
         }
         else if(GlobalData.$userData.attrs.groupon != null)
         {
            if(GlobalData.$userData.attrs.groupon[1] == 1)
            {
               _loc4_ = true;
            }
            else
            {
               _loc4_ = false;
            }
         }
         else
         {
            _loc4_ = false;
         }
         if(_loc3_ >= _loc5_)
         {
            _loc4_ = false;
            SendServiceAMFFun.send_user_groupon_close(reService);
         }
         return _loc4_;
      }
      
      private function checkClose_Welfare() : Boolean
      {
         var _loc7_:Boolean = false;
         var _loc3_:Object = GlobalData.$mConfig.ploy_system_simple.welfare;
         var _loc5_:Number = SendAndSelect.$systemTimer_nowSecond;
         var _loc8_:int = (_loc3_.start_time as Date).time * 0.001;
         var _loc9_:int = (_loc3_.end_time as Date).time * 0.001;
         var _loc2_:int = _loc3_.duration * 60;
         var _loc6_:int = int(_loc3_.start_lv[0]);
         var _loc1_:int = int(_loc3_.start_lv[1]);
         var _loc4_:Object = GlobalData.$userData;
         if(_loc5_ > _loc8_ && _loc5_ <= _loc9_ && (_loc6_ <= GlobalData.$userData.lv || _loc1_ <= GlobalData.$userData.vip_lv))
         {
            _loc7_ = true;
         }
         return _loc7_;
      }
      
      private function checkClose_gamble() : Boolean
      {
         var _loc5_:Boolean = false;
         var _loc1_:Object = GlobalData.$mConfig_ploy_system_simple.gamble;
         var _loc3_:Number = (GlobalData.$userData.add_time as Date).time;
         var _loc2_:Number = _loc3_ + _loc1_.days * 24 * 60 * 60 * 1000;
         var _loc4_:Number = SendAndSelect.$systemTimer_nowSecond * 1000;
         if(_loc4_ > _loc2_)
         {
            _loc5_ = true;
         }
         return _loc5_;
      }
      
      private function checkClose_rank() : Boolean
      {
         var _loc3_:Boolean = false;
         var _loc5_:String = SendAndSelect.$serviceId;
         var _loc7_:Object = GlobalData.$mConfig_zones;
         var _loc11_:Array = _loc7_[_loc5_];
         var _loc2_:Number = (_loc11_[1] as Date).time;
         var _loc4_:Number = SendAndSelect.$systemTimer_nowSecond * 1000 + GlobalConfig.HOURS_8_MS;
         var _loc9_:Number = (GlobalData.$userData.add_time as Date).time + GlobalConfig.HOURS_8_MS;
         var _loc1_:int = int(GlobalData.$mConfig_ploy_system_simple.rank.rank_end);
         var _loc8_:int = (GlobalData.$mConfig_ploy_system_simple.rank.gift.rank_sort as Array).length + 1;
         var _loc6_:Number = 86400000;
         var _loc13_:Date = new Date();
         _loc13_.setTime(_loc2_);
         var _loc10_:Date = new Date(_loc13_.fullYear,_loc13_.month,_loc13_.date,0);
         var _loc12_:Number = _loc10_.time;
         if(_loc4_ > _loc12_ + _loc6_ * _loc1_ - 1000 || _loc9_ > _loc12_ + _loc6_ * _loc8_ - 1000)
         {
            _loc3_ = true;
         }
         return _loc3_;
      }
      
      private function checkClose_fund() : Boolean
      {
         var _loc1_:Object = PanelActivityFund.checkStatus();
         return _loc1_.status < 0 || _loc1_.status == 2 && GlobalData.$userData.attrs.fund.money < GlobalData.$mConfig_ploy_system_simple.fund["return"][0];
      }
      
      private function checkClose_roulette() : Boolean
      {
         var _loc5_:Boolean = false;
         var _loc1_:Object = GlobalData.$mConfig_ploy_system_simple.roulette;
         var _loc4_:Number = (_loc1_.start_time as Date).time;
         var _loc2_:Number = (_loc1_.end_time as Date).time;
         var _loc3_:Number = SendAndSelect.$systemTimer_nowSecond * 1000;
         if(_loc3_ < _loc4_ || _loc3_ > _loc2_ || GlobalData.$userData.lv < _loc1_.start_lv)
         {
            _loc5_ = true;
         }
         return _loc5_;
      }
      
      private function checkOpen_morph() : Boolean
      {
         return GlobalFunction.checkMorph() >= 0;
      }
      
      private function checkOpen_spend_rank() : Boolean
      {
         var _loc5_:Boolean = false;
         var _loc2_:Object = GlobalData.$mConfig_ploy_system_simple.spend_rank;
         var _loc1_:Number = (_loc2_.start_time as Date).time;
         var _loc4_:Number = (_loc2_.end_time as Date).time;
         var _loc6_:Number = SendAndSelect.$systemTimer_nowSecond * 1000;
         var _loc3_:Boolean = GlobalData.$userData.lv >= _loc2_.start_lv[0] || GlobalData.$userData.vip_lv >= _loc2_.start_lv[1];
         if(_loc6_ >= _loc1_ && _loc6_ < _loc4_ && _loc3_)
         {
            _loc5_ = true;
         }
         return _loc5_;
      }
   }
}

