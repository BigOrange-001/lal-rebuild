package com.meng52.game.ui.element
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.StarlingTools;
   import feathers.controls.List;
   import feathers.display.Scale9Image;
   import flash.geom.Rectangle;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.events.Touch;
   import starling.events.TouchEvent;
   import starling.filters.ColorMatrixFilter;
   
   public class ItemEditTeam extends ItemBase
   {
      
      private var _bg:Scale9Image;
      
      private var _role:Sprite;
      
      private var _name:LOL_TextField;
      
      private var _level:LOL_TextField;
      
      private var _send:LOL_Scale9Button;
      
      private var _data:Object = null;
      
      private var _lock:Boolean = false;
      
      private var _teamLeader:Image;
      
      public function ItemEditTeam()
      {
         super();
      }
      
      override public function layoutWH() : void
      {
         this.width = GlobalData.$mStageWidth - 40;
         this.height = 105;
      }
      
      override public function init(param1:Object) : void
      {
         var _loc7_:Boolean = false;
         var _loc2_:Image = null;
         var _loc5_:ColorMatrixFilter = null;
         var _loc3_:Object = null;
         var _loc4_:Object = null;
         var _loc6_:ColorMatrixFilter = null;
         _data = param1;
         _bg = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",GlobalData.$mStageWidth - 200,95,new Rectangle(110,55,70,20));
         _bg.x = 100;
         addChild(_bg);
         if(_data.tag == 0)
         {
            _loc7_ = GlobalFunction.isTeamItemUnlock(this.data["indexID_s"]);
            if(_loc7_)
            {
               if(data["type"] == "show_type_dynamic")
               {
                  this.touchable = false;
                  this.mBg = GlobalFunction.createImage("UI_bg_card_2_0001");
                  this.addChild(this.mBg);
               }
               else
               {
                  this.mBg = GlobalFunction.createImage("UI_bg_card_2_0002");
                  this.addChild(this.mBg);
                  _loc2_ = GlobalFunction.createImage("UI_icon_0_0000");
                  _loc2_.x = int(this.mBg.x + (this.mBg.width - _loc2_.width) * 0.5);
                  _loc2_.y = int(this.mBg.y + (this.mBg.height - _loc2_.height) * 0.5);
                  addChild(_loc2_);
               }
            }
            else
            {
               this.mBg = GlobalFunction.createImage("UI_bg_card_2_0001");
               this.addChild(this.mBg);
               _lock = true;
               _loc5_ = new ColorMatrixFilter();
               _loc5_.adjustBrightness(-0.1);
               _loc5_.adjustSaturation(-0.8);
               _bg.filter = _loc5_;
            }
         }
         else
         {
            _loc3_ = {};
            _loc3_[_data.id] = _data;
            _loc4_ = GlobalFunction.getAwardByType("avatar",_loc3_);
            _role = _loc4_.ui;
            _role.touchable = false;
            addChild(_role);
            if(data["indexID_s"] == 0)
            {
               _teamLeader = GlobalFunction.createImage("UI_tag_leader_0_0000");
               addChild(_teamLeader);
            }
            this.mAvatarData = new Avatar(_data.id,_data);
            _name = new LOL_TextField(this.mAvatarData.avatarData.name,150,30);
            _name.x = 150;
            _name.y = 15;
            addChild(_name);
            _level = new LOL_TextField(GlobalLanguageStr.getLanguageStr(20004,_data.lv),150,30);
            _level.fontColor = 4926491;
            _level.x = 150;
            _level.y = 43;
            addChild(_level);
         }
         _send = new LOL_Scale9Button("",125,45,"UI_btn_enterGame_0_0000");
         _send.x = 370;
         _send.y = (_bg.height - _send.height) / 2 - 1;
         addChild(_send);
         _send.addEventListener("triggered",send_Triggered);
         if(data.selected == 1)
         {
            _loc6_ = new ColorMatrixFilter();
            _loc6_.adjustBrightness(-0.25);
            _bg.filter = _loc6_;
            _send.visible = true;
            _send.name = "yx";
            if(data["indexID_s"] == 0)
            {
               _send.text = GlobalLanguageStr.getLanguageStr(25062);
            }
            else
            {
               _send.text = GlobalLanguageStr.getLanguageStr(25063);
            }
         }
         else if(data.selected == 0)
         {
            _bg.filter = null;
            _send.visible = true;
            _send.name = "wz";
            _send.text = GlobalLanguageStr.getLanguageStr(25022);
         }
         else if(data.selected == -1)
         {
            _send.visible = false;
         }
         else
         {
            _bg.filter = null;
            _send.visible = false;
         }
         addEventListener("touch",item_Touch);
      }
      
      private function item_Touch(param1:TouchEvent) : void
      {
         var _loc5_:List = null;
         var _loc2_:int = 0;
         var _loc4_:Array = null;
         var _loc6_:int = 0;
         var _loc3_:Touch = param1.getTouch(this,"ended");
         if(_loc3_)
         {
            _loc5_ = this.parent.parent as List;
            if(_loc5_.isScrolling)
            {
               return;
            }
            _loc2_ = 0;
            _loc4_ = _loc5_.dataProvider.data as Array;
            _loc6_ = 0;
            while(_loc6_ < _loc4_.length)
            {
               if(_lock)
               {
                  _loc4_[_loc6_]["selected"] = -1;
               }
               else if(GlobalData.$tempEditTeamSelect && GlobalData.$tempEditTeamSelect["indexID_s"] == this.index && _loc4_[_loc6_]["selected"] != -1)
               {
                  _loc4_[_loc6_]["selected"] = -1;
               }
               else if(_loc4_[_loc6_]["indexID_s"] != this.data["indexID_s"])
               {
                  if(data["index_fight"] == 1 && _loc4_[_loc6_].tag == 0 || data.tag == 0 && _loc4_[_loc6_]["index_fight"] == 1 || _loc4_[_loc6_].tag == 0 && data.tag == 0)
                  {
                     _loc4_[_loc6_]["selected"] = -1;
                  }
                  else if(GlobalFunction.isTeamItemUnlock(_loc4_[_loc6_]["indexID_s"]))
                  {
                     _loc4_[_loc6_]["selected"] = 0;
                  }
                  else
                  {
                     _loc4_[_loc6_]["selected"] = -1;
                  }
               }
               else
               {
                  if(_lock)
                  {
                     _loc4_[_loc6_]["selected"] = -1;
                  }
                  else
                  {
                     _loc4_[_loc6_]["selected"] = 1;
                  }
                  GlobalData.$tempTeamSelect = _loc4_[_loc6_];
               }
               _loc5_.dataProvider.updateItemAt(_loc6_);
               _loc6_++;
            }
            GlobalData.$tempEditTeamSelect = this.data;
         }
      }
      
      private function send_Triggered(param1:Event) : void
      {
         var _loc3_:Array = null;
         var _loc4_:int = 0;
         GlobalData.$isUpdateMazeTeam = true;
         GlobalData.$isUpdateTeamInfo = true;
         GlobalData.$tempChangeAvatarTitle = GlobalLanguageStr.getLanguageStr(90487);
         var _loc2_:LOL_Scale9Button = param1.currentTarget as LOL_Scale9Button;
         if(_loc2_.name == "yx")
         {
            GlobalData.$tempTeamSelect = this._data;
            LOL_TeamSet.$mCurrIndex = this.index;
            GlobalData.$tempEquipIndex = this.index;
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("panel_team_avatar",false,true);
         }
         else
         {
            _loc3_ = GlobalFunction.changeEquipGroupAll(GlobalData.$tempTeamSelect["indexID_s"],_data["indexID_s"]);
            SendServiceAMFFun.send_user_equip_dress(re_equip_dress,{"data":_loc3_});
            if(_data.id == "" || _data.id == null)
            {
               LOL_TeamSet.$mCurrIndex = this.index;
               GlobalData.$tempEquipIndex = this.index;
               GlobalFunction.changeTeam(GlobalData.$tempTeamID,_data["indexID_s"],GlobalData.$tempEditTeamSelect.id);
               GlobalData.$tempTeamSelect = GlobalData.$tempEditTeamSelect;
               GlobalData.$mEventDispatcher.dispatchEventWith("update_team_dn_change_only",false,{
                  "index":index,
                  "type":"show_type_team",
                  "data":GlobalData.$tempEditTeamSelect
               });
               GlobalData.$mEventDispatcher.dispatchEventWith("change_team_member",false,GlobalData.$tempEditTeamSelect);
            }
            else
            {
               LOL_TeamSet.$mCurrIndex = this.index;
               GlobalData.$tempEquipIndex = this.index;
               GlobalFunction.changeTeam(GlobalData.$tempTeamID,GlobalData.$tempEditTeamSelect["indexID_s"],_data.id);
               _loc4_ = int(GlobalData.$tempEditTeamSelect["indexID_s"]);
               GlobalData.$tempEditTeamSelect["indexID_s"] = _data["indexID_s"];
               GlobalData.$tempTeamSelect = GlobalData.$tempEditTeamSelect;
               GlobalData.$mEventDispatcher.dispatchEventWith("update_team_dn_change_only",false,{
                  "index":index,
                  "type":"show_type_team",
                  "data":GlobalData.$tempEditTeamSelect
               });
               GlobalData.$mEventDispatcher.dispatchEventWith("change_team_member",false,GlobalData.$tempEditTeamSelect);
            }
            GlobalData.$mEventDispatcher.dispatchEventWith("update_team_avatar_list",false,_data);
         }
      }
      
      private function re_equip_dress(param1:Object) : void
      {
         var _loc2_:Object = param1["params"];
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.as_equips = _loc2_["data"];
         }
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(_bg)
         {
            _bg.removeFromParent();
            _bg = null;
         }
         if(_role)
         {
            _role.removeFromParent();
            _role = null;
         }
         if(_name)
         {
            _name.removeFromParent();
            _name = null;
         }
         if(_level)
         {
            _level.removeFromParent();
            _level = null;
         }
         if(_send)
         {
            _send.removeFromParent();
            _send = null;
         }
         if(_teamLeader)
         {
            _teamLeader.removeFromParent();
            _teamLeader = null;
         }
         StarlingTools.removeChildrenClear(this);
      }
   }
}

