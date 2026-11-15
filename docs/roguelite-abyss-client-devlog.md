> 最新状态（2026-11-16）：手机黑屏已修复，用户已确认进入主界面。正式包与 PR #37 审核收尾进行中；旧安装记录为历史。

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


## 2026-11-16 编译类型解析

FFDec内置编译器在102_PanelActivityExploration.as:1054报AbyssPanel104 is not an existing type，无法解析新增私有类继承链。没有改界面继承或用临时桩绕过：该阶段改用官方AIR SDK的mxmlc编译实际完整源码，经FFDec原生MxmlcAs3ScriptReplacer合回模板ABC；既有模板类型使用external-library-path，不重复链接游戏类。CompileAirAs3.java直调SDK编译器并保留完整错误输出，移除仅Apache Flex支持的include-inheritance-dependencies-only参数。验证编译产物反编译包含全部18个Abyss类、enemy_preview读取与leave按钮。后续AIR签名打包仍走官方ADT。


## 集成兼容：炼金页签

集成时client/两处冲突按用户要求先采用前端分支；随后发现main已有的词条传承与遗物重随都占第三个页签，会丢失原入口。保留本分支遗物第三页，将原词条传承追加为第四页，继续复用main的PanelEquipAlchemyStart继承模式、原等级门槛，并在切页/离开时重置模式。没有更改遗物重随流程。此为保护既有功能的必要集成修复，不是编译器报错修复。


## 2026-11-16 遗物美术接入

按用户新增指令，子会话用image gen逐个生成20张独立透明中心图，参考真实解码的原版装备（粗描边、手绘分块、高光金属及饱和魔法色），不生成外框。256px源PNG和id/名称/摘要映射在client/resources/abyss-relics；运行时contain到76×77主体、92×93安全区，20张压到共享512×512图集，压缩像素189357字节嵌入SWF，没有20次独立GPU上传；纹理恢复使用原bitmap。

背包/奖励/详情、第7格、重随目标与材料格均接入。所有遗物共用原生Equip彩虹框（48帧、20fps、自动随舞台注册/移除），没有AI重画外框，原装备帧像素摘要不变。build_abyss_relic_art_104.py生成独立.aspart，client同步脚本拼接，代码生成后依次跑passives/client同步。

验证：20个id、PNG和嵌入像素摘要、安全区、单纹理缓存与GPU恢复；实际UI方法夹具确认敌方预览读取/头像/队长、全员不可升级时leave请求回地图；炼金传承/遗物页签及等级门槛；原彩虹框/原装备框8项。合计前端专项13/13通过，其中装备被动夹具覆盖27/27文件与320组真理之刃边界。静态图集预览不替代真机界面/动画验收。


## 最终构建与安装记录（2026-11-16）

| 前端工作 | 提交 |
| --- | --- |
| 休息处离开（原生按钮、原send防重） | 97035f2 |
| 敌方预览 | 原读取逻辑支持，无需改动；方法级测试在10142cd |
| 旧报错文字 | 源码无“圣遗物”硬编码，无对应代码提交 |
| 被动对照及真理/反伤/圣佑修复 | 87774ca |
| 私有类类型解析改用官方AIR mxmlc | d9b69c9 |
| 保留既有词条传承入口 | 65a8618 |
| 20图标与原生彩虹框、UI/纹理测试 | 10142cd |

集成代码ea9edcf，181/181阶段冷编译通过，源清单与当前源码逐项一致；SWF SHA256为83ee9840296fca48ec764abeb18b6a57d1674e2765f10a6061678e5661e82793。初次FFDec在102_PanelActivityExploration.as:1054报私有基类类型不存在，改该阶段为AIR mxmlc后通过；没有因编译错误修改界面设计。缓存中的Gradle ZIP不完整导致ADT首次打包失败，恢复官方SHA256校验通过的完整缓存后，用同一份冷编译SWF重新执行官方ADT打包成功，没有用旧SWF替代新代码。

最终集成前端专项16/16（含原装备框/星尘/出售等），27份被动方法对照27/27，额外320组真理之刃边界及护盾/反伤专项通过；后端受影响回归172/172。存档压缩4/4、实际Java SaveStore边界8/8。批次有重叠，不相加为独立总数。安卓管理器使用便携Python3.11构建成功，其APK内117个服务端模块与当前源码一致。

build-merged.ps1合包成功：421+70个dex类无重复，客户端负载逐字节不变，4个清单资源引用正确。包名air.com.meng52.lol.android，版本1.0.5/1000005，ARMv7+ARM64。最终APK使用用户提供、匹配已装包的原密钥，v2/v3签名验证通过（v1未启用）；证书SHA256为9ea69ea5377b1d59f0b4b410d581ac21aea510933adcd733ea05913b5aed71af。迁移目录private/debug.p12的0c89…证书不匹配手机，不能作为该手机后续覆盖更新的原密钥。

