package com.meng52.game.ui.element
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.equip.Fragment;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.renderers.IListItemRenderer;
   import flash.utils.Timer;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.Event;
   import starling.text.TextField;
   
   public class ItemFragment extends ItemBase implements IListItemRenderer
   {
      
      public var mFragment:Fragment;
      
      public var mEquipUI:LOL_Button;
      
      private var mTxt_name:TextField;
      
      private var mTxt_num:TextField;
      
      private var mTxt_numS:TextField;
      
      private var mBtn:LOL_Scale9Button;
      
      private var mTag_a:Sprite;
      
      private var mStatus_full:Boolean;
      
      private var mBg_quad:Quad;
      
      private var mTxt_fTimer:TextField;
      
      private var _width:Number = 155;
      
      private var _height:Number = 155;
      
      private var _str:String;
      
      public function ItemFragment()
      {
         super();
      }
      
      override public function layoutWH() : void
      {
         this.width = _width;
         this.height = _height;
      }
      
      override public function init(param1:Object) : void
      {
         var _loc7_:Number = NaN;
         _loc7_ = 45;
         mFragment = new Fragment(param1["id"]);
         mEquipUI = GlobalFunction.createButton_5("",mFragment.equipData.res + "0000");
         mEquipUI.y = 0;
         mEquipUI.addEventListener("triggered",onTRIGGERED_info);
         addChild(mEquipUI);
         var _loc6_:Timer = new Timer(1000,0);
         mTxt_name = GlobalTextStyle.getTextField(mFragment.equipData.name,20,16777215,"center",130,35);
         if(MainConfig.$isEnglish == true)
         {
            mTxt_name.x = 45 - 58;
         }
         else
         {
            mTxt_name.x = 45 - 64;
         }
         mTxt_name.y = mEquipUI.y + 90 + 2;
         addChild(mTxt_name);
         this.mTag_a = GlobalFunction.getTagPopTip(GlobalFunction.getFragmentNumType(param1["data_base"]));
         this.mTag_a.x = mEquipUI.x + mEquipUI.width - mTag_a.width / 2;
         this.mTag_a.y = mEquipUI.y - 10;
         addChild(this.mTag_a);
         if(!param1["data_base"])
         {
            return;
         }
         mStatus_full = GlobalFunction.checkFragmentIsFull(param1["data_base"]);
         var _loc3_:String = mStatus_full ? "UI_btn_normalFun_0000" : "UI_btn_normalFun_0000";
         var _loc5_:String = mStatus_full ? GlobalLanguageStr.getLanguageStr(20432) : GlobalLanguageStr.getLanguageStr(20433);
         mBtn = new LOL_Scale9Button(_loc5_,105,70,"UI_btn_normalFun_0000");
         mBtn.fontSize = 20;
         if(mStatus_full)
         {
            mBtn.showGlow();
         }
         else
         {
            mBtn.clearGlow();
         }
         mBtn.x = int(45 - mBtn.width * 0.5);
         mBtn.y = int(mTxt_name.y + 29);
         mBtn.addEventListener("triggered",onTRIGGERED_btn);
         addChild(mBtn);
         mBg_quad = Tools.newQuad(mEquipUI.width,29,0,0,1118481);
         mBg_quad.alpha = 0.5;
         mBg_quad.x = mEquipUI.x;
         mBg_quad.y = mEquipUI.y + mEquipUI.height - 29;
         var _loc2_:int = int(String(param1["id"]).split("_")[2]);
         var _loc4_:String = GlobalFunction.getFragmentNumType(param1["data_base"]) + "/" + _loc2_;
         mTxt_num = GlobalTextStyle.getTextField(_loc4_,20,16777215,"right",80,29);
         mTxt_numS = GlobalTextStyle.getTextField(_loc4_,20,1118481,"right",80,29);
         mTxt_num.x = mEquipUI.x;
         mTxt_num.y = mEquipUI.y + mEquipUI.height - 29;
         mBg_quad.touchable = mTxt_num.touchable = mTxt_numS.touchable = false;
         mTxt_numS.x = mTxt_num.x + 2;
         mTxt_numS.y = mTxt_num.y + 2;
         addChild(mBg_quad);
         addChild(mTxt_numS);
         addChild(mTxt_num);
      }
      
      private function onTRIGGERED_btn(param1:Event) : void
      {
         var _loc3_:int = 0;
         var _loc2_:Array = null;
         var _loc4_:Object = null;
         if(mStatus_full)
         {
            _loc3_ = Tools.getElementNum(GlobalData.$userData.my_equips);
            if(_loc3_ >= GlobalData.$mConfig_simple.equip_config[0])
            {
               GlobalFunction.popEquipFull();
               return;
            }
            SendServiceAMFFun.send_user_compose_fragment(reService,{"eid":data["id"]});
         }
         else
         {
            _loc2_ = GlobalData.$mConfig_simple.capacity_config as Array;
            _loc4_ = GlobalFunction.getFragmentPower();
            if(_loc4_.energy >= _loc2_[3])
            {
               _loc3_ = Tools.getElementNum(GlobalData.$userData.my_equips);
               GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
               if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
               {
                  GlobalFunction.popAvatarLen();
                  return;
               }
               if(_loc3_ >= GlobalData.$mConfig_simple.equip_config[0])
               {
                  GlobalFunction.popEquipFull();
                  return;
               }
               GlobalData.$fragment_data = data;
               GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_fragment",false,true);
            }
            else
            {
               GlobalFunction.sevice_pvp_buy(GlobalLanguageStr.getLanguageStr(20098));
            }
         }
      }
      
      private function onTRIGGERED_info(param1:Event) : void
      {
         GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_pvp_chip_info",false,true,data);
      }
      
      private function reService(param1:Object) : void
      {
         var _loc7_:Object = null;
         SoundManager.getOnlyExample().playSound("drop");
         var _loc6_:Object = param1.data;
         var _loc8_:Object = param1["params"];
         var _loc5_:Object = _loc6_.fragment;
         var _loc3_:Object = _loc6_.get_equips;
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            for(_loc7_ in _loc5_)
            {
               GlobalData.$userData.fragment["equips"][_loc7_] = _loc5_[_loc7_];
            }
            for(_loc7_ in _loc3_)
            {
               GlobalData.$userData.my_equips[_loc7_] = _loc3_[_loc7_];
            }
         }
         var _loc4_:Object = {};
         _loc4_[_loc8_["eid"]] = 1;
         var _loc2_:Object = GlobalFunction.getAwardByType("equip",_loc4_);
         GlobalFunction.popAward("equip",GlobalLanguageStr.getLanguageStr(90062,_loc2_.msg),_loc4_,false);
         GlobalData.$mEventDispatcher.dispatchEventWith("update_fragment_list");
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(mTxt_num)
         {
            mTxt_num.removeFromParent(true);
         }
         if(mTxt_numS)
         {
            mTxt_numS.removeFromParent(true);
         }
         if(mTag_a)
         {
            StarlingTools.removeChildrenClear(mTag_a);
            mTag_a.removeFromParent(true);
         }
         if(mEquipUI)
         {
            mEquipUI.removeFromParent(true);
         }
         if(mTxt_name)
         {
            mTxt_name.removeFromParent(true);
         }
         if(mBtn)
         {
            mBtn.removeFromParent(true);
         }
         if(mFragment)
         {
            mFragment.clear();
         }
         clear();
         mTag_a = null;
         mFragment = null;
         mEquipUI = null;
         mTxt_name = null;
         mBtn = null;
         mTxt_num = null;
         mTxt_numS = null;
      }
   }
}

