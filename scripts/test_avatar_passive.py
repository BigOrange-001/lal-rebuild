"""Execute Avatar's actual action/passive methods with presentation stubs.

Only ActionScript type syntax is removed for Node. This tests the call path,
cooldown and trigger gates, not Flash rendering or the complete game runtime.
Node is optional; the tests are skipped when it is unavailable.
"""
import json
import re
import shutil
import subprocess
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
NODE = shutil.which('node')


def method_body(source, name):
    signature = re.search(r'function\s+' + re.escape(name) + r'\s*\([^)]*\)\s*:\s*(?:\w+|\*)\s*\{', source)
    if signature is None:
        raise ValueError(f'Missing Avatar method: {name}')
    start = signature.end()
    tokens = re.compile(r'//[^\n]*|/\*[\s\S]*?\*/|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|[{}]')
    depth = 1
    for token in tokens.finditer(source, start):
        if token.group() == '{':
            depth += 1
        elif token.group() == '}':
            depth -= 1
            if depth == 0:
                body = source[start:token.start()]
                body = re.sub(r'\s+as\s+(?:Vector\.<\w+>|\w+)', '', body)
                body = re.sub(r'(\bfunction\s*(?:\w+)?\s*\([^)]*\))\s*:\s*\w+', r'\1', body)
                # Only declarations carry types. A broad colon matcher also
                # erases the else arm of ordinary ternary expressions.
                return re.sub(r'(\bvar\s+\w+)\s*:\s*(?:Vector\.<\w+>|\w+|\*)', r'\1', body)
    raise ValueError(f'Unclosed Avatar method: {name}')


HARNESS = r'''
const fs = require('node:fs');
const vm = require('node:vm');
const input = JSON.parse(fs.readFileSync(0, 'utf8'));
const options = input.options;
const calls = {casts: 0, ticks: 0, starts: 0, ends: 0, attacks: 0, active: 0, moves: 0};
const noop = () => {};
const enemies = [{hp: 1000, line: 1, team: 2}];
const map = {
  winnerList: [options.laneEnded ? 1 : 0, 0],
  isEnd(line = -1) { return !!options.battleEnded || (line >= 0 && this.winnerList[line] !== 0); },
  getAliveList() { return enemies; },
  startAction() { calls.starts++; },
  endAction: noop
};
const gl = {
  juggler: {removeTweens: noop}, addTween: noop,
  delayCall(fn) { if (fn === map.endAction) calls.ends++; }
};
const context = vm.createContext({
  GameMap: {currentMap: map, actionDelay: 0},
  GameMapLayer: {gl}, GameMapConfig: {LINE_POS: 3000},
  GlobalData: {$userData: {}, skillBoo: !!options.directPassive},
  GameMapTools: {gameTrace: noop}, trace: noop,
  SoundManager: {getOnlyExample() { return {playSound: noop}; }},
  Tween: function() { this.scaleTo = noop; this.fadeTo = noop; this.animate = noop; },
  Math, Number
});
const passive = options.noPassive ? null : {
  isModEffectSequence(){return false;},
  cd: options.directPassive ? -1 : (options.warmup || 0),
  getCastRange() { return options.range || 4000; },
  cooldown() { calls.ticks++; this.cd = Math.max(-1, this.cd - 1); },
  checkUse() {
    if (this.cd >= 0 || !enemies.some(enemy => enemy.hp > 0)) return false;
    calls.casts++; return true;
  }
};
const unit = {
  hp: options.dead ? 0 : 1000, line: 0, team: 1, otherTeam: 2,
  id: 'A_1226_6', manualFocusTarget: null,
  avatarData: {skill_diff: 18}, buffs: options.guarded ? {stun: {}} : {},
  skill0: null, skill1: null, skill2: null, skillB: passive,
  fightRes: {parent: null},
  advanceManualOwnerAction: noop, getScale() { return 1; },
  emitModEvent: noop,
  refreshIcon: noop, getTeamHp: noop, abilityTurnStart() { return false; },
  checkBuff() { return false; }, getEffectiveActionType() { return 2; },
  checkSkill() { calls.active++; return false; },
  checkAttack() { calls.attacks++; return enemies[0]; },
  checkMove() { calls.moves++; return false; },
  checkDangerous() { return false; }, getSortOnFun() { return null; }
};
for (const [name, body] of Object.entries(input.methods)) {
  unit[name] = vm.runInContext('(function() { with (this) {' + body + '\n} })', context);
}
const admitted = options.directPassive ? unit.checkSkillB() : unit.checkAction();
process.stdout.write(JSON.stringify({...calls, admitted: admitted === true}));
'''


@unittest.skipUnless(NODE, 'Node is needed for the ActionScript control-flow harness')
class AvatarPassivePathTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        source = (ROOT / 'client/src/stages/137_Avatar.as').read_text(encoding='utf-8')
        cls.methods = {name: method_body(source, name) for name in
                       ('checkAction', 'checkBuffOfSkillB', 'checkSkillB')}

    def run_path(self, **options):
        options.setdefault('laneEnded', True)
        result = subprocess.run([NODE, '-e', HARNESS],
                                input=json.dumps({'methods': self.methods, 'options': options}),
                                capture_output=True, text=True, encoding='utf-8', timeout=15)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def test_finished_lane_still_casts_global_passive_on_other_lane(self):
        result = self.run_path()
        self.assertTrue(result['admitted'])
        self.assertEqual(result['casts'], 1)
        self.assertEqual(result['ticks'], 1)
        self.assertEqual(result['ends'], 1)
        self.assertEqual((result['attacks'], result['active'], result['moves']), (0, 0, 0))

    def test_finished_lane_still_rejects_lane_local_passive(self):
        result = self.run_path(range=3000)
        self.assertFalse(result['admitted'])
        self.assertEqual((result['casts'], result['ticks'], result['starts']), (0, 0, 0))

    def test_finished_lane_without_passive_is_skipped(self):
        result = self.run_path(noPassive=True)
        self.assertFalse(result['admitted'])
        self.assertEqual(result['starts'], 0)

    def test_global_passive_respects_opening_cooldown(self):
        result = self.run_path(warmup=1)
        self.assertTrue(result['admitted'])
        self.assertEqual((result['ticks'], result['casts']), (1, 0))

    def test_global_passive_respects_the_existing_buff_trigger(self):
        result = self.run_path(guarded=True)
        self.assertTrue(result['admitted'])
        self.assertEqual(result['casts'], 0)

    def test_dead_owner_cannot_act(self):
        result = self.run_path(dead=True)
        self.assertFalse(result['admitted'])
        self.assertEqual((result['casts'], result['starts']), (0, 0))

    def test_finished_battle_cannot_start_another_turn(self):
        result = self.run_path(laneEnded=False, battleEnded=True)
        self.assertFalse(result['admitted'])
        self.assertEqual((result['casts'], result['starts']), (0, 0))

    def test_finished_battle_cannot_cast_an_event_passive(self):
        result = self.run_path(battleEnded=True, directPassive=True)
        self.assertEqual(result['casts'], 0)


if __name__ == '__main__':
    unittest.main()
