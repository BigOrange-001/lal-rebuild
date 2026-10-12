package com.meng52.game.ui.panel
{
   import com.meng52.display.ScrollScreenForTxt;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.map.GameMapTools;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.element.LOL_TextField;
   import com.meng52.game.ui.screen.PanelCenterCasino;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.HtmlTextFormat;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import starling.animation.Tween;
   import starling.core.Starling;
   import starling.display.DisplayObject;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   
   public class PanelActivityGrouponBuy extends PanelCenterCasino
   {
      
      public static var BTN_NAME_BUYONE:String = "btn_name_buyone";
      
      public static var BTN_NAME_BUYTEN:String = "btn_name_buyten";
      
      private var mTxt_one:LOL_TextField;
      
      private var mTxt_ten:LOL_TextField;
      
      private var case_one:Scale9Image;
      
      private var case_ten:Scale9Image;
      
      private var bgOne:Image;
      
      private var bgTen:Image;
      
      private var quad_one:Quad;
      
      private var quad_ten:Quad;
      
      private var currentGold:LOL_MutilTextFieldIcon;
      
      private var _bgBottom:Scale9Image;
      
      private var infoBottom:ScrollScreenForTxt;
      
      private var mTxt_buy:TextField;
      
      private var buyOne_pay:TextField;
      
      private var buyTen_pay:TextField;
      
      private var _wordA_bg:Image;
      
      private var _wordB_bg:Image;
      
      private var mImgBg:Image;
      
      private var m_light_bg:Image;
      
      private var _tween:Tween;
      
      private var buyAgain:LOL_Scale9Button;
      
      private var buyOk:LOL_Scale9Button;
      
      private var needNum:LOL_MutilTextFieldIcon;
      
      private var mBoxSpriteOne:Sprite;
      
      private var _ui:DisplayObject;
      
      private var mBoxSpriteTen:Sprite;
      
      private var mBoxSpriteIconTen:Sprite;
      
      private var buyGift:Array;
      
      private var buyTenBg:Array;
      
      private var buyTenBgTween:Array;
      
      private var iconStartArr:Array;
      
      private var oneIcon:Image;
      
      private var tenIcon:Image;
      
      private var cfg:Object;
      
      private var price:Number = 0;
      
      private var money:Number = 0;
      
      public function PanelActivityGrouponBuy()
      {
         super();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         var _loc2_:Tween = null;
         var _loc3_:Image = null;
         GlobalData.$mEventDispatcher.removeEventListener("update_groupon_buy_coin",upDataGold);
         if(buyTenBgTween)
         {
            while(buyTenBgTween.length > 0)
            {
               _loc2_ = buyTenBgTween.pop();
               Starling.juggler.remove(_loc2_);
               _loc2_ = null;
            }
         }
         if(buyTenBg)
         {
            while(buyTenBg.length > 0)
            {
               _loc3_ = buyTenBg.pop();
               _loc3_.removeFromParent(true);
               _loc3_.dispose();
               _loc3_ = null;
            }
         }
         if(quad_one)
         {
            quad_one.removeFromParent(true);
            quad_one.dispose();
         }
         if(quad_ten)
         {
            quad_ten.removeFromParent(true);
            quad_ten.dispose();
         }
         if(mTxt_one)
         {
            mTxt_one.removeFromParent(true);
            mTxt_one.dispose();
         }
         if(mTxt_ten)
         {
            mTxt_ten.removeFromParent(true);
            mTxt_ten.dispose();
         }
         if(case_one)
         {
            case_one.removeFromParent(true);
            case_one.dispose();
         }
         if(case_ten)
         {
            case_ten.removeFromParent(true);
            case_ten.dispose();
         }
         if(bgOne)
         {
            bgOne.removeFromParent(true);
            bgOne.dispose();
         }
         if(bgTen)
         {
            bgTen.removeFromParent(true);
            bgTen.dispose();
         }
         if(currentGold)
         {
            currentGold.removeFromParent(true);
            currentGold.dispose();
         }
         if(_bgBottom)
         {
            _bgBottom.removeFromParent(true);
            _bgBottom.dispose();
         }
         if(infoBottom)
         {
            infoBottom.removeFromParent(true);
            infoBottom.dispose();
         }
         if(mTxt_buy)
         {
            mTxt_buy.removeFromParent(true);
            mTxt_buy.dispose();
         }
         if(buyOne_pay)
         {
            buyOne_pay.removeFromParent(true);
            buyOne_pay.dispose();
         }
         if(buyTen_pay)
         {
            buyTen_pay.removeFromParent(true);
            buyTen_pay.dispose();
         }
         if(_wordA_bg)
         {
            _wordA_bg.removeFromParent(true);
            _wordA_bg.dispose();
         }
         if(_wordB_bg)
         {
            _wordB_bg.removeFromParent(true);
            _wordB_bg.dispose();
         }
         if(mImgBg)
         {
            mImgBg.removeFromParent(true);
            mImgBg.dispose();
         }
         if(buyAgain)
         {
            buyAgain.removeFromParent(true);
            buyAgain.dispose();
         }
         if(buyOk)
         {
            buyOk.removeFromParent(true);
            buyOk.dispose();
         }
         if(needNum)
         {
            needNum.removeFromParent(true);
            needNum.dispose();
         }
         if(m_light_bg)
         {
            m_light_bg.removeFromParent(true);
            m_light_bg.dispose();
         }
         if(mBoxSpriteOne)
         {
            mBoxSpriteOne.removeFromParent(true);
            mBoxSpriteOne.dispose();
         }
         if(mBoxSpriteTen)
         {
            mBoxSpriteTen.removeFromParent(true);
            mBoxSpriteTen.dispose();
         }
         if(_tween)
         {
            Starling.juggler.remove(_tween);
         }
         if(oneIcon)
         {
            oneIcon.removeFromParent(true);
            oneIcon.dispose();
         }
         if(tenIcon)
         {
            tenIcon.removeFromParent(true);
            tenIcon.dispose();
         }
         if(mBoxSpriteIconTen)
         {
            mBoxSpriteIconTen.removeFromParent(true);
            mBoxSpriteIconTen.dispose();
         }
         mBoxSpriteIconTen = null;
         quad_one = null;
         quad_ten = null;
         mTxt_one = null;
         mTxt_ten = null;
         case_one = null;
         case_ten = null;
         bgOne = null;
         bgTen = null;
         currentGold = null;
         _bgBottom = null;
         infoBottom = null;
         mTxt_buy = null;
         buyOne_pay = null;
         buyTen_pay = null;
         _wordA_bg = null;
         _wordB_bg = null;
         mImgBg = null;
         buyAgain = null;
         buyOk = null;
         needNum = null;
         m_light_bg = null;
         mBoxSpriteOne = null;
         mBoxSpriteTen = null;
         _tween = null;
         iconStartArr = null;
         oneIcon = null;
         tenIcon = null;
         StarlingTools.removeChildrenClear(this);
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(97049));
         GlobalData.$mEventDispatcher.addEventListener("update_groupon_buy_coin",upDataGold);
         cfg = GlobalData.$mConfig_ploy_system_simple.groupon;
         money = cfg.coin;
         case_one = GlobalFunction.createScale9Image("UI_bg_box_0_0000",260,330,new Rectangle(30,30,30,30));
         case_one.x = this.mImg9_baseBg.width / 2 - case_one.width - 10;
         case_one.y = this.mImg9_baseBg.y + 120;
         addChild(case_one);
         case_ten = GlobalFunction.createScale9Image("UI_bg_box_0_0000",260,330,new Rectangle(30,30,30,30));
         case_ten.x = this.mImg9_baseBg.width / 2 + 10;
         case_ten.y = case_one.y;
         addChild(case_ten);
         bgOne = GlobalFunction.createImage("UI_bg_colorbottom_1_0000");
         bgOne.x = case_one.x + 13;
         bgOne.y = case_one.y + 12;
         bgOne.width = 234;
         bgOne.height = 304;
         bgOne.touchable = false;
         addChild(bgOne);
         quad_one = Tools.newQuad(bgOne.width,bgOne.height,bgOne.x,bgOne.y,0);
         quad_one.alpha = 0;
         addChild(quad_one);
         quad_one.addEventListener("touch",quadoneTouch);
         bgTen = GlobalFunction.createImage("UI_bg_colorbottom_1_0000");
         bgTen.x = case_ten.x + 13;
         bgTen.y = case_ten.y + 12;
         bgTen.width = 234;
         bgTen.height = 304;
         bgTen.touchable = false;
         addChild(bgTen);
         quad_ten = Tools.newQuad(bgTen.width,bgTen.height,bgTen.x,bgTen.y,0);
         quad_ten.alpha = 0;
         addChild(quad_ten);
         quad_ten.addEventListener("touch",quadtenTouch);
         mTxt_one = new LOL_TextField(GlobalLanguageStr.getLanguageStr(97045),200,40);
         mTxt_one.fontSize = 20;
         mTxt_one.fontColor = 16777215;
         mTxt_one.shadowFilter();
         mTxt_one.x = bgOne.x + 10;
         mTxt_one.y = this.mImg9_baseBg.y + 135;
         mTxt_one.hAlign = "left";
         mTxt_one.touchable = false;
         addChild(mTxt_one);
         mTxt_ten = new LOL_TextField(GlobalLanguageStr.getLanguageStr(97046),200,40);
         mTxt_ten.fontSize = 20;
         mTxt_ten.fontColor = 16777215;
         mTxt_ten.shadowFilter();
         mTxt_ten.x = bgTen.x + 10;
         mTxt_ten.y = mTxt_one.y;
         mTxt_ten.hAlign = "left";
         mTxt_ten.touchable = false;
         addChild(mTxt_ten);
         var _loc3_:Array = GlobalData.$mConfig_simple.show_avatar;
         var _loc7_:Array = _loc3_[3];
         var _loc2_:Rectangle = new Rectangle(0,0,234,304);
         var _loc9_:Image = GameMapTools.newAvatarImgById(_loc7_[0],120,160);
         var _loc5_:Sprite = new Sprite();
         _loc5_.addChild(_loc9_);
         _loc5_.clipRect = _loc2_;
         _loc5_.x = case_one.x + 13;
         _loc5_.y = case_one.y + 12;
         _loc5_.touchable = false;
         _loc9_.scaleX = _loc9_.scaleY = 0.85;
         addChild(_loc5_);
         var _loc8_:Image = GameMapTools.newAvatarImgById(_loc7_[1],120,160);
         var _loc6_:Sprite = new Sprite();
         _loc6_.addChild(_loc8_);
         _loc6_.clipRect = _loc2_;
         _loc6_.x = case_ten.x + 13;
         _loc6_.y = case_ten.y + 12;
         _loc6_.touchable = false;
         _loc8_.scaleX = _loc8_.scaleY = 0.85;
         addChild(_loc6_);
         _wordA_bg = GlobalFunction.createImage("UI_wordbg_yellow_0_0000");
         _wordA_bg.x = case_one.x + (case_one.width - _wordA_bg.width) * 0.5;
         _wordA_bg.y = case_one.y + case_one.height * 0.65 + 35;
         _wordA_bg.touchable = false;
         addChild(_wordA_bg);
         _wordB_bg = GlobalFunction.createImage("UI_wordbg_yellow_0_0000");
         _wordB_bg.x = case_ten.x + (case_ten.width - _wordB_bg.width) * 0.5;
         _wordB_bg.y = case_ten.y + case_ten.height * 0.65 + 35;
         _wordB_bg.touchable = false;
         addChild(_wordB_bg);
         oneIcon = GlobalFunction.createImage("UI_icon_fragment_0000");
         oneIcon.x = mTxt_one.x + 190;
         oneIcon.y = mTxt_one.y - 5;
         addChild(oneIcon);
         tenIcon = GlobalFunction.createImage("UI_icon_fragment_0000");
         tenIcon.x = mTxt_ten.x + 190;
         tenIcon.y = mTxt_ten.y - 5;
         addChild(tenIcon);
         var _loc4_:Number = Number(cfg.coin);
         buyOne_pay = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20394,_loc4_),20,1118481,"center",160,35);
         buyOne_pay.x = case_one.x + (case_one.width - buyOne_pay.width) * 0.5;
         buyOne_pay.y = _wordA_bg.y;
         addChild(buyOne_pay);
         buyTen_pay = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20394,_loc4_ * 10 * 0.9),20,1118481,"center",160,35);
         buyTen_pay.x = case_ten.x + (case_ten.width - buyTen_pay.width) * 0.5;
         buyTen_pay.y = buyOne_pay.y;
         addChild(buyTen_pay);
         currentGold = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getLanguageStr(90494),GlobalData.$userData.coin,"UI_money_coin_0_0000",16777215,16777215);
         currentGold.x = case_one.x;
         currentGold.y = case_one.y + case_one.height + 20;
         addChild(currentGold);
         _bgBottom = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",560,169,new Rectangle(110,55,70,20));
         _bgBottom.x = int((GlobalData.$mStageWidth - _bgBottom.width) * 0.5);
         _bgBottom.y = this.mImg9_baseBg.y + this.mImg9_baseBg.height - _bgBottom.height - 30 - 5;
         addChild(_bgBottom);
         var _loc10_:String = HtmlTextFormat.font(GlobalLanguageStr.getLanguageStr(97653),4926491);
         infoBottom = new ScrollScreenForTxt(_loc10_,_bgBottom.width - 60,_bgBottom.height - 45);
         infoBottom.x = _bgBottom.x + 33;
         infoBottom.y = _bgBottom.y + 25;
         addChild(infoBottom);
         buyGift = [];
      }
      
      private function upDataGold() : void
      {
         currentGold.text(GlobalLanguageStr.getLanguageStr(90494),GlobalData.$userData.coin,"UI_money_coin_0_0000");
      }
      
      private function sendGrouponBuy(param1:Object, param2:Boolean) : void
      {
         var _self:* = this;
         var _vipBefore:int = int(GlobalData.$userData.vip_lv);
         if(param2)
         {
            SendServiceAMFFun.send_user_groupon_buy(function(response:Object):void
            {
               _self.refun(response,_vipBefore);
            },param1);
         }
         else
         {
            SendServiceAMFFun.send_user_groupon_buy(function(response:Object):void
            {
               _self.reService(response,_vipBefore);
            },param1);
         }
      }
      
      private function quadoneTouch(param1:TouchEvent) : void
      {
         var _loc4_:Object = null;
         var _loc2_:String = null;
         price = cfg.coin;
         var _loc3_:Touch = param1.getTouch(this);
         if(_loc3_ && _loc3_.phase == "ended")
         {
            if(GlobalData.$userData.coin >= price)
            {
               sendGrouponBuy({"num":1},false);
            }
            else
            {
               _loc4_ = {
                  "ok":gotoCoin,
                  "no":GlobalFunction.functionNull,
                  "aid":"A_2009_5"
               };
               _loc2_ = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90051,price),GlobalTextStyle.COLOR_W_Y_Y_G);
               GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(90010),_loc2_,_loc4_);
            }
         }
      }
      
      private function quadtenTouch(param1:TouchEvent) : void
      {
         var _loc4_:Object = null;
         var _loc2_:String = null;
         var _loc3_:Touch = param1.getTouch(this);
         if(_loc3_ && _loc3_.phase == "ended")
         {
            price = cfg.coin;
            if(GlobalData.$userData.coin >= price * 10 * 0.9)
            {
               sendGrouponBuy({"num":10},true);
            }
            else
            {
               _loc4_ = {
                  "ok":gotoCoin,
                  "no":GlobalFunction.functionNull,
                  "aid":"A_2009_5"
               };
               _loc2_ = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90051,price * 10 * 0.9),GlobalTextStyle.COLOR_W_Y_Y_G);
               GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(90010),_loc2_,_loc4_);
            }
         }
      }
      
      private function gotoCoin() : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_pay",false,true);
      }
      
      private function refun(param1:Object, param2:int = -1) : void
      {
         if(stage == null)
         {
            return;
         }
         var _loc4_:Object = null;
         var _loc2_:String = null;
         var _loc3_:Object = null;
         var _loc5_:String = "getAvatar";
         SoundManager.getOnlyExample().playSound(_loc5_);
         var _loc6_:Object = param1.data;
         buyGift = _loc6_.buy_gift;
         _loc4_ = _loc6_.new_avatar_soul;
         for(_loc2_ in _loc4_)
         {
            _loc3_ = GlobalData.$userData.avatar_soul;
            _loc3_[_loc2_] = _loc4_[_loc2_];
         }
         _loc4_ = _loc6_.new_equip_soul;
         for(_loc2_ in _loc4_)
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.equip_soul[_loc2_] = _loc4_[_loc2_];
            }
         }
         var _oldVip:int = param2 >= 0 ? param2 : int(GlobalData.$userData.vip_lv);
         if(int(_loc6_.vip_lv) > _oldVip && (!GlobalFunction.isVersionedProfileReceipt(param1) || int(GlobalData.$userData.vip_lv) == int(_loc6_.vip_lv)))
         {
            GlobalFunction.popAward("_$vip$_",GlobalLanguageStr.getLanguageStr(20203,_loc6_.vip_lv),_loc6_.vip_lv);
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.vip_exp = _loc6_.vip_exp;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.vip_lv = _loc6_.vip_lv;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.coin = _loc6_.coin;
         }
         GlobalFunction.updateVip();
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
         upDataGold();
         if(mBoxSpriteTen == null)
         {
            mBoxSpriteTen = new Sprite();
            addChild(mBoxSpriteTen);
            mImgBg = GlobalFunction.createImage("pic_groupBuy_bg_",true);
            mImgBg.width = GlobalData.$mStageWidth;
            mImgBg.height = GlobalData.$mStageHeight;
            if(GlobalData.$mStageHeight > 960)
            {
               mImgBg.y = this.mImg9_baseBg.y - 150;
            }
            else
            {
               mImgBg.y = this.mImg9_baseBg.y - 70;
            }
            mImgBg.alpha = 1;
            mBoxSpriteTen.addChild(mImgBg);
            buyAgain = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(97052),150,70,"UI_btn_normalFun_0000");
            buyAgain.x = GlobalData.$mStageWidth * 0.5 - buyAgain.width - 28;
            buyAgain.y = GlobalData.$mStageHeight * 0.5 + buyAgain.height + 30;
            mBoxSpriteTen.addChild(buyAgain);
            buyAgain.addEventListener("triggered",buyAgainTenTriggered);
            buyOk = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20021),150,70,"UI_btn_normalFun_0000");
            buyOk.x = GlobalData.$mStageWidth * 0.5 + 30;
            buyOk.y = buyAgain.y;
            mBoxSpriteTen.addChild(buyOk);
            buyOk.addEventListener("triggered",buyOkTenTriggered);
            mTxt_buy = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97639),20,16777215,"left",800,46);
            mTxt_buy.x = GlobalData.$mStageWidth / 2 - 148;
            mTxt_buy.y = this.mImg9_baseBg.y + 85;
            mBoxSpriteTen.addChild(mTxt_buy);
            needNum = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getLanguageStr(90493),String(money * 10 * 0.9),"UI_money_coin_0_0000",16777215,16777215);
            needNum.x = buyAgain.x;
            needNum.y = buyAgain.y + buyAgain.height + 5;
            mBoxSpriteTen.addChild(needNum);
         }
         GlobalData.$mEventDispatcher.dispatchEventWith("update_group_buy",false,param1.data);
         addTenIcon(_loc6_);
      }
      
      private function addTenIcon(param1:Object) : void
      {
         var _loc5_:String = null;
         var _loc11_:* = undefined;
         var _loc4_:Object = null;
         var _loc7_:int = 0;
         var _loc2_:Array = null;
         var _loc3_:String = null;
         var _loc8_:DisplayObject = null;
         var _loc15_:Image = null;
         var _loc13_:Number = NaN;
         var _loc9_:Tween = null;
         mBoxSpriteIconTen = new Sprite();
         this.addChild(mBoxSpriteIconTen);
         var _loc12_:int = 80;
         var _loc14_:Number = 0;
         buyTenBg = [];
         buyTenBgTween = [];
         iconStartArr = [];
         _loc7_ = 0;
         while(_loc7_ < buyGift.length)
         {
            for(var _loc6_:Object in param1.buy_gift[_loc7_])
            {
               _loc5_ = _loc6_.toString();
               _loc11_ = param1.buy_gift[_loc7_][_loc5_];
               for(var _loc10_ in _loc11_)
               {
                  _loc2_ = String(_loc10_).split("_");
                  _loc3_ = _loc2_[2];
               }
               iconStartArr.push(_loc3_);
            }
            _loc4_ = GlobalFunction.getAwardByType(_loc5_,_loc11_,false,null,"",true);
            _loc8_ = _loc4_.ui;
            _loc8_.y = int(_loc7_ / 5) * 220;
            _loc8_.x = _loc7_ % 5 * 122 + _loc12_;
            _loc8_.y += 250;
            _loc8_.pivotX += _loc8_.width / 2;
            _loc8_.pivotY += _loc8_.height / 2;
            if(_loc5_ == "avatar_soul")
            {
               _loc8_.y += 10;
            }
            _loc8_.visible = false;
            if(int(iconStartArr[_loc7_]) > 4)
            {
               _loc15_ = GlobalFunction.createImage("UI_card_effect",true);
               _loc15_.pivotY = _loc15_.height * 0.5;
               _loc15_.pivotX = _loc15_.width * 0.5;
               _loc15_.scaleX = _loc15_.scaleY = 1.5;
               _loc15_.touchable = false;
               _loc15_.visible = false;
               _loc15_.scaleX = _loc15_.scaleY = 0.7;
               mBoxSpriteIconTen.addChild(_loc15_);
               if(iconStartArr[_loc7_] == 5)
               {
                  _loc15_.blendMode = Tools.getBlendMode(null,1,0.5,1.9);
               }
               else if(iconStartArr[_loc7_] == 6)
               {
                  _loc15_.blendMode = Tools.getBlendMode(null,1,1,1);
               }
               _loc13_ = 1.2;
               _loc9_ = new Tween(_loc15_,_loc13_ * 2000);
               _loc9_.animate("rotation",3.141592653589793 * 200);
               Starling.juggler.add(_loc9_);
               buyTenBg.push(_loc15_);
               buyTenBgTween.push(_loc9_);
               buyTenBg[_loc7_].x = _loc8_.x;
               buyTenBg[_loc7_].y = _loc8_.y;
               if(_loc5_ == "avatar_soul")
               {
                  _loc15_.y -= 10;
               }
               onIconMoveFun(_loc8_.x,_loc8_.y,_loc8_,_loc14_,buyTenBg[_loc7_]);
            }
            else
            {
               buyTenBg.push(null);
               onIconMoveFun(_loc8_.x,_loc8_.y,_loc8_,_loc14_);
            }
            mBoxSpriteIconTen.addChild(_loc8_);
            _loc14_ += 0.1;
            _loc7_++;
         }
         iconStartArr = null;
      }
      
      private function onIconMoveFun(param1:Number, param2:Number, param3:DisplayObject, param4:Number, param5:Image = null) : void
      {
         param3.x = GlobalData.$mStageWidth * 0.5;
         param3.y = mTxt_buy.y;
         param3.scaleX = param3.scaleY = 0;
         var _loc6_:Tween = new Tween(param3,0.3);
         _loc6_.animate("x",param1);
         _loc6_.animate("y",param2);
         _loc6_.animate("rotation",3.141592653589793 * 2);
         _loc6_.animate("scaleX",1);
         _loc6_.animate("scaleY",1);
         _loc6_.delay = param4;
         _loc6_.onStart = onStart;
         if(param5)
         {
            _loc6_.onComplete = icondelayCom;
            _loc6_.onCompleteArgs = [param5];
         }
         _loc6_.onStartArgs = [param3];
         Starling.juggler.add(_loc6_);
      }
      
      private function icondelayCom(param1:Image) : void
      {
         if(param1)
         {
            param1.visible = true;
         }
      }
      
      private function onStart(param1:DisplayObject) : void
      {
         param1.visible = true;
      }
      
      private function buyAgainTenTriggered(param1:Event) : void
      {
         var _loc3_:Object = null;
         var _loc2_:String = null;
         price = cfg.coin;
         if(GlobalData.$userData.coin >= price * 10 * 0.9)
         {
            removeTenIcon();
            sendGrouponBuy({"num":10},true);
         }
         else
         {
            _loc3_ = {
               "ok":gotoCoin,
               "no":GlobalFunction.functionNull,
               "aid":"A_2009_5"
            };
            _loc2_ = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90051,price * 10 * 0.9),GlobalTextStyle.COLOR_W_Y_Y_G);
            GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(90010),_loc2_,_loc3_);
         }
      }
      
      private function removeTenIcon() : void
      {
         var _loc1_:Image = null;
         var _loc2_:Tween = null;
         if(mBoxSpriteIconTen)
         {
            while(buyTenBg.length > 0)
            {
               _loc1_ = buyTenBg.pop();
               if(_loc1_)
               {
                  _loc1_.removeFromParent(true);
                  _loc1_.dispose();
                  _loc1_ = null;
               }
               _loc2_ = buyTenBgTween.pop();
               if(_loc2_)
               {
                  Starling.juggler.remove(_loc2_);
               }
               _loc2_ = null;
            }
            buyTenBg = null;
            StarlingTools.removeChildrenClear(mBoxSpriteIconTen);
            mBoxSpriteIconTen = null;
         }
      }
      
      private function buyOkTenTriggered(param1:Event) : void
      {
         removeTenBg();
         removeTenIcon();
      }
      
      private function removeTenBg() : void
      {
         if(mImgBg)
         {
            mImgBg.removeFromParent(true);
            mImgBg.dispose();
         }
         if(buyAgain)
         {
            buyAgain.removeFromParent(true);
            buyAgain.dispose();
         }
         if(buyOk)
         {
            buyOk.removeFromParent(true);
            buyOk.dispose();
         }
         if(mTxt_buy)
         {
            mTxt_buy.removeFromParent(true);
            mTxt_buy.dispose();
         }
         if(needNum)
         {
            needNum.removeFromParent(true);
            needNum.dispose();
         }
         StarlingTools.removeChildrenClear(mBoxSpriteTen);
         mBoxSpriteTen = null;
      }
      
      private function reService(param1:Object, param2:int = -1) : void
      {
         if(stage == null)
         {
            return;
         }
         var _loc3_:Object = null;
         var _loc2_:String = null;
         var _loc4_:String = "drop";
         SoundManager.getOnlyExample().playSound(_loc4_);
         var _loc5_:Object = param1.data;
         buyGift = _loc5_.buy_gift;
         _loc3_ = _loc5_.new_avatar_soul;
         for(_loc2_ in _loc3_)
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.avatar_soul[_loc2_] = _loc3_[_loc2_];
            }
         }
         _loc3_ = _loc5_.new_equip_soul;
         for(_loc2_ in _loc3_)
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.equip_soul[_loc2_] = _loc3_[_loc2_];
            }
         }
         var _oldVip:int = param2 >= 0 ? param2 : int(GlobalData.$userData.vip_lv);
         if(int(_loc5_.vip_lv) > _oldVip && (!GlobalFunction.isVersionedProfileReceipt(param1) || int(GlobalData.$userData.vip_lv) == int(_loc5_.vip_lv)))
         {
            GlobalFunction.popAward("_$vip$_",GlobalLanguageStr.getLanguageStr(20203,_loc5_.vip_lv),_loc5_.vip_lv);
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.vip_exp = _loc5_.vip_exp;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.vip_lv = _loc5_.vip_lv;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.coin = _loc5_.coin;
         }
         GlobalFunction.updateVip();
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
         upDataGold();
         if(mBoxSpriteOne == null)
         {
            mBoxSpriteOne = new Sprite();
            addChild(mBoxSpriteOne);
            mImgBg = GlobalFunction.createImage("pic_groupBuy_bg_",true);
            mImgBg.width = GlobalData.$mStageWidth;
            mImgBg.height = GlobalData.$mStageHeight;
            if(GlobalData.$mStageHeight > 960)
            {
               mImgBg.y = this.mImg9_baseBg.y - 150;
            }
            else
            {
               mImgBg.y = this.mImg9_baseBg.y - 70;
            }
            mBoxSpriteOne.addChild(mImgBg);
            mTxt_buy = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97639),20,16777215,"left",800,46);
            mTxt_buy.x = GlobalData.$mStageWidth / 2 - 148;
            mTxt_buy.y = this.mImg9_baseBg.y + 85;
            mBoxSpriteOne.addChild(mTxt_buy);
            buyAgain = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(97051),150,70,"UI_btn_normalFun_0000");
            buyAgain.x = GlobalData.$mStageWidth * 0.5 - buyAgain.width - 28;
            buyAgain.y = GlobalData.$mStageHeight * 0.5 + buyAgain.height + 30;
            mBoxSpriteOne.addChild(buyAgain);
            buyAgain.addEventListener("triggered",buyAgainOneTriggered);
            buyOk = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20021),150,70,"UI_btn_normalFun_0000");
            buyOk.x = GlobalData.$mStageWidth * 0.5 + 30;
            buyOk.y = buyAgain.y;
            mBoxSpriteOne.addChild(buyOk);
            buyOk.addEventListener("triggered",buyOkOneTriggered);
            needNum = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getLanguageStr(90493),String(money),"UI_money_coin_0_0000",16777215,16777215);
            needNum.x = buyAgain.x;
            needNum.y = buyAgain.y + buyAgain.height + 5;
            mBoxSpriteOne.addChild(needNum);
         }
         GlobalData.$mEventDispatcher.dispatchEventWith("update_group_buy",false,param1.data);
         addOneIcon(_loc5_);
      }
      
      private function removeOneIcon() : void
      {
         if(m_light_bg)
         {
            m_light_bg.removeFromParent(true);
            m_light_bg.dispose();
         }
         if(_tween)
         {
            Starling.juggler.remove(_tween);
         }
         if(_ui)
         {
            _ui.removeFromParent(true);
            _ui.dispose();
         }
         _ui = null;
         _tween = null;
         m_light_bg = null;
      }
      
      private function addOneIcon(param1:Object) : void
      {
         var _loc5_:String = null;
         var _loc2_:* = undefined;
         var _loc3_:Object = null;
         var _loc7_:int = 0;
         var _loc6_:Number = 1.2;
         m_light_bg = GlobalFunction.createImage("UI_card_effect",true);
         m_light_bg.pivotY = m_light_bg.height * 0.5;
         m_light_bg.pivotX = m_light_bg.width * 0.5;
         m_light_bg.scaleX = m_light_bg.scaleY = 1.5;
         m_light_bg.x = GlobalData.$mStageWidth * 0.5;
         m_light_bg.y = GlobalData.$mStageHeight * 0.5 - 150;
         m_light_bg.touchable = false;
         m_light_bg.visible = false;
         mBoxSpriteOne.addChild(m_light_bg);
         _tween = new Tween(m_light_bg,_loc6_ * 2000);
         _tween.animate("rotation",3.141592653589793 * 200);
         Starling.juggler.add(_tween);
         _loc7_ = 0;
         while(_loc7_ < buyGift.length)
         {
            for(var _loc4_:Object in param1.buy_gift[_loc7_])
            {
               _loc5_ = _loc4_.toString();
               _loc2_ = param1.buy_gift[_loc7_][_loc5_];
            }
            _loc3_ = GlobalFunction.getAwardByType(_loc5_,_loc2_,false,null,"",true);
            _ui = _loc3_.ui;
            _ui.x = m_light_bg.x;
            _ui.y = m_light_bg.y + 10;
            mBoxSpriteOne.addChild(_ui);
            _loc7_++;
         }
         _ui.pivotX = _ui.width / 2;
         _ui.pivotY = _ui.height / 2;
         _ui.visible = false;
         onIconMoveFun(_ui.x,_ui.y,_ui,0,m_light_bg);
      }
      
      private function buyAgainOneTriggered(param1:Event) : void
      {
         var _loc3_:Object = null;
         var _loc2_:String = null;
         removeOneIcon();
         price = cfg.coin;
         if(GlobalData.$userData.coin >= price)
         {
            sendGrouponBuy({"num":1},false);
         }
         else
         {
            _loc3_ = {
               "ok":gotoCoin,
               "no":GlobalFunction.functionNull,
               "aid":"A_2009_5"
            };
            _loc2_ = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90051,price),GlobalTextStyle.COLOR_W_Y_Y_G);
            GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(90010),_loc2_,_loc3_);
         }
      }
      
      private function buyOkOneTriggered(param1:Event) : void
      {
         if(m_light_bg)
         {
            m_light_bg.removeFromParent(true);
            m_light_bg.dispose();
         }
         if(_ui)
         {
            _ui.removeFromParent(true);
            _ui.dispose();
         }
         if(mImgBg)
         {
            mImgBg.removeFromParent(true);
            mImgBg.dispose();
         }
         if(mTxt_buy)
         {
            mTxt_buy.removeFromParent(true);
            mTxt_buy.dispose();
         }
         if(buyAgain)
         {
            buyAgain.removeFromParent(true);
            buyAgain.dispose();
         }
         if(buyOk)
         {
            buyOk.removeFromParent(true);
            buyOk.dispose();
         }
         if(needNum)
         {
            needNum.removeFromParent(true);
            needNum.dispose();
         }
         if(mBoxSpriteOne)
         {
            StarlingTools.removeChildrenClear(mBoxSpriteOne);
         }
         mBoxSpriteOne = null;
         m_light_bg = null;
         _ui = null;
         mImgBg = null;
         mTxt_buy = null;
         buyAgain = null;
         buyOk = null;
         needNum = null;
      }
   }
}

