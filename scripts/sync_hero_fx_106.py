"""Attach the code-painted hero effects (core + groups A/B/C/D/E) to the AIR Avatar.

Sources: client/src/hero_fx_core_106.aspart, kaisa_rain_fx_106.aspart and hero_fx_{a,b,c,d,e}_106.aspart.
Run after the other sync scripts; it is idempotent. Every hook only adds a call into
the core, so the groups never need to touch this file.
"""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ['hero_fx_core_106.aspart', 'kaisa_rain_fx_106.aspart', 'hero_fx_a_106.aspart', 'hero_fx_b_106.aspart', 'hero_fx_c_106.aspart',
           'hero_fx_d_106.aspart', 'hero_fx_e_106.aspart']
START = '      // BEGIN HERO CODE FX 106\n'
END = '      // END HERO CODE FX 106\n'
NATIVE_HOOK = ('         var heroFxClaimed106:Object={targets:param1,buff:param7};\n'
               '         if(param5 && param1 && param1.length && heroFxClaim106("native",param5,param1[0],heroFxClaimed106))\n'
               '            _loc41_ = {nativeContact104:_loc41_.nativeContact104,laneWave:_loc41_.laneWave,sp:heroFxClaimed106.sp};\n')


def sync():
    avatar = ROOT / 'client/src/stages/137_Avatar.as'
    s = avatar.read_text('utf-8')
    if START in s:
        rest = s[s.index(END) + len(END):]
        s = s[:s.index(START)] + (rest[1:] if rest.startswith('\n') else rest)
    code = ''.join((ROOT / 'client/src' / name).read_text('utf-8') for name in SOURCES)
    anchor = '      public function abilityCanCast('
    if s.count(anchor) != 1:
        raise ValueError('Missing or ambiguous block anchor')
    s = s.replace(anchor, START + code + END + '\n' + anchor, 1)

    def once(old, new):
        nonlocal s
        if new in s:
            return
        if s.count(old) != 1:
            raise ValueError('Missing or ambiguous hero FX hook: ' + old[:110])
        s = s.replace(old, new, 1)

    # Skin v2 strikes: the family kind, with "_ult" during the captain skill, before the atlas fallback.
    once('         var kind:String=String(s2Family());\n'
         '         if(skin2.castSkill && skin2.castSkill===skill1 && fxProfile104(kind+"_ult").length)kind+="_ult";\n'
         '         if(target)fxPulse104(kind,target);',
         '         var kind:String=String(s2Family());\n'
         '         if(target && heroFxClaim106("strike",kind+(skin2.castSkill && skin2.castSkill===skill1 ? "_ult" : ""),target)) return;\n'
         '         if(skin2.castSkill && skin2.castSkill===skill1 && fxProfile104(kind+"_ult").length)kind+="_ult";\n'
         '         if(target)fxPulse104(kind,target);')
    # State and passive pulses.
    once('      private function fxPulse104(kind:String, target:Avatar = null, lane:int = -1, position:Number = 0) : void\n'
         '      {\n         if(GameMapLayer.isFastest)return;\n',
         '      private function fxPulse104(kind:String, target:Avatar = null, lane:int = -1, position:Number = 0) : void\n'
         '      {\n         if(GameMapLayer.isFastest)return;\n'
         '         if(heroFxClaim106("pulse",kind,target || this,lane>=0 ? {lane:lane,pos:position} : null))return;\n')
    # Skin v2 heal and shield had no presentation at all.
    once('         if(target && target.hp > 0 && hp > 0) target.injured(Tools.toInt(getDamage()*coefficient),1,null,4,this,false,this);',
         '         if(target && target.hp > 0 && hp > 0) {heroFxClaim106("heal",String(s2Family()),target);target.injured(Tools.toInt(getDamage()*coefficient),1,null,4,this,false,this);}')
    once('         if(target && target.hp > 0 && hp > 0) target.addBuff("shield",duration,Tools.toInt(getDamage()*coefficient),0,-1,this);',
         '         if(target && target.hp > 0 && hp > 0) {heroFxClaim106("shield",String(s2Family()),target);target.addBuff("shield",duration,Tools.toInt(getDamage()*coefficient),0,-1,this);}')
    # Named native effects: a claim drops the borrowed visuals and keeps the combat flags.
    # The claim also sees the buff the action applies, and may set the bullet speed (sp) so
    # the hit waits a known time for the projectile it draws. Upgrade the first form in place.
    legacy = ('         if(param5 && param1 && param1.length && heroFxClaim106("native",param5,param1[0],{targets:param1}))\n'
              '            _loc41_ = {nativeContact104:_loc41_.nativeContact104,laneWave:_loc41_.laneWave};\n')
    s = s.replace(legacy, NATIVE_HOOK)
    once('         var _loc41_:* = DisplayTools.getAttrs(param5);\n'
         '         if(!_loc41_)\n         {\n            _loc41_ = {};\n         }\n',
         '         var _loc41_:* = DisplayTools.getAttrs(param5);\n'
         '         if(!_loc41_)\n         {\n            _loc41_ = {};\n         }\n'
         + NATIVE_HOOK)
    # Persistent state art and its animation.
    once('         if(id.charAt(0)!="c" || index<0 || index>=32 || !fxAtlases104[sheet])return null;',
         '         if(id.charAt(1)==":")return heroFxImage106(id,scale,alpha);\n'
         '         if(id.charAt(0)!="c" || index<0 || index>=32 || !fxAtlases104[sheet])return null;')
    once('               var ids:Array=fxPersistent104(row);if(!ids.length)continue;',
         '               var ids:Array=heroFxState106(row) || fxPersistent104(row);if(!ids.length)continue;')
    once('      private static function fxAnimateState104(art:DisplayObject, row:Object, index:int, seed:int) : void\n      {\n',
         '      private static function fxAnimateState104(art:DisplayObject, row:Object, index:int, seed:int) : void\n      {\n'
         '         if(heroFxAnimate106(art,row,index,seed))return;\n')
    # Frame clock and battle teardown, next to the Demonblade ones.
    once('         yasuoAdvanceEffects104(elapsed);\n         demonFxAdvance105(elapsed);\n',
         '         yasuoAdvanceEffects104(elapsed);\n         demonFxAdvance105(elapsed);\n         heroFxAdvance106(elapsed);\n')
    avatar.write_text(s, encoding='utf-8', newline='')

    layer = ROOT / 'client/src/stages/177_GameMapLayer.as'
    t = layer.read_text('utf-8')
    # Before the existing clears, so the Demonblade teardown keeps its exact neighbours.
    hook = '         Avatar.heroFxClear106();\n'
    t = t.replace(hook, '')
    old = '         Avatar.clearEffects104();\n         Avatar.demonFxClear105();\n'
    if t.count(old) != 1:
        raise ValueError('Missing GameMapLayer clear anchor')
    t = t.replace(old, hook + old, 1)
    layer.write_text(t, encoding='utf-8', newline='')

    config = ROOT / 'client/build.json'
    cfg = json.loads(config.read_text('utf-8'))
    for row in cfg['stages']:
        if row['source'] in ('client/src/stages/137_Avatar.as', 'client/src/stages/177_GameMapLayer.as'):
            row['source_sha256'] = hashlib.sha256((ROOT / row['source']).read_bytes()).hexdigest()
    config.write_text(json.dumps(cfg, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('Hero code FX 106: core, groups A/B/C/D/E and hooks synchronized')


if __name__ == '__main__':
    sync()
