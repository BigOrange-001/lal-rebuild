"""Group E hooks for code-painted hero effects that no shared hook reports.

Run after scripts/sync_hero_fx_106.py and the group A, B, C and D scripts; it is
idempotent. Each hook is one presentation call into heroFxClaim106 placed on the
combat line it describes, which keeps doing exactly what it did:

Avatar (client/src/stages/137_Avatar.as)
* "cast" "1114_charge": Aurelion Sol stores a charge (4/5 and 6 stars); the claim draws
  the charge instead of the borrowed lightning flash, the text still pops.
* "cast" "1114_stand": the six-star storm channel starts (the standing state).
* "cast" "1128_box": Shaco's Jack in the Box appears.
* "direct" from checkMove: the effect a move action plays along the way (Shaco's dash).
* heroFxRowsE106 at the end of fxState104: state rows only group E draws.
  (Avatar.aoxingChain106 calls "chain" itself: that is part of the new chain rule.)

SkillSet (client/src/stages/139_SkillSet.as)
* "direct": queueDirectActionEffect, the effect a stat or move action plays on a unit.
* "spawn": the summon action's effect on the new unit (Shaco's Hallucinate clone). The
  0.25 s the borrowed effect took is kept, so later visuals keep their time.

Groups A to D ignore these events, and B's generic fallback answers none of them.
"""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
AVATAR = 'client/src/stages/137_Avatar.as'
SKILLSET = 'client/src/stages/139_SkillSet.as'

AVATAR_HOOKS = [
    ('abilityFeedback("风暴电荷："+int(abilityState.nextCharge)+"/5","FX_A_1114_MAGIC");',
     'abilityFeedback("风暴电荷："+int(abilityState.nextCharge)+"/5",heroFxClaim106("cast","1114_charge",this) ? "" : "FX_A_1114_MAGIC");'),
    ('abilityFeedback("风暴电荷："+int(abilityState.thunder)+"/3","FX_A_1114_MAGIC");',
     'abilityFeedback("风暴电荷："+int(abilityState.thunder)+"/3",heroFxClaim106("cast","1114_charge",this) ? "" : "FX_A_1114_MAGIC");'),
    ('                  abilityFeedback("风暴引导",effect);',
     '                  abilityFeedback("风暴引导",heroFxClaim106("cast","1114_stand",this) ? "" : effect);'),
    ('            box.abilityFeedback(box.avatarData.name,effect);',
     '            box.abilityFeedback(box.avatarData.name,heroFxClaim106("cast","1128_box",box) ? "" : effect);'),
    ('               if(param6)\n               {\n                  _loc19_ = DisplayTools.getAttrs(param6);',
     '               if(param6 && !heroFxClaim106("direct",param6,this))\n               {\n                  _loc19_ = DisplayTools.getAttrs(param6);'),
    ('         if(isManualSummonUnit && statisticsOwner104 && statisticsOwner104.hp>0) result.push({key:"summon",kind:"summon",target:this});\n'
     '         return result;\n',
     '         if(isManualSummonUnit && statisticsOwner104 && statisticsOwner104.hp>0) result.push({key:"summon",kind:"summon",target:this});\n'
     '         heroFxRowsE106(result);\n'
     '         return result;\n'),
]
SKILLSET_HOOKS = [
    ('         var _loc1_:Object = DisplayTools.getAttrs(param1) as Object;\n'
     '         var _loc2_:Object = null;\n'
     '         if(!_loc1_) return;\n',
     '         var _loc1_:Object = DisplayTools.getAttrs(param1) as Object;\n'
     '         var _loc2_:Object = null;\n'
     '         if(param2 && avatar && avatar.hfxCHook106("direct",param1,param2)) return;\n'
     '         if(!_loc1_) return;\n'),
    ('                  if(!_loc12_)\n'
     '                  {\n'
     '                     _loc12_ = DisplayTools.getAttrs("SUMMON_EFF");\n'
     '                  }\n'
     '                  if(_loc12_)\n'
     '                  {\n',
     '                  if(!_loc12_)\n'
     '                  {\n'
     '                     _loc12_ = DisplayTools.getAttrs("SUMMON_EFF");\n'
     '                  }\n'
     '                  if(_loc12_ && avatar.hfxCHook106("spawn",String(_loc20_[_loc20_.length - 1]),_loc1_))\n'
     '                  {\n'
     '                     _loc12_ = null;\n'
     '                     GameMap.actionDelay += 0.25;\n'
     '                  }\n'
     '                  if(_loc12_)\n'
     '                  {\n'),
]


def patch(relative, hooks):
    path = ROOT / relative
    s = path.read_text('utf-8')
    for old, new in hooks:
        if new in s:
            continue
        if s.count(old) != 1:
            raise ValueError('Missing or ambiguous group E hook in %s: %s' % (relative, old[:110]))
        s = s.replace(old, new, 1)
    path.write_text(s, encoding='utf-8', newline='')


def sync():
    if 'BEGIN HERO FX E 106' not in (ROOT / AVATAR).read_text('utf-8'):
        raise ValueError('Run scripts/sync_hero_fx_106.py first')
    patch(AVATAR, AVATAR_HOOKS)
    patch(SKILLSET, SKILLSET_HOOKS)
    config = ROOT / 'client/build.json'
    cfg = json.loads(config.read_text('utf-8'))
    for row in cfg['stages']:
        if row['source'] in (AVATAR, SKILLSET):
            row['source_sha256'] = hashlib.sha256((ROOT / row['source']).read_bytes()).hexdigest()
    config.write_text(json.dumps(cfg, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('Hero code FX 106 group E: Avatar and SkillSet hooks synchronized')


if __name__ == '__main__':
    sync()
