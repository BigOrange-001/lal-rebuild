package com.meng52.game.ui.screen
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.ui.element.ItemBase;
   import com.meng52.game.ui.element.ItemGuildFight;
   import com.meng52.game.ui.element.ItemPVEcombat;
   import com.meng52.game.ui.element.ItemPVEmain;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_TextField;
   import com.meng52.game.ui.stage.GuideTools;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.data.ListCollection;
   import feathers.display.Scale3Image;
   import feathers.display.Scale9Image;
   import feathers.layout.HorizontalLayout;
   import feathers.layout.TiledRowsLayout;
   import feathers.layout.VerticalLayout;
   import starling.display.DisplayObjectContainer;
   import starling.display.Image;
   import starling.display.MovieClip;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class PanelCenterPVE extends PanelCenterMainAvatar
   {
      
      public static const PLOY_SHOW_LEVEL_D:int = 3;
      
      public static var $currData:Object;
      
      private var rndAvatar:Avatar;
      
      private var rndCid:String;
      
      private var rndBox:Sprite;
      
      private var m_mapTf:TextField;
      
      private var _mc1:MovieClip;
      
      private var _mc2:MovieClip;
      
      private var mBtn_ran:LOL_Button;
      
      public var mImg_head:Image;
      
      public var mImg_right:Image;
      
      public var mImg_left:Image;
      
      public var mImg3_info:Scale3Image;
      
      public var mImg9_info:Scale9Image;
      
      private var _awardSprite:Sprite;
      
      private var _imgStar:Image;
      
      private var _txtStar:TextFieldHtmlRenderer;
      
      private var _getAward:LOL_Button;
      
      private var _starObj:Object;
      
      private var isJY:Boolean = false;
      
      public function PanelCenterPVE()
      {
         super();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalData.$mEventDispatcher.removeEventListener("update_pve_combat_list",onUPDATE_PVE_COMBAT_LIST);
         GlobalData.$mStarling.juggler.removeTweens(this);
         this.clearAvatar();
         this.clearTabBarBaseFun();
         super.onREMOVED_FROM_STAGE(param1);
         $currData = null;
      }
      
      public function clearAvatar() : void
      {
         if(rndAvatar)
         {
            rndAvatar.clear();
            rndAvatar = null;
         }
         if(rndBox)
         {
            StarlingTools.removeChildrenClear(rndBox);
            rndBox.removeFromParent(true);
            rndBox = null;
         }
         if(m_mapTf)
         {
            m_mapTf.dispose();
            m_mapTf = null;
         }
         rndCid = null;
         if(_mc1)
         {
            _mc1.removeFromParent(true);
            _mc1 = null;
         }
         if(_mc2)
         {
            _mc2.removeFromParent(true);
            _mc2 = null;
         }
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         mImg_head = getImg_headBg();
         addChild(mImg_head);
         this.setTabBar([{
            "label":GlobalLanguageStr.getLanguageStr(20253),
            "indexID":0
         },{
            "label":GlobalLanguageStr.getLanguageStr(20254),
            "indexID":1
         },{
            "label":GlobalLanguageStr.getLanguageStr(20029),
            "indexID":2
         }],tabBar_changeHandler,tabBar_CREATION_COMPLETE);
         mTabBar.y = 20;
         mImg3_info = getImg3_info();
         mImg3_info.y = mTabBar.y + 55;
         mImg3_info.height = 110;
         addChild(mImg3_info);
         mImg9_info = getImg9_info();
         mImg9_info.y = mTabBar.y + 55;
         mImg9_info.width = mImg3_info.width;
         mImg9_info.height = 110;
         mImg9_info.visible = false;
         addChild(mImg9_info);
         mBtn_ran = GlobalFunction.createButtonStarling("UI_btn_rndAvatar_0_0000");
         mBtn_ran.x = mImg3_info.x + mImg3_info.width - mBtn_ran.width - 10;
         mBtn_ran.y = mImg3_info.y + 20;
         mBtn_ran.addEventListener("triggered",onTRIGGERED_ran);
         addChild(mBtn_ran);
         mImg_right = GlobalFunction.createImage("UI_tag_right_0_0000");
         mImg_right.y = int(mImg3_info.y + (mImg3_info.height - mImg_right.height) * 0.5);
         mImg_left = GlobalFunction.createImage("UI_tag_right_0_0000");
         mImg_left.y = mImg_right.y;
         mImg_left.scaleX = -1;
         mImg_left.x = mImg_left.width;
         mImg_right.x = 520;
         addChild(mImg_right);
         addChild(mImg_left);
         var _loc2_:Number = 155;
         var _loc3_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(20475),150,35);
         _loc3_.fontColor = 16777215;
         _loc3_.fontSize = 22;
         _loc3_.hAlign = "right";
         _loc3_.shadowFilter();
         _loc3_.x = 350;
         _loc3_.y = mTabBar.y + 20;
         _loc3_.touchable = false;
         addChild(_loc3_);
         GlobalData.$tempTeamPower = GlobalFunction.getTeamPower(GlobalData.$tempTeam);
         var _loc4_:LOL_TextField = new LOL_TextField(Tools.formateNum(GlobalData.$tempTeamPower),_loc2_,35);
         _loc4_.fontColor = 16763904;
         _loc4_.fontSize = 20;
         _loc4_.hAlign = "left";
         _loc4_.shadowFilter();
         _loc4_.touchable = false;
         _loc4_.x = _loc3_.x + _loc3_.width;
         _loc4_.y = _loc3_.y + 2;
         addChild(_loc4_);
         GlobalData.$mEventDispatcher.addEventListener("update_pve_combat_list",onUPDATE_PVE_COMBAT_LIST);
      }
      
      override public function tabBar_CREATION_COMPLETE(param1:*) : void
      {
         mTabBar.setChildStatus(1,GlobalFunction.checkGameFunIsOpenByType("status_pve_hard") < 0,tabBar_changeHandler_false);
         mTabBar.setChildStatus(2,GlobalFunction.checkGameFunIsOpenByType("status_pve_activities") < 0,tabBar_changeHandler_false);
         if(GlobalData.$tempPVE_type_id > 0)
         {
            mTabBar.selectedIndex = GlobalData.$tempPVE_type_id;
         }
         else
         {
            tabBar_changeHandler(null);
         }
         if(GlobalData.$maze_BattleId != "")
         {
            if(GlobalData.$maze_BattleId.indexOf("M") > -1)
            {
               mTabBar.selectedIndex = 0;
            }
            else
            {
               mTabBar.selectedIndex = 2;
            }
            tabBar_changeHandler(null);
         }
      }
      
      override public function tabBar_changeHandler(param1:Event) : void
      {
         if(mTabBar)
         {
            GlobalData.$tempPVE_type_id = this.mTabBar.selectedIndex;
            GlobalData.$tempPVE_type = GlobalFunction.getPveTypeById(GlobalData.$tempPVE_type_id);
            if(mTabBar.selectedIndex == 0 || mTabBar.selectedIndex == 1 || mTabBar.selectedIndex == 3)
            {
               mImg_left.visible = true;
               mImg_right.visible = true;
               mBtn_ran.visible = true;
               update();
            }
            else
            {
               mImg_left.visible = false;
               mImg_right.visible = false;
               mBtn_ran.visible = false;
               activeUpdate();
            }
         }
      }
      
      override public function tabBar_changeHandler_false(param1:int) : void
      {
         var _loc3_:int = 0;
         var _loc2_:String = null;
         if(mTabBar)
         {
            _loc3_ = 0;
            if(param1 == 1)
            {
               _loc3_ = GlobalFunction.checkGameFunIsOpenByType("status_pve_hard");
            }
            else if(param1 == 2)
            {
               _loc3_ = GlobalFunction.checkGameFunIsOpenByType("status_pve_activities");
            }
            if(_loc3_ > 0)
            {
               _loc2_ = GlobalData.$mConfig_simple.show_id[8];
               GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(20184,_loc3_),{"aid":_loc2_});
            }
         }
      }
      
      public function check_passAward() : void
      {
         var _loc2_:Boolean = false;
         var _loc3_:Boolean = false;
         var _loc4_:Number = 0;
         _starObj = GlobalFunction.passBattleInfo(GlobalData.$tempPVE_battleID);
         if(_starObj.isPass)
         {
            if(_starObj.getGift)
            {
               _loc2_ = false;
            }
            else
            {
               _loc2_ = true;
            }
         }
         else
         {
            _loc2_ = true;
         }
         if(GlobalData.$isForceGuide)
         {
            _loc2_ = false;
         }
         if(_awardSprite)
         {
            StarlingTools.removeChildrenClear(_awardSprite);
            _awardSprite.removeFromParent(true);
         }
         _awardSprite = null;
         if(!_loc2_)
         {
            return;
         }
         _awardSprite = new Sprite();
         this.addChild(_awardSprite);
         _imgStar = GlobalFunction.createImage("UI_icon_avatarStar_0_0000");
         _imgStar.scaleX = _imgStar.scaleY = 0.5;
         _imgStar.x = GlobalData.$mStarlingStageWidth * 0.3;
         _imgStar.y = 20;
         _awardSprite.addChild(_imgStar);
         _txtStar = GlobalTextStyle.getHtmlTextRenderer();
         this._txtStar.text = GlobalFunction.getBattleStarById(GlobalData.$tempPVE_battleID,GlobalData.$tempPVE_type);
         this._txtStar.height = 35;
         this._txtStar.x = _imgStar.x + _imgStar.width + 2;
         this._txtStar.y = _imgStar.y + 10;
         _awardSprite.addChild(_txtStar);
         // Let the HTML renderer measure the localized star string before
         // placing the adjacent button; character-count estimates clip CJK.
         this._txtStar.validate();
         _loc4_ = this._txtStar.width;
         if(_starObj.isAll && !_starObj.getGift)
         {
            _loc3_ = true;
         }
         else
         {
            _loc3_ = false;
         }
         var _loc1_:Number = 155;
         _getAward = GlobalFunction.createButton_normal(GlobalLanguageStr.getLanguageStr(!_starObj.getGift ? 90239 : 20377));
         _getAward.enabled = _loc3_;
         _getAward.x = _txtStar.x + _loc4_ + 12;
         _getAward.y = 10;
         _getAward.addEventListener("triggered",onTRIGGERED_btn);
         _awardSprite.addChild(_getAward);
      }
      
      protected function onTRIGGERED_ran(param1:Event) : void
      {
         var _loc2_:Object = null;
         var _loc4_:String = null;
         var _loc3_:int = GlobalData.$diff;
         if(GlobalFunction.hasRndAvatar(_loc3_))
         {
            _loc2_ = GlobalFunction.getRndAvatarObj(_loc3_);
            rndCid = _loc2_.cid as String;
            update();
            GuideMaster.getOnlyExample().nextGuideStep();
         }
         else
         {
            _loc4_ = (_loc3_ == 0 ? GlobalLanguageStr.getLanguageStr(20253) : GlobalLanguageStr.getLanguageStr(20254)) + GlobalLanguageStr.getLanguageStr(20028);
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90404,_loc4_));
            rndCid = null;
         }
      }
      
      protected function onTRIGGERED_btn(param1:Event) : void
      {
         var _btn:LOL_Button;
         var _event:Event = param1;
         var send_pass_battle_gift:* = function():void
         {
            var _loc1_:int = 0;
            if(GlobalData.$tempPVE_type == "status_pve_normal")
            {
               _loc1_ = 0;
            }
            else if(GlobalData.$tempPVE_type == "status_pve_hard")
            {
               _loc1_ = 1;
            }
            else
            {
               _loc1_ = -1;
            }
            SendServiceAMFFun.send_user_get_pass_battle_gift(reFun,{
               "bid":GlobalData.$tempPVE_battleID,
               "diff":_loc1_
            });
         };
         ItemBase.soundTriggered();
         _btn = _event.currentTarget as LOL_Button;
         if(_btn.enabled)
         {
            send_pass_battle_gift();
         }
         else
         {
            if(_btn.text == GlobalLanguageStr.getStr(20377))
            {
               GlobalFunction.popAlert("",GlobalLanguageStr.getStr(90244));
            }
            if(_btn.text == GlobalLanguageStr.getStr(90239))
            {
               GlobalFunction.popAlert("",GlobalLanguageStr.getStr(90245));
            }
         }
      }
      
      private function reFun(param1:Object) : void
      {
         if(this.stage == null) return;
         var _loc7_:Object = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc3_:Object = null;
         var _loc2_:String = null;
         var _loc6_:String = null;
         if(param1)
         {
            _loc7_ = param1.data;
            _loc4_ = int(_loc7_.coin);
            _loc5_ = _loc4_ - GlobalData.$userData.coin;
            _loc3_ = GlobalFunction.getAwardByType("coin",_loc5_);
            _loc2_ = _loc3_.msg;
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.coin = _loc4_;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.combat_score = _loc7_.combat_score;
            }
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
            this._getAward.text = GlobalLanguageStr.getLanguageStr(20377);
            this._getAward.enabled = false;
            _loc6_ = "sound03";
            SoundManager.getOnlyExample().playSound(_loc6_);
            GlobalFunction.popAward("coin",GlobalLanguageStr.getLanguageStr(90033,_loc2_),_loc5_,false);
         }
      }
      
      public function checkGuide() : void
      {
         var _loc1_:String = GuideTools.checkGuideType();
         if(_loc1_ == "2")
         {
            isJY = true;
            if(GlobalData.$tempPVE_type != "status_pve_hard")
            {
               LayoutUIAnimation.getOnlyExample().addArrowhead(177,154);
            }
            else if(GuideMaster.getOnlyExample().checkGuide("M2_1") == -1)
            {
               LayoutUIAnimation.getOnlyExample().clearIfNoGuide();
            }
         }
         else if(_loc1_ == "3")
         {
            isJY = false;
            LayoutUIAnimation.getOnlyExample().addArrowhead(58,890,100);
         }
         else if(_loc1_ == "4")
         {
            isJY = false;
            LayoutUIAnimation.getOnlyExample().addArrowhead(58,890,100);
         }
         else if(_loc1_ == "5")
         {
            isJY = false;
            if(GuideTools.getTeamNowNum() >= 3)
            {
               LayoutUIAnimation.getOnlyExample().addArrowhead(269,890,100);
            }
         }
         else if(_loc1_ == "6")
         {
            isJY = false;
            LayoutUIAnimation.getOnlyExample().addArrowhead(59,890,100);
         }
         else if(_loc1_ == "7")
         {
            isJY = false;
            if(GlobalData.$tempPVE_type != "status_pve_activities")
            {
               LayoutUIAnimation.getOnlyExample().addArrowhead(292,154);
            }
            else if(GuideMaster.getOnlyExample().checkGuide("M7_1") == -1)
            {
               LayoutUIAnimation.getOnlyExample().clearIfNoGuide();
            }
         }
      }
      
      override public function update() : void
      {
         checkGuide();
         setList_h();
         addList_h();
         var _loc1_:int = GlobalData.$diff;
         if(!GlobalFunction.hasRndAvatar(_loc1_))
         {
            mBtn_ran.enabled = false;
         }
         else
         {
            mBtn_ran.enabled = true;
            if(_loc1_ == 0)
            {
               if(GuideMaster.getOnlyExample().checkGuide("M11_1") == -1 && !isJY)
               {
                  LayoutUIAnimation.getOnlyExample().clearIfNoGuide();
               }
            }
         }
      }
      
      public function activeUpdate() : void
      {
         checkGuide();
         setList_Active();
         addList_h();
         var _loc1_:int = GlobalData.$diff;
         if(!GlobalFunction.hasRndAvatar(_loc1_))
         {
            mBtn_ran.enabled = false;
         }
         else
         {
            mBtn_ran.enabled = true;
         }
      }
      
      public function updateList() : void
      {
         check_passAward();
         setList();
         addList();
      }
      
      private function onUPDATE_PVE_COMBAT_LIST(param1:Event) : void
      {
         updateList();
      }
      
      public function delList_h() : void
      {
         if(mList_h)
         {
            if(mList_h.dataProvider)
            {
               mList_h.dataProvider.removeAll();
            }
            StarlingTools.removeChildrenClear(mList_h.viewPort as DisplayObjectContainer);
            mList_h.removeFromParent(true);
            mList_h.dispose();
         }
         mList_h = null;
      }
      
      public function setList_h() : void
      {
         var _loc3_:Number = NaN;
         var _loc2_:Object = null;
         var _loc1_:HorizontalLayout = null;
         delList_h();
         if(mList_h == null)
         {
            _loc3_ = 50;
            _loc2_ = {
               "paging":0,
               "gap":0,
               "horizontalGap":8,
               "verticalGap":0,
               "paddingTop":0,
               "paddingRight":0,
               "paddingBottom":0,
               "paddingLeft":0,
               "horizontalAlign":"left",
               "verticalAlign":"middle"
            };
            _loc1_ = new HorizontalLayout();
            _loc1_.gap = _loc2_.gap;
            _loc1_.paddingTop = _loc2_.paddingTop;
            _loc1_.paddingRight = _loc2_.paddingRight;
            _loc1_.paddingBottom = _loc2_.paddingBottom;
            _loc1_.paddingLeft = _loc2_.paddingLeft;
            _loc1_.horizontalAlign = _loc2_.horizontalAlign;
            _loc1_.verticalAlign = _loc2_.verticalAlign;
            _loc1_.gap = _loc2_.horizontalGap;
            _loc1_.hasVariableItemDimensions = false;
            mList_h = new List();
            mList_h.width = 490;
            mList_h.height = 90;
            mList_h.layout = _loc1_;
            mList_h.snapScrollPositionsToPixels = true;
            addChild(mList_h);
            _loc2_ = null;
            _loc1_ = null;
            mList_h.dataProvider = new ListCollection();
         }
      }
      
      public function delList_Active() : void
      {
         if(mList_h)
         {
            if(mList_h.dataProvider)
            {
               mList_h.dataProvider.removeAll();
            }
            StarlingTools.removeChildrenClear(mList_h.viewPort as DisplayObjectContainer);
            mList_h.removeFromParent(true);
            mList_h.dispose();
         }
         mList_h = null;
      }
      
      public function setList_Active() : void
      {
         var _loc3_:Number = NaN;
         var _loc2_:Object = null;
         var _loc1_:TiledRowsLayout = null;
         delList_Active();
         if(mList_h == null)
         {
            _loc3_ = 50;
            _loc2_ = {
               "paging":0,
               "gap":0,
               "horizontalGap":30,
               "verticalGap":5,
               "paddingTop":8,
               "paddingRight":0,
               "paddingBottom":0,
               "paddingLeft":0,
               "horizontalAlign":"left",
               "verticalAlign":"top"
            };
            _loc1_ = new TiledRowsLayout();
            _loc1_.useSquareTiles = false;
            _loc1_.gap = _loc2_.gap;
            _loc1_.paddingTop = _loc2_.paddingTop;
            _loc1_.paddingRight = _loc2_.paddingRight;
            _loc1_.paddingBottom = _loc2_.paddingBottom;
            _loc1_.paddingLeft = _loc2_.paddingLeft;
            _loc1_.horizontalAlign = _loc2_.horizontalAlign;
            _loc1_.verticalAlign = _loc2_.verticalAlign;
            _loc1_.horizontalGap = _loc2_.horizontalGap;
            _loc1_.verticalGap = _loc2_.verticalGap;
            mList_h = new List();
            mList_h.width = 600;
            mList_h.layout = _loc1_;
            mList_h.snapScrollPositionsToPixels = true;
            mList_h.verticalScrollPolicy = "off";
            addChild(mList_h);
            _loc2_ = null;
            _loc1_ = null;
            mList_h.dataProvider = new ListCollection();
         }
      }
      
      private function chapterIdForProgress(value:Object) : String
      {
         var raw:String = value == null ? "" : String(value);
         var parts:Array = raw.split("_");
         if(parts.length >= 3)
         {
            return String(parts[0]) + "_" + String(parts[1]);
         }
         return parts.length == 2 ? raw : "";
      }
      
      private function findUnlockedChapter(rows:Array, chapterId:String) : int
      {
         var index:int = 0;
         if(chapterId == null || chapterId.length == 0)
         {
            return -1;
         }
         while(index < rows.length)
         {
            if(rows[index] != null && rows[index]["id"] == chapterId)
            {
               return index;
            }
            index++;
         }
         return -1;
      }
      
      public function addList_h() : void
      {
         var _loc12_:String = null;
         var _loc18_:Object = null;
         var _loc9_:Object = null;
         var _loc6_:int = 0;
         var _loc16_:Boolean = false;
         var _loc1_:Object = null;
         var _loc5_:Object = null;
         var _loc19_:Boolean = false;
         var _loc10_:int = 0;
         var _loc14_:int = 0;
         GlobalData.$setPVE();
         mList_h.x = mImg3_info.x + 25;
         mList_h.y = mImg3_info.y + 10;
         var _loc15_:Object = GlobalFunction.getPveBattleCfg(GlobalData.$tempPVE_type);
         var _loc2_:Array = [];
         var _loc8_:int = 0;
         var _loc3_:Boolean = false;
         var _loc7_:int = -1;
         var _loc13_:Boolean = false;
         var _loc11_:int = -1;
         var _loc17_:int = 0;
         if(GlobalData.$tempPVE_type == "status_pve_normal")
         {
            _loc3_ = true;
            _loc6_ = 0;
            for(_loc9_ in _loc15_)
            {
               _loc12_ = _loc9_.toString();
               _loc8_ = GlobalFunction.check_pass_battle_main(_loc12_);
               if(_loc8_ > 0)
               {
                  _loc18_ = _loc15_[_loc12_];
                  _loc18_["id"] = _loc12_;
                  _loc18_["diff"] = _loc6_;
                  _loc18_["status"] = _loc8_;
                  _loc18_["choice"] = 0;
                  _loc18_["tab_index"] = "status_pve_normal";
                  _loc18_["status_activity"] = _loc18_["status_activity"] != null ? _loc18_["status_activity"] : 0;
                  _loc2_.push(_loc18_);
               }
            }
            if(_loc2_.length > 0)
            {
               _loc2_.sortOn(["indexID_s","id"],[0x10 | 2,0]);
               if(rndCid)
               {
                  _loc7_ = 0;
                  while(_loc7_ < _loc2_.length)
                  {
                     _loc12_ = _loc2_[_loc7_]["id"];
                     if(rndCid.indexOf(_loc12_) >= 0)
                     {
                        break;
                     }
                     _loc7_++;
                  }
               }
               if(_loc7_ < 0 || _loc7_ >= _loc2_.length)
               {
                  var wasFirstWin:Boolean = GlobalData.$tempPVE_battleID_isFirstWin;
                  if(wasFirstWin)
                  {
                     GlobalData.$tempPVE_battleID_isFirstWin = false;
                  }
                  var preferredChapter:String = "";
                  if(!wasFirstWin)
                  {
                     preferredChapter = this.chapterIdForProgress(GlobalData.$tempPVE_battleID_normal);
                     _loc7_ = this.findUnlockedChapter(_loc2_,preferredChapter);
                  }
                  if(_loc7_ < 0)
                  {
                     preferredChapter = this.chapterIdForProgress(GlobalData.$userData.cid);
                     _loc7_ = this.findUnlockedChapter(_loc2_,preferredChapter);
                  }
                  if(_loc7_ < 0)
                  {
                     // Rows are sorted by chapter index descending. If neither
                     // a replay pointer nor the saved progress maps to an
                     // unlocked row, keep the newest unlocked chapter instead
                     // of falling back to the last (oldest) row.
                     _loc7_ = 0;
                  }
               }
               _loc7_ = Math.min(_loc7_,_loc2_.length - 1);
               _loc2_[_loc7_]["choice"] = 1;
               this.setListHData(mList_h,_loc2_,ItemPVEmain,false,_loc7_);
               // ListCollection.data dispatches reset, which clears List's
               // selectedIndices. Select only after installing the provider.
               mList_h.selectedIndex = _loc7_;
               mList_h.scrollToDisplayIndex(_loc7_);
            }
         }
         else if(GlobalData.$tempPVE_type == "status_pve_hard")
         {
            _loc3_ = true;
            _loc6_ = 1;
            for(_loc9_ in _loc15_)
            {
               _loc12_ = _loc9_.toString();
               _loc8_ = GlobalFunction.check_pass_battle_main(_loc12_,1);
               if(_loc8_ > 0)
               {
                  _loc18_ = _loc15_[_loc12_];
                  _loc18_["id"] = _loc12_;
                  _loc18_["diff"] = _loc6_;
                  _loc18_["status"] = _loc8_;
                  _loc18_["choice"] = 0;
                  _loc18_["tab_index"] = "status_pve_hard";
                  _loc18_["status_activity"] = _loc18_["status_activity"] != null ? _loc18_["status_activity"] : 0;
                  _loc2_.push(_loc18_);
               }
            }
            if(_loc2_.length > 0)
            {
               _loc2_.sortOn(["indexID_s","id"],[0x10 | 2,0]);
               if(rndCid)
               {
                  _loc7_ = 0;
                  while(_loc7_ < _loc2_.length)
                  {
                     _loc12_ = _loc2_[_loc7_]["id"];
                     if(rndCid.indexOf(_loc12_) >= 0)
                     {
                        break;
                     }
                     _loc7_++;
                  }
               }
               if(_loc7_ < 0 || _loc7_ >= _loc2_.length)
               {
                  var wasHardFirstWin:Boolean = GlobalData.$tempPVE_battleID_isFirstWin;
                  if(wasHardFirstWin)
                  {
                     GlobalData.$tempPVE_battleID_isFirstWin = false;
                  }
                  var preferredHardChapter:String = "";
                  if(!wasHardFirstWin)
                  {
                     preferredHardChapter = this.chapterIdForProgress(GlobalData.$tempPVE_battleID_hard);
                     _loc7_ = this.findUnlockedChapter(_loc2_,preferredHardChapter);
                  }
                  if(_loc7_ < 0)
                  {
                     preferredHardChapter = this.chapterIdForProgress(GlobalData.$userData.hid);
                     _loc7_ = this.findUnlockedChapter(_loc2_,preferredHardChapter);
                  }
                  if(_loc7_ < 0)
                  {
                     // Rows are sorted by chapter index descending; index 0
                     // is the newest unlocked chapter.
                     _loc7_ = 0;
                  }
               }
               _loc2_[_loc7_]["choice"] = 1;
               this.setListHData(mList_h,_loc2_,ItemPVEmain,false,_loc7_);
               // The provider reset clears selectedIndices, so apply the
               // selection after replacing its data.
               mList_h.selectedIndex = _loc7_;
               mList_h.scrollToDisplayIndex(_loc7_);
            }
         }
         else if(GlobalData.$tempPVE_type == "status_pve_activities")
         {
            for(_loc9_ in _loc15_)
            {
               _loc12_ = _loc9_.toString();
               _loc18_ = _loc15_[_loc12_];
               if(_loc18_.ulv <= GlobalData.$userData.lv + 3)
               {
                  _loc5_ = GlobalData.$mConfig_battle_ploy[_loc12_];
                  _loc1_ = GlobalFunction.check_battle_ploy(_loc12_);
                  if((_loc1_.startS <= _loc1_.rulerS || _loc1_.endS > 0) && (_loc1_.now >= _loc1_.s - _loc1_.rulerS && _loc1_.now < _loc1_.e))
                  {
                     _loc18_["id"] = _loc12_;
                     _loc18_["status"] = 0;
                     _loc18_["indexID_s"] = 0;
                     _loc18_["diff"] = 0;
                     _loc18_["choice"] = 0;
                     _loc18_["state"] = _loc5_["state"] != null ? _loc5_.state : 0;
                     _loc18_["tab_index"] = "status_pve_activities";
                     _loc18_["status_activity"] = _loc18_["status_activity"] != null ? _loc18_["status_activity"] : 0;
                     if(_loc1_.endS > 0 && _loc1_.now >= _loc1_.s && _loc1_.now < _loc1_.e)
                     {
                        _loc18_["indexID_s"] = 1;
                     }
                     _loc2_.push(_loc18_);
                  }
               }
            }
            if(_loc2_.length > 0)
            {
               _loc2_.sortOn(["indexID_s","index"],[0x10 | 2,16]);
               _loc19_ = !Tools.strIsNull(GlobalData.$tempPVE_battleID_ACTIVITIES);
               _loc7_ = 0;
               while(_loc7_ < _loc2_.length)
               {
                  _loc18_ = _loc2_[_loc7_];
                  if(_loc18_["indexID_s"] == 1)
                  {
                     if(!_loc19_)
                     {
                        _loc7_ = int(_loc7_ < 0 ? 0 : _loc7_);
                        break;
                     }
                     if(GlobalData.$tempPVE_battleID_ACTIVITIES == _loc18_["id"])
                     {
                        _loc7_ = int(_loc7_ < 0 ? 0 : _loc7_);
                        break;
                     }
                  }
                  _loc7_++;
               }
               _loc7_ = int(_loc7_ < 0 || _loc7_ >= _loc2_.length ? 0 : _loc7_);
               _loc2_[_loc7_]["choice"] = 1;
               this.setListHData(mList_h,_loc2_,ItemPVEmain,false);
            }
         }
         else if(GlobalData.$tempPVE_type == "status_pve_guild")
         {
            _loc3_ = true;
            _loc6_ = 0;
            for(_loc9_ in _loc15_)
            {
               _loc12_ = _loc9_.toString();
               _loc8_ = GlobalFunction.check_pass_battle_main(_loc12_);
               if(_loc8_ > 0)
               {
                  _loc18_ = _loc15_[_loc12_];
                  _loc18_["id"] = _loc12_;
                  _loc18_["diff"] = _loc6_;
                  _loc18_["status"] = _loc8_;
                  _loc18_["choice"] = 0;
                  _loc18_["tab_index"] = "status_pve_normal";
                  _loc18_["status_activity"] = _loc18_["status_activity"] != null ? _loc18_["status_activity"] : 0;
                  _loc2_.push(_loc18_);
               }
            }
            if(_loc2_.length > 0)
            {
               _loc2_.sortOn(["indexID_s","id"],[0x10 | 2,0]);
               if(rndCid)
               {
                  _loc7_ = 0;
                  while(_loc7_ < _loc2_.length)
                  {
                     _loc12_ = _loc2_[_loc7_]["id"];
                     if(rndCid.indexOf(_loc12_) >= 0)
                     {
                        break;
                     }
                     _loc7_++;
                  }
               }
               if(_loc7_ < 0 || _loc7_ >= _loc2_.length)
               {
                  if(Tools.strIsNull(GlobalData.$tempPVE_battleID_normal))
                  {
                     _loc16_ = false;
                  }
                  else
                  {
                     _loc16_ = GlobalFunction.check_pass_battle_main(GlobalData.$tempPVE_battleID_normal,0) == 1;
                  }
                  if(GlobalData.$tempPVE_battleID_isFirstWin)
                  {
                     GlobalData.$tempPVE_battleID_isFirstWin = false;
                     _loc16_ = false;
                  }
                  _loc7_ = 0;
                  while(_loc7_ < _loc2_.length)
                  {
                     _loc18_ = _loc2_[_loc7_];
                     if(_loc16_)
                     {
                        if(_loc18_["id"] == GlobalData.$tempPVE_battleID_normal)
                        {
                           _loc7_ = int(_loc7_ < 0 ? 0 : _loc7_);
                           break;
                        }
                     }
                     else if(GlobalData.$userData.lv < _loc18_.ulv)
                     {
                        _loc7_ -= 1;
                        _loc7_ = int(_loc7_ < 0 ? 0 : _loc7_);
                        _loc13_ = true;
                        break;
                     }
                     _loc7_++;
                  }
                  if(!_loc16_)
                  {
                     if(!_loc13_)
                     {
                        _loc7_ = _loc2_.length - 1;
                     }
                  }
               }
               _loc7_ = Math.min(_loc7_,_loc2_.length - 1);
               _loc2_[_loc7_]["choice"] = 1;
               mList_h.selectedIndex = _loc7_;
               mList_h.scrollToDisplayIndex(_loc7_);
               this.setListHData(mList_h,_loc2_,ItemPVEmain,false,_loc7_);
            }
         }
         if(GlobalData.$tempPVE_type == "status_pve_normal")
         {
            GlobalData.$tempPVE_battleID_normal = GlobalData.$tempPVE_battleID = _loc2_[_loc7_].id;
         }
         else if(GlobalData.$tempPVE_type == "status_pve_hard")
         {
            GlobalData.$tempPVE_battleID_hard = GlobalData.$tempPVE_battleID = _loc2_[_loc7_].id;
         }
         else if(GlobalData.$tempPVE_type == "status_pve_activities")
         {
            GlobalData.$tempPVE_battleID_ACTIVITIES = GlobalData.$tempPVE_battleID = _loc2_[_loc7_].id;
         }
         else if(GlobalData.$tempPVE_type == "status_pve_guild")
         {
            GlobalData.$tempPVE_battleID_GUILD = GlobalData.$tempPVE_battleID = _loc2_[_loc7_].id;
         }
         if(mTabBar.selectedIndex == 3 || mTabBar.selectedIndex == 2)
         {
            mBtn_ran.visible = false;
            if(mTabBar.selectedIndex == 3)
            {
               mList_h.width = 600;
               mImg_right.x = GlobalData.$mStageWidth - mImg_right.width;
            }
         }
         else
         {
            mBtn_ran.visible = true;
            mList_h.width = 490;
            mImg_right.x = 520;
         }
         if(mTabBar.selectedIndex == 2)
         {
            mImg3_info.visible = false;
            mImg9_info.visible = true;
            _loc10_ = 0;
            if(_loc2_.length % 3 > 0)
            {
               _loc10_ += 1;
            }
            mImg9_info.height = (int(_loc2_.length / 3) + _loc10_) * 80 + (int(_loc2_.length / 3) + _loc10_ - 1) * 5 + 20;
            mList_h.height = mImg9_info.height;
         }
         else
         {
            mImg3_info.visible = true;
            mImg9_info.visible = false;
         }
         var _loc4_:int = checkBattle(_loc2_);
         if(_loc4_ != -1)
         {
            _loc14_ = 0;
            while(_loc14_ < _loc2_.length)
            {
               _loc2_[_loc14_]["choice"] = 0;
               _loc14_++;
            }
            _loc2_[_loc4_]["choice"] = 1;
            mList_h.selectedIndex = _loc4_;
            mList_h.scrollToDisplayIndex(_loc4_);
            GlobalData.$maze_BattleId = "";
            if(GlobalData.$tempPVE_type == "status_pve_normal")
            {
               GlobalData.$tempPVE_battleID_normal = GlobalData.$tempPVE_battleID = _loc2_[_loc4_].id;
            }
            else if(GlobalData.$tempPVE_type == "status_pve_hard")
            {
               GlobalData.$tempPVE_battleID_hard = GlobalData.$tempPVE_battleID = _loc2_[_loc4_].id;
            }
            else if(GlobalData.$tempPVE_type == "status_pve_activities")
            {
               GlobalData.$tempPVE_battleID_ACTIVITIES = GlobalData.$tempPVE_battleID = _loc2_[_loc4_].id;
            }
            else if(GlobalData.$tempPVE_type == "status_pve_guild")
            {
               GlobalData.$tempPVE_battleID_GUILD = GlobalData.$tempPVE_battleID = _loc2_[_loc4_].id;
            }
         }
         _loc15_ = null;
         _loc2_ = null;
         _loc18_ = null;
         updateList();
      }
      
      public function checkBattle(param1:Array) : int
      {
         var _loc2_:int = 0;
         if(GlobalData.$maze_BattleId != "")
         {
            _loc2_ = 0;
            while(_loc2_ < param1.length)
            {
               if(param1[_loc2_].id == GlobalData.$maze_BattleId)
               {
                  return _loc2_;
               }
               _loc2_++;
            }
         }
         return -1;
      }
      
      public function checkCombat(param1:Array) : int
      {
         var _loc2_:int = 0;
         if(GlobalData.$maze_CombatId != "")
         {
            _loc2_ = 0;
            while(_loc2_ < param1.length)
            {
               if(param1[_loc2_].id == GlobalData.$maze_CombatId)
               {
                  return _loc2_;
               }
               _loc2_++;
            }
         }
         return -1;
      }
      
      override public function setList() : void
      {
         var _rulerH:Number;
         var settings:Object;
         var _layout:VerticalLayout;
         var tweenComplete:* = function():void
         {
            isReady = true;
         };
         isReady = false;
         isOut = true;
         GlobalData.$mStarling.juggler.tween(this,0.4,{"onComplete":tweenComplete});
         this.delList();
         if(this.mList == null)
         {
            _rulerH = 110;
            settings = {
               "paging":0,
               "gap":5,
               "horizontalGap":20,
               "verticalGap":20,
               "paddingTop":0,
               "paddingRight":0,
               "paddingBottom":35,
               "paddingLeft":0,
               "horizontalAlign":"center",
               "verticalAlign":"top"
            };
            _layout = new VerticalLayout();
            _layout.paddingTop = settings.paddingTop;
            _layout.paddingRight = settings.paddingRight;
            _layout.paddingBottom = settings.paddingBottom;
            _layout.paddingLeft = settings.paddingLeft;
            _layout.horizontalAlign = settings.horizontalAlign;
            _layout.verticalAlign = settings.verticalAlign;
            _layout.gap = settings.gap;
            _layout.hasVariableItemDimensions = true;
            this.mList = new List();
            this.mList.isSelectable = false;
            this.mList.width = GlobalData.$mStageWidth - 20;
            this.mList.height = mListH = GlobalData.$center_height - 230;
            this.mList.layout = _layout;
            this.mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
            this.mList.x = int((GlobalData.$mStageWidth - this.mList.width) * 0.5);
            this.mList.y = mListY = _rulerH;
            this.mList.snapScrollPositionsToPixels = true;
            this.addChild(this.mList);
            settings = null;
            _layout = null;
            this.mList.dataProvider = new ListCollection();
         }
      }
      
      override public function addList() : void
      {
         var _loc17_:Number = NaN;
         var _loc16_:Object = null;
         var _loc15_:String = null;
         var _loc8_:Object = null;
         var _loc11_:int = 0;
         if(!_awardSprite)
         {
            _loc17_ = 230;
            if(mTabBar.selectedIndex == 2)
            {
               _loc17_ = mImg9_info.y + mImg9_info.height + 45;
            }
         }
         else if(mTabBar.selectedIndex == 2)
         {
            _awardSprite.y = mImg9_info.y + mImg9_info.height;
            _loc17_ = mImg9_info.y + mImg9_info.height + 35 + _awardSprite.height;
         }
         else
         {
            _awardSprite.y = mImg3_info.y + mImg3_info.height;
            _loc17_ = 290;
         }
         setListHeight(_loc17_ - 50);
         mList.y = mListY = _loc17_;
         var _loc12_:Object = GlobalFunction.getPveCombatCfg(GlobalData.$tempPVE_type);
         var _loc9_:Object = GlobalFunction.getPveBattleCfg(GlobalData.$tempPVE_type);
         var _loc1_:String = GlobalData.$tempPVE_battleID;
         var _loc2_:Array = [];
         var _loc10_:String = "";
         var _loc6_:int = 0;
         var _loc13_:String = GlobalData.$tempPVE_battleID;
         // Selection callbacks store a full stage id here; list filtering must
         // use its chapter key so refreshes do not hide sibling stages.
         var _loc20_:int = _loc13_.indexOf("_");
         var _loc21_:int = _loc13_.lastIndexOf("_");
         if(_loc20_ > 0 && _loc21_ > _loc20_)
         {
            _loc13_ = _loc13_.substring(0,_loc21_);
         }
         var _loc4_:int = 0;
         var _loc5_:int = GlobalData.$diff;
         var _loc14_:Boolean = false;
         for(var _loc7_:Object in _loc12_)
         {
            _loc10_ = _loc7_.toString();
            if(_loc10_ != "M_000_0")
            {
               if(_loc10_.indexOf(_loc13_) > -1)
               {
                  _loc4_ = int(_loc10_.split("_")[2]);
                  _loc16_ = _loc12_[_loc10_];
                  _loc16_["id"] = _loc10_;
                  _loc16_["status"] = 0;
                  _loc16_["indexID_s"] = _loc4_;
                  if(_loc12_[_loc10_].needvip)
                  {
                     _loc16_.needvip = _loc12_[_loc10_].needvip;
                  }
                  _loc16_["diff"] = _loc5_;
                  _loc15_ = _loc10_.substring(0,_loc10_.lastIndexOf("_"));
                  _loc16_["status_activity"] = _loc9_[_loc15_]["status_activity"] != null ? _loc9_[_loc15_]["status_activity"] : 0;
                  if(GlobalData.$tempPVE_type == "status_pve_normal" || GlobalData.$tempPVE_type == "status_pve_hard")
                  {
                     _loc6_ = GlobalFunction.check_pass_combat_main(_loc10_,_loc5_);
                     if(_loc6_ > 0)
                     {
                        _loc2_.push(_loc16_);
                     }
                  }
                  else
                  {
                     _loc2_.push(_loc16_);
                  }
               }
            }
         }
         if(_loc2_.length > 0)
         {
            _loc2_.sortOn("indexID_s",16);
            mList.y = mListY - 20;
            _loc4_ = -1;
            if(!rndCid)
            {
               if(GlobalFunction.hasRndAvatar(_loc5_))
               {
                  _loc8_ = GlobalFunction.getRndAvatarObj(_loc5_);
                  rndCid = _loc8_.cid as String;
               }
            }
            if(rndCid)
            {
               _loc4_ = 0;
               while(_loc4_ < _loc2_.length)
               {
                  _loc10_ = _loc2_[_loc4_]["id"];
                  if(rndCid == _loc10_)
                  {
                     break;
                  }
                  _loc4_++;
               }
            }
            if(_loc4_ < 0 || _loc4_ >= _loc2_.length)
            {
               if(GlobalData.$tempPVE_type == "status_pve_normal")
               {
                  _loc14_ = GlobalFunction.check_pass_battle_main(GlobalData.$tempPVE_battleID_normal,0) == 1;
               }
               else if(GlobalData.$tempPVE_type == "status_pve_hard")
               {
                  _loc14_ = GlobalFunction.check_pass_battle_main(GlobalData.$tempPVE_battleID_hard,1) == 1;
               }
               else
               {
                  _loc4_ = 0;
               }
               if(Tools.strIsNull(GlobalData.$tempPVE_combatID))
               {
                  _loc14_ = false;
               }
               if(_loc14_)
               {
                  _loc4_ = 0;
                  while(_loc4_ < _loc2_.length)
                  {
                     _loc16_ = _loc2_[_loc4_];
                     if(_loc16_["id"] == GlobalData.$tempPVE_combatID)
                     {
                        break;
                     }
                     _loc4_++;
                  }
               }
               else if(GlobalData.$tempPVE_type == "status_pve_activities")
               {
                  _loc4_ = 0;
               }
               else
               {
                  _loc4_ = _loc2_.length - 1;
               }
            }
            else
            {
               mList.scrollToDisplayIndex(_loc4_,0.5);
            }
            _loc4_ = int(_loc4_ < 0 ? 0 : _loc4_);
            if(_loc4_ >= _loc2_.length)
            {
               _loc4_ = _loc2_.length - 1;
            }
            if(GlobalData.$tempPVE_type != "status_pve_activities")
            {
               _loc2_[_loc4_]["status"] = 1;
            }
            mList.selectedIndex = _loc4_;
            mList.scrollToDisplayIndex(_loc4_);
            if(GlobalData.$tempPVE_type != "status_pve_guild")
            {
               this.setListTimer(mList,_loc2_,ItemPVEcombat,false,_loc4_);
            }
            else
            {
               this.setListTimer(mList,_loc2_,ItemGuildFight,false,_loc4_);
            }
            rndCid = null;
            GlobalData.$tempPVE_combatID = "";
         }
         var _loc3_:int = checkCombat(_loc2_);
         if(_loc3_ != -1)
         {
            _loc11_ = 0;
            while(_loc11_ < _loc2_.length)
            {
               _loc2_[_loc11_]["status"] = 0;
               _loc11_++;
            }
            _loc2_[_loc3_]["status"] = 1;
            mList.selectedIndex = _loc3_;
            mList.scrollToDisplayIndex(_loc3_);
            GlobalData.$maze_CombatId = "";
         }
         _loc12_ = null;
         _loc2_ = null;
         _loc16_ = null;
      }
   }
}

