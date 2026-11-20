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
    cleaned = {}
    for aid, hero in cfg.get('avatar', {}).items():
        if aid.startswith('A_2024_'):
            hero['name'] = '哮天犬'
    def visit(value):
        if isinstance(value, dict):
            for key, child in value.items():
                if key in TEXT_FIELDS and isinstance(child, str):
                    if child not in cleaned:
                        cleaned[child] = clean_player_text(child)
                    value[key] = cleaned[child]
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


# Campaign stage titles (after "第N章·"). Every main stage is covered; see docs/stage-rename-proposal.md.
# Boss stages (each chapter's last stage) use a story-style line instead of the hero's title.
STAGE_TITLES_104 = {
    'M_001_1': '黑默丁格炮台', 'M_001_2': '潘森空降', 'M_001_3': '第一波兵线', 'M_001_4': '武器大师', 'M_001_5': '德玛西亚皇子', 'M_001_6': '佣兵的价码',
    'M_002_1': '德玛西亚之力', 'M_002_2': '众星的祈愿', 'M_002_3': '凯南闪电', 'M_002_4': '布里茨钩人', 'M_002_5': '约德尔哨点', 'M_002_6': '剑魔觉醒',
    'M_003_1': '赵信探草', 'M_003_2': '黄昏之幕', 'M_003_3': '艾尼维亚冰墙', 'M_003_4': '艾希鹰眼', 'M_003_5': '娑娜琴声', 'M_003_6': '不祥的预感',
    'M_004_1': '冰晶凤凰', 'M_004_2': '推线进塔', 'M_004_3': '众星之子', 'M_004_4': '灯柱下的宗师', 'M_004_5': '炮车兵压境', 'M_004_6': '强者为尊',
    'M_005_1': '冰河上的娑娜', 'M_005_2': '德玛西亚双璧', 'M_005_3': '炮台还没架好', 'M_005_4': '孤军踏冰', 'M_005_5': '岸边的炮声', 'M_005_6': '凛冬的号角',
    'M_006_1': '曙光女神', 'M_006_2': '放风筝的探险家', 'M_006_3': '魂锁典狱长', 'M_006_4': '菲兹潜伏', 'M_006_5': '墨菲特开团', 'M_006_6': '真假妖姬',
    'M_007_1': '婕拉的藤蔓', 'M_007_2': '希瓦娜龙化', 'M_007_3': '披甲龙龟', 'M_007_4': '迦娜的风口', 'M_007_5': '入侵野区', 'M_007_6': '猎手的战利品',
    'M_008_1': '营地里的酒香', 'M_008_2': '光芒引路', 'M_008_3': '硬闯红区', 'M_008_4': '营火边的雷兹', 'M_008_5': '皇子的军旗', 'M_008_6': '九尾的魅惑',
    'M_009_1': '艾希的冷箭', 'M_009_2': '突然的gank', 'M_009_3': '无灯处的刀光', 'M_009_4': '没插眼的巷口', 'M_009_5': '暮光之眼', 'M_009_6': '灯灭之时',
    'M_010_1': '强拆二塔', 'M_010_2': '烈阳之盾', 'M_010_3': '菲兹绕后', 'M_010_4': '提灯的狱卒', 'M_010_5': '荆棘花园', 'M_010_6': '刀锋起舞',
    'M_011_1': '猛龙摆尾', 'M_011_2': '无尽怒火', 'M_011_3': '安妮与提伯斯', 'M_011_4': '赏金猎人', 'M_011_5': '伊芙琳夜袭', 'M_011_6': '失控的力量',
    'M_012_1': '疾风剑豪', 'M_012_2': '法外狂徒', 'M_012_3': '魔蛇的毒雾', 'M_012_4': '火龙争夺战', 'M_012_5': '绷带与果冻', 'M_012_6': '虚空裂隙',
    'M_013_1': '趁乱偷大龙', 'M_013_2': '提莫的蘑菇', 'M_013_3': '瓦洛兰之盾', 'M_013_4': '操控时间的老人', 'M_013_5': '命运的卡牌', 'M_013_6': '隐匿的暗影',
    'M_014_1': '强上高地', 'M_014_2': '圣锤之毅', 'M_014_3': '实验室逃逸者', 'M_014_4': '冰霜女巫', 'M_014_5': '亚索的风墙', 'M_014_6': '皇帝的归来',
    'M_015_1': '爆破鬼才', 'M_015_2': '萨科的盒子', 'M_015_3': '影流之主', 'M_015_4': '娜美的潮汐', 'M_015_5': '兵临水晶', 'M_015_6': '突破水晶',
    'M_016_1': '圣枪游侠', 'M_016_2': '不朽堡垒', 'M_016_3': '生命与死亡',
    'M_017_1': '飞舞的刀刃', 'M_017_2': '火烧货仓', 'M_017_3': '海神的考验',
    'M_018_1': '矿道里的稻草人', 'M_018_2': '带刺的甲壳', 'M_018_3': '风暴来袭',
    'M_019_1': '基兰拨钟', 'M_019_2': '失控的巨鳄', 'M_019_3': '血色钟声',
    'M_020_1': '双城的枪声', 'M_020_2': '浪人与刺客', 'M_020_3': '致命的拥抱',
    'M_021_1': '魔影迷踪', 'M_021_2': '拉克丝驱雾', 'M_021_3': '孤独的木乃伊',
    'M_022_1': '雷恩加尔潜猎', 'M_022_2': '羊灵与狼灵', 'M_022_3': '队长待命',
    'M_023_1': '故乡的剑舞', 'M_023_2': '抱熊的女孩', 'M_023_3': '无双挑战',
    'M_024_1': '冰下的女王', 'M_024_2': '冰桥上的倒影', 'M_024_3': '破冰之光',
    'M_025_1': '猫女截游行', 'M_025_2': '黄金骑士开道', 'M_025_3': '盛典的第一箭',
    'M_026_1': '长廊上的羽翼', 'M_026_2': '苹果味的铁钩', 'M_026_3': '猎取芳心',
    'M_027_1': '偶像歌手开唱', 'M_027_2': '护士查房', 'M_027_3': '复活节的惊喜',
    'M_028_1': '兔女郎开场', 'M_028_2': '看台上的狙击', 'M_028_3': '源计划启动',
    'M_029_1': '逆转裁判开庭', 'M_029_2': '龙的传人横扫', 'M_029_3': '殿堂里的恶魔',
    'M_030_1': '圣诞维嘉送礼', 'M_030_2': '幽魂出没', 'M_030_3': '全明星决战',
}

