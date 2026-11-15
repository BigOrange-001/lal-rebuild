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

---

## 第二轮（合入后端 7ba6548/0431630 之后）

本轮同样**只写代码，未编译、未打包、未运行任何测试**（用户中途明确要求不做测试）。

### 合入与核对
- `git merge feat/roguelite-abyss` 无冲突（后端只改 docs/server/scripts）。
- 按新版接口核对：英雄等级改为读 `roguelite_abyss.level`（99），难度倍率/重打次数只取配置 `difficulties`，配置缺失时显示「—」，不再写死旧初值。Boss 掉率配置里没有，仍按服务端 `grant_boss_rewards` 同一公式计算。

### 待办 11 重随（提交 c16d8bd）
- 炼金研究所 `PanelAlchemy` 新增第三个页签「深渊遗物」。该类原本只在模板 SWF 中，现由反编译源码加入构建（`client/src/stages/181_PanelAlchemy.as`，build.json stage 181，stage_count 181 / unique_class_count 154）。
- 界面 `AbyssRerollView104`：目标格 ← 消耗格（ItemEquip 框）、主词条一块标「不变」、3 条副词条可点选（选中「重随这条 ✓」，其余「保留」）、按钮「重随『X』这条」；缺目标/词条/消耗品时按钮仍可点并飘字说明缺什么；消耗品列表中已穿戴、与目标同件的灰显并写原因；返回后被重随的行闪烁。请求带 `substat_index`。

### 待办 12 面板/战力（提交 896932f）
- `Avatar.setEquips`（本人阵位、param2=true）读取 `abyss_relic_slots` 对应的遗物；四维（含装备时）与四属性在所有原有加成之后逐条 `int(v*(1+value))`，与服务端 `apply_panel` 一致；战力在技能乘区加 `main_power_rate`（`abyss_relic_main_power_rate`，太古 ×1.25）。
- 深渊战斗单位来自服务端标准化快照（`hp_max` 已定，getter 直接返回快照值），且深渊流程不调用 `setEquips`，因此不计入。
- 注意：`137_Avatar.as` 也被其他同步脚本修改；本改动是直接编辑，若以后重新生成 Avatar，需要重新执行这些改动（锚点见提交）。

### 待办 13～15 战斗通道（提交 bd34dc3）
- 代码：`client/src/abyss_equip_passives_104.aspart`（Avatar 方法）+ `scripts/sync_abyss_passives_104.py`（幂等插入方法与钩子，执行后再跑 `sync_abyss_client_104.py` 刷新哈希）。
- 数据：`Avatar.init` 只从战斗快照（有 `hp_max`）读取 `equip_passives` 与 `skill.abyss_relic_A`；`abyss_standardized` 时全部忽略。
- 钩子位置：`injured`（伤害修正、碎盾倍率、复苏、受击后效果、治疗放大、护士跳过）、`addBuff`（护盾放大）、`checkMiss`（疾风步）、`removeAllDebuff`（清遗物 DOT）、`hasManualDotKind`（遗物 DOT 保留中毒易伤/灼烧减疗）、`settleBuffs104`（持有者回合先结算遗物 DOT）、`countDamage`（真理之刃防御前拆分）、`inheritSummonPanel`（召唤契约、坚城继承）、`GameMap.beginFight`（每场一次初始化：队长光环→入场护盾→时之沙）。
- A 类上下文：使用原生 `beginAbilityAttack(owner,"active")` 的上下文，且要求 `context.skill === owner.skill0`；大招、普攻、skillB、他人代打不继承。

### 规格不清 / 与服务端可能不一致（需对照确认）
- **延迟命中通道**：客户端的延迟范围打击、炸弹、持续区域、蓄力在施放上下文结束（`endAbilityAttack`）后结算的，目前拿不到 A 类上下文，因此这些命中**不会**触发 #8～#11、#13、#20。服务端已传递，需要后续逐个通道接入。
- **手写技能命中**：只接了原生 `countDamage` 的拆分（#20）；不经过 `countDamage` 的手写伤害不拆分。
- #20 拆分作用在已乘属性克制倍率的数值上（客户端 `countDamage` 先乘克制）；服务端 legacy 分支未乘克制，取整可能差 1。
- 荆棘反弹：按“绝对真伤”跳过暴击/全局倍率/韧性（derived）和原生天赋真伤加成，但仍吃中毒 1.2 易伤、皮肤与亚索的既有入伤修正——服务端 `_damage_modifiers_104` 为空实现，这两项可能与服务端不同。
- 护盾放大（圣佑）放在 `addBuff` 的技能效果倍率、恢复天赋之前；服务端 `_add_buff` 的这两项倍率顺序未确认。
- 坚守誓约回满后的显示刷新用 `refreshHp` 延时调用，未确认与原生弹字时序一致。

### 未做 / 未验证
- 27 份对照用例与真实整场双端逐事件对照：**未执行**（用户要求不做测试）。
- 所有新代码均未编译；FFDec 对新增 stage（PanelAlchemy 反编译源码重编译）也未验证。
- 仍需后端：节点 `enemy_preview`（前端已按该字段读取）、休息处「离开」选项、3 条报错文字的「圣遗物」。

## 2026-11-16 收尾：休息处离开

遗留2：AbyssRestPanel104 的原生按钮区新增并列的「离开」，发送 user.abyss_rest(option=leave)，不要求选英雄；复用 AbyssCore104.send 的5秒防重复点击和状态刷新，成功后关闭休息页回地图。无可提升英雄时提示可离开。改动位于 .aspart，已依次执行 passives/client 同步脚本；真机布局和点击回地图待验收。

遗留1：现有 enemy_preview → enemies → run.battle.orgin_team_b 读取链已接收后端字段，AbyssEnemyPanel104 按line与leader展示英雄，未改前端逻辑；节点实机显示待验收。遗留3：源文件检索无硬编码「圣遗物」，前端无需替换，服务端错误原样显示。


## 2026-11-16 被动对照与修复

27份服务端用例全部重放，并以实际Avatar的injured/addBuff/装备被动/继承方法（只翻译AS类型语法为JS，渲染、调度和无关技能为中性替身）逐命令比较单位状态、装备事件与RNG调用：27/27通过。死亡负HP仅在比较时归零，AIR保留负值用于动画，未改变原客户端死亡行为。此验证不等于Android整场一致性。

附加320组真理之刃原始值/克制/分摊/普通太古边界，发现原版先克制后拆分、合并取整与服务端分支各自取整有差异；现先拆原始伤害，两分支独立克制、取整和分摊，再相加。荆棘反伤保持已结算伤害20%/25%，跳过重复的上下文、皮肤/亚索入伤倍率，仍保留中毒及独立遗物减伤；额外2倍全局倍率用例核对仅结算一次。圣佑护盾改为技能效果/恢复天赋后放大并取整，增加小数边界用例。仅遗物来源进入新分支，无遗物的原结算路径保留。同步脚本连续运行摘要一致。

已知延迟/手写A类技能通道的完整覆盖仍未验收；27份基准为B类，真理之刃另作边界测试。

