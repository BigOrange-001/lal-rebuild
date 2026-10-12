package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.talent.Talent;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelCenterMainAvatar;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.net.SendAndSelect;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.events.TimerEvent;
   import flash.geom.Rectangle;
   import flash.utils.Timer;
   import flash.utils.getTimer;
   import starling.animation.Juggler;
   import starling.animation.Tween;
   import starling.core.Starling;
   import starling.display.DisplayObject;
   import starling.display.Image;
   import starling.display.MovieClip;
   import starling.display.Quad;
   import starling.display.Shape;
   import starling.display.Sprite;
   import starling.events.EnterFrameEvent;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   import starling.textures.Texture;
   
   public class PanelAvatarTalentAvatar extends PanelCenterMainAvatar
   {
      
      private static const BTN_START:String = "btn_start";
      
      private static const BTN_SAVE:String = "btn_save";
      
      private static const BTN_CANCEL:String = "btn_cancel";
      
      private static const BTN_STOP:String = "btn_stop";
      
      private static const ICON_TALENT:String = "icon_talent";
      
      private var data:Object;
      
      private var txtName:TextField;
      
      private var txtLv:TextField;
      
      private var mBg_list:Scale9Image;
      
      private var mBg_list2:Scale9Image;
      
      private var mBg_list3:Scale9Image;
      
      private var avatarObj:Object;
      
      private var btn_Radio:LOL_Button;
      
      private var talten_Icon:LOL_MutilTextFieldIcon;
      
      private var btn_Start:LOL_Scale9Button;
      
      private var mBtn_save:LOL_Scale9Button;
      
      private var mBtn_cancel:LOL_Scale9Button;
      
      private var arr1:Array;
      
      private var index:int = -1;
      
      private var _index:int = 1;
      
      private var tween_ItemBox:Tween;
      
      private var tween_ItemBox_1:Tween;
      
      private var container:Shape;
      
      private var parentContainer:Sprite;
      
      private var selectCase:Scale9Image;
      
      private var arrItem:Array;
      
      private var item:Sprite;
      
      private var obj:Object;
      
      private var onj_1:Object;
      
      private var talent:Talent;
      
      private var id:String;
      
      private var av_Id:String;
      
      private var skillName:TextField;
      
      private var skillLv:TextField;
      
      private var skillInfo:TextField;
      
      private var ar:Array = [];
      
      private var _timer:Timer;
      
      private var _delay:int = 5000;
      
      private var _timeTemp:int = 0;
      
      private var _timeAll:int = 0;
      
      private var xx:int = 0;
      
      private var tfBg:Image;
      
      private var tfName:TextField;
      
      private var tfmsg:TextField;
      
      private var mTalent:String;
      
      private var ic:LOL_MutilTextFieldIcon;
      
      private var Cursor_Left:LOL_MutilTextFieldIcon;
      
      private var Cursor_Right:LOL_MutilTextFieldIcon;
      
      private var _sp:Sprite;
      
      private var mc:MovieClip;
      
      private var mCurrentId:String = "";

      private var mReceiptViewEpoch:uint = 0;

      private var mReceiptOperation:uint = 0;

      
      private var mAvatar:Avatar;
      
      private var mTalent_1:Talent;
      
      private var avatar:Sprite;
      
      private var ta_Lv:String;
      
      private var talentSp:Sprite;
      
      private var talentQuad:Quad;
      
      private var talentQuad1:Quad;
      
      private var btn1:LOL_Scale9Button;
      
      private var booo:Boolean = false;
      
      private var mBox_top:Sprite;
      
      private var _attrs:*;
      
      private var _attrs1:*;
      
      private var _attrs2:*;
      
      private var tween:Tween;
      
      private var box1:Sprite;
      
      private var box:Sprite;
      
      private var box2:Sprite;
      
      private var btn:LOL_Button;
      
      private var ziCotainer:Sprite;
      
      private var allItemNum:uint;
      
      private var arr_A:Array = [];
      
      private var arr_New:Array = [];
      
      private var ziCotainer_1:Sprite;
      
      private var ziCotainer_2:Sprite;
      
      private var obj_ta:Object;
      
      private var arr_1:Array;
      
      private var obj1:Object;
      
      public function PanelAvatarTalentAvatar(param1:Object)
      {
         data = param1;
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         mReceiptViewEpoch++;
         this.removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getStr(98006),960);
         initUI();
      }
      
      private function initUI() : void
      {
         var _loc2_:String = null;
         var _loc4_:* = 0;
         mCurrentId = data.aid;
         mAvatar = new Avatar(mCurrentId);
         var _loc3_:String = mCurrentId.split("|")[0];
         avatar = mAvatar.getAvatarRes();
         addChild(avatar);
         avatar.touchable = false;
         avatar.y = 90;
         avatar.x = 50;
         txtName = GlobalTextStyle.getTextField(mAvatar.avatarData.name,21,16777215,"left",300,35);
         txtName.x = avatar.x + avatar.width + 10;
         txtName.y = avatar.y + avatar.height / 2 - txtName.height;
         this.addChild(txtName);
         txtLv = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20079,mAvatar.lv),21,16777215,"left",300,35);
         txtLv.x = avatar.x + avatar.width + 10;
         txtLv.y = avatar.y + avatar.height / 2;
         this.addChild(txtLv);
         setChengeUI();
         mBg_list = GlobalFunction.createScale9Image("UI_Auras_lottery_bg_0_0000",615,355,new Rectangle(30,30,58,30));
         mBg_list.x = int((GlobalData.$mStageWidth - mBg_list.width) * 0.5);
         mBg_list.y = avatar.y + avatar.height + 5;
         addChild(mBg_list);
         mBg_list2 = GlobalFunction.createScale9Image("UI_guildShop_bg_2_0000",600,200,new Rectangle(30,30,58,30));
         mBg_list2.x = int((GlobalData.$mStageWidth - mBg_list2.width) * 0.5);
         mBg_list2.y = mBg_list.y + mBg_list.height + 5;
         addChild(mBg_list2);
         mBg_list3 = GlobalFunction.createScale9Image("UI_guildShop_bg_2_0000",600,100,new Rectangle(30,30,58,30));
         mBg_list3.x = int((GlobalData.$mStageWidth - mBg_list3.width) * 0.5);
         mBg_list3.y = mBg_list2.y + mBg_list2.height;
         addChild(mBg_list3);
         btn_Start = new LOL_Scale9Button("",150,60,"UI_btn_guild_2_red_0000");
         btn_Start.fontSize = 25;
         btn_Start.fontColor = 16777215;
         btn_Start.name = "btn_start";
         btn_Start.text = GlobalLanguageStr.getLanguageStr(98045);
         btn_Start.x = int((GlobalData.$mStageWidth - btn_Start.width) * 0.5);
         btn_Start.y = mBg_list3.y + mBg_list3.height;
         addChild(btn_Start);
         this.btn_Start.addEventListener("triggered",onTRIGGERED_btn);
         mBtn_save = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20271),150,60,"UI_btn_guild_2_red_0000");
         mBtn_save.name = "btn_save";
         mBtn_save.fontColor = 16777215;
         mBtn_save.x = 390;
         mBtn_save.y = btn_Start.y;
         mBtn_save.addEventListener("triggered",this.onTRIGGERED_btn);
         mBtn_cancel = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20270),150,60,"UI_btn_guild_2_red_0000");
         mBtn_cancel.name = "btn_cancel";
         mBtn_cancel.fontColor = 16777215;
         mBtn_cancel.x = 100;
         mBtn_cancel.y = btn_Start.y;
         mBtn_cancel.addEventListener("triggered",this.onTRIGGERED_btn);
         if(data["talent"])
         {
            mAvatar = new Avatar(mCurrentId);
            avatar = mAvatar.getAvatarRes();
            talentSp = new Sprite();
            talentSp.x = 345;
            talentSp.y = 110;
            this.addChild(talentSp);
            talentSp.addChild(Talent.getImage(mAvatar.talent.id));
            talentQuad = Tools.newQuad(talentSp.width,talentSp.height,talentSp.x,talentSp.y,0);
            talentQuad.alpha = 0;
            this.addChild(talentQuad);
            talentQuad.addEventListener("touch",talentTouch);
            skillName = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(98046) + mAvatar.talent.my_HaloData.name,21,16777215,"left",300,35);
            skillName.x = 410;
            skillName.y = talentSp.y + (talentSp.height - skillName.height) * 0.5;
            addChild(skillName);
         }
         setLs();
         setTo();
         add_Cursor();
         var _loc5_:Object = GlobalData.$userData.attrs.sp;
         var _loc1_:Array = GlobalData.$mConfig_simple.talent_config;
         if(xx >= _loc5_.length || _loc5_[xx] < _loc1_[xx])
         {
            btn_Start.enabled = false;
         }
         mTalent = GlobalData.$userData.attrs.avatar_talent;
         if(mTalent != null)
         {
            GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(10504));
            if(mBg_list)
            {
               mBg_list.removeFromParent(true);
               mBg_list.dispose();
            }
            if(Cursor_Left)
            {
               Cursor_Left.removeFromParent(true);
               Cursor_Left.dispose();
            }
            if(Cursor_Right)
            {
               Cursor_Right.removeFromParent(true);
               Cursor_Right.dispose();
            }
            if(mc)
            {
               removeEventListener("enterFrame",onENTER_FRAME_clip);
               mc.removeFromParent(true);
               mc.dispose();
            }
            if(parentContainer)
            {
               parentContainer.removeFromParent(true);
               parentContainer.dispose();
            }
            parentContainer = null;
            mc = null;
            Cursor_Right = null;
            Cursor_Left = null;
            mBg_list = null;
            setChengeUI();
            tweenRemove();
            _loc2_ = (GlobalData.$userData.attrs.avatar_talent as String).split("`")[1];
            _loc4_ = 0;
            while(_loc4_ < arr_New.length)
            {
               if(_loc2_ == arr_New[_loc4_].id)
               {
                  ziCotainer.y = -item.height * (_loc4_ - 2);
               }
               _loc4_++;
            }
            mBg_list = GlobalFunction.createScale9Image("UI_Auras_lottery_bg_0_0000",615,355,new Rectangle(30,30,58,30));
            mBg_list.x = int((GlobalData.$mStageWidth - mBg_list.width) * 0.5);
            mBg_list.y = 90 + avatar.height + 5;
            addChild(mBg_list);
            add_Cursor();
            index = xx;
            _loc4_ = 0;
            while(_loc4_ < arr1.length)
            {
               (arr1[_loc4_] as LOL_Button).touchable = false;
               _loc4_++;
            }
            btn_Start.visible = false;
            btn_Start.enabled = false;
            addChild(mBtn_save);
            addChild(mBtn_cancel);
            mBtn_save.name = "btn_save";
            mBtn_cancel.name = "btn_cancel";
            mBtn_save.visible = true;
            mBtn_cancel.visible = true;
            mBtn_save.enabled = true;
            mBtn_cancel.enabled = true;
         }
      }
      
      private function talentTouch(param1:TouchEvent) : void
      {
         var _loc4_:Talent = null;
         var _loc5_:String = null;
         var _loc2_:String = null;
         var _loc3_:Touch = param1.getTouch(this);
         if(_loc3_ && _loc3_.phase == "ended")
         {
            if(mAvatar && mAvatar.talent != null)
            {
               _loc4_ = new Talent(mAvatar.talent.id);
            }
            _loc5_ = _loc4_.my_HaloData.name;
            _loc2_ = _loc4_.my_HaloData.info + "\n" + GlobalLanguageStr.getLanguageStr(98041) + "\n";
            _loc2_ = Tools.formatLineX(_loc2_,GlobalTextStyle.COLOR_W_R_R_R);
            GlobalFunction.popAlert(_loc5_,_loc2_,{"res":mAvatar.resId});
         }
      }
      
      private function add_Cursor() : void
      {
         Cursor_Left = new LOL_MutilTextFieldIcon("","","UI_Auras_lottery_arrow_0_0000");
         Cursor_Left.x = mBg_list.x + 68;
         Cursor_Left.y = mBg_list.y + (mBg_list.height - Cursor_Left.height) * 0.5 + 25;
         addChild(Cursor_Left);
         Cursor_Right = new LOL_MutilTextFieldIcon("","","UI_Auras_lottery_arrow_0_0000");
         Cursor_Right.scaleX = -1;
         Cursor_Right.x = 549;
         Cursor_Right.y = Cursor_Left.y;
         addChild(Cursor_Right);
      }
      
      private function checkBtns() : void
      {
         var _loc1_:Boolean = false;
         btn_Start.enabled = _loc1_;
      }
      
      private function onTRIGGERED_btn(param1:Event) : void
      {
         var talentData:Object;
         var talentNum:Array;
         var oldTalentIndex:int;
         var _fun:Object;
         var str:String;
         var go_Start:*;
         var e:Event = param1;
         btn1 = e.currentTarget as LOL_Scale9Button;
         if(index == -1)
         {
            GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(98047));
            return;
         }
         if(btn1.name == "btn_start")
         {
            index = xx;
            talentData = GlobalData.$userData.attrs.sp[xx];
            talentNum = GlobalData.$mConfig_simple.talent_config;
            if(xx >= GlobalData.$userData.attrs.sp.length || talentData < talentNum[xx])
            {
               GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(10503));
               return;
            }
            if(GlobalData.$userData.avatars[data.aid].talent != null)
            {
               go_Start = sendTalentStart;
               oldTalentIndex = getTalentOptionIndex(GlobalData.$userData.avatars[data.aid].talent as String);
               if(oldTalentIndex >= 0 && xx < oldTalentIndex)
               {
                  _fun = {
                     "ok":go_Start,
                     "no":GlobalFunction.functionNull,
                     "aid":"A_2009_5"
                  };
                  str = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(98043),GlobalTextStyle.COLOR_W_Y_Y_G);
                  GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(90010),str,_fun);
                  return;
               }
            }
            sendTalentStart();
            if(booo == false)
            {
               booo = true;
               GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(98049));
            }
         }
         else if(btn1.name == "btn_stop")
         {
            if(btn1.enabled)
            {
               btn1.enabled = false;
               click_Stop();
            }
         }
         else if(btn1.name == "btn_cancel")
         {
            if(btn1.enabled)
            {
               sendTalentSave(false);
            }
         }
         else if(btn1.name == "btn_save")
         {
            if(btn1.enabled)
            {
               sendTalentSave(true);
            }
         }
      }

      private function sendTalentStart() : void
      {
         if(stage == null || mCurrentId == "" || SendAndSelect.checkRepeat("user.get_avatar_talent",""))
         {
            return;
         }
         mReceiptOperation++;
         var _op:uint = mReceiptOperation;
         var _epoch:uint = mReceiptViewEpoch;
         var _aid:String = mCurrentId;
         var _spIndex:int = xx;
         SendServiceAMFFun.send_user_get_avatar_talent(function(param1:Object):void
         {
            onReFun_Start(param1,_op,_epoch,_aid,_spIndex);
         },{"aid":_aid,"sp_index":_spIndex});
      }

      private function sendTalentSave(param1:Boolean) : void
      {
         if(stage == null || mCurrentId == "" || SendAndSelect.checkRepeat("user.save_talent",""))
         {
            return;
         }
         mReceiptOperation++;
         var _op:uint = mReceiptOperation;
         var _epoch:uint = mReceiptViewEpoch;
         var _aid:String = mCurrentId;
         var _spIndex:int = xx;
         var _callback:Function = param1 ? onReFun_Save : onReFun_Cancel;
         SendServiceAMFFun.send_user_save_talent(function(param2:Object):void
         {
            _callback(param2,_op,_epoch,_aid,_spIndex);
         },param1 ? {"is_save":true} : {});
      }
      
      private function click_Stop() : void
      {
         var _talen_id:String;
         var num:Number;
         var i:uint;
         var over_1:* = function():void
         {
            btn_Start.name = "btn_stop";
            btn_Start.text = GlobalLanguageStr.getLanguageStr(90472);
            btn_Start.visible = false;
            addChild(mBtn_save);
            addChild(mBtn_cancel);
            mBtn_save.name = "btn_save";
            mBtn_cancel.name = "btn_cancel";
            mBtn_save.visible = true;
            mBtn_cancel.visible = true;
            mBtn_save.enabled = true;
            mBtn_cancel.enabled = true;
            mBtn_close.touchable = true;
         };
         if(ziCotainer)
         {
            ziCotainer.removeFromParent(true);
            ziCotainer.dispose();
         }
         if(mBg_list)
         {
            mBg_list.removeFromParent(true);
            mBg_list.dispose();
         }
         if(Cursor_Left)
         {
            Cursor_Left.removeFromParent(true);
            Cursor_Left.dispose();
         }
         if(Cursor_Right)
         {
            Cursor_Right.removeFromParent(true);
            Cursor_Right.dispose();
         }
         if(mc)
         {
            removeEventListener("enterFrame",onENTER_FRAME_clip);
            mc.removeFromParent(true);
            mc.dispose();
         }
         if(box)
         {
            box.removeFromParent(true);
            box.dispose();
         }
         if(box2)
         {
            box2.removeFromParent(true);
            box2.dispose();
         }
         box2 = null;
         box = null;
         ziCotainer = null;
         mc = null;
         Cursor_Right = null;
         Cursor_Left = null;
         mBg_list = null;
         setChengeUI();
         tweenRemove();
         _talen_id = (GlobalData.$userData.attrs.avatar_talent as String).split("`")[1];
         i = 0;
         while(i < arr_New.length)
         {
            if(_talen_id == arr_New[i].id)
            {
               ziCotainer.y = -item.height * (i - 2) + 500;
               num = -item.height * (i - 2);
            }
            i = i + 1;
         }
         tween_ItemBox = new Tween(ziCotainer,2,"easeOutBack");
         tween_ItemBox.animate("scaleX",1);
         tween_ItemBox.animate("scaleY",1);
         tween_ItemBox.animate("y",num);
         tween_ItemBox.repeatCount = 1;
         tween_ItemBox.onUpdate = onListen1;
         tween_ItemBox.onComplete = over_1;
         Starling.juggler.add(tween_ItemBox);
         mBg_list = GlobalFunction.createScale9Image("UI_Auras_lottery_bg_0_0000",615,355,new Rectangle(30,30,58,30));
         mBg_list.x = int((GlobalData.$mStageWidth - mBg_list.width) * 0.5);
         mBg_list.y = 90 + avatar.height + 5;
         addChild(mBg_list);
         add_Cursor();
         clearTimer();
      }
      
      private function onListen1() : void
      {
         if(ziCotainer.y <= -(ziCotainer.height / 2))
         {
            ziCotainer_1.y = ziCotainer.y + ziCotainer.height;
         }
         else
         {
            ziCotainer_1.y = ziCotainer.y - ziCotainer.height;
         }
      }
      
      private function onReFun_Cancel(param1:Object, param2:uint, param3:uint, param4:String, param5:int) : void
      {
         if(GlobalFunction.isMalformedProfileReceipt(param1))
         {
            return;
         }
         if(GlobalFunction.isLegacyProfileReceipt(param1))
         {
            RpcStaticCall.$remoting.reportDiagnostic("PROFILE_RECEIPT_LEGACY|method=user.save_talent");
         }
         if(param2 != mReceiptOperation || param3 != mReceiptViewEpoch || param4 != mCurrentId || param4 != data.aid || param5 != xx || stage == null)
         {
            return;
         }
         var _loc3_:* = 0;
         btn_Start.visible = true;
         var _loc4_:Object = GlobalData.$userData.attrs.sp;
         var _loc2_:Array = GlobalData.$mConfig_simple.talent_config;
         if(xx >= _loc4_.length || _loc4_[xx] < _loc2_[xx])
         {
            btn_Start.enabled = false;
         }
         else
         {
            btn_Start.enabled = true;
         }
         btn_Start.text = GlobalLanguageStr.getLanguageStr(98045);
         btn_Start.name = "btn_start";
         btn_Start.touchable = true;
         mBtn_save.visible = false;
         mBtn_cancel.visible = false;
         _loc3_ = 0;
         while(_loc3_ < arr1.length)
         {
            (arr1[_loc3_] as LOL_Button).touchable = true;
            _loc3_++;
         }
      }
      
      private function onReFun_Save(param1:Object, param2:uint, param3:uint, param4:String, param5:int) : void
      {
         if(GlobalFunction.isMalformedProfileReceipt(param1))
         {
            return;
         }
         if(GlobalFunction.isLegacyProfileReceipt(param1))
         {
            RpcStaticCall.$remoting.reportDiagnostic("PROFILE_RECEIPT_LEGACY|method=user.save_talent");
         }
         if(param2 != mReceiptOperation || param3 != mReceiptViewEpoch || param4 != mCurrentId || param4 != data.aid || param5 != xx || stage == null)
         {
            return;
         }
         var _loc4_:* = 0;
         this.setEffects();
         _loc4_ = 0;
         while(_loc4_ < arr1.length)
         {
            (arr1[_loc4_] as LOL_Button).touchable = true;
            _loc4_++;
         }
         addChild(btn_Start);
         btn_Start.text = GlobalLanguageStr.getLanguageStr(98045);
         btn_Start.name = "btn_start";
         btn_Start.visible = true;
         var _loc3_:Object = GlobalData.$userData.attrs.sp;
         var _loc2_:Array = GlobalData.$mConfig_simple.talent_config;
         if(xx >= _loc3_.length || _loc3_[xx] < _loc2_[xx])
         {
            btn_Start.enabled = false;
         }
         else
         {
            btn_Start.enabled = true;
         }
         btn_Start.touchable = true;
         mBtn_save.visible = false;
         mBtn_cancel.visible = false;
         GlobalData.$mEventDispatcher.dispatchEventWith("uptata_avatar_talent_info");
      }
      
      private function talentTouch1(param1:TouchEvent) : void
      {
         var _loc4_:Object = null;
         var _loc5_:Talent = null;
         var _loc6_:String = null;
         var _loc2_:String = null;
         var _loc3_:Touch = param1.getTouch(this);
         if(_loc3_ && _loc3_.phase == "ended")
         {
            _loc4_ = GlobalData.$userData.avatars[data.aid];
            if(_loc4_ && _loc4_.talent != null)
            {
               _loc5_ = new Talent(_loc4_.talent);
            }
            _loc6_ = _loc5_.my_HaloData.name;
            _loc2_ = _loc5_.my_HaloData.info + "\n" + GlobalLanguageStr.getLanguageStr(98041) + "\n";
            _loc2_ = Tools.formatLineX(_loc2_,GlobalTextStyle.COLOR_W_R_R_R);
            GlobalFunction.popAlert(_loc6_,_loc2_,{"res":mAvatar.resId});
         }
      }
      
      private function setEffects() : void
      {
         var _loc2_:Sprite = new Sprite();
         this.addChild(_loc2_);
         _attrs1 = {
            "id":"e003",
            "x":175,
            "y":385,
            "sc":1,
            "a":0.7
         };
         _attrs1.par = _loc2_;
         var _loc1_:DisplayObject = DisplayTools.addEffectOne(_attrs1);
         _loc1_.blendMode = Tools.getBlendMode(null,0.8,0.8,1);
         this.setJuggler();
         _attrs = _attrs = {
            "id":"e506",
            "x":0,
            "y":0,
            "sc":1
         };
         _attrs.par = this.mJugglerBox;
         DisplayTools.addEffectOne(_attrs);
         this.setChildIndex(mJugglerBox,this.numChildren - 1);
         this.mJugglerBox.x = 135;
         this.mJugglerBox.y = 430;
         tween = new Tween(mJugglerBox,0.3);
         tween.animate("x",375);
         tween.animate("y",140);
         tween.scaleTo(2);
         tween.onComplete = over_Com;
         tween.repeatCount = 1;
         mJuggler.add(tween);
      }
      
      private function over_Com() : void
      {
         if(mJugglerBox)
         {
            mJugglerBox.removeFromParent(true);
            mJugglerBox.dispose();
         }
         if(tween)
         {
            mJuggler.remove(tween);
         }
         if(skillName)
         {
            skillName.removeFromParent(true);
            skillName.dispose();
         }
         if(skillLv)
         {
            skillLv.removeFromParent(true);
            skillLv.dispose();
         }
         if(talentSp)
         {
            talentSp.removeFromParent(true);
            talentSp.dispose();
         }
         skillName = null;
         skillLv = null;
         talentSp = null;
         mJugglerBox = null;
         tween = null;
         talentSp = new Sprite();
         talentSp.x = 345;
         talentSp.y = 110;
         this.addChild(talentSp);
         talentSp.addChild(Talent.getImage(GlobalData.$userData.avatars[data.aid].talent));
         talentQuad1 = Tools.newQuad(talentSp.width,talentSp.height,talentSp.x,talentSp.y,0);
         talentQuad1.alpha = 0;
         this.addChild(talentQuad1);
         talentQuad1.addEventListener("touch",talentTouch1);
         id = GlobalData.$userData.avatars[data.aid].talent;
         talent = new Talent(id);
         skillName = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(98046) + talent.my_HaloData.name,21,16777215,"left",300,35);
         skillName.x = 410;
         skillName.y = talentSp.y + (talentSp.height - skillName.height) * 0.5;
         addChild(skillName);
         SoundManager.getOnlyExample().playSound("skill1");
         box1 = new Sprite();
         this.addChild(box1);
         _attrs2 = {
            "id":"e008",
            "x":375,
            "y":140,
            "sc":1
         };
         _attrs2.par = box1;
         var _loc1_:DisplayObject = DisplayTools.addEffectOne(_attrs2);
         _loc1_.blendMode = Tools.getBlendMode(null,0.8,0.8,1);
      }
      
      private function onReFun_Start(param1:Object, param2:uint, param3:uint, param4:String, param5:int) : void
      {
         if(GlobalFunction.isMalformedProfileReceipt(param1))
         {
            return;
         }
         if(GlobalFunction.isLegacyProfileReceipt(param1))
         {
            RpcStaticCall.$remoting.reportDiagnostic("PROFILE_RECEIPT_LEGACY|method=user.get_avatar_talent");
         }
         if(param2 != mReceiptOperation || param3 != mReceiptViewEpoch || param4 != mCurrentId || param4 != data.aid || param5 != xx || stage == null)
         {
            return;
         }
         var i:uint;
         var _textures:Vector.<Texture>;
         var _sp1:Sprite;
         var tween_Cursor_Left:Tween;
         var dis1:DisplayObject;
         var _sp2:Sprite;
         var tween_Cursor_Right:Tween;
         var dis2:DisplayObject;
         var re:Object = param1;
         var over:* = function():void
         {
            var _loc1_:Tween = null;
            if(_loc1_)
            {
               Starling.juggler.remove(_loc1_);
            }
            _loc1_ = null;
            _loc1_ = new Tween(_sp1,0.1);
            _loc1_.animate("rotation",-0.08726646259971647);
            _loc1_.repeatCount = 0;
            Starling.juggler.add(_loc1_);
         };
         var over1:* = function():void
         {
            if(tween_Cursor_Right)
            {
               Starling.juggler.remove(tween_Cursor_Right);
            }
            tween_Cursor_Right = null;
            var _loc1_:Tween = new Tween(_sp2,0.1);
            _loc1_.animate("rotation",0.08726646259971647);
            _loc1_.repeatCount = 0;
            Starling.juggler.add(_loc1_);
         };
         if(booo == false)
         {
            booo = true;
            GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(98049));
         }
         getNewData();
         tweenRemove();
         if(tfBg)
         {
            tfBg.removeFromParent(true);
            tfBg.dispose();
         }
         if(tfName)
         {
            tfName.removeFromParent(true);
            tfName.dispose();
         }
         if(tfName)
         {
            tfmsg.removeFromParent(true);
            tfmsg.dispose();
         }
         if(ziCotainer)
         {
            ziCotainer.removeFromParent(true);
            ziCotainer.dispose();
         }
         if(item)
         {
            item.removeFromParent(true);
            item.dispose();
         }
         if(parentContainer)
         {
            parentContainer.removeFromParent(true);
            parentContainer.dispose();
         }
         if(mBg_list)
         {
            mBg_list.removeFromParent(true);
            mBg_list.dispose();
         }
         if(Cursor_Left)
         {
            Cursor_Left.removeFromParent(true);
            Cursor_Left.dispose();
         }
         if(Cursor_Right)
         {
            Cursor_Right.removeFromParent(true);
            Cursor_Right.dispose();
         }
         if(box1)
         {
            box1.removeFromParent(true);
            box1.dispose();
         }
         if(tween)
         {
            mJuggler.remove(tween);
         }
         if(mJugglerBox)
         {
            mJugglerBox.removeFromParent(true);
            mJugglerBox.dispose();
         }
         mJugglerBox = null;
         tween = null;
         box1 = null;
         Cursor_Right = null;
         Cursor_Left = null;
         mBg_list = null;
         parentContainer = null;
         tfBg = null;
         tfName = null;
         tfmsg = null;
         ziCotainer = null;
         item = null;
         i = 0;
         while(i < arr1.length)
         {
            (arr1[i] as LOL_Button).touchable = false;
            i = i + 1;
         }
         _textures = new Vector.<Texture>();
         _textures[0] = GlobalFunction.getTextureByBD("Talent_clip2");
         _textures[1] = GlobalFunction.getTextureByBD("Talent_clip1");
         _sp = new Sprite();
         addChild(_sp);
         mc = new MovieClip(_textures,12);
         mc.loop = true;
         mc.play();
         mJuggler = new Juggler();
         mc.x = 126;
         mc.y = 225;
         mJuggler.add(mc);
         _sp.addChild(mc);
         addEventListener("enterFrame",onENTER_FRAME_clip);
         mBg_list = GlobalFunction.createScale9Image("UI_Auras_lottery_bg_0_0000",615,355,new Rectangle(30,30,58,30));
         mBg_list.x = int((GlobalData.$mStageWidth - mBg_list.width) * 0.5);
         mBg_list.y = 90 + avatar.height + 5;
         addChild(mBg_list);
         mBtn_close.touchable = false;
         _sp1 = new Sprite();
         addChild(_sp1);
         Cursor_Left = new LOL_MutilTextFieldIcon("","","UI_Auras_lottery_arrow_0_0000");
         _sp1.addChild(Cursor_Left);
         Cursor_Left.y = -10;
         Cursor_Left.x = -5;
         _sp1.x = mBg_list.x + 68 + 8;
         _sp1.y = mBg_list.y + (mBg_list.height - Cursor_Left.height) * 0.5 + 25 + 15;
         tween_Cursor_Left = new Tween(_sp1,0.3);
         tween_Cursor_Left.animate("rotation",-0.22689280275926285);
         tween_Cursor_Left.onComplete = over;
         Starling.juggler.add(tween_Cursor_Left);
         box = new Sprite();
         this.addChild(box);
         _attrs = {
            "id":"e506",
            "x":123,
            "y":390,
            "sc":1.4,
            "a":0.3
         };
         _attrs.par = box;
         dis1 = DisplayTools.addEffectOne(_attrs);
         dis1.blendMode = Tools.getBlendMode(null,0.8,0.9,1);
         _sp2 = new Sprite();
         addChild(_sp2);
         Cursor_Right = new LOL_MutilTextFieldIcon("","","UI_Auras_lottery_arrow_0_0000");
         Cursor_Right.scaleX = -1;
         _sp2.addChild(Cursor_Right);
         Cursor_Right.y = -10;
         Cursor_Right.x = 5;
         _sp2.x = 541;
         _sp2.y = _sp1.y;
         tween_Cursor_Right = new Tween(_sp2,0.3);
         tween_Cursor_Right.animate("rotation",0.22689280275926285);
         tween_Cursor_Right.onComplete = over1;
         Starling.juggler.add(tween_Cursor_Right);
         box2 = new Sprite();
         this.addChild(box2);
         _attrs = {
            "id":"e506",
            "x":512,
            "y":390,
            "sc":1.4,
            "a":0.3
         };
         _attrs.par = box2;
         dis2 = DisplayTools.addEffectOne(_attrs);
         dis1.blendMode = Tools.getBlendMode(null,0.8,0.9,1);
         _timeTemp = getTimer();
         _timer = new Timer(_delay,5);
         _timer.addEventListener("timer",time_Tick);
         _timer.start();
         btn_Start.text = GlobalLanguageStr.getLanguageStr(90472);
         btn_Start.name = "btn_stop";
         btn_Start.visible = true;
         btn_Start.enabled = true;
      }
      
      private function onENTER_FRAME_clip(param1:EnterFrameEvent) : void
      {
         if(mJuggler)
         {
            mJuggler.advanceTime(param1.passedTime);
         }
      }
      
      private function time_Tick(param1:TimerEvent) : void
      {
         var _loc2_:int = getTimer();
         _timeAll += _loc2_ - _timeTemp;
         if(_timeAll / 1000 >= 5)
         {
            GlobalData.$mGameClassObject.closePopUp();
            btn_Start.text = GlobalLanguageStr.getLanguageStr(90472);
            btn_Start.name = "btn_stop";
            btn_Start.touchable = false;
            btn_Start.enabled = false;
            click_Stop();
         }
      }
      
      private function clearTimer() : void
      {
         if(_timer)
         {
            _timer.stop();
            _timer.removeEventListener("timer",time_Tick);
            _timer = null;
         }
      }
      
      private function setLs() : void
      {
         var _loc5_:* = 0;
         var _loc3_:Object = null;
         var _loc4_:String = null;
         var _loc2_:Array = [];
         var _loc1_:Array = GlobalData.$mConfig_simple.talent_config;
         _loc5_ = 0;
         while(_loc5_ < _loc1_.length)
         {
            _loc3_ = {};
            _loc3_.name = GlobalLanguageStr.getLanguageStr(98048,_loc1_[_loc5_]);
            _loc3_.num = _loc1_[_loc5_];
            _loc2_.push(_loc3_);
            _loc5_++;
         }
         arr1 = [];
         _loc5_ = 0;
         while(_loc5_ < _loc2_.length)
         {
            btn_Radio = new LOL_Button("       " + _loc2_[_loc5_].name,"UI_equip_radio_0_0001",true);
            if(_loc5_ == 0 && !mTalent)
            {
               btn_Radio.texture = GlobalFunction.getTexture("UI_equip_radio_0_0000");
               index = 0;
            }
            btn_Radio.fontSize = MainConfig.$isEA ? 23 : 24;
            btn_Radio.name = _loc5_ + "";
            btn_Radio.fontColor = 16777215;
            // All six native talent grades remain selectable. The current
            // SP balance is checked when the player starts a roll.
            btn_Radio.x = mBg_list2.x + 20 + (_loc5_ % 2 ? GlobalData.$mStageWidth / 2 : 0);
            btn_Radio.y = mBg_list2.y + 30 + int(_loc5_ / 2) * 55;
            this.addChild(btn_Radio);
            btn_Radio.addEventListener("triggered",onTRIGGERED_radio);
            talten_Icon = new LOL_MutilTextFieldIcon("","","UI_soulStone_icon_0_000" + _loc5_);
            talten_Icon.scaleX = talten_Icon.scaleY = 0.7;
            talten_Icon.x = btn_Radio.x + 12;
            talten_Icon.y = btn_Radio.y + 17;
            addChild(talten_Icon);
            arr1.push(btn_Radio);
            _loc5_++;
         }
         if(mTalent != null)
         {
            _loc4_ = getTalentOptionIndex(mTalent);
            if(_loc4_ >= 0 && _loc4_ < arr1.length)
            {
               xx = int(_loc4_);
               arr1[xx].texture = GlobalFunction.getTexture("UI_equip_radio_0_0000");
               index = xx;
            }
         }
      }
      
      private function onTRIGGERED_radio(param1:Event) : void
      {
         var _loc4_:* = 0;
         var selectedSP:Array = GlobalData.$userData.attrs.sp as Array;
         var requestedIndex:int = int((param1.currentTarget as LOL_Button).name);
         if(selectedSP == null || requestedIndex < 0 || requestedIndex >= selectedSP.length)
         {
            return;
         }
         tweenRemove();
         btn = param1.currentTarget as LOL_Button;
         index = btn.name as int;
         onj_1 = {};
         onj_1.name = btn.name + "";
         xx = onj_1.name;
         _loc4_ = 0;
         while(_loc4_ < arr1.length)
         {
            arr1[_loc4_].texture = GlobalFunction.getTexture("UI_equip_radio_0_0001");
            if(tfBg)
            {
               tfBg.removeFromParent(true);
               tfBg.dispose();
            }
            if(tfName)
            {
               tfName.removeFromParent(true);
               tfName.dispose();
            }
            if(tfmsg)
            {
               tfmsg.removeFromParent(true);
               tfmsg.dispose();
            }
            if(item)
            {
               item.removeFromParent(true);
               item.dispose();
            }
            if(parentContainer)
            {
               parentContainer.removeFromParent(true);
               parentContainer.dispose();
            }
            tfBg = null;
            tfName = null;
            tfmsg = null;
            item = null;
            parentContainer = null;
            setChengeUI();
            if(mBg_list)
            {
               mBg_list.removeFromParent(true);
               mBg_list.dispose();
            }
            if(Cursor_Left)
            {
               Cursor_Left.removeFromParent(true);
               Cursor_Left.dispose();
            }
            if(Cursor_Right)
            {
               Cursor_Right.removeFromParent(true);
               Cursor_Right.dispose();
            }
            mBg_list = null;
            Cursor_Left = null;
            Cursor_Right = null;
            mBg_list = GlobalFunction.createScale9Image("UI_Auras_lottery_bg_0_0000",615,355,new Rectangle(30,30,58,30));
            mBg_list.x = int((GlobalData.$mStageWidth - mBg_list.width) * 0.5);
            mBg_list.y = 90 + avatar.height + 5;
            addChild(mBg_list);
            add_Cursor();
            _loc4_++;
         }
         btn.texture = GlobalFunction.getTexture("UI_equip_radio_0_0000");
         if(btn != null)
         {
            btn_Start.enabled = true;
         }
         var _loc3_:Object = GlobalData.$userData.attrs.sp;
         var _loc2_:Array = GlobalData.$mConfig_simple.talent_config;
         if(xx >= _loc3_.length || _loc3_[xx] < _loc2_[xx])
         {
            btn_Start.enabled = false;
         }
      }
      
      private function setChengeUI() : void
      {
         var _loc7_:String = null;
         var _loc3_:Boolean = false;
         var _loc9_:int = 0;
         var _loc2_:Object = null;
         var _loc6_:* = 0;
         tweenRemove();
         arr_A = [];
         arr_New = [];
         mTalent = GlobalData.$userData.attrs.avatar_talent;
         if(mTalent != null)
         {
            xx = getTalentOptionIndex(mTalent);
            if(xx < 0 || xx > 5)
            {
               xx = 0;
            }
         }
         var _loc1_:Object = GlobalData.$mConfig_talent;
         var _loc8_:Array = [];
         for(var _loc4_:String in _loc1_)
         {
            arr_1 = _loc4_.split("_");
            if(arr_1[2] == xx + 2)
            {
               obj1 = {};
               if(MainConfig.$gameLanguage == "tw")
               {
                  obj1.info = _loc1_[_loc4_].info_tw;
                  obj1.name = _loc1_[_loc4_].name_tw;
               }
               else
               {
                  obj1.info = _loc1_[_loc4_].info;
                  obj1.name = _loc1_[_loc4_].name;
               }
               obj1.id = _loc4_;
               _loc8_.push(obj1);
            }
         }
         if(mTalent != null)
         {
            _loc7_ = (GlobalData.$userData.attrs.avatar_talent as String).split("`")[1];
         }
         // The original panel expects ten choices, but this reconstructed
         // talent table has only four unique options at each rank. Never ask
         // getRandomNumber() for more entries than exist: its native helper
         // removes entries without replacement and would return undefined.
         var _loc5_:Array = GlobalFunction.getRandomNumber(_loc8_.length,Math.min(10,_loc8_.length));
         _loc9_ = 0;
         while(_loc9_ < _loc5_.length)
         {
            arr_New[_loc9_] = _loc8_[_loc5_[_loc9_]];
            if(_loc7_)
            {
               if(_loc7_ == _loc8_[_loc5_[_loc9_]].id)
               {
                  _loc3_ = true;
                  _loc2_ = _loc8_[_loc5_[_loc9_]];
                  _loc6_ = uint(_loc9_);
               }
            }
            _loc9_++;
         }
         if(_loc3_)
         {
            arr_New.splice(_loc6_,1);
            if(arr_New.length > 5)
            {
               arr_New[5] = _loc2_;
            }
            else
            {
               arr_New.push(_loc2_);
            }
         }
         if(_loc3_ == false && _loc7_)
         {
            _loc9_ = 0;
            while(_loc9_ < _loc8_.length)
            {
               if(_loc7_ == _loc8_[_loc9_].id)
               {
                  if(arr_New.length > 5)
                  {
                     arr_New[5] = _loc8_[_loc9_];
                  }
                  else
                  {
                     arr_New.push(_loc8_[_loc9_]);
                  }
               }
               _loc9_++;
            }
         }
         arr_A = arr_New;
         arrItem = [];
         parentContainer = new Sprite();
         ziCotainer = new Sprite();
         ziCotainer_1 = new Sprite();
         ziCotainer_2 = new Sprite();
         allItemNum = arr_A.length;
         _loc9_ = 0;
         while(_loc9_ < arr_New.length)
         {
            item = new Sprite();
            tfBg = GlobalFunction.createImage("UI_Auras_lottery_bar_0_0000");
            tfBg.height = 65;
            item.addChild(tfBg);
            tfName = GlobalTextStyle.getTextField(arr_New[_loc9_].name,19,16777215,"left",300,35);
            tfName.x = 23;
            tfName.y = tfBg.height / 2 - tfName.height / 2;
            item.addChild(tfName);
            tfmsg = GlobalTextStyle.getTextField(arr_New[_loc9_].info,19,16777215,"left",300,35);
            tfmsg.x = 105;
            tfmsg.y = tfBg.height / 2 - tfmsg.height / 2;
            item.addChild(tfmsg);
            item.x = 126;
            item.y = item.height * _loc9_;
            arrItem.push(item);
            ziCotainer.addChild(item);
            _loc9_++;
         }
         _loc9_ = 0;
         while(_loc9_ < arr_New.length)
         {
            item = new Sprite();
            tfBg = GlobalFunction.createImage("UI_Auras_lottery_bar_0_0000");
            tfBg.height = 65;
            item.addChild(tfBg);
            tfName = GlobalTextStyle.getTextField(arr_New[_loc9_].name,19,16777215,"left",300,35);
            tfName.x = 23;
            tfName.y = tfBg.height / 2 - tfName.height / 2;
            item.addChild(tfName);
            tfmsg = GlobalTextStyle.getTextField(arr_New[_loc9_].info,19,16777215,"left",300,35);
            tfmsg.x = 105;
            tfmsg.y = tfBg.height / 2 - tfmsg.height / 2;
            item.addChild(tfmsg);
            item.x = 126;
            item.y = item.height * _loc9_;
            arrItem.push(item);
            ziCotainer_1.addChild(item);
            _loc9_++;
         }
         parentContainer.addChild(ziCotainer);
         parentContainer.addChild(ziCotainer_1);
         ziCotainer_1.y = ziCotainer.y + ziCotainer.height;
         addChild(parentContainer);
         parentContainer.y = 225;
         parentContainer.clipRect = new Rectangle(126,0,item.width,item.height * 5);
         if(!mTalent)
         {
            tween_ItemBox = new Tween(ziCotainer,allItemNum / 2);
            tween_ItemBox.animate("y",-(item.height * arr_New.length));
            tween_ItemBox.onUpdate = onListen;
            Starling.juggler.add(tween_ItemBox);
            tween_ItemBox.repeatCount = 0;
         }
      }

      // Talent IDs use the T_branch_rank format.
      // and expose rank in cfg.talent. Original five-field IDs store the
      // option rank at field 4. Both are mapped onto the six UI choices, whose
      // native minimum is rank 2; legacy rank 1 remains usable as choice 0.
      private function getTalentOptionIndex(value:String) : int
      {
         var talentId:String = value;
         var separator:int = talentId.lastIndexOf("`");
         var row:Object = null;
         var rank:Number = NaN;
         var parts:Array = null;
         var optionIndex:int = -1;
         if(separator >= 0)
         {
            talentId = talentId.substr(separator + 1);
         }
         if(GlobalData.$mConfig_talent != null)
         {
            row = GlobalData.$mConfig_talent[talentId];
         }
         if(row != null && row.hasOwnProperty("rank"))
         {
            rank = Number(row.rank);
         }
         if(isNaN(rank))
         {
            parts = talentId.split("_");
            if(parts.length >= 5)
            {
               rank = Number(parts[4]);
            }
            else if(parts.length >= 3)
            {
               rank = Number(parts[2]);
            }
         }
         if(isNaN(rank) || !isFinite(rank))
         {
            return -1;
         }
         optionIndex = int(rank) - 2;
         if(optionIndex < 0)
         {
            return 0;
         }
         if(optionIndex > 5)
         {
            return 5;
         }
         return optionIndex;
      }
      
      private function onListen() : void
      {
         ziCotainer_1.y = ziCotainer.y + ziCotainer.height;
      }
      
      private function setTo() : void
      {
         var _loc2_:* = 0;
         var _loc1_:Array = GlobalData.$userData.attrs.sp;
         _loc2_ = 0;
         while(_loc2_ < _loc1_.length)
         {
            obj = {};
            obj.num = _loc1_[_loc2_];
            ic = new LOL_MutilTextFieldIcon("",obj.num,"UI_soulStone_icon_0_000" + _loc2_);
            ic.x = mBg_list3.x + 10 + (_loc2_ % 3 * GlobalData.$mStageWidth / 3 - 10);
            ic.y = mBg_list3.y + 10 + int(_loc2_ / 3) * 40;
            ic._mIcon.scaleX = ic._mIcon.scaleY = 0.7;
            ic._mIcon.x = 25;
            ic._mIcon.y = 3;
            this.addChild(ic);
            ar.push(ic);
            _loc2_++;
         }
      }
      
      private function getNewData() : void
      {
         var _loc1_:* = 0;
         _loc1_ = 0;
         while(_loc1_ < ar.length)
         {
            ar[_loc1_].txt2 = GlobalData.$userData.attrs.sp[_loc1_];
            ar[_loc1_]._mIcon.scaleX = ar[_loc1_]._mIcon.scaleY = 0.7;
            ar[_loc1_]._mIcon.x = 25;
            ar[_loc1_]._mIcon.y = 3;
            _loc1_++;
         }
      }
      
      private function tweenRemove() : void
      {
         if(tween_ItemBox)
         {
            Starling.juggler.remove(tween_ItemBox);
         }
         tween_ItemBox = null;
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         mReceiptViewEpoch++;
         mReceiptOperation++;
         if(txtName)
         {
            txtName.removeFromParent(true);
            txtName.dispose();
         }
         if(txtLv)
         {
            txtLv.removeFromParent(true);
            txtLv.dispose();
         }
         if(mBg_list)
         {
            mBg_list.removeFromParent(true);
            mBg_list.dispose();
         }
         if(mBg_list2)
         {
            mBg_list2.removeFromParent(true);
            mBg_list2.dispose();
         }
         if(mBg_list3)
         {
            mBg_list3.removeFromParent(true);
            mBg_list3.dispose();
         }
         if(btn_Radio)
         {
            btn_Radio.removeEventListener("triggered",onTRIGGERED_radio);
            btn_Radio.removeFromParent(true);
            btn_Radio.dispose();
         }
         if(btn_Start)
         {
            this.btn_Start.removeEventListener("triggered",onTRIGGERED_btn);
            btn_Start.removeFromParent(true);
            btn_Start.dispose();
         }
         if(mBtn_save)
         {
            mBtn_save.removeEventListener("triggered",this.onTRIGGERED_btn);
            mBtn_save.removeFromParent(true);
            mBtn_save.dispose();
         }
         if(mBtn_cancel)
         {
            mBtn_cancel.removeEventListener("triggered",this.onTRIGGERED_btn);
            mBtn_cancel.removeFromParent(true);
            mBtn_cancel.dispose();
         }
         if(selectCase)
         {
            selectCase.removeFromParent(true);
            selectCase.dispose();
         }
         if(talten_Icon)
         {
            talten_Icon.removeFromParent(true);
            talten_Icon.dispose();
         }
         if(tween_ItemBox)
         {
            Starling.juggler.remove(tween_ItemBox);
         }
         if(parentContainer)
         {
            parentContainer.removeFromParent(true);
            parentContainer.dispose();
         }
         if(item)
         {
            item.removeFromParent(true);
            item.dispose();
         }
         if(skillName)
         {
            skillName.removeFromParent(true);
            skillName.dispose();
         }
         if(skillLv)
         {
            skillLv.removeFromParent(true);
            skillLv.dispose();
         }
         if(skillInfo)
         {
            skillInfo.removeFromParent(true);
            skillInfo.dispose();
         }
         if(_timer)
         {
            _timer.stop();
            _timer.removeEventListener("timer",time_Tick);
         }
         if(tfBg)
         {
            tfBg.removeFromParent(true);
            tfBg.dispose();
         }
         if(tfName)
         {
            tfName.removeFromParent(true);
            tfName.dispose();
         }
         if(tfmsg)
         {
            tfmsg.removeFromParent(true);
            tfmsg.dispose();
         }
         if(ic)
         {
            ic.removeFromParent(true);
            ic.dispose();
         }
         if(Cursor_Left)
         {
            Cursor_Left.removeFromParent(true);
            Cursor_Left.dispose();
         }
         if(Cursor_Right)
         {
            Cursor_Right.removeFromParent(true);
            Cursor_Right.dispose();
         }
         if(_sp)
         {
            _sp.removeFromParent(true);
            _sp.dispose();
         }
         if(mJuggler)
         {
            mJuggler.remove(mc);
            mJuggler.purge();
         }
         if(mc)
         {
            mc.removeFromParent(true);
            mc.dispose();
         }
         if(avatar)
         {
            avatar.removeFromParent(true);
            avatar.dispose();
         }
         if(talentSp)
         {
            talentSp.removeFromParent(true);
            talentSp.dispose();
         }
         if(ziCotainer)
         {
            ziCotainer.removeFromParent(true);
            ziCotainer.dispose();
         }
         if(ziCotainer_1)
         {
            ziCotainer_1.removeFromParent(true);
            ziCotainer_1.dispose();
         }
         if(ziCotainer_2)
         {
            ziCotainer_2.removeFromParent(true);
            ziCotainer_2.dispose();
         }
         if(talentQuad)
         {
            talentQuad.removeEventListener("touch",talentTouch);
            talentQuad.removeFromParent(true);
            talentQuad.dispose();
         }
         if(talentQuad1)
         {
            talentQuad1.removeEventListener("touch",talentTouch1);
            talentQuad1.removeFromParent(true);
            talentQuad1.dispose();
         }
         if(tween)
         {
            mJuggler.remove(tween);
         }
         if(box1)
         {
            box1.removeFromParent(true);
            box1.dispose();
         }
         if(mJugglerBox)
         {
            mJugglerBox.removeFromParent(true);
            mJugglerBox.dispose();
         }
         mJugglerBox = null;
         box1 = null;
         tween = null;
         talentQuad1 = null;
         talentQuad = null;
         ziCotainer_2 = null;
         ziCotainer_1 = null;
         ziCotainer = null;
         talentSp = null;
         avatar = null;
         mc = null;
         _sp = null;
         Cursor_Right = null;
         Cursor_Left = null;
         ic = null;
         tfmsg = null;
         tfName = null;
         tfBg = null;
         _timer = null;
         skillInfo = null;
         skillLv = null;
         skillName = null;
         item = null;
         parentContainer = null;
         tween_ItemBox = null;
         talten_Icon = null;
         txtName = null;
         txtLv = null;
         mBg_list = null;
         mBg_list2 = null;
         mBg_list3 = null;
         btn_Radio = null;
         btn_Start = null;
         mBtn_save = null;
         mBtn_cancel = null;
         selectCase = null;
         tweenRemove();
         StarlingTools.removeChildrenClear(this);
         this.clear();
      }
   }
}

