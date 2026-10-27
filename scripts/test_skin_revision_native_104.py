"""Run the maintained AS skin methods in a deterministic combat fixture.

Only AS syntax is translated; the skill/event method bodies are not reimplemented.
AIR damage/visual primitives are fixture stubs. FFDec compilation is separate.
"""
import re, json, subprocess, unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def balanced(s,start):
 depth=0;quote=None;escape=False
 for i in range(start,len(s)):
  c=s[i]
  if quote:
   if escape:escape=False
   elif c=='\\':escape=True
   elif c==quote:quote=None
   continue
  if c in ('"',"'"):quote=c;continue
  if c in '({[':depth+=1
  if c in ')}]':
   depth-=1
   if depth==0:return i
 raise ValueError('unbalanced')

def translate():
 source=(ROOT/'client/src/skin_revision_v2.aspart').read_text('utf8');out=[]
 pattern=re.compile(r'(?:private|public) function (\w+)\((.*?)\)\s*:\s*[\w.<>]+\s*\{',re.S)
 for m in pattern.finditer(source):
  start=m.end()-1;body=source[start+1:balanced(source,start)]
  params=re.sub(r':(?:Vector\.<\w+>|\w+|\*)','',m[2])
  body=re.sub(r'\bvar (\w+)\s*:(?:Vector\.<\w+>|\w+|\*)',r'var \1',body)
  body=re.sub(r'\s+as\s+(?:Array|Avatar|Object|Vector\.<Avatar>)','',body)
  body=body.replace('new Vector.<Avatar>()','[]')
  while 'for each(' in body:
   a=body.index('for each(');b=balanced(body,a+8)
   left,right=body[a+9:b].split(' in ',1)
   body=body[:a]+'for ('+left+' of '+right+')'+body[b+1:]
  body=re.sub(r'function\((.*?)\):Number',lambda m:'function('+re.sub(r':\w+','',m[1])+')',body)
  out.append('methods.'+m[1]+'=function('+params+'){with(this){'+body+'}};')
 return '\n'.join(out)

class NativeRevisionTests(unittest.TestCase):
 def test_native_runtime_scenarios(self):
  script=(ROOT/'scripts/skin_revision_fixture.js').read_text('utf8').replace('/*METHODS*/',translate())
  result=subprocess.run(['node'],input=script,cwd=ROOT,capture_output=True,text=True,encoding='utf8')
  self.assertEqual(result.returncode,0,result.stdout+'\n'+result.stderr)
  print(result.stdout)

if __name__=='__main__':unittest.main()
