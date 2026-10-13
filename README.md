# 撸啊撸重构（lal-rebuild）

版本：**1.0.0**。

基于《撸啊撸／最强王者》客户端的本地单人游戏项目，包含客户端改动源码、游戏资源、Python 服务端和游戏配置。支持关卡战斗、英雄技能与紫卡羁绊、养成、招募、装备、探险、远征、德诺阵、AI竞技场及资源邮件；充值入口仅用于本地赠送，不产生真实扣款。

## 构建与运行

**无需提供原始 APK 或游戏残端。** 仓库包含构建需要的游戏素材和 SWF 模板；Python、Java、AIR SDK、JPEXS FFDec 及 Android 调试工具由使用者从官方渠道获取。

在 Windows 上启动服务器：

```powershell
py -3.12 -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r server\requirements.txt
.\start-server.ps1 --database .\data\local.sqlite3
```

服务器保留交互命令行，输入 `help` 查看管理命令。客户端构建会在随仓库提供的 SWF 模板中重新编译客户端改动，再由官方 AIR SDK 打包；不需要原 APK 中的运行库。它不是所有原游戏代码的完全源码重编译。

客户端安装到 Android 设备或模拟器，通过 ADB 端口映射连接本机服务器。依赖安装、客户端构建、连接、账号注册及存档备份步骤见 [部署说明](DEPLOYMENT.md)。

仓库不包含预编译安装包、AIR SDK、个人存档、签名密钥或开发过程文件。版本号固定为 1.0.0，后续仅在明确指定时更新。

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
