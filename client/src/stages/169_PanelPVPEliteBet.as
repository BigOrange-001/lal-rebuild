package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelCenterMainAvatar;
   import com.meng52.net.SendAndSelect;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import feathers.textures.Scale9Textures;
   import flash.geom.Rectangle;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;

   public class PanelPVPEliteBet extends PanelCenterMainAvatar
   {

      public static var isbet:Boolean = false;

      private var user_team:Array;

      private var team_A_bg:Scale9Image;

      private var team_B_bg:Scale9Image;

      private var bet_title_A_bg:Image;

      private var bet_title_B_bg:Image;

      private var fans_A_btn:LOL_Scale9Button;

      private var bet_A_btn:LOL_Scale9Button;

      private var fans_B_btn:LOL_Scale9Button;

      private var bet_B_btn:LOL_Scale9Button;

      private var change_teamA_btn:LOL_Scale9Button;

      private var change_teamB_btn:LOL_Scale9Button;

      private var teamA_power_txt:TextField;

      private var teamA_flower_txt:TextField;

      private var teamA_coin_txt:TextField;

      private var teamB_coin_txt:TextField;

      private var teamA_coin_txt2:TextField;

      private var teamA_moods_txt:TextField;

      private var teamA_name_txt:TextField;

      private var teamA_server_txt:TextField;

      private var teamB_power_txt:TextField;

      private var teamB_flower_txt:TextField;

      private var teamB_moods_txt:TextField;

      private var teamB_name_txt:TextField;

      private var teamB_server_txt:TextField;

      private var mImg_coin:Image;

      private var mImg_coin1:Image;

      private const FANS_A:String = "fansa";

      private const BET_A:String = "beta";

      private const FLW_A:String = "flwa";

      private const CHANGE_TEAMA:String = "change_teama";

      private const CHANGE_TEAMB:String = "change_teamb";

      private const FANS_B:String = "fansb";

      private const BET_B:String = "betb";

      private const FLW_B:String = "flwb";

      private var _team_A:Array;

      private var _team_B:Array;

      private var _avatar_array:Array;

      private var _avatar_sprite_array:Array;

      private var _teamA_sprite:Sprite;

      private var _teamB_sprite:Sprite;

      private const HEIGHT_9X9:int = 285;

      private const WIDTH_9X9:int = 560;

      private const BTNGAP:int = 175;

      private const constX1:Array = [80,255,430];

      private const constX2:Array = [160,255,350];

      public function PanelPVPEliteBet()
      {
         super();
      }

      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         super.onREMOVED_FROM_STAGE(param1);
         GlobalData.$mEventDispatcher.removeEventListener("update_betui",updateBtn);
         GlobalData.$mEventDispatcher.removeEventListener("update_PanelPVPEliteBet",onUPDATE_PANELPVPELITEBET);
         GlobalData.$mEventDispatcher.removeEventListener("update_PanelPVPFlower",onUPDATE_FLOWER);
      }

      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         GlobalData.$mEventDispatcher.addEventListener("update_betui",updateBtn);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(20278));
         this.addEventListener("close_panel_self",onCLOSE_PANEL_SELF);
         isbet = GlobalData.$useExtreme.gamble == null ? false : true;
         user_team = GlobalData.$tempExtremeBetTeam;
         GlobalData.$mEventDispatcher.addEventListener("update_PanelPVPEliteBet",onUPDATE_PANELPVPELITEBET);
         GlobalData.$mEventDispatcher.addEventListener("update_PanelPVPFlower",onUPDATE_FLOWER);
         setUI();
      }

      private function onUPDATE_PANELPVPELITEBET(param1:Event) : void
      {
         isbet = GlobalData.$useExtreme.gamble == null ? false : true;
         user_team = GlobalData.$tempExtremeBetTeam;
         clear();
         setUI();
      }

      override public function onBTN_NAME_BACK() : void
      {
         PanelPVPEliteGroupSelect._screenChange = true;
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_elite_group_select");
         clear();
      }

      private function setUI() : void
      {
         var _loc3_:int = 0;
         var _loc1_:Avatar = null;
         var _loc13_:Object = null;
         var _loc9_:int = 0;
         var _loc10_:Sprite = null;
         var _loc7_:int = 0;
         var _loc15_:Sprite = null;
         _avatar_array = [];
         _avatar_sprite_array = [];
         _teamA_sprite = new Sprite();
         _teamB_sprite = new Sprite();
         var _loc11_:Boolean = user_team[0].uid == GlobalData.$userData.uid && user_team[0].zone == GlobalData.$userData.zone ? true : false;
         var _loc12_:Boolean = user_team[1].uid == GlobalData.$userData.uid && user_team[1].zone == GlobalData.$userData.zone ? true : false;
         var _loc8_:Number = SendAndSelect.$systemTimer_nowSecond * 1000;
         var _loc18_:String = GlobalData.$useExtreme.phase;
         var _loc5_:int = int(GlobalData.$useExtreme.phase_data[0]);
         var _loc6_:Object = GlobalFunction.getExtremeStartEndTime(_loc18_,_loc5_);
         var _loc14_:Scale9Textures = new Scale9Textures(GlobalFunction.getTexture("UI_bg_9slice_0_0000"),new Rectangle(110,55,70,20));
         team_A_bg = new Scale9Image(_loc14_);
         team_A_bg.width = 560;
         team_A_bg.height = 285;
         team_A_bg.x = this.mImg9_baseBg.x + (this.mImg9_baseBg.width - team_A_bg.width) * 0.5;
         team_A_bg.y = 110;
         this.addChild(team_A_bg);
         bet_title_A_bg = GlobalFunction.createImage("UI_extreme_bg_0_0000");
         bet_title_A_bg.x = team_A_bg.x + (team_A_bg.width - bet_title_A_bg.width) * 0.5;
         bet_title_A_bg.y = team_A_bg.y - 20;
         this.addChild(bet_title_A_bg);
         team_B_bg = new Scale9Image(_loc14_);
         team_B_bg.width = 560;
         team_B_bg.height = 285;
         team_B_bg.x = this.mImg9_baseBg.x + (this.mImg9_baseBg.width - team_B_bg.width) * 0.5;
         team_B_bg.y = team_A_bg.y + team_B_bg.height + 15;
         this.addChild(team_B_bg);
         bet_title_B_bg = GlobalFunction.createImage("UI_extreme_bg_1_0000");
         bet_title_B_bg.x = team_B_bg.x + (team_B_bg.width - bet_title_B_bg.width) * 0.5;
         bet_title_B_bg.y = team_B_bg.y - 10;
         this.addChild(bet_title_B_bg);
         fans_A_btn = new LOL_Scale9Button(GlobalLanguageStr.getStr(90263),125,45,"UI_btn_enterGame_0_0000");
         fans_A_btn.name = "fansa";
         fans_A_btn.x = _loc11_ ? constX1[0] : constX2[0];
         fans_A_btn.y = team_A_bg.y + team_A_bg.height - fans_A_btn.height - 40;
         fans_A_btn.shadowFilter();
         fans_A_btn.addEventListener("triggered",butClickHandler);
         this.addChild(fans_A_btn);
         change_teamA_btn = new LOL_Scale9Button(GlobalLanguageStr.getStr(90286),125,45,"UI_btn_enterGame_0_0000");
         change_teamA_btn.name = "change_teama";
         change_teamA_btn.x = _loc11_ ? constX1[1] : constX2[1];
         change_teamA_btn.y = fans_A_btn.y;
         change_teamA_btn.shadowFilter();
         change_teamA_btn.visible = _loc11_;
         change_teamA_btn.addEventListener("triggered",butClickHandler);
         this.addChild(change_teamA_btn);
         mImg_coin = GlobalFunction.createImage("UI_money_coin_0_0000");
         mImg_coin.x = change_teamA_btn.x + mImg_coin.width / 2;
         mImg_coin.y = change_teamA_btn.y + change_teamA_btn.height - 2;
         mImg_coin.scaleX = mImg_coin.scaleY = 0.8;
         mImg_coin.visible = _loc11_;
         this.addChild(mImg_coin);
         var _loc17_:Object = GlobalData.$mConfig_simple.extreme;
         teamA_coin_txt = GlobalTextStyle.getTextField(_loc17_.change_team,20,4926491,"left",100,35);
         teamA_coin_txt.x = mImg_coin.x + mImg_coin.width;
         teamA_coin_txt.y = mImg_coin.y;
         teamA_coin_txt.visible = _loc11_;
         this.addChild(teamA_coin_txt);
         addChild(teamA_coin_txt);
         bet_A_btn = new LOL_Scale9Button(isbet ? GlobalLanguageStr.getStr(90276) : GlobalLanguageStr.getStr(90275),125,45,"UI_btn_enterGame_0_0000");
         bet_A_btn.name = isbet ? "flwa" : "beta";
         bet_A_btn.x = _loc11_ ? constX1[2] : constX2[2];
         bet_A_btn.y = fans_A_btn.y;
         bet_A_btn.shadowFilter();
         bet_A_btn.addEventListener("triggered",butClickHandler);
         this.addChild(bet_A_btn);
         teamA_power_txt = GlobalFunction.createTextField(MainConfig.$isEA ? 400 : 240,MainConfig.$isEA ? 40 : 30,"","",20,4926491);
         teamA_power_txt.hAlign = "left";
         teamA_power_txt.x = MainConfig.$isEA ? team_A_bg.x + 22 : team_A_bg.x + 50;
         teamA_power_txt.y = fans_A_btn.y - teamA_power_txt.height;
         this.addChild(teamA_power_txt);
         teamA_flower_txt = GlobalFunction.createTextField(MainConfig.$isEA ? 250 : 170,30,"","",15,4926491);
         teamA_flower_txt.x = MainConfig.$isEA ? bet_A_btn.x - 65 : bet_A_btn.x - 25;
         teamA_flower_txt.y = bet_A_btn.y + bet_A_btn.height - 5;
         this.addChild(teamA_flower_txt);
         teamA_moods_txt = GlobalFunction.createTextField(240,30,"","",20,4926491);
         teamA_moods_txt.hAlign = "left";
         teamA_moods_txt.x = MainConfig.$isEA ? teamA_power_txt.x + teamA_power_txt.width - 25 : teamA_power_txt.x + teamA_power_txt.width + 15;
         teamA_moods_txt.y = MainConfig.$isEA ? teamA_power_txt.y + 6 : teamA_power_txt.y;
         this.addChild(teamA_moods_txt);
         teamA_server_txt = GlobalFunction.createTextField(200,30,"","",20,16777215,true);
         teamA_server_txt.x = bet_title_A_bg.x + 30;
         teamA_server_txt.y = bet_title_A_bg.y + 8;
         teamA_server_txt.hAlign = "right";
         this.addChild(teamA_server_txt);
         teamA_name_txt = GlobalFunction.createTextField(190,30,"","",20,16777215,true);
         teamA_name_txt.x = teamA_server_txt.x + teamA_server_txt.width + 20;
         teamA_name_txt.y = teamA_server_txt.y;
         teamA_name_txt.hAlign = "left";
         this.addChild(teamA_name_txt);
         fans_B_btn = new LOL_Scale9Button(GlobalLanguageStr.getStr(90263),125,45,"UI_btn_enterGame_0_0000");
         fans_B_btn.name = "fansb";
         fans_B_btn.x = _loc12_ ? constX1[0] : constX2[0];
         fans_B_btn.y = team_B_bg.y + team_B_bg.height - fans_B_btn.height - 40;
         fans_B_btn.shadowFilter();
         fans_B_btn.addEventListener("triggered",butClickHandler);
         this.addChild(fans_B_btn);
         change_teamB_btn = new LOL_Scale9Button(GlobalLanguageStr.getStr(90286),125,45,"UI_btn_enterGame_0_0000");
         change_teamB_btn.name = "change_teamb";
         change_teamB_btn.x = _loc12_ ? constX1[1] : constX2[1];
         change_teamB_btn.y = fans_B_btn.y;
         change_teamB_btn.shadowFilter();
         change_teamB_btn.visible = _loc12_;
         change_teamB_btn.addEventListener("triggered",butClickHandler);
         this.addChild(change_teamB_btn);
         mImg_coin1 = GlobalFunction.createImage("UI_money_coin_0_0000");
         mImg_coin1.x = change_teamB_btn.x + mImg_coin1.width / 2;
         mImg_coin1.y = change_teamB_btn.y + change_teamB_btn.height - 2;
         mImg_coin1.scaleX = mImg_coin1.scaleY = 0.8;
         this.addChild(mImg_coin1);
         mImg_coin1.visible = _loc12_;
         teamB_coin_txt = GlobalTextStyle.getTextField(_loc17_.change_team,20,4926491,"left",200,24);
         teamB_coin_txt.x = mImg_coin1.x + mImg_coin1.width;
         teamB_coin_txt.y = mImg_coin1.y + 5;
         teamB_coin_txt.visible = _loc12_;
         this.addChild(teamB_coin_txt);
         teamA_coin_txt2 = GlobalTextStyle.getTextField(_loc17_.change_team,20,4926491,"left",200,24);
         teamA_coin_txt2.x = mImg_coin1.x + mImg_coin1.width;
         teamA_coin_txt2.y = mImg_coin1.y + 5;
         teamA_coin_txt2.visible = _loc12_;
         addChild(teamA_coin_txt2);
         bet_B_btn = new LOL_Scale9Button(isbet ? GlobalLanguageStr.getStr(90276) : GlobalLanguageStr.getStr(90275),125,45,"UI_btn_enterGame_0_0000");
         bet_B_btn.name = isbet ? "flwb" : "betb";
         bet_B_btn.x = _loc12_ ? constX1[2] : constX2[2];
         bet_B_btn.y = fans_B_btn.y;
         bet_B_btn.shadowFilter();
         bet_B_btn.addEventListener("triggered",butClickHandler);
         this.addChild(bet_B_btn);
         teamB_power_txt = GlobalFunction.createTextField(MainConfig.$isEA ? 400 : 240,MainConfig.$isEA ? 40 : 30,"","",20,4926491);
         teamB_power_txt.hAlign = "left";
         teamB_power_txt.x = MainConfig.$isEA ? team_B_bg.x + 22 : team_B_bg.x + 50;
         teamB_power_txt.y = fans_B_btn.y - teamB_power_txt.height;
         this.addChild(teamB_power_txt);
         teamB_flower_txt = GlobalFunction.createTextField(MainConfig.$isEA ? 250 : 170,30,"","",15,4926491);
         teamB_flower_txt.x = MainConfig.$isEA ? bet_B_btn.x - 65 : bet_B_btn.x - 25;
         teamB_flower_txt.y = bet_B_btn.y + bet_B_btn.height - 5;
         this.addChild(teamB_flower_txt);
         teamB_moods_txt = GlobalFunction.createTextField(240,30,"","",20,4926491);
         teamB_moods_txt.hAlign = "left";
         teamB_moods_txt.x = MainConfig.$isEA ? teamB_power_txt.x + teamB_power_txt.width - 25 : teamB_power_txt.x + teamB_power_txt.width + 15;
         teamB_moods_txt.y = MainConfig.$isEA ? teamB_power_txt.y + 6 : teamB_power_txt.y;
         this.addChild(teamB_moods_txt);
         teamB_server_txt = GlobalFunction.createTextField(200,30,"","",20,16777215,true);
         teamB_server_txt.hAlign = "right";
         teamB_server_txt.x = bet_title_B_bg.x + 30;
         teamB_server_txt.y = bet_title_B_bg.y + 8;
         this.addChild(teamB_server_txt);
         teamB_name_txt = GlobalFunction.createTextField(200,30,"","",20,16777215,true);
         teamB_name_txt.hAlign = "left";
         teamB_name_txt.x = teamB_server_txt.x + teamB_server_txt.width + 25;
         teamB_name_txt.y = teamB_server_txt.y;
         this.addChild(teamB_name_txt);
         if(_loc8_ >= _loc6_.start && _loc8_ < _loc6_.fans)
         {
            bet_A_btn.enabled = true;
            bet_B_btn.enabled = true;
         }
         else
         {
            bet_A_btn.enabled = false;
            bet_B_btn.enabled = false;
         }
         if(_loc8_ >= _loc6_.start && _loc8_ < _loc6_.team)
         {
            change_teamA_btn.enabled = true;
            change_teamB_btn.enabled = true;
         }
         else
         {
            change_teamA_btn.enabled = false;
            change_teamB_btn.enabled = false;
         }
         var _loc20_:int = int(user_team[0].score);
         _loc3_ = countMoods(_loc20_);
         var _loc16_:Object = GlobalData.$tempExtremeBetTeam;
         teamA_name_txt.text = _loc16_[0].name;
         teamA_server_txt.text = GlobalData.$mConfig_zones[_loc16_[0].zone][0];
         teamB_name_txt.text = _loc16_[1].name;
         teamB_server_txt.text = GlobalData.$mConfig_zones[_loc16_[1].zone][0];
         _team_A = _loc16_[0].data as Array;
         _team_B = _loc16_[1].data as Array;
         var _loc2_:Boolean = _team_A[0][0].indexOf("|") < 0;
         var _loc4_:Object = GlobalFunction.setOtherCfgAvatarsObj(_team_A);
         var _loc19_:Number = 0;
         _loc9_ = 0;
         while(_loc9_ < _team_A.length)
         {
            if(_team_A[_loc9_] && _team_A[_loc9_] is Array)
            {
               _loc13_ = GlobalFunction.getPVPenemyEquip(_loc2_ ? [] : (_team_A[_loc9_][10] != null ? _team_A[_loc9_][10] : null),_loc2_);
               _loc1_ = new Avatar(_team_A[_loc9_][0],_team_A[_loc9_]);
               _loc1_.setDestinyAndDN(_team_A[_loc9_][0],_loc4_.team,_loc13_.as_equips,_loc13_.my_equips,_loc4_.dn);
               _loc10_ = _loc1_.getAvatarRes();
               _loc10_.x = 105 * _loc9_;
               _avatar_array.push(_loc1_);
               _avatar_sprite_array.push(_loc10_);
               _teamA_sprite.addChild(_loc10_);
               _loc10_.addEventListener("touch",avatarA_Touch);
               _loc19_ += countPowerByAvatar(_loc1_,_loc3_,_loc9_);
            }
            _loc9_++;
         }
         teamA_power_txt.text = GlobalLanguageStr.getStr(90279) + Tools.formateNum(_loc19_);
         teamA_moods_txt.text = GlobalLanguageStr.getStr(90280) + _loc3_;
         teamA_flower_txt.text = GlobalLanguageStr.getStr(90316) + user_team[0].score;
         _loc20_ = int(user_team[1].score);
         _loc3_ = countMoods(_loc20_);
         _loc19_ = 0;
         _loc20_ = int(user_team[1].score);
         _loc3_ = countMoods(_loc20_);
         _loc2_ = _team_B[0][0].indexOf("|") < 0;
         _loc4_ = GlobalFunction.setOtherCfgAvatarsObj(_team_B);
         _loc7_ = 0;
         while(_loc7_ < _team_B.length)
         {
            if(_team_B[_loc7_] && _team_B[_loc7_] is Array)
            {
               _loc13_ = GlobalFunction.getPVPenemyEquip(_loc2_ ? [] : (_team_B[_loc7_][10] != null ? _team_B[_loc7_][10] : null),_loc2_);
               _loc1_ = new Avatar(_team_B[_loc7_][0],_team_B[_loc7_]);
               _loc1_.setDestinyAndDN(_team_B[_loc7_][0],_loc4_.team,_loc13_.as_equips,_loc13_.my_equips,_loc4_.dn);
               _loc15_ = _loc1_.getAvatarRes();
               _loc15_.x = 105 * _loc7_;
               _avatar_array.push(_loc1_);
               _avatar_sprite_array.push(_loc15_);
               _teamB_sprite.addChild(_loc15_);
               _loc15_.addEventListener("touch",avatarB_Touch);
               _loc19_ += countPowerByAvatar(_loc1_,_loc3_,_loc7_);
            }
            _loc7_++;
         }
         teamB_power_txt.text = GlobalLanguageStr.getStr(90279) + Tools.formateNum(_loc19_);
         teamB_moods_txt.text = GlobalLanguageStr.getStr(90280) + _loc3_;
         teamB_flower_txt.text = GlobalLanguageStr.getStr(90316) + user_team[1].score;
         _teamA_sprite.x = team_A_bg.x + 25;
         _teamA_sprite.y = bet_title_A_bg.y + bet_title_A_bg.height;
         this.addChild(_teamA_sprite);
         _teamB_sprite.x = team_B_bg.x + 25;
         _teamB_sprite.y = bet_title_B_bg.y + bet_title_B_bg.height;
         this.addChild(_teamB_sprite);
      }

      private function onUPDATE_FLOWER(param1:Event) : void
      {
         var _loc4_:int = 0;
         var _loc3_:Avatar = null;
         var _loc11_:Object = null;
         var _loc7_:int = 0;
         var _loc9_:Sprite = null;
         var _loc6_:int = 0;
         var _loc12_:Sprite = null;
         isbet = GlobalData.$useExtreme.gamble == null ? false : true;
         user_team = GlobalData.$tempExtremeBetTeam;
         var _loc8_:Boolean = user_team[0].uid == GlobalData.$userData.uid && user_team[0].zone == GlobalData.$userData.zone ? true : false;
         var _loc10_:Boolean = user_team[1].uid == GlobalData.$userData.uid && user_team[1].zone == GlobalData.$userData.zone ? true : false;
         var _loc14_:int = int(user_team[0].score);
         _loc4_ = countMoods(_loc14_);
         if(bet_A_btn)
         {
            bet_A_btn.removeFromParent(true);
            bet_A_btn = null;
         }
         bet_A_btn = new LOL_Scale9Button(isbet ? GlobalLanguageStr.getStr(90276) : GlobalLanguageStr.getStr(90275),125,45,"UI_btn_enterGame_0_0000");
         bet_A_btn.name = isbet ? "flwa" : "beta";
         bet_A_btn.x = _loc8_ ? constX1[2] : constX2[2];
         bet_A_btn.y = fans_A_btn.y;
         bet_A_btn.shadowFilter();
         bet_A_btn.addEventListener("triggered",butClickHandler);
         this.addChild(bet_A_btn);
         if(bet_B_btn)
         {
            bet_B_btn.removeFromParent(true);
            bet_B_btn = null;
         }
         bet_B_btn = new LOL_Scale9Button(isbet ? GlobalLanguageStr.getStr(90276) : GlobalLanguageStr.getStr(90275),125,45,"UI_btn_enterGame_0_0000");
         bet_B_btn.name = isbet ? "flwb" : "betb";
         bet_B_btn.x = _loc10_ ? constX1[2] : constX2[2];
         bet_B_btn.y = fans_B_btn.y;
         bet_B_btn.shadowFilter();
         bet_B_btn.addEventListener("triggered",butClickHandler);
         this.addChild(bet_B_btn);
         clearAvtArray();
         _team_A = user_team[0].data as Array;
         _team_B = user_team[1].data as Array;
         var _loc2_:Boolean = _team_A[0][0].indexOf("|") < 0;
         var _loc5_:Object = GlobalFunction.setOtherCfgAvatarsObj(_team_A);
         var _loc13_:Number = 0;
         _loc7_ = 0;
         while(_loc7_ < _team_A.length)
         {
            if(_team_A[_loc7_] && _team_A[_loc7_] is Array)
            {
               _loc11_ = GlobalFunction.getPVPenemyEquip(_loc2_ ? [] : (_team_A[_loc7_][10] != null ? _team_A[_loc7_][10] : null),_loc2_);
               _loc3_ = new Avatar(_team_A[_loc7_][0],_team_A[_loc7_]);
               _loc3_.setDestinyAndDN(_team_A[_loc7_][0],_loc5_.team,_loc11_.as_equips,_loc11_.my_equips,_loc5_.dn);
               _loc9_ = _loc3_.getAvatarRes();
               _loc9_.x = 105 * _loc7_;
               _avatar_array.push(_loc3_);
               _avatar_sprite_array.push(_loc9_);
               _teamA_sprite.addChild(_loc9_);
               _loc9_.addEventListener("touch",avatarA_Touch);
               _loc13_ += countPowerByAvatar(_loc3_,_loc4_,_loc7_);
            }
            _loc7_++;
         }
         teamA_power_txt.text = GlobalLanguageStr.getStr(90279) + Tools.formateNum(_loc13_);
         teamA_moods_txt.text = GlobalLanguageStr.getStr(90280) + _loc4_;
         teamA_flower_txt.text = GlobalLanguageStr.getStr(90316) + user_team[0].score;
         _loc13_ = 0;
         _loc14_ = int(user_team[1].score);
         _loc4_ = countMoods(_loc14_);
         _loc2_ = _team_B[0][0].indexOf("|") < 0;
         _loc5_ = GlobalFunction.setOtherCfgAvatarsObj(_team_B);
         _loc6_ = 0;
         while(_loc6_ < _team_B.length)
         {
            if(_team_B[_loc6_] && _team_B[_loc6_] is Array)
            {
               _loc11_ = GlobalFunction.getPVPenemyEquip(_loc2_ ? [] : (_team_B[_loc6_][10] != null ? _team_B[_loc6_][10] : null),_loc2_);
               _loc3_ = new Avatar(_team_B[_loc6_][0],_team_B[_loc6_]);
               _loc3_.setDestinyAndDN(_team_B[_loc6_][0],_loc5_.team,_loc11_.as_equips,_loc11_.my_equips,_loc5_.dn);
               _loc12_ = _loc3_.getAvatarRes();
               _loc12_.x = 105 * _loc6_;
               _avatar_array.push(_loc3_);
               _avatar_sprite_array.push(_loc12_);
               _teamB_sprite.addChild(_loc12_);
               _loc12_.addEventListener("touch",avatarB_Touch);
               _loc13_ += countPowerByAvatar(_loc3_,_loc4_,_loc6_);
            }
            _loc6_++;
         }
         teamB_power_txt.text = GlobalLanguageStr.getStr(90279) + Tools.formateNum(_loc13_);
         teamB_moods_txt.text = GlobalLanguageStr.getStr(90280) + _loc4_;
         teamB_flower_txt.text = GlobalLanguageStr.getStr(90316) + user_team[1].score;
      }

      private function clearAvtArray() : void
      {
         var _loc2_:Avatar = null;
         var _loc1_:Sprite = null;
         while(_avatar_array.length > 0)
         {
            _loc2_ = _avatar_array.pop();
            _loc2_.clear();
            _loc2_ = null;
         }
         while(_avatar_sprite_array.length > 0)
         {
            _loc1_ = _avatar_sprite_array.pop();
            _loc1_.removeFromParent(true);
            _loc1_ = null;
         }
      }

      private function avatarA_Touch(param1:TouchEvent) : void
      {
         var _loc2_:Object = null;
         var _loc3_:Touch = param1.getTouch(this,"ended");
         if(_loc3_)
         {
            _loc2_ = GlobalData.$tempExtremeBetTeam;
            PanelTeamListInfoPVP.proScreenId = "PanelPVPEliteBet_True";
            GlobalData.$pvp_rival = {
               "data":_loc2_[0].data,
               "name":_loc2_[0].name,
               "lv":_loc2_[0].lv
            };
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_change_pvp",false,true);
         }
      }

      private function avatarB_Touch(param1:TouchEvent) : void
      {
         var _loc2_:Object = null;
         var _loc3_:Touch = param1.getTouch(this,"ended");
         if(_loc3_)
         {
            _loc2_ = GlobalData.$tempExtremeBetTeam;
            PanelTeamListInfoPVP.proScreenId = "PanelPVPEliteBet_True";
            GlobalData.$pvp_rival = {
               "data_base":_loc2_[1].data,
               "name":_loc2_[1].name
            };
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_change_pvp",false,true);
         }
      }

      public function updateBtn() : void
      {
         isbet = GlobalData.$useExtreme.gamble == null ? false : true;
         bet_A_btn.text = isbet ? GlobalLanguageStr.getStr(90276) : GlobalLanguageStr.getStr(90275);
         bet_A_btn.name = isbet ? "flwa" : "beta";
         bet_B_btn.text = isbet ? GlobalLanguageStr.getStr(90276) : GlobalLanguageStr.getStr(90275);
         bet_B_btn.name = isbet ? "flwb" : "betb";
      }

      public function countMoods(param1:int = 0) : int
      {
         var _loc3_:int = int(GlobalData.$mConfig_simple.extreme.flower[4]);
         var _loc2_:int = int(GlobalData.$mConfig_simple.extreme.flower[5]);
         return Math.ceil(Math.max(param1 / _loc3_,Math.sqrt(param1) * _loc2_));
      }

      public function countPower(param1:Object, param2:int) : String
      {
         var _loc3_:Avatar = null;
         var _loc7_:int = 0;
         var _loc5_:int = int((param1.data as Array).length);
         var _loc4_:String = "";
         var _loc6_:Number = 0;
         _loc7_ = 0;
         while(_loc7_ < _loc5_)
         {
            _loc4_ = param1.data[_loc7_][0];
            if(!Tools.strIsNull(_loc4_))
            {
               _loc3_ = new Avatar(_loc4_,param1.data[_loc7_]);
               _loc3_.initFightAttr();
               _loc3_.hpMax += param2;
               _loc6_ += _loc3_.getPowerBase104(_loc7_ == 0);
               _loc3_.clear();
            }
            _loc7_++;
         }
         return Tools.formateNum(Avatar.normalizeTeamPower104(_loc6_));
      }

      public function countPowerByAvatar(param1:Avatar, param2:int, param3:int) : int
      {
         var _loc4_:int = 0;
         param1.initFightAttr();
         param1.hpMax += param2;
         return int(_loc4_ + param1.getPower(param3 == 0));
      }

      private function butClickHandler(param1:Event) : void
      {
         var _loc2_:Object = param1.currentTarget;
         switch(_loc2_.name)
         {
            case "fansa":
               GlobalData.$tempScreenToFans = "PanelPVPEliteBet";
               GlobalData.$tempExtremeBetTeamDate = GlobalData.$tempExtremeBetTeam[0];
               PanelPVPFans._name = GlobalData.$tempExtremeBetTeam[0].name;
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_elite_fans",false,true);
               break;
            case "beta":
               if(checkTime("betflw") && bet_A_btn.enabled)
               {
                  GlobalData.$tempExtremeBetTeamDate = GlobalData.$tempExtremeBetTeam[0];
                  GlobalFunction.popPanelBet();
               }
               else
               {
                  GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(90307));
               }
               break;
            case "flwa":
               if(checkTime("betflw") && fans_A_btn.enabled)
               {
                  GlobalData.$tempExtremeBetTeamDate = GlobalData.$tempExtremeBetTeam[0];
                  GlobalFunction.popPanelFlower();
               }
               else
               {
                  GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(90308));
               }
               break;
            case "fansb":
               GlobalData.$tempScreenToFans = "PanelPVPEliteBet";
               GlobalData.$tempExtremeBetTeamDate = GlobalData.$tempExtremeBetTeam[1];
               PanelPVPFans._name = GlobalData.$tempExtremeBetTeam[1].name;
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_elite_fans",false,true);
               break;
            case "betb":
               if(checkTime("betflw") && bet_B_btn.enabled)
               {
                  GlobalData.$tempExtremeBetTeamDate = GlobalData.$tempExtremeBetTeam[1];
                  GlobalFunction.popPanelBet();
               }
               else
               {
                  GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(90307));
               }
               break;
            case "flwb":
               if(checkTime("betflw") && fans_B_btn.enabled)
               {
                  GlobalData.$tempExtremeBetTeamDate = GlobalData.$tempExtremeBetTeam[1];
                  GlobalFunction.popPanelFlower();
               }
               else
               {
                  GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(90308));
               }
               break;
            case "change_teama":
               if(checkTime("teams") && change_teamA_btn.enabled)
               {
                  GlobalData.$tempIsApplyorChangeTeam = true;
                  gotoChangeTeam();
               }
               else
               {
                  GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(90309));
               }
               break;
            case "change_teamb":
               if(checkTime("teams") && change_teamB_btn.enabled)
               {
                  GlobalData.$tempIsApplyorChangeTeam = true;
                  gotoChangeTeam();
               }
               else
               {
                  GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(90309));
               }
         }
      }

      private function checkTime(param1:String) : Boolean
      {
         var _loc3_:int = 0;
         var _loc4_:Object = null;
         var _loc5_:Number = NaN;
         var _loc2_:Object = GlobalData.$useExtreme;
         var _loc6_:String = GlobalData.$useExtreme.phase;
         if(GlobalData.$useExtreme.phase_data == null)
         {
            return false;
         }
         _loc3_ = int(GlobalData.$useExtreme.phase_data[0]);
         _loc4_ = GlobalFunction.getExtremeStartEndTime(_loc6_,_loc3_);
         _loc5_ = SendAndSelect.$systemTimer_nowSecond * 1000;
         if(param1 == "betflw")
         {
            if(_loc5_ >= _loc4_.start && _loc5_ < _loc4_.fans)
            {
               return true;
            }
            return false;
         }
         if(param1 == "teams")
         {
            if(_loc5_ >= _loc4_.start && _loc5_ < _loc4_.team)
            {
               return true;
            }
            return false;
         }
         return false;
      }

      private function gotoFans(param1:Object) : void
      {
         var _loc2_:Object = GlobalData.$tempExtremeBetTeamDate;
         PanelPVPFans._name = GlobalData.$tempExtremeBetTeamDate.name;
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_elite_fans");
      }

      private function gotoChangeTeam() : void
      {
         var _fun:Object;
         var showpanel:*;
         var _gamblingCfg:int = int(GlobalData.$mConfig_simple.extreme.change_team);
         if(GlobalData.$mUserData.coin > _gamblingCfg)
         {
            showpanel = function():void
            {
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_elite_battle",false,true);
            };
            _fun = {
               "ok":showpanel,
               "no":GlobalFunction.functionNull,
               "aid":"A_2009_5"
            };
            GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90315),GlobalTextStyle.COLOR_W_Y_Y_G),_fun);
         }
         else
         {
            GlobalFunction.popErrorCoin(_gamblingCfg);
         }
      }

      private function clear() : void
      {
         var _loc1_:Avatar = null;
         var _loc2_:Sprite = null;
         if(team_A_bg)
         {
            team_A_bg.dispose();
            team_A_bg.removeFromParent(true);
         }
         if(team_B_bg)
         {
            team_B_bg.dispose();
            team_B_bg.removeFromParent(true);
         }
         team_A_bg = null;
         team_B_bg = null;
         if(fans_A_btn)
         {
            fans_A_btn.removeFromParent(true);
         }
         fans_A_btn = null;
         if(bet_A_btn)
         {
            bet_A_btn.removeFromParent(true);
         }
         bet_A_btn = null;
         if(fans_B_btn)
         {
            fans_B_btn.removeFromParent(true);
         }
         fans_B_btn = null;
         if(bet_B_btn)
         {
            bet_B_btn.removeFromParent(true);
         }
         bet_B_btn = null;
         if(teamA_power_txt)
         {
            teamA_power_txt.dispose();
            teamA_power_txt.removeFromParent(true);
         }
         teamA_power_txt = null;
         if(teamA_moods_txt)
         {
            teamA_moods_txt.dispose();
            teamA_moods_txt.removeFromParent(true);
         }
         teamA_moods_txt = null;
         if(teamA_name_txt)
         {
            teamA_name_txt.dispose();
            teamA_name_txt.removeFromParent(true);
         }
         teamA_name_txt = null;
         if(teamA_server_txt)
         {
            teamA_server_txt.dispose();
            teamA_server_txt.removeFromParent(true);
         }
         teamA_server_txt = null;
         if(teamB_power_txt)
         {
            teamB_power_txt.dispose();
            teamB_power_txt.removeFromParent(true);
         }
         teamB_power_txt = null;
         if(teamB_moods_txt)
         {
            teamB_moods_txt.dispose();
            teamB_moods_txt.removeFromParent(true);
         }
         teamB_moods_txt = null;
         if(teamB_name_txt)
         {
            teamB_name_txt.dispose();
            teamB_name_txt.removeFromParent(true);
         }
         teamB_name_txt = null;
         if(teamB_server_txt)
         {
            teamB_server_txt.dispose();
            teamB_server_txt.removeFromParent(true);
         }
         teamB_server_txt = null;
         _team_A = null;
         _team_B = null;
         if(_avatar_array)
         {
            while(_avatar_array.length > 0)
            {
               _loc1_ = _avatar_array.pop();
               _loc1_.clear();
               _loc1_ = null;
            }
         }
         _avatar_array = null;
         if(_avatar_sprite_array)
         {
            while(_avatar_sprite_array.length > 0)
            {
               _loc2_ = _avatar_sprite_array.pop();
               _loc2_.removeFromParent(true);
               _loc2_ = null;
            }
         }
         _avatar_sprite_array = null;
         if(_teamA_sprite)
         {
            _teamA_sprite.removeFromParent(true);
         }
         _teamA_sprite = null;
         if(_teamB_sprite)
         {
            _teamB_sprite.removeFromParent(true);
         }
         _teamB_sprite = null;
         if(teamA_flower_txt)
         {
            teamA_flower_txt.dispose();
            teamA_flower_txt.removeFromParent(true);
         }
         teamA_flower_txt = null;
         if(teamB_flower_txt)
         {
            teamB_flower_txt.dispose();
            teamB_flower_txt.removeFromParent(true);
         }
         teamB_flower_txt = null;
      }
   }
}
