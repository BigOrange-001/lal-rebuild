# Mod 系统实施与验收记录

日期：2026-10-18。开发基线：GitHub `main` 的 `c00e6ab487881b2e37c7bb63f56d2f778562fc75`。

本页记录实际实现、自动验证、原生运行证据与尚未覆盖的边界，不把自动检查扩大解释为所有设备和界面都已实测。产品要求见 [mod-system-design.md](mod-system-design.md)，作者格式见 [mod-authoring.md](mod-authoring.md)，接口与持久化见 [mod-api.md](mod-api.md)。

## 实际架构

1. `server/mod_schema.py` 定义 API 1 的严格字段、引用类型、动作白名单、版本范围和配额。`mod_packages.py` 负责 ZIP／JSON／媒体校验、安装暂存与发布、目录检查、跨进程注册表锁及永久编号。目录只登记可用内容，安装不自动启用或发卡。
2. `server/mod_compile.py` 在不可变基础配置上，为每个存档解析 `new`、`patch`、依赖、原值契约和冲突。输出独立的完整配置、`mod_roster` 侧表及 `cfg.mod_runtime`，不临时覆盖服务端共享配置。
3. `server/mod_service.py` 将登录 UID、Mod 修订、配置摘要和玩家状态修订绑定到预览／激活。每个存档保存固定版本、摘要、手动选择及已知身份；同一包允许不同存档使用不同组合。无 Mod 元数据的旧存档沿用原处理路径。
4. `server/mod_policy.py` 为实际玩法生成器提供统一的可用性、渠道、候选、品阶分类及上下文身份解析。配置中的私有别名不成为新的可持有英雄，也不泄漏进候选、商店或助战名册。
5. 客户端在登录后、构造英雄前同步有效配置和素材；账号、配置上下文不匹配的迟到结果被丢弃。“系统设置 → Mod 管理”负责存档选择、包／英雄开关、冲突预览、安装／卸载及备份入口。保存成功后要求重新进入，资源预载失败时阻止混用定义进入玩法。

`new` 的永久身份与玩家卡牌实例分别保存。`patch` 使用精确目标和可撤销覆盖；技能字段修改采用独立副本。`owned`、`arenaEnemy`、`pveEnemy`、`assist`、`summoned` 分别编译，定义不同的上下文通过受管别名选择。服务端开战快照与 AIR 初始化使用相同定义；原协议 `orgin_team_a`、`orgin_team_b` 保留。

API 1 是受约束的数据接口。十五类公开动作、目标策略、能力与具体配额由 `schemas/mod-engine-api-v1.json` 输出。未知动作、任意代码、ID 特判的特殊召唤／分身及未经适配的机制不会因为原始配置出现过就自动获准使用。可持久化养成契约发生不兼容变化时拒绝激活，第一版不进行部分迁移或截断进度。

## 玩法接入与默认值

所有实际支持且适用的选项默认开启。玩家单英雄覆盖优先于包覆盖；禁用状态、内容完整性和不适用条件优先于任何勾选。恢复默认清除手动覆盖。出现／获取渠道与补丁作用域独立保存。