交付：E:/My Project/lal-rebuild/release/lal-abyss-1.0.5-20261116.apk，151206707字节，SHA256 c56e3bf8a21828bfff24b32800e3c33891eee762e0a3ee1d4e6fefa7f4f330fc。经用户追加授权已adb install -r覆盖安装Success，手机上的base.apk摘要与交付包一致，firstInstallTime仍为2026-10-20 19:57:50；单机HomeActivity已启动。没有执行卸载或清数据。

真机仍待验收：第7格位置、各深渊界面布局、地图节点敌方展示、休息处离开按钮实际点击，以及游戏整场战斗与动画。A类延迟/手写技能通道尚未全面验收；27基准属于B类，真理之刃另有边界对照。本次只启动管理器，未操纵玩家局/英雄/资源。


## PR #37 客户端审核修复

恢复编译清单182/183两份词条传承选择器，避免只有四页签入口却遗漏真正选择逻辑。延迟炸弹、区域和引导保存原始小技能上下文，回调恢复原技能与同一份命中集合；大招不继承A类遗物，变身替换skill0后仍按原施法判定。复苏净化后跳过DOT循环副本中已清除的层，与服务端bd1cb61一致。

验证：27份B类样例逐命令对照仍27/27，320组真理边界、反伤/圣佑顺序通过；新增普通/太古复苏多DOT清除，炸弹/区域/引导的真实AS方法延迟来源和大招排除通过。UI专项3/3，包含两份选择器被纳入构建清单。此为方法夹具验证，渲染/调度仍为替身。


## Android 启动黑屏修复

直接在正常MainLLOL入口捕获到EncryptedLocalStore.setItem内部错误，调用栈为LocalStore.setItemStr → GlobalLocalStore.setVersion → checkClearLocalStore；统一AIR/合包签名后仍能复现，因此签名不是本次阻塞点。AIR官方记录相同的旧存储fallback写入失败问题：https://github.com/airsdk/Adobe-Runtime-Support/issues/3391 。

移动端descriptor显式采用fallbackMode=never、storageMode=os_store，避开失败的旧格式fallback访问。首次触及ELS前，按nativePath备份原始.dat和两份对应SharedPreferences到应用私有Local Store/els-before-compat-20261116；先写.pending、校验大小再改名，已有原始备份永不覆盖。没有调用EncryptedLocalStore.reset、卸载、清数据，也没有触及files/state中的玩家数据库。旧客户端缓存可能需要重新获取；原始缓存和密钥均保留以便恢复。

手机日志确认三个原文件分别6934528、166、65字节已保留，版本写入和初始化均通过。屏幕已显示游戏加载页，随后用户明确确认“已进主界面”。备份辅助函数以实际AS方法在合成文件系统执行，验证原始内容保留、重复启动不覆盖、Windows无副作用；诊断Socket和额外加载器均不进入正式源码。


## 第二轮自动审核修复

卡莎单次齐射的逐导弹结算边界保持原状，但这些上下文共享本次施法的遗物命中集合；同一存活目标在一次齐射只判定一次寒霜，下次齐射重新判定。removeBuff按类型删除遗物毒/灼烧层，即使没有普通Buff也能清除，亚索大招定向净化因此与服务端一致。

真实AS方法夹具覆盖3枚和5枚导弹（共8个独立结算上下文，只产生2次遗物判定）、按类型净化与保留其他层；27份B类基准、320真理边界及前轮延迟/复苏专项仍通过。追加实际SkillSet召唤策略校验52/52，验证后端召唤策略重绑定，并以旧错误ID作为拒绝反例。

手机第二次黑屏发生于临时诊断包，其重复备份检查会比较迁移后缓存与原备份的大小；该诊断逻辑未提交。正式674e3d7使用已有原备份直接保留、不重复比较的实现。正式包已覆盖安装，用户确认首次正常进入，随后要求优先检查PR并优化启动慢；重复重启和新版手机耗时仍待验，不据此宣称已稳定完成全流程。


## 第三轮审核：隔离触发护盾上下文

abyssShield104用可恢复的relic_shield来源调用原生addBuff，仅跳过当前技能manualEffectMultiplier，保留自身恢复增幅、圣佑和原盾合并规则。来源在finally恢复，普通技能盾仍按原倍率结算。

实际AS方法验证0.37/2.5外部倍率下太古坚守250盾、疾风125盾、圣佑150盾，普通技能盾仍为100×倍率。补用真实yasuoDamage104/yasuoNight104方法及夜临状态验证反伤20不二次缩至4。服务端同步修正英雄减伤/原生攻击保护对绝对反伤的影响。27份、320边界及此前52份召唤策略校验仍通过。脚本连续同步两次可重复，未手改生成区。
