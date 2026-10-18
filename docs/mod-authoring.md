# Mod API 1：英雄包作者与宿主管理说明

本页记录可执行协议。产品目标见 `mod-system-design.md`；编辑器 Schema 在 `schemas/mod-*.schema.json`，实际能力和配额在 `schemas/mod-engine-api-v1.json`。运行时还会检查 Schema 无法表达的引用、原值、资源解码、升级边界与补丁顺序。

## 最小创作流程

在项目根目录执行，下列 `python` 指服务端使用的 Python 3.10 或更新版本。工具不要求安装第三方 Python 包。

```powershell
python -B scripts/mod_tools.py template new work/my-hero
python -B scripts/mod_tools.py pack work/my-hero work/my-hero.heropack
python -B scripts/mod_tools.py validate work/my-hero.heropack
python -B scripts/mod_tools.py --mods-root state/mods install work/my-hero.heropack
python -B scripts/mod_tools.py --mods-root state/mods list
```

安装只登记可用内容。登录存档后，通过“系统设置 → Mod 管理”选择版本、渠道和英雄覆盖，预览后保存，再重新进入完成配置及素材同步。工具没有隐含发卡、修改数据库或消费资源的操作。服务端实际的 `--mods-root` 必须与工具一致；不填写时工具使用项目根目录 `mods/`。

`examples/mods/` 包含 `new-minimal`、`patch-skill`、`patch-data` 三份作者源文件和对应可直接验证的 `.heropack`。技能示例是格式演示，不声称已证实原版。源文件的 `files` 由 `pack` 自动重算，不能手写零摘要后直接当作有效包。

生成补丁或读取当前基础逻辑单元摘要：

```powershell
python -B scripts/mod_tools.py template patch work/restore-garen --target A_1001_5
python -B scripts/mod_tools.py template data-patch work/adjust-garen --target A_1001_5
python -B scripts/mod_tools.py target-digest A_1001_5 skills.normal
python -B scripts/mod_tools.py fork work/my-hero work/another-hero
```

`--config` 选择基础配置文件；工具按正式服务端顺序应用内置英雄、技能与属性修正后计算补丁摘要。直接对原始 JSON 摘要会遗漏这些启动修正。显式依赖另一补丁的中间结果，应从该组合的有效配置计算对应逻辑单元摘要。

## 身份与引用

包使用 UUID 和三段语义版本，英雄永久身份是 `mod:<包UUID>/hero/<id>/<variant>`。显示名字与本地英雄 ID 可以跨包重复。游戏内部英雄系列编号由注册器分配；同系列各品阶共享家族号。作者不能填写任意 `A_…` 号覆盖已有身份。

`builtin:avatar/A_1001_5` 是英雄目标，`builtin:skill/S_201001_5` 是技能，`builtin:portrait/A_1001_5`／`builtin:icon/A_1001_5` 是卡面与头像，`builtin:effect/E_008` 是普攻效果集合。单个技能视觉也以 `builtin:effect/FX…` 引用，必须存在于当前基础效果表。引用类别不允许混用。

`self:asset/portrait.png` 对应包内 `assets/portrait.png`，也可写完整的包内载荷相对路径。`self:skill/my_skill` 引用本包技能。跨包引用使用 `mod:<UUID>/skill/<id>` 或 `mod:<UUID>/hero/<id>/<variant>`，必须声明直接依赖。文件路径、网络 URL、脚本和外部磁盘路径不是资源引用。

依赖约束支持 `*`、精确 `1.2.3`、`^1.2.3`、`~1.2.3` 和逗号连接比较式 `>=1.0.0,<2.0.0`，按数字比较；可同时锁定内容摘要。一个存档只能选择同包的一个版本。安装可并存多个版本。更新不会自动覆盖当前存档，也不覆盖玩家明确取消的选项。

同包同版本同摘要重复安装会去重；同包同版本不同内容拒绝。分叉请使用 `fork`，生成新 UUID 并重写自身永久引用，重新打包。未签名或昵称相同不会授予覆盖权。API 1 不验证作者签名的信任关系，清单中的签名属于未验证资料。

## new 数据

最小包只有 `manifest.json` 与 `heroes.json`，可以完全复用内置技能与素材。字段见示例与 Schema。`signType` 使用与客户端一致的 `attack`、`tank`、`assist`；`actionType` 使用 `forward`、`sly`、`stand`、`cunning`。这两者分别编译到原生 `tl[0]`、`tl[1]`，不把法术伤害误作职业类型。`damageType` 独立选择 `physical` 或 `magic`。

