package com.meng52.game.ui.panel
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.map.GameMapTools;
   import com.meng52.game.ui.element.ItemActivityExpedition;
   import com.meng52.game.ui.element.ItemAvatarAward;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.screen.PanelBase;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import starling.animation.Juggler;
   import starling.animation.Tween;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.EnterFrameEvent;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.utils.deg2rad;
   
   public class PanelActivityExpedition extends PanelBase
   {
      
      private var mImg_bg:Image;
      
      private var mImg_avatar:Image;
      
      private var mImg_bg_clip:Image;
      
      private var m9x9_bg:Scale9Image;
      
      private var mBox:Sprite;
      
      private var mBoxShow:Sprite;
      
      private var mQuad:Quad;
      
      private var mBtn_expedition:LOL_Button;
      
      private var mBtn_close:LOL_Button;
      
      private var mClip_rotation:Number;
      
      private var mClip_scale:Number = 0;
      
      private var mTxt_info:TextFieldHtmlRenderer;
      
      private var mBox_award:Sprite;
      
      private var mBox_result:Sprite;
      
      private var mDnStone:Number = 0;
      
      private var mTalent:String;
      
      public function PanelActivityExpedition()
      {
         super();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalFunction.clearExpeditionItems();
         delAwardUIs();
         GlobalData.$mEventDispatcher.removeEventListener("update_PanelActivityExpedition_ui",onUPDATE_PANELACTIVITYEXPEDITION_UI);
         if(mBox)
         {
            StarlingTools.removeChildrenClear(mBox);
            mBox.removeFromParent(true);
         }
         if(mImg_bg)
         {
            mImg_bg.removeFromParent(true);
         }
         if(mImg_bg_clip)
         {
            mImg_bg_clip.removeFromParent(true);
         }
         if(m9x9_bg)
         {
            m9x9_bg.removeFromParent(true);
         }
         if(mBtn_expedition)
         {
            mBtn_expedition.removeFromParent(true);
         }
         if(mTxt_info)
         {
            mTxt_info.removeFromParent(true);
         }
         mImg_bg = null;
         mImg_bg_clip = null;
         mBox = null;
         mBoxShow = null;
         m9x9_bg = null;
         mBtn_expedition = null;
         mTxt_info = null;
         mQuad = null;
         GlobalFunction.delTextureByBD("pic_expedition_bg_0");
         GlobalFunction.delTextureByBD("pic_expedition_bg_1");
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         removeEventListener("addedToStage",initializeHandler);
         setUIs();
      }
      
      private function setUIs() : void
      {
         var _mColorArr:Array;
         var _arrInfo:String;
         var _arr:Array;
         var _show_id:String;
         mClip_rotation = deg2rad(1);
         mImg_bg_clip = GlobalFunction.createImage("pic_expedition_bg_1",true);
         var _ww:Number = 214;
         var _hh:Number = 148;
         mImg_bg_clip.pivotX = _ww;
         mImg_bg_clip.pivotY = _hh;
         mImg_bg = GlobalFunction.createImage("pic_expedition_bg_0",true);
         mImg_bg.y = (GlobalData.$center_height_curr - 121 - mImg_bg.height) / 2 - 20;
         mImg_bg_clip.x = mImg_bg.x + 110 + _ww;
         mImg_bg_clip.y = mImg_bg.y + 272 + _hh;
         addChild(mImg_bg_clip);
         addChild(mImg_bg);
         mBtn_expedition = GlobalFunction.createButton_5("","UI_expedition_btn_0000");
         mBtn_expedition.pivotX = int(mBtn_expedition.width * 0.5);
         mBtn_expedition.pivotY = int(mBtn_expedition.height * 0.5);
         mBtn_expedition.x = mImg_bg_clip.x;
         mBtn_expedition.y = mImg_bg_clip.y;
         mBtn_expedition.addEventListener("triggered",onTRIGGERED_send);
         addChild(mBtn_expedition);
         m9x9_bg = GlobalFunction.createScale9Image("UI_bg_9slice_5_0000",616,120,new Rectangle(30,20,50,30));
         m9x9_bg.touchable = false;
         m9x9_bg.x = int((GlobalData.$mStageWidth - m9x9_bg.width) * 0.5);
         m9x9_bg.y = GlobalData.$center_height_curr - 121 - m9x9_bg.height;
         addChild(m9x9_bg);
         _mColorArr = [16777215,16764006,13421772,13777209];
         _arrInfo = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90190),_mColorArr,MainConfig.$isEnglish ? 20 : 18,20);
         _arr = [_arrInfo];
         mTxt_info = GlobalTextStyle.getHtmlTextRenderer();
         mTxt_info.touchable = false;
         mTxt_info.text = Tools.formatHtmlTextBr(_arr);
         mTxt_info.mLayoutFun = function():void
         {
            var _loc2_:Rectangle = mTxt_info.getTextSnapshotFrame();
            mTxt_info.x = m9x9_bg.x + 213;
            var _loc1_:Number = m9x9_bg.height - _loc2_.height;
            if(_loc1_ > 0)
            {
               mTxt_info.y = MainConfig.$isEnglish ? m9x9_bg.y + int(_loc1_ * 0.5) - 3 : m9x9_bg.y + int(_loc1_ * 0.5) - 5;
            }
            else
            {
               mTxt_info.y = MainConfig.$isEnglish ? m9x9_bg.y + 7 : m9x9_bg.y + 5;
            }
         };
         _show_id = GlobalData.$mConfig_simple.show_id[6];
         mImg_avatar = GameMapTools.newAvatarImgById(_show_id);
         mImg_avatar.x = 50;
         mImg_avatar.y = m9x9_bg.y + 50;
         addChild(mImg_avatar);
         addChild(mTxt_info);
         setItemUIs();
         addEventListener("enterFrame",onENTER_FRAME_clip);
         GlobalData.$mEventDispatcher.addEventListener("update_PanelActivityExpedition_ui",onUPDATE_PANELACTIVITYEXPEDITION_UI);
      }
      
      private function onUPDATE_PANELACTIVITYEXPEDITION_UI(param1:Event) : void
      {
         setItemUIs();
      }
      
      private function onENTER_FRAME_clip(param1:EnterFrameEvent) : void
      {
         if(mImg_bg_clip)
         {
            mImg_bg_clip.rotation += mClip_rotation;
         }
         if(mBtn_expedition)
         {
            if(mClip_scale >= 360)
            {
               mClip_scale = 0;
            }
            mClip_scale += 5;
            mBtn_expedition.scaleX = mBtn_expedition.scaleY = 1 + Math.abs(Math.sin(deg2rad(mClip_scale))) * 0.2;
         }
      }
      
      private function setItemUIs() : void
      {
         var _loc5_:ItemActivityExpedition = null;
         if(!mQuad)
         {
            mQuad = Tools.newQuad(GlobalData.$mStageWidth,130);
            mQuad.alpha = 0.7;
            addChild(mQuad);
         }
         if(mBox)
         {
            StarlingTools.removeChildrenClear(mBox);
         }
         else
         {
            mBox = new Sprite();
            mBox.addEventListener("touch",onTOUCH);
            addChild(mBox);
         }
         if(mBoxShow)
         {
            StarlingTools.removeChildrenClear(mBoxShow);
         }
         else
         {
            mBoxShow = new Sprite();
            mBoxShow.touchable = false;
            addChild(mBoxShow);
         }
         var _loc7_:uint = 0;
         var _loc3_:uint = 5;
         var _loc6_:Number = 115;
         var _loc4_:String = "";
         var _loc2_:Object = {};
         var _loc1_:Object = GlobalData.$tempExpeditionElements;
         _loc7_ = 0;
         while(_loc7_ < _loc3_)
         {
            _loc5_ = new ItemActivityExpedition();
            _loc2_ = {};
            _loc2_["status"] = 0;
            _loc4_ = GlobalData.$tempExpeditionArr[_loc7_];
            if(_loc4_ != "" && _loc4_ != null)
            {
               if(GlobalData.$tempExpeditionElements[_loc4_])
               {
                  _loc2_ = GlobalData.$tempExpeditionElements[_loc4_];
               }
            }
            _loc5_.data = _loc2_;
            _loc5_.x = int(_loc7_ * _loc6_);
            mBox.addChild(_loc5_);
            _loc7_++;
         }
         mBox.x = int((GlobalData.$mStageWidth - _loc3_ * _loc6_ + 25) * 0.5);
         mBox.y = m9x9_bg.y - m9x9_bg.height - 50;
         mBoxShow.x = mBox.x;
         mBoxShow.y = mBox.y;
         mQuad.y = mBox.y - 10;
      }
      
      private function onTRIGGERED_send(param1:Event) : void
      {
         var _fun:Object;
         var _event:Event = param1;
         var gotoExpedition:* = function():void
         {
            SendServiceAMFFun.send_user_expedition(re_expedition,{"aids":GlobalData.$tempExpeditionArr});
         };
         mTalent = GlobalData.$userData.attrs.avatar_talent;
         var arr_1:Array = GlobalData.$tempExpeditionArr;
         var i:int = 0;
         while(i < arr_1.length)
         {
            if(mTalent != null)
            {
               if(arr_1[i] == mTalent.split("`")[0])
               {
                  GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(98054));
                  return;
               }
            }
            i = i + 1;
         }
         if(GlobalData.$tempExpeditionArr.length > 0)
         {
            _fun = {
               "ok":gotoExpedition,
               "no":GlobalFunction.functionNull
            };
            GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90210),GlobalTextStyle.COLOR_W_B_Y_O),_fun);
         }
         else
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90209));
         }
      }
      
      private function re_expedition(param1:Object) : void
      {
         if(this.stage == null) return;
         SoundManager.getOnlyExample().playSound("E_8003",0.3);
         var _loc4_:Array = param1["params"].aids as Array;
         var _loc5_:Object = param1.data;
         GlobalFunction.clearExpeditionItems();
         mDnStone = Number(_loc5_.gained_dn_stone);
         if(!isFinite(mDnStone)) mDnStone = _loc5_.dn_stone - GlobalData.$userData.attrs.dn_stone;
         GlobalData.$tempExpeditionDnStone = mDnStone > 0 ? mDnStone : 0;
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
         GlobalData.$userData.attrs.dn_stone = _loc5_.dn_stone;
         }
         mTalent = GlobalData.$userData.attrs.avatar_talent;
         var _loc6_:int = 0;
         var _loc2_:int = int(_loc4_.length);
         _loc6_ = 0;
         while(_loc6_ < _loc2_)
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            delete GlobalData.$userData.avatars[_loc4_[_loc6_]];
            }
            _loc6_++;
         }
         for(var _loc3_:Object in _loc5_.get_avatars)
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.avatars[_loc3_] = _loc5_.get_avatars[_loc3_];
            }
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
         GlobalData.$userData.attrs.expedition = _loc5_.attr_expedition;
         }
         GlobalData.$mGameClassObject.touchable = false;
         showExpedition(_loc5_);
      }
      
      private function showExpedition(param1:Object) : void
      {
         var _tween:Tween;
         var _juggler:Juggler;
         var i:int;
         var l:int;
         var _item:ItemActivityExpedition;
         var _spr:Sprite;
         var _radian:Number;
         var _x0:int;
         var _y0:int;
         var _time:Number;
         var _data:Object = param1;
         if(!mBoxShow)
         {
            return;
         }
         _juggler = GlobalData.$mStarling.juggler;
         i = 0;
         l = mBox.numChildren;
         _x0 = mBtn_expedition.x - mBoxShow.x - 15;
         _y0 = mBtn_expedition.y - mBoxShow.y;
         _time = 0.6;
         i = 0;
         while(i < l)
         {
            _item = mBox.getChildAt(i) as ItemActivityExpedition;
            _radian = Math.atan2(_item.y - _y0,_item.x - _x0);
            _spr = _item.mAvatar;
            if(_spr)
            {
               mBoxShow.addChild(_spr);
               _spr.x = _item.x;
               _spr.y = _item.y;
               _juggler.removeTweens(_spr);
               _tween = new Tween(_spr,_time / 2,"easeOut");
               _tween.animate("y",(_y0 + _spr.y) / 2 - 150);
               _juggler.add(_tween);
               _tween = new Tween(_spr,_time / 2,"easeIn");
               _tween.delay = _time / 2;
               _tween.animate("y",_y0);
               _juggler.add(_tween);
               _tween = new Tween(_spr,_time);
               _tween.animate("x",_x0);
               _juggler.add(_tween);
               _tween = new Tween(_spr,_time,"easeIn");
               _tween.scaleTo(0.3);
               _tween.fadeTo(0.2);
               if(i == 0)
               {
                  _tween.onComplete = function(param1:Object):void
                  {
                     setItemUIs();
                     GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_activity_expeditionaward",false,true,param1);
                  };
                  _tween.onCompleteArgs = [_data.get_avatars];
               }
               _juggler.add(_tween);
            }
            i = i + 1;
         }
      }
      
      private function setAwardUIs(param1:Object) : void
      {
         var _loc5_:ItemActivityExpedition = null;
         var _loc11_:Object = null;
         var _loc2_:Object = null;
         var _loc4_:ItemAvatarAward = null;
         GlobalData.$mGameClassObject.touchable = true;
         SoundManager.getOnlyExample().playSound("drop");
         delAwardUIs();
         mBox_award = new Sprite();
         addChild(mBox_award);
         var _loc6_:Quad = Tools.newQuad(GlobalData.$mStageWidth,GlobalData.$center_height_curr - 121,0,0,0);
         _loc6_.alpha = 0.75;
         mBox_award.addChild(_loc6_);
         var _loc9_:Image = GameMapTools.newAvatarImgById("A_1201_5");
         var _loc8_:Scale9Image = GlobalFunction.createScale9Image("UI_bg_vip_buy_0_0000",585,330,new Rectangle(30,25,30,15));
         _loc8_.touchable = false;
         _loc8_.x = int((GlobalData.$mStageWidth - _loc8_.width) * 0.5);
         _loc8_.y = int((GlobalData.$center_height_curr - 121 - _loc8_.height) * 0.5);
         mBox_award.addChild(_loc8_);
         mBox_award.addChild(_loc9_);
         _loc9_.x = int((GlobalData.$mStageWidth - _loc9_.width) * 0.5);
         _loc9_.y = _loc8_.y - _loc9_.height + 30;
         mBtn_close = GlobalFunction.createButtonStarling("UI_box_key_exchange_btn_0_0000",{
            "t":GlobalLanguageStr.getLanguageStr(20121),
            "fs":25,
            "fc":16777215
         });
         mBtn_close.shadowFilter();
         mBtn_close.x = int((GlobalData.$mStageWidth - mBtn_close.width) * 0.5);
         mBtn_close.y = _loc8_.y + _loc8_.height + 5;
         mBtn_close.addEventListener("triggered",onTRIGGERED_awardClose);
         mBox_award.addChild(mBtn_close);
         mBox_result = new Sprite();
         mBox_award.addChild(mBox_result);
         var _loc3_:int = 0;
         var _loc7_:Number = 105;
         for(var _loc10_:Object in param1)
         {
            _loc11_ = {};
            _loc11_["id"] = _loc10_.toString();
            _loc11_["status"] = 1;
            _loc5_ = new ItemActivityExpedition();
            _loc5_.data = _loc11_;
            _loc5_.x = int(_loc3_ * _loc7_);
            mBox_result.addChild(_loc5_);
            _loc3_ += 1;
         }
         if(mDnStone > 0)
         {
            _loc2_ = {
               "id":"dn_stone",
               "num":mDnStone
            };
            _loc4_ = new ItemAvatarAward();
            _loc4_.data = _loc2_;
            _loc5_.x = int(_loc3_ * _loc7_);
            mBox_result.addChild(_loc4_);
            _loc3_ += 1;
         }
         mBox_result.x = _loc8_.x + int((_loc8_.width - _loc3_ * _loc7_ + 15) * 0.5);
         mBox_result.y = _loc8_.y + 30;
      }
      
      private function delAwardUIs() : void
      {
         if(mBtn_close)
         {
            mBtn_close.removeFromParent(true);
         }
         if(mBox_result)
         {
            StarlingTools.removeChildrenClear(mBox_result);
            mBox_result.removeFromParent(true);
         }
         if(mBox_award)
         {
            StarlingTools.removeChildrenClear(mBox_award);
            mBox_award.removeFromParent(true);
         }
         mBtn_close = null;
         mBox_award = null;
         mBox_result = null;
      }
      
      private function onTRIGGERED_awardClose(param1:Event) : void
      {
         delAwardUIs();
      }
      
      private function onTOUCH(param1:TouchEvent) : void
      {
         var _loc2_:Touch = null;
         if(mBox)
         {
            _loc2_ = param1.getTouch(mBox,"began");
            if(_loc2_)
            {
               if(this.parent)
               {
                  if(this.parent is PanelMaze)
                  {
                     GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("expedition_select",false,true);
                  }
               }
            }
         }
      }
   }
}

