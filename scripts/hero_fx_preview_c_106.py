"""Render group C's code-painted hero effects with the game's own effect code.

The core helpers (hero_fx_core_106.aspart) and group C's pure block (hero_fx_c_106.aspart)
are pasted into the Demonblade AIR harness (scripts/demonblade_fx_harness.as, adapted
here), compiled with mxmlc and run with adl. Every frame draws the exact sprite list the
game hands to Starling, plus the persistent marks through the same pose function; ffmpeg
turns the frames into looping videos and contact strips with an index page.

    python scripts/hero_fx_preview_c_106.py [--out DIR] [--only SCENE ...]
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
PURE = ('      // BEGIN HFX C PURE 106\n', '      // END HFX C PURE 106\n')
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


E3 = [(240, 300), (196, 214), (288, 150)]
SCENES = [
    dict(id='vayne', title='暗影薇恩 · 普攻与暗影翻滚', dur=2.3,
         note='普攻是一支紫黑弩箭，尾焰带暗烟，命中钉住片刻后化烟。暗影翻滚：向后翻滚 500 码，原位置留下渐隐的暗影残影与飘落的羽毛，随后三支银紫弩箭微微散开连射，命中处闪出银色交叉。',
         units=[unit('A_1223_6', 1, (240, 560), label='暗影薇恩')] + enemies(*E3),
         moves=[dict(unit=0, at=1.0, len=.2, x=240, y=650)],
         fx=[dict(kind='vbolt', src=0, tgt=1, at=.1, seed=11),
             dict(kind='vtumble', src=0, tgt=1, at=1.2, seed=12, frozen=True),
             dict(kind='vcombo', src=0, tgt=1, at=1.22, seed=13), dict(kind='vcombo', src=0, tgt=1, at=1.37, seed=14),
             dict(kind='vcombo', src=0, tgt=1, at=1.52, seed=15)],
         texts=[hit(1, .35, '-1260'), hit(1, 1.45, '-980'), hit(1, 1.6, '-980'), hit(1, 1.75, '-980')]),
    dict(id='vayne_ult', title='暗影薇恩 · 终极时刻 / 击杀分身', dur=2.6,
         note='终极时刻：脚下暗紫法阵与黑烟，身后五羽一侧的暗影羽翼展开并缓慢扇动，眼前一点银光。击杀分身：黑烟中走出暗影分身，羽毛四散；分身脚下常驻一圈淡紫印记，普攻同样是暗色弩箭。',
         units=[unit('A_1223_6', 1, (240, 560), label='暗影薇恩'), unit('A_1223_5', 1, OFF)] + enemies((240, 300)),
         moves=[appear(1, 1.3, 320, 640)],
         fx=[dict(kind='vult', src=0, at=.1, seed=21), dict(kind='vsummon', src=0, tgt=1, at=1.3, seed=22),
             dict(kind='vbolt', src=1, tgt=2, at=2.0, seed=23)],
         marks=[dict(kind='s_vayne', unit=1, ids=['sigil'], at=1.6)],
         texts=[hit(2, 2.25, '-640')]),
    dict(id='white_curse', title='白娘子 · 咒术青蛇', dur=2.4,
         note='普攻是一团带小白蛇的水珠。咒术青蛇：漩涡中一条青蛇盘起现身（召唤）；随后青蛇蜿蜒游向最前排敌人，上下两颗毒牙咬合，脚下留下诅咒符阵与滴落的毒液。青蛇脚下常驻淡青印记。',
         units=[unit('A_1227_6', 1, (240, 560), label='白娘子'), unit('A_2025_6', 1, OFF)] + enemies((240, 300), (196, 214)),
         moves=[appear(1, .6, 315, 640)],
         fx=[dict(kind='wspit', src=0, tgt=2, at=.1, seed=31), dict(kind='wsnake', src=0, tgt=1, at=.6, seed=32),
             dict(kind='wcurse', src=0, tgt=2, at=1.3, seed=33)],
         marks=[dict(kind='s_snake', unit=1, ids=['sigil'], at=1.1)],
         texts=[hit(2, .38, '-820'), hit(2, 1.7, '-2130')]),
    dict(id='white_flood', title='白娘子 · 水漫金山（白蛇覆水）', dur=2.7,
         note='大招：白娘子脚下起漩涡，一道与分路同宽的浪头卷起，白蛇骑在浪尖上，沿本路冲过所有敌人，所到之处溅起水花；友军身上升起水滴回血。青蛇在场时随后追咬被诅咒的敌人，友军裹上一层水膜护盾。',
         units=[unit('A_1227_6', 1, (240, 610), label='白娘子'), unit('A_2025_6', 1, (315, 670)), unit('A_1212_6', 1, (165, 670))]
         + enemies((240, 330), (196, 245), (288, 170)),
         fx=[dict(kind='wflood', src=0, tgt=3, at=.1, seed=41, frozen=True),
             dict(kind='wsplash', src=0, tgt=3, at=.82, seed=42), dict(kind='wsplash', src=0, tgt=4, at=.98, seed=43),
             dict(kind='wsplash', src=0, tgt=5, at=1.15, seed=44),
             dict(kind='wheal', src=0, tgt=0, at=.45, seed=45), dict(kind='wheal', src=0, tgt=1, at=.5, seed=46),
             dict(kind='wheal', src=0, tgt=2, at=.55, seed=47),
             dict(kind='wsnakebite', src=1, tgt=3, at=1.05, seed=48), dict(kind='wsnakebite', src=1, tgt=4, at=1.1, seed=49),
             dict(kind='wshield', src=0, tgt=0, at=1.0, seed=50), dict(kind='wshield', src=0, tgt=2, at=1.05, seed=51)],
         texts=[hit(3, .85, '-2460'), hit(4, 1.0, '-2460'), hit(5, 1.15, '-2460'), hit(0, .5, '+1050', GREEN),
                hit(3, 1.35, '-1170'), hit(4, 1.4, '-1170')]),
    dict(id='white_shatter', title='白娘子 · 红尘破碎 / 青蛇 · 双生毒牙与三生相伴', dur=3.0,
         note='红尘破碎：一根红线在残血敌人身上结成心形，收紧后崩断，碎成小红心飞散。双生毒牙：两颗毒牙从两侧弧线飞入咬合，诅咒符阵、真伤咬击与毒泡依次出现。三生相伴：一青一白两条小蛇绕着友军盘旋上升（净化），随后水滴回血。',
         units=[unit('A_1227_6', 1, (200, 600), label='白娘子'), unit('A_2025_6', 1, (300, 600)), unit('A_1212_6', 1, (250, 680))]
         + enemies((240, 300), (196, 214)),
         fx=[dict(kind='wshatter', src=0, tgt=4, at=.1, seed=61),
             dict(kind='gfang', src=1, tgt=3, at=1.0, seed=62), dict(kind='gbite', src=1, tgt=3, at=1.4, seed=63),
             dict(kind='gvenom', src=1, tgt=3, at=1.55, seed=64),
             dict(kind='gcleanse', src=1, tgt=1, at=2.0, seed=65), dict(kind='gcleanse', src=1, tgt=0, at=2.06, seed=66),
             dict(kind='gcleanse', src=1, tgt=2, at=2.12, seed=67), dict(kind='gheal', src=1, tgt=0, at=2.5, seed=68)],
         marks=[dict(kind='s_snake', unit=1, ids=['sigil'], at=0)],
         texts=[hit(4, .6, '-3600'), hit(3, 1.45, '-1890'), hit(0, 2.55, '+930', GREEN)]),
    dict(id='teemo_laser', title='超人提莫 · X视线', dur=2.0,
         note='普攻是一道短促的红色热视线。X视线：双眼亮起，两道平行激光同时锁定全场血量最低的三个目标并灼烧，命中点有橙白焦点、火花和余烟；随后的真实伤害打出一团橙色爆燃。',
         units=[unit('A_1309_6', 1, (240, 590), label='超人提莫')] + enemies(*E3),
         fx=[dict(kind='tblip', src=0, tgt=1, at=.1, seed=71)]
         + [dict(kind='tlaser', src=0, tgt=i, at=.6 + (i - 1) * .06, seed=72 + i) for i in (1, 2, 3)]
         + [dict(kind='tburn', src=0, tgt=i, at=1.05 + (i - 1) * .06, seed=76 + i) for i in (1, 2, 3)],
         texts=[hit(1, .25, '-520'), hit(1, 1.1, '-1740'), hit(2, 1.16, '-1740'), hit(3, 1.22, '-1740')]),
    dict(id='teemo_buddy', title='超人提莫 · 超人伙伴 / 超人之身 / 蘑菇', dur=3.4,
         note='超人伙伴：一颗蘑菇带着蓝色拖影从天而降、落地弹一下，星星和孢子溅开；全路友军脚下印出金色英雄徽记和蓝色光环（神佑+护盾）。超人之身：披风在身侧展开飘动，蓝色速度线上升，脚下徽记落定。蘑菇：普攻是一串孢子，技能时喷出一团孢子云，友军头顶落下孢子回血。',
         units=[unit('A_1309_6', 1, (240, 570), label='超人提莫'), unit('A_2018_2', 1, OFF), unit('A_1212_6', 1, (165, 650))]
         + enemies((240, 290)),
         moves=[appear(1, .1, 315, 660)],
         fx=[dict(kind='tsummon', src=0, tgt=1, at=.1, seed=81),
             dict(kind='tbless', src=0, tgt=0, at=.45, seed=82), dict(kind='tbless', src=0, tgt=2, at=.5, seed=83),
             dict(kind='tbless', src=0, tgt=1, at=.55, seed=84),
             dict(kind='tsuper', src=0, at=1.4, seed=85), dict(kind='tbless', src=0, tgt=2, at=1.45, seed=86),
             dict(kind='mpuff', src=1, at=2.4, seed=87), dict(kind='mheal', src=1, tgt=0, at=2.55, seed=88),
             dict(kind='mheal', src=1, tgt=2, at=2.6, seed=89), dict(kind='mspore', src=1, tgt=3, at=2.9, seed=90)],
         marks=[dict(kind='s_mush', unit=1, ids=['sigil'], at=.6)],
         texts=[hit(0, 2.6, '+640', GREEN), hit(2, 2.65, '+640', GREEN), hit(3, 3.2, '-310')]),
    dict(id='kassadin', title='卡萨丁 · 虚无黑洞 / 虚空法王 / 虚空行走', dur=3.6,
         note='普攻是一颗带两粒青色卫星的虚空球。虚无黑洞：目标脚下张开一个黑洞，下方符阵旋转，光屑螺旋着被吸进去，最后坍缩爆开（沉默）。虚空法王：脚下符阵转动，一圈虚空碎片如王冠般升起。虚空行走：身旁撕开一道裂隙，分身从另一道裂隙中走出；分身脚下常驻淡紫印记。',
         units=[unit('A_1134_6', 1, (240, 560), label='卡萨丁'), unit('A_1134_5', 1, OFF)] + enemies((240, 300), (196, 214)),
         moves=[appear(1, 2.75, 315, 645)],
         fx=[dict(kind='kbolt', src=0, tgt=2, at=.1, seed=91), dict(kind='khole', src=0, tgt=2, at=.7, seed=92),
             dict(kind='kking', src=0, at=1.6, seed=93), dict(kind='kwalk', src=0, tgt=1, at=2.4, seed=94)],
         marks=[dict(kind='s_kass', unit=1, ids=['sigil'], at=3.1)],
         texts=[hit(2, .4, '-700'), hit(2, 1.0, '-1650')]),
    dict(id='yasuo_tempest', title='源计划亚索 · 脉冲斩钢（第三段旋风击飞）', dur=2.9,
         note='前两段：一道青色霓虹直刺加一记横斩，红色火花点缀；亚索身边多一枚环绕的旋风刃（积层）。第三段：每个敌人各被一股旋风沿路卷中并击飞，脚下风涡转动；被击飞的敌人身下常驻淡青小龙卷，亚索获得浪客协议风盾（风刃环绕，常驻淡青光圈）。',
         units=[unit('A_1219_6', 1, (240, 540), label='源计划亚索')] + enemies(*E3),
         fx=[dict(kind='ystrike', src=0, tgt=1, at=.1, seed=101), dict(kind='ystrike', src=0, tgt=1, at=.8, seed=102)]
         + [dict(kind='ywhirl', src=0, tgt=i, at=1.5, seed=102 + i) for i in (1, 2, 3)]
         + [dict(kind='yair', src=0, tgt=i, at=1.8, seed=106 + i) for i in (1, 2, 3)]
         + [dict(kind='yguard', src=0, at=1.55, seed=110)],
         marks=[dict(kind='y_wind', unit=0, ids=['crescent'], at=.3, until=.95),
                dict(kind='y_wind', unit=0, ids=['crescent', 'crescent'], at=.95, until=1.5),
                dict(kind='y_guard', unit=0, ids=['ring'], at=1.9)]
         + [dict(kind='y_air', unit=i, ids=['tornado', 'whirl'], at=2.3) for i in (1, 2, 3)],
         texts=[hit(1, .25, '-1530'), hit(1, .95, '-1530'), hit(1, 1.9, '-1280'), hit(2, 1.9, '-1280'), hit(3, 1.9, '-1280')]),
    dict(id='yasuo_ult', title='源计划亚索 · 超载绝息（空中连斩）', dur=2.4,
         note='亚索闪到被击飞的目标身边：第一斩带青红残影突进并在目标身下卷起龙卷，三道空中斩分别为斜劈、反斜劈和横斩，第三斩把目标砸回地面，青红双环和尘烟炸开。同路每个击飞目标依次挨三斩。',
         units=[unit('A_1219_6', 1, (240, 560), label='源计划亚索')] + enemies((240, 280), (196, 214)),
         moves=[dict(unit=0, at=.05, len=.15, x=240, y=380)],
         fx=[dict(kind='yult0', src=0, tgt=1, at=.05, seed=111, frozen=True), dict(kind='yult1', src=0, tgt=1, at=.3, seed=112),
             dict(kind='yult2', src=0, tgt=1, at=.55, seed=113), dict(kind='yult0', src=0, tgt=2, at=.85, seed=114),
             dict(kind='yult1', src=0, tgt=2, at=1.1, seed=115), dict(kind='yult2', src=0, tgt=2, at=1.35, seed=116)],
         marks=[dict(kind='y_air', unit=1, ids=['tornado', 'whirl'], at=0, until=.8),
                dict(kind='y_air', unit=2, ids=['tornado', 'whirl'], at=0, until=1.6)],
         texts=[hit(1, .2, '-1150'), hit(1, .45, '-1150'), hit(1, .7, '-1150'), hit(2, 1.0, '-1150'), hit(2, 1.25, '-1150'),
                hit(2, 1.5, '-1150')]),
    dict(id='zongzi', title='粽子少女 · 召唤粽子 / 粽子飘香 / 粽香余韵', dur=3.6,
         note='普攻扔出一颗翻滚的粽子，落地迸出粽叶和米粒。召唤粽子：粽子从天而降、落地压扁再弹起，冒出热气。粽子飘香：热气与粽叶在身边盘旋外扩，米粒升起，每个友军身上冒出米香热气回血。粽香余韵（击杀触发）：粽叶裹住友军收拢，红绳火花一闪（神佑+净化）；两片粽叶交叉划过每个敌人（真伤）。',
         units=[unit('A_1212_6', 1, (240, 560), label='粽子少女'), unit('A_2014_5', 1, OFF), unit('A_1227_6', 1, (165, 650))]
         + enemies((240, 300), (196, 214)),
         moves=[appear(1, .35, 315, 650)],
         fx=[dict(kind='zsummon', src=0, tgt=1, at=.1, seed=121), dict(kind='zthrow', src=0, tgt=3, at=.6, seed=122),
             dict(kind='zaroma', src=0, at=1.2, seed=123), dict(kind='zheal', src=0, tgt=0, at=1.3, seed=124),
             dict(kind='zheal', src=0, tgt=1, at=1.36, seed=125), dict(kind='zheal', src=0, tgt=2, at=1.42, seed=126),
             dict(kind='zbless', src=0, tgt=0, at=2.6, seed=127), dict(kind='zbless', src=0, tgt=2, at=2.66, seed=128),
             dict(kind='zleaf', src=0, tgt=3, at=2.75, seed=129), dict(kind='zleaf', src=0, tgt=4, at=2.81, seed=130),
             dict(kind='zthrow', src=1, tgt=3, at=3.0, seed=131)],
         marks=[dict(kind='s_zongzi', unit=1, ids=['sigil'], at=.7)],
         texts=[hit(3, .95, '-860'), hit(0, 1.4, '+720', GREEN), hit(2, 1.45, '+720', GREEN), hit(3, 2.9, '-105'), hit(4, 2.95, '-105')]),
    dict(id='ezreal_wave', title='动感伊泽 · 动感光波', dur=2.5,
         note='普攻是一发霓虹光弹，尾随一个音符。动感光波：每个敌人头顶打下一束彩色追光并落下音符（诅咒），三圈彩色声波沿路推进，命中处跳起一排均衡器光柱；随后伊泽脚下一排均衡器随节拍跳动，音符升起（自疗）。',
         units=[unit('A_1222_6', 1, (240, 570), label='动感伊泽')] + enemies(*E3),
         fx=[dict(kind='ebolt', src=0, tgt=1, at=.1, seed=141)]
         + [dict(kind='estage', src=0, tgt=i, at=.6 + (i - 1) * .06, seed=141 + i) for i in (1, 2, 3)]
         + [dict(kind='ewave', src=0, tgt=i, at=.8 + (i - 1) * .06, seed=144 + i) for i in (1, 2, 3)]
         + [dict(kind='egroove', src=0, at=1.35, seed=149)],
         texts=[hit(1, .35, '-610'), hit(1, 1.15, '-2050'), hit(2, 1.2, '-2050'), hit(3, 1.25, '-2050'), hit(0, 1.5, '+1380', GREEN)]),
    dict(id='ezreal_ult', title='动感伊泽 · 深藏身与名 / 绝境翻盘', dur=3.3,
         note='深藏身与名：目标头顶高处降下一颗镜面迪斯科球（在血条与伤害数字之上），向四周甩出彩色光束；五发旋转星弹左右交替弧线飞入，第五发炸出一圈音符。绝境翻盘：一束金色追光照在伊泽身上，星光升起，脚下光柱跳动（净化+暴击）。',
         units=[unit('A_1222_6', 1, (240, 570), label='动感伊泽')] + enemies((240, 300), (196, 214)),
         fx=[dict(kind=f'estar{i}', src=0, tgt=1, at=.1 + i * .22, seed=151 + i) for i in range(5)]
         + [dict(kind='ecomeback', src=0, at=1.9, seed=158)],
         texts=[hit(1, .3 + i * .22, '-1450', GOLD if i == 2 else WHITE, 26 if i == 2 else None) for i in range(5)]),
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
    code = block(ROOT / 'client/src/hero_fx_c_106.aspart', PURE)
    table = code[code.index('function hfxCSize106'):code.index('function heroFxPaintC106')]
    return re.findall(r'case "(\w+)": return \[', table)


MARKS = '''            for each(var mark:Object in scene.marks || [])
            {
               if(t<Number(mark.at) || (mark.until!=undefined && t>Number(mark.until))) continue;
               var mat:Array=unitAt(scene,mark.unit,t);
               for(var mi:int=0;mi<mark.ids.length;mi++)
               {
                  var pose:Array=hfxCPose106(String(mark.kind),mi,int(mark.ids.length),t,int(mark.unit)+1);
                  var mt:BitmapData=texture(String(mark.ids[mi]));
                  var base:Number=96/Math.max(mt.width,mt.height)*.65;
                  var mm:Matrix=new Matrix();
                  mm.translate(-mt.width/2,-mt.height/2);mm.scale(base*pose[2],base*pose[3]);mm.rotate(pose[4]);mm.translate(mat[0]+pose[0],mat[1]+pose[1]);
                  var mc:uint=uint(pose[6]);
                  canvas.draw(mt,mm,new ColorTransform(((mc>>16)&255)/255,((mc>>8)&255)/255,(mc&255)/255,pose[5]),pose[7] ? BlendMode.ADD : BlendMode.NORMAL,null,true);
               }
            }
'''
SHEET = '''         var sheet:BitmapData=new BitmapData(1320,1220,false,0x101418);
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
    core = block(ROOT / 'client/src/hero_fx_core_106.aspart', HELPERS) + block(ROOT / 'client/src/hero_fx_c_106.aspart', PURE)

    def swap(old, new):
        nonlocal code
        if old not in code:
            raise ValueError('Harness anchor moved: ' + old[:80])
        code = code.replace(old, new)

    swap('/*CORE*/\n', core)
    swap('DemonFxHarness', 'HeroFxCHarness')
    swap('textures[id]=demonFxPaint105(id);', 'textures[id]=heroFxPaintC106(id);')
    swap('demonFxLife105(fx.kind)', 'heroFxLifeC106(fx.kind)')
    swap('demonFxSprites105(fx.kind,', 'heroFxSpritesC106(fx.kind,')
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
    (build / 'HeroFxCHarness.as').write_text(harness_source(), encoding='utf-8')
    sdk = TOOLS / 'air-sdk'
    run([TOOLS / 'java/bin/java.exe', '-Xmx512m', '-Duser.language=en', f'-Dflexlib={sdk / "frameworks"}', '-jar', sdk / 'lib/mxmlc-cli.jar',
         '+configname=air', '-output', build / 'harness.swf', '-default-size', '480', '720',
         f'-source-path={build}', '--', build / 'HeroFxCHarness.as'])
    (build / 'app.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n<application xmlns="http://ns.adobe.com/air/application/51.4">'
        '<id>herofx.c.preview</id><filename>HeroFxCPreview</filename><versionNumber>1.0.0</versionNumber>'
        '<initialWindow><content>harness.swf</content><visible>false</visible></initialWindow></application>\n',
        encoding='utf-8')
    (build / 'scenes.json').write_text(json.dumps(scenes, ensure_ascii=False), encoding='utf-8')
    run([sdk / 'bin/adl.exe', build / 'app.xml', build, '--', out, art, build / 'scenes.json'], timeout=1800)


def encode(out, scenes):
    ffmpeg = next((TOOLS / 'pythonlibs/imageio_ffmpeg/binaries').glob('ffmpeg*.exe'))
    for scene in scenes:
        frames = out / scene['id']
        run([ffmpeg, '-loglevel', 'error', '-y', '-framerate', 30, '-i', frames / '%04d.png',
             '-c:v', 'libvpx-vp9', '-b:v', '0', '-crf', 28, '-pix_fmt', 'yuv420p', out / f"{scene['id']}.webm"])
        # Every fifth frame, for reviewing the timing at a glance.
        run([ffmpeg, '-loglevel', 'error', '-y', '-i', frames / '%04d.png', '-vf',
             "select='not(mod(n\\,5))',scale=160:-1,tile=10x2", '-frames:v', 1, out / f"{scene['id']}-strip.png"])


def index(out, scenes):
    cards = ''.join(
        f'<article><h2>{s["title"]}</h2><video src="{s["id"]}.webm" autoplay loop muted playsinline></video>'
        f'<p>{s["note"]}</p></article>' for s in scenes)
    (out / 'index.html').write_text(f'''<!doctype html><html lang="zh"><meta charset="utf-8">
<title>英雄特效 · C 组</title><style>
body{{margin:0;background:#0f1214;color:#e8efe9;font:15px "Microsoft YaHei",sans-serif}}
main{{max-width:1600px;margin:24px auto;padding:0 20px}}h1{{font-size:26px;color:#9fe8c8;margin:0 0 6px}}
.lead{{color:#b8c6be;margin:0 0 20px;line-height:1.7}}
.grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:18px}}
article{{background:#181e1f;border:1px solid #2c3a36;border-radius:10px;padding:12px}}
h2{{font-size:17px;margin:0 0 8px;color:#d8ffe8}}video{{width:100%;border-radius:6px;display:block;background:#000}}
article p{{color:#b8c6be;line-height:1.65;font-size:13.5px;margin:10px 0 2px}}
.tex{{margin-top:26px}}.tex img{{width:100%;border-radius:8px;border:1px solid #2c3a36}}
</style><main><h1>英雄特效 · C 组（代码绘制）</h1>
<p class="lead">画面由客户端里同一份特效代码逐帧绘制（AIR 运行），角色卡片、血条和伤害数字只是示意，用来检查遮挡。
暗影薇恩、白娘子与青蛇、超人提莫与蘑菇、卡萨丁、源计划亚索、粽子少女与粽子、动感伊泽。尚未在真机或模拟器上播放。</p>
<div class="grid">{cards}</div>
<div class="tex"><h2>代码绘制的 {len(textures())} 张贴图</h2><img src="textures.png"></div></main></html>
''', encoding='utf-8')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', type=Path, default=ROOT / 'build/hero-fx-c-preview')
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
