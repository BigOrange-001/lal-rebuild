package com.meng52.game.ui.screen
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.module.map.GameMap;
   import com.meng52.game.ui.element.ItemFragment;
   import com.meng52.game.ui.element.ItemPVP;
   import com.meng52.game.ui.element.ItemPVPMsg;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.panel.PanelChip;
   import com.meng52.game.ui.panel.PanelPVP15;
   import com.meng52.game.ui.panel.PanelPopPVPup;
   import com.meng52.game.ui.stage.GuideTools;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.net.RpcStaticCall;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.data.ListCollection;
   import feathers.display.Scale3Image;
   import feathers.display.Scale9Image;
   import feathers.layout.VerticalLayout;
   import feathers.textures.Scale9Textures;
   import flash.events.TimerEvent;
   import flash.geom.Rectangle;
   import flash.utils.Timer;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   
   public class PanelCenterPVP extends PanelCenterMainAvatar
   {
      
      public static var $tabBarSelectedIndex:int = 0;
      
      public var mBg_list:Scale9Image;
      
      public var mBg_number:Image;
      
      public var mTxt_pkTimes:TextField;
      
      public var mBtn_re:LOL_Scale9Button;
      
      public var mPVP_list:Array;
      
      public var mRefresh_s:Number = 0;
      
      public var mSelfID:int = 0;
      
      public var mFun_status:Boolean = false;
      
      private var mMailListArr:Array;
      
      private var mBox_info:Sprite;
      
      private var mBg_msg:Image;
      
      private var mBg_mask:Image;
      
      private var mMC_times:Number = 0;
      
      private var _isapply:Boolean = false;
      
      private var mStatus:int;
      
      private var updateTimer:Timer;
      
      private var _currPhase:Object;
      
      public var mImg_head:Image;
      
      public var mImg_right:Image;
      
      public var mImg_left:Image;
      
      public var mImg3_info:Scale3Image;
      
      public var recMsg:Boolean = true;
      
      private var _panelChip:PanelChip;
      
      private var _txt_coin:LOL_MutilTextFieldIcon;
      
      private var _show_id:String;
      
      private var headImg:Image;
      
      private var pvpRule:LOL_Scale9Button;
      
      private var _panel15:PanelPVP15;
      
      private var mBox_elite:Sprite;
      
      private var mBox_elite_bg:Image;
      
      private var gamerule:LOL_Button;
      
      private var battlegroup:LOL_Button;
      
      private var winS:Image;
      
      private var bottom_bg:Scale9Image;
      
      private var txt_time_infor:TextField;
      
      private var first_time_txt:TextField;
      
      private var second_time_txt:TextField;
      
      private var awardBtn:LOL_Scale9Button;
      
      private var blessBtn:LOL_Scale9Button;
      
      private var battleinfoBtn:LOL_Scale9Button;
      
      private var mTag_a:Sprite;
      
      private const AWARD_BTN:String = "awardBtn";
      
      private const BLESS_BTN:String = "blessBtn";
      
      private const APPLY_BTN:String = "applyBtn";
      
      private const BATTLEINFO_BTN:String = "battleinfoBtn";
      
      private const BATTLEGROUP:String = "battlegroup";
      
      private const GAMERULE:String = "gamerule";
      
      private var txt_extreme_info:TextFieldHtmlRenderer;
      
      private var first_status:Boolean = false;
      
      private var second_status:Boolean = false;
      
      private var user_arr:Array;
      
      private var term_txt:TextField;
      
      private var _spRule:Sprite;
      
      private var _spRule1:Sprite;
      
      private var mark:Object;
      
      public function PanelCenterPVP()
      {
         super();
      }
      
      public function checkGuide() : void
      {
         GuideMaster.getOnlyExample().skipGuide();
         GuideMaster.getOnlyExample().checkGuide("M5_1",checkGuide);
         if(GuideTools.checkShouldPVP())
         {
            LayoutUIAnimation.getOnlyExample().addArrowhead(550,674,100);
         }
         else
         {
            LayoutUIAnimation.getOnlyExample().clearIfNoGuide();
         }
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalData.$mStarling.juggler.removeTweens(this);
         delPVPList();
         delPVP_elite();
         delTimer_Extreme();
         delPVP_BattleOfThePeak();
         GlobalData.$mEventDispatcher.removeEventListener("update_signup",afterSignUpdate);
         GlobalData.$mEventDispatcher.removeEventListener("update_pvpelite_updateaward",update_tag);
         GlobalData.$mStarling.juggler.removeTweens(mTag_a);
         super.onREMOVED_FROM_STAGE(param1);
         GlobalFunction.delTextureByBD("UI_pvp_bg_0_");
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         GlobalData.$mEventDispatcher.addEventListener("update_signup",afterSignUpdate);
         GlobalData.$mEventDispatcher.addEventListener("update_pvpelite_updateaward",update_tag);
         mImg_head = getImg_headBg(-60);
         addChild(mImg_head);
         mFun_status = false;
         setTabBar([{
            "label":GlobalLanguageStr.getLanguageStr(20347),
            "indexID":0
         },{
            "label":GlobalLanguageStr.getLanguageStr(20277),
            "indexID":1
         },{
            "label":GlobalLanguageStr.getLanguageStr(20278),
            "indexID":2
         },{
            "label":GlobalLanguageStr.getLanguageStr(96557),
            "indexID":3
         }],tabBar_changeHandler,tabBar_CREATION_COMPLETE,MainConfig.$isEnglish ? 155 : 135,55);
         mTabBar.y = 20;
         if(GlobalFunction.check_panelIDsort(["stage_game","center_pvp"]) && GameMap.isLoadFile)
         {
            mFun_status = true;
         }
         mMC_times = 0;
         mImg3_info = getImg3_info();
         mImg3_info.y = mTabBar.y + 55;
         mImg3_info.height = 38;
         addChild(mImg3_info);
      }
      
      override public function tabBar_CREATION_COMPLETE(param1:*) : void
      {
         var _loc6_:Array = GlobalData.$mConfig_simple.wild_area as Array;
         var _loc5_:int = GlobalFunction.checkGameFunIsOpenByType("center_pvp_fragment");
         if(_loc5_ > -1)
         {
            mTabBar.setChildStatus(0,false,tabBar_changeHandler_false);
         }
         var _loc4_:int = GlobalFunction.checkGameFunIsOpenByType("center_pvp");
         if(_loc4_ > -1)
         {
            mTabBar.setChildStatus(1,false,tabBar_changeHandler_false);
         }
         var _loc9_:int = int(GlobalData.$mConfig_simple.extreme.open_status);
         var _loc8_:int = GlobalFunction.checkGameFunIsOpenByType("center_pvp_embattle");
         if(_loc9_ == 0 || _loc8_ > -1)
         {
            mTabBar.setChildStatus(2,false,tabBar_changeHandler_false);
         }
         var _loc11_:int = GlobalFunction.checkGameFunIsOpenByType("status_pvp_fifteen");
         var _loc7_:Object = GlobalData.$mConfig_simple != null ? GlobalData.$mConfig_simple["cross_pvp"] : null;
         var _loc3_:int = _loc7_ != null ? int(_loc7_["open_status"]) : 0;
         var _loc10_:Number = NaN;
         var _loc2_:Date = null;
         var _crossSchedule:Array = _loc7_ != null ? _loc7_["cross_server_pvp"] as Array : null;
         if(_loc7_ == null || (_loc3_ != 0 && (_crossSchedule == null || _crossSchedule.length < 5 || !(_crossSchedule[2] is Date))))
         {
            reportCrossPvpConfigState("tabBar_CREATION_COMPLETE",_loc7_,_crossSchedule);
            mTabBar.setChildStatus(3,false,tabBar_changeHandler_false);
         }
         else if(_loc3_ == 0 || _loc11_ > -1)
         {
            mTabBar.setChildStatus(3,false,tabBar_changeHandler_false);
         }
         else
         {
            _loc10_ = 86400 * Number(_crossSchedule[3]);
            _loc2_ = _crossSchedule[2] as Date;
            if(_loc10_ > 0 && _loc10_ - (SendAndSelect.$systemTimer_nowSecond - _loc2_.time / 1000) % _loc10_ < Number(_crossSchedule[4]) * 60 * 60)
            {
               mTabBar.setChildStatus(3,false,tabBar_changeHandler_false_clear);
            }
         }
         if(_loc3_ == 0 && $tabBarSelectedIndex == 3)
         {
            $tabBarSelectedIndex = 0;
         }
         if(this.mTabBar.selectedIndex == $tabBarSelectedIndex)
         {
            update();
         }
         else
         {
            if(_loc3_ != 0 && _loc7_ != null && _crossSchedule != null && _crossSchedule.length >= 5 && _crossSchedule[2] is Date && _loc10_ > 0 && _loc10_ - (SendAndSelect.$systemTimer_nowSecond - _loc2_.time / 1000) % _loc10_ < Number(_crossSchedule[4]) * 60 * 60 && $tabBarSelectedIndex == 3)
            {
               $tabBarSelectedIndex = 0;
            }
            this.mTabBar.selectedIndex = $tabBarSelectedIndex;
         }
      }
      
      public function tabBar_changeHandler_false_clear(param1:int) : void
      {
         GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(98053),false);
      }
      
      override public function tabBar_changeHandler_false(param1:int) : void
      {
         var _loc5_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc7_:int = 0;
         var _loc6_:int = 0;
         var _loc2_:int = 0;
         var _loc8_:int = 0;
         if(mTabBar)
         {
            if(param1 == 0)
            {
               _loc3_ = _loc5_ = GlobalFunction.checkGameFunIsOpenByType("center_pvp_fragment");
               if(_loc3_ < 0)
               {
                  mTabBar.selectedIndex = 0;
               }
               else
               {
                  _show_id = GlobalData.$mConfig_simple.show_id[8];
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90129,_loc3_),false,_show_id);
               }
            }
            if(param1 == 1)
            {
               _loc4_ = GlobalFunction.checkGameFunIsOpenByType("center_pvp");
               if(_loc4_ > -1)
               {
                  _show_id = GlobalData.$mConfig_simple.show_id[8];
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90129,_loc4_),false,_show_id);
               }
            }
            if(param1 == 2)
            {
               _loc7_ = int(GlobalData.$mConfig_simple.extreme.open_status);
               _loc6_ = GlobalFunction.checkGameFunIsOpenByType("center_pvp_embattle");
               if(_loc7_ == 0)
               {
                  _show_id = GlobalData.$mConfig_simple.show_id[8];
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90046),false,_show_id);
               }
               else if(_loc6_ > -1)
               {
                  _show_id = GlobalData.$mConfig_simple.show_id[8];
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90129,_loc6_),false,_show_id);
               }
            }
            if(param1 == 3)
            {
               var crossCfg:Object = GlobalData.$mConfig_simple != null ? GlobalData.$mConfig_simple["cross_pvp"] : null;
               _loc2_ = crossCfg != null ? int(crossCfg["open_status"]) : 0;
               _loc8_ = GlobalFunction.checkGameFunIsOpenByType("status_pvp_fifteen");
               if(crossCfg == null)
               {
                  reportCrossPvpConfigState("tabBar_changeHandler_false",crossCfg,null);
                  GlobalFunction.popError("跨服巅峰配置暂不可用；本地竞技与碎片争夺可以继续游玩。",false);
               }
               else if(_loc2_ == 0)
               {
                  _show_id = GlobalData.$mConfig_simple.show_id[8];
                  GlobalFunction.popError("跨服巅峰当前未开放；本地竞技与碎片争夺可以继续游玩。",false);
               }
               else if(_loc8_ > -1)
               {
                  _show_id = GlobalData.$mConfig_simple.show_id[8];
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90129,_loc8_),false,_show_id);
               }
            }
         }
      }
      
      override public function update() : void
      {
         $tabBarSelectedIndex = this.mTabBar.selectedIndex;
         LayoutUIAnimation.getOnlyExample().clear();
         if(this.mTabBar.selectedIndex == 0)
         {
            delPVPList();
            delPVP_elite();
            delPVP_fragment();
            delPVP_BattleOfThePeak();
            setPVP_fragment();
         }
         if(this.mTabBar.selectedIndex == 1)
         {
            delPVPList();
            delPVP_elite();
            delPVP_fragment();
            delPVP_BattleOfThePeak();
            setPVPList();
         }
         else if(this.mTabBar.selectedIndex == 2)
         {
            delPVPList();
            delPVP_elite();
            delPVP_fragment();
            delPVP_BattleOfThePeak();
            startTimer_Extreme();
            startPVPExtreme();
         }
         else if(this.mTabBar.selectedIndex == 3)
         {
            if(_panel15 == null)
            {
               delPVPList();
               delPVP_elite();
               delPVP_fragment();
               delPVP_BattleOfThePeak();
               setPVP_BattleOfThePeak();
            }
         }
      }
      
      private function delPVP_BattleOfThePeak() : void
      {
         if(_panel15)
         {
            _panel15.removeFromParent(true);
            _panel15.dispose();
         }
         _panel15 = null;
      }
      
      private function setPVP_BattleOfThePeak() : void
      {
         var _loc2_:Object = GlobalData.$mConfig_simple != null ? GlobalData.$mConfig_simple["cross_pvp"] : null;
         var _loc4_:Array = _loc2_ != null ? _loc2_["cross_server_pvp"] as Array : null;
         if(_loc2_ == null || int(_loc2_["open_status"]) == 0)
         {
            reportCrossPvpConfigState("setPVP_BattleOfThePeak_closed",_loc2_,_loc4_);
            GlobalFunction.popError("跨服巅峰当前未开放；本地竞技与碎片争夺可以继续游玩。",false);
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_main");
            return;
         }
         if(_loc4_ == null || _loc4_.length < 5 || !(_loc4_[2] is Date) || Number(_loc4_[3]) <= 0)
         {
            reportCrossPvpConfigState("setPVP_BattleOfThePeak_invalid",_loc2_,_loc4_);
            GlobalFunction.popError("跨服巅峰赛程数据暂不可用，请返回后重试。",false);
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_main");
            return;
         }
         var _loc3_:Number = 86400 * Number(_loc4_[3]);
         var _loc1_:Date = _loc4_[2] as Date;
         if(_loc3_ - (SendAndSelect.$systemTimer_nowSecond - _loc1_.time / 1000) % _loc3_ < _loc2_.cross_server_pvp[4] * 60 * 60)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(98053),false);
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_main");
            return;
         }
         _panel15 = new PanelPVP15();
         this.addChildAt(_panel15,0);
      }

      private function reportCrossPvpConfigState(site:String, cross:Object, schedule:Array) : void
      {
         var simple:Object = GlobalData.$mConfig_simple;
         var pvpConfig:* = simple != null ? simple["pvp_config"] : null;
         var pvpMark:* = simple != null ? simple["pvp_get_mark"] : null;
         if(RpcStaticCall.$remoting != null)
         {
            RpcStaticCall.$remoting.reportDiagnostic("PVP_CROSS_CONFIG site=" + site + " cfg_version=" + SendAndSelect.$cfgVersion + " page=PanelCenterPVP:" + $tabBarSelectedIndex + " simple=" + (simple != null) + " pvp_config=" + String(pvpConfig) + " pvp_get_mark=" + String(pvpMark) + " cross_open_status=" + (cross != null ? String(cross["open_status"]) : "missing") + " cross_schedule=" + (schedule != null ? String(schedule) : "missing") + " cross_start=" + (schedule != null && schedule.length > 2 ? String(schedule[2]) : "missing") + " cross_period=" + (schedule != null && schedule.length > 3 ? String(schedule[3]) : "missing") + " cross_window=" + (schedule != null && schedule.length > 4 ? String(schedule[4]) : "missing"));
         }
      }
      
      private function afterSignUpdate(param1:Event) : void
      {
         if(battleinfoBtn)
         {
            battleinfoBtn.text = GlobalLanguageStr.getStr(90369);
            battleinfoBtn.clearGlow();
         }
      }
      
      private function startPVPExtreme() : void
      {
         var _fun:* = function(param1:Object):void
         {
            GlobalData.$useExtreme = param1.data;
            if(param1.data.phase != "signup")
            {
               GlobalData.$mEventDispatcher.dispatchEventWith("update_timer");
            }
            var _loc2_:Object = GlobalFunction.getExtremeTime();
            if(param1.data.status == 0 && param1.data.grant_data == null)
            {
               mStatus = 0;
            }
            else if(param1.data.status == 0 && param1.data.grant_data != null)
            {
               mStatus = 1;
            }
            else if(param1.data.status > 0 && param1.data.grant_data == null)
            {
               mStatus = 2;
            }
            else if(param1.data.status > 0 && param1.data.grant_data != null)
            {
               mStatus = 3;
            }
            if(GlobalFunction.getExtremeTime().time == GlobalData.$useExtreme.phase)
            {
               setPVP_elite();
            }
            recMsg = true;
         };
         recMsg = false;
         SendServiceAMFFun.send_user_get_my_extreme(_fun);
      }
      
      private function isJoinGame() : Object
      {
         var _loc1_:Object = {};
         if(GlobalData.$useExtreme.status == 1)
         {
            _loc1_.isF = true;
         }
         else
         {
            _loc1_.isF = false;
         }
         if(GlobalData.$useExtreme.grant_data == null)
         {
            _loc1_.isBless = false;
         }
         else
         {
            _loc1_.isBless = true;
         }
         return _loc1_;
      }
      
      private function startTimer_Extreme() : void
      {
         delTimer_Extreme();
         updateTimer = new Timer(1000);
         updateTimer.addEventListener("timer",onTimerHandler);
         updateTimer.start();
      }
      
      private function delTimer_Extreme() : void
      {
         if(updateTimer)
         {
            updateTimer.stop();
            if(updateTimer.hasEventListener("timer"))
            {
               updateTimer.removeEventListener("timer",onTimerHandler);
            }
         }
         updateTimer = null;
         _currPhase = {};
      }
      
      protected function onTimerHandler(param1:TimerEvent) : void
      {
         if(recMsg)
         {
            _currPhase = GlobalFunction.getExtremeTime();
            if(GlobalData.$useExtreme.phase != "battle")
            {
            }
            if(GlobalData.$useExtreme.phase != _currPhase.time)
            {
               if(GlobalData.$useExtreme.phase == "grant" && _currPhase.time == "signup")
               {
                  GlobalData.$mGameClassObject.closePopForPanel();
               }
               delPVP_elite();
               startPVPExtreme();
            }
            else if(GlobalData.$useExtreme.phase == "battle" && GlobalFunction.getExtremeTime().time == "battle" && GlobalData.$useExtreme.phase_data[0] != GlobalFunction.getExtremeTime().timeNum)
            {
               delPVP_elite();
               startPVPExtreme();
            }
            chechToBlessTime();
         }
      }
      
      override public function tabBar_changeHandler(param1:Event) : void
      {
         var _loc7_:int = 0;
         var _loc6_:int = 0;
         var _loc5_:int = 0;
         var _loc3_:int = 0;
         var _loc2_:int = 0;
         var _loc4_:Boolean = false;
         if(mTabBar)
         {
            if(this.mTabBar.selectedIndex == 0)
            {
               _loc7_ = GlobalFunction.checkGameFunIsOpenByType("center_pvp_fragment");
               _loc6_ = GlobalFunction.checkGameFunIsOpenByType("center_boss");
               _loc5_ = Math.min(_loc7_,_loc6_);
               if(_loc5_ > 0)
               {
                  _show_id = GlobalData.$mConfig_simple.show_id[8];
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90129,_loc5_),false,_show_id);
               }
               else
               {
                  _loc4_ = true;
               }
            }
            if(this.mTabBar.selectedIndex == 1)
            {
               delTimer_Extreme();
               _loc3_ = GlobalFunction.checkGameFunIsOpenByType("center_pvp");
               if(_loc3_ != -1)
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90129,_loc3_),false,"A_1201_6");
               }
               else
               {
                  _loc4_ = true;
               }
            }
            else if(this.mTabBar.selectedIndex == 2)
            {
               _loc2_ = GlobalFunction.checkGameFunIsOpenByType("center_pvp_embattle");
               if(GlobalData.$mConfig_simple.extreme.open_status == 0)
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90046),false,"A_1053_6");
               }
               else if(_loc2_ != -1)
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90129,_loc2_),false,"A_1053_6");
               }
               else
               {
                  _loc4_ = true;
               }
            }
            else if(this.mTabBar.selectedIndex == 3)
            {
               delTimer_Extreme();
               if(int(GlobalData.$mConfig_simple.cross_pvp.open_status) == 0)
               {
                  $tabBarSelectedIndex = 0;
                  this.mTabBar.selectedIndex = 0;
                  GlobalFunction.popError("跨服巅峰暂未接入本地重构版本；本地NPC竞技与碎片争夺可正常游玩。",false);
               }
               else
               {
                  _loc4_ = true;
               }
            }
            if(_loc4_)
            {
               update();
            }
         }
      }
      
      private function delPVPList() : void
      {
         if(mBox_info)
         {
            if(mBox_info.isFlattened)
            {
               mBox_info.unflatten();
            }
            StarlingTools.removeChildrenClear(mBox_info);
            mBox_info.removeFromParent(true);
         }
         if(mTxt_pkTimes)
         {
            mTxt_pkTimes.removeFromParent(true);
            mTxt_pkTimes.dispose();
         }
         if(_txt_coin)
         {
            _txt_coin.removeFromParent(true);
            _txt_coin.dispose();
         }
         if(mBtn_re)
         {
            mBtn_re.removeFromParent(true);
         }
         if(mBg_list)
         {
            mBg_list.removeFromParent(true);
         }
         if(mBg_number)
         {
            mBg_number.removeFromParent(true);
         }
         if(headImg)
         {
            headImg.removeFromParent(true);
         }
         if(pvpRule)
         {
            pvpRule.removeFromParent(true);
         }
         mBox_info = null;
         mPVP_list = null;
         mTxt_pkTimes = null;
         _txt_coin = null;
         mBtn_re = null;
         mBg_list = null;
         mBg_number = null;
         headImg = null;
         pvpRule = null;
         this.delList();
      }
      
      private function setPVPList() : void
      {
         this.mBox_info = new Sprite();
         mBg_list = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",618,GlobalData.$mStageHeight - 110 - 121,new Rectangle(110,55,70,20));
         mBg_list.x = int((GlobalData.$mStageWidth - mBg_list.width) * 0.5);
         mBg_list.y = 193;
         addChild(mBg_list);
         addChild(this.mBox_info);
         headImg = GlobalFunction.createImage("UI_help_style_0_0000");
         headImg.x = mBg_list.x + 85;
         headImg.y = mBg_list.y + 15;
         addChild(headImg);
         pvpRule = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(97061),150,70,"UI_btn_normalFun_0000");
         pvpRule.fontSize = 20;
         pvpRule.x = mBg_list.x + mBg_list.width - pvpRule.width - 150;
         pvpRule.y = mBg_list.y - 50 - 20;
         addChild(pvpRule);
         pvpRule.addEventListener("triggered",pvpRuleTriggered);
         if(mTabBar)
         {
            if(this.mTabBar.selectedIndex == 0)
            {
               pvpRule.visible = false;
            }
            else if(this.mTabBar.selectedIndex == 1)
            {
               pvpRule.visible = true;
            }
            else if(this.mTabBar.selectedIndex == 2)
            {
               pvpRule.visible = false;
            }
         }
         var _loc1_:Array = GlobalData.$mConfig_simple.pvp_config as Array;
         var _loc2_:Number = mBg_list.width * 0.5;
         mTxt_pkTimes = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90657),MainConfig.$isEnglish ? 17 : 20,16777215,"left",MainConfig.$isEA ? _loc2_ + 200 : _loc2_,35);
         mTxt_pkTimes.x = MainConfig.$isEnglish ? 10 : 17;
         mTxt_pkTimes.y = MainConfig.$isEA ? this.mBg_list.y - 68 : (MainConfig.$isEnglish ? this.mBg_list.y - 60 + 3 : this.mBg_list.y - 80);
         mBox_info.addChild(mTxt_pkTimes);
         _txt_coin = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getLanguageStr(90443),GlobalData.$userData.mark,"UI_money_mark_0_0000");
         _txt_coin.fontSize = MainConfig.$isEnglish ? 17 : 20;
         _txt_coin.x = MainConfig.$isEA ? mTxt_pkTimes.x : (MainConfig.$isEnglish ? mTxt_pkTimes.x + mTxt_pkTimes.width - 55 : mTxt_pkTimes.x - 7);
         _txt_coin.y = MainConfig.$isEA ? mTxt_pkTimes.y + mTxt_pkTimes.height - 4 : (MainConfig.$isEnglish ? mTxt_pkTimes.y - 4 : mTxt_pkTimes.y + mTxt_pkTimes.height);
         addChild(_txt_coin);
         this.mBtn_re = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(mFun_status ? 20304 : 20303),135,70,"UI_btn_normalFun_0000");
         this.mBtn_re.addEventListener("triggered",this.onTRIGGERED_btns);
         if(MainConfig.$isEnglish == true)
         {
            mBtn_re.fontSize = 19;
         }
         this.mBtn_re.x = mBg_list.x + mBg_list.width - mBtn_re.width - 3;
         this.mBtn_re.y = mBg_list.y - 50 - 20;
         this.addChild(this.mBtn_re);
         mBtn_re.visible = !GlobalFunction.checkIsFirstPVP();
         if(mBox_info)
         {
            mBox_info.flatten();
         }
         if(mFun_status)
         {
            selectMsg();
         }
         else
         {
            selectList(true);
         }
         checkGuide();
      }
      
      private function pvpRuleTriggered(param1:Event) : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_pvp_get_day_award",false,true);
      }
      
      private function onTRIGGERED_btns(param1:Event) : void
      {
         mFun_status = !mFun_status;
         if(mFun_status)
         {
            mBtn_re.text = GlobalLanguageStr.getLanguageStr(20304);
            selectMsg();
         }
         else
         {
            mBtn_re.text = GlobalLanguageStr.getLanguageStr(20303);
            selectList(true);
         }
      }
      
      public function selectList(param1:Boolean) : void
      {
         var _loc2_:Number = SendAndSelect.$systemTimer_nowSecond;
         var _loc3_:Boolean = false;
         if(_loc2_ - mRefresh_s > 10)
         {
            mRefresh_s = _loc2_;
            _loc3_ = true;
         }
         if(_loc3_ || param1)
         {
            SendServiceAMFFun.send_user_get_rank_list(re_get_rank_list);
         }
         else
         {
            GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(20213));
         }
      }
      
      private function re_get_rank_list(param1:Object) : void
      {
         if(param1.data[5])
         {
            GlobalData.$userData.mark = param1.data[5];
         }
         mPVP_list = param1.data;
         if(mTxt_pkTimes && mPVP_list.length > 6)
         {
            mTxt_pkTimes.text = GlobalLanguageStr.getLanguageStr(90657) + "：" + String(mPVP_list[6]);
         }
         if(mTabBar.selectedIndex != 0)
         {
            this.setList();
            this.addList();
         }
      }
      
      private function selectMsg() : void
      {
         SendServiceAMFFun.send_user_get_msg(reServiceMsg);
      }
      
      private function reServiceMsg(param1:Object) : void
      {
         GlobalData.$msg_new_num = param1.data.new_num;
         mMailListArr = param1.data.pvp_msg["pvp"];
         this.setList();
         this.addList();
      }
      
      override public function setList() : void
      {
         var tweenComplete:*;
         this.delList();
         if(this.mTabBar.selectedIndex == -1)
         {
            if(this.mList == null)
            {
               super.setList();
            }
            return;
         }
         if(this.mTabBar.selectedIndex == 1)
         {
            tweenComplete = function():void
            {
               isReady = true;
            };
            isReady = false;
            isOut = true;
            GlobalData.$mStarling.juggler.tween(this,0.4,{"onComplete":tweenComplete});
            setPVPList_listData();
         }
         else if(this.mTabBar.selectedIndex == 3)
         {
            setPVPList_listData();
         }
      }
      
      private function setPVPList_listData() : void
      {
         var _loc3_:Number = NaN;
         var _loc2_:Object = null;
         var _loc1_:VerticalLayout = null;
         if(this.mList == null)
         {
            _loc3_ = 170;
            _loc2_ = {
               "paging":0,
               "gap":(mFun_status ? 10 : 0),
               "horizontalGap":20,
               "verticalGap":20,
               "paddingTop":10,
               "paddingRight":0,
               "paddingBottom":40,
               "paddingLeft":0,
               "horizontalAlign":"center",
               "verticalAlign":"top"
            };
            _loc1_ = new VerticalLayout();
            _loc1_.paddingTop = _loc2_.paddingTop;
            _loc1_.paddingRight = _loc2_.paddingRight;
            _loc1_.paddingBottom = _loc2_.paddingBottom;
            _loc1_.paddingLeft = _loc2_.paddingLeft;
            _loc1_.horizontalAlign = _loc2_.horizontalAlign;
            _loc1_.verticalAlign = _loc2_.verticalAlign;
            _loc1_.gap = _loc2_.gap;
            _loc1_.hasVariableItemDimensions = true;
            this.mList = new List();
            this.mList.isSelectable = false;
            this.mList.width = GlobalData.$mStageWidth - 20;
            this.mList.height = mListH = GlobalData.$center_height - 205;
            this.mList.layout = _loc1_;
            this.mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
            this.mList.x = int((GlobalData.$mStageWidth - this.mList.width) * 0.5);
            this.mList.y = mListY = _loc3_ + 70;
            this.mList.snapScrollPositionsToPixels = true;
            this.addChild(this.mList);
            _loc2_ = null;
            _loc1_ = null;
            this.mList.dataProvider = new ListCollection();
         }
      }
      
      override public function addList() : void
      {
         var _data:Object;
         var i:int;
         var l:int;
         var _myRank:int;
         var _list_pk:Array;
         var _list_enemy:Array;
         var _list_winner:Array;
         var _list_loser:Array;
         var _itemArr:Array;
         var _currCfg:Array;
         var _123Obj:Object;
         var _had123:Boolean;
         var j:int;
         var _isFirstPVP:Boolean;
         var _itemData:Object;
         var _lv:int;
         var _listArr:Array;
         if(this.mTabBar)
         {
            $tabBarSelectedIndex = this.mTabBar.selectedIndex;
         }
         if(mTabBar.selectedIndex == 1)
         {
            i = 0;
            this.delTips();
            if(mFun_status)
            {
               if(mMailListArr.length > 0)
               {
                  l = int(mMailListArr.length);
                  i = 0;
                  while(i < l)
                  {
                     _data = mMailListArr[i];
                     _data["numberIndex"] = (_data.time as Date).time;
                     _data["indexID_s"] = i;
                     i = i + 1;
                  }
                  mMailListArr.sortOn("numberIndex",0x10 | 2);
                  this.setListTimer(mList,mMailListArr,ItemPVPMsg,false);
               }
               else
               {
                  this.setTips(GlobalLanguageStr.getLanguageStr(25054));
               }
               return;
            }
            _myRank = int(mPVP_list[0]);
            GlobalData.$userData.records.current_rank = _myRank;
            _list_pk = mPVP_list[1];
            _list_enemy = mPVP_list[2];
            _list_winner = mPVP_list[3];
            _list_loser = mPVP_list[4];
            l = int(_list_pk.length);
            _itemArr = [];
            i = 0;
            while(i < l)
            {
               _currCfg = _list_pk[i];
               if(GlobalData.$userData.uid != _currCfg[1])
               {
                  _data = getListData(_currCfg,0,_list_enemy);
                  _itemArr.push(_data);
               }
               i = i + 1;
            }
            l = int(_list_enemy.length);
            i = 0;
            while(i < l)
            {
               _currCfg = _list_enemy[i];
               _data = getListData(_currCfg,1);
               _itemArr.push(_data);
               i = i + 1;
            }
            l = int(_list_winner.length);
            _had123 = false;
            i = 0;
            while(i < l)
            {
               _had123 = false;
               _currCfg = _list_winner[i];
               j = 0;
               while(j < _itemArr.length)
               {
                  _123Obj = _itemArr[j];
                  if(_currCfg[1] == _123Obj["id"])
                  {
                     _had123 = true;
                     break;
                  }
                  j = j + 1;
               }
               if(!_had123 && GlobalData.$userData.uid != _currCfg[1])
               {
                  _data = getListData(_currCfg,-1);
                  _itemArr.push(_data);
               }
               i = i + 1;
            }
            _data = {};
            _data["status"] = -1;
            _data["numberIndex"] = GlobalFunction.check_pvp_list_title(_myRank);
            _data["indexID_s"] = _myRank;
            _data["id"] = GlobalData.$userData.uid;
            _data["is_enemy"] = 0;
            _itemArr.push(_data);
            _isFirstPVP = GlobalFunction.checkIsFirstPVP();
            if(_isFirstPVP)
            {
               _list_loser = [[_myRank - 1,"r999999999_6_0",GlobalLanguageStr.getLanguageStr("pvp_robot_name")]];
               l = int(_list_loser.length);
               i = 0;
               while(i < l)
               {
                  _currCfg = _list_loser[i];
                  _data = getListData(_currCfg,-1,null,1);
                  _itemArr.push(_data);
                  i = i + 1;
               }
               mList.verticalScrollPolicy = "off";
            }
            else
            {
               mList.verticalScrollPolicy = "on";
               l = int(_list_loser.length);
               i = 0;
               while(i < l)
               {
                  _currCfg = _list_loser[i];
                  _data = getListData(_currCfg,-1,null,1);
                  _itemArr.push(_data);
                  i = i + 1;
               }
            }
            _itemArr.sortOn("indexID_s",16);
            l = int(_itemArr.length);
            _itemData = null;
            _lv = 0;
            _listArr = [];
            i = 0;
            while(i < l)
            {
               _itemData = _itemArr[i];
               if(_lv != _itemData["numberIndex"])
               {
                  _lv = int(_itemData["numberIndex"]);
                  _listArr.push(getLvTitleData(_lv));
               }
               if(!(_itemData["id"].indexOf("r") > -1 && _itemData["numberIndex"] == 1 && _itemData["indexID_s"] != 1 && _itemData["is_enemy"] == -1))
               {
                  _listArr.push(_itemData);
                  if(_itemData["status"] < 0)
                  {
                     mSelfID = _listArr.length - 1;
                  }
               }
               i = i + 1;
            }
            if(_myRank < 4)
            {
               mSelfID = -1;
            }
            if(_isFirstPVP)
            {
               mSelfID = _listArr.length - 1;
            }
            this.delTips();
            this.setListTimer(mList,_listArr,ItemPVP,false,mSelfID);
            if(GlobalData.$PVPupClip)
            {
               GlobalData.$PVPupClip = false;
               GlobalData.$mGameClassObject.openPopUp(new PanelPopPVPup());
               SoundManager.getOnlyExample().playSound("E_9006");
               GlobalData.$mStarling.juggler.tween(this,1,{"onComplete":function():void
               {
                  SoundManager.getOnlyExample().playSound("levelUp");
               }});
            }
         }
      }
      
      private function getLvTitleData(param1:int) : Object
      {
         var _loc2_:Object = {};
         _loc2_["status"] = param1;
         return _loc2_;
      }
      
      private function getListData(param1:Array, param2:int, param3:Array = null, param4:int = 0) : Object
      {
         var _loc5_:int = 0;
         var _loc6_:Object = {};
         _loc6_["loser"] = param4;
         _loc6_["status"] = 0;
         _loc6_["numberIndex"] = GlobalFunction.check_pvp_list_title(param1[0]);
         _loc6_["indexID_s"] = param1[0];
         _loc6_["id"] = param1[1];
         _loc6_["name"] = param1[2];
         _loc6_["data_base"] = param1[3] == null ? null : param1[3];
         _loc6_["lv"] = param1[4] == null ? 1 : param1[4];
         _loc6_["is_enemy"] = param2;
         if(param3 != null)
         {
            _loc5_ = checkPkHadEnemy(param3,param1);
            _loc6_["is_enemy"] = _loc5_;
         }
         return _loc6_;
      }
      
      private function checkPkHadEnemy(param1:Array, param2:Array) : int
      {
         var _loc5_:int = 0;
         var _loc4_:int = int(param1.length);
         var _loc3_:int = 0;
         _loc5_ = 0;
         while(_loc5_ < _loc4_)
         {
            if(param1[_loc5_][0] == param2[0] && param1[_loc5_][1] == param2[1])
            {
               param1.splice(_loc5_,1);
               _loc3_ = 1;
               break;
            }
            _loc5_++;
         }
         return _loc3_;
      }
      
      private function checkHadWinner(param1:Array, param2:Array) : void
      {
         var _loc4_:int = 0;
         var _loc3_:int = int(param1.length);
         _loc4_ = 0;
         while(_loc4_ < _loc3_)
         {
            if(param1[_loc4_][0] == param2[0] && param1[_loc4_][1] == param2[1])
            {
               param1.splice(_loc4_,1);
               break;
            }
            _loc4_++;
         }
      }
      
      private function setPVP_fragment() : void
      {
         _panelChip = new PanelChip();
         _panelChip.y = -80;
         addChildAt(_panelChip,0);
      }
      
      private function addList_fragment() : void
      {
         var _loc6_:Object = null;
         var _loc5_:Object = null;
         if(this.mTabBar)
         {
            $tabBarSelectedIndex = this.mTabBar.selectedIndex;
         }
         var _loc1_:Object = GlobalData.$userData.fragment["equips"];
         var _loc4_:Array = [];
         var _loc3_:String = "";
         var _loc2_:Array = null;
         for(_loc6_ in _loc1_)
         {
            _loc3_ = _loc6_.toString();
            _loc2_ = _loc3_.split("_");
            _loc5_ = {};
            _loc5_["id"] = _loc6_.toString();
            _loc5_["data_base"] = _loc1_[_loc6_] as Array;
            _loc5_["sort_1"] = _loc2_[2];
            _loc5_["sort_2"] = _loc2_[1];
            _loc4_.push(_loc5_);
         }
         this.delTips();
         if(_loc4_.length > 0)
         {
            mList.y = 200;
            setListHeight(-80);
            _loc4_.sortOn(["sort_1","sort_2"],[0x10 | 2,16]);
            this.setListTimer(mList,_loc4_,ItemFragment,false);
         }
         else
         {
            this.setTips(GlobalLanguageStr.getLanguageStr(90182));
         }
      }
      
      private function delPVP_fragment() : void
      {
         if(_panelChip)
         {
            _panelChip.removeFromParent(true);
         }
      }
      
      private function delPVP_elite() : void
      {
         var _loc1_:headSprite = null;
         if(mBox_elite)
         {
            if(mBox_elite.isFlattened)
            {
               mBox_elite.unflatten();
            }
            StarlingTools.removeChildrenClear(mBox_elite);
            mBox_elite.removeFromParent(true);
         }
         if(mImgBg)
         {
            mImgBg.removeFromParent(true);
         }
         if(mBox_elite_bg)
         {
            mBox_elite_bg.removeFromParent(true);
         }
         if(winS)
         {
            winS.removeFromParent(true);
         }
         if(bottom_bg)
         {
            bottom_bg.removeFromParent(true);
            bottom_bg.dispose();
         }
         if(txt_time_infor)
         {
            txt_time_infor.removeFromParent(true);
            txt_time_infor.dispose();
         }
         if(first_time_txt)
         {
            first_time_txt.removeFromParent(true);
            first_time_txt.dispose();
         }
         if(second_time_txt)
         {
            second_time_txt.removeFromParent(true);
            second_time_txt.dispose();
         }
         if(txt_extreme_info)
         {
            txt_extreme_info.removeFromParent(true);
            txt_extreme_info.dispose();
         }
         if(gamerule)
         {
            gamerule.removeFromParent(true);
            gamerule.dispose();
         }
         if(battlegroup)
         {
            battlegroup.removeFromParent(true);
            battlegroup.dispose();
         }
         if(_spRule)
         {
            _spRule.removeEventListener("touch",onPith2);
            _spRule.removeFromParent(true);
            _spRule = null;
         }
         if(_spRule1)
         {
            _spRule1.removeEventListener("touch",onPith1);
            _spRule1.removeFromParent(true);
            _spRule1 = null;
         }
         if(mTag_a)
         {
            StarlingTools.removeChildrenClear(mTag_a);
         }
         if(awardBtn)
         {
            awardBtn.removeFromParent(true);
         }
         if(blessBtn)
         {
            blessBtn.removeFromParent(true);
         }
         if(battleinfoBtn)
         {
            battleinfoBtn.removeFromParent(true);
         }
         if(user_arr)
         {
            while(user_arr.length > 0)
            {
               _loc1_ = user_arr.pop();
               _loc1_.removeFromParent(true);
               _loc1_ = null;
            }
         }
         if(term_txt)
         {
            term_txt.dispose();
            term_txt.removeFromParent(true);
         }
         term_txt = null;
         mTag_a = null;
         awardBtn = null;
         blessBtn = null;
         battleinfoBtn = null;
         bottom_bg = null;
         winS = null;
         mBox_elite_bg = null;
         mBox_elite = null;
         gamerule = null;
         txt_extreme_info = null;
         user_arr = null;
         battlegroup = null;
         _spRule = null;
         _spRule1 = null;
         GlobalFunction.delTextureByBD("pic_extreme_bg_0");
      }
      
      private function chechToBlessTime() : void
      {
         var _loc9_:Object = GlobalData.$mConfig_simple.extreme;
         var _loc7_:Object = _loc9_.grant_gift;
         var _loc5_:Number = _loc7_[2] * 60 * 1000;
         var _loc10_:Date = Tools.getServerNowTimeDate(SendAndSelect.$systemTimer_nowSecond * 1000);
         var _loc3_:Number = _loc10_.time;
         var _loc1_:Date = new Date(_loc10_.fullYear,_loc10_.month,_loc10_.date,_loc7_[0][0][0],_loc7_[0][0][1]);
         var _loc11_:Number = _loc1_.time;
         var _loc4_:Date = new Date(_loc10_.fullYear,_loc10_.month,_loc10_.date,_loc7_[0][0][0],_loc7_[0][0][1],null,_loc5_);
         var _loc6_:Number = _loc4_.time;
         var _loc8_:Date = new Date(_loc10_.fullYear,_loc10_.month,_loc10_.date,_loc7_[0][1][0],_loc7_[0][1][1]);
         var _loc12_:Number = _loc8_.time;
         var _loc13_:Date = new Date(_loc10_.fullYear,_loc10_.month,_loc10_.date,_loc7_[0][1][0],_loc7_[0][1][1],null,_loc5_);
         var _loc2_:Number = _loc13_.time;
         if(_loc3_ == _loc11_ || _loc3_ == _loc12_)
         {
            setTime();
         }
      }
      
      private function setPVP_elite() : void
      {
         var _users:Array;
         var _u:Object;
         var constX:Array;
         var constY:Array;
         var o:Object;
         var oo:Object;
         var _recRank:Rectangle;
         var _t9x9:Scale9Textures;
         var _gift_obj:Object;
         var _str:String;
         var _player:headSprite;
         var i:int;
         var _currTime:Object;
         var _str2:String;
         var allUIhide:* = function():void
         {
            bottom_bg.visible = false;
            txt_time_infor.visible = false;
            first_time_txt.visible = false;
            second_time_txt.visible = false;
            awardBtn.visible = false;
            blessBtn.visible = false;
            blessBtn.clearGlow();
            battleinfoBtn.visible = false;
            mTag_a.visible = false;
            txt_extreme_info.visible = false;
         };
         var getTermName:* = function():String
         {
            var _loc3_:String = null;
            var _loc1_:Object = GlobalFunction.getExtremeTime();
            var _loc2_:String = "";
            switch(_loc1_.time)
            {
               case "signup":
                  _loc3_ = GlobalLanguageStr.getLanguageStr(90351) + GlobalLanguageStr.getLanguageStr(90376,Tools.dateFormatByMS(_loc1_.end + GlobalConfig.HOURS_8_MS));
                  break;
               case "audition":
               case "select_aud":
                  _loc3_ = GlobalLanguageStr.getLanguageStr(90352);
                  break;
               case "battle":
                  _loc3_ = GlobalLanguageStr.getLanguageStr(90353);
                  if(_loc1_.timeNum == 0)
                  {
                     _loc2_ = " " + GlobalLanguageStr.getLanguageStr(90355);
                  }
                  else if(_loc1_.timeNum == 1)
                  {
                     _loc2_ = " " + GlobalLanguageStr.getLanguageStr(90343);
                  }
                  else if(_loc1_.timeNum == 2)
                  {
                     _loc2_ = " " + GlobalLanguageStr.getLanguageStr(90342);
                  }
                  else if(_loc1_.timeNum == 3)
                  {
                     _loc2_ = " " + GlobalLanguageStr.getLanguageStr(90340);
                  }
                  else if(_loc1_.timeNum == 4)
                  {
                     _loc2_ = " " + GlobalLanguageStr.getLanguageStr(90339);
                  }
                  break;
               case "grant":
                  _loc3_ = " " + GlobalLanguageStr.getLanguageStr(90354);
                  break;
               default:
                  _loc3_ = " " + GlobalLanguageStr.getLanguageStr(90533);
            }
            return _loc3_ + _loc2_;
         };
         mark = isJoinGame();
         if(mark.isF)
         {
            _isapply = GlobalData.$useExtreme.phase == "signup";
         }
         else
         {
            _isapply = false;
         }
         _users = GlobalData.$useExtreme.grant_data;
         _u = GlobalData.$useExtreme;
         user_arr = [];
         mImgBg = GlobalFunction.createImage("pic_extreme_bg_0",true);
         mImgBg.y = GlobalData.$center_height_curr - 121 - mImgBg.height + 20;
         this.addChildAt(mImgBg,0);
         constX = [320,320,160,480];
         constY = [mImgBg.y + 230,mImgBg.y + 435,mImgBg.y + 435,mImgBg.y + 435];
         o = GlobalFunction.get_HelpLink(GlobalLanguageStr.getLanguageStr(90335));
         _spRule = o.ui;
         _spRule.x = 10;
         _spRule.y = 110;
         addChild(_spRule);
         _spRule.addEventListener("touch",onPith2);
         oo = GlobalFunction.get_HelpLink(GlobalLanguageStr.getLanguageStr(90252));
         _spRule1 = oo.ui;
         _spRule1.x = GlobalData.$mStageWidth - oo.w - 20;
         _spRule1.y = _spRule.y;
         addChild(_spRule1);
         _spRule1.addEventListener("touch",onPith1);
         txt_extreme_info = GlobalTextStyle.getHtmlTextRenderer();
         txt_extreme_info.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90337),[16776960,4241129,16711680,16776960],20,25);
         txt_extreme_info.mLayoutFun = function():void
         {
            _recRank = txt_extreme_info.getTextSnapshotFrame();
            txt_extreme_info.x = GlobalData.$mStageWidth - _recRank.width >> 1;
            txt_extreme_info.y = GlobalData.centerRealHeight() >> 1;
         };
         this.addChild(txt_extreme_info);
         _t9x9 = new Scale9Textures(GlobalFunction.getTexture("UI_bg_9slice_7_0000"),new Rectangle(30,30,50,50));
         bottom_bg = new Scale9Image(_t9x9);
         bottom_bg.width = 616;
         bottom_bg.height = 85;
         bottom_bg.x = int((GlobalData.$mStageWidth - bottom_bg.width) * 0.5);
         bottom_bg.y = GlobalData.$center_height_curr - 121 - bottom_bg.height + 5;
         this.addChild(bottom_bg);
         txt_time_infor = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90253),20,16764006,"center",550,40);
         txt_time_infor.x = GlobalData.$mStageWidth - txt_time_infor.width >> 1;
         txt_time_infor.y = bottom_bg.y + 15;
         this.addChild(txt_time_infor);
         first_time_txt = GlobalFunction.createTextField(280,40,"","",20,16777215);
         first_time_txt.x = bottom_bg.x + 15;
         first_time_txt.y = MainConfig.$isEA ? bottom_bg.y + bottom_bg.height * 0.5 + 6 : bottom_bg.y + bottom_bg.height * 0.5 - 8;
         this.addChild(first_time_txt);
         second_time_txt = GlobalFunction.createTextField(280,40,"","",20,16777215);
         second_time_txt.hAlign = "right";
         second_time_txt.x = bottom_bg.x + bottom_bg.width - second_time_txt.width - 45;
         second_time_txt.y = MainConfig.$isEA ? bottom_bg.y + bottom_bg.height * 0.5 + 6 : bottom_bg.y + bottom_bg.height * 0.5 - 8;
         this.addChild(second_time_txt);
         this.awardBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90249),150,70,"UI_btn_normalFun_0000");
         awardBtn.name = "awardBtn";
         awardBtn.x = 30;
         awardBtn.y = bottom_bg.y - awardBtn.height;
         awardBtn.addEventListener("triggered",clickHandler);
         this.addChild(awardBtn);
         mTag_a = GlobalFunction.getTagPopTip(GlobalData.$useExtreme.gifts_count,false);
         mTag_a.pivotY = mTag_a.height;
         mTag_a.x = int(awardBtn.x + awardBtn.width - 20 * 2) + 20;
         mTag_a.y = awardBtn.y + 20;
         addChild(mTag_a);
         this.blessBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90250),150,70,"UI_btn_normalFun_0000");
         if(MainConfig.$isEnglish)
         {
            blessBtn.fontSize = 20;
         }
         blessBtn.name = "blessBtn";
         blessBtn.pivotX = blessBtn.width >> 1;
         blessBtn.x = GlobalData.$mStageWidth >> 1;
         blessBtn.y = awardBtn.y - 1;
         blessBtn.showGlow();
         blessBtn.addEventListener("triggered",clickHandler);
         this.addChild(blessBtn);
         if(mark.isF)
         {
            if(GlobalData.$useExtreme.phase == "signup")
            {
               if(GlobalData.$useExtreme.is_signup == true)
               {
                  _str = GlobalLanguageStr.getLanguageStr(90369);
               }
               else
               {
                  _str = GlobalLanguageStr.getLanguageStr(90255);
               }
            }
            else
            {
               _str = GlobalLanguageStr.getLanguageStr(90251);
            }
         }
         else
         {
            _str = GlobalLanguageStr.getLanguageStr(90255);
         }
         this.battleinfoBtn = new LOL_Scale9Button(_str,150,70,"UI_btn_normalFun_0000");
         battleinfoBtn.name = _isapply ? "applyBtn" : "battleinfoBtn";
         if(MainConfig.$isEA)
         {
            battleinfoBtn.fontSize = 18;
         }
         battleinfoBtn.x = GlobalData.$mStageWidth - battleinfoBtn.width - 20;
         battleinfoBtn.y = awardBtn.y - 1;
         battleinfoBtn.addEventListener("triggered",clickHandler);
         this.addChild(battleinfoBtn);
         if(GlobalData.$useExtreme.grant_data == null)
         {
            i = 0;
            while(i < 4)
            {
               _player = new headSprite(null,i);
               _player.x = constX[i];
               _player.y = constY[i];
               this.addChild(_player);
               user_arr.push(_player);
               i = i + 1;
            }
         }
         else
         {
            i = 0;
            while(i < _users.length)
            {
               if(i == 0 && _users[i].zone == GlobalData.$userData.zone)
               {
                  winS = GlobalFunction.createImage("UI_extreme_bg_0040000");
                  winS.x = GlobalData.$mStageWidth * 0.05;
                  winS.y = _spRule1.y + 50;
                  this.addChild(winS);
               }
               _player = new headSprite(_users[i],i);
               _player.x = constX[i];
               _player.y = constY[i];
               this.addChild(_player);
               user_arr.push(_player);
               i = i + 1;
            }
         }
         mark = isJoinGame();
         _currTime = GlobalFunction.getExtremeTime();
         if(mark.isF)
         {
            _str2 = getTermName();
            _str2 = Tools.formatLine(_str2,"\n",18);
            term_txt = GlobalFunction.createTextField(300,60,_str2,"",14,16764006);
            term_txt.hAlign = "center";
            term_txt.vAlign = "bottom";
            term_txt.x = battleinfoBtn.x - 75;
            term_txt.y = battleinfoBtn.y - term_txt.height;
            this.addChild(term_txt);
         }
         if(mark.isF == true && mark.isBless == true)
         {
            txt_extreme_info.visible = false;
            if(GlobalData.$useExtreme.is_signup == false)
            {
               if(_currTime.time == "audition" || _currTime.time == "select_aud")
               {
                  battleinfoBtn.enabled = false;
               }
               else
               {
                  battleinfoBtn.enabled = true;
               }
            }
            else
            {
               battleinfoBtn.enabled = true;
            }
         }
         if(mark.isF == true && mark.isBless == false)
         {
            txt_extreme_info.visible = false;
            blessBtn.enabled = false;
            blessBtn.clearGlow();
            if(GlobalData.$useExtreme.is_signup == false)
            {
               if(_currTime.time == "audition" || _currTime.time == "select_aud")
               {
                  battleinfoBtn.enabled = false;
               }
               else
               {
                  battleinfoBtn.enabled = true;
               }
            }
            else
            {
               battleinfoBtn.enabled = true;
            }
         }
         if(mark.isF == false && mark.isBless == true)
         {
            blessBtn.enabled = true;
            battleinfoBtn.enabled = false;
            txt_extreme_info.visible = false;
         }
         if(mark.isF == false && mark.isBless == false)
         {
            blessBtn.enabled = false;
            battleinfoBtn.enabled = false;
            txt_extreme_info.visible = false;
         }
         if(battleinfoBtn.enabled && battleinfoBtn.name == "applyBtn" && GlobalData.$useExtreme.is_signup != true)
         {
            battleinfoBtn.showGlow();
         }
         else
         {
            battleinfoBtn.clearGlow();
         }
         if(mBox_elite)
         {
            mBox_elite.flatten();
         }
         setTime();
      }
      
      private function onPith2(param1:TouchEvent) : void
      {
         var _loc7_:Array = null;
         var _loc6_:Array = null;
         var _loc8_:int = 0;
         var _loc3_:Object = null;
         var _loc2_:Number = NaN;
         var _loc5_:Date = null;
         var _loc4_:Touch = param1.getTouch(_spRule,"ended");
         if(_loc4_)
         {
            _loc7_ = GlobalData.$useExtreme.my_zone_list;
            _loc6_ = [];
            if(_loc7_ != null)
            {
               _loc6_.push(Tools.formatLineX(GlobalLanguageStr.getStr(90402),GlobalTextStyle.COLOR_G_G_R_R,1000,20));
               _loc8_ = 0;
               while(_loc8_ < _loc7_.length)
               {
                  if(_loc7_[_loc8_] == GlobalData.$userData.zone)
                  {
                     _loc6_.push(Tools.formatLineX(GlobalData.$mConfig_zones[_loc7_[_loc8_]][0],GlobalTextStyle.COLOR_DR,1000,20));
                  }
                  else
                  {
                     _loc6_.push(Tools.formatLineX(GlobalData.$mConfig_zones[_loc7_[_loc8_]][0],GlobalTextStyle.COLOR_DG,1000,20));
                  }
                  _loc8_++;
               }
               GlobalFunction.popInforAlert(GlobalLanguageStr.getLanguageStr(90335),Tools.formatHtmlTextBr(_loc6_,"center"));
            }
            else
            {
               _loc3_ = GlobalFunction.getExtremeStartEndTime("signup");
               _loc2_ = _loc3_.start + GlobalData.$mConfig_simple.extreme.time.cycle * 60 * 1000;
               _loc5_ = new Date();
               _loc5_.setTime(_loc2_ + GlobalConfig.HOURS_8_MS);
               GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(90360,Tools.dateFormatByMS(_loc5_.time,"YYYY-MM-DD HH:NN:SS")),null,true);
            }
         }
      }
      
      private function onPith1(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(_spRule1,"ended");
         if(_loc2_)
         {
            GlobalFunction.popPanelHelp(MainConfig.SERVER_ADDRESS_HELP_EXTREME);
         }
      }
      
      public function update_tag() : void
      {
         if(mTag_a)
         {
            mTag_a.removeFromParent(true);
         }
         mTag_a = GlobalFunction.getTagPopTip(GlobalData.$useExtreme.gifts_count,false);
         mTag_a.pivotY = mTag_a.height;
         mTag_a.x = int(awardBtn.x + awardBtn.width - 20 * 2) + 20;
         mTag_a.y = awardBtn.y + 20;
         addChild(mTag_a);
      }
      
      private function clickHandler(param1:Event) : void
      {
         var _lv:int;
         var _fun:Object;
         var showpanel:*;
         var _cfg:Object;
         var _lastMS:Number;
         var _htmlStr:String;
         var e:Event = param1;
         var _btn:LOL_Scale9Button = e.currentTarget as LOL_Scale9Button;
         if(_btn.name == "awardBtn")
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_elite_award",false,true);
         }
         else if(_btn.name == "blessBtn")
         {
            if(mark.isBless == false)
            {
               GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(90297));
            }
            else if(first_status || second_status)
            {
               if(blessBtn.enabled)
               {
                  SendServiceAMFFun.send_user_get_extreme_grant(_refun);
                  blessBtn.showGlow();
               }
               else
               {
                  GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(90303));
               }
            }
            else
            {
               GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(90298));
            }
         }
         else if(_btn.name == "applyBtn")
         {
            _lv = int(GlobalData.$mConfig_simple.start_lv[16]);
            if(mark.isF == false)
            {
               GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(90337));
            }
            else if(GlobalData.$mUserData.lv < _lv)
            {
               GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(90318,String(_lv)));
            }
            else
            {
               showpanel = function():void
               {
                  GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_elite_battle",false,true);
               };
               GlobalData.$tempIsApplyorChangeTeam = false;
               _fun = {
                  "ok":showpanel,
                  "no":GlobalFunction.functionNull,
                  "aid":"A_2009_5"
               };
               GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90258),GlobalTextStyle.COLOR_W_Y_Y_G),_fun);
            }
         }
         else if(_btn.name == "battleinfoBtn")
         {
            if(mark.isF == false)
            {
               GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(90338));
            }
            else if(GlobalData.$useExtreme.phase == "battle" || GlobalData.$useExtreme.phase == "grant")
            {
               GlobalData.$extreme_groupIndex = 0;
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_elite_group_select",false,true);
            }
            else if(GlobalData.$useExtreme.phase == "audition" || GlobalData.$useExtreme.phase == "select_aud")
            {
               if(GlobalData.$useExtreme.is_signup == true)
               {
                  GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_elite_select",false,true);
               }
               else
               {
                  _cfg = GlobalFunction.getExtremeStartEndTime("select_aud");
                  if(_cfg && _cfg.end)
                  {
                     _lastMS = _cfg.end - SendAndSelect.$systemTimer_nowSecond * 1000;
                     _lastMS = _lastMS > 0 ? _lastMS : 0;
                     _htmlStr = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90299,Tools.timeFormatAll(_lastMS * 0.001,false)),GlobalTextStyle.COLOR_W_Y_R_Y);
                     GlobalFunction.popAlert("",_htmlStr);
                  }
               }
            }
         }
      }
      
      private function _refun(param1:*) : void
      {
         var _loc3_:Array = null;
         var _loc5_:int = 0;
         var _loc2_:Object = null;
         var _loc6_:String = null;
         var _loc4_:String = null;
         var _loc7_:Array = null;
         if(param1)
         {
            blessBtn.enabled = false;
            blessBtn.clearGlow();
            GlobalData.$userData.records.extreme_grant = param1.data.record_extreme_grant;
            GlobalData.$userData.attrs.energy_extra = param1.data.attr_energy_extra;
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateEn(param1.data["energy"]);
            _loc3_ = GlobalData.$mConfig_simple.extreme.grant_gift;
            if(GlobalData.$useExtreme.grant_data[0].zone == GlobalData.$userData.zone)
            {
               _loc5_ = int(_loc3_[1][0]);
            }
            else
            {
               _loc5_ = int(_loc3_[1][1]);
            }
            _loc2_ = GlobalFunction.getAwardByType("energy",_loc5_);
            _loc7_ = GlobalData.$useExtreme.grant_data;
            _loc4_ = _loc2_.msg;
            if(_loc7_ && _loc7_[0] && _loc7_[0].data)
            {
               if(_loc7_[0].data[0])
               {
                  _loc6_ = _loc7_[0].data[0][0];
                  _loc4_ = GlobalLanguageStr.getLanguageStr(90358,_loc7_[0].name) + _loc2_.msg;
               }
            }
            GlobalFunction.popAward("energy",_loc4_,_loc5_,false,_loc6_);
         }
      }
      
      private function fun(param1:Number) : String
      {
         if(param1 == 0)
         {
            return "00";
         }
         return String(param1);
      }
      
      private function setTime() : void
      {
         var _loc3_:Array = null;
         var _loc15_:Array = null;
         var _loc4_:Date = null;
         var _loc8_:int = 0;
         var _loc7_:int = 0;
         var _loc14_:Object = GlobalData.$mConfig_simple.extreme;
         var _loc12_:Object = _loc14_.grant_gift;
         var _loc10_:Number = _loc12_[2] * 60 * 1000;
         var _loc17_:Date = Tools.getServerNowTimeDate(SendAndSelect.$systemTimer_nowSecond * 1000);
         var _loc5_:Number = _loc17_.time;
         var _loc1_:Date = new Date(_loc17_.fullYear,_loc17_.month,_loc17_.date,_loc12_[0][0][0],_loc12_[0][0][1]);
         var _loc18_:Number = _loc1_.time;
         var _loc6_:Date = new Date(_loc17_.fullYear,_loc17_.month,_loc17_.date,_loc12_[0][0][0],_loc12_[0][0][1],null,_loc10_);
         var _loc11_:Number = _loc6_.time;
         var _loc13_:Date = new Date(_loc17_.fullYear,_loc17_.month,_loc17_.date,_loc12_[0][1][0],_loc12_[0][1][1]);
         var _loc19_:Number = _loc13_.time;
         var _loc20_:Date = new Date(_loc17_.fullYear,_loc17_.month,_loc17_.date,_loc12_[0][1][0],_loc12_[0][1][1],null,_loc10_);
         var _loc2_:Number = _loc20_.time;
         var _loc16_:Array = GlobalData.$userData.records.extreme_grant;
         var _loc9_:int = 0;
         if(mark.isBless == false)
         {
            if(_loc5_ < _loc18_)
            {
               this.first_time_txt.text = GlobalLanguageStr.getLanguageStr(90300,_loc1_.hours,fun(_loc1_.minutes),_loc6_.hours,fun(_loc6_.minutes));
               this.second_time_txt.text = GlobalLanguageStr.getLanguageStr(90300,_loc13_.hours,fun(_loc13_.minutes),_loc20_.hours,fun(_loc20_.minutes));
               first_time_txt.color = 8421504;
               second_time_txt.color = 8421504;
            }
            else if(_loc18_ <= _loc5_ && _loc5_ < _loc11_)
            {
               this.first_time_txt.text = GlobalLanguageStr.getLanguageStr(90301,_loc1_.hours,fun(_loc1_.minutes),_loc6_.hours,fun(_loc6_.minutes));
               this.first_time_txt.color = 16777215;
               this.second_time_txt.text = GlobalLanguageStr.getLanguageStr(90300,_loc13_.hours,fun(_loc13_.minutes),_loc20_.hours,fun(_loc20_.minutes));
               this.second_time_txt.color = 8421504;
            }
            else if(_loc5_ >= _loc11_ && _loc5_ < _loc19_)
            {
               this.first_time_txt.text = GlobalLanguageStr.getLanguageStr(90302,_loc1_.hours,fun(_loc1_.minutes),_loc6_.hours,fun(_loc6_.minutes));
               this.first_time_txt.color = 8421504;
               this.second_time_txt.text = GlobalLanguageStr.getLanguageStr(90300,_loc13_.hours,fun(_loc13_.minutes),_loc20_.hours,fun(_loc20_.minutes));
               this.second_time_txt.color = 8421504;
            }
            else if(_loc19_ <= _loc5_ && _loc5_ < _loc2_)
            {
               this.first_time_txt.text = GlobalLanguageStr.getLanguageStr(90302,_loc1_.hours,fun(_loc1_.minutes),_loc6_.hours,fun(_loc6_.minutes));
               this.first_time_txt.color = 8421504;
               this.second_time_txt.text = GlobalLanguageStr.getLanguageStr(90301,_loc13_.hours,fun(_loc13_.minutes),_loc20_.hours,fun(_loc20_.minutes));
               this.second_time_txt.color = 16777215;
            }
            else if(_loc5_ >= _loc2_)
            {
               this.first_time_txt.text = GlobalLanguageStr.getLanguageStr(90302,_loc1_.hours,fun(_loc1_.minutes),_loc6_.hours,fun(_loc6_.minutes));
               this.first_time_txt.color = 8421504;
               this.second_time_txt.text = GlobalLanguageStr.getLanguageStr(90302,_loc13_.hours,fun(_loc13_.minutes),_loc20_.hours,fun(_loc20_.minutes));
               this.first_time_txt.color = 8421504;
            }
            blessBtn.enabled = false;
         }
         else
         {
            if(_loc5_ < _loc18_)
            {
               this.first_time_txt.text = GlobalLanguageStr.getLanguageStr(90300,_loc1_.hours,fun(_loc1_.minutes),_loc6_.hours,fun(_loc6_.minutes));
               first_time_txt.color = 8421504;
               first_status = false;
               this.second_time_txt.text = GlobalLanguageStr.getLanguageStr(90300,_loc13_.hours,fun(_loc13_.minutes),_loc20_.hours,fun(_loc20_.minutes));
               this.second_time_txt.color = 8421504;
               second_status = false;
               blessBtn.enabled = false;
            }
            else if(_loc18_ <= _loc5_ && _loc5_ < _loc11_)
            {
               this.first_time_txt.text = GlobalLanguageStr.getLanguageStr(90301,_loc1_.hours,fun(_loc1_.minutes),_loc6_.hours,fun(_loc6_.minutes));
               first_time_txt.color = 16777215;
               first_status = true;
               _loc9_ = 0;
               while(_loc9_ < _loc16_.length)
               {
                  if(_loc16_[_loc9_] == 0)
                  {
                     blessBtn.enabled = false;
                  }
                  else
                  {
                     blessBtn.enabled = true;
                  }
                  _loc9_++;
               }
               this.second_time_txt.text = GlobalLanguageStr.getLanguageStr(90300,_loc13_.hours,fun(_loc13_.minutes),_loc20_.hours,fun(_loc20_.minutes));
               this.second_time_txt.color = 8421504;
               second_status = false;
            }
            else if(_loc5_ >= _loc11_ && _loc5_ < _loc19_)
            {
               this.first_time_txt.text = GlobalLanguageStr.getLanguageStr(90302,_loc1_.hours,fun(_loc1_.minutes),_loc6_.hours,fun(_loc6_.minutes));
               first_time_txt.color = 8421504;
               first_status = false;
               this.second_time_txt.text = GlobalLanguageStr.getLanguageStr(90300,_loc13_.hours,fun(_loc13_.minutes),_loc20_.hours,fun(_loc20_.minutes));
               this.second_time_txt.color = 8421504;
               second_status = false;
               blessBtn.enabled = false;
            }
            else if(_loc19_ <= _loc5_ && _loc5_ < _loc2_)
            {
               this.first_time_txt.text = GlobalLanguageStr.getLanguageStr(90302,_loc1_.hours,fun(_loc1_.minutes),_loc6_.hours,fun(_loc6_.minutes));
               first_time_txt.color = 8421504;
               first_status = false;
               this.second_time_txt.text = GlobalLanguageStr.getLanguageStr(90301,_loc13_.hours,fun(_loc13_.minutes),_loc20_.hours,fun(_loc20_.minutes));
               this.second_time_txt.color = 16777215;
               second_status = true;
               _loc9_ = 0;
               while(_loc9_ < _loc16_.length)
               {
                  if(_loc16_[_loc9_] == 1)
                  {
                     blessBtn.enabled = false;
                  }
                  else
                  {
                     blessBtn.enabled = true;
                  }
                  _loc9_++;
               }
            }
            else if(_loc5_ >= _loc2_)
            {
               this.first_time_txt.text = GlobalLanguageStr.getLanguageStr(90302,_loc1_.hours,fun(_loc1_.minutes),_loc6_.hours,fun(_loc6_.minutes));
               first_time_txt.color = 8421504;
               first_status = false;
               this.second_time_txt.text = GlobalLanguageStr.getLanguageStr(90302,_loc13_.hours,fun(_loc13_.minutes),_loc20_.hours,fun(_loc20_.minutes));
               this.second_time_txt.color = 8421504;
               second_status = false;
               blessBtn.enabled = false;
            }
            _loc3_ = GlobalData.$userData.records.extreme_grant as Array;
            _loc15_ = GlobalData.$mConfig_simple.extreme.grant_gift as Array;
            _loc4_ = Tools.getServerNowTimeDate(SendAndSelect.$systemTimer_nowSecond * 1000);
            _loc8_ = _loc15_[2] * 60 * 1000;
            _loc7_ = _loc4_.time;
         }
      }
   }
}

