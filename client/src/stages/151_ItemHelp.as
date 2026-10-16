package com.meng52.game.ui.element
{
   import com.meng52.game.global.GlobalData;
   import com.meng52.game.global.GlobalFunction;
   import com.meng52.game.global.GlobalLanguageStr;
   import com.meng52.game.global.GlobalLocalStore;
   import com.meng52.game.global.GlobalPFANE;
   import com.meng52.game.global.GlobalTextStyle;
   import com.meng52.game.ui.screen.PanelLogin;
   import com.meng52.global.GlobalStaticConst;
   import com.meng52.utils.StarlingTools;
   import com.meng52.utils.Tools;
   import feathers.controls.renderers.IListItemRenderer;
   import flash.net.URLRequest;
   import flash.net.navigateToURL;
   import starling.events.Event;
   
   public class ItemHelp extends ItemBase implements IListItemRenderer
   {
      
      private var mPanelLogin:PanelLogin;
      
      public function ItemHelp()
      {
         super();
      }
      
      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         if(mPanelLogin)
         {
            StarlingTools.removeChildrenClear(mPanelLogin);
            mPanelLogin.removeFromParent(true);
         }
         super.onREMOVED_FROM_STAGE(param1);
         mPanelLogin = null;
      }
      
      override public function init(param1:Object) : void
      {
         super.init(param1);
         var _loc2_:LOL_Scale9Button = new LOL_Scale9Button(getMenuTitle(param1),230,80,"UI_btn_normalFun_0000");
         addChild(_loc2_);
         this.width = _loc2_.width + 15;
         this.height = _loc2_.height;
         _loc2_.addEventListener("triggered",btn_Triggered);
      }
      
      private function getMenuTitle(item:Object) : String
      {
         var titles:Object = {"center_help_notice": "游戏公告", "center_help_avatar": "英雄帮助", "center_help_setting": "游戏设置", "center_help_help": "玩法说明", "center_help_name": "修改昵称", "center_help_quit": "返回登录", "center_help_award_code": "兑换码", "center_help_bbs": "游戏论坛", "pf_share": "分享游戏", "face_book": "游戏社区", "tw_change_login": "切换账号", "tw_system_help": "系统帮助", "pf_comment_gift_fun": "评价奖励", "meng52_sys_change_password": "修改密码", "center_help_uid_change": "账号迁移", "center_binding_user": "绑定账号", "ext_help_91_pf": "账号中心", "ext_help_91_bbs": "游戏论坛", "ext_help_91_FeedBack": "意见反馈", "ext_help_dk_accountmanager": "账号管理", "ext_help_anzhi_accountmanager": "账号管理", "ext_help_pp_accountmanager": "账号管理", "ext_help_ky_user": "账号中心"};
         if(titles[item.name] != null) return titles[item.name];
         var title:String = GlobalLanguageStr.getLanguageStr(item.title);
         return title == null || title == "" ? "系统帮助" : title;
      }

      public function btn_Triggered(param1:Event) : void
      {
         var _fun:Object;
         var _url:String;
         var _pfURL:Object;
         var toURL:*;
         var _str:String;
         var quit3:*;
         var quit:*;
         var quit2:*;
         var _helpURL:Object;
         var _helpURLstr:String;
         var _event:Event = param1;
         soundTriggered();
         if(this.data.name == "center_help_avatar")
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_help_avatar",false,true);
         }
         else if(this.data.name == "center_help_notice")
         {
            GlobalFunction.popPanelHelp(MainConfig.SERVER_ADDRESS_NOTICE);
         }
         else if(this.data.name == "center_help_help")
         {
            GlobalFunction.popPanelHelp(MainConfig.SERVER_ADDRESS_HELP_HELP);
         }
         else if(this.data.name == "center_help_bbs")
         {
            toURL = function():void
            {
               try
               {
                  navigateToURL(new URLRequest(_url),"_blank");
               }
               catch(_error:Error)
               {
               }
            };
            _url = "";
            if(GlobalData.$mConfig_client["pf_bbs_url"])
            {
               _pfURL = GlobalData.$mConfig_client.pf_bbs_url;
               if(_pfURL[GlobalLocalStore.$pf_type_curr])
               {
                  _url = _pfURL[GlobalLocalStore.$pf_type_curr];
               }
            }
            if(_url == "")
            {
               GlobalFunction.popError(GlobalLanguageStr.getLanguageStr(90046));
            }
            else
            {
               GlobalPFANE.extPF_bbs(0,toURL);
            }
         }
         else if(this.data.name == "center_help_setting")
         {
            GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_help_setting",false,true);
         }
         else if(this.data.name != "center_help_weibo_sina")
         {
            if(this.data.name == "center_help_weibo_qq")
            {
               GlobalData.$weiboType = "qq";
               GlobalFunction.setWebView("https://open.t.qq.com/cgi-bin/oauth2/authorize?response_type=token&client_id=801377918&  redirect_uri=http%3A%2F%2Fmeng52.f3322.org%2F&scope=all",GlobalFunction.webCallBack);
            }
            else if(this.data.name != "center_help_weibo_id_change")
            {
               if(this.data.name == "center_help_quit")
               {
                  quit3 = function():void
                  {
                     GlobalFunction.quitGame();
                  };
                  quit = function():void
                  {
                     if(GlobalLocalStore.$pf_type_curr == "gatios")
                     {
                        GlobalPFANE.changeLogin();
                        return;
                     }
                     GlobalPFANE.outApp();
                  };
                  quit2 = function():void
                  {
                     if(GlobalLocalStore.$pf_type_curr == "7k7k" || GlobalLocalStore.$pf_type_curr == "bfyy" || GlobalLocalStore.$pf_type_curr == "anfeng" || GlobalLocalStore.$pf_type_curr == "gameBaby" || GlobalLocalStore.$pf_type_curr == "kugou" || GlobalLocalStore.$pf_type_curr == "sougou1" || GlobalLocalStore.$pf_type_curr == "sougou2" || GlobalLocalStore.$pf_type_curr == "sougou3")
                     {
                        MainConfig.classMainExtension.getInstance().rkExit();
                     }
                     GlobalFunction.quitGame();
                  };
                  GlobalData.$userGuild.guildFightGuide = false;
                  _fun = {
                     "ok":GlobalFunction.quitGame,
                     "okUI":GlobalLanguageStr.getLanguageStr(20249),
                     "no":GlobalPFANE.extPF_quit,
                     "noUI":GlobalLanguageStr.getLanguageStr(20250),
                     "closeA":true
                  };
                  if(GlobalStaticConst.$isIOS)
                  {
                     _str = GlobalLanguageStr.getLanguageStr(90072);
                     _fun = {
                        "ok":quit,
                        "okUI":GlobalLanguageStr.getLanguageStr(20249),
                        "no":GlobalFunction.functionNull,
                        "noUI":GlobalLanguageStr.getLanguageStr(20251),
                        "closeA":true
                     };
                  }
                  else if(GlobalStaticConst.$isAndroid)
                  {
                     _fun = {
                        "ok":quit2,
                        "okUI":GlobalLanguageStr.getLanguageStr(20249),
                        "no":GlobalFunction.functionNull,
                        "noUI":GlobalLanguageStr.getLanguageStr(20251),
                        "closeA":true
                     };
                     if(GlobalLocalStore.$pf_type_curr == "dnyad")
                     {
                        _fun = {
                           "ok":GlobalFunction.functionNull,
                           "okUI":GlobalLanguageStr.getLanguageStr(20251),
                           "no":quit3,
                           "noUI":GlobalLanguageStr.getLanguageStr(20249),
                           "closeA":true
                        };
                     }
                  }
                  GlobalFunction.popAlert("",Tools.formatLineX(GlobalLanguageStr.getLanguageStr(90045),GlobalTextStyle.COLOR_W_Y_Y_G),_fun);
               }
               else if(this.data.name == "center_help_award_code")
               {
                  GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_help_award_code",false,true);
               }
               else if(this.data.name == "center_help_weibo_meng52")
               {
                  GlobalPFANE.getOtherSysHelp();
               }
               else if(this.data.name == "ext_help_ky_user")
               {
                  GlobalPFANE.extPF_bbs(66);
               }
               else if(this.data.name == "ext_help_91_pf")
               {
                  GlobalPFANE.extPF_bbs(2);
               }
               else if(this.data.name == "ext_help_91_bbs")
               {
                  GlobalPFANE.extPF_bbs(0);
               }
               else if(this.data.name == "ext_help_91_FeedBack")
               {
                  GlobalPFANE.extPF_bbs(3);
               }
               else if(this.data.name == "ext_help_dk_accountmanager")
               {
                  GlobalPFANE.extPF_bbs(4);
               }
               else if(this.data.name == "ext_help_anzhi_accountmanager")
               {
                  GlobalPFANE.extPF_bbs(44);
               }
               else if(this.data.name == "ext_help_pp_accountmanager")
               {
                  GlobalPFANE.extPF_bbs(55);
               }
               else if(this.data.name == "center_help_name")
               {
                  GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_help_name",false,true);
               }
               else if(this.data.name == "pf_comment_gift_fun")
               {
                  GlobalFunction.popAppleComment();
               }
               else if(this.data.name == "ext_help_360_settings")
               {
                  GlobalPFANE.extStatus(null);
               }
               else if(this.data.name == "meng52_sys_change_password")
               {
                  if(mPanelLogin)
                  {
                     removeChild(mPanelLogin);
                  }
                  mPanelLogin = null;
                  mPanelLogin = new PanelLogin(99);
                  mPanelLogin.mPop_currID = GlobalData.$mGameClassObject.mLayoutUICenter.addPop(mPanelLogin,0);
               }
               else if(this.data.name == "center_binding_user")
               {
                  if(mPanelLogin)
                  {
                     removeChild(mPanelLogin);
                  }
                  mPanelLogin = null;
                  mPanelLogin = new PanelLogin(98);
                  mPanelLogin.mPop_currID = GlobalData.$mGameClassObject.mLayoutUICenter.addPop(mPanelLogin,0);
               }
               else if(this.data.name == "tw_change_login")
               {
                  GlobalPFANE.changeLogin();
               }
               else if(this.data.name == "tw_system_help")
               {
                  GlobalPFANE.getOtherSysHelp();
               }
               else if(this.data.name == "center_help_uid_change")
               {
                  GlobalPFANE.getOtherSysHelp(2);
               }
               else if(this.data.name == "pf_share")
               {
                  GlobalPFANE.pfShare();
               }
               else if(this.data.name == "face_book")
               {
                  GlobalPFANE.faceBook();
               }
               else if(this.data.name == "center_help_raiders")
               {
                  _helpURL = GlobalData.$mConfig_client.help_url;
                  if(_helpURL)
                  {
                     try
                     {
                        _helpURLstr = _helpURL[GlobalLocalStore.$pf_type_curr];
                        navigateToURL(new URLRequest(_helpURLstr),"_blank");
                     }
                     catch(_error:Error)
                     {
                     }
                  }
               }
               else if(this.data.name == "center_binding_user")
               {
                  GlobalData.$mGameClassObject.mLayoutUICenter.showPanel("center_binding_user",false,true);
               }
            }
         }
      }
   }
}

