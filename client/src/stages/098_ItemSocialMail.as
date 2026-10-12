package com.meng52.game.ui.element
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.command.avatar.AvatarData;
   import com.meng52.game.command.avatar.AvatarManager;
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.ui.panel.PanelMail;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.Tools;
   import feathers.controls.renderers.IListItemRenderer;
   import flash.geom.Rectangle;
   import starling.display.Image;
   import starling.events.Event;
   
   public class ItemSocialMail extends ItemSocialFriend implements IListItemRenderer
   {
      
      private var mNormal:Image;
      
      public function ItemSocialMail()
      {
         super();
      }
      
      override public function layoutWH() : void
      {
         var _loc1_:int = int(this.data["index"] != null ? this.data["index"] : -1);
         if(_loc1_ != 3)
         {
            super.layoutWH();
         }
         else if(this.mScale9Image)
         {
            this.width = this.mScale9Image.width;
            this.height = this.mScale9Image.height;
         }
         tweenX();
      }
      
      override public function init(param1:Object) : void
      {
         var _loc2_:int = int(this.data["index"] != null ? this.data["index"] : -1);
         if(_loc2_ != 3)
         {
            super.init(param1);
         }
         else
         {
            this.removeEventListener("triggered",this.onTRIGGERED);
            this.mScale9Image = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",600,115,new Rectangle(110,55,70,20));
            this.addChild(this.mScale9Image);
            this.mBgImg = GlobalFunction.createScale3Image("UI_bg_9slice_6_0000",20,20,410);
            this.mBgImg.x = mScale9Image.x + 28;
            this.mBgImg.y = mScale9Image.y + 15 + 3;
            this.addChild(this.mBgImg);
            this.mRight_ruler = this.mScale9Image.width;
            this.mBottom_ruler = this.mScale9Image.height;
            this.setUI();
         }
      }
      
      override public function setAvatarUI() : void
      {
         var _loc2_:String = null;
         var _loc1_:Boolean = data.uid == GlobalData.$mSYS.uid;
         if(_loc1_)
         {
            this.data.avatar = {
               "aid":GlobalData.$mConfig_client["sys_aid"],
               "lv":99,
               "slv":10
            };
         }
         if(this.data.avatar)
         {
            _loc2_ = this.data.avatar.aid;
            this.setAvatar(_loc2_,3,this.data.avatar,false,true);
            this.addChild(this.mAvatar);
         }
         else
         {
            this.mNormal = GlobalFunction.createImage("UI_bg_card_2_0003");
            this.mNormal.touchable = false;
            this.addChild(this.mNormal);
         }
      }
      
      override public function setUI() : void
      {
         var _loc3_:String = null;
         var _loc7_:* = 0;
         var _loc5_:AvatarData = null;
         var _loc10_:String = null;
         var _loc18_:String = null;
         var _loc11_:Object = null;
         var _loc13_:Object = null;
         var _loc4_:Object = null;
         var _loc9_:TextFieldHtmlRenderer = null;
         var _loc12_:int = 0;
         var _loc8_:Number = NaN;
         var _loc15_:Object = null;
         var _loc14_:String = null;
         var _loc1_:int = 0;
         var _loc17_:Number = 0;
         var _loc19_:int = int(this.data["index"] != null ? this.data["index"] : -1);
         var _loc16_:Boolean = data.uid == GlobalData.$mSYS.uid;
         if(_loc19_ != 3)
         {
            _loc17_ = 110 * 3;
            if(_loc16_)
            {
               _loc5_ = AvatarManager.getOnlyExample().getData(GlobalData.$mConfig_client["sys_aid"]);
               _loc3_ = GlobalLanguageStr.getLanguageStr(20172,_loc5_.name);
               _loc7_ = 13056;
            }
            else
            {
               _loc3_ = this.data.name;
               _loc7_ = 1118481;
            }
            this.mTxt_title = GlobalTextStyle.getTextField(_loc3_,20,_loc7_,"left",165,35,GlobalConfig.FONT_1);
            this.mTxt_title.x = 120;
            this.mTxt_title.y = 18;
            this.addChild(this.mTxt_title);
         }
         else
         {
            _loc10_ = GlobalLanguageStr.getLanguageStr(this.data.info_type,this.data.info_data);
            _loc11_ = data.gift_dict;
            _loc13_ = null;
            for(var _loc6_:Object in _loc11_)
            {
               if(_loc6_ == "avatar_soul" || _loc6_ == "equip_soul")
               {
                  for(var _loc2_:String in _loc11_[_loc6_])
                  {
                     _loc4_ = {};
                     _loc4_[_loc2_] = _loc11_[_loc6_][_loc2_];
                     _loc13_ = GlobalFunction.getAwardByType(_loc6_.toString(),_loc4_);
                     _loc10_ += "," + GlobalLanguageStr.getLanguageStr(90062,_loc13_.msg);
                  }
               }
               else
               {
                  _loc13_ = GlobalFunction.getAwardByType(_loc6_.toString(),_loc11_[_loc6_]);
                  _loc10_ += "," + GlobalLanguageStr.getLanguageStr(90062,_loc13_.msg);
               }
            }
            _loc9_ = GlobalTextStyle.getHtmlTextRenderer();
            _loc9_.width = 410;
            _loc9_.height = 60;
            if(_loc10_.length > 42)
            {
               _loc18_ = _loc10_.substr(0,42);
               _loc9_.text = Tools.formatLineX(_loc18_ + ".....",[1513239,1513239,1513239,1513239],21,18);
            }
            else
            {
               _loc9_.text = Tools.formatLineX(_loc10_,[1513239,1513239,1513239,1513239],21,18);
            }
            _loc9_.x = int(this.mScale9Image.x + 30);
            _loc9_.y = 19;
            this.addChild(_loc9_);
         }
         if(_loc19_ == 1)
         {
            this.UI_btn_smallFun_0 = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20145),126,45,"UI_btn_enterGame_0_0000");
            this.UI_btn_smallFun_0.addEventListener("triggered",this.onTRIGGERED_btns);
            this.UI_btn_smallFun_0.x = this.mRight_ruler - this.UI_btn_smallFun_0.width - 29;
            this.UI_btn_smallFun_0.y = this.mBottom_ruler - this.UI_btn_smallFun_0.height - 35;
            this.addChild(this.UI_btn_smallFun_0);
            _loc17_ = 300;
            this.mTxt_str0 = GlobalTextStyle.getTextField(Tools.dateFormat(this.data.time as Date,-8),20,4926491,"left",_loc17_,35);
            this.mTxt_str0.x = 121;
            this.mTxt_str0.y = this.mBottom_ruler - 60;
            this.addChild(this.mTxt_str0);
         }
         else if(_loc19_ == 3)
         {
            _loc17_ = this.mScale9Image.width;
            this.mTxt_str0 = GlobalTextStyle.getTextField(Tools.dateFormat(this.data.time as Date,-8),15,4926491,"left",_loc17_,35);
            this.mTxt_str0.x = this.mScale9Image.x + 25;
            this.mTxt_str0.y = this.mBottom_ruler - 39;
            this.addChild(this.mTxt_str0);
            _loc12_ = int(_data["status"] ? _data["status"] : 0);
            if(_loc12_ == 0)
            {
               this.UI_btn_smallFun_0 = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20173),126,45,"UI_btn_enterGame_0_0000");
               this.UI_btn_smallFun_0.shadowFilter();
               this.UI_btn_smallFun_0.addEventListener("triggered",this.onTRIGGERED_btns);
               this.UI_btn_smallFun_0.x = this.mRight_ruler - this.UI_btn_smallFun_0.width - 29;
               this.UI_btn_smallFun_0.y = this.mBottom_ruler - this.UI_btn_smallFun_0.height - 43;
               this.addChild(this.UI_btn_smallFun_0);
            }
            else
            {
               this.mTxt_title = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20377),25,4926491,"right",80,35);
               this.mTxt_title.x = int(this.mScale9Image.x + this.mScale9Image.width - 135);
               this.mTxt_title.y = 31;
               this.addChild(this.mTxt_title);
            }
         }
         else
         {
            if(_loc16_)
            {
               data["vip_lv"] = GlobalFunction.geVipMaxLv();
               data["lv"] = 50;
            }
            mVip = GlobalFunction.getVipImg(data.vip_lv,data.uid);
            this.addChild(this.mVip);
            mVip.visible = GlobalFunction.checkIOSvip();
            mVip.x = 160;
            mVip.y = this.mBottom_ruler - 24 - 15 - 3;
            if(MainConfig.$isEA)
            {
               mVip.visible = false;
            }
            this.mTxt_lvUser = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20004,this.data.lv),MainConfig.$isEA ? 24 : 20,4926491,"left",_loc17_,35);
            this.mTxt_lvUser.x = mVip.x + 45;
            this.mTxt_lvUser.y = mVip.y - 15;
            this.addChild(this.mTxt_lvUser);
            this.UI_btn_smallFun_0 = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20171),84,45,"UI_btn_enterGame_0_0000");
            this.UI_btn_smallFun_0.addEventListener("triggered",this.onTRIGGERED_btns);
            this.UI_btn_smallFun_0.x = this.mRight_ruler - this.UI_btn_smallFun_0.width - 19;
            this.UI_btn_smallFun_0.y = this.mBottom_ruler - this.UI_btn_smallFun_0.height - 20;
            this.addChild(this.UI_btn_smallFun_0);
            _loc17_ = 200;
            if(_loc16_)
            {
               this.mTxt_str0 = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20169),15,13056,"left",_loc17_,24 * 2,GlobalConfig.FONT_1);
            }
            else
            {
               _loc8_ = (this.data.login_time as Date).time * 0.001;
               _loc15_ = GlobalData.$mConfig.system_simple.friend_cd;
               _loc14_ = "";
               if(SendAndSelect.$systemTimer_nowSecond - _loc8_ < _loc15_[3] * 60)
               {
                  _loc14_ = GlobalLanguageStr.getLanguageStr(90651);
               }
               else if(SendAndSelect.$systemTimer_nowSecond - _loc8_ < _loc15_[2] * 60)
               {
                  _loc14_ = GlobalLanguageStr.getLanguageStr(90650);
               }
               else
               {
                  _loc14_ = "";
               }
               this.mTxt_str0 = GlobalTextStyle.getTextField(_loc14_,15,13056,"left",_loc17_,24 * 2,GlobalConfig.FONT_1);
            }
            mTxt_str0.touchable = false;
            this.mTxt_str0.x = this.UI_btn_smallFun_0.x - 75;
            this.mTxt_str0.y = mTxt_title.y + 28;
            this.mTxt_str0.width = 85;
            this.mTxt_str0.height = 55;
            this.addChild(this.mTxt_str0);
            _loc1_ = 6;
            if(data.current_rank != null)
            {
               _loc1_ = GlobalFunction.check_pvp_list_title(data.current_rank);
            }
            else
            {
               _loc1_ = 7;
            }
            if(_loc16_)
            {
               _loc1_ = 1;
            }
            mImg_title = GlobalFunction.createImage("UI_pvp_icon_0_000" + (_loc1_ - 1));
            mImg_title.pivotX = mImg_title.width * 0.5;
            mImg_title.pivotY = mImg_title.height * 0.5;
            mImg_title.scaleX = mImg_title.scaleY = 0.25;
            mImg_title.x = MainConfig.$isEA ? this.mTxt_lvUser.x + 205 : this.mTxt_lvUser.x + 130;
            mImg_title.y = this.mTxt_lvUser.y + 5;
            this.addChild(mImg_title);
         }
      }
      
      override public function onTRIGGERED_btns(param1:Event) : void
      {
         var _loc2_:int = int(this.data["index"] != null ? this.data["index"] : -1);
         if(_loc2_ == 1)
         {
            read_msg();
            GlobalFunction.setMail("type_mail_get",{
               "name":this.data.name,
               "uid":this.data.uid,
               "content":this.data.content,
               "num":this.data["indexID_s"]
            });
            data["status"] = 1;
         }
         else if(_loc2_ == 3)
         {
            if((data.gift_dict as Object).hasOwnProperty("equip"))
            {
               if(Tools.getElementNum(GlobalData.$userData.my_equips) >= GlobalData.$mConfig_simple.equip_config[0])
               {
                  GlobalFunction.popEquipFull();
                  return;
               }
            }
            if((data.gift_dict as Object).hasOwnProperty("avatar"))
            {
               if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
               {
                  GlobalFunction.popAvatarLen();
                  return;
               }
            }
            var _beforeClaim:Object = {"lv":GlobalData.$userData.lv,"energy":GlobalFunction.getEnergy(),"leadership":GlobalFunction.getLeaderShip()};
            var _mailGift:Object = data.gift_dict;
            var _mailItem:ItemSocialMail = this;
            SendServiceAMFFun.send_user_get_gift_msg(function(_receipt:Object):void
            {
               _receipt._extendedABefore = _beforeClaim;
               _receipt._extendedAGift = _mailGift;
               _mailItem.re_gift_msg(_receipt);
            },{"gk":data.id});
         }
         else
         {
            PanelMail.mType = "type_mail_send";
            PanelMail.mCfg = {
               "name":this.data.name,
               "uid":this.data.uid
            };
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_send_mail",false,true);
         }
      }
      
      private function re_gift_msg(param1:Object) : void
      {
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            return;
         }
         if(data.status == 1)
         {
            return;
         }
         var mPower_old:Object;
         var _data:Object;
         var _isLvUp:Boolean;
         var mBeforeEn:Object;
         var mPower_new:Object;
         var _leaderShip:int;
         var _leader:String;
         var arr:Array;
         var _re:Object = param1;
         var _giftDict:Object = _re._extendedAGift;
         var getReward:* = function():void
         {
            GlobalFunction.showReward2({"info":GlobalLanguageStr.getLanguageStr(90131)},_giftDict);
         };
         var _snd:String = "sound03";
         SoundManager.getOnlyExample().playSound(_snd);
         mPower_old = _re._extendedABefore == null ? null : _re._extendedABefore.energy;
         data["status"] = 1;
         _data = _re.data;



















         _isLvUp = false;
         if(GlobalFunction.didApplyProfileStateSync(_re) && _re._extendedABefore != null && int(_data.lv) > int(_re._extendedABefore.lv) && int(_data.lv) == int(GlobalData.$userData.lv))
         {
            _isLvUp = true;
         }
         GlobalFunction.updateEn();
         if(_isLvUp)
         {
            mBeforeEn = _re._extendedABefore.energy;

            mPower_new = GlobalFunction.getEnergy();
            if(mBeforeEn)
            {
               _leaderShip = GlobalFunction.getLeaderShip();
               _leader = String(_re._extendedABefore.leadership);
               arr = [[Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20137)),mPower_old.energy,mPower_new.energy],[Tools.formatLineX(GlobalLanguageStr.getLanguageStr(97623)),_leader,_leaderShip.toString()]];
            }
            GlobalFunction.popFunctionOpenAlert(GlobalLanguageStr.getLanguageStr(97607,_data.lv),arr,{"close":getReward},true);
         }
         else
         {
            getReward();
         }
         if(_data.lv != null && _data.exp != null)
         {
            GlobalFunction.updateExp();
         }
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
         if(this.stage)
         {
            this.mTxt_title = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20377),25,4926491,"right",80,35);
            this.mTxt_title.x = int(this.mScale9Image.x + this.mScale9Image.width - 135);
            this.mTxt_title.y = 31;
            this.addChild(this.mTxt_title);
         }
         GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
         if(this.stage && this.UI_btn_smallFun_0)
         {
            this.UI_btn_smallFun_0.removeFromParent(true);
         }
         if(this.stage)
         {
            read_msg();
         }
         GlobalData.$mEventDispatcher.dispatchEventWith("update_mail_tag");
      }
      
      private function read_msg() : void
      {
         SendServiceAMFFun.send_user_read_msg();
         GlobalData.$msg_new_num -= 1;
      }
   }
}

