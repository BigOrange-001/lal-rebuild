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
| map | 节点数组；节点有 id、act（1～3）、layer（1～7）、type（weak/normal/elite/rest/boss）、next（节点 id 数组）、completed |
| current_node/available_nodes | 当前节点 id 或 null；现在可以选择的下一节点 id 数组 |
| pool | 以英雄家族 id 为键；值有 id、aid（含品质）、quality（5/6）、lv=125、slv（5/10）、temporary、can_orange |
| retries | 剩余重打次数；为 0 时仍可战斗，再失败才终止 |
| pending_choice | null 或 {node_id,options（英雄对象数组）,count（必须选的人数）,can_skip} |
| battle | null 或完整已保存开战结果；用于重进继续战斗 |
| rewards | 本局已获得奖励记录 |
| attempt | 已结算战斗次数，仅用于持久化随机数域 |

地图为 7 层/幕，每层 2～3 个候选节点，Boss 层单节点。前三层的所有路线都是弱敌；每条路线固定经过休息和精英层。
第一位上阵者为队长，三路编号 0/1/2，每路至少一人。因此有效阵容实际至少 3 人，最多 5 人。
星裔赠送皮肤只进入本局池，不写曾获得记录；其紫卡正常登场结算后仍开放橙卡阶段。

## 方法

下表的请求字段都位于 params，并且都要包含 actionID。表内 JSON 为额外请求字段，完整成功响应逐个存放在同名样例文件，包含所有共同字段。

| 方法 | 用途与请求 | 是否改变玩法状态 | 成功样例 |
| --- | --- | --- | --- |
| user.abyss_query | 查询/续局 `{}` | 仅首次初始化永久记录；不推进节点 | [query.json](roguelite-abyss-api-samples/query.json) |
| user.abyss_start | 开局 `{"difficulty":1,"deck":"blade","seed":20261116}`；seed 可省略由服务端随机 | 是；只可替换已终止局 | [start.json](roguelite-abyss-api-samples/start.json) |
| user.abyss_route | 选路线 `{"node_id":"1-1-0"}` | 是；只能在 available_nodes 中选 | [route.json](roguelite-abyss-api-samples/route.json) |
| user.abyss_combat | 开战 `{"team":[["A_1001",0,0.2],["A_1007",1,0.2],["A_1004",2,0.2]]}` | 是；冻结双方快照及凭证 | [combat.json](roguelite-abyss-api-samples/combat.json) |
| user.abyss_finish | 结算 `{fight_id,fight_kind:"abyss",metadata:{run_id,node_id},sign:1或2,teams:{team_a:[],team_b:[]}}` | 是；胜利推进、失败消耗次数，胜负均登记紫卡登场 | [finish.json](roguelite-abyss-api-samples/finish.json) |
| user.abyss_choose | 选人 `{"heroes":["A_1022","A_1023","A_1024"]}`；传候选 id，必须选满 count | 是；只添加，不能删除 | [choose.json](roguelite-abyss-api-samples/choose.json) |
| user.abyss_skip | 跳过选人 `{}`；弱敌不可跳 | 是 | [skip.json](roguelite-abyss-api-samples/skip.json) |
| user.abyss_rest | 休息提升 `{"hero_id":"A_1001","option":"skill"}`；option 另可为 orange | 是；单节点只能一次 | [rest.json](roguelite-abyss-api-samples/rest.json) |
| user.abyss_abandon | 放弃 `{}`；已掉落奖励保留，清理未结算战斗 | 是 | [abandon.json](roguelite-abyss-api-samples/abandon.json) |

开战额外返回 fight_id、seed、fight_kind、metadata、orgin_team_a、orgin_team_b、line=[3,1,1]、is_pve=false、round_max=0、expires。
保留现有协议拼写 orgin。前端把双方快照、三路和种子交给现有战斗场景，使用 abyss 结算分支，不走主线体力/关卡奖励。
teams 可省略；填写时只作诊断，单队至多30个对象，每个对象需 aid、有限 hp、hp_max>0，hp<=hp_max，绝对值不超过10亿。
服务端不读取客户端的面板、候选、圣遗物或奖励来结算。战斗凭证有效一小时；有效时 query 返回原凭证和快照继续，不能重复开战；过期后允许在当前节点重新开战。

