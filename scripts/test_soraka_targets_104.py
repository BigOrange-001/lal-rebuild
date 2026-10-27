"""Execute the real client group-binding method after healing changes HP order."""
import re
import unittest
from pathlib import Path
from test_avatar_passive import method_body
from test_playtest_client import PlaytestClientTests

class SorakaTargetsTests(unittest.TestCase):
    run_js=PlaytestClientTests.run_js

    def test_followup_reuses_healed_target_and_excludes_dead_members(self):
        source=(Path(__file__).resolve().parents[1]/'client/src/stages/139_SkillSet.as').read_text('utf8')
        body=method_body(source.replace(': Vector.<Avatar>',': Object'),'applyActionTargetLinks')
        body=body.replace('new Vector.<Avatar>()','[]').replace(' is String'," === ObjectStringMarker")
        body=body.replace('!(_loc2_[param2] === ObjectStringMarker)',"typeof _loc2_[param2] !== 'string'")
        body=re.sub(r'(param4\[_loc3_\]) is Vector\.<Avatar>',r'Array.isArray(\1)',body)
        script='''const unit={skillSetData:{actionTargetGroups:['ally','ally','ally']},
          applyActionTargetLock:x=>x,
          selectAndCapActionTargets:(x,i)=>x.slice().sort((a,b)=>a.hp-b.hp).slice(0,i===2?99:1)};
        unit.bind=function(param1,param2,param3,param4){with(this){'''+body+'''}};
        const a={id:'hurt',hp:10},b={id:'healthy',hp:60};const groups={};
        const first=unit.bind([a,b],0,[],groups);a.hp=100;
        const purify=unit.bind([a,b],1,[],groups);
        a.hp=0;const dead=unit.bind([a,b],1,[],groups);
        const multi={ally:[a,b]};const living=unit.bind([a,b],2,[],multi);
        console.log(JSON.stringify([first.map(x=>x.id),purify.map(x=>x.id),dead,living.map(x=>x.id)]));'''
        self.assertEqual(self.run_js(script),[['hurt'],['hurt'],[],['healthy']])

if __name__=='__main__':unittest.main()
