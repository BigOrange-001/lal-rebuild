"""Integrate arena rules help and top-ten raid defense into the native arena UI.

Replayable: every edit is anchored and idempotent, like the formation-share
integration it builds on. Run after ``sync_formation_share_104.py``.
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


p = 'client/src/stages/001_GlobalData.as'
s = normal(read(p))
s = once(s, '      public static var $formationShare104:Object = {};',
         '      public static var $formationShare104:Object = {};\n      public static var $arenaRaid105:Object = {};')
write(p, s)

p = 'client/src/stages/046_PanelCenterPVP.as'
s = normal(read(p))
s = once(s, '   import com.meng52.game.module.map.GameMap;',
         '   import com.meng52.game.module.map.GameMap;\n   import com.meng52.game.module.avatar.Avatar;')
s = once(s, '      private var formationRows104:Array = [];',
         '      private var formationRows104:Array = [];\n'
         '      private var raidRows105:Array = [];\n'
         '      private var raidButton105:LOL_Scale9Button;\n'
         '      private var arenaHelp105:LOL_Scale9Button;\n'
         '      private var raidModal105:Sprite;')
# Arena tab header: lay out all buttons together.
s = once(s, '''            mBtn_change.addEventListener("triggered",changeOpponents);
            addChild(mBtn_change);
         }''', '''            mBtn_change.addEventListener("triggered",changeOpponents);
            addChild(mBtn_change);
         }
         if(this.mTabBar.selectedIndex == 1 && !GlobalFunction.checkIsFirstPVP()) addArenaControls105();''')
s = once(s, '''      private function delPVPList() : void
      {
         clearFormationControls104();''', '''      private function delPVPList() : void
      {
         clearFormationControls104();
         clearArenaControls105();''')
s = once(s, '''         closeFormationCode104();clearFormationControls104();''',
         '''         closeFormationCode104();clearFormationControls104();clearArenaControls105();''')
# Toggling between list and reports changes which buttons are visible.
s = once(s, '''         mFun_status = !mFun_status;
         if(mBtn_change) mBtn_change.visible = !mFun_status;''', '''         mFun_status = !mFun_status;
         if(mBtn_change) mBtn_change.visible = !mFun_status;
         layoutArenaControls105();''')
# Every rank-list refresh also checks for raids.
s = once(s, '''         if(mTabBar.selectedIndex == 1)
         {
            this.setList();
            this.addList();
            if(shareModal104) addChild(shareModal104);
         }''', '''         if(mTabBar.selectedIndex == 1)
         {
            this.setList();
            this.addList();
            if(shareModal104) addChild(shareModal104);
            if(raidModal105) addChild(raidModal105);
            loadRaids105();
         }''')
s = methods(s, 'client/src/arena_raids_105.aspart', 'ARENA RAIDS 105')
write(p, s)

p = 'client/src/stages/047_ItemPVP.as'
s = normal(read(p))
s = once(s, '''         GlobalData.$formationShare104={};
         if(mBtn_pk.alpha < 1)''', '''         GlobalData.$formationShare104={};
         GlobalData.$arenaRaid105={};
         if(mBtn_pk.alpha < 1)''')
write(p, s)

p = 'client/src/stages/175_GameMap.as'
s = normal(read(p))
s = once(s, '''            if(GlobalData.$formationShare104 && GlobalData.$formationShare104.mode=="challenge")
            {
               _obj.formation_id=GlobalData.$formationShare104.id;''', '''            if(GlobalData.$arenaRaid105 && GlobalData.$arenaRaid105.id)
            {
               // Top-ten raid defense: an ordinary arena battle, settled by the raid.
               _obj.raid_id=GlobalData.$arenaRaid105.id;
               _obj.actionID="arena-raid-"+_obj.raid_id+"-"+new Date().time+"-"+Math.random();
               GlobalData.$arenaRaid105={};
               SendAndSelect.sendAndSelectService("user.pk_combat_raid",_obj,reSend);
            }
            else if(GlobalData.$formationShare104 && GlobalData.$formationShare104.mode=="challenge")
            {
               _obj.formation_id=GlobalData.$formationShare104.id;''')
write(p, s)

p = 'client/src/stages/180_PanelPVEembattle.as'
s = normal(read(p))
s = once(s, '''      override public function onTRIGGERED(param1:Event) : void
      {
         if(GlobalData.$formationShare104 && GlobalData.$formationShare104.mode)''', '''      override public function onTRIGGERED(param1:Event) : void
      {
         GlobalData.$arenaRaid105={};
         if(GlobalData.$formationShare104 && GlobalData.$formationShare104.mode)''')
write(p, s)

manifest = ROOT / 'client/build.json'
cfg = json.loads(manifest.read_text('utf-8'))
for row in cfg['stages']:
    row['source_sha256'] = hashlib.sha256((ROOT / row['source']).read_bytes()).hexdigest()
manifest.write_text(json.dumps(cfg, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('Arena raids UI integrated:', cfg['stage_count'], 'client stages')
