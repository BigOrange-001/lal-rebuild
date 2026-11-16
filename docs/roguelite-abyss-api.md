# 深渊回廊后端接口

分支 `feat/roguelite-abyss`。接口使用现有网关、uid、sessionid 和 `params.actionID`。
完整可执行请求及成功响应见 [真实接口样例](roguelite-abyss-api-samples/)。样例由
`scripts/abyss_api_walkthrough.py` 在内存数据库的合成账号上导出；输赢为流程测试主动提交，不能视为战斗胜率证据。

## 通用规则

所有方法（包括 query）通过 `store.atomic_update`，`actionID` 必须为 1～180 字符的非空字符串。
同方法同 actionID 同请求重放首次响应，附 `replayed:true`；同键不同请求报 `RequestKeyConflict`。
不同 actionID 的 query 得到当前状态；不要用同一 actionID 轮询。
`user.battle_finish` 的 `fight_kind:"abyss"` 是 `user.abyss_finish` 的别名，二者共用去重命名空间，重放时应使用完全相同 params。
并发凭证结算最多成功一次，奖励与凭证消费同事务。与其他单机模式一致，sign 是客户端报告，不是服务器重演得出的胜利证明。

成功结果共同包含 `abyss_account`、`abyss_run`、`unlocked` 和 `replayed`。未开局时 abyss_run 为 null。
永久记录 abyss_account 包括 schema、obtained（曾获得的完整 aid）、appeared（结算过的紫卡 aid）、cleared（通过难度）、max_difficulty（1～10）、decks（已开放卡组 id）。
unlocked 包括 purple、orange、standalone_orange 三个 aid 列表。

## 本局对象

`abyss_run` 字段：

| 字段 | 类型及意义 |
| --- | --- |
| id/status | 字符串；status 为 active/cleared/failed/abandoned |
| seed/difficulty/deck | 整数种子、1～10 难度、blade/flame/venom/summon/star |
| map_version | 2＝路径地图（见下）。字段缺失＝旧局的 v1 分层地图，继续按旧图玩完 |
| map | 节点数组；节点有 id、act（1～3）、layer、col、type（weak/normal/elite/rest/boss）、next（节点 id 数组，只列真实连线）、completed、enemy_preview |
| current_node/available_nodes | 当前节点 id 或 null；现在可以选择的下一节点 id 数组 |
| pool | 以英雄家族 id 为键；值有 id、aid（含品质）、quality（5/6）、lv=99、slv（5/10）、temporary、can_orange |
| retries | 剩余重打次数；为 0 时仍可战斗，再失败才终止 |
| pending_choice | null 或 {node_id,options（英雄对象数组）,count（**最多**可选人数）,can_skip（现恒为 true）} |
| battle | null 或完整已保存开战结果；用于重进继续战斗 |
| rewards | 本局已获得奖励记录 |
| attempt | 已结算战斗次数，仅用于持久化随机数域 |

### 路径地图（map_version 2，2026-11-16 起新开局）

