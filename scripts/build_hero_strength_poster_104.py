"""Exact-data high-resolution ranking poster; commentator rows are excluded."""
import json
import math
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
from run_hero_strength_104 import load_study_policy

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'outputs/hero-tier-poster-20261030'
SOURCE=ROOT/'outputs/hero-strength-independent-20261030-1000/results.json'
REGULAR='C:/Windows/Fonts/msyh.ttc'
BOLD='C:/Windows/Fonts/msyhbd.ttc'
NUMERIC='C:/Windows/Fonts/consola.ttf'
BG='#080F1D';PANEL='#101B2D';INK='#F0F4FC';MUTED='#91A2BD';LINE='#22324D'
CYAN='#65DCCB';PURPLE='#C5A5FF';GOLD='#F2CE83'


def font(size,bold=False,numeric=False):return ImageFont.truetype(NUMERIC if numeric else BOLD if bold else REGULAR,size)


def main():
    OUT.mkdir(parents=True,exist_ok=True)
    report=json.loads(SOURCE.read_text('utf8'));excluded=set(load_study_policy()['excluded_families'])
    rows=[r for r in report['rows'] if r['aid'].rsplit('_',1)[0] not in excluded]
    groups={m:sorted((dict(r) for r in rows if r['mode']==m),key=lambda r:(-r['win_rate'],-r['avg_damage_share'],r['aid'])) for m in ('mixed','ordinary','skin')}
    assert {m:len(a) for m,a in groups.items()}=={'mixed':125,'ordinary':90,'skin':35}
    for group in groups.values():
        for rank,row in enumerate(group,1):row['display_rank']=rank
    payload=dict(schema='hero-strength-poster-v1',source=str(SOURCE),data_sampling_design=report['sampling_design'],
                 removed_families=sorted(excluded),display_only_filter=True,source_battlefield_included_commentators=True,
                 no_new_simulation=True,akali_statistics_precede_latest_skill_buff=True,groups=groups)
    (OUT/'poster-data.json').write_text(json.dumps(payload,ensure_ascii=False,indent=2),encoding='utf8')
    W=3200;M=80;GAP=80;PW=(W-2*M-GAP)//2;RH=51;TOP=340;TITLE=100;HEAD=64
    total_h=TITLE+HEAD+len(groups['mixed'])*RH
    ordinary_h=TITLE+HEAD+len(groups['ordinary'])*RH
    skin_y=TOP+ordinary_h+40
    H=max(TOP+total_h,skin_y+TITLE+HEAD+len(groups['skin'])*RH)+90
    im=Image.new('RGB',(W,H),BG);d=ImageDraw.Draw(im)

    def text(x,y,s,size=30,color=INK,bold=False,anchor='lt',numeric=False):
        d.text((x,y),s,font=font(size,bold,numeric),fill=color,anchor=anchor)

    d.rectangle((M,65,M+7,230),fill=GOLD)
    text(M+35,65,'英雄强度一图流',76,bold=True)
    text(M+38,180,'125 名英雄',32,color=MUTED)
    text(W-M,93,'1.0.4',40,color=GOLD,bold=True,anchor='rt')
    text(W-M,160,'2026.10.30',27,color=MUTED,anchor='rt',numeric=True)
    d.line((M,265,W-M,265),fill=LINE,width=2)

    def section(x,y,mode,title,accent):
        data=groups[mode];height=TITLE+HEAD+len(data)*RH
        d.rounded_rectangle((x,y,x+PW,y+height),radius=20,fill=PANEL)
        d.rounded_rectangle((x+28,y+28,x+35,y+70),radius=3,fill=accent)
        text(x+56,y+25,title,39,bold=True)
        text(x+PW-30,y+33,f'{len(data)} 名',27,color=accent,anchor='rt')
        hy=y+TITLE
        d.rectangle((x,hy,x+PW,hy+HEAD),fill='#1A2942')
        cols=[('排名',62),('T级',142),('英雄',190),('类别',650),('胜率',805),('平均伤害占比',990),('平均治疗占比',1175),('平均抗伤占比',1360)]
        for label,cx in cols:text(x+cx,hy+HEAD//2,label,24,color='#C4D0E5',bold=True,anchor='lm' if label=='英雄' else 'mm')
        for i,row in enumerate(data):
            yy=hy+HEAD+i*RH;cy=yy+RH//2
            if i%2==1:d.rectangle((x+2,yy,x+PW-2,yy+RH),fill='#142137')
            win=row['win_rate'];tier='T0' if win>=.7 else 'T1' if win>=.6 else 'T2' if win>=.5 else 'T3' if win>=.4 else 'T4'
            tint={'T0':'#F3B985','T1':GOLD,'T2':CYAN,'T3':'#A6B6D1','T4':'#7B8BA7'}[tier]
            rank=row['display_rank']
            text(x+62,cy,str(rank),27,color=GOLD if rank<=3 else MUTED,anchor='mm',numeric=True)
            d.rounded_rectangle((x+111,cy-17,x+173,cy+17),radius=7,fill='#243249')
            text(x+142,cy,tier,25,color=tint,bold=True,anchor='mm')
            name=row['name'];size=30
            assert d.textlength(name,font=font(size))<410,(mode,name)
            text(x+190,cy,name,size,color=INK,anchor='lm')
            text(x+650,cy,'皮肤' if row['category']=='skin' else '普通',25,color=PURPLE if row['category']=='skin' else CYAN,anchor='mm')
            text(x+805,cy,f'{win*100:.2f}%',30,color=INK,anchor='mm',numeric=True)
            for cx,key in [(990,'damage'),(1175,'healing'),(1360,'taken')]:
                text(x+cx,cy,f'{row["avg_"+key+"_share"]*100:.1f}%',28,color='#B6C4DB',anchor='mm',numeric=True)
        return height

    section(M,TOP,'mixed','总榜',GOLD)
    section(M+PW+GAP,TOP,'ordinary','普通英雄榜',CYAN)
    section(M+PW+GAP,skin_y,'skin','皮肤英雄榜',PURPLE)
    path=OUT/'英雄强度一图流.png';im.save(path,optimize=True)
    preview=im.copy();preview.thumbnail((1600,10000));preview.save(OUT/'preview.png',optimize=True)
    for label,box in [('top',(0,0,W,1250)),('bottom',(0,H-1300,W,H)),('skin',(M+PW+GAP,skin_y,M+PW+GAP+PW,min(H,skin_y+800)))]:
        crop=im.crop(box);crop.thumbnail((1600,1800));crop.save(OUT/f'qa-{label}.png')
    print(json.dumps(dict(path=str(path),size=im.size,heroes={m:len(a) for m,a in groups.items()},excluded=sorted(excluded)),ensure_ascii=False))


if __name__=='__main__':main()
