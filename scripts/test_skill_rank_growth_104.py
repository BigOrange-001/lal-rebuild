"""Audit every generated hero skill, and execute shipped AS rank methods in Node."""
import copy
import json
from pathlib import Path
import re
import subprocess
import unittest
from unittest.mock import patch

from gateway import load_game_config
from native_skill_snapshot import _native_skill_snapshot
from skill_rank_growth_104 import apply_skill_rank_growth_104, hero_skill_references, magnitude_paths
from skill_balance_overlay import _get
from test_avatar_passive import method_body

ROOT = Path(__file__).resolve().parents[1]


def translated(source, method):
    body = method_body(source, method)
    expression = r'([\w.$]+(?:\[(?:[^\[\]\n]|\[[^\[\]\n]*\])*\])*)'
    body = re.sub(expression + r' is Array', r'Array.isArray(\1)', body)
    body = re.sub(expression + r' is (?:int|Number)', r'(typeof \1 === "number")', body)
    from test_skin_revision_native_104 import balanced
    while 'for each(' in body:
        start=body.index('for each(')
        end=balanced(body,start+8)
        left,right=body[start+9:end].split(' in ',1)
        body=body[:start]+'for ('+left+' of '+right+')'+body[end+1:]
    return body


class RankGrowthTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        with patch('skill_rank_growth_104.apply_skill_rank_growth_104', lambda d: d):
            cls.before = load_game_config(ROOT / 'config/reconstruction/full-config.json')['cfg']
        cls.cfg = load_game_config(ROOT / 'config/reconstruction/full-config.json')['cfg']
        cls.refs = hero_skill_references(cls.cfg)
        cls.factors = {sid: factor for family, factor in cls.cfg.get('hero_balance_iteration_104', {}).get('final_skill_multipliers', {}).items()
                       for sid in hero_skill_references(cls.cfg, {family})}

    def test_fiora_followup_weakness_grows_from_thirty_to_sixty_percent(self):
        sid = 'S_621130_6'
        for level in (1, 5, 10):
            actions = _native_skill_snapshot(self.cfg, sid, level)['skills']
            followup = next(a for a in actions if a[0] == 'shield_followup' and len(a) == 9)
            self.assertAlmostEqual(followup[6], .3 * (1 + (level - 1) / 9))
            self.assertIn((6,), magnitude_paths(followup))

    def test_every_magnitude_at_every_rank_and_endpoint_preservation(self):
        checked = 0
        for sid, slot in self.refs.items():
            row = self.cfg['skill'][sid]
            snapshots = [_native_skill_snapshot(self.cfg, sid, lv) for lv in range(1, 11)]
            original = _native_skill_snapshot(self.before, sid, 10 if slot == 10 else 1)['skills']
            for ai, path, first, last in row['rankGrowth104']['magnitudes']:
                for lv, snap in enumerate(snapshots, 1):
                    actual = _get(snap['skills'][ai], path)
                    self.assertAlmostEqual(actual, first * (1 + (lv - 1) / 9), places=8, msg=f'{sid} {lv} {ai} {path}')
                    checked += 1
                self.assertAlmostEqual(last, first * 2, places=10)
                # Newly exposed native constants have no original action path.
                try:
                    old = _get(original[ai], path)
                except IndexError:
                    continue
                self.assertAlmostEqual(_get(snapshots[9 if slot == 10 else 0]['skills'][ai], path), old* self.factors.get(sid,1), places=8)
            for key, growth in row['rankSettingGrowth104'].items():
                records = [(None, *growth)] if type(growth[0]) in (int, float) else growth
                for path, base, step in records:
                    for lv, snap in enumerate(snapshots, 1):
                        value = snap['nativeSettings104'][key]
                        if path:
                            for i in path:
                                value = value[i]
                        self.assertAlmostEqual(value, base * (1 + (lv - 1) / 9), places=9)
                        checked += 1
        self.assertGreater(checked, 100000)

    def test_counts_geometry_timing_and_nonhero_rows_unchanged(self):
        for sid, slot in self.refs.items():
            row = self.cfg['skill'][sid]
            old = _native_skill_snapshot(self.before, sid, 10 if slot == 10 else 1)['skills']
            new = _native_skill_snapshot(self.cfg, sid, 10 if slot == 10 else 1)['skills']
            for ai, action in enumerate(old):
                for index, value in enumerate(action):
                    if not any(p[0] == index for p in magnitude_paths(action)):
                        self.assertEqual(new[ai][index], value, (sid, ai, index))
            self.assertEqual(row.get('pl'), self.before['skill'][sid].get('pl'))
        for sid, row in self.before['skill'].items():
            if sid not in self.refs:
                self.assertEqual(self.cfg['skill'][sid], row, sid)

    def test_idempotent_no_snapshot_mutation_and_bounds(self):
        baseline = copy.deepcopy(self.cfg)
        apply_skill_rank_growth_104(self.cfg)
        self.assertEqual(self.cfg, baseline)
        for sid in self.refs:
            one = _native_skill_snapshot(self.cfg, sid, 1)
            ten = _native_skill_snapshot(self.cfg, sid, 10)
            self.assertEqual(_native_skill_snapshot(self.cfg, sid, 0), one)
            self.assertEqual(_native_skill_snapshot(self.cfg, sid, 11), ten)
        self.assertEqual(self.cfg, baseline)

    def test_real_client_rank_methods_match_all_server_snapshots(self):
        source = (ROOT/'client/src/stages/139_SkillSet.as').read_text('utf8')
        init = translated(source, 'init')
        setting = translated(source, 'getNativeSetting')
        rows, expected = {}, {}
        for sid in self.refs:
            row = self.cfg['skill'][sid]
            rows[sid] = {k: row[k] for k in ('skill', 'skillUp', 'skillUpPaths', 'rankSettingGrowth104')}
            for key in row['rankSettingGrowth104']:
                rows[sid][key] = row[key]
            expected[sid] = []
            for lv in range(1, 11):
                snap = _native_skill_snapshot(self.cfg, sid, lv)
                expected[sid].append([snap['skills'], snap.get('nativeSettings104', {})])
        script = r'''
const data=JSON.parse(require('fs').readFileSync(0,'utf8'));
const int=Math.trunc,Tools={clone:x=>JSON.parse(JSON.stringify(x))};
const GlobalData={$mConfig_skill:data.rows};let count=0;
const init=function(){with(this){/*INIT*/}};
const getNativeSetting=function(key,fallback=null){with(this){/*SETTING*/}};
for(const [sid,row] of Object.entries(data.rows))for(let lv=1;lv<=10;lv++){
 const obj={lv,skills:null,m_cooldownNum:0,activeNativeSettings:null,
 skillSetData:{id:sid,warmup:0,skills:row.skill,skillUp:row.skillUp,skillUpPaths:row.skillUpPaths}};
 init.call(obj);let settings={};for(const key of Object.keys(row.rankSettingGrowth104))settings[key]=getNativeSetting.call(obj,key);
 if(JSON.stringify([obj.skills,settings])!==JSON.stringify(data.expected[sid][lv-1]))throw Error(sid+' rank '+lv+' differs');count++;
}
console.log(JSON.stringify({client_rank_cases:count}));
'''.replace('/*INIT*/', init).replace('/*SETTING*/', setting)
        result = subprocess.run(['node', '-e', script], input=json.dumps(dict(rows=rows, expected=expected)),
                                capture_output=True, text=True, encoding='utf8', timeout=90)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(json.loads(result.stdout)['client_rank_cases'], len(self.refs)*10)
        print(result.stdout.strip())

    def test_live_compound_normal_outputs_grow_once(self):
        from test_manual_ability_oracle_103 import ManualOracleTests, HARNESS
        ManualOracleTests.setUpClass()
        selected = {}
        for sid, slot in self.refs.items():
            for action in self.cfg['skill'][sid]['skill']:
                if slot == 10 and action[:1] == ['manual_ability'] and len(action) == 4 and not action[1].startswith('skin2_'):
                    selected.setdefault(action[1], sid)
        for kind, sid in selected.items():
            events = []
            for lv in (1, 5, 10):
                snapshot = _native_skill_snapshot(self.cfg, sid, lv)
                settings = snapshot['nativeSettings104']
                action = next(a for a in snapshot['skills'] if a[:2] == ['manual_ability', kind])
                options = dict(kind=kind, scale=action[2], damage=settings['manualDamageMultiplier'], effect=settings['manualEffectMultiplier'])
                result = subprocess.run(['node', '-e', HARNESS], input=json.dumps(dict(methods=ManualOracleTests.methods, units=ManualOracleTests.units, **options)),
                                        capture_output=True, text=True, encoding='utf8', timeout=15)
                self.assertEqual(result.returncode, 0, result.stderr)
                events.append(json.loads(result.stdout)['events'])
            for row_index in range(len(events[0])):
                event = events[0][row_index]
                magnitude_index = {'hit': 2, 'heal': 2, 'shield': 2, 'buff': 4, 'summon': 3}.get(event[0])
                if magnitude_index is not None:
                    for rank_index, lv in enumerate((1, 5, 10)):
                        self.assertAlmostEqual(events[rank_index][row_index][magnitude_index], event[magnitude_index]*(1+(lv-1)/9), places=8, msg=kind)
        self.assertEqual(len(selected), 20)

    def test_compound_multiplier_does_not_scale_following_native_actions(self):
        from manual_ability_sim import SkillCompleteBattle
        from test_manual_ability_sim import unit
        class Probe(SkillCompleteBattle):
            def execute(self, owner, kind, scale, skill):
                self.observed=self._context(owner)['effect_factor']
                return True
        for lv in (1, 5, 10):
            factor=1+(lv-1)/9
            owner=unit('A_1001_6',1,1800)
            owner['skill']={'skid':'TEST','pl':[0,0,3000,0,0],
                            'skills':[['manual_ability','veigar_n',1,'FX'],['strong',.2*factor,2,'FX']],
                            'nativeSettings104':{'manualEffectMultiplier':3*factor}}
            battle=Probe([owner],[unit('A_1002_6',2,1600)],config=self.cfg)
            self.assertTrue(battle._apply_native_skill(battle.a[0],battle.b))
            self.assertAlmostEqual(battle.observed,3*factor)
            self.assertAlmostEqual(battle._buff(battle.a[0],'strong').value,.2*factor)

    def test_rank_descriptions_resolve_in_actual_client_method(self):
        source=(ROOT/'client/src/stages/139_SkillSet.as').read_text('utf8')
        method=translated(source,'getLevelInfo')
        cases=[]
        for sid in self.refs:
            row=self.cfg['skill'][sid]
            if not row.get('rankInfoTemplate'):
                continue
            for lv in (1,5,10):
                cases.append(dict(lv=lv,isSuper=False,skillSetData=dict(id=sid,info=row.get('info','')),
                                  skills=_native_skill_snapshot(self.cfg,sid,lv)['skills']))
        script=r'''
const data=JSON.parse(require('fs').readFileSync(0,'utf8')),int=Math.trunc;
const GlobalData={$mConfig_skill:data.rows};
const info=function(){with(this){/*BODY*/}};
for(const row of data.cases){let text=info.call(row);if(/\{(?:rank|scale|flat|linear):|NaN|undefined/.test(text))throw Error(row.skillSetData.id+' '+row.lv+' '+text);}
console.log(data.cases.length);
'''.replace('/*BODY*/',method)
        result=subprocess.run(['node','-e',script],input=json.dumps(dict(rows={s:self.cfg['skill'][s] for s in self.refs},cases=cases)),
                              capture_output=True,text=True,encoding='utf8',timeout=30)
        self.assertEqual(result.returncode,0,result.stderr)


if __name__ == '__main__':
    unittest.main()
