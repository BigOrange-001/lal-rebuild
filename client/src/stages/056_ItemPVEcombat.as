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
         mH_max = 142;
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
         var _loc13_:GameMapData = GameMapManager.getOnlyExample().getData(data.id);
         mBossId = _loc13_.bossId;
         this.setAvatar(mBossId,0,null);
         mBaseSpr.addChild(this.mAvatar);
         mAvatar.touchable = false;
         this.mAvatar.x = 30;
         this.mAvatar.y = 15;
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
         if(GlobalData.$tempPVE_type == "status_pve_activities" && this.data.activity_kind == "material" && this.data.material_kind != "skill_biscuit")
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
         var _loc9_:Number = _loc13_.getUserPower(diff);
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
         // Keep only combat guidance in the expanded card. The stage reward
         // payload remains on the server; this card does not preview it.
         var _detailsBottom:Number = _loc42_.y + _loc42_.height;
         if(data.info != null && String(data.info) != "")
         {
            var _description:TextFieldHtmlRenderer = GlobalTextStyle.getHtmlTextRenderer();
            _description.x = 0;
            _description.y = _detailsBottom;
            _description.width = 485;
            _description.height = 34;
            _description.touchable = false;
            _description.text = Tools.formatLineX(String(data.info),[_loc17_],28,MainConfig.$isEnglish ? 15 : 16,false);
            _description.height = Math.max(34,_description.text.split("\n").length * 24 + 8);
            this.mDetails.addChild(_description);
            _detailsBottom = _description.y + _description.height;
         }
         // Leave space for the existing expand/collapse arrow without the
         // former reward grid's empty height.
         this.mH_max = Math.max(this.mH_min + 1,Math.ceil(this.mDetails.y + _detailsBottom + mArrowsSpr.height + 20));
         this.addEventListener("touch",this.onTOUCH);
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

