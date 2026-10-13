package com.meng52.game.ui.element
{
   import com.meng52.game.global.GlobalConfig;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.equip.Equip;
   import com.meng52.game.ui.effect.DisplayTools;
   import com.meng52.game.ui.panel.PanelEquipInfoSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.renderers.IListItemRenderer;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import starling.display.DisplayObject;
   import starling.display.Image;
   import starling.display.MovieClip;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.TouchEvent;
   import starling.text.TextField;
   
   public class ItemEquipSelect extends ItemBase implements IListItemRenderer
   {
      
      public static const BG_WIDTH:int = 580;
      
      public static const BG_HEIGHT:int = 105;
      
      public var mImg_null:Image;
      
      public var mBtn_fun:LOL_Scale9Button;
      
      public var mEquip:Equip;
      
      public var mEquipUI:Sprite;
      
      public var mAttBaseNum:int = 0;
      
      public var mAttNewNum:int = 0;
      
      public var mEquip_clip:MovieClip;
      
      public var mBox_magic:Sprite;
      
      public var _bg:Scale9Image;
      
      public var select_Bg:Image;
      
      public var selected:Boolean = false;

      private var mDressRequestId:uint = 0;
      
      public function ItemEquipSelect()
      {
         super();
      }
      
      public static function getMagicUIs(param1:int, param2:Array, param3:Boolean = true, param4:Number = 1, param5:uint = 4926491) : Sprite
      {
         var _loc20_:Image = null;
         var _loc15_:TextField = null;
         var _loc7_:Sprite = new Sprite();
         var _loc18_:String = "UI_magic_icon_lv_000";
         var _loc17_:int = 0;
         var _loc13_:int = param2 == null ? 0 : int(param2.length);
         var _loc21_:Object = GlobalData.$mConfig_simple.equipment_magic;
         var _loc22_:Array = _loc21_ == null ? null : _loc21_.stat_per_level as Array;
         var _loc19_:int = 0;
         var _loc14_:Boolean = false;
         var _loc12_:Boolean = false;
         var _loc9_:int = 0;
         var _loc8_:Number = 0;
         var _loc11_:Number = 0;
         var _loc16_:Number = 17;
         var _loc10_:Number = param3 ? 14 : 20;
         var _loc6_:Number = param3 ? 67 : 109;
         _loc17_ = 0;
         while(_loc17_ < _loc13_)
         {
            _loc19_ = int(param2[_loc17_]);
            if(_loc22_ != null && _loc17_ < _loc22_.length)
            {
               _loc19_ *= Math.max(0,int(_loc22_[_loc17_]));
            }
            if(_loc19_ > 0)
            {
               _loc20_ = GlobalFunction.createImage(_loc18_ + _loc17_);
               _loc16_ = _loc20_.width;
               _loc20_.scaleX = _loc20_.scaleY = param4;
               _loc9_ = _loc17_ % 2;
               _loc20_.x = MainConfig.$isEA ? _loc20_.width + _loc6_ - 105 : (MainConfig.$isEnglish ? _loc20_.width + _loc6_ - 146 : _loc20_.width + _loc6_ - 88);
               if(param3)
               {
                  _loc20_.scaleX = _loc20_.scaleY = 0.57;
                  _loc16_ = _loc20_.width;
                  _loc20_.y = _loc9_ * 17;
               }
               else
               {
                  _loc20_.y = _loc9_ * 23;
               }
               if(_loc9_ == 0)
               {
                  _loc8_ += _loc19_;
                  _loc14_ = true;
               }
               if(_loc9_ != 0)
               {
                  _loc11_ += _loc19_;
                  _loc12_ = true;
               }
               _loc7_.addChild(_loc20_);
            }
            _loc17_++;
         }
         if(_loc14_)
         {
            _loc15_ = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(98140) + " +" + _loc8_,_loc10_,param5,"left",_loc6_ + 20,35);
            _loc15_.x = _loc20_.x + _loc20_.width;
            if(param3)
            {
               _loc15_.y = -4;
            }
            else
            {
               _loc15_.y = -4;
            }
            _loc7_.addChild(_loc15_);
         }
         if(_loc12_)
         {
            _loc15_ = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(98141) + " +" + _loc11_,_loc10_,param5,"left",_loc6_ + 20,35);
            _loc15_.x = _loc20_.x + _loc20_.width;
            if(param3)
            {
               _loc15_.y = 13;
            }
            else
            {
               _loc15_.y = 19;
            }
            _loc7_.addChild(_loc15_);
         }
         return _loc7_;
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(mBox_magic)
         {
            StarlingTools.removeChildrenClear(mBox_magic);
            mBox_magic.removeFromParent(true);
         }
         if(mEquip_clip)
         {
            GlobalData.$mStarling.juggler.remove(mEquip_clip);
            mEquip_clip.removeFromParent(true);
         }
         if(mBtn_fun)
         {
            mBtn_fun.removeFromParent(true);
         }
         if(mEquip)
         {
            mEquip.clear();
         }
         if(mEquipUI)
         {
            mEquipUI.removeFromParent(true);
         }
         if(mImg_null)
         {
            mImg_null.removeFromParent(true);
         }
         clear();
         mBtn_fun = null;
         mEquip = null;
         mImg_null = null;
         mEquipUI = null;
         mEquip_clip = null;
         mBox_magic = null;
      }
      
      override public function layoutWH() : void
      {
         this.width = 580;
         this.height = 105;
         tweenX();
      }
      
      override public function init(param1:Object) : void
      {
         _bg = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",GlobalData.$mStageWidth - 165,95,new Rectangle(110,55,70,20));
         _bg.x = 108;
         _bg.y = 5;
         addChild(_bg);
         if(this.data["isHad"] != null)
         {
            if(this.data["isHad"] == 2)
            {
               setEquip(param1["id"],param1);
               setFunBtnUI(GlobalLanguageStr.getLanguageStr(98147),true,"UI_btn_enterGame_0_0000");
               setOtherUIs(GlobalFunction.checkEquipIsBook(param1["eid"]));
               setUsedStatusUI();
            }
            else if(this.data["isHad"] == 0)
            {
               setEquip(param1["id"],param1);
               setFunBtnUI(GlobalLanguageStr.getLanguageStr(98148),true,"UI_btn_smallFun_1_0000");
               setOtherUIs(GlobalFunction.checkEquipIsBook(param1["eid"]));
               setUsedStatusUI();
            }
         }
      }
      
      public function setFunBtnUI(param1:String, param2:Boolean = true, param3:String = "UI_btn_enterGame_0_0000") : void
      {
         this.mBtn_fun = new LOL_Scale9Button(param1,84,45,param3,true,false);
         this.mBtn_fun.addEventListener("triggered",this.onTRIGGERED_btns);
         this.mBtn_fun.enabled = param2;
         this.mBtn_fun.y = int((105 - this.mBtn_fun.height + 26) * 0.5);
         if(_data["tag"] == 0)
         {
            this.mBtn_fun.x = 580 - this.mBtn_fun.width - 10 + 17;
         }
         else
         {
            this.mBtn_fun.x = 580 - this.mBtn_fun.width - 10 - 2;
         }
         this.addChild(this.mBtn_fun);
      }
      
      public function setFunSelect() : void
      {
         this.select_Bg = GlobalFunction.createImage("UI_tag_sell_to_book_0000");
         this.select_Bg.x = 580 - this.select_Bg.width - 30;
         this.select_Bg.y = 0 + int((105 - this.select_Bg.height) * 0.5) - 2;
         select_Bg.touchable = false;
         this.addChild(this.select_Bg);
         this.mUI_select = GlobalFunction.createImage("UI_tag_sell_to_book_0001");
         this.mUI_select.touchable = false;
         addChild(this.mUI_select);
         if(mEquipUI)
         {
            this.mUI_select.x = 580 - this.mUI_select.width - 30;
            this.mUI_select.y = 0 + int((105 - this.mUI_select.height) * 0.5) - 2;
         }
         this.mSelect.visible = _data.selected;
         _bg.addEventListener("touch",bg_Touch);
      }
      
      public function setEquip(param1:String, param2:Object = null, param3:Number = 8, param4:Number = 7, param5:int = -1) : void
      {
         var _loc6_:int = 0;
         var _loc8_:Object = null;
         var _loc11_:LOL_TextField = null;
         var _loc14_:Boolean = false;
         var _loc9_:String = null;
         mEquip = new Equip(param1,param2);
         mEquipUI = mEquip.getRes(null,1);
         mEquipUI.x = param3;
         mEquipUI.y = param4;
         var _loc12_:Number = mEquip.haloLv;
         var _loc10_:Object = GlobalData.$userData;
         var _loc7_:* = mEquip.getMyEquipData(param1);
         if(_loc7_)
         {
            _loc8_ = GlobalData.$userData.my_equips[_loc7_.id];
         }
         else
         {
            _loc8_ = GlobalData.$userData.my_equips[GlobalData.$tempEquipCurrSelected];
         }
         var _loc13_:Boolean = GlobalFunction.checkEquipIsBook(mEquip.equipData.id);
         if(_loc13_)
         {
            if(_loc8_)
            {
               _loc6_ = int(_loc8_.slv);
            }
            else
            {
               _loc6_ = mEquip.slv;
            }
         }
         else
         {
            _loc6_ = mEquip.slv;
         }
         if(_loc12_ > 0)
         {
            mEquip_clip = DisplayTools.newMc("UI_equip_light_0_");
            mEquip_clip.alpha = 0.5 + _loc12_ * 0.1;
            if(_loc12_ == 1)
            {
               mEquip_clip.color = 16777215;
            }
            else if(_loc12_ == 2)
            {
               mEquip_clip.color = 43520;
            }
            else if(_loc12_ == 3)
            {
               mEquip_clip.color = 3368703;
            }
            else if(_loc12_ == 4)
            {
               mEquip_clip.color = 13369548;
            }
            else if(_loc12_ == 5)
            {
               mEquip_clip.color = 16777062;
            }
            mEquip_clip.pivotX = mEquip_clip.pivotY = 0;
            mEquip_clip.scaleX = mEquip_clip.scaleY = 2.1;
            GlobalData.$mStarling.juggler.add(mEquip_clip);
            mEquip_clip.x = mEquipUI.x - 18;
            mEquip_clip.y = mEquipUI.y - 18;
            addChild(mEquip_clip);
         }
         addChild(mEquipUI);
         if(param5 > -1)
         {
            this.mTxt_lv = new Sprite();
            _loc14_ = GlobalFunction.checkEquipIsBook(mEquip.equipData.id);
            _loc9_ = GlobalLanguageStr.getLanguageStr(20017,_loc14_ ? _loc6_ : mEquip.lv);
            _loc11_ = new LOL_TextField(_loc9_,_loc9_.length * 10,35);
            _loc11_.fontSize = 20;
            _loc11_.fontColor = 16777215;
            _loc11_.hAlign = "center";
            _loc11_.shadowFilter();
            mTxt_lv.addChild(_loc11_);
            mTxt_lv.touchable = false;
            mTxt_lv.x = (mEquipUI.width - _loc11_.width) / 2 + 3;
            if(mEquip.symp >= 0)
            {
               mTxt_lv.y = mEquipUI.y + mEquipUI.height - 22;
            }
            else
            {
               mTxt_lv.y = mEquipUI.y + mEquipUI.height - 19;
            }
            addChild(mTxt_lv);
         }
      }
      
      public function updateEquipUI() : void
      {
         if(mEquipUI && mEquip)
         {
            StarlingTools.removeChildrenClear(mEquipUI);
            mEquip.getRes(mEquipUI);
         }
      }
      
      public function setUsedStatusUI() : int
      {
         var _loc3_:Quad = null;
         var _loc1_:LOL_TextField = null;
         var _loc2_:int = -1;
         if(mEquip && mEquipUI)
         {
            _loc2_ = GlobalFunction.checkEquipHasUsed(data["id"]);
            if(_loc2_ > -1)
            {
               _loc2_ = Math.floor(_loc2_ * 0.1);
               _loc3_ = Tools.newQuad(82,16,0,0,0);
               _loc3_.touchable = false;
               _loc1_ = new LOL_TextField("",82,20);
               _loc1_.touchable = false;
               _loc1_.fontSize = 15;
               _loc1_.fontColor = 16777215;
               _loc1_.hAlign = "center";
               addChild(_loc3_);
               addChild(_loc1_);
               _loc3_.x = mEquipUI.x + 5;
               _loc3_.y = mEquipUI.y + mEquipUI.height - _loc3_.height - 10;
               _loc1_.x = _loc3_.x;
               _loc1_.y = _loc3_.y - 2;
               if(_loc2_ == 0)
               {
                  _loc1_.text = GlobalLanguageStr.getLanguageStr(10130);
               }
               else
               {
                  _loc1_.text = GlobalLanguageStr.getLanguageStr(10131,_loc2_);
               }
            }
         }
         return _loc2_;
      }
      
      public function getUIRec() : Rectangle
      {
         return new Rectangle(0,0,mEquipUI.width,mEquipUI.height);
      }
      
      public function setOtherUIs(param1:Boolean = false) : void
      {
         var _loc7_:int = 0;
         var _loc6_:String = null;
         var _loc10_:TextField = null;
         var _loc11_:Array = null;
         var _loc8_:int = 0;
         var _loc3_:String = null;
         var _loc5_:TextField = null;
         var _loc4_:TextField = null;
         var _loc9_:TextField = null;
         var _loc2_:Rectangle = null;
         if(mEquip)
         {
            _loc7_ = GlobalData.$mStageWidth * 0.4;
            _loc6_ = Tools.formatLineX(mEquip.equipData.name,GlobalTextStyle.COLOR_B_P_B_R);
            _loc10_ = GlobalTextStyle.getTextField(mEquip.equipData.name,20,1118481,"left",_loc7_,35);
            _loc11_ = [7015559,15329540,13777209];
            _loc8_ = int(GlobalData.$mConfig_simple.equip_alchemy.equip_al);
            _loc3_ = mEquip.getStep() > -1 ? GlobalLanguageStr.getLanguageStr(90703,mEquip.getStep()) : "";
            _loc5_ = GlobalFunction.createTextField(200,30,_loc3_,"",20,_loc11_[mEquip.getStar() - _loc8_]);
            _loc5_.hAlign = "left";
            this.addChild(_loc5_);
            _loc4_ = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20079,param1 ? mEquip.slv : mEquip.lv),20,4926491,"left",_loc7_,46);
            _loc10_.x = _loc4_.x = 130;
            _loc4_.x = _loc10_.x + _loc10_.width - 50;
            _loc10_.y = _loc4_.y = _loc5_.y = 15;
            if(MainConfig.$isEnglish)
            {
               _loc4_.x = _loc10_.x + _loc10_.width + 30;
            }
            _loc5_.x = _loc10_.x + _loc10_.textBounds.width;
            addChild(_loc10_);
            addChild(_loc4_);
            if(!param1)
            {
               mAttBaseNum = 0;
               createAttTxt(98140,mEquip.getHpMax(),this._bg);
               createAttTxt(98141,mEquip.getDamage(),this._bg);
               createAttTxt(98142,mEquip.getDePh(),this._bg);
               createAttTxt(98143,mEquip.getDeMa(),this._bg);
               createAttTxt(98144,mEquip.getRange(),this._bg);
               createAttTxt(98145,mEquip.getSpeed(),this._bg);
               mAttNewNum = 0;
               if(mEquip.hasHit())
               {
                  createAttNewTxt(30021,mEquip.getHit(),this._bg);
               }
               if(mEquip.hasFlee())
               {
                  createAttNewTxt(30022,mEquip.getFlee(),this._bg);
               }
               if(mEquip.hasCrit())
               {
                  createAttNewTxt(30023,mEquip.getCrit(),this._bg);
               }
               if(mEquip.hasTough())
               {
                  createAttNewTxt(30024,mEquip.getTough(),this._bg);
               }
               if(mEquip.symp >= 0)
               {
                  if(mBox_magic)
                  {
                     StarlingTools.removeChildrenClear(mBox_magic);
                     mBox_magic.removeFromParent(true);
                     mBox_magic = null;
                  }
                  mBox_magic = getMagicUIs(mEquip.symp,mEquip.magic);
                  addChild(mBox_magic);
                  mBox_magic.x = _loc4_.x - 10;
                  mBox_magic.y = _loc4_.y + 30;
               }
            }
            else
            {
               _loc9_ = GlobalTextStyle.getTextField(mEquip.getBookSkill().getInfo(),16,4926491,"left",360,24 * 2);
               _loc9_.touchable = false;
               _loc2_ = _loc9_.textBounds;
               _loc9_.x = 130;
               _loc9_.y = 45;
               addChild(_loc9_);
            }
         }
      }
      
      private function createAttTxt(param1:int, param2:int, param3:DisplayObject) : void
      {
         var _loc6_:* = 0;
         var _loc7_:TextField = null;
         var _loc5_:int = GlobalData.$mStageWidth * 0.3;
         var _loc4_:int = mEquip.haloLv;
         if(param2 > 0 && mAttBaseNum < 2)
         {
            _loc6_ = 16777215;
            if(_loc4_ > 0)
            {
               _loc6_ = uint(Equip.haloColor[_loc4_ - 1]);
            }
            _loc7_ = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(param1) + " " + param2,15,_loc6_,"left",_loc5_,29,GlobalConfig.FONT_1);
            _loc7_.touchable = false;
            _loc7_.x = 130;
            _loc7_.y = 35 + 5 + (int(mAttBaseNum * 19 - 1));
            mAttBaseNum += 1;
            addChild(_loc7_);
         }
      }
      
      private function createAttNewTxt(param1:int, param2:int, param3:DisplayObject) : void
      {
         var _loc6_:TextField = null;
         var _loc5_:int = GlobalData.$mStageWidth * 0.3;
         var _loc4_:Number = 0;
         if(param2 > 0 && mAttNewNum < 2)
         {
            _loc6_ = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(param1) + " " + param2,15,4926491,"left",_loc5_,29,GlobalConfig.FONT_1);
            _loc6_.touchable = false;
            _loc6_.x = MainConfig.$isEA ? 260 : 230;
            _loc6_.y = 35 + 5 + (int(mAttNewNum * 19 - 1));
            mAttNewNum += 1;
            addChild(_loc6_);
         }
      }
      
      public function onTRIGGERED_btns(param1:Event) : void
      {
         var _loc2_:Array = null;
         if(this.data["isHad"] == 2)
         {
            _loc2_ = GlobalFunction.changeEquipGroup(_data["id"],LOL_TeamSet.$mCurrIndex,GlobalData.$tempEquipChangeIndex);
            sendDressChange(_loc2_);
            _loc2_ = null;
         }
         else if(this.data["isHad"] != 1)
         {
            if(this.data["isHad"] == 0)
            {
               _loc2_ = GlobalFunction.changeEquipGroup("",LOL_TeamSet.$mCurrIndex,GlobalData.$tempEquipChangeIndex,true);
               sendDressChange(_loc2_);
               _loc2_ = null;
            }
         }
         GlobalData.$mEventDispatcher.dispatchEventWith("update_panelequip",false,_data);
         (this.parent.parent.parent as PanelEquipInfoSelect).onCLOSE_PANEL_SELF();
      }
      
      public function bg_Touch(param1:TouchEvent) : void
      {
      }
      
      private function sendDressChange(param1:Array) : void
      {
         var _request:uint = ++mDressRequestId;
         var _team:int = LOL_TeamSet.$mCurrIndex;
         var _slot:int = GlobalData.$tempEquipChangeIndex;
         var _screen:String = GlobalData.$mGameClassObject.mLayoutUICenter.screenID;
         var _expected:* = param1[_team][_slot];
         SendServiceAMFFun.send_user_equip_dress(function(param2:Object):void
         {
            re_equip_dress(param2,_request,_screen,_team,_slot,_expected);
         },{"data":param1});
      }

      private function re_equip_dress(param1:Object, param2:uint, param3:String, param4:int, param5:int, param6:*) : void
      {
         if(GlobalFunction.isMalformedProfileReceipt(param1))
         {
            return;
         }
         if(GlobalFunction.isLegacyProfileReceipt(param1))
         {
            RpcStaticCall.$remoting.reportDiagnostic("PROFILE_RECEIPT_LEGACY|method=user.equip_dress");
         }
         var _layout:Object = GlobalData.$mGameClassObject.mLayoutUICenter;
         if(param2 != mDressRequestId || _layout.screenID != param3 || !_layout.checkPanelIsCurrentScreen() || LOL_TeamSet.$mCurrIndex != param4 || GlobalData.$tempEquipChangeIndex != param5 || GlobalData.$userData.as_equips[param4][param5] != param6)
         {
            return;
         }
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("equip_fun_change");
      }
   }
}

