# 星辉图标（2026-11-16）

基于主线 `09cf9bd` 接入；分支 `feat/stardust-icon-20261116`。使用内置 imagegen，参考从原版 `ui_main.atf` 经 AIR Stage3D 解码的四种粉尘图标，没有使用 CLI/API。

## 素材与界面

- 母图：`client/resources/currency/stardust-master.png`，保留 imagegen 透明通道。
- 游戏图：`client/resources/currency/stardust-52x50.png`，与原版 `UI_magic_money_0000..0003` 的 52×50 尺寸一致。
- 运行时按原版粉尘 0.6 比例显示（31.2×30 逻辑像素）。缩图脚本只执行透明区域裁切和预乘 alpha Lanczos 缩放，不重绘图案。
- `Equip.createStardustIcon()` 内嵌最终 PNG 的 ARGB 数据，缓存一张可恢复纹理；面板销毁只释放 Image，纹理随 AssetManager 管理。不依赖网络或运行时图片路径。
- 装备出售页：图标位于四种粉尘之后，保留「星辉 数量」文字；将整行左边缘移至面板内 20 像素处，让五种资源都在 630 像素面板内显示。
- 炼金面板：星辉余额/费用旁显示同一个图标；文本宽度限制在炼金按钮之前，并启用自动缩字。词条传承模式不显示该控件。
- 对比图 `stardust-icon-comparison-20261116.png`：左四个是原版粉尘，最右为星辉；均放大三倍便于检查，不是游戏实机截图。

## 验证

- 从星辉功能分支已有 SWF（附源码清单）增量重编译 Equip、PanelEquipAlchemyStart、PanelEquipSellSelect 三个类成功，输出 `build/stardust-icon.swf` 和源码清单。
- `test_stardust_icon.py`：嵌入像素与 PNG 完全一致；两个面板复用一次上传；释放 Image 后仍可复用，纹理恢复使用保留的原始 BitmapData。
- `test_equipment_stardust_client.py`：装备属性、星辉产出与消耗的客户端/服务端对照通过。
- `test_rainbow_frame_105.py`：原装备边框像素、缓存与恢复的两项检查通过。
- 新旧两个完整 SWF 在独立 AIR 动态加载探针中均报 VerifyError #1107，随后 ReferenceError #1065。因此不能把这次探针当作完整客户端运行通过；尚未完成 Android 实机界面验收。
- APK 打包未成功：本地 Gradle 8.13 下载缓存的 ZIP 不完整（zip END header not found），原始 toolchain/android-sdk 同时缺少 platforms 目录。切换已有 project/build/android-sdk-adt 后仍受 Gradle 缓存阻塞。未修改全局缓存，未安装到设备。

复现素材：`python scripts/build_stardust_icon.py`；替换母图可加 `--master PATH`。

## 最终 imagegen 提示词

```text
Use case: stylized-concept. Asset type: a single transparent currency icon for the existing fantasy mobile RPG UI. Input image 1 is STYLE REFERENCE ONLY: four original in-game magic-dust resource icons, enlarged with nearest-neighbor sampling from their native 52x50 resolution. Create ONE new resource icon for 星辉 (Stardust): a chunky faceted golden four-point star crystal with a smaller crystal chip at its lower right and one tiny sparkle at upper left. Match the reference's old-school hand-painted fantasy inventory art: dark olive-brown irregular outline, simple chunky facets, bright pale-gold upper-left highlights, amber-orange lower-right shading, restrained warm glow, readable compact silhouette. Slight three-quarter volume; cheerful magical treasure feel, not a modern flat vector or realistic 3D render. The object must remain legible after downsampling to 52x50 pixels, so use very few large facets and avoid delicate linework. One icon centered in a square canvas with about 8 percent transparent padding, no frame or tile, no text, no numeral, no watermark, no multiple variants, no sheet. Actual transparent background, retain alpha; glow must be compact and not fill the canvas. Do not copy the reference's cylindrical crystal subject: the new main silhouette should be a distinct four-point star-shaped golden crystal.
```
