"""Render group B's code-painted hero effects with the game's own effect code.

The pure part of client/src/hero_fx_b_106.aspart (plus the core helpers) is pasted into a
small AIR harness, compiled with amxmlc and run with adl. The harness draws each scene frame
by frame with the exact sprite list the game hands to Starling (and the persistent marks with
the same per-part transforms), and ffmpeg turns the frames into looping videos with an index.

    python scripts/hero_fx_preview_b_106.py [--out DIR] [--art DIR] [--only ID ...]
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
PURE_START = '      // BEGIN HERO FX B PURE 106\n'
PURE_END = '      // END HERO FX B PURE 106\n'
HELPERS_START = '      // BEGIN HERO FX HELPERS 106\n'
HELPERS_END = '      // END HERO FX HELPERS 106\n'
ART = ['A_1215_6', 'A_1203_6', 'A_1211_6', 'A_1206_6', 'A_1138_6', 'A_1103_6', 'A_2013_5',
       'A_1001_5', 'A_1002_5', 'A_1004_5', 'A_1005_5']
WHITE, GREEN, GOLD, RED, PINK, VIOLET = 0xFFFFFF, 0x66FF66, 0xFFD040, 0xFF5040, 0xFF8AA8, 0xC080FF


def unit(art, x, y, team=2, hp=1.0, label=None, show=None):
    row = dict(art=art, team=team, x=x, y=y, hp=hp)
    if label:
        row['label'] = label
    if show is not None:
        row['show'] = show
    return row


def foes(*at):
    return [unit(art, x, y) for art, (x, y) in zip(('A_1001_5', 'A_1002_5', 'A_1005_5'), at)]


SCENES = [
    dict(id='lee', title='李青 · 天音回响 → 回响追击', dur=2.9,
         note='第一次施放：金色掌印裹着音波弧飞出，命中后掌印烙在目标身上，音波向四周散开，脚下留下金色回声环（声波标记）。'
              '同时为队友落下金钟护体：一口半透明金钟罩下、敲响一圈金色声浪，之后队友角落留一枚小金钟。'
              '下一次施放：李青循着回声化作金色残影突进，回声环收拢到目标身上，双重踢击斩痕收尾。',
         units=[unit('A_1215_6', 240, 560, 1, .9, '李青'), unit('A_1004_5', 240, 660, 1, .7)] + foes((240, 300), (196, 214)),
         moves=[dict(unit=0, at=1.62, len=.15, x=240, y=392)],
         fx=[dict(kind='lee_wave', src=0, tgt=2, at=.1, seed=11),
             dict(kind='lee_bell', src=0, tgt=1, at=.4, seed=12),
             dict(kind='lee_dash', src=0, tgt=2, at=1.62, seed=13)],
         marks=[dict(kind='sonic', unit=2, at=.5, to=1.8), dict(kind='ward', unit=1, at=.6, to=1.8)],
         hp=[dict(unit=2, at=.42, value=.7), dict(unit=2, at=1.82, value=.3), dict(unit=1, at=.75, value=.7)],
         texts=[dict(unit=2, at=.42, text='-1680', color=WHITE), dict(unit=1, at=.75, text='护盾', color=GOLD),
                dict(unit=2, at=1.82, text='-3120', color=WHITE)]),
    dict(id='lee_ult', title='李青 · 神龙摆尾（大招）', dur=2.1,
         note='金色龙焰绕着踢腿卷起，两道龙尾弧线横扫目标，命中处炸开金橙冲击与一圈龙焰；被踢飞的敌人拖着彗尾向后飞出，'
              '撞到后排敌人时再爆一圈冲击波，被撞者头顶（血条下方）转起三颗眩晕星。',
         units=[unit('A_1215_6', 240, 470, 1, .85, '李青')] + foes((240, 330), (240, 170)),
         moves=[dict(unit=1, at=.34, len=.3, x=240, y=200)],
         fx=[dict(kind='lee_kick', src=0, tgt=1, at=.1, seed=21),
             dict(kind='lee_crash', src=0, tgt=2, at=.4, seed=22)],
         hp=[dict(unit=1, at=.36, value=.35), dict(unit=2, at=.45, value=.75)],
         texts=[dict(unit=1, at=.36, text='-4510', color=WHITE, size=26), dict(unit=2, at=.45, text='-2205', color=WHITE)]),
    dict(id='ryze', title='男爵瑞兹 · 血契烙印 + 吸血 + 男爵之躯', dur=2.9,
         note='一枚血红符文沿弧线飞出，命中后契约法阵在目标脚下收紧、烙印闪现在身上，之后脚下常驻淡红契约环和小烙印。'
              '若目标早已被诅咒，血珠从敌人身上被抽回瑞兹。行动开始成长时，紫色涌流与上升的烙印，脚下常驻一圈随层数变亮的淡紫环。',
         units=[unit('A_1203_6', 240, 560, 1, .7, '男爵瑞兹')] + foes((240, 300)),
         fx=[dict(kind='ryze_brand', src=0, tgt=1, at=.1, seed=31),
             dict(kind='ryze_leech', src=1, tgt=0, at=.4, seed=32),
             dict(kind='ryze_growth', src=0, tgt=0, at=1.55, seed=33)],
         marks=[dict(kind='contract', unit=1, at=.45, to=2.9), dict(kind='growth', unit=0, at=1.7, to=2.9, count=4)],
         hp=[dict(unit=1, at=.4, value=.66), dict(unit=0, at=.9, value=.82)],
         texts=[dict(unit=1, at=.4, text='-2210', color=VIOLET), dict(unit=0, at=.9, text='+1000', color=GREEN),
                dict(unit=0, at=1.6, text='男爵之躯', color=VIOLET)]),
    dict(id='ryze_ult', title='男爵瑞兹 · 地狱领地（大招）', dur=2.3,
         note='四枚契约法阵从瑞兹脚下沿分路依次铺开到敌阵之后，地面红光连成一片，地狱火沿路升起；每个敌人身上喷出火柱并打上烙印。'
              '瑞兹自身被一层暗红护盾罩住。',
         units=[unit('A_1203_6', 240, 560, 1, .9, '男爵瑞兹')] + foes((240, 330), (200, 240), (282, 168)),
         fx=[dict(kind='ryze_domain', src=0, tgt=1, at=.1, seed=41)] +
            [dict(kind='ryze_hell', src=0, tgt=i + 1, at=.35 + i * .07, seed=42 + i) for i in range(3)],
         marks=[dict(kind='contract', unit=i + 1, at=.7, to=2.3) for i in range(3)],
         hp=[dict(unit=i + 1, at=.5, value=.55) for i in range(3)],
         texts=[dict(unit=i + 1, at=.5 + i * .03, text='-3610', color=VIOLET) for i in range(3)] +
               [dict(unit=0, at=.3, text='护盾', color=GOLD)]),
    dict(id='cait', title='凯特琳 · 通缉射击 + 伏击阵地', dur=2.9,
         note='步枪射击：枪口火光与硝烟，一道细长金白曳光瞬间打到目标，命中处火星前溅；随后红色准星旋转收拢锁定目标，'
              '目标脚下常驻红色地面准星，卡片右上角一枚小准星（通缉）。脚下留下一枚钢制捕兽夹；敌人走进范围时钢牙合拢咬住双脚、火星四溅。',
         units=[unit('A_1211_6', 240, 600, 1, .9, '凯特琳')] + foes((240, 280)),
         moves=[dict(unit=1, at=1.45, len=.3, x=240, y=500)],
         fx=[dict(kind='cait_shot', src=0, tgt=1, at=.1, seed=51),
             dict(kind='cait_wanted', src=0, tgt=1, at=.24, seed=52),
             dict(kind='cait_trap', src=0, tgt=1, at=1.8, seed=53)],
         marks=[dict(kind='wanted', unit=1, at=.55, to=2.9), dict(kind='trap', x=240, y=600, at=.3, to=1.8)],
         hp=[dict(unit=1, at=.22, value=.72), dict(unit=1, at=1.82, value=.5)],
         texts=[dict(unit=1, at=.22, text='-2800', color=WHITE), dict(unit=1, at=1.82, text='-2200', color=WHITE),
                dict(unit=1, at=1.95, text='禁锢', color=GOLD)]),
    dict(id='cait_ult', title='凯特琳 · 落日处决（大招）', dur=1.9,
         note='红色激光瞄准线从枪口拉到目标并逐渐收细，准星旋转收拢；随后一声枪响：大号枪口火光，曳光弹穿透目标继续飞出，'
              '整条弹道留下一道渐隐的金色余辉，命中处碎片顺着弹道方向溅出。',
         units=[unit('A_1211_6', 240, 620, 1, .9, '凯特琳')] + foes((240, 260)),
         fx=[dict(kind='cait_snipe', src=0, tgt=1, at=.1, seed=61)],
         marks=[dict(kind='wanted', unit=1, at=0, to=1.9)],
         hp=[dict(unit=1, at=.8, value=.05)],
         texts=[dict(unit=1, at=.8, text='-6500', color=WHITE, size=28)]),
    dict(id='vayne', title='薇恩 · 穿心连射 → 心印引爆', dur=1.9,
         note='两支银色弩箭先后真的飞出；目标脚下的心形印记随命中从 2 颗变成第 3 颗时，一颗玫红心脏在身上跳一下后裂成两半，'
              '交叉的白色闪光代表真实伤害，碎片四散；薇恩随后回血（通用治疗：绿色光点上升）。',
         units=[unit('A_1206_6', 240, 600, 1, .75, '薇恩')] + foes((240, 300)),
         fx=[dict(kind='vayne_bolt', src=0, tgt=1, at=.1, seed=71),
             dict(kind='vayne_bolt', src=0, tgt=1, at=.24, seed=72),
             dict(kind='vayne_burst', src=0, tgt=1, at=.42, seed=73),
             dict(kind='fb_heal', src=0, tgt=0, at=.45, seed=74)],
         marks=[dict(kind='rings', unit=1, at=0, to=.28, count=1), dict(kind='rings', unit=1, at=.28, to=.42, count=2)],
         hp=[dict(unit=1, at=.28, value=.85), dict(unit=1, at=.42, value=.7), dict(unit=1, at=.58, value=.45),
             dict(unit=0, at=.5, value=.9)],
         texts=[dict(unit=1, at=.28, text='-1200', color=WHITE), dict(unit=1, at=.42, text='-1200', color=WHITE),
                dict(unit=1, at=.6, text='-1920', color=PINK, size=26), dict(unit=0, at=.5, text='+960', color=GREEN)]),
    dict(id='vayne_ult', title='薇恩 · 终极追猎（大招）', dur=2.0,
         note='暗影双翼从身后展开，负面状态化作碎片四散（净化），两圈银色/玫红光环（攻击与闪避提升）；'
              '随后对心印最多的敌人连射三支更大的银色弩箭，每一箭都有玫红交叉闪光。',
         units=[unit('A_1206_6', 240, 610, 1, .8, '薇恩')] + foes((240, 300), (196, 214)),
         fx=[dict(kind='vayne_hunt', src=0, tgt=0, at=.1, seed=81)] +
            [dict(kind='vayne_bolt_ult', src=0, tgt=2, at=.22 + i * .16, seed=82 + i) for i in range(3)],
         marks=[dict(kind='rings', unit=2, at=0, to=2.0, count=2)],
         hp=[dict(unit=2, at=.4 + i * .16, value=.8 - i * .18) for i in range(3)],
         texts=[dict(unit=2, at=.4 + i * .16, text='-1560', color=WHITE) for i in range(3)]),
    dict(id='tahm', title='塔姆 · 快到碗里来 + 金身猛击', dur=2.9,
         note='快到碗里来：粉色长舌从嘴里甩出卷到目标，一副带牙的大嘴在目标身上合拢咬下，溅出河水；舌头随后收回。'
              '金身猛击：先一圈白金净化环，全身镀上一层半透明金壳，脚下两圈嘲讽声浪；再化作金色冲撞砸向目标，地面金色裂纹、河水与碎石溅起。',
         units=[unit('A_1138_6', 240, 560, 1, .9, '塔姆')] + foes((240, 320)),
         fx=[dict(kind='tahm_tongue', src=0, tgt=1, at=.1, seed=91),
             dict(kind='tahm_gold', src=0, tgt=0, at=1.2, seed=92),
             dict(kind='tahm_slam', src=0, tgt=1, at=1.35, seed=93)],
         hp=[dict(unit=1, at=.3, value=.75), dict(unit=1, at=1.55, value=.3)],
         texts=[dict(unit=1, at=.3, text='-1560', color=VIOLET), dict(unit=1, at=.45, text='沉默', color=GOLD),
                dict(unit=0, at=1.2, text='嘲讽', color=GOLD), dict(unit=1, at=1.55, text='-4700', color=WHITE, size=26)]),
    dict(id='malzahar', title='马尔扎哈 · 虚无烈焰 + 虚空召唤 + 虚灵', dur=3.9,
         note='虚无烈焰：马尔扎哈身前聚起虚空光点，本路每个敌人脚下依次裂开紫色裂隙，虚空火焰窜起。'
              '虚空召唤：脚下张开旋转的螺旋传送门，一道紫色裂缝撕开，光点被吸入，虚灵从中走出。'
              '虚灵出手：吐出一枚虚空弹点燃目标，再冒出一串黄绿色毒泡（中毒）。',
         units=[unit('A_1103_6', 240, 600, 1, .9, '马尔扎哈')] + foes((240, 300), (196, 214), (284, 150)) +
               [unit('A_2013_5', 300, 470, 1, 1, '虚灵', show=1.62)],
         fx=[dict(kind='malz_cast', src=0, tgt=0, at=.1, seed=101)] +
            [dict(kind='malz_flame', src=0, tgt=i + 1, at=.22 + i * .06, seed=102 + i) for i in range(3)] +
            [dict(kind='malz_summon', src=0, tgt=4, at=1.5, seed=106),
             dict(kind='void_burn', src=4, tgt=1, at=2.75, seed=107),
             dict(kind='void_venom', src=4, tgt=1, at=2.97, seed=108)],
         hp=[dict(unit=i + 1, at=.5, value=.85) for i in range(3)] + [dict(unit=1, at=2.97, value=.7)],
         texts=[dict(unit=i + 1, at=.5, text='灼烧', color=VIOLET) for i in range(3)] +
               [dict(unit=1, at=2.97, text='-74', color=WHITE)]),
    dict(id='shared', title='通用兜底 · 治疗 / 护盾 / 净化', dur=1.5,
         note='所有没有英雄专属表现的治疗、护盾与净化都用这三种轻量效果：治疗是上升的绿色光点和十字加柔光，'
              '护盾是一层淡金色半透明护罩闪现，净化是白金色光环向外扩散。',
         units=[unit('A_1004_5', 140, 420, 1, .6), unit('A_1001_5', 240, 420, 1, .8), unit('A_1002_5', 340, 420, 1, .9)],
         fx=[dict(kind='fb_heal', src=0, tgt=0, at=.1, seed=111), dict(kind='fb_shield', src=1, tgt=1, at=.1, seed=112),
             dict(kind='fb_cleanse', src=2, tgt=2, at=.1, seed=113)],
         hp=[dict(unit=0, at=.4, value=.8)],
         texts=[dict(unit=0, at=.4, text='+1200', color=GREEN), dict(unit=1, at=.3, text='护盾', color=GOLD),
                dict(unit=2, at=.3, text='净化', color=WHITE)]),
    dict(id='marks', title='常驻状态标记一览', dur=3.0,
         note='小而淡（不超过 0.55 透明度），都避开血条：薇恩心印 1/2/3 颗（满 3 颗跳得更快），瑞兹契约环+烙印，男爵之躯成长环，'
              '凯特琳通缉（地面准星+卡角小准星）与捕兽夹，李青声波回声环，金钟护体的小金钟。',
         units=[unit('A_1001_5', 120, 170, 2, .8), unit('A_1002_5', 240, 170, 2, .8), unit('A_1005_5', 360, 170, 2, .8),
                unit('A_1001_5', 120, 360, 2, .8), unit('A_1002_5', 240, 360, 2, .8), unit('A_1005_5', 360, 360, 2, .8),
                unit('A_1203_6', 120, 560, 1, .8), unit('A_1004_5', 240, 560, 1, .8), unit('A_1211_6', 360, 560, 1, .8)],
         marks=[dict(kind='rings', unit=0, count=1), dict(kind='rings', unit=1, count=2), dict(kind='rings', unit=2, count=3),
                dict(kind='contract', unit=3), dict(kind='wanted', unit=4), dict(kind='sonic', unit=5),
                dict(kind='growth', unit=6, count=6), dict(kind='ward', unit=7), dict(kind='trap', x=360, y=560)],
         labels=[[120, 230, '心印 1'], [240, 230, '心印 2'], [360, 230, '心印 3'], [120, 420, '契约'], [240, 420, '通缉'],
                 [360, 420, '声波'], [120, 620, '成长'], [240, 620, '金钟'], [360, 700, '捕兽夹']]),
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

   // Renders group B's effect code (pasted below) into PNG frames, like Starling would.
   public class HeroFxBHarness extends Sprite
   {
/*CORE*/
      private static const W:int = 480;
      private static const H:int = 720;
      private static const FPS:int = 30;
      private var outDir:File;
      private var arts:Object = {};
      private var textures:Object = {};
      private var pending:int = 0;
      private var scenes:Array;
      private var textureIds:Array;

      public function HeroFxBHarness()
      {
         NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE,onInvoke);
      }
      private function onInvoke(event:InvokeEvent) : void
      {
         outDir=new File(String(event.arguments[0]));
         var job:Object=JSON.parse(String(event.arguments[2]));
         scenes=job.scenes as Array;textureIds=job.textures as Array;
         var artDir:File=new File(String(event.arguments[1]));
         var names:Object={};
         for each(var scene:Object in scenes) for each(var unit:Object in scene.units) names[unit.art]=true;
         for(var name:String in names)
         {
            var file:File=artDir.resolvePath(name+".png");
            if(!file.exists) continue;
            ++pending;
            loadArt(name,file);
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
         if(!textures[id]) textures[id]=heroFxPaintB106(id);
         return textures[id];
      }
      private function renderAll() : void
      {
         var sheet:BitmapData=new BitmapData(1600,900,false,0x101418);
         var x:Number=10;var y:Number=10;var rowH:Number=0;
         for each(var id:String in textureIds)
         {
            var tex:BitmapData=texture(id);
            if(x+tex.width>1590) {x=10;y+=rowH+24;rowH=0;}
            var normal:Boolean=id=="smoke" || id=="tongue" || id=="jaw" || id=="trap" || id=="trapjaw" || id=="bolt";
            sheet.draw(tex,new Matrix(1,0,0,1,x,y),null,normal ? BlendMode.NORMAL : BlendMode.ADD,null,true);
            drawText(sheet,id,0xC0C8D0,x+tex.width/2,y+tex.height+9,1,11);
            x+=tex.width+14;rowH=Math.max(rowH,tex.height);
         }
         save(sheet,outDir.resolvePath("textures.png"));
         for each(var scene:Object in scenes) renderScene(scene);
         NativeApplication.nativeApplication.exit(0);
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
         shape.graphics.beginFill(0x2f4237,.65);shape.graphics.drawRect(70,0,340,H);shape.graphics.endFill();
         for(var y:int=0;y<H;y+=64)
         {
            shape.graphics.beginFill(0x3a5042,.35);shape.graphics.drawRect(74,y+2,332,58);shape.graphics.endFill();
         }
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
      private function visible(scene:Object, index:int, t:Number) : Boolean
      {
         var unit:Object=scene.units[index];
         return unit.show==undefined || t>=Number(unit.show);
      }
      private function drawUnit(canvas:BitmapData, scene:Object, index:int, t:Number) : void
      {
         if(!visible(scene,index,t)) return;
         var unit:Object=scene.units[index];var at:Array=unitAt(scene,index,t);
         var fadeIn:Number=unit.show==undefined ? 1 : Math.min(1,(t-Number(unit.show))/.25);
         var shape:Shape=new Shape();var g:*=shape.graphics;
         var frame:uint=unit.team==1 ? 0x4d8fe0 : 0xd8503c;
         g.beginFill(0x000000,.35);g.drawEllipse(-40,36,80,18);g.endFill();
         g.beginFill(0x1b1f26,1);g.drawRoundRect(-45,-45,90,90,16,16);g.endFill();
         var alpha:ColorTransform=new ColorTransform(1,1,1,fadeIn);
         canvas.draw(shape,new Matrix(1,0,0,1,at[0],at[1]),alpha);
         var art:BitmapData=arts[unit.art];
         if(art)
         {
            var m:Matrix=new Matrix();var scale:Number=86/(art.height*.82);
            m.translate(-art.width/2,-art.height*.52);m.scale(scale,scale);m.translate(at[0],at[1]);
            canvas.draw(art,m,alpha,null,new Rectangle(at[0]-43,at[1]-43,86,86),true);
         }
         shape=new Shape();g=shape.graphics;
         g.lineStyle(4,frame,1);g.drawRoundRect(-45,-45,90,90,16,16);
         var hp:Number=valueAt(scene,"hp",index,t);
         g.lineStyle();g.beginFill(0x111111,1);g.drawRect(-40,-58,80,8);g.endFill();
         g.beginFill(unit.team==1 ? 0x4fd06a : 0xe04a3a,1);g.drawRect(-39,-57,78*hp,6);g.endFill();
         canvas.draw(shape,new Matrix(1,0,0,1,at[0],at[1]),alpha);
         if(unit.label) drawText(canvas,String(unit.label),0xFFE7B0,at[0],at[1]+56,fadeIn,14);
      }
      private function drawText(canvas:BitmapData, text:String, color:uint, x:Number, y:Number, alpha:Number, size:int) : void
      {
         var field:TextField=new TextField();field.autoSize=TextFieldAutoSize.LEFT;
         field.defaultTextFormat=new TextFormat("Microsoft YaHei",size,color,true);field.text=text;
         var holder:Sprite=new Sprite();holder.addChild(field);
         field.filters=[new GlowFilter(0x000000,1,4,4,6,2)];
         canvas.draw(holder,new Matrix(1,0,0,1,x-field.width/2,y-field.height/2),new ColorTransform(1,1,1,alpha),null,null,true);
      }
      private function drawPart(canvas:BitmapData, part:Object, fade:Number) : void
      {
         var tex:BitmapData=texture(part.k);
         if(!tex) return;
         var m:Matrix=new Matrix();
         m.translate(-tex.width/2,-tex.height/2);m.scale(part.sx,part.sy);m.rotate(part.r);m.scale(1,part.fy);m.translate(part.x,part.y);
         var c:uint=part.c;
         var tint:ColorTransform=new ColorTransform(((c>>16)&255)/255,((c>>8)&255)/255,(c&255)/255,Math.max(0,Math.min(1,part.a*fade)));
         canvas.draw(tex,m,tint,part.add ? BlendMode.ADD : BlendMode.NORMAL,null,true);
      }
      private function renderScene(scene:Object) : void
      {
         var dir:File=outDir.resolvePath(String(scene.id));
         if(dir.exists) dir.deleteDirectory(true);
         dir.createDirectory();
         var bg:BitmapData=background();
         var canvas:BitmapData=new BitmapData(W,H,false,0);
         var frames:int=int(Math.ceil(Number(scene.dur)*FPS));
         var sprites:Array=[];var starts:Object={};
         for(var f:int=0;f<frames;f++)
         {
            var t:Number=f/FPS;
            canvas.copyPixels(bg,bg.rect,new flash.geom.Point(0,0));
            // Persistent marks sit under the units, as in the game.
            var drawn:Array=[];
            for each(var mark:Object in scene.marks || [])
            {
               if(mark.at!=undefined && t<Number(mark.at) || mark.to!=undefined && t>=Number(mark.to)) continue;
               var base:Array=mark.unit!=undefined ? unitAt(scene,mark.unit,t) : [Number(mark.x),Number(mark.y)];
               var ids:Array=hfxBMarkIds106(String(mark.kind),Number(mark.count || 0));
               for(var i:int=0;i<ids.length;i++)
               {
                  var mm:Object=hfxBMark106(String(mark.kind),i,Number(mark.count || 0),t,3);
                  drawn.push({k:ids[i],x:base[0]+mm.x,y:base[1]+mm.y,sx:mm.sx,sy:mm.sy,r:mm.r,a:mm.a,c:mm.c,add:mm.add,fy:1});
               }
            }
            for(var u:int=0;u<scene.units.length;u++) drawUnit(canvas,scene,u,t);
            for each(var part:Object in drawn) drawPart(canvas,part,1);
            var effects:Array=scene.fx || [];
            for(var n:int=0;n<effects.length;n++)
            {
               var fx:Object=effects[n];
               var age:Number=t-Number(fx.at);
               if(age<0) continue;
               var life:Number=heroFxLifeB106(fx.kind);
               if(age>=life) continue;
               // As in the core: the source is fixed at the start, the target is tracked.
               if(!starts[n]) starts[n]=unitAt(scene,fx.src,Number(fx.at));
               var src:Array=starts[n];
               var dst:Array=unitAt(scene,fx.tgt,t);
               sprites.length=0;
               heroFxSpritesB106(fx.kind,age,src[0],src[1],dst[0],dst[1],int(fx.seed || 1),sprites);
               if(sprites.length>72) sprites.length=72;
               for each(part in sprites) drawPart(canvas,part,1);
            }
            for each(var pop:Object in scene.texts || [])
            {
               var p:Number=(t-Number(pop.at))/1.1;
               if(p<0 || p>1) continue;
               var at:Array=unitAt(scene,pop.unit,t);
               drawText(canvas,pop.text,uint(pop.color),at[0],at[1]-70-30*ease(p),p<.75 ? 1 : 1-(p-.75)/.25,int(pop.size || 22));
            }
            for each(var label:Array in scene.labels || []) drawText(canvas,String(label[2]),0xE8E0C8,label[0],label[1],1,13);
            drawText(canvas,String(scene.title),0xFFE7B0,W/2,26,1,20);
            save(canvas,dir.resolvePath(("000"+f).substr(-4)+".png"));
         }
      }
   }
}
'''


def run(cmd, **kw):
    print('>', ' '.join(str(c) for c in cmd[:4]), '...')
    subprocess.run([str(c) for c in cmd], check=True, **kw)


def export_art(dest):
    """Pull the chibi art out of the hero SWF the first time (missing classes are skipped)."""
    dest.mkdir(parents=True, exist_ok=True)
    missing = [name for name in ART if not (dest / f'{name}.png').exists()]
    if not missing or (dest / '_tried').exists():
        return
    temp = dest / '_export'
    run([TOOLS / 'java/bin/java.exe', '-jar', TOOLS / 'ffdec/ffdec.jar', '-cli', '-selectclass', ','.join(missing),
         '-format', 'sprite:png', '-export', 'sprite', temp, ROOT / 'client/resources/app/assets/swfs/hero_A.swf'])
    for name in missing:
        found = next(temp.glob(f'*_{name}/1.png'), None)
        if found:
            shutil.copy(found, dest / f'{name}.png')
    shutil.rmtree(temp, ignore_errors=True)
    (dest / '_tried').write_text('1', encoding='utf-8')


def painted():
    code = (ROOT / 'client/src/hero_fx_b_106.aspart').read_text('utf-8')
    block = code[code.index(PURE_START):code.index(PURE_END)]
    return re.findall(r'case "(\w+)": return \[', block)


def harness_source():
    group = (ROOT / 'client/src/hero_fx_b_106.aspart').read_text('utf-8')
    core = (ROOT / 'client/src/hero_fx_core_106.aspart').read_text('utf-8')
    code = core[core.index(HELPERS_START):core.index(HELPERS_END) + len(HELPERS_END)]
    code += group[group.index(PURE_START):group.index(PURE_END) + len(PURE_END)]
    return HARNESS.replace('/*CORE*/\n', code)


def render(out, art, scenes):
    build = out / '_build'
    shutil.rmtree(build, ignore_errors=True)
    build.mkdir(parents=True)
    (build / 'HeroFxBHarness.as').write_text(harness_source(), encoding='utf-8')
    sdk = TOOLS / 'air-sdk'
    run([TOOLS / 'java/bin/java.exe', '-Xmx512m', '-Duser.language=en', f'-Dflexlib={sdk / "frameworks"}', '-jar', sdk / 'lib/mxmlc-cli.jar',
         '+configname=air', '-output', build / 'harness.swf', '-default-size', '480', '720',
         f'-source-path={build}', '--', build / 'HeroFxBHarness.as'])
    (build / 'app.xml').write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n<application xmlns="http://ns.adobe.com/air/application/51.4">'
        '<id>herofx.b.preview</id><filename>HeroFxBPreview</filename><versionNumber>1.0.0</versionNumber>'
        '<initialWindow><content>harness.swf</content><visible>false</visible></initialWindow></application>\n',
        encoding='utf-8')
    job = json.dumps(dict(scenes=scenes, textures=painted()), ensure_ascii=False)
    run([sdk / 'bin/adl.exe', build / 'app.xml', build, '--', out, art, job], timeout=1800)


def encode(out, scenes):
    ffmpeg = next((TOOLS / 'pythonlibs/imageio_ffmpeg/binaries').glob('ffmpeg*.exe'))
    for scene in scenes:
        frames = out / scene['id']
        run([ffmpeg, '-loglevel', 'error', '-y', '-framerate', 30, '-i', frames / '%04d.png',
             '-c:v', 'libvpx-vp9', '-b:v', '0', '-crf', 28, '-pix_fmt', 'yuv420p', out / f"{scene['id']}.webm"])
        run([ffmpeg, '-loglevel', 'error', '-y', '-i', frames / '%04d.png', '-vf',
             "select='not(mod(n\\,4))',scale=192:-1,tile=8x3", '-frames:v', 1, out / f"{scene['id']}-strip.png"])


def index(out):
    cards = ''.join(
        f'<article><h2>{s["title"]}</h2><video src="{s["id"]}.webm" autoplay loop muted playsinline></video>'
        f'<p>{s["note"]}</p></article>' for s in SCENES)
    (out / 'index.html').write_text(f'''<!doctype html><html lang="zh"><meta charset="utf-8">
<title>B 组英雄 · 代码绘制特效</title><style>
body{{margin:0;background:#11140f;color:#efe6cf;font:15px "Microsoft YaHei",sans-serif}}
main{{max-width:1600px;margin:24px auto;padding:0 20px}}h1{{font-size:26px;color:#ffd27a;margin:0 0 6px}}
.lead{{color:#c9bc9a;margin:0 0 20px;line-height:1.7}}
.grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(300px,1fr));gap:18px}}
article{{background:#1b1f19;border:1px solid #3c4330;border-radius:10px;padding:12px}}
h2{{font-size:17px;margin:0 0 8px;color:#ffe2a0}}video{{width:100%;border-radius:6px;display:block;background:#000}}
article p{{color:#c9bc9a;line-height:1.65;font-size:13.5px;margin:10px 0 2px}}
.tex{{margin-top:26px}}.tex img{{width:100%;border-radius:8px;border:1px solid #3c4330}}
</style><main><h1>B 组英雄 · 代码绘制特效</h1>
<p class="lead">塔姆、马尔扎哈与虚灵、李青、男爵瑞兹、凯特琳、薇恩，以及通用治疗/护盾/净化。画面由游戏客户端里同一份特效代码逐帧绘制（AIR 运行，未经手工修饰）；
角色卡片、血条和伤害数字只是示意（找不到立绘的单位只画空卡）。尚未在真机或模拟器上播放过。</p>
<div class="grid">{cards}</div>
<div class="tex"><h2>代码绘制的特效贴图</h2><img src="textures.png"></div></main></html>
''', encoding='utf-8')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out', type=Path, default=ROOT.parent.parent / 'outputs/hero-fx-b-106')
    parser.add_argument('--art', type=Path)
    parser.add_argument('--only', nargs='*')
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    art = (args.art or out / 'art').resolve()
    scenes = [s for s in SCENES if not args.only or s['id'] in args.only]
    export_art(art)
    render(out, art, scenes)
    encode(out, scenes)
    index(out)
    print('Preview:', out / 'index.html')


if __name__ == '__main__':
    sys.exit(main())
