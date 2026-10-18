package
{
   import flash.desktop.NativeApplication;
   import flash.display.BitmapData;
   import flash.display.Loader;
   import flash.display.PNGEncoderOptions;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.TimerEvent;
   import flash.events.UncaughtErrorEvent;
   import flash.filesystem.File;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;
   import flash.net.URLRequest;
   import flash.system.ApplicationDomain;
   import flash.system.Capabilities;
   import flash.system.LoaderContext;
   import flash.utils.ByteArray;
   import flash.utils.Timer;
   import flash.utils.getQualifiedClassName;
   import flash.utils.getTimer;

   /** Runs the delivered SWF in AIR; no replacement battle implementation. */
   public class ModRuntimeProbe extends Sprite
   {
      private var loader:Loader = new Loader();
      private var domain:ApplicationDomain;
      private var timer:Timer = new Timer(500);
      private var started:int = getTimer();
      private var phase:int = 0;
      private var phaseTime:int = 0;
      private var lastStatus:int = 0;
      private var settings:Object;
      private var map:Object;
      private var panel:Object;
      private var failed:Boolean = false;
      private var scopeOwned:Object;
      private var scopeEnemy:Object;
      private var scopeOwnedCast:Boolean = false;
      private var scopeEnemyCast:Boolean = false;

      public function ModRuntimeProbe()
      {
         stage.scaleMode = "noScale";
         stage.align = "TL";
         settings = JSON.parse(read("probe.json"));
         var overrides:File = File.applicationStorageDirectory.resolvePath("probe-override.json");
         if(overrides.exists)
         {
            var overrideStream:FileStream = new FileStream();
            overrideStream.open(overrides,FileMode.READ);
            var overrideValues:Object = JSON.parse(overrideStream.readUTFBytes(overrideStream.bytesAvailable));
            overrideStream.close();
            for(var key:String in overrideValues) settings[key] = overrideValues[key];
         }
         log("PROBE_START");
         loader.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR,onError);
         loader.contentLoaderInfo.addEventListener(Event.COMPLETE,onLoaded);
         addChild(loader);
         loader.load(new URLRequest("MainLLOL.swf"),new LoaderContext(false,new ApplicationDomain(ApplicationDomain.currentDomain)));
         timer.addEventListener(TimerEvent.TIMER,tick);
         timer.start();
      }

      private function read(name:String):String
      {
         var stream:FileStream = new FileStream();
         stream.open(File.applicationDirectory.resolvePath(name),FileMode.READ);
         var value:String = stream.readUTFBytes(stream.bytesAvailable);
         stream.close();
         return value;
      }

      private function log(value:String):void
      {
         trace("MOD_PROBE "+value);
         var stream:FileStream = new FileStream();
         var target:File = Capabilities.manufacturer.indexOf("Android") >= 0 ? File.applicationStorageDirectory : new File(String(settings.outputDirectory));
         stream.open(target.resolvePath("mod-probe.log"),FileMode.APPEND);
         stream.writeUTFBytes(String(getTimer()-started)+" "+value+"\n");
         stream.close();
      }

      private function onError(event:UncaughtErrorEvent):void
      {
         event.preventDefault();
         failed = true;
         var error:Error = event.error as Error;
         log("UNCAUGHT "+(error == null ? String(event.error) : error.getStackTrace()));
      }

      private function onLoaded(event:Event):void
      {
         domain = loader.contentLoaderInfo.applicationDomain;
         log("SWF_LOADED");
      }

      private function definition(name:String):Class
      {
         return domain.getDefinition(name) as Class;
      }

      private function find(root:Object, match:String, text:Boolean=false, depth:int=0, contains:Boolean=false):Object
      {
         if(root == null || depth > 16) return null;
         if(text)
         {
            try { if("text" in root && (contains ? String(root.text).indexOf(match) >= 0 : String(root.text) == match)) return root; }
            catch(textError:Error) { /* Some unlabeled native buttons have no TextField. */ }
         }
         try
         {
            if(!text && getQualifiedClassName(root).indexOf(match) >= 0) return root;
            if("numChildren" in root)
            {
               for(var i:int=0;i<int(root.numChildren);i++)
               {
                  var found:Object = find(root.getChildAt(i),match,text,depth+1,contains);
                  if(found != null) return found;
               }
            }
         }
         catch(error:Error) { return null; }
         return null;
      }

      private function snapshot(name:String, gd:Class):void
      {
         try
         {
            var bitmap:BitmapData = gd["$mStarling"].stage.drawToBitmapData();
            var bytes:ByteArray = bitmap.encode(bitmap.rect,new PNGEncoderOptions());
            var stream:FileStream = new FileStream();
            var target:File = Capabilities.manufacturer.indexOf("Android") >= 0 ? File.applicationStorageDirectory : new File(String(settings.outputDirectory));
            stream.open(target.resolvePath(name+".png"),FileMode.WRITE);
            stream.writeBytes(bytes);
            stream.close();
            bitmap.dispose();
            log("CAPTURE "+name);
         }
         catch(error:Error) { log("CAPTURE_ERROR "+error.message); }
      }

      private function advance(value:int):void
      {
         phase = value;
         phaseTime = getTimer();
      }

      private function tick(event:TimerEvent):void
      {
         if(getTimer()-started > 600000 || failed)
         {
            timer.stop();
            log("PROBE_FAILED phase="+phase);
            NativeApplication.nativeApplication.exit(1);
            return;
         }
         if(domain == null) return;
         try
         {
            var gd:Class = definition("com.meng52.game.global.GlobalData");
            // AIR pauses Starling when an automated test loses native focus.
            // Keep its real render/animation loop running in this QA host.
            if(gd["$mStarling"] != null) gd["$mStarling"].start();
            var root:Object = gd["$mGameClassObject"];
            if(getTimer()-lastStatus > 10000)
            {
               log("STATE phase="+phase+" starling="+(gd["$mStarling"] != null)+" game="+(root != null)+" user="+(gd["$userData"] != null));
               lastStatus = getTimer();
            }
            if(root == null) return;
            if(phase == 0)
            {
               var login:Object = find(root,"PanelServiceMain");
               if(login == null || String(gd["$mServiceID"]).length == 0) return;
               var local:Class = definition("com.meng52.game.global.GlobalLocalStore");
               local["$pf_token_curr"] = settings.account;
               local["$pf_uid_curr"] = settings.password;
               local["$pf_type_curr"] = "local";
               login.sendLoginService();
               log("LOGIN_SENT");
               advance(1);
            }
            else if(phase == 1 && gd["$userData"] != null && gd["$modReady"] && getTimer()-phaseTime > 2000)
            {
               if(root["mLayoutUICenter"] == null) return;
               log("LOGIN_READY uid="+gd["$modUid"]+" digest="+gd["$modDigest"]);
               if(settings.mode == "managed")
               {
                  var heroState:Object = gd["$modRuntime"].heroes[String(settings.expectedHero)];
                  if(heroState == null || heroState.channels["acquisition.summon.normal"] !== false)
                     throw new Error("The manual channel choice did not survive the real re-login.");
                  log("MANUAL_CHANNEL_PERSISTED revision="+gd["$modRevision"]);
               }
               for each(var asset:Object in gd["$modRuntime"].assets)
               {
                  if(asset.kind == "image")
                  {
                     var texture:Object = gd["$assetManager"].getTexture(String(asset.alias));
                     if(texture == null) throw new Error("Native image was not decoded: "+asset.path);
                     log("IMAGE_READY "+asset.path+" "+texture.width+"x"+texture.height);
                  }
                  else if(asset.kind == "sound")
                  {
                     var sound:Object = gd["$assetManager"].getSound(String(asset.alias));
                     if(sound == null || sound.length <= 0) throw new Error("Native audio was not decoded: "+asset.path);
                     var channel:Object = sound.play();
                     if(channel == null) throw new Error("Native audio channel was not started.");
                     channel.addEventListener(Event.SOUND_COMPLETE,function(event:Event):void { log("SOUND_COMPLETE"); });
                     log("SOUND_PLAY "+asset.path+" ms="+sound.length);
                  }
               }
               root.closePopUp();
               gd["$currentGuide"] = null;
               definition("com.meng52.game.module.guide.GuideMaster")["getOnlyExample"]().skipGuide();
               root["mLayoutUICenter"].showPanel("center_help_setting");
               panel = find(root,"PanelHelpSetting");
               log("SETTINGS_OPEN");
               advance(2);
            }
            else if(phase == 2 && getTimer()-phaseTime > 1000)
            {
               panel = find(root,"PanelHelpSetting");
               var button:Object = find(panel,"Mod 管理",true);
               if(button == null) return;
               button.dispatchEventWith("triggered",true);
               log("MOD_MANAGER_OPEN");
               advance(3);
            }
            else if(phase == 3 && getTimer()-phaseTime > 2500)
            {
               snapshot("mod-manager",gd);
               if(settings.mode == "manage")
               {
                  var details:Object = find(panel,"展开英雄、玩法及补丁范围",true);
                  if(details == null) throw new Error("Package details are unavailable.");
                  details.dispatchEventWith("triggered",true);
                  advance(8);
                  return;
               }
               if(settings.mode == "missing")
               {
                  if(!gd["isMissingModHero"](String(settings.expectedHero))) throw new Error("Missing hero was not frozen.");
                  definition("com.meng52.game.global.GlobalFunction")["setDetaiAvatar"]({id:String(settings.expectedInstance)});
                  log("MISSING_PLACEHOLDER "+settings.expectedHero);
                  advance(7);
                  return;
               }
               if(settings.mode == "import" || settings.mode == "directory-import")
               {
                  var importButton:Object = find(panel,settings.mode == "import" ? "导入包" : "检查目录",true);
                  if(importButton == null) throw new Error("Native import button is missing.");
                  importButton.dispatchEventWith("triggered",true);
                  log(settings.mode == "import" ? "IMPORT_PICKER_OPEN" : "IMPORT_DIRECTORY_SCAN");
                  advance(6);
                  return;
               }
               root.closePopForPanel(0);
               root["mLayoutUICenter"].showPanel("center_main");
               var layer:Object = definition("com.meng52.game.ui.map.GameMapLayer")["gl"];
               var layerClass:Class = definition("com.meng52.game.ui.map.GameMapLayer");
               layerClass["fpsLv"] = layerClass["FPS_LIST"].length - 1;
               root.addChild(layer.mapStage);
               gd["$isNoFriendToPVE"] = true;
               gd["$tempPVE_combatID"] = "M_001_1";
               gd["$tempPVE_type"] = "status_pve_normal";
               definition("com.meng52.game.ui.stage.GuideTools")["doPreStory"]("M_001_1");
               var mapClass:Class = definition("com.meng52.game.module.map.GameMap");
               mapClass["isLoad"] = mapClass["isLoadFile"] = false;
               map = new mapClass("M_001_1",0);
               var prepared:Array = [];
               var selected:Array = gd["$userData"].team[0];
               map.myList = [];
               map.team1Offset = [];
               for(var slot:int=0;slot<selected.length;slot++)
               {
                  if(selected[slot] == null || selected[slot] == "") continue;
                  if(prepared.length >= 5) break;
                  prepared.push({data:{id:selected[slot],indexID_s:slot}});
                  map.myList.push([selected[slot],(prepared.length-1)%map.getLaneCount(),0.35]);
                  map.team1Offset.push(0);
               }
               map.initMap(true,prepared);
               map.sendFight();
               log("FIGHT_SENT own="+map.team1List.length+" enemy="+map.team2List.length);
               advance(4);
            }
            else if(phase == 4 && map.re != null)
            {
               var names:Array = [];
               for each(var avatar:Object in map.team1List) names.push(avatar.avatarData.id);
               log("FIGHT_ORIGIN own="+names.join(","));
               if(names.indexOf(String(settings.expectedHero)) < 0) throw new Error("The registered Mod hero did not enter the real battle.");
               if(settings.scopeTargetAid != null)
               {
                  for each(var owned:Object in map.team1List)
                     if(String(owned.avatarData.id) == String(settings.scopeTargetAid)) scopeOwned = owned;
                  for each(var enemy:Object in map.team2List)
                     if(String(enemy.avatarData.id) == String(settings.scopeEnemyDefinition)) scopeEnemy = enemy;
                  if(scopeOwned == null || scopeEnemy == null) throw new Error("The same target hero is not present on both sides.");
                  if(scopeOwned.skill0 == null || String(scopeOwned.skill0.skillSetData.id) != String(settings.scopeOwnedSkill) ||
                     scopeEnemy.skill0 == null || String(scopeEnemy.skill0.skillSetData.id) != String(settings.scopeEnemySkill))
                     throw new Error("Native per-side skill definitions do not match the compiled scopes.");
                  log("SCOPES_READY owned="+scopeOwned.skill0.skillSetData.id+" enemy="+scopeEnemy.skill0.skillSetData.id);
               }
               snapshot("mod-battle",gd);
               advance(5);
            }
            else if(phase == 5)
            {
               if(scopeOwned != null && scopeOwned.skill0.abilityHasCast && !scopeOwnedCast)
               { scopeOwnedCast = true; log("SCOPE_OWNED_CAST "+scopeOwned.skill0.skillSetData.id); }
               if(scopeEnemy != null && scopeEnemy.skill0.abilityHasCast && !scopeEnemyCast)
               { scopeEnemyCast = true; log("SCOPE_ENEMY_CAST "+scopeEnemy.skill0.skillSetData.id); }
               if(getTimer()-phaseTime > 5000 && map.roundNum > 0)
               {
                  log("BATTLE_PROGRESS round="+map.roundNum+" winner="+map.winner+" settling="+map.settlementPending+" sent="+map.settlementSent);
                  phaseTime = getTimer();
               }
               if(map.settlementSent && !map.settlementPending && map.winner > 0)
               {
                  if(scopeOwned != null && (!scopeOwnedCast || !scopeEnemyCast)) throw new Error("Both scoped skills must execute before A11 can pass.");
                  snapshot("mod-battle-finished",gd);
                  log("PROBE_FINISHED winner="+map.winner+" round="+map.roundNum);
                  timer.stop();
                  NativeApplication.nativeApplication.exit(0);
               }
            }
            else if(phase == 6 && getTimer()-phaseTime > 2000)
            {
               if(find(panel,"Native Import QA",true,0,true) != null)
               {
                  snapshot("mod-imported",gd);
                  log("PROBE_FINISHED imported="+settings.expectedImportedPackage);
                  timer.stop();
                  NativeApplication.nativeApplication.exit(0);
               }
            }
            else if(phase == 7 && getTimer()-phaseTime > 1500)
            {
               snapshot("mod-missing",gd);
               log("PROBE_FINISHED missing="+settings.expectedHero);
               timer.stop();
               NativeApplication.nativeApplication.exit(0);
            }
            else if(phase == 8 && getTimer()-phaseTime > 1000)
            {
               var channelButton:Object = find(panel,"[开] 普通召唤",true);
               if(channelButton == null) throw new Error("The default normal-summon channel is not enabled.");
               channelButton.dispatchEventWith("triggered",true);
               if(find(panel,"[关] 普通召唤",true) == null) throw new Error("The channel checkbox did not change.");
               snapshot("mod-channel-edited",gd);
               find(panel,"预览保存",true).dispatchEventWith("triggered",true);
               log("MANAGE_PREVIEW_SENT");
               advance(9);
            }
            else if(phase == 9 && getTimer()-phaseTime > 1000)
            {
               var commit:Object = find(panel,"确认保存并重新进入游戏",true);
               if(commit == null) return;
               snapshot("mod-preview",gd);
               commit.dispatchEventWith("triggered",true);
               log("MANAGE_COMMIT_SENT");
               advance(10);
            }
            else if(phase == 10 && String(definition("com.meng52.net.SendAndSelect")["$uid"]).length == 0)
            {
               log("MANAGE_RELOGIN");
               settings.mode = "managed";
               advance(0);
            }
         }
         catch(error:Error)
         {
            timer.stop();
            log("PROBE_ERROR phase="+phase+" "+error.getStackTrace());
            NativeApplication.nativeApplication.exit(1);
         }
      }
   }
}
