# 深渊回廊 前端开发日志

分支 `feat/roguelite-abyss-client`（worktree `lal-abyss-client`），基于后端 `feat/roguelite-abyss` 2802bb4（阶段 1、2）。
本轮按用户要求**只写代码，未编译、未打包、未实机/模拟器验证**。下文“完成”指代码已写入并自查，不代表已运行通过。

## 实现方式

- FFDec 构建只能替换已有类（已实验：`-importScript` 不会新增类）；在已有类文件的 package 外追加私有类可以编译（已用 FFDec 实测并反编译确认）。
  因此全部界面写在 `client/src/abyss_ui_104.aspart`，由 `scripts/sync_abyss_client_104.py` 拼接到 `102_PanelActivityExploration.as` 的 package 之后（`// BEGIN/END ABYSS_UI_104`），同时刷新 `client/build.json` 全部 `source_sha256`。修改界面后先改 aspart 再运行该脚本。
- 入口：探险页（`PanelActivityExploration`）「开始探索」上方新增「深渊回廊」按钮。界面均为 `PanelBase` 弹出层，走原版 `openPopForPanel/closePopForPanel`。
- 战斗：沿用探险战斗分支（combatType=4），用 `GlobalData.$abyss104` 区分深渊；与探险的差别逐点分支，探险原逻辑不变（探险出战前会清除该状态）。

## 完成项（代码）

| 前端待办 | 内容 | 位置 |
| --- | --- | --- |
| 1 入口 | 难度 ‹N›（敌人倍率、重打次数、三幕 Boss 掉率按服务端同一公式）、5 套卡组各一排 5 张卡（选中蓝框、未解锁灰显并写解锁条件、星裔 5 张问号卡）、「卡池图鉴」「深渊遗物」「开始新的一局/继续本局」 | `AbyssEntryPanel104` |
| 2 地图 | 当前幕 7 层自下而上，Boss 在顶；可前往节点黄色高亮、当前节点绿色、已走路径虚线、可达层以上迷雾；顶栏幕/剩余重打/阵容池；底部「阵容池」「放弃本局」；续局按 run 状态自动打开选人/休息/出战/结算 | `AbyssMapPanel104`、`AbyssCore104.openNodeStep` |
| 3 选人 | 3 列卡片（6 张为 3×2，5 张为 3+2），下方显示焦点英雄技能、队长技与按“阵容池+已选”判断的羁绊；「跳过」（弱敌不显示）「加入阵容池（N）」 | `AbyssChoicePanel104` |
| 4 出战选人+布阵 | ① 5 个编号卡位（1 号位队长）+ 阵容池头像格，点上阵/再点下阵，满 5 人飘字，≥3 人且 1 号位非空才能开战；② 进入原版 `PanelPVEembattle`（三路原生地图、拖动站位），「返回选人」只关弹层、不发请求、不扣次数 | `AbyssTeamPanel104`、`180_PanelPVEembattle.as`、`175_GameMap.as` |
| 5 战斗与结算 | `user.abyss_combat` 开战（team 按卡位顺序 `[池id, 路, 位置]`，首位队长）；`fight_kind=abyss` 走现有 `submitBattleFinish`（`user.battle_finish` 别名）；回到探险页后重新 query 恢复：胜→Boss 奖励/选人/地图，败→失败弹窗，次数用完→本局失败 | `GameMap.sendFight/reSend/endFight`、`AbyssCore104.resumeAfterBattle` |
| 5 凭证续战 | run.battle 未过期时出战页预填当时阵容、按钮为「继续战斗」，GameMap 直接用保存的快照开战，不再请求 | `AbyssTeamPanel104`、`GameMap.sendFight` |
| 6 休息处 | 「技能 5→10」「升为橙卡」二选一页签，“目标 → 结果”预览，阵容池中不可选者灰显并写原因（技能已满/已是橙卡/本模式登场后可升），按钮写明结果（如「升级凯南技能」） | `AbyssRestPanel104` |
| 7 卡池图鉴 | 已开放紫卡、橙卡开放状态、皮肤橙卡，点击看技能 | `AbyssCodexPanel104` |
| 8 重打/放弃 | 失败弹窗写明已消耗 1 次、剩余 X/Y、敌人不变，按钮「放弃本局」「调整布阵」；所有放弃入口共用 `confirmAbandon`（列出四条后果，「确认放弃」红字，「继续本局」为默认高亮）；结算页显示通关/失败/放弃、剩余重打、阵容池、本次新开放橙卡、解锁难度/卡组、获得的深渊遗物 | `AbyssConfirmPanel104`、`AbyssResultPanel104`、`AbyssRewardPanel104` |
| 9 深渊遗物 | 背包与详情：名称、主词条、3 条副词条直接显示后端 `text`；太古行使用专用青色 `0x3CF0E0`，有太古词条的名称前加 `*` | `AbyssRelicBagPanel104`、`AbyssRelicDetailPanel104`、`AbyssRelicView104` |
| 10 第 7 格 | 英雄详情（`show_type_team`）原版 6 格不动，第 7 格用 `ItemEquip` 框（0.8）放在两列中间、第三排下方，空格写「在深渊回廊中获得」，点击进入选择/详情，穿脱后刷新；客户端把 `as_equips` 第 7 列拆到 `$userData.abyss_relic_slots`（见下） | `143_LOL_DetailAvatar.as`、`AbyssRelicSlotView104` |

