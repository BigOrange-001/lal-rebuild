package com.meng52.game.ui.element
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.command.map.GameMapData;
   import com.meng52.game.command.map.GameMapManager;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.module.map.GameMap;
   import com.meng52.game.module.map.GameMapTools;
   import com.meng52.net.RpcStaticCall;
   import com.meng52.net.SendAndSelect;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.controls.renderers.IListItemRenderer;
   import feathers.display.Scale9Image;
   import feathers.textures.Scale9Textures;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import starling.display.DisplayObjectContainer;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   import starling.textures.Texture;
   
   public class ItemPVEcombat extends ItemPVEmain implements IListItemRenderer
   {
      
      public var HARD_LIST:Array = [0.2,0.45,1,2.5];
      
      public var HARD_COLOR:Array = [10526880,10551200,16777215,16765024,16728128];
      
      private var isPlay:Boolean = false;
      
      private var mLimit:int = 0;
      
      private var mDetails:Sprite;
      
      private var mHardType:int;
      
      private var mBossId:String;
      
      private var mEquip:*;
      
      private var mFirstStar:Image;
      
      private var mSecondStar:Image;
      
      private var mThirdStar:Image;
      
      private var mImg9_bg:Scale9Image;
      
      private var rndList:Array;
      
      private var mBaseSpr:Sprite;
      
      private var mRndSpr:Sprite;
      
      private var m_infoTf:LOL_TextPop;
      
      private var mSrc:String;
      
      private var mArrows:String;
      
      private var mArrowsSpr:Sprite;
      
      private var mArrows_bg:Image;
      
      private var mArrows_topbg:Image;
      
      private const BOTTON_GAP:int = 12;
      
      private var _quad:Quad;
      
      private var mBtn_bg_lv:LOL_Scale9Button;
      
      public function ItemPVEcombat()
      {
         super();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(mEquip)
         {
            mEquip.removeFromParent(true);
         }
         if(mFirstStar)
         {
            mFirstStar.removeFromParent(true);
         }
         if(mSecondStar)
         {
            mSecondStar.removeFromParent(true);
         }
         if(mThirdStar)
         {
            mThirdStar.removeFromParent(true);
         }
         if(mBtn_bg_lv)
         {
            mBtn_bg_lv.removeFromParent(true);
         }
         super.onREMOVED_FROM_STAGE(param1);
         mDetails = null;
         HARD_LIST = null;
         HARD_COLOR = null;
         mEquip = null;
         mFirstStar = null;
         mSecondStar = null;
         mThirdStar = null;
         mBtn_bg_lv = null;
      }
      
      override public function layoutWH() : void
      {
         if(mImg9_bg)
         {
            this.width = mImg9_bg.width;
         }
         this.changeH();
      }
      
      override public function init(param1:Object) : void
      {
         var _loc2_:Object = null;
         var _loc5_:String = null;
         var _loc3_:String = GlobalData.$tempPVE_type;
         if(_loc3_ == "status_pve_normal")
         {
            mSrc = "UI_bg_pve_normal_0_0000";
            mArrows = "UI_bg_arrows_1_0001";
         }
         else if(_loc3_ == "status_pve_hard")
         {
            mSrc = "UI_bg_pve_hard_0_0000";
            mArrows = "UI_bg_arrows_1_0000";
         }
         else if(_loc3_ == "status_pve_activities")
         {
            mSrc = "UI_bg_pve_activity_0_0000";
            mArrows = "UI_bg_arrows_1_0000";
         }
         else if(_loc3_ == "status_pve_guild")
         {
            mSrc = "UI_bg_pve_normal_0_0000";
            mArrows = "UI_bg_arrows_1_0001";
         }
         var _loc4_:GameMapData = GameMapManager.getOnlyExample().getData(data.id);
         if(_loc4_.isFinnal)
         {
            mSrc = "UI_bg_pve_activity_0_0000";
            mArrows = "UI_bg_arrows_1_0000";
         }
         if(_loc4_.id == "M_001_3")
         {
            GuideMaster.getOnlyExample().checkGuide("M1_1");
         }
         else if(_loc4_.id == "M_002_1")
         {
            GuideMaster.getOnlyExample().checkGuide("M1_3");
         }
         diff = param1.diff;
         mBaseSpr = new Sprite();
         addChild(mBaseSpr);
         mImg9_bg = new Scale9Image(new Scale9Textures(GlobalFunction.getTexture(mSrc),new Rectangle(30,30,10,18)));
         rndList = null;
         if(GlobalFunction.hasRndAvatar(diff))
         {
            _loc2_ = GlobalFunction.getRndAvatarObj(diff);
            _loc5_ = _loc2_.cid as String;
            if(_loc5_ == this.data.id)
            {
               rndList = _loc2_.random_team;
               mRndSpr = new Sprite();
               mBaseSpr.addChild(mRndSpr);
            }
         }
         mH_max = 380;
         mH_min = 142;
         mImg9_bg.width = 570;
         mBaseSpr.addChild(mImg9_bg);
         mArrowsSpr = new Sprite();
         mArrowsSpr.touchable = false;
         mArrows_bg = GlobalFunction.createImage(mArrows);
         mArrowsSpr.addChild(mArrows_bg);
         mArrows_topbg = GlobalFunction.createImage("UI_bg_arrows_2_0000");
         mArrows_topbg.pivotX = mArrows_topbg.width * 0.5;
         mArrows_topbg.pivotY = mArrows_topbg.height * 0.5;
         mArrows_topbg.x = mArrows_bg.x + mArrows_bg.width * 0.5;
         mArrows_topbg.y = mArrows_bg.y + (mArrows_bg.height - mArrows_topbg.height * 0.5);
         mArrowsSpr.addChild(mArrows_topbg);
         mArrowsSpr.x = mImg9_bg.x + (mImg9_bg.width - mArrowsSpr.width) * 0.5;
         mArrowsSpr.y = mImg9_bg.y + mImg9_bg.height - mArrowsSpr.height - 12;
         mBaseSpr.addChild(mArrowsSpr);
         setUI();
      }
      
      override public function setUI() : void
      {
         var _loc2_:Number = Number(NaN);
         _loc2_ = 0.35;
         var _loc29_:int = 0;
         var _loc16_:TextField = null;
         var _loc21_:String = null;
         var _loc36_:String = null;
         var _loc22_:Image = null;
         var _loc31_:Image = null;
         var _loc12_:LOL_TextField = null;
         var _loc33_:Avatar = null;
         var _loc19_:Image = null;
         var _loc39_:* = undefined;
         var _loc38_:Array = null;
         var _loc40_:String = null;
         var _loc32_:TextField = null;
         var _loc41_:Sprite = null;
         var _loc35_:Array = null;
         var _loc5_:Array = null;
         var _loc30_:int = 0;
         var _loc26_:Object = null;
         var _loc4_:Object = null;
         var _loc23_:* = undefined;
         var _stageCfg:Object = null;
         var _stageReward:Object = null;
         var _rewardAttrs:Object = null;
         var _guaranteedItems:Array = null;
         var _firstClearItems:Array = null;
         var _firstClearReward:Object = null;
         var _firstAttrs:Object = null;
         var _spClaimed:Array = null;
         var _rewardY:Number = 0;
         var _itemRow:Object = null;
         var _dustIndex:int = 0;
         var _dustAmount:int = 0;
         var _spIndex:int = 0;
         var _spAmount:int = 0;
         var _firstClear:Boolean = false;
         var _randomHeroCandidates:Array = null;
         var _rewardGold:int = 0;
         var _rewardExp:int = 0;
         var _rewardFactor:Array = null;
         var _loc13_:GameMapData = GameMapManager.getOnlyExample().getData(data.id);
         mBossId = _loc13_.bossId;
         this.setAvatar(mBossId,0,null);
         mBaseSpr.addChild(this.mAvatar);
         mAvatar.touchable = false;
         this.mAvatar.x = 30;
         this.mAvatar.y = 15;
         var _loc11_:int = GlobalFunction.check_pass_combat(data.id,diff);
         var _loc1_:Number = Math.floor(this.width * 0.4);
         var _loc3_:Rectangle = new Rectangle(this.mAvatar.x,this.mAvatar.y,this.mAvatar.x + 80,this.mAvatar.y + 35);
         var _loc25_:Number = _loc3_.x + _loc3_.width + 135;
         var _loc28_:Number = _loc3_.y + 18;
         _quad = Tools.newQuad(510,2);
         _quad.alpha = 0.7;
         _quad.visible = false;
         _quad.color = 10120765;
         _quad.y = 112;
         _quad.x = 27;
         mBaseSpr.addChildAt(_quad,mBaseSpr.numChildren - 1);
         this.mFirstStar = new Image(Texture.empty(1,1));
         mFirstStar.touchable = false;
         this.mFirstStar.readjustSize();
         mBaseSpr.addChild(this.mFirstStar);
         this.mSecondStar = new Image(Texture.empty(1,1));
         mSecondStar.touchable = false;
         this.mSecondStar.readjustSize();
         mBaseSpr.addChild(this.mSecondStar);
         this.mThirdStar = new Image(Texture.empty(1,1));
         mThirdStar.touchable = false;
         this.mThirdStar.readjustSize();
         mBaseSpr.addChild(this.mThirdStar);
         _loc29_ = 0;
         while(_loc29_ < 3)
         {
            if(_loc29_ < int(GlobalFunction.getCombatStarById(this.data.id)))
            {
               if(_loc29_ == 0)
               {
                  this.mFirstStar.texture = GlobalFunction.getTexture("UI_icon_avatarStar_0_0000");
                  this.mFirstStar.readjustSize();
                  this.mFirstStar.x = _loc25_ + 30;
                  this.mFirstStar.y = _loc28_;
                  mFirstStar.scaleX = mFirstStar.scaleY = 0.35;
               }
               else if(_loc29_ == 1)
               {
                  this.mSecondStar.texture = GlobalFunction.getTexture("UI_icon_avatarStar_0_0000");
                  this.mSecondStar.readjustSize();
                  this.mSecondStar.x = mFirstStar.x + mFirstStar.width;
                  this.mSecondStar.y = _loc28_;
                  mSecondStar.scaleX = mSecondStar.scaleY = 0.35;
               }
               else
               {
                  this.mThirdStar.texture = GlobalFunction.getTexture("UI_icon_avatarStar_0_0000");
                  this.mThirdStar.readjustSize();
                  this.mThirdStar.x = mSecondStar.x + mSecondStar.width;
                  this.mThirdStar.y = _loc28_;
                  mThirdStar.scaleX = mThirdStar.scaleY = 0.35;
               }
            }
            else if(_loc29_ == 0)
            {
               this.mFirstStar.texture = GlobalFunction.getTexture("UI_icon_avatarStar_0_0002");
               this.mFirstStar.readjustSize();
               this.mFirstStar.x = _loc25_ + 30;
               this.mFirstStar.y = _loc28_;
               mFirstStar.scaleX = mFirstStar.scaleY = 0.35;
            }
            else if(_loc29_ == 1)
            {
               this.mSecondStar.texture = GlobalFunction.getTexture("UI_icon_avatarStar_0_0002");
               this.mSecondStar.readjustSize();
               this.mSecondStar.x = mFirstStar.x + mFirstStar.width;
               this.mSecondStar.y = _loc28_;
               mSecondStar.scaleX = mSecondStar.scaleY = 0.35;
            }
            else
            {
               this.mThirdStar.texture = GlobalFunction.getTexture("UI_icon_avatarStar_0_0002");
               this.mThirdStar.readjustSize();
               this.mThirdStar.x = mSecondStar.x + mSecondStar.width;
               this.mThirdStar.y = _loc28_;
               mThirdStar.scaleX = mThirdStar.scaleY = 0.35;
            }
            _loc29_++;
         }
         var _loc20_:Number = 160;
         var _loc27_:uint = uint(mSrc == "UI_bg_pve_activity_0_0000" ? 16764006 : 1513239);
         var _loc10_:uint = uint(mSrc == "UI_bg_pve_activity_0_0000" ? 16777215 : 10027008);
         var _loc17_:uint = uint(mSrc == "UI_bg_pve_activity_0_0000" ? 16764006 : 4926491);
         this.mTxt_title = GlobalTextStyle.getTextField(this.data.name,25,_loc27_,"left",_loc20_,35);
         this.mTxt_title.x = _loc3_.x + _loc3_.width - 10;
         this.mTxt_title.y = _loc3_.y + 18;
         mBaseSpr.addChild(this.mTxt_title);
         if(diff == 0)
         {
            if(GlobalData.$userData.records.combat_main == null)
            {
               GlobalData.$userData.records.combat_main = {};
            }
         }
         else if(diff == 1)
         {
            if(GlobalData.$userData.records.combat_main_hard == null)
            {
               GlobalData.$userData.records.combat_main_hard = {};
            }
         }
         this.mLimit = GlobalFunction.getUserCombat(GlobalData.$tempPVE_type,this.data.id);
         this.mLimit = _loc13_.getLimit(diff) - this.mLimit;
         this.mLimit = this.mLimit < 0 ? 0 : this.mLimit;
         if(GlobalData.$tempPVE_type == "status_pve_activities" && this.data.activity_kind == "material")
         {
            var _materialDay:Date = new Date(Number(SendAndSelect.$systemTimer_nowSecond) * 1000 + 28800000);
            var _month:int = _materialDay.getUTCMonth() + 1;
            var _day:int = _materialDay.getUTCDate();
            var _today:String = String(_materialDay.getUTCFullYear()) + "-" + (_month < 10 ? "0" : "") + String(_month) + "-" + (_day < 10 ? "0" : "") + String(_day);
            var _daily:Object = GlobalData.$userData.records.material_activity;
            var _used:int = _daily != null && String(_daily.day) == _today && _daily.uses != null ? int(_daily.uses[String(this.data.id).substring(0,String(this.data.id).lastIndexOf("_"))]) : 0;
            this.mLimit = Math.max(0,2 + int((Math.max(0,GlobalFunction.getVipLv()) + 1) / 2) - _used);
         }
         var _loc37_:Number = 140;
         this.mTxt_str0 = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20032,_loc13_.getEnergy(diff)),20,_loc27_,"left",_loc37_,35);
         this.mTxt_str0.touchable = false;
         this.mTxt_str0.x = this.mTxt_title.x;
         this.mTxt_str0.y = this.mTxt_title.y + 35 + 10;
         mBaseSpr.addChild(this.mTxt_str0);
         this.mTxt_num = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20031,mLimit),20,_loc27_,"left",200,35);
         this.mTxt_num.touchable = false;
         this.mTxt_num.x = this.mTxt_str0.x + _loc37_ + 5;
         this.mTxt_num.y = this.mTxt_str0.y;
         if(mLimit <= 20)
         {
            mBaseSpr.addChild(this.mTxt_num);
         }
         mBtn_bg_lv = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20033),126,47,GlobalData.$tempPVE_type == "status_pve_normal" ? "UI_btn_enterGame_0_0000" : (GlobalData.$tempPVE_type == "status_pve_hard" ? "UI_btn_enterGame_1_0000" : "UI_btn_enterGame_0_0000"));
         mBtn_bg_lv.x = mImg9_bg.width - mBtn_bg_lv.width - 30;
         mBtn_bg_lv.y = _loc28_ - 4;
         mBtn_bg_lv.addEventListener("triggered",this.onTRIGGERED_btn);
         mBaseSpr.addChild(mBtn_bg_lv);
         if(this.data.needvip)
         {
            _loc16_ = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97684,this.data.needvip),14,16724736,"center",200,35);
            mBaseSpr.addChild(_loc16_);
            _loc16_.x = mBtn_bg_lv.x + mBtn_bg_lv.width / 2 - _loc16_.width / 2;
            _loc16_.y = mBtn_bg_lv.y + mBtn_bg_lv.height;
         }
         if(mRndSpr)
         {
            mBtn_bg_lv.showGlow();
         }
         if(GlobalFunction.current_battle_main(diff) == this.data.id)
         {
            mBtn_bg_lv.showGlow();
         }
         var _loc8_:int = int(data["status_activity"] ? data["status_activity"] : 0);
         if(_loc8_ > 0)
         {
            _loc21_ = "";
            _loc36_ = "";
            if(_loc8_ == 1)
            {
               _loc21_ = "UI_money_gold_0_0000";
               _loc36_ = GlobalLanguageStr.getLanguageStr(25042);
            }
            else if(_loc8_ == 2)
            {
               _loc21_ = "UI_money_exp_0_0000";
               _loc36_ = GlobalLanguageStr.getLanguageStr(25043);
            }
            else if(_loc8_ == 3)
            {
               _loc21_ = "UI_money_energy_0_0000";
               _loc36_ = GlobalLanguageStr.getLanguageStr(25044);
            }
            _loc22_ = GlobalFunction.createImage("UI_wordbg_yellow_0_0000");
            _loc22_.width = 120;
            mBaseSpr.addChild(_loc22_);
            _loc31_ = GlobalFunction.createImage(_loc21_);
            _loc31_.x = mBtn_bg_lv.x + 15;
            _loc31_.y = mBtn_bg_lv.y + mBtn_bg_lv.height;
            _loc22_.x = _loc31_.x;
            _loc22_.y = _loc31_.y;
            if(_loc8_ == 2)
            {
               _loc31_.scaleX = _loc31_.scaleY = 0.5;
            }
            mBaseSpr.addChild(_loc31_);
            _loc12_ = new LOL_TextField(_loc36_,100,30);
            _loc12_.fontSize = 15;
            _loc12_.x = _loc31_.x + _loc31_.width;
            _loc12_.y = _loc31_.y + 8;
            mBaseSpr.addChild(_loc12_);
         }
         var _loc9_:int = _loc13_.getUserPower(diff);
         var _loc14_:Array = [_loc10_,_loc10_,_loc10_,_loc10_];
         if(rndList)
         {
            _loc33_ = new Avatar(rndList[1],{
               "lv":rndList[2],
               "slv":rndList[3]
            });
            _loc33_.isLeader = rndList[6] == 1;
            _loc9_ += _loc13_.getAvatarPower(_loc33_,diff);
            _loc19_ = GameMapTools.newAvatarImg(_loc33_.avatarData.res);
            _loc19_.x = 550 - _loc19_.width * 0.3;
            _loc19_.y = -_loc19_.height * 0.3;
            mRndSpr.addChild(_loc19_);
            _loc39_ = GlobalFunction.getRndAvatarObj(diff);
            _loc38_ = _loc39_.random_team;
            _loc40_ = _loc38_[10];
            m_infoTf = new LOL_TextPop(300,120,"textpop_right");
            m_infoTf.show(_loc40_);
            m_infoTf.fontSize = 20;
            m_infoTf.touchable = false;
            m_infoTf.x = 5;
            m_infoTf.y = _loc19_.y - _loc19_.height * 0.1 - 55;
            mRndSpr.addChild(m_infoTf);
            _loc14_ = [_loc10_,_loc10_,16776960,_loc10_];
         }
         var _loc7_:String = Tools.formateNum(_loc9_);
         this.mDetails = new Sprite();
         this.mDetails.touchable = false;
         this.mDetails.x = _loc3_.x;
         this.mDetails.y = _loc3_.y + 106;
         var _requiredPower:TextField = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(98240,_loc7_),18,_loc10_,"left",385,28);
         _requiredPower.y = 0;
         _requiredPower.touchable = false;
         this.mDetails.addChild(_requiredPower);
         var _currentPower:TextField = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(98241,Tools.formateNum(GlobalData.$tempTeamPower)),18,_loc10_,"left",385,28);
         _currentPower.y = 27;
         _currentPower.touchable = false;
         this.mDetails.addChild(_currentPower);
         var _loc34_:int = 485;
         var _loc42_:TextField = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20178,GameMapTools.getWinStr(this.data.id,true)),18,_loc10_,"left",_loc34_,48);
         _loc42_.x = 0;
         _loc42_.y = 57;
         _loc42_.touchable = false;
         this.mDetails.addChild(_loc42_);
         var _loc15_:TextFieldHtmlRenderer = GlobalTextStyle.getHtmlTextRenderer();
         _loc15_.x = 0;
         _loc15_.y = 105;
         _loc15_.width = 485;
         _loc15_.height = 34;
         _loc15_.touchable = false;
         this.mDetails.addChild(_loc15_);
         if(data.info != null && String(data.info) != "")
         {
            _loc15_.text = Tools.formatLineX(data.info,[_loc17_],52,MainConfig.$isEnglish ? 15 : 16,false);
         }
         else
         {
            _loc15_.text = "";
         }
         _stageCfg = GlobalData.$tempPVE_type == "status_pve_activities" ? GlobalData.$mConfig.combat_ploy[data.id] : GlobalData.$config_combat_main[data.id];
         _stageReward = _stageCfg && _stageCfg.reward is Object ? _stageCfg.reward : {};
         _rewardAttrs = _stageReward.attrs is Object ? _stageReward.attrs : {};
         _guaranteedItems = [];
         _firstClearItems = [];
         _rewardY = data.info != null && String(data.info) != "" ? 148 : 118;
         var _previewTitle:TextField = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20057),20,_loc27_,"left",485,27);
         _previewTitle.x = 0;
         _previewTitle.y = _rewardY;
         _previewTitle.touchable = false;
         this.mDetails.addChild(_previewTitle);
         _rewardY += 29;
         _randomHeroCandidates = _stageCfg && _stageCfg.hero_drop_candidates_by_diff is Object ? _stageCfg.hero_drop_candidates_by_diff[String(diff)] as Array : null;
         if(_randomHeroCandidates && _randomHeroCandidates.length > 0)
         {
            _rewardY = addRandomHeroDropPreview(this.mDetails,_randomHeroCandidates,_rewardY);
         }
         _firstClear = GlobalFunction.check_pass_combat(this.data.id,diff) != 1;
         _rewardGold = _loc13_.getGold(diff) * (_firstClear ? 2 : 1);
         _rewardExp = _loc13_.getExp(diff) * (_firstClear ? 2 : 1);
         _firstClearReward = _stageReward.first_clear is Object ? _stageReward.first_clear : {};
         _firstAttrs = _firstClearReward.attrs is Object ? _firstClearReward.attrs : {};
         _spClaimed = GlobalData.$userData.records.talent_sp_first_clear as Array;
         if(_firstAttrs.sp is Array && (!_spClaimed || _spClaimed.indexOf(this.data.id) < 0))
         {
            _spIndex = 0;
            while(_spIndex < _firstAttrs.sp.length)
            {
               _spAmount = int(_firstAttrs.sp[_spIndex]);
               if(_spAmount > 0)
               {
                  _firstClearItems.push({
                     "type":"sp",
                     "value":{
                        "indexID_s":_spIndex,
                        "numberIndex":_spAmount
                     },
                     "count":_spAmount
                  });
               }
               _spIndex++;
            }
         }
         if(_firstClear)
         {
            _rewardGold += int(_firstClearReward.gold);
         }
         if(_rewardGold > 0)
         {
            _guaranteedItems.push({
               "type":"gold",
               "value":_rewardGold,
               "count":_rewardGold
            });
         }
         if(_rewardExp > 0)
         {
            _guaranteedItems.push({
               "type":"exp",
               "value":_rewardExp,
               "count":_rewardExp
            });
         }
         if(_rewardAttrs.dust is Array)
         {
            _dustIndex = 0;
            while(_dustIndex < _rewardAttrs.dust.length)
            {
               _dustAmount = int(_rewardAttrs.dust[_dustIndex]);
               if(_dustAmount > 0)
               {
                  _guaranteedItems.push({
                     "type":"dust",
                     "value":{
                        "indexID_s":_dustIndex,
                        "numberIndex":_dustAmount
                     },
                     "count":_dustAmount
                  });
               }
               _dustIndex++;
            }
         }
         if(Number(_rewardAttrs.dn_stone) > 0)
         {
            _guaranteedItems.push({
               "type":"dn_stone",
               "value":Number(_rewardAttrs.dn_stone),
               "count":Number(_rewardAttrs.dn_stone)
            });
         }
         if(Number(_rewardAttrs.culture_book) > 0)
         {
            _guaranteedItems.push({
               "type":"culture_book",
               "value":Number(_rewardAttrs.culture_book),
               "count":Number(_rewardAttrs.culture_book)
            });
         }
         if(_rewardAttrs.sp is Array)
         {
            _spIndex = 0;
            while(_spIndex < _rewardAttrs.sp.length)
            {
               _spAmount = int(_rewardAttrs.sp[_spIndex]);
               if(_spAmount > 0)
               {
                  _guaranteedItems.push({
                     "type":"sp",
                     "value":{
                        "indexID_s":_spIndex,
                        "numberIndex":_spAmount
                     },
                     "count":_spAmount
                  });
               }
               _spIndex++;
            }
         }
         if(Number(_stageReward.coin) > 0)
         {
            _guaranteedItems.push({
               "type":"coin",
               "value":Number(_stageReward.coin),
               "count":Number(_stageReward.coin)
            });
         }
         if(Number(_stageReward.mark) > 0)
         {
            _guaranteedItems.push({
               "type":"mark",
               "value":Number(_stageReward.mark),
               "count":Number(_stageReward.mark)
            });
         }
         if(Number(_stageReward.medal) > 0)
         {
            _guaranteedItems.push({
               "type":"medal",
               "value":Number(_stageReward.medal),
               "count":Number(_stageReward.medal)
            });
         }
         if(_stageReward.items is Array)
         {
            for each(_itemRow in _stageReward.items)
            {
               if(_itemRow && _itemRow.eid && int(_itemRow.num) > 0)
               {
                  _guaranteedItems.push({
                     "type":"equip",
                     "value":String(_itemRow.eid),
                     "count":int(_itemRow.num)
                  });
               }
            }
         }
         if(_stageReward.heroes is Array)
         {
            for each(_itemRow in _stageReward.heroes)
            {
               if(_itemRow && _itemRow.aid && int(_itemRow.num) > 0)
               {
                  _guaranteedItems.push({
                     "type":"avatar",
                     "value":String(_itemRow.aid),
                     "count":int(_itemRow.num)
                  });
               }
            }
         }
         if(_firstClear)
         {
            if(Number(_firstClearReward.coin) > 0)
            {
               _firstClearItems.push({
                  "type":"coin",
                  "value":Number(_firstClearReward.coin),
                  "count":Number(_firstClearReward.coin)
               });
            }
            if(Number(_firstClearReward.mark) > 0)
            {
               _firstClearItems.push({
                  "type":"mark",
                  "value":Number(_firstClearReward.mark),
                  "count":Number(_firstClearReward.mark)
               });
            }
            if(Number(_firstClearReward.medal) > 0)
            {
               _firstClearItems.push({
                  "type":"medal",
                  "value":Number(_firstClearReward.medal),
                  "count":Number(_firstClearReward.medal)
               });
            }
            if(_firstAttrs.dust is Array)
            {
               _dustIndex = 0;
               while(_dustIndex < _firstAttrs.dust.length)
               {
                  _dustAmount = int(_firstAttrs.dust[_dustIndex]);
                  if(_dustAmount > 0)
                  {
                     _firstClearItems.push({
                        "type":"dust",
                        "value":{
                           "indexID_s":_dustIndex,
                           "numberIndex":_dustAmount
                        },
                        "count":_dustAmount
                     });
                  }
                  _dustIndex++;
               }
            }
            if(Number(_firstAttrs.dn_stone) > 0)
            {
               _firstClearItems.push({
                  "type":"dn_stone",
                  "value":Number(_firstAttrs.dn_stone),
                  "count":Number(_firstAttrs.dn_stone)
               });
            }
            if(Number(_firstAttrs.culture_book) > 0)
            {
               _firstClearItems.push({
                  "type":"culture_book",
                  "value":Number(_firstAttrs.culture_book),
                  "count":Number(_firstAttrs.culture_book)
               });
            }
            if(_firstClearReward.items is Array)
            {
               for each(_itemRow in _firstClearReward.items)
               {
                  if(_itemRow && _itemRow.eid && int(_itemRow.num) > 0)
                  {
                     _firstClearItems.push({
                        "type":"equip",
                        "value":String(_itemRow.eid),
                        "count":int(_itemRow.num)
                     });
                  }
               }
            }
            if(_firstClearReward.heroes is Array)
            {
               for each(_itemRow in _firstClearReward.heroes)
               {
                  if(_itemRow && _itemRow.aid && int(_itemRow.num) > 0)
                  {
                     _firstClearItems.push({
                        "type":"avatar",
                        "value":String(_itemRow.aid),
                        "count":int(_itemRow.num)
                     });
                  }
               }
            }
         }
         if(_guaranteedItems.length > 0)
         {
            var _guaranteedTitle:TextField = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(98242),16,_loc10_,"left",485,24);
            _guaranteedTitle.x = 0;
            _guaranteedTitle.y = _rewardY;
            _guaranteedTitle.touchable = false;
            this.mDetails.addChild(_guaranteedTitle);
            _rewardY += 23;
            _rewardY = addRewardPreviewItems(this.mDetails,_guaranteedItems,_rewardY);
         }
         if(_firstClearItems.length > 0)
         {
            var _firstClearTitle:TextField = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(98243),16,_loc10_,"left",485,24);
            _firstClearTitle.x = 0;
            _firstClearTitle.y = _rewardY + 3;
            _firstClearTitle.touchable = false;
            this.mDetails.addChild(_firstClearTitle);
            _rewardY += 28;
            _rewardY = addRewardPreviewItems(this.mDetails,_firstClearItems,_rewardY);
         }
         this.mH_max = Math.max(this.mH_max,this.mDetails.y + _rewardY + 16);
         this.addEventListener("touch",this.onTOUCH);
      }
      
      private function addRandomHeroDropPreview(param1:Sprite, param2:Array, param3:Number) : Number
      {
         var _row:Object = null;
         var _result:Object = null;
         var _icon:* = null;
         var _cell:Sprite = null;
         var _nameField:TextField = null;
         var _chanceField:TextField = null;
         var _map:Object = null;
         var _avatar:Object = null;
         var _aid:String = null;
         var _name:String = null;
         var _totalBp:Number = 0;
         var _chanceBp:Number = 0;
         var _cardChance:Number = 0;
         var _index:int = 0;
         var _rowY:Number = param3 + 25;
         var _cellX:Number = 0;
         for each(_row in param2)
         {
            _totalBp += Number(_row.chance_bp);
         }
         var _totalChance:Number = _totalBp / (param2.length * 100);
         var _title:TextField = GlobalTextStyle.getTextField("随机英雄（每场均匀抽1名，总掉率 " + _totalChance.toFixed(2) + "%）",15,16777215,"left",485,23);
         _title.x = 0;
         _title.y = param3;
         _title.touchable = false;
         param1.addChild(_title);
         for each(_row in param2)
         {
            _aid = String(_row.aid);
            _map = {};
            _map[_aid] = 1;
            _result = GlobalFunction.getAwardByType("avatar",_map,false,null,"",false,0.62);
            _icon = _result ? _result.ui : null;
            _cell = new Sprite();
            _cell.touchable = false;
            _cellX = (_index % 4) * 120;
            _rowY = param3 + 24 + int(_index / 4) * 91;
            if(_icon)
            {
               _icon.touchable = false;
               _icon.x = Math.max(0,(116 - _icon.width) * 0.5);
               _icon.y = 0;
               _cell.addChild(_icon);
            }
            _avatar = GlobalData.$mConfig_avatar ? GlobalData.$mConfig_avatar[_aid] : null;
            _name = _avatar && _avatar.name ? String(_avatar.name) : _aid;
            _nameField = GlobalTextStyle.getTextField(_name,11,16777215,"center",116,20);
            _nameField.x = 0;
            _nameField.y = 52;
            _nameField.touchable = false;
            _cell.addChild(_nameField);
            _chanceBp = Number(_row.chance_bp);
            _cardChance = _chanceBp / (param2.length * 100);
            _chanceField = GlobalTextStyle.getTextField("本卡 " + _cardChance.toFixed(2) + "%",11,16776960,"center",116,18);
            _chanceField.x = 0;
            _chanceField.y = 71;
            _chanceField.touchable = false;
            _cell.addChild(_chanceField);
            _cell.x = _cellX;
            _cell.y = _rowY;
            param1.addChild(_cell);
            _index++;
         }
         return param3 + 24 + Math.ceil(param2.length / 4) * 91 + 4;
      }
      
      private function addRewardPreviewItems(param1:Sprite, param2:Array, param3:Number) : Number
      {
         var _row:Object = null;
         var _result:Object = null;
         var _icon:* = null;
         var _cell:Sprite = null;
         var _count:TextField = null;
         var _value:* = null;
         var _countValue:int = 0;
         var _index:int = 0;
         var _rowY:Number = param3;
         var _cellX:Number = 0;
         var _map:Object = null;
         for each(_row in param2)
         {
            _value = _row.value;
            if(_row.type == "equip" || _row.type == "avatar")
            {
               _map = {};
               _map[String(_value)] = int(_row.count);
               _value = _map;
            }
            _result = GlobalFunction.getAwardByType(String(_row.type),_value,false,null,"",false,0.62);
            _icon = _result ? _result.ui : null;
            if(_icon)
            {
               _cell = new Sprite();
               _cell.touchable = false;
               _index = param2.indexOf(_row);
               _cellX = _index % 6 * 80;
               _rowY = param3 + int(_index / 6) * 78;
               _icon.touchable = false;
               _icon.x = 5;
               _icon.y = 0;
               _cell.addChild(_icon);
               _countValue = int(_row.count);
               if(_countValue > 0)
               {
                  _count = GlobalTextStyle.getTextField("×" + String(_countValue),13,16777215,"center",70,18);
                  _count.x = 0;
                  _count.y = 53;
                  _count.touchable = false;
                  _cell.addChild(_count);
               }
               _cell.x = _cellX;
               _cell.y = _rowY;
               param1.addChild(_cell);
            }
         }
         if(param2.length == 0)
         {
            return param3;
         }
         return param3 + Math.ceil(param2.length / 6) * 78;
      }
      
      private function onTOUCH(param1:TouchEvent) : void
      {
         var _loc3_:Touch = null;
         var _debugTouch:Touch = null;
         var _debugPoint:Point = null;
         var _loc2_:int = 0;
         var _loc6_:int = 0;
         var _loc4_:int = 0;
         var _loc8_:List = null;
         var _loc7_:DisplayObjectContainer = null;
         var _loc5_:int = 0;
         if(GlobalData.$tempPVE_type == "status_pve_activities")
         {
            _debugTouch = param1.getTouch(this,"ended");
            if(_debugTouch && RpcStaticCall.$remoting)
            {
               _debugPoint = _debugTouch.getLocation(this);
               RpcStaticCall.$remoting.reportDiagnostic("PVE_ACTIVITY_CARD_TOUCH id=" + (String(this.data ? this.data.id : "")) + " status=" + (String(this.data ? this.data["status"] : "")) + " local=" + String(_debugPoint.x) + "," + String(_debugPoint.y) + " item=" + String(this.width) + "x" + String(this.height) + " bg=" + (String(this.mImg9_bg ? this.mImg9_bg.width : -1)) + "x" + (String(this.mImg9_bg ? this.mImg9_bg.height : -1)) + " button=" + (this.mBtn_bg_lv ? this.mBtn_bg_lv.x + "," + this.mBtn_bg_lv.y + "," + this.mBtn_bg_lv.width + "x" + this.mBtn_bg_lv.height : "null") + " details=" + (this.mDetails ? this.mDetails.x + "," + this.mDetails.y + "," + this.mDetails.width + "x" + this.mDetails.height : "null") + " bgHit=" + (String(this.mImg9_bg && param1.getTouch(this.mImg9_bg,"ended"))) + " target=" + String(_debugTouch.target));
            }
         }
         if(this.mImg9_bg)
         {
            _loc3_ = param1.getTouch(this.mImg9_bg,"ended");
            if(_loc3_)
            {
               _loc2_ = this.data["status"] == 1 ? 0 : 1;
               _loc6_ = int(this.data["status"]);
               if(_loc6_ != _loc2_)
               {
                  _loc4_ = 0;
                  _loc8_ = null;
                  if(this.parent)
                  {
                     _loc7_ = this.parent as DisplayObjectContainer;
                     _loc5_ = _loc7_.numChildren;
                     if(_loc7_)
                     {
                        if(_loc7_.parent)
                        {
                           _loc8_ = _loc7_.parent as List;
                        }
                     }
                  }
                  if(_loc8_)
                  {
                     if(_loc8_.isScrolling)
                     {
                        return;
                     }
                     for(var _loc9_:Object in _loc8_.dataProvider.data)
                     {
                        if(_loc8_.dataProvider.data[_loc9_].id != this.data.id)
                        {
                           _loc8_.dataProvider.data[_loc9_]["status"] = 0;
                        }
                        else
                        {
                           _loc8_.dataProvider.data[_loc9_]["status"] = _loc2_;
                        }
                        _loc8_.dataProvider.updateItemAt(_loc4_);
                        _loc4_ += 1;
                     }
                     _loc8_.dataProvider.dispatchEventWith("change");
                  }
               }
            }
         }
      }
      
      override public function changeUILayout() : void
      {
         var _loc1_:Boolean = this.data["status"] == 1;
         if(_loc1_)
         {
            if(!mBaseSpr.contains(this.mDetails))
            {
               mBaseSpr.addChild(this.mDetails);
            }
         }
         else
         {
            mBaseSpr.removeChild(this.mDetails);
         }
      }
      
      override public function onTRIGGERED(param1:Event) : void
      {
      }
      
      override public function changeH() : void
      {
         var _loc2_:Boolean = false;
         var _loc4_:List = null;
         var _loc3_:DisplayObjectContainer = null;
         var _loc1_:int = 0;
         if(mImg9_bg)
         {
            _loc2_ = this.data["status"] == 1;
            _quad.visible = _loc2_;
            this.height = mImg9_bg.height = _loc2_ ? this.mH_max : this.mH_min;
            mArrowsSpr.y = mImg9_bg.y + mImg9_bg.height - mArrowsSpr.height - 12;
            this.mArrows_topbg.scaleY = _loc2_ ? -1 : 1;
            if(rndList)
            {
               mBaseSpr.y = mRndSpr.height * 0.8;
               this.height += mBaseSpr.y;
            }
            this.changeUILayout();
            if(_loc2_ && GlobalData.$tempPVE_type == "status_pve_activities" && RpcStaticCall.$remoting)
            {
               RpcStaticCall.$remoting.reportDiagnostic("PVE_ACTIVITY_CARD_EXPANDED id=" + (String(this.data ? this.data.id : "")) + " status=" + (String(this.data ? this.data["status"] : "")) + " item=" + String(this.width) + "x" + String(this.height) + " bg=" + String(mImg9_bg.width) + "x" + String(mImg9_bg.height) + " details=" + (this.mDetails ? this.mDetails.x + "," + this.mDetails.y + "," + this.mDetails.width + "x" + this.mDetails.height : "null"));
            }
            _loc4_ = null;
            if(_loc2_ && this.parent)
            {
               _loc3_ = this.parent as DisplayObjectContainer;
               _loc1_ = _loc3_.numChildren;
               if(_loc3_)
               {
                  if(_loc3_.parent)
                  {
                     _loc4_ = _loc3_.parent as List;
                     if(_loc4_)
                     {
                        if(_loc4_.dataProvider.length - 1 == index)
                        {
                           _loc4_.scrollToDisplayIndex(this.index);
                        }
                     }
                  }
               }
            }
         }
      }
      
      private function showNextFriend() : void
      {
         GlobalData.$tempPVE_combatID = this.data.id;
         var _loc1_:GameMapData = GameMapManager.getOnlyExample().getData(data.id);
         if(!GameMap.canHelp(data.id))
         {
            GlobalData.$isNoFriendToPVE = true;
            GlobalData.$tempHelpAvatar = null;
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pve_embattle",false,true);
         }
         else
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pve_friend",false,true);
         }
      }
      
      private function onTRIGGERED_btn(param1:Event) : void
      {
         var _loc7_:Object = null;
         var _loc6_:GameMapData = null;
         var _loc9_:int = 0;
         var _loc5_:Object = null;
         var _loc4_:Array = null;
         var _loc2_:int = 0;
         var _loc3_:int = 0;
         var _loc8_:int = 0;
         GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
         if(GlobalData.$userData_avatarNum < GlobalData.$userData.attrs.avatar_len)
         {
            if((GlobalData.$tempPVE_type == "status_pve_hard" || GlobalData.$tempPVE_type == "status_pve_activities") && Tools.getElementNum(GlobalData.$userData.my_equips) >= int(GlobalData.$mConfig_simple.equip_config[0]))
            {
               GlobalFunction.popEquipFull();
            }
            else
            {
               if(this.data.needvip > GlobalData.$userData.vip_lv)
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97685));
                  return;
               }
               this.isPlay = false;
               _loc6_ = GameMapManager.getOnlyExample().getData(data.id);
               _loc9_ = _loc6_.getEnergy(diff);
               _loc5_ = GlobalFunction.getEnergy();
               if(_loc5_.energy >= _loc9_ && this.mLimit > 0 && _loc5_.max >= _loc9_)
               {
                  this.isPlay = true;
               }
               if(this.isPlay)
               {
                  if(mHardType >= 5)
                  {
                     GlobalFunction.popHardGuide(showNextFriend);
                     param1.stopPropagation();
                  }
                  else
                  {
                     showNextFriend();
                  }
               }
               else if(this.mLimit > 0)
               {
                  _loc4_ = GlobalData.$mConfig_simple.energy_config as Array;
                  _loc7_ = {
                     "ok":GlobalFunction.service_energy,
                     "no":GlobalFunction.functionNull
                  };
                  _loc2_ = int(_loc4_[5]);
                  _loc2_ += int(GlobalFunction.getVipLv() > 0 ? GlobalFunction.getVipObj().buy_energy : 0);
                  _loc3_ = _loc2_ - GlobalData.$userData.records.energy_times;
                  _loc8_ = _loc4_[4] + _loc4_[7] * GlobalData.$userData.records.energy_times;
                  if(_loc3_ > 0)
                  {
                     if(_loc5_.maxExtra < _loc9_)
                     {
                        GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90052));
                     }
                     else
                     {
                        GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(20095),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90002,_loc8_,_loc2_,_loc3_),GlobalTextStyle.COLOR_W_Y_Y_G),_loc7_);
                     }
                  }
                  else
                  {
                     GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90032,_loc2_));
                  }
               }
               else
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90031));
               }
            }
         }
         else
         {
            GlobalFunction.popAvatarLen();
         }
      }
   }
}

