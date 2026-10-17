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
   import com.meng52.sound.SoundManager;
   import feathers.display.Scale3Image;
   import feathers.textures.Scale3Textures;
   import flash.geom.Point;
   import starling.display.Sprite;
   import starling.events.Event;
   
   public class PanelHelpAwardCode extends PanelSocialSearch
   {
      
      public function PanelHelpAwardCode()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(20218),350,600);
         this.setUIGroup();
      }
      
      override public function onBTN_NAME_BACK() : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_help");
      }
      
      override public function setUIGroup() : void
      {
         this.mBox = new Sprite();
         mBox.x = mImg9_baseBg.x;
         mBox.y = mImg9_baseBg.y + 110;
         mBox.width = mImg9_baseBg.width;
         this.addChild(this.mBox);
         var _loc1_:Number = mImg9_baseBg.width;
         this.mTxt_uid = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20219),30,16777215,"center",_loc1_,35);
         this.mTxt_uid.x = 0;
         this.mTxt_uid.y = 0;
         this.mBox.addChild(this.mTxt_uid);
         m9x9_txt = new Scale3Image(new Scale3Textures(GlobalFunction.getTexture("UI_bg_9slice_6_0000"),15,25));
         m9x9_txt.width = 352;
         m9x9_txt.height = 46.6;
         m9x9_txt.x = int(mImg9_baseBg.x + (mImg9_baseBg.width - m9x9_txt.width) * 0.5 - 17);
         m9x9_txt.y = mTxt_uid.y + 35 + 10;
         this.mBox.addChild(m9x9_txt);
         this.mBtn_search = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20459),150,70,"UI_btn_normalFun_0000");
         this.mBtn_search.addEventListener("triggered",this.onTRIGGERED_search);
         this.mBtn_search.x = int(mImg9_baseBg.x + (mImg9_baseBg.width - mBtn_search.width) * 0.5 - 20);
         this.mBtn_search.y = m9x9_txt.y + m9x9_txt.height + 15;
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
         this.nt.restrict = "[a-zA-Z0-9]";
         this.nt.maxChars = 20;
         this.nt.color = 0;
         this.nt.fontFamily = GlobalConfig.FONT_1;
         this.nt.text = "";
         this.nt.width = int(mImg9_baseBg.width * GlobalData.$mStage$Starling_w);
         this.nt.height = 46 * 4;
         var _loc1_:Point = new Point(mImg9_baseBg.x,mImg9_baseBg.y);
         this.nt.x = int(_loc1_.x * GlobalData.$mStage$Starling_w) + GlobalData.$isNotFullScreenX;
         this.nt.y = int(((GlobalData.$mStageHeight - mImg9_baseBg.height) * 0.5 + 163) * GlobalData.$mStage$Starling_h + GlobalData.$mStarling.viewPort.y);
         GlobalData.$mStarling.nativeStage.addChild(this.nt);
      }
      
      private function onTRIGGERED_search(param1:Event) : void
      {
         SendServiceAMFFun.send_user_get_reward_by_code(reCodeAward,{"code":this.nt.text});
         this.nt.text = "";
      }
      
      private function reCodeAward(param1:Object) : void
      {
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            return;
         }
         SoundManager.getOnlyExample().playSound("sound05");
         if(this.stage && this.nt)
         {
            this.nt.text = "";
         }







         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateAll();
         GlobalFunction.updateCoin();
         var _loc2_:Object = param1.data.rewards;
         GlobalFunction.showReward2({"info":param1.data.info},_loc2_);
      }
   }
}

