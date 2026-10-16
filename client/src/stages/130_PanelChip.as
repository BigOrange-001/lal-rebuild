package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.equip.Equip;
   import com.meng52.game.module.guide.GuideMaster;
   import com.meng52.game.ui.element.ItemFragment;
   import com.meng52.game.ui.element.ItemFragmentChild;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.screen.PanelCenterMainAvatar;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.data.ListCollection;
   import feathers.layout.TiledRowsLayout;
   import flash.events.TimerEvent;
   import flash.utils.Timer;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class PanelChip extends PanelCenterMainAvatar
   {
      
      public static var $tabBarSelectedIndex:int = -1;
      
      private var mBox_fragment:Sprite;
      
      private var mTxt_fName:TextField;
      
      private var mTxt_fPower:TextField;
      
      private var mTxt_fTimer:TextField;
      
      private var mTimer_fragment:Timer;
      
      private var mBox_child:Sprite;
      
      private var mBox_child_item:Sprite;
      
      private var mBox_child_close:LOL_Button;
      
      private var mInfo:TextField;
      
      public function PanelChip()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         var _loc2_:Number = NaN;
         _loc2_ = 200;
         GlobalData.$mEventDispatcher.addEventListener("update_fragment_list",onUPDATE_FRAGMENT_LIST);
         GlobalData.$mEventDispatcher.addEventListener("update_fragment_child",setFragment_child);
         mBox_fragment = new Sprite();
         addChild(mBox_fragment);
         mTxt_fName = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20429),30,16777215,"left",150,46);
         mTxt_fPower = GlobalTextStyle.getTextField("",20,16777215,"right",200,35);
         mTxt_fName.x = 10;
         mTxt_fName.y = 10;
         mTxt_fPower.x = GlobalData.$mStageWidth - 200 - 10;
         mTxt_fPower.y = 15;
         mBox_fragment.y = 140;
         mInfo = mTxt_fName = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90658),20,16777215,"left",300,46);
         mInfo.x = 10;
         mInfo.y = mInfo.height + 5;
         mBox_fragment.addChild(mInfo);
         setList();
         selectFragment();
         updateFragmentEn();
         this.mTimer_fragment = new Timer(1000,0);
         this.mTimer_fragment.addEventListener("timer",this.onTIMER_fragment);
         this.mTimer_fragment.start();
         if(GuideMaster.getOnlyExample().checkGuide("M14_1") == -1)
         {
            LayoutUIAnimation.getOnlyExample().clearIfNoGuide();
         }
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(mTimer_fragment)
         {
            mTimer_fragment.stop();
            mTimer_fragment.removeEventListener("timer",onTIMER_fragment);
            mTimer_fragment = null;
         }
         GlobalData.$mEventDispatcher.removeEventListener("update_fragment_list",onUPDATE_FRAGMENT_LIST);
         GlobalData.$mEventDispatcher.removeEventListener("update_fragment_child",setFragment_child);
         super.onREMOVED_FROM_STAGE(param1);
      }
      
      private function onTIMER_fragment(param1:TimerEvent) : void
      {
         this.updateFragmentEn();
      }
      
      private function selectFragment() : void
      {
         SendServiceAMFFun.send_user_get_my_fragments(reFragment);
      }
      
      private function setList() : void
      {
         var _loc3_:Number = NaN;
         var _loc2_:Object = null;
         var _loc1_:TiledRowsLayout = null;
         if(this.mList == null)
         {
            _loc3_ = 170;
            _loc2_ = {
               "paging":0,
               "gap":0,
               "horizontalGap":0,
               "verticalGap":50,
               "paddingTop":10,
               "paddingRight":10,
               "paddingBottom":60,
               "paddingLeft":10,
               "horizontalAlign":"left",
               "verticalAlign":"top"
            };
            _loc1_ = new TiledRowsLayout();
            _loc1_.paddingTop = _loc2_.paddingTop;
            _loc1_.paddingRight = _loc2_.paddingRight;
            _loc1_.paddingBottom = _loc2_.paddingBottom;
            _loc1_.paddingLeft = _loc2_.paddingLeft;
            _loc1_.horizontalGap = _loc2_.horizontalGap;
            _loc1_.verticalGap = _loc2_.verticalGap;
            _loc1_.horizontalAlign = _loc2_.horizontalAlign;
            _loc1_.verticalAlign = _loc2_.verticalAlign;
            _loc1_.useSquareTiles = false;
            this.mList = new List();
            this.mList.clipContent = true;
            this.mList.autoHideBackground = true;
            this.mList.isSelectable = false;
            this.mList.width = GlobalData.$mStageWidth;
            this.mList.height = GlobalData.$center_height_curr - 121 - 150;
            this.mList.layout = _loc1_;
            this.mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
            this.mList.x = 30;
            this.mList.y = 220;
            this.mList.snapScrollPositionsToPixels = true;
            this.addChild(this.mList);
            _loc2_ = null;
            _loc1_ = null;
            this.mList.dataProvider = new ListCollection();
         }
      }
      
      private function reFragment(param1:Object) : void
      {
         if(stage == null)
         {
            return;
         }
         var _loc9_:Array = null;
         var _loc4_:String = null;
         var _loc7_:Equip = null;
         var _loc6_:String = null;
         var _loc8_:Array = null;
         var _loc2_:String = null;
         var _loc10_:Array = param1.data as Array;
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.fragment["equips"] = _loc10_[0]["equips"];
         }
         var _loc3_:Object = _loc10_[1];
         var _loc5_:int = Tools.getElementNum(_loc3_);
         if(_loc5_ > 0)
         {
            _loc4_ = "";
            _loc6_ = GlobalLanguageStr.getLanguageStr(20437);
            _loc8_ = [Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90184),GlobalTextStyle.COLOR_W_Y_Y_G,18,20),""];
            for(var _loc11_:Object in _loc3_)
            {
               _loc4_ = _loc11_.toString();
               _loc9_ = _loc3_[_loc11_];
               _loc7_ = new Equip(_loc4_);
               _loc8_.push(Tools.formatLineX("[" + _loc7_.equipData.name + _loc6_ + "] " + "{-" + _loc9_.length + "}",GlobalTextStyle.COLOR_W_Y_Y_G,1000,20));
               _loc7_.clear();
            }
            SoundManager.getOnlyExample().playSound("stun");
            _loc2_ = GlobalData.$mConfig_simple.show_id[8];
            GlobalFunction.popTips("",Tools.formatHtmlTextBr(_loc8_,"center"),{"aid":_loc2_});
         }
         addList();
      }
      
      private function addList() : void
      {
         var _cfg:Object;
         var _fragment_keep:Array;
         var _const_cfg:Array;
         var i:Object;
         var _data:Object;
         var _itemArr:Array;
         var _id:String;
         var j:int;
         var h:Object;
         var _idArr:Array;
         var initChip:* = function(param1:String):Array
         {
            var _loc3_:int = 0;
            var _loc2_:Array = [];
            _loc3_ = 0;
            while(_loc3_ < int(param1))
            {
               _loc2_[_loc3_] = 0;
               _loc3_++;
            }
            return _loc2_;
         };
         if(this.mTabBar)
         {
            $tabBarSelectedIndex = this.mTabBar.selectedIndex;
         }
         _cfg = GlobalData.$userData.fragment["equips"];
         _fragment_keep = GlobalData.$mConfig_simple.fragment_keep;
         _const_cfg = Tools.clone(_fragment_keep);
         _itemArr = [];
         _id = "";
         j = 0;
         _idArr = null;
         for(i in _cfg)
         {
            _id = i.toString();
            _idArr = _id.split("_");
            _data = {};
            _data["id"] = i.toString();
            _data["data_base"] = _cfg[i] as Array;
            _data["sort_1"] = _idArr[2];
            _data["sort_2"] = _idArr[1];
            if(GlobalFunction.getFragmentNumType(_data["data_base"]) != 0)
            {
               j = 0;
               while(j < _const_cfg.length)
               {
                  if(_const_cfg[j] == _data["id"])
                  {
                     _const_cfg.splice(j,1);
                     break;
                  }
                  j = j + 1;
               }
               _itemArr.push(_data);
            }
            else
            {
               j = 0;
               while(j < _const_cfg.length)
               {
                  if(_const_cfg[j] == _data["id"])
                  {
                     _itemArr.push(_data);
                     _const_cfg.splice(j,1);
                     break;
                  }
                  j = j + 1;
               }
            }
         }
         if(_const_cfg.length > 0)
         {
            j = 0;
            while(j < _const_cfg.length)
            {
               _id = _const_cfg[j];
               _idArr = _id.split("_");
               _data = {};
               _data["id"] = _id.toString();
               _data["data_base"] = initChip(_idArr[2]);
               _data["sort_1"] = _idArr[2];
               _data["sort_2"] = _idArr[1];
               _itemArr.push(_data);
               j = j + 1;
            }
         }
         this.delTips();
         if(_itemArr.length > 0)
         {
            _itemArr.sortOn(["sort_1","sort_2"],[0x10 | 2,16]);
            this.setListTimer(mList,_itemArr,ItemFragment,false);
         }
         else
         {
            this.setTips(GlobalLanguageStr.getLanguageStr(90182));
         }
      }
      
      private function updateFragmentEn() : void
      {
         var _loc1_:Object = GlobalFunction.getFragmentPower();
         if(mTxt_fPower)
         {
            mTxt_fPower.text = GlobalLanguageStr.getLanguageStr(20430,_loc1_.energy,_loc1_.max);
         }
      }
      
      private function onUPDATE_FRAGMENT_LIST(param1:Event) : void
      {
         setList();
         selectFragment();
      }
      
      private function setFragment_child(param1:Event) : void
      {
         var _loc12_:ItemFragmentChild = null;
         var _loc13_:Object = param1.data;
         mBox_child = new Sprite();
         addChild(mBox_child);
         mBox_child.y = mBox_fragment.y;
         var _loc3_:Quad = Tools.newQuad(GlobalData.$mStageWidth,GlobalData.$center_height_curr - 121,0,0,1118481);
         _loc3_.alpha = 0.75;
         mBox_child.addChild(_loc3_);
         var _loc14_:Image = GlobalFunction.createImage("UI_fragment_bg_0000");
         _loc14_.x = int((GlobalData.$mStageWidth - _loc14_.width) * 0.5);
         mBox_child.addChild(_loc14_);
         var _loc5_:Equip = new Equip(_loc13_["id"]);
         var _loc10_:Image = GlobalFunction.getEquipUI(_loc5_.equipData.res);
         _loc10_.x = _loc14_.x + 35;
         _loc10_.y = _loc14_.y + 25;
         mBox_child.addChild(_loc10_);
         var _loc7_:TextField = GlobalTextStyle.getTextField(_loc5_.equipData.name,24,16777215,"left",160,35);
         _loc7_.x = _loc10_.x + _loc10_.width + 10;
         _loc7_.y = _loc10_.y;
         mBox_child.addChild(_loc7_);
         var _loc16_:TextField = GlobalTextStyle.getTextField(_loc5_.getBookSkill().getInfo(),20,16777215,"left",350,35 * 2);
         _loc16_.x = _loc7_.x;
         _loc16_.y = _loc7_.y + 35;
         mBox_child.addChild(_loc16_);
         mBox_child_close = GlobalFunction.createButton_5("","UI_regist_btn_3_0000");
         mBox_child_close.x = _loc14_.x + _loc14_.width - mBox_child_close.width - 20;
         mBox_child_close.y = 20;
         mBox_child_close.addEventListener("triggered",onTRIGGERED_closeChild);
         mBox_child.addChild(mBox_child_close);
         mBox_child_item = new Sprite();
         mBox_child.addChild(mBox_child_item);
         var _loc4_:Array = _loc13_["data_base"] as Array;
         var _loc8_:int = 0;
         var _loc6_:int = int(_loc4_.length);
         var _loc15_:Object = null;
         _loc8_ = 0;
         while(_loc8_ < _loc6_)
         {
            _loc15_ = {};
            _loc15_["id"] = _loc13_["id"];
            _loc15_["indexID_s"] = _loc8_;
            _loc15_["data_base"] = _loc4_[_loc8_];
            _loc12_ = new ItemFragmentChild(_loc15_);
            _loc12_.x = _loc8_ % 3 * 150;
            _loc12_.y = Math.floor(_loc8_ / 3) * 95;
            mBox_child_item.addChild(_loc12_);
            _loc8_++;
         }
         var _loc11_:int = Math.floor(_loc8_ / 3);
         var _loc9_:Number = _loc11_ > 0 ? 450 : _loc8_ * 150;
         var _loc2_:Number = Math.ceil(_loc8_ / 3) * 95;
         mBox_child_item.x = _loc14_.x + int((_loc14_.width - _loc9_) * 0.5);
         mBox_child_item.y = _loc14_.y + 135 + int((200 - _loc2_) * 0.5);
      }
      
      private function onTRIGGERED_closeChild(param1:Event) : void
      {
         delFragment_child();
      }
      
      private function delFragment_child() : void
      {
         if(mBox_child_item)
         {
            StarlingTools.removeChildrenClear(mBox_child_item);
            mBox_child_item.removeFromParent(true);
         }
         if(mBox_child_close)
         {
            mBox_child_close.removeFromParent(true);
         }
         if(mBox_child)
         {
            StarlingTools.removeChildrenClear(mBox_child);
            mBox_child.removeFromParent(true);
         }
         if(mInfo)
         {
            mInfo.removeFromParent(true);
         }
         mBox_child = null;
         mBox_child_close = null;
         mBox_child_item = null;
         mInfo = null;
      }
   }
}

