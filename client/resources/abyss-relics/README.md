# 深渊遗物中心图

20张中心图由独立图标生成任务使用 image gen 创建，参考原版真实装备贴图的手绘卡通、深色勾线和分块金属高光。外框不由AI生成，游戏运行时复用原生彩虹框。

`manifest.json` 列出relic_id 1～20、名称、PNG摘要和图集区域；每张PNG为256px审查源图。`atlas.png` 为512px运行图集，主体contain到76×77并在92×93区域保留8px安全区。

重建：运行 `scripts/build_abyss_relic_art_104.py`，然后 `scripts/sync_abyss_passives_104.py`、`scripts/sync_abyss_client_104.py`。只做几何缩放、居中和打包，未以脚本绘制替代生成图。
