"""Apply the weighted cultivation, enchantment and chapter reward rules.

Usage: python scripts/cultivation_equipment_overlay.py INPUT OUTPUT
An idempotent overlay; existing profiles are migrated by PlayerStore, not here.
"""
import copy
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'server'))
from cultivation_rules import apply_cultivation_config
from equipment_magic import apply_equipment_magic_config


BOND_DESCRIPTIONS = {
    'demacia': '德玛西亚守护：盖伦、嘉文、赵信齐上阵\n紫卡技能伤害／治疗／护盾＋30%\n施放后自身获20%恢复基数护盾（1回合）',
    'frost': '凛冬同盟：艾希、瑟庄妮、丽桑卓齐上阵\n紫卡技能伤害／治疗／护盾＋30%\n前两名命中敌人攻击－10%（1回合）',
    'harmony': '和声庇护：索拉卡、娑娜、迦娜齐上阵\n紫卡技能伤害／治疗／护盾＋30%\n施放后治疗本路最低血友军20%恢复基数',
}


def apply_rules(document):
    output = apply_equipment_magic_config(apply_cultivation_config(document))
    cfg = output['cfg']
    for bond in cfg['system_simple'].get('purple_bonds', []):
        bond['required'] = len(bond['families'])
        if bond['id'] in BOND_DESCRIPTIONS:
            bond['short_info'] = BOND_DESCRIPTIONS[bond['id']]
            bond['info'] = bond['short_info']
    gifts = cfg.setdefault('pass_battle_gift', {})
    for difficulty, multiplier in (('0', 1), ('1', 2)):
        tier = gifts.setdefault(difficulty, {})
        for bid, chapter in cfg['battle_main'].items():
            if bid.startswith('M_'):
                number = int(bid.split('_')[1])
                tier[bid] = {'need_star': int(chapter['combat']) * 3,
                             'gift': {'coin': number * 60 * multiplier}}
    gifts.setdefault('-1', {})['P_200'] = {
        'need_star': 300, 'gift': {'coin': 66666666}}
    # Some cached bootstrap readers use the top-level table. Keep it equal to
    # the authoritative cfg table instead of maintaining a second balance.
    output['pass_battle_gift'] = copy.deepcopy(gifts)
    return output


def main():
    if len(sys.argv) != 3:
        raise SystemExit('usage: cultivation_equipment_overlay.py INPUT OUTPUT')
    source, target = map(Path, sys.argv[1:])
    document = json.loads(source.read_text(encoding='utf-8'))
    target.write_text(json.dumps(apply_rules(document), ensure_ascii=False,
                                 separators=(',', ':')) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
