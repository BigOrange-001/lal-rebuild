"""Group A code-painted hero effects: run the timelines (AS, types stripped) in Node and check the wiring."""
from pathlib import Path
import json
import re
import subprocess
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT / 'scripts')]
from test_skin_revision_native_104 import balanced
from test_dragonmancer_kaisa_native import strip_as_comments

FX = ROOT / 'client/src/hero_fx_a_106.aspart'
CORE = ROOT / 'client/src/hero_fx_core_106.aspart'
AVATAR = ROOT / 'client/src/stages/137_Avatar.as'
TEXTURES = ['glow', 'dot', 'spark', 'ring', 'star', 'note', 'note2', 'clef', 'staff', 'wave', 'gavel', 'seal', 'crack',
            'shard', 'chain', 'claw', 'clawShut', 'lock', 'gear', 'dart', 'egg', 'shell', 'confetti', 'puff', 'smoke',
            'ball', 'trail', 'shuriken', 'slash', 'lotus', 'petal', 'flame', 'rune']
KINDS = ['sonaHeal', 'sonaShield', 'sonaCast', 'sonaEncore', 'sonaUlt',
         'judgeQ', 'judgeBreak', 'judgeTransfer', 'judgeCast', 'verdict', 'judgeTrue',
         'zedStar', 'shadowStar',
         'teemoDart', 'eggBoom', 'eggHit', 'teemoParade', 'eggToss',
         'blitzGrab', 'blitzLock', 'blitzReboot', 'blitzPurify', 'blitzZap', 'blitzMute',
         'ezCurl', 'ezVolley', 'ezWorldie', 'ezFinish', 'ezPass', 'ezBackPass', 'ezJuggle', 'ezShotReady',
         'karmaOrb', 'karmaStun', 'karmaFlame', 'karmaPurify', 'karmaShield', 'karmaCast', 'karmaNova', 'karmaNova2', 'karmaHeal']
CAPTAINS = {'sonaCast', 'sonaUlt', 'judgeCast', 'verdict', 'teemoParade', 'blitzReboot', 'ezWorldie', 'karmaCast', 'karmaNova2'}
STATES = {'exposed': 1, 'egg': 1, 'egg_ready': 2, 'aura_heal': 3, 'aura_guard': 3, 'ball': 1, 'shot': 2, 'shadow': 1}


def pure_functions(path, start, end):
    code = path.read_text('utf-8')
    block = strip_as_comments(code[code.index(start):code.index(end)])
    out = []
    for match in re.finditer(r'(?:private|public) static function (\w+)\((.*?)\)\s*:\s*[\w.]+\s*\{', block, re.S):
        if match[1] == 'heroFxPaintA106' or match[1].startswith('hfxAPaint'):
            continue  # Painting needs flash.display; the preview harness renders it.
        begin = match.end() - 1
        body = block[begin + 1:balanced(block, begin)]
        args = re.sub(r':[\w.]+', '', match[2])
        body = re.sub(r'\bvar (\w+)\s*:[\w.]+', r'var \1', body)
        out.append(f'function {match[1]}({args}){{{body}}}')
    return '\n'.join(out)


def translate():
    return (pure_functions(CORE, '// BEGIN HERO FX HELPERS 106', '// END HERO FX HELPERS 106') + '\n' +
            pure_functions(FX, '// BEGIN HFX A PURE 106', '// END HFX A PURE 106'))


