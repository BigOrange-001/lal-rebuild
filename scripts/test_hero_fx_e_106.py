"""Group E code-painted hero effects: run the AS timelines (types stripped) in Node and
check the painter, the claim table, the "e:" kind prefix, the state rows and the hooks.

    python scripts/test_hero_fx_e_106.py
"""
from pathlib import Path
import hashlib
import json
import re
import subprocess
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(ROOT / 'scripts')]
from test_skin_revision_native_104 import balanced
from test_dragonmancer_kaisa_native import strip_as_comments

GROUP = ROOT / 'client/src/hero_fx_e_106.aspart'
CORE = ROOT / 'client/src/hero_fx_core_106.aspart'
AVATAR = 'client/src/stages/137_Avatar.as'
SKILLSET = 'client/src/stages/139_SkillSet.as'
PURE = ('// BEGIN HFX E PURE 106', '// END HFX E PURE 106')
HELPERS = ('// BEGIN HERO FX HELPERS 106', '// END HERO FX HELPERS 106')
STATES = ['a_charge', 'a_stand', 'k_guard', 'k_ascend', 'g_grit']
# Sprites stretched between two points (bolts, tracers) may be longer than a lane is wide.
STRETCHED = {'streak', 'line'}


def section(path, marks):
    code = path.read_text('utf-8')
    return code[code.index(marks[0]):code.index(marks[1])]


def translate():
    out = []
    for code in (section(CORE, HELPERS), section(GROUP, PURE)):
        code = strip_as_comments(code)
        out += [f'const {name}={value};' for name, value in
                re.findall(r'public static const (\w+):Number = ([\d.]+);', code)]
        for match in re.finditer(r'(?:private|public) static function (\w+)\((.*?)\)\s*:\s*[\w.]+\s*\{', code, re.S):
            start = match.end() - 1
            body = code[start + 1:balanced(code, start)]
            if 'flash.' in body:
                continue  # Painting needs flash.display; the preview renders it.
            args = re.sub(r':[\w.]+', '', match[2])
            body = re.sub(r'\bvar (\w+)\s*:[\w.]+', r'var \1', body)
            out.append(f'function {match[1]}({args}){{{body}}}')
    return 'const int=v=>v|0;\n' + '\n'.join(out)


def kinds():
    code = section(GROUP, PURE)
    life = code[code.index('function heroFxLifeE106'):]
    life = life[:life.index('return 0;')]
    return re.findall(r'case "(\w+)": return', life)


def sizes():
    code = section(GROUP, PURE)
    table = code[code.index('function hfxESize106'):code.index('function heroFxPaintE106')]
    return {name: [int(w), int(h)] for name, w, h in re.findall(r'case "(\w+)": return \[(\d+),(\d+)\]', table)}


def first_argument(code, open_paren):
    """The text of a call's first argument (up to its first top-level comma)."""
    depth = 0
    quote = None
    for i in range(open_paren + 1, len(code)):
        c = code[i]
        if quote:
            if c == quote:
                quote = None
            continue
        if c == '"':
            quote = c
        elif c in '([{':
            depth += 1
        elif c in ')]}':
            if depth == 0:
                return code[open_paren + 1:i]
            depth -= 1
        elif c == ',' and depth == 0:
            return code[open_paren + 1:i]
    raise ValueError('unterminated call')


def played_kinds(code):
    """Every kind literal a heroFx106 call can play, checked to be an "e:" literal (or a ternary of them)."""
    found = []
    for match in re.finditer(r'\bheroFx106\(', code):
        arg = first_argument(code, match.end() - 1).strip()
        branches = [arg]
        if '?' in arg:
            ternary = re.fullmatch(r'\s*("[^"]*")\s*:\s*("[^"]*")\s*', arg[arg.rindex('?') + 1:])
            if not ternary:
                raise AssertionError('heroFx106 kind is not a literal ternary: ' + arg)
            branches = [ternary[1], ternary[2]]
        for branch in branches:
            if not re.fullmatch(r'"e:[a-z0-9]+"', branch):
                raise AssertionError('heroFx106 kind without the "e:" prefix: ' + arg)
            found.append(branch[3:-1])
    return found


