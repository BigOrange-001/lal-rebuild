"""Run Kai'Sa's Icathian Rain timeline (the AS code, types stripped) in Node."""
from pathlib import Path
import re
import subprocess
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT / 'scripts')]
from test_skin_revision_native_104 import balanced  # noqa: E402
from test_dragonmancer_kaisa_native import strip_as_comments  # noqa: E402

FX = ROOT / 'client/src/kaisa_rain_fx_106.aspart'
CORE = ROOT / 'client/src/hero_fx_core_106.aspart'
FUNCTION = re.compile(r'(?:private|public) static function (\w+)\((.*?)\)\s*:\s*[\w.]+\s*\{', re.S)


def functions(code, skip=()):
    out = []
    for match in FUNCTION.finditer(code):
        if match[1] in skip:
            continue
        start = match.end() - 1
        body = code[start + 1:balanced(code, start)]
        args = re.sub(r':[\w.*]+', '', match[2])  # keep default values
        body = re.sub(r'\bvar (\w+)\s*:[\w.*]+', r'var \1', body)
        out.append(f'function {match[1]}({args}){{{body}}}')
    return out


def translate():
    fx = strip_as_comments(FX.read_text('utf-8'))
    core = strip_as_comments(CORE.read_text('utf-8'))
    helpers = core[core.index('public static function hfxRand106'):]
    out = ['const int=v=>v|0;']  # AS int() casts
    out += [f'const {name}={value};' for name, value in
           re.findall(r'private static const (KAISA_RAIN_\w+106):Number = ([\d.]+);', fx)]
    out += functions(helpers)
    timeline = fx[fx.index('public static function heroFxLifeK106'):]
    out += functions(timeline)
    return '\n'.join(out)


SCRIPT = '''
const assert=require('assert');
%s
const textures=new Set(['glow','streak','bolt','spark','ring']);
const scenes=[[240,560,240,300],[150,600,330,240],[240,200,240,520],[300,500,120,380]];
let checked=0,maxCount=0;
for(const [sx,sy,tx,ty] of scenes)for(let shot=0;shot<13;shot++)for(const hover of [0,.16,.45,.8]){
 const p={hover,shot},seed=shot+7,life=heroFxLifeK106('rain',p);
 assert.ok(Math.abs(life-(hover+KAISA_RAIN_FLIGHT106+KAISA_RAIN_IMPACT106))<1e-9);
 for(let t=0;t<=life+1e-9;t+=1/60){
  const out=[];heroFxSpritesK106('rain',t,sx,sy,tx,ty,seed,out,p);
  maxCount=Math.max(maxCount,out.length);
  for(const s of out){
   assert.ok(textures.has(s.k),s.k);
   for(const key of ['x','y','sx','sy','r','a','fy'])assert.ok(Number.isFinite(s[key]),key+' '+t);
   assert.ok(s.a>0&&s.a<=.85+1e-9,'alpha '+s.a+' '+s.k);
   assert.ok(Math.abs(s.x-sx)<420&&Math.abs(s.y-sy)<560,'on screen '+s.k+' '+s.x+','+s.y);
   checked++;
  }
  // Floating missiles sit beside the 90px card, not on the portrait or health bar.
  const bolt=out.find(s=>s.k==='bolt');
  if(bolt&&t<hover&&t>KAISA_RAIN_EMERGE106){
   const dx=bolt.x-sx,dy=bolt.y-sy,dist=Math.hypot(dx,dy);
   assert.ok(dist>50,'hover overlaps the card '+dist.toFixed(1));
  }
 }
 // The missile lands on the target exactly when the old projectile did.
 const end=[];heroFxSpritesK106('rain',hover+KAISA_RAIN_FLIGHT106-1e-6,sx,sy,tx,ty,seed,end,p);
 const bolt=end.find(s=>s.k==='bolt');
 assert.ok(Math.hypot(bolt.x-tx,bolt.y-(ty-12))<1,'lands on target');
 const start=[];heroFxSpritesK106('rain',0,sx,sy,tx,ty,seed,start,p);
 assert.ok(start.some(s=>s.k==='bolt'),'visible from spawn');
}
assert.ok(maxCount<=72,'sprite budget '+maxCount);
const none=[];heroFxSpritesK106('other',0,0,0,0,0,1,none,null);assert.equal(none.length,0);
assert.equal(heroFxLifeK106('other',null),0);
console.log('kaisa rain sprites checked',checked,'max per missile',maxCount);
'''


class KaisaRainTimelineTests(unittest.TestCase):
    def test_timeline_runs_in_node(self):
        result = subprocess.run(['node'], input=SCRIPT % translate(), text=True, encoding='utf-8',
                                capture_output=True, cwd=ROOT)
        self.assertEqual(result.returncode, 0, result.stdout + '\n' + result.stderr)
        print(result.stdout.strip())

    def test_projectile_hands_off_to_rain(self):
        kaisa = (ROOT / 'client/src/dragonmancer_kaisa.aspart').read_text('utf-8')
        start = kaisa.index('private function kaisaProjectile104(')
        body = kaisa[start:kaisa.index('\n      }\n', start)]
        self.assertIn('kaisaRain106(target,shot);', body)
        avatar = (ROOT / 'client/src/stages/137_Avatar.as').read_text('utf-8')
        self.assertIn('// BEGIN KAISA RAIN FX 106', avatar)
        self.assertIn('kaisaRain106(target,shot);', avatar)
        self.assertNotIn('getTexture("MOD_KAISA_MISSILE104")', avatar)


if __name__ == '__main__':
    unittest.main()
