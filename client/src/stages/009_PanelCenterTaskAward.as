package com.meng52.game.ui.screen
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.ui.element.ItemTaskAward;
   import com.meng52.net.SendAndSelect;
   import com.meng52.events.NetEvent;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import flash.utils.Timer;
   import starling.text.TextField;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.data.ListCollection;
   import feathers.layout.VerticalLayout;
   import starling.events.Event;
   import starling.core.Starling;
   import starling.animation.Tween;
   import starling.display.Quad;
   import starling.display.DisplayObject;
   import flash.geom.Rectangle;
   
   public class PanelCenterTaskAward extends PanelCenterPVE
   {
      
      private static var mTaskData_need_hero_score:Number = 0;
      private static var adventureReady:int = 0;
      private var adventureData:Object;
      private var adventureTab:int = 0;
      private var adventureRequest:int = 0;
      private var adventureClaiming:Boolean = false;
      private var adventureButtons:Array = [];
      private var adventureStatus:TextField;
      private var adventureTimer:Timer;
      private var adventureUnderline:Quad;
      
      public function PanelCenterTaskAward()
      {
         super();
         this.removeEventListener("addedToStage",initializeHandler);
         this.addEventListener("removedFromStage",this.onREMOVED_FROM_STAGE);
         GlobalData.$mEventDispatcher.addEventListener("update_shop_coin",onUPDATE_SHOP_COIN);
         SendAndSelect.$SendServiceAMFDispatcher.addEventListener("error_broadcast",onAdventureError);
         this.addEventListener("adventure_task_claim",onAdventureClaim);
      }
      
      public static function checkTaskComplete() : Number
      {
         return adventureReady;
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
         adventureRequest++;
         if(adventureUnderline) Starling.juggler.removeTweens(adventureUnderline);
         if(mList) Starling.juggler.removeTweens(mList);
         if(adventureTimer)
         {
            adventureTimer.stop();
            adventureTimer.removeEventListener("timer",onAdventureTimer);
         }
         GlobalData.$mEventDispatcher.removeEventListener("update_shop_coin",onUPDATE_SHOP_COIN);
         SendAndSelect.$SendServiceAMFDispatcher.removeEventListener("error_broadcast",onAdventureError);
         this.removeEventListener("adventure_task_claim",onAdventureClaim);
         this.delList();
         this.clear();
      }

      private function buildAdventureUI() : void
      {
         if(adventureStatus) return;
         var width:Number = GlobalData.$mStageWidth;
         var header:DisplayObject = GlobalFunction.createScale9Image("UI_bg_9slice_6_0000",width - 24,168,new Rectangle(20,20,10,10));
         header.x = 12;
         header.y = 4;
         header.touchable = false;
         addChild(header);
         var title:TextField = GlobalFunction.createTextField(width - 48,36,"奇遇任务","",28,16764006,true);
         title.x = 24;
         title.y = 10;
         title.hAlign = "center";
         title.touchable = false;
         addChild(title);
         var labels:Array = ["日常任务","累计充值","循环奖励"];
         var buttonWidth:Number = (width - 48) / 3;
         for(var i:int = 0; i < labels.length; i++)
         {
            var button:LOL_Scale9Button = new LOL_Scale9Button(labels[i],buttonWidth,44,"UI_btn_enterGame_0_0000");
            button.name = String(i);
            button.x = 20 + i * (buttonWidth + 4);
            button.y = 54;
            button.fontSize = 19;
            button.addEventListener("triggered",onAdventureTab);
            addChild(button);
            adventureButtons.push(button);
         }
         adventureUnderline = new Quad(buttonWidth - 12,3,16764006);
         adventureUnderline.x = 26;
         adventureUnderline.y = 100;
         adventureUnderline.touchable = false;
         addChild(adventureUnderline);
         adventureStatus = GlobalFunction.createTextField(width - 52,56,"正在加载任务…","",18,16777215);
         adventureStatus.x = 26;
         adventureStatus.y = 108;
         adventureStatus.autoScale = true;
         adventureStatus.hAlign = "left";
         adventureStatus.touchable = false;
         addChild(adventureStatus);
         setList();
         adventureTimer = new Timer(60000);
         adventureTimer.addEventListener("timer",onAdventureTimer);
         adventureTimer.start();
      }

      private function onAdventureTimer(param1:flash.events.Event) : void
      {
         if(stage != null && !adventureClaiming) update();
      }

      private function onAdventureTab(param1:Event) : void
      {
         var button:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         if(button == null || int(button.name) == adventureTab) return;
         adventureTab = int(button.name);
         if(mList) mList.verticalScrollPosition = 0;
         addList();
         if(adventureUnderline)
         {
            Starling.juggler.removeTweens(adventureUnderline);
            var indicator:Tween = new Tween(adventureUnderline,0.18,"easeOut");
            indicator.animate("x",button.x + 6);
            Starling.juggler.add(indicator);
         }
         if(mList)
         {
            Starling.juggler.removeTweens(mList);
            mList.alpha = 0.55;
            var content:Tween = new Tween(mList,0.18,"easeOut");
            content.fadeTo(1);
            Starling.juggler.add(content);
         }
      }

      private function onUPDATE_SHOP_COIN(param1:Event) : void
      {
         update();
      }

      override public function update() : void
      {
         if(stage == null || adventureClaiming) return;
         buildAdventureUI();
         var request:int = ++adventureRequest;
         SendAndSelect.sendAndSelectService("user.adventure_tasks_info",{},function(reply:Object):void
         {
            if(stage == null || request != adventureRequest || reply == null || int(reply.return_code) != 0) return;
            if(reply.state_sync && !GlobalData.isCurrentProfileSyncEnvelope(reply.state_sync)) return;
            if(adventureData != null && JSON.stringify(adventureData) == JSON.stringify(reply.data)) return;
            adventureData = reply.data;
            addList();
            GuideMaster.getOnlyExample().nextGuideStep();
         });
      }

      override public function setList() : void
      {
         if(mList) return;
         var layout:VerticalLayout = new VerticalLayout();
         layout.gap = 10;
         layout.hasVariableItemDimensions = true;
         layout.horizontalAlign = "center";
         mList = new List();
         mList.isSelectable = false;
         mList.layout = layout;
         mList.width = GlobalData.$mStageWidth;
         mList.height = Math.max(80,GlobalData.$center_height_curr - 121 - 184 - 12);
         mList.y = 184;
         mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
         mList.snapScrollPositionsToPixels = true;
         mList.dataProvider = new ListCollection();
         addChild(mList);
      }

      override public function addList() : void
      {
         if(!adventureData || !mList) return;
         var savedScroll:Number = mList.verticalScrollPosition;
         var rows:Array = [];
         var source:Array = adventureTab == 0 ? adventureData.daily as Array : adventureData.milestones as Array;
         if(adventureTab == 2) source = [adventureData.repeat];
         adventureReady = 0;
         var item:Object;
         var counts:Array = [0,0,0];
         for each(item in adventureData.daily) if(item.claimable) counts[0]++;
         for each(item in adventureData.milestones) if(item.claimable) counts[1]++;
         if(adventureData.repeat && adventureData.repeat.claimable) counts[2] = 1;
         adventureReady = counts[0] + counts[1] + counts[2];
         for each(item in source)
         {
            var row:Object = Tools.clone(item);
            row.adventure_task = true;
            row.kind = adventureTab == 0 ? "daily" : adventureTab == 1 ? "milestone" : "repeat";
            row.busy = adventureClaiming;
            row.progress_ratio = row.claimed || row.claimable ? 1 : 0;
            if(adventureTab == 0)
            {
               row.progress_text = "进度：" + Math.min(Number(row.count),Number(row.goal)) + "/" + row.goal;
               row.progress_ratio = Number(row.goal) > 0 ? Math.min(1,Number(row.count) / Number(row.goal)) : 0;
            }
            else if(adventureTab == 1)
            {
               row.title = "累计充值" + row.required_yuan + "元";
               row.progress_ratio = Number(row.required_yuan) > 0 ? Math.min(1,Number(adventureData.paid_yuan) / Number(row.required_yuan)) : 0;
               row.progress_text = "进度：" + Math.min(Number(adventureData.paid_yuan),Number(row.required_yuan)) + "/" + row.required_yuan + "元";
            }
            else
            {
               row.title = "每累计充值2000元，再领橙卡";
               row.progress_ratio = row.claimable ? 1 : Number(adventureData.paid_yuan) % 2000 / 2000;
               row.progress_text = "已领取" + row.claimed_count + "张，当前可领取" + row.available_count + "张";
            }
            rows.push(row);
         }
         var labels:Array = ["日常任务","累计充值","循环奖励"];
         for(var i:int = 0; i < adventureButtons.length; i++)
         {
            adventureButtons[i].alpha = i == adventureTab ? 1 : 0.72;
            adventureButtons[i].text = labels[i] + (counts[i] > 0 ? " · " + counts[i] : "");
         }
         adventureStatus.text = adventureTab == 0 ? "每日零点刷新；完成后分别领取奖励。" :
            "累计充值：" + adventureData.paid_yuan + "元\n累计与循环奖励可同时领取，首充翻倍不计入累计金额。";
         mList.dataProvider = new ListCollection();
         setListTimer(mList,rows,ItemTaskAward,false);
         mList.validate();
         mList.verticalScrollPosition = savedScroll;
         GlobalData.$mEventDispatcher.dispatchEventWith("update_activity_fun_task_num");
      }

      private function onAdventureClaim(param1:Event) : void
      {
         var row:Object = param1.data;
         if(stage == null || adventureClaiming || row == null || !row.claimable) return;
         adventureClaiming = true;
         var rewardText:String = row.reward_text;
         var request:int = ++adventureRequest;
         addList();
         SendAndSelect.sendAndSelectService("user.adventure_task_claim",{"kind":row.kind,"key":String(row.key)},function(reply:Object):void
         {
            if(stage == null || request != adventureRequest) return;
            adventureClaiming = false;
            if(reply == null || int(reply.return_code) != 0 || reply.data == null) { addList(); update(); return; }
            if(reply.state_sync && !GlobalData.isCurrentProfileSyncEnvelope(reply.state_sync)) { addList(); update(); return; }
            adventureData = reply.data.tasks;
            addList();
            var lines:Array = [];
            var award:Object = reply.data.award;
            if(award)
            {
               for(var aid:String in award.avatar)
                  lines.push((GlobalData.$mConfig_avatar[aid] ? GlobalData.$mConfig_avatar[aid].name : "橙色英雄") + "×" + award.avatar[aid]);
               for(var eid:String in award.equip)
                  lines.push((GlobalData.$mConfig_equip[eid] ? GlobalData.$mConfig_equip[eid].name : "橙色装备") + "×" + award.equip[eid]);
            }
            GlobalFunction.popAlert("奖励已领取",lines.length > 0 ? lines.join("\n") : rewardText);
         });
      }

      private function onAdventureError(param1:NetEvent) : void
      {
         var reply:Object = param1.data;
         if(!reply || (reply.method != "user.adventure_task_claim" && reply.method != "user.adventure_tasks_info")) return;
         adventureClaiming = false;
         if(stage != null)
         {
            if(reply.method == "user.adventure_task_claim") { addList(); update(); }
            else if(adventureStatus) adventureStatus.text = "任务加载失败，请重新进入奇遇。";
         }
      }
   }
}
