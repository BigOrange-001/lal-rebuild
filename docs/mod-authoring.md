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

最小包只有 `manifest.json` 与 `heroes.json`，可以完全复用内置技能与素材。字段见示例与 Schema。`signType` 使用与客户端一致的 `attack`、`tank`、`assist`；`actionType` 使用 `forward`、`sly`、`stand`、`cunning`。这两者分别编译到原生 `tl[0]`、`tl[1]`，不把法术伤害误作职业类型。英雄普攻 `damageType` 独立选择 `physical`、`magic` 或 `true`，分别编译为 `tl[2]` 的 1、2、3。真实伤害不扣物防／魔防，沿用原版 `REAL_DAMAGE_RATE`（当前默认 0.3）及其他原生结算规则，不能理解为无条件造成面板攻击的 100%。技能动作的 `damageType` 仍按该动作公开规范选择。

### 位移与原版目标链扩展（2026-10-18）

本次是 API 1 的能力扩展，保留旧包行为与存档身份；不把整个协议升级为不兼容格式。包必须在 `requiredCapabilities` 声明实际使用的新能力，编辑器自动生成。旧游戏会因不认识能力而拒绝包，更新编辑器本身不会更新已安装游戏的服务端。现有客户端已实现以下运行逻辑，本次接通服务端校验和编译，无需为这些动作改写战斗执行器。

| 数据 | 所需能力 | 约束 |
| --- | --- | --- |
| 动作 `move_to_target` | `skill.move_to_target` | `distance` 必填，整数 0～10000；0 不额外限制距离，正数是移动距离上限。只选一个敌方目标，`maxTargets` 必须为 1，不接受伤害系数、伤害类型、持续回合或附加量。沿用原生碰撞／站位规则，不保证和目标坐标重合。 |
| 动作 `lockOnly: true` | `skill.target.lock-only` | 必须指定更早的同阵营 `lockToAction`，用于后续伤害／控制不再次按目标策略筛选。编译为原生空策略加目标锁，仍检查目标存活、射程等原生条件；位移动作不能启用此项。 |
| 动作 `maxTargets: -1` | `skill.target.unlimited` | 对筛选和射程内的全部有效目标结算，不是全地图无条件命中。其他合法值为 1～6，0 无效；位移动作只允许 1。 |
| 技能 `rankInfoTemplate` | `skill.description.rank-template` | 最长 4000 字符，支持 `{rank:动作索引:数字字段索引}` 显示百分数和 `{flat:动作索引:数字字段索引}` 显示整数，索引从 0 开始。引用必须存在且为数字字段，不开放旧式隐含首动作参数的 scale 表达式。 |
| 新英雄 `damageType: true` | `hero.damage.true` | JSON 中的值为字符串 `"true"`，不是布尔值。仅改变普攻原生伤害类型。 |
| 补丁修改 `damageType` | `hero.patch.damage-type` | 可替换为字符串 physical／magic／true；保留原值保护及作用域隔离，不能 clear。 |

突进后攻击同一敌人的动作示例（其他技能必填字段仍按 Schema 提供）：

```json
[
  {"type":"move_to_target","distance":0,"effect":"builtin:effect/FX60_GAREN_DASH","targetPolicy":"enemy_lane_frontmost","maxTargets":1},
  {"type":"damage","coefficient":1.32,"damageType":"physical","effect":"builtin:effect/FX60_GAREN_SLASH","targetPolicy":"enemy_lane_frontmost","maxTargets":1,"lockToAction":0,"lockOnly":true}
]
```

上述为旧版命名字段格式的扩展；完整原版技能现在使用下节的 `native-template-v1`，不再受旧格式转换子集限制。

属性包含生命、攻击、物防、魔防的基础值及每级成长，逐项检查最高合法等级后的有限值。`progression.preset` 为 `builtin:progression/default-player-hero`。`starUp` 必须显式 `null` 或指向同系列下一品阶；声明的下一变体必须存在，客户端升星入口与服务端使用同一链条。没有隐含的推断升星。

普通、队长、被动技能槽都必须声明，`null` 代表关闭。声音 `null` 表示静音。引擎可解析的素材是必需条件，不用缺失占位图伪装为成功导入。

## 自定义技能

旧版命名字段格式开放 `mod-engine-api-v1.json` 中列出的十六类通用动作和目标策略。每项使用命名字段，编译器生成原生动作数组。`timingUnit` 固定为 `ownerTurns`：准备和冷却按施法者行动机会计数；状态持续回合沿用原生 Buff 对受影响目标的计数规则。

动作最多 32 项，按顺序执行；锁定目标只能指向较早的同阵营动作。伤害、减益必须使用敌方策略；治疗、护盾和增益必须使用友方策略。`armor` 当前只作用于自身。技能等级固定采用现有 1–10 级规则；所有逐级增量在完整合法等级范围内校验。API 1 没有新增无限触发、递归施法、任意代码或新召唤策略的入口。

