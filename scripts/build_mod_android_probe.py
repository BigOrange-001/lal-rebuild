"""Build an isolated Android AIR Mod QA probe; never installs an application.

The APK has its own application ID, private data and generated debug signer.
It embeds only explicitly supplied QA account settings, never a player DB.
"""
from __future__ import annotations

import argparse
import contextlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path
from xml.etree import ElementTree as ET

from android_manifest import (read_binary_manifest_cleartext, read_binary_manifest_version,
                              _decode_string_pool,_iter_axml_chunks,_read_u32)
from build_client import cli_command, find_adt, java_major, require_file, sha256_file, signature_evidence

ROOT=Path(__file__).resolve().parents[1]
APP_ID="org.bigorange.lal.mods.qa"
AIR_NS="http://ns.adobe.com/air/application/51.4"
DEBUG_ALIAS="lal-mod-qa-debug"


def run(command,label,*,cwd=None,secrets=()):
    completed=subprocess.run(command,cwd=cwd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,check=False)
    output=(completed.stdout or b"").decode("utf-8",errors="replace")
    for secret in secrets:
        if secret:output=output.replace(secret,"<redacted>")
    if completed.returncode or re.search(r"\bSEVERE\b|compilation\s+error|syntax\s+error|compile\s+failed",output,re.I):
        raise RuntimeError(label+" failed (exit %s):\n"%completed.returncode+output[-12000:])
    return output


@contextlib.contextmanager
def ascii_sdk_path(sdk):
    """ADT's Android subprocess needs ASCII SDK paths on Windows.

    Only an unused drive is temporarily created. Existing drive mappings are
    never changed. Package staging itself is under an ASCII system-temp path.
    """
    sdk=Path(sdk).absolute()
    try:str(sdk).encode("ascii");needs_alias=False
    except UnicodeEncodeError:needs_alias=os.name=="nt"
    if not needs_alias:
        yield sdk;return
    drive=next((letter+":" for letter in "ZYXWVUTSRQPONMLKJIEB" if not os.path.exists(letter+":\\")),None)
    if drive is None:raise RuntimeError("No unused drive letter is available for an ASCII AIR SDK alias; pass an existing ASCII --air-sdk path")
    run(["subst",drive,str(sdk)],"temporary AIR SDK alias")
    try:yield Path(drive+"\\")
    finally:run(["subst",drive,"/D"],"release temporary AIR SDK alias")


def descriptor(version):
    # This descriptor is deliberately unrelated to the production application.
    # addAirToAppID=false keeps the exact org.* ID for both manifest and data.
    return f'''<?xml version="1.0" encoding="utf-8"?>
<application xmlns="{AIR_NS}">
  <id>{APP_ID}</id>
  <filename>LALModQA</filename>
  <name>LAL Mod QA (isolated)</name>
  <versionNumber>{version}</versionNumber>
  <versionLabel>{version}-mod-qa</versionLabel>
  <supportedProfiles>mobileDevice</supportedProfiles>
  <initialWindow>
    <content>ModRuntimeProbe.swf</content>
    <softKeyboardBehavior>none</softKeyboardBehavior>
    <aspectRatio>portrait</aspectRatio>
    <autoOrients>false</autoOrients>
    <fullScreen>true</fullScreen>
    <visible>true</visible>
    <renderMode>direct</renderMode>
  </initialWindow>
  <android>
    <addAirToAppID>false</addAirToAppID>
    <manifestAdditions><![CDATA[
      <manifest android:installLocation="auto">
        <uses-sdk android:minSdkVersion="24" android:targetSdkVersion="35" />
        <uses-permission android:name="android.permission.INTERNET" />
        <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
        <uses-permission android:name="android.permission.WAKE_LOCK" />
        <application android:enabled="true" android:hardwareAccelerated="true" android:usesCleartextTraffic="true" android:debuggable="true" />
      </manifest>
    ]]></manifestAdditions>
    <buildArchitectures>armv7,armv8</buildArchitectures>
    <buildLegacyAPK>false</buildLegacyAPK>
    <androidGradlePluginVersion>8.9.1</androidGradlePluginVersion>
    <gradleVersion>8.13</gradleVersion>
    <androidBuildToolsVersion>35.0.0</androidBuildToolsVersion>
    <androidCompileSdkVersion>35</androidCompileSdkVersion>
  </android>
</application>
'''


def native_package_name(data):
    strings,pool_end=_decode_string_pool(data)
    for offset,kind,_,size in _iter_axml_chunks(data,pool_end):
        if kind!=0x0102 or size<36:continue
        if strings[_read_u32(data,offset+20)]!="manifest":continue
        import struct
        start,stride,count=struct.unpack_from("<HHH",data,offset+24)
        for index in range(count):
            position=offset+16+start+index*stride
            if strings[_read_u32(data,position+4)]=="package" and data[position+15]==0x03:
                return strings[_read_u32(data,position+16)]
    raise RuntimeError("Native Android package identity is missing")


