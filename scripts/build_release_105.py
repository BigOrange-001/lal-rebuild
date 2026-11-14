"""Compile the 1.0.5 delta onto the verified battle-power hotfix.

The normal build_merged.py then joins this client with a freshly built manager.
Inputs are explicit, so another checkout or concurrent release is not modified.
"""
from pathlib import Path
import argparse
import json
import shutil
import sys
from build_client import checked_run, sha256_file, read_build_config

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--parent-swf', required=True, type=Path)
    parser.add_argument('--parent-report', required=True, type=Path)
    parser.add_argument('--air-sdk', required=True, type=Path)
    parser.add_argument('--ffdec', required=True, type=Path)
    parser.add_argument('--android-sdk', required=True, type=Path)
    parser.add_argument('--keystore', required=True, type=Path)
    parser.add_argument('--storepass-env', required=True)
    parser.add_argument('--keypass-env', required=True)
    parser.add_argument('--work', type=Path, default=ROOT/'build/release-1.0.5')
    args = parser.parse_args()
    work = args.work.resolve()
    work.mkdir(parents=True,exist_ok=True)
    manifest = ROOT/'client/build.json'
    cfg = json.loads(manifest.read_text('utf8'))
    for stage in cfg['stages']:
        actual = sha256_file(ROOT/stage['source'])
        if actual != stage['source_sha256']:
            raise ValueError('Unpinned stage: '+stage['source'])
    read_build_config()
    parent = json.loads(args.parent_report.read_text('utf8'))
    assert sha256_file(args.parent_swf)==parent['outputSwfSha256']
    current = args.parent_swf.resolve()
    compiled = []
    for name in ['084_Equip.as','136_MainLLOL.as']:
        stage = next(s for s in cfg['stages'] if s['source']=='client/src/stages/'+name)
        frozen = work/name
        frozen.write_bytes((ROOT/stage['source']).read_bytes())
        target = work/(frozen.stem+'.swf')
        log = checked_run([shutil.which('java'),'-Dfile.encoding=UTF-8','-jar',
                           str(args.ffdec.resolve()),'-air','-replace',
                           str(current),str(target),stage['class'],str(frozen)],label=stage['class'])
        (work/(name+'.log')).write_text(log,'utf8')
        current = target
        compiled.append(dict(source=stage['source'],source_sha256=stage['source_sha256'],className=stage['class']))
        print('Compiled '+stage['class'],flush=True)
    final = work/'MainLLOL.swf'
    shutil.copyfile(current,final)
    client = work/'client-1.0.5.apk'
    # AIR validates its own signed license against the application payload.
    # Android re-signing alone cannot make an APK with replaced SWF/XML valid.
    # Always package the final payload through ADT, then preserve its protected
    # files byte-for-byte when the Android manager is merged in.
    adt_metadata = work/'adt-client-metadata.json'
    log = checked_run([sys.executable,'-X','utf8',str(ROOT/'scripts/build_client.py'),
                       '--air-sdk',str(args.air_sdk.resolve()),
                       '--ffdec',str(args.ffdec.resolve()),
                       '--android-sdk',str(args.android_sdk.resolve()),'--android-gradle',
                       '--prebuilt-swf',str(final),'--keystore',str(args.keystore.resolve()),
                       '--storepass-env',args.storepass_env,'--keypass-env',args.keypass_env,
                       '--output',str(client),'--metadata',str(adt_metadata)],label='ADT package final 1.0.5 client')
    (work/'adt-build.log').write_text(log,'utf8')
    for row in compiled:
        assert sha256_file(ROOT/row['source'])==row['source_sha256']
    result = dict(version='1.0.5',mode='verified-incremental-client-build',stages_verified=len(cfg['stages']),
                  parent_swf_sha256=parent['outputSwfSha256'],outputSwfSha256=sha256_file(final),
                  compiledClasses=compiled,adt_metadata=str(adt_metadata),client_apk=str(client),
                  client_apk_sha256=sha256_file(client))
    (work/'client-build.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n','utf8')
    print('1.0.5 client prepared: '+str(client),flush=True)


if __name__=='__main__':
    main()
