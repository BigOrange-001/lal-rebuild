"""Campaign chapters 31-60: five encounters each, in normal and elite.

The chapter table below is authored data: chapter names, stage titles, map
lanes, each stage's captain and the few heroes its card text names. Every
other hero slot is filled from the whole enemy pool, least-used first, so
ordinary heroes keep appearing to the last chapter and every hero gets a
similar number of fights. apply_campaign_expansion turns the table into stage
rows with the same native shape as chapters 1-30, fits every enemy snapshot to
its recommended power, and extends the chapter star gifts and the elite
equipment tiers. Chapters 1-30 are never modified.

Difficulty follows one geometric curve per mode from the live chapter-30
finale to chapter 60's finale: 20 billion displayed power in normal and 300
billion in elite. Inside a chapter the five encounters sit at fixed shares of
that chapter's finale, so every encounter is harder than the one before it.

These chapters cannot be swept. Normal wins may add a purple or an orange card
of a regular hero on the field; elite wins may add one abyss relic with at most
one ancient affix.
"""
from __future__ import annotations

import copy
import hashlib
import math
from collections import Counter

from battle_engine import level_stats, serialize_stage_team
from campaign_workbook_overlay import _fit_power, _power
from power_balance_104 import POWER_ANCHOR, POWER_SCHEMA, normalize_team_power
from pve_formation import stagger_lane_offsets

SCHEMA = 'campaign-expansion-106-v2'
FIRST_CHAPTER, LAST_CHAPTER, STAGES = 31, 60, 5
# Displayed (team-anchor) recommendation of chapter 60's finale.
FINALE_POWER = {'0': 20_000_000_000, '1': 300_000_000_000}
STAGE_SHARE = (.80, .84, .88, .93, 1.0)
# Finale bosses stand one level above their escort: the client draws an enemy
# above the field's lowest level 1.3x larger. Levels do not enter the fit.
LEVEL, ESCORT_LEVEL = 99, 98
# Normal and elite enemy skill levels for each act of five chapters.
SKILL_LEVEL = {'0': (5, 5, 6, 6, 7, 7), '1': (9, 9, 10, 10, 10, 10)}
# Relative weighted panel of one unit before the stage is fitted.
LEADER_WEIGHT, HERO_WEIGHT, MINION_WEIGHT = 1.2, 1.0, .72
HERO_DROP_RATE = .15
# Battle results reject any combatant above 1e9 health; keep a margin.
HP_LIMIT = 900_000_000
WIN_RULES = {'两路': [-1], '全歼': [-2], '中路': [1], '两翼': [0, 2]}
OBSERVATIONS = {
    '两路': '任意两路制：先拿下任意两路即可获胜，两路失守即告失败。',
    '全歼': '全灭关必须清理每条分路，后置单位延长收尾。',
    '中路': '中路制：只看中路，击溃中路即胜，中路失守即败，两翼只需拖住。',
    '两翼': '两翼制：拿下左、右两路即可获胜，中路的强敌可以不打。',
}
# Native lane names by lane count (GameMapTools.getWinStr).
LANE_NAMES = {1: ('',), 2: ('左路', '右路'), 3: ('左路', '中路', '右路')}

MINIONS = {'近战兵': 'A_3003_3', '远程兵': 'A_3004_3', '炮车': 'A_3006_4', '超级兵': 'A_3008_5'}
FILLER = '英雄'
# Heroes named in the table. Every other hero slot ('英雄') comes from POOL.
HEROES = {
    '拉莫斯': 'A_1090_6', '墨菲特': 'A_1077_6', '卡西奥佩娅': 'A_1063_6', '波比': 'A_1108_6',
    '阿木木': 'A_1074_6', '塔里克': 'A_1093_6', '亚托克斯': 'A_1113_6', '卡萨丁': 'A_1134_6',
    '千珏': 'A_1142_6', '雷克顿': 'A_1101_6', '格雷福斯': 'A_1053_6', '厄运小姐': 'A_1030_6',
    '普朗克船长': 'A_1011_6', '希维尔': 'A_1078_6', '金克斯': 'A_1115_6', '崔斯特': 'A_1096_6',
    '卢锡安': 'A_1136_6', '布里茨': 'A_1013_6', '沙漠治安官凯瑟琳': 'A_1211_6', '阿兹尔': 'A_1124_6',
    '扎克': 'A_1112_6', '乐芙兰': 'A_1127_6', '莫甘娜': 'A_1133_6', '婕拉': 'A_1040_6',
    '维嘉': 'A_1027_6', '马尔扎哈': 'A_1103_6', '奈德丽': 'A_1105_6', '雷恩加尔': 'A_1135_6',
    '古拉加斯': 'A_1106_6', '卡兹克': 'A_1097_6', '辛德拉': 'A_1126_6', '艾克': 'A_1140_6',
    '吉格斯': 'A_1125_6', '俄洛伊': 'A_1143_6', '伊芙琳': 'A_1033_6', '莫德凯撒': 'A_1137_6',
    '幽魂费德提克': 'A_1218_6', '锤石': 'A_1032_6', '弗拉基米尔': 'A_1109_6',
    '恶魔男爵瑞兹': 'A_1203_6', '邪恶圣诞老人维嘉': 'A_1217_6', '卡尔萨斯': 'A_1098_6',
    '纳尔': 'A_1123_6', '艾尼维亚': 'A_1081_6', '艾希': 'A_1002_6', '瑟庄妮': 'A_1049_6',
    '泰达米尔': 'A_1028_6', '极地射手艾希': 'A_1202_6', '丽桑卓': 'A_1117_6', '布兰德': 'A_1068_6',
    '努努': 'A_1073_6', '雷兹': 'A_1003_6', '贾克斯': 'A_1008_6', '拉克丝': 'A_1060_6',
    '潘森': 'A_1017_6', '嘉文四世': 'A_1007_6', '蕾欧娜': 'A_1020_6', '索拉卡': 'A_1004_6',
    '希瓦娜': 'A_1054_6', '黛安娜': 'A_1086_6', '伊泽瑞尔': 'A_1021_6', '赵信': 'A_1009_6',
    '凯尔': 'A_1120_6', '易大师': 'A_1012_6', '阿狸': 'A_1022_6', '粽子少女': 'A_1212_6',
    '慎': 'A_1018_6', '白娘子': 'A_1227_6', '亚索': 'A_1119_6', '凯南': 'A_1016_6',
    '李青': 'A_1026_6', '二郎真君赵信': 'A_1226_6', '新年安妮': 'A_1221_6', '卡尔玛': 'A_1139_6',
    '艾瑞莉娅': 'A_1024_6', '悟空': 'A_1005_6', '阿卡丽': 'A_1015_6', '劫': 'A_1132_6',
    '龙的传人李青': 'A_1215_6', '娜美': 'A_1131_6', '塔姆肯奇': 'A_1138_6', '菲兹': 'A_1052_6',
    '敖兴': 'A_1114_6', '恶魔之刃泰达米尔': 'A_1803_6', '大肥鱼！': 'A_1804_6',
    '冠军-卡密尔': 'A_1805_6', '黑夜使者亚索': 'A_1802_6', '神龙尊者卡莎': 'A_1801_6',
    '偶像歌手阿狸': 'A_1207_6', '逆转裁判崔斯特': 'A_1214_6', '足球先生伊泽瑞尔': 'A_1213_6',
    '黄金骑士盖伦': 'A_1201_6', '苹果机器人布里茨': 'A_1204_6', 'DJ娑娜': 'A_1228_6',
    '源计划亚索': 'A_1219_6', '钢铁侠提莫': 'A_1310_6', '超人提莫': 'A_1309_6',
}
# Highest configured color of every enemy hero family, frozen so that a hero
# added later never reshuffles these lineups. Abandoned heroes and the named
# NPC family 19xx (except 加百列) are left out.
POOL = (
    'A_1001_6', 'A_1002_6', 'A_1003_6', 'A_1004_6', 'A_1005_6', 'A_1006_6', 'A_1007_6',
    'A_1008_6', 'A_1009_6', 'A_1010_6', 'A_1011_6', 'A_1012_6', 'A_1013_6', 'A_1014_6',
    'A_1015_6', 'A_1016_6', 'A_1017_6', 'A_1018_6', 'A_1019_6', 'A_1020_6', 'A_1021_6',
    'A_1022_6', 'A_1023_6', 'A_1024_6', 'A_1025_6', 'A_1026_6', 'A_1027_6', 'A_1028_6',
    'A_1029_6', 'A_1030_6', 'A_1032_6', 'A_1033_6', 'A_1036_6', 'A_1040_6', 'A_1041_6',
    'A_1045_6', 'A_1049_6', 'A_1052_6', 'A_1053_6', 'A_1054_6', 'A_1056_6', 'A_1060_6',
    'A_1063_6', 'A_1068_6', 'A_1071_6', 'A_1073_6', 'A_1074_6', 'A_1077_6', 'A_1078_6',
    'A_1079_6', 'A_1081_6', 'A_1082_6', 'A_1083_6', 'A_1085_6', 'A_1086_6', 'A_1090_6',
    'A_1093_6', 'A_1094_6', 'A_1095_6', 'A_1096_6', 'A_1097_6', 'A_1098_6', 'A_1099_6',
    'A_1101_6', 'A_1103_6', 'A_1105_6', 'A_1106_6', 'A_1108_6', 'A_1109_6', 'A_1112_6',
    'A_1113_6', 'A_1114_6', 'A_1115_6', 'A_1117_6', 'A_1119_6', 'A_1120_6', 'A_1123_6',
    'A_1124_6', 'A_1125_6', 'A_1126_6', 'A_1127_6', 'A_1128_6', 'A_1129_6', 'A_1130_6',
    'A_1131_6', 'A_1132_6', 'A_1133_6', 'A_1134_6', 'A_1135_6', 'A_1136_6', 'A_1137_6',
    'A_1138_6', 'A_1139_6', 'A_1140_6', 'A_1142_6', 'A_1143_6', 'A_1201_6', 'A_1202_6',
    'A_1203_6', 'A_1204_6', 'A_1205_6', 'A_1206_6', 'A_1207_6', 'A_1208_6', 'A_1209_6',
    'A_1210_6', 'A_1211_6', 'A_1212_6', 'A_1213_6', 'A_1214_6', 'A_1215_6', 'A_1216_6',
    'A_1217_6', 'A_1218_6', 'A_1219_6', 'A_1221_6', 'A_1222_6', 'A_1223_6', 'A_1226_6',
    'A_1227_6', 'A_1228_6', 'A_1309_6', 'A_1310_6', 'A_1311_6', 'A_1801_6', 'A_1802_6',
    'A_1803_6', 'A_1804_6', 'A_1805_6', 'A_1998_6',
)
# The newer legends are finale bosses: as filler they appear only after the
# chapter they lead.
LEGEND_CHAPTER = {'A_1803_6': 56, 'A_1804_6': 57, 'A_1805_6': 58, 'A_1802_6': 59, 'A_1801_6': 60}
# Depth inside a lane, front first.
TANK_FAMILIES = {f'A_{i}' for i in (1001, 1007, 1013, 1020, 1018, 1077, 1049, 1085, 1073, 1090,
                                    1137, 1138, 1201, 1204)}
