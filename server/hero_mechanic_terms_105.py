"""Hero mechanic names for skill detail popups.

Each hero family names its own mechanics (stacks, marks, states, resources)
with a color picked from what the mechanic does, away from the popup's
white, gray, yellow and green markup. A name is colored only for avatars
whose skill text uses it. Notes go on a skill that uses a mechanic defined
by another of the hero's skills, so the popup explains it in place.
"""

# Family number -> {mechanic name: color}.
TERMS = {
    1801: {'电浆': 0x3FE0FF},                                   # 卡莎：虚空电能
    1802: {'融入黑夜': 0x8FA8FF},                               # 黑夜亚索：夜色
    1120: {'登神长阶': 0x7FE3FF},                               # 凯尔：天界之光
    1115: {'罪恶快感': 0xFF5FCF},                               # 金克斯：狂热
    1054: {'怒气': 0xFF8A1E, '巨龙真身': 0xFF7043},             # 希瓦娜：龙怒与龙焰
    1036: {'盘丝': 0xFF7FA8},                                   # 伊丽丝：蛛丝
    1030: {'大步流星': 0xFF6FA8},                               # 厄运小姐
    1140: {'共振': 0x4DD8FF, '残影': 0x9DB8FF, '相位打击': 0x4DD8FF},  # 艾克：时间
    1206: {'心印': 0xFF6F91},                                   # 觅心猎手薇恩
    1215: {'声波': 0x9EC9FF, '天音': 0x9EC9FF},                 # 龙的传人李青
    1209: {'彩蛋': 0xFFB36B},                                   # 兔宝宝提莫
    1213: {'持球': 0x6FD3FF, '射门机会': 0x6FD3FF},             # 足球先生伊泽瑞尔
    1210: {'舞步': 0xFF8FD8, '兔刃觉醒': 0xFF8FD8},             # 兔女郎瑞雯
    1211: {'通缉': 0xFFA95E, '捕兽夹': 0xFFA95E},               # 沙漠治安官凯瑟琳
    1204: {'暴露': 0xFF7AA0},                                   # 苹果机器人布里茨
    1216: {'寒冷': 0x9FE8FF, '冰核': 0x9FE8FF},                 # 艾维尼亚：冰霜
    1207: {'魅惑': 0xFF8AD8},                                   # 偶像歌手阿狸
    1221: {'提伯斯': 0xFF7B3A},                                 # 新年安妮
    1029: {'提伯斯': 0xFF7B3A},                                 # 安妮
    1027: {'邪恶之力': 0xE07BFF},                               # 维嘉
    1086: {'月光': 0xC7D4FF},                                   # 黛安娜：月光
    1105: {'狩猎标记': 0xFFAD5C},                               # 奈德丽
    1025: {'瞄准标记': 0xFF9466},                               # 凯瑟琳
    1114: {'风暴电荷': 0x5CE1FF, '电荷': 0x5CE1FF},             # 敖兴：雷暴
    1011: {'火刀标记': 0xFF6A33},                               # 普朗克
    1127: {'恶意魔印': 0xE08CFF},                               # 乐芙兰
    1103: {'虚灵': 0xC59BFF},             # 马尔扎哈：虚空
    1212: {'美味粽子': 0xFFC07A},         # 粽子少女
    1138: {'灰血': 0xD9B38C},                                   # 塔姆
    1133: {'链接': 0xD6A6FF},                                   # 莫甘娜：灵魂镣铐
    1040: {'荆棘植物': 0xFF8FB1, '疗愈': 0xFF8FB1},             # 婕拉
    1218: {'鸦群': 0xD0A8FF},                                   # 幽魂费德提克
    1219: {'旋风': 0x7CF2E0},                                   # 源计划亚索
    1129: {'负面抵消': 0xFF9FD0},                               # 猫女卡特琳娜
}

SLOTS = {'N': 10, 'C': 11, 'P': 13}

