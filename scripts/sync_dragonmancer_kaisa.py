"""Synchronize Kai'Sa's maintained runtime into the final Avatar build source."""
from pathlib import Path
import hashlib,json,re
ROOT=Path(__file__).resolve().parents[1]
p=ROOT/'client/src/stages/137_Avatar.as'
s=p.read_text('utf-8')
start='      // BEGIN DRAGONMANCER KAISA 104\n';end='      // END DRAGONMANCER KAISA 104\n'
if start in s:s=s[:s.index(start)]+s[s.index(end)+len(end):]
code=(ROOT/'client/src/dragonmancer_kaisa.aspart').read_text('utf-8')
anchor='      public function abilityCanCast('
s=s.replace(anchor,start+code+'\n'+end+'\n'+anchor,1)
def once(old,new):
 global s
 if new not in s:
  if old not in s:raise RuntimeError('Missing KaiSa hook: '+old[:90])
  s=s.replace(old,new,1)
once('         if(kind.indexOf("skin2_")==0) return skin2CanCast(kind,sourceSkill);',
     '         if(kind.indexOf("dragon_kaisa_")==0) return kaisaCanCast104(kind);\n         if(kind.indexOf("skin2_")==0) return skin2CanCast(kind,sourceSkill);')
once('         if(kind.indexOf("skin2_")==0) return executeSkin2(kind,sourceSkill);',
     '         if(kind.indexOf("dragon_kaisa_")==0) return kaisaExecute104(kind,sourceSkill);\n         if(kind.indexOf("skin2_")==0) return executeSkin2(kind,sourceSkill);')
once('         skin2Event(event,source,target,amount,overheal);',
     '         kaisaEvent104(event,source,target);\n         skin2Event(event,source,target,amount,overheal);')
legacy_reset='         kaisaRoot104=null;kaisaCast104=0;kaisaMarks104={};kaisaHunting104=false;kaisaBurst104=false;'
new_reset='         kaisaClearPlasma104();kaisaRoot104=null;kaisaCast104=0;kaisaMarks104={};kaisaHunting104=false;kaisaBurst104=false;'
if legacy_reset in s:s=s.replace(legacy_reset,new_reset,1)
if new_reset not in s:
 once('         summonStatSnapshot = false;\n         formationOwner = null;',
      '         summonStatSnapshot = false;\n'+new_reset+'\n         formationOwner = null;')
once('         getTeamHp();\n         emitModEvent("turn_start",this,this);',
     '         kaisaTryCaptain104();\n         getTeamHp();\n         emitModEvent("turn_start",this,this);')
a=s.index('      public function addBuff(');b=s.index('\n      public function resetBuff()',a)
section=s[a:b]
hook='         if(param1=="stun" && hp>0 && buffs.stun) kaisaNotifyStun104(this);\n'
if hook not in section:
 endfn=section.rfind('\n      }')
 section=section[:endfn]+'\n'+hook+section[endfn:];s=s[:a]+section+s[b:]
p.write_bytes(s.encode('utf-8'))
manifest=ROOT/'client/build.json';doc=json.loads(manifest.read_text('utf-8'))
for stage in doc['stages']:
 if stage['source']=='client/src/stages/137_Avatar.as':stage['source_sha256']=hashlib.sha256(p.read_bytes()).hexdigest()
manifest.write_text(json.dumps(doc,ensure_ascii=False,indent=2)+'\n','utf-8')
print('Synchronized KaiSa runtime and updated the final Avatar source hash')
