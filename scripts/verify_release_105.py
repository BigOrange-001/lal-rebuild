"""Verify upgrade identity, embedded runtime, pinned client and compiled fixes."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import re
import zipfile
import xml.etree.ElementTree as ET
import zlib
from android_manifest import read_binary_manifest_version
from build_client import read_build_config, sha256_file
from build_merged import verify_signature, dump_badging, Badging

ROOT = Path(__file__).resolve().parents[1]


def assert_air_payload(adt_client, merged):
    """Android signatures do not authenticate AIR's inner license/payload pair."""
    names = [n for n in adt_client.namelist() if n=='assets/MainLLOL.swf'
             or n.startswith('assets/META-INF/AIR/')]
    if 'assets/META-INF/AIR/license.txt' not in names:
        raise ValueError('Official ADT client has no AIR license')
    for name in names:
        if merged.read(name)!=adt_client.read(name):
            raise ValueError('Merged APK changed ADT-protected AIR payload: '+name)
    return len(names)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apk',required=True,type=Path)
    parser.add_argument('--previous',required=True,type=Path)
    parser.add_argument('--output',required=True,type=Path)
    parser.add_argument('--adt-client',required=True,type=Path)
    parser.add_argument('--adt-metadata',required=True,type=Path)
    parser.add_argument('--expected-runtime-change',action='append',default=None)
    parser.add_argument('--android-sdk',type=Path,default=Path(os.environ.get('ANDROID_SDK_ROOT') or os.environ.get('ANDROID_HOME') or Path.home()/'AppData/Local/Android/Sdk'))
    args = parser.parse_args()
    tools = args.android_sdk/'build-tools/35.0.0'
    cert = '9ea69ea5377b1d59f0b4b410d581ac21aea510933adcd733ea05913b5aed71af'
    for candidate in (args.apk,args.previous):
        assert cert in verify_signature(tools/'apksigner.bat',candidate).replace(':','').lower()
    before = Badging(dump_badging(tools/'aapt2.exe',args.previous),'installed 1.0.4')
    after = Badging(dump_badging(tools/'aapt2.exe',args.apk),'1.0.5 test')
    assert before.package==after.package=='air.com.meng52.lol.android'
    assert after.version_name=='1.0.5' and after.version_code=='1000005'
    assert int(after.version_code)>int(before.version_code)
    config,version,*_ = read_build_config()
    assert version=='1.0.5'
    assert all(sha256_file(ROOT/s['source'])==s['source_sha256'] for s in config['stages'])
    attestation = json.loads(args.adt_metadata.read_text('utf8'))
    assert attestation['build_mode']=='prebuilt-swf-package'
    assert attestation['apk_sha256']==sha256_file(args.adt_client)
    assert attestation['compiled_swf_sha256']==sha256_file(ROOT/'build/release-1.0.5/MainLLOL.swf')
    with zipfile.ZipFile(args.previous) as old,zipfile.ZipFile(args.apk) as new,zipfile.ZipFile(args.adt_client) as adt:
        protected_air_entries = assert_air_payload(adt,new)
        assert new.read('assets/META-INF/AIR/license.txt')!=old.read('assets/META-INF/AIR/license.txt')
        air_license_sha256 = hashlib.sha256(new.read('assets/META-INF/AIR/license.txt')).hexdigest()
        assert read_binary_manifest_version(new.read('AndroidManifest.xml'))==(1000005,'1.0.5')
        assert new.read('resources.arsc')==adt.read('resources.arsc')
        assert new.read('assets/MainLLOL.swf')==(ROOT/'build/release-1.0.5/MainLLOL.swf').read_bytes()
        descriptor = ET.fromstring(new.read('assets/META-INF/AIR/application.xml'))
        ns = {'a':descriptor.tag.split('}')[0].lstrip('{')}
        assert descriptor.findtext('a:id',namespaces=ns)=='air.com.meng52.lol.android'
        for tag in ['versionNumber','versionLabel']:
            assert descriptor.findtext('a:'+tag,namespaces=ns)=='1.0.5'
        runtime = json.loads(new.read('assets/runtime/runtime-manifest.json'))
        assert runtime['version']=='1.0.5'
        assert new.read('assets/runtime/VERSION').strip()==b'1.0.5'
        for name,digest in runtime['files'].items():
            data = new.read('assets/runtime/'+name)
            assert hashlib.sha256(data).hexdigest()==digest
            assert data==(ROOT/name).read_bytes()
        prior = json.loads(old.read('assets/runtime/runtime-manifest.json'))
        assert set(runtime['files'])==set(prior['files'])
        runtime_changed_files = sorted(n for n in runtime['files'] if runtime['files'][n]!=prior['files'][n])
        expected_changes = sorted(args.expected_runtime_change or ['VERSION'])
        assert runtime_changed_files==expected_changes,(runtime_changed_files,expected_changes)
        alchemy = json.loads(new.read('assets/runtime/config/reconstruction/full-config.json'))['cfg']['system_simple']['equip_alchemy']
        preserved = 0
        for name in old.namelist():
            if name.startswith('assets/assets/'):
                assert new.read(name)==old.read(name),name
                preserved += 1
        for name in adt.namelist():
            if name.startswith(('lib/','res/')) or name=='classes.dex':
                assert new.read(name)==adt.read(name),name
                preserved += 1
        abi = sorted({n.split('/')[1] for n in new.namelist() if n.startswith('lib/') and n.endswith('.so')})
    readback = ROOT/'build/release-1.0.5/readback/scripts'
    equip = (readback/'com/meng52/game/module/equip/Equip.as').read_text('utf8')
    main_source = (readback/'MainLLOL.as').read_text('utf8')
    map_source = (readback/'com/meng52/game/module/map/GameMapTools.as').read_text('utf8')
    panel = (readback/'com/meng52/game/ui/panel/PanelPVEembattleTeam.as').read_text('utf8')
    assert 'getEquipAlchemyRate(my_data,0)' in equip
    assert 'new MovieClip(getRainbowFrameTextures105(),20)' in equip
    assert 'Starling.juggler.remove(clip)' in equip
    assert main_source.count('"1.0.5"')==3
    assert 'originValuesMatch' in map_source
    assert 'previewTeam.slice(0,5)' in panel
    block = re.split(r'\bencoded\s*=\s*\[',equip,maxsplit=1)[1]
    block = re.split(r'\]\s*\.join',block,maxsplit=1)[0]
    raw = zlib.decompress(bytes.fromhex(''.join(re.findall(r'"([0-9a-f]+)"',block))))
    meta = json.loads((ROOT/'client/resources/equipment/rainbow-frame-105.json').read_text('utf8'))
    assert hashlib.sha256(raw).hexdigest()==meta['raw_sha256']
    (ROOT/'build/release-1.0.5/verified-atlas.argb').write_bytes(raw)
    report = dict(version='1.0.5',channel='test',package=after.package,version_code=1000005,
                  source_main_commit='72fda9e4f158d6d6819ef525561b6ca711a053f2',
                  apk_sha256=sha256_file(args.apk),apk_bytes=args.apk.stat().st_size,
                  client_swf_sha256=sha256_file(ROOT/'build/release-1.0.5/MainLLOL.swf'),
                  upgrade_from=before.version_name,same_package=True,same_signing_certificate=True,
                  certificate_sha256=cert,stages_verified=len(config['stages']),
                  official_adt_package_verified=True,protected_air_entries=protected_air_entries,
                  air_license_sha256=air_license_sha256,
                  preserved_native_and_art_entries=preserved,runtime_files_verified=len(runtime['files']),
                  runtime_changed_files=runtime_changed_files,architectures=abi,
                  alchemy_max_star=alchemy['star_lv'],alchemy_terminal_phase=alchemy['phase'].get('8_0'),
                  rainbow_frame=meta,compiled_fixes_verified=True,device_installed=False,
                  old_save_policy='state/local.sqlite3 is retained; legacy SQLite and gzip are supported; 10 MiB is a retention budget, not a read limit')
    args.output.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n','utf8')
    print(json.dumps({k:report[k] for k in ['version','version_code','upgrade_from','same_signing_certificate','apk_bytes','compiled_fixes_verified']}))


if __name__=='__main__':
    main()
