package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_IconText;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelBase;
   import com.meng52.game.ui.screen.PanelCenterPVE;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import starling.core.Starling;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   
   public class PanelActivityExploration extends PanelBase
   {
      
      private const _BTN_IN:String = "mbtn_in";
      
      private const GAMERULE:String = "gamerule";
      
      private var mBg:Image;
      
      private var mBtn_In:LOL_Scale9Button;
      
      
      private var mInfo_bg:Scale9Image;
      
      private var mSchedule_spr:LOL_IconText;
      
      private var mFresh_num:TextField;
      
      private var gamerule:LOL_Button;
      
      private var serverBack:Object;
      private var resumeExploration:Boolean = false;
      
      private var _spRule:Sprite;
      
      public function PanelActivityExploration()
      {
         super();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalFunction.delTextureByBD("UI_exploration");
         mBg = null;
         if(mInfo_bg)
         {
            mInfo_bg.dispose();
            mInfo_bg.removeFromParent(true);
         }
         mInfo_bg = null;
         if(mSchedule_spr)
         {
            mSchedule_spr.dispose();
            mSchedule_spr.removeFromParent(true);
         }
         mSchedule_spr = null;
         if(mFresh_num)
         {
            mFresh_num.dispose();
            mFresh_num.removeFromParent(true);
         }
         if(_spRule)
         {
            _spRule.removeEventListener("touch",onPith);
            _spRule.removeFromParent(true);
            _spRule = null;
         }
         mFresh_num = null;
         GlobalData.$mEventDispatcher.removeEventListener("update_exploration_fresh_count",freshCountFun);
         GlobalData.$mEventDispatcher.removeEventListener("update_exploration_fresh_stage",freshCountFun);
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         removeEventListener("addedToStage",initializeHandler);
         GlobalData.$mEventDispatcher.addEventListener("update_exploration_fresh_count",freshCountFun);
         GlobalData.$mEventDispatcher.addEventListener("update_exploration_fresh_stage",freshCountFun);
         setUIs();
      }
      
      private function freshCountFun(param1:Event) : void
      {
         var _loc3_:String = null;
         var _loc4_:String = null;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc2_:int = 0;
         if(param1.data.refresh_count != null)
         {
            _loc3_ = param1.data.refresh_count;
            _loc4_ = GlobalLanguageStr.getLanguageStr(90560,_loc3_);
            mFresh_num.text = _loc4_;
         }
         if(param1.data.stage != null)
         {
            _loc5_ = int(param1.data.stage);
            _loc6_ = int(GlobalData.$mConfig_simple.explore.map_max);
            _loc2_ = _loc5_ <= _loc6_ ? _loc5_ : _loc6_;
            _loc4_ = GlobalLanguageStr.getLanguageStr(90566,_loc2_);
            mSchedule_spr.text = _loc4_;
         }
      }
      
      private function setUIs() : void
      {
         var o:Object;
         var _stage:int;
         var _map_max:int;
         var _battle_id:int;
         var _num:String;
         var num_info:String;
         var fun:*;
         mBg = GlobalFunction.createImage("UI_exploration",true);
         mBg.y = GlobalData.$center_height_curr - 121 - mBg.height + 10;
         addChild(mBg);
         o = GlobalFunction.get_HelpLink(GlobalLanguageStr.getLanguageStr(90649));
         _spRule = o.ui;
         _spRule.x = GlobalData.$mStageWidth - o.w - 20;
         _spRule.y = 140;
         addChild(_spRule);
         _spRule.addEventListener("touch",onPith);
         mBtn_In = new LOL_Scale9Button(GlobalLanguageStr.getStr(90549),150,70,"UI_btn_normalFun_0000");
         mBtn_In.name = "mbtn_in";
         mBtn_In.x = (GlobalData.$mStageWidth - mBtn_In.width) * 0.5;
         mBtn_In.y = mBg.y + mBg.height - 200;
         mBtn_In.addEventListener("triggered",onTRIGGERED_btn);
         addChild(mBtn_In);
         mInfo_bg = GlobalFunction.createScale9Image("UI_bg_9slice_5_0000",618,100,new Rectangle(40,30,30,30));
         mInfo_bg.x = mBg.x + (mBg.width - mInfo_bg.width) * 0.5;
         mInfo_bg.y = mBg.y + mBg.height - mInfo_bg.height - 10;
         this.addChild(mInfo_bg);
         _stage = int(GlobalData.$userData.exploration.stage);
         _map_max = int(GlobalData.$mConfig_simple.explore.map_max);
         _battle_id = _stage <= _map_max ? _stage : _map_max;
         mSchedule_spr = new LOL_IconText(GlobalLanguageStr.getLanguageStr(90566,_battle_id));
         mSchedule_spr.fontSize = MainConfig.$isEnglish ? 18 : 20;
         mSchedule_spr.x = MainConfig.$isEnglish ? mInfo_bg.x + 10 : mInfo_bg.x + 40;
         mSchedule_spr.y = mInfo_bg.y + (mInfo_bg.height - mSchedule_spr.height) * 0.5;
         mSchedule_spr.bgVisible = false;
         this.addChild(mSchedule_spr);
         _num = GlobalData.$userData.records.exploration_times.refresh_count;
         num_info = GlobalLanguageStr.getLanguageStr(90560,_num);
         mFresh_num = GlobalFunction.createTextField(400,30,num_info,"",MainConfig.$isEnglish ? 18 : 20,16777215);
         mFresh_num.x = mInfo_bg.x + MainConfig.$isEnglish ? mInfo_bg.width * 0.5 - 50 : mInfo_bg.width * 0.5;
         mFresh_num.y = mSchedule_spr.y;
         this.addChild(mFresh_num);
         if(GlobalData.backFromExploration)
         {
            fun = function():void
            {
               onTRIGGERED_btn(null);
               GlobalData.backFromExploration = false;
            };
            Starling.juggler.delayCall(fun,0.1);
         }
         else if(GlobalData.$abyss104 && GlobalData.$abyss104.resume)
         {
            // The Abyss now lives in 副本 (center_pve, 4th tab); that tab resumes the run.
            PanelCenterPVE.$abyssTab104 = true;
            Starling.juggler.delayCall(function():void
            {
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pve");
            },0.1);
         }
      }
      
      // 副本 · 深渊回廊 tab page (entry: difficulty, deck, codex, start/continue).
      public static function createAbyssTab104(param1:Rectangle) : Sprite
      {
         return AbyssCore104.createEntryTab(param1);
      }

      // Rebuilds the run screens after an Abyss battle; called by the 副本 tab.
      public static function resumeAbyss104() : void
      {
         AbyssCore104.resumeAfterBattle();
      }

      // Equipment management (PanelEquipBase) tab content listing every relic.
      public static function createRelicManageView104(param1:Number) : Sprite
      {
         return new AbyssRelicManageView104(param1);
      }

      // Called from the hero detail panel for the 7th (relic) slot of a team position.
      public static function openRelicSlot104(param1:int) : void
      {
         AbyssCore104.openRelicSlot(param1);
      }


      // Alchemy institute tab content: reroll one relic substat.
      public static function createRerollView104(param1:Number) : Sprite
      {
         return new AbyssRerollView104(param1);
      }

      // Native-framed 7th equipment slot for the hero detail panel.
      public static function createRelicSlotView104(param1:int) : Sprite
      {
         return AbyssRelicSlotView104.create(param1);
      }

      private function onTRIGGERED_btn(param1:Event) : void
      {
         GlobalData.$abyss104 = null;
         resumeExploration=param1==null && GlobalData.backFromExploration;
         SendServiceAMFFun.send_user_exploration_start(backFun);
      }
      
      protected function onPith(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(_spRule,"ended");
         if(_loc2_)
         {
            GlobalFunction.popPanelHelp(MainConfig.SERVER_ADDRESS_HELP_EXPLORATION);
         }
      }
      
      private function backFun(param1:Object) : void
      {
         var _loc6_:Object = null;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc2_:int = 0;
         var _armyMax:int = 15;
         var _armyCount:int = 0;
         if(param1.data && GlobalFunction.isVersionedProfileReceipt(param1) && this.stage)
         {
            if(!GlobalData.isCurrentProfileSyncEnvelope(param1.state_sync))
            {
               LayoutUIAnimation.getOnlyExample().popWords("探索状态已更新，请重新确认队伍。");
               return;
            }
            GlobalData.$exploration_data = null;
            GlobalData.$exploration_data = param1.data;
            GlobalData.$exploration_select_avatar = null;
            _loc6_ = Tools.clone(param1.data.army);
            for(var _loc5_:String in _loc6_)
            {
               _loc6_[_loc5_]["id"] = _loc5_;
            }
            GlobalData.$exploration_select_avatar = _loc6_;
            _loc3_ = int(GlobalData.$userData.exploration.stage);
            _loc4_ = int(GlobalData.$mConfig_simple.explore.map_max);
            _loc2_ = _loc3_ <= _loc4_ ? _loc3_ : _loc4_;
            mSchedule_spr.text = GlobalLanguageStr.getLanguageStr(90566,_loc2_);
            // A deliberate entry always confirms the up-to-15 hero roster.
            // Returning from a settled battle resumes the map/reward directly.
            _armyCount=Tools.getElementNum(GlobalData.$userData.exploration.army);
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel(resumeExploration && _armyCount>0 ? "exploration_select_game" : "exploration_select",false,true);
         }
      }
   }
}
// BEGIN ABYSS_UI_104
// Abyss Corridor (深渊回廊) client screens.
// Appended after the package block of PanelActivityExploration by
// scripts/sync_abyss_client_104.py. FFDec cannot add new top-level classes, so
// every screen is a file-private class here; other files reach it through the
// static entry points on PanelActivityExploration.
import com.meng52.game.global.GlobalData;
import com.meng52.game.global.GlobalFunction;
import com.meng52.game.module.avatar.Avatar;
import com.meng52.game.module.equip.Equip;
import com.meng52.game.module.skill.SkillSet;
import com.meng52.game.ui.element.ItemEquip;
import com.meng52.game.ui.element.LOL_Scale9Button;
import com.meng52.game.ui.screen.PanelBase;
import com.meng52.game.ui.stage.LayoutUIAnimation;
import com.meng52.net.SendAndSelect;
import com.meng52.utils.Tools;
import feathers.controls.ScrollContainer;
import feathers.layout.VerticalLayout;
import flash.geom.Rectangle;
import flash.display.BitmapData;
import flash.utils.ByteArray;
import flash.utils.getTimer;
import starling.animation.Tween;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.display.Image;
import starling.display.Quad;
import starling.display.Sprite;
import starling.events.Event;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.text.TextField;
import starling.textures.Texture;

class AbyssCore104
{
   // closePopForPanel(-1) tweens for 0.1s before removing every pop; reopen after it.
   public static const REOPEN_DELAY:Number = 0.3;

   public static const DECK_ORDER:Array = ["blade","flame","venom","summon","star"];

   public static const COLOR_TITLE:uint = 0xFFCC66;
   public static const COLOR_TEXT:uint = 0xFFFFFF;
   public static const COLOR_DIM:uint = 0x9A9A9A;
   public static const COLOR_RED:uint = 0xFF4A3D;
   public static const COLOR_GREEN:uint = 0x66DD66;
   public static const COLOR_PURPLE:uint = 0xCC77FF;
   public static const COLOR_ORANGE:uint = 0xFF9933;
   // Ancient affixes use blue, distinct from normal and orange-quality text.
   public static const COLOR_ANCIENT:uint = 0x4CA6FF;
   public static const COLOR_SELECT:uint = 0x33AAFF;
   // Text on the tan UI_bg_9slice_4 box, same values the native equipment lists use.
   public static const INK_NAME:uint = 0x990000;
   public static const INK_TEXT:uint = 0x4B2C1B;
   public static const INK_ANCIENT:uint = 0x1663B8;
   public static const INK_GREEN:uint = 0x1A6F1A;
   // Selection mark: warm gold with a dark outline, the palette of native leader/VIP tags.
   public static const MARK_GOLD:uint = 0xFFD24A;
   public static const MARK_EDGE:uint = 0x4A2A00;

   // Last successful reply of any user.abyss_* method.
   public static var data:Object = null;
   public static var panels:Array = [];
   // Session snapshots used by the settlement screen to show what this run opened.
   public static var orangeBefore:Array = null;
   public static var decksBefore:Array = null;
   public static var maxBefore:int = 0;
   // Last team sent to battle, used to prefill "调整布阵".
   public static var lastTeam:Array = null;
   private static var busyUntil:int = 0;

   public static function get run() : Object
   {
      return data ? data.abyss_run : null;
   }

   public static function get account() : Object
   {
      return data && data.abyss_account ? data.abyss_account : {"max_difficulty":1,"decks":["blade","flame"],"cleared":[],"appeared":[]};
   }

   public static function get unlocked() : Object
   {
      return data && data.unlocked ? data.unlocked : {"purple":[],"orange":[],"standalone_orange":[]};
   }

   public static function get relics() : Object
   {
      return data && data.abyss_relics ? data.abyss_relics : (GlobalData.$userData && GlobalData.$userData.abyss_relics ? GlobalData.$userData.abyss_relics : {});
   }

   public static function cfg() : Object
   {
      var simple:Object = GlobalData.$mConfig_simple;
      return simple && simple.roguelite_abyss ? simple.roguelite_abyss : {};
   }

   public static function isSkin(aid:String) : Boolean
   {
      var families:Array = cfg().skin_families as Array;
      return families && families.indexOf(family(aid)) >= 0;
   }

   public static function retriesTotal(difficulty:int) : int
   {
      var rows:Array = cfg().difficulties as Array;
      // Config is the only source of these numbers (calibrated server-side); never hard-code.
      if(rows && difficulty >= 1 && difficulty <= rows.length) return int(rows[difficulty - 1].retries);
      return -1;
   }

   public static function enemyMultiplier(difficulty:int) : Number
   {
      var rows:Array = cfg().difficulties as Array;
      if(rows && difficulty >= 1 && difficulty <= rows.length) return Number(rows[difficulty - 1].multiplier);
      return NaN;
   }

   // Same formula as the server: act base rate scaled linearly to double at difficulty 10.
   public static function bossRate(difficulty:int, act:int) : Number
   {
      var base:Number = [0.2,0.3,0.5][act - 1];
      return Math.min(1,base * (1 + (difficulty - 1) / 9));
   }

   public static function retriesText(difficulty:int) : String
   {
      var total:int = retriesTotal(difficulty);
      return total < 0 ? "—" : String(total);
   }

   public static function percent(value:Number) : String
   {
      return (Math.round(value * 10000) / 100).toFixed(2) + "%";
   }

   public static function deckInfo(key:String) : Object
   {
      var decks:Object = cfg().decks;
      if(decks && decks[key]) return decks[key];
      var fallback:Object = {
         "blade":{"clear_required":0,"members":["A_1001_5","A_1007_5","A_1004_5","A_1009_5","A_1012_5"]},
         "flame":{"clear_required":0,"members":["A_1013_5","A_1020_5","A_1006_5","A_1003_5","A_1016_5"]},
         "venom":{"clear_required":1,"members":["A_1018_5","A_1077_5","A_1045_5","A_1063_5","A_1082_5"]},
         "summon":{"clear_required":3,"members":["A_1049_5","A_1085_5","A_1094_5","A_1014_5","A_1040_5"]},
         "star":{"clear_required":5,"members":[]}
      };
      return fallback[key];
   }

   public static function deckName(key:String) : String
   {
      var info:Object = deckInfo(key);
      var fallback:Object = {"blade":"锋刃","flame":"炎咒","venom":"蚀骨","summon":"群策","star":"星裔"};
      return info && info.name ? String(info.name) : (fallback[key] ? fallback[key] : key);
   }

   // Pool bonds under the pool rule: a bond counts once every member family is in
   // the pool at one quality (purple set or orange set), as bonds_104.active_bonds.
   public static function poolBonds() : Array
   {
      var defs:Array = GlobalData.$mConfig_simple ? GlobalData.$mConfig_simple.bonds_104 as Array : null;
      var r:Object = run;
      var aids:Object = {};
      var fams:Object = {};
      if(r && r.pool) for(var id:String in r.pool)
      {
         var aid:String = String(r.pool[id].aid);
         aids[aid] = true;
         fams[family(aid)] = true;
      }
      var result:Array = [];
      for each(var bond:Object in defs)
      {
         var members:Array = bond.families as Array;
         if(!members || !members.length) continue;
         var present:int = 0;
         var missing:Array = [];
         for each(var f:String in members)
         {
            if(fams[f]) present++;
            else missing.push(heroName(f + "_5"));
         }
         if(present == 0) continue;
         var active:Boolean = false;
         for each(var q:String in ["5","6"])
         {
            var all:Boolean = true;
            for each(f in members) if(!aids[f + "_" + q]) { all = false; break; }
            if(all) { active = true; break; }
         }
         result.push({"name":String(bond.name),"active":active,"missing":missing,"mixed":!active && missing.length == 0,"present":present,"total":members.length});
      }
      result.sort(function(a:Object, b:Object):int
      {
         if(a.active != b.active) return a.active ? -1 : 1;
         return a.missing.length - b.missing.length;
      });
      return result;
   }

   public static function family(aid:String) : String
   {
      return aid.split("_").slice(0,2).join("_");
   }

   public static function heroName(aid:String) : String
   {
      var row:Object = GlobalData.$mConfig_avatar ? GlobalData.$mConfig_avatar[aid] : null;
      return row && row.name ? String(row.name) : aid;
   }

   public static function isOrange(aid:String) : Boolean
   {
      return aid.charAt(aid.length - 1) == "6";
   }

   public static function skillBase105(aid:String) : int
   {
      return isSkin(aid) ? (cfg().skin_skill_level ? int(cfg().skin_skill_level) : 3) : 5;
   }

   public static function skillMax105(aid:String) : int
   {
      return isSkin(aid) ? (cfg().skin_skill_level_max ? int(cfg().skin_skill_level_max) : 6) : 10;
   }

   // Display/battle-preview data for a standardized pool hero (no owned progression).
   // limitBreak only switches on the native pulse edge (elite boosted enemy); stats stay 0.
   public static function heroData(aid:String, id:String, slv:int, limitBreak:Boolean = false) : Object
   {
      return {
         "id":id,
         "aid":aid,
         "base_aid":aid,
         "lv":cfg().level ? int(cfg().level) : 99,
         "slv":slv,
         "exp":0,
         "hp":0,
         "ap":0,
         "de_ph":0,
         "de_ma":0,
         "love_exp":0,
         "phase":0,
         "limit_break":limitBreak ? 1 : 0,
         "culture_schema":"",
         "morph":0
      };
   }

   public static function node(id:String) : Object
   {
      var r:Object = run;
      if(!r || !id) return null;
      for each(var n:Object in r.map)
      {
         if(n.id == id) return n;
      }
      return null;
   }

   public static function poolIds() : Array
   {
      var result:Array = [];
      var r:Object = run;
      if(!r || !r.pool) return result;
      for(var id:String in r.pool) result.push(id);
      result.sort(function(a:String, b:String):int
      {
         var qa:int = int(r.pool[a].quality);
         var qb:int = int(r.pool[b].quality);
         if(qa != qb) return qb - qa;
         return a < b ? -1 : (a > b ? 1 : 0);
      });
      return result;
   }

   public static function poolCount() : int
   {
      return poolIds().length;
   }

   public static function poolCap() : int
   {
      return cfg().pool_cap ? int(cfg().pool_cap) : 20;
   }

   public static function toast(text:String) : void
   {
      LayoutUIAnimation.getOnlyExample().popWords(text);
   }

   // Every abyss request goes through here. A failed request is reported by the
   // shared error broadcast and never reaches done().
   public static function send(method:String, params:Object, done:Function = null) : void
   {
      var now:int = getTimer();
      if(now < busyUntil) return;
      busyUntil = now + 5000;
      SendAndSelect.sendAndSelectService(method,params ? params : {},function(re:Object):void
      {
         busyUntil = 0;
         if(!re || !re.data || int(re.return_code) != 0) return;
         applyReply(re.data);
         if(done != null) done(re.data);
         refreshAll();
      });
   }

   public static function applyReply(reply:Object) : void
   {
      if(reply.hasOwnProperty("abyss_run") || reply.hasOwnProperty("abyss_account")) data = reply;
      else if(data) for(var key:String in reply) data[key] = reply[key];
      var profile:Object = GlobalData.$userData;
      if(profile)
      {
         if(reply.abyss_relics) profile.abyss_relics = reply.abyss_relics;
         if(reply.as_equips is Array)
         {
            var slots:Array = [null,null,null,null,null,null];
            var rows:Array = reply.as_equips as Array;
            for(var i:int = 0; i < rows.length && i < 6; i++)
            {
               if(rows[i] is Array && rows[i].length > 6) slots[i] = rows[i][6];
            }
            profile.abyss_relic_slots = slots;
         }
      }
      if(orangeBefore == null && data && data.unlocked)
      {
         orangeBefore = (unlocked.orange as Array).concat();
         decksBefore = (account.decks as Array).concat();
         maxBefore = int(account.max_difficulty);
      }
   }

   public static function refreshAll() : void
   {
      for each(var p:AbyssPanel104 in panels.concat())
      {
         if(p.stage) p.refresh();
      }
   }

   public static function open(p:AbyssPanel104) : AbyssPanel104
   {
      p.mPop_currID = GlobalData.$mGameClassObject.openPopForPanel(p);
      return p;
   }

   public static function closeTop() : void
   {
      GlobalData.$mGameClassObject.closePopForPanel(0);
   }

   public static function closeAll() : void
   {
      GlobalData.$mGameClassObject.closePopForPanel(-1);
   }

   public static function query(done:Function) : void
   {
      send("user.abyss_query",{},done);
   }

   // ---------- navigation ----------

   public static function embeddedEntry() : AbyssPanel104
   {
      for each(var p:AbyssPanel104 in panels) if(p.embed && p.stage) return p;
      return null;
   }

   // The entry page lives in the 副本 screen's 深渊回廊 tab; a pop-up entry is only the
   // fallback when that tab is not on screen.
   public static function openEntry() : void
   {
      query(function(d:Object):void
      {
         if(!embeddedEntry()) open(new AbyssEntryPanel104());
      });
   }

   public static function createEntryTab(area:Rectangle) : Sprite
   {
      var p:AbyssEntryPanel104 = new AbyssEntryPanel104();
      p.embed = area;
      query(function(d:Object):void
      {
         p.resetChoice();
         p.refresh();
         // This reply already refreshed the run. Resume only after it arrives,
         // so the shared request guard cannot discard a second timed query.
         if(GlobalData.$abyss104 && GlobalData.$abyss104.resume) resumeAfterBattle(true);
      });
      return p;
   }

   public static function startRun(difficulty:int, deck:String) : void
   {
      orangeBefore = (unlocked.orange as Array).concat();
      decksBefore = (account.decks as Array).concat();
      maxBefore = int(account.max_difficulty);
      lastTeam = null;
      send("user.abyss_start",{"difficulty":difficulty,"deck":deck},function(d:Object):void
      {
         continueRun();
      });
   }

   public static function continueRun() : void
   {
      closeAll();
      Starling.juggler.delayCall(function():void
      {
         open(new AbyssMapPanel104());
         openNodeStep();
      },AbyssCore104.REOPEN_DELAY);
   }

   // Opens whatever the run currently waits for on top of the map.
   public static function openNodeStep() : void
   {
      var r:Object = run;
      if(!r) return;
      if(r.status != "active")
      {
         open(new AbyssResultPanel104());
         return;
      }
      if(r.pending_choice)
      {
         open(new AbyssChoicePanel104());
         return;
      }
      var n:Object = node(r.current_node);
      if(n && !n.completed)
      {
         if(n.type == "rest") open(new AbyssRestPanel104());
         else open(new AbyssTeamPanel104());
      }
   }

   public static function route(nodeId:String) : void
   {
      send("user.abyss_route",{"node_id":nodeId},function(d:Object):void
      {
         openNodeStep();
      });
   }

   public static function startBattle(slots:Array, pending:Object) : void
   {
      var r:Object = run;
      if(!pending)
      {
         var current:Object = node(r.current_node);
         var skinCount:int = 0;
         for each(var selected:* in slots) if(selected && r.pool[selected] && isSkin(String(r.pool[selected].aid))) skinCount++;
         if(skinCount > (current ? int(current.act) : 1))
         {
            toast("已超过本幕皮肤英雄上阵上限，请先调整阵容");
            return;
         }
      }
      var heroes:Object = {};
      for(var id:String in r.pool)
      {
         heroes[id] = heroData(String(r.pool[id].aid),id,int(r.pool[id].slv));
      }
      lastTeam = slots.concat();
      GlobalData.$abyss104 = {"heroes":heroes,"node_id":r.current_node,"pending":pending,"finish":null,"resume":false};
      GlobalData.$exploration_team_avtId_arr = slots.concat();
      GlobalData.$exploration_team_avatar = [];
      GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_exploration_battle",false,true);
   }

   // Called by PanelActivityExploration after the battle scene returns to the hub.
   public static function resumeAfterBattle(afterQuery:Boolean = false) : void
   {
      var state:Object = GlobalData.$abyss104;
      if(!state || !state.resume) return;
      var finish:Object = state ? state.finish : null;
      var nodeId:String = state ? String(state.node_id) : "";
      var restore:Function = function(d:Object):void
      {
         // Preserve the return context until a successful query can restore it.
         if(GlobalData.$abyss104 == state) GlobalData.$abyss104 = null;
         closeAll();
         Starling.juggler.delayCall(function():void
         {
            open(new AbyssMapPanel104());
            var r:Object = run;
            if(!r) return;
            if(finish && int(finish.sign) == 2)
            {
               if(r.status == "failed") showFinalFailure();
               else showRetry();
               return;
            }
            if(finish && int(finish.sign) == 1)
            {
               var gained:Array = rewardsOf(nodeId);
               if(gained.length > 0)
               {
                  open(new AbyssRewardPanel104(gained));
                  return;
               }
            }
            openNodeStep();
         },AbyssCore104.REOPEN_DELAY);
      };
      if(afterQuery) restore(null);
      else query(restore);
   }

   public static function rewardsOf(nodeId:String) : Array
   {
      var result:Array = [];
      var r:Object = run;
      if(!r || !r.rewards) return result;
      for each(var row:Object in r.rewards)
      {
         if(!nodeId || row.node_id == nodeId) result.push(row);
      }
      return result;
   }

   public static function showRetry() : void
   {
      var r:Object = run;
      var total:int = retriesTotal(int(r.difficulty));
      open(new AbyssConfirmPanel104("战斗失败",[
         "已消耗 1 次重打机会，剩余 " + int(r.retries) + "/" + AbyssCore104.retriesText(int(r.difficulty)) + " 次。",
         "敌人不变，可以调整阵容和站位后再次挑战。",
         int(r.retries) == 0 ? "重打次数已用完：下一场战斗再失败，本局即失败。" : ""
      ],"放弃本局",confirmAbandon,"调整布阵",function():void
      {
         closeTop();
         openNodeStep();
      },true,false));
   }

   public static function showFinalFailure() : void
   {
      open(new AbyssConfirmPanel104("本局失败",[
         "重打次数已用完，本局结束。",
         "已获得的深渊遗物会保留。"
      ],"",null,"查看结算",function():void
      {
         closeTop();
         open(new AbyssResultPanel104());
      },false,false));
   }

   // The single confirmation used by every "放弃本局" entry.
   public static function confirmAbandon() : void
   {
      open(new AbyssConfirmPanel104("放弃本局",[
         "放弃后：",
         "· 本局进度不可恢复；",
         "· 已获得的深渊遗物保留；",
         "· 不发放通关保底；",
         "· 不解锁下一难度。"
      ],"确认放弃",function():void
      {
         send("user.abyss_abandon",{},function(d:Object):void
         {
            closeAll();
            Starling.juggler.delayCall(function():void
            {
               open(new AbyssResultPanel104());
            },AbyssCore104.REOPEN_DELAY);
         });
      },"继续本局",closeTop,true,true));
   }

   public static function backToEntry() : void
   {
      closeAll();
      Starling.juggler.delayCall(openEntry,REOPEN_DELAY);
   }

   // ---------- relics ----------

   public static function relicSlots() : Array
   {
      var profile:Object = GlobalData.$userData;
      return profile && profile.abyss_relic_slots is Array ? profile.abyss_relic_slots as Array : [null,null,null,null,null,null];
   }

   public static function relicSlotOf(itemId:String) : int
   {
      var slots:Array = relicSlots();
      for(var i:int = 0; i < slots.length; i++)
      {
         if(slots[i] == itemId) return i;
      }
      return -1;
   }

   public static function relicName(item:Object) : String
   {
      var prefix:String = "";
      for(var i:int=0;i<relicAncientCount(item);i++) prefix += "*";
      return prefix + String(item.name);
   }

   public static function relicAncientCount(item:Object) : int
   {
      if(!item) return 0;
      var count:int = item.main && item.main.ancient ? 1 : 0;
      var subs:Array = item.substats is Array ? item.substats as Array : [];
      for(var i:int=0;i<Math.min(3,subs.length);i++) if(subs[i] && subs[i].ancient) ++count;
      return count;
   }

   public static function relicFrameQuality(item:Object) : int
   {
      // No ancient affix: blue; then purple, orange, red, rainbow.
      return 4 + relicAncientCount(item);
   }

   public static function positionName(slot:int) : String
   {
      var team:Array = GlobalData.$userData && GlobalData.$userData.team is Array ? GlobalData.$userData.team[0] as Array : null;
      var iid:String = team && slot < team.length ? team[slot] : null;
      var hero:Object = iid && GlobalData.$userData.avatars ? GlobalData.$userData.avatars[iid] : null;
      var name:String = hero && hero.aid ? heroName(String(hero.aid).split("|")[0]) : "空位";
      return (slot + 1) + "号位 · " + name;
   }

   // 7th slot of a team position, same behaviour as the six equipment slots:
   // empty -> chooser list, worn -> detail with 卸下 / 更换.
   public static function openRelicSlot(slot:int) : void
   {
      send("user.abyss_relics",{},function(d:Object):void
      {
         var itemId:* = relicSlots()[slot];
         if(itemId && relics[itemId]) open(new AbyssRelicInfoPanel104(String(itemId),slot));
         else open(new AbyssRelicPickPanel104(slot));
      });
   }

   // Native team/hero screen, where every position's 7th slot lives.
   public static function goEquip() : void
   {
      closeAll();
      Starling.juggler.delayCall(function():void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_main_avatar");
      },REOPEN_DELAY);
   }

   // Alchemy institute, relic reroll tab (index 2 of PanelAlchemy).
   public static function goReroll() : void
   {
      closeAll();
      Starling.juggler.delayCall(function():void
      {
         GlobalData.$tempAlchemyIndex = 2;
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_panel_alchemy");
      },REOPEN_DELAY);
   }

   public static function equipRelic(itemId:String, slot:int, done:Function) : void
   {
      var current:int = relicSlotOf(itemId);
      var doEquip:Function = function():void
      {
         send("user.abyss_relic_equip",{"item_id":itemId,"slot":slot},function(d:Object):void
         {
            GlobalData.$mEventDispatcher.dispatchEventWith("abyss_relic_changed_104");
            if(done != null) done();
         });
      };
      if(current >= 0 && current != slot)
      {
         // The server rejects an item worn by another position; take it off first.
         send("user.abyss_relic_unequip",{"item_id":itemId},function(d:Object):void
         {
            Starling.juggler.delayCall(doEquip,0.05);
         });
      }
      else doEquip();
   }

   public static function unequipRelic(itemId:String, done:Function) : void
   {
      send("user.abyss_relic_unequip",{"item_id":itemId},function(d:Object):void
      {
         GlobalData.$mEventDispatcher.dispatchEventWith("abyss_relic_changed_104");
         if(done != null) done();
      });
   }

   // ---------- hero info ----------

   public static function heroInfoLines(aid:String, slv:int, poolExtra:Array = null) : Array
   {
      var lines:Array = [];
      var av:Avatar = new Avatar(aid,heroData(aid,family(aid),slv));
      if(av.skill0) lines.push("技能 · " + av.skill0.skillSetData.name + "（" + slv + "级）：" + SkillSet.conciseInfo104(av.skill0.getInfo()));
      if(av.skill1) lines.push("队长技 · " + av.skill1.skillSetData.name + "：" + SkillSet.conciseInfo104(av.skill1.getInfo()));
      av.clear();
      if(poolExtra != null) lines.push(bondLine(aid,poolExtra));
      return lines;
   }

   // Bonds the hero belongs to, judged against the current pool plus extra ids.
   public static function bondLine(aid:String, extra:Array) : String
   {
      var defs:Array = GlobalData.$mConfig_simple ? GlobalData.$mConfig_simple.bonds_104 as Array : null;
      var fam:String = family(aid);
      var have:Object = {};
      have[fam] = true;
      for each(var id:String in poolIds()) have[id] = true;
      for each(var e:String in extra) have[family(e)] = true;
      var parts:Array = [];
      for each(var bond:Object in defs)
      {
         if(!bond.families || (bond.families as Array).indexOf(fam) < 0) continue;
         var missing:int = 0;
         for each(var member:String in bond.families) if(!have[member]) missing++;
         parts.push(String(bond.name) + (missing == 0 ? "（已集齐）" : "（差" + missing + "人）"));
      }
      return "羁绊：" + (parts.length ? parts.join("、") : "无");
   }

   public static function showHeroInfo(aid:String, slv:int, note:String = null) : void
   {
      var av:Avatar = new Avatar(aid,heroData(aid,family(aid),slv));
      var res:String = av.resId;
      av.clear();
      var text:String = (note ? note + "\n" : "") + heroInfoLines(aid,slv,[]).join("\n");
      GlobalFunction.popAlert(heroName(aid) + (isOrange(aid) ? "（橙卡）" : "（紫卡）"),Tools.formatLineX(text + "\n"),{"res":res},false);
   }
}

class AbyssPanel104 extends PanelBase
{
   protected var body:Sprite;
   protected var avatars:Array = [];
   protected var pulses:Array = [];
   protected var built:Boolean = false;
   // Set when the panel is drawn inside another screen (副本 · 深渊回廊 tab) instead of
   // as a pop-up: no pop frame; body is shifted so the pop layout's y=80 is embed.y.
   public var embed:Rectangle = null;

   public function AbyssPanel104()
   {
      super();
   }

   override protected function initializeHandler(param1:Event) : void
   {
      this.removeEventListener("addedToStage",initializeHandler);
      if(!embed) this.setPopPanelBg(panelTitle(),panelHeight());
      AbyssCore104.panels.push(this);
      body = new Sprite();
      if(embed) body.y = embed.y - 80;
      addChild(body);
      built = true;
      refresh();
   }

   protected function panelTitle() : String
   {
      return "深渊回廊";
   }

   protected function panelHeight() : Number
   {
      return GlobalData.$center_height + 100;
   }

   public function refresh() : void
   {
      if(!built) return;
      clearBody();
      build();
   }

   protected function build() : void
   {
   }

   protected function clearBody() : void
   {
      for each(var av:Avatar in avatars) av.clear();
      avatars = [];
      for each(var m:DisplayObject in pulses) Starling.juggler.removeTweens(m);
      pulses = [];
      if(body) body.removeChildren(0,-1,true);
   }

   override public function onREMOVED_FROM_STAGE(param1:Event) : void
   {
      var index:int = AbyssCore104.panels.indexOf(this);
      if(index >= 0) AbyssCore104.panels.splice(index,1);
      clearBody();
      built = false;
      super.onREMOVED_FROM_STAGE(param1);
   }

   protected function get lx() : Number
   {
      if(embed) return embed.x;
      return mImg9_baseBg ? mImg9_baseBg.x : 0;
   }

   protected function get iw() : Number
   {
      if(embed) return embed.width;
      return mImg9_baseBg ? mImg9_baseBg.width : 640;
   }

   protected function get by() : Number
   {
      if(embed) return embed.y + embed.height - (body ? body.y : 0);
      return mImg9_baseBg ? mImg9_baseBg.y + mImg9_baseBg.height : panelHeight();
   }

   protected function addText(value:String, x:Number, y:Number, w:Number, h:Number, size:int = 20, color:uint = 0xFFFFFF, align:String = "left", parent:Sprite = null) : TextField
   {
      var tf:TextField = GlobalFunction.createTextField(w,h,value,"",size,color);
      tf.hAlign = align;
      tf.vAlign = "top";
      tf.x = x;
      tf.y = y;
      tf.touchable = false;
      (parent ? parent : body).addChild(tf);
      return tf;
   }

   protected function addButton(label:String, x:Number, y:Number, w:Number, h:Number, fn:Function, enabled:Boolean = true, parent:Sprite = null) : LOL_Scale9Button
   {
      var b:LOL_Scale9Button = new LOL_Scale9Button(label,w,h,"UI_btn_normalFun_0000");
      b.fontSize = label.length > 6 ? 20 : 22;
      b.x = x;
      b.y = y;
      b.enabled = enabled;
      b.addEventListener("triggered",function(e:Event):void
      {
         if(fn != null) fn();
      });
      (parent ? parent : body).addChild(b);
      return b;
   }

   protected function addBox(x:Number, y:Number, w:Number, h:Number, parent:Sprite = null) : DisplayObject
   {
      var bg:DisplayObject = GlobalFunction.createScale9Image("UI_bg_9slice_4_0000",w,h,new Rectangle(40,30,30,30));
      bg.x = x;
      bg.y = y;
      bg.touchable = false;
      (parent ? parent : body).addChild(bg);
      return bg;
   }

   protected function addFrame(x:Number, y:Number, w:Number, h:Number, color:uint, parent:Sprite = null) : void
   {
      var target:Sprite = parent ? parent : body;
      var edges:Array = [[x,y,w,3],[x,y + h - 3,w,3],[x,y,3,h],[x + w - 3,y,3,h]];
      for each(var e:Array in edges)
      {
         var q:Quad = new Quad(e[2],e[3],color);
         q.x = e[0];
         q.y = e[1];
         q.touchable = false;
         target.addChild(q);
      }
   }

   // The one selection mark of every abyss screen: gold corner brackets with a dark
   // outline and a soft inner glow, like the native target/leader highlights.
   //   "picked"  chosen item: brackets + native check badge (UI_select_0), breathing.
   //   "current" the active option of a group (deck, tab, default button): static.
   //   "focus"   the item whose details are shown but not chosen: thin and light.
   protected function selectMark(x:Number, y:Number, w:Number, h:Number, style:String = "picked", parent:Sprite = null) : Sprite
   {
      var m:Sprite = new Sprite();
      m.touchable = false;
      var focus:Boolean = style == "focus";
      var color:uint = focus ? 0xFFF4D6 : AbyssCore104.MARK_GOLD;
      if(!focus)
      {
         var g:Number = Math.max(8,Math.min(w,h) * 0.12);
         var a:Number = style == "picked" ? 0.55 : 0.4;
         glow(m,0,0,w,g,color,a,0,0,a);
         glow(m,0,h - g,w,g,color,0,0,a,a);
         glow(m,0,0,g,h,color,a,0,a,0);
         glow(m,w - g,0,g,h,color,0,a,0,a);
      }
      var len:Number = Math.max(14,Math.min(w,h) * (focus ? 0.22 : 0.3));
      var t:Number = focus ? 3 : 5;
      // Outline first, then the gold stroke inset by 1px.
      corners(m,w,h,len + 2,t + 2,-1,focus ? 0x5A4A30 : AbyssCore104.MARK_EDGE);
      corners(m,w,h,len,t,0,color);
      if(style == "picked")
      {
         var badge:Sprite = new Sprite();
         var edge:Quad = new Quad(30,30,AbyssCore104.MARK_EDGE);
         badge.addChild(edge);
         var fill:Quad = new Quad(26,26,0x2A1A06);
         fill.x = fill.y = 2;
         badge.addChild(fill);
         var check:Image = GlobalFunction.createImage("UI_select_0_0000");
         check.x = int((30 - check.width) * 0.5);
         check.y = int((30 - check.height) * 0.5);
         badge.addChild(check);
         badge.x = w - 24;
         badge.y = -6;
         m.addChild(badge);
         var pulse:Tween = new Tween(m,0.8,"easeInOut");
         pulse.animate("alpha",0.6);
         pulse.repeatCount = 0;
         pulse.reverse = true;
         Starling.juggler.add(pulse);
         pulses.push(m);
      }
      m.x = x;
      m.y = y;
      (parent ? parent : body).addChild(m);
      return m;
   }

   // Gradient strip; alphas are per vertex: top-left, top-right, bottom-left, bottom-right.
   private function glow(target:Sprite, x:Number, y:Number, w:Number, h:Number, color:uint, a0:Number, a1:Number, a2:Number, a3:Number) : void
   {
      var q:Quad = new Quad(Math.max(1,w),Math.max(1,h),color);
      q.setVertexAlpha(0,a0);
      q.setVertexAlpha(1,a1);
      q.setVertexAlpha(2,a2);
      q.setVertexAlpha(3,a3);
      q.x = x;
      q.y = y;
      q.touchable = false;
      target.addChild(q);
   }

   private function corners(target:Sprite, w:Number, h:Number, len:Number, t:Number, inset:Number, color:uint) : void
   {
      var o:Number = inset;
      var bars:Array = [
         [o,o,len,t],[o,o,t,len],
         [w - o - len,o,len,t],[w - o - t,o,t,len],
         [o,h - o - t,len,t],[o,h - o - len,t,len],
         [w - o - len,h - o - t,len,t],[w - o - t,h - o - len,t,len]
      ];
      for each(var b:Array in bars)
      {
         var q:Quad = new Quad(b[2],b[3],color);
         q.x = b[0];
         q.y = b[1];
         q.touchable = false;
         target.addChild(q);
      }
   }

   protected function onTap(target:DisplayObject, fn:Function) : void
   {
      target.addEventListener("touch",function(e:TouchEvent):void
      {
         var t:Touch = e.getTouch(target,"ended");
         if(t) fn();
      });
   }

   protected function gray(target:DisplayObject) : void
   {
      target.blendMode = Tools.getBlendMode(null,0.45,0.45,0.45);
   }

   // Native hero card (same art as roster/exploration cards). Returns its holder.
   protected function heroCard(aid:String, id:String, slv:int, x:Number, y:Number, scale:Number = 1, leader:Boolean = false, parent:Sprite = null, limitBreak:Boolean = false) : Sprite
   {
      var holder:Sprite = new Sprite();
      var av:Avatar = new Avatar(aid,AbyssCore104.heroData(aid,id,slv,limitBreak));
      avatars.push(av);
      var res:Sprite = av.getAvatarRes(false,leader,false);
      // Keep the native pulse edge but not its unnamed "突破极限" caption (user decision).
      if(limitBreak) removeCaption(res,"突破极限");
      holder.addChild(res);
      holder.scaleX = holder.scaleY = scale;
      holder.x = x;
      holder.y = y;
      (parent ? parent : body).addChild(holder);
      return holder;
   }

   private function removeCaption(root:DisplayObjectContainer, text:String) : void
   {
      for(var i:int = root.numChildren - 1; i >= 0; i--)
      {
         var child:DisplayObject = root.getChildAt(i);
         if(child is TextField && TextField(child).text == text) child.removeFromParent(true);
         else if(child is DisplayObjectContainer) removeCaption(DisplayObjectContainer(child),text);
      }
   }

   protected function emptyCard(label:String, x:Number, y:Number, scale:Number = 1, parent:Sprite = null) : Sprite
   {
      var holder:Sprite = new Sprite();
      var img:Image = GlobalFunction.createImage("UI_bg_card_2_0002");
      holder.addChild(img);
      var tf:TextField = GlobalFunction.createTextField(img.width,img.height,label,"",36,0xFFFFFF);
      tf.hAlign = "center";
      tf.vAlign = "center";
      tf.touchable = false;
      holder.addChild(tf);
      holder.scaleX = holder.scaleY = scale;
      holder.x = x;
      holder.y = y;
      (parent ? parent : body).addChild(holder);
      return holder;
   }

   protected function line(x1:Number, y1:Number, x2:Number, y2:Number, color:uint, dashed:Boolean, parent:Sprite = null) : void
   {
      var target:Sprite = parent ? parent : body;
      var dx:Number = x2 - x1;
      var dy:Number = y2 - y1;
      var len:Number = Math.sqrt(dx * dx + dy * dy);
      var angle:Number = Math.atan2(dy,dx);
      var step:Number = dashed ? 14 : len;
      for(var d:Number = 0; d < len; d += step)
      {
         var q:Quad = new Quad(Math.max(1,Math.min(dashed ? 8 : len,len - d)),3,color);
         q.pivotY = 1.5;
         q.x = x1 + Math.cos(angle) * d;
         q.y = y1 + Math.sin(angle) * d;
         q.rotation = angle;
         q.touchable = false;
         target.addChild(q);
      }
   }
}

// ---------------------------------------------------------------- entry

class AbyssEntryPanel104 extends AbyssPanel104
{
   private var difficulty:int = 1;
   private var deck:String = "blade";

   public function AbyssEntryPanel104()
   {
      super();
      resetChoice();
   }

   // Defaults follow the account/run; re-run when the first query reply arrives.
   public function resetChoice() : void
   {
      var r:Object = AbyssCore104.run;
      var acc:Object = AbyssCore104.account;
      if(r && r.status == "active")
      {
         difficulty = int(r.difficulty);
         deck = String(r.deck);
      }
      else
      {
         difficulty = Math.max(1,int(acc.max_difficulty));
         var decks:Array = acc.decks as Array;
         deck = decks && decks.length ? String(decks[0]) : "blade";
      }
   }

   override protected function build() : void
   {
      var r:Object = AbyssCore104.run;
      var active:Boolean = r && r.status == "active";
      var acc:Object = AbyssCore104.account;
      var maxD:int = Math.max(1,int(acc.max_difficulty));
      var y:Number = 90;
      addButton("‹",lx + 60,y,70,60,function():void
      {
         if(difficulty > 1) { difficulty--; refresh(); }
      },!active && difficulty > 1);
      addText("难度 " + difficulty,lx + 140,y + 10,iw - 280,44,30,AbyssCore104.COLOR_TITLE,"center");
      addButton("›",lx + iw - 130,y,70,60,function():void
      {
         if(difficulty < maxD) { difficulty++; refresh(); }
      },!active && difficulty < maxD);
      y += 70;
      var mult:Number = AbyssCore104.enemyMultiplier(difficulty);
      addText("敌人强度 ×" + (isNaN(mult) ? "—" : mult.toFixed(2)) + "　重打次数 " + AbyssCore104.retriesText(difficulty),lx + 30,y,iw - 60,28,20,AbyssCore104.COLOR_TEXT,"center");
      y += 30;
      addText("Boss 掉落深渊遗物：第1幕 " + AbyssCore104.percent(AbyssCore104.bossRate(difficulty,1)) + " · 第2幕 " + AbyssCore104.percent(AbyssCore104.bossRate(difficulty,2)) + " · 第3幕 " + AbyssCore104.percent(AbyssCore104.bossRate(difficulty,3)),lx + 20,y,iw - 40,28,17,AbyssCore104.COLOR_TEXT,"center");
      y += 26;
      var note:String = active ? "本局进行中，结束后可重新选择难度和卡组" : (maxD < 10 ? "通关难度 " + maxD + " 后解锁难度 " + (maxD + 1) + "　通关保底 1 件深渊遗物" : "通关保底 1 件深渊遗物");
      addText(note,lx + 20,y,iw - 40,26,16,AbyssCore104.COLOR_DIM,"center");
      y += 32;
      addText("起始卡组 · " + AbyssCore104.deckName(deck) + (active ? "" : "　（点击下方一行切换）"),lx + 20,y,iw - 40,30,21,AbyssCore104.COLOR_TITLE,"center");
      y += 38;
      var unlockedDecks:Array = acc.decks as Array;
      var bottomY:Number = by - 100;
      var rowH:Number = Math.min(96,(bottomY - y - 10) / 5);
      var scale:Number = Math.min(0.85,(rowH - 10) / 90);
      for each(var key:String in AbyssCore104.DECK_ORDER)
      {
         buildDeckRow(key,y,rowH,scale,unlockedDecks && unlockedDecks.indexOf(key) >= 0,active);
         y += rowH;
      }
      addButton("卡池图鉴",lx + 60,bottomY + 10,200,66,function():void
      {
         AbyssCore104.open(new AbyssCodexPanel104());
      });
      addButton(active ? "继续本局" : "开始新的一局",lx + iw - 260,bottomY + 10,200,66,function():void
      {
         if(active) AbyssCore104.continueRun();
         else AbyssCore104.startRun(difficulty,deck);
      });
   }

   private function buildDeckRow(key:String, y:Number, rowH:Number, scale:Number, open:Boolean, active:Boolean) : void
   {
      var row:Sprite = new Sprite();
      row.x = lx + 40;
      row.y = y;
      body.addChild(row);
      var cardW:Number = 90 * scale;
      var gap:Number = ((iw - 80) - cardW * 5) / 4;
      var hit:Quad = new Quad(iw - 80,rowH - 4,0x000000);
      hit.alpha = 0.01;
      row.addChild(hit);
      var info:Object = AbyssCore104.deckInfo(key);
      var members:Array = info && info.members ? info.members as Array : [];
      for(var i:int = 0; i < 5; i++)
      {
         var x:Number = i * (cardW + gap);
         var card:Sprite;
         if(key == "star" || i >= members.length) card = emptyCard("?",x,4,scale,row);
         else card = heroCard(String(members[i]),AbyssCore104.family(String(members[i])),5,x,4,scale,i == 0,row);
         card.touchable = false;
         if(!open) gray(card);
      }
      if(!open)
      {
         var cover:Quad = new Quad(iw - 80,30,0x000000);
         cover.alpha = 0.6;
         cover.y = (rowH - 30) * 0.5;
         cover.touchable = false;
         row.addChild(cover);
         addText("首次通关难度 " + int(info ? info.clear_required : 0) + " 后解锁",0,cover.y + 2,iw - 80,28,20,AbyssCore104.COLOR_TEXT,"center",row);
      }
      if(key == deck) selectMark(-8,-2,iw - 64,rowH,"current",row);
      if(open && !active)
      {
         onTap(hit,function():void
         {
            deck = key;
            refresh();
         });
      }
   }
}

// ---------------------------------------------------------------- map

class AbyssMapPanel104 extends AbyssPanel104
{
   private static const TYPE_NAMES:Object = {"weak":"弱敌","normal":"普通战","elite":"精英战","rest":"休息处","boss":"Boss"};
   // map_version 2: route nodes sit on a 4-column grid (col 0..3); the fixed rest and
   // the boss carry col=null and are centred. v1 saves have no col: spread by index.
   private static const COLUMNS:int = 4;

   override protected function panelTitle() : String
   {
      return "深渊回廊";
   }

   override protected function build() : void
   {
      var r:Object = AbyssCore104.run;
      if(!r) return;
      var act:int = currentAct(r);
      addText("第" + act + "幕　剩余重打 " + int(r.retries) + "/" + AbyssCore104.retriesText(int(r.difficulty)) + "　阵容池 " + AbyssCore104.poolCount() + "/" + AbyssCore104.poolCap(),lx + 20,88,iw - 40,30,21,AbyssCore104.COLOR_TITLE,"center");
      var top:Number = 124;
      var bottom:Number = by - 100;
      var areaW:Number = iw - 40;
      var areaH:Number = bottom - top;
      var bg:Image = GlobalFunction.createImage("UI_map_exploration",true);
      bg.x = lx + 20;
      bg.y = top;
      bg.width = areaW;
      bg.height = areaH;
      bg.touchable = false;
      body.addChild(bg);
      var nodes:Array = [];
      var layerCount:int = 1;
      for each(var n:Object in r.map)
      {
         if(int(n.act) != act) continue;
         nodes.push(n);
         layerCount = Math.max(layerCount,int(n.layer));
      }
      var layers:Array = [];
      for(var L:int = 0; L < layerCount; L++) layers.push([]);
      for each(n in nodes) (layers[int(n.layer) - 1] as Array).push(n);
      var rowGap:Number = (areaH - 80) / Math.max(1,layerCount - 1);
      var pos:Object = {};
      for(L = 0; L < layerCount; L++)
      {
         var row:Array = layers[L];
         for(var i:int = 0; i < row.length; i++)
         {
            var c:* = row[i].col;
            var share:Number = c === null || c === undefined ? (row.length == 1 || row[i].hasOwnProperty("col") ? 0.5 : (i + 1) / (row.length + 1)) : (Number(c) + 0.5) / COLUMNS;
            pos[row[i].id] = {"x":lx + 20 + areaW * share,"y":bottom - 40 - L * rowGap};
         }
      }
      var available:Array = r.available_nodes is Array ? r.available_nodes as Array : [];
      // Only real connections (node.next) are drawn; walked edges are gold and dashed.
      for each(var from:Object in nodes)
      {
         for each(var toId:String in from.next)
         {
            if(!pos[toId]) continue;
            var to:Object = AbyssCore104.node(toId);
            var walked:Boolean = from.completed && to && (to.completed || to.id == r.current_node);
            var reachable:Boolean = (from.id == r.current_node || from.completed) && available.indexOf(toId) >= 0;
            line(pos[from.id].x,pos[from.id].y,pos[toId].x,pos[toId].y,walked ? 0xFFE08A : (reachable ? 0xFFFFFF : 0x8A8A8A),walked);
         }
      }
      for each(n in nodes) addNode(n,pos[n.id],r,available,rowGap);
      addButton("阵容池",lx + 60,bottom + 14,170,66,function():void
      {
         AbyssCore104.open(new AbyssPoolPanel104());
      });
      addButton("放弃本局",lx + iw - 230,bottom + 14,170,66,AbyssCore104.confirmAbandon,r.status == "active");
   }

   private function currentAct(r:Object) : int
   {
      var cur:Object = AbyssCore104.node(r.current_node);
      if(cur && !cur.completed) return int(cur.act);
      if(r.available_nodes && r.available_nodes.length)
      {
         var next:Object = AbyssCore104.node(r.available_nodes[0]);
         if(next) return int(next.act);
      }
      return cur ? int(cur.act) : 1;
   }

   // Every node shows its type (the whole map is known from the start).
   private function addNode(n:Object, p:Object, r:Object, available:Array, rowGap:Number) : void
   {
      var isCurrent:Boolean = n.id == r.current_node && !n.completed;
      var canGo:Boolean = available.indexOf(n.id) >= 0 && !r.pending_choice;
      var label:String = TYPE_NAMES[n.type] ? TYPE_NAMES[n.type] : String(n.type);
      var w:Number = n.type == "boss" ? 140 : 112;
      var h:Number = Math.min(50,Math.max(40,rowGap - 20));
      if(isCurrent || canGo)
      {
         var glow:Quad = new Quad(w + 14,h + 14,isCurrent ? 0x55DD55 : 0xFFCC33);
         glow.alpha = 0.45;
         glow.x = p.x - (w + 14) * 0.5;
         glow.y = p.y - (h + 14) * 0.5;
         glow.touchable = false;
         body.addChild(glow);
      }
      var b:LOL_Scale9Button = addButton(label,p.x - w * 0.5,p.y - h * 0.5,w,h,function():void
      {
         if(canGo) AbyssCore104.route(String(n.id));
         else if(isCurrent || r.pending_choice) AbyssCore104.openNodeStep();
         else if(n.completed) AbyssCore104.toast("该节点已完成");
         else AbyssCore104.toast("只能前往高亮的节点");
      });
      b.fontSize = 19;
      if(n.completed)
      {
         b.alpha = 0.55;
         if(rowGap >= 76) addText("已完成",p.x - 50,p.y + h * 0.5 - 1,100,22,15,AbyssCore104.COLOR_DIM,"center");
      }
      else if(!isCurrent && !canGo) gray(b);
   }
}

// ---------------------------------------------------------------- pick heroes

class AbyssChoicePanel104 extends AbyssPanel104
{
   private var selected:Array = [];
   private var focus:Object = null;

   override protected function panelTitle() : String
   {
      var c:Object = AbyssCore104.run ? AbyssCore104.run.pending_choice : null;
      return c && int(c.count) > 1 ? "最多选择" + int(c.count) + "名英雄" : "选择1名英雄";
   }

   override protected function build() : void
   {
      var r:Object = AbyssCore104.run;
      var c:Object = r ? r.pending_choice : null;
      if(!c) return;
      var options:Array = c.options as Array;
      var count:int = int(c.count);
      addText("阵容池 " + AbyssCore104.poolCount() + "/" + AbyssCore104.poolCap() + "　" + (count > 1 ? "可选 1～" + count + " 名加入，也可以跳过" : "选 1 名加入，也可以跳过"),lx + 20,88,iw - 40,28,20,AbyssCore104.COLOR_TITLE,"center");
      if(!focus && options.length) focus = options[0];
      var cols:int = 3;
      var cellW:Number = (iw - 60) / cols;
      var cellH:Number = 150;
      for(var i:int = 0; i < options.length; i++)
      {
         var hero:Object = options[i];
         var col:int = i % cols;
         var rowIndex:int = int(i / cols);
         var inRow:int = Math.min(cols,options.length - rowIndex * cols);
         var rowLeft:Number = lx + 30 + (cols - inRow) * cellW * 0.5;
         var cx:Number = rowLeft + col * cellW + (cellW - 90) * 0.5;
         var cy:Number = 126 + rowIndex * cellH;
         var card:Sprite = heroCard(String(hero.aid),String(hero.id),int(hero.slv),cx,cy);
         addText(AbyssCore104.heroName(String(hero.aid)),cx - 30,cy + 96,150,26,18,AbyssCore104.isOrange(String(hero.aid)) ? AbyssCore104.COLOR_ORANGE : AbyssCore104.COLOR_PURPLE,"center");
         if(selected.indexOf(hero.id) >= 0) selectMark(cx - 7,cy - 7,104,104,"picked");
         else if(focus == hero) selectMark(cx - 5,cy - 5,100,100,"focus");
         bindPick(card,hero,count);
      }
      var infoY:Number = 126 + Math.ceil(options.length / cols) * cellH + 4;
      var infoH:Number = by - 100 - infoY;
      addBox(lx + 25,infoY,iw - 50,infoH);
      if(focus)
      {
         var extra:Array = [];
         for each(var sid:String in selected) extra.push(sid);
         var lines:Array = [AbyssCore104.heroName(String(focus.aid)) + (AbyssCore104.isOrange(String(focus.aid)) ? "（橙卡）" : "（紫卡）")].concat(AbyssCore104.heroInfoLines(String(focus.aid),int(focus.slv),extra));
         addText(lines.join("\n"),lx + 45,infoY + 14,iw - 90,infoH - 24,17,AbyssCore104.COLOR_TEXT,"left");
      }
      var bottomY:Number = by - 90;
      // Every offer may be skipped (server rule since map_version 2, legacy saves too).
      addButton("跳过，不加入",lx + 50,bottomY,190,66,function():void
      {
         AbyssCore104.send("user.abyss_skip",{},function(d:Object):void
         {
            AbyssCore104.continueRun();
         });
      });
      var picked:int = selected.length;
      addButton(picked > 0 ? "加入阵容池（" + picked + " 名）" : "先点选英雄",lx + iw - 280,bottomY,230,66,function():void
      {
         if(picked < 1 || picked > count)
         {
            AbyssCore104.toast("请选择 1～" + count + " 名英雄");
            return;
         }
         AbyssCore104.send("user.abyss_choose",{"heroes":selected.concat()},function(d:Object):void
         {
            AbyssCore104.continueRun();
         });
      },picked >= 1 && picked <= count);
   }

   private function bindPick(card:Sprite, hero:Object, count:int) : void
   {
      onTap(card,function():void
      {
         focus = hero;
         var at:int = selected.indexOf(hero.id);
         if(at >= 0) selected.splice(at,1);
         else if(count == 1) selected = [hero.id];
         else if(selected.length < count) selected.push(hero.id);
         else AbyssCore104.toast("最多选择 " + count + " 名，再点已选英雄可取消");
         refresh();
      });
   }
}

// ---------------------------------------------------------------- team (step 1)

class AbyssTeamPanel104 extends AbyssPanel104
{
   private var slots:Array = [null,null,null,null,null];
   private var pending:Object = null;

   public function AbyssTeamPanel104()
   {
      super();
      var r:Object = AbyssCore104.run;
      var expires:Number = r && r.battle ? Number(r.battle.expires) : 0;
      if(r && r.battle && expires >= SendAndSelect.$systemTimer_nowSecond)
      {
         // A frozen combat exists: continue it with exactly the saved team.
         pending = r.battle;
         var i:int = 0;
         for each(var unit:Object in r.battle.orgin_team_a)
         {
            if(i < 5) slots[i++] = AbyssCore104.family(String(unit.aid));
         }
      }
      else if(AbyssCore104.lastTeam)
      {
         for(var j:int = 0; j < 5; j++)
         {
            var id:* = AbyssCore104.lastTeam[j];
            slots[j] = id && r && r.pool[id] ? id : null;
         }
      }
   }

   override protected function panelTitle() : String
   {
      return "选择出战英雄";
   }

   override protected function build() : void
   {
      var r:Object = AbyssCore104.run;
      if(!r) return;
      var n:Object = AbyssCore104.node(r.current_node);
      var enemies:Array = enemyPreview(r,n);
      var y:Number = 88;
      if(enemies && enemies.length)
      {
         var link:TextField = addText("敌方 " + enemies.length + " 人 · 查看敌方阵容 ›",lx + 30,y,iw - 60,32,22,AbyssCore104.COLOR_TITLE,"center");
         var hit:Quad = new Quad(iw - 60,36,0x000000);
         hit.alpha = 0.01;
         hit.x = lx + 30;
         hit.y = y - 2;
         body.addChild(hit);
         onTap(hit,function():void
         {
            AbyssCore104.open(new AbyssEnemyPanel104(enemies));
         });
      }
      else addText("敌方阵容：开战后显示",lx + 30,y,iw - 60,32,22,AbyssCore104.COLOR_DIM,"center");
      y += 40;
      var skinLimit:int = n ? int(n.act) : 1;
      addText("本幕皮肤英雄上限：" + skinLimit + "名",lx + 20,y,iw - 290,38,17,AbyssCore104.COLOR_TEXT,"center");
      addButton("刷新敌人 " + int(r.enemy_refreshes) + "/" + int(r.enemy_refresh_total),lx + iw - 265,y,240,40,refreshEnemy105,!pending && int(r.enemy_refreshes) > 0);
      y += 50;
      var slotW:Number = 90;
      var gap:Number = ((iw - 60) - slotW * 5) / 4;
      for(var i:int = 0; i < 5; i++)
      {
         var sx:Number = lx + 30 + i * (slotW + gap);
         var id:* = slots[i];
         if(id && r.pool[id])
         {
            var card:Sprite = heroCard(String(r.pool[id].aid),String(id),int(r.pool[id].slv),sx,y,1,i == 0);
            bindSlot(card,i);
         }
         else emptyCard(String(i + 1),sx,y);
         addText(i == 0 ? "1号位·队长" : (i + 1) + "号位",sx - 20,y + 94,130,24,16,i == 0 ? AbyssCore104.COLOR_TITLE : AbyssCore104.COLOR_DIM,"center");
      }
      y += 128;
      var count:int = filled();
      addText(pending ? "上次战斗未结算，将按开战时的阵容继续" : "点击下方英雄上阵，再点一次下阵（" + count + "/5，至少上阵3人）",lx + 20,y,iw - 40,26,17,pending ? AbyssCore104.COLOR_TITLE : AbyssCore104.COLOR_TEXT,"center");
      y += 32;
      var ids:Array = AbyssCore104.poolIds();
      var cols:int = 5;
      var scale:Number = 0.82;
      var cellW:Number = (iw - 60) / cols;
      var cellH:Number = Math.min(112,(by - 100 - y) / Math.max(1,Math.ceil(ids.length / cols)));
      scale = Math.min(scale,(cellH - 26) / 90);
      for(var k:int = 0; k < ids.length; k++)
      {
         var hid:String = ids[k];
         var hx:Number = lx + 30 + (k % cols) * cellW + (cellW - 90 * scale) * 0.5;
         var hy:Number = y + int(k / cols) * cellH;
         var hero:Object = r.pool[hid];
         var c:Sprite = heroCard(String(hero.aid),hid,int(hero.slv),hx,hy,scale);
         addText("技能" + int(hero.slv) + "级",hx - 10,hy + 90 * scale,90 * scale + 20,22,14,int(hero.slv) >= AbyssCore104.skillMax105(String(hero.aid)) ? AbyssCore104.COLOR_TITLE : AbyssCore104.COLOR_DIM,"center");
         if(slots.indexOf(hid) >= 0) selectMark(hx - 5,hy - 5,90 * scale + 10,90 * scale + 10,"picked");
         if(!pending) bindPool(c,hid);
      }
      addButton(pending ? "继续战斗" : "开始战斗",lx + (iw - 220) * 0.5,by - 90,220,66,function():void
      {
         if(pending)
         {
            AbyssCore104.startBattle(slots,pending);
            return;
         }
         if(filled() < 3)
         {
            AbyssCore104.toast("至少上阵3人");
            return;
         }
         // Close gaps so the first hero is the leader; the native formation screen
         // that follows checks lanes and positions.
         var packed:Array = [];
         for each(var sid:* in slots) if(sid) packed.push(sid);
         while(packed.length < 5) packed.push(null);
         slots = packed;
         AbyssCore104.startBattle(slots,pending);
      },pending != null || filled() >= 3);
   }

   private function filled() : int
   {
      var n:int = 0;
      for each(var id:* in slots) if(id) n++;
      return n;
   }

   private function refreshEnemy105() : void
   {
      AbyssCore104.send("user.abyss_refresh",{"node_id":AbyssCore104.run.current_node},function(d:Object):void
      {
         pending = null;
         refresh();
      });
   }

   private function canAddSkin105(id:String) : Boolean
   {
      var r:Object = AbyssCore104.run;
      if(!AbyssCore104.isSkin(String(r.pool[id].aid))) return true;
      var n:Object = AbyssCore104.node(r.current_node);
      var count:int = 0;
      for each(var hid:* in slots) if(hid && AbyssCore104.isSkin(String(r.pool[hid].aid))) count++;
      return count < (n ? int(n.act) : 1);
   }

   private function bindSlot(card:Sprite, index:int) : void
   {
      if(pending) return;
      onTap(card,function():void
      {
         slots[index] = null;
         refresh();
      });
   }

   private function bindPool(card:Sprite, id:String) : void
   {
      onTap(card,function():void
      {
         var at:int = slots.indexOf(id);
         if(at >= 0)
         {
            slots[at] = null;
            refresh();
            return;
         }
         var empty:int = slots.indexOf(null);
         if(!canAddSkin105(id))
         {
            AbyssCore104.toast("已达到本幕皮肤英雄上阵上限");
            return;
         }
         if(empty < 0)
         {
            AbyssCore104.toast("最多上阵5人");
            return;
         }
         slots[empty] = id;
         refresh();
         var t:Tween = new Tween(body,0.12);
         body.alpha = 0.85;
         t.animate("alpha",1);
         Starling.juggler.add(t);
      });
   }

   // The public run strips node enemies; use whatever preview the server exposes.
   public static function enemyPreview(r:Object, n:Object) : Array
   {
      if(n && n.enemy_preview is Array) return n.enemy_preview as Array;
      if(n && n.enemies is Array) return n.enemies as Array;
      if(r && r.battle && r.battle.orgin_team_b is Array && r.battle.metadata && r.battle.metadata.node_id == r.current_node) return r.battle.orgin_team_b as Array;
      return null;
   }
}

class AbyssEnemyPanel104 extends AbyssPanel104
{
   private var enemies:Array;

   public function AbyssEnemyPanel104(list:Array)
   {
      super();
      enemies = list;
   }

   override protected function panelTitle() : String
   {
      return "敌方阵容";
   }

   override protected function panelHeight() : Number
   {
      return 620;
   }

   override protected function build() : void
   {
      var colW:Number = (iw - 60) / 3;
      var names:Array = ["上路","中路","下路"];
      var counts:Array = [0,0,0];
      for(var c:int = 0; c < 3; c++) addText(names[c],lx + 30 + c * colW,90,colW,30,22,AbyssCore104.COLOR_TITLE,"center");
      var ordered:Array = enemies.concat();
      ordered.sort(function(a:Object, b:Object):int
      {
         if(a is String || b is String) return 0;
         return int(a.line) - int(b.line) || Number(a.pos) - Number(b.pos);
      });
      for each(var e:* in ordered)
      {
         var aid:String = e is String ? String(e) : String(e.aid);
         var lane:int = e is String ? counts.indexOf(Math.min(counts[0],counts[1],counts[2])) : Math.max(0,Math.min(2,int(e.line)));
         var slv:int = e is String ? AbyssCore104.skillBase105(aid) : int(e.slv);
         var x:Number = lx + 30 + lane * colW + (colW - 90) * 0.5;
         var y:Number = 130 + counts[lane] * 140;
         counts[lane]++;
         var card:Sprite = heroCard(aid,AbyssCore104.family(aid),slv > 0 ? slv : AbyssCore104.skillBase105(aid),x,y,1,!(e is String) && int(e.leader) == 1,null,!(e is String) && int(e.limit_break) == 1);
         addText(AbyssCore104.heroName(aid),x - 30,y + 94,150,24,16,AbyssCore104.isOrange(aid) ? AbyssCore104.COLOR_ORANGE : AbyssCore104.COLOR_PURPLE,"center");
         bindInfo(card,aid,slv > 0 ? slv : AbyssCore104.skillBase105(aid));
      }
      addText("点击头像查看技能",lx + 20,by - 50,iw - 40,26,17,AbyssCore104.COLOR_DIM,"center");
   }

   private function bindInfo(card:Sprite, aid:String, slv:int) : void
   {
      onTap(card,function():void
      {
         AbyssCore104.showHeroInfo(aid,slv);
      });
   }
}

// ---------------------------------------------------------------- rest

class AbyssRestPanel104 extends AbyssPanel104
{
   private var option:String = "skill";
   private var heroId:String = null;

   override protected function panelTitle() : String
   {
      return "休息处";
   }

   override protected function build() : void
   {
      var r:Object = AbyssCore104.run;
      if(!r) return;
      var tabW:Number = (iw - 90) / 2;
      var b1:LOL_Scale9Button = addButton("提升技能",lx + 30,90,tabW,60,function():void { option = "skill"; heroId = validFor(heroId) ? heroId : null; refresh(); });
      var b2:LOL_Scale9Button = addButton("升为橙卡",lx + 60 + tabW,90,tabW,60,function():void { option = "orange"; heroId = validFor(heroId) ? heroId : null; refresh(); });
      selectMark((option == "skill" ? b1.x : b2.x) - 6,84,tabW + 12,72,"current");
      addText("二选一，每处一次；皮肤技能3→6级，普通技能5→10级",lx + 20,156,iw - 40,24,17,AbyssCore104.COLOR_DIM,"center");
      // Target -> result preview, laid out like the alchemy screen.
      var py:Number = 186;
      addBox(lx + 25,py,iw - 50,170);
      if(heroId && r.pool[heroId])
      {
         var hero:Object = r.pool[heroId];
         var aid:String = String(hero.aid);
         var resultAid:String = option == "orange" ? aid.substr(0,aid.length - 1) + "6" : aid;
         var resultSlv:int = option == "skill" ? AbyssCore104.skillMax105(aid) : int(hero.slv);
         heroCard(aid,heroId,int(hero.slv),lx + 120,py + 30);
         addText("→",lx + (iw - 80) * 0.5,py + 52,80,50,40,AbyssCore104.COLOR_TITLE,"center");
         heroCard(resultAid,heroId,resultSlv,lx + iw - 210,py + 30);
         addText(option == "skill" ? "技能 " + int(hero.slv) + "级" : "紫卡",lx + 90,py + 126,150,24,16,AbyssCore104.COLOR_TEXT,"center");
         addText(option == "skill" ? "技能 " + resultSlv + "级" : "橙卡（面板1.4倍，技能换为橙卡）",lx + iw - 300,py + 126,270,24,16,AbyssCore104.COLOR_ORANGE,"center");
      }
      else addText("在下方选择一名英雄",lx + 25,py + 70,iw - 50,30,22,AbyssCore104.COLOR_DIM,"center");
      var y:Number = py + 182;
      var ids:Array = AbyssCore104.poolIds();
      var cols:int = 5;
      var cellW:Number = (iw - 60) / cols;
      var cellH:Number = Math.min(116,(by - 100 - y) / Math.max(1,Math.ceil(ids.length / cols)));
      var scale:Number = Math.min(0.8,(cellH - 26) / 90);
      var any:Boolean = false;
      for(var k:int = 0; k < ids.length; k++)
      {
         var hid:String = ids[k];
         var h:Object = r.pool[hid];
         var hx:Number = lx + 30 + (k % cols) * cellW + (cellW - 90 * scale) * 0.5;
         var hy:Number = y + int(k / cols) * cellH;
         var card:Sprite = heroCard(String(h.aid),hid,int(h.slv),hx,hy,scale);
         var reason:String = reasonFor(h);
         if(reason)
         {
            gray(card);
            addText(reason,hx - 14,hy + 90 * scale,90 * scale + 28,22,14,AbyssCore104.COLOR_DIM,"center");
         }
         else
         {
            any = true;
            addText(AbyssCore104.heroName(String(h.aid)),hx - 14,hy + 90 * scale,90 * scale + 28,22,14,AbyssCore104.COLOR_TEXT,"center");
            bindHero(card,hid);
         }
         if(hid == heroId) selectMark(hx - 5,hy - 5,90 * scale + 10,90 * scale + 10,"picked");
      }
      if(!any) addText("当前没有可进行此项提升的英雄，可切换选项或离开",lx + 20,by - 128,iw - 40,26,17,AbyssCore104.COLOR_RED,"center");
      var name:String = heroId && r.pool[heroId] ? AbyssCore104.heroName(String(r.pool[heroId].aid)) : "";
      addButton(heroId ? (option == "skill" ? "升级" + name + "技能" : "将" + name + "升为橙卡") : "请先选择英雄",lx + 30,by - 90,iw - 250,66,function():void
      {
         if(!heroId) return;
         AbyssCore104.send("user.abyss_rest",{"hero_id":heroId,"option":option},function(d:Object):void
         {
            AbyssCore104.closeTop();
            AbyssCore104.toast(option == "skill" ? name + "技能升至" + resultSlv + "级" : name + "已升为橙卡");
         });
      },heroId != null);
      addButton("离开",lx + iw - 200,by - 90,170,66,function():void
      {
         AbyssCore104.send("user.abyss_rest",{"option":"leave"},function(d:Object):void
         {
            AbyssCore104.closeTop();
         });
      });
   }

   private function reasonFor(h:Object) : String
   {
      if(option == "skill") return int(h.slv) >= AbyssCore104.skillMax105(String(h.aid)) ? "技能已满" : null;
      if(int(h.quality) >= 6) return "已是橙卡";
      if(!h.can_orange) return "本模式登场后可升";
      return null;
   }

   private function validFor(id:String) : Boolean
   {
      var r:Object = AbyssCore104.run;
      return id && r && r.pool[id] && reasonFor(r.pool[id]) == null;
   }

   private function bindHero(card:Sprite, id:String) : void
   {
      onTap(card,function():void
      {
         heroId = id;
         refresh();
      });
   }
}

// ---------------------------------------------------------------- pool / codex

class AbyssPoolPanel104 extends AbyssPanel104
{
   override protected function panelTitle() : String
   {
      return "阵容池";
   }

   override protected function build() : void
   {
      var r:Object = AbyssCore104.run;
      if(!r) return;
      var ids:Array = AbyssCore104.poolIds();
      var cap:int = AbyssCore104.poolCap();
      addText(ids.length + "/" + cap + " 人　只能加入，不能移出　点击头像查看技能",lx + 20,88,iw - 40,26,18,AbyssCore104.COLOR_TITLE,"center");
      // Every pool place is drawn, so the empty ones show how much room is left.
      var cols:int = 5;
      var cellW:Number = (iw - 60) / cols;
      var rows:int = Math.ceil(Math.max(cap,ids.length) / cols);
      var cellH:Number = Math.min(122,(by - 380 - 124) / Math.max(1,rows));
      var scale:Number = Math.min(0.82,(cellH - 40) / 90);
      for(var k:int = 0; k < Math.max(cap,ids.length); k++)
      {
         var hx:Number = lx + 30 + (k % cols) * cellW + (cellW - 90 * scale) * 0.5;
         var hy:Number = 124 + int(k / cols) * cellH;
         if(k >= ids.length)
         {
            var slot:Sprite = emptyCard("",hx,hy,scale);
            slot.alpha = 0.35;
            slot.touchable = false;
            continue;
         }
         var hid:String = ids[k];
         var h:Object = r.pool[hid];
         var card:Sprite = heroCard(String(h.aid),hid,int(h.slv),hx,hy,scale);
         addText(AbyssCore104.heroName(String(h.aid)),hx - 16,hy + 90 * scale - 4,90 * scale + 32,20,14,AbyssCore104.isOrange(String(h.aid)) ? AbyssCore104.COLOR_ORANGE : AbyssCore104.COLOR_PURPLE,"center");
         addText("技能" + int(h.slv) + "级" + (h.temporary ? "·本局" : ""),hx - 16,hy + 90 * scale + 15,90 * scale + 32,20,13,AbyssCore104.COLOR_DIM,"center");
         bindInfo(card,String(h.aid),int(h.slv));
      }
      buildBonds(124 + rows * cellH + 8);
   }

   // Bond summary under the pool rule: a bond works once all members are in the pool.
   private function buildBonds(top:Number) : void
   {
      var boxH:Number = by - 40 - top;
      if(boxH < 120) return;
      addBox(lx + 25,top,iw - 50,boxH);
      var list:Array = AbyssCore104.poolBonds();
      var active:Array = [];
      var near:Array = [];
      for each(var b:Object in list)
      {
         if(b.active) active.push(b.name);
         else if(b.mixed) near.push(b.name + "（需同为紫卡或同为橙卡）");
         else if(b.missing.length <= 2) near.push(b.name + "（缺 " + b.missing.join("、") + "）");
      }
      addText("羁绊　阵容池中集齐全部成员即生效",lx + 45,top + 16,iw - 90,26,19,AbyssCore104.INK_NAME,"left");
      var lines:Array = [];
      lines.push("已生效（" + active.length + "）：" + (active.length ? active.join("、") : "暂无"));
      lines.push("即将集齐：" + (near.length ? near.join("、") : "暂无"));
      addText(lines.join("\n"),lx + 45,top + 48,iw - 90,boxH - 60,17,AbyssCore104.INK_TEXT,"left");
   }

   private function bindInfo(card:Sprite, aid:String, slv:int) : void
   {
      onTap(card,function():void { AbyssCore104.showHeroInfo(aid,slv); });
   }
}

class AbyssCodexPanel104 extends AbyssPanel104
{
   override protected function panelTitle() : String
   {
      return "卡池图鉴";
   }

   // Every hero the mode can ever offer: all A_1*_5 plus orange-only skins, minus the
   // server's excluded_families (placeholder/commentator heroes). Never keep a list here.
   public static function catalogue() : Array
   {
      var excluded:Object = {};
      for each(var ex:String in AbyssCore104.cfg().excluded_families) excluded[ex] = true;
      var avatars:Object = GlobalData.$mConfig_avatar ? GlobalData.$mConfig_avatar : {};
      var result:Array = [];
      for(var aid:String in avatars)
      {
         if(!/^A_1\d+_5$/.test(aid) || excluded[AbyssCore104.family(aid)]) continue;
         result.push(aid);
      }
      for each(aid in AbyssCore104.cfg().skin_orange_only)
      {
         if(!excluded[AbyssCore104.family(aid)] && result.indexOf(aid) < 0) result.push(aid);
      }
      result.sort();
      return result;
   }

   override protected function build() : void
   {
      var u:Object = AbyssCore104.unlocked;
      var purple:Array = u.purple is Array ? u.purple as Array : [];
      var orange:Array = u.orange is Array ? u.orange as Array : [];
      var standalone:Array = u.standalone_orange is Array ? u.standalone_orange as Array : [];
      var rows:Array = [];
      for each(var aid:String in catalogue())
      {
         var fam:String = AbyssCore104.family(aid);
         var orangeOnly:Boolean = AbyssCore104.isOrange(aid);
         // state 0 = orange open, 1 = purple only, 2 = locked
         var state:int = 2;
         if(orangeOnly ? standalone.indexOf(aid) >= 0 : orange.indexOf(fam + "_6") >= 0) state = 0;
         else if(!orangeOnly && purple.indexOf(aid) >= 0) state = 1;
         var shown:String = state == 0 && !orangeOnly ? fam + "_6" : aid;
         rows.push({"aid":shown,"state":state,"orangeOnly":orangeOnly});
      }
      rows.sortOn(["state","aid"]);
      var counts:Array = [0,0,0];
      for each(var row:Object in rows) counts[row.state]++;
      addText("橙卡 " + counts[0] + "　紫卡 " + counts[1] + "　未解锁 " + counts[2],lx + 20,88,iw - 40,26,20,AbyssCore104.COLOR_TITLE,"center");
      addText("点击卡牌查看技能与开放条件",lx + 20,116,iw - 40,24,15,AbyssCore104.COLOR_DIM,"center");
      var scroll:ScrollContainer = new ScrollContainer();
      scroll.layout = new VerticalLayout();
      scroll.setSize(iw - 40,by - 40 - 150);
      scroll.x = lx + 20;
      scroll.y = 146;
      scroll.hasElasticEdges = false;
      body.addChild(scroll);
      var content:Sprite = new Sprite();
      scroll.addChild(content);
      var cols:int = 6;
      var cellW:Number = (iw - 40) / cols;
      var scale:Number = 0.7;
      for(var i:int = 0; i < rows.length; i++)
      {
         row = rows[i];
         var x:Number = (i % cols) * cellW + (cellW - 90 * scale) * 0.5;
         var y:Number = int(i / cols) * 82;
         var card:Sprite = heroCard(String(row.aid),AbyssCore104.family(String(row.aid)),5,x,y,scale,false,content);
         if(row.state == 2)
         {
            gray(card);
            var lock:Image = GlobalFunction.createImage("UI_icon_lock_1_0000");
            lock.x = x + int((90 * scale - lock.width) * 0.5);
            lock.y = y + int((90 * scale - lock.height) * 0.5);
            lock.touchable = false;
            content.addChild(lock);
         }
         bindInfo(card,String(row.aid),int(row.state),Boolean(row.orangeOnly));
      }
   }

   private function bindInfo(card:Sprite, aid:String, state:int, orangeOnly:Boolean) : void
   {
      var note:String = state == 2 ? "开放条件：持有或曾获得该英雄后开放" : (state == 1 ? "本模式登场后开放橙卡" : (orangeOnly ? "皮肤橙卡：只出现在精英战后的选人中" : "橙卡已开放"));
      onTap(card,function():void { AbyssCore104.showHeroInfo(aid,5,note); });
   }
}

// ---------------------------------------------------------------- confirm / rewards / result

class AbyssConfirmPanel104 extends AbyssPanel104
{
   private var titleText:String;
   private var lines:Array;
   private var dangerLabel:String;
   private var dangerFn:Function;
   private var safeLabel:String;
   private var safeFn:Function;
   private var dangerRed:Boolean;
   private var tapOutsideIsSafe:Boolean;

   // dangerLabel (left) is the irreversible choice; safeLabel (right) is the default.
   public function AbyssConfirmPanel104(title:String, bodyLines:Array, danger:String, onDanger:Function, safe:String, onSafe:Function, red:Boolean, outsideSafe:Boolean)
   {
      super();
      titleText = title;
      lines = [];
      for each(var s:String in bodyLines) if(s) lines.push(s);
      dangerLabel = danger;
      dangerFn = onDanger;
      safeLabel = safe;
      safeFn = onSafe;
      dangerRed = red;
      tapOutsideIsSafe = outsideSafe;
   }

   override protected function panelTitle() : String
   {
      return titleText;
   }

   override protected function panelHeight() : Number
   {
      return 250 + lines.length * 32;
   }

   override protected function build() : void
   {
      addText(lines.join("\n"),lx + 50,92,iw - 100,lines.length * 32 + 10,21,AbyssCore104.COLOR_TEXT,"left");
      var y:Number = by - 100;
      if(dangerLabel)
      {
         var danger:LOL_Scale9Button = addButton(dangerLabel,lx + 70,y,200,70,dangerFn);
         if(dangerRed) danger.fontColor = AbyssCore104.COLOR_RED;
         var safe:LOL_Scale9Button = addButton(safeLabel,lx + iw - 270,y,200,70,safeFn);
         // The safe choice is the default: mark it like the native highlighted button.
         safe.fontColor = 0x1A6F1A;
         selectMark(safe.x - 6,safe.y - 6,212,82,"current");
      }
      else addButton(safeLabel,lx + (iw - 200) * 0.5,y,200,70,safeFn);
      if(mBtn_close) mBtn_close.visible = tapOutsideIsSafe;
   }
}

class AbyssRewardPanel104 extends AbyssPanel104
{
   private var rows:Array;

   public function AbyssRewardPanel104(gained:Array)
   {
      super();
      rows = gained;
   }

   override protected function panelTitle() : String
   {
      return "获得深渊遗物";
   }

   override protected function panelHeight() : Number
   {
      return 260 + rows.length * 150;
   }

   override protected function build() : void
   {
      var y:Number = 92;
      for each(var row:Object in rows)
      {
         var item:Object = AbyssCore104.relics[row.item_id];
         if(!item) continue;
         AbyssRelicView104.draw(this,body,item,lx + 30,y,iw - 60,row.guaranteed ? "通关保底" : "");
         y += 150;
      }
      addButton("继续",lx + (iw - 200) * 0.5,by - 96,200,66,function():void
      {
         AbyssCore104.closeTop();
         AbyssCore104.openNodeStep();
      });
   }
}

// Shared relic block: name, main affix and three substats; ancient lines use the ancient color.
class AbyssRelicView104
{
   public static function draw(panel:Object, parent:Sprite, item:Object, x:Number, y:Number, w:Number, tag:String = "") : void
   {
      var bg:DisplayObject = GlobalFunction.createScale9Image("UI_bg_9slice_4_0000",w,140,new Rectangle(40,30,30,30));
      bg.x = x;
      bg.y = y;
      bg.touchable = false;
      parent.addChild(bg);
      var icon:Sprite = AbyssRelicArt104.create(item,92);
      icon.x = x + 12;
      icon.y = y + 18;
      parent.addChild(icon);
      // Dark ink on the tan box; ancient main/name and affix lines use blue.
      var mainAncient:Boolean = item.main && item.main.ancient;
      add(parent,AbyssCore104.relicName(item),x + 116,y + 10,w - 132,28,22,mainAncient ? AbyssCore104.INK_ANCIENT : AbyssCore104.INK_NAME);
      if(tag) add(parent,tag,x + w - 236,y + 13,214,26,17,AbyssCore104.INK_GREEN,"right");
      add(parent,item.main ? String(item.main.text) : "",x + 116,y + 40,w - 132,46,17,mainAncient ? AbyssCore104.INK_ANCIENT : AbyssCore104.INK_TEXT);
      var subs:Array = item.substats is Array ? item.substats as Array : [];
      for(var i:int = 0; i < subs.length; i++)
      {
         add(parent,String(subs[i].text),x + 116 + i * ((w - 132) / 3),y + 98,(w - 132) / 3,28,18,subs[i].ancient ? AbyssCore104.INK_ANCIENT : AbyssCore104.INK_TEXT);
      }
   }

   public static function add(parent:Sprite, value:String, x:Number, y:Number, w:Number, h:Number, size:int, color:uint, align:String = "left") : void
   {
      var tf:TextField = GlobalFunction.createTextField(w,h,value,"",size,color);
      tf.hAlign = align;
      tf.vAlign = "top";
      tf.x = x;
      tf.y = y;
      tf.touchable = false;
      parent.addChild(tf);
   }
}

class AbyssResultPanel104 extends AbyssPanel104
{
   override protected function panelTitle() : String
   {
      var r:Object = AbyssCore104.run;
      if(r && r.status == "cleared") return "通关";
      if(r && r.status == "abandoned") return "已放弃本局";
      return "本局失败";
   }

   override protected function build() : void
   {
      var r:Object = AbyssCore104.run;
      if(!r) return;
      var acc:Object = AbyssCore104.account;
      var y:Number = 90;
      var total:int = AbyssCore104.retriesTotal(int(r.difficulty));
      addText("难度 " + int(r.difficulty) + "　剩余重打 " + int(r.retries) + "/" + AbyssCore104.retriesText(int(r.difficulty)),lx + 20,y,iw - 40,28,22,AbyssCore104.COLOR_TITLE,"center");
      y += 34;
      var unlockText:Array = [];
      var orangeNow:Array = AbyssCore104.unlocked.orange as Array;
      var newOrange:Array = [];
      if(orangeNow && AbyssCore104.orangeBefore)
      {
         for each(var o:String in orangeNow) if(AbyssCore104.orangeBefore.indexOf(o) < 0) newOrange.push(o);
      }
      if(r.status == "cleared" && int(acc.max_difficulty) > AbyssCore104.maxBefore) unlockText.push("已解锁难度 " + int(acc.max_difficulty));
      var decksNow:Array = acc.decks as Array;
      if(decksNow && AbyssCore104.decksBefore)
      {
         for each(var d:String in decksNow) if(AbyssCore104.decksBefore.indexOf(d) < 0) unlockText.push("已解锁起始卡组：" + AbyssCore104.deckName(d));
      }
      if(r.status != "cleared") unlockText.push("未通关：不发放通关保底，不解锁下一难度");
      if(unlockText.length)
      {
         addText(unlockText.join("\n"),lx + 40,y,iw - 80,unlockText.length * 26 + 6,18,AbyssCore104.COLOR_TEXT,"left");
         y += unlockText.length * 26 + 10;
      }
      var cols:int = 10;
      var cellW:Number = (iw - 60) / cols;
      // Newly opened orange cards as native hero cards with their names.
      addText("新开放橙卡" + (newOrange.length ? "（" + newOrange.length + "）" : "：无"),lx + 40,y,iw - 80,26,20,AbyssCore104.COLOR_TITLE,"left");
      y += 30;
      if(newOrange.length)
      {
         var ocols:int = 6;
         var ocellW:Number = (iw - 60) / ocols;
         for(var n:int = 0; n < newOrange.length; n++)
         {
            var aid:String = String(newOrange[n]);
            var ox:Number = lx + 30 + (n % ocols) * ocellW + (ocellW - 63) * 0.5;
            var oy:Number = y + int(n / ocols) * 96;
            heroCard(aid,AbyssCore104.family(aid),5,ox,oy,0.7);
            addText(AbyssCore104.heroName(aid),ox - 20,oy + 64,103,22,14,AbyssCore104.COLOR_ORANGE,"center");
         }
         y += Math.ceil(newOrange.length / ocols) * 96 + 4;
      }
      addText("阵容池",lx + 40,y,200,26,20,AbyssCore104.COLOR_TITLE,"left");
      y += 28;
      var ids:Array = AbyssCore104.poolIds();
      for(var k:int = 0; k < ids.length; k++)
      {
         var h:Object = r.pool[ids[k]];
         heroCard(String(h.aid),ids[k],int(h.slv),lx + 30 + (k % cols) * cellW,y + int(k / cols) * 60,0.58);
      }
      y += Math.max(1,Math.ceil(ids.length / cols)) * 60 + 8;
      var rewards:Array = AbyssCore104.rewardsOf(null);
      addText("本局获得的深渊遗物" + (rewards.length ? "（" + rewards.length + "）" : "：无"),lx + 40,y,iw - 80,26,20,AbyssCore104.COLOR_TITLE,"left");
      y += 32;
      // Same relic cards as the relic list; scrolls when they do not fit.
      if(rewards.length)
      {
         var scroll:ScrollContainer = new ScrollContainer();
         scroll.layout = new VerticalLayout();
         scroll.setSize(iw - 60,Math.max(150,by - 110 - y));
         scroll.x = lx + 30;
         scroll.y = y;
         scroll.hasElasticEdges = false;
         body.addChild(scroll);
         var content:Sprite = new Sprite();
         scroll.addChild(content);
         var ry:Number = 0;
         for each(var row:Object in rewards)
         {
            var item:Object = AbyssCore104.relics[row.item_id];
            if(!item) continue;
            AbyssRelicView104.draw(this,content,item,0,ry,iw - 60,row.guaranteed ? "通关保底" : "");
            ry += 148;
         }
      }
      // Relics are worn on the native hero equipment bar (7th slot).
      addButton("去装备",lx + 70,by - 90,190,66,AbyssCore104.goEquip);
      addButton("返回",lx + iw - 260,by - 90,190,66,AbyssCore104.backToEntry);
   }
}

// ---------------------------------------------------------------- relics

// Relic chooser in the layout of the native PanelEquipInfoSelect / ItemEquipSelect rows
// (those classes read my_equips/Equip config, which relics are not part of).
//   slot >= 0        : 7th slot of that team position; row button 装备 / 卸下.
//   mode "target"    : pick the reroll target; "material": pick the consumed relic.
class AbyssRelicPickPanel104 extends AbyssPanel104
{
   private var slot:int;
   private var pickMode:String;
   private var onPick:Function;
   private var excludeId:String;

   public function AbyssRelicPickPanel104(pickSlot:int, mode:String = null, picked:Function = null, exclude:String = null)
   {
      super();
      slot = pickSlot;
      pickMode = mode;
      onPick = picked;
      excludeId = exclude;
   }

   override protected function panelTitle() : String
   {
      if(pickMode == "target") return "选择要重随的深渊遗物";
      if(pickMode == "material") return "选择消耗的深渊遗物";
      return "选择深渊遗物";
   }

   override protected function panelHeight() : Number
   {
      return GlobalData.$center_height;
   }

   private function pickReason(id:String) : String
   {
      if(pickMode != "material") return null;
      if(id == excludeId) return "不能消耗目标本身";
      if(AbyssCore104.relicSlotOf(id) >= 0) return "已穿戴，请先卸下";
      return null;
   }

   override protected function build() : void
   {
      var items:Object = AbyssCore104.relics;
      var ids:Array = AbyssRelicRows104.sortedIds(slot);
      var hint:String = pickMode == "material" ? "消耗品会被销毁，必须未穿戴且不是目标本身" : (pickMode == "target" ? "可选择已穿戴的深渊遗物，重随后仍在原位" : "穿戴到 " + AbyssCore104.positionName(slot) + "（第7格）");
      addText(hint,lx + 20,84,iw - 40,26,17,AbyssCore104.COLOR_TITLE,"center");
      if(!ids.length)
      {
         addText("暂无深渊遗物。在深渊回廊中击败 Boss 或通关可获得。",lx + 40,200,iw - 80,60,20,AbyssCore104.COLOR_DIM,"center");
         return;
      }
      var self:AbyssRelicPickPanel104 = this;
      AbyssRelicRows104.build(body,lx + 10,116,iw - 20,by - 40 - 116,ids,function(id:String):Object
      {
         var worn:int = AbyssCore104.relicSlotOf(id);
         if(pickMode)
         {
            var reason:String = pickReason(id);
            return {"tag":reason ? reason : (worn >= 0 ? "已穿戴：" + (worn + 1) + "号位" : ""),"label":"选择","enabled":reason == null,"red":false};
         }
         if(worn == slot) return {"tag":"已穿戴：" + (worn + 1) + "号位","label":"卸下","enabled":true,"red":true};
         return {"tag":worn >= 0 ? "已穿戴：" + (worn + 1) + "号位" : "","label":"装备","enabled":true,"red":false};
      },function(id:String):void
      {
         if(pickMode)
         {
            var reason:String = pickReason(id);
            if(reason) { AbyssCore104.toast(reason); return; }
            AbyssCore104.closeTop();
            if(onPick != null) onPick(id);
            return;
         }
         if(AbyssCore104.relicSlotOf(id) == slot) AbyssCore104.unequipRelic(id,function():void { AbyssCore104.closeTop(); });
         else AbyssCore104.equipRelic(id,slot,function():void { AbyssCore104.closeTop(); });
      },function(id:String):void
      {
         AbyssCore104.open(new AbyssRelicInfoPanel104(id,pickMode ? -2 : slot));
      });
   }
}

// Shared list rows: native ItemEquipSelect geometry (580x105, UI_bg_9slice_0 body,
// equipment frame on the left, dark name, two attribute lines, 84x45 native button).
class AbyssRelicRows104
{
   public static function sortedIds(slot:int) : Array
   {
      var items:Object = AbyssCore104.relics;
      var rows:Array = [];
      for(var id:String in items)
      {
         var worn:int = AbyssCore104.relicSlotOf(id);
         rows.push({"id":id,"key":worn == slot && slot >= 0 ? 0 : (worn >= 0 ? 1 : 2)});
      }
      rows.sortOn(["key","id"]);
      var ids:Array = [];
      for each(var row:Object in rows) ids.push(row.id);
      return ids;
   }

   // state(id) -> {tag,label,enabled,red}; onButton(id); onInfo(id) when the row body is tapped.
   public static function build(parent:Sprite, x:Number, y:Number, w:Number, h:Number, ids:Array, state:Function, onButton:Function, onInfo:Function) : ScrollContainer
   {
      var scroll:ScrollContainer = new ScrollContainer();
      scroll.layout = new VerticalLayout();
      scroll.setSize(w,h);
      scroll.x = x;
      scroll.y = y;
      scroll.hasElasticEdges = false;
      parent.addChild(scroll);
      var content:Sprite = new Sprite();
      scroll.addChild(content);
      var items:Object = AbyssCore104.relics;
      var rowW:Number = Math.min(580,w);
      var left:Number = int((w - rowW) * 0.5);
      for(var i:int = 0; i < ids.length; i++)
      {
         var row:Sprite = new Sprite();
         row.x = left;
         row.y = i * 110;
         content.addChild(row);
         drawRow(row,items[ids[i]],rowW,state(ids[i]),String(ids[i]),onButton,onInfo);
      }
      return scroll;
   }

   private static function drawRow(row:Sprite, item:Object, rowW:Number, st:Object, id:String, onButton:Function, onInfo:Function) : void
   {
      var bg:DisplayObject = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",rowW - 105,95,new Rectangle(110,55,70,20));
      bg.x = 108;
      bg.y = 5;
      row.addChild(bg);
      var frame:ItemEquip = new ItemEquip();
      frame.width = 100;
      frame.data = {"id":null,"indexID_s":null,"status":-1,"isPVP":0,"lock":0,"lockdesc":0,"teamNum":0,"sympClip":false};
      frame.touchable = false;
      frame.y = 2;
      row.addChild(frame);
      var art:Sprite = AbyssRelicArt104.create(item,100);
      art.y = 2;
      art.touchable = false;
      row.addChild(art);
      var mainAncient:Boolean = item.main && item.main.ancient;
      AbyssRelicView104.add(row,AbyssCore104.relicName(item),130,12,rowW - 260,28,20,mainAncient ? AbyssCore104.INK_ANCIENT : 0x111111);
      if(st.tag) AbyssRelicView104.add(row,String(st.tag),rowW - 250,12,150,24,15,AbyssCore104.INK_GREEN,"right");
      AbyssRelicView104.add(row,item.main ? String(item.main.text) : "",130,40,rowW - 240,40,15,mainAncient ? AbyssCore104.INK_ANCIENT : AbyssCore104.INK_TEXT);
      var subs:Array = item.substats is Array ? item.substats as Array : [];
      var parts:Array = [];
      for each(var s:Object in subs) parts.push(String(s.text));
      AbyssRelicView104.add(row,parts.join("　"),130,76,rowW - 240,22,15,AbyssCore104.INK_TEXT);
      var hit:Quad = new Quad(rowW - 105,95,0x000000);
      hit.alpha = 0.01;
      hit.x = 0;
      hit.y = 5;
      row.addChild(hit);
      hit.addEventListener("touch",function(e:TouchEvent):void
      {
         if(e.getTouch(hit,"ended") && onInfo != null) onInfo(id);
      });
      var btn:LOL_Scale9Button = new LOL_Scale9Button(String(st.label),84,45,st.red ? "UI_btn_smallFun_1_0000" : "UI_btn_enterGame_0_0000",true,false);
      btn.x = rowW - 84 - 10;
      btn.y = int((105 - 45 + 26) * 0.5);
      btn.enabled = Boolean(st.enabled);
      btn.addEventListener("triggered",function(e:Event):void { onButton(id); });
      row.addChild(btn);
   }
}

// Relic detail in the layout of the native equipment detail (frame + name at top,
// UI_bg_9slice_0 body). slot >= 0: opened from that 7th slot (卸下 / 更换);
// slot == -1: equipment management tab (wear to a position, take off, reroll);
// slot == -2: read only (from a picker).
class AbyssRelicInfoPanel104 extends AbyssPanel104
{
   private var itemId:String;
   private var slot:int;

   public function AbyssRelicInfoPanel104(id:String, fromSlot:int)
   {
      super();
      itemId = id;
      slot = fromSlot;
   }

   override protected function panelTitle() : String
   {
      return "深渊遗物";
   }

   override protected function panelHeight() : Number
   {
      return 470;
   }

   override protected function build() : void
   {
      var item:Object = AbyssCore104.relics[itemId];
      if(!item)
      {
         addText("该深渊遗物已不存在",lx + 40,120,iw - 80,40,22,AbyssCore104.COLOR_DIM,"center");
         return;
      }
      var frame:ItemEquip = new ItemEquip();
      frame.width = 100;
      frame.data = {"id":null,"indexID_s":null,"status":-1,"isPVP":0,"lock":0,"lockdesc":0,"teamNum":0,"sympClip":false};
      frame.touchable = false;
      frame.x = lx + 30;
      frame.y = 96;
      body.addChild(frame);
      var art:Sprite = AbyssRelicArt104.create(item,100);
      art.x = frame.x;
      art.y = frame.y;
      art.touchable = false;
      body.addChild(art);
      var mainAncient:Boolean = item.main && item.main.ancient;
      addText(AbyssCore104.relicName(item),lx + 150,100,iw - 180,32,24,mainAncient ? AbyssCore104.COLOR_ANCIENT : AbyssCore104.COLOR_TITLE);
      var worn:int = AbyssCore104.relicSlotOf(itemId);
      addText(worn >= 0 ? "已穿戴：" + AbyssCore104.positionName(worn) : "未穿戴",lx + 150,136,iw - 180,26,18,worn >= 0 ? AbyssCore104.COLOR_GREEN : AbyssCore104.COLOR_DIM);
      addText("不可强化、不可出售；在深渊回廊以外的玩法生效",lx + 150,164,iw - 180,24,15,AbyssCore104.COLOR_DIM);
      var boxY:Number = 206;
      var bg:DisplayObject = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",iw - 60,150,new Rectangle(110,55,70,20));
      bg.x = lx + 30;
      bg.y = boxY;
      bg.touchable = false;
      body.addChild(bg);
      AbyssRelicView104.add(body,"主词条",lx + 50,boxY + 12,120,24,16,AbyssCore104.INK_NAME);
      AbyssRelicView104.add(body,item.main ? String(item.main.text) : "",lx + 50,boxY + 36,iw - 100,48,17,mainAncient ? AbyssCore104.INK_ANCIENT : AbyssCore104.INK_TEXT);
      AbyssRelicView104.add(body,"副词条",lx + 50,boxY + 88,120,24,16,AbyssCore104.INK_NAME);
      var subs:Array = item.substats is Array ? item.substats as Array : [];
      for(var i:int = 0; i < subs.length; i++)
      {
         AbyssRelicView104.add(body,String(subs[i].text),lx + 50 + i * ((iw - 100) / 3),boxY + 112,(iw - 100) / 3,26,17,subs[i].ancient ? AbyssCore104.INK_ANCIENT : AbyssCore104.INK_TEXT);
      }
      var bottomY:Number = by - 96;
      if(slot >= 0)
      {
         addButton("卸下",lx + 60,bottomY,200,66,function():void
         {
            AbyssCore104.unequipRelic(itemId,function():void { AbyssCore104.closeTop(); });
         },worn == slot);
         addButton("更换",lx + iw - 260,bottomY,200,66,function():void
         {
            AbyssCore104.closeTop();
            Starling.juggler.delayCall(function():void { AbyssCore104.open(new AbyssRelicPickPanel104(slot)); },AbyssCore104.REOPEN_DELAY);
         });
      }
      else if(slot == -1)
      {
         addButton("卸下",lx + 60,bottomY,200,66,function():void
         {
            AbyssCore104.unequipRelic(itemId,null);
         },worn >= 0);
         addButton("去重随",lx + iw - 260,bottomY,200,66,AbyssCore104.goReroll);
      }
   }

}

// Equipment management (PanelEquipBase) tab "深渊遗物": every relic as a native row.
class AbyssRelicManageView104 extends Sprite
{
   private var viewH:Number;

   public function AbyssRelicManageView104(height:Number)
   {
      super();
      viewH = height;
      addEventListener("addedToStage",onAdded);
   }

   private function onAdded(e:Event) : void
   {
      removeEventListener("addedToStage",onAdded);
      addEventListener("removedFromStage",onRemoved);
      GlobalData.$mEventDispatcher.addEventListener("abyss_relic_changed_104",onChanged);
      AbyssCore104.send("user.abyss_relics",{},function(d:Object):void { draw(); });
      draw();
   }

   private function onRemoved(e:Event) : void
   {
      removeEventListener("removedFromStage",onRemoved);
      GlobalData.$mEventDispatcher.removeEventListener("abyss_relic_changed_104",onChanged);
   }

   private function onChanged(e:Event) : void
   {
      if(stage) draw();
   }

   private function draw() : void
   {
      removeChildren(0,-1,true);
      var ids:Array = AbyssRelicRows104.sortedIds(-1);
      var head:TextField = GlobalFunction.createTextField(GlobalData.$mStageWidth - 40,26,"共 " + ids.length + " 件　点开查看详情，可卸下或去重随","",17,AbyssCore104.COLOR_TITLE);
      head.hAlign = "center";
      head.x = 20;
      head.touchable = false;
      addChild(head);
      if(!ids.length)
      {
         var none:TextField = GlobalFunction.createTextField(GlobalData.$mStageWidth - 80,60,"暂无深渊遗物。在副本 · 深渊回廊中击败 Boss 或通关可获得。","",20,AbyssCore104.COLOR_DIM);
         none.hAlign = "center";
         none.x = 40;
         none.y = 80;
         none.touchable = false;
         addChild(none);
         return;
      }
      AbyssRelicRows104.build(this,6,34,GlobalData.$mStageWidth - 12,viewH - 34,ids,function(id:String):Object
      {
         var worn:int = AbyssCore104.relicSlotOf(id);
         return {"tag":worn >= 0 ? "已穿戴：" + (worn + 1) + "号位" : "","label":"详情","enabled":true,"red":false};
      },openInfo,openInfo);
   }

   private function openInfo(id:String) : void
   {
      AbyssCore104.open(new AbyssRelicInfoPanel104(id,-1));
   }
}

// 7th equipment slot shown by LOL_DetailAvatar (built from the native ItemEquip frame).
class AbyssRelicSlotView104
{
   public static function create(slot:int) : Sprite
   {
      var holder:Sprite = new Sprite();
      var frame:ItemEquip = new ItemEquip();
      frame.width = 100;
      frame.data = {"id":null,"indexID_s":null,"status":-1,"isPVP":0,"lock":0,"lockdesc":0,"teamNum":slot,"sympClip":false};
      frame.touchable = false;
      holder.addChild(frame);
      var slots:Array = AbyssCore104.relicSlots();
      var itemId:* = slots[slot];
      var items:Object = GlobalData.$userData && GlobalData.$userData.abyss_relics ? GlobalData.$userData.abyss_relics : {};
      var item:Object = itemId ? items[itemId] : null;
      var label:TextField;
      if(item)
      {
         holder.addChild(AbyssRelicArt104.create(item,100));
         var ancient:Boolean = item.main && item.main.ancient;
         label = GlobalFunction.createTextField(96,60,AbyssCore104.relicName(item),"",18,ancient ? AbyssCore104.COLOR_ANCIENT : AbyssCore104.COLOR_TITLE);
         label.y = 104;
         label.height = 44;
      }
      else
      {
         label = GlobalFunction.createTextField(96,60,"深渊遗物","",17,AbyssCore104.COLOR_DIM);
         label.y = 20;
      }
      label.x = 2;
      label.hAlign = "center";
      label.vAlign = "center";
      label.touchable = false;
      holder.addChild(label);
      if(!item)
      {
         var hint:TextField = GlobalFunction.createTextField(160,24,"副本 · 深渊回廊获得","",15,AbyssCore104.COLOR_DIM);
         hint.hAlign = "center";
         hint.x = -30;
         hint.y = 98;
         hint.touchable = false;
         holder.addChild(hint);
      }
      var hit:Quad = new Quad(100,100,0x000000);
      hit.alpha = 0.01;
      holder.addChild(hit);
      hit.addEventListener("touch",function(e:TouchEvent):void
      {
         if(e.getTouch(hit,"ended")) AbyssCore104.openRelicSlot(slot);
      });
      return holder;
   }
}

// Alchemy institute tab "深渊遗物": reroll exactly one substat by consuming another relic.
// Layout: target slot <- material slot, main affix block marked 不变, three selectable
// substat rows, and a button that names the chosen substat.
class AbyssRerollView104 extends Sprite
{
   private var targetId:String = null;
   private var materialId:String = null;
   private var index:int = -1;
   private var flashIndex:int = -1;
   private var area:Sprite;
   private var areaHeight:Number;

   public function AbyssRerollView104(height:Number)
   {
      super();
      areaHeight = height;
      area = new Sprite();
      addChild(area);
      addEventListener("removedFromStage",onRemoved);
      AbyssCore104.send("user.abyss_relics",{},function(d:Object):void
      {
         if(stage) draw();
      });
      draw();
   }

   private function onRemoved(e:Event) : void
   {
      removeEventListener("removedFromStage",onRemoved);
      area.removeChildren(0,-1,true);
   }

   private function txt(value:String, x:Number, y:Number, w:Number, h:Number, size:int, color:uint, align:String = "left") : TextField
   {
      var tf:TextField = GlobalFunction.createTextField(w,h,value,"",size,color);
      tf.hAlign = align;
      tf.vAlign = "top";
      tf.x = x;
      tf.y = y;
      tf.touchable = false;
      area.addChild(tf);
      return tf;
   }

   private function box(x:Number, y:Number, w:Number, h:Number) : DisplayObject
   {
      var bg:DisplayObject = GlobalFunction.createScale9Image("UI_bg_9slice_4_0000",w,h,new Rectangle(40,30,30,30));
      bg.x = x;
      bg.y = y;
      bg.touchable = false;
      area.addChild(bg);
      return bg;
   }

   private function tap(x:Number, y:Number, w:Number, h:Number, fn:Function) : void
   {
      var hit:Quad = new Quad(w,h,0x000000);
      hit.alpha = 0.01;
      hit.x = x;
      hit.y = y;
      area.addChild(hit);
      hit.addEventListener("touch",function(e:TouchEvent):void
      {
         if(e.getTouch(hit,"ended")) fn();
      });
   }

   // One relic slot: native ItemEquip frame plus the relic name.
   private function slotView(x:Number, y:Number, itemId:String, caption:String, empty:String) : void
   {
      var frame:ItemEquip = new ItemEquip();
      frame.width = 100;
      frame.data = {"id":null,"indexID_s":null,"status":-1,"isPVP":0,"lock":0,"lockdesc":0,"sympClip":false};
      frame.touchable = false;
      frame.x = x;
      frame.y = y;
      area.addChild(frame);
      var item:Object = itemId ? AbyssCore104.relics[itemId] : null;
      if(item)
      {
         var art:Sprite = AbyssRelicArt104.create(item,100);
         art.x = x;
         art.y = y;
         area.addChild(art);
      }
      var name:String = item ? AbyssCore104.relicName(item) : empty;
      txt(name,x - 30,y + (item ? 104 : 22),160,item ? 38 : 60,item ? 18 : 16,item ? (item.main && item.main.ancient ? AbyssCore104.COLOR_ANCIENT : AbyssCore104.COLOR_TITLE) : AbyssCore104.COLOR_DIM,"center");
      txt(caption,x - 40,y - 28,180,24,17,AbyssCore104.COLOR_TEXT,"center");
   }

   private function draw() : void
   {
      area.removeChildren(0,-1,true);
      var w:Number = GlobalData.$mStageWidth;
      var items:Object = AbyssCore104.relics;
      if(targetId && !items[targetId])
      {
         targetId = null;
         index = -1;
      }
      if(materialId && (!items[materialId] || AbyssCore104.relicSlotOf(materialId) >= 0 || materialId == targetId)) materialId = null;
      var y:Number = 0;
      txt("消耗另一件深渊遗物，只重随所选的 1 条副词条；主词条和另外 2 条不变",20,y,w - 40,26,17,AbyssCore104.COLOR_DIM,"center");
      y += 34;
      var leftX:Number = w * 0.5 - 170;
      var rightX:Number = w * 0.5 + 70;
      slotView(leftX,y,targetId,"目标","点击选择");
      txt("←",w * 0.5 - 40,y + 26,80,50,40,AbyssCore104.COLOR_TITLE,"center");
      slotView(rightX,y,materialId,"消耗","点击放入");
      tap(leftX,y,100,100,pickTarget);
      tap(rightX,y,100,100,pickMaterial);
      y += 160;
      var target:Object = targetId ? items[targetId] : null;
      box(25,y,w - 50,96);
      txt("主词条　不变",45,y + 10,w - 90,26,19,AbyssCore104.COLOR_TITLE);
      if(target && target.main) txt(String(target.main.text),45,y + 40,w - 90,50,18,target.main.ancient ? AbyssCore104.COLOR_ANCIENT : AbyssCore104.COLOR_TEXT);
      else txt("先选择目标深渊遗物",45,y + 40,w - 90,30,18,AbyssCore104.COLOR_DIM);
      y += 108;
      txt("副词条（点选要重随的一条）",25,y,w - 50,26,19,AbyssCore104.COLOR_TITLE);
      y += 32;
      var subs:Array = target && target.substats is Array ? target.substats as Array : [null,null,null];
      for(var i:int = 0; i < 3; i++)
      {
         var sub:Object = i < subs.length ? subs[i] : null;
         var rowY:Number = y + i * 66;
         box(25,rowY,w - 50,58);
         if(i == index)
         {
            var mark:Quad = new Quad(w - 62,46,AbyssCore104.COLOR_SELECT);
            mark.alpha = 0.35;
            mark.x = 31;
            mark.y = rowY + 6;
            mark.touchable = false;
            area.addChild(mark);
         }
         if(i == flashIndex) flash(25,rowY,w - 50,58);
         txt(sub ? String(sub.text) : "—",50,rowY + 16,w - 300,30,21,sub && sub.ancient ? AbyssCore104.COLOR_ANCIENT : AbyssCore104.COLOR_TEXT);
         txt(i == index ? "重随这条 ✓" : "保留",w - 230,rowY + 17,180,30,19,i == index ? AbyssCore104.COLOR_SELECT : AbyssCore104.COLOR_DIM,"right");
         bindRow(rowY,w,i,sub != null);
      }
      y += 3 * 66 + 8;
      var material:Object = materialId ? items[materialId] : null;
      txt(material ? "将消耗：" + AbyssCore104.relicName(material) + "（重随后该件消失）" : "需要放入一件未穿戴的深渊遗物作为消耗",25,y,w - 50,26,17,material ? AbyssCore104.COLOR_RED : AbyssCore104.COLOR_DIM,"center");
      var label:String = target && index >= 0 && index < subs.length && subs[index] ? "重随『" + String(subs[index].text) + "』这条" : "重随所选词条";
      var btn:LOL_Scale9Button = new LOL_Scale9Button(label,300,66,"UI_btn_normalFun_0000");
      btn.fontSize = label.length > 10 ? 19 : 22;
      btn.x = (w - 300) * 0.5;
      btn.y = Math.max(y + 34,areaHeight - 80);
      // Always tappable: tell the player what is missing instead of disabling.
      btn.addEventListener("triggered",function(e:Event):void
      {
         submit();
      });
      area.addChild(btn);
      flashIndex = -1;
   }

   private function bindRow(rowY:Number, w:Number, i:int, valid:Boolean) : void
   {
      tap(25,rowY,w - 50,58,function():void
      {
         if(!valid)
         {
            AbyssCore104.toast("请先选择目标深渊遗物");
            return;
         }
         index = index == i ? -1 : i;
         draw();
      });
   }

   private function flash(x:Number, y:Number, w:Number, h:Number) : void
   {
      var q:Quad = new Quad(w,h,AbyssCore104.COLOR_ANCIENT);
      q.x = x;
      q.y = y;
      q.alpha = 0;
      q.touchable = false;
      area.addChild(q);
      var t:Tween = new Tween(q,0.25);
      t.animate("alpha",0.6);
      t.repeatCount = 4;
      t.reverse = true;
      t.onComplete = function():void
      {
         q.removeFromParent(true);
      };
      Starling.juggler.add(t);
   }

   private function pickTarget() : void
   {
      AbyssCore104.open(new AbyssRelicPickPanel104(-1,"target",function(id:String):void
      {
         if(targetId != id) index = -1;
         targetId = id;
         if(materialId == id) materialId = null;
         draw();
      }));
   }

   private function pickMaterial() : void
   {
      if(!targetId)
      {
         AbyssCore104.toast("请先选择目标深渊遗物");
         return;
      }
      AbyssCore104.open(new AbyssRelicPickPanel104(-1,"material",function(id:String):void
      {
         materialId = id;
         draw();
      },targetId));
   }

   private function submit() : void
   {
      var missing:Array = [];
      if(!targetId) missing.push("目标深渊遗物");
      if(index < 0) missing.push("要重随的副词条");
      if(!materialId) missing.push("消耗的深渊遗物");
      if(missing.length)
      {
         AbyssCore104.toast("请选择" + missing.join("、"));
         return;
      }
      var chosen:int = index;
      AbyssCore104.send("user.abyss_relic_reroll",{"item_id":targetId,"material_id":materialId,"substat_index":chosen},function(d:Object):void
      {
         materialId = null;
         flashIndex = chosen;
         if(stage) draw();
         GlobalData.$mEventDispatcher.dispatchEventWith("abyss_relic_changed_104");
      });
   }
}
// Generated by scripts/build_abyss_relic_art_104.py; do not edit pixel data.
class AbyssRelicArt104
{
   public static function create(item:Object, size:Number = 92) : Sprite
   {
      var holder:Sprite = new Sprite();
      holder.touchable = false;
      var background:Quad = new Quad(92,93,0x291530);
      holder.addChild(background);
      var kind:int = item ? int(item.relic_id) : 0;
      if(kind >= 1 && kind <= 20)
      {
         var texture:Texture = Texture.fromTexture(atlas(),new Rectangle(((kind - 1) % 5) * 100,int((kind - 1) / 5) * 100,92,93));
         holder.addChild(new Image(texture));
      }
      holder.addChild(Equip.createQualityFrame104(AbyssCore104.relicFrameQuality(item)));
      holder.scaleX = holder.scaleY = size / 92;
      return holder;
   }

   private static function atlas() : Texture
   {
      var texture:Texture = GlobalData.$assetManager.getTexture("__abyssRelicAtlas104");
      if(!texture)
      {
         var encoded:String = [
            "78daec7d0758145bb6753541726c72ce39e79c41a28a8a828a220a985001415454c40062c08082987316735654cc62cef1aad72c6609dd5d8bf39f46b9e3bde3cc9b7933ef9fabd3fbfbf657457775357dc25e6bed138a6144263291894c64221399c844263291894c64221399c844263291894c64221399c844263291894c64221399c844263291894c64221399c844263291894c64221399c844263291894c64221399c844263291894c64221399c8fe3513ffe65c6af6ecd90aa93e5ce13987ba98a8784426b27f9b71444520329189ec4f6062dfc423c9baba057d35c5984b0a0c734785617aeb4b4b7e8f1f884c642213d97f0b4f53d553549408fc4bbc14d9bf5eae220efc9faf836f313d498d612e53dc27369a9a646cf6303226d99b98ca8aef546238266e064ac26b2444c5f643f6334d3b39c6df5e9e112709bfe37d22fbf7f26871515cfb29f1dfc044457aa5a98aa2b6acacaca8effcfb4c3c41d467fe23e5fecd798032c3d4c853dc7731b725d3c78fe0bf787a4b409a7e153c5e1bca3f58e24112dcd55fa9893151260aed441ce0c7eb5f429b612ecbb4184b73ead4c599413a124cbb0d367fd50e44f6bfe7d062e3c78f1795c6cfdd87365a7015eeba6a2b69308c1c23c2ac7fc994545454e4fe0e2689ecff56a7088db663a692227a8b938925993d692cbffefa7201f9b40b84f0f1e840016a4bedb06bac07ef4c990f19116724d09614ebaf212626e2bf3f9676510a33619ee9b563c80a7f0e59152846fcb89c33940738d8c931a238f6bfc77cf18484846f5f77a43e5b5d5656dbca404dd4477e0c0df48fd49130ef2facf344156939521aa9792cdc4849aa95f389faceff167b3c341515afe82828ae315556ef4c6b42f29bf74565fa7f53ee12df70ac68733585872e26a664f2a811eceb1babf9e4d144f06e4f4473d32334bebd8f2b5541d89ceb8095990e583ec45170b4c4935d34cc8e58ab480dd0911213b67d517cfb735bdb7865b2704ca7bb31874f0671042483c3fb98cc2159569cb7a6d24c948582687ee73f8919df9a32f52ed437f9ba5837e676b3225d3c7437284bc9b45d2b8a653f86bee7fc03751ec2305298dd5983ac8ad618a3d84efedbdc80c8fef93e94a7242b4d6275ed493f13bf2b464aaaddbea35d44f6af6994efe5ea5d0c249966fa06993ca25f33795ec17eae1bcc36fe3215bce64b54fbbfc7ebf30bb07b9439d60c73c2fa6cea394e383ec387bf7dbc5b8ba7befc231d4931450f3355d11c8e1f43ffd7e84830e47002c5ff6c061ffb3020fd99a65fbb7088a51cd3cf42f6bbb826b2bf5fae41d4e7596bab3e4eefdb9fac5b3c933cded50df7aadc9a0e4cf2271ec66a93b85f3880a4a8b8fe947d42389faf8b99aa92beb4b4f4ff84396d7d2382e23f9992a829789badfb2e4853519b61447301fe450e70485b5e812d30694f163af7243106f64bc5c519e93e8681220ef0cfb569b16ff0fe7be56641bd1ff56a3986f96067608494ae5d05937ad8e2f1ae64bc3c3618fc862310b077c0f21fe364791cd60cb164d7e4d86303c5fea33302303dd992dfcd4995a87198cdc672ad614d425447ffdf385cdb51ec9fec5f2eb4a6043d4d18b0451c963f9203de408647067048b211670af74bed898946aeffa1ba90f1d2d34be62a704f47f87891b2d26272efd64d425e1ee2f38f75e1bf5c61cade5bee86632501fcb5233c88b9ba728a2c2325e2567f3e13f6a17636364ca9a1b262a3b7ae72858bb682e2dfe100adf97f4298e1128c0c599ba7df484af4c9581b951c152585b6f77fa678f3ff236ff5979c8a38d3e2a366cc9b6014c1df179045065804ed6b27c9c8856b3a88f4e5f7db6e1bdeffbdb1123daa3ee26921cfa07e8e6276838f95151992d2876cdbb4923cbaba8d3d333f11bb4a43d170bf14af0fa5e2c3956954fb7fc4e373ebb1769029c57d57ac1a6a874b2b3a6253511032bcd5b136db891d9f64c95765982cb32f7301c544fcf7ff54a7fc4ffde76fbeff352f39df519a21477a73786425070dd914fb4772c81c1fce1ae5bfdc87f3cd7772fe6bca97d032da9020115813289e401284e7df2b7b61db963213722442f2d5a5db919c6edee4ede38b2cf97893d7583b807db6d6146faa9df079b72778b57ef8755f57f6725584605dbe2beb6dae96a6ab24dfc695457cf9ff4fdff8676c9fab96125919a35d1b6ea4a2c07c7f2ca0ad2f1db35451240f979b34374ed36fd911a871cc4e53b1b5cf901f1f53be378e216df8cf6bcf6fe754d072217f8f4f08cb4df8fa4913252e196618c8cfd20b6abe183696a49b78ed909414ae55da201a43fb9fdbbda42bc398d26307ea9368811d56e370ded8ea689384b06032ad701ca9dd5fddf2eef17e3e21b5fc4f378bd973f37c70ac220ecd1ff650cc3f840fc7fbe1f3d5327a4e70704677ac1d62898d392eb8b0240e4f0ea6e348790c8a3be9e3caaaae78b6a72726f4b2275a1262530de57e4b6f8ad604fcfbeb5936d695e94259d6547a5e493d8f16b29bbecc5f71c1bff579758a3c2f075b715af8951c96b7578c4f6672c8f124ce310b19dab70d7ff779b1ffa3f8fa67c47d21e6533df757515b327d41ba647a7abad87866fcf7e6f44fa19720cd57b3f17891136eccb3c4ded991d8bb241595038df06c972f485d304eaf8ea0bcd99c3d56682cc88cd4225c69b9f4af1ce01fe56e22fb3bbc966c48f85b7de69f69b7adb8429b40008539dea4600d72aeafee5c5dd9bf1ad36ff765990c134f4fc9c8380d01396dc9be986a48ee74d1ad8f3151fe91d702fc51bb6953efc595935ba523afb441435ec15b435a9af3077df0ed3cb2eff5a17f06bfda30235bae9d04e9a3e7c6cbd609c40493",
            "f0e66b61792442dbb2444a9223ea2fbf8fcfa10672e287551866076da93b9518e60897616e1bc9cb7c76b7b42009816664423f37b2774e04f9f5e4680185731e219f04a47e3ecb3e28c2f3a3a978bcaf275e5f188b6727276157d9009cdb5fcc927b39c0b38d78fde83ad6655a625d9633f64ef445758117f64e0bc3affbfbe1c0d420dcd8d01d7776f4655f1eea2fa8caf52786d2629b3425c4d492025d194634dfe9df85fd4257f430638eab8a8b117f0b695294c22525191a24de4711baf212b50a0c27c640569cf90e76b7f6abaff9c8218e520cd99bcce1935a8afd3562e4491ee76e981aa325fbfbcfb5dd48b2ce5538f6f6d3720021f68b7d857465a5a5815169b72624173e98969b75af28a7dfa502affebbf3147bf68cfc36ae1953cf9060c4b6bad85ad577f034c0b0705df6d42407d44cb542ddae3c909b79284fd4c4c609f6f865b30f867a2ba0b2bb0a860429b3716e9a6c889de67b5b2d95edaa92d2bda5c5a4152c2db90c239ae7fc4fd71dad92b67a913939434fec5f5c6ed956f6327a0c73dfcf5809fc79a62d992e1ac32524e4dab0a94dd77b538ef03ad246056fb798b1e488255e9718b39ffa1ab60c7552f5a5effd8818f5edffeb417d99aea2cacbf61ad6c45bcdf49cbabcbcbd869cdc1ff5fdf74c9846b4a7de957a81ac84d832aebcfc417d75ad4b960666478d35751728b413efc27c3f47dc764f6f5ada244acb8a9d601481c11a1eec3e8ffefc5daebd89b5925ab89c94f87f3b07688b157abaaa32af8c6425c9dc6c6fb273e35cb2a77a2b39b86b17b97eb186bcb93a5d406e64f3c8fde17cf2723e4bf01454d0031f3783dccd45e3d98178b0b103f64cf1c4ac2475640748a28b0583e1a13a7875bb020437717e532956a41bb27b0bbdb16da4134a3ae96056a2218e9585e0c9e10cdcddde0737b7a5e0f191a120cf67f14eaeeb4fdcf514ee28324ca48dbaecb7bc4e14dbfe7731a9ad9d57ab4b4a104755b1e6d7d5063c72db8af77ca51e6ff7706576519a2a490e52225a7212cb69b9ab473ac9ffb17f0863a5f0ef73bd8d18f2693e87474e705a9a8a39af0758726cdafd3ea7d97634b690624e688931270cdb314a612a3fd5588018c5fdafba7fbcecf8baf1693d6ee4dd58f96125b9428e7f9cf9b262d6a0db635dd20fe64ad7fc5223bc5e58a0dda96f77b1b6ff383ca337d9ba2497dcda31989c2871c5d27e8678b62312ebcba2b0325519eb523530d8978bf34b3d51996e8ca91dd490d75e0d0bfb9ae050812d7b6ea60b39551e4816e7f892442f83bb060a72a90a524aa25cc03f87fd6d96fda4d234f75e998910ffc5c8f87fa84ffdcd3cd9d7fb9e76d652246fd69ab247fbeaf20374946c54557f1bb319489bc3fb585b15f2eb462b0139610ffe5e73bc2d32e2f3d38dc9ac40cd743131d96f39f78f1063dab05838276c95a682021b6fe84aa65ac491743ddfad9a728ae2dfc4f16f715bf22bd6a7509fab222f5f63656cf1d8d3c1830d70f527e1dee12436a003e91ade9df48eeb4b06741f4286f61a41fa7719483c6dddf7515e205cf3ffc77c82d074a9bf0bd2302625a6edd94cae0bf6f8a50b6e0465910203dfdbaab232b2ae8cf67ff35c80b6fad8485b1a291de8d344ee64f205efcef0291f167cf13b2c79340e82a7f380c6e320ec47f05fd4e1c99129383237024b865aa0af8f1c5cd4a5a1256708038b8ed0b24c87a64506acb94a38b23c8752854fd8363614db29ee4f4b324480b1022c3434e065cc4569674d5cae0cc6af35837177670ade5d990001ef20fdcc397efda38d64704a6fa2ce6116a8538e1269af2be201ff5a3de7e8488b111dc576bc95c3b9c00163bcd86c82c95e0c0a5d19544488f30f662a0a560dd724c176f2776518c6c14ef9b7f9986d78eeafcf302d4b23a9f65fc561c9348657eac509d1fd4b7e80f3cdb5912a0cf3cc5a8e2115be1c9269c1d9ac21f6d36053dbb8bef4f89aa5123535e38d734e4ffcd8e3fe2852ce2ead9cf7b4d2aacf89ecb66b85a09c457ffaed105f7f327fc658f2a8ae8c90db797c72b53baf714f107ba0c80687a7b981342fc0ebbb235140fbc9b8eec6385ce58ea787a2d8e24e9a14fb3550d5db14db33adb02fdf1ae76738b087c73af09b8fc7f11bebfa912d13434994ad4ab58a948296a1baba8803fc63d8aff17c3cb3edf3515b428ebabbde9b6ed05a6e1b36fcddbef4f7d6e6b5c525e1dc8edbfe068aa4e1886dd3cb1233b2225033db465fc98ec2dd693b0d2552dc439b7cdc6a2e20b7fcd1bcd70282fd96a81f65cc136418913591ba85725fd679fc08f8ff2d860ea1febebd991b59e299ca5f65d10579fa41a7b972726d0355edbef99c1bf599f25292d7edcd6dd9ce915d4841ce043269ec34929d3e9af4e89082508f08819b851bcfded09e6fae6dc63752371418a91bf00dd474799d4212f833f317123b132bb73fc439ce37fdee918fba3e996d1629c8e7baa2366010ee752ce2af366c4f3ae9580ff93a5220fe5f8c09c2b17d12e7aacb6f38330c358b9351bb671cb69785e2dcb14314877f05fb760dde5c9989ba3543b17cb803c6c5c962488c2e06876bc34a5e022a865d1094b21e832b7e45bfd25fe111b7075ef135d0b21e8be2ecdef8f4b016eb0719a3bb9b3a5494eca1663608261e33a169950b0d556b8c0853c5bdd511f870ad10ec878de0f3cfa2b9e932c8eb4502c23b22d8b56539f1b6b5794535e94883768c62cf488fdff54546343ef03fe5788466e36420ff994614766cb6097bbfda021f7718e35cb91e26b83358102d8195f15258df4d0a5b7ac9f0aecfd4217989daafe4188e9bfe973ed22ee1cb80e5924eda0cf97500a7894ce69075114c6f57e9dfb0ff5b",
            "4e3fc2528c410f530eb994c2e191e11c5e732a87c46a73faabfdf81ca00dfbed07d715d8645e982ccc1f0f48be3efa6ce2edbca8ded7f3a4da786a0d21c2b531b77d1d1dc9b28a69e455dd7c3eb933824f1e17b0ef4f67e1e2baee5831d20553073ba2fec6245cdc918b7d535db1a3d001bb2758e397adc1a8ad0ac6001f658c88d1c2892936b8b5c0154d7b7d70b1cc01f756784270220482930102f2620eef456d2999d8cdf081bea29c9b8c844c1b7713d9f773feb24f639963bc2b69f474d1d1cfa77c5bfb0bf96bf1df3a361df87b201612637f7335656d2b35d96f31a76dfcdf996164054343d458f28bbbe079a565cbb5ee0657ad55155ff4f2e792fb2b4c79e4a8018b9b21e09d7183e0a0299aaa2df166a8218f649b906db1baa56af2723f02feb761bf64ba6bfa1221968c8c4e23c73a4e6c9ea91d28986a10f1d14e59c7fa2beab761bf25f5f50a52ed043e8e9e24b54b3ac9e89189e4f8147e986f18cfd2d08cafa7aacdeaabe8c2886b080b2d0b58685bc044c318e6dae6b0d0b1808ab402327b64f1270e9d06335da3f6b2e2bfcb717ea903860839c72f7e5a0664b165b46082aa3b4e070f0419b54eb0d338b6a5caacfd1d63451529e6bfef99016db91a596d57ed9b3a32e22d75ab7bf3ef6def86eb674a41de6fc0fd7219940df6a7f16938a6261aa3bf8f02064469a1b4a02b0e1f5a8b9b4727213d5013165eb928de4d306133417cf60538866fa4be091e9df6c23eb6167d32c6e2dc929ef0d457869ae920d8052d834bf85a3885ae8253f84ae83815415ec50ba93e5c548ff2c2db075b29e778027ed375f01ecd42d3bd22b0f7a6f2dfdd5b4e268dec49cc3555ee52523740478251e9e1672f8a64ff38cfab5493e4107b7d19dea7fa50dcde68890fdb8c70769e21924d187435e6a09f8d382a3ac8a03a5916970b94f9bc8dfa64e128937a75690977eed7bc9e4e3b865fe6c108480e879ce8c4c98f55ff0dfbdb3491900d2cf4156afe280e2b982d2620051c7ccce008c80006c7a338f78ca519d958ed1fb6cfb5617f54daadb16b33ee4fe0e6df98ab35e297d2febdaf16188d3c552c4e9856f1286c9c7bcd3594c9d471a3c9a74ff7f8e46db9e09755413852ec860d6343318cf2e7080b25f8986a626745776c1f69874c170619deaa48f7e6222f54156bfa69e2d4046344dbaac3c5cc0c31cefa1815a78d83d31cf1ee7817905b49e0d77aa3f9123d36de074b088fbcde45f64ef77f6bafad1220f1650c59c401bec1fd565e56d38aaa3d78470c29f6df69613fec89fcbcf34bcee4eb3cc0b63cd61fe7a209c7ec67bbea71ef5a69a88c3155559473d0d414fb8d23fc65cdeb3aad76f2e464952d9f7c0ec6eba5d6b8ded9804ce9ac41f8fbcdf9e430174d573b81ffbc0b04478d80f3b43ecbccf031479f47469b90ed71ba33b8f27ffafcff6febfa366c209b84fbbe94f72ce0dd1ab484cd54b4e5cf308820bd75ddc74bb413fb16fb93a9bf35d733227de3fba25348279eb99eb1405d5e89559196075756093aca1ab0d4b184adbe3d6cf46c61ad6b036b3d1b58e959c240551f4aed149093360a4ba66fe005b987112773bb7c7989d6ef90fa83aed0a4fe2c5cd78c2cb58c614bd43c712d3e173b530a305acf8b3fdec08f846b9876939414fbb68f70fe8b306104fde5a4a08f2b9fdc1e89ad93ddf161bb359e5468626e820c3616476054ac160a536c71e5f0401a5b56b7e6f2c9ab1a14454a43d5b807f236023d0b6fc3396e3bac43b7c123e11882d2aec0abfb09b877398d80d8a9703737829ecb4cb8456d8663d0623850b70d5c004bff72d8862c02d77a1474d4cd9111c0c5bc9e06787b6925c03e06fb74163edf9a88174706e2e399412cb95fc8bf71389764a778134b3585c78a0cb3887ab232c304698a335a86b2a200f71d6b6bd7e5940cb784b9abf0c84b5fdcdf6d87979bcc7067bd39bc1519b8ca3370a7eea7cc20dd4e02fb8629e175a51a9f6c3520dbcb5d5e692b4adb51c1a3e7a12ab37fa633434ec570e667187dc5c3bfc4281dea35097a0c393e84e1915d622c7f1e070d59942f50fd4f8671d8a6143112a6ce246889ff90390031667cebdc7dedf8bae12fa7d497cf18f9749af075ed993716184edc3951eaceeed9c2bf07d37ef5b14b7820b971f554eb58dadb5f166173a13786862823c94901c9619e189d3d0ea347cd414aa435a6271920c0400e4931a13854918458271df8b8f821c6c31a69415cf8d8986370bf1c640dcc47d7e86e8870b2c3d0f6fa38b5a227c89be5609b6f832f104020a8c7e7e79bf99f8f7621078bbd3fba1aaa0549fd77ef15209c6b27cce77fabeb25484debf9dce6cb897c7c9891c23beedea6fd39dfc9ef0bb95cae81bae6c968578b96e1c1fa24de517b80bea2625bb97ebbcf851843c824e1d74e4a351390e67808de86e0e51c6b3c1b602220fb4d59526308de9d812d02f21c82fa6408ee38a2b92e0c2f86ea8037dd9847c69a900d31ba05b2d2b2adbadaf5cf1f5ba60b75ffd4f619cd64cc3ee429dab2c3345c5ba618463cb350d4e07e73fd24e175a11e0124ab4f36cfc9cc0e8a52d250935784819a0e0c35f45b8f46ea06b0a2986fa563ddca011c0c9d280fb08386bc1aac4c2cb063eb2e9c3f7607a13e51024b43bb96f6deed6fa9c9cb7dbb10c684bacad778c44b34706859611ec5aeb58c42ae89371cda71597f1553582a6abdd7955318a025ff57f39c7ee67d4bbee82ec2a8d2e3533b4d05bc393d58409a5662f7da49288c92c6d84e5aa89adc1b5b8bc3513dc21a2fb704e3d1e628dc3b360dcd6f6ee2589129cc0c3c3162fb7b642c7a85ce636f2122fb17742e7c8ca4d2a7f0e9711a6e1df6c3bdd32118",
            "b815c32268155c2337c32178291c4396c12e70212cfdca6141dd2ab002065ee5b0360fc49d5d89989a1382d1115c5c5d9904de8dd168b83c126f4f0dc787ba6cb6f1720e9a2f670bc8e319fcc777979139c54349af0ec1c4dbc68298a92a9ed7979190d5d6d61621fef7fbe828ca9388a3812cafa1c6046f4f3be3c10e6fbcbf9b88601d4978283008e632a0d88c7055067d4cc55057a88ecfabb5a856b122fb56f8fea22ddf4ef3ebbdfac4a90bf37dadb15532fdcb6b4e543ddd1d6ac990c71339cde4bc988077529c471673408a39e4e5400e591acc698ad4e21cb49465fc6ce47fc8bd8185da5ff87faf1af5a894dc25a76b739e4f9d3ef0d789a57d2fe59b4db93645d1cccc6389702ff7c923e228ec3fe713c13dec99d30d83bd24116baf8d01c9e958b1fa18ce5ce2a3b6f621b66e3c829e1dba826a18a4a5a4e1d5c3cbb836c79bcd8a3644f690719830b204f1313dd0af473acaa755a172d6622caf5c85f9b3966048ea10747034c2acf40034d53fa0dc9cc5dbf3b9b839cf06e7cb5cf84f3686901de33d3fd86a2b79ab48ff9073c9ffe5fadaf0fb357d6627c7eba952176a7c612e607cfd569f940f9bccbfe87e92f06d7b143ec324538e616afdec4cf86373fb926db30793b363bdc9a808c341ea32f27ffc2e1a78d45295d4d44edb48b523259df505e4635ff0793d29fe47e3f9680b342e32075b6b01fe5d5f08c88116818040d0301244908dfa59d6789fad0ffe12133e9964462ac3b57b3362d27f663ddad6963a0a313dd1ca9bf29623386adb1d43551c7863b4fdc8505def39f2d2adb25f464f4f6fae82b434e91412cbcfed97cb1a6a684345460eba2aead0a1aecfd5860157a7f568ae65de8af7f6060e30563381aa0c1786eabae815d70587371fc4a1edc7d12d3a0576264e70307763433dda934017bf5aae825cb89cb8f84cfa7d9fec8d4defda1b192f9110675a465b05e2904302a69b05c3494e93eda8698f6eba9e6f74e5955dbe3c72f1777148474646e6bf010f5ab57fc9607ffebd6d3db16e5626f84f2a71e7781ece1d5d8d43331250d9531da3a2d5d1c14101693eb25897a686f7bbc25bf3fe7da61cc47942b0fc4123b2b7128cda2e4046c573b8753e0297d8bd708f3f01efb8d908f0f7a63a7f15c5fde514ff97b77200ab8079add86f4edd32701ef4bd17c1d33910fc3ba3c1366cc5a251c1e8e7cdc5a65c67d4d7f4679b6f8e667937f2c0bb3a0c82670b689cabc3a7ab45ecdbbad1fcd797a7f23edead425956a4802bc6b8d969298a10fffbf59da5d14e8c98284af21eadd604396b8a5fb67b83b0c548f4d684a314c306723948d0e520cf9a41b605832c3306270be8b5c71c79e45e20d9bac4f7ac5a3b71d9d858e6dbfca8d0fc68f0ab2ff664c8a7199c4672468c2527a9945ac72177467104d3833827c23499914a0c63f32363c9d7bc7fa0df858182751f57f309ee9393e470ede08745d645b78b54f518c563065c15b2a68896d79b1cf6c1a9721444a9a0a3b51c0653ac5ebbf1021e3f2778fe96a0f6d44b6c5c77103bb79ec4a431d391939e02014bf0b8663a8e8cd14755ba29fa53cc5f326f25aa28d657cc58dc8aff425f50b618dbd6efc4c923e75077ee2a4af2066354ac313e3eda8c8673dd7179b613c57f579c9fe52278b42a982cca747da1af2c6f6ca0a9c430ff3d7b6ab5e5ed55374428fa9dcad6defc60b1637edd641385e3b9bf49529993594c9bee6fcb61c97ce5cacf12a383c9e665e3c8bb97b52def2e2c6cbc39d985ccee66bc4a535ea1edf3a60c233580aba2b2c34d4fe575bca12229b45322a7c7ba0848631e5896c62bf443e3f5383ccb30c5bbf916109cb507ffbe438ba0792af546805c44e3f1ce7892ac8ac65c33342f3201293021e9362ace928cac54a619a361a229f7a7ccfb273009428dfdc84a49bde569f60601c95a831ac3480cd774e74fd60d223db4ec7b3392adf5205ceb2ab03234621f5cbccf86fa0482fe4db15e135aca5ce828abb7627f6b0e404daf55fb0b3900575e15ce36b6183d6820d6cf998f15d3e6a277a75e88f08847f7880c783b04c0cdda1bce961e6c5c603cb137b6265c0579326e4826595e5c46bab7ef408ce9776c774fc236c72e08573181a7929ea0839613493589b8a62bafd4c66338df1c579b2aa82ed49753fe19f972db98ab9c832673434352ac25bfab95202b440b39d1fa787f7b1c048fe760e33017743467a0cd3587925e1f68384e859a4309823c4271789c0a82daa7e3c0078273cd4d38c6e363cd73a0cfcc7b708cda07b7b87df049380c93c0dd983b3d09d9bdbda0e5b0002e612b611fb414d6819554f353fcf79f0733ea564115f4de6518911a4eb1e800de5e9886a6f303716e4d12fafaeba0205a075757c6e2e3b57c96bc59095e432d8e2c4ac4d6e2105cd9d81bb7b626e3eaf26876419a658b9eb4788491ac68caf3dfc0ff717af2124457528c575bc20539a987975bcc419a96a2243f0ae60c870dd710473f230ef26d3818497da21307252e1c1c2d35c3c3b91abce65d7664ee38c70ded188e305eb6e525a37c15980f4b82392c29620859c821f593c5c8b6eecc95d14eccc44825c649f2afdbe08f884162e3c97861be636dcf8763c809b2971c6dda3123e78e30a5295cabac5467aaa94af697b936937b1d7170862b7ada3048ed108ed5eb8ee1f4b9d7a87fc307557cb87efb1df6ecbb825ddb4f6261f95a8c1a968d4f9f1b21687c813bcbfd71b1cc1a35134c90d23112f3ca9663fef44558386739e502abb0a47c055654aec6e2d98b5177f27cebbe5a422fc81c8aec1853345dcdc3c3159eb852ee81e3539db1678c2dffd6824032a6abf571ae8c6cbb84049b9f7daeac",
            "b08ec4be62ffd0db65e6376eccb66bf97033f1d0d32dad397eb94b2b1cace9eb26b5f9065f79c26f3c56f89cc5b3be964664f38a2a82a63a3e210ff8efaf6f111ccb77683936cee59e9fa99a50f88753dcaf763552f934c08d4b16056a9243317ae4fa50537ee391ae02424ac063f3c16f1a09968cc0db456eec9301d6783ccb0c386b0dc1354f08def56ec57ef6f10c3cca90c39b34137cca32e6936926e4660fbdebae1aad1c63aea19282b7a98ac29f2ea67ce54ae5b29292646354167f5ffc380c30f743b54d07146879f227ea0592046ddb9e14ff853c41f83ccbcd721262644ace58feedd397d039260eeaf24a54fbabb5eaff2fda5f07a69ac630d53285969232e64c2dc1db972f7078cb366424a5c2d3de075e14f3e382bb23313203012e1170a1f8efe3140c434d6381a9ae9e604ec1247ef5bc056c97b018818b9d273fc9ca072b1ce211a36c021f450304a99a2150cd921d619bc8fa685a877efd3dc224453b9b2ff2646928d7880c37f419a32afbd33d83a1edb7e89baa487fd66e27dee2ae23cb2ecdb0c4c5959d28166c446d592082f42520a7d39d62f83ad844ee815bd75a78f5a883754c0d2ccdc3d06bd2116cfb44f19f0870f493003d8a2ec3366c0f3c3b1da0be0f4ed13508ec3209cd37a2d133c419fa1ecbe112ba9cb50ea88425d5fe5681f3611130ff0bfe072f86aa7936f6ef2bc7e7fa7db8b0b62bae6de98de6db0578b6bb3bc676314677672554f4b7c59d836351551086bdeb0a707c7567540d73c4c9aa781c9ae4c52e1fe6488ce424a30d45f8ffb7f07f91868c043195e6f0960e50a5f86f85cf3b55407eadc4e9137b602ec1a0bd8618a8dec0282b0e26d97330dd9d8325e11cccf26470345309b7262af33e569b91e149da63beded3cb5e8121eb855bde8d60c8bdbe9c97e5fecca2647d26c4e4f773ce8431b96d8e60db7c811f699f9ab6fdfa0c120ea4bf1af87a0a296a9c9f9778b9757d9faa8d97d759736d5572648e2b8fdc8a65d7e69a23ce520945634b70ed6e13b66daba3f8ff1ccd3c80cf17e0d19346d49efc059ba8fecf1d3c0c2f1f9f0479391ff51727e0e92a5bbcddea8cb7d58ec8ecec8ca913ab28eeafc0b2ca3558b37413766fd98b0d2b36e1f0de2368f8dc80a6a626ecdfbe0745a3a6a2737018a667b84050d70f4726daa3284a0d8511ca58d8c78077aa3480c439eb8e5194f8a9c7015ac7fa09699d7f39fbfdf96e04d73a93a6e7452d844c6ffc74a747edab4301eb7f5deb3ce3ce1ccbd423b97adc03f93a6d759b4c1be4a7b48438f2ecd1031ea5542cfbee023e3ebb86e333e305779625b614f5b45f4daf5be365a14f4a7b1a907b23f4c9a75c33fec7398efc86a3ed59f66321c5fb79e0f34641d0bca84540f6520a11897a5a178f4639e1d15c23907356e0d539038f7d21f875001e646ae0798a013e0c34c6c76c637e439621667aa94fe470e4a6396b2ac2d7485957f5cf958f6e6b3b3d1425a59160e2c62f748a87bd9c0eac14f410a16e8909fa7ebc4914fffbe8386489c9fc069f1952620c0976f4e2ad9bbb18f327cda0ba5f95e23cb7750cc080ea7e03355d98681a4253491d8ee616583665168af346d1731778d878c1cf2508b1815d29fe27a073586f44fa7681bb9d0f0c358c606f6a8cbd4b9761e58cd96c8c5f3892a27ba163706724fb774467ef6884daf9c1dfd0119eaaa6f0533117f4340a6ec975e8f5c85449e3db9ca41ac3c83f8e3672e5ef72eedb1ca36a624399412b9ffc99c6c4be1ea7a9723824c44c997facc403ef2e8ec483a3d330d05b168aba5d611b7d10d6e1dbe1d8e1005c3bd7c029ee003a143c4444de7d8cd8c647e9b106e4ae7f8998e1176043b1dfabf341b877d807ef2e4760e2bd1cd53b8703c73d10ede90e639fd5700e5906ab800aaafbbf60bfb9f03c701e74dd17a043cfb1f870b504d5c3ac30ab9b161624eb63d5202bec18e382f3737d911eaa8bf34b3b615dbe23aeee4ea07ae725c885be6cf55055cce96b8d336501583cc4b1c5405622dc584e4a84f8dfc9f9508d734a595c9c74b110e34f8b93c787dd8660efa440f0a8b085d7f808315ed6f09261906d29862c730e3b8d6aff722f0ed6c4896161000733dd3838335295bd3f95cbaf5fa74f229ce4c2855a2a5c93595fe6cc9c9fe7ce0c88e2329a7ff86ee11c01619ea0ed39273f6eee9fb42ac4f8842b5924b5694a61f7ebb9ad5ab2d7b4f0433a8a8a64468a398fd4c560c1406336d2d600d34b97e2cc8537983d6d1e96546dc0959b0d2d0d8dfcd631fafb0f5e61cfae3a8c1c9a871b97e683bccd05ef762a9e1fccc09b6a2b5cacb4c78559348e261a61f488a954f3af42d59c6558b5701d6af61cc3aa452b70ecd0d156dd5fb36b1fa6174ec78821f9c81d36968df3f1c68e99c15831d004557d74706aba1deeaf70636f2ff213acc9766f305757b2d05150f8599fcb2cdc87a115fb1baf4da6c553db24109ca2c7cb02debb199b1a6ff4e8f862a7bfe29df1aa7fd443a3857363ca268c6921bc5754f337a0e1f1294ad63ee0f6d6a2965373527067e730b818a9b5f48cf6228fd605b264be3e5fb03a806d7e9001b641b8bff9250804afc16faea4c7a52d02c13e081e26a071853d9a57fbe27ea1039e2dd2a571cb06e49e1b3e9d0ac4c5142d3c4bd1673f0d37c53b8affef334d5aeabaeaf04d65e59eb8182a915d8374af245829fd5902dab77cbd8bba8c4ca3be821271e2ea1333255d786ada2148d3015e145f3b6858f38bf583498ebec70a4519a9687a7da19294640115042d11ee7e8211c99988f38b04574e0ebaaaead0168e0150ccd753d586b186017d5d19416e5e281c34121d02a3e1e7ec8f10cf70c40476414c4057",
            "84784421d03584e27f243c6d5c61a2af879b972fe3f1f9b348eddc1da306162227752486f71e81e17d4762445a01b2fb8e64fb270c42a7b06ef03275810fd7821d66dd858c71e9f7ca5ad560908c9458b8b69cea0949ca5116c416362fb04e24b9ba9e0bcd14b90cf3733d8bf9b7f960c2f51a23e34d794fb644e3d39d45583b22004e0606d0f35d07abb01d54fbef825f9f0bf0ee750109a5ef90590d0cdb46d063f60b78743f06dbc883ac43cc7ed6bdf321b877dc0feff8fdb0093f8c5ee999201f32707fae06227c8260eab7168e218ba9f6afa0da7f012c032b29fe57d2e30268bbcec4b821a128ecc88587910e2cf42c29073445a8851a4ae2b53029561b73460481bc2f4759ba3d9eafb3c7b33576ecbdd9c6a8e8ad8ef2343b8aff81647e863d4f4f5ac2d35c41b4d4e90fd82f346d5735e6bd22c5ffa20869768a9f246a1698b63e9fa1e1dd0d90a66d58b362092c3842fc17c740130e8aec192c0fe260659818cadd19b6cc9541a5bf38ae4d5617d4576ab65caad07e62c295509397fff2ccb33f60be70af80efeda1a6c5b43eeb9cc9916398ed06924ca2addc0f518e6df83fa7c3f561c73add1cd66e03239c3f46562948c89055554378d797c4625c7b05c479bb62c1fc8d58bdba866a973e5858568c13a71ee1f53b7eeb9699cf5ef070fce413ca0be663f7c621f4b545e03796a1f9dd363cdf118b834586a848d462b765ea63519a36b232466071f96acc9e5a89aad94bb17fc721ecdf5983d42e1db175ed4a54afaac6c49193299728c0d471d3302c23175dbdcc70796510d8e3219483533fecce7e3ae4cfbf30278c0c8d345baf2a25fb33e60084f3f784c7ccfa33dd68d5ec6659f29c1e5fece33f29f77ab12dec77d76e48602417a4b78e609518284891758b2a29ee7f663f3f3d8f77776b20f8fc126fef1fc7998afe78b07302ceef1b83b913fa82d4c5f3c9325d341c8a83804c012b28a65a7f19c5fccf2d7c41333d9e03fb6921048fdb4370291cfcdb1d80bbb1b8926f8acfbb8d415ef8e2f946279c4c50c7eb210668caa3d83fc8887d3bc8184ffa1820df411923a2355bdeae34674fa4ea2dd69696ff33c591b6a13c5b4d3939a1878b8b338ff414555a3cb41cd81e06c108e7dac043c508dd35ed31dd2898e7a8a84e7c9ddc4927bff62d2ab2b268ef118871197908f70c808a8c0c34155529fe6bc0d1cc0186ea7af45c9de2bf3c52e37b50fccf457bbf08f852fc0f740f436c5017aaff3b20292a0903ba0d407ad77498e91961fbcac5209fdea3302717a3074fc0feeab3d8b0f830164edf8859858b3139671626e7cec5caf93b316ad04444f977849b852bfc346c0533dd8791a9d403749c88723b0932d02591bd95b14f3042c7b365a241d09b303513f59f10138431fb9489a214a99913ceff7c3e0bcfce54604aac22742cfbc332f2002c8236c227e5220232eec2d233139dc61e40efa50431f97741311f2e1d0ec12dfe30ebdae920f543ac2bd5fe5ef1b5b0f49981cbe753d1703d9162851c2202a26046f1df8ee2bd55c002580756510e50d58afd16810b61ee5b067db38e50321e0235bb29d0742a81baf548486b76868eba3586052aa372b81f78efd663d7fc788c8ae1626ba61a4a3b2a20c54b15bbc67ab0478a7d48c540c7cfba52e23636aaed44a8fffb5c8fb0bebb09f7fdd3931317acef238b3dfda430a7972a58fe21f0052c04f53bd1fc7a3662dcd4d1559d83746331e45b73b03a9043b19f83d9ae1cccf5e060960b839ddda5f1a45c9d47b6a893e5594a6ba4be840621d6ff717f94d67126a156a0a03fd34d96391eadc3d4f73567c858570e5915c221f49e874da47f9071b3f1ad3f7445a7ba21c1ddf60e14be365146528e940c75e711528a23157148f477c1d225dbb078c136ac28cf44d5a4546cdf7e16bffcdad8aad51f3efe8c0d9bea30ad7429fac4bae1ec0c475c5d16087ed31acac1aee344b927e67456c3da017aa89b6681c503d4d03526094b2ab752ec5f869554ffbf785e8fcb75d73061c448cccc0942c5f43998386a2a0ab2276076c97ccc9c340b89911db1a22804e45a1734ec7743d3d964cac78fe0fec162c1f61cbb1677638d10ae94dccfc401dad6f6b9df5fe9ddc87f9a4a48f3a057ecdbd17d7937fb7ec30f3608d703b4e673bfeef15fac443550c5f462e11a4df6d5ad837875733fde3da0da9f6dc2ed1d25b8b072349e9d2843c3eb5d201793c05fa189a6ddc1604909044d4320e0f5a398bf9aeafd37f42327685fca015b9f06c1bbe5e0f366d37a1f8797c7e370b7540fe44d28ee965be1741f357c9e650cc134337c18daaafbf1668031eef6d1c7fdb1fa20abcdf86cb109e96fa5122a2e25f79fc68ab63652a82e23e7aa2dfb578bac7768c8c99304a3507e96455784abd921806b41398031a235ed5be2755cd8f6ce813c07636ba8cac9b1bd22bb233f75187c1d5ca1242d0b270b07746ddf01837be621b77f11ba4725c3c5d21665b96391d12d058ee6ce88098ec184dc69282b988792ec29c8ea330c1d83a2a1afae45757d1f3c3d750c1b2ae6209662cdd4fc726c5a7a04174f3dc1a5d32f70f5dc0b9c39fc08974fbdc1cc090bd1392409ddc293d131a43b9ccd9c91641ac1461b78f3fd759c0485de830477071cc7c1e852365fdd995f6a184252b51c7bc9c949fe2c78d096efb2a5ceebe16fd8d270a237dbf8722b1eefcc442f5f5d6879ada41a7e3b5cba1c4578ce13c44f039cbb2cc498be2688e95d0ca3a023f0e9751e6e9d0fb3ce1d85f87f9875a11cc0bb7b2d8c7d37a2708250d32cc6832d1dd8eb13da21c23f4aa8ff595bff0a580b9d72002be1fa3fca01ac832917085a0ce3a0cdb00a5bcb9afacc8789",
            "6f050c5ca740cb7210e4f57ad13a36439a8b24b6960fa51c6f13d6148622bbab0d26a638e1c4fc48d44cf1626b4bfdc8d4649bd71ae21c6d5703d12600dfa9ef6a050e874458b6e33d2896c3a74d5c54766270627d512b2e35363ca7b1a91847d77ac34e8a415f43310cb7e0a0d283c316d9322871e2a0d491038ad9d81ecbe0428e1c9a562bf1c92e0592e4d3aed337b14288e6017a0c33294e9ba9cdb463decd8a60c8b6340eb93d89211fe7d1303d478c25059c2692cd615ff412bbeb20cfc869fe1865299bbe3d7d50d77dadd8dffaccb67e51c67c723c82bdbc260ac393a2b164e1662c28df802d1b66a0765d3ae616cfc689938f70f4e875ac5c3c1fcb17e6a0766b1aceaef6674b7aa823cd57158747e9e2d3b3fd78fbcb0ecceeae8185bd74b1678c09fa066920c94793f63b2f8c1a9242317e12eeddf9150fee3cc49e2dbb28ee2fc2ae3569583323916aff89282d9c8e59c5e5a89cb99072812224073be1f5b9a12c79359fe2d3a3d6e7757c7e7f857fa12c941474b63ac19591a31a3841ec27c27f09323ef0f4dbfd01849cf7d9d370d0dee8dd5aa5afef91367ef0ed9a15aaadc549afe81021f6e3dd93cb7879e300841c80dff01a1f9e5cc2b58d0578525b819757b7a0f1d258f0aa8dd0bcce068227c32168cca2d83f946aff3954efaf04fb3a97be1e47717f1ce502cf2060af81cf3f03defbb978bac105efeb7c70b1d408372773819d14fbab4cd040ebb92197fa08537c1e6186e6124bb013f4f8649a35d9dfdfe4a0a9a26cebbe42e3fff3f163bc99a21adf46454b5551f1779c3180fa47373533769c7d5f76846517c4693a21867aa8ba2ddcd42ce1a9690b73592d58519dde23aa1bc2dd8391979209372b7be8aa6aa07af15254144ea67adc11299d0721d2af03d2ba74c3e249c5488a4bc0c259f3f1f1f5273cbcf11625a3a7c1d7c90dda2aca90601878dadb6243d95ceca85c8094f878f4ead00fe332a76162d62c2c995d8dabe71fe0fcc9bb785f4fb0b47c0dba85f542ff84a16c624c2ac27d63e161ee8a087d0f64daf7c4f2d012d4f5d88d2743ce62954d12c66979f1661b86b44c320a5869a4a8f2b3e5fe47d3404d362de8c123bcadb42d3fc2ddc5aeb0b78b8549d87e8ac5d5683ff239e2a736a273f17bb8663c45d78830bcaa71c380dc8130f2590ed76e57e09d78126e9d0ec2ab6b0dec638f23287a243ebcdf41fbc441346cb7635f2d90a1e5dc1e66011b581bff0ad6da6f3e3dce876df04258872c87bee732e8782c81835f1674ec73297f5808438f59d0b2c9a63e1c9ae60320a31183087359ec9bd91d0f8e14e0cee66e7872201d756b7ae0c0ec48ec9be829383f279864b637baa24a83f2f8f13622d4fffd789d998dba5483b2a4387283dab107b2147168b20db68d74c3f4282eea1f9da5d0701b8d47da833ceb8fc2e1fe70e630186e2dce4eb1e7a0c09ac1043b0e2aa8fedfdd490c7503383892c8c18bf276027248a2e55a95e47d3d7971293333c6364e85b939cb93d372844aaca7390c69a9e4b064bf7833b922d1446e89f3c8617101af84c3360c65d8e63486bceec9a9f75165747f90f2948d1d1fab3ef9c264e19aafd741b69ab859e521b85ce98cacc430ac58ba95eafe6a8ac1a3c0bb9d8cb593c330327b1ae6964ec6e60da3f1f0d2303cdc1387b5e33c519ce68f9ca470843a9a60f72843343cde8c43b36230315c0ed5392648f45246173b05ec2ff162c9e554343d99863d3b1661e1dc72ac5f5e8d93078e63cc88493859dd0d2ff6866368cf6e983f6329664d9e838a1955ad79825e9151342e0efdc2ef9e6d42e3dda968ba918bab6b7b0a768d7227ee261a1db932f23f430ea06dbfbeb407153684dde438fb4ea9695bbeba6d9f9fdfe25fe09724d52c575343929fde8b77aeb6869651335eb462ff617c7a71b3b5cc7e3dbd1acfcf54e1ddeddd7879610d9a0f7a81bfcd0afcc32110bca4b8df3886c6b902083e501ef0aa0f044fbb82ff722404fc67e0372da7f8bf8ede67153e9c4fc3cd75c1385bac8f172b34418e1a81bfc504bc6586e05719833fd71cbc524b340bb9c0407534cff763eb2b02f909264a4eb4c9fd27eba7ed7b7d242418d2dbdcfb76a09645db6b3a5c8659aa2223f32158c799ccf6ce6297058cc530f3383656c381f5e69ac1504115ba0a2a3050e22221ac23668c988182b4b1c84dcf47695e11fc1dddb07062316e1fad454eaf01e813db15861a8688f20bc0dec58bb06ef65cfade7190f71fb07ad95284f8f8c244cf04aeb69e70b571878a9c1c668fcac78ef2cad663907b20b2520b90d3bf1023d2c6217fc0240c49ce4351f62c6c58ba1ffdbb0d466ad210c407754192631cf29dfaa0c26714b646ccc3fed86538df7b3b5e0e3986abdd16628b5967ac318d162c37694f2a4cc3afbaa86aff2c0900e198a51017ceba18e990572f8e085ad70fd5efc78ed15ad07228a6d8bf0b5e2967d179261f01036fc125e1389c3a1d879af33c54e7a9d16b3b61437526bc22f26019b1173e3deae0dee5046cfdc6e1dab95290e6127cbcd50f0fe76bb0a446095d23fd61e8b58e750c5dcada052d634dbc9741cb7909741d4bd0be471e2a8a6329e7b3839aed0498f855d1d7c7b15a56c3a16d9f0f4deb6cc8a985624a7763fc7a3003b7b6f5a69cbc2766a4d8a3bfa71a32fc34312ace84bfafc81bb1f66ad5aaa227007cafff4ed3959324263262bcd5fde4f172872578cf0b696c7a8d27d74f627f55017877b3c15faf8ae66de6687a3d0bd17e0ee8aec2b0c58e621865cdc15c770eed271c9ce82b868763c4f0799618aee58be1e32a864f2e48908949ed3229ddd0e9c065c8c1580ee16573c8db3c86bc2de290f73338a4",
            "698118c10a2ac19689b590528e80e4729ac95046d0dc9bf3d44b85f911c6d7385fb0a3558b9d30d152257b27bbf21f2c72445e77672c5dbc955db978335b32710e6ae6058077c01b8f36f961fdec4ea8afbf48b1610d768eb1c5f0cea1289e300fcb97eec392c5079091948813d3ccf0eefa3c2c4831a6da5f1b337aeac0d9c20e69dd7b61606222d2db5be3e492beb4be9ee3f52f0b31675c270c4c1f8be2d109a8df1d8c5f963a6156860ba616cdc582b22a2c9cbd047bb71ec0d4712518951207d27812aff684e3da1c4b5c9d638bbb9b3bf34f970691e13116bb9425a5bfd5783fa6ee1fdf3a3f5beed234cd7737a69a2ebe5af8db9a3eb1aff34d397fd0fde994f590e5f367f1ce1ed88c4f1f3ee0e3f31b7875fb083e3ebb0c1600afe10d5e9c5e888647fbf0e65e2dde9d2e045be304de4e57f04f8441f03c13029451fc9f00c1278af9ef87837d439dff02f8500ed23418cd2fd2f07077242ecc74c6bd0a6d088e9a819c15f20723b0870de9fd8c21d86f06c106ca038a55d05c4479c1910cfec7ed3d49953f779981e2176ef61f9c7746dbfa78610c39e6a0aa43663bf77ceba14e593ec308e7f35de12a28902cc79e2dfb3a55b2a51e839164180457552368ca2a4051561a6614ab4db58da1a7ae09574b07c407c7b04ba6af666f1c7f88b5158bb1b4642a762c5b8554aaf5270dcec5c83e990875f746d5a449d8317f318e6fdc864d8b96b061940f389ad823d23b161d42baa1634412fc5c23d0312404c756adc0c9b5ab91919080a8804eecf0be6330a8673686f5cdc7e05e391890341c4539332927188bd4e8540c73ef89c5de23b0ab7d29aac326636dc8582c09cc45a56f26d53769c834f247b4aa258619f961a75d3cbbcfaa135961d6fe79a89ad1cf3007a0ad9f3b50176424766de5b94d2c012ee66240b405b47c36c3367217a20a9ec3b7ff553876ac815dec41d8c5ec8371c431440547e2dd724590cf73685cdb80fc516954cb572028f5068cdd2660e1f4409087feb8b3c60e178b54b136470de60e09b00a5a0303d719d0771c0bffa8e1c81f938463c7faa0fe0ce56c1d8da1603e06a67e0b61207c26904d16b4edf2a0659b0d4593c1b030f0c0d985e178722c87bdbda527e6a4396264a42ea62599232fda901d16aad7186dab4acc14da15eacb88d6fefd41fb6b05dac8d6cb331ca4fbc8b0e48006c893c1b4de5fa099ff0ae4ed7caa6de6e050790cb0cb189f9673c1dfe58047b747c1cf5411c38d19547a71b02a9083f56162d8d9510cc7933878522486c7d339b838508c7d572581671b249f5aa98869686a323d3a6a30633aeb30c5dd0c988509fa4c75820153dbdb9c733ddd96793ed89ee1e7ba71c8741f0ed918c221ebfc39772ce5fed4fb9bfe914be5b713932693536d78bcddfe284936c584d13330aba412b3a6afc1bc826e785bed820f7b4371adca0e9fae17a0e9e9369c9a6c86098392b073df7d9c3cf508fbf79cc3dad54730b26f183eee0fc283bdfdb0b0873a76e4182125581fbdba0dc0da251b7170cf095cb8700769d1be5897e70cf2cb307c3ae8893d9541787720029ff6f9e3f27c776c1c6e89b143b3b0b26a1d362edf8c1335a771684f2dd23bc7e3d9f9523451edfa780df595ae68a4f875634968cbd631de8dc6aa8a26064a3fec9e40dfae27493d3fdef0faf97146adcf9317eef5fb757cff5bfc146a1fe13ebe9fb3faa7b0fccff5ecf5133b41048d7871b3061fa9ee07457f96e5a1f1d5757cb8bd198d4f6bf1fe975a349e4c46734df097397fb5be54f39780cf9f0b016f2afd4809041ff3c1fb70b1a5f1c912d41f77c7f5c536383d460b37a7e9a1a1da18e4980570d20a82f3ae105c0b82e0a6170417e9f91917ca0b02c1bf3a8ade7319fb6a63225bd741ed6d7b635523464ae93fb9eeacedf9395e8c706f3f4337b6dc39adc547c5e2b186a20209f38d22637c87f08e755fcaa65987b1b672ead0975781929c3454e5e5e162ee02772b0fd8195ba3bd4f3402dd43a1c7d542d7984ed8b76907564e2fc3fe0deb9168ed8e0e92aa488d4fc0c2c29998913311c9b1f158515a8691e903616b648d6e113d302c7904d2ba0e445c6017740eeb01073367ac993d1d97776cc381258b10e3178ad4ae8331b0474eebb17ff761c848ccc2f0bea3313c750c223d23d1d93c00bd6cc2d8f6862eaca38a2eace5d5e0a9ac8f08ae0592d59d90c475442897febf1ab6f0533547376d07b6da2696ecb2ebf0babd86b1cecf96fb5fbf6c094f88ffbc863b78b83a14aeced1300ed90be7f843f0e97b058e9d8ec03eee106c630ec2266a2f1c3a1e879167094e4c5541e35e57900f94039cf08099733a6c626aa1ef3a1b39037d409e77c2d5b9e6ecae4c1968e8b68749f056a8db4e4266563ece9c9987cfcf7b517e9c8a8f87bc3026920b69c36114fbab60e435177ace93a8e6cfa2d89f070df37e90d2ee8b942837bcafcb661fecc94075a10fe6269bb107277a6051ba359b13ae0b2f5d39a2272d71d6484ed2c45c494a9401f83d5ecde44a7288ad8e14fff55663349df3c5b3db4bf0e6c9351af7ae4370c80ea4c61e17967be3c8382ec83603bc98ab08fe3e2b9cdee4011fae38ca9c1994b909d70070d8d5be0c360432d812ccc1d91406570689e1fa10093e7f553b3221b1ddf0bf13ae849332850b6984cffd8aa09e21c3308b7424987c0bd91fa2df88272408f77a633e863969b31f7604b25b461a61709f0c144f9c87d289e528a6fafb64a51bd8ba3094a51ab271d6cac88e36c0fe316678bcce0b7b570cc3ae3d7771f4e8afecd9b3af306bce466c2fd247c3613fd49679e3e0085d9c9e6288783f6b4c9f341f3b36eec2cd6b942f9c388badeb27",
            "e1e67a5f7cbe9243fb5d15fbe9582caead0e40c39970d46ff3c5b1224b140d4c42f5ba7d38b4f3102ed5dd4063238bdc8c41583d2b03e46267f00e51ec3f1a800b552ed836ca867fa9dc8774f5d61d242326f56d6cf83170bf35e7df7aaeb16f808904a909ac3c315227e278be7e6bdbdf90f0bb86a86baeaa6ae46968283c3fee6d654aea5f3ee3bffff5325edd3985cf2f6fa1fede71aadd79687af704cdefa9bf3a8fe66747a8b67f884f4f4fa2f9641c3e1ccfc4a7a3c9602fc68125ebc136cf457363153e3dcb47fd857ef86567122ecd32c4e902335c19638f2765ee783ddf1b2f667ae0e57447bcad3047c3760bb0f7a3c1bec903fb7601c5fcad1090f760df5d68f9303b90f72c914ba6fb69152ac9c9fda7b57fdb77971929ab905cab585e849a2dc23ddb93e2d18bd82539ab04efc75d42be7f4f58482ab0e65c1d186ae9b7cee773b7f244886b18c57e1b740eee8c4ea1dd1015d819eeb6beadb980750b2a7068fd06c4da7ae04c487f6c95b7829fbc2a8a86e5e3eac14bb8565387bcb40c986aeb2136301e7d3b0d40526432d2bb0d4572877e94037445a47f004e6d5885b4ce3d909d9c8a0e4191880bee848e81d1488ee98ad44e89488aed8eee5129484f18827ef1e9189a9c839cf402748febc3bad979c3ded2097a6a5aac8e8232ac9435e1a26a80184d07416f1d6f24697ba0bd9a1dfbffd87bcfa8a8b2f5ddb724e79c73ce39e79c24e72c20415440140451904624a988022a8a9815b39873ce593107cc09410926a8aaf5b0ee2c7abb77fff7dd67dc7b3e9cbbdbbe5d63bc63958555b56aad39e7ef796678e754757bfab44354b78fe25fc2ffffcc87795e5742947edef58245f7ef04fbf942ec996d0625a3a9300a3c41987f14161167601c4cd81f789478ffa3e4487441f829283a6ec6860a0dd007c5f166ad12faf7c92333ca19358d8bf1f27535e17a2998af6a41dff4c3eb0e238c0bb181b4ee0cb805a6a3ef5906f19d573134b8066f375b61538620a4b592a0e1cc61ff62a813fe2b99968d7a7f59dd4990d14e87b07c388ead4dc670d702eaca521f6adf2c4bea748d0375a6c69eaa8ed482b9ac2053899fbb54578cefa787fc9bffff82b0a7b638f7b004371735274902c767caa261ac38163872a3de4500edb96ec4ab4c068be8027a9f1ada326470b95c02cccd8ae89a2706e65e6d9c5c6d064bd13198a4cea04a0dc76081e5186c721b83bd3e8cdf23600c6ee771b33fcde31db9bb48f49e9a28b790b5e2e8fa3f9edfdc47db614efccaebfeffc8916db24222f4816a4bd6874da6c80a76c5dcf2a59839ad02ab5a77a3228f30608325964fd482bf8d3d8af2e712cf128a143f576c2c32c7e69a5074bdfa8e57ef696cdc701445e9fee8b951872747abb063aa32b6e5abe152b50a26869a61f58a1db879f52e9e3dfb88f54d59609ef1a6beee35a798d7637065fb744c709244b4bd3626b8c9e2e632537cd96d85c6fc001cde7f010fef3c21de1478fff63d0a26cec094647fd07792d0bdd716eb26eaa0394a05b3fde499657eb274a8b9ec2c89dfd797fd8a8b66a5df368bae79b35243f24ead69f699e9caa3658df13ff7802fd29214bd6da428a3e86a6d902c30daefdfc8a2597dd4db3bc7a8cf2f6ea2b7eb22be7f7a891f031f881e380be68f01307bae80fd6d742f450cbd3b89efe7823170671586af2680fd6606bef5acc0e0930a7cbc3c118fd65911af2f8b3399e2b85362820fcdeee85be58b81b5fef8b29ac44a3f0c3479a2b7ca091fa69ba26fa92ed84fccc0eeb200fbb51d5857123054a9c6fa9ead441f0d577b6d2e2726c5f8efe6c61af30f8d25a1aeaefed6505c7ec44dc5841a1f9b8be535bba98a9c265c49d98cb5d17360c82f057d490518eb9a42595a1aae1656b020dedf50d51896ba9688f64e848f7d20e1780866e44ec5db67cf70fbec59f8abeae1766631be13ae5fe6d6c662210d58ca2aa37e662556ce6fc0fabac5585e5187259555585cbb004dd50b31356502fc9d7c60a96783fc94244c894f818f8d075209ef0b92d23031221615999351973b1d8dd34bb1b5a905cb172e46946f2c8ac697a122a7160569a5a36bfffc5d42e1eb14040f1b6fca50c3002a72ca50955786ac98386d2da9860c2567a42939b013e42de81d2e914f5c157ff99de57eb6639cc1b1af7e4e2e23432fb751df2e8cc3f0ed2a548ed3838c79132c38ec0f3d06f3b093300f25fe9f8471d069188c3d0bbdb1e7a01f70148e2e11288cd6c581a9c238b82c8db435df41e3386e6e0c43feb420786765223fd6087da73c417f4f475da1392eedf401fdc11f9fee97e3f35647bc68e0839db517e4ac9741cb91b0dfbe116ab60d50342b853ce1bf8c561a8494d361e7180cf6e745787e781275a2d29a3a52694f5d6972a5ced73b5261c692c38a7cdcc17fd87bfb6ff6ff4fef5faa24c443936039c871a189f8f62353a5d1752a1c3716aaa0c99381d638497ce9d0c38f4db23859a38274a33178b45006bd2be4d149b4c0bbb5dad8bbdc0c2642dc885360205e998154d5319845fedf1a5706363832703c8d1b03ad3c146b8b181de728e8f36fe7f03fda947f94436ec6bf720172fd02d7515985c19821c223f423dc567ee4cb0e6baa2e491593b3668ecec16b5ad08ad6151d6898ec49bcbe1ac25c1cb1a06605962c68237f5b8565cd5b5192e28b837b4f8ecec1dfb1b11d5b37ac0273e0155eddb98a2bad1330b0df0bdf3b63d0b9672ceab3d589ff5f30caf03b77bb70a4d1151fb69850d9015a5449b83aca8264909f9e8796c5ab515a548314274df4ee30c3fa591ee8ec7c09f225387af0244aa694212f6b3a627cbdf081d4f3dd45ba688e51c3a66c1d6a51acfa",
            "c8540f850fda5262f272bf7bcd5fa1eefccc2711f26cb9bedbf3df0422bf5c9dc066bd9821fb642643fa58890183f1afbcb49cbe9aa391de4ef4f4ccc4287d85d17c3f4fbcad4c47fade3d61bfbb758cea7d7675d4fff7bdba85ef9f5fa1fbc1490c7e7804e6b71efce8b90c8afa36ba1fc3d0f3360c5f4bc1c0ad160c9c89c697c775f87861121eaf77c1f52a15dcaeb5c17ba2c9be5e69c68f1bb3f1ed782abeed8dc7d7ed11f8b22188f09f68812677f42f70c2e74a5bbc4dd4c5f71356600f386068af3e86662b52c35334e9a361caaf1d95c51d040545ffdbe331ff6c3fc4f878683d0515d6d4e412944ea8c7b8e869a8749f82edcec5f094d48791a8222c0c2c61a2650415694524f80760667a1622bd7c11eb1f8c6cc2e8d249b9682e9b83c90969a8ada8448285232e3a0411cfb10f5f755cf052400fd725cc5120a808777d13a21f4c91161a832525d5d8b16825f18dcf09c717c2cec804e1ded1d055d1c2a49878648625223b721c26c7a4a2a96416dacaabd03abb8abcaf029513f2b1ad713968361b372f9e4762600c4a26cc451cd11b7ece21f0710e829b8d373cec7ce168e10e630d3358e9dbc1405dff212f2f83369650a07255dc5813e4ede916dbe0f356724abf3a5b7eeafb38ce78ced4046716753387fa7c319f94e95484395b40dab6031a1ec7a0e478180a761d50b4dd0435c7561879b5c1266839c2d296c035b014aa1e6720a2b700e579c6a439ebc08b33652898e202cb15ab90ffa11fe1c79e8291bc0c7e6e96f8703a14ecfb3e585fa486173bed71a9540c9db5bc5890a5423e632e749c9742cd7e31d4ec9aa06a530f258b4ac8eae5414e27036324e331af2e1bf48f9db8d8e88563b58eb8bccc83fa7e3a84b926d798d617e55ba526c8f3b36ff96ff6ffe73abc499c7b0ceda6c9cf7a54ce8bee13dea0bfe680eeb447ff112bcc7727fe7d812cbe6e90c1857a35641a8cc14c3b06ae9789e05a81183a62f8d1bdd500bb1a0c60c0cf852805cefe400c2a58968138150666121db0c29d0b837b7898f445617acd5489e5bcff99ffbfeaf5d320f1c8d94899365092662f4dd7c3d9395a88f571c3cce9752823fc6f5fb7070be6adc6aa5c33944619202fbb026545759857d984d5cb7762e3ba03d8b2f9346edf1fc6aead4bf1f4e141f4dc3b8bf25457c4c7e9c0265103a9a19ae8dc1c0afa752a6e2f279f1165879ede01c2ff77583b3716edc55a9859b40865d34a919b321eeb5a3bb07ddd765cb9781b8be62dc5ce19aad837df07f71fbec5dad6f5c8cd28c08c29a528993607a15efe38bc22145b88f7df90a5831d7906ec75993a74a18fd2236d19317e9d5fa7df8ce7d46fa3744ffdd46ec4645e75bbc6be15fe92f5a25cf843e1e8df79ad7fef04e48c2fbd9f90104e3fbe79fa6090a315e7b5607243e9e6dadfd8ccee87787a7e373ebfba0d8e061878f7001f1f9f43cfe3b3600ff5e0cbfbebf831708bc8283628663f06cf65a0e7f838f4deae46f795a978b4c9077717e9e0f5e640fc78dc4ed4d65bd0d475e0630bd88f66817dab00d4d529a0cf4f008e2583d5118daf2bfdf0b9c6191f724dd0df6c46eeb30be883a4fd9caf4d0d17eb522bbd141f19ca88054b0889feb7ebcecf72202e2929f94e4a586824696c0a3535692692832720d12f1d5bec7291a3e9012f5933182a6ac1cdce13faaa3af0b2f18596821af2e212b1b8a8022be7d46265e53c148fcfa5c687248e72dd9178ed8b2ed1a08f916b3dd88761cf307c52b141a79c19768aeac2575605be2ede88f61e8b5595f5686f584afc7b20a4044511483cbbb3852b4c34b530312a0e6e963630525787a6a202f45455e0606c84b4b070acaaaec1c51ddbf1f9c53350c3437877eb325a2b2b10e41a4c7449fce81c026fc70078d8fa8eea00674b0fc27e07a6a3a9076da5679520c9cbf51b8f0017ed25a3fda35cd983ae36f26cd79690faab8cfd3773fac056967832993772f1e15c3eb694dbc1dccc13b661f5889b340785e5d3b068690e76edcec1854b4d787a6f317aef44811a6cc1a36b53e01b1889b0b121607547e24abb07f20a32b0e5fd20f6fd631f92d035a7c1d5700a8cbc7548f75121f5c00afb662863968f307cadf4a1a01d0319fd7c6813f66bd83710efffbbff1fe5bf7925f1fe1990d2ce86944a089e74ed47ff83f5383ad70cf7d6f98279218cea391884446bd921e2fd0d8da544b818ffffd9cfec7f875d1c0c73c648cff333c6d0732305d95fda4430f8240dac3b7ef871c519f43553ecca12c0c345724087225a920590ae4598ee2f858a4845344749606bbc108e660ae1c37279ec2a928289c8186aac0c8322eca742e51954903cd1018a0cdcace267d30724e97bcb641f6a8871f3337eedb1989fe589d87ec6633d4559fafab149c351ae2a68cfd4c0f400451417cc437df552c2de15d8b9e5289aea97634e98343cac1c316b7a11f2e36d5033bb11edeb0f63e7b6d3387afc1996d6cf23be3102e756a563ac9f0c161dc8c7b8333990697786689335f44395b1bbcc10afd79a6073a1321a1734e3f2d91b58bf620366648d23ef5f8ef5addb509c938ff4287f6cdd70006c161b0f1fbf457d863136cdf6406d551ba66517a1b4702e4aa656a0a2b806d141f1583bcb01878b888ecbd3c5e112036a4fa1e1484588ea17256161754305895f2517f0cf35fcd6bdcb84e8916f6b68fadb9a69835b4773e30bfc963a3abe1f4982559099449aa27e6a5e6ebcdf3fdebbcf48519a7ef1e00a6bf0f965bcbe719870ff21fadedc43efd3cbe8be7b0c836f6f8139f8183d0f3a40a11b4303afd17363357a6f4d434fe7543cd9e28e078d46f8b83b02d4fb8e119a668e90066f84c5ea076be038",
            "d8bddbc17ed504d6fd19f871760206b746a16f852f3e2d74454f8d0d7ae69b63708325beedb7c4bb6a6d5c4953468b972c02d52498161a525f5cb524e37565c4b8fedbe3feff3872ae1b6da665cc8ef34f4152c078c40667a0c839051bcc9211aa608b60457bd81a5ac1c5c209762676f071f023cfdda0282945f4802af4549490181084b2ac024c8c4e81a3953daa559df0d82b13dfde7dc0e3ea7aac52d4c07c5135d408296321973c22b50c1113108949d14938b8721562fd022127260e331d137813af6e676c0b2d4525ce5803252f2e05355965c84b4843415c1c6a525210e21e036572cc4f1d87378f1fe1fddd9ba89b52809a9c424c888c83979d3f423da3e16eef031fa720385978c050dd085606f64c5fc770dadb2660a194d068797a202324844265477a86aed30c4921815f9d093f73c05f50e6e3a24fb5c6b0facee721cd471b53235570638b1bbe5ff604ee87817e1607e6eb09a43c5781666e033dd442623d8003a0fb23f1f8a83dce6e7302b333189ace5e58f678e0f73dc82816eef77d835ceb5970d71c00f7bc63109ab610e7e62ae1519332acb534c0a5510759e3b9d0b6cd87985e15e42d9640cb6909d101f550b1990f79e31990d54e079f7c2a22239346736adfdf9c80871b3dc0ba14457c6b02aba3c2813612e7ddaaf2bbf7ff7bc2ffff7abc3a48868f9bd695e4653f982784ef877449fb1406e61557721dddd0b7550ee757d982bae342da35492cca0dc7fdab2d187c998ade0b5eb8bbc51cfb8ae5b0364e0087890678b14002a72ba4e120cf4db98a32a824f531549cda18f84a31b0348c9f7adf2039f2618d2ccbdb88dff43f9ccbaf76fd641445146f2b8808d207db129974ef64ec68f64461a80ee2bd8d10e61d80154b3661d7b6e3685bb60569f1e9981c17843d1bab30fcb40c6717192139368778f1fd58bbe6142aca16a2739d0b8ecdb5814b92068e7e690793fe02d3065f0854ea40eb902fb4b7f9c3d35d1e2f3758e1cd6a75948c73c6be5d27b063c32eac5ad68e75cb3762f6f47a2caa8cc79b6735289f168a6387cfe2d2e567a81eef80f9d91e983dab19b388e79f535c37caffca925a24448cc7921c43dc5c60844b75c6b8596f820d996aac6c1f753ac95fb74e8a57f057a9479c3169ce1c26be7b468cb3c35db5e4e9cdc0e1a35a3f75a62b89e1a2cc448ad31e3d3bbde699a7faa89fce248294ce880c64733441ff8b6b787fe738be7c7882fe3777d1f3f0243e3d3d4f7cff250cbe3a8d4f77b760b0eb08061e2fc7e0b35274edf1c3bdc57af8742806e869257eff16d8f4db1126f3fd089bf9798462b346d8e4550a4cb0bf3f00d5bf1facc775f8763c133d9ba2f0bcde0dd7679960c7644d54862920cf5e1aa9b6d218672fcf59fbc4dc596642af4a56dde9a221c1b907ffcd5c3f7ff489e5423c5cb4afbd1f33c23b01513e090822de79896d1a8a34fd10abea055f394ba2775de164660f372b3704b987c158cb6474ed6a2879ee69eb0d69117114a56560cea402847bf8a24583e8566e2b5c748ec26a3e452c6248610dbf32ce89e861118f3cc6f904615c5022d6d6d662ee945c68c829c0dad01253d36662f6947ae48d9b8910af6804bb4722d02d123ef66361a0a6075b031d58e9e840555a0a62fcbc10e21a037f7b27b4ce9d8bcaec7c148f9b80f2cc1cf8d87910ef3f16de4e63e168e60a23756372ce6630d5b660fb3884d3313ee35f69c82973da80442e01061d236f44272b9bb933fe1a29e539498c3e5a2a89d10ff78ca73e5f9a82cbaba3906c2d01231d27c4b99ba33a520a5b3204712a5f18e78be470ba441dc72bccd1d916893b1b63f0749f0f76d4dbe0dd8389b8b0d405dcce19e099d88a677d83b8f289b0bfe924185507c0b3f038f8365d03a36e2f56141b50df36aa23cb470536e4be57d715e0d5bd0958b6280c0ebe9910d39905098379a3fe5fc1300ff27a59e0950cc5ae9df330dcbd112fb7fb0037e2c0be9588bedb395496ab2294f9b91d0d2405c6fccdffff587733a478b966aa0af15ce678ffb2706136bd5504df1ffa83f588e8bb5b6ef8b45717fb6b3d31d4bd0cdf7629a273930369bdae82feb000f42e790cb408a3ab8a30bf410abb278b604d141f0ea509e15689249e34c921c351004403205b87813ca331a8f7e1c3d91c11d6e38592f4447f9138c6af3906f073ce95a08383ca69712e06bd636130937e3109dfcef8837e92881777cab120db0e61eeae68696ac7f49c224ccacc45c7fa467c3a3305f4a719e8bf94804f5bf4b1a8c0065949b1c8494fc0ce3a07bcdbe401e7280dacfdba7e740f600ea3eace36437fa10322b78f837a8416846da470629125e873e668cc524154502a962c5889eab2464c993807c5133dd1db45ee517f07be9d73c1e259de98923b17d322ac5033753ce655ad209ebf16d5a50b5136bd1a5544778c4f9c8225b9c678d868829d9394b13441115599ced49dfd612317967a7fd2101751509795fd55fa6b381e8613ca9fd6322e7cbd161cd6bddd8ef33a67e2ff9bd4105f9ac5fc3144fff8406f9f11d26ca3aec4596fc24c0a70a74e74aca568f4e07bef03f43eb98841c2ffbe973746d9fff9c505f43f3b8117fbcbf1e96633863eccc3ab1311b85aab87d72b3dc1be5b01facb51b0a941b098df465843dd60b3de82cd7e3dc2a63e83e2f4017cba88e1d71d187a7704ccbe3360f7ec061172a0df36827a5281ef9732f1e96c06de1d4fc19b2d3118e88862d2e77ce8dde91ae78ca5c404197f8e394c3febec365971513ac6378ec5f1cb01eee108750c43836902d2543ce1cad9ebc7d295f8f338b859d8c3d5ca9df0d409e63a86284e2b407ae444d44e5f8650af388c0f0f41db9c5a",
            "6406466283a227f6883ae0b0bc359611eeef11d1c02709233c11d04585bc16721233509a998f8e654be06e610e3f677f2c9ebd161b971ec5e28a7528ceae45eeb859480c4a477c603abc1d8260aca987b440724e16165094108784203fa44404c951005e368ea8cb2fc282bc22e427a423d0c917eeb6246c7c88ef37869186298c34cdc9d11c56060eacf880c974804348b110dfa80de8719052ed71905411f98bf081333a361260a184eed313a9de8bd3707f7d30b2bc7421a8370772f61b206bb312ea1653e16aef8bdcb16ad8982581ceb942d4a71601dc9a23860b8512589a2485874b34a91d79d2e08d9c8d31694be0bbfd32e4d75d05a3e630b85ace82e77e3fc5b5f126b8fdf2717abd177e1c30c28a5c65b09e0593766f05e8a7e1a05f07e0fba3b1d8be31022171e321a939117c72191052c986ad7d04be7dd98fae0313f0724710be5c8c07fd6321ebc4aa68da429cfbb88a20efafea2fff4ff5edfccc4fe54c4400d34c898f3694e1a5cd94f9d0dd260ee63155b0d8f3c07a9103faaa2d7a776a626f8d0b5847adf17db304d04dbccdfd400c5f30c0a9f99cfb2e8a8b2522b8532682fb73c451e72f808e2411ec8c11c6b10c31bc5ca2885d95ea4877914208f1ff13b51928b6e062de9a2f45d7a648ccf9373df2ab5cc39fc79d9c31b20d2b4b98df1ecf245ede021fb639e2cb29a27d4b2d10ae2f021f177f4c1c97828d6b56e3dbdbd3f87e2c1cc34fd249d9de077c3d0ed63952beaf79e0eb155fdcdde504ba331aa51986106db7c5e69e03a3ec7ff1f125dc72bca118ae0ed971da10f592056f28e1f36c4bf4eeb6c6f62265cccd7745594122caa7876147930b7edc24fa8df91a435d4b30b0d308ac531e38dc3296e81153cc9c5689b665eda82d6f20d188e48878a4c7c5c2d3c10379813268cbd2c69ab2689c3f40f876371ffd1793587b8b6ce92467b59f6b007f15bdf6733d89cca96086ccf57a6bce3d3be4656e487f7cddc5a2a92fac7717d6d2cb277815a9898b1ff477b0a2ef5f3ac27a75f70c30f41acc6fcff1f5c31d7cfff48c70ff0abe743fc6bb8babf0fa6825bebd5882af2f0a7173952faeb666a1f7e66a7c7f7f1c5f3eddc7d0b73ec2f9a11172ef7e06e13f0dd6e003b07acf80f9fe24bebf3a8aaf4f77e3cba31df8dab50bdf9e6e43efa56578bd7f2e9eefaac0d34d6578b6760a3e6e8b1fa64ffbd22d912ab7b4844565190a0a7f96f68cb3e69f733ca726a740a78565b2423da2295fd7504459fa61b66e289c24f508ef5d302db5180901c9c4d7fbc142cf027aaa9a98397e1a4ac6176172d24ccc9fb90a3372eab068d674dc3e7c04536212d1c26788cb62ae38216e82165e79bc903504ad60864ef27c01f97bfbe26538ddbe05e5d99308cfed5055d08c15f3b7e3feadf7685bb81be5f90d983ea10ad3b3ab9118920107533798eb9a20d6c7071eb6f69017171de5beb488d0a80e50909044944f08e64f2d42a27f04223d0261c759fba76339baa7b0bda923dcac3de166e9413ecb91f2b0f6a5e27c3387d565d538f3e4d7684a48ef561115fbabf4332772c674b2838d585f2fe7a2e762113a570721ccd10ad2667530f4d90aa38023d0f33b0a358f035071d90835cb22b8da396165be123a17895193fd95a8281b39dc59a0803d05721893580b9e65a7c15879198c25e7c0db7e13caef062042ea06d7fe27304dcbc2b525ba589d2a8396697af8fa7c0606de6dc18f27c9187a1c09bce7b499c4cfb0a6e1ea91204cca4f80a074000af227801ede81fbebfc707bb53f7aaf4dc28fde46f6141f155a859f3b42579cef57e3cbff170f7701064f37f1fe23a75bb48727794a52ad5902a0cf48139f9f0336bd07ccbbf1a339c7beed55c3a13a53b0ae7b807dd112acae4030f76ba23e5602319a6310a5cec0642b6e5c9f298aae2a314c73e2c5fa08619c1c2f868d2122a877e5c3f9b99a787b3b0ac70fc7615d8509764c9762d297d4e9e9a122d37f41fe73da5e017577f5362549317af5d22266ff8b561ceb28c3d50d215891a182276b6c51315606be16da5838af06bd1fdf101fff192f4f4cc3dd8e18745d9a813bc76af1f4e23a3c385e8b7b3b2271776b006e6df7c2e3bd7108cfb583f69320143d69c4f0f71fb09d1f00469018246718416eb11524429420526c84c525365816ab8225e31440535748fdb80bfa6b01e8c1f9e4fbdeff3ed6d65f8b6fe77df1668d11beed31c7eb03a1a89a9e8aecf4e9a82d6b40dd9c66043958e1c4ea19e8bc7d13174e1dc287eed7e4bdfda0bb1682be97830bab23599b2718d08d69a6471544457e353dfdc735a5d9ca6282f4f13d5b9834b31783dd0fa9cef6dfe855055157c589165eb1783e61f44bbc7f74064383cfc0fafe02c3839c788b2f3d4ff0f1ce6e7c385f43aef172bc3a158e23d581b8ba6511ee1e59858b5b16e2445b058e34158ec6e995a5b8d5b118af2e6e44ffcb0b607f3e0fba770798af36e1fbb3cdf8fa6427faefefc0a75b9bf1e1dc72eacdd1063cd9b910f7b62ec2c36db578d391c3629d0865d237fce865c95ae7d50585e53535e5fe6cd79e732e37b595d5e849b179ac68ef04cacb2504b1469e485272849da11526c5e5a1a6a001e5934a3167523ee1ac0415eb1346b5cce6e4ed998b92890bd0d67000cd752bd175e33aee5ebc82e4e008248f91c43b296f9c17d5c3216155d03246b820a38df91131d4f13dfbf1e25627fa9fbc40636939c2bda2505dd48265b5dbf1b8b30fd7cebfc4d2ba9d6899b71d53334ae16ae949b9587ac254db14c9638310e9e90759519151fe4b090b8e8698000ff9bb0126c4a4203d340e09fe91184f8e9c3503c5e3a7a0a57619d62c5e8fa2f185c8899f8889",
            "3199ec5919f9746e62c6596951e148413e3e2b4571a1bfca5ed995c424d235d9cecc1f5726e3ebcb36bcde1936bacfb2b4c562e87bef848e5707743d77c03cf4381c93aec336ee1a7483cf43da780ed4f5222062d20651f9281c2a12271a4011a2136783eb1d4db8df09819d7720d33f0c3bd23e3990606cb9829a52575c98a386999ea2581c21894353547070ba362e10f69c9eab878b8bac716d950f1eb63be0eb2957d06fc2f0f17e3ada9b499b3bd31da716ba515d5b4241bf28669d5d17336225c573475990873f40e7eff57e7ff8fdbc2bac1915fc8c312c23191efa64b3129b7e1d8989f6a2f878509d30631a86599b895769c78f7d8417ebc431bc550adb7295f1e57e24d81df2f8dea18197ad0a680ce2c69b06613486f020d9901b7deb15b121811ffef20ca4e88cc11c577e6c8f17425b9000eaecb8b12d5604f7da6cd075c40503870da8dbf58a94b91c8f9538ef2fd53ff3f33cb5180c7eb8e829e0697b04b5ad501d8f377ae2de325b544529e3c01c63a4db4b6079c9589c6a2b229ad80ff3e3b45117ad85b6340db4c42ae050b12ad6a4cb609a8b3866f92b21db4906c7e61aa33d5f0753f764c0ba3b01ed1f8e22ab2d1f6388bf57dce406b953de10a9328648812e545aedb16a9a319a6295b0609c1e6e1e5b81fba7eb71f778351e5dde8537f74ea2a7eb28bebcad01f3690686cefa63609f03deae35c58b8d3ed83c3f09e3a2133165d25c447b3a63cd7895911f6f4f111dd10bfacb53e0690bbe9f490775218c7abdc79d5a9b6d8a03c5d63fbc0c650d18ff5a9ff9ab947dcebe3e9cada37a0a329341337bd89f5edec6c09b9b38b7a2104797cea09d745471ebea09c2ff47787bf71006df7782f5f539d843dd440b74e3dd95f5f8fa6605580315b8dce280fd5519b8777c3b9e9ddf81a727b7e2c5855d787dfd109e5dda837bc736e2f2f62538d13a07471a0b71bc318f7c4f3e1e1d998b1fcf56817ebd095fee6d4237f9cc37a75ba8ae034dd4e38e06f68b7d75ac8113854cfa4a0245df08a4fb0e7bd1e5f1ba6b25b90585cdcce4ff8cf584d319745f57599d9e965ccc0e758b82b7730062745de1a96181696953519153868ce824b8585850eaf272b0d637c6c6ea15583abb0565794dd8b8ec18b6ae398394e8384c4a4aa13cad9c901e95083f43731c1230c4731933f48b6ae294820e0a63e2a8b4b0182a2b341231fe63313e360153c68f476c4032f1fb8d583e7f179e3d18c0977e36f66db988dc9402d81b3bc2c9cc9578771f98ea5a22d6db1bb9314950929480b8003f2485387d002250975586b2940cc23d839015918cbcb8f1682dad46635125ea8baab079f9661cdc7604b585733133b380e880a99837b59cb5b7790d5d933ffd8ca4d0e8c43faebf086bb68912feafaff061d1cfe660f84d1bde6eb283857900e4ad5ba04bd8afe3b57b540338a4de816dfc35d8c45d8175d42998069d80a6d35a587957606ab607f14392a06f5b63517d2018056d1873659092b8df0d4dc27dd587dd1853be15ee2585d4a5161beccc9040a0b134dc0c35b0658214de364be3418d04ce4ce7e801516ac74451ac1d2f892589525835411e1bf3c5b06aaa2a32bda410e7a0843b1b423178338f353d448b56e6e34ad711ffa5fa2aff8fb67f1cf64f9860bd9db3b75facb328f5e1ac2d45bf4cc230731d1a72fcb0b654013d2fab88ef3b0ce6fd74eac77a317cdbac006a871c36c5f3605729d1e06775f1b1490c1f487c6a11c3e33a114c361f837db395f0b65509ab5285b1335718ab930431dd99179966dc5814cc4f9d9b228a1369c25868cb40b333d7f0c6107eda4b91eb8a342ff7cf3c2cbfd4f5a47fbfa667f56545e94591caacf5b98698e12b830c1b5236b375b16fa601a22c64e1a62d8e7941a25818ae80aa6025ac4cd5c4ee7c7ddc5c648ceb8b8d5017a189a5491a581ca78ada4825f2ba29daa6eb4371a615d49b5d10d3318912fa4d87925e6103d9675190bd1d04a31dde94f6b550382f75c6f61c5db4a4a95133c6ca63aaa3108add4450e82a82599e02688a14c1ca24696c9ca88d35f9e6d854e68043f5f6b8d0ec88d3751678d2e648eacb5814a6f9c1cb420fdb27a9e0feb600e0a62fdeefb4c5ee32036c2f3344d73a6baa6faf0b8e54d9314fccb4a56b930d1a2404847e953e9bd1726ffdfb62bf222d6951facef9434c6af0398606dee0d3e37338d152443c7c3db5a3b114772fecc450ef5d749d6b47ffababa07e74e353d765bcbed00c565f1d7aef25e15085136eec5a89dee737d1f7fc1a065eddc4d7f70ff0bdb70b83ef6ea3efd5f5d1b9027d2faea3fbe1193c38b91967d62dc0c9b61aec9b3705edb362707c6932ba0ee5b0bf5c2d66e3f6ec11d6b5121a577368ea72323d703484bed4e28eb224c3f34edad2f15c0c817fd79e7fa6072797da5d1d25357a5c700a3b233c054569d310a8eb80407b5f4c4fcba3ac0df4293e0603423c5c94302f0f26c76692d7a762f2b81234576dc3d695a73023a71afecec1d05352a37ced9c10e5158894e070144ba911df6f8cbd52aa589c3f05e513b2a9df3232897ff7a0387b023a183b21cc2b9178fcb9289fba04ab9bf68c6c5bd78182094588f48a82bb95079c2ddce16ae509270b373898bac2cbd61eb9b1c930d6d082081f37252d2c4c692b68c250cd088a92b27034b14571da24b4d72fc6f2f23accca2ec084b82c24862620d22f02c1ee8188f40ea752829290199e8682c49ce18ea6d574f9c49c4dfc3cdc7f85b166ce1e5957650927ce74cc60d3c43f7cbd3e030f565a42c7281a2a0eaba1ebb30fda1e3b611870003ec5bd70c9ea8275cc0518fa1d8692d502b46f9888cf9c7d630663d098ab83ceadba",
            "a09fb9a0bad0118c9c4514a3b317fc1bce4065eadc918ac515d4c743693853248771968210920b039fd62cd89b996129617c8297051c89263434f2868a4e20a4d48220a21a0b3e71072ca988c4b195e370aad1179deb42f1fa681afb22f1fe76727c8f950578041d54fef6fe7ff8fd82d362182f04c7f050253edc6cfa7d316e9ddb885bfba711e6d7e0d18d4dd8347732690f03401f5503ab43115f36c9e37eb5088e4de44395e318accc90c2994a391c9c2682b6440194bbf3e040be283eae90c5856942b83e4712e76789e264810875708a08abd09d8fadc13f860ed0e56537c50ab28e4f1262b68609d21eaa3c2c39011e4ecec15fb1befccc1b53a9282e4a97056b334f9699624b9131b64d37c0c7ddced842fc79b8a51242825210606f8225492ad83441177b0a3839010cd1bddd06fb0b75b0385119c9ce0a08305787afb10c7a0e38615b8d19b802e4206a2701b1127dc86e7084dca55068a310caf7e250f9ba0465c335c82b31c791025d6a7d8e3aaa2214b0204209f38886688e53c3920435b4a5a9614bb63a8ecdd04489973426db4b628a8b0ca67ac8635e942a1ae289c626fae1e41c2354442a63f7544dbcd8e38bef57dcb179a1375ebc398ba77b825112a48cf3b51678bac9953a55e5387272ae5daf8d86b4ec2fc2fe7fb669242e6545078d10c0b386fb5f8d8e8d7cb8771cb7762dc4e52d0d787d631fee1c6a45cfe3137878a20dfdaf3bf1ecec7abc3a376784fa548c077b7c70a83a1e6f6e9ec2b79ec784f5f7313cf86e84c51c1ae1e4fe637efd30ba0ff0e75737f089b0ffd38b1be8797211afae1f247a62335e9cdf8cae531b706ecd5cf6f29c08d6b20c4fba2ac182ce0d33189e916832302d52f7699297c611377db96a057e41eb7ffb1d7fd6364c82c43b6519999149b1e95475de6fa3fc7735b14346442accb50dc03f8631dad72e252c043971f1510e5bead98de6e64b0acb40726816c5996317e21d85b16ea130d5d243aca71f6aa74e43a6be195af8c4b1a5a60a1d8be66371613ee1be01acf4ad11ee1d8fb4c81c4c4a9e898949c5c888cd47ecd864785a133d6b174074410cd1144170b5f4809d89137c1c03303e6c3cdc2c9d10e31d083f7b0f88f2f1404b4183325431a40c550da121a74674811e4ab30aa829495970b37281a1ba2e94a5e5a0282543f48134792e0b0d792518a86ac34acf0cfe76de54b26f2c6b75453d1de6eee1f117e085b0993ce3a99290287debcc12eafba50c7cbb3d03979bcca0ac97044db77618f81d80b6fb7698479dc3d839437099d80593c02390b5588da64521a46e4d016b702d6eac74c6ce2c69849b0be078892806b76a62ff725f4c9a391e0b6758e3ca6a6f7ced70a65e129f3f7bac0896268bc1c5ce053246a590372e01bffa5488ea5540caa416927a8590d0c8809c6e36f895b2c8fd0e04fd750d5eee4fc1c3f6503cd81c81ee8bb9ac99e1dab41a3ff7241db1bfbdffbfb57f9c71d0e5020c5e3adc90c1a48fbae1f9830254854ae3fcd200bcbfb193dcb773d857634ad8248e1fdb6571bb4c10e7a6f0e14896005606f3a0d29a816c3d061aa284b067b2304e168962e70421cc70e246a6293726188f61e7998d61052a3168753e06adc0cf4dab08f3fc90e0e6a289d7a7ed9479685561ee0732bcdcbe3a62bfac56fe59a62205b905e9c99e6aac4bf32cf070952d56a46ba2bdc0007b8a75e165ae8fe9f9e5a8af5b011f7b1bac99ac8dae1596c4775be0e3562b54842bc2dec800ceb6de08f289829395038e5619e050a52964c2942116a50ce96c5dc8ecf580c6402e1ce84a28aff782f3e600646f4ec1f13521e8deef82fd5586f0371487afa90abc8c9591ee268f1d79ead8315903e72a75b17fba164a7c1531334009c5fe4a58314e159b27a8a2395e19f99e72f0d195408cad2c4ecc36c0a7fdee38576f8aa30bac3074331b07665ba3c84f152bb2f4f07cb52dfa2e05b35e6df0a217669acc13e315fe15d86fa6292c1164ada526439e7f595a339b609fa6584ce628ffdfdf398237d73a70eff02a7c7c780e57b6ccc38b2b5b71eff85a3cd8b7101fefd480ea9e884b4b5d71b279363ede3b457cfd35c2f65bf8def31414736084cdfa31c21e1a24fcefc697eefbf8fc92f8fe4784fbd70ee1d9855d7872a61d4f4e6ec083832b71734713aeacafa34fad9c4b578c0fbf6baea4c059becfd9638d939040f83fcc5bf8b3b75f7365c525e9599905ac7953ab909f301139b1594808884638f1c9e2fc7c901611a624850447f9cf1967b7d0b5240cf682bdb133092704b94520c4330a0184fd61ded170b3f686a329d1d3f50bd1989787c5338a8816c84751623cf4555489877741b47f12c2bd6211e99b44de1b8728bf71480ac9c2589770047a4660ac7b38792d61744f003b136724858e4745ee5ca4868e8387b53ba977e6e4fda150975380aab4228c548d2803157d68ca6b42474985ed6c6a47cb89495024a024254778af467e8728c405f9212124307a1417e01b3d8a91a39682eaf0587b6f767678c2e2bfc0fa7f293106e3ad86b8087d63fb786ae05c06980faa7188f81605fd6ce8f9ee81a1ff01e87aee8253d60304940fc232ea0c64adb6a364461461722cf5ec54021e2ed2c5cbf98248f55087a8661e54959d51eccb8fcea55a3859a6818e0992688b13c02c1f5ee4ba08634b9e22e83386f8764213f1418e1037ac85966d35d4ace642c5623664b5c7934883b44e366495fcf1f04c39fa3b1b71abcd077788f77f7f3a8b7db62d72c45e8ef799b2208f88bb91ecdfdeff0ffd74ff384ee3e1e2a2a32d7899f45543ec596084370f17e149e7226c9e6387abcb9dc83dd0476ba2308e4ce6c5d5e9fcb8902f881d",
            "498268706260698c01dede4cc78bad5a5811cd8f025b6e64193030d7998bbd259a87bd309097f6d2e0a1958578de280973af22ac8f5416e1d6309767446b8a70af90e2e54e5616e6128c5161fcaaecff23ff6d488ca4bba95297ebad501fab84121f4524dbcaa1364a0e639d1c31737a35f6ed3c8e35ab3a30d64a131db3b4419f70c08e122d9870e622c564a2286f1616cc6d465ae244d4c5a9e2c94a0758f92943b0d418e2b95ad059e50b7fba1e669d69105f6e0e46a936caca7d41bfc9230c6b4259aa3ef12246880d4d4474703c1cad5ce163a682b3d53a78badc10ebb3d4511daa848658ce5a0dc2f21405a439cbc1d5400576c6a63031b047a28bf2e87ebfef77b9e2e81c7394042b616d8a12799f3ae2ed94b0298f6883231e585d64c09e17a7898d538c87f464c534c4f9f9ffccecb79317141c305510b3b7d6d0b0e16130e8fd5bd68eaef71ffef28e938f079f1e9fc5a72767d17de7307aee9fc2f5ed0d78707439ee6c29c4f78f6d60be4dc3b16a675c58d784f7370fe373d7157cf9f80cc35f7bc0660d81cdfc06f6502fd8df3f82f5f523be7e7888de2757f0e4c26e5cdcb3069b9754a26e5a1a2646ba23ccc1980ab034448493ed055b4df524e1ff5cfc39932b0bf5a5c5dd756424feec7584b347d77b0f1b7b4c8acb6007b9f820de3f0c13a352519659081b036308f370435a588826eca725880610e1e346a85b205c2c3c49d97326feda0ba11e3108f1881acdb3ef653f16e3425210e2ee879adc1c5cdbd3819aa2428439bb12ad608c708f3064464f4498672cfc9d2288bf8f40724816559831878a0d4843903b87fd61444b8421ca271e81aee4ffc766a3724a3562c7c6c3c6c8129a0a4a9022e7e2efe80b0f1b8fd1b9ffaa324ad051d681ae920ea52aa3484b080a7c14e5e3a63509f75dcc7c48f8c244d36c94f752c2c2a3ef97e4cc1914e483a48810cb54d39c6da2614eeb28aa15c8880affeaac50516630fa3445f9e9abab43a9e17b15a0de1dc2ae622d28181542df6f1f0c38fcf7de03afc2b770cdbc0379db3d489b9c09fa7d281ead34c6cef1025896268b99d12a5031990439dbcdf00c4ac3d5d321583acb14539d05106a2c0919393b8c918943b2ab1e6e9449e0fd492fd0572dd13a5115c2baa550b59c03658b4a2818e4435a23050a7a99e0964e40414e0268d619ea7e7b32756f7d10ba76c5e1e3c529acc2b1eab4eadfdeff7fd51eda1a2bf05c1bc31883867449f6a7edea38dd9e05263ad09a118915e10638572586f333c570b7460284e5b859cc8f3d893c5868cf4053b41206bbb7e0fa5a7fe41a31506ecf853a372e6a572c0febe4041e3acd928796e7e7be20c5cb95a22ac425692afeffba6ff657bd9eba24be453baad2a7caf4a8c5b10a487594467ea022f4152411ece93f9af3eff8914bd8b0763b55334e178efa1ad85cac89541f1da4244ec582ca2634d4aef8675ee0344f350cec75c1ba324b8815184278b7232c778522f9e92c309a0d20566686ea7999183c1d07fa81336eec8e84a9921c2a67d6a0ad790d5a1bdbb0747e33bc9d835114ad8a9e2d16583b5e1ddb73b5b1284111f1f672b0d4d183a3a51b82bcc39012930a37477f944528e1d5063b746d74c3ad7a0b34a4e820d15e01b1360aa889d624af3ba07a9c169566254de5b929d0b6aae2454aa2a2fc3a3a7fca7bc3f1cd9cc9721fd35d64ee25d871ac3f235f86e8de338777b3687cc1c0cb6b00c5c2e0ab9b187c4d98febe139f9e5ec695352578b2bb0cd4d0157c7b9a82c3b39dd1b9af9d70ff12be763fc48fbe9718ea7f0de6e05bc2fcf744037c1961b331c2c9fdcfa640f4c05730fb1fe1c7c7dbe87fdb89de979cf180bbe826df77fb6a075635158ea485da5e753152aa3494e68f274e913394c4892422d01bdccc8cbbbdcd0d4e6a4949f01919fdd7f3fbfc3f3d148584181f15252569191131a6aca83861a308f1cb520876f18496bc0225cacf3b42d8df43bcf2a09a9cfc08f1c948098a466af0b8d11cfa9c1c7b219ed1f0b00f247c4e42cdb459289f389972343145848f17ceb66f40464830fcecec39e3f5d4b4b42c34ce2ec786454bb0b47c11ea6736a2bab009292193a808ef782ad83d6a94ff9ce07c6e665426f25372c9f77812ee2b435152067a2abac4e7ab425f556b541f98e998428c9f87330790ad2c254793b82c2322ac467ed71e117e1eda54d38ce56ce20557731fce1e801cee53f212926c256939a6babc0accb52d69124c6529d979e4f7f2ff053ca71ea9315f75c405e8473ba2297ae815d81f2f637ba13a256f5844d87f10fabefb60147814de535f42d3ef324293a781eab4c3f90a59647ba8c0d8d80f927ad3216dd60479abe5c89d1c8181fec5447237508f76f8e17c81186927d520a2530465dba53033f3405783206e542ae1ed6a55dc6d9481924126942caaa16c3e1b32da9990d14a85844626d4b4fcf0f6dd15f4dd5d83bbabbdf0705b2c06afe6b20fcdf71db194e67baa2ac8c319bff8dbfbff6bec9f131c1e3f5714e4a6ad25c7b06fd608e0d83c13fc60d56063cd7874d72f4287b4225ac3b871ac4014d78806680ce4c3b250213445ca60574d0006ee8f43cf1e75149931d0e0c98565fedcec23a93c236b62796933199e9bc4cf703cfe1fd75a71ff23b8fef09cfb2f705f7e9e3f6731d6c7301bc5917593b4a8402309b4a66a60dd142d78b9046072c654ac69db8af317ee6165730b56e668202e380c9ef61e880a08c5fc394b5157b9142d8d9bb175d3415cbffa04c911a15892248fe365265835db126ae5d6103ae40db12a1384d705615feb14dc5fee8d17ab35d07dc603eeba02c84ccec6f183e77068cf49ecdf7514678e5fc292852b",
            "11e9618247ad269c79fdc8f29027dcd725e71584ac7193515a38070baa9a5035bb1eaeb66ed851a48fefb726e1ed3e3f3c586e8b6bf32c71b8d408e76b4df176830d168ed3a0d2ac65d8857ecab483a6f42449c13f6d9a13aedf7e87e626273551fac262fb061f0b254ef96b20674c776c6866d2ec8fe87ec2d95bf403be753f20fcbf0ad6f757a3797d6fad4c21bee202be764dc191d91eb877780b3e3f3d87cf2f6ee0f3cb5be87b7d1b5f3edcc370df530eff4758ccaf236c166b84b3b69fcdfe01f6601798bdb730d4730ddf3f5c45cfd30bb87b6227ee1ddb818f9d6740f73d04fde321fdf5dd45faeef9767adfd6167ac38a06ba75f13c7ad7aac5f4baaaa267ae065a12ff56cefecc0f074106e3b18284246da866c0b4d0b6a274898f96101c5d53cf921412a289ff2f17e2e37aa029af44a78e4d616b110ea785c422d039089e36be08708dc0f48c2958565141fe6d056951514a4e52163a2aaad8dbd28cfc8404e82b2b5332445f2849298fb2db50530bc16e9e682c9b835b27cf6379c31a8479c55384e754b04704f9cc3044fa2520373e1b8ea6b6a36bfbb51535616de0005b03a751eda1a5a0016b432b8c75098599b6099bb37f81081ff72d09013e720aa3bfcd908fc1f84eb80e17534fcaddc297ed6ce6cdb433701a7136f3a43dac03683b03474a434e759b8490a0b510ef5f86194652c4d7e84909d26f9e5fa3687617585d8bb0b5409792d59f0eb3b0d330f0d90bcba8d370c9eb837f62356e6cd4c6ac280da8ebc543daa2196a2e9b61e0bd0da6fedb2165de8af50b5d4177c7e1c7c03e5cac31a72ece96c6cd7992d0d20b84b2752394cd4ae060e1846549d2b8552987c18d52f0740d8694711d948ca611ef9f3a9aeb8f5b22124d75e340e32a1e6f8d251146759fcec6db13d9ac7427795a859f27555742e06fefffafc7cf39daab49d0e37d2586efac36464382259edd2ec5c125deb89b90067aef7ebcd1d6c44131069a230571b54c025bc70b626b912abe1cb1c3e06e0bf4b64ae2c34a695479f062431837eb7c360f5de1c33324c7cf5d26c5c323f0fb762bffdc53f5afacbdc6fce1da3eb75695a4add424d9a5c1aa383fdb186ba7e92222300e330b2bb1b7e3249ebdfc82b6c646b417e822332e04b30a6b3177d602e2fb57a2bca810f57366e2f28587e8ef1bc28ce9b570d7971bf5ece7aacc70a6c50be5f363b1a1611c8e5485e1e42c3d7436a8e26c9321bc0c4510e11f8177effb70ebd663ac686ac48d6bf771e5d23decdb7512c9219e288f918515b9afe11612989a31016d2d5bb066c5362c5bbc6e54239495cc47a4bb29ae353b61e17833944668a035c7105797d8e24eb3353e6db5c7b6423d64d8c9b1660528d36e3ad293c5f8ffb47b00ffec97f12045104de9da232f4f67ced1951ded88daa1222c444779d8b298832ff0e9396139f1e503efee10469f1d19ea7f8eae43b5f8f1be15df1f44e060a9133a0f6e46ef8393e879701ebd5dd7d0ff869307e809985f5e13dfdfcf99f337428de6f2a5c11a1ac0707f17863e3d185d3ff0bdfb3a3e3e3a8727170fe3f1b97d787ab6034f4e6ec7d3e3dbf0e2dc5e76dffd8b4c1a5f58344db3a8fed7435f1f5fa4dbeb66dcb75695d7fa85fac77e9e23672ee836e29f695d25ed112b5d3b96b9b635252b263e427cff374921412915319574f29f6967135bb69d811561b83cd2c392e1e31088e9a9933125219e334e0059512958195813b687405fcd00f30ba7203f310112029c7903d648089e80f8c02cf8bb84c1449bd31f2f027f77175c3a7c080b88a6e5e4faf5770e43b04714b2a333e067e7064921e1d1fc7d36064e94a5be2dacf4ec60a261caf1ede0f4ef5be95920da336e38c537951de618725246e47f94effd52820294a3b1dbb09f4314ed6ce6459b689ab0d4e594ef28484a2f1317e075e0f9bf8f0bfeea0f6349a27b746464e917f7cf51f4b362301f2da0764cd701c7ff9b869c8055d41938653e8579e87aa4066bc1d6211552361ba1ef7b6094fbba1e9ba0ebb68e3cdf0c69b36558bfc81df40b4ffc78508c81f572a0f7c8a12c490322dac5d0766e81a6e332c8593643463715530354f16dad38cab36c21a83d078afa1346c7fd859433e04cbcd3d0c795e8bbd980e7db03f1fa500a86ee17b1369638d106a23c17d584f878dcddffcef5f76fe5d1499487411b2909b05f6d52057d4412ac9e0de8fd7e8eaad197a2cea9a9e3b2bb2bda34e450ce60608e131f6ed64ae152850c2e9689e1fb4609742d95c6950605ac9e2c8585de5cec1b39dcf41447ee3b6263b81d940579fe6ae5ff7fa7edfb4d4e44a45f594c846a9f6a449d2e33c5f6d94608f10d454df922ecda7118ab566e41765c1c0e959aa2a96c2c521308f3e7b6a074460b5aab63f1fcd62c1cd877087b769e44434d0b827c2390e8208dc3c55a609df3c6ce52172c4b54c7da74456aff4c75d4a629c14c451201ee21b8d7f910d72e9fc2a16563b1b9a512afdeb271fe6c274e1fbf8ce4884878380621273e002b276ba1a2641e36af3f80fa9a6528ca2b43e38256e46517c1db441a2166e4f3f4c4116926834c3b39cc8e50c79b0e4774b559a2c44f81353744850e33976b94fdbd6de4f44dff29b5aefbef1a749eae142ffd708d2bddf76a4787ad9614aff504ebf7257993e8adab5ba97985e960f63fc3fb87c49f3fbb8e3777cfe2d9c9151878dc00e6edb1385262857bc777a2afeb02fa1e9fc7e0eb4e0c7d790b8add0f8a1a047bb80fcc6fdda339817e0cbcc4501fd104dd5730f4e62cfa9f9cc4c77b47f1f6c661bcba7c086fae1dc2dbeb47c9f1185e5f3d4ee218de779ea33e3fbbcdea27f1e9ce79baf3c0167a466aec113511",
            "41855f706cec8f753e578c9fe79b8ab402a73ffc07d100c4afcb1c9410fce71c9103a4fcd0ee162e2c6529058c757243e1b88948f40b80100f37f454b4e166e98a40976044f9c4c0c5c203b949090874b2878eb22e16556d40c9e445c84ba940565c3192422723c8231a2a52ca9021da61667a364a32f2911a9e8692f43ca404c58cea0663c27e3b43275813cfef62e63eca7d534db3d1f17c17633798aa1bb14dd4f5e95087203ac229f40ad131a33952ad7fd7f9b344047868132d535a5f55ff96d4ffc5de7b803595756dc3a106482085107a127aefbdf72ad251408a5491aed810b08bbd8b62c7de7b1d75ec8ebd77c7de9d5167742c909c9bfd9fa0cef8cc33f3bccf77bddfffff33239b6b5f2709909c9cb3f7baef7bedbdd662b306b155151d54fe95fffed3eaca991933996f8c586ae4d48a4c8a7c5f4d73e249d4ba1a73e8db54c22a7207adff37d2f87f1d8e31736115b51eb689a7e1dc752f2c4356c12c7029cc8396d37d29ac425741c7691ab62f0a06f9a93b2eaf08c7f71339383b850f9ea43b8cbde7d2d83f1312ef9930f39d0913bf79d0a03941ff6433ec1ca207ae790574ccf33bfcff6c410c0e2def01d2ba8f7a79b0907ab63717ad349fb8b2be872cde4a5366a8a6ec65c35767303a73fdca9bcaa7b969e66bccbca4a9a880fa6e1c1939e50bf27d2d6852d791a37eeb201e16d0987f92c9402e7dcc92a8e1c0402deca913e0cc286d94b82863548c3a1a42d5d018a88ca63086f4ca4026a90e52d9a2c650e406897fd5c15fe35acbe7efbc4f22d024eb06d94b4f363ae39b89aeb42e8fc398e1d3509453d4110350909e8d956526f870241e8bc6a7a1ae6f39adff4b71ffca3890b6cdd8bda20c0dfdc66121adcfabcb8761700a8df7f4df1f98658fd9f9fa684cd1c3a854032ac69e0773030b64a5e662d9c20dd8b17d0f5eddde806313c5d8bcf1206edc788543fb4fe2d0b7c7d03c7d357ae714e070b33f7def1d30697c0b664e6941fd803118409f53f3cca5340f18006bb13d46f5b6c7ea2a1b147aebd25c4007bdbd855839c0063b47d84a2726ea91be9186bb0d34d94a84ac31489f91ae949696f657bc1f9ff17fa19f0d973cdd122423e4ddbbbe0529a3e8d75a572e9829dffb8f856307e3e4f6c5f8e5e9753cbe760247978cc0b3532341ce2761777f335cd8b6043fdf39819fbf3f01d99b67edc00748dfff80772f6fe0c34f574164f7e87bf61cef5f3deaf01f3c38bb0d1776ccc5d5ddf3f0f0e45aeaf1d98d78727e3b1e9ddd8bfba7f6520fcf1e903d3e7f44fac3e5636dafbf3f23fd70f712f9f9ca0972f7e86eb26c52e39d2ede6ea5eaffce2bff6ef3e0f3793ba9a8308ed11a9a581959117303539a13287e5e830c50a36d8ca5a109e560ea4c63b23d06e6e44393a90c530331bc1d7cd135200e4961a9880f49a6620392d035288cd6edf6d8b1e908b6ad3e8d3ef96351953f0af96935c849aa44846f7cc71a8295c8127a1c2d9a4f14a0b96e18aa338b61acab0fbe9616accc9d290b330704b98421c02188e603f6b0a3f5bf97b53712bd9365796105c4d6d0e20a53913196a5a260cb565555f842ff27f3d9ecdd5c75b568e6bfeb1ba57f28d6f0bd6db51eeb2832c881792914b93f103f9fadc7dafe1630b2cc8565c42e5804ad825dcc2e44d6be4470d96d3874d903db28794ce072ba2fa3bb9c032c86258dff86ae13706c23adff1f25e1db06094e0ee1a28b9f1338761361eedf4c63ff2c8869fc17fb3475f801cc03e683633d1cdd826c60691d056db362286a67a0be5708c89b0d687b7f026d576a20bbdc076f2ed74b87249b11130de52926ecce3d7f7fd01a69fa4dc41a4a6d213c05143a6b62ed904cfc7c730bc8a958fcb2928dc5be1ab8c463a14c5d195bfb0bb0bb441d4b6a44d855cd43ad8722b6a4ab606b962a757e80fa07e91c3699d25dfd315b41512d3788f157f503ff7fe90390db8a6dfa5a6cb2698893f4fa0c67dc5c1f86dcd42e28cc29c7bcd9cb3176e42c9a079461cb601bfcb4c1037797f8e0de862e909deb01d9c974bcddea8d934d4ea8adacc5caa5bb505a3c100bfad9e166b32ba61499a3a72f1f45be02f40ee0c3c3ca067919456899b7158b9b1af0eafeec8e5a33979bcc30aa6f09d6af3f8e4deb0e61cecc75a8e99585e32b437062a60f0a634330ab693546d44d42bff27ad4d68c44cbfcd5e899518adc9420dcd91c8bfdf4fcde5c6989fa2e8688b4116044bc58b6b64c4ccd2f307ee964c8356130989a9b7e9c5fd7e34815b3625ac55f95efc9e7ff99142f2169bd162e256d67c88fcfae9020274b6aceb86120ef1fe1c995efb063663da8774f7072dd4c9c5bdf07e47a01be1b2cc4817963680d7f1c6fee9fc7dbe7d7f1f4ea015cd9b30827578fc3a14543b07f6e1d8eaf1a8787977682485f80e067b4fefc003fdd3b86735b6661e78c8138b7763275694b1375fbd04a3c3ebb9b3cbffa1d7972f128b9717817d9bf6a219933a2f66d6546ca9e2e3e6ef99a1fe3e77fcf27ffee6b8d72ed3180a3a67a539bc5f2d452ff5593c95fbfa2cbe5c9d7cd65ae168e1d757fb535d83015e8c1cdda0d492149480a95c703a422393c93e604dee8995a8ed3877ec0ecf11bd05039137d8bc6a2778f3a6474ed8500f74804d2f81fe619055dae80e614d698583518a11e0110a973d0cb3a0cfd5d939069130a471af3cd4dede068e204577337c4bac7ca728273488463e8368e1a936dab63fb9fbed397cfff2939fefeaca90dcd0dbaca6330c88e39693272ab3f9e1fec858d032d21b14a8345d8765806af856bca21c4d63d46dab847f02f3807cbb0f5300d5cf209fbe57d09cc8357c3c463386e1d89c0eb53513846ebcaa67c",
            "3db0c4bd69ec9f07098df9621aff45deb3e9c7cdf4e3d930f56b8619fd3b8e793574c45dc1d4ef89206f3f7cb83d1632d93b48a97b903e6d0279d62c5b372abadd55a0fcc0485d856f6ba4f54fbf2fff275c3cc75843659b8ebae23b0fb6ba6cbaae3196eb9b209bc541b82a037d3d9570736518ad799c707ab816a67234d018a289cb23b8c8b76460453f0966c728616ca012ced7a8533786b070a03f8bf48d60bed3632a551bab2b7672addfbeff5a1e5383ace8ef20bdb7c80b8726bba247842d8a7af6c1c8fac918dcaf117daa46614eb933be196c8533939d71b9d90953b28c501aa4853dc3acf10dddebfb8dc492f95b50985580ede3dd7163ae17be99e68f626f0126a41853bdc3f511e21b8959931662dae4e538b22814e47626f0e31050e7527062b63be6d67541f3e874ac9b198117e7b3f1ee5c05c626e9a3a1ff106cdd72184b166dc6c8864958bd623b16cd5d8150ef10ec5a558c4bb303b0a7d602271a1db1a19f0502cdb8549a9b9ef450ad8464790b8a99cc8e35f4ae15271bae0c793c8953bc66e0c7b146fe72be187962c247055d2ddbc9eb78eafd9b8114f96522f5ec5a399a0647e3cadef534a67f87a3ab66e2f185fd38baa802b83108571bf5a88dc372f1e8dc61fc70f9009eca7df8e777e0e935faf9ad63f4f1201e5cd88b9bdf6dc6b1b54dd836b906bb9a06e2fe99cd7871e320ee9ddd8557b70e61cbc251545552283563502f32b6aa27e99f93fc262f21ea419cafc7416f6bd339667c4e0e0d82e6ffc187fe4f5917ebc0912fbedbe7e32a790e207f8700a99b85072486268832f141a4be331cace4b9f9b391169181f8d06e880fe98684b0ee1835a0192d33f662eea49d185fbf0883cba7a25ff178aa6b683a823ca311e697001fe72088740ce4b90650d53d83e61562e8b035e1c113a1c42410ab7d0a70d4bf0a3d45ee30a4ffcecbce5f961598d59ee6937a5dc0d2d0fc82b728fec9d852fa8ab0455e37fba8168dff0b46c6c8a4677ae3d98122ec1fed001beb0898866eebc07fbf828b881ff93372e6bf43dcf0db90f8b6c02c78e9aff86f11bc0c12ff95b0f7adc44fd7e2f168b327ce0f67c3d33508baaeb360ea2bc7fe26faff9ae93ea7a39bf82d80c8730a845665109af6004752087dc3405cdd5e00425d445bdbcf686b7d0742ee5197b70d95a6d86a102375d5782b4dd54e3cfacd1fe56aa6a1420cd415c930a161fb39137b5c3675c05d0b17ac3432c726739aff32d5d0cf89810bd34478b5558cbe1ecad851aa8571be0cf40cb6c3dddd31d8dc688dfe211ad4843025d2d349a54da8a238851e1ae6461f632b3bd7587ed306d354184c32a7c2a6edbbb14ed4a8ae42443a889010d31d7dca6ad130702c860d99899aac18b4e419e1568b3766e69b20cc4a0f719199c88bf6c0906c2f4c1eb708638735a35f493c9e6ea135f98a002c1bec897e217a682931477a8008793daa68ddbe0d6306d7e1f67277345798a321d518bb1bed81ef683e772c10849e6be46d1dda9eccc2817a1bf44df6c3fec35771f3d64b9c397b1747bebb81c74f7e469fde3534e7c8c7c33d7d7164b819ce4e71c2a959eea88f3744ba9b40e629e691d1a9c63b0d389a4a6bc81af904fbb6e579cbd3ed6f367239539cfe6af8df3126c9d0a1f23580e301f606e4e78713a5f2bc96efce86e3c5ceaef8e16400560fc9c08dc33bb16fe1441c69a9c5ab33a3f0688e0d56957ae3e29e8db8737c139e5cf9166f5fde853c3f807cbd401eebf7e39d33787af3049e5c3f8e8717f6e1fafe9538d03201638aba62fdd4beb25b075649cf6c5e247d70628b6c4663cd4d9ea2423ce3637ca884f131a6ff8f6cac4ab19b9bcae9396e0ae41f861f7f608b3fdb8b033a5a9ac4cfc1af559effc7d6c40eb576a9e821f293c7a15099f47c48084e466a440fc405a62033ae00e3072fc0bc49dbb06df505ecdbf63d56cd3f88baea8954b47f22c27de311ee9f0073daae39983ac198c6762b637dd8886d6067e200ae261bee1c23046b9960b67b065e870ec11c937038eb886461ae51edae12fbb83fd1f95f7bdb441369322cdf43fae648319e1eadc6a999bef075f683a1df065885ae474cfd33244ef880ecf932f8167c0b91d73c5aefd3b8ff09ff2d8397c0c8bd1901d1f9f8e55e2a5e2e37c18c7c4368980da2b5ff1c1afb67c084c67e131af74dfde7d3d8df0c7d8706689be44020ce848e7921d47991d834351aa46d1f8dfbd7206d7dff316fe795fdd27e117ac484a5324bc2eac4fe4ff3ebf3189ec5515340109bf5be464b805bcedeb86de3861f5dfcb1cfd6037b699e3d4a60040f161343dc14b0bf5e0f27eab85812a784696536909eed8b97ab5c706a84bef470354756e2a2fc833a43d1cf94a7fc471cbf53ff3318e58a34fe97c74ada3656596244a221fa264a1017d61595250331ac760246d64fc388fa468c8c37c689892e98dc4d1fb9f1b19836610986d1fc6078ed444c1dbb10697199f876750ec87e67bc399a8c963e9e98decd183b6bad91e86789e1755331a7693d46d65462609204a9d1dd10e9e98b5e3e425c6c76060e79e1f62a5fdc5a178e474b5c30be9b105bb7edc3db3682273fb4e2f2b51f70efc1cfd8b87a1bf2ba67e1f6f145d4e9f18eb83acb11f7967aa1a9cab1bd3e52d81ae7c06fd3d764bfb0d2e5daeb1a75d49de95f726930794a2eed5ff17cb93223485e4fe72f179dfe392f7320ddef777132964eede54ef3242f9c9b1c00f2533f6c1e60895d0b6663ebf86adcda3b182fd6856173a11eb64e1b82eb073774e4ed93fef218146490ca287c78f13d5edc3e8967378ee3c9b5a3787cf910ee9dde852b7b57e0c8d2f1d43733874ad3035d486dcf7872604513",
            "797cf15bda3c3d22fb762cbd9110e2d7c75ac8579f34a9cf676e22c7fb8ec7438732fe6998ff9f7c325fae956573d5d4eee96a7188a5d88af235b4c53ad702c41b3ac04047a7a33e6f804b00ba062521253c037929a5185f3b1f73c66fc4c5133fe1c08eaba828a841947f2c92c3d3911a950d272b571af3ade1614bf309891d443a4670b6f0808bb93bc4fa1278700d50a0e78e688e19760557e18e4b897495691c09149a7fa7d1591bfecfda74795df3f278dbb657070af1e0601fdcd99082e4404768bb2e847dec0e741df51a6933a44899f213acc297c334a0e593f65f46f715b0086886d06132d2727321bbd30577a769c1c9291afa1e9ff6fcf9cca2b17f364c68ec17794c828e6529f8e21ed0966441685e00654e3c660c0c02f9b005ad6d9720a33ee6ecfce5f121d9e41e56c496ab72c9585d55c34d5fff6bf7fb7ff9ddc368547a2f5257c23e131b6a8e9ea47d8cb139484c1a5a83e370daceb37dbd8925be1559a1922544808e12a606a9e2e8201e4644ab635dbd217d5440b61d831ae2af44b6e5304996a3721d5fb9638aa876ce953fc47f0f65863ae56bcac7d262330c8c31c0b6065bc40406a038af0f46d54fa2757623ce5db88321a5d9584a73e04dfdad509a918271a3e66240c540541697a2303d05eb564e06b95980b693ddf1e2d2142ceb6d8ba505e6383ec91939b176f4fb4cc3fc992b31a661126a4a07a269520bfaf7198d92086b9c9b6a07723400eb06d8607591180bf2b4b160767307f63f7ff9014f7f6cc5cbd704278f5f415e7a1e0e6c6bc1cdc55d7174b4358dffae383adb5796efabd73e34cee0acb5ae568c80a769adafdd215dabbb5de8438663d6cda69f16f9159c6b90eb7ec5a17f2dfcff3c07bae96a0916c578bb6c7591185f556028a3bb8d1a75768c27de9ceb891d154668a9abc2ae6934f7599b8123553ccc290cc3a57d9bf0f8da31bcfde12664ef7e005a5f836afd19d2d70ff1f2eee90ecd7febd8365cdbbf06e7772cc2919553a5fbe68fc6c1798da432254a5e3b78b39348ff729cbfdb99c4109f95d95da3aac2dd9d9d2cb81aca4141414a69691d3989428e3498791c6d30f97cce82c77d190daf363a065e9969f399237c0d764aa0cf607ca3a2a6d8de4be421db6adf9d72a2315a4f8b07039ea023b7be3fad55d2a2baa3a6b01e13eb1662eda2239837652d620262a800a72004b985500ea6d61db9f8ddac9d3be2089d2d3de06ee34d6bd420783b0674e41734175b234260864146fec8d6b2c296e0323c4f9942edb2e84e2db6cb7be1a363e6f3493575ee1bfbd7d6578eff499ec66d4fbec9a1f1bf3f5e7dd7807e8946e0d88e8373c2b708edf310a953a58818f03d8de50b68edff71df5fc71ec0c025b0f49f0a6d9b89a81c9447db341f8ceba10f96c50858f83743e44d63bfffdc4f9abf0e7c492e8dfd591048b22134cb83222711c34bfc68cebe14bfdc5a04d92f173b726afc747608d552694f79e9abbd35565375b4e7b2be76fef679dcc618aa2a1d95eff38be16ab68fd533a4d689adb0c8d802392c1e6e7985e08c8533b61a986183c8022724b62866ebc093a98e1a57152c4965a3afb72aaaed19705460225c91d76ea9a6fcd492a758a5ca5094eb954effd87fbe07a7adf5b9a421de40b66e801dee2cf5436e942352e2f3d0d07f349aa62ec2a953d7b173d751f44f72c1c9d1961855ec8fda01b3919f1287231b4af1cbfba734bf3d89d61bf27a4c3fe3dea9d558556c8c8d7d1c7172b227b6ce0946b7842ea8ed538711831a3176d8740ce93712a5c5b598986383575b7df1fd0a5f2cc811a13e8a8fc9a347e1caf5e7f8fef62b3c7ede46633f70fbf6135415f7c1a2d95341ae0ec4c971663832da09d75afc51dfdd425a1e2824c92e3a155cf58e79a53e89ac199a7aa4fc4ae683c1a3f21f0e35b45893f671befdb5c4abd2a768841203368f8c4e1690378fb69077cf97c81ad2f928f6e3e19b616eb8d9e48ce9917c2c1999879b476761f340274c8dd1c1b78b67e0de997d7872e1085e5c3e869757bfeb88fdfbe5fe491afb4fe1e74717f0ecea615cdeb70e47372c941d593d477a72fd7cb261eaf0b6786fa711da2a4acc1dd3a67de6c77f887b9f2e97eeb1d1f6471f6cf0179e9fe0a849e633ee523fce24d4f7b9a2db43f53ffb05fee9f8cffcb4f9a188cd5421d32da2dbfa8a7c60c535822d6d97dc6d3c20111ac1584717012e3e185c3a027b365fc78a79db11e31f056f07792ca08432e00b29537d3165416b9bbce452aa6b5032fc5c8211e419097fd71004784450c1ee9130d23746899e2bc61a0662a2a13fa63ac723dbc407ddf5dda483cce2c828dbf48bd61c5d75c66f353d3bdbc716cfa5f1df43c495dedc9081d79747a3f5ce32ac283780be3c0770f84678641c45f28436b8671ca0f17f218dffcb3fc5fd2d87a9df2c58fa4d06cf663c9aa6a7e2976d7ab0b4498491e71c9878cfec58eb17794e85d0b28cc6fe2c689bf484c02487c6fe7c287193d0501400f2623e1e1f1b8b7b9bbbe3c9813eb8bd25835a56692b0d3361135af777b7d452f95a799bd2effcfdcc0a73f3875c26837461b365930406d45e531bfc4c63fe335b4f4c1418639e91390e19596189ae29161b9aa24928a6b259da8855e5a09ba90a76e7b1b1339b8d787325aa405b9bccd711dd776031ff4e79c8fe7ff3397f3ace66a968b457841bb7dd5ae88dc75b23d154e688c8e0aee8573918ab966dc5b7bb8f61d6f4851824af279e4b7384c5f6a8afcc415c543e96f5a3b5fbf7a3f1cb9db9686b7dd9e1e7bab4a101fb069be2564b20aecff1c283b5a1b8ba251103b26c111f168bc6baf1a82a1f83ca8c183cde12841f77456259811efac588",
            "30af6916ce9dbf8b3ddf7c876b375ee1c9730af71ebcc4f041a3d0585f0bf27006a8439ef8718b3feead0cc09ae1deb2525f617b55b8d13d73811687c7e0c9d7d12d9267f70ce976a042337f5cfe6f58bb26edaf8629726d2d272c77f30205d4fb35ce6fdf5f9c28fde1f8a8f6773b3df174a503760c73c281b12138bfbe0a97be9986c77b07e1607f1dcc2aee8ae36b17e3bbd5737174f9786c9d5a849955e118991386faec14b43454614ff370eacca6b9d2ef0f6fc6a57d5bc9e1b50bc9c8f282834ec6fa5effc2417e8b89545ab3264daefb15bec0ff8f7b13188c97af8e2705de6976497a77c0ef03f5c398d8b7a7323e6a7ff255687fa5358c8eebb43646604dc6984649fd74ac60cb13c39eb65951beb1f0b0f7863c87a0014f1bdda2d370f1d86d14742b80998118123d635adb075109a13908708b44906b08559659d3113310e91f8700cf084406c623c83d0c5c0e07b65a022c924462be51306a8d7dd145608f585d3784e97bc14b68ff3e5b1c4a724481992c15952fe772676330acc56c55a9485da5fdbbf9891479b78cd6e0a771768a2daced522109dc00d7947d88ae7b05ab88b5300b58fc2bf69b052e82a9d70458fa4e06c766148e2cf7c1ec6a0ba89bd1dadf6f7a87cfdfd06524b44df33eaef59be441c724bb23c65f899b40ebfe201afb67e1d9b111b8b1261e77b665e3da864cccefeddcd6c54a8bd0e75467c156edbc5f1f9b9cbb2e535565900201bfedb96b002ebaf861368df1e3f445d826b2c4321af387d39c7aafb11526f08d3046c71003b5f450a4a94355b084b208a10a75a6af264a7c59e0a832a8a91a3c2cd7347961aca8e4abf6f10a77fafcff67ff4b322dff48aaa781ecf26c0fbc3993885b6bc2911cea81bcac0a6c5ebf179b36ec46cf8c2294e495a3aeb611334a1d71798e1daabbfba0204484bb732dd1b6c70d6d273320fb701f3fec2bc1b3f5eef86e8a079655da60668e19c624e821c2c51635958d282d1a867ec56978b03312d796fb635c8a2eaa5383b075f34e3c79f60ebb761cc5e1c397db6fdffd05f7eebfc0e431d351dfb72f5adf1c83ec5c0c3e1ca4e7d9d9085cdc908a7ee1066d8d49221266a3d3e3535dbf7f8b7b0a2243ff6afbfdbe1c9b7674972e1f66432ecff3268303b4c9cc30162eb784d036c40d079a137160550d868fea09e7e478f448b3c49339d6985d168ff5d307b69f5d5d82578ff6e2ddeb4d787bd4072f36d8e2c0446b0c4c71c4e01e296462711a1998d1852a4f4fb814ea645ba2f5dbe77eb92fbc4343d25ce4f76bfb2ae474b1fc98f1785b14693f9d1276a556287eb5cec5f4d9d04fff47be8ab96222fa1847e2c8555179976ee085785d372a94d6e7866c3e3c6ddd11ee1585109f68783b05c054df0456c612d4f6ae8148a08f10ef2894f4a84761da20748be9050f3b3fc4f8774549f7bec84e2a4197a04424456420d82d94623195c1556362837d3a75c62117634c229169ec8f14e34078eb58136b9e51bb15df98d8689b901463ff756e3cc947ff0b6368a745fbd8d4860e0dba2df701ac9d5d2423e43c5a3fdcc583d55d11e1e9097daf957049da8de0cabb30f35f028be0959fd6fd5776e4f333f59a0891db6488dd6ab1778e255cdc5261e8369d32f59c087dbbfe1df97ce59a9f6f920ba1693678927c30b951985edb05e4cd1cb4ddafc58b6f13f07c7726ee6dcdc4c232e7b6180b4d22d2506932d3fc2ab1ffcb7a0699b4f109a08ffe6c06e38ca916930cd13790ddb174c62b5af393b004bc74f2c171890d1a758d50aea58dbe7c5d6c30b0402d5717555c2155c3d6958ee3e8b7f7d0e01277a112093552426d773e6e9d4843634a176a900f9fcccf66fe126eaa6cf63b3bdbd9fe58d7f0380cce53733ea7fde038770ad792401e1761c1e870244675c7bebd27306dd23c64a6e420a77b3eaa7af7c3e851b3509b1389d95942e4f8ea60eb403bdc5ae485fb8badf0e1ce4c7c3b231a239374d1275417c3620d31acab31652f1251dd12f230a0572ee60d0ec0d9792e68a9b241598c1b0694f745c3e0091837621a7efcf1175cbff10477efbdc2bd7b3f62e2e86968a8a9c0bb3727017203efef35829c89c6c3434598dcc35c3abd9b01290e32dcaccb627dc9693eaef30f1dfa57f6ff7c1e97f20574529f637632ca86db87c160dd8e32e792ad1562eaecfade5832a514856307e3e1eb7718b0671fd413c3f1749927565598635f9d3d5e6c09c28beb8bf060f770dc5c5f822b8b53f17a73b0ecc9229bf65ea1fae7b45535b3842a0cf9e6bd3f2beeaa4448da1f8d8dcfd86ff772add3b3d66bf9ef5faf7336395fa3fbebf9ffc375ffe7fb13c9d7600ee7a833e53503affa0b6d4886384cd645d70b565a8630d0162292d6eee19e5108f28a44a86f6c47dd5e4b630be871b431b8cf781cdaf518953d1b919bdc07c91179f0750e467c60327253cb90ed9782082b1ff8b905515c355558f0f5b1d1af0c5702076284791ce20d7d10a8ef24d363730997a5b14f535dc55d599931404355f991584be7b52dd74853bbd3d7f9fb7bb69db6066468bf3c292177d146bec78f8787a03c521fda8ed3e092f80d3cb34fd2782fc7ff55300b5a01b3801648bca643e45c03b15d2e3c837ba1ba8725f8d62361e63d81d2312f035fd483c67ef97a3f8dfd6639d034ca034f1886753333409e4cc6cbe30568bd9c0972af042f0fa56361a9435b9c0d97883554169a69a9fe9e73ff9371fe8feec95815fa9ef4086493d27841bb8d508d0c6469481fdab8e3be9d1ba8c0980efcbf65ef814ba6f63407b0c3608e10316c4dacd63341168b874a2d1dd92cae01c9d4d46cd353573ca5a3aaf84c474db9fd408532f5f3de1eb43e5c85",
            "cb2bdda82395aaa4c84dc5ff773ab7b3fdb90f600a93a1462614d9b4917b89687b5080f737aa9115ed8a8a5eb558bb721b7a17562337bd00853925681c321573e76ec5808afe0876b0c4e2724becaab1c3de7a075cfba602d54134570b1262548211a6a61b21d0541379010698ddcb1ccbfa9a617aa90b2abbc7a1775e396afa0c474571bf8ec7e5457d70e6cc0d10fae7f6ada718d94073829143d07a7f01f07d093ebc3f0d426ee2c58dd95851694f6d2b17624492e88d095fd352a0a9a9f037e37a9fe78a9a582cde6325608bb96a1d107dce5597ddbeafde5eb6636e390a9a9bf08010bc841409bbb640a9b408777726e248bd092e4d75c485e571b833c70ead77e55ae7894cfa780d8e4d0da56e2d0cc4eb5d81cfaa128dbbff0efab53cf97c7523a37f3b1fcd6bf90ced478b3d58e72738ca63fce4af85c92e54dea77e6e21a4b574f58b75d61dfa65fffe2045f2cf979b9f6b181eb4e6e85e73e31b5fea6aec417a9845cb62f47ce16d6c47633f1f36c656e81ede1d219e9134fe472184c6ff00f770c40625a1be7a328eed7d8a05d377a1b0db60e4a5f6ebd0ff41ee51f4ef9311e218801d81e5541f492865c0e2c04d608eb12e799860978e445d1704ea3ac35fdf0dba6c2da9899e9878db787fcef12f6ff28d172b7534d8b6fc8faf75ea9cdfe268c6cb6b66a584b8b7117209ad3fadc6cbd393b1a04402439b3eb0efb217b691eb611eb0b463bf7f87efdf771638960d983e3a1309a1a1d0b34887855d72c75abfae65c9afd8af2dc986ae794fa80a32616e1586e3dbab69db3402571686e0c95a7f902b59787c20839a5168230d37d394fbfc3febfe7f725d3fc5dfd9b5cff5f2543fea044603575591e404b25ac93109452edbe3e9dd15b20935b528d06063aec81cdb1ddcf03c28126f3d8271466c8b453a622cd691a05c4b80347a6e246a68c9a670f54892267b35475dc1d190a5a23c3488314da8a64486c532dba49b7868dbac23db14af489a2355de8648940c189dbcf8bfbd6fb461576df5b21050afcf2652d29bdd7077993f0e2dee42db352ff42bafc3ac692d1d1ca0b2d700340e6fa271b9094d539621b7471f0ceb668a8334f61f18e58ebdb3e3501120407d1763346719c2df5217412e4e18901d8d3e7919e8955b8af2dec350555e8fe2dc32e476cf45514e2f541455a334bf12674f5fc7351afbcb2afb63d9dc717875b211b71779e1d58e5090f75bf0f2c9496c1ee84c7d37585bd652644cecf5b9697cf5bfbdfde339883afccb536c8db4c8ea425edbcd1505481f5c8a89f7ee61d6c573108cac0363d95c68cf9a8447df26e0e40c3b1c9e158a65d9fa189f6182da045b3221d3996cac36931d2ed597ed29125187065990fb4bdc4873b5d5b1183bed86187bc19c703b9df966da5a2c47dd5f757c6debd9981bb2a70b7f68bb5632e3c7350e5617a638c85fefd77a2de503f55e1e17d8fa58f6a050f26191959c17287e053effcfbc384289a9d49e270e20931dd248be79b42c4cd71d4e220b0ca0f9aaa7ad23443a7a28eb564963463744052420dc2f0efe6ea128c91e80cdcbce62eea42de85b3c1155f96351d173140abaf5435c501adc9c025060e28d3ba1755868968985d6d9d8e05a89790eb948d7f54012dd53442130e718c0ccd0940a740ea3e2fd12a416fa62ffdf9dab6aa719fb0dff3f1db38434febb18f1a53fbd5c8d477bf3717f4f358ecf0c86b7bd1b78f6d3601ab006d661b4ee0f5c0cab9045d034ad477d633fbcd89b0c2f336b70ac6b21761b0d3d9b4a688bb33ad6f93bba593e14d8f1888c8cc7c36b93f0cbb97eb832cf1bb79707522f7744e3d42c7f59638a89cc5fc426c66aca63cc347f8dd3fc27eb7e7953292e76fb239f20dfdb96f1565341a93dd658891a12c9c38d6333691df71eb217f35017e688ad02130ce3eb2183cdc5205d436c9458628bbe199af8c698c2334284064b9ac9e2901e9a9c712acc7f79ef5a2d5506b165aa4a737c353026932dabf2579205182937085495bff4b774e657fc9f6ddd7c5586329951e725253fe6e1c478677a5c07606d533c7c1c7d505ed81713c63461f490e91843e3bf9c038caa9f828a5e0d28ef6a8f03f576d491095e583ac015657e3a68ce9620d155081fb760e4742b4049e1405495d6a1aedf6894175422278dc6fdac62faff6b505d5283cade03e9f79e86ed7b8fa32c2c02b35cacb16d54148e8fb1c1fe116e78b13d0e0f4f8dc2fc625bea603f2eb5bcb71171d0d7eac35767fddd7d3cbffa01e87eab7f814ffbb393c5b2bd337a82d72b1f1a53c682377b0a149b2642f9d821782e1a8ff76b3db1b0b73196670ab0ae87166a023894584d65bdb682e2715b2e9b14f908c9fe81a6d4db250e6dd406a73672d49b90ed1e647bbde5b368078183f0e35a89ca9c62c6c2379b1d0879977b0fafe7c593fb55f2d75dee4e34dff7fe900f0df503e87efc3a9ecf756ddb62f6d1e73ff4ab5867febc9ebed58167482659a7b676d3739305086c6140db28176b3b0cccab46b42fad13b9dab09358c1c5d21581aea1480c4f478c7f4287f65f35ff306634aec78486a518d2b709b9a91508700d81bda93d8c04ba98681a81b361c370d6b71e5b5d4ab0ddad188d6631e86118882c5118628c7c612cd0438073285c2ddd651ed6ee24d0dee7b6214f3b8a3e3741a7e9fa533d636eabc37cafafaad2be7b5e06756f430aae6fcac4adf5c91895a68fd1fd23e0e05f09a1f33cd8862f8696f908e41457827c988f6f078ae16b6b03a1d358881cfbd2989f052dc35c6818e68365980315cd50f4eb5f8a772f56e3f9de3cea4ab33b2ed276f2d44c3f6c1ae422adeb22265e86ac762335e512732de63fdde7fff97a",
            "a7d316e5065f81718ecf601ce4aba8ac546730ba6a2b31fad37f728aaba4244d7652a50e35a862551e03bd3dc5787ca00c64a70eb68eb1c638ae1ef61b5a6226cf181e2a4c04ab6b20539387415c5d2c1588a4f51c1d12c162ed35fb58a85ac5ede367a6d0ccf74384169baae1eb523d55b5655e0a2c62abc23cc2515260fc0f6b119ded5faf897cbd5cc26032df3818f3a853cba2a8eb0bfdf1cd403b5c6989c4fcf1f108740f447e660946d64f40e3b09918d5301de347ccc4a0bee39113ed8d3db5363832de035372cd3136c108a5c13a70b5a3354c4c0aadf1f35090914f6bfcbe185039048534ee97155421bd7b3e6283a290149f8ea2c44c2486c4a2d4dd0d4fc33cf0a3b71b7a1973b06d88136eccf7c3a1f95dd12bd4403aaa8b0ed59c6344eb7ead12dec77abe72fd238fa3ebe87f43aef7290e80c8bfccd321557ee4cef6346a450f2e749b2741e9ca39685e3c09b51307c158bd01cd8b4a65f7a69bb7ad2937a15e7d9b81d65b0d52f2bc8cec991f39d28cd7910eb61b4d258ebbe96b91865463b272b015692a337b5c12a13fc141c8fe322e46efc47871d1e3c5b69e3f6fb530b856c670b9395063e5fd665bd2b6db8b905b0997640f0bc7c8aea408de4cfc384ebe92bd7e9f6d8484ee6f530d5ca87e9230ca9367027d0d4d5a3f7ad178ec4be37f196a7a16c0dad81ada6c36049a5ad0e5ca6b00bb222ba1104d63d761dfb63bd8b7fd06069535c2df2d8812d3da4697c3055b5d158e3c3dacb6ec8693813518ed948250be35a2858e28a171bfcc341eb9a671f0d77786b1ae3c279053c767c6fa4653119ea1c4cbca8df8db78df35e20b248c7fad61d4d97e9b4f1d798047e438489fecec81e3f3bae2d5897a6c1ee18df575f6787028155d4243a0ac538998241acfdf6fc0f53d83a88d052c74f1b606d3b00c4c9d9e50d1cd828d7b0682fdfce1e5e88ab56b6642fa78392e2e8ca68ed31ae9e8247fec19ed83a5650e6dfda38c88b350e32743a652920547fdefae4bfeab6b4ddb0479aed0778136ea64e72c3bb26e9029599ca54266f577274eb40dea1ba5420ed43341ad66806c5706b9678f961236a6a60940adb7c0e5197c7accf3b04adb0483b9fa8854d74491261fc59a0224b1d8d26a2d3ed5574b4019aa2bd1ba45e5e3bd95ef215466b4056bb1dab71a5950f93407df23b24221974fd5f074de6bab310a38cc8e3921276042ba5b757280ffca07305c538149125d74dbee6cea8223a39cb0aa97252e2f8dc19ae67444fa07a347721e0654d56344ed24e476eb85aadec3909b188b8d5566d83fda0d93334cd19868001f1b4b24467743068deb45d925c8cf284025adf51bfa376260451d7aa4e6a2d2da12c7e38231d9de12736d4d712bc005195c4daca79f2f36d4433e5f80257dadb1a1c109399e3ad28a603d52126cd86e23d4cad654d1e838ef357f5ecf4fbe16f877b9d79fe3e797873bf1c9da7e22e9e57a03044ca9048310f0db08540f1ea6ca9a8749c9f799647ea11e995d684556e45be1c4bc724adada4c0855f4b420c182fdc5180fa42f41b6224385d68a4a82ff30fef96b0a8cb22f8db31c777f86d99807f3ed329f6df4707cd662c9dcf1c5ff7c25d8ffe55c885755552245a200122774946aaba9c1d1dc0ee9e199f0b4f7c08ef9f3b164fc1858896c60662081356d7fe4397cf47902389ad963dde27d7878e71d0a334a2096e7f6155bc1c72918b6625b0875f45068e88e23b6d9986612091fae05a275dd1067108038a300741387a1c23a5d1ee707777b4794a717232b361dbe8e7e88748da4bafb756fab8aab2699fedd76ab2bcb739c0cfd9a72fcffb76b000df23d00dd7c446d773674c7f1e670fc72a519efeecfc4b02c6bdc9a67871f768560ced82e78f940aefd97614bad1fb5a5421be3d3f5c097c42123371b2de343b1bc5682b92313f1e8f60ebc3c3d1e7b47bae09b11ee38383180da3dcc939a576c2b2d09d423d65ce6796335653b27de5715dfdfa4afa9445a0a38ada7faf164af0ee44ac98bb1524226c9968f0f941e1fa222232744f8703216d2d765a05e27e1d4082e7ad929e2ee6c0390dd66e8ebc1c1287503f4646b234a5d0bbd34f9b2257c91acaf963631555326961a2aa38cd43b2ea75ce3c9edd711fa39396d66d7b656df14599a3cdc3075401a9b4335f2f549315f40ec386a176cd8ccabbe1cd68b0401ef43868ef601fa7d9c3a2a6574ee09fc23ce2cbfae2c4747c72bfaea6a644aa9b3ece68a68ac2aa1f1b7c20adf8e0dc29e6585c8cf8c47725c168deb3d317a402492a3fce06a618b6feaec70809e17737a881065c985ad9517227c83909ddc03a53dcb50965781fe34eef7af1e86c8b80ca41a1b02d9f12039c920fe6e182936c205176b1cb631453c9783097abac8e6f15018a88bea605d6955a8014976d5bd21e2b263f45435bec432f9a6b42486aa529180c3eeaec252b365a8fe8b2d948f99bfba6dfc9c0728ce44c095596873a963c34cb0b229b6dd63c62c6ac0fcdab6eda363da6f0cb121f3fb5a5d76106acde32aa8beee22516bdf5766203b39d9affdfb854e2f4ae24db4191f63f8ff2847ef1f5d0725b2268dfefb3f3f2f42d6287c45d8ffa56de866c062914c91df3e734de138a60a8324f875952686a4c1d3c103fb962ec48291c36123b2ee88f977347340883b8de58e81e0d336acb2b002d54595d0a5754c74400a32bb962121341bb6120748748cd0641a8d6f6c5291aceb82aefa5e48350c84bfae034cb57461a8c58723ad87422cdcd1d43096ea199fd9912328ccb72b528233911948cf1f9fd4b6418983488453f0a0df9d77a73ff36373e63018321b6d75ec9b1a8e5b1bd3f0fa54030839416b990cb4",
            "14e9e2c20c5b909f86d1af4dc4a39343b02c9b8fed35c6b8d32cc28525ce383b5382e5fdbdf0cdba8578fbe3613cdc998f43e35d706a6e34aead48c0378d3eb2e9d916e8eea24d241acacb45eaca1c3753de971ce49fdee47ae356a48d4afbdede2cd9305f257cd78f857777e5790f87e1cd0f4b31b2281e6f7e3a405fe33378fe5d575c1fa781fd45cae8eda8808d95025c1ea5833e1eeae8a1c2476f4d812c8fcd6beba3a5437234b9445f4d699b81ba6290dec7607e954f9f194c77f415eaca3ed87a62385f1f0378425c94d861ac8e214a38da5865604e1db1b227e76c9cc8030777029f40bc75f323eb8dcd7ff662abfb7eda0edde907f863bbe7a1a5a5f58ba7015bb672880f75729a3f9617dba0a9bb18ab2b1c716a550e465786213fd204e4d530dcb9208f1330c1946c53cccc36a2ca420da8941867cc1a1488643f3d7878d31c81d6fa11118908f50f47b4bb2706d8586004adef67d95b50e76dcdb1496284b9341fa8d4156087893112f95c546b6b2385cf439f705d6a449c01f137e5afd663b355877e2c752a8f991f61a7cd3b536c217e3fc3cd8e6c0ef624cb1c2cc94453e3d63223bdd3f1063ac3c4da1c8bbfc9ee28799e5df9785ce626e690cda343a5cbfb9be2dde9225c19e9492ef43720cbb285efbb3b72a609157edd0073c4d54013cf5779fff26c9e0b5999aabbdd5157eba32fe1b73db8721fc87fa30de5184f730186f2fea141724e20dfdfaf40beee791029a171d8555b62a1aaca58622410929ce85c6998572c823cfcb076ca048ca9ac80a5b139cd01ac686deedf91bb27c035b423be5f8f2b80bda9238a3307a324b31e69d185880de80e4b135ad30bcdb0cd261d2324a18815ba526934fedbf18da1c3e6c0d1d41ac34babb070ec18cc1e3e1c35f9bd91da250fc9917988094c41a45f029203bb51197ee9545e489e6c58b721ad0ec656de9dbecd7ff703d063f9225f8141a6f47693b59eadc29b93e5c0ab6ff0e4501fd4251b62ff2003ead29a388a602ef68f75c5a6325d5c9c28c1de01da68ca9360eddc1978f65206429dc1dbe37978f64d77fc74b817f5ea4809b57b4c80b4315944a2ac386d064ca50a339632e32be461f2626aef2b429864650e9372505740372b065eac0b87f4dd7d90674bb16a4c22f62eec89c74bed71aa9281e37dd4a88d3d9451e7ad805a7f261646aba297930ad593c9978de1e890600d0de2c9625e15aa2924eba92b7da94f3f3fd9c8652a902643f187c7162ea8e60ad1a427c671892dce99d9a3871617e3f986982310c90e1a5bca4e88aca85b362e94cc37b8ed473b0fb24f64f5c84d53cde8d33a42e77cf963df59b311974392ec05ad2bfa3b62e76067b414d8a039cb0cd3928d31b2bb194ecef1c2eb83f178772c0fe47e7f9cdd99877d3b46e0c68519787ab0085b073a5189121daad4cc0c03adcddb9b7d5cb023cc1bf7ba06e14d8817964b8c11cc6661bca12ea6d35a7f888e00093caeb45e47200be468a10b970b1f6d0e1561c76b3316b0ebd4543b489b3d434565a1af80f77e9c8598dc0870232421b49d740d969eb1b792ee30134bf7989bb4d39decb534256b2d4cdef631d25fe8aacd35e570987fe5f81b958fe57518b3442c0eb93c4ad2b67f9c0df54da31bc646b11f7b4b38fdb535682ec3e858dff7b7e4b167db1a72494ba30721e7a3c98106cb8711963cab4fbfef1cd3ff7b5f98bc990a99cc9942b6a6dcbf24f5b27643cf2e85945cdfa746c46062df41a8ee910f73432338d17628cc2b1a419e1134370887b7bd1fe2c3bb63cce01654178c477e5a7fa4d2f81f17940e6b0b5724e93b6183753ab2f43d90a2eb4699690920161a21252c0e4bc64ec69ac9b3f0ddea351837701016ceda8c01bdc7d3fc211f09e1591d7503638352914cbf57ac5b4c5ba85308f1b0705dafc96476fa00fe9dc34d95ef01c808346923376af1cb996abcbf3305b22bf598544c6b942c3deaf97a6feaedf9146a773f7dac2a3140bf306d4caf72c3fd5bab68cdfa04e4c303b4bebb4bebd9d520cfa7e0c5e1226aef08b7b681917ac4d380754b5f4531d086abf679de7d6d6b30722d4e0d4fd240533213e1ba0c98282960753f11c8c9425c19cec0ee1a2d4c8861e04aad320e55aa538b9394a8e668450cf45044859b32a646a852bd6c5548863a87d8b3548feba829d40b3514d9b63abff259a52fe6a5bc6719b2545e8835944919474055d13c7bafc406e74cedf0a3ad1b661b8b11c56261bdbe052e98d94b1f583ab7bd76f094fee4e12b3d6bebfcfe92a513596264b64eaca6d8692bffd8f6c9af3797c3e01c91f03549aa934eeb9c422b9a033861698115fa4549b0b2da04dfafcb00793d07e75bfcb1b8af3d8ecf8ec183b5a9b8b1281c071bec51132ba1ea053a386c21a10e589b62979d158ed95ae09e8315b69b1acbf19eeacae361809e0ecab4f988a3313f9dcb2579da7c12c8d592966bf350af27c420a15096a7a37d245c9b7b344628900e35d627579dacdb49805b1b89f293b585fb50fb2c4db15264840d26226c3411531b4d446495c4988c33362015067aaf3cf9dc5a7dadbf6c8ce0e773f2a4fb8b01193ac09d446af7f468699dbb727ba1133793d19122f8573f41aaa1bafa99603bdd5b037b5a9d4ff7d29e2c616b883ec5f877ae01ffdfc510792ee4253c168bf488cc912687768787bd0fcad2b3509b5f853e598570b7b543b46f00bc1cfd10e21d8360af0878da7b6350c504cc9bb213bdb387a3287d10d2624a10e69b0c1b0b27f411056286793c92f4dc60cdd1059fe6c18e6676488b4ac1d6858b70ebf03ed495546265cb2efcf49ca07faff1c84c28415a6c1152630b11ea150b679a47d888aca5b6621b62",
            "2cd093d724e8c4ff7fc7ff20236506b1e2a953b7be29a1c8cd06dcdd9685477b72717145328a82b85856658c5555461813cb414d82398eadcaa4f5cc28fc787632bedfd00def9fade8c8692e93ddc7a30325b263639da941b146c492c3dc4c63bfae9790f535f9fb7fdfe4e916a821496cacca6521c7420176ea0ce47baae1edae00accbd5c6e244550c0a54c5da4c26a6862953b3a295b0374f190d014a54adb74aeb89deccf6742ba5d70225c50c014bf18feee11fd94a1bbe2ae3349fa9d01ea2c596ddb575c52d4b27ba3be3898d1bad2339f0d4506f9fa52b22cb8d4c495fa12ef162a9117b7555e2cad220819a2c62c95289d5d350ea9c337fae7fe40b5987e41c20c951d83626594c8da5f5ffde09ee78b83a1aef5eedc6c3db8bb16e591dee9e6fc4985401b60f32c7e5992ed83fd203991e06a8e36a6391d808cb695c3e606182c7ced678ea668bddf4e3913a3ac8a631fe88a509bc3435e1a1c996f970b4369a6ab2eedbb159a488cf934dd0134a1718eb633d8de7db2c4cc83e6bf3f6cbf6966d6ffd5c656d3101b2d6302feaa8a529b54a22c206530936994aa8733616d45003dda7765aec1902b6463083c964fe85afb5e247df3b31a68ff70b127c49eb0fd365d2d63d58d0c3eac3ae1e5c3225493f4b538525f7e37f8e7bf9dc3418ff5ea7b6b3fddfc50f47bab7b95bb9503de37a51016e11e81edd15e3aa06a0bea80f1a7a95c35264828ce804248784c1cdd60b613e3108f008c7a0f289983b693b1aaa672127b986d6ec69e8119b8a489f200c9244d03d124e1c43584b2ce169ed012b633115e3158d313583316ffc189a33f4c7ba96d3b87af605d62e3a8afaea1928cce88f20b7f08e3d07621d0399014fbbddc1c4fe8e405353e37773b7b37daad934ad22fa9a268341e6d447c9c8adc1d4b979b1b8b22291d6f28bb06fc766ec5c3d13d34add302ccf1d3f9fe98397477be1ecf26e38b1a02b1e1f2e07695d859f1e6cc7936db96d074758921c1f1d1832951b441a5fa5bffff74d9e28e45daf4075b236579d2ab557848fb60282f414f0dd603e16246b6046982a4a9c95d0e0a524dd91a382dd452ab211614ad2182305d214cf2495beaa1f442cc5105da6d2977aff3f8de3cffb001ce907943b87d5913ff036cdabefd2c73b56ceb868eb028986f2074d55c616094b79a48a12a30fcd174af4d415bb0bd414694c60840b994a2e061fe3093be7cc9ff32cb95d5961a2ad49fc247c59758284ba38c71317b655e2cda97e98dbdb1c279a43706b451c06c7186241990d1e2ef5c5d129dec8b6d1c57c43436cb410e3908d195ebada81f2a2399a932d261b1920588743c5f339b4be175021b4f66fd0d5f910cce388e5be07b198b38dc66f52ae2f241bccc438686ed24af3840ffb2c4cda6e3a5a5324d29f90f850f2c4cb891cb63495ee373769db4debfefd5666386f67294b156a7b319495ff88d3fce5ae3321439518698c03319e36e4e5939b52b9d6f8766482747ba6065953247e166bc373e4aab0be8cf1fac4197ec3aab44eecff7f0bff170ab95c921d97d71617d81df121f1983660301a8a4b647db2f330a2ac0c16c662847a8460404e119242c2e1e1e08f98e064340e9a8f65b30f6040e9641acb0b30aaa21abd52b210e4e48361665d90a4e30c2b913915e51d0d7fc7808e1a4179f159284c48476c40326acb276342fd12fa3d8ee2fe0d424d18be40ea6ee5d926d23168a3f15ea6a9aad42acf096869643e98adaaf8356bd03f6b9fafc73839fe27fb98b4bdd85f489d9d1b857bdb72b06d7903f66c1c875dcd89b8b0261d1fce56e0ea9aee38d5928cd34b52f1706f21da6e0da21fa7c90e0eb391b5948a89af58f39a404121c89afbabafed6b9f77f20d47f7222c54c88e62756a8cbf22322c1460cf666047a916e6c5ab61562413037c55646b3395c9a42eca327b6d45c2575224965a4a0f4cb4949a54180a6e0215c6ffc9f855fcd4e5f92f5fdab3d5c8353b57ea9695139e3a7be33a7dfcc1de9dba60ebfc3e8ccb1ed46919ffd71c40de4672d459c4d5882b1b1e2ba206851b60c7400b6cadb54569881eaa8374901f60804b33dd706f5d301e6c0941919b1e6a69fddf6c6c8885c646986564845a893e522df954bc0b5f9a1d2094faeb71a8702d2dd40805b2fe3a82f64356a657c2053cbb4f9f19aec4627debccd32279340f986726265b2d4dc94a6b7332d85cfc30415fe74e9080ff3a46a84d0ae9dfb7988870c6c6bcedac9d052937d20b50565393e3a2ca5f18fb3f638c2f3df4c9a2b1fe32425ee1ead671d233556c32af40b2d194cffa4f7efd7f723ed1bf82ff4b6e8fae8b847aa8ccec23cbe99a4b6bfe6afa713ee562e948845a1c993e9f070b233102dd82911b9f8ee903ea10e6e98bf4f8624c1bbd06fdcb4662f9ec66ac9e3a0d65693d911c1a8f70677f541a87c9dcf42c10e11b055f471f18690b616e2842dfac12740d4e40765205cd19faa1b66c0aadfd8f49c70d9d4a2c0dcd88ae1697f058ea84a7a14eb4d92c22161adcd3d1d4947ba03bc7c29fcf2f0f4b756588e8be755c281e6fcfc2bed99138bba70af2da003facb3c19874039c6849c1a515a9b8427381efb7e4e0c2ca6e544b9573dbc43463d2d3478788d455e7e82a2970139c389d5ceb5fdb5a239642fb96deacb6f5dd54303154095e7c0636e4b3b120410ddf55aacb1aa3548897aee2168ea2a20bfdf709665ca5343d7525eeffd277a96acb605c153015c9517b17d9735afb3f74f2a03566207e70f2c41dfaf92d5b57325b62f2bd8fa67a8640adc37faaccf82d37712733f8ef6ce1e77954c35363115f3381b431d11483a3c4d837c2116bfad9614a4f09ce37b9e0f078470c",
            "4b32c6b41c5394461a22448b8b38431ea2cd7854b6375f5a15256c1b10ad2fafd947cf293d6263c06977d2d24493a13e46eb0aa9b30ed6e465b8cffbc176e6b35d75f88e0c1515f967cbcbae57e86bb1569973d8d3386cb510c6c78d6ef2041b260c26a31b83a5b649578b8578a1806cb334c10cb161015343e3afee9b53fa94ba60b2bdbe56fbc323b16d1f9e2c69bb3e4242161618cfd6d560fd6fe64667fbbf831d63990a0a24d62f423aa0670dfa6497c0dbde83c67eee752da61231371453c134f647f84521c2271253070ec184befd11179a80a92327e0e2a96358357b1e7262bba128290b595dba53b12ec1b234a11b7132b723f62656a0b19ca28d1242dcbc909f988348ff34a4c7f542cf942aaaae6232d523be901870046fb81aeaebb91acc1134fe97f0d4d553f96cf5203565869e8646e7cdfa9fec17216967e5fb00fb275bc95e9fa8c2fab1bef8798b0beeae0ac1a509220c4bd0c5b145a9b8bf230f975667625dbdbf7474b2497b81af2e71d3675dd65152ec62a1a9fafbb1d1d93eb66486fcda4630a557eb3430ce5711bd1c15ff1ff6ce02bcc973ede369d3c63d6d23754d9bbabb51f796b614a75829eeeeee32dcdd75b8cb906db8dbe40cc6868cc184419be4fdf7f9de00dd3ac6ced9d9d9f66df0feaeebbe9234da47eeff7d3ff6624785089b9af30ccfe6894991afd5d05f7163bf57877f1c9fb3b26291314ece061291643486c61a4ef80499ba29d468285660a0c2deb0c9c1936c74f434f90bb98e2f2eafc2c4c9bfa30fd5c6bb23a4d67c92e0696b98d4c00393ca3cf0afc5a178ba3302ebbbbb6144b69d694cbec63822c7c13838476b0c749698da25a931b2c09e98f7f055c6aa488eaf0d15682f3bec281135530a04d73da4e29ac5ce0ea605f65aacf7703155a544911f12c2c9b9f04032d5d3f9665b47d58c18a53c8ec5e3fda7df19cfe2599d0c924b494fad6a88db8bf57eb5d703f95b962b21c4dc8ecfb7ccb023355f76aababf269f2c6d6633d741fa3cc7309f09c468ffff5f9b379b790dcc2dad4259d3b9510743716a1151cb147d451c2bf3359bf6caf83c12e51f692c4c29797efd9f0e8ddbe0ccbbdb7062f37a1cdfb205e3fb0ca7b5bf0ced4acaa92e8ddb19fbb4ec5693119840c2e44ea7e562613cdda906ca04026223169aca32ea232fb90c598965284a2f375634ec43d2a2b2888d483c4f26e079da8839ff69bc82e197fc781690daca8a84ab7886ea8fc762eddcee58d4c80a4707a8303c53884165deb8b3a71cfba7661a67b7f235f5485593140fe933479ed568ad355b549a685bab394c59bf32463cd49c87eb59675d256c72b42fdfb0af3d173b3bf2a88b83c4d57bdaf1c9b06cdec75abe25b773e68f73fbec3fa02c6bf53f59c865916031dff8516024196cef483cad2d49225f642a17db9846cab4e829511947cbed6bb22592da7dff4cfcf6bfc5008b241c3e290cd11a6734d663c7f0006cede7629a53666b5c59e14086e43992e21015097290132f1b0989739323cc5176d74d2139622f160e51f0042102d68f49cb68a1904fc6b9381876b83a61959303aefae9a87f05f9184eeadca9639eae64bdab2359ece64486386acfc629e5b9ac17094fed1ef7bad79a3263aee12df612f15037d9df5aff7f3ca79cb6aac97d7c8de4936664552bed6a0fc58fdacff89abfc7184003737e931c1a4dc2bc83a6727faa15f3f5c5eeab6532e42715990a928a513fad04fbd6acc1ccc123d1b9712506751c84115d871847741e483a356e471243a29f392b6cd66b44e2da354c6651bfac91c948614a43537ebd46c84d6e68689adf81c405253c90f1784552fecff24e2bd6cfc7309936f21bfb59b0bbc353058b55b363ed48eae9b3ab1859998836310af4afef853d63138d4bbb061b07e43892023f39f194727768ac2d833ca5d64cceffdbfa48246da6707b2b72ac9fa8fad9122959d49847426dadf6892c2c5d555cee9fb156e2c76b3d6bf8964427e2bc2be1b2c6a9f916a79d046c1222e491ce525be33899bd69b4cc9ee48a25996c2e5397ff630c602e737e9483c3595b3e9f7449f7342c6eed63dcdc414dde69a2257901ca9b2e72517f8995a08d9c2b28d78ac53902b6c09fc5b2568a5fec4dafdb6eccf3f3aef4ed936c95923aa9f7301df074c3ed605f5cf4d7613f7d7f95b3a37182caae6aae565df5aeab13d9e3e1423a6a55136522e1ebaee954b75ec54aa5f26f9d97bc8c4b4ad82c3639b62c9a5c9e15b8d3dff6f92122e6b57d4cdefff7f26fbb6442de6da558c47dd9ee6a85a18c7e40fcdcbc8d8db25aa034ad21da973447b3ac12b42b2ec7ac91d38d9b966c20a569793fd82b94c3e8c6ea2b64b19ce998a13656355349573a49094f3334cb6d67689adb8e44e8234e89b9d61e9217d78fb1623173407f441d6ea4cb9eb42e49331272109fedafa40e4d88336c1e10450dcc7526c5010ae26fc33fa8b6b6cc7416b0ebbe9789b17e9b0e37e0b12cbf71155b91742febef1d05ec01124bcb3f738caaf6c3dd9cb8dc4225e7677fafafe0b3aeb8f0d9a4a1586e982273acc91489e399fcff0feb4b4152967595b74a4ec637f420ade26cae3948c5edf9967ca1ea3f8f2158bef259c3857c2e59a0737df634d49ffa38d007c7bdddb1d7c315cb9c1cc834072d99e1a825739d1d88791fe0251f0f32d3d5719e974cca7a8d5ffca7f455abc41701c0c0245f3b727651d8f14c4fb198d1febf65cc6b3627398f1725e65bb15ed37eb708adad484674a6b1a2b83dba366e8bd6058da99ecd3b9afa557423e17aff2374f6e36ffdfa58da3c071464ce9d427521c6f6a53d499877e8268195456dfccaac33fbe37c56aa96cd223e36c2ea7b17861a",
            "4fce4a25c34bdce97cdfacfbbcfd74be9fafe5b05fad1f86ff528bedb8ac66962c4b4f7bf12f9efb2bfaeacf7240da66cb792c922b121be284020f16f72ffd3d6f7a7fea6b2f153df6b09175155a09f975b58df5f3799e5f3b17eb791f1bfa220f7adf472123db7dbda8bb417ae37b3a776abbbb4bcd6c47872f23e5d29d7aa9e440a85c7c224621bd9e6a237bd25dab227976361d6c45afbdc6d63f612d347bfd8bb57feb72836d1f348ab553fdc57d85e1f7fb98ba7ecdfcd87c61e4270e362aaa73e3ce548fa695a69ecddaa36d7153e264a79ec87e5ed7ebebe6f116af7c96791fd3b7a1ba601217145f777e81c953fe587d32cfa91db1635b92f6595ea4385879df5d60b548c3b188b1fd69afb00553eeff730cf057b7dfd7d559ddc73d951cd6652d9fcdf987e5887f773f685ebfee28ff695ddeef192bab7dbdf91a8d4b3422a1a135aded6bdc9dabf7ba3861b256b3d85322aafb7ab3e09bcff4ef662f152e73968acc6b4f2cfec17d6581874c9224650b197ffff76fef96ff26161e6a9e07c8894da99ad66b744d797e43934a266fc9b5fcb7efb5a8d3a6efab65f251523e97c57a3bcf91fdabfa5bb89784bfd696c56a4cf7383bd5bfd71086df57ce7f97f92a8b9f8f4b7099daf9f3c6032cfec77aaa259865cddae8261193723b1b3246a39ee723159bc708ac2b58bfb81ecd3f7d8ccefcfb150e12091393fef3e30273107cde5e2e276d0b1b57d92b6df35f8a89d56fa85bf36b825e1c45c6ece3ff7ff05dcc981b03c3eff37d167fe067d55e03d74c064bc0bd1a2c934c7b99ffb35ff1b7ccbc28c3df2db7f416713897255c4ebef8c53cb2d5efe8030c7fbecf62ffc6b88c8181e1aff7a5e67cdf8c59f89d347239e31b19fe09ba6246a852a958bf23a76472500606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606060606863f038b576e19decc3ab6a2cdb2cedf1c793fddb764ea9fe11feab77e2faff60786dfcfebca51489b9236f96b5ecbf81a0686bf06f62b8f1d681b6dc1b2f8dad956be5f2de2e5fd813e9581e1ff1347398f9724150adbca05a2d172a1709ac8da7a3ecf823d836361d18b7e3e9f36f7d7f40fa6ddff31da9f48db58b985c54177b9dd0d3f8deb97a1ce1e9f073b7b9df0b37798a0b0608533bee6ad6d236ca618fedfb45fac532a2be9db03624beb6f829dc424d6cd8a1cddd8831cd9d68fe4c428e7092d38564cbffc53b14a4c4c643139e79f3616602ed7fe32810832be9038daaa484e5216e9d2aa2be9dbbe1fe9d2b20b292f6d41725372aac2fc833fd4dadaf6a65feff46fe26486dfee5f22683bae605b9304df30d22cb38c5416f72015f5fb906e8d0691f15d67935983d691c5535792d625654bedb95c39e36bdeda7ecaf0d7f6cd3c0e8b7353ca669356195ab26bbc9ebc3739c2746a869e2277c61aa7746960ec162e21edea3b6f9173adad59a1ccf8dc9f901bd55773d8e71d78ac70073ea3357fb26fd129c5e2393281d0a09229a8206fffeac6054d8c13074f31cc9fb0c43475d8ac9ab9e317913913e792013dfb7d131e143c8df5624cacb6be98b6ffdff9977ab43dd56bd564d5e821c62def2c7d36aed78caacafa6d91179b41b2a2d2a9d6f91555d3062eacfae2f233d3d685bb48ebdca61f78ca6452a6bcdf1aff17a192f08b1c14522606f86bcbbddc9a6549dce41cb2777ab881dceb6a24f72751df9deb882747d2f1f0f63e744bad878319adaa873b2b48eb6c9799226b36a34f7fac1e99e741bff0d6da93fca28a7bae12ae5ecde13065fce7b67b331912aee0a198c3232aa9dca473764745d3b6983761113561d03ba6b913161977aede43ae9db942e6cf9cf355a0af5ffb5ff91c865f2f676fda1eb92b6d499bcc46869df39619978e9b4a127dfc895622f85ec2613f10b12d28a1258ba8c57ce4252698ba35e958d5b94147521c93bad25ec067cafaed881157d0ed816804dc08078584f17d7f7edfb42084e567cd6255bb2885b8b826c3f8fdb91e38b571108ead1e80cf3fec0b62bc8c2b97b660484818c88263f8c02fd7d8dc534ad2836c325ea93b86ffadeda7d201404d887f54d5e0e97b48667afd9bf63c4b8d8d40c0f8be3faffdd7ce6585da08a48f6dc4327839b9516e1a4734cc2fc58ed53bb178ea326c58b481ba79e6aaa1fad10fe4db6fbe25fd7bf7dd24e609944cfbff8f71adb98c69f7c23aae1208496e64baa14b834a53a782fa446f67734e64c92aa39f74e5b2b86a014b1020b4168e165bb0abe9160f9d5a656a9cd9d0d02aa7398975774f923265fda6e73fe67672de4521abc98c8b3e6c27e0d1da4418bff7e7ebce123e875d33b5b36ff5b611b128f29521c3c5020dbd2d3038c596fae4401fec5e928931ba441c4b6c8c691a37537b9694b489579d765108ac98719a3fac1e66a8396c9294d6c23069ce76c390b10b48b06fd80917215bc0d2845a30e5fca761fdf2b681d0d29ad8dba84cf1a1b1f077d7a35161293e3a77039f5dfb040f6fddc5b3274fa9aaef9f191fddfa8aac5eb0e2aaa78b9b2f1303fc2ab5b15563da8993b8c01863aba236a6e629e924cade76bdd48a2df895f765c939822a25c78a0a72f3a86e9951401ac5462d7716099f97732953ae7f570daf8df7fedbb99ada75b51174",
            "c60fbda3bde9e48923f076d444f199bef567c75ce6bd7d350e521e89741512573e0b3d12151898a946ba8f146dc225383c3200076626a243a8065d3decd0c34a8ed12c1baa9dbd9224f8489299eaf943eac1ec0b3f73d73890bc4643a8511396e3dca51b86f49c0a121312bd5163f9b37ec2f0e7c560ef49f902121510612c4c2b808bca11c3fa0e029d87c060a80601f0edfdc7b87eea8ae1f3cb9f9103efeebd1fe8e31b5a673c81a1cef8cad0a1cf6f0f3bc8c4358d324bab9ae594d4c4b8399d5270acb92fb59c5ba75d9bcb8ff3f2bd8b656c367156caab1b26259376e929377d55b6bc57fa0cc3ffafdf62b3fefdde58f66fec13b57d6f221d8893fa99694fe9fe469a15174c60ff3c8e64f8e375c741c1670d517038056c167bbf958535e9996a67bc3ada1303326cd12fd306e7e6c4e39355b138bf3a01fbd637c1c6b16198d7c8c5d02e40493a65a9670a18fdff5f75c78245483eedf84864449aa9a87c123560f83c3ca135a7dff05986ece29e2436387ca21dd317fefc7a60b1c609adad49845f98212d26155e4e1eb0b75363ed92d558347d15a68d998b05ef2cc3faa59bb16fdb41e39d9bf7c9a757eedc8d080a736362809f6b7f6d7e41db77810e1ad22431ded0203e8178a8d559ffc61fd5ea7fb194cd225a89a4ba302e89d48f4dfadacbc64ecbe8ffff4b3db2eb68fdaf69ba2057a3d1d2f9ba875953e85bf6fad2d257f5fddf8d1bc8737272ee8a2d58352b972c3698f57feaf85127e980cf92becbd4f75fc336a9b515298b94199b27c910ebcdc3dac1def874731126367642c758252ac2a4684fdf4e6de564babe3480cc6de5784ec9e158bdd8aec6f03ff8c9ad2a1e8f1434e86dcc6d3812a327adc2b92f809def7f86666d471a1a558c2381aeee5d6d2c9918e0bf8c717fabefa8f55163c45c3e7cdd7daa9c54f6b09329e068ab8693ca015989b918d4751cbab719841e6d87a04beb7e28cc2a364e1b379bec7df7d0c910ff60b3765930feea67eddabcdf0f314e1a344f8841657e09e5a2b43dccb7661d50883823e9e7cc6b8834afbcc7bce7af1bddc889bb8dc2901f9b4652c3921fba2b6c348cfeff6575f79f7c8c385fa7ac27e57287d195b1cf9a65f1b182c7fbd6452931f86ae4df79da4a2ecbb8bcc9744ee969f3620df3afc5c5b5df3396d67e12171c687cfac30f142146b265cbc6af6d785c959f9d1d53e77f7e5dfba8391cca8ec7adf1e3c9a942be33fa2bf5f0972b50106a8b89b91acc2973c2cc464e1896a342cf5805b5a0c2856ceeed764b23e48a9862fcdd656fcefdf5f46db5afbb3f1ab59d4265160fc2ac25bbf0fec755d875ea21662cdb4f95b59f66ca296c5de32e64152a39fcff1453bfcd7affe398e4d09783cf2f35d92af1dfe7e63faec1508ac4442992105ba91c7a574fb8db3b214c1f8408bf10c484c661caf07918de631206771b8f16c515e0b2d8067f4f5f522f2e6981842f64eae6e75aee636edb91f6b6359569f5a82649e9f073d59121eddb90611d9a93c699712425c2efb1462a2c7999f8bbd0f66988906770625b50d10161c68ef94d495a68ec358d4060cde8ff5f92ebd7c53c7e13435b13dafa58b22ca7f1acad374a78dc7f49e87cc55d25278de3746441c77ae4e8c842727a7441cda9a199e4c38129e460ef2432205bffbdb34cd44e62c57d5d0c50fb5d417aadb64ac6b1a6b66ddb4e99e7da8ccfee51474e9ca8f174b00f9330e36abf564f56b596f8fbcf28ad1dcf09e35b59999cf942aa93d2933ae21c8f7dce092893bac0d1528cf6f5549854ea606a12263515fb894dbdead91a57b476aa59d3dbe398c2dafa6ded8fffebff5ddbfe1728d86c925dd4c1d06ee04ae4351e814d7b3ec4475f57e3f0d56f70e0e2234c5f7dc2d4b8f33be8932e7b12ebc8097db9648dd1999feac1ea57fe6ef95fd6a5b752244a55088597cd3180b34a6bf2727485b78b070a53f2e16c678f26c58db16bed414c1bb5c0b460ca6ad2b7c3c04fe92f29a02b6311fd1ef3b9828c46bd1c7b212fe6f73f721771c9e0e4305342800f968d19685a327c9271c1e0b1867d4b67548d685f42225c5d774ab85c5b0fb5fa84da9a4d8e46e84c97927488737635c68725910877afa9b29ff719863f96bae56a9ecbea4fdb293b91e871a4979694c478914ea97ad23f5d4f86a4e8c8b07a3ad237cec3b4ae6dbce1febc16c67343724dab1a86512393bca896fecea6f661eea6a9f5830c9f4dcca9d9d72391e855f202d9cff732d7c6ea6c5aef8fd38d84f4eadddb68d67ed3d35bf8e6e127a62327cf938800ff1c0e53efffcec7fd11f9929995028e15c991688dfde45e9862e78f6e0a4f942b5c912975848754606a122221c16a1ed10a39c449c431cc6d6e4fc63675186bf1f6b93ab35f3393fd4923b9f05e53d5ff921ff9d24a5ee5ebe94f751ab5996ad577295a749a8ab99b4e63e0ec03d8f2e12d3c30100c1f39117ed10d4de39aba939ddd559f3af02d6d44a2ff4adfde06bf655e43699e5b9e24e27277797b789ccd4e4fbf589495bb3f39326ea29bbd638cf8b76b739498cf37da88a5948783335c340e689c5382e4c824b8d86931bcef70ec5af71eb56aee26d3895da78c1d5b764a79f93e2e2325bfa89bee0a2b2b1221b336f62dcba60e4ded898de3fae0f30f3663f9a4e1a650b55d8d8b4c7681766e47e90a24bdb50ae391280f3c4a0fc4643715d550a3a8f1110a62588c0efc6971dacbfb3ada16d20f9e44e81cc8c81609e4e8e8227261440ef57e8f64e39e56318635a52186c50581c6d939fea6d5a5c1d4ec0c3d3534da9dea17ea4c0d897443bf480faa81a70355e4e1002f8104a30afcaac9b286352da2dcfabc7455b51a567b3bc2ac",
            "fd89b131c61f0ccf60fae15390a737a88f3fb9623c7cf22a498a8e2a79cbf5dfe235ffbb336d39b4f5a0cb741297c59ee720e52cd588b8cd943cebdfeadfeac6137dccdaefc5179bb2446a745678a0a5dc155e3c315c79428488948600919c78dbf236caacacd36d05dc9d162c4b348c511a73c3e4fe6fa35f232f96b68c7cd8429ef055739be77a4e86fe579f515bf6bbccbeb1b4cd4863fbe11b5056390d15fd163ed7febed377a3ffec8338f1d15788098fa102442c8c6fe668a8dae8472635546e55585ad47ecedb986bbe38bb82f53c12334f100ea6ede3e888083262d870b275ed66f2e9e51be4cee79f9379536792ca666d48847f70b54c28ea251788ffddba80ba739f4715423171777031ba6a9dd0a64133e4a6e422c93f02f59cddb176e926ec5cb5df7468db5172e6c8f92fc2fcc2942c66feffd5365e3b0f73512a10908ae47853f3c81894c7c550a35b94a2302c001e4a2512fd426b0ae2334859560353a6bd06a31c9598ab73c43745c1a6cba93e353d35ca133e5c8e5cfadfade960f86d3988b9cd9af3fdef835dd46441af7c72667c99e1e2a04cd38a06c1a6fee16e543b7f67aa94d6f504ad1d2255b628f5b2a786c47a98c6267b9a46257850631275e816ee8e2ea11e54439d13f25c1d90e062872ba3328c3746649250adb2be88ffe3bc656dffcab6e170e0686b6bba7cfd0a458c7760787c01c6efae51ef9fbd683c74ea3a890b0fcf65bfbdfa5f37b733af7d319f437edcd94efc6d519c3de957ea40e674f6243b477993312d9ceed80938c13602ebdf9213d69ec961668a88cb263e02a9b1b5cc15b3544138ef968a89ea20aa50ea48b9f32526079e90a878bc0fe41c8ead87e8f954bf9b94cb228e52fe581be16be775de78bf76f8c57ac7b15f972ba6df6f2eaffbb7df426dd977a08d346ed6c9b4fcc83df49eba0715fd17a372c80af498b4053d266fc598e51f60cdcee3f07674a58e0c16e0784f5b7cb43ccc50b525805426497bbca5b171ddffd75c865f4487869345331790afef3e34d1becc58f5f50fc6e1fd071b7dddbd289544f1add09adb876769e561cb95c8a452e96fd12d733f9a23138889ced9c3e0e5e48ee6f51b51f9c9b9a817978a8e6a77742c6984d3ef5dc0ae757b8d1f9fff84cc9bb2608a80cb7b9b7395dabddfafee5335af6f7994e1a141eff478aa3c210e95a9495471683815e6a081b7bd33951f9d626a9eddc8d0ab7977535c5832b4b42e6c0974c37c3f2714aaa53563dc35c48fcbf17c8d5f64f8dfb4c5ce4da5da6d4d87005d8b22c9e5796d0c8b5bc451bdc25cd0cad7916a486b7e136f67aa99de85ca71d552715a5b5404386346aa8f694a8aa7694c829b697cb2277a477aa0d0d3112dfc5da8427747f82be45855198daa85f531283bbcc649a18ab4175b99db44edfe0e1f4fb5e26b19c71a5bb7bd4bf7d9fba8fefa344cdf5ec5179f5fa2f6bf7f19bb0f9f82afbb5b88f5dbede3ccbe68006d0fe22382c88231f9e4e3ada9e4d18e78e393c325d5f7d6c71bb7f472b9e326e739fcc6be51f7f9326b6b4be249e7fd3de55ed424bb001c774ac0064d24ba2a3cd142ee6af413c889334fb4d886c7a9ddcb6bfe5d42958a55aea0dffc96c6e2b55adfef410bf9ad87ade5e6dcdf3c27503b2fc0fa0db9653a6dd5f1d1f54c7b2e3fa30ede20d879ee313a0c5b8e8e6336a0e3a875683d6029a66d3a8fb1339721da5e8cab9365b8bf468c03fddc29d3a924d3fd2d0155716e3cba7f58bf4d3eb1b6fccced7dbbad5c412a9b5790b5f3d71bdedbfa9ee9cb2b5fc26830a2634525652b9253dece1e555aa55d865c22f96fbfc3dcae672ac45212e0a137f8bae9d0b2b42995101c83b0e068bce3178b76f69e58bb660b4e1f3c43edde70903a7df8c2b3bcb43cef97f994e55be8ab5ea527edec0f39c92577cdfb8a7a063b528da32251181e8e4e99f5a8ec9020e89472ca47634f127dfc48823e9024f9049060776f438a8dc234dbdd1eadd40a90e230d3a5041dd54229ed666769c9e8ff1fa7fdf60e0afe6529874396f62baafe62597baa7f9c172afc1da856fece2870d750adfc5ca8e67a67aa4ce748a53aa951cf518d86f47db3750c76a5c6257a51c3e3bca8223747a4d86b90a8b6838f5c8a19cdc2405636a216348b20f5fc63be76b5b1518a7ffa7e2737b9fc233e9dfbcc9d3b8fd6fec7303e3a83ebd72fe2d1dd8b3879e61cf5dee91b64f1ca4df7d5228152abd5b2dfb23aafed4fe67518c7ec6dd464e63b23c9b33b930ce442bec974a611f5fde5b1d83f21c3b4b5b3337203650d5fc92b7f8d5aad76a1f3f7c9026bb6797c9f2a16db530d250e682d7341ae588d30be1cf544b6a63299133225da8f69ed173071f7cfebe7e5f87fa347ede484ea280b7cdceef9eaa45f9b03b07ca5ecca69fb213929a366ffe5c7d4b1cf08cedd3161e2c2bd683b68053a8c5c8b96bd17a049b73998bdf522da751b4255847170a05c8e9b736df0e912194ecd0c31927bf9e4f04cfd19079e25475faa7f1b62b15aed8fa5ed332f1777327ed004c3a6855ba965335663f7da7db87df53606f51908471b7b634c503489098e3a2417896bfb466d19fda7b2aaadabf56a852d09d4f91b43f58128cbac8f385aff230323b1441f8d791a6f746fd11637cfdfc4eef5fb8d47769e249b976f596a2791bf2df9caab638de6b5e2d1b4d517b1590b85162c52e4ad2503f2f249796a7daa656c34e2f4de48f0f541764804a2dddc29b5900f055ff0d896c7b9e528125cd7f2b9f7f9f4fb322422922d151b177bd86384abca1029e6937891e0a0d6eaf9a497e5d09fbedf82f5f33deacc75827e5b9d89f47afd19319b4dd68f6a54fdd5ea4e68e7ef883c373b2a",
            "cb45456538aba85c372dd5dcd7992a70b77f9efb27daab90eca046968b3dead9aba9283b5ba43ad8215ca5449c8b1a25a1ae6897a4c3ee9e29f876611956340b33e5f90592cc8894e36ab1401a1aea665eeb678e8f6fc8b85664d6ecb94642be81e1d1699c397f111f9ebd80cf3fbb841d87ce182e7cf205e9d4b1db36dedb1b9b85d17627d8c7999c3b3cc040c829caf8dd36fcf0d934543f3a810fe614519b2a5564c740dd6357054fa4b77da14ba5af6ffbec3ae32ef5157cce774e7c014916dba191c4916a2f75c3725538766963d055ee8568912da5e2f2ab1d78021228904d57be58b769f51b63fe37b2cf905fdeb7bb57a95afbb0950864b16b9fef7b3daf00ab3afa5fbb6ec39c0bd6fe2d84b62db674b9e617b5acd97af60ef5feada7b8fdc488953bcea2e5c095e8307c159a759b8d567d16a169cf8558bef712ea1735c4e44c6b1ced24c7aed632dcdba8c08589b6b87facc040be2e26c35ab80c7c19a0bdc967a3d6b6b712da9e86fa069165ef2c372e9bb612a3fb8e41cf763dd1b7733ff46cdf13ed9b7440b077a031332183642766ed55c994ac3a63d2ecd2d2d2ffe41fcdf6fc3c46578d2309d107996283a3d038b70142a393d02f281ea77ce371581785ee819135fbf61ec5c12d47a8cdcb76e1eb3b0f9fb46951eefa16c4cb75b53f93cb629df251081ee5ea9c496e803fc9098a24c93ec1c63cbf00437660b4a93ca5013577d02c5c3d7616633bf7466e4414429c5d4d4a81b0462b919bc7c2cc419a7932d159cd624db7b1b038696b6949d2c422931f87436df4733396dac9c2eae439ffa9ad9bc72b997ce5d7fbd11cba02c9d88ed9d5e4e80834d569a82085181e223e15a09452498e2a64baa8a9220f47538eb396ca74d15209b4d6c7a96ce12b91225c6b8376893acc6e1d837d8332716c7816f6f64ec5da367178a7280423eaf9a05580aba17e7c0e89f30d996023b45e6327e21f9273ac3ff77476229bdfdd6e341abec7b3af4ee3f4b90bd875f83c9dff5fc289d3e771f6da15d3fb172f21c0d32b412d93b9d18d62061d071cd44a440a87ff6e1cef9faafde67598f782dc15e493ed8506f27163503fbc0b421e00e4073cbdb3813a39c61e1f4ef437ed1eaeab09d2088658b1acac5e93e7bf0aa7b4547fd186cb21594255550f5aeb8728bcb1cf3e0e179d5230c1c60f1de4eec8106b4cbe7c594d8840fe50c6b50ed65a0b9875e62f74df9cf75bbcccf3cdd74d9af66d330121b763b6566df07991ffbf08005e2dff38da56a9f85c5354640669db67bea9cf8ca354afc97b316dcd49ccdd7c8ed6fed5e83c76335af65942ebff0c34ef3e03ddc66fc6b653b79016158a8d4d7838d65589e35da5b8364589af97097165613485c73d4ddf5d2d7e96ac13fbb3dedc7980daff298f653e4b2638b266c1e405c66eadbb23212c1e41ba40440746232d3a0d4df29a61fdfc2d28cc28a0f293f3515ebfe5379e4eeeaeaf7c9e79cd2adfc1c1e175df553b86d65c606d4d427d824ce1bea1c84bcc424e7a01ba4625639b3e1233752138169880b9ce7e98316d368eef3a892dcbb71b3ebf71871c3d726498b505fb7531f33fa19c7fcb3ee2bab1ff68f3397d611a19c9f0f6224d2222a8d2a80463657a89a1734e6baa7b7117aa475977aa4d6e1b746dda157347cd419f865dd121ab042d53324c39a151353a3bfb8efc5f8eeb8b126d598be9db9ac64a99e1669c2ffabbabd6d29988ea153f674f5b106d09b425bd8cb135bfc117becde3fee632a2c2bd9c4ca63353a801297aca89634de91512ca5b2aa27ce5622ad84686303b3995e2a8a2f2dc1d10a7b1850b8f8f741f072ca88cc3e773cbf0606e037c3820138b4a43318acefbfb47baa34fb81b06477b627c920f0a02fca9e2c4424aefe0749a0ea64de971b12423319e7cf0fe09d3bfee7c85fbb75f68ffee43e7f1de071771fdc645dcfce43cf5e0bb2fc8a871136e0959ac77e8cef8bdb7a33d6957debcca5129777ab9b7f64d8ea7cd7ee9b4bd5c40ce2e4f32907f75c7dd9363717e5d4f6cec9b8a39adc2a9b91de2b1ae5f302ece0dc0b565e1e891664b3a24d89c0db4e71fd00838fd6d5fe4eb9c1ff31d16ab0d1d4315d3f7f70b68d9d208f9c6487b2dfa493cb05e1381ad0ed158a109477fb90efd943a2a5da231258bd526579e3055ca65bfede3fe9cf5a52cd75b4d7fb666ccacffb43dd7fa2dcfd6ebbe339c0ce37e549b77bcb8352f766d46b7dfa33a2767525ede8e0c9d750803175d300e9cf301462e3c8e31f30f61ecbc7d68d27d3e2a47ac43d3ce539196d30221c1f1f0f10c44b05f184a5bf444c3043d0e570af07e6f054ef793e2e3e9327cb74e8e9b9365787865a091909964efb282f79cac69bfbcbe94fd06fa2cf3188a796cf9ab70ff508ced37b63a3739c718ea136a8c0f4ba0b212b250965d8656a5ad31b8cb482c9cb00c1dcb3b213b21db94119b49a203a34ed949e5ae2f7561ba8f97371513169123e070cc6301d675c68fad43439f1fe56f3e67f6730f475724472599d263d35096d708e9a1b1e810148524da02e8df91efe98b0dcefe18d4aa3d4e1dbb809dab77993ebf768b18aaab6f448547705f19fbf9a7e48575cb9dcdfae5d9afb5983bc43af3197de9de9ec63e6969c6dcb0142ada3b1c012e3e0871f342cf064da97115dda87195c3b06ee2269cdb790527b69ec390f6a3a882982c2ac93bd810a70b24311eba1322f68ff1d2cfd68899cfc4eee6644b3dcd08a2ded1db93721bd9bd3489708dad85c51a272b8b0bd142fed78d9c1454df0c6732a5a90f99d5231663da047ddd3c41b3c55b22f0790bc6617e4f1d2fa6efd4cc1ed8d0401eacc4f40e5970e271e1cae3527ee6184022",
            "82af5c4205d9c811a9b181af5804bdad0c8b7a65a36a7d2b3c9ed3009b5bc7a17fbc0eed029de93ee14cf58d76c7c8246fbc93ee8f05d9816817e286b4a068e4c66450528e15f17672c285d31f185b366968dab6ff0cce9d3f8bb3748ebfebf0391c3a7e1eb73fbb4c7dfbf0221e3fbe8e73d7cfc3d94e45a9c462d2a55d05f9fcd6a7a663c70ede9459b1856969016f7add0ca48dcceaa9af2677061bf74f6b6158d15c6d9c95cfa5466448312a578189453698565f8dd1395a9c9a13812dc3834cebdba8c9f6eeee64534fb7c7414e228f3a9f6bf69b54a8de99b4c97727914e026af5e211a817e68a042b05f2a41aa48b54a0737dda64c811ab0d6d656e2448201f22e258fd1373983f3ae737aff56bfc656bf9ee6f5ac99a7dd75659370678aef39fb358279f2cd7c53c9ae4f4e23d8415a1e2f3af3bc855a46dab6ee4d2f59bd40f84184fdd23d4ceb3df61f9ae6b98b8703fda98f7faf75b8d669d26212e2117be5efe0875b241834031faa788d0258603371b3b74aea7c187dd25383f5c817383a4b8b7d4acff0a3c58ccc797db9261acda6420640be9d528acc2facd9b07a8f5dd1b5d348ea4638b8ec6f8f078e2e3aa239e8e6ec4c1560d473b2de5a276808fab177ab5eb8b011d06a320b90039c9d9c84acea422fdc3e8d7ba7e1d1618f260d8c891e4ecd9b3a47d93a67d7e4514fc683befeba6230d72ca4c45e945685ad814499149488e4840527c1afd99d928a8978b9090684c70f6c5c8b43c1c39f4212e1d3d8f7b1f7f69be56504dbf3e7d23fe81656c76ae9d582ff617ff1ad62fc7616e48adb924d32fd45059af902a0c4f446a700c62f4e1a8e71f444defda911a5fd9914a0908a712f441284ecac3e6559bb067e9566a52c7c1d4d0f2de546556b9313f3409e16e3eb7e51cae771d3ff872de8c9569f685e33dd5a66f530330cfcfd158a69491157a37b23ed08bacf5f32007437cc899485f5ccb08347dd628dc78af531a75ab535ccda385f9e4f49c8c8b212a3a61747efe590c7534868e7d49e3189df1daf2ae209f2dc58d3d2391e1ef0ab5a515fc945284da291028974163698d8c108f9a4ff68f84714b27ec6f178b3e51ee68e8a3457d9d06055e6a2ac5c586f2b591503a8518115a0506c57ba39ebb131ad07dd0c3ce1e366211f5e1fb1fe2a38b1fa02033935abee52875ecd4656aef7b1771e0f8055cba7a094f1f5d04797a1d77ee5d4749e3e628292ec5cdabc7e9dce6196dd564ec989107046fb0cebcbc358f6d3d8cf110981e1f6b5cb3b86b1ce91ac5214dc3c5748c2da58afca454be5e820c9d04c31a68b1bad20963d394383637171b47d7339e9b1d5c4dbeec48f62d2ffec44eca4f33e73b364edeaba5027ecd94766e55fba6a599b62c1d8daf4e0f44a43b07c95c35e6ab82d14dee45850b6de0c19318b45c3ef113483ed3f0781c16b396a636063053f44d4be993677d9447aae738ab9ef83dff5bed7c7fe4bd0a45e6ddeeeadaf79498d7b64645e654b5ecb2c054de6e2cd66cd88debb71f62fc9c1d68da611a1a54ce40db81ab51bf696f04fa4723d8598b8eb122ac6e22c2d1ae529c1f24c3f9fe324ccae7635a811067facb717dbc0c174748f0dd2e1b1876cbf164a3148fb7a8f1ecee22132187f0f9f5590f62ed055a165ff9a6ccd7d4faab58118f4712c26249a86fb04921921c97f205cb841cee6e298f4fc90422f3357b9fc700662bc92c465e522ef253b2717cd741ac5fbcdc3476e438327dd828b27af8b8ea1ef9c5480c0efd54cce33791f184e6b936f3feb47c0e9b3dcbd14ef3a430239f9cdf7fc6b470c24254366e8fc4884444074723353615f9f5f29093948ddcc42c2424a463884f18c6f845e283d317f0f4cb6f70ff5ff79e5fbb64df9ebdfdad2cff115550fb232b68fb4e672b20692151dfda2bd41bb82c567b73bba7ad116d5d689bc7b3605fb11348884eed428aa2b38c1db39aa2694a291aa595a228310729e1f1d83275243e583411d9d151c88bcf42694a1195119e4c79ab5d29bd8327b2c2a350129388867119e89a5b66ea99574aca62321e3acb6d235f9983c935eb7f1f475be385701d667939a0b1add234ddc3d9b8d0c7cd7830dcc7742c524f1d8ed0e368b0377532408763697ed4d1ec00d3ee10bde9a361b1359db2b47a46f67fa133120f85e28e9d80573322c18d9adf2c0637b7f4077571263ae54780ce70a0b5e620dc4189999dd260ba3a0b97e7b7c784241d1aeab5e819e906f37efff1c93e9896ea875674fe9fee6647c701b6f0948b91e6e18082e01004387ac3cfdd1de7ce9cc1f9931f60c98c7128ad5f8c259bdfa376d1dabffdc0191c38761677ef5c0168ed3f79ee103a0e1987d1b356e28727b7418c3751f5f88ac158fd2569d4b0c978fe9b5b2fb5397637737b9fdfcb8fccebe8f383a788b5c84e24ec4e77d135522b4e8dbb8c8f468132aa6d840c29ae02ac1f198a5d03f458dc5485eb5b3be1f0d20e35fba725505fed4d25bb47fa92c240e143471e8bf8ca5978a76b3ade5d391e7df362b1a88b2bfa1468116a23421b911b952055c15720a3c2844aa2e34b1ec839d6cd6d796fd59eb2ff583f2f75bec3836622422e869f351d0e957cdd44f17c9fd7cb7d91bcc389ceb5d7f22ba2db2ae2620b8d4d2a6721a7c12894341d8821d37722a7c52434ed32079d476f46415917f8d1fa91a39762596301deef21c795b10adc5f2a46d576113e9d29c5f1ee521ce94ac702c3e5f864b204d7274a5175ce0ba6936ea87e5784eaa31a54df188c6ac3193a4e3e45568c6bbac8f6cd1903a86d7fdb95122971b4d52ce0b3ad42a4829f6502597281f807b9504cf9b87851fe1e3e880c084736adcf4911f1583c790e",
            "eac72660ac5b0075a4e330ea68f38e68a3b4a77293ea993f8f04ebfc8d7eee7a53847f1829cb2e213dda742763fb8e357df3d1d7d8bb6207d213d250989e8fb29c5294661523232e0d31415188a6bf232a3a19e383e230c72308473f3c05f2bd014fbefdc17c86297970effe56377ba77f4af94e62d3616eb2a7a2667eeb0c43fba2f6a4a2a8036998de9c24052792487d18490c4c20d911e9a4514a19e952d2dd34aced58539f16435059d2094dd39ba0243e17f5a352914bebfafa49c37078ee2c4ceede190b87f442695216d520b1086d1ab7c292f103b06a48070c6f5e8696e979a81f93401547441b8b2393e81820ed818354e95d47a7cc390c69612b372df372a2de71d3d4c409f964998fbb616b8027b5d2db0ddbf45ed8eded85e38901b831b11e2e8d4ac0e98e91383b380607eb07d4748db50b63dcd76b63ead17c3ad72b0b7232ac290e425b3f07acea590072613a364e6e8df5a34af16c47579083fdb0b55b0e3a073a22cd4d85f240178c49f2c1d8446f8c4bd6a373b83b95e6aea672755a2ad7534505686c10a652c0592241db96ad70f78bdb387fe210668c1d810d4b66a0b0a03e966efd109bf69dc5b1d39770fbf6255cfff434966fdf8e91f3d662dd213a1eb8ff31a86fcea1ead12590a7574de7af5d21813ebe996f70fe5fab213b835d2464425bd7e30ab6051db7feecb23aadad59d6356e323e35205585167e1ccc1bde00e48b6e7878b018f74f3402c1e59adbd74f62fdc40ad3d23e31d4a21ea16460cb1cd38e7573b1735e3f2c2acb40a5d815539bbb627a2b578c6da8019de7c3932d3545886d880f5f7a42c6e1386a5facb160b4ff957e434a59e287f9cab8c73d3413abd6eb1b7d3550631e57acddfb5f378e1babb06093ecfa5d0ccd3acf45718b09a8e8351f0367ee47932ef3d067da411437eb0d5faf10b48d96e0502711ce0e94e3fe3211b04f046aaf10c69d4260af1857c68bb1bfbd14ff7a47864f260a716b89868ed3bd60bcdb02c6632a98be6805c3c5c63056dd81d1f489a9eabb53a69260a718ab173fe59fbc16a05603d40281603f9de32771d9ecbacfb1ebe489d344d63ca277f53286ebc3104be7ea7a576f34c92fc5ecf1d3d1282818b7ecfc615ab51babbc03d19e2b47a7864da9404f6f63983eb4262f35af263d3eddd4bcb0b9a177bb3ed4c48193f0d567f77064d721f46ad795d6fd22c4054721d8db9fb6002ac42708917ea1f0a16d61602c56bb0562fbee7d74ff23e6b17fd3f78fbf27678e9cba12131af9773f0bb8b68fefa50ddb5a7a1b76f46b8dd2bc9e5465713763ebbc8aea8e451d8dbd9bf432f62bef6b185631dc307dc042e3d8eed3d12cb71d1aa4b64083e486689c5c8ae6690dd136af2dd52ca529954697d5a0b6ada811edca511a1f8f723a3e68929a83939be7e3eaa6b9d498d67dd0a3b4037a95b444bfd2c6545e64383c555a43b4bb8ee4f8eadf577238b5f3ffbeb4190be99c72aa9b7dcd64576d953fd7fa811f8f4b96e9ddc889383fea52a350e38df218c3fd85f9869b7d62a9bd3ede38d830149bb3f4c6835dfc4867b56d167360f02ff49ffd7c8e87277bea6d2bab5952126c1a10a343230f0d461684e387dd03f1c58aced8df231373b3fdd127cc8daae7a641898f037ac779a353941786d031c0083a0628f4d25039ae4a6438c8a818570de46c16e5efe9890d6bd7e29b079fe3e6d9835831633cb62c9f8fd57327a0b8a405d6ecbf84d5bbdfc3a2ed7b3065c30e2cdc7e08dbde3b850367aee2ce175761fad67c06e0653a9ebe44dd7ff82f327bf9fa0776029edcdfc9e94dac8f5a3f67f6155f86b888afe8b57c699d7181baeb6e8e4bd81cd23152611c96a6c5a59d3d706b7d060e8c08c7861ec158d2211c07968ec4b3bb1b70ef4011be7ebf1df5ecf1662cee958325cd1ae2e3f9abd0596483b1690e58d4dd1d7b077b60db481d15e028a11cad454fd43cbe978df8177bfd9838e0f5589fa9f8f9bec01771dc50ae8787c735f3fc74e5c025c6461da7a141c5547418b41c7d671c40df99c7d0b4723402bc43a95ef50438db5f82aba3649489cef7efae16e1de5a094c07c5a8de2582e98008dfed52e0c23029eecd97e1d3093c3c3ae0075cb083e9612b981e7506655a81efdf4f80e1d10d98cc17cda425e8c0da59c75dd8f46f318f4dfcf3fb85542e970b342f9674bf7a0e48ed5af562118743b44a9531d0cb17deae9e28cacec5e9dd07d1ab472f4ca075fa81ad1f9608edb09bc5c36c1617e549e97867c404f87b7853f1e1f154fdf442f4aae88e615d07a17b455714e71622d0db0f1ef6aef0b477a1e3091dfc68dd0ff40ba5427d4310e51f8610ff706cf28fc574071fec30eb3f5df8d7cf5ea3f6addf43964e5bf6556a7c3df53f64dcb1922e44521c6063dcd32319335bb746ff96bdd0ab797faa7feb81d490f6c3a85923e761de8825685bd012a12e5e35d35a25637117b3867744e7a24ee85cdc1bc3da4dc3844eb330b1cb04742da9449792d698d37b0235b8555fcc1fd4170b7a0dc2b44e3dd12aaf8c0a76f7474a70047ae467527df23210e0e064f2513bd4443a6a6ed8f2ac6be3267302f459aa4c4496e95c0c135db4a6de5a5bf35ed731762cd6a36c5719e99ee34826560492b503a2c996786fb22fd8d778aa5bb86957373fc39a021d196d6f3fd5d59ad902f01a32e9c6f9adad508091693e54df182f340f7041e7284f6ca3e3a721c1f69899acc398041d0a7c1c91eea1a58627f96150b22f06c4e9d02dc801995a09ccf9beab4e07454c32580e6e68d7b20d75e5fc79ecddbc0e5b97cec49737dea38e6e5b89633bd761d2b05e88cc2a43c7294bd165f202ccd9b407a72f9ea5e384cbb8f2d125",
            "dcbf7b0977ee5c46d53757407d7f15976e9e37bcffc917a455abb62b043f1fbb7813f55fac64b16ed3b16fb4dc8af7aa06d7ae87996dcdb22643b355c6ab73c2b071802f7ad493a275b4946a1b23a6ba27cb302245444d2875c327eb53f0e99e56189b1386a39563e8588ae058722126b1841818ec84e3f34230a05083737342a80d43fc4976a0f4891df779eeffbab963a603bd2c87977b00d98494fe9a2f2d338f59366fdbcf3872e959aaf79403683d6015fa4fdb81a9ef7e813674ee1419148b4119025c1c28c6471365d4335af337b413616973099e1e90c2f49e04c6c3623abf97e06bfab97bf324f872ae18f7972861bc1507d3a75a5afbf3e87cff1008b518f777dbe0ee899978faf00a4cc6ef9f8f3f5764c795bc619d85fd2bf9abb96dae1271f9a4557113e3ba39cbb0730d1dff7ef105164f9f810e2d5be19cbd1feecadc708665816d6a678c292c41ffca4e58326906668e9c8050df4084ea839010160d7f4ffdf33504ae1a27e85dbce8c7743ca10f44886f300af46128f30d47825f3882022350a4a7f34ccf70b4d37860ff7b4771e5c32b58387111b566de5a3267dc82a75949193eff90fcdf9d16dc67523607197a5faa699837daa4a7a124319f2a8e4ba31a256552ed72eaa369541472bd7588767545ebb8408c2f8aa0a6374ac5922eadb179c6bbd83a7523560e9e89c5431660e5a845b8b8f322aeefbc4c756d50894e251998dba53d4697b7466240309aa66723812ef7dcb02074cd4843cb7a89c682c808e2afb6df29b57e3eac63f5f238eded6ed656d8e8ef59b5dac7ad6687bffbed263652f35901e644259cf5625f5357baf3ad74e15add89170948859d0d599ce051bd32d2934c71713e1b27e45b31aeeb473f6e95989838c17c8d45fb846448747aaa4b842b7a25f8a2a1bf1b9a0538a032c91ff54203d03ec01edd22bd10622b456f5aefbbf8aa51e46e87385f777826c44396570c69e3361037ef4a59054663e6b42978f4f031268f1a85391347e3e289dd387a601b86f4ed8ed2faf5111b1e815ee31762cba10f71eda3ab748e7f1de487cbcf73fd275f5fc1958f2fe2ecf54b78facd559cb8729e3a78f1aa71ebb193c4d35e9b20e3bdf1e76a9b1b7d3d15975b576f6bcf22797eae0fadff9b54122e19d1d4c9981d24851dd70aae523e7c947c48e8be2bb5e621c65d813ef14a6c1a5d0f733b25618ccc03e75bf4c3edee63b08fa5c1650b574cb6d3e2dcf2504c6aee8c0c279ea977b22de91ca3bc62c7e78a593fbfbe86f9acf4428d88cfc400bf4d9b14b47d1a13188055073e350e5f76951abfe6267a4f3d80a91b6fa2e7849d4888c9a6faa4c9a88b0344b8314e82ef564ab0b88904ebda88f1f4a004e4a21c8613740c406bffb31db4fe2f13e3de02291e2f15e1e92e15a8af0261fad201a6c70d60c21d504f67e0d3656a1c9b1050f3c13ba1b8baa6c0f4fdcd9535a7f66d38ef2b1349581e1e6f528cfcba32cf66b3d924212cca3465e008f469d701bddb54a057cbd6c8894d40bf4eddb04da8c176910283c2a230b8575fb42a6d88509d0f1c6d6ce1ebe6096f570f689476f0f3f0850f9de707d09a1fece50f3d6dc1fa60f4f08dc006df58acf68e44a14f084202a31047ebff2ccf30cc730e4406fdfa154bd6518b272fc7b2192ba965b356901923e756e5a7e505ff03caf6c735167c0b564d8abb83a17574040afd7ca97a9e1e54a2bb1b95e8e28018073595e9ee885cbd17e2e872290c08a3ef0721cfd70fe5112118d2b81916b56f861d433a51c7674fc6d55d27f0fd6784babaeb536a6ecf715441782a5ad48bc6b25eed31a94d0bcc6edf0aa5d191c80e8ba27a64a551152989a6c6b19124dcc5f3bc5a2862b37e5abfd2ca1c4ff77450575d8d09ac3e11e14b2ec5fa5deaef6c93ad66ff420ecc072f36a3ed92b7c88a0ccd52637d89e7e33ca9c88971513ff69796b493221e058546fda47728a1508c0cb5102dbd5454aabd123e0e0ed8bb772716cf998dc4b05078c945f0d0792034a31edc9b3585cb8891b09f341d7683c642d17100256bd50396a189e855d91a572fdfc49a35dbb174de3cac5f36075d3b7640587024024312919cd5107de9f71cfce006f61ebb80dbb7aec0f0ed15902757f0d5ddcb3879e5220e5eba802bffba8263572ee0c0a50bd5e7ee3e2065658d160adfdcdcffb7fabae7f1f0d0a143af38c90484c3b23269b91c340b92a16d8402514e4278f12554a4d8160a0b3ee29dc558d3418715bda2308c254117161f1d5962e4b045352b59b6e8c65363edb0705c9ee98f76a95a43f74829a98cb51dcfb6b036e7b79c3a73442ece52eeb74a0ed75f2e14327301afaf2beb3af337bb555219d97ee884f1e31f08c6affb1433b6ddc2ccf5e750396c03b2f32bd12cde0d277a0af0f12405be5921c1820612eceb2506f5ae10d57b84309e95c3f8a11486836298f6887177b10c5f2e94c1b45d8c1fb68a60f85c07eab13f8c4fc680fa6138bebdd601d716c7e2e4ec189c9c15850b734370fa1d2fdcd95e4032fc6ce3796fb63f33977f864420b8a251282985504469e536880f0ac5e43e4330b6477f8ceadb1fb3fb0f42a7d615e8d1a133ba953582874a03b5c2163a6777da3c29f3b57df46e3a84d15a1fee178648df50f87a0722511f82ed4109b8a08fc345da06eb82e1e11b82828048acd44761b55b28863bfa223220142be6adc6a2c94bb166c17a6af9ec5564e69805d50569f9c1ff205d4836ebacab90676aa477a242b57694a34c4a29785cd07a0cb558065b5a2b046c2b2479e8d03ea91ed539310e1d1253d0322e138dc352d03a2a9fea169d8e298579f860d132dcfbf028aead5b46ed9f3c835a3b74265aa69751c5c1de",
            "e89f17871671a1741e1982114d5b523db233a80e59e9546154544d84bbfe999bc2ceb3ce6f330ffd1e70b6b622835cedc90a7f77b23dcc935c4ef621eb225cae7570903571e23d774bd6a13ffd4f6667b5dcbc07674caafabb2efe722fc655fd58cfe9b62c16a50e8b34794f9d85802953e13768203c3b7484d44b8723fbf6e0fe57f7d1be752b1cd9bc0a0d4af2c02e2883cdf819705bb3052e0b97c396d67179275afb9b7781554139523353b175e5128c1a3909478e9cc4a2f90b9093998588c87a68d16d2a262d3b8c778f5cc6bef7afe1e08973b8fdd9255cbf496bfd8d8b387ff902f69dbc405db87515e7ccda7ffd02ce7e7eb3fad257f74945872e17e46c4b516262e2dbb20fedd5b94db5b34050bbcec9bc8ef5226d3511ce62d394627b4c28b447819f0c6e5c311525b4a3a244b654a8c816f67c1e96b675c5eee985986aa1c2186b0d2aace47897658f2996b6e894ef898b4b13a9ebb456dc3d5860e859e441b29d58b38516bf28e26e424b2b9217a99ae2267f3e03f3269f2ffbdf68fe8bfce4a77364cdfba50f38d8a849e7c10b8deb4e55e3ecfd6adca926d872fc33b4e8b500454d07213b3e192b1af3f0c97839be5a2cc69c42098e0d91e2e906311d0bd0f9fd7a3eaa689d37be47e7ff47a4a8da29c157cba5a8de298371a70877d7ab51fda517a8ef9ac0f45919aacfb0717b4736aeafc9c1e9b911b8b6220ee7e7471bef6c4824eb06bb1fb7b766f19c139ddfe4baa85d27d6c98a6549744e1e86305a53e442190ad27370ebdc254c1e3c0c0df30b91141c8ad2a47a480e0d838bc61969d1f590169382b4d854244624202a3092d6ff1044d0da1f42c70049f4e32f937341c567e169522e3e09aa87edba68acf78dc6319f181cd54562bb67045a3af920323a1eefae78979a376111362cdd4c6d59ba956c5ab4e587828c02dd3fccef8c329fd92fb260c1452aa29ca462b8ca6da9149f20c47af822c12b10d1ae1e50585bc2552246b4839a2ad73b6258920e0b4a13b1a66936b5b1bc0c073a55e2ecb8b1d4bcc65d31a920178b5ae5512b3b37a596f5e84bf528ae4461782a9517964a15d2b1c2c8e6e5689a140f4fb5860af7f0ae4ef60b25e1ce1eddad7e1a1335631e806c47ffc8e96a0bd6870e96162459c8c370273b32cfd39eb457cbdb6a5eecb534cf1958fda877a5ac8b490aee9d724f318f715b3fea27df81c5ba6da3d512798bce26bb6e83e1be642d38155dd1a26d3b7c76fe03341c3018d206e5e8d9b12d3e7b7f3b9a9795c231be1e645d7ac37ec53ad88d99069b41e3216bd307e2c8442c18d71f93478fc2a299ef603e6d85798548a4fb4eaf495b3176c9512c79f703acdef9210e1e3f8babd72fe1d8a90bd871f43cb6bf770e3b8f9fc3475f5ea16edebd826b5f5ea53e7f76d7f4c1c757496949e90da905cbcdf3c59a3fcbb7ac9e9e9f81a567b1f6ab789c6b4e36ca4bbe7e5e86e4845032f99dbea8ba35085f6c8e45b75c47ca9b27a512852a2a566447850894c895d8436f2dc13be52e787ffb702ce069b0828e0116b13418a1b547bf06ae58d75387651d7458d93b1ce75634c2a3db0b30754cef6a27a57c3cfdbd112ff5ac2d6ddf3b298435efcf8bbd19ac11f0fec3f8c4db8879ab5d0f318bf55564580ae9347cad71e8d24b98faee97b8f08060fba1d3286d3301052d462121bd1c15092a9c1f20c6f54962ccc813e1fd01227cbd4c82db736478b2568c874b85f876a508dfae91e0e956190cfb68dd3f2481691ffd780b0f9faef6a173ff5c183fc90075528a077bf4f8624f6b7cb426063757c6e35feb137063799cf1c19e849a745f7112f7cd1e32fb717f006dffb257dad524452652f16171c84fce8193faffd8fb0af0a8926deb4e77d2699748c73ad271777721461442200604b740080e0106777782bbbbbb0cee030c83fb60830d0c903e5d2bf59f06722f77ee5c79efddf7be9f0cf57dfbebce4977724ec95e6bedaadaa5c6ed9f7e429f0e9d90e21f441ad74b46e3e464385bdbb27a3d1459f119689a53822ea59d51d6acfd472e10e6134ac2596d1fe617819d114958131485366e3e68e7e285e51ec138e9198dc31ed1d8eb1e8e432cfeaff50887b7ad330a321be2c0e68364c9d4a538b2f30839b0691f3db6f3e8d3f4a434d557a83d9a4ab91cc65ac8279622014977f324b93e8188730f408a4f38dac74622c6c90381162a08390644c6352056861cf84938c8b11790de912a6c6dc5f6cba54dc9a511cdc9eccc1cb40f8847abc028b40c09225d9352489f06ad48affc4e689d56845496978d69d982d40f082601f68e4cb65f684dc3a098ab66429190f3f7eb3d6bdbbdd894c3791e2b12ea06a92d98d56e76d525a6f22f73fdd57280e68e46dcf95e86df7600fcae8d77a84c4da979f34e8c79c73ee097f5865b621a1e5c3c898edd2b30edcc59841c3c0d4ef70148cccec685839bf0fad6710ce9da16168386c2a26a31ccfb8d8051a3b6884d4fc5adb37bb17ade342c9c360e2d9bb7444464227a8ddf82e1730f63e2e27d58b4f904b61c384b761fb9888dfbce63c3be732cfe5fc0d10b57f0f2ed0dbcc37dbca64fc9add777e994f9b3a8af9bdb320987234b4b4bfbb3c69c6bfb6f959067401bdabbd3f5bd7ad65cdab8983cdcbf12f307b7458abb35c239726488ac49a4c482448b54244f668b01669ef032906176375fdc3c3b1653f91618cb31478f70732cebe9882d5d3498516483b18dac3122db12b39a58624f65287ebdbe823ebcbd93568d6a44f32355ef63dca53439504177cf4cc09b3d59ba7847b1ef1fc428fe6cfc596f0a3f7bfb1cd6a3ccb63631ffb97e5a1e6dd3633aed3be328d36fe6090c997b068bb65ec2f0f14b90",
            "d4a007724a4722aba00f82fca231a78918877a9a604c9a18bbcba4b83956868bc3e4b83f558aeb6324b8394186574b591eb0408267f365a8de2907b34f0a66971caf96f3f070577dd0ea41d09db221eff62af16847315e1ec8c49db53178b6a31eeeae8dd1d253a9746299cb82cf3b47eb6abca6f63c452fb191d1457b4b1b9a9b9cab6bdea004a37a0c45494e01accd2c306df4585d59e3025d6664748d879d03b155593256a6e6ecab15f416ea1384cab23e185a3100f9e98d10e5178e908028b4f20e435b56ebbab8fbc1df27043e5e41f0b577c20ce700ac720dc5148d3fd63a87a0a1bb3f722c35e8dbbe1ce759df7666ff29dcbb724f77fdcc0d7af9d4951f2343c2045fa9dfe9a4df0fe0a7943083e222d0343c0e29014918da2009cd427c49136f6ff899296027161157859838cac4442d10c08a6748586d095f030e0acd0dd02fca84ccc8b1275b8a0230332d9274f60b4103274fe4383aa2d8cf071d121210e1e281bca85852d5ad9cb44c4824f16e1eda4c6f7f1a62eb3494f3d718c05ff641e5ffd5ffe8cf807c9b2d97541ff277a33bfc5da6fb0afe66dda07eacca951c8e85f81beeff7e0e6095b9544255c56db4e2669d119d9088bbac2edfb76d0bc2bbf7c694e7afe0bc7117b85d2ad1b25d6b6c5f310779058dd1a1300fde9dca60b67815ccba0e0427a5313ab72f05a5bfe2cd2fd731b0720082038211131985068d5ba1b46222e66e3ccbeaffa358b6ed24166c3a86b9acad65c7c9f7e74fe3dc8f8771f2d2f758b66925e9daaf1709f0f57d6ccce1b4651bd824dc335c6d2314fe59b1a6761c0e3736e22145acfa304eec4a2a051a7437744034470c6f8e14b922332c32b6412391353ac93418a3f440773377d87284359b2627e2e19e26c8970b31b9c006cbbbdaa373b239821c24f0b61421d85684682729720214e89765828343ecc9b565a9ccf5a58978b03c90fe30c58379ba2186d0abad98fb6bead3820059d6e7eec3fb93b7c92419cf8896b52ba7e76fdda35b7f043363fb2f64ccd2731831ef002ac7ac4051bb9148cced81dc924a346c3e04f1a92d91e4e3881959228cae27c7b6760a9ce927c7d15e725c1a2ac7951152fcc8da8df132bc5c2cad793a57825f164958fd2f8376af0ccc4e095eaf97e3ed250fe0ba2398130abcda97800f67dbe2c5ae68bcd8938cd7fb9275bad3a9b8ba21fa672f85914a6c21aeab6736197cd11627a5620975536bb4ded60e488c8e478f0edd897e8fbebd8d2df9ae4b575a3f228aca8462ad8944462d14a6fa3c81350e966a9d83951a1626667054dba35e643d344e6f82ccf80cc4064523c92f1401bea188098864394118227d43e0ede98f760e9e58e41888c91a3fb473f6414f970074b17042d5ec45f8f0fc3d5e3d7ac9da6b061f287d70f7c10e475bbbafb18febf3591472b91c3a26ca9c5996ee85fce0480c2dc9c192f6e12872774596a315d44223049a88e0ad101267a180b849599309e0a33086bfcc08cd645cecf4e490bed61c525f6e80721f31999d688769b1aee817ec8ecefeeefa73e491ebe78f58775f9426a7606a9bd6e8955b440aa25375f57cc2f46b0e3afd3d7ee51b7e8e8deacbb200633edd17e84e7705bb4df03036aacb9cf73fa9ff37992b9554d5ac03a3ec3c00e6c5add0b14d29964d9f84d492127026cc03a7eb60a43729c49a19e361e315004ecbae1056f481f594e9b098381ba69563c1cd6a8ace2d0a7070cb321cddb705c989f53073ca68dcbfb80fcba70d4741761af25a56a272e676749bb00abd26afc4c0aab518386f1d862f5a83a92b5763cba1dd58b8642669519453131be2f73ac2dbf55288b7c77b5ba562bc954cf267c59b5aff364160c4a379526bed7cb71832d6399c0c33f32459326b122150c247a0c05e232b5c163861b8c21d23946e68ac708087508af3ebeae3c844d65715aa50515f05279904028e00819662b40e31216d83954ca99f8249771233516a1169196386a3a39c30265385251d5cc8d505c1e4e9ce74f2e1525bed0fb3a269c73893d2cfd3717fc6bd349fb43fa5420e477ddb41c5faad263dab878d9e4b8e5fba8f99cbf6a1ebe0b968583a1411896d1111dd0859f915c82aaa4476615fc4243446a2b319a665c8b0a74c89a33d95f8bebb02a7590ef0c36019ae8c94e1da6819ae8f95b1da5f86e70ba578b7450add21f9c7f8bf76a714da9356d0dd7180ee272b7c38e10dedcd7120171be1ede134f6e774549fc964e8cd3cda26515562f4b75cbfaef9afda33754284a6a61f02942aa6ab890336394760b8851b2cf942f8baf968bd1c5d686166d655a5489227170a7d54626594c45030c6442c796f2655503b95b54e7fbe8fa3b51d71b6b1477a6c1a1aa73546b23ebf5f703442bd02a1dfe71fc85a886700bc58ebe4e883558e4198e8e48ff18efe58ece08fa61e41b872edd6c7bdff0ca343f5876a7dfedf9ac3870e8dfc7c06e0d7a80ffbc90cb9d4c34cccf8d8d8102f2b07d4f3d2604a8c836e748813f157881063264084a9104172634c8de491fa2a1e7b9d4f424c8c480c6b7e5243324ec3052de361a39f0109e670883b9f83540b2354fa99624c04ab47025c3024da175d630290e411802c7f7f8c2d698421451d48aba402d23ab5290d730b5925e2f1f47900bf94f1b57180befe02439c88f0fcadb7bda5cb1fc427bfdccbf4adfcb57eaea92c2d6b2cba7dc798560c82c9f839304acb43496e2e164f188d80f61d60c67282051347a15e5232b809b92ce6cf81ddda4db09eb718963dfbc1343593189b5ba2b44943cc9a301ee3870d42a3ac34685fdfc6feadabb16dd96c6c5d3a03b131491838630799bde124166d3d8913172ee0e5b34b78fff20ae8fb",
            "6ba05ad6e81dd67e86eefdb59afb2fafd1e98b67bf568945366ab5c99f35de5c3b0e9749847cda9cafd2eeca68868d0d4a3148a041b6c48a44f015f0375662ad508d9bc68e18cde27f375317a48a6da0cfc3f4747f632ceda046a88308b6460ab8895535d1763252956fcb2c2eb2a55da34d697d67298db015d34427090d303366a6b7b7c7c13e4e185acf1c4bcafd08b9d113777797326b3b3ad29e9956c59f9be2cfccc74aa51c0e0d0baec7a4e755202db7135a769f8598ccee08896a8af8a8300cef9f8dce05ee884e6c8606c57d9098d810e1ac9eac4c157fd4fcfa5cbedf7797e3441f054eb13f5f1cc26affe12cfe8f91d55c1d25c7c39912fcb65904dd593b30df9bb0f82f47358bffcc4fced0dd67af5d7305736f1a211f0e83b9da1ccca546a8feb189963e6b41570d09de6c5977e3feb57e403f2ffc712dac8495aa395c29334daec1298f380c64f13f45a6226a53158bef56bf9a49a41e12bee4f77f27cc4428bc672a96d6b0d8aff3d4b8c2ddc119811e7e685cbf0039c9b9480c8f87b74f087cbd8210c15a9077f047fd3fc73504ab59fc9fed148879ce4118a17246b7d23678ff468b0fef3e40a7d5d568b55a9d3effc2d8d1a373bee23afe980fc04aa1aac989c9252d521aa257663829b037a7437da5d4946f8c0416fb4badf9e864cbe27b068f34b1e4910c16db73cc0c49b6198f442b0c4995a501685bd6867131c5868b2091211c8c8d8882cb85466cc49a315cd9577bd66235f6c80f0c42aa8f3f2af33230b9751b5256bfa5ae7383aeb4695a1b1aeb1777d3c9d27e855c24692d3736167c8ef1f7cc3595d2edc18ec37d85dfb4ffbf3d6ff6dd77d32ce5126a151e5563d5a93b514faa82d9e8699087c662c2b06158543509c387f6c3903e7d2165fbbfac5557c89bb684757a3adcdd1c898fb982849acb89926b808619a9585e350d53460d475a4202668c1d8a16a5adb078e6586c5a3a1bc949a9e8337e39166c3f8785db4e61d18e33d873e22c9e3eba08e6f545e87ebd08fc7a094f1e9dc3f94757b53baf9fa77e9e6e457fb23d7f7fa437f5e5a885584c071a5ae82e550cc1e14efd319e6b8b26521b441b2b4990c0141b248e7821f6c240b9331a993922916b8ef266a9d8332305f6121ea2cd5d51e81a0c37a51c738ad5645e811dcd7097bf564b8c0fc97846eb6486467b9446fca726c646d4df468c09256aaceea0c1883473fcb0be1d99d7d147b7b0544d3ba6582673ea7e9bd4c696b9bfd79cacf6d793d1bb1a732b346cda4797593400f51a0d4012ab193b14b963e35c7b3c7bdc9ce5b1a331b7dc0641a10d10199982442f5b964f1963675b39f67794e2508502c759ecffbe9b0ce7074a7069a8145746c83fe602f8917dff628b04b89b08e6bc37740758fd7f5009ed3e25740f82a17be40de6664fe874efc0545f0273bf3bb4b7da11fab823b973a0c9f3480b637b8e40a0dfc359d738736d9f2b61ed86bfbb170a3373686559173266e020f42b2c414b959e17ab74094a0b6a23960d971a0b9d659f7269f0387f5d2f50bb9edc5f6464f4ce5ca6048bffc4cfc58be8f3fe64d7cbfd180348884d45a7c028acf68ac40a9750647806a18157308e7b4461875b3816b33c60b64b10caad5cb07af526d00f148421351494fcf6eb5bfae4dea3575969e9aaafb09effb26e8eb59a463109da360d3a626cfb12d22bd59f065bd8deb2e21bbe70978a6a3ca4429603f051ae36443f6b2ee965c145a58a87f1ae3c8cd170b0d28e43de0571a09dc6055d6a80e341068813f310c9f2064f8518f642437474b34023776784d9d81029cf08ae4a291af87a23d1c397f46e92854d13ab30b7df3c665a8f2a32b1cb143ab1622a1dd175225589258e9f13a42e2ab692df6a6a21d76f4ed2e750ffa6f5ff9d38e6a79260c3e13c560a85b070732316f109e07bf921253e1ea78e1cc1f6350b909e9800a1d20ce62a73782b25d0f07928f5b6418b206724b8d8c1522281bf9b138bf5133166f060f4ad28475a7c1cc68e188cbd9b166148dfde888d4dc0e8053bb178cf0f58b8f334769fba803bf72ea35abff7ffcd25bcfee5124edd3c47763db855bdf9fe351a1b17355ef8d7316fc839f09ddef7fe19b15f7f16e02b6fa9922e1468c88bcdfb70be6218aa0cd4c891582249688e2881194ed806e39aa93f69217340899933d21576685314061f9512f9f681a80c4b47897b021a052b75c7067a504f73d104b66aed949cbf599a64ee6c29196ec4e1c15c2820d34bed30afc40e7bc7d523d39aa86b96b6d3bc4bf35638fe417cad2ed5f91f6907ee27bff2318bee46739623e534e9c2d42fac4456fd788c2ad3e0fc5c4b68cff8a3fa623aae6d6c89f7270a3120c3104e2ee148f6526156b6003b5a29b19bc5ff839d6538da5d1f0350e24ca50c9758ed7f79980c1787b05ca09f048f578980374dc13cce67b5bf10cc61d34f79004f5842f7a105abfd1b83fc76b7861598acd6bc0ae69729601e5430f4f9705a5e4fd3b48ec6fd6b9f27937d43d36312e89c9113c98a69f37467761ffc18773f75f8284af21a31e11636d45bac9824134938ffa4afd6728069728188bad939690359bfa7cf1b9c119781dcfa4dd0322c1e1358dd33d1d90fbb3c22d0d5230833dd42b1c63514fbddc3d18ce50345d62ee89d578c771f183cbeff1847f79dc4fead87986d2bb6d5cc1c356b839dc5c7480cf73bce579581593fb7a2afef93ced6767468bbaeda91ddc6e8d68eec5453e8e1f8d4df44a9cf51ba325021a29166426d88c298842b8d502ce7626b82011e0de5a17a2c07e8cb031d6a0366830d3e9c35fea8fff778192057c925f5cc05c45b21428499002ba21dc9b8684f34f5f346b0c6133652",
            "252c047cd4f77443b2872f1a840460606947cc1f3c1febc66e64568edfa1eb9e5bf056233272e6708cf53c7789139f17645677fdd2ffda1c1a6bc562b1ec433d174b5d89ab25f1950888bfa9141a9908ad9bb740f3a222d8b21caf9ebd3969e6a94679980b5a8538a39e93057a47bb23dddd1e6ab100beee1e387d702bd62f9c81ed2baa7072f7721c3bbc1313c78c46694931ea65e6a3eff40d98bee928d65eb88b55272f62ede9f364eb0f17b0e7da25b2eef60d66fdebe79879e6280d8d089dfe39cfaf80d3bc398ff3d7fdd57f265e57ebef0a3832016d6ca4642e46e502e7aee3629372e473244810ab9026b44096d80acfc272c91c736f760c3aa0dcc213417253b8cae428738d448fc0448c8ccb43a957926e68634b9a1360dafd8b61c2fdc26acb7c1e874773fc95daed3d9cb17f4a1ab3ac95a6667e6bcd612713e1e739f03a1b57d617bdd3ee632110e4d94884bc2ffa5e9598c59edc820aa671496ff46b138807a773400f45e3ed7a3fdc99a1c6a1723976b5e3e3f6822094c5c9106c2325cb8b64d85c6a82ed6de4d8d7498eeff567f975917d9c07b83454f6d1cef7d7f300199e6f91b3badf17daeb71d03eb461f5be339853662c07300679db0dda9b6dc1dc59091d25d031efa1d3fd82ea377b184a56d215fd1b2eb2ab9b71ffcff3fd1c6f16b45f7b393aa3555e01131d108c106f5fc48747a2a263274ce83b80541496d434888b7fa8148995767676dc7fc2836ae33b0d853c3e75516b98509f2012c0e24d6e6a1e7292b2911114051fdf3004397b62b97be847bdbfc439182b5c42d096e5021e5e018877f3c3e2794bb1b46a2d06548c42fff291983f65916efec4c5b45db376395f61acacf65e3f9eb9d7b6b039995831026bc64ed54eef544c736cac86ba4b8d2571e6e6bf46988a6bd22d04ba4e1a235261cac5ce4216eff71b027bb9608e0783b9db0cef37c5014355209d59fddf8087196a0334b5e0e9b2d9ef052884c8b615916d09ae9813ef8686febe2458e38544777fb8ab6c20e77191e464876c0f1744ab2d91e1e58e2609e9ba4e31a135bdfdada98b5ce8f0b95f28e57f3e7cf84f8da9a36263633abf6914736540161999ee4f1abbd9a1919b1a41964ac43a98a3738886f46071bf7fac07a6a6fb913959fe24c2c60ced829d4859b0135cac54b878ee141e5c3a8425b326a2b2576f74ecd009d9990d909a5a1f6191f1e83d792d862cdd87bc4e7dd173da422cbcf99859fce8b976d9cb97baf9cf9ed44cb8708a361bdcffbd9da5aa42fcd7b68cb25bba6091fda6b5231db76d30769e3cb976fdd59fa87de85ea9a1115d62e6cae846cc061dbe169b433211c2e1b3fa5f8d4423330c770cc4d5c074f411d9931e161ee86317803c95138679c66152443686456661667a2ba62c2489360e936d35f974ac86e11f7065c3cff1b37afaf4f6d18e52e6e0604f1c9a18a5ddd3cb91b64fb228aca3b1ffdae7d10743fa4804a2c77d4aad694eb03449fe2976ace7039be55c2e6ddb7d0a3375fb4ba4a4364155810cda53e978be44821b53c5f8618c18b7a69ae0c62453fc38d10a9d6325189b2a23db5a9b60476b19f6b497637f990c47bac970ba8f7ece5f8ecb2ce65f1c24c3fd390a541f3307ae5842fbbd0a94c57bfacc196022c13cf10479330ebfdd188cdf4e9683905f59dc7f0fa2fb006df5071da56fe98f9b465e8b501a283872bfba18fffccb5e2f438ee11b8da50d09707127964a733858daa25d613152591fe3a276608aeb67d25e4d9b1f0d7071add5b1ffaacdf3f4f8efac76d44507442236241a85590548894941525412c202a390ed19888d6ee1d8ec1686ed1e1168eee2077fff70f83a7ba34bc7ae98306c26ca5bf543df2ec33165e44cdde4c1536ac67f37f98aaf9b27ff5fdcc3ff9775fd39ceb5cec1ce8eee5db755bb79de567276de485406da92341b73fd58e819672aa54576126d7bb500fb72b9e4601697d03b7ce03a07dafb0dc0548f8676510c74c11c3cf3e5e0651817f3edb8e8ace292b6d686b4bd2dbf26426e849ee1a6789aef8d632dfc901e148118577f247a0420d4ce19124343288d8d91e96a87223f3724b93a312dbdd5359383553446251e61fc29d79f411d8e47fe5fccf19470395ceaa736632e0eccc2b5a1b958d53c1aed029d58cc77469f08d662ddb1a42802eb4b22b1a63094f40a7526b9ced688b453a19e8d1cd3278ec5c37b37d0adbc1c595979080b094768582c32f39aa1a8431f8c5bb60b55bbcea06acf69ccfdfe32c26213109a94441b5674a169a525342c21f6adad85d95a16f703cc8c8cfeaa493ff54307fb0d2beeb91edeb5dbf3c23143ce8103b5d7ff0cda3f8a2330448ad48c7c98ba08ef47ac042d9f8321f68188e5cad048628b02a10d76bbc561bddc03a394ee9862ed8b41e6eee862ee8ca6660ec833b34709cba9abb23b922ea1a9b01071a3ad241203ce3f3e47455ff429344998bdb8e6ecf440eda5a97e744e4bf5f79662be2127aecece2907b2762a31c482ee99ec46cf4fb258e26ef611fbf56b50ee6b2ced69bbde55cce2832fd0aed72c84fb04624133295eaf32c3f7a385887032818b891c85e1125c1825c74f132dd1235e8cc58de4d8d356819dadd9d7f6faf97e394ef596e14085ece39e3fbdfd385206dd0105c82105de6f9440b75b8e3b9b55b8b4d5151f9e1580a58078776b295eec6e81f7675b80b93d417fc65f8df6c35bfd1a33f2eadac177f9aec2e04f4be2eaecba8cdae76a2b1749a895d29409f6f447a84f0846f7ec8fd28645b03251e9ec2dacd13ab7e1c3205777937f113334fcfcbb7221d7907a39796a634262d124331f8d33f23fe6038c0f8e81b74f10c67a8461876b3876fbc6",
            "a0d8231009c99988098a464e7a2e664f5a80be658331a0db700ceb3506437b0e6346f51d4b5b16b42ce67e7d5cb9766ceb73e854376779d5c6d9ebc88eb91b983d3d1ad272478bc5b1661fe7547e4e521ad7b4b036d675d61893096a3eb93e868727b30cf1700007b81788eaa7c38162117ef0e590322b1e5a5bf250dfcc1031ecf7fc64fc979e6243adca908b55950e644f919a0cc97525792151a8ef178a54df70ad5a66c268e432c6c3dc84b19389746dfd1db543c335744280ecb5bf845bf207f376dfca7f0dfbf53a5aee181474c85a29af199a17a2fb6958431cee9a8a6315a96463b3305295ed476664fb6266a63f36b688c1be8e89647c8a3769e6614b5afb69489e931912c34370f2e04e0ce8d50be9c929080e8e42e3d6fd3074ce364cdf7492ac39758b2c3e7c0eb3761ec3fa63a7985bbf3ea063aaa66c63ff7f163b304ad90e97c67a598d85f1df8df34fef3f71e708efb3276954f58be631cf6f7fbcffb80307eabaf6d797f56cb5d01d0b166ae9d97b78df6b015ef79bf771de3f47a0422b912d06ca9c70cbcc1f7bf81a8c103b9002be0909e10ae161c047b0813122d8573f0e47976be5442ba273aec8785c7ebea7e73f1a33b575af5f565b931f61ae7db5259aaeefeef8d2d342e45e0779762d076ec0dadb368dc3e8c3ed311f7e9d6b8a5e2992b5ecb59dce2a0b1a1d99415bf79ac7741ab80499b96d10159b87240f6b1c192c07ddacc0c80211dcd516a81a1188dc501956b797e2ea78330c4a976275b11cfb58dd7fb04cfe49f7f79563733b190e7697e2c668292eb0daffee0c16fff74851bd59cae2bf14ba1d523c3a6c8341c5e6e815aac099c9052cee77c3fb8b15f8754f24aa4fe68079779b10fd39bf6f1ed2aef1b6cdbe42acf9af96daf9fa50b6d1a883855a971c590fadf29ba2bc795bd8aaac75fa3cfea1defe34353ce6899badbdf25f60436d3f5e63a134a5ed0b5b3365cd3a61589f41880f4f4052783c3c592c2af709c7318f282cf38b41328bfd492959d8b06c235213d2307dc26c8ce8351efdcb876140058bff3d47317dcb06d0efba0f3ee46863f7e59a91af663c7c5e4f3f562696d0611dfb6b47b5198ac51515645e922b5a3b5accb0e37136269bc868be852999e36e8ca5de5c0c7610e058b631a6dbf1b04acd43f5160e98c72d8096e664a98643bad9f048673b435d0bf677f956c6effde50257299f3f48696440335c64da0a0f2b12a852c3c7da1a79613124d927849a0a04d4db5c49832c4da89789840ef092d2523bc17156b9f870ea7e5fffdf2c5f8e8721eca0a259ce66ccf2c2208c8973c4d444672cc8f1c79616d16457eb6872a0431cf6b74dc0ee360938d42d9d0c88712785ee6af48a7243473f6bf4286b8f69e3c79288a04022e27050bf7127ccd97b0333371fc1b0157bd161c8383a65cb7eed9a1fef324bce5f63f6debd46aebebcf1283e2a4cc23137ff1becc9cfcf370a9a3d9b974fa9def4e796eb398a7e0ce975fffddc0fbf1c2c7efbf3a71855dd9d03a8edd7d11c3d6ec7c412fddaa63733b7814ed88ef56d7b2191634c3a4b1cd08dafc66efb703cb78d44579e1ef745c495272461866292cd9392249e98c9e28ab4a5ac35e318d1228dd7724be93fcda5508b87ddf4fa7f6e0f37ba6f98e75b575341721dccf953ebfff5731a353ddb04d5d0c7e5ccdba5525c196f4202d542eae313473372dbe9728bfbead21b942129b51952339ac3dd2d820c4c33c6b509e6f879960c85b152148528f166891a0b3b297178b0028f175891a11952ac2b51e0440f7dbc5f4ace55cab0ad9d1ccb9b4ac9fdf1325c19fe69dddfcb5532907d7254ef5542b74f8a0ffb4cf0688971cdbb33a1583230153ddd39f8f9d464e87e688cb7fb53517d3a03daf7e7b57af81f5d1c3e5cfab7bebb2efb2cfdd4e056a1a1518db7ab2793149d88e94347212a208c7838b8507f57afb7f616563f5b29cdd79a4965ff8cabd6cead59b1afaf3c9d5c6ba60c1843ce1f3c89e2868588f28f846f70343a7ab3badf3d1cfdfd6310c0627f4a72168eec3e8a25b35762fcc8495838652946f599804115a330b2cf38d2b7f320dda87e13dec787c6787f855cb9b68ef553e90f82ddfd6a061477d1f5c96f830dcd93c8ac307bd2d846498bec357490978b6eba8d925cf230024d34c05a672e16bb0bc9d26031d9ed2fc087632c87fdb510748492ecf7e5e07c360f0b7c0cb5dd1d8c6873b5609dcfa734fcddc45c0e9de16b517d24c31709fe91c4c3da5117e6e84823358ebbf91cce3a85a1e17619d7609f9911f784926b30e00b0ef8ed1cdfff99cf4b34e5718ed9383b56bbe466eb5c3a7484557937d877ec04bbccfa7073b247bc4a824ec14ee81be78141899e1898e4854e61cea4bdaf3dc973b5c128f65a919f06dd2b2a10e4e747343211f15099c04c24245d864e62969dbf83a987af6add0242dfd85a5ad2e22ee574c89a3574c2c9e374f9d37bb4dfc259fb941291c82a3348a8aec8378cfb639efc711deaea4f58bfab27f3ea56e56f8feb3a37e37d7eee834a1e8f9e3a7490a1f75ee0fde46df86dcb293476f14047431506893498aa70c721ff1434149b135fae8078f344c83294a2174fa1cb321031d906229acd13d124232122f942ad335f30c0e4d3f9c9ff68fc703f37c3c13037259d56e67acb466214f1f9e37511fbf5cf56ddaebe18f449968e3e698a0f0734a8dee38cf27481cec33385a9dfa82b52325a203dbb15eaa5b1d8ef1c819609523c586889e3952638d64f8a70170b9425a9f070ae096e4d57e1e430536ced638e8a7811b6b750e050b90ca7fac8b0a5b50c13d264b8375d8adb63252cfecb70670aabfbf7c8584d2f87ee9219a93e6b85eb",
            "53c4f86956386e6d2ac1ed6d0598d6d211fb271683deea80f747d249f5d5a62cf6dfa4f32bf217a96ab973dd8d81d63e579ca1a1e1f90057775ad9ae8c1cdebe033b376d42667c92cecdce99fab97a9d5308257a6da8d09bfc5fc7fef565b2c458406382a39946f5f3d1b2717304077c9abb1ce8138175de91280c8a869b47404db382663877f4344eee3f83c3bb8f61f9ac55983f613ea68e98858943666070f751da51955368d3bca61d0db95fa53efd4b6e0b7dcedf9c8864a655bdc618d8a409f694f893697e5668646daa1beae3a2ddad919207891c684b584be58034e5e260200f07341c3c68a6067d578cea8769a03b38e4728e21e6071962b6179f99eb27a63996924c5fa948bf66ff7c8c199f5677f2612616679210b7505dbc7728b59448cf9bf00db9ffc6d8fd56feeb3e4f3f1eacf5672658dad952a7916374769367c361ed16b81d3c0aa7cdbb60bb623d6ce62d8169d316301709116d2547898f2d5afadba3156b2dfd1dd039d409b3d27d90e7ef82a090507899ca48869b1a711a4bd89b98504ba98c36ed31b066f8812b175c3d7cf5078ff765f9dc01f6efdd7074b4bfe5ece17642e3ec34c64a65f6e5e63375daf3eba98d7ffbb945c9af8f9b17bf7c1496fdf8f697f7bfbf8a79bd61c4db8ff85fcb09eae2bc8cbeb4658d56b66ecbe8b5ffbbdb3f83fefc1baa7af642638e0043652e982472c44c737724f16524842320512ceeb73754608fa1a5aecc404ae3b822eacb171eb33236ee2216f2433842a12b5fcad7efdbf957718754736363eaa4122f56898d2deb60accde013bffa3859fe43b8a3883e59a262de9fccc69e59f998d34a83cd035cf161bf2766948be1ebe489b884260808484790bb37a60cf1c6f3bdfeb83dcb068fa79b607633116ccc3464408e09367656a04d90088d3d04c872e46374aa0487cb58fcef22c38a421946d593e1f234097e5d2ac5adb12cf64f64b17f971cf4b60af4b537f04b22ee2db0c79dd5b9b8bbb31867e744e0cae228fcb43c1cbba7e681dcac40f599742dfd30932ee95fbad15adf5fbea3dcefea3ef6eb63f92f5c6cec69fba2a6daf6cd4ab17cd9326c5eb48c7468908f104fefdfcce426ee123effbf32c6e2f5f1352f47775d416601c94b6d883056f3a787c6614a40342606c622c23f0c7e7e2118d26f30ae9cbf861f4f5dc6c983a7b079d94eac60f17fd1d42558346d29260f9d563d75d81cdab363ef2a934f7187af519fb2984cf5f5fdbdb5dc84962664ea8a131a627ab3fae44cb6867ce7668a424b259964664c1ea5f109fdb931e8c302302c5765e61be0dd2003fc16c305bd311c0c1d07bc94e3dd3c031c77e6e288afb1ae978d88f673123f4c37970af3d56afd5a9b9ab1d196a05dfd496942149318105f13e9e1bd4d606060c1f9ebd93ddc2f708bc7f936cfff9f882b2fb6e01b52fbb61dde5b8f9e06abf1d3e17afa3cdc2f5e86cda295301d3006ca1ec3609c5b8cd1e3c6a263f312789948501ea2c18c0c7f4c4bf74555a61f999be98b0c371bd82aa4c8f3b42569ae6ac6cf524983dcbc4f68545693442c7e79f90755b1daffcb7bd06feb93fc8ddea4b430eef593ed096f1e3fcbfcf5312d79fd33ed8c57b42f7d4f7be85eaee9fdfe8924eef265bd1e5e37e6b767fead9fdea9abf1ff5a5eab3f2bf465b4a59afcf6f817a2fd500d5a4df1fdc60d68c062ff00b106e3c54ee8656c4de20c44248a2b26492cf677e329b097a7d24d3650d2649ee8173b6341a9d4d8d8e0bff1ffdba984c659d2bf1ca95ae7f876edf3e8cf3142b764056e4eb0c0dc260a4ca967849919128c4f12614e910d3e9c8ac1e1a52e08d598a0639123ee5deb087abe3ece559ae1640f097695f3e16f2d47b07f28a23552e438f1d12958827169726c6f6982ed4d6558992fc1ac4c19a6e64a71a34a02ed06099ece92e2c114395e2d93e2e7031a1c9c1b829ba7fae2ddf51e787bba075e1c29c6add5d1b8b739050fb6a5e3c6aa68dcdcd10c1f1ef4afa6affbd04503f2775aeaf72ad837d7eba8baec136b9fcd4a2412bdb43635879f42458ac41648159a20cccb87e95258440b92537749f87f896b19fc1bba5faf497ed658a96bda3469a3cb4bcb434c682cf223e2d13f3c010dfd22e0e11b8c46b98db16de30edcbdf10407b61faff9f1f4259c3d7c1a7b36eec38ad9abb171c9662c99b1b47ac1a4a57444e5a85d362a0b23cea7794c83af141b22f5632258e34adad44b43417c06763509223fa658a1d24e484e3b1be1b50fabf7db9ae1c5ac08dc186203e6b610ba551c6847f0a07bb888c5fe9bd0ed0ac4af037978d393e503c506f8c58b533dc5d19a16d9d92e0e977df42b939d9446f441274fed8db6fea81f1e4b1ac424535fb53af65b7cff7fb57deb99b0b86c1518c8588f994acc874f80f39e4370bf7295386cdf43cc474e86e584d9e06416a17d5939ab49ee63d9ac29583c7b02429dec90e7628196418ea4c8db1615e1ce6819e880421f3b52e86547d25cac196753794d4a70f47995442c7376764e61997090995c549b6febf763223df8e60f77026e5fa1fecfef53f7cb67a9cba1bdd471fb960f2e3b366b532f9ed20ea97e42d7523a76fceb07facf3b34bff3539d8efbe77338c6ce6969c7cdb83c7abcdb28869eb805bae11c4e4c998f8612057a086c3141ea422af856249ac5fd789e84d4e34949065742da7065ba9506a6b4034f76cfd4d8d8572136aafdbbbfe7d1ff364ed6515d593b1692d8b735fdd395da3d1d4c9889995252e82f45235f29663652605da118633354d8bea821ee1d8b83f64e2e2e2c4dc08ab646985faec0d27e7618d0da1139718e487032c1c8242516e42ab0b9c4041b0a94985c4f82a9859658d7",
            "db16eb3acb7175a21c8f67c9f174bab8e6d94c091ecd90e2f552195e1e51a06faa04bd3d793831a733e8bb05787b3217bfec4dd3911f72f16a7f3a1e6f4bc2ebe34db494aea0d32a1236abf43c3a28e8cf100badc572fdbcff6333a184569a3b93bd6eb1a4aba5333c8d25d59951313545a9696b1522b1c13f8953f13ee3b2febd3e7fd5355b0b2bdab169275d517611624262101f1a8344df50040584233b27bf66f2982958b36407aefc701fa78f5ec3f103e770effa6d5c3a7501bbd6eec68eb5bbc9ce75bbb51b166ea3c32b47ec64b15fc2f9e7730e5fc398582931e4d1fc8868a6382e05cd9313f14b33071ca9678671b61c9c0ce7606dbe0055012254b95b62536a34d6440bf06c8a0128d30eb8b71ed51521d0b19fbbeb29c5765f3eaeb4e3e1552c974cf67045576fbfc779b6ea5c398773b55db409a5e3fc74f30a82999490189a191a73d5462213fe37fcd4b7f2ef8c214ac5161cce652b3b758dcbb2558cd3be83f03879065e3f5e85d39113c462c22c980f1a0b41b7c1704bcec6fd9f2e60f18c51b07674c782a963316fda54f86bec116b2543b19f03ba843ba12cd489b40f60f9008bffa136a6c8f270609ac4a5d230afa07d6aa5f28ffbd9a73138d0f3ca99979ed72eac743e7aa048b57a45bce99225f9366b561e70d8b595ba1dddafb3d9b945d7f6ce15dd39fadbbb210faeb971664cfcf8fdfcba1df79fc13616adaa57a0a593770393b6625d69576409c4682ab0c2668527f9cec88244f224ba149e4c97ca627f3a6ba95c896e285789295c93972a3df67fda4369f43fd0c775796d6dedb315b25584a169723a245546bdcc2534406d02bdb99949d8eb320c4e34c6ea4e0e78736510ee9f6b8fbd534d717c9d07ce1f48c0fd1b9da1bbd5910ccdb724dd4204d854648aa57926989d2d475553050e4c76c48f0bbd707a8835ae8e50e2c7a14a3c9d23c7af8b2578314f8a6773942cfef380c36acceeacc1f0183e0e0f0826d5af5733f4d701a00f7bd2bba7bba3fa720b42ce6568e9edd6b47f69ec6296bff33f8fa13fc33c686d5b755108c535890a0bdd605b2fb2da290cc972952e4a6a4a0334ced4cfc9a59d31f71fae51f9b29ef46b6a6f592acd68766236131f92004f8d07823c839096908eae65dd5135652ed62ddd8a0533d660f4c059b877eb673cbcf3028fee3ec5cf37efe2fc91b338baf71873e6d0f99abd1b0fd3dee5bde7292512fe571a2bd3d7179ff3699f827ecfdf07770b4bb44da98ff4d0248c284e04e96e8769f12244cbe4e8ebef853e1edee8ef1746162726e34c7c108ed81862bdbd10d71bfae0551f3ee86c0eb49d0d7155c32147ac0cc910131956fb0bb1c8554a5aa82d681b1727ea27569035fd3d419747a2756c5875924f188d77f7192b3330e070beadebffdf1a43bdcdf97c6a919ea1356f560acbd85858a6a641dda225d42346c366de52a8a62e8041781296ce9d8363dbd6c333300c064dda41e0178e29234763f79eef513fd41f1d821c4859901369e7a7211dfc1d49acbd0a0d3c6c5016e64692032348717a635da8a75ff0a7f1f01df72f63e3d37afe16cea70e2f723d79d8de72eddadfdf2bdff3f2e593de974ed5b8fd748e49bb7a417b83bea7a5372e75946c5fa78ff9f3f257afaeabd8afcfb54dcbfca2183a693bb9dc7f122a236291c46254298bfd5d952e982bb22749066292c8937ec47e16f74903ae8c34e1ca75f3b866348c2fcae37c4a5767f4addbffcbfaaeb014f2698c9de094b5c878b3b9b1e0a5935284742f7392e6a5829b8904399e22ec63b5fe86b60a4c2b09c4def214ec6a938415194998d6c49d9c1a6e8b0c0d8f4c4a576274b21c53d365d8d45a8e1f4699e1c25015b617097173b4048fa7caf060a614ba6d62bc6135fff339323c9bc9c5f3351e78fbe338f4c9f423c3128c987b73a209650ed1a35b86e94a3343aed94ae4647cff14fc7aab2d2d8db71c23fc634cababe5d31a7d0e47c33136fed54d2caf9965e34bc63bf8a385a91dc95058523fa9c913a554d6f1737e7fee1fe89eda6b1d58db626369c5f87b78d3c6d9f9baa2bc22b46bd10ee3478cc3eeedbb71e5c2151cd971148ba6ad607ddd1c8c1d3c1373a7ada979f7560bed07e6e3b93eb72e5d2757cfffa47d7aef19ddbb79ff6f4d1a34eec8f97adbe4f71a7b89d0c080a6f887300da3529013531fb3b282b029d906792e1224dbb9a32acc9d1c8a7224336363c9dad8685c709640ebc7c17567439c56707054cdc10f5d0ca1edcbc37b0f1e3e447070d69947a6981963bdda106bed04a4d4dc8464fab0fdfe4a1b5c99144112dcc274d9c13134c4c636ee7778f5adfce7f05fdf3727582b95356295b536486a844c1b399a389921c95c04678121ec5d5d20c8c845bbbefd41df3f45cb92427022d260b57e3724e366c3c4d91b974f9fc0e08103e126e090224f5b52ece3406258eccff55093be311ec874b5419a9787363d328936cb6cdc85fb29878fe1177d4d617fe0408c66ef8eda7b3376debedd28e8cc191e67f56afd7bfdb592b05b1769c08bfbda924737b59bdf3ca5eee78e15b99d3958fbf9bac8cd42587b9feee046aafb2ed0d1311b50199f007640a095c40eed158e182c7346679e098966f13f99c5fd14ae047d784ad298276706714d697743c542beb1e197f8f6adfc635cd1171fb5d8a8a184c3affd395f9ff3b09eaba9ae22598d1c5f0b84d849707d822566170ab1811d1ff4ca49307bd661a3ab1be69528c88a0e2648d14830304e8aaa2c19361428b0b354863da5526c6e2cc1cd4972e8d64b7177ac042f97c8a0db27c7870d4678b5c418af0eb580ee7a3fbc38d3062dfde5d50b4ae5f4eee2085a96576f8d158713caf9b456e6",
            "aeb7954497ec69d6ee4b4cfc93c42c6bf7336eb515cb69b9b923b3c72d16936c7d997a32739aa2b43a622692aafe01f6d6eea1d1bfefa3e7d5ed4a3bd0b3472f63ed924dba95f3d761fbea9db8f7d36dfcf6cbaf1fcf0eb87cf212164f5b86e963e661f684c598387c2eb6ae3f0ea69a42a763f47b70f5e7f9d2574f5fd35993677defefed1350fbbfbec2f9fedafa4a656d10cb9ed64bb9064425122335381e717e31480f4bc5c8c4300c09b44394b939c9d538a0c0de9a0cd69892efdcecc8c5041fc2c41a401bcb81ae904374d90678efc5c53199011e177080211c904b46a06d38b86fc7c15e67f65a0a0f232cf8e8db3c0474611266d60fd085b947d3fce0e85b3e4a89e82b9e3ff9ff791cd5c6a69a088c8ca88fa509d337d60303e23c70a47703ecec9a8991e9812872b382831107957dfb62e7f6ede8dea11564a56544b2f5108ccb2a1153bf3e3b2e46c2cf2f1822ff3078d95a22c4448424272b7d5e6052ec658f125f0da2d5264ce78625342b32a931f76ff5d63f8bdfeb79825edbebe303a1e1b72ed388e77798f62fef23fbe6a5971e3f9d96e7bfbc15ebb06b63b0db91ddb59faf2bd8cfba7bd12d27a509bd3d6c9e0ebd17838e5b8fa16999283290926e7227d243e182b1025ba4b2d89fc0e27e14578cf95c332ce59aeb8a782658c6337f1dca17da71049cba78e6dbff0d3ffe8e13a3cf2b53cfd55cd722c216498e2c37f616e3e52a0b4ccd56e0077b6b3c19d405a72303315d64840de5e618902e45137731d6355162459e126b1a2bb0bb850cdb4ae4b834520eb25d821755123c99a5c0fd71123c5d24c0fb9321f8f0701b98b7fb416f16e0e6d67c3477e7d39671b21f62ecf9e9bfbbb742b5801b27f802d3fe6431cbee5c019fc6c955cc201b4f0cb5f321454ab52e51ae7aa716cbbc8cc47f33cf65f03b5fa3f77be3f4d8dfb17517ed95b3f799a533d79171836660d2b059d8be6a1b2e7c7f062f9e3cc78ba7cfb167fd1eac9cb30655131763e6b8851ff1fff4f13b7adcd7519621bc7cf61b3d7cf0fba779d939ddbfb83fde575cb7adf475136629a59d227d696e5814e27c43111f10cdbe8623272a16dde3c311a73645a0d090b4b65692f6362664a683942cb51392677102a0d200bad312d04bf6e4d96821aec770f1da8f83c7bd55a0f75be0c3ee245c2be26191a30415b656989ec4fa2d962fecc87323ba361ea443646875824f1c2df2f19ee9c0ff14fbff766eef7f0cf7bfec9beea6a656b7ed4d14a44794abae7f941b59581c8dd303f371b46f1e0e764dc7e2fc70740977858b9912b1d10998347a0caa260d836fe5607082ea61c6846118d0bb0f64d6f610967683bccf68c8bc02906da740a1870d0afc1c91e56683625f075296188b40678f330a6323376b53e9a77b6139f2673e2ee36cdf9ee178fe442ff3d5cb3baa57af74567f8ae91bc6d1037afc4f09fdf90a4daf7ef63ef1c9759af8eec998f847d7f5bf3feaf7e3490fafb3c7eb02fed7ea38515050d01111fbd49b26ce60e8c243f83078259e6ff91ecdac6d51ce57937256f72f1038e8b9000259ec4f676d254f85e73c3bdd4aaec5bb795c159dce335d2233e67f8b9dfdd7db80576bacdf596c666c4cb33c654cbf4c31ba17abd133df0acfd799605ea412579cdd304720c47aae0893cca5d8d7578ef2380986c6ca313b538185b90a6c2a32c1fa02139caf9441bb83f58b07e578b7528cfbe38d7167aa355eedad07ed2f9b40a816daa7f3401f9791130b1a56872a0c26480c8c257fe1c87faff30dbf3b10c7a3349f47f3ff14eda25f7b3ac45428a609720b66bcb517cefaa661968d0f536a6a4b83e4e6953281e89fc5baf43cea9483ad3dfdaef770dde6958731b2df74d62663dce0e9983779290e6cd9879fce5fa961b40cce1d3e8d5dabb793e5b357926963e63333c72dd6ae5bba173ffef0887ebfef1c1df9ddd467f513b3460979c6365f71bcffcbe2cf5ab5462a20a353a3abdba6366672a3d3513f3c195951c9689a9c81f2fc2294e5b7405941019ad6cf20ada2c3487b2f67ccd218e3a7400ede6572d8fe6d8c5f7ea88f354d6330d147836e2e0e98e026c0f94819b9176c874b7642ac76d160427028cafc43916ee3409a6844b897ef8b73c57e24c53f9269189a44739d6d33f9df62ffff49ecaf2dfad46009acdd635198b60f50ebc6267963783d7fecef918d237d1b6075d338322f2f882c6f1282a50d43d0dcd71e7e164af8fb0662caa811d8b0681a060fe98de3fbb623232505dca038880b3b40dcb23b94436640dca0391c55a648529b9056814ea443a00b1a78bb3241ee7eb4b0b0c3362bf9a73c5c9fd1ba7de2933b3793de3ca261cf6ed3d01f4e52cd86756fec57af4cb759bf86cba11f3f3521f5e55dda80bed5e5be7ff2a4d1fba7862cd68f4c7dfbe45ec4e3eb7adcffdacfffa9f5ed46b3dbcedea8cfb5316bf4682dbdf6146fc7ae03bdf11c53dbb545214780ae72172c116ad0976b027dbc7f1457894b4636a0124f863176a63378a6b4a9a18c46f0458dc5464606df62ffffed38a81b2b176bf20324359b3b28c88f134df0e65a7b1c1cef87cb932598186282e5be66985fcf146b9ad962e3c0203ca8b247636f01ba0449302d5d8e75f9a658dbd804172a15d0ae9082ec91e2d94619ae4f35c7cdc50178beaf3eb44753a17b32014cf539bc7f344b4bdf0dac5938a4d100c3bfd766b5c5f46453a9f448cbbfc9da6040ebb6efd2b7891edc5f384914b4c24ca3dbe51a8b5d4e51ba164a754d84dcfc92954826f8621cd5fabb0033917c8a5c20bae2a8d6d0c206a574eee455efd7ccdfa39d3c728176c6d825cc9c49cb98950b3630270f9e62ee5dbba38fe733cc7b2d73e3",
            "c24fcca16d876b96cd5e4f174c5b4b674f5a41c70e9d81e2bc1667bd1cbdfbf0b95c9bdfcf2d7cc5756c2a954a2fc80d0de8e828676660723cc90b8f417200abf57dc39019168dc2f854d2ac5e43b4482f46fb861dd1b3b00cc35b7723d3ba0d20732a2bb1be7753ececea82effbcac96a57038c52f2d1ded1857472f32013ec14e4410687bc89e4e0a1270f1b22bc4947670d1aa92d106d654bba7ada92ebadc2c882e6a124cc2f991646263d0d51294dbfc5feff23beac3616266adbb66d955aa1b89b111b4ebbb76d4607776dab2bcb4946bb4047ccc80ec19e8a6c6ced90864579e164519360b2303f904c4cf325cdbced3fcee3e738ab10e0ea8ce6cd5a62cfe695d8b3762ecc1c5d61dcb025c4a51510e7b78138af15e4ddc740d26910ac9c5d51e06e8d74575bf8d95831eddaf54245cfd1fbcc3e4deb8838dfcd5edffef5435a4e3fd098a7b7b5a9ef9e6887d337ef5b5f3a4dadd6ae3ae3b0e1630cc0dee3f6d917c5d5cf74cdab9fd12ef47d4ae6bd2b119d9827b429a525618f6e7d9e4358fd35b7d1c778085dbd7a9501cb64c6e535d7d28bf7f1e1d00fa08fde62cd985168c831447bb103d6b2baffa6911ae379a6d8cc33c7012e8b250247862afd697fa1eab619dfa83757c00fe7080df9dfe266ffad62c4f994f3305bcae7d744a8c54c9aad0c81663244d959624b2f295eef8cc2a11951d83b44858dddcd31a78d1526155863cf406b94c449d1c44384bdcd4cb1bd8509ee8f93e1fd62319e2c92e0a719e6b83cc51df73724e0e1a604dc5bec8f370792a0bb5b8eeab73fe8e8fb358492d5b44ba3386f8e911197c522a34f5bfafe82f1fa1c45610f4a4ce6bd1e6c79fcc38ea08dbf6d0c68f1b4d5c76cbf5cfa5d9df495b554a8522210214361c5ccb5f7c371ef248cb3f4d0169aa811a55075938ac55f7eb69603d82905ca415263e1698d8dfdabd4f80c5a98d39c96b5ec4907f51a47470f9e4e278daca273262fa1f3a72fa74b66afa273a72ea153c756d1d18326d29e6595ba66f9ad1ea4c6d7dfe9e3e2dd57c21704ff4ee3d7951c8bfafc3a0facf83ce47b38e8fced1d58fd660907330bf6d50ace966a78da6ae0e3e08a78bf5092159e8486e1696893d4887c97df96ccecf81d4e54ad80eee97d3cdc3e1547c735c2ba2ee11893628b0e6e66648d9c439e379382eeb406cde6e2a05a40065ac948033b7b12a3529271d13e647ed374d2392b8189f249a2edc20237b80b0cbed488dfca7f0f536a8b7e99f042d66869a36cba6aee0cb270da04ddaaf933c99923bb71e4d01e0c69de084b8ba3b1a3539a3e764396158492252cfe8f4ff6fa98db7f408227fac479c24e620c670b732427a520212a0c46890d206ad605e246ad88a4b81391147584b87e11e40d5b41d2a63f64ce9e08d038a24bd960ede8d10b69b077e02253c9c7b13a65cab37b741fa5d559b72f52bbe30769ec4f67b191feaa1b72ef5a8dc5b68dd79cb6acd53fc3f6ce6f1fd39e78458753ede0d6af1e88bb3fbea0eba27d59d5e8e5fd4f7de4ebd5feb5be84b73a3fff23f68f8acdd2d2ced3417f7a00e6ed3bcc2cef820c0e87b415aa315ca0c65916fb87b2b8dfcdd01c9d0c556434cf927961ec445b0b4d5672f83c5377a9f45befff9fb787beecb7140ae9105b8d6eb5ab07e6797a21cf52891f97dae2fc18350625b238ef2624959162d223548476be0294b2baffe8144b0c2e9061423d297eea2bc7891e521cea6785cbd33df1cbfa483cdb1c8d5b0b03717d9e3f1eac8a40f5b1181db953ceeace77f4d18f9b69af46718b1d59eec6f1fcc3f563b53a5f7127473ee46d95c76bed061ffa5b3f8ba6bf3455d4e5f648e118f3741ab19cb430b327fd6dbdd05ae540d2e416c837b1a18172b37abc4f79adfe59ac58cd5a7dd62af81cce3833896ca18d99d55a076bfb8df69676eb1d2ced56d9a9d4f36d4cad46a9e466dda47c4143f6b37e9fe3a5bf2f7571dd857e3d29b5539a319ed63688757541ba7f20021cdd88afc615ff8fbdf3008be2eafeff00db77611b2c2cbdf7de7befa0804a5150aca8581011bb127befbdd76882bdbed69868346ad4686cd1c4686212634d6283dd9d2ff73f2b9297f837edfda569e6f33cf7996577dd5de7de7bbee79cb9f78c978d23dac50461506e3a46b46d8d410579e8d322037db23231b2b01d7d78dd76684eeea2afcf198d6d8367626d4535d60fea8cf5fdb3b1b2c00b1b321d70604a202e2451f403078abe1dc6455b1b5bb4b337c1db59a1189392844c9f504deb9068d2dfdbbc97f0a7be1fcbff66c3c2f4b9733e455d09f4f626bdca7b6916cf5fac1b52350ce55d2b50d6a927aafbf6c7e54b9fe0f6dd3ba8c84bc58050bb675a3f32de0333d3bde949c95e280b74c0bc168108b15222d2da0c097666f0313586299f0ba5ad038c7b0c81a47c2444799d202928a325a945b4716c16f8b199b0f40d43fb9c7674a7a2ae9aa8e078e2e9ec33d85cf46cf5d29d95f5f7b573ebee3db23b73ecb0e3a13ddf859ffba0e188ee076dcaf993c4f1e4e18de60776cf9aa7b94f9691c76415d1ac1cf1e48e28fbebaf0f563ebe3dbef377df3469ffab3a0f9bc6b63e19b2956fc8c4fd11991a925d0db27a0f3ebf701ed5a161c8a628741258a20f4f8d151c737436324509a3fd5db82a7a14c742f7a1a19a14f24d665002a39fc4afec34f89ff2cc7af417a7e6d98bc52457a5a22b6d6c7025290adaf4148c08b046d76419c24cf9a88a16a3858b08ce723116b692617da10cf3f2cc707fb31dbe582e43d750317695dbe0dd093eb8ba2e0675fba271774318ae2d0fc6e76b4271636d185db72f4243aee592faafd7937513ab3f0b379714368ff599a3f3a75dcc1aff262f",
            "cdf50b6b29aac50f3d651bef7692977dde4ece25653fdeafe155a7698f52084728acf796c8e9fe668ef43eb7586c7608a7db4a2d751126a68f2dc5c615c64231cff3e563bef9bd33fe4f36b5a671cfd2ebbad7a2e9faca150987431c140a5de79804b48988a2435dbd11e4e283c2f8144cedd401e3db96606cdb12ba222d861e5ed002abfa75c39a372a91151186dc404f54e5e76354c7fe98dab11a63db0dc3e0826a54b4e98aeadc9618111f80aa305f0cf0b7a557c68b9066c2c5e21839ceb60a615e8ba0233cc3d13fcc87ceb71206bc44cb587ebbf6ebeb596d3515f049cbcc2cb26edd7a72fee255dd960d3b316bd22ccc9f31172b172dc7a675b5a85df51606f4a9c2db2b1661fdb2456813e88a01618ea88c70417fa6f50b77c6d06857b4f7b5450b57357a8739a1c0db061dfced91ec64011b110f66521348db7461fc801110a715c038b90d04a189f074f3427e720b248627c0c7c14d1b13d58278bb05e44b79cfb4ea3fddbfbb493a1174753f7fe2593e60fcfd9b64b0ee877ac70ba768ebd347ee567c711967c943729860fdf4c777f5ef49e972ef8b98e23bd75ef5b8bf49fbf5d7108f48b946645968b686b4188cba318bb16bfc047496c8504471d055a04637ae394672cce96e1c33ba07478572aeb97602c7125b0d552491271e4909384d7dcfce97ff7ddee873b99e0a1eef428a5249a63a3ae976797862a3af1726f8b8e2727c14e6db3ba2a58929e2a44ac4db89759511129d8bdc18117662d4769463598e310e8cf702f9408de9a542bc3b8dd1fa7591b8551b8eefb786e1ab75e1f8624d98ee762da3fb1f2436e84e2693bd735bfd90e3ef3456d8788f9a1f7fcbf3357db977c7d94d79b8d8bd29bfdfdc073022b53fb9c2e379b55861723c5df1bae5fde7080402d2466ea55962ed87d3de2918af72d5b6935b131fa9b2d45864fc5b75a2696da7fe733971549c7e8f9ebee9b55ddf9afee6c4c5c5e9f7191a51ff9ebd954de7ba589f03f0b6b0d0962666d21981a17490ab0f42dc7c31b04d6b5466e761709b7c6406f822253802a5c969c80c89a5cfae998ccff7afa013bc02e950276f3ac8de0911eebe745a6024f2a333d03ea52d0a6273911f9b817671a968c33c97179e8c64e673d6b464fce55676e81b1daccbf68f2023c35c3ef135e10aa8d77b4dcb9fa9fde14c677eebeee448c68d9faa3b70f0847e4d8beedcb9abf486d56f61efcedd786fff7ea61dc07b7b0f60e796edb874fa10ded9b21a6f2f5d8481bd7ba3a3af0d86c4ba6320a3fb95e18c0f10e68c4c2773ba3ad485ee17eaf4acceafbede6fba9339ba873821cece0ce63c0e644cff1ab7ed034158329cec9d911812037f373f783b7ad2811e41488ccfd7395a39044a45cf9624481d6b6b5bb5fee63371d5ad5bc6d4fbef9f6ff5e44e43f4a35b5aa72f2e6bb26e5c6eb8aaf98e7c441a164ffae1f6336d6be6c3bfaa35ff0c9bc522faadcc9fb949a4e49d96e51ad27b2ebeac1a8fd90989e8c6c4fc150652f4e499a38cab62f4df82399ad37d181fa082abd6cc6362fea51c338d1f5fd88be2735ed77ce45f19f737ed2bdfadbfc7f82847c7ba2301fef8323e1af5594998ecea8cc92e4e58c2e87f370b73baa599a92e5eae20dea64212e328a7436c14e81d638283654ccc3f2418e44977ec9e1f800d03dcf160471c7ed8164e7fb72542fb7857ac56f74e1cb9bb2b8a6c1ce3f9382750b650d15877be79ccdb3cc6e7efeee37cfbe976bfe1dfcfb67ff6fa0b9adfe807e4ffc437785d627f3df1149faf0b959ae92698bbe1987b02d6d987687b28ed48ac54b54d219234e5bbd8b1ff7f3fdf7abbd452afff599eaebaee19f9745e54221def1b4847baf9d23e762ee89c10cbc4f4c5a8cacdc5f46e9db161687f46cbd330ac6d1ebe5e3e04c38a3ba24bcb6e7469722b6406c720cadd8ff6b777a6dd2d6c685f1b473ac1d31f1901616813168d0e7109e8919e8dd6d12928090f65decbf80bde7e0d855e8e97451425b0fb694e8ee5d77545bf5fd9424489beb2575b90c14346d7cf9fbd1817cf9d074070f79baf70e6e8619c7aff3d7c74ec3d7c76fe04ce1ddf8bfbdf7e8ee3ef6c45d70ea5c866fa233d320c457ef618cae8bf3e073022ce83ee15e44877f1b3a507843ad3fd18bdd76b7fa6b3057a853aa3ad970de21d54705199422d1643e2ee074b1b0704b93263463f6edc7cf43e80262c2096c444b5fc4e2d57caa4d267b5879bf45c4e7d7ce440de935ba41579a88978f46d7dbbef6f92b3e449c366eda3419defdf7c9eff244d6bfc5fc5b8ffc575f8d54cd3e68584936f666dd092291bf04e4e5b8c33b5c030ca08939818bf1f474577d6e7fb993680d1fd811cb5661cc78a2c35b22003b9b2f36abe209a6abc6f2fbb3fe68fd1fe12cad0505bc0c43efdacad51e9e48063c95138191c80d936b6e8ac5663ac9d1d5da43223794c8b93cbcf187304276cc422e26f29a38b426438d2cf041fcc08c137fb8b31bfcc1187a7faeac8b1780d3912db507720869c5b1942a674b7ff3cde453c5e4c51ee2fdadf176df2f325ad63ef579bedbcd75ff9620ee0fffbbfbc2665b09be26e0565425d3317491aba28ed7403d4ae283577a463a56674b889f29e95c8c49a120a0dd89cd71fea6f4530edb187999c2e894fa58b1373509c988582e844c4780523d8d903933ae4637a877698d9b533c6176532cf876378410e768ea8a0479775474172213a67b645dba43ce4c7b740766416daa7b7a02b0b5ba1383e1e89de3e086462c334ff605a5f4f3823389e4ef18f456a6034a2ddbc759e166ae269aeda6dc2e14828b6eeffefedbfa5321e87e465e7d58f1e390107b76d7956c78ae029eedd3883bb372f327a",
            "7f03d0d5e1cbeb9fe0b32b677168e7569477ee86888824647939a07fa81d86c4b8a34fa00d46277862429217ddd3cf8eeee46b4b0f89704517c63768e361853e612e487332a7bd2dcde1e7e48a001777b8dbd8c3d5dc92f675f144807b001de01ea80df20cd1067984107ff720626f61dd536922697e9fde849e776f5eaed4de277dc8c3a71d9f7e4b466bef9103847c325ef37db2cb5757a8e771ffabbcbfafb93e7b336dbf854842e64c9d067cf68deedac43958efec8ec514070728398e73ad30cb48854e46e6a83232d32d3232d7ae30b224f3b896640457f15d384f3886e273252ff96c96ff9db686865c6d99a515363abbd1e7c28271233301d50ef618ebe88039b676c857a9e89e966a3acfccf481b344d251cae5eaafb31bbb29a92fa506fc86517972dd9d6556383cde865e9ec5d18ccc3041ddc158f2e5e670b26a886b5d51b47297ab94db569ff76a3e36f27f5ebf9a72002e375b198fffb6bdfcd7f4ff75ca61ead92217894992894a3b48e58a2d2e9168afb0d1664b2d889f89b2b3542462c7ff1feb0737ad953865c40c3db554a14df40b43dbc45c744a6b83b2ec02a407472190b1f531eeee887473a5c35ddd50d9b6003b46f7a097570f449b8474b48cc943715a090a13db203b340dc3fb0cc0f6e9a33136bf2586b64c479fac5cb4898a8587951d5c2ded10eaea43277a87202b208c4e0f8c42cbe028edd8783f52ecaa5a2b3532a058ffee37cf19fd35ff279ef60ef4807ec3e825b3e7e2f6975fe0deddbb4cbcbf0747dfdd810f4f1cc5a3474fa1d5d2d8fb9f3da85db706dbde5c8f5993a6213e3611392e6af4f6b34491b7353a6424a28d970d5d19644f97fb3ba285b31a7d429cd1d1d7163d831c9fe5fcbded1cb4d13e411a5f7b279d5a2aa5ed5516fafb66e818edd7847a87d221dee1c4cfc58f3858581f55494d9215aa1faf4d9abef9c9a9a96f3e79a07953fb3d5949dfc74ccd1d3297e87e18affd6e7cfe0f77a4d4a9fdfaf7716a0e1d7a95e754937dd217231fc6b447ad7373c985331f69bfdfb397de121e83594cbcbf90e2610b25c3f77c47fa96919576bd8152b3dfd00c1f1a28c81a2305e9c895de0ae509a60a855c87679fc46aff1f3167f4e7cf4a21146ef7979a20cdccb461a4b50dbdc1cf07a4300b172343b1dac91905a6a67417b5b9a69dcaacbec4cc8ca42b149946463f9e7a89a719f5a59588473e9a66455f99a9d6ad2e90925189c62423404ef7cc547fe06dce1fc47c99c70bdfafcf39fc16bbd6e403b4b8da5129faba4cfd6f8861e48c87345f2e12910013a5b69fd201273c1231d7da579b2b539308a9ea8085c4c4801dff7f8a86e8c7299def206fe816e84a5bc84c11e9ea81ae99add02ba73d8617156344bb428ceb5a8a5995ddb1b8b20c3b260ec6ee29e3d137a705da2727634849093a31efcf4fc8a1d382d2e94e992d5195158f783717144444a04b42327aa7a7a06374383cad1de1646e433ba92ce8200767b40c0c416e7094ae5f883b76279a7e1a646cd87c3f27cbcb693a47837814455a65e56a268f9b89f7766dc7feed3bd0bfd70094752c47d70ee5183978020eecfb007b771dc196b7b6a05fcf0af4efdd07abe6cfc3d6352b30f38d419830a027e6cf99837ddb3660d4c06a24b9d9d39dbc6c98585f8d625f3b5484bbead7ffd3fe8e2eda78ff10e260a6222a63315149c41a470b6b047b32b1be9b3ff176f420761656875572791b85f4c7bb94283c972ca9c87d70f3f3c1f5f7c94a42936da49e2c274feff5afbb3b33ffe12d57eadaa5ffc646af47cc9fc4b4339e363664d9a8b1e4f1fab7b5e7523219dda7e83914975e6528d51d149869888d9f8e98f893eb064ab2df4846c6714db4493ce17bb67c7e1913efab9eddedf4e773c52cbf8fa69a1873443c1ee9676ba3d9eae54d6f0ef0c5382f370c7671c43267178cb7b1d17552a948a44c4e426432926b66bac753f22cf5d2747d329d69e89f21abff7eb9ba6e5b171999972bbb176421182ea238812fdad89affbdef8c6af3a97f439d3ffd3ef48fd57c11c937b3d34eb6f4c4601b2f2cb20ba0fb281de868a9d9132bb18907afb10fd8b8f08fb557fa6bacf1cc9174f275d4f560743ad9db07764a15fc6d6d31b25d1e16f62bc3c2be5de84d632be979fdfbd3332a86d06bc74da6ef5db8847307dec19caa5118deae0346971633ad146f9414a275743c22dcfde0ef128a44ef2054a4c5a24558248ac30211e3e24607bb78d33eb64eb4bbda121e2a33f4f1b3d6cd8d75265be24c2f849b18b0faffdbe24c3dfb6d4d4d1ba64c9ea59d3d791616cd9c8b61fd06a17719a3f17daa199d1f88e993e7e2ed377760d35bbbb068f632cc9e3c0fa5edba223faf0003faf4c59a85b3b065ed6a2c9a310b9d8ada62edfcb998fcc6482438aa91e6688e369ed668e96a49073a396b5282c389bda9e906a548d0c3426e72c3cc58426ccdcc8983a5cd550b8562ba9980ef2ffaef6f740bfefcf2c4e83b5fdc4a7b7a8f7464065a6fa27bd4f7f1ad83dd1e7edb3bfcde0d2beaa363ffb575af47bedf94698bb83c5e433faf2072afcba0a724a66dfd6d4aa43d4871b587382a1c1658908fe5b6e49ab32fd961ed4a06f1a5df27f204ef58f278d5148fe34b89b92f7e2e6bf3fe387fb9036568585f62a1d64c7174a4273a3b41939b867bd949e86b65852ca5a9b6a3858a949a9bffe0676cb2c198cb9f6b21105851d4b36bce46f9f9cff6099e0ab3e693bdfd4dc9ca221919146f7cdec794efffc2ad16396cbffdaaedd22f6459672e95dd74757024e1d676da22ae1cdbad83b0c33912d9520b6d81cc920498980e91b079ff3f734ebc21662c6fbbd0084d415c36b2c3e2d1363a06ce6666f0",
            "b6b2d0b50ef040aebf179d17e049e70605a0302a821e585244af9b339b3eb97b37bd7bce4a2cac9e85a1edaa509e5d82818c860c2dc865e2fd6474888f4355ab2cf4488ea34b63a2d12b361091f60e0871f246a4ab3752bc03199db1858799423329d48cbe94253ce224346c9e0363f9f9f9a3b745dfc6868792f7de3d4a57f71d8c3143463e6b15e5fd51d9ab3faafa0cc49ce98bb16ee566ac5db10193474fc39ca9f3f0c690b18c0fd00d6d728a101d9188eade7db169f93254f6ec8dbcec56583d773ef2d3d211ae3286bf851c511e1eda8cf018e2acb6daaa1009f4fb659e699d5a2229945394f77fc354cacfeae6e7e3ec8fbe77cefdea7912fce01b125bffe04acaa3dbcbd31f7cdd25e6d65517e3cf2efe44df9878bfa9deefabaefd89149ffa345aac20c75c63080233c9672a1fb2939292a93c05a9e2cb484f81942e10496f25484c8ed8717933987f5340710ded9eafe96bdebf6cbcff7fec93fce78da27edc1bdfd9906b48f2cdcdb1d4d199dee0e68e9de141a88d0cc2011f6f2c7172d615aacc488a5279c64d22f1fb993e0e36e170ee307a7f2154cddb6e27e10e66627e79b3fc02abf9bfdd7ee903fa07aeb6f6645c9f2aedea790bb078fe3c74f10f437bb1b9ae50694d428d956798d89f47b16bc2fe2cf4f1cacd201b8b86f2d4167441742add392507eda2c3687f1b1bda5ea124ae328926da4aa90b3257d0216a533a486d8a607339622d157496ab2ddd2d26147d3273e8bed9edd12faf07ba657444617436f24263d03e360abdd2e3d1273d89ee10130e7f1b6b785b3b23c4d18d4ef5f647925f846e45ac8d36ca4a41c26cad482747e14253238af5f57e9bde0c900b78242a30545bdd7f18460c1c813799f9337af00826eeaf42657925860f1c89c5739763f5d2b7b068ce0a1cdcbd0f9f5efd0cdb376d447545350a5bb74745ef4a1cdbbb053bd62e4351eb42b4cdef80217d0760fad889f0b6b14194a78f2e272601fece6eb7cc8d4d54e68d35371b6d1d216a11799caad8bbbbc6b4f6ad0de65b36be6bb967e756bb638726ba5df9b8b5d7e5b3ce9ea78fbdd897fa9c935ef75ff5fafdcdf391fab892895f8cc97985079929527f1f63c079c79ec35d2812f14630717d578acfcda278467ecc9933fd199bc8c68c7f1edd99fe212dcd54f45a37777a9b8f0f6e24c5e2dbd4787ab09d2da6d9dbeb46585b910ca5f2b89d482c6f161fbdcc0fd36f3ee7fdcc3860f965dd6f7e3e6d18aff73b571b5b549676a38f32b6e9e9dd07983e7a1c9d1c18448732beb28bb12cde48cc67f5e0cf435f8be4a1bf8d6d43696236dd363e07a5f1293a46fb75914e4ec45365f685fefab28cc725ce0aa9c64725d7998b84b05398c15ea1809b52862073391d676346b770b3a7737cfdd02a2c16ed623250149d818ce0043ade2f9c4ef1f7870fa325491e1ec80df047ba7f101ded13a61d14e14b7aba9810995078c99ccf1dcafc1633c94fefe5c0f2f3fabf56cee791ec842c4d76524bb4cecec5d07efd30a057050631fa3da8df60cc9f3a1beb97bd89752b36d0efee7b1793c64d427e5e115ae7e46370fffe58b574214ebeb707dbde5c84aea59de9ee5d7aa34fcf4a7ac9bcb9f492058be9f8e0083a3f3aa13ed2c79f89fd2d07281b6bf8fd58c34e5d53e6219931d14fb6608183f9ead512b3dada9f8fc708e1c41d3a644811f2baf5431ba1118f54cbc4f84e2e7f5264207c83d1783b4af68bb559f5f9ad267d61b5e38fd397a67339d484a27a28f9fc143e253e626f2a24d1723906585bd1236dedb0dcdf1b7ba243e81dde5e18c93cd75665a6abb254d78549a5aecfa5fdb7d420d55fdbe7b0b6ea77c5fc4dbe92d1b3182288fa4c213126366616ba9498784c1c320203da95d29d5ae690005bfb6fcc794263a552c9eac19f1bbbec940b84c88d6ea11d5d54a02bf473d566bb3b91502bf3717c030363254595490d0d2fab0402e2ad10132f95195a472423da3d007e766e705259d35652391c6432f8a89488b0b3a2e35d5ce9142f5f640546d02d2252e9a4a064e6f35350149742e78545233338b23e3f2286cc89b43c64c93348a61a6bd5b3fc369a6c530f09c7b021c0d54bd3363b1f3dda97a177b77ea8ec5989aeedbba0434131de18381833c64d44ed9b1be91e65bd111f938aa236ed995682d2922ee8d9ad374a8b3b212b3d072db35aa3756e0172d2b35198dd12a9c19174665894368c89fffd5d3d6e5bc9e5a61289e4d7e6a23ea66fd2fae7b9fdd722ceff399b26ccb7a6ce080d39e4a893941c7694553493f3268d6fd2f97f536db1bfc51f7bbe546eb0994840b62c694116745692483587ec99ec460ff1b2a067d93ae1644c188e85876088a5258a2d54744fb585aea5a992743237dff8fc3e0a4db5017ea9dfd93efcfddacf77a6a872994422b4b6d697e5a7c29889f1c84a694e47f887d2e13ea160fc00e42524698a53d3740549c91fc98492a6ebc006bfc1af60f91f75447fefd1d66191da9169e1a4d0db81845b99558b0c7f1296e893be3d9876cfc5ca0e438bbad23dd20b5092988ba2d80cba383699cef00ba0ed64265a27855c9be06447c73b3bd0a9eeae749a970fdd3b2e06435363e9dca0603ac6c559eb676b47521d2d1f842bf9b62fc4536c7ffef67e1b27e7734998977f5d944f20e28342d1af6b4fac59b802b5ab6b71f1fc455cfee40ab6d6be8d4573e660f0806af4e8dc0385b9f9c849cb42764a06b212d3d03239032d93d2901d9b84dcb864b44bcd447e420a9d1e16a50972f3ae0ff1f4259eb6f6b3cc5ebe06c7e0b9be37b67f9fffacb74f211487a3ed2be4df192f12e8f7791b913f275fc9eaceafc7326e4c7b3abc54a925a444f3c58e16f49474",
            "9ef6e1e6102caef2c5127b07dccf48c26227470cb5b6a64b54a624cd5459ef2491bc632b92384a1bef27c3e663fef8bed127f1f728c4c60f4c8d65b60201d59e4b51b7d40a1509f10ea2fb96f6444e4a4b982bccb48e9636a44b8b1cd23a3ee15395546ec8eafc9f6bbf9866c504dfc7cc843cadbbc2e4be8752d2fa053d6e9e0bfb30ccd5834c281ba41d51d405238bbba0a265313da2b0a4a18d9f0731170a88b5b198045a281a5a3a9bd3259e3674b99735ddd2de147e160ad8c8a53a3b85125612d15b46ffad85c5e6d0feb77e8b321308beb735352381ae1ef5c1ee9eba406737847bfaa03513c3af5ab41cefed3f8403dbb760f7c6b7f0f68a15983c642486742f4755c74ee8dfa114fd8adba3479b42b44dcfa2736213e894d0485d94b7bfcec7deb9c1cfd195f839b91247738b4d6a6363b5a948c4c6ae2fd71c3389847ad29bcbbbd18b23e43bb3f6ea6fe98be76bfc96f9a805e4cb550a4dfd954c1cded1133dc385b8fea63574772a30b9c00ec3956a4cb1b5d775b554912e6af31b8126267e1497cb9ec13f97b10606066458bfaa272d12921f0a8cf824d0dd8f64c6a6d1e3078e46ef8ebde1a0b6a13dec9d895a6efa8595c274b6314f942ce58b599ff7af43bfe6d5a999f6ff24ee2084e82f8c9dcb09b123ef8d29d7cdea3e04e38b3b61586129dd332a48eb672a2b620c622bc69758c23330a8f330e123c95c40db4884f03137839f950d9de8e2da3027d2fa619e8dc0e425dfc3f2fbb52758c9e19c353736262e565624d4c35b1be1e1ab0d72f1a063fc42e828c6b7f6b677868bda0aee567688f20e44b44f201deb17ac4b0c0cd3eab5dedfd1595fcb47eb69e7081f4717e2616d472ca5b227764ad38dcce7c6c804eced187f06a3e7f17f2a656444a6cb64f5d57c637f8adb589f9d3d3d7ff95cd0e7121f96270a1ae8f7bde9993d43313331ba61f790be787b6622eacef9e3fece70cc68af40a65242e7484d357132790ad558d787cd3dfe79e817c27c6da930c5fbbbf7d237ce5d24dd4a3aeac282a3e8de5dcb31b94725229dbdb4ae0e2ec4c9d276994c2896b1a7ec2fc5e025768d7a89feeb8f27435d54f4fbb35b6b0f8c6e8b4d03caeaa67728211d3cad97c9053f5912bb836b60d860ab34d7385b3aa183bf075d19eaada90af5214b23554b1d85cfe62c37883df77f84ddd35f4f1ba014083e534ba5c4c5c29244f8f893acd864b48c4bd545f9066afd9cdcb4915efeba18df60c4f8061146ff499c7f08f17570268cce130f1b5bc2f80875f666aa536a99ac5825167b2878bc17f30d2c2fc69c8dc7f54e1c0ef9c8d68d0c149a2eb1307a76de8cf2d9f3f357db2f0ba6ddce7417361c7fc3929edbda04a75ae5821cff0f36458763419e01ce8d31c5d9c936bacdfd156448aae4235785a0a91fd9f1fde7a15fdf45029c5dd13e331b1b57aca2776ede8a563235f6c4e6a13630858e94281a3cdcbcaf5bc8144d1b61d9bd947f8f9efcdc39ffb156009fe9cb185b6bba43845b7defc410322cc2fd5e809c674b35d6c7103eb77d254c0792106bb526c6d50bb95e6e747598a76e64b887a693932cf005fd62f9bffb007af46b350be502ee5b6612c90d6b85a2ded1dc8238314d7f74565bea1b98c73fd8abcc3fb5552ad731f17d815c2ce8672a16b7940979aec6bc97aed365f9793c291e55d781678c7bc6cef40843457d225712c46dbcd7213bbeffc25ccc737f6bae82cb25ab3bca344bdb2ab0d7de0edbf97c2c3712a12ad1196f648a303054a49992614246a69accb19108d89ab27f3e3e4c7be06061d950949c4ae744c560d2f8c95868eb851b01a9a892dbeac24dd5c4d5d1ed944a2a67cfd63f5b676c0402c1719580f7c8d1c484f899995e711673039ae7099e377d6d876bd66221c9f674abeb12e856373fd1938c8bf6ba1a6e26d1afaf35206c819f3f32fe79d186e9cfbf8f98a2e2a54646e9267c7ea631cf2889791c24e552b602aa5945f997d85256bb7e33931987976ccd6ea5b99b5daa194171c950aee91677aea0797e80e52fd07faad1a6c432a14ac3c05463bab6930c2b45a698e5aac0b699ce204fab71697920a6e409341dfdc50d5dc3246ffa5a880cd85ccd5f42857e8d795a78b47650a7ae98376326164a6d315d6e8d3e192d50555686f488a83a954c992fe1f1f47bfe58fbf3cf467fdf99d6468db59b5f8c759ab428575f3bc0416a428a3c6dc9f238eb272166263d841c433636fa73fd80df1acf34c5f7cdf7a1b379d0dfa339849c0ea5a88687473fd07d3a760a3d9c79bc8aa7bad7862336a5243ff609cb5f33f6f5e8fdda2bc5a162b2a58742b3b448aeb9b6d6527363a3a366fba810cd8e41eeda0f6ae4f5ef5428496d67e587fe96a226bf81eda73fb16f0821beccb1212e380ce32b07d20bc78e47dfe070ba57a7cedad699d99ad4d0084db7dc5c5dd7dc56c4ddd6beb388cbd6fcf987cfb397e5065ef65c24a5bfa723d7709b85c0d0eb173e83e58fef27c366fe40f3fde7acceff31c8283fbb9b290686e4dab8c9f4d6b41c7a1665442e1b499f8e110a5d7f616eb0fc49fe5863596a6a9587a990ecad3423478629c9f416c6a43c40cc341ee91b2c24c3e2a46449be5c93e9228e7a7e5993eda33f1f1ba63d890e0821ebe72ed24e1f3b4e5b90954d8a52d248abd838921e1e415a32c7e490b0890a63295b07f39f4f93b618fcca7b7ecb732c2caf22fa8bfc1f87f184584809349329a1e6a2484c133fd537bd658d8564583feb2fa5698d52a12957f038c15e743cc094b7c44ecc19666722e86e219154591a0b163bcb781ffb2af99d158d31266b8ffe1a2c99f67d41564b7ae3d295a445540c490b0af93ec0c56d9fad99f96ca5c4788b42",
            "6c3c44c4e1b173e635f3c99b62ce1a76aeb1bc7ef49609f9a44c202357f926847849c881089b5156cff397ec75e5bfc72f0b0aa2f4757c7f6d2d336b8ffe3af4653148514e2ec94fcb386f25530e901b1bdbbfe47dacf6b3b0b0bc0a1834f301ceb6150a2ef510f3475873384df5ac585bc6c2d2488054243a65662c2b15181a36df28ae8f0b9b5f9764616d2a0bcbab865ef3f9ec6960617929fab961f4c27c61f59e85d57e16161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161696570b03a619318df3fc310b0b0bcbeb62db585e5f0c9b3de6d5e47b4a3ccd28eea2b2a017dfc379ae71ec78683c1f46cd349f9d332c2c2caf034d363e5d2e325a6a6c64f4a246b0fccdda5343d57098a63f32fd5263944fd5eadbffa2394dff26496a44ad61feb8606c60f0b99cc3f9584419ee92713925b662812ac2dc9cd5b797fb4b3ffa4d4c4b635a37a6f1fba43bb3738685e5ef999b86acfffd7fd597676c0d7456901e793e09cdfc0296bf57f799467eed3dbf57c7fa9bf238c45e6e4cde2889259b0667918d7da3c8f80c67126569424c3846778d29830dcc9b87991872729d2442ea5f3c1e9a627d0f173b8ba5320e35482ea0a6d8998a2fb8a945a465bc3d292b4eda66c2e508d839f35a62c0f6e93fb65f0c5e12c7b23ef8ff10fb13424298637daf3c47fad1c9b2e3de96620e154719e5e7b37ed5df38be9b882f359fb1b0abe5cc435dd5b3f776b298b9a4abd5ccc26afbb546b5f9b5bfc70768b2633bf91445f2429d9e92cf16e8c87ba3e86f17b6d2dd9a93a5dd5f19a95d571e4ae616fb935ef14ec4c7dc84181b71f60929031b2fb9e0dfa46fcded7ea2a3b9f2b68c4791f8107fe2efec48ec4d8dc8d241963a72af6b1dd12e2733ab03f659ca2532a99d1deb03bc5eb125cb3fbb5f3c284a124851222945c97fa269ec69fa6dfa9fdf78dc221709c8c9257175e4c16832a3bb5b27369ef9dbf1af7159bb72a8f3da770639ae9a31c861f98241f6ab1f56d9ae20bdac9691aeeaf9872b6d57b84cf2d8f15b7d80a6be5c2e343022590e26dac77b47e2f6db3d717a54224e8c48c08571c9f87266267d7d6a9af693d109da351dfcb4fd129d4845b2dbe78c0f106cc2e1348f89ff0db14599ad4a5a2f66fca581bdbbd4efd8b847b370fa0acd98c1a37469112128ce54634db94a73649039995828ff58c9a17c54722eab1daf475ca4c78c694364029148ad56b367e59fa3fd56d642ebddd6024ad33a44a86b1b6ef26588ad64a69c2b726bbc34c7fa6fbf638cc7338d1edc3542472eb6d2e2fe46fc70b8e39759de7c738a1253ac2ff5576b0fe1d578d6640f765e5533dc7575da28b7b79abfee32d363dfad312e9b359d2de6908eaa799f0fb47fd37a96cf6e83dfe0031834e67aa8c3c6465c52e428d69e18148f470747e3daca1e383624113bbb05e2cca8247c3c3619470644e228d3ce0e8fd73c589c47a616fa3d3017f052d462feebec03348d757d4e6c92a9984ba48614664f1ea17b70e73656cd5f8f15f3d7a176e5366c5eb30323074d40888b3d5655796aaeaecf2573abfc6eaba5bc402997f5015e83bc4f04d33ef5f5f2252e0e2e36028180edd37f86f63b323ef9a78e128ad42e2e07b9d6124fd773c9e7736564654fd9e35477f10c39c555509409ab5dbf32d6192de03b3b5397eccdc4a47648807649278b86796d1d34ab3adb92c119b2378c1bed18873d557fed3867745c58695ddbfc39fdfa3fee226a91fef1f6c91eff21831d6a1fb7339d4e46396fdf3bd16ddbf3b502353f67d39ad6c9283c4d4cbe96191991c1e116ba8ffaf831317f06c8f1c9204747e1feb236b839330bd7a6a5e3daf40c7cc6b42b53d2707152baf687156dc89c0ec17502cab0a58ac77b1d73434d71bf497a68e876130e455c2d95daff6c5b4b33be00ce1c3f857776edc7fbfbdfc3de2d3bf1de9ec358bfea2dac1a1602ede516a87bb249f3c327d5e4ad1aef2fad4db8e62a95d880b53fafa4bee8e9c3b4babcac2cf2eec75f3ef10a4df16063cabf7d6eeacfbd20aeb4f4436b3e45362e28afd7cf4bcd9377e9fae31e74dd4e3b0dd92125dfbd6d4a9655a8af05d94a12aca462b6cf7ef99c728328aaab5a22faca516284e1d146da2fb71537ace9e174c95668682f954a591bf637e667f4ebfc6bf36b0d0845f4eb008d6aa95a4352433e5ee07d84ccf1795737c573b776aae76e32dbe750ab295eff79f66f9eaf0968d2e717fbce4bcee5c2826b84b5ad9df1d9c8487cd4d7176f96f86270412466768ac2bc127fbc37281ad76664e1c3e10938393c1e37e7e7e05045a46e698e7343af20738da38930854fbd76fb449afc99dd32ae01490cf3afffe0bd03b8f6e9e7f8e6ab2ff0e9f98f71fafde3f4e9c3efe3fcc93358bf722d1696dbd34fb63be1d1f10c7ae700577a618e00bd134c35f6a66237a531efc5f3f3e3fec1b8ff36fdf537767efdfd34c5387ac158a60f8daaab0681d6e9e8d5e7741a07ef683756ffff6e5bf88c2a31252055f97246fb3f411d0874faa63d03dddd1ed07e9e437fb92ba7feec6807b2a485f1d7fe6ab17e5d00ab61bfe0533d8f188f873a4ac8b2ce0acdcc41d9647699eb851417230965e6695853c39ebbbfbe4f08a726ee905ef75f7cbddf78d71d",
            "649ceb2eed24f7ddf442bf239a39be071b16f8be5f3bcbeb6073fd6fde67627373734be6e8c928d278fdb57f7f53a1f6fca0307c323c12d7df8846ef107314f99963598f385c58d50b5faf28c6e549c9f864722ace8f4bc1e1ca081c1b10856da57eda6d45ee6454bcdd1d4b21df5a2114be2e73ab49fbbb49f986c4dbc1aa7ed1ec45983b7305a64d5a80fb776f4357f703beb9f109ae5fbc886db51bb1668817eeacb5c5bd0ff2f09fa1ee989426a493fc9d48906fc23d3b53a9859988a258bbf38fcaeb18fc5c0cf4fcb10bd34ea8941664d5aa755a26b6d45dfea6aea16ae77d9d47608c27abff7f6bffe9913aca1dbff631e7e2fac1041dc12d68be580dedb9d6d07d190fdd0f63f1d99212accd926242b4887eb78371436b4fb17e6d20db6f2fa769dc77d6dbbc001b99d6ddce0d8101799ac4d852e26169dadf54f0af58eff58f18e3e499e6ff7ff97bf114f3bdc693945bad27fa1c1a39ccb996aeb05d4677b698450f71588f752167b46b424e6275d0e983b33c0e508dbe434d939695c9f9fc636203ea53058ffbc0ca58a97335b52262431e3a0599e33346fb3fec178813fd82511260812315a1d852e088b73bf8e0ec9c627cb3a6336e2d2bc2977373717a44220ef40ac5fa024f2ccc70a85fd9c28144a925fdc586afc5f868da3f6c672193ddb730e6d1832a06e8a64e5a842103a762d5f20db873f77b7cfdf55dd0dac7387bf243ac5d5005ed95f6a0bf1a8e932bda624c9c11227d3ce9a4d842929b9affc85621b1b013899a6a28e98fc2f070eb680145f5661e4f6226de0c39973f96094eba312f2aac4dd86b957fa18e34f7099a74218b69dffa7a059093274e69f479655a5b8f3947eed3030fd537788726867358fdffdb7233718dc7522e13fb57e72bb4e4d348d41f8f017d5801dd5119b45f97d2e7a7e763541085481b315c14227a53beb8a153802496a2fe55fb967e6fbc63cb9c9d9b1652193cdc127441216dd0a5eb58ede8916fc3d72ffd84854cca6f1cf335ac6dfaf36c923ecfdffcb9b0291e1bde18e3f2f67b431c57df18e8b8e2cb6a8715dff5b75f4a46bb6ec55cdf77b132e434b6455fc3f2a00feb2678ee24a35cb60e1f61ffec33b8654165fae340a540402c44c6a420a21d19963f89f44c1dd0d026289f5672c55852e08ea33dfdf141ef00bcdf37084392ecf14e670f6c686d8b752dad3139568999796e78bb7714f68c4cc7a919adf1647d31ee2c6a85f36353b4a787c66160b2f3263165a85f4362f89acc855d520e458a72723533a62da5c78e9a8141d593b17fff312c59b40153262dc3ee5d1f60edc25e78f2657710b215df7eba0dd3d24588f1b043564a095ddaba9bb6aca482f838da0d3715fce43b4a65222e490830278b262791bd4ba2c83bcbfcc8e17d5dc9baf99d76b8289eadfb34ac61e7c39f1dff376f8dd7626a6aaac41c4e43bbdc5cf2e8c13d7ddc8ffb8f9ee2e2ada7e8b9e39e76cc47848466b4cd7b61acb0fcb5feb99e1dd61241c38159765a72c61eba0fedf170af2334e7fc7071962f29f7a0e0652e41b4a5884eb117614fb188b4f31145b2fafffffb53cf8f4aa69d36379690b0e06c5d74745b24a7774759af31983363933627b79a0407a52e5349c44de78ff501fef898bfe9b1aa87f9fcaae14eeb4ed638bf89f16e1bc902df4364becfbb64a6d73e32c56337f3f7fbdabd31dfd027929e6247f4757aa2e7ceba5e368bf57b01cf57d82c3799e57c5c1ffbebfbc832c0c6edb190a2d02eaebd66c3d0c3f498e279b4b7da8936669eb311f2f04e7910b6b575c32743c270a232040b5bbb61578913b614dae3ed36f69896648ef1314a0c0c93c25fce459e9b0c4bdbfb6352813f167508a8dfd8338c748f75baa6e070f8e9ceceaf72ecda64173a1b1b5224d8c3453363ea124c9cb000d5032660c68c95d8b6fd08c68c9a87f9733762f6a421f8f24008c88d24107a0ef64ec8421b77239477abc6c88153d0ab6c20ddabdb60ba67e74ad82ac4ed2d8cb93ecc67bb581953815caea8a143a259fdcdb7a335774e543131e626a69da9af7b378f7489334ea5283e6ba7fe7ccd6f6a9cb8b8675165a2d8884f3c4293e9b147eee8aa0edc42c49b9f61fd95efb1f682065d773fd04cbb4c48cb9e3583383fcd99b2fcb5391b53a6dd8bf3342177b63bd075879c7063b11a3757a8f1f54a6b52e1cbfdc64e296988b51121ca524c177888c9914ee247694e429be7facfe66d7e7a3ef546fbacb552459253ba68e3934a1015dd0651316d1017db06e1a12de0e71da38d8ccc277e9ee11354c662f6ccfd39dacfd8fbfcea72cb155f5558ad66e2f8cd645dc829fafdf8db756753eae8f3c934b9944ac88564e898a3e67c32b4b52117eb873bada7ab1d56e8f301a746bb6c779adc78ed9f1b443dabe15fa5e4f1885a2cd54ceebc086b866dc6f88e93d122201d261c2e926cc43858ea8d4d45aef86a4c0cf6f508a4176659d13b4becb1abbd3316665a31faafc2ec3435b29da448b0956050a42922547c64d889b4056e26c449c461fc0bc32c2b11ef559e5b4d797f0b3333b3db6a133eaafa0ed14d9ab008c3864c4345c5786cdd7e140be633ba3f633d66cd5c83838bc340ae67e0d38339f4ae51a13858ad46b28705a3ff83b07a792d460c9dcef80cabe8b9736a1b3ab6eda6b130e66be202ddae053aabd730dfd330b2dc8b3e56638d89711c1c9c5982275facd27c3ed796ace969b5dd42cadaa93f4ef749e33a9a9a9a9735a3fcfc7cbe73a3df9aa3d4fbc489a55aa7f5dfc168fe671870ea7b5cbffb18057bef60cc69ad66fe0d42062e7c6b31eff5d5ff7f72fddc267f38897948fae59ad28f3758e2d278052e4d52e81eacb326b35284cb6c",
            "65e21dae661252e02ed615ba8874b3d2c50dfb3b1a9ff05589d8dac03f9d1bfa5c7e3bb94070c7c1d29124c477d18685e5c0cb2d1c017ea9484aea882e9d66a1737e216a27c622c03b49ebe79b48ec2d6ce6998a78fa1a186c1ee00fe98767daaf2a319fbfa78fcd4a32c87e2319e0b04eb323f292ee6636d1ddcc24e49b16e4f1c5d427972fa6d5dd3d9dfc3d399df490ec8ffe9accf0de476678edd74ef7de3f639eff61e3f75bde7d36879fc7fe868490b38cad22998159ba79e56fa1655031d68d5e802555535114d516fe2a19468729b1a9b53376b4f7c281321fd4e6db62735b474c4fb5c21426f69f976185f65e3284ab04a88e50a2ad8714ed7de49acefe0ae26222386bcae705384b45d42b3e169a6ccb0a13238ab4484ed58e1bbb1803074c469f5ea3307b6e2d6a37bc8ff973dec2fcf9bb3163681e4d3e8ea4cfac8ea627a64950194ad17d63c588f5f3444662112aba55e1fcf96b387cf4132c5bb69d9e396b3dfc5ddc1a762f9f480e6f7f9be4a5d8e1c107adb0afbf1596b733c5eaf6c674b72415bd798447c3e971768fa29cc4b62fe43b597e77ac4ff4751b387135877835172e700e1d3ac4d16b3ed16b7e6dadbee9ffe6a7a7a7f3f2f36bf473e5a08544422267edd2991fd4a1fd9947d0e7ff579ebe056acc07e871ea81ee43e689b567cf1f37939abdb88ef075b083fff4b1c64f7f96aba1469870046465a5b9e6fe62335c182fd7dd5ea526bb3a884f849809069b484c74a5be627a43a610ab5285f50fe7cbc9c42ce337e4c267b5cb9bd60fbccefc9a9fd37c9deb7a19cf80b83bf8d7f978c4c28f6929c99dd02aaf3f7af55c806ea553b06b822fc8b5328c2e8da583424be8b0906c622597f9cab83fda4dd607f8bff960bc0bf917dea9b25d4d46ba6cab1be4bc8e5e1e7814b75a10fa9b6c1db992f164f9eea84f5dd7879c1595a917998ff3de96b224e883d14b838fad7933f4ccb4d5c1678237445efeb1ef1bef0bd4e827abf8622805227a46f7e5e8df7234e29cb351105e8aff2c5e86d3eb56627e456f24fb38a3d88e87b5d9f6d8d7d11d3b19ed9f936183786b11e303a83129c9023d03157823ce0c5dfce528f494d1edbce5c482cfdd2ce770e43e526973fd7c95b53f5eca68bf87ad5a3774d0645a9ff3efdb7b2c860e9d851dbb4f32b1ff26ac5ab50fc3068cc2b5ad7ef4d5da08baab1f07b1ce62dadfd31f51a169c8cd2841fbfcee2868518ac1fd47e3d4a94fb077df1994771f414f199145ef5fdd9ebeb07bb5f6dd0db331a34485fff452e2e0203bf44c34a5a36c45740b77a166631f4b54a42a4a9e9b6376bded6fd2fa9fe8b00145883eb6e7f7d97db5e9bd8cb52a13e6d71e3309dd7d9cbb68d12241694d8d28bbacace9f5094c23c55583b549f7094aaed743075d0323ff68b5f306a891c7205e70891e76e9bb866b44fb343834caa5d9d8791df6bd34d98c4c5323de3e17b9d0d24d29fca7f8352ffe86dd2e66627274ac4a7b739612d7e79be1e250e3ba16f6fc0d62b1f851a187a8e1cd0ca16e4d0abffed642153932d6ec337799e0df5283c3e037f6b31e7d81f25376e676747c4c475d74641ba4a7f542467a157232abd0be5539968c4c04399704f2f42ddcfb601afa65bbea82434b757e7eb9ef5929a472dbdffebdac8ff012dd79be3f2f6b76d07eb220f0a866a4db464cf0da860f126f6a1fe51172bdc5d3552bc23ef84d9fa5bf07e0f3eb084d9a5125363424bed66e9aeadc91c80fe988b6915dd136a23b8aa3cbb061da045cd9b901e777bc8d5143ca91e922a7e7a49963559e3d0a3de468cbc4fc0b32ad3038ca14836394a80863627f1fb9aead97bcc19cc75daae4715ed4cf57d807d3c715351f988a0c49bbfc52ede041d3d1af622cca7bbc814d9bdfc15b6f1dc2d2455b307de656ac1d1d8d5bdb03d027ce04a38a2d101f1683ceedfaa0635177ba5b89fed8035ddaf74249611906540cc38e9dc7e8c2ac4c7cf27e39134fcec69ef951d8b7680cde9e3e02938a9d312c5382145763b4f197627caa4c3b2d574dbac72916ca046cbdaddfa9ffffcdf3931a46eb9fcd2d6f6ad3d96589e76f9f8dbbf6fd0792135f855bed3e279c969fcf614279fdeb014cdb66229193ea5e7d748b9e68d0ed810e37353a6c7aacc3f51fea60567b13d4c45390cfbf00c5daebda29df1052f9c6989efff52b7e714fe1abe4ffa6310fb5c5f12ad223d32291df78ef57a3bfb83ff57bfb0d7f463772f57b96a506fc07f1ee92864f6798d1d7669ad1df4c53a07f105fa7968a4959a098bcd542acd9d74e4c3e1aa9200b3acb2ffba844dee6e27f45ed9fa67395ce34e3978cc9a6c70e7cbed49719b8571cd576a44576b52e32a60bbc7dda2039b600ddf3a3f1d6cc545cffa827c8ede1f8e1d2687c7572352e6d9b80cf96b8e1dd85e174d7bc04e2641f7e5e2191edb4960acc7e217fc4eafecfa3dfd7af3f4e1aeafe66c3e698ab9a2dd197e9b97e07f051f22d6d7d2121ef245c8f9be5ff8ebece8fe050dc7523924f189f81704f0511feeef4ab7aff41fff78bf7056cea77330b89c50d255f4898b856e728b7407e581186b61980216dca5112d90a47d72e02a9ff0ce4e6092c1c340c096e5ef092f39060c5c1fc744b5485a990eb6282fe610ab4f396e9dafbc88915dfe0a2ccc8a0b976bed23ed8f36381beae7fb097bb76f8b0e9e8df6f1ccaba0dc7dc396b70e1d25758be6c1756ac388011fd2bf0f5db2ed83cde0b37de2fc4a4ea6c54761b88beddfaa14b492fba47c7bee8d6a10f7a74edcfc4fc03d0b9b4172afa8ca46303c3717c5b6f7c7eb017c8adce38bd3d13ab471463f51b5528cf894112a3ff3d23e5189661f7c4dfd678bf959417672dfb",
            "c91a80a635ea6cbeede7d7f1355ecfafad15561e3ba6df8b926272e4dafd15f7ebc85142e8c81b3f14991eba62f85cf7fd99b6dc4428ab2f2c68474e1e3fa965649d9e534fe3529d86aeb9adc1f01f68ccb8fa10d48147b4e1bc4bb46cc165b8ecb9a7f13f41484cb781234d1a7f0bcfd3535f17a5e655f5019a72c55642a1f076a0a5b0e1cef978babaa37dee5fecdb1bfc826faedf2fbbd946c42535956964cb780794c70871638e19be9e6b4a2f6ac9a7e3ac85f4b4049166776b31d956644ce6b6367e98ee219e2035109a287e5e9b5e279ef52333b6f5b55d3459e1d683839c958d7161fe4ffad157cc15df7231177c6f6b6e47c2227be9bc7d5a22233210b32a03716d5b3cc8872d71676f2e8ece4ac1b2ae1e18936a8a9e0146e8e84a6164bc08ef4ff2c60fbbc2747b26049008376b12e6a1da9f1164fe6c6f33f9697da0a673be54652c483513b16b9a7f46ff574df4de82352127eb2e64d6e3e394efe8cf73bfd73cec0efadd941b3357841cffd939437efe7ec03f5e03508aa575323e8f7632b586a5c40c4551e998dc79007aa4b6c59ed993a0fbfa04ce6d5d89fd0be662d7c45918513208b1ae4188b731868fcc00a53ec6e816a044b1af0a4e129ece4561af7131b5299318be16b17f63ddcba0a0536662a3868af22aedb429cb316cc8740c1d3c0d274f5fa5cf5ebc8dfd073ec2ac595bb0796238c8e7c5209a51f8f4f25c746c5584a92327a21fa3f5bdbb56a24b691f74ef5289eeddaad0afef50540f180b7fcf684c1e5b82bbef97616331075b07b8a2ee930eb873ba0dd68e48c18a413de9d1dd8ae8dee93e0dde6a61f1afe4ecfe2d7eb5e12f68c2ff1fef37aee333aaadade5f7d9bd5b40ae1fb266e2fcef2a6f3e22eb9f9223c1e7ef445aee7c768dcc35b757fff96ab5fd93b4ac3664cfde830d8ccdd4eff3a3673caac782a75a7af4031d5d7c9f409f0b88fbb88ea62e82365a769596cebfa48dbc4c88ffec2d178c7942337fffe867dfc9b4a6dff02aea7fd3fc9d2337e09215a3dd9e10d28ebcd12b78d0f32dab7fc5f5f2a673c6f852d45847b151819fe5b3789d1bd4f8fc38b90145e68ccaac2357fa91114962521d2bd23c5e2cc7d1fec66865c743376f1e792b5b4806464b6ea5b888a7a8c562e7e77b68fe0dda4f35ce8367c7156ab101b9b9a7e8c1b0122fc7269d797ed4ef9bb8dc2ec69494a5a91acc4d5d759dd23db07ea023be7a3310f7360662f71026e68b13a095bb0051b612da452e8293b91ad68c76b8dbd923c4d51e414a2e4a7d8d7078a4a5ee93b9eef51b8678926d43dd975835d6386d1a2f4de32a906964428f806325c90e86cf72deb5f96c4ee0c7fcff33fd2e58107890bc1d799a7c94f680be97431aee76d290ef8612f2752f0df94ffc95939be3ceadda997871d39e94ab67dec9b8b66f5ff2a7c56f869ff8252d307cde07167622b38712be11296f31908e0a0b81546880b2d4224ceb5a81efcfeec4b155b3d127b5053ac5676264876e9857311e8bfa2d45759b51c8f4cb80bf850dbc9462d8880c692145d1eea67624cbbbcd431997ebae94485ee5f9d53446b3980724292258b77df35e2c98bb1653272dc1a103efe1ab3b04bbf79dc3be8397306f427f5c5de1829be7278290f7b16ec9205475ed8ee9a32763cce0b1e8d773307a771f88decc7158f538f42d1f8a9890788c1bd509b839129f2fb0456d2f35c6177b6265276b7cfb7e279007d5d8b5b20586b4cba4fbe4e4921e39a967bc6ccc546271e33db79bcd5dbd6decce1cf57bcf9989e6f96fcaade9b595b12b719ce7e7a3e9deee4dbaab5fc7c7cbafa91195d5d448cb16e9eb62d78c743ef5d5bef4eb0f43a8dd9f78649ebede39e0ec57ad02cede0ecdedd0fdb14a6a4a9247bd5d9fb5f501bc679cc6b0e3b7e9b584a62b1e6ae9f6f7b4f4906f6f63cc6d0d38e73434ffba96e6acff9c16aebf41c75d05eca353d2ad1b7f97a0b4b494f3fcfb5fc51c40d3ef9431ed5694b3b4e1fea5180d213dc9a983633e72101b18d610f2bfac99ff3dffa6a9eeac7ebfd2b620b580ccecee7628c2a671ed012194fede3ddf46da0968f2496cc3981cc144e6f94bf10e42b22c9b8f2e3e7c7a7b271e46a70abff2508afaa9a542d5f3fbd451ffa25c59931dcb9308790d53bb7a68c897e3c8e75bdbbf9be0c4356edcdaffcc197ac7462620e7177a6b4eccf3a3770f73c4e5a98ed85d6185218972647b4ad1353f1393468fc0fe3d7bb166f15238ab1d10e21506574b47f42aed86cfaf7c824deb5763686505623cec511d2bc65b5d4c359f4c7322cb7adad7c8448df515f21b7311fac7ef853b1983dca826879765f750365ab3a6facd2cff8de1cb37c59ef9ea7cc6f7e4878206edbd72edd5bb4375877f18834b377a3cbe72a4c5cd593b122fb53b5378b7ff575d9f1ebddebe8e5cced52cdd1cfbb1fedf3f8b41a8c65a7f4df6b1697d67b9216548c23c43b4f387bf09af04391c0284f0b772c5e77bb7817c71140b7af54265cb36e893d906b94159c8f2cb44717421fae5f4c6f0b6a398e787a128a21b92bd5a20ca311611f6719a5e296348b863c42c81c14ffccb572efff2fc3886690d832a7a6968ed53fac3e3a7b070ee3254f5a9c69a555bb16bd7fbd8b4ed18fe33c1131f8eb3c6fb633c18fd3f85b796e46340f77e58bf6415c60d9d8461fdc7d223193fa0bcac0abd3bb6a7ab7b16e2d87b9340eac7e1c14677acefafc6ae35e5a81d9b8225052678bba3192e6f2d653eeb03dcf962ac6e467504e9981e7fcbddca546f779bff4ebd0f7d4229e291110373c9b881c507ed143c1145a95fd7fd4c426b6b6b5bb94020ff55ff9989f7d3d3d385e1e1e1c2caca4a23c6e6f0f539d049fb",
            "4efb555eb96d67bff6e8f00e371e5e0cba727f9cfd47b7a3db1ebaa0605ecf8e8e887e2a95d9d05663dfa395ab6f41b9fa2bfa8daf1fd37d0841fad235685b350a9e1701ea7a3dadf88ea6f9ef3cd0191e794cf23e7b78c72b38c2da5961c5bb408840ef773c6f2ff3010c5e11dd8865a64243cf4c254dee47a2feabde3a42ae90b2160eedb9cfd7a0fe8e1c80c1afe4ad5e7c6f9316acb1637cf0b5d3dbe81e1fce3a1763a69f9b358dfa6f627d3fd2864fbe7bd398ae4e13ae36159ae4592b2423ac65a23a5ba181f6c1015fb2a083497fc366ba9fffefda37a38ffdf5b6ecacb38509995a64a7595a6c492f2cb2d024388b02b85c91b15249edb6550ac8b6116e9aefdef4c1ba6e7254847190edcc83af85026aa91a51c1317867f721ecd9b003670e1ec4ba3973612191c38e89fd653c090ad35be3fae96338b861e3b3d77bb4ef00138e10a1762a3adb55a49dda52407ac4c83a1bf37fccbb4cb2301192d5154e9ab3eb0be873cb329f768814fb73d91acc2f9907cfecbde258eaf7315f173ef57bd05b23b85e7afd590e8c9097e6f83bdf6b4f93d3590f7236c79ff9b9cf0d71b0b0bec77c3806751ca3ebd3a337ece329b8a719c1c95e81c593de409ba40484dbbba1343e0d3dd38b51145d84bc909648f34e42a2472c3cd5cef0b3f540bc7b2c32fcf3d039a10ac30ae668560e38d090e095b4556068f02a5f0368d27ffd8d14c9ac2993348f1e3da6e7cd984317b4688f94f85618dc77002e5f7b8ad9ff8fbdf7808a6ae9b6853739e71c0489224949928380888280282288084a4604140349c10426145482a08062420115c59c7340c4ec31e7ac18a1bb6b52ff6e94ef9efbbd73efbbef8ef7dfcf73cedb63d4d8dd8c6677efaa5d6bceb9d6aa55b327e2ce6a2df2b0da825c5eae8f93659e38b7d9138599d3c8c1c6662ccb5f86b2e56b11131689f99306e0fad9e52cae37e2cd6fb1d85f624caae70cc4f9b3b3c8e71b0b51182089ed293a684e50c6a37dde78757735cead0944fb2657e44cd0fda62923b4524e88e1fbeed4ed4c75e769c8497d1de1ac4a4fadb3e6743ec9eda29c6334d357b6525cb4876b8bfc853840ef7df451105778a9add1e779a0afdf152b0bebe63e1a7d4b64c4e5f8fbf0f9b3cde2a72ff39f79a72dfb27670f8f21e2ec9c19d1e7d0ad5be9afbf7d19f1e053907fdb13654a3feb3c7ffec1b876cf413e075862aea145fb3807724d8f7711e51defe0739f62d48913285ebd0ebe33d681b9f09e488012f35b1dc4e24e17cfe829a539ef3f3d31b771e863a6a929b9ebd225c98a8a0ab1969662b1e2e262fe9a823f5b2c808feb7cec98c8da645a3451894b8f28e0fbf570fe1e97e4e1d5c56fcd55050c65c564ffab73bcf77e0d54c4187939e63fd50602bfe3152bb4d9f95734ddb98b7e5f4c9f57997f083612edc388f343d98c971423f6d9c742059be65af19e5e4ca0971b5c1eb8f4155d2b2f24cc5b343f9a47af8fea8e1d28602f2cac28541ff2b758dff787fe1616262c4444a4deda2a33e456b50b3d5060df68d0b3e4e147bd84c4c1cadcad714a3d981feae98c82bc3c0cb2b0465f757d1869f4879bb53dd616d76273452dae1d3f8013bb9b90376b1659b16411962d2ac0b6da3adc397b06bb6a6ab1b3ba06a3870e8504238af999f9d8b9752b27c4d38dfa1a4a2cd690fdc7ba911c96a7750ed517e36d8e51c7d6c97a0ffa2b899888feb97dc6ff3fc602eaff23df40cf3c3aea7e54a4c2a6422cc5b758748e69cf678bcefabc5c7678f003490d0dc64a575299ffe847b01debab222969aaa3a8fe5a4e4c94eaaa6bf0d6aed8062b6f0d8c4a93c0a4b99ab0759684a434036543069ac6ec59510446cabaf031f362f13f0881b6fe08b21d0147033be8c8aba3af8226f414d9ffd3b1c144c738ee48b3402a2dc48c5697fe53affdeb7d0677298a0bd2d4d8584e52741a867b8ec4a880f1081c1e8ef8a82958555c8a3db375f074bd19ead3b4c91c2f29643b09a120500a49619e683f7f11479bf760cfd61dc89db988c4bba9e1546e3f2c8d3346436908ae5f2bc2b7ef65c0d7469c9d67460a42e4c9ce740ddc5d6b023c9b448ac76961a416035f4b234c1c1b898cb45c1a1511ffd97e80e51b053121ea692edebd3ab50f37ca59025b9606e0fd9d12cefe04791aeda694f1d3bc0aff1fd8e63fcb981c529457a78bb79ea39fbf7ca50fef3fa0478f9da29b376ea54b172ce2a5c425be0cf60bbce4646dbf555f5b6f014b82f61be9197387780ed9adaaa491a1fda08bb7e1fd573ae3f5d7b146a71f6ab1783660dfebafe6579ebcecdf7ae7a1e1bea367cc1794563dd15254a58e0d97b8a60f2824b6dec0ec65cb71f52985ffb46a089ebc43a48ebc2522796d446ffd6f24f7fd77ba89c77b3fc063483f0b4d4da997944aaf5ab58ae500bb24eaebeb45eb7bea091ce5fb247af1ff97e7bf3fb172bcb8a0245d1dabc0a5eb197c69eed7cde174f028eda07bb7c65ed3111350939252fddf3d67bd7c4749468679e165a678c5555fc6fc777afcdfd6d9fcc0aadefad653d458ec9f1966cca1b402ef4f8d271fd6f5a3293662362272cafcf569ef7ccc24e8c6aa3164f5b14df059edc17dd9ac4ef7a44bd10b4dbe9df4461c6d1a2776c142595298f9fbe6c5f6da5f3b167a3bbd4c24c9781fbbeeb1de4e9f6cb4c435942525fbc988ca500b65616aa3ad4c0a72e66103cb718f36b6c0d7c91bca52b2b033374742643436576ec5ee4ddbd1ba7f373a6e9f03fdf490d5319f593ef816cf6fb4e170d31e6cafaac1aeda0dc89f96027d4d4d2ccbca2387b7edc2a2ecf92fd41514b4257e8e359dc3a8308c74c708131134ccb6a11bf3dc4f7ae80af6fa2bfedff1c7",
            "b1809e7c7e3a87f6623f7f3d3f3ff6f9cf9f156b496931d9e77f75628165c535095186ab2123474d34f4a98d9e39559596fea82821c1bf00c965f9d9945969f09c204cd2964ae2f2dd26dcba7504c9f374e1345694980c1184f97041e8db0a405d5d04862ada3db8cff703381adab1b8af0503961b98b31c31d0229013633389aa4948952b8affe96bd4f5da8b935a0a623465e2244ee4a818840645f6e0ffe880080c1f1685143f631ccfd1c0e22025126f2d4e86992a1007134398eb9bc1dacc1eb3d2b370e5e24572ffe61db265fd2e1236d8026d0b3431c353162b23fae0f1be29ec1c7a82cf378ac8953c79b23a460b8d53d580530eb852eb80105329121b1d87850bcab16a753d5957b3975b5db39f969636d24585659ca9293349f8980418689be3f4fe31787b2e89a4d90bf16a2628d251360a537e0e81e09f1cf7ffd92793c8aa4eda6fd8b4cea5a73bf9f9799c9f797abc3794763f645fdc24ddf454c7675a7df3373a776b23bdfbf4299d537bb44bcecc815ef8d2457fa3b446f9d4231df6a35607df7cb4bcffeac380a71f3e58debe7fdfe4d2d5db36d3a6e5beb0b4b2a3491fb93cc5c38f109ebf1ccf1fbe40eebab398b2bc19ccf47a08963f2102c537c194fd06e3d6cfd84a2902c223bd15c5e424d8eb2a94966e946d69699166319fef0bf8c9017a7211f9f1cf3f43df5bdaeb495d951512277382a409dd26858e350cb84f36a00bfcfebe4a776d18dede575af4f7b9647f745fbd7e7c0fbe2f6d51941ebd7721a26398954284f87ffcdd81a20c83f19e5abcaecf8b08f7f37abcd8624f3e6d1e8092c1426735e5a55e86fb59d1ba540532a1ca0fcbae6e0533ad1f564f93e31e8d11a735632469ae3df3c85a55c24a5759eeefaa297b6bc8f09deeed1a7272d4ccc48bebe191cc1d175640fb6a9a442afe18007eac9667616c4df267ac464c682236ac5c8ba2fc3c942d5e88833b1bb1b3ae118db5f52cfe37e2e9f513f8f6a215df3ede46c7b376d276682fd9cbf282e6baadd85ebd11277634e0ce99c338b16b27cb2376722a16afa651a3c6afd590ed89c188ebeafef84e2549116aa5a7c331d677225eaed1b49f968eadac30f367d68cff93e32af4efb801a5b6ea4a4ae9128c6003ab776eb2ed2ecbb51e4a8b0a503569d9ee596372c9b2d8959c1176fe3c790931aa28254112e29250dfbc1bd6010a246ebe04166ff40497c7018f7030779d359296c8c021440c7af6823076118681a33054f419a8a80a43435e16669a86c4a6af25cf52db9437c4c4ab2bd929995aa99b5e93111690765731fd33c79f057e67cfdaf4d5e5e99498245e6850148bfb9108f61f875181d118e1e58bba28452c1b2187043b710cd4d78595b93bec077a62b0e3700c1b1c0c3f8f2004788f42f1a215a8dfb80b89811678d76045160628226f980c1ac68be2fafea9d85b358e741c7627674b4cd098a1057ade0d35a9bab033b144fde646dcba7907a7cfdd4443d349d4d4ee214d3bcf9296fd6dd8b6fd0459bb761f22467ae353ab17da2a6c10eee54c7cecad78cb02a4e81053f9082911913f9a5302f41fbe2546be2955eecfa4ff7559b3f5d5d0ccb5db7dd56d92bce729ce3eff820e2e070fb81c72b18b4b4e70b8dc3da09c5a42394f596e70f0258f98149c21e6160ee4dc978f9d63df7605071dbb69c6f9f2c5a6f5f10b9b7b2f5ed83e7efbd6f67c6bab3e3b976699ea1ad24143fd797ecd8711b7a814f4eb5744ceadc6b0996b50b9fb0e24635741a8f11344f67de0e97da4d07bd4c91bc1b2909892d2643561097e8c41adb2b25261f7ee937c0e205355552539276e0e3f0ef067ca07dc69a72b4be7c59873869948e2db46597c592f86ef3bb4bb69e743747276b01c209a9eda1bf4dcc14039e00f34e73fe37fa48ca048f7ba89529d942ea11fef8fa4d3c275962a3302fc20823dc3c814eaca481df73696bae16324d61560a3d0fde6f122565fdec5c74b8bf1aaae2fde6e7320f543193a3f4c85ded83e826c8a10477ca238981c35d84ed520ed53c5e9145bb1467911f1380d05051575757586f97b6affdf634495929438757418cb1bec198fb898425ef9f216b8bb463cd751d55497fcb1fff84b2b961bcf4a5f49a644a56151d662d4b21c60e5fc32ac985f8afaca4d38dcb807bf9d3f014a1eb39ae5233bbbdee2c9a5b3a4fde87172f1c0219cdeb307d78fedc795c37b7168fb36ac5bbe062be61673e64ecba7b1a1d1858a1222bdf3d79365021c5d351ddec001fec4d535829b33bd9a0e1d127740595a4690f97ffb08fe57715fd9ddc6269d05a98bec6b480b0b537d6d2deae4309006067a517f3f6faa2e2bcbcb1a974d668ccac2a42113e0d6cf1e839c4cc9caea626cddd904bf38278c4c9746c20a199cb9bebda7a6e9f12bd5882e1045fa4a35241629c1c44d84f4b110421f0b61d80689c3c487819d533f62d7cf8a2ab25cc248459bdaf631a7765a9644515ccc5e4d42e6cfcee17a9f3d3e3b7eaeaf2687b09111bcd10113103c22e287f61f1e85545f3d34c52822df5b125efd55606d31182e56eec4cdce9be506c118e33716e1411118e53b06c13ea3e06ae78b9ad9a6e86871254b8649a02044098fd60f40598c36269a32c80fd6c4a67903513c490bbcc38ec80ed3253eeec1981899d2b3cf50fbb5fb78f8e43dda6e3e47dbadf73872ea371c3a768314afda892553ad406fba63f3147564a76663e5ea1d1c977edadd23cda5b7abca4afeaf7cf1879f95fff7c4e62469f5fa244901fae7f267ee529155a43e85fbb8c3777f41ffca7b08dcfe107bef7fc68b4f9d287cc281f3c5afb03dff85e43fea82cb863b30ad7dc6ede71840e523a3cf29df7a6bc4e7cc47afdeb2fcc2",
            "a1662c745bdfbc7bd7e2d5ab0f1e4b0a963cb6e83fa0bb61c73e72efda8d9e39b1b4b2192635cdf05f7708c76f74c27b460598ed8fa079ed25d589984834073a746939ba536d2bfb4a432d5d297e9e218bf98a67ce9c51d8b87123df07d0e397f3f5f5e5af27fd33e402f29dfa6ffc6c94415f8c23b3220cb1619200e841157cda2086e73526a0ef56a2ab2b97e50053e8b3eb23684ca04ea98280b8e23f71b51fb1841f2eca7c0325397a285d80431f1512f23987d0972eb466a1c5131b7509a4bb89d36333a4e9e3a53274578c68f76f17d358ec7f09f60bf072c350bc6d32c6e34d0e383396e165384b10631106a39d8c71a5cc0d9b6364b93733c4e80a2f91264365c9dfdf87a8e98fb8027fad3bbfdf7fcf47feca38d17b1469c8ca537b9b911c778f78b8b98613afc113e0e9368a673dd0879af5733eaaa1a8a8c5b773b6966e34337d15498c988ca9b199c84b2f44f1bc52d4956f4453ed566c58b9065b4acb585c5f899cf4992471dc44123f2e0a93a3625134bb10eb8bcb505f5e89dd1bb7a2b1763bd6165763def4f99c59c9d97442f0b8193fd7849b88b25c4347bd4fb7a3c3689eab6b1486f924a330bf863b3d6d25b5b3f1abd05656feb3fa27ff27ec1eff900f0c749fc5e2fe53b64ba99989114dcb988cb29a65dcd59b0a39d92529bc89992379d6de46c4dbca0bcb124a30725020223cc2903d763274d455e0384e9b0c9ba68af00215442f1643e156bf1e3b47c045e1161f92582883b41235c416b0f8ef2d44b42d04091ffb3d268ac0da47954c4fc8a07aea7dde498b0a3d901715be212b2cd0ccb6512a127f99fc8d9ffe0bba4a555a885a1a18704258fc0ff20bc7a88089f01f3c041b22154855b832497490c4c07e03e062ed09c7016e24684808c202c2101d128dd0a0099814168bd09171186eab894f57c6e1f2720bb2dc5f1cdbb2f470b3d498a43ac890e841f2081f2881442719b22d8dd5ffd74762fe1447f6bbe29031bd00c949f9983c791e2a2aeaf1eaf5477ce152b4dd7d8fc7ef8045f317e07a5d3fd0362f14449a61d6cce5a82c6fe42c5b5c45f5d5944a35a4fe5dadc01e2e40eb7b2c60654baa54e4be54995e3fc03ff90d7f490ed7bb76254a8c1d1ce7a81ceee45b9478ef7a4524cb1f40b0e83a74a71dc098e3af30ec1e81e1e52ea2d5ce6afff31f60defc9e0c98bc12a993521e685bb8040e1f3ed47447cb8961b1b1934353274f1d70eef2653e27880cf0f3eb3631b2e88e9bb783349d7f83ba1d27bafd8b6bb1879d1fcad57bd176ef0d5e7efe4cc6adaae916351f546e2c24eee5efe13d74a8a575809ba985d7a851a1ead7af5f573f7af4a8eafefd0df2ec592b3d3d7d90f0ef31c9d494bfafa020f3ebeea963c9b6ce49c37568f7e331a4f371060a2639a06d3e037a429d1c4a95c49114717c3fec01bc9cc2a3ef8379f4be3ddd325fef81bdbe4ca8f8bfeda5f7238fffc7b3b56590ae1cbd96cf70796d892cae3f00ef490097bef3a5f7f73b625bbc12e75a9614ef5c8a20eff8dae12cf6bf026b94c0fbf6080fe64ae0d39921b8bfc919edd10c92ad44b0749619f07a02de359a748fd617e21e29d2a6bbe66a2c561512fbbb6b44fea3a6a82dab5da320214c8dfa9872adcc7dd1dfc80143bc2660e8b02c944e7342ce782b5e9f3e1eb45f1fe303ac427839c87a089d33b38a4c8b9b85ccc9b331357e3a268d8d819793272c0cfa21359ae505d16998979e0b070b2ba8caab113d4d43e8a868202f2d07d949d9c84ece86d3005b38593b61e2d8584c8bcfe0ce9f510016ff63d951d1951717bfa7aba14b1d0705f32c2d7c31d8c11dcef68170711a037b5b7fae9dcd083ac0dca54c4b9165f78ce2ffab67f6732d73afdd60f96ba292ac343ff99f5a9819d3ea2debb9afb99f78f5c7d62226c7078ea3d561e02a4a4c3c64a065290a770b472c9cb800a31d0231d6793496c44ec7f2e4a9d03794c1b475e6a83a33026b0e44e3e2bd7af2feeb53b27acf244c59a94ea62d57c5b4d56af04d9482810743ac824589df4c6918b831242b2781b83bdb76b00fd9404d151519252525be3dfbab71b6dfebb2065652502b93fe9cd09193e0ef371189de7dd19ca0425606c9f1822c9579b6969e3c16ff49e09060448d66319f7df6bd1cdd31d842077ede417036e9832b2d23f1fe6c3c8e4c964645b82276ce35469e9f12226ca4c9aa08551c9da5857b55163831df105ba61a2137ca0461a149c8ce2e467ada423239391753a72dc1a62d87b0b9ae199d3c8a53e7da50b7cc07f486339e1e1e8599f15164cd9a3d64fe9c55bc35e54ddd05f94b6f6ac848ca337272ffc8b13a3aa7478c959f98a372ee70a6522ff6f7e65cf76aa45f389ed973f01dbbef8d06b8764fbdf295445fe984fa8eb7902ebb0926713f9845ad50b8cd83c13d2e0c1ff388e13b0ad72e0a930da749cbfe9374eb81eb5f1d3dc7b4faf9057e1a1d3cb6cda06f3f8b5bf76f39346c69307ef3a92bdac7c5bd4b49dd94c4949cc59e23d7e1b1e500fa9f7c81d08a666c6f3ec3ad6eb94d4bd6359e921795d2663983de95478ff4efbc7aa5f7f2e3c7beb76e3dd43d7cfab416abfdb5d7ac59c35f7758a928abd83dd07ce006096131a33fe2f6212121fc3c1ea15f880fd8b28d93e0abd54d7f0b00efc542747676a0614922ae2c912227a60be140c5029c58e8828b1982f8b0d3015d578773e83513faa2418b26f9caaf501293ecd52d7c5f13ffdc3adc5286be2c11e0759e0e46c7d56d78bbc71ebcdb6e84de1d443eecd2c2427b06f39dc4f1eec622bc3bb709cf77cdc2c3d54eb83393c1bbbd0e787fcc1e47c305d19ca6087ac70cefd6c974dfcf13eceaaf2cf17de84059fa629deaa5818a42",
            "aa3ff98b0fdb26b2b893a726205263a6267bc4ddd6f0d20807ad4a2b750969531595bfa2c6ece55ad66cef535d1555aed3a010383b8763a87f26468514635e520868bb3f5e1e8845a0bd2daf9fe968aaa1a80ddb016ec8485b83a021a311322c1463fd42a024290d2d255568286b2231220a7b376e2587366f263312e2313f230b6b1697206edc786cab28c7b635b558382b177a1aba509296c1603b1744048ce3460447515f678f487141c1036a72d2d4dcc89e6361e20aa3be4e3852ec81651943316ae4422426141337d770ae797f57da4745c3ee672ec0df71cdc61f69fe80be9aaa9758564d65c58568767e06e7c1a727e460fb7e4c98e1077d5741980c91807fdc208c4d1d8aa07827588d9087a6aa14e64fcac694c058e48f9bc2eac3a9d853b41abb572dc7202b7d94ac9ddba3fbf96b7a5a5a1790a8f9729830570609acee8f5da40c8b004162e4cd60588e2a06454bc027dc883b6f510295101298a5222bf9cf3ce5af96b7d1cb01640d0d0dafa94a0a50b7416e1c3faf00521222c73d3aad0faf384891da1968513b7367ea31c80391c1e3780911712c671e8c586719d485c920d996c1b9e670705f2cc5e9b91a3893a982da381544792a217ba82c3992a1860bf374707bbd1dca276a60849128069b6883d594c8983a1fd333962163da62f6bc18ab566fc7cc59c59834610632a72e40c9fc1c7c7d960fda918a9aa2686cded8429a1a4f9225056bb17cd15a6e6dd52e9a1e3329f7e75c122b4ee9d9cb36ff74a12e7db8d9c6624fbaea3f6bff9ecf313fea0a0c5716fd257d39fcbdb0f9e74d8a62f288da7c8a33f73bc5e03bdfa150fd1b040bda8848411b048fbd07f31450995d0a97f2ad303d7c0e9a758d58bdb696bf868ddeefa0f4eebb6f74d6ca96567575a381a74e1d35eda2d4f4f2e5eb8b7435b5380e4ede646ac551fcf69207efc59b6057548f6d4d67109cbd8b6b17349bab6be8b87ca0a595ce774a2db76ddb69d9d2d2d2efd9dbb77dd94b1beedcb7cfa0a2a2861f079829ca0853ffc010d2f1ed3baddbb8e5bdb151ffc29fd8a4cbfcae10dd7fc00bfe551ac880fd699f475bc951dea56184737d2448e79d1e5b71bff53836a60ec1811509e8fafa0e27d766614bb8382ee7cae1e3117b1e3da5cda10714e8bc50f9026511897fc42aa535343e4c7094a49ddb14c9d37235dcc964702395c1dda512b8bbae3fae55f8e2c2066f3c3a68838fc74df0629b2a9e5649e2c10a49dc5d2c835b99027855268be628715c63f9c6b555faa8f16279c8544532d54b9af8e848a074944cd718279d37a1c3adbaa744d9d34599ee7473a92f3d732882debd9a4c1fed0fa51be3755e5aaa892b9968cafc77622fbf72ce466fecdc455a98a9d4525423760e493c2b87380cf31d8fcc29e3d15839019f2f8d43c7cd1cbc385bccf7456276840d71b1b4818ca412cc0d2d59dc1f87989068e4a64c8781461fb8d879626cc038848d08467a4c2ce2c745b27a3f05dca797405f5c456d5101522227203e3c12435c3ce1e3321c96c69648191fc7cb4ecea27e6ebefb14c5c5edd5849937ba6a5a3cd3febec4c834184ba24c412f2782f77e25966585227e7c2ac68ccee6d9b9c4135313f739ead2a2ba7f104bfa3be97efe31405e527297aa822ce5d7a1b3b1eecf3dda7a849cf8ed28328bd33182c579337f41f82628217f753afc126cd1cf4704465e0c4cfd047ad6f07959da6167c1521427e460595c26eab2f3403f5cc387c79790323a0031511370e5da659c7a3c1ff9f546089e2a4eecc285e11021464c860b10f320218494eac3c84788cc5b1bdaed3dcce285083b9f8d8d357e65ffe5ff6d0e66aeaf20f2454d5692ba9b28d12db1ea74de48753a4857fab9a69cd84d6d79f1db7d1425bbf455e5685f757512e52887c369ead891a08ad7a726b376f3085e37daa0b55013e7e76961e5045594b1ad755e1f9cced3c4fd7a472c1faf09476d19e2e51e80b8b86c6466972033b318b3661561faf422cccd2f436eee6a64642c45c6f415880a8bc28ba74decb52fe0c6e51a2c9d3b17d76fbe2487f69f2575d57bb0a6783da7ede8beee2539f139e282ffa8b9957c68aa3ce5b485ac685d6ec2fcf407f470b790fafa990ae2820dfd0d0c6e050c1b426332f3df5bda38c9ffa2fe4dfe315a4248883a87c6f0723f7ec5520a5837dc03537c9b08d4bf82e0be5710fa462159bd1b4b0b36e1ecd9761c3e7802ef5ebe45c7db8fe4ee83d75dab0fbdea768a2a3ea1a9a665b26bfbaec9e626e6addaea7de982fcb968697b4c5257edc02b16f32aeb76a27acb21c4ac38c1759fb0945afb24eed4565633397afa2a8bfddb4c4f9c386179b6f56a8d99b159ac91565fcdc76fdfcab1fd9d21272a49fd8705f1ce7ffe4a6efd58a340df3f7f4eb7d4aca79933723a424785dd7273f2d863d8b75f91b4986c34d39307c7a8fc02fdcc2fd87a75809a04bdbfc98e47db87e27b7b2c385feff57080ef8feab063b6173a1eb218f0fd059e5eda8df593cc712c56181dc73c0867a72287ee95a293062b8c126524f8d7e2e707d2ec91d2e4f33a451c0d6570650adb0a5c716f6f053ebe7c011e3dcf5ebb886d53d86b86817e6575eaa720d08f7ec05b6f74de77c1a7a3fdf0628d1c5a8bb459ae60833bb57a38314b092d715278747c309edd5fd9fdf9490ca5afd8ffed18c9a3641c97f21238dfda823aef2ed64343a0c8337b35d17e4a4a327f355ce9cdb1986dad2f4b0d54a5a991a127a20387606b9e356eacb7c1a5f2fed8916f8a05217d113b481151a6023db94bbb5354b0334915a9eecad0919740f88808e424cfc2a490705818f4c7c4d1135194bb102be72dc6b2dc7c34545681dbf110b72eb460effa",
            "32d0cfbfe15dfb71ec585b85b2c2224c9d940a5f171fe265ef8c2991494f0718184d9011642eab286a5123230f5ee060376ccd19840ff566b8b57d02da9b17e0e99171b8dfe8860bd56e5891e6095f8f61544dddf293919ae478637599dfc72fff4ed89faa2825d1a9242b45d99be78d1d1fc8bbf1f626966ecc47ca820424e447206c9635566f9d81e76fee80c3f98ea6c3eb10cbce4beb505158850ac174b8106494184c091e896bf51bb0a360013a9f5dc4bb5bc7d0bcbc10d79a6ab065c1348c1cec8a90182bcc6e3444f66e6db827ab6050a4066c4295894b9232fce6f6816784167765e344aa222fb9555ee26fb55f43ef7d06aa4a8bbe3654117f67aa21b95b514a6c98a8909092a60c23ce1255490d96ab69c98b1c951515a4be16f2bc53b9bad8bfd01a3b968cc6b66c471c5f6c8447b56678546d46da16e9e2de9afe78b2de149f8eb8615b96399cb52430d4672c499f3287d5faf3909db9acc7f79f995582d9ac86cdcf2fc7f419cb9037b712b1135371be81b5714fc2c07b1a8792fc24dcbbff1ce7cedf23a74f5d27d72e5e24677637a1e3f121ae9f93a1d5cfdf1fba2b51b6fb7dfbb8974ff60d555d22d5c30944437e846e72f8b9242b2b2ae89bf7efe8f1b7944e3b4ddb4d6cdd447fd11800ff2ce3e414502f2f2a89fe4e9e64edd7afb06e790e818d0f217bf913a4def320c16215f3ec1d9c33aad078ea2da62ea942e2ea2d082d5c8390ec7564ef1d60c9e643af14e5b5aeda3bb9d029e9d3e9dd5bb7787c8c2b6cbe86ad276ee003fbfa6d472766acbb88612915c439a2a83babe1ed4b63730ff7e92929260f9fbf35b974e9aadf50efa1d47fc4683a337f7e33abf1cbf9d81f1e9b444e7671788dec35b67deec28e8f5d643f8f726e53caff8e9ee37b67177dfdf2156dbb748936d56fa30bf3f2dec48c1f7fdacbd9a5dcc4d82c5e415a415e4eee5fb23e23529211c4dcf0be5c7a7734be9df3c5b7cbe1e8ba39199f8fbae0ecaa7070df3dc4974797405e5fc5bbeb07b06ebc11aecfd544d7bda9847e8dc5d55af32f0315851e8e1ea2f77598bd3a290a96454b2083dda1da7874a0089cce6bbdfe47705e9fc08b0319b8bac2096733f5702c45996d723833531eb74bb4f0f1e840e09537e84b279043ea7852298f1d13c451e220880f27f558be90dd4d2907e83c4448470c38cf23f0e14c20da0a0c78474285ba5b02243f0cd693b6f9d997ff5dece7ef37d4bb46fd57d13dbdd818c52f09b732a12f298e35e06d48d6c5e12c351447aa2279983e2287bbc15c5b1ffa6a86d053d3c7d8a020448df48597a916824cc4b0608834626da560a66f04274b2b58189a63ccf050a4b178be72e17234acadc591eddbf0e8662beeb61d8393912e8c951470a06e253edd398f533bea71a87e2b8ae72d45564a1609f40aa0869a5a67e4c4843ec94bca52bf41d6bcca3823eccd504569841ca2ece531b8af249c35a5e169a082f12e1a280855c5f634459c99af43964519d3e25823ceec500dd73ff087ffd5b1c6564956024a329294d5da9ce4191370f7f32dc4e4056174ca5024158ec2bcf2703c78d6fe63fe800b1eafb3e7f5a67d45b08d148343b408ac591d6fe42d087925219465a6817e63edd9ada3d8909385a5131391e41b8279d1f1d8be600172229211e8e60abf097a7018af8c0163956037411d5e530de039a32f16340491bc55a378628cc027256989e90a7ffe35feff1d4ea62ccd486bfd279feb63a6a9f0594356acdbad9f34b1d71246800183594e226481bb2829182689030b4cc9e77301e4fb59d696dd1e8efb8722106a2685e143023033a300299373487ede0a2c5c50c1eafd95c89f5b86c2c275989559cc728032cccc2ac3bc0447b42fd721b4cd05472b9d505d518ba7cf3ee0e5db4edcbc72031dcf2ff0c8e7ebf4dcbef27386d23d386fb7c59ff972a36e10256fd327ef4beaf1cb8acef9e1f7f7e0c77ae3a2c775b57da35d91e58fbba6d7bfa0a99baeeed25051617e41fc17f887aff387213eac28a140175f6ce3fa7d05942ebd8464491ba46a6f40e5f81328bee5c0a0741bca773cc0fceabdb03f751569ec3cf1d8d08203173ee221abca37ecbf402b8f3c20d73e51deb9279fb1f6e443ec3977131b366c464a5a0e361eb88cf08203f09e5884e8c5677835ac989f5ada72a18f9a966346722a5febd7aa292877cf2fddc179cfbed9d17e8dce6ddc49d680929c4e1e497ddf85f88f04a9df09e67ee7a2ea7b173ef03884122e9f0770bb08e5bcefa2dc7b1f2939f5e03b6db8fc91d65ee8a01ec3c3ea248445a57f975ff33f79d898284b3e506098ee8a747342ef4580df707d2ce88358b497dae37a0b7b87dcb7f8fee81ce8b3d3385b9b8ffd910cb8edd3f1f5f942bc2e53ea9e662f4c4f2f766089ce3256efb96173b433de3ddccddaaa196cbb085ec75ddcda311a8d93655139520255617d5113ef888d6943b13e7930d6c6d8a1d85f136b7d04712c46082feb74c1b9e7cef2000f7cbc390c17ca4dc17b3e8abd16a7bb2787997ec697ab13f16c8d1e4ec7099323a38448eb78a5ce4013590f2929b1ff6e4cb9d72eef3756106de9a724216aca98fe4ab66f30db78292334793796f4e5ad081647988d128c54d4919e300d9babb7e3cee5768c1f39167a2a7d61a0a68783dbb6e0d8ce3d28ca5f06fd3e06509696e9d96bdc508681b3f378c48c9b89c4f044cc9d361bd5c56bb0737d1d4eeedc8ef7f7ce91712e569864cc9019560cbcf454707d7f3d6e1cdbd7c30f2a97aec4bc19f391959c8d21f62e445b56bc3bcdcb88571aa28249f6b218666d868cb8c9a8abaec530cfe14457bd1f8c744db0a1aa1aa54b57217ecc38b81ba96186b70277fd04b9eeeb",
            "4bf59f873828eafe0d30e6f73e8e33caacee67c51727353b0677beb623615e10b41d18f8c699e0e0b98dffe0cddfbe7de8c17f2e8bffb32ba349df910c8c4733c4740c03eb0821384c1484798000242418942f9a8b536bcbb0243a094b264d41c2d0312cef0a44846b3012fdc390111c871923a760bcfb2878da0c82959521ac5d75613e441d23e207c27fb42561f908d55154a11a32f2c172a2a27f273f80e01fe43bfc1e8ff8effb682a887feeab2c41e3ac44c9127f694c7691c5d07e12186d2941325d44906ecba024521bcfae24b1e3b70ed55306c15a5306deae0158535a45d66f68c2ea559b50545483fcbc32945734b0b85f81d9b3576349d116a426c4a22557875c29ea4f5eb75861e1d448b268411576ef3985fb77ee81703eb0baea11975fa32d2fd2835f438d7fe86f0c67b6b6ae30badb56d24f24ae677fc91e2bc8df46edcd8821eedd276ebfe705aeb84f34239a397d271c824dcc86152ad262bf2cfecf993347ccd0d090cf6de64a0908756734357d1fc98280547307476cd33bae50e53330cb6e83a97909664635361dbb8e6b0fbf6040691de4f7df8071f17aec3d710d279f837c66f578ebe34e6c3bfb10eb779dc0ea95a5081f37115a7ef3e037a9044a2a43d1cf2e0c29656790527e193b1ff278ac86a7abf61e7b60ebe4b9465d5ef69b8de7e8ee0b4fb8841d542edbf9dcb7ecdcdccdb626b6ed2714a54fbe22e6e247e277fc037c0ebec3e0231fb0ed4927521b1f916125573178c905b82f3c4742d7dce9ca3dcaa52ec1c945ffc289c51ff8dbf6068a48183d9067afaf80b4e1da38b2c20e77b77be2594b00ee6e70414d843a0e954ec3e3539bf0a16d1b2e6ec8c3d1341174edd6c5fd25b2b8972e4cb25ca4796b070b91b393d4b02bcf115f6e2e023ef8b3dd948297e7f2b07da632eaa69ae058c564dc3bbd05afef9d45c7d3cbe878781a1fef1ec0cbd6ed2c1f1884dd2be250933a04552c87be942e8eaf2cf6533a1b5d1d49787d6126ee37ce477bd918bcda668f3bb90c0e8c152207464991df2629778f33930e969696f8effa917bf94202df479639de924e0bd41ef60bcd093356f7bf723391ed5e1ba5c48b70d0c6c43163a1a1a40f35394d14cd5b81752575b8b0f720a6c54f6675862fc28247e1e0968d58b7ac02b39267b39f5380a1961e2202c3a1afa681d8b875880dcf404ad414e4a66663696e21aa9797e0f49e269cdf5d8f784b693ccb14c297125124598a624f75392eee6bc6daa212644fc9c4ecf46c16e36760ccb09170d793255176eae8afa9064961258c193106352beb70687b3312c68d477f433378d83be1d281169663346063792d74d40da022af8351deeedce841f2b42a42f1ac99a694c45f185b7a7d49d22a2a2acbd4e4a5f9ba9f1b9d1c825b9f2f22768117fa7a32b0099542eb9d233db8dfd5f509df3b3ff4bc7ef9ee01620adc88e158860c4e17c5f643a3b1e3b23e82f218b8c40ac239461003470b4296e5762923235097351f059153901e3811c9c32660824708865abac3a3bf23bc2d5c31c6391091eee118ef1a8e8081c3e06ee88c413a36b0d5b582b3d120ce189b51ddcefaf6e7a54504ff2cf54cff6fe3cf1fc54bf9c7708691a45e0622dcd625fdf1f440186a43245116248b181b49b8ea8963a6bb04721c05b070a834aeed9c8195216a7036548599a113dc077961e386061c3eda8a952bb7a071c751ac59b30373e7ad4165d54e6465adc496fc817852d71f5ff60ec4da59b6488b9d8e82bc1254956f40faa4349c6ad9cdcf6feb7e7cedc8375f5d2103c37fd3f09b0e4d9319b52fb9671a09523a479cd1d5bde938d094aedb779de336f70ecf2aef7ed7c0ccf6ef0332ce53a361d353e5857fc9beffb92fdc9cde752723d9cea7bed979b4ff9a83543e30852a8d9941a552cb89fa8a437059bc192bea1af1e6c37b9cbefd12cbd71ec482b2661454ecc4bd478fc1623f56379ec7e4ac029236351d41e10970995c0a9be50fb1e83e45f0fc8760843782919b0127bf58cc6f7a80a91b7ec3b2c3cf798b8fbfa17165c7a9775c61f78e4baf70fcd213c4cdadc6ea8dbb317ff566acdfda822debb620784b3b64777480697807a6f93d98f5cf607ae03da20e7510e3b287702cbd03ffaa3bc83afc91537e9352b7e0f865bfd39dff8af9c5cf23db6ba126459f9f4fe4723facc29583e938b56d0aae1d6fc4e5adb3b02d3b106dbbcab06b39fbf78d0bf0fcec26ec9a3b1ccfcbc5d0d9a082db59e23818c020409bc13c5b516c0c95c49b73fe785f2d0bfa6d02aeae73c59a716ab8b86d31bebfb8054abe81f23e83fbe106ba5eb782f7e51e785f3fe16a6d280e641ae0e3fd13787d6523f695a662f5283d9c18cfe0537b106bff26e3eb2923b48c62b0dd9bc1e5a9c2d83f46127b4749f11e25a8d1c9d6d2c94ab2ff6ddddffb3fb6ecacf9666fa4c9f9f6380b55090ad345995f263436504444ee9bb98a50b78b890159b6b00a3b6a1be1ede08a4963c358ecaf46cdea3a1cd8be1b2f6f5c42e79bdff0f0ca455c3cb817554b56a3604601220303e1efe68d20af2018eb0f4074f46af87b8d4158402432126762795e01b69695e369db09dc3fbb1725bed284d72c0dfac80425c3c4d176a0813c6b3f4d36ae5a8dd2c52b90c7e27f4c582246fb0441555a02be6ec331dc6338b4e49510133a1e250b4bb1654d2dda8e1fc4a31be7d07ee6044eb6ec46f3c67ad4ac5a0b4f7b7bb85adba079c3565e52d4646aa72ddb62a82826f617c7fe71b222827754a425a994a0106f90bd192e3e3f8449858e30f463d03f8cc18e732b7bf0feebf7b7e8ecfad8f3bafdb7e3f09bae45064c628845a43066d54ae079673c4ebeea8335e704e13049",
            "90b8a70a92412c0718304a0872f28288f31d8dea8c79c80b4bc324af7084380492006b768c060c45b0fd080cb11c0c771327b818d91303656df4d7d08785b6316cfa5ac2cfc297e479ceed8eb58bf9a6202eaeaf2af7b7adaff9477e81035a72a2b439539d4b3b8bf0faf4443427ca625bbc0616b0b81f6a210ebb3ee258c0ce9f059ea2583b5e866c98a483e166aa18d8df090e035c6163ea88d95985b8fddb539cbb740f15950d686c3aca9ef76245de587c3f6e0f7aca1eedb5a624696c08c94ecbc582ec25989e3493cc49cf2205299379cfda0ed1c3d5b34f3bc832bdfb05eaee4e925fb07fdabf8b231bb1268c3b362c0433ea1e72c2565cebf69abe95ea3845520dbd01f79514148d9465447f55fcffb15ef1870fc3d0d4c0f485ba7adf8d5a726a13cd65e4a60c54d368511391a6237c86f33abf7dc18d07ef7839d59749e4dcfd885cb00f934a8e21b9fc0272aacee2d99bef3872f60491d00827a6e35be1dbd485853728ee7fa664e1690e11caed8248ffbb10307d0446ad0cb63e9390517b0523666d4352c921b26ccf4deecd8f943c7cfe153e8beab0fce65d0cdadf8efe89f3b0bcb8016ac17960f6bc82f8052ea4ef7121d6fa1d42acf6773dfb11ae073a31fcc01784edfb4c965de5722a1f506a3f6262e1bf18fb7b8f78bede5d1c6bc4a1df59bbc3f9b7583de5bdc2fe857e2c6edf6071fb3de8bbab7878622b8ee6ab811e62b17f9902cafd057168d970e4270563aab5181e351ae0ed6a517c6db1c5c50a7794855be2e3a3d69f754768379707747d7a8aef6fae80f7f1263a3fbc456bdd14bc3dea87bd334cf1b9e33d781fdaf1e5fe1e5c6a2cc0ca51fab8942a8c6f570781ee55c183356ad81d228e738992680a14e33e99ac46cb872a16ca4bf4948c10b1f93fbfffde5a137d59e07960a2284acf1d5fd049df26d23513981c6961d95f696e8ce1c7f0ecad3d7885b36b5056588a6d2cefdc5ab58dc5d33a6c5d5b8ff6a347413b6eb3e3781ff7ce1e43e3bacdece756b1f83f1fd993b311cfe2b5a395138c74cd10e43f19e302a390939a87354bcbb06dcd5a72bca11ef7ce1dc4f32b4750335a98d027c6ecd84dc4fa08515cddd7486e9c38809db51bd0b06e23ca169721237e0692c6c5c1b88f0e86ba056272443cf2d26660f5c255282928c58e9a4d78d97e9c7d96eee3c5b533b871fc108e343561c3ea1a6c29afc2fa92525232afa87bcac4b4473a6a6a4a7fe1783f7f8e5b4b8a88506d79253ac23680ab222383b53b0b30658d07fa8e6010982b8486b3913fe71ff9c73c3c7975271c1324895118436c6345c8c04902185b2880baab0cf63c64486e9d30b18d63886b9a20719e2c08b7544138270b404d5d1409be617032b2819a9c2cb4584cd23116451f5d29986a1b6088992782ecfce169e6468c557561a8dc07ba0aeab0d0ea07effe9e98ee3a939bed964dfbcaab8d9616fddbe466fc6771c13059119153465a32d4c342013b16bbb25c792eda8bfae0719d35eaa2d491ea2889310324e16722c61bda4f925712288f1d29fa981ba4030b5d1d38590d66f1df1dce365e186c37049baa37e1d9ab6f387df1310e1d6ac78ac21978767924e8351ff0aef92133c69dd5fbd391939e83ac2959c89d92898269334955ce74cedbd6125a3ad97ea9c5bf79cc4cf6652a89cf7167fa34258a0f6998d263bb22d9d63d7be1a26f1567bed3a0d89c2f6a8aca95ace61fae20c4c82928fc92fdfd7bff7fcfba79f62ccd9ef5bd5cbcf875f77b6aefb34d856d1be5a495e9acf94b39f31a1fd141011954cfc80a367e538975c06c960b6c47fe8e87c86b7c8063a74ea17fc02a44ada7f8ed23879d5b5dd8dede4584967188dade4e22e0fa8530b69f21e840c1a8ac83834700da6eddffc73c7cf9f22d8627e5c1a2663f8cdbdfa37fd3716cda7119f6914b0973e21191fc4c61f89e037b2ea0708f03c59df789ebb54e845ee620eadc3714dee772eadf53ea383276e1ef6281ff6abf9ab6a2a2c4372b2d697a77bb278f3e4bc797bb2bf0e5410d38f70af060cb60ec290cc797e7d741bfdec3c97599b855240aecd744459814deb539b17dc3af9f780037ebd4d13a8bc5fe8ddab8bede0da5d1cef8f2f804b81fef820b16ff79846d3c703b3f81f7f9313a1e9cc5e50df1f8f2a61a5d27c6e048aa3a3e7ff90eeea787f8faf418be3f39888bdbe7a3cc5f018f164ba073ab023a37cae050b2245ac60a93c3e192dd2f27abbd09369190651415f9f507f8f9f13d3500ff8b7cbeb74620bf8ec0ddfeca92f478f3541ea59b39d8a34d374d91c8961696fc65e604fb0cf28bebbf74b6f5a2f373aac8dce98bb17af13a5416ad475df9166caeaac3aef53568d9be153b36adefa9e157b26005587cc5ec29b9983426114143c6c1cca01ffcfda6203d693926474ec1c2cc45585f564b1aaad6e1ccae06bcbb71164f2fed232b83147167d740fc763004e5e11ab876b0116dc70ea1be723d8beb75a461cdba9e35043929b97030b780adb923c68f9c8459c9792898b50cd52535d8b7b50137cf1ec4d58b2771e5e4411cdeb2095bd6b0bfb7ac066b97afc1e2ac65dc8cf84c9a1099b4abaf4a4f5949becfefaf8a1fb512024cb7ab895357ac572a4c8cb4485a950b318f61c89ccdea38f7d807dfb9f7c9cd47e770f9ce0eec3e5384791bc6c3354d82c57321e4af3745d8022138c4091087440104670b233857880c98c810fb6401e2982240ec9304c820b6394f17825db410e4c5c4a1a12748cc0218580433b00a1380fd040626c319f41d280623cd3e70d4b785b19a1e0c557460a4aa035b5d56ff9bfb62966b1677817721b554eb37fe675567e1bf31f647f3dde9a3ece569eb322ddee3f311",
            "b876653776978fc3c2246bec5b6086d240598c66b57fa4ad346fe90825eaa0234ea7796bf06ae38d61dd570956fd9df9d84ff81c60a8db088cf40981b39527d65654e3e5db2eac292fc6c3df668172737ad648edd99488f8d0893d71b6d9533249deb45cb2686636ca7366a17dc722deeb6b59748c89c800791111e54b73a43577cce9c7ff9d634fcf513e7f2c5bc964fbe49e3a8d9b2d0cfbd02317cfd3f049c9c7581a67a92a25f2477ea95fd3ff3f670e1ffbc5525252f8fbebc8dcba754bbdbaba5aa3a1a1a1efe6cd4dba870f9f36d85c5373ddc4c49afa84a636e9a8eb54ea6baa773b8ccce28565376341ed4904a7ae407f9b48226f301563727774a3875b7371fa198fc896f288e2494a54bf53229e4421e0ceb6082e4c7d0ad1ce6afcf6475fb1ffe203ac3ff81be6d55dc6e2bad3985f730cd36af660dd813604259783a93b0e350e85f7f32fc8fcdc49323e764171ed0db85c7d87d88f8464bfa79c553ccad9cd1a70afc8e4f9bf10f6f73edbe3954444ba7dcdf9f5f6fd097d1403fa6822e8cd087c393b0617960e44659c359a56cdc0ce45d1b8bd5c1cd8a78ead49d2b8b4d2040d935c71b56e02e88501383659088fb60f424994355eddd88faf0ff782d3d5d9cdedfa8aae0ff7c061b94057c71dd0cec77872e930daca06e0d5cd6cdc5dac8413b314f1fc4e1bbade9cc3e7c787590e7092e5217bb0a3703c1a4304f1a94e095deb25717b893459e62ac8db3b528c560f9139af2022a9f53b1dfffbe748f077393b7cace7fbf97fd4bffa9da6663ff0d1a5bf3a6d3d3e9dc5fe167cba389443b70bd39a64b9e93f6b1cfe2a077f43e4b72e0e01b4a8a089e4651460e6e4d93debf6470f0bc598e1610819160e0b433be86b9aa11f6bc7dd6c3d31da772c82bc47c1cfc39f3d8f81a1b63e264e2a42cac41ca4b2da62ee8c42542c5d4d0ab3f251b57c1536af2ec583d62378fde01aee5fbc80bbe74fe1d9cd36dcbe700c352b566351ce22d42c2f219b5795b2b6291733e273e0e3e88201c6d6880e4962af3bb5272e10393a1aa3d9df34c0d80efd742c30d0c40ee38323d9bf472136221e491312919130839b9198dd1d1f9154a3212b25c0fcf5ea36f7ae63eaa7242ad3a92c218908d768e48415425b5605fd02192c3fac8db60f36247b4b3f32bed880c42c57476ee50032783aabf7d3186297c2607eb31c9e717db0fda1285c9219382531f0cb15c4a47201cc6c1044ce2e2164360863c63621a4d50b607c0583118b19588e1442ff1182300f16e8c17cff7449c414c962f8547138c5cb6240880cb474a4a123a70e03853ed0905686aeb22a4c34f57ace0e9a36d44445cff6c73dd0bf9bffbff77ecd59e3f2c5b9bf1cb95369d6d5797208a174278b214d84927cb4d5fb21d14b9e8c311343bc8324e60ed7a00e7a728f5465449fe8ab48d1be4a62c454cf144e033de130d09d78390d27fe83476218dbbcdcfde1e4e087e48911b87d2c0b2f2fcdc6fd43e9b8d4108f94880856ef67213f2d936d5958949189cafc2c9caacae3f2de54d0da9c41957d0518157a62e0b403d395faacd664d6ddacb0a42f9a1c838e666af07f379f507f18e1eb4d83470615313f6a4bfee3dee6d05f763cffa1fdebebebf9fbe988b3982fbb61c30615f63dbfe6aee6a953ad3a972e5deab777ef5e551656b3eded9cdab4553534f9afed2c2ca8cfa4c5dcdd573a70e0d647183a8c258cd65ab86fa6f8c4cfa5fdce43db7b2ecc9b08e4f771a07cfa2d513efc14526157c0589f8640d875280e9c89c0f1b9985ed58acc2db7115772126373eb1130ad0661b9dbc8b4252d98b56827a4c79740b8f12d91597687c8cebe41d48a6f13f54d0f61def214692cc72865bf2ff7da2d1abfa488e5279105bd3e67fefe00bfd833ee25c5083d30901541849b3a591c6f8ef5b307e3d4faf1b8b8cc065b6787e3c6e9063c3c5687e60c5516eb35d0717d225af72fc0c97c4d947b08e0eb6e13b4cf95c492004972ae7139b8cff6e1d393b32cde3f41e7cb73e0bc65b1fdfd6d70bf3f61e74e277b2d561f166a2160aa0d2a4731684a77c1c787c7f0edf94916ff0fe0dbeb767c7f73138fce5660ddf87eb8572881ef9be5f071ad14560d15c5f9e9e2383e4b12f3c2e53e4579cbb6fbdbc9b6b89acb6e71d4970e335596fadfdd37bf3046b5aa90104d89b0a16f9e14b2d8df86ce37c5f8522fcea5bbe4e8fc108548915f0bff0df8f5b06d589d1d1b359f8c1c320af6e676901593c4e041ee28cc5c8cc5394b113f2e16eb8a8a313b7526624263909b321b61fee1d05252431f153518f6d163f17f118bcd13101d1a8fbc693958945d8086aa4aecde5487b2c262b41eda8d1b670ee3c281dd6cdb834b87f6e2ccee9da82daec0a6f2b5d85e598d82cc05488a4cc1c4d0648c191a00434d5d38583a414b51157eac5d9b9190898cb86918332c04d313d211ec134096ce5988c2590b11e83d0cd2226270b272e81a3f6a221d356cd4420531a1bfa2c6ece5d82b2585186adbd78a93ea9b85e509abe06ee2837e0319bca06e5876581d01cb1984ad14c2d2463732ae48095ed982c467b60871481784ef7c0619bb18a46e1244e42a16eb9b85b1e0a800c96966df57082070b100829608c09f3d475789e2dc7b4f5cfd6e8886478258705008de2902c4c09b8147ac18a20be530a554055e89b21814238741b132d0d0952006fa1ac461ac068c4730884c1c81856593b94603e4286b17125415a4ff8efeffde677199a498088d7793ef5a12ac88dc91ba68ccf7c7930b69e4ddb920b237590e07a76a22dc418617e7a84c7dfa2bce1114149476375591535050d8ad2e2d4c4d7474b88e033ce16e3f040143469140ef100cf51801",
            "4f8f6098597820d95b1e6766a9a236580c3bc68b20dda72f66a56463eed41fd8bf705a16ca73b370ac7236797769295e5ccd7832445b74e88ca192272ecc562c3c18cfdcbcbf6328a5cf130b2f14f42ca311a473e6f8eb298b5ed65694fe7d4a143f99cee9171ecb5eecefd5fe7cce22c1e2be3ccb0154d7af6fd06a6e6eee73e1c285be6d6d6d86adadd74d4e9fbe64bf7efd268fb2b24afebe7e2b8c740de8ecd2262e87c5deb223d7a1a4170ab13482b48627185b7b1fdacd8058ce57304ebf41c4690b18e375602cf6b2b87f8d08a8d480d13e4818d926308c1f02a23391587c00fea9a5189a54ce1b91be99671a381b1223e61239bfd910c8384e98c58fb9cce68f3c81931d8479f285309f3864421797b71620f56fdf77e9180f2866ef69dc4f1fee8f3d017e9d7cda5e8d6cd6474ae493a7651f5e616624b6d72dc0e3bb6c477d6ec1f37d63b16f71189e5dde87af8f4e623bcb057665ea823c5a0efa381bad33e4503154045d0d8ad89722806591eea4f3d15e7cbacf6afff757c17b7f031d0f2ee0d3f35b00b7039d9f9ee3d9e9edd8b3dc0ea53bb330626b3a32030470bf7929789faee10babfbbfbfbdd6cde372c1edfa860f37b6a2b9301c471284f1bd49055fd64ae2489a049ead9404dda70e7ad390d2cb7af4f3012d7ab75c9926bb4acfd79111e3cf5d03b659308c941bc38807f17d782c8fcf5664449bfb29497d0b1b6a480f374d64717f67cffef69cce2be83aa88faf9b24d1b1511d618314ac45fe17b7c2bf749cf879e3eb14c405a8beba06498a484154f038565fdb6284e7484c8d9f8a1989d3b06b5d053e5c3f8396f5b5489f3405f1e10918e6e60b7b4b3718e918a0bfa13522c2e722665c0af2a716b09abe1295456538d6d488fd9bf83184ad38b7b707ef49ebc1bde4128bffad87f7e3cab1a3d8b3a901db2af979fd3b50b1b40c999373ff3ff2de032a8a6ddb1aae6e7256c92039832441828208281915549024124414040105c570404050302082800491a08228228a8a088a113107cc3961ce48774df65fcd39deefde3bbeff7b6ffc615c8fafc658a3ba4bacaeaa5d7bcf39d75e7b2d4407c731fcc20fb2e2a2d06074a331737eb7f1ae581e9f8ab8d9f3b06dc37a3c3ed78edd259bb13c361e8be62ea0dd27b8c340c3800e9f164002bc677e909794301213f897dcdfbfc3f6d38fa9a2355ce99384001fc3ade7d08b3c32901ab80297f6de84b19e02765d1c89c403fc08af6121b359074beb343095e10293d7b3e1c9e079641585bc0e516cbf2a890d675868b82383dd77e491d844d1f18d2c44d5b2e157c8a2ddd2d9f4d8140a25a74760009538fdc21165d728ec78c28fea176cda268c45abda51b4a13b1b13a344312650003651821813c907cb6051f82fb5a767a659d2a6b358b47da41c2ab69471d3ca0388828cf8bd61c282222347fe8fabd3f0336ec3535e42147a72425c231911e84af1c3408a42f868616c8f90a75b62e5511b349cd3b95485381948ed9314fe973143494f5ae4a5bc84c0a0ada935d7d7cd1f939d7d31cd753a1ced7c31da6c2cf2e6a8e370bc3c9ae7c9e170ac2c5d304b995e181d8fd5c9e9c84c5a860c46ff17a7adc4e1924c3c6ecde092ef5b494e94e9d1601dea565f8319b99927f7e3757714032d9bce5edda42b92c0f016d231a4f385fe0de703d5f4f43ecccfcc1b9cb369e72583f13e0e32fcfcd42fd6e7feddf7cfd3ffa2cc5eecf2e597bc797fde3a7cb596f676ad3d7b0eeaecdebd5fed3bf9aefdf163bfd9de9616e3274f9e1cd3d537213dd77b39df18fc8f5a5b0796c6320804bf059fc43a50f34f83ba40408dbf0196722528ed1a5006cd60c73fa1d997084d45bf014be71158f217a0651a83b8dcddb4ffe232c4149da4132a2e10b37193c908db99f4c8e227a0b26e7084ea3e0e2a743d274ae7ae13858fef392308e1b009a143bef50f5c602ed4d56f56fc3fdd9b202fd72f63bf527ed99fd7a2232121f8ce4e5796dc6e5bf48390431cc23dc8211ff7d0a4af009f0ebaa13a520b4daba6a035c31da58106c8b1e747910d855556142eac1b06d2a984b250311caf5a89fe87ade8bbb61ff73a8a7165ef725c698c46cf2617dca84fc2e9ad01d8bf3910d9557371e3ed2328ac1983156114ae542482fe7a1b5f5f5c40ffc727f8fefe017e7ceec397479d38b363291a0225f1a54901dc5d5238bb4a1ca7960dc7f35a0ddccd97a71f664a70ae2f14e286e952cf65f905aa4dd4156f7bd92a7e8e74e1ad6914232b028693f5ab5c48e5462fd2bcc58cf49e67fa0b673b87904743b1095cce7df4771ae34b8d30f7eb6ee5c173392a578ce545f97fb176fab9a54909b0c8683d23ee445b17465707303a219dc1d9cdb87cb809f3fca7216de1425c3cd48c8abccd880d59006f475f4c1ce7057579250405e52031a61021be7318dc0ec2f2854bb0bda81aedbb1b71a47e37f23356339ade0ff36787222a281051b34210151c84b8b050d46ea94043591d5aea76a362730d16cd5b81f9a1295816bb1296fafa30d63187a3b52b7c5cfc1038398819bf56a06dd70e3c3bdf86c2ac3434166d44d5fa3cc4cf8ea1a74e9c027b0bab377a23473a8afdab2fea77d3fe19127c2ca22ba7ce59316d3da29ce3e1a06b87035b0e2027661354f429ac39c3879cd302c8ef50c7ea4ee6f329364aaf0be0c81b215c2742e825c370a95f120dcf29bab4970fdb6ef1a3eabe004a6ff363c31516569d6421a28a4ddb2f6521ff3c0be5b728a41ca4b0a49585b4a37cd84ff3c17b250b5ace2c187851d09a44c12c8005bb056cd8cc65c37a8e007c97582168b923c68549d13afe14e62504a1fe4021d763b62e11a304fce5878bfd4ff301fcbc57",
            "0f5151bec1d18ac3b8ab2c74b1c9c10cc1265a509314c1244d41acf610c7c974cd8123894a83f3c749fd314c5498f5d77ce44fff41f470218a186ba872a6b9fac3db793ac68d990cb771a6d8bd54053de98ad8132d8f43710ad817339c8e0b988ab5cb729191908aacc465d890ba92deb331130f0fad0679b315978e2d46b411455e770512eea358eeb797d92064ffd38775364a05ffebda15cefd216bdab57c98f81f33647998e33f5c4c80b8f8069225d5c7c8bcaa5b44c721cc4af25feff357c37fde750b3b3884f28e4f5151516952909275351a3e5279cb966dd27fc5007abb4df29ae8e9ecacc67c9e36c17ec28f5921e143f17af517dec32938157caad50c07680325550f8115bd106862305ea696d1fc7b4059768272b90dea288796e8e7d2fab768089873c052b801f7992928d8d3837da71e70d7b73e27e3dc67d64b8b4b1c509592222327cce60c2b7a48941667ff501a657a43515ae5a5bc8e29518d882312e72ff52f652e6079f6bacabf1ead64505090a857549440544909ef9efebd36f0af822de6cc4b7b43579222d9b3b5c9e55a2f72afd98f9cd9e284142f05b4952fc6c0dd32bcdc3f0bb78afd1031461215cb3cd0f7681f487f147acb4722c3471ff78f6ec6ce68739c5e638c276db3f0e67e0ee88f85385ea78a9ce27148dbbf08ee6756e2e4d78738fe9879fe09c390b4441937f2cdf0e84a07c8d75e0cbc3b8fcf8f8ee0fdadfdf874b705570fe4a22e6824deef9607b9a8896bb9c3b0c39b1fbdf17ce85dc08ffdbe6c4c92a530ce5477b030dd99dcdc6d45be1e5462ba850848db082ef918c2e8fc0c0ef9143c40481683fb77c0c0fe20afee30f74327fadb74f1b556146f772872fa9bb4c8b2a9b2e1a2d4ffe3f584ff7fb6d3cf31a5528c459199d3123931218b51b26613ceb5342361562026ca5198a92384ba824d682cad64c690747aa6c72c3858b94061981cdc5c1662bcb533fca74e41ceaa95983cd11933bd7dd15cd3803d55f598eee989bd3bb6e1e5839b78f1f2091edcba823b572e61e1dc08860784636f7513eab73520c867265c9d2662fc98b1f074980c0b3d43e8a9e8c2c57e3202a6846351742ab632fca3ab69370a962f86b1181b21ae4e38b6733bf2d33339b1a1f3c97873f3c07ff3b5fe4eda9fb7c999c86bf689b0284cb70ea497fae4c0d9d001138d26c0c9c01ee52b2a10e7930c630b3e1cbc2d84fb90c6ad7e61fa0d91a45ff60f43efabe178dc27072eadc38c69e3f192e8a0f909854dc728249751084ba330798e28a2d7f0a3e4261bf3ebd808dfcac686537c0c0f60635d378bd1fe7cc83bcb8f51d32918fab060348d45f3cc229285f1090c078865c36a2e454f5d6c8cb055ae709ea74e6b4d61d156c152a8aa2ee764edf41f5490113d3a4c58f877f3cffc977e689ecf8db15e4d19d1c195d67adc5d1ed6b830c70b0dbe0e98a9a500533929d8aa303a28507aa03a449104588c48193e241bfe11dfc5facb6ff752594a988cb374a56d473b226eaa26ceae51c1c5d52ab85c64843b65a37074e13024fb5ba36ce3566c599d878d2bb290b32815d5abd37075ef7afc785c04ced706ac7693474f0b0fe35ab9fddff7d01cd236f8e55af09dabab8717dedd6eb1f3e941d74bb7aa2c5acfa6c9b81c5c28c9cbffc78b8de6e52cf2901014cc6510e9ade408f56219a961bf3af60b44454509d6d7d7f388e7555bebb124ffc429da716edc051333ab6a434dbd759a8af2ef2c468ffbea392daa5dcfc0fa86be9e31b976f72ef7c8ddb7283970010a3a3ea0cc4f826dcf60bcd6550886bd8680ff499a526a0135e60c4d8dbb0f6a553fc4ded3d0fbccc10af20dde5904945233e2d28ad0dcd5cbbdd9474848d2fab3d2a292da17eef6e9eed8d3764945419dc86899ef50119570986066a79a53df6ce01f1211ae2724754576a40eb18c98dfa9a2a826bda4a04032bfba5a2c37375728ffe0419e2f835783e19ff1ff578b75911ca1adbd4894621fd61d26dc6aa922f1485990c55914e1cbe0e6b501f4ae1d7cbe3b74704b881e6eedb602f99c85cf375bd1b3790632edd8288e77c7b77b2db87fac18adc9f6680b17416f9a369e6fd04040b01c94b37c10b76715d69c2a47f7b32b48e95a0dd1e30690d86d86acb5cab8bec912b78e6c47efa1527c7c701c5f1eb4e0ddf5ddb8ddb513db0235f16eaf029e942be248303feafd047029560845e329b8ab8a6043f60c7c7bec0e72539343ba8673499716cdedb103f75534381f17e1c7bd40705ea6827cda03f26a1b3ef42cc297f33ef8d63c125f7688e3fd0e392e7d4083b4ad54d9a72d252a35345ff30bce493a5043b53cf2b5466a93c405f90331a189d8909e471fd85686c91626381fc7c6ad1c6154666730bc201f0bc312e0ee30151a8aea186b668a35cb93d0d6b213f72e9d0179f700db36e6434162f8500df379a1711863628a27978f817e7a01e4cb43bcb8d441bfbcd28d352909b4b5a93536ae2e879ff774d8188dc2fdabddb878ea300ab35331c5d10e2ad2b2b01c658780c97390327f29338ead454bed0ee404d9e25e1c8569fa5228c9c9c1d6dc7543f81fe2ed1d2d29c4cffe0df1ffe7fd2c1463b3898ebcea40aa5f36665807c0ddc405eea66e3056328699d228d464e423615a024cb5c5515ccf8703b744b0ae59988e28e083ef4636028bf9b0b09c0f45db15b03841199eee9a08f675c58ac478eca9a982dfd819981a2a80235ff951718d1fab8eb1318fe1010b77b031b7940ddf1c16342653882c1045d22e11e84f63c13c9805db58162624b1e090c8e87fa66dfcd2f490903f855edb6a8cb587f9e0b080c2fce428d49fc81db47153f82a4a09a8aba9fd8fc903f0b3fd364b490810",
            "570d59ce4a5b7da4399920dbc59cceb6376638b632a6aacbc240468c13622ac8cdf5557ba9232f26f76ff3aabccd564942983372b808265b8f446d822a1e946ae356e9281c5fa58186c5bab852668e82b83168a8da8d3d15db515bb019bb366fa2ebd6e7d0c74bb3f1e94e3183f73df4d17561a85fe10eeec045f47f3bc93bc6583d7e7cca2734a79890efabc99316f79c8b6b35a4aba6fea3a6c6bff72df951623c4ef24bd639fb67dfbfa8979717efd81fc2fcc2647b5373ff0546afe5324aaee8f51bb2f2c23562f8473e292c2c25df18bdbdf7fc2b72f8c613fad4b3af5877e02aaedc79808c551be01bbb16fc2a4b40499480a55409966d2f28a3cb608d7d02caff1bcdbe0418132e16102eddc39cff441f81dac4cd58bc6e377dbce73eba1e7dfbaa65603e3d2c28cce0cc856bdad7afdf9d397d7ac0424b23239e0f42f1e6d7af6a352dedc3c9e3c7437c3f293a2975045bd8d46fee5ca9fb848c58b7b55e7c737d87706547070ffff9ff8a6df815e7d2febd5ff37c58cfcc54a5c9c95d7f9033dba3c9b6a4f19cc0b1ea1c573dd1c1359e2350eb2c8ccda32954b853e84ce243536e04be3d3cc4e8f7cbf8fae21c8e6d8ec1de403e5c4ca5e8234114fc83c540c5c9808a9082fc6c5d1836b8417dd968c8ee1c0daac10c2159ca0c9750c4ed03e37072cb743c39bb13ef6f36e2c6e132d44519e15e9e384e8689a26b8e20f2260860f5183e4c365142d7f1d34c3f7806d21f89ef379df062bf1d1e6db7c69575c63899aa8cae44719c5f321c579284712d911f478305d0bd5004dff629e053e3487cdaa30272440bddb92a5f752558f5aa12420f6cb4641cf465c47f395df2578dafd3baea7a2424209913ec1b8182d5f9387f782fe26c55e8817671dc393b06a76ab6d2bc3cbd11fef3a0a5ac81ec254b71f6d0111cdf7f082d754d38bca301cfba8f62d3aa2c38da8c4368b03f962d5e8892c24df8c260ffb73b9d7877e5282eb4b5d077ce7462e7964d981de487597e3360a0a949cf7099821bc70fe3d2d143e83ed286f3875ab1b79c97d7c70a36a676880e8ec7f2b8a568dbd588d68d53411e28236fea70ecdb5a8cea82c28179b3e691991e53b6ca8a09ff8efaffa7ae0ae6e5d21da5a2cbc99cbd81c17d17789879c0ced0129991b3903a2f0ce38dccd159bb0d874a8b61ac6904a3c9fc9852c04260051bae2b28684f6074bb892a82bdbcb035230ded95c57874ac9e79df1fa3a97c33fcac27c32f7038ee107e34335abfb09b8dec136c2c3dc446da0136bcd259f04b97824f061bce8b59b08860b4ff5c36ec92185bcac2f8156c786fa25070dc903e74d70b273e1ae02a11c2bd7e3612d7eaa0a6a99c13956e46c459028172ff33e6007ede9f9ba428dfe078d5119cfcf1c674ad972dcecff3c6fec049583c5a078eca23e8699a72b489ac2499662c4cbc8cc452c485ff2557f2cfbdbda2b8f0e0c8e1a274d7463d9a6eb7c4955253ec8a5541aebb240adc8531639424dc1d3db1bdb402673b4e0ccdc53530fdf068453efde24235d3d6e7f0b2b70a455346a26b4b225e5c6f638edda12f1ece466b793c8388bb30703ff16ad71f9a725f26fdedfd2ebc1839fe3f3a3a78dfc731f6353c622e3d54bffa753f26f57ee778bf201cad7b84e39a5b49bfbcff8c4ed8d8c039d6739b7bfff11bf4de7b3ee4ff7ff0ec3d0e5ffd4427aeaf0725b0182c891ab0f8180e30e63928bbcfa0ac3e83b59b8632e1c0fb723f420b3fc13df628d4823a61e29e80c50587e9b2c377c8fede0f0f4d2c6cac37e46e30ef3cd53daabbfbb2cebda74f5599df303872a453fb50c769bdea2bbdae9e3d0f02c7f5dc77cb7ff14e91f93751c5926689a63565323db76e4995b4f5889634370bfe515f3f84ffd4af9b4f9345fdaf3572bcf5f433f414c4abb52459bbb425f8c36504d853284af0f32871c1c134138a9e67c887a5166cfa4989222eec34c2bebcb9f8fee430bef6ddc28f2f2f802fbdb8b83b8be1b84ea85b3a156d8c4e591e2b0381451a18b67c14449fda838a5706e5a30c915055c806cb63c71a23e0c572bc3b6f8dd3c54e7878ac00570fe4a326da00b7165368f7a5b0d75f183116a230911044cd2265f0d6edf573089e1e4a46f722451c8f1042b927c34bfc15d198e480a36b43d05918838b4d1bd15e9d8f8a00557c6b35c28f0e13708eeae1f35e35d4c78a63ac9a1822a6db92f307e3c8727fedc05f28feef9fb9314f63bc31311843e6842ea3572466a271db2e5c3eb41baba698d0b7f68cc5e5e630fad4ce6aba282b8f0ef20ac2281d5334d674a1645d050ad66c455561358e35eec5d3ee763cb97e1a7d777bf0fdc54d900f0f78351618fbc468ffdbb877b61367186cbfd87e0837cf9cc0bb67f7f1eae1255cef66f0bead0177cf76e078d35e54e557a028a70407ea5ab1283a0e3a23b511179e82d5291938d9d4848e8a18bce8b14751b022dacb37624f651567f1bc64322f28e2b896a22cfb9f78cdefe6ff177730747820caa2489cef226eacd74298ab98607d4c24f37c6f31cffb3aa68f1d073b7d3b1cac284288bb3b182284917a140c5c2898ea6a22256409ea32b6e240de7a1c5c978d63058c1e7c761e076b4a11e9e881f91e11b01d238de61bfc38f35618e7bf08a1f1113f2a98ef7577f970eaa320ce7ed0c2b2fdfcb43dd37fec18bd3f36818d89996cf86e6163de1e7e241fa1b0fbae367dfdc758dcf86e8ab74402ddcf85e8a2937cd8be2f7720afc16750769850e57011e1df1dff7feaf6616a52d47dd5e122836bec8cb935ae5638e0e78413a1eea89e6485a5669af4347559327ea42c51192ef2545d5aa8545e722846f2df6b25ff7c56b1c3f88588aea21067c7624dd485",
            "caa170b214b39741a48302c65bf37202b8c2d6dc16d1b322716cff7e5c39d1890bfb2bc0f97a09f48f2ba80956c73afb61385fb31a679ab760a5cf686c88f5c3ca003b3a63963add9922fa26587f284798066366d49ff5586319cb11a2a8b261c2ac3c662f272ff60f6df72b732f1e915acad8e7d9216183afdfbea30980b0db3fa078898b61bd5ce86795e1eec5ab88ad3888e4933d70e9bc0ecdb9d9d85e73101b9b7a11957f0a0b6bef607ad23a08884e0525d50996f855b0d49e83ed40c0378f86e8a5017a58e4575a5cf71bc307080ca714a1aaaa06e5dbf7617dcd717ad3ee1e149d7bf3c37a92cf744fa749fa1d873aec5252968da9aede69dcd6d96970e1c235cdabb76f8f2eb8f9c86fe2a5678b2d7bfb76453ffdf038e1d9c723c59fbecf58f6eca3b84347c7b0870f1f8ae51ebecc9bcbe0ff53fbff2dc73a438a1a71cd5a911a6cc9d1a49faf91458e0585a3317cf8b8430d970e4cc0deec207c7dd88caf2f2f0ef2f2fd0df47f05dddf8781b7d7810f57d1ba79218e45f141275c017c35e6a0de3bc362b91a56329abe3088853a1f167a98f3dd5cc08fcba9c37071ad24aac3e5b0276b0e9a6214d111218cf6f5b1b8dd36058fdb3471a14113653328dcda1b8a6f5db37136924277bc108aa649a13527046fce546180192bf1e11ec8c06bf43d388f1dc913f1ac4e075f8e18e051a512bad264b1394c1f5b5684e0deb91c90fe5a9a5cf6edf73116d6a528895fb16f8c668c78b947d08be3d6212b652d7697d7e10283d1178e1fc3f9c3c770f9e811349496d12be253692f076f186a9ba0b4603fb6e49661cbba4a6cdd58853d0c673877a09917e38f73ad2d78d17d04f4735e7de60ff8fcfa010e566dc5dae5ab51b9a90827f637e3cce123e868da838e3d7b71a2f900ae9e38863ba7db70a4610f4a376ec7e6dc7294e5d722645a2078eb9d97c7a563edb22c345556a0e7d01e5c3cb4171719ce70b9ad117b2ab6d1c9b1a9242132f1b985ae2e2f671345fdbe35e6cf8bf1f11103459e0f602dacb54c90326d326ab396233b3c14ce46a3e062e28489fa8e98686d89d2b5c9b0d4d3c71c4f1fec5f578cf29525581e3a0fabe744a176d552bcb87d1ccfaf7562855f30127d429873c5c0544b0fc611143c33f9907740903eff5a04ef8928be1371c6a470f1131fca6fb3e83f4eb010bf9f0fb14d8cb66f65d1cb8eb39071820f053d6cf47c55461fd1c6572243efeb11a147f9f2d37feca770f0f25c6ef5f124a26b207e5f824f5058cd41ed776eab9f7ea86a19494132534f999364a18db610179c0ef34483b71dd6da1a72033464e0afa3f452474662d208313ec911ff677fea54a6e3762a31fa5f4f4585ab20ca8f1c1f19ec99af8c207b55d88d718607a3fd278d9f046f670f9ab796d7cdde05151b36e0c30b5e2df637389aed8154430aeb8347d36be7b82033cc0d174fec1bfab7c7978ec0cd68249dbd680ec94c9c4366784cfae2e3e932181ae84f9626c693bcd559a46c730169aadf4d7233b36e4b8b098dfb378efaab8d6fbc7c2ea7f5740d4943ed4ec261743f4fcfefe81b80e2352e949e01e69b6bd17bb917c9057ba1bea10e96b73f43a1ed12b6eceaa03377de865f5a33a62757c36761298233db11cfe81e61f140b014be835220a0ccce4320f913cd17c05b0bc098e317500e0db09a9288c33daf70e1fec7211fc227d074f3ad3ee2b724e7b6ae9ec185c93366beb3b79f18e23565064fe31bb41c39a2dfdcd1a175f0e449a5c7274fca7fd9b74fa6b6a3c763d4c5172f029f7d263708292d7ef34552fbe01df18eebd779fa9f37ffcfa881bf05fef3da83fdd7a5260a535298ed28409e9c4b61dae32c7839303ab67aa367391f3e54cae151f774d4ae70c7bbeb35f8fca80d5c0e175c2e630c73fbf1e939be3f3f8937f74fa23d45076ef38683ea1a0bbd1243b4f8b3b023441dfb977b61775a104afd6499efb2a89b6785c625dee8cc0f475346004a66aae1e165deef5e06796c0fd23b0ae495115e1fd7c4ee05d2f8502381a79b46a07eb6388ee5cf05a7772f3e3f38854f0fce32d7739ee121cf716e5f318aa68f40478e350ee74cc189ad4b70a5bd19efdff074ef259037551c72cd7ff0cc7ab573dac3c4d8d41fbfdc3a0d86db0bd5323c7e30347805373e2a0d49f39633dabb00bbcbb6e3e89e46b4ef6d64c68e426cc95a87b901d1b493f54418eb5ba2aab41d59a9b9589bb6091505d5a829a9c3d1bdfb195c3f8c9e634771bbeb28c321f6625be14664af48c78e6d9538d576081bd2b391be68393665adc5f1e6bde866febeada109077734a2b3691fb615d562d39a72ac5f5d82cac20604fb0640575517617ed1981b12834d19abb1bda0688847b454d760674919b6e66dc282884588999dc09d307a344fa3888ca446b27f235cf9791fd20c837c292f29429495297a92b12bdccd5d30d5420ff3273ac0d5cc04baf28a88700e82e7e8f1f0b6b6c6be0df9a8cdccc4b6d42c84bb4ec7d43193106ae783d581c9285d908715c189889932036bc2e7203d28124b67ccc334cba93070a5e0b49205f3488ab68d67213c4f00652d62b8765f1934578bc17529dcee17c5a9f78268eb13c4c1178238f24610673e0be166bf087a3f89a1e59200e6e6b1694d5716ad329e0ff3cb29ecb9668bfd57d2689b892368514ad056494ee2778d01f889fdb34445d9c45d4b81d3e069831297315835d114e7a23c51ea684e47eb2b72837495076d54e5dc4545f9fe19ebff77ba3f6db8081fb11f6d4ec2a607d3b1b3e6d12ee31ca1262d066315494cb076c24c371f7838b8c1d7d91d3ece1e701def06e7711e98ed30164f0f2dc5db9b3be85566149d389a9f5ee96f897a86975fbe",
            "7406af5edc65c6ace7d85dbc1e81deeef4c53397e863fb3bb9ed2dc7c8a9a3a770b1ab9b7be648d78f13cd2d3f0eed6ae2346cd9fca3fbf85972e460fb8f7116a353fef2b9fd2a7deea70f909770f58496ba2eb971f5c68fd70cf6977f1a40ef370e6c9e02eaefb918bda9024db50750ded28b65c5c7b0a1f614e2abdb5172a0135b8e3cc1e4e46a5ad72e9ad67658085da72498f9662269db2d6ca8280725b500e2fa07b062d92a8879d6804af904d68422184f4cc0d2accdd8b2e338f69e7f4d276ebb862dfbafa2efdb0f3c6378c09d7e061d5e7f210f0608098a4d4fd460f39b854e091c79f0ca95617fad49fcb957aebffd4482f49ed4a35a1f5c73baff91741292ea7aff2def1e45124e3ff9bbe0ffcfbec0f31655ab8888928204319abc0ee2d532c640ff0f7cbbd386a3191e389d258e8f45c2f8d21b89ba0c17f41ec8c6871b75436bf7c08baffffe1efdafaf31587c089f5f5cc499342b4424f281bdca00b581fc74f5dcd1b8dd5189af8f4e6080e10877db2b70ef4439de5fabc3a7dbfbf1fed611542df6c6d91d6ecce9b6e2ceeec9a89b228d6dd347e2d9be91f8d42e8d8604457c6bd1c093cde2a808d1c2ab8ecdf8fef0e420f9701be4fb7310bcc3dba737197e310df7f6fa6160e023b83feb1c0cd53a788aef8f4af1a5db7f803ee548c227280549fee922fb55e2ff7931bc3ce7eb4d07135932d15c993b6d6a22a3b5a3302f3409b545553852bf07c7f735a375e76e94ad63f07f4d216267c5c3db71ca50cebf195323e1c48c2b4be256a2a67807eacb6be89d25e5485b9c8e8899d198ee1588c069a1a8dab40edc77bdcc73f90af2ed356e9c3c8ecb1d6d43f98443a7cf4241d61aecddb603871bf6a1b1b21e959b6b50bca10a99a90c362dca819fd734a829a8d3b3fd63b174c10ae6da2a70b06e172af38b50bba50cd59bb70ec52b4405c733bf3b8f3bced486788e91ce375491fa9d7ccbffc81d272620c69595104642b12054d50460a7390e36ba867030d08081a2221c0dc6610583e196ea069837d90d39e1b1f019e3037b83317035193f54bb37c5271a75898538b6be09abfc12e06d36113e3693b032201cc9be5158e4b310fa5a4ab05b4cd1f6c96cda3296451b4650308ba5306129c3050a04b16aa708f29a29941e6561db514194b709627d932096560920ae941fa1456c4c2e60417f068bd663f05fdb9b8df96514b6746aa2e55a06c723589e199c0583e4a47fcb18809fed652426467dd69115e32eb2d0e52eb735409e8b057c751491626740afb6d5e70469c9132f5d95adf292823ffde8acff1beec72bcbfb457ba422b293570dac5d92851589cb91ba2061c8cfa328c686c60821385b98227e9a3752fcbc11e4ea89d9ee5ed838672abad2ece90a3f61ec4eb0a0975909d1c1ba14e2e6cdc5ac8c465807af87d9e46528aba8c79a8c6c64acccc6d5d3577164cf7e86cb1fa28f37efc7feda06349455d33b8a2be98a6553f1ec4619dab706701a4b0bf1f2f95b9299bab8584280fa15b8dccf794dded5ec579056265d1d27077e30e3f2c64fdfd0cca1b1aa9f86c6bd2f90d971198afeaba118590cb1d9f9908d2983f2ac7ca4151fc5b13ba0932a7bb846decbe9b173cb389ecb0f709d131a1198790421992dd871e2398a19edd176b805affa09ec83b3a0e33c170b736ab0f1c03de4ecba8129b1e5f4b4f80d482939cabcfb97905b7f1dc9eb6ab1b4640f7755d95eeeb6d65eda3122f3bbbcdbb40f6e61730e5a8d1a9da1262d1f2bc92f3647801248d2d3d2d18d4cfc4361edc33e11429e3853cdf738f11f7f3c59fbf19b0255798e9f7474f03b7474fceaf8fff3fdd561acdb5a478274d6eb0f902f13e8ef0f0bf1a229015792b5d1359542e3580a87d294f0683985770daee86c8cc1be358178d5b3059f1e77e1ebcbabe87f7393c1ffebf8fef4082ed467e276d30c1c3a1e8d2dd1c2d817228deb47b660e0d5697cb87f0cefef1e61f4fa51bcef6dc6cbeeed7873f3282eb794a334da10dfda55f0fac404545850685e6489e73797626fbc2cea1738e2766b1cc86119dcdc208e86a44978d5558a5315a9385ab2085ddb96e1c8e668ec4d1e8d073bec40df8a46fffd751878771c3fde76a2ff590dbedf588cef3d3e3fc84d5fb269aee12e0541a19fdcf857da78f588c99a30cd81d67c7b5818b922327011562d593754fb67c7d69d38b8731f7695ed42614e317218ad3f372806939da74169840c02183c0ef29d87bcf40d385cbf97c717e8fae272388df5c19c9039b8d6b90faf7acfe1686303fdf14e371ab6d76165e22a546ddc8c5ba7da515db4152ddbb76177e916cc9c1c88590c66e5676dc4f6cd15a8d95283cc25ab616d6207357985a15cbf013e73198d9f3ce46fd85e548392bc62ecdd5e8ffa8a5ad496d421252e13932786729d2dcd71b3cae2d9444329b1df084f7ee2a3a728254a549544b839070460ecccc2087161d868dac2c5cc112ec68e88700a42cad4d9305052c1dae885489911036793713094d386898a269c468d4146f062d4a79663dbc202cc759c095f2b37b89b3ac1833907afbeeff29909f01d3385d13b2cda354b00e3e2d9b46d029b76cb61c3238f458f5b41617c3ad35fcfd96363bb3ccce650d09ec18251080b53f359985dc746443d1b312d6c8c9bcbcb15cca24705b3b0b086a297ed1c41379c5f3ee817a3f456881254d5341cfe2bc68dffbfc61fc678cbe1afa88d102511a3d438d97646748d8f1d4eccf344998735dc5464b8a1ba4a0831d67ca22923319cfad718ffff5ddbf382d789a7e304ceb68212860b2f4488cf54581a9b434dcf064aa35c21ad6408098a82828828fcc759226fb62776267aa374b60e3d538ba223",
            "ed0de94c774d3a729420eda82d8d80a5a5082eee85d7da6b98b4f903349d6220ad624ecf084ba52b0bb7a2b7e724faee75a3f7ec21b437d6a2ae680baab654d3f9f3ace88b85e319ada68be4c049dcab3d7706ca366e20638d8ddc24f9f8fed3cffecf9c3884da2925214df6ed3b38c0d364e7bf7ec715d0b8f8a11f66fb1e4378532fa8c27ba076be01b597b1fa57a01afb409dfa4ecb2dada41b2e7e62f07b3d51d0b4a3b58c1d899577ece08cdc937458c965ecbcfe03c159cdb8fdfcdb90decb3f7007495bcf60ee9a56cc293c89d055cdf05c580dcfa49db481fb1fb4dad8f9981c578035adcf307335c3b74eddc0b4fbcf115471180bd73713fe9a9b64fc6b42e2ee3e2119cd0748766905d9585c3e68603ad6c4dcdc5caa8710f1fa8e8e00bb9bafb99706686ed2ebafc602077affccfff76be3ffcff7d94d4148e865d41479f2b6dbec1bb96631f0b14497f32841887bd18fa24f4e61e1a88f20ddeec1c6ceb011b8b38ec1f1f9c2787d2d17a54b3c7169ef0a06bfcbd077a112ef6e34e033a3edbf3f6dc7c9d2683cad33c6d7ae39e82f15437db838a3fdabf0ed6907deded98fb7770fe3eded0b787fef015e5e3d8ec75d95a85e128cd2e902f8b24b0ed73295e8020b166ee4ab83bcb3c2b7abe3f0f9f602906b662017d4513b4f12e74a12413f3d890fb73a70b5752bead303501969881be5f618b81905dc8f016e8783737d167e5c0bc28f2b33806b33b89c33bea42052ffb486a488c4583de95f6d8ce35dcb4e3d4589c163abb439cfebc7a228dd0b6e632760d6b439889bb30cc931695812bf02e17eb31038652656c4af4264c07c4cb2f386a6b23ae216acc14cef0894e597a37d4f0b5aeb5be82d6b8b306b7a282e751ea3bfdcee06e7e50dac4c4947d094303859bac05cc71c2eb61e88f48b425a62321ef61cc7dd331d68ddb90b5326f9a338b7087bb6d56377653d8ad66e618e05434b591516063698e11586f9618b18beb199e1297330dd6d2ae22362b1383a112973e3e0e7361d333d1c71aed693fba1de942c992ae7f61bfa92195d204a46190b7356ed61c3cc938d85a56c8c541484ffd869581b9988d4691108b277c318dd51c89abd1c010e3ed090528599b90482a659a1727e3ea3fd0bb033b914cb7ce7c3cfc603532c5d31cdc613deccdedb6222623cc2b0c42f01a354f5a0644bc12e993717c0a67df2d9f4acad0caeefe0c35206dbbb5feaa3feb61456309f79b582c62f6123ae898da56d6c2432c796b4b269bb792cda3c9485d1e12c2c69a0e888f582dcaa33e183fe0b947a05287ea105f9dabfd3fcff3fe7d4a891951024734d35064a9d476387972d7d36ca0387663aa3788219c2f595075c54e5888daadc0c7111beff930fe4e7f98285d9d4e0445b9b81b8b068cc709f0c25edb1b494e57cc8d82781cf6a19bca707a0bd652de6458c83ad068549ba527053e3c368690af9ab13e96f6f1bd1ffe53c9d143c19b6d6e3b0f2d817786e7943fb54039356b54141cb144ea97b6118db0965fb4498bbc5c1d63306962e9130778e849a65107c7cc2b12a69111d6ea7025f4b35941596635d56de0f6f47cf417f4fdfaae12282ff69ece77d2ee5e71321dbb7ef1cf8d327cb0123d17999d9e07b9cc1faad4fc0c7e03d7b6f1fd80dcfc02ab90d56ed43aef84b42cb7c2444ad7c1fd97de621c7dad1eb0f6d3939ef88e0d9ebf49495397a633c1056719daebf3380d939fbf0faed3b706882d4ed5710957f1c134237d0111b3ae8a84da70762ca6fd1a17967c9f839951ca7d83a5acf3909cb6b4f21bfb917f285bb207ff611c65435a3b0fc302d90be8f4b757ee3883f26038e840c7432d75cf3943c19663159638695aae41d420429c31937b35e7e215b39649b7cf7f37fe0eb1fe48f5f15ffffe1b71213a330465d8254a72891edb3869162270152e7ce4f8e4c172557670fc7cb1839fa55ac1c6ecd16c712737eb4af57c1c3140a7d3b1d70e57826ca163aa3f7700efaae329af2c236bcec29c3e7bb4db8b46f03bad304f1b6500887e7b0d0b4ca0f1f6fef6774fe6e06fb4fe0e3c397f8f4e8333e3efe8cbeeb6770a27c05b62c30427b9238de954ae26196389d69c587eac96cbcd9ae025c3107e935c7c74b5ed8b1480bdba2c7e2f3f94a0c3c3c01f2e62608e735f32e7dc7f5cebda88dd2c199f5b6e82e72c2dd462fbcea08c08793417875681addb1d68684dacad72b8a0849eb2bfd92f39bbc2a9ff7ad342506dbd3b5b9b7b618839cf5c0c7bba938d49080b2555350b2722aaad6bae26c5322a65b2b22c82712a1d3a26067e104431d2324c4e7c2cf2314a51bca7060c73eb435b632d8bc067b2acad173f438783ec394d8e5186bec001d2575682bab414546011a0a2acc678da17aa5eb57640fcdf99f6a398cdc95d9c84bdb80c66d8d433e87e2756598e13907c6da4630d234c654b710c486273363db52f8db2ae2e6e1d538dcb40c0d5b13d15cbf05d7bbd218de16447fda6fcd3d92aacef53291b2e2e7e7ffddf03f4d8425420cf4450696d7f1c1661a3f763e646341211ba2020298686c83f294e53055d346f8a400a4fac5c396e15c2a32d2a8382384c27c0324bb2f4471f89aa1398208c769087698023f3b4f4cb57267f4ff448cd7b786dfb8c98864b857b2df7c844f9e8c3176ea183b4b10e1557c88a967219ee11e89fbd828bc40a1e20a8594fd7c70c966d3aed96c2435b190d3c1a6b33ad9c86a67d3ce8b59b4550c0b36312c3afd00454f59228aaa0b2e1cb78011448c1239282d29cccb6bffbbc46afc04bf39e2e24264869ed2c0f64996a8f7b6c7e9700f7406bbd2e54ea3113f4a75c04f438e58290daf901117fcafe63f7eb6fd7c213645dcec",
            "c60f2c9e9b8810df00488e8e84acc352088d4d87c3f478bcbb9a07f268059e348d43ea5c471466ba617b410cbacfec06e95b87c68d33d075b20e177a0e4247438f0ecaac4142673f3c57ee828e8d3b3cf3cec2a5e4076db7e6156d9bfd821e95721dba0bbaa1b7e03cf462ce4323f60a34c7cd41c5c642ecaad987832d9dd85955477b4ff4e28607cca5f5d5d4c7fe025a730dafaec9f692921fbc357eafdf7d425b6f1fd2db1ec1b1fa0ee40fbe84787b1f58bb9e82aa7d04aae22104f6bfe22a3d7c47e417af24f256135e8e54d17f6f31c6f1a1b696914d6575a3c985abb7f49873ad37d1d41a749fb38abbbce51eea0e770f69ffb2ba76baa0f529bce2abe01a5f4927373ec1f4ec4e32734915319d10fc4559c382e85b4d86454001166d6a44ef072e76ec3f87ad4de7905e73083d579f61c29a3da0ba3f43fcce77daeaf30f6edec7efc468f7abf7c32cbc74ddc78c11203d3d13e43bee5eb6befad25db4eba900454585f9bdfc6aa772e6fe9fef4e7dfdafdc27042c286ab6a1ace84a194a30599c12fc436e98f83ae561e2f58672e2b7c68d14c1343d51b2c671048add86a1cc9985ca60093caf55c0c36514c8c3241ca95b88edc9de78d85d8d770fcee0c5c51d7873b506370e17e27ca6227a57b1b17da123dedd68626c3783ff6718ec7f8fafcfbfe0cbcb2ff8fae419eeb715607b46185e9c9a85439182b8bf61384df6cae07882188275f8b19ce1019b3c255112a08a0c1775b4aef2c797ee723c6d2f44477102ae1f2947576d2ef66505e2709a25be5c4800fdf5381e9f2f47e7e600ba7c810d9deca6c675d71bf15d5f5a2c6ab880d0bff3a05f6dcb16131022537585396ba6caa0316d0cfaaee5807c2f02b93e15e4982dc88d79b851688f99e682b034b683c7f8290c161bc1d2d4160ba33319fd1f8ef51945a82fafa7ab8b6a9091923694cbf7da8913880b4f60f4be0d83f723a1a5a8893186b650916674a8ae0dad3d52175a0c27b032b243e9ba4dccdf7761f5f25ce42c5f87a6ea26d46ddd858dab4b30734a34ac4daca1a3a2837163dc690fc799b4a5c9043ac5550257b30d8027db983e788bb107f87679210e648ce66cf41d41661a08e589b2847ea779e59f18903b424484c849880ec46ee0a35de6f2a1b697c1dc2a36d4ad599091e68782d808f8d84d40e5e23444bbcf84beac36c69829a17d801f7d440ad90759889832098ba78461dec45004580662f2287f8cd7b3c578631338ea8f83d3281b14c425e3564b15e8a7a7302f2802daa329e45ee2477a273f96b6f20de17fca413e2c39c446f46e1616b4b0e904e6f89a136ce476b0b1fe38631d2c4c4c61d1b6f16cb8a4f121633f05ef4479ecbeeb00bdd1fc03a67266c442c5304190cdfee77bfcbbeafe9fb5262d2851812f964ac3b999b64674f67853147adba0d4c716f90cf66759e97182b5e4c8646dc59bead26212d2d2d47fc57d7ebec3f5b2124224d467e640dde66284ce8a86e8e818487a6d87dd9c12bc6e9f87073b3cb02cda031ace2918e15989b969eb99bed102fa5e3af29707232b6705c2d2b7a3e5da733a2caf19ba2656503575809a81359634ddc7a44a02fbf5cf187b8eb1ab1f60cc8a5bb05e7517a68baec124f91694829ab074d906743431b8d5d58d978fee2164da4cceec8079c4799c73a1308bfa4ff5b99fd8bf5241468164e76fc5b92f6470d585aff069ff46db1c1ce09ab5118ef9693230e61219b0fc4e386a8470477c20f48817df38e60c906bf8851c51a204a67b3ab9d965e46c745eb134dd333727d7faf0e163c6f7ef3f317cf1f6c7e4c9ae93bf0c57d01eccdbd931b48620717323ccc356d2adbddfe09a5045bb2caa266e49a55c552dcbbd2ab2ca11360646f6d19191397a4a3290d1b4a70b1b3a70f4c67bda3f79276d3b3b97f65b528598f52d084f2c85586b176dc6f095a95f0668f51bdfb9f617c9a055f8120f893fe31867cbb65e1f2972f08e90f682fcd3d59f7f90a4f70306235a6ef3e2b8d8d4df77ad332f06cd544040f49aacb8c860f50c21cecb240a5d0912682fd401b939063f9e8f65dee18d38521d8c8a8449b8d9568847e776e2f1a9ade86ddbc268f911a88fd1c183ae0abcbe5c8337b7cea1ff030dee00014d73413e3fc4f33385682d5a86a7974bd1b755193df17ca89f2d82fe5625865f68625bcc30180e134353ca585cdfe281bd8b2c7169473a3ede3802f2f63a1a57cf41ae9b187a365ae0519d2d7e5c8e60b0ff1838dcde3ff1a7bf0bfd7d4ddc8f0fb7712eb62612176385a96a5222acbfb8cfaf3a5ef196193dd59715469abd2837d55a10b34ca490e53b0a0d719a78d793819b7b12d0182404273d5178bbf822257a31ec468f8595a935c266c6319a3c100b221391bd341d1b337390ca6046cfb10eb4efd937e4cfd764305e5351871ecf687d5e6df29c453e70b31947db5b7a32bc400bda8a1ac85a948ef3ed5dd8b4ba00c9312bb0adb016a51bab909eb26e08ff9d6c5ca1a9a08c292e3e8899bd00fa1aa648711f81f605c3d15de48513a509489f2403bf31aadc786b51523859f2a6a19ca818f567ce09d66f86ff61f25242449225c2991cc10f774657efbccd467c299b6694170c26b221a7c682b69c229c99b13dd26526a6da4c84998a1e5297d9a0fcb402aa1e492129d601291e310861302974be1a6253e591d1244007cfd580a5822526188fc632bf30ac0c9f0b7b63b3214e6163ad0ed7080af1db29145ea5507e8f8dcd37d8c8bbc88fdc0b0cee9fe6c38673fca8b8cc4f97f4b051789a8dfc2e361c9732f89fc4c68a561efeb3317da936a6cf5185949008d7dbd413c60a7aee7cd47f0c37febff4730ecd73f2fa94ae9418593c5a87b36e82",
            "09bdc9653476f98fa3373899d251062369a79123b8ee6a721c4379a9b112c2fcffd57dff3c37ef7d7ea2a7a64cb66d2ce41e6fdc0567ef39909c71180eb13b70b9d411e569d33136b202ca73ce4233a801260967e19f5e8f374799765c9684a8f47c7437cfc7c4d44308aeea83cfb67ec4b67c822dc311f9c4751198b205898740db6f7805e72daf312ef729ecf39ed116e98f60b2ec3ed4622ec03e680d0e3734a1e3e051bc79fe04b9ab72b901536723c027f4b1b484d830294aea3f91d3f9e7ef4d1c2125f54c5d59f3e9c480b8f71aae51fd5a93e3613a6b25b19a97436c933611db15a564ecba5a62bf733f197bf21c19f7b26f602a03ae365bb6760f678919757d19d0794a88c999abb74cee3f7d65f6ecd93387aaaadae869536734da5a8ce90bf09b89baba7a101ac82b6d814bcd21daa0e428769e78c64daabb09dd49f31f8c54520f761a3b568339ad563f21ba376f3ed36b6a6dbf2f2bad80a2ba0eee84a46a50998d34b5f8104dcd2c07155806b1a86228ee3c82e9cc7973befc80ec8d1fdce98fc960ec998797476a18aa5acc0811dfdcd7c7bbc7c55e37fac89afe417fddcbaf87de9d1984fc1dc6381e37e6c5beffb49fdf799b14450def9b3a4a9c3c48e4e3de5b278f4fed96d83f431837da6c40b81eb857ac80f7c767e1fc412f6c8d1d8dd6fc5046fbe7e1c6c11c94cdd2c2a5dd4bf1e25c095e5e3b886fef9f63e04b1f3e3fbb8c27a7eb70aa320e9dd5f9f8f6e91238a74cf0781d1b03cd4aa80c13c3e27142b8b055817bbb529eeba32b811b251e78b5cf0fef8e25a371a135f6a54ec4c10dd168cd0940e7ca51b85c3c0e039743406e87e3fb9510baff6e32dd7f3f831e789039405eac202f8e069039aeaacb55c585ffaccbf80bb7c75f7b3f362540a61b4b727687c8628d8714145c63603e2d1eeb03f5702acb08bb438761c104298c313080a75320afc62e78797bfdbd672371eee2a138bd0d191bb131a300a90b57e04ae7319cdcbf0f2e765ed051d684ad990346eb4da053633c411eaf445ea816ccf41d61a167050d7975ac4a5889eba7cea028b7188b18fcdf945d82f4e45c4404c4c1c763f6509d21234d6d44f8c7c3cd613a829c18be162687e3cbd4e8d37f2821d05a191a09f5b493d714eef1b811f0351b36fe2fb8fc9d62caff114f2e3f5c6040924f0446a60c2f8b640fe17f42190b6a562c8cf167c178321b234751901215808ebcf210077031b381fe701dcc99300d2ba647618e6310e64f9a8de52b2c708a50b8c8d803c242f2d291b49e942102267860e6f8a943b985a4040431d5ca1b05b1a5a8cdd883a8e9e170765383cf7c01c46ca2907188c2e68b142aee5368ec63a1e33b1fddf94d0027b982a8ba23404f5cc587053bf8507a9a1f2eb328484a0a4063983ad7c3c483cc309f765746444cf817f793fd77b07f246307b5154588978d0c097550a3a3cd54e9d451ea74fb4c471c0f72a637db1bd3f3f41439013a4ac4504e32495a82ffbfe3f3f8d9ee568cc1dfcb153d1ded74c396028c725f02d3f987b07e893fa6c5ac87ccec4b305cf90ca6f127313ae522b4e32e615e7a115664ae81c9dc7a5cbf9085074d33e0b16407bcaa6806df5f62c65e82d0b40288492a6042ce55649c2274e2e1eff4c48dcfe09477971ebffe252c339fc168d10d28cda8c3a6fc6d68d9d982abdd1770a6f30402a64472e22297127d0d2d7ff67f9ec3f1ea2248fea56b1445294a4786a24633e032419aa2bc199b254b5149d294e006594afcb89298fc4b551d53623c2df0bbb2a6fea499c1c106675ebcb5ec38796ef4dde78f1c4e5cbd69fa7580cc9a15104cd45575c9f6966ef2e04dff90cf7fd1865658a597a297f92c7ff2261d91b79fd3f48810e7d0f42631b6306f2dffe8c6c666f3b6b64ed3aeae2e831d7b5a6e1a6a1992f133e22176f4022dcee87cd69177345fea399a2ff33acd2a79049d6b5fb0065cfa00a35927bde0c0eb51ffc0da8f84846fdcb646eccfb563e20e9beb176a9f7d6a4975dc1b7a778662ffa8bfadf6e7e13fafffc4880989914c0f51ce9bcdd2f4b3bd16746fbc207d338a854a773e5cdb2887ebf1fc68f3a1f0789b271ef6ac44ddda4814cdb343c5621f542f0f4457cd329cac5e8e33f5eb71ac321d4dd97350bbd4070dd91371a38bc16bb483cb6d00fd8cc1a07b53d0b94605a51329d4bab1e1a7cc26bebac2c45c5e847b38d309af9a7cf1e346310eaef6a36f6cb6a69f3738e345eb2ce045051e9cce45698c394e954e18fc76611619b81834d87fce9f3c6ff1241509a39eda8c149dcef7f719cb7ef6d51dd2a24224d34b71e044bc023739c00c52f14730719213cea68cf833b758801cda8bec3075923d648424e1eb1684b8c8d4a135f7f3c39290bc20038be6a7216a5602ca376d477d69059cc638c35cdf1896868ef0b137c7a7bb0bf1e1622aba335411e9390adaca96d065f8c18ab8a538d1721439cb37212e2a15eb576d41ee8acd0cafc845544822f35bc1901561f427a349372eb24367a61ec3f964707c89123a92a4a1e8bd8cab3f7fdd8ff62479b27ea6d27a49a1df36a7dc4f6d757a9888c8a09ca408c7d0891f75bd7c48ad6543c59a05bf6c36a62c676394279bd61e2b00312116468dd4c22c271fa84acb227c921792190d93be4310a9f3bd30c76e3672d3c7e1da63193c782186a913d460a96a8668af104c327184ea0819182bebd30ebae3e0686087f86931c88ecec212bf54c4782422c02e049e768e98e16d022f1f65b84c11877728d3a71219ac5a48c1d68b82921e051d230ac3875183e6aaa60866fecfacf1a103b3ac6713572de73c2116f5776daf9fd8ccc39bab3af22264df720d4e5f953af7eb751fdcbe",
            "53466f59e34b079b2b21638c11161aab0ef8abcb104f6de566e5e1ffed1cd53fff269ef93192b574d1c099d643a8d9b4013ade39181dd30afdc8560c8becc5acec5ada69c97ea8a6f44163c175a82db80d9305276135773b3a0f8482f4e5e1d3b129088b990fb3ec8f98584630bbfa0e860f1f01156d63382fdc0c15db40e83b476062721566ecfc06878277305dda0b85d99df08dd98cb3478f634f4d33ba3b4f6171ecb281e8d06432c9de6dbf083febefd686c20f09d198643fc9575364c4743b5b07cdee7e6278f1ec59bbdafbcfa7e7f4be18dbfde899c585ab57753ffd207bb454d4693b8fc881a08de7507ae80e761fba019da216b83fa2a190d988ed4dc770e27e3f77df5d0e991dbba4525f43dfb8b3f3b4d1b973978c2e5dbaa4d77db2bb5c4b5dff94b4b4f217250353a2baae88961d2034bbf026cd5e750502650fc157741f0eedaf717e8083baef5c2cfef283b3e91319acbcfff494fa485d7e873ffe100bdebefd27ae0844f5f4fcddd7cdfcac87d3a9374274f0ccea11fd38a0c579bc5800ddb3d9e4900fffe00e2716e68fe2474782182ecc17c6c149147ae28df0b2751daed4c7a139edff62ef3cc0a23ad6377e76d95e5896de597a0711a42a20522c20080252555044c486bdf7de7bd7d8150bf6ae18bbc6de4b6289bdc76894dd3d2ff33f8b926b12736fdabd7fcbf93dcff7ecb2b085999d79df6f66ce8c0b1674b4c5b4427bcc6ce78a391d5db06a480dec5e10872bbb9b40fd208df16b8cab22d3aaf6f4fdf1d618ac6f6f8dfdfd9c706fa68de6f1602ee913259eaa90c83b180b78a4a09e83e6f9fa449a7c3f1bd3fbe490dc10b34af5811c2d395f8c57d7e78254ecc7f5b30b2b9b063b5504db489ee4865b6b5203cdaf87aaf4c71a72f4cc294af229b503eebb3a606c3175cbc74a46d697b890d27c33ba478c25420383b0b6d0045b8a2d30a68921ce4ff6c08d4d5998c278aba6710d90149588bc8c12746ad31f837b4ca8f2001d5a77c79451f330bcf768d4ad15011ba50dd2eac7e1f6956120daaf70754b2f1cee678693d36a213d2600262253742de88ab58b3762ece0a96897df13e306cfc1c02ee3d126ab04f14cbedfac510286768ac5fe59713839da1b5f317e645e0b131ce963418fcdb0a063c3fcc957990664734ffbd31e167271d5b8ff80cf723fb9eaef5589522a22c62289dad89a8f7927f43074b51e6c4239c81dc745d7b55c046570611fce61b4570ff686166812da10753c7c3022a708c51931d8b6cf969ed23301f975b391e8d710450d1291135d0796520be4c6a4307e2103fe2a4f58ea1b218af16f916ee14cd441944b38221c43519ff10659e12968512f07c35b77c557bd066342db5ee8dbac1dba35c9c5b41e5d317bd450744aca605e3f0a11ae1188659ed329b11889351bc3d3c2956e53ab102e4adbda14f549ebbfee73afb6331591cd633cdfbcde12801f0e3560fa1add1efb4b41be6b8a0bcbfc9014a0a463cc0d91e961fba383b1cc495f48fdd171f2ea72596620d423d3470eaf38b87133964c9b0455c26858e71f62623f42daadc083f224ec5bdf061d870ea2737a8d41f392be1836a4251eee8b01a1c7e0d1e9e1289f9780cd0b3291d96d041accbc0527df2084a7b644eef83588ceef8ba0d44e700a6d02a9752812866ea423c6dd837dd17138642cc2bad27528dfbc173b37ecc6d05e23b4f9191d2b33935a3e3594891d8442e1c7729623f7bd7aa93af3cfdfdf5fe854bfbe38383555121f5f20cfcbeb66d0b1e300e588e9d3959bceded2edb163c1a4eeaa1ba70e47155fbedf3bfce4dd5a7bef3df6bc76ffbedfce63c71c1f12d2be9e9f1f918435d6b8b69f85aca98770e3de1b444c5b0f6a5419f6967f8365071f2173ec61f45d7959b3f8124844fdf4792a0b5bdd19c21e478e9c743c70e0b8f599ab6774e7fb340cb5737f61263345c0f56f69976f5fd3d4f86b34b5ea11a815f7412dbe8b9a3b1fe2d4ab0a94139adefb5a537915e4654252960bf5761d00dfbf4077e61ff9d4fbb7eaef8a2b45097e6a515b426b9628c9da6602d2d14f40273a8a5e34b2176b42cdc5288894617f4f09b6b716e3444729f6a65258174e616bb2010eb4b3c0c95e86b834c210b7e718e1f14a6b3c5ce58ae7ebbd400e3b83bc4866dae15054dc2cc2d1298158dc808f4b336399c76ee0f1d606ea171329b2284fd6c54850b546ff2b2ba998f468eca0d59ee9a739bc7ee82d0545bd6e51d79e9c5f9240ab8f666bc8b51e1a52b15c4d5eae2599717e839866ecf476fee237edf553d39486024aef4da083fe691b4379657eb0218647c93133d70c2786daa1573d7dcccc31c3d519aea8d8978467375660fb9a49185c9c88d6e9e928c86c8ba60d9a233bb998c9dba7a130a318be76aee8d4221a4f4eb60579351097f7cd40a0674daceaa2c2d93176b8b0bc1e0ad3839058bb11260f9f8fae850319bd4f4587965d5094d316fd3b75c0a6255df0edb62c9c9f198a9d9dad519a6f8292702956b531c39e9ed6da591946a457a4f4a08785ecaca7953c58fc76bdffe77a9e5c759bb7512a45cf8d252288f544f480653ccc3cc8e87f18071de773e8beeb38f06fca81630497b6a9c5e4dee6d688f78f455efd26e893d912457159e8d9a40003b3f3d02a2e1596068a2a9d57195a228ad18392e42234ae15070b7d0304dafb33fa1fc944049af837467a5053a406a5a0b15f02021d6a20313c0c414e1ef030f340b84b1dc47a4722a3763cfab56a8969c3ba6350ab16c88a6c88e490868870af0d37332798ca94da466e0d495ecdfc0b521e5790ea91fa29d6059f7abbbe244a4f4f8f34f035d0eceaa9a25730b9c5c169d1f8fee40cd03f8ec0eb032178",
            "b5c10747c6386aeabb19102f33655f7303c11fed2738eff595c72d0d2464c1a4099afd1b3663eb9a95b08b1f0755de5ed8b5398cc0fc7928c9a9476fefe742dff8ca178fb6d70539170f7237130fce1660f3da119837b63df6afeb0ff27c349edc9e043b7b0fd8f9c7a3d91a82f0990431733574e2820aa42f7c84f4e1cbe0139b41d71a7213768cfef718b91887b7efc5f6b21d58be60299d9ddc5ad326bb336ccccc92047a1f5dbfc7792f741e40973bebf6c9e717cc9a2599356b96ee0c5d83056565c64bcbcb6d966f3b6677f0e089e0a1371eecf0bdf038bae79527ce8f1eddf6d972e284cfaec3870d19cd1d69cb48afcbd8056aeea6bbf06e390e3f80a0fde82598b56c2d569e7e8db4c927d0a8cb52da3f7f22510536d9a8b2718de8d5ab9feba5ebd75d2e5ebce870f6ec1587fdfbf73bce9af5959079bdd9661c31a93168a4a61f2174d4c127b4e7c91fe17de6057ccfbc42f8b11fd07eef431cb8fb4a77dda2eefa453265f6a2b6efba35818787c7e7b05f46f5dc7f0f3399840c4c9092f6c1a2dd767249ae815ceeaf5028cc2853e9583125216bba29346497092e0e17634b2e85bd45221c6c274579360f3b92f5b023898f63b97cdc1c28c6edf1323c9d6f00ed6e2bfc74c415dfadf3c1962e26981849614a0085034566204fe741fbfa305e9ceea1793c8622077bc9d6bb9948abfc2b2103061872b96f926b5991416da247b89b4ac31845f9c6db544632ead892be19ae6458ae2be99ee67d3bce5f55df5129797f7d03e713d7154f26748be67729993ae91b6da9f92adb047b7ad8607ab221ea5a0b312acb0e37e7bb82dceef9769f43fa04ee6c4bc2f629d15830320573c7b7a1c7f4cec4b43e0d706469125eef4fc0d395ae78b6a30829e959f09fff00417573707a8c39ae315ee2f9ce386c9e918c89bd5331636c07ac5e30106b6675c377fb87826836a1626f435c18afc2de9e56989b638258277db40a60fc601f3bedb6122b32beb1f2b49b994c48fdebfc91cf751ff95ffbb5f126fa2222a6c4ea462df8587543af2ae76f3b8d4b8fd9c3a503b238708de3c0dc874280832f9ad56e829a0eaeb037b640b7a6994809ab8b8159c5a85f330c768666880f8c40c7a65998d2a10bfa33397ca0a30f6c95a68c9ed743b86b6d3409688ccc90346486a621372cab325855031be78c60be0337b166484fd4f3f24190ca1f912e61085105c2566e037d8e1c46420398cb8c6973b911ac1426b0535ae8e617d47d230757865a078ce273a83f3a0efe31b6171d66a652e9a3005b71652b7f391d652744ba1b17c3a204d83e24082ff6d4c6a9098eda69897232b4b1c13d337d81c2dfe10fef77f4fedabf5bd64672326ffc44edad0b27b1b174292ceb0d817dc15138b52a87aaf0184c5b1d4750e3ae98956387eddd5d717e651afaf76f8ec2b699583ab1138e4da983c363fcb16f42246eed2c4246036fb4ebd60d6da66e44e3d17b3066fa303aaadfd7081cfb0ce98c27084acc46dcb0ed706d36999e306c0c562d5883bd9bf7a05361674d7e666712ec1bd89b477db4f5575dc6ba7d00ab3c00732b481d30403c6e9ceefcdc5245e9ce9d463b8f1eb5da78e58ae9fd6fbf2d4ffaf6e9f2f0ab8fcdc8cb07be33ce5dafda8f7fdab439c32c8dcc9fd48e8c43c2b18bb4fc2e81c9f0d5787ceb7bdcbcf704cb4eff80ecc90768b7267d34bc3e9b083fb9f30c959e9e15f35ca76bd7aeb99d3d7b56776b7ff3e64dd5a54b975465656552e677e9665c1182d35b68d6115239fdcdebcaeed0681209d106dd23b4efae97709f7313b5a65ec18673cf343afdbf7cf3f666958d5b5559bf3bebf753efe7aaaf95c9f43695eef63295303ef23767e30eb110cbc98ec1066ab2590cbadc154f56d7c0ca063c2c4a126069ba004b32c558dd528ae579122ccb15a1ac8d04abda2930375d825175f4b403bd29cdec3a14b6a40a70b49500fb32b938d99142c57663d0e782b4cf5658935ba384df46b9febc0649871f2326c5261465e56b6d58edbf8398c8611ecf17525cdd3e5ccaf7c7d03fa3dc5247081374b8a3929e966c8ead4cdebd2acf1c759d4d616fe1818c401bac1f198f2757f655f5ffcff724e0e438174c69e9866d5313f1c3f142904b2d404e36c08bad21509fee8cbead525067ed49f4b94a202ffa0eadd342e91f3707e1e5f650fcb8ad367e3a9888e7c73b62768f444cceb0c7b3d59e203ff5c2a3add15857628de2ba160876f660dedf13e352cc7164b833bda5bd059de02a8b787b0909f539edf5ff1fe76c98b0333010fda8cf17c1ca54440f2ce321673817c1d95c8cd9ad8790e65c3837a0e0e66b80c286add1bc6e5304d8bbd34ec63688f10d6074d8140d6b85a1b67b4d340aa887bcd84cf44ccf4771a344f4ce6c096ba531429d6b21c62b0af1351b20e3adf657b6a893c578812688f5a9897d33c7e254d95ccceb5c8ce6e111f0b674473db7483accb1165d4be54bbb98a96867335bdad9d4164e264c18dba2a6ad0fd2fdd235fdc3071373a97e1d03de27b74eb3fa3b1640bd3d4bb61e13d765227165831a327a629e25f2ea1822c45e8c4c4f3dcccd34c4ca36e6da817545645403d9bd28177d933fe153abff46e26f6171c34822205b4b1769af9f3f816dab57c23d71386c5b1d86aad95a38b4d846bb7638028bc27388c9e886a5c5f6c888f3c0fa497540dfe9850b0b53b1b38f230e8dad89fd43dcb0a3b70b0ae2dde82365ed5071bc395d71269fde3c2116357a9fa1eb4efb818e98f40269a3cae01a1e8f06094d1113dd106181753076e8184d4e6a1b92dc20fda48158c8545e84de47daee381ff000fc828202e1a44993c4a5a5a5fa8bb76c315a78f4a23eb97a35b6eeb987",
            "64e31b7a77c18d176e5edb2eeb3392db26d02ff08aa76f00c99b30854c7dc5e4f83f12dae63ea1050bf7e1d2372770f90d41d3611b6965ca209a9a78b192779ebc52366a1a991fd1c8fef4f3e7aebb0f1c70bc7aeb96e3ad5bb7ecae5fbf6e7bfefc7756bb76edd27f42484d6f473762efe84eeaa464563807d6d63804d725fee36793c8d3f72ae34e1175930b4413b74d4d872eb8432f3bf5b492f93caf32b35a3b7cc273657fb4ce74be80efefafbb4fe6bb1808c8d90da11af26c34e8075d717bb53ff62673b1b7191f5b9b0ab47322f534452e1cba5b201f3bdb897166823eae2cb4c5b2fa3c8c0ce090969e42b2355da4bdd94eacb9d64e461f6d2dc09e2c1e4e759340fbb50d5e1ff1c1ebf9324ddb4899cf5b9bfd9b732cb97f600ee373d296eaefd616539998f48f3153efeca6c28e2e8ec8aa69024ff730f8fb8623d8d5132d83ac30bd280c072606e2fc142f7cdddb1e2d5d294c4832c0c6622b6ceded8e8787fbe0e0fc7cb8b71e8d518f08967df794769f741f82a4a9d8322d19f70f744259b105d6b7b544d75001dafb717062ac1b4eccaf83393d23d032d205915e7e08f2a98bd09a31087575c737639dd54f96fb564ecd342f3313f13ff5b197bf330630d1445f486494b82292f1c3ed977311d49283f07c2ea3ff7a708ca350d3d50d93da7641c7c40ca485c5d1eee60e703355c1c3dc1e214e359011de041d9ae423a75e326aa89c612c91c04c2283994c1ffe2a2fc4f94622bb4e1a7218ddcf0c4daf6c169c8efa3e8d10e6e4843ec9f1685c3380ce080d661ef3828f9507eabad646a0ca8f76d35ddb69624b3b9858d1f64696d085b7951b623da2d4ed433b916855c411199f2b8ab08bf8947299ea728f14ea51745c805165e7a656a430c690ccce97e339e363afcea9816ffa9961cf280f04d88a11efc2a787d797d223ea4be8494916887637f2fa137dc7cfe3ff4cff7f4acee39045b3a76977addb8e43dbb6223cbd3f2cb2b6c12e65211cb218adee7c090eb96550b825c2d3d3110716c4e0d5c6003c3cd81c9b7b78329ed90b0b3b7a22be4163b8341a06f3e03c2425c62135ad053d3caf16dd32bf35ed3ff607848fbb0baf2e671132fe31924b66e3eed52bb8fddd1de434cbd4edfba9d19db3e1646353ef13b866f37d0f50b5fffa80b7f3008c07d82299b5618372c4fefd7c428ee7981fbb4db6317fc068f3772deebd1ced7ff9c95373573fb2e6d071f53542e8bd1a2d129e5620ee3541c6d6fdd879f0143a4fdf0941c6587037bdd0f28e13a23a77e7aacaded565ec94858e6bd76e519d3a75caeec2f5eb3aedb7b976ed9ae58913974cf6eddb67505656665c5252d2c0cad83c5c976b2a28be37934c765250d4611b95d76bf746d92462e06cd26cc325927748a349db475e1f5613b266f5fa0ed4c73bdef277ebe8fdef916efd968e4dfed63c72e772730db99503f5117b1cef22c1ce543d1c6a29d41ccae19391617c12612d21bb7b4841beb101b9ee851f0ef9694fe4092a5734119e75508a777a9b48482b1f31599d2c27d7db1b69be2f51688fb4e0e14c4f312a8e396bc81e2b32abb9a48d982bab9e97e052ffba36817aeff3e974a63a389fb9b64433772b1bba1b6ace4cf4c7d9493e98db5a0537075f2436ca4056463b444624233a3006894121c80ab447f7680bf40857a2b99f04df4c74c781be765898a28fbd1da46892d582b61afa846e38f7224da56c46a3bc3c1c1c6c8fc971326c6b6f83cdbd9c90e82c46db303364063b3039a73f12ebc423ba761364a6b4419bec62d4abd304715e56989263aa999c6e4c9ad650c4319f51b7ffc5e77c7efc7f1a0378612415137dae58139b2f40b7d55c78a77050339b03afc67a3032e155fad93a61684bddb97e3908726074dad209515e4168159b81e2c6b90876f68142c681b113054b772e4ccc7930928b612c92c3526e0c0f0b47447a84229da98bbce82cb488cc84bf9d07ea793ad20dfcbc98dfb9c0c5d402c12a7f843a04c0d3c2058e4cbeef60625d95fbbb33cf67bc011deb514f1defdd90f85b7a1dd117702d6c8d8d3fb5f99aeaefd96499804f967573a8f8695b88b6e2642e4daef780f6e96c5c9ee785eb5bd2b0bac4155d43f8a8612d4686175f3db79911e9ddd0bedc5cbfea827fee9fac6b1d1b851c8a746b5ba8debf6537f6ac5983e6857d61d47809548cfe3b36df0ca766b360e55d0fbe491d105ab41067192fa2fda63e2eafcfc4fe7e2e18dedc1f96d14361d1e26bdab5cf3d38a58c846febf9701bf41c2eed0fa366af93081dfb08cec5c7e0dce52aac1a4fc5dead3bf0fa87a7f8e98767983d6186dac6cc927839b92e37927d127b6b713e10dc77eb0004a5a5a5d231dbb7cbd71d38609d557e7581dbc97b8fd3efbc7c187df3f91eb7ebaf8f1b07c7d2f5c66ed4faeea1d1ebcc0bccd768b083100c3e7d16d94cd9cbda7f05ee512db8e7685097dfd0cb68a2699391d7544f6ca21b3fb02dddb0c1fac8993396972e5db2387efcb8c9c99327959b36edd75fbc788b74cca24554b52721ffdabb47579e6e02ddde9114b5d6d258f5c83b3c89c4771d475aac394d36de78511e52abf63b7d1cf039f76fba3e5d575727ead63024cf2f456ac9510b3cd9e8807dcd79f4c9b622ede15c0169e3253ce66a222d9289f51fc7ba492a1f959a6ac9dd40dc58eb411fcee0d005fe923019af4ad3a3f5f4a45fd92ba48f92dd24645e632372a1d84473ad504a5f1baaaf21e71dc891e18a150e0692f7e725be6474d704e8be8b679ccde4644023f38a2e6172740a972123c01c71d1cdd03cb32d5212b2e88e05bdd1a3e328746c3bb86aed7e6652365c2d5d307b680c8e4d0dc2a662736ce9688b4d9d4ce0da",
            "b50c8e0b5ec1327504b6f7b3c7e2664a2ccc31c6de71fee896e58d1a2e2168d3bc043d3b8d46ffaee3d0b764145a6516a15d5e67b4c9ef83a4da61280916aaf33d79a48e85f06b23b150372ecafd42eba8faff0e3796891e19331e40448935c5a3f918b2938ba8765ca40ee1c22d8103853ea72a97ef9ad20c850d9b20c0ce8bd1fea668119dc4e4e5e6501853b00fe5d2f6611c38d5e3d09e4d38706bc081aa961ecc6cf830900b602012c15ca644a0834fd5fabe18cf48381ad9c143b797b3b1356aa96a20dc2508c18e7ef0b3f1424d3b6f04d9d744b05d10225d6bd3e1ce219521f601c45e69b64bcee718d8d9d97d8ae367d57a37432ee0570e4d33af28ef62816dbd1cf0e24c37685e6d03a1d7e1ccbc587a5eba3ec6c5eb235425d626b9f1c9e00646ea5af68a1a7f61fcb63ad71bc2046996d850bd67dd56ac9a3d1753c68c8151bd3170cedf0bf3b076f04d1f4487f5dc8fa01ec76098f135668e6a02722313276744d1a372dc61da703aec0a8ec0b9ed61daa1cd5e0465f542f8886bf0e8f80dedd3f32cfc077f07f78e27a06a770a92e45518366a2e342f9e56adf33979f8883637b9259d18dbe4b9944f39d89a9a723e81fafb3dfdd79d99cb1b505eaef30092591b8ecb0f1c382025a74f7b2ab75e70b19fbd59f7dcf62a8a4bbc4bc657488e103aeac84b5ca535984208ddfddbef68aac334702e1270eed3b078ac45df571add39b6e4fbeb37cffafa8478356992667afaf469f3f2f272937d274f1a1d3d7a54b97fff7efd2d5bb6c8aade73d62c59515191a4a0a040d4bc797351842e222274eb14dffffc964c64f075d767cb0c1fd4ac97443cbd036b2a248acf71ecf9d7635eba7d1cbe4f8db622f4c59a3439e1846be38de9b3453ceda9d622d2cc4534d8422115787854fd6d269712919e8d655a72af86e6fb258e647503ce0e5ff3b77afedecec85614252e92098597a2ece5646a23139c6961a07eb9c89c3cdb61fd6d88ad58c4a4549f5a4ef2dfd4966043b1f8a1b148409a380b35457e428c6e2843f7c62ea81f978be4c69948699481d1fd27e3abe94bb17cfe1aac58b81e23064d83a7a521933f4a519ce0441f1ae6429f1f658b7e5d1a40d4f31026960461638129a6a59b20ccdd1aa61219bcec549837bd14eb966fc59c494b3069f86c8cea3f0da90d33919fd315e90de23135d55033b1818cb409949db036901afc8979d4cf7d1e40b727d0254389981888c4dabe0bf898738e8ba987b988eec281952f172ec62a84ba04a0539354b469908e82b814e6313b284d19cd8fe4d2b6411cda298a03ef140a9e2914ed99ce81572a07b5f219efd08c0b87102e2cddf56064c981810117c672096c8c1555f304167203988a9530e01ac0886f084b7d43988a98fa1728616f23a775dec45024fad140c85fa514f285f59dea7faafdd72fcee14baaa5d41e1e64878d1dcc70679e29c8c97a38b9b1036e2ef5c2e9b1f6f48c54256ada8889bfb5f8a5ab99b8b5f15fcb997f1e8f63ee100f073bba6ce1522c9d3a150736ac406cee3098d61b0a55781e5c5bed8255fc5cd8349e0b65d641f41d59027229178bdab8d1f6f507d3d685df40d5621ba3ef27502b6f3a1a0e3f0cbbd647e0d27a375cda1e807de15198e5ee805b8be5e8366c3e9edcbe8b376f7e82e6cd1b746fdb5993dfac9804d7a85528e6713f85dcfffdbee1833e807a3b17c07880f3d231db4f2b47ec3f2b27970e18966edb267b4848ac93c4b0d22b399f76bb44e079be02d32b34d805d0436efd08c35ba0056f081da1d6d23dce3e45e2b2ef68efd50f34f50e5410df98f42ed672233e63078ca64c99a2d37cc5ce9d3be5ebd61d906cd8b041b7fe50b70641d87ed224dd7a045e44c4009deeebd627bcbd56212242b7c69fefef5ff0feffa21b2ccb1071f98186fa869fb3fe57ff5fbaebea2adaa4d954922b5ef86197232ef514a9bf6b2f24b9eea28e86726975bd0ade5a00aacc46242427573856fcb8c48a74f1e6a52a148aeaf17cbd5fe5f53a6f3192e997d409ae0a529a6cac263bac2a0ae3e435de4dff7329969fcf9b574aa5df3b184948e7307dcdd0ba32accc37c6a01c26cff389465e56115a37ef84092367a16cf916ac5cb80e6b966e467a6206a2421bc0d13608b33b7be2c92a3f9c98e08282f4406ced698f05a90688f3b586af67341a4535457ae3965836af0c65cbb660c1f49518de7732ddad7820a2c25211135407cb8bed350bd30cc8a07a06379d8ca4b6bffa8c5f32d5f9a1b99d9de48c5228aa647c80a6e71c01ca1e70e9d957f450239e82bb890ba3ff3599fcdd135d529b21ca3d1426c6227834e4421542c13986d1fba68cfe37adbaa55d9bbc9d43881fc241e2700ee27a73105ecc815f330eed1ccba13306719136844274270e42f2b808cce2a2f7575c4cd9c5450cf3b3475d0eba2de1a8eba6f08882279e662c15d9582a95d57b957daaf556ad27464c3cf6b19590bd431ce9c3435578b1d11757177b23df8b42ef8686f4e929aed8dfd7960e7590b466fa145ba552f457ffefeaf754dadadade570879644cff01daed2b4ae993e5dbd0b2794bc87d3268cf76e5b44d93f9b04f5e00c79c7530687e1c7d46f5c193f551a85d2f8736cd3b0255cb5db0cddf07fb563be9b8fe5b68cfcea7e1d2e66b58b52c8779c67a04b65a88ae43e661d99c85f87afd3a3c7d70b72af75fb37489a6698334929e90b54f211170a84f7bfdd987e60274eb01a463166dd79fc468f5c8d29dd2ed84383a09f51f7bd669406a5fa369d54d1adb18fda7091036f72a0ca65c40cee3d788d8719fe68cbba6a696bc22d4c2db841b943250ce118b0f11a2cfbcb674d1a245ba5cff7ddde7333febde93f76e4da2ee",
            "33bc1fbff4286fdbf79734bf59fdbf46e93cf6a0421b2db9e149df9e6fa1be55a247baf88b869bbed5feeaf9f9b773f1840a6672fbca96714acded4986df869b89249485c5aff3430ef5afeb0e7504f178bcfd76720919dc409f74acaf1fc6e37db67bc7fd1d6d612c96e09eb391980c8d556aa6262850decf11638ac2d0283a93d1ffce6899d51ee347ccc48e0d7bb16bd33eac5dba114de3b3d1b06e2652a243f06c8d177e2a8fc1e5b59958d454869eb1a608f66f809ce4d6e854d007437b4ec6dc498bb075ed4ef4ea34021df27b21a7690912c263b065b0b7665d2b133229c9e8790d0ba9df3b8fc6d6d16febc9dfc258a2361489b5fa7a626d7c2e1f6d2752f0f096a08e4b18829d7c50c3c60d418e3550c3ca1b76be4c6e9fcb814702a3fba96fb5df2399034fe636ac8883c6c338481ac5dc0ee7d04d4670d088f9397a081783b6323a7f804b17cce6206d02072993b89877818b33848be987f5509bd1ff3107b915e95df844ce15ef329688f9bfea7b3f075fbcdb542e20ab7ba834771638e1d54e7f8c6c6c40677bf191eaced116d612561c1ee8400f4ab42c96f2de5db7fdf7fbc44502a64f4cae1f5b717affd7745e663e8a5ae6a3b0cb28daa0f10a38e56e845d46191cf377433ff738264eee81491debd206291be098b71bb64c6e6f9dbd1dbedd8fd3fefd2ed12699db61de743962db2fc2b869abe8758b9663f9b4f9983a6c32164f9d8e4bdf1cc6833b77e8acc4746dcbf402adb3ad2af02fcc5f7cecfacf687029a3c5e58201034a4503162c908e19c368f6f1e3861efafad7dc6b0691d6775f686b3d20780a1ae7eeff04de88f3a0465e80d1ca475a6a030d6aab9a88c7953f33f4a89df16e81be38b5736746efc7e9f45ef7babad0e9fe3bcd2fadcef53fa4f9bf8ef7bf77bc2f60bcb35a9f5b73292199d3cf5a4d2e7ba9ef0d9692b1e182f9b606bfd0fe5fb7c9d95e6662d23a543ec8d5484c51bf3f97ffbe87e55203a82e4a8168baa34222f1b7f8e2c7947f4f5b7c18ddbdef65266574d85453dac294c97722317d682e9ad46f890e6dfaa0756e0906f71983b54bd6a05d5e7726af4f4361f32e88abdd1807174581a8e760d7c830cc6ec44752903b5a667743ebac8ee85d321ce387cec2f4b1f3d0a3fd50b463b4bfb0793fb468928c7dd36b6bf6f6b4230bb2cd5f86a8f423df551b8fad96dfada71263b9941849446a038e01ed65e28dfabe7510eb1b8a4095276a3111ed5d1b4e4676708aa4e0c7e4ed5e4ddfe5fea95c3aac1d17898cd6a74d66747d3c07a9e398fbe3387423e6b1368bf4b0fba600079ff330620785f62b38e851c6a5d7dde2e298460f4bcef1903d8a8b7e1bb91531e97cddde045799cf616a6626fd9cfcdacfe730eb517a644c9ea59a1c0ac1aa5e6eda3c5fa9ba2452a9ee13ad449f6853323a5945bad6b719aa14f3b97ff33b5b5d76f5847a1471b6b1d4b6cf6b8fd446a998377e02b62e9b0bef863d6195bb07f6cdb7c3a1f55e98e51f41ff6e5974adb421b0ce3b00fbdccd706cb91db6795fc3a6f018e3135622a5eb22acdfba1f77bffb167bcab631af351b3347cdc4ba85cbe8b2f90be8e9234761d6c40915f91905242a2462acf0e3dbe7e79ff200efad0918c068f50071e771e374fb067ee3ecec4d16dc7da8497b41f092c9fd4bbe7ecc68ff6508373cd5500709118eddfe5a3f3c759e9148dfd9ea9df60707a7ea5e43f06e6c81f7eeb53fa4fbff49fbbf441daad6ecd1861c31d93845f59aecb6234be2f4f6ba1a49aad6ce7ee04cb7eab292fa98519dcde552332f53e91f293f76fcf8cff53f8c07a0eefb5ac8c8aa627bcdce2e56b8b1a915164eee8ce4b86ce4e7764544707db4ce2946cbcc62344d6881a2fc1e68129b89d2a583409ecc43596b19263656a061ed28742e1a8216cddaa3b04517e4671523b9612ebab51f8696e95d509c9b89b3ebb3352786bb921505d63fd476d2afcb6aff1faea7214ab19898e94b11e2e2a34d0a8c441d373f043978a3ae470012fca360616080e03c0e6a36e7c235910397040eedda9843d7cce520a61ba3fb13b8c89ec145d60c0e9acfe560fa7e1e9e56084088005798dbb597f5b0e35b3e7d512da02f123e763ce1a1d75aae367fa29ed6d55b48a494f8b8a95ce466f4f66c7bee6758c68c17a5e8eea916150fca22b4edead89082702bd2ac963989f6307a53536570c7c95cb6c654ce375028fe91befce7b31f74fb0084d608d07c357132668c1c8d55736662c6c409308c190fe7a263706cc3e87d8b2df06fdc99b6c9dd06a7168ceeb7d803a3b44d70ce29459b21a5d877f018085dc1849a3e75e40c36976ec5b6551bb072ee5718d1a70f9d9198aa090fa9a3ce484a21ad9a35ffd6542195539fdf1e1bbff401d480ea7d0244cd9b57adc3dbacb274245baf5ed7cc2004177e52c37ac93df0ca1e55286e13221fbe6c8711c573b7fbd7eb099d9cea57ef35a89bc7ff90deff19edff123d40b5fe2fb19288c9d9a5b6f4d9eed267fe464207e1dbf97cbdffc277a0fa9a3e96ffdceff93271dbcf464e96b5b557977731c34f673a62c3f2dea8e35717cd528a31acef78f4e93a0afd7a8c46abdc4e681c9783e5d3bbe2f196046c686f8209890688af9b80362d7ba077d7e1e8df63143a14f462f43f0799898518d4ad079e5e99a07eb03480ace9647f27c84111f4abdc8be53fd753b1a158a895f3f588bba5b53aad765d3a25b41ef2a31b20b1565d188a64a8d188d1f9c914dd84c9efa3ba70e880561cda83d17fe616f14cbe9f33978b4eab3998759a4bdf264246fb85b8ff44884da7f8b8ff5cc4fc2cc27322c6aebb7c6dbb791c75403c8f282522a2d0134f355788646f8f95f8ec3c76757f",
            "ac5b7ffa3ca68621691165493ccc64e75446e2294a093f93cfe5eaf6d194ff97ea354e5f48113b5343cde26953b066de7c4c1e3c187bd795a263d7c110355c04a3665b6199b11e3619658cee97c33875231cd2be42ab3e0bb079fd0efabb33e750f1f205b4b4ba6a7effc19dbbd8bd712386f6ea47a7c5a7a8e322e2503f2296d40e0c21ae2ad5554b43459852f4d99da7f9ebfaa4de1b0fa85ea3bac858df8cec3cfc8dfa21534e132fbe0067ed23b5eb03422ce66cdf67a83457da7a575d8f27b2b3b3d38d1754fb87df8cefbfdb7be0cfe83de7039fef4b80fbee0a88ad355432faf410059dea2c8a1748e4ef7b837f5797bf9e1b60f9e7fb20dd4694573ccca5645d4f2735b9db1278dc17fb67d547467c325a64f766f2feee689bd71dbd4b4620323419533b7ae3cd267f7cdddf09a313f41119520fdd3b0d6772ff6ec8cbec80fc9c6e880a4dc2cc0943416bcfabc99b7164efe4c0b335544ae75fbd37cb1fafa7180ba9fef7fa023eb1511a9086fe019a92a4444d51c324da44a280bba90beded65a24928e16bfb6ed0a3e79ce762ee052e269fe662cc01e6fe593d2cbbc2c5ec137a18b7998f0ed3f4903b8a8b499b79f49d1f05dac7af059ad2237c75fd963c62662e240aaee498b15454df5c29fcdcc7d7aafb97e1a652fe2485502f542ee2f1ff4d7ef94fd7eb2a7d3e872445d7536f5f558a2553a7d30bc64fc0d13dbbd0b6db044c58b01de1ade64291b20e9e59f3d1aafb0c942e5e83839b7762fbeaed3871f04495ee6bd4af7068d70e8c1f3c84ce4eca50a7354c234d1b34257543c235f69696a50a89b0a1448f127f413a54adffbaf5f7ba9fc7f33942b279cb0edd1efc88297f54e1799f10cfafb67fadd4375328df5ebfcfe4fc4e555a4f315a4fbdd5f83fa3f5bfd6fc2f75dcffd7fa7fb8968d94a47b4a8a4c643236f7fbf8b44537dd75d8dd5a46cab77750e3783c7d6ebc13be991988ae39f5d1ac6917746c3b08ed181f90503f0721eeaef87e7314ce4ef543b49b39d252da5569bfce27e466f440f3a639d8b6b0bd965c29d212b291ac98db67839db1d298d5febf5d4f96364646d31402c143899e1eb1365090700f2f626768423b995a1127433b22a344c4c65c441a240bb5bd260ad453b7f0d58bbfe16b476de2d1cd2770e986fd38daa8ae1c75542f4ad36c14479bdd9b474213f8c4c553488cf445449f23beaf14883a181b087854c4cfeffd25f661d56bb5ff5be3e4d5afab5228a8a7160672ba5b6121bda374355d367f09bd69f17c5cdb3f07e7774cc59cc9b3d0a9cb082c9830116be6ccc3aab92bb062f612946fdc86635f9763fdd2a5f498debd3545e9d99a36e92d488ba6d924a676e40f0e969633e4223d1ffe6fdff74bd0feeaa8d6ff6e4c90752b4ad5d741d47eb7090958b87997526ef2f60a3cdd426426e77f4ff7dfcdd1fc69ede7fc97fce2a7ecad1b38184b5a5928646cfffff16a8bae7296188bc564520fffcab3135c35bb4aac7168b813a6770a4676d336689ad41ed969ad11e013873eed62b07c782c6ab8d646a7a27e2868d90be9c91dd1b7201ea796c4a9d5db82c9d3fd19a447db26a3f8bf3cfb8ce5efd5930e530733b34c7d3e7fa990c3b96d24121103a1e0818190bfc944263aa7e0897e14313e80cf8484090301a3ebccdf181908899d9d90b8bb0b899b8b8858188b888c277ac178860bfa1cd152a6ee3b9819882d8c8d25d417e8d57e3e67f67fd86f57976f2b85904b7c1d1dd573c68fa3bfdeba17f3ba44e0a74b83716e511446b7cf66347f31660c1b81c5536761f3f265289d3f1b83bbf7d0366f9aa96e9d9a837e85ed4971560e890c0cbc616d623c44cca71c3ef0bf7d497a54adbfd5f6a7854effe74f9cfc7a3193e8aba6976e36951ac9fee5f5223ebcafc01fcff139ff410359d8b2f898fbbe6a74fb52bf4e0f3321659d549a35cd4de81d9d2db075b0378ad3ea23b66e36521a1720ba56201a05ba213bb5039a67f546cb942c2cee15aabd38cb5bf360b117d93daec6ed7ab5ec93abeb9d1056fbffa1f6f36b4d3650505498894c66612ca91a62e1454450f6b6b6c2386b13617713856891a1547c94f1080f0d85a2dbfa3ce17e39473c9fd1fc12c627c498ea0b757fcb8b18f01b5d62dbeaffce03e8ca7abb914c409a44c76af66cda82f19dd230305a0f43932c31a4537b94ce598cf913a760eac8d1daeeed3ba8b3129bd169f1e92437399334ad1faf09f070df632c97e453ff3acb8c7a6ffc82f5cd4c0eca043a0d194912566c5c25e44b451176ba6bcd09ef2fe4f77f25c7ff92c703aafc27bb26efa3d796eab31afc9828773797936e7126644996a97a77270b5c98e189c5436291d6280d01ee114cd4416e6a270c691d8d7d637cd41727b89243c3dd489f66aae5a632a115ab25ff751fa0f76f7cdcaf31b69051fa4e4effb69fe4b175f5ffe6bd1d99f8c1d6c4881ed4b597f6d09edde8d9be18437af4c09c49b3b4bd3a74d7e46514d0e9f19924a15e02890e8d247eee9e17985c7fb0508ff2fed56bfed97309be84f2f5534824c4c9a3c67c53239bb77d12217a7f51f7d9bc96e57385f7de77ba1d97123e0c77362013d32de963431c356fb685e0e6d6540cead21c05495158dbc75b737c98037d78a023999eafba59c7d5a8d907bc37cb7fdf0bbc9f9370dfd373bddff9fbfff6fc36cb9fcf5173257c8af83a39a9cb376ed61e3f7c54d3b5a8bb263bb90549ac9f4aa242a374e7f55c3237564e900839ba3dd504ffe67bc0f22b7f656262d2df502479fbd880017a7f302f67d7f3b17c896d86f3ee282b1b2666194b44c80c33256767d4d0909bd93479329e3e3c2e50bdaba33159d4da8e6e166c3245291254aff1fbd0",
            "be0e2cffff3e81ad938fdf034cd1ed0b9811df90b4cecc67343f960478fbddb131339d2915e84532bf17b2b9fe5ffefe53eff2febfda16d836c4f225f6493a74e75bef73b3d42753fb479337977a9075c576a45db8e17e7773796d36e76761f9dbfa54352e1311412d51087977ad4c0c5718ca84a9cc83861f68976caeffd7c702fe091fc1c2f225f54bd5f70b99b8db30d0f66e94876101d3a438eff5496cdb6061f967b4c588d57c1616968f682ca07a4e4077669f0d9bf3b3b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b07c2470dfdd3a399a08f96c71b0b0b0b0b0fcc3e831c121e4777fafd39e5a4c585b89c56c69fd6fe0bdbb8d5352d4532bb1a095bd42525d572cff7b38effcd88782e5c3e5c5f987cb9e8585e59f6fa7d5183161cf842713914cb46162b688a24e057b1a6a1af91b2db312b2f2f3811c9d17f15697b9eff499f737fbbeea5cbf0e132feb789a911e194ed3157a1c56ffffb7eda2ba2eff88f6e8b175f38f6a3fe70365cafd073d050b0bdb46df92c5c43e9542f8a46ea8cb4f6949319adc9478d2a97502993630841c2a8d264766879279ad6c4ea9643cb68ffbe3fcd9b2e2bef79c28269ebb591ae1c2def695eb7a9aad31e07259fdffdff8b90f95b14184afc2dd901284f0285e20f3b33f13c1cc7d958279ce80017fabde3f97fce19fc8f1abfcd62f8b933266c2e9bff09e2c2c5f6a7babeea3462af4f4486a0d055955e244f68e0e24dfed1c5249c8452dd1ce5293273d34872707a9d7b6b3ad5c55e2785125e709d92af8453dd4b2d6e7f5b59488961af3846b0d38c2e5624ad889e9c8cc4ca5ff510b7ed1e7bdf778311315216ec6e4e237bdd5af4fb4221b3a50e7bdcd65ec1a80ff7ebe5f8da4a0203e4246f1063285be434c716e9908856a67131909709091082f7955043bcb5f78584ace99cb440bc49420e6bd976073d5bfe793ad984865629e88e2dc0d74377bd3a0b6fd42999ed894f5002c2cff489ea3639809a3ffb56d2515c5e14a6dbbda0a7a582c973eb6a403342ff760ffe4281c18e9a6bdb73a905c5c1c78c1592962f5ff977dd664a5804fe27de464fd1063b267922959d6cf841437b5bee3a854a4eafd7efff6a1fe2b80898d4aae9814a6d8e0f1e5ce5aa2d9841393dd2b4f0ee75724f8485d294a40511f1e8fe690b7c1f2f7f4c7d9ddca783863ddae29298af8a994a4559a3b993d21861cd8905479759d2ffdfd2a1bfad60a5bfaea7c6bfafc4c2b7278a225d93cd08c8c6fa9248dfce4072da4e244f1db7afabdba62f96d3bd02d2c0a62a21b135b2d04d4d3687f5b32a06314d9b93881dc2d4fc4cb6f52c8b23edea7cc65527d272743d65fb1b0fc331ea03b1324d557a1fd7a901bbad737c6a67efe58d83d1233f24c716c419c5673a525f9e974ca452f6bb9802db65f949d52415177dc8c84da552d05ea07f3f4d5e4b2979ad08bc9d99365a461a0453be1dba57cbfa703b5def579bbec95124d567d1b523edf434b1e14d0843cc6d32b6b71b02f477d6db2820c6b266bc5a784ba759abcf73f07a10630ba4ffef5f3af06a359fe50ce6f19ede73a454e512fcc045c92d1d08fac5dd69d7ef260819a909d1a42d6d1e4db4cfad93a0f9c1d6349ef2e31c4c6d6fad8d6464e6fcbe36bf7b5e36b4ef69569cf0c5592f9f90624c249bac8542c56f83b28ffd318d097ecb9f8d4db75c7bd2d64b2efbcad0d4856ac339933ba35b9707831f9f1db959aa73bf235b71647d167c7d5a40ff6f37af3726510e991ac6afb6e792c8f2dc68fba5df1de05fbfdffb8f39e149dfe07d84ae90313dc31b7d0166b4a1cd0dc5788542f7da47b88e9e9ad7cc89ddd890f227cf44dd962fb4deeb24b29109161f5459a8d591c1c1a650ff5eb4b5af2bcbfe6c75d8e24c64b1627d413567b80ea7517068c6f586f6f2825794d6cc957c37dc9e54dc120dfc668c8f3c1a878730fd05ec28d75f138d89bd29c19ad200786eaaff7311355bdce0724de6867ad7ad23194195b2b7fcebfe9686126e4dfd3e5fb69718164eff6318ce65fd31202104243ad264c7d3c85e6d910bc3cd6005767dae2e0600b6c2e52626b913e4ecf72c5839dc178b4c605376659696e8e33d6ec2951905807d1292bb9d8d35d29653dc02fdbccfb79bb37630388a3813e3931339026770630a57d94f15b84263f9dc5b7a50de80b5302717ea23f4e8cf0d51c1be883c3e36b9c309749f55253d9fcff23d6947fd7de583e8efe4fe7bd9be8e9e96932238ce8e3ebd37178ef5c2c1f9388e248259a0728d12bd64853186aa04e70e46b9714d9fc941e6116c016ddcfbc5de74fa879063c11e95d4fa43edc458c73a3283c3d9a499f9beb57392a4eef792d2b7112930b567be2ea76b04e29e491619986ea1babfc359a0b4d35e47a24adbe98890afa35b4cf564273b32d4e4fb2c3d1417c1c192ac7a5b1b2579d1b489cded59b5e2a95ca3feeefdfe042587cd9ed849ca70f5bb6bdf163d79e3defb72cd22b65e702fe88f6cb061445cc61727ee269a9204be7b55313f55c9abcea09f5a35ea87875085a0d40d304da57ab41df4ec7e3f5feb832d50a6727a9b0a9808f93b353198f508e471b7db1b6a32126a6cbb1bc508e43fd8dd4b39b4909d36e1e990a05a1b672d197dc",
            "07be9f0f56539b89e1ccafae9ac96474af645bf5fe3edef4e38d41787da90fae1e2dc3b195837176656b9c9c1f85735f45e266695deceb5b83be3e2380e4445ad7fb0f7ac3f2ffe7eb7473394cfde8b5666e7b3011cb7a808f52bb748c5470382427dcb8a267a61b160d6a84db6b2251dac30585b5959583e20c497d1729715108499cb394d4b292048bd951b79fcb30e2eded60b99e90b40f11a9af4f9042bd53415f5f5103e3ea891e7a1af2fd29aaeaba7ddd1d46b3ab9ea35bdf9c652a1269a21c84da65291cacc814e3eed610904b3150dfe84ee35a233c3f96c168bf102746cab0bfa758b3bd4040f6f695afaea5aad2123d924ab91d0c894d3b1b96107b353e2bf776e3ecef5f74eb45c8f4a979df37cbab6a6fec5cc0efe62736753c2d0fcb18ed4f8971d4dcbed8434baea5417d290eea9ba9d0de4f065df17595f6d35a2db42fa6307e2c9b7eb8dc19d7e7d8e0db397638d45b8eb3cb53401e2fc6ca967c740d1761458101d6b45560589c00a50562f5be1e52322e4dff99b958e4652de57f497de087aedf7b5bfea9d4283dc635a7d777206b86f8913333fce9a7ab837160a02b9e9c2ac1d691b998d7c404cbd20cb021d7147bdada6365ae0356b6f7c6f1b97535df7f154ab60cf5d926e78b594df9f82864e25a1d463306379793d2d1ae64ebca54d2aa91656701ebd73eb6b6a9b4a514c74c6432187a07d196892da070f141809d3ecafb3a626989e36b0ba1de0409c5c936e272874829bda9c67a7a52337688f9d71eaa9b801290920891e6f56a46fff7396a4e4df225adbdb95d1522c9bf7b7e171e2522c392a59a03c55c1c196509722506152783401e14e0eee6287c338883837da4589fcb43590e5f7ba2b788cc6a231fa6148adffa8f885fbc5eda9da45c9a8c193df161aba2771e2195ada5dfe6fdd6814e8697158c3dea53e455f1e6720e7edaea8697dbeca0bd9301fa4e16b48fdb42ab7dc8e4ff041a26b42f27807c9b00f56607dc5c60870bb33cf0ed2433ece86d8a9747a3303a5e843dbdcd7075aa0d767437c5f8182e4ac7c6829c8e55bf9e2f23439264a78d45225984c7dbbdb6be30cdd7358248e6d1b1123e75d646624c7c64de74bbd45aea9df383b53fec8cc2a36541b8bd2a0a9bc7c620cf4b8406ee4a04da9820c85689cc5a06d8d9c9012bb2545894e78e7bdba2e98a9d752a1bf95bd47df756aca6fcb3fe98f31fc670aae7f475e3904c8e51d50f497d7ca8f9a6520119d8c282688ed6d49267c51a42ce5410ed582dbdc541b7be2c87ffb609b29eede3d0ad09ba394f135b95a656a7ae082aee0c87a838082d1cd491ce06f4a62eaa43f60a76b9df1f28c78e14a3ff6373e46ab25b4ebf3e5a07fb8607d20ded29078a32d5a70ca9089188d7c559215d18606ab429ccc8705398be6c899f52b24cae2740d300314ef415e0e86873682f3504b99d829b5fa7e0fc0c731c1f2cc0d67c3e8e0f92e0da4c03fac000d9eb6f274849fb7a922221b76a4d01bfc0df9f7fbca080571e11d1f0466206a96855187336a199eeb3090678787cce7af357b4dfa48693ec843ec523137b39abdf1c8aa0af8c31a15f9599437d321cf4bd5c68efa643f37c14345a02425e327112eafb03f1ddea5a58d7dd1c431a8af1f0685bdc2df5c196760adcdd15834393ddb1244782fed17cac69c1c7aa4c0a0bbad6004ed4c3b65e12f5fc1c1149f1118d9770449fba5ebd3f8ff57bd7afea5030d18089990a81de357b991509310c214d2db2486b9bce74816d0f44489ac2552f10c12a1b6c1ae28217dbeba29e8b12762257d4314c407dd30c34306b060b8e37dac65be1f2a41a9895ee8467071a6af0755db26190ef61999e84376000ab27ff60dd7ea8ddfc91ef6ba22edd887291579c18a9d21e18ef8d8757e6404bce835c4dd192ad36d8dcd1e6871ae65215c5eee7f8ffedef74b43195892bad7d0334310b5620e7c20df8b6eb0edbc858adb9770d62666c4ca2ec25bd2d4402dddf0b29767fb30fea7ff5f8bf90e293b281466a522ea5d5e7922a8f4e087b1da3a2d69b8b2437eb29f5c900372fb2b3510a7990d79e3c6b5e442e87d727ebac556480c2022dc2f5716582085716b931797f53dcdc168ad523d2f0757f312e8e93e0dc2819ce4ed4c7574d059553e278a45d4d3ea96b2f5c6e2bfb79fcb37a9c7fc58da8c6d3ee27a4fe5ebd7fc9f3cfbaff5d52106fb14f9ff16ad37a58a95f6e77c7bece72dc5b640dcd0e15d497e2413f690bcdbd16806609a3fbbbf1ec72379c98ea8375ada5f4d4783e3d3d49883c3f0e5677b6a0af944668efee4bd0aa9fccd1de3f50a4ed15a5471f5c14866747b3717d5d02760fb6c685a996989fafd0663a529a033d24da304769d83bdbf829b5a57fedcbf3efa79374d7ec3763628942c8fbdecbc0952458249296b645a4c0b60ba3f93dd585aa9eda12a721e8eb3c1e137dbec244df0568633108b54d6aa1453d053c24fec8b669874ceb4234b3698d02872ef0d36b8ca2246b7cbf2a1cd736c5837c97861ff7c46a5e960591f410b356efbed66cdff4cff8e396728a6bec6221fbb5eeebd67debf624cb61229389e9b64afee13a2ed2dd11aee255be16bced0e4602ad94e2d1dd6a1bd05b0b8c716b91235e5f4ac2b6816eb8b5505571a49f1de91ea79a20e170decf9d58feb8e7ae1a77497ddb0eff4a4e575de6614cde5f696a6a46ab62e3e9e09e7de1969c0eab9ac11a0b2f46fb1d9cce9b4a443d2414574cfdb3fb787f765eea9dd296da2bc4e4dc5c633539648c2787127179515865a22b973492284907a511dd4a6ea09e69eba479141ca339e4e4add96ae5a0396063af1929b1c08802133c5aa4c46b26ffbcbac615df9fd88c2727",
            "2662750185474b95b838559f9edf9847cf64f4274a25fcca58280ce151225184dd5b5d7bd72537bc129ed8e7756caa05733f81890226da32bfd6ddb7fc403bff12c769168a19ed1fd9d6a4e2a78dd6d8d55e8663030df1d3461b5430faafb9d40015e762417eec8297374b70629c0bf614f170b88f88dedd5e449fea2bd57c3f52ae39d44daaed5587430a7d29d2a5b6800c8a1393367e1cb2b0b321f9e1a09f96be974513ba3b08dd01af99fcff61a90a33f3e49a85e97c32334b72da465f2cb6fe38f707fa39b767fa97aab52ad46ff7e2d3e9405d267cf89454776183eefad55ecc7fb3d34a62fcacb66908c9772824833cc693d11e73b57d1c27693aa80668fbb88ec134bfa55815b21bab83ca31c3b71483dda7a083c34014a8ba22c3aa08b5150d9166d50a797625e8e43c1059d66d1161148bb45027dcdf5c172fb6c7e0c6e27a3834be0ef6cf8ad53edf9754797673e22d4b85be52a160fba97f20272cb4d117925057c3224bd9cff26ccbc41c29a5f730be863e298834261d62cd48b36043e26f25227797381152ee4ece4e73266b3a9863567b730c6f6b478fceb4c4c66e16383cca01a3a38dd1bbae91767e9645e5caf635cf594884020fb6ccff4c7bfc27fd9d919ca24e1889c595f6e1d19aa03ec351ab730f3827a6d2e69e3ec4c4d8f89289446c6bc196fd1f1d2bd395ebe950471179b1c558fb8ad1912b5b5ae1cc347b74ac2bd4240b95da36064a64c914586062850da6d6586d6c89cd962a6c37b6430b6b639cdf1404edd7b6b8bad21d0f2fadc3eeb2d9d8de4b89ad25223c586680cd45227a7e224f1d682d4ca728d16f3e0761fae4fb4db21bee0d6a345ccc113fac1fe64f7a16a7906983ea9369dd3c49b766964fa33ce50b99bcd7e6ddf3b95f60dfd69d4bf1489bc68615ea726becebaa8fbd4c5c9a6802ed2e155e6fb18186b9255793706e590c76b611e2fc18095e95dbd0e4b2a3faf52a93ca033da5644aba94b4ad2d21b12e92574e86e2873672e1754b89e0ac9dbee8aaa7a9f899a7219fc4b9f049d74433ac1fe6ccf83a5368d75b02db6c70729ab96665a13e49f610f4d6177d746739fdbbef840313ed193bb0c5dec2f061425d15e9531cf8c6cfc9f85b95c4ae32c13a8194b8f621a3bc6792c9decb3413dc976b8639cfa547bbcfc5dc80d5280bdb8bd5a17b303fb00c65a1fbd0c7751c5ad9774157b7a1185b631646f94e47a1630f64dbb6c360cf49d81d7d1493fc1720cda200358cbcd13dd508735b5ba1773d03e4fa8ad1215881c5a9d6f4e27c77727869d2333f07138b2fd8dbfe13fd986e1e9fe91ba8e7f57c4c34674a43ef5b4979ba7360fcec14fc3b3e5612b2a8831359dbd19d9e90e0a89995e2a2d9d9c55d33b2b18526ab965cb37ea4b386be97ac25b792f0605b1ddcd9550f970f36c1a639c1e8d7488176410a0c8e31a5e766bb9151a99e4f2d650223cb5ff6a12cffbe3deafa8910263a53946081b958b0d9c752bccf52a8e76fccff436b8aabcf29d33734343ca41bdb77884bd0d41e351bba706996afb50e8fa1cd3c7d1e1a1b18581bbe7d0ebbd7ec1fd37f6bb1987a911b2925957b4ce8aba56ed83f2f8ac9d99558d0468268a93e0a0d0cd15e61848de636d86665879db68ed8a0b4446799009b5714835c0ac3b9f98e787c6305be5ed615bdcd6d31335d82f2be529c1a2b4759733e9de12dd0ba0aa4ffc7de7b8045756dede3439d5ee843efbdf75e458a58e84540b0000252ec026244c50e0a2a2a2a76454151b1f7aed87b8bb1c41235d1c4eecc9c97fd3b43c2bdb9f7bb25f77effe79fe4d3f33ceb3903330c337bedb5def5aebdf6daa71d05cc7ebfc2fd6ebd1a06eae9ed3512a992856501e4e3e36932422e4a89b4564a9ef694911b76e4c33e7db26982c683004b8e2357e5b3516d37be862a3194283f6bbeece55e13ea7c953a8e8f13e1042dcfd7ebd3b86f0472c40cefcf846065b119164633f074bd3645ae184bc80d5372adc58894a7ab7d7212b30f69b2d8e3590c56b812836ba5c757d5b210f358c1c6c6f2b9202f943164b158511c06e7b290a1d469a8ac200b3752c6e20c0e9e36aa51e48c83ecfdcd488cebcd7ba1cb626a78daf0ff68e3444f0c7779efe9fd265aa2d59a1cde581af3db0dd5056f13820cc8a2d18ee44ca31f79b52b927a782eb9d35dd7864cb49d8f290e8b24a56653a4234c2751d3ed1761a97b2b36f9ef478bff5ecc755d8152ab8934b61720cd200fb9a663d0df300fd9c6c528b59e802a87b9d814b40fbb424f22d3a808b35c17e344e415347a6d44b6490952f4f3e0cd8b8603c70fae826084ab27c296e381104b91f450a161e7c258cd835a2cf6172cf9dfe7c6aae84940aa338d3f914731644395e9534b1de1f76a4aca64698e896445ba0555e2a047550719634396050e8db6a2ee2f70c2ad4637cc1c608cbc283196ce0ec4a3fbc5903e4ac7db5321f86683332ecc30c0d22c0d14066852ae7a828fba6c95bd34fecbf9ff977ccdbfb747b94f2994f34b370757523a2882acaaf422171b5d4959b2611b5f5981eba4a3f3eff288bfaeb558a6a6a040b48c4d3e198745c03e311d460161d073f592ea38ba126db16e96bae2dfcc892fd7bfd7518cbceea53657287bb34307476a9cb1cc25140768fe7e6b911079fe5cf462f0315fac8b765d23cce36b60184309034dc538b06b05c8ebd9b8bacc02af1e6f42dbd4fed8169d8057d18558e4ad8cc35379d837828d65892af05267239f272253f54c489995dd7c31ef2f202ed798bd0e57e583ad2657de8350f67ab72308398157f71a70717500f68e17533b4bf8efae4de692fa0ceed7867c16df5ae3cf1b1713c657f27a877fd7dfa07bdeabdb1908",
            "eeea7259a463b9a1ecbb26318e8e1675e5fd2f4c56c7bb1dfa20a7cd7077b323ca23f9589ea440dd98c49792fdbae45e8b2e298957ffd658c09ea4c450b15357e5fdd6cf5865c867931013b624d88809139e0a06382a52779a4c41be8b94de5f6348bcb495076871387fa4792ccfe39fd5e6aa90999312c99dbd09a465a42d595462434ed4b8911f5a83a4ef0ff4963e6b8ba4c88d0c4c1de349d9320264f235fa9e1a71186e311147c22fa13df038b6061ec534878548331a8a14faf9341aef07d078dfdf28073d34fa22db705467b6f1b0cefe06433b53e99820d3b8a82b0658e6d38aa5b4ec0e3983b680e358efb707539d17a0c0a20c59c62574cc50847aa795a8b2aa871ac340b266a03699de4f6ff42f39ad2f3eebbfe730725f72cd54c4eadc355a2c7b777712454813797c6534699de9285b526288a9b90e5832c60f9ba778a3a3c1133ba7d9a121c70cbbc758e065b3072ecd75445d7f23140569626a812dd6ce0bc4f31d8e78b8d202fbca0c64cbfa8b3b87068a8f6ab3ff62445f7235ffda1e5d683963aea54716d4d5929777d652e4c15809b99b233db620f8bd095351ce35fedd3876fb40f97d91268b458c1c5d242e392508aa9a0d97bc229847f492699a9a132d8160b61687fd47cb49fea171e89775d19d965a2c72ae41537a653e074717cfc28f631761a51913575668e0f2626da4bbab2349918b24a100d94e6668a82cc28b974f40deecc38525667871af0a5b26c6e168ef2c909507714fc31deb4d0538388b87d6412cd427a9229ccfc370be9aac59cf44467ac693037e3d76b96b0845bffa3c33b84a6c322a4851223ddd1337da06a2319e8379e10ad4da38156a55aa88c45b736e98709885e622e69f710fa71cf3ffbe9f81d2c6a424f9be07f9fd9fd9d11c15860a193f405322dba3878e32212e4f53c7b92a35dca9d304e93041c70203e47bb1b03096297b349327bb3189436a07897eb2d6e654d3b8af6da6c3fdb53dfdfaac6785bf13955ffeef78751687449bb33e0d72615291962c3868a8a2af39038fd7e8495eafd2ec2cf6579dcf5352fda3f81a793dd707575b5372eedc090921e7a5ef77784a4f563848be5de026fd61432075714d0c560ff7c3b8380b348c754292bf112244fd9169988f51969369acde81694ef351605e4673fc511868528a0cd36118605e824cfa9e4573f938a3744cc87547b44118e2b58a3ae5afcb311b8e64c32198e3de844311e7d0ecbf8be6fe741ce0dd8ad6c08338dcf31276861d47a5432d92f486a0d4b2128d2ead54a828a1333f90fb21d65ec3fce7f2e42f78f2bfc831bbd122eb612ba0ae56eb62ffe400fcf4a48622f7822872cd1de45e34cd2716d05207f2722464cf4a20795b89efee0dc69421d6589a698267ab3cf1b0d115cb68ec3fb6a50a1bca021067cf42cb04133c5a638eeb730c65074699908a4883b5fa7cb62a83c1f8b22fe99fdba3bcb7d5ab505f0f72e7fa6ada1ef7caa8d7bbb0677509f5e07012559b6b27b3603182443fe3bfeaaff2fb4a7f37aedde7d02fd5a6f98f998fbfcc61d83884d5af85c7d869308aec2bd1f5f2233a56765b7fe1225fb0ff3fd3531ff9bebfb10942d9775bd4b1b3bf0ddeaf3882efe233a96d0c4d1ca834c0b5466d3cdaeb8db6c610746c4dc2ebaf4b3b097642f6fa083a169ae2f99968b416f9e17c743ec896b3f8b1691d1e2a88d1a6a68f43d3795895a68ae539ec2efcaf126a629b961e9ab5f53edd76f127177cc34e04696bfeb25cc3984d6315593b4e24f9b1cd1c9b52185899a84aad4d62526b875a92102b8d697c25159e9696d69f72bc7f85efaeefa2faf67d1c971e7233252ff868d240ab1db12982baa8a85fe703bafd9a9990c97c672be6500f37e952d726f171a75613b768b934450d6f371be0488d0e86b8a8a2a61797ba522920bb8a3824d286bd81c3605a69fef50c1fe5df882f7f39138aafc222fd1d9892d1beaa88325345baa32a6c452a280952953e99c921ab0671dbb5d9cc3fc21ccea085f83ae9773ebe38424ac84dbcfff131de1e08c1c9298eb838cb0db7db6331b9973942f5b9b06459c04ed5197eea8118605484c126c351663f03e9460528b6aa44a5632dd24d0a916a598874db22f4b7a3793f7dcfb618891e7ae178787b16da2abcd1d7c6123db5923afba9e72355b7b4ab1620c76c14fa1b0d458671011d3b1460081d4394db4fc7ba801de888be811ad7a54831c841bdf36ae908b36a62ada6b941f767bff55bb1ff0bdefce33930481e5e0ff0174a1e3798513b8bb5d09061806dd3dd7068913f4ead4cc6b62951989a604a554488b12cdb00f7da0681bc9f8b0fe7bc511ca48305a926583fc50bb72e5663677b25da4ab5d0d74c03394e7a487756c7c458756c1eae2d3d56664c1a06d82e33d3e88aa99583bfe8e0ef7d967c9dff6d78a00b7971a94c4aaef581f4fb1538bf6d381a47bb63ef7c5fd99955819df9fe6ab7341518e6ffe2fdba9d57ae2e874934cd6c3ea9f946c0a5575fd8f48a85614028a5ebe4daa9656df7565b28b4d0fa6b0cf1e5faa77cff2bb974733d791de503275d26d95921909daa1562a7a115b60a4c50cde4633e430dada9ea585fcca52ecfe2511ff698825cf401753910e4e346ec9ee58eeb9bfcb1a5d01317fa95806c3c4ac7d7042fd28af05c4107c70456681fc3c7ba6c556c1dc545a42e1713f8ea2817d136c517619a505dd2a26f4a5a6c9df7b9690a9d182adc47ce3aca9d2ff65a52a72668a17d108b5a9faa225b5be8d819ec603cf05748f367cb9376737e3f69bf949d544c7cdd879878dfc74999a28b5959f2be075d6b01ffc4afcd94c7445372b524afd7a9e37c39172fd789716f9e065e2cd7c1816a6d",
            "0c7265617a248fda9dcfc3fc44d5af2dd539a92a7fadb154fe0f31a3bb96ea883a934d2a82546553c394a97e16ca48b353c6685f25b86aa9c8f61673c8d92ac1352b0d96caefec6b7c94951912733d75eae6fe1499ec00cdfb0e8642f6e92964b7a6e2f11a47dc5a19864de5bef0d5e1c041e08364bddc2eac4f33c8efdaa32717797e7faefb326c093d4015598fa7fa5b1521d5a908bda3c62132b10afdbd87a3af381f29e1fea0a80db8b96516b6e4eaa2b1d0b2b3ac9f03d2dd7dd05b3719d9a645c8eaca151421c3b60471bea3906c9a8b44e72254b8d5e268cf0b98685f8b119655d27ac775c447cd2f8b1e417accc997dcff7f77758fdb447adaa2b0a79a84b45b514f179be2ec643d94b809b020560b63fd3988d663a12c421fabf32c30d45d0bd3a3b878732c063f6db6c2a4442dec68f4c2d9335998debe0a81d396605399210abd34b028de16abd3ec3021d81c039cb4a974279174426f7389a506cb87fdb7b6fa395fbff80d223f2cec1b7b6311b9b0b697e4e92a2bbcedc80491ccc3e945f6d84ec763c79afcf0ee6404b5698203691c65fbc4458f5b4cff8d3d2df2bef071b4d4d14e4518ee1e2e7f5ff97edc871c65361cadb465732ba3d154ee03e388de30e91923d33234966a70b9a9bfd4107ed1c33fd00bf9b9879e5c377fc196a49ff525b050675c3616b048b19baa6c53a92a367ab37189ab8df54a1a586a234063a60a560f6452df36f2a857bbac20bbe2818ff7c7827c588a43b3f4d1324409b3dd39a816eaa3c6c313a78ac6e2ba890fee89ecf0b58e1b76646bd0dc9f89bd63781816c6478ca200a902010a05eaa8d3d2c524354dd932b10129d2d67b4f077ba46daa015e1f0ac3e67415ecc95391ec1a634dfafad90fff257badf227e43fddd83fe653ea30d2993c648aac5fea6fe5786a4642c65373756ee7d5265dd9d50a36be99af8e775bf5f1ae5517676bb431d09589a9e15c342670a4457e0ca227502b16292a768fd57f1a0b77af0798180b99ef4c04acce0d69aad49410252acd5211d3c395b02b531119f64ab2aa7e1c72af5efd91ad1653f47bf91af9f80418096fb39498a4796e88f4c65c6f7cb3c2079f0e78d2bcee387e78781297d6c4e0d6525f14048b61c6b2e9da9b97a837084516e3b1dcb715cd413b30c2aa0a7966a3b137bc839ec34ba904935cf4772e4544da2498ef3d00dfca85e8eb560a7fcb9e38b1b90f64e768ccf87a2a6d17aed857648327ab9d11e6a48e00760232c44518605884c116c3916d3e0cf1216548f418813e7d2be13b7012c63a4fc3b6b0c318623c5cdae4de468a4cc76d57637ed6e72afc7f85ffb56a4c25e265cc918ceeab8169291a6819ab8be503b550ea2f42b8be16da8639e0699307ae2e76c7f64a47e438ebe042bd09e60d34c283c37db1655706c6ecda83b3af29684d58878d333c302a44888a400bd4849b605aa829e646585165be66b2044b6d6479b9bcb0d652f755fedb78f473cfc3cc642b289055c32d3e7dbdc89e6c9e60dbb9a13a926a9dd643b277aebf6ce3745fb4ccf647cb64674c4c35923ddf164aced7db93a9c51e9f52e382dec6c784939a9953c9e2eaecddf480cea2dfefb997318b4c1e68485ddf3d02373666636ea6068c42a324fa01a144c7dc6aa916eb4bedccbfc19eeecbf3568fe4888b81b1e243c1bdbaf7fda7c8d796632cd9d285b12c6c2864e2ae9b3b4eeb5ba0298b897989aad4a3a57cead93a0d7c3aed04c9d5509afbb783fc3818b7375a62797f15ac48e4612c838d62862216d071c354651e16b2d57141d9022dbdb4b07f1a8f7e1d0b1d752278303948670b314e530b0b74f450a7a983f12c912c8ac5220b2bcc28722f1587476a625ba692f4e25742529eecb04aa8a4fcdff0d83f844d90a48df2fbc077b95309c99970fa43d290dfa2a7eeb99c293f572eaba7baf4d53a2dea44a10af564ad2ec8390bbc6c3344a99f2a268630d1d08f8fbe56aa544e4621756247c74b7f07170fc67fe793baffef48168345921cd992cb2354303944118b6314b12d43096dfd9550d353912a0e65935b751af7ccd558dcdfd1e757d00f495290b1e4d3de10eae0686bea6abd0b3e5ccfc38985795896668eb2206d34679921d6511d5efc48241b0c46aed918d4d05c7fa1d75a1c8bbe80f541db516851813d1127d1e8d78c640b9ae77b8e40645a15dce7ad81e1b113f08b88c1c10df1a06ee600571341cef7c4de69fed8536a83d2de86746ca08b82be3d91ec138b28c368840b1290a0918781a6c548731886988851706bdb8b30fa5ee3b618a36d26a3ca6e2e35cf711d9c854e9e5f30e47f9507928b9383b6ca59aea20aa26c05b229b4df19ec29c4f868350c0f1561769c18db879ba1b9d402af2f846359a63146fa68e1fc320f94856be2e2044d44578f86ef991f11b36a1718e35a317b613acdfdb934ceeb6025adebe6793e9891658e620f630cf3369215f9d991cac4cca7165a5a86acbfad53fbdc7868b75f96afe3fed8c3964fa6a6ea77fa99703f590955a5d65c06f1d6562209365c32269ce67bf99654cb14775cdb1e87f727a2647716da4aefaf74edfcfe402279757e94ecf58366c937a76691259307929699c1e4566b5feaee916938b9a502cb0aacd0982596e9999943cdcafe274d01df58f425efff8f79ffcf7c9fb398a19bf54376e9c1e72943677c13916e712d3849be16dd5dfb27dfc6fa93ab98456a7a0aa8a5592ad818678875f15a9893a88c8e2a1e3aa6327166ae0eae6dea83abdbc6e0f0b2145c58ee82573b8d685c57466b2e1f754a023471b4b046cd18939538e850d0c372230dec1ac5c18c7eaa989fccc48f6b84d85026821b978324450e06d371420a8dfff9114ed8",
            "b322827a7aac376e2ed0c6ae81cab233e3f9d853a6f98db9882d64a8fd21fbccfc96bc8bfc62dea9db79edcda806eae3e0aaabafd34abc5f27e45abf764c0a9686847b91c030d6214670774e46e9977bd7de225a7d9bf98aaccee52334a5dfcee2e3281d9b7dd8638477172c91eeac005f6d06e2ad5411a8a7044703635c3a74514a5e822c9fbbfe8c1e5fa8c2707757fc2ffc28cda9190f75d8ecce8d4338b2ebe354b13b5b09bbb394b029959634252ceda3289dda87490e4c503f2166b31508f95dfc8dbc67fb198e12a7b331df46fa70be33aed4b8e0f2eade681fe581619e2c78e80a602a3080bfb108be867c04abf7ebcaf30f311d8524fd1ce4998f455be8116c09398243d1e7b125fc0096f86e4091e34424ba14a05fe870b836b5c266df01040624c1d7dc1015f14e681ae98f47db7be0d9d660b4d1f83fb487019e370782dc4a0191acc6e3e7b7b1a9792a0ae263106e988038aba1888eaf80f9d33bf099b804432dc660b8cd24e4988e9234386e249906b96bd498cc2ff9cbff1df638d0724ec86060b097b2ac225c0d0bfbeb51eb0bf47064b2319e6cb0c68b7647b45559e1c3dd38dc39948e6b7b86e1fa02672c4d51c3f63c2eea57a68071ee4728ac3b0bc69a7398b7381127268ae9984103045340c85290c75168ad30a2122c749069a7f3695a4202199792bb4abdabc5ec67bbdffc2f7c454345f1b5295fb592f5730d80393dab6d78aabc088e12f32b91b2f24523ae328934e790197d35a9ba345d344f70c3839d513836cb96da38d296da312709fb1787e1e0a22859e3e864697e42009591da0b63074662cf2c779c5fed8dea245d6988398fe80938851a4ce52f76f3cfb1a7c7e3f4828befc74d209d9593873f4dcdfb477623ef71fe9d931e97b4e4e95373a3b9d859ad8b19095ccc8da1b95f98229a8699e3e9b9fe38be6e188eae9b8647fbc3b17ba208f5b1ca981bab8acd455cac5013e228df1c2f75cd7085ab8735761ad852aa8ab1c1ca989fc4c4f92a0e8e95b3f166b33a6eac37c2e2c91e68591c8d53db8bf1f40afd9ee773693e65805df94a385dc197deaad526c363741395febc67a3c875208fc198a46ee785e75f3593eff26b5fbdc89b4c5e658f25a4369790ad79844ccafc5a9a10e3f33e3ceaefff5e65f162f72756da5c726aaa1675b18c876b953c9cacd345721807732a7be3cab919d83081c636630e0c053a58523d0da7f65e962e9bbb8ff40b8d8bfb0fcf2aebb6e146b6029b0cf2e54a9fce62e302adb31d0355b02553199be958efec282656c52b7c5a3190d3d954a8be5495f1bbd5ffcb8b407f301209c8fa5c1beaec4447dc591388d5398e48b6e7c24de48d49968d88d7ce8221d304ae7c6fc488939142e3be7c8fbebc4fcf229f666c0d3d49c7008730c9b90e03cc4a9062558034e762f48d1a07df898b1058d5881e7e8508b00b456da9236e37ba617fb93d166658e1fea6109ca871465e8001ea336c316f8837d68d4fc6d9cd35a0beab07b99d858dd3fd1036b81096a7cec1e1d42944a64e41ba652106998d90d70952331c16a3daaae1a3bdc0daf6671d04ab32bed4f8fd47eb5574fc69a7aacaf8c9df8a43ce347b51372ecfc0d4a15e08d252c5005731867a6aa1d05713b519a668cc31c3a1a63e90bd9d8a77fb83f0a4918e0db6b9a3b5440bbb97f981f1440abdf357306d4a2f2c4d50436984268e3606e3407d3c3696f740c742779093ce6819674045186853656181583962ea1b0f330b9d9f5b4932b83a0c4614f3f382a4bfecc1d05451b156fdd73e269b7ef94b471d16593a509f6ace11636eb619daeb83519be785f36d63b0b9da0d96fa0150f2dc80d09aef30e7f63b38c49e009b118dd632636ae73427126bcd79eaa9cba607fc37f50ef81c73fec1dfe60c7ff76e7235212b97ad79993ff2977c7452776cd06d3bf2be686f032c85e4f632776acb505d54f7e161e90026ea7b2b634e6f26de9c70c3d6725b4cf464607a082d3d3978d51185b609f654968902368fe661b59d08cfc4ce7869688b4d819a681da682f1c12ad890cbc1f5995c1c1bc7c1d9c91cdc69e042ba5f0c72dd01ef0e39e2c1d18138b5720cd62605625132137b46f3a4d7a6f3c8c1c936573c4c347f4bbff63f832efc1e4c6ebbf968ec8a238f462f9ef374f4acd53f4d1ed9f8b6bc74cbdb92c29f48eec0ab5462a25d3a433597c3602cd756604ce277f5c96220c25180db33d5a8ab9502acc9e2a1a7bd081d753c10e9229a8f7c0f7231005766ab23d88287b29c22b4ad3e225db7707fe79821e5ab3499aa8a8cafbeeadea7a4f81bb05f7e9e3371d2e5492f4fe6e1e56a6d5c9b2ac4d67445ecc963e2f2040eeecee061595f45c9d9399a243f5a94f33b521e77f9da88838e10ad39d63849fb8ce6027bf4b5e2c347d403ebdcf6e364c81d4cb659007bbe03c234a311a99d4063bfbc2f7f4157adfeaef0936809de8702ab32241be520d5b200c9aec3109958018fc60d88c89e8460eb0cf4eed90fd74f0f02f93a0dcf76c7a2bdcc1583dd75d1dbdd0407eb9d616d6d0d1d573f4acdcf9bd276758493851112dd2dd15c168253078663acec6bb81cdf81909062a4380dc3008b5264cbd7050c7331dc7aa264896b1b49d61bb080abaaf439fbadff6a7ded977b9adcd44a7aaa7fbabf3200cf2f4ec39b3dc198112d8297980d57733db8b838c2d3ca043d2d3490e3a28ee9515ad8586481f31bd3f1e1fb02ec5ae082938bed91b6ba0a7332cd50e9cdc4981e226c1a6f81e111fa54b896121563c8429c190ff3d3c490edb547cb281df4b2d0a56667959358afb07846574f69a5b34642a6c4db8c6fc4fabcf5a2c8f8db3d7dbf5ebff5a1e5b5ab1e9b3a39dd8eba",
            "3ec7060d197a585e648cb21e5c5ca831457c5c3a14e3dea2f539853db73f40d9700714f8cd305473a7cece36a7868488bf93c71be62a7fe3bffe619ef0731b7bb2b16bcd79da8bc29134f62fa5b074e1881f330be558f4ebb374ffda334599d19911ac4b3d5c17847d55bab8be549dc66255b4a633b18cbe3f58cec1ee5225ec2f15e064b93ae6f454c4ee0966f861bb1526f92861692e0b5bfb6ae3b2ba17d6f752c3867c1564db29a1225011eb0731d19acba24e5670a86fe6f3f162833aa8c37ab8d4a0894b9bd371a02c0bb7474ec719d73e68885642fb489ee476ad98cc1ae43882abf8f3baff9f7c7f4df79c17dd9fd316757fdc729d2b654b7efd7cee31df28fc1893f161658c1b5958154c0eee98475a578f2143fa99c29bf639074b85b8304e087f23164ecd510739e3819b074750cb065b53e34358d840eba9dc9f81f1c3cab17ff30949f9a042921313dfa82750ff4776a9f04fb0dfc35a83fd469bc5a1da467229c97613fc74cc0f6746b37061020fdf36a8e37183481e0350db87b2706985de3bfaf5c6bfecdffd3dae68f9be551f4335d9de523bec1b4bf3706f75b80b3d31deb41eb36d576057c079347b1e40884634fd7b2f4469c723c3b000297ab9f23a3f1cef7d0523ac2723d93007d996a548752a46af1ec36173e4289c37b5c3cf7b081213a2f0c3b37574acf51417dbc66144a829ac4ccc29359f00088223e11be10d9bd83e502f19049d4b9b298ded0d94fa800ce885c4c0ccde16f15b976116f9012b5664a197a71fd24c86a38f411cfa680ec260d391c834cda7e6b8ace81c6f51fba305d7683c4b9191c3e8aafb147e89017e3bffef414fed4ff66aaa3857a94d6d1dca4759881a56a66ac1d5d112b6c36be130a60e3e950d702b9c0083c824d8b87922ccd600590e22d42559a226cb0a1d4d4e58334003553102ec9ba04f914336585ea087aa08118e559b6264801146f89922c2904ff31b7dc8b659e3e8641d54249b23d8d3e9474b5d1189f2129093abdda5c37a8b433f537dfcbb5e3edd84a18dafa040ce2ff791b557db21dc4a041f336d4c4fd6c1925c531c5fe40d7ee611d8cf9641cbbbbd93ebb10266d50fc0d03d84d24803d9ea42319950d8e38e9da1b16677bef4efec45f1338da5bbd7fdddefc666fdf87a6405210be62ffcb1605437ffff755cc4ede9c46890ef2f4bf0144b5b47eae2c7760d74ccd1c4a6022e4e4ea2e3df220db48e14e35cbd11560ee46063060307c6f1f068059bda319c4935c6b1b13083853d6566688ad7c6f2c1cae86fad88625765d4676a62ed30356c2ee660733e93ba309d0bd9615d48f6ebe246a33a5a32d9d866190ae9a65dd8a76185c64836b57118b7f352ade5fb5eee86e6ff408f7ff63c40f763d6a1ac2c155a4f3183748c7e98686b247b35626ca7a42e404af689a484cc9510f28d8cbc2bc6b1460b14060b1161ac8cea049af75fb0c2e27277847355a8180613f9aa66c8126b6288071b8b6734606842aab43c3d8b2487440e60fc7cee89dc0f45d262f00feca11bfb2d836cf9dff2186c523b544d464e98e0d3bd0178bdc7092f56aae175ab2e9e2fd7c4d3460d1c1bc196de5ba84146f7e6b5f07fdf9e35710cfaf3865a8aa437a7d9627db619bc747590ab5f8172b35a8c35aec146af43d843c700232da6c096ef805eda89e8a79b8e54fda158e4b31e1b43f6d21c7c28f22dcb91615d8cd8b031f09ab91c06d2ef6074ec08bcfaf4c6a54d3d41beafc6d94d7390eaa00bb1ad1bd4d293a1d5560f8da62aa8a5a54033391e6adbe640975c8731b909ed1533a09f980cddd844f087e721e67c1bceacef87bd13ace1c4f44772881f4624bb239013d7d94794db39da74261a6ddb49885a34e9a71f4f6adc977488996a3c06e34f59f7f2ff775ccdd3d2623cb0d66292f619e61479de87da5e6e4e5586e820d54508a71c5aa71317237ede3a7cf3ea4de7c31f7e42db85db88ab5905bdf83ce80746c2d1c60291a67c0cf1e3a1c0471b47e7b9e2cd361b90d3eee86809c2cd05e678b7db1ea342f4b124d60e4976628c0b51c7a53916d4a76db614b5d500cf4ef4254f9f6ea168c245bdbb5ef029d080eff54545ffd8177ef5b3ee0e9a085824d243fda3a19a364a4b6a3060c044447adaa361a00e1eeecf47f8c8a960a4dc07c3e902b447dc80dfcafd888aafc0a46c7b9c9eeb223dbf36966c59577486cfe498fe1dee772f4114d30c6824ff6ff9eee7110330ba62805e7743d35ebd2d2dfff8b1accaf456cf8c2e9f2fef35f7cbeb6a454a4c9219c2939ea853c3a92a1af32b7838399e479da9e253b7ea85d487c3167873be079e9cc8c6dd8eb5f8eefa3648be998493733d51d3874fc9d7842b4395f0edc15e5849c7dd39cecaa88b52c19df604bcbf3110b71ab571a0928b73b5021c9dc4a37fd60439a28d8e595c6c49e16205838df9aa7c343374b1264e205d3b8485fd533d8fdae8a8fd12cbfc9f8acb9436febc1f4025d7dd5d99fef94414974dce2ecf9592b52ba94f4b68bc3d188e8ec61e589a6e44cdeec1c6f6513a385cab87e6e9261439628185a5e6c860a8602e4313abf91668605b6081c013fd4cecd0c33b1863533351109b48996a6a7d1de0e4f63a3f7b089954369e548e1ef73226b0c724f62f8de67e15875b7adbf2bfe6329449f9105d29b9eb04c9b31248bf1d02e9192f7c3a608ad76dba78b14a0bcfd7e8e26c254fb66e30075602153f3d35feef69578e2a0c2e65adc9c7d509a6a88dd7841bcf0f597a25283799831146d3d1e0d4823d81e7b035e014a2c4fde0a71684583d39fee76286f342cc715b8e6ce35294d9cf429a553e7acaf7fb1d3b09332283e69bc728da3713d73645e0da966c647999",
            "50fa8e9e9441727f086b4643179760446e40bfad01dc210994ee8d5d9405ee23182f11facd1970072641737c31d4a78d84eac41128c80f86b4dd1f93920c503f3e04e47101d697d97696c67b7766faf646914b01956c94240dd20afab8d5f71c196458b442a0aafab9f9adff164b9acd84ca644981b9f44a4b1875fa2b23a43bb160915182d875fbe153b510575ebceea4edad4b5efef4137c73465106097930cb1a09a301a36010d31ffa76ae08b5d1418eab0666c61a63d77457fc742f99f67d01a81d6888541b4dd4445823dfdd988e05d4b0698898da5b6d45bd3ee60bf22899c6feedb2c7e79775aeca0f7f64251288bea8e75fae0f14180b0415f4fd6372bffed8b2ad0353263662764d13260f31c48df60c9cdb3f0e99e989183e321df3c60562c3284bac291663c1605334165ad37c485df6a835906ca90d78e664c82b65fc5c13d47d59d1f283af95f87da88358ff17fffb39ad0574734ed7eb41a91d6f878e3efb22a348e3468fccaef1ff6515a04da4c0c485a5ea72de89c323b938318e8393e51ceafc642ef5749526452ebb82dcf2a7e7771208918248af42763b1def6fe6e1cde50c3cd846eb658c2546c49a63b8bb2296462be3588d315e1f74c49278058cf556427528139501aab8344b8875f91c744ce353e766f1a8f63401eeb0ecb0836780157e7c6a4e92f2876d65ce645e49f03c0d15a57fb5aef367e52b8abf5acf707052d191c69aa8536f9604809c3c80fbc7a7627e3f4324aa3150ac6b486df68ec4468606a6283370789c29762f71c5389af3bfb1ee817bfefdb045dd12abb8e658c0b4c504b1338a920d10686d8300470f54944c217b5a8e931feeff40fb2522fdf0fd27d2b1f71aa91a31799f858ebeda2f9fc9db5287ff982fc7fe426b29f93016d2f7ed907e5c07d9fd14c8ee264272c61b6f37abe3c3613b3c5c61286d4d5324e9f62a6d3a9cdf75cf7af7ffddafc860772e4ad3958c08d58417a70f7a68c4a0d8b00a634c66a2d2ba0e4783eea0c5e908e2d4b3a1cf344100bf2fe2c5d928b1a8c470cb4998ec508f0afbd948b6c8457ccf71709bb10cb6a72e22f8c10d8c79771d75af3a5036ac274c6d1d61d62f155a4971d0d83e9f8e11eec2ede343a451afa0316318bcaf1d4524798b6ac95bccf8fe3e14cab3a17777370ca497209c5306a157005ac7bb407224122f8ea5e3f9d51abc3fdc178f36fae3d91e7fac9f6c8a484b4738f05ce029f493acf33c44520d3287303e3feef29f5cddfe612c3d1b495582dea7a9111ad4085f3ec2ddf5507af82ac266af44d5be73f2be649d1f3f493a651485c275bb613b762ee5903f81324ace87714a01cc078e86594e19f492f261e2df031e9606e86f2340758c31e6679ae168a53eaed418606ebc2e62cdb53137511b1b078aa902171126f5d5c3bca14e68cc7196ec28ea438ac3fd170b55bea46dfe851f540e0eeef282bbcc747449dbe683d2a54d3bd0bef508da77ecc6e20a079c5ee68fa6b1be68c8d6424b8136a6f41520cd558074173e66651b6155b9034e3585e0ce6a6fd9374d8ee4ec3c673221c3f099b301bf5d9bc55d2754567d6e676dd37966cf34b2a8d8a65cf96797f1b9f508e8ee39abe2ce608c7a1c3768c183c80cc7cbe1492a8bdddde5bfdfa6cf65769e6a50975e98c6c7e63c369a87b0b12a9385d5596cb415d19cbd5a17d79b1cf1f4f068bc7d7496228f2780dc0da3a5071d17f480f48227de1fb4c2cd7596b8bed40c1bf3d4b167a2001d554c4c0a514173261f6b699e3f379c89531379d4aef13c6ab4b732b5672c13ad699a38666b8bc6be6cd9cc789ad36658928c10cb2316ea7c671311e7ff4aed8612e37f9e3fefee666e7ec59625c694019ed487b5eed49b6383b1295e1fc3b419982f3607d9be03e4dc35903135f814d41b1b186a98a9ac8c0f3db3f062e0584cd3166328431553958d51a06a8048050db4543a63646f3514a797a179c166aa63cf354afa460a4864b8b0f71ab5bbb5e3d38e0de7c8d431b3775aebea0de12972de6933596441a5b9943c8984f4dd71480981ecc33e50cf06817a3410d21b31905d0cc08733ded4966c25aa3240e99d9d26cb464395f77beae7573dc6b9c4d35040859ae85041827e08508f40927830c65bd4225f7b6267a65901c60e1d89cdab8760cb0c370c0ed34388662486188feaea0338dd79112aed6b916c9c83fe8ea588f32f85934f1aaac78761ffba24ccee580e9f4dab28cd98ded04f48a684f1fd60d9de047ff206bdde3cc1467abc7c36cc8365e354cca31f6fa625e2e05ab0d74f8305b90f77f2046e57f743b56f2c7a87d8e1c854774c8eb6c4a244135c98eb8abb75ae5892ae0f77a1354a4ca6a1d87c3c8cb8ba54ac763ab5d5e7ccdb707184a30a43858e19bf52657cd9e3fc3ff9ff575d39c253ae663cf2c3f914cc8ad7235c06034955b5987ded095ccbeb71eac7f720a0ba7a931eb9fd00eed35720bc611315b27807e557df02e7f2b994058dff26a98530cb1c4e59e59453a69923601a16036f2b7d64390a511d678c3d13ccf07889096ae23490ecc8c7c4080d2c4e14636694266684b3646d05bda8e545f96fcdd5f816822feb36ffdc17fecc4b6be44d2f674ea9955dbefc1d16d46fc0fb0f52ac5e5283f65a3b540f30c7f4040d0c0fe521d4c112de0e7e5488853a1a071850af3b526567e6d8cbead3f4a815e33d71734b04f57abbb7f4d2622f7266433239bc368ab42f4b241fbfab97bc3838a473df44d3d3569aac9ffb137e8636f2abb567cd43c1bd43cf85c5ebb78785c97f3e66a1c9ec6c486249eac2559062a90c4f3555380b95612750862b7defa1a5887e460a18ecc0c0c43015340e32c7d1992e78b4cd0beff65b",
            "e1fd0e75bc6b17e2dd3611aecf53c7953a1d5c98a381135384b45d30b1a82f1b37eae9e7961a839c31ebda5750ecaa84fa04168ecf31c1c45e4ab2e9918aa4ba8fde47677db552d5ff6363ffabc7625a9c6909a4e5a1962293b4ccf2a6e1f624a87b79d49da92c3406ab60288b8deb4a42bc8d4c80e4ed7b48689f453d7f042c5a0f2aa9043f96cfc4424d2d6a2243091395d898aca087d12aa6085260625ea10df68f60222124062be7ae42ebd2f538b8633fbe7bf8040faf3ec2ae0da7b06856abaca17a03c98acd234e464c72a0ce4826396c8b27ab75f1fea80d643fed860c804c7215d2975320fba1127898883d251cc9ac3045d2d38c355c5df50f71c656f7d8ce5163f2a0c31249a3351310a4de0b513a7148139522decb07c77767d07eff35c8cb563c5d66815315f6487031416f8dc11868548c41c6c331d6761ad28d0a91615e88785a42ec7c7065893b1eb706a136db1206b3ca2861d930e82caea684e386423c61184a64afb184d64d33a160d23403ec84beb0a9ad84c9aa39502ee90fefab471180572896be41fe8b9b5029ca8229fd792e2ef2c0d9d9ce1816a08f0bb35db177bc05ec397648d0cf43adf3122c76da040fa13b7cb4bd659712ee9162abd181ff803f7db9fee6fc12069955e14b9e6c8d7ceca7a97c43455989d41c3b4be5b79f40c2e21674d021f0c59f3ee2c1470a452d07e0356b3542166da17a6e394d85addc8b90fa8d089cb30e5e550be150520dcbdc0a580f1a0b9b41636045df1dfba521d444844c276d54f6d1c3e67c3d548669a287090743fd04545b9ea174ef9828ac2ece216e46bae9dcff69fb5faebf9db753e53a1b55582afdf6e147b46e3c863bb7ef43262368983604777725a13e431d83820d90d0278bfa6a6293746265136c8cdda48b47b8936fb66591953962b23ad7082bb374a54bf2cc707ab91f968e72a6be3fde4bba757690b4a9c29d3a38df9d7ab8a30fb9b1d8e96d3f4f0d63c6e7ad975fd7fe77e741066a319924dc8449ad8c67c98a3c55e1cfe120822780338f0d4f0e1b53d4c4c8116ac24f59083775050cb26320c188813c470666f66263ef48011e2c51c3776bd571a29c835d392a38308c89f393f938374b8845191c34e570f1f56a4d6c1e2dc0282f6534c431313d9e8b297122d9a2de2c5297a4fbcc5c8d1dc4faeb9a9ee257ff77e67b082d5b8cd4345f44fb05770e4a48234392d249efa01eb2295946589ead89072dee78b2d408c5360aa85264e1ba401fefd3274076fc1664723efefd737c6cdf867723ca70c4c414f3190caa518543352871b1916982a92a064867f0717af754bcdce98610532122bd7b604074124ab3c6a2a9be155f5ffa161d7baf61e1ec56d45536c9e27a0c906e18c1a7be6bd4c1d5991a78b4c2807ad9a20ec9191f5034b6c9283aee204f415e14e3f0389ea42946810c70656d10ff7cbea6f21f0c03860b551589af2840da47270d6eaa61480875c577872321dbe3810f7767d331c05bfc74340ed767bba36180113c046134fe9720cbb008d9c6255d67fb0e322d452fadc1181c6a83d75bbdf1685318c6c4da40d82b82122df80ac6e406cc5e7640b46802ec164c44d6f59330ddbe04aa831229d1a83cf02a86819b954229f7ef87fe578f633eadbbe3b4643dec804a5e3a34689db4d707e1d5663f58686aa02c561ffdbd4dd05394854ce37c1498956167d099ce01fa4331d1672a3095a0a77158a381aac1104d0e475ecf69fd2506f8cbf757a2dd198b616c7cc599c6e19faef6274b07e9cfd45452dac2653149c399b3b2fe6b76a1b8ed003a40a8d6e71f31f7c6332aa46e6317defbcfdd00ffdaf55440cd5a2ab4b19d0a59bc0dc10d9b28dfc53ba8c0e623f09ad604d79133e1397e1ec296ed81556a21dc2d7490eaa8854c371dcc891563761f7d445a6b9178172352191f25b1d4100cfc0c6bcdfe934b7e26e04103811a99fad574d9c3fbefd171f22e6eddfeb62b3773e9f26dac9f198e69fd2d11e6e68b31e54b64f3176c21c372279250cf704a97a7467a7be9bc0a30655fb05457be69a7cda6226c85a42c4a939adf5f97da54698df565d6f8f6501c9eb4076076be075e3f5842bdd9e9474a534c83beaca575e53fe4e7fffc3a0e2a102933d1db8643daf335248b534548d6e52141244498808b0e5d2b6c14ea2345471167696e4f9e2ec3993a1b8c0f5044a295327cb49430d44505cb525469fce7e1ec443e8e8de660ef5026f617b070679e0087a7f1302a500515beaa5895c845f310015a4a84b27991aad4a642d39f6cc5428f5f0045e59fe42dfe6cbea97b6c67ababa890017169e4f8f6e3e4ed93d7f2794ebd7ff18eba7aea1696ccdd8a8c5e49d4207b36b5a754448d7367a28ee6f55f5bf882244ec1a7469af34f9d8977a65eb8abac831bca22bcd233c1119e1a563014a9835c1d9c5533c3348602ca3d6cf0e2ec2c9c9c604c396931e163ed8010276744b9bb23c2270843d34b71f5e40d1cde761215f9b5e8e1e48296814c9c99a081eb35ea78b0489bfabe5903b26be190d2d84f3e5d03f5200bfbc770259b1214484518f3a23e9725df97f647aa49ffcb3e165abe35e3eb77f6564ba7bc4d6d717e953f9e3479e1e9060fbcbf340ca7578dc7f4543394f4d0414db21e82f4ed112fcec5209311c8302cecaa038c31e80b5be5084cc9b6a3de6ef2c2375b7ba134ca1a6a416194f6c67ae8e31a4c24b7104bc71296ebea2846561c78fd13a0bd6636c2df3c86bbe41e2c9f9c84fe86f9d09c568cecebc790fddd65a8cd1d0fed9454a8f9f7c4ae2591d83ece06c6aad6f0d0b146906e00d20c0a9169340ca9067958e1d58e42b33198645d87ab7d5f20dd268be4198c22b50e2b486b",
            "62fbd330e320839fed987ccefcb23bfe9cdf7566c83c2f1975368a4ab163da3354d476301515c8bc8387a5fdd7edc3b8bda7b0f9d98f587eef474c3e7b9ff29dbd86f29fbd9a0a6bdc06b904cc6da6021bda28eff96d9447d31e84eebe088f957b10b0683382ea3620bc693b7aaed801df294dd00e4980239f815e963cb868b03b67c4daa230ccee011d11ef555366787fc1fe7f689f7261322ca2da8dd5b448516e013972f09cf4f1b71f719ce637976e3fc593f79fbaf07fc9dc2a24fb889095321ccbd71c96cd9fd74232924b7eb2109b0c653218313a4a8c72cecfe701c92f395d949ff9bc844b53db482b7ee794beda54439e19968c72c684583d2c9a3c10909ca6c88d5ea430de38ec0bfeff53fe14413ffcc6db804bea52c53416e9a1b7191b6e2c1666d86b6188832906076ae0e0ca8178717d2ecda158d892c942868b2a7c94390860f3e0236221d95a05f3fba9e2d0281e3a26f070a6928b67abf920fb45f871b30636e6735117cd465b9e10ed250269f3200312e9a093c8fe2bf6cbe78ae199c07e9c5fea13fe8c3140f79896d2a044b213b2a4e70fdd979ed87e9dba72f426debe7a43cf4929ae1cbf86a69a95a8ab584c63b52b92cd18a87055c566b6082f5dfbe18c5b18f609b57043c5084f8456b8c137c27303537cb23487c4ce18378db47047ac476d656ba09cad824b75563834884163090371c64c643a2863b09b2a723d5431c455093d4d98b0109b61d18cf958dfb80bbe6686d4f2741e7561a21aae4f17e2eb396a78b393c6ff2ba120cf26e3f5111bb4e4323fad8d552295e1ac7b867cb68990f9873ca3be1b0bbed2e3f188a9aa8db4768815f60db3c6a51a173cda108a5a9a4ff86b3311ac1684006114c44c35d8088d11a393860c83220c362b45a4201d0b67c461488c252afb9be2f9ee207cbc9185ea241b887c0329dd357360491ec0f5dd031448dfa2e6ed334ab524035a0bab604deec24e7a87d2ff7811a6b80907f2181e0fce8337af1c8cbc546827a540372e1906919138dcd01b8d038ce0ace685de3ae9e82dee2f3f0fb873805151679ac1509459cfc4388b6908d78cc41cbb15d815785e3ada72a224597bc087cb09cfc834a7f90d9aaa5d1966a5a4cf1bfbe567c6919109e24fe4c348d2516d7acd5bb7cb9334d306482a56ae95141fbb41852fa1797ded1a04cf5e835e0bb7c0b3ba89729dbc045ef52df068d802ffe5bbe05eb31e5e8bb6c16fcf2544dd7a81f0839710dabc1f1e33572174d51e84346c84c7a42644843be1ca22533cbd5320dbb420844499b3cfe87259020b8bff61fb5faebf1d8f50b92f0cf18e96edd97b457aeffef758b5763ff61fbb858b777fc08357eff1e0feb7e8d7231a15e50bd1b2f9b46ceedc6652925f75c7526ce4f81bfe8fdc143e3869b150ec2fa2d697d3767fb41f5e5ecaa7a8174d9d4f5abcdf0599724cbee4cefea58ee47d14eaf558aa94bf191f2393d571688919be391e8a1f9eb6e2f1e30738b4791866667130295405637bd078cf176287d80453357490c015209a2d808f9085044b55ccedc5c4f1721e5eb68af0669b3abe5924c4d1916c2ccbe276d6a770a5fb476a90344f718dd6cfe7c77763bf3c3fa17da9675cf59dd044dbab41b1dd398b3f5bce5fc3c646efb93e8f8d19150db2350b0e60cf86d3e8d873191fde7ec0a7d7129a879fc792591b91111d8f2dcda3d036d21929fa0ccc618ab09baf83c50c06b62a0ad1aaaa85937c03ea7b4339ee9be0a38b111066835731ae6860aa608402033b2679e2f22821a61b0b516e2244852307a35d3918e1c34151001fd3a305d498601e9cccec6124e0a166e26ca4f6ee8f117e0ad4854a35eaca443ef5748d16452e9b809c35c2e5792caa265a45b2a8b70a29f4635fd7e5b0adf454f97f54ffd6dd03c694a6196f9c0c059d5b8a6ca82529e6e898e68ad13db561c536468ed1781c08ba890af35a7808bde0250a4484562c069a152151bd18a93eae907d5f0d7c3d15775a8371654318eeef8cc6fa613610bbfb4263741e22dedc4302798f6584c2d8ef6f43a13a07e6cf3ba04f5da6c41f2e509692dbf0fbf818bd3f3c430ff213fa7c7a05937993a1959c0476df1404a5f6c4fde591989daa0f677e20120d0622517f10d20cf3916154208f01e477cc775e8f5e5a7110b334102b4ec470d38988d089916cf43c4ab2f40b27aa31d99f2bd6747fe77439f6a706b165d4ab3a09ee8f24cdd99c75a6228efcb9b1f2e7124ac74a267cf38af29cd74a794f5f8198e6bd483a721e69176ea1dfe96b883972117d4f5c47fce91b28b8fd2d2a5fbe41d52729a6d1b258064ca639e9b087cf10b3f70c7acc6f41cfba0d18172dc29d4da1f8f0aa4e464ef9938d83b5af5b69b0598ccff3cc9fdfa8afae28b55d5ba8df39e6ab559295abf763c59a7d387af61b745c798a83a76ee3a384c2ee7d67b168c976b46c3a412d5abc8d9a3c71e90b776ba7eec8aafb2cd35ff72febcefd75e78c53e47af73560cb66f5d5c2b5355e208f86486fae4f2133faa9edd35255f92372973fcad55d76974d733c0c0ce2c88e940b7074b4080f9688418e5be2dd213a0ed8e506d92103ac1f2b82971a135bb58c71c2c8120d9a628c1369215120840d9b0563268be6373407b555c6c2be4c9ca3f9e5f1715c2cedad8203c53cd9c6624d64bab0cf99f35559c6c67fd3e3a47bbf42ff6f7bf77ff43c63a8f5bda441dd7df4ff4cf8af6da663f65c9fcf21e3f2aba9d6a547b16bfd493cbef97d579eebccf10eac98df8449e3ea911ba4837b2d71f866534fec1ea48485412a386cc4c3235b318e2973b058858d914a2cb4a90b20f1a16380302bc886f5c0131b136c66c87b31a5e1fe4267246a2b",
            "a0c2540d0fbc5cb0ce4e1793e91860ac171bb323d854731a0ba3fd1848e99581e28c12188b04c84acaa775c0c7b549227cd8ae0772cd042fb788d19ccb43853f5b5613c526498e9c639a6c0efd5db87f64bce9b669797cff3ac543a77367a105d53cd81a937ae9c086638d41066331dd6e094ef6b8dbd513205a33969ebffee8a9dd17fd44f9e8eb188edbbb83f1e66209de3dde8873eb933133ce025b47dbe2dbc54ef0f176022f2e0926b3c721fae105a4bcba05f5a5e5d0d8db0833720fa61f6ec251720f119fbe470a8df963246f91ffe187aefd8041d74e529cbc0c18272662477301f56eb31f46f635860ba727fa1be7769d43906158d899dd557f30bc6b1da0d0a402e11abd61c9338335d71a062c7d6a98d5e8cedd01973f7a0bfc2cffee7b7f2e57f7f7ed4d8bb45f98987af7fd2c8a905b92d7dbbcc8bc44f599babcaeb8487ef6a5cc2920941a77fe3e1546f3f88ae72f3187b6bb465a26d3328c96725a26d1329e965a5ae652141a2452347f92609744829540d7df643cfd0139876f2363d34978ea0ba855499a989f28962dcad441db50d3efdcf478fc2fbcf29fe569baf6f865b2181c12953553b67ae703ecd87e12c72e3cc4be23373bd7b71ec78d9b0fd1b4741b6ae6b460d9f2bd685ab15bdab47c3f199c5194f72becff7757f76b96721594c9f060a1f4d48270eaea8e6192e559bac4df88d3e34b7ee6dfe2bfbc9ea64e8bc52223fc399205d12ac87357c6844806ea062863dd50056c1da0885d253c3c5dae819a242e460bb4b1424b0f23459af0e17260c965c29dcf86af9003172e1bb61c36c2f45551e6a38235196cecc8e7e26419f7d3ad0667d2dbdd288fadf83ff664cab15e5ea7a8768ce148de567ed5f262f82f7d0b7fee69fca759f3a271fe9898a34a460dae946e5d7502578edfc59e2dbb1013da136ed60e48efd31f8ec616f0d251462f3103d3e278d4fd5a0ddc9fc9c1f3d56ef866566fec70a2318cc6f8190c05ac6228e12a3da69f32fd211dd3076f1515d191d8074fd62750a3f41988137030d28283332e0ef8181e8b454e9a58dc838d957d55a855f1aa981eca40df9068d457356348421e6c8cad112056c0caa14a5857cd47593f1584d0efe3a1ce90f53261c04ec898c7535061fc0736f87be382a7fc2ce03ef61ad4c50936589f630107756da4ea16a2c8b81215d6737182c6ff6dfe673150af049e6a3e0812c560504428cde98271a3de0f3b8aec71b6de0593234cb0628835eeadf2c6c7e3d1585be102917f24843109e066a4809d9d0cdee86c58bfbc0247d963784b9e2256f203b23ebe44d3c7f76896bc47f1871fd1937c80dbeda360a42763705f2fdc68ed8fefb7fa22c2da00e19aa9c8342ee8cc342c44168dfd69ba4311a3918a7893fec875ccc7aaf8353894710a69e241d05110cbd647ec265bfd4f5fb76259aa7e8678d3ad630b2693f1cecd98436eec8e9711c95e90b76d92972b0cc9dc148329bfe412e5fbcb8e0a854232b479b734aced1492ae3d41f58bd7382293e1326438289560fda74fb4ae245843e3fd265aae48a5f85626c1ddffc7de558045b5aded919a60e8ee6e90525a50941444105404050c4cc4c6001b14c54604bb50510c4c0c54c06eecee6ee9d97bbfb3fe3d20e77acf3df73fb79e7b8f47f7f3ac67866118f6acf8def7fdd6b7be8f3038c8be2fede52778965d85e7ce0b4c410d613a8e9f8359fd3580fb41ccfa241d66701b551261af32455320f75357fea6eedfda3c5e8a31af8c23b391775644ef2dbd85a21da7b06dd739e4151cc0956b8f3177ce46c4c54dc784492bb1b5b89cd953728229d973e18587435b250e474562475bfd83f343e2039470e37a2f3d1e732ac74db4b6bf0909b5e04f576a25fd738c7e5fb34a2e49ceaa97ae5a5cf1403701bd36918397a746e2fac1e9981d2e857e6df85813258b0d315cec19a280ee960a542fbe2aeda0c863dc840284c82b22545e19c1026504f19510c2b6b6b28a68adcac5a8b69218411e756b9105593fdef7631b2355677581ecb7f9a2257bfd2dfbfd89af7a0d14578f181ff6386968cbefbe97fe6cc1ca0d1a5c6932246e347562ef758c1d3c02ea728a70b1b1c7c3dbf7f1fe510d3a7bfb23c69483346f2ea24d5b21ce43c0dc5aa40172a135aa3fe6a16a770eca737ba224c20c3b0402bc941200a10ea08704e09193213e17f6c2b52043acd050c52235156cd6d3c76b9f70203913273a99625b281fdb63657164300f67c74ba3b38703e64e5a8bec71cb91919285dc590b302b3d0bd3d3e662ced465c89bb716ab97ac6332276431b1a1dd0e381a9bf4e234c7d9fcb2c6fec0f357b27ff5c6465d517c75ba253331580b963c17c4e82622c53803434d32b0d5eb28ca3bde4496753edaab86c045c716e3622d9116a08d69411aa89c608edb0b1c11eba80b17032564f81b60c3007b3cd8d11e417ea6708dec04f3e040a885454363da30f836bc8473e32b8436bcc584c61a9412e014dbd6903a565fd6b29ce029040559100684a024c71bc549c6d83cdc1c0e2af688d6eb27a94524969c3d88d1e98701ae835194b415677b5ec5dd5e6f7138e01266db2dc34caba528f05e4fd566326499e796fd9a524acd18c799f223d9a86f7d3cf5fee6f2281daacbe0bc074e2e71a236f7d3122f4f325fa02d6c496d29c90dcd21fefd53a8aedb4f33da6b8fc374cf557438f718d9cf3ee1680d85bb148d372cce3f651f6fb18fe57522acf84423e14135ec779c87e2ecad30cc3bc8cc7cc590f1472f137d2d352c4d34628ecc73a62b27197ef13296ef25d57c5bad7e6aff5f8dd59429d25bb76e55e89b9d5da916b2892cbc0aaae2560d366e2cc3aaf547b17ccd615c62b17f",
            "f1a26de8dd6736c68c5f8db1630a98f1133737eebc5e474e9dbf72ce4c5387c3f9e7fcbe12fc978cc3e9d65a3cb275b41909b3919f23cff989fdffc0ba0a57e0f0f758a8f00e07daf23e5ba8c989c7b5e33075958120a40a1ff639a0620c17933bf0d1b70d0ff33ab462b6f4d5a646849a1117356932c5974b66b717d033bde5a9744f79d1541f61e3542f45517a3ba168aa3f9f9ad1418ecaf297a3337da4c9e2beb61f1df4d47c5a7862cc5fefef4bc630e17970ef332fa3fb777ed025ee9f9d037f009f57d3e564a1a17b97b54618d56f34336ef038381858c0c3ce058fee3e68da03a8aea947a49f13aee76ae069ae1af6f696c6f0d61c26b2351f670f85a2fe62244ef4e33057661ae2d63a2b5c5b6a8d52171e5ef5f50659968177a961f8382c18af7ba5808c9d0526613c9038036441099e8e1e87dd1d84284b94c7a9515c5c4817e0de1c79747713627cca1ccc1ebd04e943e660cfc6a37874ed35ae9dbb8f8b95b771a1fc16ee9f7bd2747fd4c74672a2e418999232ee721b2bfb6e7f872ffe81f446d395df8ac32305bdb51b260468c1991f844e9ae148364ac310a389c864f1b4ccff32d6b73980eeacae6ea3e201577e20bc14bbc04dc50fee3a8658d053173e86fa309276858bae260639ab62447c07dcb99583b727c2b07e8005ac3ab5874a721c635d75009d480d924935f2d8d6f3610534d6cd86e5ca49502b9809cea84130edde197b37f5c4ab6ded7079a63da25aabc14d29a409fb7b1b34e37f27f53094455ec6995e7731d9743ec234bbc141e880deba4370a1cb535c88ba470db79a481c155a0f53e5ff907bffcd39e3389c4e4a5ce9d7fa8a72e255bd85f48b75a65810a121caedaa47e6f7b0daa0ce6dd2e2b2aeae4d187444515595c4166ca39cf75c81f9e9e730a87804f36b9fe0feb611a98d14a68928a64f1d85aeaf458ccf631ac6173f42a9f00c84995b605970889afe8690b9d71ed7e9d9387cd0e54989f3bbeb88c67baa927e6d5576596bf07ee2ca6f63bf9ced94eb92da2685c29e5749de893aea0145b07bdf65acde741cebb69ec0a98bf7b1346f3712fa2dc2a88c228c1ebb891e38b992f4def592444c9a7fc4424fbf8d1a9fdf8a43fea9fe6dca05c53e5eb050e1be7333e0c7fe0ae37e5ebf8dfd36721c39dad74640ee6d5223b547b4c8ab4b0371f25009d62e9e887d39aea81cc7c1b63879a4f9ca424b461a63bde5c8a6245d12eaac77d4982f75dd4f9f571761cd23fddbf2497a8080e4442a9045d10a644977059213c127a37de448efd63c1260c27b6ca922e7a9d20c93dfda30a507ae3141b7da759f71d73726eda17f2f8d0a9f98ef4df7b7607f949023576da9a540223d054c90a73f8646f7819bb93d8a5615e2f1e5c73877e02c6e553dc1800873900f71a06fb7c793152a389fae84f9c1327498254f34a9bb1a7524854fdd992c4b3fcde4a2b6441f9fae77c7fea476d819e28efb83e4b18ce5030bf584b8d8d90d6fc78cc2879c2c1ce9d95dbcc856859eecc2a7a6f97245b3fc6545d91d65458b42b8f410170e13e617cc2c9cbc12e393a76244ef09589eb31115072fe2e0ae9338baeb341e5d7e08112542cdfb6afa46e575ea62e959b273d966d23f2a6e93964041e50fca015a7c1376acf9a7db1a2891206b65da5729a2a9f65f944e22869b4c458af1646cf2388462afe3986036171eaadee8a819861efa7d9bf20176d51c002b795b38a93889bbeb0f80a98c03c2fcb4515bb7079f2e2cc7926efa48f1d1878b8511a43a75837c4a7fe8edce87d9892de0afcc04272e02f99bd371ff483a960eb3c0baa91eb8bd2b04c7b3daa230de1823fcd460af648f6eba7dd1db6818fa998c42946e6f0c341f81e3ed1ec05bde1f56426b382bba4097af8170cd180c321a4559702d8996acca6a659e8ce4dcdf8f96c3f497fa994a4a9c4f9ec67c5232db817e726d01ceaf0d62d2fd594e1ba4ffda414be8a32223f3ed3ab4655bad95a72f13b6a58271bcf28ef1794d3349b534e6b1f37bad4884be0d14fa5503be77eb6159fe18aa4b4ba1b1a084eeb8e79a28b796908cb2339ff4ac6c25f1846f4674564765863189b4515aac2627adc0f9db7a733ffdc892737e297725cfb33963bf90a9fbc494444b54563dc7fae2d358bfe3342acedf45c1f2fd88ebb70c6999fb3076d261aae78a27a4fda1f7b54661298365fe3d9d21c1941e2a1c29fd9fd8ff0fe3d520290e974ceda9507f7791127d6a9606aacfa581d0a7c0dced897d997a18d38187e91df988f4b5660a27aa33fdda48bfb7d310141a0ae564beae033376e825b5af7bc9726487f139326315a4e426a9cac84d12726486f239dc48966348f6675515398a2de32489f5d33de1d5a5e3459f88fed7bc22a26ff9446a5ff7fb4b7de2ad3131df5b5f262a71a4c4f6866ae2132bade8b7db7460abad8e00670f0c8aed83fb67ef60fbb2121c2baec4a1e25318ddd79ad5dadb51ff7107f3f2607bd1b1096acc92705932ca5d8a38aaca100b651ee9e7254f76a42ad29f8fb8b0ef2d42f5b36cece8ca41797f1ed35d878b346b01ce440b71d05d0edb5af31125cb69f056e0930eba7cc9f9241269c523d1565c1269c92381a602a227cf2313874ea2678f59c02c9e964f9f28bd4c5d3a794f74edec13eac3d36a49ad00f6ff008d9fea71bdfc2a8eef384e172fd9222a5db9834c1b3abed248455df807f579b6dc4f272e47e994405a967450f36702d5baa103abaf071b4f42b2411ae638ac4269fb0b58e450c87283a0a67300011a114d75817bb3ad8b763c823462c4ee8afeb053b4c3e59d7e2055d1981ea4022b153e7213acb0698613e213dce01c1d08f5a000a84786a06def486c5ed5170d155df1",
            "f4685f142558e2e972571c186d8b69fe5af037d384a5bc233a6bf714b3b82f8ed31f8430b558382ab8609af57cac76dac3e2be335c15dde0c83e866a44b33fb781baac021daed59dc4eb0dbca02b5095f901edda2f35e31564649e9b2acb6276883cb37b5247a672913b8a93355fda6b722de5fefabd2dda2245b20fe0dd7b301d7ae5399348d3cc3216f7ef88282c00c3f8bda718fbf3af19dde2f394d1fa1354f091874cfa53862c79f481444f9a7e495959d98a05fa4233752eb9bfc99eac4e32d8a5cd93f923fbc1fe776344585e3aa5c94f3b5a7e713de9b383a125b94e1ebfa9c7d68377b061f7591c3d730ff9cb0f2079f82acc2b388109595745e1073f13c7f2eadb4a7eb3db36876e36c56ffc27e6f7cf58bfdfef1f493f7752e52aa18ba50cddc38e8f644f0d0cf7e4a0b02f074f566aa22a5b154bbbf1e163228b3be5c9d49d6d6164df24cd5516caad5a7c2effaadf813fcfc3c3a8cc3354e742bba0bfba2f1213f33d9df96b3108bd253548dc6cf4993bc73ad2e4b22b70d983d528a6b03354c5c9fd15d8bf66b7b868e976946dabc0b15d951810d78eb9b96f84e8ce1c2bb23d569a0c7591219e7abc33864abc4926cabc4ebaf2dc815c0ef79eb69c9c24ef2e5d34dc105f0e79e2e5320dccf49741343b2643ad657062aa31ae0c53a62a7b2b903853e1245d199e440b0dd1e0f22768f004e3d996ac242b682f2dade4af24cd7966ab6f48164c5920be5c7193541c384336e46d22d9e95964cad849a474e711baee83086f6ebfc2f58a9b38b5ef2cf6acd8c7ec58b49529c9dd4492a3e2377ccdfffb47c420a96fb4e23b33796371a4566fc65b3510b17a0325fa5f9c6a32151b3df7635ddbbde8a1d30f6d94dde1cff283ee7afd11af3f04bdf406a19d66074c6d3b1f1303c35153ea8a9d438de1add216fefa0e9819ac8b2dc9b6383fbf0daeaef5c6ad938370e3c2527cba3b1d0d8703f16e8f2f3e940562f3405b5464d86346882e6c540de0addc055d75e3d1c77018a27592c471d609284cdc842d11db30ca3a1dbdb40620db6e05d22d17c041c111111abdd84787267e32dd3a975e6cb79978a9790f9269ce75f4a3e0cf2fe769e4e5e5dfb2384f76675bd31f9fe7e1ec9a50a6afb5149914a859d3c15ca82d1034d9a2163f50730d585b5b694e4ccc390d1d5de2bbaa84ceab17e12d186ca768bafdf31a91c3c917f039748b245d7c45a6dd7a4f328e9c21516919d70daded46719af722a325e62827d594a62abd985e760aeeec7297bc2ef3133e7e65039bb1bfa76e61bd28b084412361982f0d0ccaaa3ea3f8d0751c3bff006bd79761e6ecedd8b0ad0a13729f8a3a5d6388d571d16181fb561d8160c3575beaf79fc0b59fdcec1fc7ad10b6313e3646cc89c299cc9bdb65a8dcbd0163c25d31b88d34b367001f2b237898d74b805333e5a84333cd48c54493d35e0602e96ff65c5ace664a9a649f4ed22435875a9a34e7f7e3c724befeefad3e430bc7ecc22222d3c6528f7978338d266f63517b271ae47d0feccbb741c6f071b8517e19ebb257a128b708274b4ea164fd01c6c74495cceec021191d5b7d6cabcf5ba9c1e7b713ca087ffd3ff4ddf4f8e7b5785ca22b23450f75e13097d2e410632b8b1417190cb4e0a098d5a3f7161a8baea4ca90144f7ea64a2beeff77cf8eb21cce654b6d9dcfdead5dafdbea1b4bea65cd675f5bc16aa83a3da12619d6632cbd77d549ec59731447b69c60d6666f249d3d035fd8e99b54596b1b7c34545675d75350f8a3728096f8f8c52a723c12ac1929eaa4deb5e9acff30e30cf130c349186a34096bdd4a9af700547ce0ab168470ed9ee86390826eba8988334dc0a9a86718dfd11517265b23a6b522d24c1662add341845919627dac1936c698a16282039e1775c4ee1417e4f77642d9924ef87424108f57b8a062b203760e3183839a36cb2fa2d1dd200989c6a988d4ee836e263d7122f4162aa26e608de74e8c359b0d63191394055621d32e1f46025dd82bdac34bb53d7ae825a3af512a93e7b80503f4c7345868ab3df17536efab2a25f811fc002df6428b6daf7d0d79e25b05f60c793f9229cf6e8d8d097a4fac34e43d659aeac9359f119ff2b782a494fd3d895dbd9dba401354d6d631ed6ebe26015b2a48975905242875e2f3763d130f59b5f598ca959595804f4bbcab2987c3fde46d21a01bee47910b732c6f78e90964397fae9ae4ff191bb8b5a943825c8a3f7ff1d8cd88dfd260588a8513f71b71f4f25b9cbbf91a45c527b038af1465471f3053d6bfa3fc9f32c4a90c9b04ee17f8fa1e5bbfdad2ad3f7bf3bf8bfd923db237de36c6b85fb186218df7404835a857e771a72413a95dbc31d0590a25831498a9617c6cec2d2b5adf934b92fcb4d3843cdeb7b6b665adb6e0bff456ce5ff9ee9bcef5c5fc2dfe379fedff3efbb0c5f6daaacac97db1d256145fbbb29426e4151ade4d00f33c1cf54fbaa377570f54955761d7b2cdd8386f1d762edf81031b0f31ab17ac13dbeb69bdb051979fca975532966c9dfd6a7ca4bf192741b2abce49634581d8519d4f8559ca21c2520613bca51909feaf9fee89d77bdb89ee4c90229343e41709393cc9594eb9162ef60d3793fee6f375387f7baecfcb4c43f799a64081f48f1c46af9bbd97da90bd8b4c1f9a5522e4b452e534dfa48ea1405dd2fea81af42bff27ceecb7a35b2bb54617ad7878ab06a09ffe680c379e8a8106e3b1c9bd144b594c0dd68884bb4a3b74528f68aa0510a6dd03a3593d3ecd70153a99a86145770378e82b23582b0aa73a3e8213abcddb18c86342276d140e32447a2735a478a961b49f26c6b7d3c1ce3467bcdae68b9b731d303a500bb67c6ff434ec8744c3",
            "1404ab4523c92e1917221e638ffb7978c8b7433b157fa43a8c4561b72d7833528444ed14d829b64677dd014dfe08c9f9c05efa0331ce3213d32d97319d0c7d49e5e1c12f5ccdb5851a1abfc43cffd9f15f523bebadbf319fbcdce9ca9c5d66231aeb2a241b06d8dd763352fef5df48fc23d66c8b6217c006a19212e31d19cb2c79f511ab441433e07303495c5e74c7c8c67eac404ec6837d9fd2dfd82442e45bb76e7d46438e434eeeecdc403ea4900d09aa2b8c149b632f637ee2c7afb1dfce7b5bcd5387ad22f2a0514c530c8dcb2f68945dafc6e527b53878a40acb961f44f9d147cccc1d9fa8f84f84841e22ab85fe8fa5639ac9146b4ba7fceccdffced562f3257994efbb9a19926b07f269e6fd0d5457bfc3c70767f1b8bc10e52bc662516f67ba837e2bfad05803d2c5491931f632b4ab96409ca4a67eb8bdb2524bde0bc97af8ad7a3d123b2ce4fcc55ff96bcdfcbddb25c9f7e006a7985f50e7f2c8be0dc114216568a00844751520d884e275a9983b231b4faedec3ba592bb023bf18252b77d0454b8bc4ab7356dd37d3d4d6faa67ba4ff8e9e6bf19b9c3354e09171de5cba9b952c52dda491e623cb0cb2e0309b6605a0f64237d1cb6c2932af87c22241339790fe1ddef2edcfd2dfcc0b6b23359da79a7c2119193fa16167ee11923376c92a538da6b4dbdfcbb9b3169fd4697d810689d0ec45b55309468c4e7f8c309ec1eaffc9d8e37d06c59ec7d0d760043cd4bde1af118a9efa0310a0118e1116937036f43ebc595ee0ad630627250784e94663b7ef699809247b019d61a7e0044b21abef15dce0aaec0b072517386818a287bd3a4e653be3f57a6774b5d7433be54824180d43b066246604ccc0bddeef71d8fb1a7cd47ce0a4e884e2b6a751165285e2c032643a2d85bb9247533c42a2c108716ffda18893e406341a8c1e467d25f7ceb8297b377e7a39974c1fe192f07528ffccfb9c2d73b535dbe8be3e2ae28632776a65bc0e59196f51d7c95abdbdb474d35cb7635b1afbe63d368e8e0ffce3fa8822c64c263db39791b8d52588db751a5d2e3e60fa7cac13f7befeeab9b5731b8ddfc07c198e9f5f8b9e59ce3692936ac0aee9cda2da13ddc9cc10855479993f54edabfffdd81022e9378da44bd5e78dd68bc8f92f84a24422bcaca5996bef1a71ff238d9367eea060d52194eebfc5cc2ef94867d51232f000c91586be6db6275324e7fbc9bfbbd67f5eff5c5f59b1d2fd8a169f4f564eea41dd3cb81417f6ccc4c50d5d716a6947ec9fe18135fd3498f57d0424c45a483adb2abed597e7d3ce9a5c71ac831cb550cb901cb5b23fdb5145d98dc3ffe5b325fab0136b8d325a2b0a77866b685c4ed237b837d8c0e8de0003c3d3ddb4b526d82a0a547ee10cdf37896eb1b9d3a459d39131d046446e3aa1f1460218d2008a2620f4330cece9891b2cf61fddb21f1be7aec6b2c9f391933a89ca1a3a9e2c98945d61a9addbc2c7a4fe1ffb2719335b21472872d5e1634e802c9de52fc32c0e91c3381f390cb1e3606ffe209067c344f4163932bfb7f27cdeff8fff2df3e0b762f85a6c9bab8e92528da1921a95332697e44d597bc0584da7b9e61a27e67b38effc4b5d4005be14e9a81e240a51ef8e408d280c339e8654931938e8771197025e6096c92ab8c9748423b70302d4a210a73f18ee8a3eb899fc1057926fa19d3084e50319c8b2cd47b2e14816e7ed593d3e08b10603d1cb70307a1b0e41bc6153fedea633fdade5bdd1c55e0b8f37b9a2a3a915ba68f5455fe391f052ed80c2b06d78d4154830488695d0169e12bf835a28da2878c29eef082bbe75d3fb928c4648e211c5925881defaa9e8a2d21f1df83dd046e08e450be6b198b45f7ca33cfc8296829274ccd63ff51e40cb7c1cca7e49b229cdb8f1c54607b2aaa7c1e74ed66a2c279095d474dda82410d487c4c59369db7691cc93556458d92571ecb60a2abae8381558b09331999487aeb75ed0b10f5e89dbad287d65d52144e2bc92754d4e96f9662eb7f4e33009f60f8cd1a348c34c881a0f52ef8b1c487ab0461fa9668afc13ff9be3fd24d8cd3ff5f4e96e8d5c1139f086509f6a45e2b7d51440534d6788efdd7bde14efb777d72566eebeb7d4944642d2f69279b291b5ff29ecff79fd737a48e22fcc5097137ce9d54e891ccf35a7456fb681aabd830fa5eeccb30d9a38992e8f8db1ada8a25eb2e285f1a61774858220164db2cde4f9e2301d256a62009744a8abd00f6c5d498595039da0ae7ad45d5978b0939acacb51fa066495a53da974f62237dafa91fb6efee4917b47729f7d7ec8c681e49a9addefa5ab15aed0bc6d20e100df23776bc66422d93b91abf7b656a65f6c3664de176a4274ca16a2b753d9b97f1137f7764272b7ce7879e339564c5f88792913a8052333a8dcf4d98df9537348d688a95b0c95557f2f6f78cbef66c84bf349b21b5fb4b28b0cb328549659d75d96991bd48cff6776ae0479325e444eca91ac3eea13a49afb57e6dfb4b9925aa6c4c7ce433c3f2d6f93a1b2daf7e4fb94fa0bcfe5343a28da214a339169a71288fe866330d97211363994639a6d2e86b54fc188b8100cee620f0f2d27f4d0198c70adeef050f1123f4cfc289ee290836d5ee5c02882f13ee3602b70445fa391e8a13b005dd4e3d0532f99d5f7a96c4b69e20249c629f01086616a1f03c4d8f9b29f97c2be968a208d6e88338b4789df690c379bd814d717a411cdfe1f5ff8698420502b0a7d0c866192550e06988c69e21371fa43d0d5b43352238391333d10172a26807cd88e86574b695233840c4d708efc13f9d47ed36eb1f64a123f74c149872b7eb5cd8e3996665cd7cd4155923fa43fdbeada4746913567cf63f1fd",
            "d7a2b85d27a83edb8ed2938e57310baf3dc3a4f3f799f0b5fb19cb85c518f6be1edebb4e8aecd29790d0b9ab0b3474f49bfbad5988b4cc171f191919a693930afdbe2a9261a812a0619be8c35a533221442ff16bbe1f991f1e4b9a63fda509d9ba5c713e450a1f10d1bbf7b578f4b641cc62bf5882fd6f5e7fc2cad587515458c9ccdbfd92eadb4048c24e32bf55f7eaaf76e427f6ff0fec61a63c874ba6452ba27eaf2145ee7647fdc78b787376341eace0e2c662556cefcd13ad8fe2d3252926e24eb69aee5f27fb691f156512adac4d17f4917fec672147651b1a50f76d5d71d8c2862cd0d3232b8c8d4989b91573ccd25e74b1755bea869b1f7dbd6d7bfa46dbf6d465470fbac8dc4a546c69437658d989a7fa198c335492fbdeb57fa1409a4b36a7eb8a1a4aedf06a8f37beecd641fde54090d723b064100773a72dc6d54327307d501a3333750219dc3d817474f7212393869111bd8746ca357f94f4ef687f350505ce4b0b559eb8b08f80ded04d9ad9142b8b736379cc8a48598c6dd30a8f2eee04ae85d0e4b40a191ca6dced6b58c6bf83092d366ea5b6bc2269dfda6bbca99a56d3eb7edf939d6aeec30bfa024d12a5d587f6550b16c7eb0c418cda200c8ff4c7a17de3f1a9ee35e8aabe78b2cc118b924ce0a1dc11034dc6c14f2d00a11a119861938b8eaa9d717bd873905c9603b8a68b3d94fc90643918197ed3116b9a8040cd2ee8acdd5ddccb60101259fc4f301c8970e310441846a2b7c170446bf5631f07a3bd7a20ec159cd056b52d8235a320f1efc7b3af4b7c09c3cd276361ebf548314d47d3e7487202eb0d838fb12db66558a36a457bbc3b1286863217d455f5a79fefed45ae6ff1b966a4a62a671bf387cdcdf89f586792dced64622f1dba7e8f233db6a3e6742559e9d542a13c19b7344f5c5a4b89d22f3d647a6f2bc3da4bb771a28ec1f17a8299e7efa3d3e222c675e156789e7d88016f6a199bfc7d8ce3a48554d8fa52123c767af037ff47fa2bd7e822cd9116277aaad227c61b833ad30ef7f60489f6a4ea8967c7988e17fe757e811ff56a89f59fc55dd040165e27d42b16eb2fdd79cf427f93ee17bf7bf7191b379563fd9a23ccbcc20774d70f8404143359dcb00fcd36c4ef27f6ffb7f52a3bb7db72387c3ade5b483d2950a0778cd7c28a611e2818ec832549aced4bb0c7dc686d3a274240e6f4d426916df5d2949a6983ad508ed310aaa14ef710ea91b931ca5372fb0b739d3405e4888f99e8828933b5c3cc825a60a84b2f32d0c55a2363949a58e3acb9332e5b79e0ba830f73c6c1159badacb1d1c486deddde967ebcd291148f345fea61a820e07c8d01fccefa541237d918e4a2c2dc5fa9cdbc3ae80f42efc4c75247bc2eef8986fd461819a38a354b8a3161e878dad7ce8618ab28ce576cc5e92bcbe13cd39157b868aea9fb7be7545aeccc222ecbd9c68628506747f1b0b5870cce8de1e1e6343e531cdf0a5961aaa87931832167f4c40d47b5eb3a39c89bfe8af3fdeb3e0e0e47555f51ff237bbf61ba0aca7f349df97b73a6e55ee7a872b92448334c14a2162b7651f140fe4407d41cefc090537eecb8bd40e3dd79b893678f6313ec1168618d70f524f4331e056f353fb4516a0343810e3a6a0489aff478895dbe27d18fc5f4e53e457838e43d9ef7afc6e91e5791e9948b2eda3d11a41e8d708d788469c421ce6008a2b41291ea3d1617075e47bcde20f464b19ee50a927d7db164af21563f1929e6e9c875d9d854fbb797e14024980c6bf2fdf7371d81f60a71e8d946039563adb026ce1a2ff77440fdd5441c99e84255eff422e97116fdffa471002dbea6625d051972b3a8b5b82cdde4a18d9adc4979a122c9de7750b4b79130fd4bcf61c9e5fbe25a9a6ed29d55352224efac44db192b18e7e9cb19db9c2d08bef10a892fab19878de58cfffc422a7cf94e717cf1a907ce4111ca4d7e68425afa4e7200bdc642514ebc33599179b7d118b9d11aa279a1ba64519c6d813a4ff6cfec6bf9472e594ef205c9e318a919b564e22942bd78f991a9bcf80c9fbed44bfa5ffcfe7d35d66f2cc7ba358799796b6ed3818f08b1db2c9aca0d7af5d5dff213fbffdb7cedab66cb3650e492c9a1ad4405835db06fd55cdc3fb51defaeecc0e7db07519e3f8e3ab26018e9e16d5fc6e7b48a10364f73898ded6524cf233d34b5eb07a81991646b95397d3cb99275f32ed14b203e116220ba60d18639a06dc71cd175a02f59b4a5ee7878899ec404895e0ee8493d890c62caac1db1ced00a9b6d6c7075a615b9bbd69ecc89377cea65a8e0a8a7fc5d9e639ac56dc525f923741a4fa62960662729545f8b06f99c8ae35956f8b855055dfd4ce166e94c25b94b91387ba93dfac25f0225f4cd55f54c0cb9dcff0fc35a6c4c3b2187c7b43112d2b717aa31c707cbe1f22401ae4ee6e3e67401b3239683c2896e202f12a89a627972778bf65933155e0b76ffbb9caa654cba192aa91aeaa8a87038df174f6be9c3ce02690e715775a79d849e5891610faab4035e6ff2404d65106a1f6dc5e3d22c9c9beb80eb398ec8ec668a36c2a0a69c808986a94de70102342360ad608718bd5ed8e37901854e4731ce3413365c1bf67d7d90e5b404253ea7b1da7f2bfa39f6c3a2e05c0c771f0a7fb510f4d4e98fdb439ea324ac1c6d157cd0a7699f6068d35ec14093b12ce66723d77923725aaf44a2f170f4d21d8aeeeac390603082e519a360cd71c3fc31b6f8bcab1db6c419e2dda918dcdd128cd2e136f4e5394ee2475b3c1edaea350d8e644feacfe003907c0739dbe6e792b83fd1e0084da6fe880b33d05d899169254d466dd846af7f5b07af65db9177ed7193e62400ded7d42161cd6e38",
            "4cce67dcb2d6305ecb7733161bca91f0f803ba9d7bc0586717326d67ae604656dc16f52fbd4c12d7ed9baba8aadeb2cf60c8e370defb590ac59b33cd99671726e2c6f668666a902233bd8bf987b686ca1d94a439dfa3adfacf617f41136e2749653588930f8079f6e23373f4cc23dc7ffaa1897b7df8588bc2a21358b7fa2893b5ea1ed5e13621a6ebaaa7f0fcef37eb19bf633fb1ffbfbf9624319a72ac643d6fa2c4156fcc1a42d7bfb9d6149fc17cba05fa4525ee1d59419dca4b21b913fa6c3056fde5fc79cb1a9ce7201490384dbdbaa9da46245d5b772c4fd0244dbbf139724cbc079f5c1ea54bbe4c6c4d6a333d48ed3a6ff26e7f20b97f6e1cb9737d3ef974a22b73679a11bdd5c58cd9d1ce92b93edff8736f77d578ce1fbba6dceff5e95953757972385d8dba3d5309d383b878c6dae5cb6b9db0229283861d5ac88995617666e833fb8629d5d9aa72ad8572c226bbf64fe0aeba9fabf0819a2c5fbc67862efd76852aae4c15e0fa0c01aa260b707fbe32f624b4c28dd204dcccb36cac1ac721f9c35432659b63ff64fe83dff57b9efb924bdb5643f04181a34a46849b33a7d26d716eb613be1cec80eb2b8351106b84deada51160ac8110333dc4b65586ab4a5b846bc73669f30456eb77d18e43a8560cac14ccd055371af3ec576190d1689613d8c24f3d1486b286d810b40b6f27d7e061bf77783ea00e85bea5f0530b44844e2c861b4fc238b3e9f054f3134b38451f8321e865301093ac73b0c2b51879ce9b30c62a133db58720ba7528fa057744984d283a987744da8814d4bd4bc7ed55deb8531c8b07459d503ed61615131d7135cf8726cfe3c9c02e661d7ec579fe0c97e47c51a5bd119f3ca9684f5fccb166cce53870ed9fca2c7dd5008f9c0d483a701ee76b69545334be348a90b87637ac27e5a1c3fa03f05ab5171e6bf6c3bafc2e66d60341e71e320e730be19abd8689df75961e73e63133e1f2d33abff87e5fcd9c248729a7d64e9d275e1aab8ae3f343999bdbc3b07fb446ad8bb6a0dd7fc0a7f667d0fde19c5975b5ddf7113c7cf985397ee6214e5f79da8425efdfd760c3961358bfba829959f89cf6bc47887ec1bb3481e7c5aff3f2a7eeff1fd8bf9638fbf52a7232a468611a4d1aee805d2da87b7b0d0d0f8fe0d9e94df4f145c9a468eeb053161aaabca6393ea5c967d072a6afc4554991f4d7d46f5ca16b24de6c685ee6a020d4e134c9764ea88023b8dcd19e579b91a4f2665ab2cea5fe5db576f839a92fb4d7565b6aa52a5fee6dae4446062b932323b51bce0c3320db06ebac3290e7b570eeef115f248170cf6d7504a47292327366bc126686b3b8bc401da797d9e3ddf372d43f1e0d72275674af3082f4b16e95af21aff0ad6d96e2fc7ebcbf0c217efbe5393c323d498722272d71274701f7e62be2519e1a5eacd2c4e3258a2c8e19e3e9c1ae389cc461ce8de551415602a7afb4ea3f69a7bee7bde596fb3e6fa8222445c32ca995d1a63896d11a9593ed59dc578493b2258bf1a3906db711111a4950975687a74afba678bd30ed9e88979cbfd71bc8fe1c055f557f8c349e8a489d1ee8a81d006fb5f67052f060757e10b26c96a1bfde704469f446b04a0406e88f40a84e1784687563394220daaa78a187fe80a67abf12ec8fd1eb8bc1a613b0b2cd7656ff176290591afc95635038cf176f8f06e2f2dece78767d0c48cd3ed0355740555f47edf961b8bfc613f78a3ae25a610053be3c44bc77b2477d677b55abafd452ea3bb757924b4b9ec359a2ab2077c7559343f2469a33d4fd7e581e2d80a6852d069f7b802eeb0fa2c3b29dd8f0a20efb3f50385c03a4ec3e098719abe0356f23dc966e87d3b21298ae2c85c7d5e7584a0196fb2ec27dfe66a6cd94a54c970de54ccae9578d434f3f24a34b0e2f95976f3a83bb475f89c7cc1ea843df399b8a5b7b6230ce4b86991da64d86b4d7f4fe6aaf7e44df7fcb7e7f3bf5c5d51f3a6c03b9fea29e3e79fe310e9f7e20ae91e4547c5783bcd5c7b066f929267dfb5bc6fd052126cbde8ee4bbb560ffd69fd8ffdf5f4b2d1a703eab3c49fed44114f9780ef5752fd0f8e501ea1f1cc1bbaa5dcc8982541cca1ffbc4cbc6d8e0571cb7252fcf390f6565324dc790dea86fccec37b325a3b5f59ec6aaab77fdc6a76dfc15177fcbfeb0da847bd3df9cd5cb63b4c55bfa6bcf3456e04b73beaf58b26f2f732e87fbd15a834fce642833ab7af15196ae8e2f7b2c515f15833727a7310dafc7e0fdd31928ec21a43cf4e41c05b2caadfe01dbfc4b6e1e42a66c91e3c8917e9d59ec7f1c86ea3217bcdf6d85baf3dea0ce3ae353b12e9e2c53c6aba3a1ccc5691ad4b95429322b947b404bfe0f9b97f77f89279273a92f239c35c9be542b7a098bffbb934d1168aa023f95488c329a85833e1771b2e33d64582e80bbb21bdc557c11a81189008daee8a69bc46af6e1e86398026fd50e88d54d449a693632ed97619edb6aa4b7c9428aed580c314c87b3820b8ce4f5e0aed60ef64a4e705474417716e713d8bf8f3518cce27fffa6f3fc43cd266286dd1214b86e65b5ff66f6b396a09bda60f4f4f3c1834d5eb839c701b7e639a3b6d417e4723b347e2cc3c7e7577173ef081c59d081291cee84dcee16d4a23023e47535b868aba620c5f97ef3687dcb33257a658f0e4f96ec98664cf0a00ffdfada0c767d9921da4a1a8e6973105b711b6db3d7a1e7ee334839791733aa9e23fdf403382ddc0adf1da7603f6f0b6c7277a1e3c9db6873ed25e67f69c0f2460666fb2e326e391be13e773d13bee90433e8d46bbaebf673e259379edf6bd32958925fe8a59789909ccf366748c358bca888a14b476ad3e1362a5b8c94e4145555557fc4",
            "3abf2df97dac7572de3d755e4591f32f18eac295173878f2219ebcfa8277efab312fff28e62fbec88c3e54cd04d4106297573394eb79f3a7eeffdf63ff44c9b9d959a97122f2e52298868720cc3330afcea1e6ee215cdc3c952a2b4823dd7d5dfac9b670bdbfb69d124cba11c0e2ff4a3d237a8d81094e5a3951f3f48c4881811199a6abbb3a404d59e5d773865dc3327e7e7e92c796fa0092e0f1cb5dec15c8aa3e9ae38c854dfaff7bc57f6d8140f0da4a9d4f72baf0986353d450bbc318a5e3d4b1385c0a45b11cdc5ba24e5d9aad451687704e1b28097e4f3f7f3b5eaa811eb67b79ac29efdf599ba23e4c01f3693c448f428197bdc03ceb8ec60b1e78bf49099fcb3df1a0d085a91cc4a10a6365899306b7bd1257fecfe603fe77f1447249ce6922b6adbaf842ba19b33dc91c3d9dd4e0add805634cb230da381359d60528f3abc22aa712046b44a0b5726b84e9744757ed3e08d38a6dca0920e10092f3789eaaede1a0e80817c53608528fc030f38958deb618493aa9b057b06faa37d85db73f928c52916296de745650b28f308cc5fc2cbba558eab419792e9b31dba100a9e653d1cf68148699a623402d1a7b723d99fa5dde78bddd1bf7b7f8e2ced6005c59158af28c76d8956480155db5b0b0b3b67871a41ebd2dd1b8a172843549f5d34b9393e27dbb76bf4f8dd96c0f245ec5c71e06f24cf1106dd1a38ad920753bf166bd09a67556837fde56041795c393c5f1c0adc7e1bafa005cf3f7c0655131bcd71e40e8c14b1874f616b29fbfc35600fbd8d6c8d058592b82d5a663705fb019edf2b623bce834922a9e2268c33171daa5a774c4a889e1ecffbd1f68a1404ecdb6606a2f79d059010ae2b5895654b0bdbada0feafb976275bfc4e7a16e59f0e2a2651e45ca9e11eaeaadb7283bf71455f7dee1e98b0f58b0fc3866cdbf4e271d6f40378688fd96d40ce0fabd68c1fe9f56e8bfcdd7fee2f34f94e5489151bd2328e6d951e6edbde37872e3106e1e5a8a6b3b337178c9002c1ad89ecee8664e226de582140582df3a8b2e79ed76888a3236e89bd0abf58d71c9da05db8dade8c5bafaf42e2373b2d7d4f2f6406dad36cda9b17e137b5af6f92d583bdce065289f68a5cafd9eed95644d9cd757e091445739ba7687019317cbc7581f292c89e162a0070f9bfa0b455569b264747bde2c7eabbffb5d7fdddf6d6538fc9b9ad2d2246b98a988d42f048307e2c69a9d60ea77807e9b06fa45021a2aac507fc2016fcb3aa262a894684bac0c89b5955da5c9e7fdc4fedfd6ffc61c0eb7aea3b992f871a609b3b4a75653eebe78bd61e8a993cce2ff2c56bb67a0d8f338f6fb9cc508b369b0e1d9c356c6039db4c3d159ab3bbae92435d5071c6396d95433a0afe108046945c15dc51b8e0ace706275bf9d228bfdeaa11867390b2b5c8ab1c2753b8adc8e20d7711396bab0cdb910d36c17b39c2003834cc763a4c534f6e745c8715a89513a733138b2139e1fee8ce3339cb16d8423d6265a634d0f23e4046b60a4b732629d359808274371a09d49a30a574082ad54c8d80eda87b5f80225151595ef599b7e7bdf021d0ee7bc3c475a3c27428b2e4d56c7bc2875763de963752f96b365cc874fc15e38b338def1d04584575c438f4bf730f1e14bccada9433e8bf7f308611613602345e18e48846b8d1432401051f510ceb3d6c373de26a66bc92526eee87d782d29668694df228397ad9bc1feef773d1c95c99b1217faf47c0b7a797743d2d35d2f455e4a4a525b40ea875b3b4df97da6f0d61c7bb45777a188ec7c4ca83b8f3ea2fcd20b9cbbf91697ae3fc7dca54791957b8f4e38478913013a60717d3cc7fff54fecffdfea1dc9d58b6d54475b03e6f4c671ccf99d33517570166eeeeb8eab2bcd71628622b60f16d0858972e29da3f4eabd4c95cc7ee3335af6ff175a0879245347af710b8bff95564e386fed8a7d2696cc1e530bd1610b2b526e65fb6e88a6b6fdffb3f7dc824b5dd5e4e4ec0ce46539dfb92fad4449864b66741150bb53849816208387738478b35088c2241e26f8c950f7a7f34994233f5e96c393e81a39ce5ff6fda57f85d392e08099d21cd9464f567f1cdee44711b21514691453a23a31cd10481a533d0dd4c3083057bd517da51b2a5205d4c6686932de4bfa8ea9124f4589a3f423fa277f0b43fe8663b174f8ac8a9c407c6ca49e687c800ada297443b8564f7464b5fe48a39948319ccae2f4665c0a7e86e9864bd0c6c41ab9993e18d0d5045e8a4188d24b68d2fe132ce762a2d51c44ab0d449cced0a6bc7e92fc3f615a3d10a1158f19d6b9c877de8a34abd9186b9985a52cf64fb09a8b548bc918c16afda9360bb1c0791d163aadc364ebf948d01f8e00d5086873ac313bc1043b065860b4b726fabaa821d6491311ad8d11e5ee8ce4a0206426f5a10b33c6c0c7caa69b1c477aa2b29c7092148727f53bdfff7b19b71076818c52e0481db5d4e49151612a747f3725140dd2c7b2686dcc0850878fa3292cc7cc43ccb9db18fca506e9348d852cdeef22a4a96d6075fe7a1185350d226615fb58c6e2ff65b6e5b32dfa8b08091441e0d173689b5dc8f82edfcbf8e5ef86d3f47c241db98ea11bb65f603bb271560f1d71ed11176ac7200392e0a13d40f6c7d4fd4dd8ff35bfcf1af5791459798b886e3dfc8493575fe3d2dd8f3872fa1126ce398cf4dcc7f4802a868c21a4a1e342510f4ec8db66ade3f713fbff47d81fc4e5702bdd4c0564563f6ddc2a76653edf9f079a5483bc5980173bcc717b891ab3b39f3cbd225c56746894310977d14990faed79deea2b079028fb83ce4a4292a3a3273a65e18873b66d70d1c605c7adec50a26b29da6d68450ed85b5deb6aa02acf",
            "f9fbe7f9ff4cd8345596c325a3fd05a2fc6e724cc5283eb36b209f99df958b055de5501025237a9ca3403a59f18728cbfcdd5a7c927d9321ac36bd63af274fe6f457177f3ad1962637dcd1702912d4bb02d0d473d0348bff0d8740bd8f073ea7a1fe5e022ac72ad26bbbb4424e806cada326d755202bf811edd43fea0f935c11ec3426dd1cd548ac8b3ae3afd80381ea5de0a31a88befaa330c26026f29c8a906fb509437af6c3f35bf9a83de003577d55787223d15da71f7ae90d66317f38daf2439039c103d16d7d591e3008fd8c24f1fc4331d622ab49fbc7ea0f4437bd24241b8f698aef9fe7b816f96db661b1d37a8c31cf4417cd78380a3c60cab780adba293ad9d8a39b9b3b022c3510e36480186f17a4760dc5dce4446c9d3e0ec7974ec7c91533a9aa0df3c8f8b82e7b65ff3cebaa656ca22462b1abbb2a09b252265d5a2be1c95273ac1baa8f09a1ea9813a68a44271e8ccd2da19e3c070efbaea0cba30f18f1b90eeb590e708aa6708ed5f98f599cafa168d4b28f9fd9d7afb1cf37b3cfe7b2bf0ffe4421f0b5087d591eedbfa712add397c185c57ec769cbd0ebd81dc42fdd201672383831df827ab9ce9aa4f9eb66aa7065bff55dfe586b26a639bf0f3fab81ccbf4a4497efbc43e59537b8fab806074e3cc0b8ac520c9af7841a7f1364a958fcd97fbea83327f4e34fecffdfad23894fba0ddbfd4c902d8f5c5dac4cd3470c187227040455207587f0668709eee72932a73314a9e27821d93ecc8824b4379c28fcff7387b4d81645b6553a2a084891891575c3ce0d67ec5d71c2d41117bb59534fe71b343ec8d625bb07e94cb6d76cc2a2bf97dfffcf92a78c95f43cd2c55e40ef1bc8c58e242e33d8458ad99a20833d7de57074388f79bd4a150136820fea72bc6c6d797e07252ed786c311bab138d48bfddb651a3cde331f337932b3972ab9b64483a2f6e831a203faa8deab0dd1210dd0973d58fc7fc6b62fa0eb0a40c876d4dc198153637854510c070511b2b4873e2f4228cdffe9f7ffc734e6580519850fea3c3e13ac1ec104abc5c05b2500e19a714df57747e9ccc4f09e43518f3abcd89e8487cb6c5198ed066f7b2bb4d16a0b6f1d3fb437f746f65877905be1285deb0307611bc4ea0d409cc1a0a69cfd892c17186e9a81d976f958eeba03390eab31d4241d9d54a360cb7781858219da189823c6d30d193d22b072447fec9d350ec7964cc6caf143b035732c2af333716a65264eae9c81b2dcc9289e3e1245135298dc9444d82a993d3512e818f1787f55afe97bd72c07d464a4c885e50ef523420d691735598c6baf81dd2906b8bbda0e0fb7b4c697127be6669e06fac4da43a5f744a8145d83e5b52f087cf419933fd6a3b4418467b408ef59dc7fc0b673228ad9d148314b58fc1f27a2d0a39146620d85a8cf14463240d4be93683d3e17ce596b9801175fc06fe43478ea7028e69813d935dce49c8daaa0651ff5c78bf76bc6fe717233aac994d384baf7e43373a0f2116ebd6a40e989471839633f92e73ea3c6df26a4442cfed87e31d381d3a5e627f6ffef6c5bcbdef27e7d792e3994aed850b3530b975658626f76076c4a0b47c1000b2c4dd4c3ec48157a6c477932c85fe3bd9f95c60825a97f286fd82fe7d1d976db5b45911cb773a2cfeabbe2d1a4509a3c082297961b938c28e5ea413ecae58e3a821fa126395f9fc3b9afa7c017ef1ac4a3d6c7ca6156900c6e4d92c38101b2281d25048eeba29ba790b8e9f048373b21f13694a703cc0524b68d808c0f51201b072a90f35315a9877315e8eb530578b34e1335bbf55177c010a27243d05fb6818224abc91730e424de9f89c7e589ada8a349adc8c69eb2222f035eb450ee27f6ff8397cc2ffe312e87b828b930919a49f0510982bf463806684f42b8ad1bdebe2c627b9c61eeaff6c7adc5aef8521a8077e7a370f170384eef0ac0d3a31d412e06a0ee900fc8c3284c1ae50e4f7e08abfd67b21c2213a3cda723497f04c23562e124f086b19c05ac544ce06f6d8f41811db068601cb64f4d45f9d2c9b8b2651eee1cc8c3fdc379b8b47d3ece6dcc46f9f2a93892978e136b66e078c134ec9c390ac5d346a0326f060646b6a73a08c348b2c9c8c30a7232527f122e2db9ffcb966a3cf2bad08c3eba3290b15250667cd4e4d0cb4109f3bbaae1d2025b7c3edb87d530f92c072ec1f1a208440d08807ace36689cff0ced9b0db07cd48890cf04d3aa29ecad17e1143b88a709c3ec61b900cb0198c9148d2c960b8c67db68f6b51442d0e9e455782ddf8b7e57df40d72b18ab072b338dfb1d11eba8eaf72bffc48fb3469acff9c573a6d78853f63334c350cc9e630f70f37935ce543dc5e8a97b306cde736ad05d425688c81bf7f9b42fa76ff54fecffdfad1da9bff8d0f8645257017d768634e6f7d0c2c6719138b27414ce6fc8c0b9c24cd6eef4a6f7e60c261dedcdd239cdb5dfff199f71cb5af062475a34c24d9d7933394c44eab348c902cf2243a1c0939d02fa5f7dda3f8a4fb9bb2c8747a21df9d4eefe7218e52d83aa3459ace926856da314409e9a625a3f65c65787279adb598199d45e28ce0a56c49a9ef2d4be7e5c6a57bc2c7378a01c8e0e93c395198aa82bd1c7979dba68386c00eadd44d0b807d2780c8dafb3f064ab13de6ee1895e2d51201b7ac87e72d3e3850aa405dfe2dacfebf7d74a8b66beadc75725ddb413687fb52e08d28c82977c188a733d412abdd1f0f132be9c1d8f07cb2c7077a92bde15b9813ae20be6b83f1a2a02f1745f00aa3674c4e9fc4ed896e30677251fc4e90e81bbd01fe6b2f6301398c145cf1c3dbc3d9199108dc2f42138caeaf82a16efefee5f8a876505785ab102cf4fadc293f2",
            "15b8b66b212e17cf6b7abc7b300f4fd8df49dae5ed0b717acd6c9c5c390ba79667a1606c12cc14f5a84cf3e5244aa7fb64453939c9b92ae9ef783c5ae6ef354b4d01b9bbc29826a7dd505932047d3bb923d4541d4186aa88b79547519202eeadf1c3db739341de0e02b9e689b25c2bf41cd91576ab7641efec43182fdb009df32fd0faca7b74bdf916a35ed722af964211c5603f4533db1b29cca96b44bf1a1142aa093cefbe41e4912b08da750ece66aa94e8842bd99f667ad84ca1398fc2941fab1c7d0bf6074b677dae8d2aa221490f77f7f967dc7a5a8debb79e626cc6760ccdba4bc5de63c8c446f2d47e0edd86d3bbee27f6ff77ed97643ffedbbcf192e7929c2f4f5db464c473bbf1e80d19f1787ebd14847e02bc3d0fbc3ac3ea8cc5a2b32b53c9e4e4ae3375f8b29c7f91dfb6f8f48fb5b3e08beb4efb926727134aedd5793fe278b4f0a64582563c92e2cb6b9ce02783dc0859666a3b29e4f71180dc31c6dd120338e9f030ca4788b4f60accc40e8a5812c6475eb81cd644c9a23c958b6329727892af86ea1d3af8b2d700f48348909aa9a05f8ec4cb833eb8369b4fd387952972db882c4b50a8b250e239ca36eff7ffd4fdff9a0f608612b715f153f51775d18a87872014916eb678bcd18be558ad517b612ce886fba0ef8d047db91b3e5586e0f6465f54ccf5c4eed1cecc8a382b64871821ab930ee21de5a1c1d183bdaa05821d9c312e3a1cabc624635ff638eccc1a858d535370307712ce6dcec62516e32f6d9b8b0765f92cbeaf6ac2faebbb17e21adbee1dcac3b313abf1e4d82adcdebd14e7d6cf42d9d289d89c3514b307476350584744b97bc34fcb879e6d5ec0a49bcd7ba12750e7ff0a4bbf47fc97d8942a1dae0cb9b8d29126f77c411a46a0eed37a9c28ec81c3336d5092618335197ec81b6085ac8e021c986887d7073bb1fc3a02e4ae370a8628206d7a5f5c5c1701d37133a074f40dd42a5e40e3d813e8543c8661f943d854bd85cbd50f70669bfd85d730de71112ecb76a3d7f55a18744942e95c038a5c6f47527d55fbc872a4247ba93f12af6e39e3ef2c98f5e975fbb514f944119aa129d4d1cd357c274edb829133ae8962ee3224fe0bb963345564cb897bdffcb7313fb1ffbfb4567e7d992972b9972cd5b80d11ee4a6468981ec6f57047e5ae65a8ab79067cb880eadba5b875205754be6800c94fef5bacdb9c774f96f3afc58ab5ec872d72d367f9fa3aeb7bfd430c25e7fa25f9855bea68b7fa81c644fa2ba6ecd65314901eadb9a2e16ed218da460643bce4203a638c0f3b3431cc978b203301323a2960627b211684f2312f480eebbbcba16cb06c13febf5ea38e86122dd0a7ec5173c10f4f77b9e0dc4c0de6dc702951cd3a45f2ec80011910acb4465986a7acc451faa9fbff3dce662927c7693093d747acee00a635df174b065a306727dae3e16a17d4948535e5337d75731f4e2c09c6fe11f6c88b32c5282f6d84592ac3415d002345011c0d74d0dddb03b39362b16d6a2af6e68c41c1f8248ce9158410773b447ab4c5dc7eb1d8306e3076658e46e5aa994d1ce03ccb052a56cd40c5ea4c5c2acac1b3632bf0e1fc3a3c3fb90267b667616df6604cec1f8df8f68108b70e41a8562413a3de8f1aa8335e34ce7876c320bd71c455b1cd1c55ee77bff7d3622bca15395264d9007dead9117fec9ceac1ec1e698607b9262017da80d4f667c7e338db727172ad0f06b92a637d82168e4fd2c7964c67f1a543a371bf2a1ff70add911eae883ea9c1b018370dca0b8ba1b0f91cb48e3c865ef913e8efba04e3b547a19fb30d06190508dc7606fe29c311e32ccd9c2f6c4deeadb2aa0eb516e8fd937ed1ef7f4d34eb7e13ad19afeeb8e48bc8b37a4211d25cc74f82fdd9738a99398bae89e21f32a4d33b7249677ca331a7c7a79fd8ffdf5d2312cc1eca4eca2d865cce503ecb51d99f8bd5b95c929fac445717ab30f4255f71f5a707e24bc7f2b06e9a2fceecccc3f3531ba9b29c24b27ddef02a47431da566bfd6947f756eb7e8ffaded2c14def7f357b3f917fd087f263c918c8350438373545728209d2db88d05e152cc206769ac19aa84ca8152389824853ece7288761020abb33c167411604d0c0fe52305a89a2a8feb598ab89ea38cd38bf4b07bb2115399a6449f1e2645dd9ed08a9c9fc0233909caf75aebc9c77cd3cd3fe3fcff7d0e50aacee791ceea31540703776c1b618eddc936ccf9e936a8be3010a5f307606b2f5dcc0bd640770735d86928c1505915763affd7de7d404759a50d1c7f4999926432c94c2699f43a0920a124a1490b0201e904429704b280b4208884502341211409468a4a135110591090a2d87165152962d7635b2bd6b52c30e5c9fd6608acd8ceb7ee5ac3ff77ce9cc9493bc97be7dee779eedcf7de042968dd5a568c1fe98de9d365db8249525e9c2ffddbb69296098d24d3d85cf2ed3d6559af28e999d550ee2b9f26dbe64e96fdcb67c8feaa197260c56c79e8e639bef5fc727cc77239b475be6c5a364166787fc7c0369da47bea95d2c356e0e96ff98bab3072aa73a47daa6778cc38d53b6a90ea60edac9a989aaaf410c7f3768339dc6c36d7fb93bf162ee4b04bf45aa01ad5caecdc382852e6e786cbc1a9f172f2e634b97d8a43ca4734956d0b8be4cb7756887abd9d1c98992ca332c264e5b42c79f96f53e5be079648ff353be5c6f99de4e0348b7c787f13f9ec056ffb6d5926a3664d90ac69d324bca45282ae5b276173364bfc82cdd2e9c0ebd275e20479636384a8f726c8810d859e1b7b99be699d60cad5d7f6b34ba18ff9eef3f33d5beb57bf7738bddaa90e9df205fe73b15f5e79f55d59b572b76cbae305e7a8773daad1",
            "1bea4973c9bfec5ac12962ff6f3b5e0545476bbb1d9600553da3897ae785f9aa7272a3b9a1ba80632de3f572b83cc8f5eaea7039fbf65a6fbb7d24723c4f3ef1d69d6bc64478d64ee95bf3f8edd3bfe8d8d851ff1788d5b5e77235d46e4b0e3564118bbef3ff87b648b3ecb1051b55af74835ad9c3df39ae693df796c101f2c4387fb9bfc85f4adb05c8e8e68132374f2fab0a0c9e7583f5b2ba40271579819e19ed02dcb32ef7733e54acb95f9ee1a71e2dd1ab79dd0c1fb48833ccd26906f3f7f20dfcef3167747890a61a19b35dc3b21b7b764c4cf56c2a74c84bd539b26776b62cee1425e3dbc688c31c2b59491952593854d64d19230f2e2993dd8ba6c98d6307c9c0f6cd242ba289e41873a567e870191d35434a1397caecc46a393a63b04ced6795a9bdf3654fc5b5b2bb629aec5d385dee9c354e2a8afbcae83e1da557abcb2537a1bd7432f7f2e48717bb46455de7bc3aaecc333c6e9cea113540b5b5e4aac6a18d555a48d227f1c6a827a28ce14b22f4c1032c465d7882d9acd581d7c285be931da4054a6694d1bd7658b47b7361ac6769ff08c94b3249cfc47019d1c022edc334993fd8211fefce92db8b63e5e8c161f2faf313a4f4de5b6a9e7eeb3de9b3f325e93863bc9cb8c126eb4b52e5ec73c3bc63e149efe351f9eaa996f2d42a872c1f9f2afd7b644a87fc1ed274c478e997152947aa32e5ab8ff78bfab2c2f5dae208b5f39acb9e6910653a7f665a9d8ffdde5a50e957ec7b6d4fdc8a336ac75bcaf5f6e7ce73b1ffb9936fc89a55f7cbe63b9f7716bfeb5469c7d57e43d19796d0e21788fdbfbd1e3a7f9d1a9069387be0da58d7735bfb7ad44bcdce0ebbdcf8459b8ce09a4563e2a5faea54597575537960697bf96c678c3cbd205cee1ba5732f2c48f0e4b7cf29d07d77ecfb5ff85fd46fa943bf7b1dfcb7156865a1baa02f1ada0caab0895e0d6914e8a9ee15e03a34dedff9f4447fd7f6217eae1bbaf8b966b4f33f5bdececf35bf433dd792ae7eaaaa87bfda5ea853b70f35a8912d8dcf79c7c269deb81fa16921da253ec7f26bb5555aaa4d7fda5ccf5233a67dbce781490eb9b3304d8e2f6f22abfba548bfcc4849d13591cb421bcacd6387cbe17537ca89edcb6463f90499ec8d1f19b648a9ee1f268b5a8e95e9b12b6569fa0659e6b84396a66e929dfda7ca9e7eb7c9e3b7674bb7ec66b265b6f767067491ae599749b3e874691edada9367eeef1e1231de591c3dd53d226e82ca8f19aaae88c853cd42b3942324e5a30463f4437663d87c9bded8d9a2f78fac3d9ee647e705eb4a7bdc19e21fa00a5b84ab05dd23540b9bd953d42446ee1a9c219b86d697b9b9c9d2dd9b0f9cac4e95cafe91f2d6eafad26eca0469b4ff55b9e3f5f7c5b86897d816ae97576f4f9739ddccdeb6b1c88beb32e59383fde4b32706883a9927ea992cf9664b82bc506191ed2382a4a09159b68d8a917d931364e5c8c4b35b8aed6ae7e4cca71bd843ea7afcf7c57e5f0cf7bd6fbb2efca6b36ad3ebca79e29d33f2f95925479e79596eaeda2977dffda273c43fdc2ae949b525a8e08ba0ec79cf9e8ffddb18457ecbb6d2b488102de4efe961fa9a3997fbb9175daec923e56135bb4b43d4de39d1b2bb2c5ef69426cb63555932c5fbb525f941726042886b5dcf4075eb30f3eed8e07361dfbfe0d7e9b7f8e1789ca4d7eb17d88cc69793c30c2ac36250f90df5eabaf63ab5dcdb266bf3bdedd22fd0fb71809ad745a7c6b6d47fd3ab81f1489328c3b2b04063274d0bd67d2fdfa2e6ffe5dbcacf3bbe3febcdb1d47579b1eec727a7cb8e9286f270692319d3c22609c664691edc56fa6567cbbe45d3e59503d572725795ecaf9e2d8fae982d378c2a94eb0747caf3e5fd6545c23e59df70975484df27078b67cadf26cd94c5f607e5a35d05d229cb2689c171d23424cbd33d7c90ab28e61a6751ece49afed15779e3fd952adbdc5c65043b3e4c30c6ec8b3658ca6c86900e6186808890901ffd9bfdebe0ebe1c29c9635c6a41d8f37e93f8c0b09f83a27ceaa26b649f354764a927db31d72dfb569327f40929cb92f5dee2d89965dc57a99b16ab4686b8f89b6688718ef382cda8e3764dffa5c3938335286378896e9d9a1724347a354f50e978d57d9e5c90529f26c55861c5e922a2fadcc90356362647a17ab375788f4ccea60550bfba679daa558f2f4753fdf0ed0e63dea7bbed1b8d8a996bca45c27de3e2d47ffe194471e3b26b3e7dce159bff198abe87da74a38a856eb7a7ceaed2bf36adb6a1e75ffef345f59a869812a2f59e75c39c820cb07993c7715ea3d6bba6ab2be6f80bcbc7d80ec9e182d5b4619655a7bbdccef1c78f6d9391135f795d53f9861335dd8c70fbfbe8bc70d43a2a6b54e34194a82038c6b43030c7b228d863dd1c186ed7126c39aa82043596840906f5f3a47ed16c03ff83dc4fd5fb74f2dafe73b5fb997fdecf3731cf24c6553d930dc21a961c1d2322c571a873696c5c505726ccbd273ebf34fecac9263db17cb8b7b96cb2b7bd748d19599f2feae2eb2bdf97e591c7b8f6ccb9f25ee43d9726cfe10a988db2827e68c9129f966c931f47015264c54bda206a936e1b9aa5148a6332538e1485c50e422bbd1ecabefad3f6cfe7fefeb7129bc0efebdc798c59b07984ca66e41fedaa76d126d9e8939499e0d57277a6bf71cf966574339bdc32173fb45c94dfdc2e4fe952d4577fc94e8de7549c0b36fc9d0b9a3645749bcdc541425d7768991fd2bf3e5c881abe4c5bd9de5d1aa46b2b0af4d4635314969870829ef122955fd236574f3307761b3b09ae256b663c9e1c68efaba35b7f2e3e353eddc7d896ecebfd4b4a3caf5ccfb673d875ef8976cdb7d58c64dbcddb3",
            "a0ea29f798f7cfa8fafbd4d2a0eea7ce5f0fcef0fb1df9d6d9bd99db30588eae89f69c792245d4fb43459d794a5e7bb0524efdbd508edfda4a36e56b52d5d320d57d8d9ed1397a75cf9454d5de61991569f8d39f0bfe67ac69fe9bfac1774e0071ffb7cbd15a7b53b49abcf430f79b8b533dafaecc92b1ada22542172e9dadbda5656c43d9b570aa1cbc79963cbcba5c5edb7f8b9c3a7ca7bcb4e71679705599f46c932547eece91bd8396cb9ce80d529dbb406ebd72867c707733a96a5b2677f4ba4eb6cd8c55b67a09aaa9b9f1378941b107628c11136dfae046c1813f6863bf4b28deff7ff3673e0fc48604480f4798ab7ba255960eb1cbb6d26829e96893a5f96972d3c018397953ac989f3a22f59f7a586e9ad4585676d3c9a82c932cceb7c8d70f6488925b45b97678d48783443ddf523ed8de40c6e4864be3b020e918172a3dd3423d239a86c9fceeb1dfb44b0acdfb5e6e5837c7a5dafabd976ec853eee1075dee273f70791e39f64fd97ccfe33276dc5a4ff1fc23eef28f9c2aef7e55aeeff2c9859f21f6ffae6da6dd9f1169503ba687b95615054b79ae49560c4a9727772d15e5dc22eab90ef2c8149d6c1d669099ed033d778d08930661fa63765d403f73ed50473cf9fdc634ff8bc675bf8b1ebe587f21de939bfd3e399a4fa5ef5c80b93dedae7f5435963e0dad92684c960e613da49da3be6cbd6ea2ecaf9c212fef5a21477655ca92d2a132b86b7bc94dcb91d840876c9d93200746964845fd15b265c878294d5bea7efbb6eeeefbc68cf12c6b37534eac69fc45ac29a42442674c36eb7f741e827cefbbfde542eefc649c49af6eec613b7b4b814dbaa7844bbf449bdc3d224d5e5bd1c29b0324c8c93529b278710f59ebcd0dae6b69947e996172b82256dc7b32e491e54d6472d70c296c1127d7768f9767aa33e41deff71fad48902503edd235dd224dc343a5518849a2eae95c09e1ba779bc605c7871bb4ba5a2b9dabe1955261895ae15bf5e73ca7b67da65c8f9efc976cbef709193b7683bb68d18b9e951f8b1ab1b3a65497f7d985b90262ffefcbaa69a6cf3a39743563b38d9e5be332e5f5b2c5f2c2bec7655d6c942ceb6f964f77277ade5913214b7bea7de7ceb90f2d88acb97e5cf2c1e6a926e3f9fc81f105f8f158e3bb9fe5ef5643b03a3029d175b337d624e91a483ffb7049345965654991dc76fd2819d2bdadb48ecf71b7377577f5092b728d8d2bf5e4e87ac8c29136393a7790dc357ca46c2898e43ab5e54af5787523f5e29d4d9cce031dbd7568bb4f5b3bc2432e9a77b890efd1277f3a2ff35d9b14b33707681469549bc6da3d5f6c4991072b1bcaad23ebcb9e890da4baaf431e59e1fd78824d06360895c9cd93a57a70ac9cde912e3ba7254a2b6f8d3fc861953159b1d23bd1221dec46d93d35561e9f1e2b4f4c8f93bdd313e59eb254593d29cebda53cb9e6a1aa869f378e35daceafbba88b6d7361ddde6cbf666bd5ec679caec39f2ad9bcfda8fc65e21ed7e0f5efd6ccfb5cd58cdc7c66a27605f7f7fd8104ccd33aec0a09f2534bd2325caa7bbea8b245a22a57c9f1a44c19a519a5a297510e9785c9f55d8c52d93bd073606efce94ff664a983e5d69b6382ceedf5f74baffd03ead21c40a6a6059ebe222ddcf564698c3327c22183ece324c7dc4a526d519e66a62c67afb0427751cc35aa20ba4875b47651cdc21a2b6bbd1829e919239f6ded205b0a47babfd9d5492d1a1dff37a3167434de14aaa60d8c531fef6b5553d425ae9bb70bfacd53dcc3f13372331fdf8cc932ab5eef9edadbecf9e8c470f9eaeb07e5a9eac6b2b4b75d8adadba46fba5596744d970d7d1bc8945cbba8c79acaa1ca144f45cf6899d32d56c665c7ba4b5ac478fa6724cad8cbc33d4fce8c93f543ecb2282f42d60f8f727ff9d7f6cecfff7a85ea91691de3f76d8e56576bff544dbbfccbbcb227e4b8529e6dfbde730f5bf892abef8b6e35f40b75bacb8a8faed29a1dad9d97623fdf3f929596e02075e2b2cb9c6f2725c9236999725768944cd3054b85d126c5b610b9ab502f6bfa19dd25cd75aab283bf9a96534f2dea1d74a069ccb93dc22eb5bdac81ffbc2eaa35c9f73ec0a06616d53cc6e6ce35f771e6478d7075b714a881f662d5d976a56a60aaffa6b744dc1c65348d8c31e947fb6e2118d636d2736a532bd72777b55453fad8ab6a4396a66ba869beafbfd93cc5a2dad5b7f5e19ca6ff6e1ee0fc3d781b7c1fb64b0a77ae9d3f5cded8d3465cf7a7ca81d26859d22b4aca3bc54859db441956df2e1503ecb2af22552a87da3d239bc6bbcbaec8560bfaf751a5bdf23db9c926f78611767755ef48d7d65189ce934bdbaa9da56d55cb78cba2c0efe68375ef5ad6beefbfd19c31553df3f669e7c137dcaeab1efe465df59552b987e421fb5f5e68aa05dd42ddffc7b42926c4280753929d8b8c6699ac33c90c43a82c08b1caa3d119b234225e2afbf8bbb75c9da03aa604bfd32ace786774a8717774907e4082997107f80fe70186685af02311ba2095146c57deba5f350bcdfe342928769dcd10d22d5cef7ff15d79beb3aece74696475a9bd2d5449f7d805e78fe3bd3886f8cecb5c115a2f2833aef6067ed679fc3c01e76b9741a1063fd5d511ec5cddcf240bfb44c8e2c176d9312546f64d8d91bdd7c4b8f74c8a71ae1a18e51cdd2cdc75655c90b34faa4d866667a88ef5d39fbd3c3dfd94556f50ddea07ab6d6313d55de31baa8d13b3d5e84ea91fc705ebc686d4edd8ef1dfbcfcdfefad6baba17546c3dfb965235c33f546ae88beaadf4f27746f8353df4ed5932c4fe3fa2627d909f9a1e1b77e6eef0587799cee4d9189fee764f9ae17923b985e7aae090b37f9d12a5",
            "168eb86cb35ef3b7685a28570cf8792e7ecfb79355af5f1aa137965a758638a3f107f305011d3a9cdb98e9cdd6defa7ef680c4e5e7ebfe00edbbe772fdaf7f076d52cbb727ff578ded06cf7bebd2dcea68b6e7c62b6d9e7c87c93532dbe2baa65d84baba5d982aeb6a55d33a5a55491b8b2aed1ca73aa55b579eafeb6f8832faffd361d57fd22ccef4665a44c8c3a17e7e73bc013f3eb576c15f5dcecbfc54ed24cafed63943d4a34ea5babd225f3be6be7483b1cd416f7e3ab5f63a2be5c73abf3f6c1ff09d35ff70726890aa8c4f550fc534502fa764abd772f2d40c7b829ad6c9a86e1e91f48ac312126ab17c9b37536f003fb756fac9cf5fbc4eff42bf5a1d6108de1be2f7ef39b67a3fd27759dfffcbcccd5419347f55d2dd2a1f6d6fa8ee1c11ab561424ab65033354a734cb63815abd593acdafd254afde8d56bd7f89d1cfafed4537f2f9ce2d89f43efb1e41ff619bd7253da2a21254e90db77b5acedfb54e4bb9a181a68dfbf6ff673fbf3f430e1c14ad69f3ad26fd895cabf5ed3e16db89c686e02f1a4406feb3739a716bb4d1186fb8745ecfc0af9d07045c9447ff549f3459ad5663ab5671d4edbfeef8e76b03a3f7326f0af10ff8ba599cf1ab2b1ca1efb548343f1e6fd24d0a0bf00b50f33afcdcdf197089b499372c241e888a70dc9b949adbc27b192f8afbdcdbf727cb017c7c535aa1e79f1db13a53ca4f7c1f00d435bef12e433b775ff477047cefe1ff2363e8a5743ef90521369b2d333830f2e27adf9b4fb1201c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000e00feeff001d79c7ae"].join("");
         var bytes:ByteArray = new ByteArray();
         for(var offset:int = 0; offset < encoded.length; offset += 2) bytes.writeByte(parseInt(encoded.substr(offset,2),16));
         bytes.uncompress();
         bytes.position = 0;
         var bitmap:BitmapData = new BitmapData(512,512,true,0);
         bitmap.setPixels(new Rectangle(0,0,512,512),bytes);
         bytes.clear();
         texture = Texture.fromBitmapData(bitmap,false,false);
         texture.root.onRestore = function():void { texture.root.uploadBitmapData(bitmap); };
         GlobalData.$assetManager.addTexture("__abyssRelicAtlas104",texture);
      }
      return texture;
   }
}
// END ABYSS_UI_104
