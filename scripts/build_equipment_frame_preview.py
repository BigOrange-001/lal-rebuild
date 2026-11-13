"""Render the actual Equip frame draw list using the decoded native textures."""
from pathlib import Path
import json
import math
import unittest
from PIL import Image, ImageDraw, ImageFont
from test_equipment_frames import frame_script
from test_playtest_client import PlaytestClientTests

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT.parents[1]/'outputs/20261113_装备红框与彩虹框_8星终阶/无尽之刃示例'
TEXTURES=ROOT/'build/equipment-frames-20261113'


def tint_vertices(image, colors):
    """Starling vertex tint multiplies texture RGB; alpha is preserved."""
    if colors==[0xffffff]*4:
        return image
    vertices=[((c>>16)&255,(c>>8)&255,c&255) for c in colors]
    result=image.copy()
    pixels=result.load()
    for y in range(image.height):
        v=(y+.5)/image.height
        for x in range(image.width):
            u=(x+.5)/image.width
            rgba=pixels[x,y]
            color=[(vertices[0][c]*(1-u)+vertices[1][c]*u)*(1-v)
                   +(vertices[2][c]*(1-u)+vertices[3][c]*u)*v for c in range(3)]
            pixels[x,y]=tuple(round(rgba[c]*color[c]/255) for c in range(3))+(rgba[3],)
    return result


