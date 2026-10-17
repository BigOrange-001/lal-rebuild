package com.meng52.game.ui.panel
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.ui.element.LOL_IconText;
   import com.meng52.game.ui.screen.PanelCenterMainAvatar;
   import feathers.controls.ScrollContainer;
   import feathers.display.Scale9Image;
   import feathers.layout.VerticalLayout;
   import flash.geom.Rectangle;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   
   public class PanelEveryDaySign extends PanelCenterMainAvatar
   {
      
      private const PANEL_HEIGHT:Number = 680;
      
      private const PRE_ROW_NUM:int = 5;
      
      private const ITEM_WIDTH:int = 114;
      
      private const ITEM_HEIGHT:int = 149;
      
      private const TOP_HEIGHT_CONST:int = 130;
      
      private var nowdate:Date;
      
      private var m_item_arr:Array;
      
      private var m_signed_txt:TextFieldHtmlRenderer;
      
      private var m_scrollContainer:ScrollContainer;
      
      private var m_background:Scale9Image;
      
      private var m_spRule:Sprite;
      
      private var m_iconTxt:LOL_IconText;
      
      private var m_user_check_in:Object;
      
      private var m_config_chech_in:Object;
      
      public function PanelEveryDaySign()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         m_user_check_in = GlobalData.$userData.attrs.check_in;
         m_config_chech_in = GlobalData.$mConfig_check_in;
         this.removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(90682,m_user_check_in.m),680);
         GlobalData.$mEventDispatcher.addEventListener("update_check_in",updateUIdate);
         setUI();
      }
      
      private function setUI() : void
      {
         var _gift_spr:Sprite;
         var i:int;
         var col:int;
         var row:int;
         var _config_gift:Array;
         var _datelen:int;
         var _count:int;
         var _b:Boolean;
         var _item:ItemSign;
         var layout:VerticalLayout;
         var o:Object;
         m_item_arr = [];
         m_iconTxt = new LOL_IconText("",6475106);
         m_iconTxt.bgWidth = MainConfig.$isEA ? 470 : (MainConfig.$isEnglish ? 370 : 230);
         m_iconTxt.x = MainConfig.$isEA ? this.mImg9_baseBg.x + (this.mImg9_baseBg.width - m_iconTxt.bgWidth) * 0.5 - 60 : this.mImg9_baseBg.x + (this.mImg9_baseBg.width - m_iconTxt.bgWidth) * 0.5;
         m_iconTxt.y = 90;
         m_background = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",592,520,new Rectangle(20,20,20,20));
         m_background.x = this.mImg9_baseBg.x + (mImg9_baseBg.width - m_background.width) * 0.5;
         m_background.y = m_iconTxt.y + m_iconTxt.height;
         this.addChild(m_iconTxt);
         m_signed_txt = GlobalTextStyle.getHtmlTextRenderer();
         this.addChild(m_signed_txt);
         m_signed_txt.mLayoutFun = function():void
         {
            var _loc1_:Rectangle = m_signed_txt.getTextSnapshotFrame();
            m_signed_txt.x = mImg9_baseBg.x + (mImg9_baseBg.width - _loc1_.width) * 0.5;
            m_signed_txt.y = mImg9_baseBg.x + 90;
         };
         _gift_spr = new Sprite();
         i = 0;
         col = 0;
         row = 0;
         _config_gift = m_config_chech_in[m_user_check_in.m];
         _datelen = int(_config_gift.length);
         _count = int(_datelen % 5 == 0 ? _datelen : (int(_datelen / 5) + 1) * 5);
         i = 0;
         while(i < _count)
         {
            if(i % 5 == 0)
            {
               row = i / 5;
            }
            col = i % 5;
            _b = i < _datelen;
            _item = new ItemSign(i,_b);
            _item.x = 114 * col;
            _item.y = 149 * row;
            m_item_arr.push(_item);
            _gift_spr.addChild(_item);
            i = i + 1;
         }
         m_scrollContainer = new ScrollContainer();
         layout = new VerticalLayout();
         m_scrollContainer.layout = layout;
         m_scrollContainer.setSize(600,this.mImg9_baseBg.height - 130 - 70);
         m_scrollContainer.pageThrowDuration = 0;
         m_scrollContainer.hasElasticEdges = false;
         m_scrollContainer.x = this.mImg9_baseBg.x + (this.mImg9_baseBg.width - m_scrollContainer.width) * 0.5 + 15;
         m_scrollContainer.y = 130 + 15;
         m_scrollContainer.addChild(_gift_spr);
         this.addChild(m_scrollContainer);
         o = GlobalFunction.get_HelpLink(GlobalLanguageStr.getLanguageStr(90684));
         m_spRule = o.ui;
         if(MainConfig.$isEA)
         {
            m_spRule.width = 120;
         }
         m_spRule.x = MainConfig.$isEA ? _width - o.w - 15 : _width - o.w - 40;
         m_spRule.y = 88;
         addChild(m_spRule);
         m_spRule.addEventListener("touch",onTRIGGERED_help);
         updateUIdate();
      }
      
      public function updateUIdate() : void
      {
         m_user_check_in = GlobalData.$userData.attrs.check_in;
         m_config_chech_in = GlobalData.$mConfig_check_in;
         var _loc1_:int = 0;
         var _loc2_:Array = m_user_check_in.had_check;
         if(_loc2_[0] == 1 && _loc2_[1] == 0)
         {
            _loc1_ = m_user_check_in.n + 1;
         }
         else
         {
            _loc1_ = int(m_user_check_in.n);
         }
         _loc1_ = Math.min(_loc1_,(m_config_chech_in[m_user_check_in.m] as Array).length);
         m_iconTxt.text = GlobalLanguageStr.getLanguageStr(90683,_loc1_);
      }
      
      private function onTRIGGERED_help(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(m_spRule);
         if(_loc2_)
         {
            if(_loc2_.phase == "ended")
            {
               GlobalFunction.popPanelHelp(MainConfig.SERVER_ADDRESS_EVERYDAYSIGN);
            }
         }
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         var _loc2_:ItemSign = null;
         super.onREMOVED_FROM_STAGE(param1);
         GlobalData.$mEventDispatcher.removeEventListener("update_check_in",updateUIdate);
         if(m_iconTxt)
         {
            m_iconTxt.removeFromParent(true);
            m_iconTxt = null;
         }
         if(m_scrollContainer)
         {
            m_scrollContainer.removeFromParent(true);
            m_scrollContainer = null;
         }
         while(m_item_arr.length > 0)
         {
            _loc2_ = m_item_arr.pop();
            _loc2_.removeFromParent(true);
            _loc2_ = null;
         }
         m_item_arr = null;
      }
   }
}

