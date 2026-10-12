package com.meng52.game.ui.element
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.controls.renderers.IListItemRenderer;
   import flash.geom.Rectangle;
   import starling.display.DisplayObject;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   
   public class ItemInteGralExchange extends ItemBase implements IListItemRenderer
   {
      
      private var _ui:DisplayObject;
      
      private var txt_HeroName:TextField;
      
      private var txt_Integral:TextField;
      
      private var btn_Exchange:LOL_Scale9Button;
      
      private var _award:Object;
      
      private var _id:String;
      
      private var _type:String;
      
      public function ItemInteGralExchange()
      {
         super();
      }
      
      override public function layoutWH() : void
      {
         this.width = 285;
         this.height = 135;
         tweenX(false);
      }
      
      override public function init(param1:Object) : void
      {
         this.mScale9Image = GlobalFunction.createScale9Image("UI_bg_vip_buy_0_0000",285,135,new Rectangle(30,30,58,30));
         this.addChild(this.mScale9Image);
         for(var _loc2_:String in param1.data)
         {
            for(var _loc3_:String in param1.data[_loc2_])
            {
               _id = _loc3_;
            }
            if(_loc2_ == "avatar" || _loc2_ == "avatar_soul" || _loc2_ == "equip" || _loc2_ == "equip_soul")
            {
               _award = GlobalFunction.getAwardByType(_loc2_,param1.data[_loc2_],false,null,"",true,0.8,this.parent.parent as List);
            }
            else
            {
               _award = GlobalFunction.getAwardByType(_loc2_,param1.data[_loc2_],false,null,"",true,1,this.parent.parent as List);
            }
            _ui = _award.ui;
            _ui.x = 25;
            _ui.y = 25;
            addChild(_ui);
         }
         txt_HeroName = GlobalTextStyle.getTextField(_award.baseName,20,16777215,"center",160,46);
         txt_HeroName.x = 110;
         txt_HeroName.y = _ui.y;
         addChild(txt_HeroName);
         txt_Integral = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97997) + param1.needNum,15,16777215,"center",100,24);
         txt_Integral.x = txt_HeroName.x + (txt_HeroName.width - txt_Integral.width) * 0.5;
         txt_Integral.y = txt_HeroName.y + txt_HeroName.height - 20;
         addChild(txt_Integral);
         btn_Exchange = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20459),80,40,"UI_btn_enterGame_0_0000");
         btn_Exchange.x = txt_HeroName.x + (txt_HeroName.width - btn_Exchange.width) * 0.5;
         btn_Exchange.y = txt_Integral.y + txt_Integral.height;
         addChild(btn_Exchange);
         if(!getVipTime().can)
         {
            btn_Exchange.enabled = false;
            btn_Exchange.touchable = true;
         }
         btn_Exchange.addEventListener("triggered",onTRIGGERED_Fight);
         this.addEventListener("touch",onTOUCH_ui);
      }
      
      private function getVipTime() : Object
      {
         var _loc6_:Object = GlobalData.$mConfig_ploy_system_simple.extract_avatar;
         var _loc3_:Number = (_loc6_.start_time as Date).time;
         var _loc5_:Number = (_loc6_.end_time as Date).time;
         var _loc1_:Number = SendAndSelect.$systemTimer_nowSecond * 1000;
         var _loc2_:Date = new Date();
         _loc2_.setTime(_loc1_);
         var _loc4_:Object = {};
         if(_loc1_ > _loc3_ && _loc1_ < _loc5_)
         {
            _loc4_.can = true;
         }
         else
         {
            _loc4_.can = false;
         }
         _loc4_.endTime = _loc5_ - _loc1_;
         return _loc4_;
      }
      
      private function onTOUCH_ui(param1:TouchEvent) : void
      {
         var _loc3_:List = this.parent.parent as List;
         if(_loc3_.isScrolling)
         {
            return;
         }
         var _loc2_:Touch = null;
         if(mAvatar)
         {
            _loc2_ = param1.getTouch(mAvatar,"ended");
            if(_loc2_)
            {
               GlobalFunction.setDetaiAvatar({"id":data.aid},true);
               return;
            }
         }
      }
      
      private function onTRIGGERED_Fight(param1:Event) : void
      {
         var _loc3_:LOL_Button = param1.currentTarget as LOL_Button;
         if(!getVipTime().can)
         {
            GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(97998));
            return;
         }
         GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
         if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
         {
            GlobalFunction.popAvatarLen();
            return;
         }
         var _loc2_:uint = 0;
         if(GlobalData.$userData.attrs.lottery_activity.score)
         {
            _loc2_ = uint(GlobalData.$userData.attrs.lottery_activity.score);
         }
         if(_loc2_ >= data.needNum)
         {
            SendServiceAMFFun.send_user_exchange_activity_avatar(onRe,{"index":data.index});
         }
         else
         {
            GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(97694));
         }
      }
      
      private function onRe(param1:Object) : void
      {
         if(stage == null)
         {
            return;
         }
         var _loc2_:Object = {};
         if(param1.data)
         {
            for(var _loc4_:Object in param1.data)
            {
               if(_loc4_ == "avatar")
               {
                  for(var _loc3_:Object in param1.data.avatar)
                  {
                     if(!GlobalFunction.isVersionedProfileReceipt(param1))
                     {
                        GlobalData.$userData.avatars[_loc3_.toString()] = param1.data["avatar"][_loc3_.toString()];
                     }
                     _loc2_ = GlobalFunction.getAwardByType("avatar",param1.data["avatar"]);
                     GlobalFunction.popAward("avatar",_loc2_.msg,param1.data["avatar"]);
                  }
               }
               if(_loc4_ == "avatar_soul")
               {
                  for(_loc3_ in param1.data[_loc4_])
                  {
                     if(GlobalData.$userData.avatar_soul[_loc3_])
                     {
                        if(!GlobalFunction.isVersionedProfileReceipt(param1))
                        {
                           GlobalData.$userData.avatar_soul[_loc3_] += param1.data[_loc4_][_loc3_];
                        }
                     }
                     else
                     {
                        if(!GlobalFunction.isVersionedProfileReceipt(param1))
                        {
                           GlobalData.$userData.avatar_soul[_loc3_] = param1.data[_loc4_][_loc3_];
                        }
                     }
                     _loc2_ = GlobalFunction.getAwardByType("avatar_soul",param1.data["avatar_soul"]);
                     GlobalFunction.popAward("avatar_soul",_loc2_.msg,param1.data["avatar_soul"]);
                  }
               }
            }
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.lottery_activity.score = param1.data.score;
         }
         GlobalData.$mEventDispatcher.dispatchEventWith("updata_vip_choujiang_fush");
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         StarlingTools.removeChildrenClear(this);
      }
   }
}

