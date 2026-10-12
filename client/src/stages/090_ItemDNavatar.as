package com.meng52.game.ui.element
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.map.GameMapTools;
   import com.meng52.game.ui.panel.PanelDetailDN;
   import com.meng52.game.ui.screen.PanelCenterDNTeam;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.Tools;
   import flash.geom.Rectangle;
   import starling.display.Image;
   import starling.events.Event;
   
   public class ItemDNavatar extends ItemBase
   {
      
      private var mBg:Image;
      
      private var mImg_lock:Image;
      
      private var mTxt_name:LOL_TextField;
      
      private var mTxt_lv:LOL_TextField;
      
      private var mTxt_stone:LOL_TextField;
      
      private var mImg_status:Image;
      
      private var mTxt_status:LOL_TextField;
      
      private var mImg_tag:Image;
      
      private var _parent:PanelCenterDNTeam;
      
      public function ItemDNavatar(param1:PanelCenterDNTeam)
      {
         super();
         _parent = param1;
      }
      
      override public function layoutWH() : void
      {
         this.width = this.height = 104;
      }
      
      override public function init(param1:Object) : void
      {
         var _loc7_:* = 0;
         var _loc6_:* = 0;
         var _loc8_:Boolean = param1["dn_self"] == false;
         var _loc2_:Number = 100;
         var _loc3_:Array = param1["data_base"];
         var _loc4_:uint = param1["lock"] == 1 ? 1513239 : 16777215;
         this.x = param1.x;
         this.y = param1.y;
         if(param1["aid"] == null)
         {
            mBg = GlobalFunction.createImage("UI_dn_bg_0_0000");
            addChild(mBg);
            mTxt_name = new LOL_TextField(GlobalLanguageStr.getLanguageStr(_loc3_[0]),_loc2_,24);
            mTxt_name.fontSize = 15;
            mTxt_name.fontColor = _loc4_;
            mTxt_name.hAlign = "center";
            if(_loc4_ == 16777215)
            {
               mTxt_name.shadowFilter();
            }
            if(param1["lock"] == 1)
            {
               _loc7_ = uint(GlobalData.$userData.lv >= _loc3_[2] ? 65382 : 10027008);
               _loc6_ = uint(GlobalData.$userData.attrs.dn_stone >= _loc3_[3] ? 65382 : 10027008);
               mImg_lock = GlobalFunction.createImage("UI_dn_lock_0000");
               addChild(mImg_lock);
               mTxt_lv = new LOL_TextField(GlobalLanguageStr.getLanguageStr(25034,_loc3_[2]),_loc2_,24);
               mTxt_lv.fontColor = _loc7_;
               mTxt_lv.hAlign = "center";
               mTxt_lv.fontSize = 10;
               _loc7_ != 10027008 ? mTxt_lv.shadowFilter() : null;
               mTxt_lv.visible = !_loc8_;
               addChild(mTxt_lv);
               mTxt_stone = new LOL_TextField(GlobalLanguageStr.getLanguageStr(25035,_loc3_[3]),_loc2_,24);
               mTxt_stone.fontColor = _loc6_;
               mTxt_stone.fontSize = 10;
               mTxt_stone.hAlign = "center";
               _loc6_ != 10027008 ? mTxt_stone.shadowFilter() : null;
               mTxt_stone.visible = !_loc8_;
               addChild(mTxt_stone);
               if(!_loc8_)
               {
                  if(GlobalData.$userData.lv < _loc3_[2])
                  {
                     mTxt_stone.visible = false;
                  }
                  else
                  {
                     mTxt_lv.visible = false;
                  }
               }
               if(mBg)
               {
                  mImg_lock.x = int(mBg.x + (mBg.width - mImg_lock.width) * 0.5);
                  mImg_lock.y = int(mBg.y + (mBg.height - mImg_lock.height) * 0.5);
               }
               mTxt_name.x = int(mBg.x + (mBg.width - _loc2_) * 0.5);
               mTxt_name.y = 10;
               mTxt_lv.x = int(mBg.x + (mBg.width - _loc2_) * 0.5);
               mTxt_lv.y = 35;
               mTxt_stone.x = int(mBg.x + (mBg.width - _loc2_) * 0.5);
               mTxt_stone.y = 55;
               if(GlobalData.$userData.lv >= _loc3_[2] && GlobalData.$userData.attrs.dn_stone >= _loc3_[3])
               {
                  mImg_tag = GlobalFunction.createImage("UI_tag_warn_0_0000");
                  mImg_tag.x = -10;
                  mImg_tag.y = -10;
                  mImg_tag.touchable = false;
                  addChild(mImg_tag);
               }
            }
            else
            {
               mTxt_name.x = int(mBg.x + (mBg.width - _loc2_) * 0.5);
               mTxt_name.y = 40;
            }
            addChild(mTxt_name);
         }
         else
         {
            setAvatar(param1["aid"]);
            mAvatar.scaleX = mAvatar.scaleY = 0.9;
            addChild(mAvatar);
         }
         var _loc5_:Object = null;
         if(data["lock"] == 1)
         {
            _loc5_ = PanelDetailDN.getDNaddValue(data["indexID_s"],[1,null]);
         }
         else
         {
            _loc5_ = PanelDetailDN.getDNaddValue(data["indexID_s"],[data["dnlv"]]);
         }
         var _loc9_:String = getAttrBgByType(_loc5_.type);
         mImg_status = GlobalFunction.createImage(_loc9_);
         mImg_status.touchable = false;
         mImg_status.x = int((80 - mImg_status.width) * 0.5);
         mImg_status.y = 80;
         addChild(mImg_status);
         _loc2_ = mImg_status.width;
         mTxt_status = new LOL_TextField(GlobalLanguageStr.getLanguageStr(25053) + GameMapTools.toPercentage(_loc5_.currP) + _loc5_.attrStr,_loc2_,24);
         mTxt_status.fontSize = 12;
         mTxt_status.fontColor = 16777215;
         mTxt_status.hAlign = "center";
         mTxt_status.shadowFilter();
         mTxt_status.x = mImg_status.x;
         mTxt_status.y = mImg_status.y - 1;
         addChild(mTxt_status);
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         this.clear();
      }
      
      override public function onTRIGGERED(param1:Event) : void
      {
         var _loc2_:Array = null;
         var _loc3_:Object = null;
         if(_parent.x < 0 || _parent.x > 5)
         {
            return;
         }
         if(data["dn_self"] == false)
         {
            return;
         }
         if(data["lock"] && data["lock"] == 1)
         {
            _loc2_ = _data["data_base"];
            if(GlobalData.$userData.lv >= _loc2_[2] && GlobalData.$userData.attrs.dn_stone >= _loc2_[3])
            {
               _loc3_ = {
                  "ok":sendService,
                  "no":GlobalFunction.functionNull
               };
               GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90425,_loc2_[2],_loc2_[3]),GlobalTextStyle.COLOR_W_Y_Y_G),_loc3_);
            }
            else
            {
               if(GlobalData.$userData.lv < _loc2_[2])
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90428,_loc2_[2]));
                  return;
               }
               if(GlobalData.$userData.attrs.dn_stone < _loc2_[3])
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90429,_loc2_[3]));
                  return;
               }
            }
         }
         else
         {
            GlobalData.$tempTeamSelect = data;
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_detailDN",false,true);
         }
      }
      
      private function sendService() : void
      {
         SendServiceAMFFun.send_user_dn_unlock(re_dn_unlock,{"key":data["indexID_s"]});
      }
      
      private function re_dn_unlock(param1:Object) : void
      {
         var _loc2_:Rectangle = null;
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.dn = param1.data.dn;
            GlobalData.$userData.attrs.dn_stone = param1.data.dn_stone;
         }
         if(stage)
         {
            _loc2_ = getBounds(stage);
            LayoutUIAnimation.getOnlyExample().popEffect({
               "id":"e012",
               "x":_loc2_.x + _loc2_.width * 0.42,
               "y":_loc2_.y + _loc2_.height * 0.4,
               "rate":0.75,
               "s":{"id":"doorOpen"}
            });
         }
         GlobalData.$mEventDispatcher.dispatchEventWith("update_dn_team_ui");
      }
      
      private function getAttrBgByType(param1:String) : String
      {
         var _loc2_:String = "";
         if(param1 == "all")
         {
            _loc2_ = "UI_dn_tag_000" + 0;
         }
         else if(param1 == "hp")
         {
            _loc2_ = "UI_dn_tag_000" + 2;
         }
         else if(param1 == "ap")
         {
            _loc2_ = "UI_dn_tag_000" + 1;
         }
         else if(param1 == "de_ph")
         {
            _loc2_ = "UI_dn_tag_000" + 4;
         }
         else
         {
            _loc2_ = "UI_dn_tag_000" + 3;
         }
         return _loc2_;
      }
   }
}

