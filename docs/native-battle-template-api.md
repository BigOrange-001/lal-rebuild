# 完整原生战斗模板接口

本接口属于游戏端，供离线创作工具使用。游戏运行、模板校验、编译和本页检查均不依赖编辑器、Qt 或 Pillow UI。接口保留 API 1，新增能力 `skill.native-template.v1`。

## 覆盖与数据边界

当前基础配置有 1077 条技能（包含品质变体），73 种原生动作，44 类复合机制，324 个复合机制可调参数。模板来自 `mod_native.make_template`；创作工具可编辑结构化数据，再通过同一包校验与编译入口使用。

- `source/sourceDigest` 绑定当前基础技能契约；基础配置变化需要重新审核。
- `actions[].type/arguments` 表达原生操作和参数；`settings` 保留目标、条件、成长、分组、召唤与联动数据。
- `abilityParameters/abilityContract` 提供复合机制数值和条件阈值，不运行外部代码；公共命中、伤害算法与复合流程仍由游戏引擎定义。
- 私有技能 ID 与机制来源分离；召唤、分身及专属派发使用来源，持久化引用仍使用私有注册身份。
- 客户端声明能力；服务端在激活、登录和玩法请求检查支持，旧客户端仍能在已有会话中管理及禁用新包。
- 普攻允许 physical/magic/true；真实伤害沿用原版倍率，不自动变为面板攻击的 100%。
- 原有 16 动作命名字段格式保留；原版历史无执行分支的 hitup/fleeup 不新增执行算法。

## 原生动作

| 操作 | 名称 |
| --- | --- |
| `armor` | 护甲 |
| `attrup` | 属性提升 |
| `back` | 反击 |
| `battle_stack` | 战斗叠层 |
| `battle_stack_unconditional` | 无条件战斗叠层 |
| `bless` | 祝福 |
| `burn` | 灼烧 |
| `caster_hp_shield` | 施法者生命护盾 |
| `clone_normal` | 普通技能分身 |
| `combo` | 连击 |
| `conditional_damage` | 条件伤害 |
| `cure` | 治疗 |
| `curse` | 诅咒 |
| `damage` | 伤害 |
| `damage_chain` | 链式伤害 |
| `dash` | 冲刺 |
| `dash_group_strike` | 突进群攻 |
| `dispel_good` | 驱散增益 |
| `evil` | 邪恶 |
| `fleeup` | 闪避提升 |
| `focus_fire` | 集火 |
| `heal_ap` | 按攻击治疗 |
| `heal_damage_sum` | 按实际伤害总和治疗 |
| `heal_missing_hp` | 回复已损生命 |
| `heal_missing_hp_per_hero` | 按命中英雄数回复已损生命 |
| `hitup` | 命中提升 |
| `hp_shield` | 生命护盾 |
| `kill_buff` | 击杀增益 |
| `lethal_floor` | 最低生命保护 |
| `locked_combo_group` | 分组连击 |
| `locked_combo_weak` | 连击附加虚弱 |
| `locked_sequence` | 锁定连段 |
| `locked_sequence_area` | 锁定连段范围攻击 |
| `manual_ability` | 原生复合机制 |
| `manual_dot` | 持续伤害 |
| `move_enemy_side_target` | 移至敌人侧面 |
| `move_self` | 自身位移 |
| `move_to_ally` | 移动至友军 |
| `move_to_target` | 移动至敌人 |
| `move_to_target_lane` | 换路并突进 |
| `normal_on_hero_kill` | 击杀英雄追加普攻 |
| `pending_area_strike` | 延后范围打击 |
| `poison` | 中毒 |
| `pull` | 拉近 |
| `pull_group` | 群体拉近 |
| `purify` | 净化 |
| `push` | 击退 |
| `push_aoe` | 范围击退 |
| `recast_on_kill` | 击杀重施 |
| `ricochet_bursts` | 弹射连发 |
| `select_target` | 选定目标 |
| `shield` | 攻击护盾 |
| `shield_composite` | 复合护盾 |
| `shield_dispel` | 驱散护盾 |
| `shield_followup` | 护盾后续结算 |
| `silence` | 沉默 |
| `stat_flat` | 固定属性 |
| `steel` | 双抗提升 |
| `strong` | 强化 |
| `stun` | 眩晕 |
| `stun_by_condition` | 条件眩晕 |
| `suck` | 吸血 |
| `summon` | 召唤 |
| `summon_turret` | 召唤炮台 |
| `sunder` | 破甲 |
| `sunder_percent` | 百分比破甲 |
| `target_hp_shield` | 目标生命护盾 |
| `taunt` | 嘲讽 |
| `timed_stack` | 定时叠层 |
| `true_damage` | 真实伤害 |
| `trynd_undying` | 不死状态 |
| `weak` | 虚弱 |
| `weak_percent` | 百分比虚弱 |

## 复合机制参数

