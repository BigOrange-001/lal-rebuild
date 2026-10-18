package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.ui.element.ItemHelpSetting;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelCenterHelp;
   import com.meng52.net.SendAndSelect;
   import feathers.display.Scale9Image;
   import feathers.controls.ScrollContainer;
   import flash.events.IOErrorEvent;
   import flash.events.SecurityErrorEvent;
   import flash.filesystem.File;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;
   import flash.geom.Rectangle;
   import flash.geom.Point;
   import flash.net.FileFilter;
   import flash.net.URLLoader;
   import flash.net.URLRequest;
   import flash.net.URLRequestHeader;
   import flash.utils.ByteArray;
   import flash.utils.setTimeout;
   import flash.utils.clearTimeout;
   import starling.display.Sprite;
   import starling.display.Quad;
   import starling.events.Event;
   import starling.text.TextField;

   public class PanelHelpSetting extends PanelCenterHelp
   {
      private static const TIER_KEYS:Array = ["small","wealthy","tycoon","protagonist"];

      private static const TIER_NAMES:Array = ["小氪（每日648元）","富哥（每日2000元）","大佬（每日5000元）","系统文主角（每日20000元）"];

      private var mSpending:Object;

      private var mTierButton:LOL_Scale9Button;

      private var mTierStatus:TextField;

      private var mTierMenu:Sprite;

      private var mDisposed:Boolean = false;

      private var mModView:Sprite;
      private var mModShield:Quad;
      private var mModScroll:ScrollContainer;
      private var mModStatus:TextField;
      private var mModInfo:Object;
      private var mModSelections:Array = [];
      private var mModPackage:int = -1;
      private var mModHero:int = -1;
      private var mModOwner:String = "";
      private var mModBusy:Boolean = false;
      private var mModDirty:Boolean = false;
      private var mModPlan:Object;
      private var mModRows:Array = [];
      private var mModY:Number = 0;
      private var mImportFile:File;
      private var mModRequestId:String = "";
      private var mModPreview:Boolean = false;
      private var mModSupport:Object;
      private var mBackupFile:File;
      private var mBackupOperation:Object;
      private var mBackupMode:String = "";
      private var mBackupValue:Object;
      private var mRestoreBackup:Object;
      private var mRestorePlan:Object;
      private var mRestoreRequestId:String = "";
      private var mModEpoch:uint = 0;
      private var mModOperation:Object;
      private var mModNeedsResync:Boolean = false;
      private var mImportOperation:Object;
      private var mPreviewBlocks:Array = [];
      private var mPreviewLineCount:int = 0;
      private var mPreviewPage:int = 0;
      private var mBuildingPreview:Boolean = false;
      private var mPreviewConfirm:Function;
      private var mPreviewConfirmLabel:String = "";

      public static function canChangeTier(param1:Object) : Boolean
      {
         return param1 != null && param1.can_change === true && param1.is_gm !== true;
      }

      public static function tierOptionIndex(param1:String) : int
      {
         for(var i:int = 0; i < TIER_KEYS.length; i++)
         {
            if(param1 == "spending_tier_" + i) return i;
         }
         return -1;
      }

      public static function changeTierParams(param1:int, param2:Object) : Object
      {
         if(!canChangeTier(param2) || param1 < 0 || param1 >= TIER_KEYS.length || TIER_KEYS[param1] == param2.tier)
         {
            return null;
         }
         return {"spending_tier":TIER_KEYS[param1]};
      }

      public static function canApplySpendingReply(param1:Object, param2:Boolean) : Boolean
      {
         return param2 && param1 != null && int(param1.return_code) == 0 &&
            param1.data != null && param1.data.tier != null &&
            (!param1.state_sync || GlobalData.isCurrentProfileSyncEnvelope(param1.state_sync));
      }

      public function PanelHelpSetting()
      {
         super();
      }

      override protected function initializeHandler(param1:Event) : void
      {
         mDisposed = false;
         this.removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(20119),550,595);
         this.setList();
         this.addList();
         this.createSpendingRow();
         var mods:LOL_Scale9Button = new LOL_Scale9Button("Mod 管理",320,56,"UI_btn_normalFun_0000");
         mods.x = mImg9_baseBg.x + (mImg9_baseBg.width - mods.width) * 0.5;
         mods.y = mImg9_baseBg.y + 430;
         mods.addEventListener("triggered",openModManager);
         addChild(mods);
         SendAndSelect.sendAndSelectService("user.spending_info",{},onSpendingInfo);
      }

      override public function onBTN_NAME_BACK() : void
      {
         if(mModView != null) { closeModManager(null); return; }
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_help");
      }

      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         mDisposed = true;
         clearModListeners();
         mTierMenu = null;
         mTierButton = null;
         mTierStatus = null;
         super.onREMOVED_FROM_STAGE(param1);
      }

      override public function addList() : void
      {
         var _loc1_:Array = [{
            "id":0,
            "status":1,
            "title":"背景音乐"
         },{
            "id":1,
            "status":1,
            "title":"游戏音效"
         }];
         mList.y = mImg9_baseBg.y + 100;
         mList.height = 205;
         this.setListTimer(mList,_loc1_,ItemHelpSetting,false);
      }

      private function createSpendingRow() : void
      {
         var rowX:Number = mImg9_baseBg.x + (mImg9_baseBg.width - 520) * 0.5;
         var rowY:Number = mImg9_baseBg.y + 310;
         var background:Scale9Image = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",520,100,new Rectangle(110,55,70,20));
         background.x = rowX;
         background.y = rowY;
         addChild(background);
         var title:TextField = GlobalTextStyle.getTextField("切换有钱程度",30,4926491,"left",270,35);
         title.x = rowX + 30;
         title.y = rowY + 13;
         addChild(title);
         mTierStatus = GlobalTextStyle.getTextField("读取中...",16,4926491,"left",310,35);
         mTierStatus.x = rowX + 30;
         mTierStatus.y = rowY + 54;
         addChild(mTierStatus);
         mTierButton = new LOL_Scale9Button("读取中...",174,50,"UI_btn_enterGame_0_0000");
         mTierButton.x = rowX + 330;
         mTierButton.y = rowY + 24;
         mTierButton.addEventListener("triggered",openTierMenu);
         addChild(mTierButton);
         mTierMenu = new Sprite();
         var menuBg:Scale9Image = GlobalFunction.createScale9Image("UI_bg_9slice_6_0000",500,285,new Rectangle(20,20,10,10));
         menuBg.x = rowX + 10;
         menuBg.y = mImg9_baseBg.y + 60;
         mTierMenu.addChild(menuBg);
         for(var i:int = 0; i < TIER_KEYS.length; i++)
         {
            var option:LOL_Scale9Button = new LOL_Scale9Button(String(TIER_NAMES[i]),450,53,"UI_btn_normalFun_0000");
            option.name = "spending_tier_" + i;
            option.x = rowX + 35;
            option.y = mImg9_baseBg.y + 68 + i * 66;
            option.addEventListener("triggered",chooseTier);
            mTierMenu.addChild(option);
         }
         mTierMenu.visible = false;
         addChild(mTierMenu);
      }

      private function onSpendingInfo(result:Object) : void
      {
         if(canApplySpendingReply(result,!mDisposed && this.stage != null))
         {
            updateSpending(result.data);
         }
      }

      private function updateSpending(data:Object) : void
      {
         mSpending = data;
         if(!mTierButton || !mTierStatus) return;
         if(data.is_gm)
         {
            mTierButton.text = "GM（固定）";
            mTierStatus.text = "GM：不限额，注册时固定";
         }
         else
         {
            mTierButton.text = String(data.label) + " ▼";
            mTierStatus.text = "今日 ¥" + data.spent_yuan + "/" + data.daily_limit_yuan + " 余 ¥" + data.remaining_yuan;
         }
      }

      private function openTierMenu(event:Event) : void
      {
         if(!mDisposed && canChangeTier(mSpending))
         {
            mTierMenu.visible = true;
         }
      }

      private function chooseTier(event:Event) : void
      {
         if(mDisposed || !mTierMenu) return;
         var index:int = tierOptionIndex(String(event.currentTarget.name));
         mTierMenu.visible = false;
         var params:Object = changeTierParams(index,mSpending);
         if(!mDisposed && params)
         {
            SendAndSelect.sendAndSelectService("user.set_spending_tier",params,onSpendingInfo);
         }
      }

      public static function modReplyMatches(reply:Object, owner:String, alive:Boolean) : Boolean
      {
         return alive && owner.length > 0 && owner == SendAndSelect.$uid && reply != null && int(reply.return_code) == 0 &&
            (!reply.state_sync || GlobalData.isCurrentProfileSyncEnvelope(reply.state_sync));
      }

      public static function modToggleValue(explicit:Object, inherited:Object, key:String) : Boolean
      {
         if(explicit != null && explicit.hasOwnProperty(key)) return explicit[key] === true;
         if(inherited != null && inherited.hasOwnProperty(key)) return inherited[key] === true;
         return true;
      }

      public static function modStatusName(status:String, enabled:Boolean) : String
      {
         if(status == "installed" || status == "") return enabled ? "当前启用" : "已安装未启用";
         if(status == "missing") return "对应内容缺失";
         if(status == "corrupt" || status == "invalid") return "文件损坏";
         if(status == "incompatible") return "版本不兼容";
         if(status == "conflict") return "补丁冲突";
         if(status == "missing_dependency") return "缺少依赖";
         if(status == "pending") return "待重新进入生效";
         return status;
      }

      private function modAlive() : Boolean
      {
         return !mDisposed && stage != null && mModView != null && mModOwner == SendAndSelect.$uid;
      }

      private function beginModOperation(method:String, mutation:Boolean = false) : Object
      {
         mModEpoch++;
         mModBusy = true;
         mModOperation = {"epoch":mModEpoch,"owner":mModOwner,"view":mModView,"method":method,"mutation":mutation};
         return mModOperation;
      }

      private function modOperationMatches(operation:Object) : Boolean
      {
         return operation != null && operation === mModOperation && operation.epoch == mModEpoch &&
            operation.owner == mModOwner && operation.owner == SendAndSelect.$uid && operation.view === mModView && modAlive();
      }

      private function completeModOperation(operation:Object) : Boolean
      {
         if(!modOperationMatches(operation)) return false;
         mModOperation = null;
         mModBusy = false;
         return true;
      }

      private function failModOperation(operation:Object, message:String, uncertain:Boolean = false) : void
      {
         if(!modOperationMatches(operation)) return;
         mModEpoch++;
         mModOperation = null;
         mModBusy = false;
         if(uncertain && operation.mutation === true)
         {
            // A transport failure is not proof that the server rolled back.
            // Keep gameplay gated until a fresh login loads the actual state.
            mModNeedsResync = true;
            mModBusy = true;
            GlobalData.$modReady = false;
            mModStatus.text = message + " 结果可能已保存；点击返回重新登录同步后继续。";
         }
         else mModStatus.text = message;
      }

      private function openModManager(event:Event) : void
      {
         if(mDisposed || mModView != null) return;
         mModOwner = SendAndSelect.$uid;
         mModNeedsResync = false;
         var origin:Point = globalToLocal(new Point(0,0));
         mModShield = new Quad(GlobalData.$mStageWidth,GlobalData.$mStageHeight,0);
         mModShield.x = origin.x;
         mModShield.y = origin.y;
         mModShield.alpha = 0.75;
         addChild(mModShield);
         mModView = new Sprite();
         var panelHeight:Number = Math.min(780,GlobalData.$mStageHeight - 40);
         var background:Quad = new Quad(590,panelHeight,0x9B733D);
         mModView.addChild(background);
         var surface:Quad = new Quad(586,panelHeight - 4,0x2B2018);
         surface.x = surface.y = 2;
         mModView.addChild(surface);
         mModView.x = origin.x + (GlobalData.$mStageWidth - 590) * 0.5;
         mModView.y = origin.y + (GlobalData.$mStageHeight - panelHeight) * 0.5;
         addChild(mModView);
         var title:TextField = GlobalTextStyle.getTextField("Mod 管理 · 只影响当前存档",25,16764006,"center",570,40);
         title.x = 10;
         title.y = 10;
         mModView.addChild(title);
         var save:TextField = GlobalTextStyle.getTextField("当前存档：" + String(GlobalData.$userData.name),18,16777215,"center",570,30);
         save.x = 10;
         save.y = 48;
         mModView.addChild(save);
         mModScroll = new ScrollContainer();
         mModScroll.x = 15;
         mModScroll.y = 85;
         mModScroll.width = 560;
         mModScroll.height = background.height - 230;
         mModView.addChild(mModScroll);
         mModStatus = GlobalTextStyle.getTextField("读取中…",17,16764006,"left",550,68);
         mModStatus.x = 20;
         mModStatus.y = background.height - 140;
         mModView.addChild(mModStatus);
         modFooter("返回",15,background.height - 65,closeModManager);
         modFooter("导入包",155,background.height - 65,importMod);
         modFooter("检查目录",295,background.height - 65,scanMods);
         modFooter("预览保存",435,background.height - 65,previewMods);
         SendAndSelect.$SendServiceAMFDispatcher.addEventListener("error_broadcast",onModError);
         SendAndSelect.$SendServiceAMFDispatcher.addEventListener("error_service",onModError);
         SendAndSelect.$SendServiceAMFDispatcher.addEventListener("net_timeout",onModError);
         requestModInfo(false);
      }

      private function modFooter(label:String, px:Number, py:Number, callback:Function) : void
      {
         var button:LOL_Scale9Button = new LOL_Scale9Button(label,130,48,"UI_btn_normalFun_0000");
         button.x = px;
         button.y = py;
         button.addEventListener("triggered",callback);
         mModView.addChild(button);
      }

      private function clearModListeners() : void
      {
         mModEpoch++;
         mModOperation = null;
         mModBusy = false;
         SendAndSelect.$SendServiceAMFDispatcher.removeEventListener("error_broadcast",onModError);
         SendAndSelect.$SendServiceAMFDispatcher.removeEventListener("error_service",onModError);
         SendAndSelect.$SendServiceAMFDispatcher.removeEventListener("net_timeout",onModError);
         clearImportPicker();
         clearBackupPicker();
      }

      private function closeModManager(event:Event) : void
      {
         if(mModNeedsResync) { GlobalFunction.quitGame(); return; }
         if(mModBusy) { mModStatus.text = "正在处理，请等待完成。"; return; }
         if(mModPreview) { mModPreview = false; mPreviewBlocks = []; mPreviewConfirm = null; renderModList(); return; }
         if(mModPackage >= 0) { mModPackage = -1; mModHero = -1; renderModList(); return; }
         if(mModDirty)
         {
            GlobalFunction.popAlert("放弃编辑？","尚未保存的 Mod 设置将被丢弃。",{"ok":discardMods,"no":GlobalFunction.functionNull});
            return;
         }
         discardMods();
      }

      private function discardMods() : void
      {
         clearModListeners();
         if(mModView != null) mModView.removeFromParent(true);
         if(mModShield != null) mModShield.removeFromParent(true);
         mModShield = null;
         mModView = null;
         mModInfo = null;
         mModScroll = null;
         mModPlan = null;
         mModSelections = [];
         mModRows = [];
         mModDirty = false;
         mModPackage = -1;
         mModHero = -1;
         mModPreview = false;
         mRestoreBackup = null;
         mRestorePlan = null;
         mRestoreRequestId = "";
         mPreviewBlocks = [];
         mPreviewConfirm = null;
         mBuildingPreview = false;
      }

      private function requestModInfo(rescan:Boolean) : void
      {
         var operation:Object = beginModOperation("user.mods_info");
         mModStatus.text = rescan ? "正在校验安装目录…" : "正在读取当前存档…";
         SendAndSelect.sendAndSelectService("user.mods_info",{"rescan":rescan},function(reply:Object):void
         {
            if(!modOperationMatches(operation) || !modReplyMatches(reply,String(operation.owner),modAlive())) return;
            completeModOperation(operation);
            mModInfo = reply.data;
            mModPackage = -1;
            mModHero = -1;
            mModPreview = false;
            mModSelections = mModInfo.selections is Array ? JSON.parse(JSON.stringify(mModInfo.selections)) : [];
            mModDirty = false;
            mModPlan = null;
            mModStatus.text = "当前配置修订 " + mModInfo.revision + "。设置只影响此存档；导入和卸载作用于全部存档。";
            renderModList();
         });
      }

      private function scanMods(event:Event) : void
      {
         if(mModBusy || !modAlive()) return;
         if(mModDirty) { mModStatus.text = "请先预览保存，或返回并放弃编辑后检查目录。"; return; }
         requestModInfo(true);
      }

      private function selectedMod(row:Object, create:Boolean = false) : Object
      {
         for each(var selection:Object in mModSelections)
         {
            if(String(selection.packageId) == String(row.packageId) && String(selection.version) == String(row.version) && String(selection.contentDigest) == String(row.contentDigest)) return selection;
         }
         if(!create) return null;
         var value:Object = {"packageId":row.packageId,"version":row.version,"contentDigest":row.contentDigest,"enabled":false,"channels":{},"patchScopes":{},"heroes":{}};
         for each(var previous:Object in mModSelections)
         {
            if(String(previous.packageId) == String(row.packageId))
            {
               value.channels = JSON.parse(JSON.stringify(previous.channels == null ? {} : previous.channels));
               value.patchScopes = JSON.parse(JSON.stringify(previous.patchScopes == null ? {} : previous.patchScopes));
               value.heroes = JSON.parse(JSON.stringify(previous.heroes == null ? {} : previous.heroes));
               break;
            }
         }
         mModSelections.push(value);
         return value;
      }

      private function beginModRows() : void
      {
         mModScroll.removeChildren(0,-1,true);
         mModRows = [];
         mModY = 0;
         mModScroll.verticalScrollPosition = 0;
      }

      private function modText(text:String, color:uint = 16777215, height:Number = 48) : void
      {
         if(mBuildingPreview)
         {
            mPreviewBlocks.push({"text":text,"color":color,"height":height,"wrapped":false,"count":1});
            mPreviewLineCount++;
            return;
         }
         var field:TextField = GlobalTextStyle.getTextField(text,18,color,"left",540,height);
         field.x = 5;
         field.y = mModY;
         mModScroll.addChild(field);
         mModY += height + 5;
      }

      private function modRow(label:String, data:Object, enabled:Boolean = true) : void
      {
         var button:LOL_Scale9Button = new LOL_Scale9Button(label,535,43,"UI_btn_normalFun_0000");
         button.name = "modrow_" + mModRows.length;
         button.x = 5;
         button.y = mModY;
         button.alpha = enabled ? 1 : 0.48;
         button.touchable = enabled && !mModBusy;
         button.addEventListener("triggered",onModRow);
         mModScroll.addChild(button);
         mModRows.push(data);
         mModY += 48;
      }

      private function renderModList() : void
      {
         if(!modAlive() || mModInfo == null) return;
         beginModRows();
         var packages:Array = mModInfo.packages is Array ? mModInfo.packages : [];
         if(mModPackage >= 0 && mModPackage < packages.length) { renderModPackage(packages[mModPackage]); return; }
         if(packages.length == 0) modText("尚未安装英雄包。可导入 .heropack，或将包放入 mods/inbox 后检查目录。",16764006,90);
         for(var i:int = 0; i < packages.length; i++)
         {
            var row:Object = packages[i];
            var selection:Object = selectedMod(row);
            var active:Boolean = selection != null && selection.enabled !== false;
            modText(String(row.name) + " · " + row.kind + " · " + row.version + "\n作者：" + row.author + " · " + modStatusName(row.status == null ? "installed" : String(row.status),active),16764006,58);
            if(row.reason) modText(String(row.reason),16736512,64);
            if(row.kind == "error" || row.packageId == null || String(row.packageId).length == 0) continue;
            modRow(active ? "当前存档：已启用此包（点击关闭）" : "当前存档：已关闭此包（点击启用）",{"action":"enable","package":i},row.status != "corrupt" && row.status != "incompatible" && row.status != "invalid");
            modRow("展开英雄、玩法及补丁范围",{"action":"details","package":i});
         }
         var errors:Array = mModInfo.errors is Array ? mModInfo.errors : [];
         for each(var error:Object in errors) modText(formatModIssue(error),16736512,85);
         modText("Mod 元数据备份只包含包清单、开关和身份映射；不含包文件，也不会回滚卡牌、装备或货币。",16764006,90);
         modRow("导出当前已保存的 Mod 设置",{"action":"backupExport"});
         modRow("从备份文件恢复（先预览）",{"action":"backupImport"});
         modRow("恢复上一次 Mod 设置（先预览）",{"action":"backupPrevious"});
         var missing:Array = mModInfo.missing is Array ? mModInfo.missing : [];
         for each(var item:Object in missing)
         {
            if(item is String) modText("内容缺失：" + String(item) + "\n英雄进度保留；请补回匹配版本。",16736512,80);
            else modText("内容缺失：" + String(item.name == null ? item.packageId : item.name) + "\n" + String(item.reason == null ? "英雄进度保留；请补回匹配版本。" : item.reason),16736512,80);
         }
      }

      private function renderModPackage(row:Object) : void
      {
         modText(String(row.name) + " / " + row.version + "\n包 ID：" + row.packageId,16764006,65);
         if(selectedMod(row) == null)
         {
            for each(var locked:Object in mModSelections)
            {
               if(String(locked.packageId) == String(row.packageId))
               {
                  modText("当前存档锁定的是 " + locked.version + "。切换此版本时会保留已有手动关闭项，并重新检查兼容性。",16764006,95);
                  modRow("选择此版本并保留玩法设置",{"action":"enable","package":mModPackage});
                  return;
               }
            }
         }
         var heroes:Array = row.heroes is Array ? row.heroes : [];
         var selection:Object = selectedMod(row,true);
         var target:Object = selection;
         // Defaults are authored values, never the active effective switches:
         // those already contain yesterday's user overrides.
         var inheritedChannels:Object = row.defaultChannels == null ? row.integrationDefaults : row.defaultChannels;
         var inheritedScopes:Object = row.defaultPatchScopes;
         mModSupport = row.channelSupport;
         if(mModHero >= 0 && mModHero < heroes.length)
         {
            var hero:Object = heroes[mModHero];
            var identity:String = String(hero.identity);
            if(selection.heroes == null) selection.heroes = {};
            if(selection.heroes[identity] == null) selection.heroes[identity] = {"channels":{},"patchScopes":{}};
            target = selection.heroes[identity];
            mModSupport = hero.channelSupport;
            inheritedChannels = mergedModDefaults(mergedModDefaults(inheritedChannels,hero.defaultChannels == null ? hero.integrationDefaults : hero.defaultChannels),selection.channels);
            inheritedScopes = mergedModDefaults(mergedModDefaults(inheritedScopes,hero.defaultPatchScopes),selection.patchScopes);
            modText("单英雄覆盖：" + hero.name + " / " + String(hero.variant == null ? hero.aid : hero.variant),16764006,48);
            modRow("返回整包设置",{"action":"heroBack"});
         }
         else
         {
            modText("整包默认设置。单英雄的手动选择优先。",16777215,42);
            for(var i:int = 0; i < heroes.length; i++) modRow("英雄：" + heroes[i].name + " / " + String(heroes[i].variant == null ? heroes[i].aid : heroes[i].variant),{"action":"hero","hero":i});
         }
         modRow("适用项全选",{"action":"all","value":true});
         modRow("适用项全不选",{"action":"all","value":false});
         modRow("恢复默认（移除本层手动覆盖）",{"action":"default"});
         modText("出现及获取渠道：关闭只停止后续产出，已有资产保留。",16764006,52);
         renderModToggles(mModInfo.channels,target.channels,inheritedChannels,"channels");
         if(row.kind == "patch")
         {
            modText("补丁替换范围：关闭后使用该场景的基础定义。",16764006,50);
            renderModToggles(mModInfo.patchScopes,target.patchScopes,inheritedScopes,"patchScopes");
         }
         if(mModHero < 0)
         {
            if(row.description) modText(String(row.description),16777215,85);
            if(row.sourceNotes) modText("来源说明：" + JSON.stringify(row.sourceNotes),16777215,90);
            modRow("全局卸载此版本（先查看影响）",{"action":"uninstall"});
         }
      }

      public static function mergedModDefaults(base:Object, overrides:Object) : Object
      {
         var result:Object = {};
         var key:String;
         if(base != null) for(key in base) result[key] = base[key];
         if(overrides != null) for(key in overrides) result[key] = overrides[key];
         return result;
      }

      private function renderModToggles(items:Object, explicit:Object, inherited:Object, group:String) : void
      {
         if(!(items is Array)) return;
         for each(var descriptor:Object in items)
         {
            var key:String = String(descriptor.key);
            var support:Object = group == "channels" && mModSupport != null ? mModSupport[key] : null;
            var supported:Boolean = descriptor.supported !== false && descriptor.applicable !== false && (support == null || support.supported !== false && support.applicable !== false);
            var value:Boolean = supported && modToggleValue(explicit,inherited,key);
            modRow((value ? "[开] " : "[关] ") + descriptor.label + (supported ? "" : "（不可用）"),{"action":"toggle","group":group,"key":key,"value":!value},supported);
            if(!supported && support != null && support.reason) modText(String(support.reason),11184810,42);
            else if(!supported && descriptor.reason) modText(String(descriptor.reason),11184810,42);
         }
      }

      private function editModTarget() : Object
      {
         var row:Object = mModInfo.packages[mModPackage];
         var selection:Object = selectedMod(row,true);
         if(mModHero < 0) return selection;
         var identity:String = String(row.heroes[mModHero].identity);
         return selection.heroes[identity];
      }

      private function onModRow(event:Event) : void
      {
         if(!modAlive() || mModBusy) return;
         var index:int = int(String(event.currentTarget.name).split("_")[1]);
         var action:Object = mModRows[index];
         if(action == null) return;
         if(action.action == "previewPage" && mModPreview) { mPreviewPage = int(action.value); renderModPreviewPage(); return; }
         if(action.action == "details") { mModPackage = int(action["package"]); mModHero = -1; renderModList(); return; }
         if(action.action == "hero") { mModHero = int(action.hero); renderModList(); return; }
         if(action.action == "heroBack") { mModHero = -1; renderModList(); return; }
         if(action.action == "uninstall") { previewUninstall(); return; }
         if(action.action == "backupExport" || action.action == "backupImport" || action.action == "backupPrevious")
         {
            beginBackupAction(String(action.action));
            return;
         }
         if(action.action == "enable")
         {
            var row:Object = mModInfo.packages[int(action["package"])];
            var selection:Object = selectedMod(row,true);
            var value:Boolean = selection.enabled === false;
            if(value)
            {
               // One version per permanent package in this save.
               for(var i:int = mModSelections.length - 1; i >= 0; i--)
                  if(mModSelections[i] !== selection && mModSelections[i].packageId == row.packageId) mModSelections.splice(i,1);
            }
            selection.enabled = value;
         }
         else
         {
            var target:Object = editModTarget();
            if(action.action == "default") { target.channels = {}; target.patchScopes = {}; }
            else if(action.action == "toggle")
            {
               if(target[action.group] == null) target[action.group] = {};
               target[action.group][action.key] = action.value;
            }
            else if(action.action == "all")
            {
               target.channels = {};
               target.patchScopes = {};
               for each(var channel:Object in mModInfo.channels)
                  if(channel.supported !== false && channel.applicable !== false) target.channels[channel.key] = action.value;
               if(mModInfo.packages[mModPackage].kind == "patch")
                  for each(var scope:Object in mModInfo.patchScopes)
                     if(scope.supported !== false && scope.applicable !== false) target.patchScopes[scope.key] = action.value;
            }
         }
         mModDirty = true;
         mModPlan = null;
         mModRequestId = "";
         mModStatus.text = "有未保存变更。预览校验通过后才会提交；失败保留当前活动配置。";
         renderModList();
      }

      private function formatModIssue(issue:Object) : String
      {
         if(issue == null) return "未知问题";
         if(issue is String) return String(issue);
         return String(issue.message == null ? issue.code == null ? JSON.stringify(issue) : issue.code : issue.message) + (issue.path == null ? "" : "\n位置：" + issue.path);
      }

      private function previewLineCount(text:String) : int
      {
         var count:int = 0;
         for each(var line:String in text.split("\n")) count += Math.max(1,Math.ceil(line.length / 28));
         return count;
      }

      private function beginPreviewPages() : void
      {
         mPreviewBlocks = [];
         mPreviewLineCount = 0;
         mPreviewPage = 0;
         mPreviewConfirm = null;
         mPreviewConfirmLabel = "";
         mBuildingPreview = true;
      }

      private function finishPreviewPages(label:String, confirm:Function) : void
      {
         mBuildingPreview = false;
         mPreviewConfirmLabel = label;
         mPreviewConfirm = confirm;
         renderModPreviewPage();
      }

      private function renderModPreviewPage() : void
      {
         var pages:int = Math.max(1,Math.ceil(mPreviewLineCount / 60));
         mPreviewPage = Math.max(0,Math.min(pages - 1,mPreviewPage));
         beginModRows();
         modText("预览第 " + (mPreviewPage + 1) + " / " + pages + " 页 · 共 " + mPreviewLineCount + " 行",16764006,40);
         var first:int = mPreviewPage * 60;
         var last:int = Math.min(first + 60,mPreviewLineCount);
         var cursor:int = 0;
         for each(var block:Object in mPreviewBlocks)
         {
            if(cursor >= last) break;
            if(cursor + int(block.count) <= first) { cursor += int(block.count); continue; }
            var text:String = block.hasOwnProperty("value") ? String(block.label) + "\n" + JSON.stringify(block.value,null,2) : String(block.text);
            if(!block.wrapped) { modText(text,block.color,block.height); cursor++; continue; }
            for each(var line:String in text.split("\n"))
            {
               var count:int = Math.max(1,Math.ceil(line.length / 28));
               for(var i:int = 0; i < count; i++)
               {
                  if(cursor >= first && cursor < last) modText(line.length == 0 ? " " : line.substr(i * 28,28),block.color,28);
                  cursor++;
               }
            }
         }
         if(mPreviewPage > 0) modRow("上一页",{"action":"previewPage","value":mPreviewPage - 1});
         if(mPreviewPage + 1 < pages) modRow("下一页",{"action":"previewPage","value":mPreviewPage + 1});
         if(mPreviewConfirm != null)
         {
            modRow(mPreviewConfirmLabel,{"action":"previewConfirm"});
            var confirm:LOL_Scale9Button = mModScroll.getChildAt(mModScroll.numChildren - 1) as LOL_Scale9Button;
            confirm.removeEventListener("triggered",onModRow);
            confirm.addEventListener("triggered",mPreviewConfirm);
         }
      }

      private function modWrappedText(text:String, color:uint = 16777215) : void
      {
         if(mBuildingPreview)
         {
            var count:int = previewLineCount(text);
            mPreviewBlocks.push({"text":text,"color":color,"wrapped":true,"count":count});
            mPreviewLineCount += count;
            return;
         }
         for each(var line:String in text.split("\n"))
         {
            if(line.length == 0) { modText(" ",color,28); continue; }
            for(var offset:int = 0; offset < line.length; offset += 28) modText(line.substr(offset,28),color,28);
         }
      }

      private function modPreviewValue(label:String, value:Object, color:uint = 16777215) : void
      {
         var text:String = label + "\n" + JSON.stringify(value,null,2);
         if(!mBuildingPreview) { modWrappedText(text,color); return; }
         var count:int = previewLineCount(text);
         // Keep the original value reference, not a second large JSON copy.
         // Only the current page constructs text fields or formatted strings.
         mPreviewBlocks.push({"label":label,"value":value,"color":color,"wrapped":true,"count":count});
         mPreviewLineCount += count;
      }

      private function renderModChange(change:Object) : void
      {
         if(change == null || change is String) { modWrappedText(String(change)); return; }
         var heading:String = change.message == null ? change.type == null ? "变更" : String(change.type) : String(change.message);
         modWrappedText(heading,16764006);
         for each(var key:String in ["packageId","patchId","target","scope","path"])
            if(change[key] != null) modWrappedText(key + "：" + String(change[key]));
         if(change.hasOwnProperty("before")) modPreviewValue("原值：",change.before);
         if(change.hasOwnProperty("after")) modPreviewValue("新值：",change.after);
         if(change.changes is Array) for each(var nested:Object in change.changes) renderModChange(nested);
         if(change.sourceNotes != null) modPreviewValue("来源说明：",change.sourceNotes,11184810);
      }

      private function clearBackupPicker() : void
      {
         if(mBackupFile != null)
         {
            mBackupFile.removeEventListener(flash.events.Event.SELECT,onBackupSelected);
            mBackupFile.removeEventListener(flash.events.Event.CANCEL,onBackupCancelled);
            mBackupFile.removeEventListener(IOErrorEvent.IO_ERROR,onBackupCancelled);
         }
         mBackupFile = null;
         mBackupValue = null;
         mBackupMode = "";
         mBackupOperation = null;
      }

      private function beginBackupAction(action:String) : void
      {
         if(mModBusy || !modAlive() || mModInfo == null) return;
         if(mModDirty) { mModStatus.text = "请先保存或放弃编辑，再备份或恢复已保存的 Mod 设置。"; return; }
         var operation:Object = beginModOperation(action == "backupImport" ? "backup_file" : "user.mods_backup");
         if(action == "backupImport") { openBackupPicker("read",null,operation); return; }
         mModStatus.text = action == "backupPrevious" ? "正在读取上一次 Mod 设置…" : "正在获取当前已保存的 Mod 设置…";
         SendAndSelect.sendAndSelectService("user.mods_backup",{"previous":action == "backupPrevious"},function(reply:Object):void
         {
            if(!modOperationMatches(operation) || !modReplyMatches(reply,String(operation.owner),modAlive())) return;
            if(action == "backupPrevious") { completeModOperation(operation); previewModRestore(reply.data); }
            else { operation.method = "backup_file"; openBackupPicker("write",reply.data,operation); }
         });
      }

      private function openBackupPicker(mode:String, backup:Object, operation:Object) : void
      {
         clearBackupPicker();
         mBackupOperation = operation;
         mBackupMode = mode;
         mBackupValue = backup;
         try
         {
            mBackupFile = File.documentsDirectory.resolvePath("lal-mod-settings-" + new Date().time + ".json");
            mBackupFile.addEventListener(flash.events.Event.SELECT,onBackupSelected);
            mBackupFile.addEventListener(flash.events.Event.CANCEL,onBackupCancelled);
            mBackupFile.addEventListener(IOErrorEvent.IO_ERROR,onBackupCancelled);
            if(mode == "write") mBackupFile.browseForSave("保存 Mod 元数据备份");
            else mBackupFile.browseForOpen("选择 Mod 元数据备份",[new FileFilter("Mod 备份 (*.json)","*.json")]);
            mModStatus.text = mode == "write" ? "选择备份保存位置；只导出 Mod 元数据。" : "请选择备份文件；读取后先校验与预览，不会立即恢复。";
         }
         catch(error:Error)
         {
            clearBackupPicker();
            failModOperation(operation,"此设备无法打开备份文件选择器；当前设置未改变。");
         }
      }

      private function onBackupCancelled(event:flash.events.Event) : void
      {
         if(event.currentTarget !== mBackupFile || !modOperationMatches(mBackupOperation)) return;
         var operation:Object = mBackupOperation;
         clearBackupPicker();
         completeModOperation(operation);
         mModStatus.text = event.type == IOErrorEvent.IO_ERROR ? "此设备无法打开文件选择器；当前设置未改变。" : "已取消文件选择；当前设置未改变。";
      }

      private function onBackupSelected(event:flash.events.Event) : void
      {
         if(event.currentTarget !== mBackupFile || !modOperationMatches(mBackupOperation)) return;
         var operation:Object = mBackupOperation;
         var mode:String = mBackupMode;
         var backup:Object = mBackupValue;
         var file:File = mBackupFile;
         clearBackupPicker();
         var stream:FileStream = new FileStream();
         try
         {
            if(mode == "write")
            {
               stream.open(file,FileMode.WRITE);
               stream.writeUTFBytes(JSON.stringify(backup,null,2));
               stream.close();
               completeModOperation(operation);
               mModStatus.text = "Mod 元数据备份已保存；英雄包文件需另行保留。";
               return;
            }
            if(file.size > 8388608) throw new Error("备份超过 8 MiB，未读取。");
            stream.open(file,FileMode.READ);
            backup = JSON.parse(stream.readUTFBytes(stream.bytesAvailable));
            stream.close();
            if(backup == null || backup.schema != "lal-mod-backup-v1") throw new Error("不是 lal-mod-backup-v1 备份。");
         }
         catch(error:Error)
         {
            try { stream.close(); } catch(ignore:Error) {}
            completeModOperation(operation);
            mModStatus.text = "备份文件操作失败：" + error.message + " 当前设置未改变。";
            return;
         }
         completeModOperation(operation);
         previewModRestore(backup);
      }

      private function previewModRestore(backup:Object) : void
      {
         if(mModBusy || !modAlive() || mModDirty || mModInfo == null) return;
         var operation:Object = beginModOperation("user.mods_restore_plan");
         mRestoreBackup = JSON.parse(JSON.stringify(backup));
         mRestorePlan = null;
         mRestoreRequestId = "";
         mModStatus.text = "正在校验备份摘要、身份映射、缺失包和恢复影响…";
         SendAndSelect.sendAndSelectService("user.mods_restore_plan",{"backup":mRestoreBackup,"expectedRevision":mModInfo.revision},function(reply:Object):void
         {
            if(!modOperationMatches(operation) || !modReplyMatches(reply,String(operation.owner),modAlive())) return;
            completeModOperation(operation);
            mRestorePlan = reply.data;
            mModPreview = true;
            beginPreviewPages();
            modText("恢复 Mod 设置预览",16764006,40);
            modWrappedText("只恢复包清单、开关和永久身份映射；不会恢复包文件，也不会回滚卡牌、装备、货币或其他游戏进度。",16764006);
            if(mRestorePlan.changes is Array) for each(var change:Object in mRestorePlan.changes) renderModChange(change);
            if(mRestorePlan.warnings is Array) for each(var warning:Object in mRestorePlan.warnings) modWrappedText(formatModIssue(warning),16764006);
            if(mRestorePlan.errors is Array) for each(var error:Object in mRestorePlan.errors) modWrappedText(formatModIssue(error),16736512);
            if(mRestorePlan.valid !== true) { finishPreviewPages("",null); mModStatus.text = "恢复校验未通过；当前配置未改变。"; return; }
            modWrappedText("缺少的英雄包仍显示内容缺失。确认后保存新修订并重新进入游戏；返回可取消。",16764006);
            finishPreviewPages("确认恢复并重新进入游戏",commitModRestore);
            mModStatus.text = "备份校验通过；等待明确确认。";
         });
      }

      private function commitModRestore(event:Event) : void
      {
         if(mModBusy || !modAlive() || !mModPreview || mRestorePlan == null || mRestorePlan.valid !== true || mRestoreBackup == null || mModDirty) return;
         var operation:Object = beginModOperation("user.mods_restore",true);
         if(mRestoreRequestId.length == 0) mRestoreRequestId = "restore_" + new Date().time + "_" + int(Math.random() * 1000000000);
         mModStatus.text = "正在原子恢复 Mod 设置；失败不会覆盖当前活动配置。";
         SendAndSelect.sendAndSelectService("user.mods_restore",{"backup":mRestoreBackup,"expectedRevision":mRestorePlan.revision,"planDigest":mRestorePlan.planDigest,"requestId":mRestoreRequestId},function(reply:Object):void
         {
            if(!modOperationMatches(operation) || !modReplyMatches(reply,String(operation.owner),modAlive())) return;
            mModDirty = false;
            GlobalData.$modReady = false;
            mModStatus.text = "Mod 设置已恢复，正在重新进入游戏同步资源…";
            setTimeout(function():void { if(modOperationMatches(operation)) GlobalFunction.quitGame(); },150);
         });
      }

      private function previewMods(event:Event) : void
      {
         if(mModBusy || !modAlive() || mModInfo == null) return;
         var operation:Object = beginModOperation("user.mods_plan");
         mModStatus.text = "正在校验依赖、冲突、渠道及存档影响…";
         SendAndSelect.sendAndSelectService("user.mods_plan",{"expectedRevision":mModInfo.revision,"selections":mModSelections},function(reply:Object):void
         {
            if(!modOperationMatches(operation) || !modReplyMatches(reply,String(operation.owner),modAlive())) return;
            completeModOperation(operation);
            mModPlan = reply.data;
            mModPreview = true;
            beginPreviewPages();
            modText("配置变更预览",16764006,40);
            for each(var change:Object in mModPlan.changes) renderModChange(change);
            for each(var warning:Object in mModPlan.warnings) modWrappedText(formatModIssue(warning),16764006);
            for each(var error:Object in mModPlan.errors) modWrappedText(formatModIssue(error),16736512);
            if(mModPlan.valid === true)
            {
               modText("提交后需要重新进入游戏。包的更新不会重置你的手动关闭项；已获得英雄和碎片继续保留。",16764006,85);
               finishPreviewPages("确认保存并重新进入游戏",commitMods);
               mModStatus.text = "校验通过；等待确认。";
            }
            else { finishPreviewPages("",null); mModStatus.text = "校验未通过，编辑内容已保留。返回后可调整。"; }
         });
      }

      private function commitMods(event:Event) : void
      {
         if(mModBusy || !modAlive() || mModPlan == null || mModPlan.valid !== true) return;
         var operation:Object = beginModOperation("user.mods_apply",true);
         if(mModRequestId.length == 0) mModRequestId = "mods_" + new Date().time + "_" + int(Math.random() * 1000000000);
         mModStatus.text = "正在原子保存；完成后重新登录同步。";
         SendAndSelect.sendAndSelectService("user.mods_apply",{"expectedRevision":mModInfo.revision,"planDigest":mModPlan.planDigest,"selections":mModSelections,"requestId":mModRequestId},function(reply:Object):void
         {
            if(!modOperationMatches(operation) || !modReplyMatches(reply,String(operation.owner),modAlive())) return;
            mModDirty = false;
            mModStatus.text = "已保存，待重新进入生效。正在返回登录界面…";
            GlobalData.$modReady = false;
            setTimeout(function():void { if(modOperationMatches(operation)) GlobalFunction.quitGame(); },150);
         });
      }

      private function onModError(event:Object) : void
      {
         if(!modAlive() || !mModBusy || mModOperation == null) return;
         var operation:Object = mModOperation;
         // Native pickers are not network requests; an unrelated timer must
         // not cancel a selected backup or import file.
         if(operation.method == "backup_file" || operation.method == "import_file") return;
         var data:Object = event.data;
         var method:String = data == null || data.method == null ? "" : String(data.method);
         if(method == "profile_state_sync" && data.receipt_method != null) method = String(data.receipt_method);
         if(method.length > 0 && method != operation.method) return;
         var uncertain:Boolean = event.type == "net_timeout" || event.type == "error_service" || data != null && data.profile_sync_error === true;
         var message:String = data != null && data.data != null ? formatModIssue(data.data) : "请求未完成。编辑内容已保留，请重新同步后重试。";
         failModOperation(operation,message,uncertain);
      }

      private function clearImportPicker() : void
      {
         if(mImportFile != null)
         {
            mImportFile.removeEventListener(flash.events.Event.SELECT,onImportSelected);
            mImportFile.removeEventListener(flash.events.Event.CANCEL,onImportCancelled);
            mImportFile.removeEventListener(IOErrorEvent.IO_ERROR,onImportCancelled);
         }
         mImportFile = null;
         mImportOperation = null;
      }

      private function onImportCancelled(event:flash.events.Event) : void
      {
         if(event.currentTarget !== mImportFile || !modOperationMatches(mImportOperation)) return;
         var operation:Object = mImportOperation;
         clearImportPicker();
         completeModOperation(operation);
         mModStatus.text = event.type == IOErrorEvent.IO_ERROR ? "此设备无法打开文件选择器；未导入英雄包。" : "已取消导入英雄包。";
      }

      private function importMod(event:Event) : void
      {
         if(mModBusy || !modAlive()) return;
         if(mModDirty) { mModStatus.text = "请先保存或放弃编辑，再导入新包。"; return; }
         var operation:Object = beginModOperation("import_file");
         clearImportPicker();
         mImportOperation = operation;
         try
         {
            mImportFile = File.documentsDirectory;
            mImportFile.addEventListener(flash.events.Event.SELECT,onImportSelected);
            mImportFile.addEventListener(flash.events.Event.CANCEL,onImportCancelled);
            mImportFile.addEventListener(IOErrorEvent.IO_ERROR,onImportCancelled);
            mImportFile.browseForOpen("导入英雄包",[new FileFilter("英雄包 (*.heropack)","*.heropack")]);
         }
         catch(error:Error)
         {
            clearImportPicker();
            failModOperation(operation,"此设备无法打开文件选择器。可将包放入 mods/inbox 后检查目录。");
         }
      }

      private function onImportSelected(event:flash.events.Event) : void
      {
         if(event.currentTarget !== mImportFile || !modOperationMatches(mImportOperation)) return;
         var operation:Object = mImportOperation;
         var file:File = mImportFile;
         clearImportPicker();
         var bytes:ByteArray = new ByteArray();
         var stream:FileStream = new FileStream();
         try
         {
            if(file.size > 67108864) { completeModOperation(operation); mModStatus.text = "英雄包超过 64 MiB，未导入。"; return; }
            stream.open(file,FileMode.READ); stream.readBytes(bytes); stream.close();
         }
         catch(readError:Error)
         {
            try { stream.close(); } catch(ignore:Error) {}
            failModOperation(operation,"无法读取所选文件，未导入英雄包。");
            return;
         }
         operation = beginModOperation("mods.install",true);
         mModStatus.text = "正在导入并验证英雄包…";
         var request:URLRequest = new URLRequest(MainConfig.$SERVER_ADDRESS.replace(/\/$/,"") + "/mods/install");
         request.method = "POST";
         request.contentType = "application/octet-stream";
         request.requestHeaders = [new URLRequestHeader("X-Lal-Uid",String(operation.owner)),new URLRequestHeader("X-Lal-Session",SendAndSelect.$sessionid)];
         request.data = bytes;
         var loader:URLLoader = new URLLoader();
         var timeout:uint = 0;
         var failed:Function = function(error:Object):void
         {
            if(!modOperationMatches(operation)) return;
            clearTimeout(timeout);
            failModOperation(operation,"导入结果尚未确认，英雄包可能已安装。",true);
            try { loader.close(); } catch(ignore:Error) {}
         };
         loader.addEventListener(IOErrorEvent.IO_ERROR,failed);
         loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR,failed);
         loader.addEventListener(flash.events.Event.COMPLETE,function(done:flash.events.Event):void
         {
            if(!modOperationMatches(operation)) return;
            clearTimeout(timeout);
            try
            {
               var result:Object = JSON.parse(String(loader.data));
               if(result.ok !== true) { completeModOperation(operation); mModStatus.text = "导入失败：" + formatModIssue(result.error); return; }
               completeModOperation(operation);
               requestModInfo(false);
            }
            catch(parseError:Error) { failModOperation(operation,"导入返回格式错误，安装结果尚未确认。",true); }
         });
         timeout = setTimeout(function():void { failed(null); },60000);
         try { loader.load(request); } catch(uploadError:Error) { failed(uploadError); }
      }

      private function previewUninstall() : void
      {
         if(mModDirty) { mModStatus.text = "请先保存或放弃存档编辑，再执行全局卸载。"; return; }
         var row:Object = mModInfo.packages[mModPackage];
         var params:Object = {"packageId":row.packageId,"version":row.version,"contentDigest":row.contentDigest};
         var operation:Object = beginModOperation("user.mods_uninstall_plan");
         SendAndSelect.sendAndSelectService("user.mods_uninstall_plan",params,function(reply:Object):void
         {
            if(!modOperationMatches(operation) || !modReplyMatches(reply,String(operation.owner),modAlive())) return;
            completeModOperation(operation);
            var plan:Object = reply.data;
            mModPreview = true;
            beginPreviewPages();
            modText("全局卸载预览",16764006,40);
            modText("将影响 " + plan.affectedSaves + " 个存档。新增英雄将显示内容缺失并冻结；替换补丁将回退。",16764006,85);
            for each(var change:Object in plan.changes) renderModChange(change);
            for each(var error:Object in plan.errors) modWrappedText(formatModIssue(error),16736512);
            if(plan.valid !== true) { finishPreviewPages("",null); mModStatus.text = "无法卸载，请先处理以上问题。"; return; }
            finishPreviewPages("确认全局卸载此版本",function(event:Event):void
            {
               if(!modAlive() || mModBusy) return;
               var mutation:Object = beginModOperation("user.mods_uninstall",true);
               params.planDigest = plan.planDigest;
               SendAndSelect.sendAndSelectService("user.mods_uninstall",params,function(done:Object):void
               {
                  if(!modOperationMatches(mutation) || !modReplyMatches(done,String(mutation.owner),modAlive())) return;
                  mModDirty = false;
                  mModStatus.text = "已卸载。需要重新进入游戏以同步缺失状态和补丁回退。";
                  GlobalData.$modReady = false;
                  setTimeout(function():void { if(modOperationMatches(mutation)) GlobalFunction.quitGame(); },150);
               });
            });
            mModStatus.text = "卸载会影响上述全部存档，等待确认。返回可取消。";
         });
      }
   }
}