# Campaign chapter names, keyed by battle_main ID. Green→orange follows the Rift (lane → jungle →
# epic monsters → Nexus), then Runeterra regions, then the all-skin finale.
CHAPTER_TITLES_104 = {
    'M_001': '泉水出发', 'M_002': '三路兵线', 'M_003': '迷雾草丛', 'M_004': '一塔之争', 'M_005': '冰封河道',
    'M_006': '中路河口', 'M_007': '蓝区密林', 'M_008': '红区营地', 'M_009': '视野盲区', 'M_010': '二塔攻坚',
    'M_011': '峡谷先锋', 'M_012': '炼狱龙坑', 'M_013': '男爵巢穴', 'M_014': '高地塔前', 'M_015': '水晶枢纽',
    'M_016': '诺克萨斯', 'M_017': '屠宰码头', 'M_018': '祖安矿道', 'M_019': '皮城钟楼', 'M_020': '双城天桥',
    'M_021': '暗影群岛', 'M_022': '扭曲丛林', 'M_023': '艾欧尼亚', 'M_024': '嚎哭深渊', 'M_025': '盛典开幕',
    'M_026': '炫彩长廊', 'M_027': '狂欢巡游', 'M_028': '荣耀赛场', 'M_029': '英雄殿堂', 'M_030': '王者之巅',
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
        for chapter_id, chapter in (holder.get('battle_main') or {}).items():
            if isinstance(chapter, dict) and chapter_id in CHAPTER_TITLES_104:
                chapter['name'] = CHAPTER_TITLES_104[chapter_id]
        for section in ('combat_main', 'combat_ploy'):
            for stage_id, stage in (holder.get(section) or {}).items():
                if isinstance(stage, dict) and 'name' in stage:
                    stage['name'] = display_stage_name_104(stage_id, stage['name'])
    for aid, hero in cfg.get('avatar', {}).items():
        family = '_'.join(aid.split('_')[:2])
        if family in UNIT_NAMES_104 and re.search(r'序号|待识别', str(hero.get('name', ''))):
            hero['name'] = UNIT_NAMES_104[family]
    return document