属性包含生命、攻击、物防、魔防的基础值及每级成长，逐项检查最高合法等级后的有限值。`progression.preset` 为 `builtin:progression/default-player-hero`。`starUp` 必须显式 `null` 或指向同系列下一品阶；声明的下一变体必须存在，客户端升星入口与服务端使用同一链条。没有隐含的推断升星。

普通、队长、被动技能槽都必须声明，`null` 代表关闭。声音 `null` 表示静音。引擎可解析的素材是必需条件，不用缺失占位图伪装为成功导入。

## 自定义技能

API 1 开放 `mod-engine-api-v1.json` 中列出的十五类通用动作和目标策略。每项使用命名字段，编译器生成原生动作数组。`timingUnit` 固定为 `ownerTurns`：准备和冷却按施法者行动机会计数；状态持续回合沿用原生 Buff 对受影响目标的计数规则。

动作最多 32 项，按顺序执行；锁定目标只能指向较早的同阵营动作。伤害、减益必须使用敌方策略；治疗、护盾和增益必须使用友方策略。`armor` 当前只作用于自身。技能等级固定采用现有 1–10 级规则；所有逐级增量在完整合法等级范围内校验。API 1 没有新增无限触发、递归施法、任意代码或新召唤策略的入口。

复用内置技能同样受能力检查。通用伤害、控制、治疗、护盾、增益和基础移动可复用；历史无执行分支的 `hitup`／`fleeup`、依赖特定英雄或技能 ID 的 `manual_ability`、召唤、炮台、分身及未开放动作不能重新绑定或做字段补丁。保留基础游戏这些技能的原有行为。未来要开放它们，需要增加能力契约并验证客户端，而非忽略检查。

## patch 数据与回退

补丁包含精确目标、`expect` 和一项以上操作。`replace` 替换整槽或已开放字段；`set` 要求该字段的原值／摘要；`clear` 只允许关闭可空的技能槽和语音。省略字段保持原值。

`expect.sha256` 对所列语义单元做规范 JSON SHA-256。`skills.normal` 的摘要包括完整技能行，能发现机制、目标策略、说明和升级规则变化；它不是技能 ID 字符串的摘要。简单字段也可以用 `expect.value`。补丁不受无关配置更新影响。

第一版仅修改英雄、战斗属性、文字、技能和表现；不开放单位类型、品阶身份、等级上限、经验曲线、培养结构或碎片比例迁移。已有永久身份更新若改变这些持久契约，明确拒绝；不截断养成进度。

修改技能单字段采用独立技能副本并保持原技能品阶，避免影响共享它的其他英雄。玩家／竞技场／PvE／助战／召唤的定义分别编译。上下文定义通过受管别名选择，基础英雄身份与卡牌实例保持不变。

重叠写入会冲突；修改普通技能整槽与修改其冷却也属于重叠。不同字段可组合。后补丁只有明确依赖前补丁并验证中间结果后才能覆盖。一个包内部对同一位置重复写入也会拒绝，作者应合并为一个最终操作。依赖环、目标不存在和目标不匹配均不能转成 `new`。

停用／删掉 `patch` 后从不可变基础重新编译；停用／删掉 `new` 后，当前存档已记录的新英雄变成缺失占位并冻结，保留等级、装备与原始数据。旧英雄编号映射成为保留记录，不再分配给别的包。别的存档没有引用的英雄不会被凭空加入占位列表。

## 渠道与适用性

所有实际支持且适用的渠道默认允许。优先顺序为内容完整性、存档启用、单英雄覆盖、包覆盖、作者默认、引擎默认。出现／获取渠道与 `patchScopes` 独立：禁止敌人出现和允许敌人出现但使用基础技能是不同设置。开关关闭只停止后续对应产出，不删除已有英雄或碎片。

新增候选沿用原渠道品阶概率、保底与价格模板：普通池的玩家英雄类别为五阶，高级池为四／五阶；活动招募为五阶；每日整卡兑换为六阶；活动兑换为五／六阶；碎片商店现有模板为二／五／六阶；爬塔整卡为六阶，碎片为四／五／六阶。不适用品阶显示原因并禁用操作。

当前主线是固定阵容，派遣型远征没有随机敌人生成器，普通活动没有随机玩家英雄掉落槽；这些入口明确显示不支持／不适用。API 1 没有自制羁绊定义适配，也不接受无效的自定义价格、权重等声明；标准渠道模板仍然可用。活动兑换的新英雄会克隆对应品阶的现有价格模板，开关同时影响客户端表与服务端验证。