def main(argv=None):
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--air-sdk",type=Path,required=True)
    parser.add_argument("--main-swf",type=Path,required=True,help="Raw Android-targeted current client; never the desktop host variant")
    parser.add_argument("--probe-settings",type=Path,required=True,help="Explicit disposable QA account JSON (embedded in this private QA APK)")
    parser.add_argument("--probe-source",type=Path,default=ROOT/"scripts/probes/ModRuntimeProbe.as")
    parser.add_argument("--probe-swf",type=Path,help="Optional already compiled current ModRuntimeProbe")
    parser.add_argument("--android-sdk",type=Path)
    parser.add_argument("--java",default=shutil.which("java"))
    parser.add_argument("--keytool",default=shutil.which("keytool"))
    parser.add_argument("--jarsigner",default=shutil.which("jarsigner"))
    parser.add_argument("--apksigner",type=Path,help="Android SDK apksigner.jar; used for Gradle APK v2/v3 signatures")
    parser.add_argument("--keystore",type=Path)
    parser.add_argument("--alias",default=DEBUG_ALIAS)
    parser.add_argument("--storepass-env")
    parser.add_argument("--keypass-env")
    parser.add_argument("--output",type=Path,default=ROOT/"build/lal-mod-android-qa.apk")
    parser.add_argument("--metadata",type=Path)
    args=parser.parse_args(argv)
    if not args.java or java_major(args.java)<17:raise RuntimeError("Java 17+ is required")
    if not args.keytool:raise RuntimeError("JDK keytool is required")
    apksigner=args.apksigner
    if apksigner is None and args.android_sdk:
        apksigner=args.android_sdk/"build-tools/35.0.0/lib/apksigner.jar"
    apksigner=require_file(apksigner,"Android SDK apksigner.jar") if apksigner else None
    if apksigner is None and not args.jarsigner:raise RuntimeError("Android apksigner or JDK jarsigner is required")
    main_swf=require_file(args.main_swf,"raw Android client SWF")
    settings_file=require_file(args.probe_settings,"QA settings")
    settings=json.loads(settings_file.read_text("utf-8-sig"))
    if not isinstance(settings,dict) or any(not isinstance(settings.get(key),str) or not settings[key] for key in ("account","password")):
        raise ValueError("probe settings must contain an explicit disposable account and password")
    probe_source=require_file(args.probe_source,"probe source")
    if not args.probe_swf and "applicationStorageDirectory" not in probe_source.read_text("utf-8-sig"):
        raise ValueError("Android probe logs and PNGs must use File.applicationStorageDirectory")
    version=(ROOT/"VERSION").read_text("utf-8").strip()
    output=args.output.expanduser().resolve();output.parent.mkdir(parents=True,exist_ok=True)
    metadata=(args.metadata or output.with_suffix(".json")).expanduser().resolve()
    temporary=Path(tempfile.mkdtemp(prefix="lal-mod-android-qa-"))
    if not str(temporary).isascii():raise RuntimeError("ADT staging requires an ASCII system temp directory")
    try:
        package=temporary/"package";package.mkdir()
        shutil.copy2(main_swf,package/"MainLLOL.swf")
        shutil.copytree(ROOT/"client/resources/app/assets",package/"assets")
        (package/"probe.json").write_text(json.dumps(settings,ensure_ascii=False),"utf-8")
        app_descriptor=package/"application.xml";app_descriptor.write_text(descriptor(version),"utf-8")
        with ascii_sdk_path(args.air_sdk) as sdk:
            adt=find_adt(sdk)
            probe_swf=package/"ModRuntimeProbe.swf"
            probe_source_sha=sha256_file(probe_source)
            if args.probe_swf:shutil.copy2(require_file(args.probe_swf,"compiled QA probe"),probe_swf)
            else:
                staged_source=temporary/"ModRuntimeProbe.as";shutil.copy2(probe_source,staged_source)
                probe_source_sha=sha256_file(staged_source)
                run([args.java,"-Dsun.io.useCanonCaches=false","-Dflexlib="+str(sdk/"frameworks"),
                     "-jar",str(sdk/"lib/mxmlc-cli.jar"),"+configname=airmobile",
                     "-debug=false","-static-link-runtime-shared-libraries=true","-target-player=51.0",
                     "-output="+str(probe_swf),str(staged_source)],"compile Android QA probe")
            if args.keystore:
                keystore=require_file(args.keystore,"QA keystore")
                password=os.environ.get(args.storepass_env or "")
                keypass=os.environ.get(args.keypass_env or "") or password
                if not password:raise ValueError("External QA keystore requires --storepass-env; no interactive/personal key prompts")
                alias=args.alias
            else:
                # This is a public debug-only signing identity, never a release key.
                keystore=ROOT/"build/mod-android-qa-debug.p12";keystore.parent.mkdir(exist_ok=True)
                alias=DEBUG_ALIAS;password=keypass="android"
                if not keystore.exists():
                    run([args.keytool,"-genkeypair","-alias",alias,"-keystore",str(keystore),
                         "-storetype","PKCS12","-storepass",password,"-keypass",keypass,
                         "-keyalg","RSA","-keysize","2048","-validity","3650",
                         "-dname","CN=LAL Mod QA Debug Only"],"generate isolated QA debug signer",secrets=(password,))
            staged_key=temporary/"qa-signing.p12";shutil.copy2(keystore,staged_key)
            apk=temporary/"lal-mod-android-qa.apk"
            # ADT accepts 'all' only on its Gradle APK path. Without it the
            # default armv7 filters even an explicit two-architecture descriptor.
            command=cli_command(adt,args.java)+["-package","-target","apk-captive-runtime","-arch","all",
                "-storetype","pkcs12","-keystore",str(staged_key),"-storepass",password,
                "-alias",alias,"-keypass",keypass,str(apk),str(app_descriptor)]
            if args.android_sdk:command.extend(("-platformsdk",str(args.android_sdk.expanduser().resolve())))
            command.extend(("ModRuntimeProbe.swf","MainLLOL.swf","assets","probe.json"))
            try:adt_log=run(command,"package isolated Android QA APK",cwd=package,secrets=(password,keypass))
            finally:staged_key.unlink(missing_ok=True)
            if apksigner:
                verify=run([args.java,"-Duser.language=en","-Duser.country=US","-jar",str(apksigner),"verify","--verbose","--print-certs",str(apk)],"verify QA APK signature")
                if not re.search(r"^Verifies\s*$",verify,re.M):raise RuntimeError("QA APK signature was not verified")
            else:
                verify=run([args.jarsigner,"-J-Duser.language=en","-J-Duser.country=US","-verify","-verbose","-certs",str(apk)],"verify QA APK signature")
                if not re.search(r"jar\s+verified",verify,re.I):raise RuntimeError("QA APK signature was not verified")
            with zipfile.ZipFile(apk) as archive:
                names=set(archive.namelist())
                for required in ("assets/ModRuntimeProbe.swf","assets/MainLLOL.swf","assets/probe.json","assets/assets/swfs/hero_A.swf"):
                    if required not in names:raise RuntimeError("QA APK missing "+required)
                embedded=ET.fromstring(archive.read("assets/META-INF/AIR/application.xml"))
                ns={"air":embedded.tag.split("}")[0].lstrip("{")}
                if embedded.findtext("air:id",namespaces=ns)!=APP_ID:raise RuntimeError("QA identity mismatch; refusing production-ID APK")
                if embedded.findtext("air:initialWindow/air:content",namespaces=ns)!="ModRuntimeProbe.swf":raise RuntimeError("QA initialWindow mismatch")
                native_manifest=archive.read("AndroidManifest.xml")
                if native_package_name(native_manifest)!=APP_ID:raise RuntimeError("Native Android QA identity mismatch; refusing possible original-app replacement")
                if not read_binary_manifest_cleartext(native_manifest):raise RuntimeError("QA APK did not allow local HTTP")
                version_code,version_name=read_binary_manifest_version(native_manifest)
                architectures=sorted(name.split("/")[1] for name in names if re.fullmatch(r"lib/[^/]+/libCore\.so",name))
                if not {"armeabi-v7a","arm64-v8a"}.issubset(architectures):raise RuntimeError("QA APK must contain ARMv7 and ARM64 runtimes: "+str(architectures))
            shutil.copy2(apk,output)
            report={"applicationId":APP_ID,"qaOnly":True,"installsApplication":False,"embeddedDisposableCredentials":True,
                    "apk":str(output),"apkSha256":sha256_file(output),"mainSwf":str(main_swf),"mainSwfSha256":sha256_file(main_swf),
                    "probeSourceSha256":probe_source_sha,"probeSwfSha256":sha256_file(probe_swf),
                    "architectures":architectures,"versionCode":version_code,"versionName":version_name,"cleartextHttp":True,
                    "signing":"isolated-debug-only" if not args.keystore else "caller-supplied-qa-key",
                    "signature":signature_evidence(verify,"apksigner" if apksigner else "jarsigner"),
                    "evidenceDirectory":"/data/user/0/"+APP_ID+"/files/<AIR application storage>/",
                    "backendForward":"adb reverse tcp:8080 tcp:<isolated QA backend port>"}
            metadata.parent.mkdir(parents=True,exist_ok=True);metadata.write_text(json.dumps(report,ensure_ascii=False,indent=2)+"\n","utf-8")
            print(json.dumps({"apk":str(output),"applicationId":APP_ID,"architectures":architectures,"sha256":report["apkSha256"],"metadata":str(metadata)},ensure_ascii=False))
    finally:
        resolved=temporary.resolve()
        if resolved.parent==Path(tempfile.gettempdir()).resolve() and resolved.name.startswith("lal-mod-android-qa-"):
            shutil.rmtree(resolved)
    return 0


if __name__=="__main__":
    try:raise SystemExit(main())
    except Exception as error:
        print("build_mod_android_probe: "+str(error),file=sys.stderr)
        raise SystemExit(1)
