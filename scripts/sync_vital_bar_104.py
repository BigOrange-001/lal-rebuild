"""Wire the native HP slot to timestamped HP/max-HP/total-shield snapshots."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
p = ROOT / 'client/src/stages/137_Avatar.as'
s = p.read_text('utf8')


def once(old, new):
    global s
    if new in s:
        return
    if old not in s:
        raise ValueError('Missing vital bar hook: ' + old[:100])
    s = s.replace(old, new, 1)


once('            mBloodSpr = new ProgressBar(team,hp / hpMax,hpMax);',
     '            mBloodSpr = new ProgressBar(team,hp / hpMax,hpMax);\n'
     '            refreshVitalBar104(hp,hpMax,shieldValue104());')
once('         if(param1=="stun" && hp>0 && buffs.stun) kaisaNotifyStun104(this);',
     '         if(_loc9_ && _loc11_.type=="shield") queueVitalBar104(param4);\n'
     '         if(param1=="stun" && hp>0 && buffs.stun) kaisaNotifyStun104(this);')
once('         delete buffs[param1];',
     '         delete buffs[param1];\n'
     '         if(_loc2_.type=="shield") queueVitalBar104();')
s = s.replace('delayCall(refreshHp,GameMap.actionDelay,hp);',
              'delayCall(refreshHp,GameMap.actionDelay,hp,false,shieldValue104(),hpMax);')
once('      public function refreshHp(param1:int, param2:Boolean = false) : void\n      {',
     '''      private function queueVitalBar104(delay:Number = -1) : void
      {
         var layer:GameMapLayer = GameMapLayer.gl;
         if(!mBloodSpr || !layer) return;
         // Capture all three values now: later hits/buffs may settle before
         // this visual frame is played by the battle animation queue.
         layer.delayCall(refreshVitalBar104,delay<0 ? GameMap.actionDelay : delay,hp,hpMax,shieldValue104());
      }

      private function refreshVitalBar104(health:Number, maximum:Number, shield:Number) : void
      {
         if(!mBloodSpr) return;
         mBloodSpr.setHealthValues104(health,maximum);
         maximum = Math.max(1,maximum);
         mBloodSpr.refresh(health/maximum,false,shield/maximum);
      }

      public function refreshHp(param1:int, param2:Boolean = false, shield:Number = -1, maximum:Number = 0) : void
      {
         if(!mBloodSpr) return;
         if(maximum<=0) maximum=hpMax;
         if(shield<0) shield=shieldValue104();''')
once('         var _loc8_:Boolean = param1 / hpMax < mBloodSpr.perRate;',
     '         var _loc8_:Boolean = param1 / Math.max(1,maximum) < mBloodSpr.perRate;')
once('         mBloodSpr.refresh(param1 / hpMax);',
     '         refreshVitalBar104(param1,maximum,shield);')

# Independent shield entries use the same total and playback queue.
part = ROOT / 'client/src/nightbringer_yasuo.aspart'
anchor = '         buffs["yasuoShield104_"+(++yasuoShieldSerial104)]=shield;'
hook = anchor + '\n         queueVitalBar104();'
if part.exists():
    code = part.read_text('utf8')
    if hook not in code:
        if anchor not in code:
            raise ValueError('Missing independent shield creation hook')
        part.write_text(code.replace(anchor, hook, 1), encoding='utf8')
    once(anchor, hook)

p.write_text(s, encoding='utf8', newline='')
manifest = ROOT / 'client/build.json'
cfg = json.loads(manifest.read_text('utf8'))
source = 'client/src/stages/178_ProgressBar.as'
if not any(stage['source']==source for stage in cfg['stages']):
    cfg['stages'].append(dict(source=source,
                             **{'class':'com.meng52.game.ui.element.ProgressBar'}))
# Avatar calls the new optional shield argument. Compile its dependency first
# so cold builds also see the extended signature in the input SWF.
bar = next(stage for stage in cfg['stages'] if stage['source']==source)
cfg['stages'].remove(bar)
avatar_index = next(i for i,stage in enumerate(cfg['stages'])
                    if stage['source']=='client/src/stages/137_Avatar.as')
cfg['stages'].insert(avatar_index,bar)
for index,stage in enumerate(cfg['stages'],1):
    stage['index'] = index
cfg['stage_count'] = len(cfg['stages'])
cfg['unique_class_count'] = len({stage['class'] for stage in cfg['stages']})
for stage in cfg['stages']:
    if stage['source'] in (source, 'client/src/stages/137_Avatar.as'):
        stage['source_sha256'] = hashlib.sha256((ROOT / stage['source']).read_bytes()).hexdigest()
manifest.write_text(json.dumps(cfg, ensure_ascii=False, indent=2)+'\n', encoding='utf8')
print('Synchronized native HP + textured purple shield bar')