## 安全与文件生命周期

`.heropack` 是根目录清单 ZIP。所有载荷必须列入 `files` 并匹配 SHA-256。拒绝绝对路径、`..`、反斜线、Windows 保留名、大小写冲突、符号链接、加密 ZIP、异常压缩比和未申报文件。严格 JSON 拒绝重复键、非有限值、未知字段和过深结构。

压缩包上限 64 MiB，解包上限 128 MiB，单载荷 32 MiB，JSON 4 MiB，载荷最多 512，单类实体最多 256，依赖深度最多 16，同一有效配置最多新增 1024 个英雄。图像每边最多 2048、总像素最多 4194304（符合当前 Starling baselineConstrained 纹理上限）；全部有效图像别名的解码纹理合计不超过 128 MiB，全部有效音像资源合计不超过 128 MiB，包含上下文变体，防止单包合法而组合耗尽内存。PNG 支持非隔行 8 位 RGB/RGBA，检查 chunk CRC、完整像素压缩流及行滤波；JPEG 需要安装 Pillow 后实际解码，否则明确拒绝。音频支持最长 120 秒的 MP3，逐帧检查结构；AIR API 1 不接受 WAV。其他图像格式、可执行 SWF 和脚本明确拒绝。

组合上限还包括：技能 2048 个（含为上下文私有复制的技能）、补丁 1024 个、补丁操作 4096 项，以及规范化结构数据总计 16 MiB。在保留新身份编号之前检查作者实体总量，编译后再次检查私有技能总量；不能通过拆分多个包绕过这些限制。所有有效音频别名预加载后的 PCM 内存另外限制为 128 MiB，以逐帧验证得到的时长乘以保守的 48 kHz 双声道 float32 大小计算，防止大量压缩率高的合法 MP3 在解码时耗尽内存。

共享安装注册表使用独立的 64 MiB 总预算，读取和每次原子写入采用相同上限；单个包内 JSON 仍限 4 MiB。安装会在发布载荷目录前检查完整候选注册表；恢复身份、分配编号和扫描补全身份也在持久写入前检查。达到总预算时返回 `ModRegistryLimit`，保留已有注册表与活动包，不把容量限制标成损坏。永久身份及卸载后的保留记录计入该预算，不能靠重建注册表释放身份编号。

安装先校验，再写暂存目录并原子发布；崩溃后可从已发布、再次验证的清单恢复安装登记。宿主和命令行通过跨进程注册表锁协调分配与发布，等待超过 10 秒会返回 `ModRegistryBusy`，不会覆盖另一个进程刚写入的身份。安装、读取、卸载会在操作前拒绝存储目录内已存在的符号链接和 Windows junction，防止父目录将写入或删除重定向到根目录外。`packages/` 是活动安装来源；删除后不从缩略图或备份缓存继续运行。注册表损坏时保留损坏文件并拒绝新分配，基础游戏仍能启动，已知新英雄按缺失处理。应从可信备份恢复注册表，不能删掉注册表重新分配编号。

跨设备恢复会按永久身份校验内部编号。碰到已绑定冲突时阻止激活并报告需要完整迁移；第一版不对存档做部分重编号。卸载工具命令如下，仅清除对应活动包文件，保留身份记录：

```powershell
python -B scripts/mod_tools.py --mods-root state/mods uninstall <packageId> <version> --digest <内容摘要>
```

## 错误说明

错误返回包含 `code`、`path`、`message`。`ModIdentityConflict` 表示身份／版本重用，使用原文件或创建新版本／分叉；`ModTargetMismatch` 表示目标已变，检查基础／前置补丁后重新制作；`ModPatchConflict` 表示重叠修改，停用其中一项或明确依赖；`ModMissingDependency` 表示未选择必要依赖；`ModMigrationRequired` 表示持久进度契约或编号冲突，需要迁移，不能强制覆盖；`ModUnsupportedMedia` 表示没有对应解码与播放能力；`ModRegistryCorrupt` 表示身份注册表损坏，需要可信恢复。其他错误会定位具体文件和字段。

Schema 可通过 `python -B scripts/generate_mod_schemas.py` 重新生成。验证命令不代替游戏内启用预览与真实客户端验证；尤其 Windows／Android 最终包、图像／语音播放及同场双定义应按开发目标分别验收。
