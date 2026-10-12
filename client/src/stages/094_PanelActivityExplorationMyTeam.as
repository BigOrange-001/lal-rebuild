package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.element.ItemExplorationSelectTeam;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelCenterMainAvatar;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.data.ListCollection;
   import feathers.display.Scale9Image;
   import feathers.layout.TiledRowsLayout;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import starling.animation.Tween;
   import starling.core.Starling;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class PanelActivityExplorationMyTeam extends PanelCenterMainAvatar
   {
      
      public static var cloneArray:Array;
      
      private var mAvt_spr:Sprite;
      
      private var mOppAvt_spr:Sprite;
      
      private var mAvt_arr:Array;
      
      private var mOppAvt_arr:Array;
      
      private var mGoBattle_btn:LOL_Scale9Button;
      
      private var mFresh_btn:LOL_Scale9Button;
      
      private var mBg:Scale9Image;
      
      private var mQuad:Quad;
      
      private var mInfo_spr:Sprite;
      
      private var mInfo_icon:Image;
      
      private const GO_BTN_NAME:String = "go_btn_name";
      
      private const FRESH_BTN_NAME:String = "fresh_btn_name";
      
      private const MOVEFROMTEAM:String = "movefromteam";
      
      private const CONSTSCALE:Number = 1;
      
      private const _gap:int = 20;
      
      private const _avt_w:int = 90;
      
      private const TOPDIS:int = 80;
      
      private var mirror_data:Object = {};
      
      private var _payGold:int = 0;
      
      private var _tw:Tween;
      
      private var mGlodSpend_spr:LOL_MutilTextFieldIcon;
      
      private var mFreshInfo_txt:TextField;
      
      private var mMyName:TextField;
      
      private var mPower_txt:TextField;
      
      private var mOppName:TextField;
      
      private var mOppPower_txt:TextField;
      
      private var mBuff_spr:Sprite;
      
      private var mBuff_bg:Image;
      
      private var mBuff_txt:TextField;
      
      public function PanelActivityExplorationMyTeam(param1:Object = null)
      {
         var _loc2_:Array = GlobalData.$userData.exploration.combat_army;
         cloneArray = (GlobalData.$userData.exploration.combat_army as Array).concat();
         mirror_data = param1;
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         GlobalData.$mEventDispatcher.addEventListener("select_exploration_select_avatar",onSELECT_AVATAR_DATA);
         GlobalData.$mEventDispatcher.addEventListener("set_start_exploration_pro_avatar",onSET_START_EXPLORATION_PRO_AVATAR);
         var _loc3_:int = int(GlobalData.$userData.exploration.stage);
         var _loc5_:int = int(GlobalData.$mConfig_simple.explore.map_max);
         var _loc2_:int = _loc3_ <= _loc5_ ? _loc3_ : _loc5_;
         var _loc4_:String = GlobalLanguageStr.getLanguageStr(90660,_loc2_);
         this.setPopPanelBg(_loc4_,GlobalData.$center_height + 200);
         setUI();
      }
      
      private function onSET_START_EXPLORATION_PRO_AVATAR(param1:Event) : void
      {
         var _loc7_:Rectangle = null;
         var _loc2_:AvatarImg = null;
         var _loc6_:Point = null;
         var _loc9_:Point = null;
         var _loc10_:Object = param1.data;
         var _loc8_:String = _loc10_.data;
         var _loc4_:Boolean = Boolean(_loc10_.isSelect);
         var _loc5_:Number = Number(_loc10_.self_power);
         var _loc3_:Object = GlobalData.$userData.exploration.army;
         if(_loc4_)
         {
            if(Tools.getArrayLength(GlobalData.$exploration_team_avatar) < 3)
            {
               for(var _loc11_:String in _loc3_)
               {
                  if(_loc11_ == _loc8_)
                  {
                     GlobalData.$exploration_drag = _loc10_.item;
                     _loc7_ = GlobalData.$exploration_drag.getBounds(this);
                     _loc2_ = new AvatarImg(_loc8_,_loc3_[_loc11_]);
                     _loc2_.name = _loc8_;
                     _loc2_.scaleX = _loc2_.scaleY = 1;
                     _loc6_ = getXY(_loc11_);
                     _loc9_ = new Point(_loc6_.x - 100,_loc6_.y + 200);
                     _loc2_.point = _loc9_;
                     _loc2_.self_power = _loc5_;
                     _loc2_.x = _loc6_.x;
                     _loc2_.y = _loc6_.y;
                     pushInTeamArray(_loc2_);
                     this.addChild(_loc2_);
                  }
               }
            }
         }
      }
      
      private function onSTART_EXPLORATION_DRAG(param1:Event) : void
      {
         var _loc3_:* = null;
         var _loc2_:* = null;
         var _loc4_:* = null;
         var _loc5_:Object = param1.data;
      }
      
      private function onSELECT_AVATAR_DATA(param1:Event) : void
      {
         var _loc4_:* = undefined;
         var _loc12_:Rectangle = null;
         var _loc2_:AvatarImg = null;
         var _loc5_:Point = null;
         var _loc7_:Point = null;
         var _loc11_:Tween = null;
         var _loc13_:Object = param1.data;
         var _loc6_:String = _loc13_.data;
         var _loc9_:Boolean = Boolean(_loc13_.isSelect);
         var _loc3_:Number = Number(_loc13_.self_power);
         var _loc10_:Object = GlobalData.$userData.exploration.army;
         if(_loc9_)
         {
            if(checkIsHadAndPushOut(_loc6_))
            {
               return;
            }
            if(Tools.getArrayLength(GlobalData.$exploration_team_avatar) < 3)
            {
               for(var _loc8_:String in _loc10_)
               {
                  if(_loc8_ == _loc6_)
                  {
                     _loc4_ = GlobalData.$exploration_drag;
                     _loc12_ = GlobalData.$exploration_drag.getBounds(this);
                     _loc2_ = new AvatarImg(_loc6_,_loc10_[_loc8_]);
                     _loc2_.x = _loc12_.x;
                     _loc2_.y = _loc12_.y;
                     _loc2_.name = _loc6_;
                     _loc5_ = getXY(_loc8_);
                     _loc7_ = new Point(_loc12_.x,_loc12_.y);
                     _loc2_.point = _loc7_;
                     _loc2_.self_power = _loc3_;
                     _loc11_ = new Tween(_loc2_,0.1);
                     _loc11_.moveTo(_loc5_.x,_loc5_.y);
                     _loc11_.scaleTo(1);
                     _loc11_.onStartArgs = [_loc2_];
                     _loc11_.onStart = pushInTeamArray;
                     Starling.juggler.add(_loc11_);
                     this.addChild(_loc2_);
                  }
               }
            }
         }
         else
         {
            if(checkIsHadAndPushOut(_loc6_))
            {
               return;
            }
            if(Tools.getArrayLength(GlobalData.$exploration_team_avatar) >= 3)
            {
               LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getStr(90574));
            }
         }
      }
      
      private function pushInTeamArray(... rest) : void
      {
         var _loc2_:* = null;
         var _loc5_:* = null;
         var _loc3_:* = 0;
         var _loc7_:int = 0;
         (rest[0] as AvatarImg).item = GlobalData.$exploration_drag;
         var _loc6_:Array = GlobalData.$exploration_team_avatar;
         var _loc4_:int = int(_loc6_.length);
         if(_loc4_ != Tools.getArrayLength(_loc6_))
         {
            _loc7_ = 0;
            while(_loc7_ < _loc4_)
            {
               if(_loc6_[_loc7_] == null)
               {
                  _loc3_ = _loc7_;
                  break;
               }
               _loc7_++;
            }
         }
         else
         {
            _loc3_ = _loc4_;
         }
         _loc7_ = 0;
         while(_loc7_ < cloneArray.length)
         {
            if(rest[0].name == cloneArray[_loc7_])
            {
               _loc3_ = _loc7_;
               break;
            }
            _loc7_++;
         }
         GlobalData.$exploration_team_avatar[_loc3_] = rest[0];
         cloneArray[_loc3_] = rest[0].name;
         GlobalData.$exploration_drag = null;
         updatePower();
      }
      
      private function checkIsHadAndPushOut(param1:String) : Boolean
      {
         var _spr:AvatarImg;
         var _tween:Tween;
         var _x:Number;
         var _y:Number;
         var _aid:String = param1;
         var _b:Boolean = false;
         var _arr:Array = GlobalData.$exploration_team_avatar;
         var j:int = 0;
         while(j < _arr.length)
         {
            if(_arr[j] != null)
            {
               if((_arr[j] as Sprite).name == _aid)
               {
                  _spr = GlobalData.$exploration_team_avatar[j];
                  GlobalData.$exploration_team_avatar[j] = null;
                  cloneArray[j] = null;
                  _tween = new Tween(_spr,0.3);
                  _x = (_spr.point.x + _spr.x) * 0.5;
                  _y = (_spr.point.y + _spr.y) * 0.5;
                  _tween.moveTo(_x,_y);
                  _tween.fadeTo(0);
                  _tween.onStartArgs = [_spr];
                  _tween.onStart = function(... rest):void
                  {
                     (rest[0] as AvatarImg).touchable = false;
                     updatePower();
                  };
                  _tween.onComplete = function():void
                  {
                     _spr.removeFromParent(true);
                     _spr = null;
                     _b = true;
                  };
                  Starling.juggler.add(_tween);
                  break;
               }
            }
            j = j + 1;
         }
         return _b;
      }
      
      private function getXY(param1:String) : Point
      {
         var _loc3_:Rectangle = null;
         var _loc5_:Point = null;
         var _loc2_:Boolean = false;
         var _loc8_:int = 0;
         var _loc7_:Boolean = false;
         _loc8_ = 0;
         while(_loc8_ < cloneArray.length)
         {
            if(cloneArray[_loc8_] != null)
            {
               _loc7_ = true;
               break;
            }
            _loc8_++;
         }
         if(!_loc7_)
         {
            cloneArray = [];
         }
         var _loc6_:Array = cloneArray;
         var _loc4_:int = int(_loc6_.length);
         if(_loc4_ != Tools.getArrayLength(_loc6_))
         {
            _loc2_ = false;
            _loc8_ = 0;
            while(_loc8_ < _loc4_)
            {
               if(_loc6_[_loc8_] != null && _loc6_[_loc8_] == param1)
               {
                  _loc3_ = mAvt_arr[_loc8_].getBounds(this);
                  return new Point(_loc3_.x,_loc3_.y);
               }
               if(_loc6_[_loc8_] == null)
               {
                  _loc2_ = true;
               }
               _loc8_++;
            }
            if(_loc2_)
            {
               _loc8_ = 0;
               while(_loc8_ < _loc4_)
               {
                  if(_loc6_[_loc8_] == null)
                  {
                     _loc3_ = mAvt_arr[_loc8_].getBounds(this);
                     _loc5_ = new Point(_loc3_.x,_loc3_.y);
                     break;
                  }
                  _loc8_++;
               }
            }
         }
         else if(_loc4_ == 0)
         {
            _loc3_ = mAvt_arr[_loc4_].getBounds(this);
            _loc5_ = new Point(_loc3_.x,_loc3_.y);
         }
         else if(_loc4_ == 3)
         {
            _loc8_ = 0;
            while(_loc8_ < _loc4_)
            {
               if(_loc6_[_loc8_] != null && _loc6_[_loc8_] == param1)
               {
                  _loc3_ = mAvt_arr[_loc8_].getBounds(this);
                  _loc5_ = new Point(_loc3_.x,_loc3_.y);
               }
               _loc8_++;
            }
         }
         else
         {
            _loc8_ = 0;
            while(_loc8_ < _loc4_)
            {
               if(_loc6_[_loc8_] != null && _loc6_[_loc8_] == param1)
               {
                  _loc3_ = mAvt_arr[_loc8_].getBounds(this);
                  _loc5_ = new Point(_loc3_.x,_loc3_.y);
                  break;
               }
               _loc3_ = mAvt_arr[_loc4_].getBounds(this);
               _loc5_ = new Point(_loc3_.x,_loc3_.y);
               _loc8_++;
            }
         }
         return _loc5_;
      }
      
      private function updatePower() : void
      {
         var _loc2_:int = 0;
         var _loc3_:Number = 0;
         var _loc1_:Array = GlobalData.$exploration_team_avatar;
         _loc2_ = 0;
         while(_loc2_ < _loc1_.length)
         {
            if(_loc1_[_loc2_] != null)
            {
               _loc3_ += (_loc1_[_loc2_] as AvatarImg).self_power;
            }
            _loc2_++;
         }
         mPower_txt.text = GlobalLanguageStr.getStr(90279) + Tools.formateNum(_loc3_);
      }
      
      private function setUI() : void
      {
         var _loc9_:int = 0;
         var _loc1_:AvatarImg = null;
         var _loc3_:Image = null;
         var _loc7_:TextField = null;
         mAvt_arr = [];
         mOppAvt_arr = [];
         GlobalData.$exploration_team_avatar = [];
         mBg = GlobalFunction.createScale9Image("UI_bg_9slice_4_0000",590,188,new Rectangle(40,30,30,30));
         mBg.x = this.mImg9_baseBg.x + (this.mImg9_baseBg.width - mBg.width) * 0.5;
         mBg.y = this.mImg9_baseBg.x + 80;
         this.addChild(mBg);
         mQuad = new Quad(590,160,590848);
         mQuad.alpha = 0.4;
         mQuad.x = mBg.x;
         mQuad.y = mBg.y + mBg.height + 10;
         this.addChild(mQuad);
         mOppAvt_spr = new Sprite();
         this.addChild(mOppAvt_spr);
         mOppName = GlobalFunction.createTextField(240,30,mirror_data.name,"",25,10027008);
         mOppName.x = mBg.x + 10;
         mOppName.y = mBg.y + 50;
         this.addChild(mOppName);
         var _loc2_:Array = mirror_data.army;
         _loc9_ = 0;
         while(_loc9_ < 3)
         {
            if(_loc9_ < _loc2_.length)
            {
               _loc1_ = new AvatarImg(_loc2_[_loc9_][0],_loc2_[_loc9_],2,true,mirror_data.is_npc);
               _loc1_.touchable = false;
               _loc1_.scaleX = _loc1_.scaleY = 1;
               _loc1_.x = (90 + 20) * _loc9_ - 20;
               mOppAvt_arr.push(_loc1_);
               this.mOppAvt_spr.addChild(_loc1_);
            }
            else
            {
               _loc3_ = GlobalFunction.createImage("UI_bg_card_2_0002");
               _loc3_.scaleX = _loc3_.scaleY = 1;
               _loc3_.x = (90 + 20) * _loc9_ - 20;
               this.mOppAvt_spr.addChild(_loc3_);
               _loc7_ = DisplayTools.newTextField("" + (_loc9_ + 1),"Font_numAndtag_1",40,16777215);
               _loc7_.pivotX = _loc7_.width * 0.5;
               _loc7_.pivotY = _loc7_.height * 0.5;
               _loc7_.x = _loc3_.x + _loc3_.width * 0.5;
               _loc7_.y = _loc3_.height * 0.5;
               this.mOppAvt_spr.addChild(_loc7_);
            }
            _loc9_++;
         }
         mOppAvt_spr.x = this.mBg.x + mBg.width - mOppAvt_spr.width;
         mOppAvt_spr.y = mBg.y + 45;
         mOppPower_txt = GlobalFunction.createTextField(240,MainConfig.$isEA ? 60 : 30,"","",20,4926491);
         mOppPower_txt.x = mOppName.x;
         mOppPower_txt.y = mOppName.y + mOppName.height + 15;
         this.addChild(mOppPower_txt);
         mOppPower_txt.text = GlobalLanguageStr.getStr(90279) + mirror_data.power.toString();
         mMyName = GlobalFunction.createTextField(240,30,GlobalData.$userData.name,"",25,16777215);
         mMyName.x = mQuad.x + 10;
         mMyName.y = mQuad.y + 50;
         this.addChild(mMyName);
         mPower_txt = GlobalFunction.createTextField(MainConfig.$isEA ? 240 : (MainConfig.$isEnglish ? 340 : 240),MainConfig.$isEA ? 60 : (MainConfig.$isEnglish ? 40 : 30),"","",MainConfig.$isEA ? 20 : (MainConfig.$isEnglish ? 18 : 20),16777215);
         mPower_txt.x = MainConfig.$isEA ? mMyName.x - 6 : (MainConfig.$isEnglish ? mMyName.x - 40 : mMyName.x);
         mPower_txt.y = mMyName.y + mMyName.height + 15;
         this.addChild(mPower_txt);
         mAvt_spr = new Sprite();
         this.addChild(mAvt_spr);
         _loc9_ = 0;
         while(_loc9_ < 3)
         {
            _loc3_ = GlobalFunction.createImage("UI_bg_card_2_0002");
            _loc3_.scaleX = _loc3_.scaleY = 1;
            _loc3_.x = (90 + 20) * _loc9_;
            mAvt_arr.push(_loc3_);
            this.mAvt_spr.addChild(_loc3_);
            _loc7_ = DisplayTools.newTextField("" + (_loc9_ + 1),"Font_numAndtag_1",40,16777215);
            _loc7_.pivotX = _loc7_.width * 0.5;
            _loc7_.pivotY = _loc7_.height * 0.5;
            _loc7_.x = _loc3_.x + _loc3_.width * 0.5;
            _loc7_.y = _loc3_.height * 0.5;
            this.mAvt_spr.addChild(_loc7_);
            _loc9_++;
         }
         mAvt_spr.x = this.mQuad.x + mQuad.width - mAvt_spr.width - 25;
         mAvt_spr.y = mQuad.y + 40;
         setList();
         addList();
         mBuff_spr = new Sprite();
         this.addChild(mBuff_spr);
         var _loc8_:Object = GlobalData.$userData.exploration;
         var _loc4_:Object = GlobalFunction.getStage_Mode(_loc8_.stage_mode);
         mBuff_bg = GlobalFunction.createImage("UI_wordbg_yellow_0_0000");
         mBuff_bg.width = 560;
         mBuff_spr.addChild(mBuff_bg);
         mBuff_txt = GlobalFunction.createTextField(440,30,GlobalLanguageStr.getLanguageStr(90608,_loc4_["info"]),"",MainConfig.$isEA ? 15 : 20,10027008);
         mBuff_txt.x = mBuff_bg.x + (mBuff_bg.width - mBuff_txt.width) * 0.5;
         mBuff_txt.y = mBuff_bg.y + (mBuff_bg.height - mBuff_txt.height) * 0.5;
         mBuff_spr.addChild(mBuff_txt);
         mBuff_spr.pivotX = mBuff_spr.width * 0.5;
         mBuff_spr.pivotY = mBuff_spr.height * 0.5;
         mFresh_btn = new LOL_Scale9Button(GlobalLanguageStr.getStr(90597),150,70,"UI_btn_normalFun_0000");
         if(mFresh_btn)
         {
            mFresh_btn.fontSize = 21;
         }
         mFresh_btn.x = this.mImg9_baseBg.x + this.mImg9_baseBg.width * 0.5 - mFresh_btn.width - 30;
         mFresh_btn.y = this.mImg9_baseBg.y + this.mImg9_baseBg.height - mFresh_btn.height - 60;
         mFresh_btn.name = "fresh_btn_name";
         mFresh_btn.addEventListener("triggered",onTRIGGERED_btn);
         this.addChild(mFresh_btn);
         mGoBattle_btn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90606),150,70,"UI_btn_normalFun_0000");
         mGoBattle_btn.x = this.mImg9_baseBg.x + this.mImg9_baseBg.width * 0.5 + 30;
         mGoBattle_btn.y = mFresh_btn.y;
         mGoBattle_btn.name = "go_btn_name";
         mGoBattle_btn.addEventListener("triggered",onTRIGGERED_btn);
         this.addChild(mGoBattle_btn);
         mBuff_spr.x = mBg.x + mBg.width * 0.5;
         mBuff_spr.y = this.mFresh_btn.y - mBuff_spr.height + 10;
         var _loc6_:int = int(GlobalData.$userData.records.exploration_times.mode_buy);
         _payGold = refreshGold(_loc6_);
         mGlodSpend_spr = new LOL_MutilTextFieldIcon(GlobalLanguageStr.getStr(90656),_payGold.toString(),"UI_money_coin_0_0000");
         mGlodSpend_spr.x = mFresh_btn.x - 20;
         mGlodSpend_spr.y = mFresh_btn.y + mFresh_btn.height;
         this.addChild(mGlodSpend_spr);
         var _loc5_:String = GlobalData.$mConfig_simple.explore.free_times;
         mFreshInfo_txt = GlobalFunction.createTextField(200,30,GlobalLanguageStr.getLanguageStr(90598,_loc5_),"",15,6475106);
         mFreshInfo_txt.x = mFresh_btn.x - (mFreshInfo_txt.width - mFresh_btn.width) * 0.5;
         mFreshInfo_txt.y = mGlodSpend_spr.y;
         this.addChild(mFreshInfo_txt);
         updatePower();
         updataCount();
      }
      
      private function updataCount() : void
      {
         var _loc1_:int = int(GlobalData.$userData.records.exploration_times.mode_buy);
         if(_loc1_ == 0)
         {
            mGlodSpend_spr.visible = false;
            mFreshInfo_txt.visible = true;
         }
         else
         {
            mGlodSpend_spr.visible = true;
            mFreshInfo_txt.visible = false;
         }
      }
      
      private function onTRIGGERED_btn(param1:Event) : void
      {
         var _loc2_:String = null;
         var _loc3_:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         switch(_loc3_.name)
         {
            case "go_btn_name":
               if(setTeamIdArr())
               {
                  GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_exploration_battle",false,true);
               }
               else
               {
                  LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getStr(90607));
               }
               break;
            case "fresh_btn_name":
               if(GlobalData.$userData.records.exploration_times.mode_buy == 0)
               {
                  sure();
               }
               else if(_payGold > GlobalData.$userData.coin)
               {
                  GlobalFunction.popErrorCoin(_payGold);
               }
               else
               {
                  _loc2_ = _payGold + GlobalLanguageStr.getLanguageStr(20149);
                  GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90599,_loc2_),GlobalTextStyle.COLOR_W_Y_Y_G),{
                     "ok":sure,
                     "no":GlobalFunction.functionNull
                  });
               }
         }
      }
      
      private function sure() : void
      {
         SendServiceAMFFun.send_user_exploration_buy_mode(refun);
      }
      
      private function refun(param1:Object) : void
      {
         var _o:Array;
         var i:int;
         var _re:Object = param1;
         if(!_re.data || !GlobalFunction.isVersionedProfileReceipt(_re) || !this.stage)
         {
            return;
         }
         // The response is the receipt; the shared revision boundary owns
         // profile fields. Read the latest cache so a stale valid receipt
         // cannot rewind the displayed cost or mode.
         _payGold = refreshGold(int(GlobalData.$userData.records.exploration_times.mode_buy));
         mGlodSpend_spr.txt2 = _payGold.toString();
         if(_tw)
         {
            Starling.juggler.remove(_tw);
         }
         _tw = null;
         _tw = new Tween(mBuff_spr,0.6,"easeOutBack");
         _tw.onStart = function():void
         {
            mBuff_txt.text = GlobalLanguageStr.getLanguageStr(90608,GlobalFunction.getStage_Mode(GlobalData.$userData.exploration.stage_mode)["info"]);
         };
         _tw.scaleTo(1.4);
         _tw.onComplete = function():void
         {
            var _loc1_:Tween = new Tween(mBuff_spr,0.6,"easeInBack");
            _loc1_.scaleTo(1);
            Starling.juggler.add(_loc1_);
         };
         Starling.juggler.add(_tw);
         _o = GlobalData.$exploration_team_avatar;
         i = 0;
         setList();
         addList();
         i = 0;
         while(i < mOppAvt_arr.length)
         {
            (mOppAvt_arr[i] as AvatarImg).updateBuffState();
            i = i + 1;
         }
         updataCount();
      }
      
      private function refreshGold(param1:int) : int
      {
         var _loc3_:int = int(GlobalData.$mConfig_simple.explore.free_times);
         var _loc4_:int = 0;
         var _loc2_:Object = GlobalData.$mConfig_simple.explore;
         if(_loc3_ - 1 >= param1)
         {
            _loc4_ = 0;
         }
         else
         {
            _loc4_ = _loc2_.refresh_mode_price[0] * param1 + _loc2_.refresh_mode_price[1];
         }
         return _loc4_;
      }
      
      private function setTeamIdArr() : Boolean
      {
         var _loc3_:int = 0;
         var _loc2_:Boolean = false;
         GlobalData.$exploration_team_avtId_arr = [];
         var _loc1_:Array = GlobalData.$exploration_team_avatar;
         _loc3_ = 0;
         while(_loc3_ < _loc1_.length)
         {
            if(_loc1_[_loc3_] != null)
            {
               GlobalData.$exploration_team_avtId_arr.push((_loc1_[_loc3_] as AvatarImg).id);
            }
            else
            {
               GlobalData.$exploration_team_avtId_arr.push(null);
            }
            if(_loc3_ == _loc1_.length - 1)
            {
               _loc2_ = true;
            }
            _loc3_++;
         }
         if(Tools.getArrayLength(_loc1_) == 0)
         {
            _loc2_ = false;
         }
         return _loc2_;
      }
      
      override public function setList() : void
      {
         var _loc3_:Number = NaN;
         var _loc2_:Object = null;
         var _loc1_:TiledRowsLayout = null;
         this.delList();
         if(this.mList == null)
         {
            _loc3_ = 80;
            _loc2_ = {
               "paging":0,
               "gap":0,
               "horizontalGap":20,
               "verticalGap":20,
               "paddingTop":5,
               "paddingRight":0,
               "paddingBottom":20,
               "paddingLeft":0,
               "horizontalAlign":"center",
               "verticalAlign":"top",
               "tileHorizontalAlign":"left",
               "tileVerticalAlign":"top"
            };
            _loc1_ = new TiledRowsLayout();
            _loc1_.useSquareTiles = false;
            _loc1_.horizontalGap = _loc2_.horizontalGap;
            _loc1_.verticalGap = _loc2_.verticalGap;
            _loc1_.paging = _loc2_.paging;
            _loc1_.paddingTop = _loc2_.paddingTop;
            _loc1_.paddingRight = _loc2_.paddingRight;
            _loc1_.paddingBottom = _loc2_.paddingBottom;
            _loc1_.paddingLeft = _loc2_.paddingLeft;
            _loc1_.horizontalAlign = _loc2_.horizontalAlign;
            _loc1_.verticalAlign = _loc2_.verticalAlign;
            _loc1_.tileHorizontalAlign = _loc2_.tileHorizontalAlign;
            _loc1_.tileVerticalAlign = _loc2_.tileVerticalAlign;
            this.mList = new List();
            this.mList.clipContent = true;
            this.mList.autoHideBackground = true;
            this.mList.isSelectable = false;
            this.mList.width = GlobalData.$mStageWidth - 20;
            this.mList.height = GlobalData.$center_height - 420;
            this.mList.layout = _loc1_;
            this.mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
            this.mList.x = int((GlobalData.$mStageWidth - this.mList.width) * 0.5);
            this.mList.y = mQuad.y + mQuad.height + 5;
            this.mList.snapScrollPositionsToPixels = true;
            this.addChild(this.mList);
            _loc2_ = null;
            _loc1_ = null;
            this.mList.dataProvider = new ListCollection();
         }
      }
      
      override public function addList() : void
      {
         var _loc4_:AvatarImg = null;
         var _loc8_:* = null;
         var _loc1_:Avatar = null;
         var _loc7_:Object = null;
         var _loc5_:Array = GlobalData.$exploration_team_avatar;
         while(_loc5_.length > 0)
         {
            _loc4_ = _loc5_.pop();
            if(_loc4_ != null)
            {
               _loc4_.dispose();
               _loc4_.removeFromParent(true);
               _loc4_ = null;
            }
         }
         var _loc2_:Array = [];
         var _loc3_:Object = GlobalData.$userData.exploration.army;
         var _loc6_:String = "";
         for(var _loc9_:String in _loc3_)
         {
            _loc6_ = _loc9_;
            if(GlobalFunction.checkSearchTypeByType(_loc6_,1))
            {
               _loc1_ = new Avatar(_loc6_,_loc3_[_loc9_]);
               _loc7_ = _loc3_[_loc9_];
               _loc7_["id"] = _loc6_;
               _loc7_["star"] = _loc1_.getStar();
               _loc7_["lv"] = _loc1_.lv;
               _loc7_["choice"] = false;
               _loc7_["status"] = setStatus(_loc6_);
               _loc7_["power"] = _loc1_.getPower(true);
               _loc2_.push(_loc7_);
               _loc1_.clear();
               _loc1_ = null;
            }
         }
         _loc2_.sortOn(["power","star","lv","id"],[0x10 | 2,0x10 | 2,0x10 | 2,1]);
         GlobalData.$explorationArmyTeam = {};
         this.setListTimer(mList,_loc2_,ItemExplorationSelectTeam,false);
      }
      
      private function setStatus(param1:String) : Boolean
      {
         var _loc5_:int = 0;
         var _loc3_:String = null;
         var _loc2_:Boolean = false;
         var _loc4_:Array = GlobalData.$exploration_team_avatar;
         _loc5_ = 0;
         while(_loc5_ < _loc4_.length)
         {
            if(_loc4_[_loc5_] != null)
            {
               _loc3_ = (_loc4_[_loc5_] as Sprite).name;
               if((_loc4_[_loc5_] as Sprite).name == param1)
               {
                  _loc2_ = true;
               }
            }
            _loc5_++;
         }
         return _loc2_;
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalData.$mEventDispatcher.removeEventListener("select_exploration_select_avatar",onSELECT_AVATAR_DATA);
         GlobalData.$mEventDispatcher.removeEventListener("set_start_exploration_pro_avatar",onSET_START_EXPLORATION_PRO_AVATAR);
         super.onREMOVED_FROM_STAGE(param1);
         if(mBg)
         {
            mBg.dispose();
            mBg.removeFromParent(true);
         }
         mBg = null;
         if(mPower_txt)
         {
            mPower_txt.dispose();
            mPower_txt.removeFromParent(true);
         }
         mPower_txt = null;
         if(mAvt_spr)
         {
            StarlingTools.removeChildrenClear(mAvt_spr);
            mAvt_spr.removeFromParent(true);
         }
         if(mGoBattle_btn)
         {
            mGoBattle_btn.removeFromParent(true);
         }
         mGoBattle_btn = null;
         if(mFresh_btn)
         {
            mFresh_btn.removeFromParent(true);
         }
         mFresh_btn = null;
         mAvt_spr = null;
         this.delList();
         mAvt_arr = [];
         GlobalData.$exploration_team_avatar = [];
         mirror_data = {};
         if(mFreshInfo_txt)
         {
            mFreshInfo_txt.dispose();
            mFreshInfo_txt.removeFromParent(true);
         }
         mFreshInfo_txt = null;
         if(mGlodSpend_spr)
         {
            mGlodSpend_spr.dispose();
            mGlodSpend_spr.removeFromParent(true);
         }
         mGlodSpend_spr = null;
         if(mBuff_spr)
         {
            StarlingTools.removeChildrenClear(mBuff_spr);
         }
         mBuff_spr = null;
         if(mBuff_bg)
         {
            mBuff_bg.dispose();
            mBuff_bg.removeFromParent(true);
         }
         mBuff_bg = null;
         if(mBuff_txt)
         {
            mBuff_txt.dispose();
            mBuff_txt.removeFromParent(true);
         }
         mBuff_txt = null;
      }
   }
}