SCRIPT = '''
const assert=require('assert');
%s
const textures=new Set(%s),kinds=%s,captains=new Set(%s),states=%s;let checked=0;
for(const kind of kinds){
 const life=heroFxLifeA106(kind);
 assert.ok(life>0,kind+' has no life');
 assert.ok(life<=(captains.has(kind)?1.8:1.2)+1e-9,kind+' too long '+life);
 let peak=0,seen=0;
 // Caster below, target above; and a self-targeted call (source == target).
 for(const [sx,sy,tx,ty] of [[240,620,240,300],[240,520,240,520],[200,640,300,120]]){
  for(let t=0;t<=life+1e-9;t+=1/60){
   const out=[];heroFxSpritesA106(kind,t,sx,sy,tx,ty,7,out);
   peak=Math.max(peak,out.length);seen+=out.length;
   for(const p of out){
    assert.ok(textures.has(p.k),kind+' '+p.k);
    for(const key of ['x','y','sx','sy','r','a','fy'])assert.ok(Number.isFinite(p[key]),kind+' '+key+' '+t);
    assert.ok(p.a>0&&p.a<=.85+1e-9,kind+' alpha '+p.a);
    assert.ok(Number.isInteger(p.c)&&p.c>=0&&p.c<=0xFFFFFF,kind+' colour');
    assert.ok(p.x>-60&&p.x<540&&p.y>-60&&p.y<780,kind+' off screen '+p.x+','+p.y);
    // Nothing balloons to a screen-wide flash: drawn size stays under ~420 px.
    assert.ok(Math.max(Math.abs(p.sx)*hfxASize106(p.k)[0],Math.abs(p.sy)*hfxASize106(p.k)[1])<=420,kind+' '+p.k+' too big '+p.sx+'x'+p.sy);
    checked++;
   }
  }
  const end=[];heroFxSpritesA106(kind,life,sx,sy,tx,ty,7,end);
  assert.ok(end.every(p=>p.a<.35),kind+' still bright at the end');
 }
 assert.ok(seen>0,kind+' draws nothing');assert.ok(peak<=72,kind+' peak '+peak);
}
// The same seed draws the same frame.
const one=[],two=[];heroFxSpritesA106('verdict',.5,0,0,0,-200,3,one);heroFxSpritesA106('verdict',.5,0,0,0,-200,3,two);
assert.deepStrictEqual(one,two);
// Persistent marks stay small and faint.
for(const [kind,parts] of Object.entries(states))
 for(let i=0;i<parts;i++) for(let t=0;t<8;t+=.07){
  const pose={};hfxAStatePose106(kind,i,t,5,t,pose);
  for(const key of ['x','y','sx','sy','r','a'])assert.ok(Number.isFinite(pose[key]),kind+' '+key);
  assert.ok(pose.a>=0&&pose.a<=.55,kind+' state alpha '+pose.a);
  assert.ok(Math.abs(pose.sx)<=1.5&&Math.abs(pose.sy)<=1.5/.45&&Math.abs(pose.x)<=40&&Math.abs(pose.y)<=40,kind+' state size');
 }
console.log('Group A effect sprites checked: '+checked);
'''


class HeroFxGroupATests(unittest.TestCase):
    def test_every_kind_stays_finite_faint_bounded_and_on_screen(self):
        source = SCRIPT % (translate(), json.dumps(TEXTURES), json.dumps(KINDS), json.dumps(sorted(CAPTAINS)), json.dumps(STATES))
        run = subprocess.run(['node'], input=source, text=True, encoding='utf-8', capture_output=True, cwd=ROOT)
        self.assertEqual(run.returncode, 0, run.stdout + '\n' + run.stderr)
        print(run.stdout.strip())

    def test_painter_covers_every_texture_and_kind(self):
        code = FX.read_text('utf-8')
        pure = code[code.index('// BEGIN HFX A PURE 106'):]
        # Literal texture names plus the ones picked by a ternary or passed to a shared helper.
        used = set(re.findall(r'hfxAP106\(out,"(\w+)"', pure)) | set(re.findall(r'\? "(\w+)" : "(\w+)"', pure)[0])
        used |= {'spark', 'ring', 'glow', 'dot', 'confetti', 'ball', 'gavel', 'petal'}
        self.assertLessEqual(used, set(TEXTURES))
        for name in TEXTURES:
            self.assertRegex(pure, rf'case "{name}":')
        self.assertIn('heroFx106("a:"+kind,target,extra);', code)
        claimed = set(re.findall(r'heroFxA106\("(\w+)"', code)) | set(re.findall(r'hfxAEach106\("(\w+)"', code))
        claimed |= {'sonaHeal', 'sonaShield', 'eggHit', 'teemoDart', 'ezJuggle', 'ezPass', 'zedStar', 'shadowStar'}
        self.assertEqual(claimed, set(KINDS))
        for ident in re.findall(r'"a:(\w+)"', code):
            self.assertIn(ident, TEXTURES)
        self.assertNotIn('$assetManager', code)

    def test_synced_into_avatar_with_cast_hooks(self):
        avatar = AVATAR.read_text('utf-8')
        code = FX.read_text('utf-8')
        self.assertTrue(code in avatar, 'Avatar is stale: run sync_hero_fx_106.py then sync_hero_fx_a_106.py')
        for family in ('1228', '1214', '1209', '1204'):
            self.assertEqual(avatar.count(f'heroFxClaim106("cast","{family}_ult"'), 1, family)
        # Hooks only add presentation calls: the combat line after each one is untouched.
        self.assertIn('heroFxClaim106("cast","1209_ult",target,{targets:targets.slice(0,3)});\n'
                      '                  if(!skin2.eggs) skin2.eggs=[];', avatar)
        # Presentation never reaches gameplay randomness.
        self.assertNotRegex(code, r'Random\.|Math\.random')

    def test_preview_harness_takes_the_pure_block_verbatim(self):
        from hero_fx_preview_a_106 import harness_source, SCENES
        code = FX.read_text('utf-8')
        pure = code[code.index('      // BEGIN HFX A PURE 106\n'):code.index('      // END HFX A PURE 106\n')]
        self.assertIn(pure, harness_source())
        shown = {fx['kind'] for scene in SCENES for fx in scene['fx']}
        self.assertEqual(shown, set(KINDS) - {'ezJuggle'})  # the solo keepy-uppy is not staged


if __name__ == '__main__':
    unittest.main()