| 稳定键 | 实际入口及规则 |
| --- | --- |
| `appearance.arena_enemy` | `arena_opponents.py` 与竞技场对手生成；候选、缓存签名和开战重新核对策略。至少五个合法英雄家族才能生成普通竞技场阵容。 |
| `acquisition.summon.normal` | `gameplay_roster.py` 的友情积分召唤；新增可持有英雄仅进入现有五阶英雄分类。 |
| `acquisition.summon.advanced` | 金砖召唤；新增英雄进入对应四／五阶分类，保持原分类权重和五阶保底。 |
| `acquisition.shop.hero_soul` | 碎片商店生成、展示、刷新和购买；按档位复用对应品阶的数量及价格模板，当前品阶为二／五／六阶。 |
| `appearance.fragment_enemy` | 掠夺机器人候选和开战快照；过滤后不足以覆盖路线时明确失败。 |
| `appearance.exploration_enemy` | `solo_progression.py` 的刷新后随机探索地图；首次手工编排地图保持固定，不因开关自动混入新英雄。 |
| `appearance.expedition_enemy` | **不支持**：当前远征是遣散英雄换取德诺石的玩法，没有敌人生成器。界面说明原因并禁用该选项。 |
| `appearance.campaign_random_enemy` | **不支持**：当前主线使用固定阵容，没有随机敌人槽。修改固定目标需要明确的补丁，不能把此开关当作随机注入。 |
| `appearance.assist_bot` | 静态本地好友机器人和动态公会伙伴；新英雄进入可被选择的队长位置，生成与缓存使用当前存档策略。 |
| `acquisition.summon.activity` | 活动英雄抽取；保持整卡／碎片、品阶和碎片数量分类的原概率，新增候选按标准五阶模板参与。 |
| `acquisition.exchange.hero` | 每日二十名六阶英雄勋章招募；展示与实际兑换使用同一份存档候选。 |
| `acquisition.exchange.activity` | 活动积分／限时英雄兑换；新五／六阶英雄使用对应既有价格模板，客户端表与购买验证一致。 |
| `acquisition.drop.campaign` | 主线掉落；新增英雄进入原关卡已有品阶分类，保留各分类的掉落概率，结算使用战斗私有随机种子。 |
| `acquisition.drop.activity` | 已存在、明确包含英雄的活动奖励受到对应策略检查。API 1 的新增玩家英雄**不适用**：普通活动当前没有随机玩家英雄掉落槽；不能填充材料固定奖励。 |
| `acquisition.drop.tower_hero` | 爬塔整卡候选、战前预检与结算；对应现有六阶英雄分类。 |
| `acquisition.drop.tower_soul` | 爬塔碎片候选、战前预检与结算；仅扩展该楼层原有品阶，不把其他品阶混入。现有模板为四／五／六阶。 |
| `usage.friend_assist` | 已解析助战卡的使用检查和战斗快照；本地模式当前只使用本地机器人／伙伴，不冒充远程玩家助战。 |
| `usage.destiny` | 既有羁绊的使用开关。API 1 未开放自制羁绊定义；无合法定义的新增英雄显示不适用。 |
| `usage.auxiliary_formation` | 德诺阵等已接入辅助位置的绑定及贡献检查；缺失／禁用英雄保留原位置数据，不提供属性加成。 |

开关只允许参与渠道，不保证抽取或出现。普通、高级、活动抽取及商店分别解析；过滤导致空品阶、保底缺失、敌人不足时，在扣资源前返回业务错误，不偷偷放回已排除英雄。自定义价格、权重和羁绊等尚未开放的非空声明被拒绝，不能静默忽略后仍显示成功。

商店因配置变化只收窄已展示商品并保持原购买／刷新账本；新增候选在正常刷新时进入，不借开关免费重抽。获取关闭不影响已经获得的英雄、碎片和奖励，包仍有效时已有碎片可以合成。

### 固定关卡的属性优先级

现有主线／活动中的 `enemy_unit_stats_by_diff` 是关卡作者指定的绝对属性快照，继续优先于英雄通用基础属性；探索敌人还会按玩家冻结战力校准。这些既有的关卡属性规则保留。

因此，`pveEnemy` 补丁中的技能、说明和表现可以按上下文生效，但不能宣称修改英雄 `baseStats` 必然覆盖每个固定关卡的独立生命／攻击／防御预算。针对关卡预算的扩展需要独立的关卡数据契约。对手强度校准同样不应被误解释为补丁失效。

## 缺失、事务和奖励保护

移除／停用 `new` 后，只根据该存档已记录的永久身份生成 `modMissing` 占位。等级、经验、技能等级、培养、进阶、装备、碎片和阵容引用继续保存；共享培养迁移器会在任何数值转换前跳过缺失定义。不能从媒体缓存继续运行该英雄。