def render_frame(parts):
    result=Image.new('RGBA',(92,93))
    for part in parts:
        if part.get('quad'):
            scale=8
            w,h=part['width'],part['height']
            piece=tint_vertices(Image.new('RGBA',(round(w*scale),round(h*scale)),(255,255,255,255)),part['colors'])
            if part.get('alpha',1)!=1:
                piece.putalpha(piece.getchannel('A').point(lambda a:round(a*part['alpha'])))
            rotation=part.get('rotation',0)
            dx=w/2-part.get('pivotX',0);dy=h/2-part.get('pivotY',0)
            center_x=part.get('x',0)+dx*math.cos(rotation)-dy*math.sin(rotation)
            center_y=part.get('y',0)+dx*math.sin(rotation)+dy*math.cos(rotation)
            piece=piece.rotate(-math.degrees(rotation),resample=Image.Resampling.BICUBIC,expand=True)
            layer=Image.new('RGBA',(92*scale,93*scale))
            layer.alpha_composite(piece,(round(center_x*scale-piece.width/2),round(center_y*scale-piece.height/2)))
            result.alpha_composite(layer.resize(result.size,Image.Resampling.LANCZOS))
            continue
        if 'resource' in part:
            piece=Image.open(TEXTURES/(part['resource']+'.png')).convert('RGBA')
        else:
            texture=part['texture']
            a=texture['area']
            native=texture['texture']
            if 'pixels' in native:
                source=Image.new('RGBA',(native['width'],native['height']))
                source.putdata([((p>>16)&255,(p>>8)&255,p&255,(p>>24)&255) for p in native['pixels']])
            else:
                source=Image.open(TEXTURES/(native['name']+'.png')).convert('RGBA')
            piece=source.crop((a['x'],a['y'],a['x']+a['width'],a['y']+a['height']))
            piece=tint_vertices(piece,part['colors'])
        result.alpha_composite(piece,(int(part.get('x',0)),int(part.get('y',0))))
    return result


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    script=frame_script()+'''
const rows=[];
for(const star of [5,6,7,8])for(const phase of (star===7?[0,1,2]:[0])){
 unit.equipData={id:'E_1004_5',res:'EQ_1004_5'};unit.my_data={alchemy:[phase,star-5]};
 const icon=unit.getRes();rows.push({star,phase,parts:icon.children[1]?.children||[]});
}
console.log(JSON.stringify(rows));'''
    rows=PlaytestClientTests.run_js(unittest.TestCase(),script)
    (OUT/'客户端边框绘制数据.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),'utf8')
    fonts={s:ImageFont.truetype('C:/Windows/Fonts/msyh.ttc',s) for s in (14,17,20,28)}
    canvas=Image.new('RGB',(1440,430),'#20252A')
    draw=ImageDraw.Draw(canvas)
    draw.text((24,20),'无尽之刃边框示例：5星 → 6星 → 7星 → 8星',font=fonts[28],fill='#F3D6A3')
    draw.text((26,65),'使用游戏内原版无尽之刃插画，展示对应星级与炼金阶段的边框，统一放大2倍。',font=fonts[17],fill='#BEC6CB')
    base=Image.open(TEXTURES/'EQ_1004_50000.png').convert('RGBA')
    base.save(OUT/'无尽之刃_原版图标.png')
    labels=['灰框','白框','绿框','蓝框','紫框','橙金框','红框','彩虹框']
    for index,row in enumerate(rows):
        star,phase=row['star'],row['phase']
        frame=render_frame(row['parts'])
        frame.save(OUT/f'{star}星_阶段{phase}_透明边框.png')
        icon=base.copy()
        icon.alpha_composite(frame)
        icon.save(OUT/f'{star}星_阶段{phase}_装备示例.png')
        if star==8:
            closeup=Image.new('RGB',(432,490),'#20252A')
            closeup_draw=ImageDraw.Draw(closeup)
            closeup_draw.text((25,16),'无尽之刃 · 8星彩虹框',font=fonts[28],fill='#E6BDFF')
            enlarged=icon.resize((368,372),Image.Resampling.LANCZOS)
            closeup.paste(enlarged,(32,68),enlarged)
            closeup_draw.text((58,458),'基础框自带宝石 · 无 +1 / +2',font=fonts[17],fill='#CDD6DF')
            closeup.save(OUT/'无尽之刃_8星彩虹宝石框.png')
            comparison=Image.new('RGB',(900,550),'#20252A')
            compare_draw=ImageDraw.Draw(comparison)
            compare_draw.text((25,14),'无尽之刃：原版角饰与彩虹角饰对照',font=fonts[28],fill='#F3D6A3')
            original=base.copy()
            original.alpha_composite(Image.open(TEXTURES/'UI_equip_box_0003.png').convert('RGBA'))
            for x,label,art in [(30,'原版：金色宝石框',original),(480,'新版：彩虹宝石框',icon)]:
                compare_draw.text((x,62),label,font=fonts[20],fill='#DFD7E9')
                zoom=art.resize((368,372),Image.Resampling.LANCZOS)
                comparison.paste(zoom,(x,103),zoom)
            compare_draw.text((30,498),'相同的连接边、金属镶座、宝石切面与阴影结构',font=fonts[20],fill='#C2CCD6')
            comparison.save(OUT/'无尽之刃_原版与彩虹角饰对照.png')
        x=20+(index%6)*237;y=110+(index//6)*267
        draw.rounded_rectangle((x,y,x+223,y+252),10,fill='#2C3238',outline='#525960')
        large=icon.resize((184,186),Image.Resampling.LANCZOS)
        canvas.paste(large,(x+19,y+12),large)
        title=f'{star}星 · {labels[star-1]}'
        if star>=7 and phase:title+=f' +{phase}'
        note=('原版品质边框' if star<7 else '终阶 · 自带彩虹宝石' if star==8
              else ['基础边框','炼金进阶1 · 金色角饰','炼金进阶2 · 红色角饰'][phase])
        draw.text((x+12,y+202),title,font=fonts[20],fill='#EAD1AD')
        draw.text((x+12,y+232),note,font=fonts[14],fill='#AAB9BC')
    draw.text((26,398),'预留终阶：7星 +0 → +1 → +2 → 8星彩虹框（停止进阶）。当前实际炼金上限仍为7星。',font=fonts[17],fill='#AEB8BE')
    canvas.save(OUT/'装备边框与炼金阶段预览.png')
    print(OUT/'装备边框与炼金阶段预览.png')


if __name__=='__main__':
    main()
