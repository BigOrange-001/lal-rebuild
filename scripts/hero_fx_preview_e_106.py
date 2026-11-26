"""Render group E's code-painted hero effects with the game's own effect code.

The core helpers (hero_fx_core_106.aspart) and group E's pure block (hero_fx_e_106.aspart)
are pasted into the Demonblade AIR harness (scripts/demonblade_fx_harness.as, adapted
here), compiled with mxmlc and run with adl. Every frame draws the exact sprite list the
game hands to Starling, plus the persistent marks through the same pose function; ffmpeg
turns the frames into looping videos and contact strips with an index page.

Timing follows the game: a claimed native hit lands HFX_E_HIT106 (.47 s) after its claim,
and the chain's jumps are .12 s apart (Avatar.AOXING_CHAIN_STEP106).

    python scripts/hero_fx_preview_e_106.py [--out DIR] [--only SCENE ...]
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
PURE = ('      // BEGIN HFX E PURE 106\n', '      // END HFX E PURE 106\n')
WHITE, GREEN, GOLD, CYAN, VIOLET = 0xFFFFFF, 0x66FF66, 0xFFD040, 0x7FF6FF, 0xC9A0FF
OFF = (-400, -400)
HIT = .47
STEP = .12


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


def mark(kind, ids, at, until=None, unit=0, count=None):
    row = dict(kind=kind, ids=ids, at=at, unit=unit)
    if until is not None:
        row['until'] = until
    if count is not None:
        row['count'] = count
    return row


def chain(order, start, seed, solo=False):
    """Aurelion Sol's chain as Avatar.aoxingChain106 plays it: one bolt per jump, .12 s apart."""
    fx, last = [], 0
    for hop, target in enumerate(order):
        fx.append(dict(kind='achain3' if solo else 'achain', src=last, tgt=target, at=start + hop * STEP, seed=seed + hop))
        last = target
    return fx


