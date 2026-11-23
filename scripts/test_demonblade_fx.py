"""Run the Demonblade effect timeline (the AS core, types stripped) in Node."""
from pathlib import Path
import re
import subprocess
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT / 'scripts')]
from test_skin_revision_native_104 import balanced
from test_dragonmancer_kaisa_native import strip_as_comments

FX = ROOT / 'client/src/demonblade_tryndamere_fx.aspart'
TEXTURES = ['glow', 'ember', 'spark', 'slash', 'ring', 'sigil', 'flame', 'shard', 'smoke', 'blade']
KINDS = ['slash', 'cleave', 'crit', 'warcry', 'rally', 'weak', 'fury', 'aura', 'edge', 'calm', 'mend']


def translate():
    code = FX.read_text('utf-8')
    core = strip_as_comments(code[code.index('// BEGIN DEMON FX CORE 105'):code.index('// END DEMON FX CORE 105')])
    out = ['const DEMON_FX_GROUND105=.42;']
    for match in re.finditer(r'(?:private|public) static function (\w+)\((.*?)\)\s*:\s*[\w.]+\s*\{', core, re.S):
        if match[1] in ('demonFxPaint105', 'demonFxCrescent105', 'demonFxDraw105'):
            continue  # Painting needs flash.display; the harness renders it.
        start = match.end() - 1
        body = core[start + 1:balanced(core, start)]
        args = re.sub(r':[\w.]+', '', match[2])
        body = re.sub(r'\bvar (\w+)\s*:[\w.]+', r'var \1', body)
        out.append(f'function {match[1]}({args}){{{body}}}')
    return '\n'.join(out)


SCRIPT = '''
const assert=require('assert');
%s
const textures=new Set(%s),kinds=%s;let checked=0;
for(const kind of kinds){
 const life=demonFxLife105(kind),looping=life<0,end=looping?6:life;
 let peak=0,seen=0;
 for(let t=0;t<=end+1e-9;t+=1/60){
  const out=[];demonFxSprites105(kind,t,240,520,240,300,7,out);
  peak=Math.max(peak,out.length);seen+=out.length;
  for(const p of out){
   assert.ok(textures.has(p.k),kind+' '+p.k);
   for(const key of ['x','y','sx','sy','r','a','fy'])assert.ok(Number.isFinite(p[key]),kind+' '+key+' '+t);
   assert.ok(p.a>0&&p.a<=1,kind+' alpha '+p.a);
   assert.ok(Math.abs(p.x-240)<700&&Math.abs(p.y-420)<700,kind+' on screen');
   checked++;
  }
 }
 // A mobile-friendly budget per effect.
 assert.ok(seen>0,kind+' draws nothing');assert.ok(peak<=90,kind+' peak '+peak);
 if(!looping){const out=[];demonFxSprites105(kind,life,240,520,240,300,7,out);
  assert.ok(out.every(p=>p.a<.35),kind+' still bright at the end');}
}
// The same seed draws the same frame.
const one=[],two=[];demonFxSprites105('fury',.4,0,0,0,-200,3,one);demonFxSprites105('fury',.4,0,0,0,-200,3,two);
assert.deepEqual(one,two);
console.log('Demonblade effect sprites checked: '+checked);
'''


class DemonbladeEffectTests(unittest.TestCase):
    def test_every_effect_stays_finite_bounded_and_on_screen(self):
        import json
        source = SCRIPT % (translate(), json.dumps(TEXTURES), json.dumps(KINDS))
        run = subprocess.run(['node'], input=source, text=True, encoding='utf-8', capture_output=True, cwd=ROOT)
        self.assertEqual(run.returncode, 0, run.stdout + '\n' + run.stderr)
        print(run.stdout.strip())

    def test_painter_covers_every_texture_the_timeline_uses(self):
        code = FX.read_text('utf-8')
        used = set(re.findall(r'demonFxPut105\(out,"(\w+)"', code)) | {'ember', 'spark', 'ring', 'flame', 'smoke'}
        self.assertEqual(used, set(TEXTURES))
        for name in TEXTURES:
            self.assertIn(f'case "{name}": return [', code)
        self.assertNotIn('$assetManager', code[:code.index('// END DEMON FX CORE 105')])

    def test_battle_teardown_releases_demonblade_effect_state(self):
        from test_vital_bar_104 import method
        layer = (ROOT / 'client/src/stages/177_GameMapLayer.as').read_text('utf-8')
        self.assertIn('Avatar.clearEffects104();\n         Avatar.demonFxClear105();\n         juggler.purge();', layer)
        clear = method('client/src/stages/137_Avatar.as', 'demonFxClear105')
        script = "const clear=" + clear + ";" + '''
const assert=require('assert');
let effect={demonFxLayer105:{removeFromParent(dispose){assert.equal(dispose,true);}},
            demonFxMap105:{},demonFxLive105:[{source:{},target:{}}]};
clear.call(effect);
assert.equal(effect.demonFxLayer105,null);
assert.equal(effect.demonFxMap105,null);
assert.deepEqual(effect.demonFxLive105,[]);
'''
        run = subprocess.run(['node'], input=script, text=True, encoding='utf-8', capture_output=True, cwd=ROOT)
        self.assertEqual(run.returncode, 0, run.stdout + run.stderr)

    def test_preview_harness_takes_the_core_verbatim(self):
        sys.path.insert(0, str(ROOT / 'scripts'))
        from demonblade_fx_preview import harness_source
        code = FX.read_text('utf-8')
        core = code[code.index('      // BEGIN DEMON FX CORE 105\n'):code.index('      // END DEMON FX CORE 105\n')]
        self.assertIn(core, harness_source())


if __name__ == '__main__':
    unittest.main()
