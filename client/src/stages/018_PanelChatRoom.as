package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.ui.element.LOL_ChatItem;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.element.LOL_TextInput;
   import com.meng52.game.ui.screen.PanelCenterMainAvatar;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.global.SocketManager;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.StarlingTools;
   import feathers.controls.ScrollContainer;
   import feathers.display.Scale9Image;
   import feathers.layout.VerticalLayout;
   import flash.geom.Rectangle;
   import starling.display.DisplayObject;
   import starling.display.DisplayObjectContainer;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class PanelChatRoom extends PanelCenterMainAvatar
   {
      
      private static var BTN_BLACKLIST:String = "btn_blacklist";
      
      private static var BTN_SEND:String = "btn_send";
      
      private var mBtn_blackList:LOL_Scale9Button;
      
      private var mChatScroll:ScrollContainer;
      
      private var mImg_bg:Scale9Image;
      
      private var m_input:LOL_TextInput;
      
      private var mTxt_input_info:TextField;
      
      private var mImg_input_bg:Scale9Image;
      
      private var mBtn_send:LOL_Scale9Button;
      
      private var mInput_spr:Sprite;
      
      private var _temp:LOL_ChatItem;
      
      private var mChatIcon:Sprite;
      
      private var M_CHATBG_WIDTH:int = 0;
      
      private var M_CHATBG_HEIGHT:int = 0;
      
      private var scrollTrueHeight:Number = 0;
      
      private var init_verticalScrollPosition:Number = 0;
      
      private var chat_cfg:Object;
      
      private var data:Object;
      
      private var level:int;
      
      private var _show_id:String;
      
      private var lvAllZone:int;
      
      public function PanelChatRoom(param1:Object)
      {
         data = param1;
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         M_CHATBG_HEIGHT = GlobalData.$center_height + 90;
         GlobalData.$mGameClassObject.mLayoutUITop.visible = false;
         GlobalData.$mGameClassObject.mLayoutUIBottom.visible = false;
         GlobalData.$mGameClassObject.mLayoutUICenter.visible = false;
         this.removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getStr(90713),M_CHATBG_HEIGHT);
         GlobalData.$mEventDispatcher.addEventListener("update_show_chatwords",pushToScrollContainer);
         GlobalData.$mEventDispatcher.addEventListener("send_privatechat_userdata",setPrivateChatUserData);
         var _loc2_:Object = GlobalData.$mGuild_simple.the_guild_info;
         level = _loc2_.user_level_limit;
         lvAllZone = GlobalData.$mConfig_simple.start_lv[21];
         initUI();
      }
      
      public function chatIcon(param1:Boolean = true) : void
      {
         if(this.mTabBar && this.mTabBar.selectedIndex == 2)
         {
            if(mChatIcon)
            {
               mChatIcon.removeFromParent(true);
               mChatIcon.dispose();
            }
            mChatIcon = null;
            GlobalData.$hasChatWords = false;
            return;
         }
         if(param1)
         {
            if(mChatIcon)
            {
               return;
            }
            mChatIcon = GlobalFunction.getTagPopTip(1,false);
            mChatIcon.x = 325;
            mChatIcon.y = 90;
            this.addChild(mChatIcon);
            GlobalData.$hasChatWords = true;
         }
         else
         {
            if(mChatIcon)
            {
               mChatIcon.removeFromParent(true);
               mChatIcon.dispose();
            }
            mChatIcon = null;
            GlobalData.$hasChatWords = false;
         }
      }
      
      private function setPrivateChatUserData(param1:Event) : void
      {
         GlobalData.$mGameClassObject.closePopForPanel(1);
         GlobalData.$mPrivateChatUserData = param1.data;
         if(GlobalData.$tempChatRoomIndex == 2)
         {
            set_tabbat_info2();
         }
         else if(mTabBar)
         {
            this.mTabBar.selectedIndex = 2;
         }
      }
      
      private function pushToScrollContainer(param1:Event) : void
      {
         var _loc2_:Object = null;
         if(!checkInBlackList(param1.data))
         {
            _loc2_ = param1.data;
            if(_loc2_.method == "chat_private" && !isMe(_loc2_))
            {
            }
            show_list(_loc2_);
         }
      }
      
      override public function update() : void
      {
      }
      
      private function initUI() : void
      {
         chat_cfg = GlobalData.$mConfig_simple.chat;
         this.setSmallTabBar([{
            "label":GlobalLanguageStr.getStr(90715),
            "indexID":0
         },{
            "label":GlobalLanguageStr.getStr(90714),
            "indexID":1
         },{
            "label":GlobalLanguageStr.getStr(90716),
            "indexID":2
         },{
            "label":GlobalLanguageStr.getStr(97665),
            "indexID":3
         }],tabBar_Change,tabBar_CREATION_COMPLETE,100);
         this.mTabBar.x = 40;
         this.mTabBar.y = 90;
         var _loc3_:uint = uint(GlobalData.$tempChatRoomIndex);
         this.mTabBar.selectedIndex = GlobalData.$tempChatRoomIndex;
         if(chat_cfg.black_status != 0)
         {
            mBtn_blackList = new LOL_Scale9Button(GlobalLanguageStr.getStr(90717),126,48,"UI_btn_smallFun_1_0000");
            mBtn_blackList.x = this.mImg9_baseBg.width - mBtn_blackList.width - 50;
            mBtn_blackList.y = this.mTabBar.y + 5;
            mBtn_blackList.name = BTN_BLACKLIST;
            mBtn_blackList.textColor = 1513239;
            mBtn_blackList.addEventListener("triggered",btn_click);
            mBtn_blackList.touchable = false;
            this.addChild(mBtn_blackList);
         }
         mInput_spr = new Sprite();
         this.addChild(mInput_spr);
         mImg_input_bg = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",560,145,new Rectangle(70,20,50,50));
         mInput_spr.addChild(mImg_input_bg);
         var _loc1_:Array = GlobalData.$userData.records.chat_free_count;
         if(!_loc1_)
         {
            _loc1_ = [0,0];
            GlobalData.$userData.records.chat_free_count = _loc1_;
         }
         mTxt_input_info = GlobalFunction.createTextField(570,30,GlobalLanguageStr.getLanguageStr(95019),"",20);
         mTxt_input_info.x = mImg_input_bg.x + (mImg_input_bg.width - mTxt_input_info.width) * 0.5;
         mTxt_input_info.y = 20;
         mInput_spr.addChild(mTxt_input_info);
         m_input = new LOL_TextInput();
         m_input.prompt = GlobalLanguageStr.getStr(90719);
         m_input.x = mImg_input_bg.x + 20;
         m_input.y = mTxt_input_info.y + mTxt_input_info.height + 10;
         m_input.focusHandler = onFOCUS;
         m_input.touchable = false;
         mInput_spr.addChild(m_input);
         mBtn_send = new LOL_Scale9Button(GlobalLanguageStr.getStr(20140),126,48,"UI_btn_enterGame_0_0000");
         mBtn_send.x = m_input.x + m_input.width + 15;
         mBtn_send.y = m_input.y + (m_input.height - mBtn_send.height) * 0.5;
         mBtn_send.name = BTN_SEND;
         mBtn_send.addEventListener("triggered",btn_click);
         mBtn_send.touchable = false;
         mInput_spr.addChild(mBtn_send);
         if(data)
         {
            if(data.status == 1)
            {
               mTabBar.selectedIndex = 1;
               if(GlobalData.$userGuild.chatText)
               {
                  m_input.text = GlobalData.$userGuild.chatText;
                  GlobalData.$userGuild.chatText = null;
               }
               func_btn_send();
            }
            if(data.status == 2)
            {
               if(GlobalData.$userGuild.ChatPrivate)
               {
                  GlobalData.$userGuild.ChatPrivate = null;
                  mTabBar.selectedIndex = 2;
                  GlobalData.$mEventDispatcher.dispatchEventWith("send_privatechat_userdata",false,data.data);
               }
            }
         }
         mInput_spr.x = 5 + this.mImg9_baseBg.x + (this.mImg9_baseBg.width - mInput_spr.width) * 0.5;
         mInput_spr.y = mTabBar.y + mTabBar.height + 60;
         mImg_bg = GlobalFunction.createScale9Image("UI_bg_9slice_7_0000",556,M_CHATBG_HEIGHT - 325,new Rectangle(25,25,10,10));
         mImg_bg.x = this.mImg9_baseBg.x + (this.mImg9_baseBg.width - mImg_bg.width) * 0.5;
         mImg_bg.y = mInput_spr.y + mInput_spr.height;
         this.addChild(mImg_bg);
         mChatScroll = new ScrollContainer();
         mChatScroll.setSize(570,M_CHATBG_HEIGHT - 350);
         var _loc2_:VerticalLayout = new VerticalLayout();
         _loc2_.gap = 15;
         _loc2_.paddingLeft = 15;
         mChatScroll.layout = _loc2_;
         mChatScroll.hasElasticEdges = false;
         mChatScroll.horizontalScrollPolicy = "off";
         mChatScroll.x = this.mImg9_baseBg.x + (this.mImg9_baseBg.width - mChatScroll.width) * 0.5;
         mChatScroll.y = mImg_bg.y + 10;
         this.addChild(mChatScroll);
         GlobalData.$mEventDispatcher.addEventListener("update_chat",update_chat);
         chatIcon(GlobalData.$hasChatWords);
         tabBar_Change(null);
      }
      
      private function onScroll(param1:Event) : void
      {
         var _loc3_:int = 0;
         var _loc2_:DisplayObject = null;
         var _loc4_:int = (mChatScroll.viewPort as DisplayObjectContainer).numChildren;
         if(_loc4_ > 0)
         {
            _loc3_ = 0;
            while(_loc3_ < _loc4_)
            {
               _loc2_ = (mChatScroll.viewPort as DisplayObjectContainer).getChildAt(_loc3_);
               if(_loc2_ == null)
               {
                  break;
               }
               if(_loc2_.getBounds(_loc2_.parent.parent).y < -30 || _loc2_.getBounds(_loc2_.parent.parent).y > mChatScroll.height + 30)
               {
                  _loc2_.visible = false;
               }
               else
               {
                  _loc2_.visible = true;
               }
               _loc3_++;
            }
         }
      }
      
      private function update_chat(param1:Event) : void
      {
         if(!isMe(param1.data))
         {
            chatIcon();
         }
      }
      
      private function onFOCUS(param1:String) : void
      {
         switch(param1)
         {
            case "focusIn":
               if(this.m_input.text.length > chat_cfg.max_word)
               {
                  mTxt_input_info.color = 10027008;
                  mTxt_input_info.text = GlobalLanguageStr.getLanguageStr(90721,m_input.text.length - chat_cfg.max_word);
               }
               else
               {
                  mTxt_input_info.color = 1118481;
                  mTxt_input_info.text = GlobalLanguageStr.getLanguageStr(90720,chat_cfg.max_word - m_input.text.length);
               }
               break;
            case "focusOut":
               switch(mTabBar.selectedIndex)
               {
                  case 0:
                     mTxt_input_info.text = GlobalLanguageStr.getStr(97641);
                     break;
                  case 1:
                     set_tabbat_input_info0();
                     break;
                  case 2:
                     set_tabbat_info2();
                     break;
                  case 3:
                     mTxt_input_info.text = GlobalLanguageStr.getStr(97987);
               }
               break;
            case "change":
               if(m_input.hasFocus)
               {
                  if(m_input.text.length > chat_cfg.max_word)
                  {
                     mTxt_input_info.color = 10027008;
                     mTxt_input_info.text = GlobalLanguageStr.getLanguageStr(90721,m_input.text.length - chat_cfg.max_word);
                  }
                  else
                  {
                     mTxt_input_info.color = 1118481;
                     mTxt_input_info.text = GlobalLanguageStr.getLanguageStr(90720,chat_cfg.max_word - m_input.text.length);
                  }
               }
         }
      }
      
      private function btn_click(param1:Event) : void
      {
         var _loc2_:String = (param1.currentTarget as LOL_Scale9Button).name;
         switch(_loc2_)
         {
            case BTN_BLACKLIST:
               func_btn_blacklist();
               break;
            case BTN_SEND:
               func_btn_send();
         }
      }
      
      private function func_btn_send() : void
      {
         if(this.m_input)
         {
            if(GlobalFunction.checkNullString(this.m_input.text))
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90123));
               this.m_input.text = "";
               switch(mTabBar.selectedIndex)
               {
                  case 0:
                     mTxt_input_info.text = GlobalLanguageStr.getStr(97641);
                     break;
                  case 1:
                     set_tabbat_input_info0();
                     break;
                  case 2:
                     set_tabbat_input_info2();
                     break;
                  case 3:
                     mTxt_input_info.text = GlobalLanguageStr.getStr(97987);
               }
            }
            else if(this.m_input.text.length > chat_cfg.max_word)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90722));
            }
            else if(allow_toSend())
            {
               chat_send_msg();
            }
            else
            {
               LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getStr(90728),1);
            }
         }
      }
      
      private function moveScrollY() : void
      {
      }
      
      private function sendRequest() : void
      {
      }
      
      private function func_btn_blacklist() : void
      {
         SendServiceAMFFun.send_user_chat_black_info(re_black_lis_Func,{});
      }
      
      private function re_black_lis_Func(param1:Object) : void
      {
         if(param1.data)
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_chatroom_blacklist",false,true,param1);
         }
      }
      
      private function tabBar_Change(param1:Event) : void
      {
         GlobalData.$tempChatRoomIndex = this.mTabBar.selectedIndex;
         clearPanel();
         switch(mTabBar.selectedIndex)
         {
            case 0:
               mTxt_input_info.text = GlobalLanguageStr.getStr(97641);
               set_msg_to_ScrollContainer(mTabBar.selectedIndex);
               break;
            case 1:
               set_tabbat_input_info0();
               set_msg_to_ScrollContainer(mTabBar.selectedIndex);
               break;
            case 2:
               chatIcon(false);
               set_tabbat_info2();
               set_tabbat_input_info2();
               break;
            case 3:
               mTxt_input_info.text = GlobalLanguageStr.getStr(97987);
               set_msg_to_ScrollContainer(mTabBar.selectedIndex);
         }
      }
      
      private function set_tabbat_input_info0() : void
      {
         mTxt_input_info.color = 1118481;
         mTxt_input_info.text = GlobalLanguageStr.getLanguageStr(90718,had_chat_count());
      }
      
      private function had_chat_count() : int
      {
         var _loc2_:int = int(int(GlobalData.$userData.vip_lv) > 0 ? int(GlobalFunction.getVipObj(GlobalData.$userData.vip_lv).close_sever_talk) : 0);
         var _loc1_:int = int(chat_cfg.free_count) + _loc2_;
         return int(_loc1_ - int(GlobalData.$userData.records.chat_free_count[0]));
      }
      
      private function set_tabbat_input_info2() : void
      {
         GlobalData.$mEventDispatcher.dispatchEventWith("update_chat_server");
         set_msg_to_ScrollContainer(mTabBar.selectedIndex);
      }
      
      private function set_tabbat_info2() : void
      {
         var _loc1_:String = null;
         var _loc2_:String = null;
         mTxt_input_info.color = 1118481;
         if(GlobalData.$mPrivateChatUserData)
         {
            _loc2_ = "";
            if(GlobalData.$mPrivateChatUserData.method == "chat_private" && this.isMe(GlobalData.$mPrivateChatUserData))
            {
               _loc2_ = GlobalData.$mConfig_zones[GlobalData.$mPrivateChatUserData.tzone][0];
               _loc1_ = GlobalLanguageStr.getLanguageStr(90729,GlobalData.$mPrivateChatUserData.tname,_loc2_);
            }
            else
            {
               _loc2_ = GlobalData.$mConfig_zones[GlobalData.$mPrivateChatUserData.zone][0];
               _loc1_ = GlobalLanguageStr.getLanguageStr(90729,GlobalData.$mPrivateChatUserData.name,_loc2_);
            }
         }
         else
         {
            _loc1_ = GlobalLanguageStr.getStr(90726);
         }
         mTxt_input_info.text = _loc1_;
      }
      
      private function chat_private_record_backFun(param1:Object) : void
      {
         var _loc2_:Array = null;
         var _loc3_:int = 0;
         if(param1.data)
         {
            GlobalData.$userData.attrs.chat_private = false;
            GlobalData.$mEventDispatcher.dispatchEventWith("update_chat_server");
            _loc2_ = param1.data.record;
            _loc2_.sortOn(["t"],[16]);
            _loc3_ = 0;
            while(_loc3_ < _loc2_.length)
            {
               SocketManager.getInstance().setMsg(_loc2_[_loc3_]);
               _loc3_++;
            }
            set_msg_to_ScrollContainer(mTabBar.selectedIndex);
         }
      }
      
      private function set_msg_to_ScrollContainer(param1:int) : void
      {
         var _loc2_:Array = [];
         switch(param1)
         {
            case 0:
               _loc2_ = SocketManager.getInstance().getMsg("chat_zone");
               checkAndShowList(_loc2_);
               break;
            case 1:
               _loc2_ = SocketManager.getInstance().getMsg("chat_all_zone");
               checkAndShowList(_loc2_);
               break;
            case 2:
               _loc2_ = SocketManager.getInstance().getMsg("chat_private");
               checkAndShowList(_loc2_);
               break;
            case 3:
               _loc2_ = SocketManager.getInstance().getMsg("chat_guild");
               checkAndShowList(_loc2_);
         }
      }
      
      private function checkAndShowList(param1:Array) : void
      {
         var _loc2_:Object = null;
         var _loc3_:int = 0;
         _loc3_ = 0;
         while(_loc3_ < param1.length)
         {
            _loc2_ = param1[_loc3_];
            if(!checkInBlackList(_loc2_))
            {
               if(_loc2_)
               {
                  show_list(_loc2_);
               }
            }
            _loc3_++;
         }
      }
      
      private function show_list(param1:Object) : void
      {
         if(mChatScroll)
         {
            _temp = null;
            switch(mTabBar.selectedIndex)
            {
               case 0:
                  if(param1.method == "chat_zone")
                  {
                     if(mChatScroll.numChildren >= chat_cfg.max_msg)
                     {
                        mChatScroll.removeChildAt(mChatScroll.numChildren - 1,true);
                     }
                     _temp = new LOL_ChatItem(param1);
                     mChatScroll.addChildAt(_temp,0);
                     mChatScroll.scrollToPosition(0,0,0);
                  }
                  break;
               case 1:
                  if(param1.method == "chat_all_zone")
                  {
                     if(mChatScroll.numChildren >= chat_cfg.max_msg)
                     {
                        mChatScroll.removeChildAt(mChatScroll.numChildren - 1,true);
                     }
                     _temp = new LOL_ChatItem(param1);
                     mChatScroll.addChildAt(_temp,0);
                     mChatScroll.scrollToPosition(0,0,0);
                  }
                  break;
               case 2:
                  if(param1.method == "chat_private")
                  {
                     if(mChatScroll.numChildren >= chat_cfg.private_save_len)
                     {
                        mChatScroll.removeChildAt(mChatScroll.numChildren - 1,true);
                     }
                     _temp = new LOL_ChatItem(param1);
                     mChatScroll.addChildAt(_temp,0);
                     mChatScroll.scrollToPosition(0,0,0);
                  }
                  break;
               case 3:
                  if(param1.method == "chat_guild")
                  {
                     if(mChatScroll.numChildren >= chat_cfg.max_msg)
                     {
                        mChatScroll.removeChildAt(mChatScroll.numChildren - 1,true);
                     }
                     _temp = new LOL_ChatItem(param1);
                     mChatScroll.addChildAt(_temp,0);
                     mChatScroll.scrollToPosition(0,0,0);
                  }
            }
         }
      }
      
      private function chat_send_msg() : void
      {
         var _loc1_:Array = m_input.text.match(new RegExp("^[a-zA-Z0-9\\一-\\龥\\ ~!@#$%^&*()_+-=:;\"\'<,>.?/\\！￥（）{}【】；：‘”《》，。？、……——]+$"));
         if(_loc1_ == null)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90737),false);
            return;
         }
         m_input.text = _loc1_.join();
         switch(mTabBar.selectedIndex)
         {
            case 0:
               send_msg_1();
               break;
            case 1:
               send_msg_0();
               break;
            case 2:
               send_msg_2();
               break;
            case 3:
               send_msg_3();
         }
      }
      
      private function send_msg_0() : void
      {
         var fun:* = function(param1:int = 0):void
         {
            if(GlobalData.$userData.coin < int(chat_cfg.waste_coin))
            {
               GlobalFunction.popErrorCoin(int(chat_cfg.waste_coin));
            }
            else
            {
               fun1();
               fun2(param1);
            }
         };
         var fun1:* = function():void
         {
            GlobalData.$mGameClassObject.closePopForPanel(1);
         };
         var fun2:* = function(param1:int = 0):void
         {
            if(m_input.text)
            {
               send_data = {
                  "s":get_send_txt(),
                  "hint":param1
               };
               SendServiceAMFFun.send_user_chat_all_zone(captureVipBefore(reFun0),send_data);
            }
         };
         var send_data:Object = {};
         var chat_free_count:Array = GlobalData.$userData.records.chat_free_count;
         if(had_chat_count() > 0)
         {
            fun2();
         }
         else if(had_chat_count() <= 0 && chat_free_count[1] == 0)
         {
            send_data = {
               "width":600,
               "height":370,
               "title":GlobalLanguageStr.getStr(90010),
               "info":GlobalLanguageStr.getLanguageStr(90732,chat_cfg.waste_coin),
               "func":{
                  "ok":fun,
                  "no":fun1
               }
            };
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_chatroom_serverpay",false,true,send_data);
         }
         else if(GlobalData.$userData.coin < int(chat_cfg.waste_coin))
         {
            GlobalFunction.popErrorCoin(int(chat_cfg.waste_coin));
         }
         else
         {
            fun2();
         }
      }
      
      private function get_send_txt() : String
      {
         return GlobalFunction.filterString(m_input.text);
      }
      
      private function reFun0(param1:Object) : void
      {
         if(this.stage == null) return;
         var _loc2_:Number = NaN;
         if(param1.data)
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.records.chat_free_count = param1.data.chat_free_count;
            }
            _loc2_ = SendAndSelect.$systemTimer_nowSecond * 1000;
            GlobalData.$pro_send_time_server = (param1.server_now as Date).time;
            this.m_input.text = "";
            mTxt_input_info.text = GlobalLanguageStr.getLanguageStr(90718,had_chat_count());
            showVipTransition(param1);
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.coin = param1.data.coin;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.vip_lv = param1.data.vip_lv;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.vip_exp = param1.data.vip_exp;
            }
            GlobalFunction.updateCoin();
            GlobalFunction.updateVip();
         }
      }
      
      private function send_msg_1() : void
      {
         var _loc1_:Object = {"s":get_send_txt()};
         SendServiceAMFFun.send_user_chat_zone(reFun1,_loc1_);
      }
      
      private function reFun1(param1:Object) : void
      {
         var _loc2_:Number = SendAndSelect.$systemTimer_nowSecond * 1000;
         GlobalData.$pro_send_time_world = (param1.server_now as Date).time;
         this.m_input.text = "";
      }
      
      private function send_msg_2() : void
      {
         var _loc2_:Object = null;
         var _loc1_:Object = null;
         if(GlobalData.$mPrivateChatUserData)
         {
            if(checkInBlackList(GlobalData.$mPrivateChatUserData))
            {
               LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getStr(90739));
            }
            else
            {
               _loc2_ = GlobalData.$mPrivateChatUserData;
               _loc1_ = {};
               if(GlobalData.$mPrivateChatUserData.method == "chat_private" && isMe(_loc2_))
               {
                  _loc1_ = {
                     "tuid":_loc2_.tuid,
                     "tzone":_loc2_.tzone,
                     "s":get_send_txt()
                  };
               }
               else
               {
                  _loc1_ = {
                     "tuid":_loc2_.uid,
                     "tzone":_loc2_.zone,
                     "s":get_send_txt()
                  };
               }
               SendServiceAMFFun.send_user_chat_private(reFun2,_loc1_);
            }
         }
         else
         {
            LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getStr(90736));
         }
      }
      
      private function reFun2(param1:Object) : void
      {
         var _loc2_:Number = SendAndSelect.$systemTimer_nowSecond * 1000;
         GlobalData.$pro_send_time_private = (param1.server_now as Date).time;
         this.m_input.text = "";
      }
      
      private function allow_toSend() : Boolean
      {
         var _loc1_:Boolean = false;
         if(mTabBar.selectedIndex == 0)
         {
            _loc1_ = SendAndSelect.$systemTimer_nowSecond * 1000 - GlobalData.$pro_send_time_world > Number(chat_cfg.interval) * 1000;
         }
         else if(mTabBar.selectedIndex == 1)
         {
            _loc1_ = SendAndSelect.$systemTimer_nowSecond * 1000 - GlobalData.$pro_send_time_server > Number(chat_cfg.interval) * 1000;
         }
         else if(mTabBar.selectedIndex == 2)
         {
            _loc1_ = SendAndSelect.$systemTimer_nowSecond * 1000 - GlobalData.$pro_send_time_private > Number(chat_cfg.interval) * 1000;
         }
         else if(mTabBar.selectedIndex == 3)
         {
            _loc1_ = SendAndSelect.$systemTimer_nowSecond * 1000 - GlobalData.$pro_send_time_guild > Number(chat_cfg.interval) * 1000;
         }
         return _loc1_;
      }
      
      private function send_msg_3() : void
      {
         var _loc1_:Object = {"s":get_send_txt()};
         SendServiceAMFFun.send_user_chat_guild(reFun3,_loc1_);
      }
      
      private function reFun3(param1:Object) : void
      {
         var _loc2_:Number = SendAndSelect.$systemTimer_nowSecond * 1000;
         GlobalData.$pro_send_time_guild = (param1.server_now as Date).time;
         this.m_input.text = "";
      }
      
      override public function tabBar_CREATION_COMPLETE(param1:*) : void
      {
         if(GlobalData.$userData.lv < level)
         {
            mTabBar.setChildStatus(3,false,tabBar_changeHandler_false);
         }
         else
         {
            SendServiceAMFFun.send_user_associatione_is(onReGuild);
         }
         if(GlobalData.$userData.lv < lvAllZone)
         {
            mTabBar.setChildStatus(1,false,tabBar_changeHandler_false);
         }
      }
      
      private function onReGuild(param1:Object) : void
      {
         if(param1.data.flag == 0)
         {
            mTabBar.setChildStatus(3,false,tabBar_changeHandler_false);
         }
      }
      
      override public function tabBar_changeHandler_false(param1:int) : void
      {
         var _loc2_:int = param1;
         if(mTabBar && _loc2_ == 3)
         {
            _show_id = GlobalData.$mConfig_simple.show_id[8];
            GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(98002),{"aid":_show_id});
         }
         if(_loc2_ == 1)
         {
            _show_id = GlobalData.$mConfig_simple.show_id[8];
            GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(90129,lvAllZone),{"aid":_show_id});
         }
      }
      
      public function clearPanel() : void
      {
         if(mChatScroll)
         {
            mChatScroll.scrollToPosition(0,0,0);
            mChatScroll.removeChildren(0,-1,true);
         }
      }
      
      private function isMe(param1:Object) : Boolean
      {
         var _loc2_:Boolean = false;
         if(param1.uid == GlobalData.$userData.uid && param1.zone == GlobalData.$userData.zone)
         {
            _loc2_ = true;
         }
         return _loc2_;
      }
      
      private function checkInBlackList(param1:Object) : Boolean
      {
         var _loc3_:Boolean = false;
         if(chat_cfg.black_status == 0)
         {
            return _loc3_;
         }
         var _loc5_:Array = GlobalData.$userData.chat_black;
         var _loc4_:int = int(_loc5_.length);
         var _loc7_:int = 0;
         var _loc6_:Object = param1;
         var _loc2_:Object = {};
         if(_loc6_.method == "chat_private" && isMe(param1))
         {
            _loc2_ = {
               "tuid":_loc6_.tuid,
               "tzone":_loc6_.tzone
            };
         }
         else
         {
            _loc2_ = {
               "tuid":_loc6_.uid,
               "tzone":_loc6_.zone
            };
         }
         _loc7_ = 0;
         while(_loc7_ < _loc4_)
         {
            if(_loc5_[_loc7_].uid == _loc2_.tuid)
            {
               _loc3_ = true;
               break;
            }
            _loc7_++;
         }
         return _loc3_;
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalData.$tempChatRoomIndex = 0;
         GlobalData.$chatBtnTouchable = true;
         GlobalData.$mGameClassObject.mLayoutUITop.visible = true;
         GlobalData.$mGameClassObject.mLayoutUIBottom.visible = true;
         GlobalData.$mGameClassObject.mLayoutUICenter.visible = true;
         GlobalData.$mEventDispatcher.removeEventListener("update_show_chatwords",pushToScrollContainer);
         GlobalData.$mEventDispatcher.removeEventListener("send_privatechat_userdata",setPrivateChatUserData);
         if(mBtn_blackList)
         {
            mBtn_blackList.dispose();
            mBtn_blackList.removeFromParent(true);
         }
         mBtn_blackList = null;
         if(mChatScroll)
         {
            mChatScroll.dispose();
            mChatScroll.removeFromParent(true);
         }
         mChatScroll = null;
         if(mImg_bg)
         {
            mImg_bg.dispose();
            mImg_bg.removeFromParent(true);
         }
         mImg_bg = null;
         StarlingTools.removeChildrenClear(this);
         if(m_input)
         {
            m_input.dispose();
            m_input.removeFromParent(true);
         }
         m_input = null;
         if(mTxt_input_info)
         {
            mTxt_input_info.dispose();
            mTxt_input_info.removeFromParent(true);
         }
         mTxt_input_info = null;
         if(mImg_input_bg)
         {
            mImg_input_bg.dispose();
            mImg_input_bg.removeFromParent(true);
         }
         mImg_input_bg = null;
         if(mBtn_send)
         {
            mBtn_send.dispose();
            mBtn_send.removeFromParent(true);
         }
         mBtn_send = null;
         if(mInput_spr)
         {
            StarlingTools.removeChildrenClear(mInput_spr);
         }
         mInput_spr = null;
         if(_temp)
         {
            _temp.clear();
         }
         _temp = null;
         if(mChatIcon)
         {
            StarlingTools.removeChildrenClear(mChatIcon);
         }
         mChatIcon = null;
         super.onREMOVED_FROM_STAGE(param1);
      }
      private var _vipTransitionReceipts:Array = [];

      private function captureVipBefore(param1:Function) : Function
      {
         var _beforeVip:int = int(GlobalData.$userData.vip_lv);
         return function(param2:Object):void
         {
            param2._vip_before_request = _beforeVip;
            param2._vip_after_request = param2.data.user_dict != null ? int(param2.data.user_dict.vip_lv) : int(param2.data.vip_lv);
            param1(param2);
         };
      }

      private function showVipTransition(param1:Object) : void
      {
         if(this.stage == null)
         {
            return;
         }
         var _beforeVip:int = int(param1._vip_before_request);
         var _afterVip:int = int(param1._vip_after_request);
         if(_afterVip <= _beforeVip)
         {
            return;
         }
         if(_afterVip != int(GlobalData.$userData.vip_lv))
         {
            return;
         }
         var _revisionKey:String = String(param1.method) + ":" + String(param1.state_sync.uid) + ":" + String(param1.state_sync.revision);
         if(_vipTransitionReceipts.indexOf(_revisionKey) >= 0)
         {
            return;
         }
         _vipTransitionReceipts.push(_revisionKey);
         GlobalFunction.popAward("_$vip$_",GlobalLanguageStr.getLanguageStr(20203,_afterVip),_afterVip);
      }

   }
}
