# 隔离 Android Mod 验证包

`scripts/build_mod_android_probe.py` 用当前 Android 客户端 SWF 与真实 AIR 运行时构建 QA 包。它不启动模拟器、不安装 APK、不替换原游戏，也不复制任何玩家数据库。

固定应用 ID 为 `org.bigorange.lal.mods.qa`，与原游戏的 `air.com.meng52.lol.android` 不同。打包后同时检查 AIR 描述符和原生 Android Manifest 的实际包名；检查本地 HTTP、ARMv7／ARM64 运行时、签名、游戏 SWF、素材和探针是否完整。

初始窗口加载 `ModRuntimeProbe.swf`；探针再加载 `MainLLOL.swf`，通过真实登录、系统设置、Mod 管理页和 `GameMap` 战斗／结算执行流程。探针不实现另一套战斗算法。日志和截图在 Android 使用 `File.applicationStorageDirectory`，不会尝试写入 APK 的只读应用目录。

## 构建

准备只用于本次 QA 的 `probe.json`，包含 `account`、`password`；可包含探针使用的其他测试参数。它会嵌入 QA APK，禁止使用真实玩家凭据。构建脚本不打印这些字段，也不把它们写进构建元数据。

```powershell
python -B scripts/build_mod_android_probe.py `
  --air-sdk '<HARMAN AIR SDK目录>' `
  --android-sdk '<Android SDK目录>' `
  --main-swf build/mod-cold-final-v2/stage-161.swf `
  --probe-settings '<隔离QA账号的probe.json>' `
  --output build/lal-mod-android-qa.apk
```

`--main-swf` 必须是原始 Android 路径、完整冷编译并与当前来源 SHA 对齐的最终客户端，不能使用修改了 Windows 启动方式的桌面 SWF，也不能使用遗漏既有辅助类的早期 targeted 调试 SWF。

没有 `--probe-swf` 时，脚本使用 SDK 的 AIR mobile 编译配置编译当前 `scripts/probes/ModRuntimeProbe.as`。可显式传入已经编译的同版探针。签名默认使用 `build/mod-android-qa-debug.p12` 的专用测试身份；外部测试签名必须通过 `--storepass-env`／`--keypass-env` 提供口令，脚本不交互请求个人发布密钥。

使用 SDK 的 Gradle 打包路径，配置 Gradle 8.13、Android Gradle Plugin 8.9.1、Android API／build-tools 35；首次运行可能下载正常构建依赖并写入 Gradle 缓存。采用 Android SDK `build-tools/35.0.0/lib/apksigner.jar` 校验实际 APK 签名，包括 v2／v3 签名；不能用仅检查 JAR/v1 的工具判定现代 APK 未签名。其他安装位置可用 `--apksigner` 显式指定。

Gradle 路径显式传入 SDK 支持的 `-arch all`，并用描述符将架构限制为 ARMv7、ARM64。SDK 51 的 legacy APK 路径拒绝 `all`，而只填写描述符会被默认命令行架构过滤成 ARMv7；脚本以 APK 实际的两个 `libCore.so` 为准验证结果。

正式游戏 APK 继续使用 `scripts/build_client.py`，增加 `--android-gradle --android-sdk '<Android SDK目录>'` 可启用同一官方工具链；可用 `--prebuilt-swf build/mod-cold-final-v2/stage-161.swf` 打包最终完整源码链的产物。此开关只修改暂存描述符里的构建配置，保留游戏应用 ID、版本、已有的 minSDK／targetSDK 声明；没有显式声明时采用已发布 APK 的 21／36 默认值。编译 SDK 优先使用已安装的 36，构建工具为 35。未加该开关继续使用已有打包模式；两条路径都检查实际 ARMv7、ARM64 运行库。正式 APK 不携带 QA 探针或测试凭据。

本次正常游戏包为 `build/lal-rebuild-1.0.2-mod-final.apk`，同名 JSON 保存 APK／游戏 SWF 摘要、签名方案与公开证书指纹、实际应用 ID、SDK、架构、161 阶段源码核对，以及没有 QA 载荷的检查结果。它沿用当前 1.0.2 交付客户端的调试签名身份；对应公开证书核对记录为 `build/current-signing-evidence.json`。QA 最终包使用单独的 `build/lal-mod-android-qa-final.apk` 和独立签名，保留在本机验收目录。

Windows 上 SDK 含中文路径时，脚本只为本次打包创建一个未占用盘符的临时 ASCII 别名，并在结束时移除；不会修改已有盘符映射。所有 ADT 载荷先写入系统临时目录，结束后清理。APK 旁的 JSON 元数据记录来源 SWF／实际参与编译的探针摘要、APK 摘要、应用 ID、架构和 HTTP 检查结果，不包含口令。

## 由测试操作者执行的安装与读取

以下是手动命令模板；构建脚本不会执行它们。先确认目标设备，再让设备的 `127.0.0.1:8080` 指向隔离测试后端端口：

```powershell
adb -s '<测试设备>' reverse tcp:8080 tcp:<隔离后端端口>
adb -s '<测试设备>' install -r build/lal-mod-android-qa.apk
adb -s '<测试设备>' shell monkey -p org.bigorange.lal.mods.qa -c android.intent.category.LAUNCHER 1
adb -s '<测试设备>' logcat -v threadtime
```

探针会输出 `MOD_PROBE` 跟踪信息，并在应用专属存储写入 `mod-probe.log`、管理页截图、战斗截图和结算截图。Release AIR 的 `trace` 不保证进入 logcat，验收应读取文件日志。调试 QA 包可用 `adb shell run-as org.bigorange.lal.mods.qa` 检查其应用专属文件；本次 AIR 子目录为 `org.bigorange.lal.mods.qa/Local Store/`。

`scripts/run_mod_runtime_probe.py --serve-only` 可准备独立数据库、包目录和临时账号；支持 `base`、`media`、`minimal`、`scopes`、`missing`、`restored`、`directory-import` 等场景。运行时可读取仅属于此 QA 应用的 `probe-override.json`。用 `scripts/probes/set_android_probe.py --adb <adb路径> --session <session.json>` 私下写入设置、更新本任务的 ADB reverse 并启动探针，不打印测试口令。只能传独立测试会话。

使用 `scripts/probes/collect_android_probe.py --adb <adb路径> --output <新证据目录> --apk <本次QA APK>` 可按原始字节导出文件日志与本次 `CAPTURE` 对应的 PNG，记录 APK 和文件摘要；不要用旧版 PowerShell 文本重定向复制二进制截图。本次最终结果及没有覆盖的界面操作见 `mod-implementation.md`。

通过标准是日志包含成功登录、Mod 管理打开、真实战斗进展及 `PROBE_FINISHED`，且没有未捕获错误；还应核对服务端该战斗确实完成持久结算。Android 导入、包卸载后的缺失恢复和系统文件选择器仍应分别操作验证，不能因为 APK 能安装或探针完成一场战斗就宣称全部平台验收通过。
