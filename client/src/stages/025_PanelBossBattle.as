package com.meng52.game.ui.panel
{
   import com.meng52.display.ProgressBar;
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.map.GameMapConfig;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.element.ItemBossRank;
   import com.meng52.game.ui.element.ItemBossTeam;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.game.ui.element.LOL_TextField;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.data.ListCollection;
   import feathers.display.Scale9Image;
   import feathers.layout.VerticalLayout;
   import feathers.textures.Scale9Textures;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import starling.animation.Juggler;
   import starling.display.DisplayObject;
   import starling.display.Image;
   import starling.display.MovieClip;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.EnterFrameEvent;
   import starling.events.Event;
   import starling.text.TextField;
   import starling.utils.deg2rad;
   
   public class PanelBossBattle extends PanelBossInfo
   {
      
      public static var mTimer_count:int;
      
      private var mBlood_halfA:ProgressBar;
      
      private var mBlood_halfB:ProgressBar;
      
      private var mBoss:Image;
      
      private var mBoss_red:Image;
      
      private var mBoss_white:Image;
      
      private var mBoss_box:Sprite;
      
      private var mService_status:Boolean = false;
      
      private var mService_fight:Boolean = false;
      
      private var mService:Boolean = false;
      
      private var mTxt_enhance:LOL_TextField;
      
      private var mTxt_timer:TextFieldHtmlRenderer;
      
      private var _timer:Image;
      
      private var mTxt_coin:TextField;
      
      private var mCfg_boss:Object;
      
      private var mBox_reSuper:Sprite;
      
      private var mBox_re:Sprite;
      
      private var mReportArr:Array;
      
      private var mReportArrTemp:Array;
      
      private var mReportIndex:int = 0;
      
      private var mBox_report:Sprite;
      
      private var mTimer_report:Number = 0;
      
      private const mReport_w:Number = 310;
      
      private const mReport_h:Number = 200;
      
      private var mJuggler_report:Juggler;
      
      private var mJuggler_other:Juggler;
      
      private var mJuggler_boss:Juggler;
      
      private var mJuggler_reLife:Juggler;
      
      private var mJuggler_bossOver:Juggler;
      
      private var mRe_status:int = 0;
      
      private var mClip_boss:MovieClip;
      
      private var mClip_boss_status:int = 0;
      
      private var mClip_boss_timer:Number = 0;
      
      private var mClip_boss_frame:Number = 0;
      
      private var mClip_boss_bg:Quad;
      
      private var mClip_boss_blood:Scale9Image;
      
      private var mClip_boss_xx:Number;
      
      private var mClip_boss_yy:Number;
      
      private var mBg_stage:Image;
      
      private var mBg_stage_yy:Number = 0;
      
      private var mClip_reLife_b:Boolean = false;
      
      private var mBossIsOver:Boolean = false;
      
      private var mBossIsBlood:Boolean = false;
      
      private var mTimer_report_cfg:Number = 0;
      
      private var _sp_Time:Sprite = new Sprite();
      
      private var _bgCoin:Image;
      
      private var mBtn_inter2:LOL_Button;
      
      private var _mTxt_currentCoin:LOL_MutilTextFieldIcon;
      
      private var _mBox:Sprite;
      
      private var mTxtLast:LOL_TextField;
      
      public function PanelBossBattle()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         GlobalData.$mEventDispatcher.addEventListener("update_shop_coin",updateCoin);
         this.setHeaderFun("","",true);
         this.mBtn_back.textPoint = new Point(0,-3);
         setUIboss();
      }
      
      private function updateCoin(param1:Event) : void
      {
         _mTxt_currentCoin.txt2 = GlobalData.$userData.coin;
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalData.$mEventDispatcher.removeEventListener("update_shop_coin",updateCoin);
         LayoutUIAnimation.getOnlyExample().clear();
         clearClip_boss();
         mService = false;
         mService_status = false;
         mService_fight = false;
         mBossIsBlood = false;
         SendAndSelect.$serviceTimeCallFunBySec = null;
         removeEventListener("enterFrame",onENTER_FRAME_boss);
         if(mJuggler_report)
         {
            mJuggler_report.purge();
         }
         if(mJuggler_reLife)
         {
            mJuggler_reLife.purge();
         }
         if(mJuggler_other)
         {
            mJuggler_other.purge();
         }
         if(mJuggler_bossOver)
         {
            mJuggler_bossOver.purge();
         }
         if(mBoss_red)
         {
            if(mBoss_red.filter)
            {
               mBoss_red.filter.clearCache();
               mBoss_red.filter.dispose();
            }
            mBoss_red.removeFromParent(true);
         }
         if(mBoss_white)
         {
            if(mBoss_white.filter)
            {
               mBoss_white.filter.clearCache();
               mBoss_white.filter.dispose();
            }
            mBoss_white.removeFromParent(true);
         }
         if(mBoss)
         {
            mBoss.removeFromParent(true);
         }
         if(mBoss_box)
         {
            mBoss_box.removeFromParent(true);
         }
         if(mBlood_halfA)
         {
            mBlood_halfA.removeFromParent(true);
            mBlood_halfA.dispose();
         }
         if(mBlood_halfB)
         {
            mBlood_halfB.removeFromParent(true);
            mBlood_halfB.dispose();
         }
         if(mBg_stage)
         {
            mBg_stage.removeFromParent(true);
         }
         super.onREMOVED_FROM_STAGE(param1);
         mBg_stage = null;
         mBoss_red = null;
         mBoss_white = null;
         mJuggler_reLife = null;
         mBoss_box = null;
         mJuggler_other = null;
         mJuggler_bossOver = null;
         mJuggler_report = null;
         mBoss = null;
         mBlood_halfA = null;
         mBlood_halfB = null;
         mReportArr = null;
         mReportArrTemp = null;
         GlobalData.$mGameClassObject.mLayoutUITop.visible = GlobalData.$mGameClassObject.mLayoutUIBottom.visible = true;
         SoundManager.getOnlyExample().setAllMusic(false);
         SoundManager.getOnlyExample().playMusic(SoundManager.SOUND_MAIN);
         GlobalFunction.delTextureByBD("UI_boss_bg_1_");
      }
      
      override public function onBTN_NAME_BACK() : void
      {
         GlobalData.$tempMazeSelect = "zone_boss";
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_maze");
      }
      
      private function setUIboss() : void
      {
         this.addEventListener("enterFrame",onENTER_FRAME_boss);
         mJuggler_report = new Juggler();
         mJuggler_other = new Juggler();
         mJuggler_reLife = new Juggler();
         mBossIsBlood = false;
         mBossIsOver = false;
         mClip_boss_status = 0;
         mTimer_report = 0;
         mReportIndex = 0;
         mReportArr = [];
         mReportArrTemp = [];
         mService = true;
         mCfg_boss = GlobalData.$mConfig_simple.zone_boss;
         mTimer_report_cfg = mCfg_boss.report_timer ? mCfg_boss.report_timer : 10;
         SendAndSelect.$serviceTimeCallFunBySec = null;
         GlobalData.$mGameClassObject.mLayoutUITop.visible = GlobalData.$mGameClassObject.mLayoutUIBottom.visible = false;
         if(this.mHeader)
         {
            this.mHeader.removeFromParent(true);
            this.mHeader = null;
         }
         mBox_a = new Sprite();
         addChildAt(mBox_a,0);
         mBg_stage = GlobalFunction.createImage("UI_boss_bg_1_",true);
         mBg_stage.blendMode = "none";
         mBg_stage.touchable = false;
         mBg_stage.y = mBg_stage_yy = -110;
         mBox_a.addChild(mBg_stage);
         var _loc1_:Scale9Image = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",GlobalData.$mStageWidth + 5,260,new Rectangle(110,55,70,20));
         _loc1_.touchable = false;
         _loc1_.y = GlobalData.$center_height_curr - _loc1_.height;
         mBox_a.addChild(_loc1_);
         var _loc8_:Quad = new Quad(2,_loc1_.height - 30,10120765);
         _loc8_.x = _loc1_.x + 10 + _loc1_.width * 0.5;
         _loc8_.y = _loc1_.y + (_loc1_.height - _loc8_.height) * 0.5;
         mBox_a.addChild(_loc8_);
         mBtn_inter2 = GlobalFunction.createButtonStarling("UI_boss_btn_fight_0000");
         mBtn_inter2.x = int((GlobalData.$mStageWidth - mBtn_inter2.width) * 0.5);
         mBtn_inter2.y = _loc1_.y - mBtn_inter2.height + 2;
         mBtn_inter2.addEventListener("triggered",onTRIGGERED_fight);
         addChild(mBtn_inter2);
         var _loc11_:TextField = GlobalFunction.createTextField(160,40,GlobalLanguageStr.getStr(90405),"",20,1118481);
         _loc11_.x = _loc8_.x + 2;
         _loc11_.y = mBtn_inter2.y + mBtn_inter2.height + 10 + 5;
         this.addChild(_loc11_);
         mBox_re = new Sprite();
         mBox_reSuper = new Sprite();
         var _loc12_:LOL_Button = GlobalFunction.createButtonStarling("UI_boss_reborn_0000");
         mBox_reSuper.visible = false;
         _loc12_.addEventListener("triggered",onTRIGGERED_rebornSuper);
         var _loc2_:LOL_Button = GlobalFunction.createButtonStarling("UI_boss_reborn_super_0000");
         mBox_re.visible = false;
         _loc2_.addEventListener("triggered",onTRIGGERED_reborn);
         mBox_reSuper.addChild(_loc12_);
         mBox_re.addChild(_loc2_);
         addChild(mBox_reSuper);
         addChild(mBox_re);
         mBox_reSuper.x = 0;
         mBox_reSuper.y = _loc1_.y - _loc12_.height + 5;
         mBox_re.x = GlobalData.$mStageWidth - _loc2_.width;
         mBox_re.y = _loc1_.y - _loc2_.height + 5;
         var _loc5_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(20372,int(mCfg_boss.super_relive * 100)),165,35);
         _loc5_.fontSize = 20;
         _loc5_.fontColor = 16777215;
         _loc5_.hAlign = "center";
         _loc5_.shadowFilter();
         _loc5_.touchable = false;
         _loc5_.y = _loc12_.height - _loc5_.height - 5;
         mBox_reSuper.addChild(_loc5_);
         var _loc9_:int = 120;
         var _loc10_:int = 10;
         var _loc14_:LOL_MutilTextFieldIcon = new LOL_MutilTextFieldIcon("",mCfg_boss.relive_coin[1],"UI_money_coin_0_0000");
         _loc14_.shadowFilter();
         mBox_reSuper.addChild(_loc14_);
         _loc14_.x = MainConfig.$isEA ? _loc9_ + 35 : _loc9_ + 20;
         _loc14_.y = mBox_reSuper.height - _loc14_.height;
         var _loc13_:LOL_MutilTextFieldIcon = new LOL_MutilTextFieldIcon("",mCfg_boss.relive_coin[0],"UI_money_coin_0_0000");
         _loc13_.shadowFilter();
         mBox_re.addChild(_loc13_);
         _loc13_.x = 80;
         _loc13_.y = mBox_re.height - _loc14_.height;
         var _loc6_:Image = GlobalFunction.createImage("UI_boss_bg_0_0000");
         _loc6_.touchable = false;
         _loc6_.y = mBtn_inter2.y - 30 - 5;
         addChild(_loc6_);
         mTxtLast = new LOL_TextField("",_loc6_.width,35);
         mTxtLast.fontSize = MainConfig.$isEnglish ? 17 : 20;
         mTxtLast.fontColor = 16777215;
         mTxtLast.hAlign = "center";
         mTxtLast.shadowFilter();
         mTxtLast.touchable = false;
         mTxtLast.x = MainConfig.$isEnglish ? _loc6_.width - mTxtLast.width + 70 : _loc6_.width - mTxtLast.width + 150;
         mTxtLast.y = _loc6_.y;
         addChild(mTxtLast);
         var _loc7_:Image = GlobalFunction.createImage("UI_boss_bg_5_0000");
         _loc7_.touchable = false;
         _loc7_.y = _loc6_.y - 20;
         var _loc3_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(20368),_loc7_.width,35);
         _loc3_.fontSize = MainConfig.$isEnglish ? 18 : 20;
         _loc3_.fontColor = 16777215;
         _loc3_.hAlign = "left";
         _loc3_.shadowFilter();
         _loc3_.touchable = false;
         _loc3_.x = _loc6_.x + 20;
         _loc3_.y = _loc6_.y;
         addChild(_loc3_);
         var _loc4_:Rectangle = _loc3_.textBounds;
         mTxt_enhance = new LOL_TextField("",180,46);
         mTxt_enhance.fontSize = 20;
         mTxt_enhance.fontColor = 16777215;
         mTxt_enhance.hAlign = "left";
         mTxt_enhance.shadowFilter();
         mTxt_enhance.touchable = false;
         mTxt_enhance.x = _loc3_.x + _loc4_.width + 10;
         mTxt_enhance.y = _loc3_.y + _loc4_.height - 46 + 16;
         addChild(mTxt_enhance);
         _mBox = new Sprite();
         _mBox.visible = false;
         _mBox.touchable = false;
         _bgCoin = GlobalFunction.createImage("UI_wordbg_yellow_0_0000");
         _bgCoin.scaleX = _bgCoin.scaleY = 1.2;
         _mBox.addChild(_bgCoin);
         _mBox.x = mBtn_inter2.x + mBtn_inter2.width * 0.5 - _bgCoin.width * 0.5;
         _mBox.y = mBtn_inter2.y + 20;
         addChild(_mBox);
         _mTxt_currentCoin = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getStr(90406),GlobalData.$userData.coin,"UI_money_coin_0_0000",1513239,1513239);
         _mTxt_currentCoin.x = _bgCoin.x + 40;
         _mTxt_currentCoin.y = _bgCoin.y + 2;
         _mBox.addChild(_mTxt_currentCoin);
         _timer = GlobalFunction.createImage("UI_activity_time_0000");
         _timer.x = MainConfig.$isEnglish ? _mTxt_currentCoin.x + _timer.width / 2 - 50 : _mTxt_currentCoin.x + _timer.width / 2 + 20;
         _timer.y = _mTxt_currentCoin.y + _mTxt_currentCoin.height + 10;
         _mBox.addChild(_timer);
         mTxt_timer = GlobalTextStyle.getHtmlTextRenderer();
         mTxt_timer.filter = GlobalFunction.getShadowFilters();
         mTxt_timer.x = _timer.x + _timer.width;
         mTxt_timer.y = _timer.y - 2;
         _mBox.addChild(mTxt_timer);
         mBlood_halfA = new ProgressBar(GlobalFunction.getTexture("UI_boss_blood_bg_0000"),GlobalFunction.getTexture("UI_boss_blood_bar_0000"),{
            "f":13,
            "s":18,
            "x":0,
            "y":0
         });
         mBlood_halfA.addTop(GlobalFunction.getTexture("UI_boss_bar_light_0_0000"),-2);
         mBlood_halfA.mTop.x = mBlood_halfA.width - 30;
         mBlood_halfA.touchable = false;
         addChild(mBlood_halfA);
         mBlood_halfA.mTop.visible = false;
         mBlood_halfB = new ProgressBar(GlobalFunction.getTexture("UI_boss_blood_bg_0000"),GlobalFunction.getTexture("UI_boss_blood_bar_0000"),{
            "f":13,
            "s":18,
            "x":0,
            "y":0
         });
         mBlood_halfB.addTop(GlobalFunction.getTexture("UI_boss_bar_light_0_0000"),-2);
         mBlood_halfB.mTop.x = mBlood_halfB.width - 30;
         mBlood_halfB.touchable = false;
         addChild(mBlood_halfB);
         mBlood_halfA.x = mBlood_halfB.x = 8;
         mBlood_halfA.y = mBg_stage.y + 10;
         mBlood_halfB.y = mBlood_halfA.y + 30;
         mBoss = GlobalFunction.createImage("UI_boss_ui_0_0000");
         mBoss_red = GlobalFunction.createImage("UI_boss_ui_0_0000");
         mBoss_white = GlobalFunction.createImage("UI_boss_ui_0_0000");
         mBoss_white.blendMode = Tools.getBlendMode(null,1.9,1.9,1.9);
         mBoss_red.blendMode = Tools.getBlendMode(null,1.9,1,1);
         mBoss_white.pivotX = mBoss_red.pivotX = mBoss.pivotX = mBoss.width * 0.5;
         mBoss_white.pivotY = mBoss_red.pivotY = mBoss.pivotY = mBoss.height * 0.5;
         mBoss_white.x = mBoss_red.x = mBoss.x = mClip_boss_xx = GlobalData.$mStageWidth * 0.5;
         mBoss_white.y = mBoss_red.y = mBoss.y = mClip_boss_yy = mBoss.height * 0.5 - 90;
         mBoss_red.visible = false;
         mBoss_white.visible = false;
         mBoss_box = new Sprite();
         mBoss_box.clipRect = new Rectangle(0,-90,GlobalData.$mStageWidth,mBoss.height);
         mBoss_box.addChild(mBoss);
         mBoss_box.addChild(mBoss_red);
         mBoss_box.addChild(mBoss_white);
         addChildAt(mBoss_box,1);
         mBtn_back.y = -mBtn_back.height + 20;
         mBox_report = new Sprite();
         mBox_report.touchable = true;
         mBox_report.clipRect = new Rectangle(0,0,310,200);
         mBox_report.x = _loc1_.x + 15;
         mBox_report.y = _loc1_.y + 25;
         addChild(mBox_report);
         mTimer_count = 0;
         mService_status = true;
         sendEnter(reService_status);
         SoundManager.getOnlyExample().setAllMusic(false);
         SoundManager.getOnlyExample().playMusic(SoundManager.SOUND_COMBAT_4);
      }
      
      private function reService_status(param1:Object) : void
      {
         mService_status = false;
         mTimer_count = 0;
         mBoss_data = param1.data;
         timerFun();
         check_other();
         setRankList();
         setFightOther();
         if(mBoss_data.is_end)
         {
            SendAndSelect.$serviceTimeCallFunBySec = null;
         }
         else if(SendAndSelect.$serviceTimeCallFunBySec == null)
         {
            SendAndSelect.$serviceTimeCallFunBySec = timerFun;
         }
      }
      
      private function timerFun() : void
      {
         if(mService)
         {
            mTimer_count += 1;
            if(mTimer_count >= mTimer_report_cfg)
            {
               mTimer_count = 0;
               sendService(reService_status);
            }
            else if(!mService_status)
            {
               check_selfFight();
            }
            mTimer_report += 1;
            if(mTimer_report % 2 == 0)
            {
               setReport();
            }
         }
      }
      
      private function onTRIGGERED_fight(param1:Event) : void
      {
         var _loc2_:int = 0;
         var _loc3_:LOL_Button = param1.currentTarget as LOL_Button;
         if(_loc3_.enabled)
         {
            _loc2_ = 0;
            if(mBoss_data && mBoss_data.attack_log)
            {
               _loc2_ = int(mBoss_data.attack_log.attack_num);
            }
            SendServiceAMFFun.send_user_attack_zoneboss(reService_fight,{"attack_num":_loc2_});
         }
      }
      
      private function onTRIGGERED_rebornSuper(param1:Event) : void
      {
         checkReborn(1);
      }
      
      private function onTRIGGERED_reborn(param1:Event) : void
      {
         checkReborn(0);
      }
      
      private function checkReborn(param1:int = 0) : void
      {
         var _loc3_:Object = null;
         var _loc4_:int = 0;
         _loc4_ = 22;
         var _loc2_:Array = GlobalData.$mConfig_simple.zone_boss.relive_coin as Array;
         var _loc5_:int = int(_loc2_[param1]);
         if(GlobalData.$userData.coin >= _loc5_)
         {
            if(param1 == 0)
            {
               _loc3_ = {
                  "ok":send_user_reborn,
                  "no":GlobalFunction.functionNull
               };
               GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90136,_loc5_),GlobalTextStyle.COLOR_W_Y_Y_G),_loc3_);
            }
            else
            {
               _loc3_ = {
                  "ok":send_user_super_reborn,
                  "no":GlobalFunction.functionNull
               };
               GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90137,_loc5_,GlobalData.$mConfig_simple.zone_boss.super_relive * 100),GlobalTextStyle.COLOR_W_Y_Y_G),_loc3_);
            }
         }
         else
         {
            GlobalFunction.popErrorCoin(_loc5_);
         }
      }
      
      private function send_user_super_reborn() : void
      {
         SendServiceAMFFun.send_user_super_reborn(reService_reborn);
      }
      
      private function send_user_reborn() : void
      {
         SendServiceAMFFun.send_user_reborn(reService_reborn);
      }
      
      private function reService_fight(param1:Object) : void
      {
         if(this.stage == null) return;
         var _loc2_:Object = null;
         mTimer_count = 0;
         mTxt_timer.visible = true;
         _timer.visible = true;
         mBoss_data.boss = param1.data.boss;
         mBoss_data.attack_log = param1.data.attack_log;
         mBoss_data.rank_list = param1.data.rank_list;
         mBoss_data.report_list = param1.data.report_list;
         if(param1.data.equip != null)
         {
            for(var _loc3_:Object in param1.data.equip)
            {
               if(!GlobalFunction.isVersionedProfileReceipt(param1))
               {
               GlobalData.$userData.my_equips[_loc3_.toString()] = param1.data.equip[_loc3_];
               }
            }
         }
         if(param1.data.kill_gifts != null)
         {
            _loc2_ = param1.data.kill_gifts;
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.medal = _loc2_.medal;
            }
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateExp();
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateEn();
         }
         if(param1.data.gold != null)
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.gold = param1.data.gold;
            }
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
         }
         if(param1.data.mark != null)
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.mark = param1.data.mark;
            }
         }
         if(param1.data.coin != null)
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.coin = param1.data.coin;
            }
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
         }
         if(param1.data.attrs != null && GlobalData.$userData.attrs != null)
         {
            for(var _attrKey:String in param1.data.attrs)
            {
               if(param1.data.attrs[_attrKey] != null)
               {
                  if(!GlobalFunction.isVersionedProfileReceipt(param1))
                  {
                  GlobalData.$userData.attrs[_attrKey] = param1.data.attrs[_attrKey];
                  }
               }
            }
         }
         if(!mBossIsOver)
         {
            check_selfFight();
            check_other();
            setRankList();
            setFightOther();
            if(param1.data.attack_hp > 0)
            {
               setFightSelf(param1.data.attack_hp);
               clearClip_boss();
               mJuggler_boss = new Juggler();
               check_teamClip(1);
               if(!param1.data.boss.is_end)
               {
                  mClip_reLife_b = false;
               }
            }
         }
      }
      
      private function reService_reborn(param1:Object) : void
      {
         if(this.stage == null) return;
         mTimer_count = 0;
         mBox_reSuper.pivotX = 0;
         mBox_re.pivotX = 0;
         mJuggler_reLife.tween(mBox_reSuper,0.1,{"pivotX":mBox_reSuper.width});
         mJuggler_reLife.tween(mBox_re,0.1,{
            "pivotX":-mBox_re.width,
            "onComplete":onComplete_reLife
         });
         mBoss_data.boss.is_end = param1.data.is_end;
         if(param1.data["boss"] != null)
         {
            if(param1.data.is_end == true)
            {
               mBoss_data.boss = param1.data.boss;
            }
         }
         mBoss_data.attack_log = param1.data.attack_log;
         if(GlobalData.$userData.coin != param1.data.coin)
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalFunction.payCoinVip(GlobalData.$userData.coin - param1.data.coin);
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.coin = param1.data.coin;
            }
         }
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
         mRe_status = param1["method"] == "user.reborn" ? 1 : 2;
         check_selfFight();
         check_other();
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
         GlobalData.$userData.coin = param1.data.coin;
         }
         if(_mTxt_currentCoin)
         {
            _mTxt_currentCoin.txt2 = GlobalData.$userData.coin;
         }
      }
      
      private function check_teamClip(param1:int) : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc4_:ItemBossTeam = null;
         if(mBox_team)
         {
            _loc2_ = 0;
            _loc3_ = mBox_team.numChildren;
            _loc2_ = 0;
            while(_loc2_ < _loc3_)
            {
               _loc4_ = mBox_team.getChildAt(_loc2_) as ItemBossTeam;
               if(param1 == 0)
               {
                  _loc4_.setClip_reLife(mRe_status);
               }
               else if(param1 == 1)
               {
                  _loc4_.setClip_fight(mBox_team.y - mBoss.y,mBtn_inter2);
               }
               else if(param1 == 2)
               {
                  _loc4_.clearClip_fight();
               }
               else if(param1 == 3)
               {
                  _loc4_.setClip_del();
               }
               _loc2_++;
            }
            mRe_status = 0;
         }
      }
      
      private function check_selfFight() : void
      {
         var _loc20_:Array = null;
         var _loc22_:Array = null;
         var _loc10_:* = 0;
         var _loc7_:int = 0;
         var _loc21_:Object = null;
         var _loc19_:ItemBossTeam = null;
         var _loc17_:int = 0;
         var _loc11_:Number = NaN;
         var _loc13_:Number = NaN;
         var _loc8_:Number = NaN;
         var _loc12_:Number = NaN;
         var _loc1_:Number = NaN;
         var _loc18_:Number = NaN;
         var _loc6_:Number = NaN;
         if(mBossIsOver)
         {
            mService = false;
            return;
         }
         var _loc15_:Boolean = false;
         var _loc2_:Boolean = Boolean(mBoss_data.boss.is_end);
         if(_loc2_ && !mBossIsOver)
         {
            this.touchable = false;
            mService = false;
            mBossIsOver = true;
            if(mJuggler_other)
            {
               mJuggler_other.purge();
            }
            clearClip_boss();
            check_teamClip(2);
            if(mBoss_data.boss.killed_by == GlobalData.$userData.uid && mBoss_data.boss.current_hp <= 0)
            {
               _loc15_ = true;
            }
         }
         var _loc4_:Number = SendAndSelect.$systemTimer_nowSecond;
         var _loc14_:Number = _loc4_ * 1000;
         var _loc3_:Number = (mBoss_data.attack_log.next_attack_time as Date).time;
         var _loc5_:Boolean = false;
         if(_loc14_ >= _loc3_)
         {
            _loc5_ = true;
         }
         if(mBox_team == null)
         {
            _loc20_ = GlobalData.$userData.team as Array;
            _loc22_ = _loc20_[0];
            _loc10_ = 0;
            _loc7_ = int(_loc22_.length);
            _loc21_ = null;
            _loc17_ = 0;
            mBox_team = new Sprite();
            _loc10_ = 0;
            while(_loc10_ < _loc7_)
            {
               if(_loc22_[_loc10_] != null)
               {
                  _loc21_ = GlobalData.$userData.avatars[_loc22_[_loc10_]];
                  _loc21_["id"] = _loc22_[_loc10_];
                  _loc19_ = new ItemBossTeam();
                  _loc19_.data = _loc21_;
                  _loc19_.x = 115 * _loc17_;
                  _loc17_ += 1;
                  mBox_team.addChild(_loc19_);
               }
               _loc10_++;
            }
            mBox_team.x = int((GlobalData.$mStageWidth - 115 * _loc17_) * 0.5) + 10;
            _loc11_ = mBoss.y + mBoss.height * 0.5;
            _loc13_ = mBtn_inter2.y - 150;
            mBox_team.y = _loc11_ > _loc13_ ? _loc13_ : _loc11_;
            addChild(mBox_team);
         }
         var _loc9_:String = GlobalLanguageStr.getLanguageStr(20363,mBoss_data.attack_log.attack_num,mBoss_data.attack_log.attack_hp);
         if(_loc9_ != mTxtLast.text)
         {
            mTxtLast.text = _loc9_;
         }
         var _loc16_:String = 100 + mBoss_data.attack_log.enhance + "%";
         if(mTxt_enhance)
         {
            if(mTxt_enhance.text != _loc16_)
            {
               mTxt_enhance.text = _loc16_;
            }
         }
         if(mBtn_inter2.enabled != _loc5_)
         {
            mBtn_inter2.enabled = _loc5_;
            if(!_loc5_)
            {
               check_teamClip(3);
            }
            else
            {
               check_teamClip(0);
            }
         }
         _mBox.visible = !_loc5_;
         mBox_reSuper.visible = false;
         mBox_re.visible = false;
         if(!_loc5_)
         {
            _loc8_ = _loc3_ * 0.001;
            _loc12_ = Number(mCfg_boss.min_relive_time);
            _loc1_ = Number(mCfg_boss.relive_time);
            _loc18_ = _loc8_ - _loc1_ + _loc12_;
            _loc6_ = 0;
            _loc18_ = Math.ceil(_loc18_ - (_loc4_ - 1));
            _loc18_ = _loc18_ > 0 ? _loc18_ : 0;
            if(_loc18_ > 0)
            {
               mTxt_timer.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20369,_loc18_),[16777215,16764006,16777215,16764006],20,20);
            }
            else
            {
               mBox_reSuper.visible = true;
               mBox_re.visible = true;
               _mBox.visible = true;
               if(!mClip_reLife_b)
               {
                  mClip_reLife_b = true;
                  mBox_reSuper.pivotX = mBox_reSuper.width;
                  mBox_re.pivotX = -mBox_re.width;
                  mJuggler_reLife.tween(mBox_reSuper,0.3,{
                     "transition":"easeOutBack",
                     "pivotX":0
                  });
                  mJuggler_reLife.tween(mBox_re,0.3,{
                     "transition":"easeOutBack",
                     "pivotX":0,
                     "onComplete":onComplete_reLife
                  });
               }
               _loc6_ = Math.ceil(_loc8_ - _loc4_);
               if(_loc6_ > 0)
               {
                  mTxt_timer.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20370,_loc6_),[16777215,16764006,16777215,16764006],20,20);
               }
            }
         }
         if(_loc2_ && !_loc15_)
         {
            setClip_bossOver();
         }
      }
      
      private function check_blood() : void
      {
         var _loc2_:Number = NaN;
         var _loc3_:Number = NaN;
         var _loc4_:Number = NaN;
         var _loc1_:Number = NaN;
         if(!mBoss)
         {
            return;
         }
         if(mBoss_data)
         {
            if(mBoss_data.boss)
            {
               _loc2_ = Number(mBoss_data.boss.max_hp);
               _loc3_ = Math.round(_loc2_ * 0.5);
               _loc4_ = Number(mBoss_data.boss.current_hp);
               _loc1_ = 0;
               if(_loc4_ < _loc2_)
               {
                  if(_loc4_ > _loc3_)
                  {
                     _loc1_ = (_loc4_ - _loc3_) / _loc3_;
                     mBlood_halfB.setClip(_loc1_);
                     mBlood_halfB.setRatio(_loc1_);
                     mBlood_halfA.setRatio(1);
                  }
                  else
                  {
                     mBlood_halfA.mTop.visible = true;
                     _loc1_ = _loc4_ / _loc3_;
                     mBlood_halfA.setClip(_loc1_);
                     mBlood_halfA.setRatio(_loc1_);
                     mBlood_halfB.setRatio(0);
                  }
               }
            }
         }
      }
      
      private function check_other() : void
      {
         var _loc1_:Array = null;
         if(mBoss_data)
         {
            _loc1_ = mBoss_data.report_list as Array;
            if(_loc1_ != null && _loc1_.length > 0)
            {
               _loc1_ = _loc1_.reverse();
               if(!mReportArr)
               {
                  mReportArr = [];
               }
               else if(mReportArr && mReportArr.length > 50)
               {
                  mReportIndex = 0;
                  mReportArr = _loc1_;
               }
               else
               {
                  mReportArr = mReportArr.concat(_loc1_);
               }
            }
         }
      }
      
      private function setReport() : void
      {
         var _data:Object;
         var _id:String;
         var _str:String;
         var _txt:TextFieldHtmlRenderer;
         if(mReportArr != null && mReportArr.length > 0)
         {
            if(mReportIndex < mReportArr.length)
            {
               _data = mReportArr[mReportIndex];
               if(mBox_report)
               {
                  _id = String(_data.data.id);
                  _str = GlobalLanguageStr.getLanguageStr(_data.type,_data.data);
                  if(mReportArrTemp.indexOf(_id) < 0)
                  {
                     mReportArrTemp.push(_id);
                     mJuggler_report.purge();
                     mReportIndex += 1;
                     _txt = GlobalTextStyle.getHtmlTextRenderer();
                     _txt.width = 310;
                     _txt.text = Tools.formatLineX(_str,[1513239,1513239,13056,10027008],14,20);
                     _txt.x = 10;
                     _txt.y = 200;
                     mBox_report.addChild(_txt);
                     _txt.mLayoutFun = function():void
                     {
                        var _loc1_:DisplayObject = null;
                        var _loc3_:Rectangle = _txt.getTextSnapshotFrame();
                        var _loc2_:Number = _loc3_.height;
                        var _loc6_:int = 0;
                        var _loc5_:int = mBox_report.numChildren;
                        var _loc4_:Object = null;
                        _loc6_ = 0;
                        while(_loc6_ < _loc5_)
                        {
                           _loc1_ = mBox_report.getChildAt(_loc6_);
                           _loc4_ = {"y":_loc1_.y - _loc2_};
                           if(_loc6_ == _loc5_ - 1)
                           {
                              _loc4_["onComplete"] = delReportUI;
                           }
                           mJuggler_report.tween(_loc1_,0.5,_loc4_);
                           _loc6_++;
                        }
                     };
                  }
                  else
                  {
                     mReportIndex += 1;
                     setReport();
                  }
               }
            }
            else
            {
               mReportIndex = mReportArr.length;
            }
         }
      }
      
      private function delReportUI() : void
      {
         if(mBox_report)
         {
            if(mBox_report.height > 200)
            {
               mBox_report.removeChildAt(0,true);
            }
         }
      }
      
      private function setRankList() : void
      {
         var _loc2_:Object = null;
         var _loc1_:VerticalLayout = null;
         this.delList();
         if(this.mList == null)
         {
            _loc2_ = {
               "paging":0,
               "gap":0,
               "horizontalGap":20,
               "verticalGap":20,
               "paddingTop":0,
               "paddingRight":0,
               "paddingBottom":0,
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
            _loc1_.hasVariableItemDimensions = true;
            this.mList = new List();
            this.mList.isSelectable = false;
            this.mList.width = 280;
            this.mList.height = 190;
            this.mList.layout = _loc1_;
            this.mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
            this.mList.x = mBox_report.x + 326;
            this.mList.y = mBox_report.y + 22;
            this.mList.snapScrollPositionsToPixels = true;
            this.addChild(this.mList);
            _loc2_ = null;
            _loc1_ = null;
            this.mList.dataProvider = new ListCollection();
         }
         addList();
      }
      
      override public function addList() : void
      {
         var _loc1_:* = null;
         var _loc4_:Object = null;
         var _loc5_:Array = mBoss_data.rank_list as Array;
         var _loc2_:Array = [];
         var _loc6_:int = 0;
         var _loc3_:int = int(_loc5_.length);
         _loc6_ = 0;
         while(_loc6_ < _loc3_)
         {
            _loc4_ = _loc5_[_loc6_];
            _loc4_["status"] = -1;
            _loc4_["indexID_s"] = _loc6_;
            _loc2_.push(_loc4_);
            _loc6_++;
         }
         if(_loc2_.length > 0)
         {
            this.setListTimer(mList,_loc2_,ItemBossRank,false);
         }
      }
      
      private function onENTER_FRAME_boss(param1:EnterFrameEvent) : void
      {
         var _loc5_:int = 0;
         var _loc2_:Number = NaN;
         var _loc4_:Rectangle = null;
         var _loc6_:Scale9Textures = null;
         var _loc7_:Number = NaN;
         var _loc3_:int = 0;
         if(mJuggler_reLife)
         {
            mJuggler_reLife.advanceTime(param1.passedTime);
         }
         if(mJuggler_report)
         {
            mJuggler_report.advanceTime(param1.passedTime);
         }
         if(mJuggler_other)
         {
            mJuggler_other.advanceTime(param1.passedTime);
         }
         if(mJuggler_boss)
         {
            mJuggler_boss.advanceTime(param1.passedTime);
            if(mClip_boss_status == 0)
            {
               if(mClip_boss_timer >= 120)
               {
                  mBoss_red.visible = false;
                  mBoss_white.visible = false;
                  if(mBossIsOver)
                  {
                     setClip_bossOver();
                  }
                  else
                  {
                     mBg_stage.y = mBg_stage_yy;
                     mBoss.y = mClip_boss_yy;
                     mBoss.alpha = 1;
                     if(mBoss.scaleX >= 1.2)
                     {
                        if(mClip_boss == null)
                        {
                           mClip_boss_bg = Tools.newQuad(GlobalData.$mStageWidth,GlobalData.$mStageHeight,1118481);
                           mClip_boss_bg.y = -110;
                           mClip_boss_bg.alpha = 0.5;
                           addChild(mClip_boss_bg);
                           mClip_boss = DisplayTools.newMc("UI_boss_clip_5_",mBoss.x,mBoss.y + 20,12);
                           _loc5_ = Math.random() > 0.5 ? -1 : 1;
                           mClip_boss.rotation = deg2rad(int(Math.random() * 30 * _loc5_));
                           mClip_boss.scaleX = mClip_boss.scaleY = 2;
                           mClip_boss.loop = false;
                           addChild(mClip_boss);
                           mJuggler_boss.add(mClip_boss);
                           mClip_boss.play();
                        }
                        else if(mClip_boss.isComplete)
                        {
                           mClip_boss_status = 1;
                        }
                     }
                     else
                     {
                        mBoss.scaleX += 0.05;
                        mBoss.scaleY += 0.05;
                     }
                  }
               }
               else
               {
                  mClip_boss_timer += 1;
                  if(mClip_boss_timer <= 76)
                  {
                     if(mClip_boss_timer > 15)
                     {
                        _loc2_ = Math.random() > 0.5 ? 1 : -1;
                        mBg_stage.y = mBg_stage_yy + _loc2_ * 2;
                        mBoss.y = mClip_boss_yy - _loc2_ * 2;
                        mBoss_red.visible = mClip_boss_timer % 2 == 0 ? true : false;
                        mBoss_white.visible = !mBoss_red.visible;
                     }
                  }
                  else
                  {
                     mBoss_red.visible = false;
                     mBoss_white.visible = false;
                  }
               }
            }
            else if(mClip_boss_status == 1)
            {
               if(mClip_boss)
               {
                  mClip_boss.alpha -= 0.15;
                  if(mClip_boss.alpha <= 0)
                  {
                     mJuggler_boss.remove(mClip_boss);
                     mClip_boss.removeFromParent(true);
                     mClip_boss = null;
                     _loc4_ = new Rectangle(80,80,85,85);
                     _loc6_ = new Scale9Textures(GlobalFunction.getTexture("UI_boss_clip_6_0000"),_loc4_);
                     mClip_boss_blood = new Scale9Image(_loc6_);
                     mClip_boss_blood.width = GlobalData.$mStageWidth + 10;
                     mClip_boss_blood.height = GlobalData.$mStageHeight + 10;
                     mClip_boss_blood.y = -110;
                     addChild(mClip_boss_blood);
                     mClip_boss_timer = 0;
                     mClip_boss_frame = 0;
                     mClip_boss_status = 2;
                  }
               }
            }
            else if(mClip_boss_status == 2)
            {
               mBoss.scaleX = 1;
               mBoss.scaleY = 1;
               if(mClip_boss_timer >= 8)
               {
                  mClip_boss_status = 3;
               }
               else
               {
                  mClip_boss_frame += 1;
                  if(mClip_boss_frame % 2 == 0)
                  {
                     mClip_boss_timer += 1;
                     mClip_boss_blood.alpha = mClip_boss_timer % 2 == 0 ? 1 : 0;
                     _loc7_ = Math.random();
                     _loc3_ = mClip_boss_timer % 2 == 0 ? -3 : 3;
                     this.x = _loc3_;
                     this.y = _loc3_;
                  }
               }
            }
            else if(mClip_boss_status == 3)
            {
               this.x = 0;
               this.y = 0;
               check_teamClip(3);
               clearClip_boss();
               mTxt_timer.visible = true;
               _timer.visible = true;
               addChild(_sp_Time);
               _sp_Time.x = GlobalData.$mStageWidth / 3 + 30;
               _sp_Time.y = GlobalData.$mStageHeight / 3 + 160;
            }
         }
         if(mJuggler_bossOver)
         {
            mJuggler_bossOver.advanceTime(param1.passedTime);
            mClip_boss_frame += 1;
            if(mClip_boss_status == 0)
            {
               if(mClip_boss_frame == 1)
               {
                  if(mBoss_data.boss.kill_log != null)
                  {
                     if(String(mBoss_data.boss.kill_log.uid) == String(GlobalData.$userData.uid))
                     {
                        LayoutUIAnimation.getOnlyExample().popSuperWord("50017",2,0.22);
                     }
                  }
               }
               mBoss.x = mClip_boss_xx + (mClip_boss_frame % 2 == 0 ? -5 : 5);
               if(mClip_boss_frame % 2 == 0)
               {
                  mBoss.y += 10;
                  if(mBoss.y >= mClip_boss_yy + mBoss.height + 10)
                  {
                     mClip_boss_frame = 0;
                     mClip_boss_status = 1;
                  }
               }
            }
            else if(mClip_boss_status == 1)
            {
               mClip_boss_frame += 1;
               if(mClip_boss_frame >= 15)
               {
                  mJuggler_bossOver.purge();
                  mJuggler_bossOver = null;
                  LayoutUIAnimation.getOnlyExample().clear();
                  PanelBossEnd.$mBoss_data = mBoss_data;
                  GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_boss_lastaction",false,true);
               }
            }
         }
      }
      
      private function clearClip_boss() : void
      {
         if(mJuggler_boss)
         {
            mJuggler_boss.purge();
         }
         if(mClip_boss)
         {
            mClip_boss.removeFromParent(true);
            mClip_boss.dispose();
         }
         if(mClip_boss_bg)
         {
            mClip_boss_bg.removeFromParent(true);
            mClip_boss_bg.dispose();
         }
         if(mClip_boss_blood)
         {
            mClip_boss_blood.removeFromParent(true);
            mClip_boss_blood.dispose();
         }
         if(mBg_stage)
         {
            mBg_stage.y = mBg_stage_yy;
         }
         if(mBoss)
         {
            mBoss.y = mClip_boss_yy;
            mBoss.alpha = 1;
         }
         mClip_boss_frame = 0;
         mClip_boss_status = 0;
         mClip_boss_timer = 0;
         mJuggler_boss = null;
         mClip_boss = null;
         mClip_boss_bg = null;
         mClip_boss_blood = null;
      }
      
      private function setFightOther() : void
      {
         var _loc3_:Array = null;
         var _loc8_:int = 0;
         var _loc9_:int = 0;
         var _loc6_:int = 0;
         var _loc5_:int = 0;
         var _loc4_:int = 0;
         var _loc10_:int = 0;
         var _loc12_:Object = null;
         var _loc11_:Image = null;
         var _loc13_:Number = NaN;
         var _loc1_:int = 0;
         var _loc2_:int = 0;
         var _loc7_:int = 0;
         if(!mBoss)
         {
            return;
         }
         if(mBoss_data)
         {
            LayoutUIAnimation.getOnlyExample().jugglerA.delayCall(check_blood,0.2);
            if(mBoss_data.report_list != null)
            {
               _loc3_ = mBoss_data.report_list as Array;
               if(_loc3_.length > 0)
               {
                  _loc8_ = GameMapConfig.SCREEN_WIDTH * 0.5;
                  _loc9_ = mBoss.y + mBoss.height * 0.5;
                  _loc4_ = int(_loc3_.length);
                  _loc10_ = Math.random() > 0.5 ? 1 : 0;
                  _loc13_ = 0;
                  mJuggler_other.purge();
                  LayoutUIAnimation.getOnlyExample().show();
                  _loc6_ = 0;
                  while(_loc6_ < _loc4_)
                  {
                     _loc12_ = _loc3_[_loc6_];
                     if(_loc12_.data.uid != GlobalData.$userData.uid)
                     {
                        if(_loc12_.type == "zb_attack" || _loc12_.type == "zb_kill")
                        {
                           _loc11_ = GlobalFunction.createImage("UI_boss_clip_3_0000");
                           _loc11_.pivotX = _loc11_.width * 0.5;
                           _loc11_.pivotY = _loc11_.height;
                           _loc11_.scaleX = 0.4;
                           _loc11_.scaleY = 2;
                           _loc11_.alpha = 0;
                           _loc2_ = _loc9_ - 100 * Math.random() - 70;
                           _loc7_ = int(_loc12_.data.attack_hp);
                           if(_loc10_ % 2 == 0)
                           {
                              _loc11_.rotation = deg2rad(80);
                              _loc8_ = 0;
                              _loc1_ = _loc8_ + 200 * Math.random() + 50;
                              _loc11_.x = -40 + Math.random() * 10;
                              _loc13_ = _loc6_ * 0.4 + Math.random() * 0.2;
                           }
                           else
                           {
                              _loc11_.rotation = deg2rad(-80);
                              _loc8_ = GameMapConfig.SCREEN_WIDTH;
                              _loc1_ = _loc8_ - 200 * Math.random() - 50;
                              _loc11_.x = _loc8_ + 40 - Math.random() * 10;
                              _loc13_ = _loc6_ * 0.4 + 0.2 + Math.random() * 0.2;
                           }
                           LayoutUIAnimation.getOnlyExample().jugglerA.delayCall(LayoutUIAnimation.getOnlyExample().popInjured,_loc13_,"-" + _loc7_,_loc8_,_loc9_,_loc1_,_loc2_,16719904,15,1);
                           LayoutUIAnimation.getOnlyExample().jugglerA.delayCall(SoundManager.getOnlyExample().playSound,_loc13_,"E_8008");
                           _loc5_ = 0;
                           while(_loc5_ < 3)
                           {
                              if(Math.random() > 0.6)
                              {
                                 _loc13_ += 4 * (_loc5_ + 1);
                                 _loc7_ *= 0.9 + Math.random() * 0.2;
                                 LayoutUIAnimation.getOnlyExample().jugglerA.delayCall(LayoutUIAnimation.getOnlyExample().popInjured,_loc13_,"-" + _loc7_,_loc8_,_loc9_,_loc1_,_loc2_,16719904,15,1);
                                 LayoutUIAnimation.getOnlyExample().jugglerA.delayCall(SoundManager.getOnlyExample().playSound,_loc13_,"E_8008");
                              }
                              _loc5_++;
                           }
                           addChild(_loc11_);
                           _loc11_.y = mBoss.y + 120 + Math.random() * 30;
                           mJuggler_other.tween(_loc11_,0.5,{
                              "alpha":1,
                              "delay":_loc13_,
                              "onComplete":onComplete_other,
                              "onCompleteArgs":[_loc11_]
                           });
                           _loc10_ += 1;
                        }
                     }
                     _loc6_++;
                  }
               }
            }
         }
      }
      
      private function onComplete_other(param1:*) : void
      {
         if(param1 != null)
         {
            if(param1 is Image)
            {
               (param1 as Image).removeFromParent(true);
            }
         }
      }
      
      private function onComplete_reLife() : void
      {
         if(mJuggler_reLife)
         {
            mJuggler_reLife.removeTweens(mBox_reSuper);
            mJuggler_reLife.removeTweens(mBox_re);
            mJuggler_reLife.purge();
         }
      }
      
      private function setFightSelf(param1:Number) : void
      {
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc5_:int = 0;
         var _loc4_:Array = null;
         if(mBoss)
         {
            _loc2_ = GameMapConfig.SCREEN_WIDTH / 2;
            _loc3_ = mBoss.y + mBoss.height * 0.5;
            LayoutUIAnimation.getOnlyExample().show();
            LayoutUIAnimation.getOnlyExample().jugglerA.delayCall(LayoutUIAnimation.getOnlyExample().popInjured,2,"-" + param1,_loc2_,_loc3_,_loc2_,_loc3_ - 120,16756800,40,1,"critBg");
            LayoutUIAnimation.getOnlyExample().jugglerA.delayCall(check_blood,2);
            LayoutUIAnimation.getOnlyExample().jugglerA.delayCall(SoundManager.getOnlyExample().playSound,0.5,"E_8007");
            _loc4_ = ["E_9019","E_9010","E_9004"];
            _loc5_ = 0;
            while(_loc5_ < 7)
            {
               LayoutUIAnimation.getOnlyExample().jugglerA.delayCall(SoundManager.getOnlyExample().playSound,_loc5_ * 0.2 + 0.5,Tools.getArrayRandom(_loc4_));
               _loc5_++;
            }
            LayoutUIAnimation.getOnlyExample().jugglerA.delayCall(SoundManager.getOnlyExample().playSound,3.6,"worldBoss1");
            LayoutUIAnimation.getOnlyExample().jugglerA.delayCall(SoundManager.getOnlyExample().playSound,5.5,"E_9021");
         }
      }
      
      private function setClip_bossOver() : void
      {
         if(mJuggler_bossOver == null)
         {
            clearClip_boss();
            mClip_boss_status = 0;
            mClip_boss_timer = 0;
            mClip_boss_frame = 0;
            mJuggler_bossOver = new Juggler();
            SoundManager.getOnlyExample().playSound("E_9020");
            LayoutUIAnimation.getOnlyExample().jugglerA.delayCall(SoundManager.getOnlyExample().playSound,0.5,"worldBoss2");
            SoundManager.getOnlyExample().playSound("worldBoss2");
            SoundManager.getOnlyExample().setAllMusic(false);
            SoundManager.getOnlyExample().playMusic(SoundManager.SOUND_MAIN);
         }
      }
   }
}
