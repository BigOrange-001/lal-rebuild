"""Attach presentation hooks without changing combat state or using gameplay RNG."""
from pathlib import Path
import re
import json,hashlib
ROOT=Path(__file__).resolve().parents[1]
avatar=ROOT/'client/src/stages/137_Avatar.as'
s=avatar.read_text('utf8')
begin='      // BEGIN BATTLE EFFECTS 104\n';end='      // END BATTLE EFFECTS 104\n'
if begin in s:s=s[:s.index(begin)]+s[s.index(end)+len(end):]
code=''.join((ROOT/'client/src'/p).read_text('utf8') for p in ['native_effect_profiles_104.aspart','battle_effects_104.aspart','native_effect_runtime_104.aspart'])
s=s.replace('      public function equipmentPart104(',begin+code+'\n'+end+'\n      public function equipmentPart104(',1)
def once(old,new):
 global s
 if new in s:return
 if old not in s:raise ValueError('Missing effect anchor: '+old[:100])
 s=s.replace(old,new,1)
once('         statisticsRows104 = [];','         clearEffects104();\n         statisticsRows104 = [];')
# Pulses are scheduled on GameMap.actionDelay, the same clock as existing hits.
once('target.skin2[name] = {owner:this,expires:manualOwnerActionSerial+duration};','{target.skin2[name] = {owner:this,expires:manualOwnerActionSerial+duration};fxPulse104(name,target);}')
once('         var egg:Object=skin2.eggs.splice(index,1)[0];','         var egg:Object=skin2.eggs.splice(index,1)[0];\n         fxPulse104("egg_ready",null,egg.line,egg.pos);')
once('         var holder:Avatar=skin2.ball;skin2.ball=null;','         var holder:Avatar=skin2.ball;holder.fxTransfer104("ball",this);fxPulse104("ball",holder);fxPulse104("shot",this);skin2.ball=null;')
once('skin2.ball=ally || this;skin2.ballTurn=', 'skin2.ball=ally || this;fxTransfer104("ball",skin2.ball);skin2.ballTurn=')
once('                  {state.count=0;++state.triggers;s2Hit(', '                  {fxPulse104(family==1206 ? "rings" : "time_rings",target);state.count=0;++state.triggers;s2Hit(')
once('               delete skin2.eggUntil;hp=Math.max(hp,int(hpMax*.4));','               fxPulse104("rebirth");delete skin2.eggUntil;hp=Math.max(hp,int(hpMax*.4));')
once('         hp=Math.max(1,int(hpMax*.3));abilityFeedback("冰晶重生");','         hp=Math.max(1,int(hpMax*.3));fxPulse104("rebirth");abilityFeedback("冰晶重生");')
once('                  unit.skin2.guardUsed=true;var transfer:Number=', '                  unit.fxPulse104("guard",this);unit.skin2.guardUsed=true;var transfer:Number=')
once('                     removeAllDebuff();reline(ghost.line,ghost.pos);','                     fxPulse104("time",null,line,pos);fxPulse104("time",null,ghost.line,ghost.pos);removeAllDebuff();reline(ghost.line,ghost.pos);')
once('                  unit.s2Shield(this,unit.s2Value(unit.skillB,"shield"),1);break;','                  unit.s2Shield(this,unit.s2Value(unit.skillB,"shield"),1);break;')
once('                  skin2.growth=int(skin2.growth || 0)+1;', '                  fxPulse104("growth");skin2.growth=int(skin2.growth || 0)+1;')
once('            {skin2.bearGrowth=int(skin2.bearGrowth || 0)+1;', '            {fxPulse104("bear");skin2.bearGrowth=int(skin2.bearGrowth || 0)+1;')
once('         if(count && s2Family()==1214)','         if(count)fxPulse104("cleanse",target);\n         if(count && s2Family()==1214)')
once('            if(family==1201) {skin2.guarding=', '            if(family==1201) {skin2.guarding=')
s=re.sub(r'         var effectKinds:Object=.*?;\n         fxPulse104\(String\(effectKinds\[family\]\),this\);\n','',s)
once('         var previous:Object = skin2.ringHit; skin2.ringHit = rings;','         fxStrike104(target);\n         var previous:Object = skin2.ringHit; skin2.ringHit = rings;')
# Custom strikes already schedule their own impact. Avoid overlaying the old generic effect.
s=s.replace('kind,kind==1 ? "FX60_SLASH" : "FX60_MAGIC");','kind,"");')
once('      public function newFightRes(param1:Sprite = null) : Sprite\n      {','      public function newFightRes(param1:Sprite = null) : Sprite\n      {\n         fxLoad104();')
once('      private function abilityBombExplode(bomb:Object) : void\n      {','      private function abilityBombExplode(bomb:Object) : void\n      {\n         fxPulse104("bomb");')
avatar.write_text(s,encoding='utf8',newline='')
layer=ROOT/'client/src/stages/177_GameMapLayer.as'
if not layer.exists():
 layer.write_bytes((ROOT/'build/effects-104/export/scripts/com/meng52/game/ui/map/GameMapLayer.as').read_bytes())
t=layer.read_text('utf8')
if 'Avatar.advanceEffects104(_loc2_);' not in t:t=t.replace('         clock.advanceTime(_loc2_);','         clock.advanceTime(_loc2_);\n         Avatar.advanceEffects104(_loc2_);',1)
if 'Avatar.clearEffects104();' not in t:t=t.replace('         juggler.purge();','         Avatar.clearEffects104();\n         juggler.purge();',1)
layer.write_text(t,encoding='utf8',newline='')
p=ROOT/'client/build.json';cfg=json.loads(p.read_text('utf8'))
if not any(r['source']==str(layer.relative_to(ROOT)).replace('\\','/') for r in cfg['stages']):
 cfg['stages'].append({'index':len(cfg['stages'])+1,'source':str(layer.relative_to(ROOT)).replace('\\','/'),'class':'com.meng52.game.ui.map.GameMapLayer','source_sha256':''})
cfg['stage_count']=len(cfg['stages']);cfg['unique_class_count']=len(set(r['class'] for r in cfg['stages']))
for r in cfg['stages']:r['source_sha256']=hashlib.sha256((ROOT/r['source']).read_bytes()).hexdigest()
p.write_text(json.dumps(cfg,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
print('Battle effects artwork, runtime, playback hooks and build stage synchronized')