| 机制 | 参数数 |
| --- | ---: |
| `kayle_c` | 4 |
| `nunu_c` | 2 |
| `illaoi_c` | 8 |
| `orianna_c` | 9 |
| `jayce_n` | 13 |
| `elise_c` | 11 |
| `nidalee_c` | 6 |
| `caitlyn_c` | 8 |
| `khazix_c` | 8 |
| `jinx_c` | 16 |
| `maokai_c` | 8 |
| `riven_c` | 10 |
| `aoxing_c` | 9 |
| `illaoi_n` | 7 |
| `jayce_c` | 11 |
| `nidalee_n` | 6 |
| `kayle_n` | 6 |
| `maokai_n` | 4 |
| `wukong_n` | 9 |
| `wukong_c` | 10 |
| `gangplank_n` | 5 |
| `gangplank_c` | 8 |
| `yi_n` | 8 |
| `yi_c` | 6 |
| `veigar_n` | 7 |
| `veigar_c` | 7 |
| `elise_n` | 5 |
| `riven_n` | 14 |
| `orianna_n` | 5 |
| `nunu_n` | 6 |
| `alistar_n` | 12 |
| `alistar_c` | 3 |
| `diana_n` | 5 |
| `diana_c` | 9 |
| `khazix_n` | 4 |
| `malzahar_n` | 4 |
| `malzahar_c` | 7 |
| `jinx_n` | 7 |
| `tahm_n` | 5 |
| `tahm_c` | 8 |
| `caitlyn_n` | 4 |
| `kaelthas_n` | 5 |
| `kaelthas_c` | 6 |
| `aoxing_n` | 9 |

完整参数默认值、类型、范围与代码上下文见 [参数契约](../server/native_ability_parameters.json)。参数生成器 `scripts/expose_native_ability_parameters.py` 仅对已固定的游戏机制提供数据入口，结构性索引和引擎哨兵值不向外开放。

## 无编辑器依赖的核心检查

```powershell
python -B scripts/check_native_api.py
python -B scripts/check_native_client_guard.py
```

第一项验证全部技能逐字段往返、逐技能修改编译、引用重排、五批真实包安装编译、new/patch 和非法输入拒绝；第二项使用临时 SQLite 验证新旧客户端能力握手。需要正常服务端依赖，不需要编辑器依赖。另有三项已有包回归检查。

客户端最终 SkillSetData、Avatar、SkillSet、SendAndSelect 已在相同源码上进行增量编译检查；后续修复已复用编译 SWF 打包 Android 客户端，并在雷电验证登录、自制卡显示与系统文件选择器导入；未做完整战斗回归或手机版整合端重打包。

格式见 [作者规范](mod-authoring.md) 与 [原生模板 Schema](../schemas/mod-native-template.schema.json)。编辑器界面、图片处理、合包 UI 和 EXE 发行应由独立工具项目管理，不纳入游戏端运行依赖。

## 卡面布局、手机导入与管理修正（2026-10-19）

PNG 可携带经严格校验的 `lal.cardFrame` 矩形，包和客户端通过 `asset.image.card-frame` 协商。布局和点击区域使用 103×118 逻辑盾框，透明留白及人物出框部分照常绘制，不计入边界；旧 PNG 沿用原显示路径。卡框图与详情页 portrait 为独立资源引用。

Android 使用 SAF，空 File 对象先完成异步权限初始化，再打开系统文件选择器；通过 File 对象读取 content URI，读取上限 64 MiB。用户可从 Download 选择包，无需 root。雷电 Android 9 普通应用的实际 `/mods/install` 请求已返回 200。包列表直接提供“删除已安装包 · 此版本”，调用现有全存档影响预览和确认卸载接口，保留永久身份与英雄进度。

助战保留原有 12 个机器人的队长，为每个可用新增英雄分配独立候选，避免同一测试英雄替换六个队长并占满首屏。额外候选每次最多六个并按日轮换；关闭出现开关后移除对应候选。

新增检查：`python -B -m unittest server.test_mod_card_frame server.test_mod_assist`；另通过已有跨存档待结算卸载保护回归。

## 审查修复（2026-10-19）

备份预览及恢复提交统一校验目标配置所需客户端能力；旧客户端仍可停用不兼容包，但不能通过恢复备份绕过激活保护。登录在创建 session、累加登录进度和派发登录结算前检查现有存档能力。

`battle_stack` 与 `heal_missing_hp_per_hero` 的动作索引参与统一重排、删除依赖和向前引用检查。锐雯连段两个取模基数最低为 1，生成器和公开 Schema 同步收紧；只放行这次范围收紧前的已知协议摘要，所有输入仍按新范围校验，后续协议变更不自动继承此例外。

新增 `server.test_mod_native_review` 验证两类索引映射、被引用动作删除／向前引用的原子拒绝、零／负数／小数／布尔参数拒绝及旧协议合法值兼容。`check_native_client_guard.py` 覆盖旧客户端备份恢复拒绝和连续三次拒绝登录时 profile、session、奖励账本、邮件与状态修订不变；新客户端恢复及登录成功。全部 1077 技能编译往返、388 次合法重排及五批真实包检查通过。
