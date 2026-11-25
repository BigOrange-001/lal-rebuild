"""Render Demonblade Tryndamere's skill effects with the game's own effect code.

The effect core in client/src/demonblade_tryndamere_fx.aspart is pasted into a
small AIR harness, compiled with amxmlc and run with adl. The harness draws each
scene frame by frame with the exact sprite list the game hands to Starling, and
ffmpeg turns the frames into looping videos with an index page.

    python scripts/demonblade_fx_preview.py [--out DIR] [--art DIR]
"""
import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT.parent / 'toolchain'
CORE_START = '      // BEGIN DEMON FX CORE 105\n'
CORE_END = '      // END DEMON FX CORE 105\n'
ART = ['A_1028_6', 'A_1004_5', 'A_1001_5', 'A_1002_5', 'A_1005_5']

TRYND, ALLY, FRONT, SECOND, THIRD = range(5)
RED, GOLD, GREEN, WHITE = 0xFF3B1F, 0xFFD040, 0x66FF66, 0xFFFFFF


def units(tryn, ally=None, enemies=(), hp=1.0, rage=.5):
    rows = [dict(art='A_1028_6', team=1, x=tryn[0], y=tryn[1], hp=hp, rage=rage, label='恶魔之刃泰达米尔')]
    rows.append(dict(art='A_1004_5', team=1, x=ally[0], y=ally[1], hp=.85) if ally else
                dict(art='A_1004_5', team=1, x=-200, y=-200, hp=1))
    for art, at in zip(('A_1001_5', 'A_1002_5', 'A_1005_5'), enemies):
        rows.append(dict(art=art, team=2, x=at[0], y=at[1], hp=1))
    return rows