import com.meng52.display.TextFieldHtmlRenderer;
import com.meng52.game.global.GlobalData;
import com.meng52.game.global.GlobalFunction;
import com.meng52.game.global.GlobalLanguageStr;
import com.meng52.game.global.GlobalTextStyle;
import com.meng52.game.ui.stage.LayoutUIAnimation;
import com.meng52.net.SendServiceAMFFun;
import com.meng52.sound.SoundManager;
import com.meng52.utils.Tools;
import feathers.display.Scale9Image;
import flash.geom.Rectangle;
import starling.animation.Tween;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.Image;
import starling.display.Quad;
import starling.display.Sprite;
import starling.events.TouchEvent;
import starling.text.TextField;

class ItemSign extends Sprite
{
   
   private const ITEM_SCALE:Number = 1.2;
   
   private var m_all_spr:Sprite;
   
   private var m_background:Scale9Image;
   
   private var m_quad:Quad;
   
   private var m_gift_bg:Image;
   
   private var m_vip_info_spr:Sprite;
   
   private var m_vip_info_bg:Image;
   
   private var m_vip_info_txt:TextFieldHtmlRenderer;
   
   private var m_num_txt:TextField;
   
   private var m_mask_bg:Quad;
   
   private var m_get_icon:Image;
   
   private var m_id:int;
   
   private var m_empty_panel:Boolean;
   
   private var m_config_chech_in:Object;
   
   private var m_user_check_in:Object;
   
   private var m_double_need_vip:int = 0;

   private var m_bonus_orange_cards:int = 0;
   
   private var m_get_status:Boolean = false;
   
   private var m_info_status:Boolean = false;
   
   private var m_had_check_in:Boolean = false;
   
   private var _AwardItem:* = null;
   
   private var _awardType:String;
   
   private var _msg:String;
   
   private var _check_in_msg:String;
   
   private var _gift_ui:DisplayObject;
   
   private var _double_gift:Boolean = false;
   
