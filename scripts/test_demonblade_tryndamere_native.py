"""Execute the actual Demonblade Tryndamere AS methods; battle primitives are stubs."""
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
    source=strip_as_comments((ROOT/'client/src/demonblade_tryndamere.aspart').read_text('utf-8'))
    result=[]
    for match in re.finditer(r'(?:private|public) function (\w+)\((.*?)\)\s*:\s*[\w.<>]+\s*\{',source,re.S):
        start=match.end()-1
        body=source[start+1:balanced(source,start)]
        args=re.sub(r':(?:[\w.<>]+|\*)','',match[2])
        body=re.sub(r'\bvar (\w+)\s*:(?:[\w.<>]+|\*)',r'var \1',body)
        body=re.sub(r'\s+as\s+\w+','',body)
        while 'for each(' in body:
            a=body.index('for each(');b=balanced(body,a+8)
            left,right=body[a+9:b].split(' in ',1)
            body=body[:a]+'for ('+left+' of Object.values('+right+'))'+body[b+1:]
        result.append('methods.'+match[1]+'=function('+args+'){with(this){'+body+'}};')
    return '\n'.join(result)


class NativeDemonbladeTests(unittest.TestCase):
    def test_native_methods(self):
        from gateway import load_game_config
        from demonblade_tryndamere_105 import AID,NORMAL,CAPTAIN,PASSIVE
        cfg=load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']
        data=dict(aid=AID,normal=NORMAL,captain=CAPTAIN,passive=PASSIVE,
                  skills={key:cfg['skill'][key] for key in (NORMAL,CAPTAIN,PASSIVE)})
        source=(ROOT/'scripts/demonblade_tryndamere_fixture.js').read_text('utf-8')
        source=source.replace('/*METHODS*/',translate()).replace('/*DATA*/',json.dumps(data))
        run=subprocess.run(['node'],input=source,text=True,encoding='utf-8',capture_output=True,cwd=ROOT)
        self.assertEqual(run.returncode,0,run.stdout+'\n'+run.stderr)
        print(run.stdout.strip())

    def test_avatar_carries_the_synchronized_block_and_every_hook(self):
        avatar=(ROOT/'client/src/stages/137_Avatar.as').read_text('utf-8')
        code=(ROOT/'client/src/demonblade_tryndamere.aspart').read_text('utf-8')
        block=avatar[avatar.index('      // BEGIN DEMONBLADE TRYNDAMERE 105\n'):avatar.index('      // END DEMONBLADE TRYNDAMERE 105\n')]
        self.assertIn(code,block)
        for hook in ('return demonCanCast105(kind);','return demonExecute105(kind,sourceSkill);',
                     'demonEvent105(event,source,target);','demonStart105();','demonTurn105();',
                     'chance=Math.min(100,chance+param1.demonCritBonus105());','if(demonImmune105(param1)) return;',
                     '_loc6_ = demonAttack105(_loc6_);','demonLethal105();\n         skin2Lethal();',
                     'demonHurtTaken105();','param3 *= Number(demonPassive105()[4]);',
                     'if(demonTakeForceCrit105()) basicContext.sixForceCrit105=true;',
                     'if(ratioDamage104()) _loc7_ = 2 + (_loc7_ - 2) * param1.demonCritDamageRate105();'):
            self.assertEqual(avatar.count(hook),1,hook)
        # Shyvana's two rage changes and the bar creation each refresh the strip.
        self.assertEqual(avatar.count('queueRageBar105();'),code.count('queueRageBar105();')+3)
        bar=(ROOT/'client/src/stages/178_ProgressBar.as').read_text('utf-8')
        self.assertIn('public function setRage105(rate:Number) : void',bar)
        self.assertIn('m_rageSpr105.scaleX = 1 / 3;',bar)


if __name__=='__main__':unittest.main()
