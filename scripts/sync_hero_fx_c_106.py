"""Group C hooks for code-painted hero effects that never pass through attackAimList.

Run after scripts/sync_hero_fx_106.py; it is idempotent. Each hook is one call into
Avatar.hfxCHook106, a public bridge to heroFxClaim106 (SkillSet cannot reach the
private claim), so every group may answer these events too:

* "native" for an effect-sequence summon (kind = its effect, "SUMMON_EFF" when blank):
  a claim drops the generic summon flash. Used by Shadow Vayne's clones, the
  White Lady's green snake, Super Teemo's mushroom, Kassadin's Riftwalk and the zongzi.
* "sequence" for every other effect-sequence step (kind = "<skill id>#<step>#<op>"):
  these steps carry no effect name and so had no presentation at all (Final Hour,
  Cursed Green Snake, Red Dust Shatter, Super Buddy's blessing).
* "native" for caster_hp_heal targets (the mushroom's and the green snake's heals):
  a claim replaces the borrowed heal effect.

Hooks test `"hfxCHook106" in avatar` first: always true for the real Avatar, and it
keeps the existing Node tests that run SkillSet code against plain mock avatars working.
"""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
SKILLSET = 'client/src/stages/139_SkillSet.as'


def sync():
    path = ROOT / SKILLSET
    s = path.read_text('utf-8')

    def once(old, new):
        nonlocal s
        if new in s:
            return
        if s.count(old) != 1:
            raise ValueError('Missing or ambiguous group C hook: ' + old[:110])
        s = s.replace(old, new, 1)

    summon = '            var summonEffect:Object = DisplayTools.getAttrs(effect || "SUMMON_EFF");\n'
    once(summon, summon +
         '            if(("hfxCHook106" in avatar) && avatar.hfxCHook106("native",effect || "SUMMON_EFF",unit,{targets:[unit],lane:unit.line,pos:unit.pos})) summonEffect = null;\n')
    step = '         var modPresentation:Object = kind == "damage" && selected.length > 1 ? avatar.beginParallelVisualBatch() : null;\n'
    once(step, '         if("hfxCHook106" in avatar) avatar.hfxCHook106("sequence",String(skillSetData.id)+"#"+index+"#"+kind,center,{units:selected});\n' + step)
    once('                     hpHealTarget.injured(hpHealAmount,1,DisplayTools.getAttrs(String(_loc20_[2])),4,avatar,false,avatar);',
         '                     hpHealTarget.injured(hpHealAmount,1,("hfxCHook106" in avatar) && avatar.hfxCHook106("native",String(_loc20_[2]),hpHealTarget,{targets:[hpHealTarget]}) ? null : DisplayTools.getAttrs(String(_loc20_[2])),4,avatar,false,avatar);')
    path.write_text(s, encoding='utf-8', newline='')

    config = ROOT / 'client/build.json'
    cfg = json.loads(config.read_text('utf-8'))
    for row in cfg['stages']:
        if row['source'] == SKILLSET:
            row['source_sha256'] = hashlib.sha256(path.read_bytes()).hexdigest()
    config.write_text(json.dumps(cfg, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('Hero code FX 106 group C: SkillSet hooks synchronized')


if __name__ == '__main__':
    sync()
