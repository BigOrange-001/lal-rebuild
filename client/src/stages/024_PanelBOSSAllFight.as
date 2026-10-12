package com.meng52.game.ui.panel
{
   import com.meng52.display.ProgressBar;
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.map.GameMapConfig;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.element.LOL_TimeStatus;
   import com.meng52.game.ui.screen.PanelBase;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale3Image;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import flash.utils.setTimeout;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   
   public class PanelBOSSAllFight extends PanelBase
   {
      
      private var _bg2:Scale3Image;
      
      private var _bg3:Image;
      
      public var mBox_a:Sprite;
      
      private var mBlood_halfA:ProgressBar;
      
      private var mBlood_halfB:ProgressBar;
      
      private var txt_GuildKillBossNum:TextField;
      
      private var txt_OWKillNum:TextField;
      
      private var btn_Out:LOL_Scale9Button;
      
      private var mBtn_close:LOL_Button;
      
      private var mBoss:Sprite;
      
      private var mBoss_red:Sprite;
      
      private var mBoss_white:Sprite;
      
      private var mBoss_box:Sprite;
      
      private var mClip_boss_xx:Number;
      
      private var mClip_boss_yy:Number;
      
      private var mBox_team:Sprite;
      
      private var btn_Attack:LOL_Scale9Button;
      
      private var txt_ResidualNum:TextField;
      
      private var txt_CD:TextField;
      
      private var mTimerT:LOL_TimeStatus;
      
      private var endTime:Number;
      
      private var now:Number;
      
      private var _cfg:Object;
      
      private var GuiBoss:PanelGuildBossInfo;
      
      public var mImg_head:Image;
      
      private var m9x9_bg:Scale9Image;
      
      private var isI5:Boolean;
      
      private var bossData:Object;
      
      private var mTimerT1:LOL_TimeStatus;
      
      private var numBoss:Number;
      
      private var bossheare:Boolean = true;
      
      public function PanelBOSSAllFight(param1:Object)
      {
         bossData = param1;
         GlobalData.$userGuild.bossData = bossData;
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         _cfg = GlobalData.$mGuild_simple.guild_BOSS;
         this.removeEventListener("addedToStage",initializeHandler);
         setUI();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         LayoutUIAnimation.getOnlyExample().clearAnimationLayer();
         LayoutUIAnimation.getOnlyExample().clear();
         bossheare = false;
         if(btn_Out)
         {
            btn_Out.removeFromParent(true);
            btn_Out.dispose();
         }
         if(mBlood_halfA)
         {
            mBlood_halfA.removeFromParent(true);
            mBlood_halfA.dispose();
         }
         if(mBlood_halfB)
         {
            mBlood_halfB.removeFromParent(true);
            mBlood_halfB.dispose();
         }
         if(txt_GuildKillBossNum)
         {
            txt_GuildKillBossNum.removeFromParent(true);
            txt_GuildKillBossNum.dispose();
         }
         if(txt_OWKillNum)
         {
            txt_OWKillNum.removeFromParent(true);
            txt_OWKillNum.dispose();
         }
         if(btn_Out)
         {
            btn_Out.removeFromParent(true);
            btn_Out.dispose();
         }
         if(mBtn_close)
         {
            mBtn_close.removeFromParent(true);
            mBtn_close.dispose();
         }
         if(mBox_a)
         {
            mBox_a.removeFromParent(true);
            mBox_a.dispose();
         }
         if(mBoss)
         {
            mBoss.removeFromParent(true);
            mBoss.dispose();
         }
         if(mBoss_red)
         {
            mBoss_red.removeFromParent(true);
            mBoss_red.dispose();
         }
         if(mBoss_white)
         {
            mBoss_white.removeFromParent(true);
            mBoss_white.dispose();
         }
         if(mBoss_box)
         {
            mBoss_box.removeFromParent(true);
            mBoss_box.dispose();
         }
         if(mBox_team)
         {
            mBox_team.removeFromParent(true);
            mBox_team.dispose();
         }
         if(btn_Attack)
         {
            btn_Attack.removeFromParent(true);
            btn_Attack.dispose();
         }
         if(txt_ResidualNum)
         {
            txt_ResidualNum.removeFromParent(true);
            txt_ResidualNum.dispose();
         }
         if(txt_CD)
         {
            txt_CD.removeFromParent(true);
            txt_CD.dispose();
         }
         if(mTimerT)
         {
            mTimerT.removeFromParent(true);
            mTimerT.dispose();
         }
         if(mImg_head)
         {
            mImg_head.removeFromParent(true);
            mImg_head.dispose();
         }
         if(m9x9_bg)
         {
            m9x9_bg.removeFromParent(true);
            m9x9_bg.dispose();
         }
         if(mTimerT1)
         {
            mTimerT1.removeFromParent(true);
            mTimerT1.dispose();
         }
         btn_Out = null;
         mBlood_halfA = null;
         mBlood_halfB = null;
         txt_GuildKillBossNum = null;
         txt_OWKillNum = null;
         btn_Out = null;
         mBtn_close = null;
         mBox_a = null;
         mBoss = null;
         mBoss_red = null;
         mBoss_white = null;
         mBoss_box = null;
         mBox_team = null;
         btn_Attack = null;
         txt_ResidualNum = null;
         txt_CD = null;
         mTimerT = null;
         mImg_head = null;
         m9x9_bg = null;
         mTimerT1 = null;
         StarlingTools.removeChildrenClear(this);
         this.clear();
      }
      
      private function delUI() : void
      {
         if(btn_Out)
         {
            btn_Out.removeEventListener("touch",onTouch);
            btn_Out.removeFromParent(true);
            btn_Out.dispose();
         }
         btn_Out = null;
      }
      
      private function onAttack(param1:* = null) : void
      {
         if(param1)
         {
            switch(param1)
            {
               case "cd":
                  SendServiceAMFFun.send_user_association_reborn(captureVipBefore(onRecd),{});
                  break;
               case "num":
                  SendServiceAMFFun.send_user_buy_attack_number(captureVipBefore(onReNum),{});
            }
         }
         else
         {
            SendServiceAMFFun.send_user_attack_associationboss(onRe,{"attack_num":bossData.data.attack_log.attack_num});
         }
      }
      
      private function onReNum(param1:Object) : void
      {
         if(this.stage == null) return;
         GlobalData.$userGuild.bossData.data.free_num = param1.data.association_free_num;
         if(txt_ResidualNum)
         {
            txt_ResidualNum.text = GlobalLanguageStr.getLanguageStr(97890,param1.data.association_free_num);
         }
         GlobalData.$userGuild.bossData.data.vip_free_num = param1.data.association_vip_free_num;
         showVipTransition(param1);
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
         GlobalData.$userData.vip_exp = param1.data.vip_exp;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
         GlobalData.$userData.vip_lv = param1.data.vip_lv;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
         GlobalData.$userData.coin = param1.data.coin;
         }
         GlobalFunction.updateVip();
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
      }
      
      private function onRecd(param1:Object) : void
      {
         if(this.stage == null) return;
         if(param1.data.res_code == -1)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97835),true);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
            return;
         }
         var _loc3_:Date = new Date();
         _loc3_.setTime((param1.data.attack_log.next_attack_time as Date).time - 2000);
         GlobalData.$userGuild.bossData.data.attack_log.next_attack_time = _loc3_;
         GuiBoss.btn_Attack.text = GlobalLanguageStr.getLanguageStr(97906);
         var _loc2_:Number = (param1.data.attack_log.next_attack_time as Date).time - SendAndSelect.$systemTimer_nowSecond * 1000;
         if(mTimerT1)
         {
            mTimerT1.refresh((_loc2_ - 2000) / 1000,"00:00:00"," ",onTimeOverFun,"",true);
         }
         else
         {
            mTimerT1 = new LOL_TimeStatus("paneleawefewa",null,null,false);
            mTimerT1.refresh((_loc2_ - 2000) / 1000,"00:00:00"," ",onTimeOverFun,"",true);
            mTimerT1.x = txt_CD.x + 50;
            mTimerT1.y = txt_CD.y;
            addChild(mTimerT1);
         }
         showVipTransition(param1);
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
         GlobalData.$userData.vip_exp = param1.data.vip_exp;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
         GlobalData.$userData.vip_lv = param1.data.vip_lv;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
         GlobalData.$userData.coin = param1.data.coin;
         }
         GlobalFunction.updateVip();
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
      }
      
      private function onRe(param1:Object) : void
      {
         if(this.stage == null) return;
         if(param1.data.res_code == -1)
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(97835),true);
            GlobalData.$mEventDispatcher.dispatchEventWith("update_guild_member_list",false,{"flag":10});
            return;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
         GlobalFunction.update_UserData(param1.data);
         }
         if(param1.data.attrs != null)
         {
            if(param1.data.attrs.guild_contribute != null)
            {
               if(!GlobalFunction.isVersionedProfileReceipt(param1))
               {
               GlobalData.$userData.attrs.guild_contribute = param1.data.attrs.guild_contribute;
               }
            }
            if(param1.data.attrs.association_gold != null)
            {
               if(!GlobalFunction.isVersionedProfileReceipt(param1))
               {
               GlobalData.$userData.attrs.association_gold = param1.data.attrs.association_gold;
               }
            }
         }
         var _loc3_:Boolean = false;
         if(GlobalData.$userGuild.bossData.data.boss.kill_num != param1.data.boss.kill_num)
         {
            _loc3_ = true;
         }
         if(GlobalData.$userGuild.bossData.data.free_num > 0)
         {
            GuiBoss.btn_Attack.text = GlobalLanguageStr.getLanguageStr(97917);
            GuiBoss.btn_Attack.fontSize = 23;
         }
         bossData = param1;
         check_boss_hp(true);
         GlobalData.$userGuild.bossData = param1;
         if(GlobalData.$userGuild.bossData.data.vip_free_num == 0)
         {
            GuiBoss.btn_Attack.enabled = false;
         }
         if(txt_GuildKillBossNum)
         {
            txt_GuildKillBossNum.text = GlobalLanguageStr.getLanguageStr(97891,param1.data.boss.kill_num);
         }
         if(txt_ResidualNum)
         {
            txt_ResidualNum.text = GlobalLanguageStr.getLanguageStr(97890,param1.data.free_num);
         }
         if(txt_OWKillNum)
         {
            txt_OWKillNum.text = GlobalLanguageStr.getLanguageStr(20363,param1.data.attack_log.attack_num,param1.data.attack_log.attack_hp);
         }
         var _loc2_:Number = (bossData.data.attack_log.next_attack_time as Date).time - SendAndSelect.$systemTimer_nowSecond * 1000;
         if(mTimerT1)
         {
            mTimerT1.refresh(_loc2_ / 1000,"00:00:00"," ",onTimeOverFun,"",true);
         }
         else
         {
            mTimerT1 = new LOL_TimeStatus("paneleawefewa",null,null,false);
            mTimerT1.refresh(_loc2_ / 1000,"00:00:00"," ",onTimeOverFun,"",true);
            mTimerT1.x = txt_CD.x + 50;
            mTimerT1.y = txt_CD.y;
            addChild(mTimerT1);
         }
         setFightSelf(param1.data.attack_hp,_loc3_);
      }
      
      private function check_boss_hp(param1:Boolean = false) : void
      {
         var _curr:Number;
         var _maxHp:Number;
         var _halfMax:Number;
         var _p:Number;
         var bb:*;
         var aa:*;
         var isAtt:Boolean = param1;
         if(mBlood_halfA && mBlood_halfB)
         {
            _curr = Number(bossData.data.boss.current_hp);
            _maxHp = Number(bossData.data.boss.max_hp);
            _halfMax = _maxHp / 2;
            if(_curr <= 0)
            {
               bb = function():void
               {
                  var cc:*;
                  if(bossheare)
                  {
                     cc = function():void
                     {
                        if(bossheare)
                        {
                           _curr = _maxHp - 1;
                           if(_curr < _maxHp)
                           {
                              if(_curr > _halfMax)
                              {
                                 _p = (_curr - _halfMax) / _halfMax;
                                 mBlood_halfB.setClip(_p);
                                 mBlood_halfB.setRatio(_p);
                                 mBlood_halfA.setRatio(1);
                              }
                              else
                              {
                                 mBlood_halfA.mTop.visible = true;
                                 _p = _curr / _halfMax;
                                 mBlood_halfA.setClip(_p);
                                 mBlood_halfA.setRatio(_p);
                                 mBlood_halfB.setRatio(0);
                              }
                           }
                        }
                     };
                     GuiBoss.BOSS_Die(GlobalData.$userGuild.bossData.data.boss.kill_num);
                     setTimeout(cc,2000);
                  }
               };
               if(_curr < _maxHp)
               {
                  if(_curr > _halfMax)
                  {
                     _p = (_curr - _halfMax) / _halfMax;
                     mBlood_halfB.setClip(_p);
                     mBlood_halfB.setRatio(_p);
                     mBlood_halfA.setRatio(1);
                  }
                  else
                  {
                     mBlood_halfA.mTop.visible = true;
                     _p = _curr / _halfMax;
                     mBlood_halfA.setClip(_p);
                     mBlood_halfA.setRatio(_p);
                     mBlood_halfB.setRatio(0);
                  }
               }
               setTimeout(bb,2000);
            }
            else if(isAtt)
            {
               aa = function():void
               {
                  if(bossheare)
                  {
                     GuiBoss.BOSS_Attack();
                     GuiBoss.check_teamClip(4);
                  }
               };
               setTimeout(aa,1601);
               if(_curr < _maxHp)
               {
                  if(_curr > _halfMax)
                  {
                     _p = (_curr - _halfMax) / _halfMax;
                     mBlood_halfB.setClip(_p);
                     mBlood_halfB.setRatio(_p);
                     mBlood_halfA.setRatio(1);
                  }
                  else
                  {
                     mBlood_halfA.mTop.visible = true;
                     _p = _curr / _halfMax;
                     mBlood_halfA.setClip(_p);
                     mBlood_halfA.setRatio(_p);
                     mBlood_halfB.setRatio(0);
                  }
               }
            }
            else if(_curr < _maxHp)
            {
               if(_curr > _halfMax)
               {
                  _p = (_curr - _halfMax) / _halfMax;
                  mBlood_halfB.setClip(_p);
                  mBlood_halfB.setRatio(_p);
                  mBlood_halfA.setRatio(1);
               }
               else
               {
                  mBlood_halfA.mTop.visible = true;
                  _p = _curr / _halfMax;
                  mBlood_halfA.setClip(_p);
                  mBlood_halfA.setRatio(_p);
                  mBlood_halfB.setRatio(0);
               }
            }
         }
      }
      
      private function setFightSelf(param1:Number, param2:Boolean = false) : void
      {
         var _loc3_:int = 0;
         var _loc4_:int = 0;
         var _loc6_:int = 0;
         var _loc5_:Array = null;
         if(GuiBoss)
         {
            _loc3_ = GameMapConfig.SCREEN_WIDTH / 2;
            _loc4_ = GuiBoss.y + GuiBoss.height * 0.5;
            LayoutUIAnimation.getOnlyExample().show();
            LayoutUIAnimation.getOnlyExample().jugglerA.delayCall(LayoutUIAnimation.getOnlyExample().popInjured,2,"-" + param1,_loc3_,_loc4_,_loc3_,_loc4_ - 120,16756800,40,1,"critBg");
            LayoutUIAnimation.getOnlyExample().jugglerA.delayCall(SoundManager.getOnlyExample().playSound,0.5,"E_8007");
            _loc5_ = ["E_9019","E_9010","E_9004"];
            _loc6_ = 0;
            while(_loc6_ < 7)
            {
               LayoutUIAnimation.getOnlyExample().jugglerA.delayCall(SoundManager.getOnlyExample().playSound,_loc6_ * 0.2,Tools.getArrayRandom(_loc5_));
               _loc6_++;
            }
            if(!param2)
            {
               LayoutUIAnimation.getOnlyExample().jugglerA.delayCall(SoundManager.getOnlyExample().playSound,3.6,"worldBoss1");
               LayoutUIAnimation.getOnlyExample().jugglerA.delayCall(SoundManager.getOnlyExample().playSound,5.5,"E_9021");
            }
         }
      }
      
      private function setUI() : void
      {
         GuiBoss = new PanelGuildBossInfo(onAttack,bossData.data.boss.kill_num);
         addChild(GuiBoss);
         var _loc1_:int = GlobalData.$mStageHeight > 960 ? (GlobalData.$mStageHeight - 960) / 2 : 0;
         mBlood_halfA = new ProgressBar(GlobalFunction.getTexture("UI_boss_blood_bg_0000"),GlobalFunction.getTexture("UI_boss_blood_bar_0000"),{
            "f":13,
            "s":18,
            "x":0,
            "y":0
         });
         mBlood_halfA.addTop(GlobalFunction.getTexture("UI_boss_bar_light_0_0000"),-2);
         mBlood_halfA.mTop.x = mBlood_halfA.width - 30;
         mBlood_halfA.touchable = false;
         addChild(mBlood_halfA);
         mBlood_halfA.mTop.visible = false;
         mBlood_halfB = new ProgressBar(GlobalFunction.getTexture("UI_boss_blood_bg_0000"),GlobalFunction.getTexture("UI_boss_blood_bar_0000"),{
            "f":13,
            "s":18,
            "x":0,
            "y":0
         });
         mBlood_halfB.addTop(GlobalFunction.getTexture("UI_boss_bar_light_0_0000"),-2);
         mBlood_halfB.mTop.x = mBlood_halfB.width - 30;
         mBlood_halfB.touchable = false;
         addChild(mBlood_halfB);
         mBlood_halfA.x = mBlood_halfB.x = 8;
         mBlood_halfA.y = 0 + 10 - _loc1_;
         mBlood_halfB.y = mBlood_halfA.y + 30;
         check_boss_hp();
         var _loc2_:Object = getTimeOut();
         mTimerT = new LOL_TimeStatus("paneltimeextraction");
         mTimerT.refresh(_loc2_.end,GlobalLanguageStr.getLanguageStr(97059,Tools.timeFormatAll(_loc2_.end)),GlobalLanguageStr.getLanguageStr(97060),isOver);
         mTimerT.x = mBlood_halfB.x;
         mTimerT.y = mBlood_halfA.y + mBlood_halfB.height - 30;
         addChild(mTimerT);
         mImg_head = getImg_headBg();
         mImg_head.height += _loc1_;
         mImg_head.y = GlobalData.$mStageHeight - mImg_head.height - _loc1_;
         addChild(mImg_head);
         m9x9_bg = GlobalFunction.createScale9Image("UI_bg_9slice_5_0000",616,120 + _loc1_,new Rectangle(30,20,50,30));
         m9x9_bg.x = int((mImg_head.width - m9x9_bg.width) * 0.5);
         m9x9_bg.y = mImg_head.y + mImg_head.height / 2 - m9x9_bg.height / 2;
         addChild(m9x9_bg);
         txt_GuildKillBossNum = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97891,Number(bossData.data.boss.kill_num)),20,16763904,"left",320,46);
         txt_GuildKillBossNum.x = m9x9_bg.x + 15;
         txt_GuildKillBossNum.y = m9x9_bg.y + m9x9_bg.height / 3 - txt_GuildKillBossNum.height / 2;
         addChild(txt_GuildKillBossNum);
         txt_OWKillNum = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20363,bossData.data.attack_log.attack_num,bossData.data.attack_log.attack_hp),20,16763904,"left",355,46);
         txt_OWKillNum.x = txt_GuildKillBossNum.x;
         txt_OWKillNum.y = m9x9_bg.y + m9x9_bg.height / 3 * 2 - txt_OWKillNum.height / 2;
         addChild(txt_OWKillNum);
         mBtn_close = GlobalFunction.createButtonStarling("UI_btn_9slice_0000");
         mBtn_close.x = GlobalData.$mStageWidth - mBtn_close.width - 10;
         mBtn_close.y = mTimerT.y;
         addChild(mBtn_close);
         mBtn_close.addEventListener("touch",onTouch);
         txt_ResidualNum = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97890,bossData.data.free_num),20,16763904,"left",300,46);
         txt_ResidualNum.x = m9x9_bg.width - txt_ResidualNum.width + 75;
         txt_ResidualNum.y = txt_GuildKillBossNum.y;
         addChild(txt_ResidualNum);
         txt_CD = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(97892),20,16763904,"left",100,46);
         txt_CD.x = txt_ResidualNum.x;
         txt_CD.y = txt_OWKillNum.y;
         addChild(txt_CD);
         numBoss = (bossData.data.attack_log.next_attack_time as Date).time - SendAndSelect.$systemTimer_nowSecond * 1000;
         if(numBoss > 0)
         {
            GuiBoss.btn_Attack.text = GlobalLanguageStr.getLanguageStr(97917);
            GuiBoss.check_teamClip(3);
         }
         mTimerT1 = new LOL_TimeStatus("paneleawefewa",null,null,false);
         mTimerT1.refresh(numBoss / 1000,"00:00:00"," ",onTimeOverFun,"",true);
         mTimerT1.x = txt_CD.x + 60;
         mTimerT1.y = txt_CD.y;
         addChild(mTimerT1);
         if(GlobalData.$userGuild.bossData.data.free_num <= 0)
         {
            GuiBoss.btn_Attack.enabled = false;
            return;
         }
      }
      
      private function onTimeOverFun() : void
      {
         GuiBoss.btn_Attack.text = GlobalLanguageStr.getLanguageStr(97906);
         if(GlobalData.$userGuild.bossData.data.free_num <= 0)
         {
            GuiBoss.btn_Attack.enabled = false;
         }
         GuiBoss.check_teamClip(0);
      }
      
      private function getTimeOut() : Object
      {
         var windows:Array = _cfg.open_times as Array;
         now = SendAndSelect.$systemTimer_nowSecond * 1000 + GlobalConfig.HOURS_8_MS;
         var activeEnd:Number = now;
         var open:Boolean = false;
         var i:int = 0;
         var row:Array = null;
         var start:Number = 0;
         var candidate:Date = null;
         if(windows)
         {
            while(i < windows.length)
            {
               row = windows[i] as Array;
               if(row && row.length >= 2)
               {
                  candidate = new Date();
                  candidate.setTime(now);
                  candidate.hours = int(row[0]);
                  candidate.minutes = int(row[1]);
                  candidate.seconds = 0;
                  start = candidate.time;
                  if(now >= start && now < start + _cfg.duration * 60000)
                  {
                     open = true;
                     activeEnd = start + _cfg.duration * 60000;
                     break;
                  }
               }
               i++;
            }
         }
         endTime = activeEnd;
         return {"can":open,"end":Math.max(0,activeEnd - now) * 0.001};
      }
      
      private function isOver() : void
      {
         GuiBoss.btn_Attack.enabled = false;
         mTimerT.refresh(0,GlobalLanguageStr.getLanguageStr(97074,Tools.timeFormatAll(0)),GlobalLanguageStr.getLanguageStr(97074));
      }
      
      private function onTouch(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(this,"ended");
         if(_loc2_)
         {
            this.onCLOSE_PANEL_SELF();
         }
      }
      private var _vipTransitionReceipts:Array = [];

      private function captureVipBefore(param1:Function) : Function
      {
         var _beforeVip:int = int(GlobalData.$userData.vip_lv);
         return function(param2:Object):void
         {
            param2._vip_before_request = _beforeVip;
            param2._vip_after_request = param2.data.user_dict != null ? int(param2.data.user_dict.vip_lv) : int(param2.data.vip_lv);
            param1(param2);
         };
      }

      private function showVipTransition(param1:Object) : void
      {
         if(this.stage == null)
         {
            return;
         }
         var _beforeVip:int = int(param1._vip_before_request);
         var _afterVip:int = int(param1._vip_after_request);
         if(_afterVip <= _beforeVip)
         {
            return;
         }
         if(_afterVip != int(GlobalData.$userData.vip_lv))
         {
            return;
         }
         var _revisionKey:String = String(param1.method) + ":" + String(param1.state_sync.uid) + ":" + String(param1.state_sync.revision);
         if(_vipTransitionReceipts.indexOf(_revisionKey) >= 0)
         {
            return;
         }
         _vipTransitionReceipts.push(_revisionKey);
         GlobalFunction.popAward("_$vip$_",GlobalLanguageStr.getLanguageStr(20203,_afterVip),_afterVip);
      }

   }
}