每幕：layer 1～6 为路线层（4 列网格，col 0～3），layer 7 为 Boss 前固定休息处，layer 8 为 Boss。
休息处和 Boss 每幕各 1 个节点，col 为 null（前端居中），id 为 `{act}-7-0` / `{act}-8-0`；路线节点 id 为 `{act}-{layer}-{col}`。
生成：按局种子从第 1 层随机起点走出 4 条路径（前两条起点不同），每步到下一层的 col-1/col/col+1，路径连线互不交叉；
节点＝路径经过的格子，next＝路径实际走过的相邻对。每层 2～4 个节点，路线节点 1～3 条出边。第 6 层全部连到休息处，休息处连 Boss，Boss 连下一幕第 1 层全部节点（第 3 幕 Boss 的 next 为空）。
类型：第 1 幕第 1～3 层全为弱敌；第 2、3 幕第 1 层全为普通战；其余按权重普通 55%／精英 25%／休息 20%（难度 10 精英 35%，配置 `roguelite_abyss.map_weights`）。
约束：同一条边两端不同为精英、不同为休息；第 6 层不出休息；同一节点的不同出边尽量是不同类型；每幕路线层至少 1 个精英（难度 10 至少 2 个）和 1 个休息；
至少有一条从第 1 层到第 6 层完全避开精英的路线；难度 5 起任一路线最多经过 1 个路线层休息处。不满足就换子种子重生成（40 次，超限用固定保底图）。
所有节点类型开局即全部可见，前端不需要遮挡；敌方阵容预览仍建议只对可前往节点展开。
第一位上阵者为队长，三路编号 0/1/2，每路至少一人。因此有效阵容实际至少 3 人，最多 5 人。
星裔赠送皮肤只进入本局池，不写曾获得记录；其紫卡正常登场结算后仍开放橙卡阶段。
初始25名普通英雄的紫/橙阶段均立即解锁；can_orange 不要求这些英雄先登场。其他持有/曾获得英雄仍须紫卡登场结算后解锁橙阶段。
全部单位按99级、不突破；紫卡直接用自身紫卡配置原始四维。橙卡用同英雄99级紫卡四维×1.4，技能/被动取橙卡；仅橙皮肤用自身99级橙卡四维×0.7。玩家原生羁绊随后按本局阵容池全体成员判定，同品质集齐即可为相关出战英雄激活属性和技能变体；敌方仍按实际出战阵容判定。`orgin_team_a[*].bonds_104` 与技能、属性一起冻结到本场战斗及待结算记录；已有待结算战斗保持原快照，后续新战斗使用当前阵容池。主线配置不变。

## 方法

下表的请求字段都位于 params，并且都要包含 actionID。表内 JSON 为额外请求字段，完整成功响应逐个存放在同名样例文件，包含所有共同字段。

| 方法 | 用途与请求 | 是否改变玩法状态 | 成功样例 |
| --- | --- | --- | --- |
| user.abyss_query | 查询/续局 `{}` | 仅首次初始化永久记录；不推进节点 | [query.json](roguelite-abyss-api-samples/query.json) |
| user.abyss_start | 开局 `{"difficulty":1,"deck":"blade","seed":20261118}`；seed 可省略由服务端随机 | 是；只可替换已终止局 | [start.json](roguelite-abyss-api-samples/start.json) |
| user.abyss_route | 选路线 `{"node_id":"1-1-0"}` | 是；只能在 available_nodes 中选 | [route.json](roguelite-abyss-api-samples/route.json) |
| user.abyss_combat | 开战 `{"team":[["A_1001",0,0.2],["A_1007",1,0.2],["A_1004",2,0.2]]}` | 是；冻结双方快照及凭证 | [combat.json](roguelite-abyss-api-samples/combat.json) |
| user.abyss_finish | 结算 `{fight_id,fight_kind:"abyss",metadata:{run_id,node_id},sign:1或2,teams:{team_a:[],team_b:[]}}` | 是；胜利推进、失败消耗次数，胜负均登记紫卡登场 | [finish.json](roguelite-abyss-api-samples/finish.json) |
| user.abyss_choose | 选人 `{"heroes":["A_1022","A_1023","A_1024"]}`；传候选 id，1～count 名不重复候选（弱敌最多 3 人，其余最多 1 人） | 是；只添加，不能删除 | [choose.json](roguelite-abyss-api-samples/choose.json) |
| user.abyss_skip | 跳过选人 `{}`；所有选人（含弱敌）都可跳过 | 是 | [skip.json](roguelite-abyss-api-samples/skip.json) |
| user.abyss_rest | 休息提升 `{"hero_id":"A_1001","option":"skill"}`；option 另可为 orange；传 {"option":"leave"} 不需hero_id，直接完成节点且不修改英雄 | 是；单节点只能一次 | [rest.json](roguelite-abyss-api-samples/rest.json) |
| user.abyss_abandon | 放弃 `{}`；已掉落奖励保留，清理未结算战斗 | 是 | [abandon.json](roguelite-abyss-api-samples/abandon.json) |

