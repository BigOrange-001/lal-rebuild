package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.ui.element.ItemBase;
   import com.meng52.game.ui.element.ItemPVEcombat;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.screen.PanelCenterPVE;
   import com.meng52.game.ui.stage.GuideTools;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import feathers.controls.List;
   import feathers.data.ListCollection;
   import feathers.layout.VerticalLayout;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class PanelPVEcombat extends PanelCenterPVE
   {
      
      private var _awardSprite:Sprite;
      
      private var _imgStar:Image;
      
      private var _txtStar:TextField;
      
      private var _getAward:LOL_Button;
      
      private var _starObj:Object;
      
      public function PanelPVEcombat()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         var _loc2_:Boolean = false;
         this.removeEventListener("addedToStage",initializeHandler);
         this.setHeaderFun("","",true);
         _starObj = GlobalFunction.passBattleInfo(GlobalData.$tempPVE_battleID);
         if(_starObj.isPass)
         {
            if(_starObj.getGift)
            {
               _loc2_ = false;
            }
            else
            {
               _loc2_ = true;
            }
         }
         else
         {
            _loc2_ = false;
         }
         _awardSprite = new Sprite();
         _awardSprite.y = 60;
         _awardSprite.visible = _loc2_;
         this.addChild(_awardSprite);
         _imgStar = GlobalFunction.createImage("UI_icon_avatarStar_0_0000");
         _imgStar.scaleX = _imgStar.scaleY = 0.6;
         _imgStar.x = GlobalData.$mStarlingStageWidth * 0.3;
         _imgStar.y = 5;
         _awardSprite.addChild(_imgStar);
         this._txtStar = GlobalTextStyle.getTextField(GlobalFunction.getBattleStarById(GlobalData.$tempPVE_battleID,GlobalData.$tempPVE_type),30,16777011,"left",110,35);
         this._txtStar.x = _imgStar.x + _imgStar.width + 2;
         this._txtStar.y = _imgStar.y + 5;
         _awardSprite.addChild(_txtStar);
      }
      
      override protected function onTRIGGERED_btn(param1:Event) : void
      {
         var _btn:LOL_Button;
         var _event:Event = param1;
         var _owner:PanelPVEcombat = this;
         var _requestedBid:String = String(GlobalData.$tempPVE_battleID);
         var _requestedType:String = String(GlobalData.$tempPVE_type);
         var _requestedDiff:int = _requestedType == "status_pve_normal" ? 0 : (_requestedType == "status_pve_hard" ? 1 : -1);
         var send_pass_battle_gift:* = function():void
         {
            var _coinBefore:int = int(GlobalData.$userData.coin);
            SendServiceAMFFun.send_user_get_pass_battle_gift(function(_receipt:Object):void
            {
               _owner.reFun(_receipt,_coinBefore,_requestedBid,_requestedType);
            },{
               "bid":_requestedBid,
               "diff":_requestedDiff
            });
         };
         ItemBase.soundTriggered();
         _btn = _event.currentTarget as LOL_Button;
         if(_btn.enabled)
         {
            send_pass_battle_gift();
         }
         else
         {
            if(_btn.text == GlobalLanguageStr.getStr(20377))
            {
               GlobalFunction.popAlert("",GlobalLanguageStr.getStr(90244));
            }
            if(_btn.text == GlobalLanguageStr.getStr(90239))
            {
               GlobalFunction.popAlert("",GlobalLanguageStr.getStr(90245));
            }
         }
      }
      
      private function reFun(param1:Object, param2:int, param3:String, param4:String) : void
      {
         var _loc7_:Object = null;
         var _loc4_:int = 0;
         var _loc5_:int = 0;
         var _loc3_:Object = null;
         var _loc2_:String = null;
         var _loc6_:String = null;
         var _viewCurrent:Boolean = this.stage != null && String(GlobalData.$tempPVE_battleID) == param3 && String(GlobalData.$tempPVE_type) == param4;
         if(param1)
         {
            _loc7_ = param1.data;
            _loc4_ = int(_loc7_.coin);
            _loc5_ = _loc4_ - param2;
            _loc3_ = GlobalFunction.getAwardByType("coin",_loc5_);
            _loc2_ = _loc3_.msg;
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.coin = _loc4_;
               GlobalData.$userData.combat_score = _loc7_.combat_score;
            }
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
            if(_viewCurrent && this._getAward)
            {
               this._getAward.text = GlobalLanguageStr.getLanguageStr(20377);
               this._getAward.enabled = false;
            }
            _loc6_ = "sound03";
            SoundManager.getOnlyExample().playSound(_loc6_);
            GlobalFunction.popAward("coin",GlobalLanguageStr.getLanguageStr(90033,_loc2_),_loc5_,false);
         }
      }
      
      override public function clear() : void
      {
         if(_txtStar)
         {
            _txtStar.dispose();
            _txtStar = null;
         }
         if(_imgStar)
         {
            _imgStar.removeFromParent(true);
         }
         _imgStar = null;
         _starObj = null;
      }
      
      override public function update() : void
      {
         var _loc1_:String = GuideTools.checkGuideType();
         if(_loc1_ == "1")
         {
            _starObj = GlobalFunction.passBattleInfo(GlobalData.$tempPVE_battleID);
            if(!_starObj.isPass)
            {
               LayoutUIAnimation.getOnlyExample().addArrowhead(535,250);
            }
         }
         else if(_loc1_ == "2")
         {
            if(GlobalData.$tempPVE_type != "status_pve_hard")
            {
               LayoutUIAnimation.getOnlyExample().addArrowhead(580,170);
            }
            else
            {
               LayoutUIAnimation.getOnlyExample().addArrowhead(535,250);
            }
         }
         else if(_loc1_ == "3")
         {
            LayoutUIAnimation.getOnlyExample().addArrowhead(59,890,100);
         }
         else if(_loc1_ == "5")
         {
            if(GuideTools.getTeamNowNum() >= 3)
            {
               LayoutUIAnimation.getOnlyExample().addArrowhead(269,890,100);
            }
         }
         setList();
         addList();
         GuideMaster.getOnlyExample().nextGuideStep();
         GlobalFunction.$rndMCShow = false;
      }
      
      override public function onTRIGGERED(param1:Event) : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pve");
      }
      
      override public function setList() : void
      {
         var _rulerH:Number;
         var settings:Object;
         var _layout:VerticalLayout;
         var tweenComplete:* = function():void
         {
            isReady = true;
         };
         isReady = false;
         isOut = true;
         GlobalData.$mStarling.juggler.tween(this,0.4,{"onComplete":tweenComplete});
         this.delList();
         if(this.mList == null)
         {
            _rulerH = 110;
            settings = {
               "paging":0,
               "gap":0,
               "horizontalGap":20,
               "verticalGap":20,
               "paddingTop":0,
               "paddingRight":0,
               "paddingBottom":0,
               "paddingLeft":0,
               "horizontalAlign":"center",
               "verticalAlign":"top"
            };
            _layout = new VerticalLayout();
            _layout.paddingTop = settings.paddingTop;
            _layout.paddingRight = settings.paddingRight;
            _layout.paddingBottom = settings.paddingBottom;
            _layout.paddingLeft = settings.paddingLeft;
            _layout.horizontalAlign = settings.horizontalAlign;
            _layout.verticalAlign = settings.verticalAlign;
            _layout.hasVariableItemDimensions = true;
            this.mList = new List();
            this.mList.isSelectable = false;
            this.mList.width = GlobalData.$mStageWidth - 20;
            this.mList.height = mListH = GlobalData.$center_height_curr - 121 - _rulerH;
            this.mList.layout = _layout;
            this.mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
            this.mList.x = int((GlobalData.$mStageWidth - this.mList.width) * 0.5);
            this.mList.y = mListY = _rulerH;
            this.mList.snapScrollPositionsToPixels = true;
            this.addChild(this.mList);
            settings = null;
            _layout = null;
            this.mList.dataProvider = new ListCollection();
         }
      }
      
      override public function addList() : void
      {
         var _loc12_:Number = NaN;
         var _loc10_:Object = null;
         if(_starObj.isPass && !_starObj.getGift)
         {
            _loc12_ = 170;
            setListHeight(10);
         }
         else
         {
            _loc12_ = 110;
            setListHeight(50);
         }
         this.mList.y = mListY = _loc12_;
         var _loc6_:Object = GlobalFunction.getPveCombatCfg(GlobalData.$tempPVE_type);
         var _loc1_:Object = GlobalFunction.getPveBattleCfg(GlobalData.$tempPVE_type);
         var _loc3_:String = GlobalData.$tempPVE_battleID;
         this.changeStr_header(_loc1_[_loc3_].name);
         var _loc5_:Array = [];
         var _loc2_:String = "";
         var _loc9_:int = 0;
         var _loc4_:String = GlobalData.$tempPVE_battleID;
         var _loc8_:int = 0;
         var _loc7_:int = GlobalData.$diff;
         for(var _loc11_:Object in _loc6_)
         {
            _loc2_ = _loc11_.toString();
            if(_loc2_.indexOf(_loc4_) > -1)
            {
               _loc8_ = int(_loc2_.split("_")[2]);
               _loc10_ = _loc6_[_loc2_];
               _loc10_["id"] = _loc2_;
               _loc10_["status"] = 0;
               _loc10_["indexID_s"] = _loc8_;
               _loc10_["diff"] = _loc7_;
               if(GlobalData.$tempPVE_type == "status_pve_normal" || GlobalData.$tempPVE_type == "status_pve_hard")
               {
                  _loc9_ = GlobalFunction.check_pass_combat_main(_loc2_,_loc7_);
                  if(_loc9_ % 2 == 0)
                  {
                     _loc10_["status"] = 1;
                  }
                  if(_loc9_ > 0)
                  {
                     _loc5_.push(_loc10_);
                  }
               }
               else
               {
                  _loc5_.push(_loc10_);
               }
            }
         }
         if(_loc5_.length > 0)
         {
            _loc5_.sortOn("indexID_s",0x10 | 2);
            mList.y = mListY - 50;
            this.setListTimer(mList,_loc5_,ItemPVEcombat,false);
         }
         _loc6_ = null;
         _loc5_ = null;
         _loc10_ = null;
         this.mStatus_back = "";
      }
   }
}

