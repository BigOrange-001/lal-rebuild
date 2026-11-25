"""Group D hooks for code-painted hero effects that no shared hook reports.

Run after scripts/sync_hero_fx_106.py and the group A, B and C scripts; it is
idempotent. Each hook is one presentation call into heroFxClaim106 placed before the
combat line it describes, which it leaves unchanged:

* "cast" kind "1201_purge" (extra.allies): King's Verdict killed a hero and is about
  to cleanse the lane allies; Garen's purify is a bare addBuff with no effect.
* "shield" kind "1207_overflow": Gentle Encore turns Ahri's overflow healing into a
  shield, also a bare addBuff.

Group A and B ignore these kinds, and B's generic fallback ignores "cast".
"""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
AVATAR = 'client/src/stages/137_Avatar.as'


def sync():
    path = ROOT / AVATAR
    s = path.read_text('utf-8')
    if 'BEGIN HERO FX D 106' not in s:
        raise ValueError('Run scripts/sync_hero_fx_106.py first')

    def once(old, new):
        nonlocal s
        if new in s:
            return
        if s.count(old) != 1:
            raise ValueError('Missing or ambiguous group D hook: ' + old[:110])
        s = s.replace(old, new, 1)

    once('if(target.hp<=0 && target.getType()==1 && !target.isManualSummonUnit) for each(unit in allies) unit.addBuff("purify",1);break;',
         'if(target.hp<=0 && target.getType()==1 && !target.isManualSummonUnit) {heroFxClaim106("cast","1201_purge",target,{allies:allies});'
         'for each(unit in allies) unit.addBuff("purify",1);}break;')
    once('         {target.addBuff("shield",2,overheal*s2Value(skillB,"overflow"),0,-1,this);}',
         '         {heroFxClaim106("shield","1207_overflow",target);target.addBuff("shield",2,overheal*s2Value(skillB,"overflow"),0,-1,this);}')
    path.write_text(s, encoding='utf-8', newline='')

    config = ROOT / 'client/build.json'
    cfg = json.loads(config.read_text('utf-8'))
    for row in cfg['stages']:
        if row['source'] == AVATAR:
            row['source_sha256'] = hashlib.sha256(path.read_bytes()).hexdigest()
    config.write_text(json.dumps(cfg, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('Hero code FX 106 group D: Avatar hooks synchronized')


if __name__ == '__main__':
    sync()
