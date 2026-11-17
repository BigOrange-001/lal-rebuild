"""Integrate VIP daily packs and the recharge-list order fix into the native UI.

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


def methods(text, part, tag):
    begin = '      // BEGIN ' + tag + '\n'
    end = '      // END ' + tag + '\n'
    block = begin + read(part).rstrip() + '\n' + end
    if begin in text:
        a = text.index(begin)
        b = text.index(end, a) + len(end)
        text = text[:a] + text[b:]
    at = text.index('\n   }\n}', text.index('public class '))
    return text[:at].rstrip() + '\n' + block + text[at:]


def normal(text):
    return text.replace('\r\n', '\n')


# VIP shop: a fifth tab for daily packs.
p = 'client/src/stages/129_PanelCenterShopVIP.as'
s = normal(read(p))
s = once(s, '   import feathers.display.Scale9Image;',
         '   import feathers.controls.ScrollContainer;\n   import feathers.display.Scale9Image;')
s = once(s, '''            },{
               "label":"VIP礼包",
               "indexID":3
            }];''', '''            },{
               "label":"VIP礼包",
               "indexID":3
            },{
               "label":"每日礼包",
               "indexID":4
            }];''')
s = once(s, '''         _itemArr = [];
         if(mTxt_VipGiftEmpty)''', '''         _itemArr = [];
         clearDaily105();
         if(mTxt_VipGiftEmpty)''')
s = once(s, '''         else if(this.mTabBar.selectedIndex == 3)
         {
            _loc9_ = GlobalData.$userData.attrs.vip_gift_buy as Array;''', '''         else if(this.mTabBar.selectedIndex == 4)
         {
            delCasinoUI();
            delVIPInfoBox();
            setVIPUI();
            showDaily105();
         }
         else if(this.mTabBar.selectedIndex == 3)
         {
            _loc9_ = GlobalData.$userData.attrs.vip_gift_buy as Array;''')
s = once(s, '''      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {''', '''      override public function onREMOVED_FROM_STAGE(param1:Event) : void
      {
         clearDaily105();''')
s = methods(s, 'client/src/vip_daily_packs_105.aspart', 'VIP DAILY PACKS 105')
write(p, s)

# Recharge list: order by the numeric index (string order put 10 before 2).
p = 'client/src/stages/008_PanelShopCoin.as'
s = normal(read(p))
s = once(s, '''                  _loc4_.sortOn("indexID_s");
                  mItemArrTemp = _loc4_;''', '''                  _loc4_.sortOn("indexID_s",16);
                  mItemArrTemp = _loc4_;''')
write(p, s)

manifest = ROOT / 'client/build.json'
cfg = json.loads(manifest.read_text('utf-8'))
for row in cfg['stages']:
    row['source_sha256'] = hashlib.sha256((ROOT / row['source']).read_bytes()).hexdigest()
manifest.write_text(json.dumps(cfg, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('Shop/VIP UI integrated:', cfg['stage_count'], 'client stages')
