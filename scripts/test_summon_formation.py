"""Exercise the shipped movement methods and matching server formation rules."""
import json
import re
import subprocess
import sys
import unittest

from test_avatar_passive import NODE, ROOT, method_body

sys.path.insert(0, str(ROOT / 'server'))
from battle_engine import ReferenceBattle


HARNESS = r'''
const fs=require('node:fs'), vm=require('node:vm');
const input=JSON.parse(fs.readFileSync(0,'utf8')), noop=()=>{};
const units=input.units;
const map={isEnd(){return false;}, getAliveList(){return units;},
 getFinalPos(team,line,pos){return Math.max(0,Math.min(3000,pos));}};
function Tween(){this.moveTo=noop;this.scaleTo=noop;}
const context=vm.createContext({Math,Number,Tween,
 GameMap:{currentMap:map,actionDelay:0},
 GameMapLayer:{gl:{delayCall:noop,addTween:noop}},
 GameMapConfig:{MIN_SPACE_POS:200,offsetToPixel(v){return v/6;},posToPixel(v){return v/5;},sideOffset:400},
 SoundManager:{getOnlyExample(){return {playSound:noop};}}});
for(const unit of units){
 Object.assign(unit,{abilityState:{},formationOwner:null,offset:0,rangeMoveEndsAt:0,
  fightRes:{parent:{setFirst:noop}},
  getSpeed(){return this.speed;},getScale(){return 1;},resBounce:noop});
 for(const [name,body] of Object.entries(input.methods)){
  const params=name==='checkMove'?'param1,param2=0,param3=null,param4=-1,param5=false,param6=null':'targetPos';
  unit[name]=vm.runInContext('(function('+params+'){with(this){'+body+'\n}})',context);
 }
}
units[1].formationOwner=units[0];
for(const op of input.ops){
 if(op.set)Object.assign(units[op.unit],op.set);
 else {context.GameMap.currentAvatar=units[op.unit];units[op.unit].checkMove(op.forward,op.distance||0,null,-1,!!op.forced);}
}
process.stdout.write(JSON.stringify(units.map(u=>u.pos)));
'''


class FormationScenarios:
    def run_scenario(self, team, ops, behind=False):
        raise NotImplementedError

    def test_kiting_and_owner_advance_cannot_swap_order(self):
        for team in (1, 2):
            for order in ((1, 0), (0, 1)):
                ops = [{'unit': i, 'forward': i == 0}
                       for _ in range(20) for i in order]
                owner, summon = self.run_scenario(team, ops)
                self.assertGreaterEqual((owner - summon) * (1 if team == 1 else -1), 200)

    def test_explicit_displacement_and_knockback_are_unrestricted(self):
        for team in (1, 2):
            for extra in ({'distance': 900}, {'forced': True, 'distance': 900}):
                owner, summon = self.run_scenario(team, [{'unit': 1, 'forward': False, **extra}])
                self.assertLess((owner - summon) * (1 if team == 1 else -1), 0)

    def test_dead_or_other_lane_owner_does_not_block_kiting(self):
        for team in (1, 2):
            for update in ({'hp': 0}, {'line': 2}):
                owner, summon = self.run_scenario(team, [
                    {'unit': 0, 'set': update},
                    *[{'unit': 1, 'forward': False} for _ in range(4)]])
                self.assertLess((owner - summon) * (1 if team == 1 else -1), 0)

    def test_displaced_summon_is_not_teleported_or_allowed_to_retreat_further(self):
        for team in (1, 2):
            owner, summon = self.run_scenario(team, [{'unit': 1, 'forward': False}], behind=True)
            self.assertEqual(summon, 1700 if team == 1 else 1300)
            owner, summon = self.run_scenario(team, [{'unit': 1, 'forward': True}], behind=True)
            self.assertEqual(summon, 1455 if team == 1 else 1545)


@unittest.skipUnless(NODE, 'Node is required for the actual client movement methods')
class ClientSummonFormationTests(FormationScenarios, unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source = (ROOT / 'client/src/stages/137_Avatar.as').read_text(encoding='utf-8')
        cls.methods = {}
        for name in ('checkMove', 'clampSummonFormation', 'clampOwnerAdvance'):
            body = method_body(source, name)
            cls.methods[name] = re.sub(r'for each\s*\(([^)]+) in ([^)]+)\)', r'for (\1 of \2)', body)

    def run_scenario(self, team, ops, behind=False):
        summon_pos = (1700 if behind else 1000) if team == 1 else (1300 if behind else 2000)
        units = [{'team': team, 'line': 1, 'pos': 1500, 'hp': 1000, 'speed': 250},
                 {'team': team, 'line': 1, 'pos': summon_pos, 'hp': 1000, 'speed': 245}]
        result = subprocess.run([NODE, '-e', HARNESS],
                                input=json.dumps(dict(methods=self.methods, units=units, ops=ops)),
                                capture_output=True, text=True, encoding='utf-8', timeout=15)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)


class ServerSummonFormationTests(FormationScenarios, unittest.TestCase):
    def run_scenario(self, team, ops, behind=False):
        summon_pos = (1700 if behind else 1000) if team == 1 else (1300 if behind else 2000)
        units = [{'aid': 'A_1310_6', 'isme': team == 1, 'line': 1, 'pos': 1500,
                  'hp': 1000, 'hp_max': 1000, 'speed': 250, '_owner_token': 'owner'},
                 {'aid': 'A_2018_2', 'isme': team == 1, 'line': 1, 'pos': summon_pos,
                  'hp': 1000, 'hp_max': 1000, 'speed': 245, 'summon_owner_token': 'owner'}]
        battle = ReferenceBattle(units if team == 1 else [], units if team == 2 else [])
        roster = battle.a if team == 1 else battle.b
        for op in ops:
            if 'set' in op:
                roster[op['unit']].update(op['set'])
            else:
                battle._check_move(roster[op['unit']], op['forward'], op.get('distance', 0), op.get('forced', False))
        return [unit['pos'] for unit in roster]


if __name__ == '__main__':
    unittest.main()
