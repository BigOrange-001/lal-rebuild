"""Render group A's code-painted hero effects with the game's own effect code.

The pure block of client/src/hero_fx_a_106.aspart (textures painted with flash.Graphics
and the timelines) plus the core's shared helpers are pasted verbatim into a small AIR
harness, compiled with mxmlc and run with adl. Every frame is drawn from the exact sprite
list the game hands to Starling; persistent state marks use the same pose function the
battle animator calls. ffmpeg turns the frames into looping videos with an index page.

    python scripts/hero_fx_preview_a_106.py [--out DIR] [--only ID,ID]
"""
import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT.parent / 'toolchain'
HELPERS = ('      // BEGIN HERO FX HELPERS 106\n', '      // END HERO FX HELPERS 106\n')
PURE = ('      // BEGIN HFX A PURE 106\n', '      // END HFX A PURE 106\n')
TEXTURES = ['glow', 'dot', 'spark', 'ring', 'star', 'note', 'note2', 'clef', 'staff', 'wave', 'gavel', 'seal', 'crack',
            'shard', 'chain', 'claw', 'clawShut', 'lock', 'gear', 'dart', 'egg', 'shell', 'confetti', 'puff', 'smoke',
            'ball', 'trail', 'shuriken', 'slash', 'lotus', 'petal', 'flame', 'rune']
SONA, TF, ZED, TEEMO, BLITZ, EZ, KARMA = 'A_1228_6', 'A_1214_6', 'A_1132_6', 'A_1209_6', 'A_1204_6', 'A_1213_6', 'A_1139_6'
ALLY, ALLY2, FOE1, FOE2, FOE3 = 'A_1004_5', 'A_1001_5', 'A_1002_5', 'A_1005_5', 'A_1003_5'
ART = [SONA, TF, ZED, TEEMO, BLITZ, EZ, KARMA, ALLY, ALLY2, FOE1, FOE2, FOE3]
RED, GOLD, GREEN, WHITE, BLUE, PURPLE = 0xFF3B1F, 0xFFD040, 0x66FF66, 0xFFFFFF, 0x8CC8FF, 0xC890FF

# Lane: allies below, enemies above. Index 0 is always the hero.
HERO, A1, A2, E1, E2, E3 = range(6)


def lane(hero, label, hp=None, ally_hp=(1, 1), foes=(1, 1, 1), y=(620, 520, 420, 300, 200, 100)):
    rows = [dict(art=hero, team=1, x=240, y=y[0], hp=1 if hp is None else hp, label=label),
            dict(art=ALLY, team=1, x=240, y=y[1], hp=ally_hp[0]),
            dict(art=ALLY2, team=1, x=240, y=y[2], hp=ally_hp[1])]
    for art, at, value in zip((FOE1, FOE2, FOE3), y[3:], foes):
        rows.append(dict(art=art, team=2, x=240, y=at, hp=value))
    return rows


