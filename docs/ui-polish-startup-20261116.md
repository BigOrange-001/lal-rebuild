# 界面打磨与登录配置复用（2026-11-16）

来源：1.0.5 实机录像审查。

## 界面

- 深渊战斗：VS 门不显示双方战力（深渊用标准化快照，没有战力，原来显示 NaN），先手标志保留；战斗标题显示「深渊回廊」而不是借用的竞技场地图名。`175_GameMap.as`（DoorLayer 只在模板 SWF，用 `Event.ADDED` 在战力文字加入时隐藏）。
- 积分兑换：积分不足时「兑换」置灰，点击仍弹原版「积分不足」。`097_ItemInteGralExchange.as`。
- 深渊界面浅色底框（`UI_bg_9slice_4`）上的文字统一用 `INK_TEXT`/`INK_NAME`：休息处预览与占位提示、选人技能说明。`abyss_ui_104.aspart`。
- 公会第 5 页签「公会技能研究」改为「公会技能」，不再撑出屏幕。`069_PanelGuildBase.as`。
- 功能说明引导气泡（无 `yy` 的默认位置）在底部导航栏可见时上移到导航栏之上。`147_LayoutUIAnimation.as`。

## 登录配置复用

问题：`sys.get_config` 先发一份完整配置（AMF 约 12 MB），`user.login` 的 `mod_config` 又深拷贝并发一整份，客户端再整体替换。

- `sys.get_config` 的 `cfg_version` 改为 `版本#基础配置摘要`（`ModService.base_digest`）。
- 客户端登录参数带 `config_digest`：当前 `$mConfig` 若是某次登录完整收到的配置，用当时的摘要；否则用 `cfg_version`。`045_GlobalFunction.as`（`170_GlobalFunction.as` 同步，但该阶段只拷贝战力方法）、`004_PanelServiceMain.as`。
- 服务端 `ModService.config(uid, held_digest)`：摘要等于该存档生效摘要（无 Mod 为基础摘要，有 Mod 为编译摘要）时，返回 `cfg_reuse: true`、`cfg_keys`、`mod_runtime`，不深拷贝、不发表；否则照旧完整下发。旧客户端不带摘要，行为不变。
- 客户端复用时删除 `cfg_keys` 之外的旧表，与完整替换一致；摘要不符则按原逻辑提示同步失败，不会用错配置。

PC 测量（新账号）：登录 1.14 s + AMF 12112 KB/编码 2.75 s → 0.06 s + 16 KB。手机端收益待实机确认。

测试：`server/test_mod_service.py::test_login_reuses_client_config_only_when_digest_matches`。