开战额外返回 fight_id、seed、fight_kind、metadata、orgin_team_a、orgin_team_b、line=[3,1,1]、is_pve=false、round_max=0、expires。
保留现有协议拼写 orgin。前端把双方快照、三路和种子交给现有战斗场景，使用 abyss 结算分支，不走主线体力/关卡奖励。
teams 可省略；填写时只作诊断，单队至多30个对象，每个对象需 aid、有限 hp、hp_max>0，hp<=hp_max，绝对值不超过10亿。
服务端不读取客户端的面板、候选、深渊遗物或奖励来结算。战斗凭证有效一小时；有效时 query 返回原凭证和快照继续，不能重复开战；过期后允许在当前节点重新开战。

## 错误码

所有失败回滚整个事务。同一 actionID 的失败不占用重放记录。

| 错误码 | 触发条件/方法 |
| --- | --- |
| InvalidRequestKey / RequestKeyConflict | 全方法：actionID 无效 / 同键不同载荷 |
| AbyssUnavailable | 全方法：配置未加载；start/star 无皮肤紫卡 |
| AbyssRunActive | start：已有 active 局 |
| AbyssDifficultyLocked / AbyssDeckLocked / AbyssInvalidSeed | start：未开放或格式错误的难度/卡组/种子 |
| AbyssNoRun | 除 query/start：没有 active 局 |
| AbyssNoChoice / AbyssInvalidChoice | choose/skip：没有候选；选 0 人或超过 count、候选不存在、重复、超出池容量（AbyssChoiceRequired 已不再出现） |
| AbyssChoicePending | route/combat/rest：尚未完成选人 |
| AbyssNodePending / AbyssInvalidRoute | route：当前节点或战斗未完成 / 非法路线 |
| AbyssInvalidNode | combat/rest：未选节点、已完成节点或类型不符 |
| AbyssUnknownHero / AbyssRestUnavailable | rest：英雄不在池中 / 已满技能或未开放升橙或选项无效 |
| InvalidFormation | combat：人数、英雄、重复、三路覆盖、位置（有限0～1）不合法 |
| AbyssBattlePending | combat：已存在有效战斗凭证 |
| MissingFight / UnknownFight / InvalidResult / InvalidBattle | finish：缺凭证、凭证过期/已消费、不合法 sign/诊断快照、kind/metadata 不符 |
| AbyssStaleBattle | finish：凭证与本局/当前节点不匹配 |
| ModBattleConfigChanged（沿用现有 Mod 策略） | finish：配置摘要与开战快照不兼容；以 Mod 通用协议为准 |

网关鉴权、存档及 Mod 错误沿用全局规则，不属于本模式新增码。

## 初始卡池与精英保证

初始25名普通英雄已全部开放橙卡，因此池容量20的规则保证始终存在足够池外英雄。未满池时精英固定提供5名不同家族的候选，难度1～2至少2名橙卡，难度3～10至少1名橙卡；只从已解锁且不在本局池中的英雄抽取。满20人不再选人。
此前橙卡不足的待决定项已由2026-11-16新版设计解决。候选仍在生成时固定入档，重进不刷新。

## 前端待办

1. 模式入口与难度/卡组选择：abyss_account.max_difficulty/decks 与配置 roguelite_abyss。
2. 地图、续局与终止状态：abyss_run.map/current_node/available_nodes/status。
3. 候选界面、弱敌6选最多3、普通3选1、精英5选1、前两幕Boss橙卡3选1、跳过：pending_choice。
4. 5人三路布阵、第一位队长、禁止删池成员：pool 与 combat.team。
5. 战斗场景、凭证续战与结算：combat 返回快照、seed、metadata 和 fight_kind=abyss。
6. 休息处技能提升/升橙：pool.slv/can_orange，rest.option。
7. 卡池图鉴与永久解锁展示：unlocked 和 abyss_account.appeared。
8. 重打、放弃确认与奖励保留说明：retries、abandon、rewards。

