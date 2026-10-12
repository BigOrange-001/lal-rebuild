package com.meng52.game.ui.panel
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.equip.Equip;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class PanelBossEnd extends PanelBossInfo
   {
      
      public static var $mBoss_data:Object;
      
      public var isIKill:Boolean = false;
      
      public function PanelBossEnd()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(90408));
         setUItoAward();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalData.$mGameClassObject.mPopUpContentManager.isRandomTouchClose = true;
         GlobalData.$tempMazeSelect = "zone_boss";
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_maze");
      }
      
      private function setUItoAward() : void
      {
         var _bg:Scale9Image;
         var _startD:Date;
         var _endD:Date;
         var _endM:int;
         var _gold:int;
         var _mark:int;
         var _str:String;
         var _txt:TextField;
         var _tRec:Rectangle;
         var _bgDel:Image;
         var _equip:Equip;
         var _equipImg:Image;
         var _lastAction:Image;
         var _awardCfg:Object;
         var _awardUI:Object;
         var _boxAward:Sprite;
         var _num:int;
         var _tNum:TextField;
         var _gap:int;
         var _awardTypeNum:Object;
         var txt_extreme_info:TextFieldHtmlRenderer;
         var _recRank:Rectangle;
         var _txtLose:TextField;
         var _btn:LOL_Scale9Button;
         var _ww:Number;
         GlobalData.$mGameClassObject.mPopUpContentManager.isRandomTouchClose = false;
         mBoss_data = PanelBossEnd.$mBoss_data;
         mBox_a = new Sprite();
         _bg = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",560,250,new Rectangle(110,55,70,20));
         mBox_a.addChild(_bg);
         addChild(mBox_a);
         _startD = mBoss_data.boss.add_time;
         _endD = mBoss_data.boss.end_time;
         _endM = int(_endD != null ? int((_endD.time - _startD.time) * 0.001 / 60) : 0);
         _gold = int(mBoss_data.attack_log.gifts ? mBoss_data.attack_log.gifts.gold : 0);
         _mark = int(mBoss_data.attack_log.gifts ? mBoss_data.attack_log.gifts.mark : 0);
         _str = GlobalLanguageStr.getLanguageStr(20367,_endM,mBoss_data.attack_log.attack_hp,mBoss_data.attack_log.attack_num,_gold,_mark);
         if(mBoss_data.boss.kill_log != null)
         {
            if(String(mBoss_data.boss.kill_log.uid) == String(GlobalData.$userData.uid))
            {
               _str += "\n" + GlobalLanguageStr.getLanguageStr(20378);
               isIKill = true;
            }
         }
         _txt = GlobalTextStyle.getTextField(_str,20,16777215,"left",360,240);
         _txt.x = 55;
         _txt.y = 100;
         this.addChild(_txt);
         _tRec = _txt.textBounds;
         if(mBoss_data.boss.kill_log != null)
         {
            if(String(mBoss_data.boss.kill_log.uid) == String(GlobalData.$userData.uid))
            {
               if(mBoss_data.boss.kill_log.eid != null)
               {
                  _bgDel = GlobalFunction.createImage("UI_boss_bg_7_0000");
                  _bgDel.x = _txt.x + 220;
                  _bgDel.y = _txt.y;
                  mBox_a.addChild(_bgDel);
                  _equip = new Equip(mBoss_data.boss.kill_log.eid);
                  _equipImg = GlobalFunction.getEquipUI(_equip.equipData.res);
                  _equipImg.scaleX = _equipImg.scaleY = 0.8;
                  _equipImg.x = _bgDel.x + _bgDel.width - _equipImg.width - 3;
                  _equipImg.y = _bgDel.y + 30;
                  mBox_a.addChild(_equipImg);
               }
               _lastAction = GlobalFunction.createImage("UI_bg_lastaction_0000");
               _lastAction.y = 30;
               _lastAction.x = 135;
               mBox_a.addChild(_lastAction);
               _awardCfg = mBoss_data.attack_log.gifts != null && (mBoss_data.attack_log.gifts.gold != null || mBoss_data.attack_log.gifts.coin != null || mBoss_data.attack_log.gifts.medal != null || mBoss_data.attack_log.gifts.mark != null) ? mBoss_data.attack_log.gifts : GlobalData.$mConfig_simple.zone_boss.kill_gifts;
               _awardUI = null;
               _boxAward = new Sprite();
               _num = 0;
               _tNum = null;
               _gap = 90;
               for(_awardTypeNum in _awardCfg)
               {
                  if(_awardTypeNum == "avatar" || _awardTypeNum == "avatar_soul" || _awardTypeNum == "equip" || _awardTypeNum == "equip_soul")
                  {
                     _awardUI = GlobalFunction.getAwardByType(_awardTypeNum.toString(),_awardCfg[_awardTypeNum],false,null,"",true,0.8);
                  }
                  else
                  {
                     _awardUI = GlobalFunction.getAwardByType(_awardTypeNum.toString(),_awardCfg[_awardTypeNum]);
                  }
                  _awardUI.ui.x = _gap * _num;
                  _boxAward.addChild(_awardUI.ui);
                  _num += 1;
               }
               _boxAward.x = _bg.x + (_bg.width - _gap * _num) * 0.5 + 9;
               _boxAward.y = _lastAction.y + _boxAward.height + 5;
               mBox_a.addChild(_boxAward);
            }
            else
            {
               txt_extreme_info = GlobalTextStyle.getHtmlTextRenderer();
               txt_extreme_info.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90528),GlobalTextStyle.COLOR_G_G_R_R,20,20);
               txt_extreme_info.mLayoutFun = function():void
               {
                  _recRank = txt_extreme_info.getTextSnapshotFrame();
                  txt_extreme_info.x = _bg.x + (_bg.width - _recRank.width) * 0.5;
                  txt_extreme_info.y = _bg.y + (_bg.height - _recRank.height) * 0.5;
               };
               mBox_a.addChild(txt_extreme_info);
            }
         }
         else
         {
            _txtLose = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20384),20,1118481,"center",345,35 * 3);
            _txtLose.x = (_bg.width - _txtLose.width) * 0.5;
            _txtLose.y = 60;
            mBox_a.addChild(_txtLose);
         }
         _btn = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20021),140,70,"UI_btn_normalFun_0000");
         _btn.shadowFilter();
         _btn.addEventListener("triggered",onTRIGGERED_btn);
         _btn.x = (_bg.width - _btn.width) * 0.5;
         _btn.y = _bg.y + _bg.height + 15;
         mBox_a.addChild(_btn);
         _ww = 430;
         mBox_a.x = int((GlobalData.$mStageWidth - _bg.width) * 0.5);
         mBox_a.y = this.mImg9_baseBg.y + 350;
         scaleX = scaleY = 0;
         GlobalData.$mStarling.juggler.tween(this,0.2,{
            "transition":"easeOut",
            "delay":0.05,
            "scaleX":1,
            "scaleY":1
         });
         GlobalData.$mEventDispatcher.dispatchEventWith("update_mail_tag");
      }
      
      private function onTRIGGERED_btn(param1:Event) : void
      {
         PanelBossList.$mBoss_data = mBoss_data;
         GlobalData.$tempMazeSelect = "zone_boss";
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_boss_list",false,true);
         GlobalData.$mGameClassObject.closePopUp();
      }
   }
}

