package com.meng52.game.ui.screen
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.ui.element.ItemAvatarBetter;
   import com.meng52.game.ui.element.ItemAvatarFoster;
   import com.meng52.game.ui.element.ItemAvatarSell;
   import com.meng52.game.ui.element.ItemAvatarStarUp;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelAvatarSell;
   import com.meng52.game.ui.stage.GuideTools;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.RpcStaticCall;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.net.SendAndSelect;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.data.ListCollection;
   import feathers.layout.TiledRowsLayout;
   import flash.geom.Rectangle;
   import flash.utils.getQualifiedClassName;
   import starling.events.Event;
   
   public class PanelSocialMainAvatar extends PanelCenterPVE
   {
      
      public static var $tabBarSelectedIndex:int = 0;
      
      public static var BTN_NAME_CLEAR:String = "btn_name_clear";
      
      public static var BTN_NAME_SELL:String = "btn_name_sell";
      
      private static var _radioBarObj:Object = {
         0:0,
         1:0,
         2:0,
         3:0,
         4:0
      };
      
      public var mBtn_clear:LOL_Scale9Button;
      
      public var mBtn_sell:LOL_Scale9Button;
      
      public var mTxt_info:TextFieldHtmlRenderer;
      
      private var mGold_all:Number = 0;
      
      public var tempSelect:int = 0;
      
      public var firstSelect:int = 0;
      
      private var _itemArr:Array = [];
      
      private var _boo:Boolean = false;
      
      private var isHero:int = 0;
      
      private var _radioSelectIndex:int = -1;

      private var mRarityBtns:Array = [];

      private var mRarityDiagEvent:String = "social-sell-open";

      private var mRarityRowHeight:Number = 40;

      private var mSellViewEpoch:uint = 0;

      private var mSellOperation:uint = 0;

      private var mHandledSellOperation:uint = 0;

      
      public function PanelSocialMainAvatar()
      {
         super();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         mSellViewEpoch++;
         GlobalData.$mEventDispatcher.removeEventListener("update_avatar_sell",onMainEvent);
         GlobalData.$mEventDispatcher.removeEventListener("update_avatar_better",onMainEvent);
         GlobalData.$mEventDispatcher.removeEventListener("update_avatar_starup",onMainEvent);
         GlobalData.$mEventDispatcher.removeEventListener("update_avatar_sell_data",onUPDATE_AVATAR_DATA);
         removeRarityFilters();
         super.onREMOVED_FROM_STAGE(param1);
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         GlobalData.$mEventDispatcher.addEventListener("update_avatar_sell",onMainEvent);
         GlobalData.$mEventDispatcher.addEventListener("update_avatar_better",onMainEvent);
         GlobalData.$mEventDispatcher.addEventListener("update_avatar_starup",onMainEvent);
         GlobalData.$mEventDispatcher.addEventListener("update_avatar_sell_data",onUPDATE_AVATAR_DATA);
         GlobalData.$mEventDispatcher.addEventListener("change_team_member_lock",CHANGE_TEAM_MEMBER_LOCK);
         this.removeEventListener("addedToStage",initializeHandler);
         mImg_head = getImg_headBg(-50);
         addChild(mImg_head);
         this.setTabBar([{
            "label":GlobalLanguageStr.getLanguageStr(70003),
            "indexID":0
         },{
            "label":GlobalLanguageStr.getLanguageStr(20085),
            "indexID":1
         },{
            "label":GlobalLanguageStr.getLanguageStr(20092),
            "indexID":2
         },{
            "label":GlobalLanguageStr.getLanguageStr(90553),
            "indexID":3
         },{
            "label":GlobalLanguageStr.getLanguageStr(20072),
            "indexID":4
         }],tabBar_changeHandler,tabBar_CREATION_COMPLETE);
         mTabBar.y = 17;
         mImg3_info = getImg3_info();
         mImg3_info.y = mTabBar.y + 55;
         mImg3_info.height = 80;
         addChild(mImg3_info);
      }
      
      private function CHANGE_TEAM_MEMBER_LOCK(param1:Event) : void
      {
      }
      
      private function onMainEvent(param1:Event) : void
      {
         update();
      }

      private function ensureRarityFilters(param1:Number) : void
      {
         if(mRarityBtns.length > 0)
         {
            return;
         }
         PanelAvatarSell.$rarityFilter = {"2":true,"3":true,"4":true,"5":true,"6":true};
         var _labels:Array = ["白","绿","蓝","紫","橙"];
         var _stars:Array = ["2","3","4","5","6"];
         var _button:LOL_Scale9Button = null;
         var _i:int = 0;
         var _x:Number = (GlobalData.$mStageWidth - 5 * 56 + 10) * 0.5;
         while(_i < _stars.length)
         {
            _button = new LOL_Scale9Button((_labels[_i] as String) + "开",56,34,"UI_btn_enterGame_0_0000");
            _button.name = "social_rarity_" + _stars[_i];
            _button.x = _x + _i * 58;
            _button.y = param1;
            _button.addEventListener("triggered",onSocialRarityFilter);
            addChild(_button);
            mRarityBtns.push(_button);
            _i++;
         }
      }

      private function onSocialRarityFilter(param1:Event) : void
      {
         var _button:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         var _star:String = _button.name.substr(14);
         PanelAvatarSell.$rarityFilter[_star] = PanelAvatarSell.$rarityFilter[_star] !== true;
         _button.text = ({"2":"白","3":"绿","4":"蓝","5":"紫","6":"橙"}[_star]) + (PanelAvatarSell.$rarityFilter[_star] === true ? "开" : "关");
         mRarityDiagEvent = "social-sell-filter-" + _star;
         update();
      }

      private function layoutRarityFilters(param1:Number) : void
      {
         var _button:LOL_Scale9Button = null;
         for each(_button in mRarityBtns)
         {
            if(_button)
            {
               _button.y = param1;
            }
         }
      }

      private function bringRarityFiltersToFront() : void
      {
         var _button:LOL_Scale9Button = null;
         for each(_button in mRarityBtns)
         {
            if(_button && _button.parent == this)
            {
               setChildIndex(_button,numChildren - 1);
            }
         }
      }

      private function removeRarityFilters() : void
      {
         var _button:LOL_Scale9Button = null;
         for each(_button in mRarityBtns)
         {
            if(_button)
            {
               _button.removeEventListener("triggered",onSocialRarityFilter);
               _button.removeFromParent(true);
               _button.dispose();
            }
         }
         mRarityBtns = [];
      }

      private function reportRarityDiagnostic(param1:String,param2:int) : void
      {
         var _button:LOL_Scale9Button = null;
         var _buttons:Array = [];
         var _children:Array = [];
         var _i:int = 0;
         for each(_button in mRarityBtns)
         {
            if(_button)
            {
               _buttons.push(String(_button.text) + "@" + int(_button.x) + "," + int(_button.y) + "," + int(_button.width) + "x" + int(_button.height) + "#" + (_button.parent == this ? getChildIndex(_button) : -1) + ":" + String(_button.visible));
            }
         }
         while(_i < numChildren && _i < 28)
         {
            _children.push(String(getChildAt(_i).name) + ":" + getQualifiedClassName(getChildAt(_i)));
            _i++;
         }
         if(RpcStaticCall.$remoting != null)
         {
            RpcStaticCall.$remoting.reportDiagnostic("SOCIAL_SELL_UI event=" + param1 + " selected=" + param2 + " clear=" + (mBtn_clear ? String(mBtn_clear.text) : "null") + " filters=" + String(PanelAvatarSell.$rarityFilter) + " filter_buttons=" + _buttons.join("|") + " list=" + (mList ? int(mList.x) + "," + int(mList.y) + "," + int(mList.width) + "x" + int(mList.height) + "#" + getChildIndex(mList) : "null") + " children=" + _children.join("|"));
         }
      }
      
      private function RadioBar_CREATION_COMPLETE(param1:*) : void
      {
         if($tabBarSelectedIndex > 0)
         {
            mTabBar.selectedIndex = $tabBarSelectedIndex;
         }
         else
         {
            tabBar_changeHandler(null);
         }
      }
      
      override public function tabBar_CREATION_COMPLETE(param1:*) : void
      {
         var _loc2_:Array = [{"label":GlobalLanguageStr.getLanguageStr(20236)},{"label":GlobalLanguageStr.getLanguageStr(20165)},{"label":GlobalLanguageStr.getLanguageStr(20255)}];
         if(MainConfig.$isHasBuilding)
         {
            _loc2_.push({"label":GlobalLanguageStr.getLanguageStr(20256)});
         }
         _loc2_.push({"label":GlobalLanguageStr.getLanguageStr(20257)});
         this.setRadioBar(_loc2_,RadioBar_changeHandler,RadioBar_CREATION_COMPLETE);
         mRadioBar.x = 25;
         mRadioBar.pivotY = mRadioBar.height / 2;
         mRadioBar.y = mImg3_info.y + 10;
         var _loc3_:Boolean = false;
         if(GlobalData.$mConfig_simple.culture != null)
         {
            _loc3_ = GlobalData.$userData.lv >= GlobalData.$mConfig_simple.culture.culture_lv ? true : false;
         }
         this.mTabBar.setChildStatus(3,_loc3_,tabBar_changeHandler_false);
      }
      
      override public function tabBar_changeHandler_false(param1:int) : void
      {
         var _loc3_:int = 0;
         var _loc2_:String = null;
         if(mTabBar)
         {
            _loc3_ = 0;
            if(param1 == 3)
            {
               _loc3_ = GlobalFunction.checkGameFunIsOpenByType("center_avatar_foster");
               _loc2_ = GlobalData.$mConfig_simple.show_id[8];
               if(_loc3_ > 0)
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90129,_loc3_),false,_loc2_);
               }
            }
         }
      }
      
      private function RadioBar_changeHandler(param1:Event) : void
      {
         _radioBarObj[mTabBar.selectedIndex] = mRadioBar.selectedIndex;
         if(mRadioBar)
         {
            if(this.mList)
            {
               this.mList.stopScrolling();
            }
            update();
         }
      }
      
      private function checkGuide() : void
      {
         var _loc1_:String = GuideTools.checkGuideType();
         if(_loc1_ == "9")
         {
            if(GlobalData.$userData.lv >= 30)
            {
               LayoutUIAnimation.getOnlyExample().addArrowhead(410,160,40);
            }
         }
      }
      
      override public function update() : void
      {
         var _loc2_:* = undefined;
         var _loc1_:Avatar = null;
         setList();
         addList();
         LayoutUIAnimation.getOnlyExample().clearIfNoGuide();
         if(this.mTabBar.selectedIndex == 4)
         {
            delPageNum();
            this.formatTxtInfo();
            this.reportRarityDiagnostic(mRarityDiagEvent,GlobalData.$tempSell == null ? 0 : GlobalData.$tempSell.length);
            mRarityDiagEvent = "social-sell-update";
         }
         else if(this.mTabBar.selectedIndex == 1)
         {
            if(GlobalData.$userData.lv < GlobalData.$mConfig_simple.start_lv[6])
            {
               if(mList)
               {
                  if(mList.dataProvider)
                  {
                     if(mList.dataProvider.data is Array)
                     {
                        _loc2_ = (mList.dataProvider.data as Array)[0];
                        if(_loc2_)
                        {
                           _loc1_ = new Avatar(_loc2_.id,_loc2_);
                           if(_loc1_.getType() == 1 && _loc1_.lv < _loc1_.getLvMax())
                           {
                              if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
                              {
                                 LayoutUIAnimation.getOnlyExample().addArrowhead(90,337);
                              }
                           }
                        }
                     }
                  }
               }
            }
            clearPriv();
         }
         else
         {
            clearPriv();
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
            _loc3_ = 167;
            _loc2_ = {
               "paging":0,
               "gap":0,
               "horizontalGap":20,
               "verticalGap":20,
               "paddingTop":10,
               "paddingRight":0,
               "paddingBottom":20,
               "paddingLeft":0,
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
            this.mList.height = GlobalData.$center_height - 203;
            this.mList.layout = _loc1_;
            this.mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
            this.mList.x = int((GlobalData.$mStageWidth - this.mList.width) * 0.5);
            this.mList.y = _loc3_;
            this.mList.snapScrollPositionsToPixels = true;
            this.addChild(this.mList);
            _loc2_ = null;
            _loc1_ = null;
            this.mList.dataProvider = new ListCollection();
         }
      }
      
      override public function addList() : void
      {
         var _loc10_:Array = null;
         var _loc13_:Object = null;
         var _loc14_:Object = null;
         var _loc1_:Avatar = null;
         var _loc15_:String = null;
         var _loc9_:int = 0;
         var _loc12_:Object = null;
         var _loc3_:Object = null;
         var _loc2_:Avatar = null;
         var _loc5_:String = null;
         var _loc6_:Boolean = false;
         var _loc4_:Boolean = false;
         var _loc7_:int = 0;
         var _loc11_:int = 0;
         if(mTabBar.selectedIndex == 0)
         {
            GlobalFunction.clearAvatarBetterItems();
            _loc10_ = [];
            _loc14_ = GlobalData.$userData.avatars;
            _loc15_ = "";
            for(var _loc16_:Object in _loc14_)
            {
               _loc15_ = _loc16_.toString();
               if(MainConfig.$isHasBuilding)
               {
                  _loc9_ = int(_radioBarObj[0]);
               }
               else if(mRadioBar.selectedIndex == 3)
               {
                  _loc9_ = _radioBarObj[0] + 1;
               }
               else
               {
                  _loc9_ = int(_radioBarObj[0]);
               }
               if(GlobalFunction.checkSearchTypeByType(_loc15_,_loc9_))
               {
                  _loc1_ = new Avatar(_loc15_);
                  _loc13_ = _loc14_[_loc16_];
                  _loc13_["id"] = _loc15_;
                  _loc13_["starType"] = _loc1_.getPhaseType() > 0 ? 1 : 0;
                  _loc13_["indn"] = PanelCenterDNTeam.checkIsInDn(_loc1_.id) == null ? 0 : 1;
                  _loc13_["teamNum"] = GlobalFunction.getTeamMemberNum(_loc13_["id"]);
                  _loc13_["star"] = _loc1_.getStar();
                  _loc13_["sort_1"] = _loc1_.avatarData.actionType != 3 ? 0 : 1;
                  _loc13_["sort_2"] = GlobalFunction.checkSearchTypeByType(_loc15_,1) ? 1 : 0;
                  _loc13_["lock"] = GlobalFunction.checkLock(_loc1_.id) ? 1 : 0;
                  _loc13_["power"] = _loc1_.getPower(GlobalData.$userData.team[0].indexOf(_loc1_.id) == 0);
                  _loc13_["type"] = 1;
                  _loc10_.push(_loc13_);
                  _loc1_.clear();
                  _loc1_ = null;
               }
            }
            _loc10_.sortOn(["teamNum","indn","lock","power","id"],[0x10 | 2,0x10 | 2,0x10 | 2,0x10 | 2,1]);
            this.setListTimer(mList,_loc10_,ItemAvatarBetter);
            this.setPageColorNumXY(GlobalLanguageStr.getLanguageStr(97005),null);
            if(_loc10_.length <= 0)
            {
               this.setTips(GlobalLanguageStr.getLanguageStr(90548));
            }
            else if(mTips)
            {
               this.delTips();
            }
         }
         else if(mTabBar.selectedIndex == 1)
         {
            GlobalFunction.clearAvatarBetterItems();
            _loc3_ = GlobalData.$userData.avatars;
            _loc5_ = "";
            for(var _loc8_:Object in _loc3_)
            {
               _loc5_ = _loc8_.toString();
               if(MainConfig.$isHasBuilding)
               {
                  _loc9_ = int(_radioBarObj[1]);
               }
               else if(mRadioBar.selectedIndex == 3)
               {
                  _loc9_ = _radioBarObj[1] + 1;
               }
               else
               {
                  _loc9_ = int(_radioBarObj[1]);
               }
               if(GlobalFunction.checkSearchTypeByType(_loc5_,_loc9_))
               {
                  _loc2_ = new Avatar(_loc5_);
                  _loc12_ = _loc3_[_loc8_];
                  _loc12_["id"] = _loc5_;
                  _loc12_["indn"] = PanelCenterDNTeam.checkIsInDn(_loc2_.id) == null ? 0 : 1;
                  _loc12_["teamNum"] = GlobalFunction.getTeamMemberNum(_loc12_["id"]);
                  _loc12_["star"] = _loc2_.getStar();
                  _loc12_["lv"] = _loc2_.lv;
                  _loc12_["sort_1"] = _loc2_.avatarData.actionType != 3 && _loc2_.getLvMax() > 1 ? 0 : 1;
                  _loc12_["sort_2"] = GlobalFunction.checkSearchTypeByType(_loc5_,1) ? 1 : 0;
                  _loc12_["lock"] = GlobalFunction.checkLock(_loc2_.id) ? 1 : 0;
                  _loc12_["power"] = _loc2_.getPower(GlobalData.$userData.team[0].indexOf(_loc2_.id) == 0);
                  _loc12_["starType"] = _loc2_.getPhaseType() > 0 ? 1 : 0;
                  _loc12_["lvMax"] = _loc2_.lv >= _loc2_.getLvMax() && _loc2_.lv > 1 ? 1 : 0;
                  _loc12_["type"] = 0;
                  _itemArr.push(_loc12_);
                  _loc2_.clear();
                  _loc2_ = null;
               }
            }
            _itemArr.sortOn(["teamNum","indn","lock","sort_1","power","id"],[0x10 | 2,0x10 | 2,0x10 | 2,16,0x10 | 2,1]);
            this.setListTimer(mList,_itemArr,ItemAvatarBetter);
            this.setPageColorNumXY(GlobalLanguageStr.getLanguageStr(97005),null);
            if(_itemArr.length <= 0)
            {
               this.setTips(GlobalLanguageStr.getLanguageStr(90548));
            }
            else if(mTips)
            {
               this.delTips();
            }
         }
         else if(mTabBar.selectedIndex == 2)
         {
            _itemArr = [];
            _loc3_ = GlobalData.$userData.avatars;
            _loc5_ = "";
            for(_loc8_ in _loc3_)
            {
               _loc5_ = _loc8_.toString();
               if(MainConfig.$isHasBuilding)
               {
                  _loc9_ = int(_radioBarObj[2]);
               }
               else if(mRadioBar.selectedIndex == 3)
               {
                  _loc9_ = _radioBarObj[2] + 1;
               }
               else
               {
                  _loc9_ = int(_radioBarObj[2]);
               }
               if(GlobalFunction.checkSearchTypeByType(_loc5_,_loc9_))
               {
                  _loc2_ = new Avatar(_loc5_);
                  _loc12_ = _loc3_[_loc8_];
                  _loc12_["id"] = _loc5_;
                  _loc12_["indn"] = PanelCenterDNTeam.checkIsInDn(_loc2_.id) == null ? 0 : 1;
                  _loc12_["teamNum"] = GlobalFunction.getTeamMemberNum(_loc5_);
                  _loc12_["starType"] = _loc2_.getPhaseType() > 0 ? 1 : 0;
                  _loc12_["lvMax"] = _loc2_.lv >= _loc2_.getLvMax() && _loc2_.lv > 1 ? 1 : 0;
                  _loc12_["star"] = _loc2_.getStar();
                  _loc12_["talent"] = _loc2_.talent;
                  _loc12_["lock"] = GlobalFunction.checkLock(_loc2_.id) ? 1 : 0;
                  _loc12_["power"] = _loc2_.getPower(GlobalData.$userData.team[0].indexOf(_loc2_.id) == 0);
                  _itemArr.push(_loc12_);
                  _loc2_.clear();
                  _loc2_ = null;
               }
            }
            _itemArr.sortOn(["teamNum","indn","lock","starType","power","id"],[0x10 | 2,0x10 | 2,0x10 | 2,0x10 | 2,0x10 | 2,1]);
            this.setListTimer(mList,_itemArr,ItemAvatarStarUp);
            this.setPageColorNumXY(GlobalLanguageStr.getLanguageStr(97005),null);
            if(_itemArr.length <= 0)
            {
               this.setTips(GlobalLanguageStr.getLanguageStr(90548));
            }
            else if(mTips)
            {
               this.delTips();
            }
         }
         else if(mTabBar.selectedIndex == 3)
         {
            _itemArr = [];
            _loc3_ = GlobalData.$userData.avatars;
            _loc5_ = "";
            for(_loc8_ in _loc3_)
            {
               _loc5_ = _loc8_.toString();
               if(MainConfig.$isHasBuilding)
               {
                  _loc9_ = int(_radioBarObj[3]);
               }
               else if(mRadioBar.selectedIndex == 3)
               {
                  _loc9_ = _radioBarObj[3] + 1;
               }
               else
               {
                  _loc9_ = int(_radioBarObj[3]);
               }
               if(GlobalFunction.checkSearchTypeByType(_loc5_,_loc9_))
               {
                  _loc2_ = new Avatar(_loc5_);
                  _loc12_ = _loc3_[_loc8_];
                  _loc12_["id"] = _loc5_;
                  _loc12_["indn"] = PanelCenterDNTeam.checkIsInDn(_loc2_.id) == null ? 0 : 1;
                  _loc12_["teamNum"] = GlobalFunction.getTeamMemberNum(_loc5_);
                  _loc12_["starType"] = _loc2_.getPhaseType() > 0 ? 1 : 0;
                  _loc12_["lvMax"] = _loc2_.lv >= _loc2_.getLvMax() && _loc2_.lv > 1 ? 1 : 0;
                  _loc12_["star"] = _loc2_.getStar();
                  _loc12_["isHero"] = GlobalFunction.checkSearchTypeByType(_loc5_,1) ? 1 : 0;
                  _loc12_["lock"] = GlobalFunction.checkLock(_loc2_.id) ? 1 : 0;
                  _loc12_["power"] = _loc2_.getPower(GlobalData.$userData.team[0].indexOf(_loc2_.id) == 0);
                  _itemArr.push(_loc12_);
                  _loc2_.clear();
                  _loc2_ = null;
               }
            }
            if(_boo == false)
            {
               _itemArr.sortOn(["teamNum","indn","isHero","star","starType","lock","power","id"],[0x10 | 2,0x10 | 2,0x10 | 2,0x10 | 2,0x10 | 2,0x10 | 2,0x10 | 2,1]);
            }
            else
            {
               _itemArr.sortOn(["isHero","star","starType","teamNum","indn","lock","power","id"],[0x10 | 2,0x10 | 2,0x10 | 2,0x10 | 2,0x10 | 2,0x10 | 2,0x10 | 2,1]);
            }
            this.setListTimer(mList,_itemArr,ItemAvatarFoster);
            this.setPageColorNumXY(GlobalLanguageStr.getLanguageStr(97005),null);
            if(_itemArr.length <= 0)
            {
               this.setTips(GlobalLanguageStr.getLanguageStr(90548));
            }
            else if(mTips)
            {
               this.delTips();
            }
            if(GlobalData.$userData.lv >= 30)
            {
               GuideMaster.getOnlyExample().checkGuide("M15_2",nextGuide);
            }
         }
         else if(mTabBar.selectedIndex == 4)
         {
            this.setListHeight(250);
            ensureRarityFilters(mList.y);
            layoutRarityFilters(mList.y);
            mList.y += mRarityRowHeight;
            mList.height = Math.max(120,mList.height - mRarityRowHeight);
            _itemArr = [];
            _loc3_ = GlobalData.$userData.avatars;
            _loc6_ = false;
            _loc4_ = false;
            _loc5_ = "";
            for(_loc8_ in _loc3_)
            {
               _loc5_ = _loc8_.toString();
               _loc6_ = PanelAvatarSell.isHeroAssigned(_loc5_);
               _loc4_ = GlobalFunction.checkLock(_loc5_);
               if(MainConfig.$isHasBuilding)
               {
                  _loc9_ = int(_radioBarObj[4]);
               }
               else if(mRadioBar.selectedIndex == 3)
               {
                  _loc9_ = _radioBarObj[4] + 1;
               }
               else
               {
                  _loc9_ = int(_radioBarObj[4]);
               }
               if(GlobalFunction.checkSearchTypeByType(_loc5_,_loc9_) || GlobalData.$tempSell.indexOf(_loc5_) > -1 && GlobalFunction.checkSearchTypeByType(_loc5_,_loc9_))
               {
                  _loc2_ = new Avatar(_loc5_);
                  _loc12_ = _loc3_[_loc8_];
                  _loc12_["id"] = _loc5_;
                  _loc12_["sort_1"] = _loc2_.getSellValue();
                  _loc12_["lock"] = _loc6_ || _loc4_ ? 1 : 0;
                  _loc12_["material_protected"] = _loc6_ ? 1 : 0;
                  _loc12_["auto_blocked"] = PanelAvatarSell.isAutoBlocked(_loc12_) ? 1 : 0;
                  _itemArr.push(_loc12_);
                  _loc2_.clear();
                  _loc2_ = null;
               }
            }
            _itemArr.sortOn(["lock","sort_1"],[16,0x10 | 2]);
            _loc11_ = 0;
            firstSelect = 0;
            _loc7_ = 0;
            while(_loc7_ < _itemArr.length)
            {
               if(_loc11_ >= tempSelect)
               {
                  break;
               }
               _loc12_ = _itemArr[_loc7_];
               if(!PanelAvatarSell.matchesRarity(_loc12_["id"]) || _loc12_["auto_blocked"])
               {
                  _loc7_++;
                  continue;
               }
               if(!_loc12_["lock"])
               {
                  GlobalData.$tempSell.push(_loc12_["id"]);
                  if(_loc11_ == 0)
                  {
                     firstSelect = _loc7_;
                  }
                  _loc11_++;
               }
               _loc7_++;
            }
            if(tempSelect > 0 && _loc11_ == 0)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90115),false,"A_3002_1");
            }
            mList.height = Math.max(120,GlobalData.$center_height - 273 - mRarityRowHeight);
            tempSelect = 0;
            this.setListTimer(mList,_itemArr,ItemAvatarSell,false);
            bringRarityFiltersToFront();
            if(_itemArr.length <= 0)
            {
               this.setTips(GlobalLanguageStr.getLanguageStr(90548));
            }
            else if(mTips)
            {
               this.delTips();
            }
         }
      }
      
      private function nextGuide() : void
      {
         var _loc1_:Avatar = null;
         var _loc5_:int = 0;
         var _loc4_:Object = GlobalData.$mConfig_simple.culture;
         var _loc2_:Array = Tools.getObjectAllProperty(GlobalData.$userData.avatars);
         var _loc3_:Boolean = false;
         _loc5_ = 0;
         while(_loc5_ < _loc2_.length)
         {
            if(_loc2_[_loc5_])
            {
               _loc1_ = new Avatar(_loc2_[_loc5_]);
               if(_loc1_.getStar() >= _loc4_.avatar_culture[0] && GlobalFunction.checkSearchTypeByType(_loc1_.id,1))
               {
                  _loc3_ = true;
               }
            }
            _loc5_++;
         }
         if(_loc3_ == true)
         {
            _boo = true;
            this.setList();
            this.addList();
            _boo = false;
            GuideMaster.getOnlyExample().checkGuide("M15_4",closeGuide);
            this.mList.verticalScrollPolicy = "off";
         }
         else
         {
            GuideMaster.getOnlyExample().checkGuide("M15_3");
         }
      }
      
      private function closeGuide() : void
      {
         LayoutUIAnimation.getOnlyExample().clearIfNoGuide();
      }
      
      override public function tabBar_changeHandler(param1:Event) : void
      {
         $tabBarSelectedIndex = mTabBar.selectedIndex;
         var _loc2_:int = mTabBar.selectedIndex;
         if(MainConfig.$isHasBuilding)
         {
            this.mRadioBar.setChildStatus(3,!($tabBarSelectedIndex == 1 || $tabBarSelectedIndex == 2 || $tabBarSelectedIndex == 3));
            this.mRadioBar.setChildStatus(4,!($tabBarSelectedIndex == 1 || $tabBarSelectedIndex == 2 || $tabBarSelectedIndex == 3));
            this.mRadioBar.setChildStatus(2,!($tabBarSelectedIndex == 1 || $tabBarSelectedIndex == 2 || $tabBarSelectedIndex == 3));
         }
         else
         {
            this.mRadioBar.setChildStatus(3,!($tabBarSelectedIndex == 1 || $tabBarSelectedIndex == 2 || $tabBarSelectedIndex == 3));
            this.mRadioBar.setChildStatus(2,!($tabBarSelectedIndex == 1 || $tabBarSelectedIndex == 2 || $tabBarSelectedIndex == 3));
         }
         _radioSelectIndex = _radioBarObj[_loc2_];
         if(mTabBar)
         {
            if(_loc2_ == 4)
            {
               GlobalFunction.clearSellItems();
               mImg9x9_bg = GlobalFunction.createScale9Image("UI_bg_9slice_4_0000",630,110,new Rectangle(110,60,30,15));
               mImg9x9_bg.x = int((GlobalData.$mStageWidth - mImg9x9_bg.width) * 0.5);
               mImg9x9_bg.y = GlobalData.$center_height - mImg9x9_bg.height + 5;
               addChild(mImg9x9_bg);
               this.mBtn_clear = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20228),126,47,"UI_btn_enterGame_0_0000");
               this.mBtn_sell = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20072),126,47,"UI_btn_enterGame_0_0000");
               this.mBtn_clear.x = this.mImg9x9_bg.x + 20 + 10;
               this.mBtn_sell.x = this.mImg9x9_bg.x + this.mImg9x9_bg.width - this.mBtn_sell.width - 20 - 10;
               this.addChild(this.mBtn_clear);
               this.addChild(this.mBtn_sell);
               this.mBtn_clear.name = BTN_NAME_CLEAR;
               this.mBtn_sell.name = BTN_NAME_SELL;
               this.mBtn_clear.addEventListener("triggered",this.onTRIGGERED_btns);
               this.mBtn_sell.addEventListener("triggered",this.onTRIGGERED_btns);
               this.mBtn_sell.y = this.mBtn_clear.y = this.mImg9x9_bg.y + 25 + 7;
            }
            if(_radioBarObj[mTabBar.selectedIndex] == mRadioBar.selectedIndex)
            {
               update();
            }
            else
            {
               mRadioBar.selectedIndex = _radioBarObj[mTabBar.selectedIndex];
            }
         }
      }
      
      public function onTRIGGERED_btns(param1:Event) : void
      {
         var _loc4_:int = 0;
         var _loc2_:Object = null;
         var _loc3_:Object = null;
         var _loc5_:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         if(_loc5_.name == BTN_NAME_CLEAR)
         {
            mRarityDiagEvent = GlobalData.$tempSell.length > 0 ? "social-sell-clear" : "social-sell-quick-select";
            if(GlobalData.$tempSell.length > 0)
            {
               tempSelect = 0;
            }
            else
            {
               tempSelect = 10;
            }
            GlobalData.$tempSellItem = {};
            GlobalData.$tempSell = [];
            setList();
            addList();
            mList.scrollToPosition(0,Math.max(int(firstSelect / 5) * 124 - 62,0),0);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_avatar_sell_data");
            this.reportRarityDiagnostic(mRarityDiagEvent,GlobalData.$tempSell.length);
            mRarityDiagEvent = "social-sell-update";
         }
         else if(_loc5_.name == BTN_NAME_SELL)
         {
            if(GlobalData.$tempSell.length > 0)
            {
               _loc2_ = GlobalFunction.formateBetterItemsError();
               if(_loc2_.s)
               {
                  _loc3_ = {
                     "ok":popSell,
                     "okA":["Pop"],
                     "no":GlobalFunction.functionNull
                  };
                  _loc4_ = int(_loc2_.s);
                  if(_loc2_.name)
                  {
                     _loc3_.aid = _loc2_.aid;
                     GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90077,_loc4_,_loc2_.name),GlobalTextStyle.COLOR_W_Y_Y_G),_loc3_);
                  }
                  else
                  {
                     GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90055,_loc4_),GlobalTextStyle.COLOR_W_Y_Y_G),_loc3_);
                  }
               }
               else
               {
                  popSell();
               }
            }
            else
            {
               GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(90009));
            }
         }
      }
      
      private function popSell() : void
      {
         var _loc1_:Object = {
            "ok":service_sell,
            "no":GlobalFunction.functionNull
         };
         GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(20069),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90008,mGold_all,GlobalData.$tempSell.length),GlobalTextStyle.COLOR_W_Y_Y_G),_loc1_);
      }
      
      private function service_sell() : void
      {
         if(stage == null || SendAndSelect.checkRepeat("user.sell_avatar",""))
         {
            return;
         }
         var _loc1_:Array = GlobalData.$tempSell.concat();
         if(_loc1_.length == 0)
         {
            return;
         }
         mSellOperation++;
         var _op:uint = mSellOperation;
         var _epoch:uint = mSellViewEpoch;
         SendServiceAMFFun.send_user_sell_avatar(function(param1:Object):void
         {
            re_sell_avatar(param1,_op,_epoch,_loc1_);
         },{"aids":_loc1_});
      }
      
      private function re_sell_avatar(param1:Object, param2:uint, param3:uint, param4:Array) : void
      {
         if(GlobalFunction.isMalformedProfileReceipt(param1))
         {
            return;
         }
         if(GlobalFunction.isLegacyProfileReceipt(param1))
         {
            RpcStaticCall.$remoting.reportDiagnostic("PROFILE_RECEIPT_LEGACY|method=user.sell_avatar");
         }
         if(param2 != mSellOperation || param2 == mHandledSellOperation)
         {
            return;
         }
         mHandledSellOperation = param2;
         var _selected:Array = GlobalData.$tempSell;
         var _sameSelection:Boolean = _selected.length == param4.length;
         var _idx:int = 0;
         while(_sameSelection && _idx < param4.length)
         {
            if(_selected.indexOf(param4[_idx]) < 0)
            {
               _sameSelection = false;
            }
            _idx++;
         }
         _idx = _selected.length - 1;
         while(_idx >= 0)
         {
            if(param4.indexOf(_selected[_idx]) >= 0 && GlobalData.$userData.avatars[_selected[_idx]] == null)
            {
               _selected.splice(_idx,1);
            }
            _idx--;
         }
         if(stage == null || param3 != mSellViewEpoch)
         {
            return;
         }
         var _loc2_:* = 0;
         SoundManager.getOnlyExample().playSound("E_8003",0.4);
         SoundManager.getOnlyExample().playSound("E_9021",0.4);
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
         if(_sameSelection)
         {
            GlobalFunction.clearSellItems();
         }
         this.update();
      }
      
      public function formatTxtInfo() : void
      {
         GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
         this.mGold_all = GlobalFunction.getSellAvatarGold();
         var _loc3_:Number = GlobalData.$tempSell.length;
         var _loc2_:Number = GlobalData.$userData_avatarNum;
         var _loc1_:Number = Number(GlobalData.$userData.attrs.avatar_len);
         this.setTxtInfo(GlobalLanguageStr.getLanguageStr(20073,_loc3_),GlobalLanguageStr.getLanguageStr(20074,_loc3_,10),GlobalLanguageStr.getLanguageStr(98133,this.mGold_all,_loc2_,_loc1_));
         if(GlobalData.$tempSell.length > 0)
         {
            this.mBtn_sell.enabled = true;
            this.mBtn_clear.text = GlobalLanguageStr.getLanguageStr(20228);
         }
         else
         {
            this.mBtn_sell.enabled = false;
            this.mBtn_clear.text = GlobalLanguageStr.getLanguageStr(90990);
         }
      }
      
      public function setTxtInfo(param1:*, param2:*, param3:*) : void
      {
         if(this.mTxt_info == null)
         {
            this.mTxt_info = GlobalTextStyle.getHtmlTextRenderer();
            this.mTxt_info.touchable = false;
            this.mTxt_info.width = GlobalData.$mStageWidth * 0.5;
            this.mTxt_info.textFormat = GlobalTextStyle.style_format();
            this.mTxt_info.textFormat.leading = 0;
            this.mTxt_info.isHTML = true;
            this.mTxt_info.x = this.mBtn_clear.x + this.mBtn_clear.width + 20 + 15;
            this.mTxt_info.y = this.mBtn_clear.y - 15 - 2;
            this.addChild(this.mTxt_info);
         }
         this.setTxtInfoCo(param1,param2,param3);
      }
      
      public function setTxtInfoCo(param1:*, param2:*, param3:*) : void
      {
         var _loc4_:Array = [Tools.formatLineX(param1,GlobalTextStyle.COLOR_0x4B2C1B,1000,20),Tools.formatLineX(param2,GlobalTextStyle.COLOR_0x4B2C1B,1000,20),Tools.formatLineX(param3,GlobalTextStyle.COLOR_0x4B2C1B,1000,20)];
         this.mTxt_info.text = Tools.formatHtmlTextBr(_loc4_,"left");
      }
      
      public function onUPDATE_AVATAR_DATA(param1:Event) : void
      {
         this.formatTxtInfo();
      }
      
      public function checkList(param1:Boolean) : void
      {
         if(mList)
         {
            if(param1)
            {
               mList.visible = true;
            }
            else
            {
               mList.visible = false;
            }
         }
      }
      
      public function clearPriv() : void
      {
         removeRarityFilters();
         if(mTxt_info)
         {
            mTxt_info.removeFromParent(true);
            mTxt_info.dispose();
         }
         if(mBtn_clear)
         {
            mBtn_clear.removeFromParent(true);
            mBtn_clear.dispose();
         }
         if(this.mBtn_sell)
         {
            mBtn_sell.removeFromParent(true);
            mBtn_sell.dispose();
         }
         if(mImgBg)
         {
            mImgBg.removeFromParent(true);
            mImgBg.dispose();
         }
         if(mImg9x9_bg)
         {
            mImg9x9_bg.removeFromParent(true);
            mImg9x9_bg.dispose();
         }
         this.mTxt_info = null;
         this.mBtn_clear = null;
         this.mBtn_sell = null;
         this.mImgBg = null;
         this.mImg9x9_bg = null;
         tempSelect = 0;
         firstSelect = 0;
      }
   }
}