客户端界面、客户端战斗结算和双端一致性均未验证。阶段2/3在下文追加深渊遗物协议及被动规格。

## 深渊遗物协议（阶段2）

所有 abyss 方法额外返回 `abyss_relics`（id 到物品对象的字典）和 `as_equips`（6个阵位，每阵位7格）。
第7格为 `as_equips[阵位][6]`，存深渊遗物实例 id，空格为 null。前6格继续存 my_equips 的 id，深渊遗物物品单独存 abyss_relics，不能通过普通装备出售/炼金接口操作。
加载旧6格存档时只追加 null；重复加载不重复追加。旧 user.equip_dress 的6格请求保留第7格；新7格请求能同时设置完整装备，并校验所有深渊遗物归属与唯一占位。
所有预设继续使用现有的“阵位装备”语义；不是按预设复制多件装备。

物品完整例子（具体随机结果见 [relics.json](roguelite-abyss-api-samples/relics.json)）：

```json
{"id":"relic-实例id","type":"relic","relic_id":1,"name":"不灭圣盾","schema":1,
 "main":{"id":1,"ancient":false,"value":1,"shield_rate":0,"duration":3,"per_round":0,"threshold":0,"text":"登场时获得100%生命上限的护盾，持续3回合。"},
 "substats":[{"stat":"hp","value":0.1,"ancient":false,"text":"生命+10.0%"},
             {"stat":"ap","value":0.08,"ancient":false,"text":"攻击+8.0%"},
             {"stat":"tough","value":0.625,"ancient":true,"text":"*韧性+62.5%"}]}
```

副词条 value 为比例，对当次全部已有面板乘算，四属性为零时百分比仍为零。三条 stat 不重复。副词条 text 固定保留1位小数（如暴击+31.5%、*韧性+62.5%）；value 保留原精度，不按显示值截断。
主、副词条各独立7%太古概率；太古副词条取上限1.25倍，普通值均匀抽取；主词条太古状态在生成后固定。
#19始终 ancient=false。主词条的 value 仅为效果幅度；#12 value 为护盾额外倍率（普通1，即最终2倍，太古1.5，即最终2.5倍），以设计稿明确的2.5倍为准。
客户端直接显示 text，不自行拼效果文字；ancient=true 时 text 以 * 开头，另按专用太古颜色渲染。文本只描述实际效果。

| 方法 | 请求（除actionID） | 结果与状态变更 | 完整真实样例 |
| --- | --- | --- | --- |
| user.abyss_relics | {} | 查询背包和穿戴，初始化旧格位；同键重放 | [relics.json](roguelite-abyss-api-samples/relics.json) |
| user.abyss_relic_equip | {item_id,slot:0至5} | 穿到该阵位第7格，原件回背包；同键重放 | [relic_equip.json](roguelite-abyss-api-samples/relic_equip.json) |
| user.abyss_relic_unequip | {item_id} | 卸下此件；已卸下也成功；同键重放 | [relic_unequip.json](roguelite-abyss-api-samples/relic_unequip.json) |
| user.abyss_relic_reroll | {item_id,material_id,substat_index:0至2} | 消耗另一件未穿戴深渊遗物，只重随所选的一条副词条，重新随机种类、数值和太古；新种类不与另两条重复。另两条（含太古状态）及主词条保持不变，无其他资源消耗；同键重放相同结果且不再消耗 | [relic_reroll.json](roguelite-abyss-api-samples/relic_reroll.json) |

新增错误：AbyssUnknownRelic（除relics外：无效/非本人item_id）、AbyssInvalidRelicSlot（equip：非整数或不在0～5）、AbyssInvalidSubstatIndex（reroll：缺少索引、不是整数或不在0～2，布尔值不接受）、AbyssInvalidRelicMaterial（reroll：材料不存在或与目标同件）、EquipmentInUse（equip：其他阵位已穿；reroll：材料未卸下）。事务和重放共通错误同上。
这些接口不需要有 active 局，不改变本局池/地图。Boss奖励在结算事务中直接入背包，通关最后发额外保底，失败/放弃不回收；同凭证不重复发。

