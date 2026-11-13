"""Run actual AS bar geometry and delayed visual snapshots with display stubs."""
from pathlib import Path
import re
import subprocess
import unittest

from test_skin_revision_native_104 import balanced

ROOT = Path(__file__).resolve().parents[1]


def method(path, name):
    source = (ROOT / path).read_text('utf8')
    tokens = re.compile(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|//[^\n]*|/\*[\s\S]*?\*/')
    source = tokens.sub(lambda m: '' if m[0].startswith(('//','/*')) else m[0], source)
    match = re.search(r'function '+name+r'\((.*?)\)\s*:\s*\w+\s*\{', source, re.S)
    start = match.end()-1
    body = source[start+1:balanced(source,start)]
    args = re.sub(r':(?:\w+|\*)', '', match[1])
    body = re.sub(r'\bvar (\w+)\s*:(?:\w+|\*)', r'var \1', body)
    body = body.replace('function():void', 'function()')
    return 'function('+args+'){with(this){'+body+'}}'


PRELUDE = '''
const assert=require('assert');
class Rectangle{constructor(x,y,width,height){Object.assign(this,{x,y,width,height})}}
class Tween{fadeTo() {}}
const Starling={juggler:{add(){},removeTweens(){}}};
const GameMapLayer={isFastest:false,gl:null},GameMap={actionDelay:2};
function sprite(){return {x:0,scaleX:1,children:[],addChild(c){this.children.push(c)},flatten(){},visible:true}}
function Sprite(){return sprite()}
const Tools={newQuad:(width,height,x,y,color)=>({width,height,x,y,color,visible:true})};
function bar(){return {
 m_per:1,m_shieldRate:0,m_middle:{width:86,height:16,x:0,y:-1,pivotX:43,pivotY:8},
 m_top:{height:21},m_middleSpr:sprite(),m_topSpr:sprite(),m_shieldSpr:sprite(),refresh,
 m_allSpr:sprite(),m_quarterSpr:null,m_quarterMarks104:[],refreshQuarterMarks104,
 setHealthValues104(h,m){this.healthNumbers=[h,m]}
}}
function widths(b){return [b.m_middleSpr.clipRect.width*b.m_middleSpr.scaleX,
 b.m_shieldSpr.clipRect.width,86-(b.m_shieldSpr.clipRect.x+43+b.m_shieldSpr.clipRect.width)]}
''' + '\nconst refreshQuarterMarks104='+method('client/src/stages/178_ProgressBar.as','refreshQuarterMarks104')+';'


class VitalBarTests(unittest.TestCase):
    def run_js(self, script):
        result = subprocess.run(['node'], input=script, text=True, capture_output=True, encoding='utf8')
        self.assertEqual(result.returncode, 0, result.stdout+result.stderr)
        print(result.stdout.strip())

    def test_native_geometry_and_transitions(self):
        refresh = method('client/src/stages/178_ProgressBar.as','refresh')
        self.run_js('const refresh='+refresh+';'+PRELUDE+'''
for(const [hp,shield,expected] of [
 [2/3,1/3,[57,29,0]], [1,1/3,[65,21,0]], [1/3,1/3,[29,28,29]],
 [1,0,[86,0,0]], [.5,0,[43,0,43]], [0,1,[0,0,86]],
 [.2,10,[2,84,0]], [NaN,Infinity,[0,0,86]], [-1,-1,[0,0,86]]
]){
 let b=bar();b.refresh(hp,true,shield);let actual=widths(b);
 actual.forEach((n,i)=>assert(Math.abs(n-expected[i])<1e-8,`${hp},${shield}: ${actual}`));
 assert.equal(b.m_shieldSpr.visible,expected[1]>0);
 assert.equal(b.m_per,Number.isFinite(hp)?Math.max(0,Math.min(1,hp)):0,'combat callers see actual HP ratio');
 assert(Math.abs(b.m_middleSpr.x-43*b.m_middleSpr.scaleX+43)<1e-8,'native left edge stays fixed');
}
for(const fastest of [false,true]){
 GameMapLayer.isFastest=fastest;
 let b=bar();b.refresh(.5,true,0);assert.deepEqual(widths(b),[43,0,43]);
 b.refresh(.5,false,1);assert.deepEqual(widths(b),[29,57,0],'same HP + added shield reflows');
 b.refresh(.5,false,.2);assert.deepEqual(widths(b),[43,17,26],'partial absorption reflows');
 b.refresh(.5,false,0);assert.deepEqual(widths(b),[43,0,43],'expiry or dispel restores native HP scale');
 b.refresh(1,false,0);assert.deepEqual(widths(b),[86,0,0]);
}
console.log('Native HP/shield/empty widths, overflow, death and fast playback passed');
''')

    def test_quarter_marks_compress_with_overflow_for_both_teams(self):
        source = 'client/src/stages/178_ProgressBar.as'
        code = 'const refresh='+method(source,'refresh')+';'+PRELUDE
        self.run_js(code+'''
for(const team of [1,2])for(const maximum of [500,10000,50000,250000,100000000]){
 let b=bar();b.team=team;b.hpMax=maximum;
 function marks(){return b.m_quarterMarks104.filter(m=>m.visible)}
 function positions(){return marks().map(m=>m.x+m.width/2+43)}
 function near(actual,expected){assert.equal(actual.length,expected.length);actual.forEach((x,i)=>assert(Math.abs(x-expected[i])<1e-8,`${actual} vs ${expected}`))}
 b.refresh(1,true,0);near(positions(),[21.5,43,64.5]);
 assert.strictEqual(b.m_allSpr.children.at(-1),b.m_quarterSpr,'ticks cover both HP and shield');
 assert.equal(b.m_middleSpr.children.length,0,'no duplicate HP-only grid');
 b.refresh(.05,false,.30);near(positions(),[21.5]);
 assert(Math.abs(positions()[0]-.05*86-.20*86)<1e-8,'5% HP + 30% shield: first mark is 20% of max HP into shield');
 b.refresh(.05,false,.20);near(positions(),[],'no mark at the exact fill endpoint');
 b.refresh(.3,false,.3);near(positions(),[21.5,43]);
 b.refresh(1,false,1/3);near(positions(),[16.125,32.25,48.375,64.5,80.625]);
 b.refresh(1,false,1);near(positions(),[10.75,21.5,32.25,43,53.75,64.5,75.25]);
 assert(marks().every(m=>m.width===1),'overflow compresses line width with its positions');
 b.refresh(.05,false,0);near(positions(),[]);
 b.refresh(0,false,1);near(positions(),[],'death hides shield and all marks');
 for(const shield of [10,1e6,1e100,1e308]){
  b.refresh(.05,false,shield);assert(marks().length<30,'extreme shields cannot allocate an unbounded tick grid');
  assert(marks().every(m=>Number.isFinite(m.x)&&m.x>=-43&&m.x<43));
 }
 assert(b.m_quarterMarks104.length<30,'pooled tick allocation remains bounded');
 b.refresh(1,false,0);near(positions(),[21.5,43,64.5]);
 assert(marks().every(m=>m.color===0x111111&&m.width===2),'native dark emphasis restored after shield expires');
}
console.log('Continuous 25%-of-max-HP grid across health/shield, overflow and expiry passed for both teams');
''')

    def test_delayed_frames_capture_hp_max_hp_and_shield_together(self):
        avatar = 'client/src/stages/137_Avatar.as'
        code = ('const refresh='+method('client/src/stages/178_ProgressBar.as','refresh')+';'+PRELUDE+
                'const queue='+method(avatar,'queueVitalBar104')+';'+
                'const render='+method(avatar,'refreshVitalBar104')+';')
        self.run_js(code+'''
let frames=[];GameMapLayer.gl={delayCall(fn,delay,...args){frames.push({fn,delay,args})}};
let owner={hp:200,hpMax:300,shieldPool:100,mBloodSpr:bar(),shieldValue104(){return this.shieldPool}};
owner.refreshVitalBar104=render.bind(owner);owner.queueVitalBar104=queue.bind(owner);
owner.queueVitalBar104();
owner.shieldPool=50;owner.queueVitalBar104(3);
owner.hp=150;owner.hpMax=600;owner.shieldPool=0;owner.queueVitalBar104(4);
assert.deepEqual(frames.map(f=>f.args),[[200,300,100],[200,300,50],[150,600,0]],'future settlements cannot leak into earlier frames');
assert.deepEqual(frames.map(f=>f.delay),[2,3,4]);
frames[0].fn(...frames[0].args);assert.deepEqual(widths(owner.mBloodSpr),[57,29,0]);
assert.deepEqual(owner.mBloodSpr.healthNumbers,[200,300],'HP label excludes the shield snapshot');
frames[1].fn(...frames[1].args);assert.deepEqual(widths(owner.mBloodSpr),[57,15,14]);
frames[2].fn(...frames[2].args);assert.deepEqual(widths(owner.mBloodSpr),[22,0,64]);
owner.mBloodSpr=null;owner.queueVitalBar104();assert.equal(frames.length,3);frames[0].fn(...frames[0].args);
owner.mBloodSpr=bar();owner.refreshVitalBar104(0,0,10);assert.deepEqual(widths(owner.mBloodSpr),[0,0,86]);
console.log('Timestamped HP/max-HP/shield playback and missing display guards passed');
''')

    def test_saved_checkbox_and_health_only_overlay(self):
        path = 'client/src/stages/178_ProgressBar.as'
        names = ['showHealthValues104','setHealthValuesVisible104','setHealthValues104',
                 'updateHealthLabel104','onHealthBarAdded104','onHealthBarRemoved104']
        code = 'const refresh='+method(path,'refresh')+';'+PRELUDE
        for name in names:
            code += 'const '+name+'Body='+method(path,name)+';'
        code += 'const toggleBody='+method('client/src/stages/151_PanelHelpSetting.as','toggleHealthValues104')+';'
        self.run_js(code+'''
const stored=new Map([['music',{music:1,sound:0}]]),listeners=new Set();let writes=0;
const LocalStore={getItemObj:k=>stored.get(k),setItemObj(k,v){stored.set(k,v);writes++}};
const GlobalData={$mEventDispatcher:{addEventListener(e,fn){listeners.add(fn)},removeEventListener(e,fn){listeners.delete(fn)},dispatchEventWith(e){for(const fn of listeners)fn()}}};
const GlobalTextStyle={getTextField(text,fontSize,color,align,width,height){return {text,fontSize,color,align,width,height,autoScale:true,touchable:false}}};
const preference={healthValuesLoaded104:false,healthValuesVisible104:false,HEALTH_VALUES_KEY104:'health-pref',HEALTH_VALUES_EVENT104:'health-event'};
preference.show=showHealthValues104Body.bind(preference);preference.set=setHealthValuesVisible104Body.bind(preference);
const showHealthValues104=()=>preference.show(),ProgressBar={showHealthValues104,setHealthValuesVisible104:enabled=>preference.set(enabled)};
let unit={m_healthValue104:0,m_healthMaximum104:0,m_healthLabel104:null,m_middle:{width:86,height:16,x:0,y:-1,pivotX:43,pivotY:8},m_allSpr:sprite(),HEALTH_VALUES_EVENT104:'health-event'};
for(const [name,fn] of Object.entries({setHealthValues104:setHealthValues104Body,updateHealthLabel104:updateHealthLabel104Body,onHealthBarAdded104:onHealthBarAdded104Body,onHealthBarRemoved104:onHealthBarRemoved104Body}))unit[name]=fn.bind(unit);
unit.onHealthBarAdded104();unit.setHealthValues104(1564298,2283741);
assert.equal(unit.m_healthLabel104,null,'default unchecked');
let panel={mDisposed:false,mHealthCheckmark104:{visible:false}};
toggleBody.call(panel);assert(panel.mHealthCheckmark104.visible);assert.equal(unit.m_healthLabel104.text,'1564298/2283741');
assert.equal(unit.m_healthLabel104.color,0xffffff);assert.equal(unit.m_healthLabel104.align,'center');assert.equal(unit.m_healthLabel104.vAlign,'center');assert(unit.m_healthLabel104.autoScale);
assert.equal(unit.m_healthLabel104.x,-43);assert.equal(unit.m_healthLabel104.width,86);
assert.strictEqual(unit.m_allSpr.children.at(-1),unit.m_healthLabel104,'overlay above shield and compressed HP');
unit.m_shieldRate=100;unit.setHealthValues104(1564298,2283741);assert.equal(unit.m_healthLabel104.text,'1564298/2283741','shield never enters either number');
unit.setHealthValues104(1,2000000000);assert.equal(unit.m_healthLabel104.text,'1/2000000000');
toggleBody.call(panel);assert(!unit.m_healthLabel104.visible);assert(!panel.mHealthCheckmark104.visible);
unit.setHealthValues104(-10,100);toggleBody.call(panel);assert.equal(unit.m_healthLabel104.text,'0/100');assert(unit.m_healthLabel104.visible);
preference.healthValuesLoaded104=false;preference.healthValuesVisible104=false;assert(preference.show(),'choice survives a fresh preference load');
assert.deepEqual(stored.get('music'),{music:1,sound:0},'independent of sound/music preferences');
let before=writes;panel.mDisposed=true;toggleBody.call(panel);assert.equal(writes,before,'disposed settings ignore clicks');
unit.onHealthBarRemoved104();assert.equal(listeners.size,0,'removed combat bars unsubscribe');
console.log('Saved checkbox, live show/hide, exact health-only overlay and listener cleanup passed');
''')


if __name__ == '__main__':
    unittest.main()
