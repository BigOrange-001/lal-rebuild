"""Render group D's code-painted hero effects with the game's own effect code.

The core helpers (hero_fx_core_106.aspart) and group D's pure block (hero_fx_d_106.aspart)
are pasted into the Demonblade AIR harness (scripts/demonblade_fx_harness.as, adapted
here), compiled with mxmlc and run with adl. Every frame draws the exact sprite list the
game hands to Starling, plus the persistent marks through the same pose function; ffmpeg
turns the frames into looping videos and contact strips with an index page.

    python scripts/hero_fx_preview_d_106.py [--out DIR] [--only SCENE ...]
"""
import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT.parent / 'toolchain'
HELPERS = ('      // BEGIN HERO FX HELPERS 106\n', '      // END HERO FX HELPERS 106\n')
PURE = ('      // BEGIN HFX D PURE 106\n', '      // END HFX D PURE 106\n')
WHITE, GREEN, GOLD, CYAN = 0xFFFFFF, 0x66FF66, 0xFFD040, 0x7FF6FF
OFF = (-400, -400)


def unit(art, team, at, hp=1.0, label=None):
    row = dict(art=art, team=team, x=at[0], y=at[1], hp=hp)
    if label:
        row['label'] = label
    return row


def enemies(*spots):
    arts = ('A_1001_5', 'A_1002_5', 'A_1005_5')
    return [unit(arts[i % 3], 2, at) for i, at in enumerate(spots)]


def appear(index, at, x, y):
    return dict(unit=index, at=at, len=.01, x=x, y=y)


def hit(index, at, text, color=WHITE, size=None):
    row = dict(unit=index, at=at, text=text, color=color)
    if size:
        row['size'] = size
    return row


def mark(kind, ids, at, until=None, unit=0, count=None, points=None):
    row = dict(kind=kind, ids=ids, at=at, unit=unit)
    if until is not None:
        row['until'] = until
    if count is not None:
        row['count'] = count
    if points:
        row['points'] = points
    return row


