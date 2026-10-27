package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.element.ItemPVPBattleOfThePeak;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.screen.PanelCenterPVE;
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

   public class PanelActivityPVPBattleOfThePeak extends PanelCenterPVE
   {

      private var teamAllArr:Array;

      private var Allsp:Sprite;

      private var selectIndex:int = 0;

      private var juggler:Juggler;

      private var boolDown:Boolean = false;

      private var pzButton:LOL_Button;

      private var liderText:TextField;

      private var mBg_list:Scale9Image;

      private var leaderNum:Number = 0;

      private var powerNum:Number = 0;

      private var m_img_Team1:Image;

      private var m_txt_Team1:TextField;

      private var btnTeamLeft:LOL_Button;

      public function PanelActivityPVPBattleOfThePeak()
      {
         super();
      }

      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         var _loc2_:* = 0;
         GlobalData.$mEventDispatcher.removeEventListener("update_team_select",onTeamUp);
         GlobalData.$mEventDispatcher.removeEventListener("updata_battle_of_the_peak_defense",onFushDefense);
         _loc2_ = 0;
         while(_loc2_ < GlobalData.$BattleOfThePeakTeam["selectSpArr"].length)
         {
            if(GlobalData.$BattleOfThePeakTeam["selectSpArr"][_loc2_] != null)
            {
               juggler.removeTweens(GlobalData.$BattleOfThePeakTeam["selectSpArr"][_loc2_]);
               (GlobalData.$BattleOfThePeakTeam["selectSpArr"][_loc2_] as MySprite).removeEventListener("touch",onUpCoin);
               GlobalData.$BattleOfThePeakTeam["selectSpArr"][_loc2_].removeFromParent(true);
               (GlobalData.$BattleOfThePeakTeam["selectSpArr"] as Array).splice(_loc2_,1);
            }
            _loc2_++;
         }
         GlobalData.$BattleOfThePeakTeam["team0"] = [];
         GlobalData.$BattleOfThePeakTeam["team1"] = [];
         GlobalData.$BattleOfThePeakTeam["team2"] = [];
         if(Allsp)
         {
            Allsp.removeFromParent(true);
            Allsp.dispose();
         }
         if(mBg_list)
         {
            mBg_list.removeFromParent(true);
            mBg_list.dispose();
         }
         if(liderText)
         {
            liderText.removeFromParent(true);
            liderText.dispose();
         }
         mBg_list = null;
         liderText = null;
         GlobalData.$BattleOfThePeakTeam["selectSpArr"] = [];
         teamAllArr = [];
         juggler = null;
         Allsp = null;
         super.onREMOVED_FROM_STAGE(param1);
      }

      override protected function initializeHandler(param1:Event) : void
      {
         var _loc9_:* = 0;
         var _loc3_:Sprite = null;
         var _loc14_:Image = null;
         var _loc15_:TextField = null;
         var _loc16_:Object = null;
         var _loc5_:Object = null;
         var _loc11_:* = null;
         var _loc8_:String = null;
         var _loc2_:Avatar = null;
         var _loc6_:Dictionary = null;
         var _loc4_:Array = null;
         var _loc10_:* = 0;
         var _loc13_:Array = null;
         removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getStr(96564),750);
         juggler = Starling.juggler;
         GlobalData.$BattleOfThePeakTeamSelect = 0;
         if(GlobalData.$BattleOfThePeakTeam == null)
         {
            GlobalData.$BattleOfThePeakTeam = new Dictionary();
            GlobalData.$BattleOfThePeakTeam["team0"] = [];
            GlobalData.$BattleOfThePeakTeam["team1"] = [];
            GlobalData.$BattleOfThePeakTeam["team2"] = [];
            GlobalData.$BattleOfThePeakTeam["teamNo0"] = 0;
            GlobalData.$BattleOfThePeakTeam["teamNo1"] = 0;
            GlobalData.$BattleOfThePeakTeam["teamNo2"] = 0;
            GlobalData.$BattleOfThePeakTeam["selectSpArr"] = [];
         }
         if(GlobalData.$BattleOfThePeakTeam["selectSpArr"] != undefined)
         {
            GlobalData.$BattleOfThePeakTeam["selectSpArr"] = [];
         }
         teamAllArr = [];
         Allsp = new Sprite();
         this.addChild(Allsp);
         _loc9_ = 0;
         while(_loc9_ < 5)
         {
            _loc3_ = new Sprite();
            _loc14_ = GlobalFunction.createImage("UI_bg_card_2_0002");
            _loc3_.addChild(_loc14_);
            _loc15_ = DisplayTools.newTextField("" + (_loc9_ + 1),"Font_numAndtag_1",40,16777215);
            _loc15_.pivotX = _loc15_.width * 0.5;
            _loc15_.pivotY = _loc15_.height * 0.5;
            _loc15_.x = _loc14_.x + _loc14_.width * 0.5;
            _loc15_.y = _loc14_.height * 0.5;
            _loc3_.addChild(_loc15_);
            teamAllArr.push(_loc3_);
            Allsp.addChild(_loc3_);
            _loc3_.x = _loc9_ * _loc14_.width;
            _loc3_.y = _loc3_.height;
            _loc9_++;
         }
         Allsp.x = GlobalData.$mStageWidth / 2 - Allsp.width / 2;
         Allsp.y = 30;
         if(GlobalData.$userData.attrs.defensive_squad)
         {
            _loc5_ = Tools.clone(GlobalData.$userData.avatars);
            _loc8_ = "";
            _loc6_ = GlobalData.$BattleOfThePeakTeam;
            for(var _loc12_:String in _loc5_)
            {
               _loc8_ = _loc12_;
               if(GlobalFunction.checkSearchTypeByType(_loc8_,1))
               {
                  _loc4_ = GlobalData.$userData.attrs.defensive_squad;
                  _loc10_ = 0;
                  while(_loc10_ < _loc4_.length)
                  {
                     _loc13_ = _loc4_[_loc10_];
                     _loc9_ = 0;
                     while(_loc9_ < _loc13_.length)
                     {
                        if(_loc13_[_loc9_])
                        {
                           if(_loc13_[_loc9_][0] == _loc8_)
                           {
                              if(_loc5_[_loc8_])
                              {
                                 _loc2_ = new Avatar(_loc8_,_loc5_[_loc8_]);
                                 _loc16_ = _loc5_[_loc12_];
                                 if(!_loc16_["aid"])
                                 {
                                    _loc16_["aid"] = _loc8_;
                                 }
                                 _loc16_["team012"] = _loc10_;
                                 _loc16_["teamNum"] = _loc9_;
                                 _loc16_["isSelect"] = 1;
                                 _loc16_["loX"] = GlobalData.$mStageWidth / 2;
                                 _loc16_["loY"] = GlobalData.$mStageHeight / 2;
                                 GlobalData.$BattleOfThePeakTeam["team" + _loc10_][_loc9_] = _loc16_;
                                 _loc2_.clear();
                                 _loc2_ = null;
                              }
                              else
                              {
                                 GlobalData.$BattleOfThePeakTeam["team" + _loc10_][_loc9_] = null;
                              }
                           }
                        }
                        else
                        {
                           GlobalData.$BattleOfThePeakTeam["team" + _loc10_][_loc9_] = null;
                        }
                        _loc9_++;
                     }
                     _loc10_++;
                  }
               }
            }
         }
         var _loc7_:Dictionary = GlobalData.$BattleOfThePeakTeam;
         m_img_Team1 = GlobalFunction.createImage("UI_extreme_bg_1_0000");
         m_img_Team1.x = GlobalData.$mStageWidth / 2 - m_img_Team1.width / 2;
         m_img_Team1.y = 80;
         this.addChild(m_img_Team1);
         m_txt_Team1 = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97657,GlobalFunction.getNumber(1)),20,1118481,"center",500,35);
         m_txt_Team1.x = GlobalData.$mStageWidth / 2 - m_txt_Team1.width / 2;
         m_txt_Team1.y = m_img_Team1.y + 10;
         this.addChild(m_txt_Team1);
         mBg_list = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",GlobalData.$mStageWidth - 60,350,new Rectangle(110,55,70,20));
         mBg_list.x = int((GlobalData.$mStageWidth - mBg_list.width) * 0.5);
         mBg_list.y = 290;
         addChild(mBg_list);
         liderText = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20170,leaderNum) + "/" + GlobalFunction.getLeaderShip(),20,16777215,"right",800,46);
         liderText.x = GlobalData.$mStageWidth - liderText.width - 30;
         liderText.y = mBg_list.y - 30;
         this.addChild(liderText);
         setUI();
      }

      private function setUI() : void
      {
         onSelect(0);
         setList();
         addList();
         GlobalData.$mEventDispatcher.addEventListener("update_team_select",onTeamUp);
         GlobalData.$mEventDispatcher.addEventListener("updata_battle_of_the_peak_defense",onFushDefense);
      }

      private function onFushDefense(param1:Event) : void
      {
         if(GlobalData.$BattleOfThePeakTeamSelect + 1 > 2)
         {
            onCLOSE_PANEL_SELF();
            return;
         }
         var _loc2_:uint = GlobalData.$BattleOfThePeakTeamSelect + 1;
         GlobalData.$BattleOfThePeakTeamSelect = _loc2_;
         setList();
         addList();
         onSelect(_loc2_);
      }

      private function onSelect(param1:int) : void
      {
         var _loc6_:* = 0;
         var _loc4_:Object = null;
         var _loc3_:Avatar = null;
         var _loc2_:MySprite = null;
         var _loc5_:Image = null;
         delSelect();
         pzButton = GlobalFunction.createButton_normal(GlobalLanguageStr.getLanguageStr(98012));
         pzButton.addEventListener("touch",pzButtonFun);
         this.addChild(pzButton);
         pzButton.x = GlobalData.$mStageWidth / 2 + 50;
         pzButton.y = mImg9_baseBg.height - pzButton.height - 30;
         btnTeamLeft = GlobalFunction.createButton_normal(GlobalLanguageStr.getLanguageStr(90648));
         btnTeamLeft.addEventListener("touch",LeftButtonFun);
         this.addChild(btnTeamLeft);
         btnTeamLeft.x = GlobalData.$mStageWidth / 2 - btnTeamLeft.width - 50;
         btnTeamLeft.y = mImg9_baseBg.height - btnTeamLeft.height - 30;
         if(GlobalData.$BattleOfThePeakTeam != null)
         {
            _loc6_ = 0;
            while(_loc6_ < 5)
            {
               if(GlobalData.$BattleOfThePeakTeam["team" + GlobalData.$BattleOfThePeakTeamSelect][_loc6_] != null)
               {
                  _loc4_ = GlobalData.$BattleOfThePeakTeam["team" + GlobalData.$BattleOfThePeakTeamSelect][_loc6_];
                  _loc3_ = new Avatar(_loc4_.aid,_loc4_);
                  _loc2_ = new MySprite();
                  _loc2_.addChild(_loc3_.getAvatarRes());
                  _loc2_.name = _loc4_.aid;
                  _loc2_.LoX = _loc4_.loX;
                  _loc2_.LoY = _loc4_.loY;
                  this.addChild(_loc2_);
                  if(_loc6_ == 0)
                  {
                     _loc5_ = GlobalFunction.createImage("UI_tag_leader_0_0000");
                     _loc5_.x = _loc2_.x;
                     _loc5_.y = _loc2_.y;
                     _loc2_.addChild(_loc5_);
                  }
                  _loc2_.addEventListener("touch",onUpCoin);
                  (GlobalData.$BattleOfThePeakTeam["selectSpArr"] as Array).push(_loc2_);
                  _loc2_.x = teamAllArr[_loc4_.teamNum].x + Allsp.x;
                  _loc2_.y = teamAllArr[_loc4_.teamNum].y + Allsp.y;
               }
               _loc6_++;
            }
         }
         getTeamLeader();
      }

      private function LeftButtonFun(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(this,"ended");
         if(_loc2_)
         {
            GlobalData.$BattleOfThePeakTeam["team0"] = [];
            GlobalData.$BattleOfThePeakTeam["team1"] = [];
            GlobalData.$BattleOfThePeakTeam["team2"] = [];
            setList();
            addList();
            GlobalData.$BattleOfThePeakTeamSelect = 0;
            onSelect(0);
         }
      }

      private function getTeamLeader() : void
      {
         var _loc3_:* = 0;
         var _loc2_:Object = null;
         var _loc1_:Avatar = null;
         leaderNum = 0;
         powerNum = 0;
         _loc3_ = 0;
         while(_loc3_ < 5)
         {
            if(GlobalData.$BattleOfThePeakTeam["team" + GlobalData.$BattleOfThePeakTeamSelect][_loc3_] != null)
            {
               _loc2_ = GlobalData.$BattleOfThePeakTeam["team" + GlobalData.$BattleOfThePeakTeamSelect][_loc3_];
               _loc1_ = new Avatar(_loc2_.aid,_loc2_);
               if(_loc3_ == 0)
               {
                  powerNum += _loc1_.getPowerBase104(true);
               }
               else
               {
                  powerNum += _loc1_.getPowerBase104();
               }
               leaderNum += _loc1_.getLeadership();
            }
            _loc3_++;
         }
         m_txt_Team1.text = GlobalLanguageStr.getLanguageStr(97657,GlobalFunction.getNumber(GlobalData.$BattleOfThePeakTeamSelect + 1),Tools.formateNum(Avatar.normalizeTeamPower104(powerNum)));
         liderText.text = GlobalLanguageStr.getLanguageStr(20170,leaderNum) + "/" + GlobalFunction.getLeaderShip();
      }

      private function pzButtonFun(param1:TouchEvent) : void
      {
         var _loc2_:* = 0;
         var _loc4_:* = 0;
         var _loc3_:Touch = param1.getTouch(this,"ended");
         if(_loc3_)
         {
            if(leaderNum > GlobalFunction.getLeaderShip())
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10015),false);
               return;
            }
            _loc2_ = 0;
            _loc4_ = 0;
            while(_loc4_ < GlobalData.$BattleOfThePeakTeam["team" + GlobalData.$BattleOfThePeakTeamSelect].length)
            {
               if(GlobalData.$BattleOfThePeakTeam["team" + GlobalData.$BattleOfThePeakTeamSelect][_loc4_] && GlobalData.$BattleOfThePeakTeam["team" + GlobalData.$BattleOfThePeakTeamSelect] != "")
               {
                  _loc2_++;
               }
               _loc4_++;
            }
            if(_loc2_ < 2)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(98015,2),false);
               return;
            }
            if(GlobalData.$BattleOfThePeakTeam["team" + GlobalData.$BattleOfThePeakTeamSelect][0] == null || GlobalData.$BattleOfThePeakTeam["team" + GlobalData.$BattleOfThePeakTeamSelect] == "")
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10132),false);
               return;
            }
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("pvp_battle-of-the-peak_game_start");
         }
      }

      private function delSelect() : void
      {
         var _loc1_:Array = null;
         var _loc2_:* = 0;
         if(GlobalData.$BattleOfThePeakTeam != null)
         {
            _loc1_ = GlobalData.$BattleOfThePeakTeam["selectSpArr"];
            _loc2_ = 0;
            while(_loc2_ < _loc1_.length)
            {
               if(_loc1_[_loc2_] != null)
               {
                  (_loc1_[_loc2_] as MySprite).removeEventListener("touch",onUpCoin);
                  _loc1_[_loc2_].removeFromParent(true);
                  _loc1_[_loc2_].dispose();
               }
               _loc2_++;
            }
            GlobalData.$BattleOfThePeakTeam["selectSpArr"] = [];
         }
         if(pzButton)
         {
            pzButton.addEventListener("touch",pzButtonFun);
            pzButton.removeFromParent(true);
            pzButton.dispose();
         }
         if(btnTeamLeft)
         {
            btnTeamLeft;
         }
         btnTeamLeft = null;
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
            _loc10_ = GlobalData.$BattleOfThePeakItem.getBounds(this);
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
            _loc5_.moveTo(teamAllArr[_loc7_.teamNum].x + Allsp.x,teamAllArr[_loc7_.teamNum].y + Allsp.y);
            _loc5_.scaleTo(1);
            _loc5_.onCompleteArgs = [_loc5_];
            _loc5_.onComplete = pushInTeamArray;
            juggler.add(_loc5_);
            this.addChild(_loc6_);
            (GlobalData.$BattleOfThePeakTeam["selectSpArr"] as Array).push(_loc6_);
         }
         else
         {
            _loc8_ = GlobalData.$BattleOfThePeakTeam["selectSpArr"] as Array;
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
                        _loc4_ = new Avatar(_loc7_.aid,_loc7_);
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

      private function popInTeamArray(param1:Tween, param2:int) : void
      {
         var _loc3_:Array = GlobalData.$BattleOfThePeakTeam["selectSpArr"] as Array;
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
            _loc7_ = GlobalData.$BattleOfThePeakTeam["selectSpArr"] as Array;
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
               if(GlobalData.$BattleOfThePeakTeam["team" + GlobalData.$BattleOfThePeakTeamSelect][_loc8_] != null)
               {
                  if(_loc4_.name == GlobalData.$BattleOfThePeakTeam["team" + GlobalData.$BattleOfThePeakTeamSelect][_loc8_].aid)
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
                        _loc5_ = GlobalData.$BattleOfThePeakTeam["team" + GlobalData.$BattleOfThePeakTeamSelect][_loc8_];
                        _loc5_.isSelect = 0;
                        _loc6_ = {};
                        _loc6_.aid = _loc5_.aid;
                        _loc6_.team012 = _loc5_.team012;
                        GlobalData.$mEventDispatcher.dispatchEventWith("update_team_select_up_click",false,_loc6_);
                        GlobalData.$BattleOfThePeakTeam["team" + GlobalData.$BattleOfThePeakTeamSelect][_loc8_] = null;
                     }
                  }
               }
               _loc8_++;
            }
         }
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
            this.mList.height = 314;
            this.mList.layout = _loc1_;
            this.mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
            this.mList.x = int((GlobalData.$mStageWidth - this.mList.width) * 0.5);
            this.mList.y = 50 + Allsp.height * 2 + 25;
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
                  while(_loc5_ < GlobalData.$BattleOfThePeakTeam["team" + _loc6_].length)
                  {
                     if(GlobalData.$BattleOfThePeakTeam["team" + _loc6_][_loc5_])
                     {
                        if(GlobalData.$BattleOfThePeakTeam["team" + _loc6_][_loc5_].aid == _loc4_)
                        {
                           _loc8_.team012 = GlobalData.$BattleOfThePeakTeam["team" + _loc6_][_loc5_].team012;
                           _loc8_.teamNum = GlobalData.$BattleOfThePeakTeam["team" + _loc6_][_loc5_].teamNum;
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
         this.setListTimer(mList,_loc2_,ItemPVPBattleOfThePeak,false);
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
