# 安卓单机管理器构建

`android-manager/` 收录既有单机管理器的Java、Python桥及Gradle配置，使轻量存档管理和服务端压缩代码可以在同一个仓库审查、构建。当前版本统一读取仓库根目录 `VERSION`。

外部依赖为JDK 17、Gradle 8.13、Android SDK平台35与Build Tools 35.0.0、Python 3.11，以及有效的AIR客户端APK和原签名密钥。Gradle会获取Android/Chaquopy依赖；工具链、密钥及构建产物不随源码提交。

先按照 `DEPLOYMENT.md` 构建AIR客户端，再运行仓库根目录的 `build-android.ps1` 构建管理器，或运行 `build-merged.ps1` 构建并合包。两份脚本均支持覆盖工具路径、客户端路径和签名文件；使用 `Get-Help ./build-merged.ps1 -Full` 查看参数。未携带Gradle wrapper二进制，可通过 `-GradleLauncher` 指定已有Gradle 8.13启动器。

`scripts/prepare_android_runtime.py --output build/android-runtime` 从本仓库 `server/`、`config/reconstruction/` 和 `VERSION` 组装运行资源，并核对文件摘要；不会复制测试、缓存或玩家数据库。默认合包清单为 `android-manager/merged-AndroidManifest.xml`，版本从实际客户端读取并写入输出清单，不以模板里的历史占位版本作为发布版本。

合包保留AIR客户端的资源表与原生负载，并校验包名、版本及签名。保持与已安装版本相同的签名密钥，才能覆盖更新并保留进度。

不需要设备的存档检查：

```powershell
py -3.12 -m unittest discover -s scripts -p test_compressed_saves.py
py -3.12 scripts/test_save_retention.py
```

前者检查压缩备份、旧格式导入和失败回滚，后者使用JDK编译、运行实际 `SaveStore`，覆盖数量和容量上限、恢复、去重、旧格式迁移及超大进度保留。Java测试中的Android/Python桥为测试替身，不代替Android界面与合包安装验收。
