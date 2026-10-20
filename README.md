# 撸啊撸重构（lal-rebuild）

版本：**1.0.3**。

1.0.2 完善养成、资源副本、招募兑换、奇遇任务和充值福利，修复战斗技能与特效、竞技场属性、装备出售／洗练／附魔及界面显示，并增加全面屏适配。

1.0.3 增加召唤与装备标定、四套配队预设、筛选与锁定、技能书概率升级及新皮肤技能，统一战力与召唤物面板，重做持续伤害与灵魂塔奖励，并调整资源副本次数和界面适配。

装备附魔使用四色粉尘，每次成功附魔重新抽取符文类型。各阶附魔独立升至100级，中央符文独立升至10级；两者的等级与属性加成分别显示。

基于《撸啊撸／最强王者》客户端的本地单人游戏项目，包含客户端改动源码、游戏资源、Python 服务端和游戏配置。支持关卡战斗、英雄技能与紫卡羁绊、养成、招募、装备、探险、远征、德诺阵、AI竞技场及资源邮件；充值入口仅用于本地赠送，不产生真实扣款。

## 构建与运行

仓库包含构建需要的游戏素材和 SWF 模板；Python、Java、AIR SDK、JPEXS FFDec 及 Android 调试工具由使用者从官方渠道获取。

在 Windows 上启动服务器：

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r server\requirements.txt
.\start-server.ps1 --database .\data\local.sqlite3
```

服务器保留交互命令行，输入 `help` 查看管理命令。客户端构建会在随仓库提供的 SWF 模板中重新编译客户端改动，再由官方 AIR SDK 打包；不需要原 APK 中的运行库。它不是所有原游戏代码的完全源码重编译。

客户端安装到 Android 设备或模拟器，通过 ADB 端口映射连接本机服务器。依赖安装、客户端构建、连接、账号注册及存档备份步骤见 [部署说明](DEPLOYMENT.md)。

## DIY 英雄与 Mod 开发版

支持纯数据 `new` 英雄包和局部 `patch` 补丁包。包统一安装，各账号存档分别在“系统设置 → Mod 管理”启用，并配置召唤、竞技场、碎片商店等玩法开关及补丁作用范围。新增英雄包缺失时冻结实例并保留进度；补丁缺失时恢复仍有效的基础定义。

- [完整开发目标](docs/mod-system-design.md)
- [作者规范、模板、打包与错误说明](docs/mod-authoring.md)
- [RPC、安装接口与存档契约](docs/mod-api.md)
- [实现范围、验收证据和平台验证状态](docs/mod-implementation.md)
- [可导入的 new、技能 patch、数据 patch 示例](examples/mods)

默认安装目录为数据库同级的 `mods` 文件夹，可用 `--mods-root` 明确指定。把 `.heropack` 放入 `mods/inbox` 后，在管理页点击“检查目录”；也可直接在管理页选择文件导入。安装不自动启用、不自动发卡。启用包后使用游戏内开放的获取渠道；独立测试账号可通过 `user.mods_test_grant` 验证英雄。

Windows 可用 `scripts/build_mod_desktop.py` 将已完整编译的 SWF、当前服务器和外部依赖打包为独立运行目录；Android 使用原有 `scripts/build_client.py` 构建。开发版的具体构建及实际运行验证状态见实现文档，不能用源码检查代替平台验收。

## 原生战斗模板 API

游戏端提供 `skill.native-template.v1`，支持当前全部 1077 条技能的结构化模板，涵盖 73 种原生动作及 44 类复合机制。新模板需要客户端与服务端同时支持；旧包保留原有行为。普攻真实伤害、原生位移、目标锁与等级说明扩展一并提供。

接口、机制清单和无需编辑器的核心检查见 [原生战斗模板接口](docs/native-battle-template-api.md)；包格式见 [作者规范](docs/mod-authoring.md)。编辑器界面与 EXE 不属于游戏运行依赖，单独维护和发行。

## 授权声明

本项目为非官方的本地重构项目。MIT 许可仅适用于本项目独立编写的服务器、工具代码及原创改动，不覆盖原客户端代码、游戏图像、音频、商标或第三方组件。随仓库提供的原游戏资源及模板权利仍归原权利人；本项目不重新授予这些内容的使用或再分发权。构建依赖分别遵循其原有许可。

### MIT License

Copyright (c) 2026 BigOrange-001

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
