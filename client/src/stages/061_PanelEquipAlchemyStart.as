package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.equip.Equip;
   import com.meng52.game.ui.element.ItemEquip;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelCenterMainAvatar;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   
   public class PanelEquipAlchemyStart extends PanelCenterMainAvatar
   {
      
      private var m_equip_add_img:PanelIconBaseSprite;
      
      private var m_box_1:infoBox;
      
      private var m_box_2:infoBox;
      
      private var m_bg:Scale9Image;
      
      private var m_empty_info:TextField;
      
      private var m_start_btn:LOL_Scale9Button;
      
      private var m_arrow:Image;
      
      private var m_select_stuff:Object;
      
      private var m_select_equip:Equip;
      
      private var m_select_equip_spr:ItemEquip;
      
      private var m_return_spr:Sprite;
      
      private var m_return_gift_info:TextField;
      
      private var m_return_gold:TextField;
      
      private var m_return_gift_mark:TextField;
      
      private var m_txt_arr:Array = [];
      
      private const TXT_CONST_WIDTH:int = 185;
      
      private const TXT_CONST_HEIGHT:int = 30;
      
      private const TXT_CONST_COLOR:uint = 4926491;
      
      private const CONST_ALCHEMY:String = "const_alchemy";
      
      private const TOP:int = 85;
      
      private var m_data:Object;
      
      public function PanelEquipAlchemyStart(param1:Object)
      {
         m_data = param1;
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getStr(90691),820);
         GlobalData.$mEventDispatcher.addEventListener("select_alchemy_stuff",onSaveSelectStuff);
         initUI();
      }
      
      private function onSaveSelectStuff(param1:Event) : void
      {
         clear_select_stuff_data();
         m_select_stuff = param1.data;
         m_select_equip = new Equip(m_select_stuff.id,m_select_stuff);
         m_select_equip_spr = new ItemEquip();
         if(m_select_stuff is String)
         {
            m_select_equip_spr.setEquip(m_select_equip.equipData.id,m_select_equip.baseData.dataObj);
         }
         else
         {
            m_select_equip_spr.setEquip(m_select_stuff.id,m_select_stuff,8,7);
         }
         m_select_equip_spr.x = m_bg.x + 30;
         m_select_equip_spr.y = m_equip_add_img.y - m_equip_add_img.height * 0.5;
         m_select_equip_spr.addEventListener("touch",onTouch);
         addChild(m_select_equip_spr);
         m_start_btn.text = GlobalLanguageStr.getStr(98201);
         update_expend_info();
      }
      
      private function update_expend_info() : void
      {
         var _loc10_:int = 0;
         _loc10_ = 10;
         var _loc8_:TextField = null;
         clear_txt_arr();
         m_equip_add_img.visible = false;
         m_empty_info.visible = false;
         m_return_spr.visible = true;
         var _loc2_:int = m_select_equip.getSellGold();
         var _loc1_:int = m_select_equip.getSellMark();
         var _loc4_:Array = m_select_equip.getSellDust();
         var _loc5_:String = m_box_2.equip_alchemy_lv;
         var _loc3_:int = m_select_equip.getAlchemyGold(_loc5_);
         m_return_gold.text = GlobalLanguageStr.getLanguageStr(90699,GlobalLanguageStr.getStr(20162),_loc2_);
         m_return_gift_mark.text = GlobalLanguageStr.getLanguageStr(90699,GlobalLanguageStr.getStr(20272),_loc1_);
         var _loc9_:Array = GlobalLanguageStr.getStr(90197).split("$");
         var _loc11_:int = 0;
         var _loc7_:Array = [0,10 + 185,10 + 185,10 + 185];
         var _loc6_:Array = [30 * 3 + 10,30 + 10,30 * 2 + 10,30 * 3 + 10];
         _loc11_;
         while(_loc11_ < _loc4_.length)
         {
            if(_loc4_[_loc11_] != 0)
            {
               _loc8_ = GlobalFunction.createTextField(185,30,"","",20,4926491);
               _loc8_.hAlign = "left";
               m_return_spr.addChild(_loc8_);
               _loc8_.text = GlobalLanguageStr.getLanguageStr(90699,_loc9_[_loc11_],_loc4_[_loc11_]);
               m_txt_arr.push(_loc8_);
            }
            _loc11_++;
         }
         _loc11_ = 0;
         while(_loc11_ < m_txt_arr.length)
         {
            m_txt_arr[_loc11_].x = _loc7_[_loc11_];
            m_txt_arr[_loc11_].y = MainConfig.$isEnglish ? _loc6_[_loc11_] + 30 : _loc6_[_loc11_];
            _loc11_++;
         }
      }
      
      private function clear_txt_arr() : void
      {
         var _loc1_:TextField = null;
         if(m_txt_arr)
         {
            while(m_txt_arr.length > 0)
            {
               _loc1_ = m_txt_arr.pop();
               _loc1_.dispose();
               _loc1_.removeFromParent(true);
               _loc1_ = null;
            }
         }
         m_txt_arr = [];
      }
      
      private function clear_select_stuff_data() : void
      {
         if(m_select_stuff)
         {
            m_select_stuff = null;
         }
         if(m_select_equip)
         {
            m_select_equip.clear();
         }
         m_select_equip = null;
         if(m_select_equip_spr)
         {
            m_select_equip_spr.removeEventListener("touch",onTouch);
            m_select_equip_spr.clear();
         }
         m_select_equip_spr = null;
      }
      
      private function createOtherUI() : void
      {
         if(m_box_1)
         {
            StarlingTools.removeChildrenClear(m_box_1);
         }
         m_box_1 = null;
         if(m_box_2)
         {
            StarlingTools.removeChildrenClear(m_box_2);
         }
         m_box_2 = null;
         if(m_arrow)
         {
            m_arrow.dispose();
            m_arrow.removeFromParent(true);
         }
         m_arrow = null;
         m_box_1 = new infoBox(m_data);
         m_box_1.x = 30;
         m_box_1.y = 85;
         this.addChild(m_box_1);
         m_arrow = GlobalFunction.createImage("UI_equip_tag_0_0000");
         m_arrow.pivotY = m_arrow.height * 0.5;
         m_arrow.x = m_box_1.x + m_box_1.width + 2;
         m_arrow.y = m_box_1.y + m_box_1.height * 0.5;
         this.addChild(m_arrow);
         m_box_2 = new infoBox(m_data,true);
         m_box_2.x = m_box_1.x + m_box_1.width + 40;
         m_box_2.y = 85;
         this.addChild(m_box_2);
      }
      
      private function initUI() : void
      {
         createOtherUI();
         m_bg = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",560,196,new Rectangle(30,25,10,10));
         m_bg.x = this.mImg9_baseBg.x + (this.mImg9_baseBg.width - m_bg.width) * 0.5;
         m_bg.y = 85 + 420;
         this.addChild(m_bg);
         m_equip_add_img = new PanelIconBaseSprite("UI_equip_bg_3_0007","UI_icon_0_0000");
         m_equip_add_img.pivotY = m_equip_add_img.height * 0.5;
         m_equip_add_img.x = m_bg.x + 30;
         m_equip_add_img.y = m_bg.y + m_bg.height * 0.5;
         m_equip_add_img.addEventListener("touch",onTouch);
         this.addChild(m_equip_add_img);
         m_empty_info = GlobalFunction.createTextField(MainConfig.$isEA ? 410 : 390,MainConfig.$isEA ? 70 : 60,GlobalLanguageStr.getStr(98202),"",20,4926491);
         m_empty_info.x = MainConfig.$isEA ? m_equip_add_img.x + m_equip_add_img.width + 5 : (MainConfig.$isEnglish ? m_equip_add_img.x + m_equip_add_img.width + 25 : m_equip_add_img.x + m_equip_add_img.width + 40);
         m_empty_info.y = m_equip_add_img.y - m_empty_info.height * 0.5;
         m_empty_info.hAlign = "left";
         this.addChild(m_empty_info);
         m_return_spr = new Sprite();
         this.addChild(m_return_spr);
         var _loc1_:int = int(MainConfig.$isEnglish ? 30 + 30 : 30);
         m_return_gift_info = GlobalFunction.createTextField(185 * 2,_loc1_,GlobalLanguageStr.getStr(90698),"",20,10027008);
         m_return_gift_info.hAlign = "left";
         m_return_spr.addChild(m_return_gift_info);
         m_return_gold = GlobalFunction.createTextField(185,30,"","",20,4926491);
         m_return_gold.y = m_return_gift_info.y + m_return_gift_info.height + 10;
         m_return_gold.hAlign = "left";
         m_return_spr.addChild(m_return_gold);
         m_return_gift_mark = GlobalFunction.createTextField(185,30,"","",20,4926491);
         m_return_gift_mark.y = m_return_gold.y + m_return_gold.height;
         m_return_gift_mark.hAlign = "left";
         m_return_spr.addChild(m_return_gift_mark);
         m_start_btn = new LOL_Scale9Button(GlobalLanguageStr.getStr(98200),150,70);
         m_start_btn.name = "const_alchemy";
         m_start_btn.x = m_bg.x + m_bg.width - m_start_btn.width - 20;
         m_start_btn.y = m_equip_add_img.y + m_equip_add_img.height + 10;
         m_start_btn.addEventListener("triggered",onTRIGGERED);
         this.addChild(m_start_btn);
         m_return_spr.pivotY = m_return_spr.height * 0.5;
         m_return_spr.x = m_equip_add_img.x + m_equip_add_img.width + 40;
         m_return_spr.y = m_bg.y + m_bg.height * 0.5 - 25;
         m_return_spr.visible = false;
      }
      
      private function onTRIGGERED(param1:Event) : void
      {
         var _loc5_:Boolean = false;
         var _loc4_:int = 0;
         var _loc6_:int = 0;
         var _loc3_:String = null;
         var _loc2_:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         var _loc7_:String = _loc2_.name;
         if("const_alchemy" === _loc7_)
         {
            if(m_select_stuff)
            {
               _loc5_ = false;
               if(m_select_equip.magic)
               {
                  _loc4_ = int((m_select_equip.magic as Array).length);
                  _loc6_ = 0;
                  while(_loc6_ < _loc4_)
                  {
                     if(m_select_equip.magic[_loc6_] > 0)
                     {
                        _loc5_ = true;
                        break;
                     }
                     _loc6_++;
                  }
               }
               if(m_select_equip.symp > -1 || _loc5_ || m_select_equip.haloLv > 0)
               {
                  _loc3_ = Tools.formatLineX(GlobalLanguageStr.getStr(97628),GlobalTextStyle.COLOR_F_FFCC66);
                  GlobalFunction.popAlert("",_loc3_,{
                     "ok":send_msg,
                     "no":GlobalFunction.functionNull
                  });
               }
               else
               {
                  send_msg();
               }
            }
            else
            {
               LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getStr(90696));
            }
         }
      }
      
      private function send_msg() : void
      {
         var _loc1_:Object = {"eqids":[m_data.id,m_select_stuff.id]};
         SendServiceAMFFun.send_user_equip_alchemy(refun,_loc1_);
      }
      
      private function refun(param1:Object) : void
      {
         if(GlobalFunction.isMalformedProfileReceipt(param1))
         {
            return;
         }
         if(GlobalFunction.isLegacyProfileReceipt(param1))
         {
            RpcStaticCall.$remoting.reportDiagnostic("PROFILE_RECEIPT_LEGACY|method=user.equip_alchemy");
         }
         var _loc6_:String = null;
         var _loc8_:String = null;
         var _loc5_:String = null;
         var _loc4_:Object = null;
         var _loc9_:String = "gold";
         SoundManager.getOnlyExample().playSound(_loc9_);
         var _loc7_:Rectangle = m_box_1.getBounds(stage);
         var _loc2_:int = _loc7_.x + 60;
         var _loc3_:int = _loc7_.y + 60;
         if(param1.data)
         {
            _loc6_ = param1["params"] != null && param1["params"]["eqids"] is Array && param1["params"]["eqids"].length > 0 ? String(param1["params"]["eqids"][0]) : "";
            if(_loc6_ == "" || String(m_data["id"]) != _loc6_)
            {
               return;
            }
            if(GlobalData.$userData.my_equips[_loc6_] == null)
            {
               return;
            }
            m_data = {};
            m_data = Tools.clone(GlobalData.$userData.my_equips[_loc6_]);
            m_data["id"] = _loc6_;
            GlobalData.$mEventDispatcher.dispatchEventWith("update_alchemy_select");
            if(checkContinueAlchemy(m_data))
            {
               LayoutUIAnimation.getOnlyExample().popEffect({
                  "id":"e008",
                  "x":_loc2_,
                  "y":_loc3_,
                  "sc":1.2
               });
               createOtherUI();
               clear_select_stuff_data();
               m_equip_add_img.visible = true;
               m_empty_info.visible = true;
               m_return_spr.visible = false;
               LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getStr(90701));
            }
            else
            {
               _loc8_ = "equip";
               _loc5_ = GlobalLanguageStr.getStr(90700);
               _loc4_ = {};
               _loc4_[m_data["eid"]] = 1;
               GlobalFunction.popAward(_loc8_,_loc5_,_loc4_,true,null,false,null,m_data);
               GlobalData.$mGameClassObject.closePopForPanel(1);
            }
         }
      }
      
      private function checkContinueAlchemy(param1:Object) : Boolean
      {
         var _loc5_:Boolean = false;
         var _loc2_:Array = param1["eid"].split("_");
         var _loc3_:int = int(_loc2_[_loc2_.length - 1]) + int(param1["alchemy"][1]);
         var _loc4_:Object = GlobalData.$mConfig_simple.equip_alchemy;
         if(_loc3_ < int(_loc4_.star_lv))
         {
            _loc5_ = true;
         }
         return _loc5_;
      }
      
      private function onTouch(param1:TouchEvent) : void
      {
         var _loc2_:Touch = param1.getTouch(this);
         if(_loc2_.phase == "ended")
         {
            clear_select_stuff_data();
            m_equip_add_img.visible = true;
            m_empty_info.visible = true;
            m_start_btn.text = GlobalLanguageStr.getStr(98200);
            m_return_spr.visible = false;
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_equipalchemy_stuff_select",false,true,m_data);
         }
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         m_data = {};
         clear_select_stuff_data();
         super.onREMOVED_FROM_STAGE(param1);
         GlobalData.$mEventDispatcher.removeEventListener("select_alchemy_stuff",onSaveSelectStuff);
         m_equip_add_img.removeEventListener("touch",onTouch);
         if(m_equip_add_img)
         {
            StarlingTools.removeChildrenClear(m_equip_add_img);
         }
         m_equip_add_img = null;
         if(m_box_1)
         {
            StarlingTools.removeChildrenClear(m_box_1);
         }
         m_box_1 = null;
         if(m_box_2)
         {
            StarlingTools.removeChildrenClear(m_box_2);
         }
         m_box_2 = null;
         if(m_bg)
         {
            m_bg.dispose();
            m_bg.removeFromParent(true);
         }
         m_bg = null;
         if(m_empty_info)
         {
            m_empty_info.dispose();
            m_empty_info.removeFromParent(true);
         }
         m_empty_info = null;
         if(m_start_btn)
         {
            m_start_btn.dispose();
            m_start_btn.removeFromParent(true);
         }
         m_start_btn = null;
         if(m_arrow)
         {
            m_arrow.dispose();
            m_arrow.removeFromParent(true);
         }
         m_arrow = null;
         if(m_return_spr)
         {
            StarlingTools.removeChildrenClear(m_return_spr);
            m_return_spr.removeFromParent(true);
         }
         m_return_spr = null;
         if(m_return_gift_info)
         {
            m_return_gift_info.dispose();
            m_return_gift_info.removeFromParent(true);
         }
         m_return_gift_info = null;
         if(m_return_gold)
         {
            m_return_gold.dispose();
            m_return_gold.removeFromParent(true);
         }
         m_return_gold = null;
         if(m_return_gift_mark)
         {
            m_return_gift_mark.dispose();
            m_return_gift_mark.removeFromParent(true);
         }
         m_return_gift_mark = null;
      }
   }
}