E3 = [(240, 300), (196, 214), (288, 150)]
ALLY = 'A_1212_6'
SCENES = [
    dict(id='garen', title='盖伦 · 金狮突击 / 骑士誓约', dur=3.0,
         note='金狮突击：一道金色冲锋线冲到前排敌人身上，两道交叉的金色斩痕带着狮鬃般的金光炸开，随后头顶浮出蓝色的沉默封印；盖伦身周狮鬃金环一闪，胸前浮现盾徽（护盾）。骑士誓约：被守护的友军身侧常驻一枚淡金盾徽；友军受击时，一条金色光索从盖伦连到友军，盾徽亮起并给友军套上护盾。',
         units=[unit('A_1201_6', 1, (240, 560), label='盖伦'), unit(ALLY, 1, (330, 650))] + enemies((240, 300)),
         fx=[dict(kind='glion', src=0, tgt=2, at=.1, seed=11), dict(kind='gmane', src=0, tgt=0, at=.3, seed=12),
             dict(kind='gvow', src=0, tgt=1, at=1.9, seed=13), dict(kind='gaegis', src=0, tgt=1, at=2.0, seed=14)],
         marks=[mark('g_guard', ['crest'], 1.3, unit=1)],
         texts=[hit(2, .3, '-2140'), hit(1, 2.0, '-860'), hit(0, 2.0, '-150')]),
    dict(id='garen_ult', title='盖伦 · 王者裁决（击杀后净化）', dur=2.6,
         note='王者裁决：残血敌人脚下先亮起旋转的金色审判圆环，一柄巨剑从天而降插入目标，十字金光、冲击波和狮鬃金环同时炸开，剑身在伤害数字升起前就已消散，金色光点上浮（真伤）。击杀英雄时，每名友军身上一圈金环向上升起并飘出星光（净化）。',
         units=[unit('A_1201_6', 1, (240, 560), label='盖伦'), unit(ALLY, 1, (165, 650)), unit('A_1207_6', 1, (320, 650))]
         + enemies((240, 300, ), (196, 214)),
         fx=[dict(kind='gverdict', src=0, tgt=4, at=.1, seed=21)]
         + [dict(kind='gpurge', src=0, tgt=i, at=.85 + .05 * n, seed=22 + i) for n, i in enumerate((0, 1, 2))],
         values=dict(hp=[dict(unit=4, at=.55, value=0)]),
         texts=[hit(4, .58, '-5320', GOLD, 26)]),
    dict(id='ahri', title='阿狸·歌姬 · 魅力主打歌 / 温柔返场（溢疗护盾）', dur=2.4,
         note='魅力主打歌：一颗粉色爱心沿着音符弧线飞向前排及其后方敌人，命中处爱心放大炸开成音符和火花；随后两名残血友军身上飘起音符与小爱心回血。溢出的治疗化作一层粉色泡泡护盾，带一枚爱心闪光。',
         units=[unit('A_1207_6', 1, (240, 570), label='阿狸·歌姬'), unit(ALLY, 1, (165, 650)), unit('A_1201_6', 1, (320, 650))]
         + enemies(*E3[:2]),
         fx=[dict(kind='anote', src=0, tgt=3, at=.1, seed=31), dict(kind='anote', src=0, tgt=4, at=.2, seed=32),
             dict(kind='aheal', src=0, tgt=1, at=.5, seed=33), dict(kind='aheal', src=0, tgt=2, at=.56, seed=34),
             dict(kind='aoverflow', src=0, tgt=2, at=1.1, seed=35)],
         texts=[hit(3, .36, '-1260'), hit(4, .46, '-1260'), hit(1, .6, '+1100', GREEN), hit(2, .66, '+1100', GREEN)]),
    dict(id='ahri_ult', title='阿狸·歌姬 · 倾城独唱 / 返场', dur=3.6,
         note='倾城独唱：阿狸身旁升起三枚音符，一束柔和的追光打在攻击最高的敌人身上，粉白爱心光束从阿狸连到目标，目标身上一颗大爱心放大后炸开；同时一颗大爱心从外向内收拢锁住目标，头顶小星星旋转（眩晕+魅惑）。被魅惑期间目标头部两侧常驻两颗环绕的小爱心。返场：被魅惑者阵亡时友军身上彩纸飞舞、爱心上升（群体治疗），一颗爱心从天而降砸在残血敌人身上。',
         units=[unit('A_1207_6', 1, (240, 570), label='阿狸·歌姬'), unit(ALLY, 1, (165, 650))] + enemies((240, 300), (196, 214)),
         fx=[dict(kind='asolo', src=0, tgt=2, at=.1, seed=41), dict(kind='acharm', src=0, tgt=2, at=.4, seed=42),
             dict(kind='aencore', src=0, tgt=0, at=2.4, seed=43), dict(kind='aencore', src=0, tgt=1, at=2.46, seed=44),
             dict(kind='aencorehit', src=0, tgt=3, at=2.55, seed=45)],
         marks=[mark('a_charm', ['heart', 'heart'], 1.2, until=2.3, unit=2)],
         values=dict(hp=[dict(unit=2, at=2.3, value=0)]),
         texts=[hit(2, .95, '-3640'), hit(0, 2.55, '+980', GREEN), hit(1, 2.6, '+980', GREEN), hit(3, 2.9, '-1400')]),
    dict(id='riven_dance', title='锐雯·月兔 · 折翼舞步（三段）', dur=4.2,
         note='第一段：月光残影一路冲到前排，两道月白色新月斩交替划过；身周两枚新月环绕成盾（护盾）。第二段：两斩后粉色光点流回锐雯（吸血）。第三段：两斩后一轮新月砸下，两道新月交叉成 X，目标头顶小星星旋转（眩晕）。脚下三颗小月牙常驻，亮起的数量表示下一段是第几段。',
         units=[unit('A_1210_6', 1, (240, 470), label='锐雯·月兔')] + enemies((240, 300)),
         moves=[dict(unit=0, at=.1, len=.2, x=240, y=400), dict(unit=0, at=3.2, len=.25, x=240, y=560)],
         fx=[dict(kind='rshield', src=0, tgt=0, at=.1, seed=51), dict(kind='rdash', src=0, tgt=1, at=.1, seed=52, frozen=True),
             dict(kind='rcut0', src=0, tgt=1, at=.22, seed=53), dict(kind='rcut1', src=0, tgt=1, at=.4, seed=54),
             dict(kind='rcut0', src=0, tgt=1, at=1.3, seed=55), dict(kind='rcut1', src=0, tgt=1, at=1.48, seed=56),
             dict(kind='rleech', src=0, tgt=0, at=1.6, seed=57),
             dict(kind='rcut0', src=0, tgt=1, at=2.5, seed=58), dict(kind='rcut1', src=0, tgt=1, at=2.68, seed=59),
             dict(kind='rfinal', src=0, tgt=1, at=2.86, seed=60)],
         marks=[mark('r_dance', ['moon'] * 3, 0, until=1.1, count=2), mark('r_dance', ['moon'] * 3, 1.1, until=2.3, count=3),
                mark('r_dance', ['moon'] * 3, 2.3, count=1)],
         texts=[hit(1, .3, '-880'), hit(1, .48, '-880'), hit(1, 1.36, '-880'), hit(1, 1.54, '-880'), hit(0, 1.7, '+610', GREEN),
                hit(1, 2.56, '-1060'), hit(1, 2.74, '-1060'), hit(1, 3.1, '-1060')]),
    dict(id='riven_ult', title='锐雯·月兔 · 月兔终幕（觉醒与终幕剑气）', dur=3.6,
         note='觉醒：锐雯肩旁升起一弯新月，一只小月兔从月牙上跳过，脚下粉色光环转动；同时一道道新月刃飞向本路每个敌人。觉醒期间肩旁常驻一弯淡淡的新月与闪烁的星光。结束时：一道与分路同宽的新月剑气沿路横扫而过，经过每个敌人时打出月白斩痕。',
         units=[unit('A_1210_6', 1, (240, 590), label='锐雯·月兔')] + enemies(*E3),
         fx=[dict(kind='rmoon', src=0, tgt=0, at=.1, seed=61)]
         + [dict(kind='rawake', src=0, tgt=i, at=.3 + (i - 1) * .06, seed=61 + i) for i in (1, 2, 3)]
         + [dict(kind='rwave', src=0, tgt=1, at=2.2, seed=66)]
         + [dict(kind='rwhit', src=0, tgt=i, at=2.2 + .08 + .55 * min(1.4, r) / 1.4, seed=66 + i) for i, r in ((1, 1), (2, 1.3), (3, 1.6))],
         marks=[mark('r_awake', ['moon', 'star'], 1.5, until=2.25)],
         texts=[hit(1, .6, '-1650'), hit(2, .66, '-1650'), hit(3, .72, '-1650'), hit(1, 2.7, '-2480'), hit(2, 2.85, '-2480'), hit(3, 2.95, '-2480')]),
    dict(id='anivia', title='艾尼维亚 · 寒霜棱羽', dur=2.6,
         note='寒霜棱羽：一根冰羽带着雪尘飞向前两名敌人，命中处碎成冰晶，脚下一枚雪花转动着落定、霜圈扩散（寒冷）。寒冷期间脚边常驻一枚淡蓝雪花和一小块冰晶。已寒冷的目标再中冰羽时，脚下突起一排冰刺并炸开大雪花（伤害提高）。',
         units=[unit('A_1216_6', 1, (240, 590), label='艾尼维亚')] + enemies((240, 300), (196, 214)),
         fx=[dict(kind='nfeather', src=0, tgt=1, at=.1, seed=71), dict(kind='nfeather', src=0, tgt=2, at=.2, seed=72),
             dict(kind='nchill', src=0, tgt=1, at=.4, seed=73), dict(kind='nchill', src=0, tgt=2, at=.5, seed=74),
             dict(kind='nshatter', src=0, tgt=1, at=1.5, seed=75), dict(kind='nchill', src=0, tgt=1, at=1.8, seed=76)],
         marks=[mark('n_cold', ['flake', 'shard'], 1.0, unit=1), mark('n_cold', ['flake', 'shard'], 1.1, unit=2)],
         texts=[hit(1, .36, '-1180'), hit(2, .46, '-1180'), hit(1, 1.78, '-1570')]),
    dict(id='anivia_ult', title='艾尼维亚 · 极寒领域', dur=3.0,
         note='极寒领域：艾尼维亚身后展开冰翼，雪尘沿路涌向敌方；本路每个敌人头顶落雪，脚下一排冰刺破土而出。领域持续期间，整条分路上常驻一串缓缓转动的淡蓝雪花（地面）。下一次行动开始时领域再次发作：每个敌人脚下冒出三根冰刺。',
         units=[unit('A_1216_6', 1, (240, 610), label='艾尼维亚')] + enemies(*E3),
         fx=[dict(kind='nfield', src=0, tgt=1, at=.1, seed=81)]
         + [dict(kind='nstorm', src=0, tgt=i, at=.35 + (i - 1) * .07, seed=81 + i) for i in (1, 2, 3)]
         + [dict(kind='ntick', src=0, tgt=i, at=2.1 + (i - 1) * .06, seed=85 + i) for i in (1, 2, 3)],
         marks=[mark('n_frost', ['flake'], 1.6, points=[(240, 120), (240, 245), (240, 370), (240, 495), (240, 620)])],
         texts=[hit(1, .7, '-1310'), hit(2, .77, '-1310'), hit(3, .84, '-1310'), hit(1, 2.4, '-1310'), hit(2, 2.46, '-1310'), hit(3, 2.52, '-1310')]),
    dict(id='anivia_rebirth', title='艾尼维亚 · 冰晶重生', dur=3.4,
         note='致命一击后：冰晶从四周聚拢，结成一枚半透明的冰核罩住艾尼维亚（不遮血条），冰核期间常驻并微微闪动。下一次行动：冰核向外炸裂，冰晶四散，冰翼扇动一次；脚下有寒冷的敌人被一根冰锥击中，头顶星星旋转（眩晕）。',
         units=[unit('A_1216_6', 1, (240, 590), hp=.3, label='艾尼维亚')] + enemies((240, 300), (196, 214)),
         fx=[dict(kind='ncore', src=0, tgt=0, at=.1, seed=91), dict(kind='nreborn', src=0, tgt=0, at=2.0, seed=92),
             dict(kind='nburst', src=0, tgt=1, at=2.35, seed=93), dict(kind='nburst', src=0, tgt=2, at=2.41, seed=94)],
         marks=[mark('n_core', ['crystal'], 1.1, until=2.05), mark('n_cold', ['flake', 'shard'], 0, until=2.6, unit=1),
                mark('n_cold', ['flake', 'shard'], 0, until=2.6, unit=2)],
         values=dict(hp=[dict(unit=0, at=2.0, value=.4)]),
         texts=[hit(1, 2.6, '-1310'), hit(2, 2.66, '-1310')]),
    dict(id='fiddle', title='费德提克 · 夺魂虹吸', dur=2.0,
         note='夺魂虹吸：两条摇曳的紫色魂索连到前排及其后方敌人，绿色魂光沿索流回，目标身上冒出淡淡黑烟和飘落的鸦羽；随后两缕魂光从被吸取的敌人处弧线飞回费德提克（回复）。',
         units=[unit('A_1218_6', 1, (240, 580), label='费德提克')] + enemies((240, 300), (196, 214)),
         fx=[dict(kind='fdrain', src=0, tgt=1, at=.1, seed=101), dict(kind='fdrain', src=0, tgt=2, at=.18, seed=102),
             dict(kind='fsoul', src=1, tgt=0, at=.4, seed=103), dict(kind='fsoul', src=2, tgt=0, at=.46, seed=104)],
         texts=[hit(1, .35, '-1520'), hit(2, .43, '-1520'), hit(0, .9, '+1060', GREEN)]),
    dict(id='fiddle_ult', title='费德提克 · 群鸦夜宴（潜伏惊惧）', dur=3.8,
         note='群鸦夜宴：费德提克脚下黑烟翻涌、身前一双黄绿色的眼睛睁开，鸦群从他身上涌出沿路飞去；每个敌人面前也睁开一双眼睛，乌鸦四散，头顶星星旋转（恐惧）。潜伏惊惧触发时眼睛更大、乌鸦更多并多一圈黄绿光环。鸦群期间三只小乌鸦绕着他盘旋；之后每次行动开始，三只乌鸦俯冲啄击每个敌人。鸦群中击杀英雄时鸦羽回旋成一圈暗色护盾。',
         units=[unit('A_1218_6', 1, (240, 600), label='费德提克')] + enemies(*E3),
         fx=[dict(kind='fswarm', src=0, tgt=1, at=.1, seed=111)]
         + [dict(kind='ffear2', src=0, tgt=i, at=.25 + (i - 1) * .07, seed=111 + i) for i in (1, 2, 3)]
         + [dict(kind='fpeck', src=0, tgt=i, at=2.3 + (i - 1) * .08, seed=115 + i) for i in (1, 2)]
         + [dict(kind='fguard', src=0, tgt=0, at=2.9, seed=119)],
         marks=[mark('f_crows', ['crow'] * 3, 1.6)],
         texts=[hit(1, .55, '-2600'), hit(2, .62, '-2600'), hit(3, .69, '-2600'), hit(1, 2.75, '-1730'), hit(2, 2.83, '-1730')]),
    dict(id='annie', title='安妮·新春 · 迎春爆竹 / 瑞兽迎春（召唤）', dur=3.6,
         note='迎春爆竹：一枚点着引线的红爆竹翻滚着抛向前排，接连三声噼啪炸响，红纸屑和金火花四溅，相邻敌人也挨一小响。瑞兽迎春：提伯斯以舞狮狮头的样子在红金彩屑中登场，金环和烟花火星散开；随后提伯斯一跺脚，红金冲击波扩散，本路每个敌人身上金币火花迸溅（眩晕前排）。提伯斯脚下常驻一圈淡金色光环。',
         units=[unit('A_1221_6', 1, (200, 590), label='安妮·新春'), unit('A_2020_6', 1, OFF)] + enemies((240, 300), (196, 214)),
         moves=[appear(1, 1.3, 300, 520)],
         fx=[dict(kind='ecracker', src=0, tgt=2, at=.1, seed=121), dict(kind='epop', src=0, tgt=3, at=.22, seed=122),
             dict(kind='elion', src=0, tgt=1, at=1.3, seed=123), dict(kind='eroar', src=1, tgt=2, at=2.05, seed=124),
             dict(kind='eslam', src=1, tgt=2, at=2.1, seed=125), dict(kind='eslam', src=1, tgt=3, at=2.16, seed=126)],
         marks=[mark('e_summon', ['ring'], 2.6, unit=1)],
         texts=[hit(2, .5, '-1420'), hit(3, .55, '-640'), hit(2, 2.2, '-1290'), hit(3, 2.26, '-1290')]),
    dict(id='annie_bear', title='安妮·新春 · 治疗提伯斯 / 团圆相伴', dur=3.4,
         note='已有提伯斯时：提伯斯身上升起金色光点和一枚小爆竹（治疗），随后同样跺脚重击。命令在身：提伯斯身侧挂着一枚轻轻摆动的小爆竹，下次普攻化作三道火焰爪痕。团圆相伴：提伯斯每成长一次脚下多一颗金色小珠；安妮受击时身上亮起红金灯笼光（护盾）。',
         units=[unit('A_1221_6', 1, (200, 600), label='安妮·新春'), unit('A_2020_6', 1, (300, 520))] + enemies((240, 300), (196, 214)),
         fx=[dict(kind='efeast', src=0, tgt=1, at=.1, seed=131), dict(kind='eroar', src=1, tgt=2, at=.4, seed=132),
             dict(kind='eslam', src=1, tgt=2, at=.45, seed=133), dict(kind='eslam', src=1, tgt=3, at=.51, seed=134),
             dict(kind='ecommand', src=1, tgt=2, at=1.9, seed=135), dict(kind='egrow', src=1, tgt=1, at=2.3, seed=136),
             dict(kind='eguard', src=0, tgt=0, at=2.7, seed=137)],
         marks=[mark('e_command', ['cracker'], 1.0, until=1.9, unit=1), mark('e_summon', ['ring'], 0, unit=1),
                mark('e_bear', ['ring', 'dot', 'dot'], 0, until=2.4, unit=1, count=2),
                mark('e_bear', ['ring', 'dot', 'dot', 'dot'], 2.4, unit=1, count=3)],
         texts=[hit(1, .3, '+2400', GREEN), hit(2, .6, '-1290'), hit(3, .66, '-1290'), hit(2, 2.05, '-780'), hit(0, 2.8, '-410')]),
    dict(id='ekko', title='艾克 · 时光交错刃 / Z型驱动共振', dur=2.6,
         note='时光交错刃：卷曲器带着两道残影旋转飞出命中前排，越过目标后折返，再次穿过目标飞回艾克手中。每层共振在目标脚下化作一颗环绕的青色小光珠（最多三颗）。三层时三颗光珠螺旋收进目标体内，一面钟盘闪现后炸开（引爆）；艾克身上浮起一层时间泡泡（护盾）。',
         units=[unit('A_1140_6', 1, (240, 570), label='艾克')] + enemies((240, 300)),
         fx=[dict(kind='kblade', src=0, tgt=1, at=.1, seed=141), dict(kind='kback', src=0, tgt=1, at=.48, seed=142),
             dict(kind='kpop', src=0, tgt=1, at=.63, seed=143), dict(kind='kbubble', src=0, tgt=0, at=.75, seed=144)],
         marks=[mark('k_res', ['dot'], 0, until=.32, unit=1), mark('k_res', ['dot', 'dot'], .32, until=.63, unit=1)],
         texts=[hit(1, .32, '-760'), hit(1, .63, '-760'), hit(1, .92, '-980')]),
    dict(id='ekko_ult', title='艾克 · 时空断裂', dur=3.6,
         note='残影：上一次行动开始的位置常驻一面淡青色钟盘（地面）。时空断裂：艾克原地碎成青色光屑消失，残影处钟盘逆时针飞转、两圈光环向内收拢，艾克从中走出；时间光点倒流回身上（回复）；本路前两名敌人身上各炸开一圈时间波纹与钟盘（伤害）。之后身边常驻一枚绕行的卷曲器（相位打击就绪），下一次小技能先由一道紫色残影斩一刀。',
         units=[unit('A_1140_6', 1, (240, 470), label='艾克')] + enemies((240, 300), (196, 214)),
         moves=[dict(unit=0, at=.3, len=.05, x=240, y=620)],
         fx=[dict(kind='kfade', src=0, tgt=0, at=.05, seed=151, gx=240, gy=470),
             dict(kind='karrive', src=0, tgt=0, at=.15, seed=152, gx=240, gy=620),
             dict(kind='kmend', src=0, tgt=0, at=.6, seed=153),
             dict(kind='kchrono', src=0, tgt=1, at=.6, seed=154), dict(kind='kchrono', src=0, tgt=2, at=.68, seed=155),
             dict(kind='kphase', src=0, tgt=1, at=2.4, seed=156), dict(kind='kblade', src=0, tgt=1, at=2.62, seed=157)],
         marks=[mark('k_record', ['dial'], 0, until=.3, points=[(240, 620)]), mark('k_phase', ['disc'], 1.4, until=2.4)],
         texts=[hit(0, .8, '+1640', GREEN), hit(1, .8, '-3010'), hit(2, .88, '-3010'), hit(1, 2.55, '-860'), hit(1, 2.84, '-1010')]),
]
ART = sorted({u['art'] for s in SCENES for u in s['units']})
SWFS = ['hero_A.swf', 'hero_B.swf', 'hero_C.swf']