SCENES = [
    dict(id='sona-heal', title='娑娜 · 应援旋律（低血治疗）', dur=1.8,
         note='有友军低于60%：一小段绿色乐句游向生命最低的两名友军，到达时脚下展开五线谱环，高音谱号升起，并清除一个负面状态。娑娜脚下常驻的现场混音光环切到“治疗”形态（绿色谱环+两枚环绕音符）。',
         units=lane(SONA, 'DJ娑娜', ally_hp=(.35, .5)),
         states=[dict(kind='aura_heal', ids=['staff', 'note', 'note2'], unit=HERO, aura=True)],
         fx=[dict(kind='sonaHeal', src=HERO, tgt=A1, at=.1, seed=1), dict(kind='sonaHeal', src=HERO, tgt=A2, at=.16, seed=2)],
         hp=[dict(unit=A1, at=.55, value=.62), dict(unit=A2, at=.6, value=.74)],
         texts=[dict(unit=A1, at=.55, text='+2310', color=GREEN), dict(unit=A2, at=.6, text='+2310', color=GREEN)]),
    dict(id='sona-shield', title='娑娜 · 应援旋律（全体护盾）', dur=1.6,
         note='友军都健康时：蓝色音符飞向本路每名友军（含自己），在腰间合成一圈旋转的谱线环与淡蓝声障。光环为“减伤”形态（蓝色）。',
         units=lane(SONA, 'DJ娑娜'),
         states=[dict(kind='aura_guard', ids=['staff', 'note', 'note2'], unit=HERO, aura=True)],
         fx=[dict(kind='sonaShield', src=HERO, tgt=HERO, at=.1, seed=3), dict(kind='sonaShield', src=HERO, tgt=A1, at=.1, seed=4),
             dict(kind='sonaShield', src=HERO, tgt=A2, at=.1, seed=5)]),
    dict(id='sona-ult', title='娑娜 · 狂欢终乐章（队长技）', dur=2.0,
         note='脚下展开品红与金色的双层谱环，三道声波沿分路滚向敌人；每名敌人被声浪击中时爆开低音冲击环，头顶下方旋转音符表示眩晕。友军脚下金环、升起的金色音符和星光代表净化+力量。',
         units=lane(SONA, 'DJ娑娜'),
         states=[dict(kind='aura_guard', ids=['staff', 'note', 'note2'], unit=HERO, aura=True)],
         fx=[dict(kind='sonaCast', src=HERO, tgt=E1, at=.1, follow=True, seed=6),
             dict(kind='sonaEncore', src=HERO, tgt=HERO, at=.5, seed=7), dict(kind='sonaEncore', src=HERO, tgt=A1, at=.55, seed=8),
             dict(kind='sonaEncore', src=HERO, tgt=A2, at=.6, seed=9),
             dict(kind='sonaUlt', src=HERO, tgt=E1, at=.1, seed=10), dict(kind='sonaUlt', src=HERO, tgt=E2, at=.15, seed=11),
             dict(kind='sonaUlt', src=HERO, tgt=E3, at=.2, seed=12)],
         hp=[dict(unit=E1, at=.45, value=.7), dict(unit=E2, at=.5, value=.72), dict(unit=E3, at=.55, value=.75)],
         texts=[dict(unit=E1, at=.45, text='-1980', color=WHITE), dict(unit=E2, at=.5, text='-1980', color=WHITE)]),
    dict(id='judge-q', title='逆转裁判崔斯特 · 异议质询', dur=1.7,
         note='金色指认光线射向增益最多的敌人，法槌从右上方挥落；落锤处金光与印章，目标的增益像金色玻璃一样碎裂。“异议成立”：碎片化作金色光点飞向本路生命最低的友军，变成护盾。',
         units=lane(TF, '逆转裁判崔斯特', ally_hp=(.45, 1)),
         fx=[dict(kind='judgeQ', src=HERO, tgt=E1, at=.1, seed=13), dict(kind='judgeBreak', src=HERO, tgt=E1, at=.22, seed=14),
             dict(kind='judgeTransfer', src=E1, tgt=A1, at=.4, seed=15)],
         hp=[dict(unit=E1, at=.45, value=.68)],
         texts=[dict(unit=E1, at=.45, text='-1430', color=WHITE)]),
    dict(id='judge-ult', title='逆转裁判崔斯特 · 终审判决（队长技）', dur=2.2,
         note='法官脚下展开天平印章与光柱；每名敌人身下印章浮现，巨型法槌砸下，增益碎裂，金印转为紫色表示诅咒。被驱散过增益的目标随后被一道短促的白色裁决光击中（额外真伤）。',
         units=lane(TF, '逆转裁判崔斯特'),
         fx=[dict(kind='judgeCast', src=HERO, tgt=E1, at=.1, follow=True, seed=16),
             dict(kind='verdict', src=HERO, tgt=E1, at=.1, seed=17), dict(kind='verdict', src=HERO, tgt=E2, at=.16, seed=18),
             dict(kind='judgeBreak', src=HERO, tgt=E1, at=.5, seed=19), dict(kind='judgeTrue', src=HERO, tgt=E1, at=.9, seed=20)],
         hp=[dict(unit=E1, at=.5, value=.6), dict(unit=E2, at=.56, value=.66), dict(unit=E1, at=.95, value=.45)],
         texts=[dict(unit=E1, at=.5, text='-1980', color=WHITE), dict(unit=E1, at=.95, text='-990', color=GOLD)]),
    dict(id='zed', title='劫 · 剧毒手里剑 / 影分身', dur=1.9,
         note='劫甩出旋转的钢制手里剑（带残影），命中时血色交叉斩并留下绿色毒雾。影分身脚下是暗红色的影印（出现时旋转收拢），它掷出的手里剑偏紫暗，起手处冒出黑烟。',
         units=[dict(art=ZED, team=1, x=240, y=620, hp=1, label='劫'), dict(art=ZED, team=1, x=240, y=500, hp=1, label='影分身', ghost=True),
                dict(art=ALLY2, team=1, x=-200, y=-200, hp=1),
                dict(art=FOE1, team=2, x=240, y=300, hp=1), dict(art=FOE2, team=2, x=240, y=200, hp=1), dict(art=FOE3, team=2, x=-200, y=-200, hp=1)],
         states=[dict(kind='shadow', ids=['rune'], unit=1)],
         fx=[dict(kind='zedStar', src=HERO, tgt=E1, at=.25, seed=21), dict(kind='shadowStar', src=1, tgt=E1, at=.8, seed=22)],
         hp=[dict(unit=E1, at=.45, value=.75), dict(unit=E1, at=1.0, value=.6)],
         texts=[dict(unit=E1, at=.45, text='-1720', color=WHITE), dict(unit=E1, at=1.0, text='-1130', color=WHITE)]),
    dict(id='teemo-q', title='兔宝宝提莫 · 彩蛋速递 / 惊喜孵化', dur=2.7,
         note='提莫吹出毒镖，命中处绿色毒雾，同时在目标脚下“种”下彩蛋（薄荷色环+彩纸）。常驻彩蛋是代码绘制的复活节彩蛋，成熟后带暖光并摇晃。中毒结算触发时，成熟彩蛋摇晃、裂开，迸出粉彩蛋壳、彩纸和毒雾。',
         units=lane(TEEMO, '兔宝宝提莫'),
         states=[dict(kind='egg', ids=['egg'], unit=E1, at=.5, ground=True), dict(kind='egg_ready', ids=['glow', 'egg'], unit=E2, stop=1.25, ground=True)],
         fx=[dict(kind='teemoDart', src=HERO, tgt=E1, at=.1, seed=23),
             dict(kind='eggBoom', src=HERO, ground=E2, at=1.25, seed=24), dict(kind='eggHit', src=HERO, tgt=E2, at=1.6, seed=25),
             dict(kind='eggHit', src=HERO, tgt=E1, at=1.62, seed=26)],
         hp=[dict(unit=E1, at=.4, value=.75), dict(unit=E2, at=1.6, value=.7), dict(unit=E1, at=1.62, value=.6)],
         texts=[dict(unit=E1, at=.4, text='-1100', color=WHITE), dict(unit=E2, at=1.6, text='-990', color=WHITE)]),
    dict(id='teemo-ult', title='兔宝宝提莫 · 复活节巡游（队长技）', dur=2.2,
         note='派对礼炮朝敌人喷出彩纸与彩带，三颗彩蛋被高高抛向本路三个敌人并弹落在脚下；已有的成熟彩蛋随后一并爆炸。',
         units=lane(TEEMO, '兔宝宝提莫'),
         states=[dict(kind='egg_ready', ids=['glow', 'egg'], unit=E1, stop=.55, ground=True),
                 dict(kind='egg', ids=['egg'], unit=E2, at=.62, ground=True), dict(kind='egg', ids=['egg'], unit=E3, at=.69, ground=True)],
         fx=[dict(kind='teemoParade', src=HERO, tgt=E1, at=.1, follow=True, seed=27),
             dict(kind='eggToss', src=HERO, tgt=E1, at=.15, seed=28), dict(kind='eggToss', src=HERO, tgt=E2, at=.22, seed=29),
             dict(kind='eggToss', src=HERO, tgt=E3, at=.29, seed=30),
             dict(kind='eggBoom', src=HERO, ground=E1, at=.55, seed=31), dict(kind='eggHit', src=HERO, tgt=E1, at=.9, seed=32)],
         hp=[dict(unit=E1, at=.9, value=.7)],
         texts=[dict(unit=E1, at=.9, text='-990', color=WHITE)]),
    dict(id='blitz-grab', title='苹果机器人布里茨 · 强制连接', dur=2.2,
         note='机械手带着一串跳动的电链射向最远的敌人，抓握合拢后把它拖到前排；目标身上电弧噼啪（眩晕），随后一枚准星缩放锁定（暴露）。暴露期间常驻一个小而淡的旋转锁定准星，代替原来的红色爪痕。',
         units=lane(BLITZ, '苹果机器人布里茨'),
         moves=[dict(unit=E3, at=.3, len=.4, x=240, y=330)],
         states=[dict(kind='exposed', ids=['lock'], unit=E3, at=1.0)],
         fx=[dict(kind='blitzGrab', src=HERO, tgt=E3, at=.1, seed=33), dict(kind='blitzLock', src=HERO, tgt=E3, at=.6, seed=34)],
         hp=[dict(unit=E3, at=.4, value=.72)],
         texts=[dict(unit=E3, at=.8, text='-1980', color=WHITE)]),
    dict(id='blitz-ult', title='苹果机器人布里茨 · 系统重启（队长技）', dur=2.0,
         note='齿轮在身后加速旋转，电涌环沿地面扩散、电弧沿分路奔向敌人；友军脚下青色电路环与星光（净化+护盾）。每名敌人被闪电劈中，被本人暴露的目标准星坍缩并被斩断（沉默）。',
         units=lane(BLITZ, '苹果机器人布里茨'),
         states=[dict(kind='exposed', ids=['lock'], unit=E1, stop=.6)],
         fx=[dict(kind='blitzReboot', src=HERO, tgt=E1, at=.1, follow=True, seed=35),
             dict(kind='blitzPurify', src=HERO, tgt=HERO, at=.4, seed=36), dict(kind='blitzPurify', src=HERO, tgt=A1, at=.44, seed=37),
             dict(kind='blitzPurify', src=HERO, tgt=A2, at=.48, seed=38),
             dict(kind='blitzZap', src=HERO, tgt=E1, at=.3, seed=39), dict(kind='blitzZap', src=HERO, tgt=E2, at=.35, seed=40),
             dict(kind='blitzZap', src=HERO, tgt=E3, at=.4, seed=41), dict(kind='blitzMute', src=HERO, tgt=E1, at=.55, seed=42)],
         hp=[dict(unit=E1, at=.4, value=.7), dict(unit=E2, at=.45, value=.72), dict(unit=E3, at=.5, value=.74)],
         texts=[dict(unit=E1, at=.4, text='-1980', color=WHITE)]),
    dict(id='ez-pass', title='足球先生伊泽瑞尔 · 弧线传射 / 二过一', dur=3.0,
         note='伊泽瑞尔踢出带旋转、拖影和地面投影的弧线球打向前排并弹开，同时把球吊传给攻击最高的队友（队友脚下常驻一只小足球）。队友技能命中后回传（二过一），伊泽瑞尔脚下金环与星光表示获得射门机会，随即凌空抽射补射。',
         units=lane(EZ, '足球先生伊泽瑞尔', y=(620, 520, -400, 300, 200, 100)),
         states=[dict(kind='ball', ids=['ball'], unit=A1, at=.6, stop=1.4), dict(kind='shot', ids=['ball', 'star'], unit=HERO, at=1.75)],
         fx=[dict(kind='ezCurl', src=HERO, tgt=E1, at=.1, seed=43), dict(kind='ezPass', src=HERO, tgt=A1, at=.15, seed=44),
             dict(kind='ezBackPass', src=A1, tgt=HERO, at=1.4, seed=45), dict(kind='ezShotReady', src=HERO, tgt=HERO, at=1.55, seed=46),
             dict(kind='ezVolley', src=HERO, tgt=E1, at=1.7, seed=47)],
         hp=[dict(unit=E1, at=.5, value=.8), dict(unit=E1, at=1.95, value=.66), dict(unit=A1, at=1.6, value=1)],
         texts=[dict(unit=E1, at=.5, text='-1210', color=WHITE), dict(unit=E1, at=1.95, text='-770', color=WHITE)]),
    dict(id='ez-ult', title='足球先生伊泽瑞尔 · 绝杀世界波（队长技）', dur=2.3,
         note='金色光点向脚下汇聚蓄力，一脚大力抽射：球拖着金色火焰与长拖尾直线飞出，沿途炸开气流环，命中时金光冲击并把球高高弹飞。若有射门机会，再补上一记金色弧线球，命中处星形爆闪。',
         units=lane(EZ, '足球先生伊泽瑞尔'),
         states=[dict(kind='shot', ids=['ball', 'star'], unit=HERO, stop=.35)],
         fx=[dict(kind='ezWorldie', src=HERO, tgt=E1, at=.1, seed=48), dict(kind='ezWorldie', src=HERO, tgt=E2, at=.17, seed=49),
             dict(kind='ezFinish', src=HERO, tgt=E1, at=.6, seed=50)],
         hp=[dict(unit=E1, at=.65, value=.6), dict(unit=E2, at=.72, value=.62), dict(unit=E1, at=1.0, value=.48)],
         texts=[dict(unit=E1, at=.65, text='-2310', color=WHITE), dict(unit=E1, at=1.0, text='-1320', color=WHITE)]),
    dict(id='karma-q', title='卡尔玛 · 梵咒', dur=1.9,
         note='品红心灵之火（被花瓣环绕）飞向血量比例最低的三名敌人：命中时脚下莲花绽放、花瓣四散，被驱散的增益化作金色碎片飘走；随后念珠环绕表示眩晕，身上燃起小簇灵火表示中毒。',
         units=lane(KARMA, '卡尔玛', foes=(.5, .4, .7)),
         fx=[dict(kind='karmaOrb', src=HERO, tgt=E1, at=.1, seed=51), dict(kind='karmaOrb', src=HERO, tgt=E2, at=.16, seed=52),
             dict(kind='karmaOrb', src=HERO, tgt=E3, at=.22, seed=53),
             dict(kind='karmaStun', src=HERO, tgt=E1, at=.4, seed=54), dict(kind='karmaStun', src=HERO, tgt=E2, at=.46, seed=55),
             dict(kind='karmaFlame', src=HERO, tgt=E1, at=.55, seed=56), dict(kind='karmaFlame', src=HERO, tgt=E2, at=.61, seed=57)],
         hp=[dict(unit=E1, at=.45, value=.35), dict(unit=E2, at=.5, value=.28)],
         texts=[dict(unit=E1, at=.45, text='-1520', color=WHITE)]),
    dict(id='karma-ult', title='卡尔玛 · 心灵核爆（队长技）', dur=2.7,
         note='卡尔玛脚下巨大的莲花曼陀罗展开、念珠环绕、灵波扩散；友军脚下莲花与升起的花瓣（两次净化合并为一次），花瓣环绕成护盾。全场敌人先受一次紫色心灵冲击（50%真伤），再由收缩的莲花曼陀罗内爆成粉白光（400%真伤）；最后花瓣螺旋回到卡尔玛身上（吸血）。',
         units=lane(KARMA, '卡尔玛'),
         fx=[dict(kind='karmaCast', src=HERO, tgt=HERO, at=.1, follow=True, seed=58),
             dict(kind='karmaPurify', src=HERO, tgt=HERO, at=.25, seed=59), dict(kind='karmaPurify', src=HERO, tgt=A1, at=.29, seed=60),
             dict(kind='karmaShield', src=HERO, tgt=A1, at=.4, seed=61), dict(kind='karmaShield', src=HERO, tgt=A2, at=.44, seed=62),
             dict(kind='karmaNova', src=HERO, tgt=E1, at=.5, seed=63), dict(kind='karmaNova', src=HERO, tgt=E2, at=.55, seed=64),
             dict(kind='karmaNova2', src=HERO, tgt=E1, at=.85, seed=65), dict(kind='karmaNova2', src=HERO, tgt=E2, at=.9, seed=66),
             dict(kind='karmaHeal', src=HERO, tgt=HERO, at=1.6, seed=67)],
         hp=[dict(unit=E1, at=.6, value=.85), dict(unit=E1, at=1.35, value=.3), dict(unit=HERO, at=2.0, value=1), dict(unit=E2, at=1.4, value=.4)],
         texts=[dict(unit=E1, at=.6, text='-640', color=WHITE), dict(unit=E1, at=1.35, text='-5120', color=WHITE),
                dict(unit=HERO, at=2.0, text='+1540', color=GREEN)]),
]