import com.meng52.display.TextFieldHtmlRenderer;
import com.meng52.game.global.GlobalConfig;
import com.meng52.game.global.GlobalData;
import com.meng52.game.global.GlobalFunction;
import com.meng52.game.global.GlobalLanguageStr;
import com.meng52.game.global.GlobalTextStyle;
import com.meng52.game.module.equip.Equip;
import com.meng52.game.ui.element.ItemEquip;
import com.meng52.game.ui.element.ItemEquipSelect;
import com.meng52.game.ui.element.LOL_StarLevel;
import com.meng52.utils.StarlingTools;
import com.meng52.utils.Tools;
import feathers.display.Scale9Image;
import flash.geom.Rectangle;
import starling.display.Image;
import starling.display.Sprite;
import starling.text.TextField;

class infoBox extends Sprite
{
   
   private var m_bg:Scale9Image;
   
   private var _equip:Equip;
   
   private var _equipSp:ItemEquip;
   
   private var m_data:Object;
   
   private var m_next:Boolean;
   
   private var m_equipName_txt:TextFieldHtmlRenderer;
   
   private var m_equipLV_txt:TextField;
   
   private var m_spr:Sprite;
   
   private var _starLevel:LOL_StarLevel;
   
   private var m_equip_alchemy_lv:String;
   