def run(cmd, **kw):
    print('>', ' '.join(str(c) for c in cmd[:4]), '...')
    subprocess.run([str(c) for c in cmd], check=True, **kw)


def export_art(dest):
    """Pull the chibi art out of the hero SWFs the first time."""
    dest.mkdir(parents=True, exist_ok=True)
    for swf in SWFS:
        missing = [name for name in ART if not (dest / f'{name}.png').exists()]
        if not missing:
            return
        temp = dest / '_export'
        shutil.rmtree(temp, ignore_errors=True)
        run([TOOLS / 'java/bin/java.exe', '-jar', TOOLS / 'ffdec/ffdec.jar', '-cli', '-selectclass', ','.join(missing),
             '-format', 'sprite:png', '-export', 'sprite', temp, ROOT / 'client/resources/app/assets/swfs' / swf])
        for name in missing:
            found = next(temp.glob(f'*_{name}/1.png'), None)
            if found:
                shutil.copy(found, dest / f'{name}.png')
        shutil.rmtree(temp, ignore_errors=True)


def block(path, marks):
    code = path.read_text('utf-8')
    return code[code.index(marks[0]):code.index(marks[1]) + len(marks[1])]


def textures():
    code = block(ROOT / 'client/src/hero_fx_d_106.aspart', PURE)
    table = code[code.index('function hfxDSize106'):code.index('function heroFxPaintD106')]
    return re.findall(r'case "(\w+)": return \[', table)