占位英雄禁止新上阵、养成、出售、吞噬、遣散、助战及材料使用，也不计算队长、羁绊或辅助贡献。未改变的旧阵容／DN 缺失位置可以保留，避免编辑健康阵容时被迫删除其他冻结引用；移动或新指派缺失英雄会被拒绝。取回正常装备只解除原装备归属和共享位置，不创建、删除或重复发放物品。

开战意图保存有效摘要、原始双方快照和私有奖励种子。外部删除包后，依赖操作冻结，配置不匹配的过期意图也不会在新战斗或探索刷新时悄悄删除。普通配置切换受未完成战斗、培养等操作和探索未领取奖励阻止。

Mod 探索战斗另外保存奖励快照；胜利后、领取前仍保留原摘要和阵容依赖。文件缺失时不领取、不重新生成奖品；恢复匹配内容后按原快照领取。领取、购买、抽取、激活和测试发卡沿用事务与稳定请求编号去重。

移除 `patch` 从基础及其余合法补丁重新计算，不改变基础英雄卡牌身份。升级／降级不自动覆盖存档版本；内部号冲突明确阻止恢复，不部分改写旧引用。备份中的包不自动成为活动来源。

每次配置激活／恢复会保存一份上次 Mod 元数据备份，通过 `user.mods_backup` 的 `previous:true` 读取；备份移除旧的 `previous`，不会递归增长。恢复旧清单时合并当前已知英雄与身份映射，较晚获得的英雄保留原实例和进度，若旧清单未启用其包则转为缺失；恢复不删除这些后来获得的资产。

有 Mod 的存档使用持久的英雄实例序号高水位。首次激活／恢复从当前引用及该账号仍保留的操作账本播种；产卡的两条公共路径共用分配器，出售、吞噬及其他删除前先保留已有最大序号。计数与玩家事务一起保存和回滚，Mod 元数据回退不回退该进度；卸载后也不复用已经保留的实例号。未使用过 Mod 的存档继续沿用原分配行为。已经在外部清理、没有任何现存记录的历史编号无法追溯。

全局卸载将 `digest`／`contentDigest` 规范化为同一引用，矛盾摘要拒绝；预览、受影响存档和未结算检查、幂等载荷及最终目录删除使用相同固定摘要。检查目录按包报告导入错误；某个待导入包失败不改变当前活动清单，成功导入的其他包也只登记可用，不自动替换当前定义。

安装注册表在后端启动后被外部损坏或删除时，目录锁定写入并保留原始文件，不重建编号。依赖包的存档仍能登录，已知英雄转为缺失占位；Mod 管理保留可见的注册表错误，无 Mod 的其他账号继续使用基础配置。新安装／编号分配在注册表修复前明确拒绝，避免因恢复空目录而错误复用旧身份。

## 自动验证记录

测试使用临时安装目录和独立内存／临时 SQLite，不读取玩家真实数据库。服务端标准命令：

```powershell
python -B -m unittest discover -s server -p "test_*.py" -v
```

| 验证层 | 当前结果 | 可追溯报告 |
| --- | --- | --- |
| 服务端 | **最终 286 项全部通过，447.971 秒**。包含既有游戏回归、包目录、生产 RPC、玩法策略、永久编号、跨进程锁、Windows 联接及上传边界。 | `build/mod-server-release-final.log`；历史综合报告 `build/mod-server-final.log`。 |
| 客户端／构建脚本 | **84 项全部通过，18.393 秒**。涵盖 Mod 管理方法、缺失保护、备份恢复、冲突行保护及大差异分页；不冒称全部是原生界面操作。 | `build/mod-client-tests-final.log`。 |
| 客户端编译 | 161 阶段完整冷编译完成；管理页最终修改后重编译 151–161，报告中的全部来源 SHA 与当前源码一致。 | `build/mod-cold-final/report.json`、`build/mod-cold-final-v2/report.json`。 |

历史定向日志保留在 `build/mod-server-followup.log`、`build/mod-service-final.log`、`build/mod-service-followup.log`、`build/mod-registry-recovery.log`、`build/mod-instance-sequence.log` 和 `build/mod-instance-sequence-restore.log`。其中旧断言预期错误的原始失败与修正后的通过记录均保留，不改写执行历史；当前结论以对应修正后结果及最终复跑为准。

