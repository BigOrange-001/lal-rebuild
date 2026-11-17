"""Daily rotating medal (equipment) and points (orange heroes) exchanges in the native UI.

Replayable: every edit is anchored and idempotent.
"""
from pathlib import Path
import hashlib
import json
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def read(name):
    return (ROOT / name).read_text('utf-8-sig')


def write(name, text):
    try:
        original = subprocess.check_output(['git', 'show', 'HEAD:' + name], cwd=ROOT, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        original = b''
    if b'\r\n' in original:
        text = text.replace('\r\n', '\n').replace('\n', '\r\n')
    (ROOT / name).write_bytes(text.encode('utf-8'))


def once(text, before, after):
    if after in text:
        return text
    if before not in text:
        raise ValueError('Missing integration anchor: ' + before[:100])
    return text.replace(before, after, 1)


def normal(text):
    return text.replace('\r\n', '\n')


# Medal exchange page: today's 20 equipment pieces from the server.
p = 'client/src/stages/155_PanelExchange.as'
s = normal(read(p))
s = once(s, '''            if(result == null || int(result.return_code) != 0 || result.data == null ||
               !(result.data.heroes is Array) || result.data.day == null ||
               result.data.heroes.length != 20 ||
               (result.state_sync && !GlobalData.isCurrentProfileSyncEnvelope(result.state_sync)))
            {
               return;
            }
            var rows:Array = [];
            var heroes:Array = result.data.heroes as Array;
            for(var i:int = 0; i < heroes.length; i++)
            {
               var hero:Object = heroes[i];
               if(hero == null || !(hero.aid is String) || int(hero.medal) != 80 ||
                  GlobalData.$mConfig_avatar[hero.aid] == null)
               {
                  return;
               }
               rows.push({"status":true,"indexID_s":"avatar","id":hero.aid,
                          "medal":80,"medal_old":0,"daily_recruit":true,
                          "day":String(result.data.day),"sort_3":0});
            }''', '''            if(result == null || int(result.return_code) != 0 || result.data == null ||
               !(result.data.items is Array) || result.data.day == null ||
               (result.state_sync && !GlobalData.isCurrentProfileSyncEnvelope(result.state_sync)))
            {
               return;
            }
            // Daily medal exchange: 10 orange and 10 purple equipment, new every night.
            var rows:Array = [];
            var items:Array = result.data.items as Array;
            for(var i:int = 0; i < items.length; i++)
            {
               var item:Object = items[i];
               if(item == null || !(item.id is String) || int(item.medal) <= 0 ||
                  GlobalData.$mConfig_equip[item.id] == null)
               {
                  continue;
               }
               rows.push({"status":false,"indexID_s":"equip","id":item.id,
                          "medal":int(item.medal),"medal_old":0,"daily_recruit":true,
                          "day":String(result.data.day),"sort_3":0});
            }''')
write(p, s)

p = 'client/src/stages/092_ItemExchange.as'
s = normal(read(p))
s = once(s, '''            var chosenAid:String = String(data["id"]);
            mBtn_to.enabled = false;
            SendAndSelect.sendAndSelectService("user.recruit_medal_exchange",
               {"aid":chosenAid,"day":String(data["day"])},function(result:Object):void''', '''            var chosenAid:String = String(data["id"]);
            mBtn_to.enabled = false;
            SendAndSelect.sendAndSelectService("user.recruit_medal_exchange",
               {"id":chosenAid,"day":String(data["day"]),"actionID":"medal-equip-"+chosenAid+"-"+new Date().time},function(result:Object):void''')
s = once(s, '''         if(result == null || int(result.return_code) != 0 || result.data == null ||
            result.data.aid != chosenAid || result.data.avatar == null ||
            (result.state_sync && !GlobalData.isCurrentProfileSyncEnvelope(result.state_sync)))
         {
            return;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(result))
         {
            GlobalData.$userData.medal = result.data.medal;
            GlobalData.$userData.avatars = result.data.avatars;
         }
         GlobalData.$userData_avatarNum = Tools.getElementNum(GlobalData.$userData.avatars);
         SoundManager.getOnlyExample().playSound("sound05");
         var award:Object = GlobalFunction.getAwardByType("avatar",chosenAid);
         GlobalFunction.popAward("avatar",GlobalLanguageStr.getLanguageStr(90062,award.msg),chosenAid,false);''', '''         if(result == null || int(result.return_code) != 0 || result.data == null ||
            result.data.id != chosenAid || result.data.equip == null ||
            (result.state_sync && !GlobalData.isCurrentProfileSyncEnvelope(result.state_sync)))
         {
            return;
         }
         if(!GlobalFunction.isVersionedProfileReceipt(result))
         {
            GlobalData.$userData.medal = result.data.medal;
            GlobalData.$userData.my_equips = result.data.my_equips;
         }
         SoundManager.getOnlyExample().playSound("sound05");
         var award:Object = GlobalFunction.getAwardByType("equip",chosenAid);
         GlobalFunction.popAward("equip",GlobalLanguageStr.getLanguageStr(90062,award.msg),chosenAid,false);''')
write(p, s)

# Points exchange page: today's 8 orange heroes from the server.
p = 'client/src/stages/131_PanelInteGralExchange.as'
s = normal(read(p))
s = once(s, '''      override public function addList() : void
      {
         var _loc5_:* = 0;
         var _loc3_:Object = null;
         var _loc2_:Array = GlobalData.$mConfig.ploy_system_simple.extract_avatar.exchange;
         _itemArr = [];''', '''      override public function addList() : void
      {
         SendAndSelect.sendAndSelectService("user.integral_exchange_info",{},function(reply:Object):void
         {
            if(stage == null || reply == null || int(reply.return_code) != 0 || reply.data == null ||
               !(reply.data.rows is Array))
            {
               return;
            }
            addDailyList(reply.data.rows as Array,String(reply.data.day));
         });
      }

      // Points exchange: 6 skin and 2 ordinary orange heroes, new every night.
      private function addDailyList(_loc2_:Array, day:String) : void
      {
         var _loc5_:* = 0;
         var _loc3_:Object = null;
         if(mList) mList.dataProvider = new ListCollection();
         if(_txt_coin) _txt_coin.removeFromParent(true);
         if(txt_Hint) txt_Hint.removeFromParent(true);
         _itemArr = [];''')
s = once(s, '''            _loc3_.needNum = _loc2_[_loc5_][1];
            _loc3_.index = _loc5_;''', '''            _loc3_.needNum = _loc2_[_loc5_][1];
            _loc3_.index = _loc5_;
            _loc3_.day = day;''')
s = once(s, '''         txt_Hint = GlobalTextStyle.getTextField("300积分兑换1张T2皮肤橙卡",18,16764006,"right",380,35);''',
         '''         txt_Hint = GlobalTextStyle.getTextField("每晚0点轮换：皮肤橙卡300 · 普通橙卡200",18,16764006,"right",380,35);''')
write(p, s)

p = 'client/src/stages/097_ItemInteGralExchange.as'
s = normal(read(p))
s = once(s, '''            SendServiceAMFFun.send_user_exchange_activity_avatar(onRe,{"index":data.index});''',
         '''            SendServiceAMFFun.send_user_exchange_activity_avatar(onRe,{"index":data.index,"day":data.day});''')
write(p, s)

manifest = ROOT / 'client/build.json'
cfg = json.loads(manifest.read_text('utf-8'))
for row in cfg['stages']:
    row['source_sha256'] = hashlib.sha256((ROOT / row['source']).read_bytes()).hexdigest()
manifest.write_text(json.dumps(cfg, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('Daily exchanges integrated:', cfg['stage_count'], 'client stages')
