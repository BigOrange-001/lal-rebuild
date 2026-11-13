"""Compile-check Yasuo against the verified playable client, preserving current HUD."""
from pathlib import Path
import hashlib
import json
import shutil
import sys
from build_client import checked_run, sha256_file

ROOT=Path(__file__).resolve().parents[1]
WORK=ROOT/'build/nightbringer-yasuo-20261113'
WORK.mkdir(parents=True,exist_ok=True)
base=ROOT/'build/vital-bar-20261113/fixed-quarters/Avatar.swf'
parent=base.parent/'client-build.json'
report=json.loads(parent.read_text('utf-8'))
if sha256_file(base)!=report['outputSwfSha256']:
    raise ValueError('Verified parent SWF hash mismatch')
manifest=json.loads((ROOT/'client/build.json').read_text('utf-8'))
sources=['client/src/stages/178_ProgressBar.as','client/src/stages/137_Avatar.as']
records=[]
for source in sources:
    stage=next(s for s in manifest['stages'] if s['source']==source)
    frozen=WORK/Path(source).name
    raw=(ROOT/source).read_bytes()
    digest=hashlib.sha256(raw).hexdigest()
    if digest!=stage['source_sha256']:
        raise ValueError('Source hash is not synchronized: '+source)
    frozen.write_bytes(raw)
    output=WORK/(stage['class'].rsplit('.',1)[-1]+'.swf')
    log=checked_run([shutil.which('java'),'-Dfile.encoding=UTF-8','-jar',
                     str(ROOT.parents[1]/'tools/ffdec/ffdec.jar'),'-air','-replace',
                     str(base),str(output),stage['class'],str(frozen)],label=stage['class'])
    (WORK/(frozen.stem+'.log')).write_text(log,'utf-8')
    records.append(dict(source=source,source_sha256=digest,className=stage['class'],
                        outputSwfSha256=sha256_file(output)))
    base=output
    print('Compiled '+stage['class'],flush=True)
result=dict(completed=True,mode='component-compile-check',parentReportSha256=sha256_file(parent),
            outputSwfSha256=sha256_file(base),compiledClasses=records,
            packaged=False,installed=False)
(WORK/'client-build.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n','utf-8')
print('Yasuo client compile check passed',flush=True)
