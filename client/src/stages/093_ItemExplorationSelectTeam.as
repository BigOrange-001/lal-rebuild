package com.meng52.game.ui.element
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.ui.panel.PanelActivityExplorationMyTeam;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.Tools;
   import feathers.controls.renderers.IListItemRenderer;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import starling.display.Image;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class ItemExplorationSelectTeam extends ItemBase implements IListItemRenderer
   {
      
      private const W_H_MAX:Number = 104;
      
      private var mUI_select:Image;
      
      private var _quad:Quad;
      
      private var _txt:TextField;
      
      private var _upIcon:Image;
      
      private var _live:Boolean = false;
      
      private const addY:int = 15;
      
      public function ItemExplorationSelectTeam()
      {
         super();
      }
      
      override public function layoutWH() : void
      {
         this.width = 104 - 10;
         this.height = 104 + 10;
      }
      
      override public function init(param1:Object) : void
      {
         var _loc8_:int = 0;
         this.setAvatar(this.data.id,3,null,false,true);
         this.addChild(this.mAvatar);
         var _loc3_:int = 0;
         this.visibleTeam(0);
         var _loc2_:Array = (GlobalData.$userData.team[0] as Array).concat();
         var _loc6_:Number = _loc2_.indexOf(this.data.id);
         this.mUI_select = GlobalFunction.createImage("UI_tag_2_0000");
         this.mUI_select.touchable = false;
         this.mUI_select.x = GlobalData.$iconRec90.width - this.mUI_select.width + 5;
         this.mUI_select.y = GlobalData.$iconRec90.height - this.mUI_select.height + 10;
         this.mUI_select.visible = this.data["status"];
         this.addChild(this.mUI_select);
         if(this.data.current_hp <= 0)
         {
            this.visibleMask(true);
            this.quad = true;
         }
         updateBuffState();
         var _loc7_:Array = PanelActivityExplorationMyTeam.cloneArray;
         var _loc4_:Object = GlobalData.$explorationArmyTeam;
         _loc8_ = 0;
         while(_loc8_ < _loc7_.length)
         {
            if(_loc7_[_loc8_] != null && _loc7_[_loc8_] == this.mAvatarData.id && !GlobalData.$explorationArmyTeam[_loc8_])
            {
               setProAvt();
               GlobalData.$explorationArmyTeam[_loc8_] = 1;
            }
            _loc8_++;
         }
         var _loc5_:Array = GlobalData.$exploration_team_avatar;
         _loc8_ = 0;
         while(_loc8_ < GlobalData.$exploration_team_avatar.length)
         {
            if(GlobalData.$exploration_team_avatar[_loc8_] != null && GlobalData.$exploration_team_avatar[_loc8_].name == this.data["id"])
            {
               GlobalData.$exploration_team_avatar[_loc8_].item = this;
            }
            _loc8_++;
         }
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(_upIcon)
         {
            _upIcon.dispose();
            _upIcon.removeFromParent(true);
         }
         _upIcon = null;
      }
      
      public function get quad() : Boolean
      {
         return _live;
      }
      
      public function set quad(param1:Boolean) : void
      {
         var _loc3_:int = 0;
         var _loc2_:* = 0;
         _live = param1;
         if(param1)
         {
            _quad = new Quad(100,20,590848);
            _quad.pivotX = _quad.width * 0.5;
            _quad.x = this.mAvatar.width * 0.5 - 5;
            _quad.y = this.mAvatar.height * 0.4;
            this.addChild(_quad);
            if(int(GlobalData.$userData.vip_lv) >= int(GlobalData.$mConfig_simple.explore.relive_vip))
            {
               _loc3_ = 90668;
               _loc2_ = 6475106;
            }
            else
            {
               _loc3_ = 90576;
               _loc2_ = 10027008;
            }
            _txt = new TextField(100,20,GlobalLanguageStr.getStr(_loc3_),"",15,_loc2_,true);
            _txt.pivotX = _txt.width * 0.5;
            _txt.x = _quad.x;
            _txt.y = _quad.y;
            this.addChild(_txt);
         }
         else
         {
            this.visibleMask(false);
            if(_quad)
            {
               _quad.removeFromParent(true);
            }
            _quad = null;
            if(_txt)
            {
               _txt.removeFromParent(true);
            }
            _txt = null;
         }
      }
      
      public function updateBuffState() : void
      {
         var _loc6_:String = null;
         var _loc4_:String = null;
         var _loc8_:Object = GlobalData.$userData.exploration;
         var _loc2_:Object = GlobalFunction.getStage_Mode(_loc8_.stage_mode);
         var _loc1_:String = _loc2_.data[1];
         var _loc5_:Boolean = _loc2_["add"] == 1;
         var _loc3_:String = this.mAvatarData.id.split("|")[0];
         var _loc7_:Object = GlobalData.$mConfig_avatar[_loc3_];
         switch(_loc1_)
         {
            case "1":
            case "2":
            case "3":
               _loc4_ = _loc7_.tl[0];
               _loc6_ = _loc1_;
               updateStart("TYPE1",_loc4_,_loc6_,_loc5_);
               break;
            case "4":
            case "5":
            case "6":
            case "7":
               _loc4_ = _loc7_.tl[1];
               _loc6_ = (int(_loc1_) - 3).toString();
               updateStart("TYPE2",_loc4_,_loc6_,_loc5_);
               break;
            case "8":
            case "9":
            case "10":
               _loc4_ = _loc7_.tl[2];
               _loc6_ = (int(_loc1_) - 7).toString();
               updateStart("TYPE3",_loc4_,_loc6_,_loc5_);
               break;
            default:
               _loc4_ = _loc1_;
               updateStart("ALL",_loc4_,_loc6_,_loc5_);
         }
      }
      
      private function updateStart(param1:String, param2:String, param3:String, param4:Boolean) : void
      {
         if(param1 == "ALL")
         {
            checkUp(param4);
         }
         else if(param2 == param3)
         {
            checkUp(param4);
         }
      }
      
      private function checkUp(param1:Boolean = true) : void
      {
         if(_upIcon)
         {
            _upIcon.removeFromParent(true);
            _upIcon = null;
         }
         if(param1)
         {
            _upIcon = GlobalFunction.createImage("UI_equip_tag_0_0000");
            _upIcon.pivotX = _upIcon.width / 2;
            _upIcon.pivotY = _upIcon.height / 2;
            _upIcon.x = GlobalData.$iconRec90.width;
            _upIcon.y = 25;
            _upIcon.rotation = -1.5707963267948966;
         }
         else
         {
            _upIcon = GlobalFunction.createImage("UI_equip_tag_0_0001");
            _upIcon.pivotX = _upIcon.width / 2;
            _upIcon.pivotY = _upIcon.height / 2;
            _upIcon.x = GlobalData.$iconRec90.width;
            _upIcon.y = 25;
            _upIcon.rotation = 3.141592653589793 / 2;
         }
         addChild(_upIcon);
      }
      
      override public function onTRIGGERED(param1:Event) : void
      {
         var _loc3_:Object = null;
         var _loc4_:Rectangle = stage.getBounds(this);
         var _loc8_:Point = new Point(_loc4_.x,_loc4_.y);
         var _loc7_:Point = localToGlobal(_loc8_);
         var _loc2_:int = int(GlobalData.$userData.records.exploration_times.relive_buy);
         var _loc6_:Array = GlobalData.$mConfig_simple.explore.relive;
         var _loc5_:int = _loc6_[0] * _loc2_ + _loc6_[1];
         var _loc9_:int = int(GlobalData.$userData.records.exploration_times.vip_relive);
         if(this.quad)
         {
            if(GlobalData.$userData.vip_lv >= GlobalData.$mConfig_simple.explore.relive_vip)
            {
               if(_loc9_ > 0)
               {
                  _loc3_ = {
                     "ok":sendMsg,
                     "no":GlobalFunction.functionNull
                  };
                  if(GlobalData.$userData.coin >= _loc5_)
                  {
                     GlobalFunction.popAlert(GlobalLanguageStr.getStr(90667),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90612,_loc5_,this.mAvatarData.avatarData.name,_loc9_),[16777215,16764006,16764006,16764006]),_loc3_);
                  }
                  else
                  {
                     GlobalFunction.popErrorCoin(_loc5_);
                  }
               }
               else
               {
                  LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getStr(90613));
               }
            }
            else
            {
               LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getStr(90576));
            }
         }
         else
         {
            changeStatus();
         }
      }
      
      private function sendMsg() : void
      {
         SendServiceAMFFun.send_user_exploration_relive(reFunc,{"aid":this.data.id});
      }
      
      private function reFunc(param1:Object) : void
      {
         var currentInfo:Object;
         if(param1.data)
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1) || !this.stage || !this.data || this.data.id != param1.data["aid"])
            {
               return;
            }
            if(GlobalFunction.didApplyProfileStateSync(param1))
            {
               currentInfo = param1.data["info"];
            }
            else if(GlobalData.$userData.exploration && GlobalData.$userData.exploration.army)
            {
               currentInfo = GlobalData.$userData.exploration.army[param1.data["aid"]];
            }
            if(currentInfo)
            {
               this.data.current_hp = currentInfo.current_hp;
               if(GlobalData.$exploration_select_avatar)
               {
                  for(var _loc3_:String in GlobalData.$exploration_select_avatar)
                  {
                     if(_loc3_ == param1.data["aid"])
                     {
                        GlobalData.$exploration_select_avatar[_loc3_] = currentInfo;
                        GlobalData.$exploration_select_avatar[_loc3_]["id"] = _loc3_;
                     }
                  }
               }
            }
            this.quad = false;
            LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getStr(90614));
         }
      }
      
      public function getPower() : Number
      {
         mAvatarData.initFightAttr();
         return mAvatarData.getPower(true);
      }
      
      public function setProAvt() : void
      {
         var _loc1_:Array = GlobalData.$exploration_team_avatar;
         if(Tools.getArrayLength(_loc1_) < 3)
         {
            this.data["status"] = true;
            this.mUI_select.visible = this.data["status"];
         }
         GlobalData.$exploration_drag = this;
         GlobalData.$mEventDispatcher.dispatchEventWith("set_start_exploration_pro_avatar",false,{
            "data":this.data["id"],
            "isSelect":this.data["status"],
            "self_power":getPower(),
            "item":this
         });
      }
      
      public function changeStatus() : void
      {
         var _loc4_:int = 0;
         var _loc2_:String = null;
         var _loc1_:Boolean = false;
         var _loc3_:Array = GlobalData.$exploration_team_avatar;
         _loc4_ = 0;
         while(_loc4_ < _loc3_.length)
         {
            if(_loc3_[_loc4_] != null)
            {
               _loc2_ = (_loc3_[_loc4_] as Sprite).name;
               if((_loc3_[_loc4_] as Sprite).name == this.data.id)
               {
                  _loc1_ = true;
               }
            }
            _loc4_++;
         }
         GlobalData.$exploration_drag = this;
         if(_loc1_ || Tools.getArrayLength(_loc3_) < 3)
         {
            this.data["status"] = !this.data["status"];
            this.mUI_select.visible = this.data["status"];
         }
         GlobalData.$mEventDispatcher.dispatchEventWith("select_exploration_select_avatar",false,{
            "data":this.data["id"],
            "isSelect":this.data["status"],
            "self_power":getPower()
         });
      }
   }
}

