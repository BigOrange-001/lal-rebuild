package com.meng52.game.ui.panel
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.avatar.Avatar;
   import com.meng52.game.ui.element.ItemExplorationSelect;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelCenterDNTeam;
   import com.meng52.game.ui.screen.PanelCenterMainAvatar;
   import com.meng52.game.ui.stage.LayoutUIAnimation;
   import com.meng52.utils.Tools;
   import feathers.controls.List;
   import feathers.data.ListCollection;
   import feathers.layout.TiledRowsLayout;
   import starling.events.Event;
   
   public class PanelActivityExplorationSelect extends PanelCenterMainAvatar
   {
      
      public static var _selectNum:int = 0;
      
      private const cfg:Object = GlobalData.$mConfig_simple.explore;
      
      private const _BTN_OK:String = "_btn_ok";
      
      private var mSelectAvatarArr:Array;
      
      private var i:int = 0;
      
      private var mNum_txt:TextFieldHtmlRenderer;
      
      private var mOk_btn:LOL_Scale9Button;
      
      public function PanelActivityExplorationSelect()
      {
         super();
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         mSelectAvatarArr = [];
         this.removeEventListener("addedToStage",initializeHandler);
         GlobalData.$mEventDispatcher.addEventListener("update_exploration_select_avatar",onUPDATE_AVATAR_DATA);
         this.setPopPanelBg(GlobalLanguageStr.getStr(90550),GlobalData.$center_height + 100);
         setList();
         addList();
         setUI();
         if(mSelectAvatarArr.length > 0)
         {
            reCountPowerAndNum();
         }
      }
      
      private function setUI() : void
      {
         mOk_btn = new LOL_Scale9Button(GlobalLanguageStr.getStr(90554),150,70,"UI_btn_normalFun_0000");
         mOk_btn.name = "_btn_ok";
         mOk_btn.x = this.mImg9_baseBg.x + this.mImg9_baseBg.width - mOk_btn.width - 40;
         mOk_btn.y = this.mImg9_baseBg.y + this.mImg9_baseBg.height - mOk_btn.height - 30;
         mOk_btn.addEventListener("triggered",onTRIGGERED_btn);
         addChild(mOk_btn);
         mNum_txt = GlobalTextStyle.getHtmlTextRenderer();
         mNum_txt.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90552,_selectNum,cfg.army_max),[16777215,16764006,13777209,16777215],20,MainConfig.$isEnglish ? 18 : 20);
         mNum_txt.x = MainConfig.$isEA ? this.mImg9_baseBg.x + 70 : (MainConfig.$isEnglish ? this.mImg9_baseBg.x + 25 : this.mImg9_baseBg.x + 40);
         mNum_txt.y = MainConfig.$isEA ? mOk_btn.y + 6 : mOk_btn.y + 18;
         this.addChild(mNum_txt);
      }
      
      private function onTRIGGERED_btn(param1:Event) : void
      {
         var _loc2_:Object = null;
         if(mSelectAvatarArr.length < 1)
         {
            LayoutUIAnimation.getOnlyExample().popWords(GlobalLanguageStr.getStr(90573));
         }
         else
         {
            _loc2_ = {
               "arr":mSelectAvatarArr,
               "num":_selectNum
            };
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("exploration_select_sure",false,true,_loc2_);
         }
      }
      
      private function onUPDATE_AVATAR_DATA(param1:Event) : void
      {
         var _loc3_:Object = param1.data.data;
         var _loc2_:Boolean = Boolean(param1.data.isSelect);
         if(_loc2_)
         {
            mSelectAvatarArr.push(_loc3_);
         }
         else
         {
            i = 0;
            while(i < mSelectAvatarArr.length)
            {
               if(mSelectAvatarArr[i].id == _loc3_.id)
               {
                  mSelectAvatarArr.splice(i,1);
               }
               i = i + 1;
            }
         }
         reCountPowerAndNum();
      }
      
      private function reCountPowerAndNum() : void
      {
         _selectNum = mSelectAvatarArr.length;
         mNum_txt.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90552,_selectNum,cfg.army_max),[16777215,16764006,13777209,16777215],20,MainConfig.$isEnglish ? 18 : 20);
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
            this.mList.height = GlobalData.$center_height - 103;
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
         var _loc1_:Avatar = null;
         var _loc7_:Object = null;
         var _loc2_:Array = [];
         var _loc3_:Object = Tools.clone(GlobalData.$userData.avatars);
         var _loc6_:Boolean = false;
         var _loc4_:Boolean = false;
         var _loc5_:String = "";
         var _army:Object = GlobalData.$userData.exploration.army;
         for(var _loc8_:Object in _loc3_)
         {
            _loc5_ = _loc8_.toString();
            if(GlobalFunction.checkSearchTypeByType(_loc5_,1))
            {
               _loc7_ = _loc3_[_loc8_];
               _loc7_["id"] = _loc5_;
               _loc1_ = new Avatar(_loc5_,_loc7_);
               _loc7_["lv"] = _loc1_.lv;
               _loc7_["star"] = _loc1_.getStar();
               _loc7_["indn"] = PanelCenterDNTeam.checkIsInDn(_loc1_.id) == null ? 0 : 1;
               _loc7_["teamNum"] = GlobalFunction.getTeamMemberNum(_loc7_["id"]);
               _loc7_["power"] = _loc1_.getPower(true);
               _loc7_["status"] = _army != null && _army.hasOwnProperty(_loc5_);
               _loc7_["choice"] = true;
               _loc2_.push(_loc7_);
               if(_loc7_["status"])
               {
                  mSelectAvatarArr.push(_loc7_);
               }
               _loc1_.clear();
               _loc1_ = null;
            }
         }
         _loc2_.sortOn(["power","star","lv","id"],[0x10 | 2,0x10 | 2,0x10 | 2,1]);
         this.setListTimer(mList,_loc2_,ItemExplorationSelect,false);
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         super.onREMOVED_FROM_STAGE(param1);
         GlobalData.$mEventDispatcher.removeEventListener("update_exploration_select_avatar",onUPDATE_AVATAR_DATA);
         _selectNum = 0;
         delList();
         if(mNum_txt)
         {
            mNum_txt.dispose();
            mNum_txt.removeFromParent(true);
         }
         if(mOk_btn)
         {
            mOk_btn.dispose();
            mOk_btn.removeFromParent(true);
         }
         mNum_txt = null;
         mOk_btn = null;
      }
   }
}