复用内置技能同样受能力检查。通用伤害、控制、治疗、护盾、增益和基础移动可复用；历史无执行分支的 `hitup`／`fleeup`、依赖特定英雄或技能 ID 的 `manual_ability`、召唤、炮台、分身及未开放动作不能重新绑定或做字段补丁。保留基础游戏这些技能的原有行为。需要使用完整原生模板接口，不能绕过旧格式的检查。

## 完整原生技能模板（1.1.0）

全部 1077 条原版技能可导入为本包独立技能；new 英雄绑定 `self:skill/<id>`，patch 可将现有英雄的技能槽替换为该引用。格式为：

```json
{
  "id": "my_skill",
  "name": "自制技能",
  "description": "可编辑说明",
  "model": "native-template-v1",
  "nativeTemplate": {
    "source": "builtin:skill/S_201001_5",
    "sourceDigest": "由编辑器读取原版技能计算的 SHA-256",
    "settings": {"pl": [0, 3, 200, 0, 0, 0], "skillUp": null},
    "passiveTrigger": 0
  },
  "actions": [{"type": "damage", "arguments": [1.2, 1, "FX60_GAREN_SLASH"]}],
  "upgrades": []
}
```

这是结构示意；来源摘要、原版字段及资源须从当前目录取值，不应直接把示意摘要当作可安装包。Schema 见 [mod-native-template.schema.json](../schemas/mod-native-template.schema.json)。

- `requiredCapabilities` 必须包含 `skill.native-template.v1`。新客户端在请求中声明该能力；旧客户端的激活、登录及玩法访问会明确拒绝。
- `settings` 保留原版全部非身份字段；`pl` 是六项时序／施放字段。成长在 `skillUp/skillUpPaths` 中编辑，顶层 `upgrades` 固定空数组。
- 每项 `actions` 使用 `type` 和原生顺序的 `arguments`，支持当前 73 种动作。可选 `origin` 记录添加动作的原版预设来源，可选 `settings` 只允许契约列出的单动作机制参数。
- 目标、锁定、分组、范围和上限等平行数组与动作对应。重排必须同步成长路径、条件引用、共享伤害和说明索引；非法或前向引用拒绝。
- 专属复合技能使用 `abilityParameters` 和 `abilityContract` 摘要，包含 44 类机制的 324 个参数。精确字段、默认值、类型和范围来自 [原生参数契约](../server/native_ability_parameters.json)。只允许固定机制的数据参数，不运行外部代码。
- 召唤／分身策略保留原始机制身份，编译时将策略技能绑定自动改为私有运行 ID。容量 1～16，存续回合 1～100；单位、策略和动作参数须一致。不可通过手写 `modNativeSource` 冒充可信来源。
- 模板来源 SHA-256 防止基础配置变化后静默套用旧契约。基础变化应重新导入审核；自制名称和数值调整不要求改变永久包身份。
- 合包保留机制来源、参数和索引；只对包内实体及引用执行原有命名空间重写。普通更新和卸载仍按原有存档冻结／缺失规则处理。

客户端改造保留原版技能的原始派发路径，为自制技能单独提供来源标识和参数读取。历史 `hitup/fleeup` 等原生无执行分支条目仍保留原始行为；不能把完整数据导入解释为新增游戏算法。覆盖清单与编辑入口见 [战斗机制目录](battle-mechanism-editor-catalog.md)。

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

## 卡面边框布局与免 root 导入（2026-10-19）

带框 PNG 可使用唯一的未压缩 tEXt 键 `lal.cardFrame`，值为整数 JSON 数组 `[x,y,width,height]`，描述整张 PNG 内的原版盾框基准区域。区域必须位于图片内，至少 8×8，比例须符合 103:118（允许像素取整误差）。包必须声明 `asset.image.card-frame`；服务端校验后把区域传入客户端素材清单。合包和图片原样导入保留 PNG 内元数据。绘制允许超出基准区域，布局和点击判断仅使用边框区域。没有此键的旧素材继续按旧方式显示。

Android 创作者／玩家将包保存在 Download（下载）或系统文件应用可访问的位置，通过“系统设置 → Mod 管理 → 导入英雄包”选择。SDK 51 的文件选择器统一使用 Storage Access Framework（最低支持 API 24），由系统授予所选文件权限，不读取 nativePath、不要求 root，也不申请所有文件访问权限。游戏立即读取、校验并复制安装包，后续启动不依赖下载目录中的原文件。

手机版整合端的默认安装目录位于应用私有 `files/state/mods`（跟随存档数据库目录），用户无需手动访问。电脑版／外置服务器使用配置的 --mods-root。`mods/inbox` 只作为宿主可选批量导入路径，不作为手机必须使用的入口。当前雷电测试连接电脑服务端，故安装副本保存在电脑端，而非模拟器的应用私有存储。


## 待测试的效果序列扩展

本轮增加 `skill.effect-sequence.v1` 和 `unit.summon.v1`。新旧模型并存，详情见 [条件与召唤物接口](mod-effect-sequence.md)。尚未运行测试、构建游戏安装包或合并。

## 1.0.3 与事件被动

新增模板、事件、能力声明和兼容规则见 [1.0.3 创作接口](mod-authoring-1.0.3.md)。本次扩展尚待用户功能验证。