重点测试文件：

- `test_mod_packages.py`：包格式、资源、路径、摘要、重复身份、依赖、冲突、作用域和进度契约。
- `test_mod_service.py`：生产 RPC 鉴权、不同存档隔离、计划过期、幂等激活、安装／卸载、缺失恢复、装备及备份身份冲突。
- `test_mod_gameplay.py`：品阶概率、空池扣费边界、私有别名、缺失培养与阵容保护、冻结意图、商店购买账本、活动概率及可选择助战。
- `test_mod_vertical.py`：独立 SQLite 与真实包，通过生产 `Backend` 完成新增英雄发放／编队／开战／结算重试，同场同英雄双方技能定义隔离，以及探索未领取奖励的删包冻结／重装恢复。
- 既有竞技场、主线、爬塔、探索、培养、招募、装备、公会和协议测试继续参与全量回归。

`test_mod_vertical.py` 验证的是服务端接受客户端结果的契约。原生证据另外使用真实 AIR／Starling、交付 SWF 的 `Avatar` 和战斗循环，等待原战斗自然结束与结算回执；不以 Python `ReferenceBattle` 或提交固定 `sign` 代替。

| 原生场景 | 已观察到的结果 | 报告 |
| --- | --- | --- |
| Windows 最终无 Mod | 未安装或启用任何 Mod 的基础存档，五名原英雄进入真实战斗，第 22 回合自然结束并完成结算；管理页可访问。 | `build/mod-native-final-base-windows/report.json`，`passed:true`。 |
| Windows 两文件最小包及补丁作用域 | 复用内置素材的 `new` 英雄进入真实战斗；同场盖伦玩家侧 `S_800000_1`、敌方基础 `S_201001_3` 分别出现原生 `abilityHasCast` 记录，第 19 回合自然结束并完成结算。 | `build/mod-native-minimum-scopes-windows/report.json`，`passed:true`。 |
| Windows 最终管理页与媒体 | 真实管理页事件关闭普通召唤，预览、确认、退出重登后修订为 2 且开关仍为关闭；PNG 纹理解码、MP3 播放完成；第 11 回合自然结束并结算。使用最终 desktop SWF `aea9ae…`。 | `build/mod-native-final-manage-windows/report.json`，`passed:true`。 |
| Windows 目录导入与缺失 | 从管理页“检查目录”导入 `mods/inbox` 的包；删除活动包后仍能登录、进入管理页并显示缺失占位。 | `build/mod-native-directory-windows-v2/report.json`、`build/mod-native-missing-windows/report.json`，均 `passed:true`。 |
| Windows 最终恢复 | 重装匹配包恢复原实例，最终 desktop SWF 重新加载媒体并进入原生战斗，第 8 回合自然结束并结算。 | `build/mod-native-final-restored-windows/report.json`，`passed:true`。 |
| Windows 便携启动入口 | 隔离复制最终目录，用包内 Python 和未修改的 production launcher 启动真实服务与 AIR；作者工具校验、登录、管理页、缺失提示通过，24.72 秒正常退出，服务记录停止且端口已关闭。副本仅更换 QA 入口与独立应用 ID，原交付目录不含 QA 数据。 | `build/windows-entry-smoke/output2/report.json`，`passed:true`。 |
| Android 媒体与缺失 | `emulator-5554` 上的完整冷编译 QA APK 完成 PNG／MP3 加载、战斗与结算；另一次删除包运行显示缺失占位并能进入管理页。 | `build/mod-native-android-media-v2/report.json`、`build/mod-native-android-missing/report.json`，均 `passed:true`。 |
| Android 最终目录导入 | 使用最终 raw SWF `caafc0…` 的 QA APK，管理页“检查目录”事件实际导入新包并在目录中确认。 | `build/mod-native-final-android-directory/report.json`，`passed:true`。 |
| Android 最终恢复 | 在之前显示缺失的同一 UID 存档中重装相同包，原实例 `A_180000_5\|5` 的进度与阵容不变；最终 SWF 重新载入媒体、执行战斗，第 9 回合自然结束并收到结算成功回执。 | `build/mod-android-missing-session/restore-report.json`、`build/mod-native-final-android-restored/report.json`，均 `passed:true`。 |