   private var mBox_magic:Sprite;
   
   public var mAttBaseNum:int = 0;
   
   public var mAttNewNum:int = 0;
   
   private const _addstr:String = "+";
   
   public function infoBox(param1:Object, param2:Boolean = false)
   {
      super();
      this.m_next = param2;
      this.m_data = param2 ? nextEquip(param1) : param1;
      init();
   }
   
   private function nextEquip(param1:Object) : Object
   {
      var _loc2_:Object = Tools.clone(param1);
      if(_loc2_.hasOwnProperty("alchemy"))
      {
         if(_loc2_.alchemy[0] < 2)
         {
            _loc2_["alchemy"] = [int(_loc2_.alchemy[0]) + 1,_loc2_.alchemy[1]];
         }
         else
         {
            _loc2_["alchemy"] = [0,int(_loc2_.alchemy[1]) + 1];
         }
      }
      else
      {
         _loc2_["alchemy"] = [1,0];
      }
      return _loc2_;
   }
   
   public function get equip_alchemy_lv() : String
   {
      return m_equip_alchemy_lv;
   }
   
   private function init() : void
   {
      var _loc3_:Array = null;
      var _loc6_:Array = null;
      var _loc9_:Number = NaN;
      var _loc1_:Number = NaN;
      var _loc5_:String = null;
      var _loc2_:Array = null;
      if(m_data.hasOwnProperty("alchemy"))
      {
         _loc3_ = m_data["alchemy"];
         _loc6_ = m_data["eid"].split("_");
         m_equip_alchemy_lv = (int(_loc6_[_loc6_.length - 1]) + int(_loc3_[1])).toString() + "_" + _loc3_[0];
      }
      m_bg = GlobalFunction.createScale9Image("UI_bg_9slice_7_0000",270,405,new Rectangle(30,25,10,10));
      addChild(m_bg);
      var _loc4_:Array = (m_data.eid as String).split("_");
      var _loc8_:Object = GlobalData.$mConfig_simple.equip_alchemy;
      if(m_data.hasOwnProperty("alchemy"))
      {
         _loc5_ = (int(_loc4_[_loc4_.length - 1]) + m_data.alchemy[1]).toString() + "_" + int(m_data.alchemy[0]).toString();
         _loc2_ = _loc8_.phase[_loc5_];
         if(this.m_next)
         {
            _loc9_ = Number(_loc2_[1]);
            _loc1_ = Number(_loc2_[0]);
         }
         else
         {
            _loc9_ = 1;
            _loc1_ = 1;
         }
      }
      else
      {
         _loc9_ = 1;
         _loc1_ = 1;
      }
      var _loc7_:int = Math.max(Math.floor(int(m_data.lv) * _loc9_),1);
      m_data.lv = _loc7_;
      _equip = new Equip(m_data.id,m_data);
      _equipSp = new ItemEquip();
      if(m_data is String)
      {
         _equipSp.setEquip(_equip.equipData.id,_equip.baseData.dataObj);
      }
      else
      {
         _equipSp.setEquip(m_data.id,m_data,8,7);
      }
      _equipSp.x = 5;
      _equipSp.y = 10;
      addChild(_equipSp);
      m_spr = createSpr();
      this.addChild(m_spr);
   }
   
