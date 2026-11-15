# 深渊回廊后端开发日志

## 环境与边界

2026-11-16，从 main 4af3330 创建 worktree `E:/My Project/lal-rebuild/lal-abyss`，分支 feat/roguelite-abyss。
设计稿独立提交 188b944。原 project 未提交修改、其他分支、client、private、runtime 存档均未改动；不推送、不构建、不安装。
测试使用包内 Python，PYTHONPATH 为 toolchain/pythonlibs、lal-abyss/server、lal-abyss/scripts；已确认 gateway.__file__ 指向 worktree。

## 阶段1：规则核心

实现独立标准化快照、种子化地图/敌人/候选、状态机、9个接口和 battle_finish 别名；持久化续局、20次重打及难度递减、永久解锁、星裔卡组。
在 PlayerStore 所有事务前后统一记录曾获得英雄；首次加载回填，确保首次出售/消耗前也保留记录。旧存档的历史已失去英雄无法从不存在的数据恢复。

固定起始卡组（顺序为2坦克、1辅助、2主力）：

| 卡组 | 名单 | 依据 |
| --- | --- | --- |
| 锋刃 | 盖伦、嘉文四世、索拉卡、赵信、易大师 | 前排承伤、治疗、单体物理；嘉文/盖伦可队长 |
| 炎咒 | 布里茨、蕾欧娜、娑娜、雷兹、凯南 | 控制承伤、治疗、范围法伤 |
| 蚀骨 | 慎、墨菲特、璐璐、卡西奥佩娅、提莫 | 承伤保护、辅助、中毒 |
| 群策 | 瑟庄妮、阿里斯塔、迦娜、黑默丁格、婕拉 | 承伤/辅助、炮台与植物召唤 |

四套英雄不重复，均来自50名初始普通紫卡；全部含A_1001～A_1021；其余按配置顺序补足。皮肤紫/橙配对和仅橙名单由加载后配置生成。
每幕两套Boss阵容写入 roguelite_abyss 配置；精英首位橙卡主属性额外1.2倍作为“强化橙卡”的实现初值。
每幕7层，分叉为同层2～3个节点，所有路径经过一次休息和至少一次精英；难度10固定两层精英。

阶段1先保留精确奖励掷骰的 pending_relic 记录，阶段2在同分支接入实际圣遗物物品；不可把阶段1单独视为圣遗物可用版本。
接口脚本使用合成内存账号和控制sign，验证完整流程，不声称战斗模型自然通关。

需用户决定：精英橙卡保证数与永久解锁/池内排除存在不可同时满足的情况，暂不为凑数绕过解锁；接口文档已说明。
未验证：客户端界面、实际战斗场景对接、Android、双端一致性。

测试和提交记录随本阶段检查完成后追加。

阶段1验证：`python -m unittest test_roguelite_abyss` 14/14通过；`python scripts/abyss_api_walkthrough.py` 76次真实RPC调用，覆盖失败重打、Boss、通关、放弃，9种接口样例已输出。
既有回归：equipment_flows、equipment_magic、equipment_bonds_104、new_skin_bonds_104、stat_power_103、dn_power、exploration_regressions、exploration_overhaul、campaign_tower_difficulty_104、activity_tower、combat_origin_phase、roster_sale_promotion 共97项，96通过、1项既有失败。
既有失败是 NewSkinBondsTests.test_yasuo_derived_damage_and_silence_exception_require_own_bond：期望队长技CD=4，实为3。通过 git archive main 的 server/config/scripts/VERSION 解包到临时目录，在纯 main 源码上独立重跑同一测试，复现同样失败。未修改该断言或无关亚索逻辑。
本阶段无新增失败。提交以 `feat(abyss): 阶段1 模式规则与事务接口` 标识；其哈希在下一阶段日志记录。
