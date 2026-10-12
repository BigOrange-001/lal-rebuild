package com.meng52.game.ui.panel
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.equip.Equip;
   import com.meng52.game.ui.element.ItemPVPFragment;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.screen.PanelCenterPVE;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.utils.Tools;
   import starling.display.Image;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class PanelPVPFragment extends PanelCenterPVE
   {
      
      private var mBg_list:Image;
      
      private var mTxt_name:TextField;
      
      private var mEquipUI:Image;
      
      private var mBtn_re:LOL_Scale9Button;
      
      private var mReTimer:Number = 0;
      
      private var mData_list:Array;
      
      private var mTxt_name_2:String;
      
      private var mTxt_power:TextField;
      
      private var mTxt_currentPower:TextFieldHtmlRenderer;
      
      public function PanelPVPFragment()
      {
         super();
      }
      
      public static function checkIsRobot(param1:String) : Boolean
      {
         return param1.indexOf("b_") > -1;
      }
      
      public static function getRandomNull(param1:Array) : int
      {
         var _loc5_:int = 0;
         var _loc3_:int = int(param1.length);
         var _loc2_:int = -1;
         var _loc4_:Array = [];
         _loc5_ = 0;
         while(_loc5_ < _loc3_)
         {
            if(param1[_loc5_] <= 0)
            {
               _loc4_.push(_loc5_);
            }
            _loc5_++;
         }
         _loc4_ = Tools.randomArray(_loc4_);
         return _loc4_[0];
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         this.removeEventListener("addedToStage",initializeHandler);
         mBg_list = GlobalFunction.createImage("UI_pvp_bg_0_",true);
         mBg_list.x = int((GlobalData.$mStageWidth - mBg_list.width) * 0.5);
         mBg_list.y = 70;
         var _loc2_:* = GlobalData.$fragment_data["id"];
         var _loc4_:Equip = new Equip(GlobalData.$fragment_data["id"]);
         mTxt_name = GlobalTextStyle.getTextField(_loc4_.equipData.name + GlobalLanguageStr.getLanguageStr(20437),30,5117970,"left",250,46);
         this.setPopPanelBg(_loc4_.equipData.name + GlobalLanguageStr.getLanguageStr(20437));
         var _loc5_:Object = GlobalFunction.getFragmentPower();
         var _loc3_:Array = _loc5_.energy == 0 ? [16777215,16764006,10027008,10027008] : [16777215,16764006,16764006,10027008];
         mTxt_power = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(98125),20,16777215,"left",300,46);
         mTxt_power.x = mImg9_baseBg.x + 40 - 2;
         mTxt_power.y = mImg9_baseBg.x + mImg9_baseBg.height - 125;
         addChild(mTxt_power);
         mTxt_currentPower = GlobalTextStyle.getHtmlTextRenderer();
         mTxt_currentPower.text = Tools.formatLineX(GlobalLanguageStr.getLanguageStr(98126,_loc5_.energy,_loc5_.max),_loc3_,23,20);
         mTxt_currentPower.x = mTxt_power.x - 6;
         mTxt_currentPower.y = mTxt_power.y + 30;
         addChild(mTxt_currentPower);
         mBtn_re = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(90413),150,70,"UI_btn_normalFun_0000");
         mBtn_re.x = mImg9_baseBg.x + mImg9_baseBg.width - mBtn_re.width - 40;
         mBtn_re.y = mImg9_baseBg.y + mImg9_baseBg.height - 130;
         mBtn_re.addEventListener("triggered",onTRIGGERED_re);
         addChild(mBtn_re);
         mReTimer = 0;
         sendService();
         this.addEventListener("close_panel_self",CLOSE_PANEL_SELF);
      }
      
      private function CLOSE_PANEL_SELF(param1:Event) : void
      {
         super.onCLOSE_PANEL_SELF();
      }
      
      private function onTRIGGERED_re(param1:Event) : void
      {
         var _loc3_:Number = SendAndSelect.$systemTimer_nowSecond;
         var _loc2_:Number = _loc3_ - mReTimer;
         if(_loc2_ > 5)
         {
            mReTimer = _loc3_;
            sendService();
         }
      }
      
      override public function onBTN_NAME_BACK() : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp");
      }
      
      private function sendService() : void
      {
         SendServiceAMFFun.send_user_get_fragment_uids(reService);
      }
      
      private function reService(param1:Object) : void
      {
         mData_list = param1.data as Array;
         setList();
         addList();
         this.mList.y = 100;
      }
      
      override public function addList() : void
      {
         var _loc7_:Object = null;
         var _loc8_:int = 0;
         var _loc5_:int = int(mData_list.length);
         var _loc1_:Array = null;
         var _loc2_:String = "";
         var _loc3_:Array = [];
         var _loc4_:String = GlobalData.$fragment_data["id"];
         var _loc6_:Array = GlobalData.$fragment_data["data_base"] as Array;
         _loc8_ = 0;
         while(_loc8_ < _loc5_)
         {
            _loc1_ = mData_list[_loc8_];
            _loc7_ = {};
            _loc2_ = _loc1_[0];
            _loc7_["id"] = _loc2_;
            _loc7_["eid"] = _loc4_;
            _loc7_["name"] = _loc1_[1];
            _loc7_["lvMax"] = _loc1_[2];
            _loc7_["vip_lv"] = _loc1_[3];
            _loc7_["data_base"] = _loc1_[4];
            _loc7_["isRobot"] = checkIsRobot(_loc2_);
            _loc7_["indexID_s"] = getRandomNull(_loc6_);
            _loc7_["uid"] = _loc2_;
            _loc3_.push(_loc7_);
            _loc8_++;
         }
         mList.y = 100;
         mList.height = 510;
         this.setListTimer(mList,_loc3_,ItemPVPFragment,false);
      }
   }
}