   public function ItemSign(param1:int, param2:Boolean = false)
   {
      super();
      this.addEventListener("removedFromStage",on_REMOVED_FROM_STAGE);
      this.addEventListener("touch",onTouch);
      this.m_id = param1;
      this.m_empty_panel = param2;
      init();
   }
   
   private function onTouch(param1:TouchEvent) : void
   {
      if(param1.getTouch(this,"ended"))
      {
         if(m_get_status)
         {
            getGift();
         }
         else if(m_info_status)
         {
            m_user_check_in = GlobalData.$userData.attrs.check_in;
            var _loc1_:Array = m_user_check_in.had_check;
            var _loc2_:int = _loc1_[0] == 1 && _loc1_[1] == 1 ? int(m_user_check_in.n) - 1 : int(m_user_check_in.n);
            var _loc3_:String = "金砖×" + Tools.formateNum(int(_AwardItem));
            if(m_bonus_orange_cards > 0)
            {
               _loc3_ += "\n随机非皮肤橙色英雄×" + m_bonus_orange_cards + "（同一英雄）";
            }
            if(m_double_need_vip > 0)
            {
               _loc3_ += "\nVIP补领：金砖×" + Tools.formateNum(int(_AwardItem));
            }
            if(m_id < _loc2_)
            {
               _loc3_ += "\n该日签到奖励已结束";
            }
            else
            {
               _loc3_ += "\n还没有到该签到日期";
            }
            GlobalFunction.popAlert("第" + (m_id + 1) + "天签到奖励",_loc3_,null,true,null,true);
         }
      }
   }
   
