package com.meng52.game.module.map
{
   import com.meng52.game.command.map.GameMapData;
   import com.meng52.game.command.map.GameMapManager;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.BaseModule;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.map.DoorLayer;
   import com.meng52.game.ui.map.GameMapLayer;
   import com.meng52.game.ui.stage.GuideTools;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.Tools;
   import starling.animation.Tween;
   
   public class GameMap extends BaseModule
   {
      
      public static const RANDOM_ID:String = "random";
      
      public static const PVP_ID:String = "pvp";
      
      public static const FRAGMENT_ID:String = "fragment";
      
      public static const EXTREME_ID:String = "extreme";
      
      public static const EXPLORATION_ID:String = "exploration";
      
      public static const BATTLE_OF_THE_PEAK_ID:String = "battle_of_the_peak";
      
      public static var ROUND_MAX:int = 30;
      
      public static var damageNum:int = 0;
      
      public static var currentMap:GameMap;
      
      public static var currentAvatar:Avatar;
      
      public static var actionDelay:Number = 0;
      
      public static var lastRe:*;
      
      public static var lastCid:String;
      
      public static var lastDiff:int = -1;
      
      public static var isLoad:Boolean = false;
      
      public static var isLoadFile:Boolean = false;
      
      public var isClear:Boolean;
      
      public var re:*;
      public var settlementPending:Boolean = false;
      public var settlementSent:Boolean = false;
      
      public var initTeam1:Array;
      
      public var initTeam2:Array;
      
      public var randomSeed:int;
      
      public var firstTeam:int;
      
      public var roundNum:int;
      
      public var roundTeam:int;
      
      public var team1Num:int;
      
      public var team2Num:int;
      
      public var isFight:Boolean;
      
      public var isInit:Boolean;
      
      public var isGetErrlog:Boolean;
      
      public var myList:Array;
      
      public var team1Offset:Array;
      
      public var teamMyList:Vector.<Avatar>;
      
      public var friendAvatar:Avatar;
      
      public var randomAvatar:Avatar;
      
      public var team1List:Vector.<Avatar>;
      
      public var team2List:Vector.<Avatar>;
      
      public var alive1List:Vector.<Avatar>;
      
      public var alive2List:Vector.<Avatar>;
      
      public var relineList:Array;
      
      public var winnerList:Array;
      
      public var winner:int;
      
      public var diff:int;
      
      public function GameMap(param1:String, param2:int = 0, param3:Boolean = false)
      {
         super();
         isLoad = param3;
         lastCid = param1;
         if(param1 == "fragment")
         {
            m_data = GameMapManager.getOnlyExample().getFragmentData(param2);
            GlobalData.$setFragment();
            initMap();
            return;
         }
         if(param1 == "pvp" || param1 == null)
         {
            m_data = GameMapManager.getOnlyExample().getPVPData(param2);
            GlobalData.$setPVP();
            initMap();
            return;
         }
         if(param1 == "guild" || GlobalData.$userData.isGuildWarSaiCheng && param1 == "extreme")
         {
            m_data = GameMapManager.getOnlyExample().getPVPData(param2);
            m_data["line"] = 1;
            GlobalData.$setPVP();
            if(GlobalData.$userGuild.guildFightGuidenew)
            {
               GlobalData.$setExtreme();
            }
            initMap();
            return;
         }
         if(param1 == "extreme")
         {
            m_data = GameMapManager.getOnlyExample().getExtremeData(param2);
            m_data["line"] = 2;
            GlobalData.$setExtreme();
            initMap();
            return;
         }
         if(param1 == "exploration")
         {
            m_data = GameMapManager.getOnlyExample().getExplorationData(param2);
            GlobalData.$setExploration();
            initMap();
            return;
         }
         if(param1 == "battle_of_the_peak")
         {
            m_data = GameMapManager.getOnlyExample().getBattleOfThePeak(param2);
            m_data["line"] = 2;
            GlobalData.$setBattleOfThePeak();
            initMap();
            return;
         }
         if(param1 == "random")
         {
            m_data = GameMapManager.getOnlyExample().getRandomData(param2);
            initMap();
            randomSeed = Math.random() * 10000;
            firstTeam = 1;
            readyFight();
            return;
         }
         GlobalData.$setPVE();
         m_data = GameMapManager.getOnlyExample().getData(param1);
         diff = param2;
         lastDiff = diff;
         initMap();
      }
      
      public static function canHelp(param1:String) : Boolean
      {
         if(GlobalData.$isPVP)
         {
            return false;
         }
         if(GlobalData.$isFragment)
         {
            return false;
         }
         if(GlobalData.$isExtreme)
         {
            return false;
         }
         var _loc2_:GameMapData = GameMapManager.getOnlyExample().getData(param1);
         if(_loc2_.isW)
         {
            return false;
         }
         if(_loc2_ && _loc2_.isMain && !_loc2_.isFinnal)
         {
            return false;
         }
         return true;
      }
      
      public function initMap(param1:Boolean = false, param2:Array = null) : void
      {
         var _loc4_:int = 0;
         if(!param1)
         {
            myList = [];
            team1Offset = [];
         }
         currentMap = this;
         isFight = false;
         actionDelay = 0;
         var _loc3_:int = gameMapData.line;
         relineList = [];
         winnerList = [];
         _loc4_ = 0;
         while(_loc4_ < _loc3_)
         {
            relineList.push(0);
            winnerList.push(0);
            _loc4_++;
         }
         GameMapConfig.lineOffset = Math.round(1200 * 3 / _loc3_);
         GameMapConfig.sideOffset = Math.round(GameMapConfig.lineOffset * 0.4);
         winner = 0;
         if(!isInit)
         {
            GameMapLayer.gl.show(_loc3_);
            initBg();
            initUi();
            isInit = true;
         }
         if(isLoad && re)
         {
            return;
         }
         initAvatar(param2);
         _loc4_ = 0;
         while(_loc4_ < _loc3_)
         {
            autoPos(_loc4_,team1Offset);
            _loc4_++;
         }
      }
      
      public function get gameMapData() : GameMapData
      {
         return m_data as GameMapData;
      }
      
      public function getName() : String
      {
         var _loc3_:* = undefined;
         var _loc2_:String = gameMapData.name;
         var _loc1_:Boolean = GlobalData.$isPVE;
         if(_loc1_)
         {
            if(diff == 1)
            {
               if(randomAvatar)
               {
                  _loc2_ += GlobalLanguageStr.getLanguageStr(20414);
               }
               else
               {
                  _loc2_ += GlobalLanguageStr.getLanguageStr(20411);
               }
            }
            else if(diff == 0)
            {
               if(randomAvatar)
               {
                  _loc2_ += GlobalLanguageStr.getLanguageStr(20413);
               }
            }
         }
         else if(re && !_loc1_)
         {
            _loc3_ = re.data.users;
            if(_loc3_)
            {
               _loc2_ = GlobalLanguageStr.getLanguageStr(32001,_loc3_.user_a[2],_loc3_.user_b[2]);
            }
         }
         if(re && GlobalData.$isBattleOfThePeak)
         {
            _loc3_ = re.data.users;
            if(_loc3_)
            {
               _loc2_ = GlobalLanguageStr.getLanguageStr(98013,_loc3_.user_a[2],_loc3_.user_b[2],re.data.Screenings);
            }
         }
         return _loc2_;
      }
      
      public function get musicId() : String
      {
         var _loc3_:* = undefined;
         if(!GlobalData.$isPVE)
         {
            return SoundManager.SOUND_COMBAT_3;
         }
         var _loc4_:String = gameMapData.id;
         var _loc1_:Array = _loc4_.split("_");
         var _loc2_:String = _loc1_[0] + "_" + _loc1_[1];
         if(_loc1_[0] == GlobalFunction.MAIN)
         {
            _loc3_ = GlobalData.$config_battle_main;
            if(!_loc3_[_loc2_])
            {
               return SoundManager.SOUND_COMBAT_1;
            }
            if(_loc3_[_loc2_].combat == int(_loc1_[2]))
            {
               return SoundManager.SOUND_COMBAT_1;
            }
            return SoundManager.SOUND_COMBAT_0;
         }
         return SoundManager.SOUND_COMBAT_2;
      }
      
      public function initBg() : void
      {
         GameMapLayer.gl.initBg();
      }
      
      public function initUi() : void
      {
         var _loc1_:Boolean = false;
         if(GlobalFunction.getVipLv() == 0)
         {
            _loc1_ = false;
         }
         else
         {
            _loc1_ = GlobalFunction.getVipObj().battle_speed == 1;
         }
         if(!GlobalData.$isPVE || isGetErrlog)
         {
            GameMapLayer.canFpsLv = GameMapLayer.FPS_LIST.length - 1;
         }
         else if(GlobalFunction.check_pass_combat(gameMapData.id,diff) != 1 && !_loc1_)
         {
            if(GlobalData.$currentGuide || GlobalData.$userData.lv >= GlobalData.$mConfig_simple.start_lv[4])
            {
               GameMapLayer.canFpsLv = 2;
            }
            else
            {
               GameMapLayer.canFpsLv = 1;
            }
            GameMapLayer.fpsLv = Math.min(GameMapLayer.canFpsLv,GameMapLayer.fpsLv);
         }
         else
         {
            GameMapLayer.canFpsLv = GameMapLayer.FPS_LIST.length - 1;
         }
         GameMapLayer.gl.lineLayer.init();
         GameMapLayer.gl.uiLayer.init();
         GameMapLayer.gl.uiLayer.m_sprFg.visible = false;
      }
      
      public function getBossResId() : String
      {
         var _loc1_:int = 0;
         _loc1_ = 0;
         while(_loc1_ < team2List.length)
         {
            if(team2List[_loc1_].isLeader)
            {
               return team2List[_loc1_].resId;
            }
            _loc1_++;
         }
         return team2List[0].resId;
      }
      
      public function randomEmbattle(param1:int) : void
      {
         var _loc6_:int = 0;
         var _loc4_:int = 0;
         myList = [];
         team1Offset = [];
         actionDelay = 0;
         GameMapLayer.gl.juggler.purge();
         GameMapLayer.gl.effectLayer.clear();
         var _loc3_:Number = GameMapConfig.MAX_POS_PER;
         var _loc2_:Number = GlobalData.$userData.lv >= GlobalData.$mConfig_simple.start_lv[1] ? 0 : 0.2;
         var _loc7_:int = Math.min(param1,team1List.length);
         var _loc8_:int = Math.min(_loc7_,getLaneCount());
         _loc6_ = 0;
         while(_loc6_ < _loc7_)
         {
            team1Offset[_loc6_] = GameMapConfig.sideOffset / 2 - Math.random() * GameMapConfig.sideOffset;
            _loc4_ = _loc6_ < _loc8_ ? _loc6_ : int(Math.random() * getLaneCount());
            myList[_loc6_] = [team1List[_loc6_].id,_loc4_,Math.round(Math.random() * (_loc3_ - _loc2_) * 100) / 100 + _loc2_];
            _loc6_++;
         }
         clearAvatarList(true);
         initAvatar();
         _loc6_ = 0;
         while(_loc6_ < getLaneCount())
         {
            autoPos(_loc6_);
            _loc6_++;
         }
      }
      
      public function initAvatar(param1:Array = null) : void
      {
         var _loc9_:int = 0;
         var _loc2_:Avatar = null;
         var _loc5_:int = 0;
         var _loc8_:Array = null;
         var _loc3_:Boolean = false;
         var _loc7_:int = 0;
         if(isGetErrlog)
         {
            return;
         }
         var _loc4_:GameMapData = gameMapData;
         if(param1 || !teamMyList)
         {
            teamMyList = new Vector.<Avatar>();
         }
         if(param1)
         {
            friendAvatar = null;
         }
         team1List = new Vector.<Avatar>();
         team2List = new Vector.<Avatar>();
         alive1List = new Vector.<Avatar>();
         alive2List = new Vector.<Avatar>();
         var _loc6_:GameMapLayer = GameMapLayer.gl;
         _loc6_.clearAvatar();
         if(param1)
         {
            _loc5_ = int(param1.length);
            _loc7_ = int(GlobalData.$isNoFriendToPVE ? _loc5_ : _loc5_ - 1);
            _loc9_ = 0;
            while(_loc9_ < _loc5_)
            {
               if(getSameAvatar(param1[_loc9_].data.id,_loc9_ == param1.length - 1) == null)
               {
                  if(!GlobalData.$isPVE)
                  {
                     _loc2_ = new Avatar(param1[_loc9_].data.id,param1[_loc9_].data);
                     _loc2_.indexID_s = param1[_loc9_].data.indexID_s;
                     teamMyList.push(_loc2_);
                  }
                  else if(_loc9_ < _loc7_)
                  {
                     _loc2_ = new Avatar(param1[_loc9_].data.id);
                     _loc2_.indexID_s = param1[_loc9_].data.indexID_s;
                     teamMyList.push(_loc2_);
                  }
                  else
                  {
                     _loc2_ = new Avatar(param1[_loc9_].data.id,param1[_loc9_].data);
                     _loc2_.isOthers = true;
                     _loc2_.indexID_s = param1[_loc9_].data.indexID_s;
                     friendAvatar = _loc2_;
                  }
               }
               _loc2_.actionNum = _loc9_;
               team1List.push(_loc2_);
               alive1List.push(_loc2_);
               _loc9_++;
            }
         }
         _loc5_ = int(myList.length);
         _loc9_ = 0;
         while(_loc9_ < _loc5_)
         {
            _loc8_ = myList[_loc9_];
            if(_loc8_ != null)
            {
               if(!GlobalData.$isPVE)
               {
                  _loc2_ = getSameAvatar(_loc8_[0]);
                  if(!_loc2_)
                  {
                     _loc2_ = new Avatar(_loc8_[0]);
                  }
                  if(GlobalData.$isExploration)
                  {
                     _loc3_ = true;
                  }
                  else
                  {
                     if(_loc9_ == 0)
                     {
                        _loc3_ = true;
                     }
                     else
                     {
                        _loc3_ = false;
                     }
                     _loc2_.setEquips();
                  }
               }
               else
               {
                  _loc7_ = int(GlobalData.$isNoFriendToPVE ? _loc5_ : _loc5_ - 1);
                  if(_loc9_ < _loc7_)
                  {
                     _loc2_ = getSameAvatar(_loc8_[0]);
                     if(!_loc2_)
                     {
                        _loc2_ = new Avatar(_loc8_[0]);
                     }
                     _loc2_.setEquips();
                     _loc2_.setDestinyAndDN();
                  }
                  else if(_loc9_ == _loc7_)
                  {
                     _loc2_ = friendAvatar;
                  }
                  if(_loc9_ == 0 || (_loc2_ == friendAvatar && (_loc2_.mData && _loc2_.mData.isF == 1) || _loc2_.isLeader))
                  {
                     _loc3_ = true;
                  }
                  else
                  {
                     _loc3_ = false;
                  }
               }
               _loc2_.goFight(1,_loc8_[1],_loc8_[2],_loc3_);
               _loc2_.offset = team1Offset[_loc9_];
               if(!param1)
               {
                  team1List.push(_loc2_);
                  alive1List.push(_loc2_);
               }
               _loc2_.refreshPos();
               _loc6_.addAvatar(_loc2_);
            }
            _loc9_++;
         }
         _loc5_ = int(_loc4_.team1List.length);
         _loc9_ = 0;
         while(_loc9_ < _loc5_)
         {
            _loc8_ = _loc4_.team1List[_loc9_];
            if(_loc8_ != null)
            {
               _loc2_ = new Avatar(_loc8_[0],_loc8_);
               _loc2_.actionNum = team1List.length;
               if(param1)
               {
                  _loc2_.actionNum = _loc9_ + param1.length;
               }
               _loc2_.goFight(1,_loc8_[3],_loc8_[4],_loc8_[5]);
               _loc4_.initAvatarNew4attrs(_loc2_);
               GameMapTools.initAvatarDiff(_loc2_,diff);
               if(!team1Offset[_loc2_.actionNum])
               {
                  team1Offset[_loc2_.actionNum] = ((_loc9_ + 1) / (_loc5_ + 1) - 0.5) * GameMapConfig.sideOffset;
               }
               _loc2_.offset = team1Offset[_loc2_.actionNum];
               team1List.push(_loc2_);
               alive1List.push(_loc2_);
               _loc2_.refreshPos();
               _loc6_.addAvatar(_loc2_);
            }
            _loc9_++;
         }
         _loc5_ = int(_loc4_.team2List.length);
         _loc9_ = 0;
         while(_loc9_ < _loc5_)
         {
            _loc8_ = _loc4_.team2List[_loc9_];
            if(_loc8_ != null)
            {
               _loc2_ = new Avatar(_loc8_[0],_loc8_);
               _loc2_.dropRate = _loc8_[6];
               _loc2_.dropId = _loc8_[8];
               if(_loc8_[9])
               {
                  _loc2_.setEquips([{
                     "eid":_loc8_[9],
                     "slv":_loc8_[10]
                  }],false);
               }
               _loc2_.goFight(2,_loc8_[3],_loc8_[4],_loc8_[5]);
               _loc2_.offset = ((_loc9_ + 1) / (_loc5_ + 1) - 0.5) * GameMapConfig.sideOffset;
               _loc4_.initAvatarNew4attrs(_loc2_);
               GameMapTools.initAvatarDiff(_loc2_,diff);
               team2List.push(_loc2_);
               alive2List.push(_loc2_);
               _loc2_.refreshPos();
               _loc6_.addAvatar(_loc2_);
               _loc2_.fightRes.visible = false;
            }
            _loc9_++;
         }
      }
      
      public function checkBig() : void
      {
         var _loc3_:int = 0;
         var _loc1_:Avatar = null;
         if(m_data.id.indexOf("V") != -1)
         {
            return;
         }
         var _loc2_:int = 2147483647;
         _loc3_ = 0;
         while(_loc3_ < alive2List.length)
         {
            _loc1_ = alive2List[_loc3_];
            if(_loc1_ != randomAvatar)
            {
               _loc2_ = Math.min(_loc2_,_loc1_.lv);
            }
            _loc3_++;
         }
         _loc3_ = 0;
         while(_loc3_ < alive2List.length)
         {
            _loc1_ = alive2List[_loc3_];
            if(_loc1_.lv > _loc2_)
            {
               _loc1_.isBoss = true;
            }
            _loc3_++;
         }
      }
      
      public function checkAdd(param1:int, param2:int) : Boolean
      {
         var _loc3_:int = Math.round(param1 / GameMapConfig.lineOffset);
         if(_loc3_ < 0 || _loc3_ >= gameMapData.line)
         {
            return false;
         }
         if(param2 < (1 - GameMapConfig.MAX_POS_PER - 0.1) * GameMapConfig.LINE_POS)
         {
            return false;
         }
         if(param2 > 1.2 * GameMapConfig.LINE_POS)
         {
            return false;
         }
         return true;
      }
      
      public function getMyListNum() : int
      {
         var _loc2_:int = 0;
         if(!myList)
         {
            return 0;
         }
         var _loc1_:int = 0;
         _loc2_ = 0;
         while(_loc2_ < myList.length)
         {
            if(myList[_loc2_] is Array)
            {
               _loc1_++;
            }
            _loc2_++;
         }
         return _loc1_;
      }
      
      public function getSameAvatar(param1:*, param2:Boolean = false) : Avatar
      {
         var _loc4_:int = 0;
         var _loc3_:Avatar = null;
         if(param1 is Avatar && param1.isOthers || param2)
         {
            return friendAvatar;
         }
         _loc4_ = 0;
         while(_loc4_ < teamMyList.length)
         {
            _loc3_ = teamMyList[_loc4_];
            if(param1 is Avatar)
            {
               if(_loc3_.id == param1.id)
               {
                  return _loc3_;
               }
            }
            else if(_loc3_.id == param1)
            {
               return _loc3_;
            }
            _loc4_++;
         }
         return null;
      }
      
      public function addAvatar(param1:Avatar, param2:int, param3:int, param4:int, param5:Boolean = true, param6:int = -2147483648) : void
      {
         var _loc9_:* = undefined;
         param1.pos = getFinalPos(param2,param3,param4);
         if(param6 != -2147483648)
         {
            param1.offset = param6;
            myList[param1.actionNum] = [param1.id,param1.line,param1.posPer];
            GameMapTools.gameTrace(myList[param1.actionNum]);
            if(getSameAvatar(param1) == null)
            {
               if(param1.isOthers)
               {
                  friendAvatar = param1;
               }
               else
               {
                  teamMyList.push(param1);
               }
            }
         }
         else if(param2 == 1)
         {
            team1List.push(param1);
            alive1List.push(param1);
         }
         else
         {
            team2List.push(param1);
            alive2List.push(param1);
         }
         param1.refreshPos();
         param1.fightRes.scaleX = param1.fightRes.scaleY = 0;
         autoPos(param1.line,true,param1);
         var _loc8_:GameMapLayer = GameMapLayer.gl;
         _loc9_ = DisplayTools.getAttrs("ADD_AVATAR_EFF");
         _loc9_.a1 = param1;
         _loc9_.par = _loc8_.effectLayer;
         _loc8_.delayCall(DisplayTools.addEffects,actionDelay,_loc9_);
         actionDelay += 0.5 / 2;
         if(param6 != -2147483648)
         {
            _loc8_.delayCall(_loc8_.addAvatar,actionDelay,param1,-1);
            GuideMaster.getOnlyExample().nextGuideStep();
         }
         else
         {
            param1.offset = 0;
            _loc8_.delayCall(_loc8_.addAvatar,actionDelay,param1,-2);
         }
         var _loc7_:Tween = new Tween(param1.fightRes,0.5,"easeOutBack");
         _loc7_.delay = actionDelay;
         _loc7_.scaleTo(param1.getScale());
         _loc8_.addTween(_loc7_);
         actionDelay += 0.5;
      }
      
      public function getForwardPos(param1:int, param2:int) : int
      {
         var _loc6_:int = 0;
         var _loc4_:* = undefined;
         var _loc3_:Avatar = null;
         var _loc5_:int = 0;
         if(param1 == 1)
         {
            _loc4_ = alive1List;
            _loc5_ = GameMapConfig.LINE_POS;
         }
         else
         {
            _loc4_ = alive2List;
            _loc5_ = 0;
         }
         _loc6_ = 0;
         while(_loc6_ < _loc4_.length)
         {
            _loc3_ = _loc4_[_loc6_];
            if(_loc3_ && _loc3_.line == param2 && _loc3_.hp > 0)
            {
               if(param1 == 1)
               {
                  _loc5_ = Math.min(_loc5_,_loc3_.pos);
               }
               else
               {
                  _loc5_ = Math.max(_loc5_,_loc3_.pos);
               }
            }
            _loc6_++;
         }
         if(param1 == 1)
         {
            _loc5_ = Math.min(_loc5_ - GameMapConfig.MIN_SPACE_POS,GameMapConfig.LINE_POS);
         }
         else
         {
            _loc5_ = Math.max(_loc5_ + GameMapConfig.MIN_SPACE_POS,0);
         }
         return _loc5_;
      }
      
      public function getFinalPos(param1:int, param2:int, param3:int) : int
      {
         var _loc4_:int = getForwardPos(3 - param1,param2);
         if(param1 == 1)
         {
            param3 = Math.min(GameMapConfig.LINE_POS,Math.max(_loc4_,param3));
         }
         else
         {
            param3 = Math.max(0,Math.min(_loc4_,param3));
         }
         return param3;
      }
      
      public function autoSort() : void
      {
         var _loc1_:GameMapLayer = null;
         if(Avatar.iconStyle == 1)
         {
            _loc1_ = GameMapLayer.gl;
            _loc1_.sortAvatar();
         }
      }
      
      public function autoPos(param1:int, param2:Boolean = true, param3:Avatar = null) : Boolean
      {
         var _loc15_:Avatar = null;
         var _loc13_:Avatar = null;
         var _loc14_:int = 0;
         var _loc11_:int = 0;
         var _loc12_:int = 0;
         var _loc7_:* = undefined;
         var _loc17_:Tween = null;
         var _loc16_:Number = NaN;
         var _loc6_:Number = NaN;
         var _loc4_:Number = NaN;
         var _loc20_:Number = NaN;
         var _loc18_:int = 0;
         var _loc19_:int = 0;
         var _loc5_:int = 0;
         var _loc8_:int = 0;
         var _loc21_:Vector.<Avatar> = getLineAliveList(1,param1).concat(getLineAliveList(2,param1));
         var _loc10_:int = int(_loc21_.length);
         var _loc9_:GameMapLayer = GameMapLayer.gl;
         _loc5_ = 5;
         _loc12_ = 0;
         while(_loc12_ < _loc5_)
         {
            _loc20_ = 0.5;
            _loc14_ = 0;
            while(_loc14_ < _loc10_)
            {
               _loc15_ = _loc21_[_loc14_];
               if(_loc15_.avatarData.actionType == 3)
               {
                  _loc15_.offset = 0;
                  _loc15_.offsetAim = _loc15_.offset;
               }
               else
               {
                  _loc18_ = -GameMapConfig.sideOffset;
                  _loc19_ = GameMapConfig.sideOffset;
                  _loc11_ = 0;
                  while(_loc11_ < _loc10_)
                  {
                     if(_loc14_ != _loc11_)
                     {
                        _loc13_ = _loc21_[_loc11_];
                        _loc6_ = _loc15_.offset - _loc13_.offset;
                        _loc4_ = _loc15_.pos - _loc13_.pos;
                        _loc16_ = Math.sqrt(_loc6_ * _loc6_ + _loc4_ * _loc4_);
                        if(_loc16_ < 700)
                        {
                           if(_loc6_ >= 0)
                           {
                              _loc18_ = Math.max(_loc13_.offset,_loc18_);
                           }
                           else
                           {
                              _loc19_ = Math.min(_loc13_.offset,_loc19_);
                           }
                        }
                     }
                     _loc11_++;
                  }
                  _loc15_.offsetAim = (_loc18_ + _loc19_) / 2 * _loc20_ + _loc15_.offsetAim * (1 - _loc20_);
               }
               _loc14_++;
            }
            _loc14_ = 0;
            while(_loc14_ < _loc10_)
            {
               _loc15_ = _loc21_[_loc14_];
               if(_loc15_.avatarData.actionType != 3)
               {
                  _loc15_.offset = _loc15_.offsetAim * _loc20_ + _loc15_.offset * (1 - _loc20_);
               }
               _loc14_++;
            }
            _loc12_++;
         }
         _loc14_ = 0;
         while(_loc14_ < _loc10_)
         {
            _loc15_ = _loc21_[_loc14_];
            _loc16_ = GameMapConfig.offsetToPixel(_loc15_.offset);
            if(param2)
            {
               _loc17_ = new Tween(_loc15_.fightRes,0.8,"easeInOut");
               _loc17_.animate("x",_loc16_);
               _loc9_.addTween(_loc17_);
            }
            else
            {
               _loc15_.fightRes.x = _loc16_;
            }
            if(!isFight && !re)
            {
               _loc8_ = team1List.indexOf(_loc15_);
               if(_loc8_ >= 0)
               {
                  team1Offset[_loc8_] = _loc15_.offset;
               }
            }
            _loc14_++;
         }
         return true;
      }
      
      public function checkLineLose(param1:int, param2:int) : Boolean
      {
         var _loc3_:Vector.<Avatar> = getLineAliveList(param1,param2);
         if(_loc3_.length == 0)
         {
            signLineWin(3 - param1,param2);
            relineList[param2] = 3 - param1;
            return true;
         }
         return false;
      }
      
      public function relineAvatar(param1:int, param2:int) : int
      {
         var _loc7_:* = undefined;
         var _loc8_:int = 0;
         var _loc3_:Avatar = null;
         var _loc4_:int = 0;
         var _loc6_:int = 0;
         var _loc5_:int = getNaerestFightLine(param2);
         _loc7_ = getLineAliveList(param1,param2);
         _loc8_ = 0;
         while(_loc8_ < _loc7_.length)
         {
            _loc3_ = _loc7_[_loc8_];
            if(_loc3_.avatarData.actionType != 3)
            {
               _loc4_++;
            }
            else
            {
               _loc3_.removeAllBuff();
            }
            _loc8_++;
         }
         if(_loc4_ > 0)
         {
            actionDelay += 0.5;
            _loc8_ = 0;
            while(_loc8_ < _loc7_.length)
            {
               _loc3_ = _loc7_[_loc8_];
               if(_loc3_.avatarData.actionType != 3)
               {
                  _loc3_.reline(_loc5_,-2147483648,(_loc6_ - (_loc4_ - 1) / 2) / (_loc4_ + 1) * GameMapConfig.lineOffset,2,_loc6_ * 0.1);
                  _loc6_++;
               }
               _loc8_++;
            }
            return _loc5_;
         }
         return -1;
      }
      
      public function checkWin() : int
      {
         var _loc5_:int = 0;
         var _loc1_:int = 0;
         var _loc3_:int = 0;
         if(winner != 0)
         {
            return winner;
         }
         var _loc4_:int = 0;
         var _loc2_:GameMapData = gameMapData;
         if(_loc2_.win[0] == -1)
         {
            _loc1_ = 0;
            _loc5_ = 0;
            while(_loc5_ < winnerList.length)
            {
               if(winnerList[_loc5_] == 1)
               {
                  _loc4_++;
               }
               else if(winnerList[_loc5_] == 2)
               {
                  _loc1_++;
               }
               _loc5_++;
            }
            _loc5_ = Math.min(winnerList.length,2);
            if(_loc4_ >= _loc5_)
            {
               winner = 1;
            }
            else if(_loc1_ > winnerList.length - _loc5_)
            {
               winner = 2;
            }
         }
         else if(_loc2_.win[0] == -2 || _loc2_.win[0] == -3)
         {
            if(getLineAliveList(1).length == 0)
            {
               winner = 2;
            }
            else if(getLineAliveList(2).length == 0)
            {
               winner = 1;
            }
         }
         else
         {
            _loc5_ = 0;
            while(_loc5_ < _loc2_.win.length)
            {
               _loc3_ = int(_loc2_.win[_loc5_]);
               if(winnerList[_loc3_] == 1)
               {
                  _loc4_++;
               }
               else if(winnerList[_loc3_] == 2)
               {
                  winner = 2;
                  break;
               }
               _loc5_++;
            }
            if(_loc4_ >= Math.min(winnerList.length,_loc2_.win.length))
            {
               winner = 1;
            }
         }
         if(_loc2_.win[0] != -3)
         {
            if(winner == 0 && roundNum >= ROUND_MAX)
            {
               winner = 2;
            }
         }
         return winner;
      }
      
      public function checkEnd() : Boolean
      {
         var _loc2_:int = 0;
         var _loc1_:Avatar = null;
         if(winner != 0)
         {
            return true;
         }
         _loc2_ = 0;
         while(_loc2_ < team1List.length)
         {
            _loc1_ = team1List[_loc2_];
            if(_loc1_.hp > 0)
            {
               if(_loc1_.avatarData.actionType != 3)
               {
                  return false;
               }
            }
            _loc2_++;
         }
         _loc2_ = 0;
         while(_loc2_ < team2List.length)
         {
            _loc1_ = team2List[_loc2_];
            if(_loc1_.hp > 0)
            {
               if(_loc1_.avatarData.actionType != 3)
               {
                  return false;
               }
            }
            _loc2_++;
         }
         winner = 2;
         return true;
      }
      
      public function signLineWin(param1:int, param2:int) : void
      {
         if(winnerList[param2] != 0)
         {
            return;
         }
         winnerList[param2] = param1;
         checkWin();
      }
      
      public function getShowLine(param1:int) : int
      {
         var _loc3_:int = 0;
         var _loc2_:int = param1;
         _loc3_ = 0;
         while(_loc3_ < param1)
         {
            if(winnerList[_loc3_] != 0)
            {
               _loc2_--;
            }
            _loc3_++;
         }
         return _loc2_;
      }
      
      public function getNaerestFightLine(param1:int) : int
      {
         var _loc4_:int = 0;
         var _loc2_:int = 0;
         var _loc3_:* = 2147483647;
         _loc4_ = 0;
         while(_loc4_ < gameMapData.line)
         {
            if(_loc4_ != param1)
            {
               if(winnerList[_loc4_] == 0)
               {
                  _loc2_ = Math.abs(param1 - _loc4_);
                  if(_loc2_ == 1)
                  {
                     return _loc4_;
                  }
                  if(_loc2_ < Math.abs(param1 - _loc3_))
                  {
                     _loc3_ = _loc4_;
                  }
               }
            }
            _loc4_++;
         }
         return _loc3_;
      }
      
      public function getTeamList(param1:int) : Vector.<Avatar>
      {
         var _loc2_:* = undefined;
         if(param1 == 1)
         {
            _loc2_ = team1List;
         }
         else
         {
            _loc2_ = team2List;
         }
         return _loc2_;
      }
      
      public function getAliveList(param1:int) : Vector.<Avatar>
      {
         var _loc2_:* = undefined;
         if(param1 == 1)
         {
            _loc2_ = alive1List;
         }
         else
         {
            _loc2_ = alive2List;
         }
         return _loc2_;
      }
      
      public function showSpeak(param1:String, param2:Boolean) : void
      {
         var _loc4_:* = undefined;
         var _loc3_:Avatar = null;
         var _loc5_:int = 0;
         if(param2)
         {
            _loc4_ = alive1List;
         }
         else
         {
            _loc4_ = alive2List;
         }
         _loc5_ = 0;
         while(_loc5_ < _loc4_.length)
         {
            _loc3_ = _loc4_[_loc5_];
            if(_loc3_.id.indexOf(param1) != -1)
            {
               _loc3_.resSpeak();
               return;
            }
            _loc5_++;
         }
      }
      
      public function getLaneCount() : int
      {
         return gameMapData && gameMapData.line > 0 ? int(gameMapData.line) : 0;
      }
      
      public function getMissingLaneCount() : int
      {
         var _loc1_:int = 0;
         var _loc2_:int = 0;
         _loc1_ = 0;
         while(_loc1_ < getLaneCount())
         {
            if(getLineAliveList(1,_loc1_).length <= 0)
            {
               _loc2_++;
            }
            _loc1_++;
         }
         return _loc2_;
      }
      
      public function checkStart() : Boolean
      {
         return getLaneCount() > 0 && getMissingLaneCount() == 0;
      }
      
      public function getLineAliveList(param1:int, param2:int = -1, param3:Boolean = false) : Vector.<Avatar>
      {
         var _loc7_:int = 0;
         var _loc4_:Avatar = null;
         var _loc5_:Vector.<Avatar> = getAliveList(param1);
         var _loc6_:Vector.<Avatar> = new Vector.<Avatar>();
         _loc7_ = 0;
         while(_loc7_ < _loc5_.length)
         {
            _loc4_ = _loc5_[_loc7_];
            if(!(param2 >= 0 && _loc4_.line != param2))
            {
               if(!(param3 && _loc4_.avatarData.actionType == 3))
               {
                  if(_loc4_ && _loc4_.hp > 0)
                  {
                     _loc6_.push(_loc4_);
                  }
               }
            }
            _loc7_++;
         }
         return _loc6_;
      }
      
      public function getConfigLineNum(param1:int = -1) : int
      {
         var _loc4_:int = 0;
         var _loc3_:Array = null;
         var _loc2_:int = 0;
         _loc4_ = 0;
         while(_loc4_ < gameMapData.team1List.length)
         {
            _loc3_ = gameMapData.team1List[_loc4_];
            if(_loc3_[3] == param1)
            {
               _loc2_++;
            }
            _loc4_++;
         }
         return _loc2_;
      }
      
      public function replay() : void
      {
         var _loc2_:* = null;
         var _loc3_:int = 0;
         isLoad = true;
         endFight(true);
         GameMapLayer.gl.clear();
         isInit = false;
         initMap(true);
         initByOrgin(re);
         checkBig();
         startFight();
         checkOrginTeam();
         var _loc1_:GameMapLayer = GameMapLayer.gl;
         _loc1_.uiLayer.m_sprFg.visible = true;
         for each(_loc2_ in team1List.concat(team2List))
         {
            _loc2_.hideActionNum();
            _loc2_.ready();
         }
         autoSort();
         _loc3_ = 0;
         while(_loc3_ < gameMapData.line)
         {
            autoPos(_loc3_,false);
            _loc3_++;
         }
         SoundManager.getOnlyExample().setAllMusic(false);
         SoundManager.getOnlyExample().playMusic(musicId);
      }
      
      public function autoFight(param1:*) : void
      {
         reSend(param1);
      }
      
      public function replayFight() : void
      {
         GlobalData.$isFightReplay = true;
         reSend(lastRe);
      }
      
      public function loadFight(param1:*) : void
      {
         isLoadFile = true;
         reSend(param1);
      }
      
      public function sendFight() : void
      {
         var _obj:Object;
         var _team:Array;
         var i:int;
         var _list:Array;
         var _avatar:Avatar;
         var _myLength:int;
         var olddata:Object;
         var s:uint;
         var data:Object;
         var _fun:Object;
         var showpanel:*;
         var _backfunen:*;
         var _backfun:*;
         var showChangeTeampanel:*;
         var _changeTeamfun:*;
         if(MainConfig.$isFightTest)
         {
            startFight();
            return;
         }
         _obj = {};
         _team = ["","","","","",""];
         if(myList.length > 0)
         {
            if(GlobalData.$isPVE && !GlobalData.$isNoFriendToPVE && !GlobalData.$isExtreme)
            {
               _myLength = myList.length - 1;
            }
            else
            {
               _myLength = int(myList.length);
            }
            i = 0;
            while(i < _myLength)
            {
               _avatar = team1List[i];
               _list = myList[i] as Array;
               _team[_avatar.indexID_s] = _list;
               i = i + 1;
            }
            if(_myLength == myList.length - 1)
            {
               _list = myList[i] as Array;
               _team[5] = _list.concat(GlobalData.$tempHelpAvatar.uid,GlobalData.$tempHelpAvatar.isF);
            }
         }
         _obj.team = _team;
         if(GlobalData.$isPVP)
         {
            _obj.cid = null;
            _obj.rank = GlobalData.$pvp_rival["indexID_s"];
            _obj.uid = GlobalData.$pvp_rival["id"];
            if(GlobalFunction.checkIsFirstPVP())
            {
               _obj.rank = 0;
            }
         }
         else if(GlobalData.$isFragment)
         {
            _obj.fragment_index = GlobalData.$fragment_data["indexID_s"];
            _obj.eid = GlobalData.$fragment_data["eid"];
            _obj.uid = GlobalData.$fragment_data["uid"];
         }
         else if(!GlobalData.$isBattleOfThePeak)
         {
            if(!GlobalData.$isExploration)
            {
               if(!GlobalData.$isExtreme)
               {
                  _obj.cid = gameMapData.id;
                  _obj.diff = diff;
               }
            }
         }
         _obj.team_num = GlobalData.$tempTeamID;
         if(GlobalData.$isPVP)
         {
            GlobalData.$isFightReplay = false;
            _team.pop();
            SendServiceAMFFun.send_user_pk_combat_pvp(reSend,_obj);
         }
         else if(GlobalData.$isFragment)
         {
            GlobalData.$isFightReplay = false;
            _team.pop();
            SendServiceAMFFun.send_user_pk_combat_fragment(reSend,_obj);
         }
         else if(GlobalData.$isExploration)
         {
            GlobalData.$isFightReplay = false;
            _team.pop();
            SendServiceAMFFun.send_user_exploration_combat(reSend,_obj);
         }
         else if(GlobalData.$isBattleOfThePeak)
         {
            GlobalData.$isFightReplay = false;
            _team.pop();
            olddata = GlobalData.$m15v15FightData;
            s = 0;
            while(s < olddata.data.combat_res.length)
            {
               olddata.data.combat_res[s].Screenings = s + 1;
               s = s + 1;
            }
            data = {};
            data.data = GlobalData.$m15v15FightData.data.combat_res[0];
            data.data.users = olddata.data.users;
            (GlobalData.$m15v15FightData.data.combat_res as Array).shift();
            data.data.glod = GlobalData.$userData.gold;
            data.data.combat_score = GlobalData.$userData.combat_score;
            reSend(data);
         }
         else if(GlobalData.$isExtreme)
         {
            showpanel = function():void
            {
               var _loc1_:* = 0;
               GlobalData.$setExtreme();
               if(!GlobalData.$userData.isGuildWarSaiCheng)
               {
                  SendServiceAMFFun.send_user_get_extreme_signup(_backfun,{"team":_team});
               }
               else
               {
                  _loc1_ = 0;
                  if(GlobalData.$userData.BMtype == 2)
                  {
                     _loc1_ = 2;
                  }
                  else
                  {
                     if(!(GlobalData.$userData.BMtype = 3))
                     {
                        return;
                     }
                     _loc1_ = 3;
                  }
                  SendServiceAMFFun.send_user_operator_association_war(_backfunen,{
                     "team":_team,
                     "type":_loc1_
                  });
               }
            };
            _backfunen = function(param1:Object):void
            {
               if(param1.data.res_code == -2)
               {
                  GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97835),true);
                  GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
                  return;
               }
               trace(param1);
               if(param1.data)
               {
                  if(!GlobalFunction.isVersionedProfileReceipt(param1)) { GlobalData.$userData.coin = param1.data.coin; }
                  GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
               }
               GlobalData.$mGameClassObject.closePopForPanel();
            };
            _backfun = function():void
            {
               if(GlobalData.$useExtreme.is_signup)
               {
                  LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getStr(90530));
               }
               else
               {
                  LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getStr(90529));
               }
               GlobalData.$useExtreme.is_signup = true;
               GlobalData.$mEventDispatcher.dispatchEventWith("update_signup");
               GlobalData.$mGameClassObject.closePopForPanel();
            };
            showChangeTeampanel = function():void
            {
               GlobalData.$setExtreme();
               SendServiceAMFFun.send_user_get_extreme_change_team(_changeTeamfun,{"team":_team});
            };
            _changeTeamfun = function(param1:Object):void
            {
               var _arr:Array;
               var _data:Object;
               var _re:Object = param1;
               var _fun:* = function(param1:Object):void
               {
                  GlobalData.$tempExtremeBetTeam = param1.data;
                  GlobalData.$mGameClassObject.closePopForPanel(2);
                  GlobalData.$mEventDispatcher.dispatchEventWith("update_PanelPVPEliteBet");
               };
               if(!GlobalFunction.isVersionedProfileReceipt(_re)) { GlobalData.$userData.coin = _re.data.coin; }
               if(!GlobalFunction.isVersionedProfileReceipt(_re)) { GlobalData.$userData.vip_lv = _re.data["vip_lv"]; }
               if(!GlobalFunction.isVersionedProfileReceipt(_re)) { GlobalData.$userData.vip_exp = _re.data["vip_exp"]; }
               GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateVip();
               GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
               _arr = GlobalData.$tempExtremeBetUser;
               _data = {"users":[[_arr[0][0],_arr[0][1]],[_arr[1][0],_arr[1][1]]]};
               SendServiceAMFFun.send_user_get_battle_users(_fun,_data);
            };
            _team.pop();
            if(GlobalData.$tempIsApplyorChangeTeam)
            {
               _fun = {
                  "ok":showChangeTeampanel,
                  "no":GlobalFunction.functionNull,
                  "aid":"A_2009_5"
               };
               GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90287),GlobalTextStyle.COLOR_W_Y_Y_G),_fun);
            }
            else
            {
               _fun = {
                  "ok":showpanel,
                  "no":GlobalFunction.functionNull,
                  "aid":"A_2009_5"
               };
               GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90271),GlobalTextStyle.COLOR_W_Y_Y_G),_fun);
            }
         }
         else
         {
            SendServiceAMFFun.send_user_pk_combat_main(reSend,_obj);
         }
      }
      
      public function reSend(param1:* = null) : void
      {
         var _loc3_:Object = null;
         var _loc4_:* = 0;
         var _loc2_:Boolean = false;
         if(re)
         {
            return;
         }
         if(GlobalData.$isExploration)
         {
            GlobalData.backFromExploration = true;
            GlobalData.$setPVE;
            if(!GlobalFunction.isVersionedProfileReceipt(param1)) { GlobalData.$userData.exploration.current_stage_finish = param1.data.current_stage_finish; }
            if(!GlobalFunction.isVersionedProfileReceipt(param1)) { GlobalData.$userData.exploration.stage = param1.data.stage; }
            if(!GlobalFunction.isVersionedProfileReceipt(param1)) { GlobalData.$userData.records.exploration_times.mode_buy = param1.data.mode_buy; }
            if(!GlobalFunction.isVersionedProfileReceipt(param1)) { GlobalData.$userData.exploration.combat_army = param1.data.combat_army; }
            if(!GlobalFunction.isVersionedProfileReceipt(param1)) { GlobalData.$userData.exploration.army = param1.data.army; }
         }
         if(param1)
         {
            SoundManager.getOnlyExample().playSound("sound01",1.3);
            re = param1;
            _loc3_ = re.data;
            randomSeed = _loc3_.seed;
            GlobalData.$poke_Data = re.data.poke_data;
            if(!GlobalData.$isPVE)
            {
               initByOrgin(re);
            }
            else
            {
               if(isLoad || GameMapLayer.isAuto || GlobalData.$tempPVE_type == "status_pve_guild")
               {
                  initByOrgin(re);
                  if(GlobalData.$tempPVE_type == "status_pve_guild")
                  {
                     _loc4_ = 0;
                     while(_loc4_ < param1.data.orgin_team_b.length)
                     {
                        team2List[_loc4_].hp = param1.data.orgin_team_b[_loc4_].hp;
                        _loc4_++;
                     }
                  }
               }
               else
               {
                  if(_loc3_.friend_avatar && friendAvatar)
                  {
                     friendAvatar.reInit(_loc3_.friend_avatar);
                  }
                  addRandom();
               }
               if(!GlobalData.$currentGuide)
               {
                  if(_loc3_.sign == 1)
                  {
                     _loc2_ = GlobalFunction.check_pass_combat(gameMapData.id) != 1;
                  }
               }
               firstTeam = 1;
            }
         }
         checkOrginTeam();
         readyFight();
      }
      
      public function checkOrginTeam(param1:* = null) : void
      {
         var _loc8_:Array = null;
         var _loc10_:int = 0;
         var _loc2_:Avatar = null;
         var _loc7_:* = undefined;
         var _loc5_:Object = null;
         var _loc4_:String = null;
         if(!re)
         {
            return;
         }
         var _loc9_:Object = re.data;
         var _loc6_:GameMapLayer = GameMapLayer.gl;
         var _loc3_:Boolean = true;
         initTeam1 = [];
         initTeam2 = [];
         GameMapTools.beginOriginCheck();
         GameMapTools.gameTrace("===【開始校驗】===");
         _loc8_ = _loc9_.orgin_team_a;
         if(!_loc8_)
         {
            GameMapTools.gameTrace("未收到我方初始數據");
         }
         else
         {
            _loc10_ = 0;
            while(_loc10_ < team1List.length)
            {
               _loc2_ = team1List[_loc10_];
               _loc5_ = _loc2_.toDataObj();
               initTeam1.push(_loc5_);
               _loc7_ = _loc8_[_loc10_];
               GameMapTools.gameTrace("校驗我方第" + _loc10_ + "位，戰力：" + _loc2_.getPower(_loc2_.isLeader));
               if(!GameMapTools.compareData(_loc5_,_loc7_,"teamA[" + _loc10_ + "]"))
               {
                  _loc3_ = false;
               }
               _loc10_++;
            }
         }
         _loc8_ = _loc9_.orgin_team_b;
         if(!_loc8_)
         {
            GameMapTools.gameTrace("未收到敵方初始數據");
         }
         else
         {
            _loc10_ = 0;
            while(_loc10_ < team2List.length)
            {
               _loc2_ = team2List[_loc10_];
               _loc5_ = _loc2_.toDataObj();
               initTeam2.push(_loc5_);
               _loc7_ = _loc8_[_loc10_];
               GameMapTools.gameTrace("校驗敵方第" + _loc10_ + "位，戰力：" + _loc2_.getPower(_loc2_.isLeader));
               if(!GameMapTools.compareData(_loc5_,_loc7_,"teamB[" + _loc10_ + "]"))
               {
                  _loc3_ = false;
               }
               _loc10_++;
            }
         }
         GameMapTools.gameTrace("===【校驗結束】===");
         if(!_loc3_)
         {
            GameMapTools.reportOriginMismatch(gameMapData ? gameMapData.id : "unknown");
            _loc4_ = GlobalLanguageStr.getLanguageStr(46099);
            _loc4_ = Tools.formatLineX(_loc4_,GlobalTextStyle.COLOR_W_Y_Y_G);
            GlobalFunction.popAlert("",_loc4_);
         }
      }
      
      public function initByOrgin(param1:*) : void
      {
         var _loc3_:Array = null;
         var _loc4_:Array = null;
         var _loc8_:Array = null;
         var _loc10_:int = 0;
         var _loc2_:Avatar = null;
         var _loc7_:* = undefined;
         var _loc5_:int = 0;
         if(!param1)
         {
            return;
         }
         var _loc9_:Object = param1.data;
         var _loc6_:GameMapLayer = GameMapLayer.gl;
         _loc3_ = _loc9_.client_orgin_team_a;
         _loc4_ = _loc9_.client_orgin_team_b;
         if(!_loc3_ || !_loc4_)
         {
            _loc3_ = _loc9_.orgin_team_a;
            _loc4_ = _loc9_.orgin_team_b;
            if(!_loc3_ || !_loc4_)
            {
               return;
            }
         }
         else
         {
            GameMapTools.gameTrace("自動使用原有前端初始化！！！！！！");
         }
         teamMyList = new Vector.<Avatar>();
         friendAvatar = null;
         team1List = new Vector.<Avatar>();
         team2List = new Vector.<Avatar>();
         alive1List = new Vector.<Avatar>();
         alive2List = new Vector.<Avatar>();
         _loc6_.clearAvatar();
         _loc8_ = _loc3_;
         _loc5_ = int(_loc8_.length);
         _loc10_ = 0;
         while(_loc10_ < _loc5_)
         {
            _loc7_ = _loc8_[_loc10_];
            _loc2_ = new Avatar(_loc7_.aid,_loc7_);
            _loc2_.goFight(1,_loc7_.line,1 - _loc7_.pos / GameMapConfig.LINE_POS,_loc7_.leader);
            team1List.push(_loc2_);
            alive1List.push(_loc2_);
            if(team1Offset && team1Offset.length > _loc10_)
            {
               _loc2_.offset = team1Offset[_loc10_];
            }
            else
            {
               _loc2_.offset = ((_loc10_ + 1) / (_loc5_ + 1) - 0.5) * GameMapConfig.sideOffset;
            }
            _loc2_.refreshPos();
            _loc6_.addAvatar(_loc2_,Math.max(0,-1));
            _loc10_++;
         }
         _loc8_ = _loc4_;
         _loc5_ = int(_loc8_.length);
         _loc10_ = 0;
         while(_loc10_ < _loc5_)
         {
            _loc7_ = _loc8_[_loc10_];
            _loc2_ = new Avatar(_loc7_.aid,_loc7_);
            _loc2_.goFight(2,_loc7_.line,_loc7_.pos / GameMapConfig.LINE_POS,_loc7_.leader);
            _loc2_.offset = ((_loc10_ + 1) / (_loc5_ + 1) - 0.5) * GameMapConfig.sideOffset;
            team2List.push(_loc2_);
            alive2List.push(_loc2_);
            _loc2_.refreshPos();
            _loc6_.addAvatar(_loc2_,Math.max(0,-1));
            _loc10_++;
         }
         _loc10_ = 0;
         while(_loc10_ < gameMapData.line)
         {
            autoPos(_loc10_,team1Offset);
            _loc10_++;
         }
         if(_loc9_.def_th == 0)
         {
            firstTeam = 2;
         }
         else if(_loc9_.def_th == 1)
         {
            firstTeam = 1;
         }
         else if(_loc9_.my_pr_power)
         {
            if(_loc9_.my_pr_power >= _loc9_.pr_power)
            {
               firstTeam = 1;
            }
            else
            {
               firstTeam = 2;
            }
         }
         else
         {
            firstTeam = 1;
         }
      }
      
      public function hasRandom() : Boolean
      {
         if(!re)
         {
            return false;
         }
         if(!re.data)
         {
            return false;
         }
         if(!re.data.random_av)
         {
            return false;
         }
         return true;
      }
      
      public function addRandom() : void
      {
         var _loc2_:Object = null;
         var _loc3_:Array = null;
         var _loc1_:Avatar = null;
         var _loc4_:GameMapLayer = null;
         if(!re)
         {
            return;
         }
         if(isLoad)
         {
            return;
         }
         var _loc5_:Object = re.data;
         if(_loc5_.random_av)
         {
            _loc2_ = GlobalFunction.getRndAvatarObj(diff);
            _loc3_ = _loc2_.random_team;
            _loc1_ = new Avatar(_loc3_[1],{
               "lv":_loc3_[2],
               "slv":_loc3_[3]
            });
            _loc1_.goFight(2,_loc5_.random_av.line,_loc5_.random_av.pos,_loc3_[6]);
            gameMapData.initAvatarNew4attrs(_loc1_);
            GameMapTools.initAvatarDiff(_loc1_,diff);
            this.team2List.splice(_loc5_.random_av.mark,0,_loc1_);
            this.alive2List.splice(_loc5_.random_av.mark,0,_loc1_);
            _loc1_.refreshPos();
            _loc4_ = GameMapLayer.gl;
            randomAvatar = _loc1_;
         }
      }
      
      public function sendErrorLog(param1:Boolean = false) : void
      {
         var _loc10_:int = 0;
         var _loc7_:Array = null;
         var _loc2_:Avatar = null;
         var _loc9_:int = 0;
         var _loc5_:Object = null;
         if(!param1 && isGetErrlog)
         {
            return;
         }
         var _loc3_:Object = {};
         var _loc4_:Array = ["","","","","",""];
         if(myList.length > 0)
         {
            if(GlobalData.$isPVE && !GlobalData.$isNoFriendToPVE)
            {
               _loc9_ = myList.length - 1;
            }
            else
            {
               _loc9_ = int(myList.length);
            }
            _loc10_ = 0;
            while(_loc10_ < _loc9_)
            {
               _loc2_ = team1List[_loc10_];
               _loc7_ = myList[_loc10_] as Array;
               _loc4_[_loc2_.indexID_s] = _loc7_;
               _loc10_++;
            }
            if(_loc9_ == myList.length - 1)
            {
               _loc7_ = myList[_loc10_] as Array;
               _loc4_[5] = _loc7_.concat(GlobalData.$tempHelpAvatar.uid,GlobalData.$tempHelpAvatar.isF);
            }
         }
         var _loc8_:Array = [];
         var _loc6_:Array = [];
         _loc10_ = 0;
         while(_loc10_ < team1List.length)
         {
            _loc5_ = {};
            _loc5_.aid = team1List[_loc10_].avatarData.id;
            _loc5_.hp = team1List[_loc10_].hp;
            _loc5_.hp_max = team1List[_loc10_].hpMax;
            _loc5_.line = team1List[_loc10_].line;
            if(team1List[_loc10_].talent)
            {
               _loc5_.talent = team1List[_loc10_].talent.id;
            }
            _loc5_.pos = team1List[_loc10_].pos;
            _loc8_.push(_loc5_);
            _loc10_++;
         }
         _loc10_ = 0;
         while(_loc10_ < team2List.length)
         {
            _loc5_ = {};
            _loc5_.aid = team2List[_loc10_].avatarData.id;
            _loc5_.hp = team2List[_loc10_].hp;
            _loc5_.hp_max = team2List[_loc10_].hpMax;
            _loc5_.line = team2List[_loc10_].line;
            _loc5_.pos = team2List[_loc10_].pos;
            if(team2List[_loc10_].talent)
            {
               _loc5_.talent = team2List[_loc10_].talent.id;
            }
            _loc6_.push(_loc5_);
            _loc10_++;
         }
         _loc3_.seed = re.data.seed;
         _loc3_.team = _loc4_;
         _loc3_.cid = gameMapData.id;
         _loc3_.client_team_a = _loc8_;
         _loc3_.client_team_b = _loc6_;
         _loc3_.orgin_team_a = re.data.orgin_team_a;
         _loc3_.orgin_team_b = re.data.orgin_team_b;
         _loc3_.sign = winner;
         if(GlobalData.$isPVP)
         {
            _loc3_.def_th = re.data.def_th;
            _loc3_.cid = re.data.cid;
         }
         else if(GlobalData.$isFragment)
         {
            _loc3_.def_th = re.data.def_th;
            _loc3_.cid = re.data.cid;
         }
         else if(GlobalData.$isExtreme)
         {
            _loc3_.def_th = re.data.def_th;
            _loc3_.cid = re.data.cid;
         }
         else if(GlobalData.$isExploration)
         {
            _loc3_.def_th = re.data.def_th;
            _loc3_.cid = re.data.cid;
         }
         else if(GlobalData.$isBattleOfThePeak)
         {
            _loc3_.def_th = re.data.def_th;
            _loc3_.cid = re.data.cid;
         }
         else
         {
            _loc3_.diff = diff;
            _loc3_.client_orgin_team_a = initTeam1;
            _loc3_.client_orgin_team_b = initTeam2;
         }
         GameMapTools.gameTrace("發出ErrLog");
         SendServiceAMFFun.send_user_pk_combat_errlog(reErrorLog,_loc3_);
      }
      
      public function reErrorLog(param1:* = null) : void
      {
      }
      
      public function readyFight() : void
      {
         var _loc2_:Tween = null;
         LayoutUIAnimation.getOnlyExample().clearAnimationLayer();
         isClear = false;
         var _loc3_:GameMapLayer = GameMapLayer.gl;
         _loc3_.doorLayer.doorClose();
         _loc3_.mgLayer.touchable = false;
         SoundManager.getOnlyExample().setAllMusic(false);
         SoundManager.getOnlyExample().playMusic(musicId);
         var _loc1_:Number = DoorLayer.DOOR_MOVE_TIME * 2 + DoorLayer.DOOR_STOP_TIME;
         if(re && !GlobalData.$isPVE)
         {
            _loc1_ += DoorLayer.PVP_ADD_TIME;
         }
         _loc2_ = new Tween(this,_loc1_);
         _loc2_.onComplete = startFight;
         _loc3_.addTween(_loc2_);
         _loc3_.uiLayer.refreashRound(0);
         autoSort();
         checkBig();
         if(!MainConfig.$isFightTest)
         {
            GlobalData.$mGameClassObject.touchable = false;
         }
      }
      
      public function readyDrop() : void
      {
         var _loc2_:* = null;
         var _loc4_:int = 0;
         var _loc3_:* = undefined;
         var _loc1_:Object = null;
         if(re && re.data && re.data.sign == 1)
         {
            _loc1_ = re.data.get_avatars;
            if(_loc1_)
            {
               for each(_loc3_ in _loc1_)
               {
                  _loc4_ = int(_loc3_.i);
                  if(_loc4_ < team2List.length)
                  {
                     team2List[_loc4_].isDrop = true;
                  }
               }
            }
         }
         else
         {
            for each(_loc2_ in team2List)
            {
               _loc2_.isDrop = Random.getRandom2() < _loc2_.dropRate * 100;
            }
         }
      }
      
      public function startFight(param1:Boolean = true) : void
      {
         var _loc3_:Array = null;
         if(param1)
         {
            _loc3_ = gameMapData.preStory;
            if(_loc3_)
            {
               if(GuideTools.hasDonePreStory(gameMapData.id) == false)
               {
                  GlobalData.$mGameClassObject.touchable = true;
                  GuideMaster.getOnlyExample().initStory(_loc3_);
                  roundNum = 0;
                  GuideTools.doPreStory(gameMapData.id);
                  return;
               }
            }
         }
         if(!MainConfig.$isFightTest)
         {
            GlobalData.$mGameClassObject.touchable = true;
         }
         else
         {
            autoSort();
         }
         roundTeam = firstTeam;
         roundNum = 0;
         team1Num = 0;
         team2Num = 0;
         damageNum = 0;
         isFight = true;
         actionDelay = 0;
         Random.seed2 = Random.seed = randomSeed;
         Random.seedNum = 0;
         readyDrop();
         var _loc2_:GameMapLayer = GameMapLayer.gl;
         if(!checkEnd())
         {
            _loc2_.delayCall(_loc2_.infoLayer.addStartFight,0.5);
            _loc2_.delayCall(SoundManager.getOnlyExample().playSound,0.7,"startFight",0.9);
            _loc2_.delayCall(beginFight,2);
            _loc2_.uiLayer.addName();
         }
      }
      
      public function beginFight() : void
      {
         var _loc2_:Number = NaN;
         var _loc1_:Tween = null;
         var _loc4_:* = undefined;
         var _loc3_:GameMapLayer = GameMapLayer.gl;
         GameMapLayer.isReady = true;
         _loc3_.uiLayer.refreashRound(roundNum + 1);
         if(randomAvatar && !isLoad)
         {
            _loc2_ = 2.5;
            _loc3_.infoLayer.randomIn(GlobalLanguageStr.getLanguageStr(20211),randomAvatar);
            randomAvatar.fightRes.scaleX = randomAvatar.fightRes.scaleY = 0;
            _loc3_.addAvatar(randomAvatar,-1);
            _loc1_ = new Tween(randomAvatar.fightRes,2.8 / 6,"easeInOut");
            _loc1_.delay = _loc2_;
            _loc1_.scaleTo(randomAvatar.getScale());
            _loc3_.addTween(_loc1_);
            _loc4_ = DisplayTools.getAttrs("RANDOM_AVATAR_EFF");
            _loc4_.a1 = randomAvatar;
            _loc4_.par = _loc3_.effectLayer;
            _loc3_.delayCall(DisplayTools.addEffects,_loc2_,_loc4_);
            _loc3_.delayCall(autoPos,_loc2_,randomAvatar.line,true,randomAvatar);
            _loc3_.delayCall(nextAction,_loc2_ + 1);
         }
         else
         {
            nextAction();
         }
      }
      
      public function endFight(param1:Boolean = false, param2:Boolean = false) : void
      {
         var _loc7_:int = 0;
         var _loc15_:* = undefined;
         var _loc10_:String = null;
         var _loc13_:String = null;
         var _loc11_:Boolean = false;
         var _loc8_:Array = null;
         var _loc6_:* = undefined;
         var _loc5_:* = undefined;
         var _loc14_:String = null;
         if(param2 && roundNum == 0 && !GlobalData.$userData.GameMap)
         {
            startFight(false);
            return;
         }
         GameMapLayer.isReady = false;
         if(!isFight && !param2)
         {
            return;
         }
         isFight = false;
         if(currentAvatar)
         {
            currentAvatar.hideRange();
            autoPos(currentAvatar.line,true,currentAvatar);
            currentAvatar = null;
         }
         var _loc16_:Number = 1.5;
         if(param2)
         {
            _loc16_ = 0;
         }
         var _loc4_:Boolean = true;
         // Submit before the chapter-story handoff below. That branch can
         // return early after a first clear; the server receipt must still be
         // requested for the actual completed, server-issued battle.
         if(!param1 && !param2 && re && re.data && re.data.fight_id &&
            (re.data.fight_kind == "main" || re.data.fight_kind == "main_hard" ||
             re.data.fight_kind == "activity" || re.data.fight_kind == "exploration" ||
             re.data.fight_kind == "pvp" || re.data.fight_kind == "fragment") &&
            !isLoad && !settlementSent)
         {
            settlementSent = true;
            settlementPending = true;
            submitBattleFinish();
         }
         if(!param1 && re)
         {
            _loc15_ = re.data;
            _loc11_ = true;
            if(diff == 0 && !param2)
            {
               if(_loc15_.next_cid && gameMapData.battleId != GameMapData.getBattleId(_loc15_.next_cid))
               {
                  _loc4_ = false;
                  _loc8_ = gameMapData.story;
                  if(_loc8_)
                  {
                     GuideMaster.getOnlyExample().initStory(gameMapData.story);
                     return;
                  }
               }
            }
            GlobalData.$userData.GameMap = false;
            _loc6_ = _loc15_.server_team_a;
            _loc5_ = _loc15_.server_team_b;
            if(_loc6_ && _loc5_)
            {
               _loc10_ = _loc15_.seed;
               _loc13_ = "" + Random.seed;
               GameMapTools.gameTrace("*****種子：" + Random.seed + " / " + _loc15_.seed);
               _loc10_ = _loc15_.sign;
               _loc13_ = "" + winner;
               GameMapTools.gameTrace("*****勝負：" + winner + "/" + _loc15_.sign);
               _loc11_ &&= _loc10_ == _loc13_;
               GameMapTools.gameTrace("我方***************");
               _loc7_ = 0;
               while(_loc7_ < team1List.length)
               {
                  _loc10_ = team1List[_loc7_].avatarData.id + ":    HP:" + team1List[_loc7_].hp + "/" + team1List[_loc7_].hpMax + ",    " + team1List[_loc7_].line + "路" + team1List[_loc7_].pos;
                  if(_loc6_[_loc7_])
                  {
                     _loc13_ = _loc6_[_loc7_].aid + ":    HP:" + _loc6_[_loc7_].hp + "/" + _loc6_[_loc7_].hp_max + ",    " + _loc6_[_loc7_].line + "路" + _loc6_[_loc7_].pos;
                  }
                  else
                  {
                     _loc13_ = "";
                  }
                  GameMapTools.gameTrace(_loc10_);
                  GameMapTools.gameTrace(_loc13_,_loc10_ == _loc13_);
                  _loc11_ &&= _loc10_ == _loc13_;
                  _loc7_++;
               }
               GameMapTools.gameTrace("敵方***************");
               _loc7_ = 0;
               while(_loc7_ < team2List.length)
               {
                  _loc10_ = team2List[_loc7_].avatarData.id + ":    HP:" + team2List[_loc7_].hp + "/" + team2List[_loc7_].hpMax + ",    " + team2List[_loc7_].line + "路" + team2List[_loc7_].pos;
                  if(_loc5_[_loc7_])
                  {
                     _loc13_ = _loc5_[_loc7_].aid + ":    HP:" + _loc5_[_loc7_].hp + "/" + _loc5_[_loc7_].hp_max + ",    " + _loc5_[_loc7_].line + "路" + _loc5_[_loc7_].pos;
                  }
                  else
                  {
                     _loc13_ = "";
                  }
                  GameMapTools.gameTrace(_loc10_);
                  GameMapTools.gameTrace(_loc13_,_loc10_ == _loc13_);
                  _loc11_ &&= _loc10_ == _loc13_;
                  _loc7_++;
               }
               if(!_loc11_)
               {
                  _loc14_ = Tools.getArrayRandom(GlobalFunction.ROLL_LIST);
                  _loc14_ = Tools.formatLineX(_loc14_,GlobalTextStyle.COLOR_W_Y_Y_G);
                  GlobalFunction.popAlert("",_loc14_);
                  sendErrorLog();
               }
            }
         }
         SoundManager.getOnlyExample().fadeMusic();
         var _loc3_:GameMapLayer = GameMapLayer.gl;
         var _loc9_:int = GameMapConfig.FIGHT_WIDTH / 2;
         var _loc12_:int = GameMapConfig.FIGHT_HEIGHT / 4;
         _loc3_.delayCall(_loc3_.uiLayer.addWinSign,_loc16_,"",winner);
         _loc3_.delayCall(_loc3_.infoLayer.addCombatSign,_loc16_,winner,_loc9_,_loc12_);
         _loc7_ = 0;
         while(_loc7_ < relineList.length)
         {
            _loc3_.delayCall(_loc3_.uiLayer.changeSignBar,_loc16_,_loc7_,winnerList[_loc7_]);
            _loc7_++;
         }
         if(winner == 1 || isLoadFile)
         {
            _loc3_.delayCall(SoundManager.getOnlyExample().playSound,_loc16_,"combatWin");
         }
         else if(winner == 2)
         {
            _loc3_.delayCall(SoundManager.getOnlyExample().playSound,_loc16_,"lose");
         }
         if(!GlobalData.$currentGuide)
         {
         }
      }
      
      public function retryBattleFinish() : void
      {
         if(settlementPending && re && re.data && re.data.fight_id)
         {
            submitBattleFinish();
         }
      }

      private function submitBattleFinish() : void
      {
         var snapshots:Object = {"team_a":[],"team_b":[]};
         var i:int = 0;
         var survivors:int = 0;
         var request:Object = {};
         var self:GameMap = this;
         while(i < team1List.length)
         {
            snapshots.team_a.push(team1List[i].toDataObj());
            if(team1List[i].hp > 0) survivors++;
            i++;
         }
         i = 0;
         while(i < team2List.length)
         {
            snapshots.team_b.push(team2List[i].toDataObj());
            i++;
         }
         request.fight_id = re.data.fight_id;
         request.fight_kind = re.data.fight_kind ? re.data.fight_kind : "main";
         request.metadata = re.data.metadata ? re.data.metadata : {};
         request.cid = gameMapData.id;
         request.diff = diff;
         request.sign = winner;
         request.combat_star = winner == 1 ? Math.max(1,Math.min(3,survivors)) : 0;
         request.teams = snapshots;
         var finishMethod:String = request.fight_kind == "main" || request.fight_kind == "main_hard" ? "user.pve_finish" : "user.battle_finish";
         SendServiceAMFFun.send_user_battle_finish(function(reply:Object):void
         {
            var key:String;
            var merged:Object = {};
            var original:Object = self.re;
            if(!reply || !reply.data || reply.return_code != 0)
            {
               return;
            }
            if(original && original.data)
            {
               for(key in original.data) merged[key] = original.data[key];
            }
            for(key in reply.data) merged[key] = reply.data[key];
            reply.data = merged;
            if(merged.poke_data && merged.poke_data.gift_list)
            {
               GlobalData.$poke_Data = merged.poke_data;
            }
            if(original) reply.params = original.params;
            self.re = reply;
            self.settlementPending = false;
            var layer:GameMapLayer = GameMapLayer.gl;
            if(layer && layer.uiLayer) layer.uiLayer.setCanReturn();
         },request,"battle_finish_" + request.fight_kind + "_" + request.fight_id,finishMethod);
      }

      public function isEnd(param1:int = -1) : Boolean
      {
         if(winner != 0)
         {
            return true;
         }
         if(param1 < 0)
         {
            return false;
         }
         if(winnerList[param1] != 0)
         {
            return true;
         }
         return false;
      }
      
      public function startAction(param1:Avatar) : void
      {
         currentAvatar = param1;
      }
      
      public function endAction() : void
      {
         var _loc3_:int = 0;
         actionDelay = 0.4;
         var _loc1_:GameMapLayer = GameMapLayer.gl;
         if(currentAvatar)
         {
            currentAvatar.hideRange();
            if(GameMapLayer.isFastest)
            {
               _loc1_.juggler.removeTweens(currentAvatar.fightRes);
               currentAvatar.refreshPos();
            }
         }
         if(winner)
         {
            endFight();
            return;
         }
         if(currentAvatar)
         {
            autoPos(currentAvatar.line,true,currentAvatar);
            currentAvatar = null;
         }
         var _loc2_:int = -1;
         _loc3_ = 0;
         while(_loc3_ < relineList.length)
         {
            if(relineList[_loc3_] != 0)
            {
               if(!isEnd())
               {
                  _loc2_ = relineAvatar(relineList[_loc3_],_loc3_);
               }
               relineList[_loc3_] = 0;
            }
            _loc3_++;
         }
         if(_loc2_ >= 0)
         {
            actionDelay += 2.8;
            _loc1_.delayCall(autoPos,actionDelay,_loc2_);
            _loc1_.delayCall(_loc1_.closeLine,actionDelay - 2.0999999999999996);
            actionDelay += 2 / 2;
         }
         _loc1_.delayCall(autoSort,actionDelay);
         _loc1_.delayCall(nextAction,actionDelay);
      }
      
      public function nextAction() : void
      {
         var _loc3_:int = 0;
         if(winner != 0)
         {
            return;
         }
         var _loc1_:Boolean = false;
         var _loc2_:GameMapLayer = GameMapLayer.gl;
         if(team1Num >= team1List.length && team2Num >= team2List.length)
         {
            roundNum = roundNum + 1;
            team1Num = 0;
            team2Num = 0;
            roundTeam = firstTeam;
            if(gameMapData.win[0] == -3)
            {
               if(roundNum == GlobalData.$mConfig_simple.battle[5] - 1)
               {
                  _loc2_.uiLayer.refreashRound(roundNum + 1);
                  _loc2_.infoLayer.addDeadMode();
                  _loc3_ = 0;
                  while(_loc3_ < gameMapData.line)
                  {
                     _loc2_.getLineBg(_loc3_).changeBg("m006",2);
                     _loc3_++;
                  }
                  _loc2_.delayCall(nextAction,5);
                  return;
               }
            }
            else if(roundNum >= ROUND_MAX)
            {
               winner = 2;
               endFight();
               return;
            }
            GameMapLayer.gl.uiLayer.refreashRound(roundNum + 1);
         }
         if(roundTeam == 1)
         {
            _loc3_ = team1Num;
            while(_loc3_ < team1List.length)
            {
               if(team1List[_loc3_] && team1List[_loc3_].checkAction())
               {
                  _loc1_ = true;
                  break;
               }
               _loc3_++;
            }
            team1Num = _loc3_ + 1;
            roundTeam = 2;
         }
         else if(roundTeam == 2)
         {
            _loc3_ = team2Num;
            while(_loc3_ < team2List.length)
            {
               if(team2List[_loc3_] && team2List[_loc3_].checkAction())
               {
                  _loc1_ = true;
                  break;
               }
               _loc3_++;
            }
            team2Num = _loc3_ + 1;
            roundTeam = 1;
         }
         if(_loc1_)
         {
            GlobalData.$userData.GameMap = true;
         }
         trace("回合数++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++" + roundNum);
         if(!_loc1_)
         {
            nextAction();
         }
      }
      
      public function clearAvatarList(param1:Boolean = false) : void
      {
         var _loc2_:* = null;
         if(team1List)
         {
            for each(_loc2_ in team1List)
            {
               param1 ? _loc2_.clearRes() : _loc2_.clear();
            }
         }
         team1List = null;
         if(team2List)
         {
            for each(_loc2_ in team2List)
            {
               param1 ? _loc2_.clearRes() : _loc2_.clear();
            }
         }
         team2List = null;
      }
      
      public function clear(param1:Boolean = true) : void
      {
         var _loc2_:* = null;
         GameMapLayer.gl.clear();
         if(param1)
         {
            SoundManager.getOnlyExample().setAllMusic(false);
            SoundManager.getOnlyExample().playMusic(SoundManager.SOUND_MAIN);
         }
         isFight = false;
         isInit = false;
         myList = null;
         if(friendAvatar)
         {
            friendAvatar.clear();
            friendAvatar = null;
         }
         if(randomAvatar)
         {
            randomAvatar.clear();
            randomAvatar = null;
         }
         if(teamMyList)
         {
            for each(_loc2_ in teamMyList)
            {
               _loc2_.clear();
            }
            teamMyList = null;
         }
         clearAvatarList();
         team1Offset = null;
         if(re)
         {
            lastRe = re;
         }
         re = null;
         actionDelay = 0;
         GameMap.currentMap = null;
      }
   }
}

