"""Render Dragonmancer Kai'Sa's Icathian Rain with the game's own effect code.

The group-K timeline and painters in client/src/kaisa_rain_fx_106.aspart (plus the
shared pure helpers of hero_fx_core_106.aspart) are pasted into the Demonblade AIR
harness, compiled with mxmlc and run with adl. Timing follows kaisaVolley104 and
kaisaRain106: shots leave .1 s apart and each lands .35 s after it was scheduled.

    python scripts/kaisa_rain_fx_preview.py [--out DIR]
"""
import argparse
import json
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import demonblade_fx_preview as demon  # noqa: E402

ROOT = demon.ROOT
TOOLS = demon.TOOLS
FX = ROOT / 'client/src/kaisa_rain_fx_106.aspart'
CORE = ROOT / 'client/src/hero_fx_core_106.aspart'
TEXTURES = ['glow', 'streak', 'bolt', 'spark', 'ring']
ENEMY_ART = ['A_1001_5', 'A_1002_5', 'A_1005_5']
FLIGHT = .34


def volley(count, first=.45, gap=.1, enemies=3, seed=1):
    """Shots, targets and hit texts as kaisaVolley104 + kaisaRain106 schedule them."""
    fx, texts = [], []
    for shot in range(count):
        now = first + shot * gap
        target = 1 + shot % enemies
        fx.append(dict(kind='rain', src=0, tgt=target, at=now + .35 - FLIGHT, seed=seed + shot, p=dict(shot=shot)))
        texts.append(dict(unit=target, at=now + .35, text=f'-{1480 + 37 * shot}', color=0xFFFFFF, size=20))
    return fx, texts


def scene(id, title, count, kaisa, enemies, note):
    fx, texts = volley(count, enemies=len(enemies))
    units = [dict(art='kaisa', team=1, x=kaisa[0], y=kaisa[1], hp=.9, label='神龙尊者卡莎')]
    for art, at in zip(ENEMY_ART, enemies):
        units.append(dict(art=art, team=2, x=at[0], y=at[1], hp=1))
    end = max(f['at'] + FLIGHT + .4 for f in fx)
    return dict(id=id, title=title, dur=round(end + .3, 2), note=note, units=units, fx=fx, texts=texts)


SCENES = [
    scene('rain3', '艾卡西亚暴雨 · 首次 3 发', 3, (240, 560), [(240, 300), (196, 214), (286, 150)],
          '飞弹每 0.1 秒从卡莎左右肩交替出膛，不悬停、不等上一发命中，出膛即沿各自的弧线飞向目标，身后拖着由青白到蓝的渐细光带，命中时只溅出小团等离子与金色火星。'),
    scene('rain7', '艾卡西亚暴雨 · 第三次 7 发', 7, (240, 580), [(240, 300), (196, 214), (286, 150)],
          '七发连成一串弹幕，左右交替、外甩幅度各不相同，从不同方向交错扑向目标。'),
    scene('rain5_side', '侧向目标 · 5 发', 5, (150, 600), [(320, 290), (360, 200), (280, 150)],
          '目标不在正前方时，出膛方向随朝向旋转，弧线仍从两侧包抄。'),
]


def core_source():
    fx = FX.read_text('utf-8')
    consts = fx[fx.index('      private static const KAISA_RAIN_FLIGHT106'):fx.index('      // Called once per missile')]
    body = fx[fx.index('      public static function heroFxPaintK106'):fx.index('      // END KAISA RAIN TIMELINE 106')]
    core = CORE.read_text('utf-8')
    helpers = core[core.index('      // BEGIN HERO FX HELPERS 106'):core.index('      // END HERO FX HELPERS 106')]
    return consts + helpers + body


def harness_source():
    s = (ROOT / 'scripts/demonblade_fx_harness.as').read_text('utf-8')
    swaps = [
        ('DemonFxHarness', 'KaisaRainHarness'),
        ('textures[id]=demonFxPaint105(id);', 'textures[id]=heroFxPaintK106(id);'),
        ('["glow","ember","spark","slash","ring","sigil","flame","shard","smoke","blade"]', json.dumps(TEXTURES).replace(' ', '')),
        ('var life:Number=demonFxLife105(fx.kind);', 'var life:Number=heroFxLifeK106(fx.kind,fx.p);'),
        ('demonFxSprites105(fx.kind,age,src[0],src[1],dst[0],dst[1],int(fx.seed || 1),sprites);',
         'heroFxSpritesK106(fx.kind,age,src[0],src[1],dst[0],dst[1],int(fx.seed || 1),sprites,fx.p);'),
    ]
    for old, new in swaps:
        if old not in s:
            raise SystemExit('Harness anchor moved: ' + old)
        s = s.replace(old, new)
    return s.replace('/*CORE*/\n', core_source())


def render(out, art):
    build = out / '_build'
    shutil.rmtree(build, ignore_errors=True)
    build.mkdir(parents=True)
    (build / 'KaisaRainHarness.as').write_text(harness_source(), encoding='utf-8')
    sdk = TOOLS / 'air-sdk'
    demon.run([TOOLS / 'java/bin/java.exe', '-Xmx512m', '-Duser.language=en', f'-Dflexlib={sdk / "frameworks"}', '-jar',
               sdk / 'lib/mxmlc-cli.jar', '+configname=air', '-output', build / 'harness.swf', '-default-size', '480', '720',
               f'-source-path={build}', '--', build / 'KaisaRainHarness.as'])
    (build / 'app.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n<application xmlns="http://ns.adobe.com/air/application/51.4">'
        '<id>kaisa.rain.preview</id><filename>KaisaRainPreview</filename><versionNumber>1.0.0</versionNumber>'
        '<initialWindow><content>harness.swf</content><visible>false</visible></initialWindow></application>\n',
        encoding='utf-8')
    demon.run([sdk / 'bin/adl.exe', build / 'app.xml', build, '--', out, art, json.dumps(SCENES, ensure_ascii=False)], timeout=900)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', type=Path, default=ROOT / 'build/kaisa-rain-preview')
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    art = out / 'art'
    demon.ART = ENEMY_ART
    demon.export_art(art)
    shutil.copy(ROOT / 'config/reconstruction/dragonmancer-kaisa-media/cards/dragonmancer_kaisa.png', art / 'kaisa.png')
    render(out, art)
    demon.SCENES = SCENES
    demon.encode(out)
    print('Preview frames and videos:', out)


if __name__ == '__main__':
    sys.exit(main())
