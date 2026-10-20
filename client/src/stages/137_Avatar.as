package com.meng52.game.module.avatar
{
   import com.meng52.game.command.avatar.AvatarData;
   import com.meng52.game.command.avatar.AvatarManager;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.BaseDisplayModule;
   import com.meng52.game.module.equip.Equip;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.module.map.GameMap;
   import com.meng52.game.module.map.GameMapConfig;
   import com.meng52.game.module.map.GameMapTools;
   import com.meng52.game.module.map.Random;
   import com.meng52.game.module.skill.Buff;
   import com.meng52.game.module.skill.SkillSet;
   import com.meng52.game.module.talent.Talent;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.effect.DragonBonesSprite;
   import com.meng52.game.ui.element.ProgressBar;
   import com.meng52.game.ui.map.AvatarLayer;
   import com.meng52.game.ui.map.GameMapLayer;
   import com.meng52.game.ui.panel.PanelDetailDN;
   import com.meng52.game.ui.screen.PanelCenterDNTeam;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import starling.animation.Tween;
   import starling.display.DisplayObject;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.filters.ColorMatrixFilter;
   import starling.text.TextField;

   public class Avatar extends BaseDisplayModule
   {

      public static var iconStyle:int = 1;

      private static var purpleBondMap:GameMap;

      private static function ensurePurpleBonds() : void
      {
         var map:GameMap = GameMap.currentMap;
         if(!map || purpleBondMap === map) return;
         purpleBondMap = map;
         var definitions:Array = GlobalData.$mConfig_simple.purple_bonds as Array;
         if(!definitions) return;
         for(var side:int=1;side<=2;side++)
         {
            var units:Vector.<Avatar> = side == 1 ? map.team1List : map.team2List;
            if(!units) continue;
            for each(var original:Avatar in units) if(original && original.abilityState) delete original.abilityState.bond;
            for each(var bond:Object in definitions)
            {
               if(!(bond.families is Array) || bond.families.length == 0) continue;
               var families:Array = [];
               var members:Array = [];
               for each(var unit:Avatar in units)
               {
                  if(!unit || unit.getStar()!=5 || unit.getType()!=1 || unit.isManualSummonUnit || !GlobalData.modChannelAllowed(unit.avatarData.id,"usage.destiny")) continue;
                  var family:String = GlobalData.baseModHeroId(unit.avatarData.id).split("_").slice(0,2).join("_");
                  if(bond.families.indexOf(family)<0 || families.indexOf(family)>=0) continue;
                  members.push(unit);
                  families.push(family);
               }
               if(families.length==bond.families.length) for each(unit in members) unit.abilityState.bond=String(bond.id);
            }
         }
      }

      public function getPurpleBondIsActive() : Boolean
      {
         if(!GlobalData.modChannelAllowed(avatarData.id,"usage.destiny") || getStar()!=5 || getType()!=1 || !GlobalData.$userData || !GlobalData.$userData.team || !GlobalData.$userData.avatars) return false;
         var definitions:Array = GlobalData.$mConfig_simple.purple_bonds as Array;
         if(!definitions) return false;
         var family:String = GlobalData.baseModHeroId(avatarData.id).split("_").slice(0,2).join("_");
         var teamIndex:int = GlobalData.$userData.attrs && GlobalData.$userData.attrs.team_num != null ? int(GlobalData.$userData.attrs.team_num) : 0;
         var teams:Array = GlobalData.$userData.team as Array;
         var lineup:Array = teams && teamIndex >= 0 && teamIndex < teams.length ? teams[teamIndex] as Array : null;
         if(!lineup) return false;
         for each(var bond:Object in definitions)
         {
            if(!(bond.families is Array) || bond.families.indexOf(family)<0) continue;
            var found:Array = [];
            var selfInLineup:Boolean = false;
            for each(var instanceId:Object in lineup)
            {
               var instance:String = String(instanceId);
               var hero:Object = GlobalData.$userData.avatars[instance];
               if(!hero) continue;
               var aid:String = String(hero.aid != null ? hero.aid : instance).split("|")[0];
               var parts:Array = aid.split("_");
               if(parts.length != 3 || parts[0] != "A" || parts[1].charAt(0) != "1" || int(parts[2]) != 5) continue;
               if(instance == id) selfInLineup = true;
               var memberFamily:String = parts[0] + "_" + parts[1];
               if(bond.families.indexOf(memberFamily)>=0 && found.indexOf(memberFamily)<0) found.push(memberFamily);
            }
            if(selfInLineup && found.length == bond.families.length) return true;
         }
         return false;
      }

      public function getPurpleBondDescription() : String
      {
         if(getStar()!=5) return "";
         var definitions:Array = GlobalData.$mConfig_simple.purple_bonds as Array;
         if(!definitions) return "";
         var family:String = GlobalData.baseModHeroId(avatarData.id).split("_").slice(0,2).join("_");
         for each(var bond:Object in definitions)
         {
            if(bond.families.indexOf(family)<0) continue;
            var color:uint = getPurpleBondIsActive() ? 0x55E889 : 0xFFD45C;
            var concise:String = bond.short_info != null ? String(bond.short_info) : String(bond.name) + "\n" + String(bond.info);
            var lines:Array = concise.split(/\r?\n/);
            var html:String = "<br/>";
            for(var i:int=0;i<lines.length;i++)
            {
               if(i>0) html += "<br/>";
               html += Tools.formatHtmlText(String(lines[i]),color,i==0,i==0 ? 16 : 15,"",0);
            }
            return html;
         }
         return "";
      }

      public function getDestinyDescription() : String
      {
         var original:String = mDestiny && mDestiny.htmlArr ? Tools.formatHtmlTextBr(mDestiny.htmlArr) : (mDestiny ? mDestiny.nameStr : "");
         var bond:String = getPurpleBondDescription();
         if(bond && original.indexOf("暂无命运关系") >= 0) original = "";
         return original + bond;
      }

      private function purpleBondMultiplier() : Number
      {
         var context:Object = currentAbilityAttack();
         return abilityState.bond && context && context.owner===this && context.kind=="active" ? 1.3 : 1;
      }

      public var formationOwner:Avatar;

      public function clampSummonFormation(targetPos:int) : int
      {
         if(!formationOwner || formationOwner.hp <= 0 || formationOwner.team != team || formationOwner.line != line) return targetPos;
         // Keep a unit of visible spacing; never teleport displaced summons.
         return team == 1 ? Math.min(targetPos,Math.max(pos,formationOwner.pos - GameMapConfig.MIN_SPACE_POS)) : Math.max(targetPos,Math.min(pos,formationOwner.pos + GameMapConfig.MIN_SPACE_POS));
      }

      private function clampOwnerAdvance(targetPos:int) : int
      {
         var units:Vector.<Avatar> = GameMap.currentMap.getAliveList(team) as Vector.<Avatar>;
         for each(var unit:Avatar in units)
         {
            if(unit.formationOwner !== this || unit.hp <= 0 || unit.line != line) continue;
            // Wait for the front summon instead of walking through it.
            targetPos = team == 1 ? Math.max(targetPos,Math.min(pos,unit.pos + GameMapConfig.MIN_SPACE_POS)) : Math.min(targetPos,Math.max(pos,unit.pos - GameMapConfig.MIN_SPACE_POS));
         }
         return targetPos;
      }

      public var abilityState:Object = {};
      private var abilityEntryAttack:Number = 0;
      private var initializingFightAttributes:Boolean = false;
      public var previewTeamTalentBonuses:Object = null;
      private var abilitySerial:int = 0;
      private var abilityIndex:int = 0;
      private static var abilityNextIndex:int = 0;
      private static var abilityContexts:Array = [];
      private var parallelVisualBatches:Array = [];

      public function beginParallelVisualBatch() : Object
      {
         var batch:Object = {context:currentAbilityAttack(),start:NaN,end:GameMap.actionDelay,target:null,hits:[],wave:-1,step:0.15,serial:0,animated:{}};
         parallelVisualBatches.push(batch);
         return batch;
      }

      public function setParallelVisualWave(batch:Object, wave:int, step:Number = 0.15) : void
      {
         if(!batch || parallelVisualBatches[parallelVisualBatches.length-1] !== batch) return;
         batch.end = Math.max(Number(batch.end),GameMap.actionDelay);
         if(isNaN(Number(batch.start))) batch.start = GameMap.actionDelay;
         batch.wave = Math.max(0,wave);
         batch.step = Math.max(0,step);
         GameMap.actionDelay = Number(batch.start)+int(batch.wave)*Number(batch.step);
      }

      public function prepareParallelVisualTarget(target:Avatar, hit:Boolean) : void
      {
         if(!target || parallelVisualBatches.length == 0) return;
         var batch:Object = parallelVisualBatches[parallelVisualBatches.length-1];
         // Reactions retain their own sequence and must not rewind their caller.
         if(batch.context !== currentAbilityAttack()) return;
         batch.end = Math.max(Number(batch.end),GameMap.actionDelay);
         if(isNaN(Number(batch.start))) batch.start = GameMap.actionDelay;
         if(int(batch.wave) >= 0)
         {
            GameMap.actionDelay = Number(batch.start)+int(batch.wave)*Number(batch.step);
            return;
         }
         if(hit && batch.hits.indexOf(target) >= 0)
         {
            // A repeated target starts the next damage wave, not another victim.
            batch.start = Number(batch.end);
            batch.serial = int(batch.serial)+1;
            batch.hits = [];
            batch.target = null;
         }
         if(batch.target !== target)
         {
            GameMap.actionDelay = Number(batch.start);
            batch.target = target;
         }
         if(hit) batch.hits.push(target);
      }

      public function endParallelVisualBatch(batch:Object) : void
      {
         if(!batch || parallelVisualBatches[parallelVisualBatches.length-1] !== batch) return;
         GameMap.actionDelay = Math.max(Number(batch.end),GameMap.actionDelay);
         parallelVisualBatches.pop();
      }

      private function flushParallelVisualBatch() : void
      {
         if(parallelVisualBatches.length)
            GameMap.actionDelay = Math.max(GameMap.actionDelay,Number(parallelVisualBatches[parallelVisualBatches.length-1].end));
      }

      private function playParallelAttackTween() : Boolean
      {
         if(parallelVisualBatches.length == 0) return true;
         var batch:Object = parallelVisualBatches[parallelVisualBatches.length-1];
         if(batch.context !== currentAbilityAttack()) return true;
         var key:String = int(batch.wave) >= 0 ? "wave"+int(batch.wave) : "auto"+int(batch.serial);
         if(batch.animated[key]) return false;
         batch.animated[key] = true;
         return true;
      }

      public static function beginAbilityAttack(owner:Avatar, kind:String) : Object
      {
         ensurePurpleBonds();
         var context:Object = {owner:owner,kind:kind,targets:[],hits:[],kills:[],guards:[],damage:0,hitSerial:0};
         abilityContexts.push(context);
         return context;
      }

      private static function currentAbilityAttack() : Object
      {
         return abilityContexts.length ? abilityContexts[abilityContexts.length - 1] : null;
      }

      private function activeManualEffectMultiplier() : Number
      {
         var context:Object = currentAbilityAttack();
         var value:Number = context && context.owner === this ? Number(context.manualEffectMultiplier) : 1;
         return isFinite(value) && value > 0 ? value : 1;
      }

      private function ownGrowthValue(effect:String) : Number
      {
         if(!talent || !talent.my_HaloData || !talent.my_HaloData.dataObj) return 0;
         var row:Object = talent.my_HaloData.dataObj;
         if(String(row.growth_effect) != effect) return 0;
         var value:Number = Number(row.growth_value);
         return isFinite(value) && value > 0 ? value : 0;
      }

      private function isTeamFlatTalent() : Boolean
      {
         return talent && talent.my_HaloData && talent.my_HaloData.dataObj && String(talent.my_HaloData.dataObj.growth_effect).indexOf("team_") == 0;
      }

      private function isPanelStatTalent() : Boolean
      {
         return ownGrowthValue("attack") > 0 || ownGrowthValue("defense") > 0 || ownGrowthValue("hp") > 0;
      }

      public function getRecoveryTalentMultiplier() : Number
      {
         return 1 + ownGrowthValue("recovery") / 100;
      }

      private function teamTalentFlat(effect:String) : int
      {
         if(this.summonStatSnapshot) return 0;
         var map:GameMap = GameMap.currentMap;
         if(!map || team < 1 || team > 2 || hp <= 0) return previewTeamTalentBonuses ? Math.max(0,int(previewTeamTalentBonuses[effect])) : 0;
         var allies:Vector.<Avatar> = map.getAliveList(team) as Vector.<Avatar>;
         if(!allies) return 0;
         var best:Number = 0;
         for each(var ally:Avatar in allies)
         {
            if(ally && ally.hp > 0) best = Math.max(best,ally.ownGrowthValue(effect));
         }
         return int(best);
      }

      public static function endAbilityAttack(context:Object) : void
      {
         if(!context || currentAbilityAttack() !== context) return;
         abilityContexts.pop();
         var owner:Avatar = context.owner as Avatar;
         var target:Avatar;
         var guard:Object;
         var record:Object;
         var state:Object;
         for each(record in context.targets)
         {
            target = record.target as Avatar;
            if(!target) continue;
            guard = target.abilityState.guard;
            if(guard && context.guards.indexOf(target) >= 0)
            {
               --guard.charges;
               if(guard.charges <= 0) delete target.abilityState.guard;
               if(guard.kind == "kayle" && target.hp > 0 && owner && owner.hp > 0)
               {
                  var guardOwner:Avatar = guard.owner as Avatar;
                  if(guardOwner && guardOwner.hp > 0)
                  {
                     var swordContext:Object = beginAbilityAttack(guardOwner,"response");
                     swordContext.manualDamageMultiplier = guard.manualDamageMultiplier;
                     var swordPresentation:Object = guardOwner.beginParallelVisualBatch();
                     try
                     {
                     for each(var swordTarget:Avatar in guardOwner.abilityEnemies(300,target,3)) guardOwner.abilityHit(swordTarget,1.5,2,"FX_A_1120_MAGIC");
                     }
                     finally { guardOwner.endParallelVisualBatch(swordPresentation); endAbilityAttack(swordContext); }
                  }
               }
            }
            if(record.damage <= 0 || !owner || target.hp <= 0 || owner.getType() != 1 || owner.isManualSummonUnit) continue;
            state = target.abilityState.sap;
            if(state && context.kind == "active")
            {
               delete target.abilityState.sap;
               var sapContext:Object = beginAbilityAttack(target,"response");
               sapContext.manualEffectMultiplier = state.manualEffectMultiplier;
               target.abilityHeal(target,0.6);
               endAbilityAttack(sapContext);
            }
            state = target.abilityState.counter;
            if(state && owner.hp > 0 && (context.kind == "active" || context.kind == "basic") && state.left > 0 && !state.seen[String(owner.abilityIndex)] && owner.line == target.line && Math.abs(owner.pos-target.pos) <= 400)
            {
               --state.left;
               state.seen[String(owner.abilityIndex)] = true;
               var counterContext:Object = beginAbilityAttack(target,"response");
               counterContext.manualDamageMultiplier = state.manualDamageMultiplier;
               counterContext.manualEffectMultiplier = state.manualEffectMultiplier;
               if(target.abilityHit(owner,1,1,"FX_A_1143_PHYSICAL")) target.abilityHeal(target,0.2);
               endAbilityAttack(counterContext);
            }
         }
         if(owner && owner.hp > 0 && context.kind == "active" && owner.abilityState.bond)
         {
            if(owner.abilityState.bond == "demacia") owner.abilityShield(owner,0.2,1);
            else if(owner.abilityState.bond == "harmony") owner.abilityHeal(owner.abilityAlly(),0.2);
            else if(owner.abilityState.bond == "frost")
            {
               for each(target in context.hits.slice(0,2)) if(target.hp>0 && target.team!=owner.team) owner.abilityControl(target,"weak",1,0.1);
            }
         }
         if(owner && owner.hp > 0 && context.kills.length > 0 && owner.abilityState.highlander && (context.kind == "basic" || context.kind == "active"))
         {
            state = owner.abilityState.highlander;
            if(state.left > 0 && owner.skill0 && (owner.skill0 as Object).abilityHasCast && owner.skill0.m_cooldownNum > 0)
            {
               --state.left;
               owner.skill0.m_cooldownNum = Math.max(0,owner.skill0.m_cooldownNum-2);
            }
         }
      }

      private function abilityDirectMultiplier(source:Avatar, damageType:int) : Number
      {
         var context:Object = currentAbilityAttack();
         if(!context || !source || context.owner !== source || damageType < 1 || damageType > 3 || (context.kind != "basic" && context.kind != "active")) return 1;
         var guard:Object = abilityState.guard;
         if(!guard || guard.charges <= 0) return 1;
         if(context.guards.indexOf(this) < 0) context.guards.push(this);
         if(guard.kind == "kayle") return 0;
         var guardFactor:Number = Number(guard.manualEffectMultiplier);
         if(!isFinite(guardFactor) || guardFactor <= 0) guardFactor = 1;
         return Math.max(0,1 - 0.55 * guardFactor);
      }

      private function abilityRecordDamage(source:Avatar, damageType:int, before:int, damageTaken:Number = -1) : void
      {
         var context:Object = currentAbilityAttack();
         var actual:Number = damageTaken >= 0 ? damageTaken : Math.max(0,before-Math.max(0,hp));
         if(abilityState.grey && actual > 0 && damageType != 4)
         {
            var greyFactor:Number = Number(abilityState.grey.manualEffectMultiplier);
            if(!isFinite(greyFactor) || greyFactor <= 0) greyFactor = 1;
            abilityState.grey.value = Math.min(hpMax*0.2*greyFactor,abilityState.grey.value+actual*0.4*greyFactor);
            abilityFeedback("灰色生命："+int(abilityState.grey.value),"FX_S9160_SHIELD",10066329);
         }
         if(!context || !source || context.owner !== source || damageType < 1 || damageType > 3) return;
         var record:Object = null;
         for each(var entry:Object in context.targets) if(entry.target === this) record = entry;
         if(!record) { record = {target:this,damage:0}; context.targets.push(record); }
         record.damage += actual;
         context.damage += actual;
         ++context.hitSerial;
         if(context.hits.indexOf(this) < 0) context.hits.push(this);
         if(hp <= 0 && getType() == 1 && !isManualSummonUnit && context.kills.indexOf(this) < 0) context.kills.push(this);
      }

      private function abilityEnemies(distance:Number, center:Avatar = null, maximum:int = 1, heroOnly:Boolean = false, order:String = "nearest", excluded:Array = null, forward:Boolean = false) : Array
      {
         if(center == null)
         {
            var context:Object = currentAbilityAttack();
            if(context && context.owner === this && context.kind == "active" && context.skill)
            {
               var configured:int = context.skill.getCastRange();
               if(configured > 0) distance = configured;
               var rangeAction:Array = context.skill.getNativeAction();
               if(rangeAction && rangeAction[0] == "manual_ability" && rangeAction[1] == "jayce_n") distance = abilityState.form && abilityState.form.hammer ? 1500 : GameMapConfig.LINE_POS;
            }
         }
         if(center != null || maximum != 1) distance = skillAreaRadius(distance);
         center = center || this;
         return abilityCandidates(otherTeam,center.line,center.pos,distance,maximum,heroOnly,order,excluded,forward);
      }

      private function abilityCandidates(whichTeam:int, lane:int, position:Number, distance:Number, maximum:int, heroOnly:Boolean = false, order:String = "nearest", excluded:Array = null, forward:Boolean = false) : Array
      {
         var result:Array = [];
         if(!GameMap.currentMap) return result;
         var list:Vector.<Avatar> = GameMap.currentMap.getAliveList(whichTeam) as Vector.<Avatar>;
         for each(var candidate:Avatar in list)
         {
            if(!candidate || candidate.hp <= 0 || candidate.line != lane || Math.abs(candidate.pos-position) > distance) continue;
            if(heroOnly && (candidate.getType() != 1 || candidate.isManualSummonUnit)) continue;
            if(excluded && excluded.indexOf(candidate) >= 0) continue;
            if(forward && (team == 1 ? candidate.pos > position : candidate.pos < position)) continue;
            result.push(candidate);
         }
         result.sort(function(a:Avatar,b:Avatar):Number
         {
            if(order == "ratio") return a.hp/a.hpMax-b.hp/b.hpMax || a.abilityIndex-b.abilityIndex;
            if(order == "front") return (whichTeam == 1 ? a.pos-b.pos : b.pos-a.pos) || a.abilityIndex-b.abilityIndex;
            var delta:Number = Math.abs(a.pos-position)-Math.abs(b.pos-position);
            if(order == "farthest") delta = -delta;
            return delta || a.abilityIndex-b.abilityIndex;
         });
         return maximum < 0 ? result : result.slice(0,maximum);
      }

      private function abilityAlly(distance:Number = 3001, order:String = "ratio", excludeSelf:Boolean = false) : Avatar
      {
         var list:Array = abilityCandidates(team,line,pos,distance,1,true,order,excludeSelf ? [this] : null);
         return list.length ? list[0] as Avatar : null;
      }

      private function abilityMarkedTarget(mark:String, distance:Number, order:String = "nearest") : Avatar
      {
         var context:Object = currentAbilityAttack();
         if(context && context.owner === this && context.skill) distance = context.skill.getCastRange();
         var list:Array = abilityCandidates(otherTeam,line,pos,distance,-1,true,order);
         for each(var target:Avatar in list) if(target.abilityHasMark(this,mark)) return target;
         return list.length ? list[0] as Avatar : null;
      }

      private function abilityHasMark(owner:Avatar, kind:String) : Boolean
      {
         var mark:Object = abilityState["mark_"+kind+"_"+owner.abilityIndex];
         return mark && int(mark.until) >= abilitySerial;
      }

      private function abilityMark(target:Avatar, kind:String, duration:int, scale:Number = 1) : void
      {
         if(target && target.hp > 0) target.abilityState["mark_"+kind+"_"+abilityIndex] = {until:target.abilitySerial+duration,owner:this,debuff:true,scale:scale};
      }

      private function abilityHit(target:Avatar, coefficient:Number, kind:int, effect:String, sharedTotal:Number = 0, visualSource:Avatar = null) : Boolean
      {
         if(!target || target.hp <= 0 || hp <= 0) return false;
         var context:Object = currentAbilityAttack();
         var hitCount:int = context ? int(context.hitSerial) : 0;
         var one:Vector.<Avatar> = new Vector.<Avatar>(); one.push(target);
         // The profile multiplier belongs to this manual action's damage,
         // not to its healing, shield, debuff or a nested normal skill.
         var manualFactor:Number = context && context.owner === this ? Number(context.manualDamageMultiplier) : 1;
         if(!isFinite(manualFactor) || manualFactor <= 0) manualFactor = 1;
         coefficient *= manualFactor;
         if(sharedTotal > 0) sharedTotal *= manualFactor;
         if(kind == 3) coefficient /= REAL_DAMAGE_RATE;
         var total:Number = sharedTotal > 0 ? sharedTotal : coefficient;
         var q:Number = sharedTotal > 0 ? coefficient/sharedTotal : 1;
         attackAimList(one,kind,total,0,effect,false,null,-1,q,visualSource);
         return context && (int(context.hitSerial) > hitCount);
      }

      private function abilityHeal(target:Avatar, coefficient:Number) : void
      {
         if(!target || target.hp <= 0) return;
         flushParallelVisualBatch();
         var one:Vector.<Avatar> = new Vector.<Avatar>(); one.push(target);
         attackAimList(one,4,coefficient,0,"FX60_HEAL");
      }

      private function abilityShield(target:Avatar, coefficient:Number, duration:int = 2, healthOnly:Boolean = false) : void
      {
         if(!target || target.hp <= 0) return;
         coefficient *= purpleBondMultiplier();
         target.addBuff("shield",duration,Tools.toInt((healthOnly ? getHpMax() : getDamage()+0.1*getHpMax())*coefficient));
      }

      private function abilityControl(target:Avatar, kind:String, duration:int, value:Number = 0) : void
      {
         if(!target || target.hp <= 0) return;
         if(kind == "root")
         {
            if(target.buffs["purify"]) { target.removeBuff("purify",true); return; }
            target.abilityState.root = {until:target.abilitySerial+duration,debuff:true};
            target.addBuff("root",duration);
            return;
         }
         target.addBuff(kind,duration,value);
      }

      private function abilityDash(target:Avatar, enemySide:Boolean = false) : Boolean
      {
         if(!target || target.hp <= 0 || abilityState.root) return false;
         var destination:int = target.pos+(team == 1 ? 125 : -125)*(enemySide ? -1 : 1);
         reline(target.line,Math.max(0,Math.min(GameMapConfig.LINE_POS,destination)));
         return true;
      }

      private function abilityPull(target:Avatar, center:Avatar, amount:int) : void
      {
         prepareParallelVisualTarget(target,false);
         if(target && target.hp > 0 && center) target.checkMove(true,amount,center,-1,true);
      }

      private function abilityIsolated(target:Avatar) : Boolean
      {
         if(!target) return false;
         return abilityCandidates(target.team,target.line,target.pos,300,-1,true,"nearest",[target]).length == 0;
      }

      private function abilitySummon(aid:String, count:int, ratio:Number, turns:int, key:String, focus:Avatar = null, clone:Boolean = false) : void
      {
         ratio *= activeManualEffectMultiplier();
         if(!Avatar.isValidSummonMultiplier(ratio)) return;
         var previous:Array = abilityState["summons_"+key] as Array;
         if(previous) for each(var old:Avatar in previous) if(old && old.hp > 0) { old.hp = 0; old.deadFast(); }
         var units:Array = [];
         for(var i:int=0;i<count;i++)
         {
            var unit:Avatar = new Avatar(GlobalData.modDefinitionId(clone ? avatarData.id : aid,"summoned"),{lv:lv,slv:1});
            unit.goFight(team,line,0,false);
            if(!unit.inheritSummonPanel(this,ratio)) return;
            unit.speed = 220; unit.range = 125; unit.skill0 = null; unit.skill1 = null; unit.skill2 = null; unit.skillB = null;
            unit.manualActionTypeOverride = 1;
            unit.addBuff("summon",turns);
            if(clone) unit.addBuff("taunt",1);
            if(focus) unit.manualFocusTarget = focus;
            GameMap.currentMap.addAvatar(unit,team,line,Math.max(0,Math.min(GameMapConfig.LINE_POS,pos+(team == 1 ? -1 : 1)*(125+100*i))),false);
            units.push(unit);
         }
         abilityState["summons_"+key] = units;
      }

      public var summonStatSnapshot:Boolean = false;

      public function getSummonPanelSnapshot() : Object
      {
         return {"hpMax":getHpMax(),
                 "ap":Tools.toInt(getDamage() * (1 + checkTalent(1))),
                 "dePh":Tools.toInt(getDePh() * (1 + checkTalent(2))),
                 "deMa":Tools.toInt(getDeMa() * (1 + checkTalent(3))),
                 "hit":getHit(),"flee":getFlee(),"crit":getCrit(),"tough":getTough()};
      }

      private function scaledSummonStat(value:Number, ratio:Number, minimum:int) : int
      {
         if(!isFinite(value)) return minimum;
         return int(Math.min(2147483647,Math.max(minimum,Math.floor(value * ratio))));
      }

      public function inheritSummonPanel(owner:Avatar, apRatio:Number, hpRatio:Number = -1, dePhRatio:Number = -1, deMaRatio:Number = -1, secondaryRatio:Number = -1) : Boolean
      {
         if(hpRatio == -1) hpRatio = apRatio;
         if(dePhRatio == -1) dePhRatio = apRatio;
         if(deMaRatio == -1) deMaRatio = apRatio;
         if(secondaryRatio == -1) secondaryRatio = apRatio;
         if(!owner || !isValidSummonMultiplier(apRatio) || !isValidSummonMultiplier(hpRatio) || !isValidSummonMultiplier(dePhRatio) || !isValidSummonMultiplier(deMaRatio) || !isValidSummonMultiplier(secondaryRatio)) return false;
         var panel:Object = owner.getSummonPanelSnapshot();
         hpMax = scaledSummonStat(Number(panel.hpMax),hpRatio,1);
         hp = hpMax;
         ap = scaledSummonStat(Number(panel.ap),apRatio,1);
         dePh = scaledSummonStat(Number(panel.dePh),dePhRatio,0);
         deMa = scaledSummonStat(Number(panel.deMa),deMaRatio,0);
         hit = scaledSummonStat(Number(panel.hit),secondaryRatio,0);
         flee = scaledSummonStat(Number(panel.flee),secondaryRatio,0);
         crit = scaledSummonStat(Number(panel.crit),secondaryRatio,0);
         tough = scaledSummonStat(Number(panel.tough),secondaryRatio,0);
         abilityEntryAttack = ap;
         // The owner's live talent/aura contribution is already in this snapshot.
         summonStatSnapshot = true;
         return true;
      }

      public static function isValidSummonMultiplier(ratio:Number) : Boolean
      {
         return isFinite(ratio) && ratio >= 0.01 && ratio <= 100;
      }

      private function abilityClearStates(debuffs:Boolean) : void
      {
         for(var key:String in abilityState)
         {
            var state:Object = abilityState[key];
            if(state && !(state is Number) && !(state is Boolean) && !(state is String) && !(state is Avatar) && !(state is Array) && state.debuff === debuffs) delete abilityState[key];
         }
      }

      private function abilityBombExplode(bomb:Object) : void
      {
         var owner:Avatar = bomb.owner as Avatar;
         if(!owner || owner.hp <= 0) return;
         var context:Object = beginAbilityAttack(owner,"active");
         context.manualDamageMultiplier = bomb.manualDamageMultiplier;
         var targets:Array = owner.abilityCandidates(owner.otherTeam,line,pos,250,4);
         if(hp > 0 && targets.indexOf(this) < 0) { targets.unshift(this); targets = targets.slice(0,4); }
         var bombPresentation:Object = owner.beginParallelVisualBatch();
         try
         {
         for each(var target:Avatar in targets) owner.abilityHit(target,Number(bomb.coefficient),2,"FX_A_1098_MAGIC");
         }
         finally { owner.endParallelVisualBatch(bombPresentation); endAbilityAttack(context); }
      }

      private function abilityDeath() : void
      {
         if(abilityState.deathHandled) return;
         abilityState.deathHandled = true;
         for(var key:String in abilityState)
         {
            var state:Object = abilityState[key];
            if(key.indexOf("bomb_") == 0) { delete abilityState[key]; if(abilityState.bombConsumeOwner !== state.owner) abilityBombExplode(state); }
            else if(key.indexOf("malz_") == 0 && state.hops == 0 && state.ticks > 0)
            {
               delete abilityState[key];
               var owner:Avatar = state.owner as Avatar;
               if(owner)
               {
                  var next:Array = owner.abilityCandidates(team,line,pos,300,1,false,"nearest",[this]);
                  if(next.length) { state.hops = 1; state.until = next[0].abilitySerial+1; next[0].abilityState[key] = state; }
               }
            }
         }
      }

      private function abilityTurnStart() : Boolean
      {
         ++abilitySerial;
         var key:String;
         var state:Object;
         var owner:Avatar;
         for(key in abilityState)
         {
            state = abilityState[key];
            if(!state || state is Number || state is Boolean || state is String || state is Avatar || state is Array) continue;
            if(key.indexOf("bomb_") == 0 && abilitySerial >= state.until) { delete abilityState[key]; abilityBombExplode(state); }
            else if(key.indexOf("malz_") == 0 && abilitySerial >= state.until)
            {
               --state.ticks;
               state.until = abilitySerial+1;
               injured(int(state.tickDamage),1,DisplayTools.getAttrs("FX_A_1103_MAGIC"),6,state.owner,false,state.owner,null,"phantasm");
               if(hp <= 0) { dead(); return true; }
               if(state.ticks <= 0) delete abilityState[key];
            }
            else if(key == "grey" && abilitySerial >= state.until)
            {
               delete abilityState.grey;
               if(hp > 0 && state.value > 0) { var greyShield:int = int(state.value * getRecoveryTalentMultiplier()); addBuff("shield",2,greyShield); abilityFeedback("灰色生命转护盾："+greyShield,"FX_S9160_SHIELD"); }
            }
            else if(state.until != undefined && abilitySerial > state.until) delete abilityState[key];
         }
         state = abilityState.zone;
         if(state && hp > 0)
         {
            var zoneContext:Object = beginAbilityAttack(this,"active");
            zoneContext.manualDamageMultiplier = state.manualDamageMultiplier;
            zoneContext.manualEffectMultiplier = state.manualEffectMultiplier;
            for each(var enemy:Avatar in abilityCandidates(otherTeam,state.line,state.pos,350,3))
            {
               if(abilityHit(enemy,1.2,1,"FX_A_1011_PHYSICAL")) abilityControl(enemy,"weak",1,0.2);
            }
            endAbilityAttack(zoneContext);
            if(--state.left <= 0) delete abilityState.zone;
         }
         state = abilityState.channel;
         if(state)
         {
            delete abilityState.channel;
            if(hp > 0 && !buffs.stun && !buffs.silence && pos == state.pos && line == state.line)
            {
               var channelContext:Object = beginAbilityAttack(this,"active");
               channelContext.manualDamageMultiplier = state.manualDamageMultiplier;
               channelContext.manualEffectMultiplier = state.manualEffectMultiplier;
               var channelPresentation:Object = beginParallelVisualBatch();
               try
               {
               for each(enemy in abilityEnemies(400,null,3)) if(abilityHit(enemy,3.6,2,"FX_A_1073_MAGIC")) abilityControl(enemy,"weak",2,0.3);
               }
               finally { endParallelVisualBatch(channelPresentation); endAbilityAttack(channelContext); }
               return true;
            }
         }
         return hp <= 0;
      }
      public static function skillAreaRadius(value:Number) : int
      {
         var scale:Number = Number(GlobalData.$mConfig_simple.skill_effect_radius_scale);
         return Math.round(value*(isFinite(scale) && scale > 0 ? scale : 1));
      }

      private function abilityFeedback(label:String, effect:String = "", color:uint = 16764006) : void
      {
         var layer:GameMapLayer = GameMapLayer.gl;
         if(!layer || !fightRes || !fightRes.parent) return;
         layer.delayCall(layer.infoLayer.popTextForAvatar,GameMap.actionDelay,label,this,color,22,1);
         if(effect.length > 0)
         {
            var attributes:Object = DisplayTools.getAttrs(effect);
            if(attributes)
            {
               attributes = Tools.clone(attributes);
               attributes.a1 = this;
               attributes.par = layer.effectLayer;
               layer.delayCall(DisplayTools.addEffects,GameMap.actionDelay,attributes);
            }
         }
      }

      private function nativeAbilityNumber(sourceSkill:*, kind:String, key:String, fallback:Number) : Number
      {
         var row:Object = sourceSkill && sourceSkill.skillSetData && GlobalData.$mConfig_skill ? GlobalData.$mConfig_skill[sourceSkill.skillSetData.id] : null;
         var parameters:Object = row && row.modNativeSource ? row.nativeAbilityParameters : null;
         var values:Object = parameters ? parameters[kind] : null;
         if(!values || !values.hasOwnProperty(key) || typeof values[key] != "number" || !isFinite(Number(values[key]))) return fallback;
         return Number(values[key]);
      }

      public function abilityCanCast(kind:String, distance:int, sourceSkill:* = null) : Boolean
      {
         if(hp <= 0 || !GameMap.currentMap) return false;
         var center:Avatar;
         switch(kind)
         {
            case "nurse_n":
            case "nurse_c": return true;
            case "cat_c": return GameMap.currentMap.getAliveList(otherTeam).length > 0;
            case "polar_c": return GameMap.currentMap.getAliveList(otherTeam).length > 0;
            case "santa_c": return GameMap.currentMap.getAliveList(otherTeam).length > 0;
            case "kayle_c": return abilityAlly(nativeAbilityNumber(sourceSkill,kind,"can_0",600)) != null;
            case "yi_c":
            case "orianna_n":
            case "alistar_c":
            case "tahm_c": return true;
            case "nunu_c": return abilityEnemies(skillAreaRadius(nativeAbilityNumber(sourceSkill,kind,"can_0",400))).length > 0;
            case "illaoi_c": return abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"can_0",350),null,nativeAbilityNumber(sourceSkill,kind,"can_1",3)).length > 0;
            case "orianna_c":
               center = abilityState.ball as Avatar;
               if(!center || center.hp <= 0 || center.line != line) center = this;
               return abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"can_1",350),center,nativeAbilityNumber(sourceSkill,kind,"can_2",3)).length > 0;
            case "jayce_n": distance = abilityState.form && abilityState.form.hammer ? nativeAbilityNumber(sourceSkill,kind,"can_0",1500) : GameMapConfig.LINE_POS; break;
            case "elise_c":
            case "nidalee_c":
            case "caitlyn_c":
            case "khazix_c":
            case "jinx_c": return abilityEnemies(distance,null,nativeAbilityNumber(sourceSkill,kind,"can_0",1),true).length > 0;
            case "maokai_c":
            case "riven_c": return abilityEnemies(distance,null,nativeAbilityNumber(sourceSkill,kind,"can_0",1),false,"nearest",null,true).length > 0;
            case "aoxing_c":
               for(var lane:int = 0; lane < 3; lane++)
                  if(abilityCandidates(otherTeam,lane,pos,nativeAbilityNumber(sourceSkill,kind,"can_2",3001),nativeAbilityNumber(sourceSkill,kind,"can_3",1)).length > 0) return true;
               return false;
         }
         return abilityEnemies(distance).length > 0;
      }

      public function executeAbility(kind:String, scale:Number, effect:String, sourceSkill:*) : Boolean
      {
         var parallelBatch:Object = ["illaoi_n", "illaoi_c", "jayce_n", "jayce_c", "maokai_c", "wukong_c", "gangplank_c", "yi_n", "riven_n", "riven_c", "orianna_n", "orianna_c", "alistar_n", "diana_n", "jinx_n", "jinx_c", "aoxing_c", "kaelthas_c", "cat_n", "cat_c", "polar_n", "polar_c", "santa_c"].indexOf(kind) >= 0 ? beginParallelVisualBatch() : null;
         try
         {
            return executeAbilityBody(kind,scale,effect,sourceSkill);
         }
         finally { endParallelVisualBatch(parallelBatch); }
      }

      private function executeAbilityBody(kind:String, scale:Number, effect:String, sourceSkill:*) : Boolean
      {
         if(kind == "cat_n" || kind == "cat_c") return executeCatSkin(kind,scale,effect,sourceSkill);
         if(kind == "polar_n" || kind == "polar_c") return executePolarSkin(kind,effect,sourceSkill);
         if(kind == "santa_n" || kind == "santa_c") return executeSantaSkin(kind,effect,sourceSkill);
         if(kind == "nurse_n" || kind == "nurse_c") return executeNurseSkin(kind,sourceSkill);
         var orangeFourStatBuffMultiplier:Number = getStar() == 6 ? 5 : 1;
         var enemies:Array;
         var targets:Array;
         var target:Avatar;
         var ally:Avatar;
         var other:Avatar;
         var state:Object;
         var primary:Avatar;
         var coefficient:Number;
         var marked:Boolean;
         var landed:Boolean;
         var i:int;
         var count:int;
         var context:Object = currentAbilityAttack();
         var manualConfig:Object = sourceSkill && sourceSkill.skillSetData && GlobalData.$mConfig_skill ? GlobalData.$mConfig_skill[sourceSkill.skillSetData.id] : null;
         var manualDamageMultiplier:Number = sourceSkill ? Number(sourceSkill.getNativeSetting("manualDamageMultiplier",1)) : 1;
         var manualEffectMultiplier:Number = sourceSkill ? Number(sourceSkill.getNativeSetting("manualEffectMultiplier",1)) : 1;
         var manualDefenseBuffMultiplier:Number = sourceSkill ? Number(sourceSkill.getNativeSetting("manualDefenseBuffMultiplier",1)) : 1;
         if(!isFinite(manualDamageMultiplier) || manualDamageMultiplier <= 0) manualDamageMultiplier = 1;
         if(!isFinite(manualEffectMultiplier) || manualEffectMultiplier <= 0) manualEffectMultiplier = 1;
         if(!isFinite(manualDefenseBuffMultiplier) || manualDefenseBuffMultiplier <= 0) manualDefenseBuffMultiplier = 1;
         var hadManualFactor:Boolean = context != null && context.hasOwnProperty("manualDamageMultiplier");
         var previousManualFactor:Object = hadManualFactor ? context.manualDamageMultiplier : null;
         var hadManualEffectFactor:Boolean = context != null && context.hasOwnProperty("manualEffectMultiplier");
         var previousManualEffectFactor:Object = hadManualEffectFactor ? context.manualEffectMultiplier : null;
         if(context && context.owner === this)
         {
            context.manualDamageMultiplier = manualDamageMultiplier;
            context.manualEffectMultiplier = manualEffectMultiplier;
         }
         try
         {
         switch(kind)
         {
            case "illaoi_n":
               enemies = abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",500)); if(!enemies.length) return false;
               primary = enemies[0]; targets = [primary].concat(abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_2",250),primary,nativeAbilityNumber(sourceSkill,kind,"cast_3",3),false,"nearest",[primary])); count = 0;
               for each(target in targets) if(abilityHit(target,nativeAbilityNumber(sourceSkill,kind,"cast_6",1.2)*scale,nativeAbilityNumber(sourceSkill,kind,"cast_7",1),effect) && target.getType() == 1 && !target.isManualSummonUnit) ++count;
               if(count) abilityHeal(this,nativeAbilityNumber(sourceSkill,kind,"cast_9",0.15)*Math.min(nativeAbilityNumber(sourceSkill,kind,"cast_10",3),count)*scale);
               break;
            case "illaoi_c":
               for each(target in abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",350),null,nativeAbilityNumber(sourceSkill,kind,"cast_1",3))) abilityHit(target,nativeAbilityNumber(sourceSkill,kind,"cast_2",2),nativeAbilityNumber(sourceSkill,kind,"cast_3",1),effect);
               abilityState.counter = {until:abilitySerial+nativeAbilityNumber(sourceSkill,kind,"cast_4",2),left:nativeAbilityNumber(sourceSkill,kind,"cast_5",2),seen:{},manualDamageMultiplier:manualDamageMultiplier,manualEffectMultiplier:manualEffectMultiplier,debuff:false};
               break;
            case "jayce_n":
               state = abilityState.form || {hammer:false}; abilityState.form = state;
               enemies = abilityEnemies(state.hammer ? nativeAbilityNumber(sourceSkill,kind,"cast_0",500) : nativeAbilityNumber(sourceSkill,kind,"cast_1",700)); if(!enemies.length) return false; primary=enemies[0];
               if(!state.hammer)
               {
                  abilityHit(primary,nativeAbilityNumber(sourceSkill,kind,"cast_3",1.4)*scale,nativeAbilityNumber(sourceSkill,kind,"cast_4",1),effect);
                  for each(target in abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_5",200),primary,nativeAbilityNumber(sourceSkill,kind,"cast_6",1),false,"nearest",[primary])) abilityHit(target,nativeAbilityNumber(sourceSkill,kind,"cast_8",0.8)*scale,nativeAbilityNumber(sourceSkill,kind,"cast_9",1),effect);
               }
               else
               {
                  if(!abilityDash(primary)) return false;
                  if(abilityHit(primary,nativeAbilityNumber(sourceSkill,kind,"cast_10",1.8)*scale,nativeAbilityNumber(sourceSkill,kind,"cast_11",1),effect)) primary.checkMove(false,nativeAbilityNumber(sourceSkill,kind,"cast_12",200),this,-1,true);
                  abilityShield(this,nativeAbilityNumber(sourceSkill,kind,"cast_14",0.5)*scale);
               }
               state.hammer = !state.hammer;
               break;
            case "jayce_c":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",700)); if(!enemies.length) return false; primary=enemies[0];
               targets=[primary].concat(abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_2",250),primary,nativeAbilityNumber(sourceSkill,kind,"cast_3",3),false,"nearest",[primary]));
               for each(target in targets) abilityHit(target,nativeAbilityNumber(sourceSkill,kind,"cast_5",1.6),nativeAbilityNumber(sourceSkill,kind,"cast_6",1),effect,target===primary ? nativeAbilityNumber(sourceSkill,kind,"cast_7",3) : nativeAbilityNumber(sourceSkill,kind,"cast_8",0));
               if(primary.hp > 0)
               {
                  if(!abilityState.root) abilityDash(primary);
                  if(abilityHit(primary,nativeAbilityNumber(sourceSkill,kind,"cast_10",1.4),nativeAbilityNumber(sourceSkill,kind,"cast_11",1),effect,nativeAbilityNumber(sourceSkill,kind,"cast_12",3))) primary.checkMove(false,nativeAbilityNumber(sourceSkill,kind,"cast_13",250),this,-1,true);
               }
               abilityState.form = {hammer:false};
               break;
            case "nidalee_n":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",650),null,nativeAbilityNumber(sourceSkill,kind,"cast_1",1),false,"farthest"); if(!enemies.length) return false; target=enemies[0];
               coefficient=(nativeAbilityNumber(sourceSkill,kind,"cast_4",1)+Math.min(sourceSkill.skillSetData.range,Math.abs(pos-target.pos))/Math.max(nativeAbilityNumber(sourceSkill,kind,"cast_5",1),sourceSkill.skillSetData.range))*scale;
               if(abilityHit(target,coefficient,nativeAbilityNumber(sourceSkill,kind,"cast_6",2),effect)) abilityMark(target,"hunt",nativeAbilityNumber(sourceSkill,kind,"cast_8",3));
               break;
            case "nidalee_c":
               ally=abilityAlly(); abilityHeal(ally,nativeAbilityNumber(sourceSkill,kind,"cast_0",0.7));
               target=abilityMarkedTarget("hunt",nativeAbilityNumber(sourceSkill,kind,"cast_2",700));
               if(target && abilityDash(target))
               {
                  marked=target.abilityHasMark(this,"hunt");
                  if(abilityHit(target,marked ? nativeAbilityNumber(sourceSkill,kind,"cast_4",3.2) : nativeAbilityNumber(sourceSkill,kind,"cast_5",2.2),nativeAbilityNumber(sourceSkill,kind,"cast_6",2),effect) && marked) delete target.abilityState["mark_hunt_"+abilityIndex];
               }
               break;
            case "kayle_n":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",500)); if(enemies.length && abilityHit(enemies[0],nativeAbilityNumber(sourceSkill,kind,"cast_2",1.2)*scale,nativeAbilityNumber(sourceSkill,kind,"cast_3",2),effect)) abilityControl(enemies[0],"sunder",nativeAbilityNumber(sourceSkill,kind,"cast_6",2),nativeAbilityNumber(sourceSkill,kind,"cast_7",0.2)*scale);
               abilityHeal(abilityAlly(),nativeAbilityNumber(sourceSkill,kind,"cast_8",0.45)*scale);
               break;
            case "kayle_c":
               ally=abilityAlly(nativeAbilityNumber(sourceSkill,kind,"cast_0",600)); if(!ally) return false;
               ally.abilityState.guard={kind:"kayle",charges:nativeAbilityNumber(sourceSkill,kind,"cast_2",1),until:ally.abilitySerial+nativeAbilityNumber(sourceSkill,kind,"cast_3",2),owner:this,manualDamageMultiplier:manualDamageMultiplier,debuff:false};
               break;
            case "maokai_n":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",500)); if(!enemies.length || !abilityDash(enemies[0])) return false;
               if(abilityHit(enemies[0],scale,nativeAbilityNumber(sourceSkill,kind,"cast_3",2),effect)) abilityControl(enemies[0],"root",nativeAbilityNumber(sourceSkill,kind,"cast_6",1));
               abilityState.sap={until:abilitySerial+nativeAbilityNumber(sourceSkill,kind,"cast_7",2),manualEffectMultiplier:manualEffectMultiplier,debuff:false};
               break;
            case "maokai_c":
               for each(target in abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",700),null,nativeAbilityNumber(sourceSkill,kind,"cast_1",3),false,"nearest",null,true)) if(abilityHit(target,nativeAbilityNumber(sourceSkill,kind,"cast_3",1.8),nativeAbilityNumber(sourceSkill,kind,"cast_4",2),effect)) abilityControl(target,"root",nativeAbilityNumber(sourceSkill,kind,"cast_6",2));
               abilityShield(this,nativeAbilityNumber(sourceSkill,kind,"cast_7",0.2),nativeAbilityNumber(sourceSkill,kind,"cast_8",2),true);
               break;
            case "wukong_n":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",175)); if(!enemies.length) return false;
               if(abilityHit(enemies[0],nativeAbilityNumber(sourceSkill,kind,"cast_2",1.4)*scale,nativeAbilityNumber(sourceSkill,kind,"cast_3",1),effect)) abilityControl(enemies[0],"sunder",nativeAbilityNumber(sourceSkill,kind,"cast_6",2),nativeAbilityNumber(sourceSkill,kind,"cast_7",0.25)*scale);
               abilitySummon(id,nativeAbilityNumber(sourceSkill,kind,"cast_8",1),nativeAbilityNumber(sourceSkill,kind,"cast_9",0.35)*scale,nativeAbilityNumber(sourceSkill,kind,"cast_10",2),"wukong",null,true); checkMove(false,nativeAbilityNumber(sourceSkill,kind,"cast_12",200));
               break;
            case "wukong_c":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",700)); if(!enemies.length || !abilityDash(enemies[0])) return false; primary=enemies[0];
               targets=[primary].concat(abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_3",300),primary,nativeAbilityNumber(sourceSkill,kind,"cast_4",3),false,"nearest",[primary]));
               for(i=0;i<nativeAbilityNumber(sourceSkill,kind,"cast_7",2);i++) for each(target in targets) if(abilityHit(target,nativeAbilityNumber(sourceSkill,kind,"cast_8",1.3),nativeAbilityNumber(sourceSkill,kind,"cast_9",1),effect,nativeAbilityNumber(sourceSkill,kind,"cast_10",2.6)) && i==0) abilityControl(target,"stun",nativeAbilityNumber(sourceSkill,kind,"cast_13",1));
               addBuff("steel",nativeAbilityNumber(sourceSkill,kind,"cast_15",2),nativeAbilityNumber(sourceSkill,kind,"cast_16",0.4)*manualDefenseBuffMultiplier);
               break;
            case "gangplank_n":
               marked=hp/hpMax < nativeAbilityNumber(sourceSkill,kind,"cast_0",0.5); enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_1",600)); if(!enemies.length) return false;
               abilityHit(enemies[0],nativeAbilityNumber(sourceSkill,kind,"cast_3",1.6)*scale,nativeAbilityNumber(sourceSkill,kind,"cast_4",1),effect);
               if(marked) { removeAllDebuff(); abilityHeal(this,nativeAbilityNumber(sourceSkill,kind,"cast_5",0.4)*scale); }
               break;
            case "gangplank_c":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",800)); if(!enemies.length) return false; primary=enemies[0];
               abilityState.zone={line:primary.line,pos:primary.pos,left:nativeAbilityNumber(sourceSkill,kind,"cast_2",2),manualDamageMultiplier:manualDamageMultiplier,manualEffectMultiplier:manualEffectMultiplier};
               for each(target in abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_3",350),primary,nativeAbilityNumber(sourceSkill,kind,"cast_4",3))) if(abilityHit(target,nativeAbilityNumber(sourceSkill,kind,"cast_5",1.2),nativeAbilityNumber(sourceSkill,kind,"cast_6",1),effect)) abilityControl(target,"weak",nativeAbilityNumber(sourceSkill,kind,"cast_8",1),nativeAbilityNumber(sourceSkill,kind,"cast_9",0.2));
               break;
            case "yi_n":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",600),null,-1); if(!enemies.length) return false;
               coefficient=(enemies.length==nativeAbilityNumber(sourceSkill,kind,"cast_2",1) ? nativeAbilityNumber(sourceSkill,kind,"cast_3",2) : nativeAbilityNumber(sourceSkill,kind,"cast_4",1.1))*scale;
               for each(target in enemies.slice(0,nativeAbilityNumber(sourceSkill,kind,"cast_6",3))) abilityHit(target,coefficient,nativeAbilityNumber(sourceSkill,kind,"cast_7",1),effect);
               addBuff("fleeup",nativeAbilityNumber(sourceSkill,kind,"cast_9",1),nativeAbilityNumber(sourceSkill,kind,"cast_10",600)*scale*orangeFourStatBuffMultiplier);
               break;
            case "yi_c":
               addBuff("strong",nativeAbilityNumber(sourceSkill,kind,"cast_1",3),nativeAbilityNumber(sourceSkill,kind,"cast_2",0.5)); addBuff("hitup",nativeAbilityNumber(sourceSkill,kind,"cast_4",3),nativeAbilityNumber(sourceSkill,kind,"cast_5",800)*orangeFourStatBuffMultiplier); removeBuff("weak");
               abilityState.highlander={until:abilitySerial+nativeAbilityNumber(sourceSkill,kind,"cast_7",3),left:nativeAbilityNumber(sourceSkill,kind,"cast_8",2),debuff:false};
               if(skill0) skill0.useSkill();
               break;
            case "veigar_n":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",600)); if(!enemies.length) return false; target=enemies[0];
               if(abilityHit(target,nativeAbilityNumber(sourceSkill,kind,"cast_2",1.2)*scale,nativeAbilityNumber(sourceSkill,kind,"cast_3",2),effect) && target.getType()==1 && !target.isManualSummonUnit)
               {
                  var oldEvilStacks:int = int(abilityState.evilStacks);
                  abilityState.evilStacks = Math.min(nativeAbilityNumber(sourceSkill,kind,"cast_5",10),oldEvilStacks+nativeAbilityNumber(sourceSkill,kind,"cast_6",1));
                  if(int(abilityState.evilStacks) > oldEvilStacks) abilityState.evilStackBonus = Number(abilityState.evilStackBonus || nativeAbilityNumber(sourceSkill,kind,"cast_7",0)) + nativeAbilityNumber(sourceSkill,kind,"cast_8",0.03) * activeManualEffectMultiplier();
                  abilityFeedback("邪恶之力："+int(abilityState.evilStacks)+"/10","FX_S9160_STRONG");
               }
               break;
            case "veigar_c":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",700),null,nativeAbilityNumber(sourceSkill,kind,"cast_1",1),true,"ratio"); if(!enemies.length) enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_3",700));
               if(!enemies.length) return false;
               target=enemies[0];
               var previousVeigarHit:Number = Number(abilityState.veigarCastHit || 0);
               abilityState.veigarCastHit = previousVeigarHit+30000;
               try { abilityHit(target,nativeAbilityNumber(sourceSkill,kind,"cast_5",2)+nativeAbilityNumber(sourceSkill,kind,"cast_6",3)*(nativeAbilityNumber(sourceSkill,kind,"cast_7",1)-target.hp/target.hpMax),nativeAbilityNumber(sourceSkill,kind,"cast_8",2),effect); }
               finally { abilityState.veigarCastHit = previousVeigarHit; }
               break;
            case "elise_n":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",600)); if(!enemies.length) return false; target=enemies[0];
               coefficient=scale+Math.min(getDamage(),target.hp*nativeAbilityNumber(sourceSkill,kind,"cast_2",0.04)*scale)/Math.max(nativeAbilityNumber(sourceSkill,kind,"cast_3",1),getDamage());
               if(abilityHit(target,coefficient,nativeAbilityNumber(sourceSkill,kind,"cast_4",2),effect)) abilityControl(target,"stun",nativeAbilityNumber(sourceSkill,kind,"cast_6",1));
               break;
            case "elise_c":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",650),null,nativeAbilityNumber(sourceSkill,kind,"cast_1",1),true,"ratio"); if(!enemies.length || !abilityDash(enemies[0])) return false; target=enemies[0];
               coefficient=nativeAbilityNumber(sourceSkill,kind,"cast_5",1.8)+Math.min(getDamage()*nativeAbilityNumber(sourceSkill,kind,"cast_6",1.8),(target.hpMax-target.hp)*nativeAbilityNumber(sourceSkill,kind,"cast_7",0.12))/Math.max(nativeAbilityNumber(sourceSkill,kind,"cast_8",1),getDamage());
               abilityHit(target,coefficient,nativeAbilityNumber(sourceSkill,kind,"cast_9",2),effect); abilitySummon("A_2013_5",nativeAbilityNumber(sourceSkill,kind,"cast_11",2),nativeAbilityNumber(sourceSkill,kind,"cast_12",0.3),nativeAbilityNumber(sourceSkill,kind,"cast_13",2),"elise");
               break;
            case "riven_n":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",450)); if(!enemies.length || !abilityDash(enemies[0])) return false; primary=enemies[0];
               count=int(abilityState.rivenStep)%nativeAbilityNumber(sourceSkill,kind,"cast_3",3)+nativeAbilityNumber(sourceSkill,kind,"cast_4",1); abilityState.rivenStep=count%nativeAbilityNumber(sourceSkill,kind,"cast_5",3); abilityFeedback("折翼之舞：第"+count+"式",effect);
               for each(target in [primary].concat(abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_8",200),primary,nativeAbilityNumber(sourceSkill,kind,"cast_9",2),false,"nearest",[primary]))) if(abilityHit(target,(count==nativeAbilityNumber(sourceSkill,kind,"cast_11",3) ? nativeAbilityNumber(sourceSkill,kind,"cast_12",1.4) : nativeAbilityNumber(sourceSkill,kind,"cast_13",0.8))*scale,nativeAbilityNumber(sourceSkill,kind,"cast_14",1),effect) && count==nativeAbilityNumber(sourceSkill,kind,"cast_15",3)) abilityControl(target,"stun",nativeAbilityNumber(sourceSkill,kind,"cast_17",1));
               if(count==nativeAbilityNumber(sourceSkill,kind,"cast_18",2)) abilityShield(this,nativeAbilityNumber(sourceSkill,kind,"cast_19",0.6)*scale);
               break;
            case "riven_c":
               addBuff("strong",nativeAbilityNumber(sourceSkill,kind,"cast_1",2),nativeAbilityNumber(sourceSkill,kind,"cast_2",0.35));
               for each(target in abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_3",700),null,nativeAbilityNumber(sourceSkill,kind,"cast_4",3),false,"nearest",null,true)) abilityHit(target,nativeAbilityNumber(sourceSkill,kind,"cast_6",1.6)+nativeAbilityNumber(sourceSkill,kind,"cast_7",0.96)*(nativeAbilityNumber(sourceSkill,kind,"cast_8",1)-target.hp/target.hpMax),nativeAbilityNumber(sourceSkill,kind,"cast_9",1),effect);
               abilityState.rivenStep=nativeAbilityNumber(sourceSkill,kind,"cast_10",2);
               break;
            case "orianna_n":
               ally=abilityAlly(nativeAbilityNumber(sourceSkill,kind,"cast_0",3001),"front",true) || this; abilityState.ball=ally;
               abilityShield(ally,nativeAbilityNumber(sourceSkill,kind,"cast_2",0.8)*scale);
               for each(target in abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_3",300),ally,nativeAbilityNumber(sourceSkill,kind,"cast_4",2))) abilityHit(target,scale,nativeAbilityNumber(sourceSkill,kind,"cast_5",2),effect);
               break;
            case "orianna_c":
               ally=abilityState.ball as Avatar; if(!ally || ally.hp<=0 || ally.line!=line) ally=this; abilityState.ball=ally;
               targets=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_1",350),ally,nativeAbilityNumber(sourceSkill,kind,"cast_2",3));
               for each(target in targets) { abilityPull(target,ally,nativeAbilityNumber(sourceSkill,kind,"cast_3",200)); if(abilityHit(target,nativeAbilityNumber(sourceSkill,kind,"cast_4",2.2),nativeAbilityNumber(sourceSkill,kind,"cast_5",2),effect)) abilityControl(target,"stun",nativeAbilityNumber(sourceSkill,kind,"cast_7",1)); }
               abilityShield(ally,nativeAbilityNumber(sourceSkill,kind,"cast_8",0.8));
               break;
            case "nunu_n":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",175)); if(!enemies.length) return false;
               target=enemies[0]; abilityHit(target,(target.isManualSummonUnit ? nativeAbilityNumber(sourceSkill,kind,"cast_2",3) : nativeAbilityNumber(sourceSkill,kind,"cast_3",1.4))*scale,target.isManualSummonUnit ? nativeAbilityNumber(sourceSkill,kind,"cast_4",3) : nativeAbilityNumber(sourceSkill,kind,"cast_5",2),effect);
               abilityHeal(this,nativeAbilityNumber(sourceSkill,kind,"cast_6",0.7)*scale);
               break;
            case "nunu_c":
               abilityShield(this,nativeAbilityNumber(sourceSkill,kind,"cast_0",1.2)); abilityState.channel={pos:pos,line:line,manualDamageMultiplier:manualDamageMultiplier,manualEffectMultiplier:manualEffectMultiplier}; abilityFeedback("绝对零度：开始引导","FX_A_1073_MAGIC");
               break;
            case "alistar_n":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",500)); if(!enemies.length || !abilityDash(enemies[0])) return false; primary=enemies[0];
               targets=[primary].concat(abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_3",250),primary,nativeAbilityNumber(sourceSkill,kind,"cast_4",3),false,"nearest",[primary]));
               abilityHit(primary,nativeAbilityNumber(sourceSkill,kind,"cast_6",0.8)*scale,nativeAbilityNumber(sourceSkill,kind,"cast_7",2),effect,nativeAbilityNumber(sourceSkill,kind,"cast_8",1.4)*scale);
               for each(target in targets) if(abilityHit(target,nativeAbilityNumber(sourceSkill,kind,"cast_9",0.6)*scale,nativeAbilityNumber(sourceSkill,kind,"cast_10",2),effect,target===primary ? nativeAbilityNumber(sourceSkill,kind,"cast_11",1.4)*scale : nativeAbilityNumber(sourceSkill,kind,"cast_12",0))) abilityControl(target,"stun",nativeAbilityNumber(sourceSkill,kind,"cast_14",1));
               addBuff("taunt",nativeAbilityNumber(sourceSkill,kind,"cast_16",2));
               break;
            case "alistar_c":
               removeAllDebuff(); abilityHeal(this,nativeAbilityNumber(sourceSkill,kind,"cast_0",0.5));
               abilityState.guard={kind:"alistar",charges:nativeAbilityNumber(sourceSkill,kind,"cast_2",3),until:abilitySerial+nativeAbilityNumber(sourceSkill,kind,"cast_3",2),owner:this,manualEffectMultiplier:manualEffectMultiplier,debuff:false};
               break;
            case "diana_n":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",650)); if(!enemies.length) return false; primary=enemies[0];
               for each(target in [primary].concat(abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_2",250),primary,nativeAbilityNumber(sourceSkill,kind,"cast_3",3),false,"nearest",[primary]))) if(abilityHit(target,scale,nativeAbilityNumber(sourceSkill,kind,"cast_5",2),effect)) abilityMark(target,"moon",nativeAbilityNumber(sourceSkill,kind,"cast_7",3));
               break;
            case "diana_c":
               primary=abilityMarkedTarget("moon",nativeAbilityNumber(sourceSkill,kind,"cast_1",650)); if(!primary || !abilityDash(primary)) return false;
               targets=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_2",300),this,nativeAbilityNumber(sourceSkill,kind,"cast_3",3)); if(targets.indexOf(primary)<0) {targets.unshift(primary); targets=targets.slice(0,nativeAbilityNumber(sourceSkill,kind,"cast_6",3));}
               for each(target in targets)
               {
                  marked=target.abilityHasMark(this,"moon"); abilityPull(target,this,nativeAbilityNumber(sourceSkill,kind,"cast_8",150));
                  if(abilityHit(target,marked ? nativeAbilityNumber(sourceSkill,kind,"cast_9",2.7) : nativeAbilityNumber(sourceSkill,kind,"cast_10",1.8),nativeAbilityNumber(sourceSkill,kind,"cast_11",2),effect) && marked) delete target.abilityState["mark_moon_"+abilityIndex];
               }
               abilityShield(this,nativeAbilityNumber(sourceSkill,kind,"cast_13",1));
               break;
            case "khazix_n":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",500)); if(!enemies.length || !abilityDash(enemies[0])) return false;
               abilityHit(enemies[0],(abilityIsolated(enemies[0]) ? nativeAbilityNumber(sourceSkill,kind,"cast_4",2.4) : nativeAbilityNumber(sourceSkill,kind,"cast_5",1.6))*scale,nativeAbilityNumber(sourceSkill,kind,"cast_6",1),effect);
               break;
            case "khazix_c":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",700),null,-1,true); primary=null;
               for each(target in enemies) if(abilityIsolated(target)) {primary=target; break;}
               if(!primary && enemies.length) primary=enemies[0]; if(!primary || !abilityDash(primary,true)) return false;
               abilityHit(primary,abilityIsolated(primary) ? nativeAbilityNumber(sourceSkill,kind,"cast_3",4.2) : nativeAbilityNumber(sourceSkill,kind,"cast_4",2.8),nativeAbilityNumber(sourceSkill,kind,"cast_5",1),effect); addBuff("fleeup",nativeAbilityNumber(sourceSkill,kind,"cast_7",2),nativeAbilityNumber(sourceSkill,kind,"cast_8",800)*orangeFourStatBuffMultiplier);
               if(primary.hp<=0 && primary.getType()==1 && !primary.isManualSummonUnit) sourceSkill.abilityCooldownOverride=nativeAbilityNumber(sourceSkill,kind,"cast_11",3);
               break;
            case "malzahar_n":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",600)); if(!enemies.length) return false; target=enemies[0];
               if(target.buffs.purify) {target.removeBuff("purify",true); break;}
               target.abilityState["malz_"+abilityIndex]={owner:this,until:target.abilitySerial+nativeAbilityNumber(sourceSkill,kind,"cast_4",1),ticks:nativeAbilityNumber(sourceSkill,kind,"cast_5",3),tickDamage:getDamage()*nativeAbilityNumber(sourceSkill,kind,"cast_6",1)*scale*manualDamageMultiplier,hops:0,debuff:true};
               break;
            case "malzahar_c":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",650)); if(!enemies.length) return false; target=enemies[0];
               if(abilityHit(target,nativeAbilityNumber(sourceSkill,kind,"cast_2",2.4),nativeAbilityNumber(sourceSkill,kind,"cast_3",2),effect)) abilityControl(target,"stun",nativeAbilityNumber(sourceSkill,kind,"cast_5",2));
               abilitySummon("A_2013_5",nativeAbilityNumber(sourceSkill,kind,"cast_7",2),nativeAbilityNumber(sourceSkill,kind,"cast_8",0.35),nativeAbilityNumber(sourceSkill,kind,"cast_9",2),"malzahar",target);
               break;
            case "jinx_n":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",650)); if(!enemies.length) return false; primary=enemies[0];
               abilityHit(primary,nativeAbilityNumber(sourceSkill,kind,"cast_2",1.5)*scale,nativeAbilityNumber(sourceSkill,kind,"cast_3",1),effect);
               for each(target in abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_4",250),primary,nativeAbilityNumber(sourceSkill,kind,"cast_5",2),false,"nearest",[primary])) abilityHit(target,nativeAbilityNumber(sourceSkill,kind,"cast_7",1.1)*scale,nativeAbilityNumber(sourceSkill,kind,"cast_8",1),effect);
               break;
            case "jinx_c":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",1000),null,nativeAbilityNumber(sourceSkill,kind,"cast_1",1),true,"ratio"); if(!enemies.length) return false; primary=enemies[0];
               targets=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_4",300),primary,nativeAbilityNumber(sourceSkill,kind,"cast_5",2),false,"nearest",[primary]);
               abilityHit(primary,nativeAbilityNumber(sourceSkill,kind,"cast_7",2)+Math.min(nativeAbilityNumber(sourceSkill,kind,"cast_8",2)*getDamage(),(primary.hpMax-primary.hp)*nativeAbilityNumber(sourceSkill,kind,"cast_9",0.12))/Math.max(nativeAbilityNumber(sourceSkill,kind,"cast_10",1),getDamage()),nativeAbilityNumber(sourceSkill,kind,"cast_11",1),effect);
               for each(target in targets) abilityHit(target,nativeAbilityNumber(sourceSkill,kind,"cast_12",1.2),nativeAbilityNumber(sourceSkill,kind,"cast_13",1),effect);
               if(context && context.kills.length) {addBuff("strong",nativeAbilityNumber(sourceSkill,kind,"cast_15",2),nativeAbilityNumber(sourceSkill,kind,"cast_16",0.3)); addBuff("critup",nativeAbilityNumber(sourceSkill,kind,"cast_18",2),nativeAbilityNumber(sourceSkill,kind,"cast_19",800)*orangeFourStatBuffMultiplier); if(skill0) skill0.useSkill();}
               break;
            case "tahm_n":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",500)); if(!enemies.length) return false;
               if(abilityHit(enemies[0],nativeAbilityNumber(sourceSkill,kind,"cast_2",1.1)*scale,nativeAbilityNumber(sourceSkill,kind,"cast_3",2),effect)) abilityControl(enemies[0],"stun",nativeAbilityNumber(sourceSkill,kind,"cast_6",1));
               abilityState.grey={until:abilitySerial+nativeAbilityNumber(sourceSkill,kind,"cast_7",1),value:0,manualEffectMultiplier:manualEffectMultiplier}; abilityFeedback("灰色生命：开始储存","FX_S9160_SHIELD");
               break;
            case "tahm_c":
               ally=abilityAlly(nativeAbilityNumber(sourceSkill,kind,"cast_0",500),"ratio",true) || this;
               if(ally!==this) ally.reline(line,Math.max(0,Math.min(GameMapConfig.LINE_POS,pos+(team==1 ? nativeAbilityNumber(sourceSkill,kind,"cast_4",100) : -nativeAbilityNumber(sourceSkill,kind,"cast_5",100)))),-2147483648,0,0,true);
               abilityShield(ally,nativeAbilityNumber(sourceSkill,kind,"cast_9",1.6)); ally.addBuff("purify",nativeAbilityNumber(sourceSkill,kind,"cast_11",2)); addBuff("taunt",nativeAbilityNumber(sourceSkill,kind,"cast_13",2)); addBuff("steel",nativeAbilityNumber(sourceSkill,kind,"cast_15",2),nativeAbilityNumber(sourceSkill,kind,"cast_16",0.4)*manualDefenseBuffMultiplier);
               break;
            case "caitlyn_n":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",600)); if(!enemies.length) return false; target=enemies[0];
               if(abilityHit(target,scale,nativeAbilityNumber(sourceSkill,kind,"cast_2",1),effect)) abilityMark(target,"aim",nativeAbilityNumber(sourceSkill,kind,"cast_4",2),scale);
               checkMove(false,nativeAbilityNumber(sourceSkill,kind,"cast_5",250));
               break;
            case "caitlyn_c":
               primary=abilityMarkedTarget("aim",nativeAbilityNumber(sourceSkill,kind,"cast_1",1000),"farthest"); if(!primary) return false; target=primary;
               for each(other in abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_3",200),primary,-1,true,"nearest",[primary]))
               {
                  if(team==1 ? other.pos>primary.pos && other.pos<pos : other.pos<primary.pos && other.pos>pos) {target=other; break;}
               }
               addBuff("hitup",nativeAbilityNumber(sourceSkill,kind,"cast_8",1),nativeAbilityNumber(sourceSkill,kind,"cast_9",800)*orangeFourStatBuffMultiplier); marked=target.abilityHasMark(this,"aim");
               if(abilityHit(target,marked ? nativeAbilityNumber(sourceSkill,kind,"cast_11",5) : nativeAbilityNumber(sourceSkill,kind,"cast_12",4),nativeAbilityNumber(sourceSkill,kind,"cast_13",1),effect) && marked) delete target.abilityState["mark_aim_"+abilityIndex];
               break;
            case "kaelthas_n":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",600)); if(!enemies.length) return false; target=enemies[0];
               if(abilityHit(target,nativeAbilityNumber(sourceSkill,kind,"cast_2",0.8)*scale,nativeAbilityNumber(sourceSkill,kind,"cast_3",2),effect) && target.hp>0 && !target.buffs.purify) target.abilityState["bomb_"+abilityIndex]={owner:this,until:target.abilitySerial+nativeAbilityNumber(sourceSkill,kind,"cast_6",1),coefficient:nativeAbilityNumber(sourceSkill,kind,"cast_7",1.2)*scale,manualDamageMultiplier:manualDamageMultiplier,debuff:true};
               break;
            case "kaelthas_c":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",700)); if(!enemies.length) return false; primary=enemies[0];
               for each(target in [primary].concat(abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_2",300),primary,nativeAbilityNumber(sourceSkill,kind,"cast_3",3),false,"nearest",[primary])))
               {
                  state=target.abilityState["bomb_"+abilityIndex];
                  target.abilityState.bombConsumeOwner=this;
                  landed=abilityHit(target,state ? nativeAbilityNumber(sourceSkill,kind,"cast_6",4) : nativeAbilityNumber(sourceSkill,kind,"cast_7",2.2),nativeAbilityNumber(sourceSkill,kind,"cast_8",2),effect);
                  delete target.abilityState.bombConsumeOwner;
                  if(landed && state) delete target.abilityState["bomb_"+abilityIndex];
               }
               break;
            case "aoxing_n":
               enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_0",650)); if(!enemies.length) return false; primary=enemies[0]; targets=[primary]; marked=false;
               for(i=0;i<nativeAbilityNumber(sourceSkill,kind,"cast_3",3);i++)
               {
                  var bounceSource:Avatar = i == 0 ? this : primary;
                  if(i>0) { enemies=abilityEnemies(nativeAbilityNumber(sourceSkill,kind,"cast_6",300),primary,nativeAbilityNumber(sourceSkill,kind,"cast_7",1),false,"nearest",targets); if(!enemies.length) break; primary=enemies[0]; targets.push(primary); }
                  if(abilityHit(primary,(i==0 ? nativeAbilityNumber(sourceSkill,kind,"cast_11",1.4) : nativeAbilityNumber(sourceSkill,kind,"cast_12",1))*scale,nativeAbilityNumber(sourceSkill,kind,"cast_13",2),effect,0,bounceSource) && primary.getType()==1 && !primary.isManualSummonUnit) marked=true;
               }
               if(marked) { abilityState.thunder=Math.min(nativeAbilityNumber(sourceSkill,kind,"cast_16",3),int(abilityState.thunder)+nativeAbilityNumber(sourceSkill,kind,"cast_17",1)); abilityFeedback("风暴电荷："+int(abilityState.thunder)+"/3","FX_A_1114_MAGIC"); }
               break;
            case "aoxing_c":
               count=int(abilityState.thunder); abilityState.thunder=0; if(count > 0) abilityFeedback("释放风暴电荷："+count,"FX_A_1114_MAGIC"); i=-1; targets=[];
               for(var lane:int=0;lane<3;lane++)
               {
                  enemies=abilityCandidates(otherTeam,lane,pos,GameMapConfig.LINE_POS,-1,true,"front");
                  if(enemies.length>i) {i=enemies.length; targets=abilityCandidates(otherTeam,lane,pos,GameMapConfig.LINE_POS,nativeAbilityNumber(sourceSkill,kind,"cast_9",4),false,"front");}
               }
               i=0;
               for each(target in targets) if(abilityHit(target,nativeAbilityNumber(sourceSkill,kind,"cast_12",1.8)+nativeAbilityNumber(sourceSkill,kind,"cast_13",0.4)*count,nativeAbilityNumber(sourceSkill,kind,"cast_14",2),effect) && count==nativeAbilityNumber(sourceSkill,kind,"cast_15",3) && target.getType()==1 && !target.isManualSummonUnit && i++<nativeAbilityNumber(sourceSkill,kind,"cast_17",2)) abilityControl(target,"stun",nativeAbilityNumber(sourceSkill,kind,"cast_19",1));
               break;
            default: return false;
         }
         return true;
         }
         finally
         {
            if(context && context.owner === this)
            {
               if(hadManualFactor) context.manualDamageMultiplier = previousManualFactor;
               else delete context.manualDamageMultiplier;
               if(hadManualEffectFactor) context.manualEffectMultiplier = previousManualEffectFactor;
               else delete context.manualEffectMultiplier;
            }
         }
      }

      private function executeSantaSkin(kind:String, effect:String, sourceSkill:*) : Boolean
      {
         var targets:Array = kind == "santa_n" ? abilityCandidates(otherTeam,line,pos,GameMapConfig.LINE_POS,-1) : abilityAllEnemies();
         if(targets.length == 0 || hp <= 0) return false;
         if(kind == "santa_n")
         {
            // Lock this cast's repeat count before any of its hits can kill.
            var count:int = 1+int(abilityState.santaKills);
            for(var i:int = 0;i < count;i++)
            {
               targets = abilityCandidates(otherTeam,line,pos,GameMapConfig.LINE_POS,-1);
               if(targets.length == 0 || hp <= 0) break;
               var ticket:int = Random.getRandom(targets.length);
               var victim:Avatar = targets[((ticket % targets.length)+targets.length)%targets.length] as Avatar;
               abilityHit(victim,Number(sourceSkill.getNativeAction()[4]),2,effect);
               abilityState.santaStacks = int(abilityState.santaStacks)+1;
               abilityFeedback("邪恶攻击 "+int(abilityState.santaStacks)+"层","FX60_STRONG",16744448);
            }
         }
         else
         {
            for each(var target:Avatar in targets)
               if(abilityHit(target,0.3,3,effect) && target.hp > 0) abilityControl(target,"stun",1);
         }
         return true;
      }

      private function executeNurseSkin(kind:String, sourceSkill:*) : Boolean
      {
         if(hp <= 0 || !GameMap.currentMap) return false;
         var allies:Vector.<Avatar> = GameMap.currentMap.getAliveList(team);
         if(allies.length == 0) return false;
         var target:Avatar;
         var amount:int;
         if(kind == "nurse_n")
         {
            for each(target in allies) if(target.hp > 0) target.addBuff("purify",1);
            amount = Tools.toInt(Tools.toInt(getDamage()*(1+checkTalent(1)))*Number(sourceSkill.getNativeAction()[4]));
            for each(target in allies)
            {
               if(target.hp <= 0) continue;
               target.injured(amount,1,DisplayTools.getAttrs("FX60_HEAL"),4,this,false,this);
            }
         }
         else
         {
            var primary:Avatar = allies[0];
            for each(target in allies)
               if(Number(target.hp)/Math.max(1,target.hpMax) < Number(primary.hp)/Math.max(1,primary.hpMax)) primary = target;
            amount = Tools.toInt(hpMax*0.5);
            // Keep both entries when the most injured target is this caster.
            for each(target in [primary,this])
            {
               if(hp <= 0) break;
               if(target.hp <= 0) continue;
               target.addBuff("purify",1);
               target.addBuff("bless",1);
               target.injured(amount,1,DisplayTools.getAttrs("FX60_HEAL"),4,this,false,this);
            }
         }
         return true;
      }

      private function queueNurseHealing(amount:int, overheal:int = 0) : void
      {
         if(hp <= 0 || amount <= 0 || !skillB || !skillB.skills || !skillB.skills.length || skillB.skills[0][0] != "nurse_healing") return;
         if(!abilityState.nursePending) abilityState.nursePending = [];
         overheal = Math.max(0,Math.min(amount,overheal));
         var overflowRate:Number = skillB.skills[0].length > 2 ? Number(skillB.skills[0][2]) : 1;
         abilityState.nursePending.push(Tools.toInt((amount-overheal)*Number(skillB.skills[0][1])+overheal*overflowRate));
         if(abilityState.nurseBusy) return;
         abilityState.nurseBusy = true;
         try
         {
            while(abilityState.nursePending.length > 0 && hp > 0)
            {
               var damage:int = int(abilityState.nursePending.shift());
               if(damage <= 0) continue;
               var context:Object = beginAbilityAttack(this,"passive");
               try
               {
                  for each(var target:Avatar in abilityAllEnemies())
                  {
                     if(hp <= 0) break;
                     // Fixed true damage enters after AP/armor/miss/crit math.
                     target.injured(damage,1,DisplayTools.getAttrs("FX_S9150_TRUE"),3,this,false,this);
                  }
               }
               finally { endAbilityAttack(context); }
            }
         }
         finally
         {
            abilityState.nurseBusy = false;
            if(hp <= 0) abilityState.nursePending = [];
         }
      }

      private function queueSantaKill() : void
      {
         if(hp <= 0 || !skillB || !skillB.skills || !skillB.skills.length || skillB.skills[0][0] != "santa_kill") return;
         abilityState.santaStacks = int(abilityState.santaStacks)+int(skillB.skills[0][1]);
         abilityState.santaKills = int(abilityState.santaKills)+int(skillB.skills[0][2]);
      }

      private function executePolarSkin(kind:String, effect:String, sourceSkill:*) : Boolean
      {
         var targets:Array;
         var target:Avatar;
         if(kind == "polar_n")
         {
            targets = abilityCandidates(otherTeam,line,pos,GameMapConfig.LINE_POS,-1);
            if(targets.length == 0) return false;
            var params:Array = sourceSkill.getNativeAction();
            addBuff("critup",1,Number(params[4]));
            var reduction:Number = Number(params[5]);
            for each(target in targets)
               if(abilityHit(target,Number(params[6]),1,effect) && target.hp > 0)
                  abilityControl(target,"sunder",1,reduction/(1-reduction));
            return true;
         }
         targets = abilityAllEnemies();
         if(targets.length == 0) return false;
         var primary:Avatar = targets[0] as Avatar;
         for each(target in targets) if(target.getDamage() > primary.getDamage()) primary = target;
         targets = abilityCandidates(otherTeam,primary.line,primary.pos,300,-1);
         var oldHit:Number = abilityState.polarCastHit != null ? Number(abilityState.polarCastHit) : 0;
         abilityState.polarCastHit = oldHit+50000;
         try
         {
            for each(target in targets)
            {
               if(abilityHit(target,3,2,effect) && target.hp > 0)
               {
                  abilityControl(target,"curse",1);
                  abilityControl(target,"stun",1);
               }
            }
         }
         finally { abilityState.polarCastHit = oldHit; }
         return true;
      }

      private function polarBasicAttack() : void
      {
         if(hp <= 0 || !skillB || !skillB.skills || !skillB.skills.length || skillB.skills[0][0] != "polar_basic") return;
         var round:int = GameMap.currentMap ? GameMap.currentMap.roundNum : 0;
         if(abilityState.polarRound == null)
         {
            abilityState.polarRound = round;
            abilityState.polarCount = 0;
            abilityState.polarBasic = false;
         }
         var elapsed:int = round-int(abilityState.polarRound);
         if(elapsed > 0)
         {
            var lost:int = elapsed-(abilityState.polarBasic ? 1 : 0);
            abilityState.polarCount = Math.max(0,int(abilityState.polarCount)-lost);
            abilityState.polarRound = round;
            abilityState.polarBasic = false;
         }
         var policy:Array = skillB.skills[0];
         if(!abilityState.polarBasic) abilityState.polarCount = Math.min(int(policy[2]),int(abilityState.polarCount)+1);
         abilityState.polarBasic = true;
         var targets:Array = abilityCandidates(otherTeam,line,pos,GameMapConfig.LINE_POS,-1);
         if(targets.length == 0) return;
         var ticket:int = Random.getRandom(targets.length);
         var target:Avatar = targets[((ticket % targets.length)+targets.length)%targets.length] as Avatar;
         var context:Object = beginAbilityAttack(this,"passive");
         try { abilityHit(target,Number(policy[1])*int(abilityState.polarCount),1,"FX_S9004_ARC"); }
         finally { endAbilityAttack(context); }
      }

      private function abilityAllEnemies() : Array
      {
         var result:Array = [];
         if(!GameMap.currentMap) return result;
         for each(var enemy:Avatar in GameMap.currentMap.getAliveList(otherTeam))
            if(enemy && enemy.hp > 0) result.push(enemy);
         return result;
      }

      public function addPurifyCharges(count:int) : void
      {
         if(count < 1 || hp <= 0) return;
         removeAllDebuff();
         var previous:Buff = buffs["purify"] as Buff;
         count = Math.max(count,previous ? int(previous.value) : 0);
         removeBuff("purify");
         // Positive purify value stores charges; ordinary purify keeps value 0.
         var guard:Buff = new Buff("purify",0,count);
         buffs["purify"] = guard;
         if(GameMapLayer.gl) GameMapLayer.gl.delayCall(showBuff,GameMap.actionDelay,guard);
         abilityFeedback("净化（"+count+"层）","FX_S9150_PURIFY",10526975);
      }

      private function executeCatSkin(kind:String, scale:Number, effect:String, sourceSkill:*) : Boolean
      {
         var context:Object = currentAbilityAttack();
         if(!context || context.owner !== this || hp <= 0) return false;
         var targets:Array;
         var primary:Avatar;
         var target:Avatar;
         var wave:int;
         if(kind == "cat_n")
         {
            if(abilityState.root) return false;
            targets = abilityCandidates(otherTeam,line,pos,GameMapConfig.LINE_POS,3,false,"front");
            if(targets.length == 0) return false;
            primary = targets[0] as Avatar;
            var params:Array = sourceSkill.getNativeAction();
            addBuff("hitup",2,Number(params[4]));
            abilityDash(primary);
            var before:Number = Number(context.damage);
            for each(target in targets) abilityHit(target,Number(params[5]),3,effect);
            abilityHit(primary,Number(params[6]),3,effect);
            var restore:int = Tools.toInt(Math.max(0,Number(context.damage)-before)*Number(params[7]));
            flushParallelVisualBatch();
            if(hp > 0 && restore > 0) injured(restore,1,null,4,null,false,this);
            return true;
         }
         if(abilityAllEnemies().length == 0) return false;
         addPurifyCharges(2);
         context.catCaptainCapture = true;
         context.catCrits = 0;
         try
         {
            for(wave=0;wave<6;wave++)
            {
               targets = abilityAllEnemies();
               for each(target in targets) abilityHit(target,0.3,3,effect);
            }
         }
         finally { context.catCaptainCapture = false; }
         flushParallelVisualBatch();
         if(hp > 0 && int(context.catCrits) > 0) addBuff("strong",2,0.03*int(context.catCrits));
         return true;
      }

      private function queueCatSkinKill() : void
      {
         if(hp <= 0 || !skillB || !skillB.skills || !skillB.skills.length || skillB.skills[0][0] != "cat_passive") return;
         var round:int = GameMap.currentMap ? GameMap.currentMap.roundNum : 0;
         if(abilityState.catKillRound == null || int(abilityState.catKillRound) != round)
         {
            abilityState.catKillRound = round;
            abilityState.catKillCount = 0;
            abilityState.catKillPending = 0;
         }
         ++abilityState.catKillPending;
         if(abilityState.catKillBusy) return;
         abilityState.catKillBusy = true;
         var policy:Array = skillB.skills[0];
         try
         {
            while(int(abilityState.catKillPending) > 0 && int(abilityState.catKillCount) < int(policy[3]) && hp > 0)
            {
               --abilityState.catKillPending;
               ++abilityState.catKillCount;
               var context:Object = beginAbilityAttack(this,"passive");
               try
               {
                  for(var strike:int=0;strike<int(policy[2]);strike++)
                  {
                     var targets:Array = abilityAllEnemies();
                     if(targets.length == 0) break;
                     var ticket:int = Random.getRandom(targets.length);
                     var victim:Avatar = targets[((ticket % targets.length)+targets.length)%targets.length] as Avatar;
                     abilityHit(victim,Number(policy[1]),3,"FX_S9130_COMBO");
                  }
               }
               finally { endAbilityAttack(context); }
            }
         }
         finally
         {
            abilityState.catKillBusy = false;
            abilityState.catKillPending = 0;
         }
      }

      public function get isManualSummonUnit() : Boolean
      {
         return buffs && buffs["summon"] != null;
      }


      public static const TEST_DAMAGE_RATE:Number = 1;

      public static var MIN_DAMAGE_RATE:Number = 0.1;

      public static var REAL_DAMAGE_RATE:Number = 0.3;

      public static var SIGN_DAMAGE_RATE:Number = 1.5;

      public static var CRIT_RATE:Number = 2;

      public static var MISS_POINT:int = 20;

      public static var CRIT_POINT:int = 20;

      public static var MISS_MAX:int = 60;

      public static var CRIT_MAX:int = 80;

      public static var DANGEROUS_RATE:Number = 0.5;

      public static var POWER_RATE:Number = 1e-8;

      public static var POWER_HP:Number = 0.5;

      public static var POWER_DAMAGE:Number = 2;

      public static var POWER_DE_PH:Number = 0.625;

      public static var POWER_DE_MA:Number = 0.625;

      public static var POWER_SPEED_RANGE:int = 1000;

      public static var POWER_SKILL_0_STAR:Number = 0.1;

      public static var POWER_SKILL_0_LV:Number = 0.1;

      public static var POWER_SKILL_1_STAR:Number = 0.5;

      public static var PITH_MAX:int = 99999;

      public static var PITH_POINT:int = 10;

      public static const RES_SIDE:int = 94;

      public static const RES_STAND_SCALE:Number = 0.4;

      public static const MISS_COLOR:uint = 13684944;

      public static const HP_BIG:int = 5;

      public static const HP_LINE:int = 1000;

      public static const HP_HIDE_LINE:int = 10000;

      public static const HP_HIDE_BIG:int = 50000;

      public static const HP_HIDE_GOD:int = 250000;

      public static const ACTION_TIME:Number = 0.3;

      public static const AUTO_POS_TIME:Number = 0.6;

      public static const SHOW_TIME:Number = 0.5;

      public static const SKILL_TIME:Number = 0.5;

      public static const WAIT_TIME:Number = 0.4;

      public static const ACTION_SHORTCUT:Number = 0.08;

      public static const MOVE_TIME:Number = 0.4;

      public static const SWING_TIME:Number = 0.12;

      public static const HIT_TIME:Number = 0.2;

      public static const RE_LINE_TIME:Number = 2.8;

      public static const DEAD_TIME:Number = 0.5;

      public static const MISS_TIME:Number = 0.2;

      public static const ROTATION_TIME:Number = 0.3;

      public static const ATTACK_TIME:Number = 0.25;

      public static const AOE_TIME:Number = 0.15;

      public static const POISON_TIME:Number = 1;

      public static const BLESS_TIME:Number = 1;

      public static const PRE_TIME:Number = 0.05;

      public static const MG_MOVE_TIME:Number = 1.2;

      public static const CLOSE_LINE_TIME:Number = 2;

      public static const POP_STR_TIME:Number = 0.5;

      public static const POP_STR_LONG_TIME:Number = 0.75;

      public static const POP_STR_LONG_LONG_TIME:Number = 1;

      public static const POP_STR_SIZE:int = 35;

      public static const POP_STR_SMALL_SIZE:int = 25;

      public static const POP_STR_BIG_SIZE:int = 45;

      public static const DEAD_FLY_DELAY:Number = 0.4;

      public static const DEAD_FLY_RANDOM_X:int = 100;

      public static const DEAD_FLY_RATE:Number = 0.2;

      public static const DEAD_FLY_SPEED:int = 1000;

      public static const DEAD_FLY_FADE_TIME:Number = 0.1;

      public static const DEAD_FLY_NUM:int = 3;

      public static const DEAD_FLY_SCALE:Number = 1.1;

      public static const MISS_X:int = 40;

      public static const HIT_Y:int = 20;

      public static const ATTACK_Y:int = 25;

      public static const MOVE_POS:int = 400;

      public static const FIGHT_RES_SCALE:Number = 1;

      public static const SUMMON_RES_SCALE:Number = 0.8;

      public static const BOSS_RES_SCALE:Number = 1.3;

      public static const ACTION_SCALE:Number = 1.2;

      public static const BOUNCE_SCALE:Number = 1.15;

      public static const MISS_SCALE:Number = 0.9;

      public static const MOVE_ROTATION:Number = 0.1;

      public static const SWING_ROTATION:Number = 0.5;

      public static const SWING_TIMES:int = 3;

      public static var index:int = 0;

      public var isShowLock:Boolean = false;

      public var dragAvatar:Avatar;

      public var m_icon:Image;

      private var mLimitBreakEdges:Vector.<Image> = new Vector.<Image>();

      public var isOthers:Boolean;

      public var actionNum:int;

      public var id:String;

      public var isLocked:Boolean;

      public var isNPC:Boolean;

      public var indexID_s:int = 0;

      public var team:int;

      public var line:int;

      private var abilityPosition:int;
      public function get pos() : int { return abilityPosition; }
      public function set pos(value:int) : void
      {
         if(value != abilityPosition && abilityState) delete abilityState.channel;
         abilityPosition = value;
      }

      public var offset:Number = 0;

      public var offsetAim:Number = 0;

      public var hp:int;

      public var hpMax:int;

      public var ap:int;

      public var dePh:int;

      public var deMa:int;

      public var speed:int;

      public var range:int;

      public var hit:int;

      public var flee:int;

      public var crit:int;

      public var tough:int;

      public var isLeader:Boolean;

      public var isBoss:Boolean;

      public var isDrop:Boolean;

      public var dropRate:Number;

      public var dropId:String;

      public var talent:Talent;

      public var skill0:SkillSet;

      public var skill1:SkillSet;

      public var skill2:SkillSet;

      public var skillB:SkillSet;

      public var currentSkillKillContext:Object;
      public var manualFocusTarget:Avatar;
      public var manualSkillDots:Object;
      private var manualDotSerial:uint = 0;
      public var manualBattleStacks:Object;
      public var manualTimedStacks:Array;
      public var manualOwnerActionSerial:int = 0;
      private static var modEventDepth:int = 0;
      private static var modEventBudget:int = 0;

      public function hasModBuff(kind:String) : Boolean
      {
         if(kind == "root" && abilityState && abilityState.root) return true;
         if(kind == "timed_bless") return buffs && buffs["bless"] && Number(buffs["bless"].value) > 0;
         return buffs && buffs[kind] != null;
      }

      public function emitModEvent(event:String,source:Avatar = null,target:Avatar = null,amount:Number = 0,overheal:Number = 0) : Boolean
      {
         if(!skillB || !skillB.isModEffectSequence() || !GameMap.currentMap) return false;
         var row:Object = GlobalData.$mConfig_skill[skillB.skillSetData.id];
         var gate:Object = row ? row.modCondition : null;
         if(!gate || gate.kind != "event" || gate.event != event || (hp <= 0 && event != "death")) return false;
         if(abilityState.modEventBusy || modEventDepth >= 8 || (modEventDepth > 0 && gate.allowChain !== true)) return false;
         var other:Avatar = source === this ? target : source;
         if(gate.relation == "self" && other !== this) return false;
         if(gate.relation == "ally" && (!other || other.team != team || other === this)) return false;
         if(gate.relation == "enemy" && (!other || other.team == team)) return false;
         if(gate.unitType == "hero" && (!other || other.getType() != 1 || other.isManualSummonUnit)) return false;
         if(gate.unitType == "summon" && (!other || !other.isManualSummonUnit && other.getType() != 2)) return false;
         if(gate.minAmount != null && amount < Number(gate.minAmount)) return false;
         if(gate.hpBelow != null && Number(Math.max(0,hp))/Math.max(1,hpMax) > Number(gate.hpBelow)) return false;
         if(gate.requiredBuff && !hasModBuff(String(gate.requiredBuff))) return false;
         if(gate.absentBuff && hasModBuff(String(gate.absentBuff))) return false;
         var ownTurn:int = manualOwnerActionSerial;
         var readyTurn:int = abilityState.modEventReady == null ? skillB.skillSetData.warmup : int(abilityState.modEventReady);
         if(ownTurn < readyTurn) return false;
         var round:int = GameMap.currentMap.roundNum;
         if(abilityState.modEventRound == null || int(abilityState.modEventRound) != round)
         {
            abilityState.modEventRound = round; abilityState.modEventCount = 0;
         }
         var limit:int = gate.maxPerRound == null ? 1 : int(gate.maxPerRound);
         if(int(abilityState.modEventCount) >= limit) return false;
         var previous:Object = skillB.modEventContext;
         skillB.modEventContext = {event:event,source:source,target:target,amount:Math.max(0,amount),overheal:Math.max(0,overheal)};
         if(!skillB.canModEventCast()) { skillB.modEventContext = previous; return false; }
         if(modEventDepth == 0) modEventBudget = 64;
         if(modEventBudget <= 0) { skillB.modEventContext = previous; return false; }
         --modEventBudget; ++modEventDepth;
         abilityState.modEventBusy = true;
         abilityState.modEventCount = int(abilityState.modEventCount)+1;
         abilityState.modEventReady = ownTurn+skillB.skillSetData.cooldown;
         try { skillB.useSkill(); }
         finally { abilityState.modEventBusy = false; --modEventDepth; skillB.modEventContext = previous; }
         return true;
      }

      public function emitModTurnEnd() : Boolean
      {
         if(abilityState.modEventEndSerial != null && int(abilityState.modEventEndSerial) == manualOwnerActionSerial) return false;
         abilityState.modEventEndSerial = manualOwnerActionSerial;
         return emitModEvent("turn_end",this,this);
      }

      public var manualSummonFamilies:Object;
      public var manualAttackRangeOverride:Number = NaN;
      public var manualSkillDamageCapture:Object;
      public var manualLethalFloor:Object;
      public var currentSkillHitContext:Object;

      public var buffs:Object;

      public var lv:int = 0;

      public var exp:int = 0;

      public var slv:int = 0;

      public var loveExp:int = 0;

      public var morph:int;

      public var hpP:int;

      public var apP:int;

      public var dePhP:int;

      public var deMaP:int;

      public var phase:int;

      public var limitBreak:int;

      public var cultureSchema:String = "";

      public var equips:Vector.<Equip>;

      protected var m_buff:Sprite;

      protected var m_avatarRes:Sprite;

      protected var m_fightRes:Sprite;

      protected var m_fightBg:Sprite;

      protected var m_fightRange:Sprite;

      private var rangePreviewQueued:Boolean = false;

      private var rangeMoveEndsAt:Number = 0;

      public var m_actionNum:Sprite;

      protected var m_tf:TextField;

      protected var m_drop:DisplayObject;

      public var mDestiny:Object;

      public var mDNdata:Object;

      public var mData:Object;

      private var _checkListmyCurrHp:Array;

      private var _checkListotherCurrHp:Array;

      public var mBloodSpr:ProgressBar;

      private var tryndUndyingActive:Boolean = false;

      private var tryndUndyingRounds:int = 0;

      public var manualActionTypeOverride:int = -1;

      public function Avatar(param1:String, param2:Object = null, param3:Boolean = false)
      {
         super();
         // Battle aliases describe the active context (owned/enemy/assist).
         // Keep the instance id in param2; never derive its definition from it.
         if(param2 != null && !(param2 is Array) && param2.aid != null && param2.base_aid != null)
         {
            param1 = String(param2.aid);
         }
         param1 = param1.replace(".","");
         var _loc4_:int = param1.indexOf("|");
         if(!param2 && !param3)
         {
            param2 = getUserAvatarObj(param1);
         }
         if(_loc4_ > -1)
         {
            id = param1;
            param1 = param1.slice(0,_loc4_);
            m_data = AvatarManager.getOnlyExample().getData(param1);
         }
         else
         {
            _loc4_ = param1.indexOf("-");
            if(_loc4_ > -1)
            {
               param1 = param1.slice(0,_loc4_);
            }
            m_data = AvatarManager.getOnlyExample().getData(param1);
         }
         init(param2);
      }

      public static function getUserAvatarObj(param1:String = "0", param2:Object = null) : Object
      {
         var _loc3_:Object = null;
         var _loc4_:String = null;
         var _loc5_:Object = {};
         if(GlobalData.$isExploration)
         {
            _loc3_ = GlobalData.$exploration_select_avatar;
         }
         else
         {
            if(!param2)
            {
               param2 = GlobalData.$userData;
            }
            if(param2)
            {
               _loc3_ = param2.avatars;
            }
         }
         if(param1.indexOf("|") > -1)
         {
            param1 = param1.split("|")[1];
         }
         if(Tools.strIsNumber(param1))
         {
            for(_loc4_ in _loc3_)
            {
               if(_loc4_.split("|")[1] == param1)
               {
                  _loc5_ = Tools.clone(_loc3_[_loc4_]);
                  _loc5_.aid = _loc4_;
                  return _loc5_;
               }
            }
         }
         return null;
      }

      public static function getPosPer(param1:int, param2:int = 1) : Number
      {
         var _loc3_:Number = param1 / GameMapConfig.LINE_POS;
         _loc3_ = Math.round(_loc3_ * 100) / 100;
         return param2 == 1 ? 1 - _loc3_ : _loc3_;
      }

      public static function getColorMatrixFilter(param1:int = 1) : ColorMatrixFilter
      {
         var _loc3_:Array = null;
         var _loc2_:ColorMatrixFilter = new ColorMatrixFilter();
         param1 = 3;
         if(param1 == 0)
         {
            _loc3_ = [1,0,0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,1,0];
         }
         else if(param1 == -1)
         {
            _loc3_ = [0.95,0,0,0,0,0,1.5,0,0,0,0,0,1.05,0,0,0,0,0,1,0];
         }
         else if(param1 == 1)
         {
            _loc3_ = [0,0,1,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,1,0];
         }
         else if(param1 == 2)
         {
            _loc3_ = [0.9,0.1,0.2,0,0,0.1,0.9,0.2,0,0,0.2,0.3,0.5,0,0,0,0,0,1,0];
         }
         else if(param1 == 3)
         {
            _loc3_ = [1.1,-0.1,-0.1,0,0,-0.1,1.3,-0.1,0,0,-0.1,-0.1,1.1,0,0,0,0,0,1,0];
         }
         _loc2_.matrix = Vector.<Number>(_loc3_);
         _loc2_.adjustContrast(-0.1);
         _loc2_.adjustSaturation(0.2);
         _loc2_.adjustHue(-0.15);
         return _loc2_;
      }

      public static function getPhaseMax(param1:String) : int
      {
         var _loc5_:Array = null;
         var _loc3_:Object = null;
         var _loc2_:int = int(param1.slice(2,3));
         var _loc4_:int = int(param1.split("_")[2]);
         var _loc6_:Array = GlobalData.$mConfig_simple.phase_config;
         if(_loc2_ == 1)
         {
            _loc3_ = _loc6_[0];
         }
         else
         {
            _loc3_ = _loc6_[1];
         }
         _loc5_ = _loc3_[String(_loc4_)];
         if(_loc5_)
         {
            return _loc5_[1];
         }
         return 0;
      }

      public static function countDamage(param1:Avatar, param2:Avatar, param3:int, param4:int = -1, param5:Number = 1) : Array
      {
         var _loc7_:Number = Number(NaN);
         var _loc6_:Array = [];
         _loc6_[1] = AvatarData.damageRate(param1.avatarData.signType,param2.avatarData.signType);
         _loc7_ = Tools.toInt(param3 * _loc6_[1]);
         trace(_loc7_ + "is克制后的伤害" + "ph" + param2.getDePh() + "ma" + param2.getDeMa());
         if(param2.checkTalent(2) != 0 || param2.checkTalent(3) != 0)
         {
            trace(param2.getDePh() + "|||||||||||||||||||||||||||||||" + param2.id + "|||||||||||||||||||||||||||||||||" + param2.getDefenseAgainst(param1,1));
            trace(param2.getDeMa() + "|||||||||||||||||||||||||||||||" + param2.id + "|||||||||||||||||||||||||||||||||" + param2.getDefenseAgainst(param1,2));
         }
         if(param4 == 1)
         {
            _loc7_ = Math.max(_loc7_ * MIN_DAMAGE_RATE,_loc7_ - param2.getDefenseAgainst(param1,1));
         }
         else if(param4 == 2)
         {
            _loc7_ = Math.max(_loc7_ * MIN_DAMAGE_RATE,_loc7_ - param2.getDefenseAgainst(param1,2));
         }
         else if(param4 == 3)
         {
            _loc7_ *= REAL_DAMAGE_RATE;
         }
         else if(param4 == 5)
         {
            _loc7_ = 0;
         }
         else if(param4 == 0)
         {
            _loc7_ = 0;
         }
         else if(param4 == 4)
         {
            _loc7_ = _loc7_;
         }
         _loc7_ = Tools.toInt(_loc7_);
         trace(_loc7_);
         _loc6_[0] = Tools.toInt(_loc7_ * param5);
         trace(param5 + "heheheheheh" + _loc6_[0]);
         _loc6_[1] = _loc6_[1] == SIGN_DAMAGE_RATE ? true : false;
         return _loc6_;
      }

      public static function checkCrit(param1:Avatar, param2:Avatar) : Number
      {
         var _loc7_:Number = Number(NaN);
         var _loc6_:* = GlobalData.$mConfig_simple.attack;
         var _loc5_:int = Tools.toInt(param1.getCrit() + param1.getCrit() * param1.checkTalent(6));
         var _loc8_:int = Tools.toInt(param2.getTough() + param2.getTough() * param2.checkTalent(7));
         trace("oldCrit" + param1.getCrit() + "|||||||||||||||newCrit" + _loc5_);
         trace("oldTough" + param2.getTough() + "|||||||||||||||newTough" + param2.getTough());
         var _loc4_:int = Tools.toInt(Math.min(_loc6_[7],Math.max(0,_loc6_[5] + 100 * (_loc5_ - _loc8_) / (_loc5_ + _loc8_ + _loc6_[11]))));
         GameMapTools.gameTrace("暴击判定",param1.id,param2.id);
         var _loc3_:Boolean = Random.getRandom() < _loc4_;
         if(_loc3_)
         {
            _loc7_ = _loc6_[3] + _loc5_ * _loc6_[16] / (_loc5_ + _loc6_[12]);
            GameMapTools.gameTrace("暴击倍数",_loc7_);
            return _loc7_;
         }
         return 1;
      }

      public static function missTween(param1:Avatar) : void
      {
         var _loc3_:Sprite = param1.fightRes;
         var _loc2_:int = 40;
         if(param1.offset < 0)
         {
            _loc2_ = -_loc2_;
         }
         _loc2_ = -_loc2_;
         var _loc6_:Tween = new Tween(_loc3_,0.2,"easeOut");
         _loc6_.scaleTo(param1.getScale() * 0.9);
         _loc6_.animate("pivotX",_loc2_);
         var _loc5_:Tween = new Tween(_loc3_,0.2,"easeIn");
         _loc5_.delay = 0.2;
         _loc5_.scaleTo(param1.getScale());
         _loc5_.animate("pivotX",0);
         var _loc4_:GameMapLayer = GameMapLayer.gl;
         _loc4_.addTween(_loc6_);
         _loc4_.addTween(_loc5_);
      }

      public static function attackTween(param1:Avatar, param2:Avatar, param3:int = -1, param4:Number = 0) : void
      {
         var _loc8_:Sprite = null;
         var _loc9_:Sprite = null;
         var _loc12_:Number = Number(NaN);
         var _loc6_:int = 0;
         var _loc5_:int = 0;
         var _loc11_:Number = Number(NaN);
         if(param3 < 0 && (!param1 || !param2))
         {
            return;
         }
         if(param1)
         {
            _loc8_ = param1.fightRes;
         }
         if(param2)
         {
            _loc9_ = param2.fightRes;
         }
         var _loc10_:int = 25;
         if(param1.team == 1)
         {
            _loc10_ = -_loc10_;
         }
         _loc11_ = 0;
         var _loc13_:Number = 0.25;
         var _loc15_:Tween = new Tween(_loc8_,_loc13_,"easeOut");
         _loc15_.delay = _loc11_ + param4;
         if(param3 >= 0)
         {
            _loc15_.animate("x",param3);
         }
         else if(param1 != param2 && param1.line == param2.line)
         {
            _loc12_ = GameMapTools.getRadians(new Point(_loc8_.x,_loc8_.y),new Point(_loc9_.x,_loc9_.y));
            _loc6_ = Math.abs(_loc10_) * Math.cos(_loc12_);
            _loc5_ = Math.abs(_loc10_) * Math.sin(_loc12_);
            _loc15_.animate("x",_loc8_.x + _loc6_);
            _loc15_.animate("y",_loc8_.y + _loc5_);
         }
         else
         {
            _loc15_.animate("y",_loc8_.y + _loc10_);
         }
         _loc15_.scaleTo(param1.getScale() * 0.9);
         var _loc14_:Tween = new Tween(_loc8_,0.25,"easeIn");
         _loc14_.delay = 0.25 + _loc11_ + param4;
         _loc14_.scaleTo(param1.getScale());
         _loc14_.animate("x",_loc8_.x);
         _loc14_.animate("y",_loc8_.y);
         var _loc7_:GameMapLayer = GameMapLayer.gl;
         _loc7_.addTween(_loc15_);
         _loc7_.addTween(_loc14_);
      }

      public static function sortOnPosLine(param1:Avatar, param2:Avatar) : int
      {
         var _loc4_:int = param1.pos;
         var _loc3_:int = param2.pos;
         if(_loc4_ < _loc3_)
         {
            return -1;
         }
         if(_loc4_ > _loc3_)
         {
            return 1;
         }
         return 0;
      }

      public function get resId() : String
      {
         var _loc1_:String = avatarData.res;
         if(morph > 0)
         {
            _loc1_ += ".";
         }
         return _loc1_;
      }

      public function get isBot() : Boolean
      {
         return id.indexOf("-") != -1;
      }

      public function setDestinyAndDN(param1:String = "", param2:Array = null, param3:Array = null, param4:Object = null, param5:Object = null, param6:Boolean = false) : void
      {
         mDestiny = PanelCenterDNTeam.getDestinyMyAll(param1 == "" ? id : param1,param2,param3,param4,param5,param6);
         mDNdata = PanelDetailDN.getDNAttrsAllValue(param5);
         if(mDestiny.skill0.length > 0)
         {
            skill0 = new SkillSet(mDestiny.skill0,this,slv);
         }
         if(mDestiny.skill1.length > 0)
         {
            skill1 = new SkillSet(mDestiny.skill1,this,1,true);
         }
      }

      public function clearDNdata() : void
      {
         mDNdata = null;
      }

      public function clearDestinydata() : void
      {
         mDestiny = null;
      }

      public function setEquips(param1:Array = null, param2:Boolean = true, param3:Object = null) : void
      {
         var _loc6_:Array = null;
         var _loc4_:int = 0;
         var _loc8_:int = 0;
         var _loc5_:Equip = null;
         var _loc7_:* = undefined;
         if(param1 == null && param2)
         {
            _loc6_ = GlobalData.$userData.as_equips;
            _loc4_ = getIndex();
            if(_loc4_ >= 0)
            {
               param1 = _loc6_[getIndex()];
            }
            else
            {
               param1 = null;
            }
         }
         equips = new Vector.<Equip>();
         if(!param1 || param1.length == 0)
         {
            skill2 = null;
            return;
         }
         if(param2)
         {
            param3 = GlobalData.$userData.my_equips;
            if(!param3)
            {
               return;
            }
            _loc8_ = 0;
            while(_loc8_ < param1.length)
            {
               _loc7_ = param3[param1[_loc8_]];
               if(_loc7_)
               {
                  _loc5_ = new Equip(param1[_loc8_],_loc7_);
                  equips.push(_loc5_);
               }
               _loc8_++;
            }
         }
         else
         {
            _loc8_ = 0;
            while(_loc8_ < param1.length)
            {
               if(param3)
               {
                  _loc7_ = param3[param1[_loc8_]];
               }
               else
               {
                  _loc7_ = param1[_loc8_];
               }
               if(_loc7_)
               {
                  _loc5_ = new Equip(_loc7_.eid,_loc7_);
                  equips.push(_loc5_);
               }
               _loc8_++;
            }
         }
         skill2 = getBookSkill();
      }

      public function getIndex() : int
      {
         var _loc1_:Array = GlobalData.$userData.team[0];
         return _loc1_.indexOf(id);
      }

      public function get avatarData() : AvatarData
      {
         return m_data as AvatarData;
      }

      public function getEffectiveActionType() : int
      {
         return manualActionTypeOverride >= 1 && manualActionTypeOverride <= 4 ? manualActionTypeOverride : avatarData.actionType;
      }

      public function get otherTeam() : int
      {
         return 3 - team;
      }

      public function get posPer() : Number
      {
         return getPosPer(pos,team);
      }

      public function refreshReline(param1:int = -1, param2:int = -1, param3:int = -1) : void
      {
         var _loc4_:GameMapLayer = GameMapLayer.gl;
         _loc4_.addAvatar(this,-1);
         refreshPos(param1,param2,param3);
      }

      public function refreshPos(param1:int = -1, param2:int = -1, param3:int = -1) : void
      {
         var _loc4_:DisplayObject = null;
         if(param1 < 0)
         {
            param1 = line;
         }
         if(param2 < 0)
         {
            param2 = pos;
         }
         if(param3 < 0)
         {
            param3 = offset;
         }
         _loc4_ = fightRes;
         _loc4_.x = GameMapConfig.offsetToPixel(param3);
         _loc4_.y = GameMapConfig.posToPixel(param2);
      }

      public function hideRange() : void
      {
         if(m_fightRange)
         {
            m_fightRange.visible = false;
         }
         fightRes.rotation = 0;
         fightRes.scaleX = fightRes.scaleY = getScale();
      }

      public function showRange(param1:int, param2:int, param3:int) : void
      {
         var _map:GameMap = GameMap.currentMap;
         var _layer:GameMapLayer = GameMapLayer.gl;
         if(!_map || !_map.isFight || GameMap.currentAvatar !== this || hp <= 0 || !m_fightRes || !m_fightRes.parent || !_layer || !_layer.effectLayer || !_layer.lineLayerList)
         {
            return;
         }
         var _showLine:int = _map.getShowLine(param1);
         if(_showLine < 0 || _showLine >= _layer.lineLayerList.length) return;
         var _bounds:Rectangle = rangePreviewBounds(param2,param3,_layer.lineLayerList.length,_layer.getLineX(_showLine));
         if(!m_fightRange)
         {
            m_fightRange = new Sprite();
            m_fightRange.name = "attackRangeOutline";
            m_fightRange.touchable = false;
            var _color:uint = team == 1 ? 3459327 : 16743262;
            for(var _edge:int = 0;_edge < 4;_edge++)
            {
               m_fightRange.addChild(new Quad(1,1,_color));
            }
            m_fightRange.alpha = 0.7;
         }
         if(m_fightRange.parent != _layer.effectLayer)
         {
            m_fightRange.removeFromParent();
            _layer.effectLayer.addChildAt(m_fightRange,0);
         }
         m_fightRange.x = _bounds.x;
         m_fightRange.y = _bounds.y;
         var _stroke:Number = Math.max(1,Math.min(3,_bounds.height / 4));
         var _top:Quad = m_fightRange.getChildAt(0) as Quad;
         var _bottom:Quad = m_fightRange.getChildAt(1) as Quad;
         var _left:Quad = m_fightRange.getChildAt(2) as Quad;
         var _right:Quad = m_fightRange.getChildAt(3) as Quad;
         _top.width = _bottom.width = _bounds.width;
         _top.height = _bottom.height = _stroke;
         _bottom.y = _bounds.height - _stroke;
         _left.width = _right.width = _stroke;
         _left.height = _right.height = _bounds.height;
         _right.x = _bounds.width - _stroke;
         m_fightRange.visible = true;
      }

      public static function rangePreviewBounds(param1:int, param2:int, param3:int, param4:Number) : Rectangle
      {
         var _allLines:Boolean = param2 > GameMapConfig.LINE_POS;
         var _width:Number = _allLines ? GameMapConfig.FIGHT_WIDTH : GameMapConfig.FIGHT_WIDTH / Math.max(1,param3);
         var _first:int = Math.max(0,Math.min(GameMapConfig.LINE_POS,param1 - Math.max(0,param2)));
         var _last:int = Math.max(_first,Math.min(GameMapConfig.LINE_POS,param1 + Math.max(0,param2)));
         var _top:Number = GameMapConfig.posToPixel(_first);
         return new Rectangle(_allLines ? 0 : param4 - _width * 0.5,_top,Math.max(1,_width),Math.max(2,GameMapConfig.posToPixel(_last) - _top));
      }

      public static function rangePreviewSchedule(param1:Number, param2:Number) : Array
      {
         var _start:Number = Math.max(param1,param2);
         return [_start,_start + 0.2];
      }

      private function queueRangePreview() : void
      {
         if(rangePreviewQueued || GameMap.currentAvatar !== this || !GameMapLayer.gl)
         {
            return;
         }
         rangePreviewQueued = true;
         var _schedule:Array = rangePreviewSchedule(GameMap.actionDelay,rangeMoveEndsAt);
         GameMapLayer.gl.delayCall(showRange,_schedule[0],line,pos,getRange());
         GameMapLayer.gl.delayCall(hideRange,_schedule[1]);
         GameMap.actionDelay = _schedule[1];
      }

      public function getAvatarRes(param1:Boolean = false, param2:Boolean = false, param3:Boolean = false) : Sprite
      {
         if(!m_avatarRes)
         {
            m_avatarRes = newAvatarRes(null,param1,param2,param3);
         }
         if(!GlobalData.modCardFrame(avatarData.res + "_icon0000") && !m_avatarRes.getChildByName("limitBreakEdge")) m_avatarRes.flatten();
         return m_avatarRes;
      }

      public function getPithNum() : int
      {
         if(isWeightedCultivation())
         {
            var weights:Object = GlobalData.$mConfig_simple && GlobalData.$mConfig_simple.culture && GlobalData.$mConfig_simple.culture.weighted ? GlobalData.$mConfig_simple.culture.weighted.weights : null;
            return Math.max(0,hpP) * (weights && weights.hp != null ? int(weights.hp) : 1) + Math.max(0,apP) * (weights && weights.ap != null ? int(weights.ap) : 12) + Math.max(0,dePhP) * (weights && weights.de_ph != null ? int(weights.de_ph) : 10) + Math.max(0,deMaP) * (weights && weights.de_ma != null ? int(weights.de_ma) : 10);
         }
         return hpP + apP + deMaP + dePhP;
      }

      public function isWeightedCultivation() : Boolean
      {
         return cultureSchema == "weighted-v2" && getType() == 1 && (getStar() == 5 || getStar() == 6);
      }

      public function getCultivationCap() : int
      {
         var culture:Object = GlobalData.$mConfig_simple ? GlobalData.$mConfig_simple.culture : null;
         if(!culture) return 0;
         if(isWeightedCultivation())
         {
            var weighted:Object = culture.weighted;
            var star:Object = weighted && weighted.stars ? weighted.stars[String(getStar())] : null;
            if(!star) return 0;
            return Math.max(0,int(star.cap_base) + Math.min(3,Math.max(0,phase)) * int(star.cap_per_phase));
         }
         var base:int = Math.max(0,int(culture.max_pith_base));
         var absolute:int = culture.max_pith != null ? Math.max(0,int(culture.max_pith)) : base;
         var bonus:int = mData && mData.pith_max != null ? Math.max(0,int(mData.pith_max)) : 0;
         return Math.min(absolute,base + bonus);
      }

      public function getCultivationDisplayScale() : int
      {
         return isWeightedCultivation() ? 1 : int(GlobalData.$mConfig_simple.culture.culture_pith);
      }

      public function newAvatarRes(param1:Sprite = null, param2:Boolean = false, param3:Boolean = false, param4:Boolean = false) : Sprite
      {
         if(param1) clearLimitBreakEdge(param1);
         var _loc6_:Image = null;
         var _loc9_:Boolean = false;
         var _loc11_:Image = null;
         var _loc14_:int = 0;
         var _loc8_:Image = null;
         var _loc16_:Image = null;
         var _loc13_:Number = Number(NaN);
         var _loc12_:Number = Number(NaN);
         var _loc7_:* = null;
         if(param1)
         {
            param1.removeChildren(0,-1,true);
         }
         if(!param1)
         {
            param1 = new Sprite();
         }
         m_icon = null;
         if(param2)
         {
            _loc6_ = GlobalFunction.createImage("UI_bg_card_2_0005");
            _loc6_.name = "avatar";
            if(team == 1)
            {
               _loc6_.color = 13158;
            }
            else
            {
               _loc6_.color = 8388608;
            }
            _loc6_.touchable = false;
            param1.addChild(_loc6_);
         }
         if(!m_icon)
         {
            m_icon = GlobalFunction.getAvatarIcon(avatarData.res);
            _loc9_ = m_icon.width > 100;
            m_icon.x = _loc9_ ? -5 : 0;
            m_icon.y = _loc9_ ? -5 : 0;
         }
         m_icon.touchable = true;
         param1.addChild(m_icon);
         var hasLimitBreakVisual:Boolean = limitBreak > 0 && getType() == 1 && (getStar() == 5 || getStar() == 6);
         if(hasLimitBreakVisual || morph > 0)
         {
            _loc14_ = Math.min(1,Math.max(0,getStar() - 5));
            _loc11_ = GlobalFunction.createImage("UI_bg_card_4_2_ 000" + String(_loc14_));
            _loc11_.touchable = false;
            _loc11_.x = m_icon.x - 3;
            _loc11_.y = m_icon.y - 1;
            param1.addChild(_loc11_);
            if(hasLimitBreakVisual)
            {
               _loc11_.name = "limitBreakEdge";
               mLimitBreakEdges.push(_loc11_);
               var pulse:Tween = new Tween(_loc11_,0.85,"easeInOut");
               pulse.animate("alpha",0.45);
               pulse.reverse = true;
               pulse.repeatCount = 0;
               if(GlobalData.$mStarling) GlobalData.$mStarling.juggler.add(pulse);
            }
         }
         if(hasLimitBreakVisual || getStar() == 6 && phase >= 3)
         {
            var breakColor:uint = getStar() == 5 ? 0xB561F1 : 0xFF9B32;
            var breakLabel:TextField = GlobalTextStyle.getTextField(getStar() == 6 && phase >= 3 ? "满阶" : "突破极限",15,breakColor,"center",m_icon.width,20);
            breakLabel.x = m_icon.x;
            breakLabel.y = m_icon.y - 21;
            breakLabel.touchable = false;
            param1.addChild(breakLabel);
         }
         var _loc10_:Image = GlobalFunction.createImage("UI_tag_0_000" + (String(this.avatarData.damageType - 1)));
         _loc10_.touchable = false;
         _loc10_.x = 28;
         _loc10_.y = m_icon.y + m_icon.height - _loc10_.height - 11;
         if(phase > 0)
         {
            _loc8_ = GlobalFunction.createImage("UI_tag_0_1_000" + (String(phase - 1)));
            _loc8_.touchable = false;
            _loc8_.x = _loc10_.x - 26;
            _loc8_.y = _loc10_.y + 7;
            param1.addChild(_loc8_);
         }
         param1.addChild(_loc10_);
         var _loc5_:Image = GlobalFunction.createImage("UI_tag_1_000" + (String(this.avatarData.signType - 1)));
         _loc5_.touchable = false;
         _loc5_.x = _loc10_.x + int((_loc10_.width - _loc5_.width) * 0.5);
         _loc5_.y = _loc10_.y + int((_loc10_.height - _loc5_.height) * 0.5) - 1;
         param1.addChild(_loc5_);
         if(param4)
         {
            _loc16_ = GlobalFunction.createImage("UI_btn_over_20_0000");
            _loc16_.visible = false;
            _loc16_.name = "UI_btn_over_20_0000";
            _loc16_.touchable = false;
            param1.addChild(_loc16_);
         }
         var _loc15_:int = getPithNum();
         if(_loc15_ > 0)
         {
            _loc13_ = _loc10_.x;
            _loc12_ = _loc10_.y;
         }
         return param1;
      }

      private function clearLimitBreakEdge(container:Sprite = null) : void
      {
         for(var i:int = mLimitBreakEdges.length - 1; i >= 0; i--)
         {
            var image:Image = mLimitBreakEdges[i];
            if(container && image.parent != container) continue;
            if(GlobalData.$mStarling) GlobalData.$mStarling.juggler.removeTweens(image);
            mLimitBreakEdges.splice(i,1);
         }
      }

      public function refreshIcon() : void
      {
         if(m_icon && m_icon.filter)
         {
            m_icon.filter.cache();
         }
      }

      public function newFightRes(param1:Sprite = null) : Sprite
      {
         var _loc2_:String = null;
         var _loc3_:Sprite = null;
         var _loc7_:Image = null;
         if(param1)
         {
            param1.removeChildren(0,-1,true);
         }
         if(!param1)
         {
            param1 = new Sprite();
         }
         if(iconStyle == 1)
         {
            _loc3_ = newAvatarRes(null,true,isLeader);
            _loc3_.pivotX = 94 / 2;
            _loc3_.pivotY = 94 / 2;
            param1.addChild(_loc3_);
            mBloodSpr = new ProgressBar(team,hp / hpMax,hpMax);
            mBloodSpr.y = -_loc3_.pivotY - 5;
            param1.addChild(mBloodSpr);
            if(isLeader)
            {
               _loc7_ = DisplayTools.newImg("aLeader");
               _loc7_.y = mBloodSpr.y - 25;
               param1.addChildAt(_loc7_,0);
            }
            m_buff = new Sprite();
            param1.addChild(m_buff);
            if(actionNum >= 0)
            {
               param1.addEventListener("touch",this.onTouch);
            }
            if(_loc7_)
            {
               _loc7_.touchable = false;
            }
            m_buff.touchable = false;
            param1.touchable = true;
            return param1;
         }
         m_fightBg = new Sprite();
         param1.addChild(m_fightBg);
         var _loc5_:Image = new Image(GlobalData.$assetManager.getTexture("avatarBg" + getStar() + "0000"));
         _loc5_.pivotX = int(_loc5_.width / 2);
         _loc5_.pivotY = int(_loc5_.height / 2);
         m_fightBg.addChild(_loc5_);
         m_resourceObj.pivotX = int(m_resourceObj.width / 2);
         m_resourceObj.pivotY = int(m_resourceObj.height / 2);
         m_resourceObj.scaleX = m_resourceObj.scaleY = 0.75;
         m_fightBg.addChild(m_resourceObj);
         param1.scaleY = param1.scaleX = getScale();
         var _loc4_:String = "0000";
         _loc2_ = "heroFrame" + team;
         if(avatarData.actionType == 3)
         {
            _loc2_ += "3";
         }
         _loc2_ += _loc4_;
         if(isLeader)
         {
            _loc7_ = new Image(GlobalData.$assetManager.getTexture("avatarLeader0000"));
            param1.addChild(_loc7_);
            _loc7_.pivotX = _loc7_.width / 2;
            _loc7_.pivotY = _loc7_.height / 2;
            if(avatarData.actionType == 3)
            {
               _loc7_.x = -42;
               _loc7_.y = -46;
            }
            else
            {
               _loc7_.x = -38;
               _loc7_.y = -43;
            }
         }
         m_buff = new Sprite();
         param1.addChild(m_buff);
         if(actionNum >= 0)
         {
            param1.addEventListener("touch",this.onTouch);
         }
         if(_loc7_)
         {
            _loc7_.touchable = false;
         }
         m_buff.touchable = false;
         param1.touchable = true;
         return param1;
      }

      public function get fightRes() : Sprite
      {
         if(!m_fightRes)
         {
            m_fightRes = newFightRes();
         }
         return m_fightRes;
      }

      public function onTouch(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(m_fightRes,"began");
         if(_loc2_)
         {
            if(GlobalData.$currentGuide)
            {
               if(GuideMaster.getOnlyExample().currentGuide.stepData.ma != actionNum)
               {
                  return;
               }
            }
            if(!GameMap.currentMap.isFight)
            {
               GlobalData.$mEventDispatcher.dispatchEventWith("update_pve_drag_avatar",false,{
                  "avatar":this,
                  "touch":_loc2_
               });
            }
         }
      }

      public function touchDetaiAvatar(param1:TouchEvent) : void
      {
         var _loc3_:* = undefined;
         var _loc2_:Touch = param1.getTouch(param1.currentTarget as DisplayObject,"ended");
         if(_loc2_)
         {
            _loc3_ = this.toDataObj();
            _loc3_.id = _loc3_.aid;
            GlobalFunction.setDetaiAvatar(_loc3_);
         }
      }

      public function hideActionNum() : void
      {
         if(m_actionNum)
         {
            m_actionNum.removeFromParent(true);
            if(m_tf)
            {
               m_tf.removeFromParent(true);
               m_tf = null;
            }
         }
      }

      public function reInit(param1:Object) : void
      {
         var _loc2_:int = 0;
         var _loc5_:int = line;
         var _loc4_:int = pos;
         var _loc3_:int = actionNum;
         var _loc6_:String = param1.aid;
         if(_loc6_)
         {
            _loc2_ = _loc6_.indexOf("|");
            id = _loc6_.slice(0,_loc2_);
            isLeader = param1.is_friend;
            if(!mData)
            {
               mData = {};
            }
            mData.isF = isLeader ? 1 : 0;
            m_data = AvatarManager.getOnlyExample().getData(id);
            m_resourceObj = null;
            m_fightRes = newFightRes(m_fightRes);
         }
         init(param1);
         if(param1.equips)
         {
            setEquips(param1.equips,false);
         }
         hp = 0;
         goFight(1,_loc5_,0,isLeader);
         pos = _loc4_;
         actionNum = _loc3_;
      }

      public function init(param1:Object) : void
      {
         var _loc3_:Array = null;
         var _loc2_:Boolean = false;
         var previousLimitBreak:int = limitBreak;
         var previousMorph:int = morph;
         skill0 = null;
         skill1 = null;
         skill2 = null;
         skillB = null;
         talent = null;
         limitBreak = 0;
         cultureSchema = "";
         if(param1 == null)
         {
            mData = {
               "aid":id,
               "id":id,
               "ap":0,
               "de_ma":0,
               "de_ph":0,
               "exp":0,
               "hp":0,
               "lv":1,
               "slv":1,
               "love_exp":0,
               "phase":0,
               "limit_break":0,
               "culture_schema":"",
               "morph":0
            };
            lv = mData.lv;
            exp = mData.exp;
            slv = mData.slv;
            hpP = mData.hp;
            apP = mData.ap;
            dePhP = mData.de_ph;
            deMaP = mData.de_ma;
            loveExp = mData.love_exp;
            phase = mData.phase;
            limitBreak = mData.limit_break;
            cultureSchema = mData.culture_schema;
            morph = mData.morph;
            id = mData.id;
         }
         else if(param1 is Array)
         {
            _loc3_ = param1 as Array;
            lv = _loc3_[1];
            slv = _loc3_[2];
            if(_loc3_.length >= 12)
            {
               hpP = _loc3_[3];
               apP = _loc3_[4];
               dePhP = _loc3_[5];
               deMaP = _loc3_[6];
               phase = _loc3_[7];
               limitBreak = _loc3_.length > 12 ? int(_loc3_[12]) : 0;
               line = _loc3_[8];
               pos = _loc3_[9];
               setEquips(_loc3_[10],false);
               _loc2_ = true;
               morph = _loc3_[11];
            }
            else if(_loc3_.length >= 11)
            {
               isNPC = true;
            }
            else
            {
               isNPC = true;
            }
         }
         else
         {
            cultureSchema = param1.culture_schema != null ? String(param1.culture_schema) : "";
            if(param1.hp_max)
            {
               hpP = apP = dePhP = deMaP = 0;
               lv = param1.lv;
               slv = param1.slv;
               hpMax = param1.hp_max;
               ap = param1.ap;
               hp = param1.hp;
               dePh = param1.de_ph;
               deMa = param1.de_ma;
               morph = param1.morph;
               phase = param1.phase;
               limitBreak = int(param1.limit_break);
               if(param1.book_skill)
               {
                  skill2 = new SkillSet(param1.book_skill.skid,this,param1.book_skill.slv);
               }
               if(param1.skill)
               {
                  skill0 = new SkillSet(param1.skill.skid,this,param1.slv);
               }
               if(param1.leader_skill)
               {
                  skill1 = new SkillSet(param1.leader_skill.skid,this,param1.leader_skill.slv,true);
               }
               if(param1.skillB)
               {
                  skillB = new SkillSet(param1.skillB.skid,this,param1.skillB.slv);
               }
               if(param1.talent)
               {
                  talent = new Talent(param1.talent);
               }
               if(param1.tpl)
               {
                  speed = param1.tpl[3];
                  range = param1.tpl[4];
               }
               if(param1.new_4attrs)
               {
                  hit = param1.new_4attrs.hit;
                  flee = param1.new_4attrs.flee;
                  crit = param1.new_4attrs.crit;
                  tough = param1.new_4attrs.tough;
               }
            }
            else
            {
               lv = param1.lv;
               exp = param1.exp;
               slv = param1.slv;
               hpP = param1.hp;
               apP = param1.ap;
               dePhP = param1.de_ph;
               deMaP = param1.de_ma;
               loveExp = param1.love_exp;
               phase = param1.phase;
               limitBreak = int(param1.limit_break);
               morph = param1.morph;
               id = param1.id ? param1.id : param1.aid;
            }
            if(param1.current_hp)
            {
               hp = param1.current_hp;
            }
            mData = param1;
         }
         if(!id)
         {
            id = avatarData.id + "-" + index;
            index += 1;
         }
         initHalo(param1);
         initSkills();
         if(m_avatarRes && (previousLimitBreak != limitBreak || previousMorph != morph))
         {
            m_avatarRes.unflatten();
            newAvatarRes(m_avatarRes);
         }
         actionNum = -1;
         line = -1;
         if(!_loc2_)
         {
            equips = new Vector.<Equip>();
         }
      }

      private function initHalo(param1:Object) : void
      {
         if(param1)
         {
            if(param1["talent"])
            {
               if(param1.talent != "" && param1.talent is String)
               {
                  talent = new Talent(param1.talent);
               }
               else
               {
                  talent = new Talent(param1.talent.id);
               }
            }
         }
      }

      public function toDataNormalObj() : Object
      {
         var _loc1_:Object = toDataObj();
         _loc1_.id = id;
         _loc1_.hp = hpP;
         _loc1_.ap = apP;
         _loc1_.de_ma = deMaP;
         _loc1_.de_ph = dePhP;
         _loc1_.love_exp = loveExp;
         _loc1_.phase = phase;
         _loc1_.limit_break = limitBreak;
         _loc1_.culture_schema = cultureSchema;
         return _loc1_;
      }

      public function toDataObj() : Object
      {
         var _loc1_:Object = {};
         _loc1_.aid = avatarData.id;
         _loc1_.ap = ap;
         _loc1_.morph = morph;
         _loc1_.phase = phase;
         _loc1_.limit_break = limitBreak;
         _loc1_.culture_schema = cultureSchema;
         _loc1_.buffs = {};
         _loc1_.de_ma = deMa;
         _loc1_.de_ph = dePh;
         _loc1_.hp = hp;
         _loc1_.hp_max = hpMax;
         _loc1_.isme = team == 1;
         _loc1_.leader = isLeader ? 1 : 0;
         _loc1_.line = line;
         _loc1_.lv = lv;
         _loc1_.new_4attrs = {};
         _loc1_.new_4attrs.hit = hit;
         _loc1_.new_4attrs.flee = flee;
         _loc1_.new_4attrs.crit = crit;
         _loc1_.new_4attrs.tough = tough;
         _loc1_.pos = pos;
         _loc1_.slv = slv;
         _loc1_.tpl = [];
         _loc1_.tpl[0] = avatarData.signType;
         _loc1_.tpl[1] = avatarData.actionType;
         _loc1_.tpl[2] = avatarData.damageType;
         _loc1_.tpl[3] = speed;
         _loc1_.tpl[4] = range;
         _loc1_.talent = talent ? talent.id : null;
         if(skill0)
         {
            _loc1_.skill = {};
            _loc1_.skill.cd = skill0.skillSetData.warmup;
            _loc1_.skill.pl = skill0.skillSetData.pl;
            _loc1_.skill.skid = skill0.skillSetData.id;
            _loc1_.skill.skills = skill0.skills;
         }
         else
         {
            _loc1_.skill = null;
         }
         if(skill1 && isLeader)
         {
            _loc1_.leader_skill = {};
            _loc1_.leader_skill.cd = skill1.skillSetData.warmup;
            _loc1_.leader_skill.pl = skill1.skillSetData.pl;
            _loc1_.leader_skill.skid = skill1.skillSetData.id;
            _loc1_.leader_skill.skills = skill1.skills;
         }
         else
         {
            _loc1_.leader_skill = null;
         }
         if(skill2)
         {
            _loc1_.book_skill = {};
            _loc1_.book_skill.pl = skill2.skillSetData.pl;
            if(_loc1_.book_skill.pl)
            {
               _loc1_.book_skill.cd = skill2.skillSetData.warmup;
            }
            _loc1_.book_skill.skid = skill2.skillSetData.id;
            _loc1_.book_skill.skills = skill2.skills;
            _loc1_.book_skill.slv = skill2.lv;
         }
         else
         {
            _loc1_.book_skill = null;
         }
         if(skillB)
         {
            _loc1_.skillB = {};
            _loc1_.skillB.cd = skillB.skillSetData.warmup;
            _loc1_.skillB.pl = skillB.skillSetData.pl;
            _loc1_.skillB.skid = skillB.skillSetData.id;
            _loc1_.skillB.skills = skillB.skills;
         }
         else
         {
            _loc1_.skillB = null;
         }
         return _loc1_;
      }

      protected function initSkills() : void
      {
         var _loc1_:String = null;
         var _loc2_:AvatarData = avatarData;
         if(!skill0)
         {
            _loc1_ = _loc2_.skill0;
            if(_loc1_ != null && _loc1_ != "")
            {
               skill0 = new SkillSet(_loc1_,this,slv);
            }
         }
         if(!skill1)
         {
            _loc1_ = _loc2_.skill1;
            if(_loc1_ != null && _loc1_ != "")
            {
               skill1 = new SkillSet(_loc1_,this,1,true);
            }
         }
         if(!skillB && _loc2_.skillB)
         {
            _loc1_ = _loc2_.skillB;
            if(_loc1_ != null && _loc1_ != "")
            {
               skillB = new SkillSet(_loc1_,this,1);
            }
         }
      }

      protected function initbuffs() : void
      {
         buffs = {};
         manualSkillDots = {};
         manualBattleStacks = {};
         manualTimedStacks = [];
         manualOwnerActionSerial = 0;
         manualSummonFamilies = {};
         manualLethalFloor = {};
      }

      public function getManualBattleStack(param1:String) : Number
      {
         if(!manualBattleStacks || !manualBattleStacks[param1]) return 0;
         return Math.max(0,Number(manualBattleStacks[param1]));
      }

      public function addManualBattleStack(param1:String, param2:Number, param3:int) : void
      {
         if(!manualBattleStacks) manualBattleStacks = {};
         if(["attack","defense","flee"].indexOf(param1) < 0) return;
         if(!isFinite(param2) || param2 <= 0 || param3 < 1) return;
         manualBattleStacks[param1] = Math.min(Number(param3) * param2,getManualBattleStack(param1) + param2);
         var flat:Boolean = ["hit","flee","crit","tough"].indexOf(param1) >= 0;
         var labels:Object = {hit:"精准",flee:"闪避",crit:"暴击",tough:"韧性"};
         abilityFeedback(flat ? labels[param1]+"叠加：+"+Math.round(getManualBattleStack(param1)) : "永久成长："+Math.round(getManualBattleStack(param1)*100)+"%",flat ? "FX_S9140_FLEE" : "FX_S9160_STRONG");
      }

      public function getManualTimedStack(param1:String) : Number
      {
         var _loc1_:int = 0;
         var _loc2_:Number = 0;
         if(!manualTimedStacks) return 0;
         while(_loc1_ < manualTimedStacks.length)
         {
            if(manualTimedStacks[_loc1_] && manualTimedStacks[_loc1_].stat == param1 && int(manualTimedStacks[_loc1_].expiresAt) >= manualOwnerActionSerial) _loc2_ += Number(manualTimedStacks[_loc1_].value);
            _loc1_++;
         }
         return Math.max(0,_loc2_);
      }

      public function addManualTimedStack(param1:String, param2:Number, param3:int, param4:int) : void
      {
         var _loc1_:int = 0;
         var _loc2_:int = 0;
         var _loc3_:Array = [];
         if(param1 != "attack" || !isFinite(param2) || param2 <= 0 || param2 > 1 || param3 < 1 || param3 > 8 || param4 < 1 || param4 > 20) return;
         if(!manualTimedStacks) manualTimedStacks = [];
         while(_loc1_ < manualTimedStacks.length)
         {
            if(manualTimedStacks[_loc1_] && int(manualTimedStacks[_loc1_].expiresAt) >= manualOwnerActionSerial)
            {
               _loc3_.push(manualTimedStacks[_loc1_]);
               if(manualTimedStacks[_loc1_].stat == param1) _loc2_++;
            }
            _loc1_++;
         }
         manualTimedStacks = _loc3_;
         if(_loc2_ >= param3) return;
         manualTimedStacks.push({"stat":param1,"value":param2,"expiresAt":manualOwnerActionSerial + param4});
         abilityFeedback("力量叠层："+(_loc2_+1)+"/"+param3,"FX_S9160_STRONG");
      }

      private function advanceManualOwnerAction() : void
      {
         var _loc1_:int = 0;
         var _loc2_:Array = [];
         manualOwnerActionSerial++;
         if(!manualTimedStacks) manualTimedStacks = [];
         while(_loc1_ < manualTimedStacks.length)
         {
            if(manualTimedStacks[_loc1_] && int(manualTimedStacks[_loc1_].expiresAt) >= manualOwnerActionSerial) _loc2_.push(manualTimedStacks[_loc1_]);
            _loc1_++;
         }
         manualTimedStacks = _loc2_;
      }

      public function getManualSummonSlots(param1:String, param2:int) : int
      {
         var _loc1_:Array = null;
         var _loc2_:int = 0;
         var _loc3_:Vector.<Avatar> = null;
         var _loc4_:Vector.<Avatar> = null;
         if(!manualSummonFamilies) manualSummonFamilies = {};
         _loc3_ = manualSummonFamilies[param1] as Vector.<Avatar>;
         if(!_loc3_) return Math.max(0,param2);
         _loc1_ = [];
         _loc2_ = 0;
         while(_loc2_ < _loc3_.length)
         {
            if(_loc3_[_loc2_] && _loc3_[_loc2_].hp > 0) _loc1_.push(_loc3_[_loc2_]);
            _loc2_++;
         }
         _loc4_ = new Vector.<Avatar>();
         _loc2_ = 0;
         while(_loc2_ < _loc1_.length)
         {
            _loc4_.push(_loc1_[_loc2_] as Avatar);
            _loc2_++;
         }
         manualSummonFamilies[param1] = _loc4_;
         return Math.max(0,param2 - _loc1_.length);
      }

      public function registerManualSummon(param1:String, param2:Avatar, param3:int) : Boolean
      {
         var _loc1_:Vector.<Avatar> = null;
         if(!param1 || !param2 || param2.hp <= 0 || getManualSummonSlots(param1,param3) <= 0) return false;
         if(!manualSummonFamilies) manualSummonFamilies = {};
         _loc1_ = manualSummonFamilies[param1] as Vector.<Avatar>;
         if(!_loc1_) _loc1_ = new Vector.<Avatar>();
         _loc1_.push(param2);
         manualSummonFamilies[param1] = _loc1_;
         return true;
      }

      public function addManualSkillDot(param1:String, param2:String, param3:Number, param4:Number, param5:int, param6:Avatar = null, param7:int = 0, stack:Boolean = false) : void
      {
         var _loc1_:Object = null;
         var _loc2_:Buff = null;
         if(!param1 || (param2 != "poison" && param2 != "burn" && param2 != "bleed") || !isFinite(param3) || param3 < 0 || !isFinite(param4) || param4 < 0 || param5 < 1) return;
         if(buffs && buffs["purify"])
         {
            removeBuff("purify",true);
            return;
         }
         if(!manualSkillDots) manualSkillDots = {};
         if(stack) param1 += ":layer:" + (++manualDotSerial);
         _loc1_ = {"kind":param2,"apTick":Math.max(0,int(param3)),"hpMaxFraction":param4,"damageType":param7,"round":param5,"source":param6};
         _loc2_ = new Buff(param2 == "bleed" ? "poison" : param2,param5,Number(_loc1_.apTick));
         _loc1_.visual = _loc2_;
         if(manualSkillDots[param1] && manualSkillDots[param1].visual && m_buff && manualSkillDots[param1].visual.displayObject && manualSkillDots[param1].visual.displayObject.parent == m_buff)
         {
            m_buff.removeChild(manualSkillDots[param1].visual.displayObject);
         }
         manualSkillDots[param1] = _loc1_;
         showBuff(_loc2_);
      }

      public function hasManualDamageOverTime() : Boolean
      {
         var _loc1_:String = null;
         if(buffs && (buffs["poison"] || buffs["burn"])) return true;
         for(_loc1_ in abilityState)
         {
            if(_loc1_.indexOf("malz_") == 0 && abilityState[_loc1_] && abilityState[_loc1_].ticks > 0) return true;
         }
         for(_loc1_ in manualSkillDots)
         {
            if(manualSkillDots[_loc1_] && manualSkillDots[_loc1_].round >= 0) return true;
         }
         return false;
      }

      public function hasManualDotKind(param1:String) : Boolean
      {
         var _loc1_:String = null;
         if(param1 == "poison" && buffs && buffs["poison"]) return true;
         if(param1 == "burn" && buffs && buffs["burn"]) return true;
         for(_loc1_ in manualSkillDots)
         {
            if(manualSkillDots[_loc1_] && manualSkillDots[_loc1_].round >= 0 && manualSkillDots[_loc1_].kind == param1) return true;
         }
         return false;
      }

      public function clearManualSkillDots() : void
      {
         var _loc1_:String = null;
         var _loc2_:Buff = null;
         if(!manualSkillDots) return;
         for(_loc1_ in manualSkillDots)
         {
            _loc2_ = manualSkillDots[_loc1_] ? manualSkillDots[_loc1_].visual as Buff : null;
            if(_loc2_ && m_buff && _loc2_.displayObject && _loc2_.displayObject.parent == m_buff) m_buff.removeChild(_loc2_.displayObject);
         }
         manualSkillDots = {};
      }

      private function tickManualLethalFloors() : void
      {
         var _loc1_:String = null;
         var _loc2_:Object = null;
         var _loc3_:int = 0;
         if(!manualLethalFloor) return;
         for(_loc1_ in manualLethalFloor)
         {
            _loc2_ = manualLethalFloor[_loc1_];
            if(!_loc2_) continue;
            if(_loc2_.justApplied === true)
            {
               _loc2_.justApplied = false;
               continue;
            }
            _loc2_.rounds = int(_loc2_.rounds) - 1;
            if(int(_loc2_.rounds) <= 0)
            {
               delete manualLethalFloor[_loc1_];
               _loc3_ = Math.max(0,int(_loc2_.expiryHeal));
               if(typeof _loc2_.expiryHealHpMaxFraction == "number" && isFinite(Number(_loc2_.expiryHealHpMaxFraction)) && Number(_loc2_.expiryHealHpMaxFraction) > 0)
               {
                  _loc3_ = Math.max(_loc3_,Math.max(0,int(hpMax * Number(_loc2_.expiryHealHpMaxFraction))));
               }
               if(_loc3_ > 0 && hp > 0)
               {
                  injured(_loc3_,1,DisplayTools.getAttrs("FX60_HEAL"),4,this,false,this);
               }
            }
         }
      }

      protected function showBuff(param1:Buff) : void
      {
         if(!m_buff)
         {
            return;
         }
         if(param1.displayObject)
         {
            m_buff.addChild(param1.displayObject);
         }
      }

      public function addBuff(param1:String, param2:int, param3:Number = 0, param4:Number = 0, param5:int = -1, param6:Avatar = null) : void
      {
         var _loc8_:* = 0;
         var _loc13_:String = null;
         var _loc9_:Boolean = false;
         var _loc6_:Number = Number(NaN);
         var sourceContext:Object = currentAbilityAttack();
         var source:Avatar = param6 || (sourceContext ? sourceContext.owner as Avatar : null);
         var manualEffect:Number = sourceContext ? Number(sourceContext.manualEffectMultiplier) : 1;
         if(!isFinite(manualEffect) || manualEffect <= 0) manualEffect = 1;
         if(param3 != 0 && param1 != "summon") param3 *= manualEffect;
         if(param1 == "shield" && source) param3 *= source.getRecoveryTalentMultiplier();
         var _loc11_:Buff = new Buff(param1,param2,param3);
         _loc11_.source = source;
         var _loc12_:Buff = buffs[param1];
         // A timed revival must never shorten an existing permanent one.
         // Legacy bless uses value 0; the explicit timed_bless action uses 1.
         if(param1 == "bless" && _loc12_)
         {
            if(_loc12_.value <= 0 && _loc11_.value > 0) return;
            if(_loc11_.value <= 0 && _loc12_.value > 0) _loc11_.round = Math.max(_loc11_.round,_loc12_.round);
         }
         var _loc7_:GameMapLayer = GameMapLayer.gl;
         if(param5 < 0)
         {
            param5 = 35;
         }
         var _loc14_:Number = 0.75;
         param4 = GameMap.actionDelay + param4;
         var _loc10_:Number = 0;
         if(param1 == "weak" && abilityState.highlander) return;
         if(param1 == "silence")
         {
            _loc10_ = checkTalent(8);
         }
         else if(param1 == "weak")
         {
            _loc10_ = checkTalent(9);
         }
         else if(param1 == "poison")
         {
            _loc10_ = checkTalent(10);
         }
         else if(param1 == "burn")
         {
            _loc10_ = checkTalent(11);
         }
         else if(param1 == "sunder")
         {
            _loc10_ = checkTalent(12);
         }
         else if(param1 == "stun")
         {
            _loc10_ = checkTalent(13);
         }
         if(_loc10_ > 0)
         {
            _loc6_ = Random.getRandom();
            if(Tools.toInt(_loc10_ * 100) > _loc6_)
            {
               _loc8_ = 10526880;
               _loc8_ = 16777215;
               if(param1 == "silence")
               {
                  _loc13_ = GlobalLanguageStr.getLanguageStr(30019) + GlobalLanguageStr.getLanguageStr(30037);
               }
               else if(param1 == "weak")
               {
                  _loc13_ = GlobalLanguageStr.getLanguageStr(30015) + GlobalLanguageStr.getLanguageStr(30037);
               }
               else if(param1 == "poison")
               {
                  _loc13_ = GlobalLanguageStr.getLanguageStr(30038) + GlobalLanguageStr.getLanguageStr(30037);
               }
               else if(param1 == "burn")
               {
                  _loc13_ = GlobalLanguageStr.getLanguageStr(30028) + GlobalLanguageStr.getLanguageStr(30037);
               }
               else if(param1 == "sunder")
               {
                  _loc13_ = GlobalLanguageStr.getLanguageStr(30017) + GlobalLanguageStr.getLanguageStr(30037);
               }
               else if(param1 == "stun")
               {
                  _loc13_ = GlobalLanguageStr.getLanguageStr(30018) + GlobalLanguageStr.getLanguageStr(30037);
               }
               _loc7_.delayCall(_loc7_.infoLayer.popTextForAvatar,param4 + 0.4,_loc13_,this,_loc8_,param5,_loc14_,null,65);
               return;
            }
         }
         if(param1 == "pull")
         {
            checkMove(true,param3,GameMap.currentAvatar,-1,true);
            return;
         }
         if(param1 == "push")
         {
            checkMove(false,param3,GameMap.currentAvatar,-1,true);
            return;
         }
         if(buffs["purify"])
         {
            if(Buff.LIST_DEBUFF.indexOf(param1) != -1)
            {
               removeBuff("purify",true);
               _loc8_ = 10526880;
               _loc13_ = GlobalLanguageStr.getLanguageStr(30025);
               _loc7_.delayCall(_loc7_.infoLayer.popTextForAvatar,param4,_loc13_,this,_loc8_,param5,_loc14_);
               return;
            }
         }
         else if(buffs["evil"] && param1 != "purify")
         {
            if(Buff.LIST_BUFF.indexOf(param1) != -1)
            {
               removeBuff("evil");
               _loc8_ = 10526880;
               _loc13_ = GlobalLanguageStr.getLanguageStr(30025);
               _loc7_.delayCall(_loc7_.infoLayer.popTextForAvatar,param4,_loc13_,this,_loc8_,param5,_loc14_);
               return;
            }
         }
         if(buffs["curse"] && Buff.LIST_BUFF.indexOf(param1) != -1 && param1 != "purify")
         {
            _loc8_ = 10526880;
            _loc13_ = GlobalLanguageStr.getLanguageStr(30025);
            _loc7_.delayCall(_loc7_.infoLayer.popTextForAvatar,param4,_loc13_,this,_loc8_,param5,_loc14_);
            return;
         }
         if(param1 == "purify")
         {
            removeAllDebuff();
            if(_loc12_ && _loc12_.value > 0) return;
         }
         else if(param1 == "evil")
         {
            removeAllGoodBuff();
         }
         if(!_loc12_)
         {
            buffs[param1] = _loc11_;
            _loc7_.delayCall(showBuff,param4,_loc11_);
            _loc9_ = true;
         }
         else
         {
            switch(param1)
            {
               case "stun":
               case "silence":
               case "purify":
               case "evil":
               case "curse":
               case "taunt":
               case "bless":
                  if(_loc11_.round >= _loc12_.round)
                  {
                     removeBuff(param1);
                     buffs[param1] = _loc11_;
                     _loc7_.delayCall(showBuff,param4,_loc11_);
                     _loc9_ = true;
                  }
                  else
                  {
                     _loc8_ = 10526880;
                     _loc13_ = GlobalLanguageStr.getLanguageStr(30020);
                     _loc7_.delayCall(_loc7_.infoLayer.popTextForAvatar,param4 + 0.4,_loc13_,this,_loc8_,param5,_loc14_,null,65);
                  }
                  break;
               case "root":
               case "weak":
               case "sunder":
               case "shield":
               case "strong":
               case "steel":
               case "armor":
               case "hitup":
               case "fleeup":
               case "critup":
               case "toughup":
               case "book_penetration":
                  if(_loc11_.value >= _loc12_.value)
                  {
                     removeBuff(param1);
                     buffs[param1] = _loc11_;
                     _loc7_.delayCall(showBuff,param4,_loc11_);
                     _loc9_ = true;
                  }
                  else
                  {
                     _loc8_ = 10526880;
                     _loc13_ = GlobalLanguageStr.getLanguageStr(30020);
                     _loc7_.delayCall(_loc7_.infoLayer.popTextForAvatar,param4 + 0.4,_loc13_,this,_loc8_,param5,_loc14_,null,65);
                  }
                  break;
               case "poison":
               case "burn":
                  _loc12_.value = int(_loc12_.value * _loc12_.round / _loc11_.round + _loc11_.value);
                  // Native DOT merges into one pool; the latest accepted applier owns it.
                  _loc12_.source = _loc11_.source;
                  _loc12_.round = _loc11_.round;
                  _loc11_ = _loc12_;
                  _loc9_ = true;
            }
         }
         _loc13_ = "";
         if(_loc9_)
         {
            if(param1 == "stun" || param1 == "silence") delete abilityState.channel;
            switch(param1)
            {
               case "stun":
                  _loc8_ = 16777120;
                  _loc13_ = GlobalLanguageStr.getLanguageStr(30018) + _loc11_.round + GlobalLanguageStr.getLanguageStr(30002);
                  break;
               case "silence":
                  _loc8_ = 13684944;
                  _loc13_ = GlobalLanguageStr.getLanguageStr(30019) + _loc11_.round + GlobalLanguageStr.getLanguageStr(30002);
                  break;
               case "weak":
                  _loc8_ = 8396928;
                  _loc13_ = GlobalLanguageStr.getLanguageStr(30015) + GameMapTools.toPercentage(1 - 1 / (1 + _loc11_.value));
                  break;
               case "sunder":
                  _loc8_ = 9478352;
                  _loc13_ = GlobalLanguageStr.getLanguageStr(30017) + GameMapTools.toPercentage(1 - 1 / (1 + _loc11_.value));
                  break;
               case "poison":
                  _loc8_ = 53248;
                  _loc13_ = GlobalLanguageStr.getLanguageStr(30013) + _loc11_.round + GlobalLanguageStr.getLanguageStr(30002);
                  break;
               case "burn":
                  _loc8_ = 16737792;
                  _loc13_ = GlobalLanguageStr.getLanguageStr(30028) + _loc11_.round + GlobalLanguageStr.getLanguageStr(30002);
                  break;
               case "shield":
                  _loc8_ = 16777024;
                  _loc13_ = GlobalLanguageStr.getLanguageStr(30012) + _loc11_.value;
                  break;
               case "strong":
                  _loc8_ = 16744448;
                  _loc13_ = GlobalLanguageStr.getLanguageStr(30014) + GlobalLanguageStr.getLanguageStr(30000) + GameMapTools.toPercentage(_loc11_.value);
                  break;
               case "steel":
                  _loc8_ = 16763904;
                  _loc13_ = GlobalLanguageStr.getLanguageStr(30082) + GlobalLanguageStr.getLanguageStr(30000) + GameMapTools.toPercentage(_loc11_.value);
                  break;
               case "taunt":
                  _loc8_ = 16737792;
                  _loc13_ = GlobalLanguageStr.getLanguageStr(30027) + _loc11_.round + GlobalLanguageStr.getLanguageStr(30002);
                  break;
               case "purify":
                  _loc8_ = 10526975;
                  _loc13_ = GlobalLanguageStr.getLanguageStr(30016) + _loc11_.round + GlobalLanguageStr.getLanguageStr(30002);
                  break;
               case "evil":
                  _loc8_ = 10053222;
                  _loc13_ = GlobalLanguageStr.getLanguageStr(30080) + _loc11_.round + GlobalLanguageStr.getLanguageStr(30002);
                  break;
               case "curse":
                  _loc8_ = 10053222;
                  _loc13_ = "诅咒" + _loc11_.round + GlobalLanguageStr.getLanguageStr(30002);
                  break;
               case "bless":
                  _loc8_ = 16777164;
                  _loc13_ = GlobalLanguageStr.getLanguageStr(30081);
                  break;
               case "hitup":
                  _loc8_ = 10526975;
                  _loc13_ = GlobalLanguageStr.getLanguageStr(30021) + "+" + _loc11_.value;
                  break;
               case "fleeup":
                  _loc8_ = 10526975;
                  _loc13_ = GlobalLanguageStr.getLanguageStr(30022) + "+" + _loc11_.value;
                  break;
               case "critup":
                  _loc8_ = 16751001;
                  _loc13_ = GlobalLanguageStr.getLanguageStr(30023) + "+" + _loc11_.value;
                  break;
               case "toughup":
                  _loc8_ = 16751001;
                  _loc13_ = GlobalLanguageStr.getLanguageStr(30024) + "+" + _loc11_.value;
            }
            if(_loc13_.length > 0)
            {
               if(param5 < 35)
               {
                  _loc7_.delayCall(_loc7_.infoLayer.popTextForAvatar,param4,_loc13_,this,_loc8_,param5,_loc14_);
               }
               else
               {
                  _loc7_.delayCall(_loc7_.infoLayer.popTextForAvatar,param4 + 0.4,_loc13_,this,_loc8_,param5,_loc14_,null,65);
               }
            }
         }
      }

      public function resetBuff() : void
      {
         var _loc1_:String = null;
         var _loc2_:Buff = null;
         removeAllBuff();
         if(skill2)
         {
            _loc1_ = skill2.getPassiveType();
            if(_loc1_)
            {
               switch(_loc1_)
               {
                  case "ae":
                     _loc2_ = new Buff("asuck",2147483647,skill2.getPassiveValue());
                     buffs["asuck"] = _loc2_;
                     break;
                  case "back":
                     _loc2_ = new Buff("back",2147483647,skill2.getPassiveValue());
                     buffs["back"] = _loc2_;
                     break;
                  case "avenge":
                     _loc2_ = new Buff("avenge",2147483647,skill2.getPassiveValue());
                     buffs["avenge"] = _loc2_;
               }
            }
         }
      }

      public function removeAllBuff() : void
      {
         var _loc1_:String = null;
         if(buffs)
         {
            for(_loc1_ in buffs)
            {
               removeBuff(_loc1_);
            }
         }
         clearManualSkillDots();
      }

      public function dispelShieldForSkill() : void
      {
         removeBuff("shield");
      }

      public function dispelGoodBuffsForSkill() : void
      {
         removeAllGoodBuff();
      }

      protected function removeAllGoodBuff() : void
      {
         abilityClearStates(false);
         var _loc1_:String = null;
         for(_loc1_ in buffs)
         {
            if(Buff.LIST_BUFF.indexOf(_loc1_) > -1)
            {
               removeBuff(_loc1_);
            }
         }
      }

      protected function removeAllDebuff() : void
      {
         abilityClearStates(true);
         var _loc1_:String = null;
         for(_loc1_ in buffs)
         {
            if(Buff.LIST_DEBUFF.indexOf(_loc1_) > -1)
            {
               removeBuff(_loc1_);
            }
         }
         clearManualSkillDots();
      }

      protected function removeBuff(param1:String, consume:Boolean = false) : void
      {
         if(param1 == "root") delete abilityState.root;
         var _loc2_:Buff = buffs[param1];
         if(!_loc2_)
         {
            return;
         }
         if(consume && param1 == "purify" && _loc2_.value > 1)
         {
            --_loc2_.value;
            abilityFeedback("净化剩余"+int(_loc2_.value)+"层","FX_S9150_PURIFY",10526975);
            return;
         }
         var _loc3_:GameMapLayer = GameMapLayer.gl;
         if(_loc2_.displayObject)
         {
            _loc3_.delayCall(m_buff.removeChild,GameMap.actionDelay,_loc2_.displayObject);
         }
         delete buffs[param1];
      }

      protected function checkBuff() : Boolean
      {
         var _loc1_:Buff = null;
         var manualDotKey:String = null;
         var manualDot:Object = null;
         var manualDotAmount:int = 0;
         var manualDotRaw:Number = Number(NaN);
         var manualDotEffect:Object = null;
         tickManualLethalFloors();
         if(tryndUndyingActive)
         {
            if(tryndUndyingRounds <= 0)
            {
               tryndUndyingActive = false;
               tryndUndyingRounds = 0;
            }
            else
            {
               --tryndUndyingRounds;
            }
         }
         var _loc3_:String = null;
         var _loc5_:* = undefined;
         var _loc4_:int = 0;
         for(_loc3_ in buffs)
         {
            _loc1_ = buffs[_loc3_];
            // Only the new timed variant expires; legacy revival stays armed.
            if(_loc3_ == "bless" && _loc1_.value <= 0) continue;
            if(_loc3_ == "purify" && _loc1_.value > 0) continue;
            --_loc1_.round;
            switch(_loc3_)
            {
               case "summon":
                  if(_loc1_.round < 0)
                  {
                     hp = 0;
                     return true;
                  }
                  break;
               case "poison":
               case "burn":
            }
            if(_loc1_.round < 0)
            {
               removeBuff(_loc3_);
            }
         }
         _loc1_ = buffs["poison"];
         if(_loc1_)
         {
            _loc5_ = DisplayTools.getAttrs("POISON_EFF");
            injured(Tools.toInt(_loc1_.value + GlobalData.$mConfig_simple.attack[18] * hpMax),1,_loc5_,6,_loc1_.source,false,_loc1_.source,null,"poison");
            if(hp <= 0)
            {
               hp = 0;
               return true;
            }
            if(_loc1_.round <= 0)
            {
               removeBuff(_loc1_.type);
            }
         }
         _loc1_ = buffs["burn"];
         if(_loc1_)
         {
            _loc5_ = DisplayTools.getAttrs("BURN_EFF");
            injured(Tools.toInt(_loc1_.value),1,_loc5_,7,_loc1_.source,false,_loc1_.source,null,"burn");
            if(hp <= 0)
            {
               hp = 0;
               return true;
            }
            if(_loc1_.round <= 0)
            {
               removeBuff(_loc1_.type);
            }
         }
         if(manualSkillDots)
         {
            for(manualDotKey in manualSkillDots)
            {
               manualDot = manualSkillDots[manualDotKey];
               if(!manualDot) continue;
               --manualDot.round;
               manualDotRaw = Number(manualDot.apTick) + Number(manualDot.hpMaxFraction) * hpMax;
               manualDotAmount = Tools.toInt(manualDotRaw);
               if(manualDot.bookRemaining !== undefined)
               {
                  manualDotAmount = Math.ceil(Number(manualDot.bookRemaining) / Math.max(1,int(manualDot.bookTicks)));
                  manualDot.bookRemaining -= manualDotAmount;
                  manualDot.bookTicks--;
               }
               if(manualDotAmount > 0)
               {
                  manualDotEffect = DisplayTools.getAttrs(manualDot.kind == "burn" ? "BURN_EFF" : "POISON_EFF");
                  injured(manualDotAmount,1,manualDotEffect,manualDot.kind == "burn" ? 7 : 6,manualDot.source as Avatar,false,manualDot.source as Avatar,null,String(manualDot.kind));
                  if(hp <= 0)
                  {
                     hp = 0;
                     return true;
                  }
               }
               if(manualDot.round <= 0)
               {
                  var manualDotVisual:Buff = manualDot.visual as Buff;
                  if(manualDotVisual && m_buff && manualDotVisual.displayObject && manualDotVisual.displayObject.parent == m_buff) m_buff.removeChild(manualDotVisual.displayObject);
                  delete manualSkillDots[manualDotKey];
               }
            }
         }
         var _loc2_:GameMap = GameMap.currentMap;
         if(_loc2_.gameMapData.win[0] == -3)
         {
            if(_loc2_.roundNum >= GlobalData.$mConfig_simple.battle[5] - 1)
            {
               _loc4_ = 2 + _loc2_.roundNum - GlobalData.$mConfig_simple.battle[5];
               _loc5_ = DisplayTools.getAttrs("DEAD_MODE_EFF");
               injured(Tools.toInt(_loc4_ * GlobalData.$mConfig_simple.attack[19] * hp),1,_loc5_,8);
               if(hp <= 0)
               {
                  hp = 0;
                  return true;
               }
            }
         }
         return false;
      }

      public function activateTryndUndying(param1:int) : void
      {
         tryndUndyingRounds = Math.max(0,param1);
         tryndUndyingActive = tryndUndyingRounds > 0;
      }

      public function getScale() : Number
      {
         if(isBoss)
         {
            return 1.3;
         }
         if(!buffs)
         {
            return 0.8;
         }
         if(buffs["summon"])
         {
            return 0.8;
         }
         return 1;
      }

      public function getBookSkill() : SkillSet
      {
         var _loc2_:SkillSet = null;
         var _loc1_:* = null;
         for each(_loc1_ in equips)
         {
            _loc2_ = _loc1_.getBookSkill(this);
            if(_loc2_)
            {
               return _loc2_;
            }
         }
         return null;
      }

      public function getSymp() : Array
      {
         var _loc1_:* = null;
         var _loc2_:Array = [0,0,0,0];
         for each(_loc1_ in equips)
         {
            if(_loc1_.symp >= 0)
            {
               _loc2_[_loc1_.symp]++;
            }
         }
         return _loc2_;
      }

      public function getSympType() : Array
      {
         var _loc2_:Array = getSymp();
         var _loc1_:Array = [];
         if(_loc2_[0] >= 2)
         {
            _loc1_.push("hp");
         }
         if(_loc2_[1] >= 2)
         {
            _loc1_.push("ap");
         }
         if(_loc2_[2] >= 2)
         {
            _loc1_.push("de_ph");
         }
         if(_loc2_[3] >= 2)
         {
            _loc1_.push("de_ma");
         }
         return _loc1_;
      }

      private function getCultivationGainFromSlope(param1:Number, param2:int) : int
      {
         if(isWeightedCultivation()) return param2;
         var _loc3_:Number = Number(GlobalData.$mConfig_simple.culture.pith_growth_rate);
         if(isNaN(_loc3_) || _loc3_ <= 0)
         {
            _loc3_ = 0.1;
         }
         return int(param1 * param2 * _loc3_);
      }

      public function getCultivationStatGain(param1:String, param2:int) : int
      {
         var _loc3_:AvatarData = avatarData;
         var _loc4_:Number = 0;
         if(param1 == "hp")
         {
            _loc4_ = _loc3_.hp1;
         }
         else if(param1 == "ap")
         {
            _loc4_ = _loc3_.ap1;
         }
         else if(param1 == "de_ph")
         {
            _loc4_ = _loc3_.d11;
         }
         else if(param1 == "de_ma")
         {
            _loc4_ = _loc3_.d21;
         }
         return getCultivationGainFromSlope(_loc4_,param2);
      }

      private function applyOwnedGuildResearch(param1:String, param2:int) : int
      {
         var _loc3_:Object = null;
         var _loc4_:Object = null;
         var _loc5_:Object = null;
         var _loc6_:Object = null;
         var _loc7_:Array = null;
         var _loc8_:String = null;
         var _loc9_:Number = 0;
         var _loc10_:Number = 0;
         var _loc11_:Boolean = false;
         if(isOthers || team == 2 || !id || (mData && mData.exploration_hero_only === true))
         {
            return param2;
         }
         _loc3_ = GlobalData.$userData;
         if(!_loc3_ || !_loc3_.avatars || !_loc3_.attrs)
         {
            return param2;
         }
         _loc4_ = _loc3_.avatars[id];
         if(!_loc4_ && mData && mData.id)
         {
            _loc4_ = _loc3_.avatars[mData.id];
         }
         if(!_loc4_)
         {
            return param2;
         }
         _loc5_ = _loc3_.attrs.guild_graduate_skill;
         _loc6_ = GlobalData.$mGuild_simple;
         if(!_loc5_ || !_loc6_ || !_loc6_.guild_graduate || !_loc6_.guild_graduate.guild_graduate_skill)
         {
            return param2;
         }
         _loc6_ = _loc6_.guild_graduate.guild_graduate_skill;
         for(_loc8_ in _loc5_)
         {
            _loc9_ = Number(_loc5_[_loc8_]);
            if(!(isNaN(_loc9_) || _loc9_ <= 0 || !_loc6_[_loc8_] || !_loc6_[_loc8_].level))
            {
               _loc7_ = _loc6_[_loc8_].effect_attributes as Array;
               if(_loc7_)
               {
                  _loc11_ = false;
                  for each(var _target:String in _loc7_)
                  {
                     if(_target == param1)
                     {
                        _loc11_ = true;
                        break;
                     }
                  }
                  if(_loc11_)
                  {
                     _loc4_ = _loc6_[_loc8_].level[String(int(_loc9_))];
                     if(_loc4_)
                     {
                        _loc10_ = Number(_loc4_.value);
                        if(!(isNaN(_loc10_) || _loc10_ <= 0))
                        {
                           param2 = Tools.toInt(param2 * (1 + _loc10_ / 100));
                        }
                     }
                  }
               }
            }
         }
         return param2;
      }

      public function getHpMax(param1:int = -1, param2:int = -1, param3:Boolean = false) : int
      {
         var _loc4_:int = 0;
         var _loc6_:* = null;
         var _loc7_:int = 0;
         var _loc5_:int = 0;
         if(hpMax)
         {
            return hpMax;
         }
         if(param1 < 0)
         {
            param1 = lv;
         }
         if(getStar() != 6)
         {
            param1 += getPhaseLv();
         }
         if(param2 < 0)
         {
            param2 = hpP;
         }
         var _loc8_:AvatarData = avatarData;
         var _baseHp:Number = _loc8_.hp0 + _loc8_.hp1 * (param1 - 1);
         if(getStar() == 6 && phase > 0)
         {
            _baseHp *= Math.pow(1.12,phase);
         }
         _loc4_ = int(_baseHp) + getCultivationGainFromSlope(_loc8_.hp1,param2);
         if(param3)
         {
            _loc7_ = 0;
            for each(_loc6_ in equips)
            {
               _loc7_ += _loc6_.getHpMax(-1,true);
            }
            if(skill2)
            {
               _loc7_ = Tools.toInt(_loc7_ * skill2.getEquipRate("hp"));
            }
            _loc4_ += _loc7_;
            _loc5_ = int(getSymp()[0]);
            if(_loc5_ >= 2)
            {
               _loc4_ += _loc5_ * GlobalData.$mConfig_simple.dust.symp[1][_loc5_ - 2] * GlobalData.$mConfig_simple.dust.symp[0][0];
            }
         }
         if(mDestiny)
         {
            _loc4_ = (_loc4_ + mDestiny.hp) * (1 + mDestiny.hpP);
         }
         if(mDNdata)
         {
            _loc4_ += mDNdata.hp;
         }
         _loc4_ = applyOwnedGuildResearch("hp",_loc4_);
         _loc4_ = Tools.toInt(_loc4_ * (1 + getBookCombatBonus("hp")));
         _loc4_ = Tools.toInt(_loc4_ * (1 + ownGrowthValue("hp") / 100));
         return Math.max(_loc4_,0);
      }

      public function getBookCombatBonus(stat:String) : Number
      {
         var value:Number = 0;
         if(skill2 && !skill2.skillSetData.pl && skill2.skills)
         {
            for each(var action:Array in skill2.skills)
            {
               if(action[0] == "book_passive" && action[2] == stat)
               {
                  value = stat == "penetration" ? Math.max(value,Number(action[1])) : value + Number(action[1]);
               }
            }
         }
         if(stat == "penetration")
         {
            if(buffs && buffs["book_penetration"]) value = Math.max(value,Number(buffs["book_penetration"].value));
            return Math.max(0,Math.min(1,value));
         }
         return isFinite(value) ? Math.max(0,value) : 0;
      }

      public function addBookBurn(total:int, rounds:int, source:Avatar) : void
      {
         if(total <= 0 || rounds < 1 || hp <= 0) return;
         var key:String = "book-burn:" + (++manualDotSerial);
         addManualSkillDot(key,"burn",0,0,rounds,source,3);
         if(manualSkillDots && manualSkillDots[key])
         {
            manualSkillDots[key].bookRemaining = total;
            manualSkillDots[key].bookTicks = rounds;
         }
      }

      private function applyBookAttackEffects(target:Avatar, dealt:int) : void
      {
         if(!target || target.hp <= 0 || dealt <= 0 || target.team == team) return;
         var burn:Number = getBookCombatBonus("attack_burn");
         if(burn > 0) target.addBookBurn(Tools.toInt(dealt * burn),3,this);
         var chance:Number = getBookCombatBonus("attack_curse");
         if(chance > 0 && Random.getRandom(10000) < Math.round(chance * 10000)) target.addBuff("curse",3);
      }

      public function getDamage(param1:int = -1, param2:int = -1, param3:Boolean = false) : int
      {
         var _loc6_:int = 0;
         var _loc10_:AvatarData = null;
         var _loc8_:* = null;
         var _loc9_:int = 0;
         var _loc7_:int = 0;
         var _loc5_:Buff = null;
         if(hpMax)
         {
            _loc6_ = ap;
         }
         else
         {
            if(param1 < 0)
            {
               param1 = lv;
            }
            if(getStar() != 6)
            {
               param1 += getPhaseLv();
            }
            if(param2 < 0)
            {
               param2 = apP;
            }
            _loc10_ = avatarData;
            var _baseAp:Number = _loc10_.ap0 + _loc10_.ap1 * (param1 - 1);
            if(getStar() == 6 && phase > 0)
            {
               _baseAp *= Math.pow(1.12,phase);
            }
            _loc6_ = int(_baseAp) + getCultivationGainFromSlope(_loc10_.ap1,param2);
            if(param3)
            {
               _loc9_ = 0;
               for each(_loc8_ in equips)
               {
                  _loc9_ += _loc8_.getDamage(-1,true);
               }
               if(skill2)
               {
                  _loc9_ = Tools.toInt(_loc9_ * skill2.getEquipRate("ap"));
               }
               _loc6_ += _loc9_;
               _loc7_ = int(getSymp()[1]);
               if(_loc7_ >= 2)
               {
                  _loc6_ += _loc7_ * GlobalData.$mConfig_simple.dust.symp[1][_loc7_ - 2] * GlobalData.$mConfig_simple.dust.symp[0][1];
               }
            }
            if(mDestiny)
            {
               _loc6_ = Tools.toInt((_loc6_ + mDestiny.ap) * (1 + mDestiny.apP));
            }
            if(mDNdata)
            {
               _loc6_ += mDNdata.ap;
            }
            _loc6_ = applyOwnedGuildResearch("ap",_loc6_);
         _loc6_ = Tools.toInt(_loc6_ * (1 + getBookCombatBonus("ap")));
         _loc6_ = Tools.toInt(_loc6_ * (1 + ownGrowthValue("attack") / 100));
         }
         var _loc4_:Number = 1;
         if(buffs)
         {
            _loc5_ = buffs["weak"] as Buff;
            if(_loc5_)
            {
               _loc4_ /= 1 + _loc5_.value;
            }
            _loc5_ = buffs["strong"] as Buff;
            if(_loc5_)
            {
               _loc4_ *= 1 + _loc5_.value;
            }
         }
         _loc6_ = Tools.toInt(_loc6_ * (1 + getManualBattleStack("attack") + getManualTimedStack("attack")) * _loc4_);
         if(hpMax && abilityEntryAttack > 0) _loc6_ += int(abilityEntryAttack * (abilityState.evilStackBonus != null ? Number(abilityState.evilStackBonus) : 0.03 * int(abilityState.evilStacks)));
         if(hpMax && this.abilityState && int(this.abilityState.santaStacks) > 0) _loc6_ = Tools.toInt(_loc6_ * (1+0.05*int(this.abilityState.santaStacks)));
         return Math.max(_loc6_,0);
      }

      public function getDefenseAgainst(source:Avatar, damageType:int) : int
      {
         var penetration:Number = source ? source.getBookCombatBonus("penetration") : 0;
         var talent:Number = checkTalent(damageType == 1 ? 2 : 3);
         var defense:Number;
         if(penetration <= 0)
         {
            defense = damageType == 1 ? getDePh() : getDeMa();
            return Tools.toInt(defense * (1 + talent));
         }
         var sunder:Number = buffs && buffs["sunder"] ? Math.max(0,Number(buffs["sunder"].value)) : 0;
         var reduction:Number = Math.max(penetration,sunder / (1 + sunder));
         defense = damageType == 1 ? getPhysicalDefense(-1,-1,false,true) : getMagicDefense(-1,-1,false,true);
         return Math.max(0,Tools.toInt(defense * (1 + talent) * (1 - reduction)));
      }

      public function getDePh(param1:int = -1, param2:int = -1, param3:Boolean = false) : int
      {
         return getPhysicalDefense(param1,param2,param3,false);
      }

      private function getPhysicalDefense(param1:int, param2:int, param3:Boolean, ignoreSunder:Boolean) : int
      {
         var _loc4_:int = 0;
         var _loc10_:AvatarData = null;
         var _loc8_:* = null;
         var _loc9_:int = 0;
         var _loc7_:int = 0;
         var _loc6_:Buff = null;
         if(hpMax)
         {
            _loc4_ = dePh;
         }
         else
         {
            if(param1 < 0)
            {
               param1 = lv;
            }
            if(getStar() != 6)
            {
               param1 += getPhaseLv();
            }
            if(param2 < 0)
            {
               param2 = dePhP;
            }
            _loc10_ = avatarData;
            var _baseDePh:Number = _loc10_.d10 + _loc10_.d11 * (param1 - 1);
            if(getStar() == 6 && phase > 0)
            {
               _baseDePh *= Math.pow(1.12,phase);
            }
            _loc4_ = int(_baseDePh) + getCultivationGainFromSlope(_loc10_.d11,param2);
            if(param3)
            {
               _loc9_ = 0;
               for each(_loc8_ in equips)
               {
                  _loc9_ += _loc8_.getDePh();
               }
               if(skill2)
               {
                  _loc9_ = Tools.toInt(_loc9_ * skill2.getEquipRate("de_ph"));
               }
               _loc4_ += _loc9_;
               _loc7_ = int(getSymp()[2]);
               if(_loc7_ >= 2)
               {
                  _loc4_ += _loc7_ * GlobalData.$mConfig_simple.dust.symp[1][_loc7_ - 2] * GlobalData.$mConfig_simple.dust.symp[0][2];
               }
            }
            if(mDestiny)
            {
               _loc4_ = (_loc4_ + mDestiny.de_ph) * (1 + mDestiny.de_phP);
            }
            if(mDNdata)
            {
               _loc4_ += mDNdata.de_ph;
            }
            _loc4_ = applyOwnedGuildResearch("de_ph",_loc4_);
         _loc4_ = Tools.toInt(_loc4_ * (1 + getBookCombatBonus("de_ph")));
         _loc4_ = Tools.toInt(_loc4_ * (1 + ownGrowthValue("defense") / 100));
         }
         var _loc5_:Number = 1;
         if(buffs)
         {
            _loc6_ = buffs["sunder"] as Buff;
            if(_loc6_ && !ignoreSunder)
            {
               _loc5_ /= 1 + _loc6_.value;
            }
            _loc6_ = buffs["steel"] as Buff;
            if(_loc6_)
            {
               _loc5_ *= 1 + _loc6_.value;
            }
         }
          _loc4_ = Tools.toInt(_loc4_ * (1 + getManualBattleStack("defense")) * _loc5_);
         return Math.max(Tools.toInt(_loc4_ * (buffs && buffs["armor"] ? 1 + Number(buffs["armor"].value) : 1)),0);
      }

      public function getDeMa(param1:int = -1, param2:int = -1, param3:Boolean = false) : int
      {
         return getMagicDefense(param1,param2,param3,false);
      }

      private function getMagicDefense(param1:int, param2:int, param3:Boolean, ignoreSunder:Boolean) : int
      {
         var _loc4_:int = 0;
         var _loc10_:AvatarData = null;
         var _loc8_:* = null;
         var _loc9_:int = 0;
         var _loc7_:int = 0;
         var _loc6_:Buff = null;
         if(hpMax)
         {
            _loc4_ = deMa;
         }
         else
         {
            if(param1 < 0)
            {
               param1 = lv;
            }
            if(getStar() != 6)
            {
               param1 += getPhaseLv();
            }
            if(param2 < 0)
            {
               param2 = deMaP;
            }
            _loc10_ = avatarData;
            var _baseDeMa:Number = _loc10_.d20 + _loc10_.d21 * (param1 - 1);
            if(getStar() == 6 && phase > 0)
            {
               _baseDeMa *= Math.pow(1.12,phase);
            }
            _loc4_ = int(_baseDeMa) + getCultivationGainFromSlope(_loc10_.d21,param2);
            if(param3)
            {
               _loc9_ = 0;
               for each(_loc8_ in equips)
               {
                  _loc9_ += _loc8_.getDeMa();
               }
               if(skill2)
               {
                  _loc9_ = Tools.toInt(_loc9_ * skill2.getEquipRate("de_ma"));
               }
               _loc4_ += _loc9_;
               _loc7_ = int(getSymp()[3]);
               if(_loc7_ >= 2)
               {
                  _loc4_ += _loc7_ * GlobalData.$mConfig_simple.dust.symp[1][_loc7_ - 2] * GlobalData.$mConfig_simple.dust.symp[0][3];
               }
            }
            if(mDestiny)
            {
               _loc4_ = (_loc4_ + mDestiny.de_ma) * (1 + mDestiny.de_maP);
            }
            if(mDNdata)
            {
               _loc4_ += mDNdata.de_ma;
            }
            _loc4_ = applyOwnedGuildResearch("de_ma",_loc4_);
         _loc4_ = Tools.toInt(_loc4_ * (1 + getBookCombatBonus("de_ma")));
         _loc4_ = Tools.toInt(_loc4_ * (1 + ownGrowthValue("defense") / 100));
         }
         var _loc5_:Number = 1;
         if(buffs)
         {
            _loc6_ = buffs["sunder"] as Buff;
            if(_loc6_ && !ignoreSunder)
            {
               _loc5_ /= 1 + _loc6_.value;
            }
            _loc6_ = buffs["steel"] as Buff;
            if(_loc6_)
            {
               _loc5_ *= 1 + _loc6_.value;
            }
         }
          _loc4_ = Tools.toInt(_loc4_ * (1 + getManualBattleStack("defense")) * _loc5_);
         return Math.max(_loc4_,0);
      }

      public function getSpeed(param1:Boolean = false) : int
      {
         var _loc5_:int = 0;
         var _loc4_:* = null;
         var _loc3_:Buff = null;
         if(hpMax)
         {
            _loc5_ = speed;
         }
         else
         {
            _loc5_ = avatarData.speed;
            if(param1)
            {
               for each(_loc4_ in equips)
               {
                  _loc5_ += _loc4_.getSpeed();
               }
            }
         }
         var _loc2_:Number = 1;
         if(buffs)
         {
            _loc3_ = buffs["weak"] as Buff;
            if(_loc3_)
            {
               _loc2_ /= 1 + _loc3_.value;
            }
            _loc3_ = buffs["strong"] as Buff;
            if(_loc3_)
            {
               _loc2_ *= 1 + _loc3_.value;
            }
         }
         return Tools.toInt(_loc5_ * _loc2_);
      }

      public function getRange(param1:Boolean = false) : int
      {
         var _loc3_:int = 0;
         var _loc2_:* = null;
         if(isFinite(manualAttackRangeOverride) && manualAttackRangeOverride > 0) return int(manualAttackRangeOverride);
         if(hpMax)
         {
            _loc3_ = range;
         }
         else
         {
            _loc3_ = avatarData.range;
            if(param1)
            {
               for each(_loc2_ in equips)
               {
                  _loc3_ += _loc2_.getRange();
               }
            }
         }
         return _loc3_;
      }

      public function getHit() : int
      {
         var _loc2_:* = null;
         var _loc4_:int = 0;
         var _loc1_:Buff = null;
         var _loc3_:int = 0;
         if(hpMax)
         {
            _loc3_ = hit;
         }
         else
         {
            _loc3_ = mData && mData.hit != null ? Math.max(0,int(mData.hit)) : 0;
            _loc4_ = 0;
            for each(_loc2_ in equips)
            {
               _loc4_ += _loc2_.getHit(-1,true);
            }
            if(skill2)
            {
               _loc4_ = Tools.toInt(_loc4_ * skill2.getEquipRate("hit"));
            }
            _loc3_ += _loc4_;
            if(mDestiny)
            {
               _loc3_ = (_loc3_ + mDestiny.hit) * (1 + mDestiny.hitP);
            }
         }
         if(!hpMax) _loc3_ = Tools.toInt(_loc3_ * (1 + getBookCombatBonus("hit")));
         if(buffs)
         {
            _loc1_ = buffs["hitup"] as Buff;
            if(_loc1_)
            {
               _loc3_ += _loc1_.value;
            }
         }
         return _loc3_ + (initializingFightAttributes ? 0 : teamTalentFlat("team_hit")) + (this.abilityState ? int(this.abilityState.polarCastHit) + int(this.abilityState.veigarCastHit) : 0);
      }

      public function getFlee() : int
      {
         var _loc3_:* = null;
         var _loc4_:int = 0;
         var _loc1_:Buff = null;
         var _loc2_:int = 0;
         if(hpMax)
         {
            _loc2_ = flee;
         }
         else
         {
            _loc2_ = mData && mData.flee != null ? Math.max(0,int(mData.flee)) : 0;
            _loc4_ = 0;
            for each(_loc3_ in equips)
            {
               _loc4_ += _loc3_.getFlee(-1,true);
            }
            if(skill2)
            {
               _loc4_ = Tools.toInt(_loc4_ * skill2.getEquipRate("flee"));
            }
            _loc2_ += _loc4_;
            if(mDestiny)
            {
               _loc2_ = (_loc2_ + mDestiny.flee) * (1 + mDestiny.fleeP);
            }
         }
         if(!hpMax) _loc2_ = Tools.toInt(_loc2_ * (1 + getBookCombatBonus("flee")));
         if(buffs)
         {
            _loc1_ = buffs["fleeup"] as Buff;
            if(_loc1_)
            {
               _loc2_ += _loc1_.value;
            }
         }
         return _loc2_ + int(getManualBattleStack("flee")) + (initializingFightAttributes ? 0 : teamTalentFlat("team_flee"));
      }

      public function getCrit() : int
      {
         var _loc3_:* = null;
         var _loc4_:int = 0;
         var _loc1_:Buff = null;
         var _loc2_:int = 0;
         if(hpMax)
         {
            _loc2_ = crit;
         }
         else
         {
            _loc2_ = mData && mData.crit != null ? Math.max(0,int(mData.crit)) : 0;
            _loc4_ = 0;
            for each(_loc3_ in equips)
            {
               _loc4_ += _loc3_.getCrit(-1,true);
            }
            if(skill2)
            {
               _loc4_ = Tools.toInt(_loc4_ * skill2.getEquipRate("crit"));
            }
            _loc2_ += _loc4_;
            if(mDestiny)
            {
               _loc2_ = (_loc2_ + mDestiny.crit) * (1 + mDestiny.critP);
            }
         }
         if(!hpMax) _loc2_ = Tools.toInt(_loc2_ * (1 + getBookCombatBonus("crit")));
         if(buffs)
         {
            _loc1_ = buffs["critup"] as Buff;
            if(_loc1_)
            {
               _loc2_ += _loc1_.value;
            }
         }
         return _loc2_ + (initializingFightAttributes ? 0 : teamTalentFlat("team_crit"));
      }

      public function getTough() : int
      {
         var _loc3_:* = null;
         var _loc4_:int = 0;
         var _loc1_:Buff = null;
         var _loc2_:int = 0;
         if(hpMax)
         {
            _loc2_ = tough;
         }
         else
         {
            _loc2_ = mData && mData.tough != null ? Math.max(0,int(mData.tough)) : 0;
            _loc4_ = 0;
            for each(_loc3_ in equips)
            {
               _loc4_ += _loc3_.getTough(-1,true);
            }
            if(skill2)
            {
               _loc4_ = Tools.toInt(_loc4_ * skill2.getEquipRate("tough"));
            }
            _loc2_ += _loc4_;
            if(mDestiny)
            {
               _loc2_ = (_loc2_ + mDestiny.tough) * (1 + mDestiny.toughP);
            }
         }
         if(!hpMax) _loc2_ = Tools.toInt(_loc2_ * (1 + getBookCombatBonus("tough")));
         if(buffs)
         {
            _loc1_ = buffs["toughup"] as Buff;
            if(_loc1_)
            {
               _loc2_ += _loc1_.value;
            }
         }
         return _loc2_ + (initializingFightAttributes ? 0 : teamTalentFlat("team_tough"));
      }

      public function getLoveList() : Array
      {
         var _loc3_:int = 0;
         var _loc2_:Array = [0,loveExp,0];
         var _loc1_:Array = GlobalData.$mConfig_simple.love_up;
         if(!_loc1_)
         {
            return [0,0,2147483647];
         }
         _loc3_ = 0;
         while(_loc3_ < _loc1_[0])
         {
            _loc2_[2] = _loc1_[1] * _loc2_[0] + _loc1_[2];
            if(_loc2_[1] < _loc2_[2])
            {
               break;
            }
            _loc2_[0]++;
            _loc2_[1] -= _loc2_[2];
            _loc3_++;
         }
         if(_loc2_[0] == _loc1_[0])
         {
            _loc2_[2] = 2147483647;
         }
         return _loc2_;
      }

      public function getSkillPro() : Number
      {
         var _loc1_:int = this.skill0 ? this.skill0.lv : 0;
         var _loc2_:Number = avatarData ? avatarData.skillUpP : 1;
         return _loc1_ * getStar() * _loc2_;
      }

      public function getSkillProMother() : Number
      {
         var _loc1_:int = this.skill0 ? this.skill0.lv : 0;
         return (_loc1_ + 1) * getStar();
      }

      public function getAllExp(param1:int = -1, param2:Boolean = false) : int
      {
         var _loc3_:int = 0;
         if(param1 < 0)
         {
            param1 = lv;
         }
         var _loc5_:Array = GlobalData.$mConfig_simple.avatar_exp;
         var _loc8_:int = int(_loc5_[0]);
         var _loc7_:int = int(_loc5_[1]);
         var _loc9_:int = int(_loc5_[2]);
         var _loc4_:int = getLvMax();
         var _loc6_:int = exp;
         if(param2)
         {
            if(param1 >= _loc4_)
            {
               param1 = _loc4_;
               _loc6_ = 0;
            }
         }
         var _loc10_:Array = getExperienceCurve();
         if(_loc10_ != null && param1 >= 1 && param1 <= _loc10_.length)
         {
            _loc3_ = int(_loc10_[param1 - 1] * avatarData.expRate);
         }
         else
         {
            _loc3_ = (_loc8_ / 3 * param1 * param1 * param1 + (_loc7_ - _loc8_) / 2 * param1 * param1 + (_loc8_ / 6 - _loc7_ / 2 + _loc9_) * param1 - _loc9_) * avatarData.expRate;
         }
         return _loc3_ + _loc6_;
      }

      public function getOfferExp(param1:int = -1) : int
      {
         var _loc2_:int = getAllExp(param1);
         var _loc4_:Number = Number((GlobalData.$mConfig_simple.provide_exp as Array)[getStar() - 1]);
         var _loc3_:int = avatarData.offerExp;
         return _loc2_ * _loc4_ + _loc3_;
      }

      public function getNextExp(param1:int = -1) : int
      {
         if(param1 < 0)
         {
            param1 = lv;
         }
         if(param1 >= getLvMax())
         {
            return 2147483647;
         }
         var _loc2_:Array = GlobalData.$mConfig_simple.avatar_exp;
         var _loc4_:int = int(_loc2_[0]);
         var _loc3_:int = int(_loc2_[1]);
         var _loc5_:int = int(_loc2_[2]);
         var _loc6_:Array = getExperienceCurve();
         if(_loc6_ != null && param1 >= 1 && param1 < _loc6_.length)
         {
            return int(_loc6_[param1] * avatarData.expRate) - int(_loc6_[param1 - 1] * avatarData.expRate);
         }
         return avatarData.expRate * (_loc4_ * param1 * param1 + _loc3_ * param1 + _loc5_);
      }

      public function getIdValue() : Number
      {
         return 0.001 * GlobalData.baseModHeroId(avatarData.id).split("_")[1];
      }

      private function getExperienceCurve() : Array
      {
         var curves:Object = GlobalData.$mConfig_simple.avatar_exp_curves;
         var curve:Array = curves ? curves[String(getStar())] as Array : null;
         return curve || GlobalData.$mConfig_simple.avatar_exp_curve as Array;
      }

      public function isSwallowProtect(param1:Avatar) : Boolean
      {
         var _loc6_:Boolean = false;
         var _loc2_:int = getType();
         var _loc5_:int = getStar();
         var _loc4_:int = avatarData.offerExp;
         var _loc3_:int = avatarData.offerGold;
         _loc6_ = GlobalData.$tempAvatarBetter.id == id || GlobalFunction.checkIsTeamMember(id) || GlobalFunction.checkLock(id);
         if(_loc6_)
         {
            return true;
         }
         if(param1.lv >= param1.getLvMax())
         {
            return true;
         }
         if(_loc2_ == 1)
         {
            return true;
         }
         if(_loc5_ >= 5)
         {
            return true;
         }
         if(morph > 0)
         {
            return true;
         }
         if(_loc4_ > 50000)
         {
            return true;
         }
         if(_loc3_ / _loc4_ > 1.5)
         {
            return true;
         }
         if(avatarData.loveExp)
         {
            return true;
         }
         if(avatarData.skillExp)
         {
            return true;
         }
         if(hpP + apP + dePhP + deMaP > 0)
         {
            return true;
         }
         return false;
      }

      public function getSwallowValue(param1:Avatar) : Number
      {
         var _loc9_:Boolean = false;
         var _loc3_:String = null;
         var _loc4_:Number = 0;
         var _loc2_:int = getType();
         var _loc8_:int = getStar();
         var _loc7_:int = avatarData.offerExp;
         var _loc6_:int = avatarData.offerGold;
         _loc9_ = GlobalData.$tempAvatarBetter.id == id || GlobalFunction.checkIsTeamMember(id) || GlobalFunction.checkLock(id);
         _loc4_ = Math.min(10,_loc7_ / _loc6_) * 200 + Math.max(-_loc6_ * 0.1,_loc7_ * 1.2 - _loc6_) + _loc7_ * 0.001 + 50;
         if(_loc9_)
         {
            _loc4_ -= 10000000;
         }
         if(param1.lv >= param1.getLvMax())
         {
            _loc4_ -= _loc7_;
         }
         var _loc5_:int = hpP + apP + dePhP + deMaP;
         if(_loc2_ == 1)
         {
            _loc4_ -= 100000;
            _loc4_ -= _loc8_ * 20000;
            _loc4_ -= _loc5_ * 100;
         }
         else if(_loc5_ > 0)
         {
            _loc4_ += 2000000 + _loc5_ * 100;
         }
         if(param1.getType() == 1)
         {
            if(param1.getLoveList()[0] < GlobalData.$mConfig_simple.love_up[0])
            {
               if(avatarData.loveExp)
               {
                  _loc4_ += 4000000 + avatarData.loveExp * 1000;
               }
            }
            if(param1.avatarData.skill0 != "" && param1.slv < GlobalData.$mConfig_simple.slv_config[0])
            {
               if(avatarData.skillExp)
               {
                  _loc4_ += 3000000 + avatarData.skillExp * 1000;
               }
            }
         }
         else
         {
            if(avatarData.loveExp)
            {
               _loc4_ -= 2000000 + avatarData.loveExp * 1000;
            }
            if(avatarData.skillExp)
            {
               _loc4_ -= 1000000 + avatarData.skillExp * 1000;
            }
         }
         if(lv > 20)
         {
            _loc4_ -= lv * 1000;
         }
         else
         {
            _loc4_ -= lv * 1;
         }
         _loc4_ -= _loc8_ * 10;
         _loc4_ -= phase * 10000;
         if(param1.slv >= GlobalData.$mConfig_simple.slv_config[0])
         {
            _loc3_ = "";
         }
         else
         {
            _loc3_ = param1.avatarData.skill0;
         }
         if(_loc3_ == "")
         {
            _loc4_ -= avatarData.skillExp * 10000;
         }
         _loc4_ -= Math.max(0,slv - 1) * 10000;
         if(isStarUpStuff())
         {
            _loc4_ -= 100000;
         }
         if(morph > 0)
         {
            _loc4_ -= 7000000;
         }
         return _loc4_ + getIdValue();
      }

      public function getExpeditionValue() : Number
      {
         var _loc2_:Number = 0;
         var _loc3_:int = getPower(getLvMax());
         _loc2_ = _loc3_;
         var _loc1_:int = getType();
         if(_loc1_ != 1)
         {
            return -1;
         }
         _loc2_ -= avatarData.skillExp * 10000;
         _loc2_ -= avatarData.loveExp * 10000;
         _loc2_ -= (hpP + apP + dePhP + deMaP) * 100;
         if(lv > 20)
         {
            _loc2_ -= lv * 200;
         }
         _loc2_ -= getStar() * 10000;
         _loc2_ -= phase * 10000;
         _loc2_ -= Math.max(0,slv - 1) * 10000;
         _loc2_ -= loveExp * 10000;
         if(morph > 0)
         {
            _loc2_ -= 7000000;
         }
         return _loc2_ + getIdValue();
      }

      public function getSellValue() : Number
      {
         var _loc2_:Number = 0;
         var _loc5_:int = getOfferExp();
         var _loc4_:int = avatarData.offerGold;
         _loc2_ = Math.min(10,_loc4_ / _loc5_) * 200 + Math.max(-_loc5_ * 0.1,_loc4_ - _loc5_) + _loc4_ * 0.001 + 250;
         var _loc1_:int = getType();
         if(_loc1_ == 1)
         {
            _loc2_ -= 10000000;
         }
         if(avatarData.loveExp)
         {
            _loc2_ -= 2000000 + avatarData.loveExp * 1000;
         }
         if(avatarData.skillExp)
         {
            _loc2_ -= 1000000 + avatarData.skillExp * 1000;
         }
         var _loc3_:int = hpP + apP + dePhP + deMaP;
         if(_loc3_ > 0)
         {
            _loc2_ -= 500000 + (hpP + apP + dePhP + deMaP) * 100;
         }
         if(lv > 10)
         {
            _loc2_ -= lv * 1000;
         }
         else
         {
            _loc2_ -= lv * 1;
         }
         _loc2_ -= getStar() * 100;
         _loc2_ -= phase * 10000;
         _loc2_ -= Math.max(0,slv - 1) * 10000;
         _loc2_ -= loveExp * 60000;
         if(isStarUpStuff())
         {
            _loc2_ -= 100000;
         }
         if(morph > 0)
         {
            _loc2_ -= 7000000;
         }
         return _loc2_ + getIdValue();
      }

      public function getPower(param1:Boolean = false, param2:int = -1, param3:Boolean = false) : Number
      {
         var _loc10_:Number = skill0 ? skill0.getPower() : 0;
         var _loc9_:Number = param1 ? (skill1 ? skill1.getPower() : 0) : 0;
         var _loc4_:Number = skill2 ? skill2.getPower() : 0;
         var _loc8_:Number = skillB ? skillB.getPower() : 0;
         var _loc7_:Number = talent ? talent.getPower() : 0;
         var _loc6_:* = GlobalData.$mConfig_simple.power;
         if(param2 < 0)
         {
            param2 = lv;
         }
         var _loc5_:Number = Math.pow(getHpMax(param2,-1,param3) * POWER_HP + getDamage(param2,-1,param3) * POWER_DAMAGE + getDePh(param2,-1,param3) * POWER_DE_PH + getDeMa(param2,-1,param3) * POWER_DE_MA,2) * (1 + _loc10_ + _loc9_ + _loc4_ + _loc8_) * (POWER_SPEED_RANGE + getSpeed(param3) + getRange(param3)) * (1 + Math.pow(getHit() + getFlee() + getCrit() + getTough(),1 / _loc6_[10]) * _loc6_[9]) * POWER_RATE;
         _loc5_ = Number(Math.floor(Number(_loc5_.toFixed(5))).toString(10)) + _loc5_ * _loc7_;
         return Number(Math.floor(Number(_loc5_.toFixed(5))).toString(10));
      }

      public function isRangedSkillCaster() : Boolean
      {
         if(getType() != 1) return false;
         var definition:Object = GlobalData.$mConfig_avatar[avatarData.id];
         var ranged:Boolean = definition && typeof definition.ranged_skill == "boolean" ? Boolean(definition.ranged_skill) : avatarData.range >= 500;
         if(!ranged) return false;
         return !abilityState.form || !abilityState.form.hammer;
      }

      public function getLvMax() : int
      {
         if(limitBreak > 0 && getType() == 1 && (getStar() == 5 || getStar() == 6)) return 125;
         if(morph == 0)
         {
            return avatarData.lvMax;
         }
         var _loc1_:* = GlobalData.$mConfig_ploy_system_simple.morph;
         return avatarData.lvMax + morph * _loc1_.attr[0];
      }

      public function getStar() : int
      {
         return avatarData.id.split("_")[2];
      }

      public function getStarMax() : int
      {
         return 6;
      }

      public function getType() : int
      {
         var modTypeRow:Object = GlobalData.$mConfig_avatar ? GlobalData.$mConfig_avatar[avatarData.id] : null;
         if(modTypeRow && modTypeRow.modUnitType == "summon") return 2;
         return int(avatarData.id.slice(2,3));
      }

      public function isStarUpStuff() : Boolean
      {
         var _loc1_:String = avatarData.id.slice(2,4);
         return _loc1_ == "60" || _loc1_ == "61";
      }

      public function getLeadership(param1:Boolean = false) : int
      {
         var _loc3_:int = 0;
         var _loc5_:Array = null;
         var _loc4_:int = avatarData.leadership;
         if(phase != 0)
         {
            _loc3_ = getType();
            _loc5_ = getPhaseList();
            if(_loc5_)
            {
               _loc4_ = _loc5_[4] * phase + _loc4_;
            }
         }
         if(morph != 0)
         {
            _loc4_ += GlobalData.$mConfig_ploy_system_simple.morph.attr[1];
         }
         if(param1)
         {
            return _loc4_;
         }
         var _loc2_:Array = getLoveList();
         if(_loc2_[0] != 0)
         {
            _loc4_ = Math.max(1,_loc4_ - _loc2_[0] * GlobalData.$mConfig_simple.love_up[3]);
         }
         return _loc4_;
      }

      public function getPhase() : int
      {
         return avatarData.id.split("_")[2];
      }

      public function getPhaseList() : Array
      {
         var _loc4_:* = null;
         var _loc2_:Object = null;
         var _loc1_:int = getType();
         var _loc5_:Array = GlobalData.$mConfig_simple.phase_config;
         var _loc3_:int = getStar();
         if(_loc1_ == 1)
         {
            _loc2_ = _loc5_[0];
         }
         else
         {
            _loc2_ = _loc5_[1];
         }
         return _loc2_[String(_loc3_)];
      }

      public function getPhaseLv() : int
      {
         if(phase == 0)
         {
            return 0;
         }
         var _loc1_:Array = getPhaseList();
         if(_loc1_)
         {
            return _loc1_[2] * phase;
         }
         return 0;
      }

      public function getPhasePith() : int
      {
         if(phase == 0)
         {
            return 0;
         }
         var _loc1_:Array = getPhaseList();
         if(_loc1_)
         {
            return _loc1_[3];
         }
         return 0;
      }

      public function getPhaseType() : int
      {
         var _loc4_:Array = null;
         var _loc2_:Object = null;
         var _loc6_:AvatarData = avatarData;
         if(_loc6_.lvMax == 1)
         {
            return 0;
         }
         var _loc1_:int = getType();
         var _loc5_:Array = GlobalData.$mConfig_simple.phase_config;
         var _loc3_:int = getStar();
         if(_loc1_ == 1)
         {
            _loc2_ = _loc5_[0];
         }
         else
         {
            _loc2_ = _loc5_[1];
         }
         _loc4_ = _loc2_[String(_loc3_)];
         if(_loc3_ == 5 && phase >= 2 && _loc6_.starUp.length > 0 && !GlobalFunction.isNullNextStarCfgId(id)) return 2;
         if(_loc4_)
         {
            if(phase < _loc4_[1])
            {
               return 1;
            }
         }
         if(_loc6_.starUp.length > 0 && !GlobalFunction.isNullNextStarCfgId(id))
         {
            return 2;
         }
         return 0;
      }

      public function goFight(param1:int, param2:int, param3:Number, param4:Boolean = true) : void
      {
         summonStatSnapshot = false;
         formationOwner = null;
         abilityState = {}; abilitySerial = 0; abilityIndex = ++abilityNextIndex;
         abilityEntryAttack = 0;
         team = param1;
         isLeader = param4;
         if(GameMap.currentMap)
         {
            if(team == 1)
            {
               pos = Math.round(GameMapConfig.LINE_POS * (1 - param3));
            }
            else
            {
               pos = Math.round(GameMapConfig.LINE_POS * param3);
            }
         }
         else
         {
            pos = 0;
         }
         offset = 0;
         line = param2;
         initbuffs();
         initFightAttr();
         abilityEntryAttack = ap;
         ready();
      }

      public function initFightAttr() : void
      {
         initializingFightAttributes = true;
         if(!(mData && mData.tpl))
         {
            hpMax = 0;
         }
         ap = getDamage(-1,-1,true);
         deMa = getDeMa(-1,-1,true);
         dePh = getDePh(-1,-1,true);
         speed = getSpeed(true);
         range = getRange(true);
         hit = getHit();
         flee = getFlee();
         crit = getCrit();
         tough = getTough();
         hpMax = getHpMax(-1,-1,true);
         initializingFightAttributes = false;
         if(hp <= 0)
         {
            hp = hpMax;
         }
      }

      public function checkAction() : Boolean
      {
         var _currentMap:GameMap;
         var _gl:GameMapLayer;
         var _tween1:Tween;
         var _avatarData:AvatarData;
         var _aimAvatar:Avatar;
         var _checkList:Vector.<Avatar>;
         var _focusAliveList:Vector.<Avatar>;
         var _hasBack:Boolean;
         var _fun:Function;
         GameMap.actionDelay = 0;
         rangePreviewQueued = false;
         rangeMoveEndsAt = 0;
         _currentMap = GameMap.currentMap;
         if(!_currentMap)
         {
            return false;
         }
         if(hp <= 0)
         {
            return false;
         }
         _focusAliveList = _currentMap.getAliveList(otherTeam) as Vector.<Avatar>;
         if(manualFocusTarget && (manualFocusTarget.hp <= 0 || manualFocusTarget.team == team || !_focusAliveList || _focusAliveList.indexOf(manualFocusTarget) < 0))
         {
            manualFocusTarget = null;
         }
         // A finished lane may still supply a global turn-start passive.
         // The lane-end guard below stops normal attacks, skills and movement.
         if(_currentMap.isEnd() || (_currentMap.winnerList[line] != 0 && (!skillB || skillB.getCastRange() <= GameMapConfig.LINE_POS)))
         {
            return false;
         }
         advanceManualOwnerAction();
         _currentMap.startAction(this);
         _gl = GameMapLayer.gl;
         _gl.juggler.removeTweens(fightRes);
         _tween1 = new Tween(fightRes,0.3 / 2,"easeInOut");
         _tween1.scaleTo(getScale() * 1.2);
         _tween1.fadeTo(1);
         _gl.addTween(_tween1);
         if(fightRes.parent)
         {
            (fightRes.parent as AvatarLayer).setFirst(fightRes);
         }
         refreshIcon();
         if(!GlobalData.$userData.nnnnnnnnn)
         {
            GlobalData.$userData.nnnnnnnnn = 0;
         }
         var _loc2_:Object = GlobalData.$userData;
         var _loc3_:Number = Number(_loc2_.nnnnnnnnn) + 1;
         _loc2_.nnnnnnnnn = _loc3_;
         trace("第" + GlobalData.$userData.nnnnnnnnn + "个英雄进行回合" + this.id);
         if(skill0)
         {
            skill0.cooldown();
         }
         if(skill1)
         {
            skill1.cooldown();
         }
         if(skill2)
         {
            skill2.cooldown();
         }
         if(skillB)
         {
            skillB.cooldown();
         }
         emitModEvent("turn_start",this,this);
         getTeamHp();
         if(checkBuffOfSkillB())
         {
            checkSkillB();
         }
         getTeamHp();
         if(GameMap.currentMap.isEnd(line))
         {
            _gl.delayCall(_currentMap.endAction,GameMap.actionDelay);
            return true;
         }
         if(skill0)
         {
            skill0.onOwnerTurnStart();
         }
         if(skill1)
         {
            skill1.onOwnerTurnStart();
         }
         if(abilityTurnStart())
         {
            _gl.delayCall(_currentMap.endAction,GameMap.actionDelay);
            return true;
         }
         if(checkBuff())
         {
            dead();
            _gl.delayCall(_currentMap.endAction,GameMap.actionDelay);
            return true;
         }
         if(buffs["stun"])
         {
            _gl.delayCall(SoundManager.getOnlyExample().playSound,GameMap.actionDelay,"stun");
            GameMap.actionDelay += 0.2;
         }
         else
         {
            GameMapTools.gameTrace("隊伍:" + team + "  " + id + "開始行動，位置：" + pos + "line:" + line);
            _avatarData = avatarData;
            _checkList = _currentMap.getAliveList(otherTeam) as Vector.<Avatar>;
            _hasBack = false;
            GlobalData.skillBoo = false;
            if(getEffectiveActionType() == 1)
            {
               _aimAvatar = checkAttack(_checkList,getSortOnFun());
               checkSkillB();
               if(!_aimAvatar)
               {
                  if(checkMove(true))
                  {
                     _aimAvatar = checkAttack(_checkList,getSortOnFun());
                     checkSkillB();
                     checkSkill();
                     checkSkillB();
                  }
                  else
                  {
                     checkSkill();
                     checkSkillB();
                  }
               }
               else
               {
                  checkSkill();
                  checkSkillB();
               }
            }
            else if(getEffectiveActionType() == 2)
            {
               _hasBack = checkSkill();
               checkSkillB();
               _aimAvatar = checkAttack(_checkList,getSortOnFun());
               checkSkillB();
               if(!_aimAvatar)
               {
                  if(!_hasBack && checkMove(true))
                  {
                     checkSkill();
                     checkSkillB();
                     _aimAvatar = checkAttack(_checkList,getSortOnFun());
                     checkSkillB();
                  }
               }
               else if(checkDangerous())
               {
                  checkMove(false);
               }
            }
            else if(getEffectiveActionType() == 4)
            {
               _hasBack = checkSkill();
               checkSkillB();
               _aimAvatar = checkAttack(_checkList,getSortOnFun());
               checkSkillB();
               if(!_aimAvatar)
               {
                  if(!_hasBack && checkMove(true))
                  {
                     checkSkill();
                     checkSkillB();
                     _aimAvatar = checkAttack(_checkList,getSortOnFun());
                     checkSkillB();
                  }
               }
               else
               {
                  checkMove(false);
               }
            }
            else
            {
               checkSkill();
               checkSkillB();
               _aimAvatar = checkAttack(_checkList,getSortOnFun());
               checkSkillB();
            }
            GameMapTools.gameTrace("隊伍:" + team + "  " + id + "結束行動，位置：" + pos + "line:" + line);
         }
         GameMap.actionDelay = Math.max(GameMap.actionDelay,0.3);
         _fun = function():void
         {
            _gl.juggler.removeTweens(fightRes);
            var _loc1_:Tween = new Tween(fightRes,0.3 / 2,"easeInOut");
            _loc1_.scaleTo(getScale());
            _loc1_.fadeTo(1);
            _loc1_.animate("x",GameMapConfig.offsetToPixel(offset));
            _loc1_.animate("y",GameMapConfig.posToPixel(pos));
            _gl.addTween(_loc1_);
         };
         _gl.delayCall(_fun,GameMap.actionDelay,fightRes);
         _gl.delayCall(_currentMap.endAction,GameMap.actionDelay);
         return true;
      }

      private function checkBuffOfSkillB() : Boolean
      {
         if(skillB && skillB.isModEffectSequence()) return skillB.modConditionReady();
         var _loc1_:Boolean = false;
         if(!this.avatarData.skill_diff)
         {
            return _loc1_;
         }
         for(var _loc2_:String in buffs)
         {
            if(_loc2_ == "evil" && this.avatarData.skill_diff == 4)
            {
               _loc1_ = true;
               GlobalData.skillBoo = true;
            }
            if(_loc2_ == "silence" && this.avatarData.skill_diff == 5)
            {
               _loc1_ = true;
               GlobalData.skillBoo = true;
            }
            if(_loc2_ == "stun" && this.avatarData.skill_diff == 6)
            {
               _loc1_ = true;
               GlobalData.skillBoo = true;
            }
            if(_loc2_ == "burn" && this.avatarData.skill_diff == 7)
            {
               _loc1_ = true;
               GlobalData.skillBoo = true;
            }
            if(_loc2_ == "sunder" && this.avatarData.skill_diff == 8)
            {
               _loc1_ = true;
               GlobalData.skillBoo = true;
            }
            if(_loc2_ == "poison" && this.avatarData.skill_diff == 9)
            {
               _loc1_ = true;
               GlobalData.skillBoo = true;
            }
            if(_loc2_ == "weak" && this.avatarData.skill_diff == 10)
            {
               _loc1_ = true;
               GlobalData.skillBoo = true;
            }
            if(_loc2_ == "shield" && this.avatarData.skill_diff == 11)
            {
               _loc1_ = true;
               GlobalData.skillBoo = true;
            }
            if(_loc2_ == "purify" && this.avatarData.skill_diff == 12)
            {
               _loc1_ = true;
               GlobalData.skillBoo = true;
            }
            if(_loc2_ == "strong" && this.avatarData.skill_diff == 13)
            {
               _loc1_ = true;
               GlobalData.skillBoo = true;
            }
            if((_loc2_ == "hitup" || _loc2_ == "fleeup" || _loc2_ == "critup" || _loc2_ == "toughup") && this.avatarData.skill_diff == 14)
            {
               _loc1_ = true;
               GlobalData.skillBoo = true;
            }
            if(_loc2_ == "bless" && this.avatarData.skill_diff == 15)
            {
               _loc1_ = true;
               GlobalData.skillBoo = true;
            }
            if(_loc2_ == "steel" && this.avatarData.skill_diff == 16)
            {
               _loc1_ = true;
               GlobalData.skillBoo = true;
            }
            if(_loc2_ == "taunt" && this.avatarData.skill_diff == 17)
            {
               _loc1_ = true;
               GlobalData.skillBoo = true;
            }
            if((_loc2_ == "evil" || _loc2_ == "silence" || _loc2_ == "stun" || _loc2_ == "burn" || _loc2_ == "sunder" || _loc2_ == "poison" || _loc2_ == "weak" || _loc2_ == "shield" || _loc2_ == "purify" || _loc2_ == "strong" || _loc2_ == "hitup" || _loc2_ == "fleeup" || _loc2_ == "critup" || _loc2_ == "toughup" || _loc2_ == "bless" || _loc2_ == "steel" || _loc2_ == "taunt") && this.avatarData.skill_diff == 18)
            {
               _loc1_ = false;
               GlobalData.skillBoo = false;
               return false;
            }
            if((_loc2_ == "root" || _loc2_ == "evil" || _loc2_ == "silence" || _loc2_ == "stun" || _loc2_ == "burn" || _loc2_ == "sunder" || _loc2_ == "poison" || _loc2_ == "weak" || _loc2_ == "curse") && this.avatarData.skill_diff == 19)
            {
               _loc1_ = true;
               GlobalData.skillBoo = true;
            }
            if(_loc1_)
            {
               trace(_loc2_ + "------" + this.avatarData.id + "---------------------------------------------------------" + "");
            }
         }
         if(this.avatarData.skill_diff == 18)
         {
            _loc1_ = true;
            GlobalData.skillBoo = true;
         }
         return _loc1_;
      }

      public function showMove(param1:Number = -1) : void
      {
         var _loc9_:int = 0;
         var _loc2_:int = 0;
         var _loc7_:int = 0;
         var _loc10_:int = 0;
         var _loc6_:GameMapLayer = GameMapLayer.gl;
         var _loc3_:int = 0;
         if(getSpeed() != 0)
         {
            _loc3_ = GameMapConfig.pixelToPos(0,GameMapConfig.FIGHT_HEIGHT * GameMapConfig.FIGHT_EXTRA_Y).y;
         }
         var _loc5_:int = pos;
         var _loc4_:int = pos;
         if(team == 1)
         {
            _loc3_ = -_loc3_;
         }
         else
         {
            _loc3_ = _loc3_;
         }
         _loc5_ = _loc4_ - _loc3_;
         var _loc8_:Number = 1.2;
         _loc3_ = Math.abs(_loc5_ - _loc4_);
         if(_loc3_ < 400)
         {
            _loc8_ *= _loc3_ / 400;
         }
         if(_loc8_ > 0)
         {
            _loc9_ = GameMapConfig.offsetToPixel(offset);
            _loc2_ = GameMapConfig.posToPixel(_loc5_);
            fightRes.x = _loc9_;
            fightRes.y = _loc2_;
            _loc7_ = GameMapConfig.offsetToPixel(offset);
            _loc10_ = GameMapConfig.posToPixel(_loc4_);
            _loc6_.delayCall(resBounce,param1,_loc7_,_loc10_,1.15,0.4 * 0.8,_loc8_);
         }
      }

      public function checkMove(param1:Boolean, param2:int = 0, param3:Avatar = null, param4:Number = -1, param5:Boolean = false, param6:String = null) : Number
      {
         if(abilityState.root && !param5) return 0;
         var _loc18_:int = 0;
         var _loc13_:int = 0;
         var _loc20_:int = 0;
         var _loc12_:Tween = null;
         var _loc19_:* = undefined;
         var _loc17_:Tween = null;
         var _loc15_:Tween = null;
         if(GameMap.currentMap.isEnd(line))
         {
            return 0;
         }
         var _loc8_:GameMapLayer = GameMapLayer.gl;
         var _loc7_:Boolean = false;
         if(param2 == 0)
         {
            param2 = getSpeed();
            _loc7_ = true;
         }
         var _loc16_:int = GameMapConfig.offsetToPixel(offset);
         var _loc11_:int = GameMapConfig.posToPixel(pos);
         param2 = Math.abs(param2);
         var _loc10_:int = 0;
         var _loc9_:int = pos;
         if(param4 < 0)
         {
            param4 = GameMap.actionDelay;
         }
         if(param1)
         {
            if(team == 1)
            {
               _loc18_ = -param2;
            }
            else
            {
               _loc18_ = param2;
            }
         }
         else if(team == 1)
         {
            _loc18_ = param2;
         }
         else
         {
            _loc18_ = -param2;
         }
         var requestedPos:int = pos + _loc18_;
         if(_loc7_ && !param5 && !param3)
         {
            requestedPos = clampSummonFormation(requestedPos);
            if(param1) requestedPos = clampOwnerAdvance(requestedPos);
         }
         pos = GameMap.currentMap.getFinalPos(team,line,requestedPos);
         var _loc14_:Number = 0.4;
         param2 = Math.abs(_loc9_ - pos);
         if(param2 < 400)
         {
            _loc14_ *= param2 / 400;
         }
         if(_loc14_ > 0)
         {
            if(GameMap.currentAvatar === this)
            {
               rangeMoveEndsAt = Math.max(rangeMoveEndsAt,param4 + _loc14_);
            }
            if(param3)
            {
               offset += (param3.offset - offset) * ((pos - _loc9_) / (param3.pos - _loc9_));
               offset = Math.max(-GameMapConfig.sideOffset,Math.min(offset,GameMapConfig.sideOffset));
            }
            _loc13_ = GameMapConfig.offsetToPixel(offset);
            _loc20_ = GameMapConfig.posToPixel(pos);
            if(_loc7_)
            {
               _loc8_.delayCall((fightRes.parent as AvatarLayer).setFirst,param4,fightRes);
               _loc8_.delayCall(resBounce,param4,_loc13_,_loc20_,1.15,0.4 / 2,_loc14_);
               _loc8_.delayCall(SoundManager.getOnlyExample().playSound,param4,"move");
            }
            else
            {
               if(param3)
               {
                  _loc8_.delayCall(SoundManager.getOnlyExample().playSound,param4,"beMoved");
               }
               else
               {
                  _loc8_.delayCall(SoundManager.getOnlyExample().playSound,param4,"dash");
               }
               _loc12_ = new Tween(fightRes,_loc14_,"easeInOutBack");
               _loc12_.delay = param4;
               _loc12_.moveTo(_loc13_,_loc20_);
               _loc8_.addTween(_loc12_);
               if(param6)
               {
                  _loc19_ = DisplayTools.getAttrs(param6);
                  _loc19_.a1 = this;
                  _loc19_.x1 = _loc16_ + _loc8_.getLineSpr(line).x;
                  _loc19_.y1 = _loc11_;
                  _loc19_.x2 = _loc13_ + _loc8_.getLineSpr(line).x;
                  _loc19_.y2 = _loc20_;
                  _loc19_.par = _loc8_.effectLayer;
                  _loc8_.delayCall(DisplayTools.addBullet,param4,_loc19_);
               }
            }
            if(GameMap.currentAvatar != this)
            {
               _loc17_ = new Tween(fightRes,0.2,"easeInOut");
               _loc17_.delay = param4;
               _loc17_.scaleTo(getScale() * 1.2);
               _loc8_.addTween(_loc17_);
               _loc15_ = new Tween(fightRes,0.2,"easeInOut");
               _loc15_.delay = param4 + 0.2;
               _loc15_.scaleTo(getScale());
               _loc8_.addTween(_loc15_);
            }
         }
         if(!param5)
         {
            GameMap.actionDelay += Math.max(0,_loc14_ - 0.08);
         }
         return _loc14_;
      }

      public function resSpeak() : void
      {
         var _loc1_:Tween = null;
         if(team == 0)
         {
            return;
         }
         var _loc3_:GameMapLayer = GameMapLayer.gl;
         var _loc2_:Sprite = fightRes;
         if(!_loc2_ || !_loc2_.parent)
         {
            return;
         }
         (_loc2_.parent as AvatarLayer).setFirst(_loc2_);
         _loc1_ = new Tween(_loc2_,0.2,"easeIn");
         _loc1_.delay = 0.2 * 1;
         _loc1_.scaleTo(_loc2_.scaleX * 1.3);
         _loc3_.addTween(_loc1_);
         _loc1_ = new Tween(_loc2_,0.2,"easeOutBack");
         _loc1_.delay = 0.2 * 4;
         _loc1_.scaleTo(_loc2_.scaleX);
         _loc3_.addTween(_loc1_);
      }

      public function resBounce(param1:int, param2:int, param3:Number, param4:Number, param5:Number) : void
      {
         var _loc11_:int = 0;
         var _loc10_:Tween = null;
         var _loc9_:Tween = null;
         var _loc6_:int = param5 / param4 + 1;
         param4 = param5 / _loc6_;
         var _loc8_:GameMapLayer = GameMapLayer.gl;
         var _loc7_:Sprite = fightRes;
         _loc11_ = 0;
         while(_loc11_ < _loc6_)
         {
            _loc10_ = new Tween(_loc7_,param4 / 2,"easeIn");
            _loc10_.delay = param4 * _loc11_;
            _loc10_.scaleTo(_loc7_.scaleX * param3);
            _loc10_.animate("rotation",_loc11_ % 2 == 0 ? 0.1 : -0.1);
            _loc10_.moveTo(_loc7_.x + (param1 - _loc7_.x) * (_loc11_ + 0.5) / _loc6_,_loc7_.y + (param2 - _loc7_.y) * (_loc11_ + 0.5) / _loc6_);
            _loc8_.addTween(_loc10_);
            _loc9_ = new Tween(_loc7_,param4 / 2,"easeOut");
            _loc9_.delay = param4 * _loc11_ + param4 / 2;
            _loc9_.scaleTo(_loc7_.scaleX);
            _loc9_.animate("rotation",0);
            _loc9_.moveTo(_loc7_.x + (param1 - _loc7_.x) * (_loc11_ + 1) / _loc6_,_loc7_.y + (param2 - _loc7_.y) * (_loc11_ + 1) / _loc6_);
            _loc8_.addTween(_loc9_);
            _loc11_++;
         }
      }

      public function resSwing(param1:Number, param2:Number) : void
      {
         var _loc9_:int = 0;
         var _loc8_:Tween = null;
         var _loc7_:Tween = null;
         var _loc5_:Number = Number(NaN);
         var _loc3_:int = param2 / param1 + 1;
         param1 = param2 / _loc3_;
         var _loc6_:GameMapLayer = GameMapLayer.gl;
         var _loc4_:Sprite = fightRes;
         _loc9_ = 0;
         while(_loc9_ < _loc3_)
         {
            _loc5_ = 0.5 * (_loc3_ - _loc9_) / _loc3_;
            _loc8_ = new Tween(_loc4_,param1 / 2,"easeIn");
            _loc8_.delay = param1 * _loc9_;
            _loc8_.animate("rotation",_loc9_ % 2 == 0 ? _loc5_ : -_loc5_);
            _loc6_.addTween(_loc8_);
            _loc7_ = new Tween(_loc4_,param1 / 2,"easeOut");
            _loc7_.delay = param1 * _loc9_ + param1 / 2;
            _loc7_.animate("rotation",0);
            _loc6_.addTween(_loc7_);
            _loc9_++;
         }
      }

      public function reline(param1:int, param2:int = -2147483648, param3:int = -2147483648, param4:Number = 0, param5:Number = 0, forced:Boolean = false) : void
      {
         if(abilityState.root && !forced) return;
         if(param1 != line) delete abilityState.channel;
         var _loc10_:* = undefined;
         var _loc6_:int = line;
         _loc10_ = DisplayTools.getAttrs("RE_LINE_OUT_EFF_" + team);
         _loc10_.a1 = this;
         DisplayTools.formatAttrs(_loc10_);
         line = param1;
         if(param2 == -2147483648)
         {
            if(team == 1)
            {
               pos = GameMapConfig.LINE_POS;
            }
            else
            {
               pos = 0;
            }
         }
         else
         {
            pos = GameMap.currentMap.getFinalPos(team,param1,param2);
         }
         if(param3 == -2147483648)
         {
            offset = 0;
         }
         else
         {
            offset = param3;
         }
         var _loc7_:GameMapLayer = GameMapLayer.gl;
         var _loc9_:Tween = new Tween(fightRes,2.8 / 6,"easeInOut");
         _loc9_.delay = GameMap.actionDelay + param5;
         _loc9_.scaleTo(0);
         _loc7_.addTween(_loc9_);
         _loc7_.delayCall(refreshReline,2.8 / 2 + GameMap.actionDelay + param4,line,pos,offset);
         var _loc8_:Tween = new Tween(fightRes,2.8 / 6,"easeInOut");
         _loc8_.delay = GameMap.actionDelay + 2.8 / 2 + param4 + 0.1 + param5;
         _loc8_.scaleTo(getScale());
         _loc7_.addTween(_loc8_);
         _loc10_.par = _loc7_.effectLayer;
         _loc7_.delayCall(DisplayTools.addEffects,GameMap.actionDelay + param5,_loc10_);
         _loc10_ = DisplayTools.getAttrs("RE_LINE_IN_EFF_" + team);
         _loc10_.a1 = this;
         _loc10_.par = _loc7_.effectLayer;
         _loc7_.delayCall(DisplayTools.addEffects,GameMap.actionDelay + param4 + param5 + 2.8 / 2,_loc10_);
      }

      public function isResolvingSkill() : Boolean
      {
         var context:Object = currentAbilityAttack();
         return context && context.owner === this && context.kind == "active";
      }

      public function checkAttack(param1:Vector.<Avatar>, param2:Function, param3:int = -1, param4:Boolean = false, param5:int = -1, param6:Number = 1, param7:int = 0, param8:String = null, param9:Buff = null, param10:Number = 1) : Avatar
      {
         var _aim:Avatar;
         if(GameMap.currentMap.isEnd(line) && !isResolvingSkill())
         {
            return null;
         }
         _aim = checkAllAttack(param1,param2,param3,param4,param5,param6,param7,param8,param9,param10);
         if(_aim && manualFocusTarget === _aim)
         {
            manualFocusTarget = null;
         }
         return _aim;
      }

      public function checkAllAttack(param1:Vector.<Avatar>, param2:Function, param3:int = -1, param4:Boolean = false, param5:int = -1, param6:Number = 1, param7:int = 0, param8:String = null, param9:Buff = null, param10:Number = 1) : Avatar
      {
         var _loc11_:* = undefined;
         _loc11_ = findAimList(param1,param2,param3,param4);
         if(_loc11_.length > 0)
         {
            if(GameMap.currentAvatar === this && param5 < 0 && !currentAbilityAttack())
            {
               queueRangePreview();
            }
            attackAimList(_loc11_,param5,param6,param7,param8,param4,param9,param3,param10);
            return _loc11_[0];
         }
         return null;
      }

      public function checkMiss(param1:Avatar, param2:Avatar, param3:* = null) : Boolean
      {
         if(param2.getEffectiveActionType() == 3)
         {
            return false;
         }
         var _loc9_:* = GlobalData.$mConfig_simple.attack;
         var _loc7_:int = Tools.toInt(param1.getHit() + param1.getHit() * param1.checkTalent(4));
         var _loc6_:int = Tools.toInt(param2.getFlee() + param2.getFlee() * param2.checkTalent(5));
         var _loc5_:int = Tools.toInt(Math.min(_loc9_[6],Math.max(0,_loc9_[4] + 100 * (_loc6_ - _loc7_) / (_loc6_ + _loc7_ + _loc9_[9]))));
         GameMapTools.gameTrace("闪避判定",param1.id,param2.id);
         var _loc4_:Boolean = Random.getRandom() < _loc5_;
         var _loc8_:GameMapLayer = GameMapLayer.gl;
         if(_loc4_)
         {
            _loc8_.delayCall(_loc8_.infoLayer.popTextForAvatar,GameMap.actionDelay,GlobalLanguageStr.getLanguageStr(30010),param2,13684944,35,1);
            _loc8_.delayCall(missTween,GameMap.actionDelay - 0.2,param2);
            _loc8_.delayCall(SoundManager.getOnlyExample().playSound,GameMap.actionDelay - 0.1,"miss");
            param1.emitModEvent("miss",param1,param2);
            param2.emitModEvent("dodge",param1,param2);
            GameMapTools.gameTrace(GameMap.currentAvatar.id,GameMap.currentAvatar.team,"        ",param2.id,param2.team + "閃避");
            if(param3)
            {
               param3 = Tools.clone(param3);
               param3.a1 = param2;
               param3.a2 = param1;
               param3.re = true;
               param3.par = _loc8_.effectLayer;
               _loc8_.delayCall(DisplayTools.addEffects,GameMap.actionDelay,param3);
            }
            if(param2.buffs["taunt"])
            {
               param3 = DisplayTools.getAttrs("TAUNT_HIT_EFF");
               param3.a1 = param2;
               param3.par = _loc8_.effectLayer;
               _loc8_.delayCall(DisplayTools.addEffects,GameMap.actionDelay - 1,param3);
            }
         }
         return _loc4_;
      }

      public function checkTalent(param1:int, param2:Boolean = false) : Number
      {
         if(this.summonStatSnapshot && param1 >= 1 && param1 <= 3) return 0;
         var _loc9_:int = 0;
         var _loc4_:Avatar = null;
         var _loc6_:Number = 0;
         var _loc8_:Number = 0;
         var _loc7_:GameMap = GameMap.currentMap;
         var _loc3_:Vector.<Avatar> = _loc7_ ? _loc7_.getAliveList(team) as Vector.<Avatar> : null;
         var _loc5_:Vector.<Avatar> = _loc7_ ? _loc7_.getAliveList(otherTeam) as Vector.<Avatar> : null;
         if(_loc7_ && team >= 1 && team <= 2 && _loc3_ && _loc5_)
         {
            if(param1 == 14 || param1 == 15 || param1 == 16)
            {
               _loc9_ = 0;
               while(_loc9_ < _loc3_.length)
               {
                  _loc4_ = _loc3_[_loc9_];
                  if(_loc4_ && _loc4_.talent && !_loc4_.isTeamFlatTalent() && !_loc4_.isPanelStatTalent())
                  {
                     if(_loc4_.talent.my_HaloData.plType == param1 && _loc4_.talent.my_HaloData.plUse == 1 && (_checkListmyCurrHp ? _checkListmyCurrHp[_loc9_] : 1) > 0)
                     {
                        _loc8_ = _loc8_ > _loc4_.talent.my_HaloData.plNum ? _loc8_ : _loc4_.talent.my_HaloData.plNum;
                     }
                  }
                  _loc9_++;
               }
               if(talent && !isTeamFlatTalent() && !isPanelStatTalent())
               {
                  if(talent.my_HaloData.plType == param1 && talent.my_HaloData.plUse == 0)
                  {
                     _loc8_ = _loc8_ > talent.my_HaloData.plNum ? _loc8_ : talent.my_HaloData.plNum;
                  }
               }
               _loc8_ = -_loc8_;
               trace(_loc8_ / 100);
               return _loc8_ / 100 < -1 ? -1 : _loc8_ / 100;
            }
            _loc9_ = 0;
            while(_loc9_ < _loc3_.length)
            {
               _loc4_ = _loc3_[_loc9_];
               if(_loc4_ && _loc4_.talent && !_loc4_.isTeamFlatTalent() && !_loc4_.isPanelStatTalent())
               {
                  if((_loc4_.talent.my_HaloData.plType == param1 || param1 == 3 && _loc4_.ownGrowthValue("defense") > 0) && _loc4_.talent.my_HaloData.plUse == 1 && (_checkListmyCurrHp ? _checkListmyCurrHp[_loc9_] : 1) > 0)
                  {
                     _loc6_ = _loc6_ > _loc4_.talent.my_HaloData.plNum ? _loc6_ : _loc4_.talent.my_HaloData.plNum;
                  }
               }
               _loc9_++;
            }
            if(talent && !isTeamFlatTalent() && !isPanelStatTalent())
            {
               if((talent.my_HaloData.plType == param1 || param1 == 3 && ownGrowthValue("defense") > 0) && talent.my_HaloData.plNum > _loc6_ && talent.my_HaloData.plUse == 0)
               {
                  _loc6_ = talent.my_HaloData.plNum;
               }
            }
            _loc9_ = 0;
            while(_loc9_ < _loc5_.length)
            {
               _loc4_ = _loc5_[_loc9_];
               if(_loc4_ && _loc4_.talent && !_loc4_.isTeamFlatTalent() && !_loc4_.isPanelStatTalent())
               {
                  if(_loc4_.talent.my_HaloData.plType < 8)
                  {
                     if(_loc4_.talent.my_HaloData.plType == param1 && _loc4_.talent.my_HaloData.plUse == 2 && (_checkListotherCurrHp ? _checkListotherCurrHp[_loc9_] : 1) > 0)
                     {
                        _loc8_ = _loc8_ > _loc4_.talent.my_HaloData.plNum ? _loc8_ : _loc4_.talent.my_HaloData.plNum;
                     }
                  }
               }
               _loc9_++;
            }
            _loc6_ -= _loc8_;
            if(_loc6_ != 0)
            {
               trace("+++++++++++++++++++++++++++++++++++++++++++++++++++++++增加数据百分比" + _loc6_);
            }
            return _loc6_ / 100 < -1 ? -1 : _loc6_ / 100;
         }
         return 0;
      }

      public function getTeamHp() : void
      {
         var _loc1_:* = 0;
         var _loc4_:GameMap = GameMap.currentMap;
         var _loc2_:Vector.<Avatar> = _loc4_.getAliveList(this.team) as Vector.<Avatar>;
         var _loc3_:Vector.<Avatar> = _loc4_.getAliveList(this.team - 1) as Vector.<Avatar>;
         _checkListmyCurrHp = [];
         _checkListotherCurrHp = [];
         _loc1_ = 0;
         while(_loc1_ < _loc2_.length)
         {
            _checkListmyCurrHp.push(_loc2_[_loc1_].hp);
            _loc1_++;
         }
         _loc1_ = 0;
         while(_loc1_ < _loc3_.length)
         {
            _checkListotherCurrHp.push(_loc3_[_loc1_].hp);
            _loc1_++;
         }
      }

      public function attackAimList(param1:Vector.<Avatar>, param2:int = -1, param3:Number = 1, param4:int = 0, param5:String = null, param6:Boolean = false, param7:Buff = null, param8:int = -1, param9:Number = 1, effectSource:Avatar = null) : int
      {
         if(param2 < 0 || param2 >= 1 && param2 <= 4) param3 *= purpleBondMultiplier();
         if(param7 && param7.type == "shield") param7.value *= purpleBondMultiplier();
         var basicContext:Object = null;
         var aimTarget:Avatar = param1 && param1.length ? param1[0] : null;
         if(param1 && param1.length == 1) prepareParallelVisualTarget(aimTarget,true);
         var playBatchAttack:Boolean = param1 && param1.length ? playParallelAttackTween() : true;
         var markedBasic:Boolean = false;
         if(!currentAbilityAttack() && (param2 < 0 || param2 >= 1 && param2 <= 3))
         {
            basicContext = beginAbilityAttack(this,"basic");
            markedBasic = aimTarget && aimTarget.abilityHasMark(this,"aim");
            if(markedBasic) param3 *= 1+0.8*Number(aimTarget.abilityState["mark_aim_"+abilityIndex].scale);
         }
         try
         {

         var bookBasicAttack:Boolean = param2 == -1;
         var bookHPBefore:int = 0;
         var _loc38_:* = 0;
         var _loc10_:Avatar = null;
         var _loc12_:Avatar = null;
         var _loc46_:Array = null;
         var _loc24_:int = 0;
         var _loc48_:int = 0;
         var _loc37_:Number = Number(NaN);
         var _loc23_:Number = Number(NaN);
         var _loc28_:Number = Number(NaN);
         var _loc15_:* = undefined;
         var _loc20_:Number = Number(NaN);
         var _loc40_:Number = Number(NaN);
         var _loc18_:Point = null;
         var _loc27_:* = undefined;
         var _loc34_:int = 0;
         var _loc43_:Number = Number(NaN);
         var _loc36_:int = 0;
         var _loc11_:Avatar = null;
         if(!param1 || param1.length == 0)
         {
            return 0;
         }
         getTeamHp();
         var _loc32_:GameMap = GameMap.currentMap;
         var _loc17_:Vector.<Avatar> = _loc32_.getAliveList(this.team) as Vector.<Avatar>;
         var _loc19_:Vector.<Avatar> = _loc32_.getAliveList(this.team - 1) as Vector.<Avatar>;
         _loc38_ = 0;
         while(_loc38_ < _loc17_.length)
         {
            _loc17_[_loc38_].getTeamHp();
            _loc38_++;
         }
         _loc38_ = 0;
         while(_loc38_ < _loc19_.length)
         {
            _loc19_[_loc38_].getTeamHp();
            _loc38_++;
         }
         param8 = Math.min(GameMapConfig.LINE_POS + 1,param8);
         var _loc16_:Number = checkTalent(1);
         var _loc29_:Number = getDamage();
         var recoveryBase:Number = Tools.toInt(_loc29_ + _loc29_ * _loc16_);
         if(param2 == 4)
         {
            recoveryBase += getHpMax() * 0.1;
         }
         var _loc14_:int = Tools.toInt(recoveryBase * param3);
          if(param2 == 4)
          {
             var recoveryHit:Number = Tools.toInt(getHit() * (1 + checkTalent(4)));
             var recoveryU:Number = 1 + 0.5 * recoveryHit / (recoveryHit + 3000);
             _loc14_ = Tools.toInt(_loc14_ * recoveryU * getRecoveryTalentMultiplier() * activeManualEffectMultiplier());
          }
         trace(this.id + "|||||||||||||oldDamage" + getDamage() + "*" + _loc16_ + "|||||||" + getDamage() * _loc16_ + "|||||||||||" + param3 + "|||||||||||newDamage" + _loc14_);
         var _loc21_:int = 0;
         var _loc33_:int = 0;
         var _loc26_:int = GameMapConfig.lineToPixel(GameMap.currentMap.getShowLine(line),offset);
         var _loc35_:int = GameMapConfig.posToPixel(pos);
         var _loc47_:Number = 0;
         var _loc45_:Number = 0;
         var _loc30_:GameMapLayer = GameMapLayer.gl;
         var _loc39_:Sprite = fightRes;
         var _loc22_:int = otherTeam;
         var _loc44_:int = 0;
         var _loc13_:Boolean = AvatarData.isAttack(param2);
         var _loc42_:Boolean = AvatarData.canMiss(param2);
         var _loc31_:Boolean = false;
         if(!_loc13_)
         {
            _loc22_ = team;
         }
         if(param2 < 0)
         {
            param2 = avatarData.damageType;
         }
         if(param5 == null)
         {
            param5 = avatarData.effectSet;
         }
         var _loc41_:* = DisplayTools.getAttrs(param5);
         if(!_loc41_)
         {
            _loc41_ = {};
         }
         // Keep the steel-impact presentation alive even when a device is
         // running an older effect table that does not know the custom marker.
         var isSteelLaneWave:Boolean = param5 == "FX_STEEL_LANE_WAVE";
         var _loc25_:* = _loc41_.h;
         if(!_loc25_)
         {
            _loc25_ = {};
         }
         _loc25_.par = _loc30_.effectLayer;
         GameMap.actionDelay += 0.3;
         if(playBatchAttack && (!effectSource || effectSource === this) && fightRes.parent)
         {
            _loc30_.delayCall((fightRes.parent as AvatarLayer).setFirst,GameMap.actionDelay,fightRes);
         }
         _loc27_ = Tools.clone(_loc41_.pre);
         if(_loc27_ && (!effectSource || effectSource === this))
         {
            _loc23_ = 0.05;
            _loc27_.a1 = effectSource || this;
            _loc27_.par = _loc30_.effectLayer;
            _loc30_.delayCall(DisplayTools.addEffects,GameMap.actionDelay - 0.3 / 2,_loc27_);
            GameMap.actionDelay += _loc23_;
         }
         if(_loc41_.laneWave || isSteelLaneWave)
         {
            _loc30_.delayCall(showLaneShockwave,GameMap.actionDelay,effectSource || this);
            if(playBatchAttack && (!effectSource || effectSource === this))
            {
               _loc30_.delayCall(attackTween,GameMap.actionDelay,this,param1[0]);
            }
            // A fixed impact time aligns the existing full-lane shockwave.
            // Keep the normal miss, crit, shield and injury paths for each unit.
            var waveHitDelay:Number = GameMap.actionDelay + 0.18;
            var waveEndDelay:Number = waveHitDelay;
            for each(var waveTarget:Avatar in param1)
            {
               GameMap.actionDelay = waveHitDelay;
               if(_loc42_ && checkMiss(this,waveTarget,_loc25_))
               {
                  if(skillB && avatarData.skill_diff == 1) GlobalData.skillBoo = true;
               }
               else
               {
                  _loc46_ = _loc42_ ? countDamage(this,waveTarget,_loc14_,param2,param9) : [_loc14_,false];
                  _loc20_ = _loc42_ ? checkCrit(this,waveTarget) : 1;
                  if(_loc20_ != 1 && skillB && avatarData.skill_diff == 2) GlobalData.skillBoo = true;
                  bookHPBefore = waveTarget.hp;
                  _loc21_ += waveTarget.injured(_loc46_[0],_loc20_,_loc25_,param2,this,_loc46_[1],this,param7);
                  if(bookBasicAttack) applyBookAttackEffects(waveTarget,Math.max(0,bookHPBefore - waveTarget.hp));
               }
               waveEndDelay = Math.max(waveEndDelay,GameMap.actionDelay);
            }
            GameMap.actionDelay = Math.max(waveEndDelay,waveHitDelay + 0.32);
            return _loc21_;
         }
         if(param4 == GameMapConfig.MIN_SPACE_POS - 1)
         {
            _loc24_ = _loc26_ = GameMapConfig.lineToPixel(GameMap.currentMap.getShowLine(line),0);
            _loc34_ = int(param8 == GameMapConfig.LINE_POS ? param8 + 400 : param8);
            _loc34_ = Math.max(-400,Math.min(GameMapConfig.LINE_POS + 400,team == 1 ? pos - _loc34_ : pos + _loc34_));
            _loc48_ = GameMapConfig.posToPixel(_loc34_);
            _loc27_ = Tools.clone(_loc41_);
            _loc27_.a1 = effectSource || this;
            _loc27_.x1 = _loc26_;
            _loc27_.x2 = _loc24_;
            _loc27_.y1 = _loc35_;
            _loc27_.y2 = _loc48_;
            _loc27_.check = true;
            _loc28_ = Math.max(DisplayTools.addBullet(_loc27_) - 0.08,0);
            delete _loc27_.check;
            _loc27_.par = _loc30_.effectLayer;
            _loc30_.delayCall(DisplayTools.addBullet,GameMap.actionDelay + 0.25,_loc27_);
            _loc26_ = GameMapConfig.offsetToPixel(0);
            if(playBatchAttack) _loc30_.delayCall(attackTween,GameMap.actionDelay,this,null,_loc26_);
            _loc26_ = pos;
            _loc10_ = param1[0];
            if(_loc10_.pos - _loc26_ < 0)
            {
               param8 = -param8;
            }
            _loc34_ = 0;
            while(_loc34_ < param1.length)
            {
               _loc10_ = param1[_loc34_];
               _loc23_ = _loc28_ * (_loc10_.pos - _loc26_) / param8;
               GameMap.actionDelay += _loc23_;
               if(_loc42_ && checkMiss(this,_loc10_))
               {
                  if(skillB)
                  {
                     if(this.avatarData.skill_diff == 1)
                     {
                        GlobalData.skillBoo = true;
                     }
                  }
               }
               else
               {
                  _loc46_ = _loc42_ ? countDamage(this,_loc10_,_loc14_,param2,param9) : [_loc14_,false];
                  _loc20_ = _loc42_ ? checkCrit(this,_loc10_) : 1;
                  if(_loc20_ != 1)
                  {
                     if(skillB)
                     {
                        if(this.avatarData.skill_diff == 2)
                        {
                           GlobalData.skillBoo = true;
                        }
                     }
                  }
                  bookHPBefore = _loc10_.hp;
                  _loc21_ += _loc10_.injured(_loc46_[0],_loc20_,_loc25_,param2,this,_loc46_[1],this,param7);
                  if(bookBasicAttack) applyBookAttackEffects(_loc10_,Math.max(0,bookHPBefore - _loc10_.hp));
                  _loc33_++;
                  _loc26_ = _loc10_.pos;
               }
               _loc34_++;
            }
            return _loc21_;
         }
         _loc34_ = 0;
         while(_loc34_ < param1.length)
         {
            if(param4 >= 0 && param4 < GameMapConfig.MIN_SPACE_POS)
            {
               if(_loc34_ > param4)
               {
                  break;
               }
            }
            else if(_loc34_ > 0)
            {
               break;
            }
            _loc10_ = param1[_loc34_];
            GameMap.actionDelay -= _loc47_;
            if(param4 >= GameMapConfig.MIN_SPACE_POS)
            {
               _loc24_ = GameMapConfig.lineToPixel(GameMap.currentMap.getShowLine(_loc10_.line),_loc10_.offset / 2);
            }
            else
            {
               _loc24_ = GameMapConfig.lineToPixel(GameMap.currentMap.getShowLine(_loc10_.line),_loc10_.offset);
            }
            _loc48_ = GameMapConfig.posToPixel(_loc10_.pos);
            _loc27_ = Tools.clone(_loc41_);
            _loc27_.a1 = effectSource || this;
            _loc27_.x1 = _loc26_;
            _loc27_.x2 = _loc24_;
            _loc27_.y1 = _loc35_;
            _loc27_.y2 = _loc48_;
            _loc27_.check = true;
            _loc28_ = Math.max(DisplayTools.addBullet(_loc27_) - 0.08,0);
            _loc45_ = Math.max(_loc28_,_loc45_);
            delete _loc27_.check;
            _loc27_.par = _loc30_.effectLayer;
            _loc30_.delayCall(DisplayTools.addBullet,GameMap.actionDelay,_loc27_);
            if(playBatchAttack && (!effectSource || effectSource === this) && param4 != GameMapConfig.MIN_SPACE_POS - 1 && _loc34_ == 0)
            {
               _loc30_.delayCall(attackTween,GameMap.actionDelay,this,_loc10_);
            }
            GameMap.actionDelay += _loc28_;
            _loc47_ = _loc28_;
            if(_loc42_ && checkMiss(this,_loc10_,_loc27_.h))
            {
               if(skillB)
               {
                  if(this.avatarData.skill_diff == 1)
                  {
                     GlobalData.skillBoo = true;
                  }
               }
            }
            else
            {
               _loc46_ = _loc42_ ? countDamage(this,_loc10_,_loc14_,param2,param9) : [_loc14_,false];
               _loc20_ = _loc42_ ? checkCrit(this,_loc10_) : 1;
               if(_loc20_ != 1)
               {
                  if(skillB)
                  {
                     if(this.avatarData.skill_diff == 2)
                     {
                        GlobalData.skillBoo = true;
                     }
                  }
               }
               bookHPBefore = _loc10_.hp;
               _loc21_ += _loc10_.injured(_loc46_[0],_loc20_,_loc25_,param2,this,_loc46_[1],this,param7);
               if(bookBasicAttack) applyBookAttackEffects(_loc10_,Math.max(0,bookHPBefore - _loc10_.hp));
               _loc33_++;
            }
            _loc34_++;
         }
         if(param4 > 0 && param4 < GameMapConfig.MIN_SPACE_POS)
         {
            _loc44_ = Math.min(6,param4 + 1 - param1.length);
            if(_loc44_ > 0)
            {
               GameMap.actionDelay -= _loc47_;
               _loc40_ = GameMapTools.getRadians(new Point(_loc26_,_loc35_),new Point(_loc24_,_loc48_));
               _loc43_ = (1 / (_loc44_ + 5) + 0.12) * 1200 / param8;
               _loc34_ = 0;
               while(_loc34_ < _loc44_)
               {
                  _loc18_ = GameMapTools.vectorToGrid(_loc40_ + _loc43_ * (_loc34_ % 2 == 0 ? _loc34_ / 2 + 1 : -((_loc34_ - 1) / 2 + 1)),param8 * GameMapConfig.LANDFORM_POS);
                  _loc24_ = _loc26_ + _loc18_.x;
                  _loc48_ = _loc35_ + _loc18_.y;
                  _loc27_ = Tools.clone(_loc41_);
                  _loc27_.a1 = effectSource || this;
                  _loc27_.x1 = _loc26_;
                  _loc27_.x2 = _loc24_;
                  _loc27_.y1 = _loc35_;
                  _loc27_.y2 = _loc48_;
                  _loc27_.par = _loc30_.effectLayer;
                  _loc30_.delayCall(DisplayTools.addBullet,GameMap.actionDelay,_loc27_);
                  _loc34_++;
               }
               GameMap.actionDelay += _loc47_;
            }
         }
         GameMap.actionDelay += _loc45_ - _loc47_;
         if(param4 >= GameMapConfig.MIN_SPACE_POS)
         {
            if(_loc33_ == 0)
            {
               if(_loc41_.h)
               {
                  _loc30_.delayCall(DisplayTools.addSound,GameMap.actionDelay,_loc41_.h.s);
               }
            }
            _loc15_ = GameMap.currentMap.getAliveList(_loc22_) as Vector.<Avatar>;
            _loc15_ = _loc10_.findAimList(_loc15_,null,param4,param6);
            _loc36_ = GameMapConfig.posToPixel(param4);
            _loc47_ = 0;
            _loc45_ = 0;
            _loc34_ = 0;
            while(_loc34_ < _loc15_.length)
            {
               _loc12_ = _loc15_[_loc34_];
               if(_loc10_ != _loc12_)
               {
                  GameMap.actionDelay -= _loc47_;
                  _loc23_ = 0.15 + _loc47_;
                  _loc45_ = Math.max(_loc23_,_loc45_);
                  GameMap.actionDelay += _loc23_;
                  _loc47_ = _loc23_;
                  if(_loc42_ && checkMiss(this,_loc12_))
                  {
                     if(skillB)
                     {
                        if(this.avatarData.skill_diff == 1)
                        {
                           GlobalData.skillBoo = true;
                        }
                     }
                  }
                  else
                  {
                     _loc46_ = _loc42_ ? countDamage(this,_loc12_,_loc14_,param2,param9) : [_loc14_,false];
                     _loc20_ = _loc42_ ? checkCrit(this,_loc12_) : 1;
                     if(_loc20_ != 1)
                     {
                        if(skillB)
                        {
                           if(this.avatarData.skill_diff == 2)
                           {
                              GlobalData.skillBoo = true;
                           }
                        }
                     }
                     bookHPBefore = _loc12_.hp;
                     _loc21_ += _loc12_.injured(_loc46_[0],_loc20_,_loc25_,param2,_loc10_,_loc46_[1],this,param7);
                     if(bookBasicAttack) applyBookAttackEffects(_loc12_,Math.max(0,bookHPBefore - _loc12_.hp));
                     _loc33_++;
                  }
               }
               _loc34_++;
            }
            GameMap.actionDelay += _loc45_ - _loc47_;
         }
         else if(param4 < 0)
         {
            _loc15_ = GameMap.currentMap.getAliveList(_loc22_) as Vector.<Avatar>;
            _loc15_ = _loc10_.findAimList(_loc15_,_loc10_.sortOnPos,GameMapConfig.LINE_POS,param6);
            param4 = -param4;
            _loc11_ = _loc10_;
            _loc34_ = 0;
            while(_loc34_ < _loc15_.length)
            {
               if(_loc44_ >= param4)
               {
                  break;
               }
               _loc12_ = _loc15_[_loc34_];
               if(_loc10_ != _loc12_)
               {
                  _loc44_++;
                  _loc26_ = _loc24_;
                  _loc35_ = _loc48_;
                  _loc24_ = GameMapConfig.lineToPixel(GameMap.currentMap.getShowLine(_loc12_.line),_loc12_.offset);
                  _loc48_ = GameMapConfig.posToPixel(_loc12_.pos);
                  _loc27_ = Tools.clone(_loc41_);
                  _loc27_.a1 = effectSource || this;
                  _loc27_.x1 = _loc26_;
                  _loc27_.x2 = _loc24_;
                  _loc27_.y1 = _loc35_;
                  _loc27_.y2 = _loc48_;
                  _loc27_.check = true;
                  _loc23_ = Math.max(DisplayTools.addBullet(_loc27_) - 0.08,0);
                  delete _loc27_.check;
                  _loc27_.par = _loc30_.effectLayer;
                  _loc30_.delayCall(DisplayTools.addBullet,GameMap.actionDelay,_loc27_);
                  _loc11_ = _loc12_;
                  GameMap.actionDelay += _loc23_;
                  if(_loc42_ && checkMiss(this,_loc12_,_loc27_.h))
                  {
                     if(skillB)
                     {
                        if(this.avatarData.skill_diff == 1)
                        {
                           GlobalData.skillBoo = true;
                        }
                     }
                  }
                  else
                  {
                     _loc46_ = _loc42_ ? countDamage(this,_loc12_,_loc14_,param2,param9) : [_loc14_,false];
                     _loc20_ = _loc42_ ? checkCrit(this,_loc12_) : 1;
                     if(_loc20_ != 1)
                     {
                        if(skillB)
                        {
                           if(this.avatarData.skill_diff == 2)
                           {
                              GlobalData.skillBoo = true;
                           }
                        }
                     }
                     bookHPBefore = _loc12_.hp;
                     _loc21_ += _loc12_.injured(_loc46_[0],_loc20_,_loc25_,param2,_loc11_,_loc46_[1],this,param7);
                     if(bookBasicAttack) applyBookAttackEffects(_loc12_,Math.max(0,bookHPBefore - _loc12_.hp));
                     _loc33_++;
                  }
               }
               _loc34_++;
            }
         }
         return _loc21_;

         }
         finally
         {
            if(basicContext)
            {
               if(markedBasic && basicContext.hits.indexOf(aimTarget) >= 0) delete aimTarget.abilityState["mark_aim_"+abilityIndex];
               endAbilityAttack(basicContext);
               if(bookBasicAttack) emitModEvent("basic_attack",this,aimTarget);
               if(bookBasicAttack && this.skillB && this.skillB.skills && this.skillB.skills.length && this.skillB.skills[0][0] == "polar_basic") polarBasicAttack();
            }
         }
      }

      public function checkDangerous() : Boolean
      {
         var _loc2_:* = undefined;
         var _loc5_:int = 0;
         var _loc1_:* = null;
         var _loc6_:Number = hpRate;
         if(_loc6_ >= DANGEROUS_RATE)
         {
            return false;
         }
         return true;
      }

      public function get hpRate() : Number
      {
         return hp / hpMax;
      }

      private static function showLaneShockwave(source:Avatar) : void
      {
         var layer:GameMapLayer = GameMapLayer.gl;
         if(!layer || !source || !source.fightRes || !source.fightRes.parent) return;
         // Resolve the rendered origin at playback, including the attack bounce,
         // horizontal offset, lane translation and camera transformation.
         var origin:Point = layer.effectLayer.globalToLocal(source.fightRes.localToGlobal(new Point(source.fightRes.pivotX,source.fightRes.pivotY)));
         var endPos:int = source.team == 1 ? -150 : GameMapConfig.LINE_POS + 150;
         var finish:Point = layer.effectLayer.globalToLocal(layer.getLineSpr(source.line).localToGlobal(new Point(0,GameMapConfig.posToPixel(endPos))));
         var laneWidth:Number = Math.abs(GameMapConfig.offsetToPixel(GameMapConfig.lineOffset * 0.92));
         var wave:Sprite = new Sprite();
         wave.name = "steelLaneWave";
         wave.touchable = false;
         wave.x = origin.x;
         wave.y = origin.y;
         layer.effectLayer.addChild(wave);
         // Hold a fully formed native ring frame. Its startup bounds are zero
         // and its later swirl frames would shrink a lane wave into a dot.
         for(var echo:int = 0;echo < 3;echo++)
         {
            var front:Sprite = new Sprite();
            var art:DragonBonesSprite = DisplayTools.newDisplayObject({id:"e001",loop:true,m:"add"}) as DragonBonesSprite;
            if(!art) continue;
            wave.addChild(front);
            front.addChild(art);
            art.armature.advanceTime(0);
            art.armature.advanceTime(0.52);
            art.stop();
            var artWidth:Number = Math.max(1,art.width);
            var fullScale:Number = laneWidth / artWidth;
            art.scaleX = fullScale;
            art.scaleY = fullScale * 0.38;
            // Keep only the forward half: a broad crescent, not a flat beam.
            front.clipRect = new Rectangle(-laneWidth * 0.6,source.team == 1 ? -laneWidth * 0.26 : 0,laneWidth * 1.2,laneWidth * 0.26);
            front.scaleX = 0.45;
            front.scaleY = 0.65;
            front.alpha = 0.8 - echo * 0.22;
            var travel:Tween = new Tween(front,0.32,"easeOut");
            travel.delay = echo * 0.035;
            travel.moveTo(finish.x - origin.x,finish.y - origin.y);
            travel.animate("scaleX",1);
            travel.animate("scaleY",1);
            layer.addTween(travel);
         }
         var fade:Tween = new Tween(wave,0.22,"easeOut");
         fade.delay = 0.39;
         fade.fadeTo(0);
         fade.onComplete = wave.removeFromParent;
         fade.onCompleteArgs = [true];
         layer.addTween(fade);
      }

      private function showCurseImpact() : void
      {
         var layer:GameMapLayer = GameMapLayer.gl;
         if(!layer || !fightRes || !fightRes.parent) return;
         var impact:DisplayObject = DisplayTools.newDisplayObject(DisplayTools.getAttrs("CURSE_IMPACT"));
         if(!impact) return;
         impact.name = "curseImpact";
         var origin:Point = layer.effectLayer.globalToLocal(fightRes.localToGlobal(new Point(fightRes.pivotX,fightRes.pivotY)));
         impact.x = origin.x;
         impact.y = origin.y;
         layer.effectLayer.addChild(impact);
         var pulse:Tween = new Tween(impact,0.35,"easeOut");
         pulse.scaleTo(1.15);
         pulse.fadeTo(0);
         pulse.onComplete = impact.removeFromParent;
         pulse.onCompleteArgs = [true];
         layer.addTween(pulse);
      }

      private function absorbShieldDamage(amount:int, factor:Number) : int
      {
         var shield:Buff = buffs["shield"] as Buff;
         if(!shield || amount <= 0) return amount;
         if(!isFinite(factor) || factor < 1) factor = 1;
         var spent:int = Math.min(Math.max(0,shield.value),Tools.toInt(amount * factor));
         shield.value -= spent;
         if(shield.value <= 0) removeBuff("shield");
         return Tools.toInt(Math.max(0,Number(amount) - Number(spent) / factor));
      }

      public function injured(param1:int, param2:Number = 1, param3:* = null, param4:int = -1, param5:Avatar = null, param6:Boolean = false, param7:Avatar = null, param8:Buff = null, dotKind:String = "") : int
      {
         var abilityHpBefore:int = hp;
         var modShieldBefore:Number = buffs && buffs["shield"] ? Number(buffs["shield"].value) : 0;
         var nurseHealAmount:int = 0;
         var abilityDamageTaken:Number = 0;
         param1 = int(param1 * abilityDirectMultiplier(param7,param4));
         var _loc12_:String = null;
         var _loc21_:* = 0;
         var _loc9_:Buff = null;
         var _loc17_:* = undefined;
         var _loc13_:Number = Number(NaN);
         var _loc18_:Number = Number(NaN);
         var _loc10_:int = 0;
         var _loc16_:int = 0;
         var _loc22_:int = 0;
         var _loc15_:int = 0;
         var _loc25_:int = 0;
         var _loc23_:String = null;
         if(hp <= 0)
         {
            return 0;
         }
         if(param4 == 0)
         {
            if(param8)
            {
               var priorCurse:Buff = buffs["curse"];
               addBuff(param8.type,param8.round,param8.value,0,-1,param7 || param5);
               // Zero-damage actions return before the normal hit VFX below.
               // Show a burst only when the curse was actually accepted;
               // purification and weaker reapplications must not fake a hit.
               if(param8.type == "curse" && buffs["curse"] && buffs["curse"] !== priorCurse)
               {
                  GameMapLayer.gl.delayCall(showCurseImpact,GameMap.actionDelay);
               }
            }
            return 0;
         }
         if(param7 && param7.currentSkillKillContext)
         {
            param7.currentSkillKillContext.hit = true;
            if(getType() == 1)
            {
               param7.currentSkillKillContext.hitHero = true;
               if(param7.currentSkillKillContext.hitHeroes is Array && param7.currentSkillKillContext.hitHeroes.indexOf(this) < 0)
               {
                  param7.currentSkillKillContext.hitHeroes.push(this);
               }
            }
         }
         var _loc19_:GameMapLayer = GameMapLayer.gl;
         var _loc11_:int = 35;
         var _loc14_:Number = 0.5;
         param3 = Tools.clone(param3);
         if(param4 == 1)
         {
            _loc21_ = 16728128;
         }
         else if(param4 == 2)
         {
            _loc21_ = 8421631;
         }
         else if(param4 == 3)
         {
            _loc21_ = 13648080;
         }
         else if(param4 == 8)
         {
            _loc21_ = 13648127;
         }
         else if(param4 == 4)
         {
            _loc21_ = 65280;
         }
         else if(param4 == 6)
         {
            _loc21_ = 53248;
            _loc14_ = 0.75;
            GameMap.actionDelay += 1 / 2;
         }
         else if(param4 == 7)
         {
            _loc21_ = 16737792;
            _loc14_ = 0.75;
            GameMap.actionDelay += 1 / 2;
         }
         else
         {
            _loc21_ = 0;
         }
         param1 *= 1;
         var _loc24_:* = GlobalData.$mConfig_simple.attack;
         if(param4 == 4)
         {
            var bookHealer:Avatar = param7 || param5 || this;
            param1 = Tools.toInt(param1 * (1 + bookHealer.getBookCombatBonus("healing")));
            if(hasManualDotKind("burn"))
            {
               param1 = Tools.toInt(param1 * 0.6);
            }
            nurseHealAmount = Math.max(0,param1);
            param1 = Math.min(param1,hpMax - hp);
            hp += param1;
            GameMapTools.gameTrace(id + "治療++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" + param1);
            _loc12_ = GlobalLanguageStr.getLanguageStr(30000) + param1;
            _loc14_ = 0.75;
         }
         else
         {
            param1 = Tools.toInt(Tools.toInt(param1 * param2) * _loc24_[21]);
            _loc13_ = Tools.toInt(getTough() * (1 + checkTalent(7)));
            _loc18_ = 1 + _loc13_ * _loc24_[15] / (_loc13_ + _loc24_[13]);
            GameMapTools.gameTrace("減傷" + _loc18_,"原傷害" + param1,"新傷害" + Tools.toInt(param1 / _loc18_));
            param1 = Tools.toInt(param1 / _loc18_);
            trace("最终伤害算减伤之前" + param1);
            switch(param4 - 1)
            {
               case 0:
                  param1 = Tools.toInt(param1 + param1 * checkTalent(14,param7 ? 1 : 0));
                  break;
               case 1:
                  param1 = Tools.toInt(param1 + param1 * checkTalent(15,param7 ? 1 : 0));
                  break;
               case 2:
                  param1 = Tools.toInt(param1 + param1 * checkTalent(16,param7 ? 1 : 0));
                  break;
               case 5:
                  param1 = Tools.toInt(param1 + param1 * checkTalent(16,param7 ? 1 : 0));
                  break;
               case 6:
                  param1 = Tools.toInt(param1 + param1 * checkTalent(16,param7 ? 1 : 0));
            }
            trace("最终伤害算减伤之后" + param1);
            if(hasManualDotKind("poison")) param1 = Tools.toInt(param1 * 1.2);
            _loc9_ = buffs["shield"] as Buff;
            if(_loc9_)
            {
               var bookShieldFactor:Number = 1 + (param7 ? param7.getBookCombatBonus("shield_damage") : 0);
               if(dotKind == "bleed" || dotKind == "phantasm") bookShieldFactor *= 3;
               param1 = absorbShieldDamage(param1,bookShieldFactor);
            }
            if(param7 && param7.manualSkillDamageCapture && param7.manualSkillDamageCapture.active === true && param7.manualSkillDamageCapture.owner === param7)
            {
               param7.manualSkillDamageCapture.total = Number(param7.manualSkillDamageCapture.total) + Math.min(Math.max(0,param1),Math.max(0,hp));
            }
            hp -= param1;
            abilityDamageTaken = Math.min(Math.max(0,param1),Math.max(0,abilityHpBefore));
            if(param4 == 6)
            {
               _loc12_ = (dotKind == "bleed" ? "流血" : dotKind == "phantasm" ? "幻象" : GlobalLanguageStr.getLanguageStr(30013)) + param1;
            }
            else if(param4 == 7)
            {
               _loc12_ = GlobalLanguageStr.getLanguageStr(30029) + param1;
            }
            else
            {
               _loc12_ = String(param1);
            }
            if(!param7 && dotKind == "")
            {
               param7 = GameMap.currentAvatar;
            }
            // Native DOTs retain their source for events without becoming direct-hit retaliation.
            if(param7 && param7.team != team && param4 != 6 && param4 != 7)
            {
               _loc17_ = DisplayTools.getAttrs("BACK_BUL");
               if(hp > 0)
               {
                  _loc9_ = buffs["back"] as Buff;
                  if(_loc9_)
                  {
                     _loc16_ = GameMapConfig.lineToPixel(GameMap.currentMap.getShowLine(line),offset);
                     _loc22_ = GameMapConfig.posToPixel(pos);
                     _loc15_ = GameMapConfig.lineToPixel(GameMap.currentMap.getShowLine(param7.line),param7.offset);
                     _loc25_ = GameMapConfig.posToPixel(param7.pos);
                     _loc17_.a1 = this;
                     _loc17_.a2 = param7;
                     _loc17_.par = _loc19_.effectLayer;
                     _loc19_.delayCall(DisplayTools.addBullet,GameMap.actionDelay,_loc17_);
                     _loc19_.delayCall(_loc19_.infoLayer.popText,GameMap.actionDelay,GlobalLanguageStr.getLanguageStr(30060),_loc16_,_loc22_,16737792,25,0.5,team == 1);
                     param7.addBuff("burn",1,Tools.toInt(Tools.toInt(getDamage() + getDamage() * checkTalent(1)) * _loc9_.value),0.25 * 2,25,this);
                  }
               }
               else
               {
                  _loc9_ = buffs["avenge"] as Buff;
                  if(_loc9_)
                  {
                     _loc16_ = GameMapConfig.lineToPixel(GameMap.currentMap.getShowLine(line),offset);
                     _loc22_ = GameMapConfig.posToPixel(pos);
                     _loc15_ = GameMapConfig.lineToPixel(GameMap.currentMap.getShowLine(param7.line),param7.offset);
                     _loc25_ = GameMapConfig.posToPixel(param7.pos);
                     _loc17_.a1 = this;
                     _loc17_.a2 = param7;
                     _loc17_.par = _loc19_.effectLayer;
                     _loc19_.delayCall(DisplayTools.addBullet,GameMap.actionDelay,_loc17_);
                     _loc19_.delayCall(_loc19_.infoLayer.popText,GameMap.actionDelay,GlobalLanguageStr.getLanguageStr(30061),_loc16_,_loc22_,16737792,25,0.5,team == 1);
                     param7.addBuff("burn",1,Tools.toInt(hpMax * _loc9_.value),0.25 * 2,25,this);
                     removeBuff("avenge");
                  }
               }
            }
         }
         if(fightRes.parent)
         {
            _loc19_.delayCall((fightRes.parent as AvatarLayer).setFirst,GameMap.actionDelay,fightRes);
         }
         var _loc20_:String = null;
         if(param2 > 1)
         {
            _loc12_ = GlobalLanguageStr.getLanguageStr(30011) + _loc12_;
            _loc11_ = 45;
            _loc14_ = 0.75;
            _loc20_ = "critBg";
         }
         if(param6 == true)
         {
            _loc12_ = GlobalLanguageStr.getLanguageStr(30004) + _loc12_;
         }
         _loc19_.delayCall(refreshHp,GameMap.actionDelay,hp);
         if(param3)
         {
            param3.a1 = this;
            param3.a2 = param5;
            param3.re = true;
            // A visual effect is optional; keep HP/status settlement and number
            // popups running when a data-authored action intentionally has none.
            param3.par = _loc19_.effectLayer;
            _loc19_.delayCall(DisplayTools.addEffects,GameMap.actionDelay,param3);
         }
         if(buffs["taunt"])
         {
            if(param4 != 4 && param4 != 6 && param4 != 7 && param4 != 5 && param4 != 8)
            {
               _loc17_ = DisplayTools.getAttrs("TAUNT_HIT_EFF");
               _loc17_.a1 = this;
               _loc17_.par = _loc19_.effectLayer;
               _loc19_.delayCall(DisplayTools.addEffects,GameMap.actionDelay - 1,_loc17_);
            }
         }
         if(_loc21_ != 0)
         {
            _loc19_.delayCall(_loc19_.infoLayer.popInjuredForAvatar,GameMap.actionDelay,_loc12_,this,_loc21_,_loc11_,_loc14_,_loc20_,param5);
         }
         if(param8)
         {
            addBuff(param8.type,param8.round,param8.value,0,-1,param7 || param5);
         }
         if(hp <= 0)
         {
            if(param7)
            {
               if(param7.skillB)
               {
                  if(param7.avatarData.skill_diff == 3)
                  {
                     GlobalData.skillBoo = true;
                  }
               }
            }
         }
         if(hp <= 0 && manualLethalFloor)
         {
            var lethalKey:String = null;
            var lethalFloor:Object = null;
            var lethalMinHp:int = 0;
            var manualLethalCleanse:Boolean = false;
            for(lethalKey in manualLethalFloor)
            {
               lethalFloor = manualLethalFloor[lethalKey];
               if(lethalFloor && int(lethalFloor.rounds) > 0)
               {
                  lethalMinHp = Math.max(lethalMinHp,int(lethalFloor.minHp));
                  if(lethalFloor.cleanseOnTrigger === true) manualLethalCleanse = true;
               }
            }
            if(lethalMinHp > 0)
            {
               if(manualLethalCleanse) removeAllDebuff();
               hp = Math.max(1,Math.min(hpMax,lethalMinHp));
               if(_loc19_) _loc19_.delayCall(refreshHp,GameMap.actionDelay,hp);
               GameMapTools.gameTrace(id + "触发限时保命，保留" + hp + "生命");
            }
         }
         if(hp <= 0 && buffs["bless"])
         {
            removeAllDebuff();
            removeBuff("bless");
            hp = Math.max(1,Tools.toInt(hpMax * GlobalData.$mConfig_simple.attack[20]));
            GameMapTools.gameTrace(id + "之后神佑+" + hp);
            _loc19_.delayCall(blessFade,GameMap.actionDelay);
            _loc19_.delayCall(blessCure,GameMap.actionDelay + 1,hp);
            GameMap.actionDelay += 1 / 2;
         }
         if(hp <= 0 && tryndUndyingActive)
         {
            tryndUndyingActive = false;
            tryndUndyingRounds = 0;
            hp = 1;
            GameMapTools.gameTrace(id + "触发限时一次免死，保留1生命");
            _loc19_.delayCall(refreshHp,GameMap.actionDelay,hp);
         }
         var modActualDamage:Number = param4 == 4 ? 0 : Math.max(0,abilityHpBefore-Math.max(0,hp));
         var modActualHeal:Number = Math.min(Math.max(0,hpMax-abilityHpBefore),nurseHealAmount);
         var modOverheal:Number = Math.max(0,nurseHealAmount-modActualHeal);
         var modKilled:Boolean = abilityHpBefore > 0 && hp <= 0;
         var modShieldBroke:Boolean = modShieldBefore > 0 && (!buffs["shield"] || Number(buffs["shield"].value) <= 0);
         if(param4 == 4 && nurseHealAmount > 0)
         {
            emitModEvent("healed",param7 || param5 || this,this,modActualHeal,modOverheal);
            if(param7 || param5) (param7 || param5).emitModEvent("heal_done",param7 || param5,this,modActualHeal,modOverheal);
         }
         else if(param4 >= 1 && param4 != 4 && param4 != 5)
         {
            if(modActualDamage > 0)
            {
               emitModEvent("damage_taken",param7,this,modActualDamage);
               if(param7) param7.emitModEvent("damage_dealt",param7,this,modActualDamage);
            }
            if(param4 <= 3 && param7)
            {
               param7.emitModEvent("hit",param7,this,modActualDamage);
               if(param2 > 1) param7.emitModEvent("crit",param7,this,modActualDamage);
            }
            if(modShieldBroke)
               emitModEvent("shield_break",param7,this,modActualDamage);
            if(modKilled)
            {
               if(param7 && param7.team != team) param7.emitModEvent("kill",param7,this,modActualDamage);
               emitModEvent("death",param7,this,modActualDamage);
            }
         }
         if(param4 == 6 || param4 == 7 || param4 == 8)
         {
            GameMap.actionDelay += 1;
         }
         else if(hp <= 0)
         {
            if(hp <= -hpMax * 0.2)
            {
               dead(param5);
            }
            else
            {
               dead();
            }
         }
         if(hp <= 0 && param7 && param7.currentSkillKillContext)
         {
            param7.currentSkillKillContext.killed = true;
            param7.currentSkillKillContext.killedTarget = this;
            param7.currentSkillKillContext.killedType = getType();
            param7.currentSkillKillContext.killedSummon = buffs && buffs["summon"] != null;
         }
         if(param4 <= 3 || param4 >= 6)
         {
            ++GameMap.damageNum;
            _loc23_ = "受傷";
            if(param4 == 6)
            {
               _loc23_ = "毒";
            }
            else if(param4 == 7)
            {
               _loc23_ = "烧";
            }
            else if(param4 == 8)
            {
               _loc23_ = "劈";
            }
            if(GameMap.currentAvatar)
            {
               GameMapTools.gameTrace(GameMap.damageNum + ":" + GameMap.currentAvatar.id,GameMap.currentAvatar.team,"        ",id,team + _loc23_ + ":",param1);
            }
            else
            {
               GameMapTools.gameTrace(GameMap.damageNum + ":" + id,team + _loc23_ + ":",param1);
            }
         }
         if(param4 != 4) abilityRecordDamage(param7,param4,abilityHpBefore,abilityDamageTaken);
         var catContext:Object = currentAbilityAttack();
         if(param2 > 1 && param4 >= 1 && param4 <= 3 && param7 && catContext && catContext.owner === param7 && catContext.catCaptainCapture)
            catContext.catCrits = int(catContext.catCrits) + 1;
         if(hp <= 0 && abilityHpBefore > 0 && param7 && param7.team != team && param7.skillB && param7.skillB.skills && param7.skillB.skills.length && param7.skillB.skills[0][0] == "cat_passive")
            param7.queueCatSkinKill();
         if(hp <= 0 && abilityHpBefore > 0 && param7 && param7.team != team && param7.skillB && param7.skillB.skills && param7.skillB.skills.length && param7.skillB.skills[0][0] == "santa_kill")
            param7.queueSantaKill();
         if(param4 == 4 && nurseHealAmount > 0) queueNurseHealing(nurseHealAmount,Math.max(0,nurseHealAmount-Math.max(0,hpMax-abilityHpBefore)));
         return param1;
      }

      public function ready() : void
      {
         var _loc1_:GameMapLayer = GameMapLayer.gl;
         _loc1_.juggler.removeTweens(fightRes);
         hideRange();
         rangePreviewQueued = false;
         rangeMoveEndsAt = 0;
         if(hp <= 0)
         {
            hp = hpMax;
         }
         else
         {
            refreshHp(hp,true);
         }
         fightRes.visible = true;
         fightRes.alpha = 1;
         fightRes.scaleX = fightRes.scaleY = getScale();
         fightRes.rotation = 0;
         if(skill0)
         {
            skill0.ready();
         }
         if(skill1)
         {
            skill1.ready();
         }
         if(skill2)
         {
            skill2.ready();
         }
         if(skillB)
         {
            skillB.ready();
         }
         if(m_buff)
         {
            m_buff.removeChildren();
         }
         if(m_fightBg)
         {
            m_fightBg.flatten();
         }
         resetBuff();
      }

      public function refreshHp(param1:int, param2:Boolean = false) : void
      {
         var _loc5_:int = 0;
         var _loc4_:int = 0;
         var _loc3_:int = 0;
         var _loc6_:Tween = null;
         var _loc7_:GameMapLayer = GameMapLayer.gl;
         var _loc8_:Boolean = param1 / hpMax < mBloodSpr.perRate;
         if(GameMap.currentAvatar != this)
         {
            if(!param2 && _loc8_)
            {
               _loc6_ = new Tween(fightRes,0.2 / 2,"easeOutBack");
               _loc6_.animate("pivotY",team == 1 ? -20 : 20);
               _loc7_.addTween(_loc6_);
               _loc6_ = new Tween(fightRes,0.2,"easeIn");
               _loc6_.delay = 0.2 / 2;
               _loc6_.animate("pivotY",0);
               _loc7_.addTween(_loc6_);
            }
            else if(GameMap.currentMap && GameMap.currentMap.isFight)
            {
               _loc6_ = new Tween(fightRes,0.2,"easeInOut");
               _loc6_.scaleTo(getScale() * 1.2);
               _loc7_.addTween(_loc6_);
               _loc6_ = new Tween(fightRes,0.2,"easeInOut");
               _loc6_.delay = 0.2;
               _loc6_.scaleTo(getScale());
               _loc7_.addTween(_loc6_);
            }
         }
         else
         {
            _loc6_ = new Tween(fightRes,0.2,"easeInOut");
            _loc6_.scaleTo(getScale());
            _loc7_.addTween(_loc6_);
            _loc6_ = new Tween(fightRes,0.2,"easeInOut");
            _loc6_.delay = 0.2;
            _loc6_.scaleTo(getScale() * 1.2);
            _loc7_.addTween(_loc6_);
         }
         mBloodSpr.refresh(param1 / hpMax);
      }

      public function dead(param1:Avatar = null) : void
      {
         if(hp <= 0) abilityDeath();
         var _loc2_:GameMapLayer = GameMapLayer.gl;
         hideRange();
         if(GameMapLayer.isFastest)
         {
            _loc2_.delayCall(deadFast,GameMap.actionDelay);
         }
         else
         {
            _loc2_.delayCall(deadFade,GameMap.actionDelay,param1);
         }
         GameMap.currentMap.checkLineLose(team,line);
         if(getEffectiveActionType() != 3)
         {
            GameMap.currentMap.checkEnd();
         }
      }

      public function deadFast() : void
      {
         var _loc1_:GameMapLayer = GameMapLayer.gl;
         _loc1_.juggler.removeTweens(fightRes);
         fightRes.visible = false;
      }

      public function drop() : void
      {
         var _loc3_:Tween = null;
         var _loc4_:GameMapLayer = GameMapLayer.gl;
         var _loc1_:int = fightRes.x + _loc4_.getLineSpr(line).x;
         var _loc2_:int = fightRes.y;
         var _loc5_:Object = {
            "id":"e301",
            "x":"_x",
            "y":"_y"
         };
         _loc5_.par = _loc4_.effectLayer;
         m_drop = DisplayTools.addEffectOne(_loc5_);
         m_drop.scaleX = m_drop.scaleY = 0.2;
         _loc3_ = new Tween(m_drop,0.4,"easeOut");
         _loc3_.scaleTo(1.5);
         _loc3_.animate("rotation",3.141592653589793 * 2);
         _loc3_.animate("y",m_drop.y - 30);
         _loc4_.addTween(_loc3_);
         _loc3_ = new Tween(m_drop,0.3,"easeIn");
         _loc3_.delay = 0.8;
         _loc3_.scaleTo(1);
         _loc4_.addTween(_loc3_);
         SoundManager.getOnlyExample().playSound("drop");
         _loc4_.delayCall(dropFade,1.5);
      }

      public function dropFade() : void
      {
         var _gl:GameMapLayer;
         var _x1:int;
         var _x2:int;
         var _time:Number;
         var _tween:Tween;
         if(!m_drop)
         {
            return;
         }
         _gl = GameMapLayer.gl;
         _x1 = m_drop.x;
         _x2 = 40;
         _time = new Point(_x1 - _x2,m_drop.y - GameMapConfig.FIGHT_HEIGHT).length / GameMapConfig.FIGHT_HEIGHT;
         _time *= 0.6;
         _tween = new Tween(m_drop,_time);
         _tween.animate("y",GameMapConfig.FIGHT_HEIGHT);
         _tween.onComplete = function():void
         {
            if(m_drop)
            {
               m_drop.removeFromParent(true);
               m_drop = null;
            }
            if(_gl.uiLayer.m_bag)
            {
               _gl.juggler.removeTweens(_gl.uiLayer.m_bag);
               _tween = new Tween(_gl.uiLayer.m_bag,0.2,"easeOut");
               _tween.scaleTo(1.1);
               _gl.addTween(_tween);
               _tween = new Tween(_gl.uiLayer.m_bag,0.2,"easeIn");
               _tween.delay = 0.2;
               _tween.scaleTo(1);
               _gl.addTween(_tween);
            }
         };
         _gl.addTween(_tween);
         _tween = new Tween(m_drop,_time,"easeInBack");
         _tween.animate("x",_x2);
         _gl.addTween(_tween);
      }

      public function blessFade() : void
      {
         var _loc1_:Tween = null;
         var _loc2_:GameMapLayer = GameMapLayer.gl;
         if(fightRes)
         {
            _loc1_ = new Tween(fightRes,1 / 2,"easeInOut");
            _loc1_.fadeTo(0);
            _loc1_.scaleTo(0.2);
            _loc2_.addTween(_loc1_);
         }
      }

      public function blessCure(param1:int) : void
      {
         var _loc4_:String = null;
         var _loc2_:Tween = null;
         var _loc5_:* = undefined;
         _loc4_ = GlobalLanguageStr.getLanguageStr(30081) + GlobalLanguageStr.getLanguageStr(30000) + param1;
         var _loc3_:GameMapLayer = GameMapLayer.gl;
         if(fightRes)
         {
            _loc2_ = new Tween(fightRes,1 / 2,"easeInOut");
            _loc2_.fadeTo(1);
            _loc2_.scaleTo(getScale());
            _loc3_.addTween(_loc2_);
         }
         refreshHp(param1);
         _loc5_ = DisplayTools.getAttrs("BLESS_EFF");
         _loc5_.a1 = this;
         _loc5_.par = _loc3_.effectLayer;
         DisplayTools.addEffects(_loc5_);
         _loc3_.infoLayer.popInjuredForAvatar(_loc4_,this,65280,35,0.75);
      }

      public function deadFade(param1:Avatar = null) : void
      {
         var _tween:Tween;
         var _res1:Sprite;
         var _res2:Sprite;
         var _SpeedX:Number;
         var _SpeedY:Number;
         var _dis:Number;
         var _w:int;
         var _rect:Rectangle;
         var _re:Object;
         var i:int;
         var _x:int;
         var _y:int;
         var _srcAvatar:Avatar = param1;
         var _gl:GameMapLayer = GameMapLayer.gl;
         var _delay:Number = 0;
         _gl.juggler.removeTweens(fightRes);
         _tween = new Tween(fightRes,0.2 / 2,"easeOutBack");
         _tween.animate("pivotY",team == 1 ? -20 : 20);
         _gl.addTween(_tween);
         _tween = new Tween(fightRes,0.2,"easeIn");
         _tween.delay = 0.2 / 2;
         _tween.animate("pivotY",0);
         _gl.addTween(_tween);
         if(isDrop)
         {
            drop();
         }
         if(_srcAvatar && avatarData.actionType != 3)
         {
            _delay = 0.4;
            _res1 = fightRes;
            _res2 = _srcAvatar.fightRes;
            _SpeedX = _res1.x - _res2.x + Math.random() * 100 - 100 / 2;
            _SpeedY = _res1.y - _res2.y;
            _dis = new Point(_SpeedX,_SpeedY).length;
            _SpeedX = _SpeedX * 1000 / _dis;
            _SpeedY = _SpeedY * 1000 / _dis;
            _w = GameMapConfig.offsetToPixel(GameMapConfig.lineOffset);
            _rect = new Rectangle(-_w / 2,0,_w,GameMapConfig.FIGHT_HEIGHT);
            _x = _res1.x;
            _y = _res1.y;
            _res1.parent.setChildIndex(_res1,_res1.parent.numChildren - 1);
            _res1.scaleX = _res1.scaleY = 1.1;
            i = 0;
            while(i < 3)
            {
               _re = GameMapTools.getHitTime(_x,_y,_SpeedX,_SpeedY,_rect);
               _x = int(_re.pos.x);
               _y = int(_re.pos.y);
               _tween = new Tween(fightRes,_re.time);
               _tween.delay = _delay;
               _tween.moveTo(_x,_y);
               _tween.animate("rotation",(_delay + _re.time) * 10);
               _gl.addTween(_tween);
               if(i == 3 - 1)
               {
                  _tween = new Tween(fightRes,0.1);
                  _tween.delay = _delay + _re.time - 0.1;
                  _tween.fadeTo(0);
                  _tween.onComplete = function():void
                  {
                     fightRes.removeFromParent();
                     fightRes.visible = false;
                  };
                  _gl.addTween(_tween);
               }
               if(_re.side == 1)
               {
                  _SpeedX = -_SpeedX;
               }
               else
               {
                  _SpeedY = -_SpeedY;
               }
               _delay += _re.time;
               i += 1;
            }
            return;
         }
         _tween = new Tween(fightRes,0.5,"easeInOut");
         _tween.delay = _delay;
         _tween.fadeTo(0);
         _tween.scaleTo(0.2);
         _tween.onComplete = function():void
         {
            fightRes.visible = false;
            fightRes.removeFromParent();
         };
         _tween.animate("y",fightRes.y - 30);
         _gl.addTween(_tween);
      }

      public function checkSkillB() : void
      {
         if(skillB && GlobalData.skillBoo)
         {
            GlobalData.skillBoo = false;
            // A global passive can still have a valid target after this lane
            // is cleared. Keep checking it when its cast range crosses lanes.
            if(!GameMap.currentMap || GameMap.currentMap.isEnd() || (GameMap.currentMap.isEnd(line) && skillB.getCastRange() <= GameMapConfig.LINE_POS))
            {
               return;
            }
            skillB.checkUse();
         }
      }

      public function checkSkill() : Boolean
      {
         var _loc1_:Boolean = false;
         if(buffs["silence"])
         {
            return _loc1_;
         }
         if(GameMap.currentMap.isEnd(line))
         {
            return _loc1_;
         }
         if(skill2)
         {
            if(skill2.checkUse())
            {
               _loc1_ = true;
            }
            if(GameMap.currentMap.isEnd(line))
            {
               return _loc1_;
            }
         }
         if(skill0)
         {
            if(skill0.checkUse())
            {
               _loc1_ = true;
            }
            if(GameMap.currentMap.isEnd(line))
            {
               return _loc1_;
            }
         }
         if(isLeader && skill1)
         {
            if(skill1.checkUse())
            {
               _loc1_ = true;
            }
         }
         return _loc1_;
      }

      public function findAimList(param1:Vector.<Avatar>, param2:Function = null, param3:int = -1, param4:Boolean = false) : Vector.<Avatar>
      {
         var _loc7_:int = 0;
         var _loc6_:* = undefined;
         var _loc8_:int = 0;
         var _loc5_:Avatar = null;
         _loc6_ = new Vector.<Avatar>();
         if(param3 == 0)
         {
            if(param1.indexOf(this) != -1)
            {
               _loc6_.push(this);
            }
            return _loc6_;
         }
         if(param3 < 0)
         {
            param3 = getRange();
         }
         if(param3 > GameMapConfig.LINE_POS)
         {
            _loc7_ = -1;
         }
         else
         {
            _loc7_ = line;
         }
         _loc8_ = 0;
         while(_loc8_ < param1.length)
         {
            _loc5_ = param1[_loc8_];
            if(_loc5_)
            {
               if(!(_loc7_ >= 0 && _loc5_.line != _loc7_))
               {
                  if(!(param4 && _loc5_.getEffectiveActionType() == 3))
                  {
                     if(_loc5_.hp > 0 && Math.abs(pos - _loc5_.pos) <= param3)
                     {
                        _loc6_.push(_loc5_);
                     }
                  }
               }
            }
            _loc8_++;
         }
         if(_loc6_.length == 0)
         {
            return _loc6_;
         }
         if(Boolean(param2))
         {
            _loc6_ = Tools.sortVector(_loc6_,param2);
         }
         return _loc6_;
      }

      public function findAim(param1:Vector.<Avatar>, param2:Function = null, param3:int = -1, param4:Boolean = false) : Avatar
      {
         param1 = findAimList(param1,param2,param3,param4);
         if(param1.length > 0)
         {
            return param1[0];
         }
         return null;
      }

      public function getSortOnFun() : Function
      {
         var _loc1_:AvatarData = avatarData;
         var _baseSort:Function;
         if(getEffectiveActionType() == 1)
         {
            _baseSort = sortOnPos;
         }
         else if(getEffectiveActionType() == 2)
         {
            _baseSort = sortOnHpLoss;
         }
         else
         {
            _baseSort = sortOnDamage;
         }
         if(manualFocusTarget && manualFocusTarget.hp > 0 && manualFocusTarget.team != team)
         {
            var _focus:Avatar = manualFocusTarget;
            var _fallback:Function = _baseSort;
            return function(param1:Avatar,param2:Avatar):int
            {
               if(param1 === _focus && param2 !== _focus) return -1;
               if(param2 === _focus && param1 !== _focus) return 1;
               return _fallback(param1,param2);
            };
         }
         return _baseSort;
      }

      public function setManualFocusTarget(param1:Avatar) : void
      {
         manualFocusTarget = param1 && param1.hp > 0 && param1.team != team ? param1 : null;
      }

      public function clearManualFocusTarget(param1:Avatar = null) : void
      {
         if(param1 == null || manualFocusTarget === param1)
         {
            manualFocusTarget = null;
         }
      }

      protected function sortOnPos(param1:Avatar, param2:Avatar) : int
      {
         if(param1 == this)
         {
            return -1;
         }
         if(param2 == this)
         {
            return 1;
         }
         if(param1.team != team)
         {
            if(param1.buffs["taunt"] && !param2.buffs["taunt"])
            {
               return -1;
            }
            if(param2.buffs["taunt"] && !param1.buffs["taunt"])
            {
               return 1;
            }
         }
         var _loc4_:int = Math.abs(line - param1.line) * (GameMapConfig.LINE_POS + 1) + Math.abs(pos - param1.pos);
         var _loc3_:int = Math.abs(line - param2.line) * (GameMapConfig.LINE_POS + 1) + Math.abs(pos - param2.pos);
         if(_loc4_ < _loc3_)
         {
            return -1;
         }
         if(_loc4_ > _loc3_)
         {
            return 1;
         }
         return 0;
      }

      protected function sortOnHpLoss(param1:Avatar, param2:Avatar) : int
      {
         if(param1.team != team)
         {
            if(param1.buffs["taunt"] && !param2.buffs["taunt"])
            {
               return -1;
            }
            if(param2.buffs["taunt"] && !param1.buffs["taunt"])
            {
               return 1;
            }
         }
         var _loc3_:int = param1.hpMax - param1.hp - (param2.hpMax - param2.hp);
         if(_loc3_ > 0)
         {
            return -1;
         }
         if(_loc3_ < 0)
         {
            return 1;
         }
         if(param1.hp < param2.hp)
         {
            return -1;
         }
         if(param1.hp > param2.hp)
         {
            return 1;
         }
         return 0;
      }

      protected function sortOnDamage(param1:Avatar, param2:Avatar) : int
      {
         if(param1.team != team)
         {
            if(param1.buffs["taunt"] && !param2.buffs["taunt"])
            {
               return -1;
            }
            if(param2.buffs["taunt"] && !param1.buffs["taunt"])
            {
               return 1;
            }
         }
         var _loc4_:int = param1.getDamage() * (1 + param1.checkTalent(1));
         var _loc3_:int = param2.getDamage() * (1 + param2.checkTalent(1));
         if(_loc4_ > _loc3_)
         {
            return -1;
         }
         if(_loc4_ < _loc3_)
         {
            return 1;
         }
         return 0;
      }

      public function clearUI() : void
      {
         clearLimitBreakEdge(m_avatarRes);
         if(m_avatarRes)
         {
            StarlingTools.removeChildrenClear(m_avatarRes);
            m_avatarRes.removeFromParent(true);
            m_avatarRes = null;
         }
      }

      public function clearRes() : void
      {
         clearLimitBreakEdge();
         var _loc1_:* = null;
         if(m_fightRange)
         {
            m_fightRange.removeFromParent(true);
            m_fightRange = null;
         }
         if(m_fightRes)
         {
            m_fightRes.removeChildren();
         }
         if(m_icon)
         {
            if(m_icon.filter)
            {
               m_icon.filter.clearCache();
               m_icon.filter.dispose();
               m_icon.filter = null;
            }
         }
         if(equips)
         {
            for each(_loc1_ in equips)
            {
               _loc1_.clear();
            }
         }
         equips = null;
         m_icon = null;
         m_buff = null;
         m_avatarRes = null;
         m_fightRes = null;
         m_fightBg = null;
         m_fightRange = null;
         m_actionNum = null;
         if(m_tf)
         {
            m_tf.removeFromParent(true);
            m_tf = null;
         }
      }

      public function clearData() : void
      {
         if(skill0)
         {
            skill0.clear();
         }
         if(skill1)
         {
            skill1.clear();
         }
         if(skill2)
         {
            skill2.clear();
         }
         if(skillB)
         {
            skillB.clear();
         }
         if(talent)
         {
            talent.clear();
         }
         clearRes();
         talent = null;
         skill0 = null;
         skill1 = null;
         skill2 = null;
         skillB = null;
         buffs = null;
      }

      public function clear() : void
      {
         this.clearUI();
         this.clearData();
      }

      public function allClear() : void
      {
         clearUI();
         clearRes();
         clearData();
      }
   }
}
