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