## 错误码

所有失败回滚整个事务。同一 actionID 的失败不占用重放记录。

| 错误码 | 触发条件/方法 |
| --- | --- |
| InvalidRequestKey / RequestKeyConflict | 全方法：actionID 无效 / 同键不同载荷 |
| AbyssUnavailable | 全方法：配置未加载；start/star 无皮肤紫卡 |
| AbyssRunActive | start：已有 active 局 |
| AbyssDifficultyLocked / AbyssDeckLocked / AbyssInvalidSeed | start：未开放或格式错误的难度/卡组/种子 |
| AbyssNoRun | 除 query/start：没有 active 局 |
| AbyssNoChoice / AbyssChoiceRequired / AbyssInvalidChoice | choose/skip：没有候选、弱敌跳过、数量/候选/重复/容量无效 |
| AbyssChoicePending | route/combat/rest：尚未完成选人 |
| AbyssNodePending / AbyssInvalidRoute | route：当前节点或战斗未完成 / 非法路线 |
| AbyssInvalidNode | combat/rest：未选节点、已完成节点或类型不符 |
| AbyssUnknownHero / AbyssRestUnavailable | rest：英雄不在池中 / 已满技能或未开放升橙或选项无效 |
| InvalidFormation | combat：人数、英雄、重复、三路覆盖、位置（有限0～1）不合法 |
| AbyssBattlePending | combat：已存在有效战斗凭证 |
| MissingFight / UnknownFight / InvalidResult / InvalidBattle | finish：缺凭证、凭证过期/已消费、不合法 sign/诊断快照、kind/metadata 不符 |
| AbyssStaleBattle | finish：凭证与本局/当前节点不匹配 |
| BattleConfigChanged（沿用现有 Mod 策略） | finish：配置摘要与开战快照不兼容；以 Mod 通用协议为准 |

网关鉴权、存档及 Mod 错误沿用全局规则，不属于本模式新增码。

## 需用户决定

精英“保证至少2名（难度3起1名）橙卡”与“必须先紫卡登场解锁、排除池内英雄”在新账号或可用橙卡不足时不能同时满足。
暂保留解锁与排重规则，仅提供实际可用橙卡，不凭空解锁；需决定不足时的玩法。候选已固定入档，不能重进刷新。

## 前端待办

1. 模式入口与难度/卡组选择：abyss_account.max_difficulty/decks 与配置 roguelite_abyss。
2. 地图、续局与终止状态：abyss_run.map/current_node/available_nodes/status。
3. 候选界面、弱敌6选3和普通/精英5选1、跳过：pending_choice。
4. 5人三路布阵、第一位队长、禁止删池成员：pool 与 combat.team。
5. 战斗场景、凭证续战与结算：combat 返回快照、seed、metadata 和 fight_kind=abyss。
6. 休息处技能提升/升橙：pool.slv/can_orange，rest.option。
7. 卡池图鉴与永久解锁展示：unlocked 和 abyss_account.appeared。
8. 重打、放弃确认与奖励保留说明：retries、abandon、rewards。

客户端界面、客户端战斗结算和双端一致性均未验证。阶段2/3在下文追加圣遗物协议及被动规格。

## 圣遗物协议（阶段2）

所有 abyss 方法额外返回 `abyss_relics`（id 到物品对象的字典）和 `as_equips`（6个阵位，每阵位7格）。
第7格为 `as_equips[阵位][6]`，存圣遗物实例 id，空格为 null。前6格继续存 my_equips 的 id，圣遗物物品单独存 abyss_relics，不能通过普通装备出售/炼金接口操作。
加载旧6格存档时只追加 null；重复加载不重复追加。旧 user.equip_dress 的6格请求保留第7格；新7格请求能同时设置完整装备，并校验所有圣遗物归属与唯一占位。
所有预设继续使用现有的“阵位装备”语义；不是按预设复制多件装备。

物品完整例子（具体随机结果见 [relics.json](roguelite-abyss-api-samples/relics.json)）：