   private function createSpr() : Sprite
   {
      var name:String;
      var lv:String;
      var _lv_rate:Number;
      var _star:int;
      var _Properties_rate:Number;
      var _name_add:String;
      var cfg_phase_id:String;
      var cfg_now:Array;
      var _mColorArr:Array;
      var alchemy_star_cfg:int;
      var _info:String;
      var falseNum:int;
      var i:int;
      var l:int;
      var _img:Image;
      var _num:int;
      var _txt:TextField;
      var _a:Boolean;
      var _b:Boolean;
      var _index:int;
      var _aV:Number;
      var _bV:Number;
      var _imgWidth:Number;
      var _fontS:Number;
      var _fontW:Number;
      var _alchemy_cfg:Object = GlobalData.$mConfig_simple.equip_alchemy;
      var _spr:Sprite = new Sprite();
      var eid_arr:Array = (m_data.eid as String).split("_");
      if(m_data.hasOwnProperty("alchemy"))
      {
         cfg_phase_id = (int(eid_arr[eid_arr.length - 1]) + m_data.alchemy[1]).toString() + "_" + int(m_data.alchemy[0]).toString();
         cfg_now = _alchemy_cfg.phase[cfg_phase_id];
         _name_add = "+" + m_data.alchemy[0];
         _star = int(eid_arr[eid_arr.length - 1]) + m_data.alchemy[1];
      }
      else
      {
         _name_add = "";
         _star = int(eid_arr[eid_arr.length - 1]);
      }
      _mColorArr = [];
      alchemy_star_cfg = int(GlobalData.$mConfig_simple.equip_alchemy.equip_al);
      switch(_star - alchemy_star_cfg)
      {
         case 0:
            _mColorArr = [16777215,12075775,16764006,16764006];
            break;
         case 1:
            _mColorArr = [16777215,16764006,16764006,16764006];
            break;
         default:
            _mColorArr = [16777215,16777215,16777215,16777215];
      }
      name = _equip.equipData.name + (_star == int(_alchemy_cfg.star_lv) ? "" : "(" + _name_add + ")");
      _info = Tools.formatLineX(name,_mColorArr,9,MainConfig.$isEnglish ? 14 : 16,false,"center");
      lv = GlobalLanguageStr.getLanguageStr(20017,_equip.lv);
      m_equipName_txt = GlobalTextStyle.getHtmlTextRenderer();
      m_equipName_txt.text = Tools.formatHtmlTextBr([_info],"left");
      m_equipName_txt.mLayoutFun = function():void
      {
         var _loc1_:Rectangle = m_equipName_txt.getTextSnapshotFrame();
         m_equipName_txt.x = MainConfig.$isEnglish ? 110 : 115;
         m_equipName_txt.y = 18;
      };
      _spr.addChild(m_equipName_txt);
      m_equipLV_txt = GlobalFunction.createTextField(160,30,lv,"",20,16777215);
      m_equipLV_txt.x = MainConfig.$isEnglish ? 110 : 115;
      m_equipLV_txt.y = 64;
      m_equipLV_txt.hAlign = "left";
      _spr.addChild(m_equipLV_txt);
      _starLevel = new LOL_StarLevel(_equip.getStar(),_equip.getStar(),0.35);
      _starLevel.y = m_equipLV_txt.y + m_equipLV_txt.height + 12;
      _spr.addChild(_starLevel);
      createAttTxt(98140,_equip.getHpMax(-1,false),_spr);
      createAttTxt(98141,_equip.getDamage(-1,false),_spr);
      createAttTxt(98142,_equip.getDePh(-1),_spr);
      createAttTxt(98143,_equip.getDeMa(-1),_spr);
      createAttTxt(98144,_equip.getRange(),_spr);
      createAttTxt(98145,_equip.getSpeed(),_spr);
      if(_equip.hasHit())
      {
         createAttTxt(30021,_equip.getHit(),_spr);
      }
      if(_equip.hasFlee())
      {
         createAttTxt(30022,_equip.getFlee(),_spr);
      }
      if(_equip.hasCrit())
      {
         createAttTxt(30023,_equip.getCrit(),_spr);
      }
      if(_equip.hasTough())
      {
         createAttTxt(30024,_equip.getTough(),_spr);
      }
      createAttTxt(20273,_equip.getPoteNow(_equip.lv),_spr);
      falseNum = 0;
      if(!_equip.hasHit())
      {
         falseNum += _equip.getHit(_equip.lv);
      }
      if(!_equip.hasCrit())
      {
         falseNum += _equip.getCrit(_equip.lv);
      }
      if(!_equip.hasFlee())
      {
         falseNum += _equip.getFlee(_equip.lv);
      }
      if(!_equip.hasTough())
      {
         falseNum += _equip.getTough(_equip.lv);
      }
      createAttTxt(20321,falseNum,_spr);
      i = 0;
      l = int(_equip.magic.length);
      _num = 0;
      _a = false;
      _b = false;
      _index = 0;
      _aV = 0;
      _bV = 0;
      _imgWidth = 17;
      _fontS = 20;
      _fontW = 109;
      i = 0;
      while(i < l)
      {
         _num = int(_equip.magic[i]);
         if(_num > 0)
         {
            _index = i % 2;
            if(_index == 0)
            {
               _aV += _num;
               _a = true;
            }
            if(_index != 0)
            {
               _bV += _num;
               _b = true;
            }
         }
         i = i + 1;
      }
      if(_a)
      {
         createAttTxt(98149,_aV,_spr,true);
      }
      if(_b)
      {
         createAttTxt(98150,_bV,_spr,true);
      }
      return _spr;
   }
   
