package com.meng52.game.ui.panel
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.command.map.GameMapData;
   import com.meng52.game.command.map.GameMapManager;
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalLocalStore;
   import com.meng52.game.global.GlobalPFANE;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.equip.Equip;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.module.map.GameMap;
   import com.meng52.game.module.map.GameMapConfig;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.element.ItemAvatarAward;
   import com.meng52.game.ui.element.ItemEquipAward;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_HtmlText;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.map.GameMapLayer;
   import com.meng52.game.ui.screen.PanelCenterMainAvatar;
   import com.meng52.game.ui.screen.PanelLogin;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.net.RpcStaticCall;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.HtmlTextFormat;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import flash.geom.Rectangle;
   import flash.utils.setTimeout;
   import starling.display.DisplayObject;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class PanelGameEndAward extends PanelCenterMainAvatar
   {
      
      private static var getL:int = 0;
      
      private var mBox:Sprite;
      
      private var mBox_avatar:Sprite;
      
      private var mBox_btn:Sprite;
      
      private var mAutoTF:TextField;
      
      private var mStatus_award:Boolean = false;
      
      private var mStatus_up:Boolean = false;
      
      private var mPower_old:Object;
      
      private var mPower_new:Object;
      
      private var isPassBattle:Boolean;
      
      private var mBg_touch:LOL_Button;
      
      private var mBtn_pvp:LOL_Scale9Button;
      
      private var mGiftCoin:int = 0;
      
      private var hasGuide:Boolean = false;
      
      private var mIsBinding:Boolean = false;
      
      private var mFragment_ok:Boolean = false;
      
      private var mPanelLogin:PanelLogin;
      
      private var isRandom_avatars:Boolean = false;
      
      private var _isFirstWin:Boolean = false;
      
      private var mDn_stone:Number = 0;
      
      private var mBeforeEn:Object;
      
      private var _txt:TextField;
      
      private var _isFightAward:Boolean = false;
      
      private var mTxtLV:LOL_HtmlText;
      
      private var mTxtEnergy:LOL_HtmlText;
      
      private var mTxtLeader:LOL_HtmlText;
      
      private var levelUp:TextField;
      
      private var functionOpen:TextField;
      
      private var mTxtFunction:TextField;
      
      private var mTxtCheck:TextField;
      
      private var mTxt:TextField;
      
      private var _lvOld:int = 0;

      private var mLimitBreakPanel:Sprite;
      private var mLimitBreakEncounter:Object;
      private var mLimitBreakBusy:Boolean = false;
      
      public function PanelGameEndAward()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         GlobalData.$mEventDispatcher.addEventListener("autoOff",autoOff);
         this.mBg_touch = GlobalFunction.createButtonStarling("UI_color_0x00000000");
         this.mBg_touch.width = GlobalData.$mStageWidth;
         this.mBg_touch.height = GlobalData.$mStageHeight;
         this.mBg_touch.alpha = 0;
         this.addChild(this.mBg_touch);
         this.mBox = new Sprite();
         this.addChild(this.mBox);
         this.mBox_avatar = new Sprite();
         this.addChild(this.mBox_avatar);
         this.mBox_btn = new Sprite();
         this.addChild(this.mBox_btn);
         _isFightAward = false;
         GlobalData.$mEventDispatcher.addEventListener("update_fightaward",UPDATE_FIGHTAWARD);
      }
      
      private var _legacyAwardWriteReported:Boolean = false;

      private function canWriteLegacyAwardProfile() : Boolean
      {
         var _kind:int = GlobalFunction.profileReceiptKind(GlobalData.$gameEndAwardObj);
         if(_kind <= 0 && !_legacyAwardWriteReported)
         {
            _legacyAwardWriteReported = true;
            RpcStaticCall.$remoting.reportDiagnostic(_kind == 0 ? "PROFILE_SYNC_ORPHAN_GAME_END_AWARD_READ_ONLY" : "PROFILE_SYNC_MALFORMED_GAME_END_AWARD");
         }
         // No evidenced producer or authenticated receipt exists for this
         // panel. It is display-only and never owns profile persistence.
         return false;
      }

      private function UPDATE_FIGHTAWARD(param1:Event) : void
      {
         _isFightAward = true;
         this.touchable = true;
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         closeLimitBreakPanel(null);
         GlobalData.$mEventDispatcher.removeEventListener("update_fightaward",UPDATE_FIGHTAWARD);
         GlobalData.$mEventDispatcher.removeEventListener("autoOff",autoOff);
         GlobalData.$mGameClassObject.mLayoutUIBottom.visible = true;
         GlobalData.$isGameEndAward = false;
         StarlingTools.removeChildrenClear(this.mBox);
         StarlingTools.removeChildrenClear(this.mBox_btn);
         StarlingTools.removeChildrenClear(this.mBox_avatar);
         if(isRandom_avatars)
         {
            GlobalData.$tempPVE_combatID = "";
         }
         if(mAutoTF)
         {
            mAutoTF.removeFromParent();
         }
         mFragment_ok = false;
         isRandom_avatars = false;
         if(mBg_touch)
         {
            mBg_touch.removeFromParent(true);
         }
         if(mBtn_pvp)
         {
            mBtn_pvp.removeFromParent(true);
         }
         if(mPanelLogin)
         {
            mPanelLogin.removeFromParent(true);
         }
         if(_txt)
         {
            _txt.removeFromParent(true);
         }
         super.onREMOVED_FROM_STAGE(param1);
         mBox = null;
         mBox_avatar = null;
         mBox_btn = null;
         mAutoTF = null;
         mBg_touch = null;
         mBtn_pvp = null;
         mPanelLogin = null;
         _txt = null;
      }
      
      private function outAndChangePanel() : void
      {
         var cfg:Object;
         var daySecond:Number;
         var startTime:Date;
         var _cfg:Array;
         var _obj:Object;
         var _awardData:Object;
         var _isWinner:Boolean;
         var _fun:Object;
         var fragment_ok:*;
         var fragment_no:*;
         if(GlobalData.$isPVP)
         {
            if(_isFightAward)
            {
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp");
               GlobalData.$setPVE();
            }
            return;
         }
         if(GlobalData.$isBattleOfThePeak)
         {
            cfg = GlobalData.$mConfig_simple.cross_pvp;
            daySecond = 86400 * cfg.cross_server_pvp[3];
            startTime = cfg.cross_server_pvp[2];
            if(daySecond - (SendAndSelect.$systemTimer_nowSecond - startTime.time / 1000) % daySecond < cfg.cross_server_pvp[4] * 60 * 60)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(98053),false);
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_main");
               return;
            }
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp");
            return;
         }
         if(GlobalData.$isFragment)
         {
            if(_isFightAward)
            {
               fragment_ok = function():void
               {
                  GlobalData.$setFragment();
                  GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_fragment_embattle",false,true);
               };
               fragment_no = function():void
               {
                  GlobalData.$setFragment();
                  GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp");
               };
               if(mFragment_ok)
               {
                  fragment_no();
               }
               else
               {
                  _cfg = GlobalData.$mConfig_simple.capacity_config as Array;
                  _obj = GlobalFunction.getFragmentPower();
                  _awardData = GlobalData.$gameEndAwardObj.data;
                  _isWinner = _awardData["sign"] == 1;
                  if(_isWinner && _obj.energy >= _cfg[3])
                  {
                     _fun = {
                        "ok":fragment_ok,
                        "no":fragment_no
                     };
                     GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90165,_obj.energy),GlobalTextStyle.COLOR_W_Y_Y_G),_fun);
                  }
                  else
                  {
                     fragment_no();
                  }
               }
            }
            return;
         }
         if(this.isPassBattle)
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pve");
         }
         else if(isRandom_avatars)
         {
            isRandom_avatars = false;
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pve");
         }
         else
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pve");
         }
      }
      
      private function onTRIGGERED_btns(param1:Event) : void
      {
         var _loc2_:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         if(_loc2_.name == "OK")
         {
            SendServiceAMFFun.send_user_apply_friend(null,{"fid":GlobalData.$tempHelpAvatar.uid});
         }
         this.outAndChangePanel();
      }
      
      override public function update() : void
      {
         if(this.mBg_touch)
         {
            if(this.mBg_touch.hasEventListener("triggered"))
            {
               this.mBg_touch.removeEventListener("triggered",onTRIGGERED_self);
            }
            this.mBg_touch.addEventListener("triggered",onTRIGGERED_self);
            this.mBg_touch.visible = true;
         }
         setUIInfo();
         checkReplayAndNext();
      }
      
      private function onTRIGGERED_self(param1:Event) : void
      {
         if(_txt)
         {
            _txt.removeFromParent(true);
            _txt = null;
         }
         if(GameMapLayer.isAuto)
         {
            GameMapLayer.setAuto(false);
            return;
         }
         var _loc2_:* = GlobalData.$gameEndAwardObj.data;
         if(GlobalData.$isPVP)
         {
            if(mStatus_up)
            {
               this.mStatus_up = false;
               delJuggler();
               this.outAndChangePanel();
            }
            else
            {
               if(checkSpeak())
               {
                  return;
               }
               this.outAndChangePanel();
            }
            return;
         }
         if(GlobalData.$isFragment)
         {
            if(mStatus_up)
            {
               this.mStatus_up = false;
               delJuggler();
               if(_loc2_.sign == 2 && _isFightAward)
               {
                  GlobalFunction.popLoseGuide(GlobalData.$isFragment);
               }
               else
               {
                  this.outAndChangePanel();
               }
            }
            else
            {
               if(checkSpeak())
               {
                  return;
               }
               if(!hasGuide && _loc2_.sign == 2 && _isFightAward)
               {
                  GlobalFunction.popLoseGuide(GlobalData.$isFragment);
                  hasGuide = true;
               }
               else
               {
                  this.outAndChangePanel();
               }
            }
            return;
         }
         if(GlobalData.$isBattleOfThePeak)
         {
            mStatus_award = false;
         }
         if(mStatus_up)
         {
            this.mStatus_up = false;
            if(!checkAwardAvatar())
            {
               if(this.mStatus_award)
               {
                  if(checkSpeak())
                  {
                     return;
                  }
                  this.mStatus_award = false;
                  if(GlobalData.$isBattleOfThePeak)
                  {
                     this.outAndChangePanel();
                  }
                  else
                  {
                     this.setUIFriend();
                  }
               }
               else
               {
                  this.outAndChangePanel();
               }
            }
         }
         else if(!hasGuide && _loc2_.sign == 2 && !isRandom_avatars)
         {
            GlobalFunction.popLoseGuide();
            hasGuide = true;
         }
         else if(this.mStatus_award)
         {
            if(checkSpeak())
            {
               return;
            }
            this.mStatus_award = false;
            if(!GlobalData.$isBattleOfThePeak)
            {
               this.setUIFriend();
            }
         }
         else
         {
            this.outAndChangePanel();
         }
      }
      
      public function checkSpeak() : Boolean
      {
         var _loc1_:Object = GlobalData.$gameEndAwardObj.data;
         var _loc3_:Boolean = _loc1_["sign"] == 1;
         var _loc2_:int = -1;
         if(GlobalData.$isPVP)
         {
            if(_loc3_)
            {
               _loc2_ = GuideMaster.getOnlyExample().checkGuide("M5_2");
            }
         }
         else if(!GlobalData.$isFragment)
         {
            if(GlobalData.$tempPVE_type == "status_pve_hard")
            {
               _loc2_ = GuideMaster.getOnlyExample().checkGuide("M2_2");
            }
         }
         return _loc2_ != -1;
      }
      
      public function setUIFriend() : void
      {
         var _awardData:Object;
         var _isWinner:Boolean;
         var _sCfg:Array;
         var _isBot:Boolean;
         var _data:Object;
         var _arr:Array;
         var _rec:Rectangle;
         var _rec2:Rectangle;
         var _0xFFCC00Arr:Array;
         var _a:TextFieldHtmlRenderer;
         var _tw:Number;
         var _nameT:TextField;
         var _x0:Number;
         var _item:ItemAvatarAward;
         var _ok:LOL_Scale9Button;
         var _no:LOL_Scale9Button;
         var _fun:Object;
         var _cid:String;
         var _gameMapData:GameMapData;
         var _name:String;
         if(!GlobalData.$gameEndAwardObj)
         {
            return;
         }
         this.delJuggler();
         _awardData = GlobalData.$gameEndAwardObj.data;
         _isWinner = _awardData["sign"] == 1;
         _sCfg = GlobalData.$mConfig_simple.score_config as Array;
         _isBot = GlobalFunction.check_bot_user(GlobalData.$tempHelpAvatar.uid);
         this.changeStr_header(GlobalLanguageStr.getLanguageStr(20114));
         StarlingTools.removeChildrenClear(this.mBox);
         StarlingTools.removeChildrenClear(this.mBox_avatar);
         StarlingTools.removeChildrenClear(this.mBox_btn);
         LayoutUIAnimation.getOnlyExample().clearAnimationLayer();
         _data = GlobalData.$tempHelpAvatar.avatar;
         if(_data)
         {
            _arr = [];
            _0xFFCC00Arr = [16763904,16763904,16763904,16763904];
            _arr = [GlobalData.$tempHelpAvatar.isF || _isBot ? "" : Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20115),_0xFFCC00Arr,1000,40,false,"center"),"","","","",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20116,_isWinner ? (GlobalData.$tempHelpAvatar.isF ? _sCfg[0] : _sCfg[1]) : "0"),GlobalTextStyle.COLOR_W_Y_Y_Y,1000,25),"",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20117,GlobalData.$userData.score),GlobalTextStyle.COLOR_W_Y_Y_Y,1000,25),"",GlobalData.$tempHelpAvatar.isF || _isBot ? "" : Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20118),GlobalTextStyle.COLOR_W_Y_Y_Y,1000,25)];
            _a = GlobalTextStyle.getHtmlTextRenderer();
            _a.text = Tools.formatHtmlTextBr(_arr,"center");
            _a.alpha = 0;
            _a.mLayoutFun = function():void
            {
               _rec = _a.getTextSnapshotFrame();
               var _loc1_:Number = int((GlobalData.$mStageWidth - _rec.width) * 0.5);
               _a.x = _loc1_ - 50;
               GlobalData.$mStarling.juggler.tween(_a,0.5,{
                  "transition":"easeOut",
                  "alpha":1,
                  "x":_loc1_
               });
            };
            _a.y = GlobalData.formatVScaleY_center(850 * 0.1) + 10;
            this.mBox.addChild(_a);
            if(GlobalData.$tempHelpAvatar.isF)
            {
               _a.y += 100;
            }
            if(GlobalData.$tempHelpAvatar.isF || _isBot)
            {
               _a.y += 80;
            }
            if(!_isBot)
            {
               _tw = int(GlobalData.$mStageWidth * 0.3);
               _nameT = GlobalTextStyle.getTextField(GlobalData.$tempHelpAvatar.name,30,16763904,"center",_tw,46,GlobalConfig.FONT_1);
               _nameT.touchable = false;
               _nameT.alpha = 0;
               _nameT.y = _a.y + 35 * 2;
               _x0 = int((GlobalData.$mStageWidth - _tw) * 0.5);
               _nameT.x = _x0 + 50;
               GlobalData.$mStarling.juggler.tween(_nameT,0.5,{
                  "transition":"easeOut",
                  "alpha":1,
                  "x":_x0
               });
               this.mBox.addChild(_nameT);
            }
            _item = new ItemAvatarAward();
            _data["id"] = _data["aid"];
            _item.data = _data;
            _item.alpha = 0;
            this.mBox_avatar.addChild(_item);
            GlobalData.$mStarling.juggler.tween(_item,1,{"alpha":1});
            this.mBox_avatar.x = int((GlobalData.$mStageWidth - 100) * 0.5);
            this.mBox_avatar.y = _isBot || GlobalData.$tempHelpAvatar.isF ? GlobalData.formatVScaleY_center(850 * 0.2) : int(_a.y + 29 * 5 - 10);
            if(!GlobalData.$tempHelpAvatar.isF && !_isBot)
            {
               _ok = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20021),140,70,"UI_btn_normalFun_0000");
               _ok.name = "OK";
               _no = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20104),140,70,"UI_btn_normalFun_0000");
               _no.name = "NO";
               _no.x = int(GlobalData.$mStageWidth * 0.5 - _ok.width - 30);
               _ok.x = int(GlobalData.$mStageWidth * 0.5 + 30);
               _ok.y = int(GlobalData.$center_height_curr * 0.7);
               _no.y = _ok.y;
               _ok.addEventListener("triggered",onTRIGGERED_btns);
               _no.addEventListener("triggered",onTRIGGERED_btns);
               this.mBox.addChild(_ok);
               this.mBox.addChild(_no);
               this.mBox.touchable = true;
               if(this.mBg_touch)
               {
                  this.mBg_touch.visible = false;
               }
            }
            GlobalData.$tempHelpAvatar.avatar = _awardData.friend_avatar;
            GlobalFunction.changePVEHelpAvatar(GlobalData.$tempHelpAvatar.uid,_awardData.friend_avatar);
         }
         if(this.isPassBattle)
         {
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.coin = _awardData.coin;
            }
            _fun = {"ok":GlobalFunction.functionNull};
            _cid = GlobalData.$tempPVE_combatID;
            _gameMapData = GameMapManager.getOnlyExample().getData(_cid);
            _name = _gameMapData.battleName;
            if(GlobalData.$tempPVE_type == "status_pve_hard")
            {
               _name += GlobalLanguageStr.getLanguageStr(20281);
            }
            GameMapManager.getOnlyExample();
            if(_isFirstWin)
            {
            }
            if(_gameMapData.isMain)
            {
               SoundManager.getOnlyExample().playSound("mainClear");
            }
            else
            {
               SoundManager.getOnlyExample().playSound("ployClear");
            }
         }
      }
      
      private function setUIInfo_fragment() : void
      {
         var _awardData:Object;
         var _params:Object;
         var _isWinner:Boolean;
         var _isOK:Boolean;
         var _fragment:Array;
         var _expCfg:Array;
         var _fraCfg:Array;
         var _expNum:Number;
         var setClip:*;
         var _0xFFCC00Arr:Array;
         var _str1:String;
         var _equip:Equip;
         var _str2:String;
         var _arr:Array;
         var _tA:TextFieldHtmlRenderer;
         var _b:LOL_HtmlText;
         var _equipUI:ItemEquipAward;
         var _data:*;
         this.touchable = false;
         this.changeStr_header(GlobalLanguageStr.getLanguageStr(20108));
         if(!GlobalData.$gameEndAwardObj)
         {
            return;
         }
         GlobalData.$isGameEndAward = true;
         this.mIsBinding = false;
         this.mBox.touchable = false;
         this.mStatus_award = true;
         _awardData = GlobalData.$gameEndAwardObj.data;
         if(!_awardData)
         {
            return;
         }
         give_avatar_equip_fragment(_awardData);
         _params = GlobalData.$gameEndAwardObj.params;
         _isWinner = _awardData["sign"] == 1;
         _isOK = mFragment_ok = _awardData.get_fragment;
         _fragment = _awardData.the_fragment;
         _expCfg = GlobalData.$mConfig_simple.exp_config as Array;
         _fraCfg = GlobalData.$mConfig_simple.fragment_pk as Array;
         _expNum = _fraCfg[0] * GlobalData.$userData.lv + _fraCfg[1];
         if(!_isWinner)
         {
            _expNum = int(_expNum * _fraCfg[2]);
         }
         _expNum = GlobalData.$userData.lv >= _expCfg[3] ? 0 : _expNum;
         this.mPower_old = GlobalFunction.getEnergy();
         if(!GameMap.isLoad)
         {
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.attrs.energy_extra = _awardData.attr_energy_extra;
            }
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateEn(_awardData.energy as Date);
         }
         this.mPower_new = GlobalFunction.getEnergy();
         mStatus_up = GlobalData.$userData.lv != _awardData.lv;
         if(mStatus_up)
         {
            setClip = function():void
            {
               setClip_lv(GlobalData.$userData.lv,_awardData.lv,popFightaward);
            };
            setTimeout(setClip,20);
         }
         if(_isOK)
         {
            GlobalData.$userData.fragment["equips"][GlobalData.$fragment_data["eid"]] = _fragment;
         }
         if(canWriteLegacyAwardProfile())
         {
         GlobalData.$userData.attrs.fragment_energy = _awardData.attr_fragment_energy;
         }
         if(canWriteLegacyAwardProfile())
         {
         GlobalData.$userData.attrs.fragment_energy_extra = _awardData.attr_fragment_energy_extra;
         }
         if(canWriteLegacyAwardProfile())
         {
         GlobalData.$userData.attrs.culture_book = _awardData.culture_book;
         }
         if(_awardData["dust"])
         {
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.attrs.dust = _awardData.dust;
            }
         }
         if(_awardData["dn_stone"])
         {
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.attrs.dn_stone = _awardData.dn_stone;
            }
         }
         if(canWriteLegacyAwardProfile())
         {
         GlobalData.$userData.coin = _awardData.coin;
         }
         if(canWriteLegacyAwardProfile())
         {
         GlobalData.$userData.exp = _awardData.exp;
         }
         if(canWriteLegacyAwardProfile())
         {
         GlobalData.$userData.lv = _awardData.lv;
         }
         if(_awardData["box_key"])
         {
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.attrs.box_key = _awardData.box_key;
            }
         }
         if(_awardData["medal"])
         {
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.medal = _awardData.medal;
            }
         }
         if(_awardData["mark"])
         {
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.mark = _awardData.mark;
            }
         }
         if(_awardData["score"])
         {
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.score = _awardData.score;
            }
         }
         if(_awardData["gold"])
         {
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.gold = _awardData.gold;
            }
         }
         _0xFFCC00Arr = [16763904,16768384,65280,16724736];
         _str1 = _isWinner ? GlobalLanguageStr.getLanguageStr(90097) : GlobalLanguageStr.getLanguageStr(90098);
         _equip = new Equip(GlobalData.$fragment_data["eid"]);
         _str2 = _isWinner ? (_isOK ? GlobalLanguageStr.getLanguageStr(90164,_equip.equipData.name) : GlobalLanguageStr.getLanguageStr(90163)) : "";
         _arr = null;
         _arr = [Tools.formatLineX(_str1,_0xFFCC00Arr,30,40,false,"center"),"",Tools.formatLineX(GlobalData.$fragment_data["name"],GlobalTextStyle.COLOR_W_Y_Y_Y,20,30,false,"center"),"",Tools.formatLineX(_str2,_0xFFCC00Arr,20,30,false,"center"),""];
         _tA = GlobalTextStyle.getHtmlTextRenderer();
         _tA.alpha = 0;
         _tA.text = Tools.formatHtmlTextBr(_arr,"center");
         _tA.mLayoutFun = function():void
         {
            var _loc1_:Rectangle = _tA.getTextSnapshotFrame();
            var _loc2_:Number = int((GlobalData.$mStageWidth - _loc1_.width) * 0.5);
            _tA.x = _loc2_ - 50;
            GlobalData.$mStarling.juggler.tween(_tA,0.7,{
               "delay":0.2,
               "transition":"easeOut",
               "alpha":1,
               "x":_loc2_
            });
         };
         _tA.y = 120;
         this.mBox.addChild(_tA);
         _arr = [Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20112) + _expNum,GlobalTextStyle.COLOR_W_Y_Y_Y,100,25,false,"center")];
         _b = new LOL_HtmlText(GlobalData.$mStageWidth,35,25,16777215,false,"center");
         _b.alpha = 0;
         _b.text = Tools.formatHtmlTextBr(_arr,"center");
         _b.x = 50;
         _b.y = int(_tA.y + _b.height + _tA.getTextSnapshotFrame().height + 140);
         this.mBox.addChild(_b);
         GlobalData.$mStarling.juggler.tween(_b,0.7,{
            "transition":"easeOut",
            "delay":0.5,
            "alpha":1,
            "x":0,
            "onComplete":function():void
            {
               if(!mStatus_up)
               {
                  GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_fightaward",false,true);
               }
            }
         });
         if(_isOK)
         {
            if(GlobalData.$isFragment)
            {
               SoundManager.getOnlyExample().playSound("sound04");
            }
            _data = {};
            _data["id"] = _equip.equipData.id;
            _data["fragmentType"] = "fragment";
            _data["indexID_s"] = GlobalData.$fragment_data["indexID_s"];
            _equipUI = new ItemEquipAward();
            _equipUI.data = _data;
            _equipUI.alpha = 0;
            this.mBox_avatar.addChild(_equipUI);
            GlobalData.$mStarling.juggler.tween(_equipUI,1,{
               "delay":0.2,
               "alpha":1
            });
            this.mBox_avatar.addChild(_equipUI);
            this.mBox_avatar.x = int((GlobalData.$mStageWidth - 100) * 0.5);
            this.mBox_avatar.y = int(GlobalData.$center_height_curr * 0.6);
         }
      }
      
      private function popFightaward() : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_fightaward",false,true);
      }
      
      private function setUIInfo_pvp() : void
      {
         var _awardData:Object;
         var _lvNew:int;
         var _params:Object;
         var _isWinner:Boolean;
         var _expCfg:Array;
         var _0xFFCC00Arr:Array;
         var _numberX:Number;
         var _pvpArr:Array;
         var _pvpRec:Rectangle;
         var _pvpRec2:Rectangle;
         var _pvpRec3:Rectangle;
         var _pvpStr1:String;
         var _pvpMyTitle_old:int;
         var _txt:TextField;
         var _rec:Rectangle;
         var _pvpStr2:String;
         var obj:Object;
         var _pvpA:TextFieldHtmlRenderer;
         var _pvpB:TextFieldHtmlRenderer;
         var _pvpCfg:Array;
         var i:String;
         var _pvpMarkStr:String;
         var _pvpExp:String;
         var _pvpC:TextFieldHtmlRenderer;
         var _pvpOtherAward:Boolean;
         var _typeOther:String;
         var _numOther:*;
         var _numB:Boolean;
         var _num2B:Boolean;
         var _pvpAtt:Object;
         var _pvpMyTitle_new:int;
         var o:Object;
         var type:String;
         var n:String;
         var _awardUI:Object;
         var _robot:*;
         var _name:String;
         var onTRIGGERED_pvp:*;
         var _pvpD:TextFieldHtmlRenderer;
         this.touchable = false;
         GlobalData.$mEventDispatcher.addEventListener("check_is_lv",checkIsLv);
         this.changeStr_header(GlobalLanguageStr.getLanguageStr(20108));
         if(!GlobalData.$gameEndAwardObj)
         {
            return;
         }
         GlobalData.$isGameEndAward = true;
         this.mIsBinding = false;
         this.mBox.touchable = false;
         this.mStatus_award = true;
         _awardData = GlobalData.$gameEndAwardObj.data;
         if(!_awardData)
         {
            return;
         }
         give_avatar_equip_fragment(_awardData);
         _lvNew = 0;
         _params = GlobalData.$gameEndAwardObj.params;
         _isWinner = _awardData["sign"] == 1;
         _expCfg = GlobalData.$mConfig_simple.exp_config as Array;
         _0xFFCC00Arr = [16764006,16764006,16764006,13777209];
         if(GlobalData.$isPVP)
         {
            _lvOld = GlobalData.$userData.lv;
            _pvpArr = null;
            _pvpStr1 = _isWinner ? GlobalLanguageStr.getLanguageStr(90097) : GlobalLanguageStr.getLanguageStr(90098);
            _pvpMyTitle_old = GlobalFunction.check_pvp_list_title(GlobalData.$userData.records.current_rank);
            if(_awardData.records)
            {
               if(canWriteLegacyAwardProfile())
               {
               GlobalData.$userData.records.current_rank = _awardData.records.current_rank;
               }
            }
            _txt = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20108),30,16777215,"center",125,46);
            _rec = _txt.bounds;
            _txt.x = (GlobalData.$mStageWidth - _rec.width) * 0.5;
            _txt.y = 60;
            this.mBox.addChild(_txt);
            _pvpStr2 = _isWinner ? GlobalLanguageStr.getLanguageStr(90100,GlobalData.$userData.records.current_rank) : GlobalLanguageStr.getLanguageStr(90099);
            obj = GlobalData.$pvp_rival;
            _pvpArr = [Tools.formatLineX(_pvpStr1,_0xFFCC00Arr,30,20) + Tools.formatLineX(GlobalData.$pvp_rival["name"],[13777209,13777209,13777209,13777209],20,20),Tools.formatLineX(_pvpStr2,_0xFFCC00Arr,50,20),""];
            _pvpA = GlobalTextStyle.getHtmlTextRenderer();
            _pvpA.alpha = 0;
            _pvpA.text = Tools.formatHtmlTextBr(_pvpArr,"center");
            _pvpA.mLayoutFun = function():void
            {
               var _loc2_:Rectangle = _pvpA.getTextSnapshotFrame();
               var _loc1_:Number = int((GlobalData.$mStageWidth - _loc2_.width) * 0.5);
               _pvpA.x = 190;
               GlobalData.$mStarling.juggler.tween(_pvpA,0.7,{
                  "delay":0.2,
                  "transition":"easeOut",
                  "alpha":1,
                  "x":_loc1_
               });
            };
            _pvpA.y = _txt.y + 60;
            this.mBox.addChild(_pvpA);
            _pvpArr = [Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20111),GlobalTextStyle.COLOR_W_Y_Y_Y,1000,20),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20297),GlobalTextStyle.COLOR_W_Y_Y_Y,1000,20)];
            if(_isWinner)
            {
               SoundManager.getOnlyExample().playSound("sound02");
               _pvpArr.push(Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20112),GlobalTextStyle.COLOR_W_Y_Y_Y,1000,20));
            }
            _pvpB = GlobalTextStyle.getHtmlTextRenderer();
            _pvpB.alpha = 0;
            _pvpB.text = Tools.formatHtmlTextBr(_pvpArr,"center");
            _pvpB.mLayoutFun = function():void
            {
               _pvpRec = _pvpB.getTextSnapshotFrame();
               var _loc1_:Number = int(GlobalData.$mStageWidth * 0.5 - _pvpRec.width);
               _pvpB.x = 190;
               _pvpRec2 = _pvpA.getTextSnapshotFrame();
               _pvpB.y = int(_pvpA.y + _pvpRec2.height);
               GlobalData.$mStarling.juggler.tween(_pvpB,0.7,{
                  "transition":"easeOut",
                  "delay":0.5,
                  "alpha":1,
                  "x":190 + 45
               });
            };
            this.mBox.addChild(_pvpB);
            _pvpCfg = GlobalData.$mConfig_simple.pvp_config as Array;
            if(_awardData.gold - GlobalData.$userData.gold > 0)
            {
               for(i in _awardData.poke_data.user_gift)
               {
                  if(i == "gold")
                  {
                     getL = _awardData.gold - GlobalData.$userData.gold - _awardData.poke_data.user_gift[i];
                  }
                  else
                  {
                     getL = _awardData.gold - GlobalData.$userData.gold;
                  }
               }
            }
            _pvpMarkStr = String(_isWinner ? _pvpCfg[11] : _pvpCfg[11] * _pvpCfg[12]);
            _pvpArr = [Tools.formatLineX(String(getL),GlobalTextStyle.COLOR_W_Y_Y_Y,1000,20),Tools.formatLineX(_pvpMarkStr,GlobalTextStyle.COLOR_W_Y_Y_Y,1000,20)];
            _pvpExp = _awardData.lv >= _expCfg[3] ? "0" : String(int(1 / (GlobalData.$pvp_rival["indexID_s"] * _pvpCfg[14] + _pvpCfg[15])));
            if(_isWinner)
            {
               _pvpArr.push(Tools.formatLineX(_pvpExp,GlobalTextStyle.COLOR_W_Y_Y_Y,1000,20));
            }
            _pvpC = GlobalTextStyle.getHtmlTextRenderer();
            _pvpC.text = Tools.formatHtmlTextBr(_pvpArr,"center");
            _pvpC.alpha = 0;
            _pvpC.mLayoutFun = function():void
            {
               var _x3:Number = int(GlobalData.$mStageWidth * 0.5 + 5 - 30);
               _pvpC.x = _x3;
               _pvpRec2 = _pvpA.getTextSnapshotFrame();
               _pvpC.y = int(_pvpA.y + _pvpRec2.height);
               GlobalData.$mStarling.juggler.tween(_pvpC,0.7,{
                  "transition":"easeOut",
                  "delay":0.6,
                  "alpha":1,
                  "x":_x3 + 40,
                  "onComplete":function():void
                  {
                     var setClip:*;
                     mStatus_up = GlobalData.$userData.lv != _awardData.lv;
                     if(canWriteLegacyAwardProfile())
                     {
                     GlobalData.$userData.exp = _awardData.exp;
                     }
                     if(mStatus_up)
                     {
                        setClip = function():void
                        {
                           setClip_lv(GlobalData.$userData.lv,_awardData.lv,popFightaward);
                        };
                        setClip();
                     }
                     else
                     {
                        popFightaward();
                     }
                  }
               });
            };
            this.mBox.addChild(_pvpC);
            _pvpOtherAward = false;
            _typeOther = "";
            _numB = Tools.isNoChildrenInObj(_awardData.get_avatars);
            _num2B = Tools.isNoChildrenInObj(_awardData.get_equips);
            if(_awardData.medal > GlobalData.$userData.medal)
            {
               _pvpOtherAward = true;
               _typeOther = "medal";
               _numOther = _awardData.medal - GlobalData.$userData.medal;
            }
            else if(!_numB)
            {
               _pvpOtherAward = true;
               _typeOther = "avatar";
               for(_pvpAtt in _awardData.get_avatars)
               {
                  _numOther = _pvpAtt.toString();
                  if(canWriteLegacyAwardProfile())
                  {
                  GlobalFunction.changeUserDataAvatars(_pvpAtt.toString(),_awardData.get_avatars[_pvpAtt],true);
                  }
               }
            }
            else if(!_num2B)
            {
               _pvpOtherAward = true;
               _typeOther = "equip";
               for(_pvpAtt in _awardData.get_equips)
               {
                  _numOther = _pvpAtt.toString();
                  if(canWriteLegacyAwardProfile())
                  {
                  GlobalData.$userData.my_equips[_pvpAtt.toString()] = _awardData.get_equips[_numOther];
                  }
               }
            }
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.gold = _awardData.gold;
            }
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.coin = _awardData.coin;
            }
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.mark = _awardData.mark;
            }
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.score = _awardData.score;
            }
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.medal = _awardData.medal;
            }
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.attrs.culture_book = _awardData.culture_book;
            }
            if(_awardData["box_key"])
            {
               if(canWriteLegacyAwardProfile())
               {
               GlobalData.$userData.attrs.box_key = _awardData.box_key;
               }
            }
            if(_awardData["dust"])
            {
               if(canWriteLegacyAwardProfile())
               {
               GlobalData.$userData.attrs.dust = _awardData.dust;
               }
            }
            if(_awardData["dn_stone"])
            {
               if(canWriteLegacyAwardProfile())
               {
               GlobalData.$userData.attrs.dn_stone = _awardData.dn_stone;
               }
            }
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.attrs.fragment_energy = _awardData.attr_fragment_energy;
            }
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.attrs.fragment_energy_extra = _awardData.attr_fragment_energy_extra;
            }
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.attrs = _awardData.attrs ? _awardData.attrs : GlobalData.$userData.attrs;
            }
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.records = _awardData.records ? _awardData.records : GlobalData.$userData.records;
            }
            _pvpMyTitle_new = GlobalFunction.check_pvp_list_title(GlobalData.$userData.records.current_rank);
            if(_pvpMyTitle_new < 6)
            {
               if(_pvpMyTitle_new < _pvpMyTitle_old)
               {
                  GlobalData.$PVPupClip = true;
               }
            }
            if(GlobalData.$PVPupClip)
            {
               o = _awardData.win_gift;
               type = "";
               for(n in o)
               {
                  type = n;
               }
               if(type == "")
               {
                  return;
               }
               _awardUI = GlobalFunction.getAwardByType(type,o[type]);
               _robot = GlobalData.$mConfig_pvp_robot;
               _name = GlobalLanguageStr.getLanguageStr(_robot[_pvpMyTitle_new.toString()].name);
               GlobalFunction.popAward(type,GlobalLanguageStr.getLanguageStr(90102,_awardUI.msg,_name),o[type],false);
               checkSharePVP_DNY();
            }
            if(!_isWinner)
            {
               onTRIGGERED_pvp = function(param1:Event):void
               {
                  if(_isFightAward)
                  {
                     GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_change_pvp",false,true);
                  }
               };
               GuideMaster.getOnlyExample().checkGuide("M10_2");
               mBtn_pvp = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20312),150,70,"UI_btn_normalFun_0000");
               mBtn_pvp.x = int((GlobalData.$mStageWidth - mBtn_pvp.width) * 0.5);
               mBtn_pvp.y = 600;
               if(MainConfig.$isEA)
               {
                  mBtn_pvp.fontSize = 20;
               }
               mBtn_pvp.addEventListener("triggered",onTRIGGERED_pvp);
               this.mBox.addChild(mBtn_pvp);
               _pvpArr = [Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90101),[13777209,13777209,13777209,13777209],1000,20)];
               _pvpD = GlobalTextStyle.getHtmlTextRenderer();
               _pvpD.text = Tools.formatHtmlTextBr(_pvpArr,"center");
               _pvpD.alpha = 0;
               _pvpD.mLayoutFun = function():void
               {
                  _pvpRec = _pvpD.getTextSnapshotFrame();
                  _pvpRec3 = _pvpB.getTextSnapshotFrame();
                  _pvpRec2 = _pvpA.getTextSnapshotFrame();
                  var _loc1_:Number = int((GlobalData.$mStageWidth - _pvpRec.width) * 0.5);
                  _pvpD.x = MainConfig.$isEA ? 190 - 160 : 190;
                  _pvpD.y = _pvpA.y + _pvpRec2.height + _pvpRec3.height + _pvpRec.height;
                  GlobalData.$mStarling.juggler.tween(_pvpD,0.7,{
                     "delay":0.6,
                     "alpha":1
                  });
               };
               this.mBox.addChild(_pvpD);
               this.mBox.touchable = true;
            }
            else
            {
               mStatus_up = GlobalData.$userData.lv != _awardData.lv;
               this.mPower_old = GlobalFunction.getEnergy();
               if(!GameMap.isLoad)
               {
                  if(canWriteLegacyAwardProfile())
                  {
                  GlobalData.$userData.attrs.energy_extra = _awardData.attr_energy_extra;
                  }
                  GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateEn(_awardData.energy as Date);
               }
               this.mPower_new = GlobalFunction.getEnergy();
            }
            _lvNew = int(GlobalData.$userData.lv);
            return;
         }
      }
      
      private function checkIsLv() : void
      {
         GlobalData.$mEventDispatcher.removeEventListener("check_is_lv",checkIsLv);
         var _loc1_:Object = GlobalData.$gameEndAwardObj.data;
         mStatus_up = _lvOld != _loc1_.lv;
         if(mStatus_up)
         {
            setClip_lv(_lvOld,_loc1_.lv);
         }
      }
      
      public function setUIInfo() : void
      {
         var reFun:*;
         var _awardData:Object;
         var _oldPassData:Object;
         var _lvOld:int;
         var _lvNew:int;
         var _params:Object;
         var _isWinner:Boolean;
         var _expCfg:Array;
         var _isBot:Boolean;
         var _helpUids:Object;
         var _time:*;
         var _0xFFCC00Arr:Array;
         var _cfgA:Object;
         var _cfgB:Object;
         var _diff:int;
         var _newPassData:Object;
         var _starNum:int;
         var _limit:int;
         var _recoder:Array;
         var _tw:Number;
         var _txt:TextField;
         var _x0:Number;
         var _arr:Array;
         var _rec:Rectangle;
         var _nameAdd:String;
         var _a:TextFieldHtmlRenderer;
         var _isMAX_lv:Boolean;
         var _add_gold:int;
         var _add_exp:int;
         var _add_updateEXP:int;
         var _diffConfig:Array;
         var _firstRate:Number;
         var _goldStr:String;
         var _expStr:String;
         var _updateEXPStr:String;
         var _random_avatars:*;
         var _random_avatars_diff:*;
         var _rndTeam:Array;
         var addGold:String;
         var addExp:String;
         var hasLearnObj:Object;
         var b:Boolean;
         var a:Boolean;
         var j:String;
         var _b:TextFieldHtmlRenderer;
         var _rect:Rectangle;
         var _str:String;
         var _stone:LOL_MutilTextFieldIcon;
         var _x2:Number;
         var checkMorph:* = function():void
         {
            if(_awardData.attr_morph)
            {
               if(GlobalFunction.checkMorph() < 0)
               {
                  if(canWriteLegacyAwardProfile())
                  {
                  GlobalData.$userData.attrs.morph = _awardData.attr_morph;
                  }
                  if(GlobalFunction.checkMorph() >= 0)
                  {
                     GlobalFunction.popAskMorph(mStatus_up);
                  }
               }
               else
               {
                  if(canWriteLegacyAwardProfile())
                  {
                  GlobalData.$userData.attrs.morph = _awardData.attr_morph;
                  }
               }
            }
         };
         var delayFun:* = function():void
         {
            setClip_lv2(_lvOld,_awardData.lv,checkMorph);
         };
         mDn_stone = 0;
         if(GlobalData.$isFragment)
         {
            setUIInfo_fragment();
            return;
         }
         if(GlobalData.$isPVP)
         {
            setUIInfo_pvp();
            return;
         }
         if(GlobalData.$isBattleOfThePeak)
         {
            reFun = function(param1:Object):void
            {
               if(param1.data)
               {
                  if(canWriteLegacyAwardProfile())
                  {
                  GlobalData.$userData.attrs.server_pvp_cd = param1.data;
                  }
                  setUIInfo_pvp15();
               }
            };
            SendServiceAMFFun.send_user_set_server_pvp_cd(reFun);
            return;
         }
         this.changeStr_header(GlobalLanguageStr.getLanguageStr(20108));
         if(!GlobalData.$gameEndAwardObj)
         {
            return;
         }
         GlobalData.$isGameEndAward = true;
         this.mIsBinding = false;
         this.mBox.touchable = false;
         this.mStatus_award = true;
         _awardData = GlobalData.$gameEndAwardObj.data;
         if(!_awardData)
         {
            return;
         }
         give_avatar_equip_fragment(_awardData);
         if(_awardData.sign == 1 && _awardData.limit_break_encounter)
         {
            var breakOpportunity:Object = _awardData.limit_break_encounter;
            setTimeout(function():void { showLimitBreakPanel(breakOpportunity); },350);
         }
         _oldPassData = GlobalFunction.passBattleInfo(GlobalData.$tempPVE_battleID);
         _lvOld = 0;
         _lvNew = 0;
         _params = GlobalData.$gameEndAwardObj.params;
         _isWinner = _awardData["sign"] == 1;
         _expCfg = GlobalData.$mConfig_simple.exp_config as Array;
         mDn_stone = _awardData.dn_stone - GlobalData.$userData.attrs.dn_stone;
         mDn_stone = mDn_stone > 0 ? mDn_stone : 0;
         if(canWriteLegacyAwardProfile())
         {
         GlobalData.$userData.attrs.dn_stone = _awardData.dn_stone;
         }
         if(_awardData.attrs)
         {
            for(var attrKey:String in _awardData.attrs)
            {
               if(canWriteLegacyAwardProfile())
               {
               GlobalData.$userData.attrs[attrKey] = _awardData.attrs[attrKey];
               }
            }
         }
         if(GlobalData.$isNoFriendToPVE)
         {
            mStatus_award = false;
         }
         if(_awardData.score && (GlobalData.$isNoFriendToPVE || !GlobalData.$isNoFriendToPVE && GlobalData.$tempHelpAvatar) && !GlobalData.$isPVP && !GlobalData.$isFragment)
         {
            if(!GlobalData.$isNoFriendToPVE)
            {
               _isBot = GlobalFunction.check_bot_user(GlobalData.$tempHelpAvatar.uid);
               if(canWriteLegacyAwardProfile())
               {
               GlobalData.$userData.score = _awardData.score;
               }
               GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateScore(0);
               if(!_isBot)
               {
                  if(GlobalData.$tempHelpAvatar.isF)
                  {
                     _helpUids = GlobalData.$userData.records.help_fuids;
                  }
                  else
                  {
                     _helpUids = GlobalData.$userData.records.help_suids;
                  }
                  _time = _awardData.friend_avatar.cd_time;
                  _helpUids[GlobalData.$tempHelpAvatar.uid] = _awardData.friend_avatar.cd_time;
               }
            }
         }
         _0xFFCC00Arr = [16763904,16768384,65280,16724736];
         _lvOld = int(GlobalData.$userData.lv);
         GlobalData.$tempPVE_battleID_isFirstWin = false;
         mStatus_up = GlobalData.$userData.lv != _awardData.lv;
         _cfgA = null;
         _cfgB = null;
         _cfgA = GlobalFunction.getPveBattleCfg(GlobalData.$tempPVE_type)[GlobalData.$tempPVE_battleID];
         _cfgB = GlobalFunction.getPveCombatCfg(GlobalData.$tempPVE_type)[GlobalData.$tempPVE_combatID];
         _diff = 0;
         if(GlobalData.$tempPVE_type == "status_pve_hard")
         {
            _diff = 1;
         }
         if(_diff == 0)
         {
            if(_awardData.next_cid)
            {
               _isFirstWin = GlobalData.$userData.cid != _awardData.next_cid;
               if(canWriteLegacyAwardProfile())
               {
               GlobalData.$userData.cid = _awardData.next_cid;
               }
            }
         }
         else if(_diff == 1)
         {
            if(_awardData.next_cid)
            {
               _isFirstWin = GlobalData.$userData.hid != _awardData.next_cid;
               if(canWriteLegacyAwardProfile())
               {
               GlobalData.$userData.hid = _awardData.next_cid;
               }
            }
         }
         if(canWriteLegacyAwardProfile())
         {
         GlobalData.$userData.gold = _awardData.gold;
         }
         if(canWriteLegacyAwardProfile())
         {
         GlobalData.$userData.combat_score = _awardData.combat_score;
         }
         if(_awardData.coin != null)
         {
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.coin = _awardData.coin;
            }
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
         }
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateExp(_awardData.lv,_awardData.exp);
         this.mPower_old = GlobalFunction.getEnergy();
         if(!GameMap.isLoad)
         {
            mBeforeEn = GlobalFunction.getEnergy();
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.attrs.energy_extra = _awardData.attr_energy_extra;
            }
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateEn(_awardData.energy as Date);
         }
         this.mPower_new = GlobalFunction.getEnergy();
         _newPassData = GlobalFunction.passBattleInfo(GlobalData.$tempPVE_battleID);
         // A server settlement carries the authoritative first-clear decision.
         // The locally cached cid/hid can lag behind a completed request, so it
         // must not add a second multiplier to the amount actually granted.
         if(_awardData.first_clear != null)
         {
            _isFirstWin = Boolean(_awardData.first_clear);
         }
         if(_diff == 0 || _diff == 1)
         {
            GlobalData.$tempPVE_battleID_isFirstWin = _isFirstWin && _newPassData.isPass;
         }
         if(_isWinner)
         {
            _starNum = int(_awardData.combat_star);
            if(mStatus_up)
            {
               GuideMaster.getOnlyExample().checkGuide("M12_1");
            }
            else
            {
               checkAwardAvatar();
            }
            _limit = 0;
            if(GlobalData.$tempPVE_type == "status_pve_normal")
            {
               if(GlobalData.$userData.records.combat_main == null)
               {
                  if(canWriteLegacyAwardProfile())
                  {
                  GlobalData.$userData.records.combat_main = {};
                  }
               }
               _limit = int(GlobalData.$userData.records.combat_main[GlobalData.$tempPVE_combatID] ? GlobalData.$userData.records.combat_main[GlobalData.$tempPVE_combatID] : 0);
               if(!GameMap.isLoad)
               {
                  if(canWriteLegacyAwardProfile())
                  {
                  GlobalData.$userData.records.combat_main[GlobalData.$tempPVE_combatID] = _limit + 1;
                  }
               }
            }
            else if(GlobalData.$tempPVE_type == "status_pve_hard")
            {
               if(GlobalData.$userData.records.combat_main_hard == null)
               {
                  if(canWriteLegacyAwardProfile())
                  {
                  GlobalData.$userData.records.combat_main_hard = {};
                  }
               }
               _limit = int(GlobalData.$userData.records.combat_main_hard[GlobalData.$tempPVE_combatID] ? GlobalData.$userData.records.combat_main_hard[GlobalData.$tempPVE_combatID] : 0);
               if(!GameMap.isLoad)
               {
                  if(canWriteLegacyAwardProfile())
                  {
                  GlobalData.$userData.records.combat_main_hard[GlobalData.$tempPVE_combatID] = _limit + 1;
                  }
               }
            }
            else
            {
               if(GlobalData.$userData.records.combat_ploy == null)
               {
                  if(canWriteLegacyAwardProfile())
                  {
                  GlobalData.$userData.records.combat_ploy = {};
                  }
               }
               _limit = int(GlobalData.$userData.records.combat_ploy[GlobalData.$tempPVE_combatID] ? GlobalData.$userData.records.combat_ploy[GlobalData.$tempPVE_combatID] : 0);
               if(!GameMap.isLoad)
               {
                  if(canWriteLegacyAwardProfile())
                  {
                  GlobalData.$userData.records.combat_ploy[GlobalData.$tempPVE_combatID] = _limit + 1;
                  }
               }
               _recoder = GlobalData.$userData.ploy_cids[GlobalData.$tempPVE_battleID];
               if(_recoder == null)
               {
                  _recoder = [];
               }
               if(_recoder.indexOf(GlobalData.$tempPVE_combatID) == -1)
               {
                  _recoder.push(GlobalData.$tempPVE_combatID);
                  _isFirstWin = true;
                  if(canWriteLegacyAwardProfile())
                  {
                  GlobalData.$userData.ploy_cids[GlobalData.$tempPVE_battleID] = _recoder;
                  }
               }
            }
         }
         else
         {
            _starNum = 0;
            GuideMaster.getOnlyExample().checkGuide("M10_1");
            _tw = int(GlobalData.$mStageWidth * 0.8);
            _txt = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90035),30,65382,"center",MainConfig.$isEA ? _tw : _tw - 80,MainConfig.$isEA ? 50 : 35);
            _txt.alpha = 0;
            _txt.y = int(GlobalData.$center_height_curr * 0.65);
            _x0 = int((GlobalData.$mStageWidth - _tw) * 0.5);
            _txt.x = _x0 - 10;
            GlobalData.$mStarling.juggler.tween(_txt,1,{
               "transition":"easeOut",
               "alpha":1,
               "x":(MainConfig.$isEA ? _x0 - 2 : _x0 + 40)
            });
            this.mBox.addChild(_txt);
         }
         _arr = [];
         _nameAdd = _diff == 1 ? GlobalLanguageStr.getLanguageStr(20281) : "";
         _arr = [Tools.formatLineX(_cfgA.name + _nameAdd,_0xFFCC00Arr,30,30),Tools.formatLineX("",_0xFFCC00Arr,30,15),Tools.formatLineX(_cfgB.name + _nameAdd,_0xFFCC00Arr,30,20)];
         _a = GlobalTextStyle.getHtmlTextRenderer();
         _a.alpha = 0;
         _a.text = Tools.formatHtmlTextBr(_arr,"center");
         _a.mLayoutFun = function():void
         {
            _rec = _a.getTextSnapshotFrame();
            var _loc1_:Number = int((GlobalData.$mStageWidth - _rec.width) * 0.5);
            _a.x = _loc1_ - 50;
            GlobalData.$mStarling.juggler.tween(_a,0.7,{
               "delay":0.2,
               "transition":"easeOut",
               "alpha":1,
               "x":_loc1_
            });
         };
         _a.y = GlobalData.formatVScaleY_center(850 * 0.1);
         this.mBox.addChild(_a);
         _isMAX_lv = GlobalData.$userData.lv >= _expCfg[3];
         _add_gold = int(_isWinner ? _cfgB.gold : 0);
         _add_exp = int(_isWinner ? (_isMAX_lv ? 0 : _cfgB.exp) : 0);
         _add_updateEXP = GlobalFunction.getCurrLvMaxEXP(GlobalData.$userData.lv) - GlobalData.$userData.exp;
         _diffConfig = GameMapData.getDiffConfig(_diff);
         _firstRate = _isFirstWin ? 2 : 1;
         _add_gold = Tools.toInt(_add_gold * _firstRate * _diffConfig[3]);
         _add_exp = Tools.toInt(_add_exp * _firstRate * _diffConfig[2]);
         if(_isWinner && _awardData.gold_reward != null)
         {
            _add_gold = int(_awardData.gold_reward);
         }
         if(_isWinner && _awardData.exp_reward != null)
         {
            _add_exp = int(_awardData.exp_reward);
         }
         _goldStr = _add_gold.toString();
         _expStr = _add_exp.toString();
         _updateEXPStr = _add_updateEXP.toString();
         isRandom_avatars = false;
         if(_awardData.random_av)
         {
            isRandom_avatars = true;
            GlobalData.$tempPVE_battleID_isFirstWin = false;
            GlobalData.$tempPVE_battleID = "";
            if(_diff == 0)
            {
               GlobalData.$tempPVE_battleID_normal = "";
            }
            if(_diff == 1)
            {
               GlobalData.$tempPVE_battleID_hard = "";
            }
            if(_isWinner)
            {
               _random_avatars = GlobalData.$userData.random_avatars;
               _random_avatars_diff = _random_avatars[_diff.toString()];
               SoundManager.getOnlyExample().playSound("sound04");
               if(_random_avatars_diff)
               {
                  _rndTeam = _random_avatars_diff.random_team;
                  if(_rndTeam)
                  {
                     _goldStr += GlobalLanguageStr.getLanguageStr(20207," +" + _rndTeam[5]);
                     _expStr += GlobalLanguageStr.getLanguageStr(20207," +" + (_isMAX_lv ? 0 : _rndTeam[4]));
                  }
               }
            }
         }
         else if(_isFirstWin)
         {
            _goldStr += GlobalLanguageStr.getLanguageStr(20229);
            _expStr += GlobalLanguageStr.getLanguageStr(20229);
         }
         hasLearnObj = GlobalData.$userData.attrs.guild_graduate_skill;
         b = false;
         a = false;
         for(j in hasLearnObj)
         {
            if(hasLearnObj != {})
            {
               if(_awardData.add_gold && _awardData.add_gold != null)
               {
                  if(j == "gs_1001")
                  {
                     b = true;
                     addGold = _awardData.add_gold;
                     if(_isFirstWin)
                     {
                        addGold += GlobalLanguageStr.getLanguageStr(20229);
                     }
                  }
               }
               if(_awardData.add_exp && _awardData.add_exp != null)
               {
                  if(j == "gs_1002")
                  {
                     a = true;
                     addExp = _awardData.add_exp;
                     if(_isFirstWin)
                     {
                        addExp += GlobalLanguageStr.getLanguageStr(20229);
                     }
                  }
               }
            }
         }
         _arr = [Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20111) + (b == true ? addGold : _goldStr),GlobalTextStyle.COLOR_W_Y_Y_Y,1000,20),HtmlTextFormat.font("",0,5),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20112) + (a == true ? addExp : _expStr),GlobalTextStyle.COLOR_W_Y_Y_Y,1000,20),HtmlTextFormat.font("",0,5),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20113) + _updateEXPStr,GlobalTextStyle.COLOR_W_Y_Y_Y,1000,20)];
         _b = GlobalTextStyle.getHtmlTextRenderer();
         _b.alpha = 0;
         _b.y = int(_a.y + 230);
         _b.text = Tools.formatHtmlTextBr(_arr,"center");
         _b.mLayoutFun = function():void
         {
            _rec = _b.getTextSnapshotFrame();
            var _loc1_:Number = (GlobalData.$mStageWidth - _rec.width) * 0.5;
            _b.x = -_b.width;
            GlobalData.$mStarling.juggler.tween(_b,0.7,{
               "transition":"easeOut",
               "delay":0.5,
               "alpha":1,
               "x":_loc1_
            });
         };
         this.mBox.addChild(_b);
         _rect = mBox.getBounds(mBox.stage);
         LayoutUIAnimation.getOnlyExample().popStars(_starNum,3 - _starNum,1,_rect.y + 165);
         _str = GlobalLanguageStr.getLanguageStr(90451,_starNum);
         if(mDn_stone > 0 && !GlobalData.$isPVP && !GlobalData.$isFragment && (GlobalData.$tempPVE_type == "status_pve_hard" || GlobalData.$tempPVE_type == "status_pve_activities" || GlobalData.$tempPVE_type == "status_pve_normal"))
         {
            _stone = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getStr(90449),mDn_stone.toString() + _str,"UI_dn_icon_stone_0000",16763904,16763904);
            _stone.alpha = 0;
            _x2 = (GlobalData.$mStageWidth - _stone.textFieldWidth) * 0.5 + 22;
            _stone.x = -_stone.textFieldWidth;
            _stone.y = _b.y + 95;
            GlobalData.$mStarling.juggler.tween(_stone,0.7,{
               "transition":"easeOut",
               "delay":0.5,
               "alpha":1,
               "x":_x2
            });
            this.mBox.addChild(_stone);
         }
         if(_awardData.random_avatars)
         {
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.random_avatars = _awardData.random_avatars;
            }
         }
         if(mStatus_up)
         {
            setTimeout(delayFun,10);
         }
         else
         {
            checkMorph();
         }
         if(GlobalData.$tempPVE_type == "status_pve_activities")
         {
            if(GlobalFunction.check_pass_activeity_battle(GlobalData.$tempPVE_battleID) && _oldPassData.isPass != _newPassData.isPass)
            {
               this.isPassBattle = true;
            }
            else
            {
               this.isPassBattle = false;
            }
         }
         else if(GlobalFunction.check_pass_battle_main(GlobalData.$tempPVE_battleID,GlobalData.$tempPVE_type_id) == 1 && _oldPassData.isPass != _newPassData.isPass)
         {
            this.isPassBattle = true;
         }
         else
         {
            this.isPassBattle = false;
         }
         this.mGiftCoin = this.isPassBattle ? _cfgA.giftcoin : 0;
         _lvNew = int(GlobalData.$userData.lv);
      }
      
      private function setUIInfo_pvp15() : void
      {
         var _awardData:Object;
         var olddata:Object;
         var _lvNew:int;
         var _params:Object;
         var _isWinner:Boolean;
         var _expCfg:Array;
         var _0xFFCC00Arr:Array;
         var _numberX:Number;
         var _pvpArr:Array;
         var _pvpRec:Rectangle;
         var _pvpRec2:Rectangle;
         var _pvpRec3:Rectangle;
         var _pvpStr1:String;
         var _pvpMyTitle_old:int;
         var _txt:TextField;
         var _rec:Rectangle;
         var _pvpStr2:String;
         var obj:Object;
         var _pvpA:TextFieldHtmlRenderer;
         var sp:Sprite;
         var str:String;
         var giftObj:Object;
         var aa:*;
         GlobalData.$mEventDispatcher.addEventListener("check_is_lv",checkIsLv);
         this.changeStr_header(GlobalLanguageStr.getLanguageStr(20108));
         if(!GlobalData.$gameEndAwardObj)
         {
            return;
         }
         GlobalData.$isGameEndAward = true;
         this.mIsBinding = false;
         this.mBox.touchable = false;
         this.mStatus_award = true;
         _awardData = GlobalData.$gameEndAwardObj.data;
         olddata = GlobalData.$m15v15FightData;
         _awardData.gold = olddata.data.gold;
         _awardData.coin = olddata.data.coin;
         _awardData.score = olddata.data.score;
         _awardData.culture_book = olddata.data.culture_book;
         _awardData.exp = olddata.data.exp;
         _awardData.lv = olddata.data.lv;
         _awardData.sp = olddata.data.sp;
         _awardData.box_key = olddata.data.box_key;
         _awardData.mark = olddata.data.mark;
         _awardData.dn_stone = olddata.data.dn_stone;
         _awardData.dust = olddata.data.dust;
         _awardData.medal = olddata.data.medal;
         _awardData.sign = olddata.data.finally_sign;
         _awardData.get_avatars = olddata.data.get_avatars;
         _awardData.get_avatar_soul = olddata.data.get_avatar_soul;
         _awardData.get_equips = olddata.data.get_equips;
         _awardData.get_equip_soul = olddata.data.get_equip_soul;
         _awardData.get_fragments = olddata.data.get_fragments;
         _awardData.current_rank = olddata.data.current_rank;
         if(!_awardData)
         {
            return;
         }
         give_avatar_equip_fragment(_awardData);
         _lvNew = 0;
         _params = GlobalData.$gameEndAwardObj.params;
         _isWinner = _awardData["sign"] == 1;
         _expCfg = GlobalData.$mConfig_simple.exp_config as Array;
         _0xFFCC00Arr = [16764006,16764006,16764006,13777209];
         if(GlobalData.$isBattleOfThePeak)
         {
            aa = function():void
            {
               sp.visible = true;
            };
            _lvOld = GlobalData.$userData.lv;
            _pvpArr = null;
            _pvpStr1 = _isWinner ? GlobalLanguageStr.getLanguageStr(90097) : GlobalLanguageStr.getLanguageStr(90098);
            _pvpMyTitle_old = GlobalFunction.check_pvp_list_title(GlobalData.$userData.records.current_rank);
            if(_awardData.records)
            {
               if(canWriteLegacyAwardProfile())
               {
               GlobalData.$userData.records.current_rank = _awardData.records.current_rank;
               }
            }
            _txt = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20108),30,16777215,"center",125,46);
            _rec = _txt.bounds;
            _txt.x = (GlobalData.$mStageWidth - _rec.width) * 0.5;
            _txt.y = 60;
            this.mBox.addChild(_txt);
            _pvpStr2 = _isWinner ? GlobalLanguageStr.getLanguageStr(90100,_awardData.current_rank) : GlobalLanguageStr.getLanguageStr(90099);
            obj = GlobalData.$pvp_rival;
            _pvpArr = [Tools.formatLineX(_pvpStr1,_0xFFCC00Arr,30,20) + Tools.formatLineX(_awardData.users.user_b[2],[13777209,13777209,13777209,13777209],20,20),Tools.formatLineX(_pvpStr2,_0xFFCC00Arr,50,20),""];
            _pvpA = GlobalTextStyle.getHtmlTextRenderer();
            _pvpA.alpha = 0;
            _pvpA.text = Tools.formatHtmlTextBr(_pvpArr,"center");
            _pvpA.mLayoutFun = function():void
            {
               var _loc2_:Rectangle = _pvpA.getTextSnapshotFrame();
               var _loc1_:Number = int((GlobalData.$mStageWidth - _loc2_.width) * 0.5);
               _pvpA.x = 190;
               GlobalData.$mStarling.juggler.tween(_pvpA,0.7,{
                  "delay":0.2,
                  "transition":"easeOut",
                  "alpha":1,
                  "x":_loc1_
               });
            };
            _pvpA.y = _txt.y + 60;
            this.mBox.addChild(_pvpA);
            if(_isWinner)
            {
               SoundManager.getOnlyExample().playSound("sound02");
               _pvpArr.push(Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20112),GlobalTextStyle.COLOR_W_Y_Y_Y,1000,20));
            }
            sp = new Sprite();
            if(_awardData.win_gift)
            {
               for(str in _awardData.win_gift)
               {
                  if(str == "dust")
                  {
                     giftObj = GlobalFunction.getAwardByType(str,_awardData.win_gift[str]);
                     sp.addChild(giftObj.ui);
                  }
                  else if(str == "dn_stone")
                  {
                     giftObj = GlobalFunction.getAwardByType(str,_awardData.win_gift[str]);
                     sp.addChild(giftObj.ui);
                     if(canWriteLegacyAwardProfile())
                     {
                     GlobalData.$userData.attrs.dn_stone = _awardData.dn_stone;
                     }
                  }
                  else if(str == "mark")
                  {
                     giftObj = GlobalFunction.getAwardByType(str,_awardData.win_gift[str]);
                     sp.addChild(giftObj.ui);
                  }
                  else if(str == "gold" || str == "coin")
                  {
                     giftObj = GlobalFunction.getAwardByType(str,_awardData.win_gift[str]);
                     sp.addChild(giftObj.ui);
                  }
                  else if(str == "key" || str == "box")
                  {
                     giftObj = GlobalFunction.getAwardByType(str,_awardData.win_gift[str]);
                     sp.addChild(giftObj.ui);
                  }
                  else if(str == "equip")
                  {
                     giftObj = GlobalFunction.getAwardByType(str,_awardData.win_gift[str]);
                     sp.addChild(giftObj.ui);
                  }
                  else if(str == "equip_soul")
                  {
                     giftObj = GlobalFunction.getAwardByType(str,_awardData.win_gift[str]);
                     sp.addChild(giftObj.ui);
                  }
                  else if(str == "avatar")
                  {
                     giftObj = GlobalFunction.getAwardByType(str,_awardData.win_gift[str]);
                     sp.addChild(giftObj.ui);
                  }
                  else if(str == "avatar_soul")
                  {
                     giftObj = GlobalFunction.getAwardByType(str,_awardData.win_gift[str]);
                     sp.addChild(giftObj.ui);
                  }
                  else if(str == "medal")
                  {
                     giftObj = GlobalFunction.getAwardByType(str,_awardData.win_gift[str]);
                     sp.addChild(giftObj.ui);
                  }
                  else if(str == "sp")
                  {
                     giftObj = GlobalFunction.getAwardByType(str,_awardData.win_gift[str]);
                     sp.addChild(giftObj.ui);
                     if(canWriteLegacyAwardProfile())
                     {
                     GlobalData.$userData.attrs.sp = _awardData.sp;
                     }
                  }
                  else if(str == "exp")
                  {
                     giftObj = GlobalFunction.getAwardByType(str,_awardData.win_gift[str]);
                     sp.addChild(giftObj.ui);
                  }
                  else if(str == "score")
                  {
                     giftObj = GlobalFunction.getAwardByType(str,_awardData.win_gift[str]);
                     sp.addChild(giftObj.ui);
                  }
                  else if(str == "culture_book")
                  {
                     giftObj = GlobalFunction.getAwardByType(str,_awardData.win_gift[str]);
                     sp.addChild(giftObj.ui);
                  }
                  else if(str == "fragment")
                  {
                     giftObj = GlobalFunction.getAwardByType(str,_awardData.win_gift[str]);
                     sp.addChild(giftObj.ui);
                  }
                  else if(str == "fragment_energy")
                  {
                     giftObj = GlobalFunction.getAwardByType(str,_awardData.win_gift[str]);
                     sp.addChild(giftObj.ui);
                  }
               }
               if(sp)
               {
                  sp.visible = false;
               }
            }
            setTimeout(aa,0.5);
            sp.x = GlobalData.$mStageWidth / 2 - sp.width / 2;
            sp.y = GlobalData.$center_height - 200;
            mBox_btn.addChild(sp);
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.gold = _awardData.gold;
            }
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.coin = _awardData.coin;
            }
            GlobalFunction.updateCoin();
            GlobalFunction.updateGlod();
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.mark = _awardData.mark;
            }
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.score = _awardData.score;
            }
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.medal = _awardData.medal;
            }
            if(GlobalData.$userData.lv != _awardData.lv)
            {
               setClip_lv(GlobalData.$userData.lv,_awardData.lv);
            }
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.exp = _awardData.exp;
            }
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.lv = _awardData.lv;
            }
            GlobalFunction.updateExp();
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.attrs.culture_book = _awardData.culture_book;
            }
            if(_awardData["box_key"])
            {
               if(canWriteLegacyAwardProfile())
               {
               GlobalData.$userData.attrs.box_key = _awardData.box_key;
               }
            }
            if(_awardData["dust"])
            {
               if(canWriteLegacyAwardProfile())
               {
               GlobalData.$userData.attrs.dust = _awardData.dust;
               }
            }
            if(_awardData["dn_stone"])
            {
               if(canWriteLegacyAwardProfile())
               {
               GlobalData.$userData.attrs.dn_stone = _awardData.dn_stone;
               }
            }
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.attrs.fragment_energy = _awardData.attr_fragment_energy;
            }
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.attrs.fragment_energy_extra = _awardData.attr_fragment_energy_extra;
            }
            if(!_isWinner)
            {
               this.mBox.touchable = true;
            }
            else
            {
               mStatus_up = GlobalData.$userData.lv != _awardData.lv;
               this.mPower_old = GlobalFunction.getEnergy();
               if(!GameMap.isLoad)
               {
                  if(canWriteLegacyAwardProfile())
                  {
                  GlobalData.$userData.attrs.energy_extra = _awardData.attr_energy_extra;
                  }
                  GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateEn(_awardData.energy as Date);
               }
               this.mPower_new = GlobalFunction.getEnergy();
            }
            _lvNew = int(GlobalData.$userData.lv);
            return;
         }
      }
      
      private function checkAwardAvatar() : Boolean
      {
         var _loc1_:Boolean = false;
         var _loc2_:Boolean = false;
         var _loc3_:Boolean = false;
         if(GlobalData.$isPVP)
         {
            _loc3_ = true;
            this.setAwardAvatar(GlobalData.$gameEndAwardObj.data);
         }
         else if(GlobalData.$isFragment)
         {
            _loc3_ = false;
         }
         else
         {
            _loc1_ = Tools.isNoChildrenInObj(GlobalData.$gameEndAwardObj.data.get_avatars);
            _loc2_ = Tools.isNoChildrenInObj(GlobalData.$gameEndAwardObj.data.get_equips);
            if((!_loc1_ || GlobalData.$gameEndAwardObj.data.get_fragments != null) && GlobalData.$tempPVE_type == "status_pve_normal" || (!_loc1_ || !_loc2_ || GlobalData.$gameEndAwardObj.data.get_fragments != null) && GlobalData.$tempPVE_type == "status_pve_hard" || (!_loc1_ || !_loc2_ || GlobalData.$gameEndAwardObj.data.get_fragments != null) && GlobalData.$tempPVE_type == "status_pve_activities")
            {
               this.setAwardAvatar(GlobalData.$gameEndAwardObj.data);
               _loc3_ = true;
            }
         }
         return _loc3_;
      }
      
      private function autoOff(param1:Event) : void
      {
         mBox_btn.visible = true;
         if(mAutoTF)
         {
            mAutoTF.visible = false;
         }
      }
      
      private function checkReplayAndNext() : void
      {
         var _loc2_:GameMapData = null;
         var _loc5_:int = 0;
         var _loc9_:LOL_Scale9Button = null;
         var _loc7_:Boolean = false;
         var _loc3_:Boolean = false;
         var _loc6_:int = 0;
         if(GameMapLayer.isAuto)
         {
            GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
            if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
            {
               GlobalFunction.popAvatarLen();
            }
            else if(GlobalData.$tempPVE_type == "status_pve_hard" && Tools.getElementNum(GlobalData.$userData.my_equips) >= int(GlobalData.$mConfig_simple.equip_config[0]))
            {
               GlobalFunction.popEquipFull();
            }
            if(GlobalData.$isFragment)
            {
               GameMapLayer.setAuto(false);
            }
            else if(GlobalData.$isPVP)
            {
               GameMapLayer.setAuto(false);
            }
            else
            {
               _loc6_ = 0;
               _loc2_ = GameMapManager.getOnlyExample().getData(GlobalData.$tempPVE_combatID);
               if(GlobalData.$tempPVE_type == "status_pve_hard")
               {
                  _loc6_ = 1;
               }
               if(GlobalFunction.getEnergy().energy < _loc2_.getEnergy(_loc6_))
               {
                  GlobalFunction.popEnergy();
               }
               else
               {
                  _loc5_ = GlobalFunction.getUserCombat(GlobalData.$tempPVE_type,GlobalData.$tempPVE_combatID);
                  _loc5_ = _loc2_.getLimit(_loc6_) - _loc5_;
                  if(_loc5_ <= 0)
                  {
                     GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90031));
                  }
               }
            }
            if(GameMapLayer.isAuto)
            {
               GlobalData.$mStarling.juggler.delayCall(toAutoFight,2.5);
               mAutoTF = DisplayTools.newTextField(GlobalLanguageStr.getLanguageStr(32006),"",25,16777215,0,0,260,50);
               mAutoTF.x = GameMapConfig.SCREEN_WIDTH * 0.5;
               mAutoTF.y = GameMapConfig.SCREEN_HEIGHT * 0.66 + 60;
               this.addChild(this.mAutoTF);
               mBox_btn.visible = false;
            }
         }
         var _loc1_:int = 0;
         var _loc8_:int = 200;
         var _loc10_:int = 0;
         var _loc4_:Sprite = new Sprite();
         if(GameMap.lastRe)
         {
            _loc7_ = GameMap.lastRe.data && GameMap.lastRe.data.random_av;
            if(!_loc7_)
            {
               if(GlobalData.$userData.lv >= GlobalData.$mConfig_simple.start_lv[14])
               {
                  _loc9_ = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20464),150,70,"UI_btn_normalFun_0000");
                  _loc9_.x = _loc1_;
                  _loc9_.addEventListener("triggered",rePlay);
                  _loc4_.addChild(_loc9_);
                  _loc1_ += _loc8_;
                  _loc10_++;
               }
               if(GlobalData.$userData.lv >= GlobalData.$mConfig_simple.start_lv[15])
               {
                  _loc3_ = false;
                  if(!GlobalData.$isFragment)
                  {
                     if(!GlobalData.$isPVP)
                     {
                        if(GlobalData.$isBattleOfThePeak)
                        {
                           _loc9_.visible = false;
                        }
                        else
                        {
                           _loc6_ = 0;
                           _loc2_ = GameMapManager.getOnlyExample().getData(GlobalData.$tempPVE_combatID);
                           if(GlobalData.$tempPVE_type == "status_pve_hard")
                           {
                              _loc6_ = 1;
                           }
                           _loc5_ = GlobalFunction.getUserCombat(GlobalData.$tempPVE_type,GlobalData.$tempPVE_combatID);
                           _loc5_ = _loc2_.getLimit(_loc6_) - _loc5_;
                           if(_loc5_ > 0)
                           {
                              _loc3_ = true;
                           }
                        }
                     }
                  }
                  if(_loc3_)
                  {
                     _loc9_ = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20295),150,70,"UI_btn_normalFun_0000");
                     _loc9_.x = _loc1_;
                     _loc9_.addEventListener("triggered",reFight);
                     _loc4_.addChild(_loc9_);
                     _loc1_ += _loc8_;
                     _loc10_++;
                  }
               }
            }
         }
         if(GlobalLocalStore.$pf_type_curr == "dnyios" || GlobalLocalStore.$pf_type_curr == "dnyad")
         {
            if(GlobalData.isShow_ShareBtn)
            {
               checkShare_DNY(_loc4_,_loc1_,_loc8_,_loc10_);
               if(++_loc10_ != 3)
               {
                  _loc1_ += _loc8_;
               }
            }
         }
         _loc9_ = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20465),150,70,"UI_btn_normalFun_0000");
         if(GlobalData.$isBattleOfThePeak)
         {
            _loc9_.x = _loc9_.width / 2 - 76;
         }
         else
         {
            _loc9_.x = _loc1_;
         }
         _loc9_.addEventListener("triggered",close_Trigered);
         _loc4_.addChild(_loc9_);
         _loc4_.x = GameMapConfig.SCREEN_WIDTH * 0.5;
         _loc4_.y = GameMapConfig.SCREEN_HEIGHT * 0.66 + 80;
         _loc4_.pivotX = _loc4_.width / 2;
         mBox_btn.addChild(_loc4_);
      }
      
      private function checkShare_DNY(param1:Sprite, param2:Number, param3:Number, param4:int) : void
      {
         var _loc5_:LOL_Scale9Button = null;
         if(GlobalData.$gameEndAwardObj)
         {
            _loc5_ = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(95020),150,70,"UI_btn_normalFun_0000");
            param1.addChild(_loc5_);
            _loc5_.x = param2;
            if(param4 == 2)
            {
               _loc5_.x = param2 - param3;
               _loc5_.y = _loc5_.height;
            }
            _loc5_.addEventListener("triggered",shareTriggered);
         }
      }
      
      private function checkSharePVP_DNY() : void
      {
         GlobalPFANE.pfShare(5);
      }
      
      private function shareTriggered(param1:Event) : void
      {
         GlobalPFANE.pfShare(4);
      }

      private function showLimitBreakPanel(opportunity:Object) : void
      {
         if(!stage || !opportunity || !(opportunity.candidate_ids is Array) || mLimitBreakPanel) return;
         var current:Object = GlobalData.$userData ? GlobalData.$userData.pending_limit_break : null;
         if(!current || current.fight_id != opportunity.fight_id) return;
         var candidates:Array = opportunity.candidate_ids as Array;
         if(candidates.length == 0) return;
         mLimitBreakEncounter = opportunity;
         mLimitBreakPanel = new Sprite();
         var shade:Quad = new Quad(GlobalData.$mStageWidth,GlobalData.$mStageHeight,0x000000);
         shade.alpha = 0.72;
         mLimitBreakPanel.addChild(shade);
         var width:Number = Math.min(500,GlobalData.$mStageWidth - 30);
         var height:Number = 132 + candidates.length * 55;
         var box:Quad = new Quad(width,height,0x282239);
         box.x = (GlobalData.$mStageWidth - width) * 0.5;
         box.y = (GlobalData.$mStageHeight - height) * 0.5;
         mLimitBreakPanel.addChild(box);
         var heading:TextField = GlobalTextStyle.getTextField("基兰：选择一张卡突破极限",24,0xFFD46D,"center",width - 20,42);
         heading.x = box.x + 10;
         heading.y = box.y + 10;
         mLimitBreakPanel.addChild(heading);
         for(var i:int = 0;i < candidates.length;i++)
         {
            var iid:String = String(candidates[i]);
            var hero:Object = GlobalData.$userData.avatars[iid];
            if(!hero) continue;
            var aid:String = iid.split("|")[0];
            var definition:Object = GlobalData.$mConfig_avatar[aid];
            var heroName:String = definition && definition.name ? String(definition.name) : aid;
            var choice:LOL_Scale9Button = new LOL_Scale9Button(heroName + "  Lv." + hero.lv + "（上限→125）",width - 40,49,"UI_btn_normalFun_0000");
            choice.name = iid;
            choice.x = box.x + 20;
            choice.y = box.y + 54 + i * 55;
            choice.addEventListener("triggered",onLimitBreakChoice);
            mLimitBreakPanel.addChild(choice);
         }
         var later:LOL_Scale9Button = new LOL_Scale9Button("稍后",150,46,"UI_btn_normalFun_0000");
         later.x = box.x + (width - later.width) * 0.5;
         later.y = box.y + height - 54;
         later.addEventListener("triggered",closeLimitBreakPanel);
         mLimitBreakPanel.addChild(later);
         addChild(mLimitBreakPanel);
      }

      private function onLimitBreakChoice(event:Event) : void
      {
         if(mLimitBreakBusy || !mLimitBreakEncounter) return;
         var iid:String = String((event.currentTarget as LOL_Scale9Button).name);
         if((mLimitBreakEncounter.candidate_ids as Array).indexOf(iid) < 0) return;
         mLimitBreakBusy = true;
         SendServiceAMFFun.send_user_avatar_limit_break(function(reply:Object):void
         {
            mLimitBreakBusy = false;
            if(GlobalFunction.isMalformedProfileReceipt(reply) || !reply || int(reply.return_code) != 0) return;
            if(reply.data && reply.data.ok === false)
            {
               closeLimitBreakPanel(null);
               if(stage) GlobalFunction.popAlert("","符合条件的卡牌已不在背包中，本次机会已结束。");
               return;
            }
            closeLimitBreakPanel(null);
            if(stage) GlobalFunction.popAlert("","突破极限成功，等级上限已提升至125。");
         },{"aid":iid});
         setTimeout(function():void { mLimitBreakBusy = false; },5000);
      }

      private function closeLimitBreakPanel(event:Event) : void
      {
         if(mLimitBreakPanel)
         {
            mLimitBreakPanel.removeFromParent(true);
            mLimitBreakPanel = null;
         }
         mLimitBreakEncounter = null;
         mLimitBreakBusy = false;
      }
      
      private function close_Trigered(param1:Event) : void
      {
         if(_txt)
         {
            _txt.removeFromParent(true);
            _txt = null;
         }
         onTRIGGERED_self(param1);
         hasGuide = true;
      }
      
      protected function toAutoFight() : void
      {
         if(!this.stage)
         {
            return;
         }
         if(!GameMapLayer.isAuto)
         {
            return;
         }
         var _loc1_:* = GameMap.lastRe;
         _loc1_ = GameMap.lastRe.params;
         SendServiceAMFFun.send_user_pk_combat_main(reAutoFight,_loc1_);
      }
      
      protected function reAutoFight(param1:*) : void
      {
         GlobalData.$mEventDispatcher.dispatchEventWith("stage_game",false,{
            "fun":"auto",
            "re":param1
         });
      }
      
      protected function reFight(param1:Event) : void
      {
         var _loc4_:int = 0;
         var _loc2_:GameMapData = null;
         var _loc5_:int = 0;
         var _loc3_:int = 0;
         if(GlobalData.$isPVE)
         {
            _loc4_ = GlobalData.$diff;
            _loc2_ = GameMapManager.getOnlyExample().getData(GlobalData.$tempPVE_combatID);
            _loc5_ = int(GlobalFunction.getEnergy().energy);
            _loc3_ = _loc2_.getEnergy(_loc4_);
            GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
            if(GlobalFunction.getEnergy().energy < _loc2_.getEnergy(_loc4_))
            {
               GlobalFunction.popEnergy();
            }
            else if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
            {
               GlobalFunction.popAvatarLen();
            }
            else if(GlobalData.$tempPVE_type == "status_pve_hard" && Tools.getElementNum(GlobalData.$userData.my_equips) >= int(GlobalData.$mConfig_simple.equip_config[0]))
            {
               GlobalFunction.popEquipFull();
            }
            else if(!GameMap.canHelp(GlobalData.$tempPVE_combatID))
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
      }
      
      protected function rePlay(param1:Event) : void
      {
         if(_isFightAward)
         {
            GlobalData.$mEventDispatcher.dispatchEventWith("stage_game",false,{"fun":"replay"});
         }
         else if(GlobalData.$isPVE)
         {
            GlobalData.$mEventDispatcher.dispatchEventWith("stage_game",false,{"fun":"replay"});
         }
      }
      
      private function give_avatar_equip_fragment(param1:Object) : void
      {
         var _loc2_:Object = null;
         var _loc3_:Object = null;
         var _loc4_:Object = null;
         if(param1.get_avatars != null)
         {
            _loc2_ = param1.get_avatars;
            for(_loc4_ in _loc2_)
            {
               _loc3_ = _loc2_[_loc4_];
               _loc3_["id"] = _loc4_.toString();
               if(canWriteLegacyAwardProfile())
               {
               GlobalFunction.changeUserDataAvatars(_loc3_["id"],_loc3_,true);
               }
            }
         }
         _loc2_ = null;
         if(param1.get_equips != null)
         {
            _loc2_ = param1.get_equips;
            for(_loc4_ in _loc2_)
            {
               if(canWriteLegacyAwardProfile())
               {
               GlobalData.$userData.my_equips[_loc4_.toString()] = _loc2_[_loc4_];
               }
            }
         }
         _loc2_ = null;
         if(param1.get_fragments != null)
         {
            if(param1.get_fragments.fragment != null)
            {
               _loc2_ = param1.get_fragments.fragment;
               for(_loc4_ in _loc2_)
               {
                  if(canWriteLegacyAwardProfile())
                  {
                  GlobalData.$userData.fragment["equips"][_loc4_] = _loc2_[_loc4_];
                  }
               }
            }
         }
         _loc2_ = null;
         if(param1.get_avatar_soul != null || param1.get_avatar_soul != {})
         {
            _loc2_ = param1.get_avatar_soul;
            for(_loc4_ in _loc2_)
            {
               if(canWriteLegacyAwardProfile())
               {
               GlobalData.$userData.avatar_soul[_loc4_] = _loc2_[_loc4_];
               }
            }
         }
         _loc2_ = null;
         if(param1.get_equip_soul != null || param1.get_equip_soul != {})
         {
            _loc2_ = param1.get_equip_soul;
            for(_loc4_ in _loc2_)
            {
               if(canWriteLegacyAwardProfile())
               {
               GlobalData.$userData.equip_soul[_loc4_] = _loc2_[_loc4_];
               }
            }
         }
      }
      
      private function setAwardAvatar(param1:Object) : void
      {
         var _loc9_:ItemAvatarAward = null;
         var _loc20_:Object = null;
         var _loc18_:Number = NaN;
         var _loc16_:Number = NaN;
         var _loc10_:Object = null;
         var _loc7_:Object = null;
         var _loc3_:DisplayObject = null;
         var _loc13_:ItemEquipAward = null;
         var _loc6_:Object = null;
         var _loc15_:Object = null;
         var _loc12_:DisplayObject = null;
         var _loc19_:Object = null;
         var _hasHeroDrop:Boolean = !Tools.isNoChildrenInObj(param1.get_avatars) || !Tools.isNoChildrenInObj(param1.new_avatar_soul);
         var _hasEquipDrop:Boolean = !Tools.isNoChildrenInObj(param1.get_equips) || !Tools.isNoChildrenInObj(param1.new_equip_soul);
         var _titleId:int = 97011;
         var _titleText:String = "";
         if(param1.get_fragments != null && param1.get_fragments.fragment != null && !Tools.isNoChildrenInObj(param1.get_fragments.fragment))
         {
            _hasEquipDrop = true;
         }
         if(_hasHeroDrop && _hasEquipDrop)
         {
            _titleId = 98135;
         }
         else if(_hasEquipDrop)
         {
            _titleId = 98134;
         }
         else if(!_hasHeroDrop)
         {
            _titleId = 0;
         }
         if(_titleId > 0)
         {
            _titleText = GlobalLanguageStr.getLanguageStr(_titleId);
         }
         this.delJuggler();
         var _loc11_:uint = 0;
         var _loc8_:uint = 10;
         var _loc5_:Object = param1.get_avatars;
         var _loc14_:int = 0;
         var _loc4_:int = 5;
         for(_loc10_ in _loc5_)
         {
            _loc20_ = _loc5_[_loc10_];
            _loc20_["id"] = _loc10_.toString();
            _loc9_ = new ItemAvatarAward();
            _loc9_.data = _loc20_;
            _loc9_.x = _loc11_ % _loc4_ * (90 + 10);
            _loc9_.y = Math.floor(_loc11_ / _loc4_) * (90 + 25);
            if(MainConfig.$ispentaKill)
            {
               if(mDn_stone > 0 && !GlobalData.$isPVP && !GlobalData.$isFragment && (GlobalData.$tempPVE_type == "status_pve_hard" || GlobalData.$tempPVE_type == "status_pve_activities" || GlobalData.$tempPVE_type == "status_pve_normal"))
               {
                  _loc9_.y = Math.floor(_loc11_ / _loc4_) * (90 + 25) + 10;
               }
            }
            _loc9_.alpha = 0;
            this.mBox_avatar.addChild(_loc9_);
            GlobalData.$mStarling.juggler.tween(_loc9_,1,{
               "delay":_loc11_ * 0.2,
               "alpha":1
            });
            _loc11_ += 1;
         }
         var _loc17_:Object = param1.new_avatar_soul;
         for(_loc10_ in _loc17_)
         {
            _loc7_ = {};
            _loc7_[_loc10_] = _loc17_[_loc10_];
            _loc3_ = GlobalFunction.getAwardByType("avatar_soul",_loc7_).ui;
            _loc3_.x = _loc11_ % _loc4_ * (90 + 10);
            _loc3_.y = Math.floor(_loc11_ / _loc4_) * (90 + 25);
            if(MainConfig.$ispentaKill)
            {
               if(mDn_stone > 0 && !GlobalData.$isPVP && !GlobalData.$isFragment && (GlobalData.$tempPVE_type == "status_pve_hard" || GlobalData.$tempPVE_type == "status_pve_activities" || GlobalData.$tempPVE_type == "status_pve_normal"))
               {
                  _loc3_.y = Math.floor(_loc11_ / _loc4_) * (90 + 25) + 10;
               }
            }
            _loc3_.alpha = 0;
            this.mBox_avatar.addChild(_loc3_);
            GlobalData.$mStarling.juggler.tween(_loc3_,1,{
               "delay":_loc11_ * 0.2,
               "alpha":1
            });
            _loc11_ += 1;
         }
         if(GlobalData.$tempPVE_type == "status_pve_hard" || GlobalData.$tempPVE_type == "status_pve_activities" || GlobalData.$isPVP)
         {
            _loc6_ = param1.get_equips;
            _loc15_ = param1.new_equip_soul;
            for(_loc10_ in _loc6_)
            {
               _loc20_ = _loc6_[_loc10_];
               _loc20_["id"] = _loc10_;
               _loc13_ = new ItemEquipAward();
               _loc13_.data = _loc20_;
               _loc13_.x = _loc11_ % _loc4_ * (90 + 10) - 10;
               _loc13_.y = Math.floor(_loc11_ / _loc4_) * (90 + 25) - 3;
               if(MainConfig.$ispentaKill)
               {
                  if(mDn_stone > 0 && !GlobalData.$isPVP && !GlobalData.$isFragment && (GlobalData.$tempPVE_type == "status_pve_hard" || GlobalData.$tempPVE_type == "status_pve_activities" || GlobalData.$tempPVE_type == "status_pve_normal"))
                  {
                     _loc13_.y = Math.floor(_loc11_ / _loc4_) * (90 + 25) + 7;
                  }
               }
               _loc13_.alpha = 0;
               this.mBox_avatar.addChild(_loc13_);
               GlobalData.$mStarling.juggler.tween(_loc13_,1,{
                  "delay":_loc11_ * 0.2,
                  "alpha":1
               });
               _loc11_ += 1;
            }
            for(_loc10_ in _loc15_)
            {
               _loc12_ = GlobalFunction.getAwardByType("equip_soul",_loc15_).ui;
               _loc12_.x = _loc11_ % _loc4_ * (90 + 10);
               _loc12_.y = Math.floor(_loc11_ / _loc4_) * (90 + 25);
               if(MainConfig.$ispentaKill)
               {
                  if(mDn_stone > 0 && !GlobalData.$isPVP && !GlobalData.$isFragment && (GlobalData.$tempPVE_type == "status_pve_hard" || GlobalData.$tempPVE_type == "status_pve_activities" || GlobalData.$tempPVE_type == "status_pve_normal"))
                  {
                     _loc12_.y = Math.floor(_loc11_ / _loc4_) * (90 + 25) + 10;
                  }
               }
               _loc12_.alpha = 0;
               this.mBox_avatar.addChild(_loc12_);
               GlobalData.$mStarling.juggler.tween(_loc12_,1,{
                  "delay":_loc11_ * 0.2,
                  "alpha":1
               });
               _loc11_ += 1;
            }
         }
         if(!GlobalData.$isPVP && !GlobalData.$isFragment && param1.get_fragments != null)
         {
            _loc19_ = param1.get_fragments.fragment;
            for(_loc10_ in _loc19_)
            {
               _loc20_ = {};
               _loc20_["id"] = _loc10_.toString();
               _loc20_["fragmentType"] = "fragment";
               _loc20_["indexID_s"] = param1.get_fragments.fragment_index;
               _loc13_ = new ItemEquipAward();
               _loc13_.data = _loc20_;
               _loc13_.x = _loc11_ % _loc4_ * (90 + 10);
               _loc13_.y = Math.floor(_loc11_ / _loc4_) * (90 + 25) + 5;
               if(MainConfig.$ispentaKill)
               {
                  if(mDn_stone > 0 && !GlobalData.$isPVP && !GlobalData.$isFragment && (GlobalData.$tempPVE_type == "status_pve_hard" || GlobalData.$tempPVE_type == "status_pve_activities" || GlobalData.$tempPVE_type == "status_pve_normal"))
                  {
                     _loc13_.y = Math.floor(_loc11_ / _loc4_) * (90 + 25) + 15;
                  }
               }
               _loc13_.alpha = 0;
               this.mBox_avatar.addChild(_loc13_);
               GlobalData.$mStarling.juggler.tween(_loc13_,1,{
                  "delay":_loc11_ * 0.2,
                  "alpha":1
               });
               _loc11_ += 1;
            }
         }
         this.mBox_avatar.x = int((GlobalData.$mStageWidth - (_loc11_ > _loc4_ ? _loc4_ : _loc11_) * 100) * 0.5);
         this.mBox_avatar.y = int(GlobalData.$center_height_curr * 0.55);
         var _loc2_:Number = int(GlobalData.$mStageWidth * 0.8);
         _txt = GlobalTextStyle.getTextField(_titleText,30,16764006,"center",_loc2_,35);
         addChild(_txt);
         if(_loc11_ > 0 && _titleId > 0)
         {
            _txt.x = int((GlobalData.$mStageWidth - _loc2_) * 0.5);
            _txt.y = this.mBox_avatar.y - 35 - 10;
            if(MainConfig.$ispentaKill)
            {
               if(mDn_stone > 0 && !GlobalData.$isPVP && !GlobalData.$isFragment && (GlobalData.$tempPVE_type == "status_pve_hard" || GlobalData.$tempPVE_type == "status_pve_activities" || GlobalData.$tempPVE_type == "status_pve_normal"))
               {
                  _txt.y = this.mBox_avatar.y - 35 + 15;
               }
            }
         }
         else
         {
            _txt.visible = false;
         }
      }
      
      private function setClip_lv(param1:int, param2:int, param3:Function = null) : void
      {
         var _loc7_:Object = null;
         var _loc4_:int = 0;
         var _loc9_:String = null;
         var _loc6_:Array = null;
         var _energy_old_max:int = 0;
         var _energy_new_max:int = 0;
         var _loc8_:String = "getAvatar";
         SoundManager.getOnlyExample().playSound(_loc8_);
         var _loc5_:Object = GlobalFunction.getEnergy();
         if(_loc5_)
         {
            _loc7_ = GlobalData.$gameEndAwardObj.data;
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.exp = _loc7_.exp;
            }
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.lv = param2;
            }
            _loc4_ = GlobalFunction.getLeaderShip();
            _loc9_ = String(_loc4_ - GlobalData.$mConfig_simple.leadership[0]);
            _energy_old_max = energyMaxForLevel(param1);
            _energy_new_max = energyMaxForLevel(param2);
            _loc6_ = [[Tools.formatLineX(GlobalLanguageStr.getLanguageStr(98230)),_energy_old_max,_energy_new_max],[Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97623)),_loc9_,_loc4_.toString()]];
         }
         GlobalFunction.popFunctionOpenAlert(GlobalLanguageStr.getLanguageStr(97607,param2),_loc6_,{"close":param3},true);
      }
      
      private function setClip_lv2(param1:int, param2:int, param3:Function) : void
      {
         var _loc9_:Object = null;
         var _loc4_:int = 0;
         var _loc11_:String = null;
         var _loc5_:GameMapData = null;
         var _loc8_:String = null;
         var _loc7_:Array = null;
         var _energy_old_max:int = 0;
         var _energy_new_max:int = 0;
         var _loc10_:String = "getAvatar";
         SoundManager.getOnlyExample().playSound(_loc10_);
         var _loc6_:Object = GlobalFunction.getEnergy();
         if(_loc6_)
         {
            _loc9_ = GlobalData.$gameEndAwardObj.data;
            _loc4_ = GlobalFunction.getLeaderShip();
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.exp = _loc9_.exp;
            }
            if(canWriteLegacyAwardProfile())
            {
            GlobalData.$userData.lv = _loc9_.lv;
            }
            _loc11_ = String(_loc4_ - GlobalData.$mConfig_simple.leadership[0]);
            _energy_old_max = energyMaxForLevel(param1);
            _energy_new_max = energyMaxForLevel(param2);
            _loc7_ = [[Tools.formatLineX(GlobalLanguageStr.getLanguageStr(98230)),_energy_old_max,_energy_new_max],[Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97623)),_loc11_,_loc4_.toString()]];
         }
         GlobalFunction.popFunctionOpenAlert(GlobalLanguageStr.getLanguageStr(97607,param2),_loc7_,{"close":param3},true);
      }

      private function energyMaxForLevel(param1:int) : int
      {
         var _cfg:Array = GlobalData.$mConfig_simple.energy_config as Array;
         var _vip_bonus:int = GlobalData.$userData.vip_lv > 0 ? int(GlobalFunction.getVipObj().energy_limit_add) : 0;
         var _max:int = int(Number(_cfg[0]) + Math.floor(param1 * Number(_cfg[1])) + _vip_bonus);
         return _max > int(_cfg[3]) ? int(_cfg[3]) : _max;
      }
      
      private function check_isBinding(param1:int, param2:int) : void
      {
      }
   }
}