# Persistent marks through hfxDPose106, scaled from the texture as heroFxAnimateD106 does;
# a lane-span mark (points) uses the core's .45 size and its own points.
MARKS = '''            for each(var mark:Object in scene.marks || [])
            {
               if(t<Number(mark.at) || (mark.until!=undefined && t>Number(mark.until))) continue;
               var spots:Array=mark.points ? mark.points : [unitAt(scene,mark.unit,t)];
               var parts:int=mark.points ? spots.length : mark.ids.length;
               for(var mi:int=0;mi<parts;mi++)
               {
                  var mat:Array=mark.points ? spots[mi] : spots[0];
                  var pose:Array=hfxDPose106(String(mark.kind),mi,mark.count!=undefined ? int(mark.count) : int(mark.ids.length),t,int(mark.unit)+1);
                  var mt:BitmapData=texture(String(mark.ids[mi%mark.ids.length]));
                  var base:Number=96/Math.max(mt.width,mt.height)*(mark.points && spots.length>1 ? .45 : .65);
                  var mm:Matrix=new Matrix();
                  mm.translate(-mt.width/2,-mt.height/2);mm.scale(base*pose[2],base*pose[3]);mm.rotate(pose[4]);
                  if(mark.points) mm.translate(mat[0],mat[1]);else mm.translate(mat[0]+pose[0],mat[1]+pose[1]);
                  var mc:uint=uint(pose[6]);
                  canvas.draw(mt,mm,new ColorTransform(((mc>>16)&255)/255,((mc>>8)&255)/255,(mc&255)/255,pose[5]),pose[7] ? BlendMode.ADD : BlendMode.NORMAL,null,true);
               }
            }
'''
SHEET = '''         var sheet:BitmapData=new BitmapData(1320,900,false,0x101418);
         var x:Number=10;var y:Number=10;var row:Number=0;
         for each(var id:String in %s)
         {
            var tex:BitmapData=texture(id);
            if(x+tex.width>1310) {x=10;y+=row+14;row=0;}
            var m:Matrix=new Matrix();m.translate(x,y);
            sheet.draw(tex,m,null,BlendMode.NORMAL,null,true);
            x+=tex.width+12;row=Math.max(row,tex.height);
         }
'''