上述 Android 证据来自 AIR 原生模拟器运行，不等于实体手机全机型验收。正常游戏 APK 完成结构、签名、资源、源码链与 SWF 一致性校验；为保留原游戏数据，运行验收使用独立应用 ID `org.bigorange.lal.mods.qa` 承载同一最终游戏 SWF，没有覆盖安装原游戏。Windows 系统文件选择器操作受自动化截图超时限制，已用正式支持的目录导入路径完成原生导入；没有将文件选择器记为通过。随后按用户要求停止 Computer Use。手工快速切号、备份 JSON 原生选择／保存、素材解码失败提示及所有英雄面板逐项操作尚未单独实测，相关协议与方法边界已有自动覆盖。

## 对照开发目标的验收映射

下表区分服务端／方法自动验证和已完成的原生场景。未单独实测的交互会明确列出；它们不据此被判定为代码未实现，也不被自动覆盖冒充原生通过。

| 编号 | 当前证据与状态 |
| --- | --- |
| A01 | 既有无 Mod 服务端行为参与 286 项完整回归；**Windows 最终无 Mod 登录、原英雄真实战斗及结算通过**，第 22 回合结束。没有把此场景扩大为所有养成／抽取页面的人工遍历。 |
| A02 | **Windows 原生通过**：两文件最小包复用内置素材，实际获得、编队、战斗自然结束与结算；服务端覆盖结算重试及进度保留。 |
| A03 | **Windows／Android 原生加载通过**：PNG 纹理建立、MP3 播放完成。包结构／丢失文件／解码边界自动检查通过；平台解码失败提示未专门故障注入实测。 |
| A04 | 严格字段／重复键／未知动作／损坏摘要／越界路径自动检查。 |
| A05 | 跨包相同本地 ID 共存、包内重复实体拒绝和永久身份检查。 |
| A06 | 相同内容去重、同版本不同内容冲突及测试发卡重试检查。 |
| A07 | 共享技能独立副本、精确目标和其他英雄不受影响有自动覆盖；Windows 原生记录了补丁与基础技能实际施放。说明面板与各效果逐项人工核对未单独完成。 |
| A08 | 重叠冲突、互不重叠组合、显式依赖链和中间摘要检查。 |
| A09 | 目标原值／逻辑单元摘要检查，不使用全基础配置版本粗略替代目标契约。 |
| A10 | 两存档真实 RPC 隔离、账号／摘要绑定和客户端迟到回调保护有自动覆盖；手工快速反复切号未单独原生实测。 |
| A11 | **Windows 手动 PvE 原生通过**：同场玩家与敌方为同一基础盖伦，私有／基础技能各自实际施放并完成结算。竞技场同场定义与快照有生产 RPC 自动覆盖，未另跑原生竞技场场景。 |
| A12 | 四核心渠道的候选、默认值、关闭项、价格／保底和购买策略有自动覆盖；**Windows 最终管理页普通召唤开关**完成实际编辑、预览、确认、重登持久验证，未冒称四渠道全部逐一原生操作。 |
| A13 | 空品阶、保底类别、敌人不足在扣资源前拒绝的边界检查。 |
| A14 | **Windows／Android 原生缺失占位与管理页可访问通过**；完整养成保留、阵容／DN 冻结、注册表运行中损坏及正常装备取回由生产 RPC 自动覆盖。未逐个原生遍历所有相关面板和装备取回按钮。 |
| A15 | 补丁回退、目标缺失、原实例关联和无重复发奖有自动覆盖；**Windows／Android 最终 SWF 原生重装恢复与结算均通过**，Android 复用了此前缺失的同一存档及实例。 |
| A16 | 未结算阻止切换、摘要变化冻结、过期缺失意图保留、探索未领取奖励快照及恢复有自动覆盖；原生战斗进行中外部删包未专门故障注入。 |
| A17 | 安装恢复、计划失效、持久契约、事务回滚与重试有自动覆盖；客户端新旧配置同步隔离及选择器取消由方法测试覆盖。最终包同步失败／进程中断的原生故障注入未单独完成。 |
| A18 | SQLite／Mod 元数据恢复先保留身份，内部号冲突明确阻止，并检查失败不改写注册表。 |
| A19 | 固定版本／摘要、开关保存和服务重启有自动覆盖；**Windows 最终管理页保存后退出重登通过**，手动关闭项仍为关闭，修订与摘要更新一致。 |
| A20 | **Windows／Android 已完成原生目录导入、管理页、媒体、真实战斗／结算、缺失及重装恢复**。Windows 使用最终 desktop SWF；Android 最终游戏 SWF 在独立 QA APK 中验收，正常包另有签名／双 ABI／内容一致性记录。系统文件选择器、原生备份文件选择／保存及实体手机未冒称已验。 |

