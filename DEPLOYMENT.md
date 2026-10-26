# 本地部署

以下步骤面向 Windows PowerShell。所有命令均在仓库根目录执行；Android 设备或模拟器需要能够通过 ADB 连接。请将源码和 AIR SDK 放在仅含英文字母、数字及常规符号的目录，例如 `C:\Projects\lal-rebuild` 与 `C:\Tools\AIRSDK_51.4.1.1`，避免 ADT 对非 ASCII 路径的兼容性问题。

## 1. 获取源码和依赖

```powershell
git clone https://github.com/BigOrange-001/lal-rebuild.git
cd lal-rebuild
```

从官方渠道安装或下载：

- [Python](https://www.python.org/downloads/windows/)：使用 Python 3.12，服务器已在 3.12.6 上验证。
- [Java JDK 17](https://adoptium.net/temurin/releases/?version=17)：将 JDK 的 `bin` 加入 PATH，确保 `java`、`keytool`、`jarsigner` 可执行。
- [AIR SDK](https://airsdk.wxlift.com/download)：获取 Windows 版 51.4.1.1，遵循官方下载流程和许可。在 SDK Manager 中安装 Android 打包组件；SDK 目录需要包含 ADT 和 Android 运行时，单独的 AIR 桌面运行时不够。
- [JPEXS FFDec](https://github.com/jindrapetrik/jpexs-decompiler/releases)：使用 26.3.0 完整发行包，解压后保留整个目录。构建参数指向其中的 `ffdec-cli.jar`。
- [Android SDK](https://developer.android.com/studio)：通过 SDK Manager 安装 Android 平台、Build-Tools 和 Platform-Tools，将包含 `adb.exe` 的目录加入 PATH。

不需要下载原始游戏 APK。游戏素材和构建模板已经在 `client/resources` 中；AIR SDK 和其他工具不随仓库分发。

检查依赖：

```powershell
py -3.12 --version
java -version
keytool -help
jarsigner -help
adb version
```

## 2. 启动本地服务器

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\python.exe -m pip install --index-url https://pypi.org/simple -r .\server\requirements.txt
.\start-server.ps1 --host 127.0.0.1 --port 8080 --database .\data\local.sqlite3
```

保持该窗口打开。第一次运行会创建数据库和父目录；游戏账号及进度保存在 `data/local.sqlite3`。

在另一个 PowerShell 窗口检查：

```powershell
Invoke-RestMethod http://127.0.0.1:8080/health
```

正常加载配置时返回 `status: ok`。服务器默认仅监听本机。客户端的服务地址为 `127.0.0.1:8080`，下述 ADB 映射将设备上的这个地址连接到电脑。

## 3. 构建客户端

将示例工具路径替换为实际安装位置：

```powershell
.\.venv\Scripts\python.exe .\scripts\build_client.py `
  --air-sdk C:\Tools\AIRSDK_51.4.1.1 `
  --android-sdk "$env:LOCALAPPDATA\Android\Sdk" `
  --android-gradle `
  --ffdec C:\Tools\ffdec\ffdec-cli.jar
```

脚本依次编译 `client/build.json` 声明的 ActionScript 类，将游戏资源与生成的 SWF 交给官方 ADT 打包，并验证 APK 签名与资源。首次打包需要网络获取工具链所需的依赖；构建结果留在被 Git 忽略的 `build` 目录；打包中间文件使用系统临时目录。

`--android-gradle` 使用现代 ADT／Gradle 打包分支，同时构建 ARMv7 与 ARM64，并使用 Android SDK 的 `apksigner` 校验签名。此分支需要已安装的 Android Build-Tools 35 及 Android 平台；当前交付使用 compileSDK 36。已有最终 SWF 时可加 `--prebuilt-swf .\build\mod-cold-final-v2\stage-161.swf` 只重新封装，仍应保留其完整冷编译报告。

默认输出为 `build/lal-rebuild-1.0.4.apk`，包含 ARM 与 ARM64 运行库；x86 模拟器需要启用 ARM 转译支持。客户端已允许访问本地 HTTP 服务。首次构建会在本地生成测试签名密钥 `build/debug.p12`，后续构建复用它；不要提交密钥。

需要自行签名时可使用 `--keystore`，并通过 `--storepass-env`、`--keypass-env` 指定保存密码的环境变量名称；省略时脚本交互询问密码。`--android-sdk` 应指向包含 `platforms`、`build-tools` 和 `platform-tools` 的 SDK 根目录。

构建基于随仓库提供的原游戏 SWF 模板，重新编译并替换已提供的客户端类，随后由 AIR SDK 提供运行时和 Android 封装。模板中的未改动原游戏代码与资源仍是必要输入；这不是完全由原游戏源码重新生成所有资源的工程。

## 4. 安装与连接

打开设备的 USB 调试，或启用模拟器的 ADB 接口。需要手动连接的模拟器按其设置执行 `adb connect 地址:端口`，随后检查设备：

```powershell
adb devices
adb install -r .\build\lal-rebuild-1.0.4.apk
adb reverse tcp:8080 tcp:8080
adb reverse --list
```

连接了多台设备时，为每条 ADB 命令添加 `-s 设备序列号`。

此包与原游戏或旧测试包可能存在签名和 Android 版本号差异，不能保证直接覆盖安装。安装报签名冲突或版本降级时，先备份所需数据，再卸载设备上的旧包，重新安装；不要因此删除服务器数据库。项目版本为 1.0.4。

保持服务器运行，打开游戏，在本地登录界面注册账号并登录即可开始游玩。设备断开或重启后重新执行端口映射。网络错误时依次检查服务器窗口、`/health` 和 `adb reverse --list`。

## 5. 服务器控制台

游戏时间实时跟随系统时间，修改系统日期会同步改变游戏时间。跳天累计偏移保存在同一个 SQLite 数据库中，重启后继续生效；旧版独立逻辑时钟不再使用，升级后默认以系统时间为准。在服务器控制台输入 `time` 查看游戏时间，`time hours 6` 推进六小时，`time days 1` 过一天。

也可以在另一个 PowerShell 窗口推进游戏时间；`--database` 必须指向启动服务器时使用的数据库：

```powershell
.\.venv\Scripts\python.exe .\scripts\game_time.py --database .\data\local.sqlite3 show
.\.venv\Scripts\python.exe .\scripts\game_time.py --database .\data\local.sqlite3 advance --hours 6
.\.venv\Scripts\python.exe .\scripts\game_time.py --database .\data\local.sqlite3 advance --days 1
```

每次只指定小时或天数，时长必须为正数，允许换算为整数秒的小数小时。推进后下一次游戏请求会读取新时间，每日次数、体力恢复和游戏内冷却按新时间结算。登录会话的安全有效期仍使用真实时间。重启后继续使用系统时间加已保存的跳天偏移，关机时间随系统时间正常累计。

在服务器窗口输入 `help` 查看命令：

| 命令 | 用途 |
| --- | --- |
| `status` | 查看地址、配置版本、数据库路径和账号数量 |
| `accounts` | 列出本地账号 |
| `mail` | 向指定账号发送资源邮件 |
| `exit` | 停止服务器 |

注册账号后发送邮件，例如：

```text
mail test-account gift-001 "测试资源" '{"coin":1000,"gold":100000}'
```

`test-account` 替换为注册的账号，`coin` 是金砖，`gold` 是 L 币。JSON 外层使用单引号。领取奖励需要在游戏邮件界面操作；同一个请求 ID 重试必须使用相同标题及奖励内容，避免重复发放。

## 6. 存档备份

先在服务器窗口输入 `exit`，再复制数据库：

```powershell
Copy-Item -LiteralPath .\data\local.sqlite3 -Destination .\data\local.backup.sqlite3
```

恢复时先停止服务器，用备份覆盖 `data/local.sqlite3`，再启动。更新源码或重新构建客户端不需要清空数据库。数据库、虚拟环境、日志、构建结果和密钥均不提交到 Git。

启用 DIY 英雄包后，建议退出游戏并停止服务器，再备份整个 `data` 文件夹，包含 `local.sqlite3` 和同级 `mods` 安装目录。自定义了 `--mods-root` 时，也要备份该目录；其中 `registry.json` 保存永久身份映射，`packages` 保存固定版本及摘要对应的包文件。不要从其他设备单独覆盖注册表并继续游玩。

只恢复数据库而没有恢复包文件时，新增英雄显示缺失并冻结，英雄和装备记录保留。服务端会在首次目录扫描前尝试恢复存档中保存的编号映射；若目标设备的编号已属于其他身份，此存档的 Mod 会冻结并报告需要身份迁移，避免误认其他英雄。重新导入对应版本和摘要的包后可恢复原实例。

## 7. Mod 作者工具与 Windows 开发包

作者工具使用当前有效基础配置校验目标合同。例如：

```powershell
.\.venv\Scripts\python.exe .\scripts\mod_tools.py template new .\build\my-hero
.\.venv\Scripts\python.exe .\scripts\mod_tools.py pack .\build\my-hero .\build\my-hero.heropack
.\.venv\Scripts\python.exe .\scripts\mod_tools.py validate .\build\my-hero.heropack
```

字段、限制、能力白名单及补丁目标摘要命令见 [作者说明](docs/mod-authoring.md)。包只能使用受支持的声明式数据和媒体文件。

Windows 打包复用完整冷编译后的 SWF，额外生成桌面启动适配，不改 Android 的源码链。以下路径按实际依赖位置填写，输出必须是新目录：

```powershell
.\.venv\Scripts\python.exe .\scripts\build_mod_desktop.py `
  --swf .\build\mod-cold-final-v2\stage-161.swf `
  --air-sdk C:\Tools\AIRSDK_51.4.1.1 `
  --ffdec C:\Tools\ffdec\ffdec.jar `
  --java 'C:\Program Files\Java\jdk-17\bin\java.exe' `
  --python-runtime C:\Tools\python-embed `
  --python-deps C:\Tools\python-deps `
  --output .\build\windows-mod
```

便携 Python 目录需要 `python.exe`、`pythonw.exe`、标准库 ZIP 和对应 DLL；依赖目录提供 `pyamf`、`cpyamf`、`defusedxml`、`tzdata`。打包脚本检验其可启动，复制干净的服务器、配置、资源及作者示例，不读取个人存档。解压后运行“开始游戏.cmd”，首次启动在包内创建 `data/local.sqlite3` 和 `data/mods`。日志在 `logs`；关闭游戏只结束本启动器创建的本地服务。


## 1.0.4 召唤池标定

`config/reconstruction/summon-calibration.json` 为已补齐重复项的正式标定：普通、高级、VIP 的品质出率分别保存；蓝、绿、紫的卡表及权重相同。VIP 橙池使用高级橙池卡表，普通橙卡权重不变，皮肤英雄权重乘 2。`normalization.skin_hero_ids` 保存精确皮肤 ID，避免把茂凯等普通英雄按编号误判为皮肤。

每次先按品质百分比抽品质，再在该池该品质中按正数权重抽卡。小数权重转为精确整数比例抽取；空白对应缺少记录、零权重均不参与。旧高级召唤紫卡保底不再覆盖品质概率。VIP 只出整卡，价格、积分和单抽/十连协议保留。皮肤英雄的全局获取限制、碎片合成的爬塔来源限制均已解除；原有兑换入口保留。

后端启动时加载标定；更新文件后重启后端。原始输入和补齐确认版另存于工作区 `outputs/召唤池标定-1.0.4/`，确认版可重新导入离线网页查看。

`summon_pools.confirm_custom_hero` 为确认导入接口：用户确认后向对应品质池添加权重 1 的记录，保留已有权重和品质概率。已应用 Mod 配置的 `mod_runtime.heroes` 会按各召唤渠道的确认状态自动加入，缺包、禁用、未开放渠道均不入池；新条目不修改基础配置。