def harness_source():
    code = (ROOT / 'scripts/demonblade_fx_harness.as').read_text('utf-8')
    core = block(ROOT / 'client/src/hero_fx_core_106.aspart', HELPERS) + block(ROOT / 'client/src/hero_fx_d_106.aspart', PURE)

    def swap(old, new):
        nonlocal code
        if old not in code:
            raise ValueError('Harness anchor moved: ' + old[:80])
        code = code.replace(old, new)

    swap('/*CORE*/\n', core)
    swap('DemonFxHarness', 'HeroFxDHarness')
    swap('textures[id]=demonFxPaint105(id);', 'textures[id]=heroFxPaintD106(id);')
    swap('demonFxLife105(fx.kind)', 'heroFxLifeD106(fx.kind)')
    swap('demonFxSprites105(fx.kind,', 'heroFxSpritesD106(fx.kind,')
    # Ground kinds (Chronobreak) aim at a lane point instead of a unit.
    swap('var dst:Array=unitAt(scene,fx.tgt!=undefined ? fx.tgt : fx.src,t);',
         'var dst:Array=fx.gx!=undefined ? [Number(fx.gx),Number(fx.gy)] : unitAt(scene,fx.tgt!=undefined ? fx.tgt : fx.src,t);')
    start = code.index('         var sheet:BitmapData=new BitmapData(1500,300')
    end = code.index('         save(sheet,outDir.resolvePath("textures.png"));')
    code = code[:start] + SHEET % json.dumps(textures()) + code[end:]
    swap('scenes=JSON.parse(String(event.arguments[2])) as Array;',
         'var sceneFile:FileStream=new FileStream();sceneFile.open(new File(String(event.arguments[2])),FileMode.READ);'
         'scenes=JSON.parse(sceneFile.readUTFBytes(sceneFile.bytesAvailable)) as Array;sceneFile.close();')
    swap('            for each(var fx:Object in scene.fx)\n', MARKS + '            for each(var fx:Object in scene.fx)\n')
    return code