## 平台构建与实测证据

开发目录是 `development/lal-mod-system`，分支 `feature/mod-system`，基于本页开头的 GitHub main 提交。没有修改原有个人存档或覆盖已安装的原游戏。

| 产物 | 位置／校验 |
| --- | --- |
| Android 正常游戏 APK | `build/lal-rebuild-1.0.2-mod-final.apk`；SHA-256 `ed08da94a4a37bea15f2162d72e0fefc3663a78e85395a9cfc9183fe756b1194`。 |
| Android 构建记录 | `build/lal-rebuild-1.0.2-mod-final.json`；实际包名 `air.com.meng52.lol.android`，版本 `1.0.2`／`1000002`，minSDK 21、targetSDK 36，ARMv7＋ARM64，v1＋v2 签名通过，证书与当前 1.0.2 交付包一致，不含探针或测试登录配置。 |
| Android 最终 raw SWF | `build/mod-cold-final-v2/stage-161.swf`；SHA-256 `caafc0a96a98d24c56d6eeb80a9dc2f622bf364634fcb079b47695282022c5bf`。 |
| Windows 最终 desktop SWF | `build/mod-cold-final-v2/desktop-MainLLOL.swf`；SHA-256 `aea9ae974b6828873eb08cdfb9006fad0c80d895bc7a723f249e3a7fd4c800fc`。只有平台启动相关的两类适配，战斗与 Mod 逻辑沿用相同源链。 |
| Windows 便携开发包 | `build/windows-mod-final/lal-mod-windows.zip`；构建记录 `build/windows-mod-final/build-record.json`。解压双击“开始游戏.cmd”；包含当前服务端、AIR／Python 运行依赖、作者工具、规范与示例，不包含个人存档。 |
| 完整源链证据 | `build/mod-cold-final/report.json`、`build/mod-cold-final-v2/report.json`；所有 161 份来源 SHA 与最终源码匹配。 |

Android 打包采用官方 ADT 的现代 Gradle 分支，正常游戏 APK 与独立 QA APK 内嵌相同最终 raw SWF。早期 targeted 探针缺少既有 `015_SendServiceAMFFun`，该构建只能用于调试；本页最终结算证据均来自完整冷链，不能将早期超时或缺类结果当作最终交付验收。

Windows 打包命令与 Android 标准构建方法见 `DEPLOYMENT.md`。正常 Android APK 仍通过 `127.0.0.1:8080`／ADB reverse 连接当前服务器。Windows 启动器使用自己的空闲本地端口及包内 `data`，关闭游戏时先通过控制台退出命令正常关闭自己创建的后端，超时才结束该子进程。

这是版本 1.0.2 基线上的 Mod 开发交付，没有自动发布新版本、推送或合并 GitHub main。文件选择器和实体设备等未覆盖项目已在上文列出；没有据此宣称所有设备、所有故障路径都经过人工实测。