HARNESS = r'''package
{
   import flash.desktop.NativeApplication;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.BlendMode;
   import flash.display.Loader;
   import flash.display.PNGEncoderOptions;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.InvokeEvent;
   import flash.filesystem.File;
   import flash.filesystem.FileMode;
   import flash.filesystem.FileStream;
   import flash.filters.GlowFilter;
   import flash.geom.ColorTransform;
   import flash.geom.Matrix;
   import flash.geom.Rectangle;
   import flash.net.URLRequest;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.utils.ByteArray;

   // Renders group A's effect code (pasted below by hero_fx_preview_a_106.py) into PNG frames.
   public class HeroFxAHarness extends Sprite
   {
/*HELPERS*/
/*PURE*/
      private static const W:int = 480;
      private static const H:int = 720;
      private static const FPS:int = 30;
      private var outDir:File;
      private var arts:Object = {};
      private var textures:Object = {};
      private var pending:int = 0;
      private var scenes:Array;
      private var names:Array;

      public function HeroFxAHarness()
      {
         NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE,onInvoke);
      }
      private function onInvoke(event:InvokeEvent) : void
      {
         outDir=new File(String(event.arguments[0]));
         scenes=JSON.parse(String(event.arguments[2])) as Array;
         names=JSON.parse(String(event.arguments[3])) as Array;
         var artDir:File=new File(String(event.arguments[1]));
         var wanted:Object={};
         for each(var scene:Object in scenes) for each(var unit:Object in scene.units) wanted[unit.art]=true;
         for(var name:String in wanted)
         {
            var file:File=artDir.resolvePath(name+".png");
            if(!file.exists) continue;
            ++pending;loadArt(name,file);
         }
         if(!pending) renderAll();
      }
      private function loadArt(name:String, file:File) : void
      {
         var loader:Loader=new Loader();
         loader.contentLoaderInfo.addEventListener(Event.COMPLETE,function(e:Event):void
         {
            arts[name]=Bitmap(loader.content).bitmapData;
            if(--pending==0) renderAll();
         });
         loader.load(new URLRequest(file.url));
      }
      private function texture(id:String) : BitmapData
      {
         if(!textures[id]) textures[id]=heroFxPaintA106(id);
         return textures[id];
      }
      private function renderAll() : void
      {
         // A sheet of every texture: additive ones on dark, the coloured ones too.
         var sheet:BitmapData=new BitmapData(1400,860,false,0x14181E);
         var x:Number=14;var y:Number=14;var row:Number=0;
         for each(var id:String in names)
         {
            var tex:BitmapData=texture(id);
            if(x+tex.width>1386) {x=14;y+=row+26;row=0;}
            sheet.draw(tex,new Matrix(1,0,0,1,x,y),null,null,null,true);
            label(sheet,id,x+tex.width/2,y+tex.height+10);
            x+=tex.width+18;row=Math.max(row,tex.height);
         }
         save(sheet,outDir.resolvePath("textures.png"));
         for each(var scene:Object in scenes) renderScene(scene);
         NativeApplication.nativeApplication.exit(0);
      }
      private function label(canvas:BitmapData, text:String, x:Number, y:Number) : void
      {
         var field:TextField=new TextField();field.autoSize=TextFieldAutoSize.LEFT;
         field.defaultTextFormat=new TextFormat("Arial",11,0xB8C0CC);field.text=text;
         canvas.draw(field,new Matrix(1,0,0,1,x-field.width/2,y-field.height/2));
      }
      private function save(bmp:BitmapData, file:File) : void
      {
         var bytes:ByteArray=bmp.encode(bmp.rect,new PNGEncoderOptions(true));
         var stream:FileStream=new FileStream();stream.open(file,FileMode.WRITE);stream.writeBytes(bytes);stream.close();
      }
      private function background() : BitmapData
      {
         var shape:Shape=new Shape();
         var m:Matrix=new Matrix();m.createGradientBox(W,H,Math.PI/2);
         shape.graphics.beginGradientFill("linear",[0x18231f,0x24332b,0x18231f],[1,1,1],[0,128,255],m);
         shape.graphics.drawRect(0,0,W,H);shape.graphics.endFill();
         shape.graphics.beginFill(0x2f4237,.65);shape.graphics.drawRect(130,0,220,H);shape.graphics.endFill();
         for(var y:int=0;y<H;y+=64)
         {
            shape.graphics.beginFill(0x3a5042,.35);shape.graphics.drawRect(134,y+2,212,58);shape.graphics.endFill();
         }
         shape.graphics.lineStyle(2,0x111a16,.8);shape.graphics.moveTo(130,0);shape.graphics.lineTo(130,H);shape.graphics.moveTo(350,0);shape.graphics.lineTo(350,H);
         var bmp:BitmapData=new BitmapData(W,H,false,0);bmp.draw(shape);
         return bmp;
      }
      private function ease(p:Number) : Number
      {
         p=Math.max(0,Math.min(1,p));return 1-(1-p)*(1-p)*(1-p);
      }
      private function unitAt(scene:Object, index:int, t:Number) : Array
      {
         var unit:Object=scene.units[index];var x:Number=unit.x;var y:Number=unit.y;
         for each(var move:Object in scene.moves || [])
         {
            if(move.unit!=index || t<move.at) continue;
            var p:Number=ease((t-move.at)/move.len);
            x+=(move.x-x)*p;y+=(move.y-y)*p;
         }
         return [x,y];
      }
      private function valueAt(scene:Object, key:String, index:int, t:Number) : Number
      {
         var value:Number=Number(scene.units[index][key]);
         for each(var change:Object in scene[key] || [])
            if(change.unit==index && t>=change.at) value=change.value;
         return value;
      }
      private function drawUnit(canvas:BitmapData, scene:Object, index:int, t:Number) : void
      {
         var unit:Object=scene.units[index];var at:Array=unitAt(scene,index,t);
         if(at[1]<-100) return;
         var shape:Shape=new Shape();var g:*=shape.graphics;
         var frame:uint=unit.team==1 ? 0x4d8fe0 : 0xd8503c;
         g.beginFill(0x000000,.35);g.drawEllipse(-40,36,80,18);g.endFill();
         g.beginFill(0x1b1f26,1);g.drawRoundRect(-45,-45,90,90,16,16);g.endFill();
         canvas.draw(shape,new Matrix(1,0,0,1,at[0],at[1]));
         var art:BitmapData=arts[unit.art];
         if(art)
         {
            var m:Matrix=new Matrix();var scale:Number=86/(art.height*.82);
            m.translate(-art.width/2,-art.height*.52);m.scale(scale,scale);m.translate(at[0],at[1]);
            canvas.draw(art,m,unit.ghost ? new ColorTransform(.45,.35,.55,1,10,0,20) : null,null,new Rectangle(at[0]-43,at[1]-43,86,86),true);
         }
         shape=new Shape();g=shape.graphics;
         g.lineStyle(4,frame,1);g.drawRoundRect(-45,-45,90,90,16,16);
         var hp:Number=valueAt(scene,"hp",index,t);
         g.lineStyle();g.beginFill(0x111111,1);g.drawRect(-40,-58,80,8);g.endFill();
         g.beginFill(unit.team==1 ? 0x4fd06a : 0xe04a3a,1);g.drawRect(-39,-57,78*hp,6);g.endFill();
         canvas.draw(shape,new Matrix(1,0,0,1,at[0],at[1]));
         if(unit.label) drawText(canvas,String(unit.label),0xFFE0A0,at[0],at[1]+56,1,13);
      }
      private function drawText(canvas:BitmapData, text:String, color:uint, x:Number, y:Number, alpha:Number, size:int) : void
      {
         var field:TextField=new TextField();field.autoSize=TextFieldAutoSize.LEFT;
         field.defaultTextFormat=new TextFormat("Microsoft YaHei",size,color,true);field.text=text;
         var holder:Sprite=new Sprite();holder.addChild(field);
         field.filters=[new GlowFilter(0x000000,1,4,4,6,2)];
         canvas.draw(holder,new Matrix(1,0,0,1,x-field.width/2,y-field.height/2),new ColorTransform(1,1,1,alpha),null,null,true);
      }
      private function drawPart(canvas:BitmapData, id:String, x:Number, y:Number, sx:Number, sy:Number, r:Number, fy:Number, a:Number, c:uint, add:Boolean) : void
      {
         var tex:BitmapData=texture(id);
         var m:Matrix=new Matrix();
         m.translate(-tex.width/2,-tex.height/2);m.scale(sx,sy);m.rotate(r);m.scale(1,fy);m.translate(x,y);
         var tint:ColorTransform=new ColorTransform(((c>>16)&255)/255,((c>>8)&255)/255,(c&255)/255,Math.max(0,Math.min(1,a)));
         canvas.draw(tex,m,tint,add ? BlendMode.ADD : BlendMode.NORMAL,null,true);
      }
      private function renderScene(scene:Object) : void
      {
         var dir:File=outDir.resolvePath(String(scene.id));
         if(dir.exists) dir.deleteDirectory(true);
         dir.createDirectory();
         var bg:BitmapData=background();
         var canvas:BitmapData=new BitmapData(W,H,false,0);
         var frames:int=int(Math.ceil(Number(scene.dur)*FPS));
         var sprites:Array=[];var pose:Object={};var live:Object={};
         for(var f:int=0;f<frames;f++)
         {
            var t:Number=f/FPS;var fx:Object;var at:Array;
            canvas.copyPixels(bg,bg.rect,new flash.geom.Point(0,0));
            for(var u:int=0;u<scene.units.length;u++) drawUnit(canvas,scene,u,t);
            // Persistent marks sit under the effects, as fxLayer104 does in the game.
            for each(var state:Object in scene.states || [])
            {
               var since:Number=t-Number(state.at || 0);
               if(since<0 || (state.stop!=undefined && t>=Number(state.stop))) continue;
               at=state.ground ? unitAt(scene,state.unit,Number(state.at || 0)) : unitAt(scene,state.unit,t);
               for(var i:int=0;i<state.ids.length;i++)
               {
                  var tex:BitmapData=texture(state.ids[i]);
                  var base:Number=96/Math.max(tex.width,tex.height)*.65;
                  hfxAStatePose106(state.kind,i,t,7,since,pose);
                  drawPart(canvas,state.ids[i],at[0]+pose.x,at[1]+(state.aura ? 25 : 0)+pose.y,base*pose.sx,base*(state.aura ? .45 : 1)*pose.sy,pose.r,1,pose.a,pose.c,false);
               }
            }
            for each(fx in scene.fx)
            {
               var age:Number=t-Number(fx.at);
               if(age<0) continue;
               var life:Number=heroFxLifeA106(fx.kind);
               if(age>=life) continue;
               // As in the core: follow tracks the caster, ground stays put, otherwise the target is tracked.
               var start:Number=Number(fx.at);
               var src:Array=unitAt(scene,fx.src,fx.follow ? t : start);
               var dst:Array=fx.ground!=undefined ? unitAt(scene,fx.ground,start) : unitAt(scene,fx.tgt!=undefined ? fx.tgt : fx.src,fx.follow ? start : t);
               sprites.length=0;
               heroFxSpritesA106(fx.kind,age,src[0],src[1],dst[0],dst[1],int(fx.seed || 1),sprites);
               if(sprites.length>72) sprites.length=72;
               for each(var part:Object in sprites) drawPart(canvas,part.k,part.x,part.y,part.sx,part.sy,part.r,part.fy,part.a,part.c,part.add);
            }
            for each(var pop:Object in scene.texts || [])
            {
               var p:Number=(t-Number(pop.at))/1.1;
               if(p<0 || p>1) continue;
               at=unitAt(scene,pop.unit,t);
               drawText(canvas,pop.text,uint(pop.color),at[0],at[1]-70-30*ease(p),p<.75 ? 1 : 1-(p-.75)/.25,int(pop.size || 22));
            }
            drawText(canvas,String(scene.title),0xFFE7B0,W/2,26,1,19);
            save(canvas,dir.resolvePath(("000"+f).substr(-4)+".png"));
         }
      }
   }
}
'''


