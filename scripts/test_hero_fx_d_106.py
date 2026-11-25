"""Group D code-painted hero effects: run the AS timelines (types stripped) in Node and
check the painter, the claim table, the "d:" kind prefix and the hooks.

    python scripts/test_hero_fx_d_106.py
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

GROUP = ROOT / 'client/src/hero_fx_d_106.aspart'
CORE = ROOT / 'client/src/hero_fx_core_106.aspart'
AVATAR = 'client/src/stages/137_Avatar.as'
PURE = ('// BEGIN HFX D PURE 106', '// END HFX D PURE 106')
HELPERS = ('// BEGIN HERO FX HELPERS 106', '// END HERO FX HELPERS 106')
# Ultimates, the rebirth and lane-wide casts may run to 1.8 s; everything else stays within 1.2 s.
LONG = {'gverdict', 'asolo', 'rmoon', 'nfield', 'nstorm', 'ncore', 'nreborn', 'fswarm', 'ffear', 'ffear2',
        'elion', 'karrive'}
STATES = ['g_guard', 'a_charm', 'r_awake', 'r_dance', 'n_cold', 'n_frost', 'n_core', 'f_crows', 'e_command',
          'e_bear', 'e_summon', 'k_phase', 'k_record', 'k_res']


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
    life = code[code.index('function heroFxLifeD106'):]
    life = life[:life.index('return 0;')]
    return re.findall(r'case "(\w+)": return', life)


def sizes():
    code = section(GROUP, PURE)
    table = code[code.index('function hfxDSize106'):code.index('function heroFxPaintD106')]
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
    """Every kind literal a heroFx106 call can play, checked to be a "d:" literal (or a ternary of them)."""
    found = []
    for match in re.finditer(r'\bheroFx106\(', code):
        arg = first_argument(code, match.end() - 1).strip()
        # cond ? "d:a" : "d:b" -- the branches after the last top-level "?".
        branches = [arg]
        if '?' in arg:
            ternary = re.fullmatch(r'\s*("[^"]*")\s*:\s*("[^"]*")\s*', arg[arg.rindex('?') + 1:])
            if not ternary:
                raise AssertionError('heroFx106 kind is not a literal ternary: ' + arg)
            branches = [ternary[1], ternary[2]]
        for branch in branches:
            if not re.fullmatch(r'"d:[a-z0-9]+"', branch):
                raise AssertionError('heroFx106 kind without the "d:" prefix: ' + arg)
            found.append(branch[3:-1])
    return found


SCRIPT = '''
const assert=require('assert');
%s
const sizes=%s,kinds=%s,long=new Set(%s),states=%s;
const views=[[240,560,240,250],[240,560,320,180],[240,420,240,420],[160,300,330,620],[240,250,240,560]];
let checked=0;const bad=[];const check=(ok,msg)=>{if(!ok&&bad.length<40&&!bad.some(b=>b.split(' ')[0]===msg.split(' ')[0]&&b.split(' ')[1]===msg.split(' ')[1]))bad.push(msg);};
for(const kind of kinds){
 const life=heroFxLifeD106(kind);
 assert.ok(life>0 && life<=(long.has(kind)?1.8:1.2),kind+' life '+life);
 let seen=0,peak=0;
 for(const [sx,sy,tx,ty] of views){
  for(let t=0;t<=life+1e-9;t+=1/60){
   const out=[];heroFxSpritesD106(kind,t,sx,sy,tx,ty,7,out);
   peak=Math.max(peak,out.length);seen+=out.length;
   for(const p of out){
    assert.ok(p.k in sizes,kind+' texture '+p.k);
    for(const key of ['x','y','sx','sy','r','a','fy','c'])assert.ok(Number.isFinite(p[key]),kind+' '+key+' at '+t);
    check(p.a>0&&p.a<=.85+1e-9,kind+' alpha '+p.a);
    check(p.x>-120&&p.x<600&&p.y>-120&&p.y<840,kind+' off screen '+p.x+','+p.y);
    // No full-screen washes: nothing wider than about a lane.
    if(p.k!=='streak')check(Math.abs(p.sx)*sizes[p.k][0]<=300&&Math.abs(p.sy)*sizes[p.k][1]<=300,kind+' too big '+p.k+' '+p.sx+'x'+p.sy);
    checked++;
   }
  }
  // Faded out by the end of its life.
  const out=[];heroFxSpritesD106(kind,life,sx,sy,tx,ty,7,out);
  check(out.every(p=>p.a<.36),kind+' still bright at the end '+JSON.stringify(out.filter(p=>p.a>=.36)[0]));
 }
 assert.ok(seen>0,kind+' draws nothing');
 check(peak<=72,kind+' peak '+peak);
}
for(const state of states)
 for(let index=0;index<3;index++)
  for(let t=0;t<4;t+=.05){
   const pose=hfxDPose106(state,index,3,t,3);
   assert.ok(pose&&pose.length===8,state);
   for(let i=0;i<7;i++)assert.ok(Number.isFinite(pose[i]),state+' pose '+i);
   assert.ok(pose[5]>0&&pose[5]<=.55,state+' alpha '+pose[5]);
   assert.ok(Math.abs(pose[0])<=60&&Math.abs(pose[1])<=48,state+' strays from its unit');
  }
assert.ok(!bad.length,bad.join(' | '));
assert.equal(hfxDPose106('unknown',0,0,0,0),null);
const one=[],two=[];heroFxSpritesD106('gverdict',.6,240,560,240,250,3,one);heroFxSpritesD106('gverdict',.6,240,560,240,250,3,two);
assert.deepEqual(one,two);
console.log('Group D effect sprites checked: '+checked);
'''

# Marks sit on the card; nothing may reach into the health bar (-58..-50 above the centre).
MARK_SIZES = {'g_guard': 'crest', 'a_charm': 'heart', 'r_dance': 'moon', 'n_cold': 'flake', 'f_crows': 'crow',
              'e_command': 'cracker', 'k_phase': 'disc', 'k_res': 'dot', 'n_core': 'crystal'}

CLAIMS = '''
const assert=require('assert');
%s
%s
const int=v=>v|0;
let played=[];
function unit(tag,extra){return Object.assign({tag,abilityIndex:tag.charCodeAt(0),hp:100,hpMax:100,pos:0,skin2:{}},extra||{});}
function hero(family,extra){
 const me=unit('hero',Object.assign({family,manualOwnerActionSerial:5,hfxDSeen106:{},hfxDSeenSerial106:-1,hfxDPhase106:false,hfxDPhaseSerial106:-1,
  hfxDImpact106:.2,hfxDImpactSerial106:-1,hfxDPetHeal106:-1,hfxDRevive106:[],hfxDDrained106:[],skin2Depth:0,lane:[]},extra||{}));
 for(const key of names)me[key]=fns[key];
 me.s2Family=()=>me.family;me.s2Pet=()=>me.pet||null;me.s2Lane=()=>me.lane;
 me.s2LiveMark=(target,key)=>!!(target.skin2[key]);
 me.heroFx106=(kind,target,extra)=>played.push([kind,target?target.tag:null,extra||null]);
 return me;
}
const claim=(me,event,kind,target,extra)=>me.heroFxClaimD106(event,kind,target,extra);
const kinds=played=>played.map(p=>p[0]);
const a=unit('a'),b=unit('b'),c=unit('c');

// Garen.
let g=hero(1201);played=[];
assert.ok(claim(g,'strike','1201',a));assert.ok(claim(g,'strike','1201_ult',b));
assert.ok(claim(g,'shield','1201',g));assert.ok(claim(g,'shield','1201',a));assert.ok(claim(g,'pulse','guard',a));
assert.ok(claim(g,'cast','1201_purge',b,{allies:[g,a,c]}));assert.ok(!claim(g,'heal','1201',a));
assert.deepEqual(kinds(played),['d:glion','d:gverdict','d:gmane','d:gaegis','d:gvow','d:gpurge','d:gpurge','d:gpurge']);

// Ahri: song, solo, charm, heals; the encore runs nested in the death handler.
let ahri=hero(1207);played=[];
claim(ahri,'strike','1207',a);claim(ahri,'strike','1207',b);claim(ahri,'heal','1207',c);claim(ahri,'strike','1207_ult',a);
claim(ahri,'pulse','charmed',a);claim(ahri,'shield','1207_overflow',c);
ahri.skin2Depth=1;claim(ahri,'heal','1207',c);claim(ahri,'strike','1207',b);
assert.deepEqual(kinds(played),['d:anote','d:anote','d:aheal','d:asolo','d:acharm','d:aoverflow','d:aencore','d:aencorehit']);
assert.equal(played[1][2].delay,.1);

// Riven: step one dashes in for two cuts, step three ends on the moon slam, the finale wave is castless.
let riven=hero(1210,{skin2:{castSkill:{},dance:1}});played=[];
claim(riven,'strike','1210',a);claim(riven,'strike','1210',a);
assert.deepEqual(kinds(played),['d:rdash','d:rcut0','d:rcut1']);
riven.manualOwnerActionSerial=6;riven.skin2.dance=0;played=[];
for(let i=0;i<3;i++)claim(riven,'strike','1210',a);
assert.deepEqual(kinds(played),['d:rcut0','d:rcut1','d:rfinal']);
riven.skin2.castSkill=null;a.pos=1000;b.pos=2000;riven.pos=0;played=[];
claim(riven,'strike','1210',a);claim(riven,'strike','1210',b);
assert.deepEqual(kinds(played),['d:rwave','d:rwhit','d:rwhit']);
assert.ok(played[2][2].delay>played[1][2].delay);
riven.skin2.castSkill={};played=[];claim(riven,'strike','1210_ult',a);claim(riven,'strike','1210_ult',b);
claim(riven,'shield','1210',riven);claim(riven,'heal','1210',riven);
assert.deepEqual(kinds(played),['d:rmoon','d:rawake','d:rawake','d:rshield','d:rleech']);

// Anivia: a chilled target shatters; the hatching core stuns the chilled, the field ticks the rest.
let anivia=hero(1216,{skin2:{castSkill:{}}});played=[];
b.skin2.cold={owner:anivia};
claim(anivia,'strike','1216',a);claim(anivia,'strike','1216',b);claim(anivia,'pulse','cold',a);
claim(anivia,'strike','1216_ult',a);
anivia.skin2.castSkill=null;anivia.skin2.eggUntil=7;claim(anivia,'pulse','rebirth');
anivia.manualOwnerActionSerial=7;anivia.lane=[a,b];claim(anivia,'pulse','rebirth');
claim(anivia,'strike','1216',b);claim(anivia,'strike','1216',a);
assert.deepEqual(kinds(played),['d:nfeather','d:nshatter','d:nchill','d:nfield','d:nstorm','d:ncore','d:nreborn','d:nburst','d:ntick']);

// Fiddlesticks: the soul wisps come from the drained, the lurking entry is the bigger fright.
let fiddle=hero(1218,{skin2:{castSkill:{}}});played=[];
claim(fiddle,'strike','1218',a);claim(fiddle,'strike','1218',b);claim(fiddle,'heal','1218',fiddle);
fiddle.skin2.lastHurt=4;claim(fiddle,'strike','1218_ult',a);
fiddle.manualOwnerActionSerial=9;claim(fiddle,'strike','1218_ult',a);
fiddle.skin2.castSkill=null;claim(fiddle,'strike','1218',b);claim(fiddle,'shield','1218',fiddle);
assert.deepEqual(kinds(played),['d:fdrain','d:fdrain','d:fsoul','d:fsoul','d:fswarm','d:ffear','d:fswarm','d:ffear2','d:fpeck','d:fguard']);
assert.equal(played[2][2].from,a);assert.equal(played[3][2].from,b);

// Annie: crackers; the lion dance only when Tibbers is summoned, not when he is healed.
const bear=unit('bear');let annie=hero(1221,{skin2:{castSkill:{}},pet:bear});bear.skin2.bearOwner=annie;played=[];
claim(annie,'strike','1221',a);claim(annie,'strike','1221',b);claim(annie,'strike','1221_ult',a);claim(annie,'strike','1221_ult',b);
assert.deepEqual(kinds(played),['d:ecracker','d:epop','d:elion','d:eroar','d:eslam','d:eslam']);
annie.manualOwnerActionSerial=6;played=[];
claim(annie,'heal','1221',bear);claim(annie,'strike','1221_ult',a);
annie.skin2.castSkill=null;claim(annie,'strike','1221',a);claim(annie,'shield','1221',annie);
assert.deepEqual(kinds(played),['d:efeast','d:eroar','d:eslam','d:ecommand','d:eguard']);
assert.equal(played[1][2].from,bear);
const cub=hero(0);cub.skin2.bearOwner=annie;played=[];assert.ok(claim(cub,'pulse','bear'));assert.deepEqual(kinds(played),['d:egrow']);

// Ekko: out and back; after Chronobreak the next Timewinder opens with the phase strike.
let ekko=hero(1140,{skin2:{castSkill:{}}});played=[];
claim(ekko,'strike','1140',a);claim(ekko,'strike','1140',a);
ekko.skin2Depth=1;assert.ok(claim(ekko,'strike','1140',a));ekko.skin2Depth=0;
claim(ekko,'pulse','time_rings',a);claim(ekko,'shield','1140',ekko);
assert.deepEqual(kinds(played),['d:kblade','d:kback','d:kpop','d:kbubble']);
assert.equal(played[2][2].delay,ekko.hfxDImpact106);
ekko.manualOwnerActionSerial=6;played=[];
claim(ekko,'pulse','time',null,{lane:1,pos:300});claim(ekko,'pulse','time',null,{lane:0,pos:900});
claim(ekko,'heal','1140',ekko);claim(ekko,'strike','1140_ult',a);claim(ekko,'strike','1140_ult',b);
ekko.manualOwnerActionSerial=7;claim(ekko,'strike','1140',a);claim(ekko,'strike','1140',a);claim(ekko,'strike','1140',a);
assert.deepEqual(kinds(played),['d:kfade','d:karrive','d:kmend','d:kchrono','d:kchrono','d:kphase','d:kblade','d:kback']);
assert.equal(played[1][2].lane,0);

// Nobody else's events.
assert.ok(!claim(hero(1206),'strike','1206',a));assert.ok(!claim(g,'pulse','cleanse',a));assert.ok(!claim(g,'cast','1228_ult',a));
const life=%s;
for(const name of %s)assert.ok(life[name]>0,name);
console.log('Group D claims checked');
'''


class HeroFxGroupDTests(unittest.TestCase):
    def test_every_kind_is_finite_bounded_and_on_screen(self):
        source = SCRIPT % (translate(), json.dumps(sizes()), json.dumps(kinds()), json.dumps(sorted(LONG)), json.dumps(STATES))
        run = subprocess.run(['node'], input=source, text=True, encoding='utf-8', capture_output=True, cwd=ROOT)
        self.assertEqual(run.returncode, 0, run.stdout + '\n' + run.stderr)
        print(run.stdout.strip())

    def test_marks_stay_clear_of_the_health_bar(self):
        source = translate() + '\nconst out={};for(const s of %s)for(let i=0;i<3;i++)for(let t=0;t<4;t+=.05){const p=hfxDPose106(s,i,3,t,3);' \
            'const top=p[1]-Math.max(Math.abs(p[2]),Math.abs(p[3]))*0.65*96/2;out[s]=Math.min(out[s]===undefined?1e9:out[s],top);}' \
            'console.log(JSON.stringify(out));' % json.dumps(sorted(MARK_SIZES))
        run = subprocess.run(['node'], input=source, text=True, encoding='utf-8', capture_output=True, cwd=ROOT)
        self.assertEqual(run.returncode, 0, run.stderr)
        for state, top in json.loads(run.stdout).items():
            self.assertGreaterEqual(top, -50, state)

    def test_every_call_uses_the_group_prefix(self):
        # The core plays nothing for a kind without "<group>:", which once silenced groups A and B.
        code = strip_as_comments(GROUP.read_text('utf-8'))
        played = played_kinds(code)
        self.assertGreater(len(played), 40)
        self.assertEqual(set(played) - set(kinds()), set(), 'played kinds without a timeline')
        self.assertEqual(set(kinds()) - set(played), set(), 'kinds nobody plays')
        # Persistent ids carry the prefix too.
        for ident in re.findall(r'ids\.push\("([^"]*)"\)|"(\w:\w+)"\]', code):
            for name in ident:
                if name:
                    self.assertTrue(name.startswith('d:'), name)
        self.assertNotIn('heroFxA106(', code)
        self.assertNotIn('heroFxB106(', code)

    def test_claims_play_the_right_kinds(self):
        from test_vital_bar_104 import method
        names = ['heroFxClaimD106', 'hfxDStrike106', 'hfxDPulse106', 'hfxDCast106', 'hfxDCare106', 'hfxDCount106']
        functions = []
        for name in names:
            js = method(AVATAR, name)
            js = re.sub(r'for each\((var )?(\w+) in ', r'for (\1\2 of ', js)
            functions.append(f'fns.{name} = {js};')
        life = {kind: 1 for kind in kinds()}
        script = CLAIMS % ('const fns={};const names=%s;' % json.dumps(names), '\n'.join(functions),
                           json.dumps(life), json.dumps(sorted(kinds())))
        # Every kind recorded by the mock must be a known group D kind.
        script = script.replace("const kinds=played=>played.map(p=>p[0]);",
                                "const known=new Set(%s);const kinds=played=>played.map(p=>{assert.ok(p[0].startsWith('d:')&&known.has(p[0].slice(2)),p[0]);return p[0];});"
                                % json.dumps(kinds()))
        run = subprocess.run(['node'], input=script, text=True, encoding='utf-8', capture_output=True, cwd=ROOT)
        self.assertEqual(run.returncode, 0, run.stdout + run.stderr)

    def test_painter_and_timelines_agree_on_textures(self):
        code = section(GROUP, PURE)
        painter = code[code.index('function heroFxPaintD106'):code.index('function hfxDCrescent106')]
        for name in sizes():
            self.assertIn(f'case "{name}":', painter, name)
        used = set(re.findall(r'hfxD(?:P|Beam|Flash|Motes|Burst|Gather)106\(out,"(\w+)"', code))
        used |= {'spark', 'ring', 'smoke', 'star', 'crow'}
        claim = GROUP.read_text('utf-8')[GROUP.read_text('utf-8').index(PURE[1]):]
        used |= set(re.findall(r'"d:(\w+)"\]', claim)) | set(re.findall(r'"d:(\w+)",', claim)) | set(re.findall(r'ids\.push\("d:(\w+)"\)', claim))
        used -= set(kinds())
        self.assertEqual(used - set(sizes()), set())
        self.assertNotIn('$assetManager', code)

    def test_hooks_are_synchronized(self):
        avatar = (ROOT / AVATAR).read_text('utf-8')
        self.assertIn(section(GROUP, PURE), avatar)
        self.assertIn('if(heroFxClaimD106(event,kind,target,extra)) return true;\n         // Shared looks', avatar)
        self.assertEqual(avatar.count('heroFxClaim106("cast","1201_purge",target,{allies:allies});for each(unit in allies) unit.addBuff("purify",1);'), 1)
        self.assertEqual(avatar.count('{heroFxClaim106("shield","1207_overflow",target);target.addBuff("shield",2,overheal*'), 1)
        build = json.loads((ROOT / 'client/build.json').read_text('utf-8'))
        for row in build['stages']:
            if row['source'] == AVATAR:
                self.assertEqual(row['source_sha256'], hashlib.sha256((ROOT / AVATAR).read_bytes()).hexdigest())
        sources = (ROOT / 'scripts/sync_hero_fx_106.py').read_text('utf-8')
        self.assertLess(sources.index("'hero_fx_c_106.aspart'"), sources.index("'hero_fx_d_106.aspart'"))

    def test_preview_takes_the_pure_block_verbatim(self):
        from hero_fx_preview_d_106 import harness_source
        self.assertIn(section(GROUP, PURE), harness_source())
        self.assertIn(section(CORE, HELPERS), harness_source())


if __name__ == '__main__':
    unittest.main()