def render(out, art, scenes):
    build = out / '_build'
    shutil.rmtree(build, ignore_errors=True)
    build.mkdir(parents=True)
    (build / 'HeroFxDHarness.as').write_text(harness_source(), encoding='utf-8')
    sdk = TOOLS / 'air-sdk'
    run([TOOLS / 'java/bin/java.exe', '-Xmx512m', '-Duser.language=en', f'-Dflexlib={sdk / "frameworks"}', '-jar', sdk / 'lib/mxmlc-cli.jar',
         '+configname=air', '-output', build / 'harness.swf', '-default-size', '480', '720',
         f'-source-path={build}', '--', build / 'HeroFxDHarness.as'])
    (build / 'app.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n<application xmlns="http://ns.adobe.com/air/application/51.4">'
        '<id>herofx.d.preview</id><filename>HeroFxDPreview</filename><versionNumber>1.0.0</versionNumber>'
        '<initialWindow><content>harness.swf</content><visible>false</visible></initialWindow></application>\n',
        encoding='utf-8')
    # The harness reads hp changes as scene["hp"]; scenes keep them under "values" for readability.
    rows = []
    for scene in scenes:
        row = dict(scene)
        for key, changes in row.pop('values', {}).items():
            row[key] = changes
        rows.append(row)
    (build / 'scenes.json').write_text(json.dumps(rows, ensure_ascii=False), encoding='utf-8')
    run([sdk / 'bin/adl.exe', build / 'app.xml', build, '--', out, art, build / 'scenes.json'], timeout=1800)


