"""Author the versioned bond catalogue (no mutation of hero/save data)."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[1]
# First member receives the only mechanism change in a 3+ member bond.
# Relations marked as role/fan settings are intentionally original designs.
GROUPS = [
 ('德玛西亚守护','region',[1009,1001,1007],'guard'),
 ('光盾王庭','region',[1007,1054,1060,1130],'banner'),
 ('不屈前锋','role',[1001,1019],'guard'),
 ('光明之誓','region',[1060,1001],'light'),
 ('龙血禁卫','region',[1054,1009],'guard'),
 ('虚空破阵','role',[1097,1008],'duel'),
 ('潜锋壁垒','role',[1018,1015,1077],'guard'),
 ('忍法诡术','role',[1022,1018],'assassin'),
 ('暗夜追猎','role',[1023,1010,1136,1033],'assassin'),
 ('无声猎杀','role',[1033,1128],'assassin'),
 ('伏击双锋','role',[1105,1023],'assassin'),
 ('疾风剑心','role',[1119,1012,1056],'duel'),
 ('霜锁剑诀','role',[1012,1117],'duel'),
 ('幻世灵契','skin',[1139,1134,1138,1227,1132],'light'),
 ('灵境守望','role',[1082,1126],'light'),
 ('雷霆武道','role',[1016,1026,1005],'storm'),
 ('离群之刃','role',[1015,1056],'assassin'),
 ('意志锋芒','role',[1024,1119],'duel'),
 ('远古符文','region',[1003,1095],'light'),
 ('奥术风暴','role',[1126,1003,1114],'storm'),
 ('凛冬战歌','role',[1049,1002,1006],'frost'),
 ('阿瓦罗萨','region',[1002,1028],'frost'),
 ('冰原守望','region',[1081,1073,1106],'frost'),
 ('寒地坚壁','role',[1073,1049],'guard'),
 ('冰封突阵','role',[1005,1081],'frost'),
 ('狂战士','role',[1028,1101,1113],'duel'),
 ('酒与火药','role',[1106,1011],'storm'),
 ('比尔吉沃特','region',[1030,1011,1053,1096],'barrage'),
 ('双枪追猎','role',[1053,1136],'barrage'),
 ('深渊守望','role',[1143,1052,1205],'tide'),
 ('潮汐回响','role',[1131,1052],'tide'),
 ('雾港同行','role',[1142,1030],'tide'),
 ('风雪庇护','role',[1004,1117,1094],'light'),
 ('巨神峰之光','region',[1020,1017,1086,1093],'light'),
 ('月下和弦','role',[1086,1006],'light'),
 ('星辰旅人','region',[1004,1093],'light'),
 ('不屈凡人','role',[1017,1008],'duel'),
 ('皮城守望','region',[1025,1021,1041],'barrage'),
 ('明日科技','role',[1041,1071,1014,1125],'storm'),
 ('野性铁拳','role',[1123,1013],'guard'),
 ('双城追逐','region',[1115,1025],'barrage'),
 ('爆破狂欢','role',[1125,1115,1083],'barrage'),
 ('爆裂工坊','role',[1014,1029],'storm'),
 ('风与炼金','region',[1094,1112,1099],'tide'),
 ('不息生灵','role',[1112,1142],'guard'),
 ('班德尔远征','region',[1082,1083,1045,1108,1123],'barrage'),
 ('幻境奇术','role',[1045,1022],'light'),
 ('钢心守卫','role',[1108,1071],'guard'),
 ('黑暗童话','role',[1027,1029,1128],'storm'),
 ('熔炉过载','role',[1068,1013],'storm'),
 ('诡术盟约','region',[1127,1063,1109],'assassin'),
 ('帝国铁壁','region',[1019,1127],'banner'),
 ('猩红锁链','role',[1109,1032],'tide'),
 ('毒性蔓延','role',[1063,1040],'tide'),
 ('幽冥异客','skin',[1137,1103,1132,1139,1138],'grave'),
 ('命运契约','role',[1096,1032],'grave'),
 ('腐毒荒林','role',[1099,1205],'grave'),
 ('诡林惊惧','role',[1205,1036],'grave'),
 ('荆棘密林','role',[1040,1036,1105],'tide'),
 ('猎杀双锋','role',[1135,1010],'assassin'),
 ('宿命猎杀','region',[1097,1135],'assassin'),
 ('虚空冥约','skin',[1134,1137,1103],'assassin'),
 ('破界锋芒','role',[1130,1024],'storm'),
 ('沙漠帝国','region',[1124,1101,1078,1090],'banner'),
 ('沙海宝藏','region',[1078,1021],'barrage'),
 ('古墓守卫','role',[1074,1090],'guard'),
 ('远古守护','role',[1077,1085,1095],'guard'),
 ('雷霆壁垒','role',[1085,1016],'guard'),
 ('孤独灵魂','role',[1074,1079],'grave'),
 ('堕落天翼','role',[1120,1133],'light'),
 ('天界裁决','fan',[1998,1120],'light'),
 ('暗裔战火','region',[1113,1133],'grave'),
 ('龙与烈焰','fan',[1114,1098,1143],'storm'),
 ('烈焰法王','role',[1098,1068],'storm'),
 ('金甲神将','skin',[1226,1201,1215],'banner'),
 ('神装破阵','skin',[1222,1226],'duel'),
 ('极地救援','skin',[1202,1309],'frost'),
 ('冬夜急援','skin',[1217,1202,1208],'frost'),
 ('节庆巡演','skin',[1221,1217,1207],'light'),
 ('新春佳节','skin',[1212,1221],'light'),
 ('兔耳派对','skin',[1210,1209],'duel'),
 ('假面夜行','skin',[1129,1209,1208],'assassin'),
 ('舞会护卫','skin',[1210,1201,1206],'duel'),
 ('羽翼追猎','skin',[1216,1206],'light'),
 ('夜色魅影','skin',[1206,1129,1208],'assassin'),
 ('端午舞台','skin',[1228,1212],'light'),
 ('全明星赛','skin',[1213,1207,1228],'barrage'),
 ('司法追猎','skin',[1211,1214,1223],'barrage'),
 ('夜幕追猎','skin',[1223,1218],'barrage'),
 ('冠军契约','skin',[1214,1213],'duel'),
 ('未来战线','skin',[1219,1204,1222,1310],'storm'),
 ('机械与气焰','skin',[1204,1311],'guard'),
 ('英雄降临','fan',[1309,1222,1311],'duel'),
 ('合金羽翼','skin',[1310,1216],'duel'),
 ('恶魔幽影','skin',[1203,1218],'grave'),
 ('夜巡执法','skin',[1201,1203,1211],'grave'),
 ('疾风龙拳','skin',[1219,1215],'duel'),
 ('日光潮汐','role',[1020,1131],'light'),
 ('帝王威仪','role',[1124,1027],'storm'),
 ('天火圣辉','fan',[1998,1098],'light'),
 ('年节乐章','skin',[1221,1228],'light'),
 ('寒霜议会','region',[1081,1002,1117,1049],'frost'),
 ('艾欧尼亚护法','role',[1018,1015,1016,1026],'guard'),
 ('战地救援','role',[1004,1006,1131,1094],'light'),
 ('幽冥攻防','role',[1032,1142,1136,1079],'grave'),
 ('赏金猎团','role',[1053,1096,1105,1135],'barrage'),
 ('奇境夜巡','skin',[1217,1202,1216,1218],'frost'),
 ('符文灾变','role',[1003,1068,1126,1029,1027],'storm'),
 ('机械火力','role',[1071,1041,1013,1014,1115],'storm'),
 ('武道争锋','role',[1008,1012,1005,1056,1130],'duel'),
 ('白蛇端阳','skin',[1227,1212],'light'),
]


def mechanism(name, style, replace=False, captain=False):
    # Tactical niches: front-line protection, anti-buff assassination,
    # sustained armor breaking, cross-lane rescue, and siege fire.
    fx = 'FX60_SLASH_COMBO'
    damage = 4.5 if captain else 2.7
    if style in ('guard', 'banner'):
        actions = [['caster_hp_shield', .35 if captain else .18, 2, 'FX60_SHIELD'], ['purify', 1, 'FX60_PURIFY']]
        policies = ['ally_all' if captain else 'ally_self'] * 2
        caps = [3 if captain else 1] * 2
        info = '为三名友军提供施法者35%最大生命护盾并净化，持续2回合。' if captain else '获得自身18%最大生命护盾并净化，持续2回合。'
        if replace:
            actions.insert(0, ['sunder_percent', damage, 1, .25, 2, fx]); policies.insert(0, 'enemy_lane_frontmost'); caps.insert(0, 1)
            info = f'先对前排造成{damage*100:g}%攻击伤害并削弱25%双防2回合；' + info
    elif style in ('light', 'tide'):
        actions = [['cure', 3.5 if captain else 1.2, 'FX60_HEAL'], ['purify', 1, 'FX60_PURIFY']]
        policies = ['ally_all' if captain else 'ally_lane_lowest_current_hp_hero'] * 2
        caps = [3 if captain else 1] * 2
        info = f'治疗{"三名友军" if captain else "本路最低生命英雄"}{350 if captain else 120}%恢复基数并净化。'
    elif style in ('assassin', 'grave'):
        actions = [['dispel_good', 1, 'FX60_PURIFY'], ['damage', damage if replace else .5, 1, fx]]
        policies = ['enemy_global_lowest_hp_ratio_hero'] * 2
        caps = [1, 1]
        info = f'跨路追击最低生命比例英雄，驱散增益并造成{(damage if replace else .5)*100:g}%攻击伤害。'
    elif style == 'frost':
        actions = [['weak_percent', damage if replace else .4, 2, .2, 2, 'FX60_WEAK']]
        policies = ['enemy_lane_frontmost']; caps = [3 if captain else 2]
        info = f'命中本路{caps[0]}名敌人，造成{(damage if replace else .4)*100:g}%攻击魔法伤害并降低20%攻击2回合。'
    elif style == 'duel':
        actions = [['sunder_percent', damage if replace else .4, 1, .2, 2, 'FX60_SUNDER'], ['caster_hp_shield', .15, 1, 'FX60_SHIELD']]
        policies = ['enemy_lane_frontmost', 'ally_self']; caps = [1, 1]
        info = f'打击前排造成{(damage if replace else .4)*100:g}%攻击伤害并削弱20%双防2回合，自身获得15%最大生命护盾1回合。'
    else:
        actions = [['damage', damage if replace else .5, 2 if style == 'storm' else 1, fx]]
        policies = ['enemy_lane_frontmost']; caps = [4 if captain else 3]
        info = f'对本路最多{caps[0]}名敌人造成{(damage if replace else .5)*100:g}%攻击伤害，压制密集阵容。'
    return {'replace': replace, 'name': name + ('·终式' if captain else '·战技'), 'actions': actions,
            'policies': policies, 'caps': caps, 'pl': [2 if captain else 0, 3 if captain else 2, 9999, 0, 99, 1],
            'upgrades': None if captain or not replace else [[next((i for i,a in enumerate(actions) if a[0] in ('damage','sunder_percent','weak_percent','cure')),0),1,.1]],
            'info': info + (' 保持原技能强化等级。' if replace else '')}


def build():
    bonds = []
    for index, (name, relation, members, style) in enumerate(GROUPS):
        families = ['A_' + str(n) for n in members]
        n = len(members)
        benefits = {}
        for i, family in enumerate(families):
            if i == 0 and n >= 3:
                benefits[family] = {}
            elif i % 3 == 2:
                benefits[family] = {'skill_rate': {2:.25,3:.32,4:.44,5:.56}[n]}
            elif i % 3 == 1 and style in ('assassin', 'barrage', 'duel'):
                benefits[family] = {'secondary': ['crit', 'hit'] if style != 'assassin' else ['flee', 'hit']}
            else:
                keys = ['hp','de_ph','de_ma'] if style in ('guard','banner') else ['ap','hp'] if style in ('light','tide') else ['ap']
                budget = {2:.28,3:.40,4:.52,5:.64}[n]
                benefits[family] = {'stats': {key: budget / len(keys) for key in keys}}
        if name == '武道争锋':
            # Yi has no orange card: use the quality-independent panel budget.
            benefits['A_1012'] = {'stats': {'ap': .32, 'hp': .32}}
        bond = {'id': f'b{index+1:03}', 'name': name, 'relation': relation, 'families': families, 'benefits': benefits}
        if n >= 3:
            bond['focus'] = families[0]
            bond['mechanism'] = {'normal': mechanism(name, style, n >= 4)}
            if n >= 4:
                bond['mechanism']['captain'] = mechanism(name, style, True, True)
                customize_rework(bond, members[0])
        bonds.append(bond)
    # A full formation must not also activate a smaller bond for free.
    # Reject duplicates as well as strict subsets before publishing the plan.
    for i, bond in enumerate(bonds):
        members = set(bond['families'])
        if len(members) != len(bond['families']):
            raise ValueError(f"Duplicate member in {bond['name']}")
        for other in bonds[i+1:]:
            other_members = set(other['families'])
            if members <= other_members or other_members <= members:
                raise ValueError(f"Nested bonds: {bond['name']} / {other['name']}")
    target = ROOT / 'config/reconstruction/bonds-1.0.4.json'
    target.write_text(json.dumps({'schema':'1.0.4', 'bonds':bonds}, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')


def customize_rework(bond, hero):
    def put(slot, name, actions, policies, caps, info, pl, upgrades=None):
        bond['mechanism'][slot] = {'replace':True,'name':name,'actions':actions,'policies':policies,
                                  'caps':caps,'info':info,'pl':pl,'upgrades':upgrades}
    slash='FX60_SLASH_COMBO'; shield='FX60_SHIELD'; heal='FX60_HEAL'
    if hero==1007:
        put('normal','王庭战旗', [['sunder_percent',2.8,1,.25,2,'FX60_SUNDER'],['strong',.25,2,'FX60_STRONG'],['taunt',1,shield]],
            ['enemy_lane_frontmost','ally_lane_all','ally_self'],[2,3,1],
            '击穿本路两名前排：280%攻击物伤并削弱25%双防2回合；本路3名友军力量+25%持续2回合，自身嘲讽1回合。强化每级伤害+28%。',[0,2,3000,0,99,0],[[0,1,.28]])
        put('captain','光盾壁垒', [['damage',4.8,1,slash],['caster_hp_shield',.4,2,shield],['purify',1,'FX60_PURIFY']],
            ['enemy_lane_frontmost','ally_all_lowest_hp_ratio','ally_all_lowest_hp_ratio'],[3,3,3],
            '对本路3名敌人造成480%攻击物伤；为全场生命比例最低的3名友军净化并赋予施法者40%最大生命护盾2回合。',[2,3,9999,0,99,1])
    elif hero==1023:
        put('normal','割喉追猎', [['dispel_good',1,'FX60_PURIFY'],['damage',3.6,1,slash],['stat_flat','flee',1500,1,'FX60_HIT']],
            ['enemy_global_lowest_hp_ratio_hero','enemy_global_lowest_hp_ratio_hero','ally_self'],[1,1,1],
            '跨路锁定最低生命比例英雄，驱散其增益后造成360%攻击物伤；自身闪避+1500持续1回合。强化每级伤害+36%。',[0,2,9999,0,0,1],[[1,1,.36]])
        put('captain','群鸦刃幕', [['sunder_percent',0,1,.35,2,'FX60_SUNDER'],['locked_combo_group',3,4,1.5,1,0,slash]],
            ['enemy_global_highest_attack_hero','enemy_global_highest_attack_hero'],[3,3],
            '跨路压制攻击最高的3名英雄，先降低35%双防2回合，再逐人四连击，每击150%攻击物伤。专克多核心后排。',[2,3,9999,0,99,1])
    elif hero==1139:
        put('normal','灵链救赎', [['cure',1.8,heal],['purify',1,'FX60_PURIFY'],['caster_hp_shield',.15,2,shield]],
            ['ally_all_lowest_hp_ratio']*3,[2]*3,
            '跨路救援生命比例最低的2名友军，治疗180%恢复基数、净化并提供施法者15%最大生命护盾2回合。强化每级治疗+18%。',[0,2,9999,0,99,1],[[0,1,.18]])
        put('captain','艾欧尼亚之魂', [['cure',3.2,heal],['purify',1,'FX60_PURIFY'],['caster_hp_shield',.3,2,shield],['strong',.25,2,'FX60_STRONG']],
            ['ally_all']*4,[-1]*4,
            '治疗全队320%恢复基数并净化；全队获得施法者30%最大生命护盾与25%力量，持续2回合。适合多路承压后的反攻。',[2,3,9999,0,99,1])
    elif hero==1030:
        put('normal','赏金穿甲弹', [['sunder_percent',2.5,1,.3,2,'FX60_SUNDER'],['damage',2.5,1,slash]],
            ['enemy_lane_frontmost','enemy_lane_behind_primary_nearest'],[1,2],
            '前排承受250%攻击物伤与30%双防削弱2回合，随后穿透其身后2个目标，各造成250%攻击物伤。强化每级两段系数各+25%。',[0,2,3000,0,99,0],[[0,1,.25],[1,1,.25]])
        bond['mechanism']['normal']['policy_args'] = [None, {'centerActionIndex':0,'distinctFromActionIndices':[0]}]
        put('captain','港湾封锁', [['sunder_percent',0,1,.35,2,'FX60_SUNDER'],['locked_combo_group',5,6,.75,1,0,slash],['weak_percent',0,1,.2,1,'FX60_WEAK']],
            ['enemy_lane_frontmost']*3,[5]*3,
            '压制本路最多5名敌人：双防降低35%持续2回合，六轮弹幕每轮75%攻击物伤，并降低20%力量1回合。',[2,3,3000,0,99,0])
    elif hero==1020:
        put('normal','曙光拦截', [['stun',3.0,2,1,'FX60_STUN'],['caster_hp_shield',.2,2,shield]],
            ['enemy_lane_highest_attack_hero','ally_self'],[1,1],
            '打击本路攻击最高英雄，造成300%攻击魔伤并眩晕1回合；自身获得20%最大生命护盾2回合。强化每级伤害+30%。',[0,2,3000,0,0,0],[[0,1,.3]])
        put('captain','日冕庇护', [['stun',4.0,2,1,'FX60_STUN'],['caster_hp_shield',.35,2,shield],['steel',.5,2,'FX60_STEEL']],
            ['enemy_global_highest_attack_hero','ally_all','ally_all'],[2,-1,-1],
            '跨路眩晕攻击最高的2名敌方英雄1回合并造成400%攻击魔伤；全队获得施法者35%最大生命护盾及50%双防2回合。',[2,3,9999,0,99,1])
    elif hero==1041:
        put('normal','超载加速炮', [['sunder_percent',3.2,2,.2,2,'FX60_SUNDER'],['push_aoe',3000,500,'push']],
            ['enemy_lane_frontmost','enemy_lane_all'],[3,3],
            '炮击本路3名敌人造成320%攻击魔伤，降低20%双防2回合并击退500码。强化每级伤害+32%。',[0,2,3000,0,99,0],[[0,1,.32]])
        put('captain','苍穹电场', [['damage',6.0,2,slash],['weak_percent',0,2,.3,2,'FX60_WEAK'],['stat_flat','hit',2500,2,'FX60_HIT']],
            ['enemy_global_highest_attack_hero','enemy_global_highest_attack_hero','ally_all'],[3,3,-1],
            '跨路电击攻击最高的3名英雄造成600%攻击魔伤并降低30%力量2回合；全队精准+2500持续2回合。',[2,3,9999,0,99,1])
    elif hero==1082:
        put('normal','游击毒云', [['poison',1.6,2,.55,3,'FX60_SUNDER'],['stat_flat','flee',2000,2,'FX60_HIT']],
            ['enemy_lane_frontmost','ally_self'],[3,1],
            '向本路3名敌人施放160%攻击魔伤和每回合55%攻击中毒，持续3回合；自身闪避+2000持续2回合。强化每级直伤+16%、毒伤+5.5%。',[0,2,3000,0,99,0],[[0,1,.16],[0,3,.055]])
        put('captain','班德尔伏击阵', [['poison',2.5,2,1.0,3,'FX60_SUNDER'],['weak_percent',0,2,.3,2,'FX60_WEAK']],
            ['enemy_global_highest_hpmax_hero']*2,[5,5],
            '跨路伏击最多5名高生命英雄：250%攻击魔伤、每回合100%攻击中毒3回合，并降低30%力量2回合。以持续伤害压制厚血阵容。',[2,3,9999,0,99,1])
    elif hero==1137:
        put('normal','冥界收割', [['sunder_percent',3.5,2,.25,2,'FX60_SUNDER'],['heal_damage_sum',.25,[0],heal]],
            ['enemy_lane_frontmost','ally_self'],[2,1],
            '对本路2名敌人造成350%攻击魔伤并削弱25%双防2回合，自身恢复本次累计伤害的25%。强化每级伤害+35%。',[0,2,3000,0,99,0],[[0,1,.35]])
        put('captain','不朽冥军', [['dispel_good',1,'FX60_PURIFY'],['damage',7.0,2,slash],['caster_hp_shield',.4,2,shield],['heal_damage_sum',.3,[1],heal]],
            ['enemy_global_highest_hpmax_hero','enemy_global_highest_hpmax_hero','ally_all','ally_self'],[2,2,3,1],
            '剥离跨路两名高生命英雄的增益并造成700%攻击魔伤；3名友军获得施法者40%最大生命护盾2回合，自身恢复累计伤害的30%。',[2,3,9999,0,99,1])
    elif hero==1124:
        put('normal','沙兵突击', [['locked_combo_group',3,3,1.0,2,0,slash],['sunder_percent',0,2,.2,2,'FX60_SUNDER']],
            ['enemy_lane_frontmost']*2,[3,3],
            '沙兵向本路3名敌人各刺击3次，每击100%攻击魔伤，并削弱20%双防2回合。强化每级每击+10%。',[0,2,3000,0,99,0],[[0,3,.1]])
        put('captain','帝国禁军壁垒', [['damage',6.0,2,slash],['push_aoe',3000,1200,'push'],['caster_hp_shield',.3,2,shield]],
            ['enemy_lane_frontmost','enemy_lane_all','ally_all'],[5,5,-1],
            '禁军冲击本路最多5人，造成600%攻击魔伤并击退1200码；全队获得施法者30%最大生命护盾2回合，形成反突进屏障。',[2,3,9999,0,99,1])
    elif hero==1219:
        put('normal','源代码切割', [['dispel_good',1,'FX60_PURIFY'],['sunder_percent',3.6,1,.25,2,'FX60_SUNDER']],
            ['enemy_lane_highest_attack_hero']*2,[2,2],
            '优先切割本路攻击最高的2名英雄，驱散增益后造成360%攻击物伤，并削弱25%双防2回合。强化每级伤害+36%。',[0,2,3000,0,99,0],[[1,1,.36]])
        put('captain','协议零式', [['stun',5.5,1,1,'FX60_STUN'],['damage',2.5,1,slash],['stat_flat','flee',3000,2,'FX60_HIT']],
            ['enemy_global_highest_attack_hero','enemy_global_highest_attack_hero','ally_self'],[3,3,1],
            '跨路锁定3名高攻击英雄，先造成550%攻击物伤并眩晕1回合，再追加250%攻击物伤；自身闪避+3000持续2回合。',[2,3,9999,0,99,1])
    elif hero==1081:
        put('normal','霜翼封路', [['weak_percent',2.8,2,.25,2,'FX60_WEAK'],['push_aoe',3000,450,'push']],
            ['enemy_lane_frontmost','enemy_lane_all'],[3,3],
            '对本路3名敌人造成280%攻击魔伤，削弱25%攻击2回合并击退450码，延缓前排推进。强化每级伤害+28%。',[0,2,3000,0,99,0],[[0,1,.28]])
        put('captain','极寒禁域', [['stun',4.2,2,1,'FX60_STUN'],['weak_percent',0,2,.35,2,'FX60_WEAK']],
            ['enemy_global_highest_attack_hero']*2,[3,3],
            '跨路冻结攻击最高的3名英雄1回合，造成420%攻击魔伤并削弱35%攻击2回合，压制多核心爆发。',[2,3,9999,0,99,1])
    elif hero==1018:
        put('normal','影护结界', [['damage',2.8,1,slash],['caster_hp_shield',.22,2,shield],['taunt',1,shield]],
            ['enemy_lane_frontmost','ally_all_lowest_hp_ratio','ally_self'],[1,2,1],
            '打击本路前排造成280%攻击物伤，跨路为生命比例最低的2名友军提供施法者22%最大生命护盾2回合，自身嘲讽1回合。强化每级伤害+28%。',[0,2,9999,0,99,1],[[0,1,.28]])
        put('captain','万里慈悲', [['purify',1,'FX60_PURIFY'],['caster_hp_shield',.5,2,shield],['steel',.4,2,'FX60_STEEL']],
            ['ally_all_lowest_hp_ratio']*3,[3]*3,
            '跨路救援生命比例最低的3名友军：净化、施法者50%最大生命护盾和40%双防，持续2回合，保护分路残血核心。',[2,3,9999,0,99,1])
    elif hero==1004:
        put('normal','星落续命', [['weak_percent',2.2,2,.2,1,'FX60_WEAK'],['cure',2.0,heal]],
            ['enemy_lane_highest_attack_hero','ally_all_lowest_hp_ratio'],[1,2],
            '削弱本路最高攻击英雄20%攻击1回合并造成220%攻击魔伤；治疗全场生命比例最低的2名友军200%恢复基数。强化每级伤害+22%、治疗+20%。',[0,2,9999,0,99,1],[[0,1,.22],[1,1,.2]])
        put('captain','群星回春', [['purify',1,'FX60_PURIFY'],['cure',4.0,heal],['caster_hp_shield',.2,2,shield]],
            ['ally_all']*3,[-1]*3,
            '先净化全队，再治疗400%恢复基数并赋予施法者20%最大生命护盾2回合，用于多路消耗战后的恢复。',[2,3,9999,0,99,1])
    elif hero==1032:
        put('normal','引魂灯笼', [['sunder_percent',2.6,2,.25,2,'FX60_SUNDER'],['caster_hp_shield',.25,2,shield]],
            ['enemy_lane_frontmost','ally_all_lowest_hp_ratio'],[2,2],
            '剥离本路2名前排25%双防2回合并造成260%攻击魔伤；为全场生命比例最低的2名友军提供施法者25%最大生命护盾2回合。强化每级伤害+26%。',[0,2,9999,0,99,1],[[0,1,.26]])
        put('captain','幽牢审判', [['dispel_good',1,'FX60_PURIFY'],['stun',4.8,2,1,'FX60_STUN'],['heal_damage_sum',.3,[1],heal]],
            ['enemy_lane_frontmost','enemy_lane_frontmost','ally_self'],[4,4,1],
            '驱散本路4名敌人的增益，再造成480%攻击魔伤并眩晕1回合，自身恢复累计伤害的30%，专克同路密集增益阵容。',[2,3,3000,0,99,0])
    elif hero==1053:
        put('normal','破阵霰弹', [['sunder_percent',3.2,1,.3,2,'FX60_SUNDER'],['push_aoe',3000,350,'push']],
            ['enemy_lane_frontmost','enemy_lane_all'],[2,2],
            '轰击本路2名前排造成320%攻击物伤并削弱30%双防2回合，击退350码，为猎团打开火力窗口。强化每级伤害+32%。',[0,2,3000,0,99,0],[[0,1,.32]])
        put('captain','悬赏清场', [['dispel_good',1,'FX60_PURIFY'],['locked_combo_group',2,3,2.2,1,0,slash]],
            ['enemy_global_lowest_hp_ratio_hero']*2,[2,2],
            '跨路锁定生命比例最低的2名英雄，先驱散增益，再各轰击3次，每击220%攻击物伤，收割分散的残血目标。',[2,3,9999,0,99,1])
    elif hero==1217:
        put('normal','坏孩子礼盒', [['dispel_good',1,'FX60_PURIFY'],['weak_percent',3.0,2,.25,2,'FX60_WEAK']],
            ['enemy_global_highest_attack_hero']*2,[1,1],
            '把诅咒礼盒送给跨路最高攻击英雄，驱散增益、造成300%攻击魔伤并削弱25%攻击2回合。强化每级伤害+30%。',[0,2,9999,0,99,1],[[1,1,.3]])
        put('captain','午夜惊喜', [['stun',4.4,2,1,'FX60_STUN'],['sunder_percent',0,2,.3,2,'FX60_SUNDER']],
            ['enemy_global_highest_attack_hero']*2,[3,3],
            '礼盒在跨路3名高攻击英雄身上炸开：440%攻击魔伤、眩晕1回合、双防降低30%持续2回合，配合夜巡队压制后排。',[2,3,9999,0,99,1])
    elif hero==1003:
        put('normal','符文裂解', [['sunder_percent',3.0,2,.3,2,'FX60_SUNDER'],['damage',2.0,2,slash]],
            ['enemy_lane_frontmost','enemy_lane_behind_primary_nearest'],[1,2],
            '裂解本路前排：300%攻击魔伤并降低30%双防2回合；符文向其身后2名不同目标扩散，各造成200%攻击魔伤。强化每级两段伤害分别+30%、20%。',[0,2,3000,0,99,0],[[0,1,.3],[1,1,.2]])
        bond['mechanism']['normal']['policy_args']=[None,{'centerActionIndex':0,'distinctFromActionIndices':[0]}]
        put('captain','奥术崩解', [['dispel_good',1,'FX60_PURIFY'],['sunder_percent',5.5,2,.35,2,'FX60_SUNDER'],['heal_damage_sum',.2,[1],heal]],
            ['enemy_global_highest_hpmax_hero','enemy_global_highest_hpmax_hero','ally_self'],[4,4,1],
            '跨路瓦解4名高生命英雄的增益，造成550%攻击魔伤并降低35%双防2回合，自身恢复累计伤害20%，为法师队打开厚甲阵线。',[2,3,9999,0,99,1])
    elif hero==1071:
        put('normal','魔偶交叉火力', [['weak_percent',2.8,2,.2,2,'FX60_WEAK'],['caster_hp_shield',.18,2,shield]],
            ['enemy_lane_frontmost','ally_all_lowest_hp_ratio'],[3,2],
            '魔偶扫射本路3人造成280%攻击魔伤并削弱20%攻击2回合；为跨路生命比例最低的2名友军提供施法者18%最大生命护盾2回合。强化每级伤害+28%。',[0,2,9999,0,99,1],[[0,1,.28]])
        put('captain','过载奇点', [['stun',4.5,2,1,'FX60_STUN'],['sunder_percent',0,2,.3,2,'FX60_SUNDER'],['stat_flat','hit',4000,2,'FX60_HIT']],
            ['enemy_lane_frontmost','enemy_lane_frontmost','ally_all'],[5,5,-1],
            '奇点压制本路5人：450%攻击魔伤、眩晕1回合、双防降低30%持续2回合；全队精准+4000持续2回合，支援后续集火。',[2,3,9999,0,99,1])
    elif hero==1008:
        put('normal','宗师破势', [['sunder_percent',3.4,1,.3,2,'FX60_SUNDER'],['stat_flat','flee',2500,2,'FX60_HIT']],
            ['enemy_lane_highest_attack_hero','ally_self'],[1,1],
            '迎战本路攻击最高英雄：340%攻击物伤并降低30%双防2回合；自身闪避+2500持续2回合，适合对抗单路强敌。强化每级伤害+34%。',[0,2,3000,0,0,0],[[0,1,.34]])
        put('captain','百武归一', [['dispel_good',1,'FX60_PURIFY'],['locked_combo_group',1,5,1.6,1,0,slash],['caster_hp_shield',.35,2,shield],['heal_damage_sum',.25,[1],heal]],
            ['enemy_global_highest_attack_hero','enemy_global_highest_attack_hero','ally_self','ally_self'],[1,1,1,1],
            '跨路挑战最高攻击英雄，驱散增益后五连击，每击160%攻击物伤；自身获得35%最大生命护盾2回合并恢复累计伤害25%，集中压制敌方主核。',[2,3,9999,0,0,1])
    else:
        raise ValueError(f'Missing authored full rework: {hero}')


if __name__ == '__main__':
    build()
