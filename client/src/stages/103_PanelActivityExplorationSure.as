package com.meng52.game.ui.panel
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.ui.element.ItemExplorationSelect;
   import com.meng52.game.ui.element.LOL_IconText;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelCenterDNTeam;
   import com.meng52.game.ui.screen.PanelCenterMainAvatar;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.data.ListCollection;
   import feathers.display.Scale9Image;
   import feathers.layout.TiledRowsLayout;
   import flash.geom.Rectangle;
   import starling.core.Starling;
   import starling.events.Event;
   
   public class PanelActivityExplorationSure extends PanelCenterMainAvatar
   {
      
      private const _BTN_OK:String = "_btn_ok";
      
      private const _BTN_BACK:String = "_btn_back";
      
      private const cfg:Object = GlobalData.$mConfig_simple.explore;
      
      private var selectData:Object;
      
      private var mInfo_bg:Scale9Image;
      
      private var mInfo_txt:TextFieldHtmlRenderer;
      
      private var mBack_btn:LOL_Scale9Button;
      
      private var mOk_btn:LOL_Scale9Button;
      
      private var mInfo:LOL_IconText;
      
      private const NUM_IN_ROW:int = 5;
      
      private const CONST_HEIGHT:int = 275;
      
      private const AVT_HEIGHT:int = 140;
      
      private var row:int = 0;
      
      public function PanelActivityExplorationSure(param1:Object)
      {
         selectData = Tools.clone(param1);
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         row = selectData.num % 5 == 0 ? selectData.num / 5 : selectData.num / 5 + 1;
         var _loc2_:int = 275 + 140 * row;
         this.setPopPanelBg(GlobalLanguageStr.getStr(90555),_loc2_);
         setList();
         addList();
         setUI();
      }
      
      private function setUI() : void
      {
         mInfo_bg = GlobalFunction.createScale9Image("UI_bg_9slice_7_0000",574,140 * row,new Rectangle(50,40,20,20));
         mInfo_bg.x = this.mImg9_baseBg.x + (this.mImg9_baseBg.width - mInfo_bg.width) * 0.5;
         mInfo_bg.y = this.mImg9_baseBg.y + 85;
         this.addChild(mInfo_bg);
         mInfo = new LOL_IconText(GlobalLanguageStr.getStr(90603),13777209,MainConfig.$isEnglish ? 17 : 20);
         mInfo.x = MainConfig.$isEnglish ? mInfo_bg.x - 10 : mInfo_bg.x + 115;
         mInfo.y = mInfo_bg.y + mInfo_bg.height + 10;
         mInfo.bgVisible = false;
         this.addChild(mInfo);
         mInfo_txt = GlobalTextStyle.getHtmlTextRenderer();
         mInfo_txt.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90602,selectData.num),[16777215,6475106,13777209,16777215],MainConfig.$isEnglish ? 30 : 20,20);
         mInfo_txt.x = MainConfig.$isEnglish ? mInfo_bg.x - 7 : mInfo_bg.x + 170;
         mInfo_txt.y = mInfo.y + mInfo.height;
         this.addChild(mInfo_txt);
         mBack_btn = new LOL_Scale9Button(GlobalLanguageStr.getStr(20070),150,70,"UI_btn_normalFun_0000");
         mBack_btn.name = "_btn_back";
         mBack_btn.x = mInfo_bg.x + mInfo_bg.width * 0.5 - mBack_btn.width - 20;
         mBack_btn.y = mInfo_txt.y + 40;
         mBack_btn.addEventListener("triggered",onTRIGGERED_btn);
         addChild(mBack_btn);
         mOk_btn = new LOL_Scale9Button(GlobalLanguageStr.getStr(20021),150,70,"UI_btn_normalFun_0000");
         mOk_btn.name = "_btn_ok";
         mOk_btn.x = mInfo_bg.x + mInfo_bg.width * 0.5 + 20;
         mOk_btn.y = mBack_btn.y;
         mOk_btn.addEventListener("triggered",onTRIGGERED_btn);
         addChild(mOk_btn);
      }
      
      private function onTRIGGERED_btn(param1:Event) : void
      {
         var _loc3_:Array = null;
         var _loc4_:int = 0;
         var _loc2_:String = (param1.currentTarget as LOL_Scale9Button).name;
         switch(_loc2_)
         {
            case "_btn_ok":
               _loc3_ = [];
               _loc4_ = 0;
               while(_loc4_ < (selectData.arr as Array).length)
               {
                  _loc3_.push(selectData.arr[_loc4_].id);
                  _loc4_++;
               }
               SendServiceAMFFun.send_user_exploration_make_army(backFun,{"aids":_loc3_});
               break;
            case "_btn_back":
               GlobalData.$mGameClassObject.closePopForPanel(mPop_currID);
         }
      }
      
      private function backFun(param1:Object) : void
      {
         var select_avt:Object;
         var i:String;
         var fun:*;
         var fun1:*;
         var _re:Object = param1;
         var _layout:Object = GlobalData.$mGameClassObject != null ? GlobalData.$mGameClassObject.mLayoutUICenter : null;
         var _routeScreen:String = _layout == null ? "" : String(_layout.screenID);
         var _routePanel:String = _layout == null ? "" : String(_layout.mCurrPanel);
         var _routeLastPanel:String = _layout == null ? "" : String(_layout.lastPanel_ID);
         var _routeMap:Object = _layout == null ? null : _layout.mPanelExplorationMap;
          // This method is passed as an AS3 bound method closure. A successful
          // receipt still updates profile state centrally, but a closed panel
          // must not close a newer screen or navigate on its behalf.
          if(!this.stage)
          {
             return;
          }
         if(_re.data)
         {
            if(GlobalFunction.isVersionedProfileReceipt(_re) && !GlobalData.isCurrentProfileSyncEnvelope(_re.state_sync)) return;
            fun = function():void
            {
               Starling.juggler.delayCall(fun1,0.1);
            };
            fun1 = function():void
            {
               var _currentLayout:Object = GlobalData.$mGameClassObject != null ? GlobalData.$mGameClassObject.mLayoutUICenter : null;
               if(_currentLayout == null || _currentLayout.screenID != _routeScreen || _currentLayout.mCurrPanel != _routePanel || _currentLayout.lastPanel_ID != _routeLastPanel || _currentLayout.mPanelExplorationMap !== _routeMap)
               {
                  return;
               }
               _currentLayout.showPanel("exploration_select_game",false,true,null);
            };
            select_avt = Tools.clone(_re.data.army);
            for(i in select_avt)
            {
               select_avt[i]["id"] = i;
            }
            GlobalData.$exploration_select_avatar=select_avt;
            GlobalData.$exploration_data=_re.data;
            if(!GlobalFunction.isVersionedProfileReceipt(_re))
            {
               GlobalData.$userData.exploration.army = select_avt;
            }
            GlobalFunction.closePopAllPanel(fun);
         }
      }
      
      override public function setList() : void
      {
         var _loc3_:Number = NaN;
         var _loc2_:Object = null;
         var _loc1_:TiledRowsLayout = null;
         this.delList();
         if(this.mList == null)
         {
            _loc3_ = 90;
            _loc2_ = {
               "paging":0,
               "gap":0,
               "horizontalGap":20,
               "verticalGap":20,
               "paddingTop":10,
               "paddingRight":0,
               "paddingBottom":20,
               "paddingLeft":0,
               "horizontalAlign":"center",
               "verticalAlign":"top",
               "tileHorizontalAlign":"left",
               "tileVerticalAlign":"top"
            };
            _loc1_ = new TiledRowsLayout();
            _loc1_.useSquareTiles = false;
            _loc1_.horizontalGap = _loc2_.horizontalGap;
            _loc1_.verticalGap = _loc2_.verticalGap;
            _loc1_.paging = _loc2_.paging;
            _loc1_.paddingTop = _loc2_.paddingTop;
            _loc1_.paddingRight = _loc2_.paddingRight;
            _loc1_.paddingBottom = _loc2_.paddingBottom;
            _loc1_.paddingLeft = _loc2_.paddingLeft;
            _loc1_.horizontalAlign = _loc2_.horizontalAlign;
            _loc1_.verticalAlign = _loc2_.verticalAlign;
            _loc1_.tileHorizontalAlign = _loc2_.tileHorizontalAlign;
            _loc1_.tileVerticalAlign = _loc2_.tileVerticalAlign;
            this.mList = new List();
            this.mList.clipContent = true;
            this.mList.autoHideBackground = true;
            this.mList.isSelectable = false;
            this.mList.width = GlobalData.$mStageWidth - 20;
            this.mList.height = GlobalData.$center_height - 203;
            this.mList.layout = _loc1_;
            this.mList.verticalScrollBarFactory = GlobalData.verticalScrollBarFactory;
            this.mList.x = int((GlobalData.$mStageWidth - this.mList.width) * 0.5);
            this.mList.y = _loc3_;
            this.mList.snapScrollPositionsToPixels = true;
            this.addChild(this.mList);
            _loc2_ = null;
            _loc1_ = null;
            this.mList.dataProvider = new ListCollection();
         }
      }
      
      override public function addList() : void
      {
         var _loc6_:* = null;
         var _loc1_:Avatar = null;
         var _loc5_:Object = null;
         var _loc7_:int = 0;
         var _loc2_:Array = [];
         var _loc3_:Array = Tools.clone(selectData.arr);
         var _loc4_:String = "";
         _loc7_ = 0;
         while(_loc7_ < _loc3_.length)
         {
            _loc4_ = _loc3_[_loc7_].id;
            _loc5_ = {};
            if(GlobalFunction.checkSearchTypeByType(_loc4_,1))
            {
               _loc5_ = _loc3_[_loc7_];
               _loc5_["id"] = _loc4_;
               _loc1_ = new Avatar(_loc4_,_loc5_);
               _loc5_["lv"] = _loc1_.lv;
               _loc5_["star"] = _loc1_.getStar();
               _loc5_["indn"] = PanelCenterDNTeam.checkIsInDn(_loc1_.id) == null ? 0 : 1;
               _loc5_["teamNum"] = GlobalFunction.getTeamMemberNum(_loc5_["id"]);
               _loc5_["power"] = _loc1_.getPower(true);
               _loc5_["choice"] = false;
               _loc5_["status"] = false;
               _loc2_.push(_loc5_);
               _loc1_.clear();
               _loc1_ = null;
            }
            _loc7_++;
         }
         _loc2_.sortOn(["power","star","lv","id"],[0x10 | 2,0x10 | 2,0x10 | 2,1]);
         this.setListTimer(mList,_loc2_,ItemExplorationSelect,false);
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         super.onREMOVED_FROM_STAGE(param1);
         delList();
         if(mInfo_bg)
         {
            mInfo_bg.dispose();
            mInfo_bg.removeFromParent(true);
         }
         mInfo_bg = null;
         if(mInfo_txt)
         {
            mInfo_txt.dispose();
            mInfo_txt.removeFromParent(true);
         }
         mInfo_txt = null;
         if(mOk_btn)
         {
            mOk_btn.dispose();
            mOk_btn.removeFromParent(true);
         }
         mOk_btn = null;
         if(mInfo)
         {
            StarlingTools.removeChildrenClear(mInfo);
         }
         mInfo = null;
      }
   }
}

