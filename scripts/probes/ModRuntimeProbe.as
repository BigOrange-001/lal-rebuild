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
   import flash.geom.Point;
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
      private var releasePrepared:Array;
      private var releaseWait:int;
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


      private function requireRelease(ok:Boolean, label:String):void
      {
         if(!ok) throw new Error("Release 1.0.3: "+label);
         log("RELEASE_PASS "+label);
      }

      private function releaseConfig(gd:Class):void
      {
         var heroes:Object=gd["$mConfig_avatar"],skills:Object=gd["$mConfig_skill"];
         requireRelease(heroes.A_1208_6.role=="双抗坦克","nurse tank role");
         requireRelease(heroes.A_1208_6.pl[4]==heroes.A_1208_6.pl[6],"nurse balanced defenses");
         var goku:Object=skills.S_201311_6;
         requireRelease(goku.skill[2][2]==4500 && goku.skill[5][0]=="caster_hp_heal" && goku.skill[5][1]==0.12,"goku level-one values");
         requireRelease(skills.S_301311_6.skill[1][2]==1500,"goku 1500 knockback");
         var morde:Object=skills[heroes.A_1137_6.pl[10]];
         requireRelease(Math.abs(Number(morde.skill[6][1])-3.276)<0.00001 && morde.skill[4][2]==6300,"morde doubled normal");
         requireRelease(skills[heroes.A_1137_6.pl[11]].skill[2][1]==1,"morde exact 100% defense");
         log("RELEASE_CONFIG_READY");
      }

      private function releaseTick(gd:Class,root:Object):void
      {
         if(getTimer()-phaseTime<1800) return;
         var button:Object;
         var cls:Class;
         if(phase==20)
         {
            snapshot("release-main",gd);
            root["mLayoutUICenter"].showPanel("center_social_main_avatar"); advance(21);
         }
         else if(phase==21)
         {
            requireRelease(find(gd["$mStarling"].stage,"PanelSocialMainAvatar")!=null,"hero bag opens");
            snapshot("release-hero-bag",gd);
            root["mLayoutUICenter"].showPanel("center_main"); advance(22);
         }
         else if(phase==22)
         {
            button=find(gd["$mStarling"].stage,"阵容预设",true);
            if(button==null) {snapshot("release-entry-missing",gd);log("RELEASE_PANEL "+root["mLayoutUICenter"].mCurrPanel+" main="+(find(gd["$mStarling"].stage,"PanelCenterMain")!=null));}
            requireRelease(button!=null,"preset entry visible");
            button.dispatchEventWith("triggered",true); advance(23);
         }
         else if(phase==23)
         {
            snapshot("release-presets",gd);
            button=find(gd["$mStarling"].stage,"保存当前",true);
            requireRelease(button!=null,"four-slot preset controls");
            button.dispatchEventWith("triggered",true); advance(24);
         }
         else if(phase==24)
         {
            var presets:Object=gd["$userData"].attrs.team_presets;
            requireRelease(presets!=null && presets[0]!=null,"preset save receipt");
            requireRelease(presets[0].preview.length==5,"five-hero preset preview");
            snapshot("release-presets-saved",gd);
            button=find(gd["$mStarling"].stage,"覆盖保存",true);button.dispatchEventWith("triggered",true);advance(73);
         }
         else if(phase==80)
         {
            find(gd["$mStarling"].stage,"阵容预设",true).dispatchEventWith("triggered",true);advance(81);
         }
         else if(phase==81)
         {
            snapshot("release-presets-final",gd);
            button=find(gd["$mStarling"].stage,"关闭",true);
            requireRelease(button!=null && String(button.name)=="team-preset-close","preset close control is present");
            var bounds:Object=button.getBounds(gd["$mStarling"].stage);
            var center:Point=new Point(bounds.x+bounds.width/2,bounds.y+bounds.height/2);
            var hit:Object=gd["$mStarling"].stage.hitTest(center,true);
            while(hit!=null && hit!=button) hit=hit.parent;
            requireRelease(hit==button,"preset close control receives touches");
            if(settings.presetCloseTouch)
            {
               var viewport:Object=gd["$mStarling"].viewPort;
               log("PRESET_CLOSE_TAP "+int(viewport.x+center.x*viewport.width/gd["$mStarling"].stage.stageWidth)+" "+int(viewport.y+center.y*viewport.height/gd["$mStarling"].stage.stageHeight));
               advance(83);return;
            }
            button.dispatchEventWith("triggered",true);
            requireRelease(!root.isPopUp_Open(),"preset close returns to main screen");
            cls=definition("com.meng52.game.ui.screen.PanelCenterActivity");
            cls["$activityFunObj"]=definition("com.meng52.game.global.GlobalFunction")["getActivityFun"]("task");
            root["mLayoutUICenter"].showPanel("center_activity");advance(82);
         }
         else if(phase==83)
         {
            if(root.isPopUp_Open()) return;
            requireRelease(true,"preset closes from real device touch");
            find(gd["$mStarling"].stage,"阵容预设",true).dispatchEventWith("triggered",true);advance(84);
         }
         else if(phase==84)
         {
            requireRelease(root.isPopUp_Open(),"preset can reopen after close");
            snapshot("release-presets-reopened",gd);root.closePopUp();
            cls=definition("com.meng52.game.ui.screen.PanelCenterActivity");
            cls["$activityFunObj"]=definition("com.meng52.game.global.GlobalFunction")["getActivityFun"]("task");
            root["mLayoutUICenter"].showPanel("center_activity");advance(82);
         }
         else if(phase==82)
         {
            snapshot("release-adventure-final",gd);log("PROBE_FINISHED release103");timer.stop();NativeApplication.nativeApplication.exit(0);
         }
         else if(phase==73)
         {
            requireRelease(find(gd["$mStarling"].stage,"确认覆盖",true)!=null,"overwrite requires second confirmation");
            snapshot("release-preset-overwrite-confirm",gd);
            find(gd["$mStarling"].stage,"取消",true).dispatchEventWith("triggered",true);
            requireRelease(find(gd["$mStarling"].stage,"确认覆盖",true)==null,"overwrite can be canceled");
            find(gd["$mStarling"].stage,"覆盖保存",true).dispatchEventWith("triggered",true);advance(74);
         }
         else if(phase==74)
         {
            find(gd["$mStarling"].stage,"确认覆盖",true).dispatchEventWith("triggered",true);advance(75);
         }
         else if(phase==75)
         {
            if(find(gd["$mStarling"].stage,"阵容1已保存。",true)==null) return;
            requireRelease(true,"confirmed overwrite receives save receipt");
            find(gd["$mStarling"].stage,"清空",true).dispatchEventWith("triggered",true);advance(76);
         }
         else if(phase==76)
         {
            requireRelease(find(gd["$mStarling"].stage,"确认清空",true)!=null,"clear requires second confirmation");
            snapshot("release-preset-clear-confirm",gd);
            find(gd["$mStarling"].stage,"取消",true).dispatchEventWith("triggered",true);
            requireRelease(gd["$userData"].attrs.team_presets[0]!=null,"cancel clear retains preset");
            find(gd["$mStarling"].stage,"清空",true).dispatchEventWith("triggered",true);advance(77);
         }
         else if(phase==77)
         {
            find(gd["$mStarling"].stage,"确认清空",true).dispatchEventWith("triggered",true);advance(78);
         }
         else if(phase==78)
         {
            if(gd["$userData"].attrs.team_presets[0]!=null) return;
            requireRelease(true,"confirmed clear removes only preset");
            find(gd["$mStarling"].stage,"保存当前",true).dispatchEventWith("triggered",true);advance(79);
         }
         else if(phase==79)
         {
            if(gd["$userData"].attrs.team_presets[0]==null) return;
            requireRelease(gd["$userData"].attrs.team_presets[0].preview.length==5,"preset can be saved again after clear");
            snapshot("release-presets-restored",gd);root.closePopUp();
            cls=definition("com.meng52.game.ui.screen.PanelCenterActivity");
            cls["$activityFunObj"]=definition("com.meng52.game.global.GlobalFunction")["getActivityFun"]("task");
            root["mLayoutUICenter"].showPanel("center_activity"); advance(25);
         }
         else if(phase==25)
         {
            requireRelease(find(gd["$mStarling"].stage,"PanelCenterTaskAward")!=null,"adventure view opens");
            snapshot("release-adventure",gd);
            root["mLayoutUICenter"].showPanel("center_main");
            gd["$tempEquipCurrSelected"]=settings.magicEquipment;
            cls=definition("com.meng52.game.ui.panel.PanelEquipMagic");
            root["mLayoutUICenter"].showPanel("equip_fun_magic",false,true);panel=find(gd["$mStarling"].stage,"PanelEquipMagic");advance(26);
         }
         else if(phase==26)
         {
            requireRelease(find(gd["$mStarling"].stage,"PanelEquipMagic")!=null,"equipment magic opens");
            snapshot("release-magic",gd);
            button=find(gd["$mStarling"].stage,"粉尘强化10次",true);
            requireRelease(button!=null && button.enabled,"batch magic control available");
            button.dispatchEventWith("triggered",true);advance(60);
         }
         else if(phase==60)
         {
            snapshot("release-magic-confirm",gd);
            var confirm:String=definition("com.meng52.game.global.GlobalLanguageStr")["getLanguageStr"](20021);
            button=find(gd["$mStarling"].stage,confirm,true);
            requireRelease(button!=null,"batch magic confirmation");button.dispatchEventWith("triggered",true);advance(61);
         }
         else if(phase==61)
         {
            if(int(gd["$userData"].my_equips[settings.magicEquipment].magic[0])==0) return;
            requireRelease(int(gd["$userData"].my_equips[settings.magicEquipment].magic[0])==10,"real ten-step magic receipt");
            snapshot("release-magic-upgraded",gd);panel.onTRIGGERED_closePanel(null);advance(65);
         }
         else if(phase==65)
         {
            gd["$tempEquipCurrSelected"]=settings.bookEquipment;
            gd["$tempFoodForBook"]=[];gd["$tempObjectFoodForBook"]={};
            root["mLayoutUICenter"].showPanel("equip_fun_book",false,true);panel=find(gd["$mStarling"].stage,"PanelEquipBook");advance(62);
         }
         else if(phase==62)
         {
            requireRelease(find(gd["$mStarling"].stage,"PanelEquipBook")!=null,"skill book view opens");
            releaseBookMaterials(gd,"e-qa-material-",5);advance(63);
         }
         else if(phase==63)
         {
            if(gd["$userData"].my_equips["e-qa-material-0"]!=null) return;
            requireRelease(int(gd["$userData"].my_equips[settings.bookEquipment].slv)==2,"first book upgrade receipt");
            releaseBookMaterials(gd,"e-qa-green-",4);advance(64);
         }
         else if(phase==64)
         {
            if(gd["$userData"].my_equips["e-qa-green-0"]!=null) return;
            requireRelease(int(gd["$userData"].my_equips[settings.bookEquipment].slv)==3,"second book upgrade without relogin");advance(27);
         }
         else if(phase==27)
         {
            requireRelease(find(gd["$mStarling"].stage,"PanelEquipBook")!=null,"skill book view opens");
            snapshot("release-books",gd);panel.onTRIGGERED_closePanel(null);
            releasePrepareBattle(gd,root);
         }
         else if(phase==66)
         {
            releasePrepareBattle(gd,root);
         }
         else if(phase==28 && getTimer()-phaseTime>releaseWait)
         {
            map.initMap(true,releasePrepared);map.sendFight();log("RELEASE_FIGHT_SENT");advance(29);
         }
         else if(phase==29 && map.re!=null)
         {
            snapshot("release-battle",gd);advance(30);
         }
         else if(phase==30)
         {
            if(map.settlementSent && !map.settlementPending && map.winner>0)
            {
               snapshot("release-battle-finished",gd);
               log("RELEASE_BATTLE_FINISHED winner="+map.winner+" round="+map.roundNum);
               root.closePopUp();map.clear();root["mLayoutUICenter"].showPanel("center_main");
               cls=definition("com.meng52.game.ui.panel.PanelHelpNotice");
               root.openPopUp(new cls(definition("MainConfig")["SERVER_ADDRESS_NOTICE"],"公告"));advance(70);
            }
         }
         else if(phase==70 && getTimer()-phaseTime>12000)
         {
            requireRelease(find(gd["$mStarling"].stage,"PanelHelpNotice")!=null,"native announcement opens");
            snapshot("release-announcement",gd);root.closePopUp();
            cls=definition("com.meng52.game.ui.screen.PanelLogin");panel=new cls(2);
            panel.mPop_currID=root.openPopForPanel(panel);advance(71);
         }
         else if(phase==71)
         {
            button=find(panel,"有钱程度：",true,0,true);
            requireRelease(button!=null,"registration funding selector");button.dispatchEventWith("triggered",true);advance(72);
         }
         else if(phase==72 && getTimer()-phaseTime>12000)
         {
            snapshot("release-registration-menu",gd);panel.onTRIGGERED_closePanel(null);
            log("PROBE_FINISHED release103");timer.stop();NativeApplication.nativeApplication.exit(0);
         }
      }

      private function releasePrepareBattle(gd:Class,root:Object):void
      {
            var cls:Class=definition("com.meng52.game.ui.map.GameMapLayer");
            cls["fpsLv"]=cls["FPS_LIST"].length-1;
            var layer:Object=cls["gl"];if(layer.mapStage.parent==null) root.addChild(layer.mapStage);
            gd["$isNoFriendToPVE"]=true;gd["$tempPVE_combatID"]="M_001_1";gd["$tempPVE_type"]="status_pve_normal";
            definition("com.meng52.game.ui.stage.GuideTools")["doPreStory"]("M_001_1");
            cls=definition("com.meng52.game.module.map.GameMap");cls["isLoad"]=cls["isLoadFile"]=false;
            map=new cls("M_001_1",0);releasePrepared=[];map.myList=[];map.team1Offset=[];
            var selected:Array=gd["$userData"].team[0];
            for(var i:int=0;i<selected.length;i++)
            {
               if(!selected[i] || releasePrepared.length>=5) continue;
               releasePrepared.push({data:{id:selected[i],indexID_s:i}});
               map.myList.push([selected[i],(releasePrepared.length-1)%map.getLaneCount(),0.35]);map.team1Offset.push(0);
            }
            map.initMap(true,releasePrepared);log("RELEASE_MAP_UNITS own="+map.team1List.length+" enemy="+map.team2List.length);
            releaseCombat(gd);
            releaseWait=Math.min(60000,Math.max(4000,Number(cls["actionDelay"])*1000+2000));
            advance(28);
      }

      private function releaseBookMaterials(gd:Class,prefix:String,count:int):void
      {
         gd["$tempFoodForBook"]=[];gd["$tempObjectFoodForBook"]={};
         for(var i:int=0;i<count;i++) gd["$tempFoodForBook"].push(prefix+i);
         gd["$mEventDispatcher"].dispatchEventWith("update_book_selected_data");
         var label:String=definition("com.meng52.game.global.GlobalLanguageStr")["getLanguageStr"](20406);
         var button:Object=find(panel,label,true);
         requireRelease(button!=null && button.enabled,"book upgrade control ready");
         button.dispatchEventWith("triggered",true);
      }

      private function releaseCombat(gd:Class):void
      {
         var Avatar:Class=definition("com.meng52.game.module.avatar.Avatar");
         var Skill:Class=definition("com.meng52.game.module.skill.SkillSet");
         var effects:Class=definition("com.meng52.game.ui.effect.DisplayTools");
         var unit:Object,nurse:Object,goku:Object,santa:Object,morde:Object;
         for each(unit in map.team1List)
         {
            unit.resetBuff();unit.abilityState={};unit.skill2=null;unit.talent=null;
            unit.hpMax=10000;unit.hp=5000;unit.ap=1000;unit.hit=1000000;unit.flee=unit.crit=unit.tough=0;
            switch(String(unit.avatarData.id))
            {
               case "A_1208_6":nurse=unit;break;
               case "A_1311_6":goku=unit;break;
               case "A_1217_6":santa=unit;break;
               case "A_1137_6":morde=unit;break;
            }
         }
         requireRelease(nurse!=null && goku!=null && santa!=null && morde!=null,"four designed heroes in real map");
         for each(unit in map.team2List)
         {
            unit.resetBuff();unit.abilityState={};unit.skill2=null;unit.skillB=null;unit.talent=null;
            unit.hpMax=10000000;unit.hp=10000000;unit.ap=100;unit.dePh=unit.deMa=1000000;unit.tough=unit.flee=unit.crit=0;
         }
         var enemy:Object=map.team2List[0];
         nurse.skill0.useSkill();
         requireRelease(nurse.hp==6400,"nurse level10 AP-only heal");
         requireRelease(enemy.hp==9999440,"nurse heal produces fixed true damage through armor");
         for each(unit in map.team1List) unit.hp=10000;
         nurse.hp=6000;
         var before:int=enemy.hp;
         var captain:Object=new Skill("S_371208_6",nurse,1,true);captain.useSkill();
         requireRelease(nurse.hp==10000 && enemy.hp==before-7600,"nurse captain double self heal and overheal");
         requireRelease(nurse.buffs.bless!=null && nurse.buffs.bless.value==0,"nurse permanent blessing");
         before=enemy.hp;nurse.resetBuff();nurse.addBuff("burn",3,1);
         requireRelease(nurse.buffs.burn!=null,"burn is present for healing reduction check");
         nurse.injured(1000,1,effects["getAttrs"]("FX60_HEAL"),4,nurse,false,nurse);
         requireRelease(enemy.hp==before-600,"nurse overheal after burn reduction");nurse.resetBuff();
         for each(unit in map.team1List) unit.hp=10000;
         for(var level:int=1;level<=10;level+=9)
         {
            goku.hp=1000;goku.ap=level==1?1:999999;
            var heal:Object=new Skill("S_201311_6",goku,level,false);heal.useSkill();
            requireRelease(goku.hp==(level==1?2200:2800),"goku max-HP-only heal level "+level);
         }
         requireRelease(morde.skill0.skills[4][2]==12600 && Math.abs(Number(morde.skill0.skills[6][1])-6.552)<0.00001,"morde max rank values");
         santa.abilityState={};santa.line=0;
         for each(unit in map.team2List) {unit.hp=1;unit.line=0;}
         santa.skill0.useSkill();
         requireRelease(int(santa.abilityState.santaKills)==1 && int(santa.abilityState.santaStacks)==3,"santa first cast locks one resolution");
         for each(unit in map.team2List) if(unit.hp>0) unit.hp=10000000;
         santa.skill0.useSkill();
         requireRelease(int(santa.abilityState.santaKills)==1 && int(santa.abilityState.santaStacks)==5,"santa next cast permanently gains second resolution");
         log("RELEASE_COMBAT_READY");
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
            if(String(settings.mode).indexOf("release103") == 0 && phase >= 20) { releaseTick(gd,root); return; }
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
               if(String(settings.mode).indexOf("release103") == 0)
               {
                  root.closePopUp(); gd["$currentGuide"] = null;
                  definition("com.meng52.game.module.guide.GuideMaster")["getOnlyExample"]().skipGuide();
                  releaseConfig(gd);
                  root["mLayoutUICenter"].showPanel("center_main");
                  advance(settings.mode=="release103combat"?66:settings.mode=="release103preview"?80:20); return;
               }
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
            try {if(String(settings.mode).indexOf("release103")==0) snapshot("release-error-"+phase,definition("com.meng52.game.global.GlobalData"));} catch(captureFailure:Error) {}
            NativeApplication.nativeApplication.exit(1);
         }
      }
   }
}