SCENES = [
    dict(id='slash', title='魔刃斩 → 必定暴击的普攻', dur=2.9,
         note='突进到最前排敌人面前，三刃回旋后十字斩收尾，破甲碎片剥落；周围被波及的敌人各挨一刀。之后刀刃上会闪烁寒光，代表下一次普攻必定暴击，暴击时打出金色斜斩。',
         units=units((240, 580), (240, 670), [(240, 300), (196, 214), (288, 150)], hp=.8, rage=.55),
         moves=[dict(unit=TRYND, at=.1, len=.18, x=240, y=405)],
         fx=[dict(kind='slash', src=TRYND, tgt=FRONT, at=.1, frozen=True, seed=11),
             dict(kind='cleave', src=TRYND, tgt=SECOND, at=.1, seed=12),
             dict(kind='cleave', src=TRYND, tgt=THIRD, at=.1, seed=13),
             dict(kind='edge', src=TRYND, at=1.0, stop=1.95, seed=14),
             dict(kind='crit', src=TRYND, tgt=FRONT, at=1.95, seed=15)],
         hp=[dict(unit=FRONT, at=.4, value=.55), dict(unit=SECOND, at=.4, value=.7), dict(unit=THIRD, at=.4, value=.74),
             dict(unit=FRONT, at=2.0, value=.12)],
         texts=[dict(unit=FRONT, at=.4, text='-1320', color=WHITE), dict(unit=SECOND, at=.42, text='-1105', color=WHITE),
                dict(unit=THIRD, at=.44, text='-987', color=WHITE), dict(unit=FRONT, at=2.0, text='-2486', color=GOLD, size=28)]),
    dict(id='mend', title='魔刃斩 · 低血时先回血', dur=2.3,
         note='生命低于40%且怒气至少40时，魔刃斩先回血：暗红光点螺旋汇入，暖色火苗升起，然后再突进斩击。',
         units=units((240, 580), None, [(240, 300), (196, 214)], hp=.3, rage=.6),
         moves=[dict(unit=TRYND, at=.8, len=.18, x=240, y=405)],
         fx=[dict(kind='mend', src=TRYND, at=.1, seed=21),
             dict(kind='slash', src=TRYND, tgt=FRONT, at=.8, frozen=True, seed=22),
             dict(kind='cleave', src=TRYND, tgt=SECOND, at=.8, seed=23)],
         hp=[dict(unit=TRYND, at=.55, value=.64), dict(unit=FRONT, at=1.1, value=.6), dict(unit=SECOND, at=1.1, value=.72)],
         texts=[dict(unit=TRYND, at=.55, text='+1850', color=GREEN), dict(unit=FRONT, at=1.1, text='-1320', color=WHITE)]),
    dict(id='warcry', title='恶魔战吼（队长技）', dur=2.3,
         note='脚下浮现恶魔法阵，三道咆哮冲击波扩散，火焰环绕喷发。友军被燃起的怒气提振（金色光柱与上升火花），前排敌人被暗红色光环压制、碎片坠落（虚弱）。',
         units=units((240, 520), (240, 650), [(240, 280), (200, 190)], hp=.7, rage=.9),
         fx=[dict(kind='warcry', src=TRYND, at=.15, seed=31),
             dict(kind='rally', src=TRYND, tgt=TRYND, at=.15, seed=32),
             dict(kind='rally', src=TRYND, tgt=ALLY, at=.15, seed=33),
             dict(kind='weak', src=TRYND, tgt=FRONT, at=.15, seed=34),
             dict(kind='weak', src=TRYND, tgt=SECOND, at=.15, seed=35)],
         rage=[dict(unit=TRYND, at=.2, value=.45)],
         hp=[dict(unit=ALLY, at=.6, value=1)],
         texts=[dict(unit=TRYND, at=.15, text='恶魔战吼', color=RED), dict(unit=ALLY, at=.6, text='+960', color=GREEN)]),
    dict(id='fury', title='无尽怒火（免死触发）', dur=4.0,
         note='受到致命伤害时，一把巨大的幽灵恶魔之刃从天而降插进地面，血光炸开、恶魔法阵砸在脚下、魔焰冲天、黑烟翻涌。怒火持续期间，恶魔之刃悬浮在身后，身边有环绕的魔焰、缓慢旋转的法阵和升起的血色火星。',
         units=units((240, 480), None, [(240, 260), (200, 170)], hp=.15, rage=.3),
         fx=[dict(kind='fury', src=TRYND, at=.35, seed=41),
             dict(kind='aura', src=TRYND, at=.35, stop=3.5, seed=42)],
         hp=[dict(unit=TRYND, at=.1, value=.01)],
         rage=[dict(unit=TRYND, at=.4, value=.85)],
         texts=[dict(unit=TRYND, at=.05, text='-3020', color=RED, size=26), dict(unit=TRYND, at=.6, text='无尽怒火', color=RED)]),
    dict(id='calm', title='怒火平息：净化并回复35%生命', dur=2.5,
         note='免死结束时怒气清空：紫色碎片向外迸散（减益被净化），法阵收缩消失，一道金色光柱落下回复生命，光点螺旋升起。',
         units=units((240, 470), None, [(240, 250)], hp=.01, rage=.8),
         fx=[dict(kind='aura', src=TRYND, at=0, stop=.55, seed=51),
             dict(kind='calm', src=TRYND, at=.55, seed=52)],
         rage=[dict(unit=TRYND, at=.55, value=0)],
         hp=[dict(unit=TRYND, at=1.0, value=.36)],
         texts=[dict(unit=TRYND, at=1.0, text='+4410', color=GREEN)]),
]


def run(cmd, **kw):
    print('>', ' '.join(str(c) for c in cmd[:4]), '...')
    subprocess.run([str(c) for c in cmd], check=True, **kw)


def export_art(dest):
    """Pull the chibi art out of the hero SWF the first time."""
    dest.mkdir(parents=True, exist_ok=True)
    if all((dest / f'{name}.png').exists() for name in ART):
        return
    temp = dest / '_export'
    run([TOOLS / 'java/bin/java.exe', '-jar', TOOLS / 'ffdec/ffdec.jar', '-cli', '-selectclass', ','.join(ART),
         '-format', 'sprite:png', '-export', 'sprite', temp, ROOT / 'client/resources/app/assets/swfs/hero_A.swf'])
    for name in ART:
        found = next(temp.glob(f'*_{name}/1.png'), None)
        if found:
            shutil.copy(found, dest / f'{name}.png')
    shutil.rmtree(temp, ignore_errors=True)


def harness_source():
    code = (ROOT / 'client/src/demonblade_tryndamere_fx.aspart').read_text('utf-8')
    core = code[code.index(CORE_START):code.index(CORE_END) + len(CORE_END)]
    return (ROOT / 'scripts/demonblade_fx_harness.as').read_text('utf-8').replace('/*CORE*/\n', core)