import com.meng52.game.global.GlobalData;
import com.meng52.game.global.GlobalFunction;
import com.meng52.game.global.GlobalLanguageStr;
import com.meng52.game.global.GlobalTextStyle;
import com.meng52.game.module.avatar.Avatar;
import com.meng52.utils.StarlingTools;
import starling.display.Image;
import starling.display.Sprite;
import starling.events.Event;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.text.TextField;

class headSprite extends Sprite
{
   
   private var _info:TextField;
   
   private var _txt_1:TextField;
   
   private var _txt_2:TextField;
   
   private var _head_data:Object;
   
   public const txt_width:Number = 150;
   
   public var _user_num:int;
   
   public function headSprite(param1:Object = null, param2:int = 0)
   {
      super();
      _head_data = param1;
      _user_num = param2;
      this.addEventListener("addedToStage",init);
   }
   
   private function init() : void
   {
      var _loc5_:String = null;
      var _loc2_:Avatar = null;
      var _loc1_:Sprite = null;
      var _loc7_:Image = null;
      var _loc4_:Image = null;
      this.removeEventListener("addedToStage",init);
      this.addEventListener("removedFromStage",onREMOVED_FROM_STAGE);
      if(_head_data == null)
      {
         return;
      }
      if(_user_num == 0)
      {
         _loc5_ = "UI_extreme_bg_0050000";
      }
      else if(_user_num == 1)
      {
         _loc5_ = "UI_pvp_icon_2_0001";
      }
      else
      {
         _loc5_ = "UI_pvp_icon_2_0002";
      }
      var _loc6_:Image = GlobalFunction.createImage(_loc5_);
      _loc6_.pivotX = _loc6_.width / 2 - 2;
      _loc6_.pivotY = 5;
      if(_head_data != null)
      {
         _loc2_ = new Avatar(this._head_data.data[0][0],this._head_data.data[0]);
         _loc1_ = _loc2_.getAvatarRes();
         _loc1_.pivotX = _loc1_.width >> 1;
         _loc1_.x = 5;
         _loc1_.y = _user_num == 0 ? _loc6_.height - 25 : _loc6_.height - 15;
         this.addChild(_loc1_);
         this.addChild(_loc6_);
      }
      else
      {
         _loc1_ = new Sprite();
         _loc7_ = GlobalFunction.createImage("UI_bg_card_2_0003");
         _loc7_.pivotX = _loc7_.width >> 1;
         _loc7_.y = _user_num == 0 ? _loc6_.height - 30 : _loc6_.height - 15;
         _loc1_.addChild(_loc7_);
         this.addChild(_loc6_);
         this.addChild(_loc1_);
      }
      _loc1_.scaleX = _loc1_.scaleY = _user_num == 0 ? 1 : 0.7;
      var _loc3_:Object = GlobalFunction.getExtremeTime();
      if(_user_num == 0)
      {
         _info = GlobalTextStyle.getTextField(_loc3_.time == "grant" ? GlobalLanguageStr.getLanguageStr(90312) : GlobalLanguageStr.getLanguageStr(90313),15,16777215,"center",150,29);
         _info.pivotX = _info.width >> 1;
         _info.y = _loc1_.y + _loc1_.height - 30;
         _txt_1 = GlobalTextStyle.getTextField(_head_data != null ? this._head_data.name : "",15,16763955,"center",150,29);
         _txt_1.pivotX = _txt_1.width >> 1;
         _txt_1.y = _info.y + _info.height - 10;
         _txt_2 = GlobalTextStyle.getTextField(_head_data != null ? GlobalData.$mConfig_zones[_head_data.zone][0] : "",15,16763955,"center",150,29);
         _txt_2.pivotX = _txt_2.width >> 1;
         _txt_2.y = _txt_1.y + _txt_1.height - 10;
         _loc4_ = GlobalFunction.createImage("UI_extreme_bg_0170000");
         _loc4_.pivotX = _loc4_.width * 0.5;
         _loc4_.x = _info.x;
         _loc4_.y = _info.y + 2;
         this.addChild(_loc4_);
         this.addChild(_info);
         this.addChild(_txt_1);
         this.addChild(_txt_2);
      }
      else
      {
         _txt_1 = GlobalTextStyle.getTextField(_head_data != null ? this._head_data.name : "",15,_user_num == 1 ? 13818334 : 13799726,"center",150,29);
         _txt_1.pivotX = _txt_1.width >> 1;
         _txt_1.y = _loc1_.y + _loc1_.height - 15;
         _txt_2 = GlobalTextStyle.getTextField(_head_data != null ? GlobalData.$mConfig_zones[_head_data.zone][0] : "",15,_user_num == 1 ? 13818334 : 13799726,"center",150,29);
         _txt_2.pivotX = _txt_2.width >> 1;
         _txt_2.y = _txt_1.y + _txt_1.height - 10;
         _loc4_ = GlobalFunction.createImage("UI_extreme_bg_0170000");
         _loc4_.pivotX = _loc4_.width * 0.5;
         _loc4_.x = _txt_1.x;
         _loc4_.y = _txt_1.y + 2;
         _loc4_.height *= 0.7;
         this.addChild(_loc4_);
         this.addChild(_txt_1);
         this.addChild(_txt_2);
      }
      this.addEventListener("touch",onTOUCH);
   }
   
   private function onREMOVED_FROM_STAGE(param1:Event) : void
   {
      StarlingTools.removeChildrenClear(this);
      this.removeEventListener("removedFromStage",onREMOVED_FROM_STAGE);
   }
   
   protected function onTOUCH(param1:TouchEvent) : void
   {
      var _loc2_:Touch = null;
      if(_head_data != null)
      {
         _loc2_ = param1.getTouch(this,"ended");
         if(_loc2_)
         {
            GlobalData.$pvp_rival = {
               "data":this._head_data.data,
               "name":_head_data.name,
               "lv":_head_data.lv
            };
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_change_pvp",false,true);
            return;
         }
      }
   }
   
   public function set scale(param1:Number) : void
   {
      this.scaleX = this.scaleY = param1;
   }
}