SUPPORT_FAMILIES = {f'A_{i}' for i in (1004, 1006, 1045, 1094, 1093, 1139, 1208, 1228)}
MINION_DEPTH = {'A_3008_5': 2, 'A_3003_3': 3, 'A_3006_4': 5, 'A_3004_3': 7}

# First-clear rewards. Each finale gives one red skill book in turn; the last
# finale of every act also gives a themed ordinary orange item.
RED_BOOKS = ('E_6001_7', 'E_6002_7', 'E_6003_7', 'E_6004_7', 'E_6005_7', 'E_6006_7',
             'E_6007_7', 'E_6008_7', 'E_6501_7', 'E_6502_7', 'E_6503_7', 'E_6504_7')
ACT_ORANGE = {35: 'E_4015_6', 40: 'E_3004_6', 45: 'E_1505_6',
              50: 'E_1504_6', 55: 'E_4002_6', 60: 'E_3003_6'}
ACT_DUST = ([6, 2, 0, 0], [6, 3, 1, 0], [8, 4, 2, 0], [8, 4, 2, 1], [10, 5, 3, 1], [10, 6, 4, 2])
ACT_BOOKS = (1, 1, 2, 2, 2, 3)
ACT_SP = (1, 1, 1, 2, 2, 2)
ELITE_TIERS = ({'chapter_min': 31, 'chapter_max': 45, 'rarity': 'orange', 'quality': 6, 'ratio': [2400, 3]},
               {'chapter_min': 46, 'chapter_max': 60, 'rarity': 'orange', 'quality': 6, 'ratio': [3000, 3]})
# Normal wins: besides the purple card of hero_drop_candidates_by_diff (1%),
# one orange card of a regular hero on the field at 1%.
CARD_CHANCE_BP = 100
# Elite wins: one abyss relic with at most one ancient affix (main included).
RELIC_CHANCE_BP = (300, 300, 300, 300, 600)
RELIC_MAX_ANCIENT = 1

