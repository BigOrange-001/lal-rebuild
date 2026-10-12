package com.meng52.game.ui.panel
{
   import com.adobe.text.NativeText;
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelBase;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.TextInput;
   import feathers.display.Scale9Image;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import starling.core.Starling;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class PanelMail extends PanelBase
   {
      
      public static const TYPE_MAIL_SEND:String = "type_mail_send";
      
      public static const TYPE_MAIL_GET:String = "type_mail_get";
      
      public static const TYPE_RADIO_SEND:String = "type_radio_send";
      
      public static const BTN_NAME_SEND:String = "Btn_name_send";
      
      public static const BTN_NAME_CANCEL:String = "Btn_name_cancel";
      
      public static const BTN_NAME_DEL:String = "Btn_name_del";
      
      public static const BTN_NAME_RE:String = "Btn_name_re";
      
      public static const BTN_NAME_CLOSE:String = "Btn_name_close";
      
      public static var mType:String = "";
      
      public static var mCfg:Object;
      
      private var mTxt_input:TextInput;
      
      public var nt:NativeText;
      
      public function PanelMail()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         var _loc10_:String = null;
         this.removeEventListener("addedToStage",initializeHandler);
         this.setPopInforBg(GlobalLanguageStr.getLanguageStr(20049),505,306);
         var _loc3_:Sprite = new Sprite();
         this.addChild(_loc3_);
         var _loc12_:Scale9Image = GlobalFunction.createScale9Image("UI_bg_9slice_6_0000",430,140,new Rectangle(20,20,20,20));
         _loc12_.x = mImg9_baseBg.x + (mImg9_baseBg.width - _loc12_.width) * 0.5;
         _loc12_.y = 70;
         _loc3_.addChild(_loc12_);
         var _loc2_:Number = mImg9_baseBg.width - 20;
         if(mType == "type_mail_send")
         {
            _loc10_ = GlobalLanguageStr.getLanguageStr(20175);
         }
         else if(mType == "type_mail_get")
         {
            _loc10_ = GlobalLanguageStr.getLanguageStr(20174);
         }
         else if(mType == "type_radio_send")
         {
            _loc10_ = GlobalLanguageStr.getLanguageStr(20380,GlobalData.$mConfig_simple.radio[2]);
         }
         var _loc13_:TextField = GlobalTextStyle.getTextField(_loc10_ + mCfg.name,20,4926491,"left",_loc2_,35,GlobalConfig.FONT_1);
         _loc3_.addChild(_loc13_);
         _loc13_.x = _loc12_.x;
         _loc13_.y = 30;
         _loc3_.x = 0;
         _loc3_.y = 0;
         var _loc11_:Number = _loc12_.width - 10;
         var _loc6_:Number = mImg9_baseBg.height - 30 - 150;
         var _loc9_:Number = Starling.contentScaleFactor;
         var _loc8_:Number = Starling.current.nativeStage.stageWidth - Starling.current.viewPort.width >> 1;
         this.nt = null;
         this.nt = new NativeText(5);
         this.nt.autoCorrect = true;
         this.nt.textAlign = "left";
         this.nt.fontSize = 20 * GlobalData.$mStage$Starling_h;
         this.nt.maxChars = 130;
         this.nt.color = 0;
         this.nt.fontFamily = GlobalConfig.FONT_1;
         this.nt.text = "";
         this.nt.width = int(_loc11_ * _loc9_);
         this.nt.height = int(_loc6_ * GlobalData.$mStage$Starling_h);
         var _loc7_:Point = new Point(_loc12_.x + 10,_loc12_.y);
         _loc7_ = _loc3_.localToGlobal(_loc7_);
         this.nt.x = int(_loc7_.x * _loc9_ + _loc8_);
         this.nt.y = int((GlobalData.$mStageHeight - _loc12_.height) * 0.5 * GlobalData.$mStage$Starling_h);
         GlobalData.$mStarling.nativeStage.addChild(this.nt);
         var _loc5_:LOL_Scale9Button = new LOL_Scale9Button("",125,45,"UI_btn_enterGame_0_0000");
         _loc5_.name = "Btn_name_del";
         var _loc4_:LOL_Scale9Button = new LOL_Scale9Button("",125,45,"UI_btn_enterGame_0_0000");
         _loc4_.name = "Btn_name_re";
         if(mType == "type_mail_send")
         {
            _loc4_.name = "Btn_name_send";
            _loc4_.text = GlobalLanguageStr.getLanguageStr(20140);
            _loc4_.x = mImg9_baseBg.x + (mImg9_baseBg.width - _loc4_.width) * 0.5;
            _loc4_.y = _loc5_.y + 225;
         }
         else if(mType == "type_mail_get")
         {
            _loc5_.text = GlobalLanguageStr.getLanguageStr(20143);
            _loc4_.text = GlobalLanguageStr.getLanguageStr(20144);
            this.nt.text = mCfg.content;
            this.nt.editable = false;
            _loc4_.x = mImg9_baseBg.x + (mImg9_baseBg.width - _loc4_.width - 70) * 1;
            _loc4_.y = _loc5_.y + 225;
            _loc5_.x = mImg9_baseBg.x + (mImg9_baseBg.width - _loc4_.width - 320) * 1;
            _loc5_.y += 225;
            _loc3_.addChild(_loc5_);
         }
         else if(mType == "type_radio_send")
         {
            _loc4_.name = "Btn_name_send";
            _loc4_.text = GlobalLanguageStr.getLanguageStr(20140);
            _loc4_.x = mImg9_baseBg.x + (mImg9_baseBg.width - _loc4_.width) * 0.5;
            _loc4_.y = _loc5_.y + 225;
         }
         _loc3_.addChild(_loc4_);
         _loc5_.addEventListener("triggered",this.onTRIGGERED_btn);
         _loc4_.addEventListener("triggered",this.onTRIGGERED_btn);
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         StarlingTools.removeChildrenClear(this);
         if(this.nt)
         {
            GlobalData.$mStarling.nativeStage.removeChild(this.nt);
         }
      }
      
      private function onTRIGGERED_btn(param1:Event) : void
      {
         var _msg:String;
         var str:Number;
         var _event:Event = param1;
         var _name:String = (_event.currentTarget as LOL_Scale9Button).name;
         if(_name == "Btn_name_send")
         {
            if(mType == "type_radio_send")
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(95019),true);
               return;
            }
            if(this.nt.text != "" || this.nt.text.length > 0)
            {
               if(mType == "type_mail_send")
               {
                  SendServiceAMFFun.send_user_send_msg(reSendMsg,{
                     "ruid":mCfg.uid,
                     "content":this.nt.text
                  });
                  GlobalFunction.delMail();
               }
               else if(mType == "type_radio_send")
               {
                  _msg = this.nt.text;
                  str = _msg.charCodeAt(0);
                  if(str > 127 && _msg.length <= 1)
                  {
                     _msg = _msg + " ";
                  }
                  if(Tools.hasText(_msg,Tools.BAN_LIST.concat(Tools.BAN_LIST2)))
                  {
                     GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90122),true);
                  }
                  else if(Tools.getCharLength(_msg) > 48)
                  {
                     GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(20381),true);
                  }
                  else
                  {
                     if(/^\S+$/.test(_msg) == false)
                     {
                        if(!MainConfig.$isEnglish)
                        {
                           GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90123),true);
                           return;
                        }
                        if(MainConfig.$isEA)
                        {
                           GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90123),true);
                           return;
                        }
                     }
                     if(GlobalData.$userData.coin < GlobalData.$mConfig_simple.radio[2])
                     {
                        this.onCLOSE_PANEL_SELF(null);
                        GlobalFunction.popErrorCoin(GlobalData.$mConfig_simple.radio[2],null);
                     }
                     else
                     {
                        if(!MainConfig.$isEnglish)
                        {
                           _msg = _msg.replace(" ","");
                           _msg = _msg.replace("\r"," ");
                        }
                        else
                        {
                           _msg = _msg.replace("\r"," ");
                        }
                        SendServiceAMFFun.send_user_send_radio(reSendRadio,{"msg":_msg});
                        GlobalFunction.delMail();
                     }
                  }
               }
            }
            else
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90048),true);
            }
         }
         else if(_name == "Btn_name_cancel")
         {
            GlobalFunction.delMail();
         }
         else if(_name == "Btn_name_del")
         {
            SendServiceAMFFun.send_user_del_msg(this.reDelMsg,{
               "mnum":mCfg.num,
               "uid":mCfg.uid,
               "content":mCfg.content
            });
         }
         else if(_name == "Btn_name_re")
         {
            GlobalData.$mGameClassObject.closePopForPanel(-1,function():void
            {
               GlobalFunction.setMail("type_mail_send",{
                  "uid":mCfg.uid,
                  "name":mCfg.name
               });
            });
         }
         else if(_name == "Btn_name_close")
         {
            GlobalFunction.delMail();
         }
      }
      
      private function reSendMsg(param1:Object) : void
      {
         if(this.nt)
         {
            this.nt.text = "";
         }
         GlobalData.$mGameClassObject.closePopForPanel();
         GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90054));
      }
      
      private function reSendRadio(param1:Object) : void
      {
         GlobalData.$mGameClassObject.closePopForPanel();
         GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90130));
         var _loc2_:String = GlobalLanguageStr.getLanguageStr("bugle",{
            "vip_lv":GlobalData.$userData.vip_lv,
            "uname":GlobalData.$userData.name,
            "msg":param1.params.msg
         });
         GlobalFunction.radioPanel.insertStr(_loc2_);
         GlobalFunction.payCoinVip(GlobalData.$mConfig_simple.radio[2]);
      }
      
      private function reDelMsg(param1:Object) : void
      {
         GlobalFunction.delMail();
         GlobalData.$mGameClassObject.closePopForPanel();
         GlobalData.$mEventDispatcher.dispatchEventWith("update_social_mail");
      }
   }
}

