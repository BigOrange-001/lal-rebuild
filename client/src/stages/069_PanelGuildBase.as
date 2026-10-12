package com.meng52.game.ui.screen
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.element.ItemGuild;
   import com.meng52.game.ui.element.ItemGuildPanel;
   import com.meng52.game.ui.element.ItemGuildResearch;
   import com.meng52.game.ui.element.ItemGuildShop;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.element.LOL_TextInput;
   import com.meng52.game.ui.element.LOL_TextPop;
   import com.meng52.game.ui.element.LOL_TimeStatus;
   import com.meng52.game.ui.stage.GuideTools;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.controls.ScrollContainer;
   import feathers.data.ListCollection;
   import feathers.display.Scale3Image;
   import feathers.display.Scale9Image;
   import feathers.layout.TiledRowsLayout;
   import feathers.layout.VerticalLayout;
   import feathers.textures.Scale9Textures;
   import flash.geom.Rectangle;
   import flash.utils.setTimeout;
   import starling.animation.Tween;
   import starling.core.Starling;
   import starling.display.DisplayObject;
   import starling.display.DisplayObjectContainer;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   
   public class PanelGuildBase extends PanelCenterMainAvatar
   {
      
      private static const FOUND_GUILD_L_BTN:String = "found_guild_l_btn";
      
      private static const FOUND_GUILD_G_BTN:String = "found_guild_g_btn";
      
      private static var listInfo:Array;
      
      private static const BTN_NAME_GUILD_DAY:String = "btn_name_guild_day";
      
      private static const BTN_NAME_GUILD_MANAGER:String = "btn_name_guild_manager";
      
      private static const BTN_NAME_GUILD_ATHER:String = "btn_name_guild_ather";
      
      private static const BTN_NAME_GUILD_ACTIVE:String = "btn_name_guild_active";
      
      public static var currGuildIndex:int = -1;
      
      private static const USUAL_TRADE_BTN:String = "usual_trade_btn";
      
      private static const SENIOR_TRADE_BTN:String = "senior_trade_btn";
      
      public static var m_scrollContainer:ScrollContainer;
      
      private var isSever:uint;
      
      private var GuildMessage:Object = {};
      
      private var userTime:Object = {};
      
      private var _bg1:Image;
      
      private var _bg2:Scale3Image;
      
      private var _bgFight:Image;
      
      private var _btn3:Sprite;
      
      private var _btnJoin:LOL_Button;
      
      private var _btnEstablish:LOL_Button;
      
      private var _btnSearch:LOL_Button;
      
      private var textfield:TextField;
      
      private var mBg_list:Scale9Image;
      
      private var btn:LOL_Scale9Button;
      
      private var m_input:LOL_TextInput;
      
      private var GuildInfo:Object;
      
      private var guildName:TextField;
      
      private var myInput:LOL_TextInput;
      
      private var guildTxT:TextField;
      
      private var guildImg:Image;
      
      private var guildAmendBtn:LOL_Scale9Button;
      
      private var foundMoneyTxT:TextField;
      
      private var tBtn:LOL_Button;
      
      private var foundGuildLBtn:LOL_Scale9Button;
      
      private var foundGuildGBtn:LOL_Scale9Button;
      
      private var guildNotice:TextFieldHtmlRenderer;
      
      private var moneyL:LOL_MutilTextFieldIcon;
      
      private var moneyGold:LOL_MutilTextFieldIcon;
      
      private var _radio1:LOL_Button;
      
      private var _radio2:LOL_Button;
      
      private var foundGuildBg:Image;
      
      private var foundGuildText:TextField;
      
      private var imageL:Scale9Image;
      
      private var imageGold:Scale9Image;
      
      private var once:Boolean = false;
      
      private var pay:int = -1;
      
      private var noGuild:TextField;
      
      private var mBg:Image;
      
      private var liveness:TextField;
      
      private var notice:TextFieldHtmlRenderer;
      
      private var playerLv:TextField;
      
      private var joinGuildsBtn:LOL_Scale9Button;
      
      private var img9:Scale9Image;
      
      private var findImg:Image;
      
      private var findText:TextField;
      
      private var findJoinLevel:int;
      
      private var findMemberCount:int;
      
      private var applyLengthMax:int;
      
      private var uGuildLv:int;
      
      private var icon:Image;
      
      private var guildID:TextField;
      
      private var guildNum:TextFieldHtmlRenderer;
      
      private var guildLV:TextField;
      
      private var _btnGuildDay:LOL_Scale9Button;
      
      private var _btnGuildManager:LOL_Scale9Button;
      
      private var _btnGuildAther:LOL_Scale9Button;
      
      private var _btnGuildActive:LOL_Scale9Button;
      
      private var guildId:int;
      
      private var guildDeclarationTxt:TextField;
      
      private var guildFight_Rank:LOL_Scale9Button;
      
      private var guildFight_Schedule:LOL_Scale9Button;
      
      private var guildFight_Reward:LOL_Scale9Button;
      
      private var guildFight_Chack:LOL_Scale9Button;
      
      private var objGuildFight:Object;
      
      private var btn_BOSS_HurtRanklist:LOL_Scale9Button;
      
      private var btn_BOSS_AllFight:LOL_Scale9Button;
      
      private var btn_BOSS_RewardPreview:LOL_Scale9Button;
      
      private var bgYuan:Image;
      
      private var bgYuanTween:Tween;
      
      private var eyes:Image;
      
      private var cfg:Object;
      
      private var _sp:Sprite;
      
      private var _avatar:Image;
      
      private var _textPop:LOL_TextPop;
      
      private var _bg:Scale9Image;
      
      private var txt_1:TextField;
      
      private var ShopGuildLV:TextField;
      
      private var mTimerT1:LOL_TimeStatus;
      
      private var guildShopBg:Image;
      
      private var guildShopCase:Scale9Image;
      
      private var guildShopRedCloth:Image;
      
      private var shopStrangeTxt:Image;
      
      private var shopGloryTxt:Image;
      
      private var _now:Number;
      
      private var _dis:DisplayObject;
      
      private var _dis1:DisplayObject;
      
      private var obj:Object;
      
      private var maxGuildMember:int;
      
      private var maxLengthApply:int;
      
      private var objBoss:Object;
      
      private var guildLvBoss:int;
      
      private var objPVP:Object;
      
      private var guildLvPVP:int;
      
      private var objShop:Object;
      
      private var guildLvShop:int;
      
      private var objStudy:Object;
      
      private var guildLvStudy:int;
      
      private var _data:Object;
      
      private var mBox_team:Sprite;
      
      private var spr:Sprite;
      
      private var title:Image;
      
      private var title1:Image;
      
      private var mTimerTBoss:LOL_TimeStatus;
      
      private var _spRule:Sprite;
      
      private var guildBattleRule:Sprite;
      
      private var guildShopRule:Sprite;
      
      private var touch:Touch;
      
      private var shopRule:TextField;
      
      private var ruleQuad:Quad;
      
      private var quad:Quad;
      
      private var iconImg:LOL_MutilTextFieldIcon;
      
      private var refreshBtn:LOL_Scale9Button;
      
      private var mTag_a:Sprite;
      
      private var guildBossRule:Sprite;
      
      private var lun:uint = 0;
      
      private var jie:uint = 0;
      
      private var _cfg:Object = getNewStartTime();
      
      private var handArr:Array;
      
      private var firstRefresh:int;
      
      private var eachTimeRefresh:int;
      
      private var foundGuild1:Scale9Image;
      
      private var foundGuild2:Scale9Image;
      
      private var foundGuild3:Scale9Image;
      
      private var downText:TextField;
      
      private var downText1:TextField;
      
      private var guildNameNum:int;
      
      private var mBox:Sprite;
      
      private var researchBg:Scale9Image;
      
      private var currentActive:LOL_MutilTextFieldIcon;
      
      private var researchRuleSp:Sprite;
      
      private var researchRuleText:TextField;
      
      private var researchRuleQuad:Quad;
      
      private var researchSkillBtn:LOL_Scale9Button;
      
      private var activeTrade:TextField;
      
      private var usualTradeBtn:LOL_Scale9Button;
      
      private var seniorTradeBtn:LOL_Scale9Button;
      
      private var btnSkill:LOL_Scale9Button;
      
      private var isFush:Boolean = false;
      
      public function PanelGuildBase(param1:Object)
      {
         _data = param1;
         super();
      }
      
      public static function checkBossIsOpen() : Object
      {
         var windows:Array = GlobalData.$mGuild_simple.guild_BOSS.open_times as Array;
         var now_ms:Number = Math.ceil(SendAndSelect.$systemTimer_nowSecond * 1000 + GlobalConfig.HOURS_8_MS);
         var duration_ms:Number = Number(GlobalData.$mGuild_simple.guild_BOSS.duration) * 60 * 1000;
         var today:Date = new Date();
         today.setTime(now_ms);
         var can:Boolean = false;
         var chosen_start:Number = -1;
         var chosen_end:Number = -1;
         var next_start:Number = Number.POSITIVE_INFINITY;
         var i:int = 0;
         var offset:int = 0;
         var row:Array = null;
         var base_start:Number = 0;
         var start:Number = 0;
         var end:Number = 0;
         var dt:Date = null;
         if(windows != null && duration_ms > 0)
         {
            i = 0;
            while(i < windows.length)
            {
               row = windows[i] as Array;
               if(row != null && row.length >= 2 && int(row[0]) >= 0 && int(row[0]) <= 23 && int(row[1]) >= 0 && int(row[1]) <= 59)
               {
                  dt = new Date();
                  dt.setTime(now_ms);
                  dt.setHours(int(row[0]),int(row[1]),0,0);
                  base_start = dt.time;
                  offset = -1;
                  while(offset <= 1)
                  {
                     start = base_start + offset * 86400000;
                     end = start + duration_ms;
                     if(now_ms >= start && now_ms < end)
                     {
                        can = true;
                        chosen_start = start;
                        chosen_end = end;
                        break;
                     }
                     if(start >= now_ms && start < next_start)
                     {
                        next_start = start;
                     }
                     offset++;
                  }
                  if(can)
                  {
                     break;
                  }
               }
               i++;
            }
         }
         if(!can && next_start < Number.POSITIVE_INFINITY)
         {
            chosen_start = next_start;
            chosen_end = next_start + duration_ms;
         }
         return {"can":can,"time_now":now_ms,"time_start":chosen_start,"time_end":chosen_end};
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         currGuildIndex = -1;
         this.removeEventListener("addedToStage",initializeHandler);
         GlobalData.$userData.isGuildWarSaiCheng = true;
         this.setTabBar([{
            "label":GlobalLanguageStr.getLanguageStr(97665),
            "indexID":0
         },{
            "label":GlobalLanguageStr.getLanguageStr(97667),
            "indexID":1
         },{
            "label":GlobalLanguageStr.getLanguageStr(97853),
            "indexID":2
         },{
            "label":GlobalLanguageStr.getLanguageStr(90749),
            "indexID":3
         },{
            "label":GlobalLanguageStr.getLanguageStr(90776),
            "indexID":4
         }],tabBar_Change,tabBar_CREATION_COMPLETE,128,60,null,true);
         this.mTabBar.y = 17;
         _bg1 = getImg_headBg(-50);
         addChildAt(_bg1,0);
         _bg2 = this.getImg3_info();
         _bg2.y = mTabBar.y + 55;
         _bg2.height = 80;
         addChildAt(_bg2,1);
         mBg_list = GlobalFunction.createScale9Image("UI_guild_bg_1_0000",638,GlobalData.$mStageHeight - 207 - 121,new Rectangle(180,147,20,20));
         mBg_list.x = int((GlobalData.$mStageWidth - mBg_list.width) * 0.5);
         mBg_list.y = _bg2.y + _bg2.height;
         addChildAt(mBg_list,1);
         var _loc2_:Array = [];
         _loc2_.push({"label":GlobalLanguageStr.getLanguageStr(97677)});
         _loc2_.push({"label":GlobalLanguageStr.getLanguageStr(97673)});
         _loc2_.push({"label":GlobalLanguageStr.getLanguageStr(97678)});
         this.setRadioBar(_loc2_,radioBar_Change,radioBar_Complete,125);
         this.mRadioBar.x = 20;
         this.mRadioBar.y = _bg2.y + 10;
         cfg = GlobalData.$mGuild_simple.the_guild_info;
         guildNameNum = cfg.guild_name;
         GlobalData.$mEventDispatcher.addEventListener("update_guild_member_list",onUpdateList);
         GlobalData.$mEventDispatcher.addEventListener("updata_guild_shop_list",onShopList);
         GlobalData.$mEventDispatcher.addEventListener("updata_guild_icon",onUpdateGuildCoin);
         GlobalData.$mEventDispatcher.addEventListener("update_guild_update",onUpdateGuildUpdate);
         GlobalData.$mEventDispatcher.addEventListener("update_guild_replace",onUpdateGuildReplace);
         GlobalData.$mEventDispatcher.addEventListener("update_avatarsoul_tag",updataTag);
      }
      
      private function ruleTouch(param1:TouchEvent) : void
      {
         touch = param1.getTouch(this);
         if(touch && touch.phase == "ended")
         {
            GlobalFunction.popPanelHelp(MainConfig.SERVER_ADDRESS_HELP_GUILD_EXPLAIN);
         }
      }
      
      private function onShopList(param1:Event) : void
      {
         iconImg.txt2 = GlobalData.$userData.attrs.association_gold;
         iconImg._mIcon.y = _bg.y - 239;
         SendServiceAMFFun.send_user_assocication_sever_shop_info(onUpdata_shop,{});
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         currGuildIndex = -1;
         delList();
         GlobalData.$userData.isGuildWarSaiCheng = false;
         GlobalData.$mEventDispatcher.removeEventListener("update_guild_member_list",onUpdateList);
         GlobalData.$mEventDispatcher.removeEventListener("updata_guild_shop_list",onShopList);
         GlobalData.$mEventDispatcher.removeEventListener("updata_guild_icon",onUpdateGuildCoin);
         GlobalData.$mEventDispatcher.removeEventListener("update_avatarsoul_tag",updataTag);
         GlobalData.$mEventDispatcher.removeEventListener("updata_exchange_num",updataExchangeNum);
         GlobalData.$mEventDispatcher.removeEventListener("updata_guild_contribute",updataGuildContribute);
         GlobalData.$mEventDispatcher.removeEventListener("update_guild_update",onUpdateGuildUpdate);
         GlobalData.$mEventDispatcher.removeEventListener("update_guild_replace",onUpdateGuildReplace);
         if(mTimerT1)
         {
            mTimerT1.removeFromParent(true);
            mTimerT1.dispose();
         }
         mTimerT1 = null;
         if(mTabBar)
         {
            mTabBar.removeFromParent(true);
            mTabBar.dispose();
         }
         if(_bg1)
         {
            _bg1.removeFromParent(true);
            _bg1.dispose();
         }
         if(_bg2)
         {
            _bg2.removeFromParent(true);
            _bg2.dispose();
         }
         if(mBg_list)
         {
            mBg_list.removeFromParent(true);
            mBg_list.dispose();
         }
         if(mRadioBar)
         {
            mRadioBar.removeFromParent(true);
            mRadioBar.dispose();
         }
         if(foundGuildBg)
         {
            foundGuildBg.removeFromParent(true);
            foundGuildBg.dispose();
         }
         if(foundGuildText)
         {
            foundGuildText.removeFromParent(true);
            foundGuildText.dispose();
         }
         if(imageL)
         {
            imageL.removeFromParent(true);
            imageL.dispose();
         }
         if(imageGold)
         {
            imageGold.removeFromParent(true);
            imageGold.dispose();
         }
         if(findImg)
         {
            findImg.removeFromParent(true);
            findImg.dispose();
         }
         if(findText)
         {
            findText.removeFromParent(true);
            findText.dispose();
         }
         if(guildShopBg)
         {
            guildShopBg.removeFromParent(true);
            guildShopBg.dispose();
         }
         if(guildShopCase)
         {
            guildShopCase.removeFromParent(true);
            guildShopCase.dispose();
         }
         if(guildShopRedCloth)
         {
            guildShopRedCloth.removeFromParent(true);
            guildShopRedCloth.dispose();
         }
         if(shopStrangeTxt)
         {
            shopStrangeTxt.removeFromParent(true);
            shopStrangeTxt.dispose();
         }
         if(shopGloryTxt)
         {
            shopGloryTxt.removeFromParent(true);
            shopGloryTxt.dispose();
         }
         if(_spRule)
         {
            _spRule.removeEventListener("touch",ruleTouch);
            _spRule.removeFromParent(true);
            _spRule.dispose();
         }
         if(guildShopRule)
         {
            guildShopRule.removeEventListener("touch",onGuildShopRule);
            guildShopRule.removeFromParent(true);
            guildShopRule.dispose();
         }
         if(shopRule)
         {
            shopRule.removeFromParent(true);
            shopRule.dispose();
         }
         if(ruleQuad)
         {
            ruleQuad.removeFromParent(true);
            ruleQuad.dispose();
         }
         if(quad)
         {
            quad.removeEventListener("touch",onGuildBattleRule);
            quad.removeFromParent(true);
            quad.dispose();
         }
         if(mTag_a)
         {
            mTag_a.removeFromParent(true);
            mTag_a.dispose();
         }
         if(guildBossRule)
         {
            guildBossRule.removeEventListener("touch",onGuildBossRule);
            guildBossRule.removeFromParent(true);
            guildBossRule.dispose();
         }
         if(refreshBtn)
         {
            refreshBtn.removeFromParent(true);
            refreshBtn.dispose();
         }
         if(ShopGuildLV)
         {
            ShopGuildLV.removeFromParent(true);
            ShopGuildLV.dispose();
         }
         if(mBox)
         {
            mBox.removeFromParent(true);
            mBox.dispose();
         }
         if(researchBg)
         {
            researchBg.removeFromParent(true);
            researchBg.dispose();
         }
         if(currentActive)
         {
            currentActive.removeFromParent(true);
            currentActive.dispose();
         }
         if(researchRuleSp)
         {
            researchRuleSp.removeEventListener("touch",researchTouch);
            researchRuleSp.removeFromParent(true);
            researchRuleSp.dispose();
         }
         if(researchRuleText)
         {
            researchRuleText.removeFromParent(true);
            researchRuleText.dispose();
         }
         if(researchRuleQuad)
         {
            researchRuleQuad.removeFromParent(true);
            researchRuleQuad.dispose();
         }
         if(researchSkillBtn)
         {
            researchSkillBtn.removeFromParent(true);
            researchSkillBtn.dispose();
         }
         if(activeTrade)
         {
            activeTrade.removeFromParent(true);
            activeTrade.dispose();
         }
         if(usualTradeBtn)
         {
            usualTradeBtn.removeFromParent(true);
            usualTradeBtn.dispose();
         }
         if(seniorTradeBtn)
         {
            seniorTradeBtn.removeFromParent(true);
            seniorTradeBtn.dispose();
         }
         if(btnSkill)
         {
            btnSkill.removeFromParent(true);
            btnSkill.dispose();
         }
         if(m_scrollContainer)
         {
            m_scrollContainer.removeFromParent(true);
            m_scrollContainer.dispose();
         }
         mRadioBar = null;
         mBg_list = null;
         _bg2 = null;
         _bg1 = null;
         mTabBar = null;
         foundGuildBg = null;
         foundGuildText = null;
         imageL = null;
         imageGold = null;
         findImg = null;
         findText = null;
         guildShopBg = null;
         guildShopCase = null;
         guildShopRedCloth = null;
         shopStrangeTxt = null;
         shopGloryTxt = null;
         _spRule = null;
         guildShopRule = null;
         shopRule = null;
         ruleQuad = null;
         quad = null;
         mTag_a = null;
         guildBossRule = null;
         refreshBtn = null;
         ShopGuildLV = null;
         mBox = null;
         researchBg = null;
         currentActive = null;
         researchRuleSp = null;
         researchRuleText = null;
         researchRuleQuad = null;
         researchSkillBtn = null;
         activeTrade = null;
         usualTradeBtn = null;
         seniorTradeBtn = null;
         btnSkill = null;
         m_scrollContainer = null;
      }
      
      private function onUpdateGuildCoin(param1:Event) : void
      {
         var _loc2_:String = null;
         if(param1.data)
         {
            if(param1.data.flag == 1)
            {
               if(guildImg)
               {
                  guildImg.removeFromParent(true);
                  guildImg.dispose();
                  guildImg = null;
               }
               guildImg = GlobalFunction.createImage("UI_guild_logo_00" + param1.data.index);
               guildImg.x = guildTxT.x + 150;
               guildImg.y = guildTxT.y + (guildTxT.height / 2 - guildImg.height / 2);
               addChild(guildImg);
            }
            else
            {
               if(icon)
               {
                  icon.removeFromParent(true);
                  icon.dispose();
                  icon = null;
               }
               _loc2_ = GuildInfo.data.association_info.icon < 10 ? "0" + GuildInfo.data.association_info.icon : GuildInfo.data.association_info.icon;
               icon = GlobalFunction.createImage("UI_guild_logo_00" + _loc2_);
               icon.x = mBg_list.x + 30;
               icon.y = mBg_list.y + 30;
               this.addChild(icon);
            }
         }
      }
      
      private function onUpdateList(param1:Event) : void
      {
         var _loc5_:* = 0;
         var _loc3_:Object = null;
         var _loc4_:int = 0;
         var _loc2_:Object = null;
         if(param1.data)
         {
            if(param1.data.flag == 1)
            {
               _loc5_ = 0;
               while(_loc5_ < GlobalData.$userGuild.info.data.info.length)
               {
                  _loc3_ = GlobalData.$userGuild.info.data.info[_loc5_];
                  if(param1.data.id == _loc3_.id)
                  {
                     GlobalData.$userGuild.info.data.info[_loc5_].flag = !_loc3_.flag;
                  }
                  _loc5_++;
               }
               NoGuildList(GlobalData.$userGuild.info);
            }
            if(param1.data.flag == 2)
            {
               _loc4_ = 0;
               while(_loc4_ < GuildInfo.data.member_list.length)
               {
                  _loc2_ = GuildInfo.data.member_list[_loc4_];
                  if(param1.data.num == 0)
                  {
                     if(GuildInfo.data.member_list[_loc4_].association_lv == 0)
                     {
                        GuildInfo.data.member_list[_loc4_].association_lv = 3;
                     }
                  }
                  if(param1.data.uid == _loc2_.uid && param1.data.zone == _loc2_.zone)
                  {
                     if(param1.data.num == -1)
                     {
                        (GuildInfo.data.member_list as Array).splice(_loc4_,1);
                     }
                     else
                     {
                        GuildInfo.data.member_list[_loc4_].association_lv = param1.data.num;
                     }
                  }
                  _loc4_++;
               }
               delList();
               RefreshGuildList();
            }
            if(param1.data.flag == 3)
            {
               if(param1.data.boo == 1)
               {
                  SendServiceAMFFun.send_user_associatione_is(onReGuild,{});
               }
            }
            if(param1.data.flag == 4)
            {
               this.radioBarSelectedIndex = -1;
               mRadioBar.selectedIndex = 0;
               F5List(0);
            }
            if(param1.data.flag == 10)
            {
               this.tabBarSelectedIndex = -1;
               mTabBar.selectedIndex = 0;
               SendServiceAMFFun.send_user_associatione_is(onReGuild,{});
            }
         }
         else
         {
            SendServiceAMFFun.send_user_associatione_is(onReGuild,{});
         }
      }
      
      private function radioBar_Complete(param1:Event) : void
      {
         this.radioBarSelectedIndex = -1;
      }
      
      private function radioBar_Change(param1:Event = null) : void
      {
         if(mTabBar.selectedIndex == 0)
         {
            delList();
            NoGuildList(GlobalData.$userGuild.info);
         }
         else if(mTabBar.selectedIndex == 3)
         {
            SendServiceAMFFun.send_user_assocication_sever_shop_info(onUpdata_shop,{});
         }
      }
      
      private function onUpdata_shop(param1:Object) : void
      {
         if(param1.data.res_code == -1)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97835),true);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
            return;
         }
         delList();
         GuildMessage.association_ShopArr = param1.data;
         updata_shop();
         checkGuildGuide();
      }
      
      private function setshopList() : void
      {
         var _rulerH:Number;
         var _layout:TiledRowsLayout;
         var tweenComplete:* = function():void
         {
            isReady = true;
         };
         isReady = false;
         GlobalData.$mStarling.juggler.tween(this,0.4,{"onComplete":tweenComplete});
         this.delList();
         if(this.mList == null)
         {
            _rulerH = 335;
            _layout = new TiledRowsLayout();
            _layout.paddingTop = 5;
            _layout.paddingRight = 10;
            _layout.paddingBottom = -10;
            _layout.paddingLeft = 0;
            _layout.horizontalAlign = "center";
            _layout.verticalAlign = "top";
            _layout.gap = 5;
            _layout.horizontalGap = 3;
            _layout.verticalGap = -8;
            _layout.useSquareTiles = false;
            this.mList = new List();
            this.mList.isSelectable = false;
            this.mList.width = GlobalData.$mStageWidth - 20;
            this.mList.height = mListH = GlobalData.$center_height - 408;
            this.mList.layout = _layout;
            this.mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
            this.mList.x = 12;
            if(GlobalData.$mStageHeight > 960)
            {
               this.mList.y = mListY = _rulerH + 28;
            }
            else
            {
               this.mList.y = mListY = _rulerH + 25;
            }
            this.mList.snapScrollPositionsToPixels = true;
            this.addChild(this.mList);
            _layout = null;
            this.mList.dataProvider = new ListCollection();
         }
      }
      
      private function addshopList() : void
      {
         var _loc7_:* = 0;
         var _loc2_:Array = null;
         var _guildRow:Array = null;
         var _guildGift:Object = null;
         var _loc11_:Object = null;
         var _loc3_:* = 0;
         var _loc13_:* = 0;
         var _loc4_:Object = null;
         var _loc9_:String = null;
         var _loc1_:* = 0;
         cfg = GlobalData.$mGuild_simple.guild_shop.sever_shop;
         handArr = cfg.hand_renovate;
         firstRefresh = handArr[0];
         eachTimeRefresh = handArr[1];
         guildShopCase = GlobalFunction.createScale9Image("UI_guildShop_box_0_0000",645,GlobalData.$mStageHeight > 960 ? 730 : 552,new Rectangle(219,153,15,15));
         guildShopCase.x = int((GlobalData.$mStageWidth - guildShopCase.width) * 0.5 - 1);
         guildShopCase.y = _bg2.y + _bg2.height + 29;
         addChildAt(guildShopCase,1);
         guildShopBg = GlobalFunction.createImage("UI_guildShop_bg_0_0000",true);
         guildShopBg.width = 572;
         if(GlobalData.$mStageHeight > 960)
         {
            guildShopBg.height = 646;
         }
         else
         {
            guildShopBg.height = 465;
         }
         guildShopBg.x = guildShopCase.x + 37;
         guildShopBg.y = guildShopCase.y + 44;
         addChildAt(guildShopBg,1);
         guildShopRedCloth = GlobalFunction.createImage("UI_guildShop_bar_0_0000",true);
         guildShopRedCloth.x = int((guildShopCase.width - guildShopRedCloth.width) * 0.5 + 21);
         guildShopRedCloth.y = guildShopCase.y - 30;
         addChild(guildShopRedCloth);
         if(isSever == 2)
         {
            if(mRadioBar.selectedIndex == 0)
            {
               shopStrangeTxt = GlobalFunction.createImage("UI_guildShop_title_1_0000",true);
               shopStrangeTxt.x = int((guildShopRedCloth.width - shopStrangeTxt.width) * 0.5 + 29);
               shopStrangeTxt.y = guildShopRedCloth.y + 20;
               addChild(shopStrangeTxt);
            }
            if(mRadioBar.selectedIndex == 1)
            {
               shopGloryTxt = GlobalFunction.createImage("UI_guildShop_title_0_0000",true);
               shopGloryTxt.x = int((guildShopRedCloth.width - shopGloryTxt.width) * 0.5 + 29);
               shopGloryTxt.y = guildShopRedCloth.y + 20;
               addChild(shopGloryTxt);
            }
         }
         else if(!isSever)
         {
            shopStrangeTxt = GlobalFunction.createImage("UI_guildShop_title_1_0000",true);
            shopStrangeTxt.x = int((guildShopRedCloth.width - shopStrangeTxt.width) * 0.5 + 29);
            shopStrangeTxt.y = guildShopRedCloth.y + 20;
            addChild(shopStrangeTxt);
         }
         else
         {
            shopGloryTxt = GlobalFunction.createImage("UI_guildShop_title_0_0000",true);
            shopGloryTxt.x = int((guildShopRedCloth.width - shopGloryTxt.width) * 0.5 + 29);
            shopGloryTxt.y = guildShopRedCloth.y + 20;
            addChild(shopGloryTxt);
         }
         var _loc14_:Object = GlobalFunction.get_HelpLink(GlobalLanguageStr.getLanguageStr(97852));
         guildShopRule = _loc14_.ui;
         guildShopRule.x = GlobalData.$mStageWidth - _loc14_.w - 30;
         guildShopRule.y = int((mTabBar.height - guildShopRule.height) * 0.5 + 80);
         addChild(guildShopRule);
         guildShopRule.addEventListener("touch",onGuildShopRule);
         _sp = new Sprite();
         this.addChild(_sp);
         _bg = GlobalFunction.createScale9Image("UI_guildShop_bg_3_0000",580,113,new Rectangle(25,25,50,25));
         _bg.x = int((GlobalData.$mStageWidth - _bg.width) * 0.5);
         _bg.y = guildShopRedCloth.y + guildShopRedCloth.height - 5;
         _sp.addChild(_bg);
         if(!iconImg)
         {
            iconImg = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getLanguageStr(97855),GlobalData.$userData.attrs.association_gold ? int(GlobalData.$userData.attrs.association_gold) + "" : "0","UI_money_guild_0_0000",1513239,1513239);
            iconImg.x = _bg.x + 16;
            iconImg.y = _bg.y + 17;
            iconImg._mIcon.y = _bg.y - 239;
            _sp.addChild(iconImg);
         }
         txt_1 = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97854),20,1513239,"left",240,46);
         txt_1.x = iconImg.x + 6;
         txt_1.y = iconImg.y + iconImg.height + 3;
         _sp.addChild(txt_1);
         refreshBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90647),120,50,"UI_btn_guild_2_0000");
         refreshBtn.fontSize = 22;
         refreshBtn.fontColor = 16777215;
         refreshBtn.x = _bg.width - 139;
         refreshBtn.y = _bg.y + (int((_bg.height - refreshBtn.height) * 0.5 + 17));
         _sp.addChild(refreshBtn);
         refreshBtn.addEventListener("triggered",onRefreshBtn);
         ShopGuildLV = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97932,GuildInfo.data.association_info.level),20,1513239,"left",240,46);
         ShopGuildLV.x = refreshBtn.x - (ShopGuildLV.textBounds.width - refreshBtn.width) - 7;
         ShopGuildLV.y = iconImg.y + 4;
         addChild(ShopGuildLV);
         var _loc12_:Object = getTimeOut();
         if(isSever == 2)
         {
            if(mRadioBar.selectedIndex == 0)
            {
               if(!mTimerT1)
               {
                  mTimerT1 = new LOL_TimeStatus("paneleawefewa",null,null,false);
                  mTimerT1.blendMode = Tools.getBlendMode(null,0,0,0);
                  mTimerT1.refresh(_loc12_.num / 1000,""," ",onTimeOverFun,"",true);
                  mTimerT1.x = txt_1.x + txt_1.width - 72;
                  mTimerT1.y = txt_1.y;
                  addChild(mTimerT1);
               }
               else
               {
                  mTimerT1.refresh(_loc12_.num / 1000,""," ",onTimeOverFun,"",true);
                  this.setChildIndex(mTimerT1,this.numChildren - 1);
               }
            }
            else
            {
               if(mTimerT1)
               {
                  mTimerT1.removeFromParent(true);
                  mTimerT1.dispose();
                  mTimerT1 = null;
               }
               if(txt_1)
               {
                  txt_1.removeFromParent(true);
                  txt_1.dispose();
                  txt_1 = null;
               }
            }
         }
         else if(!isSever)
         {
            if(!mTimerT1)
            {
               mTimerT1 = new LOL_TimeStatus("paneleawefewa",null,null,false);
               mTimerT1.blendMode = Tools.getBlendMode(null,0,0,0);
               mTimerT1.refresh(_loc12_.num / 1000,""," ",onTimeOverFun,"",true);
               mTimerT1.x = txt_1.x + txt_1.width - 83;
               mTimerT1.y = txt_1.y;
               addChild(mTimerT1);
            }
            else
            {
               mTimerT1.refresh(_loc12_.num / 1000,""," ",onTimeOverFun,"",true);
               this.setChildIndex(mTimerT1,this.numChildren - 1);
            }
         }
         else
         {
            if(mTimerT1)
            {
               mTimerT1.removeFromParent(true);
               mTimerT1.dispose();
               mTimerT1 = null;
            }
            if(txt_1)
            {
               txt_1.removeFromParent(true);
               txt_1.dispose();
               txt_1 = null;
            }
         }
         if(mRadioBar.selectedIndex == 1 || isSever == 1)
         {
            iconImg.y = _bg.y + (_bg.height - iconImg.height) * 0.5;
         }
         var _loc10_:Array = [];
         var _loc6_:Array = [];
         cfg = GlobalData.$mGuild_simple.guild_shop;
         if(isSever == 2)
         {
            if(mRadioBar.selectedIndex == 0)
            {
               cfg = GlobalData.$mGuild_simple.guild_shop.sever_shop.gift_info;
               _loc7_ = 0;
               while(_loc7_ < GuildMessage.association_ShopArr.sever_shop_info.length)
               {
                  for(var _loc5_:String in cfg)
                  {
                     if(_loc5_ == _loc7_ + "")
                     {
                        _loc2_ = cfg[_loc5_][GuildMessage.association_ShopArr.sever_shop_info[_loc7_]["index"]];
                        if(_loc2_ is Array && _loc2_.length > 0)
                        {
                           _loc2_ = (_loc2_ as Array).concat();
                           while(_loc2_.length < 2)
                           {
                              _loc2_.push(null);
                           }
                           _loc2_.push({
                              "index_2":GuildMessage.association_ShopArr.sever_shop_info[_loc7_]["index"],
                              "index_1":_loc7_
                           });
                           _loc6_.push(_loc2_);
                        }
                        break;
                     }
                  }
                  _loc7_++;
               }
            }
            else if(mRadioBar.selectedIndex == 1)
            {
               cfg = GlobalData.$mGuild_simple.guild_shop.guild_shop.gift_info;
               _loc11_ = GlobalData.$userGuild;
               _loc3_ = uint(_loc11_.GuildList.data.association_info.level);
               _loc13_ = uint(GlobalData.$mGuild_simple.guild_level["level_" + _loc3_].guild_shop_level);
               for(_loc5_ in cfg)
               {
                  if(_loc5_.split("_")[1] <= _loc13_)
                  {
                     for(var _loc8_:String in cfg[_loc5_ + ""])
                     {
                        cfg[_loc5_][_loc8_][3] = _loc5_.split("_")[1];
                        cfg[_loc5_][_loc8_][4] = _loc8_;
                        _loc6_.push(cfg[_loc5_][_loc8_]);
                     }
                  }
               }
            }
            if(mRadioBar.selectedIndex == 0)
            {
               _loc7_ = 0;
               while(_loc7_ < _loc6_.length)
               {
                  _loc4_ = {};
                  for(_loc5_ in _loc6_[_loc7_][0][0])
                  {
                     _loc9_ = _loc5_;
                     _loc4_["data"] = {};
                     _loc4_["data"][_loc9_] = _loc6_[_loc7_][0][0][_loc9_];
                  }
                  _loc4_["pay"] = _loc6_[_loc7_][0][1];
                  _loc4_["need_lv"] = _loc6_[_loc7_][0][2];
                  _loc4_["index_1"] = _loc6_[_loc7_][2]["index_1"];
                  _loc4_["index_2"] = _loc6_[_loc7_][2]["index_2"];
                  _loc4_["buyNum"] = GuildMessage.association_ShopArr.sever_shop_info[_loc7_].total_count;
                  _loc4_["isBuy"] = GuildMessage.association_ShopArr.sever_shop_info[_loc7_].can_buy;
                  _loc4_["s_type"] = mRadioBar.selectedIndex;
                  _loc4_["index"] = _loc7_;
                  _loc10_.push(_loc4_);
                  _loc7_++;
               }
            }
            else
            {
               _loc7_ = 0;
               while(_loc7_ < _loc6_.length)
               {
                  _loc4_ = {};
                  // Config stores each guild offer as [ [gift, pay, need_lv] ].
                  // The inner array is the row; passing its numeric indexes as
                  // reward types makes ItemGuildShop render a blank card.
                  _guildRow = _loc6_[_loc7_][0] as Array;
                  _guildGift = _guildRow[0] as Object;
                  _loc4_["data"] = {};
                  for(_loc5_ in _guildGift)
                  {
                     _loc9_ = _loc5_;
                     _loc4_["data"][_loc9_] = _guildGift[_loc9_];
                  }
                  _loc4_["lv"] = _loc6_[_loc7_][3];
                  _loc4_["need_lv"] = _guildRow[2];
                  _loc4_["pay"] = _guildRow[1];
                  _loc4_["buyNum"] = 0;
                  _loc1_ = 0;
                  while(_loc1_ < GuildMessage.association_ShopArr.guild_shop_info.length)
                  {
                     if(GuildMessage.association_ShopArr.guild_shop_info[_loc1_][0] == _loc6_[_loc7_][4])
                     {
                        _loc4_["buyNum"] = GuildMessage.association_ShopArr.guild_shop_info[_loc1_][1];
                     }
                     _loc1_++;
                  }
                  // ItemGuildShop treats boolean true as purchasable; false
                  // means the one-time offer has already been bought.
                  _loc4_["isBuy"] = _loc4_["buyNum"] < 1;
                  _loc4_["s_type"] = mRadioBar.selectedIndex;
                  _loc4_["index"] = _loc6_[_loc7_][4];
                  _loc10_.push(_loc4_);
                  _loc7_++;
               }
               _loc10_.sortOn("index",16);
            }
         }
         else if(!isSever)
         {
            cfg = GlobalData.$mGuild_simple.guild_shop.sever_shop.gift_info;
            _loc7_ = 0;
            while(_loc7_ < GuildMessage.association_ShopArr.sever_shop_info.length)
            {
               for(_loc5_ in cfg)
               {
                  if(_loc5_ == _loc7_ + "")
                  {
                     _loc2_ = cfg[_loc5_][GuildMessage.association_ShopArr.sever_shop_info[_loc7_]["index"]];
                     if(_loc2_ is Array && _loc2_.length > 0)
                     {
                        _loc2_ = (_loc2_ as Array).concat();
                        while(_loc2_.length < 2)
                        {
                           _loc2_.push(null);
                        }
                        _loc2_.push({
                           "index_2":GuildMessage.association_ShopArr.sever_shop_info[_loc7_]["index"],
                           "index_1":_loc7_
                        });
                        _loc6_.push(_loc2_);
                     }
                     break;
                  }
               }
               _loc7_++;
            }
            _loc7_ = 0;
            while(_loc7_ < _loc6_.length)
            {
               _loc4_ = {};
               for(_loc5_ in _loc6_[_loc7_][0][0])
               {
                  _loc9_ = _loc5_;
                  _loc4_["data"] = {};
                  _loc4_["data"][_loc9_] = _loc6_[_loc7_][0][0][_loc9_];
               }
               _loc4_["pay"] = _loc6_[_loc7_][0][1];
               _loc4_["need_lv"] = _loc6_[_loc7_][0][2];
               _loc4_["index_1"] = _loc6_[_loc7_][2]["index_1"];
               _loc4_["index_2"] = _loc6_[_loc7_][2]["index_2"];
               _loc4_["buyNum"] = GuildMessage.association_ShopArr.sever_shop_info[_loc7_].total_count;
               _loc4_["isBuy"] = GuildMessage.association_ShopArr.sever_shop_info[_loc7_].can_buy;
               _loc4_["s_type"] = isSever == 2 ? mRadioBar.selectedIndex : (isSever == 1 ? 1 : 0);
               _loc4_["index"] = _loc7_;
               _loc10_.push(_loc4_);
               _loc7_++;
            }
         }
         else
         {
            cfg = GlobalData.$mGuild_simple.guild_shop.guild_shop.gift_info;
            _loc11_ = GlobalData.$userGuild;
            _loc3_ = uint(_loc11_.GuildList.data.association_info.level);
            _loc13_ = uint(GlobalData.$mGuild_simple.guild_level["level_" + _loc3_].guild_shop_level);
            for(_loc5_ in cfg)
            {
               if(_loc5_.split("_")[1] <= _loc13_)
               {
                  for(_loc8_ in cfg[_loc5_ + ""])
                  {
                     cfg[_loc5_][_loc8_][3] = _loc5_.split("_")[1];
                     cfg[_loc5_][_loc8_][4] = _loc8_;
                     _loc6_.push(cfg[_loc5_][_loc8_]);
                  }
               }
            }
            _loc7_ = 0;
            while(_loc7_ < _loc6_.length)
            {
               _loc4_ = {};
               // Same nested row shape as the guild tab above.
               _guildRow = _loc6_[_loc7_][0] as Array;
               _guildGift = _guildRow[0] as Object;
               _loc4_["data"] = {};
               for(_loc5_ in _guildGift)
               {
                  _loc9_ = _loc5_;
                  _loc4_["data"][_loc9_] = _guildGift[_loc9_];
               }
               _loc4_["lv"] = _loc6_[_loc7_][3];
               _loc4_["need_lv"] = _guildRow[2];
               _loc4_["pay"] = _guildRow[1];
               _loc4_["buyNum"] = 0;
               _loc1_ = 0;
               while(_loc1_ < GuildMessage.association_ShopArr.guild_shop_info.length)
               {
                  if(GuildMessage.association_ShopArr.guild_shop_info[_loc1_][0] == _loc6_[_loc7_][4])
                  {
                     _loc4_["buyNum"] = GuildMessage.association_ShopArr.guild_shop_info[_loc1_][1];
                  }
                  _loc1_++;
               }
               _loc4_["isBuy"] = _loc4_["buyNum"] < 1;
               _loc4_["s_type"] = mRadioBar.selectedIndex;
               _loc4_["index"] = _loc6_[_loc7_][4];
               _loc10_.push(_loc4_);
               _loc7_++;
            }
            _loc10_.sortOn("index",16);
         }
         this.setListTimer(mList,_loc10_,ItemGuildShop,false);
      }
      
      private function onRefreshBtn(param1:Event) : void
      {
         var _fun:Object;
         var eve:Event = param1;
         var refreshService:* = function():void
         {
            GlobalData.$mGameClassObject.closePopUp();
            SendServiceAMFFun.send_user_assocication_sever_shop_refresh(onShopRefresh);
         };
         if(GlobalData.$userData.attrs.association_gold < firstRefresh + eachTimeRefresh * GuildMessage.association_ShopArr.guild_shop_refresh_count)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97920),false);
            return;
         }
         _fun = {
            "ok":refreshService,
            "okA":["Pop"],
            "no":GlobalFunction.functionNull,
            "aid":"A_1001_3"
         };
         GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(90647),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97918,String(firstRefresh + eachTimeRefresh * GuildMessage.association_ShopArr.guild_shop_refresh_count)),GlobalTextStyle.COLOR_W_B_Y_O),_fun,true,null,false,true);
      }
      
      private function onShopRefresh(param1:Object) : void
      {
         GlobalData.$userData.attrs.association_gold = param1.data.association_gold;
         iconImg.txt2 = String(Math.floor(GlobalData.$userData.attrs.association_gold - (firstRefresh + eachTimeRefresh * GuildMessage.association_ShopArr.guild_shop_refresh_count)));
         GlobalData.$mEventDispatcher.dispatchEventWith("updata_guild_shop_list");
      }
      
      private function onTimeOverFun() : void
      {
         radioBar_Change();
      }
      
      private function getTimeOut() : Object
      {
         cfg = GlobalData.$mGuild_simple.guild_shop.sever_shop;
         var _loc3_:Number = cfg.refresh_interval * 60 * 60 * 1000;
         _now = SendAndSelect.$systemTimer_nowSecond * 1000;
         var _loc1_:Number = _now % _loc3_;
         var _loc2_:Number = _loc3_ - _loc1_;
         return {"num":_loc2_};
      }
      
      private function updata_shop() : void
      {
         setshopList();
         addshopList();
      }
      
      override public function tabBar_CREATION_COMPLETE(param1:*) : void
      {
         isFush = true;
         onReGuild(_data);
      }
      
      private function onReGuild(param1:Object) : void
      {
         var _loc2_:* = 0;
         var guildNotice:String = "";
         if(param1.data.user)
         {
            GlobalData.$userData.attrs.association_gold = param1.data.user.association_gold;
         }
         if(GlobalData.$userGuild.guildFight_gameStart)
         {
            this.tabBarSelectedIndex = -1;
            mTabBar.selectedIndex = 1;
         }
         if(param1.data.flag)
         {
            GlobalData.$userGuild.guild_icon = param1.data.association_info.icon;
            GlobalData.$userData.attrs.association_id = param1.data.association_info.id;
            GlobalData.$userGuild.total_alive = param1.data.association_info.total_alive;
         }
         if(param1.data.member_list)
         {
            while(_loc2_ < param1.data.member_list.length)
            {
               if(param1.data.member_list[_loc2_].uid == GlobalData.$userData.uid && param1.data.member_list[_loc2_].zone == GlobalData.$userData.zone)
               {
                  GlobalData.$userData.attrs.association_lv = param1.data.member_list[_loc2_].association_lv;
               }
               _loc2_++;
            }
         }
         GuildInfo = {};
         GuildInfo.flag = param1.data.flag;
         GuildInfo.data = param1.data;
         GlobalData.$userGuild.GuildList = GuildInfo;
         if(mTabBar.selectedIndex != 0)
         {
            return;
         }
         F5List(GuildInfo.flag);
         if(param1.data.user)
         {
            if(param1.data.flag == 1)
            {
               if(param1.data.user.join_flag && param1.data.user.join_flag == true)
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97862),true);
               }
               else
               {
                  if(param1.data.user.join_flag && param1.data.user.join_flag == true && (param1.data.user.exit_flag && param1.data.user.exit_flag == true))
                  {
                     return;
                  }
                  if(param1.data.user.accredit_leader && param1.data.user.accredit_leader == true && GlobalData.$userData.attrs.association_lv == 0)
                  {
                     GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97993),false);
                  }
                  else if(param1.data.user.accredit_vice_leader && param1.data.user.accredit_vice_leader == true && GlobalData.$userData.attrs.association_lv == 1)
                  {
                     GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97992),false);
                  }
                  else if(param1.data.user.vice_leader_change_info && param1.data.user.vice_leader_change_info == true && GlobalData.$userData.attrs.association_lv != 1)
                  {
                     GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97833),false);
                  }
               }
            }
            else if(param1.data.user.exit_flag && param1.data.user.exit_flag == true)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97834),true);
            }
            else if(param1.data.user.join_flag && param1.data.user.join_flag == true && (param1.data.user.exit_flag && param1.data.user.exit_flag == true))
            {
               return;
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
               _loc3_ = guildLvPVP;
            }
            else if(param1 == 2)
            {
               _loc3_ = guildLvBoss;
            }
            else if(param1 == 3)
            {
               _loc3_ = guildLvShop;
            }
            else if(param1 == 4)
            {
               _loc3_ = guildLvStudy;
            }
            if(GlobalData.$userGuild.GuildList.data.association_info.level < _loc3_)
            {
               _loc2_ = GlobalData.$mConfig_simple.show_id[8];
               GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(97830,_loc3_),{"aid":_loc2_});
            }
         }
      }
      
      private function tabBar_Change(param1:Event = null) : void
      {
         var _loc2_:Array = null;
         var _loc3_:Object = null;
         isFush = true;
         clearRadioBarBaseFun();
         if(mTabBar.selectedIndex == 0)
         {
            if(!mBg_list)
            {
               mBg_list = GlobalFunction.createScale9Image("UI_guild_bg_1_0000",638,GlobalData.$mStageHeight - 207 - 121,new Rectangle(180,147,20,20));
               mBg_list.x = int((GlobalData.$mStageWidth - mBg_list.width) * 0.5);
               mBg_list.y = _bg2.y + _bg2.height;
               addChildAt(mBg_list,1);
            }
         }
         else
         {
            if(mBg_list)
            {
               mBg_list.removeFromParent(true);
               mBg_list.dispose();
            }
            mBg_list = null;
         }
         if(mTimerT1)
         {
            mTimerT1.removeFromParent(true);
            mTimerT1.dispose();
         }
         mTimerT1 = null;
         if(mTabBar.selectedIndex == 0)
         {
            _loc2_ = [];
            _loc2_.push({"label":GlobalLanguageStr.getLanguageStr(97677)});
            _loc2_.push({"label":GlobalLanguageStr.getLanguageStr(97673)});
            _loc2_.push({"label":GlobalLanguageStr.getLanguageStr(97678)});
            this.setRadioBar(_loc2_,radioBar_Change,radioBar_Complete,125);
            this.mRadioBar.x = 20;
            this.mRadioBar.y = _bg2.y + 10;
            F5List(GuildInfo.flag);
         }
         else if(mTabBar.selectedIndex == 1)
         {
            delList();
            if(mRadioBar)
            {
               mRadioBar.visible = false;
               mRadioBar.touchable = false;
            }
            if(_bg2)
            {
               _bg2.height = 30;
            }
            if(mBg_list)
            {
               mBg_list.y = _bg2.y + _bg2.height;
            }
            GuildFight();
         }
         else if(mTabBar.selectedIndex == 2)
         {
            delList();
            if(mRadioBar)
            {
               mRadioBar.visible = false;
               mRadioBar.touchable = false;
            }
            if(_bg2)
            {
               _bg2.height = 30;
            }
            if(mBg_list)
            {
               mBg_list.y = _bg2.y + _bg2.height;
            }
            GuildBoss();
            checkGuildGuide();
         }
         else if(mTabBar.selectedIndex == 3)
         {
            _loc2_ = [];
            isSever = 2;
            _loc3_ = GlobalData.$mGuild_simple.guild_shop;
            if(_loc3_.sever_shop.open && _loc3_.guild_shop.open)
            {
               isSever = 2;
            }
            else if(_loc3_.sever_shop.open)
            {
               isSever = 0;
            }
            else
            {
               isSever = 1;
            }
            if(_loc3_.sever_shop.open)
            {
               _loc2_.push({"label":GlobalLanguageStr.getLanguageStr(98152)});
            }
            if(_loc3_.guild_shop.open)
            {
               _loc2_.push({"label":GlobalLanguageStr.getLanguageStr(98153)});
            }
            this.setRadioBar(_loc2_,radioBar_Change,radioBar_Complete1,125);
            this.mRadioBar.x = 20;
            this.mRadioBar.y = _bg2.y + 10;
            delList();
            if(mRadioBar)
            {
               mRadioBar.visible = true;
               mRadioBar.touchable = true;
            }
            if(_bg2)
            {
               _bg2.height = 80;
            }
            if(mBg_list)
            {
               mBg_list.y = _bg2.y + _bg2.height;
            }
         }
         else if(mTabBar.selectedIndex == 4)
         {
            delList();
            if(_bg2)
            {
               _bg2.height = 30;
            }
            if(mBg_list)
            {
               mBg_list.y = _bg2.y + _bg2.height;
            }
            updateResearch();
         }
      }
      
      private function updateResearch() : void
      {
         setResearchList();
         addResearchList();
      }
      
      private function setResearchList() : void
      {
         var _layout:TiledRowsLayout;
         var tweenComplete:* = function():void
         {
            isReady = true;
         };
         isReady = false;
         GlobalData.$mStarling.juggler.tween(this,0.4,{"onComplete":tweenComplete});
         this.delList();
         if(this.mList == null)
         {
            _layout = new TiledRowsLayout();
            _layout.paddingTop = 5;
            _layout.paddingRight = 10;
            _layout.paddingBottom = -10;
            _layout.paddingLeft = 0;
            _layout.horizontalAlign = "center";
            _layout.verticalAlign = "top";
            _layout.gap = 5;
            _layout.horizontalGap = 55;
            _layout.verticalGap = -8;
            _layout.useSquareTiles = false;
            this.mList = new List();
            this.mList.isSelectable = false;
            this.mList.width = GlobalData.$mStageWidth - 20;
            this.mList.height = mListH = GlobalData.$center_height + 400;
            this.mList.layout = _layout;
            this.mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
            this.mList.x = 17;
            this.mList.y = mListY = 110;
            this.mList.snapScrollPositionsToPixels = true;
            this.addChild(this.mList);
            _layout = null;
            this.mList.dataProvider = new ListCollection();
         }
      }
      
      private function addResearchList() : void
      {
         var _loc5_:Object = null;
         var _loc4_:Object = null;
         GlobalData.$mEventDispatcher.addEventListener("updata_exchange_num",updataExchangeNum);
         GlobalData.$mEventDispatcher.addEventListener("updata_guild_contribute",updataGuildContribute);
         m_scrollContainer = new ScrollContainer();
         var _loc3_:VerticalLayout = new VerticalLayout();
         _loc3_.paddingBottom = GlobalData.$mStageHeight > 960 ? -260 : -30;
         m_scrollContainer.layout = _loc3_;
         m_scrollContainer.setSize(800,GlobalData.$mStageHeight > 960 ? 675 : 550);
         m_scrollContainer.pageThrowDuration = 0;
         m_scrollContainer.hasElasticEdges = true;
         m_scrollContainer.x = 16;
         m_scrollContainer.y = 110;
         m_scrollContainer.addChild(this.mList);
         this.addChild(m_scrollContainer);
         cfg = GlobalData.$mGuild_simple.guild_graduate.guild_graduate_skill;
         var _loc1_:Object = GlobalData.$mGuild_simple.guild_contribute_info.exchange_count_info;
         mBox = new Sprite();
         addChild(mBox);
         var _loc2_:Scale9Textures = new Scale9Textures(GlobalFunction.getTexture("UI_guild_bg_2_0000"),new Rectangle(30,30,50,50));
         researchBg = new Scale9Image(_loc2_);
         researchBg.width = 642;
         researchBg.height = 120;
         researchBg.x = int((GlobalData.$mStageWidth - researchBg.width) * 0.5);
         researchBg.y = GlobalData.$center_height - researchBg.height;
         mBox.addChild(researchBg);
         currentActive = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getLanguageStr(90758),GlobalData.$userData.attrs.guild_contribute + "","UI_contribution_icon_0_0000",1513239,1513239);
         currentActive._mIcon.scaleX = currentActive._mIcon.scaleY = 0.7;
         currentActive.x = researchBg.x + 15;
         currentActive.y = researchBg.y + 15;
         mBox.addChild(currentActive);
         researchRuleSp = new Sprite();
         researchRuleText = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90752),20,10027008,"left",100,35);
         researchRuleSp.addChild(researchRuleText);
         researchRuleQuad = Tools.newQuad(83,2,currentActive.x - 13,researchRuleText.height - 5,10027008);
         researchRuleQuad.y = researchRuleText.height - 5;
         researchRuleSp.addChild(researchRuleQuad);
         researchRuleSp.x = currentActive.x + 5;
         researchRuleSp.y = currentActive.y + 46;
         mBox.addChild(researchRuleSp);
         researchRuleText.touchable = true;
         researchRuleSp.addEventListener("touch",researchTouch);
         researchSkillBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90753),120,50,"UI_btn_guild_2_0000");
         researchSkillBtn.fontColor = 16777215;
         researchSkillBtn.fontSize = 22;
         researchSkillBtn.x = researchRuleText.x + 110;
         researchSkillBtn.y = researchRuleSp.y - 5;
         mBox.addChild(researchSkillBtn);
         researchSkillBtn.addEventListener("triggered",skillTriggered);
         if(GlobalData.$userData.attrs.association_lv == 0 || GlobalData.$userData.attrs.association_lv == 1)
         {
            researchSkillBtn.enabled = true;
         }
         else
         {
            researchSkillBtn.enabled = false;
         }
         activeTrade = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90754),20,1513239,"left",100,35);
         activeTrade.x = researchBg.width * 0.5 - 50;
         activeTrade.y = researchBg.y + researchBg.height * 0.5 - 16;
         mBox.addChild(activeTrade);
         usualTradeBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90755),120,50,"UI_btn_guild_2_0000");
         usualTradeBtn.fontColor = 16777215;
         usualTradeBtn.fontSize = 22;
         usualTradeBtn.name = "usual_trade_btn";
         usualTradeBtn.x = activeTrade.x + 98;
         usualTradeBtn.y = activeTrade.y - 9;
         mBox.addChild(usualTradeBtn);
         usualTradeBtn.addEventListener("triggered",tradeTriggered);
         if(GlobalData.$userGuild.GuildList.data.user.guild_contribute_exchange_normal_count >= _loc1_[GlobalFunction.getVipLv()]["normal"])
         {
            usualTradeBtn.enabled = false;
         }
         seniorTradeBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90756),120,50,"UI_btn_guild_2_0000");
         seniorTradeBtn.fontColor = 16777215;
         seniorTradeBtn.fontSize = 22;
         seniorTradeBtn.name = "senior_trade_btn";
         seniorTradeBtn.x = usualTradeBtn.x + 130;
         seniorTradeBtn.y = usualTradeBtn.y;
         mBox.addChild(seniorTradeBtn);
         seniorTradeBtn.addEventListener("triggered",tradeTriggered);
         if(GlobalData.$userGuild.GuildList.data.user.guild_contribute_exchange_expert_count >= _loc1_[GlobalFunction.getVipLv()]["expert"])
         {
            seniorTradeBtn.enabled = false;
         }
         var _loc6_:Array = [];
         for(var _loc7_ in cfg)
         {
            _loc4_ = cfg[_loc7_];
            _loc5_ = {};
            _loc5_["name"] = MainConfig.$gameLanguage == "tw" ? _loc4_.name : _loc4_.name_cn;
            _loc5_["description"] = MainConfig.$gameLanguage == "tw" ? _loc4_.description : _loc4_.description_cn;
            _loc5_["id"] = _loc7_;
            _loc5_["icon"] = _loc4_.icon;
            _loc5_["level"] = _loc4_.level;
            _loc6_.push(_loc5_);
         }
         _loc6_.sortOn("icon",16);
         this.setListTimer(this.mList,_loc6_,ItemGuildResearch,false);
      }
      
      private function onUpdateGuildUpdate(param1:Event) : void
      {
         var _loc4_:Object = null;
         var _loc3_:* = 0;
         var _loc7_:int = 0;
         var _loc5_:Object = param1.data.guild_graduate_skill;
         var _loc6_:Array = this.mList.dataProvider.data as Array;
         for(var _loc2_:String in _loc5_)
         {
            _loc7_ = 0;
            while(_loc7_ < _loc6_.length)
            {
               if(_loc6_[_loc7_].id == _loc2_)
               {
                  _loc4_ = _loc6_[_loc7_];
                  _loc3_ = _loc7_;
                  this.mList.dataProvider.setItemAt(_loc4_,_loc3_);
                  this.mList.dataProvider.updateItemAt(_loc3_);
                  break;
               }
               _loc7_++;
            }
         }
      }
      
      private function onUpdateGuildReplace(param1:Event) : void
      {
         updateResearch();
      }
      
      private function researchTouch(param1:TouchEvent) : void
      {
         touch = param1.getTouch(this);
         if(touch && touch.phase == "ended")
         {
            GlobalFunction.popPanelHelp(MainConfig.SERVER_ADDRESS_HELP_GUILD_RESEARCH);
         }
      }
      
      private function skillTriggered(param1:Event) : void
      {
         if(researchSkillBtn.enabled == false)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90757),true);
         }
         else
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_guild_research_skill",false,true);
         }
      }
      
      private function tradeTriggered(param1:Event) : void
      {
         btnSkill = param1.currentTarget as LOL_Scale9Button;
         switch(btnSkill.name)
         {
            case "usual_trade_btn":
               if(usualTradeBtn.enabled == false)
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90760));
               }
               else
               {
                  GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_guild_usual_trade",false,true);
               }
               break;
            case "senior_trade_btn":
               if(seniorTradeBtn.enabled == false)
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90760));
               }
               else
               {
                  GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_guild_senior_trade",false,true);
               }
         }
      }
      
      private function updataExchangeNum(param1:Event) : void
      {
         if(btnSkill.name == "usual_trade_btn")
         {
            if(GlobalData.$userGuild.GuildList.data.user.guild_contribute_exchange_normal_count >= param1.data.num)
            {
               usualTradeBtn.enabled = false;
            }
         }
         else if(btnSkill.name == "senior_trade_btn")
         {
            if(GlobalData.$userGuild.GuildList.data.user.guild_contribute_exchange_expert_count >= param1.data.num)
            {
               seniorTradeBtn.enabled = false;
            }
         }
         currentActive.txt2 = param1.data.guild_contribute;
         currentActive._mIcon.scaleX = currentActive._mIcon.scaleY = 0.7;
      }
      
      private function updataGuildContribute(param1:Event) : void
      {
         currentActive.txt2 = param1.data.guild_contribute;
         currentActive._mIcon.scaleX = currentActive._mIcon.scaleY = 0.7;
      }
      
      private function checkGuildGuide() : void
      {
         var _loc1_:Date = null;
         var _loc3_:* = 0;
         var _loc2_:String = GuideTools.checkGuildFight();
         if(_loc2_ == "10")
         {
            currLunAndJie();
            _now = SendAndSelect.$systemTimer_nowSecond * 1000;
            _now = Tools.getServerNowTimeDate(_now).time;
            _loc1_ = new Date();
            _loc1_.setTime(_now);
            _loc3_ = 0;
            while(_loc3_ < userTime.memberTimeArr.length)
            {
               if(_loc1_.time > (userTime.memberTimeArr[_loc3_].start as Date).time && _loc1_.time < (userTime.memberTimeArr[_loc3_].end as Date).time)
               {
                  LayoutUIAnimation.getOnlyExample().addArrowhead(198,154,0);
               }
               _loc3_++;
            }
            if(_now > (userTime.FightStartTime as Date).time && _now < (userTime.guildBMendTime as Date).time)
            {
               LayoutUIAnimation.getOnlyExample().addArrowhead(198,154,0);
            }
         }
         if(isFush)
         {
            isFush = false;
         }
         else
         {
            LayoutUIAnimation.getOnlyExample().clear();
         }
      }
      
      private function onGuildBattleRule(param1:TouchEvent) : void
      {
         touch = param1.getTouch(this);
         if(touch && touch.phase == "ended")
         {
            GlobalFunction.popPanelHelp(MainConfig.SERVER_ADDRESS_HELP_GUILD_BATTLE);
         }
      }
      
      private function onGuildShopRule(param1:TouchEvent) : void
      {
         touch = param1.getTouch(this);
         if(touch && touch.phase == "ended")
         {
            GlobalFunction.popPanelHelp(MainConfig.SERVER_ADDRESS_HELP_GUILD_SHOP);
         }
      }
      
      private function GuildBoss() : void
      {
         _bgFight = GlobalFunction.createImage("png_guild_boss",true);
         this.addChildAt(_bgFight,0);
         var _loc2_:Object = GlobalFunction.get_HelpLink(GlobalLanguageStr.getLanguageStr(97909));
         guildBossRule = _loc2_.ui;
         guildBossRule.x = GlobalData.$mStageWidth - _loc2_.w - 30;
         guildBossRule.y = int((mTabBar.height - guildBossRule.height) * 0.5 + 88);
         addChild(guildBossRule);
         guildBossRule.addEventListener("touch",onGuildBossRule);
         btn_BOSS_RewardPreview = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(97764),150,70,"UI_btn_guild_2_0000");
         btn_BOSS_RewardPreview.name = "rewardpreview";
         btn_BOSS_RewardPreview.x = GlobalData.$mStageWidth / 3 - btn_BOSS_RewardPreview.width;
         btn_BOSS_RewardPreview.y = GlobalData.$center_height - btn_BOSS_RewardPreview.height - 20;
         this.addChild(btn_BOSS_RewardPreview);
         btn_BOSS_RewardPreview.addEventListener("triggered",onBOSSFightTriggered);
         title = GlobalFunction.createImage("UI_guildBoss_title_0_0000",true);
         title1 = GlobalFunction.createImage("UI_guildBoss_title_1_0000",true);
         title.x = 20;
         title.y = 120;
         title1.x = 20;
         title1.y = 480;
         if(GlobalData.$mStageHeight > 960)
         {
            title1.y += (GlobalData.$mStageHeight - 960) / 2;
         }
         this.addChild(title);
         this.addChild(title1);
         btn_BOSS_AllFight = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20042),150,70,"UI_btn_guild_2_0000");
         btn_BOSS_AllFight.name = "allfight";
         btn_BOSS_AllFight.y = btn_BOSS_RewardPreview.y;
         btn_BOSS_AllFight.x = GlobalData.$mStageWidth / 2 - btn_BOSS_AllFight.width / 2;
         this.addChild(btn_BOSS_AllFight);
         btn_BOSS_AllFight.addEventListener("triggered",onBOSSFightTriggered);
         var _loc1_:Object = checkBossIsOpen();
         mTimerTBoss = new LOL_TimeStatus("paneltimeextractiona");
         mTimerTBoss.y = _bg2.y + _bg2.height;
         mTimerTBoss.x = 20;
         addChild(mTimerTBoss);
         btn_BOSS_HurtRanklist = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(97858),150,70,"UI_btn_guild_2_0000");
         btn_BOSS_HurtRanklist.name = "hurtranklist";
         btn_BOSS_HurtRanklist.x = GlobalData.$mStageWidth - btn_BOSS_HurtRanklist.x - btn_BOSS_RewardPreview.width - 63;
         btn_BOSS_HurtRanklist.y = btn_BOSS_RewardPreview.y;
         this.addChild(btn_BOSS_HurtRanklist);
         btn_BOSS_HurtRanklist.addEventListener("triggered",onBOSSFightTriggered);
         if(_loc1_.can)
         {
            mTimerTBoss.refresh((_loc1_.time_end - _loc1_.time_now) / 1000,GlobalLanguageStr.getLanguageStr(97059,Tools.timeFormatAll((_loc1_.time_end - _loc1_.time_now) / 1000)),GlobalLanguageStr.getLanguageStr(97060),isOver);
         }
         else
         {
            btn_BOSS_AllFight.visible = false;
            btn_BOSS_RewardPreview.x = GlobalData.$mStageWidth / 3 - btn_BOSS_RewardPreview.width / 2;
            btn_BOSS_HurtRanklist.x = GlobalData.$mStageWidth / 3 * 2 - btn_BOSS_HurtRanklist.width / 2;
            mTimerTBoss.refresh(0,GlobalLanguageStr.getLanguageStr(98157)," ",isOver);
         }
      }
      
      private function onGuildBossRule(param1:TouchEvent) : void
      {
         touch = param1.getTouch(this);
         if(touch && touch.phase == "ended")
         {
            GlobalFunction.popPanelHelp(MainConfig.SERVER_ADDRESS_HELP_GUILD_BOSS);
         }
      }
      
      private function isOver() : void
      {
         mTimerTBoss.refresh(0,GlobalLanguageStr.getLanguageStr(98157),GlobalLanguageStr.getLanguageStr(98157));
      }
      
      private function onBOSSFightTriggered(param1:Event) : void
      {
         var _loc2_:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         if(_loc2_)
         {
            switch(_loc2_.name)
            {
               case "hurtranklist":
                  SendServiceAMFFun.send_user_get_association_boss_ranks(onBossHert);
                  break;
               case "allfight":
                  SendServiceAMFFun.send_user_get_associationboss(onBossFun,{});
                  break;
               case "rewardpreview":
                  GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_goss_gift",false,true);
            }
         }
      }
      
      private function onBossHert(param1:Object) : void
      {
         if(param1.data.res_code == -1)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97835),true);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
            return;
         }
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_boss_hert_rank",false,true,param1);
      }
      
      private function onBossFun(param1:Object) : void
      {
         if(param1.data.res_code == -1)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97835),true);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
            return;
         }
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_boss_all_fight",false,true,param1);
      }
      
      private function radioBar_Complete1(param1:Event) : void
      {
         this.radioBarSelectedIndex = -1;
         radioBar_Change();
      }
      
      private function GuildFight() : void
      {
         var datel:Date;
         var i:uint;
         var objlll:Object;
         var startOver:Boolean;
         var str:String;
         var _attrs1:*;
         var _attrs:*;
         var eyes:Image;
         var eyes2:Image;
         var aa:* = function():void
         {
            if(GlobalData.$userGuild.guildFight_gameStart)
            {
               GlobalData.$userGuild.guildFight_gameStart = false;
               SendServiceAMFFun.send_user_get_fight_result(onReFUN,{});
            }
         };
         _now = SendAndSelect.$systemTimer_nowSecond * 1000;
         var datesss:Date = Tools.getServerNowTimeDate(_now);
         _now = datesss.time;
         var obj:Object = currLunAndJie();
         var _step1:String = GuideTools.checkGuildFight();
         if(_step1 == "10")
         {
            currLunAndJie();
            _now = SendAndSelect.$systemTimer_nowSecond * 1000;
            _now = Tools.getServerNowTimeDate(_now).time;
            datel = new Date();
            datel.setTime(_now);
            i = 0;
            while(i < userTime.memberTimeArr.length)
            {
               if(datel.time > (userTime.memberTimeArr[i].start as Date).time && datel.time < (userTime.memberTimeArr[i].end as Date).time)
               {
                  LayoutUIAnimation.getOnlyExample().addArrowhead(337,551,0);
               }
               i = i + 1;
            }
            if(_now > (userTime.FightStartTime as Date).time && _now < (userTime.guildBMendTime as Date).time)
            {
               LayoutUIAnimation.getOnlyExample().addArrowhead(337,551,0);
            }
         }
         objlll = getShaShaDaoJiShi();
         startOver = false;
         if(datesss.time > (userTime.FightStartTime as Date).time && datesss.time < (userTime.FightOverTime as Date).time)
         {
            startOver = true;
         }
         objGuildFight = getTimeOutSchedule();
         bgYuan = GlobalFunction.createImage(startOver ? "png_guild_fight_yuan_red" : "png_guild_fight_yuan",true);
         bgYuan.y = _bg2.y + _bg2.height;
         this.addChild(bgYuan);
         str = "";
         switch(objlll.type)
         {
            case "GuildBMTime":
               str = GlobalLanguageStr.getLanguageStr(97912);
               break;
            case "MemberBMTime":
               str = GlobalLanguageStr.getLanguageStr(97913);
               break;
            case "NextMemberBMTime":
               str = GlobalLanguageStr.getLanguageStr(97914,lun);
               break;
            case "NextMemberBMTime2":
               str = GlobalLanguageStr.getLanguageStr(97914,lun + 1);
               break;
            case "NextGameTime":
               str = GlobalLanguageStr.getLanguageStr(97915);
               break;
            case "":
               str = GlobalLanguageStr.getLanguageStr(97915);
         }
         mTimerTBoss = new LOL_TimeStatus("GuildFight");
         mTimerTBoss.y = _bg2.y + _bg2.height;
         mTimerTBoss.x = 20;
         addChild(mTimerTBoss);
         mTimerTBoss.refresh(objlll.overTime / 1000,"",str,isOverFight);
         _attrs1 = {};
         _attrs = {};
         if(startOver)
         {
            _attrs = {
               "id":"p05",
               "xml":"px08",
               "y":100,
               "rate":0.3,
               "st":200,
               "scy":1,
               "ep":{
                  "bfs":3,
                  "bfd":1,
                  "maxr":120,
                  "maxrv":60,
                  "minr":14,
                  "s1":300,
                  "s1v":100,
                  "s2":0,
                  "s2v":0,
                  "r2v":8,
                  "rps":8,
                  "rpsv":0,
                  "maxp":50,
                  "life":20
               },
               "ec":{
                  "co1":{
                     "r":1,
                     "g":0.5,
                     "b":0.5,
                     "a":0.1
                  },
                  "co2":{
                     "r":0.1,
                     "g":0.1,
                     "b":0.1,
                     "a":0.8
                  }
               },
               "i":1
            };
            _attrs1 = {
               "id":"p19",
               "xml":"px08",
               "y":100,
               "rate":0.5,
               "st":200,
               "scy":1.5,
               "ep":{
                  "bfs":3,
                  "bfd":13,
                  "maxr":90,
                  "maxrv":60,
                  "minr":0,
                  "minrv":0,
                  "s1":30,
                  "s1v":8,
                  "s2":0,
                  "s2v":0.2,
                  "rps":9,
                  "rpsv":0,
                  "maxp":150
               },
               "ec":{
                  "co1":{
                     "r":1,
                     "g":0,
                     "b":0,
                     "a":0
                  },
                  "co2":{
                     "r":0,
                     "g":0,
                     "b":0,
                     "a":0.7
                  }
               }
            };
         }
         else
         {
            _attrs = {
               "id":"p05",
               "xml":"px08",
               "y":100,
               "rate":0.3,
               "st":200,
               "scy":1,
               "ep":{
                  "bfs":3,
                  "bfd":1,
                  "maxr":120,
                  "maxrv":60,
                  "minr":14,
                  "s1":300,
                  "s1v":100,
                  "s2":0,
                  "s2v":0,
                  "r2v":8,
                  "rps":8,
                  "rpsv":0,
                  "maxp":50,
                  "life":20
               },
               "ec":{
                  "co1":{
                     "r":0,
                     "g":0.2,
                     "b":0.5,
                     "a":0.1
                  },
                  "co2":{
                     "r":0.1,
                     "g":0.1,
                     "b":0.1,
                     "a":0.8
                  }
               },
               "i":1
            };
            _attrs1 = {
               "id":"p19",
               "xml":"px08",
               "y":100,
               "rate":0.5,
               "st":200,
               "scy":1.5,
               "ep":{
                  "bfs":3,
                  "bfd":13,
                  "maxr":90,
                  "maxrv":60,
                  "minr":0,
                  "minrv":0,
                  "s1":30,
                  "s1v":8,
                  "s2":0,
                  "s2v":0.2,
                  "rps":9,
                  "rpsv":0,
                  "maxp":150
               },
               "ec":{
                  "co1":{
                     "r":0,
                     "g":0.3,
                     "b":1,
                     "a":0
                  },
                  "co2":{
                     "r":1,
                     "g":1,
                     "b":1,
                     "a":0.7
                  }
               }
            };
         }
         _attrs.x = GlobalData.$mStageWidth / 2 + 10;
         _attrs.y = 440;
         _attrs.par = this;
         _dis = DisplayTools.addEffectOne(_attrs);
         _attrs1.x = GlobalData.$mStageWidth / 2 + 10;
         _attrs1.y = 440;
         _attrs1.par = this;
         _dis1 = DisplayTools.addEffectOne(_attrs1);
         _bgFight = GlobalFunction.createImage("png_guild_fight",true);
         _bgFight.y = _bg2.y + _bg2.height;
         this.addChildAt(_bgFight,1);
         this.setChildIndex(bgYuan,0);
         this.setChildIndex(_dis,1);
         this.setChildIndex(_dis1,1);
         spr = new Sprite();
         this.addChild(spr);
         eyes = GlobalFunction.createImage(startOver ? "png_guild_fight_up_red" : "png_guild_fight_up",true);
         eyes.y = _bg2.y + _bg2.height;
         spr.addChild(eyes);
         eyes2 = GlobalFunction.createImage(startOver ? "png_guild_fight_up_red" : "png_guild_fight_up",true);
         eyes2.y = _bg2.y + _bg2.height + 3;
         eyes2.scaleX = -1;
         eyes2.x = eyes2.width + 2;
         spr.addChild(eyes2);
         eyes1(spr);
         guildFight_Reward = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(97764),130,60,"UI_btn_guild_2_0000");
         guildFight_Reward.textColor = 16777215;
         guildFight_Reward.name = "reward";
         guildFight_Reward.x = GlobalData.$mStageWidth / 3 - guildFight_Reward.width;
         guildFight_Reward.y = GlobalData.$center_height - guildFight_Reward.height - 20;
         guildFight_Reward.addEventListener("triggered",onGuildFightTriggered);
         this.addChild(guildFight_Reward);
         guildFight_Rank = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20469),130,60,"UI_btn_guild_2_0000");
         guildFight_Rank.textColor = 16777215;
         guildFight_Rank.name = "rank";
         guildFight_Rank.y = guildFight_Reward.y;
         guildFight_Rank.x = GlobalData.$mStageWidth / 2 - guildFight_Rank.width / 2;
         guildFight_Rank.addEventListener("triggered",onGuildFightTriggered);
         this.addChild(guildFight_Rank);
         guildFight_Schedule = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(97773),150,80,"null");
         guildFight_Schedule.textColor = 16777215;
         guildFight_Schedule.name = "schedule";
         guildFight_Schedule.filter = GlobalFunction.getShadowFilters();
         guildFight_Schedule.x = GlobalData.$mStageWidth / 2 - guildFight_Schedule.width / 2 + 15;
         guildFight_Schedule.y = 400;
         guildFight_Schedule.addEventListener("triggered",onGuildFightTriggered);
         this.addChild(guildFight_Schedule);
         guildFight_Chack = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(97774),130,60,"UI_btn_guild_2_0000");
         guildFight_Chack.textColor = 16777215;
         guildFight_Chack.name = "chack";
         guildFight_Chack.x = GlobalData.$mStageWidth - guildFight_Chack.width - guildFight_Reward.x;
         guildFight_Chack.addEventListener("triggered",onGuildFightTriggered);
         guildFight_Chack.y = guildFight_Reward.y;
         this.addChild(guildFight_Chack);
         setTimeout(aa,20);
         shopRule = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97851),20,1118481,"right",125,55);
         shopRule.x = GlobalData.$mStageWidth - shopRule.width - 30;
         shopRule.y = bgYuan.y + 7;
         addChild(shopRule);
         ruleQuad = Tools.newQuad(97,2,shopRule.x + 26,shopRule.y + 27,0);
         addChild(ruleQuad);
         quad = Tools.newQuad(102,shopRule.height - 31,shopRule.x + 25,shopRule.y + 7,0);
         quad.alpha = 0;
         addChild(quad);
         quad.addEventListener("touch",onGuildBattleRule);
      }
      
      private function isOverFight() : void
      {
         currLunAndJie();
         var _loc1_:Object = getShaShaDaoJiShi();
         var _loc2_:String = "";
         switch(_loc1_.type)
         {
            case "GuildBMTime":
               _loc2_ = GlobalLanguageStr.getLanguageStr(97912);
               break;
            case "MemberBMTime":
               _loc2_ = GlobalLanguageStr.getLanguageStr(97913);
               break;
            case "NextMemberBMTime":
               _loc2_ = GlobalLanguageStr.getLanguageStr(97914,lun);
               break;
            case "NextMemberBMTime2":
               _loc2_ = GlobalLanguageStr.getLanguageStr(97914,lun + 1);
               break;
            case "NextGameTime":
               _loc2_ = GlobalLanguageStr.getLanguageStr(97915);
               break;
            case "":
               _loc2_ = GlobalLanguageStr.getLanguageStr(97915);
         }
         mTimerTBoss.refresh(_loc1_.overTime / 1000,"",_loc2_,isOverFight);
      }
      
      private function getTimeOutSchedule() : Object
      {
         var _loc2_:Object = GlobalData.$mGuild_simple.the_guild_pvp.time;
         var _loc3_:Number = SendAndSelect.$systemTimer_nowSecond * 1000;
         var _loc6_:Number = (_loc2_.start_time as Date).time;
         var _loc1_:Number = _loc6_ + _loc2_.cycle * 1000 * 60;
         var _loc5_:Boolean = false;
         if(_loc3_ >= _loc6_ && _loc3_ < _loc1_)
         {
            _loc5_ = true;
         }
         var _loc4_:Number = _loc1_ - _loc3_;
         return {
            "can":_loc5_,
            "end":_loc4_ * 0.001
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
      
      private function eyes1(param1:Sprite) : void
      {
         var tween:Tween;
         var eyes:Sprite = param1;
         var bloodup:* = function():void
         {
            var over:* = function():void
            {
               setTimeout(blooddown,1000);
            };
            eyes.alpha = 0;
            if(tween)
            {
               Starling.juggler.remove(tween);
               tween = null;
            }
            tween = new Tween(eyes,1);
            tween.animate("alpha",1);
            tween.onComplete = over;
            Starling.juggler.add(tween);
         };
         var blooddown:* = function():void
         {
            var over1:* = function():void
            {
               setTimeout(bloodup,1000);
            };
            eyes.alpha = 1;
            if(tween)
            {
               Starling.juggler.remove(tween);
               tween = null;
            }
            tween = new Tween(eyes,1);
            tween.animate("alpha",0);
            tween.onComplete = over1;
            Starling.juggler.add(tween);
         };
         blooddown();
      }
      
      private function onGuildFightTriggered(param1:Event) : void
      {
         var _loc3_:Object = null;
         var _loc2_:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         if(_loc2_)
         {
            switch(_loc2_.name)
            {
               case "reward":
                  SendServiceAMFFun.send_user_get_reward_data(onReFu,{});
                  break;
               case "rank":
                  SendServiceAMFFun.send_user_get_war_rank(onReFun,{});
                  break;
               case "schedule":
                  _loc3_ = currLunAndJie();
                  SendServiceAMFFun.send_user_show_war_data(onDataRe,{});
                  break;
               case "chack":
                  SendServiceAMFFun.send_user_get_fight_result(onReFUN,{});
            }
         }
      }
      
      private function onReFu(param1:Object) : void
      {
         if(param1.data.res_code == -1)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97835),true);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
            return;
         }
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_gvg_prizes",false,true,param1);
      }
      
      private function onDataRe(param1:Object) : void
      {
         if(param1.data)
         {
            if(param1.data.res_code == -1)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97835),true);
               GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
               return;
            }
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_guildfight_schedule",false,true,param1);
         }
         else
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_guildfight_schedule",false,true,{"data":{
               "report":{"association_join":0},
               "time":{
                  "lun":0,
                  "jie":0
               }
            }});
         }
      }
      
      private function currLunAndJie() : Object
      {
         var _loc21_:* = 0;
         var _loc19_:* = 0;
         var _loc5_:Object = null;
         var _loc2_:Number = NaN;
         var _loc16_:Date = null;
         var _loc9_:Number = NaN;
         var _loc4_:Date = null;
         var _loc11_:Number = NaN;
         var _loc10_:Number = NaN;
         var _loc8_:Number = NaN;
         var _loc6_:Number = NaN;
         var _loc15_:Number = NaN;
         var _loc13_:Number = NaN;
         var _loc14_:Date = null;
         var _loc1_:Object = getTimeOutSchedule();
         var _loc3_:Date = new Date();
         _loc3_.setTime((GlobalData.$mGuild_simple.the_guild_pvp.time.start_time as Date).time + GlobalConfig.HOURS_8_MS);
         _now = SendAndSelect.$systemTimer_nowSecond * 1000;
         _now = Tools.getServerNowTimeDate(_now).time;
         var _loc23_:Number = (_now - _loc3_.time) % (GlobalData.$mGuild_simple.the_guild_pvp.time.cycle * 1000 * 60);
         var _loc18_:Date = new Date();
         _loc18_.setTime(_now - _loc23_);
         _cfg.start_time = _loc18_;
         var _loc22_:Array = [];
         var _loc24_:Array = [];
         var _loc25_:Date = new Date();
         _loc25_.setTime((_cfg.start_time as Date).time + (_cfg.guild_sign_up + _cfg.match + _cfg.member_sign_up * 7 + _cfg.get_ready * 7 + _cfg.fight * 7 + _cfg.interval * 6) * 1000 * 60);
         var _loc7_:Date = new Date();
         _loc7_.setTime((_cfg.start_time as Date).time + _cfg.guild_sign_up * 1000 * 60);
         _loc21_ = 0;
         while(_loc21_ < 7)
         {
            _loc19_ = uint(_loc21_ ? 1 : 0);
            _loc5_ = {};
            _loc2_ = (_cfg.start_time as Date).time + (_cfg.guild_sign_up * _loc19_ + _cfg.match * _loc19_ + _cfg.member_sign_up * _loc21_ + _cfg.get_ready * _loc21_ + _cfg.fight * _loc21_ + _cfg.interval * _loc21_) * 1000 * 60;
            _loc16_ = new Date();
            _loc16_.setTime((_cfg.start_time as Date).time + (_cfg.guild_sign_up + _cfg.match + _cfg.member_sign_up * _loc21_ + _cfg.get_ready * _loc21_ + _cfg.fight * _loc21_ + _cfg.interval * _loc21_) * 1000 * 60);
            _loc5_.start = _loc16_;
            _loc16_ = null;
            _loc16_ = new Date();
            _loc16_.setTime((_cfg.start_time as Date).time + (_cfg.guild_sign_up + _cfg.match + _cfg.member_sign_up * (_loc21_ + 1) + _cfg.get_ready * _loc21_ + _cfg.fight * _loc21_ + _cfg.interval * _loc21_) * 1000 * 60);
            _loc5_.end = _loc16_;
            _loc24_.push(_loc5_);
            _loc9_ = (_cfg.start_time as Date).time + (_cfg.guild_sign_up * _loc19_ + _cfg.match * _loc19_ + _cfg.member_sign_up * _loc21_ + _cfg.get_ready * _loc21_ + _cfg.fight * _loc21_ + _cfg.interval * _loc21_) * 1000 * 60;
            _loc4_ = new Date();
            _loc4_.setTime(_loc9_);
            _loc22_.push(_loc4_);
            _loc21_++;
         }
         userTime.FightStartTime = _cfg.start_time;
         userTime.guildBMendTime = _loc7_;
         userTime.memberTimeArr = _loc24_;
         userTime.FightOverTime = _loc25_;
         var _loc12_:Date = new Date();
         _loc12_.setTime((_cfg.start_time as Date).time + _cfg.cycle * 1000 * 60);
         userTime.NextGameTime = _loc12_;
         _loc21_ = 0;
         while(_loc21_ < 7)
         {
            if(!_loc22_[_loc21_ + 1])
            {
               if((_loc22_[_loc21_] as Date).time < _now && (_loc22_[_loc21_] as Date).time + (_cfg.member_sign_up + _cfg.get_ready + _cfg.fight) * 1000 * 60 > _now)
               {
                  lun = _loc21_ + 1;
               }
               break;
            }
            if((_loc22_[_loc21_] as Date).time < _now && (_loc22_[_loc21_ + 1] as Date).time > _now)
            {
               lun = _loc21_ + 1;
            }
            _loc21_++;
         }
         var _loc17_:uint = lun == 1 ? 6 : (lun == 7 ? 3 : (lun == 0 ? 0 : 4));
         var _loc20_:Array = [];
         if(_loc17_ == 6)
         {
            _loc11_ = (_loc22_[lun - 1] as Date).time;
            _loc10_ = (_loc22_[lun - 1] as Date).time + _cfg.guild_sign_up * 1000 * 60;
            _loc8_ = (_loc22_[lun - 1] as Date).time + (_cfg.guild_sign_up + _cfg.match) * 1000 * 60;
            _loc6_ = (_loc22_[lun - 1] as Date).time + (_cfg.guild_sign_up + _cfg.match + _cfg.member_sign_up) * 1000 * 60;
            _loc15_ = (_loc22_[lun - 1] as Date).time + (_cfg.guild_sign_up + _cfg.match + _cfg.member_sign_up + _cfg.get_ready) * 1000 * 60;
            _loc13_ = (_loc22_[lun - 1] as Date).time + (_cfg.guild_sign_up + _cfg.match + _cfg.member_sign_up + _cfg.get_ready + _cfg.fight) * 1000 * 60;
            _loc20_.push(_loc11_);
            _loc20_.push(_loc10_);
            _loc20_.push(_loc8_);
            _loc20_.push(_loc6_);
            _loc20_.push(_loc15_);
            _loc20_.push(_loc13_);
         }
         if(_loc17_ == 4)
         {
            _loc8_ = (_loc22_[lun - 1] as Date).time;
            _loc6_ = (_loc22_[lun - 1] as Date).time + _cfg.member_sign_up * 1000 * 60;
            _loc15_ = (_loc22_[lun - 1] as Date).time + (_cfg.member_sign_up + _cfg.get_ready) * 1000 * 60;
            _loc13_ = (_loc22_[lun - 1] as Date).time + (_cfg.member_sign_up + _cfg.get_ready + _cfg.fight) * 1000 * 60;
            _loc20_.push(_loc8_);
            _loc20_.push(_loc6_);
            _loc20_.push(_loc15_);
            _loc20_.push(_loc13_);
         }
         if(_loc17_ == 3)
         {
            _loc8_ = (_loc22_[lun - 1] as Date).time;
            _loc6_ = (_loc22_[lun - 1] as Date).time + _cfg.member_sign_up * 1000 * 60;
            _loc15_ = (_loc22_[lun - 1] as Date).time + (_cfg.member_sign_up + _cfg.get_ready) * 1000 * 60;
            _loc20_.push(_loc8_);
            _loc20_.push(_loc6_);
            _loc20_.push(_loc15_);
         }
         _loc21_ = 0;
         while(_loc21_ < _loc17_)
         {
            _loc4_ = new Date();
            _loc4_.setTime(_loc20_[_loc21_]);
            if(!_loc20_[_loc21_ + 1])
            {
               if(_loc17_ == 6 || _loc17_ == 4)
               {
                  _loc14_.setTime(_loc13_ + _cfg.interval * 1000 * 60);
                  if(_loc4_.time < _now && _loc14_.time > _now)
                  {
                     jie = 6;
                  }
               }
               if(_loc17_ == 3)
               {
                  _loc14_.setTime(_loc15_ + _cfg.fight * 1000 * 60);
                  if(_loc4_.time < _now && _loc14_.time > _now)
                  {
                     jie = 5;
                  }
               }
               break;
            }
            _loc14_ = new Date();
            _loc14_.setTime(_loc20_[_loc21_ + 1]);
            if(_loc4_.time < _now && _loc14_.time > _now)
            {
               if(_loc17_ == 3 || _loc17_ == 4)
               {
                  jie = _loc21_ + 3;
               }
               if(_loc17_ == 6)
               {
                  jie = _loc21_ + 1;
               }
            }
            _loc21_++;
         }
         return {
            "lun":lun,
            "jie":jie
         };
      }
      
      private function onReFUN(param1:Object) : void
      {
         if(param1.data.res_code == -1)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97835),true);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
            return;
         }
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_kook_logbuch",false,true,param1);
      }
      
      private function onReFun(param1:Object) : void
      {
         if(param1.data.res_code == -1)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97835),true);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
            return;
         }
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_guild_ranklist",false,true,param1);
      }
      
      private function F5List(param1:uint) : void
      {
         delList();
         if(param1)
         {
            objPVP = GlobalData.$mGuild_simple.the_guild_pvp;
            guildLvPVP = objPVP.need_guild_lv;
            objBoss = GlobalData.$mGuild_simple.guild_BOSS;
            guildLvBoss = objBoss.need_guild_lv;
            objShop = GlobalData.$mGuild_simple.guild_shop;
            guildLvShop = objShop.need_guild_lv;
            objStudy = GlobalData.$mGuild_simple.guild_contribute_info;
            guildLvStudy = objStudy.need_guild_lv;
            mTabBar.setChildStatus(1,true,tabBar_changeHandler_false);
            mTabBar.setChildStatus(2,true,tabBar_changeHandler_false);
            mTabBar.setChildStatus(3,true,tabBar_changeHandler_false);
            mTabBar.setChildStatus(4,true,tabBar_changeHandler_false);
            if(!objPVP.open_status)
            {
               mTabBar.setChildStatus(1,objPVP.open_status ? true : false,tabBar_changeHandler_open);
            }
            if(!objBoss.open_status)
            {
               mTabBar.setChildStatus(2,objBoss.open_status ? true : false,tabBar_changeHandler_open);
            }
            if(!objShop.open_status)
            {
               mTabBar.setChildStatus(3,objShop.open_status ? true : false,tabBar_changeHandler_open);
            }
            if(objStudy.open_status)
            {
               mTabBar.setChildStatus(4,objStudy.open_status ? true : false,tabBar_changeHandler_open);
            }
            if(mRadioBar)
            {
               mRadioBar.visible = false;
               mRadioBar.touchable = false;
            }
            if(_bg2)
            {
               _bg2.height = 30;
            }
            if(mBg_list)
            {
               mBg_list.y = _bg2.y + _bg2.height;
            }
            RefreshGuildList();
         }
         else
         {
            mTabBar.setChildStatus(1,false,onFalseHandel);
            mTabBar.setChildStatus(2,false,onFalseHandel);
            mTabBar.setChildStatus(3,false,onFalseHandel);
            mTabBar.setChildStatus(4,false,onFalseHandel);
            if(_bg2)
            {
               _bg2.height = 80;
            }
            if(mBg_list)
            {
               mBg_list.y = _bg2.y + _bg2.height;
            }
            if(mRadioBar)
            {
               mRadioBar.visible = true;
               mRadioBar.touchable = true;
            }
            RefreshNoGuildList();
         }
      }
      
      private function onFalseHandel(param1:int) : void
      {
         var _loc2_:String = null;
         if(mTabBar)
         {
            if(!mTabBar.getActiveTabs(param1).isToggle)
            {
               _loc2_ = GlobalData.$mConfig_simple.show_id[8];
               GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(97860),{"aid":_loc2_});
            }
         }
      }
      
      private function RefreshNoGuildList() : void
      {
         SendServiceAMFFun.send_user_get_association_list(NoGuildList,{});
      }
      
      private function NoGuildList(param1:Object) : void
      {
         listInfo = param1.data.info;
         GlobalData.$userGuild.info = param1;
         setList_Guild();
         addList_Guild();
      }
      
      private function setList_Guild() : void
      {
         var _loc3_:Number = NaN;
         var _loc2_:Object = null;
         var _loc1_:VerticalLayout = null;
         if(this.mList == null)
         {
            _loc3_ = 170;
            _loc2_ = {
               "paging":0,
               "gap":5,
               "horizontalGap":30,
               "verticalGap":20,
               "paddingTop":10,
               "paddingRight":0,
               "paddingBottom":40,
               "paddingLeft":22,
               "horizontalAlign":"center",
               "verticalAlign":"top"
            };
            _loc1_ = new VerticalLayout();
            _loc1_.paddingLeft = _loc2_.paddingLeft;
            _loc1_.gap = _loc2_.gap;
            this.mList = new List();
            this.mList.isSelectable = false;
            this.mList.width = GlobalData.$mStageWidth - 20;
            this.mList.height = GlobalData.$center_height - 190;
            this.mList.layout = _loc1_;
            this.mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
            this.mList.x = int((GlobalData.$mStageWidth - this.mList.width) * 0.5);
            this.mList.y = _bg2.y + _bg2.height + 33;
            this.mList.snapScrollPositionsToPixels = true;
            this.addChild(this.mList);
            _loc2_ = null;
            _loc1_ = null;
            this.mList.dataProvider = new ListCollection();
         }
      }
      
      private function addList_Guild() : void
      {
         var _loc4_:Array = null;
         var _loc1_:VerticalLayout = null;
         var _loc2_:Array = null;
         var _loc3_:String = null;
         var _loc5_:String = null;
         if(!mRadioBar)
         {
            if(this.mTabBar.selectedIndex == 0)
            {
               _loc4_ = [];
               _loc4_.push({"label":GlobalLanguageStr.getLanguageStr(97677)});
               _loc4_.push({"label":GlobalLanguageStr.getLanguageStr(97673)});
               _loc4_.push({"label":GlobalLanguageStr.getLanguageStr(97678)});
               this.setRadioBar(_loc4_,radioBar_Change,radioBar_Complete,125);
               this.mRadioBar.x = 20;
               this.mRadioBar.y = _bg2.y + 10;
            }
            else
            {
               _loc4_ = [];
               _loc4_.push({"label":GlobalLanguageStr.getLanguageStr(97677)});
               _loc4_.push({"label":GlobalLanguageStr.getLanguageStr(97673)});
               _loc4_.push({"label":GlobalLanguageStr.getLanguageStr(97678)});
               this.setRadioBar(_loc4_,radioBar_Change,radioBar_Complete,125);
               this.mRadioBar.x = 20;
               this.mRadioBar.y = _bg2.y + 10;
            }
         }
         if(this.mTabBar && this.mTabBar.selectedIndex == 0)
         {
            if(this.mRadioBar.selectedIndex == 0)
            {
               if(listInfo == null)
               {
                  noGuild = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97763),20,16777215,"left",500,35);
                  this.addChild(noGuild);
                  noGuild.x = GlobalData.$mStageWidth / 2 - noGuild.width / 2 + 20;
                  noGuild.y = GlobalData.$center_height / 2 - noGuild.height / 2 + 85;
               }
               else
               {
                  _loc1_ = new VerticalLayout();
                  _loc1_.paddingLeft = 13;
                  _loc1_.gap = 25;
                  _loc1_.paddingBottom = 25;
                  mList.layout = _loc1_;
                  _loc2_ = GlobalFunction.cloneArray(listInfo);
                  _loc2_.sortOn(["flag","level","total_alive","member_count"],[0x10 | 2,0x10 | 2,0x10 | 2,0x10 | 2]);
                  this.setListTimer(mList,_loc2_,ItemGuild,false,currGuildIndex);
               }
            }
            if(this.mRadioBar.selectedIndex == 1)
            {
               cfg = GlobalData.$mGuild_simple.the_guild_info;
               GlobalData.$userGuild.guild_icon = 0;
               _loc3_ = cfg.create_gold;
               _loc5_ = cfg.create_coin;
               guildShopCase = GlobalFunction.createScale9Image("UI_guildShop_box_0_0000",590,GlobalData.$mStageHeight > 960 ? 630 : 512,new Rectangle(219,153,15,15));
               guildShopCase.x = int((GlobalData.$mStageWidth - guildShopCase.width) * 0.5 - 1);
               guildShopCase.y = _bg2.y + _bg2.height + 60;
               addChild(guildShopCase);
               guildShopBg = GlobalFunction.createImage("UI_guildShop_bg_0_0000",true);
               guildShopBg.width = 530;
               if(GlobalData.$mStageHeight > 960)
               {
                  guildShopBg.height = 546;
               }
               else
               {
                  guildShopBg.height = 455;
               }
               guildShopBg.x = guildShopCase.x + 35;
               guildShopBg.y = guildShopCase.y + 44;
               addChildAt(guildShopBg,this.numChildren - 1);
               foundGuild1 = GlobalFunction.createScale9Image("UI_guildShop_bg_2_0000",500,100,new Rectangle(30,30,58,30));
               foundGuild1.x = int((GlobalData.$mStageWidth - foundGuild1.width) * 0.5 - 1);
               foundGuild1.y = _bg2.y + _bg2.height + 113 + (GlobalData.$mStageHeight > 960 ? (GlobalData.$mStageHeight - 960) / 3 : 0);
               foundGuild2 = GlobalFunction.createScale9Image("UI_guildShop_bg_2_0000",500,130,new Rectangle(30,30,58,30));
               foundGuild2.x = foundGuild1.x;
               foundGuild2.y = foundGuild1.y + foundGuild1.height;
               foundGuild3 = GlobalFunction.createScale9Image("UI_guildShop_bg_2_0000",500,130,new Rectangle(30,30,58,30));
               foundGuild3.x = foundGuild2.x;
               foundGuild3.y = foundGuild2.y + foundGuild2.height;
               this.addChild(foundGuild1);
               this.addChild(foundGuild2);
               this.addChild(foundGuild3);
               guildShopRedCloth = GlobalFunction.createImage("UI_guildShop_bar_0_0000",true);
               guildShopRedCloth.x = GlobalData.$mStageWidth / 2 - guildShopRedCloth.width / 2 + 20;
               guildShopRedCloth.y = guildShopCase.y - 30;
               addChild(guildShopRedCloth);
               shopStrangeTxt = GlobalFunction.createImage("UI_found_guild_title_0_0000",true);
               shopStrangeTxt.x = int((guildShopRedCloth.width - shopStrangeTxt.width) * 0.5 + 28);
               shopStrangeTxt.y = guildShopRedCloth.y + 20;
               addChild(shopStrangeTxt);
               guildName = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97668),20,16777215,"left",300,46);
               guildName.x = foundGuild1.x + 20;
               guildName.y = foundGuild1.y + foundGuild1.height / 2 - guildName.height / 2;
               this.addChild(guildName);
               myInput = new LOL_TextInput(true);
               myInput.restrict = "[一-龥A-Za-z0-9_]+$";
               myInput.width = 220;
               myInput.height = 50;
               myInput.x = guildName.textBounds.x + guildName.textBounds.width + 85;
               myInput.y = guildName.y - 12;
               myInput.focusHandler = onFOCUS;
               this.addChild(myInput);
               foundGuildText = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97669,guildNameNum),18,16777215,"left",300,35);
               foundGuildText.x = myInput.x;
               foundGuildText.y = myInput.y + myInput.height;
               addChild(foundGuildText);
               guildTxT = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97670),20,16777215,"left",300,46);
               guildTxT.x = guildName.x;
               guildTxT.y = foundGuild2.y + foundGuild2.height / 2 - guildTxT.height / 2;
               this.addChild(guildTxT);
               guildImg = GlobalFunction.createImage("UI_guild_logo_0000");
               guildImg.x = guildTxT.x + 150;
               guildImg.y = guildTxT.y + (guildTxT.height / 2 - guildImg.height / 2);
               addChild(guildImg);
               guildAmendBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(97838),160,64,"UI_btn_guild_2_0000");
               guildAmendBtn.fontSize = 21;
               guildAmendBtn.fontColor = 16777215;
               guildAmendBtn.x = guildImg.x + guildImg.width + 30;
               guildAmendBtn.y = guildImg.y + 20;
               this.addChild(guildAmendBtn);
               guildAmendBtn.addEventListener("triggered",btnTriggered);
               foundMoneyTxT = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97672),20,16777215,"left",300,46);
               foundMoneyTxT.x = guildTxT.x;
               foundMoneyTxT.y = foundGuild3.y + 20;
               this.addChild(foundMoneyTxT);
               imageL = GlobalFunction.createScale9Image("UI_guild_bg_4_0000",155,40,new Rectangle(10,10,5,5));
               imageL.x = foundMoneyTxT.x + 101;
               imageL.y = foundMoneyTxT.y;
               addChild(imageL);
               moneyL = new LOL_MutilTextFieldIcon("",_loc3_,"UI_money_gold_0_0000",16777215,16777215,18);
               moneyL.x = imageL.x - 5;
               moneyL.y = imageL.y + 5;
               addChild(moneyL);
               foundGuildLBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(97714),125,50,"UI_btn_guild_2_0000");
               foundGuildLBtn.fontSize = 21;
               foundGuildLBtn.fontColor = 16777215;
               foundGuildLBtn.name = "found_guild_l_btn";
               foundGuildLBtn.x = guildAmendBtn.x + guildAmendBtn.width - foundGuildLBtn.width;
               foundGuildLBtn.y = moneyL.y - 10;
               this.addChild(foundGuildLBtn);
               foundGuildLBtn.addEventListener("triggered",onFoundGuildBtn);
               imageGold = GlobalFunction.createScale9Image("UI_guild_bg_4_0000",195,40,new Rectangle(10,10,5,5));
               imageGold.x = imageL.x;
               imageGold.y = imageL.y + imageL.height + 10;
               addChild(imageGold);
               moneyGold = new LOL_MutilTextFieldIcon("",_loc5_ + GlobalLanguageStr.getLanguageStr(97716),"UI_money_coin_0_0000",16777215,16777215,18);
               moneyGold.x = imageGold.x - 5;
               moneyGold.y = imageGold.y + 5;
               this.addChild(moneyGold);
               foundGuildGBtn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(97715),125,50,"UI_btn_guild_2_0000");
               foundGuildGBtn.fontSize = 21;
               foundGuildGBtn.fontColor = 16777215;
               foundGuildGBtn.name = "found_guild_g_btn";
               foundGuildGBtn.x = guildAmendBtn.x + guildAmendBtn.width - foundGuildGBtn.width;
               foundGuildGBtn.y = imageGold.y - 5;
               this.addChild(foundGuildGBtn);
               foundGuildGBtn.addEventListener("triggered",onFoundGuildBtn);
               downText = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97933,GlobalData.$mGuild_simple.the_guild_info.create_gold_lv),20,16764006,"center",300,29);
               downText.x = GlobalData.$mStageWidth / 2 - downText.width / 2;
               downText.y = foundGuild3.y + foundGuild3.height - 5 + (GlobalData.$mStageHeight > 960 ? 30 : 0);
               this.addChild(downText);
               downText1 = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97934,GlobalData.$mGuild_simple.the_guild_info.create_coin_lv),20,16764006,"center",300,29);
               downText1.x = GlobalData.$mStageWidth / 2 - downText1.width / 2;
               downText1.y = downText.y + downText.height;
               this.addChild(downText1);
            }
            if(this.mRadioBar.selectedIndex == 2)
            {
               textfield = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97675),20,16777215,"center",300,35);
               textfield.x = -textfield.textBounds.x + 60;
               textfield.y = 220;
               this.addChild(textfield);
               m_input = new LOL_TextInput(true);
               m_input.width = 200;
               m_input.height = 50;
               m_input.maxChars = 6;
               m_input.x = textfield.textBounds.width + 65;
               m_input.y = textfield.y + textfield.height / 2 - m_input.height / 2;
               this.addChild(m_input);
               findText = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97785),18,16777215,"left",300,35);
               findText.x = m_input.x;
               findText.y = m_input.y + m_input.height;
               addChild(findText);
               btn = new LOL_Scale9Button("    " + GlobalLanguageStr.getLanguageStr(97676),145,64,"UI_btn_guild_4_0000");
               btn.fontColor = 16777215;
               btn.fontSize = 21;
               btn.x = m_input.x + m_input.width + 30;
               btn.y = m_input.y - 3;
               btn.addEventListener("triggered",onbtnTriggered);
               this.addChild(btn);
               findImg = GlobalFunction.createImage("UI_btn_guildFind_3_0000",true);
               findImg.x = btn.x + 34;
               findImg.y = btn.y + 18;
               addChild(findImg);
            }
         }
         if(this.mTabBar && this.mTabBar.selectedIndex == 1)
         {
         }
         if(this.mTabBar && this.mTabBar.selectedIndex == 2)
         {
         }
      }
      
      private function RefreshGuildList() : void
      {
         var _loc1_:String = null;
         var _loc4_:int = 0;
         var _loc2_:String = null;
         var _loc5_:* = 0;
         checkGuildGuide();
         objPVP = GlobalData.$mGuild_simple.the_guild_pvp;
         guildLvPVP = objPVP.need_guild_lv;
         objBoss = GlobalData.$mGuild_simple.guild_BOSS;
         guildLvBoss = objBoss.need_guild_lv;
         objShop = GlobalData.$mGuild_simple.guild_shop;
         guildLvShop = objShop.need_guild_lv;
         objStudy = GlobalData.$mGuild_simple.guild_contribute_info;
         guildLvStudy = objStudy.need_guild_lv;
         mTabBar.setChildStatus(1,GlobalData.$userGuild.GuildList.data.association_info.level >= guildLvPVP ? true : false,tabBar_changeHandler_false);
         mTabBar.setChildStatus(2,GlobalData.$userGuild.GuildList.data.association_info.level >= guildLvBoss ? true : false,tabBar_changeHandler_false);
         mTabBar.setChildStatus(3,GlobalData.$userGuild.GuildList.data.association_info.level >= guildLvShop ? true : false,tabBar_changeHandler_false);
         mTabBar.setChildStatus(4,GlobalData.$userGuild.GuildList.data.association_info.level >= guildLvStudy ? true : false,tabBar_changeHandler_false);
         if(!objPVP.open_status)
         {
            mTabBar.setChildStatus(1,objPVP.open_status ? true : false,tabBar_changeHandler_open);
         }
         if(!objBoss.open_status)
         {
            mTabBar.setChildStatus(2,objBoss.open_status ? true : false,tabBar_changeHandler_open);
         }
         if(!objShop.open_status)
         {
            mTabBar.setChildStatus(3,objShop.open_status ? true : false,tabBar_changeHandler_open);
         }
         if(!objStudy.open_status)
         {
            mTabBar.setChildStatus(4,objStudy.open_status ? true : false,tabBar_changeHandler_open);
         }
         var _loc3_:Object = GlobalFunction.get_HelpLink(GlobalLanguageStr.getLanguageStr(97850));
         _spRule = _loc3_.ui;
         _spRule.x = GlobalData.$mStageWidth - _loc3_.w - 32;
         _spRule.y = int((this.mTabBar.height - _spRule.height) * 0.5 + 67);
         addChild(_spRule);
         _spRule.addEventListener("touch",ruleTouch);
         if(mTabBar && mTabBar.selectedIndex == 0)
         {
            _bg2.height = 55;
            mBg_list.y = _bg2.y + _bg2.height;
            cfg = GlobalData.$mGuild_simple.guild_level["level_" + GuildInfo.data.association_info.level];
            maxGuildMember = cfg.max_member_length;
            _loc1_ = GuildInfo.data.association_info.icon < 10 ? "0" + GuildInfo.data.association_info.icon : GuildInfo.data.association_info.icon;
            icon = GlobalFunction.createImage("UI_guild_logo_00" + _loc1_);
            icon.x = mBg_list.x + 38;
            icon.y = mBg_list.y + 35;
            this.addChild(icon);
            // Keep the guild name and level on separate rows. The old inline
            // suffix made long names run underneath the management buttons.
            guildName = GlobalTextStyle.getTextField(GuildInfo.data.association_info.name,19,16777215,"left",300,35);
            this.addChild(guildName);
            guildName.x = icon.x + icon.width + 5;
            guildName.y = icon.y - 5;
            guildLV = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(98151,GuildInfo.data.association_info.level),18,16777215,"left",220,32);
            guildLV.x = guildName.x;
            guildLV.y = guildName.y + 30;
            this.addChild(guildLV);
            _loc4_ = int(GuildInfo.data.association_info.id);
            _loc2_ = "" + (10000 + _loc4_);
            guildID = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97724,"" + _loc2_),19,16777215,"left",200,46);
            this.addChild(guildID);
            guildID.x = guildName.x;
            guildID.y = guildLV.y + 30;
            guildNum = GlobalTextStyle.getHtmlTextRenderer();
            guildNum.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97723,GuildInfo.data.member_list.length,maxGuildMember),GlobalTextStyle.COLOR_W_R_R_R,30,19);
            this.addChild(guildNum);
            guildNum.x = guildID.x;
            guildNum.y = guildID.y + 30;
            _btnGuildDay = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(97728),140,64,"UI_btn_guild_4_0000");
            _btnGuildDay.name = "btn_name_guild_day";
            _btnGuildDay.fontColor = 16777215;
            _btnGuildDay.addEventListener("triggered",onBtnGuildTouch);
            _btnGuildDay.x = mBg_list.x + mBg_list.width - _btnGuildDay.width - 37;
            _btnGuildDay.y = mBg_list.y + 28;
            this.addChild(_btnGuildDay);
            _btnGuildManager = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(97727),140,64,"UI_btn_guild_4_0000");
            _btnGuildManager.name = "btn_name_guild_manager";
            _btnGuildManager.fontColor = 16777215;
            _btnGuildManager.addEventListener("triggered",onBtnGuildTouch);
            _btnGuildManager.x = _btnGuildDay.x - _btnGuildDay.width - 5;
            _btnGuildManager.y = _btnGuildDay.y;
            guildName.width = guildLV.width = Math.max(120,_btnGuildManager.x - guildName.x - 12);
            this.addChild(_btnGuildManager);
            _btnGuildActive = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(97725),140,64,"UI_btn_guild_4_0000");
            _btnGuildActive.name = "btn_name_guild_active";
            _btnGuildActive.fontColor = 16777215;
            _btnGuildActive.addEventListener("triggered",onBtnGuildTouch);
            _btnGuildActive.x = _btnGuildManager.x;
            _btnGuildActive.y = _btnGuildManager.y + _btnGuildManager.height - 2;
            this.addChild(_btnGuildActive);
            _loc5_ = 0;
            while(_loc5_ < GuildInfo.data.member_list.length)
            {
               if(GuildInfo.data.member_list[_loc5_].uid == GlobalData.$userData.uid && GuildInfo.data.member_list[_loc5_].zone == GlobalData.$userData.zone)
               {
                  if(GuildInfo.data.member_list[_loc5_].association_lv > 1)
                  {
                     _btnGuildManager.enabled = false;
                  }
               }
               _loc5_++;
            }
            _btnGuildAther = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(97726),140,64,"UI_btn_guild_4_0000");
            _btnGuildAther.name = "btn_name_guild_ather";
            _btnGuildAther.fontColor = 16777215;
            _btnGuildAther.addEventListener("triggered",onBtnGuildTouch);
            _btnGuildAther.x = _btnGuildDay.x;
            _btnGuildAther.y = _btnGuildActive.y;
            this.addChild(_btnGuildAther);
            guildDeclarationTxt = GlobalTextStyle.getTextField("公会公告：" + GlobalLanguageStr.getLanguageStr(97927),20,16764006,"left",500,46);
            guildDeclarationTxt.x = icon.x;
            guildDeclarationTxt.y = Math.max(_btnGuildActive.y + _btnGuildActive.height - 10,guildNum.y + 24);
            guildDeclarationTxt.height = 30;
            addChild(guildDeclarationTxt);
            // guildNotice is a TextFieldHtmlRenderer used by other tabs; do
            // not reuse it as a String. association_is returns content/notice
            // as strings, and assigning one to that typed renderer throws AS
            // Error #1034 before the member list is built.
            if(GuildInfo.data.association_info.content != null && String(GuildInfo.data.association_info.content) != "")
            {
               _loc1_ = String(GuildInfo.data.association_info.content);
            }
            else if(GuildInfo.data.association_info.notice != null && String(GuildInfo.data.association_info.notice) != "")
            {
               _loc1_ = String(GuildInfo.data.association_info.notice);
            }
            if(_loc1_ != null && _loc1_ != "")
            {
               guildDeclarationTxt.text = GlobalLanguageStr.getLanguageStr(97729,_loc1_);
            }
            setListGuildPanel();
            addListGuildPanel();
            if(GlobalData.$userData.attrs.association_lv != 3 && GuildInfo.data.association_info.association_application > 0)
            {
               mTag_a = GlobalFunction.getTagPopTip(1,false);
               mTag_a.x = _btnGuildManager.x + _btnGuildManager.width - 23;
               mTag_a.y = _btnGuildManager.y - 5;
               addChild(mTag_a);
            }
         }
         else if(mTabBar && mTabBar.selectedIndex == 1)
         {
         }
      }
      
      private function tabBar_changeHandler_open(param1:int) : void
      {
         var _loc2_:String = GlobalData.$mConfig_simple.show_id[8];
         GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(90046),{"aid":_loc2_});
      }
      
      private function updataTag(param1:Event) : void
      {
         if(mTag_a)
         {
            if(param1.data.length == 0)
            {
               mTag_a.visible = false;
            }
         }
      }
      
      private function addListGuildPanel() : void
      {
         var _loc3_:* = 0;
         var _loc1_:VerticalLayout = new VerticalLayout();
         _loc1_.paddingLeft = 17;
         _loc1_.gap = -10;
         _loc1_.paddingBottom = -10;
         _loc1_.paddingTop = -4;
         mList.layout = _loc1_;
         var _loc2_:Array = GlobalFunction.cloneArray(GuildInfo.data.member_list);
         _loc3_ = 0;
         while(_loc3_ < _loc2_.length)
         {
            _loc2_[_loc3_].return_code = GuildInfo.data.return_code;
            _loc2_[_loc3_].worship_info = GuildInfo.data.user.worship_info;
            _loc2_[_loc3_].method = "chat_private";
            _loc3_++;
         }
         _loc2_.sortOn(["association_lv","lv","vip_lv","power"],[16,0x10 | 2,0x10 | 2,0x10 | 2]);
         this.setListTimer(mList,_loc2_,ItemGuildPanel,false);
      }
      
      private function setListGuildPanel() : void
      {
         var _loc2_:Object = null;
         var _loc1_:VerticalLayout = null;
         if(this.mList == null)
         {
            _loc2_ = {
               "paging":0,
               "gap":-27,
               "horizontalGap":30,
               "verticalGap":20,
               "paddingTop":15,
               "paddingRight":0,
               "paddingBottom":40,
               "paddingLeft":17,
               "horizontalAlign":"center",
               "verticalAlign":"top"
            };
            _loc1_ = new VerticalLayout();
            _loc1_.paddingLeft = _loc2_.paddingLeft;
            _loc1_.gap = _loc2_.gap;
            this.mList = new List();
            this.mList.isSelectable = false;
            this.mList.width = GlobalData.$mStageWidth - 20;
            this.mList.height = GlobalData.$center_height - 315;
            this.mList.layout = _loc1_;
            this.mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
            this.mList.x = int((GlobalData.$mStageWidth - this.mList.width) * 0.5);
            this.mList.y = Math.max(_btnGuildAther.y + _btnGuildAther.height + 21,guildDeclarationTxt ? guildDeclarationTxt.y + guildDeclarationTxt.height + 8 : 0);
            this.mList.snapScrollPositionsToPixels = true;
            this.addChild(this.mList);
            _loc2_ = null;
            _loc1_ = null;
            this.mList.dataProvider = new ListCollection();
         }
      }
      
      private function onFoundGuildBtn(param1:Event) : void
      {
         var _loc2_:* = null;
         var _loc5_:Object = null;
         var _loc6_:Object = null;
         var _loc7_:int = int(cfg.create_gold);
         var _loc4_:int = int(cfg.create_coin);
         if(myInput && myInput.text.length > guildNameNum)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97669,guildNameNum),true);
            return;
         }
         if(myInput && myInput.text == "")
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97848),true);
            return;
         }
         if(myInput.text.indexOf("*") != -1)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97964),true);
            return;
         }
         if(Tools.hasText(myInput.text,Tools.BAN_LIST.concat(Tools.BAN_LIST3)))
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97718),true);
            return;
         }
         var _loc3_:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         if(_loc3_.name == "found_guild_l_btn")
         {
            pay = 0;
            if(GlobalData.$userData.gold < _loc7_)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10023),false,"A_6999_3");
               return;
            }
            _loc5_ = {
               "ok":sendService,
               "okA":["Pop"],
               "no":GlobalFunction.functionNull,
               "aid":"A_1001_3"
            };
            GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97679,_loc7_,GlobalLanguageStr.getLanguageStr(20162),"1"),GlobalTextStyle.COLOR_W_Y_Y_G),_loc5_,true,null,false,true);
         }
         if(_loc3_.name == "found_guild_g_btn")
         {
            pay = 1;
            if(GlobalData.$userData.coin < _loc4_)
            {
               GlobalFunction.popErrorCoin(_loc4_);
               return;
            }
            _loc6_ = {
               "ok":sendService,
               "okA":["Pop"],
               "no":GlobalFunction.functionNull,
               "aid":"A_1001_3"
            };
            GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97679,_loc4_,GlobalLanguageStr.getLanguageStr(20149),"2"),GlobalTextStyle.COLOR_W_Y_Y_G),_loc6_,true,null,false,true);
         }
      }
      
      private function sendService() : void
      {
         GlobalData.$mGameClassObject.closePopUp();
         var _loc1_:int = int(GlobalData.$userGuild.guild_icon);
         SendServiceAMFFun.send_user_add_association(captureVipBefore(onTrue),{
            "icon":_loc1_,
            "flag":pay,
            "name":myInput.text
         });
      }
      
      private function onTrue(param1:Object) : void
      {
         if(this.stage == null) return;
         if(param1.data.res_code == 1)
         {
            showVipTransition(param1);
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.vip_exp = param1.data.user_dict.vip_exp;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.vip_lv = param1.data.user_dict.vip_lv;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.coin = param1.data.user_dict.coin;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.gold = param1.data.user_dict.gold;
            }
            GlobalFunction.updateVip();
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
            SendServiceAMFFun.send_user_associatione_is(onReGuild,{});
         }
         else
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97719),true);
         }
         if(param1.data.res_code == -1)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97861),true);
            SendServiceAMFFun.send_user_associatione_is(onReGuild,{});
         }
      }
      
      private function onFOCUS(param1:String) : void
      {
         switch(param1)
         {
            case "focusIn":
            case "focusOut":
               break;
            case "change":
               myInput.text = GlobalFunction.filterString(myInput.text);
         }
      }
      
      private function onbtnTriggered(param1:Event) : void
      {
         if(m_input && m_input.text == "")
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90123),true);
            return;
         }
         if(isNumeric(m_input.text))
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97706),true);
            return;
         }
         if(m_input.text.length != 5)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97705),true);
            return;
         }
         SendServiceAMFFun.send_user_find_association(onFindGuild,{"id":m_input.text});
      }
      
      private function onFindGuild(param1:Object) : void
      {
         var _loc3_:Scale9Textures = null;
         var _loc2_:String = null;
         delFind();
         findText = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97785),18,16777215,"left",300,35);
         findText.x = m_input.x;
         findText.y = m_input.y + m_input.height;
         addChild(findText);
         btn.text = "    " + GlobalLanguageStr.getLanguageStr(97676);
         btn.x = m_input.x + m_input.width + 30;
         btn.y = m_input.y - 3;
         findImg = GlobalFunction.createImage("UI_btn_guildFind_3_0000",true);
         findImg.x = btn.x + 34;
         findImg.y = btn.y + 18;
         addChild(findImg);
         if(param1.data.res_code == 1)
         {
            findJoinLevel = param1.data.association_info.join_level_limit;
            findMemberCount = param1.data.association_info.member_count;
            cfg = GlobalData.$mGuild_simple.guild_level["level_" + param1.data.association_info.level];
            maxGuildMember = cfg.max_member_length;
            guildId = param1.data.association_info.id;
            _loc3_ = new Scale9Textures(GlobalFunction.getTexture("UI_guild_bg_2_0000"),new Rectangle(30,30,50,50));
            img9 = new Scale9Image(_loc3_);
            img9.width = 590;
            img9.height = 130;
            img9.x = GlobalData.$mStageWidth / 2 - img9.width / 2;
            img9.y = GlobalData.$center_height / 2 - img9.height / 2;
            this.addChild(img9);
            _loc2_ = param1.data.association_info.icon < 10 ? "0" + param1.data.association_info.icon : param1.data.association_info.icon;
            mBg = GlobalFunction.createImage("UI_guild_logo_00" + _loc2_);
            mBg.x = img9.x + 20;
            mBg.y = img9.y + img9.height / 2 - mBg.height / 2;
            addChild(mBg);
            guildName = GlobalTextStyle.getTextField(param1.data.association_info.name + "(" + GlobalLanguageStr.getLanguageStr(20005,param1.data.association_info.member_count,maxGuildMember) + ")",25,1513239,"left",300,46);
            guildName.x = mBg.x + mBg.width + 5;
            guildName.y = mBg.y;
            this.addChild(guildName);
            guildLV = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(98151,param1.data.association_info.level),20,1513239,"left",200,46);
            guildLV.x = guildName.x;
            guildLV.y = guildName.y + 35;
            this.addChild(guildLV);
            liveness = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97703,param1.data.association_info.total_alive),20,1513239,"left",200,46);
            liveness.x = guildLV.x + 120;
            liveness.y = guildLV.y;
            this.addChild(liveness);
            notice = GlobalTextStyle.getHtmlTextRenderer();
            notice.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97927),GlobalTextStyle.COLOR_B_R_R_R,21,16);
            notice.x = guildName.x;
            notice.y = guildLV.y + 27;
            this.addChild(notice);
            if(param1.data.association_info.content != null && String(param1.data.association_info.content) != "")
            {
               notice.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97729,param1.data.association_info.content),GlobalTextStyle.COLOR_B_R_R_R,100,15);
            }
            playerLv = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97704,param1.data.association_info.join_level_limit),15,1513239,"left",200,46);
            playerLv.x = img9.width - playerLv.textBounds.width + 2;
            playerLv.y = guildName.y + 7;
            this.addChild(playerLv);
            if(param1.data.flag == 0)
            {
               if(param1.data.association_info.join_type == 0)
               {
                  setFunBtnUI(GlobalLanguageStr.getLanguageStr(97712),true,"UI_btn_guild_2_0000");
                  joinGuildsBtn.enabled = false;
               }
               if(param1.data.association_info.join_type == 1)
               {
                  setFunBtnUI(GlobalLanguageStr.getLanguageStr(97709),true,"UI_btn_guild_2_0000");
               }
               if(param1.data.association_info.join_type == 2)
               {
                  setFunBtnUI(GlobalLanguageStr.getLanguageStr(97710),true,"UI_btn_guild_2_0000");
               }
            }
            else
            {
               setFunBtnUI(GlobalLanguageStr.getLanguageStr(97711),true,"UI_btn_guild_2_red_0000");
            }
         }
         else
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97708),true);
         }
      }
      
      public function setFunBtnUI(param1:String, param2:Boolean = true, param3:String = "UI_btn_guild_2_0000") : void
      {
         if(joinGuildsBtn)
         {
            joinGuildsBtn.removeEventListener("triggered",inGuild);
            joinGuildsBtn.removeFromParent(true);
            joinGuildsBtn.dispose();
            joinGuildsBtn = null;
         }
         joinGuildsBtn = new LOL_Scale9Button(param1,115,50,param3,true,false);
         joinGuildsBtn.fontSize = 20;
         joinGuildsBtn.fontColor = 16777215;
         joinGuildsBtn.enabled = param2;
         joinGuildsBtn.x = img9.width - joinGuildsBtn.width + 7;
         joinGuildsBtn.y = playerLv.y + 30;
         this.addChild(joinGuildsBtn);
         joinGuildsBtn.addEventListener("triggered",inGuild);
      }
      
      private function inGuild(param1:Event) : void
      {
         maxGuildMember = cfg.max_member_length;
         if(joinGuildsBtn.text == GlobalLanguageStr.getLanguageStr(97709) || joinGuildsBtn.text == GlobalLanguageStr.getLanguageStr(97710))
         {
            if(GlobalData.$userData.lv < findJoinLevel)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97720),true);
            }
            else if(findMemberCount >= maxGuildMember)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97782),true);
            }
            else
            {
               SendServiceAMFFun.send_user_apply_member(sureGuild,{"id":guildId});
            }
         }
         else if(joinGuildsBtn.text == GlobalLanguageStr.getLanguageStr(97712))
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97959),true);
         }
         else
         {
            SendServiceAMFFun.send_user_calcel_member(cacelGuild,{"id":guildId});
         }
      }
      
      private function cacelGuild(param1:Object) : void
      {
         if(param1.data.res_code == -1)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97862),true);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
         }
         else if(param1.data.res_code == -2)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97835),true);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
         }
         else if(param1.data.res_code == -3)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97863),true);
         }
         else
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(98004),true);
            setFunBtnUI(GlobalLanguageStr.getLanguageStr(97709),true,"UI_btn_guild_2_0000");
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
         }
      }
      
      private function sureGuild(param1:Object) : void
      {
         if(param1.data.res_code == 1)
         {
            if(param1.data.join_flag == true)
            {
               GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
            }
            else
            {
               setFunBtnUI(GlobalLanguageStr.getLanguageStr(97711),true,"UI_btn_guild_2_red_0000");
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97713),true);
               GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
            }
         }
         else if(param1.data.res_code == -1)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97864),true);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
         }
         else if(param1.data.res_code == -2)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97835),true);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
         }
         else
         {
            GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97832,int(param1.data.punish_time / 60)),GlobalTextStyle.COLOR_W_R_R_R));
         }
      }
      
      private function delFind() : void
      {
         if(mBg)
         {
            mBg.removeFromParent(true);
            mBg.dispose();
         }
         if(liveness)
         {
            liveness.removeFromParent(true);
            liveness.dispose();
         }
         if(notice)
         {
            notice.removeFromParent(true);
            notice.dispose();
         }
         if(playerLv)
         {
            playerLv.removeFromParent(true);
            playerLv.dispose();
         }
         if(joinGuildsBtn)
         {
            joinGuildsBtn.removeEventListener("triggered",btnTriggered);
            joinGuildsBtn.removeFromParent(true);
            joinGuildsBtn.dispose();
         }
         if(img9)
         {
            img9.removeFromParent(true);
            img9.dispose();
         }
         if(guildName)
         {
            guildName.removeFromParent(true);
            guildName.dispose();
         }
         if(guildID)
         {
            guildID.removeFromParent(true);
            guildID.dispose();
         }
         if(guildDeclarationTxt)
         {
            guildDeclarationTxt.removeFromParent(true);
            guildDeclarationTxt.dispose();
         }
         if(guildLV)
         {
            guildLV.removeFromParent(true);
            guildLV.dispose();
         }
         if(foundGuildBg)
         {
            foundGuildBg.removeFromParent(true);
            foundGuildBg.dispose();
         }
         if(foundGuildText)
         {
            foundGuildText.removeFromParent(true);
            foundGuildText.dispose();
         }
         if(imageL)
         {
            imageL.removeFromParent(true);
            imageL.dispose();
         }
         if(imageGold)
         {
            imageGold.removeFromParent(true);
            imageGold.dispose();
         }
         if(findImg)
         {
            findImg.removeFromParent(true);
            findImg.dispose();
         }
         if(findText)
         {
            findText.removeFromParent(true);
            findText.dispose();
         }
         if(guildShopBg)
         {
            guildShopBg.removeFromParent(true);
            guildShopBg.dispose();
         }
         if(guildShopCase)
         {
            guildShopCase.removeFromParent(true);
            guildShopCase.dispose();
         }
         if(guildShopRedCloth)
         {
            guildShopRedCloth.removeFromParent(true);
            guildShopRedCloth.dispose();
         }
         if(shopStrangeTxt)
         {
            shopStrangeTxt.removeFromParent(true);
            shopStrangeTxt.dispose();
         }
         if(shopGloryTxt)
         {
            shopGloryTxt.removeFromParent(true);
            shopGloryTxt.dispose();
         }
         if(guildShopRule)
         {
            guildShopRule.removeEventListener("touch",onGuildShopRule);
            guildShopRule.removeFromParent(true);
            guildShopRule.dispose();
         }
         if(_spRule)
         {
            _spRule.removeEventListener("touch",ruleTouch);
            _spRule.removeFromParent(true);
            _spRule.dispose();
         }
         if(shopRule)
         {
            shopRule.removeFromParent(true);
            shopRule.dispose();
         }
         if(ruleQuad)
         {
            ruleQuad.removeFromParent(true);
            ruleQuad.dispose();
         }
         if(quad)
         {
            quad.removeEventListener("touch",onGuildBattleRule);
            quad.removeFromParent(true);
            quad.dispose();
         }
         if(mTag_a)
         {
            mTag_a.removeFromParent(true);
            mTag_a.dispose();
         }
         if(guildBossRule)
         {
            guildBossRule.removeEventListener("touch",onGuildBossRule);
            guildBossRule.removeFromParent(true);
            guildBossRule.dispose();
         }
         if(refreshBtn)
         {
            refreshBtn.removeFromParent(true);
            refreshBtn.dispose();
         }
         if(ShopGuildLV)
         {
            ShopGuildLV.removeFromParent(true);
            ShopGuildLV.dispose();
         }
         if(mBox)
         {
            mBox.removeFromParent(true);
            mBox.dispose();
         }
         if(researchBg)
         {
            researchBg.removeFromParent(true);
            researchBg.dispose();
         }
         if(currentActive)
         {
            currentActive.removeFromParent(true);
            currentActive.dispose();
         }
         if(researchRuleSp)
         {
            researchRuleSp.removeEventListener("touch",researchTouch);
            researchRuleSp.removeFromParent(true);
            researchRuleSp.dispose();
         }
         if(researchRuleText)
         {
            researchRuleText.removeFromParent(true);
            researchRuleText.dispose();
         }
         if(researchRuleQuad)
         {
            researchRuleQuad.removeFromParent(true);
            researchRuleQuad.dispose();
         }
         if(researchSkillBtn)
         {
            researchSkillBtn.removeFromParent(true);
            researchSkillBtn.dispose();
         }
         if(activeTrade)
         {
            activeTrade.removeFromParent(true);
            activeTrade.dispose();
         }
         if(usualTradeBtn)
         {
            usualTradeBtn.removeFromParent(true);
            usualTradeBtn.dispose();
         }
         if(seniorTradeBtn)
         {
            seniorTradeBtn.removeFromParent(true);
            seniorTradeBtn.dispose();
         }
         if(btnSkill)
         {
            btnSkill.removeFromParent(true);
            btnSkill.dispose();
         }
         if(m_scrollContainer)
         {
            m_scrollContainer.removeFromParent(true);
            m_scrollContainer.dispose();
         }
         guildLV = null;
         guildID = null;
         guildName = null;
         img9 = null;
         joinGuildsBtn = null;
         playerLv = null;
         notice = null;
         liveness = null;
         mBg = null;
         guildDeclarationTxt = null;
         foundGuildBg = null;
         foundGuildText = null;
         imageL = null;
         imageGold = null;
         findImg = null;
         findText = null;
         guildShopBg = null;
         guildShopCase = null;
         guildShopRedCloth = null;
         shopStrangeTxt = null;
         shopGloryTxt = null;
         guildShopRule = null;
         _spRule = null;
         shopRule = null;
         ruleQuad = null;
         quad = null;
         mTag_a = null;
         guildBossRule = null;
         mBox = null;
         refreshBtn = null;
         ShopGuildLV = null;
         researchBg = null;
         currentActive = null;
         researchRuleSp = null;
         researchRuleText = null;
         researchRuleQuad = null;
         researchSkillBtn = null;
         activeTrade = null;
         usualTradeBtn = null;
         seniorTradeBtn = null;
         btnSkill = null;
         m_scrollContainer = null;
      }
      
      private function btnTriggered() : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_guild_amend_icon",false,true,{"flag":1});
      }
      
      private function onBtnGuildTouch(param1:Event) : void
      {
         var _loc3_:* = 0;
         _loc3_ = 0;
         while(_loc3_ < GuildInfo.data.member_list.length)
         {
            if(GuildInfo.data.member_list[_loc3_].uid == GlobalData.$userData.uid && GuildInfo.data.member_list[_loc3_].zone == GlobalData.$userData.zone)
            {
               uGuildLv = GuildInfo.data.member_list[_loc3_].association_lv;
            }
            _loc3_++;
         }
         var _loc2_:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         switch(_loc2_.name)
         {
            case "btn_name_guild_day":
               SendServiceAMFFun.send_user_get_guild_log(onReGuildDayFun);
               break;
            case "btn_name_guild_manager":
               if(_btnGuildManager.enabled == false)
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97819),true);
                  return;
               }
               if(GuildInfo.data.association_info.association_application == 0)
               {
                  GlobalData.$mEventDispatcher.dispatchEventWith("update_avatarsoul_tag",false,{"length":GuildInfo.data.association_info.association_application});
               }
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_guild_manager",false,true,{
                  "lv":uGuildLv,
                  "data":GuildInfo
               });
               break;
            case "btn_name_guild_active":
               SendServiceAMFFun.send_user_association_rank_index(reServiceFun);
               break;
            case "btn_name_guild_ather":
               SendServiceAMFFun.send_user_associatione_is(onAther);
         }
         _loc2_ = null;
      }
      
      private function onAther(param1:Object) : void
      {
         onReGuild(param1);
         GlobalData.$userGuild.GuildList = param1;
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_guild_ather",false,true,param1);
      }
      
      private function onReGuildDayFun(param1:Object) : void
      {
         if(param1.data.res_code == 1)
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_guild_day",false,true,param1);
         }
         else
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97835),true);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
         }
      }
      
      private function reServiceFun(param1:Object) : void
      {
         if(param1.data.res_code == 1)
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_guild_ranking",false,true,param1);
         }
         else
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97835),true);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
         }
      }
      
      public function isNumeric(param1:String) : Boolean
      {
         var _loc4_:* = 0;
         var _loc3_:int = 0;
         var _loc2_:Boolean = false;
         _loc4_ = 0;
         while(_loc4_ < param1.length)
         {
            _loc3_ = param1.charCodeAt(_loc4_);
            if(_loc3_ < 48 || _loc3_ > 57)
            {
               return true;
            }
            _loc2_ = false;
            _loc4_++;
         }
         return _loc2_;
      }
      
      private function getShaShaDaoJiShi() : Object
      {
         var _loc4_:* = 0;
         _now = SendAndSelect.$systemTimer_nowSecond * 1000;
         _now = Tools.getServerNowTimeDate(_now).time;
         var _loc3_:Date = new Date();
         _loc3_.setTime(_now);
         var _loc2_:String = "";
         var _loc1_:Number = 0;
         if(_loc3_.time > (userTime.FightStartTime as Date).time && _loc3_.time < (userTime.FightOverTime as Date).time)
         {
            if(_loc3_.time > (userTime.FightStartTime as Date).time && _loc3_.time < (userTime.guildBMendTime as Date).time)
            {
               _loc2_ = "GuildBMTime";
               _loc1_ = (userTime.guildBMendTime as Date).time - _loc3_.time;
               return {
                  "overTime":_loc1_,
                  "type":_loc2_
               };
            }
            _loc4_ = 0;
            while(_loc4_ < userTime.memberTimeArr.length)
            {
               if(_loc3_.time > (userTime.memberTimeArr[_loc4_].start as Date).time && _loc3_.time < (userTime.memberTimeArr[_loc4_].end as Date).time)
               {
                  _loc2_ = "MemberBMTime";
                  _loc1_ = (userTime.memberTimeArr[_loc4_].end as Date).time - _loc3_.time;
                  return {
                     "overTime":_loc1_,
                     "type":_loc2_
                  };
               }
               _loc4_++;
            }
            if(_loc2_ == "")
            {
               if((userTime.memberTimeArr[lun - 1].start as Date).time < _loc3_.time)
               {
                  if(lun == 7)
                  {
                     _loc2_ = "";
                     _loc1_ = (userTime.NextGameTime as Date).time - _loc3_.time;
                     return {
                        "overTime":_loc1_,
                        "type":_loc2_
                     };
                  }
                  _loc2_ = "NextMemberBMTime2";
                  _loc1_ = (userTime.memberTimeArr[lun].start as Date).time - _loc3_.time;
                  return {
                     "overTime":_loc1_,
                     "type":_loc2_
                  };
               }
               _loc2_ = "NextMemberBMTime";
               _loc1_ = (userTime.memberTimeArr[lun - 1].start as Date).time - _loc3_.time;
               return {
                  "overTime":_loc1_,
                  "type":_loc2_
               };
            }
            return null;
         }
         _loc2_ = "NextGameTime";
         if((userTime.FightStartTime as Date).time > _loc3_.time)
         {
            _loc1_ = (userTime.FightStartTime as Date).time - _loc3_.time;
         }
         else
         {
            _loc1_ = (userTime.NextGameTime as Date).time - _loc3_.time;
         }
         return {
            "overTime":_loc1_,
            "type":_loc2_
         };
      }
      
      override public function delList() : void
      {
         LayoutUIAnimation.getOnlyExample().clearIfNoGuide();
         if(this.mList)
         {
            if(this.mList.dataProvider)
            {
               this.mList.dataProvider.removeAll();
            }
            StarlingTools.removeChildrenClear(this.mList.viewPort as DisplayObjectContainer);
            this.mList.removeFromParent(true);
            this.mList.dispose();
         }
         this.mList = null;
         if(downText)
         {
            downText.removeFromParent(true);
            downText.dispose();
         }
         if(downText1)
         {
            downText1.removeFromParent(true);
            downText1.dispose();
         }
         downText1 = null;
         downText = null;
         if(foundGuild1)
         {
            foundGuild1.removeFromParent(true);
            foundGuild1.dispose();
         }
         if(foundGuild2)
         {
            foundGuild2.removeFromParent(true);
            foundGuild2.dispose();
         }
         if(foundGuild3)
         {
            foundGuild3.removeFromParent(true);
            foundGuild3.dispose();
         }
         foundGuild3 = null;
         foundGuild2 = null;
         foundGuild1 = null;
         if(guildShopBg)
         {
            guildShopBg.removeFromParent(true);
            guildShopBg.dispose();
         }
         guildShopBg = null;
         if(mTimerTBoss)
         {
            mTimerTBoss.removeFromParent(true);
            mTimerTBoss.dispose();
         }
         mTimerTBoss = null;
         if(title)
         {
            title.removeFromParent(true);
            title.dispose();
         }
         title = null;
         if(title1)
         {
            title1.removeFromParent(true);
            title1.dispose();
         }
         title1 = null;
         if(bgYuan)
         {
            bgYuan.removeFromParent(true);
            bgYuan.dispose();
         }
         bgYuan = null;
         if(bgYuanTween)
         {
            Starling.juggler.remove(bgYuanTween);
         }
         bgYuanTween = null;
         if(spr)
         {
            spr.removeFromParent(true);
            spr.dispose();
         }
         spr = null;
         if(_dis1)
         {
            _dis1.removeFromParent(true);
            _dis1.dispose();
         }
         _dis1 = null;
         if(_dis)
         {
            _dis.removeFromParent(true);
            _dis.dispose();
         }
         _dis = null;
         if(iconImg)
         {
            iconImg.removeFromParent(true);
            iconImg.dispose();
         }
         iconImg = null;
         if(_sp)
         {
            _sp.removeFromParent(true);
            _sp.dispose();
         }
         _sp = null;
         if(_bgFight)
         {
            _bgFight.removeFromParent(true);
            _bgFight.dispose();
         }
         _bgFight = null;
         if(guildFight_Rank)
         {
            guildFight_Rank.removeFromParent(true);
            guildFight_Rank.dispose();
         }
         if(guildFight_Schedule)
         {
            guildFight_Schedule.removeFromParent(true);
            guildFight_Schedule.dispose();
         }
         if(guildFight_Reward)
         {
            guildFight_Reward.removeFromParent(true);
            guildFight_Reward.dispose();
         }
         if(guildFight_Chack)
         {
            guildFight_Chack.removeFromParent(true);
            guildFight_Chack.dispose();
         }
         if(textfield)
         {
            textfield.removeFromParent(true);
            textfield.dispose();
         }
         if(m_input)
         {
            m_input.removeFromParent(true);
            m_input.dispose();
         }
         if(btn)
         {
            btn.removeEventListener("triggered",onbtnTriggered);
            btn.removeFromParent(true);
            btn.dispose();
         }
         if(guildName)
         {
            guildName.removeFromParent(true);
            guildName.dispose();
         }
         if(myInput)
         {
            myInput.removeFromParent(true);
            myInput.dispose();
         }
         if(guildTxT)
         {
            guildTxT.removeFromParent(true);
            guildTxT.dispose();
         }
         if(guildImg)
         {
            guildImg.removeFromParent(true);
            guildImg.dispose();
         }
         if(guildAmendBtn)
         {
            guildAmendBtn.removeEventListener("triggered",btnTriggered);
            guildAmendBtn.removeFromParent(true);
            guildAmendBtn.dispose();
         }
         if(foundMoneyTxT)
         {
            foundMoneyTxT.removeFromParent(true);
            foundMoneyTxT.dispose();
         }
         if(moneyL)
         {
            moneyL.removeFromParent(true);
            moneyL.dispose();
         }
         if(moneyGold)
         {
            moneyGold.removeFromParent(true);
            moneyGold.dispose();
         }
         if(foundGuildLBtn)
         {
            foundGuildLBtn.removeEventListener("triggered",onFoundGuildBtn);
            foundGuildLBtn.removeFromParent(true);
            foundGuildLBtn.dispose();
         }
         if(foundGuildGBtn)
         {
            foundGuildGBtn.removeEventListener("triggered",onFoundGuildBtn);
            foundGuildGBtn.removeFromParent(true);
            foundGuildGBtn.dispose();
         }
         if(guildNotice)
         {
            guildNotice.removeFromParent(true);
            guildNotice.dispose();
         }
         if(icon)
         {
            icon.removeFromParent(true);
            icon.dispose();
         }
         if(guildID)
         {
            guildID.removeFromParent(true);
            guildID.dispose();
         }
         if(guildLV)
         {
            guildLV.removeFromParent(true);
            guildLV.dispose();
         }
         if(guildNum)
         {
            guildNum.removeFromParent(true);
            guildNum.dispose();
         }
         if(_btnGuildActive)
         {
            _btnGuildActive.removeEventListener("triggered",onBtnGuildTouch);
            _btnGuildActive.removeFromParent(true);
            _btnGuildActive.dispose();
         }
         if(_btnGuildAther)
         {
            _btnGuildAther.removeEventListener("triggered",onBtnGuildTouch);
            _btnGuildAther.removeFromParent(true);
            _btnGuildAther.dispose();
         }
         if(_btnGuildDay)
         {
            _btnGuildDay.removeEventListener("triggered",onBtnGuildTouch);
            _btnGuildDay.removeFromParent(true);
            _btnGuildDay.dispose();
         }
         if(_btnGuildManager)
         {
            _btnGuildManager.removeEventListener("triggered",onBtnGuildTouch);
            _btnGuildManager.removeFromParent(true);
            _btnGuildManager.dispose();
         }
         if(noGuild)
         {
            noGuild.removeFromParent(true);
            noGuild.dispose();
         }
         if(mBg)
         {
            mBg.removeFromParent(true);
            mBg.dispose();
         }
         if(liveness)
         {
            liveness.removeFromParent(true);
            liveness.dispose();
         }
         if(notice)
         {
            notice.removeFromParent(true);
            notice.dispose();
         }
         if(playerLv)
         {
            playerLv.removeFromParent(true);
            playerLv.dispose();
         }
         if(joinGuildsBtn)
         {
            joinGuildsBtn.removeEventListener("triggered",btnTriggered);
            joinGuildsBtn.removeFromParent(true);
            joinGuildsBtn.dispose();
         }
         if(img9)
         {
            img9.removeFromParent(true);
            img9.dispose();
         }
         if(guildName)
         {
            guildName.removeFromParent(true);
            guildName.dispose();
         }
         if(guildID)
         {
            guildID.removeFromParent(true);
            guildID.dispose();
         }
         if(guildDeclarationTxt)
         {
            guildDeclarationTxt.removeFromParent(true);
            guildDeclarationTxt.dispose();
         }
         if(_bg)
         {
            _bg.removeFromParent(true);
            _bg.dispose();
         }
         if(txt_1)
         {
            txt_1.removeFromParent(true);
            txt_1.dispose();
         }
         if(btn_BOSS_HurtRanklist)
         {
            btn_BOSS_HurtRanklist.removeFromParent(true);
            btn_BOSS_HurtRanklist.dispose();
         }
         if(btn_BOSS_AllFight)
         {
            btn_BOSS_AllFight.removeFromParent(true);
            btn_BOSS_AllFight.dispose();
         }
         if(btn_BOSS_RewardPreview)
         {
            btn_BOSS_RewardPreview.removeFromParent(true);
            btn_BOSS_RewardPreview.dispose();
         }
         if(foundGuildBg)
         {
            foundGuildBg.removeFromParent(true);
            foundGuildBg.dispose();
         }
         if(foundGuildText)
         {
            foundGuildText.removeFromParent(true);
            foundGuildText.dispose();
         }
         if(imageL)
         {
            imageL.removeFromParent(true);
            imageL.dispose();
         }
         if(imageGold)
         {
            imageGold.removeFromParent(true);
            imageGold.dispose();
         }
         if(findImg)
         {
            findImg.removeFromParent(true);
            findImg.dispose();
         }
         if(findText)
         {
            findText.removeFromParent(true);
            findText.dispose();
         }
         if(guildShopBg)
         {
            guildShopBg.removeFromParent(true);
            guildShopBg.dispose();
         }
         if(guildShopCase)
         {
            guildShopCase.removeFromParent(true);
            guildShopCase.dispose();
         }
         if(guildShopRedCloth)
         {
            guildShopRedCloth.removeFromParent(true);
            guildShopRedCloth.dispose();
         }
         if(shopStrangeTxt)
         {
            shopStrangeTxt.removeFromParent(true);
            shopStrangeTxt.dispose();
         }
         if(shopGloryTxt)
         {
            shopGloryTxt.removeFromParent(true);
            shopGloryTxt.dispose();
         }
         if(guildShopRule)
         {
            guildShopRule.removeEventListener("touch",onGuildShopRule);
            guildShopRule.removeFromParent(true);
            guildShopRule.dispose();
         }
         if(_spRule)
         {
            _spRule.removeEventListener("touch",ruleTouch);
            _spRule.removeFromParent(true);
            _spRule.dispose();
         }
         if(shopRule)
         {
            shopRule.removeFromParent(true);
            shopRule.dispose();
         }
         if(ruleQuad)
         {
            ruleQuad.removeFromParent(true);
            ruleQuad.dispose();
         }
         if(quad)
         {
            quad.removeEventListener("touch",onGuildBattleRule);
            quad.removeFromParent(true);
            quad.dispose();
         }
         if(mTag_a)
         {
            mTag_a.removeFromParent(true);
            mTag_a.dispose();
         }
         if(guildBossRule)
         {
            guildBossRule.removeEventListener("touch",onGuildBossRule);
            guildBossRule.removeFromParent(true);
            guildBossRule.dispose();
         }
         if(refreshBtn)
         {
            refreshBtn.removeFromParent(true);
            refreshBtn.dispose();
         }
         if(ShopGuildLV)
         {
            ShopGuildLV.removeFromParent(true);
            ShopGuildLV.dispose();
         }
         if(mBox)
         {
            mBox.removeFromParent(true);
            mBox.dispose();
         }
         if(researchBg)
         {
            researchBg.removeFromParent(true);
            researchBg.dispose();
         }
         if(currentActive)
         {
            currentActive.removeFromParent(true);
            currentActive.dispose();
         }
         if(researchRuleSp)
         {
            researchRuleSp.removeEventListener("touch",researchTouch);
            researchRuleSp.removeFromParent(true);
            researchRuleSp.dispose();
         }
         if(researchRuleText)
         {
            researchRuleText.removeFromParent(true);
            researchRuleText.dispose();
         }
         if(researchRuleQuad)
         {
            researchRuleQuad.removeFromParent(true);
            researchRuleQuad.dispose();
         }
         if(researchSkillBtn)
         {
            researchSkillBtn.removeFromParent(true);
            researchSkillBtn.dispose();
         }
         if(activeTrade)
         {
            activeTrade.removeFromParent(true);
            activeTrade.dispose();
         }
         if(usualTradeBtn)
         {
            usualTradeBtn.removeFromParent(true);
            usualTradeBtn.dispose();
         }
         if(seniorTradeBtn)
         {
            seniorTradeBtn.removeFromParent(true);
            seniorTradeBtn.dispose();
         }
         if(btnSkill)
         {
            btnSkill.removeFromParent(true);
            btnSkill.dispose();
         }
         if(m_scrollContainer)
         {
            m_scrollContainer.removeFromParent(true);
            m_scrollContainer.dispose();
         }
         btn_BOSS_RewardPreview = null;
         btn_BOSS_AllFight = null;
         btn_BOSS_HurtRanklist = null;
         txt_1 = null;
         _bg = null;
         guildFight_Rank = null;
         guildFight_Chack = null;
         guildFight_Reward = null;
         guildFight_Schedule = null;
         guildID = null;
         guildName = null;
         img9 = null;
         joinGuildsBtn = null;
         playerLv = null;
         notice = null;
         liveness = null;
         mBg = null;
         noGuild = null;
         _btnGuildManager = null;
         _btnGuildDay = null;
         _btnGuildAther = null;
         _btnGuildActive = null;
         guildNum = null;
         guildLV = null;
         guildID = null;
         icon = null;
         guildNotice = null;
         foundGuildLBtn = null;
         foundGuildGBtn = null;
         moneyGold = null;
         moneyL = null;
         foundMoneyTxT = null;
         guildAmendBtn = null;
         guildImg = null;
         guildTxT = null;
         myInput = null;
         guildName = null;
         btn = null;
         m_input = null;
         textfield = null;
         guildDeclarationTxt = null;
         foundGuildBg = null;
         foundGuildText = null;
         imageL = null;
         imageGold = null;
         findImg = null;
         findText = null;
         guildShopBg = null;
         guildShopCase = null;
         guildShopRedCloth = null;
         shopStrangeTxt = null;
         shopGloryTxt = null;
         guildShopRule = null;
         _spRule = null;
         shopRule = null;
         ruleQuad = null;
         quad = null;
         mTag_a = null;
         guildBossRule = null;
         refreshBtn = null;
         ShopGuildLV = null;
         mBox = null;
         researchBg = null;
         currentActive = null;
         researchRuleText = null;
         researchRuleSp = null;
         researchRuleQuad = null;
         researchSkillBtn = null;
         activeTrade = null;
         usualTradeBtn = null;
         seniorTradeBtn = null;
         btnSkill = null;
         m_scrollContainer = null;
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

