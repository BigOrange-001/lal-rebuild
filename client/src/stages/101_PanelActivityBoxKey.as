package com.meng52.game.ui.panel
{
   import com.meng52.display.TextFieldHtmlRenderer;
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.module.map.GameMapTools;
   import com.meng52.game.ui.element.ItemBoxKeySea;
   import com.meng52.game.ui.element.LOL_IconText;
   import com.meng52.game.ui.element.LOL_Scale9Button;
   import com.meng52.game.ui.element.LOL_ScrollText;
   import com.meng52.game.ui.element.LOL_TextField;
   import com.meng52.game.ui.screen.PanelBase;
   import com.meng52.net.SendAndSelect;
   import com.meng52.net.SendServiceAMFFun;
   import com.meng52.sound.SoundManager;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.display.Scale3Image;
   import feathers.display.Scale9Image;
   import feathers.textures.Scale3Textures;
   import feathers.textures.Scale9Textures;
   import flash.geom.Rectangle;
   import starling.animation.Juggler;
   import starling.display.DisplayObject;
   import starling.display.Image;
   import starling.display.MovieClip;
   import starling.display.Quad;
   import starling.display.Sprite;
   import starling.events.EnterFrameEvent;
   import starling.events.Event;
   import starling.text.TextField;
   import starling.textures.Texture;
   import starling.utils.deg2rad;
   
   public class PanelActivityBoxKey extends PanelBase
   {
      private var mReceiptBoxKeyBefore:int;

      
      public static const TYPE_BOX:String = "box";
      
      public static const TYPE_KEY:String = "key";
      
      private var mBg_quad:Quad;
      
      private var mBox_clip:Sprite;
      
      private var mClip_sea_A:ItemBoxKeySea;
      
      private var mClip_sea_B:ItemBoxKeySea;
      
      private var mClip_sea_C:ItemBoxKeySea;
      
      private var mClip_sea_D:ItemBoxKeySea;
      
      private var mMC_boat:MovieClip;
      
      private var mClip_boxOpen:MovieClip;
      
      private var mJuggler_clip:Juggler;
      
      private var mTimer_boat:Number = 0;
      
      private var mY_boat:Number = 0;
      
      private var m9x9_bg:Scale9Image;
      
      private var mTxt_info:TextFieldHtmlRenderer;
      
      private var mBtn_get:LOL_Scale9Button;
      
      private var mBtn_open:LOL_Scale9Button;
      
      private var mImg_box:Image;
      
      private var mImg_key:Image;
      
      private var mWhat:Object;
      
      private var mTag_box:Sprite;
      
      private var mTag_key:Sprite;
      
      private var mTxt_tagBox:TextField;
      
      private var mTxt_tagKey:TextField;
      
      private var mTxt_box:TextField;
      
      private var mTxt_key:TextField;
      
      private var mGiftData:Object;
      
      private var mBtn_exchange:LOL_Scale9Button;
      
      private var mBox_exchange:Sprite;
      
      private var mBtn_exchange_bk:LOL_Scale9Button;
      
      private var mBtn_exchange_kb:LOL_Scale9Button;
      
      private var mBtn_exchange_close:LOL_Scale9Button;
      
      private var mAvatarIcon:Image;
      
      private var _txt1:TextField;
      
      private var _txt2:TextField;
      
      private var _bg:Image;
      
      private var _scrollText:LOL_ScrollText;
      
      private var mNum:Number;
      
      public function PanelActivityBoxKey()
      {
         super();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         removeEventListener("enterFrame",onENTER_FRAME_clip);
         if(mTxt_tagBox)
         {
            mTxt_tagBox.removeFromParent(true);
         }
         if(mTxt_tagKey)
         {
            mTxt_tagKey.removeFromParent(true);
         }
         if(m9x9_bg)
         {
            m9x9_bg.removeFromParent(true);
            m9x9_bg.dispose();
         }
         if(mTxt_info)
         {
            mTxt_info.removeFromParent(true);
            mTxt_info.dispose();
         }
         if(mBtn_open)
         {
            mBtn_open.removeFromParent(true);
         }
         if(mBtn_get)
         {
            mBtn_get.removeFromParent(true);
         }
         if(mBtn_exchange)
         {
            mBtn_exchange.removeFromParent(true);
         }
         if(mImg_box)
         {
            mImg_box.removeFromParent(true);
         }
         if(mImg_key)
         {
            mImg_key.removeFromParent(true);
         }
         if(mClip_sea_A)
         {
            mClip_sea_A.removeFromParent(true);
         }
         if(mClip_sea_B)
         {
            mClip_sea_B.removeFromParent(true);
         }
         if(mClip_sea_C)
         {
            mClip_sea_C.removeFromParent(true);
         }
         if(mClip_sea_D)
         {
            mClip_sea_D.removeFromParent(true);
         }
         if(mClip_boxOpen)
         {
            mClip_boxOpen.removeFromParent(true);
            mClip_boxOpen.dispose();
         }
         if(mJuggler_clip)
         {
            mJuggler_clip.remove(mMC_boat);
            mJuggler_clip.remove(mClip_boxOpen);
            mJuggler_clip.purge();
         }
         if(mMC_boat)
         {
            mMC_boat.removeFromParent(true);
            mMC_boat.dispose();
         }
         if(mBg_quad)
         {
            mBg_quad.removeFromParent(true);
         }
         if(mBox_clip)
         {
            StarlingTools.removeChildrenClear(mBox_clip);
            mBox_clip.removeFromParent(true);
         }
         delExChangeUIs();
         clear();
         dispose();
         mTxt_info = null;
         m9x9_bg = null;
         mBox_clip = null;
         mBg_quad = null;
         mMC_boat = null;
         mJuggler_clip = null;
         mClip_sea_A = null;
         mClip_sea_B = null;
         mClip_sea_C = null;
         mClip_sea_D = null;
         mBtn_open = null;
         mBtn_get = null;
         mTag_box = null;
         mTag_key = null;
         mImg_box = null;
         mImg_key = null;
         mTxt_tagBox = null;
         mTxt_tagKey = null;
         mBtn_exchange = null;
         mBox_exchange = null;
         GlobalFunction.delTextureByBD("UI_box_key_sea_");
         var _loc3_:int = 0;
         var _loc2_:int = 4;
         _loc3_ = 0;
         while(_loc3_ < _loc2_)
         {
            GlobalFunction.delTextureByBD("UI_box_key_boat_000" + (_loc3_ + 1));
            _loc3_++;
         }
         _loc3_ = 0;
         _loc2_ = 10;
         GlobalFunction.delTextureByBD("png_boxKey_bg_0");
         _loc3_ = 0;
         while(_loc3_ < _loc2_)
         {
            GlobalFunction.delTextureByBD("UI_box_key_clipBoxOpen_" + (_loc3_ + 1));
            _loc3_++;
         }
      }
      
      override protected function initializeHandler(param1:Event) : void
      {
         removeEventListener("addedToStage",initializeHandler);
         setUIs();
         SendServiceAMFFun.send_user_box_gift_record(box_Gift_Record,null);
      }
      
      private function box_Gift_Record(param1:Object) : void
      {
         var _loc5_:int = 0;
         var _loc4_:Array = [];
         var _loc2_:Array = param1.data.box_record as Array;
         _loc5_ = 0;
         while(_loc5_ < _loc2_.length)
         {
            for(var _loc3_:String in _loc2_[_loc5_].gift)
            {
               _loc4_.push(GlobalLanguageStr.getLanguageStr(90531,_loc2_[_loc5_].name,GlobalFunction.getAwardByType(_loc3_,_loc2_[_loc5_].gift[_loc3_]).msg));
            }
            _loc5_++;
         }
         if(!_scrollText)
         {
            _scrollText = new LOL_ScrollText(_loc4_,500,25,5,16777215,15);
            _scrollText.x = 20;
            _scrollText.y = 150;
            addChild(_scrollText);
         }
         else
         {
            _scrollText.data = _loc4_;
         }
      }
      
      private function setUIs() : void
      {
         var _tSea:Texture;
         var _recSea:Rectangle;
         var _textures:Vector.<Texture>;
         var i:int;
         var l:int;
         var _cfg:Object;
         var _infoData:Object;
         var _box:Array;
         var _key:Array;
         var _mColorArr:Array;
         var _arr:Array;
         var _btnStr:String;
         var _status:Object;
         mBg_quad = Tools.newQuad(GlobalData.$mStageWidth,GlobalData.$center_height_curr - 121,0,0,1891052);
         mBg_quad.touchable = false;
         mBg_quad.blendMode = "none";
         _bg = GlobalFunction.createImage("png_boxKey_bg_0",true);
         _bg.y = 0;
         addChild(_bg);
         _tSea = GlobalFunction.getTextureByBD("UI_box_key_sea_");
         _recSea = _tSea.frame;
         _textures = new Vector.<Texture>();
         i = 0;
         l = 4;
         i = 0;
         while(i < l)
         {
            _textures[i] = GlobalFunction.getTextureByBD("UI_box_key_boat_000" + (i + 1));
            i = i + 1;
         }
         mMC_boat = new MovieClip(_textures,30);
         mMC_boat.loop = true;
         mMC_boat.play();
         mJuggler_clip = new Juggler();
         mJuggler_clip.add(mMC_boat);
         _textures = null;
         mBox_clip = new Sprite();
         addChild(mBox_clip);
         mClip_sea_A = new ItemBoxKeySea(1.44,1.28,2);
         mClip_sea_A.x = 0;
         mClip_sea_A.y = (GlobalData.$center_height_curr - 121) * 2 / 3;
         mClip_sea_B = new ItemBoxKeySea(0.57,0.53,3);
         mClip_sea_B.x = 0;
         mClip_sea_B.y = mClip_sea_A.y;
         mClip_sea_C = new ItemBoxKeySea(0.44,0.37,4);
         mClip_sea_C.x = 0;
         mClip_sea_C.y = mClip_sea_B.y - 10;
         mClip_sea_D = new ItemBoxKeySea(0.3,0.25,4);
         mClip_sea_D.x = 0;
         mClip_sea_D.y = mClip_sea_C.y - 10;
         mBox_clip.addChild(mClip_sea_D);
         mBox_clip.addChild(mClip_sea_C);
         mMC_boat.x = GlobalData.$mStageWidth * 0.5 - (MainConfig.$idCenter_DN ? 150 : 100);
         mMC_boat.y = mY_boat = mClip_sea_C.y - 200;
         mBox_clip.addChild(mMC_boat);
         mBox_clip.addChild(mClip_sea_B);
         mBox_clip.addChild(mClip_sea_A);
         addEventListener("enterFrame",onENTER_FRAME_clip);
         m9x9_bg = GlobalFunction.createScale9Image("UI_bg_9slice_5_0000",616,120,new Rectangle(30,20,50,30));
         m9x9_bg.x = int((GlobalData.$mStageWidth - m9x9_bg.width) * 0.5);
         m9x9_bg.y = GlobalData.$center_height_curr - 121 - m9x9_bg.height;
         addChild(m9x9_bg);
         _cfg = GlobalData.$mConfig_ploy_system_simple.box_key.time;
         _infoData = checkTimeInfo(_cfg);
         _box = _infoData["box"];
         _key = _infoData["key"];
         _mColorArr = [16777215,16764006,16764006,16764006];
         _arr = [Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20438,_box[0],_box[1],_box[2],_box[3]),_mColorArr,1000,MainConfig.$isEnglish ? 15 : 20,false,"center"),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20439,_key[0],_key[1],_key[2],_key[3]),_mColorArr,1000,MainConfig.$isEnglish ? 15 : 20,false,"center"),Tools.formatLineX(GlobalLanguageStr.getLanguageStr(20440),_mColorArr,1000,MainConfig.$isEnglish ? 15 : 20,false,"center")];
         mTxt_info = GlobalTextStyle.getHtmlTextRenderer();
         mTxt_info.text = Tools.formatHtmlTextBr(_arr,"center");
         mTxt_info.mLayoutFun = function():void
         {
            var _loc1_:Rectangle = mTxt_info.getTextSnapshotFrame();
            mTxt_info.x = m9x9_bg.x + int((m9x9_bg.width - _loc1_.width) * 0.5);
            mTxt_info.y = m9x9_bg.y + int((m9x9_bg.height - _loc1_.height) * 0.5);
         };
         addChild(mTxt_info);
         mWhat = checkTime(_cfg);
         _btnStr = GlobalLanguageStr.getLanguageStr(20441);
         if(mWhat)
         {
            if(mWhat["id"] == "key")
            {
               _btnStr = GlobalLanguageStr.getLanguageStr(20442);
            }
         }
         mBtn_get = new LOL_Scale9Button(_btnStr,150,70,"UI_btn_normalFun_0000");
         mBtn_get.name = mWhat != null ? mWhat["id"] : "";
         mBtn_get.fontSize = 25;
         mBtn_get.shadowFilter();
         mBtn_get.x = GlobalData.$mStageWidth - mBtn_get.width - 15;
         mBtn_get.y = m9x9_bg.y - mBtn_get.height - 15;
         mBtn_get.addEventListener("triggered",onTRIGGERED_get);
         mBtn_exchange = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20457),150,70,"UI_btn_normalFun_0000");
         mBtn_exchange.shadowFilter();
         mBtn_exchange.x = mBtn_get.x;
         mBtn_exchange.y = mBtn_get.y;
         mBtn_exchange.addEventListener("triggered",onTRIGGERED_exchange);
         mImg_box = GlobalFunction.createImage("UI_box_key_box_0000");
         mImg_box.pivotX = mImg_box.width * 0.5;
         mImg_box.pivotY = mImg_box.height * 0.5;
         mImg_box.scaleX = mImg_box.scaleY = 0.3;
         mImg_key = GlobalFunction.createImage("UI_box_key_key_0000");
         mImg_key.pivotX = mImg_key.width * 0.5;
         mImg_key.pivotY = mImg_key.height * 0.5;
         addChild(mImg_box);
         addChild(mImg_key);
         mImg_box.x = m9x9_bg.x + mImg_box.width * 0.5 + 10;
         mImg_box.y = m9x9_bg.y - mImg_box.height * 0.5;
         mImg_key.x = m9x9_bg.x + mImg_key.width * 0.5 + 100;
         mImg_key.y = mImg_box.y;
         mBtn_open = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20443),150,70,"UI_btn_normalFun_0000");
         mBtn_open.fontSize = MainConfig.$isEnglish ? 17 : 25;
         mBtn_open.fontColor = 1513239;
         mBtn_open.shadowFilter();
         mBtn_open.x = mBtn_get.x;
         mBtn_open.y = mBtn_get.y;
         mBtn_open.addEventListener("triggered",onTRIGGERED_open);
         addChild(mBtn_exchange);
         addChild(mBtn_open);
         addChild(mBtn_get);
         _status = checkBtnGetStatus();
         mBtn_get.enabled = _status.isCan;
         mBtn_get.visible = _status.isCan;
         if(_status.isCan)
         {
            mBtn_get.showGlow();
         }
         else
         {
            mBtn_get.clearGlow();
         }
         mBtn_open.enabled = _status.isOpen;
         mBtn_open.visible = _status.isOpen;
         mTxt_tagBox = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20193) + _status.box,20,16777215,"left",120,46);
         mTxt_tagKey = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20193) + _status.key,20,16777215,"left",120,46);
         mTxt_tagBox.x = int(mImg_box.x + mImg_box.width * 0.5);
         mTxt_tagBox.y = mImg_box.y - 15;
         addChild(mTxt_tagBox);
         mTxt_tagKey.x = int(mImg_key.x + mImg_key.width * 0.5);
         mTxt_tagKey.y = mImg_key.y - 15;
         addChild(mTxt_tagKey);
      }
      
      private function onTRIGGERED_get(param1:Event) : void
      {
         var _loc2_:String = null;
         var _before:Object = null;
         var _self:* = this;
         if(mBtn_get)
         {
            if(mBtn_get.enabled)
            {
               _loc2_ = mBtn_get.name;
               _before = checkBtnGetStatus();
               mReceiptBoxKeyBefore = int(_loc2_ == "key" ? _before.key : _before.box);
               SendServiceAMFFun.send_user_get_box_key(reService_get,{"what":_loc2_});
            }
            else if(mWhat == null)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90171),false,"A_1011_3");
            }
            else
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90170),false,"A_1011_3");
            }
         }
      }
      
      private function onTRIGGERED_open(param1:Event) : void
      {
         var _loc2_:int = 0;
         if(mBtn_open)
         {
            if(mBtn_open.enabled)
            {
               GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
               _loc2_ = Tools.getElementNum(GlobalData.$userData.my_equips);
               if(GlobalData.$userData_avatarNum >= GlobalData.$userData.attrs.avatar_len)
               {
                  GlobalFunction.popAvatarLen();
                  return;
               }
               if(_loc2_ >= GlobalData.$mConfig_simple.equip_config[0])
               {
                  GlobalFunction.popEquipFull();
                  return;
               }
               SendServiceAMFFun.send_user_box_key_gift(reService_open);
            }
            else if(mClip_boxOpen && mClip_boxOpen.isComplete)
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90172),false,"A_1011_5");
            }
         }
      }
      
      private function getItClip(param1:String) : void
      {
         var _loc2_:DisplayObject = null;
         if(param1 == "box")
         {
            _loc2_ = mImg_box;
         }
         else
         {
            _loc2_ = mImg_key;
         }
         var _loc3_:Number = 0;
      }
      
      private function reService_get(param1:Object) : void
      {
         if(stage == null)
         {
            return;
         }
         var _loc2_:Object = checkBtnGetStatus();
         if(mWhat["id"] == "key")
         {
            mNum = param1.data.attr_box_key.key.num - mReceiptBoxKeyBefore;
         }
         else
         {
            mNum = param1.data.attr_box_key.box.num - mReceiptBoxKeyBefore;
         }
         SoundManager.getOnlyExample().playSound("drop");
         var _loc3_:Object = param1["params"];
         getAward_boxKey(_loc3_["what"],param1.data.attr_box_key,!GlobalFunction.isVersionedProfileReceipt(param1));
      }
      
      private function getAward_boxKey(param1:String, param2:Object, param3:Boolean = true) : void
      {
         var _loc3_:String = null;
         getItClip(param1);
         if(param3)
         {
            GlobalData.$userData.attrs.box_key = param2;
         }
         var _loc4_:Object = checkBtnGetStatus();
         mBtn_get.enabled = _loc4_.isCan;
         mBtn_get.visible = _loc4_.isCan;
         if(_loc4_.isCan)
         {
            mBtn_get.showGlow();
         }
         else
         {
            mBtn_get.clearGlow();
         }
         mBtn_open.enabled = _loc4_.isOpen;
         mBtn_open.visible = _loc4_.isOpen;
         if(mWhat)
         {
            _loc3_ = "";
            if(mWhat["id"] == "key")
            {
               _loc3_ = GlobalLanguageStr.getLanguageStr(90187) + GlobalLanguageStr.getLanguageStr(20510) + mNum;
            }
            else
            {
               _loc3_ = GlobalLanguageStr.getLanguageStr(90186) + GlobalLanguageStr.getLanguageStr(20510) + mNum;
            }
            GlobalFunction.popAward(param1,_loc3_,mNum);
         }
         mTxt_tagBox.text = GlobalLanguageStr.getLanguageStr(20193) + _loc4_.box;
         mTxt_tagKey.text = GlobalLanguageStr.getLanguageStr(20193) + _loc4_.key;
      }
      
      private function reService_open(param1:Object) : void
      {
         if(stage == null)
         {
            return;
         }
         var _loc4_:* = undefined;
         var _loc8_:int = 0;
         var _loc3_:int = 0;
         var _loc2_:Rectangle = null;
         SoundManager.getOnlyExample().playSound("doorOpen");
         SoundManager.getOnlyExample().playSound("cure");
         var _loc6_:Object = param1.data;
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.box_key = _loc6_.attr_box_key;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.coin = _loc6_.coin;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.gold = _loc6_.gold;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.medal = _loc6_.medal;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.score = _loc6_.score;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.mark = _loc6_.mark;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.sp = _loc6_.sp;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.dust = _loc6_.dust;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.dn_stone = _loc6_.dn_stone;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.exp = _loc6_.exp;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.lv = _loc6_.lv;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.fragment_energy = _loc6_.fragment_energy;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.fragment_energy_extra = _loc6_.fragment_energy_extra;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.energy_extra = _loc6_.energy_extra;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.energy = _loc6_.energy;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.avatar_soul = _loc6_.avatar_soul;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.equip_soul = _loc6_.equip_soul;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.culture_book = _loc6_.culture_book;
         }
         var _loc5_:Object = null;
         for(_loc5_ in _loc6_.get_avatars)
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.avatars[_loc5_] = _loc6_.get_avatars[_loc5_];
            }
         }
         for(_loc5_ in _loc6_.get_equips)
         {
            if(!GlobalFunction.isVersionedProfileReceipt(param1))
            {
               GlobalData.$userData.my_equips[_loc5_] = _loc6_.get_equips[_loc5_];
            }
         }
         _loc5_ = null;
         if(_loc6_.get_fragments != null)
         {
            if(_loc6_.get_fragments.fragment != null)
            {
               _loc5_ = _loc6_.get_fragments.fragment;
               for(_loc8_ in _loc5_)
               {
                  if(!GlobalFunction.isVersionedProfileReceipt(param1))
                  {
                     GlobalData.$userData.fragment["equips"][_loc8_] = _loc5_[_loc8_];
                  }
               }
            }
         }
         if(_loc6_.exp != null)
         {
            GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateExp();
         }
         mGiftData = _loc6_.gift;
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateCoin();
         GlobalData.$mGameClassObject.mLayoutUITop.mPanelTopMain.updateGold();
         GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
         var _loc7_:Object = checkBtnGetStatus();
         mBtn_get.enabled = _loc7_.isCan;
         mBtn_get.visible = _loc7_.isCan;
         if(_loc7_.isCan)
         {
            mBtn_get.showGlow();
         }
         else
         {
            mBtn_get.clearGlow();
         }
         mBtn_open.enabled = _loc7_.isOpen;
         mBtn_open.visible = _loc7_.isOpen;
         mTxt_tagBox.text = GlobalLanguageStr.getLanguageStr(20193) + _loc7_.box;
         mTxt_tagKey.text = GlobalLanguageStr.getLanguageStr(20193) + _loc7_.key;
         if(mClip_boxOpen == null)
         {
            _loc4_ = new Vector.<Texture>();
            _loc8_ = 0;
            _loc3_ = 15;
            _loc8_ = 0;
            while(_loc8_ < _loc3_)
            {
               _loc4_[_loc8_] = GlobalFunction.getTextureByBD("UI_box_key_clipBoxOpen_" + (_loc8_ + 1));
               if(_loc8_ == 0)
               {
                  _loc2_ = (_loc4_[_loc8_] as Texture).frame;
               }
               _loc8_++;
            }
            mClip_boxOpen = new MovieClip(_loc4_,15);
            mClip_boxOpen.pivotX = mImg_box.width * 0.5;
            mClip_boxOpen.pivotY = mImg_box.height * 0.5;
            mClip_boxOpen.x = (GlobalData.$mStageWidth - mClip_boxOpen.width) / 2 + 35;
            mClip_boxOpen.y = (_bg.height - mClip_boxOpen.height) / 2 - 50;
            mClip_boxOpen.loop = false;
            addChild(mClip_boxOpen);
         }
         mClip_boxOpen.visible = true;
         mJuggler_clip.add(mClip_boxOpen);
         mClip_boxOpen.play();
         mBtn_open.enabled = false;
      }
      
      private function checkBtnGetStatus() : Object
      {
         var _loc2_:Object = null;
         var _loc5_:Number = NaN;
         var _loc6_:Boolean = false;
         var _loc1_:Object = GlobalData.$userData.attrs.box_key;
         if(mBtn_get)
         {
            if(mWhat)
            {
               _loc2_ = GlobalData.$userData.attrs.box_key[mWhat["id"]];
               _loc5_ = _loc2_.last_time != null ? (_loc2_.last_time as Date).time : 0;
               if(!Tools.checkIsSameDay(_loc5_,SendAndSelect.$systemTimer_nowSecond * 1000))
               {
                  _loc6_ = true;
               }
            }
         }
         var _loc4_:Number = Number(_loc1_["box"]["num"]);
         var _loc3_:Number = Number(_loc1_["key"]["num"]);
         var _loc7_:Number = _loc3_ - _loc4_;
         var _loc8_:Boolean = false;
         if(_loc3_ > 0 && _loc4_ > 0)
         {
            _loc8_ = true;
         }
         return {
            "isCan":_loc6_,
            "box":_loc4_,
            "key":_loc3_,
            "isOpen":_loc8_
         };
      }
      
      private function checkTimeInfo(param1:Object) : Object
      {
         var _loc12_:Date = null;
         var _loc8_:Date = null;
         var _loc3_:Array = param1["box"];
         var _loc2_:Array = param1["key"];
         var _loc6_:int = 0;
         var _loc5_:int = int(_loc3_.length);
         var _loc9_:Number = SendAndSelect.$systemTimer_nowSecond * 1000;
         var _loc10_:Date = Tools.getServerNowTimeDate(_loc9_);
         _loc9_ = _loc10_.time;
         var _loc11_:Array = null;
         var _loc13_:Object = {};
         var _loc4_:* = 0;
         var _loc7_:Number = 86400000;
         _loc6_ = 0;
         while(_loc6_ < _loc5_)
         {
            _loc11_ = _loc3_[_loc6_];
            _loc4_ = _loc6_;
            if(_loc11_[0] - 1 == _loc10_.month)
            {
               _loc13_["box"] = _loc11_;
               break;
            }
            _loc6_++;
         }
         if(_loc11_)
         {
            _loc8_ = new Date(_loc10_.fullYear,_loc11_[2] - 1,_loc11_[3]);
            if(_loc9_ >= _loc8_.time + _loc7_)
            {
               _loc4_ += 1;
               _loc4_ = int(_loc4_ >= _loc3_.length ? 0 : _loc4_);
               _loc13_["box"] = _loc3_[_loc4_];
            }
         }
         _loc12_ = null;
         _loc8_ = null;
         _loc11_ = null;
         _loc4_ = 0;
         _loc5_ = int(_loc2_.length);
         _loc6_ = 0;
         while(_loc6_ < _loc5_)
         {
            _loc11_ = _loc2_[_loc6_];
            _loc4_ = _loc6_;
            if(_loc11_[0] - 1 == _loc10_.month)
            {
               _loc13_["key"] = _loc11_;
               break;
            }
            _loc6_++;
         }
         if(_loc11_)
         {
            _loc8_ = new Date(_loc10_.fullYear,_loc11_[2] - 1,_loc11_[3]);
            if(_loc9_ > _loc8_.time + _loc7_)
            {
               _loc4_ += 1;
               _loc4_ = int(_loc4_ >= _loc2_.length ? 0 : _loc4_);
               _loc13_["key"] = _loc2_[_loc4_];
            }
         }
         return _loc13_;
      }
      
      private function checkTime(param1:Object, param2:Boolean = false) : Object
      {
         var _loc14_:Date = null;
         var _loc10_:Date = null;
         var _loc4_:Array = param1["box"];
         var _loc3_:Array = param1["key"];
         var _loc9_:int = 0;
         var _loc5_:int = int(_loc4_.length);
         var _loc11_:Number = SendAndSelect.$systemTimer_nowSecond * 1000;
         var _loc12_:Date = Tools.getServerNowTimeDate(_loc11_);
         _loc11_ = _loc12_.time;
         var _loc13_:Array = null;
         var _loc7_:Object = null;
         var _loc6_:Boolean = false;
         var _loc8_:Number = 86400000;
         _loc9_ = 0;
         while(_loc9_ < _loc5_)
         {
            _loc13_ = _loc4_[_loc9_];
            _loc14_ = new Date(_loc12_.fullYear,_loc13_[0] - 1,_loc13_[1]);
            _loc10_ = new Date(_loc12_.fullYear,_loc13_[2] - 1,_loc13_[3]);
            if(_loc11_ >= _loc14_.time && _loc11_ <= _loc10_.time + _loc8_)
            {
               _loc7_ = {};
               _loc7_["id"] = "box";
               _loc7_["indexID_s"] = _loc9_;
               _loc6_ = true;
               break;
            }
            _loc9_++;
         }
         if(!_loc6_)
         {
            _loc5_ = int(_loc3_.length);
            _loc9_ = 0;
            while(_loc9_ < _loc5_)
            {
               _loc13_ = _loc3_[_loc9_];
               _loc14_ = new Date(_loc12_.fullYear,_loc13_[0] - 1,_loc13_[1]);
               _loc10_ = new Date(_loc12_.fullYear,_loc13_[2] - 1,_loc13_[3]);
               if(_loc11_ >= _loc14_.time && _loc11_ <= _loc10_.time + _loc8_)
               {
                  _loc7_ = {};
                  _loc7_["id"] = "key";
                  _loc7_["indexID_s"] = _loc9_;
                  _loc6_ = true;
                  break;
               }
               _loc9_++;
            }
         }
         return _loc7_;
      }
      
      private function onENTER_FRAME_clip(param1:EnterFrameEvent) : void
      {
         var _loc5_:Number = NaN;
         var _loc4_:Object = null;
         var _loc2_:Object = null;
         var _loc3_:Object = null;
         if(mJuggler_clip)
         {
            mJuggler_clip.advanceTime(param1.passedTime);
            if(mMC_boat)
            {
               mTimer_boat += 2;
               if(mTimer_boat >= 360)
               {
                  mTimer_boat = 0;
               }
               _loc5_ = Math.abs(Math.sin(mTimer_boat * 3.141592653589793 / 180));
               mMC_boat.y = mY_boat + _loc5_ * 10;
               mMC_boat.rotation = deg2rad(_loc5_ * 5);
            }
            if(mClip_boxOpen)
            {
               if(mClip_boxOpen.visible)
               {
                  if(mClip_boxOpen.isComplete)
                  {
                     mImg_box.visible = true;
                     mImg_box.scaleX = mImg_box.scaleY = 0.3;
                     mClip_boxOpen.stop();
                     mClip_boxOpen.visible = false;
                     mJuggler_clip.remove(mClip_boxOpen);
                     _loc4_ = mGiftData;
                     _loc2_ = null;
                     _loc3_ = null;
                     for(_loc3_ in _loc4_)
                     {
                        _loc2_ = GlobalFunction.getAwardByType(_loc3_.toString(),_loc4_[_loc3_]);
                        GlobalFunction.popAward(_loc3_.toString(),GlobalLanguageStr.getLanguageStr(90062,_loc2_.msg),_loc4_[_loc3_],false);
                     }
                     mBtn_open.enabled = true;
                     SendServiceAMFFun.send_user_box_gift_record(box_Gift_Record,null);
                  }
               }
            }
         }
         if(mClip_sea_A && mClip_sea_B && mClip_sea_C && mClip_sea_D)
         {
            mClip_sea_A.setVx(5,30,2);
            mClip_sea_B.setVx(3,5,1);
            mClip_sea_C.setVx(2,10,2);
            mClip_sea_D.setVx(1,5,1);
         }
      }
      
      private function onTRIGGERED_exchange(param1:Event) : void
      {
         setExChangeUIs();
      }
      
      private function setExChangeUIs() : void
      {
         delExChangeUIs();
         mBox_exchange = new Sprite();
         if(this.parent)
         {
            this.parent.addChild(mBox_exchange);
         }
         var _loc16_:Quad = Tools.newQuad(GlobalData.$mStageWidth,GlobalData.$center_height_curr - 121,0,0,0);
         _loc16_.alpha = 0.75;
         mBox_exchange.addChild(_loc16_);
         var _loc30_:Scale9Image = new Scale9Image(new Scale9Textures(GlobalFunction.getTexture("UI_bg_9slice_1_0000"),new Rectangle(83,94,88,100)));
         _loc30_.width = 595;
         _loc30_.height = 425;
         _loc30_.x = int((GlobalData.$mStageWidth - _loc30_.width) * 0.5);
         _loc30_.y = int((_loc16_.height - _loc30_.height) * 0.5) + 25;
         mBox_exchange.addChild(_loc30_);
         var _loc23_:Image = GlobalFunction.createImage("UI_bg_9slice_2_0000");
         var _loc24_:Image = GlobalFunction.createImage("UI_bg_9slice_2_0000");
         _loc24_.scaleX = -1;
         mBox_exchange.addChild(_loc23_);
         mBox_exchange.addChild(_loc24_);
         mImg3_title = new Scale3Image(new Scale3Textures(GlobalFunction.getTexture("UI_bg_9slice_3_0000"),90,100));
         mImg3_title.touchable = false;
         mBox_exchange.addChild(mImg3_title);
         var _loc34_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(90506),GlobalData.$mStageWidth,46);
         _loc34_.fontSize = 30;
         _loc34_.fontColor = 16764006;
         _loc34_.hAlign = "center";
         _loc34_.shadowFilter();
         _loc34_.touchable = false;
         mBox_exchange.addChild(_loc34_);
         mBtn_close = GlobalFunction.createButtonStarling("UI_btn_9slice_0000");
         mBtn_close.addEventListener("triggered",onTRIGGERED_exchangeClose);
         mBox_exchange.addChild(mBtn_close);
         var _loc5_:Rectangle = _loc34_.textBounds;
         var _loc3_:Number = _loc5_.width + 90;
         mImg3_title.width = Math.max(_loc3_,100);
         mImg3_title.x = int(_loc30_.x + (_loc30_.width - mImg3_title.width) * 0.5);
         mImg3_title.y = int(_loc30_.y + 12);
         _loc34_.y = mImg3_title.y;
         _loc23_.x = _loc30_.x + 15;
         _loc24_.x = _loc30_.x + _loc30_.width - 15;
         _loc23_.y = int(_loc30_.y + 10);
         _loc24_.y = _loc23_.y;
         mBtn_close.x = _loc30_.x + _loc30_.width - mBtn_close.width - 15;
         mBtn_close.y = _loc30_.y + 10;
         var _loc21_:Object = GlobalData.$mConfig_ploy_system_simple.box_key.exchange;
         var _loc9_:Image = GlobalFunction.createImage("UI_box_key_box_0000");
         _loc9_.scaleX = _loc9_.scaleY = 0.4;
         var _loc13_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(20193) + _loc21_["box"][0],50,35);
         _loc13_.fontSize = 25;
         _loc13_.fontColor = 16777215;
         _loc13_.hAlign = "left";
         _loc13_.shadowFilter();
         var _loc7_:Image = GlobalFunction.createImage("UI_box_key_key_0000");
         _loc7_.scaleX = _loc7_.scaleY = 1;
         var _loc14_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(20193) + _loc21_["box"][1],50,35);
         _loc14_.fontSize = 25;
         _loc14_.fontColor = 16777215;
         _loc14_.hAlign = "left";
         _loc14_.shadowFilter();
         var _loc35_:String = GlobalLanguageStr.getLanguageStr(20459);
         var _loc17_:LOL_TextField = new LOL_TextField(_loc35_,60,46);
         _loc17_.fontSize = 30;
         _loc17_.fontColor = 16763955;
         _loc17_.hAlign = "left";
         _loc17_.shadowFilter();
         mBox_exchange.addChild(_loc9_);
         mBox_exchange.addChild(_loc13_);
         mBox_exchange.addChild(_loc7_);
         mBox_exchange.addChild(_loc14_);
         mBox_exchange.addChild(_loc17_);
         var _loc12_:Number = _loc30_.x + 60;
         var _loc11_:Number = _loc30_.y + 230;
         _loc9_.x = _loc12_;
         _loc9_.y = _loc11_ - _loc9_.height;
         _loc13_.x = _loc9_.x + _loc9_.width;
         _loc13_.y = _loc11_ - 35 - 5;
         _loc5_ = _loc13_.textBounds;
         _loc17_.x = _loc13_.x + _loc5_.width + 15;
         _loc17_.y = _loc11_ - 46;
         _loc5_ = _loc17_.textBounds;
         _loc7_.x = _loc17_.x + _loc5_.width + 15;
         _loc7_.y = _loc11_ - _loc7_.height;
         _loc14_.x = _loc7_.x + _loc7_.width;
         _loc14_.y = _loc11_ - 35 - 5;
         var _loc22_:Image = GlobalFunction.createImage("UI_box_key_key_0000");
         _loc22_.scaleX = _loc22_.scaleY = 1;
         var _loc26_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(20193) + _loc21_["key"][0],50,35);
         _loc26_.fontSize = 25;
         _loc26_.fontColor = 16777215;
         _loc26_.hAlign = "left";
         _loc26_.shadowFilter();
         var _loc20_:Image = GlobalFunction.createImage("UI_box_key_box_0000");
         _loc20_.scaleX = _loc20_.scaleY = 0.4;
         var _loc27_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(20193) + _loc21_["key"][1],50,35);
         _loc27_.fontSize = 25;
         _loc27_.fontColor = 16777215;
         _loc27_.hAlign = "left";
         _loc27_.shadowFilter();
         var _loc19_:LOL_TextField = new LOL_TextField(_loc35_,60,46);
         _loc19_.fontSize = 30;
         _loc19_.fontColor = 16763955;
         _loc19_.hAlign = "left";
         _loc19_.shadowFilter();
         mBox_exchange.addChild(_loc22_);
         mBox_exchange.addChild(_loc26_);
         mBox_exchange.addChild(_loc20_);
         mBox_exchange.addChild(_loc27_);
         mBox_exchange.addChild(_loc19_);
         var _loc33_:Number = _loc12_ + 10;
         var _loc32_:Number = _loc30_.y + 310;
         _loc22_.x = _loc33_;
         _loc22_.y = _loc32_ - _loc22_.height;
         _loc26_.x = _loc22_.x + _loc22_.width;
         _loc26_.y = _loc32_ - 35 - 5;
         _loc5_ = _loc26_.textBounds;
         _loc19_.x = _loc26_.x + _loc5_.width + 15;
         _loc19_.y = _loc32_ - 46;
         _loc5_ = _loc19_.textBounds;
         _loc20_.x = _loc19_.x + _loc5_.width + 15;
         _loc20_.y = _loc32_ - _loc20_.height;
         _loc27_.x = _loc20_.x + _loc20_.width;
         _loc27_.y = _loc32_ - 35 - 5;
         var _loc28_:Number = 0;
         var _loc15_:String = GlobalLanguageStr.getLanguageStr(20458);
         var _loc6_:LOL_IconText = new LOL_IconText(GlobalLanguageStr.getLanguageStr(20458),16777215);
         _loc6_.x = _loc12_ - 30;
         _loc6_.y = _loc11_ + 127;
         _loc6_.bgWidth = _loc30_.width - 65;
         mBox_exchange.addChild(_loc6_);
         var _loc10_:Image = GlobalFunction.createImage("UI_box_key_box_0000");
         _loc10_.scaleX = _loc10_.scaleY = 0.23;
         _loc10_.x = _loc6_.x + 115;
         _loc10_.y = _loc6_.y + 5 - 13;
         mBox_exchange.addChild(_loc10_);
         var _loc1_:Image = GlobalFunction.createImage("UI_box_key_key_0000");
         _loc1_.scaleX = _loc1_.scaleY = 0.8;
         _loc1_.x = _loc10_.x + _loc1_.width * 3 - 20;
         _loc1_.y = _loc10_.y + 3;
         mBox_exchange.addChild(_loc1_);
         var _loc18_:Object = checkBtnGetStatus();
         mBtn_get.enabled = _loc18_.isCan;
         mBtn_get.visible = _loc18_.isCan;
         if(_loc18_.isCan)
         {
            mBtn_get.showGlow();
         }
         else
         {
            mBtn_get.clearGlow();
         }
         mBtn_open.enabled = _loc18_.isOpen;
         mBtn_open.visible = _loc18_.isOpen;
         _txt1 = GlobalTextStyle.getTextField(_loc18_.box,20,16777215,"left",120,35);
         _txt2 = GlobalTextStyle.getTextField(_loc18_.key,20,16777215,"left",120,35);
         _txt1.x = _loc10_.x + _loc10_.width + 5;
         _txt1.y = _loc6_.y;
         _txt2.x = _loc1_.x + _loc1_.width + 5;
         _txt2.y = _loc6_.y;
         mBox_exchange.addChild(_txt1);
         mBox_exchange.addChild(_txt2);
         var _loc2_:TextField = GlobalTextStyle.getTextField(GlobalLanguageStr.getLanguageStr(20458),20,16777215,"left",70,35);
         _loc2_.x = 35;
         _loc2_.y = _loc28_ - 35;
         mBox_exchange.addChild(_loc2_);
         _loc5_ = _loc2_.textBounds;
         var _loc25_:Image = GlobalFunction.createImage("UI_box_key_box_0000");
         _loc25_.scaleX = _loc25_.scaleY = 0.2;
         var _loc4_:Image = GlobalFunction.createImage("UI_box_key_key_0000");
         _loc4_.scaleX = _loc4_.scaleY = 0.4;
         mBox_exchange.addChild(_loc25_);
         mBox_exchange.addChild(_loc4_);
         mTxt_box = GlobalTextStyle.getTextField("" + GlobalData.$userData.attrs.box_key["box"]["num"],20,16777215,"left",60,35);
         mTxt_key = GlobalTextStyle.getTextField("" + GlobalData.$userData.attrs.box_key["key"]["num"],20,16777215,"left",60,35);
         mBox_exchange.addChild(mTxt_box);
         mBox_exchange.addChild(mTxt_key);
         _loc25_.x = _loc2_.x + _loc5_.width;
         _loc25_.y = _loc28_ - _loc25_.height;
         mTxt_box.x = _loc25_.x + _loc25_.width;
         mTxt_box.y = _loc28_ - 35;
         _loc5_ = mTxt_box.textBounds;
         _loc4_.x = mTxt_box.x + _loc5_.width + 15;
         _loc4_.y = _loc28_ - _loc4_.height;
         mTxt_key.x = _loc4_.x + _loc4_.width;
         mTxt_key.y = _loc28_ - 35;
         var _loc37_:LOL_TextField = new LOL_TextField(GlobalLanguageStr.getLanguageStr(90185),530,35 * 2);
         _loc37_.fontSize = 20;
         _loc37_.fontColor = 16777215;
         _loc37_.hAlign = "left";
         _loc37_.shadowFilter();
         mBox_exchange.addChild(_loc37_);
         _loc37_.x = _loc30_.x + 35;
         _loc37_.y = _loc30_.y + 100;
         var _loc31_:int = int(GlobalData.$userData.attrs.box_key["box"]["num"]);
         var _loc29_:int = int(GlobalData.$userData.attrs.box_key["key"]["num"]);
         var _loc36_:Object = {
            "t":GlobalLanguageStr.getLanguageStr(20460),
            "fs":25,
            "fc":16777215
         };
         mBtn_exchange_bk = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20460),150,70,"UI_btn_normalFun_0000");
         mBtn_exchange_bk.shadowFilter();
         mBtn_exchange_kb = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20460),150,70,"UI_btn_normalFun_0000");
         mBtn_exchange_kb.shadowFilter();
         mBtn_exchange_bk.addEventListener("triggered",onTRIGGERED_bk);
         mBtn_exchange_kb.addEventListener("triggered",onTRIGGERED_kb);
         if(_loc31_ < _loc21_["box"][0])
         {
            mBtn_exchange_bk.enabled = false;
         }
         else
         {
            mBtn_exchange_bk.enabled = true;
         }
         if(_loc29_ < _loc21_["key"][0])
         {
            mBtn_exchange_kb.enabled = false;
         }
         else
         {
            mBtn_exchange_kb.enabled = true;
         }
         mBox_exchange.addChild(mBtn_exchange_bk);
         mBox_exchange.addChild(mBtn_exchange_kb);
         mBtn_exchange_bk.x = _loc30_.x + _loc30_.width - mBtn_exchange_bk.width - 50;
         mBtn_exchange_bk.y = _loc11_ - mBtn_exchange_bk.height + 10;
         mBtn_exchange_kb.x = mBtn_exchange_bk.x;
         mBtn_exchange_kb.y = _loc32_ - mBtn_exchange_kb.height + 10;
         mBtn_exchange_close = new LOL_Scale9Button(GlobalLanguageStr.getLanguageStr(20121),150,70,"UI_btn_normalFun_0000");
         mBtn_exchange_close.shadowFilter();
         mBtn_exchange_close.x = int((GlobalData.$mStageWidth - mBtn_exchange_close.width) * 0.5);
         mBtn_exchange_close.y = _loc30_.y + _loc30_.height - 100;
         mBtn_exchange_close.addEventListener("triggered",onTRIGGERED_exchangeClose);
         var _loc8_:String = GlobalData.$mConfig_simple.show_id[3];
         mAvatarIcon = GameMapTools.newAvatarImgById(_loc8_);
         mAvatarIcon.x = _loc30_.width / 2;
         mAvatarIcon.y = _loc30_.y - 70;
         mBox_exchange.addChildAt(mAvatarIcon,1);
      }
      
      private function onTRIGGERED_bk(param1:Event) : void
      {
         var _loc5_:Object = checkBtnGetStatus();
         var _loc4_:int = int(GlobalData.$userData.attrs.box_key["box"]["num"]);
         var _loc3_:int = int(GlobalData.$userData.attrs.box_key["key"]["num"]);
         var _loc2_:Object = GlobalData.$mConfig_ploy_system_simple.box_key.exchange;
         if(_loc4_ >= _loc2_["box"][0])
         {
            sendService_exchange("box");
         }
         else
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90189,_loc2_["box"][0],GlobalLanguageStr.getLanguageStr(90186)));
         }
      }
      
      private function onTRIGGERED_kb(param1:Event) : void
      {
         var _loc5_:Object = checkBtnGetStatus();
         var _loc4_:int = int(GlobalData.$userData.attrs.box_key["key"]["num"]);
         var _loc3_:int = int(GlobalData.$userData.attrs.box_key["box"]["num"]);
         var _loc2_:Object = GlobalData.$mConfig_ploy_system_simple.box_key.exchange;
         if(_loc4_ >= _loc2_["key"][0])
         {
            sendService_exchange("key");
         }
         else
         {
            GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90189,_loc2_["key"][0],GlobalLanguageStr.getLanguageStr(90187)));
         }
      }
      
      private function sendService_exchange(param1:String) : void
      {
         SendServiceAMFFun.send_user_box_key_exchange(re_box_key_exchange,{"what":param1});
      }
      
      private function re_box_key_exchange(param1:Object) : void
      {
         if(stage == null)
         {
            return;
         }
         var _loc10_:Object = param1["params"];
         var _loc3_:String = _loc10_["what"];
         var _loc8_:String = GlobalLanguageStr.getLanguageStr(90186);
         var _loc7_:String = GlobalLanguageStr.getLanguageStr(90187);
         SoundManager.getOnlyExample().playSound("beMoved");
         if(!GlobalFunction.isVersionedProfileReceipt(param1))
         {
            GlobalData.$userData.attrs.box_key = param1.data.attr_box_key;
         }
         var _loc6_:int = int(GlobalData.$userData.attrs.box_key["box"]["num"]);
         var _loc4_:int = int(GlobalData.$userData.attrs.box_key["key"]["num"]);
         var _loc2_:Object = GlobalData.$mConfig_ploy_system_simple.box_key.exchange;
         if(_loc6_ < _loc2_["box"][0])
         {
            mBtn_exchange_bk.enabled = false;
         }
         else
         {
            mBtn_exchange_bk.enabled = true;
         }
         if(_loc4_ < _loc2_["key"][0])
         {
            mBtn_exchange_kb.enabled = false;
         }
         else
         {
            mBtn_exchange_kb.enabled = true;
         }
         getAward_boxKey(_loc3_,param1.data.attr_box_key,!GlobalFunction.isVersionedProfileReceipt(param1));
         var _loc5_:Object = checkBtnGetStatus();
         _txt1.text = _loc5_.box;
         _txt2.text = _loc5_.key;
         mTxt_box.text = GlobalData.$userData.attrs.box_key["box"]["num"];
         mTxt_key.text = GlobalData.$userData.attrs.box_key["key"]["num"];
         var _loc9_:String = "";
         if(_loc3_ == "box")
         {
            _loc9_ = GlobalLanguageStr.getLanguageStr(90188,_loc2_["box"][0],_loc8_,_loc2_["box"][1],_loc7_);
         }
         else
         {
            _loc9_ = GlobalLanguageStr.getLanguageStr(90188,_loc2_["key"][0],_loc7_,_loc2_["key"][1],_loc8_);
         }
         GlobalFunction.popError(_loc9_);
      }
      
      private function onTRIGGERED_exchangeClose(param1:Event) : void
      {
         delExChangeUIs();
      }
      
      private function delExChangeUIs() : void
      {
         if(mAvatarIcon)
         {
            mAvatarIcon.removeFromParent(true);
         }
         if(mBtn_exchange_close)
         {
            mBtn_exchange_close.removeFromParent(true);
         }
         if(mBtn_exchange_bk)
         {
            mBtn_exchange_bk.removeFromParent(true);
         }
         if(mBtn_exchange_kb)
         {
            mBtn_exchange_kb.removeFromParent(true);
         }
         if(mTxt_box)
         {
            mTxt_box.removeFromParent(true);
         }
         if(mTxt_key)
         {
            mTxt_key.removeFromParent(true);
         }
         if(mBox_exchange)
         {
            StarlingTools.removeChildrenClear(mBox_exchange);
            mBox_exchange.removeFromParent(true);
         }
         mBox_exchange = null;
         mTxt_box = null;
         mTxt_key = null;
         mBtn_exchange_bk = null;
         mBtn_exchange_kb = null;
         mBtn_exchange_close = null;
         mAvatarIcon = null;
      }
   }
}