import com.meng52.game.global.GlobalData;
import com.meng52.game.global.GlobalFunction;
import com.meng52.game.global.GlobalLanguageStr;
import com.meng52.game.module.avatar.Avatar;
import com.meng52.game.ui.element.ItemExplorationSelectTeam;
import com.meng52.game.ui.element.ProgressBar;
import com.meng52.utils.StarlingTools;
import com.meng52.utils.Tools;
import flash.geom.Point;
import starling.display.Image;
import starling.display.Quad;
import starling.display.Sprite;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.text.TextField;

class AvatarImg extends Sprite
{
   
   private var _avt:Avatar;
   
   private var _spr:Sprite;
   
   private var _data:Object;
   
   private var _id:String;
   
   private var _booldbar:ProgressBar;
   
   private var _type:int;
   
   private const W_H_MAX:Number = 104;
   
   private var _isArray:Boolean;
   
   private var _isNpc:Boolean;
   
   private var _upIcon:Image;
   
   private var _quad:Quad;
   
   private var _txt:TextField;
   
   private var _sprMark:Sprite;
   
   private var _point:Point;
   
   private var _itemExplorationSelectTeam:ItemExplorationSelectTeam;
   
   private var _self_power:Number;
   
   private const addY:int = 15;
   
   public function AvatarImg(param1:String, param2:* = null, param3:int = 1, param4:Boolean = false, param5:Boolean = false)
   {
      var _loc6_:Object = null;
      super();
      this._data = param2;
      this._id = param1;
      this._type = param3;
      this._isArray = param4;
      this._isNpc = param5;
      if(param4)
      {
         _loc6_ = {};
         if(param5)
         {
            _loc6_["id"] = param2[0];
            _loc6_["aid"] = param2[0];
            _loc6_.lv = param2[1];
            _loc6_.slv = param2[2];
            _loc6_.max_hp = param2[7];
            _avt = new Avatar(param1,_loc6_);
         }
         else
         {
            _loc6_["id"] = param2[0];
            _loc6_["aid"] = param2[0];
            _loc6_.lv = param2[1];
            _loc6_.slv = param2[2];
            _loc6_.max_hp = param2[14];
            _avt = new Avatar(param1,_loc6_);
         }
      }
      else
      {
         _avt = new Avatar(param1,param2);
      }
      this.addEventListener("touch",onTOUCH);
      this.addEventListener("removedFromStage",onREMOVE);
      setUI();
   }
   
