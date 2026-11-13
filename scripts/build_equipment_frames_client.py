"""Compile the equipment frame and alchemy UI changes on a verified client."""
from pathlib import Path
import json
import shutil
from build_client import checked_run, sha256_file

ROOT=Path(__file__).resolve().parents[1]
WORK=ROOT/'build/equipment-rainbow-20261113'


def main():
    WORK.mkdir(parents=True,exist_ok=True)
    parent=ROOT/'build/integrated-playtest-20261113/client-build.json'
    base=parent.parent/'MainLLOL.swf'
    if sha256_file(base)!=json.loads(parent.read_text('utf8'))['outputSwfSha256']:
        raise ValueError('Verified parent SWF hash mismatch')
    config_path=ROOT/'client/build.json'
    manifest=json.loads(config_path.read_text('utf8'))
    sources=['084_Equip.as','058_ItemEquipSelect.as','065_PanelEquipChange.as','061_PanelEquipAlchemyStart.as']
    frozen=[]
    for name in sources:
        stage=next(s for s in manifest['stages'] if s['source']=='client/src/stages/'+name)
        source=ROOT/stage['source']
        digest=sha256_file(source)
        target=WORK/name
        target.write_bytes(source.read_bytes())
        frozen.append((stage,target,digest))
    records=[]
    for stage,source,digest in frozen:
        output=WORK/(source.stem+'.swf')
        log=checked_run([shutil.which('java'),'-Dfile.encoding=UTF-8','-jar',
                         str(ROOT.parents[1]/'tools/ffdec/ffdec.jar'),'-air','-replace',
                         str(base),str(output),stage['class'],str(source)],label=stage['class'])
        (WORK/(source.stem+'.log')).write_text(log,'utf8')
        records.append(dict(source=stage['source'],source_sha256=digest,
                            className=stage['class'],outputSwfSha256=sha256_file(output)))
        base=output
        print('Compiled '+stage['class'],flush=True)
    # Read again before updating only this task's four hashes; other chats may
    # be synchronizing unrelated entries in this shared workspace.
    latest=json.loads(config_path.read_text('utf8'))
    for record in records:
        if sha256_file(ROOT/record['source'])!=record['source_sha256']:
            raise ValueError('Source changed during compilation: '+record['source'])
        next(s for s in latest['stages'] if s['source']==record['source'])['source_sha256']=record['source_sha256']
    config_path.write_text(json.dumps(latest,ensure_ascii=False,indent=2)+'\n','utf8')
    report=dict(completed=True,mode='equipment-frame-component-compile-check',
                parentReportSha256=sha256_file(parent),compiledClasses=records,
                outputSwfSha256=sha256_file(base),packaged=False,installed=False)
    (WORK/'client-build.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n','utf8')
    print('Equipment frame client compile check passed',flush=True)


if __name__=='__main__':
    main()
