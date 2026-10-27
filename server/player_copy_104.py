"""Player-facing copy only. Run after numeric/variant generation, never on rules."""
import re

TEXT_FIELDS = {'info', 'info_tw', 'description', 'description_cn', 'description_tw',
               'rankInfoTemplate', 'reward_note'}
REPLACEMENTS = {
    '原生反击': '反击', '原生同路集火': '同路集火',
    '施加时攻击力': '攻击力', '当前生命比例': '生命比例',
    '实际扣血总伤害': '总伤害', '自身实时总攻击力': '自身攻击力',
    '不是粽子死亡触发': '',
    '每次初始施放最多传播一次，不重置剩余次数和伤害快照': '最多传播一次，保留剩余持续时间',
    '每次释放开始时锁定结算次数为1＋本局累计击杀数': '攻击次数为1＋本场累计击杀数',
    '每次结算重新随机选择': '每次攻击随机选择',
    '本次新增击杀从下次释放起增加结算次数': '本次击杀增加下次施放的攻击次数',
    '中毒基础值按下述持续伤害规则结算': '中毒',
    '中毒，中毒': '中毒',
    '在自身所在分路的接口默认召唤位置生成一个粽子': '在本路召唤一个粽子',
    '先施加减益再结算伤害': '先施加减益再造成伤害',
    '当前采用击杀触发的兼容方案，不是粽子死亡触发；未实现其他粽子攻击力增加10%并无限叠加。': '',
}
PATTERNS = [
    (r'[，,；;]?(?:中毒|灼烧)?(?:并)?沿用原版(?:附加|结算|触发)?规则', ''),
    (r'[，,；;]?嘲讽目标遵循原生优先规则', ''),
    (r'眩晕按原生命中与闪避结算[。；]?', ''),
    (r'穿透上限\d+(?:\.\d+)?%[；;。]?', ''),
    (r'与其他破甲、穿透效果只取最高值，不叠加[。；]?', ''),
    (r'[，,]?作为独立乘区结算', ''),
    (r'层内加算，与其他攻击增益独立乘算[。；]?', ''),
    (r'该部分按技能等效收益的[^。]*。', ''),
    (r'原设计的[^。\n]*暂未实现[^。\n]*。', ''),
    (r'当前采用击杀触发的兼容方案[^。]*。', ''),
    (r'(?:强化每级|两项倍率每级)[^。；\n]*[。；]?', ''),
    (r'(^|[。；\n])[^。；\n]*线性成长[^。；\n]*[。；]?', r'\1'),
    (r'治疗比例不随等级成长[。；]?', ''),
    (r'准备(?:时间)?[：:]?\s*\d+\s*(?:回合)?[，,；;、\s]+冷却(?:时间)?[：:]?\s*\d+\s*(?:回合)?[。；;]?', ''),
    (r'[，,]?不随(?:技能)?等级成长', ''),
    (r'首选无目标才回退另一组，无目标则不施法。', ''),
    (r'两段均使用力量生效后的攻击力。', ''),
    (r'破盾溢出按原伤害额度扣血[。；]?', ''),
    (r'召唤属性按施法者召唤当刻的完整面板和技能倍率折算，天赋与光环仅计入一次[。；]?', ''),
    (r'本轮为同次立即结算，不使用延迟标记[。；]?', ''),
    (r'本体小技能的驱散和中毒延期[。；]?', ''),
    (r'召唤编号\d+的单位（[^）]*）协同作战', '召唤灵兽协同作战'),
    (r'（不叠加）', ''),
    (r'[，；]\s*。', '。'),
    (r'。\s*。', '。'),
]

def clean_player_text(text):
    if not isinstance(text, str):
        return text
    # Long, specific substitutions must precede shorter terminology changes.
    for old, new in sorted(REPLACEMENTS.items(), key=lambda pair: -len(pair[0])):
        text = text.replace(old, new)
    for pattern, replacement in PATTERNS:
        text = re.sub(pattern, replacement, text)
    return text.strip()

def apply_player_copy_104(document):
    cfg = document.get('cfg', document)
    for aid, hero in cfg.get('avatar', {}).items():
        if aid.startswith('A_2024_'):
            hero['name'] = '哮天犬'
    def visit(value):
        if isinstance(value, dict):
            for key, child in value.items():
                if key in TEXT_FIELDS and isinstance(child, str):
                    value[key] = clean_player_text(child)
                elif isinstance(child, (dict, list)):
                    visit(child)
        elif isinstance(value, list):
            for child in value:
                visit(child)
    # Restrict traversal to player catalogs; audit/debug metadata is not UI copy.
    for section in ('avatar','skill','equip','talent','battle_main','combat_main',
                    'battle_ploy','combat_ploy','battle_association','combat_association',
                    'destiny','guide','task','vip','system_simple'):
        visit(cfg.get(section, {}))
    # Some historical descriptions were scaled as prose rather than from the
    # live action. Repair their displayed numbers without changing mechanics.
    for row in cfg.get('skill', {}).values():
        actions=row.get('skill', [])
        for field in ('info','rankInfoTemplate'):
            text=row.get(field)
            if not isinstance(text,str):continue
            if field=='info' and row.get('calibration_104'):
                def bind_review(match):
                    kind,index,path=match.groups()
                    value=actions[int(index)]
                    for part in path.split('.'):value=value[int(part)]
                    value*=row.get('rankDisplayFactors104',{}).get(index+':'+path,1)
                    return f'{value*100:.1f}%' if kind=='rank' else str(round(value))
                text=re.sub(r'\{(rank|flat):(\d+):([0-9.]+)\}',bind_review,text)
            if row.get('name') == '唤犬令':
                text = '召唤哮天犬协同作战。'
            if any(a[:2]==['manual_ability','alistar_c'] for a in actions):
                if row.get('calibration_104'):
                    heal=.5*row.get('manualEffectMultiplier',1)*.8*100
                    text=f'清除自身负面效果，恢复{heal:.1f}%攻击力＋{heal/10:.1f}%自身生命上限的生命；获得80%减伤，持续至下次自身行动。'
                reduction=min(100,55*row.get('manualEffectMultiplier',1))
                text=re.sub(r'直接伤害降低[\d.]+%',f'直接伤害降低{reduction:.1f}%',text)
            if any(a[0]=='bless' for a in actions):
                revive=cfg['system_simple']['attack'][20]*100
                text=re.sub(r'以最大生命值[\d.]+%复活',f'恢复{revive:.1f}%最大生命',text)
            for action in actions:
                if action[0]=='conditional_damage' and action[3]=='prehit_bleed':
                    text=re.sub(r'倍率提高至[\d.]+%',f'倍率提高至{(action[1]+action[4])*100:.1f}%',text)
            if row.get('name')=='悲伤收割' and len(actions)>=6 and actions[0][0]=='cure':
                heal=actions[0][1]*100
                damage=[a[1]*100 for a in actions if a[0] in ('weak','silence','damage')]
                weak=next(a[3]*100 for a in actions if a[0]=='weak')
                text=(f'击杀敌人时，为友军恢复{heal:.1f}%攻击力＋{heal/10:.1f}%自身最大生命并净化1回合；'
                      f'自身获得嘲讽1回合。对全体敌人造成'+ '、'.join(f'{x:.1f}%' for x in damage)+
                      f'攻击力的3段真实伤害，并施加{weak:.1f}%衰弱和沉默，持续1回合。')
            row[field]=text
    if cfg.get('skin_revision_v2_104'):
        from skin_revision_104 import refresh_bond_copy
        refresh_bond_copy(cfg)
    return document