   public function getPower(param1:Boolean = false) : int
   {
      return _avt.getPower(param1);
   }
   
   private function onREMOVE() : void
   {
      this.removeEventListener("removedFromStage",onREMOVE);
      if(_avt)
      {
         _avt.clear();
         _avt = null;
      }
      if(_spr)
      {
         StarlingTools.removeChildrenClear(_spr);
      }
      if(_booldbar)
      {
         _booldbar.dispose();
         _booldbar.removeFromParent(true);
      }
      _booldbar = null;
      _spr = null;
   }
   
   protected function onTOUCH(param1:TouchEvent) : void
   {
      var _loc2_:Touch = param1.getTouch(this,"ended");
      if(_loc2_)
      {
         _itemExplorationSelectTeam.changeStatus();
         return;
      }
   }
   
   private function setUI() : void
   {
      var _loc1_:Number = NaN;
      _spr = _avt.getAvatarRes();
      this.addChild(_spr);
      var _loc3_:int = 0;
      if(_isArray)
      {
         if(_isNpc)
         {
            _loc1_ = this._data[6] / this._data[7];
            _loc3_ = int(this._data[7]);
         }
         else
         {
            _loc1_ = this._data[13] / this._data[14];
            _loc3_ = int(this._data[14]);
         }
      }
      else
      {
         _loc1_ = this._data.current_hp / this._data.max_hp;
         _loc3_ = int(this._data.max_hp);
      }
      _booldbar = new ProgressBar(_type,_loc1_,_loc3_);
      _booldbar.x = _spr.width * 0.5 - 5;
      _booldbar.y = -10;
      this.addChild(_booldbar);
      _sprMark = new Sprite();
      _sprMark.touchable = false;
      this.addChild(_sprMark);
      _quad = new Quad(100,20,590848);
      _quad.pivotX = _quad.width * 0.5;
      _quad.x = this._spr.width * 0.5 - 5;
      _quad.y = this._spr.height * 0.4;
      _sprMark.addChild(_quad);
      _txt = new TextField(MainConfig.$isEA ? 140 : 100,MainConfig.$isEA ? 50 : 20,GlobalLanguageStr.getStr(90576),"",15,10027008,true);
      _txt.pivotX = _txt.width * 0.5;
      _txt.x = _quad.x;
      _txt.y = MainConfig.$isEA ? _quad.y - 15 : Number(_quad.y);
      _sprMark.addChild(_txt);
      var _loc2_:Boolean = _loc1_ <= 0;
      visibleMask(_loc2_);
      updateBuffState();
   }
   
