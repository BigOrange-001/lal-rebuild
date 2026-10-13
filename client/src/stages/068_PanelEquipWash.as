package com.meng52.game.ui.panel
{
   import com.meng52.display.ProgressBar;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.equip.Equip;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.ui.element.ItemEquip;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelCenterMainAvatar;
   import com.meng52.game.ui.stage.GuideTools;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.RpcStaticCall;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale3Image;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import starling.animation.Juggler;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.EnterFrameEvent;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.extensions.ColorArgb;
   import starling.extensions.PDParticleSystem;
   import starling.text.TextField;
   
   public class PanelEquipWash extends PanelCenterMainAvatar
   {
      
      private static const BTN_NAME_WASH:String = "btn_name_wash";
      
      private static const BTN_NAME_BACK:String = "btn_name_back";
      
      private static const BTN_NAME_SAVE:String = "btn_name_save";
      
      private static const BAR_NAME_EXP:String = "bar_name_exp";
      
      private static const BAR_NAME_BG:String = "bar_name_bg";
      
      private static const BAR_NAME_PROGRESS:String = "bar_name_progress";
      
      private static const BAR_NAME_LIGHT:String = "bar_name_light";
      
      public static var $selectType:int = 0;
      
      private var mCurrEquip:ItemEquip;
      
      private var mImg_label:Image;
      
      private var mBtn_wash:LOL_Scale9Button;
      
      private var mBtn_back:LOL_Scale9Button;
      
      private var mBtn_save:LOL_Scale9Button;
      
      private var mBox_price:Sprite;
      
      private var mArr_price:Array;
      
      private var mArr_priceData:Array;
      
      private var mBox_att:Sprite;
      
      private var mCurr_selectPrice:Object;
      
      private var mCurr_eid:String = "";
      private var mWashViewEpoch:uint = 0;
      private var mWashOperationToken:uint = 0;
      
      private var mBox_exp:Sprite;
      
      private var mBox_expBar:Sprite;
      
      private var mJuggler_upLv:Juggler;
      
      private var mParticleSystem:PDParticleSystem;
      
      public var mBox_data:Sprite;
      
      public var mBox_team:Sprite;
      
      public var mBg_team:Image;
      
      public var mBg_data:Image;
      
      public var mArr_team:Array;
      
      public var mRuler_item:Number = 0;
      
      public var mBox_equip:Sprite;
      
      private var mBtn_help:LOL_Button;
      
      private var _coinT:LOL_MutilTextFieldIcon;
      
      private var _spRule:Sprite;
      
      public function PanelEquipWash()
      {
         super();
         GlobalData.$mEventDispatcher.addEventListener("update_coin",updataCoin);
         GlobalData.$mEventDispatcher.addEventListener("profile_state_sync",onProfileStateSync);
      }
      
      private function updataCoin() : void
      {
         if(_coinT)
         {
            _coinT.txt2 = GlobalData.$userData.coin;
         }
      }

      private function onProfileStateSync(param1:Event) : void
      {
         if(stage == null || mCurr_eid == "" || mBox_equip == null || mBox_data == null || mBox_att == null)
         {
            return;
         }
         var _selectedEid:String = mCurr_eid;
         setEquipUIs(mBox_equip,true);
         setTxt_lv_pote(mBox_data,true);
         setAttUIs(mBox_att,0,true);
         checkBtns();
         setHaloExp();
         updataCoin();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         mWashViewEpoch += 1;
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(20006) + GlobalLanguageStr.getLanguageStr(20260));
         initOtherUIs();
      }
      
      override public function onTRIGGERED_closePanel(param1:Event) : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.reSetLastPanel_ID();
         GlobalData.$mEventDispatcher.dispatchEventWith("update_equip_list_data");
         super.onTRIGGERED_closePanel(null);
         if(PanelTeamListInfo.isTeamListInfo)
         {
            LayoutUIAnimation.getOnlyExample().clearIfNoGuide();
         }
      }
      
      public function checkGuide() : void
      {
         var _loc1_:* = undefined;
         var _loc2_:Equip = null;
         var _loc3_:String = GuideTools.checkGuideType();
         if(mCurrEquip && mCurrEquip.data && mCurrEquip.data.id != "")
         {
            if(!GlobalData.$userData.attrs.equip_wash)
            {
               GuideMaster.getOnlyExample().checkGuide("M6_1",checkGuide);
            }
         }
         if(_loc3_ == "6")
         {
            if(mCurrEquip && mCurrEquip.data && mCurrEquip.data.id != "")
            {
               _loc1_ = GlobalData.$userData;
               _loc2_ = new Equip(mCurrEquip.data.id);
               if(GlobalData.$userData.attrs.equip_wash)
               {
                  LayoutUIAnimation.getOnlyExample().addArrowhead(463,774,50);
               }
               else if(!mCurr_selectPrice)
               {
                  LayoutUIAnimation.getOnlyExample().addArrowhead(119,595,50);
               }
               else
               {
                  LayoutUIAnimation.getOnlyExample().addArrowhead(325,774,50);
               }
            }
            else
            {
               LayoutUIAnimation.getOnlyExample().addArrowhead(320,450,50);
            }
         }
         else
         {
            LayoutUIAnimation.getOnlyExample().clearIfNoGuide();
         }
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalData.$mEventDispatcher.removeEventListener("profile_state_sync",onProfileStateSync);
         mWashViewEpoch += 1;
         mWashOperationToken += 1;
         _spRule.removeEventListener("touch",onTRIGGERED_help);
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
         if(mCurrEquip)
         {
            mCurrEquip.removeFromParent(true);
         }
         if(mBox_price)
         {
            StarlingTools.removeChildrenClear(mBox_price);
         }
         if(mBox_exp)
         {
            StarlingTools.removeChildrenClear(mBox_exp);
            mBox_exp.removeFromParent(true);
         }
         if(mBtn_wash)
         {
            mBtn_wash.dispose();
         }
         if(mBtn_back)
         {
            mBtn_back.dispose();
         }
         if(mBtn_save)
         {
            mBtn_save.dispose();
         }
         if(mBox_price)
         {
            StarlingTools.removeChildrenClear(mBox_price);
         }
         if(mBox_att)
         {
            StarlingTools.removeChildrenClear(mBox_att);
            mBox_att.removeFromParent(true);
         }
         if(mBtn_help)
         {
            mBtn_help.removeFromParent(true);
         }
         mBtn_help = null;
         super.onREMOVED_FROM_STAGE(param1);
         mJuggler_upLv = null;
         mParticleSystem = null;
         mBtn_wash = null;
         mBtn_back = null;
         mBtn_save = null;
         mArr_price = null;
         mArr_priceData = null;
         mCurr_selectPrice = null;
         mBox_exp = null;
         mCurr_eid = "";
         GlobalData.$tempEquipCurrSelected = "";
      }
      
      private function onENTER_FRAME_clip(param1:EnterFrameEvent) : void
      {
         if(mJuggler_upLv)
         {
            mJuggler_upLv.advanceTime(param1.passedTime);
         }
      }
      
      public function initOtherUIs() : void
      {
         mCurr_selectPrice = null;
         mJuggler_upLv = new Juggler();
         this.addEventListener("enterFrame",onENTER_FRAME_clip);
         mBox_equip = new Sprite();
         mBox_equip.x = 78;
         mBox_equip.y = 100;
         addChild(mBox_equip);
         setEquipUIs(mBox_equip);
         if(!checkIsWash())
         {
            setChangeStatusUI();
            return;
         }
         setExpBarUIs();
         mBox_data = new Sprite();
         mBox_data.touchable = false;
         mBox_data.x = 125;
         mBox_equip.addChild(mBox_data);
         setTxt_lv_pote(mBox_data);
         mBox_exp.x = mBox_equip.x;
         mBox_exp.y = mBox_equip.y + 115;
         mBox_price = new Sprite();
         addChild(mBox_price);
         setFun_price(mBox_price);
         mBox_att = new Sprite();
         mBox_att.addEventListener("touch",onTOUCH_att);
         var _loc3_:Scale9Image = GlobalFunction.createScale9Image("UI_bg_9slice_7_0000",490,140,new Rectangle(25,25,15,15));
         mBox_att.addChild(_loc3_);
         addChild(mBox_att);
         var _loc2_:Number = GlobalData.$center_height;
         var _loc1_:Number = 0;
         var _loc4_:Number = 0;
         mBtn_wash = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20260),150,70,"UI_btn_normalFun_0000");
         mBtn_wash.name = "btn_name_wash";
         mBtn_back = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20270),150,70,"UI_btn_normalFun_0000");
         mBtn_back.name = "btn_name_back";
         mBtn_save = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20271),150,70,"UI_btn_normalFun_0000");
         mBtn_save.name = "btn_name_save";
         addChild(mBtn_wash);
         addChild(mBtn_back);
         addChild(mBtn_save);
         mBtn_wash.shadowFilter();
         mBtn_back.shadowFilter();
         mBtn_save.shadowFilter();
         _loc1_ = mBtn_wash.width * 3 + 15 * 2;
         _loc4_ = int((GlobalData.$mStageWidth - _loc1_) * 0.5) + 10;
         mBtn_wash.y = mBtn_back.y = mBtn_save.y = _height - mBtn_wash.height - 35;
         mBtn_back.x = _loc4_;
         mBtn_wash.x = mBtn_back.x + mBtn_back.width + 15;
         mBtn_save.x = mBtn_wash.x + mBtn_wash.width + 15;
         mBtn_back.x += 30;
         mBtn_save.x -= 30;
         mBox_att.x = int((GlobalData.$mStageWidth - _loc3_.width) * 0.5);
         mBox_att.y = mBox_equip.y + 155;
         mBox_price.x = mBox_att.x;
         mBox_price.y = mBtn_wash.y - _loc3_.height - 100;
         mBtn_wash.addEventListener("triggered",onTRIGGERED_fun);
         mBtn_back.addEventListener("triggered",onTRIGGERED_fun);
         mBtn_save.addEventListener("triggered",onTRIGGERED_fun);
         setAttUIs(mBox_att,_loc3_.width);
         checkBtns();
         checkGuide();
         setHaloExp();
         var _loc5_:Object = GlobalFunction.get_HelpLink(GlobalLanguageStr.getLanguageStr(90518));
         _spRule = _loc5_.ui;
         _spRule.x = _width - _loc5_.w - 40;
         _spRule.y = 88;
         addChild(_spRule);
         _spRule.addEventListener("touch",onTRIGGERED_help);
      }
      
      private function onTRIGGERED_help(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(_spRule);
         if(_loc2_)
         {
            if(_loc2_.phase == "ended")
            {
               GlobalFunction.popPanelHelp(MainConfig.SERVER_ADDRESS_HELP_ADD_WASH);
            }
         }
      }
      
      private function setChangeStatusUI() : void
      {
         var _loc2_:ColorArgb = null;
         var _loc1_:ColorArgb = null;
         if(mBox_equip)
         {
            mBox_equip.x = int((GlobalData.$mStageWidth - 100) * 0.5);
            mBox_equip.y = int((GlobalData.$center_height_curr - 121 - 100) * 0.5);
            mParticleSystem = new PDParticleSystem(GlobalData.$assetManager.getXml("drugs"),GlobalFunction.getTexture("drugs_particle"));
            mParticleSystem.x = 50;
            mParticleSystem.y = 50;
            _loc2_ = ColorArgb.fromArgb(102);
            _loc1_ = ColorArgb.fromArgb(65535);
            mParticleSystem.startColor = new ColorArgb(_loc2_.red,_loc2_.green,_loc2_.blue,0.76);
            mParticleSystem.startColorVariance = new ColorArgb(_loc2_.red,_loc2_.green,_loc2_.blue,0.08);
            mParticleSystem.endColor = new ColorArgb(_loc1_.red,_loc1_.green,_loc1_.blue,0.2);
            mBox_equip.addChildAt(mParticleSystem,0);
            mJuggler_upLv.add(mParticleSystem);
            mParticleSystem.start();
            checkGuide();
         }
      }
      
      private function onTouchEvent_bar(param1:TouchEvent) : void
      {
         var _loc2_:Touch = null;
         var _loc3_:Equip = null;
         if(mBox_exp)
         {
            _loc2_ = param1.getTouch(mBox_exp);
            if(_loc2_)
            {
               if(_loc2_.phase == "ended")
               {
                  if(mCurrEquip.data.id != null && mCurrEquip.data.id != "")
                  {
                     _loc3_ = new Equip(mCurrEquip.data.id,mCurrEquip.data);
                     GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(90108,Math.round((_loc3_.getHaloUpAttrs() - 1) * 100)));
                  }
               }
            }
         }
      }
      
      private function onTOUCH_att(param1:TouchEvent) : void
      {
         var _loc2_:Touch = null;
         var _loc3_:Array = null;
         if(mBox_att)
         {
            _loc2_ = param1.getTouch(mBox_att,"ended");
            if(_loc2_)
            {
               if(GlobalData.$mGameClassObject.isPopUp_Open())
               {
                  return;
               }
               _loc3_ = [Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90109),GlobalTextStyle.COLOR_W_W_Y_G,20),"",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90110),GlobalTextStyle.COLOR_W_W_Y_G,20),"",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90111),GlobalTextStyle.COLOR_W_W_Y_G,20),"",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90112),GlobalTextStyle.COLOR_W_W_Y_G,20),"",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90522),GlobalTextStyle.COLOR_W_W_Y_G,20),"",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90523),GlobalTextStyle.COLOR_W_W_Y_G,20)];
               GlobalFunction.popAlert("",Tools.formatHtmlTextBr(_loc3_,"center"));
            }
         }
      }
      
      public function setHaloExp() : void
      {
         var _loc2_:ProgressBar = null;
         var _loc4_:Equip = null;
         var _loc1_:Number = NaN;
         var _loc5_:Number = NaN;
         var _loc3_:Number = NaN;
         if(mCurrEquip)
         {
            if(mBox_exp)
            {
               _loc2_ = mBox_exp.getChildByName("bar_name_progress") as ProgressBar;
               mBox_exp.visible = false;
               if(mCurrEquip.data.id != null && mCurrEquip.data.id != "")
               {
                  mBox_exp.visible = true;
                  _loc4_ = new Equip(mCurrEquip.data.id,mCurrEquip.data);
                  _loc1_ = _loc4_.getHaloExpMax();
                  _loc5_ = _loc4_.haloExp;
                  _loc3_ = _loc1_ < 0 ? 1 : _loc5_ / _loc1_;
                  _loc2_.mMax = _loc2_.mBg.width;
                  _loc2_.ratio = _loc3_;
                  var haloExpLabel:TextField = mBox_exp.getChildByName("halo_exp_text") as TextField;
                  if(haloExpLabel != null)
                  {
                     haloExpLabel.text = _loc1_ < 0 ? GlobalLanguageStr.getLanguageStr(98212) : GlobalLanguageStr.getLanguageStr(98211,_loc5_,_loc1_);
                  }
               }
            }
         }
      }
      
      private function checkBtns() : void
      {
         var _loc2_:Boolean = GlobalData.$userData.attrs.equip_wash == null;
         mBtn_wash.visible = _loc2_;
         mBtn_save.visible = !_loc2_;
         mBtn_back.visible = !_loc2_;
         var _loc1_:Boolean = false;
         if(_loc2_ && mCurr_eid != "" && mCurr_selectPrice != null)
         {
            _loc1_ = true;
         }
         mBtn_wash.enabled = _loc1_;
      }
      
      private function onTRIGGERED_fun(param1:Event) : void
      {
         var _equipData:Object;
         var _equip:Equip;
         var sendWash:*;
         var _event:Event = param1;
         var _btn:LOL_Scale9Button = _event.currentTarget as LOL_Scale9Button;
         if(_btn.name == "btn_name_wash")
         {
            if(_btn.enabled)
            {
               _equipData = GlobalData.$userData.my_equips[mCurr_eid];
               if(_equipData != null)
               {
                  sendWash = function():void
                  {
                     var _loc1_:int = 0;
                     if(mCurr_selectPrice.type == "coin")
                     {
                        _loc1_ = _equip.getWashCoin(-1,mCurr_selectPrice.num);
                        if(GlobalData.$userData.coin < _loc1_)
                        {
                           GlobalFunction.popErrorCoin(_loc1_);
                        }
                        else
                        {
                           sendWashRequest();
                        }
                     }
                     else if(GlobalData.$userData.mark < _equip.getWashMark(-1,mCurr_selectPrice.num))
                     {
                        GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90080));
                     }
                     else
                     {
                        sendWashRequest();
                     }
                  };
                  _equip = new Equip(mCurr_eid,_equipData);
                  if(_equip.getPoteNow() > 0)
                  {
                     if(checkIsPay())
                     {
                        sendWash();
                     }
                  }
                  else
                  {
                     sendWash();
                  }
               }
            }
            else
            {
               if(!checkIsPay())
               {
                  return;
               }
               if(mCurr_eid == "")
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90081));
               }
            }
         }
         else if(_btn.name == "btn_name_back")
         {
            if(_btn.enabled)
            {
               if(SendAndSelect.checkRepeat("user.equip_wash_cancel",""))
               {
                  RpcStaticCall.$remoting.reportDiagnostic("PROFILE_REQUEST_DUPLICATE_SUPPRESSED|method=user.equip_wash_cancel");
                  return;
               }
               var _cancelEid:String = mCurr_eid;
               var _cancelEpoch:uint = mWashViewEpoch;
               var _cancelToken:uint = ++mWashOperationToken;
               SendServiceAMFFun.send_user_equip_wash_cancel(function(param1:Object):void
               {
                  re_equip_wash_cancel(param1,_cancelEid,_cancelEpoch,_cancelToken);
               });
            }
         }
         else if(_btn.name == "btn_name_save")
         {
            if(_btn.enabled)
            {
               if(SendAndSelect.checkRepeat("user.equip_wash_save",""))
               {
                  RpcStaticCall.$remoting.reportDiagnostic("PROFILE_REQUEST_DUPLICATE_SUPPRESSED|method=user.equip_wash_save");
                  return;
               }
               var _saveEid:String = mCurr_eid;
               var _saveEpoch:uint = mWashViewEpoch;
               var _saveToken:uint = ++mWashOperationToken;
               SendServiceAMFFun.send_user_equip_wash_save(function(param1:Object):void
               {
                  re_equip_wash_save(param1,_saveEid,_saveEpoch,_saveToken);
               });
            }
         }
      }

      private function sendWashRequest() : void
      {
         if(SendAndSelect.checkRepeat("user.equip_wash",""))
         {
            RpcStaticCall.$remoting.reportDiagnostic("PROFILE_REQUEST_DUPLICATE_SUPPRESSED|method=user.equip_wash");
            return;
         }
         var _washEid:String = mCurr_eid;
         var _washEpoch:uint = mWashViewEpoch;
         var _washToken:uint = ++mWashOperationToken;
         var _washType:String = mCurr_selectPrice.type;
         var _washNum:int = int(mCurr_selectPrice.num);
         SendServiceAMFFun.send_user_equip_wash(function(param1:Object):void
         {
            re_equip_wash(param1,_washEid,_washEpoch,_washToken);
         },{
            "eqid":_washEid,
            "ttype":_washType,
            "num":_washNum
         });
      }
      
      private function re_equip_wash(param1:Object, param2:String, param3:uint, param4:uint) : void
      {
         if(GlobalFunction.isMalformedProfileReceipt(param1))
         {
            return;
         }
         if(GlobalFunction.isLegacyProfileReceipt(param1))
         {
            RpcStaticCall.$remoting.reportDiagnostic("PROFILE_RECEIPT_LEGACY|method=user.equip_wash");
         }
         if(!isCurrentWashView(param2,param3,param4))
         {
            return;
         }
         var _loc8_:Object = param1["params"];
         var _loc3_:Array = param1.data as Array;
         if(_loc8_["ttype"] == "coin")
         {
            if(mBox_price.getChildByName("_coin_txt_"))
            {
               (mBox_price.getChildByName("_coin_txt_") as LOL_MutilTextFieldIcon).txt2 = GlobalData.$userData.coin;
            }
         }
         else
         {
            if(mBox_price)
            {
               if(mBox_price.getChildByName("_mark_txt_"))
               {
                  (mBox_price.getChildByName("_mark_txt_") as LOL_MutilTextFieldIcon).txt2 = GlobalData.$userData.mark;
               }
            }
         }
         setEquipUIs(mBox_equip,true);
         setTxt_lv_pote(mBox_data,true);
         setAttUIs(mBox_att,0,true);
         checkBtns();
         setHaloExp();
         GlobalData.$tempTeamPowerTemp = GlobalFunction.getTeamPower(GlobalData.$userData.team[0]);
         if(GlobalFunction.didApplyProfileStateSync(param1))
         {
            SoundManager.getOnlyExample().playSound("skill1");
            GuideTools.doModuleGuide("6",25);
            checkGuide();
            var _loc6_:Rectangle = mCurrEquip.getBounds(stage);
            var _loc4_:int = _loc6_.x + 51;
            var _loc5_:int = _loc6_.y + 51;
            LayoutUIAnimation.getOnlyExample().popEffect({
               "id":"e008",
               "x":_loc4_,
               "y":_loc5_,
               "sc":1.2
            });
         }
      }
      
      private function re_equip_wash_save(param1:Object, param2:String, param3:uint, param4:uint) : void
      {
         if(GlobalFunction.isMalformedProfileReceipt(param1))
         {
            return;
         }
         if(GlobalFunction.isLegacyProfileReceipt(param1))
         {
            RpcStaticCall.$remoting.reportDiagnostic("PROFILE_RECEIPT_LEGACY|method=user.equip_wash_save");
         }
         if(!isCurrentWashView(param2,param3,param4))
         {
            return;
         }
         GlobalData.$tempTeamPowerTemp = GlobalFunction.getTeamPower(GlobalData.$userData.team[0]);
         if(GlobalFunction.didApplyProfileStateSync(param1))
         {
            SoundManager.getOnlyExample().playSound("E_9011");
            checkGuide();
            var _loc4_:Rectangle = mCurrEquip.getBounds(stage);
            var _loc2_:int = _loc4_.x + 51;
            var _loc3_:int = _loc4_.y + 41;
            LayoutUIAnimation.getOnlyExample().popEffect({
               "id":"e703",
               "x":_loc2_,
               "y":_loc3_,
               "sc":1.2,
               "t":1
            });
         }
      }
      
      private function re_equip_wash_cancel(param1:Object, param2:String, param3:uint, param4:uint) : void
      {
         if(GlobalFunction.isMalformedProfileReceipt(param1))
         {
            return;
         }
         if(GlobalFunction.isLegacyProfileReceipt(param1))
         {
            RpcStaticCall.$remoting.reportDiagnostic("PROFILE_RECEIPT_LEGACY|method=user.equip_wash_cancel");
         }
         if(!isCurrentWashView(param2,param3,param4))
         {
            return;
         }
         GlobalData.$tempTeamPowerTemp = GlobalFunction.getTeamPower(GlobalData.$userData.team[0]);
         if(GlobalFunction.didApplyProfileStateSync(param1))
         {
            SoundManager.getOnlyExample().playSound("E_8002");
            checkGuide();
         }
      }

      private function isCurrentWashView(param1:String, param2:uint, param3:uint) : Boolean
      {
         return stage != null && mCurrEquip != null && mBox_price != null && mBox_data != null && mBox_att != null && param1 == mCurr_eid && param2 == mWashViewEpoch && param3 == mWashOperationToken && GlobalData.$userData.my_equips != null && GlobalData.$userData.my_equips[param1] != null;
      }
      
      private function checkIsWash() : Boolean
      {
         var _loc1_:Object = GlobalData.$userData.attrs.equip_wash;
         if(_loc1_)
         {
            mCurr_eid = _loc1_.eqid;
         }
         else
         {
            mCurr_eid = GlobalData.$tempEquipCurrSelected;
         }
         var _loc3_:Object = GlobalData.$userData.my_equips[mCurr_eid];
         return _loc3_ != null;
      }
      
      private function setExpBarUIs() : void
      {
         var _loc2_:Object = {
            "f":10,
            "s":10,
            "x":3,
            "y":3,
            "gapX":3
         };
         mBox_exp = new Sprite();
         mBox_exp.addEventListener("touch",onTouchEvent_bar);
         var _loc3_:Scale3Image = GlobalFunction.createScale3Image("UI_bar_exp_8_0000",10,10,485);
         _loc3_.y = 2;
         mBox_exp.addChild(_loc3_);
         var _loc1_:ProgressBar = new ProgressBar(GlobalFunction.getTexture("UI_bar_exp_8_0000"),GlobalFunction.getTexture("UI_equip_bar_1_0000"),_loc2_);
         _loc1_.mBg.visible = false;
         _loc1_.mBg.width = 485;
         _loc1_.mBg.height = 22;
         _loc1_.name = "bar_name_progress";
         _loc1_.setRatio(0);
         mBox_exp.addChild(_loc1_);
         var haloExpLabel:TextField = GlobalTextStyle.getTextField("",15,16777215,"center",485,22);
         haloExpLabel.name = "halo_exp_text";
         haloExpLabel.y = 2;
         haloExpLabel.touchable = false;
         mBox_exp.addChild(haloExpLabel);
         addChild(mBox_exp);
      }
      
      private function setEquipUIs(param1:Sprite, param2:Boolean = false) : void
      {
         if(param2)
         {
            StarlingTools.removeChildrenClear(mCurrEquip);
            mCurrEquip.clear();
         }
         mCurrEquip = null;
         var _loc3_:Object = GlobalData.$userData.attrs.equip_wash;
         if(_loc3_)
         {
            mCurr_eid = _loc3_.eqid;
            mCurr_selectPrice = {
               "type":_loc3_.ttype,
               "num":_loc3_.num
            };
         }
         else
         {
            mCurr_eid = GlobalData.$tempEquipCurrSelected;
         }
         var _loc5_:Object = GlobalData.$userData.my_equips[mCurr_eid];
         var _loc4_:Boolean = _loc5_ != null;
         _loc5_ = _loc5_ == null ? {} : _loc5_;
         _loc5_["status"] = -1;
         _loc5_["score"] = _loc4_;
         _loc5_["id"] = _loc5_ == null ? null : mCurr_eid;
         mCurrEquip = new ItemEquip();
         mCurrEquip.data = _loc5_;
         param1.addChild(mCurrEquip);
      }
      
      private function setTxt_lv_pote(param1:Sprite, param2:Boolean = false) : void
      {
         if(param2)
         {
            StarlingTools.removeChildrenClear(param1);
         }
         var _loc13_:String = mCurr_eid;
         var _loc12_:Object = GlobalData.$userData.my_equips[_loc13_];
         var _loc14_:int = 0;
         var _loc9_:String = GlobalLanguageStr.getLanguageStr(90081);
         var _loc10_:Equip = null;
         if(_loc12_ != null)
         {
            _loc10_ = new Equip(_loc13_,_loc12_);
            _loc14_ = _loc10_.lv;
            _loc9_ = _loc10_.equipData.name;
         }
         var _loc16_:int = 34;
         var _loc15_:int = GlobalData.$mStageWidth * 0.8;
         var _loc11_:TextField = GlobalTextStyle.getTextField(_loc9_,20,16777215,"left",_loc15_,46);
         param1.addChild(_loc11_);
         if(_loc12_ == null)
         {
            return;
         }
         var _loc8_:TextField = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20079,_loc14_),20,16777215,"left",_loc15_,46);
         _loc8_.y = _loc11_.y + _loc16_;
         param1.addChild(_loc8_);
         var _loc5_:int = 0;
         var _loc7_:int = 0;
         var _loc4_:* = 6710886;
         if(_loc10_ != null)
         {
            _loc5_ = _loc10_.haloLv;
            _loc7_ = Math.round((_loc10_.getHaloUpAttrs() - 1) * 100);
            if(_loc5_ > 0)
            {
               _loc4_ = uint(Equip.haloColor[_loc5_ - 1]);
            }
         }
         var _loc6_:Array = [16777215,16777215,43520,3368703,13369548,16763904];
         var _loc3_:TextField = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(98210,_loc5_,_loc7_),20,_loc6_[_loc10_.haloLv],"left",_loc15_ - 100,46);
         _loc3_.y = _loc8_.y + _loc16_;
         param1.addChild(_loc3_);
      }
      
      private function setFun_price(param1:Sprite, param2:Boolean = false) : void
      {
         var _loc7_:Equip = null;
         var _loc11_:LOL_Button = null;
         var _loc4_:Rectangle = null;
         var _loc19_:Object = null;
         var _loc9_:Image = null;
         if(param2)
         {
            StarlingTools.removeChildrenClear(param1);
         }
         var _loc17_:String = mCurr_eid;
         var _loc15_:Object = GlobalData.$userData.my_equips[_loc17_];
         var _loc3_:int = int(GlobalData.$mConfig_simple.equip_config[7]);
         var _loc5_:int = GlobalData.$mConfig_simple.equip_config[8] + GlobalData.$mConfig_simple.equip_config[9];
         var _loc20_:int = GlobalData.$mStageWidth * 0.5;
         var _loc16_:Scale9Image = GlobalFunction.createScale9Image("UI_bg_9slice_7_0000",490,140,new Rectangle(25,25,15,15));
         _loc16_.y = mImg9_baseBg.height * 0.07 + 15;
         param1.addChild(_loc16_);
         if(mCurr_eid == "")
         {
            return;
         }
         var _loc10_:TextField = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(98213),20,16764006,"left",_loc20_,46);
         _loc10_.x = _loc16_.x;
         _loc10_.y = _loc16_.y - 29 - 5;
         param1.addChild(_loc10_);
         var _loc23_:LOL_MutilTextFieldIcon = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getLanguageStr(98214),GlobalData.$userData.mark,"UI_money_mark_0_0000");
         _loc23_.name = "_mark_txt_";
         if(MainConfig.$isEA)
         {
            _loc23_.fontSize = 18;
         }
         _loc23_.x = MainConfig.$isEA ? _loc16_.x - 28 : _loc16_.x + 5;
         _loc23_.y = _loc16_.y + _loc16_.height;
         param1.addChild(_loc23_);
         _coinT = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getLanguageStr(90671),GlobalData.$userData.coin,"UI_money_coin_0_0000");
         _coinT.name = "_coin_txt_";
         if(MainConfig.$isEA)
         {
            _coinT.fontSize = 17;
         }
         _coinT.x = MainConfig.$isEA ? _loc23_.x + 275 : _loc23_.x + 250;
         _coinT.y = _loc23_.y;
         param1.addChild(_coinT);
         var _loc18_:Number = _loc16_.x + 10;
         var _loc21_:Number = _loc16_.y + 5;
         var _loc12_:int = 0;
         var _loc8_:int = 4;
         if(_loc15_ != null)
         {
            _loc7_ = new Equip(_loc17_,_loc15_);
            _loc3_ = _loc7_.getWashMark();
            _loc5_ = _loc7_.getWashCoin();
         }
         if(mCurr_eid == "")
         {
            _loc3_ = 0;
            _loc5_ = 0;
         }
         var _loc14_:String = " " + GlobalLanguageStr.getLanguageStr(20272);
         var _loc13_:String = " " + GlobalLanguageStr.getLanguageStr(20149);
         var _loc22_:Array = [_loc3_ + _loc14_ + GlobalLanguageStr.getLanguageStr(90563),_loc5_ + _loc13_ + GlobalLanguageStr.getLanguageStr(90563),_loc3_ * 10 + _loc14_ + GlobalLanguageStr.getLanguageStr(90564),_loc5_ * 10 + _loc13_ + GlobalLanguageStr.getLanguageStr(90564)];
         mArr_priceData = null;
         mArr_priceData = [{
            "type":"mark",
            "num":1
         },{
            "type":"coin",
            "num":1
         },{
            "type":"mark",
            "num":10
         },{
            "type":"coin",
            "num":10
         }];
         mArr_price = [];
         _loc12_ = 0;
         while(_loc12_ < _loc8_)
         {
            _loc11_ = new LOL_Button(_loc22_[_loc12_],"UI_equip_radio_0_0001",true);
            _loc11_.fontSize = MainConfig.$isEA ? 19 : 19;
            _loc11_.fontColor = 16777215;
            _loc11_._text.hAlign = "center";
            _loc11_._text.x = 10;
            _loc11_._text.y = -3;
            _loc11_.shadowFilter();
            _loc11_.name = _loc12_.toString();
            _loc11_.shadowFilter();
            _loc4_ = _loc11_.textBounds;
            _loc4_.x = 30;
            _loc11_.x = _loc18_ + _loc12_ % 2 * (490 - _loc11_.width - 20);
            _loc11_.y = _loc21_ + Math.floor(_loc12_ / 2) * (_loc11_.height + 5) + 20;
            param1.addChild(_loc11_);
            _loc11_.addEventListener("triggered",onTRIGGERED_radio);
            mArr_price.push(_loc11_);
            _loc12_++;
         }
         var _loc6_:int = 0;
         if(mCurr_selectPrice)
         {
            _loc19_ = {
               "mark1":0,
               "coin1":1,
               "mark10":2,
               "coin10":3
            };
            _loc6_ = int(_loc19_[mCurr_selectPrice.type + mCurr_selectPrice.num]);
            selectRadio(_loc6_);
         }
         if(GlobalFunction.checkIsSale("equip_fun_wash"))
         {
            _loc9_ = GlobalFunction.createImage("UI_sale_bg_2_0000");
            _loc9_.x = _loc16_.x + _loc16_.width - _loc9_.width - 8;
            _loc9_.y = _loc16_.y - _loc9_.height - 3;
            param1.addChild(_loc9_);
         }
      }
      
      private function onTRIGGERED_radio(param1:Event) : void
      {
         var _loc2_:int = int((param1.currentTarget as LOL_Button).name);
         selectRadio(_loc2_,true);
      }
      
      private function checkIsPay() : Boolean
      {
         var _loc1_:Object = null;
         var _loc3_:Equip = null;
         var _loc2_:int = 0;
         var _loc4_:Boolean = true;
         if(GlobalData.$userData.attrs.equip_wash != null)
         {
            GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(10061));
         }
         else if(mCurr_eid != "")
         {
            if(mCurr_selectPrice != null)
            {
               _loc1_ = GlobalData.$userData.my_equips[mCurr_eid];
               _loc3_ = new Equip(mCurr_eid,_loc1_);
               if(mCurr_selectPrice.type == "mark")
               {
                  if(GlobalData.$userData.mark < _loc3_.getWashMark(-1,mCurr_selectPrice.num))
                  {
                     GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90080));
                     _loc4_ = false;
                  }
               }
               else if(mCurr_selectPrice.type == "coin")
               {
                  _loc2_ = _loc3_.getWashCoin(-1,mCurr_selectPrice.num);
                  if(GlobalData.$userData.coin < _loc2_)
                  {
                     GlobalFunction.popErrorCoin(_loc2_);
                     _loc4_ = false;
                  }
               }
            }
            else
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90082));
            }
         }
         return _loc4_;
      }
      
      private function selectRadio(param1:int, param2:Boolean = false) : void
      {
         var _loc6_:LOL_Button = null;
         if(mCurr_eid == "")
         {
            return;
         }
         if(GlobalData.$userData.attrs.equip_wash != null && param2)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90113));
            return;
         }
         var _loc3_:Object = mCurr_selectPrice;
         mCurr_selectPrice = mArr_priceData[param1];
         var _loc5_:Boolean = checkIsPay();
         if(!_loc5_)
         {
            mCurr_selectPrice = _loc3_;
            return;
         }
         if(param2)
         {
            checkBtns();
         }
         var _loc7_:int = 0;
         var _loc4_:int = int(mArr_price.length);
         _loc7_ = 0;
         while(_loc7_ < _loc4_)
         {
            _loc6_ = mArr_price[_loc7_] as LOL_Button;
            _loc6_.texture = GlobalFunction.getTexture("UI_equip_radio_0_0001");
            _loc7_++;
         }
         _loc6_ = mArr_price[param1] as LOL_Button;
         _loc6_.texture = GlobalFunction.getTexture("UI_equip_radio_0_0000");
         checkGuide();
      }
      
      private function setAttUIs(param1:Sprite, param2:Number, param3:Boolean = false) : void
      {
         if(param3)
         {
            StarlingTools.removeChildrenClear(param1);
            var bg:Scale9Image = GlobalFunction.createScale9Image("UI_bg_9slice_7_0000",490,140,new Rectangle(25,25,15,15));
            param1.addChild(bg);
            param2 = bg.width;
         }
         var eqid:String = mCurr_eid;
         var item:Object = GlobalData.$userData.my_equips[eqid];
         if(item == null)
         {
            return;
         }
         var equip:Equip = new Equip(eqid,item);
         var pending:Object = GlobalData.$userData.attrs.equip_wash;
         var changes:Object = pending != null && pending.eqid == eqid ? pending.rolled : null;
         var keys:Array = ["hit","flee","crit","tough"];
         var labels:Array = [30021,30022,30023,30024];
         // The wash API exchanges persisted new_4attrs counters. Equip.getHit/
         // Flee/Crit/Tough add the per-level allocation (getPoint), which made
         // the wash ledger show effective combat totals instead of the stored
         // values changed by this preview. Keep the allocation out of this
         // ledger; it remains part of combat stats and getPoteNow below.
         var raw:Object = item.new_4attrs is Object ? item.new_4attrs : item;
         var values:Array = [int(raw.hit || 0),int(raw.flee || 0),int(raw.crit || 0),int(raw.tough || 0)];
         var remaining:int = equip.getPoteNow(equip.lv);
         var added:int = 0;
         for(var i:int = 0; i < keys.length; i++)
         {
            var key:String = keys[i];
            var delta:int = 0;
            if(changes != null && !isNaN(changes[key]))
            {
               delta = int(changes[key]);
            }
            var currentValue:int = int(values[i]);
            var resultValue:int = currentValue + delta;
            added += delta;
            var valueText:String = GlobalLanguageStr.getLanguageStr(labels[i]) + "：" + currentValue;
            var color:uint = 16777215;
            if(changes != null)
            {
               valueText += " -> " + resultValue + " (" + (delta > 0 ? "+" : "") + delta + ")";
               color = delta > 0 ? 52275 : (delta < 0 ? 16711680 : 16777215);
            }
            var field:TextField = GlobalTextStyle.getTextField(valueText,17,color,"left",210,27);
            field.touchable = false;
            field.x = 25 + (i % 2) * 230;
            field.y = 24 + int(i / 2) * 34;
            param1.addChild(field);
         }
         if(changes != null)
         {
            remaining = Math.max(0,remaining - added);
         }
         var potential:TextField = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(98161) + "：" + remaining,17,16777215,"left",440,25);
         potential.touchable = false;
         potential.x = 25;
         potential.y = 94;
         param1.addChild(potential);
      }
   }
}

