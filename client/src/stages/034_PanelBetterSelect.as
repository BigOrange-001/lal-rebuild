package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.ui.element.ItemBetterSelect;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelAvatarSell;
   import com.meng52.game.ui.screen.PanelCenterDNTeam;
   import com.meng52.utils.Tools;
   import flash.geom.Rectangle;
   import starling.events.Event;
   
   public class PanelBetterSelect extends PanelAvatarSell
   {
      
      public static var $tabBarSelectedIndex:int = 0;
      public static var $betterRarityFilter:Object = {"2":true,"3":true,"4":true,"5":true,"6":true};

      public static function matchesBetterRarity(param1:String) : Boolean
      {
         var _parts:Array = param1.split("|")[0].split("_");
         var _star:int = _parts.length > 2 ? int(_parts[2]) : 0;
         var _key:String = _star <= 2 ? "2" : (_star >= 6 ? "6" : _star.toString());
         return $betterRarityFilter[_key] === true;
      }

      public static function autoMaterialPriority(param1:String) : int
      {
         var kind:int = autoFeedMaterialKind(param1);
         return kind == 1 || kind == 2 ? 0 : (isAutoMinion(param1) ? 1 : 2);
      }

      public static function isAutoMinion(param1:String) : Boolean
      {
         if(param1 == null || GlobalData.$mConfig_avatar == null)
         {
            return false;
         }
         var _base:String = param1.split("|")[0];
         var _parts:Array = _base.split("_");
         if(_parts.length != 3 || _parts[0] != "A" || GlobalData.$mConfig_avatar[_base] == null)
         {
            return false;
         }
         var _type:int = int(String(_parts[1]).charAt(0));
         // Match the game's own minion/monster tab, including every family.
         return _type == 2 || _type == 3 || _type == 4;
      }
      
      private static function autoFeedMaterialKind(param1:String) : int
      {
         var _base:String = param1.split("|")[0];
         if(_base == "A_6992_4" || _base == "A_6992_5" || _base == "A_6992_6")
         {
            return 1;
         }
         if(_base == "A_6996_3" || _base == "A_6996_4" || _base == "A_6996_5" ||
            _base == "A_6997_3" || _base == "A_6997_4" || _base == "A_6997_5" ||
            _base == "A_6998_3" || _base == "A_6998_4" || _base == "A_6998_5")
         {
            return 2;
         }
         return isAutoMinion(param1) ? 3 : 0;
      }

      private static function autoFeedMaterialSafe(param1:Avatar, param2:Object, param3:String) : Boolean
      {
         return param3 != GlobalData.$tempAvatarBetter.id &&
            !PanelAvatarSell.isHeroAssigned(param3) &&
            !PanelAvatarSell.isAutoBlocked(param2) &&
            !GlobalFunction.checkLock(param3) &&
            param1.morph == 0 && param1.phase == 0 && param1.slv <= 1 &&
            param1.loveExp <= 0 && param1.exp <= 0 && param1.getPithNum() <= 0;
      }

      public static function checkBetterFood(respectRarity:Boolean = false) : void
      {
         var _target:Avatar = new Avatar(GlobalData.$tempAvatarBetter.id);
         var _canSkill:Boolean = _target.skill0 != null && _target.slv < int(GlobalData.$mConfig_simple.slv_config[0]);
         var _remainingExp:Number = Math.max(0,_target.getAllExp(_target.getLvMax()) - (_target.getAllExp() + _target.exp));
         var _biscuits:Array = [];
         var _books:Array = [];
         var _monsters:Array = [];
         var _owned:Object = GlobalData.$userData.avatars;
         var _id:String;
         var _kind:int;
         var _material:Avatar;
         var _row:Object;
         var _offer:int;
         var _candidate:Object;
         for(_id in _owned)
         {
            _kind = autoFeedMaterialKind(_id);
            if((_kind == 1 && !_canSkill) || (_kind >= 2 && _remainingExp <= 0) || _kind == 0 || (respectRarity && !matchesBetterRarity(_id)))
            {
               continue;
            }
            _row = _owned[_id];
            _material = new Avatar(_id);
            if(autoFeedMaterialSafe(_material,_row,_id))
            {
               _offer = _material.getOfferExp();
               if(_offer > 0)
               {
                  _candidate = {"id":_id,"data":_row,"offer":_offer};
                  (_kind == 1 ? _biscuits : (_kind == 2 ? _books : _monsters)).push(_candidate);
               }
            }
            _material.clear();
         }
         _biscuits.sortOn("offer",0x10);
         var _selected:int = 0;
         var _totalExp:int = 0;
         var _unaffordable:Boolean = false;
         var _budget:Number = Number(GlobalData.$userData.gold);
         var _i:int;
         for(_i = 0; _i < _biscuits.length && _selected < 5; _i++)
         {
            _candidate = _biscuits[_i];
            if(Math.ceil((_totalExp + int(_candidate.offer)) / 10) > _budget)
            {
               _unaffordable = true;
               continue;
            }
            _totalExp += int(_candidate.offer);
            _row = _candidate.data;
            _row["id"] = _candidate.id;
            _row["give"] = {"exp":_candidate.offer,"gold":Math.ceil(int(_candidate.offer) / 10)};
            GlobalFunction.changeAvatarBetterArray(_candidate.id,false,null,_row);
            _selected++;
         }
         // Books are useful only while the target still has level XP to gain.
         // Prefer the smallest book that finishes the gap, otherwise the
         // largest available book so the five slots make useful progress.
         // Dedicated materials always precede ordinary minions/monsters.
         for each(var _pool:Array in [_books,_monsters])
         {
         while(_selected < 5 && _totalExp < _remainingExp && _pool.length > 0)
         {
            var _best:int = -1;
            var _need:Number = _remainingExp - _totalExp;
            for(_i = 0; _i < _pool.length; _i++)
            {
               _candidate = _pool[_i];
               if(Math.ceil((_totalExp + int(_candidate.offer)) / 10) > _budget)
               {
                  _unaffordable = true;
                  continue;
               }
               if(_best < 0 ||
                  (int(_candidate.offer) >= _need && (int(_pool[_best].offer) < _need || int(_candidate.offer) < int(_pool[_best].offer))) ||
                  (int(_candidate.offer) < _need && int(_pool[_best].offer) < _need && int(_candidate.offer) > int(_pool[_best].offer)))
               {
                  _best = _i;
               }
            }
            if(_best < 0)
            {
               break;
            }
            _candidate = _pool.splice(_best,1)[0];
            _totalExp += int(_candidate.offer);
            _row = _candidate.data;
            _row["id"] = _candidate.id;
            _row["give"] = {"exp":_candidate.offer,"gold":Math.ceil(int(_candidate.offer) / 10)};
            GlobalFunction.changeAvatarBetterArray(_candidate.id,false,null,_row);
            _selected++;
         }
         }
         if(_selected == 0)
         {
            if(_remainingExp <= 0 && !_canSkill)
            {
               var _res:String = _target.resId.indexOf(".") > -1 ? _target.resId.slice(0,_target.resId.length - 1) : _target.resId;
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90198),false,_res);
            }
            else if(_unaffordable)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10023),false,"A_6999_3");
            }
            else
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90115),false,_canSkill ? "A_6992_4" : "A_6996_5");
            }
         }
         _target.clear();
      }

      public var mNum_select:int = 0;
      
      public var mNum_selectObj:Object = 0;
      
      public function PanelBetterSelect()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(20083),GlobalData.$center_height_curr - 121);
         mImg9x9_bg = GlobalFunction.createScale9Image("UI_bg_9slice_4_0000",600,110,new Rectangle(110,60,30,15));
         mImg9x9_bg.x = int((GlobalData.$mStageWidth - mImg9x9_bg.width) * 0.5);
         mImg9x9_bg.y = mImg9_baseBg.y + mImg9_baseBg.height - mImg9x9_bg.height - 20;
         addChild(mImg9x9_bg);
         this.mBtn_clear = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90990),125,45,"UI_btn_enterGame_0_0000");
         this.mBtn_sell = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20021),125,45,"UI_btn_enterGame_0_0000");
         this.mBtn_clear.x = mImg9x9_bg.x + 20;
         this.mBtn_sell.x = mImg9x9_bg.x + mImg9x9_bg.width - this.mBtn_sell.width - 25;
         this.addChild(this.mBtn_clear);
         this.addChild(this.mBtn_sell);
         this.mBtn_clear.name = BTN_NAME_CLEAR;
         this.mBtn_sell.name = BTN_NAME_SELL;
         this.mBtn_clear.addEventListener("triggered",this.onTRIGGERED_btns);
         this.mBtn_sell.addEventListener("triggered",this.onTRIGGERED_btns);
         this.mBtn_sell.y = this.mBtn_clear.y = mImg9x9_bg.y + 25;
         GlobalData.$mEventDispatcher.addEventListener("update_avatar_better_data",this.onUPDATE_AVATAR_DATA);
         var _loc2_:Array = [{"label":GlobalLanguageStr.getLanguageStr(20236)},{"label":GlobalLanguageStr.getLanguageStr(20165)},{"label":GlobalLanguageStr.getLanguageStr(20255)}];
         if(MainConfig.$isHasBuilding)
         {
            _loc2_.push({"label":GlobalLanguageStr.getLanguageStr(20256)});
         }
         _loc2_.push({"label":GlobalLanguageStr.getLanguageStr(20257)});
         this.setSmallTabBar(_loc2_,tabBar_changeHandler,tabBar_CREATION_COMPLETE);
         mTabBar.x = 28;
         mTabBar.y = 90;
         this.mTabBar.selectedIndex = $tabBarSelectedIndex;
         $betterRarityFilter = createDefaultRarityFilter();
         this.createRarityFilters((GlobalData.$mStageWidth - 5 * 56 + 10) * 0.5,mTabBar.y + 59,$betterRarityFilter);
         this.addEventListener("close_panel_self",onCLOSE_PANEL_SELF);
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
      
      override public function tabBar_CREATION_COMPLETE(param1:*) : void
      {
         tabBar_changeHandler(null);
      }
      
      override public function onTRIGGERED_closePanel(param1:Event) : void
      {
         gotoStartBetter();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalData.$mEventDispatcher.removeEventListener("update_avatar_better_data",this.onUPDATE_AVATAR_DATA);
         clearPriv(param1);
      }
      
      override public function onUPDATE_AVATAR_DATA(param1:Event) : void
      {
         this.mNum_select = GlobalData.$tempAvatarBetterArr.length;
         this.formatTxtInfo();
      }
      
      override public function onBTN_NAME_BACK() : void
      {
         gotoStartBetter();
      }
      
      override public function onTRIGGERED_btns(param1:Event) : void
      {
         var _loc2_:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         GlobalData.$tempAvatarChoose = [];
         if(_loc2_.name == BTN_NAME_CLEAR)
         {
            var _wasSelected:Boolean = GlobalData.$tempAvatarBetterArr.length > 0;
            mRarityDiagEvent = _wasSelected ? "better-clear" : "better-quick-select";
            tempSelect = 0;
            GlobalFunction.clearAvatarBetterItems();
            if(!_wasSelected)
            {
               PanelBetterSelect.checkBetterFood(true);
            }
            setList();
            addList();
            mList.scrollToPosition(0,Math.max(int(firstSelect / 5) * 124 - 62,0),0);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_avatar_better_data");
            this.reportRarityDiagnostic(mRarityDiagEvent,GlobalData.$tempAvatarBetterArr.length);
            this.reportRarityDiagnostic(mRarityDiagEvent,GlobalData.$tempAvatarBetterArr.length);
         }
         else if(_loc2_.name == BTN_NAME_SELL)
         {
            gotoStartBetter();
         }
      }
      
      private function gotoStartBetter() : void
      {
         var weightedTarget:Avatar = new Avatar(GlobalData.$tempAvatarBetter.id);
         if(weightedTarget.isWeightedCultivation())
         {
            confirmWeightedFeed(weightedTarget);
            return;
         }
         var meanNum:int;
         var _arr:Array;
         var _arr2:Array;
         var showAvatar:Avatar;
         var i:int;
         var _avatar:Avatar;
         var resId:String;
         var resId2:String;
         var id1:String;
         var id2:String;
         var avatar:Avatar;
         var _star:int;
         var mObject:Object;
         var mObjec:Object;
         var mainAvatar:Avatar;
         var mainAvatar2:Avatar;
         var obj:Object;
         var maxP:int;
         var currentMax:int;
         var mhpP:Number;
         var mapP:Number;
         var mde_phP:Number;
         var mde_maP:Number;
         var map:int;
         var mhp:int;
         var mph:int;
         var mma:int;
         var mP:int;
         var j:int;
         var h:int;
         var _fun:Object;
         var _num:int;
         var _str:String;
         var _str2:String;
         var _str3:String;
         var gotoFun:* = function():void
         {
            onCLOSE_PANEL_SELF();
            GlobalData.$mEventDispatcher.dispatchEventWith("update_avatar_better_start");
            GlobalData.$tempAvatarChoose = [];
         };
         var clearAvatar:* = function():void
         {
            GlobalData.$tempAvatarChoose = [];
         };
         var _error:Object = GlobalFunction.formateBetterItemsError(GlobalData.$tempAvatarBetterArr);
         var allPith:int = 0;
         var hpP:int = 0;
         var apP:int = 0;
         var de_phP:int = 0;
         var de_maP:int = 0;
         var _hpP:int = 0;
         var _apP:int = 0;
         var _de_phP:int = 0;
         var _de_maP:int = 0;
         var avatarArr:Array = GlobalData.$tempAvatarBetterArr;
         var _hp:int = 0;
         var _ap:int = 0;
         var _de_ph:int = 0;
         var _de_ma:int = 0;
         var mObj:Object = GlobalData.$mConfig_simple.culture;
         var mMaxPith:int = 0;
         var pithAdd:int = int(GlobalData.$mConfig_simple.culture.culture_pith);
         if(avatarArr.length > 0)
         {
            mainAvatar = weightedTarget;
            i = 0;
            while(i < avatarArr.length)
            {
               _avatar = new Avatar(avatarArr[i]);
               allPith += _avatar.getPithNum() * pithAdd;
               resId = avatarArr[i].split("|")[0];
               resId2 = GlobalData.$tempAvatarBetter.id.split("|")[0];
               id1 = resId.split("_")[1];
               id2 = resId2.split("_")[1];
               if(id1 == id2)
               {
                  avatar = new Avatar(avatarArr[i]);
                  _star = avatar.getStar();
                  mObject = GlobalData.$userData.avatars[avatarArr[i]];
                  mObjec = GlobalData.$userData.avatars[GlobalData.$tempAvatarBetter.id];
                  if(_star >= 2)
                  {
                     mMaxPith += mObj.pith_limit_add[_star];
                     if(mObjec.pith_max)
                     {
                        if(mMaxPith > GlobalData.$mConfig_simple.culture.max_pith - GlobalData.$mConfig_simple.culture.max_pith_base - mObjec.pith_max)
                        {
                           mMaxPith = GlobalData.$mConfig_simple.culture.max_pith - GlobalData.$mConfig_simple.culture.max_pith_base - mObjec.pith_max;
                        }
                     }
                     else if(mMaxPith > GlobalData.$mConfig_simple.culture.max_pith - GlobalData.$mConfig_simple.culture.max_pith_base)
                     {
                        mMaxPith = GlobalData.$mConfig_simple.culture.max_pith - GlobalData.$mConfig_simple.culture.max_pith_base;
                     }
                  }
               }
               if(showAvatar == null)
               {
                  showAvatar = _avatar;
               }
               else if(_avatar.getStar() > showAvatar.getStar())
               {
                  showAvatar = _avatar;
               }
               hpP += _avatar.isWeightedCultivation() ? legacyCulturePointEquivalent(mainAvatar,"hp",_avatar.hpP) : _avatar.hpP;
               apP += _avatar.isWeightedCultivation() ? legacyCulturePointEquivalent(mainAvatar,"ap",_avatar.apP) : _avatar.apP;
               de_phP += _avatar.isWeightedCultivation() ? legacyCulturePointEquivalent(mainAvatar,"de_ph",_avatar.dePhP) : _avatar.dePhP;
               de_maP += _avatar.isWeightedCultivation() ? legacyCulturePointEquivalent(mainAvatar,"de_ma",_avatar.deMaP) : _avatar.deMaP;
               i = i + 1;
            }
            _arr = [hpP,apP,de_phP,de_maP];
            _arr2 = [hpP,apP,de_phP,de_maP];
            mainAvatar2 = mainAvatar;
            obj = GlobalData.$userData.avatars[GlobalData.$tempAvatarBetter.id];
            maxP = 0;
            currentMax = 0;
            if(obj.pith_max)
            {
               maxP = GlobalData.$mConfig_simple.culture.max_pith - GlobalData.$mConfig_simple.culture.max_pith_base - obj.pith_max;
               currentMax = GlobalData.$mConfig_simple.culture.max_pith_base + obj.pith_max;
            }
            else
            {
               maxP = GlobalData.$mConfig_simple.culture.max_pith - GlobalData.$mConfig_simple.culture.max_pith_base;
               currentMax = int(GlobalData.$mConfig_simple.culture.max_pith_base);
            }
            if(currentMax >= GlobalData.$mConfig_simple.culture.max_pith)
            {
               currentMax = int(GlobalData.$mConfig_simple.culture.max_pith);
            }
            if(avatarArr.length > 0)
            {
               if(mainAvatar.getPithNum() <= currentMax)
               {
                  mhpP = mainAvatar2.hpP;
                  mapP = mainAvatar2.apP;
                  mde_phP = mainAvatar2.dePhP;
                  mde_maP = mainAvatar2.deMaP;
                  mP = currentMax - mainAvatar.getPithNum() + (mMaxPith == 0 ? 0 : mMaxPith);
                  meanNum = Math.ceil(mP / 4);
                  j = 0;
                  while(j < 4)
                  {
                     if(mP > 0)
                     {
                        if(_arr[j] > meanNum)
                        {
                           var _loc2_:* = j;
                           var _loc3_:* = _arr[_loc2_] - meanNum;
                           _arr[_loc2_] = _loc3_;
                           mP -= meanNum;
                        }
                        else
                        {
                           mP -= _arr[j];
                           _arr[j] = 0;
                        }
                     }
                     j = j + 1;
                  }
                  h = 0;
                  while(h < 4)
                  {
                     if(mP > 0)
                     {
                        if(_arr[h] > mP)
                        {
                           _loc3_ = h;
                           _loc2_ = _arr[_loc3_] - mP;
                           _arr[_loc3_] = _loc2_;
                           mP -= mP;
                           break;
                        }
                        mP -= _arr[h];
                        _arr[h] = 0;
                     }
                     h = h + 1;
                  }
                  mhp = _arr2[0] - _arr[0];
                  map = _arr2[1] - _arr[1];
                  mph = _arr2[2] - _arr[2];
                  mma = _arr2[3] - _arr[3];
                  _hp += mhp;
                  _ap += map;
                  _de_ph += mph;
                  _de_ma += mma;
               }
            }
         }
         if(_error.s)
         {
            _fun = {
               "ok":gotoFun,
               "no":clearAvatar
            };
            _num = int(_error.s);
            _str = "";
            _str2 = "";
            _str3 = "";
            if(mhp > 0 || map > 0 || mph > 0 || mma > 0)
            {
               _str = GlobalLanguageStr.getLanguageStr(90661) + (mhp > 0 ? GlobalLanguageStr.getLanguageStr(90662,mainAvatar.getCultivationStatGain("hp",mhp)) : "") + (map > 0 ? GlobalLanguageStr.getLanguageStr(90663,mainAvatar.getCultivationStatGain("ap",map)) : "") + (mph > 0 ? GlobalLanguageStr.getLanguageStr(90664,mainAvatar.getCultivationStatGain("de_ph",mph)) : "") + (mma > 0 ? GlobalLanguageStr.getLanguageStr(90665,mainAvatar.getCultivationStatGain("de_ma",mma)) : "");
            }
            else
            {
               _str = (mhp > 0 ? GlobalLanguageStr.getLanguageStr(90662,mainAvatar.getCultivationStatGain("hp",mhp)) : "") + (map > 0 ? GlobalLanguageStr.getLanguageStr(90663,mainAvatar.getCultivationStatGain("ap",map)) : "") + (mph > 0 ? GlobalLanguageStr.getLanguageStr(90664,mainAvatar.getCultivationStatGain("de_ph",mph)) : "") + (mma > 0 ? GlobalLanguageStr.getLanguageStr(90665,mainAvatar.getCultivationStatGain("de_ma",mma)) : "");
            }
            if(mMaxPith > 0)
            {
               _str2 = GlobalLanguageStr.getLanguageStr(90676,mMaxPith * pithAdd);
            }
            if(_arr[0] > 0 || _arr[1] > 0 || _arr[2] > 0 || _arr[3] > 0)
            {
               _str3 = "{" + GlobalLanguageStr.getLanguageStr(90666) + "}";
            }
            if(_error.name)
            {
               _fun.aid = GlobalData.$mConfig_simple.show_id[0];
               GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90076,_num,_error.name) + _str + _str2 + _str3,[16777215,10526880,16764006,13777209]),_fun);
            }
            else
            {
               _fun.aid = GlobalData.$mConfig_simple.show_id[0];
               GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90016,_num) + _str + _str2 + _str3,[16777215,10526880,16764006,13777209]),_fun);
            }
         }
         else
         {
            gotoFun();
         }
      }

      private function legacyCulturePointEquivalent(target:Avatar,stat:String,actual:int) : int
      {
         if(actual <= 0) return 0;
         var slope:Number = stat == "hp" ? target.avatarData.hp1 : stat == "ap" ? target.avatarData.ap1 : stat == "de_ph" ? target.avatarData.d11 : target.avatarData.d21;
         var rate:Number = Number(GlobalData.$mConfig_simple.culture.pith_growth_rate);
         if(isNaN(rate) || rate <= 0) rate = 0.1;
         return slope > 0 ? Math.max(0,int(actual / (slope * rate))) : 0;
      }

      private function confirmWeightedFeed(target:Avatar) : void
      {
         var selected:Array = GlobalData.$tempAvatarBetterArr;
         var weightConfig:Object = GlobalData.$mConfig_simple.culture.weighted.weights;
         var weights:Array = [int(weightConfig.hp),int(weightConfig.ap),int(weightConfig.de_ph),int(weightConfig.de_ma)];
         var requested:Array = [0,0,0,0];
         for each(var instanceId:String in selected)
         {
            var material:Avatar = new Avatar(instanceId);
            requested[0] += Math.max(0,material.getCultivationStatGain("hp",material.hpP));
            requested[1] += Math.max(0,material.getCultivationStatGain("ap",material.apP));
            requested[2] += Math.max(0,material.getCultivationStatGain("de_ph",material.dePhP));
            requested[3] += Math.max(0,material.getCultivationStatGain("de_ma",material.deMaP));
         }
         var room:int = Math.max(0,target.getCultivationCap() - target.getPithNum());
         var totalWeighted:int = 0;
         var i:int;
         for(i=0;i<4;i++) totalWeighted += int(requested[i]) * int(weights[i]);
         var gains:Array = [0,0,0,0];
         if(totalWeighted <= room)
         {
            gains = requested.concat();
         }
         else if(totalWeighted > 0)
         {
            var used:int = 0;
            for(i=0;i<4;i++)
            {
               gains[i] = Math.min(int(requested[i]),int(Number(requested[i]) * room / totalWeighted));
               used += int(gains[i]) * int(weights[i]);
            }
            for(i=0;i<4;i++)
            {
               var extra:int = Math.min(int(requested[i]) - int(gains[i]),int((room - used) / int(weights[i])));
               gains[i] = int(gains[i]) + extra;
               used += extra * int(weights[i]);
            }
         }
         var error:Object = GlobalFunction.formateBetterItemsError(selected);
         var finish:Function = function():void
         {
            onCLOSE_PANEL_SELF();
            GlobalData.$mEventDispatcher.dispatchEventWith("update_avatar_better_start");
            GlobalData.$tempAvatarChoose = [];
         };
         if(!error.s)
         {
            finish();
            return;
         }
         var cancel:Function = function():void { GlobalData.$tempAvatarChoose = []; };
         var message:String = "";
         if(int(gains[0]) > 0 || int(gains[1]) > 0 || int(gains[2]) > 0 || int(gains[3]) > 0) message = GlobalLanguageStr.getLanguageStr(90661);
         if(int(gains[0]) > 0) message += GlobalLanguageStr.getLanguageStr(90662,gains[0]);
         if(int(gains[1]) > 0) message += GlobalLanguageStr.getLanguageStr(90663,gains[1]);
         if(int(gains[2]) > 0) message += GlobalLanguageStr.getLanguageStr(90664,gains[2]);
         if(int(gains[3]) > 0) message += GlobalLanguageStr.getLanguageStr(90665,gains[3]);
         for(i=0;i<4;i++) if(int(gains[i]) < int(requested[i])) { message += "{" + GlobalLanguageStr.getLanguageStr(90666) + "}"; break; }
         var intro:String = error.name ? GlobalLanguageStr.getLanguageStr(90076,int(error.s),error.name) : GlobalLanguageStr.getLanguageStr(90016,int(error.s));
         var actions:Object = {"ok":finish,"no":cancel,"aid":GlobalData.$mConfig_simple.show_id[0]};
         GlobalFunction.popAlert("",Tools.formatLineX(intro + message,[16777215,10526880,16764006,13777209]),actions);
      }
      
      override public function formatTxtInfo() : void
      {
         var _loc7_:int = 0;
         var _loc4_:Avatar = null;
         GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
         var _loc5_:int = 0;
         var _loc6_:Array = GlobalData.$tempAvatarBetterArr;
         while(_loc7_ < _loc6_.length)
         {
            _loc4_ = new Avatar(_loc6_[_loc7_]);
            _loc5_ += _loc4_.getOfferExp();
            _loc7_++;
         }
         var _loc3_:Number = this.mNum_select;
         var _loc2_:Number = GlobalData.$userData_avatarNum;
         var _loc1_:Number = Number(GlobalData.$userData.attrs.avatar_len);
         this.setTxtInfo(GlobalLanguageStr.getLanguageStr(20086,_loc3_,5),GlobalLanguageStr.getLanguageStr(98127,_loc5_),GlobalLanguageStr.getLanguageStr(98128,_loc2_,_loc1_));
         if(_loc6_.length > 0)
         {
            this.mBtn_clear.text = GlobalLanguageStr.getLanguageStr(20228);
         }
         else
         {
            this.mBtn_clear.text = GlobalLanguageStr.getLanguageStr(90990);
         }
      }
      
      override public function setTxtInfoCo(param1:*, param2:*, param3:*) : void
      {
         var _loc4_:Array = [Tools.formatLineX(param2,GlobalTextStyle.COLOR_0x4B2C1B,1000,20),Tools.formatLineX(param1,GlobalTextStyle.COLOR_0x4B2C1B,1000,20),Tools.formatLineX(param3,GlobalTextStyle.COLOR_0x4B2C1B,1000,20)];
         this.mTxt_info.text = Tools.formatHtmlTextBr(_loc4_,"left");
      }
      
      override public function addList() : void
      {
         var _loc5_:String = null;
         var _loc14_:Object = null;
         var _loc1_:Avatar = null;
         var _candidateOffer:Number = 0;
         var _autoCandidates:Array = null;
         var _hasUnaffordableCandidate:Boolean = false;
         var _loc12_:int = 0;
         var _loc8_:int = 0;
         if(this.mTabBar)
         {
            $tabBarSelectedIndex = this.mTabBar.selectedIndex;
         }
         var _baseListY:Number = mImg9_baseBg.y + 150;
         var _filterY:Number = mTabBar.y + 59;
         var _listY:Number = Math.max(_baseListY,_filterY + 40);
         this.layoutRarityFilters(_filterY);
         mList.y = _listY;
         mList.height = Math.max(120,mImg9_baseBg.y + mImg9_baseBg.height - 280 - (_listY - _baseListY));
         this.mNum_select = 0;
         var _loc4_:Avatar = new Avatar(GlobalData.$tempAvatarBetter.id);
         if(_loc4_.slv >= GlobalData.$mConfig_simple.slv_config[0])
         {
            _loc5_ = "";
         }
         else
         {
            _loc5_ = _loc4_.skill0 ? _loc4_.skill0.skillSetData.id : "";
         }
         var _loc11_:Boolean = false;
         var _loc2_:Array = [];
         var _loc3_:Object = GlobalData.$userData.avatars;
         var _loc6_:String = "";
         var _loc15_:int = 0;
         for(var _loc9_:Object in _loc3_)
         {
            _loc11_ = false;
            _loc6_ = _loc9_.toString();
            _loc15_ = 0;
            if(GlobalData.$tempBetterElements[_loc6_] != null)
            {
               _loc15_ = -1;
               mNum_select += 1;
            }
            if(MainConfig.$isHasBuilding)
            {
               _loc12_ = this.mTabBar.selectedIndex;
            }
            else if(this.mTabBar.selectedIndex == 3)
            {
               _loc12_ = this.mTabBar.selectedIndex + 1;
            }
            else
            {
               _loc12_ = this.mTabBar.selectedIndex;
            }
            if(GlobalFunction.checkSearchTypeByType(_loc6_,_loc12_) || _loc15_ == -1 && GlobalFunction.checkSearchTypeByType(_loc6_,_loc12_))
            {
               _loc1_ = new Avatar(_loc6_);
               _loc14_ = _loc3_[_loc9_];
               _loc14_["id"] = _loc6_;
               _loc14_["status"] = _loc15_;
               _loc14_["canBetter"] = 0;
               _loc14_["sort_1"] = _loc1_.getSwallowValue(_loc4_);
               _loc14_["material_protected"] = PanelAvatarSell.isHeroAssigned(_loc6_) ? 1 : 0;
               _loc14_["auto_blocked"] = PanelAvatarSell.isAutoBlocked(_loc14_) ? 1 : 0;
               _loc14_["xp_material_priority"] = PanelBetterSelect.autoMaterialPriority(_loc6_);
               _loc14_["lock"] = PanelBetterSelect.isAutoSwallowProtected(_loc1_,_loc4_,_loc6_) || _loc14_["material_protected"] != 0;
               _loc2_.push(_loc14_);
               _loc1_.clear();
               _loc1_ = null;
            }
         }
         _loc2_.sortOn(["material_protected","sort_1"],[0x10,0x10 | 2]);
         _autoCandidates = _loc2_.concat();
         _autoCandidates.sortOn(["xp_material_priority","material_protected","sort_1"],[0x10,0x10,0x10 | 2]);
         var _loc13_:int = 0;
         var _loc10_:int = _loc4_.getAllExp(_loc4_.getLvMax()) - (_loc4_.getAllExp() + _loc4_.exp);
         var _loc7_:int = 0;
         firstSelect = 0;
         _loc8_ = 0;
         while(_loc8_ < _autoCandidates.length)
         {
            if(_loc13_ >= tempSelect)
            {
               break;
            }
            if(_loc10_ - _loc7_ <= 0)
            {
               break;
            }
            _loc14_ = _autoCandidates[_loc8_];
            if(!isAutoMinion(_loc14_["id"]) || !matchesBetterRarity(_loc14_["id"]) || _loc14_["auto_blocked"])
            {
               _loc8_++;
               continue;
            }
            if(!_loc14_["lock"])
            {
               _loc1_ = new Avatar(_loc14_["id"]);
               _candidateOffer = _loc1_.getOfferExp();
               if(_loc7_ + _candidateOffer > GlobalData.$userData.gold)
               {
                  _hasUnaffordableCandidate = true;
                  _loc8_++;
                  continue;
               }
               _loc7_ += _candidateOffer;
               GlobalData.$tempAvatarBetterArr.push(_loc14_["id"]);
               if(_loc13_ == 0)
               {
                  firstSelect = _loc2_.indexOf(_loc14_);
               }
               _loc13_++;
            }
            _loc8_++;
         }
         if(tempSelect > 0 && _loc13_ == 0)
         {
            if(_loc10_ <= 0)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90198),false,_loc4_.resId);
            }
            else if(_hasUnaffordableCandidate)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(10023),false,"A_6999_3");
            }
            else
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90115),false,"A_3001_1");
            }
         }
         tempSelect = 0;
         this.setListTimer(mList,_loc2_,ItemBetterSelect,false);
         this.bringRarityFiltersToFront();
      }

      override protected function getRaritySelectionCount() : int
      {
         return GlobalData.$tempAvatarBetterArr == null ? 0 : GlobalData.$tempAvatarBetterArr.length;
      }

      public static function isAutoSwallowProtected(param1:Avatar, param2:Avatar, param3:String) : Boolean
      {
         var _data:Object = param1.avatarData;
         var _offerExp:Number = Number(_data.offerExp || 0);
         var _offerGold:Number = Number(_data.offerGold || 0);
         if(param3 == GlobalData.$tempAvatarBetter.id || PanelAvatarSell.isHeroAssigned(param3) || GlobalFunction.checkLock(param3))
         {
            return true;
         }
         if(param2.lv >= param2.getLvMax() || param1.morph > 0)
         {
            return true;
         }
         if(_offerExp > 50000 || (_offerExp > 0 && _offerGold / _offerExp > 1.5))
         {
            return true;
         }
         // AvatarData.loveExp/skillExp are template defaults (love/skillup),
         // not player investments. Checking them here locks nearly every card.
         // Use Avatar instance fields serialized from the player's record.
         if(param1.loveExp > 0 || param1.slv > 1 || param1.phase > 0 || param1.getPithNum() > 0)
         {
            return true;
         }
         return false;
      }
   }
}

