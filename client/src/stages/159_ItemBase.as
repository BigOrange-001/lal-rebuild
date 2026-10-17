package com.meng52.game.ui.element
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.map.GameMapConfig;
   import com.meng52.game.ui.screen.PanelBase;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.controls.renderers.DefaultListItemRenderer;
   import feathers.controls.renderers.IListItemRenderer;
   import feathers.display.Scale3Image;
   import feathers.display.Scale9Image;
   import starling.animation.Juggler;
   import starling.display.DisplayObject;
   import starling.display.DisplayObjectContainer;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.EnterFrameEvent;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.filters.ColorMatrixFilter;
   import starling.text.TextField;
   import starling.textures.Texture;

   public class ItemBase extends DefaultListItemRenderer implements IListItemRenderer
   {

      public static const TYPE_TEAM_LEADER:String = "leader";

      public static const TYPE_TEAM_MEMBER:String = "member";

      public static const TOUCH_AVATAR_CHANGEUI_B:Boolean = false;

      public var mIsInitB:Boolean = false;

      public var mIsInitClass:Boolean = false;

      public var mImg_bg_lv:LOL_Scale9Button;

      public var mTag_status:Image;

      public var mImgLight:Image;

      public var mTxt_num:TextField;

      public var mTxt_title:TextField;

      public var mTxt_str0:TextField;

      public var mTxt_info:TextFieldHtmlRenderer;

      public var mIndex:int = 0;

      public var mTxt_lv:Sprite;

      public var mBg:Image;

      public var mBgImg:Scale3Image;

      public var mScale9Image:Scale9Image;

      public var mAvatar:Sprite;

      private var mUI_mask:Image;

      public var mUI_lock:Image;

      private var mUI_team:Quad;

      private var mTxt_team:TextField;

      private var mUI_team_type:int;

      protected var mUI_select:Image;

      public var mAvatarData:Avatar;

      public var mAvatarDatas:Vector.<Avatar>;

      public var mStatus:int;

      public var mTouchB:Boolean = true;

      public var mBox_all:Sprite;

      public var mCheckData:Object;

      public var mJuggler:Juggler;

      public var mJugglerLv:Juggler;

      public var mLight:ColorMatrixFilter;

      public var mIsAvatarTouch:Boolean = false;

      public var mLv_:LOL_TextField;

      public var mTweenOn:Boolean = false;

      public var mPrevIndexID:int = 0;

      public function ItemBase()
      {
         super();
         this.blendMode = "normal";
         this.mIsAvatarTouch = true;
         this.isSelected = false;
         this.itemHasIcon = false;
         this.itemHasLabel = false;
         this.labelFactory = null;
         this.labelFunction = null;
         this.mTouchB = true;
         this.mIsInitB = false;
         this.mIsInitClass = false;
      }

      public static function soundTriggered(param1:Boolean = false) : void
      {
         if(param1)
         {
            SoundManager.getOnlyExample().playSound("btn2");
         }
         else
         {
            SoundManager.getOnlyExample().playSound("btn1");
         }
      }

      public function get mMask_000000() : Image
      {
         return mUI_mask;
      }

      public function get mSelect() : Image
      {
         return mUI_select;
      }

      public function visibleMask(param1:Boolean) : void
      {
         if(!mMask_000000)
         {
            return;
         }
         if(param1 == mMask_000000.visible)
         {
            return;
         }
         this.mMask_000000.visible = param1;
         this.mAvatar.flatten();
         if(this.isFlattened)
         {
            this.flatten();
         }
      }

      public function visibleLock(param1:Boolean) : void
      {
         if(!mUI_lock)
         {
            this.mUI_lock = GlobalFunction.createImage("UI_icon_lock_1_0000");
            mUI_lock.scaleX = mUI_lock.scaleY = 0.6;
            this.mUI_lock.touchable = false;
            this.mUI_lock.x = GlobalData.$iconRec.width - this.mUI_lock.width + 10;
            mUI_lock.y = GlobalData.$iconRec.height - mUI_lock.height + 15;
            this.mAvatar.addChild(this.mUI_lock);
         }
         if(param1 == mUI_lock.visible)
         {
            return;
         }
         this.mUI_lock.visible = param1;
         this.mAvatar.flatten();
         if(this.isFlattened)
         {
            this.flatten();
         }
      }

      public function visibleTeam(param1:int, param2:int = -1) : void
      {
         var _loc5_:String = null;
         var _loc4_:int = 0;
         var _loc6_:int = 13777209;
         mUI_team_type = param1;
         if(mUI_team)
         {
            mUI_team.removeFromParent(true);
         }
         if(mTxt_team)
         {
            mTxt_team.removeFromParent(true);
         }
         var _loc3_:Number = 75;
         if(param1 != 0)
         {
            if(param1 == 1)
            {
               _loc4_ = 25046;
            }
            else if(param1 == 2)
            {
               _loc4_ = 25047;
               _loc6_ = 16764006;
            }
            else if(param1 == 3)
            {
               _loc4_ = 25048;
            }
            else if(param1 == 4)
            {
               _loc4_ = 25049;
            }
            else if(param1 == 5)
            {
               _loc4_ = 25050;
               _loc6_ = 16764006;
            }
            else if(param1 == 6)
            {
               _loc4_ = 20012;
            }
            if(param2 != -1)
            {
               if(param2 == 0)
               {
                  _loc5_ = GlobalLanguageStr.getLanguageStr(20015);
               }
               else
               {
                  _loc5_ = GlobalLanguageStr.getLanguageStr(10134) + param2;
               }
            }
            else
            {
               _loc5_ = GlobalLanguageStr.getLanguageStr(_loc4_);
            }
            if(param1 == 6)
            {
               _loc5_ = GlobalLanguageStr.getLanguageStr(_loc4_,param2);
            }
            if(param1 == 5)
            {
               // This language-table entry is absent in the restored client.
               // Keep the DN badge visible in every hero-list renderer.
               _loc5_ = "德诺阵中";
            }
            if(_loc5_)
            {
               mUI_team = Tools.newQuad(92,17,0,0,1513239);
               mTxt_team = GlobalTextStyle.getTextField(_loc5_,15,_loc6_,"center",95,50);
               mUI_team.touchable = false;
               mUI_team.x = 0;
               mUI_team.y = _loc3_ - mUI_team.height;
               mTxt_team.x = mUI_team.x;
               mTxt_team.y = mUI_team.y - 4;
               mAvatar.addChild(mUI_team);
               mAvatar.addChild(mTxt_team);
            }
         }
         this.mAvatar.flatten();
         if(this.isFlattened)
         {
            this.flatten();
         }
      }

      public function visibleSelect(param1:Boolean) : void
      {
         if(mSelect != null)
         {
            if(param1 == mSelect.visible)
            {
               return;
            }
            this.mSelect.visible = param1;
            if(mAvatar)
            {
               this.mAvatar.flatten();
            }
            if(this.isFlattened)
            {
               this.flatten();
            }
         }
      }

      override public function set data(param1:Object) : void
      {
         super.data = param1;
         if(data != null)
         {
            mTweenOn = false;
            mCheckData = data;
            clear();
            initListeners();
            init(data);
            setLvClip();
            layoutWH();
         }
      }

      override public function set index(param1:int) : void
      {
         var _loc2_:Boolean = false;
         if(param1 != -1 && param1 != index)
         {
            _loc2_ = true;
         }
         super.index = param1;
         if(_loc2_)
         {
            _loc2_ = false;
            mTweenOn = true;
            layoutWH();
         }
      }

      public function initVar() : void
      {
      }

      public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
      }

      public function onTRIGGERED(param1:Event) : void
      {
      }

      public function onCHANGE(param1:Event) : void
      {
      }

      public function onREMOVED(param1:Event) : void
      {
      }

      public function init(param1:Object) : void
      {
      }

      public function setUI() : void
      {
      }

      public function changeUILayout() : void
      {
      }

      public function layoutWH() : void
      {
      }

      public function changeWH() : void
      {
      }

      public function myDispose() : void
      {
      }

      public function getPanelBase() : PanelBase
      {
         var _loc1_:PanelBase = null;
         if(parent && parent.parent && parent.parent.parent)
         {
            _loc1_ = parent.parent.parent as PanelBase;
         }
         return _loc1_;
      }

      public function getOwner() : List
      {
         var _loc1_:List = null;
         if(this.parent)
         {
            if(this.parent.parent)
            {
               _loc1_ = this.parent.parent as List;
            }
         }
         return _loc1_;
      }

      public function tweenX(param1:Boolean = true, param2:Boolean = false) : void
      {
         var _loc4_:* = null;
         var _loc3_:int = 0;
      }

      public function tweenXout(param1:Boolean = true, param2:Boolean = false) : void
      {
         if(!mTweenOn)
         {
            return;
         }
         mTweenOn = false;
         if(pivotX != 0)
         {
            return;
         }
         var _loc4_:PanelBase = getPanelBase();
         var _loc3_:int = -GameMapConfig.SCREEN_WIDTH;
         if(param2 && index % 2 == 0)
         {
            _loc3_ = -_loc3_;
         }
         if(_loc4_ && !_loc4_.isOut)
         {
            pivotX = 0;
            GlobalData.$mStarling.juggler.tween(this,0.2,{
               "delay":index * 0.05,
               "pivotX":_loc3_
            });
         }
      }

      public function checkLock() : void
      {
      }

      public function setAvatar(param1:String, param2:int = 0, param3:Object = null, param4:Boolean = false, param5:Boolean = false, param6:Boolean = false) : void
      {
         var _loc10_:* = 0;
         var _loc12_:LOL_TextField = null;
         var _loc7_:String = null;
         var _loc9_:String = null;
         var _loc11_:int = 0;
         this.mAvatarData = new Avatar(param1,param3 == null ? this.data : param3);
         this.mAvatar = this.mAvatarData.getAvatarRes(false,param5,false);
         var _loc8_:Number = 95;
         mUI_team_type = 0;
         this.mUI_mask = GlobalFunction.createImage("UI_bg_card_2_0004");
         this.mUI_mask.x = 0;
         this.mUI_mask.y = 0;
         this.mUI_mask.alpha = 0.65;
         this.mUI_mask.touchable = false;
         this.mUI_mask.visible = false;
         this.mAvatar.addChild(this.mUI_mask);
         if(param2 == 1 || param2 == 3)
         {
            if(this.mAvatarData.lv < this.mAvatarData.getLvMax())
            {
               _loc7_ = GlobalLanguageStr.getLanguageStr(20017,this.mAvatarData.lv);
               _loc10_ = 16777215;
            }
            else
            {
               _loc7_ = GlobalLanguageStr.getLanguageStr(20017,GlobalLanguageStr.getLanguageStr(20180));
               _loc10_ = 16763904;
            }
            this.mTxt_lv = new Sprite();
            _loc12_ = new LOL_TextField(_loc7_,90,35,false);
            _loc12_.fontSize = 20;
            _loc12_.fontColor = _loc10_;
            _loc12_.hAlign = "center";
            _loc12_.shadowFilter();
            _loc12_.y = -5;
            this.mTxt_lv.addChild(_loc12_);
            this.mTxt_lv.touchable = false;
            this.mTxt_lv.x = int((90 - this.mTxt_lv.width) * 0.5);
            this.mTxt_lv.y = _loc8_;
            this.mAvatar.addChild(this.mTxt_lv);
         }
         if(param2 == 2 || param2 == 3)
         {
            if(this.mAvatarData != null && this.mAvatarData.phase != 0)
            {
               _loc10_ = 13696768;
               _loc11_ = Avatar.getPhaseMax(mAvatarData.avatarData.id);
               if(mAvatarData.phase == _loc11_)
               {
                  _loc9_ = GlobalLanguageStr.getLanguageStr(20314);
               }
               else
               {
                  _loc9_ = GlobalLanguageStr.getLanguageStr(20292,mAvatarData.phase);
               }
               mLv_ = new LOL_TextField(_loc9_,90,35,false);
               mLv_.fontSize = 20;
               mLv_.fontColor = _loc10_;
               mLv_.hAlign = "center";
               mLv_.shadowFilter();
               this.mLv_.touchable = false;
               this.mLv_.x = -3;
               this.mLv_.y = _loc8_ - 5;
               this.mAvatar.addChild(this.mLv_);
            }
         }
         if(param4)
         {
            this.mTxt_lv = new Sprite();
            _loc12_ = new LOL_TextField(GlobalLanguageStr.getLanguageStr(20181,this.data.numberIndex),90,35,false);
            _loc12_.fontSize = 20;
            _loc12_.fontColor = 16777215;
            _loc12_.hAlign = "center";
            _loc12_.shadowFilter();
            this.mTxt_lv.addChild(_loc12_);
            this.mTxt_lv.touchable = false;
            this.mTxt_lv.x = int((90 - this.mTxt_lv.width) * 0.5);
            this.mTxt_lv.y = _loc8_ - 5;
            this.mAvatar.addChild(this.mTxt_lv);
         }
         this.mAvatar.flatten();
      }

      public function getBettrGiveOther() : Object
      {
         var _loc1_:Number = this.mAvatarData.getOfferExp();
         return {
            "exp":_loc1_,
            "gold":_loc1_
         };
      }

      public function setUISelect() : void
      {
         this.mUI_select = GlobalFunction.createImage("UI_tag_2_0000");
         this.mUI_select.touchable = false;
         this.mUI_select.x = GlobalData.$iconRec90.width - this.mUI_select.width + 5;
         this.mUI_select.y = GlobalData.$iconRec90.height - this.mUI_select.height + 10;
         this.mAvatar.addChild(this.mUI_select);
         this.visibleSelect(false);
      }

      public function setJuggle() : void
      {
         if(this.mJuggler == null)
         {
            this.mJuggler = new Juggler();
            this.addEventListener("enterFrame",onEnterFrame);
         }
      }

      public function delJuggle() : void
      {
         if(this.mJuggler)
         {
            this.mJuggler.purge();
         }
         this.mJuggler = null;
         if(mJugglerLv)
         {
            mJugglerLv.purge();
         }
         mJugglerLv = null;
      }

      public function onEnterFrame(param1:EnterFrameEvent) : void
      {
         if(this.mJuggler)
         {
            this.mJuggler.advanceTime(param1.passedTime);
         }
         if(mJugglerLv)
         {
            this.mJugglerLv.advanceTime(param1.passedTime);
         }
      }

      public function checkIsTeam() : Boolean
      {
         return GlobalFunction.checkIsTeamMember(this.data.id);
      }

      public function clearChildren() : void
      {
         var _loc1_:Avatar = null;
         if(this.mAvatarData)
         {
            this.mAvatarData.clear();
         }
         if(mAvatarDatas)
         {
            for each(_loc1_ in mAvatarDatas)
            {
               _loc1_.clear();
               _loc1_ = null;
            }
         }
         StarlingTools.removeChildrenClear(this);
         if(mTxt_num)
         {
            mTxt_num.dispose();
         }
         if(mTxt_title)
         {
            mTxt_title.dispose();
         }
         if(mTxt_str0)
         {
            mTxt_str0.dispose();
         }
         if(mTxt_info)
         {
            mTxt_info.dispose();
         }
         if(mTxt_lv)
         {
            mTxt_lv.dispose();
         }
         if(mJuggler)
         {
            mJuggler.purge();
         }
         mTxt_num = null;
         mTxt_title = null;
         mTxt_str0 = null;
         mTxt_info = null;
         mTxt_lv = null;
         mAvatarData = null;
         mAvatarDatas = null;
         mJuggler = null;
         mBg = null;
         mScale9Image = null;
         mUI_mask = null;
         mUI_lock = null;
         mUI_team = null;
         mUI_select = null;
         mBox_all = null;
         mTag_status = null;
      }

      public function clear() : void
      {
         pivotX = 0;
         this.delJuggle();
         this.clearChildren();
         this.dispose();
      }

      public function initListeners() : void
      {
         this.removeEventListener("touch",button_touchHandler);
         this.removeEventListener("removedFromStage",button_removedFromStageHandler);
         this.removeEventListener("removedFromStage",this.onREMOVED_FROM_STAGE);
         this.removeEventListener("triggered",this.onTRIGGERED);
         this.addEventListener("touch",button_touchHandler);
         this.addEventListener("removedFromStage",button_removedFromStageHandler);
         this.addEventListener("removedFromStage",this.onREMOVED_FROM_STAGE);
         this.addEventListener("triggered",this.onTRIGGERED);
      }

      public function clearBaseListeners() : void
      {
         this.removeEventListener("touch",button_touchHandler);
         this.removeEventListener("removedFromStage",button_removedFromStageHandler);
         this.removeEventListener("removedFromStage",this.onREMOVED_FROM_STAGE);
         this.removeEventListener("triggered",this.onTRIGGERED);
      }

      override protected function button_removedFromStageHandler(param1:Event) : void
      {
         mCheckData = null;
         super.button_removedFromStageHandler(param1);
      }

      override protected function button_touchHandler(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(this);
         if(_loc2_)
         {
            if(_loc2_.phase == "ended")
            {
               getPrevSelectIndexID();
            }
         }
         super.button_touchHandler(param1);
         onTouchEventExt(param1);
      }

      public function getPrevSelectIndexID() : int
      {
         if(this.parent && this.parent.parent)
         {
            if(this.parent.parent is List)
            {
               mPrevIndexID = (this.parent.parent as List).selectedIndex;
            }
         }
         return mPrevIndexID;
      }

      public function setListSelectIndex(param1:int = -1) : void
      {
         if(this.parent && this.parent.parent)
         {
            if(this.parent.parent is List)
            {
               (this.parent.parent as List).selectedIndex = param1 < 0 ? mPrevIndexID : param1;
            }
         }
      }

      public function onTouchEventExt(param1:TouchEvent) : void
      {
         var _loc3_:Touch = null;
         var _loc2_:Touch = param1.getTouch(this);
         if(_loc2_)
         {
            if(_loc2_.phase == "began")
            {
               onTouchBEGAN();
            }
            else if(_loc2_.phase == "ended")
            {
               onTouchENDED();
            }
         }
         if(this.mAvatar)
         {
            _loc3_ = param1.getTouch(mAvatar);
            if(_loc3_)
            {
               if(_loc3_.phase == "began")
               {
                  onTouchAvatarB();
               }
               else if(_loc3_.phase == "ended")
               {
                  onTouchAvatarE();
               }
            }
         }
      }

      public function onTouchAvatarB() : void
      {
         var _loc1_:DisplayObject = null;
         if(mIsAvatarTouch && this.mAvatar)
         {
            _loc1_ = mAvatar.getChildByName("UI_btn_over_20_0000");
            if(_loc1_)
            {
               _loc1_.visible = true;
               mAvatar.flatten();
            }
         }
      }

      public function onTouchAvatarE() : void
      {
         var _loc1_:DisplayObject = null;
         if(mIsAvatarTouch && this.mAvatar)
         {
            _loc1_ = mAvatar.getChildByName("UI_btn_over_20_0000");
            if(_loc1_)
            {
               _loc1_.visible = false;
               mAvatar.flatten();
            }
         }
      }

      public function onTouchBEGAN() : void
      {
         if(!mIsAvatarTouch)
         {
            if(mImgLight)
            {
               mImgLight.visible = true;
            }
         }
      }

      public function onTouchENDED() : void
      {
         if(!mIsAvatarTouch)
         {
            if(mImgLight)
            {
               mImgLight.visible = false;
            }
         }
      }

      public function changeLight(param1:Texture, param2:String) : void
      {
         if(mImgLight)
         {
            if(mImgLight.name != param2)
            {
               mImgLight.name = param2;
               mImgLight.texture = param1;
            }
         }
      }

      public function setLight(param1:String = "", param2:Object = null) : void
      {
         if(param1 != "" && mImgLight == null)
         {
            mImgLight = GlobalFunction.createImage(param1);
            mImgLight.name = param1;
            mImgLight.touchable = false;
            mImgLight.visible = false;
            if(param2 != null)
            {
               mImgLight.x = param2.x;
               mImgLight.y = param2.y;
            }
            addChild(mImgLight);
         }
      }

      public function delLight(param1:DisplayObject) : void
      {
         if(mLight)
         {
            mLight.dispose();
         }
         mLight = null;
         if(param1)
         {
            if(param1.filter)
            {
               param1.filter.clearCache();
               param1.filter.dispose();
            }
            param1.filter = null;
         }
      }

      public function setLvClip() : void
      {
         var clip1:*;
         var clip2:*;
         if(mLv_ && mTxt_lv && mAvatar && data != null)
         {
            clip1 = function():void
            {
               mAvatar.unflatten();
               mTxt_lv.alpha = 1;
               mLv_.alpha = 0;
               mJugglerLv.tween(mTxt_lv,0.5,{
                  "delay":2,
                  "onComplete":clip2,
                  "alpha":0
               });
               mJugglerLv.tween(mLv_,0.5,{
                  "delay":2,
                  "alpha":1
               });
            };
            clip2 = function():void
            {
               mAvatar.unflatten();
               mTxt_lv.alpha = 0;
               mLv_.alpha = 1;
               mJugglerLv.tween(mLv_,0.5,{
                  "delay":2,
                  "onComplete":clip1,
                  "alpha":0
               });
               mJugglerLv.tween(mTxt_lv,0.5,{
                  "delay":2,
                  "alpha":1
               });
            };
            if(mAvatarData)
            {
               if(mAvatarData.phase <= 0)
               {
                  return;
               }
            }
            if(mJugglerLv)
            {
               mJugglerLv.purge();
            }
            mJugglerLv = null;
            mJugglerLv = new Juggler();
            clip1();
            this.addEventListener("enterFrame",onEnterFrame);
         }
      }
   }
}
