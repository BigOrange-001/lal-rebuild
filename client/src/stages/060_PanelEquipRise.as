package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.equip.Equip;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.ui.element.ItemEquip;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelCenterMainAvatar;
   import com.meng52.game.ui.stage.GuideTools;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import starling.animation.Juggler;
   import starling.core.Starling;
   import starling.display.DisplayObject;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.EnterFrameEvent;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.extensions.PDParticleSystem;
   import starling.text.TextField;
   
   public class PanelEquipRise extends PanelCenterMainAvatar
   {
      
      public static var $selectType:int = 0;
      
      protected var mCurrEquip:ItemEquip;
      
      protected var mBtn_to:LOL_Scale9Button;
      
      protected var mBtn_riseByonce:LOL_Scale9Button;
      
      protected var mBox_dataUp:Sprite;
      
      protected var mPrice_num:int = 0;
      
      protected var mCurr_lv:int = 0;
      
      protected var mImg9_base:Scale9Image;
      
      protected var mImg9_new:Scale9Image;
      
      protected var mStatus_up:Boolean = false;
      
      protected var mSpr_:Sprite;
      
      protected var mClip_pause:Number;
      
      protected var mJuggler_upLv:Juggler;
      
      protected var mParticleSystem:PDParticleSystem;
      
      public var mBox_data:Sprite;
      
      public var mBox_team:Sprite;
      
      public var mBg_team:Image;
      
      public var mBg_data:Image;
      
      public var mArr_team:Array;
      
      public var mRuler_item:Number = 0;
      
      public var mBox_equip:Sprite;
      
      public var _mTxt_currentCoin:LOL_MutilTextFieldIcon;
      
      private var _spRule:Sprite;
      
      private var _btn_status:Boolean = false;

      private var _riseBatchRemaining:int = 0;
      private var riseBefore:Object;
      
      private const MBTN_TO:String = "mbtn_to";
      
      private const MBTN_RISEBYONCE:String = "mbtn_risebyonce";
      
      public function PanelEquipRise()
      {
         super();
         GlobalData.$mEventDispatcher.addEventListener("profile_state_sync",onProfileStateSync);
      }

      private function onProfileStateSync(param1:Event) : void
      {
         var _selectedEid:String = GlobalData.$tempEquipCurrSelected;
         if(stage == null || mBox_equip == null || _selectedEid == "" || _btn_status || _riseBatchRemaining > 0 || mStatus_up || riseBefore != null)
         {
            return;
         }
         if(GlobalData.$userData.my_equips[_selectedEid] != null)
         {
            updateAttUIs();
         }
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         setPopPanelBg(GlobalLanguageStr.getLanguageStr(90411));
         initOtherUIs();
      }
      
      override public function onTRIGGERED_closePanel(param1:Event) : void
      {
         _btn_status = false;
         _riseBatchRemaining = 0;
         GlobalData.$mGameClassObject.mLayoutUICenter.reSetLastPanel_ID();
         GlobalData.$mEventDispatcher.dispatchEventWith("update_equip_list_data");
         super.onTRIGGERED_closePanel(null);
         if(PanelTeamListInfo.isTeamListInfo)
         {
            LayoutUIAnimation.getOnlyExample().clearIfNoGuide();
         }
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalData.$mEventDispatcher.removeEventListener("profile_state_sync",onProfileStateSync);
         _btn_status = false;
         _riseBatchRemaining = 0;
         GlobalData.$mGameClassObject.touchable = true;
         if(mParticleSystem)
         {
            mParticleSystem.stop();
            mParticleSystem.removeFromParent(true);
            if(mJuggler_upLv)
            {
               mJuggler_upLv.remove(mParticleSystem);
            }
         }
         if(mJuggler_upLv)
         {
            mJuggler_upLv.purge();
         }
         if(mSpr_)
         {
            mSpr_.removeFromParent(true);
         }
         if(mBox_equip)
         {
            StarlingTools.removeChildrenClear(mBox_equip);
            mBox_equip.removeFromParent(true);
         }
         if(mCurrEquip)
         {
            mCurrEquip.clear();
            mCurrEquip.removeFromParent(true);
         }
         if(mBtn_to)
         {
            mBtn_to.removeFromParent(true);
         }
         if(mImg9_base)
         {
            mImg9_base.removeFromParent(true);
         }
         if(mImg9_new)
         {
            mImg9_new.removeFromParent(true);
         }
         if(_spRule)
         {
            _spRule.removeEventListener("touch",onTRIGGERED_help);
         }
         if(mBox_dataUp)
         {
            StarlingTools.removeChildrenClear(mBox_dataUp);
            mBox_dataUp.removeFromParent(true);
         }
         if(_mTxt_currentCoin)
         {
            _mTxt_currentCoin.dispose();
            _mTxt_currentCoin.removeFromParent(true);
         }
         _mTxt_currentCoin = null;
         super.onREMOVED_FROM_STAGE(param1);
         mParticleSystem = null;
         mCurrEquip = null;
         mBtn_to = null;
         mImg9_base = null;
         mImg9_new = null;
         mBox_dataUp = null;
         mBox_equip = null;
         mJuggler_upLv = null;
         mSpr_ = null;
         GlobalData.$tempEquipCurrSelected = "";
      }
      
      public function checkGuide() : void
      {
         var _loc1_:Equip = null;
         LayoutUIAnimation.getOnlyExample().clearIfNoGuide();
         if(mStatus_up)
         {
            return;
         }
         var _loc2_:String = GuideTools.checkGuideType();
         if(_loc2_ == "4")
         {
            if(mCurrEquip && mCurrEquip.data && mCurrEquip.data.id != "")
            {
               _loc1_ = new Equip(mCurrEquip.data.id);
               if(_loc1_.lv < 5)
               {
                  LayoutUIAnimation.getOnlyExample().addArrowhead(482,751,50);
               }
            }
         }
      }
      
      public function initOtherUIs() : void
      {
         mPrice_num = 0;
         mCurr_lv = 0;
         mStatus_up = false;
         mJuggler_upLv = new Juggler();
         addEventListener("enterFrame",onENTER_FRAME_clip);
         mBox_equip = new Sprite();
         mBox_equip.addEventListener("touch",onTOUCH_att);
         mBox_equip.x = 75;
         mBox_equip.y = 220;
         addChild(mBox_equip);
         var _loc6_:Object = GlobalData.$userData.my_equips[GlobalData.$tempEquipCurrSelected];
         var _loc5_:Boolean = _loc6_ != null;
         _loc6_ = _loc6_ == null ? {} : _loc6_;
         _loc6_["status"] = -1;
         _loc6_["id"] = _loc6_ == null ? null : GlobalData.$tempEquipCurrSelected;
         mCurrEquip = new ItemEquip();
         mCurrEquip.data = _loc6_;
         mCurrEquip.y = -120;
         mBox_equip.addChild(mCurrEquip);
         if(!_loc5_)
         {
            setChangeStatusUI();
            return;
         }
         mImg9_base = GlobalFunction.createScale9Image("UI_bg_9slice_7_0000",490,350,new Rectangle(25,25,10,10));
         mBox_equip.addChild(mImg9_base);
         var _loc2_:Number = GlobalData.$center_height_curr - 121;
         var _loc1_:Number = 0;
         var _loc3_:Number = 0;
         mBtn_to = new LOL_Scale9Button("强化一次",155,70,"UI_btn_normalFun_0000");
         mBtn_to.addEventListener("triggered",onTRIGGERED_up);
         mBtn_to.name = "mbtn_to";
         mBtn_to.enabled = _btn_status;
         addChild(mBtn_to);
         _mTxt_currentCoin = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getLanguageStr(90444),"0","UI_money_gold_0_0000");
         addChild(_mTxt_currentCoin);
         // The bounded ten-upgrade action is available to everyone. VIP only
         // affects the server-side probability of a critical upgrade.
         if(mBtn_to != null)
         {
            mBtn_riseByonce = new LOL_Scale9Button("强化十次",155,70,"UI_btn_normalFun_0000");
            mBtn_riseByonce.addEventListener("triggered",onTRIGGERED_up);
            mBtn_riseByonce.name = "mbtn_risebyonce";
            if(MainConfig.$isEA)
            {
               mBtn_riseByonce.fontSize = 22;
            }
            mBtn_riseByonce.x = mImg9_base.x + 70;
            mBtn_riseByonce.y = 620;
            addChild(mBtn_riseByonce);
            mBtn_to.x = mImg9_base.x + mImg9_base.width - mBtn_to.width + 70;
            mBtn_to.y = 620;
            _mTxt_currentCoin.x = this.mImg9_baseBg.x + (this.mImg9_baseBg.width - _mTxt_currentCoin.textFieldWidth) * 0.5 - 25;
            _mTxt_currentCoin.y = mBtn_to.y - _mTxt_currentCoin.height;
         }
         else
         {
            mBtn_to.x = mImg9_base.x + mImg9_base.width - mBtn_to.width + 70;
            mBtn_to.y = 600;
            _mTxt_currentCoin.x = mCurrEquip.x + 80;
            _mTxt_currentCoin.y = mBtn_to.y + 20;
         }
         var _loc4_:Object = GlobalFunction.get_HelpLink(GlobalLanguageStr.getLanguageStr(90517));
         _spRule = _loc4_.ui;
         _spRule.x = _width - _loc4_.w - 40;
         _spRule.y = 88;
         addChild(_spRule);
         _spRule.addEventListener("touch",onTRIGGERED_help);
         updateAttUIs();
      }
      
      private function onTRIGGERED_help(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(_spRule);
         if(_loc2_)
         {
            if(_loc2_.phase == "ended")
            {
               GlobalFunction.popPanelHelp(MainConfig.SERVER_ADDRESS_HELP_ADD_RISE);
            }
         }
      }
      
      protected function setChangeStatusUI() : void
      {
         if(mBox_equip)
         {
            mBox_equip.x = int((GlobalData.$mStageWidth - 100) * 0.5);
            mBox_equip.y = int((GlobalData.$center_height_curr - 121 - 100) * 0.5);
            mParticleSystem = new PDParticleSystem(GlobalData.$assetManager.getXml("drugs"),GlobalFunction.getTexture("drugs_particle"));
            mParticleSystem.x = 50;
            mParticleSystem.y = 50;
            mBox_equip.addChildAt(mParticleSystem,0);
            mJuggler_upLv.add(mParticleSystem);
            mParticleSystem.start();
            checkGuide();
         }
      }
      
      protected function onTOUCH_att(param1:TouchEvent) : void
      {
         var _loc2_:Touch = null;
         var _loc3_:Array = null;
         if(mBox_equip && mImg9_new)
         {
            _loc2_ = param1.getTouch(mImg9_new);
            if(_loc2_)
            {
               if(_loc2_.phase == "began")
               {
                  _loc3_ = [Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90109),GlobalTextStyle.COLOR_W_W_Y_G,20),"",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90110),GlobalTextStyle.COLOR_W_W_Y_G,20),"",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90111),GlobalTextStyle.COLOR_W_W_Y_G,20),"",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90112),GlobalTextStyle.COLOR_W_W_Y_G,20)];
                  GlobalFunction.popTips("",Tools.formatHtmlTextBr(_loc3_,"center"));
               }
               else if(_loc2_.phase == "ended")
               {
                  GlobalData.$mGameClassObject.closePopUp();
               }
            }
         }
      }
      
      protected function onENTER_FRAME_clip(param1:EnterFrameEvent) : void
      {
         if(mJuggler_upLv)
         {
            mJuggler_upLv.advanceTime(param1.passedTime);
            if(mSpr_)
            {
               GlobalData.$mGameClassObject.touchable == false;
               if(!mSpr_.stage)
               {
                  mClip_pause += 1;
                  if(mClip_pause > 5)
                  {
                     mSpr_ = null;
                     GlobalData.$mGameClassObject.touchable = true;
                     mClip_pause = 0;
                  }
               }
            }
         }
      }
      
      private function updateAttUIs(param1:Boolean = false, param2:int = 0, param3:int = 1) : void
      {
         var _type:int;
         var _list:String;
         var tweenComplete:*;
         var _data:Object;
         var _equip:Equip;
         var _onlyClear:Boolean = param1;
         var _upLvGrade:int = param2;
         var _lvTimes:int = param3;
         if(mBox_data)
         {
            StarlingTools.removeChildrenClear(mBox_data);
            mBox_data.removeFromParent(true);
         }
         mBox_data = null;
         if(mBox_dataUp)
         {
            StarlingTools.removeChildrenClear(mBox_dataUp);
            mBox_dataUp.removeFromParent(true);
         }
         mBox_dataUp = null;
         if(!_onlyClear)
         {
            if(mImg9_base == null)
            {
               return;
            }
            mBox_data = getAttBase(GlobalData.$tempEquipCurrSelected);
            mBox_data.touchable = false;
            mBox_data.x = mImg9_base.x + 50;
            mBox_data.y = mImg9_base.y + 50;
            mBox_equip.addChild(mBox_data);
            if(mCurr_lv < GlobalFunction.getEquipRiseMaxLv() && mStatus_up)
            {
               tweenComplete = function():void
               {
                  mStatus_up = false;
                  riseBefore = null;
                  updateAttUIs();
                  GlobalData.$mGameClassObject.touchable = true;
                  GuideMaster.getOnlyExample().checkGuide("M4_2",checkGuide);
               };
               mBox_dataUp = getAttBase(GlobalData.$tempEquipCurrSelected,true,_lvTimes);
               mBox_dataUp.touchable = false;
               mBox_dataUp.x = mBox_data.x + 220;
               mBox_dataUp.y = mBox_data.y;
               mBox_equip.addChild(mBox_dataUp);
               mBox_dataUp.pivotX = 30;
               mBox_dataUp.alpha = 0;
               if(!_btn_status)
               {
                  GlobalData.$mGameClassObject.touchable = false;
               }
               if(_upLvGrade > 0)
               {
                  mClip_pause = 0;
                  if(mSpr_ && mJuggler_upLv)
                  {
                     mSpr_.removeFromParent(true);
                  }
                  mSpr_ = null;
                  _type = _upLvGrade == 1 ? 1 : 2;
                  _list = _type == 1 ? "50004" : "50003";
                  mSpr_ = LayoutUIAnimation.getOnlyExample().popSuperWord(_list,_type,0.65);
               }
               mJuggler_upLv.tween(mBox_dataUp,1,{
                  "onComplete":tweenComplete,
                  "transition":"easeOut",
                  "alpha":1,
                  "pivotX":0
               });
            }
            _data = GlobalData.$userData.my_equips[GlobalData.$tempEquipCurrSelected];
            if(_data != null)
            {
               _equip = new Equip(GlobalData.$tempEquipCurrSelected,_data);
               mPrice_num = _equip.getRiseGold();
               mCurr_lv = _equip.lv;
               if(_mTxt_currentCoin)
               {
                  _mTxt_currentCoin.txt2 = mPrice_num.toString();
               }
            }
            if(mBtn_to && !_btn_status)
            {
               mBtn_to.enabled = mPrice_num != 0;
            }
         }
         checkGuide();
      }
      
      private function send_rise_fun() : void
      {
         var _data:Object;
         var reSetStatus:* = function():void
         {
            chengeStutes(true);
            if(mBtn_to)
            {
               mBtn_to.touchable = true;
            }
            _btn_status = false;
            _riseBatchRemaining = 0;
            if(mBtn_riseByonce)
            {
               mBtn_riseByonce.text = "强化十次";
            }
         };
         var _b:Boolean = true;
         if(GlobalData.$userData.gold < mPrice_num)
         {
            _b = false;
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10023),false,"A_6999_3");
            reSetStatus();
            return;
         }
         if(mCurr_lv >= GlobalFunction.getEquipRiseMaxLv())
         {
            _b = false;
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90083));
            reSetStatus();
            return;
         }
         _data = GlobalData.$userData.my_equips[GlobalData.$tempEquipCurrSelected];
         if(_data == null)
         {
            _b = false;
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90084));
            reSetStatus();
            return;
         }
         if(_b == true)
         {
            riseBefore = Tools.clone(_data);
            SendServiceAMFFun.send_user_equip_rise(re_equip_rise,{
               "eqid":GlobalData.$tempEquipCurrSelected,
               "lv":mCurr_lv
            });
         }
      }
      
      private function onTRIGGERED_up(param1:Event) : void
      {
         var _loc3_:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         var _loc2_:String = _loc3_.name;
         switch(_loc2_)
         {
            case "mbtn_to":
               _btn_status = false;
               if(_loc3_.enabled && riseBefore == null && !mStatus_up)
               {
                  send_rise_fun();
               }
               break;
            case "mbtn_risebyonce":
               if(!_btn_status && (riseBefore != null || mStatus_up)) return;
               _btn_status = !_btn_status;
               if(_btn_status)
               {
                  _riseBatchRemaining = 10;
                  chengeStutes();
                  mBtn_to.touchable = false;
                  _loc3_.text = "停止强化";
                  send_rise_fun();
               }
               else
               {
                  _riseBatchRemaining = 0;
                  chengeStutes(true);
                  mBtn_to.touchable = true;
                  _loc3_.text = "强化十次";
               }
         }
      }
      
      private function chengeStutes(param1:Boolean = false) : void
      {
         mBox_equip.touchable = param1;
         _spRule.touchable = param1;
         mBtn_to.enabled = param1;
      }
      
      private function re_equip_rise(param1:Object) : void
      {
         var _dataArr:Array;
         var _data:Object;
         var _lvPv:int;
         var _multiple:Object;
         var _multipleArr:Array;
         var i:Object;
         var _index:int;
         var _arr:Object;
         var _rec:Rectangle;
         var _x:int;
         var _y:int;
         var delaycall:*;
         var _re:Object = param1;
         var _eid:String = _re["params"]["eqid"];
         if(stage == null || _eid != GlobalData.$tempEquipCurrSelected) return;
         if(GlobalFunction.isMalformedProfileReceipt(_re))
         {
            riseBefore = null;
            mStatus_up = false;
            _btn_status = false;
            _riseBatchRemaining = 0;
            chengeStutes(true);
            return;
         }
         if(GlobalFunction.isLegacyProfileReceipt(_re))
         {
            RpcStaticCall.$remoting.reportDiagnostic("PROFILE_RECEIPT_LEGACY|method=user.equip_rise");
         }
         var _snapshotApplied:Boolean = GlobalFunction.didApplyProfileStateSync(_re);
         mStatus_up = true;
         if(_re.data)
         {
            delaycall = function():void
            {
               var _current:Object = GlobalData.$userData.my_equips[_eid];
               if(_btn_status && _snapshotApplied && _riseBatchRemaining > 0 && _current != null && int(_current.lv) < GlobalFunction.getEquipRiseMaxLv())
               {
                  send_rise_fun();
               }
               else if(_btn_status)
               {
                  _btn_status = false;
                  _riseBatchRemaining = 0;
                  chengeStutes(true);
                  if(mBtn_to)
                  {
                     mBtn_to.touchable = true;
                  }
                  if(mBtn_riseByonce)
                  {
                     mBtn_riseByonce.text = "强化十次";
                  }
               }
            };
            _dataArr = _re.data;
            _data = GlobalData.$userData.my_equips[_eid];
            if(!_snapshotApplied || _data == null)
            {
               _btn_status = false;
               _riseBatchRemaining = 0;
               chengeStutes(true);
               if(mBtn_to)
               {
                  mBtn_to.touchable = true;
               }
               if(mBtn_riseByonce)
               {
                  mBtn_riseByonce.text = "强化十次";
               }
               return;
            }
            _lvPv = int(_dataArr[0]) - int(_re["params"]["lv"]);
            _multiple = GlobalData.$mConfig_simple.equip_multiple;
            _multipleArr = [];
            for(i in _multiple)
            {
               _multipleArr.push(int(i));
            }
            _multipleArr.sort();
            _index = 0;
            _index = _multipleArr.indexOf(_lvPv);
            updateAttUIs(false,_index,_lvPv);
            if(_lvPv > 1) LayoutUIAnimation.getOnlyExample().popWords("强化暴击：提升" + _lvPv + "级",2,GlobalData.$mStageHeight * 0.38);
            if(_btn_status && _riseBatchRemaining > 0)
            {
               _riseBatchRemaining--;
            }
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
            _arr = GlobalData.$userData;
            GlobalData.$tempTeamPowerTemp = GlobalFunction.getTeamPower(GlobalData.$userData.team[0]);
            SoundManager.getOnlyExample().playSound("E_9008");
            GuideTools.doModuleGuide("4",20);
            if(!stage || !mCurrEquip)
            {
               return;
            }
            _rec = mCurrEquip.getBounds(stage);
            _x = _rec.x + 51;
            _y = _rec.y + 51;
            LayoutUIAnimation.getOnlyExample().popEffect({
               "id":"e016",
               "x":_x,
               "y":_y,
               "sc":2
            });
            Starling.juggler.delayCall(delaycall,1.5);
         }
         else
         {
            riseBefore = null;
            mStatus_up = false;
            _btn_status = false;
            _riseBatchRemaining = 0;
            chengeStutes(true);
            if(mBtn_to)
            {
               mBtn_to.touchable = true;
            }
            if(mBtn_riseByonce)
            {
               mBtn_riseByonce.text = "强化十次";
            }
         }
      }
      
      public function getAttBase(param1:String, param2:Boolean = false, param3:int = 1) : Sprite
      {
         var _tNo1:TextField;
         var _equip:Equip;
         var _equipLv:int;
         var _tName:TextField;
         var _tLv:TextField;
         var _hasNewAtt:Boolean;
         var _colorNull:uint;
         var _eid:String = param1;
         var _isUp:Boolean = param2;
         var _lv:int = param3;
         var createAttTxt:* = function(param1:int, param2:int, param3:Boolean = false, param4:Boolean = false):void
         {
            var _loc7_:int = 0;
            var _loc6_:String = null;
            var _loc5_:* = 0;
            var _loc8_:TextField = null;
            if(param2 > 0 || param3)
            {
               if(!param4 && !_isUp)
               {
                  _loc7_ = _equip.haloLv;
                  if(_loc7_ > 0)
                  {
                     _color = Equip.haloColor[_loc7_ - 1];
                  }
               }
               _loc6_ = _isUp ? param2.toString() : GlobalLanguageStr.getLanguageStr(param1) + (param3 ? " " : " +") + param2;
               _loc5_ = uint(param4 && !_isUp ? 65484 : _color);
               _loc8_ = GlobalTextStyle.getTextField(_loc6_,20,!_isUp ? 16777215 : 65280,"left",_txtW,46);
               _loc8_.y = _attY + 20;
               _attY += _txtGap;
               _box.addChild(_loc8_);
               createUpIcon(_loc8_);
            }
         };
         var createUpIcon:* = function(param1:DisplayObject):void
         {
            var _loc2_:Image = null;
            if(_isUp)
            {
               _loc2_ = GlobalFunction.createImage("UI_equip_tag_0_0000");
               _loc2_.x = param1.x - _loc2_.width - 10;
               _loc2_.y = param1.y + 2;
               _box.addChild(_loc2_);
            }
         };
         var _box:Sprite = new Sprite();
         var _equipData:Object = !_isUp && mStatus_up && riseBefore != null ? riseBefore : GlobalData.$userData.my_equips[_eid];
         var _txtGap:int = 34;
         var _txtW:int = GlobalData.$mStageWidth * 0.5;
         var _color:uint = _isUp ? 52275 : 16777215;
         var _attY:Number = 0;
         var _h_txt_h:Number = 46;
         if(_equipData == null)
         {
            _tNo1 = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90084),24,_color,"left",_txtW,_h_txt_h);
            _tNo1.y = -29 - 20;
            _box.addChild(_tNo1);
            return _box;
         }
         _equip = new Equip(_eid,_equipData);
         _equipLv = int(_equip.lv);
         if(!_isUp)
         {
            _tName = GlobalTextStyle.getTextField(_equip.equipData.name,20,_color,"left",_txtW,_h_txt_h);
            _tName.x = 65;
            _tName.y = -170;
            _box.addChild(_tName);
            _attY = 5;
         }
         else
         {
            _attY = 5;
         }
         _tLv = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20079,_isUp ? _equipLv : _equip.lv),20,_color,"left",_txtW,_h_txt_h);
         _tLv.y = _attY - 20;
         _box.addChild(_tLv);
         createUpIcon(_tLv);
         _attY = _tLv.y + _txtGap;
         createAttTxt(98140,_equip.getHpMax(_equipLv));
         createAttTxt(98141,_equip.getDamage(_equipLv));
         createAttTxt(98142,_equip.getDePh(_equipLv));
         createAttTxt(98143,_equip.getDeMa(_equipLv));
         createAttTxt(98144,_equip.getRange());
         createAttTxt(98145,_equip.getSpeed());
         _attY = 130 + 10;
         _hasNewAtt = false;
         if(_equip.hasHit())
         {
            _hasNewAtt = true;
            createAttTxt(30021,_equip.getHit(_equipLv),false,true);
         }
         if(_equip.hasFlee())
         {
            _hasNewAtt = true;
            createAttTxt(30022,_equip.getFlee(_equipLv),false,true);
         }
         if(_equip.hasCrit())
         {
            _hasNewAtt = true;
            createAttTxt(30023,_equip.getCrit(_equipLv),false,true);
         }
         if(_equip.hasTough())
         {
            _hasNewAtt = true;
            createAttTxt(30024,_equip.getTough(_equipLv),false,true);
         }
         if(_hasNewAtt)
         {
            createAttTxt(20273,_equip.getPoteNow(_equipLv),true,true);
         }
         return _box;
      }
   }
}