```json
{"id":"relic-实例id","type":"relic","relic_id":1,"name":"不灭圣盾","schema":1,
 "main":{"id":1,"ancient":false,"value":1,"shield_rate":0,"duration":3,"per_round":0,"threshold":0,"text":"登场时获得100%生命上限的护盾，持续3回合。"},
 "substats":[{"stat":"hp","value":0.1,"ancient":false,"text":"生命+10%"},
             {"stat":"ap","value":0.08,"ancient":false,"text":"攻击+8%"},
             {"stat":"tough","value":0.625,"ancient":true,"text":"*韧性+62.5%"}]}
```

副词条 value 为比例，对当次全部已有面板乘算，四属性为零时百分比仍为零。三条 stat 不重复。
主、副词条各独立7%太古概率；太古副词条取上限1.25倍，普通值均匀抽取；主词条太古状态在生成后固定。
#19始终 ancient=false。主词条的 value 仅为效果幅度；#12 value 为护盾额外倍率（普通1，即最终2倍，太古1.5，即最终2.5倍），以设计稿明确的2.5倍为准。
客户端直接显示 text，不自行拼效果文字；ancient=true 时 text 以 * 开头，另按专用太古颜色渲染。文本只描述实际效果。

| 方法 | 请求（除actionID） | 结果与状态变更 | 完整真实样例 |
| --- | --- | --- | --- |
| user.abyss_relics | {} | 查询背包和穿戴，初始化旧格位；同键重放 | [relics.json](roguelite-abyss-api-samples/relics.json) |
| user.abyss_relic_equip | {item_id,slot:0至5} | 穿到该阵位第7格，原件回背包；同键重放 | [relic_equip.json](roguelite-abyss-api-samples/relic_equip.json) |
| user.abyss_relic_unequip | {item_id} | 卸下此件；已卸下也成功；同键重放 | [relic_unequip.json](roguelite-abyss-api-samples/relic_unequip.json) |
| user.abyss_relic_reroll | {item_id,material_id} | 消耗另一件未穿戴圣遗物，重抽3副词条和各自太古标记，主词条不变，无其他资源消耗；同键重放相同结果且不再消耗 | [relic_reroll.json](roguelite-abyss-api-samples/relic_reroll.json) |

新增错误：AbyssUnknownRelic（除relics外：无效/非本人item_id）、AbyssInvalidRelicSlot（equip：非整数或不在0～5）、AbyssInvalidRelicMaterial（reroll：材料不存在或与目标同件）、EquipmentInUse（equip：其他阵位已穿；reroll：材料未卸下）。事务和重放共通错误同上。
这些接口不需要有 active 局，不改变本局池/地图。Boss奖励在结算事务中直接入背包，通关最后发额外保底，失败/放弃不回收；同凭证不重复发。

面板 battle_attributes 额外包含 `relic_contribution:{item_id,stats:{hp,ap,de_ph,de_ma,hit,flee,crit,tough},main_power_rate}`，stats 为副词条产生的实际面板增量，main_power_rate 为主词条计入战力的独立预算。
战斗快照透传 `relic_contribution` 与 `equip_passives`；后者为B类主词条列表，不覆盖 skillB。
A类小技能映射到配置中预生成变体（包含全部现有英雄/装备羁绊变体），snapshot.skill.abyss_relic_A 描述该附加效果，原动作和等级成长保持不变。
装备不参与深渊标准化快照，因此本模式完全不生效。前端的面板和战力必须按同一字段排除深渊装备贡献。

### 追加前端待办

9. 圣遗物背包、详情、对比与太古专用颜色：abyss_relics、main/substats.text/ancient。
10. 第7格穿脱、旧6格保存兼容：as_equips[*][6] 和 relic_equip/unequip。
11. 重随材料选择和消耗提示：relic_reroll，材料必须未穿戴且与目标不同。
12. 面板/战力同步展示与模式排除：relic_contribution，深渊直接使用标准化战斗快照。
13. A类新效果钩子：skill.abyss_relic_A。现有客户端没有“仅普通技能命中”的统一效果钩子；仅加载变体元数据不会自动生效，须按下一阶段被动规格接入所有原生、手写和延迟命中通道。
