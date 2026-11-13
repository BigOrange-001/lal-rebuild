"""Render generated assets with the imported native e703 size/motion, not a gameplay recording."""
from pathlib import Path
import json
import math
import shutil
import zipfile
from PIL import Image,ImageDraw,ImageFont

ROOT=Path(__file__).resolve().parents[1]
PROJECT=ROOT.parents[1]
MEDIA=ROOT/'config/reconstruction/nightbringer-yasuo-media'
OUT=PROJECT/'我的英雄作品/黑夜使者亚索/专属技能特效_20261113'
layout=json.loads((MEDIA/'manifest.json').read_text('utf8'))['buffLayout']
vortex=[Image.open(MEDIA/f'effects/night_vortex_{i}.png').convert('RGBA') for i in range(4)]
wisps=[Image.open(MEDIA/f'effects/night_buff_{i}.png').convert('RGBA') for i in range(4)]
original=Image.open(OUT/'references/native_strong_arrow.png').convert('RGBA').rotate(-90,expand=True)
card=Image.open(MEDIA/'cards/nightbringer_yasuo.png').convert('RGBA')
enemy=Image.open(ROOT/'config/reconstruction/dragonmancer-kaisa-media/cards/dragonmancer_kaisa.png').convert('RGBA')
font=Path('C:/Windows/Fonts/msyh.ttc')
fonts={n:ImageFont.truetype(str(font),n) for n in (13,15,17,22,28)}


def sprite(target,image,x,y,sx=1,sy=1,alpha=1):
    width=max(1,round(image.width*abs(sx)));height=max(1,round(image.height*abs(sy)))
    image=image.resize((width,height),Image.Resampling.LANCZOS)
    if sx<0:image=image.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    if sy<0:image=image.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    if alpha<1:image.putalpha(image.getchannel('A').point(lambda a:round(a*max(0,alpha))))
    target.alpha_composite(image,(round(x-width/2),round(y-height/2)))


def hero(target,image,x,y):
    # Native card frame is 94x94; map the PNG's embedded 112x128 frame to it.
    image=image.resize((round(160*94/112),round(160*94/128)),Image.Resampling.LANCZOS)
    target.alpha_composite(image,(round(x-image.width/2),round(y-image.height/2)))


def buff(target,x,y,age,native=False):
    for slot in layout['slots']:
        frame=(age%slot['cycle'])/slot['cycle']*slot['frames']
        keys=slot['keys'];index=max(i for i,k in enumerate(keys) if frame>=k['at'])
        a=keys[index];b=keys[(index+1)%len(keys)]
        if not a['visible']:continue
        stop=b['at'] if b['at']>a['at'] else slot['frames']
        t=(frame-a['at'])/max(.001,stop-a['at']) if b['visible'] else 0
        rise=a['y']+(b['y']-a['y'])*t
        stretch=a['stretch']+(b['stretch']-a['stretch'])*t
        alpha=a['alpha']+(b['alpha']-a['alpha'])*t
        texture=original if native else wisps[int(frame/slot['frames']*4)%4]
        sprite(target,texture,x+slot['x'],y+slot['y']+rise*slot['scaleY'],
               slot['scaleX'],slot['scaleY']*stretch,slot['alpha']*alpha)