# Five enemies over three lanes: the chain runs down his lane, then jumps to the nearest lane.
SPREAD = [(240, 330), (240, 240), (120, 290), (360, 262), (120, 190)]
CHAIN = [1, 2, 4, 3, 5]
SCENES = [
    dict(id='aoxing_chain', title='熬兴 · 连锁闪电（5 名目标，可跨路）', dur=2.6,
         note='连锁闪电：一道青白闪电从熬兴身上劈到本路最近的敌人，再一跳一跳地劈向离上一个目标最近、本次没打过的敌人，本路打完就跳到相邻分路，共 5 名。每一跳间隔 0.12 秒，电弧锯齿状闪烁、带一道小分叉，命中处炸开蓝色光晕、金色星芒和电火花。命中敌方英雄后头顶多一颗环绕的星星（风暴电荷）。',
         units=[unit('A_1114_6', 1, (240, 600), label='熬兴')] + enemies(*SPREAD),
         fx=chain(CHAIN, .1, 11),
         marks=[mark('a_charge', ['star'], .7, count=1)],
         texts=[hit(t, .1 + HIT + i * STEP, '-1620' if i == 0 else '-1160', CYAN) for i, t in enumerate(CHAIN)]),
    dict(id='aoxing_solo', title='熬兴 · 连锁闪电（场上只剩 1 名敌人，3 倍伤害）', dur=2.0,
         note='场上只有一名敌人时：电弧更粗更亮，天上同时劈下一道紫色闪电，命中处光晕更大，多一圈紫色冲击环和上升的星尘，伤害为首跳的 3 倍。',
         units=[unit('A_1114_6', 1, (240, 600), label='熬兴')] + enemies((240, 260)),
         fx=chain([1], .1, 21, solo=True),
         texts=[hit(1, .1 + HIT, '-4860', CYAN, 28)]),
    dict(id='aoxing_storm', title='熬兴 · 风暴降临（4/5 星）', dur=2.4,
         note='风暴降临：熬兴脚下展开一张旋转的星图，星尘向他聚拢；敌方英雄最多的分路里，每名敌人头顶先亮起一枚紫色小星图，星光汇聚后一道闪电直劈而下，落地炸开光圈、星芒和上升的光点。头顶三颗环绕的电荷星在施放时消耗。',
         units=[unit('A_1114_5', 1, (240, 620), label='熬兴')] + enemies((240, 340), (240, 260), (240, 190), (240, 120)),
         fx=[dict(kind='acast', src=0, tgt=0, at=.2, seed=31)]
         + [dict(kind='astorm', src=0, tgt=i, at=.2 + (i - 1) * .15, seed=31 + i) for i in (1, 2, 3, 4)],
         marks=[mark('a_charge', ['star'] * 3, 0, until=.2, count=3)],
         texts=[hit(i, .2 + HIT + (i - 1) * .15, '-3380', CYAN) for i in (1, 2, 3, 4)]),
    dict(id='aoxing_stand', title='熬兴 · 电荷与站定引导（6 星）', dur=4.6,
         note='每次施放获得一层电荷：电火花旋进他体内、炸开一颗星，头顶环绕的星星多一颗（最多 5 颗）。满 5 层再施放就进入站定引导：脚下星图猛地展开锁定，一道光柱向上升起，星光聚拢；引导期间脚下一直有一张缓缓旋转的星图，腰间三颗星环绕。每次行动开始连放 3 次连锁闪电。风暴龙光环（被动）：一颗流星砸向每名敌人，炸开紫色星爆，目标头顶星星旋转（眩晕）。',
         units=[unit('A_1114_6', 1, (240, 600), label='熬兴')] + enemies((240, 320), (240, 240), (120, 280)),
         fx=[dict(kind='acharge', src=0, tgt=0, at=.1, seed=41), dict(kind='acharge', src=0, tgt=0, at=.6, seed=42),
             dict(kind='astand', src=0, tgt=0, at=1.2, seed=43)]
         + chain([1, 2, 3], 2.2, 44) + chain([1, 2, 3], 2.8, 47)
         + [dict(kind='anova', src=0, tgt=i, at=3.6, seed=50 + i) for i in (1, 2, 3)],
         marks=[mark('a_charge', ['star'] * 4, 0, until=.5, count=4), mark('a_charge', ['star'] * 5, .5, until=1.2, count=5),
                mark('a_stand', ['rune', 'star', 'star', 'star'], 1.3)],
         texts=[hit(1, 2.2 + HIT, '-1840', CYAN), hit(2, 2.2 + HIT + STEP, '-840', CYAN), hit(3, 2.2 + HIT + 2 * STEP, '-840', CYAN),
                hit(1, 2.8 + HIT, '-1840', CYAN), hit(2, 2.8 + HIT + STEP, '-840', CYAN), hit(3, 2.8 + HIT + 2 * STEP, '-840', CYAN),
                hit(1, 4.0, '-2210', GOLD), hit(2, 4.0, '-1980', GOLD), hit(3, 4.0, '-1760', GOLD)]),
    dict(id='shaco', title='恶魔小丑萨科 · 欺诈突袭 / 惊吓魔盒（6 星）', dur=2.8,
         note='欺诈突袭：萨科在紫烟里一闪消失，落到攻击最高的敌人身后，小丑面具在落点咧嘴一笑；头顶弹出面具、眼角闪一道红光（暴击）；两把匕首从两侧交叉刺穿目标，一红一紫两道弧斩、红色火花和一口毒雾（背刺）。6 星时原地留下惊吓魔盒：一团烟后盒子弹开，小丑头顶着弹簧晃出来，绿紫彩屑四散。',
         units=[unit('A_1128_6', 1, (240, 600), label='恶魔小丑萨科')] + enemies((240, 340), (340, 250)) + [unit('A_2019_5', 1, OFF)],
         moves=[dict(unit=0, at=.1, len=.2, x=240, y=230), appear(3, .12, 240, 600)],
         fx=[dict(kind='sblink', src=0, tgt=0, at=.15, seed=61), dict(kind='sbox', src=0, tgt=3, at=.12, seed=62),
             dict(kind='sgrin', src=0, tgt=0, at=.5, seed=63), dict(kind='sstab', src=0, tgt=1, at=.75, seed=64)],
         texts=[hit(1, .75 + HIT, '-3960', GOLD, 26)]),
    dict(id='shaco_ult', title='恶魔小丑萨科 · 幻象分身 / 诅咒匕首', dur=2.8,
         note='幻象分身：一大团紫烟炸开，面具一闪，分身走了出来；萨科本体在紫烟中往后一闪，脚下红紫两圈脉冲、紫色光点上升、面具狂笑般抖动（力量）；接着紫色残影从身上向两侧滑开消散（闪避）。诅咒匕首（6 星被动）：一把旋转的匕首拖着绿色尾迹飞向中了诅咒的敌人，溅开一团绿色毒雾。',
         units=[unit('A_1128_6', 1, (240, 470), label='恶魔小丑萨科'), unit('A_1128_6', 1, OFF)] + enemies((240, 300), (196, 214)),
         moves=[appear(1, .1, 240, 420), dict(unit=0, at=.45, len=.2, x=240, y=650)],
         fx=[dict(kind='sclone', src=0, tgt=1, at=.1, seed=71), dict(kind='sblink', src=0, tgt=0, at=.5, seed=72),
             dict(kind='smad', src=0, tgt=0, at=.8, seed=73), dict(kind='sfade', src=0, tgt=0, at=1.1, seed=74),
             dict(kind='sdagger', src=0, tgt=2, at=1.7, seed=75)],
         texts=[hit(2, 1.7 + HIT, '-1520', GREEN)]),
    dict(id='kayle', title='凯尔 · 圣焰普攻 / 圣焰裁决 / 圣裁之刻', dur=3.4,
         note='普攻：一颗拖着羽毛的圣火球飞向目标，炸成金色火焰。圣焰裁决：敌人头顶天光一开、羽毛飘落，一柄燃烧的巨剑直插下来，火焰冲起、两圈金环扩散，灰色碎甲飞出（破甲）；同时金色羽毛在柔光里落到残血友军身上（治疗）。圣裁之刻：原版金色圣罩之后，凯尔两侧一直收拢着一对呼吸般明暗的金色羽翼（99% 减伤期间）。',
         units=[unit('A_1120_6', 1, (240, 600), label='凯尔'), unit('A_1212_6', 1, (330, 660))] + enemies((240, 300), (196, 214)),
         fx=[dict(kind='kbolt', src=0, tgt=2, at=.1, seed=81), dict(kind='kbolt', src=0, tgt=2, at=.6, seed=82),
             dict(kind='kjudge', src=0, tgt=2, at=1.2, seed=83), dict(kind='kmend', src=0, tgt=1, at=1.75, seed=84)],
         marks=[mark('k_guard', ['wing', 'wing'], 2.3)],
         texts=[hit(2, .1 + HIT, '-980'), hit(2, .6 + HIT, '-980'), hit(2, 1.2 + HIT, '-3420', GOLD, 26), hit(1, 1.75 + .5, '+1460', GREEN)]),
    dict(id='kayle_ascend', title='凯尔 · 登神长阶（第二、三阶段普攻）', dur=2.4,
         note='登神长阶：头顶一圈淡金光环，身后每进一阶多亮一根羽毛（最多 4 根）。第二阶段起普攻改为本路所有敌人：每名敌人头上各落下一柄燃烧的金剑，火焰炸开、金环扩散。',
         units=[unit('A_1120_6', 1, (240, 620), label='凯尔')] + enemies((240, 330), (240, 250), (240, 170)),
         fx=[dict(kind='kwave', src=0, tgt=i, at=.2, seed=90 + i) for i in (1, 2, 3)]
         + [dict(kind='kwave', src=0, tgt=i, at=1.2, seed=94 + i) for i in (1, 2, 3)],
         marks=[mark('k_ascend', ['ring', 'feather', 'feather', 'feather'], 0, count=3)],
         texts=[hit(i, .2 + HIT, '-1840', GOLD) for i in (1, 2, 3)] + [hit(i, 1.2 + HIT, '-1840', GOLD) for i in (1, 2, 3)]),
    dict(id='graves', title='男枪 · 霰弹普攻 / 霰弹轰击', dur=2.8,
         note='普攻：枪口炸出尖刺状火光、喷出一小团硝烟，弹壳翻着跟头抛出；七颗弹丸扇形散开打在目标身上，各自冒出火星和小烟。霰弹轰击：一圈硝烟烟圈从他身上升起、橙色火星飘起（永久攻防加成），随后同样的一枪覆盖目标和附近敌人。之后他肩头一直冒着一缕青烟，腰间一枚弹壳不时反光（硬汉状态）。',
         units=[unit('A_1053_6', 1, (240, 600), label='男枪')] + enemies((240, 330), (140, 250), (340, 250)),
         fx=[dict(kind='gblast', src=0, tgt=1, at=.1, seed=101), dict(kind='ggrit', src=0, tgt=0, at=.8, seed=102),
             dict(kind='gfire', src=0, tgt=1, at=1.5, seed=103)]
         + [dict(kind='gspray', src=0, tgt=i, at=1.5, seed=103 + i) for i in (1, 2, 3)],
         marks=[mark('g_grit', ['smoke', 'shell'], 1.2)],
         texts=[hit(1, .1 + HIT, '-760')] + [hit(i, 1.5 + HIT, '-540') for i in (1, 2, 3)]),
    dict(id='graves_ult', title='男枪 · 终极爆弹 / 快速拔枪（6 星）', dur=2.6,
         note='终极爆弹：一枚大号弹壳带着火光划出弧线砸到前排，炸开橙红火球、两圈冲击环、四散的火星碎片和一大团硝烟；后方两名敌人身上各爆出一团弹片火星。快速拔枪：突进到敌人面前后，枪口火光更大，一道曳光直接打穿目标。',
         units=[unit('A_1053_6', 1, (240, 620), label='男枪')] + enemies((240, 330), (240, 230), (340, 200)),
         moves=[dict(unit=0, at=1.6, len=.2, x=240, y=440)],
         fx=[dict(kind='gshell', src=0, tgt=1, at=.1, seed=111), dict(kind='gfrag', src=0, tgt=2, at=.5, seed=112),
             dict(kind='gfrag', src=0, tgt=3, at=.5, seed=113), dict(kind='gquick', src=0, tgt=1, at=1.85, seed=114)],
         texts=[hit(1, .1 + HIT, '-5680', GOLD, 26), hit(2, .5 + HIT, '-3780'), hit(3, .5 + HIT, '-3780'), hit(1, 1.85 + HIT, '-1260')]),
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
    code = block(ROOT / 'client/src/hero_fx_e_106.aspart', PURE)
    table = code[code.index('function hfxESize106'):code.index('function heroFxPaintE106')]
    return re.findall(r'case "(\w+)": return \[', table)


# Persistent marks through hfxEPose106, scaled from the texture as heroFxAnimateE106 does.
MARKS = '''            for each(var mark:Object in scene.marks || [])
            {
               if(t<Number(mark.at) || (mark.until!=undefined && t>Number(mark.until))) continue;
               var mat:Array=unitAt(scene,mark.unit,t);
               for(var mi:int=0;mi<mark.ids.length;mi++)
               {
                  var pose:Array=hfxEPose106(String(mark.kind),mi,mark.count!=undefined ? int(mark.count) : int(mark.ids.length),t,int(mark.unit)+1);
                  var mt:BitmapData=texture(String(mark.ids[mi]));
                  var base:Number=96/Math.max(mt.width,mt.height)*.65;
                  var mm:Matrix=new Matrix();
                  mm.translate(-mt.width/2,-mt.height/2);mm.scale(base*pose[2],base*pose[3]);mm.rotate(pose[4]);
                  mm.translate(mat[0]+pose[0],mat[1]+pose[1]);
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
    core = block(ROOT / 'client/src/hero_fx_core_106.aspart', HELPERS) + block(ROOT / 'client/src/hero_fx_e_106.aspart', PURE)

    def swap(old, new):
        nonlocal code
        if old not in code:
            raise ValueError('Harness anchor moved: ' + old[:80])
        code = code.replace(old, new)

    swap('/*CORE*/\n', core)
    swap('DemonFxHarness', 'HeroFxEHarness')
    swap('textures[id]=demonFxPaint105(id);', 'textures[id]=heroFxPaintE106(id);')
    swap('demonFxLife105(fx.kind)', 'heroFxLifeE106(fx.kind)')
    swap('demonFxSprites105(fx.kind,', 'heroFxSpritesE106(fx.kind,')
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
    (build / 'HeroFxEHarness.as').write_text(harness_source(), encoding='utf-8')
    sdk = TOOLS / 'air-sdk'
    run([TOOLS / 'java/bin/java.exe', '-Xmx512m', '-Duser.language=en', f'-Dflexlib={sdk / "frameworks"}', '-jar', sdk / 'lib/mxmlc-cli.jar',
         '+configname=air', '-output', build / 'harness.swf', '-default-size', '480', '720',
         f'-source-path={build}', '--', build / 'HeroFxEHarness.as'])
    (build / 'app.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n<application xmlns="http://ns.adobe.com/air/application/51.4">'
        '<id>herofx.e.preview</id><filename>HeroFxEPreview</filename><versionNumber>1.0.0</versionNumber>'
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
             "select='not(mod(n\\,5))',scale=160:-1,tile=12x2", '-frames:v', 1, out / f"{scene['id']}-strip.png"])


def index(out, scenes):
    cards = ''.join(
        f'<article><h2>{s["title"]}</h2><video src="{s["id"]}.webm" autoplay loop muted playsinline></video>'
        f'<p>{s["note"]}</p></article>' for s in scenes)
    (out / 'index.html').write_text(f'''<!doctype html><html lang="zh"><meta charset="utf-8">
<title>英雄特效 · E 组</title><style>
body{{margin:0;background:#0f1214;color:#e8efe9;font:15px "Microsoft YaHei",sans-serif}}
main{{max-width:1600px;margin:24px auto;padding:0 20px}}h1{{font-size:26px;color:#9fe8c8;margin:0 0 6px}}
.lead{{color:#b8c6be;margin:0 0 20px;line-height:1.7}}
.grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:18px}}
article{{background:#181e1f;border:1px solid #2c3a36;border-radius:10px;padding:12px}}
h2{{font-size:17px;margin:0 0 8px;color:#d8ffe8}}video{{width:100%;border-radius:6px;display:block;background:#000}}
article p{{color:#b8c6be;line-height:1.65;font-size:13.5px;margin:10px 0 2px}}
.tex{{margin-top:26px}}.tex img{{width:100%;border-radius:8px;border:1px solid #2c3a36}}
</style><main><h1>英雄特效 · E 组（代码绘制）</h1>
<p class="lead">画面由客户端里同一份特效代码逐帧绘制（AIR 运行），角色卡片、血条和伤害数字只是示意，用来检查遮挡；
伤害数字的时间按游戏里的命中时间摆放。熬兴、恶魔小丑萨科、凯尔、男枪格雷福斯。尚未在真机或模拟器上播放。</p>
<div class="grid">{cards}</div>
<div class="tex"><h2>代码绘制的 {len(textures())} 张贴图</h2><img src="textures.png"></div></main></html>
''', encoding='utf-8')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', type=Path, default=ROOT / 'build/hero-fx-e-preview')
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
