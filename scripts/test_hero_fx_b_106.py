"""Run group B's code-painted hero effect timelines (AS source, types stripped) in Node.

Checks every kind and every persistent mark: finite numbers, legal alpha (one sprite <= .85,
marks <= .55), on screen, within the core sprite budget, faded out at the end of life, and
that every texture a timeline names has a painter.
"""
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

CORE = ROOT / 'client/src/hero_fx_core_106.aspart'
GROUP = ROOT / 'client/src/hero_fx_b_106.aspart'
PURE_START = '      // BEGIN HERO FX B PURE 106\n'
PURE_END = '      // END HERO FX B PURE 106\n'
KINDS = ['tahm_tongue', 'tahm_slam', 'tahm_gold', 'malz_flame', 'malz_cast', 'malz_summon', 'void_burn', 'void_venom',
         'lee_wave', 'lee_dash', 'lee_kick', 'lee_crash', 'lee_bell', 'ryze_brand', 'ryze_leech', 'ryze_domain',
         'ryze_hell', 'ryze_growth', 'cait_shot', 'cait_wanted', 'cait_snipe', 'cait_trap', 'vayne_bolt',
         'vayne_bolt_ult', 'vayne_hunt', 'vayne_burst', 'fb_heal', 'fb_shield', 'fb_cleanse']
MARKS = [dict(kind='rings', count=c) for c in (1, 2, 3)] + [dict(kind=k, count=n) for k, n in (
    ('contract', 0), ('growth', 1), ('growth', 10), ('wanted', 0), ('trap', 0), ('sonic', 0), ('ward', 0))]


def pure_block():
    code = GROUP.read_text('utf-8')
    return code[code.index(PURE_START):code.index(PURE_END)]


def helpers_block():
    code = CORE.read_text('utf-8')
    return code[code.index('// BEGIN HERO FX HELPERS 106'):code.index('// END HERO FX HELPERS 106')]


def translate():
    out = []
    for source in (helpers_block(), pure_block()):
        source = strip_as_comments(source)
        for match in re.finditer(r'(?:private|public) static function (\w+)\((.*?)\)\s*:\s*[\w.]+\s*\{', source, re.S):
            start = match.end() - 1
            body = source[start + 1:balanced(source, start)]
            if 'flash.' in match[2] + body:
                continue  # Painting needs flash.display; the preview harness renders it.
            args = re.sub(r':[\w.]+', '', match[2])
            body = re.sub(r'\bvar (\w+)\s*:[\w.]+', r'var \1', body)
            out.append(f'function {match[1]}({args}){{{body}}}')
    return '\n'.join(out)


