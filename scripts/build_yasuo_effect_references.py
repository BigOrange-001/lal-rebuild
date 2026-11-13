"""Extract original packed sprites for art reference; no game assets are modified."""
from pathlib import Path
import argparse
import shutil
import xml.etree.ElementTree as ET
from PIL import Image

ROOT=Path(__file__).resolve().parents[1]
PROJECT=ROOT.parents[1]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output-dir',type=Path,default=PROJECT/'我的英雄作品/黑夜使者亚索/专属技能特效_20261113')
parser.add_argument('--gameplay-reference',type=Path,help='Optional user-provided gameplay reference image')
args=parser.parse_args()
OUT=args.output_dir
REFS=OUT/'references'
REFS.mkdir(parents=True,exist_ok=True)
atlas=ET.fromstring((PROJECT/'analysis/embedded/11_texture_xml.bin').read_bytes())
sheet=Image.open(next((PROJECT/'analysis/readonly-effect-export').glob('12_texture_png*.png'))).convert('RGBA')
entry=next(e for e in atlas if e.get('name')=='Symbol 39')
x,y,w,h=[int(entry.get(k)) for k in ('x','y','width','height')]
# Native e703 uses this arrow through Symbol 46, rotated ninety degrees.
sprite=sheet.crop((x,y,x+w,y+h))
sprite.save(REFS/'native_strong_arrow.png')
shutil.copy2(PROJECT/'analysis/readonly-effect-armature-components.png',REFS/'native_effect_components.png')
shutil.copy2(ROOT/'config/reconstruction/dragonmancer-kaisa-media/effects/icathian_missile.png',REFS/'kaisa_projectile.png')
if args.gameplay_reference:
    shutil.copy2(args.gameplay_reference,REFS/'nightbringer_gameplay.png')
print(REFS)
