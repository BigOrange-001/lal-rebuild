"""Execute the actual AS statistics reducer with summon and lifecycle cases."""
import re
import unittest
from pathlib import Path
from test_avatar_passive import method_body
import test_playtest_client as harness

ROOT = Path(__file__).resolve().parents[1]

class BattleStatisticsTests(unittest.TestCase):
    run_js = harness.PlaytestClientTests.run_js

    def test_summons_share_owner_without_merging_duplicate_cards(self):
        source = (ROOT/'client/src/stages/137_Avatar.as').read_text('utf8')
        code = 'let statisticsRows104=[],statisticsRunning104=false; function clearEffects104() {}\n'
        for name, args in [('resetStatistics104',''),('statisticsRow104','unit'),('recordStatistics104','source,target,damage,healing')]:
            body = method_body(source,name)
            body = re.sub(r'for each\(var (\w+) in ([^)]+)\)',r'for(var \1 of \2)',body)
            code += 'function '+name+'('+args+'){'+body+'}\n'
        code += '''
const hero=()=>({team:1,avatarData:{name:'相同卡'}});
const a=hero(), b=hero(), enemy={team:2,avatarData:{name:'敌人'}};
const summon={team:1,statisticsOwner104:a};
const nested={team:1,statisticsOwner104:summon};
recordStatistics104(a,enemy,999,0);
if(statisticsRows104.length) throw Error('prebattle counted');
statisticsRunning104=true;
statisticsRow104(b);
recordStatistics104(nested,enemy,120,0);
recordStatistics104(enemy,summon,80,0);
recordStatistics104(nested,a,0,30);
recordStatistics104(a,enemy,NaN,Infinity);
const result=statisticsRows104.map(({name,team,damage,healing,taken})=>({name,team,damage,healing,taken}));
statisticsRunning104=false;
recordStatistics104(a,enemy,1000,0);
if(statisticsRow104(a).damage!==120) throw Error('postbattle counted');
resetStatistics104();
console.log(JSON.stringify({result,empty:statisticsRows104.length===0&&!statisticsRunning104}));
'''
        result=self.run_js(code)
        self.assertTrue(result['empty'])
        self.assertEqual(result['result'],[
            dict(name='相同卡',team=1,damage=0,healing=0,taken=0),
            dict(name='敌人',team=2,damage=80,healing=0,taken=120),
            dict(name='相同卡',team=1,damage=120,healing=30,taken=80)])

    def test_injury_uses_capped_actuals_and_summon_sources(self):
        source=(ROOT/'client/src/stages/137_Avatar.as').read_text('utf8')
        body=method_body(source,'injured')
        self.assertIn('Math.min(Math.max(0,param1),Math.max(0,abilityHpBefore))',body)
        self.assertLess(body.index('param1 = Math.min(param1,hpMax - hp)'),body.index('recordStatistics104(bookHealer'))
        self.assertIn('abilityDamageTaken+statisticsShield104',body)
        self.assertIn('statisticsOwner104 = owner',method_body(source,'inheritSummonPanel'))
        skill=(ROOT/'client/src/stages/139_SkillSet.as').read_text('utf8')
        self.assertIn('unit.statisticsOwner104 = avatar',skill)

if __name__=='__main__': unittest.main()