def run(cmd, **kw):
    print('>', ' '.join(str(c) for c in cmd[:4]), '...')
    subprocess.run([str(c) for c in cmd], check=True, **kw)


def block(path, marks):
    code = path.read_text('utf-8')
    return code[code.index(marks[0]):code.index(marks[1]) + len(marks[1])]


def harness_source():
    helpers = block(ROOT / 'client/src/hero_fx_core_106.aspart', HELPERS)
    pure = block(ROOT / 'client/src/hero_fx_a_106.aspart', PURE)
    return HARNESS.replace('/*HELPERS*/\n', helpers).replace('/*PURE*/\n', pure)


def export_art(dest):
    """Pull the chibi art out of the hero SWFs the first time."""
    dest.mkdir(parents=True, exist_ok=True)
    missing = [name for name in ART if not (dest / f'{name}.png').exists()]
    if not missing:
        return
    temp = dest / '_export'
    for swf in sorted((ROOT / 'client/resources/app/assets/swfs').glob('hero_*.swf')):
        try:
            run([TOOLS / 'java/bin/java.exe', '-jar', TOOLS / 'ffdec/ffdec.jar', '-cli', '-selectclass', ','.join(missing),
                 '-format', 'sprite:png', '-export', 'sprite', temp, swf])
        except subprocess.CalledProcessError:
            continue
        for name in list(missing):
            found = next(temp.glob(f'*_{name}/1.png'), None)
            if found:
                shutil.copy(found, dest / f'{name}.png')
                missing.remove(name)
        shutil.rmtree(temp, ignore_errors=True)
        if not missing:
            break
    if missing:
        print('No art for', ', '.join(missing), '(cards are drawn without it)')