### 第 7 格兼容（重要）

后端现在所有响应和存档同步都返回 7 列 `as_equips`。客户端大量旧循环按行长度遍历并执行 `my_equips[id].symp`（`GlobalFunction.checkIsSympSame/Count`、装备属性汇总、`LOL_DetailAvatar.updateEquip` 等），读到深渊遗物 id 会空引用。
处理：`GlobalData.normalizeAbyssSlots104` 在 `$userData` 赋值和 `applyProfileSnapshot` 时把每行截成 6 列，第 7 列存 `abyss_relic_slots`；旧 `user.equip_dress` 仍发 6 列，后端会保留第 7 格。

## 复用的原版类

`PanelBase.setPopPanelBg`（`UI_bg_9slice_1/2/3`）、`LOL_Scale9Button`（`UI_btn_normalFun_0000`）、`UI_bg_9slice_4_0000` 底框、`Avatar.getAvatarRes` 英雄卡、`UI_bg_card_2_0002` 空卡位、`ItemEquip`、`UI_map_exploration` 与 `pic_war_fog`、`PanelPVEembattle`/`GameMap`/`GameMapManager.getPVPData` 三路地图、`GlobalFunction.popAlert`（技能说明）、`LayoutUIAnimation.popWords`、feathers `ScrollContainer`、`$mConfig_simple.bonds_104` 羁绊定义。

## 需后端配合

1. **敌方阵容预览**：`public_run` 删除了节点的 `enemies`，出战前拿不到敌人。前端已支持读取 `node.enemy_preview`（aid 字符串数组或含 `aid/line/slv/leader` 的对象数组）或 `node.enemies`；目前只有凭证续战时能显示（来自 `run.battle.orgin_team_b`），其余显示「敌方阵容：开战后显示」。
2. **休息处无可提升英雄时卡死**：休息节点只能通过 `abyss_rest` 完成，若全员技能 10 级且无可升橙者，无法继续。需要“跳过休息”或兜底规则。
3. 后端提示文本仍有「圣遗物」（如 `AbyssUnknownRelic` 的“该圣遗物不存在。”、`AbyssInvalidRelicMaterial`），前端未替换。
4. 卡组名称前端用 `roguelite_abyss.decks[key].name`（结算页解锁提示）；入口页按定稿不显示名称。

## 未做 / 未验证（不得视为完成）

- **全部未编译**：FFDec 编译器对文件私有类、闭包等的兼容只做过最小实验；SWF/APK 未构建，`client/build.json` 哈希已由脚本刷新。
- **全部未实机/模拟器验证**：开局→选路→选人→出战→胜/败→休息→Boss→结算/放弃整局未跑；第 7 格是否遮挡英雄形象未截图确认（偏移量常量 `RELIC_SLOT_OFFSET_104 = 40`，需要时下移）。
- 待办 11 重随界面：按约定暂不做（等 `substat_index`）。
- 待办 12 面板/战力：未把深渊遗物副词条计入客户端英雄详情面板与战力（`Avatar.as` 由同步脚本生成，需按 `relic_contribution` 单独接入）；深渊内战斗使用服务端标准化快照，本身不受影响。
- 待办 13 / B 类主词条客户端战斗：按约定暂不做。
- 选人界面“飞入卡位”只做了刷新+淡入，没有逐个飞行动画。
- 深渊战斗不支持战斗回放按钮（回放会按普通探险重建地图）。
- 结算页“新开放橙卡”按本次进入模式时的快照对比；若中途重启客户端，开始前已开放的也可能被算作新开放。
