"""Exercise the real AS state descriptors; visuals must never mutate gameplay."""
import json,re,subprocess,unittest
from pathlib import Path
from test_skin_revision_native_104 import balanced,translate,runtime_data
from build_native_effects_104 import PROFILES,STATE_NAMES
ROOT=Path(__file__).resolve().parents[1]
class EffectsTests(unittest.TestCase):
 def test_state_lifetimes_and_ownership(self):
  source=(ROOT/'client/src/battle_effects_104.aspart').read_text('utf8')
  a=source.index('      private function fxState104()');start=source.index('{',a);body=source[start+1:balanced(source,start)]
  body=re.sub(r'\bvar (\w+)\s*:\w+',r'var \1',body).replace('state is Avatar','state instanceof Avatar')
  while 'for each(' in body:
   a=body.index('for each(');b=balanced(body,a+8);left,right=body[a+9:b].split(' in ',1)
   body=body[:a]+'for ('+left+' of '+right+')'+body[b+1:]
  fixture=(ROOT/'scripts/skin_revision_fixture.js').read_text('utf8').split('let cases=0;')[0]
  fixture=fixture.replace('/*METHODS*/',translate()+'\nmethods.fxState104=function(){with(this){'+body+'}};')
  fixture=fixture.replace('/*RUNTIME_DATA*/',json.dumps(runtime_data(),ensure_ascii=False))
  fixture+='''
function Avatar(){}
function prepare(u){u.abilitySerial=1;u.manualBattleStacks={};u.manualTimedStacks=[];return u}
let {a,b,c,ally}=fresh(1140);roster.forEach(prepare);
a.s2Mark(b,'wanted',1);assert(b.fxState104().some(x=>x.kind==='wanted'));
a.manualOwnerActionSerial+=2;assert(!b.fxState104().some(x=>x.kind==='wanted'));
a.s2Mark(b,'cold',2);b.skin2ClearDebuffs();assert(!b.fxState104().some(x=>x.kind==='cold'));
a.skin2.previous={line:2,pos:777};let r=a.fxState104().find(x=>x.key==='record');assert.equal(r.lane,2);assert.equal(r.pos,777);
a.skin2.eggs=[{line:0,pos:300,ready:a.manualOwnerActionSerial+1}];assert(a.fxState104().some(x=>x.kind==='egg'));
a.manualOwnerActionSerial++;assert(a.fxState104().some(x=>x.kind==='egg_ready'));
a.skin2.eggs=[];assert(!a.fxState104().some(x=>x.kind==='egg_ready'));
a.skin2.ball=ally;assert.equal(a.fxState104().find(x=>x.key==='ball').target,ally);
ally.line=2;assert(!a.fxState104().some(x=>x.key==='ball'));ally.line=a.line;
a.skin2.guarding=ally;a.skin2.guardUsed=false;assert(a.fxState104().some(x=>x.key==='guarding'));
a.skin2.guardUsed=true;assert(!a.fxState104().some(x=>x.key==='guarding'));
b.skin2['rings_'+a.abilityIndex]={count:2};assert(b.fxState104().some(x=>x.kind==='time_rings'&&x.count===2));
a.hp=0;assert(!b.fxState104().some(x=>x.kind==='time_rings'));assert.equal(a.fxState104().length,0);a.hp=10000;
a.abilityState.guard={charges:0,until:4};assert(!a.fxState104().some(x=>x.key==='guard'));
a.abilityState.counter={left:1,until:0};assert(!a.fxState104().some(x=>x.key==='counter'));
a.skin2.frost={lane:1,end:a.manualOwnerActionSerial};assert(!a.fxState104().some(x=>x.key==='frost'));
a.skin2.frost.end++;assert(a.fxState104().some(x=>x.key==='frost'&&x.span===3001));
a.manualTimedStacks=[{expiresAt:a.manualOwnerActionSerial-1},{expiresAt:a.manualOwnerActionSerial}];assert.equal(a.fxState104().find(x=>x.key==='timedGrowth').count,1);
let before=JSON.stringify({hp:a.hp,state:a.abilityState,serial:a.manualOwnerActionSerial});a.fxState104();assert.equal(JSON.stringify({hp:a.hp,state:a.abilityState,serial:a.manualOwnerActionSerial}),before);
console.log('18 visual lifetime, owner, ground-position and read-only checks passed');
'''
  p=subprocess.run(['node'],input=fixture,cwd=ROOT,text=True,capture_output=True,encoding='utf8')
  self.assertEqual(p.returncode,0,p.stdout+p.stderr);print(p.stdout)
 def test_art_and_runtime_wiring(self):
  names={'c'+str(i) for i in range(32)}
  self.assertEqual(len(PROFILES),50)
  for p in PROFILES.values():
   for part in p['parts']:
    self.assertIn(part['id'],names)
    self.assertGreater(part['life'],0)
    self.assertIn(part['at'],('source','target','flight'))
  avatar=(ROOT/'client/src/stages/137_Avatar.as').read_text('utf8')
  layer=(ROOT/'client/src/stages/177_GameMapLayer.as').read_text('utf8')
  self.assertIn('Avatar.advanceEffects104(_loc2_);',layer)
  self.assertIn('Avatar.clearEffects104();',layer)
  self.assertIn('GameMapLayer.gl.delayCall(fxSpawn104,GameMap.actionDelay',avatar)
  self.assertIn('fxStrike104(target);',avatar)
  runtime=(ROOT/'client/src/native_effect_runtime_104.aspart').read_text('utf8')
  self.assertNotIn('Math.random',runtime);self.assertNotIn('Random.',runtime)
  self.assertIn('fxPulseCount104>=48',runtime)
  self.assertIn('battle!==GameMap.currentMap',runtime)
  self.assertIn('epoch!=fxEpoch104',runtime)
  self.assertNotIn('new TextField',runtime)
  self.assertNotIn('new Quad',runtime)
  self.assertNotIn('fxArt104',avatar)
  self.assertNotIn('effectKinds',avatar)
  self.assertNotRegex(runtime,r'"e\d{3}"')
  self.assertNotIn('DragonBones',runtime)
  self.assertIn('app:/assets/effects/custom104/',runtime)
  self.assertIn('onRestore',runtime)
  for id in re.findall(r'"(c\d+)"',runtime):self.assertIn(id,names)
 def test_all_special_states_have_custom_visuals(self):
  source=(ROOT/'client/src/native_effect_runtime_104.aspart').read_text('utf8')
  a=source.index('function fxPersistent104');start=source.index('{',a);body=source[start+1:balanced(source,start)]
  body=re.sub(r'\bvar (\w+)\s*:\w+',r'var \1',body)
  rows=[{'key':{'time':'record','aura_heal':'aura','aura_guard':'aura'}.get(k,k),'kind':k,'count':3} for k in STATE_NAMES]
  script='const int=Math.trunc;function pick(row){'+body+'}\nconst rows='+json.dumps(rows)+';for(const r of rows){const ids=pick(r);if(!ids.length||ids.some(x=>!/^c\\d+$/.test(x)||+x.slice(1)>=32))throw Error(r.kind)}console.log(rows.length+" state kinds covered");'
  p=subprocess.run(['node'],input=script,text=True,capture_output=True,encoding='utf8')
  self.assertEqual(p.returncode,0,p.stdout+p.stderr);print(p.stdout)
if __name__=='__main__':unittest.main()