# (chapter name, finale boss, elite guests, stages). The elite roster swaps
# its last minion for the first guest who is not already on the field: as a
# rule the next chapter's boss shows up one chapter early.
# Stage: (title, win rule, backgrounds, lanes listed left to right and split
# by '|', with * on the captain and 英雄 for a pool hero, card text). Units
# stand by role inside a lane: tanks, fighters, minions, ranged, supports.
CHAPTERS = (
    ('沙海遗迹', '阿木木', ('雷克顿', '希维尔'), (
        ('流沙驿道', '两路', 'm012', '近战兵 英雄 远程兵 | 拉莫斯* 英雄 炮车 | 超级兵 英雄 英雄',
         '拉莫斯在中路打头阵，滚过流沙替身后的队伍开路。'),
        ('风化的石像', '全歼', 'm003 m012', '墨菲特* 英雄 超级兵 远程兵 | 英雄 英雄 英雄 炮车',
         '墨菲特像一尊风化的石像堵在左路。'),
        ('蛇女的墓穴', '全歼', 'm003', '英雄 近战兵 远程兵 | 卡西奥佩娅* 超级兵 英雄 | 英雄 英雄 炮车',
         '卡西奥佩娅盘踞在中路墓穴深处。'),
        ('墓门守卫', '两翼', 'm012 m003 m012', '英雄 近战兵 远程兵 | 波比* 超级兵 炮车 | 英雄 英雄 英雄',
         '波比举着盾牌死守中路墓门；只要拿下左、右两路，就能绕开她。'),
        ('千年的眼泪', '全歼', 'm003 m012 m003', '英雄 英雄 远程兵 | 拉莫斯 阿木木* 英雄 | 卡西奥佩娅 超级兵 炮车',
         '阿木木走出中路墓室，拉莫斯在前开路；卡西奥佩娅守在右路。'),
    )),
    ('飞升神殿', '雷克顿', ('希维尔', '沙漠治安官凯瑟琳'), (
        ('神殿台阶', '两路', 'm003', '超级兵 英雄 远程兵 | 塔里克* 英雄 炮车 | 近战兵 英雄 英雄',
         '塔里克守在中路台阶上，用宝石的光辉护住身边的同伴。'),
        ('暗裔的低语', '全歼', 'm006 m003', '亚托克斯* 英雄 超级兵 远程兵 | 英雄 英雄 英雄 炮车',
         '亚托克斯提剑站在左路，暗裔之刃的低语从剑身里传出。'),
        ('金色沙暴', '全歼', 'm012', '英雄 远程兵 炮车 | 卡萨丁* 超级兵 英雄 | 英雄 英雄 近战兵',
         '沙暴遮住了视野，卡萨丁从中路突进。'),
        ('神殿的守灵人', '中路', 'm003 m006 m003', '英雄 近战兵 远程兵 | 千珏* 超级兵 炮车 | 英雄 英雄 英雄',
         '千珏守在中路神殿正门；击溃中路即可入殿，中路失守即告失败。'),
        ('屠夫的狂怒', '全歼', 'm012 m003 m012', '塔里克 英雄 远程兵 | 雷克顿* 亚托克斯 英雄 | 英雄 超级兵 炮车',
         '雷克顿在中路狂怒挥刃，亚托克斯与他并肩；左路由塔里克压阵。'),
    )),
    ('太阳圆盘', '希维尔', ('沙漠治安官凯瑟琳', '阿兹尔'), (
        ('佣兵营地', '两路', 'm012', '英雄 近战兵 远程兵 | 格雷福斯* 超级兵 炮车 | 英雄 英雄 英雄',
         '格雷福斯扛着散弹枪在中路带队。'),
        ('悬赏告示', '全歼', 'm012 m003', '英雄 英雄 超级兵 远程兵 | 厄运小姐* 英雄 英雄 炮车',
         '厄运小姐在右路贴出悬赏，赏金猎人们闻讯而来。'),
        ('船长的藏宝图', '全歼', 'm005', '普朗克船长* 英雄 英雄 英雄 英雄 超级兵 远程兵',
         '普朗克船长握着藏宝图，把守这条唯一的通路。'),
        ('圆盘守卫', '中路', 'm006 m012 m006', '英雄 近战兵 远程兵 | 雷克顿* 超级兵 炮车 | 英雄 英雄 英雄',
         '雷克顿守在中路太阳圆盘前；击溃中路即可夺下圆盘，中路失守即告失败。'),
        ('刀锋上的契约', '全歼', 'm012 m006 m012', '厄运小姐 英雄 远程兵 | 格雷福斯 希维尔* 英雄 | 英雄 超级兵 炮车',
         '希维尔收下了所有佣兵的定金，握着十字刃坐镇中路；格雷福斯与她同守中路，厄运小姐守在左路。'),
    )),
    ('荒漠小镇', '沙漠治安官凯瑟琳', ('阿兹尔', '希维尔'), (
        ('通缉令上的脸', '两路', 'm012', '英雄 超级兵 远程兵 | 近战兵 金克斯* 炮车 | 英雄 英雄 英雄',
         '金克斯的通缉令贴满了小镇，她本人就在中路开火。'),
        ('酒馆里的赌局', '全歼', 'm012 m003', '崔斯特* 英雄 超级兵 远程兵 | 英雄 英雄 英雄 炮车',
         '崔斯特在左路的酒馆里摊开牌局。'),
        ('正午的决斗', '全歼', 'm012', '英雄 近战兵 远程兵 | 卢锡安* 超级兵 炮车 | 英雄 英雄 英雄',
         '正午钟响，卢锡安提着双枪站在中路。'),
        ('押送的囚车', '两翼', 'm012 m003 m012', '英雄 近战兵 远程兵 | 布里茨* 炮车 超级兵 | 英雄 英雄 英雄',
         '布里茨押着囚车挡在中路；拿下左、右两路，就能截住这辆囚车。'),
        ('黄昏的警徽', '全歼', 'm012 m006 m012', '金克斯 英雄 远程兵 | 卢锡安 沙漠治安官凯瑟琳* 英雄 | 英雄 超级兵 炮车',
         '沙漠治安官凯瑟琳在中路架枪，卢锡安与她同守中路；被押来的金克斯在左路助阵。'),
    )),
    ('黄沙王座', '阿兹尔', ('马尔扎哈', '卡兹克'), (
        ('沙兵方阵', '两路', 'm012', '英雄 近战兵 远程兵 | 阿木木* 超级兵 炮车 | 英雄 英雄 英雄',
         '阿木木领着沙兵方阵压上中路。'),
        ('皇城的回声', '全歼', 'm003 m012', '英雄 英雄 超级兵 远程兵 | 希维尔* 英雄 英雄 炮车',
         '希维尔重返皇城，守在右路。'),
        ('飞升之光', '全歼', 'm006 m012 m006', '英雄 近战兵 远程兵 | 雷克顿* 超级兵 英雄 | 英雄 英雄 炮车',
         '雷克顿沐浴着飞升之光，守在中路。'),
        ('王座前的卫队', '中路', 'm003 m012 m003', '英雄 近战兵 远程兵 | 塔里克* 超级兵 炮车 | 英雄 英雄 英雄',
         '塔里克把守中路王座台阶；击溃中路即可直面皇帝，中路失守则前功尽弃。'),
        ('恕瑞玛重生', '全歼', 'm012 m003 m012', '英雄 英雄 远程兵 | 雷克顿 阿兹尔* 希维尔 | 英雄 超级兵 炮车',
         '阿兹尔端坐中路王座，雷克顿挡在他身前，希维尔也回到了他身边。'),
    )),
    ('艾卡西亚', '马尔扎哈', ('卡兹克', '卡萨丁'), (
        ('废城的入口', '两路', 'm013', '英雄 超级兵 远程兵 | 扎克* 近战兵 炮车 | 英雄 英雄 英雄',
         '扎克在中路摊成一团，堵住废城入口。'),
        ('虚空的呼唤', '全歼', 'm014 m013', '乐芙兰* 英雄 超级兵 远程兵 | 英雄 英雄 英雄 炮车',
         '乐芙兰在左路回应虚空的呼唤。'),
        ('先知的信徒', '全歼', 'm013 m006 m013', '英雄 近战兵 远程兵 | 超级兵 莫甘娜* 英雄 | 英雄 英雄 炮车',
         '莫甘娜替虚空先知召集信徒，坐镇中路。'),
        ('噬光裂缝', '两翼', 'm006', '英雄 英雄 远程兵 | 婕拉* 超级兵 炮车 | 英雄 英雄 近战兵',
         '婕拉的藤蔓长满了中路裂缝；拿下左、右两路即可绕开。'),
        ('群星熄灭之时', '全歼', 'm013 m006 m013', '英雄 英雄 远程兵 | 维嘉 马尔扎哈* 莫甘娜 | 英雄 超级兵 炮车',
         '马尔扎哈在中路念出预言，维嘉挡在他身前，莫甘娜守在他身后。'),
    )),
    ('进化巢穴', '卡兹克', ('卡萨丁', '马尔扎哈'), (
        ('林间的爪痕', '两路', 'm010', '英雄 超级兵 远程兵 | 奈德丽* 近战兵 炮车 | 英雄 英雄 英雄',
         '奈德丽循着爪痕走在中路。'),
        ('宿敌的气味', '全歼', 'm014 m010', '雷恩加尔* 英雄 近战兵 远程兵 | 英雄 英雄 英雄 炮车',
         '雷恩加尔闻到了宿敌的气味，在左路蠢蠢欲动。'),
        ('巢穴深处', '全歼', 'm013', '英雄 近战兵 远程兵 | 古拉加斯 千珏* 炮车 | 英雄 英雄 超级兵',
         '千珏在中路深处等待猎物，古拉加斯挡在她身前。'),
        ('酒桶堵住巢口', '中路', 'm013 m014 m013', '英雄 近战兵 远程兵 | 古拉加斯* 超级兵 炮车 | 英雄 英雄 英雄',
         '古拉加斯挺着酒桶堵住中路巢口；击溃中路即可攻入，中路失守即告失败。'),
        ('进化的终点', '全歼', 'm013 m014 m013', '英雄 奈德丽 远程兵 | 雷恩加尔 卡兹克* 英雄 | 英雄 超级兵 炮车',
         '卡兹克在中路完成了进化，宿敌雷恩加尔竟也挡在它身前；左路的奈德丽伺机扑出。'),
    )),
    ('虚空之门', '卡萨丁', ('锤石', '卡尔萨斯'), (
        ('漂浮的碎石', '两路', 'm006', '超级兵 英雄 远程兵 | 近战兵 辛德拉* 炮车 | 英雄 英雄 英雄',
         '辛德拉让碎石悬在中路上空。'),
        ('逆流的时间', '全歼', 'm013 m006', '英雄 英雄 超级兵 远程兵 | 艾克* 英雄 英雄 炮车',
         '艾克在右路拨动时间。'),
        ('星门前的独木桥', '全歼', 'm006', '吉格斯* 英雄 英雄 英雄 英雄 超级兵 远程兵',
         '星门前只剩一条窄路，吉格斯把炸弹堆满了这条路。'),
        ('星门回响', '两翼', 'm006 m013 m006', '英雄 近战兵 远程兵 | 马尔扎哈* 超级兵 炮车 | 英雄 英雄 英雄',
         '马尔扎哈在中路星门前吟唱；拿下左、右两路即可不与他正面交锋。'),
        ('门后的行者', '全歼', 'm013 m006 m013', '英雄 英雄 远程兵 | 卡兹克 卡萨丁* 马尔扎哈 | 英雄 超级兵 炮车',
         '卡萨丁从虚空之门里走出，卡兹克与马尔扎哈跟在他身后。'),
    )),
    ('黑雾海岸', '锤石', ('卡尔萨斯', '恶魔男爵瑞兹'), (
        ('迷雾中的灯火', '两路', 'm005 m011 m005', '英雄 近战兵 远程兵 | 俄洛伊* 超级兵 炮车 | 英雄 英雄 英雄',
         '俄洛伊守在中路岸边，驱散涌来的黑雾。'),
        ('沉船墓地', '全歼', 'm005 m011', '伊芙琳* 英雄 超级兵 远程兵 | 英雄 英雄 英雄 炮车',
         '伊芙琳隐没在左路的沉船之间。'),
        ('亡魂的潮汐', '全歼', 'm011', '英雄 近战兵 远程兵 | 莫德凯撒* 超级兵 炮车 | 英雄 英雄 英雄',
         '莫德凯撒率亡魂从中路涌上岸。'),
        ('幽魂的提灯', '中路', 'm011 m005 m011', '英雄 近战兵 远程兵 | 幽魂费德提克* 超级兵 炮车 | 英雄 英雄 英雄',
         '幽魂费德提克提着灯笼守在中路；击溃中路即可破雾，中路失守即告失败。'),
        ('灯笼里的囚徒', '全歼', 'm011 m005 m011', '英雄 英雄 远程兵 | 莫德凯撒 锤石* 英雄 | 千珏 超级兵 炮车',
         '锤石摇着灯笼站在莫德凯撒身后，灯笼里关着无数亡魂；千珏在右路默默注视。'),
    )),
    ('死亡颂歌', '卡尔萨斯', ('泰达米尔', '瑟庄妮'), (
        ('猩红的仪式', '两路', 'm011', '英雄 近战兵 远程兵 | 超级兵 弗拉基米尔* 炮车 | 英雄 英雄 英雄',
         '弗拉基米尔在中路主持猩红仪式。'),
        ('男爵的宴会', '全歼', 'm013 m011', '英雄 英雄 超级兵 远程兵 | 恶魔男爵瑞兹* 英雄 英雄 炮车',
         '恶魔男爵瑞兹在右路摆下宴席。'),
        ('黑色的礼物', '全歼', 'm011 m014 m011', '英雄 英雄 远程兵 | 超级兵 邪恶圣诞老人维嘉* 炮车 | 英雄 英雄 近战兵',
         '邪恶圣诞老人维嘉在中路分发黑色礼物。'),
        ('骸骨合唱团', '两翼', 'm011', '英雄 近战兵 远程兵 | 锤石* 超级兵 炮车 | 英雄 英雄 英雄',
         '锤石领着骸骨合唱团守在中路；拿下左、右两路即可绕开他。'),
        ('安魂曲奏响', '全歼', 'm011 m013 m011', '英雄 英雄 远程兵 | 莫德凯撒 卡尔萨斯* 弗拉基米尔 | 英雄 超级兵 炮车',
         '卡尔萨斯在中路唱起安魂曲，莫德凯撒挡在他身前，弗拉基米尔守在他身后。'),
    )),
    ('霜原部落', '泰达米尔', ('瑟庄妮', '丽桑卓', '极地射手艾希'), (
        ('冰原狼群', '两路', 'm004', '纳尔* 近战兵 英雄 | 英雄 英雄 炮车 | 英雄 英雄 远程兵',
         '纳尔在左路领着狼群冲锋。'),
        ('冰裂的湖面', '全歼', 'm002 m004', '英雄 英雄 英雄 远程兵 | 艾尼维亚* 英雄 英雄 超级兵',
         '艾尼维亚在右路冻住了湖面。'),
        ('蛮王的酒宴', '全歼', 'm004', '古拉加斯 英雄 远程兵 | 超级兵 艾希* 英雄 | 英雄 英雄 炮车',
         '艾希在中路举杯，古拉加斯在左路早已喝醉；全歼才能散席。'),
        ('冰崖哨口', '中路', 'm004', '英雄 英雄 远程兵 | 瑟庄妮* 超级兵 炮车 | 英雄 英雄 英雄',
         '瑟庄妮骑着战猪守住中路哨口；击溃中路即可通过，中路失守即告失败。'),
        ('怒火不熄', '全歼', 'm004', '英雄 英雄 远程兵 | 瑟庄妮 泰达米尔* 艾希 | 英雄 英雄 超级兵',
         '泰达米尔在中路怒吼，瑟庄妮挡在他身前，艾希在他身后张弓。'),
    )),
    ('凛冬之爪', '瑟庄妮', ('努努', '丽桑卓', '极地射手艾希'), (
        ('部落的战鼓', '两路', 'm004', '英雄 英雄 远程兵 | 泰达米尔* 超级兵 炮车 | 英雄 英雄 英雄',
         '泰达米尔敲响部落的战鼓，在中路领着战士冲锋。'),
        ('冰封的箭雨', '全歼', 'm004', '英雄 英雄 英雄 远程兵 | 英雄 英雄 极地射手艾希* 超级兵',
         '极地射手艾希在右路放出冰封的箭雨。'),
        ('冰川裂谷', '全歼', 'm004 m002 m004', '英雄 近战兵 远程兵 | 纳尔* 英雄 英雄 | 英雄 英雄 炮车',
         '纳尔守在中路的冰川裂谷前。'),
        ('部落营门', '两翼', 'm004', '英雄 英雄 远程兵 | 墨菲特* 超级兵 炮车 | 英雄 英雄 英雄',
         '墨菲特堵在中路营门前；拿下左、右两路即可绕开他。'),
        ('冬猎开始', '全歼', 'm004', '英雄 英雄 远程兵 | 纳尔 瑟庄妮* 艾尼维亚 | 英雄 英雄 超级兵',
         '瑟庄妮在中路发起冬猎，纳尔紧随其后，艾尼维亚在后方压阵。'),
    )),
    ('雪原秘境', '努努', ('艾尼维亚', '丽桑卓', '极地射手艾希'), (
        ('风雪迷途', '两路', 'm004', '英雄 英雄 远程兵 | 丽桑卓* 超级兵 炮车 | 英雄 英雄 英雄',
         '丽桑卓在中路的风雪里等着迷路的旅人。'),
        ('冰晶洞窟', '全歼', 'm004 m013', '英雄 英雄 英雄 远程兵 | 布兰德* 英雄 英雄 超级兵',
         '布兰德在右路点燃了冰晶洞窟。'),
        ('冰原上的童谣', '全歼', 'm004', '瑟庄妮* 英雄 英雄 英雄 英雄 英雄 远程兵',
         '冰原上只剩一条小路，瑟庄妮骑着战猪挡在路上。'),
        ('威朗普守山口', '中路', 'm004', '英雄 英雄 远程兵 | 努努* 超级兵 炮车 | 英雄 英雄 英雄',
         '努努和威朗普守住中路山口；击溃中路即可通过，中路失守即告失败。'),
        ('雪人的约定', '全歼', 'm004 m002 m004', '英雄 英雄 远程兵 | 瑟庄妮 努努* 艾希 | 英雄 英雄 超级兵',
         '努努和威朗普守在中路，瑟庄妮紧随其后，艾希在后方掩护。'),
    )),
    ('冰凤之巢', '艾尼维亚', ('丽桑卓', '极地射手艾希', '泰达米尔'), (
        ('冰封的长廊', '两路', 'm004', '英雄 英雄 远程兵 | 雷兹* 超级兵 炮车 | 英雄 英雄 英雄',
         '雷兹在中路长廊深处寻找世界符文。'),
        ('巢中的冰蛋', '全歼', 'm004 m006', '英雄 英雄 英雄 远程兵 | 艾尼维亚* 英雄 英雄 超级兵',
         '艾尼维亚守在右路的巢里，护着一枚冰蛋。'),
        ('三姐妹的传说', '全歼', 'm004', '瑟庄妮 英雄 远程兵 | 超级兵 丽桑卓* 英雄 | 艾希 英雄 炮车',
         '艾希、瑟庄妮与丽桑卓各守一路，三姐妹的传说在这里重演。'),
        ('寒霜结界', '两翼', 'm004', '英雄 英雄 远程兵 | 泰达米尔* 超级兵 炮车 | 英雄 英雄 英雄',
         '泰达米尔守在中路结界前；拿下左、右两路即可绕过结界。'),
        ('冰凤涅槃', '全歼', 'm004 m006 m004', '英雄 英雄 远程兵 | 努努 艾尼维亚* 丽桑卓 | 英雄 英雄 超级兵',
         '艾尼维亚在中路从冰蛋中重生，努努挡在她身前，丽桑卓守在她身后。'),
    )),
    ('寒冰王座', '丽桑卓', ('蕾欧娜', '黛安娜'), (
        ('寒冰守卫', '两路', 'm004', '英雄 英雄 远程兵 | 英雄 超级兵 炮车 | 英雄 极地射手艾希* 英雄',
         '极地射手艾希在右路放箭。'),
        ('王座的阶梯', '全歼', 'm004 m013', '英雄 英雄 英雄 远程兵 | 努努* 英雄 英雄 超级兵',
         '努努和威朗普在右路的阶梯上打滚。'),
        ('冰卫的誓言', '全歼', 'm004', '瑟庄妮 英雄 远程兵 | 超级兵 艾希* 英雄 | 泰达米尔 英雄 炮车',
         '艾希在中路立下誓言；瑟庄妮守左路，泰达米尔守右路。'),
        ('王冠之下', '中路', 'm004 m006 m004', '英雄 英雄 远程兵 | 超级兵 艾尼维亚* 炮车 | 英雄 英雄 英雄',
         '艾尼维亚在中路守护王座；击溃中路即可登上王座，中路失守即告失败。'),
        ('沉睡的守望者', '全歼', 'm004 m013 m004', '英雄 英雄 远程兵 | 努努 丽桑卓* 艾尼维亚 | 瑟庄妮 英雄 超级兵',
         '丽桑卓在中路王座上唤醒沉睡的守望者，努努挡在她身前，艾尼维亚守在她身后；瑟庄妮守在右路。'),
    )),
    ('烈阳圣坛', '蕾欧娜', ('黛安娜', '凯尔'), (
        ('登山者营地', '两路', 'm001 m004 m001', '英雄 英雄 远程兵 | 贾克斯* 超级兵 炮车 | 英雄 英雄 英雄',
         '贾克斯守在中路营地前，迎接每一个登山者。'),
        ('日光长阶', '全歼', 'm006 m001', '英雄 英雄 英雄 远程兵 | 拉克丝* 英雄 英雄 超级兵',
         '拉克丝在右路点亮长阶。'),
        ('堕落之翼', '全歼', 'm006', '潘森 英雄 远程兵 | 超级兵 莫甘娜* 英雄 | 英雄 英雄 炮车',
         '莫甘娜张开堕落之翼坐镇中路，潘森守在左路。'),
        ('烈日当空', '中路', 'm006 m001 m006', '英雄 英雄 远程兵 | 嘉文四世* 超级兵 炮车 | 英雄 英雄 英雄',
         '嘉文四世在烈日下守住中路；击溃中路即可登上圣坛，中路失守即告失败。'),
        ('日冕加身', '全歼', 'm006 m004 m006', '英雄 英雄 远程兵 | 蕾欧娜* 潘森 拉克丝 | 英雄 英雄 超级兵',
         '蕾欧娜披着日冕站在中路最前，潘森与拉克丝紧随其后。'),
    )),
    ('皎月神殿', '黛安娜', ('塔里克', '凯尔'), (
        ('月下的巡礼', '两路', 'm006', '英雄 英雄 远程兵 | 蕾欧娜* 超级兵 炮车 | 英雄 英雄 英雄',
         '蕾欧娜带着巡礼的队伍走在中路。'),
        ('暗月之下', '全歼', 'm006 m013', '英雄 英雄 英雄 远程兵 | 索拉卡* 英雄 英雄 超级兵',
         '索拉卡在右路的暗月之下为同伴祈愿。'),
        ('神殿前的长枪', '全歼', 'm006', '英雄 英雄 远程兵 | 潘森* 超级兵 炮车 | 英雄 英雄 英雄',
         '潘森持枪守在中路神殿前。'),
        ('月蚀之门', '两翼', 'm006', '英雄 英雄 远程兵 | 塔里克* 超级兵 炮车 | 英雄 英雄 英雄',
         '塔里克守在中路月蚀之门前；拿下左、右两路即可绕开他。'),
        ('皎月降临', '全歼', 'm006 m013 m006', '英雄 英雄 远程兵 | 希瓦娜 黛安娜* 莫甘娜 | 蕾欧娜 英雄 超级兵',
         '黛安娜在中路月光下拔出月刃，希瓦娜挡在她身前，莫甘娜守在她身后；宿敌蕾欧娜也站到了右路。'),
    )),
    ('群星之门', '塔里克', ('潘森', '凯尔'), (
        ('攀登者的足迹', '两路', 'm006', '英雄 英雄 远程兵 | 伊泽瑞尔* 超级兵 炮车 | 英雄 英雄 英雄',
         '伊泽瑞尔走在中路，寻找通往群星之门的路。'),
        ('星辰的伤痕', '全歼', 'm006 m004', '蕾欧娜* 英雄 英雄 远程兵 | 英雄 英雄 英雄 超级兵',
         '蕾欧娜在左路领头。'),
        ('守护者的试炼', '全歼', 'm006', '潘森* 英雄 英雄 英雄 英雄 英雄 远程兵',
         '通往群星之门只剩一条路，潘森在这里设下试炼。'),
        ('群星的屏障', '中路', 'm006', '英雄 英雄 远程兵 | 嘉文四世* 超级兵 炮车 | 英雄 英雄 英雄',
         '嘉文四世在中路架起屏障；击溃中路即可通过，中路失守即告失败。'),
        ('宝石骑士之誓', '全歼', 'm006 m004 m006', '潘森 英雄 远程兵 | 蕾欧娜 塔里克* 索拉卡 | 英雄 英雄 超级兵',
         '塔里克在中路立誓守护众星，蕾欧娜挡在他身前，索拉卡守在他身后；左路是潘森。'),
    )),
    ('战神之峰', '潘森', ('凯尔', '阿兹尔'), (
        ('长枪如林', '两路', 'm001 m006 m001', '赵信* 英雄 远程兵 | 英雄 超级兵 炮车 | 英雄 英雄 英雄',
         '赵信在左路领着枪阵。'),
        ('月刃的伏击', '全歼', 'm006', '英雄 英雄 英雄 远程兵 | 黛安娜* 英雄 英雄 超级兵',
         '黛安娜埋伏在右路。'),
        ('烈阳与皎月', '全歼', 'm006', '英雄 英雄 远程兵 | 蕾欧娜* 英雄 炮车 | 黛安娜 英雄 超级兵',
         '蕾欧娜守在中路，黛安娜守在右路，烈阳与皎月难得并肩。'),
        ('宗师守关', '两翼', 'm006 m001 m006', '英雄 英雄 远程兵 | 贾克斯* 超级兵 炮车 | 英雄 英雄 英雄',
         '贾克斯举着灯柱守在中路；拿下左、右两路即可绕开他。'),
        ('凡人的怒火', '全歼', 'm006 m001 m006', '英雄 英雄 远程兵 | 蕾欧娜 潘森* 黛安娜 | 塔里克 英雄 超级兵',
         '潘森在中路举起长矛与盾牌，蕾欧娜冲在他前面，黛安娜守在他身后；右路是塔里克。'),
    )),
    ('登神长阶', '凯尔', ('白娘子', '敖兴'), (
        ('天梯的起点', '两路', 'm006', '英雄 英雄 远程兵 | 莫甘娜* 超级兵 炮车 | 英雄 英雄 英雄',
         '莫甘娜守在中路的天梯起点。'),
        ('圣焰洗礼', '全歼', 'm006', '希瓦娜* 英雄 英雄 远程兵 | 英雄 英雄 英雄 超级兵',
         '希瓦娜在左路迎着圣焰前进。'),
        ('光与暗之间', '全歼', 'm006 m013 m006', '英雄 英雄 远程兵 | 莫甘娜 拉克丝* 超级兵 | 英雄 英雄 炮车',
         '拉克丝与莫甘娜同守中路，光与暗在这里交汇。'),
        ('天界之门', '中路', 'm006', '英雄 英雄 远程兵 | 潘森* 超级兵 炮车 | 英雄 英雄 英雄',
         '潘森守在中路天界之门；击溃中路即可登顶，中路失守即告失败。'),
        ('天使的裁决', '全歼', 'm006', '英雄 英雄 远程兵 | 蕾欧娜 凯尔* 莫甘娜 | 拉克丝 英雄 超级兵',
         '凯尔在中路展开双翼，蕾欧娜挡在她身前，妹妹莫甘娜守在她身后；拉克丝站在右路。'),
    )),
    ('金山古寺', '白娘子', ('二郎真君赵信', '悟空'), (
        ('断桥相会', '两路', 'm002 m005 m002', '英雄 英雄 远程兵 | 易大师* 英雄 英雄 | 英雄 英雄 炮车',
         '易大师守在中路断桥上。'),
        ('狐仙的幻境', '全歼', 'm010 m002', '英雄 英雄 英雄 英雄 | 阿狸* 英雄 英雄 远程兵',
         '阿狸在右路布下幻境。'),
        ('端午的龙舟', '全歼', 'm002', '英雄 英雄 远程兵 | 英雄 粽子少女* 英雄 | 英雄 英雄 炮车',
         '粽子少女在中路的龙舟上召唤粽子。'),
        ('雷峰塔下', '中路', 'm003', '英雄 英雄 远程兵 | 慎* 英雄 炮车 | 英雄 英雄 英雄',
         '慎守在中路塔门；击溃中路即可进塔，中路失守即告失败。'),
        ('白蛇的执念', '全歼', 'm002 m003 m002', '英雄 英雄 远程兵 | 易大师 白娘子* 阿狸 | 英雄 英雄 英雄',
         '白娘子在中路掀起滔天大水，易大师挡在她身前，阿狸守在她身后。'),
    )),
    ('灌江神庙', '二郎真君赵信', ('悟空', '龙的传人李青'), (
        ('天兵列阵', '两路', 'm001 m003 m001', '赵信* 英雄 远程兵 | 英雄 英雄 炮车 | 英雄 英雄 英雄',
         '赵信在左路领着天兵列阵。'),
        ('江边的剑客', '全歼', 'm002 m005', '英雄 英雄 英雄 远程兵 | 亚索* 英雄 英雄 英雄',
         '亚索在右路江边拔剑。'),
        ('雷云压境', '全歼', 'm006 m001 m006', '英雄 英雄 远程兵 | 英雄 凯南* 英雄 | 英雄 英雄 炮车',
         '凯南在中路召来雷云。'),
        ('神庙山门', '两翼', 'm003', '英雄 英雄 远程兵 | 李青* 英雄 炮车 | 英雄 英雄 英雄',
         '李青守在中路山门；拿下左、右两路即可绕开他。'),
        ('天眼洞开', '全歼', 'm003 m006 m003', '英雄 英雄 远程兵 | 李青 二郎真君赵信* 英雄 | 英雄 英雄 英雄',
         '二郎真君赵信在中路睁开天眼，李青挡在他身前；他的神犬随时可能扑出。'),
    )),
    ('花果仙山', '悟空', ('龙的传人李青', '敖兴'), (
        ('水帘洞口', '两路', 'm002 m010 m002', '英雄 英雄 远程兵 | 新年安妮* 英雄 英雄 | 英雄 英雄 炮车',
         '新年安妮在中路的水帘洞口放起了爆竹。'),
        ('蟠桃盛会', '全歼', 'm010', '英雄 英雄 英雄 英雄 | 卡尔玛* 英雄 英雄 远程兵',
         '卡尔玛在右路张罗蟠桃盛会。'),
        ('天兵围山', '全歼', 'm010', '赵信* 英雄 英雄 英雄 英雄 英雄 英雄',
         '上山只有一条路，赵信率天兵把这条路围得水泄不通。'),
        ('云端的哨卡', '中路', 'm006', '英雄 英雄 远程兵 | 艾瑞莉娅* 英雄 炮车 | 英雄 英雄 英雄',
         '艾瑞莉娅守在中路的云端哨卡；击溃中路即可冲上云霄，中路失守即告失败。'),
        ('齐天大圣归来', '全歼', 'm010 m006 m010', '英雄 英雄 远程兵 | 李青 悟空* 英雄 | 赵信 英雄 英雄',
         '悟空在中路挥起金箍棒，李青冲在他前面；天兵出身的赵信反倒站在了右路。'),
    )),
    ('龙拳道场', '龙的传人李青', ('敖兴', '白娘子'), (
        ('上门踢馆', '两路', 'm003', '英雄 英雄 远程兵 | 李青* 英雄 英雄 | 英雄 英雄 炮车',
         '李青在中路接下踢馆的挑战。'),
        ('木人巷试炼', '全歼', 'm003 m010', '易大师* 英雄 英雄 英雄 | 英雄 英雄 英雄 远程兵',
         '易大师领着弟子在左路闯木人巷。'),
        ('道场比武', '全歼', 'm003', '英雄 英雄 远程兵 | 英雄 阿卡丽* 英雄 | 英雄 英雄 炮车',
         '阿卡丽在中路道场摆开架势。'),
        ('擂台规矩', '中路', 'm003', '英雄 英雄 远程兵 | 劫* 英雄 炮车 | 英雄 英雄 英雄',
         '劫守在中路擂台；击溃中路即可登台，中路失守即告失败。'),
        ('拳出如龙', '全歼', 'm003 m006 m003', '英雄 英雄 远程兵 | 李青 龙的传人李青* 易大师 | 英雄 英雄 英雄',
         '龙的传人李青在中路摆开架势，李青与易大师挡在他身前。'),
    )),
    ('东海龙宫', '敖兴', ('恶魔之刃泰达米尔', '大肥鱼！'), (
        ('虾兵蟹将', '两路', 'm005', '英雄 英雄 远程兵 | 英雄 娜美* 英雄 | 英雄 英雄 近战兵',
         '虾兵蟹将守着龙宫外围，娜美在中路掌管潮水。'),
        ('定海神针', '全歼', 'm005 m002', '英雄 英雄 英雄 远程兵 | 悟空* 英雄 英雄 英雄',
         '悟空闯进龙宫要借定海神针，正在右路翻找。'),
        ('龙宫宝库', '全歼', 'm005 m002 m005', '塔姆肯奇 英雄 远程兵 | 英雄 菲兹* 英雄 | 英雄 英雄 炮车',
         '菲兹守在中路宝库前，塔姆肯奇在左路张着大嘴。'),
        ('潮汐之门', '两翼', 'm005', '英雄 英雄 远程兵 | 白娘子* 英雄 炮车 | 英雄 英雄 英雄',
         '白娘子守在中路潮汐之门前；拿下左、右两路即可绕开她。'),
        ('龙王掀起风暴', '全歼', 'm005 m006 m005', '英雄 英雄 远程兵 | 亚索 敖兴* 娜美 | 英雄 英雄 英雄',
         '敖兴在中路掀起风暴，亚索挡在他身前，娜美守在他身后。'),
    )),
    ('魔刃战场', '恶魔之刃泰达米尔', ('大肥鱼！', '冠军-卡密尔'), (
        ('恶魔的狂宴', '两路', 'm011 m014 m011', '英雄 英雄 远程兵 | 恶魔男爵瑞兹* 英雄 英雄 | 英雄 英雄 英雄',
         '恶魔男爵瑞兹在中路开席。'),
        ('暗裔的剑冢', '全歼', 'm012 m011', '亚托克斯* 英雄 英雄 英雄 | 英雄 英雄 英雄 英雄',
         '亚托克斯在左路的剑冢前挥剑。'),
        ('蛮王入魔', '全歼', 'm014', '英雄 英雄 远程兵 | 泰达米尔* 英雄 英雄 | 英雄 英雄 英雄',
         '泰达米尔在中路被恶魔的低语缠身。'),
        ('魔域之门', '中路', 'm011 m014 m011', '英雄 英雄 远程兵 | 莫德凯撒* 英雄 英雄 | 英雄 英雄 英雄',
         '莫德凯撒把守中路魔域之门；击溃中路即可破门，中路失守即告失败。'),
        ('魔刃出鞘', '全歼', 'm014 m011 m014', '亚托克斯 英雄 英雄 | 莫德凯撒 恶魔之刃泰达米尔* 泰达米尔 | 英雄 英雄 英雄',
         '恶魔之刃泰达米尔在中路拔出魔刃，莫德凯撒挡在他身前，入魔的泰达米尔跟在他身后；左路是亚托克斯。'),
    )),
    ('深海狂潮', '大肥鱼！', ('冠军-卡密尔', '黑夜使者亚索'), (
        ('渔港的警报', '两路', 'm005', '英雄 英雄 远程兵 | 菲兹* 英雄 英雄 | 英雄 英雄 英雄',
         '菲兹在中路拉响渔港的警报。'),
        ('鲸落之地', '全歼', 'm005 m002', '英雄 英雄 英雄 英雄 | 娜美* 英雄 英雄 英雄',
         '娜美在右路召来潮水。'),
        ('龙王追海', '全歼', 'm005 m006 m005', '英雄 英雄 远程兵 | 英雄 敖兴* 英雄 | 英雄 英雄 英雄',
         '敖兴从龙宫一路追到深海，守在中路。'),
        ('漩涡中心', '两翼', 'm005', '英雄 英雄 远程兵 | 塔姆肯奇* 英雄 英雄 | 英雄 英雄 英雄',
         '塔姆肯奇镇守中路漩涡中心；拿下左、右两路即可绕开漩涡。'),
        ('肥鱼翻江', '全歼', 'm005 m002 m005', '英雄 英雄 英雄 | 菲兹 大肥鱼！* 娜美 | 敖兴 英雄 英雄',
         '大肥鱼！在中路唤来巨鲸，菲兹冲在他前面，娜美守在他身后；龙王敖兴也赶到了右路。'),
    )),
    ('冠军之夜', '冠军-卡密尔', ('黑夜使者亚索', '神龙尊者卡莎'), (
        ('开幕表演', '两路', 'm006 m014 m006', '英雄 英雄 远程兵 | 偶像歌手阿狸* 英雄 英雄 | 英雄 英雄 英雄',
         '偶像歌手阿狸在中路开唱。'),
        ('裁判的哨声', '全歼', 'm014 m006', '英雄 英雄 英雄 英雄 | 逆转裁判崔斯特* 英雄 英雄 英雄',
         '逆转裁判崔斯特在右路吹响哨声。'),
        ('半决赛加赛', '全歼', 'm006', '足球先生伊泽瑞尔* 英雄 英雄 英雄 英雄 英雄 英雄',
         '加赛只开一条赛道，足球先生伊泽瑞尔带队上场。'),
        ('选手通道', '中路', 'm014 m006 m014', '英雄 英雄 远程兵 | 黄金骑士盖伦* 英雄 英雄 | 英雄 英雄 英雄',
         '黄金骑士盖伦堵住中路选手通道；击溃中路即可进场，中路失守即告失败。'),
        ('冠军的奖杯', '全歼', 'm006 m014 m006', '英雄 英雄 英雄 | 苹果机器人布里茨 冠军-卡密尔* 偶像歌手阿狸 | DJ娑娜 英雄 英雄',
         '冠军-卡密尔在中路举起奖杯，苹果机器人布里茨挡在她身前，偶像歌手阿狸守在她身后；DJ娑娜在右路打碟。'),
    )),
    ('永夜降临', '黑夜使者亚索', ('神龙尊者卡莎', '超级赛亚人孙悟空'), (
        ('长夜将至', '两路', 'm013', '英雄 英雄 远程兵 | 亚索* 英雄 英雄 | 英雄 英雄 英雄',
         '亚索在中路迎着长夜拔剑。'),
        ('暗巷里的影子', '全歼', 'm013 m011', '劫* 英雄 英雄 英雄 | 英雄 英雄 英雄 英雄',
         '劫在左路的暗巷里分出影子。'),
        ('双剑同鸣', '全歼', 'm013 m006 m013', '英雄 英雄 远程兵 | 亚索 源计划亚索* 英雄 | 英雄 英雄 英雄',
         '源计划亚索与亚索在中路并肩出剑。'),
        ('无月之夜', '两翼', 'm013', '英雄 英雄 远程兵 | 黛安娜* 英雄 英雄 | 英雄 英雄 英雄',
         '黛安娜在中路守着仅剩的月光；拿下左、右两路即可绕开中路。'),
        ('黑夜吞没疾风', '全歼', 'm013 m006 m013', '英雄 英雄 英雄 | 亚索 黑夜使者亚索* 源计划亚索 | 英雄 英雄 英雄',
         '黑夜使者亚索站在中路，亚索与源计划亚索挡在他身前；三把剑同时指向你。'),
    )),
    ('神话之巅', '神龙尊者卡莎', ('钢铁侠提莫', '超人提莫'), (
        ('魔刃与巨鲸', '两路', 'm014 m005 m014', '英雄 英雄 远程兵 | 恶魔之刃泰达米尔* 大肥鱼！ 英雄 | 英雄 英雄 英雄',
         '恶魔之刃泰达米尔与大肥鱼！在中路联手。'),
        ('冠军与永夜', '全歼', 'm006 m013', '冠军-卡密尔* 英雄 英雄 英雄 | 黑夜使者亚索 英雄 英雄 英雄',
         '冠军-卡密尔守在左路，黑夜使者亚索守在右路。'),
        ('神话集结', '全歼', 'm006', '英雄 英雄 英雄 | 敖兴* 白娘子 英雄 | 二郎真君赵信 英雄 远程兵',
         '敖兴与白娘子坐镇中路，二郎真君赵信守在右路。'),
        ('终焉之门', '中路', 'm006 m014 m006', '英雄 英雄 远程兵 | 恶魔之刃泰达米尔* 冠军-卡密尔 黑夜使者亚索 | 英雄 英雄 英雄',
         '恶魔之刃泰达米尔、冠军-卡密尔与黑夜使者亚索依次守住中路；击溃中路即可登顶，中路失守即告失败。'),
        ('神龙降世', '全歼', 'm006', '大肥鱼！ 英雄 英雄 | 恶魔之刃泰达米尔 神龙尊者卡莎* 冠军-卡密尔 黑夜使者亚索 | 二郎真君赵信 英雄 英雄',
         '神龙尊者卡莎在中路降临，恶魔之刃泰达米尔挡在她身前，冠军-卡密尔与黑夜使者亚索守在她身后；所有传说都在这里等你。'),
    )),
)