SCRIPT = '''
const assert=require('assert');
%s
const sizes=%s,kinds=%s,states=%s,stretched=new Set(%s);
const views=[[240,560,240,250],[240,560,320,180],[240,420,240,420],[160,300,330,620],[240,250,240,560]];
let checked=0;const bad=[];const check=(ok,msg)=>{if(!ok&&bad.length<40&&!bad.some(b=>b.split(' ')[0]===msg.split(' ')[0]&&b.split(' ')[1]===msg.split(' ')[1]))bad.push(msg);};
for(const kind of kinds){
 const life=heroFxLifeE106(kind);
 assert.ok(life>0 && life<=1.2,kind+' life '+life);
 let seen=0,peak=0;
 for(const [sx,sy,tx,ty] of views){
  for(let t=0;t<=life+1e-9;t+=1/60){
   const out=[];heroFxSpritesE106(kind,t,sx,sy,tx,ty,7,out);
   peak=Math.max(peak,out.length);seen+=out.length;
   for(const p of out){
    assert.ok(p.k in sizes,kind+' texture '+p.k);
    for(const key of ['x','y','sx','sy','r','a','fy','c'])assert.ok(Number.isFinite(p[key]),kind+' '+key+' at '+t);
    check(p.a>0&&p.a<=.85+1e-9,kind+' alpha '+p.a);
    check(p.x>-120&&p.x<600&&p.y>-120&&p.y<840,kind+' off screen '+p.x+','+p.y);
    // No full-screen washes: nothing wider than about a lane.
    if(!stretched.has(p.k))check(Math.abs(p.sx)*sizes[p.k][0]<=300&&Math.abs(p.sy)*sizes[p.k][1]<=300,kind+' too big '+p.k+' '+p.sx+'x'+p.sy);
    else check(Math.abs(p.sy)*sizes[p.k][1]<=48,kind+' too thick '+p.k+' '+p.sy);
    checked++;
   }
  }
  // Faded out by the end of its life.
  const out=[];heroFxSpritesE106(kind,life,sx,sy,tx,ty,7,out);
  check(out.every(p=>p.a<.36),kind+' still bright at the end '+JSON.stringify(out.filter(p=>p.a>=.36)[0]));
 }
 assert.ok(seen>0,kind+' draws nothing');
 check(peak<=72,kind+' peak '+peak);
}
// Claimed native hits land HFX_E_HIT106 after the claim: every hit kind is brightest about then.
for(const kind of ['achain','astorm','sstab','sdagger','kbolt','kwave','kjudge','gblast','gspray','gshell','gquick']){
 const at=t=>{const out=[];heroFxSpritesE106(kind,t,240,560,240,250,7,out);return out.filter(p=>p.k==='glow'&&Math.abs(p.y-240)<30).reduce((s,p)=>s+p.a*p.sx,0);};
 check(at(HFX_E_HIT106+.03)>at(HFX_E_HIT106-.1),kind+' impact is not at the hit');
}
for(const state of states)
 for(let index=0;index<5;index++)
  for(let t=0;t<4;t+=.05){
   const pose=hfxEPose106(state,index,5,t,3);
   assert.ok(pose&&pose.length===8,state);
   for(let i=0;i<7;i++)assert.ok(Number.isFinite(pose[i]),state+' pose '+i);
   assert.ok(pose[5]>0&&pose[5]<=.55,state+' alpha '+pose[5]);
   assert.ok(Math.abs(pose[0])<=60&&Math.abs(pose[1])<=48,state+' strays from its unit');
  }
assert.ok(!bad.length,bad.join(' | '));
assert.equal(hfxEPose106('unknown',0,0,0,0),null);
const one=[],two=[];heroFxSpritesE106('achain3',.5,240,560,240,250,3,one);heroFxSpritesE106('achain3',.5,240,560,240,250,3,two);
assert.deepEqual(one,two);
// The bolt is re-struck over time but stays anchored at both ends.
const a=[],b=[];heroFxSpritesE106('achain',.5,240,560,240,250,3,a);heroFxSpritesE106('achain',.56,240,560,240,250,3,b);
assert.notDeepEqual(a.filter(p=>p.k==='line').map(p=>p.x),b.filter(p=>p.k==='line').map(p=>p.x));
console.log('Group E effect sprites checked: '+checked);
'''