   public function get mMask_000000() : Sprite
   {
      return _sprMark;
   }
   
   public function visibleMask(param1:Boolean) : void
   {
      if(param1)
      {
         _spr.blendMode = Tools.getBlendMode(null,0.5,0.5,0.5);
      }
      else
      {
         _spr.blendMode = Tools.getBlendMode(null,1,1,1);
      }
      if(!mMask_000000)
      {
         return;
      }
      if(param1 == mMask_000000.visible)
      {
         return;
      }
      this.mMask_000000.visible = param1;
      _sprMark.flatten();
   }
   
   public function set point(param1:Point) : void
   {
      this._point = param1;
   }
   
   public function get point() : Point
   {
      return this._point;
   }
   
   public function set item(param1:ItemExplorationSelectTeam) : void
   {
      this._itemExplorationSelectTeam = param1;
   }
   
   public function get item() : ItemExplorationSelectTeam
   {
      return this._itemExplorationSelectTeam;
   }
   
   public function set self_power(param1:Number) : void
   {
      this._self_power = param1;
   }
   
   public function get self_power() : Number
   {
      return Math.floor(this._self_power);
   }
   
   public function get id() : String
   {
      return this._id;
   }
   
   public function updateBuffState() : void
   {
      var _loc6_:String = null;
      var _loc4_:String = null;
      if(_upIcon)
      {
         _upIcon.removeFromParent(true);
         _upIcon = null;
      }
      var _loc8_:Object = GlobalData.$userData.exploration;
      var _loc2_:Object = GlobalFunction.getStage_Mode(_loc8_.stage_mode);
      var _loc1_:String = _loc2_.data[1];
      var _loc5_:Boolean = _loc2_["add"] == 1;
      var _loc3_:String = _avt.id.split("|")[0];
      var _loc7_:Object = GlobalData.$mConfig_avatar[_loc3_];
      switch(_loc1_)
      {
         case "1":
         case "2":
         case "3":
            _loc4_ = _loc7_.tl[0];
            _loc6_ = _loc1_;
            updateStart("TYPE1",_loc4_,_loc6_,_loc5_);
            break;
         case "4":
         case "5":
         case "6":
         case "7":
            _loc4_ = _loc7_.tl[1];
            _loc6_ = (int(_loc1_) - 3).toString();
            updateStart("TYPE2",_loc4_,_loc6_,_loc5_);
            break;
         case "8":
         case "9":
         case "10":
            _loc4_ = _loc7_.tl[2];
            _loc6_ = (int(_loc1_) - 7).toString();
            updateStart("TYPE3",_loc4_,_loc6_,_loc5_);
            break;
         default:
            _loc4_ = _loc1_;
            updateStart("ALL",_loc4_,_loc6_,_loc5_);
      }
   }
   
   private function updateStart(param1:String, param2:String, param3:String, param4:Boolean) : void
   {
      if(param1 == "ALL")
      {
         checkUp(param4);
      }
      else if(param2 == param3)
      {
         checkUp(param4);
      }
   }
   
   private function checkUp(param1:Boolean = true) : void
   {
      if(param1)
      {
         _upIcon = GlobalFunction.createImage("UI_equip_tag_0_0000");
         _upIcon.pivotX = _upIcon.width / 2;
         _upIcon.pivotY = _upIcon.height / 2;
         _upIcon.x = GlobalData.$iconRec90.width;
         _upIcon.y = 25;
         _upIcon.rotation = -1.5707963267948966;
      }
      else
      {
         _upIcon = GlobalFunction.createImage("UI_equip_tag_0_0001");
         _upIcon.pivotX = _upIcon.width / 2;
         _upIcon.pivotY = _upIcon.height / 2;
         _upIcon.x = GlobalData.$iconRec90.width;
         _upIcon.y = 25;
         _upIcon.rotation = 3.141592653589793 / 2;
      }
      addChild(_upIcon);
   }
}