def render(age):
    image=Image.new('RGBA',(960,720),(24,28,32,255));d=ImageDraw.Draw(image)
    d.text((24,16),'黑夜使者亚索 · 专属技能特效',font=fonts[28],fill='#F0CF9F')
    d.text((25,58),'素材动画合成预览；卡牌内框按94像素，Buff沿用原生e703尺寸与动作',font=fonts[15],fill='#AEB8BC')
    d.rounded_rectangle((20,94,540,696),12,fill='#292D30',outline='#545047')
    d.rounded_rectangle((558,94,940,696),12,fill='#292D30',outline='#545047')
    d.text((36,108),'黑夜剑气 · 单个旋风贯穿本路',font=fonts[22],fill='#E8D6BF')
    for x in (110,280,450):
        d.rectangle((x-61,150,x+61,680),fill='#403B30')
        d.line((x-62,150,x-62,680),fill='#66543D',width=2)
        d.line((x+62,150,x+62,680),fill='#66543D',width=2)
    # Idle neighbouring lanes show the size relative to existing battle cards.
    hero(image,enemy,110,290);hero(image,enemy,450,350)
    phase=age%2.4
    dash=min(1,max(0,phase/.25))
    hero_pos=2400-400*dash
    y=lambda p:170+p*.195
    hero(image,card,280,y(hero_pos))
    launch=.28
    for i,pos in enumerate((1400,1100,800)):
        hit=launch+(2000-pos)/2400
        recoil=min(1,max(0,(phase-hit)/.3))
        hero(image,enemy,280,y(pos-300*recoil))
        if 0<phase-hit<.48:
            text='225%' if i==0 else '135%'
            d=ImageDraw.Draw(image)
            d.text((330,y(pos)-30-(phase-hit)*36),text,font=fonts[17],fill='#FF9B73')
    if launch<=phase<=launch+2000/2400:
        progress=(phase-launch)*2400
        frame=int((phase-launch)*12)%4
        sprite(image,vortex[frame],280,y(2000-progress),96/256,96/256)
    d=ImageDraw.Draw(image)
    d.text((574,112),'融入黑夜 · 与原版Buff同尺寸',font=fonts[22],fill='#E8D6BF')
    d.text((586,165),'原版加攻击',font=fonts[17],fill='#B8C3C5')
    d.text((780,165),'亚索红黑版',font=fonts[17],fill='#EFAD9A')
    hero(image,card,650,285);hero(image,card,845,285)
    buff(image,650,285,age,True);buff(image,845,285,age,False)
    d=ImageDraw.Draw(image)
    d.text((578,400),'尺寸、挂载层、偏移与伸展曲线取自原版',font=fonts[15],fill='#AAB4B8')
    d.text((578,428),'仅替换流光素材，保持卡面中心可辨认',font=fonts[15],fill='#AAB4B8')
    d.text((578,490),'旋风：四帧循环，按接触顺序结算',font=fonts[15],fill='#D2BDA5')
    d.text((578,518),'同一名敌人一次命中，击退300距离',font=fonts[15],fill='#D2BDA5')
    d.text((578,560),'透明PNG已接入源码；此预览不是实机录像',font=fonts[13],fill='#879397')
    return image.convert('RGB')


frames=[render(i/25) for i in range(60)]
frames[16].save(OUT/'特效尺寸与接触预览.png')
frames[0].save(OUT/'特效动画预览.gif',save_all=True,append_images=frames[1:],duration=40,loop=0,optimize=True)
target=OUT/'game-assets'
target.mkdir(exist_ok=True)
shutil.copytree(MEDIA/'effects',target/'effects',dirs_exist_ok=True)
shutil.copy2(MEDIA/'manifest.json',target/'manifest.json')
(OUT/'使用说明.txt').write_text('内置生图工具生成两份四帧透明素材，原图及提示词保留于本工程。\n'
    '旋风：256×256四帧，客户端按现有特效96逻辑单位显示，单个弹体贯穿本路。\n'
    f'融入黑夜：{layout["width"]}×{layout["height"]}四帧，画布取自原生e703旋转后的Symbol 39，运行时沿用原生坐标、缩放及伸展动画。\n'
    'game-assets/manifest.json同时记录12条原生子流光的坐标与动画数据。\n'
    'GIF和PNG为素材合成预览，不是游戏内试玩录像。本次未打包安装。\n','utf8')
archive=PROJECT/'outputs/20261113_黑夜亚索_旋风与融入黑夜特效.zip'
with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED) as zipped:
    for file in OUT.rglob('*'):
        if file.is_file():zipped.write(file,file.relative_to(OUT))
print(json.dumps(dict(preview=str(OUT/'特效动画预览.gif'),archive=str(archive),nativeBuffCanvas=[layout['width'],layout['height']]),ensure_ascii=False))
