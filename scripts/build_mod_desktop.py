"""Package the compiled Mod client and current server as a portable Windows host.

No player save or installation is read. Supply a clean portable Python runtime
and frozen site-packages; SDK/FFDec are external build dependencies.
"""
from __future__ import annotations

import argparse
import json
import shutil
import zipfile
from pathlib import Path

from build_client import checked_run, cli_command, read_build_config, sha256_file

ROOT = Path(__file__).resolve().parents[1]


def replace_method(source, name, body):
    import re
    match = re.search(r"(?:public|private|protected) (?:static )?function " + re.escape(name) + r"\([^)]*\)\s*:\s*\w+\s*\{", source)
    if not match:
        raise ValueError("Missing desktop adapter target: " + name)
    start = source.index("{", match.start())
    depth, quote, escaped, pos = 1, None, False, start + 1
    while pos < len(source) and depth:
        char = source[pos]
        if quote:
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
        elif char in "\"'":
            quote = char
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
        pos += 1
    if depth:
        raise ValueError("Unbalanced desktop adapter target: " + name)
    return source[:start + 1] + "\n" + body + "\n      " + source[pos - 1:]


def desktop_sources(target):
    main = (ROOT / "client/src/stages/136_MainLLOL.as").read_text("utf-8-sig")
    main = replace_method(main, "LoadXML", "         initFun();")
    main = replace_method(main, "checkCapabilities", '''         MainConfig.$isAir = true;
         MainConfig.$isWindows = true;
         MainConfig.$isDebug = false;
         MainConfig.$hideFPS = true;
         setAirStage();''')
    main = replace_method(main, "setAirStage", '''         GlobalData.$fullScreenWidth = stage.stageWidth;
         GlobalData.$fullScreenHeight = stage.stageHeight;''')
    main = main.replace('NativeApplication.nativeApplication.systemIdleMode = "keepAwake";', "")
    main = main.replace('Starling.handleLostContext = false;', 'Starling.handleLostContext = true;')
    # The Windows host uses its own application identity and never touches the
    # legacy C:/lol_ini.xml or another installed game's local preferences.
    config = (ROOT / "client/src/stages/005_MainConfig.as").read_text("utf-8-sig")
    config = config.replace("{", "{\n   import flash.filesystem.FileStream;", 1)
    version = (ROOT / "VERSION").read_text("utf-8").strip()
    config = replace_method(config, "getServiceURLByPF", '''         $appAssetsDir = File.applicationDirectory;
         $appAssetsDirString = "";
         gameSpecial = false;
         pf_tw_android_full = false;
         classANETools = classStoreIOS = classMainExtension = classNetworkInfo = classTalkClass = classInmobileClass = classIOSmacID = classIOSLocalNotification = classIOS_tl_event = null;
         $gameLanguage = "cn";
         GlobalLocalStore.$pf_type_curr = "local";
         SendAndSelect.$MACID = "";
         var stream:FileStream = new FileStream();
         stream.open(File.applicationDirectory.resolvePath("bootstrap.json"),"read");
         var launch:Object = JSON.parse(stream.readUTFBytes(stream.bytesAvailable));
         stream.close();
         var port:int = int(launch.port);
         if(port < 1024 || port > 65535 || launch.version != "VERSION_VALUE") throw new Error("请从本包的启动脚本进入游戏。");
         VERSION_CURR = "VERSION_VALUE";
         $SERVER_ADDRESS = "http://127.0.0.1:" + port;
         $canPay = true;
         if($font.length > 0) GlobalConfig.FONT_0 = GlobalConfig.FONT_1 = $font;
         server_address_group();'''.replace("VERSION_VALUE", version))
    rows = []
    for name, source in (("MainConfig", config), ("MainLLOL", main)):
        file = target / (name + ".as")
        file.write_text(source, "utf-8")
        rows.append((name, file))
    return rows


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--swf", type=Path, required=True)
    parser.add_argument("--air-sdk", type=Path, required=True)
    parser.add_argument("--ffdec", type=Path, required=True)
    parser.add_argument("--java", required=True)
    parser.add_argument("--python-runtime", type=Path, required=True)
    parser.add_argument("--python-deps", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True, help="New output directory")
    args = parser.parse_args()
    _, version, _, _, _ = read_build_config()
    output = args.output.resolve()
    if output.exists():
        raise FileExistsError("Output already exists; use a fresh destination")
    output.mkdir(parents=True)
    generated = output / "build-sources"
    generated.mkdir()
    current = args.swf.resolve()
    adapted = []
    for name, source in desktop_sources(generated):
        destination = generated / (name + ".swf")
        checked_run(cli_command(args.ffdec.resolve(), args.java) + ["-air", "-replace", str(current), str(destination), name, str(source)], label="Windows " + name)
        adapted.append({"class": name, "source_sha256": sha256_file(source), "swf_sha256": sha256_file(destination)})
        current = destination
    package = output / "lal-mod-windows"
    app = package / "app"
    app.mkdir(parents=True)
    shutil.copy2(current, app / "MainLLOL.swf")
    shutil.copytree(ROOT / "client/resources/app/assets", app / "assets")
    shutil.copytree(ROOT / "server", package / "server", ignore=shutil.ignore_patterns("__pycache__", "test_*", "*.sqlite*", "*.log"))
    shutil.copytree(ROOT / "config", package / "config")
    shutil.copytree(ROOT / "examples/mods", package / "examples/mods")
    shutil.copytree(ROOT / "schemas", package / "schemas")
    shutil.copytree(ROOT / "docs", package / "docs")
    shutil.copy2(ROOT / "VERSION", package / "VERSION")
    shutil.copy2(ROOT / "README.md", package / "README.md")
    shutil.copy2(ROOT / "DEPLOYMENT.md", package / "DEPLOYMENT.md")
    (package / "scripts").mkdir()
    shutil.copy2(ROOT / "scripts/mod_tools.py", package / "scripts/mod_tools.py")
    (package / "使用说明.md").write_text('''# Windows Mod 开发包

解压到可写目录后双击“开始游戏.cmd”，在游戏中注册或登录本地账号。首次运行会创建本包的 `data/local.sqlite3` 和 `data/mods`；更新时先关闭游戏并备份整个 `data` 目录。

系统设置 → Mod 管理可按存档启用内容。安装是全局的，启用和玩法开关按存档保存。把 `.heropack` 放进 `data/mods/inbox`，再点“检查目录”；也可使用“导入包”文件选择器。导入成功后还需要选择启用、预览、确认并重新进入。

新增英雄包缺失时保留进度和装备并冻结；恢复相同 UUID、版本与内容摘要的包可关联原实例。请勿手工清空 `registry.json`。恢复或迁移前阅读 `docs/mod-api.md` 和 `DEPLOYMENT.md`。

作者工具已经包含在包内，可在本目录 PowerShell 执行：

```powershell
.\\runtime\\python.exe -B .\\scripts\\mod_tools.py validate .\\examples\\mods\\new-minimal.heropack
.\\runtime\\python.exe -B .\\scripts\\mod_tools.py template new .\\my-hero
.\\runtime\\python.exe -B .\\scripts\\mod_tools.py pack .\\my-hero .\\my-hero.heropack
```

格式、限制与示例见 `docs/mod-authoring.md`。本开发包没有个人存档；日志保存在 `logs`。关闭游戏时仅结束本启动器创建的服务。Android APK 仍需按 `DEPLOYMENT.md` 连接对应的当前服务端，不能连接未升级的旧后端。
''', "utf-8")
    shutil.copy2(ROOT / "client/desktop/launcher.py", package / "launcher.py")
    (package / "开始游戏.cmd").write_text('@echo off\r\ncd /d "%~dp0"\r\nstart "" "runtime\\pythonw.exe" "launcher.py"\r\n', "utf-8")
    runtime = package / "runtime"
    shutil.copytree(args.python_runtime, runtime, ignore=shutil.ignore_patterns("__pycache__", "*.pyc"))
    lib = package / "lib"
    lib.mkdir()
    for name in ("pyamf", "cpyamf", "defusedxml", "tzdata"):
        source = args.python_deps / name
        if not source.is_dir():
            raise FileNotFoundError("Missing Python dependency: " + str(source))
        shutil.copytree(source, lib / name, ignore=shutil.ignore_patterns("__pycache__", "tests", "test", "*.pyc"))
    pth = next(runtime.glob("python*._pth"))
    python_zip = next(runtime.glob("python3*.zip"))
    pth.write_text(python_zip.name + "\n.\n..\\lib\n..\\server\n", "ascii")
    sdk = args.air_sdk.resolve()
    (package / "air/bin").mkdir(parents=True)
    shutil.copy2(sdk / "bin/adl64.exe", package / "air/bin/adl64.exe")
    shutil.copytree(sdk / "runtimes/air/win64", package / "air/runtimes/air/win64")
    (app / "application.xml").write_text('''<?xml version="1.0" encoding="utf-8"?>
<application xmlns="http://ns.adobe.com/air/application/51.4"><id>org.bigorange.lal.mods.desktop</id>
<filename>LALModGame</filename><name>最强王者 Mod 游戏端</name><versionNumber>VERSION_VALUE</versionNumber>
<supportedProfiles>extendedDesktop</supportedProfiles><initialWindow><content>MainLLOL.swf</content>
<title>最强王者 Mod 游戏端 - 免费开源</title><visible>true</visible><width>640</width><height>960</height>
<renderMode>direct</renderMode><depthAndStencil>true</depthAndStencil></initialWindow></application>'''.replace("VERSION_VALUE", version), "utf-8")
    checked_run([str(runtime / "python.exe"), "-B", "-c", "import sqlite3,ssl,pyamf,defusedxml; from zoneinfo import ZoneInfo; print(ZoneInfo('Asia/Shanghai'))"], label="Portable Python")
    record = {"version": version, "source_swf_sha256": sha256_file(args.swf), "desktop_swf_sha256": sha256_file(app / "MainLLOL.swf"), "adapters": adapted,
              "mod_install_root": "data/mods", "database": "data/local.sqlite3", "contains_personal_saves": False}
    (output / "build-record.json").write_text(json.dumps(record, ensure_ascii=False, indent=2) + "\n", "utf-8")
    archive = output / "lal-mod-windows.zip"
    with zipfile.ZipFile(archive, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as bundle:
        for file in sorted(package.rglob("*")):
            if file.is_file():
                bundle.write(file, file.relative_to(output))
    print(json.dumps({"package": str(package), "archive": str(archive), "sha256": sha256_file(archive)}, ensure_ascii=False))


if __name__ == "__main__":
    raise SystemExit(main())