CLAIMS = '''
const assert=require('assert');
%s
const int=v=>v|0;const HFX_E_FAST106=100000;
class Avatar{constructor(tag,tribe,extra){Object.assign(this,{tag,tribe,abilityIndex:tag.charCodeAt(0),hp:100,hpMax:100,pos:0,abilityState:{}},extra||{});}}
function hfxETribeOf106(unit){return unit?unit.tribe:'';}
const hfxEStateKind106=fns.hfxEStateKind106,heroFxStateE106=fns.heroFxStateE106;
let played=[];
const skill0={id:'n'},skill1={id:'c'},skillB={id:'p'};
function hero(tribe,extra){
 const me=new Avatar('hero',tribe,Object.assign({manualOwnerActionSerial:5,hfxESeen106:{},hfxESeenSerial106:-1,hfxEChainTarget106:null,hfxEChainSerial106:-1,
  hfxEGrit106:false,skill0,skill1,skillB,ctx:null},extra||{}));
 for(const key of names)me[key]=fns[key];
 me.currentAbilityAttack=()=>me.ctx;
 me.heroFx106=(kind,target,extra)=>played.push([kind,target?target.tag:null,extra||null]);
 return me;
}
const cast=(me,skill,kind,action)=>{me.ctx={owner:me,kind:kind||'active',skill:skill?Object.assign(skill,{getNativeAction:()=>action||['manual_ability','x']}):null};};
const claim=(me,event,kind,target,extra)=>me.heroFxClaimE106(event,kind,target,extra);
const kinds=played=>played.map(p=>p[0]);
const a=new Avatar('a','A_1001'),b=new Avatar('b','A_1002'),c=new Avatar('c','A_1005');

// Aurelion Sol: the chain draws each bolt from the last target and silences its native hit.
let ao=hero('A_1114');played=[];
let extra={};
assert.ok(claim(ao,'chain','1114',a,{from:ao,hop:0,solo:false}));
assert.ok(claim(ao,'native','FX_A_1114_MAGIC',a,extra));assert.equal(extra.sp,HFX_E_FAST106);
assert.ok(claim(ao,'chain','1114',b,{from:a,hop:1,solo:false}));assert.ok(claim(ao,'native','FX_A_1114_MAGIC',b,{}));
assert.ok(claim(ao,'chain','1114',c,{from:ao,hop:0,solo:true}));
assert.ok(claim(ao,'native','FX_A_1114_MAGIC',c,{}));
// A bolt whose hit never came does not silence a later hit on the same enemy.
claim(ao,'chain','1114',b,{from:ao,hop:0,solo:false});ao.manualOwnerActionSerial=6;
assert.deepEqual(kinds(played),['e:achain','e:achain','e:achain3','e:achain']);
assert.equal(played[0][2].from,ao);assert.equal(played[1][2].from,a);
// Storm descends: the star chart once, a sky bolt on every target; the six-star passive is the nova.
played=[];cast(ao,skill1);
claim(ao,'native','FX_A_1114_MAGIC',a,{});claim(ao,'native','FX_A_1114_MAGIC',b,{});
cast(ao,skillB,'passive');claim(ao,'native','FX_A_1114_MAGIC',c,{});
assert.ok(claim(ao,'cast','1114_charge',ao));assert.ok(claim(ao,'cast','1114_stand',ao));
assert.deepEqual(kinds(played),['e:acast','e:astorm','e:astorm','e:anova','e:acharge','e:astand']);
assert.ok(!claim(ao,'native','E_008',a,{}));
// Rows: the channel and the six-star charges.
let rows=[];ao.abilityState={nextStorm:[1],nextCharge:3};ao.heroFxRowsE106(rows);
assert.deepEqual(rows.map(r=>[r.key,r.count]),[['aoStand',undefined],['aoCharge',3]]);
assert.deepEqual(heroFxStateE106({key:'thunder',target:ao,count:2}),['e:star','e:star']);
assert.deepEqual(heroFxStateE106({key:'aoCharge',target:ao,count:5}).length,5);
assert.deepEqual(heroFxStateE106({key:'aoStand',target:ao}),['e:rune','e:star','e:star','e:star']);
assert.equal(heroFxStateE106({key:'thunder',target:a,count:2}),null);

// Shaco: dash, crit, backstab, mad laugh, vanish, box, clone and the passive dagger.
let shaco=hero('A_1128');played=[];cast(shaco,skill0);
assert.ok(claim(shaco,'direct','FX_S9002_DASH',shaco));assert.ok(claim(shaco,'direct','FX60_HIT',shaco));
assert.ok(claim(shaco,'native','FX_A_1128_PHYSICAL',a,{}));
assert.ok(!claim(shaco,'native','FX60_MAGIC',a,{}));
cast(shaco,skill1);assert.ok(claim(shaco,'native','FX60_STRONG',shaco,{}));assert.ok(claim(shaco,'direct','FX_S9140_FLEE',shaco));
assert.ok(claim(shaco,'spawn','SUMMON_EFF',b));assert.ok(claim(shaco,'cast','1128_box',c));
cast(shaco,skillB,'passive');assert.ok(claim(shaco,'native','FX60_MAGIC',a,{}));
assert.ok(!claim(shaco,'direct','FX60_HIT',a));assert.ok(!claim(shaco,'native','FX60_STRONG',a,{}));
assert.deepEqual(kinds(played),['e:sblink','e:sgrin','e:sstab','e:smad','e:sfade','e:sclone','e:sbox','e:sdagger']);
assert.equal(played[0][2].follow,true);

// Kayle: basics, ascended lane basics, the judgement and the heal; her ward and ascension rows.
let kayle=hero('A_1120');played=[];
assert.ok(claim(kayle,'native','E_008',a,{}));
cast(kayle,null,'basic');assert.ok(claim(kayle,'native','FX_A_1120_MAGIC',a,{}));
cast(kayle,skill0);assert.ok(claim(kayle,'native','FX_A_1120_MAGIC',b,{}));assert.ok(claim(kayle,'native','FX60_HEAL',c,{}));
assert.deepEqual(kinds(played),['e:kbolt','e:kwave','e:kjudge','e:kmend']);
assert.deepEqual(heroFxStateE106({key:'sixBatchKayleGuard105',target:kayle}),['e:wing','e:wing']);
assert.deepEqual(heroFxStateE106({key:'sixBatchKayle105',target:kayle,count:3}),['e:ring','e:feather','e:feather','e:feather']);
assert.equal(heroFxStateE106({key:'sixBatchKayleGuard105',target:a}),null);

// Graves: buckshot spreads over every target, Collateral Damage is one shell then shrapnel.
let graves=hero('A_1053');played=[];
assert.ok(claim(graves,'native','E_008',a,{}));
cast(graves,skill0);assert.ok(claim(graves,'native','FX_A_1053_PHYSICAL',a,{targets:[a,b]}));
assert.ok(claim(graves,'native','FX60_STEEL',graves,{buff:{round:99}}));assert.ok(claim(graves,'native','FX60_STRONG',graves,{buff:{round:99}}));
assert.ok(graves.hfxEGrit106);
assert.deepEqual(kinds(played),['e:gblast','e:gfire','e:gspray','e:gspray','e:ggrit']);
graves.manualOwnerActionSerial=6;played=[];cast(graves,skill1);
claim(graves,'native','FX_A_1053_PHYSICAL',a,{targets:[a]});claim(graves,'native','FX_A_1053_PHYSICAL',b,{targets:[b,c]});
assert.deepEqual(kinds(played),['e:gshell','e:gfrag','e:gfrag']);
graves.manualOwnerActionSerial=7;played=[];cast(graves,skill0,'active',['manual_ability','six_next_graves_n']);
claim(graves,'native','FX_A_1053_PHYSICAL',a,{targets:[a]});assert.ok(claim(graves,'direct','FX60_STRONG',graves));
assert.deepEqual(kinds(played),['e:gquick','e:ggrit']);
rows=[];graves.heroFxRowsE106(rows);assert.deepEqual(rows.map(r=>r.key),['gGrit']);
let six=hero('A_1053');six.abilityState={nextGravesBasic:.15};rows=[];six.heroFxRowsE106(rows);assert.deepEqual(rows.map(r=>r.key),['gGrit']);
assert.deepEqual(heroFxStateE106({key:'gGrit',target:graves}),['e:smoke','e:shell']);

// Nobody else's events, and nothing for strangers.
const other=hero('A_1001');
for(const [event,kind] of [['native','E_008'],['native','FX_A_1114_MAGIC'],['chain','1114'],['cast','1128_box'],['direct','FX_S9002_DASH'],['spawn','SUMMON_EFF']])
 assert.ok(!claim(other,event,kind,a,{}),event+' '+kind);
rows=[];other.heroFxRowsE106(rows);assert.equal(rows.length,0);
console.log('Group E claims checked');
'''


