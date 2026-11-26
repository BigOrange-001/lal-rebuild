"""Group C code-painted hero effects: run the AS timelines (types stripped) in Node and
check the painter, the claim table and the hooks.

    python scripts/test_hero_fx_c_106.py
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

GROUP = ROOT / 'client/src/hero_fx_c_106.aspart'
CORE = ROOT / 'client/src/hero_fx_core_106.aspart'
PURE = ('// BEGIN HFX C PURE 106', '// END HFX C PURE 106')
HELPERS = ('// BEGIN HERO FX HELPERS 106', '// END HERO FX HELPERS 106')
# Ultimates and team-wide casts may run to 1.8 s; everything else stays within 1.2 s.
LONG = {'vult', 'wflood', 'estar0', 'ecomeback', 'zaroma', 'kwalk', 'tsuper'}
STATES = ['y_mark', 'y_air', 'y_wind', 'y_guard', 's_vayne', 's_kass', 's_snake', 's_mush', 's_zongzi']


def section(path, marks):
    code = path.read_text('utf-8')
    return code[code.index(marks[0]):code.index(marks[1])]


def translate():
    out = []
    for code in (section(CORE, HELPERS), section(GROUP, PURE)):
        code = strip_as_comments(code)
        for match in re.finditer(r'(?:private|public) static function (\w+)\((.*?)\)\s*:\s*[\w.]+\s*\{', code, re.S):
            start = match.end() - 1
            body = code[start + 1:balanced(code, start)]
            if 'flash.' in body:
                continue  # Painting needs flash.display; the preview renders it.
            args = re.sub(r':[\w.]+', '', match[2])
            body = re.sub(r'\bvar (\w+)\s*:[\w.]+', r'var \1', body)
            out.append(f'function {match[1]}({args}){{{body}}}')
    return '\n'.join(out)


def kinds():
    code = section(GROUP, PURE)
    life = code[code.index('function heroFxLifeC106'):]
    life = life[:life.index('return 0;')]
    return re.findall(r'case "(\w+)": return', life)


def textures():
    code = section(GROUP, PURE)
    table = code[code.index('function hfxCSize106'):code.index('function heroFxPaintC106')]
    return re.findall(r'case "(\w+)": return \[', table)


SCRIPT = '''
const assert=require('assert');
%s
const textures=new Set(%s),kinds=%s,long=new Set(%s),states=%s;
const views=[[240,560,240,250],[240,560,320,180],[240,420,240,420],[160,300,330,620]];
let checked=0;const bad=[];const check=(ok,msg)=>{if(!ok&&bad.length<40&&!bad.some(b=>b.split(' ')[0]===msg.split(' ')[0]&&b.split(' ')[1]===msg.split(' ')[1]))bad.push(msg);};
for(const kind of kinds){
 const life=heroFxLifeC106(kind);
 assert.ok(life>0 && life<=(long.has(kind)?1.8:1.2),kind+' life '+life);
 let seen=0,peak=0;
 for(const [sx,sy,tx,ty] of views){
  for(let t=0;t<=life+1e-9;t+=1/60){
   const out=[];heroFxSpritesC106(kind,t,sx,sy,tx,ty,7,out);
   peak=Math.max(peak,out.length);seen+=out.length;
   for(const p of out){
    assert.ok(textures.has(p.k),kind+' texture '+p.k);
    for(const key of ['x','y','sx','sy','r','a','fy','c'])assert.ok(Number.isFinite(p[key]),kind+' '+key+' at '+t);
    check(p.a>0&&p.a<=.85+1e-9,kind+' alpha '+p.a);
    check(p.x>-120&&p.x<600&&p.y>-120&&p.y<840,kind+' off screen '+p.x+','+p.y);
    // No full-screen washes: nothing wider than about a lane.
    const size={glow:128,ring:256,wave:256,cone:128,smoke:128,rune:256,crescent:256,streak:256}[p.k]||96;
    if(p.k!=='streak')check(Math.abs(p.sx)*size<=300,kind+' too wide '+p.k+' '+p.sx);
    checked++;
   }
  }
  // Faded out by the end of its life.
  const out=[];heroFxSpritesC106(kind,life,sx,sy,tx,ty,7,out);
  check(out.every(p=>p.a<.36),kind+' still bright at the end '+JSON.stringify(out.filter(p=>p.a>=.36)[0]));
 }
 assert.ok(seen>0,kind+' draws nothing');
 check(peak<=60,kind+' peak '+peak);
}
for(const state of states)
 for(let index=0;index<2;index++)
  for(let t=0;t<4;t+=.05){
   const pose=hfxCPose106(state,index,2,t,3);
   assert.ok(pose&&pose.length===8,state);
   for(let i=0;i<7;i++)assert.ok(Number.isFinite(pose[i]),state+' pose '+i);
   assert.ok(pose[5]>0&&pose[5]<=.55,state+' alpha '+pose[5]);
   assert.ok(Math.abs(pose[0])<=50&&Math.abs(pose[1])<=40,state+' strays from its unit');
  }
assert.ok(!bad.length,bad.join(' | '));
assert.equal(hfxCPose106('unknown',0,0,0,0),null);
const one=[],two=[];heroFxSpritesC106('wflood',.6,240,560,240,250,3,one);heroFxSpritesC106('wflood',.6,240,560,240,250,3,two);
assert.deepEqual(one,two);
console.log('Group C effect sprites checked: '+checked);
'''


class HeroFxGroupCTests(unittest.TestCase):
    def test_every_kind_is_finite_bounded_and_on_screen(self):
        source = SCRIPT % (translate(), json.dumps(textures()), json.dumps(kinds()), json.dumps(sorted(LONG)), json.dumps(STATES))
        run = subprocess.run(['node'], input=source, text=True, encoding='utf-8', capture_output=True, cwd=ROOT)
        self.assertEqual(run.returncode, 0, run.stdout + '\n' + run.stderr)
        print(run.stdout.strip())

    def test_painter_and_timelines_agree_on_textures(self):
        code = section(GROUP, PURE)
        painter = code[code.index('function heroFxPaintC106'):code.index('function hfxCCrescent106')]
        for name in textures():
            self.assertIn(f'case "{name}":', painter, name)
        used = set(re.findall(r'hfxC(?:P|Beam|Flash|Motes|Burst)106\(out,"(\w+)"', code))
        used |= {'spark', 'ring', 'smoke', 'fang', 'glow', 'rift'}
        claim = GROUP.read_text('utf-8')[GROUP.read_text('utf-8').index(PURE[1]):]
        used |= set(re.findall(r'"c:(\w+)"\]', claim)) | set(re.findall(r'"c:(\w+)",', claim))
        used = {name for name in used if name in textures() or not name[-1].isdigit()} - set(kinds())
        self.assertEqual(used - set(textures()), set())
        self.assertNotIn('$assetManager', code)

    def test_every_claimed_kind_has_a_timeline(self):
        claim = GROUP.read_text('utf-8')[GROUP.read_text('utf-8').index(PURE[1]):]
        played = set(re.findall(r'"c:([a-z]+\d?)"', claim)) - set(textures()) - {'estar'}
        played |= {f'estar{i}' for i in range(5)} | {'yult0', 'yult1', 'yult2'}
        self.assertEqual(played - set(kinds()), set())
        self.assertEqual(set(kinds()) - played, set(), 'kinds nobody plays')

    def test_claimed_native_names_come_from_the_hero_packs(self):
        names = set()
        for pack in ('nine', 'zongzi'):
            text = (ROOT / f'config/reconstruction/hero-packs-104/{pack}.json').read_text('utf-8')
            names |= set(re.findall(r'"((?:FX|E)[A-Z0-9]*_[A-Z0-9_]+)"', text))
            names |= set(re.findall(r'builtin:effect/((?:FX|E)[A-Z0-9]*_[A-Z0-9_]+)', text))
        code = GROUP.read_text('utf-8')
        native = code[code.index('function hfxCNative106'):code.index('function hfxCSequence106')]
        claimed = set(re.findall(r'name=="(\w+)"', native)) - {'SUMMON_EFF'}
        self.assertEqual(claimed - names, set())
        # Sequence keys name real effect-sequence steps.
        packs = {}
        for pack in ('nine', 'zongzi'):
            for skill in json.loads((ROOT / f'config/reconstruction/hero-packs-104/{pack}.json').read_text('utf-8'))['data']['skills']['skills']:
                packs[skill['id']] = skill
        sequence = code[code.index('function hfxCSequence106'):code.index('function hfxCStateKind106')]
        for key, step, op in re.findall(r'case "(\w+)#(\d+)#(\w+)":', sequence):
            self.assertEqual(packs[key]['model'], 'effect-sequence-v1', key)
            self.assertEqual(packs[key]['actions'][int(step)]['type'], op, key)

    def test_green_snake_cleanse_plays_once_per_recipient_per_action(self):
        from test_vital_bar_104 import method

        path = 'client/src/stages/137_Avatar.as'
        functions = []
        for name in ('hfxCNative106', 'hfxCCount106', 'hfxCEach106'):
            js = method(path, name).replace('for each(var unit in list)', 'for (var unit of list)')
            functions.append(f'const {name} = {js};')
        script = '\n'.join(functions) + """
