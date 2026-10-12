package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.module.map.GameMap;
   import com.meng52.game.module.map.GameMapConfig;
   import com.meng52.game.module.map.GameMapTools;
   import com.meng52.game.ui.element.ItemBase;
   import com.meng52.game.ui.element.ItemDDAvatar;
   import com.meng52.game.ui.element.ItemTeamEmbattle;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.map.GameMapLayer;
   import com.meng52.game.ui.screen.PanelCenterPVE;
   import com.meng52.game.ui.stage.GuideTools;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   import starling.textures.Texture;
   
   public class PanelPVEembattle extends PanelCenterPVE
   {
      
      public static var lastTime:Number = 0;
      
      public static const MAP_SCALE:Number = 0.9;
      
      public static const BTN_NAME_RANDOM:String = "btn_name_random";
      
      public static const BTN_NAME_PLAY:String = "btn_name_play";
      
      public static const BTN_NAME_APPLY:String = "btn_name_apply";
      
      public static const BTN_NAME_TEAM:String = "btn_name_team";
      
      public static const BTN_NAME_BACK:String = "btn_name_back";
      
      public static const BTN_NAME_SURE:String = "btn_name_sure";
      
      public static const BTN_NAME_CHANGETEAM:String = "btn_name_changeteam";
      
      public var mPanelTeamSet:PanelPVEembattleTeam;
      
      public var mPanelMap:Sprite;
      
      public var mList_drag:Sprite;
      
      public var mArr_drag:Array;
      
      public var mCurr_drag:ItemDDAvatar;
      
      public var mRec_s:Rectangle;
      
      public var mPoint_to:Point;
      
      public var mOffset_drag:Number;
      
      public var mBtn_random:LOL_Scale9Button;
      
      public var mBtn_play:LOL_Scale9Button;
      
      public var mBtn_apply:LOL_Scale9Button;
      
      public var mBtn_team:LOL_Scale9Button;
      
      public var mBtn_changeTeam:LOL_Scale9Button;
      
      public var mExploration_Power:TextField;
      
      private var mBuff_spr:Sprite;
      private var mDefensiveSquadBefore:Array;
      
      private var mBuff_bg:Image;
      
      private var mBuff_txt:TextField;
      
      public var mExploration_Back:LOL_Scale9Button;
      
      public var mTxt_sign:TextField;
      
      public var mFriend:ItemTeamEmbattle;
      
      public var mMap:Sprite;
      
      private var m9x9_bg:Scale9Image;
      
      public function PanelPVEembattle()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         var _loc6_:* = null;
         var _loc10_:Object = null;
         var _loc4_:Object = null;
         var _loc5_:Array = null;
         var _loc9_:int = 0;
         var _loc8_:int = 0;
         this.removeEventListener("addedToStage",initializeHandler);
         var _loc3_:int = GameMapConfig.SCREEN_HEIGHT * 0.35 + 470;
         if(GlobalData.$isPVP)
         {
            if(GlobalData.$pvp_Embattle != "")
            {
               this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(20289) + GlobalData.$pvp_Embattle,_loc3_);
               GlobalData.$pvp_Embattle = "";
            }
            else
            {
               this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(20276),_loc3_);
            }
         }
         else if(GlobalData.$isFragment)
         {
            this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(20419),_loc3_);
         }
         else if(GlobalData.$isExtreme)
         {
            if(!GlobalData.$userData.isGuildWarSaiCheng)
            {
               this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(20278),_loc3_);
            }
            else
            {
               this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(97667),_loc3_);
            }
         }
         else if(GlobalData.$isExploration)
         {
            this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(90554),_loc3_ - 100);
         }
         else if(GlobalData.$isBattleOfThePeak)
         {
            if(GlobalData.$userData.isAttTeam15v15)
            {
               this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(20289) + GlobalData.$userData.otherPlayerName,_loc3_);
            }
            else
            {
               this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(98011,GlobalData.$BattleOfThePeakTeamSelect + 1),_loc3_);
            }
         }
         else
         {
            this.setPopPanelBg("",_loc3_);
         }
         GlobalData.$mEventDispatcher.addEventListener("update_team_pk_list",this.onUPDATE_TEAM_PK_LIST);
         GlobalData.$mEventDispatcher.addEventListener("update_pve_drag_avatar",this.onTouchAvatar);
         GlobalData.$mEventDispatcher.addEventListener("start_pve_drag",this.onSTART_PVE_DRAG);
         GlobalData.$mEventDispatcher.addEventListener("update_pve_drag",this.onUPDATE_PVE_DRAG);
         var _loc7_:Texture = null;
         m9x9_bg = GlobalFunction.getUI_BG_9SLICE_0();
         m9x9_bg.x = int((GlobalData.$mStageWidth - 590) * 0.5);
         m9x9_bg.y = 85;
         m9x9_bg.width = 590;
         m9x9_bg.height = _loc3_ - 385;
         addChild(m9x9_bg);
         this.mBtn_random = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20041),150,70,"UI_btn_normalFun_0000");
         this.mBtn_random.name = "btn_name_random";
         addChild(this.mBtn_random);
         this.mBtn_random.x = int((GlobalData.$mStageWidth - mBtn_random.width) * 0.5);
         this.mBtn_random.y = this.mImg9_baseBg.y + this.mImg9_baseBg.height - mBtn_random.height - 40;
         this.mBtn_random.addEventListener("triggered",onTRIGGERED_);
         this.mBtn_play = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20042),150,70,"UI_btn_normalFun_0000");
         this.mBtn_play.name = "btn_name_play";
         addChild(this.mBtn_play);
         this.mBtn_play.addEventListener("triggered",onTRIGGERED_);
         this.mBtn_team = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20018),150,70,"UI_btn_normalFun_0000");
         mBtn_team.name = "btn_name_team";
         addChild(this.mBtn_team);
         this.mBtn_play.x = this.mBtn_random.x + this.mBtn_random.width + 30;
         this.mBtn_play.y = this.mBtn_random.y;
         this.mBtn_team.addEventListener("triggered",onTRIGGERED_);
         if(GlobalData.$isExploration)
         {
            _loc10_ = GlobalData.$userData.exploration;
            _loc4_ = GlobalFunction.getStage_Mode(_loc10_.stage_mode);
            mBuff_spr = new Sprite();
            this.addChild(mBuff_spr);
            mBuff_bg = GlobalFunction.createImage("UI_wordbg_yellow_0_0000");
            mBuff_bg.width = 560;
            mBuff_spr.addChild(mBuff_bg);
            mBuff_txt = GlobalFunction.createTextField(400,30,GlobalLanguageStr.getLanguageStr(90608,_loc4_["info"]),"",MainConfig.$isEA ? 15 : 20,10027008);
            mBuff_txt.x = mBuff_bg.x + (mBuff_bg.width - mBuff_txt.width) * 0.5;
            mBuff_txt.y = mBuff_bg.y + (mBuff_bg.height - mBuff_txt.height) * 0.5;
            mBuff_spr.addChild(mBuff_txt);
            mBuff_spr.pivotX = mBuff_spr.width * 0.5;
            mBuff_spr.pivotY = mBuff_spr.height * 0.5;
            mBuff_spr.x = this.m9x9_bg.x + m9x9_bg.width * 0.5;
            mBuff_spr.y = this.m9x9_bg.y + this.m9x9_bg.height + 60;
            _loc5_ = GlobalData.$exploration_team_avatar;
            _loc9_ = 0;
            _loc8_ = 0;
            while(_loc8_ < _loc5_.length)
            {
               if(_loc5_[_loc8_] != null)
               {
                  _loc9_ += _loc5_[_loc8_].self_power;
               }
               _loc8_++;
            }
            mExploration_Power = GlobalFunction.createTextField(400,30,GlobalLanguageStr.getLanguageStr(90279) + _loc9_.toString(),"",20,16777215);
            mExploration_Power.pivotX = mExploration_Power.width * 0.5;
            mExploration_Power.pivotY = mExploration_Power.height * 0.5;
            mExploration_Power.x = this.m9x9_bg.x + m9x9_bg.width * 0.5;
            mExploration_Power.y = this.m9x9_bg.y + this.m9x9_bg.height + 15;
            mExploration_Power.hAlign = "center";
            this.addChild(mExploration_Power);
            mBtn_team.visible = false;
            mBtn_team.x = this.mBtn_random.x - mBtn_team.width - 30;
            mBtn_team.y = this.mBtn_random.y;
            mExploration_Back = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20070),150,70,"UI_btn_normalFun_0000");
            mExploration_Back.name = "btn_name_back";
            mExploration_Back.x = mBtn_team.x;
            mExploration_Back.y = mBtn_team.y;
            mExploration_Back.addEventListener("triggered",onTRIGGERED_);
            this.addChild(mExploration_Back);
         }
         else
         {
            mBtn_team.visible = true;
            mBtn_team.x = this.mBtn_random.x - mBtn_team.width - 30;
            mBtn_team.y = this.mBtn_random.y;
         }
         if(GlobalData.$isExtreme)
         {
            if(!GlobalData.$userData.isGuildWarSaiCheng)
            {
               this.mBtn_apply = new LOL_Scale9Button(GlobalData.$useExtreme.is_signup ? GlobalLanguageStr.getLanguageStr(90286) : GlobalLanguageStr.getLanguageStr(90257),150,70,"UI_btn_normalFun_0000");
               this.mBtn_apply.name = GlobalData.$useExtreme.is_signup ? "btn_name_changeteam" : "btn_name_apply";
            }
            else
            {
               this.mBtn_apply = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90257),150,70,"UI_btn_normalFun_0000");
               this.mBtn_apply.name = "btn_name_apply";
            }
            this.mBtn_apply.x = mBtn_play.x;
            this.mBtn_apply.y = mBtn_play.y;
            this.mBtn_apply.fontSize = MainConfig.$isEA ? 22 : 25;
            this.mBtn_apply.visible = GlobalData.$isExtreme;
            addChild(this.mBtn_apply);
            this.mBtn_apply.addEventListener("triggered",onTRIGGERED_);
            this.mBtn_changeTeam = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90286),150,70,"UI_btn_normalFun_0000");
            this.mBtn_changeTeam.name = "btn_name_changeteam";
            this.mBtn_changeTeam.x = mBtn_play.x;
            this.mBtn_changeTeam.y = this.mBtn_random.y - 1;
            this.mBtn_changeTeam.fontSize = 25;
            this.mBtn_changeTeam.shadowFilter();
            this.mBtn_changeTeam.visible = GlobalData.$tempIsApplyorChangeTeam;
            addChild(this.mBtn_changeTeam);
            this.mBtn_changeTeam.addEventListener("triggered",onTRIGGERED_);
         }
         if(GlobalData.$isBattleOfThePeak)
         {
            mBtn_team.visible = false;
            if(!(GlobalData.$BattleOfThePeakDefenseSelect == 2 && GlobalData.$userData.isAttTeam15v15))
            {
               mBtn_play.text = GlobalLanguageStr.getLanguageStr(98010);
            }
            mBtn_play.name = "btn_name_sure";
         }
         var _loc2_:Number = 220;
         this.mTxt_sign = GlobalTextStyle.getTextField("",20,4926491,"left",_loc2_,35);
         this.mTxt_sign.x = m9x9_bg.x + 20 + 2;
         this.mTxt_sign.y = m9x9_bg.y + 15;
         addChild(this.mTxt_sign);
         this.mPoint_to = new Point();
         this.mRec_s = new Rectangle();
         this.mOffset_drag = -45;
         mPanelMap = new Sprite();
         addChild(mPanelMap);
         mMap = new Sprite();
         mPanelMap.addChild(mMap);
         onUPDATE_PVE_DRAG_TEAM(null);
      }
      
      private function popLaneCoverageError() : void
      {
         var laneCount:int = GameMap.currentMap.getLaneCount();
         var missingCount:int = GameMap.currentMap.getMissingLaneCount();
         GlobalFunction.popError("每条路线至少布置1名英雄；当前地图有" + laneCount + "条路线，还缺" + missingCount + "条路线。");
      }
      
      private function onUPDATE_TEAM_PK_LIST(param1:Event) : void
      {
         onUPDATE_PVE_DRAG_TEAM(null);
      }
      
      override public function clear() : void
      {
         GlobalData.$mEventDispatcher.removeEventListener("update_team_pk_list",this.onUPDATE_TEAM_PK_LIST);
         GlobalData.$mEventDispatcher.removeEventListener("update_pve_drag",this.onUPDATE_PVE_DRAG);
         GlobalData.$mEventDispatcher.removeEventListener("update_pve_drag_avatar",this.onTouchAvatar);
         GlobalData.$mEventDispatcher.removeEventListener("start_pve_drag",this.onSTART_PVE_DRAG);
         StarlingTools.removeChildrenClear(this.mList_drag);
         StarlingTools.removeChildrenClear(this.mPanelTeamSet);
         StarlingTools.removeChildrenClear(this.mCurr_drag);
         if(this.mFriend)
         {
            StarlingTools.removeChildrenClear(this.mFriend);
            this.mFriend.removeFromParent(true);
            this.mFriend = null;
         }
         if(this.mMap)
         {
            mMap.removeChildren();
            mMap.removeFromParent();
         }
         if(mExploration_Back)
         {
            mExploration_Back.removeFromParent(true);
         }
         mExploration_Back = null;
         if(mExploration_Power)
         {
            mExploration_Power.removeFromParent(true);
         }
         mExploration_Power = null;
         if(mBuff_spr)
         {
            StarlingTools.removeChildrenClear(mBuff_spr);
         }
         mBuff_spr = null;
         if(mBuff_bg)
         {
            mBuff_bg.dispose();
            mBuff_bg.removeFromParent(true);
         }
         mBuff_bg = null;
         if(mBuff_txt)
         {
            mBuff_txt.dispose();
            mBuff_txt.removeFromParent(true);
         }
         mBuff_txt = null;
         StarlingTools.removeChildrenClear(this.mPanelMap);
         StarlingTools.removeChildrenClear(this);
         if(this.hasEventListener("touch"))
         {
            this.removeEventListener("touch",this.onTOUCH);
         }
         if(mPanelTeamSet)
         {
            mPanelTeamSet.clear();
         }
         if(mTxt_sign)
         {
            mTxt_sign.dispose();
            mTxt_sign = null;
         }
         LayoutUIAnimation.getOnlyExample().clearIfNoGuide();
         this.dispose();
         this.mPanelTeamSet = null;
         this.mCurr_drag = null;
         this.mFriend = null;
         this.mMap = null;
         this.mPanelMap = null;
         this.mList_drag = null;
         this.mArr_drag = null;
         super.clear();
      }
      
      private function randomEmbattle() : void
      {
         var _loc1_:* = null;
         lastTime = new Date().getTime();
         GameMap.currentMap.randomEmbattle(mArr_drag.length);
         for each(_loc1_ in mArr_drag)
         {
            setItemMask(_loc1_.data.id);
         }
         setItemMask("");
         SoundManager.getOnlyExample().playSound("embattle");
      }
      
      private function onTRIGGERED_(param1:Event) : void
      {
         var _loc7_:* = null;
         var _loc8_:Object = null;
         var _loc9_:Number = NaN;
         var _loc2_:Date = null;
         var _loc6_:Object = null;
         var _loc4_:String = null;
         var _loc5_:Object = null;
         var _loc3_:Array = null;
         var _loc10_:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         if(_loc10_.name == "btn_name_random")
         {
            if(Math.abs(lastTime - new Date().getTime()) > 500)
            {
               randomEmbattle();
            }
         }
         else if(_loc10_.name == "btn_name_play")
         {
            if(!GameMap.currentMap.checkStart())
            {
               popLaneCoverageError();
            }
            else if(mArr_drag.length > GameMap.currentMap.getMyListNum())
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(31000));
            }
            else
            {
               if(GlobalData.$isFragment || GlobalData.$isPVP || GlobalData.$isExploration)
               {
                  GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.checkTimer(false);
               }
               GlobalData.$mEventDispatcher.dispatchEventWith("stage_game");
            }
         }
         else if(_loc10_.name == "btn_name_apply")
         {
            if(!GameMap.currentMap.checkStart())
            {
               popLaneCoverageError();
            }
            else if(mArr_drag.length > GameMap.currentMap.getMyListNum())
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(31000));
            }
            else
            {
               GlobalData.$mEventDispatcher.dispatchEventWith("stage_game");
            }
         }
         else if(_loc10_.name == "btn_name_team")
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_editteam",false,true);
         }
         else if(_loc10_.name == "btn_name_back")
         {
            GlobalData.$mGameClassObject.closePopForPanel(mPop_currID);
         }
         else if(_loc10_.name == "btn_name_changeteam")
         {
            if(!GameMap.currentMap.checkStart())
            {
               popLaneCoverageError();
            }
            else if(mArr_drag.length > GameMap.currentMap.getMyListNum())
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(31000));
            }
            else
            {
               GlobalData.$mEventDispatcher.dispatchEventWith("stage_game");
            }
         }
         else if(_loc10_.name == "btn_name_sure")
         {
            if(!GameMap.currentMap.checkStart())
            {
               popLaneCoverageError();
            }
            else if(mArr_drag.length > GameMap.currentMap.getMyListNum())
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(31000));
            }
            else
            {
               _loc8_ = GlobalData.$mConfig_simple.cross_pvp;
               _loc9_ = 86400 * _loc8_.cross_server_pvp[3];
               _loc2_ = _loc8_.cross_server_pvp[2];
               if(_loc9_ - (SendAndSelect.$systemTimer_nowSecond - _loc2_.time / 1000) % _loc9_ < _loc8_.cross_server_pvp[4] * 60 * 60)
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(98053),false);
                  return;
               }
               if(GlobalData.$userData.isAttTeam15v15)
               {
                  if(GlobalData.$BattleOfThePeakDefenseSelect != 2)
                  {
                     _loc6_ = {
                        "ok":sureSave,
                        "no":GlobalFunction.functionNull,
                        "aid":"A_2009_5"
                     };
                     _loc4_ = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(98008),GlobalTextStyle.COLOR_W_Y_Y_G);
                     GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(90010),_loc4_,_loc6_);
                  }
                  else
                  {
                     _loc5_ = GlobalFunction.getFragmentPower();
                     _loc3_ = GlobalData.$mConfig_simple.cross_pvp.cross_server_pvp;
                     if(_loc5_.energy < _loc3_[1])
                     {
                        GlobalFunction.sevice_pvp_buy(GlobalLanguageStr.getLanguageStr(20098));
                        return;
                     }
                     sureSaveOver();
                  }
               }
               else if(GlobalData.$BattleOfThePeakTeamSelect != 2)
               {
                  _loc6_ = {
                     "ok":sureSave,
                     "no":GlobalFunction.functionNull,
                     "aid":"A_2009_5"
                  };
                  _loc4_ = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(98008),GlobalTextStyle.COLOR_W_Y_Y_G);
                  GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(90010),_loc4_,_loc6_);
               }
               else
               {
                  _loc6_ = {
                     "ok":sureSaveOver,
                     "no":GlobalFunction.functionNull,
                     "aid":"A_2009_5"
                  };
                  _loc4_ = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(98042),GlobalTextStyle.COLOR_W_Y_Y_G);
                  GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(90010),_loc4_,_loc6_);
               }
            }
         }
      }
      
       private function sureSaveOver() : void
      {
         var _loc3_:Array = null;
         var _loc9_:Array = null;
         var _loc8_:* = 0;
         var _loc6_:Array = null;
         var _loc1_:int = 0;
         var _loc4_:Array = null;
         var _loc7_:* = 0;
         var _loc5_:Object = null;
         if(!mDefensiveSquadBefore)
         {
            mDefensiveSquadBefore = [];
         }
         if(GlobalData.$userData.isAttTeam15v15)
         {
            mDefensiveSquadBefore[GlobalData.$BattleOfThePeakDefenseSelect] = GameMap.currentMap.myList;
            _loc3_ = mDefensiveSquadBefore;
            GlobalData.$BattleOfThePeakTure = true;
            _loc9_ = [];
            _loc8_ = 0;
            while(_loc8_ < 3)
            {
               _loc6_ = [];
               _loc1_ = 0;
               _loc4_ = GlobalData.$BattleOfThePeakDefenseTeam["team" + _loc8_];
               _loc7_ = 0;
               while(_loc7_ < 5)
               {
                  if(_loc3_[_loc8_])
                  {
                     if(_loc4_[_loc7_])
                     {
                        _loc6_.push(_loc3_[_loc8_][_loc1_]);
                        _loc1_++;
                     }
                     else
                     {
                        _loc6_.push("");
                     }
                  }
                  _loc7_++;
               }
               _loc9_.push(_loc6_);
               _loc8_++;
            }
            GlobalData.$userData.sendFightData.teams = _loc9_;
            for(var _loc2_:String in GlobalData.$userData.sendFightData.oldteams)
            {
               if(GlobalData.$userData.sendFightData.oldteams[_loc2_])
               {
                  _loc9_[int(_loc2_)] = GlobalData.$userData.sendFightData.oldteams[_loc2_];
               }
            }
            _loc5_ = GlobalData.$userData.sendFightData;
            GlobalData.$userData.sendFightData.oldteams = null;
            GameMap.isLoadFile = false;
            SendServiceAMFFun.pk_combat_cross_server_pvp(fight,GlobalData.$userData.sendFightData);
         }
         else
         {
            mDefensiveSquadBefore[GlobalData.$BattleOfThePeakTeamSelect] = GameMap.currentMap.myList;
            _loc3_ = mDefensiveSquadBefore;
            GlobalData.$BattleOfThePeakTure = true;
            _loc9_ = [];
            _loc8_ = 0;
            while(_loc8_ < 3)
            {
               _loc6_ = [];
               _loc1_ = 0;
               _loc4_ = GlobalData.$BattleOfThePeakTeam["team" + _loc8_];
               _loc7_ = 0;
               while(_loc7_ < 5)
               {
                  if(_loc4_[_loc7_])
                  {
                     _loc6_.push(_loc3_[_loc8_][_loc1_]);
                     _loc1_++;
                  }
                  else
                  {
                     _loc6_.push("");
                  }
                  _loc7_++;
               }
               _loc9_.push(_loc6_);
               _loc8_++;
            }
            var pendingDraft:Array = mDefensiveSquadBefore;
            SendServiceAMFFun.send_user_set_defensive_squad(function(response:Object):void
            {
               onTeamSure(response,pendingDraft);
            },{"teams":_loc9_});
         }
      }
      
      private function fight(param1:Object) : void
      {
         mDefensiveSquadBefore = null;
         trace("954796090");
         GlobalData.$m15v15FightData = param1;
         GlobalData.$mEventDispatcher.dispatchEventWith("stage_game");
      }
      
      private function onTeamSure(param1:Object, param2:Array) : void
      {
         if(param1.data && GlobalFunction.isVersionedProfileReceipt(param1) && mDefensiveSquadBefore == param2)
         {
            mDefensiveSquadBefore = null;
            if(this.stage)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(98009),true);
               GlobalData.$mEventDispatcher.dispatchEventWith("updata_battle_of_the_peak_defense",false,{"isOver":1});
               onCLOSE_PANEL_SELF();
            }
         }
      }
      
      private function sureSave() : void
      {
         if(!mDefensiveSquadBefore)
         {
            mDefensiveSquadBefore = [];
         }
         if(GlobalData.$userData.isAttTeam15v15)
         {
            mDefensiveSquadBefore[GlobalData.$BattleOfThePeakDefenseSelect] = GameMap.currentMap.myList;
         }
         else
         {
            mDefensiveSquadBefore[GlobalData.$BattleOfThePeakTeamSelect] = GameMap.currentMap.myList;
         }
         GlobalData.$mEventDispatcher.dispatchEventWith("updata_battle_of_the_peak_defense");
         onCLOSE_PANEL_SELF();
      }
      
      override public function onTRIGGERED(param1:Event) : void
      {
         if(GlobalData.$isPVP)
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp");
         }
         else if(GlobalData.$isFragment)
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_fragment");
         }
         else if(GlobalData.$isExtreme)
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp");
         }
         else
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pve_friend");
            GlobalData.$mEventDispatcher.dispatchEventWith("update_pve_friend");
         }
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(GlobalData.$isBattleOfThePeak)
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.mCurrPanel = "";
         }
         clear();
      }
      
      public function setFriendUI() : void
      {
         var _loc1_:Rectangle = null;
         var _loc2_:Object = null;
         if(this.mFriend)
         {
            StarlingTools.removeChildrenClear(this.mFriend);
            this.mFriend.removeFromParent(true);
            this.mFriend = null;
         }
         if(GlobalData.$isPVE)
         {
            if(GameMap.canHelp(GlobalData.$tempPVE_combatID))
            {
               _loc1_ = new Rectangle(this.mPanelTeamSet.x,this.mPanelTeamSet.y,GlobalData.$mStageWidth,0);
               this.mFriend = new ItemTeamEmbattle();
               if(!GlobalData.$isNoFriendToPVE)
               {
                  this.mFriend.data = GlobalData.$tempHelpAvatar.avatar;
               }
               else
               {
                  _loc2_ = {};
                  _loc2_["status"] = -1;
                  this.mFriend.data = _loc2_;
               }
               this.mFriend.x = _loc1_.x + _loc1_.width - 90 - 52;
               this.mFriend.y = _loc1_.y + 15;
               this.mFriend.mPanelPVEembattle = this;
               this.addChildAt(this.mFriend,2);
               this.mPanelTeamSet.x = 0;
            }
         }
      }
      
      private function onUPDATE_PVE_DRAG_TEAM(param1:Event) : void
      {
         this.setMapUI();
         if(this.mPanelTeamSet == null)
         {
            this.mPanelTeamSet = new PanelPVEembattleTeam();
            this.mPanelTeamSet.y = this.m9x9_bg.y + this.m9x9_bg.height + (GlobalData.$isExploration ? 25 : 10);
            this.addChildAt(this.mPanelTeamSet,1);
         }
         else
         {
            this.mPanelTeamSet.update();
         }
         this.mPanelTeamSet.x = 15;
         this.setFriendUI();
      }
      
      private function onUPDATE_PVE_DRAG(param1:Event) : void
      {
         this.update();
      }
      
      override public function update() : void
      {
         var _loc1_:Object = GlobalFunction.getPveBattleCfg(GlobalData.$tempPVE_type);
         var _loc4_:GameMap = GameMap.currentMap;
         var _loc5_:String = "";
         if(_loc4_)
         {
            _loc5_ = GameMapTools.getWinStr(_loc4_.gameMapData);
         }
         this.mTxt_sign.text = GlobalLanguageStr.getLanguageStr(20043,_loc5_);
         this.setListDrag();
         setItemMask("",false);
         var _loc3_:ItemTeamEmbattle = getItem("") as ItemTeamEmbattle;
         if(_loc3_)
         {
            _loc3_.setActionNumber();
         }
         if(GameMap.currentMap)
         {
            GameMap.currentMap.initMap(false,mArr_drag);
            randomEmbattle();
         }
         GuideMaster.getOnlyExample().nextGuideStep();
         var _loc2_:String = GuideTools.checkGuideType();
         if(_loc2_ == "1")
         {
            LayoutUIAnimation.getOnlyExample().addArrowhead(497,811,68);
         }
      }
      
      public function setListDrag() : void
      {
         var _loc3_:* = 0;
         var _loc1_:ItemDDAvatar = null;
         var _loc5_:Object = null;
         var _loc2_:* = undefined;
         var _loc4_:Array = null;
         if(this.mList_drag == null)
         {
            this.mList_drag = new Sprite();
            this.mList_drag.x = this.mPanelMap.x;
            this.mList_drag.y = this.mPanelMap.y;
            this.addChild(this.mList_drag);
         }
         StarlingTools.removeChildrenClear(this.mList_drag);
         this.mArr_drag = [];
         this.mCurr_drag = null;
         var _loc7_:uint = 0;
         var _loc6_:Array = [];
         if(GlobalData.$isExploration)
         {
            _loc3_ = 3;
            _loc2_ = GlobalData.$exploration_team_avatar;
            _loc6_ = GlobalData.$tempTeam = GlobalData.$exploration_team_avtId_arr;
            _loc5_ = {};
            _loc7_ = 0;
            while(_loc7_ < _loc3_)
            {
               if(_loc6_[_loc7_] != null)
               {
                  _loc5_ = GlobalFunction.setTeamData(_loc6_[_loc7_]);
                  _loc5_["id"] = _loc6_[_loc7_];
                  _loc5_["indexID_s"] = _loc7_;
                  _loc1_ = new ItemDDAvatar();
                  _loc1_.data = _loc5_;
                  _loc1_.visible = false;
                  this.mList_drag.addChild(_loc1_);
                  this.mArr_drag.push(_loc1_);
               }
               _loc7_++;
            }
         }
         else if(GlobalData.$isBattleOfThePeak)
         {
            _loc3_ = 5;
            if(GlobalData.$userData.isAttTeam15v15)
            {
               _loc6_ = GlobalData.$BattleOfThePeakDefenseTeam["team" + GlobalData.$BattleOfThePeakDefenseSelect];
            }
            else
            {
               _loc6_ = GlobalData.$BattleOfThePeakTeam["team" + GlobalData.$BattleOfThePeakTeamSelect];
            }
            _loc5_ = {};
            _loc7_ = 0;
            while(_loc7_ < _loc3_)
            {
               if(_loc6_[_loc7_] != null)
               {
                  _loc5_ = GlobalData.$userData.avatars[_loc6_[_loc7_].aid];
                  _loc5_["id"] = _loc6_[_loc7_].aid;
                  _loc5_["indexID_s"] = _loc7_;
                  _loc1_ = new ItemDDAvatar();
                  _loc1_.data = _loc5_;
                  _loc1_.visible = false;
                  this.mList_drag.addChild(_loc1_);
                  this.mArr_drag.push(_loc1_);
               }
               _loc7_++;
            }
         }
         else
         {
            _loc3_ = 5;
            _loc4_ = GlobalData.$userData.team as Array;
            _loc6_ = GlobalData.$tempTeam = _loc4_[0];
            _loc5_ = {};
            _loc7_ = 0;
            while(_loc7_ < _loc3_)
            {
               if(_loc6_[_loc7_] != null)
               {
                  _loc5_ = GlobalData.$userData.avatars[_loc6_[_loc7_]];
                  _loc5_["id"] = _loc6_[_loc7_];
                  _loc5_["indexID_s"] = _loc7_;
                  _loc1_ = new ItemDDAvatar();
                  _loc1_.data = _loc5_;
                  _loc1_.visible = false;
                  this.mList_drag.addChild(_loc1_);
                  this.mArr_drag.push(_loc1_);
               }
               _loc7_++;
            }
         }
         if(GlobalData.$isPVE)
         {
            if(GameMap.canHelp(GlobalData.$tempPVE_combatID))
            {
               if(!GlobalData.$isNoFriendToPVE)
               {
                  _loc5_ = GlobalData.$tempHelpAvatar.avatar;
                  _loc5_["isF"] = GlobalData.$tempHelpAvatar["isF"];
                  _loc1_ = new ItemDDAvatar();
                  _loc1_.data = _loc5_;
                  _loc1_.data["indexID_s"] = 6;
                  _loc1_.visible = false;
                  this.mList_drag.addChild(_loc1_);
                  this.mArr_drag.push(_loc1_);
               }
            }
         }
         this.removeEventListener("touch",this.onTOUCH);
         this.addEventListener("touch",this.onTOUCH);
      }
      
      private function onSTART_PVE_DRAG(param1:Event) : void
      {
         var _loc3_:ItemDDAvatar = null;
         var _loc2_:* = null;
         var _loc4_:String = null;
         var _loc5_:int = 0;
         _loc5_ = 0;
         while(_loc5_ < this.mArr_drag.length)
         {
            _loc3_ = this.mArr_drag[_loc5_];
            _loc4_ = _loc3_.data["indexID_s"];
            if(_loc4_ == GlobalData.$tempPVE_drag.data["indexID_s"] && !_loc3_.visible)
            {
               if(GlobalData.$tempPVE_drag.mMask_000000.visible)
               {
                  return;
               }
               if(GlobalData.$currentGuide)
               {
                  if(GuideMaster.getOnlyExample().currentGuide.stepData.ma != _loc5_)
                  {
                     return;
                  }
               }
               this.mRec_s = GlobalData.$tempPVE_drag.getBounds(this.mList_drag);
               this.mCurr_drag = _loc3_;
               this.mCurr_drag.x = this.mRec_s.x;
               this.mCurr_drag.y = this.mRec_s.y;
               this.mCurr_drag.visibleMask(true);
               SoundManager.getOnlyExample().playAvatar(mCurr_drag.mAvatarData.avatarData.soundId);
               return;
            }
            _loc5_++;
         }
      }
      
      protected function onTouchAvatar(param1:Event) : void
      {
         var _loc2_:Avatar = param1.data.avatar as Avatar;
         var _loc3_:Touch = param1.data.touch as Touch;
         if(_loc2_.actionNum < mArr_drag.length)
         {
            mCurr_drag = mArr_drag[_loc2_.actionNum] as ItemDDAvatar;
            _loc3_.getLocation(this.mList_drag,this.mPoint_to);
            this.mCurr_drag.x = this.mPoint_to.x + this.mOffset_drag;
            this.mCurr_drag.y = this.mPoint_to.y + this.mOffset_drag;
            mCurr_drag.visible = true;
            _loc2_.fightRes.visible = false;
            ItemBase.soundTriggered();
         }
         else
         {
            ItemBase.soundTriggered(true);
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(31007),false,_loc2_.resId);
         }
      }
      
      protected function onTOUCH(param1:TouchEvent) : void
      {
         var _loc5_:Touch = null;
         var _loc4_:Rectangle = null;
         var _loc7_:Point = null;
         var _loc2_:Avatar = null;
         var _loc3_:Boolean = false;
         var _loc6_:Array = null;
         var _loc9_:int = 0;
         _loc5_ = param1.getTouch(this);
         var _loc8_:GameMapLayer = GameMapLayer.gl;
         var _loc10_:GameMap = GameMap.currentMap;
         if(_loc5_)
         {
            if(_loc5_.phase == "began")
            {
               if(param1.target is Image)
               {
                  if((param1.target as Image).parent.parent is ItemDDAvatar)
                  {
                     this.mCurr_drag = (param1.target as Image).parent.parent as ItemDDAvatar;
                  }
               }
               if(mCurr_drag)
               {
                  _loc4_ = mCurr_drag.getBounds(_loc8_.mgLayer);
                  _loc7_ = GameMapConfig.pixelToPos(_loc4_.x + _loc4_.width / 2,_loc4_.y - _loc4_.height / 2);
                  if(_loc10_.checkAdd(_loc7_.x,_loc7_.y))
                  {
                     mCurr_drag.visibleMask(false);
                  }
                  else
                  {
                     mCurr_drag.visibleMask(true);
                  }
               }
            }
            else if(_loc5_.phase == "moved")
            {
               if(this.mCurr_drag)
               {
                  _loc5_.getLocation(this.mList_drag,this.mPoint_to);
                  this.mCurr_drag.x = this.mPoint_to.x + this.mOffset_drag;
                  this.mCurr_drag.y = this.mPoint_to.y + this.mOffset_drag;
                  _loc4_ = mCurr_drag.getBounds(_loc8_.mgLayer);
                  _loc7_ = GameMapConfig.pixelToPos(_loc4_.x + _loc4_.width / 2,_loc4_.y - _loc4_.height / 2);
                  if(_loc10_.checkAdd(_loc7_.x,_loc7_.y))
                  {
                     mCurr_drag.visibleMask(false);
                  }
                  else
                  {
                     mCurr_drag.visibleMask(true);
                  }
               }
            }
            else if(_loc5_.phase == "ended")
            {
               if(this.mCurr_drag)
               {
                  _loc4_ = mCurr_drag.getBounds(_loc8_.mgLayer);
                  _loc7_ = GameMapConfig.pixelToPos(_loc4_.x + _loc4_.width / 2,_loc4_.y - _loc4_.height / 2);
                  _loc2_ = mCurr_drag.mAvatarData;
                  _loc3_ = false;
                  if(_loc2_.mData["indexID_s"] == 0)
                  {
                     _loc3_ = true;
                  }
                  else if(_loc2_.mData["indexID_s"] == 6)
                  {
                     if(mCurr_drag.mAvatarData.mData.isF == 1)
                     {
                        _loc3_ = true;
                     }
                     _loc2_.isOthers = true;
                  }
                  _loc2_ = _loc10_.getSameAvatar(_loc2_);
                  if(GlobalData.$isExploration)
                  {
                     _loc9_ = 0;
                     _loc7_.x = Math.round(Math.min(GameMapConfig.sideOffset,Math.max(_loc7_.x - _loc9_ * GameMapConfig.lineOffset,-GameMapConfig.sideOffset)));
                     _loc7_.y = Math.round(Math.min(GameMapConfig.LINE_POS,Math.max((1 - GameMapConfig.MAX_POS_PER) * GameMapConfig.LINE_POS,_loc7_.y)));
                     _loc2_.goFight(1,_loc9_,Avatar.getPosPer(_loc7_.y),_loc3_);
                     GameMap.actionDelay = 0;
                     _loc10_.addAvatar(_loc2_,1,_loc9_,_loc2_.pos,_loc3_,_loc7_.x);
                     setItemMask(_loc2_.isOthers ? "" : _loc2_.id);
                     _loc2_.fightRes.visible = true;
                     SoundManager.getOnlyExample().playSound("embattle");
                     mCurr_drag.visible = false;
                     this.mCurr_drag = null;
                  }
                  else
                  {
                     if(_loc10_.checkAdd(_loc7_.x,_loc7_.y))
                     {
                        _loc9_ = Math.round(_loc7_.x / GameMapConfig.lineOffset);
                        _loc2_.hp = 0;
                        _loc7_.x = Math.round(Math.min(GameMapConfig.sideOffset,Math.max(_loc7_.x - _loc9_ * GameMapConfig.lineOffset,-GameMapConfig.sideOffset)));
                        _loc7_.y = Math.round(Math.min(GameMapConfig.LINE_POS,Math.max((1 - GameMapConfig.MAX_POS_PER) * GameMapConfig.LINE_POS,_loc7_.y)));
                        if(!_loc2_.isOthers)
                        {
                           _loc6_ = GlobalData.$userData.as_equips;
                           _loc2_.setEquips(_loc6_[_loc2_.indexID_s]);
                        }
                        _loc2_.goFight(1,_loc9_,Avatar.getPosPer(_loc7_.y),_loc3_);
                        GameMap.actionDelay = 0;
                        _loc10_.addAvatar(_loc2_,1,_loc9_,_loc2_.pos,_loc3_,_loc7_.x);
                        setItemMask(_loc2_.isOthers ? "" : _loc2_.id);
                        _loc2_.fightRes.visible = true;
                        SoundManager.getOnlyExample().playSound("embattle");
                     }
                     else
                     {
                        if(_loc2_.line != -1)
                        {
                           _loc2_.fightRes.visible = false;
                        }
                        _loc2_.line = -1;
                        _loc10_.myList[_loc2_.actionNum] = null;
                        setItemMask(_loc2_.isOthers ? "" : _loc2_.id,false);
                     }
                     mCurr_drag.visible = false;
                     this.mCurr_drag = null;
                  }
               }
            }
         }
      }
      
      public function getItem(param1:String = "") : ItemBase
      {
         var _loc3_:ItemBase = null;
         var _loc2_:* = undefined;
         if(param1 == "")
         {
            _loc3_ = GlobalData.$isPVE ? mFriend : null;
         }
         else
         {
            _loc2_ = GlobalData.$tempItemTeamEmbattle;
            _loc3_ = _loc2_[param1];
         }
         return _loc3_;
      }
      
      public function setItemMask(param1:String = "", param2:Boolean = true) : void
      {
         var _loc3_:ItemBase = getItem(param1);
         trace(_loc3_);
         if(_loc3_)
         {
            _loc3_.visibleMask(param2);
         }
      }
      
      public function setMapUI() : void
      {
         if(this.mMap)
         {
            mMap.removeChildren();
         }
         if(GameMap.currentMap)
         {
            GameMap.currentMap.clear(false);
         }
         var _loc2_:GameMapLayer = GameMapLayer.gl;
         mMap.addChild(_loc2_.mapStage);
         _loc2_.mapStage.pivotX = GameMapConfig.FIGHT_WIDTH / 2;
         _loc2_.mapStage.pivotY = GameMapConfig.SCREEN_HEIGHT * 0.8;
         _loc2_.mapStage.x = GameMapConfig.FIGHT_WIDTH / 2;
         _loc2_.mapStage.y = GameMapConfig.SCREEN_HEIGHT * 0.72 - 5;
         _loc2_.mapStage.scaleX = _loc2_.mapStage.scaleY = 0.9;
         var _loc4_:int = GameMapConfig.SCREEN_HEIGHT * 0.62 - 50;
         var _loc3_:int = GameMapConfig.SCREEN_HEIGHT * 0.4;
         _loc2_.mapStage.clipRect = new Rectangle(20,_loc4_,GameMapConfig.FIGHT_WIDTH - 40,_loc3_);
         mMap.y = -GameMapConfig.SCREEN_HEIGHT * 0.55 + 185;
         var _loc5_:String = GlobalData.$tempPVE_combatID;
         var _loc1_:int = GlobalData.$diff;
         if(GlobalData.$isPVP)
         {
            _loc5_ = "pvp";
            _loc1_ = -1;
         }
         else if(GlobalData.$isExtreme)
         {
            _loc5_ = "extreme";
            _loc1_ = -1;
         }
         else if(GlobalData.$isFragment)
         {
            _loc5_ = "fragment";
            _loc1_ = -1;
         }
         else if(GlobalData.$isBattleOfThePeak)
         {
            _loc5_ = "battle_of_the_peak";
            _loc1_ = -1;
         }
         else if(GlobalData.$isExploration)
         {
            _loc5_ = "exploration";
            _loc1_ = -1;
         }
         GameMap.isLoad = GameMap.isLoadFile = false;
         new GameMap(_loc5_,_loc1_);
         if(GlobalData.$isPVE)
         {
            this.changeStr_header(GameMap.currentMap.gameMapData.name);
         }
      }
   }
}

