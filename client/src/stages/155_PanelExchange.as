package com.meng52.game.ui.screen
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.ui.element.ItemExchange;
   import com.meng52.game.ui.element.LOL_IconText;
   import com.meng52.game.ui.element.LOL_MutilTextFieldIcon;
   import com.meng52.net.SendAndSelect;
   import feathers.controls.List;
   import feathers.data.ListCollection;
   import feathers.layout.VerticalLayout;
   import starling.events.Event;
   import starling.text.TextField;

   public class PanelExchange extends PanelCenterMainAvatar
   {

      private var mTxt_medalNum:TextField;

      private var _txt_coin:LOL_MutilTextFieldIcon;

      private var _icon_bg:LOL_IconText;

      private var mRecruitRequest:int = 0;

      public function PanelExchange()
      {
         super();
      }

      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg("勋章兑换",GlobalData.$center_height_curr - 121);
         this.addEventListener("close_panel_self",onCLOSE_PANEL_SELF);
         setSmallTabBar([{"label":"英雄兑换"},{"label":"装备兑换"}],tabBar_changeHandler,tabBar_CREATION_COMPLETE,116,55);
         var _loc5_:int = 7;
         var _loc3_:Number = 160;
         var _loc4_:TextField = GlobalTextStyle.getTextField("勋章余额",20,16777215,"left",_loc3_,46);
         _loc4_.x = 45 + _loc5_;
         _loc4_.y = 155 + _loc5_;
         _txt_coin = new LOL_MutilTextFieldIcon("","0","UI_exchange_icon_0_0000");
         _txt_coin.iconScale = 0.65;
         _icon_bg = new LOL_IconText("勋章余额");
         _icon_bg.x = 45 + _loc5_ - 20;
         _icon_bg.y = _loc5_ + GlobalData.$center_height_curr - 121 - 70;
         _icon_bg.bgWidth = 575;
         addChild(_icon_bg);
         addChild(_txt_coin);
         _txt_coin.x = MainConfig.$isEnglish ? _icon_bg.x + 107 : _icon_bg.x + 120;
         _txt_coin.y = _icon_bg.y - 1;
         var _loc2_:int = int(GlobalData.$mConfig_simple.medal_fun);
         this.mTabBar.selectedIndex = _loc2_;
      }

      public function updateInfo() : void
      {
         var _loc2_:Boolean = false;
         if(this.mTabBar.selectedIndex == 0)
         {
            _loc2_ = true;
         }
         else
         {
            _loc2_ = false;
         }
         var _loc1_:String = "";
         if(_txt_coin)
         {
            _txt_coin.txt2 = GlobalData.$userData.medal;
         }
      }

      override public function tabBar_CREATION_COMPLETE(param1:*) : void
      {
         mTabBar.y = 90;
         mTabBar.x = this.mImg9_baseBg.y + 40;
         update();
      }

      override public function onBTN_NAME_BACK() : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_casino");
      }

      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         mRecruitRequest++;
         GlobalData.$mStarling.juggler.removeTweens(this);
         if(mTxt_medalNum)
         {
            mTxt_medalNum.removeFromParent(true);
         }
         super.onREMOVED_FROM_STAGE(param1);
         mTxt_medalNum = null;
      }

      override public function tabBar_changeHandler(param1:Event) : void
      {
         if(mTabBar)
         {
            update();
         }
      }

      override public function setList() : void
      {
         var _rulerH:Number;
         var settings:Object;
         var _layout:VerticalLayout;
         var tweenComplete:* = function():void
         {
            isReady = true;
         };
         isReady = false;
         isOut = true;
         GlobalData.$mStarling.juggler.tween(this,0.4,{"onComplete":tweenComplete});
         this.delList();
         if(this.mList == null)
         {
            _rulerH = 200;
            settings = {
               "paging":0,
               "gap":0,
               "horizontalGap":20,
               "verticalGap":20,
               "paddingTop":0,
               "paddingRight":0,
               "paddingBottom":0,
               "paddingLeft":0,
               "horizontalAlign":"center",
               "verticalAlign":"top"
            };
            _layout = new VerticalLayout();
            _layout.paddingTop = settings.paddingTop;
            _layout.paddingRight = settings.paddingRight;
            _layout.paddingBottom = settings.paddingBottom;
            _layout.paddingLeft = settings.paddingLeft;
            _layout.horizontalAlign = settings.horizontalAlign;
            _layout.verticalAlign = settings.verticalAlign;
            _layout.hasVariableItemDimensions = true;
            this.mList = new List();
            this.mList.isSelectable = false;
            this.mList.width = GlobalData.$mStageWidth - 20;
            this.mList.height = mListH = GlobalData.$center_height_curr - 121 - _rulerH - 25;
            this.mList.layout = _layout;
            this.mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
            this.mList.x = int((GlobalData.$mStageWidth - this.mList.width) * 0.5);
            this.mList.y = mListY = _rulerH - 40;
            this.mList.snapScrollPositionsToPixels = true;
            this.addChild(this.mList);
            settings = null;
            _layout = null;
            this.mList.dataProvider = new ListCollection();
         }
      }

      override public function addList() : void
      {
         if(this.mTabBar && this.mTabBar.selectedIndex == 0)
         {
            loadDailyRecruit();
            return;
         }
         var _loc15_:Array = null;
         var _loc16_:Object = null;
         var _loc13_:Object = null;
         var _loc21_:Object = null;
         var _loc6_:Array = null;
         var _loc17_:String = null;
         var _loc18_:Array = null;
         var _loc23_:Object = null;
         var _loc11_:int = 0;
         var _loc12_:Boolean = this.mTabBar.selectedIndex == 0;
         var _loc9_:String = _loc12_ ? "avatar" : "equip";
         var _loc3_:Object = GlobalData.$mConfig_exchange[_loc9_];
         var _loc20_:Object = null;
         if(_loc12_)
         {
            _loc15_ = _loc3_.cycle_exchange as Array;
            _loc23_ = checkAvatarExchange();
            _loc20_ = _loc23_.start ? _loc15_[_loc23_.id] : {};
            _loc16_ = {};
            for(var _loc10_:Object in _loc3_.exchange)
            {
               _loc16_[_loc10_.toString()] = _loc3_.exchange[_loc10_];
            }
            for(var _loc8_:Object in _loc20_)
            {
               _loc16_[_loc8_.toString()] = _loc20_[_loc8_];
            }
         }
         else
         {
            _loc16_ = _loc3_.exchange;
         }
         _loc6_ = [];
         var _loc4_:Array = GlobalData.$mConfig_festival[_loc9_];
         var _loc2_:Object = null;
         var _loc19_:Object = {};
         var _loc5_:Number = 0;
         var _loc14_:Number = 0;
         var _loc7_:Number = SendAndSelect.$systemTimer_nowSecond;
         var _loc1_:Boolean = false;
         _loc11_ = 0;
         while(_loc11_ < _loc4_.length)
         {
            _loc2_ = _loc4_[_loc11_];
            _loc5_ = (_loc2_.start_time as Date).time * 0.001;
            _loc14_ = (_loc2_.end_time as Date).time * 0.001;
            if(_loc7_ >= _loc5_ && _loc7_ < _loc14_)
            {
               _loc1_ = true;
               break;
            }
            _loc11_++;
         }
         if(_loc1_)
         {
            _loc19_ = _loc2_.exchange;
            for(_loc13_ in _loc19_)
            {
               _loc21_ = {};
               _loc17_ = _loc13_.toString();
               _loc18_ = _loc17_.split("_");
               _loc21_["status"] = _loc12_;
               _loc21_["indexID_s"] = _loc9_;
               _loc21_["id"] = _loc17_;
               _loc21_["medal"] = _loc12_ ? _loc19_[_loc13_] : _loc19_[_loc13_][0];
               if(!_loc12_)
               {
                  _loc21_["status_vip"] = _loc19_[_loc13_][1];
               }
               _loc21_["sort_1"] = _loc18_[2];
               _loc21_["sort_2"] = _loc18_[1];
               _loc21_["sort_3"] = -2;
               _loc21_["start_time"] = _loc5_;
               _loc21_["end_time"] = _loc14_;
               _loc21_["medal_old"] = _loc12_ ? (_loc3_.exchange[_loc17_] ? _loc3_.exchange[_loc17_] : _loc19_[_loc17_] * 2) : (_loc3_.exchange[_loc17_] ? _loc3_.exchange[_loc17_][0] : _loc19_[_loc17_][0] * 2);
               _loc6_.push(_loc21_);
            }
         }
         var _loc22_:Object = checkAvatarExchange();
         for(_loc13_ in _loc16_)
         {
            if(!(!_loc12_ && _loc16_[_loc13_][1] > GlobalData.$userData.vip_lv + 2))
            {
               if(_loc13_.toString() != "info")
               {
                  _loc21_ = {};
                  _loc17_ = _loc13_.toString();
                  if(_loc19_[_loc17_] == null)
                  {
                     _loc18_ = _loc17_.split("_");
                     _loc21_["status"] = _loc12_;
                     _loc21_["indexID_s"] = _loc9_;
                     _loc21_["id"] = _loc17_;
                     _loc21_["medal"] = _loc12_ ? _loc16_[_loc13_] : _loc16_[_loc13_][0];
                     if(!_loc12_)
                     {
                        _loc21_["status_vip"] = _loc16_[_loc13_][1];
                        if(!GlobalFunction.checkIOSvip())
                        {
                           if(_loc21_["status_vip"] > 0)
                           {
                              continue;
                           }
                        }
                     }
                     _loc21_["sort_1"] = _loc18_[2];
                     _loc21_["sort_2"] = _loc18_[1];
                     _loc21_["sort_3"] = 0;
                     _loc21_["start_time"] = 0;
                     _loc21_["end_time"] = 0;
                     _loc21_["medal_old"] = 0;
                     if(_loc20_ != null)
                     {
                        if(_loc20_[_loc17_] != null)
                        {
                           _loc21_["sort_3"] = -1;
                           _loc21_["end_time"] = _loc22_.endDate;
                           _loc21_["medal_old"] = _loc3_.exchange[_loc17_] ? _loc3_.exchange[_loc17_] : _loc20_[_loc17_] * 2;
                        }
                     }
                     _loc6_.push(_loc21_);
                  }
               }
            }
         }
         updateInfo();
         if(_loc12_)
         {
            _loc6_.sortOn(["sort_3","medal_old","sort_1","sort_2"],[16,0x10 | 2,2,2]);
         }
         else
         {
            _loc6_.sortOn(["sort_3","status_vip","sort_1","sort_2"],[16,0x10 | 2,2,16]);
         }
         this.setListTimer(mList,_loc6_,ItemExchange,false);
         GuideMaster.getOnlyExample().checkGuide("M8_1");
      }

      private function loadDailyRecruit() : void
      {
         var request:int = ++mRecruitRequest;
         updateInfo();
         SendAndSelect.sendAndSelectService("user.recruit_exchange_info",{},function(result:Object):void
         {
            if(request != mRecruitRequest || stage == null || mTabBar == null || mTabBar.selectedIndex != 0)
            {
               return;
            }
            if(result == null || int(result.return_code) != 0 || result.data == null ||
               !(result.data.heroes is Array) || result.data.day == null ||
               result.data.heroes.length != 20 ||
               (result.state_sync && !GlobalData.isCurrentProfileSyncEnvelope(result.state_sync)))
            {
               return;
            }
            var rows:Array = [];
            var heroes:Array = result.data.heroes as Array;
            for(var i:int = 0; i < heroes.length; i++)
            {
               var hero:Object = heroes[i];
               if(hero == null || !(hero.aid is String) || int(hero.medal) != 80 ||
                  GlobalData.$mConfig_avatar[hero.aid] == null)
               {
                  return;
               }
               rows.push({"status":true,"indexID_s":"avatar","id":hero.aid,
                          "medal":80,"medal_old":0,"daily_recruit":true,
                          "day":String(result.data.day),"sort_3":0});
            }
            if(mList == null)
            {
               return;
            }
            mList.dataProvider = new ListCollection();
            setListTimer(mList,rows,ItemExchange,false);
            GuideMaster.getOnlyExample().checkGuide("M8_1");
         });
      }

      private function checkAvatarExchange() : Object
      {
         var _loc1_:Object = GlobalData.$mConfig_exchange["avatar"];
         var _loc8_:Number = (_loc1_.start_time as Date).time * 0.001;
         var _loc7_:Number = 0;
         var _loc9_:Number = _loc1_.cycle_days * 24 * 60 * 60;
         var _loc3_:Number = SendAndSelect.$systemTimer_nowSecond;
         var _loc6_:Number = 0;
         var _loc5_:Number = 0;
         var _loc4_:int = int((_loc1_.cycle_exchange as Array).length);
         var _loc2_:Boolean = false;
         _loc7_ = Math.floor(_loc3_ - _loc8_);
         if(_loc7_ >= 0)
         {
            _loc2_ = true;
            _loc6_ = Math.floor(_loc7_ / _loc9_);
            _loc5_ = _loc6_ % _loc4_;
         }
         return {
            "id":_loc5_,
            "end":_loc7_,
            "start":_loc2_,
            "endDate":_loc8_ + (_loc6_ + 1) * _loc9_ - _loc3_
         };
      }

      private function checkEquipExchange() : Object
      {
         var _loc1_:Object = GlobalData.$mConfig_exchange["equip"];
         var _loc8_:Number = (_loc1_.start_time as Date).time * 0.001;
         var _loc7_:Number = (_loc1_.end_time as Date).time * 0.001;
         var _loc9_:Number = _loc1_.cycle_days * 24 * 60 * 60;
         var _loc3_:Number = SendAndSelect.$systemTimer_nowSecond;
         var _loc6_:Number = 0;
         var _loc5_:Number = 0;
         var _loc4_:int = int((_loc1_.exchange as Array).length);
         var _loc2_:Boolean = false;
         _loc7_ = Math.floor(_loc3_ - _loc8_);
         if(_loc7_ >= 0)
         {
            _loc2_ = true;
            _loc6_ = Math.floor(_loc7_ / _loc9_);
            _loc5_ = _loc6_ % _loc4_;
         }
         return {
            "id":_loc5_,
            "end":_loc7_,
            "start":_loc2_,
            "endDate":_loc8_ + (_loc6_ + 1) * _loc9_ - _loc3_
         };
      }
   }
}
