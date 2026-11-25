"""Group B extra hooks for the code-painted hero effects (run after sync_hero_fx_106.py).

One presentation event the shared hooks do not cover, a single heroFxClaim106 line:
  * "summon": a summoned unit entering the battle tells its owner (Malzahar's voidling portal).
Idempotent; only adds calls into the effect core.
"""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]

HOOKS = [
    ('         demonStart105();\n         ready();\n      }\n',
     '         demonStart105();\n         ready();\n'
     '         if(statisticsOwner104 && statisticsOwner104!==this) statisticsOwner104.heroFxClaim106("summon","summon",this);\n      }\n'),
]


def sync():
    avatar = ROOT / 'client/src/stages/137_Avatar.as'
    s = avatar.read_text('utf-8')
    if 'BEGIN HERO FX B 106' not in s:
        raise ValueError('Run scripts/sync_hero_fx_106.py first')
    for old, new in HOOKS:
        if new in s:
            continue
        if s.count(old) != 1:
            raise ValueError('Missing or ambiguous group B hook: ' + old[:110])
        s = s.replace(old, new, 1)
    avatar.write_text(s, encoding='utf-8', newline='')

    config = ROOT / 'client/build.json'
    cfg = json.loads(config.read_text('utf-8'))
    for row in cfg['stages']:
        if row['source'] == 'client/src/stages/137_Avatar.as':
            row['source_sha256'] = hashlib.sha256(avatar.read_bytes()).hexdigest()
    config.write_text(json.dumps(cfg, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('Hero code FX 106 group B: summon hook synchronized')


if __name__ == '__main__':
    sync()
