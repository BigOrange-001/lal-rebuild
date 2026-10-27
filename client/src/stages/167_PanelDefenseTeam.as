package com.meng52.game.ui.panel
{
   import com.meng52.game.Game;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.map.GameMap;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.element.ItemPVPBattleOfThePeakDefense;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.map.GameMapLayer;
   import com.meng52.game.ui.screen.PanelCenterPVE;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.data.ListCollection;
   import feathers.display.Scale9Image;
   import feathers.layout.TiledRowsLayout;
   import flash.geom.Rectangle;
   import flash.utils.Dictionary;
   import starling.animation.Juggler;
   import starling.animation.Tween;
   import starling.core.Starling;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;

   public class PanelDefenseTeam extends PanelCenterPVE
   {

      private var m_img_Team1:Image;

      private var m_img_Team2:Image;

      private var m_txt_Team1:TextField;

      private var m_txt_Team2:TextField;

      private var Allsp:Sprite;

      private var teamAllArr:Array;

      private var data:Object;

      private var vs:TextField;

      private var btnTeamLeft:LOL_Button;

      private var btnTeamRight:LOL_Button;

      private var btnNext:LOL_Button;

      private var curIndex:int = 0;

      private var DandM_Allicon:Array;

      private var boolDown:Boolean = false;

      private var juggler:Juggler;

      private var leaderNum:Number = 0;

      private var powerNum:Number = 0;

      private var liderText:TextField;

      private var mBg_list:Scale9Image;

      private var cftNum:uint = 0;

      public function PanelDefenseTeam(param1:Object)
      {
         data = param1;
         GlobalData.$userData.otherPlayerName = data.name;
         GlobalData.$userData.sendFightData = {};
         GlobalData.$userData.sendFightData.oldteams = {};
         GlobalData.$userData.sendFightData.rank = param1.rank;
         GlobalData.$userData.sendFightData.uid = param1.uid;
         GlobalData.$userData.sendFightData.zone = param1.zone;
         super();
      }

      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         var _loc2_:* = 0;
         GlobalData.$mEventDispatcher.removeEventListener("update_team_select",onTeamUp);
         GlobalData.$mEventDispatcher.removeEventListener("updata_battle_of_the_peak_defense",onFushDefense);
         _loc2_ = 0;
         while(_loc2_ < GlobalData.$BattleOfThePeakDefenseTeam["selectSpArr"].length)
         {
            if(GlobalData.$BattleOfThePeakDefenseTeam["selectSpArr"][_loc2_] != null)
            {
               juggler.removeTweens(GlobalData.$BattleOfThePeakDefenseTeam["selectSpArr"][_loc2_]);
               (GlobalData.$BattleOfThePeakDefenseTeam["selectSpArr"][_loc2_] as MySprite).removeEventListener("touch",onUpCoin);
               GlobalData.$BattleOfThePeakDefenseTeam["selectSpArr"][_loc2_].removeFromParent(true);
               (GlobalData.$BattleOfThePeakDefenseTeam["selectSpArr"] as Array).splice(_loc2_,1);
            }
            _loc2_++;
         }
         GlobalData.$BattleOfThePeakDefenseTeam["team0"] = [];
         GlobalData.$BattleOfThePeakDefenseTeam["team1"] = [];
         GlobalData.$BattleOfThePeakDefenseTeam["team2"] = [];
         GlobalData.$userData.isAttTeam15v15 = false;
         GlobalData.$BattleOfThePeakDefenseTeam["selectSpArr"] = [];
         juggler = null;
         if(liderText)
         {
            liderText.removeFromParent(true);
            liderText.dispose();
         }
         liderText = null;
         if(mBg_list)
         {
            mBg_list.removeFromParent(true);
            mBg_list.dispose();
         }
         mBg_list = null;
         delSelect();
         if(Allsp)
         {
            Allsp.removeFromParent(true);
            Allsp.dispose();
         }
         if(m_txt_Team1)
         {
            m_txt_Team1.removeFromParent(true);
            m_txt_Team1.dispose();
         }
         if(m_txt_Team2)
         {
            m_txt_Team2.removeFromParent(true);
            m_txt_Team2.dispose();
         }
         if(m_img_Team1)
         {
            m_img_Team1.removeFromParent(true);
            m_img_Team1.dispose();
         }
         if(m_img_Team2)
         {
            m_img_Team2.removeFromParent(true);
            m_img_Team2.dispose();
         }
         m_img_Team1 = null;
         m_img_Team2 = null;
         m_txt_Team1 = null;
         m_txt_Team2 = null;
         Allsp = null;
         teamAllArr = null;
      }

      override protected function initializeHandler(param1:Event) : void
      {
         var _loc11_:Object = null;
         var _loc5_:Object = null;
         var _loc10_:* = null;
         var _loc7_:String = null;
         var _loc2_:Avatar = null;
         var _loc6_:Dictionary = null;
         var _loc4_:Array = null;
         var _loc9_:* = 0;
         var _loc3_:Array = null;
         var _loc8_:* = 0;
         removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getStr(97655),870);
         juggler = Starling.juggler;
         GlobalData.$BattleOfThePeakDefenseSelect = 0;
         GlobalData.$userData.isAttTeam15v15 = true;
         if(GlobalData.$BattleOfThePeakDefenseTeam == null)
         {
            GlobalData.$BattleOfThePeakDefenseTeam = new Dictionary();
            GlobalData.$BattleOfThePeakDefenseTeam["team0"] = [];
            GlobalData.$BattleOfThePeakDefenseTeam["team1"] = [];
            GlobalData.$BattleOfThePeakDefenseTeam["team2"] = [];
            GlobalData.$BattleOfThePeakDefenseTeam["teamNo0"] = 0;
            GlobalData.$BattleOfThePeakDefenseTeam["teamNo1"] = 0;
            GlobalData.$BattleOfThePeakDefenseTeam["teamNo2"] = 0;
            GlobalData.$BattleOfThePeakDefenseTeam["selectSpArr"] = [];
         }
         if(GlobalData.$BattleOfThePeakDefenseTeam["selectSpArr"] != undefined)
         {
            GlobalData.$BattleOfThePeakDefenseTeam["selectSpArr"] = [];
         }
         if(data.data.my_attack_squad)
         {
            _loc5_ = Tools.clone(GlobalData.$userData.avatars);
            _loc7_ = "";
            _loc6_ = GlobalData.$BattleOfThePeakDefenseTeam;
            for(var _loc12_:String in _loc5_)
            {
               _loc7_ = _loc12_;
               if(GlobalFunction.checkSearchTypeByType(_loc7_,1))
               {
                  _loc4_ = data.data.my_attack_squad;
                  _loc9_ = 0;
                  while(_loc9_ < _loc4_.length)
                  {
                     _loc3_ = _loc4_[_loc9_];
                     _loc8_ = 0;
                     while(_loc8_ < _loc3_.length)
                     {
                        if(_loc3_[_loc8_])
                        {
                           if(_loc3_[_loc8_][0] == _loc7_)
                           {
                              if(_loc5_[_loc7_])
                              {
                                 _loc2_ = new Avatar(_loc7_,_loc5_[_loc7_]);
                                 _loc11_ = _loc5_[_loc12_];
                                 if(!_loc11_["aid"])
                                 {
                                    _loc11_["aid"] = _loc7_;
                                 }
                                 _loc11_["team012"] = _loc9_;
                                 _loc11_["teamNum"] = _loc8_;
                                 _loc11_["isSelect"] = 1;
                                 _loc11_["loX"] = GlobalData.$mStageWidth / 2;
                                 _loc11_["loY"] = GlobalData.$mStageHeight / 2;
                                 GlobalData.$BattleOfThePeakDefenseTeam["team" + _loc9_][_loc8_] = _loc11_;
                                 _loc2_.clear();
                                 _loc2_ = null;
                              }
                              else
                              {
                                 GlobalData.$BattleOfThePeakDefenseTeam["team" + _loc9_][_loc8_] = null;
                              }
                           }
                        }
                        else
                        {
                           GlobalData.$BattleOfThePeakDefenseTeam["team" + _loc9_][_loc8_] = null;
                        }
                        _loc8_++;
                     }
                     _loc9_++;
                  }
               }
            }
         }
         liderText = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20170,leaderNum) + "/" + GlobalFunction.getLeaderShip(),20,16777215,"right",800,46);
         this.addChild(liderText);
         setUI();
      }

      private function setUI() : void
      {
         var _loc8_:* = 0;
         var _loc5_:Array = null;
         var _loc7_:* = 0;
         var _loc2_:Sprite = null;
         var _loc1_:Image = null;
         var _loc4_:TextField = null;
         var _loc6_:Object = GlobalData.$mConfig_simple.cross_pvp;
         for(var _loc3_:String in _loc6_.hide_team)
         {
            if(_loc3_.indexOf("-") != -1)
            {
               if(data.rank >= _loc3_.split("-")[0] && data.rank <= _loc3_.split("-")[1])
               {
                  cftNum = _loc6_.hide_team[_loc3_];
               }
            }
            else if(data.rank == _loc3_)
            {
               cftNum = _loc6_.hide_team[_loc3_];
            }
         }
         mBg_list = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",GlobalData.$mStageWidth - 60,250,new Rectangle(110,55,70,20));
         mBg_list.x = int((GlobalData.$mStageWidth - mBg_list.width) * 0.5);
         mBg_list.y = 500;
         addChild(mBg_list);
         m_img_Team1 = GlobalFunction.createImage("UI_extreme_bg_0_0000");
         m_img_Team1.x = GlobalData.$mStageWidth / 2 - m_img_Team1.width / 2;
         m_img_Team1.y = 80;
         this.addChild(m_img_Team1);
         m_txt_Team1 = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97656,GlobalFunction.getNumber(1),data.data.power_list[0]),20,1118481,"center",500,35);
         m_txt_Team1.x = GlobalData.$mStageWidth / 2 - m_txt_Team1.width / 2;
         m_txt_Team1.y = m_img_Team1.y + 10;
         this.addChild(m_txt_Team1);
         m_img_Team2 = GlobalFunction.createImage("UI_extreme_bg_1_0000");
         m_img_Team2.x = GlobalData.$mStageWidth / 2 - m_img_Team1.width / 2;
         m_img_Team2.y = m_img_Team1.y + 200;
         this.addChild(m_img_Team2);
         m_txt_Team2 = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97657,GlobalFunction.getNumber(1)),20,1118481,"center",500,35);
         m_txt_Team2.x = GlobalData.$mStageWidth / 2 - m_txt_Team2.width / 2;
         m_txt_Team2.y = m_img_Team2.y + 10;
         this.addChild(m_txt_Team2);
         teamAllArr = [];
         Allsp = new Sprite();
         this.addChild(Allsp);
         _loc8_ = 0;
         while(_loc8_ < 2)
         {
            _loc5_ = [];
            _loc7_ = 0;
            while(_loc7_ < 5)
            {
               _loc2_ = new Sprite();
               _loc1_ = GlobalFunction.createImage("UI_bg_card_2_0002");
               _loc2_.addChild(_loc1_);
               _loc4_ = DisplayTools.newTextField("" + (_loc7_ + 1),"Font_numAndtag_1",40,16777215);
               _loc4_.pivotX = _loc4_.width * 0.5;
               _loc4_.pivotY = _loc4_.height * 0.5;
               _loc4_.x = _loc1_.x + _loc1_.width * 0.5;
               _loc4_.y = _loc1_.height * 0.5;
               _loc2_.addChild(_loc4_);
               _loc5_.push(_loc2_);
               Allsp.addChild(_loc2_);
               _loc2_.x = _loc7_ * _loc1_.width + 15;
               _loc2_.y = _loc8_ * 200 + 40;
               _loc7_++;
            }
            teamAllArr.push(_loc5_);
            _loc8_++;
         }
         Allsp.x = GlobalData.$mStageWidth / 2 - Allsp.width / 2 - 20;
         Allsp.y = m_txt_Team1.y + m_txt_Team1.height;
         GlobalData.$mEventDispatcher.addEventListener("update_team_select",onTeamUp);
         GlobalData.$mEventDispatcher.addEventListener("updata_battle_of_the_peak_defense",onFushDefense);
         onSelect(curIndex);
         liderText.x = GlobalData.$mStageWidth - liderText.width - 30;
         liderText.y = Allsp.y + Allsp.height + 30;
      }

      private function returnSpr(param1:uint, param2:uint) : Sprite
      {
         switch(int(cftNum))
         {
            case 0:
               return null;
            case 1:
               if(param1 != 2)
               {
                  return null;
               }
               return getAvatarBg(6);
               break;
            case 2:
               if(param1 != 2 && param1 != 1)
               {
                  return null;
               }
               return getAvatarBg(6);
               break;
            case 3:
               return getAvatarBg(6);
            default:
               return null;
         }
      }

      private function getAvatarBg(param1:uint) : Sprite
      {
         var _loc2_:Sprite = new Sprite();
         _loc2_.addChild(GlobalFunction.createImage("UI_bg_card_2_000" + param1));
         return _loc2_;
      }

      private function getTeamLeader(param1:int = -1) : void
      {
         var _loc4_:* = 0;
         var _loc3_:Object = null;
         var _loc2_:Avatar = null;
         leaderNum = 0;
         powerNum = 0;
         _loc4_ = 0;
         while(_loc4_ < 5)
         {
            if(GlobalData.$BattleOfThePeakDefenseTeam["team" + GlobalData.$BattleOfThePeakDefenseSelect][_loc4_] != null)
            {
               _loc3_ = GlobalData.$BattleOfThePeakDefenseTeam["team" + GlobalData.$BattleOfThePeakDefenseSelect][_loc4_];
               _loc2_ = new Avatar(_loc3_.aid,_loc3_);
               if(_loc4_ == 0)
               {
                  powerNum += _loc2_.getPowerBase104(true);
               }
               else
               {
                  powerNum += _loc2_.getPowerBase104();
               }
               leaderNum += _loc2_.getLeadership();
            }
            _loc4_++;
         }
         m_txt_Team2.text = GlobalLanguageStr.getLanguageStr(97657,GlobalFunction.getNumber(GlobalData.$BattleOfThePeakDefenseSelect + 1),Tools.formateNum(Avatar.normalizeTeamPower104(powerNum)));
         liderText.text = GlobalLanguageStr.getLanguageStr(20170,leaderNum) + "/" + GlobalFunction.getLeaderShip();
      }

      private function onTeamUp(param1:Event) : void
      {
         var _loc4_:Avatar = null;
         var _loc6_:MySprite = null;
         var _loc10_:Rectangle = null;
         var _loc9_:Image = null;
         var _loc5_:Tween = null;
         var _loc8_:Array = null;
         var _loc11_:* = 0;
         var _loc2_:MySprite = null;
         var _loc3_:Tween = null;
         var _loc7_:Object = param1.data;
         if(_loc7_.isSelect)
         {
            _loc4_ = new Avatar(_loc7_.aid,_loc7_);
            _loc6_ = new MySprite();
            _loc6_.addChild(_loc4_.getAvatarRes());
            _loc6_.name = _loc7_.aid;
            _loc10_ = GlobalData.$BattleOfThePeakDefenseItem.getBounds(this);
            _loc7_.loX = _loc10_.x;
            _loc7_.loY = _loc10_.y;
            _loc6_.LoX = _loc10_.x;
            _loc6_.LoY = _loc10_.y;
            _loc6_.x = _loc10_.x;
            _loc6_.y = _loc10_.y;
            _loc6_.scaleX = _loc6_.scaleY = 0.1;
            _loc6_.alpha = 0;
            _loc6_.addEventListener("touch",onUpCoin);
            if(_loc7_.teamNum == 0)
            {
               _loc9_ = GlobalFunction.createImage("UI_tag_leader_0_0000");
               _loc6_.addChild(_loc9_);
            }
            _loc5_ = new Tween(_loc6_,0.2);
            _loc5_.animate("alpha",1);
            _loc5_.transition = "easeOut";
            _loc5_.moveTo(teamAllArr[1][_loc7_.teamNum].x + Allsp.x,teamAllArr[1][_loc7_.teamNum].y + Allsp.y);
            _loc5_.scaleTo(1);
            _loc5_.onCompleteArgs = [_loc5_];
            _loc5_.onComplete = pushInTeamArray;
            juggler.add(_loc5_);
            this.addChild(_loc6_);
            (GlobalData.$BattleOfThePeakDefenseTeam["selectSpArr"] as Array).push(_loc6_);
         }
         else
         {
            _loc8_ = GlobalData.$BattleOfThePeakDefenseTeam["selectSpArr"] as Array;
            _loc11_ = 0;
            while(_loc11_ < _loc8_.length)
            {
               if(_loc8_[_loc11_] != null)
               {
                  if(_loc8_[_loc11_].name == _loc7_.aid)
                  {
                     if(!boolDown)
                     {
                        boolDown = true;
                        _loc2_ = _loc8_[_loc11_];
                        _loc3_ = new Tween(_loc2_,0.2);
                        _loc3_.animate("alpha",0);
                        _loc3_.transition = "easeIn";
                        _loc3_.moveTo(_loc2_.LoX,_loc2_.LoY);
                        _loc3_.scaleTo(0.1);
                        _loc3_.onCompleteArgs = [_loc3_,_loc11_];
                        _loc3_.onComplete = popInTeamArray;
                        juggler.add(_loc3_);
                     }
                  }
               }
               _loc11_++;
            }
            _loc8_ = null;
         }
         _loc7_ = null;
         getTeamLeader();
      }

      private function onFushDefense(param1:Event) : void
      {
         var _loc2_:uint = GlobalData.$BattleOfThePeakDefenseSelect + 1 > 2 ? 2 : GlobalData.$BattleOfThePeakDefenseSelect + 1;
         GlobalData.$BattleOfThePeakDefenseSelect = _loc2_;
         onSelect(_loc2_);
      }

      private function popInTeamArray(param1:Tween, param2:int) : void
      {
         var _loc3_:Array = GlobalData.$BattleOfThePeakDefenseTeam["selectSpArr"] as Array;
         _loc3_[param2].removeFromParent(true);
         _loc3_.splice(param2,1);
         _loc3_ = null;
         juggler.remove(param1);
         param1 = null;
         boolDown = false;
         getTeamLeader();
      }

      private function pushInTeamArray(param1:Tween) : void
      {
         juggler.remove(param1);
         param1 = null;
      }

      private function onUpCoin(param1:TouchEvent) : void
      {
         var _loc4_:MySprite = null;
         var _loc2_:int = 0;
         var _loc7_:Array = null;
         var _loc10_:* = 0;
         var _loc8_:* = 0;
         var _loc3_:Tween = null;
         var _loc5_:Object = null;
         var _loc6_:Object = null;
         var _loc9_:Touch = param1.getTouch(this,"ended");
         if(_loc9_)
         {
            _loc7_ = GlobalData.$BattleOfThePeakDefenseTeam["selectSpArr"] as Array;
            _loc10_ = 0;
            while(_loc10_ < _loc7_.length)
            {
               if((param1.currentTarget as MySprite).name == _loc7_[_loc10_].name)
               {
                  _loc4_ = _loc7_[_loc10_];
                  _loc2_ = _loc10_;
                  _loc4_.name = _loc7_[_loc10_].name;
               }
               _loc10_++;
            }
            _loc8_ = 0;
            while(_loc8_ < 5)
            {
               if(GlobalData.$BattleOfThePeakDefenseTeam["team" + GlobalData.$BattleOfThePeakDefenseSelect][_loc8_] != null)
               {
                  if(_loc4_.name == GlobalData.$BattleOfThePeakDefenseTeam["team" + GlobalData.$BattleOfThePeakDefenseSelect][_loc8_].aid)
                  {
                     if(!boolDown)
                     {
                        boolDown = true;
                        _loc3_ = new Tween(_loc4_,0.2);
                        _loc3_.moveTo(_loc4_.LoX,_loc4_.LoY);
                        _loc3_.scaleTo(0.2);
                        _loc3_.animate("alpha",0);
                        _loc3_.transition = "easeIn";
                        _loc3_.onCompleteArgs = [_loc3_,_loc2_];
                        _loc3_.onComplete = popInTeamArray;
                        juggler.add(_loc3_);
                        _loc5_ = GlobalData.$BattleOfThePeakDefenseTeam["team" + GlobalData.$BattleOfThePeakDefenseSelect][_loc8_];
                        _loc5_.isSelect = 0;
                        _loc6_ = {};
                        _loc6_.aid = _loc5_.aid;
                        _loc6_.team012 = _loc5_.team012;
                        GlobalData.$mEventDispatcher.dispatchEventWith("update_team_select_up_click",false,_loc6_);
                        GlobalData.$BattleOfThePeakDefenseTeam["team" + GlobalData.$BattleOfThePeakDefenseSelect][_loc8_] = null;
                     }
                  }
               }
               _loc8_++;
            }
         }
      }

      private function onSelect(param1:int) : void
      {
         var _loc9_:* = 0;
         var _loc13_:Image = null;
         var _loc4_:Sprite = null;
         var _loc14_:Object = null;
         var _loc11_:Avatar = null;
         var _loc10_:Object = null;
         var _loc6_:Object = null;
         var _loc7_:Avatar = null;
         var _loc8_:MySprite = null;
         delSelect();
         if(param1 == 0)
         {
            btnTeamLeft = GlobalFunction.createButton_normal(GlobalLanguageStr.getLanguageStr(90648));
            btnTeamRight = GlobalFunction.createButton_normal(GlobalLanguageStr.getLanguageStr(98012));
         }
         else
         {
            btnTeamLeft = GlobalFunction.createButton_normal(GlobalLanguageStr.getLanguageStr(98016));
            btnTeamRight = GlobalFunction.createButton_normal(GlobalLanguageStr.getLanguageStr(98012));
         }
         this.addChild(btnTeamLeft);
         btnTeamLeft.addEventListener("touch",btnTeamLeftClick);
         btnTeamLeft.x = GlobalData.$mStageWidth / 2 - btnTeamLeft.width - 50;
         btnTeamLeft.y = mImg9_baseBg.height - btnTeamLeft.height - 40;
         this.addChild(btnTeamRight);
         btnTeamRight.addEventListener("touch",btnTeamRightClick);
         btnTeamRight.x = GlobalData.$mStageWidth / 2 + 50;
         btnTeamRight.y = mImg9_baseBg.height - btnTeamRight.height - 40;
         if(data.data.my_attack_squad)
         {
            if(btnTeamLeft)
            {
               btnTeamLeft.x = GlobalData.$mStageWidth / 4 - btnTeamLeft.width / 2;
            }
            btnTeamRight.x = GlobalData.$mStageWidth / 2 - btnTeamRight.width / 2;
            btnNext = GlobalFunction.createButton_normal(param1 == 2 ? GlobalLanguageStr.getLanguageStr(20042) : GlobalLanguageStr.getLanguageStr(98019));
            this.addChild(btnNext);
            btnNext.addEventListener("touch",btnTeamNextClick);
            btnNext.x = GlobalData.$mStageWidth / 4 * 3 - btnTeamRight.width / 2;
            btnNext.y = mImg9_baseBg.height - btnNext.height - 40;
         }
         var _loc12_:Dictionary = GlobalData.$BattleOfThePeakDefenseTeam;
         DandM_Allicon = [];
         var _loc5_:Array = [];
         _loc9_ = 0;
         while(_loc9_ < 5)
         {
            if(data.data.team_list[param1])
            {
               if(returnSpr(GlobalData.$BattleOfThePeakDefenseSelect,_loc9_))
               {
                  _loc4_ = new Sprite();
                  _loc4_.addChild(returnSpr(GlobalData.$BattleOfThePeakDefenseSelect,_loc9_));
                  _loc4_.x = teamAllArr[0][_loc9_].x + Allsp.x;
                  _loc4_.y = teamAllArr[0][_loc9_].y + Allsp.y;
                  this.addChild(_loc4_);
                  DandM_Allicon.push(_loc4_);
               }
               else if(data.data.team_list[param1][_loc9_] != null && data.data.team_list[param1][_loc9_] != "")
               {
                  _loc14_ = data.data.team_list[param1][_loc9_];
                  _loc11_ = new Avatar(_loc14_[0],{"morph":_loc14_[_loc14_.length - 1]});
                  _loc4_ = new Sprite();
                  _loc4_.addChild(_loc11_.getAvatarRes());
                  this.addChild(_loc4_);
                  if(_loc9_ == 0)
                  {
                     _loc13_ = GlobalFunction.createImage("UI_tag_leader_0_0000");
                     _loc13_.x = _loc4_.x;
                     _loc13_.y = _loc4_.y;
                     _loc4_.addChild(_loc13_);
                  }
                  _loc4_.x = teamAllArr[0][_loc9_].x + Allsp.x;
                  _loc4_.y = teamAllArr[0][_loc9_].y + Allsp.y;
                  DandM_Allicon.push(_loc4_);
               }
            }
            else if(data.data.team_list[0][_loc9_] != null)
            {
               if(returnSpr(GlobalData.$BattleOfThePeakDefenseSelect,_loc9_))
               {
                  _loc4_ = new Sprite();
                  _loc4_.addChild(returnSpr(GlobalData.$BattleOfThePeakDefenseSelect,_loc9_));
                  _loc4_.x = teamAllArr[0][_loc9_].x + Allsp.x;
                  _loc4_.y = teamAllArr[0][_loc9_].y + Allsp.y;
                  this.addChild(_loc4_);
                  DandM_Allicon.push(_loc4_);
               }
               else
               {
                  _loc14_ = data.data.team_list[0][_loc9_];
                  _loc11_ = new Avatar(_loc14_[0]);
                  _loc4_ = new Sprite();
                  _loc4_.addChild(_loc11_.getAvatarRes());
                  this.addChild(_loc4_);
                  if(_loc9_ == 0)
                  {
                     _loc13_ = GlobalFunction.createImage("UI_tag_leader_0_0000");
                     _loc13_.x = _loc4_.x;
                     _loc13_.y = _loc4_.y;
                     _loc4_.addChild(_loc13_);
                  }
                  _loc4_.x = teamAllArr[0][_loc9_].x + Allsp.x;
                  _loc4_.y = teamAllArr[0][_loc9_].y + Allsp.y;
                  DandM_Allicon.push(_loc4_);
               }
            }
            else
            {
               _loc4_ = new Sprite();
               _loc4_.addChild(returnSpr(GlobalData.$BattleOfThePeakDefenseSelect,_loc9_));
               _loc4_.x = teamAllArr[0][_loc9_].x + Allsp.x;
               _loc4_.y = teamAllArr[0][_loc9_].y + Allsp.y;
               this.addChild(_loc4_);
               DandM_Allicon.push(_loc4_);
            }
            _loc10_ = GlobalData.$userData.avatars;
            if(_loc12_["team" + param1][_loc9_] != null && _loc12_["team" + param1][_loc9_] != "")
            {
               _loc6_ = _loc12_["team" + param1][_loc9_];
               if(_loc10_[_loc6_.aid])
               {
                  _loc7_ = new Avatar(_loc6_.aid,_loc10_[_loc6_.aid]);
                  _loc8_ = new MySprite();
                  _loc8_.name = _loc6_.aid;
                  _loc8_.LoX = GlobalData.$mStageWidth / 2;
                  _loc8_.LoY = GlobalData.$mStageHeight / 2;
                  _loc8_.addChild(_loc7_.getAvatarRes());
                  _loc8_.addEventListener("touch",onUpCoin);
                  this.addChild(_loc8_);
                  if(_loc9_ == 0)
                  {
                     _loc13_ = GlobalFunction.createImage("UI_tag_leader_0_0000");
                     _loc13_.x = _loc8_.x;
                     _loc13_.y = _loc8_.y;
                     _loc8_.addChild(_loc13_);
                  }
                  _loc8_.x = teamAllArr[1][_loc9_].x + Allsp.x;
                  _loc8_.y = teamAllArr[1][_loc9_].y + Allsp.y;
                  (GlobalData.$BattleOfThePeakDefenseTeam["selectSpArr"] as Array).push(_loc8_);
               }
            }
            _loc9_++;
         }
         var _loc2_:Number = Number(data.data.power_list[param1] ? data.data.power_list[param1] : data.data.power_list[0]);
         var _loc3_:Number = GlobalFunction.getTeamPower(_loc5_);
         m_txt_Team1.text = GlobalLanguageStr.getLanguageStr(97656,GlobalFunction.getNumber(param1 + 1),Tools.formateNum(Tools.toInt(_loc2_)));
         m_txt_Team2.text = GlobalLanguageStr.getLanguageStr(97657,GlobalFunction.getNumber(param1 + 1),Tools.formateNum(Avatar.normalizeTeamPower104(powerNum)));
         setList();
         addList();
         getTeamLeader(param1 + 1);
      }

      override public function setList() : void
      {
         var _loc3_:Number = NaN;
         var _loc2_:Object = null;
         var _loc1_:TiledRowsLayout = null;
         this.delList();
         if(this.mList == null)
         {
            _loc3_ = 80;
            _loc2_ = {
               "paging":0,
               "gap":0,
               "horizontalGap":5,
               "verticalGap":15,
               "paddingTop":5,
               "paddingRight":0,
               "paddingBottom":20,
               "paddingLeft":10,
               "horizontalAlign":"center",
               "verticalAlign":"top",
               "tileHorizontalAlign":"left",
               "tileVerticalAlign":"top"
            };
            _loc1_ = new TiledRowsLayout();
            _loc1_.useSquareTiles = false;
            _loc1_.horizontalGap = _loc2_.horizontalGap;
            _loc1_.verticalGap = _loc2_.verticalGap;
            _loc1_.paging = _loc2_.paging;
            _loc1_.paddingTop = _loc2_.paddingTop;
            _loc1_.paddingRight = _loc2_.paddingRight;
            _loc1_.paddingBottom = _loc2_.paddingBottom;
            _loc1_.paddingLeft = _loc2_.paddingLeft;
            _loc1_.horizontalAlign = _loc2_.horizontalAlign;
            _loc1_.verticalAlign = _loc2_.verticalAlign;
            _loc1_.tileHorizontalAlign = _loc2_.tileHorizontalAlign;
            _loc1_.tileVerticalAlign = _loc2_.tileVerticalAlign;
            this.mList = new List();
            this.mList.clipContent = true;
            this.mList.autoHideBackground = true;
            this.mList.isSelectable = false;
            this.mList.width = GlobalData.$mStageWidth - 20;
            this.mList.height = 219;
            this.mList.layout = _loc1_;
            this.mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
            this.mList.x = int((GlobalData.$mStageWidth - this.mList.width) * 0.5);
            this.mList.y = Allsp.y + Allsp.height + 75;
            this.mList.snapScrollPositionsToPixels = true;
            this.addChild(this.mList);
            _loc2_ = null;
            _loc1_ = null;
            this.mList.dataProvider = new ListCollection();
         }
      }

      override public function addList() : void
      {
         var _loc8_:Object = null;
         var _loc7_:* = null;
         var _loc1_:Avatar = null;
         var _loc6_:* = 0;
         var _loc5_:* = 0;
         var _loc2_:Array = [];
         var _loc3_:Object = Tools.clone(GlobalData.$userData.avatars);
         var _loc4_:String = "";
         for(var _loc9_:String in _loc3_)
         {
            _loc4_ = _loc9_;
            if(GlobalFunction.checkSearchTypeByType(_loc4_,1))
            {
               _loc1_ = new Avatar(_loc4_,_loc3_[_loc9_]);
               _loc8_ = _loc3_[_loc9_];
               _loc6_ = 0;
               while(_loc6_ < 3)
               {
                  _loc5_ = 0;
                  while(_loc5_ < GlobalData.$BattleOfThePeakDefenseTeam["team" + _loc6_].length)
                  {
                     if(GlobalData.$BattleOfThePeakDefenseTeam["team" + _loc6_][_loc5_])
                     {
                        if(GlobalData.$BattleOfThePeakDefenseTeam["team" + _loc6_][_loc5_].aid == _loc4_)
                        {
                           _loc8_.team012 = GlobalData.$BattleOfThePeakDefenseTeam["team" + _loc6_][_loc5_].team012;
                           _loc8_.teamNum = GlobalData.$BattleOfThePeakDefenseTeam["team" + _loc6_][_loc5_].teamNum;
                        }
                     }
                     _loc5_++;
                  }
                  _loc6_++;
               }
               _loc8_["aid"] = _loc4_;
               _loc8_["star"] = _loc1_.getStar();
               _loc8_["lv"] = _loc1_.lv;
               _loc8_["choice"] = false;
               _loc8_["power"] = _loc1_.getPower(true);
               _loc2_.push(_loc8_);
               _loc1_.clear();
               _loc1_ = null;
            }
         }
         _loc2_.sortOn(["team012","teamNum","power","star","lv","aid"],[16,16,0x10 | 2,0x10 | 2,0x10 | 2,1]);
         this.setListTimer(mList,_loc2_,ItemPVPBattleOfThePeakDefense,false);
      }

      private function btnTeamNextClick(param1:TouchEvent) : void
      {
         var _loc12_:Boolean = false;
         var _loc6_:Dictionary = null;
         var _loc4_:Object = null;
         var _loc10_:* = 0;
         var _loc5_:Object = null;
         var _loc2_:Array = null;
         var _loc16_:Array = null;
         var _loc11_:Array = null;
         var _loc7_:Array = null;
         var _loc3_:int = 0;
         var _loc14_:Array = null;
         var _loc8_:* = 0;
         var _loc15_:Object = null;
         var _loc9_:Touch = param1.getTouch(this,"ended");
         if(_loc9_)
         {
            _loc12_ = false;
            _loc6_ = GlobalData.$BattleOfThePeakDefenseTeam;
            _loc4_ = GlobalData.$userData.attrs.defensive_squad_before;
            if(_loc4_)
            {
               if(_loc4_[GlobalData.$BattleOfThePeakDefenseSelect])
               {
                  GlobalData.$BattleOfThePeakDefenseSelect += 1;
                  onSelect(GlobalData.$BattleOfThePeakDefenseSelect);
                  return;
               }
            }
            _loc10_ = 0;
            while(_loc10_ < 5)
            {
               if(data.data.my_attack_squad[GlobalData.$BattleOfThePeakDefenseSelect][_loc10_] != "" && _loc6_["team" + GlobalData.$BattleOfThePeakDefenseSelect][_loc10_] != null)
               {
                  if(data.data.my_attack_squad[GlobalData.$BattleOfThePeakDefenseSelect][_loc10_][0] != _loc6_["team" + GlobalData.$BattleOfThePeakDefenseSelect][_loc10_].aid)
                  {
                     _loc12_ = false;
                     break;
                  }
                  _loc12_ = true;
               }
               else
               {
                  if(data.data.my_attack_squad[GlobalData.$BattleOfThePeakDefenseSelect][_loc10_] != "" || _loc6_["team" + GlobalData.$BattleOfThePeakDefenseSelect][_loc10_] != null)
                  {
                     _loc12_ = false;
                     break;
                  }
                  _loc12_ = true;
               }
               _loc10_++;
            }
            if(!_loc12_)
            {
               if(leaderNum > GlobalFunction.getLeaderShip())
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10015),false);
                  return;
               }
               if(GlobalData.$BattleOfThePeakDefenseSelect == 0)
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(98017),false);
               }
               btnTeamRightClick();
               return;
            }
            if(leaderNum > GlobalFunction.getLeaderShip())
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10015),false);
               return;
            }
            _loc5_ = GlobalFunction.getFragmentPower();
            _loc2_ = GlobalData.$mConfig_simple.cross_pvp.cross_server_pvp;
            if(_loc5_.energy < _loc2_[1])
            {
               GlobalFunction.sevice_pvp_buy(GlobalLanguageStr.getLanguageStr(20098));
               return;
            }
            GlobalData.$userData.sendFightData.oldteams[GlobalData.$BattleOfThePeakDefenseSelect] = data.data.my_attack_squad[GlobalData.$BattleOfThePeakDefenseSelect];
            if(GlobalData.$BattleOfThePeakDefenseSelect == 2)
            {
               if(!GlobalData.$userData.attrs.defensive_squad_before)
               {
                  GlobalData.$userData.attrs.defensive_squad_before = [];
               }
               _loc16_ = GlobalData.$userData.attrs.defensive_squad_before;
               GlobalData.$BattleOfThePeakTure = true;
               _loc11_ = [];
               _loc10_ = 0;
               while(_loc10_ < 3)
               {
                  _loc7_ = [];
                  _loc3_ = 0;
                  _loc14_ = GlobalData.$BattleOfThePeakDefenseTeam["team" + _loc10_];
                  _loc8_ = 0;
                  while(_loc8_ < 5)
                  {
                     if(_loc16_[_loc10_])
                     {
                        if(_loc14_[_loc8_])
                        {
                           _loc7_.push(_loc16_[_loc10_][_loc3_]);
                           _loc3_++;
                        }
                        else
                        {
                           _loc7_.push("");
                        }
                     }
                     _loc8_++;
                  }
                  _loc11_.push(_loc7_);
                  _loc10_++;
               }
               GlobalData.$userData.sendFightData.teams = _loc11_;
               for(var _loc13_:String in GlobalData.$userData.sendFightData.oldteams)
               {
                  if(GlobalData.$userData.sendFightData.oldteams[_loc13_])
                  {
                     _loc11_[int(_loc13_)] = GlobalData.$userData.sendFightData.oldteams[_loc13_];
                  }
               }
               _loc15_ = GlobalData.$userData.sendFightData;
               GlobalData.$userData.sendFightData.oldteams = null;
               GameMap.isLoadFile = false;
               SendServiceAMFFun.pk_combat_cross_server_pvp(fight,GlobalData.$userData.sendFightData);
               SoundManager.getOnlyExample().playSound("sound01",0.3);
               return;
            }
            GlobalData.$BattleOfThePeakDefenseSelect += 1;
            onSelect(GlobalData.$BattleOfThePeakDefenseSelect);
         }
      }

      private function fight(param1:Object) : void
      {
         var _loc4_:* = 0;
         if(param1.data.server_pvp_num)
         {
            GlobalData.$userData.records.server_pvp_num = param1.data.server_pvp_num;
         }
         GlobalData.$userData.attrs.defensive_squad_before = null;
         GlobalData.$m15v15FightData = param1;
         if(GameMap.currentMap)
         {
            GameMap.currentMap.clear();
         }
         var _loc3_:Object = GlobalData.$m15v15FightData;
         _loc4_ = 0;
         while(_loc4_ < _loc3_.data.combat_res.length)
         {
            _loc3_.data.combat_res[_loc4_].Screenings = _loc4_ + 1;
            _loc4_++;
         }
         var _loc6_:Object = {};
         _loc6_.data = _loc3_.data.combat_res[0];
         if(_loc3_.data.combat_res.length == 1)
         {
            _loc6_.data.win_gift = _loc3_.data.win_gift;
         }
         _loc6_.data.users = _loc3_.data.users;
         _loc6_.data.glod = GlobalData.$userData.gold;
         _loc6_.data.combat_score = GlobalData.$userData.combat_score;
         (GlobalData.$m15v15FightData.data.combat_res as Array).shift();
         var _loc5_:GameMap = new GameMap("battle_of_the_peak",-1);
         var _loc2_:Game = GlobalData.$mGameClassObject;
         _loc2_.removeChildren(1,-1);
         _loc2_.addChild(GameMapLayer.gl.mapStage);
         _loc5_.initByOrgin(_loc6_);
         _loc5_.randomSeed = _loc6_.data.seed;
         _loc5_.re = _loc6_;
         _loc5_.checkOrginTeam();
         _loc5_.readyFight();
      }

      private function btnTeamLeftClick(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(this,"ended");
         if(_loc2_)
         {
            switch(GlobalData.$BattleOfThePeakDefenseSelect)
            {
               case 0:
                  GlobalData.$BattleOfThePeakDefenseTeam["team0"] = [];
                  GlobalData.$BattleOfThePeakDefenseTeam["team1"] = [];
                  GlobalData.$BattleOfThePeakDefenseTeam["team2"] = [];
                  GlobalData.$userData.attrs.defensive_squad_before = null;
                  onSelect(0);
                  break;
               case 1:
                  curIndex = 0;
                  GlobalData.$userData.sendFightData.oldteams[GlobalData.$BattleOfThePeakDefenseSelect] = null;
                  GlobalData.$BattleOfThePeakDefenseSelect = 0;
                  onSelect(0);
                  break;
               case 2:
                  curIndex = 1;
                  GlobalData.$userData.sendFightData.oldteams[GlobalData.$BattleOfThePeakDefenseSelect] = null;
                  GlobalData.$BattleOfThePeakDefenseSelect = 1;
                  onSelect(1);
            }
         }
      }

      private function btnTeamRightClick(param1:TouchEvent = null) : void
      {
         var _loc2_:Touch = param1 ? param1.getTouch(this,"ended") : null;
         if(_loc2_ || param1 == null)
         {
            if(leaderNum > GlobalFunction.getLeaderShip())
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10015),false);
               return;
            }
            if(GlobalData.$BattleOfThePeakDefenseTeam["selectSpArr"].length <= 1)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(98018,2),false);
               return;
            }
            if(GlobalData.$BattleOfThePeakDefenseTeam["team" + GlobalData.$BattleOfThePeakDefenseSelect][0] == null)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10132),false);
               return;
            }
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("pvp_battle-of-the-peak_game_start");
         }
      }

      private function delSelect() : void
      {
         var _loc2_:* = 0;
         var _loc1_:Array = GlobalData.$BattleOfThePeakDefenseTeam["selectSpArr"];
         _loc2_ = 0;
         while(_loc2_ < 5)
         {
            if(_loc1_[_loc2_] != null)
            {
               juggler.removeTweens(_loc1_[_loc2_]);
               (_loc1_[_loc2_] as MySprite).removeEventListener("touch",onUpCoin);
               _loc1_[_loc2_].removeFromParent(true);
            }
            _loc2_++;
         }
         GlobalData.$BattleOfThePeakDefenseTeam["selectSpArr"] = [];
         if(btnTeamLeft)
         {
            btnTeamLeft.removeEventListener("touch",btnTeamLeftClick);
            btnTeamLeft.removeFromParent(true);
            btnTeamLeft.dispose();
         }
         if(btnNext)
         {
            btnNext.removeEventListener("touch",btnTeamNextClick);
            btnNext.removeFromParent(true);
            btnNext.dispose();
         }
         btnNext = null;
         if(btnTeamRight)
         {
            btnTeamRight.removeEventListener("touch",btnTeamRightClick);
            btnTeamRight.removeFromParent(true);
            btnTeamRight.dispose();
         }
         if(DandM_Allicon)
         {
            _loc2_ = 0;
            while(_loc2_ < DandM_Allicon.length)
            {
               DandM_Allicon[_loc2_].removeFromParent(true);
               DandM_Allicon[_loc2_].dispose();
               DandM_Allicon.unshift();
               _loc2_++;
            }
         }
         DandM_Allicon = null;
         btnTeamRight = null;
         btnTeamLeft = null;
      }
   }
}

import starling.display.Sprite;

class MySprite extends Sprite
{

   private var loX:Number;

   private var loY:Number;

   private var _name:String;

   public function MySprite()
   {
      super();
   }

   override public function get name() : String
   {
      return _name;
   }

   override public function set name(param1:String) : void
   {
      _name = param1;
   }

   public function get LoX() : Number
   {
      return loX;
   }

   public function set LoX(param1:Number) : void
   {
      loX = param1;
   }

   public function get LoY() : Number
   {
      return loY;
   }

   public function set LoY(param1:Number) : void
   {
      loY = param1;
   }
}
