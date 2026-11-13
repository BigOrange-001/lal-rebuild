"""Import the previously approved transparent portrait and unbadged orange card."""
from pathlib import Path
import hashlib
import json
import shutil
import sys
import xml.etree.ElementTree as ET
from PIL import Image,ImageOps

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'server'))
from mod_packages import validate_media

ART = ROOT.parents[1] / 'outputs/20261110_黑夜使者亚索_Codex自制v4_透明动态立绘与卡面'
MEDIA = ROOT / 'config/reconstruction/nightbringer-yasuo-media'
entries = []
assets = [('portraits', 'MOD_NIGHT_YASUO104', 'portrait'),
          ('cards', 'MOD_NIGHT_YASUO104_icon0000', 'icon')]
WORK=ROOT.parents[1]/'我的英雄作品/黑夜使者亚索/专属技能特效_20261113'


def animation_frames(path, size):
    sheet=Image.open(path).convert('RGBA')
    if sheet.getchannel('A').getextrema()!=(0,255):
        raise ValueError('Generated VFX must retain true transparent alpha')
    # Equal grid cells, then one common crop/scale for every animation frame.
    # A shared crop preserves the generator's anchors and avoids frame pumping.
    parts=[]
    edge=max((sheet.width+1)//2,(sheet.height+1)//2)
    for row in range(2):
        for col in range(2):
            box=(col*sheet.width//2,row*sheet.height//2,(col+1)*sheet.width//2,(row+1)*sheet.height//2)
            part=sheet.crop(box)
            cell=Image.new('RGBA',(edge,edge))
            cell.alpha_composite(part,((edge-part.width)//2,(edge-part.height)//2))
            parts.append(cell)
    bounds=[p.getchannel('A').point(lambda a:255 if a>=8 else 0).getbbox() for p in parts]
    if any(b is None for b in bounds):raise ValueError('Empty animation cell')
    union=(min(b[0] for b in bounds),min(b[1] for b in bounds),max(b[2] for b in bounds),max(b[3] for b in bounds))
    result=[]
    for cell in parts:
        sprite=ImageOps.contain(cell.crop(union),size,Image.Resampling.LANCZOS)
        output=Image.new('RGBA',size)
        output.alpha_composite(sprite,((size[0]-sprite.width)//2,(size[1]-sprite.height)//2))
        result.append(output)
    return result


def native_buff_layout():
    project=ROOT.parents[1]
    skeleton=ET.fromstring((project/'analysis/embedded/13_skeleton_xml.bin').read_bytes())
    armatures={a.get('name'):a for a in skeleton.iter('armature')}
    native=armatures['effect/e703']
    parent=native.find('animation')
    timelines={t.get('name'):t for t in parent.findall('timeline')}
    slots=[]
    for slot in native.find('skin').findall('slot'):
        display=slot.find('display')
        if not display.get('name').startswith('Symbol 46'):continue
        track=timelines[slot.get('name')]
        parent_frame=next(f for f in track.findall('frame') if f.find('transform') is not None)
        tr=parent_frame.find('transform')
        color=parent_frame.find('colorTransform')
        child=armatures[display.get('name')].find('animation')
        keys=[];frame=0
        first=child.find('timeline/frame/transform')
        base_y=float(first.get('y',0))
        for node in child.find('timeline').findall('frame'):
            transform=node.find('transform')
            tint=node.find('colorTransform')
            visible=node.get('displayIndex')!='-1'
            keys.append(dict(at=frame,visible=visible,y=(float(transform.get('y',base_y))-base_y) if transform is not None else 0,
                             stretch=float(transform.get('scX',1)) if transform is not None else 1,
                             alpha=float(tint.get('aM',100))/100 if tint is not None else 1))
            frame+=int(node.get('duration',1))
        slots.append(dict(x=float(tr.get('x',0)),y=float(tr.get('y',0)),
                          scaleX=float(tr.get('scX',1)),scaleY=float(tr.get('scY',1)),
                          alpha=float(color.get('aM',100))/100 if color is not None else 1,
                          frames=frame,cycle=frame/float(skeleton.get('frameRate',30))*float(child.get('scale',1)),keys=keys))
    # Symbol 39 is rotated 90 degrees inside e703's Symbol 46. Its upright
    # dimensions and the parent's authored .69 vertical scale are preserved.
    reference=Image.open(WORK/'references/native_strong_arrow.png')
    return dict(source='native effect/e703 (strong)',width=reference.height,height=reference.width,
                anchor='native m_buff',runtimeScale=1,slots=slots)


layout=native_buff_layout()
effect_dir=MEDIA/'effects'
effect_dir.mkdir(exist_ok=True,parents=True)
for kind,source,size,prefix in (
    ('vortex','vortex-sheet.png',(256,256),'MOD_NIGHT_YASUO_VORTEX104_'),
    ('buff','buff-sheet.png',(layout['width'],layout['height']),'MOD_NIGHT_YASUO_BUFF104_')):
    for index,frame in enumerate(animation_frames(WORK/'generated'/source,size)):
        path=effect_dir/f'night_{kind}_{index}.png'
        frame.save(path)
        assets.append(('effects',prefix+str(index),'effect',path))

for item in assets:
    folder,alias,role=item[:3]
    if role=='effect':
        target=item[3]
    else:
        target = MEDIA / folder / 'nightbringer_yasuo.png'
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ART / folder / target.name, target)
    raw = target.read_bytes()
    validation = validate_media(raw, target.name)
    entry = dict(alias=alias, kind='image', path=target.relative_to(MEDIA).as_posix(),
                 sha256=hashlib.sha256(raw).hexdigest(), bytes=len(raw),
                 width=validation['width'], height=validation['height'], role=role,
                 packageId='builtin.nightbringer-yasuo-104', version='1.0.4')
    if role == 'icon':
        entry['cardFrame'] = validation['cardFrame']
    entries.append(entry)
digest = hashlib.sha256(json.dumps(entries, sort_keys=True).encode()).hexdigest()
for entry in entries:
    entry['contentDigest'] = digest
(MEDIA / 'manifest.json').write_text(json.dumps(dict(digest=digest,assets=entries,buffLayout=layout), ensure_ascii=False, indent=2), 'utf-8')
shutil.copy2(MEDIA/'manifest.json',WORK/'素材清单.json')
print(json.dumps(dict(images=len(entries), digest=digest)))
