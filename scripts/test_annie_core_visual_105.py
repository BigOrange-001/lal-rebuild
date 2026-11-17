import json
import re
import subprocess
import unittest
from pathlib import Path

from test_avatar_passive import method_body

ROOT = Path(__file__).resolve().parents[1]


class AnnieCoreVisualTests(unittest.TestCase):
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