def render(out, art, scenes):
    build = out / '_build'
    shutil.rmtree(build, ignore_errors=True)
    build.mkdir(parents=True)
    (build / 'HeroFxAHarness.as').write_text(harness_source(), encoding='utf-8')
    sdk = TOOLS / 'air-sdk'
    run([TOOLS / 'java/bin/java.exe', '-Xmx512m', '-Duser.language=en', f'-Dflexlib={sdk / "frameworks"}', '-jar', sdk / 'lib/mxmlc-cli.jar',
         '+configname=air', '-output', build / 'harness.swf', '-default-size', '480', '720',
         f'-source-path={build}', '--', build / 'HeroFxAHarness.as'])
    (build / 'app.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n<application xmlns="http://ns.adobe.com/air/application/51.4">'
        '<id>hero.fx.a.preview</id><filename>HeroFxAPreview</filename><versionNumber>1.0.0</versionNumber>'
        '<initialWindow><content>harness.swf</content><visible>false</visible></initialWindow></application>\n',
        encoding='utf-8')
    run([sdk / 'bin/adl.exe', build / 'app.xml', build, '--', out, art, json.dumps(scenes, ensure_ascii=False), json.dumps(TEXTURES)],
        timeout=1800)


def encode(out, scenes):
    ffmpeg = next((TOOLS / 'pythonlibs/imageio_ffmpeg/binaries').glob('ffmpeg*.exe'))
    for scene in scenes:
        frames = out / scene['id']
        run([ffmpeg, '-loglevel', 'error', '-y', '-framerate', 30, '-i', frames / '%04d.png',
             '-c:v', 'libvpx-vp9', '-b:v', '0', '-crf', 28, '-pix_fmt', 'yuv420p', out / f"{scene['id']}.webm"])
        # Every fourth frame on a contact sheet, for reviewing timing and overlap at a glance.
        run([ffmpeg, '-loglevel', 'error', '-y', '-i', frames / '%04d.png', '-vf',
             "select='not(mod(n\\,4))',scale=160:-1,tile=10x2", '-frames:v', 1, out / f"{scene['id']}-strip.png"])


