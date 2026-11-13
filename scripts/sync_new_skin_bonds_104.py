"""Wire shared new-skin bond metadata into native stats, tooltips and silence gate."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
p = ROOT/'client/src/stages/137_Avatar.as'
s = p.read_text('utf8')
start = '      // BEGIN NEW SKIN BONDS 104\n'
end = '      // END NEW SKIN BONDS 104\n'
if start in s:
    s = s[:s.index(start)] + s[s.index(end)+len(end):]
anchor = '      public function getBondRows104()'
s = s.replace(anchor,start+(ROOT/'client/src/new_skin_bonds_104.aspart').read_text('utf8')+end+'\n'+anchor,1)


def once(old, new):
    global s
    if new in s:
        return
    if old not in s:
        raise ValueError('Missing new skin bond hook: '+old[:100])
    s = s.replace(old,new,1)


once('         return value;\n      }\n\n      public function getEquipmentBondRows104()',
     '''         for each(var equipmentBond:Object in getEquipmentBondRows104())
            if(equipmentBond.stats && equipmentBond.stats[stat]!=null)
               value = Tools.toInt(value*(1+Number(equipmentBond.stats[stat])));
         return value;
      }

      public function getEquipmentBondRows104()''')
once('         var text:String = "<br/>装备羁绊（本人穿戴，分别强化指定技能部分）";',
     '''         var text:String = definitions.length && definitions[0].kind=="stats" ? "<br/>装备羁绊（本人穿戴，提升属性）" : "<br/>装备羁绊（本人穿戴，分别强化指定技能部分）";''')
once('               if(benefit.skill_rate) effects.push("技能数值提高"+Math.round(Number(benefit.skill_rate)*100)+"%");',
     '               if(benefit.skill_rate) effects.push("技能数值提高"+Math.round(Number(benefit.skill_rate)*100)+"%");\n'
     '               if(benefit.info) effects.push(String(benefit.info));')
once('            if(benefit.skill_rate) description += "\\n技能数值 +"+Math.round(Number(benefit.skill_rate)*100)+"%";',
     '            if(benefit.skill_rate) description += "\\n技能数值 +"+Math.round(Number(benefit.skill_rate)*100)+"%";\n'
     '            if(benefit.info) description += "\\n"+String(benefit.info);')
a = s.index('      public function checkSkill()')
b = s.index('      public function findAimList(',a)
old = '''         if(buffs["silence"])
         {
            return _loc1_;
         }'''
new = '''         if(buffs["silence"])
         {
            // This bond permits only Yasuo's ready captain skill, not his Q
            // or book. checkUse still owns cooldown and target validation.
            if(yasuoCastSilenced104() && isLeader && skill1 && GameMap.currentMap && !GameMap.currentMap.isEnd(line))
               return skill1.checkUse();
            return _loc1_;
         }'''
part = s[a:b]
if new not in part:
    if old not in part:
        raise ValueError('Missing native silence gate')
    s = s[:a]+part.replace(old,new,1)+s[b:]
p.write_text(s,'utf8',newline='')
manifest = ROOT/'client/build.json'
m = json.loads(manifest.read_text('utf8'))
for stage in m['stages']:
    if stage['source']=='client/src/stages/137_Avatar.as':
        stage['source_sha256'] = hashlib.sha256(p.read_bytes()).hexdigest()
manifest.write_text(json.dumps(m,ensure_ascii=False,indent=2)+'\n','utf8')
print('Synchronized new skin hero/equipment bonds and captain silence gate')
