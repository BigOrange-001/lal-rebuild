package com.meng52.game.ui.element
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.ui.screen.PanelCenterPVP;
   import com.meng52.game.ui.screen.PanelCenterShopVIP;
   import com.meng52.game.ui.screen.PanelCenterSocial;
   import com.meng52.game.ui.screen.PanelCenterTaskAward;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.controls.renderers.IListItemRenderer;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import starling.display.DisplayObject;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.display.Quad;
   import starling.core.Starling;
   import starling.animation.Tween;
   import starling.events.Event;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   
   public class ItemTaskAward extends ItemPVEmain implements IListItemRenderer
   {
      
      protected var mMsg:String = "";
      
      protected var mAwardItem:*;
      
      protected var m_uiBox:Sprite;
      
      private var _bg:Scale9Image;
      private var adventureButton:LOL_Scale9Button;
      private var adventureProgress:Quad;
      
      public function ItemTaskAward()
      {
         super();
      }
      
      override public function layoutWH() : void
      {
         if(this._bg)
         {
            this.width = this._bg.width;
            this.height = this._bg.height;
         }
         tweenX(false);
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(adventureProgress) Starling.juggler.removeTweens(adventureProgress);
         if(adventureButton)
         {
            Starling.juggler.removeTweens(adventureButton);
            adventureButton.removeEventListener("triggered",onAdventureButton);
         }
         adventureButton = null;
         adventureProgress = null;
         if(m_uiBox)
         {
            StarlingTools.removeChildrenClear(m_uiBox);
            m_uiBox.dispose();
         }
         this.clear();
         mAwardItem = null;
         m_uiBox = null;
      }
      
      override public function init(param1:Object) : void
      {
         if(param1 && param1.adventure_task === true)
         {
            renderAdventureTask(param1);
            return;
         }
         _bg = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",GlobalData.$mStageWidth - 30,110,new Rectangle(110,55,70,20));
         addChild(_bg);
         this.setUI();
      }
      
      override public function setUI() : void
      {
         var PASS_MAP_MAIN:String;
         var PASS_MAP_MAIN_HARD:String;
         var PASS_MAP_PLOY:String;
         var PVP_RANK:String;
         var PAY:String;
         var TIME_PAY:String;
         var TIME_PAY_LOOP:String;
         var _str:String;
         var i:Object;
         var _awardUI:Object;
         var _ui:DisplayObject;
         var _isNewUI:Boolean;
         var str:String;
         var id:String;
         var arr:Array;
         var m:String;
         var k:String;
         var _progressStr:String;
         var _progress:LOL_TextField;
         var _progressColor:uint;
         var _progressUI:String;
         var _payGiftNeed:int;
         var _myLast:int;
         var _isCanGift:Boolean;
         var hot:Image;
         var re:Object;
         var _cfg:Object;
         var _needStr:String;
         var _re:Object;
         var _reCurr:Number;
         var _reNeed:int;
         var _boo:Boolean;
         var _info:TextFieldHtmlRenderer;
         var _rec:Rectangle;
         var _strArr:Array;
         var _endS:Number;
         var _testStr:String;
         var hot1:Image;
         var hot2:Image;
         var _morebaseArr:Array;
         var _moreAvatar:Avatar;
         var _moreObj:Object;
         var j:int;
         var ss:String;
         var HAVE_AVATAR:String = "have_avatar";
         var HERO_SCORE:String = "hero_score";
         var TIME_LOGIN:String = "time_login";
         var TIME_CONSUMECOIN:String = "time_consumecoin";
         var _data:Object = this.data;
         var _type:String = _data["id"];
         var btn:LOL_Scale9Button = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20173),125,45,"UI_btn_enterGame_0_0000");
         var _rulerLeft:Number = int(this._bg.x + 90 * 2);
         var _giftObj:Object = _data["gift"];
         var _awardType:String = "";
         mAwardItem = null;
         if(data.id != "time_pay_loop")
         {
            for(i in _giftObj)
            {
               _awardType = i.toString();
               mAwardItem = _giftObj[i];
            }
            this.data["giftType"] = _awardType;
            this.mMsg = "";
            _awardUI = null;
            if(_awardType == "avatar" || _awardType == "equip")
            {
               _awardUI = GlobalFunction.getAwardByType(_awardType,mAwardItem,false,null,"",true,0.8,this.parent.parent as List);
            }
            else if(_awardType == "avatar_soul" || _awardType == "equip_soul")
            {
               _awardUI = GlobalFunction.getAwardByType(_awardType + "_random",null,false,null,"",true,0.8,this.parent.parent as List);
            }
            else
            {
               _awardUI = GlobalFunction.getAwardByType(_awardType,mAwardItem,false,null,"",true,1,this.parent.parent as List);
            }
            this.mMsg = _awardUI.msg;
            _ui = _awardUI.ui;
            _isNewUI = false;
         }
         m_uiBox = new Sprite();
         if(_ui)
         {
            if(_type.indexOf("_$paygift$_") > -1)
            {
               if(GlobalData.$userData.attrs.pay_gift_count > 0)
               {
                  _ui = GlobalFunction.createImage("UI_bg_card_2_0003") as DisplayObject;
                  _ui.scaleX = _ui.scaleY = 0.8;
               }
            }
            if(_awardType == "avatar_soul" || _awardType == "equip_soul")
            {
               _ui.x = 10;
               _ui.y = 10;
            }
            else
            {
               _ui.x = 10;
               _ui.y = 15;
            }
            m_uiBox.addChild(_ui);
         }
         else
         {
            _isNewUI = true;
            if(_type.indexOf("time_pay_loop") > -1)
            {
               if(_giftObj is Array)
               {
                  _ui = GlobalFunction.createImage("UI_bg_card_2_0003") as DisplayObject;
                  _ui.scaleX = _ui.scaleY = 0.8;
                  _ui.x = 10;
                  m_uiBox.addChild(_ui);
               }
               else if(_giftObj is Object)
               {
                  arr = [];
                  for(m in _giftObj)
                  {
                     str = m;
                     if(str == "dust")
                     {
                        arr = _giftObj[str];
                     }
                     else
                     {
                        for(k in _giftObj[str])
                        {
                           id = k;
                        }
                     }
                  }
                  if(id == null)
                  {
                     id = _giftObj[str];
                  }
                  if(str == "dust")
                  {
                     _ui = GlobalFunction.getAwardByType(str,arr,false,null,"",true).ui;
                  }
                  else if(str == "avatar" || str == "avatar_soul" || str == "equip" || str == "equip_soul")
                  {
                     _ui = GlobalFunction.getAwardByType(str,_giftObj[str],false,null,"",true).ui;
                  }
                  else if(str == "sp")
                  {
                     _ui = GlobalFunction.getAwardByType(str,_giftObj[str],false,null,"",true).ui;
                  }
                  else
                  {
                     _ui = GlobalFunction.getAwardByType(str,id,false,null,"",true).ui;
                  }
                  if(str == "avatar" || str == "avatar_soul" || str == "equip" || str == "equip_soul")
                  {
                     _ui.scaleX = _ui.scaleY = 0.8;
                  }
                  _ui.x = 10;
                  _ui.y = 5;
                  m_uiBox.addChild(_ui);
               }
            }
         }
         m_uiBox.x = int(this._bg.x + 25);
         this.addChild(m_uiBox);
         this.data["taskResult"] = 0;
         _progressColor = 10027008;
         _progressUI = "UI_tag_5_0001";
         if(_type.indexOf("_$everyday$_") > -1 || _type.indexOf("_$vip$_") > -1)
         {
            _str = _data["info"];
            this.data["taskResult"] = 1;
            _progressStr = GlobalLanguageStr.getLanguageStr(20136,1,1);
            _progressUI = "UI_tag_5_0000";
            _progressColor = 13056;
         }
         else if(_type.indexOf("_$pf_comment_gift$_") > -1)
         {
            _str = _data["info"];
            this.data["taskResult"] = 1;
            _progressUI = "UI_tag_5_0000";
         }
         else if(_type.indexOf("_$paygift$_") > -1)
         {
            _payGiftNeed = this.data["need"] * 10;
            _str = GlobalLanguageStr.replaceStrArr(_data["info"],[_payGiftNeed]);
            _myLast = Tools.toInt(GlobalData.$userData.attrs.pay_gift * 10);
            _isCanGift = _myLast >= _payGiftNeed;
            _reCurr = _myLast;
            _reNeed = _payGiftNeed;
            this.data["taskResult"] = _isCanGift ? 1 : 0;
            _progressStr = GlobalLanguageStr.getLanguageStr(20136,_myLast,_payGiftNeed);
            if(_isCanGift)
            {
               _progressUI = "UI_tag_5_0000";
               _progressColor = 13056;
            }
            btn.enabled = _isCanGift;
            hot = GlobalFunction.createImage("UI_icon_hot_0000");
            hot.x = _bg.x + _bg.width - hot.width - 5;
            hot.y = 5;
            addChild(hot);
         }
         else if(_type.indexOf("pvp_rank") > -1)
         {
            re = PanelCenterTaskAward.checkTask(_type,_data,data["data_base"]);
            _str = GlobalLanguageStr.replaceStrArr(_data["info"],[re.need]);
            this.data["taskResult"] = 1;
            _progressStr = GlobalLanguageStr.getLanguageStr(20136,1,1);
            _progressUI = "UI_tag_5_000";
            _progressColor = 13056;
            if(!re.ok)
            {
               btn.enabled = false;
            }
         }
         else
         {
            _needStr = _data["need"];
            _re = PanelCenterTaskAward.checkTask(_type,_data,data["data_base"]);
            _reCurr = Number(_re.curr);
            _reNeed = int(_re.need);
            if(_type == "pass_map_main" || _type == "pass_map_main_hard")
            {
               _cfg = GlobalData.$mConfig_battle_main[_needStr];
               _needStr = _cfg.name;
            }
            else if(_type == "pass_map_ploy")
            {
               _cfg = GlobalData.$mConfig_battle_ploy[_needStr];
               _needStr = _cfg.name;
            }
            else if(_type == "pay")
            {
               _needStr = String(_data["need"] * 10);
               _reCurr = _reCurr * 10;
               _reNeed = _reNeed * 10;
            }
            else if(_type == "time_pay")
            {
               _needStr = String(_data["need"] * 10);
               ;
               ;
            }
            else if(_type == "time_pay_loop")
            {
               _needStr = String(_data["need"] * 10);
               ;
               ;
            }
            _reCurr = Tools.toInt(_reCurr);
            _str = GlobalLanguageStr.replaceStrArr(_data["info"],[_needStr]);
            _boo = true;
            if(_type == HAVE_AVATAR)
            {
               _progressStr = "";
               _boo = false;
            }
            else
            {
               _progressStr = GlobalLanguageStr.getLanguageStr(20136,_reCurr,_reNeed);
            }
            if(!_re.ok)
            {
               btn.enabled = false;
            }
            if(_type == "pay")
            {
               btn.enabled = GlobalData.$userData.lv < _data["lvMax"] ? false : btn.enabled;
            }
            this.data["taskResult"] = _re.ok ? 1 : 0;
            if(_re.ok)
            {
               _progressUI = "UI_tag_5_0000";
               _progressColor = 13056;
            }
         }
         _reCurr = Tools.toInt(_reCurr);
         _progress = new LOL_TextField(_progressStr,300,35);
         if(_reCurr >= _reNeed)
         {
            _progress.fontColor = 13056;
         }
         else
         {
            _progress.fontColor = 10027008;
         }
         _progress.fontSize = 15;
         _progress.x = _rulerLeft - 50;
         _progress.y = _bg.height - 60;
         if(_type.indexOf("_$everyday$_") > -1 || _type.indexOf("_$vip$_") > -1 || _type.indexOf("pvp_rank") > -1 || _type.indexOf("_$pf_comment_gift$_") > -1)
         {
            _progress.y += 5;
         }
         else
         {
            this.addChild(_progress);
         }
         this.addChild(btn);
         btn.addEventListener("triggered",onTRIGGERED_btn);
         _info = GlobalTextStyle.getHtmlTextRenderer();
         _rec = null;
         _info.mLayoutFun = function():void
         {
            _rec = _info.getTextSnapshotFrame();
            _info.x = _rulerLeft - 50;
            if(_type == HAVE_AVATAR)
            {
               _info.y = 12;
               if(_rec.height >= _bg.height - 30)
               {
                  _bg.height = _rec.height + _progress.height + 20;
                  _info.y = 25;
               }
            }
            else
            {
               if(_rec.height < 40)
               {
                  if(_boo == false)
                  {
                     _info.y = _bg.height / 2 - 15;
                     _progress.y = _rec.height + 20;
                  }
                  else
                  {
                     _info.y = _bg.height / 2 - 30;
                     _progress.y = _rec.height + 20;
                  }
               }
               else if(_rec.height > 40 && _rec.height < 80)
               {
                  _info.y = 12;
                  _bg.height = _rec.height + 30;
                  _progress.y = _rec.height + 10;
               }
               else
               {
                  _info.y = 12;
                  _progress.y = _rec.height + 10;
               }
               if(_progress.y + 35 + 5 >= _bg.height)
               {
                  _bg.height = _rec.height + _progress.height + 20;
               }
            }
            btn.x = int(_bg.x + _bg.width - btn.width - 30);
            btn.y = int((_bg.height - btn.height) * 0.5);
            height = _bg.height;
            m_uiBox.y = int(_bg.y + (_bg.height - 90) * 0.5) - (_awardType == "avatar" ? 13 : 5);
         };
         _testStr = "";
         if(_type == "time_pay" || _type == "time_pay_loop" || _type == TIME_LOGIN || _type == TIME_CONSUMECOIN)
         {
            _endS = (this.data["data_base"].end_time as Date).time * 0.001 - SendAndSelect.$systemTimer_nowSecond;
            _endS = _endS > 0 ? _endS : 0;
            _info.text = Tools.formatHtmlTextBr([Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20130,Tools.timeFormatToDate(_endS,false)),GlobalTextStyle.COLOR_0x990000,20,MainConfig.$isEnglish ? 17 : 20),Tools.formatLineX(_str,GlobalTextStyle.COLOR_task_2,20,MainConfig.$isEA ? 15 : (MainConfig.$isEnglish ? 17 : 20))]);
            hot1 = GlobalFunction.createImage("UI_icon_hot_0000");
            hot1.x = _bg.x + _bg.width - hot1.width - 5;
            hot1.y = 5;
            addChild(hot1);
         }
         else if(_type == HAVE_AVATAR)
         {
            hot2 = GlobalFunction.createImage("UI_icon_hot_0000");
            hot2.x = _bg.x + _bg.width - hot2.width - 5;
            hot2.y = 5;
            addChild(hot2);
            _endS = (this.data["data_base"].end_time as Date).time * 0.001 - SendAndSelect.$systemTimer_nowSecond;
            _endS = _endS > 0 ? _endS : 0;
            _strArr = [Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20130,Tools.timeFormatToDate(_endS,false)),GlobalTextStyle.COLOR_0x990000,20,MainConfig.$isEA ? 18 : 20),Tools.formatLineX(GlobalLanguageStr.replaceStrArr(_data["info"],[""]),GlobalTextStyle.COLOR_task,20,MainConfig.$isEA ? 18 : 20)];
            _morebaseArr = data["task_more_base"] as Array;
            j = 0;
            j = 0;
            while(j < _morebaseArr.length)
            {
               _moreObj = _morebaseArr[j];
               _moreAvatar = new Avatar(_moreObj["aid"]);
               ss = GlobalLanguageStr.getLanguageStr(20205,_moreAvatar.getStar(),_moreAvatar.avatarData.name) + " : " + _moreObj.curr + "/" + _moreObj.need;
               _strArr.push(Tools.formatLineX(ss,_moreObj.curr >= _moreObj.need ? GlobalTextStyle.COLOR_0x003300 : GlobalTextStyle.COLOR_0x990000,20,15));
               _moreAvatar.allClear();
               _moreAvatar = null;
               j = j + 1;
            }
            _info.text = Tools.formatHtmlTextBr(_strArr);
         }
         else
         {
            _info.text = Tools.formatLineX(_str,GlobalTextStyle.COLOR_task_2,15,MainConfig.$isEnglish ? 17 : 20);
         }
         this.addChild(_info);
      }
      
      protected function onTOUCH(param1:TouchEvent) : void
      {
         var _loc2_:String = null;
         if(this.data["giftType"] == "avatar")
         {
            _loc2_ = data["id"];
            if(_loc2_.indexOf("_$paygift$_") > -1)
            {
               if(GlobalData.$userData.attrs.pay_gift_count > 0)
               {
                  return;
               }
            }
         }
      }
      
      protected function onTRIGGERED_btn(param1:Event) : void
      {
         var _type:String;
         var _giftType:String;
         var _idArr:Array;
         var _id:int;
         var _energyObj:Object;
         var _fun:Object;
         var send_everyday_gift:*;
         var goStore:*;
         var _payfun:Object;
         var _info:String;
         var goWagerscore:*;
         var _wagerscoreFun:Object;
         var goFriendsearch:*;
         var _friendsearchFun:Object;
         var washcount:*;
         var _washfun:Object;
         var _inforId:String;
         var pvprunk:*;
         var _pvprunkFun:Object;
         var mapmain:*;
         var _mianFun:Object;
         var mapmainhard:*;
         var _mianhardFun:Object;
         var mapploy:*;
         var _mianployFun:Object;
         var _event:Event = param1;
         var p:List = this.parent.parent as List;
         if(p.isScrolling)
         {
            return;
         }
         soundTriggered();
         _type = data["id"];
         GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
         if(data["taskResult"] == 1)
         {
            _giftType = data["giftType"];
            _idArr = null;
            _id = 0;
            if(_giftType == "score")
            {
               if(GlobalData.$userData.score >= GlobalData.$mConfig_simple.score_config[2])
               {
                  GlobalFunction.popCasion_A();
                  return;
               }
            }
            if(_type == "pay" && GlobalData.$userData.lv < data["lvMax"])
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90124,data["lvMax"]),true);
               return;
            }
            if(_type.indexOf("_$everyday$_") > -1)
            {
               send_everyday_gift = function():void
               {
                  SendServiceAMFFun.send_user_everyday_gift(reFun,{
                     "gnum":_id,
                     "type":_type,
                     "giftType":_giftType,
                     "awardItem":mAwardItem
                  });
               };
               _idArr = _type.split("_");
               _id = int(_idArr[_idArr.length - 1]);
               if(_giftType == "energy")
               {
                  _energyObj = GlobalFunction.getEnergy();
                  if(_energyObj.energy >= _energyObj.max)
                  {
                     GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90003));
                     return;
                  }
                  if(_energyObj.energy > 6)
                  {
                     _fun = {
                        "ok":send_everyday_gift,
                        "no":GlobalFunction.functionNull
                     };
                     GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(90183),_fun);
                  }
                  else
                  {
                     send_everyday_gift();
                  }
               }
               else if(_giftType == "avatar")
               {
                  if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
                  {
                     GlobalFunction.popAvatarLen();
                  }
                  else
                  {
                     send_everyday_gift();
                  }
               }
               else if(_giftType == "avatar_soul" || _giftType == "equip_soul" || _giftType == "culture_book")
               {
                  send_everyday_gift();
                  if(_giftType == "avatar_soul")
                  {
                  }
                  if(_giftType == "equip_soul")
                  {
                  }
               }
               else
               {
                  send_everyday_gift();
               }
            }
            else if(_type.indexOf("_$paygift$_") > -1)
            {
               _idArr = _type.split("_");
               _id = int(_idArr[_idArr.length - 1]);
               if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
               {
                  GlobalFunction.popAvatarLen();
               }
               else
               {
                  SendServiceAMFFun.send_user_get_pay_gift(this.reFun,{
                     "gnum":_id,
                     "type":_type,
                     "giftType":_giftType,
                     "awardItem":mAwardItem
                  });
               }
            }
            else if(_type.indexOf("_$vip$_") > -1)
            {
               _idArr = _type.split("_");
               _id = int(_idArr[_idArr.length - 1]);
               SendServiceAMFFun.send_user_vip_gift(this.reFun,{
                  "gnum":_id,
                  "type":_type,
                  "giftType":_giftType,
                  "awardItem":mAwardItem
               });
            }
            else if(_type.indexOf("_$pf_comment_gift$_") > -1)
            {
               GlobalFunction.popAppleComment(false);
            }
            else if((_type.indexOf("pay") || _type.indexOf("time_pay")) && data["giftType"] == "equip")
            {
               if(Tools.getElementNum(GlobalData.$userData.my_equips) >= int(GlobalData.$mConfig_simple.equip_config[0]))
               {
                  GlobalFunction.popEquipFull();
               }
               else
               {
                  SendServiceAMFFun.send_user_task_done(this.reFun,{
                     "task_key":_type,
                     "type":_type,
                     "giftType":_giftType,
                     "awardItem":mAwardItem,
                     "task_code":_data["taskcode"]
                  });
               }
            }
            else if(_type == "login_catena")
            {
               if(data["giftType"] == "avatar")
               {
                  if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
                  {
                     GlobalFunction.popAvatarLen();
                  }
                  else
                  {
                     SendServiceAMFFun.send_user_task_done(this.reFun,{
                        "task_key":_type,
                        "type":_type,
                        "giftType":_giftType,
                        "awardItem":mAwardItem,
                        "task_code":_data["taskcode"]
                     });
                  }
               }
               else
               {
                  SendServiceAMFFun.send_user_task_done(this.reFun,{
                     "task_key":_type,
                     "type":_type,
                     "giftType":_giftType,
                     "awardItem":mAwardItem,
                     "task_code":_data["taskcode"]
                  });
               }
            }
            else if(_type == "time_login")
            {
               if(data["giftType"] == "avatar")
               {
                  if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
                  {
                     GlobalFunction.popAvatarLen();
                  }
                  else
                  {
                     SendServiceAMFFun.send_user_task_done(this.reFun,{
                        "task_key":_type,
                        "type":_type,
                        "giftType":_giftType,
                        "awardItem":mAwardItem,
                        "task_code":_data["taskcode"]
                     });
                  }
               }
               else if(data["giftType"] == "equip")
               {
                  if(Tools.getElementNum(GlobalData.$userData.my_equips) >= int(GlobalData.$mConfig_simple.equip_config[0]))
                  {
                     GlobalFunction.popEquipFull();
                  }
                  else
                  {
                     SendServiceAMFFun.send_user_task_done(this.reFun,{
                        "task_key":_type,
                        "type":_type,
                        "giftType":_giftType,
                        "awardItem":mAwardItem,
                        "task_code":_data["taskcode"]
                     });
                  }
               }
               else
               {
                  SendServiceAMFFun.send_user_task_done(this.reFun,{
                     "task_key":_type,
                     "type":_type,
                     "giftType":_giftType,
                     "awardItem":mAwardItem,
                     "task_code":_data["taskcode"]
                  });
               }
            }
            else if(_type == "level_up")
            {
               if(data["giftType"] == "avatar")
               {
                  if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
                  {
                     GlobalFunction.popAvatarLen();
                  }
                  else
                  {
                     SendServiceAMFFun.send_user_task_done(this.reFun,{
                        "task_key":_type,
                        "type":_type,
                        "giftType":_giftType,
                        "awardItem":mAwardItem,
                        "task_code":_data["taskcode"]
                     });
                  }
               }
               else if(data["giftType"] == "equip")
               {
                  if(Tools.getElementNum(GlobalData.$userData.my_equips) >= int(GlobalData.$mConfig_simple.equip_config[0]))
                  {
                     GlobalFunction.popEquipFull();
                  }
                  else
                  {
                     SendServiceAMFFun.send_user_task_done(this.reFun,{
                        "task_key":_type,
                        "type":_type,
                        "giftType":_giftType,
                        "awardItem":mAwardItem,
                        "task_code":_data["taskcode"]
                     });
                  }
               }
               else
               {
                  SendServiceAMFFun.send_user_task_done(this.reFun,{
                     "task_key":_type,
                     "type":_type,
                     "giftType":_giftType,
                     "awardItem":mAwardItem,
                     "task_code":_data["taskcode"]
                  });
               }
            }
            else if(_type == "time_pay_loop")
            {
               if(_giftType == "coin")
               {
                  SendServiceAMFFun.send_user_task_done(this.reFun,{
                     "task_key":_type,
                     "type":_type,
                     "giftType":_giftType,
                     "awardItem":mAwardItem,
                     "task_code":_data["taskcode"]
                  });
               }
               else if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
               {
                  GlobalFunction.popAvatarLen();
               }
               else
               {
                  SendServiceAMFFun.send_user_task_done(this.reFun,{
                     "task_key":_type,
                     "type":_type,
                     "giftType":_giftType,
                     "awardItem":mAwardItem,
                     "task_code":_data["taskcode"]
                  });
               }
            }
            else if(_type == "friend_num")
            {
               if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
               {
                  GlobalFunction.popAvatarLen();
               }
               else
               {
                  SendServiceAMFFun.send_user_task_done(this.reFun,{
                     "task_key":_type,
                     "type":_type,
                     "giftType":_giftType,
                     "awardItem":mAwardItem,
                     "task_code":_data["taskcode"]
                  });
               }
            }
            else
            {
               SendServiceAMFFun.send_user_task_done(this.reFun,{
                  "task_key":_type,
                  "type":_type,
                  "giftType":_giftType,
                  "awardItem":mAwardItem,
                  "task_code":_data["taskcode"]
               });
            }
         }
         else if(_type == "pay" || _type == "_$paygift$_" || _type == "time_pay_loop" || _type == "time_pay")
         {
            goStore = function():void
            {
               PanelCenterShopVIP.$selectType = 1;
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_pay",false,true);
            };
            _payfun = {
               "ok":goStore,
               "no":GlobalFunction.functionNull,
               "aid":"A_2009_5"
            };
            GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90219,[String(_data["need"] * 10)]),GlobalTextStyle.COLOR_W_Y_Y_G),_payfun);
         }
         else if(_type == "wager_coin")
         {
            _info = GlobalLanguageStr.getLanguageStr(90223,[String(_data["need"])]);
            GlobalFunction.popCasion_B(_info);
         }
         else if(_type == "wager_score")
         {
            goWagerscore = function():void
            {
               PanelCenterShopVIP.$selectType = 0;
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_shopAndVIP");
               if(GlobalFunction.checkWagerTime(0) > 0)
               {
                  GlobalData.$mEventDispatcher.dispatchEventWith("update_casino_A");
               }
               else
               {
                  GlobalData.$mEventDispatcher.dispatchEventWith("update_casino_free_A");
               }
            };
            _wagerscoreFun = {
               "ok":goWagerscore,
               "no":GlobalFunction.functionNull,
               "aid":"A_2009_5"
            };
            GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90229,[String(_data["need"])]),GlobalTextStyle.COLOR_W_Y_Y_G),_wagerscoreFun);
         }
         else if(_type == "friend_num")
         {
            goFriendsearch = function():void
            {
               PanelCenterSocial.$tabIndex = 1;
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_social");
            };
            _friendsearchFun = {
               "ok":goFriendsearch,
               "no":GlobalFunction.functionNull,
               "aid":"A_2009_5"
            };
            GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90222,[String(_data["need"])]),GlobalTextStyle.COLOR_W_Y_Y_G),_friendsearchFun);
         }
         else if(_type == "coin_wash_count")
         {
            washcount = function():void
            {
               GlobalData.$tempEquipFunId = 1;
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_change_base");
            };
            _washfun = {
               "ok":washcount,
               "no":GlobalFunction.functionNull,
               "aid":"A_2009_5"
            };
            GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90230,[String(_data["need"])]),GlobalTextStyle.COLOR_W_Y_Y_G),_washfun);
         }
         else if(_type == "pvp_count" || _type == "pvp_rank" || _type == "pvp_sucess_count")
         {
            pvprunk = function():void
            {
               PanelCenterPVP.$tabBarSelectedIndex = 1;
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp");
            };
            _inforId = "";
            switch(_type)
            {
               case "pvp_count":
                  _inforId = "90232";
                  break;
               case "pvp_rank":
                  _inforId = "90234";
                  break;
               case "pvp_sucess_count":
                  _inforId = "90233";
            }
            _pvprunkFun = {
               "ok":pvprunk,
               "no":GlobalFunction.functionNull,
               "aid":"A_2009_5"
            };
            GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(_inforId,[String(_data["need"])]),GlobalTextStyle.COLOR_W_Y_Y_G),_pvprunkFun);
         }
         else if(_type == "pass_map_main")
         {
            mapmain = function():void
            {
               GlobalData.$tempPVE_type_id = 0;
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pve");
            };
            _mianFun = {
               "ok":mapmain,
               "no":GlobalFunction.functionNull,
               "aid":"A_2009_5"
            };
            GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90235,[GlobalFunction.getBattleNameById(String(_data["need"]))]),GlobalTextStyle.COLOR_W_Y_Y_G),_mianFun);
         }
         else if(_type == "pass_map_main_hard")
         {
            mapmainhard = function():void
            {
               GlobalData.$tempPVE_type_id = 1;
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pve");
            };
            _mianhardFun = {
               "ok":mapmainhard,
               "no":GlobalFunction.functionNull,
               "aid":"A_2009_5"
            };
            GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90236,[GlobalFunction.getBattleNameById(String(_data["need"]))]),GlobalTextStyle.COLOR_W_Y_Y_G),_mianhardFun);
         }
         else if(_type == "pass_map_ploy")
         {
            mapploy = function():void
            {
               GlobalData.$tempPVE_type_id = 2;
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pve");
            };
            _mianployFun = {
               "ok":mapmain,
               "no":GlobalFunction.functionNull,
               "aid":"A_2009_5"
            };
            GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90237,[GlobalFunction.getBattleNameById(String(_data["need"]))]),GlobalTextStyle.COLOR_W_Y_Y_G),_mianployFun);
         }
         else
         {
            GlobalFunction.popAlert("",GlobalLanguageStr.getLanguageStr(20216),null,true);
         }
      }
      
      override public function onTRIGGERED(param1:Event) : void
      {
      }
      
      private function reFun(param1:Object) : void
      {
         if(stage == null)
         {
            return;
         }
         var _loc13_:String = null;
         var _loc7_:String = null;
         var _loc14_:String = null;
         var _loc5_:* = undefined;
         var _loc10_:Array = null;
         var _loc11_:int = 0;
         var _loc8_:Object = null;
         var _loc3_:Object = null;
         var _loc12_:Array = null;
         var _loc4_:int = 0;
         var _loc6_:int = 0;
         var _loc9_:Object = null;
         var _loc2_:Object = null;
         if(param1)
         {
            _loc13_ = "sound03";
            SoundManager.getOnlyExample().playSound(_loc13_);
            GuideMaster.getOnlyExample().guideWait();
            _loc7_ = param1["params"]["type"];
            _loc14_ = param1["params"]["giftType"];
            _loc5_ = param1["params"]["awardItem"];
            _loc10_ = null;
            _loc11_ = 0;
            if(_loc7_.indexOf("_$everyday$_") > -1)
            {
               _loc10_ = _loc7_.split("_");
               _loc11_ = int(_loc10_[_loc10_.length - 1]);
               if(!GlobalFunction.isVersionedProfileReceipt(param1))
               {
                  (GlobalData.$userData.records.everyday_gift as Array).push(_loc11_);
               }
            }
            else if(_loc7_.indexOf("_$paygift$_") <= -1)
            {
               if(_loc7_.indexOf("_$vip$_") > -1)
               {
                  _loc10_ = _loc7_.split("_");
                  _loc11_ = int(_loc10_[_loc10_.length - 1]);
                  if(!GlobalFunction.isVersionedProfileReceipt(param1))
                  {
                     (GlobalData.$userData.records.vip_gift as Array).push(_loc11_);
                  }
               }
               else
               {
                  if(!GlobalFunction.isVersionedProfileReceipt(param1))
                  {
                     GlobalData.$userData.task = param1.data.task;
                  }
                  if(!GlobalFunction.isVersionedProfileReceipt(param1))
                  {
                     GlobalData.$userData.catena = param1.data.catena;
                  }
               }
            }
            if(param1.data.attrs)
            {
               if(!GlobalFunction.isVersionedProfileReceipt(param1))
               {
                  GlobalData.$userData.attrs = param1.data.attrs;
               }
            }
            if(param1.data.records)
            {
               if(!GlobalFunction.isVersionedProfileReceipt(param1))
               {
                  GlobalData.$userData.records = param1.data.records;
               }
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.avatars = param1.data.avatars;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.my_equips = param1.data.my_equips;
            }
            if(param1.data.avatar_soul)
            {
               if(!GlobalFunction.isVersionedProfileReceipt(param1))
               {
                  GlobalData.$userData.avatar_soul = param1.data.avatar_soul;
               }
            }
            if(param1.data.equip_soul)
            {
               if(!GlobalFunction.isVersionedProfileReceipt(param1))
               {
                  GlobalData.$userData.equip_soul = param1.data.equip_soul;
               }
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.medal = param1.data.medal;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.mark = param1.data.mark;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.coin = param1.data.coin;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.energy = param1.data.energy;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.gold = param1.data.gold;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.score = param1.data.score;
            }
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.attrs.culture_book = param1.data.culture_book;
            }
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
            _loc8_ = null;
            _loc3_ = null;
            _loc4_ = 0;
            _loc6_ = 0;
            if(_loc7_.indexOf("_$paygift$_") > -1)
            {
               if(GlobalData.$userData.attrs.pay_gift_count > 0)
               {
                  for(_loc3_ in param1.data.gift)
                  {
                     _loc8_ = GlobalFunction.getAwardByType(_loc3_.toString(),param1.data.gift[_loc3_]);
                     GlobalFunction.popAward(_loc3_.toString(),_loc8_.msg,param1.data.gift[_loc3_]);
                  }
               }
               else
               {
                  GlobalFunction.popAward(_loc14_,mMsg,_loc5_);
               }
            }
            else if(_loc7_.indexOf("time_pay_loop") > -1)
            {
               for(_loc3_ in param1.data.gift)
               {
                  if(_loc3_.toString() == "dust")
                  {
                     _loc12_ = param1.data.gift[_loc3_] as Array;
                     _loc4_ = int(_loc12_.length);
                     _loc6_ = 0;
                     while(_loc6_ < _loc4_)
                     {
                        if(_loc12_[_loc6_] != 0)
                        {
                           _loc9_ = {};
                           _loc9_["indexID_s"] = _loc6_;
                           _loc9_["numberIndex"] = _loc12_[_loc6_];
                           _loc8_ = GlobalFunction.getAwardByType("dust",_loc9_);
                           GlobalFunction.popAward("dust",_loc8_.msg,_loc9_);
                        }
                        _loc6_++;
                     }
                  }
                  else
                  {
                     _loc8_ = GlobalFunction.getAwardByType(_loc3_.toString(),param1.data.gift[_loc3_]);
                     GlobalFunction.popAward(_loc3_.toString(),_loc8_.msg,param1.data.gift[_loc3_]);
                  }
               }
            }
            else if(_loc14_ == "avatar_soul" || _loc14_ == "equip_soul")
            {
               for(_loc3_ in param1.data.gift)
               {
                  _loc2_ = GlobalFunction.getAwardByType(_loc14_,param1.data.gift[_loc3_]);
                  GlobalFunction.popAward(_loc14_,_loc2_.msg,param1.data.gift[_loc3_]);
               }
            }
            else
            {
               GlobalFunction.popAward(_loc14_,mMsg,_loc5_);
            }
         }
         GlobalData.$mEventDispatcher.dispatchEventWith("update_avatar_award");
         GlobalData.$mEventDispatcher.dispatchEventWith("update_activity_fun_task_num");
      }
      private function renderAdventureTask(row:Object) : void
      {
         var cardWidth:Number = GlobalData.$mStageWidth - 24;
         _bg = GlobalFunction.createScale9Image("UI_bg_9slice_4_0000",cardWidth,208,new Rectangle(110,60,30,15));
         addChild(_bg);
         var surface:Quad = new Quad(cardWidth - 18,190,0x282B30);
         surface.x = surface.y = 9;surface.touchable = false;addChild(surface);
         var title:TextField = GlobalFunction.createTextField(cardWidth - 32,32,String(row.title),"",22,0xFFD684,true);
         title.x = 16;
         title.y = 12;
         title.autoScale = true;
         title.hAlign = "left";
         title.touchable = false;
         addChild(title);
         addAdventureRewardIcon(row);
         var progress:TextField = GlobalFunction.createTextField(cardWidth - 116,28,String(row.progress_text),"",18,row.claimable ? 0xA9DEA1 : 0xBAC2CC);
         progress.x = 100;
         progress.y = 54;
         progress.autoScale = true;
         progress.hAlign = "left";
         progress.touchable = false;
         addChild(progress);
         var track:Quad = new Quad(cardWidth - 116,8,0x11161C);
         track.x = 100;
         track.y = 87;
         track.alpha = 0.8;
         track.touchable = false;
         addChild(track);
         var ratio:Number = Number(row.progress_ratio);
         if(isNaN(ratio)) ratio = row.claimed || row.claimable ? 1 : 0;
         ratio = Math.max(0,Math.min(1,ratio));
         adventureProgress = new Quad(cardWidth - 116,8,row.claimable ? 0x8CB968 : 0xBB9952);
         adventureProgress.x = 100;
         adventureProgress.y = 87;
         adventureProgress.scaleX = ratio;
         adventureProgress.touchable = false;
         addChild(adventureProgress);
         var reward:TextField = GlobalFunction.createTextField(cardWidth - 116,48,"奖励：" + String(row.reward_text),"",17,0xE5D9C1);
         reward.x = 100;
         reward.y = 102;
         reward.autoScale = true;
         reward.hAlign = "left";
         reward.vAlign = "top";
         reward.touchable = false;
         addChild(reward);
         var state:TextField = GlobalFunction.createTextField(cardWidth - 180,28,row.claimed ? "奖励已领取" : row.claimable ? "奖励已备好，点击领取" : row.kind == "daily" ? "完成任务即可领取" : "达成条件后解锁","",16,row.claimable ? 0xA9DEA1 : 0xBAC2CC);
         state.x = 16;
         state.y = 163;
         state.autoScale = true;
         state.hAlign = "left";
         state.touchable = false;
         addChild(state);
         var label:String = row.claimed ? "已领取" : row.claimable ? "领取奖励" : "未完成";
         if(row.kind == "repeat") label = row.claimable ? "领取" + row.available_count + "张" : "待达成";
         if(row.busy && row.claimable) label = "领取中…";
         adventureButton = new LOL_Scale9Button(label,132,42,"UI_btn_enterGame_0_0000");
         adventureButton.x = cardWidth - 148;
         adventureButton.y = 155;
         adventureButton.enabled = row.claimable && !row.busy;
         adventureButton.addEventListener("triggered",onAdventureButton);
         addChild(adventureButton);
         if(row.claimable && !row.busy)
         {
            adventureButton.alpha = 0.65;
            var ready:Tween = new Tween(adventureButton,0.22,"easeOut");
            ready.fadeTo(1);
            Starling.juggler.add(ready);
         }
         layoutWH();
      }

      private function addAdventureRewardIcon(row:Object) : void
      {
         var icon:DisplayObject;
         var reward:Object = row.reward;
         if(reward)
         {
            for(var type:String in reward)
            {
               if(type == "random_non_skin_orange_hero" || type == "random_normal_orange_equipment")
               {
                  icon = GlobalFunction.createImage("UI_bg_card_2_0003");
                  break;
               }
               if(type == "attrs" && reward.attrs.dust)
               {
                  var dust:Array = reward.attrs.dust as Array;
                  for(var i:int = 0; i < dust.length; i++)
                  {
                     if(Number(dust[i]) > 0)
                     {
                        icon = GlobalFunction.getAwardByType("dust",{"indexID_s":i,"numberIndex":dust[i]},false,null,"",true,1,this.parent ? this.parent.parent as List : null).ui;
                        break;
                     }
                  }
               }
               else if(type == "coin" || type == "culture_book" || type == "dn_stone" || type == "avatar" || type == "equip")
                  icon = GlobalFunction.getAwardByType(type,reward[type],false,null,"",true,1,this.parent ? this.parent.parent as List : null).ui;
               if(icon) break;
            }
         }
         if(!icon) icon = GlobalFunction.createImage("UI_award_ui_type_0016");
         var scale:Number = Math.min(72 / Math.max(1,icon.width),76 / Math.max(1,icon.height));
         icon.scaleX *= scale;
         icon.scaleY *= scale;
         icon.x = 18 + (72 - icon.width) / 2;
         icon.y = 57 + (76 - icon.height) / 2;
         addChild(icon);
         var caption:String = reward && reward.random_non_skin_orange_hero ? "随机橙卡" : reward && reward.random_normal_orange_equipment ? "随机橙装" : "任务奖励";
         var label:TextField = GlobalFunction.createTextField(80,24,caption,"",14,0xBFC1C4);
         label.x = 14;
         label.y = 133;
         label.autoScale = true;
         label.touchable = false;
         addChild(label);
      }

      private function onAdventureButton(param1:Event) : void
      {
         if(data && data.claimable && !data.busy && adventureButton && adventureButton.enabled)
         {
            adventureButton.enabled = false;
            adventureButton.text = "领取中…";
            dispatchEventWith("adventure_task_claim",true,data);
         }
      }

   }
}

