"""Install the skill detail popup layout (skill_tips_105.aspart) into SkillSet and its callers."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
START = '      // BEGIN SKILL TIPS 105\n'
END = '      // END SKILL TIPS 105\n'
OLD_DETAILS = '''      public function getInfoDetails() : String
      {
         var _loc3_:String = null;
         var _loc4_:SkillSetData = skillSetData;
         var _loc1_:int = _loc4_.aoe;
         var _loc2_:int = Math.abs(_loc4_.range);
         _loc3_ = GlobalLanguageStr.getLanguageStr(20468,_loc4_.warmup,_loc4_.cooldown) + "\\n";
         if(_loc4_.hpType > 0)
         {
            _loc3_ += GlobalLanguageStr.getLanguageStr(24030,GameMapTools.toPercentage(_loc4_.hpType)) + "\\n";
         }
         else if(_loc4_.hpType < 0)
         {
            _loc3_ += GlobalLanguageStr.getLanguageStr(24031,GameMapTools.toPercentage(-_loc4_.hpType)) + "\\n";
         }
         _loc3_ += getInfo() + "\\n";
         return _loc3_;
      }
'''


def read(path):
    raw = (ROOT / path).read_bytes().decode('utf-8')
    return raw.replace('\r\n', '\n'), '\r\n' in raw


def write(path, text, crlf):
    (ROOT / path).write_bytes((text.replace('\n', '\r\n') if crlf else text).encode('utf-8'))


def once(text, old, new, label):
    if new in text:
        return text
    if text.count(old) != 1:
        raise ValueError(f'Missing or ambiguous skill tip hook in {label}: {old[:80]}')
    return text.replace(old, new, 1)


skill_path = 'client/src/stages/139_SkillSet.as'
s, crlf = read(skill_path)
code = (ROOT / 'client/src/skill_tips_105.aspart').read_text('utf-8').replace('\r\n', '\n')
block = START + code + END
if START in s:
    s = s[:s.index(START)] + block + s[s.index(END) + len(END):]
else:
    s = once(s, OLD_DETAILS, block, skill_path)
s = once(s, '   import com.meng52.game.global.GlobalLanguageStr;\n',
         '   import com.meng52.game.global.GlobalLanguageStr;\n   import com.meng52.game.global.GlobalTextStyle;\n', skill_path)
write(skill_path, s, crlf)

OLD_FORMAT = '_loc2_ = Tools.formatLineX(_loc2_,GlobalTextStyle.COLOR_W_W_Y_G);'
NEW_FORMAT = '_loc2_ = SkillSet.formatTip105(_loc2_);'
CALLERS = {'client/src/stages/035_PanelBetterStart.as': 1,
           'client/src/stages/141_PanelDetailAll.as': 2,
           'client/src/stages/143_LOL_DetailAvatar.as': 2}
for path, count in CALLERS.items():
    # Single-line swap on the raw text: some callers mix CRLF and LF lines.
    text = (ROOT / path).read_bytes().decode('utf-8')
    if text.count(NEW_FORMAT) != count:
        if text.count(OLD_FORMAT) != count:
            raise ValueError(f'Expected {count} skill popup formatter call(s) in {path}')
        (ROOT / path).write_bytes(text.replace(OLD_FORMAT, NEW_FORMAT).encode('utf-8'))

manifest = ROOT / 'client/build.json'
cfg = json.loads(manifest.read_text('utf-8'))
for stage in cfg['stages']:
    if stage['source'] == skill_path or stage['source'] in CALLERS:
        stage['source_sha256'] = hashlib.sha256((ROOT / stage['source']).read_bytes()).hexdigest()
manifest.write_text(json.dumps(cfg, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('Synchronized skill detail popup layout')
