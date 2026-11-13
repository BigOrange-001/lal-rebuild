"""Execute actual maintained Kai'Sa AS method bodies after syntax-only translation."""
from pathlib import Path
import sys,re,json,subprocess,unittest
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'));sys.path.insert(0,str(ROOT/'server'))
from test_skin_revision_native_104 import balanced
def strip_as_comments(source):
 # Keep string literals intact; comments can contain unmatched apostrophes or
 # braces and must not participate in the method-boundary scan.
 tokens=re.compile(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|//[^\n]*|/\*[\s\S]*?\*/')
 return tokens.sub(lambda m:'' if m[0].startswith(('//','/*')) else m[0],source)
def translate():
 source=strip_as_comments((ROOT/'client/src/dragonmancer_kaisa.aspart').read_text('utf-8'))
 methods=[]
 pattern=re.compile(r'(?:private|public)(?: static)? function (\w+)\((.*?)\)\s*:\s*[\w.<>]+\s*\{',re.S)
 for m in pattern.finditer(source):
  if m[1] in ('kaisaProjectile104','kaisaQueuePlasma104','kaisaShowPlasma104','kaisaClearPlasma104'):continue
  start=m.end()-1;body=source[start+1:balanced(source,start)]
  args=re.sub(r':(?:Vector\.<\w+>|\w+|\*)','',m[2])
  body=re.sub(r'\bvar (\w+)\s*:(?:Vector\.<\w+>|\w+|\*)',r'var \1',body)
  body=re.sub(r'\s+as\s+(?:Array|Avatar|Object|Vector\.<Avatar>)','',body)
  while 'for each(' in body:
   a=body.index('for each(');b=balanced(body,a+8)
   left,right=body[a+9:b].split(' in ',1)
   body=body[:a]+'for ('+left+' of '+right+')'+body[b+1:]
  methods.append('methods.'+m[1]+'=function('+args+'){with(this){'+body+'}};')
 return '\n'.join(methods)
class NativeKaisaTests(unittest.TestCase):
 def test_actual_native_methods(self):
  from gateway import load_game_config
  from dragonmancer_kaisa_104 import NORMAL,CAPTAIN,PASSIVE
  c=load_game_config(ROOT/'config/reconstruction/full-config.json')['cfg']
  data={key:c['skill'][key] for key in [NORMAL,CAPTAIN,PASSIVE]}
  data.update(normal=NORMAL,captain=CAPTAIN,passive=PASSIVE)
  js=(ROOT/'scripts/dragonmancer_kaisa_fixture.js').read_text('utf-8').replace('/*METHODS*/',translate()).replace('/*DATA*/',json.dumps(data))
  p=subprocess.run(['node'],input=js,text=True,encoding='utf-8',capture_output=True,cwd=ROOT)
  self.assertEqual(p.returncode,0,p.stdout+'\n'+p.stderr)
  print(p.stdout.strip())
if __name__=='__main__':unittest.main()
