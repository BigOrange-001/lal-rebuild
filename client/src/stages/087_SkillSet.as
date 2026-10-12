package com.meng52.game.module.skill
{
   import com.meng52.game.command.skill.SkillSetData;
   import com.meng52.game.command.skill.SkillSetManager;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.module.BaseModule;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.map.GameMap;
   import com.meng52.game.module.map.GameMapConfig;
   import com.meng52.game.module.map.GameMapTools;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.map.AvatarLayer;
   import com.meng52.game.ui.map.GameMapLayer;
   import com.meng52.utils.Tools;
   
   public class SkillSet extends BaseModule
   {
      
      public static const SKILL_LV_MAX:int = 10;
      
      public var skills:Array;
      
      public var avatar:Avatar;
      
      public var lv:int;
      
      public var isSuper:Boolean;
      
      public var m_cooldownNum:int;
      private var boundedSummons:Vector.<Avatar>;
      private var pendingShieldFollowupTarget:Avatar;
      private var pendingShieldFollowupBuff:Object;
      private var pendingShieldFollowupDamage:Number = 0;
      private var pendingShieldFollowupDamageType:int = 2;
      private var pendingShieldFollowupEffect:String;
      private var pendingAreaStrike:Object;
      private var inKillRecast:Boolean = false;
      private var killRecastRemaining:int = -1;
      
      public function SkillSet(param1:String, param2:Avatar, param3:int = 1, param4:Boolean = false)
      {
         super();
         m_data = SkillSetManager.getOnlyExample().getData(param1);
         avatar = param2;
         lv = Math.max(1,param3);
         isSuper = param4;
         init();
      }
      
      public function get skillSetData() : SkillSetData
      {
         return m_data as SkillSetData;
      }
      
      public function getStar() : int
      {
         return skillSetData.id.split("_")[2];
      }
      
      public function isActive() : Boolean
      {
         return skillSetData.pl != null;
      }
      
      public function getEquipRate(param1:String) : Number
      {
         var _loc2_:Array = null;
         if(!skillSetData.pl && skills)
         {
            _loc2_ = skills[0];
            if(_loc2_[0] == "equipup")
            {
               if(_loc2_[2] == param1)
               {
                  return 1 + _loc2_[1];
               }
            }
         }
         return 1;
      }
      
      public function getEquipUpKind() : String
      {
         var _loc1_:Array = null;
         if(!skillSetData.pl && skills)
         {
            _loc1_ = skills[0];
            if(_loc1_[0] == "equipup")
            {
               return _loc1_[2];
            }
         }
         return "";
      }
      
      public function getInfo() : String
      {
         var _loc5_:Array = null;
         var _loc2_:String = null;
         var _loc1_:String = null;
         var _loc3_:String = null;
         var _loc4_:SkillSetData = skillSetData;
         if(!_loc4_.pl)
         {
            if(skills)
            {
               _loc5_ = skills[0];
               _loc2_ = _loc5_[0];
               _loc1_ = _loc5_[2];
               if(_loc2_ == "equipup")
               {
                  if(_loc1_ == "hp")
                  {
                     _loc3_ = GlobalLanguageStr.getLanguageStr(20283);
                  }
                  else if(_loc1_ == "ap")
                  {
                     _loc3_ = GlobalLanguageStr.getLanguageStr(20284);
                  }
                  else if(_loc1_ == "de_ph")
                  {
                     _loc3_ = GlobalLanguageStr.getLanguageStr(20285);
                  }
                  else if(_loc1_ == "de_ma")
                  {
                     _loc3_ = GlobalLanguageStr.getLanguageStr(20286);
                  }
                  else if(_loc1_ == "hit")
                  {
                     _loc3_ = GlobalLanguageStr.getLanguageStr(30021);
                  }
                  else if(_loc1_ == "flee")
                  {
                     _loc3_ = GlobalLanguageStr.getLanguageStr(30022);
                  }
                  else if(_loc1_ == "crit")
                  {
                     _loc3_ = GlobalLanguageStr.getLanguageStr(30023);
                  }
                  else if(_loc1_ == "tough")
                  {
                     _loc3_ = GlobalLanguageStr.getLanguageStr(30024);
                  }
                  _loc3_ = GlobalLanguageStr.getLanguageStr(30100,_loc3_,GameMapTools.toPercentage(_loc5_[1]));
               }
               else if(_loc2_ == "avenge")
               {
                  _loc3_ = GlobalLanguageStr.getLanguageStr(30101,GameMapTools.toPercentage(_loc5_[1] * GlobalData.$mConfig_simple.attack[1]));
               }
               if(_loc3_)
               {
                  return _loc3_;
               }
            }
         }
         return _loc4_.info;
      }
      
      public function getInfoDetails() : String
      {
         var _loc3_:String = null;
         var _loc4_:SkillSetData = skillSetData;
         var _loc1_:int = _loc4_.aoe;
         var _loc2_:int = Math.abs(_loc4_.range);
         _loc3_ = GlobalLanguageStr.getLanguageStr(20468,_loc4_.warmup,_loc4_.cooldown) + "\n";
         if(_loc4_.hpType > 0)
         {
            _loc3_ += GlobalLanguageStr.getLanguageStr(24030,GameMapTools.toPercentage(_loc4_.hpType)) + "\n";
         }
         else if(_loc4_.hpType < 0)
         {
            _loc3_ += GlobalLanguageStr.getLanguageStr(24031,GameMapTools.toPercentage(-_loc4_.hpType)) + "\n";
         }
         _loc3_ += getInfo() + "\n";
         if(Math.abs(_loc4_.range) > GameMapConfig.LINE_POS)
         {
            _loc3_ += GlobalLanguageStr.getLanguageStr(24011) + "\n";
         }
         else if(Math.abs(_loc4_.range) >= GameMapConfig.LINE_POS * 0.66)
         {
            _loc3_ += GlobalLanguageStr.getLanguageStr(24010) + "\n";
         }
         if(_loc1_ == GameMapConfig.MIN_SPACE_POS - 1)
         {
            _loc3_ += GlobalLanguageStr.getLanguageStr(24003,_loc2_) + "\n";
         }
         else if(_loc1_ >= 1 && _loc1_ < GameMapConfig.MIN_SPACE_POS)
         {
            _loc3_ += GlobalLanguageStr.getLanguageStr(24000,_loc1_ + 1) + "\n";
         }
         else if(_loc1_ >= GameMapConfig.MIN_SPACE_POS)
         {
            if(_loc1_ >= GameMapConfig.LINE_POS)
            {
               _loc3_ += GlobalLanguageStr.getLanguageStr(24006) + "\n";
            }
            else
            {
               _loc3_ += GlobalLanguageStr.getLanguageStr(24002,_loc1_) + "\n";
            }
         }
         else if(_loc1_ < 0)
         {
            _loc3_ += GlobalLanguageStr.getLanguageStr(24001,Math.abs(_loc1_) + 1) + "\n";
         }
         else if(_loc1_ == 0)
         {
            if(_loc2_ == 0)
            {
               _loc3_ += GlobalLanguageStr.getLanguageStr(24005) + "\n";
            }
            else
            {
               _loc3_ += GlobalLanguageStr.getLanguageStr(24004) + "\n";
            }
         }
         if(_loc4_.banStand == 0)
         {
            _loc3_ += GlobalLanguageStr.getLanguageStr(24020) + "\n";
         }
         return _loc3_ + getSkillActionInfo();
      }
      
      public function getSkillActionInfo() : String
      {
         var _loc2_:int = 0;
         var _loc6_:Array = null;
         var _loc5_:* = undefined;
         var _loc3_:String = "";
         var _loc4_:SkillSetData = skillSetData;
         var _loc1_:Object = {};
         _loc2_ = 0;
         while(_loc2_ < skills.length)
         {
            switch((_loc6_ = skills[_loc2_])[0])
            {
               case "stun":
                  _loc1_["stun"] = GlobalLanguageStr.getLanguageStr(25000);
                  break;
               case "silence":
                  _loc1_["silence"] = GlobalLanguageStr.getLanguageStr(25001);
                  break;
               case "weak":
               case "weak_percent":
                  _loc1_["weak"] = GlobalLanguageStr.getLanguageStr(25002);
                  break;
               case "sunder":
               case "sunder_percent":
                  _loc1_["sunder"] = GlobalLanguageStr.getLanguageStr(25003);
                  break;
               case "poison":
                  _loc1_["poison"] = GlobalLanguageStr.getLanguageStr(25004,GameMapTools.toPercentage(GlobalData.$mConfig_simple.attack[18]));
                  break;
               case "burn":
                  _loc1_["burn"] = GlobalLanguageStr.getLanguageStr(25005,GameMapTools.toPercentage(GlobalData.$mConfig_simple.attack[17]));
                  break;
               case "evil":
                  _loc1_["evil"] = GlobalLanguageStr.getLanguageStr(25017);
                  break;
               case "summon":
                  _loc1_["summon"] = GlobalLanguageStr.getLanguageStr(25006);
                  break;
               case "shield":
                  _loc1_["shield"] = GlobalLanguageStr.getLanguageStr(25007);
                  break;
               case "strong":
                  _loc1_["strong"] = GlobalLanguageStr.getLanguageStr(25008);
                  break;
               case "purify":
                  _loc1_["purify"] = GlobalLanguageStr.getLanguageStr(25018);
                  break;
               case "attrup":
                  _loc3_ = _loc6_[2];
                  if(_loc3_ == "hit")
                  {
                     _loc1_["hitup"] = GlobalLanguageStr.getLanguageStr(25011);
                  }
                  else if(_loc3_ == "flee")
                  {
                     _loc1_["fleeup"] = GlobalLanguageStr.getLanguageStr(25012);
                  }
                  else if(_loc3_ == "crit")
                  {
                     _loc1_["critup"] = GlobalLanguageStr.getLanguageStr(25013);
                  }
                  else if(_loc3_ == "tough")
                  {
                     _loc1_["toughup"] = GlobalLanguageStr.getLanguageStr(25014);
                  }
                  break;
               case "taunt":
                  _loc1_["taunt"] = GlobalLanguageStr.getLanguageStr(25009);
                  break;
               case "bless":
                  _loc1_["bless"] = GlobalLanguageStr.getLanguageStr(25010,GameMapTools.toPercentage(GlobalData.$mConfig_simple.attack[20]));
                  break;
               case "steel":
                  _loc1_["steel"] = GlobalLanguageStr.getLanguageStr(25019);
                  break;
               case "suck":
                  _loc1_["suck"] = GlobalLanguageStr.getLanguageStr(25020);
            }
            _loc2_++;
         }
         _loc3_ = "";
         for(_loc5_ in _loc1_)
         {
            _loc3_ += _loc1_[_loc5_] + "\n";
         }
         if(_loc3_ != "")
         {
            _loc3_ = "\n" + _loc3_;
         }
         return _loc3_;
      }
      
      public function getInfoAll() : String
      {
         var _loc1_:SkillSetData = skillSetData;
         if(isBookSkill)
         {
            if(_loc1_.pl)
            {
               return GlobalLanguageStr.getLanguageStr(20421,getInfo(),_loc1_.warmup,_loc1_.cooldown);
            }
         }
         return getInfo();
      }
      
      public function getInfoDesc() : String
      {
         var _loc1_:SkillSetData = skillSetData;
         return GlobalLanguageStr.getLanguageStr(25021,_loc1_.warmup,_loc1_.cooldown);
      }
      
      public function get isBookSkill() : Boolean
      {
         return skillSetData.id.slice(0,1) == "K";
      }
      
      public function getPassiveType() : String
      {
         var _loc2_:Array = null;
         var _loc1_:SkillSetData = skillSetData;
         if(!_loc1_.pl)
         {
            if(skills)
            {
               _loc2_ = skills[0];
               return _loc2_[0];
            }
         }
         return null;
      }
      
      public function getPassiveValue() : Number
      {
         var _loc2_:Array = null;
         var _loc1_:SkillSetData = skillSetData;
         if(!_loc1_.pl)
         {
            if(skills)
            {
               _loc2_ = skills[0];
               return _loc2_[1];
            }
         }
         return null;
      }
      
      public function get isEquipUp() : Boolean
      {
         var _loc2_:Array = null;
         var _loc1_:SkillSetData = skillSetData;
         if(!_loc1_.pl)
         {
            if(skills)
            {
               _loc2_ = skills[0];
               return _loc2_[0] == "equipup";
            }
         }
         return false;
      }
      
      public function getPower() : Number
      {
         var _loc1_:int = getStar();
         if(isBookSkill)
         {
            if(isEquipUp)
            {
               return 0;
            }
            return _loc1_ * GlobalData.$mConfig_simple.power[11] + lv * GlobalData.$mConfig_simple.power[12];
         }
         if(!isSuper)
         {
            return _loc1_ * Avatar.POWER_SKILL_0_STAR + lv * Avatar.POWER_SKILL_0_LV;
         }
         return _loc1_ * Avatar.POWER_SKILL_1_STAR;
      }
      
      public function init() : void
      {
         var _loc2_:SkillSetData = skillSetData;
         m_cooldownNum = _loc2_.warmup;
         var _loc1_:Array = _loc2_.skillUp;
         var rankUpgradePaths:Array = _loc2_.skillUpPaths;
         var rankUpgradeLevel:int = Math.max(1,Math.min(10,lv));
         if((_loc1_ || rankUpgradePaths && rankUpgradePaths.length > 0) && lv > 1)
         {
            skills = Tools.clone(skillSetData.skills);
            if(_loc1_ && _loc1_[0] is Array)
            {
               var _loc3_:int = 0;
               var _loc4_:Array = null;
               while(_loc3_ < _loc1_.length)
               {
                  _loc4_ = _loc1_[_loc3_];
                  if(_loc4_ is Array && _loc4_.length >= 3 && (_loc4_[0] is int || _loc4_[0] is Number) && (_loc4_[1] is int || _loc4_[1] is Number) && (_loc4_[2] is int || _loc4_[2] is Number))
                  {
                     if(int(_loc4_[0]) == _loc4_[0] && int(_loc4_[1]) == _loc4_[1] && _loc4_[0] >= 0 && _loc4_[0] < skills.length && skills[_loc4_[0]] is Array && _loc4_[1] >= 0 && _loc4_[1] < skills[_loc4_[0]].length && (skills[_loc4_[0]][_loc4_[1]] is int || skills[_loc4_[0]][_loc4_[1]] is Number))
                     {
                        skills[_loc4_[0]][_loc4_[1]] += _loc4_[2] * (lv - 1);
                     }
                  }
                  _loc3_++;
               }
            }
            else if(_loc1_ && _loc1_.length >= 2 && (_loc1_[0] is int || _loc1_[0] is Number) && int(_loc1_[0]) == Number(_loc1_[0]) && int(_loc1_[0]) >= 0 && int(_loc1_[0]) < skills.length && skills[int(_loc1_[0])] is Array && skills[int(_loc1_[0])].length > 1 && (skills[int(_loc1_[0])][1] is int || skills[int(_loc1_[0])][1] is Number) && (_loc1_[1] is int || _loc1_[1] is Number) && isFinite(Number(_loc1_[1])))
            {
               skills[int(_loc1_[0])][1] += _loc1_[1] * (lv - 1);
            }
            var rankPathIndex:int = 0;
            var rankPathRecord:Array = null;
            var rankPath:Array = null;
            var rankPathActionIndex:int = 0;
            var rankPathValue:* = null;
            var rankPathStep:int = 0;
            var rankPathIndexValue:Number = 0;
            var rankPathDelta:Number = 0;
            var rankPathValid:Boolean = false;
            var rankPathLeaf:* = null;
            while(rankUpgradePaths && rankPathIndex < rankUpgradePaths.length)
            {
               rankPathRecord = rankUpgradePaths[rankPathIndex] as Array;
               if(rankPathRecord && rankPathRecord.length >= 3 && (rankPathRecord[0] is int || rankPathRecord[0] is Number) && rankPathRecord[1] is Array && (rankPathRecord[2] is int || rankPathRecord[2] is Number))
               {
                  rankPathActionIndex = int(rankPathRecord[0]);
                  rankPath = rankPathRecord[1] as Array;
                  rankPathDelta = Number(rankPathRecord[2]);
                  rankPathValid = rankPathActionIndex == Number(rankPathRecord[0]) && rankPathActionIndex >= 0 && rankPathActionIndex < skills.length && skills[rankPathActionIndex] is Array && rankPath.length > 0 && isFinite(rankPathDelta);
                  rankPathValue = rankPathValid ? skills[rankPathActionIndex] : null;
                  rankPathStep = 0;
                  while(rankPathValid && rankPathStep < rankPath.length)
                  {
                     if(!(rankPath[rankPathStep] is int || rankPath[rankPathStep] is Number))
                     {
                        rankPathValid = false;
                        break;
                     }
                     rankPathIndexValue = Number(rankPath[rankPathStep]);
                     if(!isFinite(rankPathIndexValue) || Math.floor(rankPathIndexValue) != rankPathIndexValue || rankPathIndexValue < 0 || !rankPathValue || rankPathIndexValue >= rankPathValue.length)
                     {
                        rankPathValid = false;
                        break;
                     }
                     rankPathLeaf = rankPathValue[int(rankPathIndexValue)];
                     if(rankPathStep < rankPath.length - 1)
                     {
                        if(!(rankPathLeaf is Array))
                        {
                           rankPathValid = false;
                           break;
                        }
                        rankPathValue = rankPathLeaf;
                     }
                     else if(!(rankPathLeaf is int || rankPathLeaf is Number) || !isFinite(Number(rankPathLeaf)))
                     {
                        rankPathValid = false;
                     }
                     rankPathStep++;
                  }
                  if(rankPathValid && rankPathValue)
                  {
                     rankPathLeaf = rankPathValue[int(rankPath[rankPath.length - 1])];
                     rankPathValue[int(rankPath[rankPath.length - 1])] = Number(rankPathLeaf) + rankPathDelta * (rankUpgradeLevel - 1);
                  }
               }
               rankPathIndex++;
            }
         }
         else
         {
            skills = skillSetData.skills;
         }
      }
      
      public function ready() : void
      {
         if(isActive())
         {
            m_cooldownNum = skillSetData.warmup;
         }
         else
         {
            m_cooldownNum = 2147483647;
         }
      }
      
      public function cooldown() : int
      {
         m_cooldownNum = m_cooldownNum - 1;
         return m_cooldownNum;
      }
      
      private function canEvent() : Boolean
      {
         var _loc1_:* = null;
         var _loc2_:* = undefined;
         if(avatar == null)
         {
            return false;
         }
         var _loc5_:GameMap = GameMap.currentMap;
         if(_loc5_ == null)
         {
            return false;
         }
         var _loc4_:SkillSetData = skillSetData;
         var _loc3_:int = _loc4_.range;
         if(m_cooldownNum >= 0)
         {
            return false;
         }
         if(_loc4_.hpType > 0)
         {
            if(avatar.hpRate < _loc4_.hpType)
            {
               return false;
            }
         }
         else if(_loc4_.hpType < 0)
         {
            if(avatar.hpRate > -_loc4_.hpType)
            {
               return false;
            }
         }
         if(_loc3_ <= 0)
         {
            return true;
         }
         _loc2_ = GameMap.currentMap.getAliveList(avatar.otherTeam);
         if(avatar.findAim(_loc2_,null,_loc3_,_loc4_.banStand) != null)
         {
            return true;
         }
         if(canUseAllyOnlyTargetPolicy(_loc3_))
         {
            return true;
         }
         return false;
      }

      private function canUseAllyOnlyTargetPolicy(param1:int) : Boolean
      {
         var _loc1_:int = 0;
         var _loc2_:Array = null;
         var _loc3_:String = null;
         var _loc4_:Vector.<Avatar> = null;
         if(!skills || !skillSetData.actionTargetPolicies) return false;
         var _loc5_:Vector.<Avatar> = GameMap.currentMap.getAliveList(avatar.team) as Vector.<Avatar>;
         _loc1_ = 0;
         while(_loc1_ < skills.length)
         {
            _loc2_ = skills[_loc1_];
             // A skill may combine an enemy action with an independent ally
             // action. Do not reject the whole skill merely because one of
             // its other actions targets enemies; canEvent() has already
             // checked that no ordinary enemy target is currently usable.
             // Continue looking for an individually eligible ally action.
            _loc3_ = getActionPolicy(_loc1_);
            if(_loc3_ && _loc3_.indexOf("ally_") == 0)
            {
               _loc4_ = applyActionTargetPolicy(_loc5_,_loc1_);
               if(avatar.findAim(_loc4_,getActionSortFunction(_loc1_,avatar.getSortOnFun()),param1,skillSetData.banStand) != null) return true;
            }
            _loc1_++;
         }
         return false;
      }

      private function isEnemyTargetAction(param1:String) : Boolean
      {
         return param1 == "damage" || param1 == "true_damage" || param1 == "conditional_damage" || param1 == "stun_by_condition" || param1 == "damage_chain" || param1 == "locked_sequence" || param1 == "locked_sequence_area" || param1 == "locked_combo_group" || param1 == "locked_combo_weak" || param1 == "combo" || param1 == "stun" || param1 == "silence" || param1 == "weak" || param1 == "weak_percent" || param1 == "sunder" || param1 == "sunder_percent" || param1 == "poison" || param1 == "burn" || param1 == "evil" || param1 == "pull" || param1 == "push" || param1 == "push_aoe" || param1 == "move_to_target" || param1 == "shield_dispel" || param1 == "focus_fire";
      }
      
      public function checkUse() : Boolean
      {
         var _loc1_:Boolean = false;
         if(canEvent())
         {
            _loc1_ = useSkill();
            m_cooldownNum = skillSetData.cooldown;
            return _loc1_;
         }
         return _loc1_;
      }
      
      public function useSkill() : Boolean
      {
         var _loc14_:int = 0;
         var _loc21_:int = 0;
         var _loc20_:Array = null;
         var _loc1_:Avatar = null;
         var _loc13_:Avatar = null;
         var _loc3_:* = undefined;
         var _loc22_:* = undefined;
         var _loc23_:Number = NaN;
         var _loc6_:Number = NaN;
         var _loc5_:Number = NaN;
         var _loc15_:Number = NaN;
         var _loc11_:Number = NaN;
         var _loc18_:Number = NaN;
         var _loc12_:* = undefined;
         var _loc8_:int = 0;
         var summonLevel:int = 0;
         var limitedSummon:Boolean = false;
         var summonApFactor:Number = 0;
         var _loc19_:SkillSetData = skillSetData;
         var _loc24_:int = Math.abs(_loc19_.range);
         var _loc7_:int = _loc19_.aoe;
         var _loc26_:GameMap = GameMap.currentMap;
         var _loc16_:GameMapLayer = GameMapLayer.gl;
         var _loc9_:String = _loc19_.name;
         var _loc17_:Number = 16777215;
         var _loc10_:int = 40;
         var _loc2_:Boolean = _loc19_.banStand;
         var _loc25_:* = GlobalData.$mConfig_simple.attack;
         var _loc4_:Boolean = false;
         var _loc27_:String = avatar.team == 1 ? "skill0Bg" : "skill1Bg";
         var actionTargets:Array = [];
         var targetGroups:Object = {};
         var aliveEnemyBefore:int = 0;
         var recastUsed:Boolean = false;
         var priorShield:Object = null;
         var appliedShield:Object = null;
         var killContext:Object = null;
         var actionKillContexts:Array = [];
         var actionDamageCapture:Object = null;
         var actionDamageTotals:Array = [];
         var preCastDotTargets:Vector.<Avatar> = new Vector.<Avatar>();
         var preCastBurnTargets:Vector.<Avatar> = new Vector.<Avatar>();
         var snapshotTargets:Vector.<Avatar> = null;
         var snapshotIndex:int = 0;
         if(isSuper)
         {
            _loc10_ = 44;
         }
         snapshotTargets = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
         snapshotIndex = 0;
         while(snapshotTargets && snapshotIndex < snapshotTargets.length)
         {
            _loc1_ = snapshotTargets[snapshotIndex];
               if(_loc1_ && _loc1_.hp > 0)
               {
                  if(_loc1_.hasManualDamageOverTime()) preCastDotTargets.push(_loc1_);
               if(_loc1_.buffs["burn"] || _loc1_.hasManualDotKind("burn")) preCastBurnTargets.push(_loc1_);
            }
            snapshotIndex++;
         }
         GameMap.actionDelay += 0.5 / 2;
         _loc16_.delayCall((avatar.fightRes.parent as AvatarLayer).setFirst,GameMap.actionDelay,avatar.fightRes);
         if(avatar && avatar.avatarData.actionType != 3)
         {
            _loc16_.delayCall(avatar.resSwing,GameMap.actionDelay,0.12,0.12 * 3);
         }
         if(!isSuper)
         {
            _loc9_ += GlobalLanguageStr.getStr(30003) + lv;
            _loc12_ = DisplayTools.getAttrs("SKILL0_PRE_EFF");
            _loc12_.a1 = avatar;
            _loc12_.par = _loc16_.effectLayer;
            _loc16_.delayCall(DisplayTools.addEffects,GameMap.actionDelay,_loc12_);
            GameMap.actionDelay += 0.05;
            _loc16_.delayCall(_loc16_.infoLayer.popTextForAvatar,GameMap.actionDelay,_loc9_,avatar,_loc17_,_loc10_,2,_loc27_);
         }
         else
         {
            _loc12_ = DisplayTools.getAttrs("SKILL1_PRE_EFF");
            _loc12_.a1 = avatar;
            _loc12_.par = _loc16_.effectLayer;
            _loc16_.delayCall(DisplayTools.addEffects,GameMap.actionDelay,_loc12_);
            GameMap.actionDelay += 0.05;
            _loc16_.delayCall(_loc16_.infoLayer.showSkill,GameMap.actionDelay,_loc9_,avatar,_loc27_);
            GameMap.actionDelay += 2;
         }
         GameMap.actionDelay += 0.5 / 2;
         _loc14_ = 0;
         while(_loc14_ < skills.length)
         {
            _loc20_ = skills[_loc14_];
            if(GameMap.currentMap.isEnd(avatar.line))
            {
               return _loc4_;
            }
            avatar.getTeamHp();
            killContext = null;
            if(isDirectDamageAction(String(_loc20_[0])) && (isSuper && skillSetData.recastNormalOnceOnKill || hasRecastForAction(_loc14_) || hasBattleStackForAction(_loc14_)))
            {
               killContext = {"hit":false,"hitHero":false,"killed":false,"killedTarget":null,"killedType":0,"killedSummon":false};
               avatar.currentSkillKillContext = killContext;
            }
            actionDamageCapture = null;
            if(isDirectDamageAction(String(_loc20_[0])))
            {
               actionDamageCapture = {"active":true,"owner":avatar,"actionIndex":_loc14_,"total":0};
               avatar.manualSkillDamageCapture = actionDamageCapture;
            }
            switch(_loc20_[0])
            {
               case "damage":
                  _loc3_ = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                  _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                   var directDamageCoeff:Number = Number(_loc20_[1]);
                   var directDamageTarget:Avatar = _loc3_.length > 0 ? _loc3_[0] : null;
                   var directDamageShareTotal:Number = damageShareTotal(_loc14_,directDamageCoeff,directDamageTarget,preCastDotTargets,preCastBurnTargets);
                   var directDamageShareQ:Number = damageShareWeight(directDamageCoeff,directDamageShareTotal);
                   _loc1_ = avatar.checkAttack(_loc3_,isSuper && _loc19_.targetPolicy == "lowest_current_hp" ? sortOnLowestCurrentHp : getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_,_loc20_[2],directDamageShareTotal,getActionAoeIndex(_loc14_,_loc7_,_loc3_),_loc20_[_loc20_.length - 1],null,directDamageShareQ);
                  if(_loc1_) actionTargets[_loc14_] = _loc1_;
                  break;
               case "hp_shield":
                  if(_loc20_.length >= 4 && _loc20_[1] > 0 && _loc20_[2] > 0)
                  {
                     avatar.addBuff("shield",_loc20_[2],int(avatar.getHpMax() * _loc20_[1]));
                     if(_loc20_[3])
                     {
                        queueDirectActionEffect(String(_loc20_[3]),avatar);
                     }
                     GameMap.actionDelay += 0.5;
                  }
                  break;
               case "manual_dot":
                  _loc3_ = getCustomActionTargets(_loc14_,actionTargets,targetGroups,false);
                  if(_loc3_.length > 0 && _loc20_.length >= 6)
                  {
                     var manualDotDamageType:int = _loc20_.length >= 8 ? int(_loc20_[5]) : 0;
                     var manualDotRefreshKey:String = _loc20_.length >= 8 && String(_loc20_[6]).length > 0 ? String(_loc20_[6]) : (_loc20_.length == 7 && String(_loc20_[5]).length > 0 ? String(_loc20_[5]) : String(skillSetData.id) + ":" + _loc14_);
                     var manualDotEffect:String = String(_loc20_[_loc20_.length - 1]);
                     var dotIndex:int = 0;
                     while(dotIndex < _loc3_.length)
                     {
                        _loc3_[dotIndex].addManualSkillDot(String(avatar.id) + ":" + manualDotRefreshKey,String(_loc20_[1]),Number(_loc20_[2]) * avatar.getDamage(),Number(_loc20_[3]),int(_loc20_[4]),avatar,manualDotDamageType);
                        dotIndex++;
                     }
                     queueDirectActionEffect(manualDotEffect,_loc3_[0],"b");
                     actionTargets[_loc14_] = _loc3_[0];
                  }
                  break;
               case "move_self":
                  if(_loc20_.length >= 3 && isFinite(Number(_loc20_[1])) && Number(_loc20_[1]) != 0)
                  {
                     // Native param1=true advances toward enemies; false
                     // retreats toward allies for either team. checkMove
                     // applies getFinalPos clamping and animation timing.
                     // This action never depends on an enemy target list.
                     avatar.checkMove(Number(_loc20_[1]) < 0,int(Math.abs(Number(_loc20_[1]))),null,-1,false,String(_loc20_[2]));
                  }
                  break;
               case "conditional_damage":
                  _loc3_ = getCustomActionTargets(_loc14_,actionTargets,targetGroups,false);
                  if(_loc3_.length > 0 && _loc20_.length >= 6)
                  {
                     var conditionalIndex:int = 0;
                     while(conditionalIndex < _loc3_.length)
                     {
                        _loc13_ = _loc3_[conditionalIndex];
                        _loc23_ = Number(_loc20_[1]);
                        if(conditionMatches(String(_loc20_[3]),_loc13_,preCastDotTargets,preCastBurnTargets)) _loc23_ += Number(_loc20_[4]);
                        var conditionalOne:Vector.<Avatar> = new Vector.<Avatar>();
                        conditionalOne.push(_loc13_);
                         if(int(_loc20_[2]) == 3) _loc23_ /= Avatar.REAL_DAMAGE_RATE;
                         var conditionalShareTotal:Number = damageShareTotal(_loc14_,_loc23_,_loc13_,preCastDotTargets,preCastBurnTargets);
                         var conditionalShareQ:Number = damageShareWeight(_loc23_,conditionalShareTotal);
                         if(avatar.checkAttack(conditionalOne,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_,int(_loc20_[2]),conditionalShareTotal,0,String(_loc20_[5]),null,conditionalShareQ)) actionTargets[_loc14_] = _loc13_;
                        conditionalIndex++;
                     }
                  }
                  break;
               case "damage_chain":
                  if(_loc20_.length >= 12 && _loc20_[2] is Array)
                  {
                     var chainCoefficients:Array = _loc20_[2] as Array;
                     var chainDamageType:int = int(_loc20_[3]);
                     var chainRadius:int = Math.max(0,int(_loc20_[4]));
                     var chainVictimCap:int = Math.max(1,int(_loc20_[5]));
                     var chainPolicy:String = String(_loc20_[6]);
                     var chainPrimaryBonus:Number = Number(_loc20_[7]);
                     var chainBurnCondition:String = String(_loc20_[8]);
                     var chainBurnBonus:Number = Number(_loc20_[9]);
                     var chainRepeatPrimary:Boolean = Boolean(_loc20_[10]);
                     var chainTargets:Vector.<Avatar> = getCustomActionTargets(_loc14_,actionTargets,targetGroups,false);
                     var chainPrimary:Avatar = chainTargets.length > 0 ? chainTargets[0] : null;
                     var chainPrevious:Avatar = chainPrimary;
                      var chainVictimTargets:Vector.<Avatar> = new Vector.<Avatar>();
                      var chainVictimCounts:Array = [];
                     var chainHit:int = 0;
                     var chainTarget:Avatar = null;
                     var chainCoeff:Number = NaN;
                     var chainWasPrimaryKilled:Boolean = false;
                     var chainDamageGroupTarget:Avatar = null;
                     var chainDamageGroupTotal:Number = 0;
                     var chainAlternatives:Vector.<Avatar> = null;
                     var chainCandidateIndex:int = 0;
                     var chainCandidate:Avatar = null;
                     var chainVictimKey:String = null;
                     var chainSort:Function = function(param1:Avatar,param2:Avatar):int
                     {
                        var distance1:int = Math.abs(param1.pos - chainPrevious.pos);
                        var distance2:int = Math.abs(param2.pos - chainPrevious.pos);
                        if(distance1 < distance2) return -1;
                        if(distance1 > distance2) return 1;
                        return param1.id < param2.id ? -1 : (param1.id > param2.id ? 1 : 0);
                     };
                     if(chainPrimary && chainCoefficients.length > 0 && chainDamageType >= 0 && chainDamageType <= 3)
                     {
                        while(chainHit < int(_loc20_[1]))
                        {
                           chainTarget = null;
                           if(chainHit == 0)
                           {
                              chainTarget = chainPrimary;
                           }
                           else if(chainPolicy == "enemy_lane_nearest_neighbor" || chainPolicy == "enemy_lane_behind_primary")
                           {
                              chainAlternatives = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                              chainAlternatives = applyActionTargetPolicy(chainAlternatives,_loc14_);
                              chainAlternatives = avatar.findAimList(chainAlternatives,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_);
                              if(chainAlternatives.length > 1)
                              {
                                 chainAlternatives = Tools.sortVector(chainAlternatives,chainSort);
                              }
                              chainCandidateIndex = 0;
                              while(chainAlternatives && chainCandidateIndex < chainAlternatives.length)
                              {
                                 chainCandidate = chainAlternatives[chainCandidateIndex];
                                  var chainCandidateIndexInPlan:int = chainCandidate ? chainVictimTargets.indexOf(chainCandidate) : -1;
                                  var chainCandidateVisits:int = chainCandidateIndexInPlan >= 0 ? int(chainVictimCounts[chainCandidateIndexInPlan]) : 0;
                                  if(chainCandidate && chainCandidate != chainPrevious && chainCandidate.line == chainPrimary.line && chainCandidate.hp > 0 && Math.abs(chainCandidate.pos - chainPrevious.pos) <= chainRadius && (chainPolicy != "enemy_lane_behind_primary" || (avatar.team == 1 ? chainCandidate.pos > chainPrimary.pos : chainCandidate.pos < chainPrimary.pos)) && chainCandidateVisits < chainVictimCap)
                                 {
                                    chainTarget = chainCandidate;
                                    break;
                                 }
                                 chainCandidateIndex++;
                              }
                               var chainPrimaryPlanIndex:int = chainVictimTargets.indexOf(chainPrimary);
                               var chainPrimaryVisits:int = chainPrimaryPlanIndex >= 0 ? int(chainVictimCounts[chainPrimaryPlanIndex]) : 0;
                               if(!chainTarget && chainRepeatPrimary && chainPrimary.hp > 0 && chainPrimaryVisits < chainVictimCap)
                              {
                                 chainTarget = chainPrimary;
                              }
                           }
                           if(!chainTarget || chainTarget.hp <= 0) break;
                           chainCoeff = Number(chainCoefficients[chainHit]);
                           if(!isFinite(chainCoeff) || chainCoeff < 0) break;
                           if(chainHit == 1 && chainWasPrimaryKilled) chainCoeff += chainPrimaryBonus;
                           if(chainBurnCondition == "prehit_burn" && (chainTarget.hasManualDotKind("burn") || chainTarget.buffs && chainTarget.buffs["burn"]))
                           {
                              chainCoeff += chainBurnBonus;
                           }
                           else if(chainBurnCondition == "prehit_bleed" && chainTarget.hasManualDotKind("bleed"))
                           {
                              chainCoeff += chainBurnBonus;
                           }
                            var chainOne:Vector.<Avatar> = new Vector.<Avatar>();
                           chainOne.push(chainTarget);
                           var chainHpBefore:int = chainTarget.hp;
                           if(chainDamageType == 3) chainCoeff /= Avatar.REAL_DAMAGE_RATE;
                            var chainShareTotal:Number = chainCoeff;
                            var chainTargetPlanIndex:int = chainVictimTargets.indexOf(chainTarget);
                            if((chainDamageType == 1 || chainDamageType == 2) && chainTarget === chainDamageGroupTarget)
                            {
                               chainShareTotal = chainDamageGroupTotal;
                            }
                            else
                            {
                               if(chainRepeatPrimary && chainTarget == chainPrimary && chainTarget.hp > 0 && (chainDamageType == 1 || chainDamageType == 2))
                               {
                                  var chainNextAlternatives:Vector.<Avatar> = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                                  chainNextAlternatives = applyActionTargetPolicy(chainNextAlternatives,_loc14_);
                                  chainNextAlternatives = avatar.findAimList(chainNextAlternatives,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_);
                                  var chainHasNextTarget:Boolean = false;
                                  var chainAlternativeIndex:int = 0;
                                  while(chainAlternativeIndex < chainNextAlternatives.length)
                                  {
                                     var chainNextCandidate:Avatar = chainNextAlternatives[chainAlternativeIndex];
                                     var chainNextPlanIndex:int = chainVictimTargets.indexOf(chainNextCandidate);
                                     var chainNextVisits:int = chainNextPlanIndex >= 0 ? int(chainVictimCounts[chainNextPlanIndex]) : 0;
                                     if(chainNextCandidate && chainNextCandidate !== chainTarget && chainNextCandidate.hp > 0 && chainNextCandidate.line == chainTarget.line && Math.abs(chainNextCandidate.pos - chainTarget.pos) <= chainRadius && (chainPolicy != "enemy_lane_behind_primary" || (avatar.team == 1 ? chainNextCandidate.pos > chainPrimary.pos : chainNextCandidate.pos < chainPrimary.pos)) && chainNextVisits < chainVictimCap)
                                     {
                                        chainHasNextTarget = true;
                                        break;
                                     }
                                     chainAlternativeIndex++;
                                  }
                                  if(!chainHasNextTarget)
                                  {
                                     var chainRepeatCount:int = Math.min(int(_loc20_[1]) - chainHit,Math.max(0,chainVictimCap - (chainTargetPlanIndex >= 0 ? int(chainVictimCounts[chainTargetPlanIndex]) : 0)));
                                     var chainFutureIndex:int = chainHit + 1;
                                     while(chainFutureIndex < chainHit + chainRepeatCount && chainFutureIndex < chainCoefficients.length)
                                     {
                                        var chainFutureCoeff:Number = Number(chainCoefficients[chainFutureIndex]);
                                        if(isFinite(chainFutureCoeff) && chainFutureCoeff >= 0)
                                        {
                                           if(chainBurnCondition == "prehit_burn" && (chainTarget.hasManualDotKind("burn") || chainTarget.buffs && chainTarget.buffs["burn"])) chainFutureCoeff += chainBurnBonus;
                                           else if(chainBurnCondition == "prehit_bleed" && chainTarget.hasManualDotKind("bleed")) chainFutureCoeff += chainBurnBonus;
                                           chainShareTotal += chainFutureCoeff;
                                        }
                                        chainFutureIndex++;
                                     }
                                  }
                               }
                               chainDamageGroupTarget = chainTarget;
                               chainDamageGroupTotal = chainShareTotal;
                            }
                            avatar.attackAimList(chainOne,chainDamageType,chainShareTotal,0,String(_loc20_[11]),_loc2_,null,_loc24_,damageShareWeight(chainCoeff,chainShareTotal));
                            chainTargetPlanIndex = chainVictimTargets.indexOf(chainTarget);
                            if(chainTargetPlanIndex < 0)
                            {
                               chainVictimTargets.push(chainTarget);
                               chainVictimCounts.push(0);
                               chainTargetPlanIndex = chainVictimTargets.length - 1;
                            }
                            chainVictimCounts[chainTargetPlanIndex] = int(chainVictimCounts[chainTargetPlanIndex]) + 1;
                           if(chainHit == 0) chainWasPrimaryKilled = chainHpBefore > 0 && chainTarget.hp <= 0;
                           chainPrevious = chainTarget;
                           chainHit++;
                           GameMap.actionDelay += 0.12;
                           if(GameMap.currentMap.isEnd(avatar.line)) break;
                        }
                        actionTargets[_loc14_] = chainPrimary;
                     }
                  }
                  break;
               case "stun_by_condition":
                  _loc3_ = getCustomActionTargets(_loc14_,actionTargets,targetGroups,false);
                  if(_loc3_.length > 0 && _loc20_.length >= 7)
                  {
                     var stunConditionIndex:int = 0;
                     while(stunConditionIndex < _loc3_.length)
                     {
                        _loc13_ = _loc3_[stunConditionIndex];
                        var stunRounds:int = int(_loc20_[3]);
                        if(conditionMatches(String(_loc20_[4]),_loc13_,preCastDotTargets,preCastBurnTargets)) stunRounds += int(_loc20_[5]);
                        var stunOne:Vector.<Avatar> = new Vector.<Avatar>();
                        stunOne.push(_loc13_);
                        var stunShareTotal:Number = damageShareTotal(_loc14_,Number(_loc20_[1]),_loc13_,preCastDotTargets,preCastBurnTargets);
                        avatar.checkAttack(stunOne,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_,int(_loc20_[2]),stunShareTotal,0,String(_loc20_[6]),new Buff("stun",stunRounds,0),damageShareWeight(Number(_loc20_[1]),stunShareTotal));
                        stunConditionIndex++;
                     }
                  }
                  break;
               case "shield_composite":
                  _loc3_ = getCustomActionTargets(_loc14_,actionTargets,targetGroups,true);
                  if(_loc3_.length > 0 && _loc20_.length >= 5)
                  {
                     var compositeEffectiveAP:Number = Tools.toInt(avatar.getDamage() * (1 + avatar.checkTalent(1))) + avatar.getHpMax() * 0.1;
                     var compositeShield:int = int(Number(_loc20_[1]) * compositeEffectiveAP + Number(_loc20_[2]) * (avatar.getDePh() + avatar.getDeMa()));
                     avatar.attackAimList(_loc3_,5,0,getActionAoeIndex(_loc14_,_loc7_,_loc3_),String(_loc20_[4]),_loc2_,new Buff("shield",int(_loc20_[3]),Math.max(1,compositeShield)),_loc24_);
                  }
                  break;
               case "focus_fire":
                  _loc3_ = getCustomActionTargets(_loc14_,actionTargets,targetGroups,false);
                  if(_loc3_.length > 0 && _loc20_.length >= 2)
                  {
                     var focusTarget:Avatar = _loc3_[0];
                     var focusAllies:Vector.<Avatar> = _loc26_.getAliveList(avatar.team) as Vector.<Avatar>;
                     var focusIndex:int = 0;
                     var focusAttackCount:int = 0;
                     var focusAttacker:Avatar = null;
                     var focusOneTarget:Vector.<Avatar> = null;
                     while(focusAllies && focusIndex < focusAllies.length)
                     {
                        focusAttacker = focusAllies[focusIndex];
                        if(focusTarget.hp <= 0 || _loc26_.isEnd(avatar.line))
                        {
                           break;
                        }
                        if(focusAttacker && focusAttacker.hp > 0 && focusAttacker.line == focusTarget.line && Math.abs(focusAttacker.pos - focusTarget.pos) <= focusAttacker.getRange())
                        {
                           focusOneTarget = new Vector.<Avatar>();
                           focusOneTarget.push(focusTarget);
                           if(focusAttacker.attackAimList(focusOneTarget,-1,1,0,null,false,null,-1,1) > 0) focusAttackCount++;
                        }
                        focusIndex++;
                     }
                     actionTargets[_loc14_] = focusTarget;
                     queueDirectActionEffect(String(_loc20_[_loc20_.length - 1]),focusTarget,"b");
                     GameMap.actionDelay += 0.15 * focusAttackCount;
                  }
                  break;
               case "back":
                  _loc3_ = getCustomActionTargets(_loc14_,actionTargets,targetGroups,true);
                  if(_loc3_.length > 0 && _loc20_.length >= 4 && Number(_loc20_[1]) > 0 && int(_loc20_[2]) > 0)
                  {
                     var backTargetIndex:int = 0;
                     var backTarget:Avatar = null;
                     while(backTargetIndex < _loc3_.length)
                     {
                        backTarget = _loc3_[backTargetIndex];
                        if(backTarget && backTarget.hp > 0)
                        {
                           backTarget.addBuff("back",int(_loc20_[2]),Number(_loc20_[1]));
                           queueDirectActionEffect(String(_loc20_[3]),backTarget);
                        }
                        backTargetIndex++;
                     }
                     GameMap.actionDelay += 0.15 * _loc3_.length;
                  }
                  break;
               case "stat_flat":
                  if(_loc20_.length >= 5 && (_loc20_[1] == "hit" || _loc20_[1] == "flee" || _loc20_[1] == "crit" || _loc20_[1] == "tough") && isFinite(Number(_loc20_[2])) && Number(_loc20_[2]) > 0 && Number(_loc20_[2]) <= 100000 && int(_loc20_[3]) >= 1 && int(_loc20_[3]) <= 20)
                  {
                     var flatTargets:Vector.<Avatar> = getCustomActionTargets(_loc14_,actionTargets,targetGroups,true);
                     var flatBuffType:String = String(_loc20_[1]) + "up";
                     var flatTargetIndex:int = 0;
                     var flatTarget:Avatar = null;
                     while(flatTargets && flatTargetIndex < flatTargets.length)
                     {
                        flatTarget = flatTargets[flatTargetIndex];
                        if(flatTarget && flatTarget.hp > 0)
                        {
                           flatTarget.addBuff(flatBuffType,int(_loc20_[3]),Number(_loc20_[2]));
                           queueDirectActionEffect(String(_loc20_[4]),flatTarget);
                        }
                        flatTargetIndex++;
                     }
                     GameMap.actionDelay += 0.15 * flatTargetIndex;
                  }
                  break;
               case "heal_missing_hp":
                  if(_loc20_.length >= 3 && isFinite(Number(_loc20_[1])) && Number(_loc20_[1]) > 0 && Number(_loc20_[1]) <= 1)
                  {
                     var missingHealTargets:Vector.<Avatar> = getCustomActionTargets(_loc14_,actionTargets,targetGroups,true);
                     var missingHealIndex:int = 0;
                     var missingHealTarget:Avatar = null;
                     var missingHealAmount:int = 0;
                     while(missingHealTargets && missingHealIndex < missingHealTargets.length)
                     {
                        missingHealTarget = missingHealTargets[missingHealIndex];
                        if(missingHealTarget && missingHealTarget.hp > 0)
                        {
                           missingHealAmount = Math.max(0,Math.min(missingHealTarget.hpMax - missingHealTarget.hp,int((missingHealTarget.hpMax - missingHealTarget.hp) * Number(_loc20_[1]))));
                           if(missingHealAmount > 0)
                           {
                              missingHealTarget.injured(missingHealAmount,1,DisplayTools.getAttrs(String(_loc20_[2])),4,avatar, false, avatar);
                           }
                        }
                        missingHealIndex++;
                     }
                     GameMap.actionDelay += 0.15 * missingHealIndex;
                  }
                  break;
               case "heal_damage_sum":
                  if(_loc20_.length >= 4 && _loc20_[2] is Array && isFinite(Number(_loc20_[1])) && Number(_loc20_[1]) > 0 && Number(_loc20_[1]) <= 1)
                  {
                     var dealtHealTotal:Number = 0;
                     var dealtSourceIndexes:Array = _loc20_[2] as Array;
                     var dealtSourceSeen:Object = {};
                     var dealtSourcePosition:int = 0;
                     var dealtSourceIndex:int = -1;
                     while(dealtSourcePosition < dealtSourceIndexes.length)
                     {
                        dealtSourceIndex = int(dealtSourceIndexes[dealtSourcePosition]);
                        if((dealtSourceIndexes[dealtSourcePosition] is int || dealtSourceIndexes[dealtSourcePosition] is Number) && dealtSourceIndex == Number(dealtSourceIndexes[dealtSourcePosition]) && dealtSourceIndex >= 0 && dealtSourceIndex < _loc14_ && !dealtSourceSeen[dealtSourceIndex])
                        {
                           dealtSourceSeen[dealtSourceIndex] = true;
                           dealtHealTotal += Number(actionDamageTotals[dealtSourceIndex]);
                        }
                        dealtSourcePosition++;
                     }
                     var dealtHealTargets:Vector.<Avatar> = getCustomActionTargets(_loc14_,actionTargets,targetGroups,true);
                     var dealtHealIndex:int = 0;
                     var dealtHealTarget:Avatar = null;
                     var dealtHealAmount:int = 0;
                     while(dealtHealTargets && dealtHealIndex < dealtHealTargets.length)
                     {
                        dealtHealTarget = dealtHealTargets[dealtHealIndex];
                        if(dealtHealTarget && dealtHealTarget.hp > 0 && dealtHealTotal > 0)
                        {
                           dealtHealAmount = Math.max(0,Math.min(dealtHealTarget.hpMax - dealtHealTarget.hp,int(dealtHealTotal * Number(_loc20_[1]) * getActiveRecoveryMultiplier())));
                           if(dealtHealAmount > 0)
                           {
                              dealtHealTarget.injured(dealtHealAmount,1,DisplayTools.getAttrs(String(_loc20_[3])),4,avatar, false, avatar);
                           }
                        }
                        dealtHealIndex++;
                     }
                     GameMap.actionDelay += 0.15 * dealtHealIndex;
                  }
                  break;
               case "battle_stack":
                  if(_loc20_.length >= 7)
                  {
                     var stackSource:Object = int(_loc20_[4]) >= 0 && int(_loc20_[4]) < actionKillContexts.length ? actionKillContexts[int(_loc20_[4])] : null;
                     var stackCondition:String = String(_loc20_[5]);
                     if(stackSource && stackSource.hit && (stackCondition == "any_hit" || stackCondition == "hero_hit" && stackSource.hitHero))
                     {
                        avatar.addManualBattleStack(String(_loc20_[1]),Number(_loc20_[2]),int(_loc20_[3]));
                        queueDirectActionEffect(String(_loc20_[6]),avatar);
                     }
                  }
                  break;
               case "lethal_floor":
                  if(_loc20_.length >= 5 && Number(_loc20_[1]) >= 1 && int(_loc20_[2]) > 0)
                  {
                     avatar.manualLethalFloor[skillSetData.id] = {"minHp":int(_loc20_[1]),"rounds":int(_loc20_[2]),"expiryHeal":Number(_loc20_[3]) * avatar.getDamage(),"effect":String(_loc20_[4]),"justApplied":true};
                     queueDirectActionEffect(String(_loc20_[4]),avatar);
                  }
                  break;
               case "move_to_target_lane":
                  _loc3_ = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                  _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_,String(_loc20_[1])),_loc14_,actionTargets,targetGroups);
                  _loc3_ = avatar.findAimList(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun(),String(_loc20_[1])),GameMapConfig.LINE_POS + 1,_loc2_);
                  if(_loc3_.length > 0 && _loc20_.length >= 5)
                  {
                     _loc1_ = _loc3_[0];
                     actionTargets[_loc14_] = _loc1_;
                     var laneOffset:int = int(_loc20_[2]);
                     var friendlyOffset:int = int(_loc20_[3]);
                     var requestedFriendlyPos:int = _loc1_.pos + (avatar.team == 1 ? -friendlyOffset : friendlyOffset);
                     requestedFriendlyPos = _loc26_.getFinalPos(avatar.team,_loc1_.line,requestedFriendlyPos);
                     avatar.reline(_loc1_.line,requestedFriendlyPos,laneOffset,GameMap.actionDelay,0);
                     queueDirectActionEffect(String(_loc20_[4]),avatar);
                     GameMap.actionDelay += 0.2;
                  }
                  break;
               case "pending_area_strike":
                  var pendingSourceIndex:int = int(_loc20_[1]);
                  if(_loc20_.length >= 8 && pendingSourceIndex >= 0 && pendingSourceIndex < actionTargets.length && actionTargets[pendingSourceIndex] is Avatar && Number(_loc20_[2]) >= 0 && Number(_loc20_[4]) > 0 && int(_loc20_[5]) > 0 && int(_loc20_[6]) == 1)
                  {
                     var pendingOrigin:Avatar = actionTargets[pendingSourceIndex] as Avatar;
                     pendingAreaStrike = {"target":pendingOrigin,"line":pendingOrigin.line,"pos":pendingOrigin.pos,"coeff":Number(_loc20_[2]),"type":int(_loc20_[3]),"radius":int(_loc20_[4]),"maxTargets":int(_loc20_[5]),"rounds":int(_loc20_[6]),"effect":String(_loc20_[7])};
                  }
                  break;
               case "recast_on_kill":
                  var sourceKill:Object = int(_loc20_[1]) >= 0 && int(_loc20_[1]) < actionKillContexts.length ? actionKillContexts[int(_loc20_[1])] : null;
                  var recastLimit:int = Math.min(2,Math.max(0,int(_loc20_[2])));
                  var ownsKillRecastBudget:Boolean = killRecastRemaining < 0;
                  if(ownsKillRecastBudget) killRecastRemaining = recastLimit;
                  if(sourceKill && sourceKill.killed && sourceKill.killedTarget && (int(_loc20_[3]) == 0 || sourceKill.killedType == 1) && (int(_loc20_[4]) == 0 || !sourceKill.killedSummon) && killRecastRemaining > 0)
                  {
                     killRecastRemaining--;
                     this.useSkill();
                     m_cooldownNum = skillSetData.cooldown;
                     recastUsed = true;
                  }
                  if(ownsKillRecastBudget) killRecastRemaining = -1;
                  break;
               case "true_damage":
                  _loc3_ = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                  _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                  _loc1_ = avatar.checkAttack(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_,3,Number(_loc20_[1]) / Avatar.REAL_DAMAGE_RATE,getActionAoeIndex(_loc14_,_loc7_,_loc3_),_loc20_[_loc20_.length - 1]);
                  if(_loc1_) actionTargets[_loc14_] = _loc1_;
                  break;
               case "locked_sequence":
                  if(_loc20_.length >= 5 + int(_loc20_[1]) && int(_loc20_[1]) > 0)
                  {
                     _loc21_ = int(_loc20_[1]);
                     _loc3_ = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                  _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                     _loc3_ = avatar.findAimList(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_);
                     if(_loc3_.length > 0)
                     {
                        _loc1_ = _loc3_[0];
                        actionTargets[_loc14_] = _loc1_;
                        _loc23_ = 0;
                        _loc11_ = Number(_loc20_[2 + int(_loc20_[1])]);
                        _loc5_ = Number(_loc20_[3 + int(_loc20_[1])]);
                        _loc9_ = String(_loc20_[4 + int(_loc20_[1])]);
                        var hitIndex:int = 0;
                        while(hitIndex < _loc21_ && _loc1_.hp > 0)
                        {
                           _loc3_ = new Vector.<Avatar>();
                           _loc3_.push(_loc1_);
                            var sequenceHitCoeff:Number = Number(_loc20_[2 + hitIndex]);
                            var sequenceShareTotal:Number = damageShareTotal(_loc14_,sequenceHitCoeff,_loc1_,preCastDotTargets,preCastBurnTargets);
                            _loc23_ += avatar.attackAimList(_loc3_,int(_loc11_),sequenceShareTotal,0,_loc9_,_loc2_,null,_loc24_,damageShareWeight(sequenceHitCoeff,sequenceShareTotal));
                           hitIndex++;
                           GameMap.actionDelay += 0.15;
                        }
                        if(_loc5_ > 0 && _loc23_ > 0)
                        {
                           avatar.injured(int(Number(actionDamageCapture ? actionDamageCapture.total : _loc23_) * _loc5_ * getActiveRecoveryMultiplier()),1,DisplayTools.getAttrs(_loc9_),4);
                        }
                     }
                  }
                  break;
               case "locked_sequence_area":
                  if(_loc20_.length >= 7 + int(_loc20_[1]) && int(_loc20_[1]) > 0)
                  {
                     var areaHitCount:int = int(_loc20_[1]);
                     var areaTargetCap:int = int(_loc20_[5 + areaHitCount]);
                     var areaCapConfig:Array = skillSetData.actionTargetMaxTargets;
                     var areaConfiguredCap:Number = NaN;
                     var areaGroupName:String = null;
                     var areaGroupConfig:Array = skillSetData.actionTargetGroups;
                     _loc3_ = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                     _loc3_ = applyAreaActionTargetCandidates(_loc3_,_loc14_,actionTargets,targetGroups);
                     _loc3_ = avatar.findAimList(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_);
                     if(areaCapConfig && _loc14_ >= 0 && _loc14_ < areaCapConfig.length && areaCapConfig[_loc14_] !== null && areaCapConfig[_loc14_] !== undefined)
                     {
                        if(typeof areaCapConfig[_loc14_] != "number" || !isFinite(Number(areaCapConfig[_loc14_])) || Math.floor(Number(areaCapConfig[_loc14_])) != Number(areaCapConfig[_loc14_]))
                        {
                           areaTargetCap = 0;
                        }
                        else
                        {
                           areaConfiguredCap = Number(areaCapConfig[_loc14_]);
                           if(areaConfiguredCap == -1)
                           {
                              // Keep the action's explicit native area cap.
                           }
                           else if(areaConfiguredCap >= 1)
                           {
                              areaTargetCap = Math.min(areaTargetCap,int(areaConfiguredCap));
                           }
                           else
                           {
                              areaTargetCap = 0;
                           }
                        }
                     }
                     if(_loc3_.length > 0)
                     {
                        _loc1_ = _loc3_[0];
                        var areaTargets:Vector.<Avatar> = new Vector.<Avatar>();
                        var areaSelection:Vector.<Avatar> = _loc3_.concat();
                        var areaAll:Vector.<Avatar> = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                        var areaIndex:int = 0;
                        var areaRadius:Number = Math.max(0,Number(_loc20_[4 + areaHitCount]));
                        while(areaIndex < areaAll.length)
                        {
                           _loc13_ = areaAll[areaIndex];
                           if(_loc13_ && areaSelection.indexOf(_loc13_) >= 0 && _loc13_.hp > 0 && _loc13_.line == _loc1_.line && Math.abs(_loc13_.pos - _loc1_.pos) <= areaRadius && Math.abs(_loc13_.pos - avatar.pos) <= _loc24_)
                           {
                              areaTargets.push(_loc13_);
                           }
                           areaIndex++;
                        }
                        if(areaTargets.indexOf(_loc1_) < 0) areaTargets.unshift(_loc1_);
                        if(areaTargets.length > 1) areaTargets = Tools.sortVector(areaTargets,getActionSortFunction(_loc14_,avatar.getSortOnFun()));
                        if(areaTargets.indexOf(_loc1_) > 0)
                        {
                           areaTargets.splice(areaTargets.indexOf(_loc1_),1);
                           areaTargets.unshift(_loc1_);
                        }
                        while(areaTargets.length > areaTargetCap) areaTargets.pop();
                        if(areaTargetCap < 1 || areaTargets.length == 0)
                        {
                           GameMapTools.gameTrace("范围技能目标数量配置无效",skillSetData.id,_loc14_);
                           break;
                        }
                        if(areaGroupConfig && _loc14_ < areaGroupConfig.length && areaGroupConfig[_loc14_] is String && String(areaGroupConfig[_loc14_]).length > 0)
                        {
                           areaGroupName = String(areaGroupConfig[_loc14_]);
                           targetGroups[areaGroupName] = areaTargets.concat();
                        }
                        actionTargets[_loc14_] = _loc1_;
                        _loc23_ = 0;
                        var areaTargetIndex:int = 0;
                        while(areaTargetIndex < areaTargets.length)
                        {
                           _loc1_ = areaTargets[areaTargetIndex];
                           var areaHitIndex:int = 0;
                           while(areaHitIndex < areaHitCount && _loc1_.hp > 0)
                           {
                              _loc3_ = new Vector.<Avatar>();
                              _loc3_.push(_loc1_);
                               var areaHitCoeff:Number = Number(_loc20_[2 + areaHitIndex]);
                               var areaShareTotal:Number = damageShareTotal(_loc14_,areaHitCoeff,_loc1_,preCastDotTargets,preCastBurnTargets);
                               _loc23_ += avatar.attackAimList(_loc3_,int(_loc20_[2 + areaHitCount]),areaShareTotal,0,String(_loc20_[6 + areaHitCount]),_loc2_,null,_loc24_,damageShareWeight(areaHitCoeff,areaShareTotal));
                              GameMap.actionDelay += 0.15;
                              areaHitIndex++;
                           }
                           areaTargetIndex++;
                        }
                        _loc5_ = Number(_loc20_[3 + areaHitCount]);
                        if(_loc5_ > 0 && Number(actionDamageCapture ? actionDamageCapture.total : _loc23_) > 0) avatar.injured(int(Number(actionDamageCapture ? actionDamageCapture.total : _loc23_) * _loc5_ * getActiveRecoveryMultiplier()),1,DisplayTools.getAttrs(String(_loc20_[6 + areaHitCount])),4);
                     }
                  }
                  break;
               case "move_to_target":
                  _loc3_ = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                  _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_,String(_loc20_[1])),_loc14_,actionTargets,targetGroups);
                  _loc3_ = avatar.findAimList(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun(),String(_loc20_[1])),_loc24_,_loc2_);
                  if(_loc3_.length > 0)
                  {
                     _loc1_ = _loc3_[0];
                     actionTargets[_loc14_] = _loc1_;
                     _loc23_ = Math.abs(_loc1_.pos - avatar.pos);
                     if(_loc20_[2] > 0)
                     {
                        _loc23_ = Math.min(_loc23_,_loc20_[2]);
                     }
                     if(_loc23_ > 0)
                     {
                        avatar.checkMove(avatar.team == 1 ? _loc1_.pos < avatar.pos : _loc1_.pos > avatar.pos, int(_loc23_), _loc1_, -1, false, _loc20_[_loc20_.length - 1]);
                     }
                  }
                  break;
               case "shield_followup":
                  _loc1_ = int(_loc20_[4]) >= 0 && int(_loc20_[4]) < actionTargets.length ? actionTargets[int(_loc20_[4])] as Avatar : null;
                  if(_loc1_ && _loc1_.hp > 0 && _loc20_.length >= 7)
                  {
                     priorShield = avatar.buffs["shield"];
                     avatar.addBuff("shield",int(_loc20_[2]),int(avatar.getHpMax() * Number(_loc20_[1])));
                     appliedShield = avatar.buffs["shield"];
                     if(appliedShield && appliedShield !== priorShield && appliedShield.value > 0)
                     {
                        queueDirectActionEffect(String(_loc20_[6]),avatar);
                        pendingShieldFollowupTarget = _loc1_;
                        pendingShieldFollowupBuff = appliedShield;
                        pendingShieldFollowupDamage = Number(_loc20_[3]);
                        pendingShieldFollowupEffect = String(_loc20_[6]);
                        pendingShieldFollowupDamageType = int(_loc20_[5]);
                     }
                     GameMap.actionDelay += 0.5;
                  }
                  break;
               case "shield_dispel":
                  _loc3_ = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                  _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                  _loc3_ = avatar.findAimList(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),int(_loc20_[1]),_loc2_);
                  _loc21_ = 0;
                  while(_loc21_ < _loc3_.length)
                  {
                     _loc13_ = _loc3_[_loc21_];
                     if(_loc13_ && _loc13_.buffs["shield"])
                     {
                        _loc13_.dispelShieldForSkill();
                        if(_loc20_[2])
                        {
                           queueDirectActionEffect(String(_loc20_[2]),_loc13_,"b");
                        }
                     }
                     _loc21_++;
                  }
                  break;
               case "push_aoe":
                  _loc3_ = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                  _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                  _loc3_ = avatar.findAimList(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),int(_loc20_[1]),_loc2_);
                  _loc21_ = 0;
                  while(_loc21_ < _loc3_.length)
                  {
                     _loc13_ = _loc3_[_loc21_];
                     _loc13_.checkMove(false,int(_loc20_[2]),avatar,-1,true,String(_loc20_[3]));
                     GameMap.actionDelay += 0.15;
                     _loc21_++;
                  }
                  break;
               case "locked_combo_group":
                  if(_loc20_.length >= 7)
                  {
                     _loc3_ = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                     _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                     _loc3_ = avatar.findAimList(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_);
                     _loc23_ = 0;
                     var groupIndex:int = 0;
                     while(groupIndex < _loc3_.length && groupIndex < int(_loc20_[1]))
                     {
                        _loc1_ = _loc3_[groupIndex];
                        var groupHit:int = 0;
                        while(groupHit < int(_loc20_[2]) && _loc1_.hp > 0)
                        {
                           var oneTarget:Vector.<Avatar> = new Vector.<Avatar>();
                           oneTarget.push(_loc1_);
                            var comboGroupCoeff:Number = Number(_loc20_[3]);
                            var comboGroupShareTotal:Number = damageShareTotal(_loc14_,comboGroupCoeff,_loc1_,preCastDotTargets,preCastBurnTargets);
                            _loc23_ += avatar.attackAimList(oneTarget,int(_loc20_[4]),comboGroupShareTotal,0,String(_loc20_[6]),_loc2_,null,_loc24_,damageShareWeight(comboGroupCoeff,comboGroupShareTotal));
                           GameMap.actionDelay += 0.12;
                           groupHit++;
                        }
                        groupIndex++;
                     }
                     if(Number(_loc20_[5]) > 0 && _loc23_ > 0)
                     {
                        avatar.injured(int(Number(actionDamageCapture ? actionDamageCapture.total : _loc23_) * Number(_loc20_[5]) * getActiveRecoveryMultiplier()),1,DisplayTools.getAttrs(String(_loc20_[6])),4);
                     }
                  }
                  break;
               case "heal_ap":
                  _loc3_ = new Vector.<Avatar>();
                  _loc3_.push(avatar);
                  avatar.attackAimList(_loc3_,4,_loc20_[1],0,_loc20_[_loc20_.length - 1],_loc2_);
                  break;
               case "locked_combo_weak":
                  _loc3_ = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                  _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                  _loc3_ = avatar.findAimList(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_);
                  if(_loc3_.length > 0)
                  {
                     _loc1_ = _loc3_[0];
                     _loc21_ = 0;
                     while(_loc21_ < _loc20_[3] && _loc1_.hp > 0)
                     {
                        _loc3_ = new Vector.<Avatar>();
                        _loc3_.push(_loc1_);
                         var comboWeakCoeff:Number = Number(_loc20_[1]);
                         var comboWeakShareTotal:Number = damageShareTotal(_loc14_,comboWeakCoeff,_loc1_,preCastDotTargets,preCastBurnTargets);
                         avatar.attackAimList(_loc3_,_loc20_[2],comboWeakShareTotal,0,_loc20_[_loc20_.length - 1],_loc2_,null,_loc24_,damageShareWeight(comboWeakCoeff,comboWeakShareTotal));
                        _loc21_++;
                     }
                     if(_loc21_ == _loc20_[3] && _loc1_.hp > 0)
                     {
                        _loc1_.addBuff("weak",_loc20_[5],_loc20_[4]);
                     }
                  }
                  break;
               case "trynd_undying":
                  avatar.activateTryndUndying(_loc20_[1]);
                  break;
               case "combo":
                  _loc9_ = _loc20_[_loc20_.length - 1];
                  _loc12_ = DisplayTools.getAttrs(_loc9_);
                  _loc12_.check = true;
                  _loc6_ = Math.max(0,DisplayTools.addBullet(_loc12_) - 0.08);
                  _loc15_ = 0;
                  _loc21_ = 0;
                  var comboShareTarget:Avatar = null;
                  var comboShareTotal:Number = 0;
                  var comboCoeffAtHit:Number = Number(_loc20_[1]);
                  var comboRemainingHits:int = 0;
                  while(_loc21_ < int(_loc20_[3]))
                  {
                     _loc3_ = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                     _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                     _loc3_ = avatar.findAimList(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_);
                     if(_loc3_.length == 0)
                     {
                        break;
                     }
                     var comboAimAtHit:Avatar = _loc3_[0];
                     if(comboAimAtHit !== comboShareTarget)
                     {
                        comboRemainingHits = int(_loc20_[3]) - _loc21_;
                        comboShareTotal = damageShareTotal(_loc14_,comboCoeffAtHit,comboAimAtHit,preCastDotTargets,preCastBurnTargets,comboRemainingHits);
                        comboShareTarget = comboAimAtHit;
                     }
                     _loc1_ = avatar.checkAttack(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_,_loc20_[2],comboShareTotal,0,_loc20_[_loc20_.length - 1],null,damageShareWeight(comboCoeffAtHit,comboShareTotal));
                     if(_loc1_ == null)
                     {
                        break;
                     }
                     _loc5_ = Math.max(0,-0.08);
                     _loc15_ = Math.max(_loc6_ + _loc5_,_loc15_);
                     GameMap.actionDelay -= Math.min(_loc6_ + _loc5_,0.25);
                     _loc21_++;
                  }
                  if(_loc1_) actionTargets[_loc14_] = _loc1_;
                  GameMap.actionDelay += _loc15_;
                  break;
               case "suck":
                  _loc3_ = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                  _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                  _loc3_ = avatar.findAimList(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_);
                  if(_loc3_.length > 0)
                  {
                      var suckCoeff:Number = Number(_loc20_[1]);
                      var suckShareTotal:Number = _loc3_.length > 0 ? damageShareTotal(_loc14_,suckCoeff,_loc3_[0],preCastDotTargets,preCastBurnTargets) : suckCoeff;
                      _loc23_ = avatar.attackAimList(_loc3_,_loc20_[2],suckShareTotal,getActionAoeIndex(_loc14_,_loc7_,_loc3_),_loc20_[_loc20_.length - 1],_loc2_,null,_loc24_,damageShareWeight(suckCoeff,suckShareTotal));
                     GameMap.actionDelay += 0.5;
                     _loc12_ = DisplayTools.getAttrs("SUCK_EFF");
                     avatar.injured(Tools.toInt(Number(actionDamageCapture ? actionDamageCapture.total : _loc23_) * _loc20_[3] * getActiveRecoveryMultiplier()),1,_loc12_,4);
                  }
                  break;
               case "stun":
                  _loc3_ = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                  _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                  var stunActionTotal:Number = _loc3_.length > 0 ? damageShareTotal(_loc14_,Number(_loc20_[1]),_loc3_[0],preCastDotTargets,preCastBurnTargets) : Number(_loc20_[1]);
                  _loc1_ = avatar.checkAttack(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_,_loc20_[2],stunActionTotal,getActionAoeIndex(_loc14_,_loc7_,_loc3_),_loc20_[_loc20_.length - 1],new Buff("stun",_loc20_[3],0),damageShareWeight(Number(_loc20_[1]),stunActionTotal));
                  if(_loc1_) actionTargets[_loc14_] = _loc1_;
                  break;
               case "silence":
                  _loc3_ = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                  _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                  var silenceActionTotal:Number = _loc3_.length > 0 ? damageShareTotal(_loc14_,Number(_loc20_[1]),_loc3_[0],preCastDotTargets,preCastBurnTargets) : Number(_loc20_[1]);
                  _loc1_ = avatar.checkAttack(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_,_loc20_[2],silenceActionTotal,getActionAoeIndex(_loc14_,_loc7_,_loc3_),_loc20_[_loc20_.length - 1],new Buff("silence",_loc20_[3],0),damageShareWeight(Number(_loc20_[1]),silenceActionTotal));
                  if(_loc1_) actionTargets[_loc14_] = _loc1_;
                  break;
               case "weak":
                  _loc3_ = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                  _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                  var weakActionTotal:Number = _loc3_.length > 0 ? damageShareTotal(_loc14_,Number(_loc20_[1]),_loc3_[0],preCastDotTargets,preCastBurnTargets) : Number(_loc20_[1]);
                  _loc1_ = avatar.checkAttack(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_,_loc20_[2],weakActionTotal,getActionAoeIndex(_loc14_,_loc7_,_loc3_),_loc20_[_loc20_.length - 1],new Buff("weak",_loc20_[4],_loc20_[3]),damageShareWeight(Number(_loc20_[1]),weakActionTotal));
                  if(_loc1_) actionTargets[_loc14_] = _loc1_;
                  break;
               case "weak_percent":
                  _loc3_ = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                  _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                  _loc18_ = getPercentDebuffValue(_loc20_[3]);
                  if(_loc18_ >= 0)
                  {
                     var weakPercentTotal:Number = _loc3_.length > 0 ? damageShareTotal(_loc14_,Number(_loc20_[1]),_loc3_[0],preCastDotTargets,preCastBurnTargets) : Number(_loc20_[1]);
                     _loc1_ = avatar.checkAttack(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_,_loc20_[2],weakPercentTotal,getActionAoeIndex(_loc14_,_loc7_,_loc3_),_loc20_[_loc20_.length - 1],new Buff("weak",_loc20_[4],_loc18_),damageShareWeight(Number(_loc20_[1]),weakPercentTotal));
                     if(_loc1_) actionTargets[_loc14_] = _loc1_;
                  }
                  break;
               case "sunder":
                  _loc3_ = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                  _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                  var sunderActionTotal:Number = _loc3_.length > 0 ? damageShareTotal(_loc14_,Number(_loc20_[1]),_loc3_[0],preCastDotTargets,preCastBurnTargets) : Number(_loc20_[1]);
                  _loc1_ = avatar.checkAttack(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_,_loc20_[2],sunderActionTotal,getActionAoeIndex(_loc14_,_loc7_,_loc3_),_loc20_[_loc20_.length - 1],new Buff("sunder",_loc20_[4],_loc20_[3]),damageShareWeight(Number(_loc20_[1]),sunderActionTotal));
                  if(_loc1_) actionTargets[_loc14_] = _loc1_;
                  break;
               case "sunder_percent":
                  _loc3_ = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                  _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                  _loc18_ = getPercentDebuffValue(_loc20_[3]);
                  if(_loc18_ >= 0)
                  {
                     var sunderPercentTotal:Number = _loc3_.length > 0 ? damageShareTotal(_loc14_,Number(_loc20_[1]),_loc3_[0],preCastDotTargets,preCastBurnTargets) : Number(_loc20_[1]);
                     _loc1_ = avatar.checkAttack(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_,_loc20_[2],sunderPercentTotal,getActionAoeIndex(_loc14_,_loc7_,_loc3_),_loc20_[_loc20_.length - 1],new Buff("sunder",_loc20_[4],_loc18_),damageShareWeight(Number(_loc20_[1]),sunderPercentTotal));
                     if(_loc1_) actionTargets[_loc14_] = _loc1_;
                  }
                  break;
               case "poison":
                  _loc3_ = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                  _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                  var poisonDirectTotal:Number = _loc3_.length > 0 ? damageShareTotal(_loc14_,Number(_loc20_[1]),_loc3_[0],preCastDotTargets,preCastBurnTargets) : Number(_loc20_[1]);
                  avatar.checkAttack(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_,_loc20_[2],poisonDirectTotal,getActionAoeIndex(_loc14_,_loc7_,_loc3_),_loc20_[_loc20_.length - 1],new Buff("poison",_loc20_[4],Tools.toInt(_loc20_[3] * Tools.toInt(avatar.getDamage() * (1 + avatar.checkTalent(1))))),damageShareWeight(Number(_loc20_[1]),poisonDirectTotal));
                  break;
               case "burn":
                  _loc3_ = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                  _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                  avatar.checkAttack(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_,0,0,getActionAoeIndex(_loc14_,_loc7_,_loc3_),_loc20_[_loc20_.length - 1],new Buff("burn",_loc20_[2],Tools.toInt(_loc20_[1] * Tools.toInt(avatar.getDamage() * (1 + avatar.checkTalent(1))))));
                  break;
               case "evil":
                  _loc3_ = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                  _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                  avatar.checkAttack(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_,0,0,getActionAoeIndex(_loc14_,_loc7_,_loc3_),_loc20_[_loc20_.length - 1],new Buff("evil",_loc20_[1]));
                  break;
               case "pull":
                  _loc3_ = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                  _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                  var pullActionTotal:Number = _loc3_.length > 0 ? damageShareTotal(_loc14_,Number(_loc20_[1]),_loc3_[0],preCastDotTargets,preCastBurnTargets) : Number(_loc20_[1]);
                  avatar.checkAttack(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_,_loc20_[2],pullActionTotal,getActionAoeIndex(_loc14_,_loc7_,_loc3_),_loc20_[_loc20_.length - 1],new Buff("pull",0,_loc20_[3]),damageShareWeight(Number(_loc20_[1]),pullActionTotal));
                  break;
               case "push":
                  _loc3_ = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                  _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                  var pushActionTotal:Number = _loc3_.length > 0 ? damageShareTotal(_loc14_,Number(_loc20_[1]),_loc3_[0],preCastDotTargets,preCastBurnTargets) : Number(_loc20_[1]);
                  avatar.checkAttack(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_,_loc20_[2],pushActionTotal,getActionAoeIndex(_loc14_,_loc7_,_loc3_),_loc20_[_loc20_.length - 1],new Buff("push",0,_loc20_[3]),damageShareWeight(Number(_loc20_[1]),pushActionTotal));
                  break;
               case "summon":
                  if(skillSetData.manualSummonPolicy)
                  {
                     executeManualSummon(_loc20_,_loc14_,actionTargets,targetGroups);
                     break;
                  }
                  limitedSummon = hasBoundedSummonPolicy();
                  if(limitedSummon)
                  {
                     if(boundedSummons && boundedSummons.length > 0 && boundedSummons[0] && boundedSummons[0].hp > 0)
                     {
                        GameMapTools.gameTrace("该队长已有存活召唤物，跳过重复召唤",skillSetData.id);
                        break;
                     }
                     boundedSummons = new Vector.<Avatar>();
                  }
                  summonLevel = Tools.toInt(_loc20_[1] * avatar.lv);
                  if(limitedSummon && summonLevel < 1)
                  {
                     summonLevel = 1;
                  }
                  _loc1_ = new Avatar(_loc20_[2],{
                     "lv":summonLevel,
                     "slv":1
                  });
                  _loc23_ = avatar.team == 1 ? avatar.pos - GameMapConfig.SUMMON_POS : avatar.pos + GameMapConfig.SUMMON_POS;
                  _loc1_.goFight(avatar.team,avatar.line,0,false);
                  summonApFactor = getSummonCombatSnapshotApFactor();
                  if(summonApFactor > 0)
                  {
                     _loc1_.hpMax = int(avatar.getHpMax() * 0.20);
                     if(_loc1_.hpMax < 1) _loc1_.hpMax = 1;
                     _loc1_.hp = _loc1_.hpMax;
                     _loc1_.ap = int(avatar.getDamage() * summonApFactor);
                     if(_loc1_.ap < 1) _loc1_.ap = 1;
                     _loc1_.dePh = int(avatar.getDePh() * 0.40);
                     if(_loc1_.dePh < 1) _loc1_.dePh = 1;
                     _loc1_.deMa = int(avatar.getDeMa() * 0.40);
                     if(_loc1_.deMa < 1) _loc1_.deMa = 1;
                  }
                  _loc1_.hit = avatar.hit;
                  _loc1_.flee = avatar.flee;
                  _loc1_.crit = avatar.crit;
                  _loc1_.tough = avatar.tough;
                  _loc1_.addBuff("summon",_loc20_[3]);
                  _loc12_ = DisplayTools.getAttrs(_loc20_[_loc20_.length - 1]);
                  if(!_loc12_)
                  {
                     _loc12_ = DisplayTools.getAttrs("SUMMON_EFF");
                  }
                  if(_loc12_)
                  {
                     _loc12_.a1 = _loc1_;
                     _loc12_.par = _loc16_.effectLayer;
                     _loc16_.delayCall(DisplayTools.addEffects,GameMap.actionDelay,_loc12_);
                     GameMap.actionDelay += 0.25;
                  }
                  GameMapTools.gameTrace("召喚 " + _loc1_.id,"召唤物lv" + _loc1_.lv,"avatarlv" + avatar.lv);
                  _loc26_.addAvatar(_loc1_,avatar.team,avatar.line,_loc23_,false);
                  if(limitedSummon)
                  {
                     boundedSummons.push(_loc1_);
                  }
                  break;
               case "summon_turret":
                  executeHeimerTurretSummon(_loc20_);
                  break;
               case "shield":
                  if(_loc24_ == 0)
                  {
                     _loc3_ = new Vector.<Avatar>();
                     _loc3_.push(avatar);
                  }
                  else
                  {
                     _loc3_ = _loc26_.getAliveList(avatar.team) as Vector.<Avatar>;
                     _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                     _loc3_ = avatar.findAimList(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_);
                  }
                  if(_loc3_.length > 0)
                  {
                     avatar.attackAimList(_loc3_,5,0,getActionAoeIndex(_loc14_,_loc7_,_loc3_),_loc20_[_loc20_.length - 1],_loc2_,new Buff("shield",_loc20_[2],Tools.toInt(_loc20_[1] * (Tools.toInt(avatar.getDamage() * (1 + avatar.checkTalent(1))) + avatar.getHpMax() * 0.1))));
                     GameMap.actionDelay += 0.5;
                  }
                  break;
               case "cure":
                  if(_loc24_ == 0)
                  {
                     _loc3_ = new Vector.<Avatar>();
                     _loc3_.push(avatar);
                  }
                  else
                  {
                     _loc3_ = _loc26_.getAliveList(avatar.team) as Vector.<Avatar>;
                     _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                     _loc3_ = avatar.findAimList(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_);
                  }
                  if(_loc3_.length > 0)
                  {
                      avatar.attackAimList(_loc3_,4,_loc20_[1],getActionAoeIndex(_loc14_,_loc7_,_loc3_),_loc20_[_loc20_.length - 1],_loc2_);
                     GameMap.actionDelay += 0.5;
                  }
                  break;
               case "strong":
                  if(_loc24_ == 0)
                  {
                     _loc3_ = new Vector.<Avatar>();
                     _loc3_.push(avatar);
                  }
                  else
                  {
                     _loc3_ = _loc26_.getAliveList(avatar.team) as Vector.<Avatar>;
                     _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                     _loc3_ = avatar.findAimList(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_);
                  }
                  if(_loc3_.length > 0)
                  {
                     avatar.attackAimList(_loc3_,5,0,getActionAoeIndex(_loc14_,_loc7_,_loc3_),_loc20_[_loc20_.length - 1],_loc2_,new Buff("strong",_loc20_[2],_loc20_[1]));
                     GameMap.actionDelay += 0.5;
                  }
                  break;
               case "purify":
                  if(_loc24_ == 0)
                  {
                     _loc3_ = new Vector.<Avatar>();
                     _loc3_.push(avatar);
                  }
                  else
                  {
                     _loc3_ = _loc26_.getAliveList(avatar.team) as Vector.<Avatar>;
                     _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                     _loc3_ = avatar.findAimList(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_);
                  }
                  if(_loc3_.length > 0)
                  {
                     avatar.attackAimList(_loc3_,5,0,getActionAoeIndex(_loc14_,_loc7_,_loc3_),_loc20_[_loc20_.length - 1],_loc2_,new Buff("purify",_loc20_[1]));
                     GameMap.actionDelay += 0.5;
                  }
                  break;
               case "attrup":
                  if(_loc24_ == 0)
                  {
                     _loc3_ = new Vector.<Avatar>();
                     _loc3_.push(avatar);
                  }
                  else
                  {
                     _loc3_ = _loc26_.getAliveList(avatar.team) as Vector.<Avatar>;
                     _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                     _loc3_ = avatar.findAimList(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_);
                  }
                  if(_loc3_.length > 0)
                  {
                     _loc9_ = _loc20_[2];
                     if(_loc9_ == "hit")
                     {
                        _loc9_ = "hitup";
                        _loc23_ = Tools.toInt((avatar.hit + _loc20_[3]) * _loc20_[1]);
                     }
                     else if(_loc9_ == "flee")
                     {
                        _loc9_ = "fleeup";
                        _loc23_ = Tools.toInt((avatar.flee + _loc20_[3]) * _loc20_[1]);
                     }
                     else if(_loc9_ == "crit")
                     {
                        _loc9_ = "critup";
                        _loc23_ = Tools.toInt((avatar.crit + _loc20_[3]) * _loc20_[1]);
                     }
                     else if(_loc9_ == "tough")
                     {
                        _loc9_ = "toughup";
                        _loc23_ = Tools.toInt((avatar.tough + _loc20_[3]) * _loc20_[1]);
                     }
                     avatar.attackAimList(_loc3_,5,0,getActionAoeIndex(_loc14_,_loc7_,_loc3_),_loc20_[_loc20_.length - 1],_loc2_,new Buff(_loc9_,_loc20_[4],_loc23_));
                     GameMap.actionDelay += 0.5;
                  }
                  break;
               case "dash":
                  if(_loc20_[1] < 0)
                  {
                     GameMap.actionDelay += 0.5;
                     avatar.checkMove(false,-_loc20_[1],null,-1,false,_loc20_[_loc20_.length - 1]);
                     _loc4_ = true;
                  }
                  else
                  {
                     avatar.checkMove(true,_loc20_[1],null,-1,false,_loc20_[_loc20_.length - 1]);
                  }
                  break;
               case "reline":
                  _loc8_ = GameMap.currentMap.getNaerestFightLine(avatar.line);
                  if(GameMap.currentMap.getLineAliveList(avatar.team,avatar.line).length > 1 && _loc8_ < 2147483647)
                  {
                     _loc23_ = Number(avatar.team == 1 ? avatar.pos - _loc20_[1] : avatar.pos + _loc20_[1]);
                     avatar.reline(_loc8_,_loc23_);
                     GameMap.actionDelay += 2.8 / 2;
                  }
                  else if(_loc20_[1] >= 0)
                  {
                     avatar.checkMove(true,_loc20_[1],null,-1,false,_loc20_[_loc20_.length - 1]);
                  }
                  else
                  {
                     avatar.checkMove(false,_loc20_[1],null,-1,false,_loc20_[_loc20_.length - 1]);
                  }
                  break;
               case "gank":
                  _loc3_ = _loc26_.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
                  _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                  _loc22_ = avatar.findAimList(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc20_[2],_loc2_);
                  if(_loc22_.length >= 1)
                  {
                     _loc22_ = _loc22_.slice(0,1);
                     _loc1_ = _loc22_[0];
                     _loc16_.delayCall((_loc1_.fightRes.parent as AvatarLayer).setFirst,GameMap.actionDelay,_loc1_.fightRes);
                     GameMap.actionDelay += 0.8;
                     _loc12_ = DisplayTools.getAttrs("GANK");
                     _loc12_.a1 = _loc1_;
                     _loc12_.par = _loc16_.effectLayer;
                     _loc16_.delayCall(DisplayTools.addEffects,GameMap.actionDelay,_loc12_);
                     GameMap.actionDelay += 1.2;
                     _loc3_ = _loc26_.getLineAliveList(avatar.team,_loc1_.line) as Vector.<Avatar>;
                     _loc21_ = 0;
                     while(_loc21_ < _loc3_.length)
                     {
                        _loc13_ = _loc3_[_loc21_];
                        if(!_loc13_.buffs["stun"])
                        {
                           _loc13_.checkAttack(_loc22_,null,_loc20_[3] + _loc13_.getRange(),false,-1,1,0,null,null,_loc20_[1]);
                           GameMap.actionDelay -= 0.3 * 0.8;
                        }
                        _loc21_++;
                     }
                     GameMap.actionDelay += 0.3 * 0.8;
                  }
                  break;
               case "taunt":
                  _loc3_ = new Vector.<Avatar>();
                  _loc3_.push(avatar);
                  if(_loc3_.length > 0)
                  {
                     avatar.attackAimList(_loc3_,5,0,0,_loc20_[_loc20_.length - 1],_loc2_,new Buff("taunt",_loc20_[1]));
                     GameMap.actionDelay += 0.5;
                  }
                  break;
               case "bless":
                  if(_loc24_ == 0)
                  {
                     _loc3_ = new Vector.<Avatar>();
                     _loc3_.push(avatar);
                  }
                  else
                  {
                     _loc3_ = _loc26_.getAliveList(avatar.team) as Vector.<Avatar>;
                     _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                     _loc3_ = avatar.findAimList(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_);
                  }
                  if(_loc3_.length > 0)
                  {
                     avatar.attackAimList(_loc3_,5,0,getActionAoeIndex(_loc14_,_loc7_,_loc3_),_loc20_[_loc20_.length - 1],_loc2_,new Buff("bless",_loc20_[1]));
                     GameMap.actionDelay += 0.5;
                  }
                  break;
               case "steel":
                  if(_loc24_ == 0)
                  {
                     _loc3_ = new Vector.<Avatar>();
                     _loc3_.push(avatar);
                  }
                  else
                  {
                     _loc3_ = _loc26_.getAliveList(avatar.team) as Vector.<Avatar>;
                     _loc3_ = applyActionTargetLinks(applyActionTargetPolicy(_loc3_,_loc14_),_loc14_,actionTargets,targetGroups);
                     _loc3_ = avatar.findAimList(_loc3_,getActionSortFunction(_loc14_,avatar.getSortOnFun()),_loc24_,_loc2_);
                  }
                  if(_loc3_.length > 0)
                  {
                     avatar.attackAimList(_loc3_,5,0,getActionAoeIndex(_loc14_,_loc7_,_loc3_),_loc20_[_loc20_.length - 1],_loc2_,new Buff("steel",_loc20_[2],_loc20_[1]));
                     GameMap.actionDelay += 0.5;
                  }
            }
            if(actionDamageCapture)
            {
               actionDamageCapture.active = false;
               if(avatar.manualSkillDamageCapture === actionDamageCapture) avatar.manualSkillDamageCapture = null;
               actionDamageTotals[_loc14_] = Math.max(0,Number(actionDamageCapture.total));
            }
            if(killContext && avatar.currentSkillKillContext === killContext)
            {
               avatar.currentSkillKillContext = null;
            }
            if(killContext) actionKillContexts[_loc14_] = killContext;
            if(killContext && killContext.killed && isSuper && skillSetData.recastNormalOnceOnKill && !recastUsed && !inKillRecast && avatar.skill0 != null)
            {
               recastUsed = true;
               inKillRecast = true;
               avatar.skill0.useSkill();
               avatar.skill0.m_cooldownNum = avatar.skill0.skillSetData.cooldown;
               inKillRecast = false;
            }
            _loc14_++;
         }
         GameMap.actionDelay += 0.5 / 2;
         return _loc4_;
      }
      
      public function clear() : void
      {
         pendingShieldFollowupTarget = null;
         pendingShieldFollowupBuff = null;
         pendingShieldFollowupDamage = 0;
         pendingShieldFollowupEffect = null;
         skills = null;
         avatar = null;
      }

       private function getActiveRecoveryMultiplier() : Number
       {
          var effectiveHit:Number = Tools.toInt(avatar.getHit() * (1 + avatar.checkTalent(4)));
          return 1 + 0.5 * effectiveHit / (effectiveHit + 3000);
       }

       private function actionShareGroupFor(param1:int) : Array
       {
          var groups:Array = skillSetData.damageShareGroups;
          var groupIndex:int = 0;
          var memberIndex:int = 0;
          var group:Array = null;
          var member:Number = NaN;
          if(!groups) return null;
          while(groupIndex < groups.length)
          {
             group = groups[groupIndex] as Array;
             if(group)
             {
                memberIndex = 0;
                while(memberIndex < group.length)
                {
                   member = Number(group[memberIndex]);
                   if((group[memberIndex] is int || group[memberIndex] is Number) && isFinite(member) && Math.floor(member) == member && int(member) == param1)
                   {
                      return group;
                   }
                   memberIndex++;
                }
             }
             groupIndex++;
          }
          return null;
       }

       private function plannedDirectDamageTotal(param1:int, param2:Avatar, param3:Vector.<Avatar>, param4:Vector.<Avatar>, param5:int = -1) : Number
       {
          var action:Array = skills && param1 >= 0 && param1 < skills.length ? skills[param1] as Array : null;
          var actionType:String = action && action.length > 0 ? String(action[0]) : "";
          var damageType:int = -1;
          var total:Number = 0;
          var hitCount:int = 0;
          var hitIndex:int = 0;
          var condition:String = null;
          var coefficient:Number = NaN;
          if(!action) return 0;
          if(actionType == "damage" || actionType == "stun" || actionType == "silence" || actionType == "weak" || actionType == "sunder" || actionType == "weak_percent" || actionType == "sunder_percent" || actionType == "pull" || actionType == "push" || actionType == "suck" || actionType == "poison" || actionType == "evil")
          {
             if(action.length >= 3)
             {
                damageType = int(actionType == "suck" ? action[2] : action[2]);
                if(damageType == 1 || damageType == 2) return Number(action[1]);
             }
             return 0;
          }
          if(actionType == "conditional_damage" || actionType == "stun_by_condition")
          {
             if(action.length >= 5)
             {
                damageType = int(action[2]);
                if(damageType == 1 || damageType == 2)
                {
                   coefficient = Number(action[1]);
                   condition = String(action[3]);
                   if(conditionMatches(condition,param2,param3,param4)) coefficient += Number(action[4]);
                   return coefficient;
                }
             }
             return 0;
          }
          if(actionType == "locked_sequence")
          {
             hitCount = int(action[1]);
             if(hitCount > 0 && action.length >= hitCount + 5)
             {
                damageType = int(action[2 + hitCount]);
                if(damageType == 1 || damageType == 2)
                {
                   while(hitIndex < hitCount) { total += Number(action[2 + hitIndex]); hitIndex++; }
                }
             }
             return total;
          }
          if(actionType == "locked_sequence_area")
          {
             hitCount = int(action[1]);
             if(hitCount > 0 && action.length >= hitCount + 7)
             {
                damageType = int(action[2 + hitCount]);
                if(damageType == 1 || damageType == 2)
                {
                   while(hitIndex < hitCount) { total += Number(action[2 + hitIndex]); hitIndex++; }
                }
             }
             return total;
          }
          if(actionType == "locked_combo_group" && action.length >= 7)
          {
             damageType = int(action[4]);
             if(damageType == 1 || damageType == 2) return Number(action[3]) * int(action[2]);
          }
          if(actionType == "locked_combo_weak" && action.length >= 6)
          {
             damageType = int(action[2]);
             if(damageType == 1 || damageType == 2) return Number(action[1]) * int(action[3]);
          }
          if(actionType == "combo" && action.length >= 4)
          {
             damageType = int(action[2]);
             if(damageType == 1 || damageType == 2)
             {
                hitCount = param5 >= 0 ? Math.min(int(action[3]),param5) : int(action[3]);
                return Number(action[1]) * Math.max(0,hitCount);
             }
          }
          return 0;
       }

       private function damageShareTotal(param1:int, param2:Number, param3:Avatar, param4:Vector.<Avatar>, param5:Vector.<Avatar>, param6:int = -1) : Number
       {
          var group:Array = actionShareGroupFor(param1);
          var total:Number = 0;
          var memberIndex:int = 0;
          var member:Number = NaN;
          var memberAction:int = -1;
          if(!isFinite(param2) || param2 <= 0) return param2;
          // Without an explicit cross-action group, repeated segments internal
          // to the current action still share the armor portion per target.
          total = plannedDirectDamageTotal(param1,param3,param4,param5,param6);
          if(group)
          {
             memberIndex = 0;
             while(memberIndex < group.length)
             {
                member = Number(group[memberIndex]);
                if((group[memberIndex] is int || group[memberIndex] is Number) && isFinite(member) && Math.floor(member) == member)
                {
                   memberAction = int(member);
                   if(memberAction != param1 && memberAction >= 0 && memberAction < skills.length)
                   {
                      total += plannedDirectDamageTotal(memberAction,param3,param4,param5);
                   }
                }
                memberIndex++;
             }
          }
          return isFinite(total) && total >= param2 ? total : param2;
       }

       private function damageShareQ(param1:int, param2:Number, param3:Avatar, param4:Vector.<Avatar>, param5:Vector.<Avatar>) : Number
       {
          var total:Number = damageShareTotal(param1,param2,param3,param4,param5);
          return damageShareWeight(param2,total);
       }

       private function damageShareWeight(param1:Number, param2:Number) : Number
       {
          if(!isFinite(param1) || param1 <= 0 || !isFinite(param2) || param2 <= 0)
          {
             return 1;
          }
          return param1 / param2;
       }

       private function isDirectDamageAction(param1:String) : Boolean
      {
          return param1 == "damage" || param1 == "true_damage" || param1 == "conditional_damage" || param1 == "stun_by_condition" || param1 == "damage_chain" || param1 == "locked_sequence" || param1 == "locked_sequence_area" || param1 == "locked_combo_group" || param1 == "locked_combo_weak" || param1 == "combo" || param1 == "suck" || param1 == "poison";
      }

      private function hasRecastForAction(param1:int) : Boolean
      {
         var _loc1_:int = 0;
         var _loc2_:Array = null;
         if(!skills) return false;
         while(_loc1_ < skills.length)
         {
            _loc2_ = skills[_loc1_];
            if(_loc2_ && String(_loc2_[0]) == "recast_on_kill" && int(_loc2_[1]) == param1) return true;
            _loc1_++;
         }
         return false;
      }

      private function hasBattleStackForAction(param1:int) : Boolean
      {
         var _loc1_:int = 0;
         var _loc2_:Array = null;
         if(!skills) return false;
         while(_loc1_ < skills.length)
         {
            _loc2_ = skills[_loc1_];
            if(_loc2_ && String(_loc2_[0]) == "battle_stack" && int(_loc2_[4]) == param1) return true;
            _loc1_++;
         }
         return false;
      }

      private function getCustomActionTargets(param1:int, param2:Array, param3:Object, param4:Boolean) : Vector.<Avatar>
      {
         var _loc1_:Vector.<Avatar> = null;
         var _loc2_:String = getActionPolicy(param1);
         if(!avatar || !GameMap.currentMap) return new Vector.<Avatar>();
         _loc1_ = GameMap.currentMap.getAliveList(param4 ? avatar.team : avatar.otherTeam) as Vector.<Avatar>;
         _loc1_ = applyActionTargetLinks(applyActionTargetPolicy(_loc1_,param1),param1,param2,param3);
         return avatar.findAimList(_loc1_,getActionSortFunction(param1,avatar.getSortOnFun()),Math.abs(skillSetData.range),skillSetData.banStand);
      }

      private function conditionMatches(param1:String, param2:Avatar, param3:Vector.<Avatar>, param4:Vector.<Avatar>) : Boolean
      {
         if(!param2 || param2.hp <= 0) return false;
         switch(param1)
         {
            case "precast_dot": return param3 != null && param3.indexOf(param2) >= 0;
            case "precast_burn": return param4 != null && param4.indexOf(param2) >= 0;
            case "prehit_burn": return param2.hasManualDotKind("burn") || param2.buffs && param2.buffs["burn"] != null;
            case "prehit_bleed": return param2.hasManualDotKind("bleed");
            case "target_hp_below_50": return param2.hpMax > 0 && Number(param2.hp) / Number(param2.hpMax) < 0.5;
            case "primary_killed": return false;
         }
         return false;
      }

      private function applyActionTargetLock(param1:Vector.<Avatar>, param2:int, param3:Array) : Vector.<Avatar>
      {
         var _loc1_:Array = skillSetData.actionTargetLocks;
         var _loc2_:int = 0;
         var _loc3_:Avatar = null;
         var _loc4_:Vector.<Avatar> = new Vector.<Avatar>();
         var _loc5_:Number = NaN;
         if(!_loc1_ || param2 < 0 || param2 >= _loc1_.length || typeof _loc1_[param2] != "number") return param1;
         _loc5_ = Number(_loc1_[param2]);
         if(!isFinite(_loc5_) || Math.floor(_loc5_) != _loc5_) return _loc4_;
         _loc2_ = int(_loc5_);
         if(_loc2_ < 0 || _loc2_ >= param3.length) return _loc4_;
         _loc3_ = param3[_loc2_] as Avatar;
         if(_loc3_ && _loc3_.hp > 0 && param1.indexOf(_loc3_) >= 0) _loc4_.push(_loc3_);
         return _loc4_;
      }

      private function applyActionTargetLinks(param1:Vector.<Avatar>, param2:int, param3:Array, param4:Object) : Vector.<Avatar>
      {
         var _loc1_:Vector.<Avatar> = applyActionTargetLock(param1,param2,param3);
         var _loc2_:Array = skillSetData.actionTargetGroups;
         var _loc3_:String = null;
         var _loc4_:Vector.<Avatar> = null;
         var _loc5_:Vector.<Avatar> = new Vector.<Avatar>();
         var _loc6_:int = 0;
         _loc1_ = selectAndCapActionTargets(_loc1_,param2);
         if(!_loc2_ || param2 < 0 || param2 >= _loc2_.length || !(_loc2_[param2] is String) || String(_loc2_[param2]).length == 0) return _loc1_;
         _loc3_ = String(_loc2_[param2]);
         if(param4[_loc3_] is Vector.<Avatar>)
         {
            _loc4_ = param4[_loc3_] as Vector.<Avatar>;
            _loc6_ = 0;
            while(_loc6_ < _loc4_.length)
            {
               if(_loc4_[_loc6_] && _loc4_[_loc6_].hp > 0 && _loc1_.indexOf(_loc4_[_loc6_]) >= 0) _loc5_.push(_loc4_[_loc6_]);
               _loc6_++;
            }
            return _loc5_;
         }
         // Capture the actual in-range/capped selection once. Later actions in
         // the group may only affect these same members; they never refill from
         // a broader candidate list after a target dies or moves.
         param4[_loc3_] = _loc1_.concat();
         return _loc1_;
      }

      private function applyAreaActionTargetCandidates(param1:Vector.<Avatar>, param2:int, param3:Array, param4:Object) : Vector.<Avatar>
      {
         var _loc1_:Vector.<Avatar> = applyActionTargetPolicy(applyActionTargetLock(param1,param2,param3),param2);
         var _loc2_:Array = skillSetData.actionTargetGroups;
         var _loc3_:String = null;
         var _loc4_:Vector.<Avatar> = null;
         var _loc5_:Vector.<Avatar> = new Vector.<Avatar>();
         var _loc6_:int = 0;
         if(!_loc2_ || param2 < 0 || param2 >= _loc2_.length || !(_loc2_[param2] is String) || String(_loc2_[param2]).length == 0) return _loc1_;
         _loc3_ = String(_loc2_[param2]);
         if(!(param4[_loc3_] is Vector.<Avatar>)) return _loc1_;
         _loc4_ = param4[_loc3_] as Vector.<Avatar>;
         while(_loc6_ < _loc4_.length)
         {
            if(_loc4_[_loc6_] && _loc4_[_loc6_].hp > 0 && _loc1_.indexOf(_loc4_[_loc6_]) >= 0) _loc5_.push(_loc4_[_loc6_]);
            _loc6_++;
         }
         return _loc5_;
      }

      private function selectAndCapActionTargets(param1:Vector.<Avatar>, param2:int) : Vector.<Avatar>
      {
         var _loc1_:Vector.<Avatar> = null;
         var _loc2_:Array = skillSetData.actionTargetMaxTargets;
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         if(!param1) return new Vector.<Avatar>();
         _loc1_ = avatar.findAimList(param1,getActionSortFunction(param2,avatar.getSortOnFun()),Math.abs(skillSetData.range),skillSetData.banStand);
         if(_loc2_ && param2 >= 0 && param2 < _loc2_.length && _loc2_[param2] !== null && _loc2_[param2] !== undefined)
         {
            if(typeof _loc2_[param2] != "number" || !isFinite(Number(_loc2_[param2])) || Math.floor(Number(_loc2_[param2])) != Number(_loc2_[param2]))
            {
               GameMapTools.gameTrace("技能目标数量配置无效",skillSetData.id,param2);
               return new Vector.<Avatar>();
            }
            _loc3_ = int(_loc2_[param2]);
            if(_loc3_ == -1) return _loc1_;
            if(_loc3_ < 1)
            {
               GameMapTools.gameTrace("技能目标数量必须为正数或-1",skillSetData.id,param2,_loc3_);
               return new Vector.<Avatar>();
            }
         }
         else
         {
            _loc3_ = Math.max(1,skillSetData.aoe + 1);
         }
         if(_loc1_.length > _loc3_)
         {
            _loc1_ = _loc1_.slice(0,_loc3_);
         }
         return _loc1_;
      }

      private function getActionAoeIndex(param1:int, param2:int, param3:Vector.<Avatar>) : int
      {
         var _loc1_:Array = skillSetData.actionTargetMaxTargets;
         var _loc2_:int = 0;
         if(!_loc1_ || param1 < 0 || param1 >= _loc1_.length || _loc1_[param1] === null || _loc1_[param1] === undefined) return param2;
         if(typeof _loc1_[param1] != "number" || !isFinite(Number(_loc1_[param1])) || Math.floor(Number(_loc1_[param1])) != Number(_loc1_[param1])) return 0;
         _loc2_ = int(_loc1_[param1]);
         if(_loc2_ == -1) return Math.max(0,param3 ? param3.length - 1 : 0);
         if(_loc2_ < 1) return 0;
         return Math.max(0,Math.min(_loc2_,param3 ? param3.length : 0) - 1);
      }

      private function getPercentDebuffValue(param1:*) : Number
      {
         var _loc1_:Number = NaN;
         if(typeof param1 != "number") return -1;
         _loc1_ = Number(param1);
         if(!isFinite(_loc1_) || _loc1_ < 0 || _loc1_ > 0.95) return -1;
         if(_loc1_ == 0) return 0;
         // Native weak/sunder Buff.value is divided by (1 + value). Convert
         // a user-facing percent reduction p to the equivalent native value.
         return _loc1_ / (1 - _loc1_);
      }

      private function getActionPolicy(param1:int, param2:String = null) : String
      {
         if(param2 != null && param2.length > 0) return param2;
         var _loc3_:Array = skillSetData.actionTargetPolicies;
         if(_loc3_ && param1 >= 0 && param1 < _loc3_.length && _loc3_[param1] is String) return _loc3_[param1];
         return null;
      }

      private function applyActionTargetPolicy(param1:Vector.<Avatar>, param2:int, param3:String = null) : Vector.<Avatar>
      {
         var _loc6_:int = 0;
         var _loc4_:Vector.<Avatar> = new Vector.<Avatar>();
         var _loc5_:String = getActionPolicy(param2,param3);
         if(!_loc5_) return param1;
         if(_loc5_ != "enemy_lane_frontmost" && _loc5_ != "enemy_lane_farthest" && _loc5_ != "enemy_lane_lowest_current_hp_hero" && _loc5_ != "enemy_global_lowest_current_hp" && _loc5_ != "enemy_global_lowest_hpmax" && _loc5_ != "enemy_global_lowest_hp_ratio_hero" && _loc5_ != "enemy_lane_lowest_hp_ratio_n" && _loc5_ != "enemy_lane_all" && _loc5_ != "enemy_lane_all_in_radius" && _loc5_ != "enemy_lane_around_primary_300" && _loc5_ != "ally_self" && _loc5_ != "ally_all" && _loc5_ != "ally_lane_all" && _loc5_ != "ally_lane_lowest_current_hp_hero" && _loc5_ != "ally_lane_lowest_hp_ratio_hero" && _loc5_ != "ally_lane_lowest_hp_ratio_heroes" && _loc5_ != "ally_lane_lowest_hp_ratio_any" && _loc5_ != "ally_lane_lowest_hp_ratio_n" && _loc5_ != "ally_all_lowest_hp_ratio") return _loc4_;
         _loc6_ = 0;
         while(_loc6_ < param1.length)
         {
            var _avatar:Avatar = param1[_loc6_];
            if(_avatar && _avatar.hp > 0)
            {
               if(_loc5_.indexOf("enemy_") == 0 && _avatar.team != avatar.otherTeam) { _loc6_++; continue; }
               if(_loc5_.indexOf("ally_") == 0 && _avatar.team != avatar.team) { _loc6_++; continue; }
               if(_loc5_ == "ally_self" && _avatar != avatar) { _loc6_++; continue; }
               if(_loc5_.indexOf("_lane_") >= 0 && _avatar.line != avatar.line) { _loc6_++; continue; }
               if(_loc5_ == "enemy_lane_around_primary_300" && _avatar.line != avatar.line) { _loc6_++; continue; }
               if((_loc5_.indexOf("_hero") >= 0 || _loc5_.indexOf("_heroes") >= 0 || _loc5_ == "enemy_global_lowest_current_hp") && _avatar.getType() != 1) { _loc6_++; continue; }
               _loc4_.push(_avatar);
            }
            _loc6_++;
         }
         if(_loc4_.length > 1) _loc4_ = Tools.sortVector(_loc4_,getActionSortFunction(param2,avatar.getSortOnFun(),_loc5_));
         if(_loc5_ == "enemy_lane_around_primary_300" && _loc4_.length > 0)
         {
            var primary:Avatar = _loc4_[0];
            var around:Vector.<Avatar> = new Vector.<Avatar>();
            _loc6_ = 0;
            while(_loc6_ < _loc4_.length)
            {
               _avatar = _loc4_[_loc6_];
               if(_avatar == primary || Math.abs(_avatar.pos - primary.pos) <= 300) around.push(_avatar);
               _loc6_++;
            }
            _loc4_ = around;
         }
         return _loc4_;
      }

      private function getActionSortFunction(param1:int, param2:Function, param3:String = null) : Function
      {
         switch(getActionPolicy(param1,param3))
         {
            case "enemy_lane_frontmost": return sortOnFrontmost;
            case "enemy_lane_farthest": return sortOnFarthest;
            case "enemy_lane_lowest_current_hp_hero":
            case "enemy_global_lowest_current_hp":
            case "ally_lane_lowest_current_hp_hero": return sortOnLowestCurrentHp;
            case "enemy_global_lowest_hpmax": return sortOnLowestHpMax;
            case "enemy_global_lowest_hp_ratio_hero": return sortOnLowestHpRatio;
            case "enemy_lane_lowest_hp_ratio_n": return sortOnLowestHpRatio;
            case "ally_lane_lowest_hp_ratio_hero":
            case "ally_lane_lowest_hp_ratio_heroes":
            case "ally_lane_lowest_hp_ratio_any":
            case "ally_lane_lowest_hp_ratio_n":
            case "ally_all_lowest_hp_ratio": return sortOnLowestHpRatio;
         }
         return param2;
      }

      private function sortOnLowestHpRatio(param1:Avatar, param2:Avatar) : int
      {
         var _loc1_:Number = param1.hpMax > 0 ? param1.hp / param1.hpMax : 1;
         var _loc2_:Number = param2.hpMax > 0 ? param2.hp / param2.hpMax : 1;
         if(_loc1_ < _loc2_) return -1;
         if(_loc1_ > _loc2_) return 1;
         if(param1.hp < param2.hp) return -1;
         if(param1.hp > param2.hp) return 1;
         if(param1.line < param2.line) return -1;
         if(param1.line > param2.line) return 1;
         if(param1.pos < param2.pos) return -1;
         if(param1.pos > param2.pos) return 1;
         return param1.id < param2.id ? -1 : (param1.id > param2.id ? 1 : 0);
      }

      private function sortOnFarthest(param1:Avatar, param2:Avatar) : int
      {
         var _loc1_:int = Math.abs(param1.pos - avatar.pos);
         var _loc2_:int = Math.abs(param2.pos - avatar.pos);
         if(_loc1_ > _loc2_) return -1;
         if(_loc1_ < _loc2_) return 1;
         return sortOnFrontmost(param1,param2);
      }

      private function sortOnLowestHpMax(param1:Avatar, param2:Avatar) : int
      {
         if(param1.hpMax < param2.hpMax) return -1;
         if(param1.hpMax > param2.hpMax) return 1;
         if(param1.hp < param2.hp) return -1;
         if(param1.hp > param2.hp) return 1;
         if(param1.line < param2.line) return -1;
         if(param1.line > param2.line) return 1;
         if(param1.pos < param2.pos) return -1;
         if(param1.pos > param2.pos) return 1;
         return param1.id < param2.id ? -1 : (param1.id > param2.id ? 1 : 0);
      }

      private function sortOnFrontmost(param1:Avatar, param2:Avatar) : int
      {
         if(avatar.team == 1)
         {
            if(param1.pos > param2.pos) return -1;
            if(param1.pos < param2.pos) return 1;
         }
         else
         {
            if(param1.pos < param2.pos) return -1;
            if(param1.pos > param2.pos) return 1;
         }
         if(param1.line < param2.line) return -1;
         if(param1.line > param2.line) return 1;
         return param1.id < param2.id ? -1 : (param1.id > param2.id ? 1 : 0);
      }

      public function onOwnerTurnStart() : void
      {
         var _loc1_:Vector.<Avatar> = null;
         resolvePendingAreaStrike();
         if(!pendingShieldFollowupTarget) return;
         if(GameMap.currentMap == null || avatar == null || avatar.hp <= 0 || GameMap.currentMap.isEnd(avatar.line) || avatar.buffs["shield"] !== pendingShieldFollowupBuff || !pendingShieldFollowupBuff || pendingShieldFollowupBuff.value <= 0 || pendingShieldFollowupTarget.hp <= 0 || GameMap.currentMap.getAliveList(avatar.otherTeam).indexOf(pendingShieldFollowupTarget) < 0)
         {
            pendingShieldFollowupTarget = null;
            pendingShieldFollowupBuff = null;
            pendingShieldFollowupDamage = 0;
            pendingShieldFollowupEffect = null;
            return;
         }
         _loc1_ = new Vector.<Avatar>();
         _loc1_.push(pendingShieldFollowupTarget);
         avatar.attackAimList(_loc1_,pendingShieldFollowupDamageType,pendingShieldFollowupDamage,0,pendingShieldFollowupEffect,false,null,GameMapConfig.LINE_POS + 1);
         pendingShieldFollowupTarget = null;
         pendingShieldFollowupBuff = null;
         pendingShieldFollowupDamage = 0;
         pendingShieldFollowupEffect = null;
      }

      private function resolvePendingAreaStrike() : void
      {
         var _loc1_:Vector.<Avatar> = null;
         var _loc2_:Vector.<Avatar> = new Vector.<Avatar>();
         var _loc3_:Avatar = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc6_:int = 0;
         var _loc7_:Number = NaN;
         var _loc8_:Object = null;
         var _loc9_:Function = null;
         var _strikeOrigin:Avatar = null;
         if(!pendingAreaStrike) return;
         if(!avatar || avatar.hp <= 0 || GameMap.currentMap == null || GameMap.currentMap.isEnd(avatar.line))
         {
            pendingAreaStrike = null;
            return;
         }
         if(int(pendingAreaStrike.rounds) > 1)
         {
            pendingAreaStrike.rounds = int(pendingAreaStrike.rounds) - 1;
            return;
         }
         _loc8_ = pendingAreaStrike;
         pendingAreaStrike = null;
         _strikeOrigin = _loc8_.target as Avatar;
         if(_strikeOrigin)
         {
            _loc8_.line = _strikeOrigin.line;
            _loc8_.pos = _strikeOrigin.pos;
         }
         _loc1_ = GameMap.currentMap.getAliveList(avatar.otherTeam) as Vector.<Avatar>;
         _loc4_ = 0;
         while(_loc1_ && _loc4_ < _loc1_.length)
         {
            _loc3_ = _loc1_[_loc4_];
            if(_loc3_ && _loc3_.hp > 0 && _loc3_.line == int(_loc8_.line) && Math.abs(_loc3_.pos - int(_loc8_.pos)) <= int(_loc8_.radius)) _loc2_.push(_loc3_);
            _loc4_++;
         }
         _loc5_ = int(_loc8_.pos);
         _loc9_ = function(param1:Avatar,param2:Avatar):int
         {
            var _loc1_:int = Math.abs(param1.pos - _loc5_);
            var _loc2_:int = Math.abs(param2.pos - _loc5_);
            if(_loc1_ < _loc2_) return -1;
            if(_loc1_ > _loc2_) return 1;
            return param1.id < param2.id ? -1 : (param1.id > param2.id ? 1 : 0);
         };
         if(_loc2_.length > 1) _loc2_ = Tools.sortVector(_loc2_,_loc9_);
         _loc6_ = int(_loc8_.maxTargets);
         if(_loc6_ > 0 && _loc2_.length > _loc6_) _loc2_ = _loc2_.slice(0,_loc6_);
         if(_loc2_.length > 0)
         {
            _loc7_ = Math.max(0,_loc2_.length - 1);
            _loc7_ = int(_loc8_.type) == 3 ? Number(_loc8_.coeff) / Avatar.REAL_DAMAGE_RATE : Number(_loc8_.coeff);
            avatar.attackAimList(_loc2_,int(_loc8_.type),_loc7_,Math.max(0,_loc2_.length - 1),String(_loc8_.effect),false,null,GameMapConfig.LINE_POS + 1);
         }
      }

      private function sortOnLowestCurrentHp(param1:Avatar, param2:Avatar) : int
      {
         var _loc3_:String = null;
         var _loc4_:String = null;
         if(param1.team != avatar.team)
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
         if(param1.hp < param2.hp) return -1;
         if(param1.hp > param2.hp) return 1;
         if(param1.hpMax < param2.hpMax) return -1;
         if(param1.hpMax > param2.hpMax) return 1;
         if(param1.line < param2.line) return -1;
         if(param1.line > param2.line) return 1;
         if(param1.pos < param2.pos) return -1;
         if(param1.pos > param2.pos) return 1;
         _loc3_ = param1.id;
         _loc4_ = param2.id;
         if(_loc3_ < _loc4_) return -1;
         if(_loc3_ > _loc4_) return 1;
         return 0;
      }

      private function hasBoundedSummonPolicy() : Boolean
      {
         var _loc1_:Array = skillSetData.id.split("_");
         if(_loc1_.length != 3 || _loc1_[0] != "S" || int(_loc1_[2]) < 2 || int(_loc1_[2]) > 6)
         {
            return false;
         }
         if(_loc1_[1] == "2061205")
         {
            return _loc1_[2] == "5" || _loc1_[2] == "6";
         }
         if(_loc1_[1] == "32551036" || _loc1_[1] == "32551103")
         {
            return _loc1_[2] == "4" || _loc1_[2] == "5" || _loc1_[2] == "6";
         }
         switch(_loc1_[1])
         {
            case "303014":
            case "203014":
            case "303029":
            case "303040":
            case "303124":
            case "305082":
            case "305128":
            case "301221":
            case "301310":
               return true;
         }
         return false;
      }

      private function isHeimerTurretSkill() : Boolean
      {
         switch(skillSetData.id)
         {
            case "S_203014_3":
            case "S_203014_4":
            case "S_203014_5":
            case "S_303014_3":
            case "S_303014_4":
            case "S_303014_5":
               return true;
         }
         return false;
      }

      private function executeHeimerTurretSummon(param1:Array) : void
      {
         var turretLevel:int = 0;
         var turretScale:Number = NaN;
         var turret:Avatar = null;
         var turretFx:Object = null;
         if(!isHeimerTurretSkill() || !hasBoundedSummonPolicy() || !param1 || param1.length < 11 || String(param1[2]) != "A_2001_4")
         {
            GameMapTools.gameTrace("拒绝非白名单炮台召唤技能",skillSetData.id);
            return;
         }
         turretScale = Number(param1[1]);
         if(!isFinite(turretScale) || turretScale <= 0 || turretScale > 1 || int(param1[3]) < 1 || int(param1[4]) != 0 || int(param1[5]) != 0)
         {
            GameMapTools.gameTrace("炮台召唤参数无效",skillSetData.id);
            return;
         }
         if(boundedSummons && boundedSummons.length > 0 && boundedSummons[0] && boundedSummons[0].hp > 0)
         {
            GameMapTools.gameTrace("该英雄已有存活炮台，跳过重复召唤",skillSetData.id);
            return;
         }
         boundedSummons = new Vector.<Avatar>();
         turretLevel = Math.max(1,avatar.lv);
         turret = new Avatar(String(param1[2]),{"lv":turretLevel,"slv":1});
         turret.goFight(avatar.team,avatar.line,0,false);
         turret.hpMax = Math.max(1,int(avatar.getHpMax() * turretScale));
         turret.hp = turret.hpMax;
         turret.ap = Math.max(1,int(avatar.getDamage() * turretScale));
         turret.dePh = Math.max(1,int(avatar.getDePh() * turretScale));
         turret.deMa = Math.max(1,int(avatar.getDeMa() * turretScale));
         turret.hit = Math.max(1,int(avatar.getHit() * turretScale));
         turret.flee = Math.max(1,int(avatar.getFlee() * turretScale));
         turret.crit = Math.max(1,int(avatar.getCrit() * turretScale));
         turret.tough = Math.max(1,int(avatar.getTough() * turretScale));
         turret.skill0 = null;
         turret.skill1 = null;
         turret.skill2 = null;
         turret.skillB = null;
         // The row comes from AvatarManager's shared AvatarData cache. Override
         // only this summoned instance so other turrets/family members retain
         // their configured behavior.
         turret.manualActionTypeOverride = 1;
         turret.addBuff("summon",int(param1[3]));
         turretFx = DisplayTools.getAttrs(String(param1[10]));
         if(!turretFx) turretFx = DisplayTools.getAttrs("SUMMON_EFF");
         if(turretFx)
         {
            turretFx.a1 = turret;
            turretFx.par = GameMapLayer.gl.effectLayer;
            GameMapLayer.gl.delayCall(DisplayTools.addEffects,GameMap.actionDelay,turretFx);
            GameMap.actionDelay += 0.25;
         }
         GameMap.currentMap.addAvatar(turret,avatar.team,avatar.line,avatar.team == 1 ? avatar.pos - GameMapConfig.SUMMON_POS : avatar.pos + GameMapConfig.SUMMON_POS,false);
         boundedSummons.push(turret);
      }

      private function executeManualSummon(param1:Array, param2:int, param3:Array, param4:Object) : void
      {
         var _loc1_:Object = skillSetData.manualSummonPolicy;
         var _loc2_:Avatar = null;
         var _loc3_:String = null;
         var _loc4_:int = 0;
         var _loc5_:Number = NaN;
         var _loc6_:Number = NaN;
         var _loc7_:Object = null;
         var _loc8_:Number = 0;
         var summonTargets:Vector.<Avatar> = null;
         var summonTarget:Avatar = null;
         var summonLine:int = 0;
         var summonPos:int = 0;
         var replacedSummons:Vector.<Avatar> = null;
         var familySummons:Vector.<Avatar> = null;
         var retainedSummons:Vector.<Avatar> = null;
         var replacementIndex:int = 0;
         var replacement:Avatar = null;
         var replacementHp:int = 0;
         if(!_loc1_ || !isManualSummonPolicyAllowed() || !param1 || param1.length < 5 || String(param1[2]) != String(_loc1_.unitId) || String(_loc1_.skillId) != skillSetData.id)
         {
            GameMapTools.gameTrace("拒绝未授权手动召唤策略",skillSetData.id);
            return;
         }
         summonTargets = getCustomActionTargets(param2,param3,param4,false);
         if(!summonTargets || summonTargets.length == 0 || !summonTargets[0] || summonTargets[0].hp <= 0)
         {
            GameMapTools.gameTrace("手动召唤缺少有效锁定目标",skillSetData.id);
            return;
         }
         summonTarget = summonTargets[0];
         summonLine = summonTarget.line;
         summonPos = summonTarget.pos;
         _loc3_ = String(_loc1_.familyKey);
         _loc4_ = int(_loc1_.maxAlive);
         if(!_loc3_ || _loc4_ < 1 || _loc4_ > 3)
         {
            GameMapTools.gameTrace("召唤家族策略无效",skillSetData.id);
            return;
         }
         _loc5_ = Number(_loc1_.apRatio);
         _loc6_ = Number(_loc1_.hpRatio);
         _loc8_ = Number(param1[1]);
         if(!isFinite(_loc5_) || !isFinite(_loc6_) || _loc5_ <= 0 || _loc5_ > 1 || _loc6_ <= 0 || _loc6_ > 1 || !isFinite(Number(_loc1_.attackRange)) || Number(_loc1_.attackRange) <= 0 || !isFinite(_loc8_) || _loc8_ <= 0 || !isFinite(Number(_loc1_.dePhRatio)) || Number(_loc1_.dePhRatio) <= 0 || !isFinite(Number(_loc1_.deMaRatio)) || Number(_loc1_.deMaRatio) <= 0 || int(param1[3]) < 1 || int(param1[3]) != Number(param1[3]) || int(_loc1_.ttlOwnerTurns) != int(param1[3])) return;
         replacedSummons = new Vector.<Avatar>();
         if(avatar.getManualSummonSlots(_loc3_,_loc4_) <= 0)
         {
            if(_loc1_.replaceOldest !== true || !avatar.manualSummonFamilies)
            {
               GameMapTools.gameTrace("召唤家族数量已满",skillSetData.id);
               return;
            }
            familySummons = avatar.manualSummonFamilies[_loc3_] as Vector.<Avatar>;
            retainedSummons = new Vector.<Avatar>();
            if(!familySummons)
            {
               GameMapTools.gameTrace("召唤家族记录缺失",skillSetData.id);
               return;
            }
            replacementIndex = 0;
            while(replacementIndex < familySummons.length)
            {
               replacement = familySummons[replacementIndex];
               if(replacement && replacement.hp > 0 && replacedSummons.length == 0)
               {
                  replacedSummons.push(replacement);
                  replacementHp = replacement.hp;
               }
               else if(replacement && replacement.hp > 0)
               {
                  retainedSummons.push(replacement);
               }
               replacementIndex++;
            }
            if(replacedSummons.length == 0)
            {
               GameMapTools.gameTrace("没有可替换的存活召唤物",skillSetData.id);
               return;
            }
            avatar.manualSummonFamilies[_loc3_] = retainedSummons;
         }
         _loc2_ = new Avatar(String(param1[2]),{"lv":Math.max(1,Tools.toInt(_loc8_ * avatar.lv)),"slv":1});
         _loc2_.goFight(avatar.team,summonLine,0,false);
         _loc2_.ap = Math.max(1,int(avatar.getDamage() * _loc5_));
         _loc2_.hpMax = Math.max(1,int(avatar.getHpMax() * _loc6_));
         _loc2_.hp = _loc2_.hpMax;
         _loc2_.dePh = Math.max(1,int(avatar.getDePh() * Number(_loc1_.dePhRatio)));
         _loc2_.deMa = Math.max(1,int(avatar.getDeMa() * Number(_loc1_.deMaRatio)));
         if(_loc1_.clearSkills === true)
         {
            _loc2_.skill0 = null;
            _loc2_.skill1 = null;
            _loc2_.skill2 = null;
            _loc2_.skillB = null;
         }
         if(typeof _loc1_.actionType == "number" && (_loc1_.actionType == 1 || _loc1_.actionType == 2 || _loc1_.actionType == 4)) _loc2_.manualActionTypeOverride = int(_loc1_.actionType);
         _loc2_.manualAttackRangeOverride = Number(_loc1_.attackRange);
         _loc2_.hit = avatar.hit;
         _loc2_.flee = avatar.flee;
         _loc2_.crit = avatar.crit;
         _loc2_.tough = avatar.tough;
         _loc2_.addBuff("summon",Math.max(1,int(_loc1_.ttlOwnerTurns)));
         _loc7_ = DisplayTools.getAttrs(String(param1[param1.length - 1]));
         if(!_loc7_) _loc7_ = DisplayTools.getAttrs("SUMMON_EFF");
         if(_loc7_)
         {
            _loc7_.a1 = _loc2_;
            _loc7_.par = GameMapLayer.gl.effectLayer;
            GameMapLayer.gl.delayCall(DisplayTools.addEffects,GameMap.actionDelay,_loc7_);
         }
         if(replacedSummons.length > 0)
         {
            replacedSummons[0].hp = 0;
            avatar.manualSummonFamilies[_loc3_] = retainedSummons;
         }
         if(avatar.registerManualSummon(_loc3_,_loc2_,_loc4_))
         {
            GameMap.currentMap.addAvatar(_loc2_,avatar.team,summonLine,summonPos,false);
            replacementIndex = 0;
            while(replacementIndex < replacedSummons.length)
            {
               replacedSummons[replacementIndex].dead();
               replacementIndex++;
            }
         }
         else if(replacedSummons.length > 0)
         {
            replacedSummons[0].hp = replacementHp;
            avatar.manualSummonFamilies[_loc3_] = familySummons;
         }
      }

      private function isManualSummonPolicyAllowed() : Boolean
      {
         var _loc1_:String = skillSetData.id;
         var _loc2_:Array = ["S_631029_5","S_631029_6","S_621040_4","S_621040_5","S_621040_6","S_631040_4","S_631040_5","S_631040_6"];
         if(_loc2_.indexOf(_loc1_) < 0 || !skillSetData.manualSummonPolicy) return false;
         if(String(skillSetData.manualSummonPolicy.skillId) != _loc1_) return false;
         if(_loc1_.indexOf("1029_") >= 0) return String(skillSetData.manualSummonPolicy.unitId) == "A_2002_5" && String(skillSetData.manualSummonPolicy.familyKey) == "manual-1029-tibbers" && int(skillSetData.manualSummonPolicy.maxAlive) == 1 && Number(skillSetData.manualSummonPolicy.apRatio) == 0.80 && Number(skillSetData.manualSummonPolicy.hpRatio) == 0.80 && Number(skillSetData.manualSummonPolicy.dePhRatio) == 0.80 && Number(skillSetData.manualSummonPolicy.deMaRatio) == 0.80 && Number(skillSetData.manualSummonPolicy.attackRange) == 125 && skillSetData.manualSummonPolicy.clearSkills === true && skillSetData.manualSummonPolicy.actionType == 1 && skillSetData.manualSummonPolicy.replaceOldest === true;
         return String(skillSetData.manualSummonPolicy.unitId) == "A_2326_5" && String(skillSetData.manualSummonPolicy.familyKey) == "manual-1040-plant" && int(skillSetData.manualSummonPolicy.maxAlive) == 3 && Number(skillSetData.manualSummonPolicy.apRatio) == 0.40 && Number(skillSetData.manualSummonPolicy.hpRatio) == 0.40 && Number(skillSetData.manualSummonPolicy.dePhRatio) == 0.40 && Number(skillSetData.manualSummonPolicy.deMaRatio) == 0.40 && Number(skillSetData.manualSummonPolicy.attackRange) == 550 && skillSetData.manualSummonPolicy.clearSkills === true && skillSetData.manualSummonPolicy.actionType == 1 && skillSetData.manualSummonPolicy.replaceOldest === true;
      }

      private function queueDirectActionEffect(param1:String, param2:Avatar, param3:String = "h") : void
      {
         var _loc1_:Object = DisplayTools.getAttrs(param1) as Object;
         var _loc2_:Object = null;
         if(!_loc1_) return;
         if(_loc1_.id)
         {
            _loc2_ = _loc1_;
         }
         else if(param3 && _loc1_[param3] && _loc1_[param3].id)
         {
            _loc2_ = _loc1_[param3] as Object;
         }
         else if(_loc1_.h && _loc1_.h.id)
         {
            _loc2_ = _loc1_.h as Object;
         }
         if(!_loc2_ || !_loc2_.id)
         {
            GameMapTools.gameTrace("技能直接特效缺少id",param1);
            return;
         }
         _loc2_.a1 = param2;
         _loc2_.par = GameMapLayer.gl.effectLayer;
         GameMapLayer.gl.delayCall(DisplayTools.addEffects,GameMap.actionDelay,_loc2_);
      }

      private function getSummonCombatSnapshotApFactor() : Number
      {
         switch(skillSetData.id)
         {
            case "S_32551036_4":
            case "S_32551036_5":
            case "S_32551036_6":
               return 0.60;
            case "S_32551103_4":
            case "S_32551103_5":
            case "S_32551103_6":
               return 0.30;
         }
         return 0;
      }
   }
}