def encode(out, scenes):
    ffmpeg = next((TOOLS / 'pythonlibs/imageio_ffmpeg/binaries').glob('ffmpeg*.exe'))
    for scene in scenes:
        frames = out / scene['id']
        run([ffmpeg, '-loglevel', 'error', '-y', '-framerate', 30, '-i', frames / '%04d.png',
             '-c:v', 'libvpx-vp9', '-b:v', '0', '-crf', 28, '-pix_fmt', 'yuv420p', out / f"{scene['id']}.webm"])
        # Every fifth frame, for reviewing the timing at a glance.
        run([ffmpeg, '-loglevel', 'error', '-y', '-i', frames / '%04d.png', '-vf',
             "select='not(mod(n\\,5))',scale=160:-1,tile=12x2", '-frames:v', 1, out / f"{scene['id']}-strip.png"])


def index(out, scenes):
    cards = ''.join(
        f'<article><h2>{s["title"]}</h2><video src="{s["id"]}.webm" autoplay loop muted playsinline></video>'
        f'<p>{s["note"]}</p></article>' for s in scenes)
    (out / 'index.html').write_text(f'''<!doctype html><html lang="zh"><meta charset="utf-8">
<title>英雄特效 · D 组</title><style>
body{{margin:0;background:#0f1214;color:#e8efe9;font:15px "Microsoft YaHei",sans-serif}}
main{{max-width:1600px;margin:24px auto;padding:0 20px}}h1{{font-size:26px;color:#9fe8c8;margin:0 0 6px}}
.lead{{color:#b8c6be;margin:0 0 20px;line-height:1.7}}
.grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:18px}}
article{{background:#181e1f;border:1px solid #2c3a36;border-radius:10px;padding:12px}}
h2{{font-size:17px;margin:0 0 8px;color:#d8ffe8}}video{{width:100%;border-radius:6px;display:block;background:#000}}
article p{{color:#b8c6be;line-height:1.65;font-size:13.5px;margin:10px 0 2px}}
.tex{{margin-top:26px}}.tex img{{width:100%;border-radius:8px;border:1px solid #2c3a36}}
</style><main><h1>英雄特效 · D 组（代码绘制）</h1>
<p class="lead">画面由客户端里同一份特效代码逐帧绘制（AIR 运行），角色卡片、血条和伤害数字只是示意，用来检查遮挡。
盖伦、阿狸·歌姬、锐雯·月兔、艾尼维亚、费德提克、安妮·新春与提伯斯、艾克。尚未在真机或模拟器上播放。</p>
<div class="grid">{cards}</div>
<div class="tex"><h2>代码绘制的 {len(textures())} 张贴图</h2><img src="textures.png"></div></main></html>
''', encoding='utf-8')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', type=Path, default=ROOT / 'build/hero-fx-d-preview')
    parser.add_argument('--art', type=Path)
    parser.add_argument('--only', nargs='*')
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    scenes = [s for s in SCENES if not args.only or s['id'] in args.only]
    art = (args.art or out / 'art').resolve()
    export_art(art)
    render(out, art, scenes)
    encode(out, scenes)
    index(out, scenes)
    print('Preview:', out / 'index.html')


if __name__ == '__main__':
    sys.exit(main())
