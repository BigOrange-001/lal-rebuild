package com.meng52.game.ui.screen
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.ui.element.ItemAvatarSell;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelCenterDNTeam;
   import com.meng52.net.RpcStaticCall;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.Tools;
   import flash.utils.getQualifiedClassName;
   import starling.display.Sprite;
   import starling.events.Event;
   
   public class PanelAvatarSell extends PanelCenterMainAvatar
   {

      public static const SELL_BATCH_MAX:int = 100;

      public static function createRosterFilters(state:Object, refresh:Function, width:Number) : Sprite
      {
         var bar:Sprite = new Sprite();
         var quality:LOL_Scale9Button = new LOL_Scale9Button("",140,30,"UI_btn_enterGame_0_0000");
         var order:LOL_Scale9Button = new LOL_Scale9Button("",150,30,"UI_btn_enterGame_0_0000");
         var direction:LOL_Scale9Button = new LOL_Scale9Button("",110,30,"UI_btn_enterGame_0_0000");
         var labels:Array = ["全部","灰","白","绿","蓝","紫","橙","红"];
         var orders:Array = ["默认排序","按等级","按上阵情况"];
         var repaint:Function = function():void
         {
            quality.text = "品质："+labels[int(state.quality)];
            order.text = orders[int(state.order)];
            direction.text = state.descending ? "降序 ↓" : "升序 ↑";
         };
         quality.x = (width-412)*0.5;
         order.x = quality.x+146;
         direction.x = order.x+156;
         for each(var button:LOL_Scale9Button in [quality,order,direction])
         {
            button.fontSize = 17;
            bar.addChild(button);
         }
         quality.addEventListener("triggered",function(event:Event):void
         {
            state.quality = (int(state.quality)+1)%8;
            repaint();refresh();
         });
         order.addEventListener("triggered",function(event:Event):void
         {
            state.order = (int(state.order)+1)%3;
            repaint();refresh();
         });
         direction.addEventListener("triggered",function(event:Event):void
         {
            state.descending = !state.descending;
            repaint();refresh();
         });
         repaint();
         return bar;
      }

      public static function filterRosterRows(rows:Array, state:Object) : Array
      {
         var result:Array = [];
         var ranks:Object = {};
         var profile:Object = GlobalData.$userData;
         var member:Object;
         var node:Object;
         if(profile && profile.attrs && profile.attrs.dn)
         {
            for each(node in profile.attrs.dn)
            {
               if(node is Array && node.length > 1 && node[1] != null) ranks[String(node[1])] = 2;
            }
         }
         var main:Array = state.previewTeam is Array ? state.previewTeam as Array : (profile && profile.team ? profile.team[0] as Array : null);
         if(main)
         {
            for each(member in main) if(member != null) ranks[String(member)] = 3;
         }
         for each(var row:Object in rows)
         {
            if(!row || row.id == null) continue;
            var id:String = String(row.id);
            var base:String = row.aid ? String(row.aid).split("|")[0] : id.split("|")[0];
            var parts:Array = base.split("_");
            var star:int = parts.length > 2 ? int(parts[2]) : int(row.star);
            if(int(state.quality) == 0 || star == int(state.quality)) result.push(row);
         }
         if(int(state.order) > 0)
         {
            result.sort(function(a:Object,b:Object):int
            {
               var av:Number = int(state.order) == 1 ? Number(a.lv || 1) : (ranks[String(a.id)] || 1);
               var bv:Number = int(state.order) == 1 ? Number(b.lv || 1) : (ranks[String(b.id)] || 1);
               if(av != bv) return (av > bv ? 1 : -1)*(state.descending ? -1 : 1);
               var aid:String = String(a.id);
               var bid:String = String(b.id);
               return aid < bid ? -1 : (aid > bid ? 1 : 0);
            });
         }
         else if(!state.descending) result.reverse();
         return result;
      }
      
      public static var $tabBarSelectedIndex:int = 0;
      
      public static var BTN_NAME_CLEAR:String = "btn_name_clear";
      
      public static var BTN_NAME_SELL:String = "btn_name_sell";

      public static var $rarityFilter:Object = {"2":true,"3":true,"4":true,"5":true,"6":true};
      
      public var mBtn_clear:LOL_Scale9Button;
      
      public var mBtn_sell:LOL_Scale9Button;
      
      public var mTxt_info:TextFieldHtmlRenderer;
      
      private var mGold_all:Number = 0;
      
      public var tempSelect:int = 0;
      
      public var firstSelect:int = 0;

      protected var mRarityFilter:Object = $rarityFilter;

      protected var mRarityBtns:Array = [];

      protected var mRarityRowHeight:Number = 40;

      protected var mRarityDiagEvent:String = "sell-open";

      private var mSellViewEpoch:uint = 0;

      private function refreshGlobalGold() : void
      {
         var _game:Object = GlobalData.$mGameClassObject;
         if(_game != null && _game.mLayoutUITop != null && _game.mLayoutUITop.mPanelTopMain != null && _game.mLayoutUITop.mPanelTopMain.stage != null)
         {
            _game.mLayoutUITop.mPanelTopMain.updateGold();
         }
      }
      
      public function PanelAvatarSell()
      {
         super();
      }

      public static function isHeroAssigned(param1:String) : Boolean
      {
         var _row:Array = null;
         var _value:Object = null;
         var _teams:Array = GlobalData.$userData && GlobalData.$userData.team is Array ? GlobalData.$userData.team as Array : [];
         for each(_row in _teams)
         {
            if(_row is Array && _row.indexOf(param1) >= 0)
            {
               return true;
            }
         }
         if(GlobalData.$userData && GlobalData.$userData.attrs)
         {
            if(containsHero(GlobalData.$userData.attrs.defensive_squad,param1) || PanelCenterDNTeam.checkIsInDn(param1) != null)
            {
               return true;
            }
         }
         if(GlobalData.$userData && GlobalData.$userData.exploration && GlobalData.$userData.exploration.army && GlobalData.$userData.exploration.army.hasOwnProperty(param1))
         {
            return true;
         }
         if(GlobalData.$tempExpeditionArr is Array && GlobalData.$tempExpeditionArr.indexOf(param1) >= 0)
         {
            return true;
         }
         _value = GlobalData.$exploration_select_avatar;
         if(_value && _value.hasOwnProperty(param1))
         {
            return true;
         }
         _teams = GlobalData.$exploration_team_avatar as Array;
         if(_teams)
         {
            for each(_value in _teams)
            {
               if(_value && _value.name == param1)
               {
                  return true;
               }
            }
         }
         return false;
      }

      private static function containsHero(param1:Object, param2:String) : Boolean
      {
         var _value:Object = null;
         if(param1 == null)
         {
            return false;
         }
         if(param1 is String)
         {
            return param1 == param2;
         }
         for each(_value in param1)
         {
            if(containsHero(_value,param2))
            {
               return true;
            }
         }
         return false;
      }

      public static function isAutoBlocked(param1:Object) : Boolean
      {
         return param1 == null || int(param1.lv) > 1 || hasLearnedTalent(param1);
      }

      public static function hasLearnedTalent(param1:Object) : Boolean
      {
         var _talent:Object = null;
         var _id:Object = null;
         if(param1 == null || !param1.hasOwnProperty("talent"))
         {
            return false;
         }
         _talent = param1["talent"];
         if(_talent == null)
         {
            return false;
         }
         if(_talent is String)
         {
            return String(_talent).length > 0;
         }
         if(_talent is Object && _talent.hasOwnProperty("id"))
         {
            _id = _talent["id"];
            return _id != null && String(_id).length > 0;
         }
         return false;
      }

      public static function matchesRarity(param1:String) : Boolean
      {
         var _parts:Array = param1.split("|")[0].split("_");
         var _star:int = _parts.length > 2 ? int(_parts[2]) : 0;
         var _key:String = _star <= 2 ? "2" : (_star >= 6 ? "6" : _star.toString());
         return $rarityFilter[_key] === true;
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         this.setHeaderFun(GlobalLanguageStr.getLanguageStr(20069),"",true);
         GlobalFunction.clearSellItems();
         $rarityFilter = createDefaultRarityFilter();
         mRarityFilter = $rarityFilter;
         this.mImgBg = GlobalFunction.createImage("UI_bg_0_6_0000");
         this.mImgBg.x = int((GlobalData.$mStageWidth - this.mImgBg.width) * 0.5) + 2;
         this.mImgBg.y = GlobalData.$center_height_curr - 121 - this.mImgBg.height + 15;
         this.addChild(this.mImgBg);
         this.mBtn_clear = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90990),140,70,"UI_btn_normalFun_0000");
         this.mBtn_sell = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20072),140,70,"UI_btn_normalFun_0000");
         this.mBtn_clear.x = this.mImgBg.x + 20;
         this.mBtn_sell.x = this.mImgBg.x + this.mImgBg.width - this.mBtn_sell.width - 20;
         this.addChild(this.mBtn_clear);
         this.addChild(this.mBtn_sell);
         this.mBtn_clear.name = BTN_NAME_CLEAR;
         this.mBtn_sell.name = BTN_NAME_SELL;
         this.mBtn_clear.addEventListener("triggered",this.onTRIGGERED_btns);
         this.mBtn_sell.addEventListener("triggered",this.onTRIGGERED_btns);
         this.mBtn_sell.y = this.mBtn_clear.y = this.mImgBg.y + 25;
         this.createRarityFilters((GlobalData.$mStageWidth - 5 * 56 + 10) * 0.5,160);
         GlobalData.$mEventDispatcher.addEventListener("update_avatar_sell_data",this.onUPDATE_AVATAR_DATA);
         setTabBar([{"label":GlobalLanguageStr.getLanguageStr(20236)},{"label":GlobalLanguageStr.getLanguageStr(20165)},{"label":GlobalLanguageStr.getLanguageStr(20255)},{"label":GlobalLanguageStr.getLanguageStr(20256)},{"label":GlobalLanguageStr.getLanguageStr(20257)}],tabBar_changeHandler);
         this.mTabBar.selectedIndex = $tabBarSelectedIndex;
      }
      
      override public function tabBar_changeHandler(param1:Event) : void
      {
         if(mTabBar)
         {
            if(this.mList)
            {
               this.mList.stopScrolling();
            }
            update();
         }
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         mSellViewEpoch += 1;
         GlobalData.$mEventDispatcher.removeEventListener("update_avatar_sell_data",this.onUPDATE_AVATAR_DATA);
         GlobalFunction.clearSellItems();
         clearPriv(param1);
      }
      
      public function clearPriv(param1:Event) : void
      {
         if(mTxt_info)
         {
            mTxt_info.removeFromParent(true);
            mTxt_info.dispose();
         }
         if(this.mBtn_clear)
         {
            mBtn_clear.removeFromParent(true);
            this.mBtn_clear.dispose();
         }
         if(this.mBtn_sell)
         {
            mBtn_sell.removeFromParent(true);
            this.mBtn_sell.dispose();
         }
         for each(var _rarityBtn:LOL_Scale9Button in mRarityBtns)
         {
            _rarityBtn.removeEventListener("triggered",onRarityFilter);
            _rarityBtn.removeFromParent(true);
            _rarityBtn.dispose();
         }
         mRarityBtns = [];
         if(mImgBg)
         {
            mImgBg.removeFromParent(true);
            this.mImgBg.dispose();
         }
         if(mImg9x9_bg)
         {
            mImg9x9_bg.removeFromParent(true);
            mImg9x9_bg.dispose();
         }
         super.onREMOVED_FROM_STAGE(param1);
         this.mTxt_info = null;
         this.mBtn_clear = null;
         this.mBtn_sell = null;
         this.mImgBg = null;
         this.mImg9x9_bg = null;
         tempSelect = 0;
         firstSelect = 0;
      }
      
      public function updataForSearch() : void
      {
         this.setList();
         this.addList();
      }

      protected function createRarityFilters(param1:Number, param2:Number, param3:Object = null) : void
      {
         if(param3 != null)
         {
            mRarityFilter = normalizeRarityFilter(param3);
         }
         var _labels:Array = ["白","绿","蓝","紫","橙"];
         var _stars:Array = ["2","3","4","5","6"];
         var _button:LOL_Scale9Button = null;
         var _i:int = 0;
         while(_i < _stars.length)
         {
            _button = new LOL_Scale9Button((_labels[_i] as String) + (mRarityFilter[_stars[_i]] === true ? "开" : "关"),56,34,"UI_btn_enterGame_0_0000");
            _button.name = "rarity_" + _stars[_i];
            _button.x = param1 + _i * 58;
            _button.y = param2;
            _button.addEventListener("triggered",onRarityFilter);
            addChild(_button);
            mRarityBtns.push(_button);
            _button.text = (_labels[_i] as String) + (mRarityFilter[_stars[_i]] === true ? "开" : "关");
            _i++;
         }
      }

      protected function onRarityFilter(param1:Event) : void
      {
         var _button:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         var _star:String = _button.name.substr(7);
         mRarityFilter[_star] = mRarityFilter[_star] !== true;
         _button.text = ({"2":"白","3":"绿","4":"蓝","5":"紫","6":"橙"}[_star]) + (mRarityFilter[_star] === true ? "开" : "关");
         mRarityDiagEvent = "sell-filter-" + _star;
         this.update();
      }
      
      override public function update() : void
      {
         this.setList();
         this.addList();
         this.formatTxtInfo();
         this.bringRarityFiltersToFront();
         this.reportRarityDiagnostic(mRarityDiagEvent,getRaritySelectionCount());
         mRarityDiagEvent = "sell-update";
         GuideMaster.getOnlyExample().nextGuideStep();
      }

      protected function normalizeRarityFilter(param1:Object) : Object
      {
         var _filter:Object = param1 == null ? {} : param1;
         var _keys:Array = ["2","3","4","5","6"];
         var _key:String = "";
         for each(_key in _keys)
         {
            if(!_filter.hasOwnProperty(_key))
            {
               _filter[_key] = true;
            }
         }
         return _filter;
      }

      protected function createDefaultRarityFilter() : Object
      {
         return {"2":true,"3":true,"4":true,"5":true,"6":true};
      }

      protected function getRaritySelectionCount() : int
      {
         return GlobalData.$tempSell == null ? 0 : GlobalData.$tempSell.length;
      }

      protected function layoutRarityFilters(param1:Number) : void
      {
         var _button:LOL_Scale9Button = null;
         var _i:int = 0;
         while(_i < mRarityBtns.length)
         {
            _button = mRarityBtns[_i] as LOL_Scale9Button;
            if(_button)
            {
               _button.y = param1;
            }
            _i++;
         }
      }

      protected function bringRarityFiltersToFront() : void
      {
         var _button:LOL_Scale9Button = null;
         for each(_button in mRarityBtns)
         {
            if(_button && _button.parent == this)
            {
               setChildIndex(_button,numChildren - 1);
            }
         }
      }

      protected function reportRarityDiagnostic(param1:String, param2:int) : void
      {
         var _button:LOL_Scale9Button = null;
         var _buttons:Array = [];
         var _children:Array = [];
         var _i:int = 0;
         for each(_button in mRarityBtns)
         {
            if(_button)
            {
               _buttons.push(String(_button.text) + "@" + int(_button.x) + "," + int(_button.y) + "," + int(_button.width) + "x" + int(_button.height) + "#" + (_button.parent == this ? getChildIndex(_button) : -1) + ":" + String(_button.visible));
            }
         }
         _i = 0;
         while(_i < numChildren && _i < 24)
         {
            _children.push(String(getChildAt(_i).name) + ":" + getQualifiedClassName(getChildAt(_i)));
            _i++;
         }
         if(RpcStaticCall.$remoting != null)
         {
            RpcStaticCall.$remoting.reportDiagnostic("ROSTER_SELECT_UI event=" + param1 + " selected=" + param2 + " button=" + (mBtn_clear ? String(mBtn_clear.text) : "null") + " filters=" + String(mRarityFilter) + " filter_buttons=" + _buttons.join("|") + " list=" + (mList ? int(mList.x) + "," + int(mList.y) + "," + int(mList.width) + "x" + int(mList.height) + "#" + getChildIndex(mList) : "null") + " tab=" + (mTabBar ? int(mTabBar.x) + "," + int(mTabBar.y) + "," + int(mTabBar.width) + "x" + int(mTabBar.height) + "#" + getChildIndex(mTabBar) : "null") + " children=" + _children.join("|"));
         }
      }
      
      public function onTRIGGERED_btns(param1:Event) : void
      {
         var _loc4_:int = 0;
         var _loc2_:Object = null;
         var _loc3_:Object = null;
         var _loc5_:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         if(_loc5_.name == BTN_NAME_CLEAR)
         {
            mRarityDiagEvent = GlobalData.$tempSell.length > 0 ? "sell-clear" : "sell-quick-select";
            if(GlobalData.$tempSell.length > 0)
            {
               tempSelect = 0;
            }
            else
            {
               tempSelect = SELL_BATCH_MAX;
            }
            GlobalData.$tempSellItem = {};
            GlobalData.$tempSell = [];
            setList();
            addList();
            mList.scrollToPosition(0,Math.max(int(firstSelect / 5) * 124 - 62,0),0);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_avatar_sell_data");
            this.reportRarityDiagnostic(mRarityDiagEvent,GlobalData.$tempSell.length);
            this.reportRarityDiagnostic(GlobalData.$tempSell.length == 0 ? "sell-quick-select" : "sell-clear",GlobalData.$tempSell.length);
         }
         else if(_loc5_.name == BTN_NAME_SELL)
         {
            if(GlobalData.$userData.attrs.avatar_culture != null)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10182));
               return;
            }
            if(GlobalData.$tempSell.length > 0)
            {
               _loc2_ = GlobalFunction.formateBetterItemsError();
               if(_loc2_.s)
               {
                  _loc3_ = {
                     "ok":popSell,
                     "okA":["Pop"],
                     "no":GlobalFunction.functionNull
                  };
                  _loc4_ = int(_loc2_.s);
                  if(_loc2_.name)
                  {
                     _loc3_.aid = _loc2_.aid;
                     GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90020),GlobalTextStyle.COLOR_W_Y_Y_G),_loc3_);
                  }
                  else
                  {
                     GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90055,_loc4_),GlobalTextStyle.COLOR_W_Y_Y_G),_loc3_);
                  }
               }
               else
               {
                  popSell();
               }
            }
            else
            {
               GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(90009));
            }
         }
      }
      
      private function popSell() : void
      {
         var _loc1_:Object = {
            "ok":service_sell,
            "no":GlobalFunction.functionNull
         };
         GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(20069),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90008,mGold_all,GlobalData.$tempSell.length),GlobalTextStyle.COLOR_W_Y_Y_G),_loc1_);
      }
      
      private function service_sell() : void
      {
         var _loc1_:Array = GlobalData.$tempSell.concat();
         var _loc2_:uint = mSellViewEpoch;
         if(_loc1_.length == 0 || _loc1_.length > SELL_BATCH_MAX)
         {
            return;
         }
         SendServiceAMFFun.send_user_sell_avatar(function(param1:Object):void
         {
            re_sell_avatar(param1,_loc1_,_loc2_);
         },{"aids":_loc1_.concat()});
      }
      
      private function re_expedition(param1:Object) : void
      {
         var _loc2_:* = param1.data;
      }
      
      private function re_sell_avatar(param1:Object, param2:Array, param3:uint) : void
      {
         if(GlobalFunction.isMalformedProfileReceipt(param1))
         {
            return;
         }
         if(GlobalFunction.isLegacyProfileReceipt(param1))
         {
            RpcStaticCall.$remoting.reportDiagnostic("PROFILE_RECEIPT_LEGACY|method=user.sell_avatars");
         }
         var _loc2_:* = 0;
         if(param3 == mSellViewEpoch && this.stage != null)
         {
            SoundManager.getOnlyExample().playSound("E_8003",0.4);
            SoundManager.getOnlyExample().playSound("E_9021",0.4);
         }
         refreshGlobalGold();
         if(param3 == mSellViewEpoch && this.stage != null)
         {
            GlobalFunction.clearSellItems();
            this.update();
         }
      }
      
      override public function addList() : void
      {
         var _loc9_:Object = null;
         var _loc1_:Avatar = null;
         var _loc8_:int = 0;
         if(this.mTabBar)
         {
            $tabBarSelectedIndex = this.mTabBar.selectedIndex;
         }
         this.setListHeight(-100);
         this.layoutRarityFilters(mList.y);
         mList.height -= mRarityRowHeight;
         mList.y += mRarityRowHeight;
         var _loc2_:Array = [];
         var _loc3_:Object = GlobalData.$userData.avatars;
         var _loc7_:Boolean = false;
         var _loc5_:Boolean = false;
         var _loc6_:String = "";
         for(var _loc10_:Object in _loc3_)
         {
            _loc6_ = _loc10_.toString();
            _loc7_ = isHeroAssigned(_loc6_);
            _loc5_ = GlobalFunction.checkLock(_loc6_) || PanelCenterDNTeam.checkIsInDn(_loc6_) != null;
            if(GlobalFunction.checkSearchTypeByType(_loc6_,this.mTabBar.selectedIndex) || GlobalData.$tempSell.indexOf(_loc6_) > -1 && GlobalFunction.checkSearchTypeByType(_loc6_,this.mTabBar.selectedIndex))
            {
               _loc1_ = new Avatar(_loc6_);
               _loc9_ = Tools.clone(_loc3_[_loc10_]);
               _loc9_["id"] = _loc6_;
               _loc9_["sort_1"] = _loc1_.getSellValue();
               _loc9_["lock"] = _loc7_ || _loc5_ ? 1 : 0;
               _loc9_["material_protected"] = _loc7_ ? 1 : 0;
               _loc9_["auto_blocked"] = isAutoBlocked(_loc9_) ? 1 : 0;
               _loc2_.push(_loc9_);
               _loc1_.clear();
               _loc1_ = null;
            }
         }
         _loc2_.sortOn(["material_protected","lock","sort_1"],[0x10,0x10,0x10 | 2]);
         var _loc4_:int = 0;
         firstSelect = 0;
         _loc8_ = 0;
         while(_loc8_ < _loc2_.length)
         {
            if(_loc4_ >= tempSelect)
            {
               break;
            }
            _loc9_ = _loc2_[_loc8_];
            if(!matchesRarity(_loc9_["id"]) || _loc9_["auto_blocked"])
            {
               _loc8_++;
               continue;
            }
            if(!_loc9_["lock"])
            {
               GlobalData.$tempSell.push(_loc9_["id"]);
               if(_loc4_ == 0)
               {
                  firstSelect = _loc8_;
               }
               _loc4_++;
            }
            _loc8_++;
         }
         if(tempSelect > 0 && _loc4_ == 0)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90115),false,"A_3002_1");
         }
         tempSelect = 0;
         this.setListTimer(mList,_loc2_,ItemAvatarSell,false);
      }
      
      public function formatTxtInfo() : void
      {
         GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
         this.mGold_all = GlobalFunction.getSellAvatarGold();
         var _loc4_:Number = this.mGold_all;
         var _loc3_:Number = GlobalData.$tempSell.length;
         var _loc2_:Number = GlobalData.$userData_avatarNum;
         var _loc1_:Number = Number(GlobalData.$userData.attrs.avatar_len);
         this.setTxtInfo(GlobalLanguageStr.getLanguageStr(20073,_loc3_),GlobalLanguageStr.getLanguageStr(20074,_loc3_,SELL_BATCH_MAX),GlobalLanguageStr.getLanguageStr(98133,_loc4_,_loc2_,_loc1_));
         if(GlobalData.$tempSell.length > 0)
         {
            this.mBtn_sell.enabled = true;
            this.mBtn_clear.text = GlobalLanguageStr.getLanguageStr(20228);
         }
         else
         {
            this.mBtn_sell.enabled = false;
            this.mBtn_clear.text = GlobalLanguageStr.getLanguageStr(90990);
         }
      }
      
      public function setTxtInfo(param1:*, param2:*, param3:*) : void
      {
         if(this.mTxt_info == null)
         {
            this.mTxt_info = GlobalTextStyle.getHtmlTextRenderer();
            this.mTxt_info.touchable = false;
            this.mTxt_info.width = GlobalData.$mStageWidth * 0.5;
            this.mTxt_info.textFormat = GlobalTextStyle.style_format();
            this.mTxt_info.textFormat.leading = 0;
            this.mTxt_info.isHTML = true;
            this.mTxt_info.x = this.mBtn_clear.x + this.mBtn_clear.width + 20;
            this.mTxt_info.y = this.mBtn_clear.y - 15;
            this.addChild(this.mTxt_info);
         }
         this.setTxtInfoCo(param1,param2,param3);
      }
      
      public function setTxtInfoCo(param1:*, param2:*, param3:*) : void
      {
         var _loc4_:Array = [Tools.formatLineX(param1,GlobalTextStyle.COLOR_W_Y_Y_Y,1000,20),Tools.formatLineX(param2,GlobalTextStyle.COLOR_W_Y_Y_Y,1000,20),Tools.formatLineX(param3,GlobalTextStyle.COLOR_W_Y_Y_Y,1000,20)];
         this.mTxt_info.text = Tools.formatHtmlTextBr(_loc4_,"left");
      }
      
      public function onUPDATE_AVATAR_DATA(param1:Event) : void
      {
         this.formatTxtInfo();
      }
   }
}

