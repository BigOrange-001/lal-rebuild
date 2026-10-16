package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.module.equip.Equip;
   import com.meng52.game.module.skill.SkillSet;
   import com.meng52.game.ui.element.ItemFragmentChild;
   import com.meng52.game.ui.element.LOL_Button;
   import com.meng52.game.ui.element.LOL_StarLevel;
   import com.meng52.game.ui.screen.PanelBase;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class PanelInfoChip extends PanelBase
   {
      
      public var _data:Object;
      
      private var mBox_child:Sprite;
      
      private var _equipUI:Image;
      
      private var _tName:TextField;
      
      private var _tLv:TextField;
      
      private var _tInfo:TextField;
      
      private var _tInfo_2:TextField;
      
      private var _tName_shipin:TextField;
      
      private var _equip:Equip;
      
      private var _skillset:SkillSet;
      
      private var mBox_child_close:LOL_Button;
      
      private var skillImg:LOL_Button;
      
      private var mBox_child_item:Sprite;
      
      private var mBg_img:Scale9Image;
      
      private var mBg_bg_equip:Image;
      
      private var mEquip:Equip;
      
      protected var _avatar:Avatar;
      
      public function PanelInfoChip(param1:Object)
      {
         super();
         _data = param1;
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         if(_data == null || !_data.id || GlobalData.$mConfig_equip[_data.id] == null)
         {
            setPopPanelBg("碎片详情",580);
            return;
         }
         _equip = new Equip(_data["id"]);
         _skillset = _equip.getBookSkill();
         this.setPopPanelBg(_equip.equipData.name + GlobalLanguageStr.getLanguageStr(20437),580);
         this.setFragment_child();
      }
      
      private function setFragment_child() : void
      {
         var _loc12_:* = null;
         var _loc13_:ItemFragmentChild = null;
         mBox_child = new Sprite();
         addChild(mBox_child);
         mBox_child.y = 20;
         var _loc2_:Quad = Tools.newQuad(GlobalData.$mStageWidth,GlobalData.$center_height_curr - 121,0,0,1118481);
         _loc2_.alpha = 0.75;
         mBg_img = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",mImg9_baseBg.width - 175,180,new Rectangle(110,55,70,20));
         mBg_img.x = 140;
         mBg_img.y = 140;
         mImg9_baseBg.addChild(mBg_img);
         var _loc15_:Image = GlobalFunction.createImage("UI_fragment_bg_0000");
         _loc15_.x = int((GlobalData.$mStageWidth - _loc15_.width) * 0.5);
         mBg_bg_equip = GlobalFunction.createImage("UI_bg_equip_1_0000");
         mBg_bg_equip.x = 25;
         mBg_bg_equip.y = mBg_img.height * 2 / 3 - 10;
         mBg_img.addChild(mBg_bg_equip);
         _equipUI = GlobalFunction.getEquipUI(_equip.equipData.res);
         _equipUI.x = 40;
         _equipUI.y = _equipUI.height * 1.5;
         mImg9_baseBg.addChild(_equipUI);
         skillImg = GlobalFunction.createButton_5(GlobalLanguageStr.getLanguageStr(90409),"UI_btn_3_0000",true,false,20);
         skillImg.x = skillImg.width / 2;
         skillImg.y = skillImg.height;
         skillImg.fontColor = 16777215;
         mBg_img.addChild(skillImg);
         var _loc4_:LOL_StarLevel = new LOL_StarLevel(_data["id"].split("_")[2],_data["id"].split("_")[2],0.35);
         _loc4_.x = mImg9_baseBg.width - _loc4_.width - 50;
         _loc4_.y = 105;
         mImg9_baseBg.addChild(_loc4_);
         _tName = GlobalTextStyle.getTextField(_equip.equipData.name,20,1118481,"left",160,35);
         _tName.x = skillImg.x + skillImg.width + 10;
         _tName.y = skillImg.y;
         mBg_img.addChild(_tName);
         _tLv = GlobalTextStyle.getTextField(_data["id"].split("_")[2] + GlobalLanguageStr.getLanguageStr(30001),20,1118481,"left",160,35);
         _tLv.x = _tName.x + _tName.textBounds.width + 10;
         _tLv.y = _tName.y;
         mBg_img.addChild(_tLv);
         _tInfo_2 = GlobalTextStyle.getTextField(getFragmentSkillInfo(),15,4926491,"left",380,35 * 2);
         _tInfo_2.x = skillImg.x;
         _tInfo_2.y = _tName.y + _tName.height + 10;
         mBg_img.addChild(_tInfo_2);
         var _loc5_:TextField = GlobalTextStyle.getTextField(_skillset == null ? "" : _skillset.getInfoDesc(),15,1513239,"right",200,35 * 2);
         _loc5_.x = mBg_img.width - _loc5_.width - 40;
         _loc5_.y = mBg_img.height / 2 + 35;
         mBg_img.addChild(_loc5_);
         var _loc10_:String = "";
         var _loc9_:String = _equip.equipData.id;
         var _loc14_:Boolean = GlobalFunction.checkEquipIsBook(_loc9_);
         _tName_shipin = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(90410),24,16777215,"left",160,35);
         _tName_shipin.y = 90;
         _tName_shipin.x = _tName_shipin.width / 4;
         mImg9_baseBg.addChild(_tName_shipin);
         mBox_child_close = GlobalFunction.createButton_5("","UI_regist_btn_3_0000");
         mBox_child_close.x = _loc15_.x + _loc15_.width - mBox_child_close.width - 20;
         mBox_child_close.y = 20;
         mBox_child_close.addEventListener("triggered",onTRIGGERED_closeChild);
         mBox_child_item = new Sprite();
         mImg9_baseBg.addChild(mBox_child_item);
         var _loc3_:Array = _data["data_base"] as Array;
         if(_loc3_ == null) _loc3_ = [];
         var _loc7_:int = 0;
         var _loc6_:int = int(_loc3_.length);
         var _loc16_:Object = null;
         _loc7_ = 0;
         while(_loc7_ < _loc6_)
         {
            _loc16_ = {};
            _loc16_["id"] = _data["id"];
            _loc16_["indexID_s"] = _loc7_;
            _loc16_["data_base"] = _loc3_[_loc7_];
            _loc13_ = new ItemFragmentChild(_loc16_);
            _loc13_.x = _loc7_ % 3 * 150;
            _loc13_.y = Math.floor(_loc7_ / 3) * 95;
            mBox_child_item.addChild(_loc13_);
            _loc7_++;
         }
         var _loc11_:int = Math.floor(_loc7_ / 3);
         var _loc8_:Number = _loc11_ > 0 ? 450 : _loc7_ * 150;
         var _loc1_:Number = Math.ceil(_loc7_ / 3) * 95;
         mBox_child_item.x = int((mImg9_baseBg.width - _loc8_) * 0.5) + 45;
         mBox_child_item.y = 350;
      }
      
      private function getFragmentSkillInfo() : String
      {
         return _skillset == null ? "该装备不附带技能。" : _skillset.getInfo();
      }

      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         delFragment_child();
         if(_equip) _equip.clear();
         _equip = null;
         _skillset = null;
         super.onREMOVED_FROM_STAGE(param1);
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
         mBox_child = null;
         mBox_child_close = null;
         mBox_child_item = null;
      }
   }
}

