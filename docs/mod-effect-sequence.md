# 条件、混合治疗与自定义召唤物接口

状态：待审查合并。2026-10-19 已完成客户端增量编译、同签名安装及用户实机验证；未运行自动化测试套件。人工确认范围为“大肥鱼·鲸鲸示例”的技能与召唤流程，不代表所有组合均已验证。

这是对 Mod Engine API 1 的显式能力扩展，旧包行为保持原约定。新包分别声明 `skill.effect-sequence.v1` 和 `unit.summon.v1`；服务端将其加入 `requiredClientCapabilities`。没有声明这些能力的旧客户端不能启用或进入对应存档，避免静默跳过新动作。

## 单位

`heroes[].unitType` 增加 `summon`。它仍使用持久注册表分配和备份的稳定编号，单位类型由编译器写入 `modUnitType`，客户端与参考引擎据此识别召唤物。不能通过更改包版本将已注册英雄改成召唤物，也不能让召唤物升星。

召唤模板的获取、商店、敌人生成、好友助战等渠道全部关闭，测试发卡接口也拒绝给玩家发放召唤模板。召唤模板不写入玩家的 `knownHeroes` 持有角色快照。当前扩展不开放递归召唤。

## 技能

`model: effect-sequence-v1` 使用以下字段：`id`、`name`、`description`、`warmup`、`cooldown`、`range`、`trigger`、`actions`、`rankInfoTemplate`、`maxLevel`。

- `trigger.kind = ready`：冷却就绪时可触发。
- `trigger = {"kind":"absent_buff","buff":"purify"}`：仅当自身没有净化时可触发。作为被动时在原有回合起始被动检查处执行；不会被不相关的护盾或强化状态挡住。
- `actions`：1～32 个有序步骤，操作为 `heal`、`damage`、`buff`、`move`、`push`、`summon`。
- `maxLevel`：1～10；成长为初值加 `growth[field] × (等级−1)`，不自动复利。

可选目标为 `self`、`all_allies`、`all_enemies`、`ally_radius`、`lane_lowest_hp`、`lane_front`、`previous`、`enemy_radius`。范围沿用原版分路距离：半径只覆盖中心所在分路，单位为原生位置码；全场目标显式使用 `all_allies/all_enemies`。`range` 限制本路选定敌人的距离。

`centerAction` 为从 0 起的前序动作索引，`-1` 表示施法者；禁止前向、循环和越界引用。`previous` 保留前序步骤选定的同一批活目标，不重新选敌；`enemy_radius` 使用中心动作执行前记录的位置，即使中心目标随后死亡或被击退也不会将范围中心意外移走。`excludeCenter` 可排除主目标。编辑器重排时同步重写目标中心和说明索引。

数值字段：

| 字段 | 含义 |
| --- | --- |
| `attackRatio` | 伤害、治疗或护盾的施法者即时攻击倍率 |
| `maxHpRatio` | 治疗或护盾中额外叠加的施法者最大生命倍率 |
| `amount` | 增减益比例，或暴击／韧性／闪避／精准的固定加值 |
| `buff` | shield、purify、strong、weak、sunder、steel、bless、critup、toughup、fleeup、hitup、stun |
| `duration` | 状态持续目标行动回合，1～100 |
| `distance` | 击退距离；突进时为距离上限，0 表示不限 |
| `unit` | 必须显式引用本包或已声明依赖中的 `summon` 模板 |
| `statRatio` | 召唤瞬间的即时面板继承倍率 |
| `lifetime` | 召唤物存续自身行动回合，1～100 |
| `maxAlive` | 同一施法者、技能与步骤的存活上限；单技能总和不超过 16 |
| `growth` | 只开放 attackRatio、maxHpRatio、amount 的每级增量 |

召唤先复制攻击、最大生命、物防、法防和四项副属性的即时值，再独立行动。继承的不是永久养成资料，也不会自动复制施法者的全部状态对象。新召唤失败时保留旧召唤物；达到上限时成功的新召唤替换最早存活者。召唤物使用自己模板的普攻与技能，不能继续召唤其他单位。

此模型的真实伤害倍率直接表示攻击面板比例，例如 `attackRatio: 0.6` 表示 60% 攻击的真实伤害。客户端在原生攻击入口抵消历史 `REAL_DAMAGE_RATE` 的 0.3 缩放，保留命中、暴击、护盾和致死保护等后续结算；参考引擎使用对应的绝对真实伤害入口。不会修改原版技能和旧模型的真实伤害算法。

## 数值说明

`rankInfoTemplate` 使用实际编译动作的字段，支持 `{rank:动作索引:字段索引}` 显示百分比和 `{flat:动作索引:字段索引}` 显示整数。用于新模型的数值索引为：4 半径、5 攻击倍率、6 自身最大生命倍率、7 增减益／固定加值、9 持续回合、10 距离、12 继承倍率、13 存续回合、14 存活上限。描述中不允许读取任意对象字段。

升级直接修改同一动作的数值，编辑器等级预览和客户端详情都从该数值渲染。大招也启用动态说明，不再受旧队长技能说明分支的固定文字限制。

## 文件与交付边界

校验与编译见 `server/mod_effects.py`，参考执行见 `server/battle_mod_effects.py`；运行客户端使用 `client/src/stages/139_SkillSet.as` 与 `137_Avatar.as`。Schema 由 `scripts/generate_mod_schemas.py` 生成。

游戏与编辑器分别提交 PR，先合并游戏接口，再合并并发布编辑器。旧发行客户端不具有上述能力，不得为了绕过兼容检查而手工删除包的 requiredCapabilities。编辑器仍为 1.2.0-dev，本轮未打包或发布新版编辑器 EXE。

实机反馈修复：可选治疗特效为空时不再访问空对象；召唤注册接口 addAvatar 返回 void，不得作为成功标志判断并误将新召唤物生命清零；达到上限的被替换召唤物进入正常退场流程。
