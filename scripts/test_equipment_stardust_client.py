"""Client Equip stardust/inheritance methods match the server rules.

Executes the real ActionScript method bodies from 084_Equip.as in Node and
compares them with server/equipment_stardust.py and equipment_growth_v2.py.
"""
import json
import random
import shutil
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'server'))
sys.path.insert(0, str(ROOT / 'scripts'))

from equipment_growth_v2 import template_wash_stats, wash_stats  # noqa: E402
from equipment_stardust import alchemy_cost, decompose_yield  # noqa: E402
from test_avatar_passive import method_body  # noqa: E402

METHODS = {
    'getStar': '', 'getAddStar': '', 'getType': '', 'getPoint': 'param1=-1',
    'hasHit': '', 'hasFlee': '', 'hasCrit': '', 'hasTough': '',
    'getHit': 'param1=-1,param2=false', 'getFlee': 'param1=-1,param2=false',
    'getCrit': 'param1=-1,param2=false', 'getTough': 'param1=-1,param2=false',
    'getTemplateAffixes': '', 'getInheritAffixes': '', 'getInheritText': 'param1=null',
    'getStardustYield': '', 'getStardustAlchemyCost': '',
}
STATIC = {'getStardustForStar': 'param1,param2=0', 'getStardustBalance': ''}


def harness(cases, simple):
    source = (ROOT / 'client/src/stages/084_Equip.as').read_text('utf8')
    script = ['const int=Math.trunc;',
              'const GlobalData={$mConfig_simple:%s,$userData:{attrs:{stardust:77}}};' % json.dumps(simple),
              'const GlobalLanguageStr={getLanguageStr:n=>({30021:"命中",30022:"闪避",30023:"暴击",30024:"韧性"})[n]};',
              'const Equip={MAX_INHERIT_COUNT:3,STARDUST_ALCHEMY_MULTIPLIER:5};']
    for name, args in STATIC.items():
        script.append(f'Equip.{name}=function({args}){{{method_body(source, name)}}};')
    # Inside instance methods AS3 resolves class statics unqualified.
    script.append('const getStardustForStar=Equip.getStardustForStar,STARDUST_ALCHEMY_MULTIPLIER=5,MAX_INHERIT_COUNT=3;')
    script.append('function makeUnit(c){const u={equipData:{id:c.eid,hasAttr:k=>c.pair.includes(k)},my_data:c.item,lv:c.item.lv,'
                  'hit:c.item.new_4attrs.hit,flee:c.item.new_4attrs.flee,crit:c.item.new_4attrs.crit,tough:c.item.new_4attrs.tough,'
                  'inheritHit:c.inherit.hit,inheritFlee:c.inherit.flee,inheritCrit:c.inherit.crit,inheritTough:c.inherit.tough};')
    for name, args in METHODS.items():
        script.append(f' u.{name}=function({args}){{with(this){{{method_body(source, name)}}}}};')
    script.append(' return u;}')
    script.append('const cases=%s;' % json.dumps(cases))
    script.append('console.log(JSON.stringify(cases.map(c=>{const u=makeUnit(c);return {'
                  'template:u.getTemplateAffixes(),total:[u.getHit(-1,true),u.getFlee(-1,true),u.getCrit(-1,true),u.getTough(-1,true)],'
                  'display:[u.getHit(),u.getFlee(),u.getCrit(),u.getTough()],'
                  'yield:u.getStardustYield(),cost:u.getStardustAlchemyCost(),text:u.getInheritText(),balance:Equip.getStardustBalance()};})));')
    run = subprocess.run([shutil.which('node'), '-e', '\n'.join(script)], capture_output=True, text=True, encoding='utf-8')
    if run.returncode:
        raise AssertionError(run.stderr)
    return json.loads(run.stdout)


@unittest.skipUnless(shutil.which('node'), 'Node is required for the AS behavior harness')
class StardustClientParityTest(unittest.TestCase):
    def test_client_affixes_yield_and_cost_match_server(self):
        config = json.loads((ROOT / 'config/reconstruction/full-config.json').read_text(encoding='utf-8'))
        cfg = config['cfg']
        simple = {'equip_config': cfg['system_simple']['equip_config']}
        rng = random.Random(20261115)
        eids = [eid for eid, row in cfg['equip'].items()
                if not eid.startswith('E_6') and len(row.get('pl', [])) >= 8][:40]
        cases = []
        for eid in eids:
            definition = cfg['equip'][eid]
            pair = [k for k in definition['pl'][6:8]]
            base = int(eid.rsplit('_', 1)[1])
            extra = rng.randint(0, max(0, 8 - base))
            phase = 0 if base + extra >= 8 else rng.randint(0, 2)
            lv = rng.randint(1, 160)
            cap = int(simple['equip_config'][3]) * (base + extra) * lv
            left = rng.randint(0, cap)
            wash = {k: 0 for k in ('hit', 'flee', 'crit', 'tough')}
            wash[pair[0]] = left
            wash[pair[1]] = rng.randint(0, cap - left)
            inherit = {k: rng.choice([0, rng.randint(1, 5000)]) for k in wash}
            item = {'eid': eid, 'lv': lv, 'alchemy': [phase, extra], 'new_4attrs': wash,
                    'wash_schema_version': 1, 'inherit_4attrs': inherit, 'inherit_count': 2}
            cases.append({'eid': eid, 'pair': pair, 'item': item, 'inherit': inherit})
        results = harness(cases, simple)
        for case, got in zip(cases, results):
            item, definition = case['item'], cfg['equip'][case['eid']]
            template = template_wash_stats(item, definition, simple)
            total = wash_stats(item, definition, simple)
            keys = ('hit', 'flee', 'crit', 'tough')
            self.assertEqual(got['template'], [template[k] for k in keys], case['eid'])
            self.assertEqual(got['total'], [total[k] for k in keys], case['eid'])
            self.assertEqual(got['yield'], decompose_yield(item), case['eid'])
            self.assertEqual(got['cost'], alchemy_cost(item), case['eid'])
            for key, value in zip(keys, got['display']):
                if key in case['pair']:
                    self.assertEqual(value, template[key])
            self.assertEqual(got['balance'], 77)
        self.assertTrue(any(r['text'] for r in results))


if __name__ == '__main__':
    unittest.main()
