package com.meng52.net
{
   import flash.events.EventDispatcher;
   import flash.events.IEventDispatcher;
   
   public class SendServiceAMFFun extends EventDispatcher
   {
      
      public static const ID_ADMIN:String = "adminID";
      
      public static var $adminID:String = "";
      
      public static var $sessionid:String = "";
      
      public static const ACTION_0001:String = "sys.get_config";
      
      public static const ACTION_000101:String = "sys.get_token";
      
      public static const ACTION_000102:String = "sys.if_music";
      
      public static const ACTION_0002:String = "user.login";
      
      public static const ACTION_0003:String = "user.get";
      
      public static const ACTION_0004:String = "user.get_friends";
      
      public static const ACTION_0005:String = "user.full_energy";
      
      public static const ACTION_0006:String = "user.expand_avatar_len";
      
      public static const ACTION_0007:String = "user.init_user";
      
      public static const ACTION_0008:String = "user.wager_avatar";
      
      public static const ACTION_0009:String = "user.fix_team";
      
      public static const ACTION_0010:String = "user.apply_friend";
      
      public static const ACTION_0011:String = "user.add_friend";
      
      public static const ACTION_0012:String = "user.del_friend";
      
      public static const ACTION_0013:String = "user.online_user";
      
      public static const ACTION_0014:String = "user.sell_avatars";
      
      public static const ACTION_0015:String = "user.swallow_avatar";
      
      public static const ACTION_0016:String = "user.star_up";
      
      public static const ACTION_0017:String = "user.expand_friend_len";
      
      public static const ACTION_0018:String = "user.pk_combat";
      
      public static const ACTION_0019:String = "user.pk_combat_errlog";
      
      public static const ACTION_0020:String = "user.do_guide";
      
      public static const ACTION_0025:String = "user.get_avatar_store";
      
      public static const ACTION_0026:String = "user.everyday_gift";
      
      public static const ACTION_0027:String = "user.task_done";
      
      public static const ACTION_0028:String = "user.get_msg";
      
      public static const ACTION_0029:String = "user.send_msg";
      
      public static const ACTION_0030:String = "user.del_msg";
      
      public static const ACTION_0031:String = "user.unapply_friend";
      
      public static const ACTION_0032:String = "user.get_radio";
      
      public static const ACTION_0033:String = "user.send_bugle_radio";
      
      public static const ACTION_0040:String = "user.appstore_pay";
      
      public static const ACTION_0041:String = "user.get_coin";
      
      public static const ACTION_0042:String = "user.vip_gift";
      
      public static const ACTION_0043:String = "user.get_reward_by_code";
      
      public static const ACTION_0044:String = "user.register";
      
      public static const ACTION_0045:String = "user.llogin";
      
      public static const ACTION_0046:String = "user.default_register";
      
      public static const ACTION_0047:String = "user.bind";
      
      public static const ACTION_0048:String = "user.get_uname";
      
      public static const ACTION_0049:String = "user.get_pay_gift";
      
      public static const ACTION_0050:String = "user.phase_up";
      
      public static const ACTION_0051:String = "user.get_pass_battle_gift";
      
      public static const ACTION_0052:String = "user.my_extreme";
      
      public static const ACTION_0053:String = "user.extreme_signup";
      
      public static const ACTION_0054:String = "user.get_battle_users";
      
      public static const ACTION_0055:String = "user.extreme_grant";
      
      public static const ACTION_0056:String = "user.extreme_change_team";
      
      public static const ACTION_0057:String = "user.extreme_gamble";
      
      public static const ACTION_0058:String = "user.extreme_flower";
      
      public static const ACTION_0059:String = "user.extreme_get_fans";
      
      public static const ACTION_0060:String = "user.extreme_reports";
      
      public static const ACTION_0061:String = "user.extreme_gifts";
      
      public static const ACTION_0062:String = "user.local_pay_test";
      
      public static const ACTION_0063:String = "user.extreme_get_gift";
      
      public static const ACTION_0064:String = "user.task_info";
      
      public static const ACTION_0065:String = "user.dn_unlock";
      
      public static const ACTION_0066:String = "user.dn_lvup";
      
      public static const ACTION_0067:String = "user.sign_reward";
      
      public static const ACTION_0068:String = "user.full_fragment_energy";
      
      public static const ACTION_0069:String = "sys.get_user_zone";
      
      public static const ACTION_0070:String = "user.exploration_start";
      
      public static const ACTION_0071:String = "user.exploration_make_army";
      
      public static const ACTION_0072:String = "user.exploration_refresh";
      
      public static const ACTION_0073:String = "user.exploration_relive";
      
      public static const ACTION_0074:String = "user.mystery_shop_info";
      
      public static const ACTION_0075:String = "user.mystery_shop_buy";
      
      public static const ACTION_0076:String = "user.mystery_shop_refresh_by_coin";
      
      public static const ACTION_0077:String = "user.exploration_combat";
      
      public static const ACTION_0078:String = "user.exploration_opponent";
      
      public static const ACTION_0079:String = "user.exploration_get_reward";
      
      public static const ACTION_0080:String = "user.exploration_buy_mode";
      
      public static const ACTION_0081:String = "user.check_in";
      
      public static const ACTION_0082:String = "user.equip_alchemy";
      
      public static const ACTION_0083:String = "user.soul_exchange_avatar";
      
      public static const ACTION_0084:String = "user.soul_exchange_equip";
      
      public static const ACTION_0085:String = "user.groupon_buy";
      
      public static const ACTION_0086:String = "user.groupon_info";
      
      public static const ACTION_0087:String = "user.chat_zone";
      
      public static const ACTION_0088:String = "user.chat_private";
      
      public static const ACTION_0089:String = "user.chat_all_zone";
      
      public static const ACTION_0090:String = "user.chat_black_add";
      
      public static const ACTION_0091:String = "user.chat_black_remove";
      
      public static const ACTION_0092:String = "user.get_chat_info";
      
      public static const ACTION_0093:String = "user.chat_record";
      
      public static const ACTION_0094:String = "user.chat_black_info";
      
      public static const ACTION_0095:String = "user.groupon_close";
      
      public static const ACTION_0096:String = "user.exchange_key";
      
      public static const ACTION_0097:String = "user.chat_guild";
      
      public static const ACTION_0098:String = "user.guild_contribute_exchange";
      
      public static const ACTION_0099:String = "user.guild_graduate_skill_append";
      
      public static const ACTION_0100:String = "user.guild_graduate_skill_up";
      
      public static const ACTION_0101:String = "user.guild_graduate_skill_change";
      
      public static const ACTION_1000:String = "user.zfb_pay";
      
      public static const ACTION_1001:String = "user.rkky_pay";
      
      public static const ACTION_5000:String = "user.equip_dress";
      
      public static const ACTION_5001:String = "user.equip_rise";
      
      public static const ACTION_5002:String = "user.equip_wash";
      
      public static const ACTION_5003:String = "user.equip_wash_save";
      
      public static const ACTION_5004:String = "user.equip_wash_cancel";
      
      public static const ACTION_5005:String = "user.equip_sell";
      
      public static const ACTION_5006:String = "user.get_rank_list";
      
      public static const ACTION_5007:String = "user.buy_pvp_count";
      
      public static const ACTION_5008:String = "user.pk_combat_pvp";
      
      public static const ACTION_5009:String = "user.medal_exchange";
      
      public static const ACTION_5010:String = "user.change_name";
      
      public static const ACTION_5011:String = "user.get_combat_errlog";
      
      public static const ACTION_5012:String = "user.vip_gift_buy";
      
      public static const ACTION_5013:String = "user.read_msg";
      
      public static const ACTION_5014:String = "user.get_zoneboss";
      
      public static const ACTION_5015:String = "user.attack_zoneboss";
      
      public static const ACTION_5016:String = "user.reborn";
      
      public static const ACTION_5017:String = "user.super_reborn";
      
      public static const ACTION_5018:String = "user.get_gift_msg";
      
      public static const ACTION_5019:String = "user.get_newzone_ranks";
      
      public static const ACTION_5020:String = "user.sign_in";
      
      public static const ACTION_5021:String = "user.gamble";
      
      public static const ACTION_5022:String = "user.get_gamble_reports";
      
      public static const ACTION_5023:String = "user.swallow_skillbook";
      
      public static const ACTION_5024:String = "user.rank_lv";
      
      public static const ACTION_5025:String = "user.roulette";
      
      public static const ACTION_5026:String = "user.roulette_lottery";
      
      public static const ACTION_5027:String = "user.get_my_fragments";
      
      public static const ACTION_5028:String = "user.compose_fragment";
      
      public static const ACTION_5029:String = "user.get_fragment_users";
      
      public static const ACTION_5030:String = "user.pk_combat_fragment";
      
      public static const ACTION_5031:String = "user.get_box_key";
      
      public static const ACTION_5032:String = "user.box_key_gift";
      
      public static const ACTION_5033:String = "user.fund";
      
      public static const ACTION_5034:String = "user.comment_gift";
      
      public static const ACTION_5035:String = "user.change_password";
      
      public static const ACTION_5036:String = "user.enter_zoneboss";
      
      public static const ACTION_5037:String = "user.add_magic";
      
      public static const ACTION_5038:String = "user.box_key_exchange";
      
      public static const ACTION_5039:String = "user.expedition";
      
      public static const ACTION_5040:String = "user.morph";
      
      public static const ACTION_5041:String = "user.get_combat_playback";
      
      public static const ACTION_5042:String = "user.get_consume_ranks";
      
      public static const ACTION_5043:String = "user.get_spend_fixed_gift";
      
      public static const ACTION_5044:String = "user.box_gift_record";
      
      public static const ACTION_5045:String = "user.welfare_reward_info";
      
      public static const ACTION_5046:String = "user.welfare_buy_dust";
      
      public static const ACTION_5047:String = "user.welfare_get_reward";
      
      public static const ACTION_5048:String = "user.avatar_culture";
      
      public static const ACTION_5049:String = "user.avatar_culture_save";
      
      public static const ACTION_5050:String = "user.avatar_culture_cancel";
      
      public static const ACTION_5051:String = "user.get_cross_server_rank_list";
      
      public static const ACTION_5052:String = "user.set_defensive_squad";
      
      public static const ACTION_5053:String = "user.get_cross_server_pvp_info";
      
      public static const ACTION_5054:String = "user.get_lottery_activity";
      
      public static const ACTION_5055:String = "user.pk_combat_cross_server_pvp";
      
      public static const ACTION_5056:String = "user.get_activity_rank";
      
      public static const ACTION_5057:String = "user.get_activity_cd";
      
      public static const ACTION_5058:String = "user.add_association";
      
      public static const ACTION_5059:String = "user.association_is";
      
      public static const ACTION_5060:String = "user.get_association_list";
      
      public static const ACTION_5061:String = "user.join_association";
      
      public static const ACTION_5062:String = "user.apply_member";
      
      public static const ACTION_5063:String = "user.get_apply_info";
      
      public static const ACTION_5064:String = "user.find_association";
      
      public static const ACTION_5065:String = "user.modify_association";
      
      public static const ACTION_5066:String = "user.over_association";
      
      public static const ACTION_5067:String = "user.exit_association";
      
      public static const ACTION_5068:String = "user.exchange_activity_avatar";
      
      public static const ACTION_5069:String = "user.calcel_member";
      
      public static const ACTION_5070:String = "user.operator_association_war";
      
      public static const ACTION_5071:String = "user.association_rank_index";
      
      public static const ACTION_5072:String = "user.show_war_data";
      
      public static const ACTION_5074:String = "user.association_setup_content";
      
      public static const ACTION_5073:String = "user.get_fight_result";
      
      public static const ACTION_5075:String = "user.association_setup";
      
      public static const ACTION_5076:String = "user.send_association_invite_message";
      
      public static const ACTION_5077:String = "user.member_worship";
      
      public static const ACTION_5078:String = "user.guild_worship";
      
      public static const ACTION_5079:String = "user.assocication_sever_shop_info";
      
      public static const ACTION_5080:String = "user.get_association_worship_gold_info";
      
      public static const ACTION_5081:String = "user.get_association_worship_gold";
      
      public static const ACTION_5082:String = "user.assocication_guild_shop_buy";
      
      public static const ACTION_5083:String = "user.get_war_rank";
      
      public static const ACTION_5084:String = "user.assocication_sever_shop_buy";
      
      public static const ACTION_5085:String = "user.get_guild_log";
      
      public static const ACTION_5086:String = "user.get_associationboss";
      
      public static const ACTION_5087:String = "user.attack_associationboss";
      
      public static const ACTION_5088:String = "user.get_association_boss_ranks";
      
      public static const ACTION_5089:String = "user.association_reborn";
      
      public static const ACTION_5090:String = "user.buy_attack_number";
      
      public static const ACTION_5091:String = "user.get_reward_data";
      
      public static const ACTION_5092:String = "user.assocication_sever_shop_refresh";
      
      public static const ACTION_5093:String = "user.inspire_association_race";
      
      public static const ACTION_5094:String = "user.get_inspire_data";
      
      public static const ACTION_5095:String = "user.get_inspire_team";
      
      public static const ACTION_5096:String = "user.get_inspire_history";
      
      public static const ACTION_5097:String = "user.get_avatar_talent";
      
      public static const ACTION_5098:String = "user.save_talent";
      
      public static const ACTION_5099:String = "user.set_server_pvp_cd";
      
      public static const ACTION_5100:String = "user.get_cross_server_pvp_rank_info";
      
      public static const ACTION_5101:String = "user.get_server_pvp_playback";
      
      public static const ACTION_5102:String = "user.get_server_pvp_userinfo";
      
      public static const ACTION_7001:String = "user.kt_pay";
      
      public static const ACTION_7002:String = "user.tstore_pay";
      
      public static const ACTION_7003:String = "user.naver_pay";
      
      public static const ACTION_7004:String = "user.google_pay";
      
      public static var ignoreList:Array = ["user.get_radio","user.get_zoneboss","user.pk_combat_errlog"];
      
      public function SendServiceAMFFun(param1:IEventDispatcher = null)
      {
         super(param1);
      }
      
      public static function sendService(param1:String, param2:Object = null, param3:Function = null, param4:String = "") : void
      {
      }
      
      public static function send_zfb_pay(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.zfb_pay",param2,param1);
      }
      
      public static function send_rkky_pay(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.rkky_pay",param2,param1);
      }
      
      public static function send_if_music(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("sys.if_music",param2,param1);
      }
      
      public static function send_get_token(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("sys.get_token",param2,param1);
      }
      
      public static function send_get_config(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("sys.get_config",param2,param1);
      }
      
      public static function send_user_login(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.login",param2,param1);
      }
      
      public static function send_user_get(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get",param2,param1);
      }
      
      public static function send_user_get_friends(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_friends",param2,param1);
      }
      
      public static function send_user_full_energy(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.full_energy",param2,param1);
      }
      
      public static function send_user_expand_avatar_num(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.expand_avatar_len",param2,param1);
      }
      
      public static function send_user_init_user(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.init_user",param2,param1);
      }
      
      public static function send_user_wager_avatar(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.wager_avatar",param2,param1);
      }
      
      public static function send_user_fix_team(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.fix_team",param2,param1);
      }
      
      public static function send_user_apply_friend(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.apply_friend",param2,param1);
      }
      
      public static function send_user_add_friend(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.add_friend",param2,param1);
      }
      
      public static function send_user_del_friend(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.del_friend",param2,param1);
      }
      
      public static function send_user_online_user(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.online_user",param2,param1);
      }
      
      public static function send_user_sell_avatar(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.sell_avatars",param2,param1);
      }
      
      public static function send_user_swallow_avatar(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.swallow_avatar",param2,param1);
      }
      
      public static function send_user_star_up(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.star_up",param2,param1);
      }
      
      public static function send_user_expand_friend_len(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.expand_friend_len",param2,param1);
      }
      
      public static function send_user_pk_combat_main(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.pk_combat",param2,param1);
      }
      
      public static function send_user_battle_finish(param1:Function = null, param2:Object = null, param3:String = "", param4:String = "user.battle_finish") : void
      {
         SendAndSelect.sendAndSelectService(param4,param2,param1,null,param3);
      }

      public static function send_user_pk_combat_errlog(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.pk_combat_errlog",param2,param1);
      }
      
      public static function send_user_get_avatar_store(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_avatar_store",param2,param1);
      }
      
      public static function send_user_everyday_gift(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.everyday_gift",param2,param1);
      }
      
      public static function send_user_task_done(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.task_done",param2,param1);
      }
      
      public static function send_user_get_msg(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_msg",param2,param1);
      }
      
      public static function send_user_send_msg(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.send_msg",param2,param1);
      }
      
      public static function send_user_del_msg(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.del_msg",param2,param1);
      }
      
      public static function send_user_unapply_friend(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.unapply_friend",param2,param1);
      }
      
      public static function send_user_get_radio(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_radio",param2,param1);
      }
      
      public static function send_user_send_radio(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.send_bugle_radio",param2,param1);
      }
      
      public static function send_user_do_guide(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.do_guide",param2,param1);
      }
      
      public static function send_user_pay(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.appstore_pay",param2,param1);
      }
      
      public static function send_user_get_coin(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_coin",param2,param1);
      }
      
      public static function send_user_vip_gift(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.vip_gift",param2,param1);
      }
      
      public static function send_user_get_reward_by_code(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_reward_by_code",param2,param1);
      }
      
      public static function send_user_register(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.register",param2,param1);
      }
      
      public static function send_user_llogin(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.llogin",param2,param1);
      }
      
      public static function send_user_default_register(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.default_register",param2,param1);
      }
      
      public static function send_user_bind(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.bind",param2,param1);
      }
      
      public static function send_user_get_uname(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_uname",param2,param1);
      }
      
      public static function send_user_get_pay_gift(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_pay_gift",param2,param1);
      }
      
      public static function send_user_get_pass_battle_gift(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_pass_battle_gift",param2,param1);
      }
      
      public static function send_user_get_my_extreme(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.my_extreme",param2,param1);
      }
      
      public static function send_user_get_extreme_signup(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.extreme_signup",param2,param1);
      }
      
      public static function send_user_get_battle_users(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_battle_users",param2,param1);
      }
      
      public static function send_user_get_extreme_grant(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.extreme_grant",param2,param1);
      }
      
      public static function send_user_get_extreme_change_team(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.extreme_change_team",param2,param1);
      }
      
      public static function send_user_get_extreme_gamble(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.extreme_gamble",param2,param1);
      }
      
      public static function send_user_get_extreme_flower(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.extreme_flower",param2,param1);
      }
      
      public static function send_user_get_fans(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.extreme_get_fans",param2,param1);
      }
      
      public static function send_user_get_reports(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.extreme_reports",param2,param1);
      }
      
      public static function send_user_get_gifts(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.extreme_gifts",param2,param1);
      }
      
      public static function send_user_local_pay_test(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.local_pay_test",param2,param1);
      }
      
      public static function send_user_extreme_get_gift(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.extreme_get_gift",param2,param1);
      }
      
      public static function send_user_task_info(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.task_info",param2,param1);
      }
      
      public static function send_user_dn_unlock(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.dn_unlock",param2,param1);
      }
      
      public static function send_user_dn_lvup(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.dn_lvup",param2,param1);
      }
      
      public static function send_user_sign_reward(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.sign_reward",param2,param1);
      }
      
      public static function send_user_full_fragment_energy(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.full_fragment_energy",param2,param1);
      }
      
      public static function send_user_get_user_zone(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("sys.get_user_zone",param2,param1);
      }
      
      public static function send_user_exploration_start(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.exploration_start",param2,param1);
      }
      
      public static function send_user_exploration_make_army(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.exploration_make_army",param2,param1);
      }
      
      public static function send_user_exploration_refresh(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.exploration_refresh",param2,param1);
      }
      
      public static function send_user_exploration_relive(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.exploration_relive",param2,param1);
      }
      
      public static function send_user_mystery_shop_info(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.mystery_shop_info",param2,param1);
      }
      
      public static function send_user_mystery_shop_buy(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.mystery_shop_buy",param2,param1);
      }
      
      public static function send_user_mystery_shop_refresh_by_coin(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.mystery_shop_refresh_by_coin",param2,param1);
      }
      
      public static function send_user_exploration_combat(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.exploration_combat",param2,param1);
      }
      
      public static function send_user_exploration_opponent(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.exploration_opponent",param2,param1);
      }
      
      public static function send_user_exploration_get_reward(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.exploration_get_reward",param2,param1);
      }
      
      public static function send_user_exploration_buy_mode(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.exploration_buy_mode",param2,param1);
      }
      
      public static function send_user_check_in(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.check_in",param2,param1);
      }
      
      public static function send_user_equip_alchemy(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.equip_alchemy",param2,param1);
      }
      
      public static function send_user_avatar_soul(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.soul_exchange_avatar",param2,param1);
      }
      
      public static function send_user_equip_soul(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.soul_exchange_equip",param2,param1);
      }
      
      public static function send_user_groupon_buy(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.groupon_buy",param2,param1);
      }
      
      public static function send_user_groupon_info(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.groupon_info",param2,param1);
      }
      
      public static function send_user_chat_zone(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.chat_zone",param2,param1);
      }
      
      public static function send_user_chat_private(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.chat_private",param2,param1);
      }
      
      public static function send_user_chat_all_zone(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.chat_all_zone",param2,param1);
      }
      
      public static function send_user_chat_black_add(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.chat_black_add",param2,param1);
      }
      
      public static function send_user_chat_black_remove(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.chat_black_remove",param2,param1);
      }
      
      public static function send_user_get_chat_info(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_chat_info",param2,param1);
      }
      
      public static function send_user_chat_record(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.chat_record",param2,param1);
      }
      
      public static function send_user_chat_black_info(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.chat_black_info",param2,param1);
      }
      
      public static function send_user_groupon_close(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.groupon_close",param2,param1);
      }
      
      public static function send_user_exchange_key(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.exchange_key",param2,param1);
      }
      
      public static function send_user_chat_guild(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.chat_guild",param2,param1);
      }
      
      public static function send_user_guild_contribute_exchange(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.guild_contribute_exchange",param2,param1);
      }
      
      public static function send_user_guild_graduate_skill_append(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.guild_graduate_skill_append",param2,param1);
      }
      
      public static function send_user_guild_graduate_skill_up(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.guild_graduate_skill_up",param2,param1);
      }
      
      public static function send_user_guild_graduate_skill_change(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.guild_graduate_skill_change",param2,param1);
      }
      
      public static function send_user_equip_dress(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.equip_dress",param2,param1);
      }
      
      public static function send_user_equip_rise(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.equip_rise",param2,param1);
      }
      
      public static function send_user_equip_wash(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.equip_wash",param2,param1);
      }
      
      public static function send_user_equip_wash_save(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.equip_wash_save",param2,param1);
      }
      
      public static function send_user_equip_wash_cancel(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.equip_wash_cancel",param2,param1);
      }
      
      public static function send_user_equip_sell(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.equip_sell",param2,param1);
      }
      
      public static function send_user_get_rank_list(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_rank_list",param2,param1);
      }

      public static function send_user_refresh_pvp_opponents(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.refresh_pvp_opponents",param2,param1);
      }

      public static function send_user_avatar_limit_break(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.avatar_limit_break",param2,param1);
      }
      
      public static function send_user_buy_pvp_count(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.buy_pvp_count",param2,param1);
      }
      
      public static function send_user_pk_combat_pvp(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.pk_combat_pvp",param2,param1);
      }
      
      public static function send_user_medal_exchange(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.medal_exchange",param2,param1);
      }
      
      public static function send_user_change_name(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.change_name",param2,param1);
      }
      
      public static function send_user_phase_up(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.phase_up",param2,param1);
      }
      
      public static function send_user_get_combat_errlog(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_combat_errlog",param2,param1);
      }
      
      public static function send_user_vip_gift_buy(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.vip_gift_buy",param2,param1);
      }
      
      public static function send_user_read_msg(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.read_msg",param2,param1);
      }
      
      public static function send_user_get_zoneboss(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_zoneboss",param2,param1);
      }
      
      public static function send_user_enter_zoneboss(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.enter_zoneboss",param2,param1);
      }
      
      public static function send_user_attack_zoneboss(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.attack_zoneboss",param2,param1);
      }
      
      public static function send_user_reborn(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.reborn",param2,param1);
      }
      
      public static function send_user_super_reborn(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.super_reborn",param2,param1);
      }
      
      public static function send_user_get_gift_msg(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_gift_msg",param2,param1);
      }
      
      public static function send_user_get_newzone_ranks(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_newzone_ranks",param2,param1);
      }
      
      public static function send_user_sign_in(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.sign_in",param2,param1);
      }
      
      public static function send_user_gamble(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.gamble",param2,param1);
      }
      
      public static function send_user_get_gamble_reports(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_gamble_reports",param2,param1);
      }
      
      public static function send_user_swallow_skillbook(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.swallow_skillbook",param2,param1);
      }
      
      public static function send_user_rank_lv(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.rank_lv",param2,param1);
      }
      
      public static function send_user_roulette(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.roulette",param2,param1);
      }
      
      public static function send_user_roulette_lottery(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.roulette_lottery",param2,param1);
      }
      
      public static function send_user_get_my_fragments(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_my_fragments",param2,param1);
      }
      
      public static function send_user_compose_fragment(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.compose_fragment",param2,param1);
      }
      
      public static function send_user_get_fragment_uids(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_fragment_users",param2,param1);
      }
      
      public static function send_user_pk_combat_fragment(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.pk_combat_fragment",param2,param1);
      }
      
      public static function send_user_get_box_key(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_box_key",param2,param1);
      }
      
      public static function send_user_box_key_gift(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.box_key_gift",param2,param1);
      }
      
      public static function send_user_fund(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.fund",param2,param1);
      }
      
      public static function send_user_comment_gift(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.comment_gift",param2,param1);
      }
      
      public static function send_user_change_password(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.change_password",param2,param1);
      }
      
      public static function send_user_add_magic(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.add_magic",param2,param1);
      }
      
      public static function send_user_box_key_exchange(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.box_key_exchange",param2,param1);
      }
      
      public static function send_user_expedition(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.expedition",param2,param1);
      }
      
      public static function send_user_morph(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.morph",param2,param1);
      }
      
      public static function send_user_get_combat_playback(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_combat_playback",param2,param1);
      }
      
      public static function send_user_get_consume_ranks(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_consume_ranks",param2,param1);
      }
      
      public static function send_user_get_spend_fixed_gift(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_spend_fixed_gift",param2,param1);
      }
      
      public static function send_user_box_gift_record(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.box_gift_record",param2,param1);
      }
      
      public static function send_user_welfare_reward_info(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.welfare_reward_info",param2,param1);
      }
      
      public static function send_user_welfare_buy_dust(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.welfare_buy_dust",param2,param1);
      }
      
      public static function send_user_welfare_get_reward(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.welfare_get_reward",param2,param1);
      }
      
      public static function send_user_avatar_culture(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.avatar_culture",param2,param1);
      }
      
      public static function send_user_avatar_culture_save(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.avatar_culture_save",param2,param1);
      }
      
      public static function send_user_avatar_culture_cancel(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.avatar_culture_cancel",param2,param1);
      }
      
      public static function send_user_get_cross_server_rank_list(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_cross_server_rank_list",param2,param1);
      }
      
      public static function send_user_set_defensive_squad(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.set_defensive_squad",param2,param1);
      }
      
      public static function send_user_get_cross_server_pvp_info(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_cross_server_pvp_info",param2,param1);
      }
      
      public static function send_user_get_lottery_activity(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_lottery_activity",param2,param1);
      }
      
      public static function pk_combat_cross_server_pvp(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.pk_combat_cross_server_pvp",param2,param1);
      }
      
      public static function send_user_get_activity_rank(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_activity_rank",param2,param1);
      }
      
      public static function send_user_get_activity_cd(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_activity_cd",param2,param1);
      }
      
      public static function send_user_add_association(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.add_association",param2,param1);
      }
      
      public static function send_user_associatione_is(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.association_is",param2,param1);
      }
      
      public static function send_user_get_association_list(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_association_list",param2,param1);
      }
      
      public static function send_user_join_association(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.join_association",param2,param1);
      }
      
      public static function send_user_apply_member(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.apply_member",param2,param1);
      }
      
      public static function send_user_get_apply_info(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_apply_info",param2,param1);
      }
      
      public static function send_user_find_association(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.find_association",param2,param1);
      }
      
      public static function send_user_modify_association(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.modify_association",param2,param1);
      }
      
      public static function send_user_over_association(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.over_association",param2,param1);
      }
      
      public static function send_user_exit_association(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.exit_association",param2,param1);
      }
      
      public static function send_user_exchange_activity_avatar(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.exchange_activity_avatar",param2,param1);
      }
      
      public static function send_user_calcel_member(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.calcel_member",param2,param1);
      }
      
      public static function send_user_operator_association_war(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.operator_association_war",param2,param1);
      }
      
      public static function send_user_association_rank_index(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.association_rank_index",param2,param1);
      }
      
      public static function send_user_show_war_data(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.show_war_data",param2,param1);
      }
      
      public static function send_user_get_fight_result(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_fight_result",param2,param1);
      }
      
      public static function send_user_association_setup_content(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.association_setup_content",param2,param1);
      }
      
      public static function send_user_association_setup(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.association_setup",param2,param1);
      }
      
      public static function send_user_send_association_invite_message(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.send_association_invite_message",param2,param1);
      }
      
      public static function send_user_member_worship(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.member_worship",param2,param1);
      }
      
      public static function send_user_guild_worship(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.guild_worship",param2,param1);
      }
      
      public static function send_user_assocication_sever_shop_info(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.assocication_sever_shop_info",param2,param1);
      }
      
      public static function send_user_get_association_worship_gold_info(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_association_worship_gold_info",param2,param1);
      }
      
      public static function send_user_get_association_worship_gold(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_association_worship_gold",param2,param1);
      }
      
      public static function send_user_assocication_guild_shop_buy(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.assocication_guild_shop_buy",param2,param1);
      }
      
      public static function send_user_get_war_rank(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_war_rank",param2,param1);
      }
      
      public static function send_user_assocication_sever_shop_buy(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.assocication_sever_shop_buy",param2,param1);
      }
      
      public static function send_user_get_guild_log(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_guild_log",param2,param1);
      }
      
      public static function send_user_get_associationboss(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_associationboss",param2,param1);
      }
      
      public static function send_user_attack_associationboss(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.attack_associationboss",param2,param1);
      }
      
      public static function send_user_get_association_boss_ranks(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_association_boss_ranks",param2,param1);
      }
      
      public static function send_user_association_reborn(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.association_reborn",param2,param1);
      }
      
      public static function send_user_buy_attack_number(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.buy_attack_number",param2,param1);
      }
      
      public static function send_user_get_reward_data(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_reward_data",param2,param1);
      }
      
      public static function send_user_assocication_sever_shop_refresh(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.assocication_sever_shop_refresh",param2,param1);
      }
      
      public static function send_user_inspire_association_race(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.inspire_association_race",param2,param1);
      }
      
      public static function send_user_get_inspire_data(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_inspire_data",param2,param1);
      }
      
      public static function send_user_get_inspire_team(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_inspire_team",param2,param1);
      }
      
      public static function send_user_get_inspire_history(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_inspire_history",param2,param1);
      }
      
      public static function send_user_get_avatar_talent(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_avatar_talent",param2,param1);
      }
      
      public static function send_user_save_talent(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.save_talent",param2,param1);
      }
      
      public static function send_user_set_server_pvp_cd(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.set_server_pvp_cd",param2,param1);
      }
      
      public static function send_user_get_cross_server_pvp_rank_info(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_cross_server_pvp_rank_info",param2,param1);
      }
      
      public static function send_user_get_server_pvp_playback(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_server_pvp_playback",param2,param1);
      }
      
      public static function send_user_get_server_pvp_userinfo(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.get_server_pvp_userinfo",param2,param1);
      }
      
      public static function send_user_kt_pay(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.kt_pay",param2,param1);
      }
      
      public static function send_user_tstore_pay(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.tstore_pay",param2,param1);
      }
      
      public static function send_user_naver_pay(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.naver_pay",param2,param1);
      }
      
      public static function send_user_google_pay(param1:Function = null, param2:Object = null) : void
      {
         SendAndSelect.sendAndSelectService("user.google_pay",param2,param1);
      }
   }
}