面板 battle_attributes 额外包含 `relic_contribution:{item_id,stats:{hp,ap,de_ph,de_ma,hit,flee,crit,tough},main_power_rate}`，stats 为副词条产生的实际面板增量，main_power_rate 为主词条计入战力的独立预算。
战力公式沿用现有公式，在原“1+各技能因子”的技能乘区中**加上**main_power_rate；普通主词条为0.15，太古为0.1875（时之沙不生成太古）。副词条的面板增量已经计入四维与四属性，不能再额外加一次。
战斗快照透传 `relic_contribution` 与 `equip_passives`；后者为B类主词条列表，不覆盖 skillB。
A类小技能映射到配置中预生成变体（包含全部现有英雄/装备羁绊变体），snapshot.skill.abyss_relic_A 描述该附加效果，原动作和等级成长保持不变。
装备不参与深渊标准化快照，因此本模式完全不生效。前端的面板和战力必须按同一字段排除深渊装备贡献。
原探险仍排除前6格的养成，但新增深渊遗物在探险生效；助战快照也透传独立装备通道。不能把原 hero_only 标志直接用于禁用第7格，只有 abyss_standardized 才禁用深渊遗物。

### 追加前端待办

9. 深渊遗物背包、详情、对比与太古专用颜色：abyss_relics、main/substats.text/ancient。
10. 第7格穿脱、旧6格保存兼容：as_equips[*][6] 和 relic_equip/unequip。
11. 重随目标副词条选择、材料选择和消耗提示：relic_reroll.substat_index，材料必须未穿戴且与目标不同，只修改所选1条。
12. 面板/战力同步展示与模式排除：relic_contribution，深渊直接使用标准化战斗快照。
13. A类新效果钩子：skill.abyss_relic_A。现有客户端没有“仅普通技能命中”的统一效果钩子；仅加载变体元数据不会自动生效，须按下一阶段被动规格接入所有原生、手写和延迟命中通道。

## 战斗被动对接（阶段3）

完整公式、顺序、次数和来源标记见 [装备被动规格](roguelite-abyss-equip-passive.md)。B类在 equip_passives 中独立执行，不能覆盖 skillB。
对照样例为 [27份普通/太古逐事件输入输出](roguelite-abyss-equip-passive-cases/)，服务端模型已重放，集成分支另用实际客户端AS方法夹具逐命令对照27/27通过；渲染/调度为替身，真实客户端整场与Android仍未验收。

14. 客户端实现B类装备被动通道、嗜血来源标记、普通技能及延迟命中上下文，并逐步运行27份基准，再进行真实整场双端一致性验证。
15. 所有放弃入口共用一个二级确认框，默认焦点“继续本局”；英雄详情保持原6格两列，第7格放两列中间、英雄形象下方（新版设计要求，后端字段不变）。

## 校准与验收边界

当前普通战系数为第1/2/3幕0.8/1.0/1.2；难度倍率依次为0.80、0.86、0.92、0.99、1.06、1.13、1.22、1.30、1.40、1.50，仅普通战、精英战和Boss使用。第1幕弱敌所有难度固定0.55，精英×1.3、Boss×1.6及重打次数保留。配置字段enemy_rates/difficulties是前端显示和新开局敌人快照的数值来源，不要写死旧表。
开局只冻结节点enemy_preview（aid、quality/star、lv=99、slv=5、line、pos、leader、is_skin、limit_break），不生成战斗面板。pos为原生战场坐标，line为0～2；休息节点为空数组。客户端只读显示。首次开战据此生成并保存完整快照，重打沿用；旧局已有enemies快照保留，缺预览时从旧快照投影。新版规则用于新开局。未运行本版胜率校准。
此前[离线报告](roguelite-abyss-calibration.md)中的40局流程与60场起始卡组普通战属于旧敌人参数的历史结果，不能当作本版验收。144场灵魂塔探针不涉及深渊敌人表；上述结果均不代表客户端/Android完成验收。

