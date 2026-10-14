package com.meng52.game.ui.panel
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.equip.Equip;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.ui.element.ItemEquipSelect;
   import com.meng52.game.ui.element.ItemEquipSell;
   import com.meng52.game.ui.element.LOL_IconText;
   import com.meng52.game.ui.element.LOL_MagicButton;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelCenterMainAvatar;
   import com.meng52.game.ui.stage.GuideTools;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.data.ListCollection;
   import feathers.display.Scale9Image;
   import feathers.layout.VerticalLayout;
   import flash.geom.Rectangle;
   import flash.events.EventDispatcher;
   import starling.display.DisplayObject;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class PanelEquipSellSelect extends PanelCenterMainAvatar
   {
      
      public static var BTN_NAME_CLEAR:String = "btn_name_clear";
      
      public static var BTN_NAME_SELL:String = "btn_name_sell";
      
      public var mBtn_clear:LOL_Scale9Button;
      
      public var mBtn_sell:LOL_Scale9Button;
      
      public var mTxt_info:TextFieldHtmlRenderer;
      
      public var mEquip_curr:ItemEquipSelect;
      
      public var mBox_dust:Sprite;
      
      public var tempSelect:int = 0;
      
      public var mImg9_base:Scale9Image;
      
      private var _txt:LOL_IconText;
      
      public var bg:Scale9Image;
      
      public function PanelEquipSellSelect()
      {
         super();
      }
      
      public static function getEquipSellAttrs(param1:Array) : Object
      {
         var _loc11_:int = 0;
         var _loc7_:int = 0;
         var _loc5_:Equip = null;
         var _loc6_:Object = null;
         var _loc13_:String = null;
         var _loc14_:Number = NaN;
         var _loc2_:Number = NaN;
         var _loc4_:Array = null;
         var _loc3_:Array = null;
         var _loc12_:Number = NaN;
         var _loc10_:int = 0;
         var _loc8_:int = 0;
         var _loc9_:Object = {
            "gold":0,
            "mark":0,
            "dust":[0,0,0,0]
         };
         if(param1 != null)
         {
            _loc11_ = 0;
            _loc7_ = int(param1.length);
            _loc6_ = null;
            _loc13_ = "";
            _loc14_ = 0;
            _loc2_ = 0;
            _loc4_ = [0,0,0,0];
            _loc12_ = 0;
            _loc11_ = 0;
            while(_loc11_ < _loc7_)
            {
               _loc13_ = param1[_loc11_];
               _loc6_ = GlobalData.$userData.my_equips[_loc13_];
               _loc5_ = new Equip(_loc13_,_loc6_);
               _loc14_ += _loc5_.getSellGold();
               _loc2_ += _loc5_.getSellMark();
               _loc3_ = _loc5_.getSellDust();
               _loc8_ = int(_loc3_.length);
               _loc10_ = 0;
               while(_loc10_ < _loc8_)
               {
                  _loc12_ = Number(_loc3_[_loc10_]);
                  var _loc15_:int = _loc10_;
                  var _loc16_:Number = _loc4_[_loc15_] + (_loc12_ >= 0 ? _loc12_ : 0);
                  _loc4_[_loc15_] = _loc16_;
                  _loc10_++;
               }
               _loc11_++;
            }
            _loc9_.gold = _loc14_;
            _loc9_.mark = _loc2_;
            _loc9_.dust = _loc4_;
         }
         return _loc9_;
      }
      
      public static function getDustUIs() : Sprite
      {
         var _loc5_:Image = null;
         var _loc3_:TextField = null;
         var _loc4_:Sprite = new Sprite();
         var _loc7_:int = 0;
         var _loc6_:int = 4;
         var _loc2_:Array = LOL_MagicButton.TXT_COLOR;
         var _loc1_:Number = 65;
         _loc7_ = 0;
         while(_loc7_ < _loc6_)
         {
            _loc5_ = GlobalFunction.createImage("UI_magic_money_000" + _loc7_);
            _loc5_.scaleX = _loc5_.scaleY = 0.6;
            _loc5_.name = "dustIcon" + _loc7_;
            _loc3_ = GlobalTextStyle.getTextField(GlobalData.$userData.attrs.dust[_loc7_] + "",20,_loc2_[_loc7_],"left",_loc1_,35);
            _loc3_.name = "dustTxt" + _loc7_;
            _loc5_.x = _loc7_ * (_loc5_.width + _loc1_);
            _loc3_.x = _loc5_.x + _loc5_.width;
            _loc3_.y = 2;
            _loc4_.addChild(_loc5_);
            _loc4_.addChild(_loc3_);
            _loc7_++;
         }
         _loc4_.flatten();
         return _loc4_;
      }
      
      public static function updateDustNum(param1:Sprite) : void
      {
         var _loc4_:int = 0;
         var _loc2_:int = 0;
         var _loc3_:DisplayObject = null;
         if(param1 != null)
         {
            _loc4_ = 0;
            _loc2_ = 4;
            _loc4_ = 0;
            while(_loc4_ < _loc2_)
            {
               _loc3_ = param1.getChildByName("dustTxt" + _loc4_);
               if(_loc3_ != null)
               {
                  (_loc3_ as TextField).text = GlobalData.$userData.attrs.dust[_loc4_] + "";
               }
               _loc4_++;
            }
            param1.flatten();
         }
      }
      
      public function checkGuide() : void
      {
         LayoutUIAnimation.getOnlyExample().clearIfNoGuide();
         var _loc1_:String = GuideTools.checkGuideType();
         if(_loc1_ == "4")
         {
            if(GlobalData.$tempEquipFunId == 1)
            {
               if(mList.dataProvider.length > 0)
               {
                  LayoutUIAnimation.getOnlyExample().addArrowhead(563,342,0);
               }
            }
            else
            {
               LayoutUIAnimation.getOnlyExample().addArrowhead(60,154,0);
            }
         }
         else if(_loc1_ == "6")
         {
            if(GlobalData.$tempEquipFunId == 2)
            {
               if(mList.dataProvider.length > 0)
               {
                  LayoutUIAnimation.getOnlyExample().addArrowhead(565,340,0);
               }
            }
            else
            {
               LayoutUIAnimation.getOnlyExample().addArrowhead(175,154,0);
            }
         }
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         var _loc2_:Array = [{"label":GlobalLanguageStr.getLanguageStr(20236)},{"label":GlobalLanguageStr.getLanguageStr(20263)},{"label":GlobalLanguageStr.getLanguageStr(20264)},{"label":GlobalLanguageStr.getLanguageStr(20265)},{"label":GlobalLanguageStr.getLanguageStr(20266)},{"label":GlobalLanguageStr.getLanguageStr(20267)}];
         this.setRadioBar(_loc2_,tabBar_changeHandler);
         this.mRadioBar.selectedIndex = 0;
         checkGuide();
         mRadioBar.x = 15;
         mRadioBar.y = 83;
         this.initOtherUIs();
      }
      
      private function tabBar_changeHandler(param1:Event) : void
      {
         tempSelect = 0;
         GlobalData.$tempEquipSellArr = [];
         GlobalData.$mEventDispatcher.dispatchEventWith("update_equip_sell_data");
         setList();
         addList();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         GlobalData.$mEventDispatcher.removeEventListener("update_equip_sell_data",this.onUPDATE_DATA);
         GlobalData.$mStarling.juggler.removeTweens(this);
         GlobalFunction.clearEquipSell();
         if(mBox_dust)
         {
            StarlingTools.removeChildrenClear(mBox_dust);
            mBox_dust.removeFromParent(true);
         }
         if(mTxt_info)
         {
            mTxt_info.removeFromParent(true);
            mTxt_info.dispose();
         }
         if(mBtn_clear)
         {
            mBtn_clear.removeFromParent(true);
            mBtn_clear.dispose();
         }
         if(mBtn_sell)
         {
            mBtn_sell.removeFromParent(true);
            mBtn_sell.dispose();
         }
         if(mImgBg)
         {
            mImgBg.removeFromParent(true);
         }
         if(mEquip_curr)
         {
            mEquip_curr.removeFromParent(true);
            mEquip_curr.clear();
         }
         super.onREMOVED_FROM_STAGE(param1);
         mEquip_curr = null;
         mTxt_info = null;
         mBtn_clear = null;
         mBtn_sell = null;
         mImgBg = null;
         mBox_dust = null;
         tempSelect = 0;
      }
      
      public function initOtherUIs() : void
      {
         bg = GlobalFunction.createScale9Image("UI_bg_9slice_4_0000",630,120,new Rectangle(110,60,30,15));
         bg.x = int((GlobalData.$mStageWidth - bg.width) * 0.5);
         bg.y = GlobalData.$center_height_curr - 121 - bg.height - 40;
         this.addChild(bg);
         this.mBtn_clear = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20228),125,45,"UI_btn_enterGame_0_0000");
         this.mBtn_sell = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90191),125,45,"UI_btn_enterGame_0_0000");
         this.mBtn_clear.x = bg.x + 20;
         this.mBtn_sell.x = bg.x + bg.width - this.mBtn_sell.width - 25;
         this.addChild(this.mBtn_clear);
         this.addChild(this.mBtn_sell);
         this.mBtn_clear.name = BTN_NAME_CLEAR;
         this.mBtn_sell.name = BTN_NAME_SELL;
         this.mBtn_clear.addEventListener("triggered",this.onTRIGGERED_btns);
         this.mBtn_sell.addEventListener("triggered",this.onTRIGGERED_btns);
         this.mBtn_sell.y = this.mBtn_clear.y = bg.y + 35;
         GlobalData.$mEventDispatcher.addEventListener("update_equip_sell_data",this.onUPDATE_DATA);
         var _loc1_:String = GlobalLanguageStr.getLanguageStr(20458);
         _txt = new LOL_IconText(_loc1_);
         _txt.x = 7;
         _txt.y = bg.y + bg.height + 3;
         _txt.bgWidth = 626;
         addChild(_txt);
         mBox_dust = getDustUIs();
         mBox_dust.x = MainConfig.$isEA ? this.mBtn_clear.x + this.mBtn_clear.width - 13 : this.mBtn_clear.x + this.mBtn_clear.width - 30;
         mBox_dust.y = this.mBtn_clear.y + 90;
         addChild(mBox_dust);
         formatTxtInfo();
         setList();
         addList();
         GuideMaster.getOnlyExample().checkGuide("M9_1");
      }
      
      public function onTRIGGERED_btns(param1:Event) : void
      {
         var _loc6_:Array = null;
         var _loc16_:Object = null;
         var _loc12_:Object = null;
         var _loc4_:Array = null;
         var _loc14_:Array = null;
         var _loc3_:Array = null;
         var _loc10_:String = null;
         var _loc8_:int = 0;
         var _loc5_:Object = null;
         var _loc2_:String = null;
         var _loc9_:Array = null;
         var _loc7_:int = 0;
         var _loc11_:String = null;
         var _loc13_:String = null;
         var _loc15_:EventDispatcher = param1.currentTarget;
         if(_loc15_.name == BTN_NAME_CLEAR)
         {
            if(GlobalData.$tempEquipSellArr.length > 0)
            {
               tempSelect = 0;
            }
            else
            {
               tempSelect = 10;
            }
            GlobalData.$tempEquipSellArr = [];
            GlobalData.$tempEquipSellItem = {};
            setList();
            addList();
            GlobalData.$mEventDispatcher.dispatchEventWith("update_equip_sell_data");
         }
         else if(_loc15_.name == BTN_NAME_SELL)
         {
            if(GlobalData.$tempEquipSellArr.length > 0)
            {
               _loc6_ = GlobalData.$tempEquipSellArr;
               _loc16_ = getEquipSellAttrs(GlobalData.$tempEquipSellArr);
               _loc12_ = {
                  "ok":service_sell,
                  "no":GlobalFunction.functionNull
               };
               _loc4_ = _loc16_["dust"] as Array;
               _loc14_ = GlobalLanguageStr.getLanguageStr(90197).split("$");
               _loc3_ = GlobalLanguageStr.getLanguageStr(90211).split("$");
               _loc10_ = "";
               if(_loc16_["mark"] > 0)
               {
                  _loc10_ = "[" + _loc16_["mark"] + "]" + GlobalLanguageStr.getLanguageStr(20272);
               }
               _loc8_ = 0;
               _loc8_ = 0;
               while(_loc8_ < _loc4_.length)
               {
                  if(_loc4_[_loc8_] > 0)
                  {
                     _loc10_ += "[" + _loc4_[_loc8_] + "]" + _loc14_[_loc8_];
                  }
                  _loc8_++;
               }
               _loc5_ = null;
               _loc2_ = "";
               _loc9_ = [0,0,0,0,0,0,0];
               _loc8_ = 0;
               while(_loc8_ < GlobalData.$tempEquipSellArr.length)
               {
                  _loc5_ = GlobalData.$userData.my_equips[GlobalData.$tempEquipSellArr[_loc8_]];
                  _loc2_ = _loc5_["eid"];
                  _loc7_ = 0;
                  if(_loc5_.hasOwnProperty("alchemy"))
                  {
                     _loc7_ += int(_loc5_["alchemy"][1]);
                  }
                  var _loc17_:Number = int(_loc2_.charAt(_loc2_.length - 1)) - 1 + _loc7_;
                  var _loc18_:Number = _loc9_[_loc17_] + 1;
                  _loc9_[_loc17_] = _loc18_;
                  _loc8_++;
               }
               _loc11_ = "";
               _loc8_ = 0;
               while(_loc8_ < _loc9_.length)
               {
                  if(_loc9_[_loc8_] > 0)
                  {
                     _loc11_ += "{" + _loc9_[_loc8_] + "}" + _loc3_[_loc8_];
                  }
                  _loc8_++;
               }
               _loc13_ = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90079,_loc11_,_loc16_["gold"],_loc10_),GlobalTextStyle.COLOR_W_Y_Y_G);
               GlobalFunction.popAlert("",_loc13_,_loc12_);
            }
            else
            {
               GlobalFunction.popAlert(GlobalLanguageStr.getLanguageStr(90010),GlobalLanguageStr.getLanguageStr(97003));
            }
         }
      }
      
      private function service_sell() : void
      {
         SendServiceAMFFun.send_user_equip_sell(re_equip_sell,{"eqids":GlobalData.$tempEquipSellArr.concat()});
      }
      
      private function re_equip_sell(param1:Object) : void
      {
         if(GlobalFunction.isMalformedProfileReceipt(param1))
         {
            return;
         }
         if(param1["params"] == null || !(param1["params"]["eqids"] is Array))
         {
            return;
         }
         var _loc5_:int = 0;
         SoundManager.getOnlyExample().playSound("E_9005",0.2);
         SoundManager.getOnlyExample().playSound("E_9021",0.4);
         var _loc2_:Array = param1.data;
         var _loc4_:Object = param1["params"];
         var _loc3_:Array = _loc4_["eqids"].concat();
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.mark = _loc2_[0];
            GlobalData.$userData.gold = _loc2_[1];
            _loc5_ = 0;
            while(_loc5_ < _loc3_.length)
            {
               delete GlobalData.$userData.my_equips[_loc3_[_loc5_]];
               _loc5_++;
            }
            GlobalData.$userData.attrs.dust = _loc2_[2];
         }
         // Versioned receipts never write profile fields here. Even when a
         // newer snapshot arrived first, this successful request must clear
         // its sold IDs from transient selection and refresh the open view.
         for each(var _soldId:String in _loc3_)
         {
            var _selectedIndex:int = GlobalData.$tempEquipSellArr.indexOf(_soldId);
            while(_selectedIndex >= 0)
            {
               GlobalData.$tempEquipSellArr.splice(_selectedIndex,1);
               _selectedIndex = GlobalData.$tempEquipSellArr.indexOf(_soldId);
            }
         }
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
          // re_equip_sell is a bound instance method. The sold IDs are removed
          // from the transient selection above even when this view is closed;
          // only rebuild the renderer while the same panel is on stage.
          if(this.stage)
          {
             update();
          }
      }
      
      public function formatTxtInfo() : void
      {
         this.setTxtInfo(GlobalLanguageStr.getLanguageStr(90192,GlobalData.$tempEquipSellArr.length,10),GlobalLanguageStr.getLanguageStr(20463,Tools.getElementNum(GlobalData.$userData.my_equips),GlobalData.$mConfig_simple.equip_config[0]));
         if(GlobalData.$tempEquipSellArr.length > 0)
         {
            this.mBtn_sell.enabled = true;
            this.mBtn_clear.text = GlobalLanguageStr.getLanguageStr(20071);
         }
         else
         {
            this.mBtn_sell.enabled = false;
            this.mBtn_clear.text = GlobalLanguageStr.getLanguageStr(20228);
         }
      }
      
      public function setTxtInfo(param1:*, param2:* = null, param3:* = null) : void
      {
         if(this.mTxt_info == null)
         {
            this.mTxt_info = GlobalTextStyle.getHtmlTextRenderer();
            this.mTxt_info.touchable = false;
            this.mTxt_info.width = GlobalData.$mStageWidth * 0.5;
            this.mTxt_info.textFormat = GlobalTextStyle.style_format();
            this.mTxt_info.textFormat.leading = 0;
            this.mTxt_info.isHTML = true;
            this.mTxt_info.x = this.mBtn_clear.x + this.mBtn_clear.width + 20 + 20;
            this.mTxt_info.y = this.mBtn_clear.y - 5;
            this.addChild(this.mTxt_info);
         }
         this.setTxtInfoCo(param1,param2,param3);
      }
      
      public function setTxtInfoCo(param1:*, param2:* = null, param3:* = null) : void
      {
         var _loc4_:Array = [Tools.formatLineX(param1,GlobalTextStyle.COLOR_0x4B2C1B,1000,20),Tools.formatLineX(param2,GlobalTextStyle.COLOR_0x4B2C1B,1000,20),Tools.formatLineX(param3,GlobalTextStyle.COLOR_0x4B2C1B,1000,20)];
         this.mTxt_info.text = Tools.formatHtmlTextBr(_loc4_,"left");
      }
      
      private function onUPDATE_DATA(param1:Event = null) : void
      {
         this.formatTxtInfo();
      }
      
      override public function update() : void
      {
         super.update();
         this.formatTxtInfo();
         updateDustNum(mBox_dust);
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
            _rulerH = 170;
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
            this.mList.width = GlobalData.$mStageWidth - 10;
            this.mList.height = mListH = GlobalData.$center_height_curr - 121 - 330;
            this.mList.layout = _layout;
            this.mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
            this.mList.x = -10;
            this.mList.y = mListY = _rulerH;
            this.mList.snapScrollPositionsToPixels = true;
            this.addChildAt(this.mList,0);
            settings = null;
            _layout = null;
            this.mList.dataProvider = new ListCollection();
         }
      }
      
      override public function addList() : void
      {
         var _loc8_:String = null;
         var _loc13_:Object = null;
         var _loc9_:String = null;
         var _loc6_:Object = null;
         var _loc14_:Array = null;
         var _loc3_:Equip = null;
         var _loc5_:int = 0;
         var _loc4_:int = 0;
         var _loc10_:int = 0;
         GlobalFunction.clearEquipSell();
         var _loc7_:Object = GlobalData.$userData.attrs.equip_forge;
         var _loc2_:Object = GlobalData.$userData.my_equips;
         var _loc1_:Array = [];
         var _loc11_:int = this.mRadioBar.selectedIndex;
         var _loc12_:String = GlobalFunction.checkEquipType(_loc11_);
         for(_loc6_ in _loc2_)
         {
            _loc8_ = _loc6_.toString();
            _loc3_ = new Equip(_loc8_);
            if(_loc7_ && _loc7_.eqid == _loc8_)
            {
               trace(_loc8_);
            }
            else
            {
               _loc13_ = _loc2_[_loc8_];
               _loc9_ = _loc13_["eid"];
               _loc5_ = int(_loc13_.hasOwnProperty("alchemy") ? _loc13_["alchemy"][1] : 0);
               if(_loc11_ == 0 || _loc9_.indexOf(_loc12_) > -1)
               {
                  _loc14_ = _loc9_.split("_");
                  _loc13_["id"] = _loc8_;
                  _loc13_["status"] = 0;
                  _loc13_["sort_1"] = _loc3_.getSellValue();
                  _loc1_.push(_loc13_);
               }
            }
         }
         if(_loc1_.length > 0)
         {
            _loc1_.sortOn(["sort_1"],[0x10 | 2]);
            _loc10_ = 0;
            _loc4_ = 0;
            while(_loc4_ < _loc1_.length)
            {
               if(_loc10_ >= tempSelect)
               {
                  break;
               }
               _loc13_ = _loc1_[_loc4_];
               if(_loc13_["sort_1"] < 0)
               {
                  break;
               }
               if(!_loc13_["lock"])
               {
                  GlobalData.$tempEquipSellArr.push(_loc13_["id"]);
                  _loc10_++;
               }
               _loc4_++;
            }
            if(tempSelect > 0 && _loc10_ == 0)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90115),false,"A_3002_1");
            }
            tempSelect = 0;
            this.setListTimer(mList,_loc1_,ItemEquipSell,false);
         }
         if(_loc1_.length <= 0)
         {
            this.setTips(GlobalLanguageStr.getLanguageStr(20505));
         }
         else if(mTips)
         {
            this.delTips();
         }
         _loc1_ = null;
         _loc2_ = null;
      }
   }
}

