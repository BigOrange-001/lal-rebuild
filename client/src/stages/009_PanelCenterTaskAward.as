package com.meng52.game.ui.screen
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.ui.element.ItemTaskAward;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.data.ListCollection;
   import feathers.layout.VerticalLayout;
   import starling.events.Event;
   
   public class PanelCenterTaskAward extends PanelCenterPVE
   {
      
      private static var mTaskData_need_hero_score:Number = 0;
      
      public function PanelCenterTaskAward()
      {
         super();
         this.removeEventListener("addedToStage",initializeHandler);
         this.addEventListener("removedFromStage",this.onREMOVED_FROM_STAGE);
         GlobalData.$mEventDispatcher.addEventListener("update_shop_coin",onUPDATE_SHOP_COIN);
      }
      
      public static function checkTaskComplete() : Number
      {
         var _loc9_:Object = null;
         var _loc3_:Object = null;
         var _loc23_:Object = null;
         var _loc18_:Object = GlobalData.$mConfig.task;
         var _loc1_:Array = GlobalData.$mConfig.everyday_gift as Array;
         var _loc22_:Array = GlobalData.$userData.records.everyday_gift as Array;
         var _loc7_:String = "";
         var _loc12_:Array = [];
         var _loc25_:Array = [];
         var _loc4_:int = int(GlobalData.$userData.lv);
         var _loc16_:int = 0;
         var _loc15_:int = int(_loc1_.length);
         var _loc24_:Number = 0;
         _loc16_ = 0;
         while(_loc16_ < _loc15_)
         {
            if(_loc22_.indexOf(_loc16_) < 0)
            {
               _loc24_ += 1;
            }
            _loc16_++;
         }
         var _loc21_:Object = GlobalData.$userData.task;
         var _loc10_:int = 0;
         var _loc6_:int = 0;
         var _loc20_:Array = null;
         for(var _loc19_:Object in _loc18_)
         {
            if(_loc19_.toString() != "time_pay")
            {
               _loc7_ = _loc19_.toString();
               _loc9_ = _loc18_[_loc19_];
               _loc10_ = int(_loc9_.content ? (_loc9_.content as Array).length : 0);
               if(_loc4_ >= int(_loc9_.need_lv))
               {
                  if(_loc21_[_loc19_] != null)
                  {
                     _loc6_ = int(_loc21_[_loc19_]);
                     if(_loc6_ < _loc10_)
                     {
                        _loc23_ = {};
                        _loc20_ = _loc9_.content as Array;
                        _loc23_["id"] = _loc7_;
                        _loc23_["gift"] = _loc20_[_loc6_].gift;
                        _loc23_["need"] = _loc20_[_loc6_].need;
                        _loc23_["info"] = _loc9_.info;
                        _loc3_ = checkTask(_loc7_,_loc23_,_loc9_);
                        if(_loc3_)
                        {
                           if(_loc3_.ok)
                           {
                              _loc24_ += 1;
                           }
                        }
                     }
                  }
               }
            }
         }
         var _loc2_:int = GlobalFunction.getVipLv();
         var _loc13_:Array = GlobalData.$mConfig_vip[_loc2_].gift as Array;
         var _loc8_:Array = GlobalData.$userData.records.vip_gift as Array;
         if(_loc13_)
         {
            _loc24_ += Math.abs(_loc13_.length - _loc8_.length);
         }
         var _loc17_:int = int(GlobalData.$userData.attrs.pay_gift);
         var _loc14_:Array = GlobalData.$mConfig_simple.pay_gift as Array;
         var _loc11_:Boolean = _loc17_ >= int(_loc14_[0]);
         var _loc5_:int = Math.floor(_loc17_ / int(_loc14_[0]));
         if(_loc11_)
         {
            _loc24_ += _loc5_;
         }
         return _loc24_;
      }
      
      public static function checkTask(param1:String, param2:Object, param3:Object) : Object
      {
         var _loc17_:Array = null;
         var _loc43_:Array = null;
         var _loc8_:Array = null;
         var _loc26_:Array = null;
         var _loc24_:Object = null;
         var _loc29_:Object = null;
         var _loc14_:Number = NaN;
         var _loc31_:Number = NaN;
         var _loc10_:Number = NaN;
         var _loc25_:Object = null;
         var _loc19_:String = "login_total";
         var _loc18_:String = "login_catena";
         var _loc4_:String = "wager_coin";
         var _loc35_:String = "wager_score";
         var _loc27_:String = "pass_map_main";
         var _loc28_:String = "pass_map_main_hard";
         var _loc16_:String = "pass_map_ploy";
         var _loc40_:String = "friend_num";
         var _loc41_:String = "pay";
         var _loc34_:String = "level_up";
         var _loc22_:String = "time_pay";
         var _loc13_:String = "pvp_count";
         var _loc20_:String = "pvp_sucess_count";
         var _loc38_:String = "pvp_rank";
         var _loc39_:String = "coin_wash_count";
         var _loc36_:String = "time_pay_loop";
         var _loc5_:String = "have_avatar";
         var _loc21_:String = "hero_score";
         var _loc37_:String = "time_login";
         var _loc33_:String = "server_pvp_task";
         var _loc42_:String = "time_consumecoin";
         var _loc11_:String = "ok";
         var _loc7_:String = "curr";
         var _loc23_:String = "need";
         var _loc12_:Object = null;
         var _loc9_:Boolean = false;
         var _loc32_:Date = null;
         var _loc6_:Date = null;
         var _loc15_:Date = null;
         var _loc30_:Number = SendAndSelect.$systemTimer_nowSecond * 1000;
         if(param1 == _loc19_)
         {
            _loc12_ = {
               "curr":GlobalData.$userData.attrs.login_total,
               "need":param2["need"],
               "ok":false
            };
            _loc12_[_loc11_] = _loc12_[_loc7_] >= _loc12_[_loc23_];
         }
         else if(param1 == _loc18_)
         {
            _loc12_ = {
               "curr":GlobalData.$userData.catena,
               "need":param2["need"]
            };
            _loc12_[_loc11_] = _loc12_[_loc7_] >= _loc12_[_loc23_];
         }
         else if(param1 == _loc4_)
         {
            _loc12_ = {
               "curr":GlobalData.$userData.attrs.wager_coin,
               "need":param2["need"]
            };
            _loc12_[_loc11_] = _loc12_[_loc7_] >= _loc12_[_loc23_];
         }
         else if(param1 == _loc35_)
         {
            _loc12_ = {
               "curr":GlobalData.$userData.attrs.wager_score,
               "need":param2["need"]
            };
            _loc12_[_loc11_] = _loc12_[_loc7_] >= _loc12_[_loc23_];
         }
         else if(param1 == _loc27_)
         {
            _loc12_ = {
               "curr":1,
               "need":1
            };
            _loc43_ = String(GlobalData.$userData.cid).split("_");
            _loc17_ = String(param2["need"]).split("_");
            _loc12_[_loc11_] = int(_loc43_[1]) > int(_loc17_[1]);
            _loc12_[_loc7_] = _loc12_[_loc11_] ? 1 : 0;
         }
         else if(param1 == _loc28_)
         {
            _loc12_ = {
               "curr":1,
               "need":1
            };
            _loc8_ = String(GlobalData.$userData.hid).split("_");
            _loc17_ = String(param2["need"]).split("_");
            _loc12_[_loc11_] = int(_loc8_[1]) > int(_loc17_[1]);
            _loc12_[_loc7_] = _loc12_[_loc11_] ? 1 : 0;
         }
         else if(param1 == _loc16_)
         {
            _loc12_ = {
               "curr":1,
               "need":1
            };
            _loc26_ = GlobalData.$userData.ploy_cids[param2["need"]];
            _loc24_ = GlobalData.$mConfig_battle_ploy[param2["need"]];
            _loc9_ = false;
            if(_loc26_ != null)
            {
               if(_loc26_.length >= _loc24_.combat)
               {
                  _loc9_ = true;
               }
            }
            _loc12_[_loc11_] = _loc9_;
            _loc12_[_loc7_] = _loc9_ ? 1 : 0;
         }
         else if(param1 == _loc41_)
         {
            _loc12_ = {
               "curr":GlobalData.$userData.attrs.pay_money,
               "need":param2["need"]
            };
            _loc12_[_loc11_] = _loc12_[_loc7_] >= _loc12_[_loc23_];
         }
         else if(param1 == _loc34_)
         {
            _loc12_ = {
               "curr":GlobalData.$userData.lv,
               "need":param2["need"]
            };
            _loc12_[_loc11_] = _loc12_[_loc7_] >= _loc12_[_loc23_];
         }
         else if(param1 == _loc40_)
         {
            _loc12_ = {
               "curr":(GlobalData.$tempFriend ? GlobalData.$tempFriend.length : 0),
               "need":param2["need"]
            };
            _loc12_[_loc11_] = _loc12_[_loc7_] >= _loc12_[_loc23_];
         }
         else if(param1 == _loc13_)
         {
            _loc12_ = {
               "curr":GlobalData.$userData.attrs.pvp_count,
               "need":param2["need"],
               "ok":false
            };
            _loc12_[_loc11_] = _loc12_[_loc7_] >= _loc12_[_loc23_];
         }
         else if(param1 == _loc20_)
         {
            _loc12_ = {
               "curr":GlobalData.$userData.attrs.pvp_sucess_count,
               "need":param2["need"],
               "ok":false
            };
            _loc12_[_loc11_] = _loc12_[_loc7_] >= _loc12_[_loc23_];
         }
         else if(param1 == _loc38_)
         {
            _loc12_ = {
               "curr":(GlobalData.$userData.attrs.pvp_rank == null ? 99999 : GlobalData.$userData.attrs.pvp_rank),
               "need":param2["need"],
               "ok":false
            };
            _loc12_[_loc11_] = _loc12_[_loc7_] <= _loc12_[_loc23_];
         }
         else if(param1 == _loc22_)
         {
            _loc29_ = GlobalData.$userData.attrs.time_pay.money;
            _loc12_ = {
               "curr":Math.round(GlobalData.$userData.attrs.time_pay.money * 10).toFixed(5),
               "need":Math.round(param2["need"] * 10).toFixed(5)
            };
            _loc15_ = GlobalData.$userData.attrs.time_pay["time_key"];
            _loc9_ = false;
            if(_loc15_ != null)
            {
               _loc32_ = param3.begin_time as Date;
               _loc6_ = param3.end_time as Date;
               _loc14_ = _loc15_.time;
               _loc31_ = _loc32_.time;
               _loc10_ = _loc6_.time;
            }
            if(_loc14_ == _loc31_)
            {
               if(_loc30_ >= _loc31_ && _loc30_ < _loc10_ && int(_loc12_[_loc7_]) >= int(_loc12_[_loc23_]))
               {
                  _loc9_ = true;
               }
            }
            _loc12_[_loc11_] = _loc9_;
         }
         else if(param1 == _loc36_)
         {
            _loc12_ = {
               "curr":Math.round(GlobalData.$userData.attrs.time_pay_loop.money * 10).toFixed(5),
               "need":Math.round(param2["need"] * 10).toFixed(5)
            };
            _loc12_[_loc11_] = int(_loc12_[_loc7_]) >= int(_loc12_[_loc23_]);
         }
         else if(param1 == _loc39_)
         {
            _loc12_ = {
               "curr":(GlobalData.$userData.records.coin_wash_count ? GlobalData.$userData.records.coin_wash_count : 0),
               "need":param2["need"]
            };
            _loc12_[_loc11_] = _loc12_[_loc7_] >= _loc12_[_loc23_];
         }
         else if(param1 == _loc5_)
         {
            _loc25_ = check_HAVE_AVATAR(param2["need"]);
            _loc12_ = {
               "curr":_loc25_.curr,
               "need":_loc25_.need
            };
            _loc12_["task_more_base"] = _loc25_.cfg;
            _loc31_ = (param3.begin_time as Date).time * 0.001;
            _loc10_ = (param3.end_time as Date).time * 0.001;
            if(SendAndSelect.$systemTimer_nowSecond <= _loc31_ || SendAndSelect.$systemTimer_nowSecond > _loc10_)
            {
               _loc12_[_loc11_] = false;
            }
            else
            {
               _loc12_[_loc11_] = int(_loc12_[_loc7_]) >= int(_loc12_[_loc23_]);
            }
         }
         else if(param1 == _loc21_)
         {
            _loc12_ = {
               "curr":mTaskData_need_hero_score,
               "need":param2["need"]
            };
            _loc12_[_loc11_] = int(_loc12_[_loc7_]) >= int(_loc12_[_loc23_]);
         }
         else if(param1 == _loc37_)
         {
            _loc12_ = {
               "curr":GlobalData.$userData.attrs.time_login.days,
               "need":param2["need"]
            };
            _loc12_[_loc11_] = int(_loc12_[_loc7_]) >= int(_loc12_[_loc23_]);
         }
         else if(param1 == _loc33_)
         {
            _loc12_ = {
               "curr":GlobalData.$userData.records.server_pvp_num,
               "need":param2["need"]
            };
            _loc12_[_loc11_] = int(_loc12_[_loc7_]) >= int(_loc12_[_loc23_]);
         }
         else if(param1 == _loc42_)
         {
            _loc12_ = {
               "curr":GlobalData.$userData.attrs.time_consumecoin.num,
               "need":param2["need"]
            };
            _loc12_[_loc11_] = int(_loc12_[_loc7_]) >= int(_loc12_[_loc23_]);
         }
         return _loc12_;
      }
      
      public static function check_HAVE_AVATAR(param1:Object) : Object
      {
         var _loc3_:Object = null;
         var _loc9_:Object = null;
         var _loc8_:int = 0;
         var _loc5_:Array = [];
         var _loc6_:String = "";
         for(_loc9_ in param1)
         {
            _loc6_ = _loc9_.toString();
            _loc3_ = {};
            _loc3_["aid"] = _loc6_;
            _loc3_["need"] = param1[_loc9_];
            _loc3_["curr"] = 0;
            _loc5_.push(_loc3_);
            _loc8_ += param1[_loc9_];
         }
         var _loc7_:int = 0;
         var _loc4_:int = int(_loc5_.length);
         var _loc2_:int = 0;
         for(_loc9_ in GlobalData.$userData.avatars)
         {
            _loc6_ = _loc9_.toString();
            _loc7_ = 0;
            while(_loc7_ < _loc4_)
            {
               _loc3_ = _loc5_[_loc7_];
               if(_loc6_.indexOf(_loc3_["aid"]) > -1)
               {
                  var _loc11_:String = "curr";
                  var _loc10_:Number = _loc3_[_loc11_] + 1;
                  _loc3_[_loc11_] = _loc10_;
                  _loc2_ += 1;
               }
               _loc7_++;
            }
         }
         return {
            "need":_loc8_,
            "curr":_loc2_,
            "cfg":_loc5_
         };
      }
      
      public static function checkExtremeAward(param1:*, param2:String = "") : Number
      {
         var _loc3_:int = 0;
         if(param1 == null)
         {
            _loc3_ = 0;
         }
         else
         {
            if(param1.hasOwnProperty("audition") && (param2 == "" || param2 == "audition"))
            {
               for(var _loc4_:String in param1["audition"])
               {
                  if(param1["audition"][_loc4_] == 0)
                  {
                     _loc3_ += 1;
                  }
               }
            }
            if(param1.hasOwnProperty("battle") && (param2 == "" || param2 == "battle"))
            {
               for(_loc4_ in param1["battle"])
               {
                  if(param1["battle"][_loc4_] == 0)
                  {
                     _loc3_ += 1;
                  }
               }
            }
            if(param1.hasOwnProperty("gamble") && (param2 == "" || param2 == "fans"))
            {
               for(_loc4_ in param1["gamble"])
               {
                  if(param1["gamble"][_loc4_] == 0)
                  {
                     _loc3_ += 1;
                  }
               }
            }
            if(param1.hasOwnProperty("fans") && (param2 == "" || param2 == "fans"))
            {
               for(_loc4_ in param1["fans"])
               {
                  if(param1["fans"][_loc4_] == 0)
                  {
                     _loc3_ += 1;
                  }
               }
            }
         }
         return _loc3_;
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         this.removeEventListener("removedFromStage",this.onREMOVED_FROM_STAGE);
         GlobalData.$mEventDispatcher.removeEventListener("update_shop_coin",onUPDATE_SHOP_COIN);
         this.delList();
         this.clear();
      }
      
      private function onUPDATE_SHOP_COIN(param1:Event) : void
      {
         update();
      }
      
      private function sendService() : void
      {
         SendServiceAMFFun.send_user_task_info(reService);
      }
      
      private function reService(param1:Object) : void
      {
         if(this.stage == null) return;
         mTaskData_need_hero_score = param1.data.hero_score;
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
         GlobalData.$userData.attrs.time_consumecoin = param1.data.time_consumecoin;
         }
         this.setList();
         this.addList();
         GuideMaster.getOnlyExample().nextGuideStep();
         GlobalFunction.$rndMCShow = false;
         if(GlobalData.$currentGuide)
         {
            mList.verticalScrollPolicy = "off";
         }
      }
      
      override public function update() : void
      {
         sendService();
      }
      
      override public function setList() : void
      {
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
            settings = {
               "paging":0,
               "gap":5,
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
            _layout.gap = settings.gap;
            _layout.hasVariableItemDimensions = true;
            this.mList = new List();
            this.mList.isSelectable = false;
            this.mList.width = GlobalData.$mStageWidth - 20;
            this.mList.layout = _layout;
            this.mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
            this.mList.x = int((GlobalData.$mStageWidth - this.mList.width) * 0.5);
            this.mList.snapScrollPositionsToPixels = true;
            this.addChild(this.mList);
            settings = null;
            _layout = null;
            this.mList.dataProvider = new ListCollection();
         }
      }
      
      override public function addList() : void
      {
         var _loc10_:Object = null;
         var _loc28_:Object = null;
         var _loc22_:String = null;
         var _loc5_:Object = null;
         var _loc21_:int = 0;
         var _loc14_:Boolean = false;
         var _loc24_:Object = GlobalData.$mConfig.task;
         var _loc1_:Array = GlobalData.$mConfig.everyday_gift as Array;
         var _loc8_:String = "";
         var _loc15_:Array = [];
         var _loc29_:Array = [];
         var _loc6_:int = int(GlobalData.$userData.lv);
         var _loc20_:int = 0;
         var _loc18_:int = 0;
         var _loc27_:Array = GlobalData.$userData.records.everyday_gift as Array;
         var _loc25_:Array = null;
         var _loc2_:int = GlobalFunction.getVipLv();
         var _loc16_:Array = GlobalData.$mConfig_vip[_loc2_].gift as Array;
         var _loc9_:Array = GlobalData.$userData.records.vip_gift as Array;
         if(_loc16_ != null)
         {
            _loc22_ = GlobalFunction.checkIOSvip() ? "(" + GlobalLanguageStr.getLanguageStr(20186) + _loc2_ + "  " + ")" + GlobalLanguageStr.getLanguageStr(70002) : GlobalLanguageStr.getLanguageStr(70002);
            _loc18_ = int(_loc16_.length);
            _loc20_ = 0;
            while(_loc20_ < _loc18_)
            {
               if(_loc9_.indexOf(_loc20_) < 0)
               {
                  _loc25_ = Tools.getObjectKeyValue(_loc16_[_loc20_]);
                  _loc28_ = {};
                  _loc28_[_loc25_[0]] = _loc25_[1];
                  _loc10_ = {};
                  _loc10_["id"] = "_$vip$_" + _loc20_;
                  _loc10_["gift"] = _loc28_;
                  _loc10_["need"] = 0;
                  _loc10_["info"] = _loc22_;
                  _loc10_["taskResult"] = 1;
                  _loc15_.push(_loc10_);
               }
               _loc20_++;
            }
         }
         _loc18_ = int(_loc1_.length);
         _loc22_ = GlobalLanguageStr.getLanguageStr(20155);
         var _loc12_:Object = GlobalData.$mConfig_simple.everyday_gifts.start_lv;
         _loc20_ = 0;
         for(; _loc20_ < _loc18_; _loc20_++)
         {
            if(_loc27_.indexOf(_loc20_) < 0)
            {
               _loc25_ = Tools.getObjectKeyValue(_loc1_[_loc20_]);
               _loc28_ = {};
               _loc28_[_loc25_[0]] = _loc25_[1];
               _loc10_ = {};
               _loc10_["id"] = "_$everyday$_" + _loc20_;
               _loc10_["gift"] = _loc28_;
               _loc10_["need"] = 0;
               _loc10_["info"] = _loc22_;
               _loc10_["taskResult"] = 1;
               if(_loc25_[0] == "avatar_soul" || _loc25_[0] == "equip_soul" || _loc25_[0] == "culture_book")
               {
                  if(GlobalData.$userData.lv < _loc12_[_loc25_[0]])
                  {
                     continue;
                  }
               }
               _loc15_.push(_loc10_);
            }
         }
         var _loc26_:Object = GlobalData.$userData.task;
         var _loc11_:int = 0;
         var _loc7_:int = 0;
         var _loc3_:Object = null;
         var _loc19_:Number = 0;
         var _loc4_:Number = 0;
         var _loc13_:Boolean = false;
         for(var _loc23_:Object in _loc24_)
         {
            _loc8_ = _loc23_.toString();
            _loc10_ = _loc24_[_loc23_];
            _loc11_ = int(_loc10_.content ? (_loc10_.content as Array).length : 0);
            if(_loc6_ >= int(_loc10_.need_lv) || _loc8_ == "pay")
            {
               if(_loc26_[_loc23_] != null || _loc8_ == "time_pay_loop")
               {
                  if(_loc8_ == "time_pay_loop")
                  {
                     _loc7_ = 0;
                  }
                  else
                  {
                     _loc7_ = int(_loc26_[_loc23_]);
                  }
                  if(_loc7_ < _loc11_)
                  {
                     if(_loc8_ == "time_pay")
                     {
                        _loc19_ = (_loc10_.begin_time as Date).time * 0.001;
                        _loc4_ = (_loc10_.end_time as Date).time * 0.001;
                     }
                     else
                     {
                        if(_loc8_ == "time_pay_loop")
                        {
                           _loc19_ = (_loc10_.begin_time as Date).time * 0.001;
                           _loc4_ = (_loc10_.end_time as Date).time * 0.001;
                           if(SendAndSelect.$systemTimer_nowSecond < _loc19_ || SendAndSelect.$systemTimer_nowSecond >= _loc4_)
                           {
                              continue;
                           }
                        }
                        else if(_loc8_ == "have_avatar")
                        {
                           _loc19_ = (_loc10_.begin_time as Date).time * 0.001;
                           _loc4_ = (_loc10_.end_time as Date).time * 0.001;
                           if(SendAndSelect.$systemTimer_nowSecond < _loc19_ || SendAndSelect.$systemTimer_nowSecond >= _loc4_)
                           {
                              continue;
                           }
                        }
                        else if(_loc8_ == "time_login")
                        {
                           _loc19_ = (_loc10_.begin_time as Date).time * 0.001;
                           _loc4_ = (_loc10_.end_time as Date).time * 0.001;
                           if(SendAndSelect.$systemTimer_nowSecond < _loc19_ || SendAndSelect.$systemTimer_nowSecond >= _loc4_)
                           {
                              continue;
                           }
                        }
                        else if(_loc8_ == "time_consumecoin")
                        {
                           _loc19_ = (_loc10_.begin_time as Date).time * 0.001;
                           _loc4_ = (_loc10_.end_time as Date).time * 0.001;
                           if(SendAndSelect.$systemTimer_nowSecond < _loc19_ || SendAndSelect.$systemTimer_nowSecond >= _loc4_)
                           {
                              continue;
                           }
                        }
                        _loc28_ = {};
                        _loc25_ = _loc10_.content as Array;
                        _loc28_["id"] = _loc8_;
                        _loc28_["gift"] = _loc25_[_loc7_].gift;
                        _loc28_["need"] = _loc25_[_loc7_].need;
                        _loc28_["taskcode"] = _loc7_;
                        _loc28_["info"] = GlobalLanguageStr.getLanguageStr(_loc10_.info);
                        _loc28_["index"] = _loc10_.index;
                        _loc28_["data_base"] = _loc10_;
                        _loc28_["lvMax"] = int(_loc10_.need_lv);
                        if(GlobalData.$currentGuide)
                        {
                           if(_loc8_ == "login_total")
                           {
                              _loc28_["index"] = -2;
                           }
                           else if(_loc8_ == "login_catena")
                           {
                              _loc28_["index"] = -1;
                           }
                        }
                        _loc5_ = checkTask(_loc8_,_loc28_,_loc10_);
                        if(_loc5_ != null)
                        {
                           if(_loc5_.ok)
                           {
                              _loc13_ = true;
                           }
                           if(_loc8_ == "have_avatar")
                           {
                              _loc28_["task_more_base"] = _loc5_["task_more_base"];
                           }
                           _loc28_["taskResult"] = _loc5_.ok ? 1 : 0;
                           if(_loc8_ != "pay")
                           {
                              _loc29_.push(_loc28_);
                           }
                           else
                           {
                              _loc3_ = _loc28_;
                           }
                        }
                     }
                  }
               }
            }
         }
         GlobalData.$mGameClassObject.mLayoutUICenter.mPanelCenterMain.awardIcon();
         if(_loc29_.length > 0)
         {
            _loc29_.sortOn(["taskResult","index"],[0x10 | 2,16]);
         }
         var _loc17_:Array = GlobalData.$mConfig_simple.pay_gift as Array;
         _loc28_ = null;
         if(_loc17_ != null && _loc17_.length > 1)
         {
            _loc21_ = int(GlobalData.$userData.attrs.pay_gift_count);
            _loc14_ = _loc21_ <= 0;
            _loc22_ = _loc14_ ? GlobalLanguageStr.getLanguageStr(20252) : GlobalLanguageStr.getLanguageStr(20428);
            _loc28_ = {};
            _loc28_["id"] = "_$paygift$_";
            _loc28_["gift"] = _loc17_[1];
            _loc28_["need"] = _loc14_ ? _loc17_[0] : _loc17_[2];
            _loc28_["info"] = _loc22_;
            _loc28_["taskResult"] = 0;
         }
         if(GlobalData.$currentGuide)
         {
            _loc15_ = _loc29_.slice(0,2).concat(_loc15_).concat(_loc29_.slice(2,-1));
         }
         else
         {
            _loc15_ = _loc15_.concat(_loc29_);
            if(_loc3_ != null)
            {
               _loc15_.unshift(_loc3_);
            }
            if(_loc28_ != null)
            {
               _loc15_.unshift(_loc28_);
            }
         }
         if(_loc15_.length > 0)
         {
            mList.y = 0;
            mList.height = GlobalData.$center_height_curr - 121 - 145;
            this.setListTimer(mList,_loc15_,ItemTaskAward,false);
         }
         _loc3_ = null;
         _loc26_ = null;
         _loc15_ = null;
         _loc29_ = null;
         _loc27_ = null;
         _loc25_ = null;
         _loc28_ = null;
         _loc10_ = null;
         _loc24_ = null;
         _loc1_ = null;
      }
   }
}

