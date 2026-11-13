"""Import approved Kai'Sa art and export the generated combat missile sprite."""
from pathlib import Path
from PIL import Image,ImageOps
import argparse,json,hashlib,shutil,sys
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'server'))
from mod_packages import validate_media
def main():
 p=argparse.ArgumentParser()
 p.add_argument('--art',type=Path,required=True);p.add_argument('--projectile',type=Path,required=True)
 p.add_argument('--plasma-dir',type=Path,required=True,help='Four approved imagegen originals, named plasma_1.png through plasma_4.png')
 a=p.parse_args();media=ROOT/'config/reconstruction/dragonmancer-kaisa-media'
 for d in ['portraits','cards','effects']:(media/d).mkdir(parents=True,exist_ok=True)
 shutil.copy2(a.art/'生图立绘_20261111_v7_特效分离合成/05_神龙尊者卡莎_分层合成_600x300.png',media/'portraits/dragonmancer_kaisa.png')
 shutil.copy2(a.art/'橙卡卡面_20261111_v1/01_神龙尊者卡莎_橙卡_160x160.png',media/'cards/dragonmancer_kaisa.png')
 im=Image.open(a.projectile).convert('RGBA')
 box=im.getchannel('A').point(lambda x:255 if x>=8 else 0).getbbox()
 assert box
 box=(max(0,box[0]-8),max(0,box[1]-8),min(im.width,box[2]+8),min(im.height,box[3]+8))
 sprite=ImageOps.contain(im.crop(box),(256,64),Image.Resampling.LANCZOS)
 sprite.save(media/'effects/icathian_missile.png')
 entries=[]
 marks=[Image.open(a.plasma_dir/f'plasma_{n}.png').convert('RGBA') for n in range(1,5)]
 if any(mark.size!=marks[3].size for mark in marks):raise ValueError('Plasma variants must retain the same canvas')
 boxes=[mark.getchannel('A').point(lambda v:255 if v>=8 else 0).getbbox() for mark in marks]
 if any(box is None for box in boxes):raise ValueError('Empty plasma mark')
 bounds=(max(0,min(b[0] for b in boxes)-8),max(0,min(b[1] for b in boxes)-8),min(marks[3].width,max(b[2] for b in boxes)+8),min(marks[3].height,max(b[3] for b in boxes)+8))
 # One crop and scale for all four states: dark cells retain their footprint.
 for n,mark in enumerate(marks,1):
  mark=ImageOps.contain(mark.crop(bounds),(152,72),Image.Resampling.LANCZOS)
  canvas=Image.new('RGBA',(160,80));canvas.alpha_composite(mark,((160-mark.width)//2,(80-mark.height)//2))
  canvas.save(media/f'effects/plasma_{n}.png')
 rows=[('MOD_DRAGON_KAISA104','portraits/dragonmancer_kaisa.png','portrait'),('MOD_DRAGON_KAISA104_icon0000','cards/dragonmancer_kaisa.png','icon'),('MOD_KAISA_MISSILE104','effects/icathian_missile.png','effect')]+[(f'MOD_KAISA_PLASMA104_{n}',f'effects/plasma_{n}.png','effect') for n in range(1,5)]
 for alias,rel,role in rows:
  f=media/rel;raw=f.read_bytes();v=validate_media(raw,f.name)
  e=dict(alias=alias,kind='image',path=rel,sha256=hashlib.sha256(raw).hexdigest(),bytes=len(raw),width=v['width'],height=v['height'],role=role,packageId='builtin.dragonmancer-kaisa-104',version='1.0.4')
  if role=='icon':e['cardFrame']=v['cardFrame']
  entries.append(e)
 digest=hashlib.sha256(json.dumps(entries,sort_keys=True).encode()).hexdigest()
 for e in entries:e['contentDigest']=digest
 (media/'manifest.json').write_text(json.dumps(dict(digest=digest,assets=entries),ensure_ascii=False,indent=2),'utf-8')
 print(json.dumps({'digest':digest,'images':len(entries),'missileSize':sprite.size}))
if __name__=='__main__':main()