   private function getGift() : void
   {
      m_user_check_in = GlobalData.$userData.attrs.check_in;
      var _loc1_:Array = m_user_check_in.had_check;
      _double_gift = check_is_double_gift(_loc1_);
      if(_loc1_[0] == 1 && _loc1_[1] == 0)
      {
         if(GlobalData.$userData.vip_lv >= m_double_need_vip)
         {
            SendServiceAMFFun.send_user_check_in(reFun,{"is_vip":true});
         }
         else
         {
            GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90685),GlobalTextStyle.COLOR_W_Y_Y_G));
         }
      }
      else if(_loc1_[0] == 1 && _loc1_[1] == 1)
      {
         LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getStr(90686,"今日双倍签到奖励已领取。"));
      }
      else
      {
         SendServiceAMFFun.send_user_check_in(reFun);
      }
   }
   
   private function check_is_double_gift(param1:Array) : Boolean
   {
      var _loc2_:Boolean = false;
      if(m_double_need_vip != 0)
      {
         // A double receipt belongs only to the second, VIP claim. The first
         // ordinary claim begins with [0,0] and must show the normal reward.
         if(param1 != null && param1.length > 1 && param1[0] == 1 && param1[1] == 0 && GlobalData.$userData.vip_lv >= m_double_need_vip)
         {
            _loc2_ = true;
         }
      }
      else
      {
         _loc2_ = false;
      }
      return _loc2_;
   }
   
   private function reFun(param1:Object) : void
   {
      var _loc2_:Object = null;
      var _loc4_:String = null;
      var _reward:Object = null;
      var _coin:int = 0;
      var _cardId:String = null;
      var _cardName:String = null;
      var _loc3_:String = "sound03";
      SoundManager.getOnlyExample().playSound(_loc3_);
      if(param1.data)
      {
         _reward = param1.data.check_in_reward;
         _coin = _reward && _reward.coin != null ? int(_reward.coin) : int(this._AwardItem);
         _loc4_ = (_double_gift ? "VIP补领：" : "签到获得：") + "金砖×" + Tools.formateNum(_coin);
         if(!_double_gift && _reward && _reward.avatar)
         {
            for(_cardId in _reward.avatar)
            {
               _cardName = GlobalData.$mConfig_avatar[_cardId] && GlobalData.$mConfig_avatar[_cardId].name ? String(GlobalData.$mConfig_avatar[_cardId].name) : _cardId;
               _loc4_ += "\n" + _cardName + "×" + int(_reward.avatar[_cardId]);
            }
         }
         if(this.m_double_need_vip != 0)
         {
            _loc2_ = {"need_vip":this.m_double_need_vip};
            GlobalFunction.popAward("coin",_loc4_,_coin,true,null,true,_loc2_);
         }
         else
         {
            GlobalFunction.popAward("coin",_loc4_,_coin,true,null);
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
         GlobalData.$userData.attrs.check_in = param1.data.check_in;
         }
         GlobalData.$mEventDispatcher.dispatchEventWith("update_check_in");
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
         GlobalFunction.update_UserData(param1.data);
         }
      }
      updateMask();
   }
   
   private function on_REMOVED_FROM_STAGE() : void
   {
      this.removeEventListener("removedFromStage",on_REMOVED_FROM_STAGE);
      this.removeEventListener("touch",onTouch);
   }
   
   public function init() : void
   {
      var _config_gift:Array;
      var _giftObj:Object;
      var i:Object;
      var _awardUI:Object;
      var _bonus_bg:Quad;
      var _bonus_txt:TextField;
      var m_vip_info_spr:Sprite;
      var _rate:Number;
      m_all_spr = new Sprite();
      this.addChild(m_all_spr);
      if(!m_empty_panel)
      {
         m_background = GlobalFunction.createScale9Image("UI_checkin_box0000",116,152,new Rectangle(5,5,10,10));
         m_quad = new Quad(m_background.width,m_background.height,12686423);
         m_all_spr.addChild(m_quad);
         m_all_spr.addChild(m_background);
      }
      else
      {
         m_user_check_in = GlobalData.$userData.attrs.check_in;
         m_config_chech_in = GlobalData.$mConfig_check_in;
         _config_gift = m_config_chech_in[m_user_check_in.m];
         _giftObj = _config_gift[m_id].reward;
         m_bonus_orange_cards = Math.max(0,int(_config_gift[m_id].bonus_orange_cards));
         for(i in _giftObj)
         {
            _awardType = i.toString();
            _AwardItem = _giftObj[i];
         }
         this.m_double_need_vip = _config_gift[m_id].vip_double;
         m_background = GlobalFunction.createScale9Image("UI_checkin_box0000",116,152,new Rectangle(5,5,10,10));
         m_quad = new Quad(m_background.width,m_background.height,12686423);
         m_all_spr.addChild(m_quad);
         m_all_spr.addChild(m_background);
         _awardUI = null;
         if(_awardType == "avatar_soul" || _awardType == "avatar")
         {
            _awardUI = GlobalFunction.getAwardByType(_awardType,_AwardItem,false,null,"",true,0.8);
         }
         else
         {
            _awardUI = GlobalFunction.getAwardByType(_awardType,_AwardItem,false,null,"",true,1);
         }
         this._gift_ui = _awardUI.ui;
         this._msg = _awardUI.msg;
         this._check_in_msg = _awardUI.check_in_msg;
         _gift_ui.pivotX = _gift_ui.width * 0.5;
         _gift_ui.pivotY = _gift_ui.height * 0.5;
         if(_awardType == "avatar_soul" || _awardType == "fragment")
         {
            _gift_ui.x = m_background.width * 0.5 + 5;
            _gift_ui.y = m_background.height * 0.5 + 5;
         }
         else if(_awardType == "avatar" || _awardType == "equip")
         {
            _gift_ui.x = m_background.width * 0.5;
            _gift_ui.y = m_background.height * 0.5;
         }
         else if(_awardType == "equip_soul")
         {
            _gift_ui.x = m_background.width * 0.5;
            _gift_ui.y = m_background.height * 0.5 + 4;
         }
         else
         {
            _gift_ui.x = m_background.width * 0.5 + 2;
            _gift_ui.y = m_background.height * 0.5 + 5;
         }
         m_all_spr.addChild(_gift_ui);
         if(m_bonus_orange_cards > 0)
         {
            _gift_ui.y = Math.min(_gift_ui.y,67);
            _bonus_bg = new Quad(108,25,3145734);
            _bonus_bg.alpha = 0.85;
            _bonus_bg.x = 4;
            _bonus_bg.y = 122;
            _bonus_bg.touchable = false;
            m_all_spr.addChild(_bonus_bg);
            _bonus_txt = GlobalTextStyle.getTextField("橙卡×" + m_bonus_orange_cards,16,16763904,"center",108,25);
            _bonus_txt.x = 4;
            _bonus_txt.y = 122;
            _bonus_txt.touchable = false;
            m_all_spr.addChild(_bonus_txt);
         }
         m_vip_info_spr = new Sprite();
         m_all_spr.addChild(m_vip_info_spr);
         m_vip_info_bg = GlobalFunction.createImage("UI_checkin_vipinfo_0000");
         m_vip_info_spr.addChild(m_vip_info_bg);
         m_vip_info_txt = GlobalTextStyle.getHtmlTextRenderer();
         m_vip_info_txt.text = Tools.formatLineX("VIP" + this.m_double_need_vip + (m_bonus_orange_cards > 0 ? "金砖×2" : "可双倍"),GlobalTextStyle.COLOR_W_Y_R_Y,m_bonus_orange_cards > 0 ? 17 : 20,17,false,"center");
         m_vip_info_txt.mLayoutFun = function():void
         {
            var _loc1_:Rectangle = m_vip_info_txt.getTextSnapshotFrame();
            m_vip_info_txt.x = m_vip_info_bg.x + (m_vip_info_bg.width - _loc1_.width) * 0.5;
         };
         m_vip_info_spr.pivotX = m_vip_info_spr.width;
         m_vip_info_spr.pivotY = m_vip_info_spr.height;
         m_vip_info_spr.rotation = -0.7853981633974483;
         _rate = Math.sin(3.141592653589793 * 0.25);
         m_vip_info_spr.x = m_vip_info_bg.width * _rate + 2;
         m_vip_info_spr.y = m_background.y + 2;
         m_vip_info_spr.addChild(m_vip_info_txt);
         m_vip_info_spr.visible = this.m_double_need_vip != 0;
         m_vip_info_spr.touchable = false;
         updateMask();
      }
   }
   
   private function updateMask() : void
   {
      var _loc5_:* = 0;
      var _loc1_:Tween = null;
      if(m_mask_bg)
      {
         Starling.juggler.removeTweens(m_mask_bg);
         m_mask_bg.removeFromParent(true);
         m_mask_bg = null;
      }
      m_user_check_in = GlobalData.$userData.attrs.check_in;
      m_config_chech_in = GlobalData.$mConfig_check_in;
      var _loc4_:int = 0;
      var _loc6_:Array = m_user_check_in.had_check;
      if(_loc6_[0] == 1 && _loc6_[1] == 1)
      {
         _loc4_ = m_user_check_in.n - 1;
      }
      else
      {
         _loc4_ = int(m_user_check_in.n);
      }
      if(this.m_id == _loc4_)
      {
         this.m_get_status = true;
         this.m_info_status = false;
      }
      else
      {
         this.m_get_status = false;
         this.m_info_status = true;
      }
      // Let the whole tile show the complete reward list instead of opening
      // the coin-only help popup attached to the icon.
      _gift_ui.touchable = false;
      var _loc3_:int = 0;
      var _loc2_:Number = 0.5;
      if(m_get_status)
      {
         if(_loc6_[0] == 1 && _loc6_[1] == 1)
         {
            _loc5_ = 1118481;
            _loc3_ = int(m_all_spr.numChildren);
            _loc2_ = 0.5;
         }
         else
         {
            if(m_double_need_vip != 0)
            {
               if(_loc6_[0] == 1 && _loc6_[1] == 0)
               {
                  _loc5_ = 7015559;
               }
               else
               {
                  _loc5_ = 6475106;
               }
            }
            else
            {
               _loc5_ = 6475106;
            }
            _loc3_ = 2;
            _loc2_ = 0.4;
         }
      }
      else
      {
         _loc5_ = 1118481;
         _loc3_ = int(m_all_spr.numChildren);
         _loc2_ = 0.5;
      }
      if(m_id <= _loc4_)
      {
         m_mask_bg = new Quad(m_background.width,m_background.height,_loc5_);
         m_mask_bg.x = m_background.x;
         m_mask_bg.y = m_background.y;
         m_mask_bg.alpha = _loc2_;
         m_mask_bg.touchable = false;
         m_all_spr.addChildAt(m_mask_bg,_loc3_);
         m_get_icon = GlobalFunction.createImage("UI_checkin_ok_0000");
         m_get_icon.x = m_background.width * 0.5;
         m_get_icon.y = m_background.height * 0.5;
         m_get_icon.touchable = false;
         m_all_spr.addChild(m_get_icon);
         if(m_id == _loc4_)
         {
            if(_loc6_[0] == 1 && _loc6_[1] == 1)
            {
               m_get_icon.visible = true;
            }
            else
            {
               m_get_icon.visible = false;
               _loc1_ = new Tween(m_mask_bg,1);
               _loc1_.fadeTo(0.15);
               _loc1_.reverse = true;
               _loc1_.repeatCount = 0;
               Starling.juggler.add(_loc1_);
            }
         }
      }
   }
}