def render(out, art):
    build = out / '_build'
    shutil.rmtree(build, ignore_errors=True)
    build.mkdir(parents=True)
    (build / 'DemonFxHarness.as').write_text(harness_source(), encoding='utf-8')
    sdk = TOOLS / 'air-sdk'
    run([TOOLS / 'java/bin/java.exe', '-Xmx512m', '-Duser.language=en', f'-Dflexlib={sdk / "frameworks"}', '-jar', sdk / 'lib/mxmlc-cli.jar',
         '+configname=air', '-output', build / 'harness.swf', '-default-size', '480', '720',
         f'-source-path={build}', '--', build / 'DemonFxHarness.as'])
    (build / 'app.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n<application xmlns="http://ns.adobe.com/air/application/51.4">'
        '<id>demonblade.fx.preview</id><filename>DemonFxPreview</filename><versionNumber>1.0.0</versionNumber>'
        '<initialWindow><content>harness.swf</content><visible>false</visible></initialWindow></application>\n',
        encoding='utf-8')
    scenes = json.dumps(SCENES, ensure_ascii=False)
    run([sdk / 'bin/adl.exe', build / 'app.xml', build, '--', out, art, scenes], timeout=900)


def encode(out):
    ffmpeg = next((TOOLS / 'pythonlibs/imageio_ffmpeg/binaries').glob('ffmpeg*.exe'))
    for scene in SCENES:
        frames = out / scene['id']
        run([ffmpeg, '-loglevel', 'error', '-y', '-framerate', 30, '-i', frames / '%04d.png',
             '-c:v', 'libvpx-vp9', '-b:v', '0', '-crf', 28, '-pix_fmt', 'yuv420p', out / f"{scene['id']}.webm"])
        # A strip of every sixth frame, for reviewing the timing at a glance.
        run([ffmpeg, '-loglevel', 'error', '-y', '-i', frames / '%04d.png', '-vf',
             "select='not(mod(n\\,5))',scale=160:-1,tile=10x2", '-frames:v', 1, out / f"{scene['id']}-strip.png"])


def index(out):
    cards = ''.join(
        f'<article><h2>{s["title"]}</h2><video src="{s["id"]}.webm" autoplay loop muted playsinline></video>'
        f'<p>{s["note"]}</p></article>' for s in SCENES)
    (out / 'index.html').write_text(f'''<!doctype html><html lang="zh"><meta charset="utf-8">
<title>恶魔之刃泰达米尔 · 技能特效</title><style>
body{{margin:0;background:#120d0c;color:#f3e2c7;font:15px "Microsoft YaHei",sans-serif}}
main{{max-width:1600px;margin:24px auto;padding:0 20px}}h1{{font-size:26px;color:#ffb070;margin:0 0 6px}}
.lead{{color:#c9b59a;margin:0 0 20px;line-height:1.7}}
.grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:18px}}
article{{background:#1f1716;border:1px solid #4a2a22;border-radius:10px;padding:12px}}
h2{{font-size:17px;margin:0 0 8px;color:#ffd9a0}}video{{width:100%;border-radius:6px;display:block;background:#000}}
article p{{color:#c9b59a;line-height:1.65;font-size:13.5px;margin:10px 0 2px}}
.tex{{margin-top:26px}}.tex img{{width:100%;border-radius:8px;border:1px solid #4a2a22}}
</style><main><h1>恶魔之刃泰达米尔 · 技能特效</h1>
<p class="lead">以下画面全部由游戏客户端里的同一份特效代码逐帧绘制（AIR 运行，未经手工修饰），角色卡片和伤害数字只是示意；恶魔之刃泰达米尔目前在游戏里借用经典蛮王的立绘，所以卡片上暂时还是经典形象。
配色走恶魔之刃的血红与黑烟，招牌元素是一把幽灵恶魔之刃。特效贴图全部在代码里实时绘制，不需要额外图片文件。</p>
<div class="grid">{cards}</div>
<div class="tex"><h2>代码绘制的 10 张特效贴图</h2><img src="textures.png"></div></main></html>
''', encoding='utf-8')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', type=Path, default=ROOT.parent.parent / 'outputs/demonblade-fx-20261124')
    parser.add_argument('--art', type=Path)
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    art = (args.art or out / 'art').resolve()
    export_art(art)
    render(out, art)
    encode(out)
    index(out)
    print('Preview:', out / 'index.html')


if __name__ == '__main__':
    sys.exit(main())
