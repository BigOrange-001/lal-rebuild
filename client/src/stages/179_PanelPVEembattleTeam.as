package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.ui.element.ItemTeamEmbattle;
   import com.meng52.game.ui.element.LOL_TextField;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;
   import starling.textures.Texture;

   public class PanelPVEembattleTeam extends PanelTeamSet
   {

      private var mTxt_leader:TextField;

      private var mTxt_helper:TextField;

      private var mPower_spr:Sprite;

      public function PanelPVEembattleTeam()
      {
         super();
      }

      override public function clear() : void
      {
         if(mTxt_leader)
         {
            mTxt_leader.dispose();
            mTxt_leader = null;
         }
         if(mTxt_helper)
         {
            mTxt_helper.dispose();
            mTxt_helper = null;
         }
         super.clear();
      }

      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         this.mBox_ui = new Sprite();
         this.mBox_ui.touchable = false;
         this.addChild(this.mBox_ui);
         var _loc3_:Texture = null;
         this.mImg_title = GlobalFunction.createImage("UI_bg_0_0000");
         this.mImg_title.alpha = 0.5;
         this.mImg_title.touchable = false;
         this.mImg_title.x = 0;
         var _loc2_:Number = GlobalData.$mStageWidth * 0.5;
         mTxt_power = new LOL_TextField("",_loc2_,35);
         mTxt_power.fontSize = 20;
         mTxt_power.fontColor = 16777215;
         mTxt_power.hAlign = "center";
         this.mTxt_power.touchable = false;
         this.mTxt_power.x = int((GlobalData.$mStageWidth - _loc2_) * 0.5);
         this.mTxt_power.y = int(this.mImg_title.y + this.mImg_title.height - 10);
         this.mBox_ui.addChild(this.mTxt_power);
         update();
      }

      override public function update() : void
      {
         this.setTag();
         this.setList();
      }

      override public function setListCollection(param1:Array) : void
      {
         setListTimer(this.mList,param1,ItemTeamEmbattle,false);
      }

      override public function setList(param1:int = 0, param2:int = 0) : void
      {
         GlobalData.$tempItemTeamEmbattle = {};
         if(!GlobalData.$isExploration)
         {
            setSkillInfo();
            super.setList(35);
         }
         GlobalData.$mEventDispatcher.dispatchEventWith("update_pve_drag");
      }

      override public function showPower() : void
      {
         var _loc4_:Number = NaN;
         var _loc1_:* = undefined;
         var _loc2_:Array = null;
         var _loc3_:* = 0;
         if(this.mTxt_power)
         {
            _loc4_ = 0;
            _loc1_ = !GlobalData.$isPVE || GlobalData.$isNoFriendToPVE ? null : GlobalData.$tempHelpAvatar;
            // PvP submits five owned slots. A legacy/imported saved roster can
            // contain a sixth entry that the battle does not field.
            var previewTeam:Array = GlobalData.$tempTeam;
            if(!GlobalData.$isPVE && previewTeam) previewTeam = previewTeam.slice(0,5);
            _loc4_ = GlobalFunction.getTeamPower(previewTeam,_loc1_);
            GlobalData.$tempTeamPower = GlobalFunction.getTeamPower(previewTeam);
            if(GlobalData.$isBattleOfThePeak)
            {
               _loc2_ = [];
               _loc3_ = 0;
               while(_loc3_ < 5)
               {
                  if(GlobalData.$userData.isAttTeam15v15)
                  {
                     if(GlobalData.$BattleOfThePeakDefenseTeam["team" + GlobalData.$BattleOfThePeakDefenseSelect][_loc3_])
                     {
                        _loc2_[_loc3_] = GlobalData.$BattleOfThePeakDefenseTeam["team" + GlobalData.$BattleOfThePeakDefenseSelect][_loc3_].aid;
                     }
                     else
                     {
                        _loc2_[_loc3_] = "";
                     }
                  }
                  else if(GlobalData.$BattleOfThePeakTeam["team" + GlobalData.$BattleOfThePeakTeamSelect][_loc3_])
                  {
                     _loc2_[_loc3_] = GlobalData.$BattleOfThePeakTeam["team" + GlobalData.$BattleOfThePeakTeamSelect][_loc3_].aid;
                  }
                  else
                  {
                     _loc2_[_loc3_] = "";
                  }
                  _loc3_++;
               }
               _loc4_ = GlobalFunction.getTeamPower(_loc2_);
               GlobalData.$tempTeamPower = GlobalFunction.getTeamPower(_loc2_);
            }
            this.mTxt_power.text = GlobalLanguageStr.getLanguageStr(90279) + Tools.formateNum(_loc4_);
         }
      }

      public function setSkillInfo() : void
      {
         var _loc2_:Avatar = null;
         if(mTxt_leader)
         {
            mTxt_leader.removeFromParent(true);
         }
         mTxt_leader = null;
         if(mTxt_helper)
         {
            mTxt_helper.removeFromParent(true);
         }
         mTxt_helper = null;
         if(mPower_spr)
         {
            StarlingTools.removeChildrenClear(mPower_spr);
         }
         mPower_spr = null;
         var _loc1_:Number = 125;
         var _loc4_:Avatar = new Avatar(GlobalData.$userData.team[GlobalData.$tempTeamID][0]);
         var _loc5_:String = _loc4_.skill1 ? _loc4_.skill1.skillSetData.name : GlobalLanguageStr.getLanguageStr(20139);
         if(GlobalData.$isBattleOfThePeak && !GlobalData.$userData.isAttTeam15v15)
         {
            if(GlobalData.$BattleOfThePeakTeam["team" + GlobalData.$BattleOfThePeakTeamSelect][0])
            {
               _loc4_ = new Avatar(GlobalData.$BattleOfThePeakTeam["team" + GlobalData.$BattleOfThePeakTeamSelect][0].aid);
               _loc5_ = _loc4_.skill1 ? _loc4_.skill1.skillSetData.name : GlobalLanguageStr.getLanguageStr(20139);
            }
            else
            {
               _loc5_ = GlobalLanguageStr.getLanguageStr(20139);
            }
         }
         else if(GlobalData.$isBattleOfThePeak && GlobalData.$userData.isAttTeam15v15)
         {
            if(GlobalData.$BattleOfThePeakDefenseTeam["team" + GlobalData.$BattleOfThePeakDefenseSelect][0])
            {
               _loc4_ = new Avatar(GlobalData.$BattleOfThePeakDefenseTeam["team" + GlobalData.$BattleOfThePeakDefenseSelect][0].aid);
               _loc5_ = _loc4_.skill1 ? _loc4_.skill1.skillSetData.name : GlobalLanguageStr.getLanguageStr(20139);
            }
            else
            {
               _loc5_ = GlobalLanguageStr.getLanguageStr(20139);
            }
         }
         mTxt_leader = GlobalTextStyle.getTextField(_loc5_,20,16777215,"left",_loc1_,29);
         mTxt_leader.x = 41;
         mTxt_leader.y = this.mTxt_power.y;
         this.addChild(this.mTxt_leader);
         _loc4_.clear();
         var _loc3_:String = GlobalLanguageStr.getLanguageStr(20037);
         var _loc6_:* = 12069411;
         if(GlobalData.$isPVE)
         {
            if(!GlobalData.$isNoFriendToPVE)
            {
               if(GlobalData.$tempHelpAvatar.isF)
               {
                  _loc2_ = new Avatar(GlobalData.$tempHelpAvatar.avatar.aid,GlobalData.$tempHelpAvatar.avatar);
                  _loc3_ = _loc2_.skill1 ? _loc2_.skill1.skillSetData.name : GlobalLanguageStr.getLanguageStr(20139);
                  _loc6_ = uint(_loc2_.skill1 ? 6475106 : 12069411);
                  _loc2_.clear();
               }
               mTxt_helper = GlobalTextStyle.getTextField(_loc3_,20,_loc6_,"center",_loc1_,35);
               mTxt_helper.x = int(this.mImg_title.x + this.mImg_title.width - _loc1_ - 23);
               mTxt_helper.y = mTxt_leader.y;
               this.addChild(this.mTxt_helper);
            }
         }
      }
   }
}
