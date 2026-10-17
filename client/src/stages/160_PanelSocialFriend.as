package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.ui.element.ItemSocialFriend;
   import com.meng52.game.ui.screen.PanelCenterPVE;
   import com.meng52.net.SendServiceAMFFun;
   import feathers.layout.VerticalLayout;
   import starling.events.Event;

   public class PanelSocialFriend extends PanelCenterPVE
   {

      public static var $currFriendIndex:int = -1;

      public var mData_re:Object;

      public var mData_f:Array;

      public var mRef:Number = 0;

      public function PanelSocialFriend()
      {
         super();
      }

      override protected function initializeHandler(param1:Event) : void
      {
         $currFriendIndex = -1;
         this.removeEventListener("addedToStage",initializeHandler);
         GlobalData.$mEventDispatcher.addEventListener("update_social_friend_del",this.onUPDATE_SOCIAL_FRIEND_DEL);
         GlobalData.$mEventDispatcher.addEventListener("update_social_request",this.onUPDATE_SOCIAL_REQUEST);
         update();
      }

      private function onUPDATE_SOCIAL_REQUEST() : void
      {
         this.update();
      }

      override public function update() : void
      {
         this.setList();
         this.select();
      }

      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         $currFriendIndex = -1;
         GlobalData.$mEventDispatcher.removeEventListener("update_social_request",this.onUPDATE_SOCIAL_REQUEST);
         GlobalData.$mEventDispatcher.removeEventListener("update_social_friend_del",this.onUPDATE_SOCIAL_FRIEND_DEL);
         super.onREMOVED_FROM_STAGE(param1);
      }

      private function onUPDATE_SOCIAL_FRIEND_DEL(param1:Event) : void
      {
         this.update_del();
      }

      public function update_del() : void
      {
         var _loc1_:* = 0;
         if(GlobalData.$tempSocial_friend)
         {
            _loc1_ = 0;
            while(_loc1_ < GlobalData.$tempFriend.length)
            {
               if(GlobalData.$tempFriend[_loc1_].uid == GlobalData.$tempSocial_friend.uid)
               {
                  GlobalData.$tempFriend.splice(_loc1_,1);
                  break;
               }
               _loc1_++;
            }
         }
         this.setList();
         this.addList();
         GlobalData.$tempSocial_friend = null;
      }

      public function select() : void
      {
         SendServiceAMFFun.send_user_get_friends(this.reService);
      }

      public function reService(param1:Object) : void
      {
         GlobalData.$tempFriend = param1.data.friends_list;
         GlobalData.$tempFriendRequest = param1.data.apply_list;
         this.addList();
      }

      override public function addList() : void
      {
         var _loc1_:VerticalLayout = null;
         var _loc2_:Array = GlobalData.$tempFriend.concat();
         if(_loc2_.length <= 0)
         {
            this.setTips(GlobalLanguageStr.getLanguageStr(90026));
            this.mTips.y = (GlobalData.$center_height - mTips.height) / 2 - 70;
            this.delPageNum();
         }
         else
         {
            this.delTips();
            mList.height = GlobalData.$center_height_curr - 121 - 167;
            mList.y = 17;
            _loc1_ = new VerticalLayout();
            _loc1_.paddingLeft = 30;
            _loc1_.gap = -5;
            mList.layout = _loc1_;
            _loc2_.sortOn("login_time",0x10 | 2);
            this.setListTimer(mList,_loc2_,ItemSocialFriend,true,$currFriendIndex);
         }
         var _loc3_:Object = GlobalData.$userData;
         this.setPageNumXY("",{
            "m":_loc2_.length,
            "d":_loc3_.attrs.friend_len
         },0,GlobalData.$center_height_curr - 121 - 150);
         if(this.mPageNum)
         {
            this.mPageNum.text = GlobalLanguageStr.getLanguageStr(25059,{
               "m":_loc2_.length,
               "d":_loc3_.attrs.friend_len
            });
         }
         _loc2_ = null;
      }
   }
}