   private function createAttTxt(param1:int, param2:int, param3:Sprite, param4:Boolean = false) : void
   {
      var _loc8_:* = 0;
      var _loc5_:String = null;
      var _loc9_:TextField = null;
      var _loc7_:int = 180;
      var _loc6_:int = int(_equip.haloLv);
      if(param2 > 0)
      {
         _loc8_ = 4926491;
         if(_loc6_ > 0)
         {
            _loc8_ = uint(Equip.haloColor[_loc6_ - 1]);
         }
         if(!param4)
         {
            _loc5_ = param2.toString();
         }
         if(param4)
         {
            if(_equip.symp >= 0)
            {
               if(mBox_magic)
               {
                  StarlingTools.removeChildrenClear(mBox_magic);
                  mBox_magic.removeFromParent(true);
                  mBox_magic = null;
               }
               mBox_magic = ItemEquipSelect.getMagicUIs(_equip.symp,_equip.magic,false,0.8,16777215);
               mBox_magic.x = MainConfig.$isEA ? -6 : (MainConfig.$isEnglish ? 30 : -30);
               mBox_magic.y = mAttBaseNum * 29 + 160;
               addChild(mBox_magic);
            }
         }
         else
         {
            _loc9_ = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(param1) + " " + _loc5_,20,16777215,"left",_loc7_,35,GlobalConfig.FONT_1);
            _loc9_.touchable = false;
            _loc9_.x = 20;
            _loc9_.y = mAttBaseNum * 29 + 160;
            mAttBaseNum += 1;
            param3.addChild(_loc9_);
         }
      }
   }
}