def chapter_act(chapter):
    return (chapter - FIRST_CHAPTER) // 5


def finale_display(start, chapter, diff):
    """Displayed recommendation of a chapter finale on the 30->60 curve."""
    end = FINALE_POWER[diff]
    return start * (end / start) ** ((chapter - 30) / (LAST_CHAPTER - 30))


def actual_for_display(display):
    """Inverse of normalize_team_power: the squared-panel team budget."""
    return POWER_ANCHOR * (display / POWER_ANCHOR) ** (4 / 3)


def parse_lanes(text):
    """'a b | c* 英雄 | e' -> [(lane, name, captain), ...] in authored order."""
    lanes = [part.split() for part in text.split('|')]
    if not 1 <= len(lanes) <= 3 or not all(lanes):
        raise ValueError(f'lineup must fill one to three lanes: {text}')
    units = [(lane, name.rstrip('*'), name.endswith('*'))
             for lane, names in enumerate(lanes) for name in names]
    if sum(unit[2] for unit in units) != 1:
        raise ValueError(f'lineup needs exactly one captain: {text}')
    return units


def lane_count(text):
    return text.count('|') + 1


def _reach(cfg, aid):
    panel = cfg['avatar'][aid].get('pl', [])
    return int(panel[9]) if len(panel) > 9 and panel[9] else 300