SCRIPT = '''
const assert=require('assert');
%s
const kinds=%s,marks=%s,textures=new Set(%s);let checked=0;const used=new Set();
// Caster below, target above, as on the battle map; also a self effect.
const layouts=[[240,560,240,300],[240,300,240,560],[200,420,200,420]];
for(const kind of kinds){
 const life=heroFxLifeB106(kind);assert.ok(life>0&&life<=1.8,kind+' life '+life);
 for(const [sx,sy,tx,ty] of layouts){
  let peak=0,seen=0;
  for(let t=0;t<=life+1e-9;t+=1/60){
   const out=[];heroFxSpritesB106(kind,t,sx,sy,tx,ty,7,out);
   peak=Math.max(peak,out.length);seen+=out.length;
   for(const p of out){
    used.add(p.k);
    for(const key of ['x','y','sx','sy','r','a','fy'])assert.ok(Number.isFinite(p[key]),kind+' '+key+' '+t);
    assert.ok(p.a>0&&p.a<=.85+1e-9,kind+' alpha '+p.a+' '+p.k);
    assert.ok(Math.abs(p.x-240)<480&&Math.abs(p.y-420)<520,kind+' off screen '+p.x+','+p.y);
    assert.ok(Math.abs(p.sx)<=6&&Math.abs(p.sy)<=6,kind+' huge '+p.k);
    checked++;
   }
  }
  assert.ok(seen>0,kind+' draws nothing');assert.ok(peak<=60,kind+' peak '+peak);
  const end=[];heroFxSpritesB106(kind,life,sx,sy,tx,ty,7,end);
  assert.ok(end.every(p=>p.a<.35),kind+' still bright at the end');
 }
}
for(const row of marks){
 const ids=hfxBMarkIds106(row.kind,row.count);assert.ok(ids.length>0,row.kind);
 if(row.kind=='rings')assert.equal(ids.length,row.count);
 for(let t=0;t<6;t+=.05)ids.forEach((id,i)=>{
  used.add(id);
  const m=hfxBMark106(row.kind,i,row.count,t,3);
  for(const key of ['x','y','sx','sy','r','a'])assert.ok(Number.isFinite(m[key]),row.kind+' '+key);
  assert.ok(m.a>=0&&m.a<=.55+1e-9,row.kind+' mark alpha '+m.a);
  // Clear of the health bar (y -58..-45) and inside the unit's neighbourhood.
  assert.ok(m.y>-42&&m.y<60&&Math.abs(m.x)<50,row.kind+' mark position '+m.x+','+m.y);
 });
}
// Row ownership.
assert.equal(hfxBMarkKind106({key:'rings_7',kind:'rings',count:2}),'rings');
assert.equal(hfxBMarkKind106({key:'contract',kind:'contract'}),'contract');
assert.equal(hfxBMarkKind106({key:'growth',kind:'growth'}),'growth');
assert.equal(hfxBMarkKind106({key:'evilStacks',kind:'growth'}),null);
assert.equal(hfxBMarkKind106({key:'mark_aim_3',kind:'wanted'}),null);
assert.equal(hfxBMarkKind106({key:'guarding',kind:'guard'}),null);
assert.equal(hfxBMarkKind106({key:'ward',kind:'guard'}),'ward');
for(const id of used)assert.ok(textures.has(id),'no painter for '+id);
const one=[],two=[];heroFxSpritesB106('lee_kick',.4,0,0,0,-200,3,one);heroFxSpritesB106('lee_kick',.4,0,0,0,-200,3,two);
assert.deepEqual(one,two);
console.log('Group B sprites checked: '+checked+', textures used: '+used.size);
'''


def painted():
    return re.findall(r'case "(\w+)": return \[', pure_block())


class HeroFxGroupBTests(unittest.TestCase):
    def test_every_kind_and_mark_stays_legal(self):
        source = SCRIPT % (translate(), json.dumps(KINDS), json.dumps(MARKS), json.dumps(painted()))
        run = subprocess.run(['node'], input=source, text=True, encoding='utf-8', capture_output=True, cwd=ROOT)
        self.assertEqual(run.returncode, 0, run.stdout + '\n' + run.stderr)
        print(run.stdout.strip())

    def test_every_life_case_is_a_tested_kind(self):
        block = pure_block()
        life = block[block.index('heroFxLifeB106'):]
        life = life[:life.index('return 0;')]
        self.assertEqual(set(re.findall(r'case "(\w+)"', life)), set(KINDS))

    def test_painter_has_a_branch_for_every_size(self):
        block = pure_block()
        paint = block[block.index('heroFxPaintB106'):block.index('private static function hfxBHeart106')]
        for name in painted():
            self.assertTrue(f'"{name}"' in paint, name)
        self.assertNotIn('$assetManager', block)

    def test_group_b_hooks_are_in_the_generated_avatar(self):
        avatar = (ROOT / 'client/src/stages/137_Avatar.as').read_text('utf-8')
        self.assertIn(pure_block(), avatar)
        self.assertIn('statisticsOwner104.heroFxClaim106("summon","summon",this);', avatar)
        # The extra hook is exactly one line and only presents.
        self.assertEqual(avatar.count('heroFxClaim106("summon"'), 1)

    def test_claims_name_only_kinds_that_exist(self):
        code = GROUP.read_text('utf-8')
        claims = code[code.index(PURE_END):]
        for kind in set(re.findall(r'heroFx106\("(\w+)"', claims)):
            self.assertIn(kind, KINDS)
        for kind in re.findall(r'"(\w+)" : "(\w+)"', claims):
            for k in kind:
                if '_' in k:
                    self.assertIn(k, KINDS)


if __name__ == '__main__':
    unittest.main()
