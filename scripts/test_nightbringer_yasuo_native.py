"""Execute actual Yasuo AS method bodies; AIR graphics/damage primitives are stubs."""
import json
from pathlib import Path
import re
import subprocess
import sys
import unittest

ROOT=Path(__file__).resolve().parents[1]
sys.path[:0]=[str(ROOT/'scripts'),str(ROOT/'server')]
from test_skin_revision_native_104 import balanced
from test_dragonmancer_kaisa_native import strip_as_comments


def translate():
    source=(ROOT/'client/src/nightbringer_yasuo.aspart').read_text('utf-8')
    avatar=(ROOT/'client/src/stages/137_Avatar.as').read_text('utf-8')
    start=avatar.index('      private function absorbShieldDamage(')
    source+=avatar[start:avatar.index('      public function injured(',start)]
    start=avatar.index('      public function addPurifyCharges(')
    source+=avatar[start:avatar.index('      private function executeCatSkin(',start)]
    start=avatar.index('      public function checkSkill()')
    source+=avatar[start:avatar.index('      public function findAimList(',start)]
    source=strip_as_comments(source)
    result=[]
    for match in re.finditer(r'(?:private|public) function (\w+)\((.*?)\)\s*:\s*[\w.<>]+\s*\{',source,re.S):
        if match[1]=='yasuoEffect104':continue
        start=match.end()-1
        body=source[start+1:balanced(source,start)]
        args=re.sub(r':(?:[\w.<>]+|\*)','',match[2])
        body=re.sub(r'\bvar (\w+)\s*:(?:[\w.<>]+|\*)',r'var \1',body)
        body=re.sub(r'\s+as\s+\w+','',body)
        body=re.sub(r'function\((.*?)\):Number',lambda m:'function('+re.sub(r':\w+','',m[1])+')',body)
        while 'for each(' in body:
            a=body.index('for each(');b=balanced(body,a+8)
            left,right=body[a+9:b].split(' in ',1)
            body=body[:a]+'for ('+left+' of Object.values('+right+'))'+body[b+1:]
        result.append('methods.'+match[1]+'=function('+args+'){with(this){'+body+'}};')
    return '\n'.join(result)


class NativeYasuoTests(unittest.TestCase):
    def test_native_methods(self):
        from gateway import load_game_config
        from nightbringer_yasuo_104 import AID,NORMAL,CAPTAIN,PASSIVE
        cfg=load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']
        data=dict(aid=AID,normal=NORMAL,captain=CAPTAIN,passive=PASSIVE,
                  skills={key:cfg['skill'][key] for key in (NORMAL,CAPTAIN,PASSIVE)})
        source=(ROOT/'scripts/nightbringer_yasuo_fixture.js').read_text('utf-8')
        source=source.replace('/*METHODS*/',translate()).replace('/*DATA*/',json.dumps(data))
        run=subprocess.run(['node'],input=source,text=True,encoding='utf-8',capture_output=True,cwd=ROOT)
        self.assertEqual(run.returncode,0,run.stdout+'\n'+run.stderr)
        print(run.stdout.strip())


if __name__=='__main__':unittest.main()
