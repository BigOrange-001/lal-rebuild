package com.meng52.game.ui.panel
{
   import com.adobe.text.NativeText;
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.ui.element.ItemSocialFriend;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.StarlingTools;
   import feathers.display.Scale3Image;
   import feathers.display.Scale9Image;
   import feathers.textures.Scale3Textures;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import starling.core.Starling;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class PanelSocialSearch extends PanelSocialFriend
   {
      
      public var mBox:Sprite;
      
      public var mTxt_uid:TextField;
      
      public var mTxt_info:TextField;
      
      public var nt:NativeText;
      
      public var mBtn_search:LOL_Scale9Button;
      
      public var mData:Object;
      
      public var m9x9_bg:Scale9Image;
      
      public var m9x9_txt:Scale3Image;
      
      public function PanelSocialSearch()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         this.setUIGroup();
         GlobalData.$mEventDispatcher.addEventListener("update_social_search_ok",this.onUPDATE_SOCIAL_SEARCH_OK);
         update();
      }
      
      public function setUIGroup() : void
      {
         this.mBox = new Sprite();
         m9x9_bg = GlobalFunction.getUI_BG_9SLICE_0();
         m9x9_bg.width = 508;
         m9x9_bg.height = 220;
         this.mBox.addChild(m9x9_bg);
         this.mBox.width = m9x9_bg.width;
         this.mBox.height = m9x9_bg.height;
         this.mBox.x = int((GlobalData.$mStageWidth - this.mBox.width) * 0.5);
         var _loc2_:Number = GlobalData.formatVScaleY_center(37.5);
         this.mBox.y = _loc2_;
         this.addChild(this.mBox);
         var _loc1_:Number = m9x9_bg.width;
         this.mTxt_uid = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20050,SendAndSelect.$uid),25,1513239,"center",_loc1_,35);
         this.mTxt_uid.x = 0;
         this.mTxt_uid.y = 25 - 3;
         this.mBox.addChild(this.mTxt_uid);
         this.mTxt_info = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20051),20,4926491,"center",_loc1_,35);
         this.mTxt_info.x = 0;
         this.mTxt_info.y = this.mTxt_uid.y + 35 - 1;
         this.mBox.addChild(this.mTxt_info);
         m9x9_txt = new Scale3Image(new Scale3Textures(GlobalFunction.getTexture("UI_bg_9slice_6_0000"),15,30));
         m9x9_txt.width = 352;
         m9x9_txt.height = 46;
         m9x9_txt.x = int((m9x9_bg.width - m9x9_txt.width) * 0.5);
         m9x9_txt.y = m9x9_bg.height - m9x9_txt.height - 30 - 52;
         this.mBox.addChild(m9x9_txt);
         this.mBtn_search = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20052),125,45,"UI_btn_enterGame_0_0000");
         this.mBtn_search.addEventListener("triggered",this.onTRIGGERED_search);
         this.mBtn_search.x = int((_loc1_ - this.mBtn_search.width) * 0.5);
         this.mBtn_search.y = m9x9_bg.height - 74;
         this.mBox.addChild(this.mBtn_search);
      }
      
      private function onUPDATE_SOCIAL_SEARCH_OK(param1:Event) : void
      {
         if(this.nt)
         {
            if(this.nt.parent)
            {
               this.nt.parent.removeChild(this.nt);
            }
         }
         this.update();
      }
      
      public function setInputText() : void
      {
         if(this.nt && this.nt.parent) this.nt.parent.removeChild(this.nt);
         this.nt = null;
         this.nt = new NativeText(1);
         this.nt.autoCorrect = true;
         this.nt.textAlign = "center";
         this.nt.fontSize = 25 * GlobalData.$mStage$Starling_h;
         this.nt.restrict = "0-9";
         this.nt.maxChars = 10;
         this.nt.color = 0;
         this.nt.fontFamily = GlobalConfig.FONT_1;
         this.nt.text = "";
         var inputPoint:Point = mBox.localToGlobal(new Point(m9x9_txt.x + 8,m9x9_txt.y + 6));
         var view:Rectangle = Starling.current.viewPort;
         var scaleX:Number = view.width / GlobalData.$mStageWidth;
         var scaleY:Number = view.height / GlobalData.$mStageHeight;
         this.nt.width = int((m9x9_txt.width - 16) * scaleX);
         this.nt.height = int((m9x9_txt.height - 12) * scaleY);
         this.nt.x = int(view.x + inputPoint.x * scaleX);
         this.nt.y = int(view.y + inputPoint.y * scaleY);
         GlobalData.$mStarling.nativeStage.addChild(this.nt);
      }
      
      override public function update() : void
      {
         this.mTxt_uid.text = GlobalLanguageStr.getLanguageStr(20050,SendAndSelect.$uid);
         this.setInputText();
         this.delList();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(this.nt)
         {
            if(this.nt.parent)
            {
               this.nt.parent.removeChild(this.nt);
            }
         }
         this.nt = null;
         if(m9x9_bg)
         {
            m9x9_bg.removeFromParent(true);
         }
         if(m9x9_txt)
         {
            m9x9_txt.removeFromParent(true);
         }
         if(mTxt_uid)
         {
            mTxt_uid.removeFromParent(true);
         }
         if(mTxt_info)
         {
            mTxt_info.removeFromParent(true);
         }
         if(mBtn_search)
         {
            mBtn_search.removeFromParent(true);
         }
         if(mBox)
         {
            StarlingTools.removeChildrenClear(mBox);
         }
         super.onREMOVED_FROM_STAGE(param1);
         GlobalData.$mEventDispatcher.removeEventListener("update_social_search_ok",this.onUPDATE_SOCIAL_SEARCH_OK);
         mTxt_uid = null;
         mTxt_info = null;
         mBtn_search = null;
         mBox = null;
         mData = null;
         mImgBg = null;
         m9x9_txt = null;
         m9x9_bg = null;
      }
      
      private function onTRIGGERED_search(param1:Event) : void
      {
         var _loc2_:String = this.nt.text;
         this.nt.text = "";
         if(_loc2_ != "" && _loc2_.length >= 8)
         {
            if(_loc2_ == SendAndSelect.$uid)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90050),true);
               return;
            }
            this.delList();
            SendServiceAMFFun.send_user_get(this.re_user_get,{"uid":_loc2_});
         }
         else
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90049),true);
         }
      }
      
      private function re_user_get(param1:Object) : void
      {
         if(param1.data)
         {
            if(param1.data.name != null)
            {
               this.mData = GlobalFunction.formateUserDataToFriend(param1.data);
               this.mData["current_rank"] = param1.data.records.current_rank;
               this.setList();
               this.addList();
            }
            else
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90037),true);
            }
         }
      }
      
      override public function setList() : void
      {
         super.setList();
      }
      
      override public function addList() : void
      {
         this.mData["status"] = "center_social_search";
         var _loc1_:Array = [this.mData];
         this.setListTimer(mList,_loc1_,ItemSocialFriend,false);
         this.mList.y = this.mBox.y + this.mBox.height + 15;
         _loc1_ = null;
      }
   }
}

