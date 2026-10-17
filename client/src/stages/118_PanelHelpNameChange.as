package com.meng52.game.ui.panel
{
   import com.adobe.text.NativeText;
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.net.SendServiceAMFFun;
   import feathers.display.Scale3Image;
   import feathers.textures.Scale3Textures;
   import starling.core.Starling;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class PanelHelpNameChange extends PanelSocialSearch
   {
      
      public function PanelHelpNameChange()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(20305),420,600);
         this.setUIGroup();
      }
      
      override public function setUIGroup() : void
      {
         this.mBox = new Sprite();
         mBox.x = mImg9_baseBg.x;
         mBox.y = mImg9_baseBg.y + 110;
         mBox.width = mImg9_baseBg.width;
         this.addChild(this.mBox);
         var _loc1_:Number = mImg9_baseBg.width;
         this.mTxt_uid = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90093),30,16777215,"center",_loc1_,35);
         this.mTxt_uid.x = 0;
         this.mTxt_uid.y = 1;
         this.mBox.addChild(this.mTxt_uid);
         var _loc2_:TextField = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90094,GlobalData.$mConfig_simple.rename),20,16764006,"center",_loc1_,29);
         _loc2_.y = mTxt_uid.y + 35;
         mBox.addChild(_loc2_);
         m9x9_txt = new Scale3Image(new Scale3Textures(GlobalFunction.getTexture("UI_bg_9slice_6_0000"),15,25));
         m9x9_txt.width = 352;
         m9x9_txt.height = 46.6;
         m9x9_txt.x = int(mImg9_baseBg.x + (mImg9_baseBg.width - m9x9_txt.width) * 0.5 - 15);
         m9x9_txt.y = _loc2_.y + 35 + 5;
         this.mBox.addChild(m9x9_txt);
         this.mBtn_search = new LOL_Scale9Button(GlobalLanguageStr.getStr(20021),150,70,"UI_btn_normalFun_0000");
         this.mBtn_search.addEventListener("triggered",this.onTRIGGERED_search);
         this.mBtn_search.x = int(mImg9_baseBg.x + (mImg9_baseBg.width - mBtn_search.width) * 0.5 - 15);
         this.mBtn_search.y = m9x9_txt.y + m9x9_txt.height + 30;
         this.mBox.addChild(this.mBtn_search);
         setInputText();
      }
      
      override public function setInputText() : void
      {
         this.nt = null;
         this.nt = new NativeText(1);
         this.nt.autoCorrect = true;
         this.nt.textAlign = "center";
         this.nt.fontSize = 25 * GlobalData.$mStage$Starling_h;
         this.nt.maxChars = 8;
         this.nt.color = 0;
         this.nt.fontFamily = GlobalConfig.FONT_1;
         this.nt.text = "";
         this.nt.width = Starling.current.viewPort.width;
         this.nt.height = 46 * 4;
         this.nt.x = Starling.current.viewPort.x;
         this.nt.y = int(((GlobalData.$mStageHeight - mImg9_baseBg.height) * 0.5 + 193) * GlobalData.$mStage$Starling_h + Starling.current.viewPort.y);
         GlobalData.$mStarling.nativeStage.addChild(this.nt);
      }
      
      private function onTRIGGERED_search(param1:Event) : void
      {
         var _loc4_:String = null;
         var _loc2_:String = null;
         var _loc3_:int = int(GlobalData.$mConfig_simple.rename);
         if(GlobalData.$userData.coin >= _loc3_)
         {
            if(this.nt && this.nt.text != "")
            {
               _loc4_ = GlobalFunction.checkName(this.nt.text);
               this.nt.visible = false;
               if(_loc4_)
               {
                  GlobalFunction.popError(_loc4_);
                  this.nt.visible = true;
                  this.nt.text = "";
               }
               else
               {
                  _loc2_ = this.nt.text;
                  _loc2_ = _loc2_.replace(" ","");
                  this.nt.text = _loc2_;
                  if(GlobalData.$userData.name == this.nt.text)
                  {
                     GlobalFunction.tipsOS_ios(GlobalLanguageStr.getLanguageStr(90010),GlobalLanguageStr.getLanguageStr(90288),GlobalLanguageStr.getLanguageStr(20021),checkNt,GlobalLanguageStr.getLanguageStr(20104),null,checkNt);
                  }
                  else
                  {
                     GlobalFunction.tipsOS_ios(GlobalLanguageStr.getLanguageStr(90010),GlobalLanguageStr.getLanguageStr(90107,_loc3_,this.nt.text),GlobalLanguageStr.getLanguageStr(20021),sendFun,GlobalLanguageStr.getLanguageStr(20104),checkNt,checkNt);
                  }
               }
            }
            else
            {
               this.nt.text = "";
               this.nt.visible = true;
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90011));
            }
         }
         else
         {
            this.nt.text = "";
            GlobalFunction.popErrorCoin(_loc3_);
         }
      }
      
      private function sendFun() : void
      {
         SendServiceAMFFun.send_user_change_name(re_name,{"name":this.nt.text});
         this.nt.visible = true;
         this.nt.text = "";
      }
      
      private function checkNt() : void
      {
         this.nt.visible = true;
      }
      
      private function re_name(param1:Object) : void
      {
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            return;
         }
         var _loc2_:Object = param1["params"];

         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateName();
         GlobalFunction.tipsOS_ios("",GlobalLanguageStr.getLanguageStr(90095,_loc2_.name));
         if(param1.data)
         {
            if(this.stage)
         {
            this.onCLOSE_PANEL_SELF();
         }
         }
      }
   }
}