## 新版候选与敌方阵容（2026-11-16）

弱敌6选3全紫；普通3选1；精英5选1（难度1～2保证2橙，3起保证1橙）；前两幕Boss胜利后3橙选1可跳过，最终Boss直接结算。池满20人不再选人。先判皮肤，再判品质；普通每卡橙率1%/1.5%/4%，精英非保证卡4%/15%/40%，皮肤0/15%/35%，Boss皮肤0/15%。橙阶段未解锁给同类紫卡，橙独有皮肤仅两项都命中时出现；同界面英雄不重复，保证橙从已解锁且不在池中英雄抽取。

敌方橙卡配额：第1幕弱敌0、精英及之后普通1、Boss2；第2幕普通/精英2、Boss3；第3幕1～3层普通/精英3，4～6层4，Boss5。皮肤计入配额；普通/弱敌不出皮肤，精英0/1/2、Boss0/2/4；Boss皮肤同定位替换，第3幕主题区别于第1幕。敌方皮肤不受玩家解锁限制。难度7起Boss额外成员仍保留。

休息离开真实请求/响应：[rest_leave.json](roguelite-abyss-api-samples/rest_leave.json)。leave沿用原事务、actionID重放与节点检查；重复完成或非休息处报AbyssInvalidNode。

## 玩法调整（2026-11-16，map_version 2 / rules schema 4）

**敌方阵容随机化**（同一 rng(seed,'enemy',node_id)，重打一致；旧局已冻结的 enemy_preview 不变）：
- 分路：随机一个三路每路 1～3 人的分配（3 人 1/1/1；4 人 2/1/1 的排列；5 人 2/2/1 或 3/1/1 的排列；6 人同理），英雄先打乱再填入。
- 路内前后：tank 在前，其余在后，同类随机；pos 为原生坐标整数，范围约为战线长度的 13%～53%。
- 队长：普通/弱敌/精英从全队均匀随机；Boss 保留手配主题队长（皮肤替换时可能换成同定位皮肤）。enemy_preview 第 0 位恒为队长。
- 橙卡位：全部在全队随机，不再优先队长。精英的保底橙卡即“被强化者”，从非队长成员中随机；四维 ×1.2（`elite_limit_break_multiplier`）只加给它。
- enemy_preview 新增 `limit_break`（0/1），被强化者为 1，开战快照的对应单位也带 `limit_break:1`。该字段**只用于显示**原生突破极限脉冲边框（前端不显示“突破极限”文字），属性只由倍率决定，没有走 base_unit 的 npc_limit_break。
- 开战快照的 line/pos/leader 与 enemy_preview 完全一致（`preview_from_units(orgin_team_b)==enemy_preview`）。旧局缺 limit_break 时精英仍强化第 0 位，与旧行为相同。

**卡池排除**：配置 `roguelite_abyss.excluded_families`（随配置下发客户端）列出永不进入本模式的英雄家族：
- 规则 A：原生配置（加载补丁前的 full-config）中主技能或队长技为占位模板 S_9000～S_9005 的家族。补丁后来改写技能 id 的家族仍算未实装。S_9140/S_9150/S_9160 不是模板。
- 规则 B：解说 A_1903/A_1904/A_1905/A_1909；规则 C：签到预览占位 A_190001。
- 当前结果：A_1139、A_1140、A_1212、A_1224、A_1225、A_1227、A_1311、A_1903～A_1906、A_1908～A_1910、A_1997～A_1999、A_190001。
- 过滤位置：unlocked 的 purple/orange/standalone_orange、skin_purple、skin_orange_only、enemy_skin_orange。已在进行中局池子里的不移除。
- 客户端图鉴的“未解锁”名单＝全部 A_1*_5 与 skin_orange_only，减去 excluded_families，再减去 unlocked。
