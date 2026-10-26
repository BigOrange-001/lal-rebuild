package com.meng52.game.ui.screen
{
   import com.meng52.game.Game;
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.manager.TimeManager;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_TeamSet;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.element.LOL_TextField;
   import com.meng52.game.ui.panel.PanelRollInfo;
   import com.meng52.game.ui.panel.PanelSocialMail;
   import com.meng52.game.ui.stage.GuideTools;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.global.ConfigManager;
   import com.meng52.global.SocketManager;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.events.NetEvent;
   import com.meng52.utils.Tools;
   import flash.display.BitmapData;
   import flash.display.PNGEncoderOptions;
   import flash.filesystem.File;
   import flash.filesystem.FileStream;
   import flash.geom.Matrix;
   import flash.geom.Rectangle;
   import flash.text.TextField;
   import flash.text.TextFormat;
   import flash.utils.ByteArray;
   import starling.animation.Tween;
   import starling.core.Starling;
   import starling.display.Image;
   import starling.display.MovieClip;
   import starling.display.Sprite;
   import starling.display.Quad;
   import starling.events.EnterFrameEvent;
   import starling.events.Event;
   import starling.filters.ColorMatrixFilter;
   import starling.utils.deg2rad;
   
   public class PanelCenterMain extends PanelBase
   {
      
      public static const CHATROOM_BTN:String = "chatroom_btn";
      
      public var mPanelTeamSet:LOL_TeamSet;
      
      public var mEditBg:Image;
      
      public var mEdit:LOL_Button;
      
      public var mBtn_casino:LOL_Button;
      
      public var mBtn_equip:LOL_Button;
      
      public var mBtn_avatar:LOL_Button;
      
      public var mBtn_science:LOL_Button;
      
      public var mBtn_alchemy:LOL_Button;
      
      public var mBtn_pvp:LOL_Button;
      
      public var mBtn_checkin:LOL_Button;
      
      public var mBtn_award:LOL_Button;
      
      public var mBtn_friend:LOL_Button;
      
      public var mBtn_guild:LOL_Button;
      
      public var mScience_MC:MovieClip;
      
      public var mUI_card_MC:MovieClip;
      
      public var mUI_water_MC:MovieClip;
      
      public var mUI_light_MC:MovieClip;
      
      public var mUI_pool_IMG:Image;
      
      public var mUI_ball_MC:MovieClip;
      
      public var mArr_flag_:Array;
      
      public var mImg_equip:Image;
      
      public var mImg_science:Image;
      
      public var mImg_alchemy:Image;
      
      private var mTxt_casino:Image;
      
      private var mTxt_equip:Image;
      
      private var mTxt_avatar:Image;
      
      private var mTxt_science:Image;
      
      private var mTxt_alchemy:Image;
      
      private var mTxt_pvp:Image;
      
      public var mBox_btns:Sprite;
      
      private var mRec_bg:Rectangle;
      
      public var mBtn_mail:LOL_Button;
      
      public var mImg_title:Image;
      
      private var mFriendIcon:Sprite;
      
      private var mMailIcon:Sprite;
      
      private var mAwardIcon:Sprite;
      
      private var mGetSoulIcon:Sprite;
      
      private var mCheckInIcon:Sprite;
      
      private var mChatIcon:Sprite;
      
      private var _reqNum:int = 0;
      
      public var mSendRedio:LOL_Button;
      
      public var mPanelRollInfo:PanelRollInfo;
      
      private var mTag_a:Sprite;
      
      private var mTag_b:Sprite;
      
      private var _pop:Sprite;
      
      private var mClip_casino:Image;
      
      private var mClip_casino_timer:Number = 0;
      
      private var mClip_casino_Y:Number = 0;
      
      private var constXY:Object = {};
      
      private var b0:Boolean = false;
      
      private var b1:Boolean = false;
      
      private var _show_id:String;
      
      private var _now:Number;
      
      private var userTime:Object = {};
      
      private var _cfg:Object = {};
      
      private var openStatus:int;

      private var mPanelGeneration:int = 0;

      private var mPresetPopup:Sprite;
      private var mPresetRows:Sprite;
      private var mPresetGeneration:int = 0;
      private var mPresetBusy:Boolean = false;
      private var mPresetActionID:String = "";
      private var mPresetNotice:String = "";
      
      public function PanelCenterMain()
      {
         _cfg = getNewStartTime();
         super();
      }
      
      public static function gotoOpenActivityPanel(param1:String = "") : void
      {
         var _loc17_:String = null;
         _loc17_ = "rank";
         var _loc9_:String = null;
         var _loc13_:Object = null;
         var _loc16_:Array = null;
         var _loc4_:Number = NaN;
         var _loc6_:Number = NaN;
         var _loc15_:Number = NaN;
         var _loc2_:int = 0;
         var _loc12_:int = 0;
         var _loc7_:Number = NaN;
         var _loc20_:Date = null;
         var _loc14_:Date = null;
         var _loc19_:Number = NaN;
         var _loc8_:int = 0;
         var _loc5_:int = 0;
         var _loc18_:Array = GlobalData.$mConfig_ploy_system_simple.fun_control as Array;
         _loc5_ = int(_loc18_.length);
         var _loc3_:Array = [];
         var _loc11_:int = 0;
         _loc8_ = 0;
         for(; _loc8_ < _loc5_; _loc8_++)
         {
            if(_loc18_[_loc8_] == "rank")
            {
               _loc9_ = SendAndSelect.$serviceId;
               _loc13_ = GlobalData.$mConfig_zones;
               _loc16_ = _loc13_[_loc9_];
               _loc4_ = (_loc16_[1] as Date).time + GlobalConfig.HOURS_8_MS;
               _loc6_ = SendAndSelect.$systemTimer_nowSecond * 1000 + GlobalConfig.HOURS_8_MS;
               _loc15_ = (GlobalData.$userData.add_time as Date).time + GlobalConfig.HOURS_8_MS;
               _loc2_ = int(GlobalData.$mConfig_ploy_system_simple.rank.rank_end);
               _loc12_ = (GlobalData.$mConfig_ploy_system_simple.rank.gift.rank_sort as Array).length + 1;
               _loc7_ = 86400000;
               _loc20_ = new Date();
               _loc20_.setTime(_loc4_);
               _loc14_ = new Date(_loc20_.fullYear,_loc20_.month,_loc20_.date,0);
               _loc19_ = _loc14_.time;
               if(_loc6_ > _loc19_ + _loc7_ * _loc2_ - 1000 || _loc15_ > _loc19_ + _loc7_ * _loc12_ - 1000)
               {
                  continue;
               }
            }
            _loc3_.push(_loc18_[_loc8_]);
         }
         var _loc10_:String = _loc3_[0];
         if(GlobalData.$currentGuide)
         {
            _loc10_ = "task";
         }
         if(param1 != "")
         {
            _loc10_ = param1;
         }
         PanelCenterActivity.$activityFunObj = GlobalFunction.getActivityFun(_loc10_);
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_activity");
      }
      
      private function getConstProperty(param1:String, param2:String) : *
      {
         var _loc3_:Object = null;
         var _loc5_:Object = null;
         var _loc4_:String = param1;
         if(!ConfigManager.getInstance().uiPos.hasOwnProperty(_loc4_))
         {
            return null;
         }
         _loc3_ = ConfigManager.getInstance().getUIPos(_loc4_);
         switch(param2)
         {
            case "width":
               return _loc3_[ConfigManager.WIDTH];
            case "height":
               return _loc3_[ConfigManager.HEIGHT];
            case "pos":
               _loc5_ = {};
               _loc5_["x"] = int(_loc3_[ConfigManager.POSX]);
               _loc5_["y"] = int(_loc3_[ConfigManager.POSY]);
               return _loc5_;
            default:
               return;
         }
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         mArr_flag_ = [];
         GlobalData.$mEventDispatcher.addEventListener("update_center_main_teamset",onMainEvent);
         GlobalData.$mEventDispatcher.addEventListener("update_team_power",onUpdateHomeTeamStats);
         GlobalData.$mEventDispatcher.addEventListener("update_check_in",checkInIcon);
         super.initializeHandler(param1);
         GlobalFunction.resetRollInfo();
         GlobalData.$mGameClassObject.setBgImg("png_bg_center_main_");
         this.mBox_btns = new Sprite();
         this.addChild(this.mBox_btns);
         this.mPanelTeamSet = new LOL_TeamSet(18,15,"show_type_main");
         this.mPanelTeamSet.type = "show_type_main";
         this.mPanelTeamSet.y = -5;
         this.addChild(mPanelTeamSet);
         this.mPanelTeamSet.clearEdit();
         mEditBg = GlobalFunction.createImage("UI_btn_superteambg0000");
         mEditBg.x = GlobalData.$mStageWidth - 114;
         mEditBg.y = 10;
         addChild(mEditBg);
         mEdit = new LOL_Button("","UI_btn_superteam0000",false,false);
         mEdit.name = "UI_btn_superteam0000";
         mEdit.x = GlobalData.$mStageWidth - 106;
         mEdit.y = 15;
         addChild(mEdit);
         mEdit.addEventListener("triggered",button_triggeredHandler);
         var presetButton:LOL_Scale9Button = new LOL_Scale9Button("阵容预设",102,30,"UI_btn_enterGame_0_0000");
         presetButton.x = GlobalData.$mStageWidth - 116;
         presetButton.y = 169;
         presetButton.addEventListener("triggered",openTeamPresets);
         addChild(presetButton);
         mBtn_casino = new LOL_Button("","UI_btn_mainFun0000",false,false);
         mBtn_casino.name = "center_casino";
         mBtn_casino.width = getConstProperty(mBtn_casino.name,ConfigManager.WIDTH);
         mBtn_casino.height = getConstProperty(mBtn_casino.name,ConfigManager.HEIGHT);
         mBox_btns.addChild(mBtn_casino);
         mBtn_casino.addEventListener("triggered",button_triggeredHandler);
         mBtn_avatar = new LOL_Button("","UI_btn_mainFun0000",false,false);
         mBtn_avatar.name = "center_main_avatar";
         mBtn_avatar.width = getConstProperty(mBtn_avatar.name,ConfigManager.WIDTH);
         mBtn_avatar.height = getConstProperty(mBtn_avatar.name,ConfigManager.HEIGHT);
         mBox_btns.addChild(mBtn_avatar);
         mBtn_avatar.addEventListener("triggered",button_triggeredHandler);
         mBtn_equip = new LOL_Button("","UI_btn_mainFun0000",false,false);
         mBtn_equip.name = "center_equip";
         mBtn_equip.width = getConstProperty(mBtn_equip.name,ConfigManager.WIDTH);
         mBtn_equip.height = getConstProperty(mBtn_equip.name,ConfigManager.HEIGHT);
         mBox_btns.addChild(mBtn_equip);
         mBtn_equip.addEventListener("triggered",button_triggeredHandler);
         mBtn_science = new LOL_Button("","UI_btn_mainFun0000",false,false);
         mBtn_science.name = "center_scence";
         mBtn_science.width = getConstProperty(mBtn_science.name,ConfigManager.WIDTH);
         mBtn_science.height = getConstProperty(mBtn_science.name,ConfigManager.HEIGHT);
         mBox_btns.addChild(mBtn_science);
         mBtn_science.addEventListener("triggered",button_triggeredHandler);
         mBtn_alchemy = new LOL_Button("","UI_btn_mainFun0000",false,false);
         mBtn_alchemy.name = "center_alchemy";
         mBtn_alchemy.width = getConstProperty(mBtn_alchemy.name,ConfigManager.WIDTH);
         mBtn_alchemy.height = getConstProperty(mBtn_alchemy.name,ConfigManager.HEIGHT);
         mBox_btns.addChild(mBtn_alchemy);
         mBtn_alchemy.addEventListener("triggered",button_triggeredHandler);
         var _loc2_:Object = GlobalData.$mConfig_simple.check_in;
         if(_loc2_.open_status == 1)
         {
            mBtn_checkin = new LOL_Button("","UI_checkin_0000",false,false);
            mBtn_checkin.name = "center_checkin";
            mBox_btns.addChild(mBtn_checkin);
            mBtn_checkin.x = 10;
            mBtn_checkin.y = 110 + 90;
            mBtn_checkin.addEventListener("triggered",button_triggeredHandler);
         }
         mBtn_award = new LOL_Button("","UI_btn_activityMainFun0000",false,false);
         mBtn_award.name = "center_award";
         mBox_btns.addChild(mBtn_award);
         mBtn_award.x = GlobalData.$mStageWidth - mBtn_award.width - 10;
         mBtn_award.y = GlobalData.$mStageHeight - 121 - mBtn_award.height * 2 + 15;
         mBtn_award.addEventListener("triggered",button_triggeredHandler);
         openStatus = GlobalData.$mGuild_simple.open_status;
         if(openStatus == 1)
         {
            mBtn_friend = new LOL_Button("","UI_btn_friendMainFun0000",false,false);
            mBtn_friend.x = mBtn_award.x + 10;
            mBtn_friend.y = 110 + 90;
         }
         else
         {
            mBtn_friend = new LOL_Button("","UI_btn_friendMainFun0000",false,false);
            mBtn_friend.x = 10;
            mBtn_friend.y = mBtn_award.y;
         }
         mBtn_friend.name = "center_social";
         mBox_btns.addChild(mBtn_friend);
         mBtn_friend.addEventListener("triggered",button_triggeredHandler);
         if(openStatus == 1)
         {
            mBtn_guild = new LOL_Button("","UI_btn_guildEnter0000",false,false);
            mBtn_guild.name = "center_guild";
            mBox_btns.addChild(mBtn_guild);
            mBtn_guild.x = 10;
            mBtn_guild.y = mBtn_award.y;
            mBtn_guild.addEventListener("triggered",button_triggeredHandler);
         }
         mTxt_casino = GlobalFunction.createImage("UI_txt_mainFun_000" + 0);
         mTxt_avatar = GlobalFunction.createImage("UI_txt_mainFun_000" + 1);
         mTxt_equip = GlobalFunction.createImage("UI_txt_mainFun_000" + 2);
         mTxt_science = GlobalFunction.createImage("UI_txt_mainFun_000" + 6);
         mTxt_alchemy = GlobalFunction.createImage("UI_txt_mainFun_000" + 7);
         mTxt_equip.visible = false;
         mTxt_science.visible = false;
         mTxt_alchemy.visible = false;
         if(GlobalFunction.checkGameFunIsOpenByType("equip_fun_change") < 0)
         {
            mImg_equip = GlobalFunction.createImage("UI_equip_bg",true);
            mImg_equip.touchable = false;
            mBox_btns.addChild(mImg_equip);
            mTxt_equip.visible = true;
         }
         if(GlobalFunction.checkIOSvip() && check_chat_open())
         {
            if(GlobalData.$mConfig_simple.radio[1] > 0)
            {
               mSendRedio = new LOL_Button("","UI_redio_btn_0_0000",false,false);
               mSendRedio.y = 130;
               mSendRedio.x = 20;
               mSendRedio.name = "chatroom_btn";
               addChild(this.mSendRedio);
               mSendRedio.addEventListener("triggered",button_triggeredHandler);
               chatIcon(GlobalData.$userData.attrs.chat_private);
               GlobalData.$mEventDispatcher.addEventListener("update_chat",update_chat);
               GlobalData.$mEventDispatcher.addEventListener("update_chat_server",resetChatIcon);
            }
         }
         this.mBtn_mail = new LOL_Button("","UI_btn_2_0000",false,false);
         this.mBtn_mail.name = "center_mail";
         this.mBtn_mail.x = 565;
         this.mBtn_mail.y = 138;
         this.addChild(this.mBtn_mail);
         mBtn_mail.addEventListener("triggered",button_triggeredHandler);
         mBox_btns.addChild(mTxt_casino);
         mBox_btns.addChild(mTxt_avatar);
         mBox_btns.addChild(mTxt_equip);
         mBox_btns.addChild(mTxt_science);
         mBox_btns.addChild(mTxt_alchemy);
         _pop = new Sprite();
         addChild(_pop);
         SendServiceAMFFun.send_user_get_friends(this.reService);
         awardIcon();
         GlobalData.$mEventDispatcher.addEventListener("update_mail_tag",UPDATE_MAIL_TAG);
         getSoulIcon(PanelCenterSoul.checkSoulIcon().x);
      }
      
      private function check_chat_open() : Boolean
      {
         var _loc1_:Object = GlobalData.$mConfig_simple.chat;
         return _loc1_.open_status >= 1;
      }
      
      private function update_chat(param1:Event) : void
      {
         if(!isMe(param1.data) && GlobalData.$tempChatRoomIndex != 2)
         {
            chatIcon();
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
      
      private function resetChatIcon() : void
      {
         chatIcon(GlobalData.$userData.attrs.chat_private);
      }
      
      public function chatIcon(param1:Boolean = true) : void
      {
         if(param1)
         {
            if(mChatIcon)
            {
               return;
            }
            GlobalData.$hasChatWords = true;
            mChatIcon = GlobalFunction.getTagPopTip(1,false);
            mChatIcon.x = mSendRedio.x + mSendRedio.width - 15;
            mChatIcon.y = mSendRedio.y + 5;
            this.addChild(mChatIcon);
         }
         else
         {
            if(mChatIcon)
            {
               GlobalData.$hasChatWords = false;
               mChatIcon.removeFromParent(true);
               mChatIcon.dispose();
            }
            mChatIcon = null;
         }
      }
      
      private function UPDATE_MAIL_TAG(param1:Event) : void
      {
         SendServiceAMFFun.send_user_get_msg(this.reServiceMsg);
      }
      
      public function reService(param1:Object) : void
      {
         if(stage == null)
         {
            return;
         }
         GlobalFunction.delLoading();
         GlobalData.$tempFriend = param1.data.friends_list;
         GlobalData.$tempFriendRequest = param1.data.apply_list;
         friendIcon();
         SendServiceAMFFun.send_user_get_msg(this.reServiceMsg);
      }
      
      public function reServiceMsg(param1:Object) : void
      {
         if(stage == null)
         {
            return;
         }
         GlobalFunction.delLoading();
         if(!param1 || !param1.data)
         {
            return;
         }
         var _loc2_:* = param1.data.gift_msg;
         var _loc4_:* = param1.data.data;
         var _loc3_:Boolean = false;
         for(var _loc5_:Object in _loc2_)
         {
            if(int(_loc2_[_loc5_]["status"]) != 1)
            {
               _loc3_ = true;
               break;
            }
         }
         if(_loc4_.length > 0)
         {
            _loc3_ = true;
         }
         mailIcon(_loc3_);
      }
      
      public function get getRoll() : PanelRollInfo
      {
         return this.mPanelRollInfo;
      }
      
      private function onMainEvent(param1:Event) : void
      {
         if(mPanelTeamSet)
         {
            mPanelTeamSet.update();
         }
      }

      private function onUpdateHomeTeamStats(param1:Event) : void
      {
         if(mPanelTeamSet)
         {
            mPanelTeamSet.update();
         }
      }
      
      public function friendIcon() : void
      {
         if(GlobalData.$tempFriendRequest != null || GlobalData.$friendReques_new_num > 0)
         {
            if(GlobalData.$tempFriendRequest != null)
            {
               _reqNum = GlobalData.$tempFriendRequest.length;
            }
            else
            {
               _reqNum = GlobalData.$friendReques_new_num;
            }
            if(mFriendIcon)
            {
               mFriendIcon.removeFromParent(true);
               mFriendIcon.dispose();
            }
            this.mFriendIcon = null;
            mFriendIcon = GlobalFunction.getTagPopTip(_reqNum,false);
            mFriendIcon.x = mBtn_friend.x + 58;
            mFriendIcon.y = mBtn_friend.y + 50;
            _pop.addChild(mFriendIcon);
         }
      }
      
      public function mailIcon(param1:Boolean) : void
      {
         if(mMailIcon)
         {
            mMailIcon.removeFromParent(true);
            mMailIcon.dispose();
         }
         this.mMailIcon = null;
         if(param1)
         {
            mMailIcon = GlobalFunction.getTagPopTip(1,false);
            mMailIcon.x = mBtn_mail.x + mBtn_mail.width / 2 + 10;
            mMailIcon.y = mBtn_mail.y + 5;
            _pop.addChild(mMailIcon);
         }
      }
      
      public function checkInIcon() : void
      {
         var _loc6_:Array = null;
         var _loc5_:Object = null;
         var _loc7_:Array = null;
         var _loc1_:int = 0;
         var _loc8_:Object = GlobalData.$mConfig_simple.check_in;
         if(_loc8_.open_status != 1)
         {
            return;
         }
         if(mCheckInIcon)
         {
            mCheckInIcon.removeFromParent(true);
            mCheckInIcon.dispose();
         }
         this.mCheckInIcon = null;
         var _loc4_:Object = GlobalData.$userData;
         var _loc2_:Object = _loc4_.attrs.check_in;
         var _loc3_:int = 0;
         if(_loc2_)
         {
            _loc6_ = _loc2_.had_check;
            if(_loc6_[0] != 1)
            {
               mCheckInIcon = GlobalFunction.getTagPopTip(1,false);
               mCheckInIcon.x = mBtn_checkin.x + 67;
               mCheckInIcon.y = mBtn_checkin.y + 72;
               _pop.addChild(mCheckInIcon);
               return;
            }
            _loc5_ = GlobalData.$mConfig_check_in;
            _loc7_ = _loc5_[_loc2_.m];
            if(_loc2_.n < _loc7_.length)
            {
               _loc1_ = int(_loc7_[_loc2_.n].vip_double);
            }
            else
            {
               _loc1_ = int(_loc7_[int(_loc2_.n) - 1].vip_double);
            }
            if(_loc6_[1] == 0 && int(_loc4_.vip_lv) >= _loc1_)
            {
               mCheckInIcon = GlobalFunction.getTagPopTip(1,false);
               mCheckInIcon.x = mBtn_checkin.x + 67;
               mCheckInIcon.y = mBtn_checkin.y + 72;
               _pop.addChild(mCheckInIcon);
               return;
            }
         }
      }
      
      public function awardIcon() : void
      {
         var _loc2_:Boolean = false;
         var _loc1_:int = PanelCenterTaskAward.checkTaskComplete();
         if(_loc1_ > 0)
         {
            _loc2_ = true;
         }
         if(mAwardIcon)
         {
            mAwardIcon.removeFromParent(true);
            mAwardIcon.dispose();
         }
         this.mAwardIcon = null;
         if(_loc2_)
         {
            mAwardIcon = GlobalFunction.getTagPopTip(1,false);
            mAwardIcon.x = GlobalData.$mStageWidth - 44;
            mAwardIcon.y = mBtn_award.y + 65;
            _pop.addChild(mAwardIcon);
         }
      }
      
      public function getSoulIcon(param1:Boolean) : void
      {
         if(mGetSoulIcon)
         {
            mGetSoulIcon.removeFromParent(true);
            mGetSoulIcon.dispose();
         }
         this.mGetSoulIcon = null;
         if(GlobalData.$userData.lv >= GlobalFunction.checkGameFunIsOpenByType("center_scence"))
         {
            if(param1)
            {
               mGetSoulIcon = GlobalFunction.getTagPopTip(1,false);
               mGetSoulIcon.x = GlobalData.$mStageWidth / 2 + 187;
               if(MainConfig.$ispentaKill)
               {
                  mGetSoulIcon.x = GlobalData.$mStageWidth / 2 + 147;
               }
               mGetSoulIcon.y = GlobalData.$mStageHeight / 2 - 140;
               _pop.addChild(mGetSoulIcon);
            }
         }
      }
      
      public function clearByManual() : void
      {
         closeTeamPresets();
         GlobalData.$mEventDispatcher.removeEventListener("update_team_power",onUpdateHomeTeamStats);
         if(mPanelTeamSet)
         {
            mPanelTeamSet.removeTick();
            mPanelTeamSet.removeFromParent(true);
            mPanelTeamSet.dispose();
         }
         removeEventListener("enterFrame",onENTER_FRAME_tag);
         mPanelTeamSet = null;
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         closeTeamPresets();
         mPanelGeneration += 1;
         GlobalData.$mEventDispatcher.removeEventListener("update_team_power",onUpdateHomeTeamStats);
         if(mPanelTeamSet)
         {
            mPanelTeamSet.removeTick();
         }
         TimeManager.instance().unregister("panelbosstime");
         GlobalData.$mGameClassObject.setBgImg("png_bg_ui");
         removeEventListener("enterFrame",onENTER_FRAME_tag);
         GlobalData.$mEventDispatcher.removeEventListener("update_check_in",checkInIcon);
         GlobalData.$mEventDispatcher.removeEventListener("update_chat",update_chat);
         GlobalData.$mEventDispatcher.removeEventListener("update_chat_server",resetChatIcon);
      }
      
      private function presetText(parent:Sprite, text:String, x:Number, y:Number, w:int, h:int, size:int = 18, color:uint = 16777215) : void
      {
         var label:LOL_TextField = new LOL_TextField(text,w,h);
         label.x = x;
         label.y = y;
         label.fontSize = size;
         label.fontColor = color;
         label.touchable = false;
         parent.addChild(label);
      }

      private function presetPending() : Boolean
      {
         var methods:Array = ["user.fix_team","user.equip_dress","user.team_preset_save","user.team_preset_load","user.team_preset_delete"];
         for each(var method:String in methods)
         {
            if(SendAndSelect.checkRepeat(method,"")) return true;
         }
         return false;
      }

      private function openTeamPresets(event:Event) : void
      {
         if(mPresetPopup || GlobalData.$mGameClassObject.isPopUp_Open()) return;
         if(GlobalData.$isForceGuide)
         {
            GlobalFunction.popAlert("阵容预设","完成新手引导后可保存阵容。");
            return;
         }
         mPresetGeneration++;
         mPresetBusy = false;
         mPresetNotice = "保存会覆盖该槽位；载入同步恢复英雄、装备和德诺阵。";
         mPresetPopup = new Sprite();
         var background:Quad = new Quad(600,690,1449514);
         mPresetPopup.addChild(background);
         var header:Quad = new Quad(600,62,2569029);
         header.touchable = false;
         mPresetPopup.addChild(header);
         presetText(mPresetPopup,"阵容预设",20,12,320,38,26,16766464);
         var close:LOL_Scale9Button = new LOL_Scale9Button("关闭",72,34,"UI_btn_enterGame_0_0000");
         close.x = 508;
         close.y = 15;
         close.addEventListener("triggered",closeTeamPresets);
         mPresetPopup.addChild(close);
         mPresetRows = new Sprite();
         mPresetPopup.addChild(mPresetRows);
         var scale:Number = Math.min(1,(GlobalData.$mStageWidth-24)/600,(GlobalData.$mStageHeight-72)/690);
         mPresetPopup.scaleX = mPresetPopup.scaleY = scale;
         mPresetPopup.addEventListener("removedFromStage",onPresetPopupRemoved);
         renderTeamPresets();
         GlobalData.$mGameClassObject.openPopUp(mPresetPopup);
      }

      private function closeTeamPresets(event:Event = null) : void
      {
         if(mPresetPopup && mPresetPopup.stage) GlobalData.$mGameClassObject.closePopUp();
      }

      private function onPresetPopupRemoved(event:Event) : void
      {
         // Child removals during a redraw must not invalidate the popup.
         if(event.target != mPresetPopup) return;
         SendAndSelect.$SendServiceAMFDispatcher.removeEventListener("error_broadcast",onPresetError);
         mPresetGeneration++;
         mPresetPopup = null;
         mPresetRows = null;
         mPresetBusy = false;
         mPresetActionID = "";
      }

      private function presetButton(parent:Sprite, label:String, command:String, x:int, y:int, enabled:Boolean) : void
      {
         var button:LOL_Scale9Button = new LOL_Scale9Button(label,72,30,"UI_btn_enterGame_0_0000");
         button.name = command;
         button.x = x;
         button.y = y;
         button.enabled = enabled;
         button.addEventListener("triggered",onPresetCommand);
         parent.addChild(button);
      }

      private function renderTeamPresets() : void
      {
         if(!mPresetRows || !GlobalData.$userData) return;
         mPresetRows.removeChildren(0,-1,true);
         var saved:Array = GlobalData.$userData.attrs.team_presets as Array;
         for(var i:int = 0; i < 4; i++)
         {
            var preset:Object = saved && i < saved.length ? saved[i] : null;
            var row:Sprite = new Sprite();
            row.x = 14;
            row.y = 76 + i * 138;
            var bg:Quad = new Quad(572,130,i % 2 == 0 ? 2175290 : 1846063);
            bg.touchable = false;
            row.addChild(bg);
            mPresetRows.addChild(row);
            presetText(row,"阵容"+(i+1),10,2,84,28,20,16766464);
            var equipmentCount:int = 0;
            var dnCount:int = 0;
            if(preset)
            {
               for each(var group:Array in preset.as_equips)
                  for each(var eqid:* in group) if(eqid) equipmentCount++;
               for each(var binding:* in preset.dn_bindings) if(binding) dnCount++;
            }
            presetText(row,preset ? "装备 "+equipmentCount+"  ·  德诺阵 "+dnCount : "尚未保存",94,3,240,26,15,11978439);
            presetButton(row,preset ? "覆盖保存" : "保存当前","save:"+(i+1),336,2,!mPresetBusy);
            presetButton(row,"载入","load:"+(i+1),414,2,preset != null && !mPresetBusy);
            presetButton(row,"清空","delete:"+(i+1),492,2,preset != null && !mPresetBusy);
            for(var j:int = 0; j < 5; j++)
            {
               var hero:Object = preset && preset.preview && j < preset.preview.length ? preset.preview[j] : null;
               var x:int = 12 + j * 112;
               var frame:Quad = new Quad(72,72,hero ? 4213081 : 1251098);
               frame.x = x+10;
               frame.y = 36;
               frame.touchable = false;
               row.addChild(frame);
               var name:String = "空位";
               if(hero)
               {
                  var owned:Object = GlobalData.$userData.avatars[hero.id];
                  var aid:String = owned && owned.aid ? String(owned.aid).split("|")[0] : String(hero.aid);
                  var cfg:Object = GlobalFunction.getAvatarCfg(aid);
                  var icon:Image = GlobalFunction.getAvatarIcon(cfg && cfg.res ? String(cfg.res) : aid);
                  icon.width = icon.height = 68;
                  icon.x = x+12;
                  icon.y = 38;
                  icon.alpha = owned ? 1 : 0.35;
                  row.addChild(icon);
                  name = owned && cfg ? String(cfg.name) : String(hero.name)+"（缺失）";
                  if(j == 0)
                  {
                     var captain:Quad = new Quad(42,20,15115822);
                     captain.x = x+10;
                     captain.y = 36;
                     captain.touchable = false;
                     row.addChild(captain);
                     presetText(row,"队长",x+13,36,38,20,14,1449514);
                  }
               }
               presetText(row,name,x,108,108,22,14,hero ? 16777215 : 8425111);
            }
         }
         presetText(mPresetRows,mPresetBusy ? "正在保存或载入，请稍候…" : mPresetNotice,22,635,556,40,16,11978439);
      }

      private function onPresetCommand(event:Event) : void
      {
         if(mPresetBusy) return;
         if(presetPending())
         {
            mPresetNotice = "配队操作尚未完成，请稍后重试。";
            renderTeamPresets();
            return;
         }
         var command:Array = String(event.currentTarget.name).split(":");
         var method:String = "user.team_preset_"+command[0];
         var slot:int = int(command[1]);
         var uid:String = String(GlobalData.$userData.uid);
         var generation:int = mPresetGeneration;
         var owner:PanelCenterMain = this;
         var params:Object = {"slot":slot};
         mPresetBusy = true;
         renderTeamPresets();
         SendAndSelect.$SendServiceAMFDispatcher.addEventListener("error_broadcast",onPresetError);
         SendAndSelect.sendAndSelectService(method,params,function(receipt:Object):void
         {
            if(!GlobalData.$userData || String(GlobalData.$userData.uid) != uid) return;
            if(method == "user.team_preset_load")
            {
               GlobalData.$tempTeamID = int(GlobalData.$userData.attrs.team_num);
               GlobalData.$tempTeam = GlobalData.$userData.team[GlobalData.$tempTeamID];
               GlobalFunction.formateTeamToObj();
               GlobalData.$tempTeamPowerTemp = GlobalFunction.getTeamPower(GlobalData.$userData.team[0]);
               GlobalData.$mEventDispatcher.dispatchEventWith("update_dn_team_ui");
               GlobalData.$mEventDispatcher.dispatchEventWith("update_team_power");
               GlobalData.$mEventDispatcher.dispatchEventWith("update_center_main_teamset");
            }
            if(generation != owner.mPresetGeneration || !owner.mPresetPopup) return;
            SendAndSelect.$SendServiceAMFDispatcher.removeEventListener("error_broadcast",owner.onPresetError);
            owner.mPresetBusy = false;
            owner.mPresetActionID = "";
            owner.mPresetNotice = "阵容"+slot+(command[0] == "save" ? "已保存。" : command[0] == "load" ? "已载入，英雄、装备和德诺阵已同步。" : "已清空。");
            owner.renderTeamPresets();
         });
         mPresetActionID = String(params.actionID);
      }

      private function onPresetError(event:NetEvent) : void
      {
         var error:Object = event.data;
         var receipt:Object = error && error.profile_receipt ? error.profile_receipt : error;
         if(!receipt || !receipt.params || String(receipt.params.actionID) != mPresetActionID) return;
         SendAndSelect.$SendServiceAMFDispatcher.removeEventListener("error_broadcast",onPresetError);
         mPresetBusy = false;
         mPresetActionID = "";
         mPresetNotice = error.profile_sync_error ? "服务器操作已返回，数据同步失败，请重新登录确认。" : "操作未完成，当前配队保持不变。";
         renderTeamPresets();
      }

      private function checkBoosTag() : void
      {
         var _loc1_:Array = GlobalData.$mConfig_simple.wager_avatar as Array;
         if(GlobalData.$userData.records.free_wager_count < _loc1_[15] && GlobalFunction.checkWagerTime(0) < 0 || GlobalFunction.checkWagerTime(1) < 0)
         {
            if(mTag_b)
            {
               mTag_b.removeFromParent(true);
               mTag_b = null;
            }
            mTag_b = GlobalFunction.getTagPopTip(1,false);
            mTag_b.x = mTxt_casino.x + mTxt_casino.width - 30;
            mTag_b.y = mTxt_casino.y - mTxt_casino.height + 30;
            this.addChild(mTag_b);
         }
         else if(mTag_b)
         {
            mTag_b.removeFromParent(true);
            mTag_b = null;
         }
      }
      
      override public function update() : void
      {
         var _loc2_:Tween = null;
         var _loc9_:Object = null;
         var _loc14_:LOL_Button = null;
         var _loc19_:Image = null;
         var _loc16_:ColorMatrixFilter = null;
         var _loc3_:MovieClip = null;
         var _loc12_:Array = null;
         var _loc13_:Array = null;
         var _loc5_:MovieClip = null;
         var _loc1_:Date = null;
         GlobalData.$mEventDispatcher.addEventListener("update_team_power",onUpdateHomeTeamStats);
         mPanelTeamSet.update();
         TimeManager.instance().regsiter("panelbosstime",time_Tick);
         getSoulIcon(PanelCenterSoul.checkSoulIcon().x);
         GlobalData.$mGameClassObject.setBgImg("png_bg_center_main_");
         mRec_bg = GlobalData.$mGameClassObject.mBgImg.getBounds(this);
         var _loc6_:Array = [mBtn_casino,mBtn_equip,mBtn_avatar,mBtn_science,mBtn_alchemy];
         var _loc7_:Array = [mTxt_casino,mTxt_equip,mTxt_avatar,mTxt_science,mTxt_alchemy];
         var _loc15_:Array = [getConstProperty("center_casino",ConfigManager.POS),getConstProperty("center_equip",ConfigManager.POS),getConstProperty("center_main_avatar",ConfigManager.POS),getConstProperty("center_scence",ConfigManager.POS),getConstProperty("center_alchemy",ConfigManager.POS)];
         if(GlobalFunction.checkGameFunIsOpenByType("equip_fun_change") < 0)
         {
            if(mImg_equip)
            {
               mImg_equip.removeFromParent(true);
               mImg_equip = null;
            }
            mImg_equip = GlobalFunction.createImage("UI_equip_bg",true);
            mImg_equip.touchable = false;
            mImg_equip.x = _loc15_[1].x - 15;
            mImg_equip.y = int(GlobalData.$center_height / 2 + 19);
            mBox_btns.addChildAt(mImg_equip,1);
            mTxt_equip.visible = true;
            if(MainConfig.$ispentaKill)
            {
               if(mUI_pool_IMG)
               {
                  Starling.juggler.removeTweens(mUI_pool_IMG);
                  mUI_pool_IMG.removeFromParent(true);
                  mUI_pool_IMG = null;
               }
               mUI_pool_IMG = GlobalFunction.createImage("ui_pool_0000");
               mUI_pool_IMG.alpha = 0;
               mUI_pool_IMG.x = mImg_equip.x + 83;
               mUI_pool_IMG.y = mImg_equip.y + 122;
               addChild(mUI_pool_IMG);
               _loc2_ = new Tween(mUI_pool_IMG,1);
               _loc2_.fadeTo(1);
               _loc2_.repeatCount = 0;
               _loc2_.reverse = true;
               Starling.juggler.add(_loc2_);
               if(mUI_light_MC)
               {
                  mUI_light_MC.removeFromParent(true);
                  mUI_light_MC = null;
               }
               mUI_light_MC = DisplayTools.newMc("ui_light_",0,0,10);
               mUI_light_MC.x = _loc15_[1].x + 15;
               mUI_light_MC.y = int(GlobalData.$center_height / 2 + 19 + 40);
               mUI_light_MC.loop = true;
               Starling.juggler.add(mUI_light_MC);
               mUI_light_MC.play();
               addChild(mUI_light_MC);
            }
         }
         var _loc18_:Object = GlobalData.$mConfig_simple.equip_alchemy;
         if(GlobalFunction.checkGameFunIsOpenByType("center_alchemy") < 0 && _loc18_.open_status == 1)
         {
            if(mImg_alchemy)
            {
               mImg_alchemy.removeFromParent(true);
               mImg_alchemy = null;
            }
            mImg_alchemy = GlobalFunction.createImage("UI_alchemy_bg",true);
            mImg_alchemy.touchable = false;
            mImg_alchemy.x = _loc15_[4].x - 15;
            mImg_alchemy.y = int(GlobalData.$center_height / 2 - mImg_alchemy.height + (MainConfig.$ispentaKill ? 40 : 25));
            mBox_btns.addChildAt(mImg_alchemy,1);
            mTxt_alchemy.visible = true;
            if(MainConfig.$ispentaKill)
            {
               if(mUI_ball_MC)
               {
                  Starling.juggler.remove(mUI_ball_MC);
                  mUI_ball_MC.removeFromParent(true);
                  mUI_ball_MC = null;
               }
               mUI_ball_MC = DisplayTools.newMc("ui_alchemy_",0,0,10);
               mUI_ball_MC.x = mImg_alchemy.x + 75;
               mUI_ball_MC.y = mImg_alchemy.y + 51;
               mUI_ball_MC.loop = true;
               Starling.juggler.add(mUI_ball_MC);
               mUI_ball_MC.play();
               addChildAt(mUI_ball_MC,1);
            }
         }
         var _loc17_:int = GlobalFunction.checkGameFunIsOpenByType("center_scence");
         if(_loc17_ == -1)
         {
            _loc9_ = getConstProperty("center_scence_offXY",ConfigManager.POS);
            if(!MainConfig.$ispentaKill)
            {
               if(mImg_science)
               {
                  mImg_science.removeFromParent(true);
                  mImg_science = null;
               }
               mImg_science = GlobalFunction.createImage("UI_shop_bg",true);
               mImg_science.name = "center_scence_offXY";
               mImg_science.touchable = false;
               mImg_science.x = _loc15_[3].x + 40 + _loc9_["x"];
               mImg_science.y = int(GlobalData.$center_height / 2 - mImg_science.height + 25 + _loc9_["y"]);
               mBox_btns.addChildAt(mImg_science,1);
               mTxt_science.visible = true;
            }
            else
            {
               if(mScience_MC)
               {
                  Starling.juggler.remove(mScience_MC);
                  mScience_MC.removeFromParent(true);
                  mScience_MC = null;
               }
               mScience_MC = DisplayTools.newMc("science_mc_",0,0,4);
               mScience_MC.name = "center_scence_offXY";
               mScience_MC.touchable = false;
               mScience_MC.x = _loc15_[3].x + 50 + _loc9_["x"] + mScience_MC.width * 0.5;
               mScience_MC.y = int(GlobalData.$center_height / 2 - mScience_MC.height * 0.5 + 25 + _loc9_["y"]);
               mScience_MC.loop = true;
               mBox_btns.addChildAt(mScience_MC,1);
               Starling.juggler.add(mScience_MC);
               mScience_MC.play();
               mTxt_science.visible = true;
            }
         }
         var _loc11_:uint = 0;
         var _loc10_:uint = _loc6_.length;
         _loc11_ = 0;
         while(_loc11_ < _loc10_)
         {
            _loc14_ = _loc6_[_loc11_] as LOL_Button;
            _loc14_.x = mRec_bg.x + _loc15_[_loc11_].x;
            _loc14_.y = mRec_bg.y + _loc15_[_loc11_].y;
            _loc19_ = _loc7_[_loc11_] as Image;
            _loc19_.touchable = false;
            _loc19_.x = int(_loc14_.x + (_loc14_.width - _loc19_.width) * 0.5);
            _loc19_.y = int(_loc14_.y + (_loc14_.height - _loc19_.height));
            if(MainConfig.$ispentaKill)
            {
               if(_loc14_.name == "center_alchemy")
               {
                  _loc19_.x -= 20;
               }
            }
            _loc11_++;
         }
         if(mEditBg && mEdit)
         {
            if(GlobalData.$userData.lv < GlobalData.$mConfig_simple.dn["1"][2])
            {
               _loc16_ = new ColorMatrixFilter();
               _loc16_.adjustBrightness(-0.2);
               _loc16_.adjustContrast(-0.2);
               _loc16_.adjustSaturation(-0.8);
               mEditBg.filter = mEdit.filter = _loc16_;
            }
            else
            {
               mEditBg.filter = mEdit.filter = null;
            }
         }
         if(mClip_casino)
         {
            mClip_casino.removeFromParent(true);
            mClip_casino = null;
         }
         mClip_casino = GlobalFunction.createImage("UI_main_clip_casino_0_0000");
         mClip_casino.touchable = false;
         mClip_casino.pivotX = mClip_casino.width * 0.5;
         mClip_casino.pivotY = mClip_casino.height;
         mClip_casino.x = _loc15_[0].x + _loc6_[0].width * 0.5;
         mClip_casino.y = mClip_casino_Y = mTxt_casino.y - 90;
         addChild(mClip_casino);
         if(MainConfig.$ispentaKill)
         {
            if(mUI_card_MC)
            {
               mUI_card_MC.removeFromParent(true);
               mUI_card_MC = null;
            }
            mUI_card_MC = DisplayTools.newMc("ui_card_",0,0,10);
            mUI_card_MC.x = _loc15_[0].x + _loc6_[0].width * 0.5 + 148;
            mUI_card_MC.y = mTxt_casino.y - 55;
            mUI_card_MC.loop = true;
            Starling.juggler.add(mUI_card_MC);
            mUI_card_MC.play();
            addChild(mUI_card_MC);
            if(mUI_water_MC)
            {
               mUI_water_MC.removeFromParent(true);
               mUI_water_MC = null;
            }
            mUI_water_MC = DisplayTools.newMc("ui_water_",0,0,10);
            mUI_water_MC.x = _loc15_[0].x + _loc6_[0].width * 0.5 - 111;
            mUI_water_MC.y = mTxt_casino.y - 30;
            mUI_water_MC.loop = true;
            Starling.juggler.add(mUI_water_MC);
            mUI_water_MC.play();
            addChild(mUI_water_MC);
            while(mArr_flag_.length > 0)
            {
               _loc3_ = mArr_flag_.pop();
               Starling.juggler.remove(_loc3_);
               _loc3_.removeFromParent(true);
               _loc3_ = null;
            }
            _loc12_ = [-2,48,113];
            _loc13_ = [-69,-43,-75];
            _loc11_ = 0;
            while(_loc11_ < 3)
            {
               _loc5_ = DisplayTools.newMc("ui_flag_",0,0,6 + _loc11_ * 2);
               _loc5_.x = mTxt_avatar.x + _loc12_[_loc11_] - 2;
               _loc5_.y = mTxt_avatar.y + _loc13_[_loc11_];
               _loc5_.loop = true;
               Starling.juggler.add(_loc5_);
               _loc5_.play();
               mArr_flag_.push(_loc5_);
               mBox_btns.addChild(_loc5_);
               _loc11_++;
            }
         }
         checkBoosTag();
         checkInIcon();
         if(GlobalData.$currentGuide)
         {
            return;
         }
         var _loc8_:String = GuideTools.checkGuideType();
         if(_loc8_ == "1")
         {
            LayoutUIAnimation.getOnlyExample().addArrowhead(159,895,100);
         }
         else if(_loc8_ == "2")
         {
            LayoutUIAnimation.getOnlyExample().addArrowhead(159,895,100);
         }
         else if(_loc8_ == "3")
         {
            LayoutUIAnimation.getOnlyExample().addArrowhead(64,171,0);
         }
         else if(_loc8_ == "4")
         {
            LayoutUIAnimation.getOnlyExample().addArrowhead(529,583,40);
         }
         else if(_loc8_ == "5")
         {
            if(GuideTools.getTeamNowNum() >= 3)
            {
               LayoutUIAnimation.getOnlyExample().addArrowhead(267,895,100);
            }
         }
         else if(_loc8_ == "6")
         {
            LayoutUIAnimation.getOnlyExample().addArrowhead(535,588,40);
         }
         else if(_loc8_ == "7")
         {
            LayoutUIAnimation.getOnlyExample().addArrowhead(159,895,100);
         }
         var _loc4_:String = GuideTools.checkGuildFight();
         if(_loc4_ == "10")
         {
            currLunAndJie();
            _now = SendAndSelect.$systemTimer_nowSecond * 1000;
            _now = Tools.getServerNowTimeDate(_now).time;
            _loc1_ = new Date();
            _loc1_.setTime(_now);
            _loc11_ = 0;
            while(_loc11_ < userTime.memberTimeArr.length)
            {
               if(_loc1_.time > (userTime.memberTimeArr[_loc11_].start as Date).time && _loc1_.time < (userTime.memberTimeArr[_loc11_].end as Date).time)
               {
                  LayoutUIAnimation.getOnlyExample().addArrowhead(60,776,100);
               }
               _loc11_++;
            }
            if(_now > (userTime.FightStartTime as Date).time && _now < (userTime.guildBMendTime as Date).time)
            {
               LayoutUIAnimation.getOnlyExample().addArrowhead(60,776,100);
            }
         }
         showRewardList();
         if(!hasEventListener("enterFrame"))
         {
            addEventListener("enterFrame",onENTER_FRAME_tag);
         }
         if(!GlobalData.$mEventDispatcher.hasEventListener("update_check_in"))
         {
            GlobalData.$mEventDispatcher.addEventListener("update_check_in",checkInIcon);
         }
         if(!GlobalData.$mEventDispatcher.hasEventListener("update_chat"))
         {
            GlobalData.$mEventDispatcher.addEventListener("update_chat",update_chat);
         }
         if(!GlobalData.$mEventDispatcher.hasEventListener("update_chat_server"))
         {
            GlobalData.$mEventDispatcher.addEventListener("update_chat_server",resetChatIcon);
         }
         if(GlobalFunction.checkIOSvip() && check_chat_open())
         {
            chatIcon(GlobalData.$userData.attrs.chat_private);
         }
      }
      
      private function getTimeOutSchedule() : Object
      {
         var _loc2_:Number = SendAndSelect.$systemTimer_nowSecond * 1000;
         var _loc5_:Number = (GlobalData.$mGuild_simple.the_guild_pvp.time.start_time as Date).time;
         var _loc1_:Number = _loc5_ + _cfg.cycle * 1000 * 60;
         var _loc4_:Boolean = false;
         if(_loc2_ >= _loc5_ && _loc2_ < _loc1_)
         {
            _loc4_ = true;
         }
         var _loc3_:Number = _loc1_ - _loc2_;
         return {
            "can":_loc4_,
            "end":_loc3_ * 0.001
         };
      }
      
      private function currLunAndJie() : Object
      {
         var _loc23_:* = 0;
         var _loc21_:* = 0;
         var _loc5_:Object = null;
         var _loc2_:Number = NaN;
         var _loc18_:Date = null;
         var _loc9_:Number = NaN;
         var _loc4_:Date = null;
         var _loc11_:Number = NaN;
         var _loc10_:Number = NaN;
         var _loc8_:Number = NaN;
         var _loc6_:Number = NaN;
         var _loc17_:Number = NaN;
         var _loc16_:Number = NaN;
         var _loc15_:Date = null;
         var _loc1_:Object = getTimeOutSchedule();
         var _loc3_:Date = new Date();
         _loc3_.setTime((GlobalData.$mGuild_simple.the_guild_pvp.time.start_time as Date).time + GlobalConfig.HOURS_8_MS);
         _now = SendAndSelect.$systemTimer_nowSecond * 1000;
         _now = Tools.getServerNowTimeDate(_now).time;
         var _loc25_:Number = (_now - _loc3_.time) % (GlobalData.$mGuild_simple.the_guild_pvp.time.cycle * 1000 * 60);
         var _loc20_:Date = new Date();
         _loc20_.setTime(_now - _loc25_);
         _cfg.start_time = _loc20_;
         var _loc24_:Array = [];
         var _loc12_:int = 0;
         var _loc13_:int = 0;
         var _loc26_:Array = [];
         var _loc27_:Date = new Date();
         _loc27_.setTime((_cfg.start_time as Date).time + (_cfg.guild_sign_up + _cfg.match + _cfg.member_sign_up * 7 + _cfg.get_ready * 7 + _cfg.fight * 7 + _cfg.interval * 6) * 1000 * 60);
         var _loc7_:Date = new Date();
         _loc7_.setTime((_cfg.start_time as Date).time + _cfg.guild_sign_up * 1000 * 60);
         _loc23_ = 0;
         while(_loc23_ < 7)
         {
            _loc21_ = uint(_loc23_ ? 1 : 0);
            _loc5_ = {};
            _loc2_ = (_cfg.start_time as Date).time + (_cfg.guild_sign_up * _loc21_ + _cfg.match * _loc21_ + _cfg.member_sign_up * _loc23_ + _cfg.get_ready * _loc23_ + _cfg.fight * _loc23_ + _cfg.interval * _loc23_) * 1000 * 60;
            _loc18_ = new Date();
            _loc18_.setTime((_cfg.start_time as Date).time + (_cfg.guild_sign_up + _cfg.match + _cfg.member_sign_up * _loc23_ + _cfg.get_ready * _loc23_ + _cfg.fight * _loc23_ + _cfg.interval * _loc23_) * 1000 * 60);
            _loc5_.start = _loc18_;
            _loc18_ = null;
            _loc18_ = new Date();
            _loc18_.setTime((_cfg.start_time as Date).time + (_cfg.guild_sign_up + _cfg.match + _cfg.member_sign_up * (_loc23_ + 1) + _cfg.get_ready * _loc23_ + _cfg.fight * _loc23_ + _cfg.interval * _loc23_) * 1000 * 60);
            _loc5_.end = _loc18_;
            _loc26_.push(_loc5_);
            _loc9_ = (_cfg.start_time as Date).time + (_cfg.guild_sign_up * _loc21_ + _cfg.match * _loc21_ + _cfg.member_sign_up * _loc23_ + _cfg.get_ready * _loc23_ + _cfg.fight * _loc23_ + _cfg.interval * _loc23_) * 1000 * 60;
            _loc4_ = new Date();
            _loc4_.setTime(_loc9_);
            _loc24_.push(_loc4_);
            _loc23_++;
         }
         userTime.FightStartTime = _cfg.start_time;
         userTime.guildBMendTime = _loc7_;
         userTime.memberTimeArr = _loc26_;
         userTime.FightOverTime = _loc27_;
         var _loc14_:Date = new Date();
         _loc14_.setTime((_cfg.start_time as Date).time + _cfg.cycle * 1000 * 60);
         userTime.NextGameTime = _loc14_;
         _loc23_ = 0;
         while(_loc23_ < 7)
         {
            if(!_loc24_[_loc23_ + 1])
            {
               if((_loc24_[_loc23_] as Date).time < _now && (_loc24_[_loc23_] as Date).time + (_cfg.member_sign_up + _cfg.get_ready + _cfg.fight) * 1000 * 60 > _now)
               {
                  _loc12_ = _loc23_ + 1;
               }
               break;
            }
            if((_loc24_[_loc23_] as Date).time < _now && (_loc24_[_loc23_ + 1] as Date).time > _now)
            {
               _loc12_ = _loc23_ + 1;
            }
            _loc23_++;
         }
         var _loc19_:uint = _loc12_ == 1 ? 6 : (_loc12_ == 7 ? 3 : (_loc12_ == 0 ? 0 : 4));
         var _loc22_:Array = [];
         if(_loc19_ == 6)
         {
            _loc11_ = (_loc24_[_loc12_ - 1] as Date).time;
            _loc10_ = (_loc24_[_loc12_ - 1] as Date).time + _cfg.guild_sign_up * 1000 * 60;
            _loc8_ = (_loc24_[_loc12_ - 1] as Date).time + (_cfg.guild_sign_up + _cfg.match) * 1000 * 60;
            _loc6_ = (_loc24_[_loc12_ - 1] as Date).time + (_cfg.guild_sign_up + _cfg.match + _cfg.member_sign_up) * 1000 * 60;
            _loc17_ = (_loc24_[_loc12_ - 1] as Date).time + (_cfg.guild_sign_up + _cfg.match + _cfg.member_sign_up + _cfg.get_ready) * 1000 * 60;
            _loc16_ = (_loc24_[_loc12_ - 1] as Date).time + (_cfg.guild_sign_up + _cfg.match + _cfg.member_sign_up + _cfg.get_ready + _cfg.fight) * 1000 * 60;
            _loc22_.push(_loc11_);
            _loc22_.push(_loc10_);
            _loc22_.push(_loc8_);
            _loc22_.push(_loc6_);
            _loc22_.push(_loc17_);
            _loc22_.push(_loc16_);
         }
         if(_loc19_ == 4)
         {
            _loc8_ = (_loc24_[_loc12_ - 1] as Date).time;
            _loc6_ = (_loc24_[_loc12_ - 1] as Date).time + _cfg.member_sign_up * 1000 * 60;
            _loc17_ = (_loc24_[_loc12_ - 1] as Date).time + (_cfg.member_sign_up + _cfg.get_ready) * 1000 * 60;
            _loc16_ = (_loc24_[_loc12_ - 1] as Date).time + (_cfg.member_sign_up + _cfg.get_ready + _cfg.fight) * 1000 * 60;
            _loc22_.push(_loc8_);
            _loc22_.push(_loc6_);
            _loc22_.push(_loc17_);
            _loc22_.push(_loc16_);
         }
         if(_loc19_ == 3)
         {
            _loc8_ = (_loc24_[_loc12_ - 1] as Date).time;
            _loc6_ = (_loc24_[_loc12_ - 1] as Date).time + _cfg.member_sign_up * 1000 * 60;
            _loc17_ = (_loc24_[_loc12_ - 1] as Date).time + (_cfg.member_sign_up + _cfg.get_ready) * 1000 * 60;
            _loc22_.push(_loc8_);
            _loc22_.push(_loc6_);
            _loc22_.push(_loc17_);
         }
         _loc23_ = 0;
         while(_loc23_ < _loc19_)
         {
            _loc4_ = new Date();
            _loc4_.setTime(_loc22_[_loc23_]);
            if(!_loc22_[_loc23_ + 1])
            {
               if(_loc19_ == 6 || _loc19_ == 4)
               {
                  _loc15_.setTime(_loc16_ + _cfg.interval * 1000 * 60);
                  if(_loc4_.time < _now && _loc15_.time > _now)
                  {
                     _loc13_ = 6;
                  }
               }
               if(_loc19_ == 3)
               {
                  _loc15_.setTime(_loc17_ + _cfg.fight * 1000 * 60);
                  if(_loc4_.time < _now && _loc15_.time > _now)
                  {
                     _loc13_ = 5;
                  }
               }
               break;
            }
            _loc15_ = new Date();
            _loc15_.setTime(_loc22_[_loc23_ + 1]);
            if(_loc4_.time < _now && _loc15_.time > _now)
            {
               if(_loc19_ == 3 || _loc19_ == 4)
               {
                  _loc13_ = _loc23_ + 3;
               }
               if(_loc19_ == 6)
               {
                  _loc13_ = _loc23_ + 1;
               }
            }
            _loc23_++;
         }
         return {
            "lun":_loc12_,
            "jie":_loc13_
         };
      }
      
      private function getNewStartTime() : Object
      {
         _cfg = {};
         var _loc2_:Object = GlobalData.$mGuild_simple.the_guild_pvp.time;
         _now = SendAndSelect.$systemTimer_nowSecond * 1000;
         var _loc4_:Date = _loc2_.start_time as Date;
         var _loc1_:Number = (_now - _loc4_.time) % (_loc2_.cycle * 1000 * 60);
         var _loc5_:Date = new Date();
         _loc5_.setTime(_now - _loc1_);
         var _loc3_:Object = {};
         _loc3_.start_time = _loc5_;
         _loc3_.cycle = _loc2_.cycle;
         _loc3_.guild_sign_up = _loc2_.guild_sign_up;
         _loc3_.match = _loc2_.match;
         _loc3_.member_sign_up = _loc2_.member_sign_up;
         _loc3_.get_ready = _loc2_.get_ready;
         _loc3_.fight = _loc2_.fight;
         _loc3_.interval = _loc2_.interval;
         return _loc3_;
      }
      
      private function time_Tick(param1:int) : void
      {
         checkBoosTag();
      }
      
      public function showRewardList() : void
      {
         if(GlobalData.$currentGuide)
         {
            return;
         }
         if(GuideMaster.getOnlyExample().hasGuideA)
         {
            return;
         }
         var _loc1_:Array = GlobalData.$userData.reward;
         if(_loc1_ == null || _loc1_.length == 0)
         {
            return;
         }
         GlobalFunction.showReward(_loc1_);
         GlobalData.$userData.reward = null;
      }
      
      private function onENTER_FRAME_tag(param1:EnterFrameEvent) : void
      {
         if(mClip_casino)
         {
            if(mClip_casino_timer < 360)
            {
               mClip_casino_timer += 10;
            }
            else
            {
               mClip_casino_timer = 0;
            }
            mClip_casino.y = mClip_casino_Y + Math.sin(deg2rad(mClip_casino_timer)) * 4;
         }
      }
      
      private function button_triggeredHandler(param1:Event) : void
      {
         var chatSocketManager:SocketManager;
         var _loc6_:int = 0;
         var _loc7_:int = 0;
         var _loc9_:Object = null;
         var _loc8_:int = 0;
         var _loc10_:Object = null;
         var _loc3_:Object = null;
         var _loc4_:int = 0;
         var _loc5_:LOL_Button = LOL_Button(param1.currentTarget);
         var _loc2_:Game = GlobalData.$mGameClassObject;
         if(_loc5_.name == "center_equip")
         {
            if(GlobalFunction.checkGameFunIsOpenByType("equip_fun_change") < 0)
            {
               GlobalData.$tempEquipFunId = 0;
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_change_base");
            }
            else
            {
               _show_id = GlobalData.$mConfig_simple.show_id[8];
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90126,GlobalFunction.checkGameFunIsOpenByType("equip_fun_change")),false,_show_id);
            }
         }
         else if(_loc5_.name == "UI_btn_superteam0000")
         {
            if(GlobalData.$userData.lv < GlobalData.$mConfig_simple.dn["1"][2])
            {
               _show_id = GlobalData.$mConfig_simple.show_id[8];
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90129,GlobalData.$mConfig_simple.dn["1"][2]),false,_show_id);
               return;
            }
            GlobalData.$tempTeamSelect = null;
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_change",false,false,"show_type_dn");
         }
         else if(_loc5_.name == "center_casino")
         {
            PanelCenterShopVIP.$selectType = 0;
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_shopAndVIP");
         }
         else if(_loc5_.name == "center_sell")
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_social_main_avatar");
         }
         else if(_loc5_.name == "center_better")
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_social_main_avatar");
         }
         else if(_loc5_.name == "center_starup")
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_social_main_avatar");
         }
         else if(_loc5_.name == "center_award")
         {
            gotoOpenActivityPanel();
         }
         else if(_loc5_.name == "center_rune")
         {
            _loc7_ = GlobalFunction.checkGameFunIsOpenByType("equip_fun_magic");
            if(_loc7_ < 0)
            {
               // The center rune entrance selects equipment enchantment, where
               // the independent elemental-rune upgrade button is available.
               GlobalData.$tempEquipFunId = 4;
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_change_base");
            }
            else
            {
               _show_id = GlobalData.$mConfig_simple.show_id[8];
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90129,_loc7_),false,_show_id);
            }
         }
         else if(_loc5_.name == "center_scence")
         {
            _loc7_ = GlobalFunction.checkGameFunIsOpenByType("center_scence");
            if(_loc7_ != -1)
            {
               _show_id = GlobalData.$mConfig_simple.show_id[8];
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90129,_loc7_),false,_show_id);
            }
            else
            {
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_gold_metallurgy");
            }
         }
         else if(_loc5_.name == "center_checkin")
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_everydaysign",false,true);
         }
         else if(_loc5_.name == "center_alchemy")
         {
            _loc9_ = GlobalData.$mConfig_simple.equip_alchemy;
            if(GlobalFunction.checkGameFunIsOpenByType("center_alchemy") < 0 && _loc9_.open_status == 1)
            {
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_panel_alchemy");
            }
            else if(_loc9_.open_status == 0)
            {
               GlobalFunction.popError(GlobalLanguageStr.getStr(90537),false,_show_id);
            }
            else
            {
               _show_id = GlobalData.$mConfig_simple.show_id[8];
               _loc8_ = int(GlobalData.$mConfig_simple.start_lv[20]);
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90129,_loc8_),false,_show_id);
            }
         }
         else if(_loc5_.name == "center_main_avatar")
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_social_main_avatar");
         }
         else if(_loc5_.name == "center_social")
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_social");
         }
         else if(_loc5_.name == "center_mail")
         {
            PanelSocialMail.$canBackHome = true;
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_social_mail");
         }
         else if(_loc5_.name == "chatroom_btn")
         {
            if(GlobalData.$chatBtnTouchable)
            {
               GlobalData.$chatBtnTouchable = false;
               if(SocketManager.getInstance().connected())
               {
                  _loc10_ = {};
                  if(GlobalData.$userData.isGuildWarSaiCheng)
                  {
                     _loc10_.status = 1;
                  }
                  if(GlobalData.$userGuild.isChatPrivate)
                  {
                     _loc10_.status = 2;
                     _loc10_.data = GlobalData.$userGuild.ChatPrivate;
                  }
                  GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_chatroom_main",false,true,_loc10_);
               }
               else
               {
                  chatSocketManager = SocketManager.getInstance();
                  chatSocketManager.init();
               }
            }
         }
         else if(_loc5_.name == "center_guild")
         {
            _loc3_ = GlobalData.$mGuild_simple.the_guild_info;
            _loc4_ = int(_loc3_.user_level_limit);
            if(openStatus == 0)
            {
               GlobalFunction.popError(GlobalLanguageStr.getStr(90537),false,_show_id);
            }
            else if(_loc4_ > GlobalData.$userData.lv)
            {
               _show_id = GlobalData.$mConfig_simple.show_id[8];
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90129,_loc4_),false,_show_id);
            }
            else
            {
               var requestGeneration:int = mPanelGeneration;
               SendServiceAMFFun.send_user_associatione_is(function(response:Object):void
               {
                  if(requestGeneration != mPanelGeneration || !stage)
                  {
                     return;
                  }
                  onReFun(response);
               },{});
            }
         }
      }
      
      private function saveInfoToCameraRoll(param1:int, param2:String) : String
      {
         var _loc5_:BitmapData = new BitmapData(480,320);
         var _loc10_:TextFormat = new TextFormat();
         _loc10_.size = 36;
         var _loc3_:TextField = new TextField();
         _loc3_.defaultTextFormat = _loc10_;
         _loc3_.width = 480;
         _loc3_.text = "hha";
         _loc5_.draw(_loc3_);
         var _loc11_:TextField = new TextField();
         _loc11_.defaultTextFormat = _loc10_;
         _loc11_.text = "ID:" + param1;
         _loc11_.width = 480;
         var _loc8_:Matrix = new Matrix();
         _loc8_.ty = 60;
         _loc5_.draw(_loc11_,_loc8_);
         var _loc6_:TextField = new TextField();
         _loc6_.defaultTextFormat = _loc10_;
         _loc6_.text = "pp";
         _loc6_.width = 480;
         _loc8_.ty = 120;
         _loc5_.draw(_loc6_,_loc8_);
         var _loc4_:ByteArray = _loc5_.encode(_loc5_.rect,new PNGEncoderOptions());
         var _loc7_:File = File.applicationStorageDirectory.resolvePath("temp.png");
         var _loc9_:FileStream = new FileStream();
         _loc9_.open(_loc7_,"write");
         _loc9_.writeBytes(_loc4_);
         _loc9_.close();
         return _loc7_.nativePath;
      }
      
      private function onReFun(param1:Object) : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_guild",false,false,param1);
      }
   }
}