# Family number -> {slot: [(mechanic name, one-line note)]}.
NOTES = {
    1801: {'N': [('电浆', '每发命中叠加1层，5层时引爆')]},
    1115: {'N': [('罪恶快感', '本路每死亡1名敌人获得1层，每层持续3回合')],
           'C': [('罪恶快感', '本路每死亡1名敌人获得1层，每层持续3回合')]},
    1120: {'C': [('登神长阶', '每8个战斗回合进阶一次，任队长时每7回合，最多4阶')]},
    1054: {'C': [('巨龙真身', '怒气达到100时永久化龙')]},
    1036: {'C': [('盘丝', '生命低于35%时净化、免疫伤害1回合并跳过下次行动')]},
    1140: {'N': [('共振', '每次命中叠1层，3层引爆')],
           'C': [('共振', '每次命中叠1层，3层引爆'), ('残影', '每次自身行动开始时记录的位置与生命')]},
    1206: {'N': [('心印', '每次命中加1枚，3枚引爆为真实伤害')],
           'C': [('心印', '每次命中加1枚，3枚引爆为真实伤害')]},
    1215: {'C': [('声波', '天音命中的目标留下声波，下次天音优先追击')]},
    1209: {'N': [('彩蛋', '经过1次自身行动成熟，本人中毒结算时引爆附近成熟彩蛋')],
           'C': [('彩蛋', '经过1次自身行动成熟，本人中毒结算时引爆附近成熟彩蛋')]},
    1213: {'C': [('射门机会', '持球友军回球后获得，持续2回合')]},
    1204: {'C': [('暴露', '本路友军对其主动技能伤害提高15%，持续2回合')],
           'P': [('暴露', '本路友军对其主动技能伤害提高15%，持续2回合')]},
    1216: {'C': [('寒冷', '主动位移距离减少50%，不叠层')],
           'P': [('寒冷', '主动位移距离减少50%，不叠层')]},
    1086: {'C': [('月光', '新月打击命中后施加，持续3回合')]},
    1105: {'C': [('狩猎标记', '标枪命中后施加，持续3回合')]},
    1025: {'C': [('瞄准标记', '绳网瞄准命中后施加，持续2回合')]},
    1127: {'C': [('恶意魔印', '再次命中带魔印的目标时，改为真实伤害并沉默')]},
    1207: {'P': [('魅惑', '倾城独唱眩晕生效时施加，持续1回合；友军主动伤害技能优先选择该目标')]},
    1211: {'C': [('通缉', '通缉射击施加，持续1回合；物防穿透比例见小技能')]},
    1218: {'P': [('鸦群', '大招施放时及之后两次自身行动开始，各造成一次全路魔伤')]},
    1219: {'P': [('旋风', '斩钢前两次各积1层，第三次消耗2层并击飞')]},
    1040: {'P': [('疗愈', '治疗本路所有友军100%植物攻击力，满血友军获得净化')]},
}


AOXING_CHARGE_NOTES = {
    'aoxing_c': (('风暴电荷', '连锁闪电每次命中至少1名敌方英雄时获得1层，最多3层'),),
    'six_next_aoxing_c': (('电荷', '施放连锁闪电增加1层；已有5层时再施放会开启引导'),),
}


def _family(aid):
    parts = str(aid).split('_')
    return int(parts[1]) if len(parts) == 3 and parts[1].isdigit() else None


def apply_hero_mechanic_terms(document):
    cfg = document.get('cfg', document)
    if cfg.get('hero_mechanic_terms_105'):
        return document
    avatars, skills = cfg['avatar'], cfg['skill']
    for aid, hero in avatars.items():
        number = _family(aid)
        if number not in TERMS:
            continue
        pl = hero.get('pl') or []
        rows = {slot: skills.get(pl[index]) for slot, index in SLOTS.items()
                if len(pl) > index and pl[index] in skills}
        text = ''.join(str(row.get('info', '')) + str(row.get('rankInfoTemplate', '')) for row in rows.values())
        present = {term: color for term, color in TERMS[number].items() if term in text}
        if not present:
            continue
        hero.setdefault('tipTerms105', {}).update(present)
        family_notes = NOTES.get(number, {})
        for slot, row in rows.items():
            notes = family_notes.get(slot, ())
            if number == 1114 and slot == 'C':
                actions = row.get('skill') or []
                if actions and actions[0][:1] == ['manual_ability'] and len(actions[0]) > 1:
                    notes = AOXING_CHARGE_NOTES.get(actions[0][1], ())
            if not notes:
                continue
            own = row.setdefault('tipNotes105', [])
            for term, note in notes:
                # Only explain names this avatar actually uses, once per skill.
                if term in present and all(existing[0] != term for existing in own):
                    own.append([term, note])
            if not own:
                row.pop('tipNotes105')
    cfg['hero_mechanic_terms_105'] = True
    return document
