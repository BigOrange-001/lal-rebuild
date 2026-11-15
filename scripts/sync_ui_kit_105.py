"""Install the shared native-style UI kit into every GlobalFunction stage.

GlobalFunction is compiled at several stages (each later source replaces the
class). Every copy must carry the kit: earlier copies so classes compiled in
between can reference it, the last copy so the final SWF keeps it.
"""
from pathlib import Path
import hashlib
import json
import subprocess

ROOT = Path(__file__).resolve().parents[1]
PART = 'client/src/ui_kit_105.aspart'
TAG = 'UI KIT 105'
IMPORTS = ('   import com.meng52.game.ui.element.LOL_Scale9Button;', '   import feathers.controls.TextInput;')


def read(name):
    return (ROOT / name).read_text('utf-8-sig')


def write(name, text):
    try:
        original = subprocess.check_output(['git', 'show', 'HEAD:' + name], cwd=ROOT, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        original = b''
    text = text.replace('\r\n', '\n')
    if b'\r\n' in original:
        text = text.replace('\n', '\r\n')
    (ROOT / name).write_bytes(text.encode('utf-8'))


def install(text):
    text = text.replace('\r\n', '\n')
    begin = '      // BEGIN ' + TAG + '\n'
    end = '      // END ' + TAG + '\n'
    if begin in text:
        a = text.index(begin)
        b = text.index(end, a) + len(end)
        text = text[:a] + text[b:]
    anchor = text.index('   import starling.textures.Texture;')
    for line in IMPORTS:
        if line + '\n' not in text:
            text = text[:anchor] + line + '\n' + text[anchor:]
            anchor = text.index('   import starling.textures.Texture;')
    start = text.index('   public class GlobalFunction')
    # The public class ends at the first line that is exactly "   }"; files may
    # continue with internal helper classes that must not receive the kit.
    close = text.index('\n   }\n', start)
    block = begin + read(PART).rstrip() + '\n' + end
    return text[:close].rstrip() + '\n\n' + block + text[close + 1:]


def main():
    manifest = ROOT / 'client/build.json'
    cfg = json.loads(manifest.read_text('utf-8'))
    sources = [row['source'] for row in cfg['stages'] if row['class'] == 'com.meng52.game.global.GlobalFunction']
    if not sources:
        raise SystemExit('No GlobalFunction stages in client/build.json')
    for name in sources:
        write(name, install(read(name)))
    for row in cfg['stages']:
        row['source_sha256'] = hashlib.sha256((ROOT / row['source']).read_bytes()).hexdigest()
    manifest.write_text(json.dumps(cfg, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('UI kit installed into', len(sources), 'GlobalFunction stages:', ', '.join(Path(s).name for s in sources))


if __name__ == '__main__':
    main()