def js_method(path, name):
    from test_vital_bar_104 import method
    js = method(path, name)
    js = re.sub(r'for each\((var )?(\w+) in ', r'for (\1\2 of ', js)
    js = re.sub(r'(\b[\w.]+) is Avatar\b', r'(\1 instanceof Avatar)', js)
    return js.replace(' as Avatar', '')


class HeroFxGroupETests(unittest.TestCase):
    def test_every_kind_is_finite_bounded_and_on_screen(self):
        source = SCRIPT % (translate(), json.dumps(sizes()), json.dumps(kinds()), json.dumps(STATES), json.dumps(sorted(STRETCHED)))
        run = subprocess.run(['node'], input=source, text=True, encoding='utf-8', capture_output=True, cwd=ROOT)
        self.assertEqual(run.returncode, 0, run.stdout + '\n' + run.stderr)
        print(run.stdout.strip())

    def test_marks_stay_clear_of_the_health_bar(self):
        source = translate() + '\nconst out={};for(const s of %s)for(let i=0;i<5;i++)for(let t=0;t<4;t+=.05){const p=hfxEPose106(s,i,5,t,3);' \
            'const top=p[1]-Math.max(Math.abs(p[2]),Math.abs(p[3]))*0.65*96/2;out[s]=Math.min(out[s]===undefined?1e9:out[s],top);}' \
            'console.log(JSON.stringify(out));' % json.dumps(STATES)
        run = subprocess.run(['node'], input=source, text=True, encoding='utf-8', capture_output=True, cwd=ROOT)
        self.assertEqual(run.returncode, 0, run.stderr)
        for state, top in json.loads(run.stdout).items():
            self.assertGreaterEqual(top, -50, state)

    def test_every_call_uses_the_group_prefix(self):
        # The core plays nothing for a kind without "<group>:", which once silenced groups A and B.
        code = strip_as_comments(GROUP.read_text('utf-8'))
        played = played_kinds(code)
        self.assertGreater(len(played), 25)
        self.assertEqual(set(played) - set(kinds()), set(), 'played kinds without a timeline')
        self.assertEqual(set(kinds()) - set(played), set(), 'kinds nobody plays')
        for ident in re.findall(r'ids\.push\("([^"]*)"\)|"(\w:\w+)"\]', code):
            for name in ident:
                if name:
                    self.assertTrue(name.startswith('e:'), name)
        for other in ('heroFxA106(', 'heroFxB106(', 'hfxD'):
            self.assertNotIn(other, code)

    def test_claims_play_the_right_kinds(self):
        names = ['heroFxClaimE106', 'hfxEChain106', 'hfxECast106', 'hfxENative106', 'hfxEDirect106', 'hfxECount106',
                 'hfxESlot106', 'hfxENativeKind106', 'heroFxRowsE106']
        statics = ['hfxEStateKind106', 'heroFxStateE106']
        functions = [f'fns.{name} = {js_method(AVATAR, name)};' for name in names + statics]
        known = set(kinds())
        prelude = 'const fns={};const names=%s;\n%s' % (json.dumps(names), '\n'.join(functions))
        script = CLAIMS % prelude
        script = script.replace("const kinds=played=>played.map(p=>p[0]);",
                                "const known=new Set(%s);const kinds=played=>played.map(p=>{assert.ok(p[0].startsWith('e:')&&known.has(p[0].slice(2)),p[0]);return p[0];});"
                                % json.dumps(sorted(known)))
        # Static helpers run with no unit bound.
        script = script.replace('const hfxEStateKind106=fns.hfxEStateKind106,heroFxStateE106=fns.heroFxStateE106;',
                                'const hfxEStateKind106=(r)=>fns.hfxEStateKind106.call(globalThis,r),heroFxStateE106=(r)=>fns.heroFxStateE106.call(globalThis,r);')
        run = subprocess.run(['node'], input=script, text=True, encoding='utf-8', capture_output=True, cwd=ROOT)
        self.assertEqual(run.returncode, 0, run.stdout + run.stderr)

    def test_painter_and_timelines_agree_on_textures(self):
        code = section(GROUP, PURE)
        painter = code[code.index('function heroFxPaintE106'):code.index('function hfxECrescent106')]
        for name in sizes():
            self.assertIn(f'case "{name}":', painter, name)
        used = set(re.findall(r'hfxE(?:P|Beam|Flash|Motes|Burst|Gather)106\(out,"(\w+)"', code))
        used |= {'spark', 'ring', 'smoke', 'star', 'line'}
        claim = GROUP.read_text('utf-8')[GROUP.read_text('utf-8').index(PURE[1]):]
        used |= set(re.findall(r'"e:(\w+)"\]', claim)) | set(re.findall(r'"e:(\w+)",', claim)) | set(re.findall(r'ids\.push\("e:(\w+)"\)', claim))
        used -= set(kinds())
        self.assertEqual(used - set(sizes()), set())
        self.assertEqual(set(sizes()) - used - {'glow', 'dot', 'streak'}, set(), 'painted but never drawn')
        self.assertNotIn('$assetManager', code)

    def test_hooks_are_synchronized(self):
        avatar = (ROOT / AVATAR).read_text('utf-8')
        self.assertIn(section(GROUP, PURE), avatar)
        self.assertIn('if(heroFxClaimC106(event,kind,target,extra)) return true;\n         if(heroFxClaimE106(event,kind,target,extra)) return true;', avatar)
        self.assertIn('if(heroFxClaimD106(event,kind,target,extra)) return true;\n         // Shared looks', avatar)
        for hook in ('heroFxClaim106("cast","1114_charge",this) ? "" : "FX_A_1114_MAGIC");',
                     'heroFxClaim106("cast","1114_stand",this) ? "" : effect);',
                     'heroFxClaim106("cast","1128_box",box) ? "" : effect);',
                     'if(param6 && !heroFxClaim106("direct",param6,this))',
                     '         heroFxRowsE106(result);\n         return result;',
                     'heroFxClaim106("chain","1114",target,{from:from,hop:i,solo:targets.length==1});',
                     'var heroFxClaimed106:Object={targets:param1,buff:param7};',
                     'laneWave:_loc41_.laneWave,sp:heroFxClaimed106.sp};'):
            self.assertGreaterEqual(avatar.count(hook), 1, hook)
        self.assertEqual(avatar.count('heroFxClaim106("cast","1114_charge",this)'), 2)
        self.assertEqual(avatar.count('heroFxClaim106("native",param5'), 1)
        skillset = (ROOT / SKILLSET).read_text('utf-8')
        self.assertEqual(skillset.count('avatar.hfxCHook106("direct",param1,param2)'), 1)
        self.assertEqual(skillset.count('avatar.hfxCHook106("spawn",'), 1)
        build = json.loads((ROOT / 'client/build.json').read_text('utf-8'))
        for row in build['stages']:
            if row['source'] in (AVATAR, SKILLSET):
                self.assertEqual(row['source_sha256'], hashlib.sha256((ROOT / row['source']).read_bytes()).hexdigest())
        sources = (ROOT / 'scripts/sync_hero_fx_106.py').read_text('utf-8')
        self.assertLess(sources.index("'hero_fx_d_106.aspart'"), sources.index("'hero_fx_e_106.aspart'"))

    def test_preview_takes_the_pure_block_verbatim(self):
        from hero_fx_preview_e_106 import harness_source
        self.assertIn(section(GROUP, PURE), harness_source())
        self.assertIn(section(CORE, HELPERS), harness_source())


if __name__ == '__main__':
    unittest.main()
