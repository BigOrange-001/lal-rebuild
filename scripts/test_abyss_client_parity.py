"""Replay the 27 backend fixtures using maintained AS method bodies in Node.

Only syntax is translated. AIR rendering and scheduling are stubs; this is a
settlement-method comparison, not an Android or whole-battle acceptance test.
"""
import json
import re
import subprocess
import tempfile
import unittest
from pathlib import Path

from test_skin_revision_native_104 import balanced
from test_avatar_passive import method_body

ROOT = Path(__file__).resolve().parents[1]


def translate_methods():
    source=(ROOT/'client/src/stages/137_Avatar.as').read_text('utf-8')
    names=set(re.findall(r'function (abyss\w+|hasAbyssDot104|loadAbyssPassives104)\(',source))
    names.update(('injured','addBuff','shieldValue104','absorbShieldDamage',
                  'inheritSummonPanel','isValidSummonMultiplier','scaledSummonStat','countDamage','defenseDamage104'))
    out=[]
    for name in sorted(names):
        m=re.search(r'function '+name+r'\((.*?)\)\s*:\s*[\w.*<>]+\s*\{',source,re.S)
        if not m: raise ValueError(name)
        body=method_body(source,name)
        params=re.sub(r':(?:Vector\.<\w+>|\w+|\*)','',m[1])
        body=re.sub(r'\bvar (\w+)\s*:(?:Vector\.<\w+>|\w+|\*)',r'var \1',body)
        body=re.sub(r'\s+as\s+\w+','',body)
        body=re.sub(r'function\((.*?)\)(?:\s*:\s*\w+)?',lambda m:'function('+re.sub(r':\w+','',m[1])+')',body)
        body=re.sub(r'([\w.]+) is Array',r'Array.isArray(\1)',body)
        while 'for each(' in body:
            a=body.index('for each(');b=balanced(body,a+8)
            left,right=body[a+9:b].split(' in ',1)
            body=body[:a]+'for ('+left+' of Object.values(('+right+') || {}))'+body[b+1:]
        out.append('methods.'+name+'=function('+params+'){with(this){'+body+'}};')
    return '\n'.join(out)


class ParityTests(unittest.TestCase):
    def test_backend_and_client_27_cases(self):
        from gateway import load_game_config
        from abyss_passive_cases import execute_case
        cfg=load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']
        docs=[]
        for path in sorted((ROOT/'docs/roguelite-abyss-equip-passive-cases').glob('*.json')):
            doc=json.loads(path.read_text('utf-8'))
            with self.subTest(backend=path.name):
                self.assertEqual(execute_case(cfg,doc['kind'],doc['ancient'],doc)['expected'],doc['expected'])
            docs.append(doc)
        self.assertEqual(len(docs),27)
        script=(ROOT/'scripts/abyss_client_parity_fixture.js').read_text('utf-8').replace('/*METHODS*/',translate_methods())
        from combat_math import damage_before_final
        extra=[]
        attack=cfg['system_simple']['attack'][:];attack[1]=.5
        for fraction in (.4,.5):
            for sign in (1,1.5):
                attack[2]=sign
                for share in (.3,1):
                    for raw in range(1,41):
                        expected=sum(damage_before_final(raw*f,0,1,t,7,7,attack,share) for f,t in ((1-fraction,1),(fraction,3)))
                        extra.append(dict(fraction=fraction,sign=sign,share=share,raw=raw,expected=expected,minimum=attack[0]))
        with tempfile.TemporaryDirectory(prefix='abyss-parity-') as tmp:
            fixture=Path(tmp)/'fixture.js';fixture.write_text(script,'utf-8')
            result=subprocess.run(['node',str(fixture)],input=json.dumps({'docs':docs,'conversion':extra}),capture_output=True,text=True,encoding='utf-8',cwd=ROOT)
        self.assertEqual(result.returncode,0,result.stdout+'\n'+result.stderr)
        print(result.stdout)


if __name__=='__main__':unittest.main()
