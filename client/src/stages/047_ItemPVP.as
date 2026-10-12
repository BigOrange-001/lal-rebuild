package com.meng52.game.ui.element
{
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.renderers.IListItemRenderer;
   import feathers.display.Scale9Image;
   import feathers.textures.Scale9Textures;
   import flash.geom.Rectangle;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class ItemPVP extends ItemBase implements IListItemRenderer
   {
      
      protected var mBtn_pk:LOL_Scale9Button;
      
      protected var mImg_title:Image;
      
      protected var mBox_avatars:Sprite;
      
      protected var mBox_UIs:Sprite;
      
      public function ItemPVP()
      {
         super();
      }
      
      override public function layoutWH() : void
      {
         if(this.mScale9Image)
         {
            this.width = mScale9Image.width;
            this.height = mScale9Image.height - 5;
         }
         else
         {
            this.width = 580;
            this.height = 110;
         }
         tweenX();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(mImg_title)
         {
            mImg_title.removeFromParent(true);
         }
         if(mBox_avatars)
         {
            StarlingTools.removeChildrenClear(mBox_avatars);
            mBox_avatars.removeFromParent(true);
         }
         if(mBox_UIs)
         {
            StarlingTools.removeChildrenClear(mBox_UIs);
            mBox_UIs.removeFromParent(true);
         }
         if(mBtn_pk)
         {
            mBtn_pk.removeFromParent(true);
         }
         this.clear();
         mBox_avatars = null;
         mBtn_pk = null;
         mImg_title = null;
         mBox_UIs = null;
      }
      
      override public function init(param1:Object) : void
      {
         var _loc12_:Scale9Textures = null;
         var _loc33_:Boolean = false;
         var _loc38_:Boolean = false;
         var _loc26_:String = null;
         var _loc19_:Boolean = false;
         var _loc15_:Number = NaN;
         var _loc31_:int = 0;
         var _loc10_:Number = NaN;
         var _loc35_:int = 0;
         var _loc5_:String = null;
         var _loc9_:Boolean = false;
         var _loc13_:Boolean = false;
         var _loc11_:int = 0;
         var _loc20_:Array = null;
         var _loc34_:int = 0;
         var _loc24_:String = null;
         var _loc2_:Avatar = null;
         var _loc32_:Sprite = null;
         var _loc6_:Array = null;
         var _loc21_:Object = null;
         var _loc36_:TextField = null;
         var _loc29_:int = 0;
         var _loc17_:Array = null;
         var _loc7_:Object = null;
         var _loc27_:TextField = null;
         var _loc23_:Number = NaN;
         var _loc18_:LOL_MutilTextFieldIcon = null;
         var _loc28_:TextField = null;
         var _loc22_:TextField = null;
         var _loc4_:Image = null;
         var _loc14_:String = null;
         var _loc39_:Image = null;
         var _loc40_:int = 0;
         var _loc16_:int = 0;
         var _loc8_:Image = null;
         var _loc37_:Image = null;
         var _loc3_:Object = null;
         var _loc30_:String = null;
         var _loc25_:TextField = null;
         mBox_UIs = new Sprite();
         addChild(mBox_UIs);
         if(param1["status"] <= 0)
         {
            _loc12_ = new Scale9Textures(GlobalFunction.getTexture("UI_pvp_bg_1_0000"),new Rectangle(30,30,50,50));
            this.mScale9Image = new Scale9Image(_loc12_);
            this.mScale9Image.width = 570;
            this.mScale9Image.height = 110;
            mBox_UIs.addChild(this.mScale9Image);
            this.width = mScale9Image.width;
            this.height = mScale9Image.height - 5;
            _loc33_ = GlobalFunction.checkIsFirstPVP();
            _loc38_ = param1["status"] < 0;
            _loc26_ = param1["id"];
            _loc19_ = _loc26_.indexOf("r") > -1;
            _loc15_ = mScale9Image.width * 0.5;
            _loc31_ = int(param1["indexID_s"]);
            _loc10_ = param1["mark"] != null ? Number(param1["mark"]) : NaN;
            if(isNaN(_loc10_) || _loc10_ < 0)
            {
               _loc10_ = GlobalFunction.getPVPoutputMark(_loc31_,60);
            }
            _loc35_ = 0;
            _loc5_ = "";
            _loc9_ = param1["is_enemy"] == 1;
            _loc13_ = false;
            _loc11_ = _loc9_ ? 20290 : (param1["is_enemy"] < 0 && !_loc33_ ? 20291 : 20289);
            // Keep _loc11_ for first-match robot behavior, but render local arena actions with dedicated text IDs.
            _loc40_ = _loc38_ && !_loc33_ ? 98111 : 98110;
            param1["isRobot"] = _loc19_;
            if(_loc38_)
            {
               _loc5_ = GlobalData.$userData.name;
               _loc35_ = int(GlobalData.$userData.lv);
            }
            else
            {
               mBox_avatars = new Sprite();
               _loc5_ = param1["name"];
               _loc34_ = 3;
               _loc24_ = "";
               if(_loc19_)
               {
                  _loc6_ = _loc26_.split("_");
                  _loc21_ = GlobalData.$mConfig_pvp_robot[_loc6_[1]];
                  _loc35_ = int(_loc21_.robot[_loc6_[2]][0]);
                  _loc20_ = (_loc21_.robot[_loc6_[2]] as Array).concat();
                  _loc20_.shift();
                  param1["data_base"] = _loc20_;
               }
               else
               {
                  _loc35_ = int(param1["lv"]);
                  _loc20_ = param1["data_base"] as Array;
               }
               if(_loc19_ && param1["indexID_s"] == 1 && _loc11_ == 20291)
               {
                  _loc36_ = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20361),30,6710886,"left",_loc15_,35);
                  _loc36_.x = 20;
                  _loc36_.y = -45;
                  mBox_avatars.addChild(_loc36_);
                  _loc13_ = true;
               }
               else
               {
                  _loc29_ = 0;
                  while(_loc29_ < _loc20_.length)
                  {
                     _loc17_ = _loc20_[_loc29_];
                     _loc24_ = _loc17_[0];
                     _loc7_ = {};
                     _loc7_.lv = _loc17_[1];
                     _loc7_.slv = _loc17_[2];
                     if(!_loc19_)
                     {
                        _loc7_.hp = _loc17_[3];
                        _loc7_.ap = _loc17_[4];
                        _loc7_.de_ph = _loc17_[5];
                        _loc7_.de_ma = _loc17_[6];
                        _loc7_.phase = _loc17_[7];
                        _loc7_.morph = _loc17_[11];
                     }
                     _loc2_ = new Avatar(_loc24_,_loc7_);
                     _loc32_ = _loc2_.getAvatarRes();
                     _loc32_.pivotY = 90;
                     if(_loc29_ > 0)
                     {
                        _loc32_.scaleX = _loc32_.scaleY = 0.6;
                        _loc32_.x = _loc29_ * 57;
                     }
                     else
                     {
                        _loc32_.scaleX = _loc32_.scaleY = 0.8;
                        _loc32_.x = -20;
                     }
                     mBox_avatars.addChildAt(_loc32_,0);
                     if(_loc34_ <= 1)
                     {
                        break;
                     }
                     _loc34_ -= 1;
                     _loc29_++;
                  }
               }
               mBox_avatars.x = 40;
               mBox_avatars.y = 90 - 5;
               addChild(mBox_avatars);
               if(mBox_avatars)
               {
                  mBox_avatars.flatten();
               }
            }
            _loc27_ = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90086,_loc31_),30,1513239,"left",_loc15_,46);
            _loc23_ = mScale9Image.width - 130;
            _loc18_ = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getLanguageStr(90497),_loc10_ + "","UI_money_mark_0_0000",4926491,4926491,MainConfig.$isEnglish ? 18 : 20);
            _loc18_.x = _loc15_ - 70;
            _loc18_.y = height - 24 - 10;
            addChild(_loc18_);
            this.mBtn_pk = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(_loc40_),85,60,(param1["is_enemy"] < 0 || _loc38_) && !_loc33_ ? "UI_btn_enterGame_0_0000" : "UI_btn_smallFun_1_0000");
            if(MainConfig.$isEnglish == true)
            {
               mBtn_pk.fontSize = 19;
            }
            mBtn_pk.x = mScale9Image.width - mBtn_pk.width - 10;
            mBtn_pk.y = (this.height - mBtn_pk.height) * 0.5;
            addChild(mBtn_pk);
            if(!_loc13_)
            {
               _loc28_ = GlobalTextStyle.getTextField(_loc5_,20,4926491,"left",130,29,GlobalConfig.FONT_1);
               _loc22_ = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20004,_loc35_),20,4926491,"right",_loc15_,29,GlobalConfig.FONT_1);
            }
            else
            {
               mBtn_pk.alpha = 0.5;
            }
            mBtn_pk.addEventListener("triggered",onTRIGGERED_btns);
            if(_loc33_)
            {
               mBtn_pk.visible = false;
            }
            if(_loc38_)
            {
               mImg_title = GlobalFunction.createImage("UI_pvp_icon_0_000" + (param1["numberIndex"] - 1));
               mImg_title.pivotX = mImg_title.width * 0.5 + 25;
               mImg_title.pivotY = mImg_title.height * 0.5 - 25;
               mImg_title.scaleX = mImg_title.scaleY = 0.4;
               mBox_UIs.addChild(mImg_title);
               mImg_title.x = 130;
               mImg_title.y = 45;
               _loc4_ = GlobalFunction.createImage("UI_pvp_bg_4_0000");
               _loc4_.x = 10;
               _loc4_.y = -3;
               mBox_UIs.addChild(_loc4_);
            }
            else if(param1["loser"] > 0)
            {
               mBtn_pk.visible = _loc33_;
            }
            if(_loc33_ && _loc38_)
            {
               _loc27_.text = GlobalLanguageStr.getLanguageStr(90103);
            }
            _loc27_.x = _loc15_ - 65;
            _loc27_.y = _loc18_.y - 35 - 3;
            mBox_UIs.addChild(_loc27_);
            if(!_loc13_)
            {
               _loc28_.x = _loc27_.x;
               _loc28_.y = _loc27_.y - 24 - 1;
               mBox_UIs.addChild(_loc28_);
               _loc22_.x = MainConfig.$isEA ? _loc23_ - _loc15_ + 10 : _loc23_ - _loc15_;
               _loc22_.y = _loc28_.y;
               mBox_UIs.addChild(_loc22_);
            }
            if(param1["indexID_s"] < 4)
            {
               mBtn_pk.y = mScale9Image.height - mBtn_pk.height - 15;
               _loc14_ = "";
               if(param1["indexID_s"] == 1)
               {
                  _loc14_ = "UI_pvp_icon_2_000" + (param1["indexID_s"] - 1);
               }
               else if(param1["indexID_s"] == 2)
               {
                  _loc14_ = "UI_pvp_icon_2_000" + (param1["indexID_s"] - 1);
               }
               else if(param1["indexID_s"] == 3)
               {
                  _loc14_ = "UI_pvp_icon_2_000" + (param1["indexID_s"] - 1);
               }
               _loc39_ = GlobalFunction.createImage(_loc14_);
               _loc39_.x = mBtn_pk.x + (mBtn_pk.width - _loc39_.width) / 2;
               _loc39_.y = mBtn_pk.y - _loc39_.height + 10;
               mBox_UIs.addChild(_loc39_);
            }
         }
         else
         {
            this.width = 580;
            this.height = 110;
            _loc16_ = param1["status"] - 1;
            _loc8_ = GlobalFunction.createImage("UI_pvp_icon_0_000" + _loc16_);
            _loc8_.pivotX = _loc8_.width * 0.5;
            _loc8_.pivotY = _loc8_.height * 0.5;
            _loc8_.scaleX = _loc8_.scaleY = 0.5;
            mBox_UIs.addChild(_loc8_);
            _loc37_ = GlobalFunction.createImage("UI_pvp_icon_1_000" + _loc16_);
            mBox_UIs.addChild(_loc37_);
            _loc37_.x = int((width - _loc37_.width) * 0.5) + 20;
            _loc37_.y = int((height - _loc37_.height) * 0.5);
            _loc8_.x = int(_loc37_.x - 70);
            _loc8_.y = int(_loc37_.y + _loc37_.height * 0.5);
            _loc3_ = GlobalData.$config_pvp_title[_loc16_];
            _loc30_ = param1["status"] == GlobalData.$config_pvp_title.length ? GlobalLanguageStr.getLanguageStr(90119,_loc3_.min) : GlobalLanguageStr.getLanguageStr(90118,_loc3_.min,_loc3_.max);
            _loc25_ = GlobalTextStyle.getTextField(_loc30_,20,4926491,"left",300,35,GlobalConfig.FONT_1);
            _loc25_.x = _loc37_.x + 10;
            _loc25_.y = _loc37_.y + _loc37_.height - 5;
            mBox_UIs.addChild(_loc25_);
         }
         if(mBox_UIs)
         {
            mBox_UIs.flatten();
         }
      }
      
      protected function onTRIGGERED_btns(param1:Event) : void
      {
         var _loc2_:Array = null;
         var _loc4_:* = null;
         var _loc3_:Object = null;
         var _loc5_:int = 0;
         if(mBtn_pk.alpha < 1)
         {
            GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(20362));
            return;
         }
         if(_data["status"] < 0)
         {
            if(GlobalData.$mGameClassObject && GlobalData.$mGameClassObject.mLayoutUICenter && GlobalData.$mGameClassObject.mLayoutUICenter.mPanelCenterPVP)
            {
               GlobalData.$mGameClassObject.mLayoutUICenter.mPanelCenterPVP.selectList(false);
            }
            return;
         }
         GlobalData.$pvp_rival = data;
         GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
         if(data["is_enemy"] >= 0)
         {
            _loc2_ = GlobalData.$mConfig_simple.capacity_config as Array;
            _loc3_ = GlobalFunction.getFragmentPower();
            _loc5_ = _loc2_[6] + GlobalData.$userData.records.fragment_energy_times * _loc2_[5];
            if(_loc3_.energy >= _loc2_[3])
            {
               if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
               {
                  GlobalFunction.popAvatarLen();
                  return;
               }
               GlobalData.$pvp_Embattle = _data["name"];
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_embattle",false,true);
            }
            else
            {
               GlobalFunction.sevice_pvp_buy(GlobalLanguageStr.getLanguageStr(20098));
            }
         }
         else if(GlobalFunction.checkIsFirstPVP())
         {
            if(GlobalData.$userData_avatarNum < GlobalData.$userData.attrs.avatar_len)
            {
               GlobalData.$pvp_Embattle = _data["name"];
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_embattle",false,true);
            }
            else
            {
               GlobalFunction.popAvatarLen();
            }
         }
         else
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_change_pvp",false,true);
         }
      }
   }
}

