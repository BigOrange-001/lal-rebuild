"""Offline visual preview that runs the actual AS projectile method after syntax translation."""
from pathlib import Path
import re,sys,shutil,json
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'scripts'))
from test_skin_revision_native_104 import balanced
def build(out):
 out.mkdir(parents=True,exist_ok=True);assets=out/'preview-assets';assets.mkdir(exist_ok=True)
 media=ROOT/'config/reconstruction/dragonmancer-kaisa-media'
 shutil.copy2(media/'effects/icathian_missile.png',assets/'missile.png')
 shutil.copy2(media/'cards/dragonmancer_kaisa.png',assets/'kaisa.png')
 refs=ROOT.parents[1]/'outputs/orange-heroes-20261026/cards'
 for n,key in enumerate(['A_1019_6','A_1021_6','A_1015_6']):shutil.copy2(refs/(key+'.png'),assets/('target'+str(n)+'.png'))
 source=(ROOT/'client/src/dragonmancer_kaisa.aspart').read_text('utf-8')
 a=source.index('      private function kaisaProjectile104(');start=source.index('{',a)
 method=source[start+1:balanced(source,start)]
 method=re.sub(r'\bvar (\w+)\s*:[\w.<>]+',r'var \1',method)
 method=re.sub(r'\s+as\s+\w+','',method)
 method=method.replace('function():void','function()')
 template=Path(__file__).with_name('dragonmancer_kaisa_effect_preview.html').read_text('utf-8')
 html=template.replace('/*NATIVE_PROJECTILE_METHOD*/',method)
 (out/'技能弹体飞行预览.html').write_text(html,'utf-8')
 print('Native projectile visual preview saved:',out)
if __name__=='__main__':
 build(ROOT.parents[1]/'我的英雄作品/神龙尊者卡莎/制作实现_20261112')
