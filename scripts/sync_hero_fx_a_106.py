"""Group A cast hooks for the code-painted hero effects (run after sync_hero_fx_106.py).

Four captain skills have presentation that no existing event covers: Sona's encore
(allies are purified and powered), the judge's court seal, Teemo's egg parade (eggs
are planted with no hit at all) and Blitzcrank's reboot (allies purified). Each hook
is a single heroFxClaim106("cast", ...) line at the start of the skill's case; group A
claims it in client/src/hero_fx_a_106.aspart. Presentation only, idempotent.
"""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parents[1]
CASE = '               case {family}:\n'
HOOKS = [
    (1228, '                  for each(unit in targets) {abilityControl(unit,"stun",1);s2Hit(unit,s2Value(skill,"hit"));}\n',
     '                  heroFxClaim106("cast","1228_ult",target,{allies:allies});\n'),
    (1214, '                  for each(unit in targets) {s2Hit(unit,s2Value(skill,"hit"));count=s2Dispel(unit,true);',
     '                  heroFxClaim106("cast","1214_ult",target);\n'),
    (1209, '                  if(!skin2.eggs) skin2.eggs=[];\n                  for each(unit in targets.slice(0,3))\n',
     '                  heroFxClaim106("cast","1209_ult",target,{targets:targets.slice(0,3)});\n'),
    (1204, '                  for each(unit in allies) {unit.addBuff("purify",1);s2Shield(unit,s2Value(skill,"shield"));}\n',
     '                  heroFxClaim106("cast","1204_ult",target,{allies:allies});\n'),
]


def sync():
    avatar = ROOT / 'client/src/stages/137_Avatar.as'
    s = avatar.read_text('utf-8')
    if 'private function heroFxClaimA106(' not in s:
        raise ValueError('Run scripts/sync_hero_fx_106.py first')
    for family, body, hook in HOOKS:
        if hook in s:
            continue
        old = CASE.format(family=family) + body
        if s.count(old) != 1:
            raise ValueError(f'Missing or ambiguous captain case for {family}')
        s = s.replace(old, CASE.format(family=family) + hook + body, 1)
    avatar.write_text(s, encoding='utf-8', newline='')

    config = ROOT / 'client/build.json'
    cfg = json.loads(config.read_text('utf-8'))
    for row in cfg['stages']:
        if row['source'] == 'client/src/stages/137_Avatar.as':
            row['source_sha256'] = hashlib.sha256(avatar.read_bytes()).hexdigest()
    config.write_text(json.dumps(cfg, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('Hero code FX 106 group A: cast hooks synchronized')


if __name__ == '__main__':
    sync()