def _depth_key(cfg, aid):
    if aid in MINION_DEPTH:
        return MINION_DEPTH[aid]
    family = aid.rsplit('_', 1)[0]
    if family in TANK_FAMILIES:
        return 0
    if family in SUPPORT_FAMILIES:
        return 6
    return 4 if _reach(cfg, aid) >= 500 else 1


def _tiebreak(stage_id, diff, aid):
    return hashlib.sha256(f'{stage_id}:{diff}:{aid}'.encode()).hexdigest()


ERA_BONUS = 2


def _era(chapter):
    return int(chapter > (FIRST_CHAPTER + LAST_CHAPTER) // 2)


def _eligible(cfg, aid, chapter):
    return aid in cfg.get('avatar', {}) and chapter > LEGEND_CHAPTER.get(aid, 0)


def plan_rosters(cfg):
    """{(chapter, number): (normal aids, elite aids)} in authored slot order.

    Pool slots go to the least-used eligible hero of that mode across all 150
    stages, counting the authored heroes and elite guests up front, so usage
    stays even from the first chapter to the last.
    """
    stages = [(chapter, number, rows[number - 1])
              for chapter, (_, _, _, rows) in enumerate(CHAPTERS, FIRST_CHAPTER)
              for number in range(1, STAGES + 1)]
    authored = Counter(HEROES[name] for _, _, row in stages for _, name, _ in parse_lanes(row[3])
                       if name in HEROES)
    guests = {}
    for chapter, number, row in stages:
        names = {HEROES.get(name) for _, name, _ in parse_lanes(row[3])}
        guests[chapter, number] = next((HEROES[name] for name in CHAPTERS[chapter - FIRST_CHAPTER][2]
                                        if HEROES[name] not in names), None)
    usage = {'0': Counter(authored), '1': Counter(authored)}
    usage['1'].update(guests[chapter, STAGES] for chapter in range(FIRST_CHAPTER, LAST_CHAPTER + 1)
                      if guests[chapter, STAGES])
    # A hero not yet seen in this half of the arc counts as ERA_BONUS fights
    # fewer, so a hero written into many early stages still returns late.
    seen = {(diff, era): set() for diff in ('0', '1') for era in (0, 1)}
    for chapter, number, row in stages:
        for _, name, _ in parse_lanes(row[3]):
            if name in HEROES:
                for diff in ('0', '1'):
                    seen[diff, _era(chapter)].add(HEROES[name])
    plans = {}
    for chapter, number, row in stages:
        stage_id = f'M_{chapter:03d}_{number}'
        era = _era(chapter)
        units = parse_lanes(row[3])
        result = {}
        for diff in ('0', '1'):
            aids = [HEROES.get(name) or MINIONS.get(name) for _, name, _ in units]
            slots = [name for _, name, _ in units]
            minions = [i for i, name in enumerate(slots) if name in MINIONS]
            if diff == '1' and minions:
                # Elite fields one more hero: the next boss at the finale,
                # a pool hero elsewhere.
                guest = guests[chapter, number] if number == STAGES else None
                if guest:
                    aids[minions[-1]] = guest
                else:
                    slots[minions[-1]] = FILLER
            for index, name in enumerate(slots):
                if name != FILLER:
                    continue
                taken = set(aids)
                choice = min((aid for aid in POOL if aid not in taken and _eligible(cfg, aid, chapter)),
                             key=lambda aid: (usage[diff][aid] - (aid not in seen[diff, era]) * ERA_BONUS,
                                              _tiebreak(stage_id, diff, aid)))
                aids[index] = choice
                usage[diff][choice] += 1
                seen[diff, era].add(choice)
            result[diff] = aids
        plans[chapter, number] = result['0'], result['1']
    return plans


def build_roster(cfg, chapter, number, lineup, aids, diff):
    """Native stage rows for one planned roster, lanes ordered front to back."""
    act = chapter_act(chapter)
    units = parse_lanes(lineup)
    # Authored heroes keep their written order ahead of pool heroes of the
    # same role, so the card text's "in front of / behind" stays true.
    named = [name in HEROES for _, name, _ in units]
    lanes = {}
    for index, ((lane, _, captain), aid) in enumerate(zip(units, aids)):
        lanes.setdefault(lane, []).append((_depth_key(cfg, aid), not named[index], not captain, index,
                                           aid, captain))
    rows = []
    for lane in sorted(lanes):
        members = sorted(lanes[lane])
        step = min(.12, .38 / max(1, len(members) - 1))
        for depth, (*_, aid, captain) in enumerate(members):
            hero = aid not in MINIONS.values()
            level = LEVEL if number != STAGES or captain else ESCORT_LEVEL
            rows.append([aid, level, SKILL_LEVEL[diff][act], lane, round(.46 - depth * step, 3),
                         int(captain), HERO_DROP_RATE if hero else 0, 0, '', None, None, None,
                         _reach(cfg, aid)])
    stagger_lane_offsets(rows)
    return rows


def _shape(cfg, aid, weights):
    stats = level_stats(cfg['avatar'][aid], LEVEL, enforce_cap=False)
    values = (stats['health'], stats['attack'], stats['physical_defense'], stats['magic_defense'])
    weighted = sum(v * w for v, w in zip(values, weights))
    return [v / weighted for v in values]


def fit_roster(cfg, team, display):
    """Enemy snapshot rows whose real team power matches a displayed target."""
    weights = [float(v) for v in cfg['system_simple']['power'][1:5]]
    hero_shapes = [_shape(cfg, row[0], weights) for row in team if row[0] not in MINIONS.values()]
    common = [sum(column) / len(hero_shapes) for column in zip(*hero_shapes)]
    rows = []
    for index, row in enumerate(team):
        if row[0] in MINIONS.values():
            shape, scale = common, MINION_WEIGHT
        else:
            shape, scale = _shape(cfg, row[0], weights), LEADER_WEIGHT if row[5] else HERO_WEIGHT
        hp, ap, de_ph, de_ma = (max(1, round(v * scale * 10000)) for v in shape)
        rows.append({'index': index, 'aid': row[0], 'hp': hp, 'ap': ap, 'de_ph': de_ph, 'de_ma': de_ma,
                     'hit': 0, 'flee': 0, 'crit': 0, 'tough': 0})
    # A hair above the inverse so the floored display never lands one unit
    # short (the chapter-60 finales show exactly 200亿 and 3000亿).
    target = round(actual_for_display(display) * (1 + 1e-6))
    # Power is quadratic in the four stats: start near the target, then let
    # the shared bisection land on it exactly.
    ratio = math.sqrt(target / _power(cfg, team, rows))
    for row in rows:
        for key in ('hp', 'ap', 'de_ph', 'de_ma'):
            row[key] = max(1, round(row[key] * ratio))
    fitted, actual = _fit_power(cfg, team, rows, target)
    if max(row['hp'] for row in fitted) > HP_LIMIT:
        raise ValueError('campaign enemy health exceeds the battle result bound')
    return fitted, actual


def _regular_heroes(document, team):
    """Regular (non-skin, non-legend) 6-star heroes in a roster that a player may own."""
    from gameplay_common import ensure_hero_acquirable
    from hero_catalog_105 import is_abandoned
    from player_store import GameplayFault
    cfg = document['cfg']
    result = []
    for row in team:
        aid = row[0]
        if not aid.endswith('_6') or aid.rsplit('_', 1)[0][2:4] not in ('10', '11') or is_abandoned(cfg, aid):
            continue
        try:
            ensure_hero_acquirable(aid, document)
        except GameplayFault:
            continue
        result.append(aid)
    return sorted(set(result))


def _hero_drops(document, normal, team):
    """Purple-card candidates in the native hero_drop shape (1% per win)."""
    from gameplay_common import ensure_hero_acquirable
    from player_store import GameplayFault
    cfg = document['cfg']
    on_field = {row[0] for row in normal}
    result = []
    for aid in _regular_heroes(document, team):
        family = aid.rsplit('_', 1)[0]
        drop = family + '_5'
        if aid not in on_field or drop not in cfg['avatar']:
            continue
        try:
            ensure_hero_acquirable(drop, document)
        except GameplayFault:
            continue
        result.append({'family': family, 'enemy_aid': aid, 'aid': drop, 'star': 5, 'chance_bp': 100})
    return result


def _stage_rule(stage, key, diff):
    rules = stage.get(key)
    return rules.get(str(diff)) if isinstance(rules, dict) else None


def roll_hero_card(config, stage, cid, diff, rng):
    """One orange hero card, or None, for a won chapter 31-60 normal stage."""
    from gameplay_common import ensure_hero_acquirable
    from hero_workshop import is_test_hero
    from mod_policy import candidate_ids, runtime
    from player_store import GameplayFault
    rule = _stage_rule(stage, 'campaign_card_drop_106', diff)
    if rule is None:
        return None
    cfg = config.get('cfg', config)
    on_field = {row[0] for row in stage.get('team2', []) if isinstance(row, (list, tuple)) and row}
    candidates = rule.get('candidates')
    chance = rule.get('chance_bp')
    if (not isinstance(candidates, list) or type(chance) is not int or not 0 <= chance <= 10000
            or any(aid not in cfg.get('avatar', {}) or aid not in on_field or not str(aid).endswith('_6')
                   for aid in candidates)):
        raise GameplayFault('InvalidHeroDropPolicy', 'Campaign card drop rule is malformed')
    pool = [aid for aid in candidates if not is_test_hero(config, aid)]
    if runtime(config):
        pool = candidate_ids(config, pool, 'acquisition.drop.campaign', include_new=True, quality=6)
    if not pool or rng.randrange(10000) >= chance:
        return None
    aid = rng.choice(pool)
    ensure_hero_acquirable(aid, config)
    return aid


def roll_relic(config, stage, cid, diff, rng):
    """One abyss relic, or None, for a won chapter 31-60 elite stage."""
    from abyss_relics import new_relic
    from player_store import GameplayFault
    rule = _stage_rule(stage, 'abyss_relic_drop_106', diff)
    if rule is None:
        return None
    chance, ceiling = rule.get('chance_bp'), rule.get('max_ancient')
    if type(chance) is not int or not 0 <= chance <= 10000 or type(ceiling) is not int or ceiling < 0:
        raise GameplayFault('InvalidRelicDropPolicy', 'Campaign relic drop rule is malformed')
    if rng.randrange(10000) >= chance:
        return None
    cfg = config.get('cfg', config)
    # Redraw rather than strip affixes, so a kept relic is an ordinary roll.
    # Each draw qualifies ~97% of the time; ids come from the same stream so
    # a retried settlement rebuilds the identical relic.
    for _ in range(64):
        item = new_relic(cfg, rng, item_id='relic-%024x' % rng.getrandbits(96))
        ancient = int(item['main']['ancient']) + sum(bool(a['ancient']) for a in item['substats'])
        if ancient <= ceiling:
            return item
    raise GameplayFault('InvalidRelicDropPolicy', 'Campaign relic roll did not settle')


def stage_reward(cfg, chapter, stage):
    act = chapter_act(chapter)
    reward = {'gold': 102000 + 3000 * (chapter - FIRST_CHAPTER) + 1000 * (stage - 1),
              'exp': (840, 855, 870, 885, 900)[stage - 1], 'attrs': {},
              'first_clear': {'coin': 40, 'attrs': {}},
              'heroes': [{'aid': 'A_6996_5', 'num': {3: 2, 5: 3}.get(stage, 1)}]}
    if stage in (3, 5):
        reward['attrs']['dust'] = list(ACT_DUST[act])
    if stage == 5:
        reward['attrs'].update(culture_book=ACT_BOOKS[act], sp=[ACT_SP[act]] * 6, dn_stone=2 * chapter)
        items = [{'eid': RED_BOOKS[(chapter - FIRST_CHAPTER) % len(RED_BOOKS)], 'num': 1}]
        if chapter in ACT_ORANGE:
            items.append({'eid': ACT_ORANGE[chapter], 'num': 1})
        reward['first_clear'] = {'coin': 100, 'mark': 60 * (act + 1), 'attrs': {}, 'items': items}
    return reward


def reward_texts(cfg, reward):
    """(reward_note, card suffix) describing the authored rewards."""
    attrs = reward['attrs']
    parts = []
    if 'sp' in attrs:
        parts.append(f'六类天赋点各{attrs["sp"][0]}点')
    if 'dust' in attrs:
        parts.append('四色洗练粉尘各' + '、'.join(str(n) for n in attrs['dust']) + '份')
    if 'culture_book' in attrs:
        parts.append(f'培养书{attrs["culture_book"]}本')
    if 'dn_stone' in attrs:
        parts.append(f'德诺石{attrs["dn_stone"]}个')
    note = '每次胜利获得' + '、'.join(parts) + '。' if parts else ''
    first = reward['first_clear']
    if not first.get('items'):
        return note, ''
    names = [cfg['equip'][item['eid']]['name'] for item in first['items']]
    suffix = '首通奖励：' + '、'.join(names + [f'洗练印记×{first["mark"]}']) + '。'
    return note + suffix, suffix


def apply_campaign_expansion(document):
    cfg = document.get('cfg', document)
    if cfg.get('campaign_expansion_106', {}).get('schema') == SCHEMA:
        return document
    main, chapters = cfg['combat_main'], cfg['battle_main']
    if any(f'M_{chapter:03d}' in chapters for chapter in range(FIRST_CHAPTER, LAST_CHAPTER + 1)):
        raise ValueError('campaign chapters 31-60 already exist outside this overlay')
    last = max((int(cid.rsplit('_', 1)[1]), stage) for cid, stage in main.items()
               if cid.startswith(f'M_{FIRST_CHAPTER - 1:03d}_'))[1]
    start = {diff: last['recommended_power_by_diff'][diff] for diff in FINALE_POWER}
    plans = plan_rosters(cfg)
    stages, battle, report = {}, {}, []
    for chapter, (chapter_name, boss, _, rows) in enumerate(CHAPTERS, FIRST_CHAPTER):
        chapter_id = f'M_{chapter:03d}'
        battle[chapter_id] = {'id': chapter_id, 'name': chapter_name, 'combat': STAGES, 'story': [],
                              'indexID_s': chapter, 'ulv': 1, 'campaign_quality': 'red'}
        for number, (title, rule, backgrounds, lineup, text) in enumerate(rows, 1):
            lanes = lane_count(lineup)
            planned = plans[chapter, number]
            normal = build_roster(cfg, chapter, number, lineup, planned[0], '0')
            elite = build_roster(cfg, chapter, number, lineup, planned[1], '1')
            fitted, actual, display = {}, {}, {}
            for diff, team in (('0', normal), ('1', elite)):
                target = finale_display(start[diff], chapter, diff) * STAGE_SHARE[number - 1]
                fitted[diff], actual[diff] = fit_roster(cfg, team, target)
                display[diff] = normalize_team_power(actual[diff])
            reward = stage_reward(cfg, chapter, number)
            note, suffix = reward_texts(cfg, reward)
            cards = _regular_heroes(document, normal)
            drops = '精英难度可能掉落深渊遗物。本关不可扫荡。'
            if cards:
                drops = '小概率掉落场上英雄的紫卡，普通难度另有橙卡；' + drops
            bg = backgrounds.split()
            stage_id = f'{chapter_id}_{number}'
            stages[stage_id] = {
                'id': stage_id, 'name': f'第{chapter}章·{title}',
                'line': [lanes, bg * lanes if len(bg) == 1 else bg], 'team1': [], 'team2': normal,
                'ulv': LEVEL * 100, 'win': list(WIN_RULES[rule]), 'energy': 5 if number == STAGES else 3,
                'exp': reward['exp'], 'gold': reward['gold'], 'limit': [99, 99, 99], 'pre': [],
                'new_4attrs': [0, 0, 0, 0], 'equip_drop': [], 'index': number, 'indexID_s': number,
                'status_activity': 0, 'reward': reward, 'reward_note': note + drops, 'hard_scale': 1.28,
                'info': text + suffix + drops, 'sweep_disabled': True,
                'enemy_unit_stats_by_diff': fitted,
                'hero_drop_candidates_by_diff': {'0': _hero_drops(document, normal, normal),
                                                 '1': _hero_drops(document, normal, elite)},
                'campaign_card_drop_106': ({'0': {'chance_bp': CARD_CHANCE_BP, 'candidates': cards}}
                                           if cards else {}),
                'abyss_relic_drop_106': {'1': {'chance_bp': RELIC_CHANCE_BP[number - 1],
                                               'max_ancient': RELIC_MAX_ANCIENT}},
                'recommended_power': display['0'], 'recommended_power_by_diff': display,
                'recommended_power_original_104': actual, 'recommendation_schema': POWER_SCHEMA,
                'recommended_power_source': 'actual enemy snapshot fitted to the chapter 31-60 curve',
                'campaign_scene': text, 'campaign_observation': OBSERVATIONS[rule],
                'campaign_elite_observation': '精英难度敌方技能等级更高，其余英雄另行抽取，并由一名英雄顶替一名小兵。',
                'team2_by_diff': {'1': elite},
            }
            serialize_stage_team(cfg, normal, team=2)
            serialize_stage_team(cfg, elite, team=2)
        report.append({'chapter': chapter, 'name': chapter_name, 'boss': boss,
                       'finale_power': stages[f'{chapter_id}_{STAGES}']['recommended_power_by_diff']})
    main.update(stages)
    for holder in (cfg, document.get('pve'), document):
        if isinstance(holder, dict) and isinstance(holder.get('battle_main'), dict):
            holder['battle_main'].update(copy.deepcopy(battle))
        if isinstance(holder, dict) and holder is not cfg and isinstance(holder.get('combat_main'), dict) \
                and holder['combat_main'] is not main:
            holder['combat_main'].update(copy.deepcopy(stages))
    gifts = cfg.setdefault('pass_battle_gift', {})
    for chapter in range(FIRST_CHAPTER, LAST_CHAPTER + 1):
        for diff, multiplier in (('0', 1), ('1', 2)):
            gifts.setdefault(diff, {})[f'M_{chapter:03d}'] = {'need_star': STAGES * 3,
                                                               'gift': {'coin': 60 * chapter * multiplier}}
    tiers = cfg['system_simple']['elite_equipment_drop']['tiers']
    for tier in ELITE_TIERS:
        ratio = list(tier['ratio'])
        chance = ratio[0] // ratio[1] if ratio[0] % ratio[1] == 0 else ratio[0] / ratio[1]
        tiers.append({key: value for key, value in tier.items() if key != 'ratio'}
                     | {'chance_bp': chance, 'chance_bp_fraction': ratio})
    cfg['campaign_expansion_106'] = {
        'schema': SCHEMA, 'chapters': [FIRST_CHAPTER, LAST_CHAPTER], 'stages_per_chapter': STAGES,
        'finale_power': dict(FINALE_POWER), 'start_power': start, 'stage_share': list(STAGE_SHARE),
        'curve': 'geometric between the chapter-30 and chapter-60 finales', 'report': report,
    }
    return document
