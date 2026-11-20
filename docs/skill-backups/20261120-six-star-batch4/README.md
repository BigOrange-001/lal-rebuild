# 第四批六星英雄旧版技能备份

基线 `af7e0dfe43182bee0b157d6c7ff2f4d36db09426` 是本批改动前的 GitHub 主分支。备份仅记录本批的 13 名英雄。

| 文件 | 内容 |
| --- | --- |
| [旧版技能表](old-skills.csv) | 39 个技能位，含原编号、名称、准备回合、冷却回合和旧版配置说明。没有配置的技能位保留空白。 |
| [旧版技能配置](old-skill-config.json) | 英雄配置、所引用的召唤模板、29 条旧技能定义及代码 SHA-256。 |
| [旧版源码](old-skill-source.zip) | 14 份旧代码和构建清单。归档目录 `af7e0df/` 内沿用仓库路径，文件字节已与基线逐一核对。 |

客户端技能执行源码位于 `client/src/stages/137_Avatar.as` 和 `client/src/stages/139_SkillSet.as`。服务端原技能处理位于 `server/manual_ability_sim.py`、`server/six_star_battle_105.py` 和 `server/six_star_balance_105.py`，其余归档文件对应配置加载、装备绑定和技能成长。

需要回退本批时，从最新主分支创建回退分支并运行 `git revert 7c8ca7aaea0fae3a7e8861ab16a342b83ad48f9a`。备份是独立提交，可以保留。若之后还有平衡配置改动，处理冲突时保留后续改动，并运行 `python server/prepared_config.py` 重新生成配置快照。
