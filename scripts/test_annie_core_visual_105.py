import json
import re
import subprocess
import unittest
from pathlib import Path

from test_avatar_passive import method_body
from test_skin_revision_native_104 import translate

ROOT = Path(__file__).resolve().parents[1]


class AnnieCoreVisualTests(unittest.TestCase):
    def test_retaliation_announces_launch_and_impacts_every_living_enemy(self):
        script = r'''
const assert=require('node:assert/strict');
const methods={}, int=Math.trunc, Tools={toInt:int};
const Buff={LIST_DEBUFF:['burn']};
let roster=[], seen=[], skin2AnnieChainDepth=0, skin2AnnieChain=[];
const GameMap={actionDelay:0, currentMap:{
    getAliveList:team=>roster.filter(unit=>unit.team===team && unit.hp>0),
    getShowLine:line=>line,
}};
const GameMapConfig={lineToPixel:(line,offset)=>100*line+offset,posToPixel:pos=>pos};
class Point {constructor(x,y){this.length=Math.hypot(x,y)}}
const DisplayTools={getAttrs:id=>({id}),addBullet(){}};
const GameMapLayer={isFastest:false,gl:{
    infoLayer:{showSkill(){}},effectLayer:{},
    delayCall(handler,time,arg){
        if(handler===DisplayTools.addBullet){
            seen.push(['launch',time,arg.x2]);
            assert.ok(Math.abs(Math.hypot(arg.x2-arg.x1,arg.y2-arg.y1)/arg.sp-.35)<1e-9);
        }
        else seen.push(['notice',time,arg]);
    },
}};
const beginAbilityAttack=()=>({}),endAbilityAttack=()=>{};
/*METHODS*/
function cast(stun_enabled){
    seen=[];GameMap.actionDelay=1;
    const spec={cooldown:1,purify_rounds:1,debuff_rounds:2,sunder:.33,weak:.33,
                poison_ap:.5, control_rounds:1,stun_enabled};
    function enemy(id,line,hp=100){
        return {id,line,hp,offset:0,pos:10,team:2,
            addBuff(kind,...args){seen.push(['impact',GameMap.actionDelay,id,kind,...args.slice(0,2)])},
            addManualSkillDot(key,kind,damage){seen.push(['impact',GameMap.actionDelay,id,kind,damage])}};
    }
    const annie={...methods, team:1,otherTeam:2,line:0,pos:0,offset:0,hp:100,
        fightRes:{parent:true},skin2:{},manualOwnerActionSerial:0,abilityIndex:1,
        getDamage(){return 1000},s2AnnieCore(){return spec},flushParallelVisualBatch(){},
        removeAllDebuff(){seen.push(['purify',GameMap.actionDelay])}};
    roster=[annie,enemy('front',0),enemy('other lane',2),enemy('dead',1,0)];
    annie.s2AnnieStatus('burn');
    assert.deepEqual(seen.slice(0,4),[['purify',1],['notice',1,'不讲道理'],
        ['launch',1.45,0],['launch',1.45,200]]);
    assert.ok(seen.slice(4).every(row=>row[0]==='impact' && row[1]>1.45));
    for(const id of ['front','other lane']){
        const effects=seen.filter(row=>row[2]===id).map(row=>row[3]);
        assert.deepEqual(effects,stun_enabled ? ['sunder','weak','poison','stun','silence']
                                            : ['sunder','weak','poison','silence']);
    }
    return seen;
}
assert.deepEqual(cast(false),cast(true).filter(row=>row[3]!=='stun'));
'''.replace('/*METHODS*/', translate())
        result = subprocess.run(['node'], input=script, capture_output=True, text=True, encoding='utf8')
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_delayed_visual_does_not_restore_a_cleansed_status(self):
        source = (ROOT/'client/src/stages/137_Avatar.as').read_text('utf8')
        body = method_body(source, 'showBuff')
        body = re.sub(r'\bvar (\w+)\s*:\w+', r'var \1', body)
        body = re.sub(r'for each\((.*?) in (.*?)\)', r'for (\1 of Object.values(\2))', body)
        script = '''
const assert=require('node:assert/strict');
const show=function(param1){with(this){BODY}};
let seen=[],native={displayObject:'native'},dot={displayObject:'dot'};
let actor={buffs:{stun:native},manualSkillDots:{layer:{visual:dot}},m_buff:{addChild:x=>seen.push(x)}};
show.call(actor,native);show.call(actor,dot);
assert.deepEqual(seen,['native','dot']);
delete actor.buffs.stun;actor.manualSkillDots={};
show.call(actor,native);show.call(actor,dot);
assert.deepEqual(seen,['native','dot'],'pending callbacks cannot recreate cleared icons');
console.log('cleansed native and DOT visual callbacks suppressed');
'''.replace('BODY', body)
        result = subprocess.run(['node', '-e', script], capture_output=True, text=True, encoding='utf8')
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == '__main__':
    unittest.main()
