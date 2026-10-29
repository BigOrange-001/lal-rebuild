package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelBase;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.global.ConfigManager;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.net.SendAndSelect;
   import com.meng52.events.NetEvent;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.ScrollContainer;
   import feathers.layout.VerticalLayout;
   import starling.animation.Tween;
   import starling.core.Starling;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class PanelActivityExplorationMap extends PanelBase
   {
      
      private var mScrollMap:ScrollContainer;
      
      private var mBg:Image;
      
      private var mBg2:Image;
      
      private var mTween:Tween;
      
      private var mArrow:Image;
      
      private var mFresh_spr:Sprite;
      
      private var mFresh_txt:TextField;
      
      private var mFresh_btn:LOL_Scale9Button;
      
      private var mMap_arr:Array;
      
      private var mBtn_arr:Array;
      
      private var i:int = 0;
      
      private const BATTLENUM:int = 7;
      
      private const FRESH_BTN_NAME:String = "fresh_btn_name";
      
      private const BATTLE_NAME:String = "battlename_";
      
      private const GIFT_NAME:String = "giftname_";
      
      private var freshNum:int;
      private var explorationRequest:String = "";
      private var explorationGeneration:int = 0;
      
      private var _tween:Tween;
      
      private var _tween1:Tween;
      
      private var m_clickImg:Image;
      
      private var m_arrowheadImg:Image;
      
      private var mGuideSpr:Sprite;
      
      private var _cfgNum:int;
      
      private var _count:int;
      
      private var _constNum:int;
      
      private var _mapNum:int;
      
      private var _sp:Sprite = new Sprite();
      
      private var mPart_arr:Array;
      
      private var mWarFog:Image;
      
      public function PanelActivityExplorationMap()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         var _explorationState:Object = GlobalData.$userData.exploration;
         var _mapMax:int = int(GlobalData.$mConfig_simple.explore.map_max);
         var _titleId:int = int(_explorationState.stage) > _mapMax ? 98221 : 98222;
         this.setPopPanelBg(GlobalLanguageStr.getStr(_titleId),GlobalData.$center_height + 100);
         SendAndSelect.$SendServiceAMFDispatcher.addEventListener("error_broadcast",onExplorationError);
         setUI();
      }
      
      private function setUI() : void
      {
         var _loc13_:Sign = null;
         var _loc2_:String = null;
         var _loc1_:int = 0;
         var _loc9_:Object = null;
         var _loc6_:String = null;
         var _loc12_:Image = null;
         var _loc5_:Image = null;
         var _loc3_:LOL_Button = null;
         mMap_arr = [];
         mBtn_arr = [];
         mPart_arr = [];
         _sp = new Sprite();
         var _loc7_:Object = GlobalData.$userData.exploration;
         var _loc4_:Object = GlobalData.$mConfig_simple.explore;
         _cfgNum = GlobalData.$mConfig_simple.explore.map_max;
         _count = _cfgNum * 2;
         _constNum = 7 * 2;
         _mapNum = _count % _constNum == 0 ? _count / _constNum : _count / _constNum + 1;
         i = 0;
         while(i < _mapNum)
         {
            mBg = GlobalFunction.createImage("UI_map_exploration",true);
            mBg.y = mBg.height * i;
            _sp.addChild(mBg);
            mMap_arr.push(mBg);
            i = i + 1;
         }
         i = 1;
         while(i < _count + 1)
         {
            _loc13_ = null;
            _loc2_ = (i % _constNum == 0 ? _constNum : i % _constNum).toString();
            _loc1_ = i % _constNum == 0 ? i / _constNum : i / _constNum + 1;
            _loc9_ = ConfigManager.getInstance().getUIPos("explor_" + _loc2_);
            if(i % 2 == 0)
            {
               if(i / 2 < int(_loc7_.stage))
               {
                  _loc6_ = _loc4_.box_kind[(i / 2 - 1).toString()] == 0 ? "UI_explor_gift_0001" : "UI_explor_gift_0003";
               }
               else
               {
                  _loc6_ = _loc4_.box_kind[(i / 2 - 1).toString()] == 0 ? "UI_explor_gift_0000" : "UI_explor_gift_0002";
               }
               _loc12_ = GlobalFunction.createImage(_loc6_);
               _loc12_.pivotX = _loc12_.width * 0.6;
               _loc12_.pivotY = _loc12_.height * 0.5;
               if(i / 2 > _loc7_.stage)
               {
                  _loc12_.color = 6710886;
               }
               if(i / 2 == _loc7_.stage && _loc7_.current_stage_finish == 0)
               {
                  _loc12_.color = 6710886;
               }
               if(i / 2 < _loc7_.stage)
               {
                  _loc13_ = new Sign(true);
               }
            }
            else
            {
               _loc6_ = _loc9_[ConfigManager.UI];
               _loc12_ = GlobalFunction.createImage(_loc6_,true);
               _loc12_.pivotX = _loc12_.width * 0.5;
               _loc12_.pivotY = _loc12_.height * 0.5;
               _loc12_.scaleX = _loc12_.scaleY = _loc9_.scale;
               if(i / 2 >= _loc7_.stage)
               {
                  _loc12_.color = 6710886;
               }
               if((i + 1) / 2 < _loc7_.stage || (i + 1) / 2 == _loc7_.stage && _loc7_.current_stage_finish == 1)
               {
                  _loc13_ = new Sign();
               }
            }
            _loc12_.x = Number(_loc9_.posX);
            _loc12_.y = mBg.height * (_mapNum - _loc1_) + Number(_loc9_.posY);
            _loc12_.touchable = false;
            mPart_arr.push(_loc12_);
            if(i % 2 == 0)
            {
               _loc5_ = GlobalFunction.createImage("UI_gift_shadow_0000");
               _loc5_.x = _loc12_.x - _loc12_.width * 0.5 + 15;
               _loc5_.y = _loc12_.y - 2;
               _sp.addChild(_loc5_);
            }
            _sp.addChild(_loc12_);
            if(_loc13_)
            {
               _loc13_.x = _loc12_.x;
               _loc13_.y = i % 2 == 0 ? _loc12_.y : _loc12_.y + 30;
               _sp.addChild(_loc13_);
            }
            _loc3_ = new LOL_Button("","UI_btn_mainFun0000",false,false);
            _loc3_.name = (i % 2 == 0 ? "giftname_" : "battlename_") + i.toString();
            _loc3_.pivotX = _loc3_.width * 0.5;
            _loc3_.pivotY = _loc3_.height * 0.5;
            _loc3_.width = _loc9_.width;
            _loc3_.height = _loc9_.height;
            _loc3_.x = _loc12_.x;
            _loc3_.y = _loc12_.y;
            _loc3_.addEventListener("triggered",onTRIGGERED_btn);
            mBtn_arr.push(_loc3_);
            _sp.addChild(_loc3_);
            i = i + 1;
         }
         mGuideSpr = createGuideSpr();
         _sp.addChild(mGuideSpr);
         updateGuidePos();
         mScrollMap = new ScrollContainer();
         var _loc8_:VerticalLayout = new VerticalLayout();
         mScrollMap.layout = _loc8_;
         mScrollMap.setSize(mBg.width,this.mImg9_baseBg.height - 200);
         mScrollMap.pageThrowDuration = 0;
         mScrollMap.verticalScrollPosition = mBg.height * _mapNum - mScrollMap.height;
         mScrollMap.hasElasticEdges = false;
         mScrollMap.x = this.mImg9_baseBg.x + (this.mImg9_baseBg.width - mScrollMap.width) * 0.5;
         mScrollMap.y = 85;
         mScrollMap.addChild(_sp);
         this.addChild(mScrollMap);
         mScrollMap.addEventListener("scroll",scrollFun);
         mFresh_spr = new Sprite();
         this.addChild(mFresh_spr);
         freshNum = GlobalData.$exploration_data.refresh_count;
         var _loc11_:String = GlobalLanguageStr.getLanguageStr(90560,freshNum);
         mFresh_txt = GlobalFunction.createTextField(350,40,_loc11_,"",20,16777215);
         mFresh_spr.addChild(mFresh_txt);
         mFresh_btn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90648),150,70,"UI_btn_normalFun_0000");
         mFresh_btn.x = mFresh_txt.x + mFresh_txt.width + 25;
         mFresh_btn.name = "fresh_btn_name";
         mFresh_btn.addEventListener("triggered",onTRIGGERED);
         mFresh_spr.addChild(mFresh_btn);
         mFresh_txt.y = mFresh_btn.y + (mFresh_btn.height - mFresh_txt.height) * 0.5;
         mFresh_spr.x = (this.mImg9_baseBg.width - mFresh_spr.width) * 0.5 + 30;
         mFresh_spr.y = this.mImg9_baseBg.height - mFresh_spr.height - 35;
         var _loc10_:int = _loc7_.stage % _constNum == 0 ? _loc7_.stage / _constNum : _loc7_.stage / _constNum + 1;
         if(_loc7_.stage * 2 <= _count - 5)
         {
            mWarFog = GlobalFunction.createImage("pic_war_fog",true);
            mWarFog.touchable = false;
            _sp.addChild(mWarFog);
         }
         updateMapPos();
         freshBtnStatus();
      }
      
      private function scrollFun(param1:Event) : void
      {
         if(mWarFog)
         {
            if(mScrollMap.verticalScrollPosition <= mWarFog.y)
            {
               mScrollMap.verticalScrollPosition = mWarFog.y;
            }
            if(mScrollMap.verticalScrollPosition > mBg.height * _mapNum - mScrollMap.height)
            {
               mScrollMap.verticalScrollPosition = mBg.height * _mapNum - mScrollMap.height;
            }
            if(mScrollMap.verticalScrollPosition <= 0)
            {
               mScrollMap.verticalScrollPosition = 0;
            }
         }
         else
         {
            if(mScrollMap.verticalScrollPosition > mBg.height * _mapNum - mScrollMap.height)
            {
               mScrollMap.verticalScrollPosition = mBg.height * _mapNum - mScrollMap.height;
            }
            if(mScrollMap.verticalScrollPosition <= 0)
            {
               mScrollMap.verticalScrollPosition = 0;
            }
         }
      }
      
      private function updateMapPos() : void
      {
         var _loc4_:Object = GlobalData.$userData.exploration;
         var _loc1_:int = 0;
         if(_loc4_.current_stage_finish == 0)
         {
            _loc1_ = _loc4_.stage * 2 - 1;
         }
         else
         {
            _loc1_ = _loc4_.stage * 2;
         }
         if(_loc1_ > _count)
         {
            if(mGuideSpr)
            {
               StarlingTools.removeChildrenClear(mGuideSpr);
            }
            mGuideSpr = null;
            mScrollMap.verticalScrollPosition = 0;
            return;
         }
         var _loc3_:int = _loc1_ % _constNum == 0 ? _loc1_ / _constNum : _loc1_ / _constNum + 1;
         var _loc2_:Object = ConfigManager.getInstance().getUIPos("explor_" + (_loc1_ % _constNum == 0 ? _constNum : _loc1_ % _constNum).toString());
         mGuideSpr.x = Number(_loc2_.posX);
         mGuideSpr.y = mBg.height * (_mapNum - _loc3_) + Number(_loc2_.posY);
         if(_loc1_ < 4)
         {
            mScrollMap.verticalScrollPosition = mBg.height * _mapNum - mScrollMap.height;
            if(mWarFog)
            {
               mWarFog.y = mScrollMap.verticalScrollPosition;
               if(_loc1_ < 4 && _loc1_ > 2)
               {
                  mWarFog.y -= 150;
               }
            }
         }
         else if(_loc1_ > _count - 7)
         {
            mScrollMap.verticalScrollPosition = 0;
            if(mWarFog)
            {
               mWarFog.y = 0;
            }
         }
         else
         {
            mScrollMap.verticalScrollPosition = mBg.height * (_mapNum - _loc3_) + Number(_loc2_.posY) - mScrollMap.height * 0.5;
            if(mWarFog)
            {
               mWarFog.y = mScrollMap.verticalScrollPosition;
            }
         }
      }
      
      private function updateGuidePos() : void
      {
         var _loc5_:Object = GlobalData.$userData.exploration;
         var _loc2_:int = 0;
         if(_loc5_.current_stage_finish == 0)
         {
            _loc2_ = _loc5_.stage * 2 - 1;
         }
         else
         {
            _loc2_ = _loc5_.stage * 2;
         }
         if(_loc2_ > _count)
         {
            if(mGuideSpr)
            {
               StarlingTools.removeChildrenClear(mGuideSpr);
            }
            mGuideSpr = null;
            return;
         }
         var _loc4_:int = int(_loc2_ % _constNum == 0 ? _constNum : _loc2_ % _constNum);
         var _loc1_:int = _loc2_ % _constNum == 0 ? _loc2_ / _constNum : _loc2_ / _constNum + 1;
         var _loc3_:Object = ConfigManager.getInstance().getUIPos("explor_" + _loc4_.toString());
         mGuideSpr.x = Number(_loc3_.posX);
         mGuideSpr.y = mBg.height * (_mapNum - _loc1_) + Number(_loc3_.posY);
      }
      
      private function createGuideSpr() : Sprite
      {
         var _loc1_:Sprite = new Sprite();
         _loc1_.touchable = false;
         m_clickImg = DisplayTools.newImg("guideClick");
         m_clickImg.alpha = 0.6;
         m_clickImg.scaleX = m_clickImg.scaleY = 1.1;
         _loc1_.addChild(m_clickImg);
         m_arrowheadImg = DisplayTools.newImg("guideMouse");
         m_arrowheadImg.pivotX = m_arrowheadImg.width;
         m_arrowheadImg.pivotY = m_arrowheadImg.height / 2;
         m_arrowheadImg.rotation = -2;
         m_arrowheadImg.scaleX = m_arrowheadImg.scaleY = 0.7;
         _loc1_.addChild(m_arrowheadImg);
         _tween = new Tween(m_clickImg,0.5,"easeInOut");
         _tween.scaleTo(1.3);
         _tween.reverse = true;
         _tween.repeatCount = 0;
         Starling.juggler.add(_tween);
         _tween1 = new Tween(m_arrowheadImg,0.5,"easeInOut");
         _tween1.animate("x",m_arrowheadImg.x + 20);
         _tween1.animate("y",m_arrowheadImg.y + 35);
         _tween1.reverse = true;
         _tween1.repeatCount = 0;
         Starling.juggler.add(_tween1);
         return _loc1_;
      }
      
      private function onTRIGGERED(param1:Event) : void
      {
         if(explorationRequest != "" || stage == null) return;
         var counts:Object=GlobalData.$userData.records.exploration_times;
         var cfg:Object=GlobalData.$mConfig_simple.explore;
         if(int(GlobalData.$userData.exploration.current_stage_finish)==1)
         {
            LayoutUIAnimation.getOnlyExample().popWords("请先领取当前关卡奖励，再刷新地图。");return;
         }
         var free:Boolean=int(counts.refresh_count)>0;
         if(!free && int(counts.refresh_buy)>=int(cfg.refresh_num))
         {
            LayoutUIAnimation.getOnlyExample().popWords("今日刷新次数已用完。");return;
         }
         var cost:int=free ? 0 : int(cfg.refresh_price);
         if(GlobalData.$userData.coin<cost) { GlobalFunction.popErrorCoin(cost);return; }
         GlobalFunction.popAlert("刷新探险",free ? "使用1次免费刷新，重新生成地图并恢复英雄生命？" : "消耗"+cost+"金砖刷新地图并恢复英雄生命？",{"ok":freeFresh,"no":GlobalFunction.functionNull});
      }

      private function freeFresh() : void
      {
         requestExploration("user.exploration_refresh");
      }

      private function requestExploration(method:String,params:Object=null) : void
      {
         if(stage == null || explorationRequest != "") return;
         explorationRequest=method;
         var generation:int=++explorationGeneration;
         freshBtnStatus();
         SendAndSelect.sendAndSelectService(method,params == null ? {} : params,function(reply:Object):void
         {
            if(stage == null || generation!=explorationGeneration || explorationRequest!=method) return;
            explorationRequest="";freshBtnStatus();
            if(!reply || int(reply.return_code)!=0 || !reply.data) return;
            if(GlobalFunction.isVersionedProfileReceipt(reply) && !GlobalData.isCurrentProfileSyncEnvelope(reply.state_sync)) return;
            if(method=="user.exploration_refresh") _refun(reply);
            else if(method!="user.exploration_opponent" || int(reply.data.stage)==int(GlobalData.$userData.exploration.stage)) reback(reply);
         });
      }

      private function onExplorationError(event:NetEvent) : void
      {
         if(event.data && String(event.data.method)==explorationRequest)
         {
            explorationGeneration++;explorationRequest="";
            if(stage) freshBtnStatus();
         }
      }

      private function _refun(param1:Object) : void
      {
         if(this.stage == null) return;
         var _loc2_:* = undefined;
         if(param1.data)
         {
            _loc2_ = GlobalData.$exploration_data;
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalFunction.update_UserData(param1.data);
            }
            GlobalData.$exploration_data = param1.data;
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.exploration.army = param1.data.army;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.exploration.combat_army = param1.data.combat_army;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.records.exploration_times.refresh_count = param1.data.refresh_count;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.records.exploration_times.refresh_buy = param1.data.refresh_buy;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.records.exploration_times.relive_buy = param1.data.relive_buy;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.records.exploration_times.mode_buy = param1.data.mode_buy;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.records.exploration_times.vip_relive = param1.data.vip_relive;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.exploration.stage_mode = param1.data.stage_mode;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.exploration.stage = param1.data.stage;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.exploration.current_stage_finish = param1.data.current_stage_finish;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
            GlobalData.$userData.exploration.combat_army = [];
            }
            GlobalData.$mGameClassObject.closePopForPanel();
            GlobalData.$mEventDispatcher.dispatchEventWith("update_exploration_fresh_count",false,{
               "refresh_count":param1.data.refresh_count,
               "stage":param1.data.stage,
               "current_stage_finish":param1.data.current_stage_finish
            });
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("exploration_select_game",false,true,null);
         }
      }
      
      private function freshBtnStatus() : void
      {
         var counts:Object=GlobalData.$userData.records.exploration_times;
         var cfg:Object=GlobalData.$mConfig_simple.explore;
         freshNum=Math.max(0,int(counts.refresh_count));
         var paid:int=Math.max(0,int(cfg.refresh_num)-int(counts.refresh_buy));
         if(mFresh_txt) mFresh_txt.text=freshNum>0 ? "免费刷新："+freshNum+"次" : "付费刷新："+paid+"次 · 每次"+cfg.refresh_price+"金砖";
         if(mFresh_btn) mFresh_btn.enabled=explorationRequest=="" && (freshNum>0 || paid>0) && int(GlobalData.$userData.exploration.current_stage_finish)==0;
      }

      private function onTRIGGERED_btn(param1:Event) : void
      {
         if(explorationRequest != "" || stage == null) return;
         var _loc4_:String = (param1.currentTarget as LOL_Button).name;
         var _loc3_:Array = _loc4_.split("_");
         var _loc2_:int = 0;
         var _loc5_:Object = GlobalData.$userData.exploration;
         if(_loc4_.indexOf("giftname_") != -1)
         {
            _loc2_ = int(_loc3_[1]) / 2;
            if(_loc5_.current_stage_finish == 1)
            {
               if(_loc5_.stage == _loc2_)
               {
                  requestExploration("user.exploration_get_reward");
               }
               else if(_loc5_.stage <= _loc2_)
               {
                  LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getStr(90595));
               }
            }
            else if(_loc5_.stage <= _loc2_)
            {
               LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getStr(90595));
            }
         }
         else if(_loc4_.indexOf("battlename_") != -1)
         {
            _loc2_ = (int(_loc3_[1]) + 1) / 2;
            if(_loc5_.current_stage_finish == 1)
            {
               if(_loc5_.stage < _loc2_)
               {
                  LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getStr(10030));
               }
            }
            else if(_loc5_.stage == _loc2_)
            {
               requestExploration("user.exploration_opponent",{"stage":_loc2_});
            }
            else if(_loc5_.stage <= _loc2_)
            {
               LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getStr(10030));
            }
         }
      }
      
      private function reback(param1:Object) : void
      {
         if(this.stage == null) return;
         var _loc3_:Tween = null;
         var _loc7_:String = null;
         var _loc6_:Object = null;
         var _loc10_:Object = null;
         var _loc2_:String = null;
         var _loc4_:int = 0;
         var _loc5_:Image = null;
         var _loc9_:Image = null;
         var _loc8_:Sign = null;
         if(param1.data)
         {
            switch(param1.method)
            {
               case "user.exploration_opponent":
                  GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("exploration_myteam",false,true,param1.data);
                  break;
               case "user.exploration_get_reward":
                  if(mWarFog != null)
                  {
                     _loc3_ = new Tween(mWarFog,0.7,"easeOut");
                     _loc3_.moveTo(mWarFog.x,mWarFog.y - 150);
                     Starling.juggler.add(_loc3_);
                  }
                  _loc7_ = "sound03";
                  SoundManager.getOnlyExample().playSound(_loc7_);
                  if(!GlobalFunction.isVersionedProfileReceipt(param1))
                  {
                  GlobalData.$userData.exploration.current_stage_finish = param1.data.current_stage_finish;
                  }
                  if(!GlobalFunction.isVersionedProfileReceipt(param1))
                  {
                  GlobalData.$userData.exploration.stage = param1.data.stage;
                  }
                  if(!GlobalFunction.isVersionedProfileReceipt(param1))
                  {
                  GlobalData.$userData.exploration.stage_mode = param1.data.stage_mode;
                  }
                  if(!GlobalFunction.isVersionedProfileReceipt(param1))
                  {
                  GlobalFunction.update_UserData(param1.data);
                  }
                  GlobalData.$mEventDispatcher.dispatchEventWith("update_exploration_fresh_stage",false,{"stage":param1.data.stage});
                  if(param1.data.gifts)
                  {
                     _loc6_ = Tools.changeArrayToObject(param1.data.gifts);
                     GlobalFunction.showReward2({"info":GlobalLanguageStr.getLanguageStr(90131)},_loc6_);
                  }
                  _loc10_ = GlobalData.$mConfig_simple.explore;
                  _loc2_ = _loc10_.box_kind[(param1.data.stage - 2).toString()] == 0 ? "UI_explor_gift_0001" : "UI_explor_gift_0003";
                  _loc4_ = (param1.data.stage - 1) * 2 - 1;
                  _loc5_ = mPart_arr[_loc4_] as Image;
                  _loc9_ = GlobalFunction.createImage(_loc2_,true);
                  _loc9_.pivotX = _loc9_.width * 0.6;
                  _loc9_.pivotY = _loc9_.height * 0.5;
                  _loc9_.x = _loc5_.x;
                  _loc9_.y = _loc5_.y;
                  _sp.addChild(_loc9_);
                  mPart_arr[_loc4_] = null;
                  mPart_arr[_loc4_] = _loc9_;
                  _loc5_.removeFromParent(true);
                  updateGuidePos();freshBtnStatus();
                  _loc8_ = new Sign(true);
                  _loc8_.x = (mPart_arr[(param1.data.stage - 1) * 2 - 1] as Image).x;
                  _loc8_.y = (mPart_arr[(param1.data.stage - 1) * 2 - 1] as Image).y;
                  _sp.addChild(_loc8_);
                  if((param1.data.stage - 1) * 2 < mPart_arr.length)
                  {
                     mPart_arr[(param1.data.stage - 1) * 2].color = 16777215;
                  }
            }
         }
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         var _loc2_:Image = null;
         var _loc3_:LOL_Button = null;
         explorationGeneration++;explorationRequest="";
         SendAndSelect.$SendServiceAMFDispatcher.removeEventListener("error_broadcast",onExplorationError);
         super.onREMOVED_FROM_STAGE(param1);
         if(mFresh_spr)
         {
            StarlingTools.removeChildrenClear(mFresh_spr);
            mFresh_spr.removeFromParent(true);
         }
         mFresh_spr = null;
         if(mFresh_txt)
         {
            mFresh_txt.dispose();
            mFresh_txt.removeFromParent(true);
         }
         mFresh_txt = null;
         if(mFresh_btn)
         {
            mFresh_btn.dispose();
            mFresh_btn.removeFromParent(true);
         }
         mFresh_btn = null;
         if(mScrollMap)
         {
            mScrollMap.dispose();
            mScrollMap.removeFromParent(true);
         }
         mScrollMap = null;
         if(mBg)
         {
            mBg.dispose();
            mBg.removeFromParent(true);
         }
         mBg = null;
         if(mBg2)
         {
            mBg2.dispose();
            mBg2.removeFromParent(true);
         }
         mBg2 = null;
         if(mTween)
         {
            Starling.juggler.remove(mTween);
         }
         mTween = null;
         if(mArrow)
         {
            mArrow.dispose();
            mArrow.removeFromParent(true);
         }
         mArrow = null;
         if(_tween)
         {
            Starling.juggler.remove(_tween);
         }
         if(_tween1)
         {
            Starling.juggler.remove(_tween1);
         }
         if(m_clickImg)
         {
            m_clickImg.removeFromParent(true);
         }
         if(m_arrowheadImg)
         {
            m_arrowheadImg.removeFromParent(true);
         }
         _tween = null;
         _tween1 = null;
         m_clickImg = null;
         m_arrowheadImg = null;
         while(mMap_arr.length > 0)
         {
            _loc2_ = mMap_arr.pop();
            _loc2_.dispose();
            _loc2_.removeFromParent(true);
            _loc2_ = null;
         }
         mMap_arr = [];
         while(mBtn_arr.length > 0)
         {
            _loc3_ = mBtn_arr.pop();
            _loc3_.dispose();
            _loc3_.removeFromParent(true);
            _loc3_ = null;
         }
         mBtn_arr = [];
         while(mPart_arr.length)
         {
            _loc2_ = mPart_arr.pop();
            _loc2_.dispose();
            _loc2_.removeFromParent(true);
            _loc2_ = null;
         }
         mPart_arr = [];
      }
   }
}

import starling.display.Image;
import starling.display.Sprite;
import starling.text.TextField;

class Sign extends Sprite
{
   
   private var _mImg:Image;
   
   private var _mInfo:TextField;
   
   public function Sign(param1:Boolean = false)
   {
      super();
   }
}
