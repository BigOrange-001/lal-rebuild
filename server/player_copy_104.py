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
    apply_display_names_104(document)
    from copy_polish_104 import polish_sections
    polish_sections(cfg)
    return document


# Campaign stage titles (after "第N章·"). Short, place-like names instead of narration.
STAGE_TITLES_104 = {
    'M_001_2': '车辙伏兵', 'M_001_3': '夺回观察哨', 'M_001_4': '遗落的补给', 'M_001_5': '先遣集结', 'M_001_6': '封锁营口',
    'M_002_1': '驿路交锋', 'M_002_2': '护桥救援', 'M_002_3': '窄口争先', 'M_002_4': '车队受阻', 'M_002_6': '截击运兵车',
    'M_003_2': '尾随护卫', 'M_003_3': '霜雾火线', 'M_003_4': '林间箭雨', 'M_003_5': '琴声护送',
    'M_004_1': '错层石阶', 'M_004_3': '偏门救护所', 'M_004_4': '巡逻回防', 'M_004_5': '缺口车队',
    'M_005_2': '两军争渡', 'M_005_3': '未成之阵', 'M_005_5': '岸边火力',
    'M_006_2': '且退且战', 'M_006_3': '封锁桥口', 'M_006_4': '桥洞伏兵', 'M_006_5': '断桥压制', 'M_006_6': '关隘疑阵',
    'M_007_1': '藤蔓暗哨', 'M_007_2': '绕行铁甲', 'M_007_3': '旧道路障', 'M_007_4': '风口营地', 'M_007_5': '迂回补给线', 'M_007_6': '猎队封路',
    'M_008_1': '未收的营帐', 'M_008_4': '篝火两侧', 'M_008_5': '截断车尾',
    'M_009_1': '箭鸣街口', 'M_009_2': '伪装维修队', 'M_009_3': '空街刺影', 'M_009_4': '巷口集结', 'M_009_5': '死守哨兵', 'M_009_6': '熄灯封门',
    'M_010_1': '墙根护车', 'M_010_3': '绕墙尖兵', 'M_010_5': '仓促火线',
    'M_011_1': '裂谷探路者', 'M_011_2': '独守双隘', 'M_011_3': '护送法师', 'M_011_4': '崖边射击线', 'M_011_5': '夜袭五人组',
    'M_012_1': '散乱护送队', 'M_012_2': '腹背卸货', 'M_012_3': '烟尘蛇影', 'M_012_5': '双重路障', 'M_012_6': '灰烬出口',
    'M_013_1': '淤泥路标', 'M_013_2': '交错巡游', 'M_013_3': '三渠守门人', 'M_013_4': '殿后的钟表匠',
    'M_014_1': '石阶守队', 'M_014_2': '守门人与访客', 'M_014_3': '前院暗沟', 'M_014_4': '冰封会合点', 'M_014_5': '阶上余火', 'M_014_6': '封锁地基',
    'M_015_1': '未爆引线', 'M_015_2': '空寂御道', 'M_015_3': '双刀岔口', 'M_015_4': '最后的潮声',
    'M_016_1': '半开城门', 'M_016_2': '穿越内门', 'M_016_3': '黎明封街',
    'M_017_1': '二次靠岸', 'M_017_2': '仓门火光', 'M_017_3': '缆绳截击',
    'M_018_1': '矿道守夜人', 'M_018_2': '矿车让道',
    'M_019_1': '钟楼后队', 'M_019_2': '死守台阶', 'M_019_3': '钟声骤停',
    'M_020_1': '上下桥之争', 'M_020_2': '两端刀锋', 'M_020_3': '高架尽头',
    'M_021_1': '半掩之门', 'M_021_2': '水声掩步', 'M_021_3': '暗门合拢',
    'M_022_1': '猎场外围', 'M_022_2': '无声火力',
    'M_023_1': '迟到三人组', 'M_023_2': '庭院残兵',
    'M_024_1': '冰面间隙', 'M_024_2': '沿镜墙而行', 'M_024_3': '碎镜出口',
    'M_025_1': '截断游行', 'M_025_2': '仪仗让路', 'M_025_3': '舞台外近卫',
    'M_026_1': '长廊残组', 'M_026_2': '迎面巡检', 'M_026_3': '三道机关门',
    'M_027_1': '脱队演员', 'M_027_2': '最后的看守', 'M_027_3': '封锁花车道',
    'M_028_1': '开场近卫', 'M_028_2': '看台观察队', 'M_028_3': '广场清场',
    'M_029_1': '台阶分兵', 'M_029_2': '横穿广场', 'M_029_3': '议事厅闭门',
    'M_030_1': '中庭三点', 'M_030_2': '最后一班岗', 'M_030_3': '终幕五人',
}

# Enemy units whose original names were never recovered (shown as "X阶英雄·序号N").
# Named from their kits so players see a readable name in battle and statistics.
UNIT_NAMES_104 = {
    'A_1140': '冰晶射手', 'A_1224': '霜羽游侠', 'A_1908': '寒星猎手',
    'A_1225': '奥能行者', 'A_1906': '逆流法剑', 'A_1996': '法能学徒', 'A_1999': '反转剑士',
    'A_1907': '正义执剑者', 'A_1910': '审判骑士', 'A_1997': '裁决卫士',
    'A_2305': '节肢助手', 'A_2326': '荆棘植物',
}

RESOURCE_TIERS_104 = ('初级', '中级', '高级', '精英', '传说')


def display_stage_name_104(stage_id, name):
    if not isinstance(name, str):
        return name
    title = STAGE_TITLES_104.get(stage_id)
    if title and '·' in name:
        return name.split('·', 1)[0] + '·' + title
    match = re.fullmatch(r'(.+?)·难度(\d+)', name)
    if match and 1 <= int(match.group(2)) <= len(RESOURCE_TIERS_104):
        return f'{match.group(1)}副本·{RESOURCE_TIERS_104[int(match.group(2)) - 1]}'
    return re.sub(r'^远古试炼·第(\d+)档$', r'远古试炼·第\1关', name)


def apply_display_names_104(document):
    cfg = document.get('cfg', document)
    for holder in (cfg, document.get('pve', {}), document):
        if not isinstance(holder, dict):
            continue
        for section in ('combat_main', 'combat_ploy'):
            for stage_id, stage in (holder.get(section) or {}).items():
                if isinstance(stage, dict) and 'name' in stage:
                    stage['name'] = display_stage_name_104(stage_id, stage['name'])
    for aid, hero in cfg.get('avatar', {}).items():
        family = '_'.join(aid.split('_')[:2])
        if family in UNIT_NAMES_104 and re.search(r'序号|待识别', str(hero.get('name', ''))):
            hero['name'] = UNIT_NAMES_104[family]
    return document