const assert = require('assert');
const int = value => value | 0;
const played = [];
const snake = {
    abilityIndex: 1, manualOwnerActionSerial: 10, hfxCSeenSerial106: -1, hfxCSeen106: {},
    hfxCNative106, hfxCCount106, hfxCEach106, hfxCSkillKey106: () => 'green_snake_passive',
    heroFx106(kind, unit) { played.push([kind, unit.abilityIndex]); }
};
const allies = [2, 3, 4, 5].map(abilityIndex => ({abilityIndex}));
for (let action = 10; action <= 11; action++) {
    snake.manualOwnerActionSerial = action;
    for (let repeat = 0; repeat < 3; repeat++) {
        assert.equal(snake.hfxCNative106('gsnake', 'FX60_PURIFY', snake, null), true);
        assert.equal(snake.hfxCNative106('gsnake', 'FX60_PURIFY', allies[0], {targets: allies}), true);
    }
}
const once = [1, 2, 3, 4, 5].map(id => ['c:gcleanse', id]);
assert.deepEqual(played, [...once, ...once]);
"""
        run = subprocess.run(['node'], input=script, text=True, encoding='utf-8', capture_output=True, cwd=ROOT)
        self.assertEqual(run.returncode, 0, run.stdout + run.stderr)

    def test_hooks_are_synchronized(self):
        avatar = (ROOT / 'client/src/stages/137_Avatar.as').read_text('utf-8')
        self.assertIn(section(GROUP, PURE), avatar)
        self.assertIn('public function hfxCHook106(', avatar)
        skillset = (ROOT / 'client/src/stages/139_SkillSet.as').read_text('utf-8')
        # Group C's three hooks; group E reuses the public hook for "direct" and "spawn".
        group_e = skillset.count('avatar.hfxCHook106("direct"') + skillset.count('avatar.hfxCHook106("spawn"')
        self.assertEqual(skillset.count('avatar.hfxCHook106(') - group_e, 3)
        self.assertIn('if(("hfxCHook106" in avatar) && avatar.hfxCHook106("native",effect || "SUMMON_EFF",unit,', skillset)
        self.assertIn('if("hfxCHook106" in avatar) avatar.hfxCHook106("sequence",String(skillSetData.id)+"#"+index+"#"+kind,center,', skillset)
        self.assertIn('hpHealTarget.injured(hpHealAmount,1,("hfxCHook106" in avatar) && avatar.hfxCHook106("native",', skillset)
        import hashlib
        build = json.loads((ROOT / 'client/build.json').read_text('utf-8'))
        for row in build['stages']:
            if row['source'] in ('client/src/stages/137_Avatar.as', 'client/src/stages/139_SkillSet.as'):
                self.assertEqual(row['source_sha256'], hashlib.sha256((ROOT / row['source']).read_bytes()).hexdigest(), row['source'])

    def test_preview_takes_the_pure_block_verbatim(self):
        from hero_fx_preview_c_106 import harness_source
        self.assertIn(section(GROUP, PURE), harness_source())
        self.assertIn(section(CORE, HELPERS), harness_source())


if __name__ == '__main__':
    unittest.main()
