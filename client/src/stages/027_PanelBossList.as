package com.meng52.game.ui.panel
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.ui.element.ItemBossRank;
   import com.meng52.game.ui.screen.PanelCenterMainAvatar;
   import com.meng52.net.SendServiceAMFFun;
   import feathers.controls.List;
   import feathers.data.ListCollection;
   import feathers.display.Scale9Image;
   import feathers.layout.VerticalLayout;
   import flash.geom.Rectangle;
   import starling.display.Image;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class PanelBossList extends PanelCenterMainAvatar
   {
      
      public static var $mBoss_data:Object;
      
      public var mBox_a:Sprite;
      
      public var mBoss_data:Object;
      
      public function PanelBossList()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         this.setPopPanelBg(GlobalLanguageStr.getLanguageStr(20357),GlobalData.$center_height);
         sendEnter(reService_list);
         GlobalData.$mEventDispatcher.addEventListener("close_panel_self",CLOSE_PANEL_SELF);
      }
      
      public function sendEnter(param1:Function) : void
      {
         SendServiceAMFFun.send_user_enter_zoneboss(param1);
      }
      
      private function CLOSE_PANEL_SELF(param1:Event) : void
      {
         super.onCLOSE_PANEL_SELF();
      }
      
      private function reService_list(param1:Object) : void
      {
         var _loc23_:Object = null;
         var _loc5_:Scale9Image = null;
         var _loc19_:Image = null;
         var _loc12_:TextField = null;
         var _loc7_:Image = null;
         var _loc9_:TextField = null;
         var _loc16_:Number = NaN;
         var _loc6_:TextField = null;
         var _loc13_:Object = null;
         var _loc15_:Object = null;
         var _loc4_:Sprite = null;
         var _loc20_:int = 0;
         var _loc24_:Number = NaN;
         var _loc8_:Object = null;
         var _loc14_:VerticalLayout = null;
         mBoss_data = param1.data;
         var _loc3_:Array = mBoss_data.rank_list as Array;
         if(_loc3_ == null || _loc3_ != null && _loc3_.length <= 0)
         {
            setTips(GlobalLanguageStr.getLanguageStr(90132));
            mTips.y = int((GlobalData.$center_height - mTips.height) / 2 + 15);
            return;
         }
         var _loc17_:Object = mBoss_data.attack_log.gifts;
         var _loc21_:int = int(_loc17_ ? _loc17_.gold : 0);
         var _loc2_:int = int(_loc17_ ? _loc17_.mark : 0);
         var _loc22_:String = "";
         if(mBoss_data.attack_log.attack_num <= 0)
         {
            if(mBoss_data.boss.current_hp > 0)
            {
               _loc22_ = GlobalLanguageStr.getLanguageStr(20398);
            }
            else
            {
               _loc22_ = GlobalLanguageStr.getLanguageStr(20383);
            }
         }
         else if(mBoss_data.boss.current_hp > 0)
         {
            _loc22_ = GlobalLanguageStr.getLanguageStr(20399,mBoss_data.attack_log.attack_num,mBoss_data.attack_log.attack_hp,mBoss_data.my_rank,_loc21_,_loc2_);
         }
         else
         {
            _loc22_ = GlobalLanguageStr.getLanguageStr(20365,mBoss_data.attack_log.attack_num,mBoss_data.attack_log.attack_hp,mBoss_data.my_rank,_loc21_,_loc2_);
         }
         var _loc11_:TextField = GlobalTextStyle.getTextField(_loc22_,20,16777215,"left",560,95);
         _loc11_.touchable = false;
         _loc11_.x = 40;
         _loc11_.y = 95;
         addChild(_loc11_);
         var _loc18_:Number = _loc11_.y + _loc11_.height;
         if(mBoss_data.boss)
         {
            if(mBoss_data.boss.kill_log)
            {
               _loc23_ = mBoss_data.boss.kill_log;
               mBox_a = new Sprite();
               _loc5_ = GlobalFunction.createScale9Image("UI_bg_9slice_0_0000",560,180,new Rectangle(110,55,70,20));
               mBox_a.addChild(_loc5_);
               mBox_a.x = this.mImg9_baseBg.x + (mImg9_baseBg.width - _loc5_.width) * 0.5;
               mBox_a.y = _loc18_ + 6;
               _loc19_ = GlobalFunction.createImage("UI_boss_bg_9_0000");
               _loc19_.x = 10;
               _loc19_.y = 8;
               mBox_a.addChild(_loc19_);
               _loc12_ = GlobalTextStyle.getTextField(_loc23_["name"],20,1118481,"left",170,35);
               _loc12_.x = _loc5_.x + 120;
               _loc12_.y = _loc5_.y + 20;
               mBox_a.addChild(_loc12_);
               _loc7_ = GlobalFunction.getVipImg(_loc23_.vip_lv,_loc23_.uid);
               _loc7_.visible = GlobalFunction.checkIOSvip();
               _loc7_.pivotX = 0;
               _loc7_.x = _loc12_.x;
               _loc7_.y = _loc12_.y + _loc12_.height + 10 + 3;
               mBox_a.addChild(_loc7_);
               _loc9_ = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20004,_loc23_["lv"]),20,4926491,"center",100,35);
               _loc9_.x = _loc12_.x + _loc12_.width + 10;
               _loc9_.y = _loc12_.y;
               mBox_a.addChild(_loc9_);
               _loc16_ = MainConfig.$isEnglish ? 50 : 30;
               _loc6_ = GlobalFunction.createTextField(110,_loc16_,GlobalLanguageStr.getStr(20376),"",MainConfig.$isEnglish ? 16 : 20,4926491);
               _loc6_.hAlign = "left";
               _loc6_.x = _loc5_.x + 15;
               _loc6_.y = MainConfig.$isEnglish ? _loc5_.y + 105 : _loc5_.y + 125;
               mBox_a.addChild(_loc6_);
               _loc13_ = mBoss_data.attack_log.gifts != null && (mBoss_data.attack_log.gifts.gold != null || mBoss_data.attack_log.gifts.coin != null || mBoss_data.attack_log.gifts.medal != null || mBoss_data.attack_log.gifts.mark != null) ? mBoss_data.attack_log.gifts : GlobalData.$mConfig_simple.zone_boss.kill_gifts;
               _loc15_ = null;
               _loc4_ = new Sprite();
               _loc20_ = 0;
               for(var _loc10_:Object in _loc13_)
               {
                  if(_loc10_ == "avatar" || _loc10_ == "avatar_soul" || _loc10_ == "equip" || _loc10_ == "equip_soul")
                  {
                     _loc15_ = GlobalFunction.getAwardByType(_loc10_.toString(),_loc13_[_loc10_],false,null,"",true,0.8);
                  }
                  else
                  {
                     _loc15_ = GlobalFunction.getAwardByType(_loc10_.toString(),_loc13_[_loc10_]);
                     _loc4_.scaleX = _loc4_.scaleY = 0.9;
                  }
                  _loc15_.ui.x = 80 * _loc20_;
                  _loc4_.addChild(_loc15_.ui);
                  _loc20_ += 1;
               }
               _loc4_.x = _loc6_.x + 100;
               _loc4_.y = 90;
               mBox_a.addChild(_loc4_);
               addChild(mBox_a);
               mBox_a.flatten();
               _loc18_ += _loc5_.height;
            }
         }
         _loc18_ = _loc18_;
         this.delList();
         if(this.mList == null)
         {
            _loc24_ = _loc18_;
            _loc8_ = {
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
            _loc14_ = new VerticalLayout();
            _loc14_.paddingTop = _loc8_.paddingTop;
            _loc14_.paddingRight = _loc8_.paddingRight;
            _loc14_.paddingBottom = _loc8_.paddingBottom;
            _loc14_.paddingLeft = _loc8_.paddingLeft;
            _loc14_.horizontalAlign = _loc8_.horizontalAlign;
            _loc14_.verticalAlign = _loc8_.verticalAlign;
            _loc14_.hasVariableItemDimensions = true;
            this.mList = new List();
            this.mList.isSelectable = false;
            this.mList.width = GlobalData.$mStageWidth - 20;
            this.mList.height = mListH = GlobalData.$center_height - 121 - 276;
            this.mList.layout = _loc14_;
            this.mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
            this.mList.x = int((GlobalData.$mStageWidth - this.mList.width) * 0.5);
            this.mList.y = mListY = _loc24_ + 6;
            this.mList.snapScrollPositionsToPixels = true;
            this.addChild(this.mList);
            _loc8_ = null;
            _loc14_ = null;
            this.mList.dataProvider = new ListCollection();
         }
         addList();
      }
      
      override public function addList() : void
      {
         var _loc1_:* = null;
         var _loc6_:Object = null;
         var _loc7_:Array = mBoss_data.rank_list as Array;
         var _loc2_:Array = [];
         var _loc8_:int = 0;
         var _loc3_:int = int(_loc7_.length);
         var _loc4_:Object = mBoss_data.boss.kill_log;
         var _loc5_:String = "";
         if(_loc4_)
         {
            _loc5_ = _loc4_.uid;
         }
         _loc8_ = 0;
         while(_loc8_ < _loc3_)
         {
            _loc6_ = _loc7_[_loc8_];
            _loc6_["status"] = 1;
            _loc6_["indexID_s"] = _loc8_;
            _loc6_["isRobot"] = _loc5_;
            _loc6_["numberIndex"] = mBoss_data.boss.current_hp;
            _loc2_.push(_loc6_);
            _loc8_++;
         }
         if(_loc2_.length > 0)
         {
            delTips();
            this.setListTimer(mList,_loc2_,ItemBossRank,false);
         }
         else
         {
            setTips(GlobalLanguageStr.getLanguageStr(90132));
            mTips.y = int((GlobalData.$center_height - mTips.height) / 2 + 5);
         }
      }
      
      override public function onTRIGGERED_closePanel(param1:Event) : void
      {
         GlobalData.$mGameClassObject.closePopForPanel();
         GlobalData.$tempMazeSelect = "zone_boss";
      }
   }
}