def index(out):
    cards = ''.join(
        f'<article><h2>{s["title"]}</h2><video src="{s["id"]}.webm" autoplay loop muted playsinline></video>'
        f'<p>{s["note"]}</p></article>' for s in SCENES)
    (out / 'index.html').write_text(f'''<!doctype html><html lang="zh"><meta charset="utf-8">
<title>组 A · 英雄技能代码特效</title><style>
body{{margin:0;background:#11141a;color:#e9e2d2;font:15px "Microsoft YaHei",sans-serif}}
main{{max-width:1600px;margin:24px auto;padding:0 20px}}h1{{font-size:26px;color:#ffd08a;margin:0 0 6px}}
.lead{{color:#b9b3a4;margin:0 0 20px;line-height:1.7}}
.grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:18px}}
article{{background:#1b1f27;border:1px solid #333a48;border-radius:10px;padding:12px}}
h2{{font-size:17px;margin:0 0 8px;color:#ffe0a8}}video{{width:100%;border-radius:6px;display:block;background:#000}}
article p{{color:#b9b3a4;line-height:1.65;font-size:13.5px;margin:10px 0 2px}}
.tex{{margin-top:26px}}.tex img{{width:100%;border-radius:8px;border:1px solid #333a48}}
</style><main><h1>组 A · 英雄技能代码特效</h1>
<p class="lead">娑娜、逆转裁判崔斯特、劫与影分身、兔宝宝提莫、苹果机器人布里茨、足球先生伊泽瑞尔、卡尔玛。画面全部由客户端里同一份特效代码逐帧绘制（AIR 运行，未经手工修饰），贴图在代码里实时画出，不需要图片文件；角色卡片、血条和伤害数字只是示意排布。未在真机/模拟器上运行。</p>
<div class="grid">{cards}</div>
<div class="tex"><h2>代码绘制的贴图</h2><img src="textures.png"></div></main></html>
''', encoding='utf-8')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', type=Path, default=ROOT / 'build/hero-fx-a-preview')
    parser.add_argument('--art', type=Path)
    parser.add_argument('--only', help='comma-separated scene ids')
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    art = (args.art or out / 'art').resolve()
    scenes = [s for s in SCENES if not args.only or s['id'] in args.only.split(',')]
    export_art(art)
    render(out, art, scenes)
    encode(out, scenes)
    index(out)
    print('Preview:', out / 'index.html')


if __name__ == '__main__':
    sys.exit(main())
