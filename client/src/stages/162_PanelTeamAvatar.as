package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.ui.element.ItemAvatarForTeam;
   import com.meng52.game.ui.element.LOL_IconText;
   import com.meng52.game.ui.screen.PanelAvatarSell;
   import com.meng52.game.ui.screen.PanelCenterDNTeam;
   import com.meng52.game.ui.screen.PanelCenterMainAvatar;
   import com.meng52.utils.Tools;
   import starling.events.Event;
   import starling.display.Sprite;
   
   public class PanelTeamAvatar extends PanelCenterMainAvatar
   {
      
      public static var $tabBarSelectedIndex:int = 0;
      
      public static const FUN_TYPE_DN:String = "dn";
      
      public static const FUN_TYPE_TEAM:String = "team";
      
      public static var $mTypeFun:String = "";
      
      private var _iconText:LOL_IconText;
      private var mRosterFilters:Sprite;
      private var mRosterState:Object = {"quality":0,"order":0,"descending":true};
      
      public function PanelTeamAvatar(param1:String = "team")
      {
         $mTypeFun = param1;
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         var _loc3_:Avatar = null;
         this.removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalData.$tempChangeAvatarTitle,GlobalData.$center_height_curr - 121);
         mRosterFilters = PanelAvatarSell.createRosterFilters(mRosterState,update,GlobalData.$mStageWidth);
         addChild(mRosterFilters);
         var _loc4_:Array = [{"label":GlobalLanguageStr.getLanguageStr(20236)},{"label":GlobalLanguageStr.getLanguageStr(20165)},{"label":GlobalLanguageStr.getLanguageStr(20255)}];
         if(MainConfig.$isHasBuilding)
         {
            _loc4_.push({"label":GlobalLanguageStr.getLanguageStr(20256)});
         }
         _loc4_.push({"label":GlobalLanguageStr.getLanguageStr(20257)});
         setSmallTabBar(_loc4_,tabBar_changeHandler,tabBar_CREATION_COMPLETE);
         this.mTabBar.selectedIndex = $tabBarSelectedIndex;
         if($mTypeFun == "dn")
         {
            $tabBarSelectedIndex = 1;
         }
         GlobalData.$tempTeamSelectLS = GlobalFunction.getTeamLeaderShip(GlobalData.$userData.team[0]);
         var _loc2_:int = 0;
         if(GlobalData.$tempTeamSelect && GlobalData.$tempTeamSelect.id != "" && GlobalData.$tempTeamSelect.id != null)
         {
            _loc3_ = new Avatar(GlobalData.$tempTeamSelect.id,GlobalData.$tempTeamSelect);
            _loc2_ = GlobalData.$tempTeamSelectLS - _loc3_.getLeadership();
         }
         else
         {
            _loc2_ = GlobalData.$tempTeamSelectLS;
         }
         _iconText = new LOL_IconText(GlobalLanguageStr.getLanguageStr(20170,_loc2_ + "/" + GlobalData.$tempUserLS));
         _iconText.x = 28;
         _iconText.y = GlobalData.$center_height_curr - 121 - 60;
         addChild(_iconText);
         GlobalData.$mEventDispatcher.addEventListener("change_team_member",CHANGE_TEAM_MEMBER);
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(mRosterFilters) mRosterFilters.removeFromParent(true);
         mRosterFilters = null;
         super.onREMOVED_FROM_STAGE(param1);
         GlobalData.$mEventDispatcher.removeEventListener("change_team_member",CHANGE_TEAM_MEMBER);
      }
      
      private function CHANGE_TEAM_MEMBER(param1:Event) : void
      {
         super.onCLOSE_PANEL_SELF();
      }
      
      override public function tabBar_CREATION_COMPLETE(param1:*) : void
      {
         if($mTypeFun == "dn")
         {
            mTabBar.setChildStatus(0,false);
            mTabBar.setChildStatus(2,false);
            mTabBar.setChildStatus(3,false);
            if(MainConfig.$isHasBuilding)
            {
               mTabBar.setChildStatus(4,false);
            }
         }
         mTabBar.x = 30;
         mTabBar.y = this.mImg9_baseBg.y + 85;
         if($tabBarSelectedIndex > 0)
         {
            this.mTabBar.selectedIndex = $tabBarSelectedIndex;
         }
         else
         {
            tabBar_changeHandler(null);
         }
      }
      
      override public function tabBar_changeHandler(param1:Event) : void
      {
         if(mTabBar)
         {
            update();
         }
      }
      
      override public function update() : void
      {
         super.update();
      }
      
      override public function addList() : void
      {
         var _loc12_:Object = null;
         var _loc1_:Avatar = null;
         var _loc10_:int = 0;
         mList.height = GlobalData.$center_height_curr - 121;
         if(this.mTabBar)
         {
            $tabBarSelectedIndex = this.mTabBar.selectedIndex;
         }
         var _loc5_:Array = [];
         var _loc6_:Object = GlobalData.$userData.avatars;
         var _loc2_:Boolean = GlobalData.$tempTeamSelect["indexID_s"] == 0;
         var _loc4_:String = GlobalFunction.getCurrTeamLeaderID(GlobalData.$tempTeamID);
         var _loc7_:Boolean = true;
         var _loc3_:Array = [];
         var _loc13_:Object = null;
         var _loc8_:String = "";
         var _loc11_:Array = GlobalData.$tempTeam;
         for(var _loc9_:Object in _loc6_)
         {
            _loc7_ = true;
            _loc8_ = _loc9_.toString();
            if(MainConfig.$isHasBuilding)
            {
               _loc10_ = this.mTabBar.selectedIndex;
            }
            else if(this.mTabBar.selectedIndex == 3)
            {
               _loc10_ = this.mTabBar.selectedIndex + 1;
            }
            else
            {
               _loc10_ = this.mTabBar.selectedIndex;
            }
            if(GlobalFunction.checkSearchTypeByType(_loc8_,_loc10_))
            {
               _loc1_ = new Avatar(_loc8_);
               _loc12_ = _loc6_[_loc9_];
               _loc12_["id"] = _loc8_;
               _loc12_["lsAll"] = GlobalData.$tempTeamSelectLS;
               _loc12_["power"] = GlobalFunction.getOwnedAvatarPower(_loc1_.id,GlobalData.$userData.team[0].indexOf(_loc1_.id) == 0);
               _loc12_["t_index"] = _loc11_.indexOf(_loc8_) > -1 ? _loc11_.indexOf(_loc8_) : 100;
               _loc12_["d_index"] = PanelCenterDNTeam.checkIsInDn(_loc8_) != null ? 1 : 0;
               if(_loc1_.avatarData.actionType != 3)
               {
                  if(!Tools.strIsNull(GlobalData.$tempTeamSelect.id) && GlobalData.$tempTeamSelect.id == _loc8_)
                  {
                     _loc13_ = _loc12_;
                  }
                  else
                  {
                     _loc5_.push(_loc12_);
                  }
               }
               else
               {
                  _loc3_.push(_loc12_);
               }
               _loc1_.clear();
               _loc1_ = null;
            }
         }
         _loc5_.sortOn(["t_index","d_index","power","id"],[16,0x10 | 2,0x10 | 2,1]);
         _loc5_ = _loc5_.concat(_loc3_);
         if(_loc13_ != null)
         {
            _loc5_.unshift(_loc13_);
         }
         mRosterState.previewTeam = _loc11_;
         _loc5_ = PanelAvatarSell.filterRosterRows(_loc5_,mRosterState);
         if(!Tools.strIsNull(GlobalData.$tempTeamSelect.id) && !_loc2_ || $mTypeFun == "dn" && !Tools.strIsNull(GlobalData.$tempTeamSelect.id))
         {
            _loc5_.unshift({"id":""});
         }
         _loc13_ = null;
         _loc3_ = null;
         mList.y = this.mImg9_baseBg.y + 85 + 60;
         mList.height = this.mImg9_baseBg.height - 85 - 35 - 85;
         if(mRosterFilters)
         {
            mRosterFilters.y = mList.y;
            mList.y += 38;
            mList.height = Math.max(80,mList.height-38);
            setChildIndex(mRosterFilters,numChildren-1);
         }
         this.setListTimer(mList,_loc5_,ItemAvatarForTeam,false);
      }
   }
}

