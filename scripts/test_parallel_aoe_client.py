"""Execute the native animation cursor without changing damage/RNG order."""
import shutil,unittest
from test_skill_books_client import method
import test_playtest_client as harness

@unittest.skipUnless(shutil.which('node'),'Node required for AS behavior checks')
class ParallelAoeTests(unittest.TestCase):
    run_js=harness.PlaytestClientTests.run_js
    def run_case(self,code):
        script='''const int=v=>Math.trunc(Number(v))||0;
const GameMap={actionDelay:1};let active={};const currentAbilityAttack=()=>active;
const unit={parallelVisualBatches:[]};const targets=Array.from({length:6},(_,id)=>({id}));'''
        for name,args in {'beginParallelVisualBatch':'','setParallelVisualWave':'batch,wave,step=.15',
                          'prepareParallelVisualTarget':'target,hit','endParallelVisualBatch':'batch',
                          'playParallelAttackTween':'','flushParallelVisualBatch':''}.items():
            script+=method('137_Avatar.as',name,args)
        return self.run_js(script+code)

    def test_six_waves_hit_all_six_targets_together_and_pose_once_per_wave(self):
        r=self.run_case('''const batch=unit.beginParallelVisualBatch();let starts=[],poses=0,order=[];
for(let wave=0;wave<6;wave++)for(const target of targets){unit.prepareParallelVisualTarget(target,true);
starts.push(GameMap.actionDelay);poses+=Number(unit.playParallelAttackTween());order.push(target.id);GameMap.actionDelay+=.4;}
unit.endParallelVisualBatch(batch);console.log(JSON.stringify({starts,poses,order,end:GameMap.actionDelay,stack:unit.parallelVisualBatches.length}));''')
        for wave in range(6):
            for value in r['starts'][wave*6:wave*6+6]:self.assertAlmostEqual(value,1+.4*wave)
        self.assertEqual(r['poses'],6);self.assertEqual(r['order'],list(range(6))*6)
        self.assertAlmostEqual(r['end'],3.4);self.assertEqual(r['stack'],0)

    def test_target_major_legacy_combo_keeps_damage_order_and_aligns_each_hit_index(self):
        r=self.run_case('''const batch=unit.beginParallelVisualBatch();let starts=[],poses=0,order=[];
for(const target of targets)for(let wave=0;wave<6;wave++){unit.setParallelVisualWave(batch,wave,.15);
unit.prepareParallelVisualTarget(target,true);starts.push(GameMap.actionDelay);order.push([target.id,wave]);
poses+=Number(unit.playParallelAttackTween());GameMap.actionDelay+=.4+.15;}
unit.endParallelVisualBatch(batch);console.log(JSON.stringify({starts,poses,order,end:GameMap.actionDelay}));''')
        for target in range(6):
            for wave,value in enumerate(r['starts'][target*6:target*6+6]):self.assertAlmostEqual(value,1+.15*wave)
        self.assertEqual(r['order'],[[t,w] for t in range(6) for w in range(6)])
        self.assertEqual(r['poses'],6);self.assertAlmostEqual(r['end'],2.3)

    def test_reactions_do_not_rewind_and_the_longest_animation_is_preserved(self):
        r=self.run_case('''const original=active,batch=unit.beginParallelVisualBatch();
unit.prepareParallelVisualTarget(targets[0],true);GameMap.actionDelay+=.4;
active={reaction:true};unit.prepareParallelVisualTarget(targets[1],true);const reactionStart=GameMap.actionDelay;
GameMap.actionDelay+=1;active=original;unit.prepareParallelVisualTarget(targets[2],true);
const secondStart=GameMap.actionDelay;GameMap.actionDelay+=.4;unit.endParallelVisualBatch(batch);
console.log(JSON.stringify([reactionStart,secondStart,GameMap.actionDelay]));''')
        for actual,expected in zip(r,[1.4,1,2.4]):self.assertAlmostEqual(actual,expected)

    def test_unbatched_chain_and_error_cleanup_keep_their_original_cursor(self):
        r=self.run_case('''unit.prepareParallelVisualTarget(targets[0],true);GameMap.actionDelay+=.4;
unit.prepareParallelVisualTarget(targets[1],true);const chainEnd=GameMap.actionDelay;
const batch=unit.beginParallelVisualBatch();try{unit.prepareParallelVisualTarget(targets[0],true);
GameMap.actionDelay+=.7;throw Error('stop');}catch(e){}finally{unit.endParallelVisualBatch(batch);}
console.log(JSON.stringify([chainEnd,GameMap.actionDelay,unit.parallelVisualBatches.length]));''')
        self.assertAlmostEqual(r[0],1.4);self.assertAlmostEqual(r[1],2.1);self.assertEqual(r[2],0)

    def test_native_group_executor_preserves_target_major_damage_and_group_total(self):
        body=method('139_SkillSet.as','executeParallelHits',
                    'targets,hitCount,coefficients,damageType,effect,actionIndex,castRange,banStand,preDots,preBurns,interval,targetCap=-1')
        body=body.replace('new Vector.<Avatar>()','[]')
        r=self.run_case('''const avatar=unit,damageShareTotal=(i,c)=>c*2,damageShareWeight=(c,s)=>c/s;
let calls=[];for(const target of targets)target.hp=10000;
unit.attackAimList=function(one,type,shared,aoe,fx,ban,buff,range,weight){
this.prepareParallelVisualTarget(one[0],true);calls.push([one[0].id,GameMap.actionDelay,shared*weight]);
GameMap.actionDelay+=.4;return shared*weight*100;};'''+body+'''
const total=unit.executeParallelHits(targets,6,[.3],3,'FX',0,3000,false,[],[],.15,3);
console.log(JSON.stringify({total,calls,end:GameMap.actionDelay,stack:unit.parallelVisualBatches.length}));''')
        self.assertAlmostEqual(r['total'],540)
        self.assertEqual([row[0] for row in r['calls']],[0]*6+[1]*6+[2]*6)
        for target in range(3):
            for wave,row in enumerate(r['calls'][target*6:target*6+6]):
                self.assertAlmostEqual(row[1],1+wave*.15)
                self.assertAlmostEqual(row[2],.3)
        self.assertAlmostEqual(r['end'],2.3)
        self.assertEqual(r['stack'],0)

if __name__=='__main__':unittest.main()
